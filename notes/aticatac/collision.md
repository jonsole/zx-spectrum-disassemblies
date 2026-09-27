# Collision

**Question this answers:** what stops the player walking, how doorways let
him out of the room, and how contact between the player, creatures, objects
and the weapon is decided.

**Short answer:** there are no masks or maps. The player may step anywhere
inside the room's walk rectangle; a step outside it is allowed only into a
doorway's box (unless the door is shut), and a step into a table's box is
refused. Everything else is a distance test: 12 pixels each way between the
player and a creature, food, a collectable or a mushroom, and between the
weapon and a creature; and a box anchored at a door's corner for going
through it.

## How it works

**The player's step** (`MOVE_PLAYER` $8D77, *read*). Before each frame's
move, bits 4 and 5 of the player's +$02 are set, meaning "do not apply x" and
"do not apply y". Then, for the proposed x (with the old y) and the proposed
y (with the old x) separately:

1. `TEST_STEP_IN_ROOM` ($8FCA) / `ALLOW_IF_IN_ROOM` ($8FE9): if the point is
   strictly inside the walk rectangle -- |x - $58| below `ROOM_HALF_WIDTH` and
   |y - $68| below `ROOM_HALF_HEIGHT` -- clear the bit.
2. `TEST_STEP_BOXES` ($900A) calls `TEST_ROOM_BOXES` ($902B), which walks the
   room's list of door and furniture halves. Each has a box in +$06 and +$07:
   per axis, an offset (bits 7-4, as a signed multiple of 4) from the record's
   own x or y and a size (bits 3-0, times 4); the box runs rightwards from
   x + offset and upwards from y + offset. If the point is inside the box:
   - +$05 bit 3 set (a shut door): ignored;
   - bit 2 set (solid): set the bit -- the step is refused even inside the
     room;
   - otherwise (a doorway): clear the bit -- the step is allowed even outside
     the rectangle.
3. `APPLY_HEADING` ($8F66) adds the step on the axes whose bit is clear.

In the template only the tables (type $12, 22 halves) are solid; the doors'
boxes are 16-28 pixels long and reach from inside the room out through the
wall, and most other furniture has a box of size zero, which is nothing
(*measured* from the template). So a shut door is a wall; an open one is a
channel out of the rectangle to the door's own trigger box.

`CHECK_IN_DOORWAY` ($957D) records whether the player's current position is
outside the rectangle on either axis, in `IN_DOORWAY` ($5E2D): no firing
from a doorway, and an open timed door will not shut on the player
([`doors.md`](doors.md)).

**Creatures** (*read*) do none of this: `STEP_ACTOR` ($84CD) keeps them inside
the rectangle (big monsters a slightly smaller one), reversing a velocity
that would leave it. Furniture and doors mean nothing to them.

**Contact tests** (*read*):

| Test | Between | Box | Extra conditions |
|---|---|---|---|
| `CHECK_HIT` $85B2 | a creature and the player | \|dx\| < 12, \|dy\| < 12 | same room; the player in play ($01-$30). Sets the player's +$02 to 1 and starts sound $64 |
| `CHECK_SHOT_HIT` $8566 | a creature and the weapon | the same | same room; a weapon in flight. Sets the weapon's hit flag |
| `NEAR_PLAYER` $90FB | food, a collectable, a mushroom and the player | the same | none -- `PICK_UP` adds its own in-play test, food and mushrooms do not |
| `PLAYER_AT_DOOR` $90CC | a door and the player | 0 <= x - door x < C, 0 <= door y - y < B, the tolerance halved across the door | the player in play; low nibble of +$02 clear |

Door tolerances (C across, B down, then one halved): 17 x 17 for ordinary
doors, so 17 x 8 in a top or bottom wall and 8 x 17 in a side wall; 32 x 32
for big doors; 24 x 24 for trapdoors; 32 x 48 for the A.C.G. door, which is
in an east wall and so becomes 16 x 48 (*read* from the BC each handler
passes).

## How this was found

`TEST_ROOM_BOXES`, then called `POPULATE_ROOM`, looked by that name and its first lines like a room set-up
routine; following its callers showed only `TEST_STEP_BOXES`, called twice a
frame from `MOVE_PLAYER` with $10 and $20 in A' -- the two "do not apply"
bits. The box fields were decoded from the SRA/RLCA arithmetic and checked
against the template's door and table records in the snapshot.

## Confidence

*Read*, with the box sizes *measured* from the data. Walking into a table was
not tried in the simulator.

## Renamed routines

Applied to the annotations on 2026-09-27; the build verified byte for byte.

| New name | Old name | Address | Role |
|---|---|---|---|
| `TEST_ROOM_BOXES` | `POPULATE_ROOM` | $902B | doorway and table boxes for one axis of the player's step |
| `TEST_STEP_BOXES` | `STEP_AND_TEST_2` | $900A | calls it for x and for y |
| `TEST_STEP_IN_ROOM` | `STEP_AND_TEST` | $8FCA | the walk rectangle for x and for y |
| `ALLOW_IF_IN_ROOM` | `DISTANCE_FROM_CENTRE` | $8FE9 | clears the permission bit inside the rectangle |
| `CHECK_IN_DOORWAY` | `WITHIN_ROOM_BOUNDS` | $957D | sets `IN_DOORWAY` |
| `IN_DOORWAY` (equate) | `FIRE_BLOCKED` | $5E2D | the player is outside the walk rectangle |
## Disassembly corrections

All applied to the annotations, the ref and the build on 2026-09-27 (the old names are used below), except where marked.

- `POPULATE_ROOM`: "Set up the records that belong to a room ... walks the
  list ... when the room is set up", with the "door pairing" check explained
  as choosing the room's half. The walk and the half-choosing are right, but
  the routine's purpose is the player's collision against doorways and
  tables; it is called twice every frame and sets up nothing. The ref's
  "What is in a room" says the same wrong thing.
- `STEP_AND_TEST`: "the check that stops a creature walking through a wall"
  and `STEP_AND_TEST_2` "differing in which axis leads": both are the
  player's, and they are different tests (the rectangle; the boxes).
- `STEP_AND_TEST` "runs a sixteen-iteration loop": the $10 in B is bit 4 of
  the flags, not a count.
- `DISTANCE_FROM_CENTRE` "The same test MOVE_ACTOR makes inline": it also
  clears a permission bit in +$02, which `MOVE_ACTOR` does not.

## Open questions

- Whether any furniture besides tables is solid in the running game (a
  handler could set bit 2; none was seen to).
