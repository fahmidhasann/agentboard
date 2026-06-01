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

/// One sidebar entry: status dot, summary, agent label. In flat mode it also shows the working
/// folder (in grouped mode the section header already carries it, so `showFolder` is false).
struct SidebarRowView: View {
    let session: AgentSession
    var showFolder: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            StatusBadge(status: session.status)
            VStack(alignment: .leading, spacing: 2) {
                Text(session.summary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                HStack(spacing: 6) {
                    Text(session.agentLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if session.status == .exited, let code = session.exitCode {
                        Text("· exit \(code)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    if showFolder, let folder = folderName {
                        Text("· \(folder)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .help(session.cwd)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }

    private var folderName: String? {
        let name = (session.cwd as NSString).lastPathComponent
        return name.isEmpty ? nil : name
    }
}
