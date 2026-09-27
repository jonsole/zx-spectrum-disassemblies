# Collision

**Question this answers:** how a move is stopped by the floor, the walls and
other objects, and what passes between two objects that meet.

**Short answer:** Knight Lore's per-axis clipping, Z then U then V, a unit
at a time: the floor, the walls (the room's half-sizes, off during the walk
into a room and in a doorway) and all 56 records. Harm passes both ways by
bits 5-7 of +$0D; a pushable obstacle takes the mover's step; a carried
mover hands its Z step to what it lands on and rides that thing's U and V
steps; and a carried mover of graphics 16-47 -- the robot, the pushable and
bobbing blocks, the lift -- marks what it lands on, which is how blocks know
they are stood on.

## How it works

```
ADJ_FOR_OUT_OF_BOUNDS $C442      (the robot's move from MOVE_PLAYER $C296,
                                  everything else's from DEC_DZ_AND_UPDATE_UVZ $BFB6)
  bit 1 of its own +$07 set while it works (so it does not meet itself);
  bits 0-2 of +$0C cleared, then set per axis cut
  Z: ADJ_DZ_FOR_OUT_OF_BOUNDS $C357 (FLOOR)   then ADJ_DZ_FOR_OBJ_INTERSECT $C535
  U: ADJ_DU_FOR_OUT_OF_BOUNDS $C5E9 (ROOM_HALF_U) then ADJ_DU_FOR_OBJ_INTERSECT $C497
  V: ADJ_DV_FOR_OUT_OF_BOUNDS $C613 (ROOM_HALF_V) then ADJ_DV_FOR_OBJ_INTERSECT $C4E6
```

- **Overlap** (`DO_OBJS_INTERSECT_ON_U`/`_V`/`_Z`, $C5A9, $C5BE, $C5D3; also
  used by `DO_ANY_OBJS_INTERSECT` $B712 and `CAN_PICK_UP` $BEA7): boxes are
  centred in U and V with +$04/+$05 their half-sizes; they overlap if the
  distance between the centres after the move is less than the two
  half-sizes added -- touching is not overlapping. In Z the base is +$03 and
  the height +$06. `IS_OBJECT_NOT_IGNORED` ($B74D) skips empty records and
  those with bit 1 of +$07. `SHORTEN_DELTA` ($C386) takes a unit off a step,
  and the test repeats until it clears or the step is gone.
- **The walls and the floor.** The floor is `FLOOR` ($5B0E, 64 in all three
  room sizes). The walls are 128 plus or minus `ROOM_HALF_U`/`ROOM_HALF_V`
  less the mover's half-size. They are off while bit 0 of +$07 is set (the
  legs in a doorway, [`doorways-and-rooms.md`](doorways-and-rooms.md)) and
  during the walk into a room (bits 4-7 of +$0C).
- **What passes between them** (all *read* at `ADJ_DZ_FOR_OBJ_INTERSECT`,
  $C54F-$C596, and the U and V tests):
  - Harm, both ways: bit 7 of one's +$0D (kills what it moves into) becomes
    bit 6 (killed) of the other, and the other's bit 5 (kills what touches
    it) becomes the mover's bit 6.
  - A stopped move sets the axis's bit in the mover's +$0C.
  - In U and V, an obstacle with bit 2 of +$07 (pushable) takes the mover's
    step, and moves by it on its own update; `PUSHABLE` ($B2FF) clears it
    after one move.
  - In Z, a mover with bit 2 of +$07 (carried by what it stands on) gives
    the obstacle its Z step (+$0B) and takes the obstacle's U and V steps
    wherever its own are zero. So a thing on a conveyor rides it, and a
    lift pushing up into its rider hands the rider its Z step.
  - In Z, if that mover's graphic is 16-47, the obstacle gets bit 3 of +$0D
    -- "landed on". The templates give bit 2 of +$07 to the pushable blocks
    (28, 29), the bobbing block (31) and the lift (47), and the robot's start
    template gives it to his legs, so all of them mark what they land on.
    The dropping block, the collapsing block and the lift read it
    ([`carrying-and-lifts.md`](carrying-and-lifts.md)).
