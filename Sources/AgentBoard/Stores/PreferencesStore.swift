import Foundation
import SwiftUI

/// Observable owner of ``AgentBoardPreferences``, persisted to JSON for inspectability.
final class PreferencesStore: ObservableObject {
    static let shared = PreferencesStore()

    @Published var preferences: AgentBoardPreferences {
        didSet { saveNow() }
    }

    private let url: URL

    init(url: URL = AppPaths.preferencesFile) {
        self.url = url
        if let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode(AgentBoardPreferences.self, from: data) {
            self.preferences = decoded
        } else {
            self.preferences = AgentBoardPreferences()
        }
        // didSet does not run for initialization, so no spurious write here.
    }

    func saveNow() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(preferences) else { return }
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? data.write(to: url, options: .atomic)
    }

    var preferredColorScheme: ColorScheme? {
        switch preferences.theme {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
