import SwiftUI
import AppKit

struct ChatWindowView: View {
    @EnvironmentObject var chat: ChatViewModel
    @EnvironmentObject var settings: SettingsViewModel
    @EnvironmentObject var status: StatusViewModel

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            chatPanel
        }
        .navigationTitle("ZeroClaw")
        .onAppear {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        }
        .onDisappear {
            NSApp.setActivationPolicy(.accessory)
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(status.isOnline ? Color.green : Color.secondary)
                        .frame(width: 7, height: 7)
                    Text(status.isOnline ? "Online" : "Offline")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List {
            Section("Server") {
                LabeledContent("Profile") {
                    Text(settings.activeProfile?.name ?? "—")
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Host") {
                    Text(settings.activeProfile?.displayHost ?? "—")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Status") {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(settings.isPaired ? Color.green : Color.orange)
                            .frame(width: 6, height: 6)
                        Text(settings.isPaired ? "Paired" : "Not paired")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Chat") {
                LabeledContent("Messages") {
                    Text("\(chat.messages.count)")
                        .foregroundStyle(.secondary)
                }
                Button(role: .destructive) {
                    chat.clearHistory()
                } label: {
                    Label("Clear History", systemImage: "trash")
                }
                .disabled(chat.messages.isEmpty)
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 180, idealWidth: 200, maxWidth: 220)
        .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 220)
    }

    // MARK: - Chat panel

    private func banner(_ icon: String, _ text: String, _ color: Color) -> some View {
        Group {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.caption)
                Text(text).font(.caption)
                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(color.opacity(0.12))
            Divider()
        }
    }

    private var chatPanel: some View {
        VStack(spacing: 0) {
            if !settings.isPaired {
                banner("lock.slash", "Not paired — go to Settings to pair with ZeroClaw", .orange)
            } else if !chat.isConnected {
                HStack(spacing: 6) {
                    Image(systemName: "wifi.slash").font(.caption)
                    Text(chat.connectionError ?? "Not connected").font(.caption)
                    Spacer()
                    Button("Connect") { chat.connect() }
                        .buttonStyle(.borderedProminent).controlSize(.mini)
                }
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(Color.orange.opacity(0.12))
                Divider()
            }

            messageList
            Divider()
            ChatInputBar(vm: chat, compact: false)
        }
        .onAppear {
            if settings.isPaired && !chat.isConnected { chat.connect() }
        }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if chat.messages.isEmpty { emptyState }
                    ForEach(chat.messages) { msg in
                        WindowMessageBubble(message: msg).id(msg.id)
                    }
                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(16)
                .textSelection(.enabled)
            }
            .onChange(of: chat.messages.count) {
                withAnimation(.easeOut(duration: 0.15)) { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .onChange(of: chat.messages.last?.content) {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "pawprint").font(.system(size: 40)).foregroundStyle(.secondary)
            Text("Send a message to start chatting with ZeroClaw")
                .font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 80)
    }

}

// MARK: - WindowMessageBubble

struct WindowMessageBubble: View {
    let message: ChatMessage
    @State private var expanded = false

    private var isTool: Bool {
        switch message.role {
        case .toolCall, .toolResult: return true
        default: return false
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            roleIcon.frame(width: 22)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(roleLabel).font(.caption.bold()).foregroundStyle(.secondary)
                    Text(message.timestamp, style: .time).font(.caption2).foregroundStyle(.tertiary)
                    Spacer(minLength: 0)
                    if isTool {
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) { expanded.toggle() }
                        } label: {
                            Image(systemName: expanded ? "chevron.up" : "chevron.down")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if message.isStreaming && message.content.isEmpty {
                    ProgressView().scaleEffect(0.8).frame(height: 22)
                } else if isTool {
                    if expanded {
                        CodeBlockView(code: message.content, language: "")
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                } else {
                    MarkdownMessageView(content: message.content)
                        .opacity(message.isStreaming ? 0.75 : 1.0)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(bubbleBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private var roleIcon: some View {
        switch message.role {
        case .user:
            Image(systemName: "person.circle.fill").font(.title3).foregroundStyle(Color.accentColor)
        case .assistant:
            Image(systemName: "pawprint.fill").font(.title3).foregroundStyle(.purple)
        case .toolCall:
            Image(systemName: "wrench.fill").font(.title3).foregroundStyle(.orange)
        case .toolResult:
            Image(systemName: "checkmark.circle.fill").font(.title3).foregroundStyle(.green)
        case .error:
            Image(systemName: "exclamationmark.triangle.fill").font(.title3).foregroundStyle(.red)
        }
    }

    private var roleLabel: String {
        switch message.role {
        case .user: return "You"
        case .assistant: return "ZeroClaw"
        case .toolCall(let name): return "⚙️ Tool: \(name)"
        case .toolResult(let name): return "✓ Result: \(name)"
        case .error: return "Error"
        }
    }

    private var bubbleBackground: Color {
        switch message.role {
        case .user:       return Color.accentColor.opacity(0.08)
        case .assistant:  return Color.purple.opacity(0.06)
        case .toolCall:   return Color.orange.opacity(0.08)
        case .toolResult: return Color.green.opacity(0.06)
        case .error:      return Color.red.opacity(0.08)
        }
    }
}
