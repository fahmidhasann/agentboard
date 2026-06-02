import Foundation
import Testing
@testable import AgentBoard

@Test func renameTrimsWhitespace() {
    let store = makeStore()
    let session = makeSession(summary: "Original")
    store.sessions = [session]

    store.setSummary(id: session.id, "  Renamed Session  ")

    #expect(store.session(id: session.id)?.summary == "Renamed Session")
    #expect(store.session(id: session.id)?.isSummaryUserEdited == true)
}

@Test func emptyRenameKeepsExistingSummary() {
    let store = makeStore()
    let session = makeSession(summary: "Original")
    store.sessions = [session]

    store.setSummary(id: session.id, "   ")

    #expect(store.session(id: session.id)?.summary == "Original")
    #expect(store.session(id: session.id)?.isSummaryUserEdited == true)
}

@Test func cwdUpdateDecodesFileURL() {
    let store = makeStore()
    let session = makeSession(cwd: "/tmp")
    store.sessions = [session]

    store.updateCwd(id: session.id, "file:///tmp/AgentBoard%20Folder")

    #expect(store.session(id: session.id)?.cwd == "/tmp/AgentBoard Folder")
}

@Test func corruptSessionsFileLoadsEmptyAndCreatesBackup() throws {
    let directory = try temporaryDirectory()
    let sessionsFile = directory.appendingPathComponent("sessions.json")
    try Data("not json".utf8).write(to: sessionsFile)

    let store = SessionStore(directory: directory)

    #expect(store.sessions.isEmpty)
    let backups = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        .filter { $0.hasPrefix("sessions.corrupt-") && $0.hasSuffix(".json") }
    #expect(backups.count == 1)
}

@Test func saveTrimsPersistedTailToLimit() throws {
    let directory = try temporaryDirectory()
    let store = SessionStore(directory: directory, tailLimit: 2)
    let session = makeSession(recentTail: ["one", "two", "three"])
    store.sessions = [session]

    store.saveNow()

    let data = try Data(contentsOf: directory.appendingPathComponent("sessions.json"))
    let decoded = try JSONDecoder().decode([AgentSession].self, from: data)
    #expect(decoded.first?.recentTail == ["two", "three"])
}

@Test func recentLineBufferUpdateLimitTrimsExistingLines() {
    var buffer = RecentLineBuffer(limit: 5)
    buffer.ingest("one\ntwo\nthree\nfour\n")

    buffer.updateLimit(2)

    #expect(buffer.lines == ["three", "four"])
}

@Test func requestCloseCanDeferOrCloseImmediately() {
    let store = makeStore()
    let deferred = makeSession(summary: "Deferred")
    store.sessions = [deferred]

    store.requestCloseSession(id: deferred.id, confirmClose: true)

    #expect(store.pendingCloseID == deferred.id)
    #expect(store.sessions.contains { $0.id == deferred.id })

    store.confirmPendingClose()

    #expect(store.pendingCloseID == nil)
    #expect(!store.sessions.contains { $0.id == deferred.id })

    let immediate = makeSession(summary: "Immediate")
    store.sessions = [immediate]
    store.requestCloseSession(id: immediate.id, confirmClose: false)

    #expect(!store.sessions.contains { $0.id == immediate.id })
}

private func makeStore(tailLimit: Int = 500) -> SessionStore {
    SessionStore(directory: temporaryDirectoryPath(), tailLimit: tailLimit)
}

private func makeSession(
    summary: String = "Session",
    cwd: String = NSTemporaryDirectory(),
    recentTail: [String] = []
) -> AgentSession {
    AgentSession(
        summary: summary,
        agentLabel: "Shell",
        cwd: cwd,
        shellPath: "/bin/zsh",
        recentTail: recentTail
    )
}

private func temporaryDirectory() throws -> URL {
    let url = temporaryDirectoryPath()
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

private func temporaryDirectoryPath() -> URL {
    URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent("AgentBoardTests")
        .appendingPathComponent(UUID().uuidString)
}
