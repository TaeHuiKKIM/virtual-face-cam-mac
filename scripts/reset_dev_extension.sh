#!/bin/bash
set -euo pipefail

echo "This removes approval state for the development system extension when possible."
echo "You may still need to remove the app from /Applications and reboot."

systemextensionsctl list | grep -i "virtualfacecam" || true
echo ""
echo "If a stale extension remains, use System Settings or increment the bundle version."
