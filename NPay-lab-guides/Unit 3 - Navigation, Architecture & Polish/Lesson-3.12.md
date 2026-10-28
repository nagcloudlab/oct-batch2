# Lesson 3.12 — Capstone — The Complete NPay Architecture

*Unit 3 · Navigation, Architecture & Polish*

---

## Concept 1 of 6 — the final architecture

> 🔑 Separate owners for separate concerns — data (Store), navigation (Router), config (Preferences) — composed and injected at the root.  

**Key points**

- THE key decision: navigation, application data, and appearance preferences have SEPARATE OWNERS.
- Consequences you must be able to state out loud:
    - – the ROUTER never deducts money
    - – the review SHEET never owns the balance
    - – the BALANCE CARD never processes a payment
    - One component, one job → low coupling, easy debugging.
- The root just COMPOSES and injects: @State owns each model; the models flow down (params or .environment).
- Why three objects instead of one mega-store? Different LIFETIMES and AUDIENCES: navigation is UI-session state, data is the domain, preferences are user config.
- This split is exactly what makes the Unit 4 MVVM refactor painless — each owner becomes (or feeds) a feature ViewModel / use case.

**Complete runnable file**

```swift
import SwiftUI

@MainActor @Observable final class NPayStore {        // DATA
    var balancePaise = 2_500_000
}
@MainActor @Observable final class NPayRouter {       // NAVIGATION
    var selectedTab = 0
}
@MainActor @Observable final class NPayPreferences {  // CONFIG
    var showDemoBadge = true
}

struct ContentView: View {                            // composition ROOT
    @State private var store = NPayStore()
    @State private var router = NPayRouter()
    @State private var preferences = NPayPreferences()
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("NPay — separate owners").font(.title2.bold())
            Label("NPayStore → balance, transactions, draft", systemImage: "banknote")
            Label("NPayRouter → tabs + navigation paths", systemImage: "map")
            Label("NPayPreferences → appearance + config", systemImage: "gearshape")
        }
        .environment(preferences)                      // config injected via environment
        .padding()
    }
}

#Preview { ContentView() }
```

---

## Concept 2 of 6 — trace one payment end-to-end

> 🔑 One payment flows input → draft (Store) → review (local) → confirm (Store deducts) → navigate (Router). Each step touches only its owner; the balance math lives in exactly one method.  

**Key points**

- The deduction lives in ONE place — NPayStore.confirm(...).
- Why does the DRAFT live in the store, not the screen? So it SURVIVES leaving the tab / dismissing review (Lesson 3.5).
- confirm() returning success/failure (not a bool scattered in the view) keeps the rule testable — the seed of a Unit 4 use case.

**Complete runnable file**

```swift
import SwiftUI

@MainActor @Observable
final class NPayStore {
    var balancePaise = 2_500_000
    var transactionCount = 3
    var draftAmount = ""                 // owned by the store → survives
    // The STORE owns the deduction; nothing else touches the balance.
    func confirm(amountPaise: Int) {
        guard amountPaise > 0, amountPaise <= balancePaise else { return }
        balancePaise -= amountPaise
        transactionCount += 1
        draftAmount = ""                 // cleared on success
    }
}

struct ContentView: View {
    @State private var store = NPayStore()
    @State private var showReview = false            // PRESENTATION state (local)
    private var amountPaise: Int { (Int(store.draftAmount) ?? 0) * 100 }
    var body: some View {
        @Bindable var store = store
        VStack(alignment: .leading, spacing: 16) {
            Text("Balance: ₹\(store.balancePaise / 100)").font(.title2.bold())
            TextField("Amount (₹)", text: $store.draftAmount)    // writes the draft
                .textFieldStyle(.roundedBorder).keyboardType(.numberPad)
            Button("Review Payment") { showReview = true }.disabled(amountPaise <= 0)
            Text("Transactions: \(store.transactionCount)").foregroundStyle(.secondary)
        }
        .padding()
        .sheet(isPresented: $showReview) {
            VStack(spacing: 20) {
                Text("Confirm ₹\(amountPaise / 100)?").font(.headline)
                Button("Confirm") { store.confirm(amountPaise: amountPaise); showReview = false }
                    .buttonStyle(.borderedProminent)
            }.padding()
        }
    }
}

#Preview { ContentView() }
// Enter 1500 → Review → Confirm: balance drops, count +1, draft clears.
```

