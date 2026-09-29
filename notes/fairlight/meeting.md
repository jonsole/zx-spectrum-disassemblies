# When objects meet

**Question this answers:** what happens when something moving runs into
something that is not a door -- who loses LIFE, what vanishes, what is
killed, what is taken.

**Short answer:** `OBJECTS_MEET` ($F959) reads the kind bytes (+12) of the
mover and of what it ran into and settles, in a fixed order: things that
hurt at a touch (bit 4: 10 LIFE, and the thing vanishes), fighters (bit 7:
1 LIFE -- or, when the knight's sword is out, a strike off a creature that
can be killed; four strikes kill), the ghost stealing things, a wraith
destroyed by two kinds of thing, and the pit floors (kind 7), which kill.
Anything else is an ordinary obstacle for `BLOCKED_MOVE`
([`collision.md`](collision.md)).

## How it works

The object being updated is the *mover*: its record at `WORK_RECORD`
($FFFD), its number in `THIS_RECORD` ($FF83), its working copy at $FFE4.
The step (`TRY_STEP`) found the other with `FIND_OBSTACLE`, which leaves it
in IX and its number in `FOUND_RECORD` ($FFF8); `BUMPED` ($F7C4) takes doors
and sends everything else here. The kind byte's meanings are in
[`object-records.md`](object-records.md). The cases, in order:

1. **The mover hurts (bit 4)** -- the troll, the bouncing balls ($7E88). If
   the other is the knight he loses 10 LIFE (`DECLI1`, $F1B4), except on a
   room's first pass (bit 2 of `GAME_FLAGS`). If the other is not still it
   is knocked -- bit 4 of its +14 and direction $12 make its next update a
   hop upward -- and the mover vanishes (bit 5 of its +16) and is erased
   where it stands. Against a still thing, on to the next case.
2. **The other hurts (bit 4) and the mover is the knight:** 10 LIFE, the
   other vanishes, and his move goes on as if it had not been there.
3. **The mover is a fighter (bit 7).** Not the knight: if it ran into the
   knight, 1 LIFE (`DECLIF`, $F1B6). The knight: with his sword not out (bit
   1 of `GAME_FLAGS`), running into a fighter costs him 1 LIFE; with it out,
   a fighter that can be killed (bit 6: the guards, the ghosts, the troll)
   loses a strike from its counter, and at none left a guard (state 6, 9 or
   10) becomes its helmet ($A4B8: the sprite changed, +14 = $10, +12 = $A0
   -- a thing that can be picked up -- and +13 = $12) and anything else
   vanishes.
