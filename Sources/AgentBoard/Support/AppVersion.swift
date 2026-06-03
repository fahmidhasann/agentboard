import Foundation

/// Runtime app-version helpers. Release scripts write these values into the generated bundle.
enum AppVersion {
    struct SemanticVersion: Comparable, CustomStringConvertible {
        let components: [Int]
        let normalizedString: String

        var description: String { normalizedString }

        init?(_ rawValue: String) {
            let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }

            let withoutPrefix: Substring
            if let first = trimmed.first, first == "v" || first == "V" {
                withoutPrefix = trimmed.dropFirst()
            } else {
                withoutPrefix = Substring(trimmed)
            }

            let parts = withoutPrefix.split(separator: ".", omittingEmptySubsequences: false)
            guard !parts.isEmpty else { return nil }

            var parsed: [Int] = []
            parsed.reserveCapacity(parts.count)
            for part in parts {
                guard !part.isEmpty, let value = Int(part), value >= 0 else { return nil }
                parsed.append(value)
            }

            components = parsed
            normalizedString = parsed.map(String.init).joined(separator: ".")
        }

        static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
            let count = max(lhs.components.count, rhs.components.count)
            for index in 0..<count {
                let left = index < lhs.components.count ? lhs.components[index] : 0
                let right = index < rhs.components.count ? rhs.components[index] : 0
                if left != right { return left < right }
            }
            return false
        }

        static func == (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
            !(lhs < rhs) && !(rhs < lhs)
        }
    }

    static var current: SemanticVersion? {
        guard let raw = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return nil
        }
        return SemanticVersion(raw)
    }
}
