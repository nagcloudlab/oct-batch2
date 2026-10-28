# Lesson 3.1 — NavigationStack & NavigationLink

*Unit 3 · Navigation, Architecture & Polish*

---

## Concept 1 of 6 — NavigationStack + Link

> 🔑 NavigationStack manages a stack of screens; NavigationLink declares a destination to push. Wrap the root in a stack.  

**Key points**

- The smallest possible example:
    - Tap "Send Money" → you slide to a new screen with a Back button.
- The two new pieces:
    - `NavigationStack  — the container that manages a STACK of` screens (push on tap, pop on Back).
    - `NavigationLink   — a tappable element that DECLARES a` destination (the screen to push).
    - .navigationTitle — the title shown in the nav bar.
- NavigationLink has two forms:
    - `NavigationLink("Title") { Destination() }           // text label`
    - `NavigationLink { Destination() } label: { AnyView }  // custom label`
- Everything must live INSIDE a NavigationStack for links/titles to work.
- A real NPay would use folders: Models/ (Money, Transaction), Components/ (BalanceCard…), Screens/ (PaymentScreen…).

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            NavigationLink("Send Money") {
                Text("NPay Payment Screen")
            }
            .navigationTitle("NPay")
        }
    }
}

#Preview { ContentView() }
```

---

## Concept 2 of 6 — NavigationStack ≠ VStack

> 🔑 NavigationStack is a navigation HISTORY (push/pop one screen at a time), not a layout container that shows kids together.  

**Key points**

- VStack/HStack/ZStack arrange MULTIPLE children on screen AT ONCE (along X/Y/Z).
- "Stack" here = a stack DATA STRUCTURE (like a stack of plates):
    - `push a screen on tap → it's on top (visible)`
    - `Back → pop the top → the previous screen shows again`
- What actually gets pushed? At the API level, SwiftUI tracks a navigation DESTINATION.
- Off-screen ≠ destroyed: when you push PaymentScreen, the dashboard stops being visible but isn't necessarily torn down; NavigationStack keeps the hierarchy so Back can return to it.
- UIKit did this imperatively: navController.pushViewController(…).

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {             // VStack = layout (both visible)
                Text("Both of these show at once:")
                NavigationLink("Go to screen 2") {   // push = navigation
                    Text("Screen 2 — tap Back to pop")
                        .navigationTitle("Screen 2")
                }
                NavigationLink("Go to screen 3") {
                    Text("Screen 3 — tap Back to pop")
                        .navigationTitle("Screen 3")
                }
            }
            .navigationTitle("Screen 1")
        }
    }
}

#Preview { ContentView() }
```

---

## Concept 3 of 6 — NavigationLink vs Button

> 🔑 Button = perform an action (stay); NavigationLink = move to a destination (push). Pick by intent.  

**Key points**

- Button = DO something (run an action, stay here): Use it to confirm a payment, toggle, submit — an action that mutates state and keeps you on the screen.
- NavigationLink = GO somewhere (push a destination): Use it to MOVE from one screen to another.
- Why it matters (not just style)
- Rule of thumb:
    - `changes data / confirms  → Button`
    - `moves to another screen   → NavigationLink`
- In NPay: "Send Money" (dashboard → form) is a NavigationLink; "Send Demo Payment" (confirm the payment) is a Button.
- Sometimes you must navigate AFTER logic runs (e.g. only on a successful payment).

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    @State private var taps = 0
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Button: acts, stays here
                Button("Tap me (action)") { taps += 1 }
                    .buttonStyle(.borderedProminent)
                Text("Button taps: \(taps)")

                // NavigationLink: goes somewhere
                NavigationLink("Go to Payment (navigate)") {
                    Text("Payment Screen").navigationTitle("Payment")
                }
            }
            .navigationTitle("Link vs Button")
        }
    }
}

#Preview { ContentView() }
```

---

## Concept 4 of 6 — destination screens as structs

> 🔑 Each destination is its own View struct carrying its content + .navigationTitle; it never wraps itself in a NavigationStack.  

**Key points**

- Why a separate struct (not inline)? A screen is a distinct DESTINATION with its own content, state, and (soon) inputs.
- Nav-bar config goes INSIDE the destination, on its root view:
    - `.navigationTitle("Send Money")          — the title`
- IMPORTANT: the destination does NOT wrap itself in a NavigationStack (recall the nesting discussion) — the ROOT stack already provides the bar/Back button.
- Preview a screen alone by wrapping it in a NavigationStack in its own #Preview (so you see its nav bar in isolation)
- Put buttons in the nav bar with .toolbar { ToolbarItem(...) } (e.g. a trailing "Edit").

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                NavigationLink("Send Money") { PaymentScreen() }
                NavigationLink("History")    { HistoryScreen() }
            }
            .navigationTitle("NPay")
        }
    }
}

