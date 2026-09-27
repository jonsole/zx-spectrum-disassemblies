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

**Nothing here has been tried in the emulator.** Every address is *read*
from the listing, and the recipes marked *measured* were run in SkoolKit's
simulator (the scratch harness `aticatac_sim.py`, 2026-09-27) with the same
breakpoint-and-hold method. Try them live before building on them, and
record what happens here.

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

**Keys in play** ([`input.md`](input.md)): Q left, W right, E down, R up,
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
  next. Or simply write $8E to $EA91: the end of the next pass ends the game
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

- **Interrupts are off on the title screen**: FRAMES does not move there, so
  `set_break_on_interrupt` sees nothing until the first `MAIN_LOOP` (*read*).
- **FRAMES is rewritten by the game**: it stays under 50 during play, so do
  not use it as a frame counter; use the `FRAME_TICK` stop.
- **Held keys**: the pick-up key acts once per press, and SPACE alone pauses.
  Release everything after loading a snapshot.
- **Death clears creatures** and awards 155 points each -- a staged trial that
  kills the player changes the score (*measured*).
- **One sound slot**: a new sound replaces one playing.
- **GAME_OVER and the end screen run with interrupts off for ten seconds** in a
  counting loop; do not mistake it for a hang.
- `get_screen` at a stop shows the CRT as drawn so far; read $4000 (6912
  bytes) for a clean picture.
