import SwiftUI

/// App settings: terminal, appearance, history, behavior, and the palette shortcut (display-only).
struct SettingsView: View {
    @EnvironmentObject var prefs: PreferencesStore

    var body: some View {
        Form {
            Section("Terminal") {
                Stepper(
                    value: $prefs.preferences.terminalFontSize,
                    in: 8...32,
                    step: 1
                ) {
                    Text("Font size: \(Int(prefs.preferences.terminalFontSize)) pt")
                }
            }

            Section("Appearance") {
                Picker("Theme", selection: $prefs.preferences.theme) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.label).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("History") {
                Stepper(
                    value: $prefs.preferences.persistedTailSize,
                    in: 100...5000,
                    step: 100
                ) {
                    Text("Persisted tail: \(prefs.preferences.persistedTailSize) lines")
                }
                .onChange(of: prefs.preferences.persistedTailSize) { _, newValue in
                    SessionStore.shared.updateTailLimit(newValue)
                }
            }

            Section("Behavior") {
                Toggle("Confirm before closing active agent sessions", isOn: $prefs.preferences.confirmClose)
                Toggle("Enable notifications", isOn: $prefs.preferences.notificationsEnabled)
                    .onChange(of: prefs.preferences.notificationsEnabled) { _, enabled in
                        if enabled {
                            NotificationService.shared.requestAuthorizationIfEnabled(true)
                        }
                    }
            }

            Section {
                ForEach($prefs.preferences.agents) { $agent in
                    HStack(spacing: 8) {
                        Image(systemName: agent.systemImage ?? "terminal")
                            .foregroundStyle(.secondary)
                            .frame(width: 18)
                        TextField("Name", text: $agent.name)
                            .frame(maxWidth: 120)
                        TextField("Command", text: $agent.command)
                            .font(.system(.body, design: .monospaced))
                        Button(role: .destructive) {
                            prefs.preferences.agents.removeAll { $0.id == agent.id }
                        } label: {
                            Image(systemName: "minus.circle")
                        }
                        .buttonStyle(.borderless)
                        .foregroundStyle(.secondary)
                        .help("Remove agent")
                    }
                }
                .onMove { prefs.preferences.agents.move(fromOffsets: $0, toOffset: $1) }

                Button {
                    prefs.preferences.agents.append(AgentLaunchConfig(name: "New Agent", command: ""))
                } label: {
                    Label("Add Agent", systemImage: "plus")
                }
            } header: {
                Text("Agents")
            } footer: {
                Text("Quick-launch entries for the New Session menu. Drag to reorder.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Shortcuts") {
                LabeledContent("Command palette", value: prefs.preferences.paletteShortcutDisplay)
            }
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 520)
    }
}
