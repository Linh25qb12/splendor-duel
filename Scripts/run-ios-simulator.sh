#!/usr/bin/env bash
# Build app cho iOS Simulator, cài và mở trên simulator đang boot.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

SCHEME="splendor duel"
PROJECT="SplendorDuel.xcodeproj"
BUNDLE_ID="linhdoan.splendor-duel"
DERIVED="${ROOT}/build/DerivedData"
APP_PATH="${DERIVED}/Build/Products/Debug-iphonesimulator/splendor duel.app"

mkdir -p "${ROOT}/build"

echo "→ Building (Debug, iOS Simulator)…"
xcodebuild -scheme "$SCHEME" \
  -project "$PROJECT" \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$DERIVED" \
  COMPILER_INDEX_STORE_ENABLE=NO \
  build

if [[ ! -d "$APP_PATH" ]]; then
  echo "Lỗi: không tìm thấy $APP_PATH" >&2
  exit 1
fi

open -a Simulator 2>/dev/null || true

BOOTED=$(xcrun simctl list devices booted 2>/dev/null | grep -oE '[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}' | head -1 || true)
if [[ -z "$BOOTED" ]]; then
  UDID=$(xcrun simctl list devices available 2>/dev/null | grep -m1 "iPhone" | sed -n 's/.*(\([^)]*\)).*/\1/p' || true)
  if [[ -z "$UDID" ]]; then
    echo "Lỗi: không tìm thấy simulator iPhone khả dụng. Cài thêm runtime trong Xcode → Settings → Platforms." >&2
    exit 1
  fi
  echo "→ Boot simulator: $UDID"
  xcrun simctl boot "$UDID"
  open -a Simulator
  sleep 2
fi

echo "→ Cài app lên simulator…"
xcrun simctl install booted "$APP_PATH"

echo "→ Khởi chạy $BUNDLE_ID …"
xcrun simctl launch booted "$BUNDLE_ID"

echo "Xong."
