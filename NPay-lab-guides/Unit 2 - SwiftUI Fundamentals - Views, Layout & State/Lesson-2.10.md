# Lesson 2.10 — ForEach, Identity & Lists

*Unit 2 · SwiftUI Fundamentals — Views, Layout & State*

---

## Concept 1 of 7 — ForEach (no for-loops in views)

> 🔑 Use ForEach (a view), not a `for` loop, to build rows from a collection; each row needs an identity.  

**Key points**

- Naive attempt FAILS — a plain `for` isn't allowed in a view.
- The tool is ForEach — a VIEW that turns a collection into one child view per element.
- Why `id: \.self`? ForEach must give each row an IDENTITY.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    let transactions = ["Coffee Shop", "Electricity Bill", "Salary Credit"]
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(transactions, id: \.self) { t in
                Text(t)
            }
        }
        .padding()
    }
}

#Preview { ContentView() }
```

---

## Concept 2 of 7 — what ForEach IS (generic view)

> 🔑 ForEach is a generic `View<Data, ID, Content>` that tracks each element's identity — not a runtime for-loop.  

**Key points**

- Three generic parameters:
    - `Data    — the collection you pass    (e.g. [String], [Transaction])`
    - `ID      — the identity type          (e.g. String, UUID)`
    - `Content — the view made per element   (e.g. Text, TransactionRow)`
- It's a VIEW that REPRESENTS a collection of child views plus their identities — SwiftUI holds onto those identities to tell rows apart across updates.
- It produces child DESCRIPTIONS; it does not, by itself, scroll or lazily load.
- `print(type(of: ForEach(items, id: \.self){ Text($0) }))` shows the full `ForEach<Data, ID, Content>` — handy proof that the identity type is baked into the type at compile time.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    let transactions = ["Coffee Shop", "Electricity Bill", "Salary Credit"]
    var body: some View {
        let list = ForEach(transactions, id: \.self) { Text($0) }
        let _ = print(type(of: list))
        // ForEach<Array<String>, String, Text>
        return VStack(alignment: .leading, spacing: 8) { list }
            .padding()
    }
}

#Preview { ContentView() }
```

---

## Concept 3 of 7 — Transaction model + Identifiable

> 🔑 Model carries its own `id`; conform to Identifiable so ForEach uses it automatically (drop `id: \.self`).  

**Key points**

- Why a dedicated `id`? Identity should represent the transaction ITSELF, not its displayed text.
- Conform to Identifiable — Swift's protocol for "I have an id":
    - }
    - Now ForEach can find the identity automatically — no id: needed:
    - ForEach(transactions) { t in TransactionRow(transaction: t) }
    - `// vs the earlier  ForEach(transactions, id: \.self) { ... }`
