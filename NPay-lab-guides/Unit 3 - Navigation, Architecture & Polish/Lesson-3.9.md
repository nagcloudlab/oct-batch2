# Lesson 3.9 — Environment & App Preferences

*Unit 3 · Navigation, Architecture & Polish*

---

## Concept 1 of 6 — @Environment

> 🔑 @Environment(\.key) reads a contextual value supplied by the view hierarchy (via a key path) — no manual passing.  

**Key points**

- @Environment reads a value SwiftUI provides from the surrounding hierarchy — you don't pass it in.
- You've already used environment values:
    - `@Environment(\.dismiss)                    // pop/close (3.1, 3.4)`
    - `@Environment(\.accessibilityReduceMotion)  // motion pref (3.6)`
    - colorScheme is just another built-in one.
- It's READ access: @Environment(\.colorScheme) tells you the effective scheme; it doesn't let you CHANGE the system.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        VStack(spacing: 20) {
            Text("NPay Environment Lab").font(.title2.bold())
            Text(colorScheme == .dark ? "Dark Mode" : "Light Mode")
            Image(systemName: colorScheme == .dark ? "moon.fill" : "sun.max.fill")
                .font(.system(size: 48))
        }
        .padding()
    }
}

#Preview { ContentView() }
```

---

## Concept 2 of 6 — overriding & precedence

> 🔑 .environment(\.key, value) overrides for a subtree; nearest ancestor wins; env values are contextual, not global.  

**Key points**

- PRECEDENCE: the NEAREST ancestor's value wins.
- It does NOT change the device's system setting — only the SwiftUI environment for that subtree.
- @Environment vs @State vs @Binding — different jobs:
    - `@State     own local mutable state         (sheet visibility)`
    - `@Binding   read/write state owned elsewhere (balance editor)`
    - `@Environment  READ a contextual value from the hierarchy (scheme)`

**Complete runnable file**

```swift
import SwiftUI

struct SchemeReader: View {
    let title: String
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        Text("\(title): \(colorScheme == .dark ? "Dark" : "Light")")
            .padding().background(.gray.opacity(0.15))
    }
}

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            SchemeReader(title: "Outer")                  // inherits .light
            SchemeReader(title: "Inner")
                .environment(\.colorScheme, .dark)        // overridden
        }
        .environment(\.colorScheme, .light)               // outer value
        .padding()
    }
}

#Preview { ContentView() }
```

---

## Concept 3 of 6 — a custom environment value

> 🔑 Define a custom env value with EnvironmentKey (default) + EnvironmentValues extension (or @Entry); set/read it by key path.  

**Key points**

- An EnvironmentKey declares the value's TYPE + a DEFAULT.
- Now set and read it like any built-in value.
- If no ancestor sets it, descendants get the DEFAULT (true here).

**Complete runnable file**

```swift
import SwiftUI

private struct NPayDemoModeKey: EnvironmentKey {
    static let defaultValue = true
}
extension EnvironmentValues {
    var npayDemoMode: Bool {
        get { self[NPayDemoModeKey.self] }
        set { self[NPayDemoModeKey.self] = newValue }
    }
}

struct Badge: View {
    @Environment(\.npayDemoMode) private var demoMode
    var body: some View { Text(demoMode ? "DEMO: on" : "DEMO: off") }
}

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Badge()                                 // default → on
            Badge().environment(\.npayDemoMode, false)  // overridden → off
        }
    }
}

#Preview { ContentView() }
```

---

## Concept 4 of 6 — appearance model + preferredColorScheme

> 🔑 Model appearance as an enum with an optional ColorScheme (nil = system); apply it with .preferredColorScheme to theme the app.  

**Key points**

- colorScheme is OPTIONAL — `.system` returns nil, meaning "don't force a scheme; follow the device." CaseIterable + Identifiable make it easy to list in a Picker (next concept).
- Apply the choice at a container with .preferredColorScheme.
- Own the choice in @State (here) or a shared model (Concept 5), and bind a control to it so changing it updates the whole app.

**Complete runnable file**

```swift
import SwiftUI

