import SwiftUI

enum SessionActionStyle {
    case menu
    case toolbar
}

struct SessionActionButtons: View {
    let session: AgentSession
    let store: SessionStore
    let style: SessionActionStyle

    var body: some View {
        switch style {
        case .menu:
            menuButtons
        case .toolbar:
            toolbarButtons
        }
    }

    @ViewBuilder
    private var menuButtons: some View {
        Button("Rename…") { store.pendingRenameID = session.id }
        Button("Clear Terminal") { store.clearTerminal(id: session.id) }
        if session.status == .exited {
            Button("Restart") { store.restartSession(id: session.id) }
        }
        Divider()
        Button("Close Session", role: .destructive) { store.requestCloseSession(id: session.id) }
    }

    @ViewBuilder
    private var toolbarButtons: some View {
        Button { store.pendingRenameID = session.id } label: {
            Label("Rename", systemImage: "pencil")
        }
        Button { store.clearTerminal(id: session.id) } label: {
            Label("Clear", systemImage: "clear")
        }
        .help("Clear Terminal (⌘K)")
        if session.status == .exited {
            Button { store.restartSession(id: session.id) } label: {
                Label("Restart", systemImage: "arrow.clockwise")
            }
        }
        Button(role: .destructive) { store.requestCloseSession(id: session.id) } label: {
            Label("Close", systemImage: "xmark")
        }
        .help("Close Session (⌘W)")
    }
}
