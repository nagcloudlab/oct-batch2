# NPay Workshop · React Native CLI + native iOS (Swift)

An incremental, hands-on workshop: **one app, grown one lab at a time**. Each lab adds one thing, ends with something
running, and has a test that proves it works. Slides come later, built from the finished labs.

## Who and why

- **Audience:** a team building iOS apps with **React Native CLI** (not Expo). They have just spent four days on
  iOS with SwiftUI.
- **The gap:** everything below lives on the native iOS side, in the `ios/` folder the team owns with the CLI:
  builds, signing, push, widgets, security, TestFlight, crash reports.
- **The approach:** screens stay in React Native; each topic adds its native part in **Swift** inside `ios/`, and
  a **Spring Boot** server plays NPay's backend.

## The app and the server

**NPayRN**: a small payments app. Asha signs in, sees her balance, sends money to Ravi, and gets told when money
arrives.

| Screen (React Native, `NPayRN/src/screens/`) | Shows |
|---|---|
| Sign in | asha / password |
| Home | balance (₹25,000.00) and recent payments |
| Send money | recipient, amount, Pay |
| Payment detail | one payment; opened from the list, a notification or the widget |

**Server** (`server/`, Spring Boot, Java 21): sign-in and tokens, balance, payments with an Idempotency-Key.
Later: device tokens, an APNs sender, HTTPS. Started from the security demo's server.

**Story across the labs:** Asha receives a payment → a push arrives → her widget shows the new balance → the app
ships through TestFlight → a crash is found in Crashlytics → fixed → build 2 ships.

## Folder

```
~/npay-workshop/     its own git repo; main = base + Lab 1, then branches lab-02 … lab-14
├── PLAN.md          this file
├── NPayRN/          the React Native CLI app (TypeScript screens; Swift in ios/)
├── server/          Spring Boot: ./mvnw spring-boot:run  → http://localhost:8080
├── labs/            lab1.md, lab2.md, … one per lab (each on its branch)
├── scripts/         autopilot.ts: drives the app for screenshots
├── evidence/        real outputs from the runs (logs, screenshots, errors)
└── deck/            slides, later
```

## Decisions made

