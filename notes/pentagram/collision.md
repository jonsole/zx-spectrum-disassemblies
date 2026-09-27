# Collision

**Question this answers:** what stops a thing moving through the walls, the
floor and other things, and what happens when two things meet.

**Short answer:** Knight Lore's collision code: each axis in turn, Z then U
then V, the step shortened a unit at a time against the floor, the walls and
all 54 records, harm passed both ways and pushes handed on. Pentagram adds
three things to the Z test: conveyors (graphics 140-143) that carry what
stands on them, a "stood on" mark in +$17 that the lift, the bobber and the
crumbling block use, and a mobile mover giving its Z step to what it lands on.

## How it works

```
DEC_DZ_AND_UPDATE_UVZ $B979   dZ - 1 (gravity)
 CLIP_AND_MOVE $B97C          ADJ_FOR_OUT_OF_BOUNDS $B6ED: bit 1 of +$07 on, bits 0-2 of +$0C off
                                Z: ADJ_DZ_FOR_OUT_OF_BOUNDS $B963 (floor), ADJ_DZ_FOR_OBJ_INTERSECT $B7E0
                                U: ADJ_DU_FOR_OUT_OF_BOUNDS $B8E2 (walls), ADJ_DU_FOR_OBJ_INTERSECT $B742
                                V: ADJ_DV_FOR_OUT_OF_BOUNDS $B90D (walls), ADJ_DV_FOR_OBJ_INTERSECT $B791
 ADD_DUVZ $B97F               position += what is left of the step
```

Most movers come in at `CLIP_AND_MOVE`, to move without falling; the
player's legs cut their own move and come in at `ADD_DUVZ`
([`player.md`](player.md)).

- **The boxes.** `DO_OBJS_INTERSECT_ON_U` $B8A2 and `_ON_V` $B8B7: U and V are
  centres with half-sizes (+$04, +$05); they overlap if the distance after the
  mover's step is less than the half-sizes added -- exactly touching is not
  overlapping. `_ON_Z` $B8CC: Z is a base with a whole height (+$06), and the
  gap between the bases is compared with the lower object's height.
  `IS_OBJECT_NOT_IGNORED` $B99B skips empty records and those with bit 1 of
  +$07, which the mover sets on itself for the duration. `SHORTEN_DELTA` $B95A
  moves a step one unit towards zero (*read*).
- **One axis at a time.** Each test counts the steps already accepted on the
  earlier axes and the later ones as zero, which is what lets a blocked
  diagonal slide along a wall (*read*).
- **The room.** `ROOM_EXTENT` ($A71D-$A71F) is the U half-size, the V
  half-size and the floor's height, copied from `ROOM_SIZES` ($5E07) by the
  builder: (64, 64), (32, 64) or (64, 32) about the room's middle at 128, the
  floor at 128 in all three. The walls keep a thing's whole footprint inside;
  the floor is the only limit in Z -- there is no ceiling (*read*). The walls
  are off while the count in the top four bits of +$0C runs (the walk into a
  room) and while bit 0 of +$07 is set (in a doorway)
  ([`doorways-and-rooms.md`](doorways-and-rooms.md)).
- **Meeting.** Each axis sets its bit in +$0C (0 U, 1 V, 2 Z -- bit 2 is
  "standing on something" after a move down). Harm passes both ways: the
  obstacle gets bit 6 of +$0D (killed) if the mover has bit 7, and the mover if
  the obstacle has bit 5. In U and V an obstacle with bit 2 of +$07 (mobile)
  is given the mover's whole intended step: it is pushed, and moves on its own
  next update -- if its routine lets it ([`movers.md`](movers.md)) (*read*).

What the Z test (`ADJ_DZ_FOR_OBJ_INTERSECT` $B7E0) adds over Knight Lore's:

- `MARK_STOOD_ON` ($B890): if the mover is the player's legs (graphics 32-39)
  or graphic 91, bit 7 of the obstacle's +$17; and if the obstacle is the
  player's legs, bit 7 of the mover's +$17. `LIFT` ($CDBB), `BOBBER` ($CE31)
  and `CRUMBLING_BLOCK` ($D2AD) read and clear it.
- `CONVEYOR_PUSH` ($B866): if the obstacle is graphic 140-143 and nothing has
  met it yet this turn (its bit 3 of +$0D clear -- set just after, cleared only
  by the conveyor's own update routine), then on odd turns (bit 0 of `TURNS`)
  the mover's step gets the pair from `CONVEYOR_STEPS` ($D30A): 140 +2 U, 141
  -2 U, 142 +2 V, 143 -2 V.
- Bit 3 of the obstacle's +$0D: something met it in Z this turn (as in Knight
  Lore).