struct PaymentScreen: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.up.right.circle.fill")
                .font(.system(size: 64)).foregroundStyle(.blue)
            Text("Send Money").font(.title.bold())
            Text("NPay payment form will appear here.")
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("Send Money")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HistoryScreen: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 64)).foregroundStyle(.blue)
            Text("Transaction History").font(.title.bold())
            Text("NPay transaction history will appear here.")
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("History")
    }
}

#Preview { ContentView() }
```

---

## Concept 5 of 6 — state across screens + dismiss

> 🔑 One owner (dashboard); screens receive values/actions, never their own copies; @Environment(\.dismiss) pops the screen.  

**Key points**

- The dashboard (ContentView) stays the single source of truth.
- Destination screens RECEIVE what they need — they do NOT make their own copies.
- A pushed screen can close ITSELF with @Environment(\.dismiss):
    - `dismiss` is read from the ENVIRONMENT (the same mechanism that propagated .font in 2.6). SwiftUI injects a close-this-screen action; calling it pops the current destination. Great after a successful action ("payment done → auto-return").
- Destinations read the owner's CURRENT value: while PaymentScreen is open, it shows the live balance; if it changes, the screen reflects it.
- Display-only screen (HistoryScreen) → pass a VALUE.
- Screen that edits owner state directly → pass a $BINDING.
- Screen that REQUESTS an operation (PaymentScreen) → pass an ACTION CLOSURE (onSend) and let the owner validate+mutate.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    @State private var balancePaise = 2_500_000
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Balance: \(balancePaise) paise")
                NavigationLink("Spend ₹100") {
                    SpendScreen(balancePaise: balancePaise) {
                        balancePaise -= 10_000      // owner mutates
                    }
                }
            }
            .navigationTitle("NPay")
        }
    }
}

struct SpendScreen: View {
    let balancePaise: Int            // received value (read-only)
    let onSpend: () -> Void          // action up to the owner
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(spacing: 20) {
            Text("Balance here: \(balancePaise) paise")
            Button("Spend ₹100 & go back") {
                onSpend()
                dismiss()            // pop back to the dashboard
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Spend")
    }
}

#Preview { ContentView() }
```

---

## Concept 6 of 6 — wire the real NPay (Milestone)

> ⭐️ MILESTONE 3.1 — NPay is multi-screen: dashboard → Send Money / History, all sharing ONE owner's state.  
> 🔑 One NavigationStack at the root; the owner passes value+action to pushed screens; screens dismiss() themselves when done.  

**Key points**

- ContentView wraps its dashboard in ONE NavigationStack and owns @State balancePaise + transactions (unchanged from 2.12).
- Two NavigationLinks with custom Label content push the screens.
- PaymentScreen = the Unit-2 PaymentForm, now a full screen.
- HistoryScreen = a List of the owner's transactions (value).
- The dashboard still shows a 3-row "Recent Transactions" peek (transactions.prefix(3)); full list lives on History.
- New bits used here (deeper dives later):
    - .alert(_:isPresented:) — simple confirmation (Lesson 3.4)
    - @Environment(\.dismiss) — pop after success (Concept 5)

