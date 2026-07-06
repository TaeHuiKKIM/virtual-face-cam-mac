#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
XCODEBUILD="${XCODEBUILD:-xcodebuild}"
TEAM_ID="${TEAM_ID:-}"

if [ -z "$TEAM_ID" ]; then
    echo "TEAM_ID is required."
    echo "Example: TEAM_ID=ABCDE12345 ./scripts/build_signed_dev.sh"
    exit 1
fi

"$ROOT/scripts/bootstrap_project.sh"

"$XCODEBUILD" \
    -project "$ROOT/native/VirtualFaceCamMac.xcodeproj" \
    -scheme VirtualFaceCam \
    -configuration Debug \
    -derivedDataPath "$ROOT/build/SignedDerivedData" \
    -allowProvisioningUpdates \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    build
