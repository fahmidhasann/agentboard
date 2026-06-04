import Foundation
import Testing
@testable import AgentBoard

@Suite("Label inference")
struct LabelInferenceServiceTests {
    private let service = LabelInferenceService()

    @Test("Detects known agents from command lines")
    func detectsKnownAgentsFromCommandLines() {
        #expect(service.detectAgent(in: "claude --help") == "Claude")
        #expect(service.detectAgent(in: "/usr/local/bin/codex run") == "Codex")
        #expect(service.detectAgent(in: "user@host % gemini chat") == "Gemini")
    }

    @Test("Strips shell prompt prefix before matching")
    func stripsShellPromptPrefixBeforeMatching() {
        let text = "fahmid@mac % claude code\n"
        #expect(service.detectAgent(in: text) == "Claude")
    }

    @Test("Most recent agent invocation wins")
    func mostRecentAgentInvocationWins() {
        let text = "codex run\nlater line\nclaude --print\n"
        #expect(service.detectAgent(in: text) == "Claude")
    }

    @Test("Returns nil when no known agent is present")
    func returnsNilWhenNoKnownAgent() {
        #expect(service.detectAgent(in: "ls -la\nnpm test") == nil)
    }

    @Test("Apply updates agent label when not user edited")
    func applyUpdatesAgentLabelWhenNotUserEdited() {
        var session = AgentSession(
            agentLabel: "Shell",
            cwd: NSHomeDirectory(),
            shellPath: "/bin/zsh"
        )
        service.apply(LabelInferenceService.Result(agentLabel: "Claude"), to: &session)
        #expect(session.agentLabel == "Claude")
    }

    @Test("Apply respects user-edited agent label lock")
    func applyRespectsUserEditedAgentLabelLock() {
        var session = AgentSession(
            agentLabel: "My Agent",
            cwd: NSHomeDirectory(),
            shellPath: "/bin/zsh",
            isAgentUserEdited: true
        )
        service.apply(LabelInferenceService.Result(agentLabel: "Claude"), to: &session)
        #expect(session.agentLabel == "My Agent")
    }
}
