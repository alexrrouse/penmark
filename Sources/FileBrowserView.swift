import SwiftUI

struct FileBrowserView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var favoritesStore: FavoritesStore
    @FocusState private var isFileListFocused: Bool

    private var favItems: [URL] {
        guard let root = appState.rootDirectory else { return [] }
        return favoritesStore.favorites(under: root)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 13))
                TextField("Filter files…", text: $appState.fileSearchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                if !appState.fileSearchQuery.isEmpty {
                    Button {
                        appState.fileSearchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Color(nsColor: .controlBackgroundColor))
            .overlay(Divider(), alignment: .bottom)

            if appState.rootDirectory == nil {
                NoFolderView()
            } else {
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
                .focusable()
                .focused($isFileListFocused)
                .onKeyPress(.upArrow) {
                    appState.selectPreviousFile()
                    return .handled
                }
                .onKeyPress(.downArrow) {
                    appState.selectNextFile()
                    return .handled
                }
                .onKeyPress(.return) {
                    appState.openSelectedFile()
                    return .handled
                }
                .onKeyPress(.rightArrow) {
                    appState.expandSelectedDirectory()
                    return .handled
                }
                .onKeyPress(.leftArrow) {
                    appState.collapseSelectedDirectory()
                    return .handled
                }
            }
        }
        .onAppear {
            isFileListFocused = true
        }
    }
}

struct NoFolderView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "folder")
                .font(.system(size: 36))
                .foregroundStyle(.tertiary)
            Text("No Folder Open")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            Button("Open Folder…") {
                let panel = NSOpenPanel()
                panel.canChooseFiles = false
                panel.canChooseDirectories = true
                panel.allowsMultipleSelection = false
                panel.prompt = "Open"
                if panel.runModal() == .OK, let url = panel.url {
                    appState.changeDirectory(to: url)
                }
            }
            .controlSize(.small)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.tertiary)
            .textCase(.uppercase)
            .tracking(0.8)
            .padding(.horizontal, 14)
            .padding(.top, 16)
            .padding(.bottom, 5)
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

    init(item: FileItem, depth: Int) {
        self._item = State(initialValue: item)
        self.depth = depth
    }

    private var isExpanded: Bool {
        appState.expandedDirectories.contains(item.url)
    }

    private var isActive: Bool {
        appState.activeTab?.fileItem.url == item.url
    }

    private var isSelected: Bool {
        appState.selectedFileURL == item.url
    }

    private var rowBackground: Color {
        if isActive {
            return Color.accentColor.opacity(0.12)
        } else if isSelected {
            return Color.accentColor.opacity(0.08)
        } else if isHovered {
            return Color(nsColor: .labelColor).opacity(0.07)
        }
        return Color.clear
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // Indent
                Spacer().frame(width: CGFloat(depth) * 18 + 10)

                // Expand arrow for directories
                if item.isDirectory {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.tertiary)
                        .frame(width: 14)
                        .padding(.trailing, 3)
                } else {
                    Spacer().frame(width: 17)
                }

                // Icon
                Image(systemName: item.isDirectory ? (isExpanded ? "folder.open.fill" : "folder.fill") : "doc.text.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(item.isDirectory ? Color.accentColor : Color(nsColor: .secondaryLabelColor))
                    .frame(width: 20)
                    .padding(.trailing, 6)

                // Name
                Text(item.name)
                    .font(.system(size: 13))
                    .lineLimit(1)
                    .foregroundStyle(isActive ? Color.accentColor : Color.primary)

                Spacer(minLength: 8)

                // Favorite star
                if isHovered || favoritesStore.isFavorite(item.url) {
                    Button {
                        favoritesStore.toggle(item.url)
                    } label: {
                        Image(systemName: favoritesStore.isFavorite(item.url) ? "star.fill" : "star")
                            .font(.system(size: 11))
                            .foregroundStyle(favoritesStore.isFavorite(item.url) ? Color.yellow : Color(nsColor: .tertiaryLabelColor))
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 10)
                }
            }
            .frame(height: 30)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(rowBackground)
                    .padding(.horizontal, 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(Color.accentColor.opacity(isSelected ? 0.4 : 0), lineWidth: 1)
                    .padding(.horizontal, 6)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                appState.selectedFileURL = item.url
                if item.isDirectory {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        if isExpanded {
                            appState.expandedDirectories.remove(item.url)
                        } else {
                            appState.expandedDirectories.insert(item.url)
                        }
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
            Spacer().frame(width: 10)
            Spacer().frame(width: 17) // align with file rows (no expand arrow)

            Image(systemName: isDirectory ? "folder.fill" : "doc.text.fill")
                .font(.system(size: 13))
                .foregroundStyle(isDirectory ? Color.accentColor : Color(nsColor: .secondaryLabelColor))
                .frame(width: 20)
                .padding(.trailing, 6)

            Text(name)
                .font(.system(size: 13))
                .lineLimit(1)
                .foregroundStyle(isActive ? Color.accentColor : Color.primary)

            Spacer(minLength: 8)

            Image(systemName: "star.fill")
                .font(.system(size: 11))
                .foregroundStyle(Color.yellow)
                .padding(.trailing, 10)
        }
        .frame(height: 30)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(isActive ? Color.accentColor.opacity(0.12) :
                      isHovered ? Color(nsColor: .labelColor).opacity(0.07) : Color.clear)
                .padding(.horizontal, 6)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if isDirectory {
                appState.changeDirectory(to: url)
            } else {
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
