import SwiftUI

/// Small editor for a session's custom title and agent label; saving marks each field user-edited.
struct RenameSheet: View {
    @EnvironmentObject var store: SessionStore
    @Environment(\.dismiss) private var dismiss

    let session: AgentSession

    @State private var title: String
    @State private var agentLabel: String

    init(session: AgentSession) {
        self.session = session
        _title = State(initialValue: session.displayTitle)
        _agentLabel = State(initialValue: session.agentLabel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rename Session")
                .font(.headline)
            Form {
                TextField("Title", text: $title)
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

    // Sheet dismiss pattern — keep in sync with NewSessionSheet.close() and CommandPaletteView.close().
    private func save() {
        store.setSummary(id: session.id, title)
        store.setAgentLabel(id: session.id, agentLabel)
        dismiss()
    }
}