4. **A state-13 mover (the ghost, $5B30) meets a thing that can be picked
   up (bit 5):** the thing's object-table entry goes to room $FE
   (`SET_THING_ROOM`, $F4E6, the author's ROMM) and it vanishes.
5. **A thing of kind 6 or 10 meets a state-11 creature (the wraith):** both
   entries go to room $FE and both vanish.
6. **The other is kind 7 (a pit's floor):** the mover vanishes, and if it is
   the knight LIFE becomes 0. The five bytes after the `JR` that ends this
   case (`SKIPPED_REMOVAL`, $FA74: `LD C,$FE : CALL $F4E6`) would have
   moved the mover's table entry to room $FE; nothing reaches them.
7. **A state-9 guard meets a decoy (kind 8)** (`MEET_DECOY`, $FA83): the
   decoy's entry to room $FE, it vanishes, and `THINGS_NOTED` is cleared,
   so the guard goes back to the knight.
8. Anything else: `BLOCKED_MOVE` ($FA9C).

When something has vanished or become a helmet, `OTHER_VANISHES` ($F9E6)
finishes the mover's move with a nested `BLOCKED_MOVE` and then redraws the
other with `THIS_RECORD` set to what it takes to be the other's number, so
that `REDRAW_OBJECT` leaves it out and it is erased. `MOVER_VANISHES`
($FA79) is the same for the mover.

**Strike counters.** `FIND_OBSTACLE` numbers the fighters as it walks down
from the top of the record list: IY+2 (`STRIKES_AT`, $FF82) starts at $9E
and drops by one at each fighter, never below $98. So the first six
fighters from the top own `STRIKES_LEFT` $FF9D down to $FF98 and any more
share $FF98. The numbering depends only on the order of the records, so a
fighter keeps its counter while the room lasts. `ROOMST` sets all six to 4
on entry: four strikes kill.

**LIFE** is two decimal digits, `LIFE_TENS` ($FF95) and `LIFE_UNITS`
($FF96), read together as HL; `DE1` ($F1C8) subtracts A with a borrow
between the digits and stops at 00. At 00 the main loop returns from
`ROOMST`: game over ([`game-cycle.md`](game-cycle.md)).

## How this was found

Read (stage 2, range 5), with the record layout checked against the object
table and templates and a census of every record in every room (each
record's kind, flags, state, +16 and sprite). The sprites named here were
looked at in the build's pictures first. Staged in the simulator:

- **The troll touched** (room 2, its record put on the knight): LIFE 99 to
  89, and at $FA0D `FOUND_RECORD` held 3 while the troll was record 19 (the
  stale number, below).
- **A guard killed** (room 29; `STRIKES_LEFT` all set to 1; the guard put
  against the knight's +x side; B and Y held): stopped at $F9C7 with IY+2 =
  $9C, then $F9D5, $F9EC, $FA00; the record became kind $A0, state $10,
  sprite $A4B8. The build's sessions never ran this.
- **A wraith destroyed** (room 28, the kind-6 thing dropped just above the
  wraith): $FA40 reached, both records hidden, both entries room 254. Not in
  the sessions either.
- **The pits**: room 9's records -- a bridge of slabs at height 70 over a
  kind-7 slab covering the floor at 10 -- and the fixed floor at 10 in rooms
  9 and 12 only.

## Confidence

The order and effects of the cases: *read*. The kill, the wraith's
destruction, the troll's 10 LIFE and the stale number: *measured*. The
names (guard, ghost, troll, wraith, ball): *inferred* from their pictures
and MIWRAI/MITRO. That a thing lost in a pit comes back when the room is
entered again: *inferred* from the skipped removal and from
`SAVE_OBJECT_POSITIONS` saving where it vanished.

## Krumlinde

He leaves $F959 unnamed (`Sub_F959` and friends); his analysis flags it as
a follow-up, "plausibly push or slide". He noted the dead bytes at $FA74
too. At $F9E2 he has `DB $FE` and a label at $F9E3: the instruction is `CP
$0A`, the third guard state, 10 -- and the code ran through it in the
sessions. His `Sub_FF98`/`Sub_FF9B` are one array of six strike counters.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `OBJECTS_MEET` | `SUBF959` | $F959 | A mover meets something not a door |
| `OTHER_VANISHES` | (entry) | $F9E6 | Hide the other and finish |
| `SKIPPED_REMOVAL` | `DATAFA74` | $FA74 | Five unreachable bytes |
| `MOVER_VANISHES` | `SUBFA79` | $FA79 | Hide the mover and finish |
| `MEET_DECOY` | `SUBFA83` | $FA83 | A guard takes a decoy; then `BLOCKED_MOVE` |
| `STRIKES_LEFT` | `VARFF98` | $FF98 | Six strike counters |
| `STRIKES_AT` | `VARFF82` | $FF82 | The low byte of the one in use |

## Open questions

- **A stale number** ($FA0D, *measured*): `OTHER_VANISHES` reads
  `FOUND_RECORD` after the mover's own redraw has reused that byte for its
  sprite's width in bytes (`DRAW_SPRITE`), so `THIS_RECORD` gets the wrong
  number. With the other hidden that is harmless; in the helmet case the
  helmet is visible and `REDRAW_OBJECT` may draw it into its own region.
  Not watched.
- What the things of kind 10 (type 21, rooms 48 and 57) and kind 11 (type
  50, room 14) are called in the game.
- The knocked hop (+14 bit 4, direction $12) is read, not watched.
