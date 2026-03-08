import SwiftUI
import UniformTypeIdentifiers

// MARK: - ChatInputBar

struct ChatInputBar: View {
    @ObservedObject var vm: ChatViewModel
    @EnvironmentObject var settings: SettingsViewModel
    var compact: Bool = true  // compact = popup, false = full window

    @State private var showFilePicker = false
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Attachment thumbnails
            if !vm.pendingAttachments.isEmpty {
                attachmentStrip
                Divider()
            }
            HStack(alignment: .bottom, spacing: 8) {
                // Attachment button
                Button {
                    showFilePicker = true
                } label: {
                    Image(systemName: "paperclip")
                        .foregroundStyle(.secondary)
                        .font(compact ? .body : .title3)
                }
                .buttonStyle(.plain)
                .help("Attach image (or paste/drop)")

                // Text input
                MultilineTextInput(
                    text: $vm.inputText,
                    placeholder: settings.activeProfile?.submitMode.placeholder
                        ?? "Message ZeroClaw… (Cmd+Return to send)",
                    submitMode: settings.activeProfile?.submitMode ?? .cmdEnter,
                    onSubmit: { Task { await vm.send() } },
                    onHistoryUp: { vm.historyUp() },
                    onHistoryDown: { vm.historyDown() },
                    onImagePaste: { data, mime in vm.addAttachment(data, mime: mime) }
                )
                .frame(minHeight: compact ? 28 : 40, maxHeight: compact ? 100 : 200)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                // Drop images onto the input
                .onDrop(of: [.image, .fileURL], isTargeted: nil) { providers in
                    handleDrop(providers)
                }

                // Stop button (while sending) or Send button + queue badge
                if vm.isSending {
                    Button {
                        Task { await vm.cancelStream() }
                    } label: {
                        Image(systemName: "stop.circle.fill")
                            .font(compact ? .title2 : .system(size: 28))
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.escape, modifiers: [])
                    .help("Cancel (Esc)")
                } else {
                    ZStack(alignment: .topTrailing) {
                        Button {
                            Task { await vm.send() }
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(compact ? .title2 : .system(size: 28))
                                .foregroundStyle(canSend ? Color.accentColor : Color.secondary)
                        }
                        .buttonStyle(.plain)
                        .disabled(!canSend)
                        .keyboardShortcut(.return, modifiers: .command)
                        .help("Send (Cmd+Return)")

                        if vm.queuedMessageCount > 0 {
                            Text("\(vm.queuedMessageCount)")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .clipShape(Capsule())
                                .offset(x: 6, y: -4)
                        }
                    }
                }

                // Submit mode toggle
                let currentMode = settings.activeProfile?.submitMode ?? .cmdEnter
                Button {
                    settings.updateActiveSubmitMode(currentMode == .cmdEnter ? .enter : .cmdEnter)
                } label: {
                    VStack(spacing: 0) {
                        Text(currentMode == .cmdEnter ? "⌘↩" : "↩")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        Text("⌘⇧↩")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundStyle(.tertiary)
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.return, modifiers: [.command, .shift])
                .help(currentMode == .cmdEnter ? "전송: Cmd+Return · 모드 전환: ⌘⇧↩" : "전송: Return · 모드 전환: ⌘⇧↩")

                // More menu
                Menu {
                    Button("Clear history", role: .destructive) { vm.clearHistory() }
                    Divider()
                    Button(vm.isConnected ? "Disconnect" : "Connect") {
                        vm.isConnected ? vm.disconnect() : vm.connect()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle").foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .menuStyle(.button)
                .menuIndicator(.hidden)
            }
            .padding(.horizontal, compact ? 10 : 16)
            .padding(.vertical, compact ? 8 : 10)
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                loadImage(from: url)
            }
        }
    }

    // MARK: - Attachment strip

    private var attachmentStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(vm.pendingAttachments) { att in
                    AttachmentThumbnail(attachment: att) {
                        vm.removeAttachment(id: att.id)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
    }

    // MARK: - Helpers

    private var canSend: Bool {
        settings.isPaired &&
        (!vm.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
         !vm.pendingAttachments.isEmpty)
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                    if let data { DispatchQueue.main.async { vm.addAttachment(data, mime: "image/png") } }
                }
                return true
            }
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { item, _ in
                    if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                        loadImage(from: url)
                    }
                }
                return true
            }
        }
        return false
    }

    private func loadImage(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        guard let data = try? Data(contentsOf: url) else { return }
        let ext = url.pathExtension.lowercased()
        let mime = (ext == "jpg" || ext == "jpeg") ? "image/jpeg" : "image/\(ext.isEmpty ? "png" : ext)"
        DispatchQueue.main.async { vm.addAttachment(data, mime: mime) }
    }
}

// MARK: - AttachmentThumbnail

private struct AttachmentThumbnail: View {
    let attachment: PendingAttachment
    let onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let img = NSImage(data: attachment.data) {
                Image(nsImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 48, height: 48)
                    .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
            }

            Button { onRemove() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .shadow(radius: 1)
            }
            .buttonStyle(.plain)
            .offset(x: 4, y: -4)
        }
    }
}
