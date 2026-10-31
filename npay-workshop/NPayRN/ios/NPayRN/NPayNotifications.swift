import Foundation
import React
import UserNotifications

/// Lab 5 · the native module JavaScript uses for notifications:
/// ask for permission, read the permission, and hear about taps (as an event).
@objc(NPayNotifications)
final class NPayNotifications: RCTEventEmitter {
  /// The live module, so NotificationCenterDelegate can forward taps to it.
  static weak var current: NPayNotifications?
  private(set) var isListening = false

  override init() {
    super.init()
    NPayNotifications.current = self
  }

  override static func requiresMainQueueSetup() -> Bool { false }

  override func supportedEvents() -> [String]! { ["notificationTapped"] }

  override func startObserving() { isListening = true }
  override func stopObserving() { isListening = false }

  func sendTap(_ data: [String: Any]) {
    sendEvent(withName: "notificationTapped", body: data)
  }

  /// Shows iOS's "Allow notifications?" prompt the first time; later calls return the saved answer.
  @objc func requestPermission(_ resolve: @escaping RCTPromiseResolveBlock,
                               rejecter reject: @escaping RCTPromiseRejectBlock) {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
      if let error { reject("permission_error", error.localizedDescription, error) } else { resolve(granted) }
    }
  }

  /// "authorized", "denied", "notDetermined", "provisional" or "ephemeral".
  @objc func getPermissionStatus(_ resolve: @escaping RCTPromiseResolveBlock,
                                 rejecter reject: @escaping RCTPromiseRejectBlock) {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      let names: [UNAuthorizationStatus: String] = [.authorized: "authorized", .denied: "denied",
                                                    .notDetermined: "notDetermined", .provisional: "provisional",
                                                    .ephemeral: "ephemeral"]
      resolve(names[settings.authorizationStatus] ?? "unknown")
    }
  }

  /// Lab 6 · a local notification: NPay itself asks iOS to show it `seconds` from now. No server, no APNs.
  /// `data` travels with it (like a push's custom keys) and comes back on a tap.
  @objc func scheduleReminder(_ seconds: NSNumber, title: String, body: String, data: NSDictionary,
                              resolver resolve: @escaping RCTPromiseResolveBlock,
                              rejecter reject: @escaping RCTPromiseRejectBlock) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default
    content.userInfo = data as? [AnyHashable: Any] ?? [:]
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds.doubleValue, repeats: false)
    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
    UNUserNotificationCenter.current().add(request) { error in
      if let error { reject("schedule_error", error.localizedDescription, error) } else { resolve(request.identifier) }
    }
  }

  /// The tap that launched the app (or arrived before JavaScript listened), once; then null.
  @objc func getInitialNotification(_ resolve: @escaping RCTPromiseResolveBlock,
                                    rejecter reject: @escaping RCTPromiseRejectBlock) {
    DispatchQueue.main.async {
      resolve(NotificationCenterDelegate.shared.pendingTap)
      NotificationCenterDelegate.shared.pendingTap = nil
    }
  }
}
