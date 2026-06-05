import Foundation

/// User-selectable appearance for the app window.
enum AppTheme: String, Codable, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

/// App-wide, user-editable preferences. Persisted as JSON so all app state stays inspectable.
struct AgentBoardPreferences: Codable, Equatable {
    var terminalFontSize: Double
    var persistedTailSize: Int
    var theme: AppTheme
    var confirmClose: Bool
    var notificationsEnabled: Bool
    var checkForUpdatesAutomatically: Bool
    var lastUpdateCheckAt: Date?
    var lastNotifiedUpdateVersion: String?
    var paletteShortcutDisplay: String
    var agents: [AgentLaunchConfig]
    var groupByFolder: Bool
    var inlineAutocompleteEnabled: Bool

    init(
        terminalFontSize: Double = 13,
        persistedTailSize: Int = 500,
        theme: AppTheme = .system,
        confirmClose: Bool = true,
        notificationsEnabled: Bool = true,
        checkForUpdatesAutomatically: Bool = true,
        lastUpdateCheckAt: Date? = nil,
        lastNotifiedUpdateVersion: String? = nil,
        paletteShortcutDisplay: String = "Cmd+Shift+P",
        agents: [AgentLaunchConfig] = AgentLaunchConfig.defaults,
        groupByFolder: Bool = false,
        inlineAutocompleteEnabled: Bool = true
    ) {
        self.terminalFontSize = terminalFontSize
        self.persistedTailSize = persistedTailSize
        self.theme = theme
        self.confirmClose = confirmClose
        self.notificationsEnabled = notificationsEnabled
        self.checkForUpdatesAutomatically = checkForUpdatesAutomatically
        self.lastUpdateCheckAt = lastUpdateCheckAt
        self.lastNotifiedUpdateVersion = lastNotifiedUpdateVersion
        self.paletteShortcutDisplay = paletteShortcutDisplay
        self.agents = agents
        self.groupByFolder = groupByFolder
        self.inlineAutocompleteEnabled = inlineAutocompleteEnabled
    }

    // Tolerate older/partial JSON by defaulting any missing fields.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = AgentBoardPreferences()
        terminalFontSize = try c.decodeIfPresent(Double.self, forKey: .terminalFontSize) ?? d.terminalFontSize
        persistedTailSize = try c.decodeIfPresent(Int.self, forKey: .persistedTailSize) ?? d.persistedTailSize
        theme = try c.decodeIfPresent(AppTheme.self, forKey: .theme) ?? d.theme
        confirmClose = try c.decodeIfPresent(Bool.self, forKey: .confirmClose) ?? d.confirmClose
        notificationsEnabled = try c.decodeIfPresent(Bool.self, forKey: .notificationsEnabled) ?? d.notificationsEnabled
        checkForUpdatesAutomatically = try c.decodeIfPresent(Bool.self, forKey: .checkForUpdatesAutomatically) ?? d.checkForUpdatesAutomatically
        lastUpdateCheckAt = try c.decodeIfPresent(Date.self, forKey: .lastUpdateCheckAt) ?? d.lastUpdateCheckAt
        lastNotifiedUpdateVersion = try c.decodeIfPresent(String.self, forKey: .lastNotifiedUpdateVersion) ?? d.lastNotifiedUpdateVersion
        paletteShortcutDisplay = try c.decodeIfPresent(String.self, forKey: .paletteShortcutDisplay) ?? d.paletteShortcutDisplay
        agents = try c.decodeIfPresent([AgentLaunchConfig].self, forKey: .agents) ?? d.agents
        groupByFolder = try c.decodeIfPresent(Bool.self, forKey: .groupByFolder) ?? d.groupByFolder
        inlineAutocompleteEnabled = try c.decodeIfPresent(Bool.self, forKey: .inlineAutocompleteEnabled) ?? d.inlineAutocompleteEnabled
    }
}
