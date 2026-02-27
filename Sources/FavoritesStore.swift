import Foundation
import Combine

final class FavoritesStore: ObservableObject {
    static let shared = FavoritesStore()

    @Published private(set) var favorites: Set<URL> = []

    private let defaultsKey = "com.penmark.favorites"

    private init() {
        load()
    }

    func isFavorite(_ url: URL) -> Bool {
        favorites.contains(url)
    }

    func toggle(_ url: URL) {
        if favorites.contains(url) {
            favorites.remove(url)
        } else {
            favorites.insert(url)
        }
        save()
    }

    func add(_ url: URL) {
        favorites.insert(url)
        save()
    }

    func remove(_ url: URL) {
        favorites.remove(url)
        save()
    }

    // Returns favorites that exist within a given root directory
    func favorites(under rootURL: URL) -> [URL] {
        favorites
            .filter { $0.path.hasPrefix(rootURL.path) }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
    }

    private func save() {
        let paths = favorites.map(\.path)
        UserDefaults.standard.set(paths, forKey: defaultsKey)
    }

    private func load() {
        let paths = UserDefaults.standard.stringArray(forKey: defaultsKey) ?? []
        favorites = Set(paths.compactMap { path -> URL? in
            let url = URL(fileURLWithPath: path)
            return FileManager.default.fileExists(atPath: path) ? url : nil
        })
    }
}
