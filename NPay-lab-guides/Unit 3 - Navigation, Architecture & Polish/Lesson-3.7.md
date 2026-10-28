# Lesson 3.7 — Design System — Tokens & Components

*Unit 3 · Navigation, Architecture & Polish*

---

## Concept 1 of 6 — design tokens (NPayTheme)

> 🔑 A design system = tokens → components → screens; tokens are shared constants (enum + static) so the look lives in one place.  

**Key points**

- Tokens = named shared constants, organised with an enum + static members (a pure namespace; you never instantiate it):
    - }
    - Use them: NPayTheme.Colors.primary, NPayTheme.Spacing.medium …
- Why not hardcode? Change the brand once in the token → every component updates.
- (This is just Unit-1 namespacing with enums + static members — no special SwiftUI mechanism needed to DEFINE the tokens.)
- A fixed RGB can't adapt to dark mode / contrast.

**Complete runnable file**

```swift
import SwiftUI

enum NPayTheme {
    enum Colors {
        static let primary = Color(red: 0.10, green: 0.34, blue: 0.65)
        static let cardBackground = Color.blue.opacity(0.06)
    }
    enum Spacing { static let small: CGFloat = 8; static let medium: CGFloat = 16
                   static let large: CGFloat = 24 }
    enum Radius  { static let small: CGFloat = 10; static let card: CGFloat = 18 }
}

struct ContentView: View {
    var body: some View {
        VStack(spacing: NPayTheme.Spacing.large) {
            Text("Tokens in action").font(.headline)
            Text("Primary color + card radius, from the theme")
                .padding(NPayTheme.Spacing.medium)
                .background(NPayTheme.Colors.cardBackground,
                            in: RoundedRectangle(cornerRadius: NPayTheme.Radius.card))
                .foregroundStyle(NPayTheme.Colors.primary)
        }
        .padding()
    }
}

#Preview { ContentView() }
```

---

## Concept 2 of 6 — NPayButton (branded component)

> 🔑 A reusable component holds the LOOK (from tokens) and takes an action closure; callers stay declarative and consistent.  

**Key points**

- The LOOK lives inside NPayButton (built from TOKENS); the CALLER supplies only the action closure — same closure-component pattern as Lesson 2.7, now branded and consistent.
- Nice Swift touches, all reused from Unit 1:
    - custom init with a leading unlabeled title (NPayButton("…"))
    - optional `symbol` with a DEFAULT (symbol: String? = nil)
    - @escaping closure (stored, called on tap)
    - if-let to add the icon only when present
- Swap the whole app's primary-button style by editing ONE view.
- Because we hand-build the background, .disabled(x) on an NPayButton greys the LABEL but not our custom background.

**Complete runnable file:  (NPayTheme + NPayButton)**

```swift
import SwiftUI

enum NPayTheme {
    enum Colors {
        static let primary = Color(red: 0.10, green: 0.34, blue: 0.65)
        static let cardBackground = Color.blue.opacity(0.06)
    }
    enum Spacing { static let small: CGFloat = 8; static let medium: CGFloat = 16
                   static let large: CGFloat = 24 }
    enum Radius  { static let small: CGFloat = 10; static let card: CGFloat = 18 }
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
        .background(NPayTheme.Colors.primary,
                    in: RoundedRectangle(cornerRadius: NPayTheme.Radius.small))
    }
}
struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            NPayButton("Send Money", symbol: "arrow.up.right") { print("send") }
            NPayButton("History") { print("history") }   // no icon
        }.padding()
    }
}
#Preview { ContentView() }
```

---

## Concept 3 of 6 — `NPayCard<Content: View>`

> 🔑 `NPayCard<Content: View>` + @ViewBuilder wraps any content in the card style; generics keep types (beat AnyView for components).  

**Key points**

- `<Content: View>` = a generic type parameter constrained to View.
- @ViewBuilder on the stored `content` lets the caller use the trailing-closure, multi-view DSL inside the card — just like a VStack body.
- Why generic, not AnyView? AnyView ERASES the type: you lose compile-time structure and some optimization.

**Complete runnable file:  (NPayTheme + NPayCard)**

```swift
import SwiftUI

enum NPayTheme {
    enum Colors {
        static let primary = Color(red: 0.10, green: 0.34, blue: 0.65)
        static let cardBackground = Color.blue.opacity(0.06)
    }
    enum Spacing { static let small: CGFloat = 8; static let medium: CGFloat = 16
                   static let large: CGFloat = 24 }
    enum Radius  { static let small: CGFloat = 10; static let card: CGFloat = 18 }
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
struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            NPayCard { Text("Single Text content") }
            NPayCard {
                VStack(alignment: .leading) {
                    Text("Account").font(.headline)
                    Text("NPay Demo User").foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }
}
#Preview { ContentView() }
```

---

## Concept 4 of 6 — reusable View vs ViewModifier

> 🔑 Reusable View = a component with content; ViewModifier = a styling rule for any view. NPaySectionHeader is a View.  

**Key points**

- A styling rule as a modifier (same as 2.6):
    - }
    - // Text("Recent Transactions").npayCardStyle()
- A reusable semantic component — NPaySectionHeader (title + optional "action" button), used by Home, History, Profile:
    - }
- Optional actionTitle + action → the trailing button appears ONLY when both are provided (if-let unwraps them together).