- A mover with bit 2 of +$07 gives its intended Z step to the obstacle and,
  where its own U or V step is zero, takes the obstacle's: standing on
  something that moves carries it along. The player has the bit, so this is
  how a sinking block sinks, a lift starts and a pacer carries him
  ([`movers.md`](movers.md)).

## How this was found

Read against Knight Lore's `adj_for_out_of_bounds` family (matches 0.5-0.94
in `kl_matches.txt`), stage 2, range 2. `CONVEYOR_PUSH` never ran in the
build's sessions (`pentagram-coverage.txt`), so it was run in SkoolKit's
simulator: the player's legs (graphic 32) falling with dZ -2 onto a block of
each of graphics 140-143, on an even and an odd turn; again with the block's
bit 3 already set; then a mover with bit 2 falling onto a block moving 3 in U
and -1 in V. A wall test: an object of half-size 4, 90 from the centre in a
room whose U half-size was poked to 96, asked to move 5 in U, moved 1 with
bit 0 of +$0C set. In play, the conveyors were stood on in room 37 (range 5):
+2 U every other turn on graphic 140, +2 V on 142.

## Confidence

*Read*: all. *Measured* (simulator): the conveyor directions, the odd-turn
rule, the once-a-turn rule, the +$17 mark, the carried mover taking the
block's U and V steps and the block taking its -2 in Z, the wall cut.

## Knight Lore

Same structure and the same instructions for the floor, the walls and the U
and V tests ([`../knightlore/collision.md`](../knightlore/collision.md)), with
54 records scanned instead of 40. Knight Lore's floor is a constant $80 in its
own variable; Pentagram reads the third byte of the room size, which is 128 in
every size. The Z test's extras above are Pentagram's.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `ADJ_FOR_OUT_OF_BOUNDS` | `SUBB6ED` | $B6ED | cut a step against the room and objects |
| `ADJ_DU_FOR_OBJ_INTERSECT`, `_DV_`, `_DZ_` | `SUBB742`, `SUBB791`, `SUBB7E0` | $B742-$B7E0 | against objects |
| `CONVEYOR_PUSH` | `SUBB866` | $B866 | conveyors carry what stands on them |
| `MARK_STOOD_ON` | `SUBB890` | $B890 | +$17 bit 7 |
| `DO_OBJS_INTERSECT_ON_U`, `_V`, `_Z` | `SUBB8A2`, `SUBB8B7`, `SUBB8CC` | $B8A2-$B8CC | overlap on one axis |
| `ADJ_DU_FOR_OUT_OF_BOUNDS`, `ADJ_DV_FOR_OUT_OF_BOUNDS` | `SUBB8E2`, `SUBB90D` | $B8E2, $B90D | the walls |
| `SHORTEN_DELTA` | `SUBB95A` | $B95A | one unit towards zero |
| `ADJ_DZ_FOR_OUT_OF_BOUNDS` | `SUBB963` | $B963 | the floor |
| `DEC_DZ_AND_UPDATE_UVZ` | `SUBB979` | $B979 | gravity, cut, move |
| `IS_OBJECT_NOT_IGNORED` | `SUBB99B` | $B99B | skip empty or ignored records |

Knight Lore's names, with its X and Y as this listing's U and V. Entry points:
`DU_OBJ_HIT_TEST`/`DU_OBJ_NEXT` and the V and Z pairs, `CLIP_DU_TO_WALLS`
$B8F1, `CLIP_DV_TO_WALLS` $B91C, `CLIP_DZ_TO_FLOOR` $B967, `SHORTEN_DELTA_DEC`
$B961, `CLIP_AND_MOVE` $B97C, `ADD_DUVZ` $B97F.

## Disassembly corrections

- The description of `ADJ_DZ_FOR_OBJ_INTERSECT` still calls $CDBB and $CE31
  "a lift and a hopper, by the remake's reading": both are settled now -- a
  lift (*measured*) and a bobbing thing, whose deadly form is the head of
  graphic 86 ([`movers.md`](movers.md)). To tidy in the annotations.
- A stage 2 draft called graphic 91 "the block pushed by $CD75"; the code at
  `HEAVY_BLOCK` clears the U and V steps before moving, so pushes are thrown
  away and it only falls (*read*; the template of graphic 91 does not have
  bit 2 anyway).

## Open questions

- Whether a mobile mover giving its Z step to what it lands on has a visible
  effect beyond the sinking block and the lift (a block under a pushed thing?)
  -- nothing traced.
