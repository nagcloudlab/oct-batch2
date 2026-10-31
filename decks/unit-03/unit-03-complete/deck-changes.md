# Unit 03 complete deck: changes from Lessons 3.1–3.12

One deck (294 slides) built by `tools/gen3_all.py` from the twelve Unit 03 decks, which are unchanged. It uses the same recipe as the Unit 01 and Unit 02 complete decks. Each lesson's `img/` is copied into `img/lN/` and the `<img>` paths are rewritten, including one screenshot that 3.7 reuses from 3.3.

## Structure
Title → Outcomes → "Twelve Parts, one app" (overview) → Parts 1–12 → Wrap-up ("Every Part left something in the app") → End.
Each Part covers one lesson: divider → content → recap → two "Check your understanding" questions → lab.

| Part | Lesson | Questions kept |
|---|---|---|
| 1 | 3.1 NavigationStack | #38, #40 |
| 2 | 3.2 Typed routes | #39, #43 |
| 3 | 3.3 TabView | #36, #40 |
| 4 | 3.4 Sheets & alerts | #36, #42 |
| 5 | 3.5 State preservation | #31, #37 |
| 6 | 3.6 Animations & transitions | #34, #40 |
| 7 | 3.7 Design system | #36, #42 |
| 8 | 3.8 Adaptive layouts | #39, #41 |
| 9 | 3.9 Environment | #35, #41 |
| 10 | 3.10 Accessibility & localization | #25, #29 |
| 11 | 3.11 Performance | #43, #44 |
| 12 | 3.12 Final integration | #26, #33 |

## Removed
- Removed from every lesson: the title, outcomes, "Where we are" (progress strip), each lesson's internal section dividers, the review divider, "Where this goes next" and the end slide.
- All review questions except two per Part. The kept questions favour predict-the-output and measured ones; the "From 3.x" spaced items were dropped.

## Moved
- 3.12's "Complete Unit 3 feature inventory" moved to the Wrap-up.

## Authored
- Title, outcomes, the overview of the twelve Parts, twelve Part dividers, the wrap-up divider and the end slide.
- References:
  - "Lesson 3.N", "(3.N)", "in 3.N" → "Part N".
  - "2.N" → "Unit 02, Part N" (the merged Unit 02 deck); "1.N" → "Unit 01, Part N"; "0.N" → "Unit 00, Part M".
  - "Milestone 3.N" → "Milestone N".
  - A lesson's own section ("Part k" inside a lesson) is named by its title.
  - "today" / "lesson" phrasings reworded.
  - A "(0.5)" inside a formula is left alone: only references preceded by a space are converted. The same rule was applied to Unit 02.
- 3.1 "Back can free memory": "(Unit 01, Part 8)" shortened to "(Unit 01)", because the longer bullet made the slide overflow.
