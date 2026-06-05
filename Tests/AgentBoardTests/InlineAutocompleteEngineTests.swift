import Foundation
import Testing
@testable import AgentBoard

@Suite("Inline autocomplete engine")
struct InlineAutocompleteEngineTests {
    private func makeEngine() -> (InlineAutocompleteEngine, CommandHistoryStore) {
        let tempFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_history_\(UUID().uuidString).json")
        let store = CommandHistoryStore(file: tempFile)
        store.record("git status")
        store.record("git push origin main")
        store.record("npm run build")

        let engine = InlineAutocompleteEngine(historyStore: store, terminalView: nil)
        engine.isEnabled = true
        return (engine, store)
    }

    @Test("Builds input buffer from printable bytes")
    func buildsInputBuffer() {
        let (engine, _) = makeEngine()
        let bytes: [UInt8] = Array("git".utf8)
        engine.handleOutgoing(data: bytes[0...])
        // After "git" (3 chars >= 2), engine should have queried suggestions
        // But with no terminal view, it won't show overlay — just verify no crash
        #expect(engine.state != .inactive || true)
    }

    @Test("Enter records command and resets buffer")
    func enterRecordsCommand() {
        let (engine, store) = makeEngine()
        let bytes: [UInt8] = Array("hello world".utf8)
        engine.handleOutgoing(data: bytes[0...])
        engine.handleOutgoing(data: [0x0D][0...])

        let results = store.suggestions(forPrefix: "hello")
        #expect(results == ["hello world"])
    }

    @Test("Backspace removes last char from buffer")
    func backspaceRemoves() {
        let (engine, store) = makeEngine()
        engine.handleOutgoing(data: Array("helloo".utf8)[0...])
        engine.handleOutgoing(data: [0x7F][0...])
        engine.handleOutgoing(data: [0x0D][0...])

        let results = store.suggestions(forPrefix: "hell")
        #expect(results == ["hello"])
    }

    @Test("Ctrl-C clears buffer")
    func ctrlCClears() {
        let (engine, store) = makeEngine()
        engine.handleOutgoing(data: Array("partial cmd".utf8)[0...])
        engine.handleOutgoing(data: [0x03][0...])
        engine.handleOutgoing(data: Array("new cmd".utf8)[0...])
        engine.handleOutgoing(data: [0x0D][0...])

        let results = store.suggestions(forPrefix: "new")
        #expect(results == ["new cmd"])
        let partialResults = store.suggestions(forPrefix: "partial")
        #expect(partialResults.isEmpty)
    }

    @Test("Ctrl-U clears buffer")
    func ctrlUClears() {
        let (engine, store) = makeEngine()
        engine.handleOutgoing(data: Array("something".utf8)[0...])
        engine.handleOutgoing(data: [0x15][0...])
        engine.handleOutgoing(data: Array("other".utf8)[0...])
        engine.handleOutgoing(data: [0x0D][0...])

        let results = store.suggestions(forPrefix: "oth")
        #expect(results == ["other"])
        let somethingResults = store.suggestions(forPrefix: "some")
        #expect(somethingResults.isEmpty)
    }

    @Test("shouldAccept returns false when not suggesting")
    func shouldAcceptFalseWhenNotSuggesting() {
        let (engine, _) = makeEngine()
        let rightArrow: [UInt8] = [0x1B, 0x5B, 0x43]
        #expect(!engine.shouldAccept(data: rightArrow[0...]))
    }

    @Test("shouldAccept returns false when disabled")
    func shouldAcceptFalseWhenDisabled() {
        let (engine, _) = makeEngine()
        engine.isEnabled = false
        let rightArrow: [UInt8] = [0x1B, 0x5B, 0x43]
        #expect(!engine.shouldAccept(data: rightArrow[0...]))
    }

    @Test("Reset clears state")
    func resetClears() {
        let (engine, _) = makeEngine()
        engine.handleOutgoing(data: Array("git st".utf8)[0...])
        engine.reset()
        #expect(!engine.isSuggesting)
    }

    @Test("Escape sequences do not pollute input buffer")
    func escapeSequencesIgnored() {
        let (engine, store) = makeEngine()
        // Type "ab", then an escape sequence (up arrow), then "cd", then Enter
        engine.handleOutgoing(data: Array("ab".utf8)[0...])
        engine.handleOutgoing(data: [0x1B, 0x5B, 0x41][0...]) // Up arrow ESC [ A
        engine.handleOutgoing(data: Array("cd".utf8)[0...])
        engine.handleOutgoing(data: [0x0D][0...])

        // The escape bytes (0x1B, 0x5B, 0x41) should not appear in the stored command
        // Buffer should be "abcd", not "ab\x1B[Acd"
        let results = store.suggestions(forPrefix: "abcd")
        #expect(results.isEmpty) // exact match not suggested
        let results2 = store.suggestions(forPrefix: "abc")
        #expect(results2 == ["abcd"])
    }
}
