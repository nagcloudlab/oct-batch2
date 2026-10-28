# Lesson 3.6 — Animations & Transitions

*Unit 3 · Navigation, Architecture & Polish*

---

## Concept 1 of 6 — withAnimation

> 🔑 withAnimation { change } animates the result of a state change; SwiftUI interpolates animatable properties for you.  

**Key points**

- Animation = HOW a visual value changes over TIME.
- withAnimation(_:) { stateChange } = EXPLICIT animation: "animate whatever this state change causes." Here toggling `expanded` changes the circle's frame → SwiftUI animates the size.
- KEY mental model (we prove it in Concept 5): the state changes ONCE to its target (expanded = true).
- (Static preview can't show motion — run in the Simulator and tap the button to see the circle grow/shrink smoothly.)

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    @State private var expanded = false
    var body: some View {
        VStack(spacing: 30) {
            Circle().fill(.blue)
                .frame(width: expanded ? 180 : 80, height: expanded ? 180 : 80)
            Button("Toggle Size") {
                withAnimation(.easeInOut(duration: 0.5)) { expanded.toggle() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview { ContentView() }
```

---

## Concept 2 of 6 — curves + implicit .animation

> 🔑 Curves set the feel (.linear/.easeInOut/.spring); attach via withAnimation (per event) or .animation(_:value:) (per value).  

**Key points**

- Which to use? - withAnimation: you control a specific event ("on this tap"). - .animation(_:value:): "whenever this value changes, animate"
- Always scope .animation to a specific `value:`.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    @State private var expanded = false
    var body: some View {
        VStack(spacing: 30) {
            // IMPLICIT: animates whenever `expanded` changes
            Circle().fill(.blue)
                .frame(width: expanded ? 180 : 80, height: expanded ? 180 : 80)
                .animation(.spring(response: 0.45, dampingFraction: 0.7),
                           value: expanded)
            Button("Toggle") { expanded.toggle() }   // no withAnimation
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview { ContentView() }
```

---

## Concept 3 of 6 — transitions (enter / leave)

> 🔑 Transitions animate a view ENTERING/LEAVING the hierarchy (driven by withAnimation on an if/condition); animations interpolate values that stay.  

**Key points**

- .transition(...) only fires when a view is INSERTED or REMOVED (here, by the `if` flipping).
- Common transitions (combine them with .combined(with:)):
    - `.opacity                 fade`
    - `.scale                   grow/shrink`
    - `.move(edge: .top)        slide in/out from an edge`
    - `.scale.combined(with: .opacity)   scale + fade (nice for success)`
- IDENTITY matters (ties to 2.10 / 3.5): a transition happens only when SwiftUI sees a view ENTER or LEAVE.
- Asymmetric in/out if you want:
    - .transition(.asymmetric(insertion: .scale, removal: .opacity))

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    @State private var showSuccess = false
    var body: some View {
        VStack(spacing: 30) {
            if showSuccess {
                Label("Payment Successful", systemImage: "checkmark.circle.fill")
                    .font(.title2).foregroundStyle(.green)
                    .transition(.scale.combined(with: .opacity))
            }
            Button("Toggle success") {
                withAnimation(.spring) { showSuccess.toggle() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview { ContentView() }
```

---

## Concept 4 of 6 — numeric text + animated insertion

> 🔑 .contentTransition(.numericText()) rolls changing digits; withAnimation around an insert animates the new row (needs stable ids).  

**Key points**

- STABLE IDENTITY is required (2.10): SwiftUI animates insertion only if existing rows keep their ids (so it knows which row is NEW).
- The state updates IMMEDIATELY (balance is already correct); the animation just presents it.

**Complete runnable file**

```swift
import SwiftUI

enum Money { static func display(_ p: Int) -> String {
    (Decimal(p)/100).formatted(.currency(code:"INR").locale(.init(identifier:"en_IN"))) } }

struct Row: Identifiable { let id = UUID(); let title: String }

struct ContentView: View {
    @State private var balancePaise = 2_500_000
    @State private var rows = [Row(title: "Coffee Shop")]
    var body: some View {
        VStack(spacing: 24) {
            Text(Money.display(balancePaise))
                .font(.largeTitle.bold())
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.4), value: balancePaise)

            Button("Spend ₹1,000 + add row") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    balancePaise -= 100_000
                    rows.insert(Row(title: "Payment"), at: 0)
                }
            }
            .buttonStyle(.borderedProminent)

            ForEach(rows) { r in
                Text(r.title).frame(maxWidth: .infinity).padding(8)
                    .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding()
    }
}

#Preview { ContentView() }
```

---

## Concept 5 of 6 — interpolation & Animatable

> 🔑 State flips once; SwiftUI interpolates animatableData of Animatable types to render the in-between frames.  

**Key points**

- Your STATE changes ONCE to the target. SwiftUI interpolates the PRESENTATION of animatable properties over time: e.g. width 80 → 180, at t = 0.5 → 80 + (180−80)·0.5 = 130.
- SwiftUI knows WHAT can interpolate via the Animatable protocol: a type exposes `animatableData` (a number or vector) that can be blended between two values.
- Build one: AnimatedNumber counts a value up/down smoothly by exposing `animatableData`.
- INTERRUPTION: tap again mid-animation and SwiftUI RETARGETS smoothly from the current presentation to the new value — no jump.
- Use `Animatable` directly (the older `AnimatableModifier` is deprecated).

**Complete runnable file**

```swift
import SwiftUI

struct AnimatedNumber: Animatable, View {
    var value: Double
    nonisolated var animatableData: Double {
        get { value } set { value = newValue }
    }
    var body: some View {
        Text(value, format: .number.precision(.fractionLength(0)))
            .font(.largeTitle.bold()).foregroundStyle(.blue)
    }
}

struct ContentView: View {
    @State private var amount: Double = 25000
    var body: some View {
        VStack(spacing: 24) {
            AnimatedNumber(value: amount)
                .animation(.easeInOut(duration: 0.8), value: amount)
            Button("Spend 1,500 (watch it count down)") { amount -= 1500 }
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview { ContentView() }
```

---

## Concept 6 of 6 — Reduce Motion + integrate (Milestone)

> ⭐️ MILESTONE 3.6 — NPay feels alive: the balance rolls on change and the success checkmark springs in (or appears instantly for Reduce Motion users).  
> 🔑 .contentTransition(.numericText()) for the balance; a spring + .transition for success, gated on accessibilityReduceMotion.  

**Key points**

- BalanceCard — rolling balance.
- PaymentSuccessScreen — spring-in checkmark, but honour Reduce Motion (some users find motion uncomfortable/nauseating)
- Everything else unchanged from 3.5 (router, store, draft, tabs).
- Reminder: animation is PRESENTATION. The balance/transactions are already correct the instant the payment records; motion just communicates the change.

**Complete runnable file (the lesson's full app)**

```swift
import SwiftUI

// MARK: - Models

struct Transaction: Identifiable {
    let id: UUID
    let title: String
    let amountPaise: Int
    let date: Date
}

struct PaymentDraft { var recipient = ""; var amountText = "" }

struct PaymentReview: Identifiable {
    let id = UUID()
    let recipient: String
    let amountPaise: Int
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

// MARK: - Router + Store

enum NPayTab: Hashable { case home, payments, history, profile }

enum NPayRoute: Hashable {
    case accountDetails
    case paymentSuccess(UUID)
    case transactionDetails(UUID)
    case settings
}

@MainActor @Observable
final class NPayRouter {
    var selectedTab: NPayTab = .home
    var homePath: [NPayRoute] = []
    var paymentsPath: [NPayRoute] = []
    var historyPath: [NPayRoute] = []
    var profilePath: [NPayRoute] = []

    func select(_ tab: NPayTab) { selectedTab = tab }
    func showPaymentSuccess(_ id: UUID) {
        selectedTab = .payments
        paymentsPath.append(.paymentSuccess(id))
    }
    func returnHome() { paymentsPath.removeAll(); selectedTab = .home }
}

@MainActor @Observable
final class NPayStore {
    var balancePaise = 2_500_000
    var transactions: [Transaction] = [
        Transaction(id: UUID(), title: "Coffee Shop", amountPaise: -25_000, date: .now),
        Transaction(id: UUID(), title: "Electricity Bill", amountPaise: -120_000, date: .now),
        Transaction(id: UUID(), title: "Salary Credit", amountPaise: 4_500_000, date: .now),
    ]
    var paymentDraft = PaymentDraft()

    func recordDemoPayment(recipient: String, amountPaise: Int) -> UUID? {
        let name = recipient.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, amountPaise > 0, amountPaise <= balancePaise else { return nil }
        let id = UUID()
        balancePaise -= amountPaise
        transactions.insert(
            Transaction(id: id, title: "Sent to \(name)", amountPaise: -amountPaise, date: .now),
            at: 0)
        return id
    }
    func clearPaymentDraft() { paymentDraft = PaymentDraft() }
}

// MARK: - Root

struct ContentView: View {
    @State private var router = NPayRouter()
    @State private var store = NPayStore()

    var body: some View {
        @Bindable var router = router
        TabView(selection: $router.selectedTab) {
            NavigationStack(path: $router.homePath) {
                HomeScreen(store: store, router: router)
                    .navigationDestination(for: NPayRoute.self, destination: destination)
            }
            .tabItem { Label("Home", systemImage: "house") }
            .tag(NPayTab.home)

            NavigationStack(path: $router.paymentsPath) {
                PaymentsScreen(store: store, router: router)
                    .navigationDestination(for: NPayRoute.self, destination: destination)
            }
            .tabItem { Label("Payments", systemImage: "arrow.up.right") }
            .tag(NPayTab.payments)

            NavigationStack(path: $router.historyPath) {
                HistoryScreen(transactions: store.transactions)
                    .navigationDestination(for: NPayRoute.self, destination: destination)
            }
            .tabItem { Label("History", systemImage: "clock") }
            .tag(NPayTab.history)

            NavigationStack(path: $router.profilePath) {
                ProfileScreen()
                    .navigationDestination(for: NPayRoute.self, destination: destination)
            }
            .tabItem { Label("Profile", systemImage: "person") }
            .tag(NPayTab.profile)
        }
    }

    @ViewBuilder
    private func destination(_ route: NPayRoute) -> some View {
        switch route {
        case .accountDetails:
            AccountDetailsScreen(balancePaise: store.balancePaise)
        case .paymentSuccess(let id):
            PaymentSuccessScreen(transactionID: id) { router.returnHome() }
        case .transactionDetails(let id):
            if let txn = store.transactions.first(where: { $0.id == id }) {
                TransactionDetailScreen(transaction: txn)
            } else {
                ContentUnavailableView("Transaction not found", systemImage: "questionmark.circle")
            }
        case .settings:
            SettingsScreen()
        }
    }
}

// MARK: - Payments

struct PaymentsScreen: View {
    @Bindable var store: NPayStore
    let router: NPayRouter

    @State private var review: PaymentReview?
    @State private var pendingSuccessID: UUID?
    @State private var paymentFailed = false
    @State private var showFailure = false
    @State private var confirmDiscard = false
    @FocusState private var focusedField: Field?
    enum Field: Hashable { case recipient, amount }

    private var parsedAmount: Int? { Money.parsePaise(store.paymentDraft.amountText) }
    private var isValid: Bool {
        !store.paymentDraft.recipient.trimmingCharacters(in: .whitespaces).isEmpty
        && (parsedAmount.map { $0 > 0 && $0 <= store.balancePaise } ?? false)
    }
    private var draftIsEmpty: Bool {
        store.paymentDraft.recipient.isEmpty && store.paymentDraft.amountText.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Available: \(Money.display(store.balancePaise))")
                    .foregroundStyle(.secondary)

                TextField("Recipient ID", text: $store.paymentDraft.recipient)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .recipient)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .amount }

                TextField("Amount (₹)", text: $store.paymentDraft.amountText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .amount)

                if !store.paymentDraft.amountText.isEmpty && !isValid {
                    Text("Enter a valid amount within your balance.")
                        .font(.caption).foregroundStyle(.red)
                }

                Button("Review Payment") {
                    guard let amount = parsedAmount else { return }
                    focusedField = nil
                    review = PaymentReview(recipient: store.paymentDraft.recipient, amountPaise: amount)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)

                Button("Discard Draft", role: .destructive) { confirmDiscard = true }
                    .disabled(draftIsEmpty)
            }
            .padding()
        }
        .navigationTitle("Payments")
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
            }
        }
        .sheet(item: $review, onDismiss: {
            if let id = pendingSuccessID {
                pendingSuccessID = nil
                router.showPaymentSuccess(id)
            } else if paymentFailed {
                paymentFailed = false
                showFailure = true
            }
        }) { review in
            PaymentReviewSheet(review: review) {
                if let id = store.recordDemoPayment(
                    recipient: review.recipient, amountPaise: review.amountPaise) {
                    store.clearPaymentDraft()
                    pendingSuccessID = id
                } else {
                    paymentFailed = true
                }
                self.review = nil
            }
        }
        .alert("Payment not recorded", isPresented: $showFailure) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The amount is no longer within your available balance.")
        }
        .alert("Discard payment draft?", isPresented: $confirmDiscard) {
            Button("Discard", role: .destructive) { store.clearPaymentDraft() }
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct PaymentReviewSheet: View {
    let review: PaymentReview
    let onConfirm: () -> Void
    @State private var isProcessing = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Review Payment").font(.title.bold())
            LabeledContent("Recipient", value: review.recipient)
            LabeledContent("Amount", value: Money.display(review.amountPaise))
            Button("Confirm Demo Payment") {
                guard !isProcessing else { return }
                isProcessing = true
                onConfirm()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isProcessing)
            Button("Edit Details") { dismiss() }.buttonStyle(.bordered)
        }
        .padding()
        .presentationDetents([.medium, .large])
        .interactiveDismissDisabled(isProcessing)
    }
}

// MARK: - Success (animated, Reduce-Motion aware)

struct PaymentSuccessScreen: View {
    let transactionID: UUID
    let onDone: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showContent = false

    var body: some View {
        VStack(spacing: 24) {
            if showContent {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80)).foregroundStyle(.green)
                    .transition(.scale.combined(with: .opacity))
            }
            Text("Payment Recorded").font(.title.bold())
            Text("Your demo payment was successful.").foregroundStyle(.secondary)
            Text(transactionID.uuidString)
                .font(.caption2.monospaced()).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Back to Dashboard", action: onDone).buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("Payment Success")
        .navigationBarBackButtonHidden()
        .onAppear {
            if reduceMotion {
                showContent = true                       // no entrance animation
            } else {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                    showContent = true
                }
            }
        }
    }
}

// MARK: - Other screens

struct HomeScreen: View {
    let store: NPayStore
    let router: NPayRouter
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                BalanceCard(balancePaise: store.balancePaise)
                HStack(spacing: 12) {
                    Button { router.select(.payments) } label: { tile("Send Money", "arrow.up.right") }
                    Button { router.select(.history) }  label: { tile("History", "clock") }
                }
                NavigationLink(value: NPayRoute.accountDetails) {
                    Label("Account Details", systemImage: "person.text.rectangle")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Transactions").font(.headline)
                    ForEach(store.transactions.prefix(3)) { t in
                        TransactionRow(transaction: t); Divider()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
        .navigationTitle("NPay")
    }
    private func tile(_ title: String, _ symbol: String) -> some View {
        Label(title, systemImage: symbol)
            .frame(maxWidth: .infinity).padding()
            .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct AccountDetailsScreen: View {
    let balancePaise: Int
    var body: some View {
        List {
            LabeledContent("Account", value: "NPay Demo Account")
            LabeledContent("Holder", value: "NPay Demo User")
            LabeledContent("Available", value: Money.display(balancePaise))
        }
        .navigationTitle("Account Details")
    }
}

struct HistoryScreen: View {
    let transactions: [Transaction]
    var body: some View {
        List(transactions) { t in
            NavigationLink(value: NPayRoute.transactionDetails(t.id)) {
                TransactionRow(transaction: t)
            }
        }
        .navigationTitle("History")
    }
}

struct TransactionDetailScreen: View {
    let transaction: Transaction
    var body: some View {
        List {
            LabeledContent("Title", value: transaction.title)
            LabeledContent("Amount", value: Money.display(transaction.amountPaise))
            LabeledContent("Date",
                value: transaction.date.formatted(date: .abbreviated, time: .shortened))
            LabeledContent("ID") { Text(transaction.id.uuidString).font(.caption2.monospaced()) }
        }
        .navigationTitle("Transaction")
    }
}

struct ProfileScreen: View {
    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 48)).foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("NPay Demo User").font(.headline)
                        Text("Account settings and preferences")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            NavigationLink(value: NPayRoute.settings) { Label("Settings", systemImage: "gearshape") }
        }
        .navigationTitle("Profile")
    }
}

struct SettingsScreen: View {
    @State private var notifications = true
    var body: some View {
        List {
            Toggle("Payment notifications", isOn: $notifications)
            LabeledContent("Version", value: "Lesson 3.6 demo")
        }
        .navigationTitle("Settings")
    }
}

// MARK: - Components

struct BalanceCard: View {
    let balancePaise: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available Balance").font(.subheadline)
            Text(Money.display(balancePaise))
                .font(.largeTitle.bold())
                .contentTransition(.numericText())                 // rolling digits
                .animation(.easeInOut(duration: 0.4), value: balancePaise)
            Text("NPay Demo Account").font(.caption)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(.blue, in: RoundedRectangle(cornerRadius: 20))
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
// ↑↑↑ This real ContentView IS the complete Lesson 3.6 code (so far). ↑↑↑
```
