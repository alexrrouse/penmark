import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var favoritesStore: FavoritesStore

    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            FileBrowserView()
                .navigationSplitViewColumnWidth(min: 200, ideal: 260, max: 400)
                .navigationTitle(appState.directoryDisplayName)
        } detail: {
            MarkdownPaneView()
                .frame(minWidth: 400)
        }
        .toolbar {
            // Open button — left side
            ToolbarItem(placement: .navigation) {
                Button(action: openDocument) {
                    Image(systemName: "folder.badge.plus")
                }
                .help("Open Folder or File… (⌘O)")
            }

            // Right-side controls
            ToolbarItem(placement: .primaryAction) {
                // Rendered / Raw toggle — images only for a clean segmented look
                Picker("View", selection: $appState.viewMode) {
                    Image(systemName: "doc.richtext")
                        .help("Rendered")
                        .tag(ViewMode.rendered)
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .help("Raw")
                        .tag(ViewMode.raw)
                }
                .pickerStyle(.segmented)
                .fixedSize()
            }

            ToolbarItem(placement: .primaryAction) {
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
                        .frame(minWidth: 16)
                }
                .menuStyle(.borderlessButton)
                .help("Color scheme")
            }

            ToolbarItem(placement: .primaryAction) {
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

    private func openDocument() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Open"
        panel.message = "Choose a markdown file or a folder to browse"

        if panel.runModal() == .OK, let url = panel.url {
            var isDir: ObjCBool = false
            FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
            if isDir.boolValue {
                appState.changeDirectory(to: url)
            } else {
                let item = FileItem(url: url, isDirectory: false)
                appState.openFile(item)
            }
        }
    }

    private func schemeIcon(_ scheme: AppColorScheme) -> String {
        switch scheme {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }
}
