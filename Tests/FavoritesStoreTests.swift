import XCTest
@testable import Penmark

final class FavoritesStoreTests: XCTestCase {
    private var store: FavoritesStore!

    override func setUp() {
        super.setUp()
        store = FavoritesStore.shared
    }

    // MARK: - Path Prefix Filtering

    func testFavoritesUnderDoesNotFalseMatchSiblingDirectories() {
        let docs = URL(fileURLWithPath: "/tmp/docs")
        let docsBackup = URL(fileURLWithPath: "/tmp/docs-backup/file.md")

        // Add a favorite under a sibling directory
        if !store.isFavorite(docsBackup) {
            store.toggle(docsBackup)
        }
        defer { if store.isFavorite(docsBackup) { store.toggle(docsBackup) } }

        let results = store.favorites(under: docs)
        let paths = results.map(\.path)
        XCTAssertFalse(paths.contains(docsBackup.path),
                       "favorites(under: /tmp/docs) should not match /tmp/docs-backup/")
    }

    func testFavoritesUnderMatchesChildPaths() {
        let root = URL(fileURLWithPath: "/tmp/test-favs-\(UUID().uuidString)")
        let child = root.appendingPathComponent("child.md")

        if !store.isFavorite(child) {
            store.toggle(child)
        }
        defer { if store.isFavorite(child) { store.toggle(child) } }

        let results = store.favorites(under: root)
        XCTAssertTrue(results.contains(child))
    }

    // MARK: - Toggle

    func testToggleAddsAndRemoves() {
        let url = URL(fileURLWithPath: "/tmp/toggle-test-\(UUID().uuidString).md")
        XCTAssertFalse(store.isFavorite(url))

        store.toggle(url)
        XCTAssertTrue(store.isFavorite(url))

        store.toggle(url)
        XCTAssertFalse(store.isFavorite(url))
    }

    // MARK: - Remove

    func testRemove() {
        let url = URL(fileURLWithPath: "/tmp/remove-test-\(UUID().uuidString).md")
        store.toggle(url) // add
        XCTAssertTrue(store.isFavorite(url))

        store.remove(url)
        XCTAssertFalse(store.isFavorite(url))
    }
}
