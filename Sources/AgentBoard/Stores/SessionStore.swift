import Foundation
import Combine
import AppKit
import os

/// The single source of truth for session metadata and live terminal controllers.
///
/// Session *metadata* is a value type persisted to JSON. Live *controllers* (the running shells)
/// are reference objects keyed by session id and are never persisted — after relaunch a session
/// reloads as `.exited` with its recent tail intact, ready to be restarted.
final class SessionStore: ObservableObject {
    static let shared = SessionStore()
    private static let logger = Logger(subsystem: "com.fahmid.AgentBoard", category: "SessionStore")

    @Published var sessions: [AgentSession] = []
    @Published var selection: UUID? {
        didSet { handleSelectionChange(from: oldValue) }
    }
    /// Set to request that the detail view present its rename sheet (used by the command palette).
    @Published var pendingRenameID: UUID?

    /// Drives the New Session… dialog (mirrors `pendingRenameID`).
    @Published var isPresentingNewSession = false
    /// Set when the app should ask before closing a session.
    @Published var pendingCloseID: UUID?
    /// When set, the New Session dialog prefills its agent + command from this quick-launch config.
    @Published var newSessionPrefill: AgentLaunchConfig?

    /// Incremented by the View ▸ Find menu to ask the active terminal to show its find bar.
    @Published var findActivationToken = 0

    /// Number of stored tail lines to persist; mirrors the user's preference.
    var tailLimit: Int = 500

    private let directory: URL
    private let fileManager: FileManager
    private var controllers: [UUID: TerminalSessionController] = [:]

    private let inference = LabelInferenceService()
    private let statusService = StatusService()

    private var statusTimer: Timer?
    private var saveWorkItem: DispatchWorkItem?

    private var sessionsFile: URL { directory.appendingPathComponent("sessions.json") }

    init(
        directory: URL = AppPaths.appSupportDirectory,
        fileManager: FileManager = .default,
        tailLimit: Int = 500
    ) {
        self.directory = directory
        self.fileManager = fileManager
        self.tailLimit = tailLimit
        load()
    }

    // MARK: - Activation

