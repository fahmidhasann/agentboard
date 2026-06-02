# Agent Instructions

- This is a macOS 14+ SwiftPM app. There is no Xcode project.
- After any code change, rebuild and relaunch with `./script/build_and_run.sh --verify`.
- Use `./script/run_tests.sh` for relevant unit tests when tests are available or affected.
- Use `./script/create_dmg.sh` only when a release/installable build is needed.
- Verify the changed feature in the launched `dist/AgentBoard.app` before final response.
- If build, launch, or tests fail, report the exact command and the main blocker.
- Do not assume an already-open AgentBoard app includes source changes; rebuild first.
