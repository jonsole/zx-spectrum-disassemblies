# Fairlight -- notes

*Fairlight* (subtitled *A Prelude*; The Edge, 1985) for the 48K Spectrum.
Code, design and graphics by Bo Jangeborg, with graphics by Jack Wilkes and
Niclas Osterlin and music by Mark Alexander. An isometric flip-screen
adventure -- Jangeborg's own engine, not Ultimate's Filmation: the knight
walks the rooms of a castle drawn in line and texture, picks things up and
carries up to five of them, uses some, fights the guards and creatures,
and looks for the one thing the ending asks after (the inlay's story calls
the quest's object the Book of Light; the game itself names nothing -- see
[`quest.md`](quest.md)). Its rooms are not pictures but little programs of
points, lines and fills that the game runs each time a room is entered.

Disassembled from the original tape, **Release 2** --
`tapes/Fairlight (1985)(The Edge)(Release 2).tzx` -- by
`scripts/build_fairlight.py`. Release 1,
`tapes/Fairlight (1985)(The Edge)(Release 1).tzx`, was loaded and compared
([`versions.md`](versions.md)). Both came from ZXDB (the entry is marked
Available), as Ramsoft MakeTZX images.

```
.venv-win\Scripts\python.exe scripts\build_fairlight.py --tape "..\tapes\Fairlight (1985)(The Edge)(Release 2).tzx" [--html]
```

(from `game-disassemblies/`; about 45 seconds, most of it the play
sessions). The build loads the tape by simulating the real LOAD and the
tape's own Alkatraz loader, checks the loader's decryption against the
tape's bytes, plays the game in SkoolKit's simulator to find which bytes are
code, lays the level data out a record per entry from the game's own bytes
(`scripts/fairlight_data.py`), reassembles what it wrote to prove every byte
matches, and writes `game_disassembly/fairlight/krumlinde.txt` beside it.

These are the working notes: how the game works, how it was worked out, and
what is still open. The commented disassembly is the build's output
(`game_disassembly/fairlight/`, not committed), and each routine's own
description is there, not repeated here.

## Credit

