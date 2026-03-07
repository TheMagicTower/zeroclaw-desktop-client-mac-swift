import SwiftUI
import AppKit

/// NSTextView wrapper — proper multiline, Cmd+Return to send, image paste, file drop.
/// Handles CJK/Korean IME composition correctly by guarding updateNSView with hasMarkedText().
struct MultilineTextInput: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String = "Message ZeroClaw… (Cmd+Return to send)"
    var submitMode: SubmitMode = .cmdEnter
    var onSubmit: () -> Void
    var onHistoryUp: (() -> Void)?
    var onHistoryDown: (() -> Void)?
    var onImagePaste: ((Data, String) -> Void)?

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.autoresizingMask = [.width]

        let tv = ChatNSTextView()
        tv.onSubmit = onSubmit
        tv.submitMode = submitMode
        tv.onHistoryUp = onHistoryUp
        tv.onHistoryDown = onHistoryDown
        tv.onImagePaste = onImagePaste
        tv.delegate = context.coordinator
        tv.isRichText = false
        tv.allowsUndo = true
        tv.font = .systemFont(ofSize: NSFont.systemFontSize)
        tv.textContainerInset = NSSize(width: 2, height: 6)
        tv.isAutomaticQuoteSubstitutionEnabled = false
        tv.isAutomaticDashSubstitutionEnabled = false
        tv.isAutomaticSpellingCorrectionEnabled = false
        tv.backgroundColor = .clear
        tv.drawsBackground = false
        tv.isVerticallyResizable = true
        tv.isHorizontallyResizable = false
        tv.textContainer?.widthTracksTextView = true

        scrollView.documentView = tv
        context.coordinator.scrollView = scrollView
        context.coordinator.setupKeyMonitor()

        // Grab focus when the containing window becomes key (e.g. menu bar popup shown)
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.windowDidBecomeKey(_:)),
            name: NSWindow.didBecomeKeyNotification,
            object: nil
        )

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let tv = scrollView.documentView as? ChatNSTextView else { return }
        tv.submitMode = submitMode
        tv.onHistoryUp = onHistoryUp
        tv.onHistoryDown = onHistoryDown

        // CRITICAL: Do NOT touch tv.string while the IME is composing (marked text).
        // Replacing the string during composition breaks Korean/Chinese/Japanese input.
        guard !tv.hasMarkedText() else { return }

        guard tv.string != text else { return }

        let sel = tv.selectedRanges
        tv.string = text

        if text.isEmpty {
            // After send: always restore focus to the text view
            DispatchQueue.main.async { tv.window?.makeFirstResponder(tv) }
        } else {
            tv.selectedRanges = sel
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    // MARK: - Coordinator

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MultilineTextInput
        weak var scrollView: NSScrollView?
        private var keyMonitor: Any?

        init(_ p: MultilineTextInput) { parent = p }

        deinit {
            NotificationCenter.default.removeObserver(self)
            if let m = keyMonitor { NSEvent.removeMonitor(m) }
        }

        /// Redirect printable key events to the text view even when it doesn't have focus.
        func setupKeyMonitor() {
            keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self,
                      let tv = self.scrollView?.documentView as? ChatNSTextView,
                      let win = tv.window,
                      win.isKeyWindow,
                      win.firstResponder !== tv,
                      // Don't intercept shortcuts (Cmd, Ctrl, Option)
                      event.modifierFlags.intersection([.command, .control, .option]).isEmpty,
                      // Only printable characters (≥ 0x20, excludes Return/Tab/Esc/arrows)
                      let chars = event.characters,
                      chars.unicodeScalars.contains(where: { $0.value >= 0x20 })
                else { return event }

                win.makeFirstResponder(tv)
                return event  // Deliver naturally to now-focused text view
            }
        }

        @objc func windowDidBecomeKey(_ notification: Notification) {
            guard let tv = scrollView?.documentView as? NSTextView,
                  let win = tv.window,
                  notification.object as? NSWindow === win else { return }
            // Claim first responder when the popup/window appears
            DispatchQueue.main.async { win.makeFirstResponder(tv) }
        }

        func textDidChange(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            // Only propagate when NOT in IME composition
            if !tv.hasMarkedText() {
                parent.text = tv.string
            }
        }

        // Called when IME composition finalises — sync the committed text
        func textDidEndEditing(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            parent.text = tv.string
        }
    }
}

// MARK: - ChatNSTextView

final class ChatNSTextView: NSTextView {
    var onSubmit: (() -> Void)?
    var submitMode: SubmitMode = .cmdEnter
    var onHistoryUp: (() -> Void)?
    var onHistoryDown: (() -> Void)?
    var onImagePaste: ((Data, String) -> Void)?

    override func keyDown(with event: NSEvent) {
        guard !hasMarkedText() else { super.keyDown(with: event); return }

        let flags = event.modifierFlags.intersection([.command, .shift, .option, .control])

        // Shift+Up → previous sent message
        if event.keyCode == 126, flags == .shift {
            onHistoryUp?(); return
        }
        // Shift+Down → next sent message (or restore draft)
        if event.keyCode == 125, flags == .shift {
            onHistoryDown?(); return
        }

        // Return → submit / newline
        guard event.keyCode == 36 else { super.keyDown(with: event); return }

        switch submitMode {
        case .cmdEnter:
            if flags == .command { onSubmit?() } else { super.keyDown(with: event) }
        case .enter:
            if flags.isEmpty { onSubmit?() } else { super.keyDown(with: event) }
        }
    }

    override func paste(_ sender: Any?) {
        if tryPasteImage() { return }
        super.paste(sender)
    }

    private func tryPasteImage() -> Bool {
        let pb = NSPasteboard.general
        if let data = pb.data(forType: .png) {
            onImagePaste?(data, "image/png"); return true
        }
        if let tiff = pb.data(forType: .tiff),
           let img = NSImage(data: tiff), let png = img.pngData() {
            onImagePaste?(png, "image/png"); return true
        }
        if let urls = pb.readObjects(forClasses: [NSURL.self],
                                     options: [.urlReadingFileURLsOnly: true]) as? [URL],
           let url = urls.first { return handleFile(url) }
        return false
    }

    @discardableResult
    private func handleFile(_ url: URL) -> Bool {
        let imageExts = ["png", "jpg", "jpeg", "gif", "webp", "heic", "bmp"]
        let ext = url.pathExtension.lowercased()
        guard imageExts.contains(ext), let data = try? Data(contentsOf: url) else { return false }
        let mime = (ext == "jpg" || ext == "jpeg") ? "image/jpeg" : "image/\(ext)"
        onImagePaste?(data, mime)
        return true
    }

    // MARK: Drag & drop

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let pb = sender.draggingPasteboard
        if pb.canReadObject(forClasses: [NSURL.self],
                            options: [.urlReadingFileURLsOnly: true]) { return .copy }
        return super.draggingEntered(sender)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pb = sender.draggingPasteboard
        if let urls = pb.readObjects(forClasses: [NSURL.self],
                                     options: [.urlReadingFileURLsOnly: true]) as? [URL],
           let url = urls.first, handleFile(url) { return true }
        return super.performDragOperation(sender)
    }
}

// MARK: - NSImage → PNG

private extension NSImage {
    func pngData() -> Data? {
        guard let cg = cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        return NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:])
    }
}
