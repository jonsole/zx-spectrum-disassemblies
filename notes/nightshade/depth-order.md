# The depth sort

**Question this answers:** in what order the things in one cell are drawn,
so that nearer ones cover further ones.

**Short answer:** only the things in one cell are ever sorted against each
other. They are listed, then drawn one per pass: the first undrawn entry is
the candidate, each later undrawn one is compared with it by their boxes'
sides in U and V, and whichever is further back becomes the candidate; at
the end of the pass the candidate is drawn and marked. Nine outcomes, times
two views, go through `DEPTH_TABLE`.

## How it works

- `LIST_THINGS_IN_CELL` ($CFAF) puts the address of every record with a
  graphic whose cell (+2, +4) is this one on `DRAW_LIST` ($D15D, 32 bytes:
  fifteen addresses and a zero word). Nothing checks the count; a
  sixteenth would put the zero over `TURN_CELL`. Four was the most
  measured.
- `SORT_AND_DRAW_THINGS` ($CFF2): `DRAW_LIST_AT` ($BBC4) just past the
  candidate's entry, `DRAW_LIST_NEXT` ($BBC6) just past the one compared.
  A drawn entry has bit 7 of its high byte cleared (every record lies above
  $8000, so it starts set).
- Each box side is (the position's low byte plus or minus the half-size) /
  2 + 64, the carry of the 9-bit sum rotated back in: a byte for a side
  from 128 units before the cell to 128 past it. On each axis: 0 the
  candidate wholly beyond, 1 overlapping, 2 the other wholly beyond; index
  = U + 3V (+9 turned round).
- `DEPTH_TABLE` ($D0A0): `DEPTH_KEEP` ($D0C4, a `RET`), `DEPTH_SWAP` ($D0C5),
  and `DEPTH_BY_CORNERS` ($D0D0) for 4 and 13. Further back is smaller U and
  larger V (turned: larger U, smaller V). Where each is further back on one
  axis and nearer on the other (0, 8, 9, 17) the candidate stays.
- `DEPTH_BY_CORNERS`: overlapping on both axes, each is placed by its
  nearest corner's V less U (the high-U, low-V corner; turned, the other),
  the one further back first.
- Drawn by `DRAW_SPRITE` ($E3D9), masked, so later things cover earlier
  ones ([`drawing-sprites.md`](drawing-sprites.md)).

## How this was found

Read (stage 2, range 3); the table checked entry by entry against the rule
(all 18 agree). The list's length measured over 1748 stops at
`SORT_AND_DRAW_THINGS` in thirty random cells of play: 0 to 4.

## Confidence

*Read*; the list length *measured*.

## Filmation (Knight Lore, Alien 8, Pentagram)

The model is Alien 8's sort at $C785 (Knight Lore's and Pentagram's
code): first undrawn candidate, compare, swap, draw the survivor.
Differences: two axes instead of three (27 outcomes there); the turned view
doubling the table; a pass that carries on from the new candidate instead
of starting again, so there is no cycle and no chain of candidates (Alien
8's `$C8EF`), at the price that a new candidate is not compared with
entries already passed; and the overlap case is a corner test, not the
earlier games' collision hook (Alien 8's index 13 destroys a valve).

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `LIST_THINGS_IN_CELL` | `SUBCFAF` | $CFAF | the records in one cell |
| `SORT_AND_DRAW_THINGS` | `SUBCFF2` | $CFF2 | draw them, furthest back first |
| `DEPTH_KEEP`, `DEPTH_SWAP`, `DEPTH_BY_CORNERS` | `SUBD0C4`, `SUBD0C5`, `SUBD0D0` | | the outcomes |
| `DRAW_LIST` | `SPACED15D` | $D15D | the list |

## Disassembly corrections

- `$D15D` was a block sna2ctl titled "Unused"; it is the list of records to
  draw, written every turn (still an `s` entry, now described).

## Open questions

- Whether the one-pass order visibly misorders three things in one cell;
  not looked for.
- A thing standing across a cell's edge is drawn in its own cell's turn, so
  something in a later-drawn cell can cover it even when it is nearer. Not
  checked on screen.