enum NPayAppearance: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var colorScheme: ColorScheme? {
        switch self { case .system: nil; case .light: .light; case .dark: .dark }
    }
}

struct ContentView: View {
    @State private var appearance: NPayAppearance = .system
    var body: some View {
        VStack(spacing: 24) {
            Picker("Theme", selection: $appearance) {
                ForEach(NPayAppearance.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            Text("Everything below follows the choice")
                .padding().background(.gray.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
        }
        .padding()
        .preferredColorScheme(appearance.colorScheme)   // applies the theme
    }
}

#Preview { ContentView() }
```

---

## Concept 5 of 6 — inject an @Observable model (env)

> 🔑 Inject a shared @Observable with .environment(obj); read it via @Environment(Type.self); @Bindable for edits. Missing it = crash.  

**Key points**

- `.environment(object)` (no key path) injects an @Observable instance keyed by its TYPE; `@Environment(NPayPreferences.self)` retrieves THAT instance.
- To EDIT its properties with a control, wrap it with @Bindable inside body to get bindings: @Environment fetches the object; @Bindable makes $ bindings to it.
- Changes propagate via Observation: edit showDemoBadge in Profile and BalanceCard on Home updates — no showDemoBadge parameter between them.
- @Environment(NPayPreferences.self) is a REQUIRED dependency. If NO ancestor injected one, it crashes at runtime:
    - "No Observable object of type NPayPreferences found…"

**Complete runnable file**

```swift
import SwiftUI

enum NPayAppearance: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var colorScheme: ColorScheme? {
        switch self { case .system: nil; case .light: .light; case .dark: .dark }
    }
}
@MainActor @Observable final class NPayPreferences {
    var appearance: NPayAppearance = .system
    var showDemoBadge = true
}
struct Root: View {
    @State private var preferences = NPayPreferences()
    var body: some View {
        SettingsLike()
            .environment(preferences)                        // inject
            .preferredColorScheme(preferences.appearance.colorScheme)
    }
}
struct SettingsLike: View {
    @Environment(NPayPreferences.self) private var preferences // read
    var body: some View {
        @Bindable var preferences = preferences                // bindings
        Form {
            Picker("Theme", selection: $preferences.appearance) {
                ForEach(NPayAppearance.allCases) { Text($0.title).tag($0) }
            }.pickerStyle(.segmented)
            Toggle("Show Demo Badge", isOn: $preferences.showDemoBadge)
        }
    }
}
#Preview { Root() }
```

---

## Concept 6 of 6 — wire preferences into NPay (Milestone)

> ⭐️ MILESTONE 3.9 — one appearance picker themes the whole app; a toggle in Profile shows/hides the badge on Home — via the environment.  
> 🔑 Own shared config at the root, inject with .environment, read with @Environment(Type.self); apply theme via .preferredColorScheme.  

**Key points**

- NPayPreferences (@Observable): appearance + showDemoBadge.
- Root (ContentView) owns it with @State, then on the TabView.
- New route .appearance → AppearanceSettingsView (reads prefs via @Environment, edits via @Bindable).
- BalanceCard reads @Environment(NPayPreferences.self) and shows the "DEMO ACCOUNT" badge only when showDemoBadge is on — no parameter passed from the root; the environment delivers it.
- Store/router unchanged — preferences is a SEPARATE concern (don't cram UI prefs into the data store).

**Complete runnable file (the lesson's full app)**

```swift
import SwiftUI

// MARK: - Preferences (shared UI config)

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
            Text(title).font(.headline); Spacer()
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
        .environment(preferences)                                  // inject shared config
        .preferredColorScheme(preferences.appearance.colorScheme)  // apply theme app-wide
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

// MARK: - Appearance settings (reads prefs from the environment)

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
            LabeledContent("Version", value: "Lesson 3.9 demo")
        }
        .navigationTitle("Settings")
    }
}

// MARK: - Domain components

struct BalanceCard: View {
    let balancePaise: Int
    @Environment(NPayPreferences.self) private var preferences   // read shared config

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
// ↑↑↑ This real ContentView IS the complete Lesson 3.9 code (so far). ↑↑↑
```
