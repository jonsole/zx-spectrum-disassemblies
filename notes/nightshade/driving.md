# Driving Nightshade

**Question this answers:** how to run the game where it can be watched --
in SkoolKit's simulator, the way the build does, or in a private
`zx_server` -- and how to stage what play takes too long to reach.

**Short answer:** load the snapshot the build makes
(`game_disassembly/nightshade/nightshade.z80`, PC $5E00, before the game
has run), keep R from it (bit 7 must be set) and leave FRAMES alone, hold
keys through a tracer, and wait on the game's own variables, never on time.
Poke only at the start of a turn (`MAIN_LOOP`, $BE71). A cell is reached by
the game's own restart: put its column and row in `START_U_CELL` ($CC38)
and `START_V_CELL` ($CC3A) and turn the knight's two records into the
vanishing cloud (12). Everything here is in `scripts/build_nightshade.py`'s
`Machine` and `sessions()`; every address is the final listing's. No live
emulator has been used yet.

## The simulator

`Machine` in `build_nightshade.py`: SkoolKit's C simulator over the
snapshot with the 48K ROM below it, interrupts off (the game never enables
them), R taken from the snapshot, and a tracer whose `read_port` reports
held keys and a Kempston stick on port $1F. A session's steps are
`(keys, seconds[, stick])`; a function of memory (a poke); `Until(what,
test, seconds, keys, during=, required=)` (run in 0.05 s slices until
`test(memory)`; `during` runs before each slice, used to keep the lives
topped up; `required=False` gives up quietly, for a try inside a
`Repeat`); `Repeat(what, steps, test, times)`; and `At(what, address)`
(run until PC reaches it; it releases the keys). The C simulator runs ten
seconds of game in about a fifth of a second.

**The protection bites a careless harness** ([`protection.md`](protection.md)):
- **R**: without bit 7 set the first new game jumps to 0 and the Spectrum
  resets (`STOCK_BUILDINGS`, $C1DB). A simulator that starts R at 0 shows
  the ROM's copyright message a second after the menu.
- **FRAMES**: its middle byte must be $63 at `START`; a harness that runs
  interrupts, or pokes FRAMES, gets sent back to BASIC.
- **`TAKE_LIFE`** ($CBDD): a poke there resets at the next death.

**Poke at the start of a turn.** A poke made wherever the simulator
stopped can land inside an update routine that then finishes with what it
read before. Turning the knight into the cloud in the middle of his own
update left graphic 4 (an object lying in the street) in his record: his
routine wrote its walking frame's bit back over it (`SET_KNIGHT_LOOK`,
$DC14), no new life ever came, and the build waited for ever. `_turn(*pokes)`
runs to `MAIN_LOOP` first.

## Starting a game

The menu: 1 keyboard, 2 Kempston, 3 cursor, 4 Interface II, 5 directional
control on or off, 0 start. `MENU_LOOP` ($C8E1) is reached once a pass.
`_start(*keys)` waits for it, presses the keys, presses 0 and waits until
the knight is playing (`_playing`): `ARRIVING` ($BC02) is $70 and his legs'
graphic (`KNIGHT`, $BC8E) is 16-21 or 24-29.

## Keys

`READ_CONTROLS` ($E241) into `CONTROLS` ($BC01) -- bit 0 left, 1 right, 2
walk, 3 throw, 4 down (directional control only), 5 turn the town round:

| Method | Left | Right | Walk | Throw | Down | Town round |
|---|---|---|---|---|---|---|
| Keyboard | X V B M | C N | A-G, H-ENTER | Q-T, Y-P | 1-0 | Z, SYMBOL SHIFT |
| Kempston | left | right | up | fire | down | Z, SYMBOL SHIFT |
| Cursor | 5 | 8 | 7 | 0 | 6 | Z, SYMBOL SHIFT |
| Interface II | 6, 1 | 7, 2 | 9, 4 | 0, 5 | 8, 3 | Z, SYMBOL SHIFT |

SPACE or CAPS SHIFT alone pauses; press again to go on (`PAUSE`, $E32C).
Turning the town round acts on release (`KEY_LATCH`, $BBBD): hold it for a
turn and let go. A turn key held turns the knight a quarter every other
turn ([`input.md`](input.md), [`knight.md`](knight.md)).

## Staging

- **Lives and hits:** `LIVES` ($BBCD), `HITS` ($BBF3, 3 a life). A villain
  that touches the knight kills him at once whatever his hits
  (`VILLAIN_WANDER`, $D94F), and the next life starts in the same cell
  (`KNIGHT_KILLED`, $CEC4, writes it into the start records) -- so a session
  waiting for him in a cell where a villain stands keeps topping the lives
  up (`during=_lives`).
