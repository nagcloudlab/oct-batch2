# Lesson 3.2 — Programmatic Navigation with Typed Routes

*Unit 3 · Navigation, Architecture & Polish*

---

## Concept 1 of 6 — navigation AS STATE

> 🔑 Programmatic navigation = drive a navigation-path STATE from code; SwiftUI renders the screens the path describes.  

**Key points**

- NavigationLink is DESTINATION-based: "when tapped, go here." It can't express "go to Success *after* the payment succeeds."
- Tempting hack: a pile of booleans (showPayment, showSuccess…) driving navigation.
- The fix: model navigation AS STATE. Keep an ARRAY of routes that describes "which screens are pushed," and MUTATE it from code.
- The building blocks we'll assemble this lesson:
    - `1. a typed Route enum               (Concept 2)`
    - `2. NavigationStack(path: $path)     (Concept 3)`
    - `3. .navigationDestination(for:)     (Concept 4)`
    - `4. path.append / removeLast / removeAll  (Concept 5)`

**Complete runnable file (the idea, minimal)**

```swift
import SwiftUI

struct ContentView: View {
    // The path IS the navigation state. Empty = just the root.
    @State private var path: [String] = []
    var body: some View {
        NavigationStack(path: $path) {
            Button("Go to Detail (from code)") {
                path.append("detail")      // navigate by MUTATING state
            }
            .navigationTitle("Home")
            .navigationDestination(for: String.self) { value in
                Text("Detail: \(value)").navigationTitle("Detail")
            }
        }
    }
}

#Preview { ContentView() }
```

---

## Concept 2 of 6 — the typed route enum

> 🔑 Model destinations as a Hashable enum with associated values; routes carry a stable ID, not a whole object.  

**Key points**

- It's a plain Swift enum with ASSOCIATED VALUES (Unit 1).
- Must be Hashable — the navigation path stores route values and needs to identify/compare them.
- TYPED = compiler-checked. You can only navigate to cases that exist; a switch over the routes is exhaustive (Concept 4).
- Carry an ID, not the whole object: The route NAMES the destination + the minimum data to resolve it; the screen looks up the real object from the source of truth.

**Complete runnable file**

```swift
import SwiftUI

enum NPayRoute: Hashable {
    case payment
    case history
    case success(transactionID: UUID)
}

struct ContentView: View {
    @State private var path: [NPayRoute] = []
    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 16) {
                Button("Payment") { path.append(.payment) }
                Button("History") { path.append(.history) }
                Button("Success") { path.append(.success(transactionID: UUID())) }
            }
            .navigationTitle("Routes")
            .navigationDestination(for: NPayRoute.self) { route in
                Text("Route: \(String(describing: route))")
            }
        }
    }
}

#Preview { ContentView() }
```

---

## Concept 3 of 6 — the path array = the nav stack

> 🔑 The bound path array IS the stack: [] = root, append = push, last element = top screen; Back edits the array for you.  

**Key points**

- $path BINDS the array to the stack (two-way, like any Binding).
- The array = the screens ABOVE the root, in order: index 0 is the first pushed screen, the LAST element is the top (visible) screen.
- Because it's a real array, you navigate with array operations.
- Two-way in action: tap the system Back button and SwiftUI removes the last element FOR you — the array always mirrors what's on screen.
- You can even LAUNCH deep: seed path = [.payment, .history] and the app opens straight into History with Payment behind it.

**Complete runnable file**

```swift
import SwiftUI

enum NPayRoute: Hashable { case payment, history, success(transactionID: UUID) }

struct ContentView: View {
    // Seeded two-deep on purpose: launches into History.
    @State private var path: [NPayRoute] = [.payment, .history]
    var body: some View {
        NavigationStack(path: $path) {
            Text("Dashboard (root)")
                .navigationTitle("NPay")
                .navigationDestination(for: NPayRoute.self) { route in
                    Text("\(String(describing: route)) — depth \(path.count)")
                }
        }
    }
}

#Preview { ContentView() }
```

