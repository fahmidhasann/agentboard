import Foundation

/// Pure status-derivation logic. Given the inputs for a session it returns the status to display.
struct StatusService {
    /// Seconds of output silence after which a live session is considered idle.
    var idleInterval: TimeInterval = 60

    func evaluate(
        now: Date,
        lastActivityAt: Date,
        isProcessRunning: Bool,
        exitCode: Int32?,
        attentionSignaled: Bool,
        isSelected: Bool
    ) -> SessionStatus {
        guard isProcessRunning else {
            return .exited
        }
        if attentionSignaled && !isSelected {
            return .attentionNeeded
        }
        if now.timeIntervalSince(lastActivityAt) >= idleInterval {
            return .idle
        }
        return .running
    }
}