- **The top.** While the legs move they are 23 high, the whole robot, and
  the top is out of the tests (bit 1 of its +$07) with no height; between
  moves the top is a box of its own from 12 to 23 above the legs' base that
  things can land on ([`robot.md`](robot.md)).

## How this was found

Read against Pentagram's `ADJ_FOR_OUT_OF_BOUNDS` (1.00),
`ADJ_DU_FOR_OBJ_INTERSECT` and `ADJ_DV_FOR_OBJ_INTERSECT` (0.97),
`ADJ_DZ_FOR_OBJ_INTERSECT` (0.78), the overlap tests (1.00) and the wall and
floor clips (0.92-1.00) (stage 2, range 4). The carrying rules were read
again by range 2 for the movers, and *measured* with the conveyors and lifts
in staged scenes ([`carrying-and-lifts.md`](carrying-and-lifts.md)). The
graphics that can set "landed on" were settled for these notes from the
object templates' flags.

## Confidence

*Read*; the Z step handed on and the ride on a conveyor *measured*.

## Knight Lore and Pentagram

The same design and nearly the same code
([`../knightlore/collision.md`](../knightlore/collision.md),
[`../pentagram/collision.md`](../pentagram/collision.md)). The Z test is
different in each: Knight Lore marks every obstacle met in Z and passes no Z
step; Pentagram passes the Z step, marks every obstacle and adds its
conveyors and its lift's "stood on" mark; Alien 8 passes the Z step and
marks only what a carried mover of graphics 16-47 lands on. Alien 8's
conveyors need no code here: they carry by the step the rider takes over.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `ADJ_DZ_FOR_OUT_OF_BOUNDS` | `SUBC357` | $C357 | the floor (`CLIP_DZ_TO_FLOOR`) |
| `SHORTEN_DELTA` | `SUBC386` | $C386 | a unit off a step (`SHORTEN_DELTA_DEC`) |
| `ADJ_FOR_OUT_OF_BOUNDS` | `SUBC442` | $C442 | cut a move short |
| `ADJ_DU_FOR_OBJ_INTERSECT` | `SUBC497` | $C497 | dU against objects (`DU_OBJ_HIT_TEST`, `DU_OBJ_NEXT`) |
| `ADJ_DV_FOR_OBJ_INTERSECT` | `SUBC4E6` | $C4E6 | dV (`DV_OBJ_HIT_TEST`, `DV_OBJ_NEXT`) |
| `ADJ_DZ_FOR_OBJ_INTERSECT` | `SUBC535` | $C535 | dZ (`DZ_OBJ_HIT_TEST`, `DZ_OBJ_NEXT`) |
| `DO_OBJS_INTERSECT_ON_U`, `_V`, `_Z` | `SUBC5A9`, `SUBC5BE`, `SUBC5D3` | $C5A9-$C5D3 | overlap per axis |
| `ADJ_DU_FOR_OUT_OF_BOUNDS`, `ADJ_DV_FOR_OUT_OF_BOUNDS` | `SUBC5E9`, `SUBC613` | $C5E9, $C613 | the walls (`CLIP_DU_TO_WALLS`, `CLIP_DV_TO_WALLS`) |
| `DO_ANY_OBJS_INTERSECT`, `IS_OBJECT_NOT_IGNORED` | `SUBB712`, `SUBB74D` | $B712, $B74D | any overlap; the skip test |

## Disassembly corrections

- Where two drafts disagreed on who sets "landed on": range 4 had "the
  robot's legs", range 2 "the robot, and the movable blocks". The code
  ($C568-$C577) tests bit 2 of +$07 and graphics 16-47; range 2 was right.
  The listing's comment there still says only the robot.
- Range 1's draft took the passing of the Z step from Pentagram's notes as
  an inference; range 4 read it at $C57B. It is *read*.

## Open questions

- Whether a bobbing block or a lift ever lands on something it then marks
  (they only go down onto the floor or what is under them) -- harmless
  either way.
