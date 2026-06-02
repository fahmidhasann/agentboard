import Foundation

/// Derives a session's agent label locally from terminal text.
///
/// Inference never calls a remote service. Results are only applied when the user has not
/// manually edited the agent label (see ``apply(_:to:)``).
struct LabelInferenceService {
    struct Result: Equatable {
        var agentLabel: String?
    }

    /// Known coding agents recognized from command invocations, with their display labels.
    static let knownAgents: [(token: String, label: String)] = [
        ("codex", "Codex"),
        ("claude", "Claude"),
        ("gemini", "Gemini"),
        ("opencode", "OpenCode"),
        ("aider", "Aider"),
        ("hermes", "Hermes")
    ]

    static let defaultAgentLabel = "Shell"

    func infer(text: String) -> Result {
        Result(agentLabel: detectAgent(in: text))
    }

    /// Applies inferred values, but never overwrites an agent label the user has edited.
    func apply(_ result: Result, to session: inout AgentSession) {
        if let agent = result.agentLabel, !session.isAgentUserEdited, session.agentLabel != agent {
            session.agentLabel = agent
        }
    }

    // MARK: - Agent detection

    /// Scans each line's leading command token for a known agent name. The most recent match
    /// wins, so switching agents mid-session updates the label. Returns nil when none is found.
    func detectAgent(in text: String) -> String? {
        var detected: String?
        for rawLine in text.split(separator: "\n", omittingEmptySubsequences: false) {
            guard let token = leadingCommandToken(of: String(rawLine)) else { continue }
            for agent in Self.knownAgents where token == agent.token {
                detected = agent.label
            }
        }
        return detected
    }

    /// First whitespace-delimited token of a line, with any shell prompt prefix and the
    /// executable's directory stripped, lowercased. e.g. `"$ /usr/bin/claude --help"` -> `"claude"`.
    private func leadingCommandToken(of line: String) -> String? {
        var working = Substring(line)
        // Strip a leading prompt such as "user@host % ", "$ ", "# ", "❯ ". Match greedily to the
        // last prompt sigil so a zsh prompt redraw (which can prepend the whole prompt to the
        // command on one physical line) is fully removed. `>` is intentionally excluded — it is
        // far more often a shell redirect inside a command than a prompt sigil.
        if let promptRange = working.range(of: #"^.*[\$#%›❯]\s+"#, options: .regularExpression) {
            working = working[promptRange.upperBound...]
        }
        working = Substring(working.trimmingCharacters(in: .whitespaces))
        guard let firstToken = working.split(whereSeparator: { $0 == " " || $0 == "\t" }).first else {
            return nil
        }
        let executable = (String(firstToken) as NSString).lastPathComponent
        let cleaned = executable.trimmingCharacters(in: CharacterSet(charactersIn: "'\""))
        return cleaned.isEmpty ? nil : cleaned.lowercased()
    }
}
