import Foundation

/// Lab 3 · the app's first native module.
/// Tells JavaScript which environment this build is and which server it talks to.
/// The values come from Info.plist, which Xcode fills in from the build configuration
/// (Debug, Staging or Release: Build Settings › NPAY_ENVIRONMENT and NPAY_SERVER_URL).
@objc(AppConfig)
final class AppConfig: NSObject {

  /// Constants are computed once, when JavaScript first asks for the module.
  @objc func constantsToExport() -> [AnyHashable: Any] {
    let info = Bundle.main.infoDictionary ?? [:]
    return [
      "environment": info["NPayEnvironment"] as? String ?? "unknown",
      "serverURL": info["NPayServerURL"] as? String ?? "",
      "version": info["CFBundleShortVersionString"] as? String ?? "",
      "build": info["CFBundleVersion"] as? String ?? "",
    ]
  }

  /// Reading Info.plist needs no UI, so React Native may set this module up off the main thread.
  @objc static func requiresMainQueueSetup() -> Bool { false }
}
