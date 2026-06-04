import SwiftUI

/// Spotlight-style palette to search sessions (by title/path/agent) and run actions.
struct CommandPaletteView: View {
    @EnvironmentObject var store: SessionStore
    @EnvironmentObject var palette: CommandPaletteModel

    @FocusState private var searchFocused: Bool

    private var items: [CommandPaletteModel.Item] {
        palette.items(sessions: store.sessions, query: palette.query)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search sessions and actions…", text: $palette.query)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .focused($searchFocused)
                    .onSubmit { runFirst() }
            }
            .padding(14)
            Divider()
            if items.isEmpty {
                Text("No matches")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(items) { item in
                            Button { run(item) } label: {
                                PaletteRow(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(8)
                }
            }
        }
        .frame(width: 560, height: 420)
        .background(.regularMaterial)
        .onAppear { searchFocused = true }
        .onExitCommand { close(refocusTerminal: true) }
    }

    private func runFirst() {
        if let first = items.first { run(first) }
    }

    private func run(_ item: CommandPaletteModel.Item) {
        switch item {
        case .session(let session):
            store.selection = session.id
            close(refocusTerminal: true)
        case .action(let action):
            close(refocusTerminal: perform(action))
        }
    }

    private func perform(_ action: CommandPaletteModel.Action) -> Bool {
        switch action {
        case .newSession:
            store.addSession()
            return true
        case .switchSession:
            return true // session rows above are the switch targets
        case .renameSession:
            store.pendingRenameID = store.selection
            return false
        case .closeSession:
            if let id = store.selection { store.requestCloseSession(id: id) }
            return false
        case .clearTerminal:
            if let id = store.selection { store.clearTerminal(id: id) }
            return true
        case .settings:
            AppDelegate.openSettings()
            return false
        }
    }

    // Sheet dismiss pattern — keep in sync with NewSessionSheet.close() and RenameSheet.save()/dismiss().
    private func close(refocusTerminal: Bool) {
        palette.isPresented = false
        guard refocusTerminal else { return }
        store.focusSelectedTerminalAsync()
    }
}

private struct PaletteRow: View {
    let item: CommandPaletteModel.Item

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .frame(width: 18)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            Text(kind)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var icon: String {
        switch item {
        case .action(let action): return action.systemImage
        case .session: return "terminal"
        }
    }

    private var title: String {
        switch item {
        case .action(let action): return action.title
        case .session(let session): return session.displayTitle
        }
    }

    private var subtitle: String? {
        switch item {
        case .action: return nil
        case .session(let session): return session.displayPath
        }
    }

    private var kind: String {
        switch item {
        case .action: return "Action"
        case .session: return "Session"
        }
    }
}
