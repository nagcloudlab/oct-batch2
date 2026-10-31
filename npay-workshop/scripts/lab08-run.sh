#!/bin/sh
# Lab 8 evidence: live widget, deep link, Live Activity, sign-out (UI driver, real taps).
# ERASES the "iPhone 17 Pro" Simulator first. Needs the NPay Debug build, the server on :8080 and Metro on :8081.
# Run from the repo root: sh scripts/lab08-run.sh
set -e
ROOT=$(cd "$(dirname "$0")/.." && pwd)
SIM="iPhone 17 Pro"
OUT=/tmp/uidriver; rm -rf $OUT; mkdir -p $OUT
xcrun simctl shutdown "$SIM" 2>/dev/null || true
xcrun simctl erase "$SIM"
xcrun simctl boot "$SIM"; xcrun simctl bootstatus "$SIM" -b >/dev/null
xcrun simctl status_bar "$SIM" override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4
xcrun simctl install "$SIM" "$ROOT/NPayRN/ios/build/Build/Products/Debug-iphonesimulator/NPayRN.app"
curl -s -X POST localhost:8080/admin/reset >/dev/null
TEST_RUNNER_UIDRIVER_OUT=$OUT xcodebuild test -project "$ROOT/scripts/uidriver/UIDriver.xcodeproj" -scheme UIDriver \
  -destination "platform=iOS Simulator,name=$SIM" -derivedDataPath /tmp/uidriver-build \
  -only-testing:UIDriverTests/Lab08 2>&1 | grep -E "Test Case.*(passed|failed)|error:|TEST (SUCCEEDED|FAILED)" | tee $OUT/test.log
# step 3: a deep link from outside, signed out
( while [ ! -f $OUT/ready-openurl ]; do sleep 0.5; done; sleep 1
  xcrun simctl openurl "$SIM" "npay://send?to=ravi@npay&amount=45000" ) &
TEST_RUNNER_UIDRIVER_OUT=$OUT xcodebuild test -project "$ROOT/scripts/uidriver/UIDriver.xcodeproj" -scheme UIDriver \
  -destination "platform=iOS Simulator,name=$SIM" -derivedDataPath /tmp/uidriver-build \
  -only-testing:UIDriverTests/Lab08Link 2>&1 | grep -E "Test Case.*(passed|failed)|error:|TEST (SUCCEEDED|FAILED)" | tee -a $OUT/test.log
cp $OUT/08-*.png "$ROOT/evidence/" 2>/dev/null || true
cp $OUT/test.log "$ROOT/evidence/08-uidriver-tests.txt"