---

## Concept 3 of 6 — the SwiftUI runtime (change STATE)

> 🔑 Mutate STATE; never hand-refresh a view. SwiftUI invalidates the dependents, re-evaluates their bodies, reconciles, and renders.  

**Key points**

- THE key principle — you NEVER write refreshBalanceCard().
    - `store.balancePaise += 50_000      // ← the ONLY thing you do`
- This is Observation (3.9/3.11) doing step 3: because views read specific properties, only the dependent bodies get invalidated — not the whole screen.
- Contrast UIKit: there you'd imperatively do label.text = "…" on every change and risk forgetting one.
- Corollary: body must be IDEMPOTENT & side-effect-free — it can run anytime, many times.

**Complete runnable file**

```swift
import SwiftUI

@MainActor @Observable
final class NPayStore { var balancePaise = 2_500_000 }

// Two independent views that both READ balance. We never tell them
// to refresh — changing state re-evaluates their bodies for us.
struct BalanceHeadline: View {
    let store: NPayStore
    var body: some View { Text("₹\(store.balancePaise / 100)").font(.largeTitle.bold()) }
}
struct BalanceFootnote: View {
    let store: NPayStore
    var body: some View { Text("Available: ₹\(store.balancePaise / 100)").foregroundStyle(.secondary) }
}

struct ContentView: View {
    @State private var store = NPayStore()
    var body: some View {
        VStack(spacing: 20) {
            BalanceHeadline(store: store)
            BalanceFootnote(store: store)
            Button("Receive ₹500") { store.balancePaise += 50_000 }   // change STATE only
        }
        .padding()
    }
}

#Preview { ContentView() }
// Tap "Receive ₹500": BOTH balance views update — no manual refresh.
```

---

## Concept 4 of 6 — state ownership (the core skill)

> 🔑 Own each value at the NARROWEST scope that fits its lifetime & sharing: local → @State, shared → @Observable owner, contextual → @Environment. Not everything belongs in the store.  

**Key points**

- Why NOT put everything in NPayStore? – a focus indicator doesn't need to be GLOBAL (local @State) – a balance shouldn't be DUPLICATED in four tabs (one shared owner) Over-sharing couples unrelated code; under-sharing loses data on dismissal.
- Decision guide:
    - `local & disposable      → @State in the view          (focus, sheet flag)`
    - `shared & long-lived     → an @Observable owner         (balance, draft)`
    - `child writes parent's   → pass a Binding / @Bindable   (amount field)`
    - `contextual, flows down  → @Environment                 (appearance)`
- LIFETIME drives ownership: ask "when must this value DIE?" Focus dies with the screen → local.
- This is literally the MVVM prep (Unit 4): the shared owners become ViewModels/use cases; the local state stays in the view.

**Complete runnable file**

```swift
import SwiftUI

@MainActor @Observable
final class NPayStore { var balancePaise = 2_500_000 }   // SHARED owner

struct ContentView: View {
    @State private var store = NPayStore()        // shared data
    @State private var showDetails = false        // LOCAL presentation state
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("₹\(store.balancePaise / 100)").font(.largeTitle.bold())  // shared
            Toggle("Show details", isOn: $showDetails)                     // local
            if showDetails {
                Text("Account: NPay Demo · Holder: Demo User")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}

#Preview { ContentView() }
// showDetails is LOCAL — it has no business in the shared store.
```

---

## Concept 5 of 6 — accessibility fixes + integration test

> 🔑 Verify the whole app against an acceptance checklist; money stays integer paise (2,500,000−150,050=2,349,950); fix the a11y gaps the checklist surfaces (real labels on inputs, hide decorative icons).  

**Key points**

