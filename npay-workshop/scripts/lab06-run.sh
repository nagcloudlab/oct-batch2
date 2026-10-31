#!/bin/sh
# Lab 6 evidence: a real payment → the NPay server's notification; a reminder scheduled by the app.
# Needs: the NPay Debug build (NPayRN/ios/build), the lab-06 server on :8080 and Metro on :8081.
# Run from the repo root: sh scripts/lab06-run.sh
set -e
ROOT=$(cd "$(dirname "$0")/.." && pwd)
SIM="iPhone 17 Pro"
OUT=/tmp/uidriver; rm -rf $OUT; mkdir -p $OUT
xcrun simctl boot "$SIM" 2>/dev/null || true
xcrun simctl status_bar "$SIM" override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4
xcrun simctl uninstall "$SIM" com.npay.workshop 2>/dev/null || true
xcrun simctl install "$SIM" "$ROOT/NPayRN/ios/build/Build/Products/Debug-iphonesimulator/NPayRN.app"
curl -s -X POST localhost:8080/admin/reset >/dev/null
TEST_RUNNER_UIDRIVER_OUT=$OUT xcodebuild test -project "$ROOT/scripts/uidriver/UIDriver.xcodeproj" -scheme UIDriver \
  -destination "platform=iOS Simulator,name=$SIM" -derivedDataPath /tmp/uidriver-build \
  -only-testing:UIDriverTests/Lab06 2>&1 | grep -E "Test Case.*(passed|failed)|error:|TEST (SUCCEEDED|FAILED)" | tee $OUT/test.log
cp $OUT/06-*.png "$ROOT/evidence/" 2>/dev/null || true
cp $OUT/test.log "$ROOT/evidence/06-uidriver-tests.txt"
