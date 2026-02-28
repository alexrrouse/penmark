import XCTest
@testable import Penmark

final class MarkdownRendererTests: XCTestCase {
    private let renderer = MarkdownRenderer()

    // MARK: - Inline Processing

    func testBoldWithAsterisks() {
        let html = renderer.renderHTML("**bold**", isDark: false)
        XCTAssertTrue(html.contains("<strong>bold</strong>"))
    }

    func testBoldWithUnderscores() {
        let html = renderer.renderHTML("__bold__", isDark: false)
        XCTAssertTrue(html.contains("<strong>bold</strong>"))
    }

    func testItalicWithAsterisks() {
        let html = renderer.renderHTML("*italic*", isDark: false)
        XCTAssertTrue(html.contains("<em>italic</em>"))
    }

    func testItalicWithUnderscores() {
        let html = renderer.renderHTML("_italic_", isDark: false)
        XCTAssertTrue(html.contains("<em>italic</em>"))
    }

    func testBoldItalic() {
        let html = renderer.renderHTML("***bolditalic***", isDark: false)
        XCTAssertTrue(html.contains("<strong><em>bolditalic</em></strong>"))
    }

    func testInlineCode() {
        let html = renderer.renderHTML("`code`", isDark: false)
        XCTAssertTrue(html.contains("<code>code</code>"))
    }

    func testInlineCodeWithHTMLEscaping() {
        let html = renderer.renderHTML("`<div>`", isDark: false)
        XCTAssertTrue(html.contains("<code>&lt;div&gt;</code>"))
    }

    func testLink() {
        let html = renderer.renderHTML("[text](https://example.com)", isDark: false)
        XCTAssertTrue(html.contains("<a href=\"https://example.com\">text</a>"))
    }

    func testImage() {
        let html = renderer.renderHTML("![alt](image.png)", isDark: false)
        XCTAssertTrue(html.contains("<img src=\"image.png\" alt=\"alt\""))
    }

    func testStrikethrough() {
        let html = renderer.renderHTML("~~deleted~~", isDark: false)
        XCTAssertTrue(html.contains("<del>deleted</del>"))
    }

    // MARK: - Block-Level Parsing

    func testHeadings() {
        for level in 1...6 {
            let prefix = String(repeating: "#", count: level)
            let html = renderer.renderHTML("\(prefix) Heading \(level)", isDark: false)
            XCTAssertTrue(html.contains("<h\(level)>Heading \(level)</h\(level)>"), "Failed for h\(level)")
        }
    }

    func testUnorderedList() {
        let md = "- item one\n- item two\n- item three"
        let html = renderer.renderHTML(md, isDark: false)
        XCTAssertTrue(html.contains("<ul>"))
        XCTAssertTrue(html.contains("<li>item one</li>"))
        XCTAssertTrue(html.contains("<li>item two</li>"))
        XCTAssertTrue(html.contains("<li>item three</li>"))
        XCTAssertTrue(html.contains("</ul>"))
    }

    func testOrderedList() {
        let md = "1. first\n2. second"
        let html = renderer.renderHTML(md, isDark: false)
        XCTAssertTrue(html.contains("<ol>"))
        XCTAssertTrue(html.contains("<li>first</li>"))
        XCTAssertTrue(html.contains("<li>second</li>"))
        XCTAssertTrue(html.contains("</ol>"))
    }

    func testFencedCodeBlock() {
        let md = "```swift\nlet x = 1\n```"
        let html = renderer.renderHTML(md, isDark: false)
        XCTAssertTrue(html.contains("<pre><code class=\"language-swift\">"))
        XCTAssertTrue(html.contains("let x = 1"))
        XCTAssertTrue(html.contains("</code></pre>"))
    }

    func testFencedCodeBlockWithoutLanguage() {
        let md = "```\nhello\n```"
        let html = renderer.renderHTML(md, isDark: false)
        XCTAssertTrue(html.contains("<pre><code>hello</code></pre>"))
    }

    func testBlockquote() {
        let md = "> quoted text"
        let html = renderer.renderHTML(md, isDark: false)
        XCTAssertTrue(html.contains("<blockquote>"))
        XCTAssertTrue(html.contains("quoted text"))
        XCTAssertTrue(html.contains("</blockquote>"))
    }

    func testTable() {
        let md = "| A | B |\n| --- | --- |\n| 1 | 2 |"
        let html = renderer.renderHTML(md, isDark: false)
        XCTAssertTrue(html.contains("<table>"))
        XCTAssertTrue(html.contains("<th>A</th>"))
        XCTAssertTrue(html.contains("<th>B</th>"))
        XCTAssertTrue(html.contains("<td>1</td>"))
        XCTAssertTrue(html.contains("<td>2</td>"))
        XCTAssertTrue(html.contains("</table>"))
    }

    func testHorizontalRule() {
        let html = renderer.renderHTML("---", isDark: false)
        XCTAssertTrue(html.contains("<hr>"))
    }

    func testHorizontalRuleWithAsterisks() {
        let html = renderer.renderHTML("***", isDark: false)
        XCTAssertTrue(html.contains("<hr>"))
    }

    func testParagraph() {
        let html = renderer.renderHTML("Hello world", isDark: false)
        XCTAssertTrue(html.contains("<p>Hello world</p>"))
    }

    // MARK: - HTML Escaping

    func testHTMLEscapingInParagraph() {
        let html = renderer.renderHTML("<script>alert('xss')</script>", isDark: false)
        XCTAssertFalse(html.contains("<script>alert"))
        XCTAssertTrue(html.contains("&lt;script&gt;"))
    }

    // MARK: - Search Highlighting

    func testSearchHighlightingIncludesScript() {
        let html = renderer.renderHTML("Hello world", isDark: false, searchQuery: "world")
        XCTAssertTrue(html.contains("highlightSearch"))
        XCTAssertTrue(html.contains("world"))
    }

    func testNoSearchHighlightingWithoutQuery() {
        let html = renderer.renderHTML("Hello world", isDark: false, searchQuery: "")
        XCTAssertFalse(html.contains("window.addEventListener('load'"))
    }

    // MARK: - Dark Mode

    func testDarkModeUsesCorrectBackground() {
        let dark = renderer.renderHTML("test", isDark: true)
        let light = renderer.renderHTML("test", isDark: false)
        XCTAssertTrue(dark.contains("#1e1e1e"))
        XCTAssertTrue(light.contains("#ffffff"))
    }
}
