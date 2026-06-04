import Foundation
import SwiftUI
import os

/// Observable owner of ``AgentBoardPreferences``, persisted to JSON for inspectability.
final class PreferencesStore: ObservableObject {
    static let shared = PreferencesStore()
    private static let logger = Logger(subsystem: AppPaths.bundleIdentifier, category: "PreferencesStore")

    @Published var preferences: AgentBoardPreferences {
        didSet { saveNow() }
    }

    private let url: URL

    init(url: URL = AppPaths.preferencesFile) {
        self.url = url
        do {
            let data = try Data(contentsOf: url)
            self.preferences = try JSONDecoder().decode(AgentBoardPreferences.self, from: data)
        } catch CocoaError.fileReadNoSuchFile {
            self.preferences = AgentBoardPreferences()
        } catch {
            Self.logger.error("Failed to load preferences from \(url.path, privacy: .public): \(error.localizedDescription, privacy: .public)")
            self.preferences = AgentBoardPreferences()
        }
        // didSet does not run for initialization, so no spurious write here.
    }

    func saveNow() {
        let encoder = JSONEncoder.agentBoard
        do {
            let data = try encoder.encode(preferences)
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: url, options: .atomic)
        } catch {
            Self.logger.error("Failed to save preferences to \(self.url.path, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch preferences.theme {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
