import SwiftUI
import AppKit

/// Bridges a controller's persistent `AgentTerminalView` into SwiftUI.
///
/// The same NSView instance is reused across selection changes (it's owned by the controller),
/// so switching sessions re-parents the live terminal without losing process state.
struct TerminalRepresentable: NSViewRepresentable {
    let controller: TerminalSessionController
    var fontSize: Double
    var focusRequest: Int
    var allowsAutoFocus = true
    @Environment(\.colorScheme) private var colorScheme

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> AgentTerminalView {
        let view = controller.terminalView
        view.font = Self.font(size: fontSize)
        applyAppearance(to: view)
        if allowsAutoFocus {
            context.coordinator.scheduleFocus(on: view, request: focusRequest)
        }
        return view
    }

    func updateNSView(_ nsView: AgentTerminalView, context: Context) {
        let target = CGFloat(fontSize)
        if abs(nsView.font.pointSize - target) > 0.5 {
            nsView.font = Self.font(size: fontSize)
        }
        applyAppearance(to: nsView)
        guard allowsAutoFocus, context.coordinator.consume(focusRequest) else { return }
        context.coordinator.scheduleFocus(on: nsView, request: focusRequest)
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

    final class Coordinator {
        private var lastHandledFocusRequest: Int?

        func consume(_ request: Int) -> Bool {
            guard lastHandledFocusRequest != request else { return false }
            lastHandledFocusRequest = request
            return true
        }

        func scheduleFocus(on view: AgentTerminalView, request: Int) {
            lastHandledFocusRequest = request
            let delays: [TimeInterval] = [0, 0.05, 0.15]
            for delay in delays {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak view] in
                    guard let view, view.window != nil else { return }
                    view.window?.makeFirstResponder(view)
                }
            }
        }
    }
}
