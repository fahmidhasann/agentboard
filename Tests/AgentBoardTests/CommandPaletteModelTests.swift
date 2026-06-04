import Foundation
import Testing
@testable import AgentBoard

@Suite("Command palette filtering")
struct CommandPaletteModelTests {
    private let model = CommandPaletteModel()

    @Test("Empty query returns all sessions and actions")
    func emptyQueryReturnsAllItems() {
        let sessions = [
            AgentSession(summary: "One", agentLabel: "Claude", cwd: "/a", shellPath: "/bin/zsh"),
            AgentSession(summary: "Two", agentLabel: "Shell", cwd: "/b", shellPath: "/bin/zsh")
        ]

        let items = model.items(sessions: sessions, query: "")
        let sessionIDs = items.compactMap { item -> UUID? in
            if case .session(let session) = item { return session.id }
            return nil
        }
        let actions = items.compactMap { item -> CommandPaletteModel.Action? in
            if case .action(let action) = item { return action }
            return nil
        }

        #expect(sessionIDs == sessions.map(\.id))
        #expect(actions == CommandPaletteModel.Action.allCases)
    }

    @Test("Filters sessions by display title and agent label")
    func filtersSessionsByDisplayText() {
        let match = AgentSession(
            summary: "Deploy",
            agentLabel: "Codex",
            cwd: "/projects/api",
            shellPath: "/bin/zsh"
        )
        let other = AgentSession(
            summary: "Docs",
            agentLabel: "Shell",
            cwd: "/notes",
            shellPath: "/bin/zsh"
        )

        let items = model.items(sessions: [match, other], query: "codex")
        let sessionIDs = items.compactMap { item -> UUID? in
            if case .session(let session) = item { return session.id }
            return nil
        }

        #expect(sessionIDs == [match.id])
        #expect(items.allSatisfy { item in
            switch item {
            case .session: return true
            case .action: return false
            }
        })
    }

    @Test("Filters actions by title")
    func filtersActionsByTitle() {
        let items = model.items(sessions: [], query: "settings")
        #expect(items.count == 1)
        if case .action(.settings) = items[0] {
        } else {
            Issue.record("Expected settings action")
        }
    }
}
