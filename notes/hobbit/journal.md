# Journal

What was investigated, how, and what came of it. Newest last. The
explanations are in the topic notes; this is the history.

## Before these notes

The disassembly reached 100% and the fast-draw patch 9.4x before the notes
began; `docs/hobbit-fast-draw-plan.md` is that work's own record. Two things
from it worth keeping here:

- The first fast-draw patch overwrote the live `SPECIAL_QUOTE` handler, so
  SAY "..." crashed the patched game. Found by rewinding in the emulator to
  the crash; the patch's spare code moved to $5D00.
- A keyboard-buffer patch driven by the interrupt was written and then
  removed: with pictures drawn fast, the keyboard is read often enough without
  it.

## 2026-09-25

- **Score.** Set a watchpoint on `SCORE` in the original game and tested
  claims about what scores, driving the game by breakpoint: entering the
  Lonelands (+25, ARRIVE+44), the treasure into the chest, taking every
  takeable object, Elrond reading the map. Only arrivals score. Searched the
  binary for every reference and ruled out indirect ones. See
  [`scoring.md`](scoring.md).
- **Driving.** First attempts timed commands with sleeps and got lost. The
  game waits after *every* picture in `WAIT_FOR_ANY_KEY`, not just the first,
  as the annotation had said -- corrected. A key held until the next
  breakpoint hung the game in `STORY_CHAR`'s end-of-line wait. A stopped run
  left ENTER held into the next snapshot load. See [`driving.md`](driving.md).
- **Staging mistakes.** Taking objects in dark rooms failed until the player
  had the sword -- with its location written as well as its holder. Typing
  full names lost the noun. Teleporting left the map behind in Bag End.
- **Screenshots.** Taken at a breakpoint, `get_screen` showed the CRT mid-frame
  and the last line torn; switched to drawing from screen memory.
- **Elrond.** Played to Rivendell for real: Gandalf takes the map back in the
  Lonelands on the scripted route and returns it after three WAITs. Elrond
  reads it on the turn after being asked, putting back the road
  `NEW_GAME_CHOICES` shut -- watched with a watchpoint and logpoints.
  `$B6F1`, described as "Elrond has read the map", is never set: corrected.
  See [`hidden-roads.md`](hidden-roads.md).
- **Versions.** Looked for v1.1: it is the tape archived as v1.0. Loaded v1.0
  and the Sinclair re-release and compared them with v1.2. See
  [`versions.md`](versions.md).
- **The disassembly.** Every routine now lists its callers (`ListRefs=2`);
  `SPECIAL_WORDS` is `DEFW`s linking to each handler; `VISIT_SCORES` is a
  location constant and a `DEFW` per entry; the routines list shows names.
  `DO_LOAD` has no callers because it is reached through two jump tables:
  `CLASS_DISPATCH` by word class to `PARSE_SPECIAL`, then `SPECIAL_WORDS`.
