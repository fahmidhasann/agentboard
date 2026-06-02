import SwiftUI

/// The single-window command center: sidebar of sessions + detail terminal, with the palette sheet.
struct ContentView: View {
    @EnvironmentObject var store: SessionStore
    @EnvironmentObject var prefs: PreferencesStore
    @EnvironmentObject var palette: CommandPaletteModel

    @State private var renamingSession: AgentSession?

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 360)
                .navigationTitle("AgentBoard")
        } detail: {
            TerminalDetailView()
        }
        .frame(minWidth: 840, minHeight: 520)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Menu {
                    Button("New Session…") { store.presentNewSession() }
                        .keyboardShortcut("n", modifiers: [.command, .shift])
                    Divider()
                    ForEach(prefs.preferences.agents) { agent in
                        Button {
                            store.presentNewSession(prefill: agent)
                        } label: {
                            if let symbol = agent.systemImage {
                                Label(agent.name, systemImage: symbol)
                            } else {
                                Text(agent.name)
                            }
                        }
                    }
                } label: {
                    Label("New Session", systemImage: "plus")
                } primaryAction: {
                    store.addSession()
                }
                .menuIndicator(.visible)
                .help("New Session (⌘N) — ▾ for options")
            }
            ToolbarItem(placement: .primaryAction) {
                SettingsLink {
                    Label("Settings", systemImage: "gearshape")
                }
                .help("Settings (⌘,)")
            }
        }
        .sheet(isPresented: $store.isPresentingNewSession) {
            NewSessionSheet()
                .environmentObject(store)
                .environmentObject(prefs)
        }
        .sheet(isPresented: $palette.isPresented) {
            CommandPaletteView()
                .environmentObject(store)
                .environmentObject(palette)
        }
        .sheet(item: $renamingSession) { session in
            RenameSheet(session: session)
                .environmentObject(store)
        }
        .alert(
            "Close this session?",
            isPresented: Binding(
                get: { store.pendingCloseID != nil },
                set: { if !$0 { store.cancelPendingClose() } }
            )
        ) {
            Button("Close", role: .destructive) { store.confirmPendingClose() }
            Button("Cancel", role: .cancel) { store.cancelPendingClose() }
        } message: {
            if let session = pendingCloseSession {
                Text("“\(session.summary)” will be closed and its process terminated.")
            } else {
                Text("This session will be closed and its process terminated.")
            }
        }
        .onChange(of: store.pendingRenameID) { _, newValue in
            presentPendingRename(id: newValue)
        }
    }

    private var pendingCloseSession: AgentSession? {
        guard let id = store.pendingCloseID else { return nil }
        return store.session(id: id)
    }

    private func presentPendingRename(id: UUID?) {
        guard let id else { return }
        guard let session = store.session(id: id) else {
            store.pendingRenameID = nil
            return
        }

        store.pendingRenameID = nil
        DispatchQueue.main.async {
            renamingSession = session
        }
    }
}
