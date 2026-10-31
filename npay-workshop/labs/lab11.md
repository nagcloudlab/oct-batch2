# Lab 11 · Archive: the build you ship

**Branch:** `lab-11` (built on `lab-10`) · **Account:** none needed to archive; a **paid** team to export

**Goal:** make the build that goes to TestFlight and the App Store, an **archive**, and read it before anyone else
does: its version and build number, the JS inside, the server it talks to, and the **dSYMs** that later turn crash
addresses into function names (Lab 13). Then see what stops a free Apple ID: **export**.

| Build | For | Signed by | Where it goes |
|---|---|---|---|
| Debug / Release for the **Simulator** (Labs 1–10) | your Mac | ad hoc | the Simulator only |
| **Archive** (this lab) | real iPhones (`generic/platform=iOS`) | nobody yet (unsigned here) | your Mac: `NPayRN.xcarchive` |
| **Export** → `.ipa` | App Store Connect | an **Apple Distribution** certificate (paid team) | TestFlight (Lab 12) |

## Two numbers

| Shown as | Build setting | Info.plist key | Who reads it | Rule |
|---|---|---|---|---|
| **Version** `1.0` | `MARKETING_VERSION` | `CFBundleShortVersionString` | users, in the App Store | change it for a release users should notice |
| **Build** `1` | `CURRENT_PROJECT_VERSION` | `CFBundleVersion` | App Store Connect, TestFlight, crash reports | **every upload needs a new one**: App Store Connect refuses a build number it already has for that version |

Both are set **per target and per configuration**: the app and the widget × Debug, Staging, Release = **six places**.
The widget must carry the **same** version as the app. `scripts/set-version.sh` writes all six at once.

## What changed on this branch

```sh
git diff lab-10 lab-11 --stat
```

| File | What it does |
|---|---|
| `NPayRN/package.json` | **`npm run ios:archive`**: a Release archive for devices, unsigned, at `ios/build/NPayRN.xcarchive` |
| `NPayRN/ios/ExportOptions.plist` (new) | how `-exportArchive` packages it: `method` **`app-store-connect`**, upload the symbols |
| `scripts/set-version.sh` (new) | sets the version and the build number in all six places |
| `scripts/check-archive.sh` (new) | looks inside an archive: versions match, https server, Hermes bytecode, a dSYM for each binary, signing |
| `scripts/lab11-run.sh` (new) | makes this lab's evidence |
| `evidence/0*-build-*.log` | the team ID that Xcode wrote into Labs 1–3's logs replaced with `<TEAM_ID>`; a stray `NPayRN/ios/release.log` removed (and `ios/*.log` ignored) |

---

## Run it

```sh
cd ~/npay-workshop && git checkout lab-11
cd NPayRN/ios && bundle exec pod install          # only if you switched branches
```

No server, no Metro, no Simulator: an archive is only built.

## 1 · Archive

```sh
cd ~/npay-workshop/NPayRN
npm run ios:archive
```

```
** ARCHIVE SUCCEEDED **
```

What the script runs (`package.json`):

```sh
xcodebuild -workspace NPayRN.xcworkspace -scheme NPayRN -configuration Release \
  -destination generic/platform=iOS -archivePath build/NPayRN.xcarchive archive CODE_SIGNING_ALLOWED=NO
```

- **`-destination generic/platform=iOS`**: for real iPhones (`arm64`, the `iphoneos` SDK), not the Simulator.
- **`archive`**: a Release build plus the **dSYMs**, kept together in one folder.
- **`CODE_SIGNING_ALLOWED=NO`**: unsigned. A free team can't sign a device build without a registered iPhone (Lab 4);
  an unsigned archive is enough to look inside. With a paid team you leave this out.

In Xcode: pick **Any iOS Device (arm64)** as the destination, then **Product › Archive**; the archive opens in the
**Organizer** (Window › Organizer).

## 2 · Look inside

```sh
cd ~/npay-workshop
sh scripts/check-archive.sh NPayRN/ios/build/NPayRN.xcarchive
```

```
version  app 1.0 (1) · widget 1.0 (1)
         ok: the widget matches the app
server   production · https://localhost:8443
         ok: https
js       Hermes JavaScript bytecode, version 98
dSYM     NPayRN 055B3216-A9F6-3618-97A2-74FB6E7EDF9C ok
dSYM     NPayWidget 4F330C98-EA1C-306F-8A88-4BB5A571C58E ok
signing  none: unsigned (fine for looking inside; export and upload need a paid team)
```

(Your UUIDs will differ.) The archive is a folder (`evidence/11-inside-archive.txt`):

```
NPayRN.xcarchive/
├── Info.plist                    ← version 1.0, build 1, bundle id, team (empty: unsigned)
├── Products/Applications/
│   └── NPayRN.app                ← 21 MB: the app, its widget, main.jsbundle, React + Hermes frameworks
└── dSYMs/                        ← 20 MB: debug symbols for our two binaries
    ├── NPayRN.app.dSYM
    └── NPayWidget.appex.dSYM
```

**For a real iPhone, not the Simulator:**

```sh
vtool -show-build NPayRN/ios/build/NPayRN.xcarchive/Products/Applications/NPayRN.app/NPayRN | grep platform
#  platform IOS                    (a Simulator build says IOSSIMULATOR: it can never go to the App Store)
```

**What a dSYM is.** A shipped binary has no function names or line numbers left in it, so a crash report shows only
addresses. The **dSYM** keeps the mapping (address → function, file, line). Each binary has a **UUID**, and its
dSYM carries the **same** UUID; that is how a crash report finds the right dSYM:

