#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
XCODEBUILD="${XCODEBUILD:-/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild}"

"$ROOT/scripts/bootstrap_project.sh"

"$XCODEBUILD" \
    -project "$ROOT/native/VirtualFaceCamMac.xcodeproj" \
    -scheme VirtualFaceCam \
    -configuration Debug \
    -derivedDataPath "$ROOT/build/DerivedData" \
    CODE_SIGNING_ALLOWED=NO \
    build
