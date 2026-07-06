#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if ! command -v xcodegen >/dev/null 2>&1; then
    echo "xcodegen is required."
    echo "Install it with: brew install xcodegen"
    exit 1
fi

cd "$ROOT/native"
xcodegen generate
PBXPROJ="$ROOT/native/VirtualFaceCamMac.xcodeproj/project.pbxproj"
if [ -f "$PBXPROJ" ]; then
    perl -0pi -e 's/objectVersion = 77;/objectVersion = 60;/' "$PBXPROJ"
fi
echo "Generated: $ROOT/native/VirtualFaceCamMac.xcodeproj"
