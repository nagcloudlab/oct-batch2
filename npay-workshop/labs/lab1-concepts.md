# Lab 1 · Concepts: how a React Native CLI app becomes an iOS app

The questions that came up while doing Lab 1, answered on the NPay project. Every file, line and error quoted here is
from this repo or from a real run (see `evidence/`).

## 1 · The big picture

```
native code (libraries) ──CocoaPods──▶ Pods.xcodeproj targets ─┐
native code (yours, Swift) ──────────▶ NPayRN.xcodeproj ───────┼─ Xcode builds ─▶ NPayRN.app
                                                               │                     contains Hermes (the JS engine)
your JS (.tsx) ── Metro bundles ──▶ one JS bundle ─────────────┘
                                    Debug:   sent by Metro when the app starts
                                    Release: put inside the app as Hermes bytecode
```

- **Native code** becomes Xcode targets. **CocoaPods prepares** them; **Xcode builds** them.
- **JS code** is bundled by **Metro** and run by **Hermes** (an engine that is itself native code inside the app).

## 2 · What a React Native app needs inside it

Your JavaScript draws nothing by itself. Native code turns `<View>`, `<Text>`, `<Pressable>` into real iOS views,
and native code (Hermes) runs your JS. That native code must be compiled into the app:

| Native code | Comes from | Language |
|---|---|---|
| React Native's core | the `react-native` npm package | Objective-C, C++ |
| Hermes, the JS engine | the `react-native` npm package | C++ |
| the screens React Navigation uses | `react-native-screens` (its `ios/` folder) | Objective-C++ |
| your app's own native code | `ios/NPayRN/AppDelegate.swift` (and later labs' Swift) | Swift |

**npm only downloads files into `node_modules/`.** It knows nothing about Xcode and cannot compile native code
into an app. That is CocoaPods' job.

## 3 · CocoaPods

**A dependency manager for native iOS code.** It does for native libraries what npm does for JS packages, with one
difference: it must **prepare Xcode's project files**, because Xcode is what compiles and builds.

> **CocoaPods prepares the project; Xcode builds it.** CocoaPods never compiles anything. It is a separate
> command-line tool, not part of Xcode, not from Apple.

### What `bundle exec pod install` does

1. **Reads `ios/Podfile`**, the recipe. Two lines do the work:
   - `use_react_native!`: React Native's own native code;
   - `use_native_modules!`: **autolinking**, which scans `node_modules` for packages that ship a `.podspec`
     (that is how `RNScreens.podspec` was found).
2. **Reads each library's `.podspec`**: which files to compile, which settings, which dependencies.
3. **Creates `ios/Pods/Pods.xcodeproj`**: one Xcode target per library (87 for NPay).
4. **Creates `NPayRN.xcworkspace`**: just a list of two projects:
   ```xml
   <FileRef location = "group:NPayRN.xcodeproj"> </FileRef>     ← your app
   <FileRef location = "group:Pods/Pods.xcodeproj"> </FileRef>  ← the libraries
   ```
5. **Edits your `NPayRN.xcodeproj`**: settings files `Pods-NPayRN.debug.xcconfig` / `.release.xcconfig` (where
   headers are, what to link), `libPods-NPayRN.a` (link the libraries), and three build steps run on every build:
   `[CP] Check Pods Manifest.lock`, `[CP] Embed Pods Frameworks`, `[CP] Copy Pods Resources` (`[CP]` = CocoaPods).
6. **Writes `Podfile.lock`**: the exact versions (`React-Core 0.87.1`, `hermes-engine 250829098.0.17`, …), like
   `package-lock.json`.

Then **Xcode** builds the **workspace**: the libraries first, then your app, linked and signed into one `NPayRN.app`.

### Why you must open `NPayRN.xcworkspace`, never `NPayRN.xcodeproj`

Built from the `.xcodeproj` alone, Xcode never sees the Pods project. Real run (`evidence/01-build-xcodeproj-only.txt`):

```
fatal error: 'React/RCTBridgeDelegate.h' file not found
```

Built from `NPayRN.xcworkspace`: `** BUILD SUCCEEDED **`.

### When to run `pod install` again

- **Yes:** you add or remove an npm package with native code, upgrade React Native, change the Podfile, add an SDK.
- **No:** you change only JS. Metro handles that.

### Its future

React Native 0.87's own `pod install` output says: *"Calling pod install directly is deprecated in React Native
because we are moving away from Cocoapods toward alternative solutions."* It is still how a React Native CLI app gets
its native code today.

## 4 · SDKs: source libraries vs prebuilt binaries

| Kind | Example | What arrives | Who compiles it |
|---|---|---|---|
| source library | RNScreens, most RN libraries | source (`.mm`, `.swift`) | **Xcode**, in the Pods project |
| binary SDK | a payment SDK; `MockAuthorizationSDK.xcframework` | a prebuilt **XCFramework**: compiled code + interface, no source | **nobody**: the vendor already did |

