# Nightshade -- notes

*Nightshade* (1985, Ultimate Play the Game; credited on its menu to A.C.G.)
for the 48K Spectrum: the first Filmation II game. A knight walks the
streets and buildings of a plague-ridden town drawn in isometric 3D -- not
a flip-screen of rooms like Knight Lore, Alien 8 and Pentagram, but a view
that follows him over a 32 by 32 map of cells and can be turned to see the
town from the other side. Monsters come at him; each touch changes his
colour (white, yellow, green) and the third ends a life. He throws
antibodies found in the buildings at them. Four objects lie somewhere in
the town, and each thrown at its own villain -- four of them, pictured on
the panel -- destroys it; with all four gone the ending plays. A percentage
after the game counts the cells visited and the villains destroyed.

Disassembled from the original tape, `tapes/Nightshade (1985)(Ultimate).tzx`
(the user's upload, a Ramsoft MakeTZX image: a BASIC loader `NIGHT`, the
loading screen `SP`, the game `0` and three small blocks `1`, `2`, `3` that
are protection), by `scripts/build_nightshade.py`. The build loads the tape
by simulating the real LOAD and the tape's own loader, checks the loader's
unscrambling against the tape's bytes, plays the game in SkoolKit's
simulator to find out which bytes are code, lays the level data out a
record per entry from the game's own bytes (`scripts/nightshade_data.py`),
and reassembles what it wrote to prove every byte matches. Only this one
tape has been looked at; no other release was compared.

These are the working notes: how the game works, how it was worked out, and
what is still open. The commented disassembly is the build's output
(`game_disassembly/nightshade/`, not committed), and each routine's own
description is there, not repeated here.

## Status

- **Disassembly: 100%** (stage 2, 2026-09-28). All 42240 bytes from $5B00
  to $FFFF are in 476 entries (189 code, 272 data, 3 text, 6 word tables,
  the draw list, 4 unused and the variables), every one titled, described
  and labelled -- no placeholder titles or labels left. It reassembles byte
  for byte with sjasmplus and writes back the snapshot it read; sna2skool,
  skool2asm and sjasmplus give 0 warnings, and the build fails on any. The
  level data -- the town map, the drawing order, 58 buildings, the boxes of
  36 cell types, the tiles' edge bytes, 51 tiles and 3 edge pictures, the
  graphic table, 94 sprites, the fonts and icon characters, the notes and
  6 tunes, the menu's and the end's text, the record templates and the
  update table -- is laid out per record at every build, each sprite and
  tile with its picture. Two labels stage 1 had (`TAKE_LIFE`,
  `DRAW_STEP_DONE`) were lost in the merge and are reported for putting
  back.
- **Code map**: 4806 instructions; 4705 ran in the build's sessions, the
  other 101 (156 bytes in 10 runs) were found by following branches
  (`game_disassembly/nightshade/nightshade-coverage.txt`; each run, and two
  the file does not list, explained in [`leftovers.md`](leftovers.md)).
  Stage 2 ran two of them in staged scenes.
- **Notes: complete to the standard** (stage 3, 2026-09-28): a topic file
  per subject, below, written from stage 2's five describing agents' drafts
  and checked against the final listing.
- **Pages (stage 3, in progress)**: how-it-works pages, the town map,
  graphics, animations, sounds and the reference pages (bugs, pokes,
  facts), as page modules.
- **Live**: nothing watched in a running emulator yet. Stage 3 is checking
  the 100% print and the 156-game crash live
  ([`driving.md`](driving.md)); everything else is *read* or *measured* in
  the simulator.

How each claim is known is tagged after it:

- *read* -- from the code (the listing, or the data as the code reads it);
  *searched* and *compared* are kinds of read (a byte search of the
  snapshot; two copies of bytes side by side);
- *measured* -- run in SkoolKit's simulator, in the build's own sessions or
  a staged scene, and the result read back (a rendered screen counts);
- *watched* -- live in the emulator (none yet);
- *inferred* -- believed from what was read or measured, but not checked,
  and why; *assumed* -- taken on trust.

