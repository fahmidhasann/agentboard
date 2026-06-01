# AgentBoard

A native macOS command center for multiple embedded terminal sessions.

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

The output is written to `dist/AgentBoard-<version>-arm64.dmg`.

## License

[MIT](LICENSE)
