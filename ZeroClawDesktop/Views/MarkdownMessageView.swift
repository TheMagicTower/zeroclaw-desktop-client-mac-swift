import SwiftUI

/// Renders message content with markdown, code blocks, and mermaid diagrams.
struct MarkdownMessageView: View {
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(segments.enumerated()), id: \.offset) { _, seg in
                switch seg {
                case .text(let md):
                    BlockMarkdownView(source: md)
                case .code(let code, let lang):
                    CodeBlockView(code: code, language: lang)
                case .mermaid(let diagram):
                    MermaidView(diagram: diagram)
                        .frame(minHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    private var segments: [Segment] { Self.parse(content) }
}

// MARK: - Segment (fenced code / mermaid splitting)

private enum Segment {
    case text(String)
    case code(String, language: String)
    case mermaid(String)
}

private extension MarkdownMessageView {
    static func parse(_ raw: String) -> [Segment] {
        var result: [Segment] = []
        var rest = raw[...]
        let fence = /```([\w+-]*)\n([\s\S]*?)```/
        while !rest.isEmpty {
            if let m = rest.firstMatch(of: fence) {
                let before = String(rest[..<m.range.lowerBound])
                if !before.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    result.append(.text(before))
                }
                let lang = String(m.output.1).lowercased()
                let body = String(m.output.2).trimmingCharacters(in: .newlines)
                result.append(lang == "mermaid" ? .mermaid(body) : .code(body, language: lang))
                rest = rest[m.range.upperBound...]
            } else {
                let remaining = String(rest)
                if !remaining.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    result.append(.text(remaining))
                }
                break
            }
        }
        return result.isEmpty ? [.text(raw)] : result
    }
}

// MARK: - Block-level AST

private enum MDBlock {
    case heading(level: Int, text: String)
    case paragraph(String)
    case bulletList([String])
    case orderedList([String])
    case blockquote(String)
    case table(headers: [String], rows: [[String]])
    case thematicBreak
}

private extension MDBlock {
    static func parse(_ source: String) -> [MDBlock] {
        var blocks: [MDBlock] = []
        let lines = source.components(separatedBy: "\n")
        var i = 0

        while i < lines.count {
            let line = lines[i]
            let t = line.trimmingCharacters(in: .whitespaces)

            // Blank line — skip
            if t.isEmpty { i += 1; continue }

            // Thematic break
            if t == "---" || t == "***" || t == "___" {
                blocks.append(.thematicBreak); i += 1; continue
            }

            // Headings
            if let level = headingLevel(t) {
                let skip = level + 1        // "# " → drop 2, "## " → drop 3, etc.
                let text = String(t.dropFirst(skip))
                blocks.append(.heading(level: level, text: text))
                i += 1; continue
            }

            // Blockquote
            if t.hasPrefix("> ") || t == ">" {
                var qLines: [String] = []
                while i < lines.count {
                    let qt = lines[i].trimmingCharacters(in: .whitespaces)
                    if qt.hasPrefix("> ") { qLines.append(String(qt.dropFirst(2))); i += 1 }
                    else if qt == ">" { qLines.append(""); i += 1 }
                    else { break }
                }
                blocks.append(.blockquote(qLines.joined(separator: "\n")))
                continue
            }

            // Bullet list
            if isBullet(t) {
                var items: [String] = []
                while i < lines.count {
                    let bt = lines[i].trimmingCharacters(in: .whitespaces)
                    if isBullet(bt) { items.append(String(bt.dropFirst(2))); i += 1 }
                    else { break }
                }
                blocks.append(.bulletList(items))
                continue
            }

            // Ordered list
            if let firstItem = orderedItem(t) {
                var items: [String] = [firstItem]; i += 1
                while i < lines.count {
                    let ot = lines[i].trimmingCharacters(in: .whitespaces)
                    if let item = orderedItem(ot) { items.append(item); i += 1 }
                    else { break }
                }
                blocks.append(.orderedList(items))
                continue
            }

            // Table (line starts and ends with |)
            if t.hasPrefix("|") {
                var tableLines: [String] = []
                while i < lines.count {
                    let tl = lines[i].trimmingCharacters(in: .whitespaces)
                    if tl.hasPrefix("|") { tableLines.append(tl); i += 1 }
                    else { break }
                }
                if tableLines.count >= 2 {
                    let headers = parseTableRow(tableLines[0])
                    // tableLines[1] is the separator row (|---|---|)
                    let rows = tableLines.dropFirst(2).map { parseTableRow($0) }
                    blocks.append(.table(headers: headers, rows: Array(rows)))
                }
                continue
            }

            // Paragraph: collect until blank line or block-starter
            var paraLines: [String] = []
            while i < lines.count {
                let pt = lines[i].trimmingCharacters(in: .whitespaces)
                if pt.isEmpty { break }
                if headingLevel(pt) != nil { break }
                if isBullet(pt) || orderedItem(pt) != nil { break }
                if pt.hasPrefix("> ") || pt == ">" { break }
                if pt.hasPrefix("|") { break }
                if pt == "---" || pt == "***" || pt == "___" { break }
                paraLines.append(lines[i])
                i += 1
            }
            if !paraLines.isEmpty {
                blocks.append(.paragraph(paraLines.joined(separator: "\n")))
            }
        }

        return blocks
    }

