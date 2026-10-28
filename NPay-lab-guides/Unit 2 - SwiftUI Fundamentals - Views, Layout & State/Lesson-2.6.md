# Lesson 2.6 — Modifiers & Reusable Views

*Unit 2 · SwiftUI Fundamentals — Views, Layout & State*

---

## Concept 1 of 8 — what a modifier REALLY is

> 🔑 A modifier returns a NEW wrapped view (ModifiedContent), it never mutates the original.  

**Key points**

- A modifier is just a METHOD you call on a view.
- The wrapper's type is `ModifiedContent<Content, Modifier>.`
- It's ordinary Swift METHOD CHAINING: each call's result becomes the receiver of the next call, and the TYPE can grow at each step.
- Not every modifier makes a ModifiedContent wrapper.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        let original = Text("NPay")
        let padded   = original.padding()
        // Console:
        //   Text
        //   ModifiedContent<Text, _PaddingLayout>
        let _ = print(type(of: original))
        let _ = print(type(of: padded))
        return padded
    }
}

#Preview { ContentView() }
```

---

## Concept 2 of 8 — why EVERY view gets .padding()

> 🔑 Shared modifiers live on the View protocol; conform to View = get the whole toolbox.  

**Key points**

- Answer: those modifiers are defined ONCE as methods on the View protocol (in a protocol extension).
- So "conform to View" = "inherit the entire modifier toolbox." Write a modifier once, use it on everything.
- A few modifiers are TYPE-SPECIFIC, not on View:
    - `.keyboardType / .textInputAutocapitalization → TextField`
    - `.resizable → Image`
    - Those live on the specific type, not the shared toolbox.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        // The SAME .padding().background(...) on 3 different
        // view types — all legal because all are Views.
        VStack(spacing: 20) {
            Text("Text")
                .padding().background(.yellow)

            Image(systemName: "star.fill")
                .padding().background(.green)

            HStack { Text("A"); Text("B") }
                .padding().background(.orange)
        }
        .padding()
    }
}

#Preview { ContentView() }
```

---

## Concept 3 of 8 — modifier ORDER (nested wrappers)

> 🔑 Modifiers nest: order = structure. padding→background ≠ background→padding.  

**Key points**

- Think of it as nested wrappers, read inside-out.
- So a modifier chain is NOT a bag of style properties — it's a PIPELINE of transformations.
- Rule of thumb: read top-to-bottom as "do this, THEN wrap the result in the next thing."

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 40) {
            Text("padding → background")
                .padding(24)
                .background(.yellow)

            Text("background → padding")
                .background(.yellow)
                .padding(24)
        }
        .padding()
    }
}

#Preview { ContentView() }
```

---

## Concept 4 of 8 — .frame() sizes the REGION

> 🔑 .frame sizes the REGION around content (not the glyphs); maxWidth: .infinity = "grow to fill".  

**Key points**

- .frame gives the view a LAYOUT REGION of the size you ask for.
- .frame(maxWidth: .infinity) = "you MAY grow up to whatever width the parent offers." It's an unbounded MAX, not a fixed width and not literally infinite.
- Pair it with alignment to place the small content inside the big region.
- .frame(width: 200)     → EXACTLY 200 (rigid).
- .frame(maxWidth: 200)  → UP TO 200 (flexible, can be less).
- .frame(maxWidth: .infinity) → up to whatever parent offers.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 30) {
            // Big region, small text (bordered to see it)
            Text("NPay")
                .frame(width: 200, height: 100)
                .border(.red)

            // Fill width, text centered
            Text("fill width")
                .frame(maxWidth: .infinity)
                .border(.red)

            // Fill width, text hugs leading
            Text("leading")
                .frame(maxWidth: .infinity, alignment: .leading)
                .border(.red)
        }
        .padding()
    }
}

#Preview { ContentView() }
```

---

## Concept 5 of 8 — environment propagation

> 🔑 STYLE modifiers (.font/.foregroundStyle) flow to children via the environment; LAYOUT modifiers (.padding/.frame) stay local.  

**Key points**

- Some modifiers set an ENVIRONMENT value that flows DOWN to descendants.
- A child can OVERRIDE the inherited value for itself:
    - }
    - .foregroundStyle(.white)
    - → first text yellow, second white. Nearest value wins.
