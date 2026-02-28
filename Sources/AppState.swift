import SwiftUI

// MARK: - View Mode
enum ViewMode: String, CaseIterable {
    case rendered = "Rendered"
    case raw = "Raw"
}

// MARK: - App Color Scheme
enum AppColorScheme: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - File Tab
struct FileTab: Identifiable, Equatable {
    let id: UUID
    let fileItem: FileItem
    var content: String

    init(fileItem: FileItem) {
        self.id = UUID()
        self.fileItem = fileItem
        self.content = (try? String(contentsOf: fileItem.url, encoding: .utf8)) ?? ""
    }

    static func == (lhs: FileTab, rhs: FileTab) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - AppState
final class AppState: ObservableObject {
    @Published var rootDirectory: URL? {
        didSet { rebuildFileTree() }
    }

    @Published var fileTree: [FileItem] = []
    @Published var openTabs: [FileTab] = []
    @Published var activeTabID: UUID?
    @Published var viewMode: ViewMode = .rendered
    @Published var appColorScheme: AppColorScheme = .system
    @Published var fileSearchQuery: String = "" {
        didSet { rebuildFileTree() }
    }
    @Published var contentSearchQuery: String = ""
    @Published var isContentSearchVisible: Bool = false
    @Published var sidebarWidth: CGFloat = 260

    private var rebuildWorkItem: DispatchWorkItem?

    init(rootDirectory: URL?) {
        self.rootDirectory = rootDirectory
        rebuildFileTree()
    }

    func changeDirectory(to url: URL) {
        rootDirectory = url
        openTabs = []
        activeTabID = nil
        fileSearchQuery = ""
    }

    var activeTab: FileTab? {
        guard let id = activeTabID else { return nil }
        return openTabs.first(where: { $0.id == id })
    }

    func openFile(_ item: FileItem) {
        guard !item.isDirectory, item.isMarkdown else { return }

        // Switch to existing tab if already open
        if let existing = openTabs.first(where: { $0.fileItem.url == item.url }) {
            activeTabID = existing.id
            return
        }

        let tab = FileTab(fileItem: item)
        openTabs.append(tab)
        activeTabID = tab.id
    }

    func closeTab(_ tab: FileTab) {
        guard let idx = openTabs.firstIndex(of: tab) else { return }
        openTabs.remove(at: idx)

        if activeTabID == tab.id {
            if openTabs.isEmpty {
                activeTabID = nil
            } else {
                let newIdx = min(idx, openTabs.count - 1)
                activeTabID = openTabs[newIdx].id
            }
        }
    }

    func closeTab(id: UUID) {
        if let tab = openTabs.first(where: { $0.id == id }) {
            closeTab(tab)
        }
    }

    func reloadActiveTab() {
        guard let id = activeTabID,
              let idx = openTabs.firstIndex(where: { $0.id == id }) else { return }
        openTabs[idx].content = (try? String(contentsOf: openTabs[idx].fileItem.url, encoding: .utf8)) ?? ""
    }

    func rebuildFileTree() {
        rebuildWorkItem?.cancel()
        guard let root = rootDirectory else {
            fileTree = []
            return
        }
        let query = fileSearchQuery
        let workItem = DispatchWorkItem { [weak self] in
            let tree = FileTreeBuilder.build(from: root, searchQuery: query)
            DispatchQueue.main.async {
                self?.fileTree = tree
            }
        }
        rebuildWorkItem = workItem
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.15, execute: workItem)
    }

    var directoryDisplayName: String {
        guard let url = rootDirectory else { return "Penmark" }
        let name = url.lastPathComponent
        return (name.isEmpty || name == "/") ? url.path : name
    }
}
