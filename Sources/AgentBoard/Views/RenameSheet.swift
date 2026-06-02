import SwiftUI

/// Small editor for a session's summary and agent label; saving marks each field user-edited.
struct RenameSheet: View {
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
