# Lesson 3.3 — TabView & Shared App State

*Unit 3 · Navigation, Architecture & Polish*

---

## Concept 1 of 6 — TabView basics

> 🔑 TabView shows selectable top-level sections; each child uses .tabItem { Label(...) } for its bar entry.  

**Key points**

- TabView = a container showing ONE child at a time, with a tab BAR to switch between them.
- .tabItem { Label("Home", systemImage: "house") } = the tab's icon + title (Label pairs text with an SF Symbol).
- Tapping a tab swaps the visible child instantly — no push, no Back button.
- These are TOP-LEVEL sections, not screens pushed on a stack.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Text("Home Screen")
                .tabItem { Label("Home", systemImage: "house") }
            Text("Payments Screen")
                .tabItem { Label("Payments", systemImage: "arrow.up.right") }
            Text("History Screen")
                .tabItem { Label("History", systemImage: "clock") }
            Text("Profile Screen")
                .tabItem { Label("Profile", systemImage: "person") }
        }
    }
}

#Preview { ContentView() }
```

---

## Concept 2 of 6 — TabView vs NavigationStack

> 🔑 TabView = which section (lateral); NavigationStack = how deep (push/pop). Put one NavigationStack INSIDE each tab.  

**Key points**

- TabView switches between PEER sections (Home ↔ Payments ↔ …).
- They COMPOSE — the standard shape is a NavigationStack INSIDE each tab.
- Order matters: TabView is the OUTER container (the tab bar persists); each stack lives INSIDE a tab.
- Push deeper in a tab → the top nav bar/back button updates, but the TabView's tab bar stays put at the bottom.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            // Each tab = its OWN navigation stack
            NavigationStack {
                NavigationLink("Go to Account Details") {
                    Text("Account Details").navigationTitle("Account")
                }
                .navigationTitle("Home")
            }
            .tabItem { Label("Home", systemImage: "house") }

            NavigationStack {
                NavigationLink("Go to a payment") {
                    Text("Payment").navigationTitle("Payment")
                }
                .navigationTitle("Payments")
            }
            .tabItem { Label("Payments", systemImage: "arrow.up.right") }
        }
    }
}

#Preview { ContentView() }
```

---

## Concept 3 of 6 — controlled selection (.tag)

> 🔑 TabView(selection: $tab) + .tag(value) makes tab selection state you can read and set; setting it switches sections.  

**Key points**

- TabView(selection: $selectedTab) binds the active tab to your state (two-way, like NavigationStack(path:)):
    - `user taps a tab → SwiftUI writes its .tag into selectedTab`
    - `you set selectedTab in code → SwiftUI switches the tab`
    - Tab selection is just STATE (UI = f(State) again).
- .tag(NPayTab.home) gives each tab its selection value.
- Switch tabs from anywhere: This changes SECTION — NOT the same as path.append(.history), which would push within the current section.
- Tapping the ALREADY-selected tab pops its NavigationStack to root (built-in iOS behavior).

**Complete runnable file**

```swift
import SwiftUI

enum NPayTab: Hashable { case home, payments, history, profile }

struct ContentView: View {
    @State private var selectedTab: NPayTab = .home
    var body: some View {
        TabView(selection: $selectedTab) {
            VStack(spacing: 16) {
                Text("Home").font(.largeTitle)
                Button("Jump to History tab") { selectedTab = .history }
                    .buttonStyle(.borderedProminent)
            }
            .tabItem { Label("Home", systemImage: "house") }
            .tag(NPayTab.home)

            Text("Payments")
                .tabItem { Label("Payments", systemImage: "arrow.up.right") }
                .tag(NPayTab.payments)

            Text("History")
                .tabItem { Label("History", systemImage: "clock") }
                .tag(NPayTab.history)

            Text("Profile")
                .tabItem { Label("Profile", systemImage: "person") }
                .tag(NPayTab.profile)
        }
    }
}

#Preview { ContentView() }
```

