import Foundation
import Combine

// Messages arriving from the ZeroClaw WebSocket chat endpoint (/ws/chat).
enum WebSocketMessage {
    case chunk(String)
    case done(String)
    case toolCall(name: String)
    case toolResult(name: String, output: String)
    case error(String)
}

@MainActor
final class WebSocketService: NSObject, ObservableObject {
    @Published private(set) var isConnected = false
    @Published private(set) var connectionError: String?

    let messagePublisher = PassthroughSubject<WebSocketMessage, Never>()

    private var task: URLSessionWebSocketTask?
    private var session: URLSession?
    private var receiveTask: Task<Void, Never>?

    func connect(baseURL: URL, token: String?) {
        disconnect()

        var components = URLComponents(
            url: baseURL.appendingPathComponent("ws/chat"),
            resolvingAgainstBaseURL: true
        )!
        // Spec: auth via ?token= query param only (not Authorization header)
        if components.scheme == "http"  { components.scheme = "ws" }
        if components.scheme == "https" { components.scheme = "wss" }
        if let token {
            components.queryItems = [URLQueryItem(name: "token", value: token)]
        }
        guard let url = components.url else { return }

        connectionError = nil
        let config = URLSessionConfiguration.default
        let s = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        session = s
        task = s.webSocketTask(with: url)
        task?.resume()
        startReceiving()
    }

    func disconnect() {
        receiveTask?.cancel()
        receiveTask = nil
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
        session = nil
        isConnected = false
    }

    /// Send a chat message. Returns immediately; response arrives via messagePublisher.
    func send(content: String) async throws {
        guard let task, isConnected else {
            throw WebSocketError.notConnected
        }
        let payload = try JSONSerialization.data(withJSONObject: [
            "type": "message",
            "content": content
        ])
        try await task.send(.string(String(data: payload, encoding: .utf8)!))
    }

    // MARK: - Private

    private func startReceiving() {
        receiveTask = Task { [weak self] in
            guard let self else { return }
            while let task = await self.task {
                do {
                    let msg = try await task.receive()
                    if case .string(let text) = msg,
                       let data = text.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let parsed = Self.parse(json) {
                        await MainActor.run { self.messagePublisher.send(parsed) }
                    }
                } catch {
                    await MainActor.run {
                        self.isConnected = false
                        self.connectionError = error.localizedDescription
                    }
                    break
                }
            }
        }
    }

    private static func parse(_ json: [String: Any]) -> WebSocketMessage? {
        switch json["type"] as? String {
        case "chunk":
            return .chunk(json["content"] as? String ?? "")
        case "done":
            return .done(json["full_response"] as? String ?? "")
        case "tool_call":
            return .toolCall(name: json["name"] as? String ?? "unknown")
        case "tool_result":
            return .toolResult(
                name: json["name"] as? String ?? "unknown",
                output: json["output"] as? String ?? ""
            )
        case "error":
            return .error(json["message"] as? String ?? "Unknown error")
        default:
            return nil
        }
    }
}

enum WebSocketError: LocalizedError {
    case notConnected
    var errorDescription: String? { "Not connected to ZeroClaw daemon" }
}

extension WebSocketService: URLSessionWebSocketDelegate {
    nonisolated func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        Task { @MainActor [weak self] in
            self?.isConnected = true
            self?.connectionError = nil
        }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        Task { @MainActor [weak self] in self?.isConnected = false }
    }
}
