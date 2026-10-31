# Lab 5 · Concepts: push notifications, questions answered

Questions that came up while doing Lab 5, answered on NPay's code. Companion to [lab5.md](lab5.md).

---

## 1 · How does a push notification work? The flow

There are two flows: the **real** one (an iPhone, a paid Apple account) and what **Lab 5** does in the Simulator.
Lab 5 replaces only the first half; everything from "iOS receives it" onwards is the same code.

### The real flow (Lab 6 explains it; needs a paid account)

```
 ① SET-UP (once per install)
 NPay ──"may I send notifications?"──▶ iOS ──prompt──▶ user taps Allow
 NPay ──registerForRemoteNotifications()──▶ iOS ──▶ APNs (Apple's push service)
 NPay ◀──── device token (an address for "NPay on this iPhone") ─────────────┘
 NPay ──sends the device token──▶ NPay server  (stores it with Asha's account)

 ② SENDING (every time)
 NPay server ──"Payment sent" payload + device token + APNs key──▶ APNs
 APNs ──────────── delivers over its permanent connection ──────▶ the iPhone (iOS)

 ③ ON THE PHONE (what Lab 5 built)
 iOS ──▶ shows the banner (or asks NPay first, if NPay is open)
 user taps ──▶ iOS ──▶ NotificationCenterDelegate (Swift) ──▶ NPayNotifications ──event──▶ JS ──▶ Payment detail
```

- **APNs** (Apple Push Notification service) is the only way to reach an iPhone. Your server never talks to the
  phone directly.
- **The device token** is the address APNs gives for "this app on this phone". The server needs it to say *who* gets
  the push.
- **The APNs key (`.p8`)** proves to Apple that the server may push for NPay. It comes from the paid developer portal,
  which is why Lab 4 showed a free team can't have Push.

### What Lab 5 does in the Simulator

```
 ① SET-UP
 NPay (after sign-in) ──requestPermission()──▶ iOS ──prompt──▶ Allow
    (no device token, no APNs: not needed for simctl)

 ② SENDING
 you ──xcrun simctl push … push/payment-sent.apns──▶ the Simulator's iOS
    (simctl takes the place of "NPay server + APNs")

 ③ ON THE PHONE (same code as real)
```

### Step ③ in detail

1. **The notification arrives.** iOS reads the **`aps`** part of the payload (title, body, sound).
2. **Is NPay open?**
   - **No** (background or not running): iOS shows the banner on its own.
   - **Yes:** iOS asks NPay first, through `NotificationCenterDelegate.willPresent`. NPay answers
     `[.banner, .list, .sound]` = "show it anyway". Without that answer, nothing would show while you're in the app.
3. **The user taps it.** iOS opens (or launches) NPay and calls `NotificationCenterDelegate.didReceive` with the whole
   payload. NPay takes its own part, **`payment`**.
4. **Swift hands it to JavaScript:**
   - **JS already listening:** the `NPayNotifications` module sends the event `notificationTapped`.
   - **NPay was not running:** JS hasn't started, so Swift keeps the tap (`pendingTap`); when JS starts, `App.tsx`
     asks `getInitialNotification()` and gets it.
5. **JS opens the screen.** `App.tsx` navigates to **Payment detail** with that payment (after sign-in if needed).

### Who does what

| Part | Real flow | Lab 5 |
|---|---|---|
| decides to notify | NPay server | you |
| delivers | APNs | `xcrun simctl push` |
| shows the banner | iOS | iOS |
| "show it while open?" | `willPresent` (Swift) | same |
| the tap → the app | `didReceive` (Swift) → event / `getInitialNotification` | same |
| opens the screen | `App.tsx` (JS) | same |

---

## 2 · Is the Spring Boot app sending these notifications?

**Not in Lab 5.** You send the notification by hand:

```sh
xcrun simctl push "iPhone 17 Pro" com.npay.workshop push/payment-sent.apns
```

The server only does what it did before (sign-in, balance, payments), and the payload file is fixed: the same
₹1,500.50 to ravi@npay every time.

**Lab 6 brings in the Spring Boot app:** after a real payment, the server sends "Payment sent" itself, with that
payment's real data. With a free Apple ID it can't use APNs, so it delivers to the Simulator:

