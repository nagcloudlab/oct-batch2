# Lesson 2.11 — TextField, Validation & Focus

*Unit 2 · SwiftUI Fundamentals — Views, Layout & State*

---

## Concept 1 of 6 — TextField needs a Binding

> 🔑 TextField edits state through a Binding — pass `$name` (`Binding<String>`), not `name` (String).  

**Key points**

- A TextField does two things: READ the current value to show it, and WRITE the edited value as the user types.
- That's why it's `text: $name`, not `text: name`.
- No manual updates: type into the field → it writes through the binding → @State changes → any view reading it (like a live "Hello, \(name)") redraws automatically.
- .textFieldStyle(.roundedBorder) gives the familiar bordered box (otherwise it's an unadorned editable line).

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    @State private var name = ""
    var body: some View {
        VStack(spacing: 20) {
            TextField("Enter your name", text: $name)
                .textFieldStyle(.roundedBorder)
            Text("Hello, \(name)")
        }
        .padding()
    }
}

#Preview { ContentView() }
```

---

## Concept 2 of 6 — amounts as String, money as Decimal

> 🔑 Keep the amount field as String while editing; parse to Decimal (never Double) when validating. Parsing is not validation.  

**Key points**

- Why String, not Int/Double, for the field? Mid-typing states are not valid numbers yet: Binding straight to a number would fight the user on every keystroke.
- Parse when needed: (POSIX locale = "." decimal separator, predictable parsing.)
- Use Decimal (or integer minor units like paise), NOT Double, for money.
- Decimal(string:) is LENIENT — it may accept junk: So "it parsed" does NOT mean "it's valid".

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    @State private var amountText = ""
    private var parsed: Decimal? {
        Decimal(string: amountText,
                locale: Locale(identifier: "en_US_POSIX"))
    }
    var body: some View {
        VStack(spacing: 16) {
            TextField("Amount (₹)", text: $amountText)
                .textFieldStyle(.roundedBorder)
            Text("raw text: \"\(amountText)\"")
            Text(parsed == nil ? "parsed: nil"
                               : "parsed: \(parsed! as NSDecimalNumber)")
        }
        .padding()
    }
}

#Preview { ContentView() }
```

---

## Concept 3 of 6 — keyboard configuration (a HINT)

> 🔑 .keyboardType / autocapitalization / autocorrection tune the typing experience — they are HINTS, never a substitute for validation.  

**Key points**

- .keyboardType picks which keyboard appears: .decimalPad, .numberPad, .emailAddress, .default, etc.
- .textInputAutocapitalization(.never) + .autocorrectionDisabled() stop iOS "helpfully" capitalising/correcting IDs & emails.
- CRITICAL: the keyboard is a UX HINT, NOT a validation boundary.
- .keyboardType and .textInputAutocapitalization live on TextField and exist on iOS/iPadOS, NOT macOS.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    @State private var recipient = ""
    @State private var amountText = ""
    var body: some View {
        VStack(spacing: 16) {
            TextField("Recipient ID (e.g. ravi@npay)", text: $recipient)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)

            TextField("Amount (₹)", text: $amountText)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
        }
        .padding()
    }
}

#Preview { ContentView() }
```

---

## Concept 4 of 6 — validation (syntax vs rules)

> 🔑 Validate independently of the keyboard: regex (syntax) + parse + range (business). Drive .disabled from it; it's UX, not security.  

**Key points**

- Client rules for our demo amount:
    - valid positive decimal, ≤ 2 fraction digits
    - greater than 0
    - not more than the available balance
    - }
- Drive the UI from validity: The button auto-enables/disables as the user types — no manual toggling.
- Show gentle feedback only once they've typed something wrong.
- A disabled button stops casual taps but is NOT a security control — never rely on UI-disabled state for money rules.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    @State private var recipient = ""
    @State private var amountText = ""
    let availableBalance = 25000

    private var isValidAmount: Bool {
        let pattern = #"^[0-9]+(\.[0-9]{1,2})?$"#
        guard amountText.range(of: pattern, options: .regularExpression) != nil
        else { return false }
        guard let amount = Decimal(string: amountText,
                                   locale: Locale(identifier: "en_US_POSIX"))
        else { return false }
        return amount > 0 && amount <= Decimal(availableBalance)
    }
    private var isValid: Bool {
        !recipient.trimmingCharacters(in: .whitespaces).isEmpty && isValidAmount
    }

    var body: some View {
        VStack(spacing: 16) {
            TextField("Recipient ID", text: $recipient)
                .textInputAutocapitalization(.never).autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)
            TextField("Amount (₹)", text: $amountText)
                .keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
            if !amountText.isEmpty && !isValidAmount {
                Text("Enter a valid amount within your balance.")
                    .font(.caption).foregroundStyle(.red)
            }
            Button("Continue Demo") { print("ok") }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
        }
        .padding()
    }
}

#Preview { ContentView() }
```

---

## Concept 5 of 6 — @FocusState (focus & keyboard)

> 🔑 @FocusState reads & sets which field is focused; set it to move focus or nil to dismiss; a .keyboard toolbar adds a Done button.  

**Key points**