**Complete runnable file (the lesson's full app)**

```swift
import SwiftUI

// MARK: - Model & money helper

struct Transaction: Identifiable {
    let id = UUID()
    let title: String
    let amountPaise: Int
    let date: Date
}

enum Money {
    static func display(_ paise: Int) -> String {
        (Decimal(paise) / 100).formatted(
            .currency(code: "INR").locale(Locale(identifier: "en_IN")))
    }
    static func parsePaise(_ text: String) -> Int? {
        let pattern = #"^[0-9]+(\.[0-9]{1,2})?$"#
        guard text.range(of: pattern, options: .regularExpression) != nil
        else { return nil }
        let parts = text.split(separator: ".", omittingEmptySubsequences: false)
        guard let rupees = Int(parts[0]) else { return nil }
        let frac = parts.count > 1 ? String(parts[1]) : ""
        let padded = frac.padding(toLength: 2, withPad: "0", startingAt: 0)
        guard let paise = Int(padded) else { return nil }
        let (r100, o1) = rupees.multipliedReportingOverflow(by: 100)
        guard !o1 else { return nil }
        let (total, o2) = r100.addingReportingOverflow(paise)
        return o2 ? nil : total
    }
}

// MARK: - Dashboard (state owner)

struct ContentView: View {
    @State private var balancePaise = 2_500_000
    @State private var transactions: [Transaction] = [
        Transaction(title: "Coffee Shop", amountPaise: -25_000, date: .now),
        Transaction(title: "Electricity Bill", amountPaise: -120_000, date: .now),
        Transaction(title: "Salary Credit", amountPaise: 4_500_000, date: .now),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    BalanceCard(balancePaise: balancePaise)
                    BalanceEditor(balancePaise: $balancePaise)

                    NavigationLink {
                        PaymentScreen(availableBalancePaise: balancePaise,
                                      onSend: sendDemoPayment)
                    } label: {
                        navTile("Send Money", "arrow.up.right")
                    }

                    NavigationLink {
                        HistoryScreen(transactions: transactions)
                    } label: {
                        navTile("Transaction History", "clock")
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Transactions").font(.headline)
                        ForEach(transactions.prefix(3)) { t in
                            TransactionRow(transaction: t)
                            Divider()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
            }
            .navigationTitle("NPay")
        }
    }

    private func navTile(_ title: String, _ symbol: String) -> some View {
        Label(title, systemImage: symbol)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }

    private func sendDemoPayment(to recipient: String, amountPaise: Int) -> Bool {
        let name = recipient.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, amountPaise > 0, amountPaise <= balancePaise else { return false }
        balancePaise -= amountPaise
        transactions.insert(
            Transaction(title: "Sent to \(name)", amountPaise: -amountPaise, date: .now), at: 0)
        return true
    }
}

// MARK: - Screens

struct PaymentScreen: View {
    let availableBalancePaise: Int
    let onSend: (String, Int) -> Bool

    @State private var recipient = ""
    @State private var amountText = ""
    @State private var showSuccess = false
    @FocusState private var focusedField: Field?
    @Environment(\.dismiss) private var dismiss

    enum Field: Hashable { case recipient, amount }

    private var parsedAmount: Int? { Money.parsePaise(amountText) }
    private var isValid: Bool {
        !recipient.trimmingCharacters(in: .whitespaces).isEmpty
        && (parsedAmount.map { $0 > 0 && $0 <= availableBalancePaise } ?? false)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Send Money").font(.title.bold())
                Text("Available: \(Money.display(availableBalancePaise))")
                    .foregroundStyle(.secondary)

                TextField("Recipient ID", text: $recipient)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .recipient)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .amount }

                TextField("Amount (₹)", text: $amountText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .amount)

                if !amountText.isEmpty && !isValid {
                    Text("Enter a valid amount within your balance.")
                        .font(.caption).foregroundStyle(.red)
                }

                Button("Send Demo Payment") {
                    guard let amount = parsedAmount else { return }
                    if onSend(recipient, amount) {
                        focusedField = nil
                        showSuccess = true
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
            }
            .padding()
        }
        .navigationTitle("Send Money")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Demo Payment Successful", isPresented: $showSuccess) {
            Button("Done") { dismiss() }
        } message: {
            Text("Your simulated payment was recorded.")
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
            }
        }
    }
}

struct HistoryScreen: View {
    let transactions: [Transaction]
    var body: some View {
        List(transactions) { TransactionRow(transaction: $0) }
            .navigationTitle("History")
    }
}

// MARK: - Components

struct BalanceCard: View {
    let balancePaise: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available Balance").font(.subheadline)
            Text(Money.display(balancePaise)).font(.largeTitle.bold())
            Text("NPay Demo Account").font(.caption)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(.blue, in: RoundedRectangle(cornerRadius: 20))
    }
}

struct BalanceEditor: View {
    @Binding var balancePaise: Int
    var body: some View {
        VStack(spacing: 12) {
            Text("Demo Balance Editor")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 12) {
                Button("− ₹1,000") { balancePaise = max(0, balancePaise - 100_000) }
                    .buttonStyle(.bordered)
                Button("+ ₹1,000") { balancePaise += 100_000 }
                    .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: transaction.amountPaise >= 0 ? "arrow.down.left" : "arrow.up.right")
                .font(.title2)
                .foregroundStyle(transaction.amountPaise >= 0 ? .green : .blue)
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.title).font(.headline)
                Text(transaction.date, format: .dateTime.day().month(.abbreviated))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(Money.display(transaction.amountPaise))
                .font(.subheadline.bold())
                .foregroundStyle(transaction.amountPaise >= 0 ? .green : .primary)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ContentView()
}
// ↑↑↑ This real ContentView IS the complete Lesson 3.1 code (so far). ↑↑↑
```