```
NPay app ──pay──▶ Spring Boot server ──builds the payload from the real payment──▶ xcrun simctl push ──▶ Simulator
```

The server runs on the same Mac as the Simulator, so it can call `simctl push` itself; that step stands in for APNs.
With a paid account, the app would register for a **device token** and send it to the server, and the server would
send the same payload to **APNs** with the **`.p8` key**. The server code stays almost the same; only the
"deliver" step differs.

---

## 3 · When I tap a notification, how does it know which app screen to open?

iOS doesn't know the screen. It only knows which app the notification is for, `com.npay.workshop`. The screen is
NPay's own decision, made in code from data we put in the payload.

**1 · The payload carries the information.** Besides Apple's `aps` part, we added our own key:

```json
"payment": { "id": "pay_101", "recipient": "ravi@npay", "amount_paise": 150050, … }
```

iOS ignores it, but keeps it with the notification.

**2 · On a tap, iOS opens NPay and gives it the whole payload,** in `NotificationCenterDelegate.swift`:

```swift
func userNotificationCenter(_ center: UNUserNotificationCenter,
                            didReceive response: UNNotificationResponse, …) {
  let userInfo = response.notification.request.content.userInfo   // the whole payload
  // keep everything except "aps" → { "payment": {…} }
  module.sendTap(data)       // JS is listening → send it as the "notificationTapped" event
  // or: pendingTap = data   // JS not started yet → keep it for getInitialNotification()
}
```

**3 · JavaScript decides the screen,** in `App.tsx`:

```ts
onNotificationTapped(data => data.payment && setTapped(data.payment));   // "a payment was tapped"
…
if (signedIn && navReady && tapped) {
  navigation.navigate('PaymentDetail', { payment: tapped });           // ← here the screen is chosen
}
```

The rule is ours: if the payload has a `payment`, open Payment detail with it. With no `payment` in the payload,
nothing navigates and NPay just opens where it was.

**In one line:** payload (`payment`) → iOS hands it to Swift (`didReceive`) → Swift hands it to JS (event) → JS calls
`navigate('PaymentDetail', …)`.

**How real apps usually do it:** many apps put a route or deep link in the payload, e.g.
`"link": "npay://payments/pay_101"`. One piece of code then maps any link to a screen, the same code that handles links
from websites or emails. React Navigation supports this ("linking"). NPay keeps it simpler by sending the payment
itself.

---

## 4 · Can notifications have emojis, or a running timer?

### Emojis: yes, they're just text

The title and body are plain Unicode text, so emojis go straight into the payload. Nothing changes in the app.

```json
"title": "✅ Payment sent",
"body": "₹1,500.50 to ravi@npay 💸 · balance ₹23,499.50"
```

- Keep payload files **UTF-8** (`₹` needs it too).
- Emojis count toward the **4096-byte** limit: usually 4 bytes each.
- Try it: `xcrun simctl push "iPhone 17 Pro" com.npay.workshop push/payment-sent-emoji.apns` (lab5.md, step 6;
  checked: the banner shows ✅ and 💸).

### Timers: a normal notification can't count down

A notification's text is **fixed when it is sent**: "expires in 2:00" stays "2:00". iOS has three related features:

| You want | iOS feature | How |
|---|---|---|
| a notification that **appears later** ("Bill due" in 1 hour) | a **local notification with a time trigger** | the app schedules it on the phone: `UNTimeIntervalNotificationTrigger` (after N seconds) or `UNCalendarNotificationTrigger` (at a date/time). No server, no Apple account. **Lab 6** |
| a **live countdown** on the lock screen ("request expires in 4:59… 4:58…") | a **Live Activity** (ActivityKit) | a small **SwiftUI** view in a widget extension; a timer text such as `Text(timerInterval: start...end)` counts down **by itself**, shown on the lock screen and in the Dynamic Island. **Lab 8** |
| an **urgent** notification that breaks through Focus | `"interruption-level": "time-sensitive"` in `aps` | needs the Time Sensitive capability; it changes delivery priority, not a countdown |

Lab 6 and Lab 8 build and test these before they're described as working.
