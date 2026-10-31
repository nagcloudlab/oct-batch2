#!/bin/sh
# Lab 10 evidence: HTTPS, an inspecting proxy, and certificate pinning (Release builds, UI driver).
# ERASES the "iPhone 17 Pro" Simulator. Starts the https (:8443) and proxy (:8444) servers itself: stop yours first.
# Run from the repo root: sh scripts/lab10-run.sh
set -e
ROOT=$(cd "$(dirname "$0")/.." && pwd)
SIM="iPhone 17 Pro"
OUT=/tmp/uidriver; rm -rf $OUT; mkdir -p $OUT
JAVA_HOME=${JAVA_HOME:-$(ls -d ~/.local/jdk/jdk-21*/Contents/Home 2>/dev/null | head -1)}; export JAVA_HOME
pkill -f npay-server-0.0.1-SNAPSHOT.jar || true; sleep 1
(cd "$ROOT/server" && ./mvnw -q -DskipTests package)
(cd "$ROOT/server" && "$JAVA_HOME/bin/java" -jar target/npay-server-0.0.1-SNAPSHOT.jar --spring.profiles.active=https > $OUT/server-https.log 2>&1 &)
(cd "$ROOT/server" && "$JAVA_HOME/bin/java" -jar target/npay-server-0.0.1-SNAPSHOT.jar --spring.profiles.active=proxy > $OUT/proxy.log 2>&1 &)
until curl -s --cacert "$ROOT/certs/ca.crt" -m 1 https://localhost:8443/v1/account >/dev/null; do sleep 1; done
until curl -sk -m 1 https://localhost:8444/ >/dev/null 2>&1; do sleep 1; done

# builds: Release (production → https://localhost:8443, pinned); the same pointed at the proxy; that one without the pin
cd "$ROOT/NPayRN/ios"
B="-workspace NPayRN.xcworkspace -scheme NPayRN -configuration Release -sdk iphonesimulator"
xcodebuild $B -destination "platform=iOS Simulator,name=$SIM" -derivedDataPath build build 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
xcodebuild $B -destination "platform=iOS Simulator,name=$SIM" -derivedDataPath /tmp/npay-viaproxy NPAY_SERVER_URL=https://localhost:8444 build 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
REAL="$ROOT/NPayRN/ios/build/Build/Products/Release-iphonesimulator/NPayRN.app"
VIA=/tmp/npay-viaproxy/Build/Products/Release-iphonesimulator/NPayRN.app
rm -rf /tmp/nopin; mkdir -p /tmp/nopin; cp -R $VIA /tmp/nopin/
/usr/libexec/PlistBuddy -c "Delete :NSAppTransportSecurity:NSPinnedDomains" /tmp/nopin/NPayRN.app/Info.plist
codesign --force --sign - --preserve-metadata=entitlements /tmp/nopin/NPayRN.app 2>/dev/null
NOPIN=/tmp/nopin/NPayRN.app
cd "$ROOT"

xcrun simctl shutdown "$SIM" 2>/dev/null || true
xcrun simctl erase "$SIM"; xcrun simctl boot "$SIM"; xcrun simctl bootstatus "$SIM" -b >/dev/null
xcrun simctl status_bar "$SIM" override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4
run() {  # run CASE APP
  xcrun simctl uninstall "$SIM" com.npay.workshop 2>/dev/null || true
  xcrun simctl install "$SIM" "$2"
  P0=$(grep -c "PROXY sees" $OUT/proxy.log || true)
  TEST_RUNNER_UIDRIVER_OUT=$OUT TEST_RUNNER_LAB10_CASE=$1 xcodebuild test -project scripts/uidriver/UIDriver.xcodeproj \
    -scheme UIDriver -destination "platform=iOS Simulator,name=$SIM" -derivedDataPath /tmp/uidriver-build \
    -only-testing:UIDriverTests/Lab10 2>&1 | grep -E "error:|TEST FAILED" || true
  P1=$(grep -c "PROXY sees" $OUT/proxy.log || true)
  echo "$1 → $(cat $OUT/10-$1.result) · the proxy saw $((P1 - P0)) requests" | tee -a $OUT/results.txt
}
run 1-root-not-trusted "$REAL"
xcrun simctl keychain "$SIM" add-root-cert certs/ca.crt              # like installing NPay's CA profile
run 2-real-server "$REAL"
run 3-proxy-not-trusted "$VIA"
xcrun simctl keychain "$SIM" add-root-cert certs/proxy-ca.crt        # the user was talked into trusting the proxy
run 4-proxy-trusted-no-pin "$NOPIN"
( xcrun simctl spawn "$SIM" log stream --level debug --predicate 'process == "NPayRN"' > $OUT/pinned-log.txt 2>&1 & echo $! > $OUT/log.pid )
sleep 2
run 5-proxy-trusted-pinned "$VIA"
kill $(cat $OUT/log.pid) 2>/dev/null || true
pkill -f npay-server-0.0.1-SNAPSHOT.jar || true

cp $OUT/10-*.png "$ROOT/evidence/" 2>/dev/null || true
cp $OUT/results.txt "$ROOT/evidence/10-results.txt"
grep -E "PROXY sees|body:|Authorization" $OUT/proxy.log | grep -v "PROXY sees  GET /$" | sed -E 's/(at|rt)_[0-9a-f]+/\1_…/g' | head -9 > "$ROOT/evidence/10-proxy-log-no-pin.txt"
grep -E "Trust evaluate failure|HTTP load failed|finished with error \[-1202\]" $OUT/pinned-log.txt | sed -E 's/^.*NPayRN: //' | cut -c1-200 > "$ROOT/evidence/10-pinned-ios-log.txt"
