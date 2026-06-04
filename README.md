# AgentBoard

A native macOS command center for managing multiple AI coding agents from a single window.

**Website:** https://agentboard-roan.vercel.app

## Why

If you run multiple agents simultaneously — one doing code review, another implementing a feature, a third running tests — you know the pain of scattered terminal windows. Agents need attention at unpredictable times (confirmations, errors, prompts), and regular terminal tabs don't tell you which one is waiting. You have to check each one manually.

AgentBoard puts every agent session in one sidebar with live status badges. You focus on whichever agent you're actively working with, and the others surface themselves when they need you.

## Features

- **Live status sidebar** — see which sessions are running, idle, waiting for input, or exited at a glance
- **Native macOS app** — keyboard shortcuts, system notifications, light/dark theme
- **Persistent sessions** — terminal history survives app restarts so you can pick up where you left off
- **Quick-launch agents** — pre-configured entries for Claude, Codex, Gemini, Aider, and others (fully customizable)
- **Command palette** (⌘⇧P) — fast session switching and actions

## Install

1. Download the latest `.dmg` from [Releases](https://github.com/fahmidhasann/agentboard/releases)
2. Open the `.dmg` and drag **AgentBoard** into your Applications folder

### Gatekeeper notice

AgentBoard is not signed with an Apple Developer certificate. On first launch macOS will block it. To open it:

- Right-click the app → **Open** → click **Open** in the dialog, or
- Run in Terminal:
  ```
  xattr -cr /Applications/AgentBoard.app
  ```

## Build from source

Requires macOS 14+ and Swift 5.9+ (Xcode Command Line Tools or full Xcode).

```bash
git clone https://github.com/fahmidhasann/agentboard.git
cd agentboard
./script/build_and_run.sh
```

To create a `.dmg` locally:

```bash
./script/create_dmg.sh
```

## License

[MIT](LICENSE)
