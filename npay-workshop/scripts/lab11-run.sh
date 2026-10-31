#!/bin/sh
# Lab 11 evidence: archive the Release app for devices (unsigned), look inside, try to export, and show that a
# version mismatch between the app and the widget archives without a warning. No Simulator, no servers.
# Run from the repo root: sh scripts/lab11-run.sh
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
EV="$ROOT/evidence"; IOS="$ROOT/NPayRN/ios"; T=/tmp/npay-lab11; rm -rf $T; mkdir -p $T
A="$IOS/build/NPayRN.xcarchive"; rm -rf "$A"
cd "$IOS"
ARCH="-workspace NPayRN.xcworkspace -scheme NPayRN -configuration Release -destination generic/platform=iOS"

# 1 · archive (unsigned)
{ echo '$ npm run ios:archive'; (cd .. && npm run -s ios:archive 2>&1); } > "$EV/11-archive.txt"

# 2 · look inside
{ echo '$ ls NPayRN.xcarchive NPayRN.xcarchive/Products/Applications NPayRN.xcarchive/dSYMs'
  ls "$A"; ls "$A/Products/Applications"; ls "$A/dSYMs"
  echo; echo '$ plutil -p NPayRN.xcarchive/Info.plist'; plutil -p "$A/Info.plist"
  echo; echo '$ dwarfdump --uuid (the app, the widget, and their dSYMs)'
  dwarfdump --uuid "$A/Products/Applications/NPayRN.app/NPayRN" "$A/Products/Applications/NPayRN.app/PlugIns/NPayWidget.appex/NPayWidget" "$A"/dSYMs/*.dSYM | sed "s#$A/##"
  echo; echo '$ vtool -show-build …/NPayRN (the archive; a Simulator build for comparison)'
  vtool -show-build "$A/Products/Applications/NPayRN.app/NPayRN" | grep -E " platform"
  SIMAPP="$IOS/build/Build/Products/Release-iphonesimulator/NPayRN.app"
  [ -d "$SIMAPP" ] && vtool -show-build "$SIMAPP/NPayRN" | grep -E " platform" | sort -u
  echo; echo '$ du -sh (the app, the dSYMs)'; du -sh "$A/Products/Applications/NPayRN.app" "$A/dSYMs" | sed "s#$A/##"
  echo; echo '$ sh scripts/check-archive.sh NPayRN/ios/build/NPayRN.xcarchive'; sh "$ROOT/scripts/check-archive.sh" "$A"
} > "$EV/11-inside-archive.txt" 2>&1

# 3 · export: unsigned, then with a free team (the team id and Apple ID are replaced in the evidence)
TEAM=$(defaults read com.apple.dt.Xcode IDEProvisioningTeamByIdentifier 2>/dev/null | grep -oE 'teamID = [A-Z0-9]{10}' | head -1 | awk '{print $3}')
{ echo '$ xcodebuild -exportArchive -archivePath build/NPayRN.xcarchive -exportOptionsPlist ExportOptions.plist -exportPath build/export'
  xcodebuild -exportArchive -archivePath "$A" -exportOptionsPlist ExportOptions.plist -exportPath $T/export1 2>&1 | grep -E "error:|EXPORT"
  if [ -n "$TEAM" ]; then
    /usr/bin/sed "s#<key>signingStyle#<key>teamID</key><string>$TEAM</string><key>signingStyle#" ExportOptions.plist > $T/team.plist
    echo; echo '$ (the same, with teamID = a free Personal Team, and -allowProvisioningUpdates)'
    xcodebuild -exportArchive -archivePath "$A" -exportOptionsPlist $T/team.plist -exportPath $T/export2 -allowProvisioningUpdates 2>&1 \
      | grep -E "error:|EXPORT" | sort -u | sed -E "s/$TEAM/<TEAM_ID>/g; s/account '[^']+'/account '<YOUR_APPLE_ID>'/g"
  fi
} > "$EV/11-export.txt"

# 4 · a widget version that drifted (1.1 while the app is 1.0): Xcode archives it without a word
cp NPayRN.xcodeproj/project.pbxproj $T/pbx
python3 - <<'PY'
p='NPayRN.xcodeproj/project.pbxproj'; s=open(p).read()
i=s.index('PRODUCT_BUNDLE_IDENTIFIER = com.npay.workshop.NPayWidget;'); j=s.rindex('MARKETING_VERSION = ',0,i)
s=s[:j]+'MARKETING_VERSION = 1.1;'+s[s.index(';',j)+1:]
open(p,'w').write(s)
PY
{ echo '(the widget target'"'"'s Release MARKETING_VERSION set to 1.1; the app stays 1.0)'
  echo '$ xcodebuild … archive'; xcodebuild $ARCH -archivePath $T/drift.xcarchive archive CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "^(warning|error): .*[Vv]ersion|ARCHIVE (SUCCEEDED|FAILED)"
  echo; echo '$ sh scripts/check-archive.sh …/drift.xcarchive'; sh "$ROOT/scripts/check-archive.sh" $T/drift.xcarchive; echo "(exit $?)"
} > "$EV/11-version-drift.txt" 2>&1
cp $T/pbx NPayRN.xcodeproj/project.pbxproj

# 5 · one command sets both targets
{ echo '$ sh scripts/set-version.sh 1.0 2'; sh "$ROOT/scripts/set-version.sh" 1.0 2
  echo; echo '$ sh scripts/set-version.sh 1.0 1      # back to build 1 for this lab'; sh "$ROOT/scripts/set-version.sh" 1.0 1
} > "$EV/11-set-version.txt"
cd "$ROOT"; git status --short NPayRN/ios/NPayRN.xcodeproj
echo "evidence written: $(ls $EV/11-*)"
