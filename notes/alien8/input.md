# Input

**Question this answers:** which keys and joysticks do what, how the pause
works, and whether the game would run on a 128K.

**Short answer:** `READ_CONTROLS` ($C8FF) builds `INPUT` ($5B15) once a turn
from the method chosen on the menu: bit 0 turn left, 1 turn right, 2 walk,
3 jump, 4 pick up or put down, and bit 5 for any letter key, ENTER or SYMBOL
SHIFT -- the pick-up under directional joystick control, when down is a
direction. Nothing but bit 5 while the game is won or the scene after it
runs. SPACE or CAPS SHIFT on its own pauses, with interrupts off. Knight
Lore's keyboard routine writes to port $xxFD before every read, as
Pentagram's does, and every turn one of those writes would page a 128K's
memory -- so on a 128K in 128 mode the game should crash at its first turn
(*inferred*, not tried).

## How it works

By bits 1-2 of `CONTROL` ($5B04):

| Method | Turn left | Turn right | Walk | Jump | Pick up / put down |
|---|---|---|---|---|---|
| keyboard (`READ_KEYBOARD` $C9A5) | Z, C, M, B | X, V, SYMBOL SHIFT, N | any of A-G, H-ENTER | any of Q-T, Y-P | any number key |
| Kempston (`READ_KEMPSTON` $C954, port $1F) | left | right | up | fire | down |
| cursor (`READ_CURSOR` $C979) | 5 | 8 | 7 | 0 | 6 |
| Interface II ($C91B) | 6 or 1 | 7 or 2 | 9 or 4 | 0 or 5 | 8 or 3 |

- Interface II reads keys 1-5 and reverses their order into C, so 5 lines up
  with 0 as fire, then ORs in 6-0: both of the interface's sticks work.
- `READ_LETTER_KEYS` ($C9EE) then sets bit 5 for any key on the two bottom
  half-rows but CAPS SHIFT and SPACE (half-rows $7E, masked) or on the four
  letter half-rows ($99), and the byte goes to `INPUT` and to A and C.
- `CHK_PICKUP_DROP` ($BD58) takes bit 5 in place of bit 4 for a joystick
  with directional control ([`picking-up.md`](picking-up.md)).
- **Directional control** (bit 3 of `CONTROL`, key 5 on the menu): with a
  joystick, the stick's direction is the facing wanted, and the robot turns
  the short way and walks ([`robot.md`](robot.md)). With the keyboard it
  does nothing: steering is rotational.
- **The pause** (`HANDLE_PAUSE` $CE22, once a turn from the main loop):
  half-rows $FE and $7F read together (A = $7E); bit 0 is SPACE or CAPS
  SHIFT, bits 1-4 the other eight keys of the two rows, and the pause needs
  bit 0 and none of the others, so no turning key starts one. A beep
  (`PAUSE_BEEP` $B6B6), a wait for the key to be let go, then for a press
  and a release, and a beep again. The game has no EI anywhere (*searched*),
  so interrupts stay off and nothing runs while it waits.
- **The stray OUT.** `READ_KEYS` ($B759) writes A to port A x 256 + $FD
  before the IN, which does the reading on its own. Nothing on a 48K
  answers it. A 128K's paging port ($7FFD, decoded on A15 and A1 low)
  would, whenever A has bit 7 clear: of the values the game passes, 0, $7F
  and $7E. The first is at the menu: `PLAY_TUNE_TILL_KEY` ($B4A9) reads
  every half-row at once with A = 0, which selects RAM 0 at $C000 -- where
  the game already is -- and the first ROM, without locking; the menu's own
  keys ($F7, $EF) have bit 7 set. Then in the first turn, with the
  keyboard, `READ_KEYBOARD` writes $7F, and with every method
  `READ_LETTER_KEYS` writes $7E ($7E again from `HANDLE_PAUSE` at the end
  of every turn). $7E pages RAM 6 in at $C000, shows the shadow screen and
  locks the paging; $7F the same with RAM 7. Either way the code from $C000
  up -- more than a third of it: the drawing, the collision code, the
  controls themselves -- is paged out, so the game should crash in its first
  turn on a 128K in 128 mode (*inferred* from the port's documented bits;
  not tried).

## How this was found

Read (stage 2, range 4), the half-row masks decoded by hand ($FE CAPS-V,
$7F SPACE-B, $BD A-G with H-ENTER, $DB Q-T with Y-P, $E7 the number rows,
$7E and $99 for bit 5). The keys agree with the build's sessions, which play
every method. The pause read at $CE22 for these notes. The paging values
worked out for these notes from the order of the calls, following
Pentagram's analysis ([`../pentagram/input.md`](../pentagram/input.md)),
whose crash was later watched live.

## Confidence

*Read*; the methods *measured* by the build's sessions (the code map). The
128K crash *inferred*.

## Knight Lore and Pentagram

`READ_KEYS` is Knight Lore's byte for byte, stray OUT included; Knight
Lore's joysticks also had directional control with the pick-up moved to bit
5 ([`../knightlore/input.md`](../knightlore/input.md)). Pentagram kept the
code but offers no menu choice for it and has a fire bit instead; Alien 8
offers it on key 5, as Knight Lore does. Pentagram's pause turns interrupts
on while it waits; Knight Lore's and Alien 8's do not.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `READ_CONTROLS` | `SUBC8FF` | $C8FF | the turn's controls (`READ_KEMPSTON`, `READ_CURSOR`, `READ_KEYBOARD`, `READ_LETTER_KEYS`) |
| `READ_KEYS` | `SUBB759` | $B759 | a keyboard half-row |
| `HANDLE_PAUSE` | `SUBCE22` | $CE22 | the pause |
| `CHK_PICKUP_DROP` | `SUBBD58` | $BD58 | is pick-up pressed |

## Disassembly corrections

- `INPUT`'s bit 5 was missing from stage 1's annotation (range 4).
- `HANDLE_PAUSE`'s description in the listing says half-row $7E is "SPACE,
  SYMBOL SHIFT, M, N, B"; $7E reads that row and CAPS SHIFT to V together,
  so CAPS SHIFT alone pauses too (the main loop's own comment at $A72E and
  stage 1's `driving.md` say so). To tidy in the annotations.

## Open questions

- Does Alien 8 in fact crash on a 128K in 128 mode? An emulator run with
  `--machine 128` would show it (the pokes agent's live session is the
  place).
