import SwiftUI

struct ShortcutReferenceGroup: Equatable, Identifiable {
    let title: String
    let items: [ShortcutReferenceItem]

    var id: String { title }

    static let all: [ShortcutReferenceGroup] = [
        ShortcutReferenceGroup(
            title: "General",
            items: [
                ShortcutReferenceItem(title: "New Session", shortcut: "Cmd+N"),
                ShortcutReferenceItem(title: "New Session with Command", shortcut: "Cmd+Shift+N"),
                ShortcutReferenceItem(title: "Settings", shortcut: "Cmd+,"),
                ShortcutReferenceItem(title: "Command Palette", shortcut: "Cmd+Shift+P")
            ]
        ),
        ShortcutReferenceGroup(
            title: "Session",
            items: [
                ShortcutReferenceItem(title: "Close Session", shortcut: "Cmd+W"),
                ShortcutReferenceItem(title: "Clear Terminal", shortcut: "Cmd+K"),
                ShortcutReferenceItem(title: "Select Session", shortcut: "Cmd+1 ... Cmd+9")
            ]
        ),
        ShortcutReferenceGroup(
            title: "Search",
            items: [
                ShortcutReferenceItem(title: "Find", shortcut: "Cmd+F"),
                ShortcutReferenceItem(title: "Find Next", shortcut: "Cmd+G"),
                ShortcutReferenceItem(title: "Find Previous", shortcut: "Cmd+Shift+G"),
                ShortcutReferenceItem(title: "Close Find", shortcut: "Esc")
            ]
        ),
        ShortcutReferenceGroup(
            title: "View",
            items: [
                ShortcutReferenceItem(title: "Zoom In", shortcut: "Cmd++"),
                ShortcutReferenceItem(title: "Zoom Out", shortcut: "Cmd+-"),
                ShortcutReferenceItem(title: "Actual Size", shortcut: "Cmd+0")
            ]
        )
    ]
}

struct ShortcutReferenceItem: Equatable, Identifiable {
    let title: String
    let shortcut: String

    var id: String { "\(title)-\(shortcut)" }
}

/// App settings: terminal, appearance, history, behavior, and shortcut reference.
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
                    SessionStore.shared.tailLimit = newValue
                }
            }

            Section("Behavior") {
                Toggle("Confirm before closing a session", isOn: $prefs.preferences.confirmClose)
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
                ForEach(ShortcutReferenceGroup.all) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(group.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        ForEach(group.items) { item in
                            LabeledContent(item.title) {
                                Text(item.shortcut)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 640)
    }
}
