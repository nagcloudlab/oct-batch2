# Lab 4 · Signing: certificates, App ID, capabilities, profiles

**Branch:** `lab-04` (built on `lab-03`) · **Account:** a free Apple ID is enough

**Goal:** understand what has to line up before an iOS app may run on a real iPhone; see each piece fail on its own;
find out, for real, what a **free Apple ID** allows; and add the two **capabilities** the later labs use:
**Push Notifications** and **App Groups**.

> **This workshop uses a free Apple ID only.** Everything in Labs 1–14 runs in the Simulator, which needs no account.
> This lab shows where a free account stops, so you know what a paid one (US$99/year) adds.

## The pieces

| Piece | What it is | Where it lives | NPay |
|---|---|---|---|
| **Team** | who the app belongs to (a 10-character Team ID) | Xcode › Settings › Accounts | your Apple ID's free **Personal Team** |
| **Certificate** (+ private key) | proves *who* signed the app | your Mac's Keychain; Apple keeps the certificate | "Apple Development: …" |
| **App ID** | Team ID + bundle id, plus the capabilities it may use | registered with Apple by Xcode | `<TEAM_ID>.com.npay.workshop` |
| **Capabilities → entitlements** | what the app is allowed to do (push, app groups, …), written into the signed app | `NPayRN/NPayRN.entitlements` | `aps-environment`, `com.apple.security.application-groups` |
| **Provisioning profile** | Apple's signed permission: *this App ID, with these entitlements, signed by this certificate, may run on these devices* | `embedded.mobileprovision` inside a device build | a development profile |
| **Devices** | the iPhones a development profile allows | registered by Xcode when an iPhone is connected | your own iPhone, if you connect one |

**All of them must agree.** The bundle id must match the App ID; every entitlement in the app must be allowed for the
team *and* listed in the profile; the certificate must be one the profile names; the iPhone must be in the profile.
Any mismatch → the build or the install fails.

The **Simulator needs none of this**: it runs apps signed "ad hoc", with no team and no profile. That's why Labs 1–3
never asked for an account, and why the rest of the workshop runs on a free Apple ID.

## What changed on this branch

```sh
git diff lab-03 lab-04 --stat
```

| File | Change |
|---|---|
| `ios/NPayRN/NPayRN.entitlements` (new) | `aps-environment = development` (notifications, Labs 5–6) and app group `group.com.npay.workshop` (widget, Lab 8) |
| `ios/NPayRN.xcodeproj/project.pbxproj` | `CODE_SIGN_ENTITLEMENTS = NPayRN/NPayRN.entitlements` in Debug, Staging and Release |

In Xcode this is: target **NPayRN** › **Signing & Capabilities** › **+ Capability** › **Push Notifications**, then
**App Groups** › **+** `group.com.npay.workshop`. Xcode writes the same file and setting.

These entitlements are fine for the **Simulator**. For a **real iPhone with a free team**, Apple refuses Push (step 6),
so a device build uses a version without it (step 6a).

**Not committed on purpose:** a `DEVELOPMENT_TEAM`. Each person's team is their own: pass it on the command line,
as below, and don't commit it.

---

## 1 · How the Simulator app is signed

```sh
cd ~/npay-workshop && git checkout lab-04
cd NPayRN/ios
xcodebuild -workspace NPayRN.xcworkspace -scheme NPayRN -configuration Debug \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath build build 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
codesign -dv build/Build/Products/Debug-iphonesimulator/NPayRN.app 2>&1 | grep -E "Identifier=|Signature|TeamIdentifier"
```

Expect (`evidence/04-simulator-signing.txt`):

```
Identifier=com.npay.workshop
Signature=adhoc
TeamIdentifier=not set
```

No team, no certificate, no profile (`ls …/NPayRN.app/embedded.mobileprovision` → not found).

## 2 · Where did the entitlements go?

`codesign -d --entitlements -` on a **Simulator** app shows nothing. For the Simulator, Xcode compiles the
entitlements **into the app binary** (a section named `__TEXT,__entitlements`) instead of the signature. The file Xcode
generated shows them:

