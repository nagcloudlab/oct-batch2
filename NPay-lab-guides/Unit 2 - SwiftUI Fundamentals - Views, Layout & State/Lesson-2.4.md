# Lesson 2.4 — HStack, Spacer & Layout Priority

*Unit 2 · SwiftUI Fundamentals — Views, Layout & State*

---

## Concept 1 of 6 — HStack (horizontal sibling)

> 🔑 HStack = VStack rotated: horizontal main axis, VerticalAlignment.  

**Key points**

- HStack is a generic struct conforming to View — exactly like VStack, just a different main axis.
- The ONE difference from VStack: its alignment type.
    - `VStack  → HorizontalAlignment  (cross axis = horizontal)`
    - `HStack  → VerticalAlignment    (cross axis = vertical)`
- Everything else is identical: generic `<Content>`, trailing closure, @ViewBuilder, spacing.
- Try it: ⌘-click `HStack` → `@frozen public struct HStack`.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        HStack(spacing: 20) {
            Text("Send")
            Text("Request")
            Text("History")
        }
        .padding()
    }
}

#Preview { ContentView() }
```

---

## Concept 2 of 6 — how HStack shares out WIDTH

> 🔑 Plain Text takes only its own width; .frame(maxWidth: .infinity) makes children split the row equally.  

**Key points**

- HStack layout is a negotiation:
    1. Parent proposes a width (say 350 pt).
    - `2. HStack subtracts spacing (2 gaps × 20 = 40 → 310 left).`
    3. It asks each child what size it wants.
    4. A plain Text asks for ONLY its text width — no more.
    5. HStack places them; leftover space stays EMPTY.
- To force equal columns, make each child FLEXIBLE.
- .frame(maxWidth: .infinity) is a MAX, not a fixed width.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 40) {
            // A) plain Text — each only as wide as its word
            HStack(spacing: 20) {
                Text("Send").border(.red)
                Text("Request").border(.red)
                Text("History").border(.red)
            }
            .border(.blue)
            // B) .frame(maxWidth: .infinity) — equal columns
            HStack(spacing: 20) {
                Text("Send").frame(maxWidth: .infinity).border(.red)
                Text("Request").frame(maxWidth: .infinity).border(.red)
                Text("History").frame(maxWidth: .infinity).border(.red)
            }
            .border(.blue)
        }
        .padding()
    }
}

#Preview { ContentView() }
```

---

## Concept 3 of 6 — Spacer (the flexible pusher)

> 🔑 Spacer() is an empty, greedy view that pushes neighbours apart.  

**Key points**

- Spacer() is a VIEW that has no visible content — its only job is to EXPAND and eat all available space along the stack's main axis.
- So the Spacer between the two shoves them apart: it swells to fill the middle, pinning the title left and the icon right.
- Spacer is GREEDY, like .frame(maxWidth: .infinity) — but it's its own empty view, not a modifier on a child. Use whichever reads clearer:
    - `Spacer()                → "push neighbours apart"`
    - `.frame(maxWidth:.infinity) → "make THIS child stretch"`
- Position controls everything:
    - `[A] Spacer()               → [A]..................`
    - `[A] Spacer() [B]           → [A].........[B]`
    - `Spacer() [A]               → ..................[A]`
    - `[A] Spacer() [B] Spacer() [C] → spreads 3 evenly-ish`
- padding adds a FIXED amount of space. Spacer adds FLEXIBLE space that changes with the screen width.
- minLength: Spacer(minLength: 20) guarantees at least 20 pt even when space is tight.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 40) {
            // No Spacer — title & icon sit together on the left
            HStack {
                Text("NPay")
                Image(systemName: "person.circle")
            }
            .border(.blue)
            // With Spacer — pushed to opposite ends
            HStack {
                Text("NPay")
                Spacer()
                Image(systemName: "person.circle")
            }
            .border(.blue)
        }
        .font(.title2)
        .padding()
    }
}