- Identifiable just REQUIRES an `id` property (any Hashable type).
- `let id = UUID()` as a DEFAULT means a fresh stable id is made once per instance, and callers can omit it:
    - (From a backend, use the SERVER's id instead — see C4.)

**Complete runnable file**

```swift
import SwiftUI

struct Transaction: Identifiable {
    let id = UUID()
    let title: String
    let amount: Int
    let date: String
}

struct ContentView: View {
    let transactions = [
        Transaction(title: "Coffee Shop", amount: -250, date: "Today"),
        Transaction(title: "Electricity Bill", amount: -1200, date: "Yesterday"),
        Transaction(title: "Salary Credit", amount: 45000, date: "22 Oct"),
    ]
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(transactions) { t in        // no id: needed
                Text(t.title)
            }
        }
        .padding()
    }
}

#Preview { ContentView() }
```

---

## Concept 4 of 7 — stable identity in action

> 🔑 Identify dynamic rows by a STABLE model id (Identifiable). Index-as-id and computed-UUID-as-id both break on insert/reorder.  

**Key points**

- ✅ STABLE model id (Identifiable): identity travels WITH the item.
- ❌ ARRAY INDEX as id: identity = position. Insert at the top and every index shifts → SwiftUI thinks each row "became" a different item → per-row state lands on the WRONG row.
- ❌ COMPUTED UUID() in the id: a NEW id every read → identity is never stable → rows look brand-new every update (state lost, janky animations).
- The live demo proves it: each row has its own @State "marked" flag (tap to highlight).
- If rows come from an API, decode the backend's transaction id into `id`.

**Complete runnable file (the lesson's full app)**

```swift
import SwiftUI

struct Transaction: Identifiable {
    let id = UUID()
    let title: String
    let amount: Int
    let date: String
}

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "creditcard")
                .font(.title2)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.title).font(.headline)
                Text(transaction.date).font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            Text(transaction.amount, format: .currency(code: "INR")
                                              .precision(.fractionLength(0)))
                .font(.subheadline.bold())
                .foregroundStyle(transaction.amount >= 0 ? .green : .primary)
        }
        .padding(.vertical, 8)
    }
}

struct TransactionHistory: View {
    let transactions: [Transaction]       // display-only → a value

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

struct ContentView: View {
    @State private var balance = 25000
    @State private var transactions = [
        Transaction(title: "Coffee Shop", amount: -250, date: "Today"),
        Transaction(title: "Electricity Bill", amount: -1200, date: "Yesterday"),
        Transaction(title: "Salary Credit", amount: 45000, date: "22 Oct"),
    ]

    var body: some View {
        // ⭐️ Final Lesson 2.10 code — Milestone 2.10 (dynamic history)
        ScrollView {
            VStack(spacing: 24) {

                Text("NPay")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.blue)

                BalanceCard(balance: balance)
                BalanceEditor(balance: $balance)

                HStack(spacing: 12) {
                    QuickAction(symbol: "arrow.up.right", title: "Send") {
                        print("Send tapped")
                    }
                    QuickAction(symbol: "arrow.down.left", title: "Request") {
                        print("Request tapped")
                    }
                    QuickAction(symbol: "clock", title: "History") {
                        print("History tapped")
                    }
                }

                Button("Add Demo Transaction") {
                    addDemoTransaction()
                }
                .buttonStyle(.borderedProminent)

                TransactionHistory(transactions: transactions)
            }
            .padding()
        }
    }

    private func addDemoTransaction() {
        transactions.insert(
            Transaction(title: "Mobile Recharge", amount: -399, date: "Today"),
            at: 0
        )
    }
}

struct BalanceCard: View {
    let balance: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available Balance").font(.subheadline)
            Text(balance, format: .currency(code: "INR")
                                    .precision(.fractionLength(0)))
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
                Button("− ₹1,000") { balance = max(0, balance - 1000) }
                    .buttonStyle(.bordered)
                Button("+ ₹1,000") { balance += 1000 }
                    .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .background(Color.blue.opacity(0.08),
                    in: RoundedRectangle(cornerRadius: 20))
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
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.blue)
        .background(Color.blue.opacity(0.08),
                    in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ContentView()
}
// ↑↑↑ This real ContentView IS the complete Lesson 2.10 code (so far). ↑↑↑
```

---

## Concept 5 of 7 — ForEach vs List (eager vs lazy)

> 🔑 ForEach builds rows (eager by default); List is a lazy, full-featured scrolling container. Container decides laziness.  

**Key points**

- VStack { ForEach(...) }  — EAGER. The VStack builds ALL row descriptions up front.
- List { ... } — a higher-level scrolling container made for collections.
- LazyVStack — a VStack that builds rows lazily, for when you want ScrollView control without List's styling:
    - (Measured in the deck for 1,000 rows: eager VStack built 1,000
    - row bodies; LazyVStack ~12; List ~9. Laziness = big win.)
- Key nuance: ForEach itself is NOT lazy. The CONTAINER decides:
    - `VStack / HStack  → eager`
    - `List / LazyVStack / LazyHStack → lazy`
- Why NPay uses ForEach-in-VStack (for now): our screen is one big ScrollView with a header, card, editor, actions, THEN the history.
- List brings its own scrolling, so it wants to own the screen (or a clear region) — don't bury it inside another ScrollView.

**Complete runnable file**

```swift
import SwiftUI

struct Transaction: Identifiable {
    let id = UUID(); let title: String
}

struct ContentView: View {
    let transactions = [
        Transaction(title: "Coffee Shop"),
        Transaction(title: "Electricity Bill"),
        Transaction(title: "Salary Credit"),
    ]
    var body: some View {
        // A List: lazy, scrolls, platform row styling — for free.
        List(transactions) { t in
            Text(t.title)
        }
    }
}

#Preview { ContentView() }
```

---

## Concept 6 of 7 — TransactionRow + TransactionHistory

> 🔑 Split into TransactionRow (one row) + TransactionHistory (the list section); display-only → pass a value, not a binding.  

**Key points**

- TransactionRow — presentation for ONE transaction.
- TransactionHistory — the section that lists them.
- Why `let transactions` (not @Binding)? This view only DISPLAYS — it never edits the array.
- `TransactionRow + Divider` inside ForEach means the LAST row also gets a divider underneath.

**Complete runnable file**

```swift
import SwiftUI

struct Transaction: Identifiable {
    let id = UUID(); let title: String; let amount: Int; let date: String
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
            Text(transaction.amount, format: .currency(code: "INR")
                                               .precision(.fractionLength(0)))
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

struct ContentView: View {
    let transactions = [
        Transaction(title: "Coffee Shop", amount: -250, date: "Today"),
        Transaction(title: "Electricity Bill", amount: -1200, date: "Yesterday"),
        Transaction(title: "Salary Credit", amount: 45000, date: "22 Oct"),
    ]
    var body: some View {
        TransactionHistory(transactions: transactions).padding()
    }
}

#Preview { ContentView() }
```

---

## Concept 7 of 7 — dynamic transactions (Milestone)

> ⭐️ MILESTONE 2.10 — NPay dashboard with a dynamic history.  
> 🔑 Hold the collection in @State; mutate the array → ForEach updates, rows keyed by stable id move/insert correctly.  

**Key points**

- Hold the array in @State so it can change.
- A button that INSERTS a new transaction at the top.
- Full dashboard = everything so far in one ScrollView: header, BalanceCard (value), BalanceEditor ($binding), QuickActions (closures), the Add button, and TransactionHistory (value).
- Design note: Add Demo Transaction does NOT subtract from the balance — editor and history are independent demos for now.
- You change the list by mutating the array in place (insert/remove/append/sort) — @State notices and re-renders.

**Complete runnable file (the lesson's full app)**

```swift
import SwiftUI

struct Transaction: Identifiable {
    let id = UUID()
    let title: String
    let amount: Int
    let date: String
}

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "creditcard")
                .font(.title2)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.title).font(.headline)
                Text(transaction.date).font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            Text(transaction.amount, format: .currency(code: "INR")
                                              .precision(.fractionLength(0)))
                .font(.subheadline.bold())
                .foregroundStyle(transaction.amount >= 0 ? .green : .primary)
        }
        .padding(.vertical, 8)
    }
}

struct TransactionHistory: View {
    let transactions: [Transaction]       // display-only → a value

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

struct ContentView: View {
    @State private var balance = 25000
    @State private var transactions = [
        Transaction(title: "Coffee Shop", amount: -250, date: "Today"),
        Transaction(title: "Electricity Bill", amount: -1200, date: "Yesterday"),
        Transaction(title: "Salary Credit", amount: 45000, date: "22 Oct"),
    ]

    var body: some View {
        // ⭐️ Final Lesson 2.10 code — Milestone 2.10 (dynamic history)
        ScrollView {
            VStack(spacing: 24) {

                Text("NPay")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.blue)

                BalanceCard(balance: balance)
                BalanceEditor(balance: $balance)

                HStack(spacing: 12) {
                    QuickAction(symbol: "arrow.up.right", title: "Send") {
                        print("Send tapped")
                    }
                    QuickAction(symbol: "arrow.down.left", title: "Request") {
                        print("Request tapped")
                    }
                    QuickAction(symbol: "clock", title: "History") {
                        print("History tapped")
                    }
                }

                Button("Add Demo Transaction") {
                    addDemoTransaction()
                }
                .buttonStyle(.borderedProminent)

                TransactionHistory(transactions: transactions)
            }
            .padding()
        }
    }

    private func addDemoTransaction() {
        transactions.insert(
            Transaction(title: "Mobile Recharge", amount: -399, date: "Today"),
            at: 0
        )
    }
}

struct BalanceCard: View {
    let balance: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available Balance").font(.subheadline)
            Text(balance, format: .currency(code: "INR")
                                    .precision(.fractionLength(0)))
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
                Button("− ₹1,000") { balance = max(0, balance - 1000) }
                    .buttonStyle(.bordered)
                Button("+ ₹1,000") { balance += 1000 }
                    .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .background(Color.blue.opacity(0.08),
                    in: RoundedRectangle(cornerRadius: 20))
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
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.blue)
        .background(Color.blue.opacity(0.08),
                    in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ContentView()
}
// ↑↑↑ This real ContentView IS the complete Lesson 2.10 code (so far). ↑↑↑
```
