import SwiftUI
import Testing
@testable import AgentBoard

@Suite("Appearance settings")
struct AppearanceSettingsTests {
    @Test("Missing theme defaults to system")
    func missingThemeDefaultsToSystem() throws {
        let data = Data("""
        {
          "terminalFontSize": 14,
          "persistedTailSize": 700,
          "confirmClose": false,
          "notificationsEnabled": true,
          "paletteShortcutDisplay": "Cmd+Shift+P",
          "agents": [],
          "groupByFolder": true
        }
        """.utf8)

        let preferences = try JSONDecoder().decode(AgentBoardPreferences.self, from: data)

        #expect(preferences.theme == .system)
    }

    @Test("Stored light and dark themes decode")
    func storedThemesDecode() throws {
        let light = try decodePreferences(theme: "light")
        let dark = try decodePreferences(theme: "dark")

        #expect(light.theme == .light)
        #expect(dark.theme == .dark)
    }

    @Test("Preferred color scheme maps persisted theme")
    func preferredColorSchemeMapsTheme() {
        #expect(AppTheme.system.preferredColorScheme == nil)
        #expect(AppTheme.light.preferredColorScheme == .light)
        #expect(AppTheme.dark.preferredColorScheme == .dark)
    }

    @Test("System theme resolves from environment scheme")
    func systemThemeResolvesFromEnvironmentScheme() {
        #expect(AppTheme.system.resolvedColorScheme(system: .light) == .light)
        #expect(AppTheme.system.resolvedColorScheme(system: .dark) == .dark)
        #expect(AppTheme.light.resolvedColorScheme(system: .dark) == .light)
        #expect(AppTheme.dark.resolvedColorScheme(system: .light) == .dark)
    }

    @Test("Terminal theme follows app and system theme")
    func terminalThemeFollowsAppAndSystemTheme() {
        #expect(TerminalTheme.resolve(appTheme: .light, systemColorScheme: .dark) == .light)
        #expect(TerminalTheme.resolve(appTheme: .dark, systemColorScheme: .light) == .dark)
        #expect(TerminalTheme.resolve(appTheme: .system, systemColorScheme: .light) == .light)
        #expect(TerminalTheme.resolve(appTheme: .system, systemColorScheme: .dark) == .dark)
    }

    private func decodePreferences(theme: String) throws -> AgentBoardPreferences {
        let data = Data("""
        {
          "terminalFontSize": 14,
          "persistedTailSize": 700,
          "theme": "\(theme)",
          "confirmClose": false,
          "notificationsEnabled": true,
          "paletteShortcutDisplay": "Cmd+Shift+P",
          "agents": [],
          "groupByFolder": true
        }
        """.utf8)

        return try JSONDecoder().decode(AgentBoardPreferences.self, from: data)
    }
}
