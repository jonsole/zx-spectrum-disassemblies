# Ant Attack -- notes

*Ant Attack* (1983, Sandy White; published by Quicksilva) for the 48K
Spectrum: the game with the walled city of Antescher drawn in solid
isometric blocks, in which a boy or a girl goes in to find the other and
lead them out past the ants. Half of it is BASIC (the title, the story
cards, the score, setting up each level) and half machine code (the city,
the movement, the drawing).

Disassembled from the original Quicksilva tape, `tapes/Ant Attack.tzx`
(ZXDB entry 0000210; a TZX made with Ramsoft MakeTZX: a program header
auto-running line 1, a 76-byte loader, and one headerless block of 41984
bytes), by `scripts/build_antattack.py`. The build loads the tape by
simulating the real LOAD, plays the game in SkoolKit's simulator to find out
which bytes are code, and reassembles what it wrote to prove every byte
matches. Only one version has been looked at; no other release was
compared.

These are the working notes: how the game works, how it was worked out, and
what is still open. The commented disassembly is the build's output,
published at <https://jonsole.github.io/zx-spectrum-disassemblies/antattack/>,
and each routine's own description is there, not repeated here.

## Status

- **Disassembly:** 100% -- all 41984 bytes the tape block loads ($5C00-$FFFF),
  the system variables and the game's BASIC included; every routine named,
  described and commented; every address the code uses a label; no build
  warnings. Every instruction in the code map ran in the build's playthrough
  but three, in `FALL`, behind a flag nothing sets. On 2026-09-27 the lead is
  splitting the big data entries: every sprite frame its own entry at
  $8000 + 64 x frame, every row of the city its own entry at
  $C000 + 128 x row, and the filler blocks labelled (`..._PAD`).
- **Pages:** How the game works, the City, the Levels, the Sprites and the
  Scripts since 2026-09-24. On 2026-09-27 parallel agents are adding
  how-it-works pages, animations, sounds and the reference pages (bugs,
  pokes, facts) as modules (`scripts/antattack_*.py`), to the Knight Lore
  standard.
- **Evidence so far:** most of what is here is *read* from the code. The
  build's scripted playthrough and a dozen staged scenes ran every
  instruction but three in the simulator. For these notes, falls, walking
  into one's own grenade, a blast waking a paralysed ant, the grenade's home
  coming into view and two events in one frame were *measured* in the
  simulator (2026-09-27). Frame costs were *measured* live in a private
  `zx_server` (2026-09-24). The driving recipe and several findings were
  *watched* live on 2026-09-27 by the agent testing pokes, each marked
  where it is used.
- **Not yet:** the pokes, being tested live (2026-09-27), go into
  [`driving.md`](driving.md) and the pokes page when done. Only one tape has
  been looked at; no other release compared.

How each claim is known is tagged after it:

- *read* -- from the code (the listing, the BASIC, or the ROM it calls);
- *played* -- in the build's scripted playthrough in SkoolKit's simulator;
- *measured* -- a run with chosen inputs or staged state, in the simulator or
  live, with the result read back; which one is said;
- *watched* -- live in the emulator with breakpoints or watchpoints;
- *assumed* -- believed but not checked, and why.

## Index

| Note | What it covers |
|---|---|
| [`overview.md`](overview.md) | **Start here** -- a tour of the findings, each linked to its deep dive |
| [`journal.md`](journal.md) | What was done when, and what turned out wrong |
| [`driving.md`](driving.md) | Running the game from a script: snapshots, breakpoints, keys, staging, traps |
| [`memory-map.md`](memory-map.md) | Where everything is, by address and label; code, data, unused |
| [`loading.md`](loading.md) | The loader, the load over the system variables, and why BREAK restarts the game |
| [`basic-and-levels.md`](basic-and-levels.md) | What the BASIC does: the flow of a game, setting up a level, the ten levels, retries |
| [`main-loop.md`](main-loop.md) | `PLAY` and `GAME_FRAME`: the order of a frame and how the machine code hands back to BASIC |
| [`objects.md`](objects.md) | The 16-byte record shared by the player, the rescued person, the grenade and the ants |
| [`city-map.md`](city-map.md) | The 128 x 128 map of height bits, the wrapping world outside it, the gate |
| [`drawing.md`](drawing.md) | The view: gathering, planes, the CPIR painter, the sprites threaded in, the copy |
| [`movement-and-collision.md`](movement-and-collision.md) | One move routine for everything; the map as the only solid thing; jumping and climbing |
| [`falling.md`](falling.md) | The grace frame, how long a fall is, bad falls, and the landings that never happen |
| [`ants.md`](ants.md) | How an ant chases, its speed, the random turns, paralysis, the ants in the map |
| [`grenades.md`](grenades.md) | Throwing, flight, the blast radius, and what a grenade does to people |
| [`energy-and-events.md`](energy-and-events.md) | Bites, blasts and bad falls as events; energy; two events in one frame |
| [`rescue-and-scoring.md`](rescue-and-scoring.md) | Finding the person, the scanner, following, leading them out, the score, the end |
| [`scripts.md`](scripts.md) | The script format that carries every message (and sound); what shows each one; the game stopping while one plays |
| [`sounds.md`](sounds.md) | Every sound: `TONE`, `NOISE`, the note table, footsteps, the BASIC's BEEPs, and the recordings checked against the code |
| [`performance.md`](performance.md) | What a frame costs, where the time goes, and why the game has no frame pacing |
| [`leftovers.md`](leftovers.md) | What is in the game but unused: signatures, a stray script, frames, NOPs, variables |
