#!/bin/sh
# Sets the version users see (MARKETING_VERSION) and the build number (CURRENT_PROJECT_VERSION) in every target and
# configuration at once (the app and the widget × Debug, Staging, Release), so the two targets can't drift apart.
# Run from the repo root: sh scripts/set-version.sh 1.0 2
set -e
[ $# -eq 2 ] || { echo "usage: sh scripts/set-version.sh <version, e.g. 1.0> <build number, e.g. 2>"; exit 1; }
PBX="$(cd "$(dirname "$0")/.." && pwd)/NPayRN/ios/NPayRN.xcodeproj/project.pbxproj"
sed -i '' -E "s/MARKETING_VERSION = [^;]+;/MARKETING_VERSION = $1;/; s/CURRENT_PROJECT_VERSION = [^;]+;/CURRENT_PROJECT_VERSION = $2;/" "$PBX"
grep -oE "(MARKETING_VERSION|CURRENT_PROJECT_VERSION) = [^;]+" "$PBX" | sort | uniq -c
