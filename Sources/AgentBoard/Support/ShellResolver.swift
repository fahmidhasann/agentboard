import Foundation

/// Resolves which shell to launch for a new session.
enum ShellResolver {
    static let fallbackShell = "/bin/zsh"

    /// Returns the user's `$SHELL` if it exists on disk, otherwise `/bin/zsh`.
    static func resolve(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        fileManager: FileManager = .default
    ) -> String {
        if let shell = environment["SHELL"], !shell.isEmpty, fileManager.fileExists(atPath: shell) {
            return shell
        }
        return fallbackShell
    }

    /// The `argv[0]` value a login shell expects, e.g. `-zsh` for `/bin/zsh`.
    static func loginExecName(forShellPath path: String) -> String {
        let name = (path as NSString).lastPathComponent
        return "-" + name
    }
}
