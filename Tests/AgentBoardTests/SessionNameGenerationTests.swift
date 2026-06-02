import Foundation
import XCTest
@testable import AgentBoard

final class SessionNameGenerationTests: XCTestCase {
    func testOutputInferenceDoesNotOverwriteLaunchSummary() {
        var session = AgentSession(
            summary: "OpenCode",
            agentLabel: "Shell",
            cwd: NSHomeDirectory(),
            shellPath: "/bin/zsh"
        )
        let output = "fahmid@host ~ % ooopencodeopopeenopenncopencodecode\r\nzsh: command not found: opencode"

        LabelInferenceService().apply(LabelInferenceService().infer(text: output), to: &session)

        XCTAssertEqual(session.summary, "OpenCode")
        XCTAssertEqual(session.agentLabel, "Shell")
    }

    func testExactKnownCommandStillUpdatesAgentLabelWithoutRenamingSession() {
        var session = AgentSession(
            summary: "Launch Title",
            agentLabel: "Shell",
            cwd: NSHomeDirectory(),
            shellPath: "/bin/zsh"
        )

        LabelInferenceService().apply(LabelInferenceService().infer(text: "fahmid@host ~ % opencode\n"), to: &session)

        XCTAssertEqual(session.summary, "Launch Title")
        XCTAssertEqual(session.agentLabel, "OpenCode")
    }

    func testTUIBannerOutputDoesNotBecomeSessionTitle() {
        var session = AgentSession(
            summary: "Hermes",
            agentLabel: "Hermes",
            cwd: NSHomeDirectory(),
            shellPath: "/bin/zsh"
        )
        let banner = """

        ╭───────────────────────────────────  ────────────────────────────────────╮
        │                                   Available Tools                         │
        ╰──────────────────────────────────────────────────────────────────────────╯
        Welcome to Hermes Agent!
        """

        LabelInferenceService().apply(LabelInferenceService().infer(text: banner), to: &session)

        XCTAssertEqual(session.summary, "Hermes")
    }

    func testLegacyCleanupRepairsUnlockedCommandErrorSummary() throws {
        let badSession = AgentSession(
            summary: "ooopencodeopopeenopenncopencodecode zsh: command…",
            agentLabel: "Shell",
            cwd: NSHomeDirectory(),
            shellPath: "/bin/zsh",
            status: .running,
            isSummaryUserEdited: false,
            recentTail: [
                "fahmid@host ~ % ooopencodeopopeenopenncopencodecode\r\nzsh: command not found: opencode"
            ]
        )

        let (store, directory) = try loadStore(with: [badSession])
        defer { try? FileManager.default.removeItem(at: directory) }

        let loaded = try XCTUnwrap(store.sessions.first)
        XCTAssertEqual(loaded.summary, "New Session")
        XCTAssertEqual(loaded.status, .exited)
    }

    func testLegacyCleanupUsesNonShellAgentLabelForNoisyBannerSummary() throws {
        let badSession = AgentSession(
            summary: "│ Available Tools │",
            agentLabel: "Hermes",
            cwd: NSHomeDirectory(),
            shellPath: "/bin/zsh",
            isSummaryUserEdited: false
        )

        let (store, directory) = try loadStore(with: [badSession])
        defer { try? FileManager.default.removeItem(at: directory) }

        let loaded = try XCTUnwrap(store.sessions.first)
        XCTAssertEqual(loaded.summary, "Hermes")
    }

    func testLegacyCleanupPreservesUserEditedSummary() throws {
        let editedSession = AgentSession(
            summary: "│ Available Tools │",
            agentLabel: "Hermes",
            cwd: NSHomeDirectory(),
            shellPath: "/bin/zsh",
            isSummaryUserEdited: true
        )

        let (store, directory) = try loadStore(with: [editedSession])
        defer { try? FileManager.default.removeItem(at: directory) }

        let loaded = try XCTUnwrap(store.sessions.first)
        XCTAssertEqual(loaded.summary, "│ Available Tools │")
    }

    private func loadStore(with sessions: [AgentSession]) throws -> (SessionStore, URL) {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AgentBoardTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let data = try JSONEncoder().encode(sessions)
        try data.write(to: directory.appendingPathComponent("sessions.json"), options: .atomic)

        return (SessionStore(directory: directory, fileManager: .default), directory)
    }
}
