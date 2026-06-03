import Foundation
import Testing
@testable import AgentBoard

@Suite("App version parsing")
struct AppVersionTests {
    @Test("Normalizes supported version strings")
    func normalizesSupportedVersionStrings() {
        #expect(AppVersion.SemanticVersion("v0.11.0")?.normalizedString == "0.11.0")
        #expect(AppVersion.SemanticVersion("0.11")?.normalizedString == "0.11")
        #expect(AppVersion.SemanticVersion("0.11.0")?.normalizedString == "0.11.0")
    }

    @Test("Compares semantic components numerically")
    func comparesSemanticComponentsNumerically() throws {
        let patch = try #require(AppVersion.SemanticVersion("0.11.10"))
        let previousPatch = try #require(AppVersion.SemanticVersion("0.11.9"))
        let minor = try #require(AppVersion.SemanticVersion("0.12.0"))
        let previousMinor = try #require(AppVersion.SemanticVersion("0.11.9"))
        let major = try #require(AppVersion.SemanticVersion("1.0.0"))
        let previousMajor = try #require(AppVersion.SemanticVersion("0.99.99"))
        let equalLong = try #require(AppVersion.SemanticVersion("0.11.0"))
        let equalShort = try #require(AppVersion.SemanticVersion("0.11"))

        #expect(patch > previousPatch)
        #expect(minor > previousMinor)
        #expect(major > previousMajor)
        #expect(equalLong == equalShort)
    }

    @Test("Rejects malformed version strings")
    func rejectsMalformedVersionStrings() {
        #expect(AppVersion.SemanticVersion("") == nil)
        #expect(AppVersion.SemanticVersion("latest") == nil)
        #expect(AppVersion.SemanticVersion("0.11.x") == nil)
        #expect(AppVersion.SemanticVersion("0..11") == nil)
        #expect(AppVersion.SemanticVersion("-1.0.0") == nil)
    }
}

@Suite("GitHub release update checks")
struct UpdateCheckServiceTests {
    @Test("Decodes latest release JSON")
    func decodesReleaseJSON() throws {
        let data = Data(Self.releaseJSON.utf8)
        let release = try JSONDecoder().decode(GitHubRelease.self, from: data)

        #expect(release.tagName == "v0.12.0")
        #expect(release.htmlURL.absoluteString == "https://github.com/fahmidhasann/agentboard/releases/tag/v0.12.0")
        #expect(release.draft == false)
        #expect(release.prerelease == false)
        #expect(release.assets.count == 2)
    }

    @Test("Selects stable latest DMG asset")
    func selectsStableLatestDMGAsset() throws {
        let release = try JSONDecoder().decode(GitHubRelease.self, from: Data(Self.releaseJSON.utf8))
        let current = try #require(AppVersion.SemanticVersion("0.11.0"))
        let update = try #require(UpdateCheckService.availableUpdate(from: release, currentVersion: current))

        #expect(update.version == "0.12.0")
        #expect(update.downloadURL == UpdateCheckService.stableDownloadURL)
        #expect(update.releaseURL == release.htmlURL)
    }

    @Test("Falls back to release page when stable asset is missing")
    func fallsBackToReleasePageWhenStableAssetIsMissing() throws {
        let release = GitHubRelease(
            tagName: "v0.12.0",
            htmlURL: URL(string: "https://github.com/fahmidhasann/agentboard/releases/tag/v0.12.0")!,
            draft: false,
            prerelease: false,
            assets: [
                .init(
                    name: "AgentBoard-0.12.0-arm64.dmg",
                    browserDownloadURL: URL(string: "https://example.com/versioned.dmg")!
                )
            ]
        )
        let current = try #require(AppVersion.SemanticVersion("0.11.0"))
        let update = try #require(UpdateCheckService.availableUpdate(from: release, currentVersion: current))

        #expect(update.downloadURL == release.htmlURL)
    }

    @Test("Ignores draft prerelease and older releases")
    func ignoresUnavailableReleases() throws {
        let current = try #require(AppVersion.SemanticVersion("0.11.0"))
        let newerDraft = GitHubRelease(
            tagName: "v0.12.0",
            htmlURL: URL(string: "https://example.com/release")!,
            draft: true,
            prerelease: false,
            assets: []
        )
        let newerPrerelease = GitHubRelease(
            tagName: "v0.12.0",
            htmlURL: URL(string: "https://example.com/release")!,
            draft: false,
            prerelease: true,
            assets: []
        )
        let sameRelease = GitHubRelease(
            tagName: "v0.11.0",
            htmlURL: URL(string: "https://example.com/release")!,
            draft: false,
            prerelease: false,
            assets: []
        )

        #expect(UpdateCheckService.availableUpdate(from: newerDraft, currentVersion: current) == nil)
        #expect(UpdateCheckService.availableUpdate(from: newerPrerelease, currentVersion: current) == nil)
        #expect(UpdateCheckService.availableUpdate(from: sameRelease, currentVersion: current) == nil)
    }

    @Test("Throttles automatic checks to once per day")
    func throttlesAutomaticChecks() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let oldCheck = now.addingTimeInterval(-UpdateCheckService.automaticCheckInterval - 1)
        let recentCheck = now.addingTimeInterval(-60 * 60)

        #expect(UpdateCheckService.shouldCheckAutomatically(
            preferences: AgentBoardPreferences(checkForUpdatesAutomatically: true),
            now: now
        ))
        #expect(UpdateCheckService.shouldCheckAutomatically(
            preferences: AgentBoardPreferences(
                checkForUpdatesAutomatically: true,
                lastUpdateCheckAt: oldCheck
            ),
            now: now
        ))
        #expect(!UpdateCheckService.shouldCheckAutomatically(
            preferences: AgentBoardPreferences(
                checkForUpdatesAutomatically: true,
                lastUpdateCheckAt: recentCheck
            ),
            now: now
        ))
        #expect(!UpdateCheckService.shouldCheckAutomatically(
            preferences: AgentBoardPreferences(checkForUpdatesAutomatically: false),
            now: now
        ))
    }

    private static let releaseJSON = """
    {
      "tag_name": "v0.12.0",
      "html_url": "https://github.com/fahmidhasann/agentboard/releases/tag/v0.12.0",
      "draft": false,
      "prerelease": false,
      "assets": [
        {
          "name": "AgentBoard-0.12.0-arm64.dmg",
          "browser_download_url": "https://example.com/AgentBoard-0.12.0-arm64.dmg"
        },
        {
          "name": "AgentBoard-latest-arm64.dmg",
          "browser_download_url": "https://example.com/AgentBoard-latest-arm64.dmg"
        }
      ]
    }
    """
}

@Suite("Preferences migration")
struct AgentBoardPreferencesMigrationTests {
    @Test("Defaults update fields when loading old preferences")
    func defaultsUpdateFieldsWhenLoadingOldPreferences() throws {
        let oldPreferencesJSON = """
        {
          "terminalFontSize": 14,
          "persistedTailSize": 700,
          "theme": "dark",
          "confirmClose": false,
          "notificationsEnabled": true,
          "paletteShortcutDisplay": "Cmd+Shift+P",
          "agents": [],
          "groupByFolder": true
        }
        """

        let decoded = try JSONDecoder().decode(
            AgentBoardPreferences.self,
            from: Data(oldPreferencesJSON.utf8)
        )

        #expect(decoded.checkForUpdatesAutomatically)
        #expect(decoded.lastUpdateCheckAt == nil)
        #expect(decoded.lastNotifiedUpdateVersion == nil)
        #expect(decoded.terminalFontSize == 14)
        #expect(decoded.groupByFolder)
    }
}
