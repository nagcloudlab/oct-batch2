#!/bin/sh
# Lab 5 evidence: real taps (XCUITest, scripts/uidriver) + real `xcrun simctl push`.
# Needs: the NPay Debug build (NPayRN/ios/build), the server on :8080 and Metro on :8081.
# Writes screenshots to evidence/. Run from the repo root: sh scripts/lab05-run.sh
set -e
ROOT=$(cd "$(dirname "$0")/.." && pwd)
SIM="iPhone 17 Pro"
OUT=/tmp/uidriver; rm -rf $OUT; mkdir -p $OUT
xcrun simctl boot "$SIM" 2>/dev/null || true
xcrun simctl status_bar "$SIM" override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4
xcrun simctl uninstall "$SIM" com.npay.workshop 2>/dev/null || true      # forget any earlier permission answer
xcrun simctl install "$SIM" "$ROOT/NPayRN/ios/build/Build/Products/Debug-iphonesimulator/NPayRN.app"
curl -s -X POST localhost:8080/admin/reset >/dev/null

# send the push whenever a test says it is ready
( for step in foreground background notrunning; do
    while [ ! -f $OUT/ready-$step ]; do sleep 0.5; done
    sleep 1
    xcrun simctl push "$SIM" com.npay.workshop "$ROOT/NPayRN/push/payment-sent.apns" | tee -a $OUT/push.log
  done ) &

TEST_RUNNER_UIDRIVER_OUT=$OUT xcodebuild test -project "$ROOT/scripts/uidriver/UIDriver.xcodeproj" -scheme UIDriver \
  -destination "platform=iOS Simulator,name=$SIM" -derivedDataPath /tmp/uidriver-build \
  -only-testing:UIDriverTests/Lab05 2>&1 | grep -E "Test Case|error:|TEST (SUCCEEDED|FAILED)" | tee $OUT/test.log
# step 5: Don't Allow (needs a fresh install)
xcrun simctl uninstall "$SIM" com.npay.workshop
xcrun simctl install "$SIM" "$ROOT/NPayRN/ios/build/Build/Products/Debug-iphonesimulator/NPayRN.app"
( while [ ! -f $OUT/ready-dontallow ]; do sleep 0.5; done; sleep 1
  xcrun simctl push "$SIM" com.npay.workshop "$ROOT/NPayRN/push/payment-sent.apns" | tee -a $OUT/push.log ) &
TEST_RUNNER_UIDRIVER_OUT=$OUT xcodebuild test -project "$ROOT/scripts/uidriver/UIDriver.xcodeproj" -scheme UIDriver \
  -destination "platform=iOS Simulator,name=$SIM" -derivedDataPath /tmp/uidriver-build \
  -only-testing:UIDriverTests/Lab05DontAllow 2>&1 | grep -E "Test Case|error:|TEST (SUCCEEDED|FAILED)" | tee -a $OUT/test.log
cp $OUT/05-*.png "$ROOT/evidence/" 2>/dev/null || true
cp $OUT/test.log "$ROOT/evidence/05-uidriver-tests.txt" 2>/dev/null || true
cp $OUT/push.log "$ROOT/evidence/05-simctl-push.txt" 2>/dev/null || true