```sh
plutil -p build/Build/Intermediates.noindex/NPayRN.build/Debug-iphonesimulator/NPayRN.build/NPayRN.app-Simulated.xcent
```

Expect (`evidence/04-simulator-entitlements.txt`):

```
"application-identifier" => "<TEAM_ID>.com.npay.workshop"
"aps-environment" => "development"
"com.apple.security.application-groups" => [ 0 => "group.com.npay.workshop" ]
```

`application-identifier` was added by Xcode: Team ID + bundle id, **the App ID**. On a real device build these go
into the code signature, and the profile must allow every one of them.

## 3 · Build for a real iPhone: no team

```sh
xcodebuild -workspace NPayRN.xcworkspace -scheme NPayRN -configuration Debug \
  -sdk iphoneos -destination 'generic/platform=iOS' -derivedDataPath build build \
  2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
```

Expect (`evidence/04-device-build-no-team.txt`):

```
error: Signing for "NPayRN" requires a development team. Select a development team in the Signing & Capabilities editor.
** BUILD FAILED **
```

> **Why `2>&1 | grep` and not `tail`:** xcodebuild prints the error *first*, then a summary and a few harmless
> "Run script build phase … will be run during every build" warnings at the end, so `tail` shows only those.
> Some of its lines go to stderr, which a plain `|` doesn't pass on: `2>&1` sends them through `grep` as well,
> so you see exactly the `error:` lines and the result, in order.

## 4 · Build for a real iPhone: a team, but no profile

Find your Team ID in Xcode › Settings › Accounts (or `defaults read com.apple.dt.Xcode IDEProvisioningTeamByIdentifier`).

```sh
xcodebuild -workspace NPayRN.xcworkspace -scheme NPayRN -configuration Debug \
  -sdk iphoneos -destination 'generic/platform=iOS' -derivedDataPath build \
  DEVELOPMENT_TEAM=<YOUR_TEAM_ID> build \
  2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
```

Expect (`evidence/04-device-build-personal-team.txt`):

```
error: No profiles for 'com.npay.workshop' were found: Xcode couldn't find any iOS App Development provisioning
profiles matching 'com.npay.workshop'. Automatic signing is disabled and unable to generate a profile.
To enable automatic signing, pass -allowProvisioningUpdates to xcodebuild.
** BUILD FAILED **
```

A team and a certificate are there; the **profile** is missing. Xcode can create one, but only if you allow it to
talk to Apple (`-allowProvisioningUpdates`, or "Automatically manage signing" in Xcode).

## 5 · Your certificate

```sh
security find-identity -v -p codesigning
security find-certificate -c "Apple Development" -p | openssl x509 -noout -subject -issuer -dates
```

Expect something like (`evidence/04-certificate.txt`, personal details replaced):

```
1) <SHA1> "Apple Development: <APPLE_ID_EMAIL> (<CERT_ID>)"
subject= /UID = <USER_ID>/CN=Apple Development: <APPLE_ID_EMAIL> (<CERT_ID>)/OU=<TEAM_ID>/O=<YOUR_NAME>/C=US
issuer= /CN=Apple Worldwide Developer Relations Certification Authority/OU=G3/O=Apple Inc./C=US
notBefore=… notAfter=…   (one year)
```

- `OU` = your **Team ID**: the certificate belongs to one team. A free Apple ID gets one too.
- The **issuer is Apple**: you make a key pair, Apple signs the certificate. Your **private key never leaves your
  Keychain**; lose it (or the Mac) and that certificate is useless: export it as a `.p12` to back it up.
- It **expires after a year**.

---

## 6 · Let Xcode talk to Apple with your free team

Step 4 said *"pass -allowProvisioningUpdates"*. Do exactly that, with **your** Team ID:

```sh
xcodebuild -workspace NPayRN.xcworkspace -scheme NPayRN -configuration Debug \
  -sdk iphoneos -destination 'generic/platform=iOS' -derivedDataPath build \
  DEVELOPMENT_TEAM=<YOUR_TEAM_ID> -allowProvisioningUpdates build \
  2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
```

