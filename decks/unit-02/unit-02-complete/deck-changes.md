# Unit 02 complete deck: changes from Lessons 2.1–2.12

One deck (218 slides: every original lesson slide plus two authored "which one when?" slides) built by `tools/gen2_all.py` from the twelve Unit 02 decks, which are unchanged. It uses the same recipe as the Unit 01 complete deck. Each lesson's `img/` is copied into `img/lN/`, and the `<img>` paths are rewritten to match.

## Structure
Title → Outcomes → "Twelve Parts, one app" (overview) → Parts 1–12 → Wrap-up ("Every Part is somewhere on this screen") → End.
Each Part covers one lesson: divider → content → recap → two "Check your understanding" questions → lab.

| Part | Lesson | Questions kept |
|---|---|---|
| 1 | 2.1 Text | #31, #33 |
| 2 | 2.2 Image & SF Symbols | #28, #29 |
| 3 | 2.3 VStack & @ViewBuilder | #32, #38 |
| 4 | 2.4 HStack & Spacer | #25, #26 |
| 5 | 2.5 ZStack | #26, #28 |
| 6 | 2.6 View modifiers | #30, #33 |
| 7 | 2.7 Button & events | #27, #33 |
| 8 | 2.8 @State | #29, #33 |
| 9 | 2.9 @Binding | #28, #30 |
| 10 | 2.10 ForEach, List & identity | #29, #33 |
| 11 | 2.11 TextField & validation | #25, #31 |
| 12 | 2.12 The payment flow | #23, #25 |

## Removed
- Removed from every lesson: the title, outcomes, "Where we are" (progress strip), each lesson's internal section dividers, the review divider, "Where this goes next" and the end slide.
- All review questions except two per Part. The kept questions favour predict-the-output and measured ones; the "From 2.x" spaced repetition items were dropped.

## Moved
- 2.12's "Unit 2 review" slide moved to the Wrap-up.

## Authored
- Title, outcomes, the overview of the twelve Parts, twelve Part dividers, the wrap-up divider and the end slide.
- References:
  - "Lesson 2.N", "(2.N)", "in 2.N" → "Part N".
  - "Lesson 1.N" → "Unit 01, Part N"; "Lesson 0.N" → "Unit 00, Part M".
  - "Milestone 2.N" → "Milestone N"; "Checkpoint 2.N" → "Checkpoint N".
  - A lesson's own section ("Part k" inside a lesson) is named by its title.
  - "today" / "next lesson" phrasings reworded; the milestone cards labelled "Today" become "In this Part".
- 2.7 "QuickAction stores a closure": "(Part 8)" → "(coming up)", because that section is now later in the same Part, and the full title made the slide overflow.

## Deep audit (user: "keep best to teach well; remove unwanted, vague, duplicate")
216 → 185 slides. The source lesson decks are unchanged; the content lists in `gen2_all.py` decide what is kept.

**Cut: the same idea taught again elsewhere** (the copy in the Part that owns the topic is kept)
- 2.1 "Same modifiers, different order" and its question: Part 6 "Order decides what wraps what" teaches this. Part 1's second question is now "What does some View mean?" (#33).
- 2.1 "Some modifiers keep Text; others wrap it": Part 6 "Each wrapper is a new generic type" teaches this.
- 2.2 "Both conform to View": Part 6 covers it.
- 2.4 "Modifiers on a container flow down": Part 2 (`.font` on an Image) and Part 6 (environment) cover it.
- 2.4 "Spacer() is not .padding(20)": the Spacer slide and its question make the same point.
- 2.6 "Constructing a view ≠ evaluating its body": Part 7 "Evaluation is not activation" makes the point, with evidence.
- 2.8 "The struct describes; SwiftUI keeps": the slide before it ran it.
- 2.8 "What does $balance mean?": Part 9 "The value, or a binding to it".
- 2.10 "Insert one; the rest keep their identity": the TXN table before it.
- 2.11 "Values, not key presses": typed vs pasted is already on the keyboard slide.

**Cut: abstract box-flow diagrams with no evidence** (a measured or screenshot slide next to each teaches the same thing)
- 2.1 "From import SwiftUI to a Text value", "From launch to visible text", "Parents propose, text chooses, parents place".
- 2.2 "From symbol name to visible icon".
- 2.3 "Five steps, no Y coordinates".
- 2.4 "How an HStack shares out width".
- 2.5 "One description, rendered by SwiftUI".
- 2.6 "Modifiers come from the View API".
- 2.7 "Six steps from glass to code".
- 2.8 "From a tap to a new balance on screen".
- 2.10 "Array in, identified views out".
- 2.11 "From a key to a visible update", "Where the validation sits".

**Cut: tangents or too deep for this unit**
- 2.1 "Read the interface" (Jump to Definition stays as a lab step), "One visible letter is not one byte" (Unicode counts).
- 2.2 "systemName: or an asset name" table: "Same string, different place to look" shows it, with evidence.
- 2.3 "Dynamic Type: measured again" (Part 1 already measures larger text), "Is nesting stacks bad?".
- 2.6 "Foreground style vs background".
- 2.7 "A closure can keep an object alive" (Unit 01, Part 8 owns ARC).
- 2.8 "@NonNegative: a wrapper in plain Swift" (27 lines).

