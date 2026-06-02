import Foundation
@testable import AgentBoard

enum RenameRequestCompileCheck {
    static func renamedSummary() -> String? {
        let store = SessionStore(
            directory: URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent(UUID().uuidString)
        )
        let session = AgentSession(
            summary: "Original",
            agentLabel: "Shell",
            cwd: NSTemporaryDirectory(),
            shellPath: "/bin/zsh"
        )
        store.sessions = [session]

        store.setSummary(id: session.id, "  Renamed Session  ")

        return store.session(id: session.id)?.summary
    }
}
