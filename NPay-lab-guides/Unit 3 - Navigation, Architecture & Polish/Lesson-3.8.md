# Lesson 3.8 — Responsive Layout

*Unit 3 · Navigation, Architecture & Polish*

---

## Concept 1 of 6 — the layout negotiation

> 🔑 SwiftUI layout = parent proposes, child chooses, parent places; adaptation means responding to the proposal, not fixed coords.  

**Key points**

- The 3-step negotiation, for every view:
    1. PARENT PROPOSES a size ("here's the space available").
    2. CHILD CHOOSES its size ("this is what I need").
    3. PARENT PLACES the child in the proposed space.
    - There are NO absolute coordinates — it's a conversation.
- A child does NOT always take all the space:
    - `Text("NPay")                       → just big enough for the text`
    - `Text("NPay").frame(maxWidth: .infinity) → expands to the proposal`
    - `Color.blue                         → greedy; fills what it's offered`
- .frame(maxWidth: .infinity) ≠ infinitely wide — it means "grow UP TO the width the parent proposed" (2.4/2.6 recap).
- Because adaptation is about the SPACE OFFERED + the CONTENT'S needs (not hardcoded device sizes), the tools in this lesson read or respond to that negotiation: GeometryReader (read the size), ViewThatFits (pick what fits), AnyLayout (swap layout).

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("NPay").border(.red)                       // hugs content
            Text("maxWidth .infinity").frame(maxWidth: .infinity).border(.green)
            Color.blue.opacity(0.2).frame(height: 40).border(.orange) // greedy width
        }
        .padding()
    }
}

#Preview { ContentView() }
```

---

## Concept 2 of 6 — GeometryReader

> 🔑 GeometryReader gives the offered size via GeometryProxy, but it's greedy (fills the space) and misbehaves in a ScrollView without an explicit height.  

**Key points**

- The closure gets a GeometryProxy (`geo`) exposing:
    - `geo.size                 the offered width/height`
    - `geo.safeAreaInsets       status bar / home indicator insets`
    - `geo.frame(in: .local)    frame in its own space`
    - `geo.frame(in: .global)   frame in screen space`
- GeometryReader is GREEDY — it expands to fill the space proposed to it (both axes).
- THE CLASSIC PITFALL — GeometryReader in a ScrollView: A vertical ScrollView proposes an UNSPECIFIED height on the scroll axis; GeometryReader then falls back to a small ideal height.
- Use GeometryReader only when you GENUINELY need geometry.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 8) {
                Text("Offered width:  \(Int(geo.size.width))")
                Text("Offered height: \(Int(geo.size.height))")
                Text(geo.size.width < 350 ? "COMPACT" : "REGULAR")
                    .font(.headline)
                    .foregroundStyle(geo.size.width < 350 ? .orange : .green)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)   // center in the reader
        }
    }
}
// Rotate the Simulator / resize to watch the numbers change.

#Preview { ContentView() }
```

---

## Concept 3 of 6 — ViewThatFits

> 🔑 ViewThatFits renders the first child that fits the space — adapts to content (incl. Dynamic Type), no width breakpoints.  

**Key points**

- ViewThatFits tries its children IN ORDER and renders the FIRST one that fits the proposed space (optionally along given axes: .horizontal / .vertical / both by default).
- Why better than `geo.size.width < 350`? A hardcoded breakpoint assumes 350 pt is right for EVERY text size and language.
- No GeometryReader, no greediness, no magic number — it just sizes to content and picks what fits.
- ViewThatFits uses each candidate's IDEAL size.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) { pills }     // used when it fits
            VStack(spacing: 12) { pills }     // fallback when it doesn't
        }
        .padding()
    }
    @ViewBuilder private var pills: some View {
        ForEach(["Send Money", "Request Money", "History"], id: \.self) { t in
            Text(t).padding().frame(maxWidth: .infinity)
                .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
        }
    }
}
// Shrink the width / raise Dynamic Type → it flips row → column.

#Preview { ContentView() }
```

---

## Concept 4 of 6 — AnyLayout (swap layout, keep identity)

> 🔑 AnyLayout swaps the layout algorithm while keeping one structural slot per child → state survives (unlike if/else branches, which reset it).  

**Key points**

- HStackLayout / VStackLayout are the Layout versions of the stacks.
- Why not just if/else between HStack{} and VStack{}? if vertical { VStack { CounterView() } }.
    - `else        { HStack  { CounterView() } }`
- Use AnyLayout when the children carry state/animation you must preserve across a layout change; use ViewThatFits when you just need "pick whichever arrangement fits."

**Complete runnable file**

```swift
import SwiftUI

struct CounterView: View {
    @State private var count = 0
    var body: some View {
        Button("Count: \(count)") { count += 1 }
            .buttonStyle(.borderedProminent)
    }
}

struct ContentView: View {
    @State private var vertical = false
    var body: some View {
        let layout = vertical ? AnyLayout(VStackLayout(spacing: 16))
                              : AnyLayout(HStackLayout(spacing: 16))
        VStack(spacing: 24) {
            layout { CounterView(); CounterView() }   // state survives switch
            Button("Switch layout") { vertical.toggle() }
        }
        .padding()
    }
}