**Tightened points**
- Cross-references left over from the merge removed: `(“Layout: place and size”)`, `(“Final NPay code”)`, `(“Z-order”)`, `(“Identity and $balance”)`, `(17)`, and "Matters for conditional views, later".
- Lab steps no longer cite the text's section numbers ("Build Section 2's ContentView" → "Build the first ContentView", and so on). "Run the text's experiments" → "Experiments A to E".
- 2.3: "The text's illustration: 41 + 20 + 20 = 81 pt" removed; the measured 89.7 pt stays.
- Part 1 recap: the third card is now "A literal is a key" (modifier order now lives in Part 6).
- Speaker notes: when the next slide in a lesson was cut, the CONNECT line now names the slide that actually follows.

## Content review (user: "do best, like Units 00 and 01")
I reviewed all 185 slides as screenshots. Most already follow the Unit 00/01 pattern: Simulator screenshots next to the code, measured numbers, short points, and NPay milestones shown as before/after phones. Changes:

- **Added: Part 5, "Five layout tools, one NPay screen"** (authored, before the recap). VStack / HStack / ZStack / Spacer / background-overlay: when to use each, where NPay uses it, and the measured evidence from Parts 3–5, next to the Milestone 5 screenshot.
- **Added: Part 9, "What does the child get?"** (authored, before the recap). A plain value / `$balance` / the child's own `@State` / a closure: when to use each, the NPay example, and what the runs showed (Parts 7–9), next to the Milestone 9 screenshot. Rule: one owner per value (parent ₹25,000 vs child ₹26,000).
- **Vague "later" placeholders now name where the topic is covered:**
  - "Localization in depth when NPay becomes multilingual" → "NPay in three languages: Unit 03, Part 10".
  - "Real balance and state: later" → "A balance that changes: Part 8, @State".
  - "The safe area matters too; .frame comes in the layout Parts" → ".frame changes that region: Part 6".
  - "Text baseline alignment: a later experiment" → "`.firstTextBaseline` lines up the text, not the boxes". This is authored from SwiftUI's documented alignment, not measured.

## Measurement cards removed (user: "remove these type of cards")
13 slides had a "Measured…" / "Size SwiftUI gave…" / "Row width, measured" card next to a Simulator screenshot that already shows the result. The cards are removed. Where a number is the point of the slide, that one fact is now the screenshot caption, for example "Measured: 48.7 + 21.0 + 20 = 89.7 pt" or "Blue = the HStack; the Spacer took 285.7 pt". The full numbers stay in the speaker notes. Where a card was a click, its "Click:" cue in the notes is reworded, so clicks and notes still match.
- Slides: Same sentence, two proposals · NPay at the end of Part 1 · It compiles, and shows nothing · A symbol takes its size from the font · Same string, different place to look · Spacing 20, then 50 · Stack height = children + spacing · Change the spacing: 0, 20, 40 · Spacer takes the leftover space · Same children, different sizes · Who decides the size? · The same card with .background(_:in:) · The frame changes the region, not the text.
- Kept: console and output cards (`type(of:)` prints, `_printChanges` logs, program output) on slides that have no screenshot. There, the card is the evidence.

## More detail (user: "more detailed slides will be good"; chose: add detail to this deck)
10 of the slides cut in the deep audit are restored: the ones that teach a practical skill or carry real evidence. The abstract box-flows and pure repeats stay out. 187 → 197 slides.
- Part 1: "Read the interface; don't memorise it" (Jump to Definition, real iOS 26.5 SDK lines); "One visible letter is not one byte" (English, Tamil and Hindi in the Simulator; the counts moved to the caption).
- Part 2: "systemName: or an asset name" (symbol vs asset comparison table).
- Part 3: "Dynamic Type: measured again, placed again" (caption: 74.0 + 49.7 + 20 = 143.7 pt); "Is nesting stacks bad?".
- Part 6: "Constructing a view ≠ evaluating its body" (real launch trace).
- Part 7: "A closure can keep an object alive" (real ARC run); QuickAction's "(coming up)" pointer is restored, since this slide follows it.
- Part 8: "@NonNegative: a wrapper in plain Swift" (how `@State` works underneath).
- Part 11: "Where this Part's validation sits" (input UX, client validation, trusted backend); "Values, not key presses" (typed vs pasted, the printed request).
- No number cards beside screenshots: the Unicode "Counted in Swift" card follows the same rule as the measured cards.

## All original slides back (user: "use original slides and merge here"; chose: all original slides, fixes kept)
Every content slide of the twelve lessons is back (218 = the 216-slide merge + the two authored "which one when?" slides). The deep-audit cuts are reverted. The fixes stay:
- Cleaned cross-references and lab steps.
- The vague "later" placeholders, now naming where each topic is covered.
- No number cards beside screenshots: the key fact is in the caption, the rest in the notes. The same treatment now also covers "All three measured" (Part 6, three orders), and the side-by-side width and priority cards (Part 4, equal widths; layoutPriority).
- Speaker-note click cues reworded to match.

Two fixes that existed only because slides had been cut are reverted:
- Part 1's recap card is "Modifiers wrap" again (modifier order is taught in Part 1 again).
- The Part 6 note "as we saw in Part 1" is restored.

Part 1 keeps question #33 ("What does some View mean?") instead of #41, which repeats Part 6's padding/background order question.
