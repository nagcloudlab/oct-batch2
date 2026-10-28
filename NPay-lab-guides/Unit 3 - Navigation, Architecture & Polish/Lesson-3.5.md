# Lesson 3.5 — Preserving State — Drafts & @Bindable

*Unit 3 · Navigation, Architecture & Polish*

---

## Concept 1 of 6 — local state can be lost

> 🔑 Local @State can reset when a screen's identity changes; preservation is about OWNERSHIP, not visibility.  

**Key points**

- Right now the draft (recipient, amountText) lives in PaymentsScreen's local @State. From Lesson 2.8 we know:
    - `stable identity → @State survives,`
    - `identity change / leaving the tree → @State RESETS.`
- A plain TabView switch usually PRESERVES a tab's local state.
- The principle: state preservation depends on OWNERSHIP & IDENTITY, not on whether a screen is currently visible.
- The plan (this lesson): move the draft OUT of PaymentsScreen and into the shared NPayStore (which the root owns).

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            PaymentsScreen()
                .tabItem { Label("Payments", systemImage: "arrow.up.right") }
            Text("History")
                .tabItem { Label("History", systemImage: "clock") }
        }
    }
}

// Draft in LOCAL @State — survives a normal tab switch,
// but is fragile against identity changes (Concept 2).
struct PaymentsScreen: View {
    @State private var recipient = ""
    @State private var amountText = ""
    var body: some View {
        VStack(spacing: 12) {
            TextField("Recipient", text: $recipient)
            TextField("Amount", text: $amountText)
        }
        .textFieldStyle(.roundedBorder).padding()
    }
}

#Preview { ContentView() }
```

---

## Concept 2 of 6 — view identity vs value

> 🔑 State is tied to IDENTITY, not the struct value; changing .id resets local @State — so keep important data in a stabler owner.  

**Key points**

- Recreating the struct value does NOT reset @State.
- Demo: type into the editor, tap "Replace View Identity" (sets identity = UUID()) → the field CLEARS.
- Warning (from 2.6/2.8): never write .id(UUID()) INLINE in body.
- The takeaway that motivates the fix: if the draft lived OUTSIDE the editor (in a longer-lived owner), an identity reset of the editor wouldn't touch it.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    @State private var identity = UUID()
    var body: some View {
        VStack(spacing: 20) {
            DraftEditor().id(identity)       // identity change → reset
            Button("Replace View Identity") { identity = UUID() }
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct DraftEditor: View {
    @State private var recipient = ""       // LOCAL state
    var body: some View {
        VStack {
            TextField("Recipient", text: $recipient).textFieldStyle(.roundedBorder)
            Text("Current: \(recipient)")
        }
    }
}

#Preview { ContentView() }
```

---

## Concept 3 of 6 — a draft model in the shared store

> 🔑 Model the draft as a struct, store it in the shared @Observable store → it survives any screen identity change (lift state up).  

**Key points**

- A DRAFT = incomplete, editable user input. Keep amountText as a String (mid-typing isn't a valid number yet).
- Put the draft on the shared store (owned by the root), so it outlives any single screen:
    - @MainActor @Observable
    - }
- Because NPayRootView owns the store with @State, the draft lives for the app's lifetime — immune to a screen being re-pushed, re-presented, hidden by an if/else, or given a new .id.
- "Recreate the child" proves it: if the editor's identity resets but the value lives in the STORE, the text stays (demo below).
- Don't dump everything in the store. Shared data (balance, txns, draft) → store.

**Complete runnable file**

```swift
import SwiftUI

struct PaymentDraft { var recipient = ""; var amountText = "" }

@MainActor @Observable
final class NPayStore {
    var paymentDraft = PaymentDraft()
    func clearPaymentDraft() { paymentDraft = PaymentDraft() }
}

struct ContentView: View {
    @State private var store = NPayStore()     // owns the draft
    @State private var identity = UUID()
    var body: some View {
        VStack(spacing: 20) {
            DraftChild(store: store).id(identity)   // reset the CHILD…
            Button("Recreate Child Identity") { identity = UUID() }
            Text("Store still has: \(store.paymentDraft.recipient)") // …value stays
        }
        .padding()
    }
}

struct DraftChild: View {
    @Bindable var store: NPayStore
    var body: some View {
        TextField("Recipient", text: $store.paymentDraft.recipient)
            .textFieldStyle(.roundedBorder)
    }
}

#Preview { ContentView() }
```

---

## Concept 4 of 6 — editing via @Bindable + clear rules

> 🔑 @Bindable binds fields to the shared draft (persists across navigation); clear it only on success or explicit discard.  

**Key points**

- @Bindable gives you $ bindings INTO an @Observable object's mutable properties — even nested ones ($store.paymentDraft.recipient).
- Now the fields read/write the store's draft directly, so it persists across tab switches, sheet dismissals, navigation — whatever happens to PaymentsScreen's identity.
- CLEAR RULES — be explicit about lifetime:
    - preserve on: tab switch, navigating away, sheet DISMISS
    - `clear on:    a SUCCESSFUL payment, or explicit "Discard"`
- Why NOT clear on sheet dismiss? Because dismiss often means "let me fix the amount" — wiping the draft would lose good input.
- Keep the editable draft and the thing being reviewed separate.

**Complete runnable file**

