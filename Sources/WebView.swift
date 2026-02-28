import SwiftUI
import WebKit

struct WebView: NSViewRepresentable {
    let html: String
    let searchQuery: String

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        #if DEBUG
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        #endif
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        // Reload HTML when content or search changes
        if context.coordinator.lastHTML != html || context.coordinator.lastQuery != searchQuery {
            context.coordinator.lastHTML = html
            context.coordinator.lastQuery = searchQuery
            webView.loadHTMLString(html, baseURL: nil)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var lastHTML: String = ""
        var lastQuery: String = ""

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Open external links in the default browser
            if navigationAction.navigationType == .linkActivated,
               let url = navigationAction.request.url,
               url.scheme == "http" || url.scheme == "https" {
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }
    }
}

// MARK: - Raw Text View
struct RawTextView: NSViewRepresentable {
    let content: String
    let searchQuery: String
    let isDark: Bool

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = NSTextView()

        textView.isEditable = false
        textView.isSelectable = true
        textView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.backgroundColor = .clear
        textView.textContainerInset = NSSize(width: 20, height: 20)
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false

        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false

        context.coordinator.textView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = context.coordinator.textView else { return }

        let fg: NSColor = isDark ? .init(white: 0.85, alpha: 1) : .init(white: 0.1, alpha: 1)
        let bgColor: NSColor = isDark ? .init(white: 0.12, alpha: 1) : .white

        scrollView.backgroundColor = bgColor
        if textView.string != content {
            textView.string = content
            textView.textColor = fg
        } else {
            textView.textColor = fg
        }

        // Highlight search matches
        if !searchQuery.isEmpty {
            let attrStr = NSMutableAttributedString(string: content)
            attrStr.addAttribute(.foregroundColor, value: fg, range: NSRange(content.startIndex..., in: content))

            let highlight = NSColor.systemYellow.withAlphaComponent(0.5)
            let nsContent = content as NSString
            var searchRange = NSRange(location: 0, length: nsContent.length)
            while searchRange.location < nsContent.length {
                let found = nsContent.range(of: searchQuery, options: .caseInsensitive, range: searchRange)
                if found.location == NSNotFound { break }
                attrStr.addAttribute(.backgroundColor, value: highlight, range: found)
                searchRange = NSRange(location: found.location + found.length,
                                      length: nsContent.length - found.location - found.length)
            }
            textView.textStorage?.setAttributedString(attrStr)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator {
        var textView: NSTextView?
    }
}
