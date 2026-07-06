#!/bin/bash
set -u

APP_DIR="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
echo "Image Stage for macOS"
echo "App files: $APP_DIR"

is_usable_python() {
    "$1" - <<'PY' >/dev/null 2>&1
import sys
if sys.version_info < (3, 9):
    raise SystemExit(1)
PY
}

find_python() {
    for cmd in "${PYTHON:-}" /usr/bin/python3 python3.14 python3.13 python3.12 python3.11 python3.10 python3; do
        [ -n "$cmd" ] || continue
        if [ -x "$cmd" ] && is_usable_python "$cmd"; then
            echo "$cmd"
            return 0
        fi
        if command -v "$cmd" >/dev/null 2>&1 && is_usable_python "$(command -v "$cmd")"; then
            command -v "$cmd"
            return 0
        fi
    done
    return 1
}

PYTHON_BIN="$(find_python)"
if [ -z "$PYTHON_BIN" ]; then
    echo ""
    echo "[Error] Python 3.9 or later is required."
    echo "Install Python from https://www.python.org/downloads/macos/ or run: brew install python"
    echo ""
    read -n 1 -s -r -p "Press any key to close..."
    exit 1
fi

echo "Opening browser UI..."
"$PYTHON_BIN" "$APP_DIR/image_stage.py"
