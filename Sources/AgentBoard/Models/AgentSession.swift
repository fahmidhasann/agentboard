import Foundation

/// The lifecycle/attention state of a session, surfaced as a colored badge in the sidebar.
enum SessionStatus: String, Codable, CaseIterable, Equatable {
    case running
    case idle
    case attentionNeeded
    case exited

    var displayName: String {
        switch self {
        case .running: return "Running"
        case .idle: return "Idle"
        case .attentionNeeded: return "Attention Needed"
        case .exited: return "Exited"
        }
    }
}

/// Persistable metadata for a single embedded terminal session.
///
/// Only metadata plus a bounded tail of recent terminal lines is stored — never the live
/// process. After relaunch a session is reconstructed from this value with no running shell.
struct AgentSession: Identifiable, Codable, Equatable {
    var id: UUID
    var summary: String
    var agentLabel: String
    var cwd: String
    var shellPath: String
    var status: SessionStatus
    var createdAt: Date
    var updatedAt: Date
    var lastActivityAt: Date
    var isSummaryUserEdited: Bool
    var isAgentUserEdited: Bool
    var recentTail: [String]
    var exitCode: Int32?

    init(
        id: UUID = UUID(),
        summary: String = "New Session",
        agentLabel: String = "Shell",
        cwd: String,
        shellPath: String,
        status: SessionStatus = .running,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        lastActivityAt: Date = Date(),
        isSummaryUserEdited: Bool = false,
        isAgentUserEdited: Bool = false,
        recentTail: [String] = [],
        exitCode: Int32? = nil
    ) {
        self.id = id
        self.summary = summary
        self.agentLabel = agentLabel
        self.cwd = cwd
        self.shellPath = shellPath
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastActivityAt = lastActivityAt
        self.isSummaryUserEdited = isSummaryUserEdited
        self.isAgentUserEdited = isAgentUserEdited
        self.recentTail = recentTail
        self.exitCode = exitCode
    }
}
