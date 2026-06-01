#!/bin/bash
#
# Canonical local launcher for AgentBoard.
#
#   ./script/build_and_run.sh            build, (re)stage the .app bundle, and launch it
#   ./script/build_and_run.sh --verify   the above, then confirm the process is running
#
set -euo pipefail

APP_NAME="AgentBoard"
BUNDLE_ID="com.fahmid.AgentBoard"
CONFIG="debug"

# Resolve repo root regardless of where the script is invoked from.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

VERIFY=0
for arg in "$@"; do
    case "$arg" in
        --verify) VERIFY=1 ;;
        --release) CONFIG="release" ;;
        *) echo "Unknown argument: $arg" >&2; exit 2 ;;
    esac
done

echo "==> Stopping any running $APP_NAME"
pkill -x "$APP_NAME" 2>/dev/null || true

echo "==> Building ($CONFIG)"
swift build -c "$CONFIG"

BIN_DIR="$(swift build -c "$CONFIG" --show-bin-path)"
EXECUTABLE="$BIN_DIR/$APP_NAME"
if [[ ! -x "$EXECUTABLE" ]]; then
    echo "Build did not produce an executable at $EXECUTABLE" >&2
    exit 1
fi

APP_DIR="$ROOT_DIR/dist/$APP_NAME.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"

echo "==> Staging $APP_DIR"
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"

cat > "$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

cp "$EXECUTABLE" "$MACOS_DIR/$APP_NAME"

echo "==> Launching $APP_NAME"
/usr/bin/open -n "$APP_DIR"

if [[ "$VERIFY" -eq 1 ]]; then
    echo "==> Verifying"
    for _ in 1 2 3 4 5 6 7 8 9 10; do
        if pgrep -x "$APP_NAME" >/dev/null 2>&1; then
            echo "OK: $APP_NAME is running (pid $(pgrep -x "$APP_NAME" | tr '\n' ' '))"
            exit 0
        fi
        sleep 0.5
    done
    echo "FAIL: $APP_NAME did not start" >&2
    exit 1
fi
