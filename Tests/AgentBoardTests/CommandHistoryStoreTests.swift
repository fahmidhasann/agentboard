import Foundation
import Testing
@testable import AgentBoard

@Suite("Command history store")
struct CommandHistoryStoreTests {
    private func makeStore() -> CommandHistoryStore {
        let tempFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_history_\(UUID().uuidString).json")
        return CommandHistoryStore(file: tempFile)
    }

    @Test("Records and suggests commands by prefix")
    func recordsAndSuggests() {
        let store = makeStore()
        store.record("git status")
        store.record("git push")
        store.record("git status")

        let results = store.suggestions(forPrefix: "git s")
        #expect(results == ["git status"])
    }

    @Test("Returns suggestions sorted by frequency")
    func sortsByFrequency() {
        let store = makeStore()
        store.record("npm install")
        store.record("npm run build")
        store.record("npm run build")
        store.record("npm run build")
        store.record("npm install")

        let results = store.suggestions(forPrefix: "npm")
        #expect(results.first == "npm run build")
    }

    @Test("Ignores commands shorter than 2 chars")
    func ignoresShortCommands() {
        let store = makeStore()
        store.record("x")
        store.record("")
        store.record("  ")

        let results = store.suggestions(forPrefix: "x")
        #expect(results.isEmpty)
    }

    @Test("Requires minimum 2 char prefix for suggestions")
    func requiresMinPrefix() {
        let store = makeStore()
        store.record("git status")

        let results = store.suggestions(forPrefix: "g")
        #expect(results.isEmpty)
    }

    @Test("Does not suggest exact match")
    func noExactMatch() {
        let store = makeStore()
        store.record("git status")

        let results = store.suggestions(forPrefix: "git status")
        #expect(results.isEmpty)
    }

    @Test("Case insensitive prefix matching")
    func caseInsensitive() {
        let store = makeStore()
        store.record("Git Status")

        let results = store.suggestions(forPrefix: "git")
        #expect(results == ["Git Status"])
    }

    @Test("Evicts lowest frequency when over capacity")
    func eviction() {
        let tempFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_history_\(UUID().uuidString).json")
        let store = CommandHistoryStore(file: tempFile)

        for i in 0..<1005 {
            store.record("command_\(i)_padding")
        }
        store.record("keep_me_please")
        store.record("keep_me_please")

        let results = store.suggestions(forPrefix: "keep")
        #expect(!results.isEmpty)
    }
}
