import Foundation

/// A bounded, line-oriented ring buffer of recent terminal output.
///
/// Bytes arrive in arbitrary chunks, so a partial (newline-less) trailing fragment is held
/// until the rest of the line arrives. `lines` only ever contains completed lines; `snapshotText`
/// additionally includes the in-progress fragment for inference.
struct RecentLineBuffer {
    private(set) var lines: [String]
    private var partial: String = ""
    var limit: Int

    /// Hard cap on a single newline-less fragment, so a binary blob can't grow `partial` forever.
    private let maxFragment = 8192

    init(limit: Int = 500, seed: [String] = []) {
        self.limit = max(1, limit)
        self.lines = Array(seed.suffix(self.limit))
    }

    /// Text including the not-yet-terminated trailing fragment — used for label inference.
    var snapshotText: String {
        if partial.isEmpty { return lines.joined(separator: "\n") }
        return (lines + [partial]).joined(separator: "\n")
    }

    /// The current trailing line of output: the in-progress fragment if present, otherwise the
    /// last completed line (empty when there is no output). The prompt heuristic only cares about
    /// what sits at the bottom of the screen with the cursor waiting, so this avoids re-scanning
    /// the whole buffer on every chunk.
    var trailingLine: String {
        partial.isEmpty ? (lines.last ?? "") : partial
    }

    /// Feed already-sanitized text (newlines and `\r` preserved) into the buffer.
    ///
    /// `\r\n` is treated as a single newline. A standalone `\r` simulates a carriage return by
    /// discarding everything before it on the current line — this is how TUI apps (Ink, Bubble Tea)
    /// overwrite previous content during redraws.
    mutating func ingest(_ text: String) {
        guard !text.isEmpty else { return }
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
        partial += normalized
        while let nl = partial.firstIndex(of: "\n") {
            var line = String(partial[partial.startIndex..<nl])
            if let cr = line.lastIndex(of: "\r") {
                line = String(line[line.index(after: cr)...])
            }
            appendLine(line)
            partial = String(partial[partial.index(after: nl)...])
        }
        if let cr = partial.lastIndex(of: "\r") {
            partial = String(partial[partial.index(after: cr)...])
        }
        if partial.count > maxFragment {
            appendLine(String(partial.suffix(maxFragment)))
            partial = ""
        }
    }

    mutating func appendLine(_ line: String) {
        lines.append(line)
        trim()
    }

    mutating func trim() {
        if lines.count > limit {
            lines.removeFirst(lines.count - limit)
        }
    }

    mutating func updateLimit(_ newLimit: Int) {
        limit = max(1, newLimit)
        trim()
    }

    mutating func clear() {
        lines.removeAll(keepingCapacity: true)
        partial = ""
    }
}

/// Removes ANSI/VT control sequences so stored tail and inference text are human-readable.
enum AnsiSanitizer {
    private static let escapeRegex: NSRegularExpression = {
        let esc = "\u{1B}"
        // OSC: ESC ] ... terminated by BEL or ST (ESC \)
        let osc = esc + "\\][^\u{07}]*(?:\u{07}|" + esc + "\\\\)"
        // CSI: ESC [ params intermediates final
        let csi = esc + "\\[[0-9;?]*[ -/]*[@-~]"
        // Any other two-character escape
        let other = esc + "."
        let pattern = [osc, csi, other].joined(separator: "|")
        // swiftlint:disable:next force_try
        return try! NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
    }()

    static func strip(_ input: String) -> String {
        guard !input.isEmpty else { return input }
        let range = NSRange(input.startIndex..., in: input)
        let noEscapes = escapeRegex.stringByReplacingMatches(in: input, options: [], range: range, withTemplate: "")
        // Drop remaining C0 control chars (incl. carriage returns and BEL) except tab and newline.
        var scalars = String.UnicodeScalarView()
        for u in noEscapes.unicodeScalars {
            if u == "\n" || u == "\t" || u == "\r" {
                scalars.append(u)
            } else if u.value >= 0x20 && u.value != 0x7F {
                scalars.append(u)
            }
        }
        return String(scalars)
    }

