import Foundation
import Testing
@testable import AgentBoard

@Suite("Terminal buffer utilities")
struct TerminalBufferTests {
    @Test("RecentLineBuffer splits chunks across ingests")
    func recentLineBufferSplitsChunksAcrossIngests() {
        var buffer = RecentLineBuffer(limit: 10)
        buffer.ingest("line one\nline ")
        #expect(buffer.lines == ["line one"])
        #expect(buffer.trailingLine == "line ")

        buffer.ingest("two\n")
        #expect(buffer.lines == ["line one", "line two"])
        #expect(buffer.trailingLine == "line two")
    }

    @Test("RecentLineBuffer enforces line limit")
    func recentLineBufferEnforcesLineLimit() {
        var buffer = RecentLineBuffer(limit: 2)
        buffer.ingest("a\nb\nc\n")
        #expect(buffer.lines == ["b", "c"])
    }

    @Test("RecentLineBuffer treats carriage return as line overwrite")
    func recentLineBufferTreatsCarriageReturnAsOverwrite() {
        var buffer = RecentLineBuffer(limit: 10)
        buffer.ingest("hello\rworld\n")
        #expect(buffer.lines == ["world"])
    }

    @Test("AnsiSanitizer strips escape sequences")
    func ansiSanitizerStripsEscapeSequences() {
        let raw = "ok\u{1B}[31mred\u{1B}[0m\n"
        #expect(AnsiSanitizer.strip(raw) == "okred\n")
    }

    @Test("AnsiSanitizer detects interactive prompts on trailing line")
    func ansiSanitizerDetectsInteractivePrompts() {
        #expect(AnsiSanitizer.looksLikePrompt("Continue? [y/N]") == true)
        #expect(AnsiSanitizer.looksLikePrompt("Password:") == true)
        #expect(AnsiSanitizer.looksLikePrompt("build finished") == false)
    }

    @Test("ScreenClearDetector returns text after last erase display")
    func screenClearDetectorReturnsTextAfterLastClear() {
        let input = "old\u{1B}[2Jnew\u{1B}[2Jafter"
        #expect(ScreenClearDetector.textAfterLastClear(input) == "after")
        #expect(ScreenClearDetector.textAfterLastClear("no clear") == nil)
    }

    @Test("UTF8StreamDecoder holds incomplete multibyte sequences")
    func utf8StreamDecoderHoldsIncompleteMultibyteSequences() {
        var decoder = UTF8StreamDecoder()
        let snowflake = "❄️"
        let bytes = Array(snowflake.utf8)
        let first = decoder.decode(bytes.prefix(bytes.count - 1))
        let second = decoder.decode(bytes.suffix(1))
        #expect(first + second == snowflake)
    }

    @Test("AttentionEvaluator signals bell and prompt only when unselected")
    func attentionEvaluatorSignalsBellAndPromptOnlyWhenUnselected() {
        #expect(AttentionEvaluator.evaluate(latestLine: "", bellPending: true, isSelected: false) == true)
        #expect(AttentionEvaluator.evaluate(latestLine: "Password:", bellPending: false, isSelected: false) == true)
        #expect(AttentionEvaluator.evaluate(latestLine: "Password:", bellPending: true, isSelected: true) == false)
        #expect(AttentionEvaluator.evaluate(latestLine: "done", bellPending: false, isSelected: false) == false)
    }
}
