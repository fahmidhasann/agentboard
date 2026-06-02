import SwiftUI

/// A small colored dot conveying ``SessionStatus``.
struct StatusBadge: View {
    let status: SessionStatus

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 9, height: 9)
            .overlay(Circle().strokeBorder(.black.opacity(0.12), lineWidth: 0.5))
            .accessibilityLabel(status.displayName)
            .help(status.displayName)
    }

    private var color: Color {
        switch status {
        case .running: return .green
        case .idle: return .gray
        case .attentionNeeded: return .orange
        case .exited: return .red
        }
    }
}

/// One sidebar entry: status dot, display title, and tilde-relative path.
struct SidebarRowView: View {
    @EnvironmentObject var store: SessionStore

    let session: AgentSession

    var body: some View {
        HStack(spacing: 10) {
            StatusBadge(status: session.status)
            VStack(alignment: .leading, spacing: 3) {
                Text(session.displayTitle)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(session.displayPath)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(session.cwd)
            }
            Spacer(minLength: 0)
            Button {
                store.pendingRenameID = session.id
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 15, weight: .medium))
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Rename Session")
            .accessibilityLabel("Rename Session")
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }
}
