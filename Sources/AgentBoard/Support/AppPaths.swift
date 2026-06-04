import Foundation

/// Centralized on-disk locations for app state, under Application Support for `com.fahmid.AgentBoard`.
enum AppPaths {
    static let bundleIdentifier = "com.fahmid.AgentBoard"
    static let folderName = "AgentBoard"
    static let home = NSHomeDirectory()

    /// `~/Library/Application Support/AgentBoard`, created on demand.
    static var appSupportDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        let dir = base.appendingPathComponent(folderName, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static var sessionsFile: URL {
        appSupportDirectory.appendingPathComponent("sessions.json")
    }

    static var preferencesFile: URL {
        appSupportDirectory.appendingPathComponent("preferences.json")
    }
}
