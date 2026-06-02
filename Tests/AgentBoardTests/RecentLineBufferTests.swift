import XCTest
@testable import AgentBoard

final class RecentLineBufferTests: XCTestCase {
    // MARK: - AnsiSanitizer

    func testSanitizerPreservesCarriageReturn() {
        let input = "hello\rworld\n"
        let result = AnsiSanitizer.strip(input)
        XCTAssertTrue(result.contains("\r"))
        XCTAssertTrue(result.contains("\n"))
    }

    func testSanitizerStripsC0ButKeepsTabNewlineCR() {
        let input = "a\u{01}b\tc\nd\re\u{07}f"
        let result = AnsiSanitizer.strip(input)
        XCTAssertEqual(result, "ab\tc\nd\ref")
    }

    func testSanitizerStripsAnsiSequences() {
        let input = "\u{1B}[32mgreen\u{1B}[0m plain"
        let result = AnsiSanitizer.strip(input)
        XCTAssertEqual(result, "green plain")
    }

    // MARK: - RecentLineBuffer \r handling

    func testIngestStandaloneCROverwritesPartial() {
        var buf = RecentLineBuffer(limit: 10)
        buf.ingest("hello\rworld\n")
        XCTAssertEqual(buf.lines, ["world"])
    }

    func testIngestCRLFTreatedAsNewline() {
        var buf = RecentLineBuffer(limit: 10)
        buf.ingest("line1\r\nline2\r\n")
        XCTAssertEqual(buf.lines, ["line1", "line2"])
    }

    func testIngestMultipleCRsKeepsLastSegment() {
        var buf = RecentLineBuffer(limit: 10)
        buf.ingest("aaa\rbbb\rccc\n")
        XCTAssertEqual(buf.lines, ["ccc"])
    }

    func testIngestCRInPartialAcrossChunks() {
        var buf = RecentLineBuffer(limit: 10)
        buf.ingest("hello")
        XCTAssertEqual(buf.trailingLine, "hello")
        buf.ingest("\rworld")
        XCTAssertEqual(buf.trailingLine, "world")
    }

    func testIngestCRAtEndOfPartial() {
        var buf = RecentLineBuffer(limit: 10)
        buf.ingest("old\r")
        XCTAssertEqual(buf.trailingLine, "")
        buf.ingest("new\n")
        XCTAssertEqual(buf.lines, ["new"])
    }

    // MARK: - ScreenClearDetector

    func testScreenClearDetectorReturnsTextAfterLastClear() {
        let input = "stale\u{1B}[2Jfresh content"
        let result = ScreenClearDetector.textAfterLastClear(input)
        XCTAssertEqual(result, "fresh content")
    }

    func testScreenClearDetectorReturnsNilWhenAbsent() {
        let result = ScreenClearDetector.textAfterLastClear("no clear here")
        XCTAssertNil(result)
    }

    func testScreenClearDetectorUsesLastOccurrence() {
        let input = "a\u{1B}[2Jb\u{1B}[2Jc"
        let result = ScreenClearDetector.textAfterLastClear(input)
        XCTAssertEqual(result, "c")
    }

    // MARK: - End-to-end: TUI redraw -> clean snapshot

    func testTUIRedrawProducesCleanSnapshot() {
        var buf = RecentLineBuffer(limit: 10)
        let stripped = AnsiSanitizer.strip("\u{1B}[32mopencode\u{1B}[0m\rOpenCode v1.0\n")
        buf.ingest(stripped)
        XCTAssertEqual(buf.lines, ["OpenCode v1.0"])
    }

    func testScreenClearThenRedraw() {
        var buf = RecentLineBuffer(limit: 10)
        buf.ingest("old line 1\n")
        buf.ingest("old line 2\n")

        let raw = "stale\u{1B}[2Jfresh line\n"
        if let afterClear = ScreenClearDetector.textAfterLastClear(raw) {
            buf.clear()
            buf.ingest(AnsiSanitizer.strip(afterClear))
        }
        XCTAssertEqual(buf.lines, ["fresh line"])
    }
}
