import Foundation

/// A user-editable quick-launch entry: a display name, the command to run, and an optional icon.
///
/// Stored in ``AgentBoardPreferences`` and surfaced in the New Session dialog, the toolbar
/// quick-launch menu, and the Agents menu. Editing these never touches a running session.
struct AgentLaunchConfig: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String         // e.g. "Claude"
    var command: String      // e.g. "claude"
    var systemImage: String? // optional SF Symbol name

    init(id: UUID = UUID(), name: String, command: String, systemImage: String? = nil) {
        self.id = id
        self.name = name
        self.command = command
        self.systemImage = systemImage
    }

    /// Sensible out-of-the-box agents. Persisted on first save, after which the user owns the list.
    static let defaults: [AgentLaunchConfig] = [
        AgentLaunchConfig(name: "Claude", command: "claude", systemImage: "sparkle"),
        AgentLaunchConfig(name: "Codex", command: "codex", systemImage: "chevron.left.forwardslash.chevron.right"),
        AgentLaunchConfig(name: "Gemini", command: "gemini", systemImage: "sparkles"),
        AgentLaunchConfig(name: "OpenCode", command: "opencode", systemImage: "curlybraces"),
        AgentLaunchConfig(name: "Aider", command: "aider", systemImage: "wand.and.stars"),
        AgentLaunchConfig(name: "Hermes", command: "hermes", systemImage: "bolt")
    ]
}
