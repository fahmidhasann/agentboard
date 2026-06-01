# Fix Garbled Session Names, Agent Detection, and Redesign Sidebar

## Context

Two problems:

1. **Garbled text**: TUI apps (Claude Code / Ink, OpenCode / Bubble Tea) redraw the terminal using `\r` and screen-clear sequences. The `AnsiSanitizer` strips these without simulating their effects, so redraws accumulate and produce garbled names like "ooopencodeooppn eodeeodeneode". This breaks both summary and agent detection.

2. **Sidebar layout doesn't match design**: The current layout shows summary on top with agent label as a small caption. The target design (from reference mockup) shows a different structure per row:
   - Line 1: Status dot + **Agent** - summary (bold agent label, dash separator, summary text)
   - Line 2: ~/path/to/folder (tilde-relative path, caption style)
   - Line 3: Colored status badge pill ("Running", "Idle", "Needs Attention")

## Changes

### 1. Preserve `\r` through the sanitizer

**File:** [RecentLineBuffer.swift:88](Sources/AgentBoard/Support/RecentLineBuffer.swift#L88)

Add `\r` to preserved C0 characters in `AnsiSanitizer.strip()`:
```swift
if u == "\n" || u == "\t" || u == "\r" {
```

### 2. Handle `\r` in `RecentLineBuffer.ingest()`

**File:** [RecentLineBuffer.swift:36-47](Sources/AgentBoard/Support/RecentLineBuffer.swift#L36-L47)

Replace the `ingest` method to:
- Normalize `\r\n` → `\n` (Windows line endings)
- On standalone `\r`, discard everything before it in the current line (simulates cursor returning to column 0)
- Use `lastIndex(of: "\r")` on both completed lines and the trailing partial

### 3. Handle screen-clear sequences

**File:** [TerminalSessionController.swift:132-146](Sources/AgentBoard/Services/TerminalSessionController.swift#L132-L146)

In `ingest()`, after UTF-8 decoding but **before** ANSI stripping:
- Search for `\u{1B}[2J` (erase display) in the decoded text
- If found, clear the buffer and only process text after the **last** occurrence

Extract a `ScreenClearDetector` helper in RecentLineBuffer.swift alongside `AnsiSanitizer`.

### 4. Redesign `SidebarRowView` layout

**File:** [SidebarRowView.swift](Sources/AgentBoard/Views/SidebarRowView.swift)

Redesign each row to match the reference:

```
[dot] Agent - summary
      ~/path/to/folder
      [Running]
```

Key changes to `SidebarRowView.body`:
- **Line 1**: `HStack { StatusBadge, Text(agentLabel).bold() + Text(" - ") + Text(summary) }` — single line, agent bold, summary regular weight, truncated with `.lineLimit(1)`
- **Line 2**: Tilde-relative folder path in caption style, always shown (not gated on `showFolder`)
- **Line 3**: Status badge pill — `Text(status.displayName)` with `.font(.caption2)`, colored background matching status, rounded corners (capsule shape)
- Remove the current small-text agent label + exit code HStack

Status badge pill colors (from reference):
- `.running` → green text on light green background
- `.idle` → gray text on light gray background
- `.attentionNeeded` → orange text on light orange background
- `.exited` → red text on light red background

### 5. Tilde-relative path display

**File:** [SidebarRowView.swift](Sources/AgentBoard/Views/SidebarRowView.swift)

Replace the `folderName` computed property with a `displayPath` that produces tilde-relative paths:
```swift
private var displayPath: String {
    let home = NSHomeDirectory()
    if session.cwd == home { return "~" }
    if session.cwd.hasPrefix(home + "/") {
        return "~/" + session.cwd.dropFirst(home.count + 1)
    }
    return session.cwd
}
```

Apply same logic to `FolderGroup.displayName` in [SidebarView.swift:106-109](Sources/AgentBoard/Views/SidebarView.swift#L106-L109).

### 6. Update `SidebarView` for new row contract

**File:** [SidebarView.swift](Sources/AgentBoard/Views/SidebarView.swift)

- Remove the `showFolder` parameter from `SidebarRowView` calls — the new layout always shows the path
- In grouped mode, the section header can remain (it shows the folder), but each row also shows its path per the reference design

### 7. Tests

**New file:** `Tests/AgentBoardTests/RecentLineBufferTests.swift` (swift-testing framework)

Test cases:
- `AnsiSanitizer.strip()` preserves `\r` while removing other C0 chars and ANSI sequences
- `RecentLineBuffer.ingest()`: standalone `\r` overwrites partial, `\r\n` as newline, multiple `\r`s, cross-chunk `\r`
- `ScreenClearDetector`: text after last `ESC[2J`, nil when absent
- End-to-end: TUI-style redraw → clean `snapshotText`

## Files to modify

| File | Change |
|------|--------|
| `Sources/AgentBoard/Support/RecentLineBuffer.swift` | `\r` in sanitizer, `\r` handling in buffer, `ScreenClearDetector` |
| `Sources/AgentBoard/Services/TerminalSessionController.swift` | Screen-clear detection in `ingest()` |
| `Sources/AgentBoard/Views/SidebarRowView.swift` | Full layout redesign + tilde-relative paths + status badge pill |
| `Sources/AgentBoard/Views/SidebarView.swift` | Remove `showFolder`, tilde path in `FolderGroup` |
| `Tests/AgentBoardTests/RecentLineBufferTests.swift` | New test file |

## Verification

1. `./script/run_tests.sh` — all tests pass
2. `./script/build_and_run.sh --verify` — app launches
3. Manual: launch sessions, confirm sidebar matches reference design — bold agent label, dash, summary, tilde path, colored status pill
4. Manual: launch Claude Code / OpenCode, confirm agent detected correctly and summary is clean
