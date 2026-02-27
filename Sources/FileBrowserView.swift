import SwiftUI

struct FileBrowserView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var favoritesStore: FavoritesStore
    @State private var fileItems: [FileItem] = []

    private var favItems: [URL] {
        favoritesStore.favorites(under: appState.rootDirectory)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 12))
                TextField("Filter files…", text: $appState.fileSearchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                if !appState.fileSearchQuery.isEmpty {
                    Button {
                        appState.fileSearchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color(nsColor: .controlBackgroundColor))
            .overlay(Divider(), alignment: .bottom)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    // Favorites section
                    if !favItems.isEmpty && appState.fileSearchQuery.isEmpty {
                        SectionHeader(title: "Favorites")

                        ForEach(favItems, id: \.self) { url in
                            let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                            FavoriteRowView(url: url, isDirectory: isDir)
                        }
                    }

                    // Files section
                    SectionHeader(title: appState.directoryDisplayName)

                    ForEach(appState.fileTree) { item in
                        FileRowView(item: item, depth: 0)
                    }
                }
                .padding(.bottom, 16)
            }
        }
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(0.5)
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - File Row
struct FileRowView: View {
    @State var item: FileItem
    let depth: Int
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var favoritesStore: FavoritesStore
    @State private var isHovered = false
    @State private var isExpanded: Bool

    init(item: FileItem, depth: Int) {
        self._item = State(initialValue: item)
        self.depth = depth
        self._isExpanded = State(initialValue: item.isExpanded)
    }

    private var isActive: Bool {
        appState.activeTab?.fileItem.url == item.url
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // Indent
                Spacer().frame(width: CGFloat(depth) * 16 + 8)

                // Expand arrow for directories
                if item.isDirectory {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 16)
                } else {
                    Spacer().frame(width: 16)
                }

                // Icon
                Image(systemName: item.isDirectory ? (isExpanded ? "folder.open" : "folder") : "doc.text")
                    .font(.system(size: 12))
                    .foregroundStyle(item.isDirectory ? Color.accentColor : .secondary)
                    .frame(width: 18)
                    .padding(.trailing, 4)

                // Name
                Text(item.name)
                    .font(.system(size: 13))
                    .lineLimit(1)
                    .foregroundStyle(isActive ? Color.accentColor : .primary)

                Spacer()

                // Favorite star
                if isHovered || favoritesStore.isFavorite(item.url) {
                    Button {
                        favoritesStore.toggle(item.url)
                    } label: {
                        Image(systemName: favoritesStore.isFavorite(item.url) ? "star.fill" : "star")
                            .font(.system(size: 11))
                            .foregroundStyle(favoritesStore.isFavorite(item.url) ? .yellow : .secondary)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 8)
                }
            }
            .frame(height: 28)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isActive ? Color.accentColor.opacity(0.15) :
                          isHovered ? Color(nsColor: .quaternaryLabelColor).opacity(0.5) : Color.clear)
                    .padding(.horizontal, 4)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                if item.isDirectory {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isExpanded.toggle()
                    }
                } else {
                    appState.openFile(item)
                }
            }
            .onHover { isHovered = $0 }
            .contextMenu {
                Button(favoritesStore.isFavorite(item.url) ? "Remove from Favorites" : "Add to Favorites") {
                    favoritesStore.toggle(item.url)
                }
                Divider()
                Button("Reveal in Finder") {
                    NSWorkspace.shared.selectFile(item.url.path, inFileViewerRootedAtPath: "")
                }
                if !item.isDirectory {
                    Button("Copy Path") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(item.url.path, forType: .string)
                    }
                }
            }

            // Children
            if item.isDirectory, isExpanded, let children = item.children {
                ForEach(children) { child in
                    FileRowView(item: child, depth: depth + 1)
                }
            }
        }
    }
}

// MARK: - Favorite Row
struct FavoriteRowView: View {
    let url: URL
    let isDirectory: Bool
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var favoritesStore: FavoritesStore
    @State private var isHovered = false

    private var name: String { url.lastPathComponent }

    private var isActive: Bool {
        appState.activeTab?.fileItem.url == url
    }

    var body: some View {
        HStack(spacing: 0) {
            Spacer().frame(width: 8)
            Spacer().frame(width: 16) // no expand arrow

            Image(systemName: isDirectory ? "folder" : "doc.text")
                .font(.system(size: 12))
                .foregroundStyle(isDirectory ? Color.accentColor : .secondary)
                .frame(width: 18)
                .padding(.trailing, 4)

            Text(name)
                .font(.system(size: 13))
                .lineLimit(1)
                .foregroundStyle(isActive ? Color.accentColor : .primary)

            Spacer()

            Image(systemName: "star.fill")
                .font(.system(size: 11))
                .foregroundStyle(.yellow)
                .padding(.trailing, 8)
        }
        .frame(height: 28)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isActive ? Color.accentColor.opacity(0.15) :
                      isHovered ? Color(nsColor: .quaternaryLabelColor).opacity(0.5) : Color.clear)
                .padding(.horizontal, 4)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if !isDirectory {
                let item = FileItem(url: url, isDirectory: false)
                appState.openFile(item)
            }
        }
        .onHover { isHovered = $0 }
        .contextMenu {
            Button("Remove from Favorites") {
                favoritesStore.remove(url)
            }
            Divider()
            Button("Reveal in Finder") {
                NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
            }
        }
    }
}
