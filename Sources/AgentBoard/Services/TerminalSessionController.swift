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
    private(set) var autocompleteEngine: InlineAutocompleteEngine?
    private let ghostOverlay = GhostTextOverlay()

    /// Flips true the first time the view is on-screen at a real size, so the controller can run
    /// any deferred initial command only after the PTY has its correct dimensions.
    private var didSignalReady = false

    func setupAutocomplete(historyStore: CommandHistoryStore) {
        autocompleteEngine = InlineAutocompleteEngine(
            historyStore: historyStore,
            terminalView: self
        )
    }

    func showGhostText(_ text: String) {
        let buffer = terminal.buffer
        let cellSize = Self.computeCellSize(font: font)
        let cursorX = cellSize.width * CGFloat(buffer.x)
        let cursorY = cellSize.height * CGFloat(buffer.y)
        ghostOverlay.show(text: text, at: CGPoint(x: cursorX, y: cursorY), cellHeight: cellSize.height)
    }

    private static func computeCellSize(font: NSFont) -> CGSize {
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let sample = "W" as NSString
        let size = sample.size(withAttributes: attrs)
        return CGSize(width: ceil(size.width), height: ceil(size.height))
    }

    func hideGhostText() {
        ghostOverlay.hide()
    }

    override func send(source: TerminalView, data: ArraySlice<UInt8>) {
        if let engine = autocompleteEngine {
            engine.isEnabled = PreferencesStore.shared.preferences.inlineAutocompleteEnabled
            if engine.shouldAccept(data: data) {
                let completionBytes = Array(engine.currentCompletion.utf8)
                super.send(source: source, data: completionBytes[0...])
                engine.didAccept()
                return
            }
            engine.handleOutgoing(data: data)
        }
        super.send(source: source, data: data)
    }

    override func dataReceived(slice: ArraySlice<UInt8>) {
        super.dataReceived(slice: slice)
        controller?.ingest(slice)
        autocompleteEngine?.handlePTYOutput()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        controller?.focusIfSelected()
        if ghostOverlay.superview == nil {
            addSubview(ghostOverlay)
        }
        guard window != nil, let process = self.process, process.running else { return }
        DispatchQueue.main.async { [self] in
            terminal.updateFullScreen()
            needsDisplay = true
            var size = self.getWindowSize()
            let _ = PseudoTerminalHelpers.setWinSize(masterPtyDescriptor: process.childfd, windowSize: &size)
            signalReadyIfNeeded()
        }
    }

    /// SwiftTerm recomputes the terminal grid (and the PTY winsize) here on every resize. Once that
    /// has happened at a real on-screen size, the controller can safely run a deferred initial
    /// command at the correct dimensions.
    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        signalReadyIfNeeded()
    }

    private func signalReadyIfNeeded() {
        guard !didSignalReady, window != nil, bounds.width > 1, bounds.height > 1 else { return }
        didSignalReady = true
        controller?.viewDidBecomeReady()
    }

    func applyThemeColors() {
        // Resolve the dynamic system colors against this view's *own* appearance rather than
        // whatever appearance happens to be current — otherwise a freshly created terminal can
        // paint dark-on-dark (or light-on-light) and look broken until the next redraw.
        effectiveAppearance.performAsCurrentDrawingAppearance {
            nativeForegroundColor = .textColor
            nativeBackgroundColor = .textBackgroundColor
            layer?.backgroundColor = nativeBackgroundColor.cgColor
        }
        terminal.updateFullScreen()
        needsDisplay = true
    }

    func updateAutocompleteFont(_ font: NSFont) {
        ghostOverlay.updateFont(font)
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
    /// Stable per-controller identity. A session keeps the same `sessionID` across a restart, but
    /// gets a fresh controller (and a fresh `terminalView`). The detail view keys its hosted
    /// `NSView` on this so restarting reliably swaps in the new live terminal instead of leaving
    /// the dead one on screen.
    let instanceID = UUID()
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

    /// Command to auto-run once the shell is live (e.g. launching an agent in a new session). Held
    /// until the terminal view is on-screen at its real size so TUIs start at the correct grid.
    private var pendingInitialCommand: String?

    init(
        sessionID: UUID,
        shellPath: String,
        cwd: String,
        tailLimit: Int,
        seedTail: [String],
        store: SessionStore,
        fontSize: Double = 13,
        initialCommand: String? = nil
    ) {
        self.sessionID = sessionID
        self.store = store
        self.buffer = RecentLineBuffer(limit: tailLimit, seed: seedTail)
        self.pendingInitialCommand = (initialCommand?.isEmpty == false) ? initialCommand : nil
        self.terminalView = AgentTerminalView(frame: CGRect(x: 0, y: 0, width: 800, height: 480))
        super.init()

        terminalView.controller = self
        terminalView.processDelegate = self
        // Set the font *before* launching so the PTY's initial winsize is computed with the same
        // cell metrics the view will display. Otherwise the grid changes the instant the view
        // appears (font is applied in TerminalRepresentable), reflowing the shell's first output.
        terminalView.font = NSFont.monospacedSystemFont(ofSize: CGFloat(fontSize), weight: .regular)
        terminalView.setupAutocomplete(historyStore: CommandHistoryStore.shared)
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
        // The initial command is held until the view is on-screen at its real size (see
        // viewDidBecomeReady) so agent TUIs launch at the correct dimensions. This fallback
        // guarantees it still runs if the view never becomes ready (e.g. the window is hidden).
        if pendingInitialCommand != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.runPendingInitialCommand()
            }
        }
    }

    /// Called by the terminal view once it is on-screen at its real size. Runs the deferred initial
    /// command (if any) now that the PTY has the correct dimensions.
    func viewDidBecomeReady() {
        DispatchQueue.main.async { [weak self] in
            self?.runPendingInitialCommand()
        }
    }

    private func runPendingInitialCommand() {
        guard let command = pendingInitialCommand else { return }
        pendingInitialCommand = nil
        runCommand(command)
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

    func updateTailLimit(_ limit: Int) {
        buffer.updateLimit(limit)
    }

    // MARK: - Focus

    func focusIfSelected() {
        guard isSelected else { return }
        focusTerminal()
    }

    /// Makes the terminal the first responder so typed input goes to it.
    ///
    /// This deliberately does **not** activate the app or reorder windows: routine session
    /// selection should never yank AgentBoard to the foreground over whatever the user is doing.
    /// Bringing the window forward is the app lifecycle's job (see `AppDelegate`), which activates
    /// before asking the store to refocus.
    func focusTerminal(retries: Int = 4) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.focusTerminal(retries: retries)
            }
            return
        }

        guard let window = terminalView.window else {
            guard retries > 0 else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                self?.focusTerminal(retries: retries - 1)
            }
            return
        }

        guard window.makeFirstResponder(terminalView) || retries == 0 else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                self?.focusTerminal(retries: retries - 1)
            }
            return
        }
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

    func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {
        terminalView.autocompleteEngine?.reset()
    }

    func setTerminalTitle(source: LocalProcessTerminalView, title: String) {}

    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
        store?.updateCwd(id: sessionID, directory)
    }

    func processTerminated(source: TerminalView, exitCode: Int32?) {
        store?.handleProcessExit(id: sessionID, exitCode: exitCode)
    }
}
