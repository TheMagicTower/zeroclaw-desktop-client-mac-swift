import Foundation
import Combine

// MARK: - PendingAttachment

struct PendingAttachment: Identifiable {
    let id = UUID()
    let data: Data
    let mime: String

    /// ZeroClaw inline image marker format
    var marker: String {
        "[\(IMAGE):data:\(mime);base64,\(data.base64EncodedString())]"
            .replacingOccurrences(of: "[\(IMAGE):", with: "[IMAGE:")
    }
}

// avoid swift string interpolation issues with the IMAGE keyword
private let IMAGE = "IMAGE"

// MARK: - ChatViewModel

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText = ""
    @Published private(set) var isSending = false
    @Published private(set) var connectionError: String?
    @Published var pendingAttachments: [PendingAttachment] = []

    // Input history (terminal-style Shift+Up/Down navigation)
    private var sentHistory: [String] = []
    private var historyIndex: Int? = nil
    private var historyDraft: String = ""

    private let ws = WebSocketService()
    private let settings: SettingsViewModel
    private var cancellables = Set<AnyCancellable>()

    var isConnected: Bool { ws.isConnected }
    var isPaired: Bool { settings.isPaired }

    init(settings: SettingsViewModel) {
        self.settings = settings

        ws.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        ws.$connectionError
            .receive(on: DispatchQueue.main)
            .assign(to: &$connectionError)

        ws.messagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handle($0) }
            .store(in: &cancellables)

        // Load history for the initial profile
        loadHistory()

        // Reload history when active profile changes
        settings.$activeProfileID
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.messages = []
                self?.loadHistory()
            }
            .store(in: &cancellables)

        // Auto-save with debounce on every messages change
        $messages
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.saveHistory() }
            .store(in: &cancellables)
    }

    // MARK: - Connection

    func connect() {
        guard let baseURL = settings.baseURL else { return }
        ws.connect(baseURL: baseURL, token: settings.token)
    }

    func disconnect() { ws.disconnect() }

    // MARK: - Attachments

    func addAttachment(_ data: Data, mime: String) {
        pendingAttachments.append(PendingAttachment(data: data, mime: mime))
    }

    func removeAttachment(id: UUID) {
        pendingAttachments.removeAll { $0.id == id }
    }

    // MARK: - Send

    func send() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasAttachments = !pendingAttachments.isEmpty
        guard (!text.isEmpty || hasAttachments), !isSending else { return }

        inputText = ""
        historyIndex = nil
        historyDraft = ""
        if !text.isEmpty { sentHistory.append(text) }
        let attachments = pendingAttachments
        pendingAttachments = []

        // Build display text (plain, no markers)
        messages.append(.user(text.isEmpty ? "📎 Image" : text))

        // Ensure connected
        if !ws.isConnected {
            connect()
            try? await Task.sleep(for: .milliseconds(800))
            guard ws.isConnected else {
                messages.append(ChatMessage(role: .error,
                    content: connectionError ?? "Could not connect to ZeroClaw daemon"))
                return
            }
        }

        isSending = true
        // Placeholder
        messages.append(ChatMessage(role: .assistant, content: "", isStreaming: true))

        // Build actual payload: attachment markers + context + text
        let markers = attachments.map(\.marker).joined(separator: " ")
        let userContent = [markers, text].filter { !$0.isEmpty }.joined(separator: "\n")
        let payload = buildMessageWithContext(userContent)

        do {
            try await ws.send(content: payload)
        } catch {
            if let idx = messages.indices.last, case .assistant = messages[idx].role {
                messages.remove(at: idx)
            }
            messages.append(ChatMessage(role: .error, content: error.localizedDescription))
            isSending = false
        }
    }

    func clearHistory() {
        messages.removeAll()
        if let url = historyURL() { try? FileManager.default.removeItem(at: url) }
    }

    // MARK: - Persistence

    private static let maxSavedMessages = 500

    private func historyURL() -> URL? {
        guard let id = settings.activeProfileID,
              let appSupport = FileManager.default.urls(
                  for: .applicationSupportDirectory, in: .userDomainMask).first
        else { return nil }
        let dir = appSupport.appendingPathComponent("ZeroClawDesktop")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("history_\(id.uuidString).json")
    }

    private func saveHistory() {
        guard let url = historyURL() else { return }
        // Don't save streaming placeholders; cap at maxSavedMessages
        let toSave = messages
            .map { msg -> ChatMessage in
                var m = msg; m.isStreaming = false; return m
            }
            .filter { msg in
                // Skip empty assistant streaming placeholders
                if case .assistant = msg.role, msg.content.isEmpty { return false }
                return true
            }
            .suffix(Self.maxSavedMessages)
        guard let data = try? JSONEncoder().encode(Array(toSave)) else { return }
        try? data.write(to: url, options: .atomic)
    }

    private func loadHistory() {
        guard let url = historyURL(),
              let data = try? Data(contentsOf: url),
              let loaded = try? JSONDecoder().decode([ChatMessage].self, from: data)
        else { return }
        messages = loaded
    }

    // MARK: - Input history navigation

    func historyUp() {
        guard !sentHistory.isEmpty else { return }
        if historyIndex == nil {
            historyDraft = inputText
            historyIndex = sentHistory.count - 1
        } else if historyIndex! > 0 {
            historyIndex! -= 1
        } else {
            return
        }
        inputText = sentHistory[historyIndex!]
    }

    func historyDown() {
        guard let idx = historyIndex else { return }
        if idx < sentHistory.count - 1 {
            historyIndex = idx + 1
            inputText = sentHistory[historyIndex!]
        } else {
            historyIndex = nil
            inputText = historyDraft
        }
    }

    // MARK: - Message handling

    private func handle(_ msg: WebSocketMessage) {
        switch msg {
        case .chunk(let text):
            if let idx = messages.indices.last,
               case .assistant = messages[idx].role,
               messages[idx].isStreaming {
                messages[idx].content += text
            } else {
                messages.append(ChatMessage(role: .assistant, content: text, isStreaming: true))
            }

        case .done(let full):
            // Parse out <tool_call> XML blocks from the raw LLM response
            let (cleanText, toolCalls) = parseToolCallXML(from: full)

            if let idx = messages.indices.last, case .assistant = messages[idx].role {
                if cleanText.isEmpty && !toolCalls.isEmpty {
                    messages.remove(at: idx)  // remove empty placeholder
                } else {
                    messages[idx].content = cleanText
                    messages[idx].isStreaming = false
                }
            } else if !cleanText.isEmpty {
                messages.append(.assistant(cleanText))
            }

            // Show parsed tool calls as styled bubbles
            for call in toolCalls {
                messages.append(ChatMessage(role: .toolCall(name: call.name),
                                            content: call.args))
            }
            isSending = false

        case .toolCall(let name):
            messages.append(ChatMessage(role: .toolCall(name: name), content: "Calling \(name)…"))

        case .toolResult(let name, let output):
            messages.append(ChatMessage(role: .toolResult(name: name), content: output))

        case .error(let errMsg):
            if let idx = messages.indices.last, case .assistant = messages[idx].role,
               messages[idx].content.isEmpty {
                messages.remove(at: idx)
            }
            messages.append(ChatMessage(role: .error, content: errMsg))
            isSending = false
        }
    }

    // MARK: - Tool call XML parsing

    private struct ToolCallInfo { let name: String; let args: String }

    /// Strips <tool_call>...</tool_call> XML blocks from LLM output.
    /// Returns (cleanText, parsedCalls).
    private func parseToolCallXML(from raw: String) -> (String, [ToolCallInfo]) {
        var calls: [ToolCallInfo] = []
        var cleaned = raw

        // Find all <tool_call>...</tool_call> blocks
        let tcPattern = try? NSRegularExpression(
            pattern: "<tool_call>[\\s\\S]*?</tool_call>",
            options: []
        )
        let range = NSRange(raw.startIndex..., in: raw)
        guard let matches = tcPattern?.matches(in: raw, range: range), !matches.isEmpty else {
            return (raw, [])
        }

        // Process in reverse so string indices stay valid
        for match in matches.reversed() {
            guard let r = Range(match.range, in: cleaned) else { continue }
            let block = String(cleaned[r])

            // Extract tool name: <tool name="X">
            let namePattern = try? NSRegularExpression(pattern: #"<tool name="([^"]+)">"#)
            if let nm = namePattern?.firstMatch(in: block, range: NSRange(block.startIndex..., in: block)),
               let nameRange = Range(nm.range(at: 1), in: block) {
                let toolName = String(block[nameRange])

                // Extract args: <arg name="X">value</arg>
                let argPattern = try? NSRegularExpression(pattern: #"<arg name="([^"]+)">([^<]*)</arg>"#)
                let argMatches = argPattern?.matches(in: block, range: NSRange(block.startIndex..., in: block)) ?? []
                let argParts = argMatches.compactMap { m -> String? in
                    guard let n = Range(m.range(at: 1), in: block),
                          let v = Range(m.range(at: 2), in: block) else { return nil }
                    return "\(block[n]): \(block[v].trimmingCharacters(in: .whitespacesAndNewlines))"
                }
                calls.append(ToolCallInfo(name: toolName, args: argParts.joined(separator: "\n")))
            }
            // Remove the block from cleaned text
            if let cr = Range(match.range, in: cleaned) {
                cleaned.replaceSubrange(cr, with: "")
            }
        }

        return (cleaned.trimmingCharacters(in: .whitespacesAndNewlines), calls.reversed())
    }

    // MARK: - Context injection

    private func buildMessageWithContext(_ newMessage: String) -> String {
        let history = messages
            .dropLast(2)  // drop new user msg + placeholder
            .filter {
                switch $0.role {
                case .user, .assistant: return !$0.content.isEmpty
                default: return false
                }
            }
            .suffix(20)

        guard !history.isEmpty else { return newMessage }

        var parts = ["[Conversation so far]"]
        for msg in history {
            switch msg.role {
            case .user:      parts.append("User: \(msg.content)")
            case .assistant: parts.append("Assistant: \(msg.content)")
            default: break
            }
        }
        parts.append("\n[Reply to this new message]")
        parts.append("User: \(newMessage)")
        return parts.joined(separator: "\n")
    }
}