- The acceptance list is executable intent: each item maps to a future XCUITest via the accessibilityIdentifiers from 3.10 (recipientField, amountField, sendButton, transactionList) — Unit 9.
- "Exactly one transaction" is why Confirm guards with isProcessing — idempotent money operations matter (double-tap, retries).

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    @State private var recipient = "ravi@npay"
    @State private var amountText = "1500.50"
    private let startPaise = 2_500_000
    private func paise(_ text: String) -> Int { Int(((Double(text) ?? 0) * 100).rounded()) }
    private func money(_ p: Int) -> String {
        (Decimal(p) / 100).formatted(.currency(code: "INR").locale(.init(identifier: "en_IN")))
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            TextField("Recipient ID", text: $recipient)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Recipient")             // 3.12 FIX
            TextField("Amount (₹)", text: $amountText)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Amount in rupees")      // 3.12 FIX
            Divider()
            LabeledContent("Starting", value: money(startPaise))
            LabeledContent("Payment",  value: "−" + money(paise(amountText)))
            LabeledContent("Expected", value: money(startPaise - paise(amountText)))
            HStack {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    .accessibilityHidden(true)               // 3.12 FIX
                Text("2,500,000 − 150,050 = 2,349,950 paise").font(.caption.monospaced())
            }
        }
        .padding()
    }
}

#Preview { ContentView() }
// Expected = ₹23,499.50, computed in integer paise.
```

---

## Concept 6 of 6 — MILESTONE — the complete, verified NPay

> ⭐️ MILESTONE 3.12 / UNIT 3 COMPLETE — a functional, accessible, localizable, performant multi-screen NPay, cleanly composed from separate owners, verified end to end. Next: Unit 4 — MVVM.  
> 🔑 Great SwiftUI apps are COMPOSED: separate owners for data/nav/config, state at the narrowest scope, a declarative runtime — verified against an acceptance checklist, ready to refactor into MVVM.  

**Complete runnable file (the lesson's full app)**

```swift
import SwiftUI

// MARK: - Accessibility identifiers (Lesson 3.10)

enum NPayAccessibilityID {
    static let balanceCard     = "npay.balanceCard"
    static let recipientField  = "npay.recipientField"
    static let amountField     = "npay.amountField"
    static let sendButton      = "npay.sendButton"
    static let transactionList = "npay.transactionList"
}

// MARK: - Preferences (shared UI config — Lesson 3.9)

enum NPayAppearance: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var colorScheme: ColorScheme? {
        switch self { case .system: nil; case .light: .light; case .dark: .dark }
    }
}

@MainActor @Observable
final class NPayPreferences {
    var appearance: NPayAppearance = .system
    var showDemoBadge = true
}

// MARK: - Design system

enum NPayTheme {
    enum Colors {
        static let primary = Color(red: 0.10, green: 0.34, blue: 0.65)
        static let success = Color.green
        static let cardBackground = Color.blue.opacity(0.06)
    }
    enum Spacing { static let small: CGFloat = 8; static let medium: CGFloat = 16; static let large: CGFloat = 24 }
    enum Radius { static let small: CGFloat = 10; static let card: CGFloat = 18 }
}

struct NPayButton: View {
    let title: String; let symbol: String?; let action: () -> Void
    init(_ title: String, symbol: String? = nil, action: @escaping () -> Void) {
        self.title = title; self.symbol = symbol; self.action = action
    }
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let symbol { Image(systemName: symbol) }
                Text(title)
            }
            .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 14)
        }
        .buttonStyle(.plain).foregroundStyle(.white)
        .background(NPayTheme.Colors.primary, in: RoundedRectangle(cornerRadius: NPayTheme.Radius.small))
    }
}

struct NPayCard<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        content
            .padding(NPayTheme.Spacing.medium).frame(maxWidth: .infinity)
            .background(NPayTheme.Colors.cardBackground, in: RoundedRectangle(cornerRadius: NPayTheme.Radius.card))
    }
}

struct NPaySectionHeader: View {
    let title: String; let actionTitle: String?; let action: (() -> Void)?
    var body: some View {
        HStack {
            Text(title).font(.headline).accessibilityAddTraits(.isHeader)
            Spacer()
            if let actionTitle, let action { Button(actionTitle, action: action).font(.subheadline) }
        }
    }
}

