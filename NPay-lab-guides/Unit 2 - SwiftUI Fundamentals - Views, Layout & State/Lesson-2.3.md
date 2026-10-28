# Lesson 2.3 — VStack & @ViewBuilder

*Unit 2 · SwiftUI Fundamentals — Views, Layout & State*

---

## Concept 1 of 6 — VStack is a generic STRUCT

> 🔑 VStack is a generic struct; `VStack(...) { }` calls its init.  

**Key points**

- VStack(spacing: 20) { ... } LOOKS like a function call, but VStack is NOT a function.
- A simplified view of its real initializer:
    - Four things to notice:
    1. VStack is a STRUCT (a value type).
    2. `<Content: View>` is a GENERIC parameter — the type of whatever you put inside.
    3. alignment + spacing are ordinary arguments w/ defaults.
    4. content is a CLOSURE marked @ViewBuilder (next concept).
- Because alignment and spacing have DEFAULTS, VStack { ... } with no arguments is legal — you only pass what you need.
- Try it: ⌘-click `VStack` → Jump to Definition → you'll see `@frozen public struct VStack<Content> : View`.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        // VStack is a generic struct; `VStack(...) { }` calls its init.
        VStack(spacing: 20) {
            Text("NPay")
        }
    }
}

#Preview { ContentView() }
```

---

## Concept 2 of 6 — the TRAILING CLOSURE

> 🔑 The { } is the content argument; it returns CHILDREN, not the stack.  

**Key points**

- The init's LAST argument is a closure (content:).
- These two are IDENTICAL.
- KEY idea: the closure does NOT return a VStack.
- If there are NO other arguments, the parens vanish too.
- Trailing closures aren't a SwiftUI invention.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 40) {
            VStack(spacing: 20) { Text("NPay") }              // sugared (trailing closure)
            VStack(spacing: 20, content: { Text("NPay") })    // de-sugared — identical
        }
    }
}

#Preview { ContentView() }
```

---

## Concept 3 of 6 — @ViewBuilder (many views, 1 closure)

> 🔑 @ViewBuilder packs multiple view lines into ONE value (a TupleView).  

**Key points**

- The answer: the content param is marked @ViewBuilder.
- For 2 children, that composite is a TupleView.
- @ViewBuilder is NOT a runtime loop and NOT an array of views.
- Proof: print the type of the stack and read the TupleView (see the print(type(of:)) line in the CODE block below).
- You may hear "a VStack can only hold 10 views." Historically the builder had buildBlock overloads up to 10 params.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        // @ViewBuilder packs the two Texts into ONE value (a TupleView)
        let stack = VStack {
            Text("NPay")
            Text("Payments made simple")
        }
        let _ = print(type(of: stack))   // VStack<TupleView<(Text, Text)>>
        stack
    }
}

#Preview { ContentView() }
```

---

## Concept 4 of 6 — build your OWN result builder

> 🔑 @ViewBuilder is just a @resultBuilder — you can build one yourself.  

**Key points**

- @resultBuilder is the Swift LANGUAGE feature.
- A result builder needs a static buildBlock(...) that takes the separate lines and combines them into one result.
- Map it back to SwiftUI: swap String→View, "joined string"→ TupleView, and makeMessage→VStack.init.
- So "multiple lines in a { }" isn't special syntax — it's a result builder turning those lines into one combined value.
- Result builders have more hooks: buildOptional (for `if`), buildEither (for `if/else`), buildArray (for `for` loops).

**Complete runnable file**

```swift
import SwiftUI

@resultBuilder
struct StringBuilder {
    static func buildBlock(_ parts: String...) -> String {
        parts.joined(separator: " ")
    }
}

func makeMessage(@StringBuilder content: () -> String) -> String {
    content()
}

struct ContentView: View {
    var body: some View {
        Text(makeMessage { "Welcome"; "to"; "NPay" })   // "Welcome to NPay"
    }
}

#Preview { ContentView() }
```

---

## Concept 5 of 6 — spacing vs padding, + alignment

> 🔑 spacing = between children; padding = around the stack; VStack aligns on its CROSS (horizontal) axis.  

**Key points**

- spacing: 20  → the gap BETWEEN adjacent children, INSIDE the stack.
- .padding(30) → space AROUND the whole stack, OUTSIDE it.
- VStack takes a HorizontalAlignment (.leading/.center/ .trailing).
- Because the children are already stacked vertically; the only freedom left is how they line up LEFT-TO-RIGHT (the CROSS axis).
- Omit spacing and VStack uses a SYSTEM default (~8 pts, and it can vary by content/platform). spacing: 0 is different — that forces zero.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        // spacing = gap BETWEEN children; padding = space AROUND the stack;
        // alignment = how children line up on the cross axis.
        VStack(alignment: .leading, spacing: 20) {
            Text("NPay")
            Text("Payments made simple")
        }
        .padding(30)
        .border(.blue)   // shows the padded area
    }
}

#Preview { ContentView() }
```

---

## Concept 6 of 6 — assemble Milestone 2.3

> ⭐️ MILESTONE 2.3 — structured NPay welcome screen.  
> 🔑 One VStack composes many Views into a finished screen.  

**Key points**

- Three children now — @ViewBuilder packs them into `TupleView<(Image view, Text, Text)>.`
- .font(.subheadline) + .foregroundStyle(.secondary) on the subtitle = a quieter, smaller caption.
- .padding() with NO number = a sensible SYSTEM default inset on all sides (you don't have to pick a number).
- Everything you learned stacks up here: generic struct + trailing closure + @ViewBuilder + spacing + alignment + padding — all in one screen.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Image(systemName: "creditcard.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            Text("NPay")
                .font(.largeTitle)
                .bold()
                .foregroundStyle(.blue)

            Text("Payments made simple")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview { ContentView() }
```

---

## Live app — final code for Lesson 2.3

```swift
import SwiftUI

@resultBuilder
struct StringBuilder {
    static func buildBlock(_ parts: String...) -> String {
        parts.joined(separator: " ")
    }
}

func makeMessage(@StringBuilder content: () -> String) -> String {
    content()
}

struct ContentView: View {

    var body: some View {
        // ⭐️ Final Lesson 2.3 code — Milestone 2.3
        VStack(alignment: .center, spacing: 20) {
            Image(systemName: "creditcard.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            Text("NPay")
                .font(.largeTitle)
                .bold()
                .foregroundStyle(.blue)

            Text("Payments made simple")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
// ↑↑↑ This real ContentView IS the complete Lesson 2.3 code. ↑↑↑
```