| Topic | Decision |
|---|---|
| React Native | **0.87.1** (React Native CLI 20.2.0, New Architecture, Hermes). 0.88.1 came out 2026-10-27, too new for library support. |
| CocoaPods | through the project's **Gemfile with Bundler**, into `NPayRN/vendor/bundle` (works with macOS's Ruby 2.6; no Homebrew needed) |
| Bundle id | `com.npay.workshop` |
| Apple account | **a free Apple ID only** (decided 2026-10-30). Everything runs in the Simulator; Lab 4 shows for real where a free account stops (Push refused, a profile needs a connected iPhone). Real APNs and TestFlight are explained, not run |
| Crash reports | **Firebase Crashlytics** (plus Xcode Organizer and TestFlight's own crash feedback) |
| Push | **open**. Recommendation: Spring Boot → APNs directly with a `.p8` key, handled in Swift, no extra push library; one slide on how Firebase Messaging would sit in front |
| Evidence | every output in a lab comes from a real run; steps needing the paid account are marked **Trainer** |

## The base app, then one patch per lab

**Base (done):** NPayRN with its four screens talking to the server: plain React Native, nothing native added.
Participants receive it; they don't build it. React Navigation 7 (native stack) is its one native dependency (`RNScreens`).

**Each lab = one git branch on the one before:** `main` is the base app + Lab 1; `lab-02` adds Lab 2's change on
top of `main`, `lab-03` on top of `lab-02`, and so on. Every branch builds and runs.

```sh
git checkout lab-05            # fell behind? jump to the end of Lab 5
git diff lab-04 lab-05         # exactly what Lab 5 changed
git log --oneline main..lab-05 # the labs' commits, in order
```

`labs/labN.md` on each branch explains its change.

✅ done · ⏳ next · ☐ planned · **Trainer** = needs the paid Apple account or Firebase

| Lab | Status | Topic | The patch adds | Test |
|---|---|---|---|---|
| **1 · Build and run** | ✅ | Build | nothing: Bundler + CocoaPods, `.xcworkspace`, Debug build, Metro | without Metro: red "No script URL provided" |
| **2 · Release build** | ✅ | Build | JS bundled into the app as Hermes bytecode | runs with Metro stopped |
| **3 · Staging and Production** | ✅ | Build | build configurations + `.xcconfig` → Info.plist → **first Swift native module** | the Staging build uses the staging server |
| **4 · Signing** | ✅ (local) | Certificates + profiles | App ID with Push + App Groups, entitlements | decode a profile; break signing, read the error. **Trainer**: certificates, profiles |
| **5 · Notifications** | ✅ | Notifications | Swift: permission, `UNUserNotificationCenter` delegate, tap → Payment detail | `xcrun simctl push` |
| **6 · Server push + reminders** | ✅ | Notifications | Spring Boot sends "Payment sent" after a real payment (to the Simulator via `simctl push`; APNs + device token explained, paid account); the app **schedules a local reminder** (`UNTimeIntervalNotificationTrigger` / `UNCalendarNotificationTrigger`) | a real payment → its notification; a reminder appears at its time |
| **7 · Balance widget** | ✅ | Widgets | SwiftUI WidgetKit extension | the widget shows a balance |
| **8 · Live widget + Live Activity** | ✅ | Widgets | App Group, native module, deep link; a **Live Activity** (ActivityKit, SwiftUI) with a countdown that runs by itself, e.g. a payment request that expires in 5 minutes | pay → the widget updates; the countdown ticks on the lock screen / Dynamic Island |
| **9 · Keychain** | ✅ | Security | Swift Keychain module, refresh token | token in the Keychain, not in app files |
| **10 · HTTPS and pinning** | ✅ | Security | server HTTPS; ATS; pinning in Swift | a fake server is refused |
| **11 · Archive and export** | ✅ | TestFlight | version/build numbers, archive, export, dSYMs | the `.xcarchive` |
| **12 · TestFlight** | ☐ | TestFlight | upload, processing, testers | **Trainer**: installed from TestFlight |
| **13 · Crashlytics** | ☐ | Crash reports | Firebase SDK, dSYM upload, planted crashes, source maps | crashes symbolicated in Crashlytics. **Trainer**: Firebase project |
| **14 · Fix and ship build 2** | ☐ | Crash reports | the fix, build bump | **Trainer**: build 2 in TestFlight |

## Every lab has the same shape

1. **Goal**: one sentence, and what you will understand.
2. **Steps**: exact commands, each with the output to expect (from the real run).
3. **Look inside**: what the step changed in the app or the build.
4. **Test it**: one check that proves it, often by breaking it on purpose.
5. **Checklist**, then **questions** to answer before the next lab.
6. **If something goes wrong**: the errors we actually hit, with the fix.

## What is needed, and when

| Lab | Needed | From |
|---|---|---|
| 1–5, 7, 9–13 | a Mac with Xcode, a Simulator, Node 22.11+, Java 21 | each participant |
| 6, 8, 14, 16 | the paid Apple account (team ID, certificates, `.p8` APNs key), an iPhone | trainer |
| 15–16 | a Firebase project with an iOS app `com.npay.workshop`, its `GoogleService-Info.plist` | trainer |
| 8 | the push decision (see Decisions) | trainer |

## Running everything

```sh
# the server (terminal 1)
cd ~/npay-workshop/server && ./mvnw spring-boot:run          # http://localhost:8080, asha / npay-demo

# Metro (terminal 2)
cd ~/npay-workshop/NPayRN && npx react-native start          # http://localhost:8081

# the app (terminal 3): see labs/lab1.md for each step
cd ~/npay-workshop/NPayRN && npx react-native run-ios
```

## Status

- **Done:** the base NPay app (screens in `NPayRN/src/`, evidence `evidence/base-*`: sign in, ₹25,000.00, pay ₹1,500.50 →
  ₹23,499.50, `invalid_credentials`, `insufficient_funds`); Lab 1 (`labs/lab1.md`).
- **Repo:** `~/npay-workshop`, branch `main` (base + Lab 1).
- **Lab 2 done** on branch `lab-02` (`labs/lab2.md`): Release build, `main.jsbundle` = Hermes bytecode, runs and pays with Metro stopped; `npm run ios:release`.
- **Lab 3 done** on branch `lab-03` (`labs/lab3.md`): Debug / Staging / Release → development :8080 / staging :8090 / production; build settings → Info.plist → the `AppConfig` Swift native module → JS; staging server profile (₹10,000).
- **Lab 4 done (local part)** on branch `lab-04` (`labs/lab4.md`): ad hoc Simulator signing, entitlements file (Push + App Group), device build fails without a team / without a profile, the certificate read with openssl. **Trainer part not yet run:** automatic signing with the paid team, decoding the profile.
- **Lab 5 done** on branch `lab-05` (`labs/lab5.md`): permission, banner in the foreground, background and cold start, tap → Payment detail; Swift delegate + `NPayNotifications` event emitter; evidence from real taps (`scripts/uidriver`, `scripts/lab05-run.sh`).
- **Lab 6 done** on branch `lab-06` (`labs/lab6.md`): the server sends "Payment sent" after a real payment (`PushNotifier`, `simctl push`, once per payment); the app schedules a local reminder that opens Send money pre-filled; real APNs explained. Two runs of the UI tests passed.
- **Lab 7 done** on branch `lab-07` (`labs/lab7.md`): a SwiftUI WidgetKit extension (NPayWidget.appex) embedded in the RN app, sample balance; added to the home screen and tapped with real taps.
- **Lab 8 done** on branch `lab-08` (`labs/lab8.md`): the widget reads the real balance from the App Group and reloads after payments; `npay://send` deep links (widget, Live Activity, `simctl openurl`); a payment-request Live Activity with a self-running countdown (lock screen + Dynamic Island), ended by paying or signing out; sign-out clears the widget.
- **Lab 9 done** on branch `lab-09` (`labs/lab9.md`): refresh token in the Keychain (Swift module), session restored at launch with rotation, revoked on sign-out, refused after a server restart; the Keychain survives reinstall → fresh-install check; found and fixed the token in iOS's HTTP cache (`Cache-Control: no-store`).
- **Lab 10 done** on branch `lab-10` (`labs/lab10.md`): Release over HTTPS (:8443, demo CA); an inspecting proxy (:8444) reads the password when trusted; `NSPinnedDomains` in Info.plist (no code) refuses it, iOS logs `Trust evaluate failure: [leaf LeafSPKISHA256]`; five cases run by the UI driver.
- **Lab 11 done** on branch `lab-11` (`labs/lab11.md`): `npm run ios:archive` (unsigned device archive, `platform IOS`), `check-archive.sh` (versions, https, Hermes, dSYM UUIDs), export fails without a paid team (no "iOS Distribution" certificate), a drifted widget version only warns, `set-version.sh` sets all six places.
- **Next:** Lab 12 · ready for TestFlight.
- **Tooling:** `scripts/autopilot.ts` drives the app's real code for screenshots (no taps from the shell); it is
  copied into the app only while capturing, then removed.
- **Waiting:** the push decision (before Lab 8); the trainer's Apple and Firebase details (Labs 6, 8, 14–16).
- **Not started:** slides (after the labs).
