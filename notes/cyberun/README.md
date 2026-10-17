# Cyberun -- notes

*Cyberun* (1986, Ultimate Play the Game) for the 48K Spectrum: a ship
flies over and under a planet's surface, gathering add-ons, fighting off
attackers and building a rocket from eight parts, one of them an ore tank
to be filled by mining, against a fuel gauge that empties as the ship
moves. Its landscape scrolls smoothly in 2-pixel steps, redrawn every pass
from tile records onto a screen that is never cleared.

Disassembled from the original tape,
`tapes/Cyberun (1986)(Ultimate Play The Game).tzx` (a BASIC loader `CYBER`,
a block `PIC`, CODE 24576,6990, and the game `CY`, CODE 24192,40300), by
`scripts/build_cyberun.py`. The build loads the tape by simulating the real
LOAD, which runs the game's own loader to move and decode the block, plays
the game in SkoolKit's simulator to find out which bytes are code, and
reassembles what it wrote to prove every byte matches. Only one tape has
been looked at; no other release was compared.

These are the working notes: how the game works, how it was worked out, and
what is still open. The commented disassembly is the build's output
(`game_disassembly/cyberun/`, not committed); each routine's own
description is there, not repeated here.

## Status

- **Stage 0 (2026-10-16):** a first look live, in a private `zx_server`,
  before any listing existed: the loader, the controls, the landscape's
  renderer, lives, damage and fuel, and three pokes tested live.
- **Stage 1 (2026-10-16):** the build. The tape is loaded by simulation to
  $5C80, after the game's own loader has moved and decoded the block; eight
  play sessions (the menu, each control method, long flights both ways, an
  empty tank, a game over, two players, the pause keys) map the code, and
  branches are followed out of what ran.
- **Stage 2 (2026-10-16): the listing is complete.** All 42240 bytes from
  $5B00 to $FFFF are in 900 entries (419 code, 280 data, 195 variables, 5
  work areas, 1 unused), every one titled, described and labelled, with the
  instructions that are not self-evident commented. It reassembles byte for
  byte and writes back the snapshot it read; sna2skool, skool2asm and
  sjasmplus give 0 warnings, and the build fails on any. Eight agents
  described the listing by address range in two passes, checked against
  each other; three more wrote the topic notes below from it and found the
  corrections the listing has since taken.
- **Code map:** 11340 instructions; 10745 ran in the build's sessions
  (95%) and 595 were found by following branches (`cyberun-coverage.txt`).
  Staged scenes, each a new life put somewhere by the game's own restart
  ([`driving.md`](driving.md)), ran what play would not reach in time: the
  launch from inside the finished rocket through the planet-secured screen
  to the next planet, a rocket part and the full ore tank delivered, all
  nine add-ons with the special beam and missiles, and tours at five depths
  of the map. The build fails if any executed address lies in an entry
  typed as data -- a guard added when a staged tour, probably started
  inside rock in the deepest caverns, sent the ship off the bottom of the
  map and the game into the frame's bitmaps.
- **Level data:** laid out record by record from the game at every build by
  `scripts/cyberun_data.py` -- the world's objects, the pick-ups' places and
  their dealing, the map and the tile records -- and every graphic's picture is
  in its entry.
- **Stage 3 (2026-10-17): the HTML pages are built** by six page modules
  (`scripts/cyberun_howitworks.py`, `_world`, `_graphics`, `_animations`,
  `_sounds`, `_reference`), each from the game's own bytes and, wherever
  there is code for it, by running the game's own routines in SkoolKit's
  simulator: eight how-it-works pages with worked examples; the planet --
  the whole map drawn cell by cell by the game's renderer, checked against
  the game's own first screen to 100.00% of its pixels, with fifteen
  layers -- its 171 tiles, the objects in it and the pick-up places; the
  landscape pieces at four shifts, every sprite and bitmap, the object
  types, the add-ons and rocket parts, the menu and panel; 28 animations;
  17 effects, 5 tunes and 8 recorded runs, each matched to its routine to
  the T-state; and the bugs, pokes (each tried against the same trial
  without it) and facts. Built with `--html`, 0 warnings; published
  2026-10-17 with `scripts/publish_pages.py --game cyberun`.

How each claim is known is tagged after it: *read* (from the code), *watched*
(watchpoint, logpoint, rewind in a running game), *measured* (instrumented run
over many cases), *run* (seen in a run in SkoolKit's simulator: the build's
sessions or a page's staged scene), *simulated* (a routine run in the simulator
on its own), *played* (seen in play) or *assumed*.

## Index

| File | What |
|---|---|
| [`overview.md`](overview.md) | **Start here**: a tour of the findings |
| [`journal.md`](journal.md) | What was done when |
| [`driving.md`](driving.md) | How to run it in the simulator and the emulator: keys, variables, staging, pokes for long runs |
| [`memory-map.md`](memory-map.md) | What is where: every region and every variable, by address and label |
| [`loading.md`](loading.md) | The tape, the BASIC, the nibble-shifted game block and the start-up tables |
| [`main-loop.md`](main-loop.md) | The start, the outer loop, a life, a pass, the death sequence, pause, the end |
| [`players.md`](players.md) | One or two players: the 105-byte records, swapping turns, scores |
| [`input.md`](input.md) | The control methods, the keys, the special key, the pause |
| [`landscape.md`](landscape.md) | The map, tiles, pieces, shift tables, POP blitters, the never-cleared screen |
| [`landscape-collision.md`](landscape-collision.md) | The per-screen box lists and the bounce rules |
| [`sprites.md`](sprites.md) | The compositor, the direct drawer, the ship's picture, colours, stars, the trail |
| [`world-and-objects-in-it.md`](world-and-objects-in-it.md) | The 290 objects lying in the world, brought in and freed as the view moves |
| [`objects.md`](objects.md) | The nine flying records, their types, handlers, frames and contact effects |
| [`attackers.md`](attackers.md) | Spawning, the waves, steering, what the ground throws, debris, missiles' targets, scoring |
| [`ship.md`](ship.md) | The ship's record and physics, its add-ons, jets, trail, carrying, the restart point |
| [`weapons.md`](weapons.md) | Lasers, missiles, the special beam, the flickering beams |
| [`rocket-and-ore.md`](rocket-and-ore.md) | The goal: the parts, the ore, docking, the launch, the next planet |
| [`damage-fuel-lives.md`](damage-fuel-lives.md) | Hits, repair, the shield, fuel, lives, the death byte |
| [`panel-and-menu.md`](panel-and-menu.md) | The menu, frames, panel, fuel gauge, font and text |
| [`sound.md`](sound.md) | The beeper effects, the tune player and the tunes |
| [`pokes.md`](pokes.md) | Pokes, the tested ones and the ones read from the code |