**Complete runnable file:  (adds header + modifier)**

```swift
import SwiftUI

enum NPayTheme {
    enum Colors {
        static let primary = Color(red: 0.10, green: 0.34, blue: 0.65)
        static let cardBackground = Color.blue.opacity(0.06)
    }
    enum Spacing { static let small: CGFloat = 8; static let medium: CGFloat = 16
                   static let large: CGFloat = 24 }
    enum Radius  { static let small: CGFloat = 10; static let card: CGFloat = 18 }
}

struct NPaySectionHeader: View {
    let title: String; let actionTitle: String?; let action: (() -> Void)?
    var body: some View {
        HStack {
            Text(title).font(.headline); Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action).font(.subheadline)
            }
        }
    }
}
struct NPayCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.padding(16)
            .background(NPayTheme.Colors.cardBackground,
                        in: RoundedRectangle(cornerRadius: 18))
    }
}
extension View { func npayCardStyle() -> some View { modifier(NPayCardModifier()) } }

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            NPaySectionHeader(title: "Recent Transactions",
                              actionTitle: "View All") { print("all") }
            NPaySectionHeader(title: "Rewards", actionTitle: nil, action: nil)
            Text("Styled by modifier").npayCardStyle()
        }.padding()
    }
}
#Preview { ContentView() }
```

---

## Concept 5 of 6 — adapting + component responsibility

> 🔑 Use semantic fonts/colors so components adapt (Dynamic Type, dark mode); keep business logic OUT of components.  

**Key points**

- DYNAMIC TYPE — prefer SEMANTIC fonts over fixed sizes:
    - `.font(.system(size: 16))   // ❌ ignores the user's text-size setting`
    - `.font(.headline) / .body / .caption   // ✅ scale with Dynamic Type`
- DARK MODE / CONTRAST — prefer SEMANTIC COLOR ASSETS over fixed RGB:
    - `NPayTheme.Colors.primary = Color(red:…)       // one fixed color`
- COMPONENT RESPONSIBILITY — keep logic OUT of components:
    - ❌ NPayButton that calls store.recordDemoPayment(...)
    - `✅ NPayButton("Send") { submitPayment() }   // caller owns behavior`
- Two LEVELS of reusable views, both valid:
    - general design components — NPayButton, NPayCard, NPaySectionHeader
    - `domain components         — BalanceCard, TransactionRow`
    - Design components know nothing about NPay's data; domain ones do.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Fixed 16pt — won't scale")
                .font(.system(size: 16))
            Text("Semantic .headline — scales with Dynamic Type")
                .font(.headline)
            Text(".primary adapts to light/dark")
                .foregroundStyle(.primary)
            Text(".secondary adapts too")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
// Try: Simulator → Settings → Accessibility → Larger Text,
//      and toggle Dark Appearance. Semantic ones adapt.

#Preview { ContentView() }
```

---

## Concept 6 of 6 — integrate the design system (Milestone)

> ⭐️ MILESTONE 3.7 — NPay has a design system: tokens → reusable components → screens, applied across the app.  
> 🔑 Compose screens from shared tokens + components; one token edit re-skins everything, logic unchanged.  

**Key points**

- DesignSystem: NPayTheme, NPayButton, NPayCard, NPaySectionHeader, NPayCardModifier/.npayCardStyle().
- HomeScreen: "Send Money" is an NPayButton; recent transactions live in an NPayCard with an NPaySectionHeader ("View All").
- BalanceCard: background uses NPayTheme.Colors.primary + Radius.card.
- Payments / Review / Success: primary actions are NPayButtons (their .disabled stays).
- Business logic (store/router) is untouched — we only changed PRESENTATION.

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
    enum Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
    }
    enum Radius {
        static let small: CGFloat = 10
        static let card: CGFloat = 18
    }
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
        .buttonStyle(.plain)
        .foregroundStyle(.white)
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

// MARK: - Home (design-system composed)

struct HomeScreen: View {
    let store: NPayStore
    let router: NPayRouter
    var body: some View {
        ScrollView {
            VStack(spacing: NPayTheme.Spacing.large) {
                BalanceCard(balancePaise: store.balancePaise)

                NPayButton("Send Money", symbol: "arrow.up.right") {
                    router.select(.payments)
                }

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

            NPayButton("Confirm Demo Payment") {
                guard !isProcessing else { return }
                isProcessing = true
                onConfirm()
            }
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
                    .font(.system(size: 80)).foregroundStyle(NPayTheme.Colors.success)
                    .transition(.scale.combined(with: .opacity))
            }
            Text("Payment Recorded").font(.title.bold())
            Text(transactionID.uuidString)
                .font(.caption2.monospaced()).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            NPayButton("Back to Dashboard", action: onDone)
        }
        .padding()
        .navigationTitle("Payment Success")
        .navigationBarBackButtonHidden()
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
                        .font(.system(size: 48)).foregroundStyle(NPayTheme.Colors.primary)
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
            LabeledContent("Version", value: "Lesson 3.7 demo")
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
        .background(NPayTheme.Colors.primary,
                    in: RoundedRectangle(cornerRadius: NPayTheme.Radius.card))
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
// ↑↑↑ This real ContentView IS the complete Lesson 3.7 code (so far). ↑↑↑
```