#Preview { ContentView() }
```

---

## Concept 5 of 6 — safe areas + full responsiveness

> 🔑 Respect safe areas (extend only decoration); design for content + Dynamic Type + orientation + localization, not fixed widths.  

**Key points**

- A responsive layout reacts to the OFFERED SPACE + CONTENT NEEDS, not a list of hardcoded device models.
- In the Simulator / previews: a small device (SE) and a large one, rotate to landscape, crank Settings→Accessibility→Larger Text, and (if supporting) a localized language.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Color.blue.opacity(0.15).ignoresSafeArea()   // decoration behind safe areas
            VStack(spacing: 16) {
                Text("Content stays inside the safe area")
                    .font(.headline)                     // semantic → Dynamic Type
                Text("Background extends under the status bar / home indicator")
                    .font(.body).multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}

#Preview { ContentView() }
```

---

## Concept 6 of 6 — adaptive quick actions (Milestone)

> ⭐️ MILESTONE 3.8 — NPay's quick actions reflow (row ↔ column) to fit the device width and text size.  
> 🔑 ViewThatFits({row}{column}) gives content-driven responsive quick actions — adapts to width + Dynamic Type, no breakpoints.  

**Key points**

- QuickAction (back from 2.7): icon over label, action closure.
- NPayQuickActions: ViewThatFits picks a ROW when it fits, else a COLUMN — adapts to width AND Dynamic Type, no breakpoints:
    - }
- HomeScreen uses it: Send → Payments tab, History → History tab, Request → an alert (not in the demo yet).
- Everything else unchanged from 3.7 (design system, store, router).

**Complete runnable file (the lesson's full app)**

```swift
import SwiftUI

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
    let title: String
    let symbol: String?
    let action: () -> Void
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
        .background(NPayTheme.Colors.primary,
                    in: RoundedRectangle(cornerRadius: NPayTheme.Radius.small))
    }
}

struct NPayCard<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        content
            .padding(NPayTheme.Spacing.medium)
            .frame(maxWidth: .infinity)
            .background(NPayTheme.Colors.cardBackground,
                        in: RoundedRectangle(cornerRadius: NPayTheme.Radius.card))
    }
}

struct NPaySectionHeader: View {
    let title: String
    let actionTitle: String?
    let action: (() -> Void)?
    var body: some View {
        HStack {
            Text(title).font(.headline)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action).font(.subheadline)
            }
        }
    }
}

// Icon-over-label action (from Lesson 2.7)
struct QuickAction: View {
    let symbol: String
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: symbol).font(.title2)
                Text(title).font(.caption)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 14).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(NPayTheme.Colors.primary)
        .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}

// Responsive: row when it fits, column otherwise.
struct NPayQuickActions: View {
    let onSend: () -> Void
    let onRequest: () -> Void
    let onHistory: () -> Void
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
    func showPaymentSuccess(_ id: UUID) { selectedTab = .payments; paymentsPath.append(.paymentSuccess(id)) }
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
            Transaction(id: id, title: "Sent to \(name)", amountPaise: -amountPaise, date: .now), at: 0)
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
        }
    }
}

// MARK: - Home (adaptive quick actions)

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
                        NPaySectionHeader(title: "Recent Transactions",
                                          actionTitle: "View All") { router.select(.history) }
                        ForEach(store.transactions.prefix(3)) { t in
                            TransactionRow(transaction: t)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("NPay")
        .alert("Request money", isPresented: $showRequestInfo) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Requests aren't part of the demo yet.")
        }
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
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .recipient)
                    .submitLabel(.next).onSubmit { focusedField = .amount }

                TextField("Amount (₹)", text: $store.paymentDraft.amountText)
                    .keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .amount)

                if !store.paymentDraft.amountText.isEmpty && !isValid {
                    Text("Enter a valid amount within your balance.").font(.caption).foregroundStyle(.red)
                }

                NPayButton("Review Payment", symbol: "arrow.up.right") {
                    guard let amount = parsedAmount else { return }
                    focusedField = nil
                    review = PaymentReview(recipient: store.paymentDraft.recipient, amountPaise: amount)
                }
                .disabled(!isValid)

                Button("Discard Draft", role: .destructive) { confirmDiscard = true }
                    .disabled(draftIsEmpty)
            }
            .padding()
        }
        .navigationTitle("Payments")
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Done") { focusedField = nil } }
        }
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
    var body: some View {
        List(transactions) { t in
            NavigationLink(value: NPayRoute.transactionDetails(t.id)) { TransactionRow(transaction: t) }
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
            LabeledContent("Version", value: "Lesson 3.8 demo")
        }
        .navigationTitle("Settings")
    }
}

// MARK: - Domain components

struct BalanceCard: View {
    let balancePaise: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available Balance").font(.subheadline)
            Text(Money.display(balancePaise))
                .font(.largeTitle.bold())
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.4), value: balancePaise)
            Text("NPay Demo Account").font(.caption)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(NPayTheme.Colors.primary, in: RoundedRectangle(cornerRadius: NPayTheme.Radius.card))
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
    }
}

#Preview {
    ContentView()
}
// ↑↑↑ This real ContentView IS the complete Lesson 3.8 code (so far). ↑↑↑
```
