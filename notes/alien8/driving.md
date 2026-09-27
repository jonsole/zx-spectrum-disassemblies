# Driving Alien 8

**Question this answers:** how to run the game where it can be watched --
in SkoolKit's simulator, the way the build does, and live in the
emulator -- and how to stage the states play takes too long to reach.

**Short answer:** load the snapshot the build makes (PC $6300, before the
game has run), hold keys through a tracer, and wait on the game's own
variables, never on time. A new room is reached by the game's own restart:
put the room (and a spot) in the start records at $CA1D and start the
robot's death. To watch a thing turn by turn, run to the end of the turn,
`MAIN_END_OF_TURN` ($A6DC), and read its record. Everything below is in
`scripts/build_alien8.py`'s `sessions()` or in the stage 2 agents' scratch
scripts built on its `Machine`, and every address is *read* from the code
and *measured* by those runs.

## The simulator

`Machine` in `build_alien8.py`: SkoolKit's C simulator over the snapshot
with the 48K ROM below it, interrupts off (`iff` 0 -- the game's first
instruction is DI and it has no EI anywhere), and a tracer whose
`read_port` reports held keys (half-rows as `skoolkit.kbtracer.KEY_BITS`)
and a Kempston stick on port $1F.
`Machine.run(seconds, keys, stick)` runs that long; steps in a session are
`(keys, seconds[, stick])`, a function of memory (a poke), `Until(what,
test, seconds, keys)` (run in 0.05 s slices until `test(memory)`, or stop
the build naming `what`), `Repeat(what, steps, test, times)`, and `At(what,
address)` (run until PC reaches it, for a poke that must land at a known
point of the turn; it releases the keys). The C simulator runs about 50
times faster than a Spectrum.

Helpers worth reusing from a scratch script (import `build_alien8` with
`scripts/` on the path): `_start(*keys)`, `_go(room, spot)`, `_onto(graphic,
which)` (drop the robot on top of the room's `which`th object of a graphic,
as a jump would land him), `_under(graphic)` (stand him on the floor under
one), `_put(place, graphic, room, u, v, z)`, `_kill`, `_lives`,
`_records_of(memory, graphics)`.

## Starting a game

`MENU` ($BA7E) reads keys 1-5 and 0: 1 keyboard, 2 Kempston, 3 cursor, 4
Interface II set bits 1-2 of `CONTROL` ($5B04); 5 toggles bit 3,
directional control, once per press (`KEY5_HELD`, $5B32); 0 starts. After 0
a tune plays and the robot materialises (graphics 56-62) for about 2.5 s of
game time. `_start(*keys)` presses each key, then 0, and waits until the
legs' graphic is one of 16-23 (walking about): that is `_playing`.

