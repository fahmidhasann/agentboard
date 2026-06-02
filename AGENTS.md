# CLAUDE.md

## What this is

AgentBoard — native macOS 14+ SwiftPM app. A single-window command center for multiple embedded terminal sessions. SwiftUI shell + SwiftTerm for terminal emulation. No Xcode project.

## Commands

```bash
./script/build_and_run.sh            # build (debug), stage dist/AgentBoard.app, launch
./script/build_and_run.sh --verify   # above + confirm process is running
./script/build_and_run.sh --release  # release build
./script/run_tests.sh                # run all unit tests (required wrapper — plain `swift test` won't work)
./script/run_tests.sh --filter Name  # run one test case
./script/create_dmg.sh               # release build + DMG
swift build                          # bare build (no .app bundle / launch)
```

## Agent workflow

1. After any code change: `./script/build_and_run.sh --verify`
2. Run `./script/run_tests.sh` when tests are affected.
3. Verify the feature in the running app before reporting done.
4. If build/launch/tests fail, report the exact command and blocker.

## Architecture (critical invariants)

- **Persisted value types vs. live controllers** — `AgentSession` (Codable struct, persisted to JSON) is separate from `TerminalSessionController` (reference type, never persisted). All session lifecycle goes through `SessionStore`.
- **Periodic sync loop** (0.5s timer in `SessionStore.activate()`) pulls snapshots from controllers, recomputes status/inference, and debounces saves. Do NOT bypass it by mutating sessions from the output path.
- **Inference locks** — `isSummaryUserEdited` / `isAgentUserEdited` prevent auto-inference from overwriting user renames.
- **SwiftTerm pinned to a specific revision** in `Package.swift` (not a tag). The released tags lack required APIs (`open LocalProcessTerminalView`, overridable `dataReceived(slice:)`, `currentDirectory:` on `startProcess`). Do not upgrade without re-verifying.
- **Tests use `swift-testing`** (`@Test`/`#expect`), not XCTest. The `run_tests.sh` wrapper is required on CLI-tools-only machines.

## Key paths

- Persistence: `~/Library/Application Support/AgentBoard/` (sessions.json, preferences.json)
- Bundle ID: `com.fahmid.AgentBoard`
- Version: `script/version.sh` (0.9.0, build 1)
