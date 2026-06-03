import SwiftUI
import AppKit

/// Bridges a controller's persistent `AgentTerminalView` into SwiftUI.
///
/// The same NSView instance is reused across selection changes (it's owned by the controller),
/// so switching sessions re-parents the live terminal without losing process state.
struct TerminalRepresentable: NSViewRepresentable {
    let controller: TerminalSessionController
    var fontSize: Double
    @Environment(\.colorScheme) private var colorScheme

    func makeNSView(context: Context) -> AgentTerminalView {
        let view = controller.terminalView
        view.font = Self.font(size: fontSize)
        applyAppearance(to: view)
        controller.focusIfSelected()
        return view
    }

    func updateNSView(_ nsView: AgentTerminalView, context: Context) {
        let target = CGFloat(fontSize)
        if abs(nsView.font.pointSize - target) > 0.5 {
            nsView.font = Self.font(size: fontSize)
        }
        applyAppearance(to: nsView)
    }

    private func applyAppearance(to view: AgentTerminalView) {
        let name: NSAppearance.Name = (colorScheme == .dark) ? .darkAqua : .aqua
        let desired = NSAppearance(named: name)
        guard view.appearance !== desired else { return }
        view.appearance = desired
        view.applyThemeColors()
    }

    private static func font(size: Double) -> NSFont {
        NSFont.monospacedSystemFont(ofSize: CGFloat(size), weight: .regular)
    }
}
