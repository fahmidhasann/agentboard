import SwiftUI

@main
struct AgentBoardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @StateObject private var store = SessionStore.shared
    @StateObject private var prefs = PreferencesStore.shared
    @StateObject private var palette = CommandPaletteModel.shared

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .environmentObject(store)
                .environmentObject(prefs)
                .environmentObject(palette)
                .preferredColorScheme(prefs.preferredColorScheme)
        }
        .commands {
            AppCommands(store: store, palette: palette, prefs: prefs)
        }

        Settings {
            SettingsView()
                .environmentObject(prefs)
                .preferredColorScheme(prefs.preferredColorScheme)
        }
    }
}

/// Menu bar commands and keyboard shortcuts. Wired to the shared stores.
struct AppCommands: Commands {
    @ObservedObject var store: SessionStore
    @ObservedObject var palette: CommandPaletteModel
    @ObservedObject var prefs: PreferencesStore

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Session") { store.addSession() }
                .keyboardShortcut("n", modifiers: .command)
            Button("New Session…") { store.presentNewSession() }
                .keyboardShortcut("n", modifiers: [.command, .shift])
        }

        CommandMenu("Agents") {
            ForEach(prefs.preferences.agents) { agent in
                Button(agent.name) { store.presentNewSession(prefill: agent) }
            }
            if prefs.preferences.agents.isEmpty {
                Text("No agents configured")
            }
        }

        CommandMenu("View") {
            Button("Find…") { store.findActivationToken += 1 }
                .keyboardShortcut("f", modifiers: .command)
                .disabled(store.selection == nil)

            Divider()

            Button("Zoom In") { adjustFont(by: 1) }
                .keyboardShortcut("+", modifiers: .command)
            Button("Zoom Out") { adjustFont(by: -1) }
                .keyboardShortcut("-", modifiers: .command)
            Button("Actual Size") { prefs.preferences.terminalFontSize = 13 }
                .keyboardShortcut("0", modifiers: .command)

            Divider()

            Toggle("Group by Folder", isOn: $prefs.preferences.groupByFolder)
        }

        CommandMenu("Session") {
            Button("Close Session") {
                if let id = store.selection { store.closeSession(id: id) }
            }
            .keyboardShortcut("w", modifiers: .command)
            .disabled(store.selection == nil)

            Button("Clear Terminal") {
                if let id = store.selection { store.clearTerminal(id: id) }
            }
            .keyboardShortcut("k", modifiers: .command)
            .disabled(store.selection == nil)

            Button("Restart Session") {
                if let id = store.selection { store.restartSession(id: id) }
            }
            .disabled(store.selection == nil)

            Divider()

            Button("Command Palette…") { palette.toggle() }
                .keyboardShortcut("p", modifiers: [.command, .shift])

            Divider()

            // ⌘1…⌘9 select the Nth visible session.
            ForEach(1...9, id: \.self) { index in
                Button("Select Session \(index)") { store.selectByOrder(index) }
                    .keyboardShortcut(KeyEquivalent(Character("\(index)")), modifiers: .command)
            }
        }
    }

    /// Adjusts the terminal font size, clamped to a sensible range. The terminal view reacts
    /// automatically (see ``TerminalRepresentable``).
    private func adjustFont(by delta: Double) {
        let next = prefs.preferences.terminalFontSize + delta
        prefs.preferences.terminalFontSize = min(32, max(8, next))
    }
}
