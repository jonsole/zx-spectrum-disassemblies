# Driving Atic Atac

**Question this answers:** how to run the game from a script in the emulator
-- get from the load to a game, step it a frame or a pass at a time, move,
fire and pick up, and stage a room, an inventory or an ending -- without
timing anything.

**Short answer:** load `game_disassembly/aticatac/aticatac.z80` (the machine as
the decryptor hands over, PC $6000). The title screen polls the keyboard in a
loop from $7C2F; hold a key between two stops there, then 0 to start. In play,
$7EB2 (`FRAME_TICK`) is reached once per 50 Hz frame and $7DC3 (`MAIN_LOOP`)
once per pass; hold keys between stops. The player is at $EA90, the room in
$EA91.

Most addresses here are *read* from the listing, and the recipes marked
*measured* were run in SkoolKit's simulator (the scratch harness
`aticatac_sim.py`, 2026-09-27) with the same breakpoint-and-hold method.
Those marked *watched* were run live on a private zx_server later the same
day; see [Driven live](#driven-live) at the end.

## The snapshot

The tape is `C:/Users/jonso/Downloads/Atic Atac (1983)(Ultimate).tap` (not in
`tapes/`); `scripts/build_aticatac.py --tape <it>` makes everything below.

`game_disassembly/aticatac/aticatac.z80` is the build's `tap2sna` output:
interrupts off, PC at `ENTRY` ($6000), FRAMES $256F. `aticatac.sna` beside it
is rebuilt from the reassembled bytes; a `.sna` keeps PC on the stack, which
the game resets at once (`LD SP,$5E00`), so it should behave the same
(*assumed*). `load_debug_info` with `aticatac.sld` and `aticatac.asm` gives
the labels.

The first game from this snapshot always hides the A.C.G. pieces in rooms
$17, $10, $2B, the green key in $22, the red key and the mummy in $85, the
cyan key in $91, the yellow in $66 ([`loading.md`](loading.md); *measured*).

## The breakpoints

| Address | Label | Stopped here means |
|---|---|---|
| $6000 | `ENTRY` | loaded; about to check FRAMES |
| $7C2F | in `TITLE_SCREEN` | top of the menu loop: keys are read at $7C36 and $7C66 on every turn (*read*) |
| $7D9A | `START_GAME` | 0 was seen; the castle is being set up |
| $7DC3 | `MAIN_LOOP` | top of a pass: once every ~1.7 frames in room $00 (*measured*) |
| $7EB2 | `FRAME_TICK` | a 50 Hz frame: the player, weapon and sound are about to move; stops once a frame (*measured*: 500 stops in 510 frames) |
| $8E78 | `PLAYER_TICK` | the player is in play and has just moved (not reached while rising or sinking) |
| $8CB7 / $8D45 | `MATERIALISING` / `DYING` | the player is rising / sinking |
| $9117 | `ENTER_ROOM` | going through a door; IX is the half touched |
| $9147 | `ARRIVE_IN_ROOM` | a room is about to be drawn (also the start of a game) |
| $9731 | `TRAPDOOR_FALL` | an open trapdoor is being tested; the fall itself starts at $973A |
| $840D | in `SPAWN_MONSTER_INTO_ROOM` | a creature is about to be put in a free slot (DE = the slot) |
| $875F | `KILL_MONSTER` (was `DRAW_MONSTER`) | a creature is being destroyed; IX = it |
| $8EA0 | `LOSE_LIFE` | a life is lost |
| $92F5 / $93E3 | `PICK_UP` / `PUT_DOWN` | each pass for objects in the room / the drop controller |
| $94A1 | in `PAUSE` | paused: waiting for SPACE to be pressed again (*measured*) |
| $8C35 | `GAME_OVER` | no lives left; the title follows about 10 s later at $7C29 (*measured*) |
| $96EC | `SHOW_END_SCREEN` | the player reached room $8E: the game is won (*measured*) |

**Getting to play** (*measured* in the simulator, by time rather than
breakpoints): from the load, run 3 s; hold 1 (keyboard) 0.3 s; release; hold
4, 5 or 6 (character); release; hold 0; release; after about 4-6 seconds the
player's sprite at $EA90 is $08, $18 or $28 -- in play. With breakpoints:
stop at $7C2F, hold the key, run to $7C2F again (the key has been read),
release, run to $7C2F again; for 0, run to $7D9A instead. Then run to $8E78
for the first frame in play (*read*).

**Keys in play** ([`input.md`](input.md)): Q left, W right, E down, R up
(down the screen is y increasing: E adds to $EA94, R takes from it --
*watched*),
T fire (keyboard); SYMBOL SHIFT pick up / drop -- one action per press, so
release it between; SPACE alone pauses and resumes. Two pixels a frame
walking; hold for N stops at $7EB2 to walk 2N pixels (then the knight coasts
5 more, the serf 16).

## Staging

Each of these was done in the simulator unless marked; start every trial
from the snapshot and a fresh game.

- **Keep creatures away** (*measured*): at each stop, set `SPAWN_COUNTDOWN`
  $5E27 to $20 and zero the sixteen bytes at $EE60, $EE70 and $EE80. The big
  five are in their own rooms and do not need it unless you visit them.
- **A room** (*read*; the build's room pictures do this): at a `MAIN_LOOP`
  stop, write the room to $EA91 (and x, y inside the walk rectangle to $EA93,
  $EA94 -- centre $58, $68) and set PC to $9147 (`ARRIVE_IN_ROOM`); it ends in
  `JP MAIN_LOOP`, which resets SP. This skips `ENTER_ROOM`: no arrival walk,
  no door immunity.
- **The life force** (*measured*): `FOOD_LEVEL` $5E28, 1-240. 1 dies on the
  next drain (a few passes).
- **Lives** (*measured*): `LIVES` $5E21 is the spare lives; 0 means the next
  death is game over.
- **An inventory** (*measured*): write slots at $5E30, $5E34, $5E38 -- two
  bytes of the object's runtime record address, its sprite, its colour. For
  effects (doors, Dracula, Frankenstein, the A.C.G. door) that is enough; to
  keep the world consistent also zero the object's record's first byte, and
  call nothing -- the scroll shows the change at the next room entry
  (`DRAW_INVENTORY` $A13B redraws it).
  Keys: $EAC0 green (colour $44), $EAC8 red ($42), $EAD0 cyan ($45), $EAD8
  yellow ($46), sprite $81. Pieces: $EAA8, $EAB0, $EAB8, sprites $8C, $8D,
  $8E, colour $46. Crucifix $EB08 ($8A, $46); spanner $EB10 ($8B, $45).
- **Picking something up** (*measured*): copy the player's room, x and y into
  the object's record (+1, +3, +4) and hold SYMBOL SHIFT for a few frames.
- **A monster on the player** (*measured*): copy room, x, y into a monster
  record's +1, +3, +4 -- $EE90 mummy, $EEA0 Dracula, $EEB0 the devil, $EEC0
  Frankenstein, $EED0 the humpback; or write a sixteen-byte creature into
  $EE60 (sprite, room, 0, x, y, colour, then zeros).
- **Winning** (*measured*): slots $8C, $8D, $8E in that order (slot one
  $8C), stand in room $00 and put the player at x $9C, y $7B (inside the
  A.C.G. door at $98, $7F); `SHOW_END_SCREEN` follows within the pass after
  next. That works only because the player is dropped straight into the
  door's trigger box (y $50-$7F). Walking in, he must get through the
  doorway's walk box first: the door's +$06/+$07 are $BA, $D6, which make it
  x $84-$AB and y $5C-$73 ([`collision.md`](collision.md)), so y $7B is
  outside it and a walk there stops at the wall. From the start position
  (y $68) holding W walks straight through (*watched*: 28 frames from x $60
  to `ENTER_ROOM`, with the three pieces staged or with the A.C.G. door
  poke). Or simply write $8E to $EA91: the end of the next pass ends the game
  (*read*).

## Variables worth watching

| Address | What |
|---|---|
| $EA90 | player sprite: $01-$30 in play, $66 rising, $67 sinking |
| $EA91, $EA93, $EA94 | room, x, y |
| $EA96, $EA97 | heading (signed; 32 is full speed) -- while dying/rising, the row count and the character |
| $EA92 | flags; low nibble = arrival / hit countdown |
| $EA98 | the weapon's sprite (0 = none) |
| $5E12-$5E13 | `TICKS`, passes |
| $5E28 | life force |
| $5E21 | spare lives |
| $5E2A-$5E2C | score, BCD |
| $5E3D-$5E3F | clock, BCD |
| $5E30-$5E3B | inventory |

## Traps

- **Interrupts are off on the title screen** after loading, after a win and
  after a game over by hunger: FRAMES does not move there, so
  `set_break_on_interrupt` sees nothing until the first `MAIN_LOOP` (*read*;
  *watched*). After a game over caused in the main loop -- a creature, a big
  monster, a mushroom -- they are on, and FRAMES runs through the delay and
  the title (*watched*; [`main-loop.md`](main-loop.md)).
- **FRAMES is rewritten by the game**: it stays under 50 during play, so do
  not use it as a frame counter; use the `FRAME_TICK` stop.
- **Held keys**: the pick-up key acts once per press, and SPACE alone pauses.
  Release everything after loading a snapshot.
- **Death clears creatures** and awards 155 points each -- a staged trial that
  kills the player changes the score (*measured*).
- **One sound slot**: a new sound replaces one playing.
- **GAME_OVER and the end screen run a ten-second counting loop**
  (`END_DELAY` $8C4A); do not mistake it for a hang. Interrupts are off in it
  except after a main-loop death (above).
- `get_screen` at a stop shows the CRT as drawn so far; read $4000 (6912
  bytes) for a clean picture.

## Driven live

*Watched* on a private zx_server (ports 14711/18000, `--no-audio`,
`--uncapped`), 2026-09-27, with the skill's `mcp_client.py`: two MCP sessions,
one to run and one to pause on a timeout, every wait a breakpoint with a time
limit. The scratch scripts are `aa2_ref_drive.py` and `aa2_ref_t*.py`.
Everything here was used for the Bugs, Pokes and Facts pages.

**Setup.** `load_snapshot` of `aticatac.z80`, then release every key (they
stay held across loads) and `load_debug_info` with `aticatac.sld` and
`aticatac.asm`. Run to $7C2F; hold 1, run to $7C2F twice, release, run to
$7C2F twice more; the same with 4 (knight; 6 is the serf). Hold 0, run to
`START_GAME` $7D9A, release. Run to `PLAYER_TICK` $8E78: the first frame in
play, sprite $08, room $00 at x $60, y $68, clock 0:00:05. Then run to
`FRAME_TICK` $7EB2 and `save_snapshot` a `.z80` there: every trial started
from that file. The first game's rooms came out as in the simulator (pieces
$17, $10, $2B; keys $22, $85, $91, $66). Uncapped, 500 `FRAME_TICK` stops
with a few memory reads each take about 7 s of wall time.

**Directions.** E makes y bigger (down the screen), R smaller; room $00's
cyan door at y $1F is at the top and is reached with R.

**Teleporting.** At a `MAIN_LOOP` stop write the room to $EA91 and x, y to
$EA93/$EA94, then `set_registers pc=$9147` (`ARRIVE_IN_ROOM`) and run on; the
room is drawn and play continues there.

**Waiting for a death.** After setting the life force to 1, stop at
`LOSE_LIFE` $8EA0 first: the sprite still reads $08 for several frames, so a
loop that waits for "$08 again" returns at once. From `LOSE_LIFE`, run
`FRAME_TICK` stops until the sprite is $08: about 205 frames for the knight.

**Watchers.**
- `set_watchpoint` on $5E28 (the life force) names each writer: $8A25 for a
  big monster's touch, $8E88 for hunger (both seen), and by the code $98B5
  for a mushroom.
- A logpoint on $8EA0 with `IX={IX} lives={(0x5E21)} food={(0x5E28)}
  player={(0xEA90)}` counts deaths and says what caused each. `get_log`
  returns every earlier line too; pass `since`.

**Staging tricks.**
- Keep creatures away by resetting `SPAWN_COUNTDOWN` $5E27 to $20 and zeroing
  the three creature slots at every stop.
- A monster on the player: copy the player's room, x and y into its record.
  A mushroom (8-byte record, e.g. $EDD8) likewise.
- To open `REGROW_FOOD`'s gate on demand, write $FFFF to `TICKS` $5E12 at a
  `MAIN_LOOP` stop: the end of that pass makes it 0.
- Ending a game: `LIVES` $5E21 = 0 and the life force 1 (a hunger death) or a
  monster on the player (a main-loop death); stop at `GAME_OVER` $8C35, then
  run to $7C2F for the title.
- Winning: the three pieces staged in the inventory, hold W from the start
  position, stop at `SHOW_END_SCREEN` $96EC and then `END_DELAY` $8C4A, when
  everything is printed.

**Traps.**
- Moving a monster by writing its x, y after its room has been drawn leaves
  its old picture on the screen: the next erase is XORed at the new place.
- The big hunters back away from the player whenever he is rising or sinking,
  so a monster staged next to a dying player moves off.
- Dying twice at the rising spot leaves two gravestones that cancel out; a
  screenshot after the second death shows none.
- Identical staged trials sometimes differed by a frame between runs (28 or
  27 frames to the A.C.G. door; FRAMES $10 or $0F at a game over), so do not
  rely on frame-exact repeats between separate loads.
- The user's own server holds 4711/8000; leave it alone.