---

## Concept 4 of 6 — shared state (@Observable store)

> 🔑 Shared app data lives in one @MainActor @Observable class; own it once with @State at the root and pass it to every tab.  

**Key points**

- @Observable (the Observation framework, iOS 17+) makes a REFERENCE type (class) whose properties SwiftUI watches.
- @MainActor: this state drives the UI, so its mutations belong on the main actor.
- Own ONE instance at the root with @State, pass it DOWN to tabs.
- @State owning a class? Yes — for @Observable objects, @State is how a view OWNS/keeps one alive.

**Complete runnable file**

```swift
import SwiftUI

@MainActor @Observable
final class NPayStore {
    var balancePaise = 2_500_000
    func spend(_ paise: Int) { balancePaise = max(0, balancePaise - paise) }
}

struct ContentView: View {
    @State private var store = NPayStore()      // single owner
    var body: some View {
        TabView {
            HomeTab(store: store)
                .tabItem { Label("Home", systemImage: "house") }
            PayTab(store: store)
                .tabItem { Label("Pay", systemImage: "arrow.up.right") }
        }
    }
}

struct HomeTab: View {
    let store: NPayStore
    var body: some View { Text("Balance: \(store.balancePaise)") }
}
struct PayTab: View {
    let store: NPayStore
    var body: some View {
        Button("Spend ₹100") { store.spend(10_000) }  // updates Home too
            .buttonStyle(.borderedProminent)
    }
}

#Preview { ContentView() }
```

---

## Concept 5 of 6 — the NPayRouter (per-tab paths)

> 🔑 An @Observable router holds selectedTab + a path PER tab; own it with @State, make bindings with @Bindable, bind each stack's path.  

**Key points**

- Separate paths = Home keeps its position while you visit History and come back.
- The router is @Observable (like the store), but it holds NAVIGATION state, not business data (that separation is Concept 6).
- Bind router properties into the views with @Bindable.
- @Bindable (Observation's partner to @Observable) lets you write $router.selectedTab / $router.homePath — bindings INTO an observable object's properties.
- Cross-tab navigation becomes one call: showPaymentSuccess(id) switches to Payments AND pushes the receipt — the router coordinates tab + path together.
- You can pass `router` explicitly (like the store), OR inject it with .environment(router) and read @Environment(NPayRouter.self) in any descendant.

**Complete runnable file**

```swift
import SwiftUI

enum NPayTab: Hashable { case home, payments }
enum NPayRoute: Hashable { case detail(Int) }

@MainActor @Observable
final class NPayRouter {
    var selectedTab: NPayTab = .home
    var homePath: [NPayRoute] = []
    var paymentsPath: [NPayRoute] = []
}

struct ContentView: View {
    @State private var router = NPayRouter()
    var body: some View {
        @Bindable var router = router
        TabView(selection: $router.selectedTab) {
            NavigationStack(path: $router.homePath) {
                Button("Push detail") { router.homePath.append(.detail(1)) }
                    .navigationTitle("Home")
                    .navigationDestination(for: NPayRoute.self) { r in
                        Text("Detail \(String(describing: r))")
                    }
            }
            .tabItem { Label("Home", systemImage: "house") }
            .tag(NPayTab.home)

            NavigationStack(path: $router.paymentsPath) {
                Text("Payments").navigationTitle("Payments")
            }
            .tabItem { Label("Pay", systemImage: "arrow.up.right") }
            .tag(NPayTab.payments)
        }
    }
}

#Preview { ContentView() }
```

---

## Concept 6 of 6 — the full 4-tab NPay (Milestone)

> ⭐️ MILESTONE 3.3 — NPay is a real tabbed app: Home · Payments · History · Profile, each with its own stack, one shared store.  
> 🔑 TabView of per-tab NavigationStacks + a shared @Observable store (data) + router (navigation) = scalable app architecture.  

**Key points**

- Two @Observable objects, clean separation of concerns:
    - `NPayStore  — WHAT the app knows (balance, transactions, the` recordDemoPayment logic)              = business state
    - Neither does the other's job (see the table below).
