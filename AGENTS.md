# Agent Instructions

- macOS 14+ SwiftPM app. No Xcode project.
- After any code change: `./script/build_and_run.sh --verify`
- Tests: `./script/run_tests.sh` (required wrapper; plain `swift test` won't work)
- Verify the feature in the launched app before reporting done.
- If build/launch/tests fail, report the exact command and the blocker.
- Do not assume an already-open app includes your changes; rebuild first.
