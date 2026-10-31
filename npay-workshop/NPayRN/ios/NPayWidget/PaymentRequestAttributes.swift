import ActivityKit
import Foundation

/// Lab 8 · what a "payment request" Live Activity carries. Compiled into BOTH the app (which starts the activity)
/// and the widget extension (which draws it), so both agree on the same type.
struct PaymentRequestAttributes: ActivityAttributes {
  /// Data that can change while the activity runs (an update would send a new ContentState).
  struct ContentState: Codable, Hashable {
    var expiresAt: Date
  }

  /// Fixed for the activity's whole life.
  var from: String
  var amountPaise: Int64
}
