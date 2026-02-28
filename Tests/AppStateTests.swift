import XCTest
@testable import Penmark

final class AppStateTests: XCTestCase {

    private func makeState() -> AppState {
        AppState(rootDirectory: nil)
    }

    private func makeFileItem(name: String = "test.md") -> FileItem {
        FileItem(url: URL(fileURLWithPath: "/tmp/\(name)"), isDirectory: false)
    }

    // MARK: - Tab Open

    func testOpenFileAddsTab() {
        let state = makeState()
        let item = makeFileItem()
        state.openFile(item)

        XCTAssertEqual(state.openTabs.count, 1)
        XCTAssertNotNil(state.activeTabID)
    }

    func testOpenFileDoesNotDuplicateTabs() {
        let state = makeState()
        let item = makeFileItem()
        state.openFile(item)
        state.openFile(item)

        XCTAssertEqual(state.openTabs.count, 1)
    }

    func testOpenFileSwitchesToExistingTab() {
        let state = makeState()
        let item1 = makeFileItem(name: "a.md")
        let item2 = makeFileItem(name: "b.md")
        state.openFile(item1)
        state.openFile(item2)
        let secondTabID = state.activeTabID

        state.openFile(item1)
        XCTAssertNotEqual(state.activeTabID, secondTabID)
        XCTAssertEqual(state.openTabs.count, 2)
    }

    func testOpenDirectoryIsIgnored() {
        let state = makeState()
        let dir = FileItem(url: URL(fileURLWithPath: "/tmp/dir"), isDirectory: true)
        state.openFile(dir)
        XCTAssertEqual(state.openTabs.count, 0)
    }

    // MARK: - Tab Close

    func testCloseTabRemovesIt() {
        let state = makeState()
        let item = makeFileItem()
        state.openFile(item)
        let tab = state.openTabs[0]

        state.closeTab(tab)
        XCTAssertEqual(state.openTabs.count, 0)
        XCTAssertNil(state.activeTabID)
    }

    func testCloseActiveTabSelectsNeighbor() {
        let state = makeState()
        state.openFile(makeFileItem(name: "a.md"))
        state.openFile(makeFileItem(name: "b.md"))
        state.openFile(makeFileItem(name: "c.md"))

        // Active is c.md (last opened)
        let middleTab = state.openTabs[1]
        state.activeTabID = middleTab.id
        state.closeTab(middleTab)

        XCTAssertEqual(state.openTabs.count, 2)
        XCTAssertNotNil(state.activeTabID)
    }

    func testCloseTabByID() {
        let state = makeState()
        state.openFile(makeFileItem())
        let tabID = state.openTabs[0].id

        state.closeTab(id: tabID)
        XCTAssertEqual(state.openTabs.count, 0)
    }

    // MARK: - Directory Display Name

    func testDirectoryDisplayNameShowsFolderName() {
        let state = AppState(rootDirectory: URL(fileURLWithPath: "/Users/test/Documents/notes"))
        XCTAssertEqual(state.directoryDisplayName, "notes")
    }

    func testDirectoryDisplayNameShowsPathForRoot() {
        let state = AppState(rootDirectory: URL(fileURLWithPath: "/"))
        XCTAssertEqual(state.directoryDisplayName, "/")
    }

    func testDirectoryDisplayNameShowsPenmarkWhenNil() {
        let state = AppState(rootDirectory: nil)
        XCTAssertEqual(state.directoryDisplayName, "Penmark")
    }
}