- **Go to a cell:** `_go(u, v)`: at the start of a turn, `START_U_CELL` =
  column, `START_V_CELL` = row, `KNIGHT` and `KNIGHT_TOP` = 12 (`_kill`).
  The cloud runs four turns, the record empties, and `NEW_LIFE` ($CBAC)
  copies the start records in. He appears at the middle of the cell. The
  game's own random start (`RANDOM_START_CELL`, $CB7B) takes any cell but
  types 1 and 2; the tour visits all 625.
- **Game over:** `_game_over`: `LIVES` 0, then the cloud: `NEW_LIFE` finds no
  life to take and goes to `GAME_OVER` ($CC56), which returns to the menu
  unless the four villains are gone.
- **A thing beside him:** `_beside_knight(record, graphic)` copies his U and
  V into a record and gives it half-size 16 and drawing offset ($F4, $04).
  Used for the bonuses (`BONUS`, $BD0E: graphic 2 a faster walk for 255
  turns, 3 his hits back), the finds (`FINDS`, $BCCE: graphics 48-63, taken
  up as antibodies 5-8), and the objects (`OBJECTS`, $BD1E + 16*n*).
- **Antibodies at a monster:** thing 5-8 in `CARRIED` ($BC03), throw held
  until an antibody is in flight (`ANTIBODIES`, $BCAE, graphics 80-95),
  then a monster record in `MONSTERS` ($BD9E) put four of the antibody's
  steps ahead of it -- it moves twice a turn by twice its step -- so the
  monster's own update finds them touching. Only the first antibody record
  can strike ([`touching.md`](touching.md)). One that meets a wall in the
  turn it is thrown is never seen in flight: turn and try again. A strike
  always scores, which is how a session knows it happened.
- **A villain:** its object laid by the knight and taken up, thrown once at
  nothing (it flies until a wall and lies down again), taken up and thrown
  again, and the villain (`VILLAINS`, $BD5E + 16*n*) put four steps ahead of
  it. The object's record is updated before the villain's, so the strike is
  found before the villain can reach the knight. The villain becomes
  graphic 132, flashes the play area for eight turns, and empties.
- **The ending:** with the four villain records empty and their sparkles
  (140-143 in `FINDS`) done, `CHECK_QUEST_DONE` ($D865) goes to
  `GAME_OVER`, which finds no villain left, fills ten records from
  `ENDING_RECORDS` ($CCE4), sets `ENDING` ($BBFF) and returns to the main
  loop. When the pit's front sees the last villain gone
  (`ENDING_PIT_FRONT`, $CD10) it plays a tune and goes back to the menu.
  About 13 seconds.
- **A hundred per cent:** `_visited_everywhere`: set the `VISITED` ($BC0E)
  bit of every cell but types 1 and 2 (byte `VISITED` + 4*row + column/8,
  bit column AND 7), then destroy the four villains. `PERCENT`
  ($BBFD) then holds 1 and 0; to see the garbage print, run to the
  instruction after `GAME_OVER`'s call to `PRINT_PERCENTAGE` ($BF36).
- **The creature:** wait for `TURNS`' low byte ($BBB2) to come round to 0,
  or poke it to $FF at the start of a turn (`NEXT_TURN` counts it to 0
  before the spawns; *read*, not tried); `SPAWN_CREATURE` ($BF95) then puts
  graphic 136 in a monster record.
- **The 156-game crash:** `_start("1")` then `_game_over`, repeatedly; SP
  at `MENU_LOOP` falls two bytes a game ([`protection.md`](protection.md)).

## Sessions and what they add

The build's sessions, with the addresses each added in the run after the
stage 2 merge (in order, each counting only what the ones before missed):
keyboard 3945; Kempston 27; cursor 25; Interface II 31; directional control
(both views) 99; every cell 75 (94 s, the longest); game over 96; the
bonuses 30; finds and antibodies 78; the villains and the ending 300. 4705
instruction starts in all; following branches added 78 more and 23 in the
loader. A tour of every third cell with the town turned round added nothing
and was dropped.

## Live driving

Not done yet; stage 3 is to check the 100% print and the 156-game crash
live. The recipe (*assumed*, from the other games' live work and the
`zx-live-verify` skill): a private `cpp-core/build/RelWithDebInfo/zx_server.exe`
on ports 14711/18000/18500 with `--no-audio`, killed by PID afterwards --
never the default ports. Load `nightshade.z80` with `nightshade.sld` for
the labels; the snapshot keeps R, FRAMES and the interrupts off, so the
protection is satisfied as long as nothing resets the machine. Breakpoints
worth having: `MENU_LOOP` ($C8E1, the menu, waiting for a key), `MAIN_LOOP`
($BE71, the start of a turn -- the place to poke), `NEW_LIFE`'s
`FIRST_LIFE` ($CBC5), `GAME_OVER` ($CC56). Run uncapped to wait, at
normal speed to type.