- @FocusState is a property wrapper like @State, but it binds to the FOCUS of controls.
- READ focus: SwiftUI writes the active field into focusedField.
- .submitLabel(.next) changes the keyboard's return key label; .onSubmit runs when the user hits it → advance to the next field.
- A keyboard toolbar "Done" button to dismiss (the .decimalPad has no return key, so users need an escape)
- ToolbarItemGroup(placement: .keyboard) exists on iOS/visionOS, not macOS (no software keyboard) — the OTHER half of the very first bug we fixed.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    @State private var recipient = ""
    @State private var amountText = ""
    @FocusState private var focusedField: Field?
    enum Field: Hashable { case recipient, amount }

    var body: some View {
        VStack(spacing: 16) {
            TextField("Recipient ID", text: $recipient)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: .recipient)
                .submitLabel(.next)
                .onSubmit { focusedField = .amount }
            TextField("Amount (₹)", text: $amountText)
                .keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: .amount)
        }
        .padding()
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
            }
        }
    }
}

#Preview { ContentView() }
```

---

## Concept 6 of 6 — PaymentForm + integrate (Milestone)

> ⭐️ MILESTONE 2.11 — NPay has a validated payment-entry form.  
> 🔑 PaymentForm owns input/focus, receives the balance to validate; the full path is keyboard → binding → state → validation → UI.  

**Key points**

- It OWNS its own input + focus (@State/@FocusState) — those are local UI concerns.
- .onChange(of:) to observe edits (debugging / reacting): onChange sees VALUE changes (incl. paste) — it is NOT a raw key-press listener.
- The complete input pipeline, end to end:
    - `keyboard → TextField → Binding → @State → validation` → Button .disabled → SwiftUI update
- Still a DEMO: Continue Demo only prints. It does NOT move money or add a transaction.

**Complete runnable file (the lesson's full app)**

```swift
import SwiftUI

struct Transaction: Identifiable {
    let id = UUID()
    let title: String
    let amount: Int
    let date: String
}

struct ContentView: View {
    @State private var balance = 25000
    @State private var transactions = [
        Transaction(title: "Coffee Shop", amount: -250, date: "Today"),
        Transaction(title: "Electricity Bill", amount: -1200, date: "Yesterday"),
        Transaction(title: "Salary Credit", amount: 45000, date: "22 Oct"),
    ]

    var body: some View {
        // ⭐️ Final Lesson 2.11 code — Milestone 2.11 (payment form)
        ScrollView {
            VStack(spacing: 24) {
                Text("NPay")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.blue)

                BalanceCard(balance: balance)
                BalanceEditor(balance: $balance)

                HStack(spacing: 12) {
                    QuickAction(symbol: "arrow.up.right", title: "Send") { print("Send tapped") }
                    QuickAction(symbol: "arrow.down.left", title: "Request") { print("Request tapped") }
                    QuickAction(symbol: "clock", title: "History") { print("History tapped") }
                }

                PaymentForm(availableBalance: balance)   // validates vs balance

                Button("Add Demo Transaction") { addDemoTransaction() }
                    .buttonStyle(.borderedProminent)

                TransactionHistory(transactions: transactions)
            }
            .padding()
        }
    }

    private func addDemoTransaction() {
        transactions.insert(
            Transaction(title: "Mobile Recharge", amount: -399, date: "Today"), at: 0)
    }
}

struct BalanceCard: View {
    let balance: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available Balance").font(.subheadline)
            Text(balance, format: .currency(code: "INR").precision(.fractionLength(0)))
                .font(.largeTitle.bold())
            Text("NPay Demo Account").font(.caption)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(.blue, in: RoundedRectangle(cornerRadius: 20))
    }
}

struct BalanceEditor: View {
    @Binding var balance: Int
    var body: some View {
        VStack(spacing: 12) {
            Text("Demo Balance Editor")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 12) {
                Button("− ₹1,000") { balance = max(0, balance - 1000) }.buttonStyle(.bordered)
                Button("+ ₹1,000") { balance += 1000 }.buttonStyle(.borderedProminent)
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

struct PaymentForm: View {
    let availableBalance: Int

    @State private var recipient = ""
    @State private var amountText = ""
    @FocusState private var focusedField: Field?

    enum Field: Hashable { case recipient, amount }

    private var isValidAmount: Bool {
        let pattern = #"^[0-9]+(\.[0-9]{1,2})?$"#
        guard amountText.range(of: pattern, options: .regularExpression) != nil
        else { return false }
        guard let amount = Decimal(string: amountText,
                                   locale: Locale(identifier: "en_US_POSIX"))
        else { return false }
        return amount > 0 && amount <= Decimal(availableBalance)
    }

    private var isValid: Bool {
        !recipient.trimmingCharacters(in: .whitespaces).isEmpty && isValidAmount
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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
                .onChange(of: amountText) { oldValue, newValue in
                    print("amount:", oldValue, "→", newValue)
                }

            if !amountText.isEmpty && !isValidAmount {
                Text("Enter a valid amount within your balance.")
                    .font(.caption).foregroundStyle(.red)
            }

            Button("Continue Demo") {
                focusedField = nil
                print("Demo payment · Recipient:", recipient, "Amount:", amountText)
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

struct TransactionRow: View {
    let transaction: Transaction
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "creditcard").font(.title2).foregroundStyle(.blue)
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.title).font(.headline)
                Text(transaction.date).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(transaction.amount, format: .currency(code: "INR").precision(.fractionLength(0)))
                .font(.subheadline.bold())
                .foregroundStyle(transaction.amount >= 0 ? .green : .primary)
        }
        .padding(.vertical, 8)
    }
}

struct TransactionHistory: View {
    let transactions: [Transaction]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Transactions").font(.headline)
            ForEach(transactions) { t in
                TransactionRow(transaction: t)
                Divider()
            }
        }
    }
}

#Preview {
    ContentView()
}
// ↑↑↑ This real ContentView IS the complete Lesson 2.11 code. ↑↑↑
```
