# Carrying

**Question this answers:** how picking up, dropping and weight work, and
where a carried or dropped thing is remembered.

**Short answer:** the knight has five places (1-5; `CARRIED`, $FF9F, five
record addresses; `SELECTED`, $FF9E, the one in use). A pick-up searches a
box his size four units ahead and takes the first thing that can be carried
(+12 bit 5), if the place in use is empty and the load stays under 8. A drop
puts the thing beside him on the side he faces, top level with his, and
lets it fall. While carried, the thing's object-table room is $FE (no room);
dropped, it is the room it lies in; and its position is saved into the table
when he leaves the room. Room 19 has two things of its own with no table
number, and picking one up writes into a door's record: a bug.

## How it works

- **The pick-up** (`PICK_UP`, $F4F4; X, C or V): only into an empty place.
  He stoops ($956C facing the viewer, $9626 away, by `FACING` with
  `AWAY_FRAMES` = 186). The search box is his own, moved two steps of two
  the way he faces; `FIND_OBSTACLE` and then `PICK_UP_LOOK_ON` ($F52A,
  going on from `NEXT_OBSTACLE`) look through every record it meets for one
  with +12 bit 5. A door ends the search (no door has bit 5).
- **Weight**: the thing's +16 less 16, not below 0, is added to
  `CARRIED_WEIGHT` ($FF92); 8 or more is TOO HEAVY (message 3,
  [`printing.md`](printing.md)) and nothing changes. So the load is at most
  7; the heaviest things weigh 6 (type 8).
- **Taking** (`TAKE_THING`, $F555, the author's WEI3): the place gets the
  record's address, +16 bit 5 (carried) is set and +14 bit 7 (in the air)
  cleared, and the object-table room becomes $FE (`SET_THING_ROOM`, $F4E6,
  the author's ROMM). Then `REDRAW_OBJECT` rubs the thing out, with
  `THIS_RECORD` set to it (from `FOUND_RECORD`, the search's counter) so
  that it is left out, and `SHOW_THING_IN_USE` (the author's INFOR) draws it
  in the panel's box. `THINGS_NOTED` is cleared, so a decoy or book still in
  the room is noted again next pass.
- **The drop** (`DROP_THING`, $F452; CAPS SHIFT or Z): ignored with 46 or
  more records in use. The spot: facing +x, past his own x length; facing
  +z, past his z length; facing -x or -z, the thing's own length short of
  him; its top level with his. The thing's box there is tested
  (`DROP_TEST`, $F498, by `FIND_OBSTACLE` -- still marked carried, it
  misses itself); a hit is BLOCKED (message 1). Otherwise (`DROP_COMMIT`,
  $F4B3): the place emptied, the thing moved there (`ISO_MOVE`), its weight
  taken off, its carried bit cleared, +14 bit 4 with +13 = $12 (one pass
  going up, then it falls like anything else), its table room set to this
  room, and the panel's box cleared (`CLEAR_THING_BOX`, INFO0).
- **Where things are remembered.** `SET_THING_ROOM` finds the thing's
  object-table entry as $A91E + 6 x its number (+19): valid because the
  first 163 entries are six bytes long. Its position is saved separately:
  `SAVE_OBJECT_POSITIONS` ($F906, EEN) copies each record's +6 to +8 into
  its entry when he leaves the room ([`entering-rooms.md`](entering-rooms.md)).
  Carried things' records travel with him: `ROOMST` copies them into the
  first places after his in the next room.

## A bug: room 19's unnumbered things

Room 19's drawing places two things of its own (kind 4, bits 4 and 5 set,
state 3) that are not from the object table and so have no number (+19 =
0). Picking one up, `SET_THING_ROOM` loops 256 times and writes 1536 bytes
on: into byte 2 of the object table's record 214, the x of the door from
room 25 to room 21. *Measured*: standing 10 short of one and pressing X
picks it up and writes $FE there; room 25's door to room 21 is then at x
254, and walking into it no longer leaves the room (before, it took him to
room 21). Dropping the thing would write 19 there instead. Reaching them
without touching them (a touch costs 10 LIFE and they vanish) is the only
difficulty; the search box reaches 4 units past him. The master copy does
not reach record 214, so a new game does not mend it.

It goes further when he leaves a room carrying one (*read*, not run):
carried records come straight after his, before the first door, so
`SAVE_OBJECT_POSITIONS` reaches it, counts 256 entries on from $A921 in the
same way, and writes the thing's x, top and z over bytes 5-7 of record 214
-- the door's destination room, its key and the x he arrives at. A carried
record keeps the place it was picked up at, so the door would lead to a
room numbered by that x (*inferred*).

## How this was found

Read (stage 2, range 4); *measured* in the simulator: the search box, by
placing a thing 8 long at offsets -22 to +18 along x from him (found from -2
to 10); a drop facing +z in room 29, followed pass by pass (it rose 2 and
fell 2 a pass to the floor, x and z unchanged); every room's records
scanned for things that can be picked up with no number (only room 19's
two); the room-19 pick-up and the door tried after it.

## Confidence

All *measured* except the 46-record limit (*read*) and why it exists (open).

## Krumlinde

He agrees on the drop (`DropItem_TestPlacement`, `DropItem_Commit`) and
BLOCKED from it. He puts the drop spot "one item-width in front"; it is the
knight's own length on the sides the axis grows, the thing's on the other
two. He does not identify $F4F4 as the pick-up or the weight limit's
arithmetic; `TAKE_THING` is where his `RTN_Store_Carried_Weight` sits. He
reads $F906 as copying from the table into the records (his
`RTN_Refresh_Shape_Data`); it is the reverse.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `DROP_THING` | (inside $F309) | $F452 | The drop |
| `DROP_TEST` | (inside) | $F498 | Krumlinde's `DropItem_TestPlacement` |
| `DROP_COMMIT` | (inside) | $F4B3 | Krumlinde's `DropItem_Commit` |
| `KNIGHT_DONE` | (inside) | $F4E3 | The author's DOE: the end of his update |
| `SET_THING_ROOM` | `SUBF4E6` | $F4E6 | The author's ROMM |
| `PICK_UP` | `SUBF4F4` | $F4F4 | |
| `PICK_UP_LOOK_ON` | `SUBF52A` | $F52A | |
| `TAKE_THING` | (inside) | $F555 | The author's WEI3 |

## Open questions

- Why the drop is refused with 46 or more records in use (the record area
  holds 43 after the fixed seven: 50 in all).
- Whether the original game ever lets these room-19 things be picked up in
  play (they look like a hazard that also restores LIFE).
- Three short stretches of the drop and the pick-up never ran in the
  sessions ($F488-$F497, $F4C5, $F547; `fairlight-coverage.txt`): read
  only.