struct QuickAction: View {
    let symbol: String; let title: String; let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) { Image(systemName: symbol).font(.title2); Text(title).font(.caption) }
                .frame(maxWidth: .infinity).padding(.vertical, 14).contentShape(Rectangle())
        }
        .buttonStyle(.plain).foregroundStyle(NPayTheme.Colors.primary)
        .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct NPayQuickActions: View {
    let onSend: () -> Void; let onRequest: () -> Void; let onHistory: () -> Void
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) { actionViews }
            VStack(spacing: 12) { actionViews }
        }
    }
    @ViewBuilder private var actionViews: some View {
        QuickAction(symbol: "arrow.up.right", title: "Send", action: onSend)
        QuickAction(symbol: "arrow.down.left", title: "Request", action: onRequest)
        QuickAction(symbol: "clock", title: "History", action: onHistory)
    }
}

// MARK: - Models

struct Transaction: Identifiable {
    let id: UUID; let title: String; let amountPaise: Int; let date: Date
}
struct PaymentDraft { var recipient = ""; var amountText = "" }
struct PaymentReview: Identifiable { let id = UUID(); let recipient: String; let amountPaise: Int }

enum Money {
    static func display(_ paise: Int) -> String {
        (Decimal(paise) / 100).formatted(.currency(code: "INR").locale(Locale(identifier: "en_IN")))
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
    case appearance
}

@MainActor @Observable
final class NPayRouter {
    var selectedTab: NPayTab = .home
    var homePath: [NPayRoute] = []
    var paymentsPath: [NPayRoute] = []
    var historyPath: [NPayRoute] = []
    var profilePath: [NPayRoute] = []
    func select(_ tab: NPayTab) { selectedTab = tab }
    func showPaymentSuccess(_ id: UUID) { selectedTab = .payments; paymentsPath.append(.paymentSuccess(id)) }
    func returnHome() { paymentsPath.removeAll(); selectedTab = .home }
}

@MainActor @Observable
final class NPayStore {
    var balancePaise = 2_500_000
    var transactions: [Transaction] = [
        Transaction(id: UUID(), title: "Coffee Shop", amountPaise: -25_000, date: .now),
        Transaction(id: UUID(), title: "Electricity Bill", amountPaise: -120_000, date: .now),
        Transaction(id: UUID(), title: "Coffee Beans Co", amountPaise: -45_000, date: .now),
        Transaction(id: UUID(), title: "Salary Credit", amountPaise: 4_500_000, date: .now),
    ]
    var paymentDraft = PaymentDraft()
    func recordDemoPayment(recipient: String, amountPaise: Int) -> UUID? {
        let name = recipient.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, amountPaise > 0, amountPaise <= balancePaise else { return nil }
        let id = UUID()
        balancePaise -= amountPaise
        transactions.insert(Transaction(id: id, title: "Sent to \(name)", amountPaise: -amountPaise, date: .now), at: 0)
        return id
    }
    func clearPaymentDraft() { paymentDraft = PaymentDraft() }
}

// MARK: - Root

struct ContentView: View {
    @State private var router = NPayRouter()
    @State private var store = NPayStore()
    @State private var preferences = NPayPreferences()

    var body: some View {
        @Bindable var router = router
        TabView(selection: $router.selectedTab) {
            NavigationStack(path: $router.homePath) {
                HomeScreen(store: store, router: router)
                    .navigationDestination(for: NPayRoute.self, destination: destination)
            }
            .tabItem { Label("Home", systemImage: "house") }.tag(NPayTab.home)

            NavigationStack(path: $router.paymentsPath) {
                PaymentsScreen(store: store, router: router)
                    .navigationDestination(for: NPayRoute.self, destination: destination)
            }
            .tabItem { Label("Payments", systemImage: "arrow.up.right") }.tag(NPayTab.payments)

            NavigationStack(path: $router.historyPath) {
                HistoryScreen(transactions: store.transactions)
                    .navigationDestination(for: NPayRoute.self, destination: destination)
            }
            .tabItem { Label("History", systemImage: "clock") }.tag(NPayTab.history)

            NavigationStack(path: $router.profilePath) {
                ProfileScreen()
                    .navigationDestination(for: NPayRoute.self, destination: destination)
            }
            .tabItem { Label("Profile", systemImage: "person") }.tag(NPayTab.profile)
        }
        .environment(preferences)
        .preferredColorScheme(preferences.appearance.colorScheme)
    }

