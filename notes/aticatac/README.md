# Atic Atac -- notes

*Atic Atac* (1983, Ultimate Play the Game; written by Tim and Chris Stamper,
credited on its title screen to A.C.G.) for the 48K Spectrum: a knight, a
wizard or a serf trapped in a castle of 149 rooms, drawn from above, hunting
for the three pieces of the A.C.G. key that open the great door out, while
the castle's creatures drain the life force a roast chicken on the status
scroll stands for.

Disassembled from a `.tap` of the original release, `Atic Atac.tap` (ZXDB
entry 0009305), which is kept in the user's Downloads, not `tapes/`:
`C:/Users/jonso/Downloads/Atic Atac (1983)(Ultimate).tap`. The build takes it
with `--tape`, by `scripts/build_aticatac.py`. The tape is a BASIC loader,
a loading screen and five CODE blocks, the game among them *encrypted*; the
build loads it by running the tape's own loader and decryptor in SkoolKit's
simulator, plays the game in the simulator to find out which bytes are code,
and reassembles what it wrote to prove every byte matches
([`loading.md`](loading.md)). Only one release has been looked at; no other
was compared.

These are the working notes: how the game works, how it was worked out, and
what is still open. The commented disassembly is the build's output,
published at <https://jonsole.github.io/zx-spectrum-disassemblies/aticatac/>,
with the castle map, every room drawn with what is in it, the room types,
the sprites, the graphics and the sounds; each routine's own description is
there, not repeated here.

## Credit

The names of the furniture graphics ($A2 upwards: the clock, the bookcase,
the barrel, the suit of armour and the rest) and the way the pictures are
drawn in the listing (`#UDGARRAY` over the game's own bytes) come from
pobtastic's Atic Atac disassembly at
<https://skoolkit.arcadegeek.co.uk/ultimate/aticatac/>, which reached the
game first. Comparing with it is also what showed that the furniture has a
format of its own ([`drawing.md`](drawing.md)). The facts are used with
credit; the words here are our own.

## Status

- **Disassembly:** 100% -- all 30208 bytes of the decrypted game, $6000-$D5FF,
  about a thousand labelled entries (631 when the data was first covered, then
  one per room list, door and graphic), every routine named and described, every
  address the code uses a label or an equate, round trip byte for byte, no
  build warnings (2026-09-24). The code/data map came from playing the game in
  the simulator; routines it never reached (the collectables' handler, the
  trapdoor fall, the end screen) were declared code from the handler tables
  and checked by the round trip.
- **Pages:** tape protection, how it is put together, where the data goes,
  the map (five floors), the room types, the sprites (with animations), the
  graphics, the sounds, one bug, one poke, facts. Not yet to the Knight Lore
  standard: there are no how-it-works pages per mechanism, no GIF animations
  of the characters dying and rising, and no layers on the map for where the
  keys, the A.C.G. pieces and the monsters are. These notes are the material
  for them.
- **Evidence:** most of what is here is *read* from the listing. On 2026-09-27,
  for these notes, a scratch harness in SkoolKit's simulator started games
  from the build's snapshot and *measured* the characters' coasting, the
  dying and rising speeds, the length of a main-loop pass and where its time
  goes, monster collisions and kills, the spanner and Frankenstein, the
  A.C.G. door's order, the pick-up key, the pause, food regrowing, the timed
  doors, and the first game's key rooms. Nothing in these notes was tried in
  the emulator (`zx_server`); the annotations' own "watched live" remarks
  come from an earlier session and are quoted as such.
- **Corrections:** these notes found about thirty annotation and ref
  statements that the code contradicts -- a routine called TEST_ROOM_BOXES that
  is the player's collision test, PLACE_ACG_KEY that hides the A.C.G. key,
  REGROW_FOOD that regrows food, PAUSE that is the pause, sounds
  attributed to the wizard that every weapon makes. Each is in its topic
  file's "Disassembly corrections" and listed in [`journal.md`](journal.md).
  All were applied the same day to the annotations, the ref and the build's
  page text, with about ninety labels renamed for what they do (each note's
  "Renamed routines" table); the rebuild verified byte for byte with 3
  warnings, down from 11, none new.

How each claim is known is tagged after it:

- *read* -- from the code (the listing, or the ROM it calls);
- *played* -- in the build's scripted playthrough in SkoolKit's simulator;
- *measured* -- a run with chosen inputs or staged state in the simulator,
  with the result read back;
- *watched* -- live in the emulator with breakpoints or watchpoints (only the
  annotations' own earlier remarks, marked as such);
- *assumed* -- believed but not checked, and why.

## Index

| Note | What it covers |
|---|---|
| [`overview.md`](overview.md) | **Start here** -- a tour of the findings, each linked to its deep dive |
| [`journal.md`](journal.md) | What was done when, and what turned out wrong |
| [`driving.md`](driving.md) | Running the game from a script: snapshot, breakpoints, keys, staging, traps |
| [`memory-map.md`](memory-map.md) | Where everything is, by address and label: code, tables, graphics, variables, the runtime records |
| [`loading.md`](loading.md) | The BASIC loader, the RRD decryptor, the FRAMES check, the poked JP (HL), and the fixed first game |
| [`main-loop.md`](main-loop.md) | MAIN_LOOP and FRAME_TICK: two rates, what a pass costs, the pause |
| [`records.md`](records.md) | The eight- and sixteen-byte records, the sprite byte as a type, the handler table, the runtime areas |
| [`castle.md`](castle.md) | Rooms, shapes and colours, walk limits, the room lists, the floors and the map |
| [`doors.md`](doors.md) | Door records and kinds, walking through, the arrival walk, timed doors, trapdoors, the characters' doors |
| [`drawing.md`](drawing.md) | Room outlines, furniture in eight orientations, sprites shifted to the pixel, erase-and-redraw, attributes |
| [`player.md`](player.md) | The three characters: movement and coasting, weapons, fire sounds, the doors only one can use |
| [`monsters.md`](monsters.md) | Spawning, the small creatures' movers, the five big monsters, kills and bursts |
| [`collision.md`](collision.md) | The walk rectangle, doorway and table boxes, the 12-pixel tests, door boxes |
| [`food-and-health.md`](food-and-health.md) | The life force, every drain, food and its regrowth, mushrooms, dying, lives, game over |
| [`objects-and-inventory.md`](objects-and-inventory.md) | The collectables, the pick-up key, the three-slot queue, dropping, the humpback |
| [`keys-and-locked-doors.md`](keys-and-locked-doors.md) | The four keys, where they go, the coloured doors, and doors that stay open |
| [`acg-key-and-winning.md`](acg-key-and-winning.md) | The three pieces, where they are hidden, the order the door wants, room $8E, CONGRATULATIONT |
| [`status-panel.md`](status-panel.md) | The scroll: clock, score, roast, lives, inventory, its colour; the end-of-game figures and the percentage |
| [`input.md`](input.md) | The title menu, keyboard / Kempston / cursor, fire, pick up, pause |
| [`sounds.md`](sounds.md) | Every sound: BEEP, the sound slot, footsteps, fire, bounce, rasp, the fall |
