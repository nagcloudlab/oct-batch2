# Lesson 2.12 — The Complete Payment Flow (Unit 2 Finale)

*Unit 2 · SwiftUI Fundamentals — Views, Layout & State*

---

## Concept 1 of 6 — the integration problem

> 🔑 The form REQUESTS a payment via an onSend closure; the PARENT (state owner) processes it. Data down, events up.  

**Key points**

- The problem of OWNERSHIP:
    - PaymentForm owns the INPUT (recipient, amountText).
    - ContentView owns the STATE (balance, transactions).
- The fix (same tool as the Button lesson 2.7): a CLOSURE.
- This is the whole unit's architecture in one line: DATA flows DOWN (balance → form to validate), EVENTS flow UP (onSend → parent to process).
- Why not do it all inside PaymentForm? The form's job is collect input + show validation.

**Complete runnable file (skeleton of the wiring)**

```swift
import SwiftUI

struct ContentView: View {
    @State private var balance = 25000
    var body: some View {
        VStack(spacing: 16) {
            Text("Balance: ₹\(balance)").font(.title2)
            // Parent passes state DOWN and an action UP:
            PaymentForm(availableBalance: balance) { amount in
                guard amount > 0, amount <= balance else { return false }
                balance -= amount        // PARENT mutates its own state
                return true
            }
        }
        .padding()
    }
}

struct PaymentForm: View {
    let availableBalance: Int
    let onSend: (Int) -> Bool           // the action contract
    @State private var amountText = ""
    var body: some View {
        HStack {
            TextField("Amount", text: $amountText)
                .textFieldStyle(.roundedBorder)
            Button("Send") {
                if let amt = Int(amountText), onSend(amt) { amountText = "" }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview { ContentView() }
```

---

## Concept 2 of 6 — money as integer paise

> 🔑 Store money as integer paise (exact); centralise formatting & safe parsing in a Money helper (parse returns Int?, never crashes).  

**Key points**

- Why paise (Int), not rupees as Double?
    - `Double can't represent 0.1 exactly → rounding bugs on money.`
- A small Money helper centralises formatting + parsing:
    - }
- parsePaise is the SAFE converter (never force-unwrap user text):
    - `1. regex check  ^[0-9]+(\.[0-9]{1,2})?$   (syntax)`
    - `2. split on "." → rupees + fraction (padded to 2 digits)`
    3. rupees * 100 + paise, using multiply/addReportingOverflow → returns nil on bad syntax OR Int overflow
- It returns Int? — nil means "reject this input".
- The model stores paise (data); Money.display turns it into a locale-aware string (presentation).

**Complete runnable file**

```swift
import SwiftUI

enum Money {
    static func display(_ paise: Int) -> String {
        (Decimal(paise) / 100).formatted(
            .currency(code: "INR").locale(Locale(identifier: "en_IN")))
    }
    static func parsePaise(_ text: String) -> Int? {
        let pattern = #"^[0-9]+(\.[0-9]{1,2})?$"#
        guard text.range(of: pattern, options: .regularExpression) != nil
        else { return nil }
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

struct ContentView: View {
    @State private var amountText = ""
    var body: some View {
        VStack(spacing: 12) {
            TextField("Amount (₹)", text: $amountText)
                .textFieldStyle(.roundedBorder)
            let paise = Money.parsePaise(amountText)
            Text(paise == nil ? "invalid"
                              : "\(paise!) paise = \(Money.display(paise!))")
        }
        .padding()
    }
}

#Preview { ContentView() }
```

---

## Concept 3 of 6 — Transaction (amountPaise + Date)

> 🔑 Model stores facts (amountPaise: Int, date: Date); the view formats them. Don't bake presentation strings into the model.  

**Key points**

- amountPaise: Int — same exact-money reasoning as the balance.
- date: Date (not String) — store the real moment; FORMAT it in the view.
- Format at display time with Date's formatted API: and the amount with our helper.
- This is the DOMAIN vs PRESENTATION split again: the model holds facts (paise, Date); the row decides how they LOOK.
- Use Date() / .now for "created now". Real transactions carry the server's timestamp; our mock data uses .now for simplicity.

**Complete runnable file**

