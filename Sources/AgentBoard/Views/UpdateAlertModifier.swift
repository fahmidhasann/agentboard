import SwiftUI

struct UpdateAlertModifier: ViewModifier {
    @ObservedObject var updates: UpdateCheckService

    func body(content: Content) -> some View {
        content.alert(
            updates.alert?.title ?? "",
            isPresented: Binding(
                get: { updates.alert != nil },
                set: { if !$0 { updates.clearAlert() } }
            ),
            presenting: updates.alert
        ) { alert in
            switch alert {
            case .available(let update):
                Button("Download") { updates.openDownload(for: update) }
                Button("View Release") { updates.openRelease(for: update) }
                Button("Later", role: .cancel) { updates.dismiss(update: update) }
            case .upToDate, .error:
                Button("OK", role: .cancel) { updates.clearAlert() }
            }
        } message: { alert in
            Text(alert.message)
        }
    }
}

extension View {
    func updateAlert(using updates: UpdateCheckService) -> some View {
        modifier(UpdateAlertModifier(updates: updates))
    }
}
