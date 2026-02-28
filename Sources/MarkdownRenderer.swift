import Foundation

struct MarkdownRenderer {

    func renderHTML(_ markdown: String, isDark: Bool, searchQuery: String = "") -> String {
        let bodyHTML = convertToHTML(markdown)
        return fullDocument(body: bodyHTML, isDark: isDark, searchQuery: searchQuery)
    }

    // MARK: - Block-level parsing

    private func convertToHTML(_ text: String) -> String {
        // Normalize line endings
        let source = text.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        var output = ""
        let lines = source.components(separatedBy: "\n")
        var i = 0

        while i < lines.count {
            let line = lines[i]

            // Fenced code block
            if line.hasPrefix("```") {
                let lang = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                i += 1
                var codeLines: [String] = []
                while i < lines.count && !lines[i].hasPrefix("```") {
                    codeLines.append(lines[i])
                    i += 1
                }
                let code = codeLines.joined(separator: "\n").htmlEscaped
                let langAttr = lang.isEmpty ? "" : " class=\"language-\(lang)\""
                output += "<pre><code\(langAttr)>\(code)</code></pre>\n"
                i += 1 // skip closing ```
                continue
            }

            // Headings
            if let (level, text) = parseHeading(line) {
                output += "<h\(level)>\(processInline(text))</h\(level)>\n"
                i += 1
                continue
            }

            // Blockquote
            if line.hasPrefix(">") {
                var bqLines: [String] = []
                while i < lines.count && lines[i].hasPrefix(">") {
                    bqLines.append(String(lines[i].dropFirst(lines[i].hasPrefix("> ") ? 2 : 1)))
                    i += 1
                }
                let inner = convertToHTML(bqLines.joined(separator: "\n"))
                output += "<blockquote>\(inner)</blockquote>\n"
                continue
            }

            // Horizontal rule
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if isHorizontalRule(trimmed) {
                output += "<hr>\n"
                i += 1
                continue
            }

            // Unordered list
            if isUnorderedListItem(line) {
                var items: [String] = []
                while i < lines.count && isUnorderedListItem(lines[i]) {
                    let content = String(lines[i].dropFirst(2))
                    items.append("<li>\(processInline(content))</li>")
                    i += 1
                }
                output += "<ul>\n\(items.joined(separator: "\n"))\n</ul>\n"
                continue
            }

            // Ordered list
            if orderedListContent(line) != nil {
                var items: [String] = []
                while i < lines.count, let c = orderedListContent(lines[i]) {
                    items.append("<li>\(processInline(c))</li>")
                    i += 1
                }
                output += "<ol>\n\(items.joined(separator: "\n"))\n</ol>\n"
                continue
            }

            // Table
            if trimmed.contains("|") && (trimmed.hasPrefix("|") || trimmed.hasSuffix("|")) {
                var tableLines: [String] = []
                while i < lines.count {
                    let t = lines[i].trimmingCharacters(in: .whitespaces)
                    if t.contains("|") && (t.hasPrefix("|") || t.hasSuffix("|")) {
                        tableLines.append(lines[i])
                        i += 1
                    } else {
                        break
                    }
                }
                output += renderTable(tableLines)
                continue
            }

            // Empty line
            if trimmed.isEmpty {
                output += "\n"
                i += 1
                continue
            }

            // Paragraph — collect consecutive non-empty, non-special lines
            var paraLines: [String] = []
            while i < lines.count {
                let l = lines[i]
                let t = l.trimmingCharacters(in: .whitespaces)
                if t.isEmpty { break }
                if l.hasPrefix("```") || parseHeading(l) != nil || l.hasPrefix(">")
                    || isUnorderedListItem(l) || orderedListContent(l) != nil
                    || isHorizontalRule(t) { break }
                paraLines.append(l)
                i += 1
            }
            if !paraLines.isEmpty {
                let paraText = paraLines.joined(separator: " ")
                output += "<p>\(processInline(paraText))</p>\n"
            }
        }

        return output
    }

    // MARK: - Inline processing

