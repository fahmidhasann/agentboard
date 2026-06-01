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

    @Test("Shortcut reference lists useful app shortcuts")
    func shortcutReferenceListsUsefulAppShortcuts() {
        let groups = ShortcutReferenceGroup.all

        #expect(groups.map(\.title) == ["General", "Session", "Search", "View"])
        #expect(groups.flatMap(\.items).count == 14)
        #expect(groups[0].items == [
            ShortcutReferenceItem(title: "New Session", shortcut: "Cmd+N"),
            ShortcutReferenceItem(title: "New Session with Command", shortcut: "Cmd+Shift+N"),
            ShortcutReferenceItem(title: "Settings", shortcut: "Cmd+,"),
            ShortcutReferenceItem(title: "Command Palette", shortcut: "Cmd+Shift+P")
        ])
        #expect(groups[1].items.contains(
            ShortcutReferenceItem(title: "Select Session", shortcut: "Cmd+1 ... Cmd+9")
        ))
        #expect(groups[2].items.contains(
            ShortcutReferenceItem(title: "Close Find", shortcut: "Esc")
        ))
        #expect(groups[3].items == [
            ShortcutReferenceItem(title: "Zoom In", shortcut: "Cmd++"),
            ShortcutReferenceItem(title: "Zoom Out", shortcut: "Cmd+-"),
            ShortcutReferenceItem(title: "Actual Size", shortcut: "Cmd+0")
        ])
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
