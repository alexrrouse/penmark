import SwiftUI

struct MarkdownEditorView: View {
    let tab: FileTab
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var systemColorScheme

    private var isDark: Bool {
        switch appState.appColorScheme {
        case .dark: return true
        case .light: return false
        case .system: return systemColorScheme == .dark
        }
    }

    private let renderer = MarkdownRenderer()

    var body: some View {
        Group {
            if appState.viewMode == .rendered {
                WebView(
                    html: renderer.renderHTML(tab.content, isDark: isDark, searchQuery: appState.contentSearchQuery),
                    searchQuery: appState.contentSearchQuery
                )
            } else {
                RawTextView(
                    content: tab.content,
                    searchQuery: appState.contentSearchQuery,
                    isDark: isDark
                )
            }
        }
        .background(Color(nsColor: isDark ? NSColor(white: 0.12, alpha: 1) : .white))
    }
}
