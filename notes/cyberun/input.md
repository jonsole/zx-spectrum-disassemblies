# Input

**Question this answers:** which keys do what, how each control method is
read, and what the game does with the result.

**Short answer:** every method produces one byte in the Kempston layout --
bit 0 right, 1 left, 2 down, 3 up (thrust), 4 fire -- plus bit 5, the
special key, which fires the special beam once add-on 7 is fitted. On the
keyboard the middle letter row thrusts, the top letter row fires, the
number row is the special key, and the bottom row steers with alternate
keys: X, V, N, SYMBOL SHIFT right; Z, C, B, M left. With a joystick
(Kempston, cursor keys or Interface II) the special key is any letter key
but CAPS SHIFT and SPACE. SPACE or CAPS SHIFT pauses. The byte is read
once a pass into `controls_now` ($5C37).

## How it works

```
move_ship $B234 (once a pass, from ship_pass)
  read_controls $B115
    read_control_method $B16F      C = the controls, by control_method
    the ceiling: no thrust while view_row is 5 (0 with add-on 5) and
                 view_y is below $60
    special_beam_on: only fire and the special key (AND $30)
    launch_state set: nothing read at all; move_ship flies the ship
    controls_now $5C37 = C
    steering or thrust: burn fuel (add_fuel)
```

### The methods

`control_method` ($F603, +28 of the current player's record), chosen on
the menu ([`panel-and-menu.md`](panel-and-menu.md)), each player having
their own:

| Method | Code | How the five bits are made |
|---|---|---|
| 0 keyboard | `read_control_method_3` | below |
| 1 Kempston | `read_control_method_0` | `IN A,($1F)` AND $1F: the port is already in this layout |
| 2 cursor keys | `read_control_method_2` | half-row $EF: 7 up, 8 right, 6 down, 0 fire; half-row $F7: 5 left; shifted into place and inverted. Bits 6 and 7 come out set, which nothing tests (only `random` adds the whole byte in) |
| 3 Interface II | `read_control_method_1` | half-row $EF: 6 left, 7 right, 8 down, 9 up, 0 fire, rotated into place a bit at a time and inverted |

**The keyboard** (method 0):

| Keys | Half-rows | Bit |
|---|---|---|
| X, V / N, SYMBOL SHIFT | $FE mask $14, $7F mask $0A | 0 right |
| Z, C / B, M | $FE mask $0A, $7F mask $14 | 1 left (only if no right key is down) |
| A-G, H-ENTER | $BD: $FD and $BF together | 3 thrust |
| Q-T, Y-P | $DB: $FB and $DF | 4 fire |
| 1-5, 6-0 | $E7: $F7 and $EF | 5 the special key |

Down is never set from the keyboard: the ship falls under gravity
instead. A read of several half-rows at once (`read_keyboard`, $9BC3: A
selects the rows by its zero bits, the result is the five keys inverted)
is how one call covers a whole row of the keyboard.

**The special key with a joystick** (`read_control_method_9`, after any
of the three joystick methods): half-rows $FE and $7F with bit 0 masked
off (so not CAPS SHIFT or SPACE, which pause), and $99 -- the half-rows
$FD, $FB, $DF and $BF whole. That is every letter, ENTER and SYMBOL
SHIFT.

### What reads the byte

| Bits | Read by | For |
|---|---|---|
| 0, 1 | `move_ship` | the push across ($40 a pass a pass), `steer_push` for the ship's facing |
| 3 | `move_ship`; `lift_jet` | thrust ($50 against gravity's $40); the lift jet's frame |
| 0, 1, 3 | `read_controls` | the fuel burn: 8 a pass, 16 thrusting and steering together |
| 4 | `fire` $B731 | a shot, every 6 passes at most (`gun_cooling`) |
| 5 | `special_beam_key` $B833 | the special beam: with add-on 7 fitted and the ship still (both speeds inside `dead_band`), `fire` is entered at its second entry with `shot_alternator` bit 2 set; while the beam is out the ship hangs still and letting the key go starts it shrinking (`end_special_beam`) |
| all | `random` $F23B | stirred into the random bytes every pass |

### Other keys

| Where | Keys | Routine |
|---|---|---|
| the title tune | any key stops it | `play_tune_until_key` $9A9A |
| the menu | A one player, B two, 1 and 2 step each player's method, 0 starts | `menu_keys` $86B9, `menu_loop` $8615 |
| in play and in the death sequence | SPACE or CAPS SHIFT: pause; again to go on | `test_pause_keys` $9EE3, `pause` $9F5B ([`main-loop.md`](main-loop.md)) |
| game over | 0 cuts the wait short | `game_over` $F4FC |

### OUT ($FD) before every read

Every keyboard read in the game is `OUT ($FD),A` then `IN A,($FE)` with the
same A: the OUT goes to port A x 256 + $FD. On a 48K nothing answers it. Why it
is there is not known. On a 128K the port is decoded as the paging port $7FFD
whenever A's bit 7 is clear, and five reads can be given such an A: the title
tune's key test (A nought, which pages the 128's editor ROM in, harmlessly),
the menu's test for B and the pause test ($7F, every menu pass and every pass
of play), the keyboard method's reads of the bottom right half-row, and a
joystick's special key ($7E). $7F pages RAM bank 7 in at $C000 and locks the
paging. Watched in SkoolKit's 128K memory, the game put in RAM as a 128 in 128
mode leaves a machine-code program, for the reference pages: the writes were
$00 to $00FD and then $7F to $7FFD, and on the menu's first pass the call to
`random` ($F23B) ran into bank 7 and the machine into the ROM. So the game must
be run in 48 mode; the poke in [pokes.md](pokes.md) takes the five OUTs out.

