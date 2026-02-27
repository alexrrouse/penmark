import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var favoritesStore: FavoritesStore

    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            FileBrowserView()
                .navigationSplitViewColumnWidth(min: 180, ideal: 260, max: 400)
                .navigationTitle(appState.directoryDisplayName)
        } detail: {
            MarkdownPaneView()
                .frame(minWidth: 400)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // View mode toggle
                Picker("View Mode", selection: $appState.viewMode) {
                    Label("Rendered", systemImage: "doc.richtext").tag(ViewMode.rendered)
                    Label("Raw", systemImage: "chevron.left.forwardslash.chevron.right").tag(ViewMode.raw)
                }
                .pickerStyle(.segmented)
                .frame(width: 90)
                .help("Toggle between rendered and raw markdown view")

                Divider()

                // Color scheme toggle
                Menu {
                    ForEach(AppColorScheme.allCases, id: \.self) { scheme in
                        Button {
                            appState.appColorScheme = scheme
                        } label: {
                            Label(scheme.rawValue, systemImage: schemeIcon(scheme))
                        }
                    }
                } label: {
                    Image(systemName: schemeIcon(appState.appColorScheme))
                }
                .menuStyle(.borderlessButton)
                .frame(width: 28)
                .help("Color scheme")

                // Content search
                Button {
                    withAnimation {
                        appState.isContentSearchVisible.toggle()
                        if !appState.isContentSearchVisible {
                            appState.contentSearchQuery = ""
                        }
                    }
                } label: {
                    Image(systemName: "magnifyingglass")
                }
                .help("Search in file (⌘F)")
            }
        }
        .preferredColorScheme(appState.appColorScheme.colorScheme)
    }

    private func schemeIcon(_ scheme: AppColorScheme) -> String {
        switch scheme {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }
}
