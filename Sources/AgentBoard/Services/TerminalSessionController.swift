import Foundation
import AppKit
import SwiftTerm

/// Immutable snapshot of a controller's derived metadata, pulled by ``SessionStore`` each tick.
struct TerminalSnapshot {
    var tail: [String]
    var lastActivityAt: Date
    var inferred: LabelInferenceService.Result
}

/// A `LocalProcessTerminalView` subclass that mirrors raw output back to its controller while
/// still feeding SwiftTerm's renderer via `super`.
final class AgentTerminalView: LocalProcessTerminalView {
    weak var controller: TerminalSessionController?

    override func dataReceived(slice: ArraySlice<UInt8>) {
        super.dataReceived(slice: slice)
        controller?.ingest(slice)
    }

    func applyThemeColors() {
        nativeForegroundColor = .textColor
        nativeBackgroundColor = .textBackgroundColor
        layer?.backgroundColor = nativeBackgroundColor.cgColor
        terminal.updateFullScreen()
        needsDisplay = true
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        applyThemeColors()
    }
}

/// Owns one live terminal: the SwiftTerm view, its process, and the rolling tail/inference state.
///
/// SwiftTerm delivers process callbacks on the main queue, so all mutation here happens on the
/// main thread and needs no additional locking.
final class TerminalSessionController: NSObject, LocalProcessTerminalViewDelegate {
    let sessionID: UUID
    let terminalView: AgentTerminalView

    weak var store: SessionStore?

    /// Set by the store; gates background attention signaling. Selecting a session clears any
    /// pending bell and its attention badge immediately.
    var isSelected = false {
        didSet {
            if isSelected {
                bellPending = false
                attentionSignaled = false
            }
        }
    }
    /// Raised on a bell or interactive-prompt while unselected; recomputed every ingest so it
    /// decays once the prompt is answered. Cleared when the session is viewed.
    var attentionSignaled = false

    /// One-shot bell flag, set on `0x07` and cleared on selection. Unlike a prompt it has no
    /// natural decay from output, so it persists until the user views the session.
    private var bellPending = false

    private var buffer: RecentLineBuffer
    private var decoder = UTF8StreamDecoder()
    private let inference = LabelInferenceService()
    private var lastActivityAt = Date()

    /// Optional command auto-run once the shell is live (e.g. launching an agent in a new session).
    private let initialCommand: String?

    init(
        sessionID: UUID,
        shellPath: String,
        cwd: String,
        tailLimit: Int,
        seedTail: [String],
        store: SessionStore,
        initialCommand: String? = nil
    ) {
        self.sessionID = sessionID
        self.store = store
        self.buffer = RecentLineBuffer(limit: tailLimit, seed: seedTail)
        self.initialCommand = (initialCommand?.isEmpty == false) ? initialCommand : nil
        self.terminalView = AgentTerminalView(frame: CGRect(x: 0, y: 0, width: 800, height: 480))
        super.init()

        terminalView.controller = self
        terminalView.processDelegate = self
        start(shellPath: shellPath, cwd: cwd)
    }

    private func start(shellPath: String, cwd: String) {
        let execName = ShellResolver.loginExecName(forShellPath: shellPath)
        terminalView.startProcess(
            executable: shellPath,
            args: [],
            environment: nil,
            execName: execName,
            currentDirectory: cwd
        )
        lastActivityAt = Date()
        // The PTY buffers stdin, so sending right after startProcess is safe — the shell reads it
        // once it is up. See PLAN.md / the improvements plan "Initial-command timing" risk note.
        if let command = initialCommand {
            runCommand(command)
        }
    }

    /// Writes a command line to the shell's stdin, as if the user typed it and pressed Return.
    func runCommand(_ command: String) {
        terminalView.send(txt: command + "\n")
    }

    var isProcessRunning: Bool {
        terminalView.process?.running ?? false
    }

    func terminate() {
        guard isProcessRunning else { return }
        terminalView.terminate()
    }

    /// Visually clears the screen and scrollback (Cmd+K), leaving the shell session untouched.
    func clear() {
        terminalView.feed(text: "\u{1B}[2J\u{1B}[3J\u{1B}[H")
        buffer.clear()
    }

    // MARK: - Output ingestion (called from AgentTerminalView.dataReceived)

    func ingest(_ slice: ArraySlice<UInt8>) {
        lastActivityAt = Date()
        if slice.contains(0x07) {
            bellPending = true
        }
        var text = decoder.decode(slice)
        if !text.isEmpty {
            if let afterClear = ScreenClearDetector.textAfterLastClear(text) {
                buffer.clear()
                text = afterClear
            }
            buffer.ingest(AnsiSanitizer.strip(text))
        }
        attentionSignaled = AttentionEvaluator.evaluate(
            latestLine: buffer.trailingLine,
            bellPending: bellPending,
            isSelected: isSelected
        )
    }

    // MARK: - Search (thin passthroughs to the SwiftTerm view)

    @discardableResult
    func findNext(_ term: String, caseSensitive: Bool, regex: Bool) -> Bool {
        guard !term.isEmpty else { return false }
        return terminalView.findNext(
            term,
            options: SearchOptions(caseSensitive: caseSensitive, regex: regex),
            scrollToResult: true
        )
    }

    @discardableResult
    func findPrevious(_ term: String, caseSensitive: Bool, regex: Bool) -> Bool {
        guard !term.isEmpty else { return false }
        return terminalView.findPrevious(
            term,
            options: SearchOptions(caseSensitive: caseSensitive, regex: regex),
            scrollToResult: true
        )
    }

    func clearSearch() {
        terminalView.clearSearch()
    }

    func snapshot() -> TerminalSnapshot {
        TerminalSnapshot(
            tail: buffer.lines,
            lastActivityAt: lastActivityAt,
            inferred: inference.infer(text: buffer.snapshotText)
        )
    }

    // MARK: - LocalProcessTerminalViewDelegate

    func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}

    func setTerminalTitle(source: LocalProcessTerminalView, title: String) {}

    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
        store?.updateCwd(id: sessionID, directory)
    }

    func processTerminated(source: TerminalView, exitCode: Int32?) {
        store?.handleProcessExit(id: sessionID, exitCode: exitCode)
    }
}