```swift
import SwiftUI

struct Transaction: Identifiable {
    let id = UUID()
    let title: String
    let amountPaise: Int
    let date: Date
}

enum Money {
    static func display(_ paise: Int) -> String {
        (Decimal(paise) / 100).formatted(
            .currency(code: "INR").locale(Locale(identifier: "en_IN")))
    }
}

struct ContentView: View {
    let transactions = [
        Transaction(title: "Coffee Shop", amountPaise: -25_000, date: .now),
        Transaction(title: "Salary Credit", amountPaise: 4_500_000, date: .now),
    ]
    var body: some View {
        List(transactions) { t in
            HStack {
                Text(t.title)
                Spacer()
                Text(t.date, format: .dateTime.day().month(.abbreviated))
                    .foregroundStyle(.secondary)
                Text(Money.display(t.amountPaise)).bold()
            }
        }
    }
}

#Preview { ContentView() }
```

---

## Concept 4 of 6 — sendDemoPayment (the operation)

> 🔑 The state owner validates then mutates balance + transactions together, returning Bool; the form just requests via onSend.  

**Key points**

- Three steps: VALIDATE (trim, >0, ≤ balance) → DEDUCT balance → INSERT a new transaction at the top.
- The parent re-validates even though the form did too.
- Both @State mutations (balance and transactions) happen in ONE synchronous call, so the UI never shows a half-updated state.
- A statusMessage (@State String?) gives the user feedback ("Demo payment recorded." / "Invalid payment request.").
- Wire the form to it (the closure from C1, now with recipient)
- The form can't be trusted with the rule "≤ balance" — it only RECEIVES the balance to hint the UI.

