# Lesson 3.11 — Performance — Lazy Views & Identity

*Unit 3 · Navigation, Architecture & Polish*

---

## Concept 1 of 6 — what "slow" actually means

> 🔑 "Body evaluated" ≠ "laid out" ≠ "pixels redrawn". Slowness can live in state, evaluation, layout, or rendering — measure which.  

**Key points**

- THE KEY DISTINCTION — these three are NOT the same event:
    1. a view's `body` was EVALUATED        (cheap, happens a lot)
    - `2. the view was LAID OUT                 (measure + position)`
    - `3. PIXELS were REDRAWN on screen         (the expensive end)`
- Consequence: counting body evaluations alone tells you almost nothing.
- Most "jank" is work on the MAIN ACTOR during a frame: a big sort, JSON decode, or generating 50k models synchronously (Concept 5).
- "Premature optimization" here means caching/threading before you've measured which stage is slow.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    // The five stages where "slow" can hide (Section 2).
    private let stages: [(name: String, detail: String, symbol: String)] = [
        ("Application state", "Large updates or expensive computations", "externaldrive"),
        ("View evaluation",   "SwiftUI re-runs dependent body descriptions", "function"),
        ("Layout",            "Views measure and position their content", "ruler"),
        ("Rendering",         "Drawing and compositing visual output", "paintbrush"),
        ("Display",           "Finished frames reach the screen", "display"),
    ]
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Where 'slow' can live").font(.title2.bold())
            ForEach(Array(stages.enumerated()), id: \.offset) { _, stage in
                HStack(spacing: 12) {
                    Image(systemName: stage.symbol).frame(width: 30).foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(stage.name).font(.headline)
                        Text(stage.detail).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
    }
}

#Preview { ContentView() }
```

---

## Concept 2 of 6 — eager VStack vs LazyVStack

> 🔑 VStack builds every child up front (eager); LazyVStack builds only what's near the viewport. Laziness = view creation, not data loading.  

**Key points**

- VStack is an EAGER layout container: it creates & lays out ALL children immediately, even the 9,985 you can't see. 10k rows → 10k bodies built on open → slow first frame, big memory.
- LazyVStack DEFERS creation/layout until a child is about to be needed (scrolled near).
- Note: ForEach is NOT the villain. Swapping ONE word (VStack → LazyVStack) is the whole fix for the eager-layout cost.
- LazyVStack lives INSIDE a ScrollView (it needs the scroll viewport to know what's "near").
- Lazy has a cost too: rows are built/discarded as you scroll, so per-row body work during scrolling matters more — keep rows cheap.

**Complete runnable file**

```swift
import SwiftUI

// Counts how many rows have actually been created/appeared.
@MainActor @Observable
final class AppearCounter { var count = 0 }

struct LabRow: View {
    let id: Int
    let onBuilt: () -> Void
    var body: some View {
        Text("Transaction #\(id)")
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .onAppear(perform: onBuilt)   // fires when the row enters the scene
    }
}

struct ContentView: View {
    enum Mode: String, CaseIterable { case eager = "VStack", lazy = "LazyVStack" }
    @State private var mode: Mode = .lazy
    @State private var counter = AppearCounter()
    private let ids = Array(1...3_000)

    var body: some View {
        VStack(spacing: 8) {
            Picker("", selection: $mode) {
                ForEach(Mode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented).padding(.horizontal)
            .onChange(of: mode) { counter.count = 0 }   // reset to compare fairly

            Text("Rows appeared: \(counter.count) / \(ids.count)")
                .font(.headline).monospacedDigit()

            ScrollView {
                if mode == .eager {
                    VStack(spacing: 0) {
                        ForEach(ids, id: \.self) { LabRow(id: $0) { counter.count += 1 } }
                    }
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(ids, id: \.self) { LabRow(id: $0) { counter.count += 1 } }
                    }
                }
            }
        }
    }
}