    private func processInline(_ text: String) -> String {
        // Step 1: Extract inline code spans to protect them
        var placeholders: [String: String] = [:]
        var protected = text
        let codePattern = try! NSRegularExpression(pattern: "``(.+?)``|`([^`]+)`", options: [.dotMatchesLineSeparators])
        var idx = 0
        let matches = codePattern.matches(in: protected, range: NSRange(protected.startIndex..., in: protected))
        var result = ""
        var lastEnd = protected.startIndex

        for match in matches {
            let range = Range(match.range, in: protected)!
            result += String(protected[lastEnd..<range.lowerBound])
            let matchStr = String(protected[range])
            let code: String
            if matchStr.hasPrefix("``") {
                code = String(matchStr.dropFirst(2).dropLast(2))
            } else {
                code = String(matchStr.dropFirst(1).dropLast(1))
            }
            let key = "\u{0001}CODE\(idx)\u{0001}"
            placeholders[key] = "<code>\(code.htmlEscaped)</code>"
            result += key
            lastEnd = range.upperBound
            idx += 1
        }
        result += String(protected[lastEnd...])
        protected = result

        // Step 2: HTML-escape remaining text
        protected = protected.htmlEscaped

        // Step 3: Unescape placeholder markers that got escaped
        for key in placeholders.keys {
            let escaped = key.htmlEscaped
            if escaped != key {
                protected = protected.replacingOccurrences(of: escaped, with: key)
            }
        }

        // Step 4: Apply inline markdown patterns
        // Images before links
        protected = applyRegex(#"!\[([^\]]*)\]\(([^)]+)\)"#, in: protected) { m in
            let alt = m[1].htmlEscaped
            let src = m[2]
            return "<img src=\"\(src)\" alt=\"\(alt)\" style=\"max-width:100%\">"
        }

        // Links
        protected = applyRegex(#"\[([^\]]+)\]\(([^)]+)\)"#, in: protected) { m in
            "<a href=\"\(m[2])\">\(m[1])</a>"
        }

        // Bold-italic ***text***
        protected = applyRegex(#"\*\*\*(.+?)\*\*\*"#, in: protected) { m in "<strong><em>\(m[1])</em></strong>" }
        protected = applyRegex(#"___(.+?)___"#, in: protected) { m in "<strong><em>\(m[1])</em></strong>" }

        // Bold **text** or __text__
        protected = applyRegex(#"\*\*(.+?)\*\*"#, in: protected) { m in "<strong>\(m[1])</strong>" }
        protected = applyRegex(#"__(.+?)__"#, in: protected) { m in "<strong>\(m[1])</strong>" }

        // Italic *text* or _text_
        protected = applyRegex(#"\*([^*\n]+)\*"#, in: protected) { m in "<em>\(m[1])</em>" }
        protected = applyRegex(#"_([^_\n]+)_"#, in: protected) { m in "<em>\(m[1])</em>" }

        // Strikethrough
        protected = applyRegex(#"~~(.+?)~~"#, in: protected) { m in "<del>\(m[1])</del>" }

        // Step 5: Restore code placeholders
        for (key, value) in placeholders {
            protected = protected.replacingOccurrences(of: key, with: value)
        }

        return protected
    }

    // MARK: - Table rendering

    private func renderTable(_ lines: [String]) -> String {
        guard lines.count >= 2 else { return "" }
        let headers = parseCells(lines[0])
        // lines[1] is the separator row — skip
        let rows = lines.dropFirst(2).map { parseCells($0) }

        var html = "<table>\n<thead>\n<tr>"
        html += headers.map { "<th>\(processInline($0))</th>" }.joined()
        html += "</tr>\n</thead>\n<tbody>\n"
        for row in rows {
            html += "<tr>"
            html += row.map { "<td>\(processInline($0))</td>" }.joined()
            html += "</tr>\n"
        }
        html += "</tbody>\n</table>\n"
        return html
    }

    private func parseCells(_ line: String) -> [String] {
        var s = line.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("|") { s = String(s.dropFirst()) }
        if s.hasSuffix("|") { s = String(s.dropLast()) }
        return s.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    // MARK: - Helpers

    private func parseHeading(_ line: String) -> (Int, String)? {
        var count = 0
        for ch in line {
            if ch == "#" { count += 1 } else { break }
        }
        guard count >= 1, count <= 6 else { return nil }
        let rest = line.dropFirst(count)
        guard rest.hasPrefix(" ") || rest.isEmpty else { return nil }
        return (count, rest.trimmingCharacters(in: .whitespaces))
    }

    private func isHorizontalRule(_ s: String) -> Bool {
        let chars = Set(s.filter { !$0.isWhitespace })
        guard chars.count == 1, let c = chars.first, c == "-" || c == "*" || c == "_" else { return false }
        return s.filter { $0 == c }.count >= 3
    }

    private func isUnorderedListItem(_ line: String) -> Bool {
        (line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("+ ")) && line.count > 2
    }

    private func orderedListContent(_ line: String) -> String? {
        guard let dotRange = line.range(of: ". "),
              line[line.startIndex..<dotRange.lowerBound].allSatisfy({ $0.isNumber }),
              !line[line.startIndex..<dotRange.lowerBound].isEmpty else { return nil }
        return String(line[dotRange.upperBound...])
    }

    private func applyRegex(_ pattern: String, in text: String, transform: ([String]) -> String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return text }
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        var result = ""
        var lastEnd = text.startIndex

        for match in matches {
            let range = Range(match.range, in: text)!
            result += String(text[lastEnd..<range.lowerBound])
            var groups: [String] = [String(text[range])]
            for g in 1..<match.numberOfRanges {
                if let r = Range(match.range(at: g), in: text) {
                    groups.append(String(text[r]))
                } else {
                    groups.append("")
                }
            }
            result += transform(groups)
            lastEnd = range.upperBound
        }
        result += String(text[lastEnd...])
        return result
    }

    // MARK: - HTML Document

    private func fullDocument(body: String, isDark: Bool, searchQuery: String) -> String {
        let css = stylesheet(isDark)
        let escapedQuery = searchQuery.htmlEscaped
        let searchScript = searchQuery.isEmpty ? "" : """
        <script>
        window.addEventListener('load', function() {
          highlightSearch('\(escapedQuery)');
        });
        </script>
        """
        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>\(css)</style>
        <script>
        function highlightSearch(query) {
          if (!query) return;
          var body = document.body;
          var walker = document.createTreeWalker(body, NodeFilter.SHOW_TEXT);
          var nodes = [];
          while (walker.nextNode()) nodes.push(walker.currentNode);
          var re = new RegExp(query.replace(/[.*+?^${}()|[\\]\\\\]/g, '\\\\$&'), 'gi');
          nodes.forEach(function(node) {
            if (node.parentElement.tagName === 'CODE' || node.parentElement.tagName === 'SCRIPT') return;
            var text = node.textContent;
            if (!re.test(text)) return;
            re.lastIndex = 0;
            var span = document.createElement('span');
            span.innerHTML = text.replace(re, '<mark>$&</mark>');
            node.parentNode.replaceChild(span, node);
          });
          var first = document.querySelector('mark');
          if (first) first.scrollIntoView({block: 'center'});
        }
        function clearHighlights() {
          document.querySelectorAll('mark').forEach(function(m) {
            m.outerHTML = m.textContent;
          });
        }
        </script>
        </head>
        <body>
        \(body)
        \(searchScript)
        </body>
        </html>
        """
    }

    private func stylesheet(_ isDark: Bool) -> String {
        let bg = isDark ? "#1e1e1e" : "#ffffff"
        let fg = isDark ? "#d4d4d4" : "#1a1a1a"
        let h = isDark ? "#e2e2e2" : "#0d1117"
        let link = isDark ? "#58a6ff" : "#0969da"
        let codeBg = isDark ? "#2d2d2d" : "#f6f8fa"
        let codeFg = isDark ? "#ce9178" : "#e36209"
        let preBg = isDark ? "#252526" : "#f6f8fa"
        let preFg = isDark ? "#d4d4d4" : "#24292f"
        let border = isDark ? "#444" : "#d0d7de"
        let blockquoteBorder = isDark ? "#555" : "#d0d7de"
        let blockquoteFg = isDark ? "#999" : "#57606a"
        let markBg = isDark ? "#b5890080" : "#fff3b0"
        let markFg = isDark ? "#ffd700" : "#1a1a1a"
        let thBg = isDark ? "#2d2d2d" : "#f6f8fa"

        return """
        * { box-sizing: border-box; margin: 0; padding: 0; }
        html { font-size: 16px; }
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif;
          font-size: 16px;
          line-height: 1.6;
          color: \(fg);
          background-color: \(bg);
          padding: 32px 48px;
          max-width: 860px;
          margin: 0 auto;
        }
        h1, h2, h3, h4, h5, h6 {
          color: \(h);
          font-weight: 600;
          line-height: 1.25;
          margin: 1.5em 0 0.5em;
        }
        h1 { font-size: 2em; border-bottom: 1px solid \(border); padding-bottom: 0.3em; }
        h2 { font-size: 1.5em; border-bottom: 1px solid \(border); padding-bottom: 0.2em; }
        h3 { font-size: 1.25em; }
        h4 { font-size: 1em; }
        h5 { font-size: 0.875em; }
        h6 { font-size: 0.85em; color: \(blockquoteFg); }
        p { margin: 0.75em 0; }
        a { color: \(link); text-decoration: none; }
        a:hover { text-decoration: underline; }
        code {
          font-family: 'SF Mono', SFMono-Regular, Consolas, 'Liberation Mono', Menlo, monospace;
          font-size: 0.875em;
          background-color: \(codeBg);
          color: \(codeFg);
          padding: 0.15em 0.35em;
          border-radius: 4px;
        }
        pre {
          background-color: \(preBg);
          border-radius: 6px;
          padding: 1em 1.25em;
          overflow-x: auto;
          margin: 1em 0;
        }
        pre code {
          background: none;
          color: \(preFg);
          padding: 0;
          font-size: 0.875em;
          border-radius: 0;
        }
        blockquote {
          border-left: 4px solid \(blockquoteBorder);
          color: \(blockquoteFg);
          padding: 0.25em 1em;
          margin: 1em 0;
        }
        ul, ol { padding-left: 2em; margin: 0.75em 0; }
        li { margin: 0.25em 0; }
        hr {
          border: none;
          border-top: 1px solid \(border);
          margin: 2em 0;
        }
        img { max-width: 100%; height: auto; border-radius: 4px; }
        table {
          border-collapse: collapse;
          width: 100%;
          margin: 1em 0;
          font-size: 0.9em;
        }
        th, td {
          border: 1px solid \(border);
          padding: 0.5em 0.75em;
          text-align: left;
        }
        th { background-color: \(thBg); font-weight: 600; }
        tr:nth-child(even) { background-color: \(isDark ? "#252526" : "#f6f8fa"); }
        del { text-decoration: line-through; opacity: 0.7; }
        mark {
          background-color: \(markBg);
          color: \(markFg);
          border-radius: 2px;
          padding: 0 2px;
        }
        """
    }
}

// MARK: - String Extension
extension String {
    var htmlEscaped: String {
        self
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}
