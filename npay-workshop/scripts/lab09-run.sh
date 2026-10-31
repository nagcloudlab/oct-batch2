#!/bin/sh
# Lab 9 evidence: the refresh token in the Keychain (UI driver + checks from outside the app).
# Starts its own server from server/ (stop yours first) and needs Metro on :8081 and the NPay Debug build.
# Run from the repo root: sh scripts/lab09-run.sh
set -e
ROOT=$(cd "$(dirname "$0")/.." && pwd)
SIM="iPhone 17 Pro"
APP="$ROOT/NPayRN/ios/build/Build/Products/Debug-iphonesimulator/NPayRN.app"
OUT=/tmp/uidriver; rm -rf $OUT; mkdir -p $OUT
LOG=$OUT/server.log
JAVA_HOME=${JAVA_HOME:-$(ls -d ~/.local/jdk/jdk-21*/Contents/Home 2>/dev/null | head -1)}; export JAVA_HOME
start_server() { (cd "$ROOT/server" && "$JAVA_HOME/bin/java" -jar target/npay-server-0.0.1-SNAPSHOT.jar >> $LOG 2>&1 &)
                 until curl -s -m 1 localhost:8080/v1/account >/dev/null; do sleep 1; done; }
stop_server() { pkill -f npay-server-0.0.1-SNAPSHOT.jar || true; while lsof -ti :8080 >/dev/null; do sleep 0.5; done; }
(cd "$ROOT/server" && ./mvnw -q -DskipTests package)
stop_server; start_server
xcrun simctl boot "$SIM" 2>/dev/null || true
xcrun simctl status_bar "$SIM" override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4
xcrun simctl uninstall "$SIM" com.npay.workshop 2>/dev/null || true
xcrun simctl install "$SIM" "$APP"
UDID=$(xcrun simctl list devices booted | grep "$SIM (" | head -1 | sed -E 's/.*\(([0-9A-F-]+)\).*/\1/')
KEYCHAIN=~/Library/Developer/CoreSimulator/Devices/$UDID/data/Library/Keychains/keychain-2-debug.db

( # answer the driver
  while [ ! -f $OUT/ready-inspect ]; do sleep 0.5; done
  RT=$(LC_ALL=C grep -o 'rt_[0-9a-f][0-9a-f][0-9a-f][0-9a-f]' $LOG | tail -1)    # the server prints its first 7 characters
  [ -n "$RT" ] || { echo "no refresh token in the server log" > $OUT/09-where-is-the-token.txt; touch $OUT/done-inspect; exit 1; }
  DATA=$(xcrun simctl get_app_container "$SIM" com.npay.workshop data)
  { echo "refresh token (as the server logs it): ${RT}…"
    echo "in NPay's own files (data container): $(LC_ALL=C grep -rl "$RT" "$DATA" 2>/dev/null | wc -l | tr -d ' ') files"
    LC_ALL=C grep -rl "$RT" "$DATA" 2>/dev/null | sed "s|$DATA|  <data>|"
    echo "UserDefaults plist:"; plutil -p "$DATA/Library/Preferences/com.npay.workshop.plist" 2>/dev/null | grep -v "^{\|^}" || true
    echo "in the Keychain database (keychain-2-debug.db), readable: $(LC_ALL=C grep -c "$RT" "$KEYCHAIN" 2>/dev/null || true) matches"
    echo "the Keychain database exists: $(ls -la "$KEYCHAIN" | awk '{print $5}') bytes"
  } > $OUT/09-where-is-the-token.txt
  touch $OUT/done-inspect

  while [ ! -f $OUT/ready-restart ]; do sleep 0.5; done
  stop_server; echo "-- server restarted: every session forgotten" >> $LOG; start_server
  touch $OUT/done-restart

  while [ ! -f $OUT/ready-reinstall ]; do sleep 0.5; done
  xcrun simctl uninstall "$SIM" com.npay.workshop; xcrun simctl install "$SIM" "$APP"
  touch $OUT/done-reinstall
) &

TEST_RUNNER_UIDRIVER_OUT=$OUT xcodebuild test -project "$ROOT/scripts/uidriver/UIDriver.xcodeproj" -scheme UIDriver \
  -destination "platform=iOS Simulator,name=$SIM" -derivedDataPath /tmp/uidriver-build \
  -only-testing:UIDriverTests/Lab09 2>&1 | grep -E "Test Case.*(passed|failed)|error:|TEST (SUCCEEDED|FAILED)" | tee $OUT/test.log
stop_server
cp $OUT/09-* "$ROOT/evidence/" 2>/dev/null || true
cp $OUT/test.log "$ROOT/evidence/09-uidriver-tests.txt"
grep -E "^-> POST /v1/(login|token|logout)|signed in|spent|signed out|refused|invalid_grant|^<- (200|204|401)|^-- " $LOG \
  | sed -E 's/Bearer at_[0-9a-f]+…/Bearer at_…/' > "$ROOT/evidence/09-server-log.txt"
