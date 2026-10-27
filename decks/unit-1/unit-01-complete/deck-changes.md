# Unit 01 complete deck: changes from Lessons 1.1–1.10

One deck (178 slides, no day split) built by `tools/gen1_all.py` from the ten Unit 01 decks, which are unchanged. Swift code stays: this is the language unit.

## Structure
Title → Outcomes → "Ten Parts, one app" (overview) → Parts 1–10 → Wrap-up (Unit 01 complete, practise anywhere) → End.
Each Part (one per lesson): divider → content → recap → two "Check your understanding" questions → lab.

| Part | Lesson |
|---|---|
| 1 | 1.1 Swift and its compiler |
| 2 | 1.2 Variables, constants & types |
| 3 | 1.3 Optionals |
| 4 | 1.4 Functions & closures |
| 5 | 1.5 Structs vs classes |
| 6 | 1.6 Protocols & extensions |
| 7 | 1.7 Generics & errors |
| 8 | 1.8 ARC & memory |
| 9 | 1.9 Concurrency |
| 10 | 1.10 NPay's domain model |

## Removed
- Per-lesson title, outcomes, "Where we are", review divider, "Where this goes next" and end slides.
- 1.1's previews taught in full by later Parts: explicit conversion (Part 2), optionals (Part 3), values vs references (Part 5), ARC (Part 8), protocols (Part 6).
- Six of each lesson's eight review questions (two kept per Part: 1.1 #29, #28 · 1.2 #33, #35 · 1.3 #34, #33 · 1.4 #31, #32 · 1.5 #29, #25 · 1.6 #29, #31 · 1.7 #27, #29 · 1.8 #29, #26 · 1.9 #29, #33 · 1.10 #31, #30).

## Authored
- Title, outcomes, overview of the ten Parts, ten Part dividers, wrap-up divider, end slide.
- References: "Lesson 1.N" → "Part N"; "Lesson 0.N" → "Unit 00, Part M" (the merged Unit 00 deck); "the lesson text" → "the course text"; lab lines saying "today" reworded; lead-ins to dropped slides rewritten.

## Improved (same treatment as the Unit 00 deck)
- Part 1, **A language for an app like NPay**: each design goal with what it means for NPay, one per click.
- Part 1, **Where Swift fits**: each layer with what NPay uses there and where the course covers it, one per click.
- Part 1 recap as three cards; the values/ARC card (its slides now live in Parts 5 and 8) replaced by "the top of the stack".
- All Parts: cross-references rewritten for the merged deck: a lesson's own section ("Part k" inside a lesson) is named by its title, "(1.N)" → "(Part N)", "(0.N)" → "(Unit 00, Part M)", lesson-number cells and labels → Part numbers.
- Part 2, **Six fundamental types**: examples in NPay terms (transferCount, a branch latitude, upload progress, payee).
- Part 3, **Which tool when?** (authored): if let, guard let, ??, ?. and ! side by side, each with when to use it and an NPay example, before the NPay example slide.
- Part 3, **What the user sees if you forget** (authored): the real swiftc warning and output: a profile screen showing `Optional("Kumar")` vs `Kumar` after unwrapping.
- Part 3, **! traps when the box is empty**: the real trap message next to the user's view: tap Edit, NPay vanishes to the Home Screen.
- Part 3: 1.3's "Implicitly unwrapped optionals" slide dropped (user).
- Part 4, **Pass behavior in; trail it outside**: the generic `performOperation` sum replaced by an NPay fee rule passed as a closure (flat ₹10 → 101000, 2% trailing closure → 102000; verified).
- Part 4, **Closures you will write in NPay every day** (authored): Button action, sorted, filter, a stored onRefresh callback, `.task`; typechecked against the iOS SDK in Swift 6.
- Part 5, **Run it: struct vs class on two screens** (authored, real evidence): `tools/sim1_5/` runs a SwiftUI app in the iOS Simulator with NPay's Dashboard and Transfer screens sharing an account; screenshots in `img/`: start ₹25,000/₹25,000; struct after sending ₹5,000: ₹25,000/₹20,000; class: ₹20,000/₹20,000.
- Part 5, **Struct or class?**: the table redrawn as NPay's types sorted into struct and class, one per click.
- Part 6, **Run it: one contract, three payment methods** (authored, real evidence, `tools/sim1_6/`): `[any PaymentMethod]` with a default `validate` in an extension and Card's ₹100 override; the app shows UPI ✓✓, Card ✗✓, Bank transfer ✓✓ for ₹50 / ₹500.
- Part 6, **Run it: same screen, injected service** (authored, real evidence): identical DashboardView + ViewModel with BalanceService (₹25,000) and MockBalanceService (₹9,99,999).
