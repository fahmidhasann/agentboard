# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

AgentBoard is a native macOS 14+ SwiftPM GUI app: a single-window command center for multiple embedded terminal sessions. A `NavigationSplitView` shows sessions in a native sidebar (with display title, inferred agent label, and status badge); selecting one shows its live terminal in the detail pane. SwiftUI is the app shell; SwiftTerm provides terminal emulation.

## Commands

```bash
./script/build_and_run.sh            # build (debug), stage dist/AgentBoard.app, launch
./script/build_and_run.sh --verify   # the above, then confirm the process is running via pgrep
./script/build_and_run.sh --release  # release build
./script/run_tests.sh                # run all unit tests
./script/run_tests.sh --filter SessionStorePersistenceTests   # run one suite
./script/run_tests.sh --filter "loads sessions as exited"       # run one test by name
./script/create_dmg.sh               # release build + DMG to dist/AgentBoard-<ver>-arm64.dmg
swift build                          # bare build (no .app bundle / launch)
```

`build_and_run.sh` is the canonical launcher — it `pkill`s any running instance, rebuilds, regenerates `dist/AgentBoard.app/Contents/Info.plist` (bundle ID `com.fahmid.AgentBoard`), copies the executable in, and `open -n`s it. There is no Xcode project; everything is SwiftPM.

**Tests require the `run_tests.sh` wrapper** on a Command-Line-Tools-only machine: it points swift at the developer frameworks dir so the bundled swift-testing framework resolves. Plain `swift test` only works with full Xcode installed. The tests use the `swift-testing` framework (`@Test`/`#expect`), not XCTest.

## Source layout

```
Sources/AgentBoard/
  App/          AgentBoardApp.swift (@main, scenes, AppCommands), AppDelegate.swift (lifecycle)
  Models/       AgentSession, AgentBoardPreferences, AgentLaunchConfig (all Codable value types)
  Stores/       SessionStore (singleton, sessions + controllers), PreferencesStore (singleton)
  Services/     TerminalSessionController, LabelInferenceService, StatusService,
                CommandPaletteModel, NotificationService, UpdateCheckService
  Support/      RecentLineBuffer (ring buffer + ANSI sanitizer + attention evaluator),
                ShellResolver, AppPaths
  Views/        ContentView, SidebarView, TerminalDetailView, TerminalRepresentable,
                CommandPaletteView, SidebarRowView, NewSessionSheet, SettingsView, FindBar
  Resources/    AppIcon.icns
Tests/AgentBoardTests/
script/         build_and_run.sh, run_tests.sh, create_dmg.sh, version.sh
```

## Architecture

The design splits **persisted value-type metadata** from **non-persisted live terminal controllers**. This separation is the core idea — internalize it before changing session/terminal code.

- **`SessionStore` (Stores/SessionStore.swift)** — the singleton source of truth (`SessionStore.shared`). Holds `@Published sessions: [AgentSession]` (value types, persisted to JSON) and a private `[UUID: TerminalSessionController]` map (reference types, never persisted). All session lifecycle (add/close/restart/clear/rename/select) goes through here. On relaunch, sessions reload from JSON forced to `.exited` status with their recent tail intact — live processes do not survive a restart, but can be restarted, reseeding the new terminal with the saved tail.

- **`TerminalSessionController` (Services/TerminalSessionController.swift)** — owns one live shell: a `AgentTerminalView` (a `LocalProcessTerminalView` subclass that mirrors raw output to the controller via an overridden `dataReceived(slice:)` while still feeding `super`), the process, and rolling tail/inference state. Acts as `LocalProcessTerminalViewDelegate`, forwarding cwd updates (OSC 7) and process-exit events back to the store. All mutation happens on the main thread (SwiftTerm delivers callbacks there) — no locking.

- **Terminal output pipeline** — raw bytes flow: `dataReceived(slice:)` → `UTF8StreamDecoder` (holds back incomplete multi-byte sequences) → `AnsiSanitizer` (strips VT/C0 escapes except tab & newline) → `RecentLineBuffer` (ring buffer, default 500 lines, splits on newlines, holds partial fragments). `AttentionEvaluator` runs heuristics on trailing lines (yes/no brackets, password cues, shell sigils) to raise attention.

