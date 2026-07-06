#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/Image Stage.app"
RES="$APP/Contents/Resources"
MACOS="$APP/Contents/MacOS"

mkdir -p "$RES" "$MACOS"
cp "$ROOT/image_stage.py" "$RES/image_stage.py"
cp "$ROOT/assets/ImageStage.icns" "$RES/ImageStage.icns"
cp "$ROOT/scripts/launch.sh" "$RES/launch.sh"
cp "$ROOT/scripts/app_executable.sh" "$MACOS/ImageStage"
chmod +x "$RES/launch.sh"
chmod +x "$MACOS/ImageStage"

echo "Updated: $APP"