## The notes

| File | What is in it |
|---|---|
| [`overview.md`](overview.md) | **Start here** -- a tour of the findings, each linked to its deep dive |
| [`journal.md`](journal.md) | What was done when, how, and what turned out wrong |
| [`driving.md`](driving.md) | Running the game in the simulator: the harness, the protection's traps, staging recipes, the sessions; live driving |
| [`memory-map.md`](memory-map.md) | Where everything is, by address and label: the regions, the code by subject, the tables, every variable, the records |
| [`protection.md`](protection.md) | The tape, the loader, the four checks, the lives byte, the stack leak and the 156-game crash |
| [`main-loop.md`](main-loop.md) | Start-up, a new game, a turn; the dispatch through `NMIADD` |
| [`object-records.md`](object-records.md) | The 23 records and every field and flag bit of one |
| [`graphic-numbers.md`](graphic-numbers.md) | What each of the 158 graphic numbers runs and shows; shared pictures |
| [`town.md`](town.md) | The map, the cell types, buildings, boxes, tiles and edges; the 625 cells |
| [`drawing-order.md`](drawing-order.md) | The nine cells round the knight, and the 32 orders they are drawn in |
| [`drawing-the-town.md`](drawing-the-town.md) | Walls behind, outlines in front, column claims, tiles and colour |
| [`projection.md`](projection.md) | The projection from the knight, and the turned-round view |
| [`depth-order.md`](depth-order.md) | The depth sort of the things in one cell |
| [`drawing-sprites.md`](drawing-sprites.md) | Sprites, turning them in place, the buffer, the tables, the copy |
| [`collision.md`](collision.md) | Trimming a step at the boxes of the cells ahead |
| [`movement.md`](movement.md) | Steps, steering, wandering, chasing; why the villains never chase |
| [`touching.md`](touching.md) | The overlap test and who tests whom; the second antibody that never strikes |
| [`knight.md`](knight.md) | His controls, turning, speeding up, stopping on the grid, throwing, his top |
| [`input.md`](input.md) | The keys and joysticks, the pause, the stray `OUT` and the 128K |
| [`monsters.md`](monsters.md) | Spawning, kinds from the nearest villain, wanderers and walkers, the stray |
| [`antibodies-and-strikes.md`](antibodies-and-strikes.md) | Antibody kinds and what a strike does; the split that does not split |
| [`creature.md`](creature.md) | The creature every 256 turns |
| [`quest.md`](quest.md) | The objects and villains: placing, the pairs, the strike, dying, sparkles, the end |
| [`finds-and-bonuses.md`](finds-and-bonuses.md) | Finds in buildings and their stock; the bonuses and where they go |
| [`carrying.md`](carrying.md) | The eleven places, last in first out, the icons, the villain-near hint |
| [`lives-and-starting.md`](lives-and-starting.md) | The start cell, lives, hits, a new life, the start records |
| [`game-over-and-ending.md`](game-over-and-ending.md) | The game-over screen and the ending over the pit |
| [`percentage.md`](percentage.md) | Cells and villains to exactly 100%, and why 100 prints wrong |
| [`menu-and-panel.md`](menu-and-panel.md) | The menu, the printer, the frames, the score, the heading, the compass, the villains |
| [`sound.md`](sound.md) | The note table, the six tunes, the effects and who plays them, the broken hum |
| [`random-numbers.md`](random-numbers.md) | The stir with R, and the ROM read as random bytes |
| [`knight-lore-alien8-pentagram.md`](knight-lore-alien8-pentagram.md) | What Nightshade shares with the Filmation games, and what is its own |
| [`bugs.md`](bugs.md) | Every bug found, a line each, linked to where it is argued |
| [`bugs-and-pokes.md`](bugs-and-pokes.md) | Each bug demonstrated for the Bugs page (simulator, and live for three), and the seven tested pokes, among them infinite lives past the game's check |
| [`leftovers.md`](leftovers.md) | Code that never runs and why, unread tables, unused cell types, memory outside the code |
