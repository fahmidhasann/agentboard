import AppKit
import SwiftUI

/// Theme colors applied to SwiftTerm's default terminal foreground/background.
struct TerminalTheme: Equatable {
    var foregroundColor: NSColor
    var backgroundColor: NSColor
    var cursorColor: NSColor

    static let light = TerminalTheme(
        foregroundColor: NSColor(calibratedWhite: 0.10, alpha: 1),
        backgroundColor: NSColor(calibratedWhite: 0.98, alpha: 1),
        cursorColor: NSColor(calibratedWhite: 0.12, alpha: 1)
    )

    static let dark = TerminalTheme(
        foregroundColor: NSColor(calibratedWhite: 0.86, alpha: 1),
        backgroundColor: NSColor(calibratedWhite: 0.00, alpha: 1),
        cursorColor: NSColor(calibratedWhite: 0.90, alpha: 1)
    )

    static func resolve(appTheme: AppTheme, systemColorScheme: ColorScheme) -> TerminalTheme {
        switch appTheme.resolvedColorScheme(system: systemColorScheme) {
        case .light:
            return .light
        case .dark:
            return .dark
        @unknown default:
            return .dark
        }
    }
}