    /// Starts the periodic status/metadata sync. Called once at app launch (not in tests).
    func activate() {
        guard statusTimer == nil else { return }
        let timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.sync()
        }
        timer.tolerance = 0.2
        RunLoop.main.add(timer, forMode: .common)
        statusTimer = timer
    }

    // MARK: - Lookup

    func session(id: UUID) -> AgentSession? {
        sessions.first { $0.id == id }
    }

    func controller(for id: UUID) -> TerminalSessionController? {
        controllers[id]
    }

    var runningCount: Int {
        controllers.values.filter { $0.isProcessRunning }.count
    }

    // MARK: - Session lifecycle

    /// Creates a new live session. The zero-argument form (⌘N) opens an instant home-directory
    /// shell; the optional parameters let the New Session dialog / quick-launch open in a chosen
    /// directory, seed an agent label, and auto-run a command once the shell is up.
    @discardableResult
    func addSession(cwd: String? = nil, command: String? = nil, agentLabel: String? = nil) -> UUID {
        let shell = ShellResolver.resolve()
        let resolvedCwd = resolveLaunchDirectory(cwd)
        let trimmedCommand = command?.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasCommand = trimmedCommand?.isEmpty == false
        let hasLabel = agentLabel?.isEmpty == false

        // Seed the label without locking it, so inference can still confirm/refine it.
        let label = hasLabel ? agentLabel! : "Shell"
        let summary = AgentSession.abbreviatedPath(resolvedCwd)

        let session = AgentSession(
            summary: summary,
            agentLabel: label,
            cwd: resolvedCwd,
            shellPath: shell,
            status: .running
        )
        sessions.append(session)
        let controller = TerminalSessionController(
            sessionID: session.id,
            shellPath: shell,
            cwd: resolvedCwd,
            tailLimit: tailLimit,
            seedTail: [],
            store: self,
            initialCommand: hasCommand ? trimmedCommand : nil
        )
        controllers[session.id] = controller
        selection = session.id
        controller.isSelected = true
        saveNow()
        return session.id
    }

    /// Permanently removes a session and terminates its process. Confirmation is the UI's job.
    func closeSession(id: UUID) {
        controllers[id]?.terminate()
        controllers[id] = nil
        sessions.removeAll { $0.id == id }
        if selection == id {
            selection = sessions.first?.id
        }
        saveNow()
    }

    func requestCloseSession(id: UUID) {
        guard sessions.contains(where: { $0.id == id }) else { return }
        requestCloseSession(id: id, confirmClose: PreferencesStore.shared.preferences.confirmClose)
    }

    func requestCloseSession(id: UUID, confirmClose: Bool) {
        guard sessions.contains(where: { $0.id == id }) else { return }
        if confirmClose {
            pendingCloseID = id
        } else {
            closeSession(id: id)
        }
    }

    func confirmPendingClose() {
        guard let id = pendingCloseID else { return }
        pendingCloseID = nil
        closeSession(id: id)
    }

    func cancelPendingClose() {
        pendingCloseID = nil
    }

    /// Relaunches the shell for an exited session, keeping its row and recent tail.
    func restartSession(id: UUID) {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
        controllers[id]?.terminate()

        let stored = sessions[index]
        let shell = fileManager.fileExists(atPath: stored.shellPath) ? stored.shellPath : ShellResolver.resolve()
        let cwd = resolveLaunchDirectory(stored.cwd)

        let controller = TerminalSessionController(
            sessionID: id,
            shellPath: shell,
            cwd: cwd,
            tailLimit: tailLimit,
            seedTail: stored.recentTail,
            store: self
        )
        controllers[id] = controller
        controller.isSelected = (selection == id)

        sessions[index].status = .running
        sessions[index].exitCode = nil
        sessions[index].shellPath = shell
        sessions[index].cwd = cwd
        sessions[index].lastActivityAt = Date()
        sessions[index].updatedAt = Date()
        saveNow()
    }

    func clearTerminal(id: UUID) {
        controllers[id]?.clear()
    }

    /// Opens the New Session dialog, optionally prefilled from a quick-launch agent.
    func presentNewSession(prefill: AgentLaunchConfig? = nil) {
        newSessionPrefill = prefill
        isPresentingNewSession = true
    }

    func selectByOrder(_ ordinal: Int) {
        let index = ordinal - 1
        guard sessions.indices.contains(index) else { return }
        selection = sessions[index].id
    }

    /// Reorders sessions via sidebar drag (flat mode). The flat array order also drives ⌘1–9
    /// selection and folder grouping, so this is the single source of order.
    func moveSessions(fromOffsets source: IndexSet, toOffset destination: Int) {
        sessions.move(fromOffsets: source, toOffset: destination)
        saveNow()
    }

    // MARK: - Renaming (locks auto-inference for the edited field)

    func setSummary(id: UUID, _ text: String) {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        sessions[index].summary = trimmed.isEmpty ? sessions[index].summary : trimmed
        sessions[index].isSummaryUserEdited = true
        sessions[index].updatedAt = Date()
        saveNow()
    }

    func setAgentLabel(id: UUID, _ text: String) {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        sessions[index].agentLabel = trimmed.isEmpty ? sessions[index].agentLabel : trimmed
        sessions[index].isAgentUserEdited = true
        sessions[index].updatedAt = Date()
        saveNow()
    }

    func terminateAll() {
        for controller in controllers.values {
            controller.terminate()
        }
    }

    func updateTailLimit(_ limit: Int) {
        tailLimit = max(1, limit)
        for controller in controllers.values {
            controller.updateTailLimit(tailLimit)
        }
        saveNow()
    }

    // MARK: - Controller callbacks

    /// Invoked by a controller when the shell reports a new working directory (OSC 7).
    func updateCwd(id: UUID, _ directory: String?) {
        guard let path = normalizedCwd(from: directory),
              let index = sessions.firstIndex(where: { $0.id == id }) else { return }
        guard !path.isEmpty, sessions[index].cwd != path else { return }
        var session = sessions[index]
        session.cwd = path
        session.updatedAt = Date()
        sessions[index] = session
        scheduleSave()
    }

    /// Invoked by a controller when its process terminates.
    func handleProcessExit(id: UUID, exitCode: Int32?) {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
        let previous = sessions[index].status
        sessions[index].exitCode = exitCode
        sessions[index].status = .exited
        sessions[index].updatedAt = Date()
        if previous != .exited {
            notifyIfBackground(session: sessions[index], newStatus: .exited)
        }
        saveNow()
    }

    // MARK: - Periodic sync

    /// Pulls the latest snapshot from every live controller and recomputes status. Running at a
    /// fixed cadence coalesces high-frequency terminal output into bounded UI/disk updates.
    private func sync() {
        guard !controllers.isEmpty else { return }
        let now = Date()
        var changed = false

        for (id, controller) in controllers {
            guard let index = sessions.firstIndex(where: { $0.id == id }) else { continue }
            var session = sessions[index]
            let selected = (id == selection)
            controller.isSelected = selected // clears any pending attention when selected

            let snapshot = controller.snapshot()
            session.recentTail = snapshot.tail
            session.lastActivityAt = snapshot.lastActivityAt
            inference.apply(snapshot.inferred, to: &session)

            let previousStatus = session.status
            session.status = statusService.evaluate(
                now: now,
                lastActivityAt: session.lastActivityAt,
                isProcessRunning: controller.isProcessRunning,
                exitCode: session.exitCode,
                attentionSignaled: controller.attentionSignaled,
                isSelected: selected
            )

            if session != sessions[index] {
                sessions[index] = session
                changed = true
            }
            if previousStatus != session.status {
                notifyIfBackground(session: session, newStatus: session.status)
            }
        }

        if changed { scheduleSave() }
    }

    private func handleSelectionChange(from previous: UUID?) {
        if let previous, let controller = controllers[previous] {
            controller.isSelected = false
        }
        guard let current = selection, let controller = controllers[current] else { return }
        controller.isSelected = true // didSet clears any pending bell + attention badge
        // Reflect cleared attention immediately rather than waiting for the next tick.
        if let index = sessions.firstIndex(where: { $0.id == current }), sessions[index].status == .attentionNeeded {
            sessions[index].status = controller.isProcessRunning ? .running : .exited
        }
    }

    private func notifyIfBackground(session: AgentSession, newStatus: SessionStatus) {
        guard PreferencesStore.shared.preferences.notificationsEnabled else { return }
        let isBackground = (session.id != selection) || !NSApp.isActive
        guard isBackground else { return }
        switch newStatus {
        case .attentionNeeded:
            NotificationService.shared.notify(title: session.displayTitle, body: "Needs attention — \(session.agentLabel)")
        case .exited:
            NotificationService.shared.notify(title: session.displayTitle, body: "Session ended")
        default:
            break
        }
    }

    // MARK: - Persistence

    private func load() {
        guard fileManager.fileExists(atPath: sessionsFile.path) else {
            sessions = []
            return
        }
        do {
            let data = try Data(contentsOf: sessionsFile)
            let decoded = try JSONDecoder().decode([AgentSession].self, from: data)
            // No live processes survive a relaunch: present everything as exited.
            sessions = decoded.map { session in
                var session = session
                if session.status != .exited { session.status = .exited }
                return session
            }
        } catch {
            Self.logger.error("Failed to load sessions from \(self.sessionsFile.path, privacy: .public): \(error.localizedDescription, privacy: .public)")
            backupCorruptFile()
            sessions = []
        }
    }

    private func backupCorruptFile() {
        let stamp = Int(Date().timeIntervalSince1970)
        let backup = directory.appendingPathComponent("sessions.corrupt-\(stamp).json")
        do {
            try fileManager.copyItem(at: sessionsFile, to: backup)
        } catch {
            Self.logger.error("Failed to back up corrupt sessions file \(self.sessionsFile.path, privacy: .public) to \(backup.path, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Debounced save (coalesces bursts). Runs on the main run loop so reading `sessions` is safe.
    private func scheduleSave() {
        saveWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.saveNow() }
        saveWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: work)
    }

    func saveNow() {
        saveWorkItem?.cancel()
        guard let data = encodeTrimmed() else { return }
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: sessionsFile, options: .atomic)
        } catch {
            Self.logger.error("Failed to save sessions to \(self.sessionsFile.path, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
    }

    private func encodeTrimmed() -> Data? {
        let limit = max(0, tailLimit)
        let trimmed = sessions.map { session -> AgentSession in
            var session = session
            if session.recentTail.count > limit {
                session.recentTail = Array(session.recentTail.suffix(limit))
            }
            return session
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(trimmed)
    }

    private func resolveLaunchDirectory(_ directory: String?) -> String {
        let candidate = directory?.trimmingCharacters(in: .whitespacesAndNewlines)
        let path = candidate?.isEmpty == false ? candidate! : NSHomeDirectory()
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: path, isDirectory: &isDirectory), isDirectory.boolValue {
            return path
        }
        Self.logger.error("Working directory \(path, privacy: .public) is unavailable; falling back to home directory")
        return NSHomeDirectory()
    }

    private func normalizedCwd(from directory: String?) -> String? {
        guard let directory, !directory.isEmpty else { return nil }
        if let url = URL(string: directory), url.isFileURL {
            return url.path
        }
        return directory.removingPercentEncoding ?? directory
    }
}
