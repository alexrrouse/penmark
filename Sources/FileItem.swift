import Foundation

struct FileItem: Identifiable, Hashable {
    let id: UUID
    let url: URL
    let name: String
    let isDirectory: Bool
    var children: [FileItem]?
    var isExpanded: Bool

    init(url: URL, isDirectory: Bool, children: [FileItem]? = nil) {
        self.id = UUID()
        self.url = url
        self.name = url.lastPathComponent
        self.isDirectory = isDirectory
        self.children = children
        self.isExpanded = false
    }

    var isMarkdown: Bool {
        FileItem.isMarkdownExtension(url.pathExtension)
    }

    static func isMarkdownExtension(_ ext: String) -> Bool {
        let lower = ext.lowercased()
        return lower == "md" || lower == "markdown" || lower == "mdown" || lower == "mkd"
    }

    static func == (lhs: FileItem, rhs: FileItem) -> Bool {
        lhs.url == rhs.url
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
}

// MARK: - File Tree Builder
enum FileTreeBuilder {
    static func build(from rootURL: URL, searchQuery: String = "") -> [FileItem] {
        buildItems(from: rootURL, searchQuery: searchQuery.lowercased())
    }

    private static func buildItems(from url: URL, searchQuery: String) -> [FileItem] {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .isHiddenKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var items: [FileItem] = []

        let sorted = contents.sorted { a, b in
            let aIsDir = (try? a.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            let bIsDir = (try? b.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            if aIsDir != bIsDir { return aIsDir }
            return a.lastPathComponent.localizedStandardCompare(b.lastPathComponent) == .orderedAscending
        }

        for itemURL in sorted {
            let isDir = (try? itemURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false

            if isDir {
                let children = buildItems(from: itemURL, searchQuery: searchQuery)
                // Only include directories that contain markdown files (recursively)
                if !children.isEmpty {
                    var dir = FileItem(url: itemURL, isDirectory: true, children: children)
                    if !searchQuery.isEmpty {
                        dir.isExpanded = true
                    }
                    items.append(dir)
                }
            } else {
                let isMarkdown = FileItem.isMarkdownExtension(itemURL.pathExtension)
                guard isMarkdown else { continue }

                let fullName = itemURL.lastPathComponent.lowercased()
                let baseName = itemURL.deletingPathExtension().lastPathComponent.lowercased()
                if searchQuery.isEmpty || fullName.contains(searchQuery) || baseName.contains(searchQuery) {
                    items.append(FileItem(url: itemURL, isDirectory: false))
                }
            }
        }

        return items
    }
}
