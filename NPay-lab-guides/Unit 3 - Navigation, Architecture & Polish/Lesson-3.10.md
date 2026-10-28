# Lesson 3.10 — Localization & Accessibility

*Unit 3 · Navigation, Architecture & Polish*

---

## Concept 1 of 6 — LocalizedStringKey vs String

> 🔑 String LITERAL in Text = translatable key. String VARIABLE in Text = literal text. Wrap variables in LocalizedStringKey(...) to localize.  

**Key points**

- Text("payment.send") — a STRING LITERAL. Its initializer takes a `LocalizedStringKey`, so SwiftUI treats "payment.send" as a KEY and looks it up in your String Catalog (Localizable.xcstrings) for the current language.
- let title: String = "payment.send"; Text(title) — now you pass a `String` VALUE.
- Force a lookup for a String value with: or type the parameter as LocalizedStringKey (what good components do).
- A String Catalog (.xcstrings, Xcode 15+) is JSON.
- Override the language in a preview with .environment(\.locale, …).

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    let title: String = "payment.send"          // a String VALUE
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("payment.send")                 // literal → KEY (no catalog yet → shows key)
            Text(title)                          // String value → literal "payment.send", always
            Text(LocalizedStringKey(title))      // force a key lookup from a String
        }
        .padding()
    }
}

#Preview { ContentView() }
// With a catalog, try a language: ContentView().environment(\.locale, .init(identifier: "hi"))
```

---

## Concept 2 of 6 — Locale-aware currency formatting

> 🔑 Value + currency live in the model; locale only decides how it's written. Format with .currency(code:), never string interpolation.  

**Key points**

- NEVER do Text("₹\(amount)"). Manual strings break grouping, decimal separators, symbol placement, negatives, AND VoiceOver's currency announcement.
- NPay stores money as integer paise and converts only at the edge for display — see Money.display below.
- Omit .locale(...) and it uses the device's current locale — usually what you want in-app; pin a locale only for fixtures/tests.
- Dates/numbers follow the same rule: Text(date, format: .dateTime...) and .number — never hand-format for display.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    let amount = Decimal(12_345_678_50) / 100   // same VALUE everywhere
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(amount, format: .currency(code: "INR").locale(.init(identifier: "en_IN")))
            Text(amount, format: .currency(code: "INR").locale(.init(identifier: "en_US")))
            Text(amount, format: .currency(code: "INR").locale(.init(identifier: "de_DE")))
            Divider()
            Text("Manual (WRONG): ₹\(amount)")   // breaks grouping/decimals/VoiceOver
                .foregroundStyle(.red)
        }
        .monospacedDigit()
        .padding()
    }
}

#Preview { ContentView() }
// en_IN ₹1,23,45,678.50 · en_US ₹12,345,678.50 · de_DE 12.345.678,50 ₹
```

---

## Concept 3 of 6 — Right-to-left (RTL) layout

> 🔑 Think leading/trailing, not left/right. HStack + semantic alignment mirror for free; test with the layoutDirection override.  

**Key points**

- Read the current direction.
- Design rule: NEVER hardcode left/right. Use SEMANTIC edges: vs absolute offsets / assuming "leading == left" → broken in RTL.
- Test it in a preview without an Arabic build: (A preview override finds layout assumptions; still test a real RTL language before shipping.)
- SF Symbols that imply direction (arrow.up.right, chevron) do NOT all auto-mirror.
- Being semantic (leading/trailing) from day one means RTL is almost free later — zero rework.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    @Environment(\.layoutDirection) private var layoutDirection
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Direction: \(layoutDirection == .rightToLeft ? "RTL ←" : "LTR →")")
                .font(.headline)
            HStack {                                  // reverses in RTL
                Image(systemName: "indianrupeesign.circle.fill")
                Text("Available Balance")
                Spacer()
                Text("₹25,000")
            }
            .padding()
            .background(.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
        }
        .frame(maxWidth: .infinity, alignment: .leading)   // flips edge in RTL
        .padding()
    }
}

#Preview("LTR") { ContentView() }
#Preview("RTL") { ContentView().environment(\.layoutDirection, .rightToLeft) }
```

---

## Concept 4 of 6 — Accessibility — meaning over layout

> 🔑 Combine related views into one element and speak MEANING (label = what, value = amount), not the on-screen layout.  

**Key points**

- children: options —.
    - `.ignore   → ignore children, you supply label/value (use for rows)`
    - `.combine  → merge children's text into one element (use for cards)`
    - `.contain  → keep children as a group/container`
