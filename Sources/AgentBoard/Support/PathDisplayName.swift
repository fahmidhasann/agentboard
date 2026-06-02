import Foundation

/// Formats filesystem paths for compact session names and sidebar labels.
struct PathDisplayName {
    static func abbreviate(_ path: String, homeDirectory: String = NSHomeDirectory()) -> String {
        let normalizedPath = trimTrailingSlash((path as NSString).expandingTildeInPath)
        let normalizedHome = trimTrailingSlash((homeDirectory as NSString).expandingTildeInPath)

        guard !normalizedPath.isEmpty else { return normalizedPath }
        guard !normalizedHome.isEmpty else { return normalizedPath }

        if normalizedPath == normalizedHome {
            return "~"
        }

        let homePrefix = normalizedHome + "/"
        if normalizedPath.hasPrefix(homePrefix) {
            return "~/" + normalizedPath.dropFirst(homePrefix.count)
        }

        return normalizedPath
    }

    private static func trimTrailingSlash(_ path: String) -> String {
        var result = path
        while result.count > 1, result.hasSuffix("/") {
            result.removeLast()
        }
        return result
    }
}