    /// Heuristic: does the *trailing* line of this text look like an interactive prompt awaiting
    /// user input? An interactive prompt is the last thing on screen with the cursor waiting at the
    /// end, so we inspect only the last non-empty line. This avoids the false positives of the old
    /// substring match, which fired on ordinary output that merely mentioned words like "continue?".
    static func looksLikePrompt(_ text: String) -> Bool {
        guard let line = lastNonEmptyLine(of: text) else { return false }

        // A bracketed/parenthesized yes-no choice at the end, e.g. "(y/n)", "[y/N]", "yes/no".
        if line.range(of: #"\([yY]/[nN]\)\s*$"#, options: .regularExpression) != nil { return true }
        if line.range(of: #"\[[yYnN]/?[yYnN]\]\s*$"#, options: .regularExpression) != nil { return true }
        if line.range(of: #"(?i)yes/no\s*$"#, options: .regularExpression) != nil { return true }

        // A question that ends with "?" *and* carries a confirmation cue.
        if line.hasSuffix("?") {
            let lower = line.lowercased()
            let cues = ["do you want", "continue", "overwrite", "are you sure", "proceed", "replace"]
            if cues.contains(where: { lower.contains($0) }) { return true }
        }

        // A credential prompt whose keyword sits at the very end, e.g. "Password:", "OTP".
        if line.range(
            of: #"(?i)(password|passphrase|token|otp|verification code)\s*:?\s*$"#,
            options: .regularExpression
        ) != nil { return true }

        // An interactive shell/REPL prompt sigil at the very end.
        if line.range(of: #"[❯›]\s*$"#, options: .regularExpression) != nil { return true }

        return false
    }

    /// The last line of `text` that is non-empty after trimming whitespace, itself trimmed.
    private static func lastNonEmptyLine(of text: String) -> String? {
        for raw in text.split(separator: "\n", omittingEmptySubsequences: false).reversed() {
            let trimmed = raw.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty { return trimmed }
        }
        return nil
    }
}

/// Pure decision for whether a session should raise a background-attention signal.
///
/// Extracted so the controller's `ingest` stays testable: a bell (one-shot, set on `0x07`) or a
/// trailing interactive prompt raises attention, but only while the session is unselected.
/// Recomputing the prompt portion from the latest line every ingest gives free decay — once the
/// agent answers the prompt and streams non-prompt output, the signal clears on its own.
enum AttentionEvaluator {
    static func evaluate(latestLine: String, bellPending: Bool, isSelected: Bool) -> Bool {
        guard !isSelected else { return false }
        return bellPending || AnsiSanitizer.looksLikePrompt(latestLine)
    }
}

/// Detects `ESC[2J` (erase display) sequences in raw decoded text and returns only the
/// content after the last occurrence, so TUI full-screen redraws don't accumulate stale lines.
enum ScreenClearDetector {
    private static let eraseDisplay = "\u{1B}[2J"

    static func textAfterLastClear(_ input: String) -> String? {
        guard let range = input.range(of: eraseDisplay, options: .backwards) else { return nil }
        return String(input[range.upperBound...])
    }
}

/// Incrementally decodes a UTF-8 byte stream, holding back an incomplete trailing
/// multi-byte sequence so characters are never split across chunk boundaries.
struct UTF8StreamDecoder {
    private var carry: [UInt8] = []

    mutating func decode<S: Sequence>(_ bytes: S) -> String where S.Element == UInt8 {
        var buffer = carry
        buffer.append(contentsOf: bytes)
        carry = []
        guard !buffer.isEmpty else { return "" }

        // Walk back over trailing continuation bytes (10xxxxxx) to find the last lead byte.
        var index = buffer.count - 1
        var continuations = 0
        while index >= 0 && (buffer[index] & 0b1100_0000) == 0b1000_0000 && continuations < 3 {
            index -= 1
            continuations += 1
        }

        var cut = buffer.count
        if index >= 0 {
            let lead = buffer[index]
            let expected: Int
            if lead & 0b1000_0000 == 0 { expected = 1 }
            else if lead & 0b1110_0000 == 0b1100_0000 { expected = 2 }
            else if lead & 0b1111_0000 == 0b1110_0000 { expected = 3 }
            else if lead & 0b1111_1000 == 0b1111_0000 { expected = 4 }
            else { expected = 1 }
            if continuations + 1 < expected {
                cut = index // incomplete sequence: hold it back for the next chunk
            }
        }

        let head = Array(buffer[0..<cut])
        carry = Array(buffer[cut...])
        return String(decoding: head, as: UTF8.self)
    }
}
