import Foundation
import Combine

/// Backing model + pure filtering for the command palette.
///
/// Search covers session summaries and agent labels plus a fixed set of actions. It deliberately
/// does NOT search the recent terminal tail in v1.
final class CommandPaletteModel: ObservableObject {
    static let shared = CommandPaletteModel()

    @Published var isPresented = false
    @Published var query = ""

    func present() {
        query = ""
        isPresented = true
    }

    func toggle() {
        if isPresented {
            isPresented = false
        } else {
            present()
        }
    }

    /// Actions the palette can invoke. Order here is the order shown for an empty query.
    enum Action: String, CaseIterable, Identifiable {
        case newSession
        case switchSession
        case renameSession
        case closeSession
        case clearTerminal
        case settings

        var id: String { rawValue }

        var title: String {
            switch self {
            case .newSession: return "New Session"
            case .switchSession: return "Switch Session"
            case .renameSession: return "Rename Session"
            case .closeSession: return "Close Session"
            case .clearTerminal: return "Clear Terminal"
            case .settings: return "Settings"
            }
        }

        var systemImage: String {
            switch self {
            case .newSession: return "plus.square"
            case .switchSession: return "rectangle.2.swap"
            case .renameSession: return "pencil"
            case .closeSession: return "xmark.square"
            case .clearTerminal: return "clear"
            case .settings: return "gearshape"
            }
        }
    }

    enum Item: Identifiable {
        case action(Action)
        case session(AgentSession)

        var id: String {
            switch self {
            case .action(let action): return "action.\(action.rawValue)"
            case .session(let session): return "session.\(session.id.uuidString)"
            }
        }
    }

    /// Pure filter used by the palette UI and unit tests. Sessions match on summary and agent
    /// label only; actions match on their title. An empty query returns everything.
    func items(sessions: [AgentSession], query: String) -> [Item] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        let matchingSessions = sessions.filter { session in
            trimmed.isEmpty
                || session.summary.localizedCaseInsensitiveContains(trimmed)
                || session.agentLabel.localizedCaseInsensitiveContains(trimmed)
        }

        let matchingActions = Action.allCases.filter { action in
            trimmed.isEmpty || action.title.localizedCaseInsensitiveContains(trimmed)
        }

        return matchingSessions.map(Item.session) + matchingActions.map(Item.action)
    }
}
