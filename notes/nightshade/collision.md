# Collision with the town

**Question this answers:** how a thing walking through the town is stopped
by walls and buildings.

**Short answer:** each cell type has a list of boxes (`BOX_TABLE`, $6334).
Before a step is taken, the cells under the thing's leading edge -- now,
and after the step -- are looked up, and the thing's footprint, moved by
the step, is tested against each of their boxes. At the first overlap the
step is cut short by the overlap, so the move ends against the box's face,
and bit 0 of the record's flags is set. Things are not tested against each
other here: that is [`touching.md`](touching.md).

## How it works

```
SET_STEP $DCE0            step (+A, +B) = speed along the facing's axis
MOVE_CLIPPED $DE59        clear flags bit 0 (MOVE_CLIPPED_AGAIN $DE5D keeps it)
  -> MOVE_TABLE $DE6A by facing (bits 6-7 of +6), through DISPATCH:
     +V CLIP_PLUS_V $DE72   +U CLIP_PLUS_U $DED3
     -V CLIP_MINUS_V $DF34  -U CLIP_MINUS_U $DF97       which cells to test
       -> CUT_STEP_PLUS_V $DFFA / CUT_STEP_MINUS_V $E00B  (HIT_BOXES_V $E0A0)
          CUT_STEP_PLUS_U $E013 / CUT_STEP_MINUS_U $E020  (HIT_BOXES_U $E063)
            PLACE_IN_CELL $E028 (TOWN_CELL $E051)   OVERLAP_U $E087 / OVERLAP_V $E0C4
            MARK_BLOCKED $E005: flags bit 0, carry
APPLY_STEP $DD01          U += step U, V += step V
```

- **The cells tested.** For +V the leading edge is V + the half-size in V
  (+9), from U - (+8) to U + (+8). The cell under the left corner is tested;
  the right corner's only if it is a different cell; then, if the step takes
  the edge into the next row of cells, the cells the moved corners reach.
  The first cut stops the search. The other three facings are the same
  turned round (`CLIP_PLUS_U` exchanges U and V; the minus facings take the
  edge at minus the half-size and the step as negative).
- **The test.** `PLACE_IN_CELL` gives the cell's type and the thing's
  position in the cell's own frame: U and V less the cell's corner, halved,
  plus 64, so the cell spans 64-191 and half a cell beyond it either way
  still fits a byte. A box (four bytes: centre U, centre V, half-size U,
  half-size V, in the same half units; a list ends at 0) overlaps when
  |position + step/2 - centre| < half the thing's half-size + the box's
  half-size, on both axes. `HIT_BOXES_U` tests V then U and returns the U
  overlap; `HIT_BOXES_V` the other way. The `CUT_STEP_*` routines add twice
  the (signed) overlap to the step, which leaves the thing touching the
  box.
- **Exact wherever it probes.** The test uses the thing's own position and
  step, so an extra probe costs only time: a step of 0 in `CLIP_MINUS_U`
  reads as -256 (the sign-extended $FF) and tests the column behind too.
- **Two-way steps** (`MOVE_SPLIT`, $DE0D): the wanderers step both ways at
  once, which no clip routine handles, so they are clipped as a U move and
  then a V move ([`movement.md`](movement.md)).
- **Twice a turn**: antibodies and thrown objects call `MOVE_CLIPPED` then
  `MOVE_CLIPPED_AGAIN`, applying the step after each, so the wall flag says
  whether either move hit.
- **Who reads the flag**: a thrown object lies down, an antibody or a
  sparkle bursts, the creature bursts, the villains and the monsters of
  112-127 turn (`STEER`), the knight's top throws out its arms, and things
  on the screen warble (`BUMP_SOUND`).

## How this was found

Read (stage 2, ranges 4 and 5): `CLIP_MINUS_U` and its callees, then the
other three, register by register (their pushes and pops swap DE and HL
between tests). The box format compared with the generator's reading of
`BOXES1` -- four thin boxes along the cell's edges.

## Confidence

*Read*, all of it. Not exercised on its own in the simulator; the sessions
walk the knight and the wanderers into walls and all of the code ran.

## Filmation (Knight Lore, Alien 8, Pentagram)

Knight Lore, Alien 8 and Pentagram cut a move against the room's walls
and every other object, one axis at a time, a unit at a time. Nightshade's
walls are not objects but per-type boxes looked up through the map, only
the cells under the leading edge are tested, and the cut is exact in one
go. "Stopped" is a flag in the record (bit 0 of +7), read by the update
routines afterwards. No routine here matches the earlier games' above 0.5
(`matches.txt`).

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `MOVE_CLIPPED`, `MOVE_CLIPPED_AGAIN` | `SUBDE59` | $DE59, $DE5D | clear the wall flag, clip by facing |
| `CLIP_PLUS_V`, `CLIP_PLUS_U`, `CLIP_MINUS_V`, `CLIP_MINUS_U` | `SUBDE72`, `SUBDED3`, `SUBDF34`, `SUBDF97` | | which cells to test |
| `CUT_STEP_PLUS_V`, `CUT_STEP_MINUS_V`, `CUT_STEP_PLUS_U`, `CUT_STEP_MINUS_U` | `SUBDFFA`, `SUBE00B`, `SUBE013`, `SUBE020` | | cut at a cell's boxes (entries `CUT_STEP_V`, `CUT_STEP_U`, `MARK_BLOCKED`) |
| `PLACE_IN_CELL`, `TOWN_CELL` | `SUBE028` | $E028, $E051 | cell type and the place in it; the plain look-up |
| `HIT_BOXES_U`, `HIT_BOXES_V`, `OVERLAP_U`, `OVERLAP_V` | `SUBE063`, `SUBE0A0`, `SUBE087`, `SUBE0C4` | | the box tests |

`MOVE_TABLE` is stage 1's and stands.

## Open questions

- `TOWN_CELL` does not check the column and row are below 32; the town's
  edge of solid cells presumably keeps everything inside -- except
  `PLACE_BONUS`, which looks a row up before wrapping it
  ([`finds-and-bonuses.md`](finds-and-bonuses.md)).
- The overlap's sign test (`JP P` after a `SUB`) is right only for
  differences within about a cell; fine for probes next to the thing, not
  proved for every case.
- Why test the cells under the front corners before the step as well as
  after: presumably because a box may reach anywhere in its cell. Whether
  any box list needs it was not checked.
