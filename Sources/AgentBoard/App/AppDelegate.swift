import AppKit

/// Application-level behavior that SwiftUI scenes don't cover: activation policy, hide-on-close,
/// the quit-with-running-sessions warning, and freeing ⌘W for "Close Session".
final class AppDelegate: NSObject, NSApplicationDelegate {
    private weak var mainWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        SessionStore.shared.tailLimit = PreferencesStore.shared.preferences.persistedTailSize
        SessionStore.shared.activate()
        NotificationService.shared.requestAuthorizationIfEnabled(
            PreferencesStore.shared.preferences.notificationsEnabled
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidBecomeMain(_:)),
            name: NSWindow.didBecomeMainNotification,
            object: nil
        )

        // Let our Session ▸ Close Session (⌘W) win over the default File ▸ Close Window.
        DispatchQueue.main.async { Self.relaxDefaultCloseShortcut() }
    }

    /// Keep the app (and its sessions) alive when the window goes away.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        NSApp.activate(ignoringOtherApps: true)
        if let window = mainWindow {
            window.makeKeyAndOrderFront(nil)
        } else {
            for window in NSApp.windows where window.canBecomeMain {
                window.makeKeyAndOrderFront(nil)
            }
        }
        return true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        let running = SessionStore.shared.runningCount
        guard running > 0 else {
            SessionStore.shared.saveNow()
            return .terminateNow
        }

        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Quit AgentBoard?"
        let noun = running == 1 ? "session is" : "sessions are"
        let pronoun = running == 1 ? "it" : "them"
        alert.informativeText = "\(running) \(noun) still running. Quitting will terminate \(pronoun)."
        alert.addButton(withTitle: "Quit")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            SessionStore.shared.terminateAll()
            SessionStore.shared.saveNow()
            return .terminateNow
        }
        return .terminateCancel
    }

    func applicationWillTerminate(_ notification: Notification) {
        SessionStore.shared.saveNow()
    }

    // MARK: - Window hide-on-close

    @objc private func windowDidBecomeMain(_ note: Notification) {
        guard mainWindow == nil, let window = note.object as? NSWindow else { return }
        mainWindow = window
        if let closeButton = window.standardWindowButton(.closeButton) {
            closeButton.target = self
            closeButton.action = #selector(hideMainWindow(_:))
        }
    }

    @objc private func hideMainWindow(_ sender: Any?) {
        mainWindow?.orderOut(nil)
    }

    // MARK: - Helpers

    /// Removes the default ⌘W from File ▸ Close so the Session menu's "Close Session" can use it.
    static func relaxDefaultCloseShortcut() {
        guard let menu = NSApp.mainMenu else { return }
        for item in menu.items {
            guard let submenu = item.submenu else { continue }
            for sub in submenu.items where sub.action == #selector(NSWindow.performClose(_:)) {
                sub.keyEquivalent = ""
            }
        }
    }

    /// Opens the Settings scene programmatically (e.g. from the command palette).
    static func openSettings() {
        let selectors = ["showSettingsWindow:", "showPreferencesWindow:"]
        for name in selectors {
            let selector = Selector((name))
            if NSApp.responds(to: selector) || NSApp.sendAction(selector, to: nil, from: nil) {
                NSApp.sendAction(selector, to: nil, from: nil)
                return
            }
        }
    }
}
