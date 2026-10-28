# Unit 3: Navigation, Architecture & Polish

| Lesson | Title | Concepts |
|---|---|---|
| 3.1 | [NavigationStack & NavigationLink](Lesson-3.1.md) | NavigationStack + Link · NavigationStack ≠ VStack · NavigationLink vs Button · destination screens as structs · state across screens + dismiss · wire the real NPay (Milestone) |
| 3.2 | [Programmatic Navigation with Typed Routes](Lesson-3.2.md) | navigation AS STATE · the typed route enum · the path array = the nav stack · .navigationDestination(for:) · push/pop + auto-navigate on success · wire the real NPay (Milestone) |
| 3.3 | [TabView & Shared App State](Lesson-3.3.md) | TabView basics · TabView vs NavigationStack · controlled selection (.tag) · shared state (@Observable store) · the NPayRouter (per-tab paths) · the full 4-tab NPay (Milestone) |
| 3.4 | [Sheets & Modal Presentation](Lesson-3.4.md) | .sheet basics · dismissing + sheet vs push · the modal family · .sheet(item:) + review sheet · dismiss → navigate + idempotency · review sheet in NPay (Milestone) |
| 3.5 | [Preserving State — Drafts & @Bindable](Lesson-3.5.md) | local state can be lost · view identity vs value · a draft model in the shared store · editing via @Bindable + clear rules · preservation vs persistence · integrate the draft (Milestone) |
| 3.6 | [Animations & Transitions](Lesson-3.6.md) | withAnimation · curves + implicit .animation · transitions (enter / leave) · numeric text + animated insertion · interpolation & Animatable · Reduce Motion + integrate (Milestone) |
| 3.7 | [Design System — Tokens & Components](Lesson-3.7.md) | design tokens (NPayTheme) · NPayButton (branded component) · `NPayCard<Content: View>` · reusable View vs ViewModifier · adapting + component responsibility · integrate the design system (Milestone) |
| 3.8 | [Responsive Layout](Lesson-3.8.md) | the layout negotiation · GeometryReader · ViewThatFits · AnyLayout (swap layout, keep identity) · safe areas + full responsiveness · adaptive quick actions (Milestone) |
| 3.9 | [Environment & App Preferences](Lesson-3.9.md) | @Environment · overriding & precedence · a custom environment value · appearance model + preferredColorScheme · inject an @Observable model (env) · wire preferences into NPay (Milestone) |
| 3.10 | [Localization & Accessibility](Lesson-3.10.md) | LocalizedStringKey vs String · Locale-aware currency formatting · Right-to-left (RTL) layout · Accessibility — meaning over layout · Accessible components + identifiers · MILESTONE — accessible, localizable NPay |
| 3.11 | [Performance — Lazy Views & Identity](Lesson-3.11.md) | what "slow" actually means · eager VStack vs LazyVStack · List vs LazyVStack · identity, Observation & _printChanges · expensive work in body & the main actor · MILESTONE — efficient, searchable NPay |
| 3.12 | [Capstone — The Complete NPay Architecture](Lesson-3.12.md) | the final architecture · trace one payment end-to-end · the SwiftUI runtime (change STATE) · state ownership (the core skill) · accessibility fixes + integration test · MILESTONE — the complete, verified NPay |
