import Testing
@testable import AgentBoard

// MARK: - AnsiSanitizer

@Test
func sanitizerPreservesCarriageReturn() {
    let input = "hello\rworld\n"
    let result = AnsiSanitizer.strip(input)
    #expect(result.contains("\r"))
    #expect(result.contains("\n"))
}

@Test
func sanitizerStripsC0ButKeepsTabNewlineCR() {
    let input = "a\u{01}b\tc\nd\re\u{07}f"
    let result = AnsiSanitizer.strip(input)
    #expect(result == "ab\tc\nd\ref")
}

@Test
func sanitizerStripsAnsiSequences() {
    let input = "\u{1B}[32mgreen\u{1B}[0m plain"
    let result = AnsiSanitizer.strip(input)
    #expect(result == "green plain")
}

// MARK: - RecentLineBuffer \r handling

@Test
func ingestStandaloneCROverwritesPartial() {
    var buf = RecentLineBuffer(limit: 10)
    buf.ingest("hello\rworld\n")
    #expect(buf.lines == ["world"])
}

@Test
func ingestCRLFTreatedAsNewline() {
    var buf = RecentLineBuffer(limit: 10)
    buf.ingest("line1\r\nline2\r\n")
    #expect(buf.lines == ["line1", "line2"])
}

@Test
func ingestMultipleCRsKeepsLastSegment() {
    var buf = RecentLineBuffer(limit: 10)
    buf.ingest("aaa\rbbb\rccc\n")
    #expect(buf.lines == ["ccc"])
}

@Test
func ingestCRInPartialAcrossChunks() {
    var buf = RecentLineBuffer(limit: 10)
    buf.ingest("hello")
    #expect(buf.trailingLine == "hello")
    buf.ingest("\rworld")
    #expect(buf.trailingLine == "world")
}

@Test
func ingestCRAtEndOfPartial() {
    var buf = RecentLineBuffer(limit: 10)
    buf.ingest("old\r")
    #expect(buf.trailingLine == "")
    buf.ingest("new\n")
    #expect(buf.lines == ["new"])
}

// MARK: - ScreenClearDetector

@Test
func screenClearDetectorReturnsTextAfterLastClear() {
    let input = "stale\u{1B}[2Jfresh content"
    let result = ScreenClearDetector.textAfterLastClear(input)
    #expect(result == "fresh content")
}

@Test
func screenClearDetectorReturnsNilWhenAbsent() {
    let result = ScreenClearDetector.textAfterLastClear("no clear here")
    #expect(result == nil)
}

@Test
func screenClearDetectorUsesLastOccurrence() {
    let input = "a\u{1B}[2Jb\u{1B}[2Jc"
    let result = ScreenClearDetector.textAfterLastClear(input)
    #expect(result == "c")
}

// MARK: - End-to-end: TUI redraw → clean snapshot

@Test
func tuiRedrawProducesCleanSnapshot() {
    var buf = RecentLineBuffer(limit: 10)
    let stripped = AnsiSanitizer.strip("\u{1B}[32mopencode\u{1B}[0m\rOpenCode v1.0\n")
    buf.ingest(stripped)
    #expect(buf.lines == ["OpenCode v1.0"])
}

@Test
func screenClearThenRedraw() {
    var buf = RecentLineBuffer(limit: 10)
    buf.ingest("old line 1\n")
    buf.ingest("old line 2\n")

    let raw = "stale\u{1B}[2Jfresh line\n"
    if let afterClear = ScreenClearDetector.textAfterLastClear(raw) {
        buf.clear()
        buf.ingest(AnsiSanitizer.strip(afterClear))
    }
    #expect(buf.lines == ["fresh line"])
}
