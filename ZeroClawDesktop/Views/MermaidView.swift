import SwiftUI
import WebKit

/// Renders a Mermaid diagram using WKWebView + mermaid.js (CDN).
struct MermaidView: NSViewRepresentable {
    let diagram: String

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.navigationDelegate = context.coordinator
        wv.setValue(false, forKey: "drawsBackground")
        wv.loadHTMLString(html, baseURL: nil)
        return wv
    }

    func updateNSView(_ wv: WKWebView, context: Context) {
        wv.loadHTMLString(html, baseURL: nil)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject, WKNavigationDelegate {}

    private var html: String {
        let escaped = diagram
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
        let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let theme = isDark ? "dark" : "default"
        let bg = isDark ? "#1e1e1e" : "#ffffff"
        return """
        <!DOCTYPE html><html><head>
        <meta name="viewport" content="width=device-width,initial-scale=1">
        <style>
        body { margin:0; padding:8px; background:\(bg); }
        .mermaid { background:\(bg); }
        </style></head><body>
        <div class="mermaid">\(escaped)</div>
        <script type="module">
        import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs';
        mermaid.initialize({startOnLoad:true,theme:'\(theme)'});
        </script>
        </body></html>
        """
    }
}
