import SwiftUI

// MARK: - Model, money, draft

struct Transaction: Identifiable {
    let id: UUID
    let title: String
    let amountPaise: Int
    let date: Date
}

struct PaymentDraft: Identifiable {
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

// MARK: - Router + Store (from 3.3)

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
                ContentUnavailableView("Transaction not found",
                                       systemImage: "questionmark.circle")
            }
        case .settings:
            SettingsScreen()
        }
    }
}

// MARK: - Payments (now with a review sheet)

struct PaymentsScreen: View {
    let store: NPayStore
    let router: NPayRouter

    @State private var recipient = ""
    @State private var amountText = ""
    @State private var reviewDraft: PaymentDraft?
    @State private var pendingSuccessID: UUID?
    @State private var paymentFailed = false
    @State private var showFailure = false
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

                Button("Review Payment") {
                    guard let amount = parsedAmount else { return }
                    focusedField = nil
                    reviewDraft = PaymentDraft(recipient: recipient, amountPaise: amount)
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
        .sheet(item: $reviewDraft, onDismiss: {
            if let id = pendingSuccessID {
                pendingSuccessID = nil
                recipient = ""; amountText = ""
                router.showPaymentSuccess(id)        // navigate after dismiss
            } else if paymentFailed {
                paymentFailed = false
                showFailure = true
            }
        }) { draft in
            PaymentReviewSheet(draft: draft) {
                // Re-validate at confirm time (balance may have changed).
                if let id = store.recordDemoPayment(
                    recipient: draft.recipient, amountPaise: draft.amountPaise) {
                    pendingSuccessID = id
                } else {
                    paymentFailed = true
                }
                reviewDraft = nil
            }
        }
        .alert("Payment not recorded", isPresented: $showFailure) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The amount is no longer within your available balance.")
        }
    }
}

struct PaymentReviewSheet: View {
    let draft: PaymentDraft
    let onConfirm: () -> Void

    @State private var isProcessing = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Review Payment").font(.title.bold())
            LabeledContent("Recipient", value: draft.recipient)
            LabeledContent("Amount", value: Money.display(draft.amountPaise))

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
            LabeledContent("Version", value: "Lesson 3.4 demo")
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
// ↑↑↑ This real ContentView IS the complete Lesson 3.4 code. ↑↑↑

