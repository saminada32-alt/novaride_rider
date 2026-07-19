#!/usr/bin/env bash
# Build Rider IPA for TestFlight / App Store Connect.
# Prerequisites: Xcode, Apple Developer account, signing configured in Xcode.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

CONFIG="config/prod.json"
if [[ ! -f "$CONFIG" ]]; then
  echo "❌ Missing config/prod.json (copy from config/prod.example.json)"
  exit 1
fi

MAPS_KEY=""
if command -v python3 >/dev/null 2>&1; then
  MAPS_KEY="$(python3 -c "import json; print(json.load(open('$CONFIG')).get('GOOGLE_MAPS_API_KEY',''))" 2>/dev/null || true)"
fi
if [[ -n "$MAPS_KEY" ]]; then
  sed -i '' "s/provideAPIKey(\"[^\"]*\")/provideAPIKey(\"$MAPS_KEY\")/" ios/Runner/AppDelegate.swift
  echo "▶ Google Maps API key injected into AppDelegate.swift"
else
  echo "⚠️  Add GOOGLE_MAPS_API_KEY to config/prod.json before release"
fi

flutter pub get
flutter build ipa \
  --release \
  --dart-define-from-file="$CONFIG"

echo ""
echo "✅ IPA ready: build/ios/ipa/*.ipa"
echo "   Upload with Apple Transporter or: xcrun altool --upload-app -f build/ios/ipa/*.ipa -t ios -u YOUR_APPLE_ID"
