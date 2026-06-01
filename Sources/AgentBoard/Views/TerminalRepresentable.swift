import SwiftUI
import AppKit

/// Bridges a controller's persistent `AgentTerminalView` into SwiftUI.
///
/// The same NSView instance is reused across selection changes (it's owned by the controller),
/// so switching sessions re-parents the live terminal without losing process state.
struct TerminalRepresentable: NSViewRepresentable {
    let controller: TerminalSessionController
    var fontSize: Double
    var appTheme: AppTheme
    var systemColorScheme: ColorScheme

    func makeNSView(context: Context) -> AgentTerminalView {
        let view = controller.terminalView
        view.font = Self.font(size: fontSize)
        view.applyTheme(resolvedTerminalTheme)
        return view
    }

    func updateNSView(_ nsView: AgentTerminalView, context: Context) {
        let target = CGFloat(fontSize)
        if abs(nsView.font.pointSize - target) > 0.5 {
            nsView.font = Self.font(size: fontSize)
        }
        nsView.applyTheme(resolvedTerminalTheme)
    }

    private static func font(size: Double) -> NSFont {
        NSFont.monospacedSystemFont(ofSize: CGFloat(size), weight: .regular)
    }

    private var resolvedTerminalTheme: TerminalTheme {
        TerminalTheme.resolve(appTheme: appTheme, systemColorScheme: systemColorScheme)
    }
}
