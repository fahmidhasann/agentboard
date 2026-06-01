import Foundation
import UserNotifications

/// Thin wrapper over `UNUserNotificationCenter` for background attention/exit alerts.
///
/// All access is guarded by a real bundle identifier, because `UNUserNotificationCenter`
/// traps when invoked from a bare (non-bundled) executable.
final class NotificationService {
    static let shared = NotificationService()

    private var hasBundle: Bool { Bundle.main.bundleIdentifier != nil }

    /// Requests permission only when the user has notifications enabled.
    func requestAuthorizationIfEnabled(_ enabled: Bool) {
        guard enabled, hasBundle else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    /// Posts a local notification if (and only if) permission has been granted.
    func notify(title: String, body: String) {
        guard hasBundle else { return }
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional else { return }

            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            )
            center.add(request, withCompletionHandler: nil)
        }
    }
}