    // Returns heading level (1-6) if line starts with the right number of '#'
    private static func headingLevel(_ t: String) -> Int? {
        for level in 1...6 {
            let prefix = String(repeating: "#", count: level) + " "
            if t.hasPrefix(prefix) { return level }
        }
        return nil
    }

    private static func isBullet(_ t: String) -> Bool {
        t.hasPrefix("- ") || t.hasPrefix("* ") || t.hasPrefix("+ ")
    }

    private static func orderedItem(_ t: String) -> String? {
        guard let m = t.firstMatch(of: /^(\d+)\. (.+)/) else { return nil }
        return String(m.output.2)
    }

    private static func parseTableRow(_ row: String) -> [String] {
        let parts = row.split(separator: "|", omittingEmptySubsequences: false)
        // Drop first and last (empty strings from leading/trailing |)
        return parts.dropFirst().dropLast().map { $0.trimmingCharacters(in: .whitespaces) }
    }
}

// MARK: - BlockMarkdownView

struct BlockMarkdownView: View {
    let source: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(MDBlock.parse(source).enumerated()), id: \.offset) { _, block in
                blockView(for: block)
            }
        }
    }

    @ViewBuilder
    private func blockView(for block: MDBlock) -> some View {
        switch block {
        case .heading(let level, let text):
            inlineMarkdown(text)
                .font(headingFont(for: level))
                .padding(.top, level <= 2 ? 4 : 1)
                .fixedSize(horizontal: false, vertical: true)

        case .paragraph(let text):
            inlineMarkdown(text)
                .fixedSize(horizontal: false, vertical: true)

        case .bulletList(let items):
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("•").foregroundStyle(.secondary)
                        inlineMarkdown(item).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

        case .orderedList(let items):
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(items.enumerated()), id: \.offset) { i, item in
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(i + 1).")
                            .foregroundStyle(.secondary)
                            .frame(minWidth: 22, alignment: .trailing)
                        inlineMarkdown(item).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

        case .blockquote(let text):
            HStack(alignment: .top, spacing: 10) {
                Capsule()
                    .fill(Color.secondary.opacity(0.4))
                    .frame(width: 3)
                inlineMarkdown(text)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 2)

        case .table(let headers, let rows):
            MDTableView(headers: headers, rows: rows)

        case .thematicBreak:
            Divider()
        }
    }

    private func headingFont(for level: Int) -> Font {
        switch level {
        case 1: return .title2.bold()
        case 2: return .title3.bold()
        case 3: return .headline
        default: return .subheadline.bold()
        }
    }

    @ViewBuilder
    private func inlineMarkdown(_ text: String) -> some View {
        if let attr = try? AttributedString(
            markdown: text,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            Text(attr).textSelection(.enabled)
        } else {
            Text(text).textSelection(.enabled)
        }
    }
}

// MARK: - MDTableView

private struct MDTableView: View {
    let headers: [String]
    let rows: [[String]]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row
            HStack(spacing: 0) {
                ForEach(Array(headers.enumerated()), id: \.offset) { i, header in
                    Text(header)
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if i < headers.count - 1 {
                        Divider()
                    }
                }
            }
            .background(Color.secondary.opacity(0.12))

            Divider()

            // Data rows
            ForEach(Array(rows.enumerated()), id: \.offset) { ri, row in
                HStack(spacing: 0) {
                    ForEach(0..<headers.count, id: \.self) { ci in
                        Text(ci < row.count ? row[ci] : "")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if ci < headers.count - 1 {
                            Divider()
                        }
                    }
                }
                .background(ri % 2 == 1 ? Color.secondary.opacity(0.05) : Color.clear)
                Divider()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.25), lineWidth: 1))
    }
}

// MARK: - CodeBlockView

struct CodeBlockView: View {
    let code: String
    let language: String
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                if !language.isEmpty {
                    Text(language)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(code, forType: .string)
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copied = false }
                } label: {
                    Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(.caption2)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.secondary.opacity(0.15))

            Divider()

            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
    }
}
