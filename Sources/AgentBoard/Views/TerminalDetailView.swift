import SwiftUI

/// Routes the detail pane to the live terminal, an exited placeholder, or an empty state.
struct TerminalDetailView: View {
    @EnvironmentObject var store: SessionStore
    @EnvironmentObject var prefs: PreferencesStore

    var body: some View {
        Group {
            if let id = store.selection, let session = store.session(id: id) {
                if let controller = store.controller(for: id) {
                    TerminalContainer(session: session, controller: controller)
                        .id(id)
                } else {
                    ExitedPlaceholder(session: session)
                        .id(id)
                }
            } else {
                EmptyDetailView()
            }
        }
    }
}

/// Hosts a live terminal with its rename/clear/restart/close toolbar.
private struct TerminalContainer: View {
    @EnvironmentObject var store: SessionStore
    @EnvironmentObject var prefs: PreferencesStore

    let session: AgentSession
    let controller: TerminalSessionController

    @State private var isRenaming = false
    @State private var isConfirmingClose = false

    @State private var isFinding = false
    @State private var findText = ""
    @State private var findCaseSensitive = false
    @State private var findUseRegex = false
    @FocusState private var findFieldFocused: Bool

    var body: some View {
        TerminalRepresentable(controller: controller, fontSize: prefs.preferences.terminalFontSize)
            .background(Color(nsColor: .textBackgroundColor))
            .overlay(alignment: .top) {
                if isFinding {
                    FindBar(
                        text: $findText,
                        caseSensitive: $findCaseSensitive,
                        useRegex: $findUseRegex,
                        focused: $findFieldFocused,
                        onNext: findNext,
                        onPrevious: findPrevious,
                        onClose: closeFind
                    )
                    .padding(8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .onChange(of: store.findActivationToken) { _, _ in openFind() }
            .navigationTitle(session.summary)
            .navigationSubtitle(session.agentLabel)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button { isRenaming = true } label: {
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
                    Button(role: .destructive) { requestClose() } label: {
                        Label("Close", systemImage: "xmark")
                    }
                    .help("Close Session (⌘W)")
                }
            }
            .sheet(isPresented: $isRenaming) {
                RenameSheet(session: session)
            }
            .alert("Close this session?", isPresented: $isConfirmingClose) {
                Button("Close", role: .destructive) { store.closeSession(id: session.id) }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("“\(session.summary)” will be closed and its process terminated.")
            }
            .onChange(of: store.pendingRenameID) { _, newValue in
                if newValue == session.id {
                    isRenaming = true
                    store.pendingRenameID = nil
                }
            }
    }

    private func requestClose() {
        if prefs.preferences.confirmClose {
            isConfirmingClose = true
        } else {
            store.closeSession(id: session.id)
        }
    }

    // MARK: - Find

    private func openFind() {
        withAnimation(.easeInOut(duration: 0.12)) { isFinding = true }
        findFieldFocused = true
    }

    private func closeFind() {
        withAnimation(.easeInOut(duration: 0.12)) { isFinding = false }
        controller.clearSearch()
    }

    private func findNext() {
        controller.findNext(findText, caseSensitive: findCaseSensitive, regex: findUseRegex)
    }

    private func findPrevious() {
        controller.findPrevious(findText, caseSensitive: findCaseSensitive, regex: findUseRegex)
    }
}

/// Shown for sessions reloaded from disk (no live process) — offers restart with the last tail.
private struct ExitedPlaceholder: View {
    @EnvironmentObject var store: SessionStore

    let session: AgentSession

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "powersleep")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            VStack(spacing: 4) {
                Text(session.summary).font(.headline)
                Text("This session isn't running.")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Button {
                    store.restartSession(id: session.id)
                } label: {
                    Label("Restart Session", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderedProminent)
                Button(role: .destructive) {
                    store.closeSession(id: session.id)
                } label: {
                    Label("Close", systemImage: "xmark")
                }
            }

            if !session.recentTail.isEmpty {
                ScrollView {
                    Text(session.recentTail.suffix(200).joined(separator: "\n"))
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .padding(8)
                }
                .frame(maxHeight: 260)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(.separator))
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(session.summary)
        .navigationSubtitle(session.agentLabel)
    }
}

/// First-launch / no-selection state.
private struct EmptyDetailView: View {
    @EnvironmentObject var store: SessionStore

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "terminal")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("AgentBoard")
                .font(.title2.weight(.semibold))
            Text("Select a session, or create one to open a shell.")
                .foregroundStyle(.secondary)
            Button {
                store.addSession()
            } label: {
                Label("New Session", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut("n", modifiers: .command)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Small editor for a session's summary and agent label; saving marks each field user-edited.
private struct RenameSheet: View {
    @EnvironmentObject var store: SessionStore
    @Environment(\.dismiss) private var dismiss

    let session: AgentSession

    @State private var summary: String
    @State private var agentLabel: String

    init(session: AgentSession) {
        self.session = session
        _summary = State(initialValue: session.summary)
        _agentLabel = State(initialValue: session.agentLabel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rename Session")
                .font(.headline)
            Form {
                TextField("Summary", text: $summary)
                TextField("Agent", text: $agentLabel)
            }
            .formStyle(.grouped)
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Save") { save() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 380)
    }

    private func save() {
        store.setSummary(id: session.id, summary)
        store.setAgentLabel(id: session.id, agentLabel)
        dismiss()
    }
}
