# Depth order

**Question this answers:** which objects are redrawn each turn, and in what
order -- and why a valve can vanish when it is drawn.

**Short answer:** Pentagram's renderer front end, the same logic byte for
byte. A moved object marks every object its old or new screen rectangle
meets (bit 4 of +$07); at the end of the turn those are listed in
`DRAW_LIST` ($C745) and drawn back to front by a pairwise comparison of
their boxes through Knight Lore's 27-entry `DEPTH_ORDER` table ($C833).
Alien 8's list (64 bytes) and candidate chain (16) are big enough for its
56 records -- Pentagram's list is not. When the comparison finds a loose
valve sharing space with anything, the valve is destroyed.

## How it works

- **Marking** (`SET_DRAW_OBJS_OVERLAPPED` $C657, called by the top and
  through `SET_WIPE_AND_DRAW_FLAGS` $BFAB): the union of the object's new
  rectangle and last turn's (+$1C-+$1F), in byte columns and pixel rows;
  bit 4 of +$07 set on every live record meeting it (`OVERLAP_TEST_OBJ`
  $C6A5).
- **Listing** (`LIST_DRAWN` $C71C, from the end of the turn): the numbers
  of the records with bit 4 set into `DRAW_LIST`, then $FF. 64 bytes: 56
  and the $FF fit.
- **Sorting** (`SORT_AND_DRAW` $C785, from `RENDER_DYNAMIC_OBJECTS`): take a
  candidate IX, compare it with each undrawn IY: a Z code 0/1/2, a V code
  0/3/6 and a U code 0/9/18 added index `DEPTH_ORDER`, 27 words, Knight
  Lore's table entry for entry. `ORDER_UNCONSTRAINED` ($C869) and
  `CANDIDATE_ALREADY_FIRST` ($C86C) go on to the next; `IY_GOES_FIRST`
  ($C86F) makes IY the candidate, recording it in `CANDIDATE_CHAIN` ($C8EF,
  16 bytes); meeting a record already in the chain breaks the circle by
  drawing it (`BREAK_ORDER_CYCLE` $C898). `DRAW_CANDIDATE` ($C8D5) sets bit
  7 of its list entry, empties the chain, counts one in `DRAW_WORK` and
  draws it ([`drawing.md`](drawing.md)); `ALL_DRAWN` ($C8EA) ends it.
  `SORT_FIRST` and `SORT_SECOND` ($5B2D, $5B2F) point just past the two
  entries being compared.
- **The same space** (`BOXES_INTERSECT` $C8AB, index 13, the two boxes
  overlapping in all three axes): unless either has bit 1 of +$07 (out of
  the collision tests), a loose valve (graphics 96-99) -- the candidate
  first, else the other -- becomes graphic 64, the short sparkle:
  `SPARKLE_STEP` ($B3A4) takes it to 65 and `SPARKLE_END_PLACE` ($B3B0)
  empties its place in `PLACES` and the record. The valve is gone for good
  ([`valves-and-sockets.md`](valves-and-sockets.md)).

## How this was found

Read against Pentagram's `CALC_2D_INFO` (1.00), `SET_DRAW_OBJS_OVERLAPPED`
(0.98), `LIST_DRAWN` (0.94), `SORT_AND_DRAW` (1.00) and its neighbours, and
Knight Lore's `objs_coincide` (stage 2, range 4). *Measured*: the high-water
marks, by filling the list and the chain with $FE (a byte no entry can be)
at the first turn's `LIST_DRAWN` and running the build's room tour -- every
room, the first 14 steps of the keyboard round and 3 s each -- reading after
each room the furthest $FF in the list and the furthest byte not $FE in the
chain: the longest list was 51 entries, the longest chain 8 (by room $12).
And the valve's end: a valve placed inside the robot's box in the start room
vanished, record and place, with the IY branch ($C8CE) and `$B3B0`
executed.

## Confidence

*Read*, with the list's and chain's lengths and the valve's destruction
*measured*. The far-side rule (smaller U, larger V, lower Z drawn first) is
Pentagram's measurement, taken on the strength of identical code.

## Knight Lore and Pentagram

The sort and its table are Knight Lore's
([`../knightlore/depth-order.md`](../knightlore/depth-order.md)). Knight
Lore destroys a collectable at index 13; Pentagram dropped that
([`../pentagram/depth-order.md`](../pentagram/depth-order.md)); Alien 8
keeps it, for its valves, and adds the test of bit 1. The chain is 16
bytes, as in Pentagram (Knight Lore's 8 holds 7); the list is 64 -- Knight
Lore's 48 for 40 records, Pentagram's 48 for 54, which can overflow.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `CALC_2D_INFO` | `SUBC63D` | $C63D | an object's screen rectangle |
| `SET_DRAW_OBJS_OVERLAPPED` | `SUBC657` | $C657 | mark what a move touches (`OVERLAP_TEST_OBJ`) |
| `LIST_DRAWN` | `SUBC71C` | $C71C | list what to draw |
| `DRAW_LIST` | `SPACEC745` | $C745 | the list (stage 1 titled it unused) |
| `SORT_AND_DRAW` | `SUBC785` | $C785 | the sort (`SORT_PASS`, `COMPARE_NEXT_OBJ`, `COMPARE_ALONG_V`, `COMPARE_ALONG_U`, `ACT_ON_COMPARISON`) |
| `DEPTH_ORDER` | `DATAC833` | $C833 | the 27 outcomes |
| `ORDER_UNCONSTRAINED`, `CANDIDATE_ALREADY_FIRST` | `SUBC869`, `SUBC86C` | $C869, $C86C | no order; the candidate first |
| `IY_GOES_FIRST` | `SUBC86F` | $C86F | IY first (`IY_BECOMES_CANDIDATE`, `BREAK_ORDER_CYCLE`) |
| `BOXES_INTERSECT` | `SUBC8AB` | $C8AB | the same space: destroy a valve |
| `DRAW_CANDIDATE` | `SUBC8D5` | $C8D5 | draw it (`DRAW_AND_NEXT_PASS`) |
| `ALL_DRAWN` | `SUBC8EA` | $C8EA | done |
| `CANDIDATE_CHAIN` | `DATAC8EF` | $C8EF | the chain |

## Disassembly corrections

- `$C745` was titled unused by stage 1 (sna2ctl's zeros): it is the draw
  list.

## Open questions

- How a valve comes to share space with something in play (it falls and is
  pushed by the collision code, which should stop that) was not looked for;
  the one test placed it there by hand. Whether a player can lose a valve
  this way is open, and matters: see
  [`valves-and-sockets.md`](valves-and-sockets.md) on the games that deal
  exactly six of one kind.
