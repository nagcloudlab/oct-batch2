#!/bin/sh
# Lab 7 evidence: add NPay's widget to the home screen with real taps (UI driver), and tap it.
# ERASES the "iPhone 17 Pro" Simulator first, for a clean home screen.
# Needs: the NPay Debug build (NPayRN/ios/build); Metro on :8081 for the last screenshot.
# Run from the repo root: sh scripts/lab07-run.sh
set -e
ROOT=$(cd "$(dirname "$0")/.." && pwd)
SIM="iPhone 17 Pro"
OUT=/tmp/uidriver; rm -rf $OUT; mkdir -p $OUT
xcrun simctl shutdown "$SIM" 2>/dev/null || true
xcrun simctl erase "$SIM"
xcrun simctl boot "$SIM"; xcrun simctl bootstatus "$SIM" -b >/dev/null
xcrun simctl status_bar "$SIM" override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4
xcrun simctl install "$SIM" "$ROOT/NPayRN/ios/build/Build/Products/Debug-iphonesimulator/NPayRN.app"
TEST_RUNNER_UIDRIVER_OUT=$OUT xcodebuild test -project "$ROOT/scripts/uidriver/UIDriver.xcodeproj" -scheme UIDriver \
  -destination "platform=iOS Simulator,name=$SIM" -derivedDataPath /tmp/uidriver-build \
  -only-testing:UIDriverTests/Lab07 2>&1 | grep -E "Test Case.*(passed|failed)|error:|TEST (SUCCEEDED|FAILED)" | tee $OUT/test.log
cp $OUT/07-*.png "$ROOT/evidence/" 2>/dev/null || true
cp $OUT/test.log "$ROOT/evidence/07-uidriver-tests.txt"