- The root (ContentView) owns both with @State and passes them to the tabs.
- ONE destination(_:) @ViewBuilder maps every NPayRoute → screen, registered on each tab's stack via .navigationDestination(for: NPayRoute.self, destination: destination).
- Cross-tab flow: PaymentsScreen records the payment on the STORE, gets a UUID, then asks the ROUTER to showPaymentSuccess(id) (switch to Payments tab + push the receipt). returnHome() clears the payments path and selects Home.
- New SwiftUI bits here (all standard):
    - `List + Section + LabeledContent  — tidy detail/profile screens`
    - `NavigationLink(value:)           — push a ROUTE value (pairs` with navigationDestination)
    - `ContentUnavailableView           — built-in empty/not-found state`
    - Router vs Store — keep them apart:
    - `NPayRouter            | NPayStore`
- A root owning observable objects and injecting them down is the seed of MVVM + dependency injection (Unit 4).

**Complete runnable file (the lesson's full app)**

```swift
import SwiftUI

// MARK: - Model & money

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

// MARK: - Navigation (router) + shared data (store)

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
    func returnHome() {
        paymentsPath.removeAll()
        selectedTab = .home
    }
}

@MainActor @Observable
final class NPayStore {
    var balancePaise = 2_500_000
    var transactions: [Transaction] = [
        Transaction(id: UUID(), title: "Coffee Shop", amountPaise: -25_000, date: .now),
        Transaction(id: UUID(), title: "Electricity Bill", amountPaise: -120_000, date: .now),
        Transaction(id: UUID(), title: "Salary Credit", amountPaise: 4_500_000, date: .now),
    ]

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
}

// MARK: - Root: TabView of per-tab NavigationStacks

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

    // ONE route→screen mapping, registered in every tab's stack.
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
                ContentUnavailableView("Transaction not found",
                                       systemImage: "questionmark.circle")
            }
        case .settings:
            SettingsScreen()
        }
    }
}

// MARK: - Screens

struct HomeScreen: View {
    let store: NPayStore
    let router: NPayRouter

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                BalanceCard(balancePaise: store.balancePaise)

                HStack(spacing: 12) {
                    Button { router.select(.payments) } label: {
                        tile("Send Money", "arrow.up.right")
                    }
                    Button { router.select(.history) } label: {
                        tile("History", "clock")
                    }
                }

                NavigationLink(value: NPayRoute.accountDetails) {
                    Label("Account Details", systemImage: "person.text.rectangle")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Transactions").font(.headline)
                    ForEach(store.transactions.prefix(3)) { t in
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

struct PaymentsScreen: View {
    let store: NPayStore
    let router: NPayRouter

    @State private var recipient = ""
    @State private var amountText = ""
    @FocusState private var focusedField: Field?
    enum Field: Hashable { case recipient, amount }

    private var parsedAmount: Int? { Money.parsePaise(amountText) }
    private var isValid: Bool {
        !recipient.trimmingCharacters(in: .whitespaces).isEmpty
        && (parsedAmount.map { $0 > 0 && $0 <= store.balancePaise } ?? false)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Available: \(Money.display(store.balancePaise))")
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
                    if let id = store.recordDemoPayment(recipient: recipient, amountPaise: amount) {
                        focusedField = nil
                        recipient = ""; amountText = ""
                        router.showPaymentSuccess(id)      // cross-tab navigation
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
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
            LabeledContent("ID") {
                Text(transaction.id.uuidString).font(.caption2.monospaced())
            }
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
            LabeledContent("Version", value: "Lesson 3.3 demo")
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
// ↑↑↑ This real ContentView IS the complete Lesson 3.3 code. ↑↑↑
```