```swift
import SwiftUI

struct PaymentDraft { var recipient = ""; var amountText = "" }

@MainActor @Observable
final class NPayStore {
    var paymentDraft = PaymentDraft()
    func clearPaymentDraft() { paymentDraft = PaymentDraft() }
}

struct ContentView: View {
    @State private var store = NPayStore()
    var body: some View {
        TabView {
            PaymentsScreen(store: store)
                .tabItem { Label("Payments", systemImage: "arrow.up.right") }
            Text("History").tabItem { Label("History", systemImage: "clock") }
        }
    }
}

struct PaymentsScreen: View {
    @Bindable var store: NPayStore
    var body: some View {
        VStack(spacing: 12) {
            TextField("Recipient", text: $store.paymentDraft.recipient)
            TextField("Amount (₹)", text: $store.paymentDraft.amountText)
            Button("Clear (discard)") { store.clearPaymentDraft() }
        }
        .textFieldStyle(.roundedBorder).padding()
    }
}

#Preview { ContentView() }
```

---

## Concept 5 of 6 — preservation vs persistence

> 🔑 Preservation = alive in memory (survives navigation, not quit); persistence = survives relaunch (disk). Pick owners by lifetime.  

**Key points**

- Our shared NPayStore draft is PRESERVED, not PERSISTED.
- The lifetime ladder (shortest → longest):
    - `@State (value)     — while the view's identity survives`
    - shared @Observable — while the store instance survives (our draft)
    - `@SceneStorage      — restores simple scene state across relaunch`
    - `@AppStorage        — persists simple prefs via UserDefaults`
    - `SwiftData          — persists structured records to disk`
- CHOOSING AN OWNER — "as local as possible, as shared as necessary":
    - `balance, transactions   → shared NPayStore`
    - `payment draft           → shared store (must outlive the screen)`
    - `review-sheet visibility → PaymentsScreen @State (screen-only)`
    - `focused text field      → PaymentsScreen @FocusState`
    - `selected tab / nav paths→ NPayRouter`
- Because the draft is shared, two screens binding to it edit the SAME value (live sync).

**Complete runnable file:  (illustrates the ladder)**

```swift
import SwiftUI

@MainActor @Observable final class DemoStore { var shared = "" }

struct ContentView: View {
    @State private var store = DemoStore()          // preserved in memory
    @AppStorage("nickname") private var nickname = ""// persisted to disk
    var body: some View {
        Form {
            TextField("Shared (preserved, lost on quit)",
                      text: Bindable(store).shared)
            TextField("Nickname (persisted across launches)",
                      text: $nickname)
        }
    }
}

#Preview { ContentView() }
```

---

## Concept 6 of 6 — integrate the draft (Milestone)

> ⭐️ MILESTONE 3.5 — NPay preserves the payment draft across tab switches, navigation and sheet dismissal; clears only on success or explicit discard.  
> 🔑 Editable draft on the shared store (@Bindable) + an immutable review snapshot; clear the draft only on success/discard.  

**Key points**

- NAME SPLIT (important): 3.4's review model and this editable input would both be "PaymentDraft" → "invalid redeclaration". So:
    - `PaymentDraft   — the EDITABLE input (recipient, amountText),` lives on the store, survives navigation.
    - `PaymentReview  — an IMMUTABLE snapshot captured when the sheet` opens (recipient, amountPaise), Identifiable.
- NPayStore now owns: balancePaise, transactions, paymentDraft, + recordDemoPayment(...) and clearPaymentDraft().
- PaymentsScreen is @Bindable var store — its TextFields bind to $store.paymentDraft.*, so the draft persists across tabs/sheets.
- Everything else (router, other screens, success flow, onDismiss coordination) is unchanged from 3.4.

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

// Editable, in-progress input (lives on the store, survives navigation).
struct PaymentDraft {
    var recipient: String = ""
    var amountText: String = ""
}

// Immutable snapshot of what the user is reviewing (presented in the sheet).
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
    var paymentDraft = PaymentDraft()            // ← preserved editable input

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

// MARK: - Payments (draft on the store + review snapshot)

struct PaymentsScreen: View {
    @Bindable var store: NPayStore               // bind to the shared draft
    let router: NPayRouter

    @State private var review: PaymentReview?     // sheet presentation (screen-local)
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
                    review = PaymentReview(recipient: store.paymentDraft.recipient,
                                           amountPaise: amount)   // immutable snapshot
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
                    store.clearPaymentDraft()      // recorded → draft is done
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

            Button("Edit Details") { dismiss() }
                .buttonStyle(.bordered)
        }
        .padding()
        .presentationDetents([.medium, .large])
        .interactiveDismissDisabled(isProcessing)
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

struct PaymentSuccessScreen: View {
    let transactionID: UUID
    let onDone: () -> Void
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72)).foregroundStyle(.green)
            Text("Payment Recorded").font(.title.bold())
            Text(transactionID.uuidString)
                .font(.caption2.monospaced()).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Back to Dashboard", action: onDone).buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("Payment Success")
        .navigationBarBackButtonHidden()
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
            NavigationLink(value: NPayRoute.settings) {
                Label("Settings", systemImage: "gearshape")
            }
        }
        .navigationTitle("Profile")
    }
}

struct SettingsScreen: View {
    @State private var notifications = true
    var body: some View {
        List {
            Toggle("Payment notifications", isOn: $notifications)
            LabeledContent("Version", value: "Lesson 3.5 demo")
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
            Text(Money.display(balancePaise)).font(.largeTitle.bold())
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
// ↑↑↑ This real ContentView IS the complete Lesson 3.5 code (so far). ↑↑↑
```
