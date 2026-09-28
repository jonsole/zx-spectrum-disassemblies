# The drawing order

**Question this answers:** in what order the cells round the knight are
drawn each turn, and how `DRAW_ORDER`'s 32 records are used.

**Short answer:** the view is the knight's cell and its eight neighbours.
Five of them lie behind or beside him; which of those five are built on
picks one of 32 records of five steps, each step a cell and whether to draw
its walls (built on) or its things (open). Then his own cell and the three
in front are done, each its outline on the ground and then its things.

## How it works

`DRAW_CELLS` ($CF08), every turn from the main loop:

1. `COLUMNS_DRAWN` ($BBBB) set to $E001: the screen columns off the
   buffer's edges already claimed ([`drawing-the-town.md`](drawing-the-town.md)).
2. His cell in view coordinates: `TURN_CELL` ($D17D) turns it round when
   `VIEW` bit 0 is set, and `LOOK_UP_CELL` ($D564) reads the map through
   the view, so U-1 and V+1 are always further back.
3. A bit for each of five cells that is not open ground: bit 0 (U-1, V+1),
   bit 1 (U-1, V), bit 2 (U, V+1), bit 3 (U-1, V-1), bit 4 (U+1, V+1). The
   five bits are the record number in `DRAW_ORDER` ($6204).
4. Each of the record's five step bytes: bits 4-5 the U offset and bits 6-7
   the V offset (the high bit of each pair "same", the low "+1", neither
   "-1"); bits 0-1 the action -- 0 the things in the cell
   (`LIST_THINGS_IN_CELL` $CFAF, then `SORT_AND_DRAW_THINGS` $CFF2), 1 its
   walls (`DRAW_WALLS`, $D372), 2 its walls by `DRAW_OUTLINE` ($D19D),
   3 nothing. `DRAW_STEP` ($CF5F) pushes the return address ($CF8D) and
   jumps to the action.
5. Then his own cell, (U, V-1), (U+1, V) and (U+1, V-1): `DRAW_FRONT_CELL`
   ($CFA5) draws the building's outline by `DRAW_OUTLINE` and falls into
   `DRAW_CELL_THINGS` ($CFAA).

**The table's contents** (*measured*, counted from the listing): every
record names the same five cells, (-1,+1), (-1,0), (0,+1), (-1,-1),
(+1,+1), each 32 times over the table, with action 1 in the 16 records
where that cell is built on and 0 in the other 16. Actions 2 and 3 appear
in no record, which is why the code for them ($CF88-$CF8C) never ran. What
changes from record to record is the order of the five: the walls behind
are drawn nearest first (a wall claims its screen columns, so what is
further back cannot overwrite it), and an open cell's things go after the
walls behind them and before those in front.

## How this was found

Read (stage 2, range 2); the 32 records decoded with
`nightshade_data.draw_steps` and counted; the front cells' routine settled
by range 3, which patched `DRAW_OUTLINE` and `DRAW_WALLS` to return at once
in the simulator and saw the outlines in front of the knight, and then the
walls behind him, disappear.

## Confidence

*Read*; the table's contents *measured* by counting. That every record
keeps an open cell's things between the walls behind and in front of it
was checked by hand for several records, not all 32 (*inferred* for the
rest).

## Filmation (Knight Lore, Alien 8, Pentagram)

Nothing like it in the three earlier games, which sort all of a room's
objects together in three dimensions. Nightshade orders cells first, by a
table, then sorts only the things within each cell
([`depth-order.md`](depth-order.md)).

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `DRAW_CELLS` | `SUBCF08` | $CF08 | the nine cells, back to front |
| `DRAW_STEP`, `DRAW_FRONT_CELL`, `DRAW_CELL_THINGS` | (new labels) | $CF5F, $CFA5, $CFAA | a step; a front cell; its things |

## Disassembly corrections

- The generator called action 2 "its wall's ends (#R$D19D)"; `DRAW_OUTLINE`
  draws a building's outline on the ground. Now "its outline on the ground".
- Stage 1's label `DRAW_STEP_DONE` ($CF8D, the address `DRAW_STEP` pushes)
  was lost in the stage 2 merge: `LD DE,$CF8D` has no label to show.
  Reported to the lead.

## Open questions

- Why a record would ever need actions 2 or 3: a pattern the table once
  had, or room for one (*inferred*: the code was written for more than the
  data uses).
- A script placing a thing in each of the five cells for each record would
  settle the "things between the walls" rule for all 32.
