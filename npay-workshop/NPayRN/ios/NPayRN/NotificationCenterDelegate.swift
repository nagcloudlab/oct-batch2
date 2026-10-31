import Foundation
import UserNotifications

/// Lab 5 · iOS calls this object about notifications for NPay.
/// It is set as UNUserNotificationCenter's delegate in AppDelegate, at launch, so it also hears
/// the tap that launched the app.
final class NotificationCenterDelegate: NSObject, UNUserNotificationCenterDelegate {
  static let shared = NotificationCenterDelegate()

  /// A tap that arrived before JavaScript was listening (for example, the tap that launched the app).
  var pendingTap: [String: Any]?

  /// A notification arrives while NPay is open: iOS asks what to do. Show it as a banner anyway.
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    completionHandler([.banner, .list, .sound])
  }

  /// The user tapped a notification: hand its custom data to JavaScript.
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo
    var data: [String: Any] = [:]
    for (key, value) in userInfo where key as? String != "aps" {
      if let key = key as? String { data[key] = value }
    }
    if let module = NPayNotifications.current, module.isListening {
      module.sendTap(data)
    } else {
      pendingTap = data   // JavaScript picks it up with getInitialNotification()
    }
    completionHandler()
  }
}