#Preview { ContentView() }
```

---

## Concept 4 of 6 — HStack alignment (VerticalAlignment)

> 🔑 HStack alignment = VerticalAlignment; .firstTextBaseline is the clean choice for mixed-size text.  

**Key points**

- HStack's alignment is a VerticalAlignment (cross axis):
    - `.top     → top edges line up`
    - `.center  → vertical centers line up   (the DEFAULT)`
    - `.bottom  → bottom edges line up`
- Only matters when heights DIFFER. Equal-height children look the same under every alignment.
- Remember the mirror from Concept 1:
    - `VStack → HorizontalAlignment (.leading/.center/.trailing)`
    - `HStack → VerticalAlignment   (.top/.center/.bottom)`
- For TEXT of different sizes, .top/.center can look "off" because they ignore the letters' baseline.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 30) {
            row(".top", .top)
            row(".center (default)", .center)
            row(".bottom", .bottom)
            row(".firstTextBaseline", .firstTextBaseline)
        }
        .padding()
    }
    func row(_ label: String, _ alignment: VerticalAlignment) -> some View {
        VStack(alignment: .leading) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            HStack(alignment: alignment) {
                Text("Send").font(.largeTitle).border(.red)
                Text("Request").font(.caption).border(.red)
            }
            .border(.blue)
        }
    }
}

#Preview { ContentView() }
```

---

## Concept 5 of 6 — layoutPriority (who wins when tight)

> 🔑 layoutPriority decides who KEEPS space when the row is too narrow.  

**Key points**

- Higher layoutPriority = served FIRST when space is scarce.
- Default priority is 0. One child at 1 outranks the rest.
- This only bites under CONSTRAINT. With plenty of width, the priorities make no visible difference — everyone fits.
- A common misread: "layoutPriority(1) makes a view larger." No — it only changes WHO gives up space first when there isn't enough.
- Related tools for text squeeze:
    - `.lineLimit(1)             → never wrap; truncate with …`
    - `.minimumScaleFactor(0.5)  → shrink font instead of truncating`
    - `.fixedSize()              → "never truncate me, grow instead"`

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("No priority:").font(.caption2).foregroundStyle(.secondary)
            HStack {
                Text("Available Balance").border(.red)
                Text("₹25,000").border(.red)
            }
            .frame(width: 200)
            .border(.blue)
            Text("Label has layoutPriority(1):").font(.caption2).foregroundStyle(.secondary)
            HStack {
                Text("Available Balance").layoutPriority(1).border(.red)
                Text("₹25,000").border(.red)
            }
            .frame(width: 200)
            .border(.blue)
        }
        .padding()
    }
}

#Preview { ContentView() }
```

---

## Concept 6 of 6 — NPay quick-action row (Milestone)

> ⭐️ MILESTONE 2.4 — welcome screen + horizontal quick actions.  
> 🔑 Compose: small VStacks inside an HStack inside the screen VStack.  

**Key points**

- NESTING is normal: VStacks inside an HStack inside the screen VStack.
- Shared modifiers on the HStack (.font / .foregroundStyle) flow DOWN to the children via the environment — set the style once on the row instead of on every icon and label.
- Still just visuals — not tappable yet. Buttons arrive in 2.7.
- The deck keeps the three actions at natural width (centered by the parent).

**Complete runnable file (the lesson's full app)**

```swift
import SwiftUI

struct ContentView: View {

    var body: some View {
        // ⭐️ Final Lesson 2.4 code — Milestone 2.4
        VStack(spacing: 24) {

            Image(systemName: "creditcard.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            Text("NPay")
                .font(.largeTitle.bold())
                .foregroundStyle(.blue)

            Text("Payments made simple")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "arrow.up.right")
                    Text("Send")
                }

                VStack(spacing: 8) {
                    Image(systemName: "arrow.down.left")
                    Text("Request")
                }

                VStack(spacing: 8) {
                    Image(systemName: "clock")
                    Text("History")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.blue)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
// ↑↑↑ This real ContentView IS the complete Lesson 2.4 code (so far). ↑↑↑
```
