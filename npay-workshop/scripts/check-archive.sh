#!/bin/sh
# Looks inside an .xcarchive before it is exported or uploaded: versions, environment, JS bundle, dSYMs, signing.
# Exits 1 if a check fails. Run from the repo root: sh scripts/check-archive.sh NPayRN/ios/build/NPayRN.xcarchive
A="${1:?usage: sh scripts/check-archive.sh path/to/NPayRN.xcarchive}"
APP="$A/Products/Applications/NPayRN.app"; W="$APP/PlugIns/NPayWidget.appex"
fail=0
p() { /usr/libexec/PlistBuddy -c "Print :$2" "$1" 2>/dev/null; }
av="$(p "$APP/Info.plist" CFBundleShortVersionString) ($(p "$APP/Info.plist" CFBundleVersion))"
wv="$(p "$W/Info.plist" CFBundleShortVersionString) ($(p "$W/Info.plist" CFBundleVersion))"
echo "version  app $av · widget $wv"
if [ "$av" = "$wv" ]; then echo "         ok: the widget matches the app"; else echo "         FAIL: the widget's version differs from the app's"; fail=1; fi
url=$(p "$APP/Info.plist" NPayServerURL)
echo "server   $(p "$APP/Info.plist" NPayEnvironment) · $url"
case "$url" in https://*) echo "         ok: https" ;; *) echo "         FAIL: not https"; fail=1 ;; esac
echo "js       $(file -b "$APP/main.jsbundle")"
for b in "$APP/NPayRN" "$W/NPayWidget"; do
  n=$(basename "$b"); bu=$(dwarfdump --uuid "$b" | awk '{print $2}')
  d=$(ls -d "$A"/dSYMs/"$n".*.dSYM 2>/dev/null | head -1)
  du=""; [ -n "$d" ] && du=$(dwarfdump --uuid "$d" | awk '{print $2}')
  if [ -n "$du" ] && [ "$bu" = "$du" ]; then echo "dSYM     $n $bu ok"; else echo "dSYM     $n $bu FAIL: no matching dSYM"; fail=1; fi
done
team=$(p "$A/Info.plist" ApplicationProperties:Team)
echo "signing  ${team:-none: unsigned (fine for looking inside; export and upload need a paid team)}"
exit $fail
