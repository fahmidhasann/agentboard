# AgentBoard Refactoring Checklist

Identified duplication patterns across the codebase. Each item is self-contained — start a new Claude Code session, open the relevant files, and follow the instructions. Items are ordered by value (highest first).

---

## Significant

### [x] 1. Extract `sessionIndex(for:)` helper in `SessionStore`

**Files:** `Sources/AgentBoard/Stores/SessionStore.swift`

**Problem:** The pattern `sessions.firstIndex(where: { $0.id == id })` is repeated 6 times at lines 177, 231, 240, 272, 283, 304. Each caller guards on nil and returns early.

**What to do:**
Add a private helper method to `SessionStore`:
```swift
private func sessionIndex(for id: UUID) -> Int? {
    sessions.firstIndex { $0.id == id }
}
```
Then replace every occurrence of `sessions.firstIndex(where: { $0.id == id })` with `sessionIndex(for: id)`. Note: line 343 uses a similar lookup but with a status check — leave that one as-is since it has additional logic.

**Verify:** Run `./script/run_tests.sh` — all tests should pass.

---

### [x] 2. Consolidate session action buttons into a shared `@ViewBuilder`

**Files:**
- `Sources/AgentBoard/Views/SidebarView.swift` (lines 65–71, inside `contextMenu`)
- `Sources/AgentBoard/Views/TerminalDetailView.swift` (lines 62–74, toolbar buttons)

**Problem:** Both views implement the same 4 session actions (Rename, Clear Terminal, Restart, Close Session) with identical `store.*` calls. Fixing a label or adding an action requires editing both files.

**What to do:**
Create a new file `Sources/AgentBoard/Views/SessionActionButtons.swift` with a `@ViewBuilder` function (or a `View` struct) that accepts a `session: AgentSession` and `store: SessionStore` and emits the four `Button`s. Both `SidebarView.contextMenu` and `TerminalDetailView` toolbar then call this shared builder instead of duplicating the buttons.

The SidebarView context menu uses text-only `Button("Rename…")` style. The TerminalDetailView toolbar uses `Label("Rename", systemImage: "pencil")` style. You can parameterize a `style` enum (`.menu` / `.toolbar`) or produce two separate helpers — whichever keeps the call sites cleanest.

**Verify:** Build with `./script/build_and_run.sh` and confirm both the sidebar right-click menu and the toolbar buttons still work for all 4 actions.

---

## Moderate

### [x] 3. Deduplicate JSON encoder configuration

**Files:**
- `Sources/AgentBoard/Stores/SessionStore.swift` (lines 424–425)
- `Sources/AgentBoard/Stores/PreferencesStore.swift` (lines 31–32)

**Problem:** Both stores create a `JSONEncoder` with identical configuration:
```swift
let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
```

**What to do:**
Add a file-private or internal extension in a new `Sources/AgentBoard/Support/JSONHelpers.swift` (or add to an existing support file):
```swift
extension JSONEncoder {
    static var agentBoard: JSONEncoder {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }
}
```
Replace both two-line blocks with `let encoder = JSONEncoder.agentBoard`.

**Verify:** Run `./script/run_tests.sh`. Check that `sessions.json` and `preferences.json` still serialize correctly after a launch.

---

### [x] 4. Consolidate `focusSelectedTerminal` dispatch at sheet/view dismissal

**Files:**
- `Sources/AgentBoard/Views/NewSessionSheet.swift` (lines 102–103, inside `close()`)
- `Sources/AgentBoard/Views/CommandPaletteView.swift` (lines 91–92, inside `close(refocusTerminal:)`)
- `Sources/AgentBoard/Views/ContentView.swift` (line 102)
- `Sources/AgentBoard/Views/TerminalDetailView.swift` (line 92)

**Problem:** All four sites do the same async dispatch:
```swift
DispatchQueue.main.async { [store] in
    store.focusSelectedTerminal()
}
```

**What to do:**
Add a `focusSelectedTerminalAsync()` convenience method to `SessionStore` that wraps this dispatch internally:
```swift
func focusSelectedTerminalAsync() {
    DispatchQueue.main.async { [weak self] in
        self?.focusSelectedTerminal()
    }
}
```
Replace the four call sites with `store.focusSelectedTerminalAsync()`. This also centralises any future changes to the focus timing/retry logic.

**Verify:** Build and manually confirm that dismissing the New Session sheet, the Command Palette, and switching sessions all still refocus the terminal correctly.

---

### [x] 5. Unify sheet `close()` dismiss pattern

**Files:**
- `Sources/AgentBoard/Views/NewSessionSheet.swift` (lines 99–104)
- `Sources/AgentBoard/Views/CommandPaletteView.swift` (lines 88–94)
- `Sources/AgentBoard/Views/RenameSheet.swift` (lines 6, 30, 44 — uses `@Environment(\.dismiss)`)

**Problem:** Each sheet has its own `close()` / dismiss function that sets `isPresenting* = false` then optionally refocuses the terminal. They're structurally identical but can drift independently.

**What to do:**
This is lower-priority cleanup — the sheets have slightly different state to clear (`newSessionPrefill`, `isPresentingCommandPalette`, etc.) so a single shared function isn't possible without over-engineering. The practical fix is: after completing item 4 above (which removes the async dispatch duplication), audit the three `close()` functions and add a comment linking them so a future change is made consistently. Alternatively, if the sheets gain more shared teardown logic, extract a `SheetDismissHandler` coordinator at that point.

**Verify:** N/A (comment/documentation change only, unless code is consolidated).

---

## Minor

### [x] 6. Extract logger subsystem string to a constant

**Files:**
- `Sources/AgentBoard/Stores/SessionStore.swift` (line 13)
- `Sources/AgentBoard/Stores/PreferencesStore.swift` (line 8)

**Problem:** Both loggers hardcode `"com.fahmid.AgentBoard"` as the subsystem string. If the bundle ID changes, both need updating.

**What to do:**
Add to `Sources/AgentBoard/Support/AppPaths.swift` (or a constants file):
```swift
enum AppConstants {
    static let bundleID = "com.fahmid.AgentBoard"
}
```
Update both logger declarations to use `AppConstants.bundleID`.

**Verify:** Build — no runtime change expected.

---

### [x] 7. Centralise `NSHomeDirectory()` usage

**Files:**
- `Sources/AgentBoard/Models/AgentSession.swift` (path abbreviation)
- `Sources/AgentBoard/Views/NewSessionSheet.swift` (default start path)
- `Sources/AgentBoard/Support/AppPaths.swift` (base paths)
- `Sources/AgentBoard/Stores/SessionStore.swift` (fallback path)

**Problem:** `NSHomeDirectory()` is called directly in 4 places. Minor: if the home directory resolution ever needs to change (e.g. sandboxing), all 4 sites need updating.

**What to do:**
`AppPaths.swift` already exists for path constants — add `static let home = NSHomeDirectory()` there and replace the other 3 call sites with `AppPaths.home`.

**Verify:** Build and confirm session creation with the default path still works.

---

*Generated by `/code-structure` audit on 2026-06-04. Run `./script/run_tests.sh` after each change to confirm nothing broke.*
