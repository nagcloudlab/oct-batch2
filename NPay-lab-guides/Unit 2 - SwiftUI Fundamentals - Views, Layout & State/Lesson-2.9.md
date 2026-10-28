# Lesson 2.9 — @Binding & One Source of Truth

*Unit 2 · SwiftUI Fundamentals — Views, Layout & State*

---

## Concept 1 of 6 — a child can't change a passed value

> 🔑 Passing a value gives the child a read-only COPY; it can't change the parent's state through it.  

**Key points**

- Naive attempt (DOES NOT COMPILE):
    - with `let` → "'balance' is a 'let' constant"
    - change to `var` → "'self' is immutable" (same wall as 2.8)
- WHY (Unit 1 value semantics): passing an Int passes a COPY.
- So a plain value is a one-way, read-only hand-off.

**Complete runnable file (display-only, works)**

```swift
import SwiftUI

struct ContentView: View {
    @State private var balance = 25000
    var body: some View {
        VStack(spacing: 24) {
            BalanceCard(balance: balance)
            Button("Add Demo ₹1,000") { balance += 1000 }
                .buttonStyle(.borderedProminent)
        }
        .padding()
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

#Preview { ContentView() }
```

---

## Concept 2 of 6 — @Binding — the two-way connection

> 🔑 @Binding = a read/write connection to state owned elsewhere; parent passes $value, child declares @Binding var.  

**Key points**

- Child declares @Binding instead of a plain value.
- Parent passes the BINDING with the $ prefix.
- Now there is ONE balance (owned by ContentView).
- The pairing to memorize.
- @State = "I OWN this state" (creates storage).

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    @State private var balance = 25000
    var body: some View {
        VStack(spacing: 20) {
            Text("Balance: ₹\(balance)").font(.title)
            BalanceEditor(balance: $balance)   // pass a Binding
        }
        .padding()
    }
}

struct BalanceEditor: View {
    @Binding var balance: Int                   // borrow parent's state
    var body: some View {
        Button("Add ₹1,000") { balance += 1000 }
            .buttonStyle(.borderedProminent)
    }
}

#Preview { ContentView() }
```

---

## Concept 3 of 6 — balance vs $balance

> 🔑 No $ = the value (Int); $ = the binding (`Binding<Int>`). Match $ to whether the child declared a value or a @Binding.  

**Key points**

- Use `balance` (no $) when you want the actual number.
- Use `$balance` (with $) when a child needs a two-way handle.
- Matching rule — the $ must match the child's property kind: Mismatch = compiler error ("Cannot convert Int to `Binding<Int>`" or vice-versa).
- Inside the CHILD, note it flips again: e.g. forwarding to a grandchild: GrandChild(balance: $balance)
- $ isn't magic SwiftUI syntax. Any property wrapper can expose a `projectedValue`; writing `$name` returns it.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    @State private var balance = 25000
    var body: some View {
        let _ = print("balance :", type(of: balance))   // Int
        let _ = print("$balance:", type(of: $balance))  // Binding<Int>
        return VStack(spacing: 20) {
            BalanceCard(balance: balance)      // value
            BalanceEditor(balance: $balance)   // binding
        }
        .padding()
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
        Button("Add ₹1,000") { balance += 1000 }
            .buttonStyle(.borderedProminent)
    }
}

#Preview { ContentView() }
```

---

## Concept 4 of 6 — how a Binding works (nonmutating set)

> 🔑 A Binding = get/set closures onto external storage; its `nonmutating set` forwards writes, so a value-type child can change parent state.  

**Key points**

- A Binding does NOT store the value. It stores a `get` (how to read it) and a `set` (how to write it) that point at storage owned ELSEWHERE (the parent's @State).
- The magic word is `nonmutating set`. Normally writing a struct's property needs a mutable struct.
- That's why `balance += 1000` in the child works: it calls the binding's setter → forwards to ContentView's @State → SwiftUI updates everything that reads balance.
    - `→ Binding.wrappedValue setter (nonmutating)` → parent @State storage changes → SwiftUI re-evaluates dependent views (card + editor)
- Takeaway: a Binding is a CONNECTION (read closure + write closure) to state owned elsewhere — it owns nothing itself.
- @State has `= 25000` (it owns storage, needs a starting value).

**Complete runnable file (prove it on the Mac/Playground)**

```swift
import SwiftUI

// A stand-in for SwiftUI's storage:
final class Storage { var value = 25000 }
let storage = Storage()

struct SimpleBinding<Value> {
    let get: () -> Value
    let set: (Value) -> Void
    var wrappedValue: Value {
        get { get() }
        nonmutating set { set(newValue) }
    }
}

// `b` is a LET, yet writing through it changes storage:
let b = SimpleBinding<Int>(get: { storage.value },
                           set: { storage.value = $0 })
b.wrappedValue += 1000
print(storage.value)   // 26000  ← write forwarded out
```

---

## Concept 5 of 6 — one source of truth

> 🔑 One state, one owner (source of truth); others get a value or a binding. Two @States = two truths that drift apart.  

**Key points**

- Now there are TWO balances: ContentView's and the editor's.
- The rule: a piece of state should have exactly ONE owner — the "source of truth".
- Who should own it? The LOWEST view that is a common ancestor of everyone who needs it.
- Decide access per child: Don't hand out a binding "just in case" — give the least access needed.
- If two sibling views need to share state, you "lift" the state up to their common parent and pass values/bindings down.

**Complete runnable file (shows the WRONG design)**

```swift
import SwiftUI

struct ContentView: View {
    @State private var balance = 25000
    var body: some View {
        VStack(spacing: 20) {
            Text("Parent sees: ₹\(balance)").font(.title2)
            BadEditor()        // has its OWN @State → diverges
        }
        .padding()
    }
}

struct BadEditor: View {
    @State private var balance = 25000     // ❌ second source of truth
    var body: some View {
        VStack {
            Text("Child sees: ₹\(balance)")
            Button("Add ₹1,000 (child only)") { balance += 1000 }
                .buttonStyle(.borderedProminent)
        }
    }
}

#Preview { ContentView() }
// Tap the button: child climbs, parent stays — they diverge.
```

---

## Concept 6 of 6 — BalanceEditor & integrate (Milestone)

> ⭐️ MILESTONE 2.9 — balance card + editor sharing ONE state.  
> 🔑 One @State owner, a value to the display, a $binding to the editor → both always in sync.  

**Key points**

- ContentView owns @State balance. It passes: Tapping +/− changes the ONE balance; the card follows. ✅.
- max(0, balance - 1000) clamps the demo so it can't go negative.
- Wrapped the screen in a ScrollView — the UI is getting tall and should stay usable on small phones.
- You can build a binding by hand to transform/validate on write.

**Complete runnable file (the lesson's full app)**

```swift
import SwiftUI

struct ContentView: View {
    @State private var balance = 25000       // the ONE source of truth

    var body: some View {
        // ⭐️ Final Lesson 2.9 code — Milestone 2.9
        ScrollView {
            VStack(spacing: 24) {

                Image(systemName: "creditcard.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)

                Text("NPay")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.blue)

                BalanceCard(balance: balance)        // value → display

                BalanceEditor(balance: $balance)     // binding → edit

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
            }
            .padding()
        }
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
                Button("− ₹1,000") {
                    balance = max(0, balance - 1000)   // clamp at 0
                }
                .buttonStyle(.bordered)

                Button("+ ₹1,000") {
                    balance += 1000
                }
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

#Preview {
    ContentView()
}
// ↑↑↑ This real ContentView IS the complete Lesson 2.9 code (so far). ↑↑↑
```