**What it does:** Xcode signs in to Apple as your free Personal Team and tries to register the App ID
`com.npay.workshop` with the capabilities in `NPayRN.entitlements` (Push Notifications, App Groups), then create a
**development profile**. It only touches your own free team: nothing is paid, nothing is published.

Expect (`evidence/04-personal-team-allow-provisioning.txt`):

```
error: Cannot create a iOS App Development provisioning profile for "com.npay.workshop".
       Personal development teams, including "<YOUR_NAME>", do not support the Push Notifications capability.
error: No profiles for 'com.npay.workshop' were found: Xcode couldn't find any iOS App Development provisioning
       profiles matching 'com.npay.workshop'.
** BUILD FAILED **
```

**A free team cannot use Push Notifications.** Apple refuses the capability, so no profile can be made, so the
build has no profile (the second error follows from the first).

## 6a · The same build without Push

An entitlements file with **only the app group**, in `/tmp`, used for this one command (`CODE_SIGN_ENTITLEMENTS=…`
overrides the project's setting; no project file changes):

```sh
cat > /tmp/NoPush.entitlements <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>com.apple.security.application-groups</key>
  <array><string>group.com.npay.workshop</string></array>
</dict></plist>
XML
xcodebuild -workspace NPayRN.xcworkspace -scheme NPayRN -configuration Debug \
  -sdk iphoneos -destination 'generic/platform=iOS' -derivedDataPath build \
  DEVELOPMENT_TEAM=<YOUR_TEAM_ID> CODE_SIGN_ENTITLEMENTS=/tmp/NoPush.entitlements \
  -allowProvisioningUpdates build \
  2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
```

Expect (`evidence/04-personal-team-no-push.txt`):

```
error: Communication with Apple failed: Your team has no devices from which to generate a provisioning profile.
       Connect a device to use or manually add device IDs in Certificates, Identifiers & Profiles.
error: No profiles for 'com.npay.workshop' were found: …
** BUILD FAILED **
```

- With Push gone, Apple **did not object to App Groups**: it stopped at the next requirement.
- **A development profile needs at least one device.** A free team can only get one by connecting an iPhone (step 6b);
  it has no web portal to type device IDs into.

## 6b · On your own iPhone (optional; not run for this lab)

**You need a USB cable.** Without one, Xcode's device setup (Window › Devices and Simulators › **+**) shows:
*"No Devices Found. Make sure that the devices are connected to your computer using a USB cable."* (A phone can use
Wi-Fi only after it has been set up once over a cable.) No cable → skip 6b; this lab is complete without it.

If you have an iPhone and a cable: connect it, turn on **Developer Mode** (Settings › Privacy & Security), trust the
Mac, then build for it, without Push:

```sh
xcrun devicectl list devices                     # your iPhone's name
xcodebuild -workspace NPayRN.xcworkspace -scheme NPayRN -configuration Debug \
  -destination 'platform=iOS,name=<YOUR_IPHONE_NAME>' -derivedDataPath build \
  DEVELOPMENT_TEAM=<YOUR_TEAM_ID> CODE_SIGN_ENTITLEMENTS=/tmp/NoPush.entitlements \
  -allowProvisioningUpdates build \
  2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
```

Xcode can now register the device and try to make the profile. Write down what happens. Then decode the profile:

```sh
security cms -D -i build/Build/Products/Debug-iphoneos/NPayRN.app/embedded.mobileprovision > profile.plist
plutil -p profile.plist | grep -E "Name|TeamIdentifier|ExpirationDate|application-groups|ProvisionedDevices" -A2
codesign -d --entitlements - --xml build/Build/Products/Debug-iphoneos/NPayRN.app | plutil -p -
```

Check: the App ID is `<TEAM_ID>.com.npay.workshop`; the app's entitlements are in the profile; your iPhone's UDID is in
`ProvisionedDevices`; and the `ExpirationDate`. (To actually *use* NPay on the phone, it would also need to reach the
server at your Mac's IP instead of `localhost`; the workshop stays on the Simulator.)

---

## What a free Apple ID allows (what this lab found)

| | Free Apple ID (Personal Team) | Paid team (US$99/year) |
|---|---|---|
| build and run in the Simulator | **yes** (Labs 1–3) | yes |
| a development certificate | **yes** (step 5) | yes |
| the App Groups capability | **not refused** (step 6a) | yes |
| the Push Notifications capability | **refused** (step 6) | yes |
| a development profile | **only with a connected iPhone** (step 6a: "no devices") | yes, devices can also be added on the web portal |
| real push through APNs | **no** (needs Push + an APNs key) | yes |
| Ad Hoc / App Store profiles, TestFlight | **no** (no distribution certificate, no App Store Connect) | yes |

What that means for the rest of this workshop:

- **Lab 5 · notifications:** in the Simulator with `xcrun simctl push`: no account needed.
- **Lab 6 · server push:** the NPay server sends the notification to the Simulator; real APNs is explained, not run.
- **Labs 7–8 · widgets:** in the Simulator, where App Groups work without an account.
- **Labs 11–14 · archive, TestFlight:** archive and dSYMs locally; the TestFlight upload is explained, not run.

## Profiles: which one when (reference)

| Profile | Signed with | Runs on | Needs |
|---|---|---|---|
| **Development** | Apple Development certificate | the devices listed in it | any team (free: a connected iPhone) |
| **Ad Hoc** | Apple Distribution certificate | the devices listed in it | a paid team |
| **App Store** | Apple Distribution certificate | any device, via TestFlight / the App Store | a paid team |

`aps-environment` follows the profile: **development** (APNs sandbox) for development builds, **production** for
Ad Hoc / App Store builds.

## Automatic vs manual signing

- **Automatic:** Xcode creates and renews App IDs and profiles (what steps 6–6b use). Fine for most teams.
- **Manual:** you create them on developer.apple.com and pick them in Xcode. Teams use it to control exactly which
  certificate and profile ship (for example on CI servers). Needs a paid team.

## Checklist

| Check | Pass when |
|---|---|
| Simulator signing | `Signature=adhoc`, `TeamIdentifier=not set` |
| entitlements in the app | the `.xcent` shows `aps-environment` and the app group |
| device build, no team | "requires a development team" |
| device build, team only | "No profiles for 'com.npay.workshop' were found" |
| certificate | `security find-identity` lists an Apple Development identity; issuer Apple, OU = Team ID |
| free team, with Push | "Personal development teams … do not support the Push Notifications capability" |
| free team, without Push | "Your team has no devices from which to generate a provisioning profile" |

## Answer before Lab 5

1. Name the five things that must agree for a device build, and what fails if each is missing.
2. Why do Labs 1–3 (and the rest of the workshop) work without any of them?
3. Where is your private key, and what happens if you lose it?
4. What is `application-identifier`, and who added it?
5. A free Apple ID: which capability did Apple refuse, and what else stopped the build?
6. What would a paid account let you do that this workshop can't?

## If something goes wrong

| You see | Do this |
|---|---|
| `** BUILD FAILED **` but no reason shown | you cut the output with `tail`: use `2>&1 | grep -E "error:|BUILD"` |
| `Signing for "NPayRN" requires a development team` | pass `DEVELOPMENT_TEAM=<YOUR_TEAM_ID>` |
| `No profiles for 'com.npay.workshop' were found` | add `-allowProvisioningUpdates` (step 6); it is also the second line of every failure in steps 6–6a |
| `Personal development teams … do not support the Push Notifications capability` | expected with a free Apple ID: build without Push (step 6a) |
| `Your team has no devices from which to generate a provisioning profile` | expected without an iPhone: connect one (step 6b), or stay on the Simulator |
| `security find-identity` shows `0 valid identities found` | Xcode › Settings › Accounts › your Apple ID › **Manage Certificates** › **+ Apple Development** |
