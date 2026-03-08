import SwiftUI

struct ChatView: View {
    @EnvironmentObject var vm: ChatViewModel
    @EnvironmentObject var settings: SettingsViewModel

    var body: some View {
        VStack(spacing: 0) {
            if !settings.isPaired {
                statusBanner("lock.slash", "Not paired — go to Settings to pair", .orange)
            } else if !vm.isConnected {
                HStack(spacing: 6) {
                    Image(systemName: "wifi.slash").font(.caption)
                    Text(vm.connectionError ?? "Not connected to ZeroClaw daemon").font(.caption)
                    Spacer()
                    Button("Connect") { vm.connect() }
                        .buttonStyle(.borderedProminent).controlSize(.mini)
                }
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Color.orange.opacity(0.12))
            }

            messageList
            Divider()
            ChatInputBar(vm: vm, compact: true)
        }
        .onAppear {
            if settings.isPaired && !vm.isConnected { vm.connect() }
        }
    }

    // MARK: - Helpers

    private func statusBanner(_ icon: String, _ text: String, _ color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.caption)
            Text(text).font(.caption)
            Spacer()
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(color.opacity(0.12))
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    if vm.messages.isEmpty { emptyState }
                    ForEach(vm.messages) { msg in
                        CompactMessageBubble(
                            message: msg,
                            isQueued: vm.queuedMessageIDs.contains(msg.id),
                            onDequeue: { vm.removeQueuedMessage(msg.id) }
                        ).id(msg.id)
                    }
                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.horizontal, 10).padding(.vertical, 8)
            }
            .onChange(of: vm.messages.count) {
                withAnimation(.easeOut(duration: 0.15)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            .onChange(of: vm.messages.last?.content) {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "pawprint").font(.largeTitle).foregroundStyle(.secondary)
            Text("Send a message to start chatting with ZeroClaw")
                .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 40)
    }
}

// MARK: - CompactMessageBubble

struct CompactMessageBubble: View {
    let message: ChatMessage
    var isQueued: Bool = false
    var onDequeue: (() -> Void)? = nil
    @State private var expanded = false

    private var isTool: Bool {
        switch message.role {
        case .toolCall, .toolResult: return true
        default: return false
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            roleIcon.frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                if isTool {
                    HStack(spacing: 4) {
                        Text(roleLabel).font(.caption.bold()).foregroundStyle(.secondary)
                        Spacer(minLength: 0)
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) { expanded.toggle() }
                        } label: {
                            Image(systemName: expanded ? "chevron.up" : "chevron.down")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    if expanded {
                        CodeBlockView(code: message.content, language: "")
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                } else if message.isStreaming && message.content.isEmpty {
                    ProgressView().scaleEffect(0.7).frame(height: 20)
                } else {
                    MarkdownMessageView(content: message.content)
                        .opacity(message.isStreaming ? 0.75 : 1.0)
                }
                HStack(spacing: 4) {
                    Text(message.timestamp, style: .time)
                        .font(.caption2).foregroundStyle(.tertiary)
                    if isQueued {
                        Text("대기 중")
                            .font(.caption2)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4).padding(.vertical, 1)
                            .background(Color.orange)
                            .clipShape(Capsule())
                    }
                    Spacer(minLength: 0)
                    if isQueued, let onDequeue {
                        Button(action: onDequeue) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("큐에서 제거")
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(8)
        .background(bubbleColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var roleLabel: String {
        switch message.role {
        case .toolCall(let name): return "⚙️ Tool: \(name)"
        case .toolResult(let name): return "✓ Result: \(name)"
        default: return ""
        }
    }

    @ViewBuilder
    private var roleIcon: some View {
        switch message.role {
        case .user:
            Image(systemName: "person.circle.fill").foregroundStyle(Color.accentColor)
        case .assistant:
            Image(systemName: "pawprint.fill").foregroundStyle(.purple)
        case .toolCall:
            Image(systemName: "wrench.fill").foregroundStyle(.orange)
        case .toolResult:
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
        case .error:
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red)
        }
    }

    private var bubbleColor: Color {
        switch message.role {
        case .user:       return Color.accentColor.opacity(0.08)
        case .assistant:  return Color.purple.opacity(0.06)
        case .toolCall:   return Color.orange.opacity(0.08)
        case .toolResult: return Color.green.opacity(0.06)
        case .error:      return Color.red.opacity(0.08)
        }
    }
}
