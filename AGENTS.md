# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## What this is

AgentBoard is a native macOS 14+ SwiftPM GUI app: a single-window command center for multiple embedded terminal sessions. A `NavigationSplitView` shows sessions in a native sidebar (with task summary, inferred agent label, and status badge); selecting one shows its live terminal in the detail pane. SwiftUI is the app shell; SwiftTerm provides terminal emulation. `PLAN.md` is the original implementation spec and remains the authoritative description of intended behavior.

## Commands

```bash
./script/build_and_run.sh            # build (debug), stage dist/AgentBoard.app, launch
./script/build_and_run.sh --verify   # the above, then confirm the process is running via pgrep
./script/build_and_run.sh --release  # release build
./script/run_tests.sh                # run all unit tests
./script/run_tests.sh --filter SessionStoreTests          # run one test target/case
swift build                          # bare build (no .app bundle / launch)
```

`build_and_run.sh` is the canonical launcher — it `pkill`s any running instance, rebuilds, regenerates `dist/AgentBoard.app/Contents/Info.plist` (bundle ID `com.fahmid.AgentBoard`), copies the executable in, and `open -n`s it. There is no Xcode project; everything is SwiftPM.

**Tests require the `run_tests.sh` wrapper** on a Command-Line-Tools-only machine: it points swift at the developer frameworks dir so the bundled swift-testing framework resolves. Plain `swift test` only works with full Xcode installed. The tests use the `swift-testing` framework (`@Test`/`#expect`), not XCTest.

## Architecture

The design splits **persisted value-type metadata** from **non-persisted live terminal controllers**. This separation is the core idea — internalize it before changing session/terminal code.

- **`SessionStore` (Stores/SessionStore.swift)** — the singleton source of truth (`SessionStore.shared`). Holds `@Published sessions: [AgentSession]` (value types, persisted to JSON) and a private `[UUID: TerminalSessionController]` map (reference types, never persisted). All session lifecycle (add/close/restart/clear/rename/select) goes through here. On relaunch, sessions reload from JSON forced to `.exited` status with their recent tail intact — live processes do not survive a restart, but can be restarted, reseeding the new terminal with the saved tail.

- **`TerminalSessionController` (Services/TerminalSessionController.swift)** — owns one live shell: a `AgentTerminalView` (a `LocalProcessTerminalView` subclass that mirrors raw output to the controller via an overridden `dataReceived(slice:)` while still feeding `super`), the process, and rolling tail/inference state. Acts as `LocalProcessTerminalViewDelegate`, forwarding cwd updates (OSC 7) and process-exit events back to the store. All mutation happens on the main thread (SwiftTerm delivers callbacks there) — no locking.

- **Periodic sync loop** — `SessionStore.activate()` starts a 0.5s timer that pulls a `TerminalSnapshot` from every controller, recomputes status via `StatusService`, applies label inference via `LabelInferenceService`, and schedules a debounced save. This cadence is what coalesces high-frequency terminal output into bounded UI/disk updates — do not bypass it by mutating sessions from the output path directly.

- **Inference & status** — `LabelInferenceService` derives the agent label (`codex`/`Codex`/`gemini`/`aider`, else `Shell`) and a short summary from terminal text only (no remote calls, ever). `apply(_:to:)` respects the `isSummaryUserEdited`/`isAgentUserEdited` locks — once a user renames a field, inference stops touching it. `StatusService` maps activity into `running`/`idle`/`attentionNeeded`/`exited`.

- **Persistence** — JSON under Application Support (`AppPaths.appSupportDirectory`), `sessions.json`. Saves are debounced (`scheduleSave`, 1.5s) or immediate (`saveNow`, atomic write). Only metadata + the last `tailLimit` (default 500) terminal lines are stored. Corrupt JSON is backed up to `sessions.corrupt-<timestamp>.json` and the app starts empty.

- **App lifecycle (App/AppDelegate.swift)** — SwiftUI scenes don't cover the macOS behaviors, so the `AppDelegate` handles them: closing the window *hides* it (sessions keep running), quitting warns if any session is live, and it frees the default ⌘W from File ▸ Close so the Session menu's "Close Session" can claim it. Menu commands and shortcuts (⌘N, ⌘W, ⌘K, ⌘⇧P, ⌘1…9) live in `AppCommands` in App/AgentBoardApp.swift.

## Conventions & gotchas

- SwiftTerm is pinned to a specific **revision**, not a tag, in `Package.swift` — see the comment there. The released 1.2.x tags lack `open LocalProcessTerminalView`, the overridable `dataReceived(slice:)`, and `currentDirectory:` on `startProcess`; the plan's original revision fails to compile (undefined `SyncDebug`). Don't "upgrade" to a tag without re-verifying these APIs.
- Shells launch as login shells: `ShellResolver.loginExecName` produces the `-zsh` style `execName`, resolving `$SHELL` (fallback `/bin/zsh`), launched in `NSHomeDirectory()`.
- `attentionNeeded` is raised only for **unselected** sessions, on a bell (0x07) or prompt-like output; viewing a session clears it. Background notifications fire only when notifications are enabled and the session is backgrounded.
- The Codex run actions (`.codex/environments/environment.toml`) just shell out to `build_and_run.sh`.
