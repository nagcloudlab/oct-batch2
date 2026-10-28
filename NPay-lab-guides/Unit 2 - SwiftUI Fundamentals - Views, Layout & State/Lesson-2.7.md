# Lesson 2.7 — Buttons & Interaction

*Unit 2 · SwiftUI Fundamentals — Views, Layout & State*

---

## Concept 1 of 6 — Button basics (creation vs activation)

> 🔑 Button stores an @escaping action; it runs on ACTIVATION, never just because body was evaluated.  

**Key points**

- Button is a struct (a View). Its init takes a TITLE and an ACTION closure. Simplified:
    - action: () -> Void = "takes nothing, returns nothing".
- CRUCIAL: the action does NOT run when `body` is evaluated.
- So if SwiftUI re-evaluates body 10 times, the action runs ZERO times until an actual tap.
- Button actions run on the MAIN actor (UI thread).
- Preview/renderer can't script taps — tap in the Simulator (⌘R) and watch Xcode's console for the printed line.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        // "created" prints on every body eval; "tapped" only on tap.
        let _ = print("body evaluated — button created")
        return Button("Send Money") {
            print("Send Money tapped")   // only on activation
        }
    }
}

#Preview { ContentView() }
```

---

## Concept 2 of 6 — Button with a custom LABEL

> 🔑 Button has an action closure AND a label closure; it's `Button<Label>`, generic over whatever you put in the label.  

**Key points**

- TWO trailing closures:
    - action: what happens on tap
    - `label:  what the button looks like (a @ViewBuilder, so it` can hold multiple views like any container)
- Button is GENERIC over its label type: `Button<Label>.`
- Everything you know about building views applies inside label: — stacks, images, modifiers, the lot.
- Button("Send") { } is shorthand that builds a Text label for you.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 30) {
            // title-only → Button<Text>
            Button("Send Money") { print("A") }

            // custom label → Button<VStack<...>>
            Button {
                print("B")
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "arrow.up.right").font(.title2)
                    Text("Send")
                }
                .padding()
            }
        }
        .padding()
    }
}

#Preview { ContentView() }
```

---

## Concept 3 of 6 — button styles & .disabled()

> 🔑 .buttonStyle sets presentation (.plain/.bordered/ .borderedProminent); .disabled() blocks taps + dims + a11y.  

**Key points**

- .buttonStyle(...) changes how a button is presented:
    - `.plain              → no chrome; looks like its label`
    - `.bordered           → subtle tinted capsule`
    - `.borderedProminent  → filled, high-emphasis (primary action)` .buttonStyle(.borderedProminent)
- Styles aren't just colors — they affect shape, emphasis, and interaction feedback, and adapt to light/dark + platform.
- .disabled(true) makes a button UNtappable AND visually dimmed.
- .tint(.green) recolors a bordered/prominent button without writing a whole custom style.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Button("Plain") { }.buttonStyle(.plain)
            Button("Bordered") { }.buttonStyle(.bordered)
            Button("Prominent") { }.buttonStyle(.borderedProminent)
            Button("Prominent green") { }
                .buttonStyle(.borderedProminent).tint(.green)
            Button("Disabled") { }
                .buttonStyle(.borderedProminent).disabled(true)
        }
        .padding()
    }
}

#Preview { ContentView() }
```

---

## Concept 4 of 6 — hit testing & .contentShape()

> 🔑 Hit testing picks the tapped view; .contentShape(Rectangle()) makes a custom area's EMPTY space tappable too.  

**Key points**

- The trap: a view's VISIBLE area and its TAPPABLE area aren't always the same.
- .contentShape(Rectangle()) fixes it: it declares "treat this whole rectangle as the tappable area", so the entire tile responds, including the empty bits.
- Rule: whenever you build a custom tappable area that has empty space (or a transparent background), add .contentShape to make the full region hittable.
- If the tile already has an opaque .background(...), that area is usually hittable without .contentShape.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 40) {
            // ❌ only the TEXT is tappable; the wide empty sides aren't
            Button { print("A") } label: {
                Text("Hard to tap")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            .border(.red)   // red shows the full frame

            // ✅ whole rectangle tappable
            Button { print("B") } label: {
                Text("Easy to tap")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .border(.green)
        }
        .padding()
    }
}

#Preview { ContentView() }
```

---

## Concept 5 of 6 — QuickAction becomes interactive

> 🔑 Store `let action: () -> Void`; the component calls it on tap, the parent decides what it does (presentation ≠ behavior).  

**Key points**

- The component does NOT know WHAT the tap means — it just stores a closure and calls it on tap.
- Flow of the behavior:
    - `ContentView defines closure → QuickAction stores it in`
    - `action` → Button(action:) uses it → tap → closure runs.
- This is the key architecture lesson: PRESENTATION (how the tile looks) is separated from BEHAVIOR (what tapping does).
- `action` is a stored closure; it can CAPTURE objects it uses (a view model, a service).

**Complete runnable file (the lesson's full app)**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        // ⭐️ Final Lesson 2.7 code — Milestone 2.7 (interactive)
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
// ↑↑↑ This real ContentView IS the complete Lesson 2.7 code (so far). ↑↑↑
```

---

## Concept 6 of 6 — a11y, responsiveness (Milestone)

> ⭐️ MILESTONE 2.7 — NPay is interactive (three working buttons).  
> 🔑 Give buttons clear a11y labels; keep actions fast (offload slow/async work to a Task).  

**Key points**

- A button needs a clear spoken label for VoiceOver.
- Prefer icon + TEXT over icon-only: an arrow could mean Send, Upload, or Share.
- Button actions run on the main actor. Slow work there FREEZES the UI.
- Offload async work to a Task (full story in the concurrency unit)
- Assemble the full interactive NPay screen: header + card + three working QuickAction buttons.

**Complete runnable file (the lesson's full app)**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        // ⭐️ Final Lesson 2.7 code — Milestone 2.7 (interactive)
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
// ↑↑↑ This real ContentView IS the complete Lesson 2.7 code (so far). ↑↑↑
```
