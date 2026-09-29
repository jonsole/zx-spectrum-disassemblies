# Collision

**Question this answers:** how the game decides a move is blocked, what it
does about it, and what pushing is.

**Short answer:** every object is a box, a corner and three lengths. A move
is tried whole; if the box would overlap another record's
(`FIND_OBSTACLE`, $FCA5, from the last record in use down to the room's
floor and walls), the meeting is settled first ([`meeting.md`](meeting.md)),
and then `BLOCKED_MOVE` ($FA9C) tries each axis and each pair of axes alone
against that one object, takes out of the move whatever collides, turns
the mover round or stops it on those axes, notes a landing, a ride or a
climb, and may push the other; what is left of the move is tried again.

## How it works

**The box.** x from +6 for the length +9, z from +8 for +11, y (the height)
from +7 down for +10. Two boxes overlap when they overlap along all three
axes, each test strict, so boxes that only touch do not (`BOX_OVERLAP`,
$FCF2, the author's BB2; each axis that does not overlap returns at once).

**`FIND_OBSTACLE`** ($FCA5): IX from `FREE_RECORD` back one record at a
time (DE' is minus 20 -- the `LD DE,$FFEC` is a constant, not the variable
at $FFEC), counting `OBJECT_COUNT` down in `FOUND_RECORD` ($FFF8, the
author's T+20), testing each with `TEST_ONE_RECORD` ($FCDC): not the
mover's own record (`FOUND_RECORD` equal to `THIS_RECORD`), and not a hidden
one (+16 bit 5) unless it is a door. Carry and IX on the first hit. The six
fixed records at the bottom of the walk are the floor, ceiling and walls
([`object-records.md`](object-records.md)), which is how things stay in the
room and on the floor. `NEXT_OBSTACLE` ($FCD1) goes on from where it
stopped, for the pick-up ([`carrying.md`](carrying.md)). On the way it deals
out the strike counters ([`meeting.md`](meeting.md)).

**`BLOCKED_MOVE`**, against the one object IX only, from the mover's old
place (`TEST_OTHER`, $FC9C):

- x alone, y alone, z alone. A colliding axis is dropped from the move and
  the mover's direction on it is reversed (if it turns back, bit 0) or
  cleared. Along x into a kind-3 object, or along z into a kind-2 one, sets
  bit 6 of `STEP_AXES`, a climb ([`movement.md`](movement.md)). Down onto
  the other sets bit 5, landed; and if the other is moving by its own state
  or coasting, the mover rides it (bit 4 of its +14; the other's +13, or +18
  if coasting, into `RIDE_DIRECTION`).
- Then the pairs: x with y colliding drops y; x with z drops both; y with
  z drops y. If all three are still in the move after that, only the whole
  diagonal collides, and none of it is made.
- `STEP_AXES` becomes what is left, the landing and door bits dropped.
- **A push**: unless it landed or the other is a door, and unless the other
  is still (+16 bits 0-4 clear), the other is pushed if its +16 is no more
  than 5 above the mover's: it coasts (bit 7 of +14) for the mover's +16
  less its own, plus 6, passes (+15), heading (+18) the way the mover asked
  to go (`ASKED_DIRECTION`, $FFFC, the direction before any collision),
  keeping its own bits 0 and 1. The knight's +16 is 18, so he pushes
  anything whose +16 is 23 or less -- weight 7 or less.
- `JP TRY_STEP` ($F6B5): what is left is tried again, and may meet
  something else and come back here.

## How this was found

Read (stage 2, range 5). The fixed records' values collected in every room
by the census (19 layouts; floors at 50 but rooms 9 and 12, at 10). The
step objects -- kind 2 and 3, no sprite, heights rising by 2 to 4 in a row
-- seen among room 2's records. The pick-up's search box *measured*
([`carrying.md`](carrying.md)), which confirms the corner-and-lengths box.

## Confidence

The box test, the order of the axis tests, turning back, climbing, riding
and pushing: *read*. The fixed records as floor, ceiling and walls:
*measured* in every room, and *read* from `PATCH_RECORDS`. Gravity: *read*.

## Krumlinde

His `RTN_Test_Move_Blocked` and `Collision_TestOneObject` agree on what
they test. What he reads as an "asymmetric" box is the corner-and-lengths
box above, not a centre and half-extents. He says the collision objects
cannot be what keeps the knight on a floor and leaves floors open: the six
fixed records and the gravity constants answer it. His source writes the
minus-20 step as `ld de,Sub_FFEC`, as though it were a variable (it
assembles the same); the listing now keeps it a number (`@ keep`).

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `MEET_DECOY` | `SUBFA83` | $FA83 | The last meeting case; `BLOCKED_MOVE` ($FA9C) inside |
| `TEST_OTHER` | `SUBFC9C` | $FC9C | The moved box against IX only |
| `FIND_OBSTACLE` | `SUBFCA5` | $FCA5 | The first record overlapping a box |
| `NEXT_OBSTACLE` | (entry) | $FCD1 | Go on with that search |
| `TEST_ONE_RECORD` | `SUBFCDC` | $FCDC | One record, unless its own or hidden |
| `BOX_OVERLAP` | (entry) | $FCF2 | The box test (the author's BB2) |

## Open questions

- Whether the "all three axes" case ever happens in play.
- Four short branches of `BLOCKED_MOVE` never ran in the sessions ($FB5D,
  $FB86, $FBAD, two bytes each) and nor did $FCCA in `FIND_OBSTACLE`
  (`fairlight-coverage.txt`): read only.