- **Periodic sync loop** — `SessionStore.activate()` starts a 0.5s timer that pulls a `TerminalSnapshot` from every controller, recomputes status via `StatusService`, applies label inference via `LabelInferenceService`, and schedules a debounced save. This cadence is what coalesces high-frequency terminal output into bounded UI/disk updates — do not bypass it by mutating sessions from the output path directly.

- **Inference & status** — `LabelInferenceService` derives the agent label from terminal text only (no remote calls, ever). Known agents: Codex, Claude, Gemini, OpenCode, Aider, Hermes — anything else leaves the label unchanged. `apply(_:to:)` only updates `agentLabel` and respects `isAgentUserEdited` — once the user renames the agent field, inference stops touching it. New sessions seed `summary` from the launch directory (`AgentSession.abbreviatedPath`); `summary` is user-editable via rename and is not inferred from terminal output. `StatusService` maps activity into `running`/`idle`/`attentionNeeded`/`exited` (idle threshold: 60s).

- **Persistence** — JSON under `~/Library/Application Support/AgentBoard/` (`AppPaths`). Two files: `sessions.json` (session metadata + tail) and `preferences.json` (font size, theme, tail limit, agents list, etc.). Session saves are debounced (`scheduleSave`, 1.5s) or immediate (`saveNow`, atomic write). Only metadata + the last `tailLimit` (default 500) terminal lines are stored. Corrupt JSON is backed up to `sessions.corrupt-<timestamp>.json` and the app starts empty.

- **App lifecycle (App/AppDelegate.swift)** — SwiftUI scenes don't cover the macOS behaviors, so the `AppDelegate` handles them: closing the window *hides* it (sessions keep running), quitting warns if any session is live, and it frees the default ⌘W from File ▸ Close so the Session menu's "Close Session" can claim it. Menu commands and shortcuts (⌘N, ⌘W, ⌘K, ⌘⇧P, ⌘1…9) live in `AppCommands` in App/AgentBoardApp.swift.

## Conventions & gotchas

- SwiftTerm is pinned to a specific **revision**, not a tag, in `Package.swift` — see the comment there. The released 1.2.x tags lack `open LocalProcessTerminalView`, the overridable `dataReceived(slice:)`, and `currentDirectory:` on `startProcess`; the plan's original revision fails to compile (undefined `SyncDebug`). Don't "upgrade" to a tag without re-verifying these APIs.
- Shells launch as login shells: `ShellResolver.loginExecName` produces the `-zsh` style `execName`, resolving `$SHELL` (fallback `/bin/zsh`), launched in `NSHomeDirectory()`.
- `attentionNeeded` is raised only for **unselected** sessions, on a bell (0x07) or prompt-like output; viewing a session clears it. Background notifications fire only when notifications are enabled and the session is backgrounded.
- `NotificationService` guards on bundle identifier presence — `UNUserNotificationCenter` traps on bare executables without a bundle, so notifications only work when launched as the staged `.app`.
- Version is centralized in `script/version.sh` — sourced by all build scripts and the CI workflow.
- CI (`.github/workflows/ci.yml`) runs unit tests on pushes to `main`; release (`.github/workflows/release.yml`) triggers on `v*` tags, runs tests, builds a release DMG on macOS 14, and publishes to GitHub Releases.
- The Codex run actions (`.codex/environments/environment.toml`) just shell out to `build_and_run.sh`.

## Release workflow

The release pipeline is fully automated. When the user asks to "release" or "ship" a new version:

1. **Bump version** — edit `script/version.sh` to the new `APP_VERSION` (e.g. `"0.11.0"`).
2. **Commit** — stage and commit the version bump (and any other pending changes).
3. **Tag** — `git tag v<version>` (e.g. `git tag v0.11.0`).
4. **Push** — `git push origin main --tags`.

That's it. Everything else is automated:
- GitHub Actions builds the release DMG and uploads it to GitHub Releases with both a versioned name (`AgentBoard-0.11.0-arm64.dmg`) and a stable name (`AgentBoard-latest-arm64.dmg`).
- The Vercel landing page (`site/index.html`) uses the permanent URL `https://github.com/fahmidhasann/agentboard/releases/latest/download/AgentBoard-latest-arm64.dmg` — it always serves the newest release without any site changes.
- Vercel only redeploys when files inside `site/` actually change (controlled by `ignoreCommand` in `site/vercel.json`). Pushing app code to `main` does not trigger a redeploy.

**Do not hardcode version numbers in `site/index.html` download links.** The `/releases/latest/download/` pattern handles this automatically.
