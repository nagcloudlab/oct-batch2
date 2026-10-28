# Lesson 2.2 — Images & SF Symbols

*Unit 2 · SwiftUI Fundamentals — Views, Layout & State*

---

## Concept 1 of 5 — `Image` with an SF Symbol

> 🔑 Image(systemName:) = a VALUE describing a built-in symbol.  

**Key points**

- Image(systemName: "creditcard.fill") creates a SwiftUI Image VALUE — just like Text, it's a struct that DESCRIBES what to show, not pixels yet.
- "systemName:" means: don't load a file — fetch a built-in symbol from Apple's SF Symbols library (thousands of icons that match the system font).
- "creditcard.fill" is a SYMBOL NAME, not a file path.
- Image conforms to View (like Text) — that's why both accept the same modifiers (.padding, .foregroundStyle, etc.).
- Try it: ⌘-click `Image` → Jump to Definition → you'll see `public struct Image`.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        Image(systemName: "creditcard.fill")   // a VALUE describing a built-in symbol
    }
}

#Preview { ContentView() }
```

---

## Concept 2 of 5 — symbols resolve at RUNTIME

> 🔑 Symbol names are resolved at RUNTIME — typos = silent blank.  

**Key points**

- The compiler does NOT turn "creditcard.fill" into pixels.
- Huge consequence: a wrong name still COMPILES fine (it's a valid string) but shows NOTHING on screen.
- So the bug is a RUNTIME + console problem, not a compile problem.
- Symbols are added in new iOS versions. A name that exists on iOS 18 may be missing on iOS 16 → blank on the old device.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "creditcard.fil")    // typo! ✅ compiles ❌ draws nothing (0 × 0)
            // Console logs: No symbol named 'creditcard.fil' ...
            Image(systemName: "creditcard.fill")   // correct name → symbol shows
        }
    }
}

#Preview { ContentView() }
```

---

## Concept 3 of 5 — .font() sizes a SYMBOL

> 🔑 Symbols are glyphs → size them with .font, and they stay sharp.  

**Key points**

- Surprise: you size an SF Symbol with .font() — the SAME modifier you'd use on Text.
- Why does a FONT modifier resize an IMAGE? Because SF Symbols are designed to behave like TEXT GLYPHS — they line up with text and scale with font size and weight.
- Because they're vector glyphs, they stay SHARP at any size.
- You can also tie a symbol to a text style so it scales with Dynamic Type: .font(.largeTitle), .font(.title), etc.
- .font(.system(size:))  → sets the symbol's POINT SIZE.
- .imageScale(.large)    → nudges size relative to the font.
- .resizable().frame(…)  → forces an EXACT box (used more for For symbols, reach for .font FIRST.

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        Image(systemName: "creditcard.fill")
            .font(.system(size: 64))   // bigger symbol — stays sharp (it's a glyph)
    }
}

#Preview { ContentView() }
```

---

## Concept 4 of 5 — color with .foregroundStyle

> 🔑 .foregroundStyle tints foreground content; ".blue" = Color.blue.  

**Key points**

- .foregroundStyle sets the symbol's color. Same modifier you use to color Text — because both are "foreground content".
- Why does ".blue" work with just a leading dot? The modifier already expects a style/color type, so Swift infers it: ".blue" is shorthand for "Color.blue".
- You're not editing a PNG's pixels — you're asking SwiftUI to RE-TINT the vector symbol.
- You may see the OLDER .foregroundColor(.blue) in tutorials.
- Multicolor symbols: some symbols have built-in colors via .symbolRenderingMode(.multicolor) / .palette(...).

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "creditcard.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)            // tint the symbol

            Image(systemName: "creditcard.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue.gradient)   // subtle gradient

            Image(systemName: "creditcard.fill")
                .font(.system(size: 64))
                .foregroundStyle(.linearGradient(colors: [.blue, .purple],
                                                 startPoint: .top,
                                                 endPoint: .bottom))   // custom
        }
    }
}

#Preview { ContentView() }
```

---

## Concept 5 of 5 — combine Image + Text (Milestone)

> ⭐️ MILESTONE 2.2 — NPay title with a payment symbol above it.  
> 🔑 A container (VStack) lets multiple Views live on one screen.  

**Key points**

- VStack arranges children top-to-bottom; "spacing: 20" is the controllable gap (remember the 2.1 demo — no container = no control over gaps).
- Both children are Views, so the SAME modifiers work on each.
- .largeTitle.bold() = chain style onto a font in one go (shorthand for .font(.largeTitle).bold()).
- Image(systemName: "creditcard.fill") → built-in SF Symbol.
- Image("NPayLogo")                    → YOUR image file from Assets.xcassets (branding/custom art).

**Complete runnable file**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "creditcard.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            Text("NPay")
                .font(.largeTitle.bold())
                .foregroundStyle(.blue)
        }
    }
}

#Preview { ContentView() }
```

---

## Live app — final code for Lesson 2.2

```swift
import SwiftUI


struct ContentView: View {
    

    var body: some View {
        // ⭐️ Final Lesson 2.2 code — Milestone 2.2
        VStack(spacing: 20) {
            Image(systemName: "creditcard.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            Text("NPay")
                .font(.largeTitle.bold())
                .foregroundStyle(.blue)
        }
    }
}

#Preview {
    ContentView()
}
```
