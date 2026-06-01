import SwiftUI

/// The single-window command center: sidebar of sessions + detail terminal, with the palette sheet.
struct ContentView: View {
    @EnvironmentObject var store: SessionStore
    @EnvironmentObject var prefs: PreferencesStore
    @EnvironmentObject var palette: CommandPaletteModel

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
    }
}
