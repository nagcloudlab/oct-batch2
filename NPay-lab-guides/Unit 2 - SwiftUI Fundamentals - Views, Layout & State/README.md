# Unit 2: SwiftUI Fundamentals — Views, Layout & State

| Lesson | Title | Concepts |
|---|---|---|
| 2.1 | [Text — Your First View](Lesson-2.1.md) | `Text` is a view · what `some View` means · modifiers (and why order matters) · Text is secretly multilingual · why "NPay" sits in the center |
| 2.2 | [Images & SF Symbols](Lesson-2.2.md) | `Image` with an SF Symbol · symbols resolve at RUNTIME · .font() sizes a SYMBOL · color with .foregroundStyle · combine Image + Text (Milestone) |
| 2.3 | [VStack & @ViewBuilder](Lesson-2.3.md) | VStack is a generic STRUCT · the TRAILING CLOSURE · @ViewBuilder (many views, 1 closure) · build your OWN result builder · spacing vs padding, + alignment · assemble Milestone 2.3 |
| 2.4 | [HStack, Spacer & Layout Priority](Lesson-2.4.md) | HStack (horizontal sibling) · how HStack shares out WIDTH · Spacer (the flexible pusher) · HStack alignment (VerticalAlignment) · layoutPriority (who wins when tight) · NPay quick-action row (Milestone) |
| 2.5 | [ZStack, Background & Overlay](Lesson-2.5.md) | ZStack (the depth axis) · z-order & .zIndex() · how ZStack sizes itself · alignment inside ZStack · ZStack vs .background vs .overlay · NPay balance card (Milestone) |
| 2.6 | [Modifiers & Reusable Views](Lesson-2.6.md) | what a modifier REALLY is · why EVERY view gets .padding() · modifier ORDER (nested wrappers) · .frame() sizes the REGION · environment propagation · extract REUSABLE views · custom ViewModifier · assemble the screen (Milestone) |
| 2.7 | [Buttons & Interaction](Lesson-2.7.md) | Button basics (creation vs activation) · Button with a custom LABEL · button styles & .disabled() · hit testing & .contentShape() · QuickAction becomes interactive · a11y, responsiveness (Milestone) |
| 2.8 | [@State — Reactive State](Lesson-2.8.md) | why a normal `var` can't change · @State — the one-word fix · what @State IS (three forms) · build your OWN property wrapper · where @State lives (identity) · when @State RESETS (identity) · wire @State into NPay (Milestone) |
| 2.9 | [@Binding & One Source of Truth](Lesson-2.9.md) | a child can't change a passed value · @Binding — the two-way connection · balance vs $balance · how a Binding works (nonmutating set) · one source of truth · BalanceEditor & integrate (Milestone) |
| 2.10 | [ForEach, Identity & Lists](Lesson-2.10.md) | ForEach (no for-loops in views) · what ForEach IS (generic view) · Transaction model + Identifiable · stable identity in action · ForEach vs List (eager vs lazy) · TransactionRow + TransactionHistory · dynamic transactions (Milestone) |
| 2.11 | [TextField, Validation & Focus](Lesson-2.11.md) | TextField needs a Binding · amounts as String, money as Decimal · keyboard configuration (a HINT) · validation (syntax vs rules) · @FocusState (focus & keyboard) · PaymentForm + integrate (Milestone) |
| 2.12 | [The Complete Payment Flow (Unit 2 Finale)](Lesson-2.12.md) | the integration problem · money as integer paise · Transaction (amountPaise + Date) · sendDemoPayment (the operation) · the final PaymentForm · the complete NPay app (FINALE) |
