import SwiftUI

struct MarkdownPaneView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            if !appState.openTabs.isEmpty {
                TabBarView()

                // Content search bar
                if !appState.contentSearchQuery.isEmpty || appState.isContentSearchVisible {
                    ContentSearchBar()
                }

                if let tab = appState.activeTab {
                    MarkdownEditorView(tab: tab)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    EmptyTabView()
                }
            } else {
                EmptyTabView()
            }
        }
    }
}

struct ContentSearchBar: View {
    @EnvironmentObject var appState: AppState
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.system(size: 13))

            TextField("Search in file…", text: $appState.contentSearchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($isFocused)
                .onSubmit { }

            if !appState.contentSearchQuery.isEmpty {
                Button {
                    appState.contentSearchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            Button("Done") {
                appState.contentSearchQuery = ""
                appState.isContentSearchVisible = false
            }
            .buttonStyle(.plain)
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Material.bar)
        .overlay(Divider(), alignment: .bottom)
        .onAppear { isFocused = true }
    }
}

struct EmptyTabView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundStyle(.quaternary)
            Text("No file open")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("Select a markdown file from the sidebar")
                .font(.callout)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
