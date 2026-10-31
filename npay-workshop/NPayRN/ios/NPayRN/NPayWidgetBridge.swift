import ActivityKit
import Foundation
import React
import WidgetKit

/// Lab 8 · the native module JavaScript uses for the widget and the Live Activity.
@objc(NPayWidgetBridge)
final class NPayWidgetBridge: NSObject {
  private let shared = UserDefaults(suiteName: "group.com.npay.workshop")   // the App Group both may read

  @objc static func requiresMainQueueSetup() -> Bool { false }

  /// Writes the balance where the widget can read it, then asks iOS to redraw the widget.
  @objc func updateBalance(_ owner: String, balancePaise: NSNumber) {
    shared?.set(owner, forKey: "owner")
    shared?.set(balancePaise, forKey: "balancePaise")
    shared?.set(Date(), forKey: "updatedAt")
    WidgetCenter.shared.reloadTimelines(ofKind: "NPayBalance")
  }

  /// On sign-out: the widget must not keep showing Asha's balance.
  @objc func clear() {
    ["owner", "balancePaise", "updatedAt"].forEach { shared?.removeObject(forKey: $0) }
    WidgetCenter.shared.reloadTimelines(ofKind: "NPayBalance")
  }

  /// Starts a "payment request" Live Activity that counts down for `seconds`.
  @objc func startPaymentRequest(_ from: String, amountPaise: NSNumber, seconds: NSNumber,
                                 resolver resolve: @escaping RCTPromiseResolveBlock,
                                 rejecter reject: @escaping RCTPromiseRejectBlock) {
    guard #available(iOS 16.2, *) else { reject("unsupported", "Live Activities need iOS 16.2", nil); return }
    guard ActivityAuthorizationInfo().areActivitiesEnabled else {
      reject("disabled", "Live Activities are turned off for NPay", nil); return
    }
    let attributes = PaymentRequestAttributes(from: from, amountPaise: amountPaise.int64Value)
    let expiresAt = Date().addingTimeInterval(seconds.doubleValue)
    let content = ActivityContent(state: PaymentRequestAttributes.ContentState(expiresAt: expiresAt),
                                  staleDate: expiresAt)
    do {
      let activity = try Activity.request(attributes: attributes, content: content, pushType: nil)
      resolve(activity.id)
    } catch {
      reject("start_failed", error.localizedDescription, error)
    }
  }

  /// Ends every payment-request activity (e.g. once the request is paid).
  @objc func endPaymentRequests() {
    guard #available(iOS 16.2, *) else { return }
    Task {
      for activity in Activity<PaymentRequestAttributes>.activities {
        await activity.end(nil, dismissalPolicy: .immediate)
      }
    }
  }
}
