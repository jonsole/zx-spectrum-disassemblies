# The Hobbit -- notes

*The Hobbit* (1982; Beam Software for Melbourne House; Philip Mitchell and
Veronika Megler), the illustrated text adventure for the 48K Spectrum in
which the other characters act on their own. Disassembled from the **v1.2**
tape (`HobbitV1.2.tzx`: a BASIC loader, the title picture loaded straight
onto the screen, and one 40000-byte block at $6000 entered at $6C00) by
`scripts/build_hobbit.py`. The v1.0 tape and the Sinclair re-release have
been loaded and compared, not disassembled ([`versions.md`](versions.md)).

These are the working notes: how the game works, how it was worked out, and
what is still open. The commented disassembly itself is the build's output,
published at <https://jonsole.github.io/zx-spectrum-disassemblies/hobbit/>,
and each routine's own description is there, not repeated here. Pictures,
room descriptions and messages are the game's and stay on the site.

## Status

- **Disassembly:** 100% -- all 40000 bytes, every routine, table, variable
  and message named and described, every address a label; it reassembles
  byte-for-byte on every build, and the build refuses a dictionary, room,
  object, message or script decode that does not account for every byte.
- **Pages:** How it works, the Map, Locations (every picture, animated at
  the game's own speed), Objects, Characters (every script decoded),
  Actions, Patches, Bugs and Credits.
- **Fast-draw patch:** pictures drawn 9.4 times faster, identical to the
  original's; `patches/hobbit_fast_draw.s`,
  [`docs/hobbit-fast-draw-plan.md`](../../docs/hobbit-fast-draw-plan.md).
- **Inspector:** a VS Code extension showing the running game's state,
  [`hobbit-vscode/`](../../hobbit-vscode/).
- **Notes:** complete to the Ant Attack standard on 2026-09-27. That pass
  found several annotations that say the opposite of the code (darkness in a
  closed container, what a script step's bit 5 does, where the barrel goes
  after its ride, what the forest's eyes do), listed in each note's
  "Disassembly corrections" and corrected in the annotations, the ref and the
  build's text the same day.

How each claim is known is tagged after it:

- *read* -- from the code (the listing, or the ROM it calls);
- *watched* -- live in the emulator with breakpoints, watchpoints or
  logpoints (2026-09-25's sessions);
- *measured* -- a run with chosen input or staged state, with the result read
  back: in SkoolKit's simulator unless it says live;
- *played* -- seen in a real playthrough, live or the build's scripted one;
- *assumed* -- believed but not checked, and why.

## Index

| Note | What it covers |
|---|---|
| [`overview.md`](overview.md) | **Start here** -- a tour of the findings, each linked to its deep dive |
| [`journal.md`](journal.md) | What was done when, and what turned out wrong |
| [`driving.md`](driving.md) | Running the game from a script: snapshots, breakpoints, injecting commands, capturing text, staging, traps |
| [`memory-map.md`](memory-map.md) | Where everything is, by address and label, and what is around the game |
| [`loading.md`](loading.md) | The tape, `START`'s copy of the world, and everything `NEW_GAME` does before the first prompt |
| [`main-loop.md`](main-loop.md) | A turn: read, tokenise, parse, obey, the world's turn; what costs no turn |
| [`time-and-timers.md`](time-and-timers.md) | The game typing WAIT after 23 s, the ten timers, the arrival hooks, the forest trap, the barrel's ride |
| [`input.md`](input.md) | The keyboard scan, the key maps, the line reader, one-key moves, @, and every key wait |
| [`dictionary.md`](dictionary.md) | The two word lists, the packed format, synonyms, abbreviations, word references |
| [`parser.md`](parser.md) | Sentences into command frames: the classes, AND/THEN, ALL/EXCEPT/IT, quotes and orders, the special words |
| [`actions.md`](actions.md) | Patterns and action codes, trying each object that fits, `DO_ACTION`, who handles what |
| [`locations.md`](locations.md) | The room records, exits and doors, moving and describing, the map as a whole, the sealed room |
| [`objects.md`](objects.md) | The object record, the flags, holding and containers, reach, size and weight, liquids, the rope |
| [`light-and-dark.md`](light-and-dark.md) | The dark rooms, the sword, falls, what the dark stops, and the closed barrel |
| [`characters.md`](characters.md) | The cast, the slots, the script steps, reactions, orders, Bard's own order step, each character's behaviour |
| [`fighting-and-dying.md`](fighting-and-dying.md) | A blow, the broken wear-down, sides, every way to die, winning |
| [`messages.md`](messages.md) | The message bytecode, the control codes, agreement, articles, how much the compression saves |
| [`screen-and-printer.md`](screen-and-printer.md) | The two windows and fonts, the end-of-line pause, the ZX Printer |
| [`pictures.md`](pictures.md) | The picture streams, the flood fill, what they cost, night and day in the trolls' clearing, the fast-draw patch |
| [`save-load.md`](save-load.md) | The four blocks, what a new game restores, and what nothing restores |
| [`chance.md`](chance.md) | `RANDOM`, its seed and unevenness, and everything left to chance |
| [`scoring.md`](scoring.md) | Where the score comes from, and why 100% cannot be reached |
| [`hidden-roads.md`](hidden-roads.md) | The road shut at random each game, and Elrond reading the map to open it |
| [`bugs.md`](bugs.md) | The bugs and the traps, each with its evidence |
| [`leftovers.md`](leftovers.md) | Unreached code, flags nothing sets, a test that never fails, unused bytes |
| [`versions.md`](versions.md) | v1.0, v1.1, v1.2 and the Sinclair re-release: which is which, and what differs |