#Preview { ContentView() }
// Eager → "3000 / 3000" on open. Lazy → a dozen, growing as you scroll.
```

---

## Concept 3 of 6 — List vs LazyVStack

> 🔑 List = batteries-included lazy collection (selection, swipe, a11y) — the default for NPay History; LazyVStack = lazy raw layout you wire up yourself. Both pay for what's visible; still measure.  

**Key points**

- For NPay History, LIST IS THE RIGHT DEFAULT: we want row selection (NavigationLink), possible swipe actions, free accessibility & Dynamic Type behavior, and it handles large collections lazily.
- Reach for LazyVStack when you need a layout List can't give you (custom spacing/backgrounds, mixed content, a magazine-style feed).
- Still MEASURE — "List is always faster" is a myth; it depends on the row hierarchy and workload.
- List rows are reused/recycled, so NEVER store per-row view state you need to survive scrolling in the row itself — keep it in the model / store (ties back to identity, Concept 4).
- List(data) { } and List { ForEach(data) { } } are both lazy; use the ForEach form when you need onDelete/onMove or multiple sections.

**Complete runnable file**

```swift
import SwiftUI

@MainActor @Observable
final class AppearCounter { var count = 0 }

struct LabRow: View {
    let id: Int
    let onBuilt: () -> Void
    var body: some View {
        HStack {
            Image(systemName: "creditcard").foregroundStyle(.blue)
            Text("Transaction #\(id)")
            Spacer()
            Text("₹250").foregroundStyle(.secondary)
        }
        .onAppear(perform: onBuilt)
    }
}

struct ContentView: View {
    enum Mode: String, CaseIterable { case eager = "VStack", lazy = "LazyVStack", list = "List" }
    @State private var mode: Mode = .list
    @State private var counter = AppearCounter()
    private let ids = Array(1...3_000)