**Complete runnable file (the lesson's full app)**

```swift
import SwiftUI

struct Transaction: Identifiable {
    let id = UUID()
    let title: String
    let amountPaise: Int          // paise, negative = debit
    let date: Date                // real Date, formatted in the view
}

enum Money {
    // paise → locale-aware currency string, e.g. 2_500_000 → "₹25,000.00"
    static func display(_ paise: Int) -> String {
        (Decimal(paise) / 100).formatted(
            .currency(code: "INR").locale(Locale(identifier: "en_IN")))
    }

    // "1500" → 150000 paise; nil if syntax is wrong or it overflows Int.
    static func parsePaise(_ text: String) -> Int? {
        let pattern = #"^[0-9]+(\.[0-9]{1,2})?$"#
        guard text.range(of: pattern, options: .regularExpression) != nil
        else { return nil }

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

struct ContentView: View {
    @State private var balancePaise = 2_500_000      // ₹25,000
    @State private var transactions: [Transaction] = [
        Transaction(title: "Coffee Shop", amountPaise: -25_000, date: .now),
        Transaction(title: "Electricity Bill", amountPaise: -120_000, date: .now),
        Transaction(title: "Salary Credit", amountPaise: 4_500_000, date: .now),
    ]
    @State private var statusMessage: String?

    var body: some View {
        // ⭐️ Final Lesson 2.12 code — complete NPay payment flow
        ScrollView {
            VStack(spacing: 24) {

                VStack(spacing: 8) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 44)).foregroundStyle(.blue)
                    Text("NPay").font(.largeTitle.bold()).foregroundStyle(.blue)
                    Text("Payments made simple")
                        .font(.subheadline).foregroundStyle(.secondary)
                }

                BalanceCard(balancePaise: balancePaise)
                BalanceEditor(balancePaise: $balancePaise)

                HStack(spacing: 12) {
                    QuickAction(symbol: "arrow.up.right", title: "Send") {
                        statusMessage = "Use the form below to send."
                    }
                    QuickAction(symbol: "arrow.down.left", title: "Request") {
                        statusMessage = "Request feature coming soon."
                    }
                    QuickAction(symbol: "clock", title: "History") {
                        statusMessage = "Scroll down for history."
                    }
                }

                PaymentForm(availableBalancePaise: balancePaise) { recipient, amountPaise in
                    sendDemoPayment(to: recipient, amountPaise: amountPaise)
                }

                if let statusMessage {
                    Text(statusMessage).font(.caption).foregroundStyle(.secondary)
                }

                TransactionHistory(transactions: transactions)
            }
            .padding()
        }
    }

    private func sendDemoPayment(to recipient: String, amountPaise: Int) -> Bool {
        let name = recipient.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, amountPaise > 0, amountPaise <= balancePaise else {
            statusMessage = "Invalid payment request."
            return false
        }
        balancePaise -= amountPaise
        transactions.insert(
            Transaction(title: "Sent to \(name)", amountPaise: -amountPaise, date: .now),
            at: 0)
        statusMessage = "Demo payment recorded."
        return true
    }
}

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

struct BalanceEditor: View {
    @Binding var balancePaise: Int
    var body: some View {
        VStack(spacing: 12) {
            Text("Demo Balance Editor")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 12) {
                Button("− ₹1,000") { balancePaise = max(0, balancePaise - 100_000) }
                    .buttonStyle(.bordered)
                Button("+ ₹1,000") { balancePaise += 100_000 }
                    .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))
    }
}

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
        .foregroundStyle(.blue)
        .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: transaction.amountPaise >= 0
                  ? "arrow.down.left" : "arrow.up.right")
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

struct TransactionHistory: View {
    let transactions: [Transaction]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Transactions").font(.headline)
            if transactions.isEmpty {
                Text("No transactions yet.")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(transactions) { t in
                    TransactionRow(transaction: t)
                    Divider()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PaymentForm: View {
    let availableBalancePaise: Int
    let onSend: (String, Int) -> Bool        // recipient, amountPaise → accepted?

    @State private var recipient = ""
    @State private var amountText = ""
    @FocusState private var focusedField: Field?

    enum Field: Hashable { case recipient, amount }

    private var parsedAmount: Int? { Money.parsePaise(amountText) }

    private var isValid: Bool {
        !recipient.trimmingCharacters(in: .whitespaces).isEmpty
        && (parsedAmount.map { $0 > 0 && $0 <= availableBalancePaise } ?? false)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Send Money · Demo").font(.headline)

            TextField("Recipient ID (e.g. ravi@npay)", text: $recipient)
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
                guard let amountPaise = parsedAmount else { return }
                if onSend(recipient, amountPaise) {     // ask the parent
                    recipient = ""; amountText = ""     // clear on success
                    focusedField = nil
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isValid)
        }
        .padding()
        .background(Color.blue.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
            }
        }
    }
}

#Preview {
    ContentView()
}
// ↑↑↑ This real ContentView IS the complete Lesson 2.12 code. ↑↑↑
```

---

## Concept 5 of 6 — the final PaymentForm

> 🔑 PaymentForm emits (recipient, amountPaise) via onSend -> Bool and clears only on success; it owns input, not money.  

**Key points**

- onSend: (String, Int) -> Bool — recipient + amount IN PAISE, returns whether the parent accepted it.
- parsedAmount uses Money.parsePaise (C2) — the SAME safe parser the parent trusts. isValid combines: non-empty recipient AND a positive amount within balance.
- Clear the fields ONLY when onSend returns true — a rejected payment keeps the user's input so they can fix it.
- Everything from 2.11 carries over: focus, Next/Done, keyboard toolbar, the red validation caption, .disabled(!isValid).
- PaymentForm knows NOTHING about balances, transactions, or NPay specifics — only "collect input, validate shape, emit a request." You could drop it into another screen with a different onSend.

**Complete runnable file (the lesson's full app)**

```swift
import SwiftUI

struct Transaction: Identifiable {
    let id = UUID()
    let title: String
    let amountPaise: Int          // paise, negative = debit
    let date: Date                // real Date, formatted in the view
}

enum Money {
    // paise → locale-aware currency string, e.g. 2_500_000 → "₹25,000.00"
    static func display(_ paise: Int) -> String {
        (Decimal(paise) / 100).formatted(
            .currency(code: "INR").locale(Locale(identifier: "en_IN")))
    }

    // "1500" → 150000 paise; nil if syntax is wrong or it overflows Int.
    static func parsePaise(_ text: String) -> Int? {
        let pattern = #"^[0-9]+(\.[0-9]{1,2})?$"#
        guard text.range(of: pattern, options: .regularExpression) != nil
        else { return nil }

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

struct ContentView: View {
    @State private var balancePaise = 2_500_000      // ₹25,000
    @State private var transactions: [Transaction] = [
        Transaction(title: "Coffee Shop", amountPaise: -25_000, date: .now),
        Transaction(title: "Electricity Bill", amountPaise: -120_000, date: .now),
        Transaction(title: "Salary Credit", amountPaise: 4_500_000, date: .now),
    ]
    @State private var statusMessage: String?

    var body: some View {
        // ⭐️ Final Lesson 2.12 code — complete NPay payment flow
        ScrollView {
            VStack(spacing: 24) {

                VStack(spacing: 8) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 44)).foregroundStyle(.blue)
                    Text("NPay").font(.largeTitle.bold()).foregroundStyle(.blue)
                    Text("Payments made simple")
                        .font(.subheadline).foregroundStyle(.secondary)
                }

                BalanceCard(balancePaise: balancePaise)
                BalanceEditor(balancePaise: $balancePaise)

                HStack(spacing: 12) {
                    QuickAction(symbol: "arrow.up.right", title: "Send") {
                        statusMessage = "Use the form below to send."
                    }
                    QuickAction(symbol: "arrow.down.left", title: "Request") {
                        statusMessage = "Request feature coming soon."
                    }
                    QuickAction(symbol: "clock", title: "History") {
                        statusMessage = "Scroll down for history."
                    }
                }

                PaymentForm(availableBalancePaise: balancePaise) { recipient, amountPaise in
                    sendDemoPayment(to: recipient, amountPaise: amountPaise)
                }

                if let statusMessage {
                    Text(statusMessage).font(.caption).foregroundStyle(.secondary)
                }

                TransactionHistory(transactions: transactions)
            }
            .padding()
        }
    }

    private func sendDemoPayment(to recipient: String, amountPaise: Int) -> Bool {
        let name = recipient.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, amountPaise > 0, amountPaise <= balancePaise else {
            statusMessage = "Invalid payment request."
            return false
        }
        balancePaise -= amountPaise
        transactions.insert(
            Transaction(title: "Sent to \(name)", amountPaise: -amountPaise, date: .now),
            at: 0)
        statusMessage = "Demo payment recorded."
        return true
    }
}

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

struct BalanceEditor: View {
    @Binding var balancePaise: Int
    var body: some View {
        VStack(spacing: 12) {
            Text("Demo Balance Editor")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 12) {
                Button("− ₹1,000") { balancePaise = max(0, balancePaise - 100_000) }
                    .buttonStyle(.bordered)
                Button("+ ₹1,000") { balancePaise += 100_000 }
                    .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))
    }
}

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
        .foregroundStyle(.blue)
        .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: transaction.amountPaise >= 0
                  ? "arrow.down.left" : "arrow.up.right")
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

struct TransactionHistory: View {
    let transactions: [Transaction]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Transactions").font(.headline)
            if transactions.isEmpty {
                Text("No transactions yet.")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(transactions) { t in
                    TransactionRow(transaction: t)
                    Divider()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PaymentForm: View {
    let availableBalancePaise: Int
    let onSend: (String, Int) -> Bool        // recipient, amountPaise → accepted?

    @State private var recipient = ""
    @State private var amountText = ""
    @FocusState private var focusedField: Field?

    enum Field: Hashable { case recipient, amount }

    private var parsedAmount: Int? { Money.parsePaise(amountText) }

    private var isValid: Bool {
        !recipient.trimmingCharacters(in: .whitespaces).isEmpty
        && (parsedAmount.map { $0 > 0 && $0 <= availableBalancePaise } ?? false)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Send Money · Demo").font(.headline)

            TextField("Recipient ID (e.g. ravi@npay)", text: $recipient)
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
                guard let amountPaise = parsedAmount else { return }
                if onSend(recipient, amountPaise) {     // ask the parent
                    recipient = ""; amountText = ""     // clear on success
                    focusedField = nil
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isValid)
        }
        .padding()
        .background(Color.blue.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
            }
        }
    }
}

#Preview {
    ContentView()
}
// ↑↑↑ This real ContentView IS the complete Lesson 2.12 code. ↑↑↑
```

---

## Concept 6 of 6 — the complete NPay app (FINALE)

> ⭐️ MILESTONE 2.12 — complete local NPay payment flow. UNIT 2 DONE.  
> 🔑 The whole app is UI = f(State): input → validate → mutate state → SwiftUI redraws. Everything else is composition on top.  

**Complete runnable file (the lesson's full app)**

```swift
import SwiftUI

struct Transaction: Identifiable {
    let id = UUID()
    let title: String
    let amountPaise: Int          // paise, negative = debit
    let date: Date                // real Date, formatted in the view
}

enum Money {
    // paise → locale-aware currency string, e.g. 2_500_000 → "₹25,000.00"
    static func display(_ paise: Int) -> String {
        (Decimal(paise) / 100).formatted(
            .currency(code: "INR").locale(Locale(identifier: "en_IN")))
    }

    // "1500" → 150000 paise; nil if syntax is wrong or it overflows Int.
    static func parsePaise(_ text: String) -> Int? {
        let pattern = #"^[0-9]+(\.[0-9]{1,2})?$"#
        guard text.range(of: pattern, options: .regularExpression) != nil
        else { return nil }

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

struct ContentView: View {
    @State private var balancePaise = 2_500_000      // ₹25,000
    @State private var transactions: [Transaction] = [
        Transaction(title: "Coffee Shop", amountPaise: -25_000, date: .now),
        Transaction(title: "Electricity Bill", amountPaise: -120_000, date: .now),
        Transaction(title: "Salary Credit", amountPaise: 4_500_000, date: .now),
    ]
    @State private var statusMessage: String?

    var body: some View {
        // ⭐️ Final Lesson 2.12 code — complete NPay payment flow
        ScrollView {
            VStack(spacing: 24) {

                VStack(spacing: 8) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 44)).foregroundStyle(.blue)
                    Text("NPay").font(.largeTitle.bold()).foregroundStyle(.blue)
                    Text("Payments made simple")
                        .font(.subheadline).foregroundStyle(.secondary)
                }

                BalanceCard(balancePaise: balancePaise)
                BalanceEditor(balancePaise: $balancePaise)

                HStack(spacing: 12) {
                    QuickAction(symbol: "arrow.up.right", title: "Send") {
                        statusMessage = "Use the form below to send."
                    }
                    QuickAction(symbol: "arrow.down.left", title: "Request") {
                        statusMessage = "Request feature coming soon."
                    }
                    QuickAction(symbol: "clock", title: "History") {
                        statusMessage = "Scroll down for history."
                    }
                }

                PaymentForm(availableBalancePaise: balancePaise) { recipient, amountPaise in
                    sendDemoPayment(to: recipient, amountPaise: amountPaise)
                }

                if let statusMessage {
                    Text(statusMessage).font(.caption).foregroundStyle(.secondary)
                }

                TransactionHistory(transactions: transactions)
            }
            .padding()
        }
    }

    private func sendDemoPayment(to recipient: String, amountPaise: Int) -> Bool {
        let name = recipient.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, amountPaise > 0, amountPaise <= balancePaise else {
            statusMessage = "Invalid payment request."
            return false
        }
        balancePaise -= amountPaise
        transactions.insert(
            Transaction(title: "Sent to \(name)", amountPaise: -amountPaise, date: .now),
            at: 0)
        statusMessage = "Demo payment recorded."
        return true
    }
}

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

struct BalanceEditor: View {
    @Binding var balancePaise: Int
    var body: some View {
        VStack(spacing: 12) {
            Text("Demo Balance Editor")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 12) {
                Button("− ₹1,000") { balancePaise = max(0, balancePaise - 100_000) }
                    .buttonStyle(.bordered)
                Button("+ ₹1,000") { balancePaise += 100_000 }
                    .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))
    }
}

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
        .foregroundStyle(.blue)
        .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: transaction.amountPaise >= 0
                  ? "arrow.down.left" : "arrow.up.right")
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

struct TransactionHistory: View {
    let transactions: [Transaction]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Transactions").font(.headline)
            if transactions.isEmpty {
                Text("No transactions yet.")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(transactions) { t in
                    TransactionRow(transaction: t)
                    Divider()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PaymentForm: View {
    let availableBalancePaise: Int
    let onSend: (String, Int) -> Bool        // recipient, amountPaise → accepted?

    @State private var recipient = ""
    @State private var amountText = ""
    @FocusState private var focusedField: Field?

    enum Field: Hashable { case recipient, amount }

    private var parsedAmount: Int? { Money.parsePaise(amountText) }

    private var isValid: Bool {
        !recipient.trimmingCharacters(in: .whitespaces).isEmpty
        && (parsedAmount.map { $0 > 0 && $0 <= availableBalancePaise } ?? false)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Send Money · Demo").font(.headline)

            TextField("Recipient ID (e.g. ravi@npay)", text: $recipient)
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
                guard let amountPaise = parsedAmount else { return }
                if onSend(recipient, amountPaise) {     // ask the parent
                    recipient = ""; amountText = ""     // clear on success
                    focusedField = nil
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isValid)
        }
        .padding()
        .background(Color.blue.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
            }
        }
    }
}

#Preview {
    ContentView()
}
// ↑↑↑ This real ContentView IS the complete Lesson 2.12 code. ↑↑↑
```