---

## Concept 4 of 6 — .navigationDestination(for:)

> 🔑 .navigationDestination(for: Route.self) maps each route to a screen via one exhaustive switch; register it once in the stack.  

**Key points**

- "for: NPayRoute.self" = "whenever a value of THIS type is in the path, build its screen with this closure." SwiftUI calls it as each route becomes active.
- The switch is EXHAUSTIVE (typed routes payoff) — the compiler forces a case for every route, so you can't forget a screen.
- Place it ONCE, on a view INSIDE the NavigationStack (commonly on the root content).
- Separation: the path says WHERE to go (data); the destination closure says WHAT to show (views).
- You can register more than one — e.g. a second .navigationDestination(for: Transaction.self) { ... } — and SwiftUI picks the handler whose TYPE matches the pushed value.

**Complete runnable file**

```swift
import SwiftUI

enum NPayRoute: Hashable { case payment, history, success(transactionID: UUID) }

struct ContentView: View {
    @State private var path: [NPayRoute] = []
    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 16) {
                Button("Payment") { path.append(.payment) }
                Button("History") { path.append(.history) }
            }
            .navigationTitle("NPay")
            .navigationDestination(for: NPayRoute.self) { route in
                switch route {
                case .payment:            Text("Payment Screen")
                case .history:            Text("History Screen")
                case .success(let id):    Text("Success: \(id.uuidString)")
                }
            }
        }
    }
}

#Preview { ContentView() }
```

---

## Concept 5 of 6 — push/pop + auto-navigate on success

> 🔑 append = push, removeLast = pop (guard empty!), removeAll = home; return a UUID from logic and append a route to navigate.  

**Key points**

- Safety: removeLast() on an EMPTY array CRASHES.
- The whole point of this lesson — auto-navigate AFTER logic. Make the payment RETURN the new transaction's id, then push the success route only on success:
    - No NavigationLink involved — the APP decided to navigate.
- The Success screen returns home by CLEARING the path: and hides its Back button (.navigationBarBackButtonHidden()) so the only way out is "Back to Dashboard".
- Why return a UUID (not Bool)? The payment logic produces a MEANINGFUL result (which transaction), navigation reacts to it, and the logic stays ignorant of SwiftUI screens.

**Complete runnable file:  (mini end-to-end flow)**

```swift
import SwiftUI

enum NPayRoute: Hashable { case success(transactionID: UUID) }

struct ContentView: View {
    @State private var path: [NPayRoute] = []
    @State private var balancePaise = 2_500_000
    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 16) {
                Text("Balance: \(balancePaise) paise")
                Button("Pay ₹100 (auto-navigate on success)") {
                    if let id = pay(amountPaise: 10_000) {
                        path.append(.success(transactionID: id))  // from code
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .navigationTitle("NPay")
            .navigationDestination(for: NPayRoute.self) { route in
                switch route {
                case .success(let id):
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.largeTitle).foregroundStyle(.green)
                        Text("Paid! \(id.uuidString)").font(.caption)
                        Button("Back to Dashboard") { path.removeAll() }
                    }
                    .navigationBarBackButtonHidden()
                }
            }
        }
    }
    func pay(amountPaise: Int) -> UUID? {
        guard amountPaise > 0, amountPaise <= balancePaise else { return nil }
        balancePaise -= amountPaise
        return UUID()
    }
}

#Preview { ContentView() }
```

---

## Concept 6 of 6 — wire the real NPay (Milestone)

> ⭐️ MILESTONE 3.2 — NPay navigates by STATE: a successful payment auto-routes to a receipt, and "Back to Dashboard" clears the path.  
> 🔑 Typed route enum + NavigationStack(path:) + one destination switch + append/removeAll = full programmatic navigation.  

**Key points**

