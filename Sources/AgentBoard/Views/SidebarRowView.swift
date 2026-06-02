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

/// One sidebar entry: status dot + agent–name, tilde-relative path, and a colored status pill.
struct SidebarRowView: View {
    @EnvironmentObject var store: SessionStore

    let session: AgentSession

    var body: some View {
        HStack(spacing: 10) {
            StatusBadge(status: session.status)
            VStack(alignment: .leading, spacing: 3) {
                (Text(session.agentLabel).bold() + Text(" - ") + Text(session.summary))
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(displayPath)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(session.cwd)
                StatusPill(status: session.status)
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

    private var displayPath: String {
        PathDisplayName.abbreviate(session.cwd)
    }
}

struct StatusPill: View {
    let status: SessionStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption2)
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
            .background(backgroundColor, in: Capsule())
    }

    private var foregroundColor: Color {
        switch status {
        case .running: return .green
        case .idle: return .gray
        case .attentionNeeded: return .orange
        case .exited: return .red
        }
    }

    private var backgroundColor: Color {
        switch status {
        case .running: return .green.opacity(0.15)
        case .idle: return .gray.opacity(0.15)
        case .attentionNeeded: return .orange.opacity(0.15)
        case .exited: return .red.opacity(0.15)
        }
    }
}
