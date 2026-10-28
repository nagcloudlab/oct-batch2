# Lesson 2.8 — @State — Reactive State

*Unit 2 · SwiftUI Fundamentals — Views, Layout & State*

---

## Concept 1 of 7 — why a normal `var` can't change

> 🔑 A View struct is an immutable UI description; a plain `var` can't be mutated from a button action (self is immutable).  

**Key points**

- Naive attempt (DOES NOT COMPILE):
    - Error: "Left side of mutating operator isn't mutable:
- WHY it fails (connect to Unit 1 value semantics):
    - `body` is a NON-MUTATING computed property, and the button's action is an @escaping closure. Neither is allowed to mutate the struct's own stored properties.
    - So `balance += 1000` tries to mutate an immutable value → error.
- Deeper point: a View isn't a long-lived mutable controller object (like a UIViewController).

**The FAILING example (for reference only)**

```swift
import SwiftUI

struct ContentView: View {
    var balance = 25000
    var body: some View {
        VStack {
            Text("Balance: ₹\(balance)")
            Button("Add ₹1,000") {
                balance += 1000   // ❌ self is immutable
            }
        }
    }
}

#Preview { ContentView() }
```

---

## Concept 2 of 7 — @State — the one-word fix

> 🔑 @State gives a view mutable, framework-managed state; change it and SwiftUI redraws automatically. UI = f(State).  

**Key points**

- Tap the button → the number goes up on screen. We did NOT:
    - call any "refresh" function,
    - manually replace the Text,
    - reload the view.
    - We just changed a property. SwiftUI redrew the affected UI automatically.