- ContentView owns @State path + balancePaise + transactions, and ONE navigationDestination switch for the whole app.
- Dashboard "Send Money"/"History" are now BUTTONS that append routes (path.append(.payment)) — not NavigationLinks — so all navigation flows through the path.
- PaymentScreen's contract changes so navigation can react: On a successful send it calls onPaymentSuccess(id); the parent does path.append(.success(transactionID: id)).
- PaymentSuccessScreen gets the id + an onDone closure that does path.removeAll() → straight home, balance already updated.
- As navigation spans tabs/features, centralise it in a small @Observable Router that owns the path: Hold it with @State, bind via @Bindable, pass through the environment.

**Complete runnable file (the lesson's full app)**

```swift
import SwiftUI

// MARK: - Route, model, money

enum NPayRoute: Hashable {
    case payment
    case history
    case success(transactionID: UUID)
}

struct Transaction: Identifiable {
    let id: UUID
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
        guard text.range(of: pattern, options: .regularExpression) != nil else { return nil }
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

// MARK: - Dashboard (owns path + state)

struct ContentView: View {
    @State private var path: [NPayRoute] = []
    @State private var balancePaise = 2_500_000
    @State private var transactions: [Transaction] = [
        Transaction(id: UUID(), title: "Coffee Shop", amountPaise: -25_000, date: .now),
        Transaction(id: UUID(), title: "Electricity Bill", amountPaise: -120_000, date: .now),
        Transaction(id: UUID(), title: "Salary Credit", amountPaise: 4_500_000, date: .now),
    ]

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 24) {
                    BalanceCard(balancePaise: balancePaise)
                    BalanceEditor(balancePaise: $balancePaise)

                    Button { path.append(.payment) } label: {
                        navTile("Send Money", "arrow.up.right")
                    }
                    Button { path.append(.history) } label: {
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
            .navigationDestination(for: NPayRoute.self) { route in
                switch route {
                case .payment:
                    PaymentScreen(
                        availableBalancePaise: balancePaise,
                        onSend: sendDemoPayment,
                        onPaymentSuccess: { id in path.append(.success(transactionID: id)) }
                    )
                case .history:
                    HistoryScreen(transactions: transactions)
                case .success(let id):
                    PaymentSuccessScreen(transactionID: id) { path.removeAll() }
                }
            }
        }
    }

    private func navTile(_ title: String, _ symbol: String) -> some View {
        Label(title, systemImage: symbol)
            .frame(maxWidth: .infinity).padding()
            .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }

    // Returns the new transaction id on success (nil on failure).
    private func sendDemoPayment(to recipient: String, amountPaise: Int) -> UUID? {
        let name = recipient.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, amountPaise > 0, amountPaise <= balancePaise else { return nil }
        let id = UUID()
        balancePaise -= amountPaise
        transactions.insert(
            Transaction(id: id, title: "Sent to \(name)", amountPaise: -amountPaise, date: .now),
            at: 0)
        return id
    }
}

// MARK: - Screens

struct PaymentScreen: View {
    let availableBalancePaise: Int
    let onSend: (String, Int) -> UUID?
    let onPaymentSuccess: (UUID) -> Void

    @State private var recipient = ""
    @State private var amountText = ""
    @FocusState private var focusedField: Field?
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
                    if let id = onSend(recipient, amount) {   // success → a UUID
                        focusedField = nil
                        onPaymentSuccess(id)                  // ask parent to navigate
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
            }
            .padding()
        }
        .navigationTitle("Send Money")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
            }
        }
    }
}

struct PaymentSuccessScreen: View {
    let transactionID: UUID
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72)).foregroundStyle(.green)
            Text("Payment Recorded").font(.title.bold())
            Text("Your demo payment was successful.").foregroundStyle(.secondary)
            Text(transactionID.uuidString)
                .font(.caption2.monospaced()).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Back to Dashboard", action: onDone)
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("Payment Success")
        .navigationBarBackButtonHidden()
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
            Text("Demo Balance Editor").font(.headline)
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
// ↑↑↑ This real ContentView IS the complete Lesson 3.2 code. ↑↑↑
```
