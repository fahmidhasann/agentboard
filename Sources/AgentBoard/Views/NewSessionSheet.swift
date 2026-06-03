import SwiftUI
import AppKit

/// The ⌘⇧N "New Session…" dialog: pick a working directory, an optional quick-launch agent, and a
/// command to auto-run. Mirrors the `pendingRenameID` presentation pattern via the store.
struct NewSessionSheet: View {
    @EnvironmentObject var store: SessionStore
    @EnvironmentObject var prefs: PreferencesStore

    @State private var directory: String = NSHomeDirectory()
    @State private var selectedAgentID: UUID?   // nil = plain shell
    @State private var command: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New Session")
                .font(.headline)

            Form {
                LabeledContent("Directory") {
                    HStack(spacing: 8) {
                        Text(directoryDisplay)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .foregroundStyle(.secondary)
                            .help(directory)
                        Spacer()
                        Button("Choose…", action: chooseDirectory)
                    }
                }

                Picker("Agent", selection: $selectedAgentID) {
                    Text("Plain shell (none)").tag(UUID?.none)
                    ForEach(prefs.preferences.agents) { agent in
                        Text(agent.name).tag(Optional(agent.id))
                    }
                }
                .onChange(of: selectedAgentID) { _, newValue in
                    command = agent(for: newValue)?.command ?? ""
                }

                TextField("Command", text: $command, prompt: Text("Optional command to run"))
                    .font(.system(.body, design: .monospaced))
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel", action: close)
                    .keyboardShortcut(.cancelAction)
                Button("Create", action: create)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 460)
        .onAppear(perform: applyPrefill)
    }

    private var directoryDisplay: String {
        (directory as NSString).abbreviatingWithTildeInPath
    }

    private func agent(for id: UUID?) -> AgentLaunchConfig? {
        guard let id else { return nil }
        return prefs.preferences.agents.first { $0.id == id }
    }

    /// Seed the agent + command if the dialog was opened from a quick-launch entry.
    private func applyPrefill() {
        guard let prefill = store.newSessionPrefill else { return }
        if prefs.preferences.agents.contains(where: { $0.id == prefill.id }) {
            selectedAgentID = prefill.id
        }
        command = prefill.command
    }

    private func chooseDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: directory)
        if panel.runModal() == .OK, let url = panel.url {
            directory = url.path
        }
    }

    private func create() {
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
        store.addSession(
            cwd: directory,
            command: trimmed.isEmpty ? nil : trimmed,
            agentLabel: agent(for: selectedAgentID)?.name
        )
        close()
    }

    private func close() {
        store.newSessionPrefill = nil
        store.isPresentingNewSession = false
        DispatchQueue.main.async { [store] in
            store.focusSelectedTerminal()
        }
    }
}