- Why it now compiles: @State moves the value OUT of the struct into SwiftUI-managed storage, and exposes a mutable wrapped value.
- Why 'private': the state belongs to THIS view.
- The mental model to burn in: UI = f(State).
- SwiftUI redraws a view when a @State value it actually USES in body changes.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    @State private var balance = 25000
    var body: some View {
        VStack(spacing: 20) {
            Text("Balance: ₹\(balance)").font(.title)
            Button("Add Demo ₹1,000") { balance += 1000 }
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview { ContentView() }
```

---

## Concept 3 of 7 — what @State IS (three forms)

> 🔑 One @State gives three forms: balance (Int), _balance (`State<Int>`), $balance (`Binding<Int>` — a shareable handle).  

**Key points**

- balance  — what you read/write normally (Text("\(balance)"),.
- _balance — the underlying `State<Int>` storage box.
- $balance — a `Binding<Int>`: a two-way "handle" to the same.
- Picture it.
- Pass the VALUE (balance) when a child only needs to DISPLAY it.
- Pass the BINDING ($balance) when a child needs to CHANGE it.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    @State private var balance = 25000
    var body: some View {
        // Prints the three types to the console:
        //   Int
        //   State<Int>
        //   Binding<Int>
        let _ = print(type(of: balance))
        let _ = print(type(of: _balance))
        let _ = print(type(of: $balance))
        return Text("Balance: ₹\(balance)").font(.title)
    }
}

#Preview { ContentView() }
```

---

## Concept 4 of 7 — build your OWN property wrapper

> 🔑 @State is just a property wrapper: wrappedValue is `balance`, the backing instance is `_balance`, projectedValue is `$balance`.  

**Key points**

- A @propertyWrapper is a struct with a `wrappedValue` get/set.
- Map back to @State: same transformation, but State's wrappedValue talks to SwiftUI-managed storage and, on set, tells SwiftUI "this changed → re-evaluate dependents".
- A wrapper can also define `var projectedValue: ...`.

**Complete runnable file  (run the wrapper demo in console)**

```swift
import SwiftUI

@propertyWrapper
struct NonNegative {
    private var storage: Int
    var wrappedValue: Int {
        get { storage }
        set { storage = max(0, newValue) }
    }
    init(wrappedValue: Int) { storage = max(0, wrappedValue) }
}

struct Account { @NonNegative var balance = 25000 }

struct ContentView: View {
    var body: some View {
        var a = Account()
        a.balance = -500
        let _ = print("clamped balance:", a.balance)  // 0
        return Text("See console: clamped to \(a.balance)")
    }
}

#Preview { ContentView() }
```

---

## Concept 5 of 7 — where @State lives (identity)

> 🔑 @State lives in SwiftUI storage keyed to view IDENTITY (not in the struct); the "= value" is the one-time initial value.  

**Key points**

- Because @State is NOT stored inside the struct.
- So "= 25000" is the INITIAL value used ONCE when SwiftUI first establishes storage for that identity — NOT an assignment that runs every time body is evaluated.
- Analogies.
- Reminder of the model: UI = f(State). State lives on; the struct is recomputed around it.
- NOT persistence: @State is in-memory only. If the app is killed, it's gone.
- Put `let _ = Self._printChanges()` at the top of body.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    @State private var balance = 25000
    var body: some View {
        let _ = Self._printChanges()   // see WHY body re-ran
        return VStack(spacing: 20) {
            Text("Balance: ₹\(balance)").font(.title)
            Button("Add ₹1,000") { balance += 1000 }
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview { ContentView() }
```

---

## Concept 6 of 7 — when @State RESETS (identity)

> 🔑 State is tied to IDENTITY, not the struct: stable identity (same tree slot / same .id / same item id) → state survives; identity change or leaving the tree → state resets.  

**Key points**

- Force a new identity with .id(...). Change the id value and SwiftUI treats it as a brand-new view → its @State reinits.
- Demo: tap Increment to raise the count, then tap "Replace Identity" (which sets identity = UUID()).
- Identity = SwiftUI's answer to "same view as before, or a new one?" across updates. State is attached to that answer. Two sources:
    1. STRUCTURAL identity (default) = the view's ROLE/SLOT in the view TREE ("the child of this VStack"). Not pixels!
    2. EXPLICIT identity = .id(value) — you override it.
- Recreating the STRUCT value does NOT lose state (that happens constantly).
- Tree position ≠ screen position. A view can slide / animate / resize / move across the screen and KEEP its state — pixels changing never changes identity.
- A List/ForEach doesn't use position for rows (positions shift on add/remove).
- Diffing by id on changes:
    - `insert  → new id      → new row, fresh state`
    - `remove  → id gone     → row destroyed`
    - `reorder → same ids    → rows MOVE, state travels WITH the item`
    - `mutate  → same id     → same row, just redraws`
- Bug: unstable ids (id: \.self on dup/reorderable values, or array INDEX as id) reassign identities on change → state lands on the WRONG row (expanded rows collapse, fields show wrong data).
- A plain display row (just `let item` → draws) owns NO state — it's data → pixels; nothing to preserve or reset.
- Identity/id correctness only MATTERS when a row owns @State (e.g.
- NEVER write .id(UUID()) inline in body. A fresh UUID each body evaluation = a new identity every update = state wiped and the view rebuilt constantly (lost scroll position, reset fields, broken animations).

**Complete runnable file**

```swift
import SwiftUI

struct CounterView: View {
    @State private var count = 0
    var body: some View {
        VStack(spacing: 16) {
            Text("Count: \(count)").font(.title)
            Button("Increment") { count += 1 }
                .buttonStyle(.bordered)
        }
    }
}

struct ContentView: View {
    @State private var identity = UUID()
    var body: some View {
        VStack(spacing: 30) {
            CounterView()
                .id(identity)      // identity change → counter resets
            Button("Replace Identity") { identity = UUID() }
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview { ContentView() }
```

---

## Concept 7 of 7 — wire @State into NPay (Milestone)

> ⭐️ MILESTONE 2.8 — NPay's balance is state-driven and reactive.  
> 🔑 Parent owns @State (source of truth); children receive values (one-way data flow): data down, events up.  

**Key points**

- WHO owns the balance? ContentView — because it coordinates both the display (BalanceCard) and the button that changes it.
- BalanceCard does NOT own state — it RECEIVES a value to show.
- The loop (one-way data flow)
- Nicer number formatting than "₹\(balance)"
- State belongs to the nearest view that needs to COORDINATE all the pieces that use it.
- Real apps: a demo balance is fine as @State, but a REAL balance comes from a trusted backend via a ViewModel — never trust a locally-incremented number as money.

**Complete runnable file (the lesson's full app)**

```swift
import SwiftUI

struct ContentView: View {
    // Single source of truth for the balance.
    @State private var balance = 25000

    var body: some View {
        // ⭐️ Final Lesson 2.8 code — Milestone 2.8 (reactive balance)
        VStack(spacing: 24) {

            Image(systemName: "creditcard.fill")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text("NPay")
                .font(.largeTitle.bold())
                .foregroundStyle(.blue)

            Text("Payments made simple")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            BalanceCard(balance: balance)        // passes the VALUE down

            Button("Add Demo ₹1,000") {
                balance += 1000                  // change state → UI updates
            }
            .buttonStyle(.borderedProminent)

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

struct BalanceCard: View {
    let balance: Int                             // read-only input (no @State)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available Balance")
                .font(.subheadline)

            Text(balance, format: .currency(code: "INR")
                                    .precision(.fractionLength(0)))
                .font(.largeTitle.bold())

            Text("NPay Demo Account")
                .font(.caption)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(.blue, in: RoundedRectangle(cornerRadius: 20))
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
// ↑↑↑ This real ContentView IS the complete Lesson 2.8 code (so far). ↑↑↑
```