    @ViewBuilder
    private func destination(_ route: NPayRoute) -> some View {
        switch route {
        case .accountDetails: AccountDetailsScreen(balancePaise: store.balancePaise)
        case .paymentSuccess(let id): PaymentSuccessScreen(transactionID: id) { router.returnHome() }
        case .transactionDetails(let id):
            if let txn = store.transactions.first(where: { $0.id == id }) {
                TransactionDetailScreen(transaction: txn)
            } else {
                ContentUnavailableView("Transaction not found", systemImage: "questionmark.circle")
            }
        case .settings: SettingsScreen()
        case .appearance: AppearanceSettingsView()
        }
    }
}

// MARK: - Appearance settings (Lesson 3.9)

struct AppearanceSettingsView: View {
    @Environment(NPayPreferences.self) private var preferences
    var body: some View {
        @Bindable var preferences = preferences
        Form {
            Section("Appearance") {
                Picker("Theme", selection: $preferences.appearance) {
                    ForEach(NPayAppearance.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
            }
            Section("Display") {
                Toggle("Show Demo Badge", isOn: $preferences.showDemoBadge)
            }
        }
        .navigationTitle("Appearance")
    }
}

// MARK: - Home

struct HomeScreen: View {
    let store: NPayStore
    let router: NPayRouter
    @State private var showRequestInfo = false
    var body: some View {
        ScrollView {
            VStack(spacing: NPayTheme.Spacing.large) {
                BalanceCard(balancePaise: store.balancePaise)
                NPayQuickActions(
                    onSend: { router.select(.payments) },
                    onRequest: { showRequestInfo = true },
                    onHistory: { router.select(.history) }
                )
                NavigationLink(value: NPayRoute.accountDetails) {
                    Label("Account Details", systemImage: "person.text.rectangle")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                NPayCard {
                    VStack(alignment: .leading, spacing: 12) {
                        NPaySectionHeader(title: "Recent Transactions", actionTitle: "View All") { router.select(.history) }
                        ForEach(store.transactions.prefix(3)) { TransactionRow(transaction: $0) }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("NPay")
        .alert("Request money", isPresented: $showRequestInfo) {
            Button("OK", role: .cancel) {}
        } message: { Text("Requests aren't part of the demo yet.") }
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
            VStack(alignment: .leading, spacing: NPayTheme.Spacing.medium) {
                Text("Available: \(Money.display(store.balancePaise))").foregroundStyle(.secondary)
                TextField("Recipient ID", text: $store.paymentDraft.recipient)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder).focused($focusedField, equals: .recipient)
                    .submitLabel(.next).onSubmit { focusedField = .amount }
                    .accessibilityLabel("Recipient")                          // 3.12 fix: was empty/placeholder-only
                    .accessibilityIdentifier(NPayAccessibilityID.recipientField)
                TextField("Amount (₹)", text: $store.paymentDraft.amountText)
                    .keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .amount)
                    .accessibilityLabel("Amount in rupees")
                    .accessibilityIdentifier(NPayAccessibilityID.amountField)
                if !store.paymentDraft.amountText.isEmpty && !isValid {
                    Text("Enter a valid amount within your balance.").font(.caption).foregroundStyle(.red)
                }
                NPayButton("Review Payment", symbol: "arrow.up.right") {
                    guard let amount = parsedAmount else { return }
                    focusedField = nil
                    review = PaymentReview(recipient: store.paymentDraft.recipient, amountPaise: amount)
                }
                .disabled(!isValid)
                .accessibilityIdentifier(NPayAccessibilityID.sendButton)
                Button("Discard Draft", role: .destructive) { confirmDiscard = true }.disabled(draftIsEmpty)
            }
            .padding()
        }
        .navigationTitle("Payments")
        .toolbar { ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Done") { focusedField = nil } } }
        .sheet(item: $review, onDismiss: {
            if let id = pendingSuccessID { pendingSuccessID = nil; router.showPaymentSuccess(id) }
            else if paymentFailed { paymentFailed = false; showFailure = true }
        }) { review in
            PaymentReviewSheet(review: review) {
                if let id = store.recordDemoPayment(recipient: review.recipient, amountPaise: review.amountPaise) {
                    store.clearPaymentDraft(); pendingSuccessID = id
                } else { paymentFailed = true }
                self.review = nil
            }
        }
        .alert("Payment not recorded", isPresented: $showFailure) {
            Button("OK", role: .cancel) {}
        } message: { Text("The amount is no longer within your available balance.") }
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
            NPayButton("Confirm Demo Payment") {
                guard !isProcessing else { return }
                isProcessing = true; onConfirm()
            }
            .disabled(isProcessing)
            Button("Edit Details") { dismiss() }.buttonStyle(.bordered)
        }
        .padding().presentationDetents([.medium, .large]).interactiveDismissDisabled(isProcessing)
    }
}

// MARK: - Success

struct PaymentSuccessScreen: View {
    let transactionID: UUID
    let onDone: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showContent = false
    var body: some View {
        VStack(spacing: 24) {
            if showContent {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80)).foregroundStyle(NPayTheme.Colors.success)
                    .transition(.scale.combined(with: .opacity))
                    .accessibilityHidden(true)
            }
            Text("Payment Recorded").font(.title.bold())
            Text(transactionID.uuidString)
                .font(.caption2.monospaced()).foregroundStyle(.secondary).multilineTextAlignment(.center)
            NPayButton("Back to Dashboard", action: onDone)
        }
        .padding().navigationTitle("Payment Success").navigationBarBackButtonHidden()
        .onAppear {
            if reduceMotion { showContent = true }
            else { withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { showContent = true } }
        }
    }
}

// MARK: - Other screens

struct HistoryScreen: View {
    let transactions: [Transaction]
    @State private var searchText = ""

    // Concept 5: recomputed when searchText (or transactions) changes.
    // Cheap at demo size; at 50k rows this is where we'd debounce.
    private var filteredTransactions: [Transaction] {
        guard !searchText.isEmpty else { return transactions }
        return transactions.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List(filteredTransactions) { transaction in
            NavigationLink(value: NPayRoute.transactionDetails(transaction.id)) {
                TransactionRow(transaction: transaction)
            }
        }
        .searchable(text: $searchText)                                   // Concept 6 milestone addition
        .navigationTitle("History")
        .accessibilityIdentifier(NPayAccessibilityID.transactionList)
    }
}

struct TransactionDetailScreen: View {
    let transaction: Transaction
    var body: some View {
        List {
            LabeledContent("Title", value: transaction.title)
            LabeledContent("Amount", value: Money.display(transaction.amountPaise))
            LabeledContent("Date", value: transaction.date.formatted(date: .abbreviated, time: .shortened))
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
                    Image(systemName: "person.crop.circle.fill").font(.system(size: 48)).foregroundStyle(NPayTheme.Colors.primary)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("NPay Demo User").font(.headline)
                        Text("Account settings and preferences").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            NavigationLink(value: NPayRoute.appearance) { Label("Appearance", systemImage: "paintbrush") }
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
            LabeledContent("Version", value: "Lesson 3.12 demo")
        }
        .navigationTitle("Settings")
    }
}

// MARK: - Domain components

struct BalanceCard: View {
    let balancePaise: Int
    @Environment(NPayPreferences.self) private var preferences

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available Balance").font(.subheadline)
            Text(Money.display(balancePaise))
                .font(.largeTitle.bold())
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.4), value: balancePaise)
            if preferences.showDemoBadge {
                Text("DEMO ACCOUNT")
                    .font(.caption.bold())
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(.white.opacity(0.18), in: Capsule())
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(NPayTheme.Colors.primary, in: RoundedRectangle(cornerRadius: NPayTheme.Radius.card))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(NPayAccessibilityID.balanceCard)
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: transaction.amountPaise >= 0 ? "arrow.down.left" : "arrow.up.right")
                .font(.title2)
                .foregroundStyle(transaction.amountPaise >= 0 ? NPayTheme.Colors.success : NPayTheme.Colors.primary)
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.title).font(.headline)
                Text(transaction.date, format: .dateTime.day().month(.abbreviated))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(Money.display(transaction.amountPaise))
                .font(.subheadline.bold())
                .foregroundStyle(transaction.amountPaise >= 0 ? NPayTheme.Colors.success : .primary)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(transaction.title)
        .accessibilityValue(Money.display(transaction.amountPaise))
    }
}

#Preview {
    ContentView()
}

// ↑↑↑ This real ContentView IS the complete Lesson 3.12 code (Unit 3 complete). ↑↑↑
```
