import XCTest
@testable import Penmark

final class FileItemTests: XCTestCase {

    // MARK: - isMarkdownExtension

    func testMarkdownExtensions() {
        XCTAssertTrue(FileItem.isMarkdownExtension("md"))
        XCTAssertTrue(FileItem.isMarkdownExtension("markdown"))
        XCTAssertTrue(FileItem.isMarkdownExtension("mdown"))
        XCTAssertTrue(FileItem.isMarkdownExtension("mkd"))
    }

    func testMarkdownExtensionsCaseInsensitive() {
        XCTAssertTrue(FileItem.isMarkdownExtension("MD"))
        XCTAssertTrue(FileItem.isMarkdownExtension("Markdown"))
        XCTAssertTrue(FileItem.isMarkdownExtension("MDOWN"))
    }

    func testNonMarkdownExtensions() {
        XCTAssertFalse(FileItem.isMarkdownExtension("txt"))
        XCTAssertFalse(FileItem.isMarkdownExtension("swift"))
        XCTAssertFalse(FileItem.isMarkdownExtension("html"))
        XCTAssertFalse(FileItem.isMarkdownExtension(""))
    }

    // MARK: - FileItem.isMarkdown

    func testIsMarkdownProperty() {
        let mdFile = FileItem(url: URL(fileURLWithPath: "/tmp/test.md"), isDirectory: false)
        XCTAssertTrue(mdFile.isMarkdown)

        let txtFile = FileItem(url: URL(fileURLWithPath: "/tmp/test.txt"), isDirectory: false)
        XCTAssertFalse(txtFile.isMarkdown)

        let dir = FileItem(url: URL(fileURLWithPath: "/tmp/docs"), isDirectory: true)
        XCTAssertFalse(dir.isMarkdown)
    }

    // MARK: - FileItem equality

    func testEqualityByURL() {
        let a = FileItem(url: URL(fileURLWithPath: "/tmp/test.md"), isDirectory: false)
        let b = FileItem(url: URL(fileURLWithPath: "/tmp/test.md"), isDirectory: false)
        XCTAssertEqual(a, b)
    }

    func testInequalityByURL() {
        let a = FileItem(url: URL(fileURLWithPath: "/tmp/a.md"), isDirectory: false)
        let b = FileItem(url: URL(fileURLWithPath: "/tmp/b.md"), isDirectory: false)
        XCTAssertNotEqual(a, b)
    }

    // MARK: - FileTreeBuilder

    func testBuildFiltersNonMarkdown() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("PenmarkTest-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        // Create mixed files
        try "# Hello".write(to: tempDir.appendingPathComponent("readme.md"), atomically: true, encoding: .utf8)
        try "notes".write(to: tempDir.appendingPathComponent("notes.markdown"), atomically: true, encoding: .utf8)
        try "code".write(to: tempDir.appendingPathComponent("main.swift"), atomically: true, encoding: .utf8)
        try "data".write(to: tempDir.appendingPathComponent("data.json"), atomically: true, encoding: .utf8)

        let tree = FileTreeBuilder.build(from: tempDir)
        XCTAssertEqual(tree.count, 2)
        let names = tree.map(\.name).sorted()
        XCTAssertEqual(names, ["notes.markdown", "readme.md"])
    }

    func testBuildExcludesEmptyDirectories() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("PenmarkTest-\(UUID().uuidString)")
        let subDir = tempDir.appendingPathComponent("empty-dir")
        try FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "# Hello".write(to: tempDir.appendingPathComponent("readme.md"), atomically: true, encoding: .utf8)

        let tree = FileTreeBuilder.build(from: tempDir)
        XCTAssertEqual(tree.count, 1)
        XCTAssertEqual(tree.first?.name, "readme.md")
    }

    func testBuildSearchQuery() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("PenmarkTest-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "a".write(to: tempDir.appendingPathComponent("alpha.md"), atomically: true, encoding: .utf8)
        try "b".write(to: tempDir.appendingPathComponent("beta.md"), atomically: true, encoding: .utf8)

        let tree = FileTreeBuilder.build(from: tempDir, searchQuery: "alpha")
        XCTAssertEqual(tree.count, 1)
        XCTAssertEqual(tree.first?.name, "alpha.md")
    }
}