**Ville Krumlinde**'s disassembly,
[FairlightZ80](https://github.com/VilleKrumlinde/FairlightZ80) -- a labelled,
commented `fairlight.asm` that reassembles to his snapshot, and a folder of
analysis -- was read beside this one (a clone sits untracked at
`game-disassemblies/.fairlight-disassembly-src/`). It has no licence, so,
as with tcdev's Knight Lore map, only facts, addresses and names are taken
from it, each credited where used; every word here is this project's own.
It is a hint, never proof: what it says is checked against the game's own
code and against running it, and where it differs,
[`krumlinde.md`](krumlinde.md) says so. His snapshot is Release 2, so his
addresses are this listing's.

`scripts/build_fairlight_krumlinde.py` (formerly `build_fairlight.py`)
assembles his source as it is, for the emulator's "ZX Spectrum: Fairlight"
launch.

## Status

- **Disassembly: 100%** (stage 2, 2026-09-29). All 42240 bytes from $5B00
  to $FFFF are in 373 entries (86 code, 273 data, 10 text, 2 zeros, 1
  unused, the variables), every one titled, described and labelled -- no
  placeholder titles or labels left; the author's own names used wherever
  his symbol table or his source text gives them. 41607 bytes are what the
  tape loads, 633 the loader's own. It reassembles byte for byte with
  sjasmplus and writes back the snapshot it read; sna2skool, skool2asm and
  sjasmplus give 0 warnings, and the build fails on any.
- **Code map**: 3545 instructions; 3476 ran in the build's sessions, the
  other 69 (154 bytes in 22 runs) were found by following branches, several
  of them run since in staged scenes ([`driving.md`](driving.md)).
  `game_disassembly/fairlight/fairlight-coverage.txt` lists them -- and
  also, wrongly, the first bytes of nine strings after `CALL PRINT` that the
  listing shows as instructions, which is why it says 3580, 104 and 31 runs
  of 192 bytes ([`journal.md`](journal.md)).
- **Generated per record at every build**: the 81 rooms and the 56 parts,
  command by command; the object table (381 records); the templates (57 +
  15) and the patches; the font (40 characters, drawn); the 26 textures
  (drawn); 89 sprites, each with its picture; the 16 strings after the
  printer's CALLs, as text; and what is left of the assembler's symbol table
  (64 names).
- **Notes: complete to the standard** (stage 3, 2026-09-29): a topic file
  per question, below, written from stage 2's five drafts and checked
  against the final listing.
- **Pages (stage 3, in progress)**: how-it-works pages, the castle map,
  graphics, animations, sounds and the reference pages, as page modules.
- **Live**: nothing watched in a running emulator yet. Everything is *read*
  or *measured* in the simulator.

How each claim is known is tagged after it:

- *read* -- from the code (the listing, or the data as the code reads it);
  *searched* and *compared* are kinds of read (a byte search; two copies
  side by side);
- *measured* -- run in SkoolKit's simulator, in the build's sessions or a
  staged scene, and the result read back; *played* -- the same, with keys
  held as a player would;
- *watched* -- live in the emulator (none yet);
- *inferred* -- believed from what was read or measured, but not checked,
  and why; *assumed* -- taken on trust.

Axes, as the listing's variables have them: x is an object's +6, y its +7
(the height of its top), z its +8. Y-P walks +x, Q-T +z.

## The notes

| File | What is in it |
|---|---|
| [`overview.md`](overview.md) | **Start here** -- a tour of the findings, each linked to its deep dive |
| [`journal.md`](journal.md) | What was done when, how, and what turned out wrong |
| [`driving.md`](driving.md) | Running the game in the simulator: the harness, the addresses, the keys, staging recipes and stage 2's scenes, the sessions and their shortcut into a room |
| [`memory-map.md`](memory-map.md) | Every region by address and label, the runtime buffers, every variable at $FF80, and the corrections |
| [`loading.md`](loading.md) | The tape's blocks, the Alkatraz loader, its decryption and checksum, and the hand-over |
| [`start-up.md`](start-up.md) | From the hand-over to the title: the copies, the master copy, and why interrupts are off for good |
| [`loading-tune.md`](loading-tune.md) | The two-voice tune over the loading screen and its player |
| [`sounds.md`](sounds.md) | Every sound: the tune is the only one; the game is silent; the loader's warble |
| [`versions.md`](versions.md) | Release 1 against Release 2: the joystick, the start-up, room 67, three doors, the freeze's lock-up |
| [`symbols.md`](symbols.md) | The author's names: the 64 of the symbol table, and those matched from the source text |
| [`leftovers.md`](leftovers.md) | The source text, the symbol scraps, the loader's leftovers and the unused bytes |
| [`rooms.md`](rooms.md) | How a room is found and drawn, and every drawing command |
| [`textured-fill.md`](textured-fill.md) | The flood fill, the clean copy as its map, and the texture layout |
| [`object-records.md`](object-records.md) | The twenty-byte record, the kind byte, the direction byte, the room's box and the knight's record |
| [`object-table.md`](object-table.md) | The object table's three parts and how a room's records are made from it and the templates |
| [`projection.md`](projection.md) | From a place in the room to a place on the screen |
| [`compositing.md`](compositing.md) | The compositor: a screen byte from an image, four pages and the clean copy |
| [`drawing-objects.md`](drawing-objects.md) | Redrawing a moving object: in front or behind, the sort, the sprite drawer, still things |
| [`printing.md`](printing.md) | The printer, the title page, the message line, the closing lines, the panel's box |
| [`object-states.md`](object-states.md) | CHE3D and every state; the decoy, the book, the freeze, Release 1's lock-up |
| [`movement.md`](movement.md) | The shared movement tail: gravity, the air, riding, climbing, animation |
| [`collision.md`](collision.md) | Boxes, the collision search, blocked moves and pushing |
| [`meeting.md`](meeting.md) | What happens when things meet: hurting, fighting, stealing, pits; strike counters |
| [`chasing.md`](chasing.md) | How the creatures aim at the knight, or at a decoy |
| [`turning-sprites.md`](turning-sprites.md) | Mirroring shared frames in place, and why EEN turns them back |
| [`knight.md`](knight.md) | The knight's keys, jump, fight and falls |
| [`carrying.md`](carrying.md) | Picking up, dropping, weight, where things are remembered; room 19's bug |
| [`doors.md`](doors.md) | Doors and holes: the way through, keys, arrival, a taken far side |
| [`entering-rooms.md`](entering-rooms.md) | EEN on the way out, ROOMST on the way in, the stack |
| [`game-cycle.md`](game-cycle.md) | The title, a new game, GAME OVER; the small input and screen routines |
| [`main-loop.md`](main-loop.md) | One pass, the keys between passes, using things |
| [`quest.md`](quest.md) | How the quest is won or failed, LIFE, keys, room 61 |
| [`bugs.md`](bugs.md) | Every bug found, a line each, linked to where it is argued |
| [`krumlinde.md`](krumlinde.md) | Where Krumlinde's disassembly agrees with this one and where it differs, and how each was checked |
