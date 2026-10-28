# Lesson 2.5 — ZStack, Background & Overlay

*Unit 2 · SwiftUI Fundamentals — Views, Layout & State*

---

## Concept 1 of 6 — ZStack (the depth axis)

> 🔑 ZStack overlaps children on the Z (depth) axis, centered.  

**Key points**

- Three stacks, three axes:
    - `VStack → top-to-bottom   (Y)`
    - `HStack → left-to-right    (X)`
    - `ZStack → front-to-back    (Z, depth) ← overlapping layers`
- ZStack overlays its children in the SAME space.
- Like the others, it's a generic struct with a @ViewBuilder closure.
- Color.blue here is a VIEW, not just a color value — a view that greedily fills whatever space it's offered.
- `Color.blue` conforms to View and is "greedy" (fills offered space).

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Color.blue
            Text("NPay")
                .foregroundStyle(.white)
        }
        .frame(width: 240, height: 140)
    }
}

#Preview { ContentView() }
```

---

## Concept 2 of 6 — z-order & .zIndex()

> 🔑 Later child = on top; .zIndex(n) overrides (relative to siblings).  

**Key points**

- DEFAULT RULE: source order = paint order. LATER children are drawn ABOVE earlier ones.
- OVERRIDE: .zIndex(n) changes drawing order without moving the code.
- zIndex ONLY affects draw order. It does NOT change a view's size, position, or layout — just who's painted over whom.
- .zIndex(n) is compared only against the OTHER direct children of the same ZStack — it's a relative front-to-back ordering, not a global one.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 30) {

            // Default order: Text (last) is on top
            ZStack {
                Color.blue.frame(width: 200, height: 120)
                Color.green.frame(width: 150, height: 90)
                Text("On top").foregroundStyle(.white)
            }

            // Text FIRST → buried by the colors
            ZStack {
                Text("Buried").foregroundStyle(.white)
                Color.blue.frame(width: 200, height: 120)
                Color.green.frame(width: 150, height: 90)
            }

            // Text FIRST but .zIndex(1) → back on top
            ZStack {
                Text("Rescued").foregroundStyle(.white).zIndex(1)
                Color.blue.frame(width: 200, height: 120)
                Color.green.frame(width: 150, height: 90)
            }
        }
        .padding()
    }
}

#Preview { ContentView() }
```

---

## Concept 3 of 6 — how ZStack sizes itself

> 🔑 ZStack overlaps (doesn't add heights); give it a .frame to control the card size.  

**Key points**

- Same two children (a 200×120 rectangle + a small Text):
    - `In a VStack → height ≈ 120 + textHeight + spacing (they` sit one below the other).
    - `In a ZStack → height ≈ 120 (they share the space; the` stack hugs the bigger child, text sits on top).
- Rough model: ZStack takes a size big enough to contain its children at their chosen sizes and alignment — it does NOT sum them.
- Caution (from the deck): don't memorize "always the largest child." Real sizing depends on proposals, child flexibility, and alignment.
- Our balance card wraps the ZStack in .frame(height: 180).

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 40) {

            Text("VStack of the two children:")
                .font(.caption).foregroundStyle(.secondary)
            VStack {
                Color.blue.frame(width: 200, height: 120)
                Text("hi")
            }
            .border(.red)

            Text("ZStack of the SAME two:")
                .font(.caption).foregroundStyle(.secondary)
            ZStack {
                Color.blue.frame(width: 200, height: 120)
                Text("hi").foregroundStyle(.white)
            }
            .border(.red)
        }
        .padding()
    }
}

#Preview { ContentView() }
```

---

## Concept 4 of 6 — alignment inside ZStack

> 🔑 ZStack aligns on BOTH axes (an Alignment); matters only when a child is smaller than the stack.  

**Key points**

- Alignment here = vertical + horizontal together:
    - `.topLeading   .top        .topTrailing`
    - `.leading      .center     .trailing      ← .center is default`
    - `.bottomLeading .bottom    .bottomTrailing`
- So .topLeading pins the front layer to the top-left corner; .bottomTrailing to the bottom-right; .center (default) dead middle.
- .topLeading is shorthand resolved by contextual inference to an Alignment value (same trick as .leading, .blue, etc.).
- If a front layer already FILLS the ZStack (e.g. a VStack with .frame(maxWidth:.infinity) + padding, like our card), there's no slack to move it, so changing ZStack alignment shows no visible change.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 24) {
            card(".topLeading", .topLeading)
            card(".center", .center)
            card(".bottomTrailing", .bottomTrailing)
        }
        .padding()
    }
    func card(_ label: String, _ alignment: Alignment) -> some View {
        ZStack(alignment: alignment) {
            Color.blue
            Text(label).foregroundStyle(.white).padding(8)
        }
        .frame(height: 90)
    }
}

#Preview { ContentView() }
```

