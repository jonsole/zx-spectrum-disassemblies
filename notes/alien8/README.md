# Alien 8 -- notes

*Alien 8* (1985, Ultimate Play the Game; credited on its menu to A.C.G.)
for the 48K Spectrum: the second game built on the Filmation engine Knight
Lore introduced, a year before Pentagram. A robot wanders the rooms of a
starship drawn in isometric 3D, carrying valves to the ship's 24 cryogenic
chambers: a valve of the right kind put on a chamber's socket activates it,
and the twenty-fourth ends the game. A clock on the panel -- the light
years left -- runs down meanwhile, and when it reaches zero the game is
over; the summary after a game counts the frozen crew in the chambers not
activated as lost. Rooms hold deadly things, things that drop from the
ceiling, and robots driven by buttons on the floor.

Disassembled from the original tape, `tapes/Alien 8 (1985)(Ultimate).tap`
(a BASIC loader `Alien8.1`, the loading screen `Alien8.2` and the game block
`Alien8.3`, CODE 25341,40195), by `scripts/build_alien8.py`. The build loads
the tape by simulating the real LOAD, plays the game in SkoolKit's simulator
to find out which bytes are code, lays the level data out a record per entry
from the game's own bytes (`scripts/alien8_data.py`), and reassembles what it
wrote to prove every byte matches. Only one tape has been looked at; no other
release was compared.

These are the working notes: how the game works, how it was worked out, and
what is still open. The commented disassembly is the build's output
(`game_disassembly/alien8/`, not committed), and each routine's own
description is there, not repeated here.

## Status

- **Disassembly: 100%** (stage 2, 2026-09-27). All 42240 bytes from $5B00 to
  $FFFF are in 622 entries (222 code, 358 data, 34 text, 2 word tables, 3
  work areas -- the panel's record, the draw list and the stack -- 2 unused
  and the variables), every one titled,
  described and labelled -- no placeholder titles or labels left -- with the
  instructions that are not self-evident commented, callers listed, and
  every address the code uses a label. It reassembles byte for byte with
  sjasmplus and writes back the snapshot it read; sna2skool, skool2asm and
  sjasmplus give 0 warnings, and the build fails on any. The level data --
  128 rooms, 37 object templates, 14 backgrounds, the 36 places, the graphic
  table, 78 sprites, the font and the update table -- is laid out per record
  at every build, each sprite with its picture.
- **Code map**: 4602 instructions; 4550 ran in the build's sessions, the
  other 52 (117 bytes in 14 runs) were found by following branches
  (`game_disassembly/alien8/alien8-coverage.txt`; each run explained in
  [`leftovers.md`](leftovers.md)). Stage 2 ran several of them in staged
  scenes (the socket's sparkle returning, the dropping block sinking).
- **Notes: complete to the standard** (stage 3, 2026-09-27): a topic file
  per subject, below, written from stage 2's five describing agents' drafts.
- **Pages (stage 3, 2026-09-27, in progress)**: how-it-works pages, the
  world map, graphics, animations, sounds and the reference pages (bugs,
  pokes, facts) are being written as page modules (`PAGE_MODULES` in the
  build).
- **Live**: the pokes, most bugs and the 128K crash were watched in a private
  `zx_server` in stage 3 (the Pokes and Bugs pages say how);
  [`driving.md`](driving.md)'s Live driving section has the breakpoints and
  staging. The rest is *read* or *measured* in the simulator.

How each claim is known is tagged after it:

- *read* -- from the code (the listing, or the data as the code reads it);
  *searched* is a kind of read: the loaded block searched for a byte pattern,
  usually an address, to show nothing refers to it; *compared* is a read of
  two games' bytes side by side;
- *measured* -- run in SkoolKit's simulator, either in the build's own
  sessions or in a staged scene with chosen state, and the result read back
  (a screenshot of the simulated screen counts); which is said;
- *watched* -- live in the emulator with breakpoints or watchpoints;
- *inferred* -- believed from what was read or measured, but not checked, and
  why.

## The notes

| File | What is in it |
|---|---|
| [`overview.md`](overview.md) | **Start here** -- a tour of the findings, each linked to its deep dive |
| [`journal.md`](journal.md) | What was done when, how, and what turned out wrong |
| [`driving.md`](driving.md) | Running the game in the simulator: the build's sessions, staging recipes, stepping a turn at a time; live driving |
| [`memory-map.md`](memory-map.md) | Where everything is, by address and label: the regions, every variable, the object records, the code's tables |
| [`main-loop.md`](main-loop.md) | Start-up, a game, a life, a room, a turn; the dispatch; the wait that evens the speed |
| [`object-records.md`](object-records.md) | The 56 records and every field and flag bit of one |
| [`graphic-numbers.md`](graphic-numbers.md) | What each of the 132 graphic numbers runs; the drawing nudges; the sprites |
| [`drawing.md`](drawing.md) | The projection, the buffer, turning sprites in place, the masked unrolled draw, the tables, what is copied out |
| [`depth-order.md`](depth-order.md) | Marking what a move touches, the draw list, the back-to-front sort; the valve it destroys |
| [`collision.md`](collision.md) | The per-axis cut, harm, pushing, riding, the Z step handed on, "landed on" |
| [`robot.md`](robot.md) | The legs and the top, turning through the in-between views, the lost step, walking, jumping, falling |
| [`carrying-and-lifts.md`](carrying-and-lifts.md) | Pushable blocks, shuttles, conveyors, sinking and collapsing blocks, lifts and bobbing blocks and their shared top |
| [`creatures.md`](creatures.md) | The two-record creatures, the chasers, the mice, the leapers, the ceiling drops, the fragile and the still deadly things |
| [`doorways-and-rooms.md`](doorways-and-rooms.md) | The pillars, leaving a room, the grid, arriving at the matching doorway |
| [`room-building.md`](room-building.md) | The room directory and templates, and how the builder reads them; the live placement nudge |
| [`valves-and-sockets.md`](valves-and-sockets.md) | The places, dealing the valves and extra lives, a valve steering to its socket, the socket's sparkle; the six-valve game |
| [`picking-up.md`](picking-up.md) | Picking up and putting down, the three carried, the panel's boxes |
| [`chambers-and-summary.md`](chambers-and-summary.md) | Activating a chamber, winning, the end of a game, the summary's counts and the rating |
| [`scenes.md`](scenes.md) | The re-programming after a loss and the oiling after a win |
| [`clock.md`](clock.md) | The light years: the rolling digits, the rate, the end |
| [`remote-robots.md`](remote-robots.md) | The buttons, the pad and the robots they drive |
| [`lives-and-starting.md`](lives-and-starting.md) | The start records and rooms, lives, dying, appearing, the extra life |
| [`input.md`](input.md) | The keys and joysticks, `INPUT`, directional control, the pause, the stray OUT and the 128K |
| [`menu-and-panel.md`](menu-and-panel.md) | The menu, the text and number printers, the panel's pieces and colours, the border |
| [`sound.md`](sound.md) | The note player, the five tunes, the effects and who plays them, what is unused |
| [`knight-lore-and-pentagram.md`](knight-lore-and-pentagram.md) | What Alien 8 shares with Knight Lore and with Pentagram, where it differs, what is its own |
| [`leftovers.md`](leftovers.md) | Dead code, code that never runs and why, unused variables, the old copyright line, the Interface 1 debris above the code |
