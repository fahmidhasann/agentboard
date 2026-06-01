#!/bin/bash
#
# Runs the AgentBoard unit tests.
#
# This environment has only the Command Line Tools (no full Xcode), so XCTest is unavailable and
# the bundled swift-testing framework isn't on SwiftPM's default search path. We point the
# compiler/linker at the developer frameworks dir and add the runtime rpaths it needs. On a
# machine with full Xcode, `swift test` works without this wrapper.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$(cd "$SCRIPT_DIR/.." && pwd)"

DEVELOPER_DIR="$(xcode-select -p)"
FRAMEWORKS="$DEVELOPER_DIR/Library/Developer/Frameworks"
INTEROP_LIB="$DEVELOPER_DIR/Library/Developer/usr/lib"

swift test \
    -Xswiftc -F -Xswiftc "$FRAMEWORKS" \
    -Xlinker -F -Xlinker "$FRAMEWORKS" \
    -Xlinker -rpath -Xlinker "$FRAMEWORKS" \
    -Xlinker -rpath -Xlinker "$INTEROP_LIB" \
    "$@"
