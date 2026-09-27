# Pentagram -- notes

*Pentagram* (1986, Ultimate Play the Game; credited on its menu to A.C.G.)
for the 48K Spectrum: the fourth Sabreman game and the second built on the
Filmation engine Knight Lore introduced. Sabreman wanders rooms of forest
and ruin drawn in isometric 3D, shooting what falls from the sky. A well
(there are three) gives a bucket when it has been shot at enough; put down in a room with one
of the four quest items, the bucket flies to it and finishes it. When all
four are done the pentagram appears in room 82, and the five collectables,
brought there, fly to their places on it; the fifth ends the game. Control
is rotational only: turn, then walk.

Disassembled from the original tape, `tapes/Pentagram.tzx` (a TZX made
with Ramsoft MakeTZX: a one-line BASIC loader `pent`, the loading screen
`pp` and the game block `game`, CODE 24064,31390), by
`scripts/build_pentagram.py`. The build loads the tape by simulating the
real LOAD, plays the game in SkoolKit's simulator to find out which bytes
are code, lays the level data out a record per entry from the game's own
bytes (`scripts/pentagram_data.py`), and reassembles what it wrote to prove
every byte matches. Only one tape has been looked at; no other release was
compared.

These are the working notes: how the game works, how it was worked out, and
what is still open. The commented disassembly is the build's output
(`game_disassembly/pentagram/`, not committed), and each routine's own
description is there, not repeated here.

## Status

- **Disassembly: 100%** (stage 2, 2026-09-27). All 41472 bytes from $5E00 to
  $FFFF are in 592 entries (192 code, 376 data, 16 text, 5 word tables, 2
  work areas, the variables), every one titled, described and labelled --
  no placeholder titles or labels left -- with the instructions that are not
  self-evident commented, callers listed, and every address the code uses a
  label. It
  reassembles byte for byte with sjasmplus and writes back the snapshot it
  read; sna2skool, skool2asm and sjasmplus give 0 warnings, and the build
  fails on any. The level data -- 139 rooms, 28 scenery templates, 30 object
  templates, the graphic table, 90 sprite records, the font, the update table
  and the quest's tables -- is laid out per record at every build, each
  sprite with its picture.
- **Code map**: 4185 instructions; 4089 ran in the build's sessions, the
  other 96 (196 bytes in 25 runs) were found by following branches
  (`game_disassembly/pentagram/pentagram-coverage.txt`). Stage 2 ran several
  of those in staged scenes (the conveyor push, the quest thing's lift).
- **Notes: complete to the standard** (stage 3, 2026-09-27): a topic file per
  subject, below, written from stage 2's five describing agents' drafts.
- **Pages (stage 3, 2026-09-27, in progress)**: how-it-works pages, the world
  map, graphics, animations, sounds and the reference pages (bugs, pokes,
  facts) are being written as page modules (`PAGE_MODULES` in the build).
- **Live**: the pokes, the bugs and the draw-list crash were watched in a
  private `zx_server` in stage 3 (the Pokes and Bugs pages say how);
  [`driving.md`](driving.md)'s Live driving section has the breakpoints and
  staging used. The rest is read or measured in the simulator.

How each claim is known is tagged after it:

- *read* -- from the code (the listing, or the data as the code reads it);
  *searched* is a kind of read: the loaded block searched for a byte pattern,
  usually an address, to show nothing refers to it;
- *measured* -- run in SkoolKit's simulator, either in the build's own
  sessions or in a staged scene with chosen state, and the result read back;
  which is said;
- *watched* -- live in the emulator with breakpoints or watchpoints (none
  yet);
- *inferred* -- believed from what was read or measured, but not checked, and
  why.

## The notes

| File | What is in it |
|---|---|
| [`overview.md`](overview.md) | **Start here** -- a tour of the findings, each linked to its deep dive |
| [`journal.md`](journal.md) | What was done when, how, and what turned out wrong |
| [`driving.md`](driving.md) | Running the game in the simulator: the build's sessions, what they wait on, staging recipes; live driving to come |
| [`memory-map.md`](memory-map.md) | Where everything is, by address and label: regions, every variable, the object records, the code's tables |
| [`main-loop.md`](main-loop.md) | Start-up, a game, a life, a room, a turn; the update dispatch; the wait that evens the speed |
| [`object-records.md`](object-records.md) | The 54 records and every field and flag bit of one |
| [`graphic-numbers.md`](graphic-numbers.md) | What each of the 172 graphic numbers runs; the drawing nudges; the sprites that draw nothing |
| [`drawing.md`](drawing.md) | The projection, the buffer, turning sprites in place, the masked unrolled draw, the shift tables, what is copied |
| [`depth-order.md`](depth-order.md) | Marking what a move touches, the draw list, the back-to-front sort; the list that may overflow |
| [`collision.md`](collision.md) | The per-axis cut, harm, pushing, riding, conveyors and the "stood on" mark |
| [`player.md`](player.md) | Turning, walking, jumping, falling, the legs and the body |
| [`input.md`](input.md) | The keys and joysticks, `INPUT`, the pause, the directional mode, the stray OUT and the 128K |
| [`world.md`](world.md) | The rooms as a whole: sizes, the 290 doorways, the 19 by 18 layout and its overlaps, where the start, the wells, the quest and the dangers are |
| [`doorways-and-rooms.md`](doorways-and-rooms.md) | Arches, leaving a room, the doorway table, arriving; every doorway walked |
| [`room-building.md`](room-building.md) | The room directory and templates, and how the builder reads them |
| [`lives-and-starting.md`](lives-and-starting.md) | The start rooms, lives, dying, restarting at the last doorway |
| [`carrying.md`](carrying.md) | Picking up, putting down, the queue of three |
| [`bolts-and-sky.md`](bolts-and-sky.md) | Firing, bolts, puffs, scoring, things from the sky and the drop timer's bug |
| [`movers.md`](movers.md) | Blocks, the lift, bobbing and pacing heads, spiders, creatures from the sky, homers, crumbling blocks, conveyors |
| [`quest.md`](quest.md) | The well, the bucket, the quest items, the pentagram, the collectables, winning |
| [`quest-records.md`](quest-records.md) | How the quest's 18 things are kept between rooms |
| [`percentage.md`](percentage.md) | The game-over percentage, and why nothing scores 56 |
| [`menu-and-panel.md`](menu-and-panel.md) | Text, the menu, the border, the panel (lives, score, carried things), the winning and game-over screens |
| [`sound.md`](sound.md) | The note player, the tunes, the effects and one-shot sounds, what is unused |
| [`knight-lore.md`](knight-lore.md) | What the engine shares with Knight Lore, what changed, what is Pentagram's own |
| [`leftovers.md`](leftovers.md) | Unreached code, unused data and variables, and Knight Lore's features cut out with their code left in |

The user's remake has its own notes in the emulator repository
(`examples/filmation/pentagram/driving.md`, and the remake's memory note);
they predate the disassembly, and where they differ these notes, from the
code, are right (see the journal's corrections).