    var body: some View {
        VStack(spacing: 10) {
            Picker("", selection: $mode) {
                ForEach(Mode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented).padding(.horizontal)
            .onChange(of: mode) { counter.count = 0 }
            Text("Rows appeared: \(counter.count) / \(ids.count)").font(.headline).monospacedDigit()

            switch mode {
            case .eager:
                ScrollView { VStack(spacing: 0) {
                    ForEach(ids, id: \.self) { LabRow(id: $0) { counter.count += 1 } }
                } }
            case .lazy:
                ScrollView { LazyVStack(spacing: 0) {
                    ForEach(ids, id: \.self) { LabRow(id: $0) { counter.count += 1 } }
                } }
            case .list:
                List(ids, id: \.self) { id in LabRow(id: id) { counter.count += 1 } }
            }
        }
    }
}

#Preview { ContentView() }
// Eager → 3000/3000. Lazy & List → only the visible window builds.
```

---

## Concept 4 of 6 — identity, Observation & _printChanges

> 🔑 Give each item ONE stable identity (stored, not computed). Observation re-runs only the bodies that read the changed property; _printChanges() explains re-runs but doesn't prove slowness.  

**Key points**

- THE CLASSIC BUG — a COMPUTED id that makes a new value every read: Now every update looks like a brand-new set of rows → SwiftUI rebuilds them, loses row state, and animates spuriously.
- ForEach(data) needs stable IDs too: ForEach(txns) works via Identifiable; ForEach(ids, id: \.self) is fine for value arrays but NEVER use \.self on a type whose "identity" can repeat or mutate.
- Prefer a persistent UUID stored in the model (ours) or a DB primary key — not an array index (indices shift on insert/delete).

**Complete runnable file**

```swift
import SwiftUI

struct Transaction: Identifiable {
    let id: UUID            // stable identity — assigned once, never recomputed
    let title: String
    let amountPaise: Int
}

@MainActor @Observable
final class NPayStore {
    var balancePaise = 2_500_000
    var transactions: [Transaction] = [
        Transaction(id: UUID(), title: "Coffee Shop", amountPaise: -25_000),
        Transaction(id: UUID(), title: "Electricity Bill", amountPaise: -120_000),
        Transaction(id: UUID(), title: "Salary Credit", amountPaise: 4_500_000),
    ]
}

// Reads ONLY balance → re-runs only when the balance changes.
struct BalanceReader: View {
    let store: NPayStore
    var body: some View {
        let _ = Self._printChanges()
        return Text("Balance: ₹\(store.balancePaise / 100)").font(.title2.bold())
    }
}

// Stable id → "Change balance" does NOT rebuild these rows.
struct TransactionRow: View {
    let transaction: Transaction
    var body: some View {
        let _ = Self._printChanges()
        return HStack {
            Text(transaction.title); Spacer()
            Text("₹\(transaction.amountPaise / 100)").foregroundStyle(.secondary)
        }
    }
}

struct ContentView: View {
    @State private var store = NPayStore()
    var body: some View {
        VStack(spacing: 16) {
            BalanceReader(store: store)                 // re-runs on balance change only
            List(store.transactions) { TransactionRow(transaction: $0) }
            Button("Change balance") { store.balancePaise += 100 }  // only BalanceReader logs
            Button("Add transaction") {
                store.transactions.append(
                    Transaction(id: UUID(), title: "New #\(store.transactions.count)", amountPaise: -100))
            }
        }
        .padding()
    }
}

#Preview { ContentView() }
// Watch the console: "Change balance" re-runs only BalanceReader; rows stay put.
```

---

## Concept 5 of 6 — expensive work in body & the main actor

> 🔑 Keep body cheap — expensive sort/filter belongs in the data layer; search cost is per keystroke (debounce at scale); a lazy container can't rescue synchronous main-actor work. Budget: ~16.67 ms @ 60 Hz.  

**Key points**

- A comparison sort is ~O(n log n). For 50,000 transactions that's a lot of comparisons — repeated on EVERY body evaluation.
- Fix (architecturally): compute it OUTSIDE body — have the store / repository provide already-sorted data, or cache the derived result.
- Also avoid animating MASSIVE collection replacements: withAnimation { transactions = brandNewHugeArray } animates thousands of structural changes at once.
- A `let` inside body is a smell only when it's EXPENSIVE; cheap derivations are fine.

**Complete runnable file**

```swift
import SwiftUI

struct Transaction: Identifiable {
    let id = UUID(); let title: String; let amountPaise: Int
}

@MainActor @Observable
final class NPayStore {
    var transactions: [Transaction] = [
        .init(title: "Coffee Shop", amountPaise: -25_000),
        .init(title: "Electricity Bill", amountPaise: -120_000),
        .init(title: "Coffee Beans Co", amountPaise: -45_000),
        .init(title: "Salary Credit", amountPaise: 4_500_000),
    ]
}

struct ContentView: View {
    @State private var store = NPayStore()
    @State private var searchText = ""

    // Recomputed whenever searchText (or transactions) changes.
    private var filtered: [Transaction] {
        guard !searchText.isEmpty else { return store.transactions }
        return store.transactions.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { txn in
                HStack {
                    Text(txn.title); Spacer()
                    Text("₹\(txn.amountPaise / 100)").foregroundStyle(.secondary)
                }
            }
            .searchable(text: $searchText)
            .navigationTitle("History")
        }
    }
}

#Preview { ContentView() }
// Type "coffee" → the list filters to the two coffee rows.
```

---

## Concept 6 of 6 — MILESTONE — efficient, searchable NPay

> ⭐️ MILESTONE 3.11 — NPay History is searchable and built on lazy, stable-identity, observation-scoped foundations. We optimized by UNDERSTANDING, and verified by MEASURING — not by guessing.  
> 🔑 Performance work = measure first, change one thing, measure again. The right primitives (List + stable id + @Observable) make NPay efficient by construction; search is one cheap addition on top.  

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
                    .accessibilityLabel("Recipient ID")
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
            LabeledContent("Version", value: "Lesson 3.11 demo")
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

// ↑↑↑ This real ContentView IS the complete Lesson 3.11 code. ↑↑↑
```