## How this was found

Stage 0 (2026-10-16) found the keyboard routine live by searching memory
for `IN A,($FE)`, read the mapping from it, and played it: the top row
fired, the middle row lifted the ship, X flew right. The stage 2
description of the listing (2026-10-16) read every method,
`read_controls`, `special_beam_key` and the menu's keys from the code.

## Confidence

The keyboard mapping is *read* and *played*. The cursor and Interface II
mappings and the special key are *read*; the build's sessions picked every
control method, so all four readers ran, and since the staged every-add-on
session the special beam (`special_beam_key`'s launch, `end_special_beam`) and
the ceiling's masking of thrust run too (`cyberun-executed.map`).

## Corrections

- Stage 0 left bit 5 (the number row) unexplained. It is the special key,
  which fires the special beam when add-on 7 is fitted and the ship is
  still; with a joystick it is any letter key.
- Stage 0 labelled methods 2 and 3 "probably cursor keys" and "probably
  Interface II" from the rows they read. The code confirms both and gives
  their key maps (above), and the menu names the four methods in this
  order.
- Stage 0 asked where the method is chosen and stored: on the menu, in
  the pointer records `player1_pointer` and `player2_pointer` ($8708,
  $870B, the third byte), copied by `new_game` into each player record's
  +28.
- Stage 0's `driving.md` warned that holding SPACE "stopped the game
  indefinitely" in a death sequence: SPACE is the pause key.
- **Coverage** (2026-10-17): this file said the special beam's launch and end
  and the ceiling's masking of thrust never ran in the build's sessions; the
  every-add-on session runs them.
- **The 128K question.** This file reasoned that the `OUT ($FD),A` ought to
  crash the game in 128 mode and left it untested; the reference pages' run in
  SkoolKit's 128K memory shows that it does, on the menu's first pass.

## Open questions

- Whether the joystick methods' special-key rows were meant to include
  ENTER and SYMBOL SHIFT, or just fell out of using whole half-rows.
- Why every read writes A to port $FD first at all: on a 48K nothing answers,
  and on a 128K it is the crash above.
