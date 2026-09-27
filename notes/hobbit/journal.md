# Journal

What was done, how, and what came of it. Newest last. The entries before
2026-09-25 are reconstructed from `git log` on the build script, the
annotations, the ref and the page modules, and from
`docs/hobbit-fast-draw-plan.md`; these notes did not exist yet. The
explanations are in the topic notes; this is the history.

## 2026-09-17 -- disassembled from the tape

- `scripts/build_hobbit.py` (`01a47cb`): the v1.2 tape loaded by simulating
  the real LOAD (`tap2sna --start $6C00`); the dictionary decoded, its
  format proved by every synonym link landing on an entry's first byte; code
  found by *playing* the game in SkoolKit's simulator -- a walkthrough typed
  a key at a time through the keyboard ports -- and the listing reassembled
  with sjasmplus and compared byte for byte before anything is written.
- Prior work consulted for where to look, credited and not copied:
  pobtastic's SkoolKit disassembly, Icemark's data-format notes.

## 2026-09-18 -- words out, pictures, the cast moving

- **The second word list** ($67AB), reached by no pointer, found with a read
  watchpoint over the range: untouched through the opening, LOOK and
  INVENTORY, first read when a sentence about an object is composed.
- **The inflection flags** worked out by calling `PRINT_WORD` with all
  sixteen, then traced to subject agreement: `ACTING` 0 for the player.
- **Code by descent** as well as by running, and the walkthrough extended
  with a command for every verb in the dictionary, since a dispatch table is
  what following branches cannot see through.
- **The picture table and every stream** decoded, by `RUN_PICTURE`'s own
  order of tests; two pairs of pictures turn out to share their ends.
- **`ACTION_TABLE`** found; `MOVE` watched running 21 times for nine
  characters in one INVENTORY turn -- the first sight of the independent
  cast.

## 2026-09-23 -- everything named, and the pages