---

## Concept 5 of 6 — ZStack vs .background vs .overlay

> 🔑 ZStack = equal layers; .background = behind & sized by host; .overlay = in front & sized by host.  

**Key points**

- ZStack { A; B } — A and B are PEERS. Both participate in the stack's layout; the stack sizes to contain them.
- view.background(X) — X is drawn BEHIND `view`, and X's size FOLLOWS `view`.
- view.overlay(X) — X is drawn IN FRONT of `view`, and again X follows `view`'s size (does NOT enlarge it).
- Rule of thumb:
    - `layers are equal partners      → ZStack`
    - `decoration BEHIND one view     → .background`
    - `decoration IN FRONT of one view→ .overlay`
- There's a one-liner that fills a SHAPE behind a view.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 30) {

            // ZStack: peers; stack sized by .frame
            ZStack {
                Color.blue
                Text("ZStack").foregroundStyle(.white)
            }
            .frame(width: 240, height: 90)
            .border(.red)

            // background: blue follows the padded text
            Text("background")
                .foregroundStyle(.white)
                .padding(30)
                .background(.blue)
                .border(.red)

            // overlay: text sits on the shape, shape keeps size
            RoundedRectangle(cornerRadius: 16)
                .fill(.blue)
                .frame(width: 240, height: 90)
                .overlay { Text("overlay").foregroundStyle(.white) }
                .border(.red)
        }
        .padding()
    }
}

#Preview { ContentView() }
```

**EXTRA — ".overlay explained" (badge & background-vs-overlay): Mental model: .overlay = a STICKER on a box. The box keeps its size; the sticker sits ON TOP, aligned to the box.**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 50) {
            // 1) Plain bell
            Image(systemName: "bell.fill").font(.system(size: 60))

            // 2) SAME bell + red badge ON TOP (size unchanged)
            Image(systemName: "bell.fill")
                .font(.system(size: 60))
                .overlay(alignment: .topTrailing) {
                    Text("3")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(.red, in: Circle())
                }

            // 3) background (BEHIND) vs overlay (IN FRONT)
            HStack(spacing: 40) {
                Image(systemName: "star.fill")
                    .font(.system(size: 50)).foregroundStyle(.yellow)
                    .background(.black)        // behind the star
                Image(systemName: "star.fill")
                    .font(.system(size: 50)).foregroundStyle(.yellow)
                    .overlay(alignment: .center) {
                        Text("★ on top").font(.caption).foregroundStyle(.red)
                    }                          // in front of the star
            }
        }
        .padding()
    }
}

#Preview { ContentView() }
```

---

## Concept 6 of 6 — NPay balance card (Milestone)

> ⭐️ MILESTONE 2.5 — NPay welcome screen WITH a balance card.  
> 🔑 Card = rounded-rect background layer + text layer, sized by .frame.  

**Key points**

- Back layer: a RoundedRectangle filled blue = the card.
- Front layer: a left-aligned VStack of three texts, white.
- .frame(maxWidth:.infinity, alignment:.leading) makes the text block span the card and hug the left (recall Concept 4: the front fills the stack, so ZStack alignment won't matter here).
- .frame(height: 180) sizes the whole card (Concept 3: ZStack won't size itself from overlapping layers — we set it).
- Everything from this lesson shows up: ZStack layering, z-order (rectangle first = behind), sizing via .frame, and a rounded shape as background.
- Same card without an explicit ZStack:
    - Fewer layers, same look. Pick whichever reads clearer.

**Complete runnable file (the lesson's full app)**

```swift
import SwiftUI

struct ContentView: View {

    var body: some View {
        // ⭐️ Final Lesson 2.5 code — Milestone 2.5
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

            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.blue)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Available Balance")
                        .font(.subheadline)

                    Text("₹25,000")
                        .font(.largeTitle.bold())

                    Text("NPay Demo Account")
                        .font(.caption)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
            }
            .frame(height: 180)

            HStack(spacing: 30) {
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
// ↑↑↑ This real ContentView IS the complete Lesson 2.5 code (so far). ↑↑↑
```