- LABEL = identity (noun). VALUE = current state/amount.
- Never rely on COLOR or ANIMATION alone. The green success checkmark reads as "Selected" to VoiceOver — pair it with a Text("Payment Recorded") so success is actually announced (and hide the icon).
- .accessibilityHidden(true) removes purely-decorative views from the tree.
- A placeholder is NOT a label — VoiceOver reads an empty label with the placeholder as value.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.up.right")
                .accessibilityHidden(true)           // decorative → drop from VoiceOver
            VStack(alignment: .leading) {
                Text("Coffee Shop").font(.headline)
                Text("25 Oct").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text("-₹250.00").font(.subheadline.bold())
        }
        .padding()
        .accessibilityElement(children: .ignore)     // one element, not four
        .accessibilityLabel("Coffee Shop")           // WHAT
        .accessibilityValue("-₹250.00")              // VALUE
        // VoiceOver reads: "Coffee Shop, minus ₹250.00" in a single swipe.
    }
}

#Preview { ContentView() }
```

---

## Concept 5 of 6 — Accessible components + identifiers

> 🔑 label = spoken, identifier = test hook (silent). Bake both into reusable components; keep identifiers in one enum.  

**Key points**

- Put accessibility modifiers INSIDE the component (TransactionRow, BalanceCard) so every use site is accessible automatically — DRY accessibility, exactly like a design token.
- Label(title, systemImage:) already pairs text + icon accessibly and adapts to Dynamic Type — prefer it over hand-built HStack(icon,text).

**Complete runnable file**

```swift
import SwiftUI

enum NPayAccessibilityID {
    static let sendButton = "npay.sendButton"
}

struct NPayActionButton: View {
    let title: LocalizedStringKey          // translatable (spoken) title
    let symbol: String
    let accessibilityID: String            // silent, stable test hook
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.headline).frame(maxWidth: .infinity).padding()
        }
        .buttonStyle(.borderedProminent)
        .accessibilityIdentifier(accessibilityID)
    }
}

struct ContentView: View {
    var body: some View {
        NPayActionButton(title: "payment.send",
                         symbol: "arrow.up.right",
                         accessibilityID: NPayAccessibilityID.sendButton) { }
            .padding()
    }
}

#Preview { ContentView() }
```

---

## Concept 6 of 6 — MILESTONE — accessible, localizable NPay

> ⭐️ MILESTONE 3.10 — the SAME NPay now reads correctly to VoiceOver, scales with Dynamic Type, formats money per locale, and is ready for other languages and RTL — with no change to balance/router/store.  
> 🔑 Accessibility + localization are presentation concerns layered on top of a stable domain model: say meaning, format by locale, test by identifier.  

**Complete runnable file (the lesson's full app)**

```swift
import SwiftUI

// MARK: - Accessibility identifiers (Concept 5)

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

// Concept 5: localized + accessible reusable action button.
struct NPayActionButton: View {
    let title: LocalizedStringKey      // takes a translatable key
    let symbol: String
    let accessibilityID: String        // stable, silent test hook
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbol)   // text + icon, accessible & Dynamic-Type aware
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
        }
        .buttonStyle(.borderedProminent)
        .tint(NPayTheme.Colors.primary)
        .accessibilityIdentifier(accessibilityID)
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
            Text(title).font(.headline).accessibilityAddTraits(.isHeader)   // jumpable heading for VoiceOver
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

// Concept 2: locale-aware formatting. Value (paise) + currency (INR)
// live here; the locale only decides how the string is WRITTEN.
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
                        .frame(maxWidth: .infinity, alignment: .leading)   // semantic edge → RTL-safe
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
                    .accessibilityLabel("Recipient ID")                       // real spoken label (Concept 4)
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
                .accessibilityIdentifier(NPayAccessibilityID.sendButton)      // stable test hook
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
                    .accessibilityHidden(true)      // decorative; the Text below announces success (Concept 4)
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
        .accessibilityIdentifier(NPayAccessibilityID.transactionList)   // stable test hook
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
            LabeledContent("Version", value: "Lesson 3.10 demo")
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
        // Concept 4+5: read as one meaningful element; stable test hook.
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
        // Concept 4: collapse 4 fragments into one "noun + value" element.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(transaction.title)
        .accessibilityValue(Money.display(transaction.amountPaise))
    }
}

#Preview {
    ContentView()
}

// Concept 3: verify RTL layout without an Arabic build.
#Preview("RTL") {
    ContentView()
        .environment(\.layoutDirection, .rightToLeft)
}

// ↑↑↑ This real ContentView IS the complete Lesson 3.10 code. ↑↑↑
```