- In one long day the rest of the game was read and named, a commit per
  subsystem: the object index (and bluespikey's v1.0 disassembly credited),
  the object records and their own handlers, driving the game by handing it
  whole commands (`hobbit_drive.py`), the rooms and exits, names read from
  the game's own words, the sword as the only lamp, the messages and control
  codes, the tokeniser (watched on real sentences: the class is four bits,
  not three, which had made verbs look unlike every other class), the
  parser's dispatch and frames, object matching and reach, the timers, the
  scripts and orders and the win, `DO_ACTION`, the arrival hooks, the visit
  scores, the shut road and the riddles, `RANDOM` (measured uneven), fighting,
  doors and locks, containers, the ring, the characters' own routines, the
  main loop, the font, and the code nothing reaches.
- `MATCH_WORD`'s description corrected: one candidate per call.
- **Pages**: Locations, Objects, Characters, Actions; the Map (thumbnails
  joined by their exits); the scripts decoded as editable source and on the
  Characters page; every picture animated at the game's own drawing speed;
  every address a label; How it works; the pages dressed in the game's
  paper and divider.

## 2026-09-24 -- faster pictures, the Inspector, a crash

- **The fast-draw patch**: first 3.8x by carrying the screen address with
  the point, then 9.4x with the fill's neighbour rows in IX and IY, each cell
  coloured once and whole bytes filled at once; every picture identical to
  the original's, whole memory compared. A Patches page with GIFs and
  per-picture timings.
- **A mistake**: the patch's overflow code sat in special word slot 0's
  handler, taken for unreachable because slot 0 holds no word. A quote mark
  tokenises as exactly that empty word -- the handler is `SPECIAL_QUOTE` --
  so SAY "..." crashed the patched game. Found by rewinding the emulator from
  the reset to the jump into $8315; the code moved to $5D00, below the game.
- **The keyboard read under interrupt**, so commands could be typed ahead
  during a picture, was added and then taken out: with pictures drawn in a
  second it cost more than it gave.
- The score's 75% ceiling recorded on the Bugs page; object flag bit 4 named
  "gives light" when Wilderland's names for the fields agreed with these, and
  Wilderland credited.
- **The Hobbit Inspector** (`hobbit-vscode/`), a VS Code extension showing
  the running game's objects, characters, timers and map, with a log fed by
  the emulator's new logpoints.

## 2026-09-25 -- the score, driving, Elrond

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

## 2026-09-26 -- the notes begin

- The first eight notes (README, overview, journal, driving, memory map,
  scoring, hidden roads, versions), from the 2026-09-25 sessions. Every
  memory map given a label column; the pages' fonts changed.

## 2026-09-27 -- the notes completed

Written to the Ant Attack standard: nineteen new topic notes (loading, main
loop, time and timers, input, dictionary, parser, actions, locations,
objects, light and dark, characters, fighting and dying, messages, screen and
printer, pictures, save and load, chance, bugs, leftovers), and the README,
overview, driving and memory map rewritten. Each claim was checked against
the listing, and the doubtful ones run in SkoolKit's simulator with a harness
around `hobbit_drive.Hobbit` that captures what is printed at $858F. What
that turned up:

- **The annotations say the opposite of the code in four places**, all
  *measured*: a player shut in a closed container is in the dark, not able
  to see (`TOO_DARK`); a script step's bit 5 spends the step, it does not
  remove the character (`SCRIPT_DO`, also the ref and the build's step
  text); the barrel goes back to the cellar after its ride, not to the lake
  (`BARREL_REACHES_LAKE`); `FOREST_ENTRY` is the forest room arrived at, not
  the one left, and `EYES_WARNING` kills whoever has left the forest.
- **Traps**: the forest road cannot be left alive except by pacing between
  its two rooms; the deep bog kills on arrival; closing the barrel over
  yourself without the sword leaves you unable to open it; BREAK held at the
  end of a tape block restarts the machine.
- **Bugs**: the fight's wear-down halves with `RRCA` instead of a shift
  (measured on Thorin: margin 13 took his defence from 120 to 52, margin 11
  did nothing); `WOUNDS` read one entry late, so a margin of 16 prints the
  ROM; FILL confirmed never to work; PUT ON, TAKE FROM, THROW, CUT and CLIMB
  have no handler anywhere; a LOAD after a new game can lose the hidden road.
- **Smaller findings**: the game types WAIT after 23.4 s; a refused command
  about an object drops the rest of the line; the trolls' clearing picture
  switches from night to day colours at dawn (the "not yet worked out" at
  $6C2B); the empty place at 47 is sealed by its stone; the story's
  end-of-line pause is about 0.58 s and `NO_PAUSE_LINES` is set to 17 and 9
  by `NEW_GAME` and `MAIN_LOOP`; five of the fourteen scoring places are dark
  and need the sword; the scripts are not restored by a new game, so
  Thorin's remark and Bard's last order carry over.
- **Stale comments** found "not yet worked out" where the code is named:
  `END_OF_TURN`'s two calls, `OBEY`'s narration and world's turn, `KILL`'s
  renaming and orders, `REACT_TO_ACTION`'s bit 3, `MOVE`'s diagonal codes.
- **This note set's own mistake**: the memory map said the tape loads
  $6000-$FFFF; 40000 bytes end at $FC3F. Corrected.

**Corrections applied** (later the same day, with the lead's go-ahead):
every one listed above, re-checked against the code first, went into
`hobbit_annotations.ctl`; the ref's light, fighting, reading and pictures
sections and "Leaving the story" paragraph were rewritten, and the Bugs page
gained the wear-down, the wound table, the forest, the lost road, BREAK and
the unreset scripts, with FILL confirmed; `build_hobbit.py`'s step note,
script preamble and `MESSAGE_TAILS` comment; and
`docs/hobbit-fast-draw-plan.md`'s printer-buffer aside. More stale "not yet
worked out" comments were settled on the way (`PLAYER_DIES`' `SHOW_SCORE`,
`ELROND_READS_MAP`'s and `BARREL_THROWN`'s tests, `DO_OPEN`'s
`CONTENTS_INTRO`, `NARRATE_ACTION`'s `NOUN_ONLY`, `DO_ACTION`'s dark message,
`PARSE_COMMAND`'s reset, `CHARACTERS_ACT`'s `NOTE_LIGHT`, the two $FF bytes
after `RIDDLES`), and the three existing "address not converted" warnings
removed. The build verifies byte for byte with no warnings (three before).
No label was renamed. `hobbit-vscode/` still calls a bit-5 step the end of a
character's part.