For a binary SDK the podspec says `vendored_frameworks = '…xcframework'` ("prebuilt, don't compile"). CocoaPods sets
up three steps that Xcode then runs: **copy** the right slice (iPhone or Simulator), **link** it
(`-framework MockAuthorizationSDK`, so `import MockAuthorizationSDK` works), **embed** it into `NPayRN.app/Frameworks/`
and sign it. Only your code that *uses* the SDK is compiled.

How SDKs reach a project: a **pod** (one line in the Podfile), a **Swift Package** (added in Xcode, no CocoaPods), or a
bare **`.xcframework`** (your own podspec with `vendored_frameworks`, or dragged into Xcode).

## 5 · Gemfile, Gemfile.lock, Bundler

CocoaPods is a **Ruby** program. Ruby has its own packages (**gems**) and package manager (**Bundler**):

| Ruby | JavaScript |
|---|---|
| a gem (CocoaPods is one) | an npm package |
| Bundler (`bundle`) | npm |
| `Gemfile` | `package.json` |
| `Gemfile.lock` | `package-lock.json` |
| `bundle install` | `npm install` |
| `bundle exec pod install` | `npx …`: run the project's own copy |

`NPayRN/Gemfile` (from the React Native template) is mostly rules:
```ruby
gem 'cocoapods', '>= 1.13', '!= 1.15.0', '!= 1.15.1'   # avoid two broken versions
gem 'activesupport', '>= 6.1.7.5', '!= 7.1.0'
gem 'xcodeproj', '< 1.26.0'                            # the library CocoaPods uses to edit Xcode projects
gem 'concurrent-ruby', '< 1.3.4'
```
`Gemfile.lock` records what Bundler picked: 41 gems, including **`cocoapods (1.15.2)`**, the newest that follows the
rules and runs on this Mac's Ruby 2.6. It is in git, so every participant runs the same CocoaPods.

## 6 · The `vendor/` folder

`NPayRN/vendor/bundle/` is where Bundler installed those gems: the Ruby version of `node_modules/`.

- `bundle config set --local path vendor/bundle` saved `BUNDLE_PATH: "vendor/bundle"` in `NPayRN/.bundle/config`.
- Inside: `vendor/bundle/ruby/2.6.0/gems/` (42 gems: `cocoapods-1.15.2`, `xcodeproj-1.25.1`, …) and `bin/pod`.
- **Not in git** (`.gitignore`: `/vendor/bundle/`); `bundle install` rebuilds it.
- Why there: no `sudo`, no system changes (a global `gem install cocoapods` fails on macOS's Ruby 2.6), and each
  project keeps its own version. Delete it and `bundle install` again to reset.

("Vendored frameworks" for SDKs is a different meaning: a library shipped as a prebuilt binary.)

## 7 · How the JS bundle gets into the app

Two real pieces.

**A build step in `NPayRN.xcodeproj`: "Bundle React Native code and images".** Xcode runs it on every build; it calls
`node_modules/react-native/scripts/react-native-xcode.sh`.

- **Debug, Simulator:** it does nothing. Our build log:
  `Skipping bundling in Debug for the Simulator (since the packager bundles for you).`
- **Release:** it runs Metro's bundler once (no server) → `main.jsbundle`; compiles it with **`hermesc`**
  (`-emit-binary`) into Hermes bytecode; copies it into the app. If that fails the build stops:
  `error: File … does not exist … your release application won't work!`

**`AppDelegate.swift` chooses where to load JS from:**
```swift
override func bundleURL() -> URL? {
#if DEBUG
    RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index")   // ask Metro
#else
    Bundle.main.url(forResource: "main", withExtension: "jsbundle")              // the file inside the app
#endif
}
```

| | Debug | Release |
|---|---|---|
| JS in the Xcode build? | no | yes: the build step bundles and compiles it |
| JS inside the app? | no | `main.jsbundle` (Hermes bytecode) |
| at launch | asks Metro (`localhost:8081`) | loads `main.jsbundle` |
| without Metro | red **"No script URL provided"** | runs normally |
| used for | development: edit, save, reload | TestFlight and the App Store |

So the JS becomes part of the app **as a file**, not as compiled native code. Hermes (native code) runs it.
Lab 2 does a Release build and checks all of this.

## 8 · Running the demo

| What | Command | Notes |
|---|---|---|
| server | `cd server && ./mvnw spring-boot:run` | `http://localhost:8080`; account **asha / npay-demo** (the only one, in `Sessions.java`) |
| Metro | `cd NPayRN && npx react-native start` | `http://localhost:8081` |
| app | build `NPayRN.xcworkspace` (Lab 1) | |

## In one line each

- **npm**: downloads JS packages (some contain native iOS code).
- **CocoaPods**: prepares that native code as Xcode projects. It doesn't build.
- **Bundler + Gemfile**: pin the CocoaPods tool itself; installed into `vendor/bundle`.
- **Xcode**: builds the workspace: native code compiled; in Release, the JS bundled in too.
- **Metro**: bundles your JS (serves it in Debug).
- **Hermes**: runs your JS inside the app (bytecode in Release).