- NOT everything propagates. LAYOUT modifiers like .padding and .frame affect ONLY the view they're on — they don't flow to children.
- A component can set DEFAULT styling once at the top (e.g.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 40) {

            // .font on the VStack → both children inherit it
            VStack {
                Text("NPay")
                Text("Payments made simple")
            }
            .font(.title)

            // override: first child wins yellow, second inherits white
            VStack {
                Text("Available Balance").foregroundStyle(.yellow)
                Text("₹25,000")
            }
            .foregroundStyle(.white)
            .padding()
            .background(.blue)   // so white is visible
        }
        .padding()
    }
}

#Preview { ContentView() }
```

---

## Concept 6 of 8 — extract REUSABLE views

> 🔑 Extract recognizable UI into View structs; use them by name, parameterize with stored properties.  

**Key points**

- A reusable view is just a struct conforming to View with a body.
- Parameterize with stored properties (its "inputs")
- Wins: ContentView reads like a summary; each component is testable/previewable alone; change the card once, every use updates.
- You can add MORE than one #Preview per file: Now you can iterate on the card in isolation — faster than rendering the whole screen.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 28) {
            BalanceCard()
            HStack(spacing: 30) {
                QuickAction(symbol: "arrow.up.right", title: "Send")
                QuickAction(symbol: "arrow.down.left", title: "Request")
                QuickAction(symbol: "clock", title: "History")
            }
        }
        .padding()
    }
}

struct BalanceCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available Balance").font(.subheadline)
            Text("₹25,000").font(.largeTitle.bold())
            Text("NPay Demo Account").font(.caption)
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
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: symbol).font(.title2)
            Text(title).font(.caption)
        }
        .foregroundStyle(.blue)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview { ContentView() }
```

---

## Concept 7 of 8 — custom ViewModifier

> 🔑 A custom ViewModifier packages a reusable styling rule; expose it via a View extension so it reads like a built-in modifier.  

**Key points**

- Conform to the ViewModifier protocol; its body receives the content and returns a decorated version:
    - Apply with .modifier(...):
- Make it read like a built-in modifier with a View extension (protocol extension from Unit 1)
- Now the SAME styling rule applies to ANY view — Text, VStack, an image — one consistent "design language", defined once.

**Complete runnable file**

```swift
import SwiftUI

struct NPayCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(Color.blue.opacity(0.08),
                        in: RoundedRectangle(cornerRadius: 16))
    }
}

extension View {
    func npayCardStyle() -> some View { modifier(NPayCardStyle()) }
}

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Recent Transactions").font(.headline).npayCardStyle()
            Text("Rewards").font(.headline).npayCardStyle()
            VStack { Text("Any view"); Text("works") }.npayCardStyle()
        }
        .padding()
    }
}

#Preview { ContentView() }
```

---

## Concept 8 of 8 — assemble the screen (Milestone)

> ⭐️ MILESTONE 2.6 — styled NPay built from reusable components.  
> 🔑 Compose small reusable views into a readable screen.  

**Key points**

- The whole lesson converges here: modifiers compose and nest, style flows via environment, and reusable views + a custom modifier keep it clean and consistent.
- Still no interactivity — tapping does nothing yet.

**Complete runnable file (the lesson's full app)**

```swift
import SwiftUI

// Custom ViewModifier: one reusable styling rule.
struct NPayCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(Color.blue.opacity(0.08),
                        in: RoundedRectangle(cornerRadius: 16))
    }
}

// Expose it like a built-in modifier.
extension View {
    func npayCardStyle() -> some View { modifier(NPayCardStyle()) }
}

struct ContentView: View {

    var body: some View {
        // ⭐️ Final Lesson 2.6 code — Milestone 2.6
        VStack(spacing: 28) {

            Image(systemName: "creditcard.fill")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text("NPay")
                .font(.largeTitle.bold())
                .foregroundStyle(.blue)

            Text("Payments made simple")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            BalanceCard()

            HStack(spacing: 30) {
                QuickAction(symbol: "arrow.up.right", title: "Send")
                QuickAction(symbol: "arrow.down.left", title: "Request")
                QuickAction(symbol: "clock", title: "History")
            }
        }
        .padding()
    }
}

struct BalanceCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available Balance").font(.subheadline)
            Text("₹25,000").font(.largeTitle.bold())
            Text("NPay Demo Account").font(.caption)
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

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: symbol).font(.title2)
            Text(title).font(.caption)
        }
        .foregroundStyle(.blue)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ContentView()
}

#Preview("Card only") {
    BalanceCard()
        .padding()
}
// ↑↑↑ This real ContentView IS the complete Lesson 2.6 code (so far). ↑↑↑
```
