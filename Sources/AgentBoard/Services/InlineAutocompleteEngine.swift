import Foundation
import SwiftTerm

final class InlineAutocompleteEngine {
    enum State: Equatable {
        case inactive
        case collecting
        case suggesting(completion: String)
    }

    private(set) var state: State = .inactive
    private var inputBuffer = ""
    private let historyStore: CommandHistoryStore
    private weak var terminalView: AgentTerminalView?
    private var outputDebounceItem: DispatchWorkItem?
    private var escBuffer: [UInt8] = []
    private var escTimer: DispatchWorkItem?
    private var inBracketedPaste = false

    var currentCompletion: String {
        if case .suggesting(let completion) = state { return completion }
        return ""
    }

    var isSuggesting: Bool {
        if case .suggesting = state { return true }
        return false
    }

    init(historyStore: CommandHistoryStore, terminalView: AgentTerminalView?) {
        self.historyStore = historyStore
        self.terminalView = terminalView
    }

    var isEnabled: Bool = true

    func shouldAccept(data: ArraySlice<UInt8>) -> Bool {
        guard isEnabled, isSuggesting else { return false }
        let bytes = Array(data)
        if bytes == [0x1B, 0x5B, 0x43] { return true }
        if bytes == [0x09] { return true }
        return false
    }

    func didAccept() {
        inputBuffer += currentCompletion
        state = .inactive
        terminalView?.hideGhostText()
    }

    func handleOutgoing(data: ArraySlice<UInt8>) {
        guard !inBracketedPaste else {
            let bytes = Array(data)
            // Bracketed paste end: ESC [ 2 0 1 ~
            if bytes.count >= 6 && bytes.suffix(6) == [0x1B, 0x5B, 0x32, 0x30, 0x31, 0x7E] {
                inBracketedPaste = false
            }
            return
        }

        for byte in data {
            handleByte(byte)
        }
    }

    private func handleByte(_ byte: UInt8) {
        // Detect bracketed paste start: ESC [ 2 0 0 ~
        if byte == 0x1B {
            escBuffer = [byte]
            return
        }

        if !escBuffer.isEmpty {
            escBuffer.append(byte)
            if escBuffer.count == 6 && escBuffer == [0x1B, 0x5B, 0x32, 0x30, 0x30, 0x7E] {
                inBracketedPaste = true
                escBuffer = []
                hideSuggestion()
                return
            }
            if escBuffer.count >= 6 || (escBuffer.count >= 2 && byte >= 0x40 && byte <= 0x7E && escBuffer.count >= 3) {
                escBuffer = []
                hideSuggestion()
                return
            }
            return
        }

        switch byte {
        case 0x0D: // Enter
            let command = inputBuffer
            inputBuffer = ""
            hideSuggestion()
            state = .inactive
            if !command.isEmpty {
                historyStore.record(command)
            }

        case 0x7F: // Backspace
            if !inputBuffer.isEmpty {
                inputBuffer.removeLast()
            }
            evaluateSuggestion()

        case 0x15: // Ctrl-U
            inputBuffer = ""
            hideSuggestion()

        case 0x03: // Ctrl-C
            inputBuffer = ""
            hideSuggestion()

        case 0x20...0x7E: // Printable ASCII
            inputBuffer.append(Character(UnicodeScalar(byte)))
            evaluateSuggestion()

        default:
            break
        }
    }

    func handlePTYOutput() {
        hideSuggestion()
        outputDebounceItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            self?.reevaluateAfterOutput()
        }
        outputDebounceItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: item)
    }

    func reset() {
        inputBuffer = ""
        hideSuggestion()
        state = .inactive
    }

    // MARK: - Private

    private func reevaluateAfterOutput() {
        guard !inputBuffer.isEmpty else { return }
        evaluateSuggestion()
    }

    private func evaluateSuggestion() {
        guard isEnabled else {
            hideSuggestion()
            return
        }

        guard let terminalView = terminalView else {
            hideSuggestion()
            return
        }

        guard !terminalView.terminal.isCurrentBufferAlternate else {
            hideSuggestion()
            return
        }

        guard inputBuffer.count >= 2 else {
            hideSuggestion()
            return
        }

        let matches = historyStore.suggestions(forPrefix: inputBuffer, limit: 1)
        guard let bestMatch = matches.first else {
            hideSuggestion()
            return
        }

        let completion = String(bestMatch.dropFirst(inputBuffer.count))
        guard !completion.isEmpty else {
            hideSuggestion()
            return
        }

        state = .suggesting(completion: completion)
        showOverlay(completion: completion)
    }

    private func showOverlay(completion: String) {
        terminalView?.showGhostText(completion)
    }

    private func hideSuggestion() {
        if case .suggesting = state {
            state = .collecting
        }
        terminalView?.hideGhostText()
    }
}
