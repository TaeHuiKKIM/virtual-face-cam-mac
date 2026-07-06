#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
"$ROOT/scripts/bootstrap_project.sh"
open "$ROOT/native/VirtualFaceCamMac.xcodeproj"