```sh
dwarfdump --uuid NPayRN/ios/build/NPayRN.xcarchive/Products/Applications/NPayRN.app/NPayRN \
                 NPayRN/ios/build/NPayRN.xcarchive/dSYMs/NPayRN.app.dSYM
# UUID: 055B3216-… (arm64) …/NPayRN.app/NPayRN
# UUID: 055B3216-… (arm64) …/NPayRN.app.dSYM/Contents/Resources/DWARF/NPayRN
```

**Keep the archive of every build you ship**: a rebuild can make a binary with a different UUID (two archives of
the same code, built in different folders, got different UUIDs here), and its dSYM won't match the crashes from the
copy users have. The archive holds dSYMs for **our** code (app + widget); React and
Hermes come prebuilt, without dSYMs in the archive.

## 3 · Export: where a free Apple ID stops

Export signs the archive with a distribution certificate and packages an `.ipa` for one **method**:

| `method` in ExportOptions.plist | For |
|---|---|
| **`app-store-connect`** | TestFlight and the App Store (Lab 12) |
| `release-testing` | ad hoc: registered iPhones only |
| `debugging` | development: registered iPhones, debugger attached |
| `enterprise` | an in-house Enterprise program |

```sh
cd ~/npay-workshop/NPayRN/ios
xcodebuild -exportArchive -archivePath build/NPayRN.xcarchive -exportOptionsPlist ExportOptions.plist -exportPath build/export
```

```
error: exportArchive No Team Found in Archive
** EXPORT FAILED **
```

Add `<key>teamID</key><string>YOUR_TEAM_ID</string>` to a copy of `ExportOptions.plist` and pass
`-allowProvisioningUpdates` (`evidence/11-export.txt`, with a free Personal Team):

```
error: exportArchive No profiles for 'com.npay.workshop.NPayWidget' were found
error: exportArchive No profiles for 'com.npay.workshop' were found
error: exportArchive No signing certificate "iOS Distribution" found
** EXPORT FAILED **
```

A free team gets **development** certificates only: no distribution certificate, no App Store profile, no upload.
(In our run Xcode's Apple ID session had also expired, so the log adds *"Unable to log in with account …"*; sign in
again in Xcode › Settings › Accounts.) With a paid team the same command writes `build/export/NPayRN.ipa`, and Xcode
creates the certificate and profiles for you (automatic signing).

In Xcode: **Organizer › Distribute App › App Store Connect** does the same export (and can upload: Lab 12).

## 4 · Break it: a widget version that drifted

In Xcode, select the **NPayWidget** target › **General** › **Version** and type `1.1` (the app stays `1.0`). Archive
again (`evidence/11-version-drift.txt`):

```
warning: The CFBundleShortVersionString of an app extension ('1.1') must match that of its containing parent app ('1.0').
** ARCHIVE SUCCEEDED **
```

A **warning**, not an error: the archive is made, and among hundreds of React Native warnings it scrolls past.
`check-archive.sh` stops on it:

```
version  app 1.0 (1) · widget 1.1 (1)
         FAIL: the widget's version differs from the app's
```

Put it back, and from now on change versions with one command:

```sh
cd ~/npay-workshop
sh scripts/set-version.sh 1.0 2      # every target and configuration
#    6 CURRENT_PROJECT_VERSION = 2
#    6 MARKETING_VERSION = 1.0
sh scripts/set-version.sh 1.0 1      # back to build 1: Lab 14 ships build 2
```

## How these results were made

`sh scripts/lab11-run.sh` archives, looks inside, tries both exports, archives the drifted version and checks it,
and runs `set-version.sh`. It needs no Simulator and no server; it puts the project file back when it is done.

## Checklist

| Check | Pass when |
|---|---|
| archive | `** ARCHIVE SUCCEEDED **`; `NPayRN/ios/build/NPayRN.xcarchive` exists |
| inside | `check-archive.sh` passes: 1.0 (1) for both, https, Hermes bytecode, two matching dSYMs |
| platform | `vtool` says `platform IOS` |
| export | fails without a team; with a free team: no "iOS Distribution" certificate |
| drift | Xcode warns but archives; `check-archive.sh` fails |
| versions | `set-version.sh` changes all six places |

## Answer before Lab 12

1. What is the difference between the version and the build number, and which one must change for every upload?
2. Why can't the Release build from Labs 2–10 go to the App Store?
3. What is in a dSYM, and how does a crash report find the right one?
4. Why keep the archive of every build you ship instead of rebuilding later?
5. What does export add to an archive, and why can't a free Apple ID do it?
6. Look at `check-archive.sh`'s server line. What else would stop this build from being useful to a tester? (Lab 12.)

## If something goes wrong

| You see | Do this |
|---|---|
| `error: Signing for "NPayRN" requires a development team` | you left out `CODE_SIGNING_ALLOWED=NO` (or use `npm run ios:archive`) |
| `No Team Found in Archive` | expected for an unsigned archive: export needs a paid team |
| `No signing certificate "iOS Distribution" found` | a free Personal Team: expected. A paid team: let Xcode manage signing, or create the certificate in Xcode › Settings › Accounts › Manage Certificates |
| `Unable to log in with account …` | Xcode › Settings › Accounts: sign in again |
| `check-archive.sh`: `FAIL: no matching dSYM` | Release `DEBUG_INFORMATION_FORMAT` must be `DWARF with dSYM File` (Build Settings) |
| the archive doesn't show in Xcode's Organizer | archives made with `-archivePath` stay where you put them; double-click the `.xcarchive` to add it |