The start room comes from `START_ROOMS` ($CA9E: $13, $4E, $88, $D7) by bits
0-1 of `SEED` ($5B00, the ROM's frame counter when the game is first run).
In the simulator the start is always the same: room $4E.

## Keys and sticks

`READ_CONTROLS` ($C8FF) reads, by control method ([`input.md`](input.md)):

| Method | Turn left | Turn right | Walk | Jump | Pick up / put down |
|---|---|---|---|---|---|
| keyboard (`READ_KEYBOARD` $C9A5) | Z, C, M, B | X, V, SYMBOL SHIFT, N | A-G and H-ENTER rows | Q-T and Y-P rows | 1-5 and 6-0 rows |
| Kempston (`READ_KEMPSTON` $C954) | left | right | up | fire | down |
| cursor (`READ_CURSOR` $C979) | 5 | 8 | 7 | 0 | 6 |
| Interface II | 6 (or 1) | 7 (or 2) | 9 (or 4) | 0 (or 5) | 8 (or 3) |

SPACE or CAPS SHIFT on its own pauses, and again goes on (`HANDLE_PAUSE`
$CE22). `INPUT` ($5B15) holds the turn's controls: bits 0-1 turn, 2 walk, 3
jump, 4 pick up, 5 a letter key.

## Where things are

| What | Address | Label |
|---|---|---|
| the end of a turn (break here to step a turn at a time) | $A6DC | `MAIN_END_OF_TURN` |
| the robot's legs (record 0) | $5B88 | `OBJECTS` |
| his U, flags, room | $5B89, $5B8F, $5B90 | `PLAYER_U`, `PLAYER_FLAGS`, `PLAYER_ROOM` |
| his top (record 1) | $5BA8 | `PLAYER_TOP` |
| what lies in the room from the places (records 2, 3) | $5BC8, $5BE8 | `VALVES`, `VALVE_SECOND` |
| the room's records (4-55) | $5C08 | `ROOM_OBJECTS` |
| lives | $5B1A | `LIVES` |
| the start records (legs, top); +1 +2 U and V, +8 the room | $CA1D, $CA3D | `START_LEGS`, `START_TOP` |
| the places (36 x 9 bytes; +0 graphic, +5-+8 U, V, Z, room) | $76E3 | `PLACES` |
| carried things, the next to put down last | $5B7C, $5B84 | `CARRIED`, `CARRIED_LAST` |
| chambers activated (BCD) | $5B40 | `CHAMBERS` |
| won | $5B23 | `WON` |
| the scene after a game is running | $5B24 | `GAME_OVER` |
| the clock (4 bytes) | $5B36 | `CLOCK` |
| the clock's turn | $AD66 | `RUN_CLOCK` |
| the remote-control orders | $5B42 | `REMOTE_ORDERS` |
| the drop latch; a drop falling | $5B3B, $5B3A | `DROP_LATCH`, `DROPPING` |
| a leaper in the air | $5B43 | `LEAPING` |
| the lifts' top | $5B25 | `LIFT_TOP` |
| the random number | $5B05 | `RANDOM` |
| the turn counter | $5B02 | `TURNS` |
| the draw list; the sort's chain | $C745, $C8EF | `DRAW_LIST`, `CANDIDATE_CHAIN` |

## Staging

- **Into a room** (`_go(room, spot)`): top the lives up, write the room into
  +8 of both start records (and the spot into +1 and +2), and start his death
  the way `START_SPARKLE` ($B39A) does -- both his records to graphic 48,
  bit 1 of +7 set. The sparkle runs, the records empty, and the main loop's
  check at $A731 starts a new life (`NEW_LIFE` $CA07) from the start
  records. Setting the killed bit of +$0D (Pentagram's way) does not work
  here: it is cleared before the legs' update routine sees it (what clears
  it is open, [`robot.md`](robot.md)). Without a spot he appears where he
  last came through a doorway, which in another room may be inside something
  deadly; the room tour does not mind, a staged scene uses (96, 160).
- **One turn at a time** (stage 2's scripts): hold the keys by setting
  `machine.tracer.keys` and trace to $A6DC by hand (`At` releases the keys),
  then step a few instructions past it before the next; or run in 0.01 s
  slices until `TURNS` changes. Read the records after each.
- **Game over**: `LIVES` 0 and his death started; after the summary (about
  25 s of game time: a tune and a wait for a key) `GAME_OVER` goes to 1 and
  the re-programming scene runs in the main loop; back at the menu it is 0
  again and both his records are empty (`_at_menu`). The summary of a game
  lost at once reads 00, 24, 132.
- **The winning scene**: set `WON` before the last death, or activate the
  twenty-fourth chamber (below).
- **A valve to carry** (`_put`, `_beside_valve`): write a place's graphic
  (96-99, the four kinds) and +5 to +8 (U, V, Z, room) before entering the
  room; it appears in `VALVES`. Stand him 14 short of it in V; each press
  of pick-up moves the carried things along (`SHIFT_CARRIED` $BE60) until
  the valve is in `CARRIED_LAST`; the next press puts it down.
- **A chamber** (`_chamber`): a valve of the socket's kind in the chamber's
  room, high up at (128, 128, 200); once the room is built, hold it over the
  socket (graphics 112-115, a record of its own) 30 above it. It falls on
  the socket and the chamber is activated. Chambers of each kind: $0C (kind
  0), $62 (1), $1D (2), $0A (3); 24 in all, one per room -- the rooms whose
  object templates 24-27 are in their records.
- **The ending**: `CHAMBERS` to $23 (BCD), then a twenty-fourth chamber. Wait
  on `CHAMBERS` and `WON`, not on the player: the game ends before he has
  finished appearing.
- **The socket's sparkle coming back** (range 1): a valve of the wrong kind
  put in room $0C, the room built, then record 2 emptied by hand: `SOCKET`
  reaches $AE7E and the sparkle record comes back as graphic 108.
- **An extra life**: a place with graphic 12 in the room, against where he
  appears; the place's graphic goes to 0 when taken.
- **The clock running out**: at `RUN_CLOCK` ($AD66, `At`), poke `CLOCK` to 0,
  0, 0, 1 -- the last digit 0 still rolling one row, not a light year left
  (each byte's low three bits are a roll count; one light year is $10). The
  turn's count runs it out and ends the game. Poked
  anywhere else in the turn, the borrow half-done can wrap the count round
  to 9s. The rate: count turns across a run and read `CLOCK` (7 turns a
  light year).
- **The remote-controlled robots**: room $0B has two of them (graphics
  124-127), two buttons of each kind (122, 123) and a pad (128). `_onto` each
  in turn (U and V the button's, Z its top plus 8, the top 12 higher), a few
  seconds each, and read `REMOTE_ORDERS` and each robot's +$10.
- **Things dropping from the ceiling** (graphic 73, rooms $0C, $1C, $58,
  $84): all four rooms are even-numbered, where `DROP_LATCH` is set on
  entry, so nothing drops until a pick-up clears it. Stand him under one
  (`_under(73)`), clear the latch, and at $AD2A (`At`) put 0 in `RANDOM` so
  this turn's test passes.
- **Movers and creatures** (range 2's scripts `a8p2_sim.py`, `a8p2_lift.py`,
  `a8p2_coll.py`, `a8p2_drop.py` in the stage's scratchpad): `_go` to the
  room, `_onto` the thing, and read its record every turn. Rooms that show
  each: a conveyor $0D (graphic 68), a collapsing block $12, a dropping block
  $82, lifts $23, bobbing blocks $36, a wanderer $2F, a pacer $A6, the spark
  chaser $9C, leapers $97, the mice breaking fragile things $72
  ([`carrying-and-lifts.md`](carrying-and-lifts.md),
  [`creatures.md`](creatures.md)).
- **The turn** (range 3's `a8p3_turn.py`): from the start room, hold Z (or
  X, or X and A) and read the legs' graphic, mirror bit and +$0D at each
  $A6DC ([`robot.md`](robot.md)).
- **The draw list's and chain's high-water marks** (range 4): at the first
  turn's `LIST_DRAWN` ($C71C) fill `DRAW_LIST` and `CANDIDATE_CHAIN` with
  $FE, run the room tour, and after each room find the furthest $FF in the
  list and the furthest byte not $FE in the chain (51 and 8).
- **A valve destroyed** (range 4): put a place's valve inside the robot's box
  in the start room; the depth sort turns it into the sparkle and its place
  empties.
- **The panel on its own** (range 5's `a8p5_panel.py`): run
  `BUILD_LOOKUP_TBLS` ($CFA7), `CLEAR_SCRN_BUFFER` ($CE7B) and
  `DISPLAY_PANEL` ($CB0F) on the snapshot and draw the buffer's bottom 64
  rows; make one `PANEL_DATA` entry's graphic 0 to see where it lands.

## Live driving

*Watched* (2026-09-27, the pokes agent: a private `zx_server` on ports
14711/18000/18500, `--no-audio --uncapped --rom roms/48.rom`, loaded with
`alien8.z80`, which starts at PC $6300; killed by PID afterwards).

**Breakpoints.** `MAIN_END_OF_TURN` $A6DC hits once a turn: hold keys between
hits, one hit being one turn of controls. At the menu, $BA9E is after the
tune and before the key reads -- step once, then run to it again for the next
pass; $A679 means 0 was pressed. A new life: $A688. The game ended: $B761.
The summary done: $B7BF. Back at the menu: $A647.

**Playing or not.** The legs' graphic is 16-27 while he plays. He is safe
while appearing (graphics 56-63): $BC90 clears the killed bit.

**Staging a room.** Write the room and U, V into +8 and +1/+2 of both start
records ($CA1D, $CA3D), give both his records graphic 48 with bit 1 of +7
set, then run to $A688 and on until he is playing. It costs a life, so top
`LIVES` up first. Choose the spot so he does not appear on something: in
chamber $0C a valve at (104,160) was destroyed because he appeared at
(96,160) -- the depth sort's valve rule.

**The clock.** The low three bits of each `CLOCK` byte are a roll count, not
part of the digit. Poking (0,0,0,1) -- as the build's clock session does --
is digit 0 still rolling one row, not "one light year left"; for one light
year left poke (0,0,0,$10) at `RUN_CLOCK` $AD66, and the game ends 6 turns
later.

**Chambers.** A valve put in a place record at (128,128,200) in the
chamber's room, before entering, steers itself onto the socket while he is
still appearing. A wrong kind lands on whatever is below it.

**Drops.** Use room $58, not $1C: $58 has 16 drops at Z 112 over blocks
topped at 76 -- stand him on a block at Z 76 and clear `DROP_LATCH`. In $1C
the only drop hangs over two pushable blocks at the same U, V, so the build's
`_under(73)` puts the robot inside them.

**Timing.** About 1.7 frames a turn in quiet rooms (50 turns took 85 frames
in an empty room, 95 in start room $13); the menu passes about 30 times a
second, `SEED` rising by one each pass (the start room went $13, $4E, $88,
$D7 as it rose).

**Logpoints.** `{IX}` works; `{IX:w}` logs nothing (`:w` is for memory words).

**128K.** A 128K snapshot made from `alien8.z80` (SkoolKit's
`write_snapshot`, paged as the 128's Tape Loader leaves it), after
`load_rom` of the 128 ROM: the menu tune's key test pages ROM 0 in, and at
the end of the first turn the pause test's `READ_KEYS` with $7E pages bank 6
in, locks the paging and crashes. Restart the server afterwards -- a locked
paging survives a snapshot load (an emulator bug) -- and reload 48.rom.
