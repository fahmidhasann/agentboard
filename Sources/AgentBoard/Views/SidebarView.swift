import SwiftUI

/// The native sidebar list of sessions, with an empty-state overlay on first launch.
///
/// Two modes (driven by `groupByFolder`): a flat, drag-reorderable list, or read-only sections
/// grouped by working directory. Reordering is intentionally a flat-mode-only affordance.
struct SidebarView: View {
    @EnvironmentObject var store: SessionStore
    @EnvironmentObject var prefs: PreferencesStore

    var body: some View {
        List(selection: $store.selection) {
            if prefs.preferences.groupByFolder {
                groupedContent
            } else {
                flatContent
            }
        }
        .listStyle(.sidebar)
        .overlay {
            if store.sessions.isEmpty {
                emptyState
            }
        }
    }

    @ViewBuilder
    private var flatContent: some View {
        ForEach(store.sessions) { session in
            SidebarRowView(session: session, showFolder: true)
                .tag(session.id)
                .contextMenu { contextMenu(for: session) }
        }
        .onMove(perform: store.moveSessions)
    }

    @ViewBuilder
    private var groupedContent: some View {
        ForEach(folderGroups) { group in
            Section {
                ForEach(group.sessions) { session in
                    SidebarRowView(session: session, showFolder: false)
                        .tag(session.id)
                        .contextMenu { contextMenu(for: session) }
                }
            } header: {
                Text(group.displayName).help(group.path)
            }
        }
    }

    /// Sessions grouped by `cwd`, preserving the flat order of each folder's first appearance.
    private var folderGroups: [FolderGroup] {
        var order: [String] = []
        var byPath: [String: [AgentSession]] = [:]
        for session in store.sessions {
            if byPath[session.cwd] == nil { order.append(session.cwd) }
            byPath[session.cwd, default: []].append(session)
        }
        return order.map { FolderGroup(path: $0, sessions: byPath[$0] ?? []) }
    }

    @ViewBuilder
    private func contextMenu(for session: AgentSession) -> some View {
        Button("Rename…") { store.pendingRenameID = session.id }
        Button("Clear Terminal") { store.clearTerminal(id: session.id) }
        if session.status == .exited {
            Button("Restart") { store.restartSession(id: session.id) }
        }
        Divider()
        Button("Close Session", role: .destructive) { store.closeSession(id: session.id) }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "terminal")
                .font(.system(size: 34))
                .foregroundStyle(.secondary)
            Text("No Sessions")
                .font(.headline)
            Text("Create a session to open a shell in your home folder.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                store.addSession()
            } label: {
                Label("New Session", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut("n", modifiers: .command)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}

/// A folder's worth of sessions for grouped sidebar mode.
private struct FolderGroup: Identifiable {
    let path: String
    let sessions: [AgentSession]

    var id: String { path }

    var displayName: String {
        let name = (path as NSString).lastPathComponent
        return name.isEmpty ? path : name
    }
}
