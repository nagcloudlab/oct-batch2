import SwiftUI
import WidgetKit

// Lab 7 · NPay's home-screen widget, in SwiftUI (WidgetKit).
// A widget is not a running app: iOS asks the Provider for a *timeline* of entries and draws the view for each one.
// Lab 8 · the real balance: the app writes it into the App Group and asks for a reload; the provider reads it.

struct BalanceEntry: TimelineEntry {
  let date: Date
  let owner: String
  let balancePaise: Int64?          // nil: signed out, nothing shared yet
  let updatedAt: Date?

  static let sample = BalanceEntry(date: .now, owner: "Asha", balancePaise: 2_500_000, updatedAt: nil)

  /// Lab 8: what the app last wrote into the shared App Group (NPayWidgetBridge.swift in the app).
  static func shared() -> BalanceEntry {
    let defaults = UserDefaults(suiteName: "group.com.npay.workshop")
    let paise = (defaults?.object(forKey: "balancePaise") as? NSNumber)?.int64Value
    let updated = defaults?.object(forKey: "updatedAt") as? Date
    return BalanceEntry(date: .now, owner: defaults?.string(forKey: "owner") ?? "", balancePaise: paise, updatedAt: updated)
  }
}

struct Provider: TimelineProvider {
  /// Shown while the widget loads, and redacted (greyed) by iOS.
  func placeholder(in context: Context) -> BalanceEntry { .sample }

  /// Shown in the widget gallery, when the user is choosing widgets.
  func getSnapshot(in context: Context, completion: @escaping (BalanceEntry) -> Void) {
    completion(.sample)
  }

  /// What the widget shows, and when to ask again. `.never`: until the app asks for a reload
  /// (WidgetCenter.reloadTimelines, after each balance update).
  func getTimeline(in context: Context, completion: @escaping (Timeline<BalanceEntry>) -> Void) {
    completion(Timeline(entries: [.shared()], policy: .never))
  }
}

/// ₹25,000.00 (Indian grouping), like the app's money.ts.
func formatPaise(_ paise: Int64) -> String {
  let formatter = NumberFormatter()
  formatter.numberStyle = .currency
  formatter.locale = Locale(identifier: "en_IN")
  formatter.currencyCode = "INR"
  return formatter.string(from: NSNumber(value: Double(paise) / 100)) ?? "₹\(paise / 100)"
}

struct NPayWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: BalanceEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("NPay")
        .font(.headline)
        .foregroundStyle(Color(red: 0.37, green: 0.92, blue: 0.83))
      Spacer()
      if let paise = entry.balancePaise {
        Text("Balance")
          .font(.caption)
          .foregroundStyle(.white.opacity(0.7))
        Text(formatPaise(paise))
          .font(family == .systemSmall ? .title3 : .title)
          .fontWeight(.bold)
          .foregroundStyle(.white)
          .minimumScaleFactor(0.6)
          .lineLimit(1)
        HStack(spacing: 4) {
          Text(entry.owner)
          if let updated = entry.updatedAt {
            Text("· \(updated, style: .time)")
          }
        }
        .font(.caption)
        .foregroundStyle(.white.opacity(0.7))
      } else {
        Text("Open NPay to see your balance")
          .font(.caption)
          .foregroundStyle(.white.opacity(0.8))
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .containerBackground(Color(red: 0.06, green: 0.09, blue: 0.16), for: .widget)
    .widgetURL(URL(string: "npay://send"))          // Lab 8: a tap opens Send money (a deep link)
  }
}

// Lab 8 · the payment-request Live Activity: lock screen and Dynamic Island. The countdown is a timer Text:
// iOS redraws it every second by itself; the app doesn't run.
struct PaymentRequestLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: PaymentRequestAttributes.self) { context in
      HStack(spacing: 12) {
        VStack(alignment: .leading, spacing: 2) {
          Text("Payment request").font(.caption).foregroundStyle(.white.opacity(0.7))
          Text("\(context.attributes.from) asks \(formatPaise(context.attributes.amountPaise))")
            .font(.headline).foregroundStyle(.white)
        }
        Spacer()
        VStack(alignment: .trailing, spacing: 2) {
          Text("expires in").font(.caption).foregroundStyle(.white.opacity(0.7))
          Text(timerInterval: Date.now...context.state.expiresAt, countsDown: true)
            .font(.title2.monospacedDigit()).fontWeight(.bold)
            .foregroundStyle(Color(red: 0.37, green: 0.92, blue: 0.83))
            .multilineTextAlignment(.trailing)
            .frame(width: 80)
        }
      }
      .padding()
      .activityBackgroundTint(Color(red: 0.06, green: 0.09, blue: 0.16))
      .widgetURL(Self.payURL(context.attributes))
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Text(context.attributes.from).font(.caption)
        }
        DynamicIslandExpandedRegion(.trailing) {
          Text(timerInterval: Date.now...context.state.expiresAt, countsDown: true)
            .monospacedDigit().frame(width: 60)
        }
        DynamicIslandExpandedRegion(.bottom) {
          Text("asks \(formatPaise(context.attributes.amountPaise))")
        }
      } compactLeading: {
        Text("₹").fontWeight(.bold).foregroundStyle(Color(red: 0.37, green: 0.92, blue: 0.83))
      } compactTrailing: {
        Text(timerInterval: Date.now...context.state.expiresAt, countsDown: true)
          .monospacedDigit().frame(width: 44)
      } minimal: {
        Text("₹")
      }
      .widgetURL(Self.payURL(context.attributes))
    }
  }

  /// A tap opens Send money, pre-filled with the request.
  static func payURL(_ a: PaymentRequestAttributes) -> URL? {
    URL(string: "npay://send?to=\(a.from)&amount=\(a.amountPaise)")
  }
}

@main
struct NPayWidgets: WidgetBundle {      // Lab 8: one extension, two widgets
  var body: some Widget {
    NPayWidget()
    PaymentRequestLiveActivity()
  }
}

struct NPayWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "NPayBalance", provider: Provider()) { entry in
      NPayWidgetView(entry: entry)
    }
    .configurationDisplayName("NPay Balance")
    .description("Your NPay balance at a glance.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

#Preview(as: .systemSmall) {
  NPayWidget()
} timeline: {
  BalanceEntry.sample
}
