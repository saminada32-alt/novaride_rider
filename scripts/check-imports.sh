#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
echo "=== Rider flutter analyze ==="
flutter analyze
echo "OK: rider analyze passed"
