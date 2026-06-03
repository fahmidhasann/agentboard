import AppKit
import Combine
import Foundation

enum UpdateCheckMode {
    case automatic
    case manual
}

struct AvailableUpdate: Equatable, Identifiable {
    var id: String { version }

    let version: String
    let downloadURL: URL
    let releaseURL: URL
}

enum UpdateCheckAlert: Equatable {
    case available(AvailableUpdate)
    case upToDate(String)
    case error(String)

    var title: String {
        switch self {
        case .available(let update):
            return "AgentBoard \(update.version) is available."
        case .upToDate:
            return "AgentBoard is up to date."
        case .error:
            return "Unable to check for updates."
        }
    }

    var message: String {
        switch self {
        case .available:
            return "Download the latest version from GitHub."
        case .upToDate(let version):
            return "You are running AgentBoard \(version)."
        case .error(let message):
            return message
        }
    }
}

struct GitHubRelease: Decodable, Equatable {
    struct Asset: Decodable, Equatable {
        let name: String
        let browserDownloadURL: URL

        private enum CodingKeys: String, CodingKey {
            case name
            case browserDownloadURL = "browser_download_url"
        }
    }

    let tagName: String
    let htmlURL: URL
    let draft: Bool
    let prerelease: Bool
    let assets: [Asset]

    private enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
        case draft
        case prerelease
        case assets
    }
}

protocol GitHubReleaseFetching {
    func latestRelease() async throws -> GitHubRelease
}

struct GitHubReleaseClient: GitHubReleaseFetching {
    static let defaultEndpoint = URL(
        string: "https://api.github.com/repos/fahmidhasann/agentboard/releases/latest"
    )!

    let endpoint: URL
    let session: URLSession

    init(endpoint: URL = Self.defaultEndpoint, session: URLSession = .shared) {
        self.endpoint = endpoint
        self.session = session
    }

    func latestRelease() async throws -> GitHubRelease {
        var request = URLRequest(url: endpoint)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("AgentBoard", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw UpdateCheckError.invalidResponse(http.statusCode)
        }
        return try JSONDecoder().decode(GitHubRelease.self, from: data)
    }
}

enum UpdateCheckError: LocalizedError {
    case currentVersionUnavailable
    case invalidResponse(Int)

    var errorDescription: String? {
        switch self {
        case .currentVersionUnavailable:
            return "The current app version is unavailable."
        case .invalidResponse(let statusCode):
            return "GitHub returned HTTP \(statusCode)."
        }
    }
}

@MainActor
final class UpdateCheckService: ObservableObject {
    static let shared = UpdateCheckService()

    nonisolated static let stableAssetName = "AgentBoard-latest-arm64.dmg"
    nonisolated static let stableDownloadURL = URL(
        string: "https://github.com/fahmidhasann/agentboard/releases/latest/download/AgentBoard-latest-arm64.dmg"
    )!
    nonisolated static let automaticCheckInterval: TimeInterval = 24 * 60 * 60

    @Published private(set) var isChecking = false
    @Published var alert: UpdateCheckAlert?

    private let client: GitHubReleaseFetching
    private let currentVersionProvider: () -> AppVersion.SemanticVersion?
    private let now: () -> Date

    init(
        client: GitHubReleaseFetching = GitHubReleaseClient(),
        currentVersionProvider: @escaping () -> AppVersion.SemanticVersion? = { AppVersion.current },
        now: @escaping () -> Date = Date.init
    ) {
        self.client = client
        self.currentVersionProvider = currentVersionProvider
        self.now = now
    }

    func checkAutomaticallyIfNeeded(preferencesStore: PreferencesStore = .shared) {
        guard Self.shouldCheckAutomatically(
            preferences: preferencesStore.preferences,
            now: now()
        ) else { return }

        Task {
            await check(mode: .automatic, preferencesStore: preferencesStore)
        }
    }

    func checkManually(preferencesStore: PreferencesStore = .shared) {
        Task {
            await check(mode: .manual, preferencesStore: preferencesStore)
        }
    }

    func clearAlert() {
        alert = nil
    }

    func openDownload(for update: AvailableUpdate) {
        recordNotified(version: update.version)
        alert = nil
        NSWorkspace.shared.open(update.downloadURL)
    }

    func openRelease(for update: AvailableUpdate) {
        recordNotified(version: update.version)
        alert = nil
        NSWorkspace.shared.open(update.releaseURL)
    }

    func dismiss(update: AvailableUpdate) {
        recordNotified(version: update.version)
        alert = nil
    }

    nonisolated static func shouldCheckAutomatically(
        preferences: AgentBoardPreferences,
        now: Date
    ) -> Bool {
        guard preferences.checkForUpdatesAutomatically else { return false }
        guard let lastCheck = preferences.lastUpdateCheckAt else { return true }
        return now.timeIntervalSince(lastCheck) >= automaticCheckInterval
    }

    nonisolated static func availableUpdate(
        from release: GitHubRelease,
        currentVersion: AppVersion.SemanticVersion
    ) -> AvailableUpdate? {
        guard !release.draft, !release.prerelease else { return nil }
        guard let latestVersion = AppVersion.SemanticVersion(release.tagName) else { return nil }
        guard latestVersion > currentVersion else { return nil }

        let hasStableAsset = release.assets.contains { $0.name == stableAssetName }
        let downloadURL = hasStableAsset ? stableDownloadURL : release.htmlURL

        return AvailableUpdate(
            version: latestVersion.normalizedString,
            downloadURL: downloadURL,
            releaseURL: release.htmlURL
        )
    }

    private func check(mode: UpdateCheckMode, preferencesStore: PreferencesStore) async {
        guard !isChecking else { return }
        isChecking = true
        preferencesStore.preferences.lastUpdateCheckAt = now()
        defer { isChecking = false }

        do {
            guard let currentVersion = currentVersionProvider() else {
                throw UpdateCheckError.currentVersionUnavailable
            }

            let release = try await client.latestRelease()
            guard let update = Self.availableUpdate(from: release, currentVersion: currentVersion) else {
                if mode == .manual {
                    alert = .upToDate(currentVersion.normalizedString)
                }
                return
            }

            if mode == .automatic,
               preferencesStore.preferences.lastNotifiedUpdateVersion == update.version {
                return
            }

            if mode == .automatic {
                preferencesStore.preferences.lastNotifiedUpdateVersion = update.version
                notifyIfAppInactive(update: update, preferences: preferencesStore.preferences)
            }
            alert = .available(update)
        } catch {
            if mode == .manual {
                alert = .error(error.localizedDescription)
            }
        }
    }

    private func recordNotified(version: String) {
        PreferencesStore.shared.preferences.lastNotifiedUpdateVersion = version
    }

    private func notifyIfAppInactive(update: AvailableUpdate, preferences: AgentBoardPreferences) {
        guard preferences.notificationsEnabled, !NSApp.isActive else { return }
        NotificationService.shared.notify(
            title: "AgentBoard \(update.version) is available",
            body: "Download the latest version from GitHub."
        )
    }
}
