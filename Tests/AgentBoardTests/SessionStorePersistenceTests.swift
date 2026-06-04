import Foundation
import Testing
@testable import AgentBoard

@Suite("SessionStore persistence")
struct SessionStorePersistenceTests {
    @Test("loads sessions as exited")
    func loadsSessionsAsExited() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let session = AgentSession(
            summary: "Task",
            agentLabel: "Claude",
            cwd: NSHomeDirectory(),
            shellPath: "/bin/zsh",
            status: .running
        )
        let data = try JSONEncoder().encode([session])
        try data.write(to: directory.appendingPathComponent("sessions.json"))

        let store = SessionStore(directory: directory, tailLimit: 50)
        #expect(store.sessions.count == 1)
        #expect(store.sessions[0].id == session.id)
        #expect(store.sessions[0].status == .exited)
        #expect(store.controller(for: session.id) == nil)
    }

    @Test("roundtrips session metadata on save")
    func roundtripsSessionMetadataOnSave() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let session = AgentSession(
            summary: "Deploy API",
            agentLabel: "Codex",
            cwd: "/tmp/agentboard-test",
            shellPath: "/bin/zsh",
            status: .exited,
            isSummaryUserEdited: true,
            isAgentUserEdited: true,
            recentTail: ["done"],
            exitCode: 0
        )

        let store = SessionStore(directory: directory, tailLimit: 50)
        store.sessions = [session]
        store.saveNow()

        let reloaded = SessionStore(directory: directory, tailLimit: 50)
        #expect(reloaded.sessions == [session])
    }

    @Test("trims recent tail to tail limit on save")
    func trimsRecentTailToTailLimitOnSave() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = SessionStore(directory: directory, tailLimit: 2)
        store.sessions = [
            AgentSession(
                cwd: NSHomeDirectory(),
                shellPath: "/bin/zsh",
                status: .exited,
                recentTail: ["a", "b", "c"]
            )
        ]
        store.saveNow()

        let reloaded = SessionStore(directory: directory, tailLimit: 2)
        #expect(reloaded.sessions[0].recentTail == ["b", "c"])
    }

    @Test("selectByOrder chooses session by flat index")
    func selectByOrderChoosesSessionByFlatIndex() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let first = AgentSession(cwd: NSHomeDirectory(), shellPath: "/bin/zsh", status: .exited)
        let second = AgentSession(cwd: NSHomeDirectory(), shellPath: "/bin/zsh", status: .exited)
        let store = SessionStore(directory: directory)
        store.sessions = [first, second]

        store.selectByOrder(2)
        #expect(store.selection == second.id)

        store.selectByOrder(9)
        #expect(store.selection == second.id)
    }

    @Test("Restart relaunches exited session as running")
    func restartRelaunchesExitedSession() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let session = AgentSession(
            cwd: NSHomeDirectory(),
            shellPath: "/bin/zsh",
            status: .exited,
            recentTail: ["seed line"]
        )
        let store = SessionStore(directory: directory, tailLimit: 50)
        store.sessions = [session]
        store.selection = session.id

        store.restartSession(id: session.id)

        #expect(store.sessions[0].status == .running)
        #expect(store.sessions[0].exitCode == nil)
        #expect(store.controller(for: session.id) != nil)

        store.closeSession(id: session.id)
        #expect(store.sessions.isEmpty)
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("AgentBoardTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
