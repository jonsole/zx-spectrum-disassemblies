# Depth order: what is redrawn, and in what order

**Question this answers:** which objects are redrawn each turn, and how the
game decides which of them is in front.

**Short answer:** Knight Lore's scheme, stretched from 40 records to 54
without all its buffers growing to match. Anything that moves marks every
object its old-or-new screen rectangle touches; those are listed; the list is
drawn back to front by comparing boxes in pairs through the 27-entry table
`DEPTH_ORDER` ($B638), identical to Knight Lore's, with cycles broken by
drawing at once.

## How it works

**Marking** (`SET_DRAW_OBJS_OVERLAPPED` $B9A7): called by every mover through
`SET_WIPE_AND_DRAW_FLAGS` ($CCDE, which sets bits 4 and 5 of its +$07 first)
and by the player's body. It works out the mover's new rectangle
(`CALC_2D_INFO` $B938), forms the union with the one it had at the start of
the turn (+$1C..+$1F), in byte columns across and pixel rows up, and sets bit
4 on every live record whose rectangle meets it, the mover included
(`OVERLAP_TEST_OBJ` $B9F5). One level only: what is marked does not mark its
neighbours (*read*).

**The list** (`LIST_DRAWN` $B531 into `DRAW_LIST` $B55A): the numbers (0-53)
of the records with bit 4, in record order, then $FF. `SORT_AND_DRAW` sets
bit 7 of each entry as it draws it. `RECORD_OF` ($B520) turns a number back
into a record address, ignoring bit 7.

**The sort** (`SORT_AND_DRAW` $B58A): the first undrawn entry is the
candidate (IX); it is compared with every other undrawn one (IY)
(`COMPARE_NEXT_OBJ` $B5AA). On each axis a code: Z 0, 1 or 2 (candidate above,
overlapping, IY above), V 0, 3 or 6, U 0, 9 or 18 (`COMPARE_ALONG_V` $B5E5,
`COMPARE_ALONG_U` $B60B); the sum indexes `DEPTH_ORDER`
(`ACT_ON_COMPARISON` $B631). "Further back" is smaller U, larger V, lower Z.
Four outcomes:

| Outcome | When | Does |
|---|---|---|
| `IY_GOES_FIRST` $B674 | IY behind or level on every axis, strictly behind on one | IY becomes the candidate (`IY_BECOMES_CANDIDATE` $B687) and the pass restarts -- unless IY is already in `CANDIDATE_CHAIN` ($B6CD): a circle, broken by drawing IY at once (`BREAK_ORDER_CYCLE` $B69D) |
| `CANDIDATE_ALREADY_FIRST` $B671 | the mirror image | nothing: on to the next |
| `ORDER_UNCONSTRAINED` $B66E | each in front on some axis | nothing |
| `BOXES_INTERSECT` $B6B0 | index 13, overlapping on all three | nothing |

A candidate that survives a whole pass is drawn (`DRAW_CANDIDATE` $B6B3:
marked, the chain emptied, `DRAW_WORK` + 1, `DRAW_OBJECT`) and the sort
starts over (`SORT_PASS` $B592) until `ALL_DRAWN` ($B6C8). `SORT_FIRST`
($A719) and `SORT_SECOND` ($A71B) hold the places just after the candidate's
and the compared object's entries (*read*).

Why the rule is right for this projection, and the table drawn as pictures:
Knight Lore's [`depth-order.md`](../knightlore/depth-order.md) and its Depth
sort page; the table is the same entry for entry.

## How this was found

Read against Knight Lore's `calc_display_order_and_render` and
`set_draw_objs_overlapped`, instruction by instruction (`kl_matches.txt`
paired them at 0.5-1.0). Then in SkoolKit's simulator, `SORT_AND_DRAW` with
`DRAW_OBJECT`'s call patched to log IX: of two overlapping boxes, the one with
smaller U, larger V or the lower base was drawn first, whichever way round
they were listed (three pairs). The room counts below came from
`pentagram_data.room_records` plus the scenery templates' piece counts
(stage 2, range 2).

## Confidence

*Read*: all of it. *Measured*: the draw order for three pairs. *Inferred*:
that no real turn lists 48 objects (not measured either way).

## Knight Lore

Same routines, same order, same table. Differences: 54 records instead of 40,
with the draw list not grown to match; a 16-byte candidate chain where Knight
Lore has 8; nothing done for intersecting boxes, where Knight Lore destroys a
collectable met by another object; and `DRAW_WORK` also counts the wiped
rectangles.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `DEPTH_ORDER` | `DATAB638` | $B638 | the 27 outcomes |
| `ORDER_UNCONSTRAINED` | `SUBB66E` | $B66E | no order between the pair |
| `CANDIDATE_ALREADY_FIRST` | `SUBB671` | $B671 | the candidate is behind |
| `IY_GOES_FIRST` | `SUBB674` | $B674 | IY first, or a circle broken |
| `BOXES_INTERSECT` | `SUBB6B0` | $B6B0 | overlap on all three axes |
| `DRAW_CANDIDATE` | `SUBB6B3` | $B6B3 | draw, next pass |
| `ALL_DRAWN` | `SUBB6C8` | $B6C8 | the end of the sort |
| `CANDIDATE_CHAIN` | `DATAB6CD` | $B6CD | the candidates since the last draw |
| `CALC_2D_INFO` | `SUBB938` | $B938 | an object's screen rectangle |
| `SET_DRAW_OBJS_OVERLAPPED` | `SUBB9A7` | $B9A7 | mark what a move covers or uncovers |

New entry points: `SORT_PASS` $B592, `COMPARE_NEXT_OBJ` $B5AA,
`COMPARE_ALONG_V` $B5E5, `COMPARE_ALONG_U` $B60B, `ACT_ON_COMPARISON` $B631,
`IY_BECOMES_CANDIDATE` $B687, `BREAK_ORDER_CYCLE` $B69D, `DRAW_AND_NEXT_PASS`
$B6B6, `OVERLAP_TEST_OBJ` $B9F5.

## Also found for the stage 3 pages (2026-09-27)

- The candidate chain needs its 16 bytes: the longest real chain is 9 (the four start rooms), and four rooms go past Knight Lore's 7 (*measured* over every room's first turn); that this is why it was doubled is *inferred*.

## Open questions

- **Can the draw list overflow?** `DRAW_LIST` is 48 bytes, Knight Lore's size
  for its 40 records. A turn listing more than 47 objects would write its
  later entries and the $FF over the start of `SORT_AND_DRAW`. The fullest
  room, 87, builds 43 records from the directory; the player's two, the two
  bolts and the two things from the sky could make 49 (though nothing falls in
  a room with a quest thing, and the quest things themselves are extra). A
  simulator run of room 87 counting the list each turn would settle it.
- **Can the candidate chain overflow?** It holds fifteen numbers and the $FF;
  a sixteenth link would put the $FF on the first byte of `FILL_RECT`. How
  long real chains get has not been measured.
