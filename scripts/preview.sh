#!/bin/bash
# Dev helper: opens the real ContentView in a window for visual inspection / screenshots.
# Optional flags: --bookmarks, --open-picker, --open-picker-target
set -euo pipefail
cd "$(dirname "$0")/.."
swift build
echo "▶ Launching preview window (Ctrl-C to quit)…"
exec .build/debug/Reversobar --window "$@"
