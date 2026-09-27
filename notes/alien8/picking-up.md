# Picking up and putting down

**Question this answers:** what the pick-up key does, what can be carried,
and how the panel shows it.

**Short answer:** `TAKE_OR_LEAVE` ($BD6B), every turn from the legs'
routine: one press picks up a valve he is on or beside; failing that, puts
down the oldest thing he carries under himself, lifting him 12 onto it; and
if the oldest slot is empty, moves what he carries one slot along. Only the
two records at `VALVES` are searched, for a valve to take and for a record
to put one in, so only valves can be carried and a room holds at most two
things from the places. Three are carried, first in first out; the panel
shows them in three boxes coloured by kind.

## How it works

- **One press, one action**: `TAKE_HELD` ($5B13) latches the key;
  `WAIT_TAKE_RELEASE` ($BDFD) clears it when the key is up. The key is
  `CHK_PICKUP_DROP` ($BD58): bit 4 of `INPUT`, or bit 5 with a joystick and
  directional control, when down is a direction ([`input.md`](input.md)).
- **Only** inside the room's walls (`CHK_PLYR_OOB` $C117), not jumping
  (bit 3 of +$0C), and standing on something (bit 2 of +$0C).
- **Headroom**: his Z raised by 12, the legs as tall as the whole robot (23,
  set by `PLAYER_LEGS`), and `DO_ANY_OBJS_INTERSECT` ($B712) asked whether
  anything overlaps; if so, `NO_HEADROOM` ($5B33). The top is kept out of
  that test by its height of 0.
- A press that gets this far beeps (`PLAIN_BEEP` $B6B1) and sets `PANEL_DUE`
  ($5B14), whether or not anything changes hands.
- **Looking**: his half-sizes widened by 4 (put back at `TAKE_DONE` $BDF1);
  the two `VALVES` records tried with `CAN_PICK_UP` ($BEA7): graphics 96-99
  only, overlapping in U and V, and in Z with him 4 lower
  (`IS_ON_OR_NEAR_OBJ` $BEAF).
- **Picking up** (`PICK_UP_VALVE` $BE76): `DROP_LATCH` cleared; the graphic,
  the flags and the place's address into `CARRIED_NEW` ($5B78); the place's
  graphic zeroed; the record marked and made graphic 1 (rubbed out, then
  emptied). If `CARRIED_LAST` holds something it goes down in the same
  record -- a swap ($BEA1, never run); then `SHIFT_CARRIED`.
- **Putting down** (`PUT_DOWN_LAST` $BE06, when there is nothing to take and
  one of the two records is empty): the graphic from `CARRIED_LAST`
  ($5B84) at his U, V and Z; both his records raised 12; its screen position
  (`CALC_PIXEL_XY_IY` $AE8A); `FILL_PUT_DOWN` ($BE3B): half-sizes 5, 5,
  height 12, the slot's flags, his room, the place's address, and bit 0 of
  +$0D set. The place itself is not written: `UPDATE_SPECIAL_OBJS` copies
  where the valve lies back into it when he leaves the room. The valve's
  own routine sees bit 0 of +$0D, clears it and redraws it.
- **Nothing to put down**: `SHIFT_CARRIED` ($BE60) alone -- twelve bytes from
  `CARRIED_NEW` up by four, `CARRIED_NEW` cleared. One valve picked up takes
  three presses to reach `CARRIED_LAST` and a fourth to go down.

| Address | Label | Slot |
|---|---|---|
| $5B78 | `CARRIED_NEW` | a thing just picked up, empty between presses |
| $5B7C, $5B80 | `CARRIED` | the newest two; the panel's first two boxes |
| $5B84 | `CARRIED_LAST` | the oldest, put down next; the third box |

Each slot is the graphic, the flags from +$07 and the address of the valve's
place in `PLACES`.

- **The panel** (`SHOW_CARRIED` $BC9D, from `RENDER_DYNAMIC_OBJECTS` each
  turn when `PANEL_DUE` is set and the game is not won; `SHOW_CARRIED_NOW`
  $BCAB from `COLOUR_PANEL`): three boxes 24 pixels square at x 8, 32 and
  56, y 0 -- `CARRIED`, the next slot, `CARRIED_LAST` (`SHOW_CARRIED_BOX`
  $BCB6). Each box cleared with `FILL_BOX`, the sprite drawn through
  `PANEL_RECORD` ($BD38) with the mirror bit clear, copied to the screen,
  and its 3 by 3 cells coloured from `CARRIED_COLOURS` ($BD34) by the
  graphic's low bits: bright red, magenta, cyan, white for valves 96-99.

## How this was found

Read against Pentagram's `TAKE_OR_LEAVE` (0.91), `CAN_PICK_UP` (0.86) and
`SHOW_CARRIED` (0.95) and Knight Lore's `handle_pickup_drop`,
`is_on_or_near_obj` (0.84) and `chk_pickup_drop` (0.94) (stage 2, range 3).
The readers of bit 0 of +$0D were found through every `(IX+$0D)` in the
listing. The headroom trick with the top's height read from
`DO_OBJS_INTERSECT_ON_Z`'s arithmetic. *Measured* by stage 1's "valves
carried" session: the pick-up, the walk along the slots, the put-down.

## Confidence

*Read*, and *measured* for the common path. The swap ($BEA1-$BEA6) never
ran.

## Knight Lore and Pentagram

Pentagram searches its 48 room records for a thing to take and a record to
put one in ([`../pentagram/carrying.md`](../pentagram/carrying.md)); Alien 8
searches only the two records from the places -- Knight Lore's special
objects, in the same slots ([`../knightlore/inventory.md`](../knightlore/inventory.md))
-- which is why only valves can be carried. Pentagram lets a thing put down
fall a turn and marks it itself; Alien 8 leaves the redraw to the valve's own
routine, through bit 0 of +$0D, which Pentagram sets and never reads. The
pick-up sound is a beep here, not an effect.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `SHOW_CARRIED` (`SHOW_CARRIED_NOW`, `SHOW_CARRIED_BOX`) | `SUBBC9D` | $BC9D | the panel's carried things |
| `CARRIED_COLOURS` | `TEXTBD34` | $BD34 | their colours by kind |
| `PANEL_RECORD` | `SPACEBD38` | $BD38 | the spare record for the panel and the border |
| `CHK_PICKUP_DROP` | `SUBBD58` | $BD58 | is pick-up pressed |
| `TAKE_OR_LEAVE` | `SUBBD6B` | $BD6B | pick up or put down (`TAKE_DONE`, `WAIT_TAKE_RELEASE`, `PUT_DOWN_LAST`, `FILL_PUT_DOWN`, `SHIFT_CARRIED`, `PICK_UP_VALVE`) |
| `CAN_PICK_UP` (`IS_ON_OR_NEAR_OBJ`) | `SUBBEA7` | $BEA7 | a valve he touches |
| `IS_OBJ_MOVING` | `SUBBED6` | $BED6 | any step in U, V or Z |

## Disassembly corrections

- `PANEL_DUE` is set on every accepted press, not only when the carried
  things change (range 3).
- `CARRIED_NEW`'s link pointed at $BE76, not an entry start; it now points
  at `TAKE_OR_LEAVE` (range 1).

## Open questions

- None of behaviour. The swap wants a staged session: a valve in
  `CARRIED_LAST` and another beside him.
