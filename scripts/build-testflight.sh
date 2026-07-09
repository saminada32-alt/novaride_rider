#!/usr/bin/env bash
# Build Rider IPA for TestFlight / App Store Connect.
# Prerequisites: Xcode, Apple Developer account, signing configured in Xcode.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ ! -f config/prod.json ]]; then
  echo "❌ Missing config/prod.json"
  exit 1
fi

if ! grep -q GOOGLE_MAPS_API_KEY config/prod.json 2>/dev/null; then
  echo "⚠️  Add GOOGLE_MAPS_API_KEY to config/prod.json before release"
fi

flutter pub get
flutter build ipa \
  --release \
  --dart-define-from-file=config/prod.json

echo ""
echo "✅ IPA ready: build/ios/ipa/*.ipa"
echo "   Upload with Apple Transporter or: xcrun altool --upload-app -f build/ios/ipa/*.ipa -t ios -u YOUR_APPLE_ID"
