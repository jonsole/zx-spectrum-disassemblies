# Movement: a step, gravity, the air, riding and animation

**Question this answers:** once an object's state has chosen a direction,
how is the move made -- how does it fall, jump, ride on something, bounce,
climb a step, and animate?

**Short answer:** every update ends in one shared tail (`ANIMATE_AND_MOVE`,
$F65C): pick the frame, force gravity onto any direction that is not
rising, turn the direction into the axes of a step, try the step against
every other record's box, deal with whatever is in the way, then write the
record back, move its sprite and redraw it. Everything falls two units a
pass until something stops it; falls are straight down; a thing landing on
a moving thing rides it; invisible steps of kinds 2 and 3 lift what walks
into them for three passes.

## How it works

```
a state's case (CHE3D $F1E0, CREATURE_UPDATE $F309) -> C a direction, HL a sprite
  ANIM $F645                 a frame from a run (the author's ANIM)
  SET_SPRITE_AND_MOVE $F677  INPE: the sprite is HL
  MOVE_IN_DIRECTION $F67D    KON6: the sprite left alone
  ADD_GRAVITY $F67E          NOPROP: not rising? no up; add down
  SKIP_GRAVITY $F68C         NOG: the direction into the step's axes (STEP_AXES)
  TRY_STEP $F6B5             STEP_ALL_AXES $FC40; FIND_OBSTACLE $FCA5
     hit -> BUMPED $F7C4:   a door ([`doors.md`](doors.md)), or OBJECTS_MEET $F959
            ([`meeting.md`](meeting.md)) and BLOCKED_MOVE $FA9C, which takes the blocked
            axes out and comes back to TRY_STEP ([`collision.md`](collision.md))
  COMMIT_STEP $F6D2          the state back; ISO_MOVE $E4F7; the air, landing, a bounce
  REDRAW_THIS_OBJECT $F7AA   REDRAW_OBJECT $ECBD
```

The direction byte is in [`object-records.md`](object-records.md): bit 0
turn back, 1 rising, 2/3 -x/+x, 4/5 up/down, 6/7 +z/-z. A step
(`STEP_ALONG_X` $FC07, `STEP_ALONG_Y` $FC1C, `STEP_ALONG_Z` $FC2B) is two
units along one floor axis, or one along each of x and z for a diagonal;
up or down is always two.

**Gravity.** `ADD_GRAVITY`: unless the direction has bit 1, it is ANDed
with `NO_RISE_MASK` ($FF8B, $EF: no up) and ORed with `GRAVITY` ($FF85, $23,
whose bit 5 is down). Both bytes are constants among the variables: the code
never writes them, and a new game restores them from the master copy. So
gravity is not a separate process: it is a down bit on every move, and the
ordinary box test against the floor record, raised floors and furniture
stops it.

**The air.** A step that goes down sets bit 7 of +14 (in the air), +15 = 1,
and keeps only the down bit (and bits 0-1) in +18. While bit 7 is set
`CHE3D` runs no case but carries the object on in the direction +18 holds:
so every fall is straight down, the end of a jump included. The air ends
when the fall is stopped, or when the count in +15 runs out (1 while
falling, 3 for a bounce); and an object that was in the air at the start of
the pass and could not move at all is updated again at once as a grounded
one (`JP CHE3D` at $F793). While the knight falls, `FALL_COUNT` ($FF94)
counts the passes ($F73A); what that costs is in [`knight.md`](knight.md).

**Riding.** When `BLOCKED_MOVE` finds the object landing on one that is
moving (by its own state, or coasting with bit 7 of +14), it sets bit 4 of
the rider's +14 and puts the carrier's direction in `RIDE_DIRECTION`
($FFFF); `COMMIT_STEP` copies it into the rider's +13 ($F70D), and the next
pass moves the rider with it (state 0's case, and the knight's, $F418).

**Climbing.** A step stopped along x by a kind-3 object, or along z by a
kind-2 one, sets bit 6 of `STEP_AXES`: `COMMIT_STEP` then gives the mover
bit 7 of +14, +15 = 3 and +18 = $12 (up, rising) -- three passes going up.
Those objects are the invisible steps of staircases, all placed by rooms'
drawings (kind 2 in rooms 53-55, 57-60, 64-67 and 77, kind 3 in rooms 2, 27 and 34).

**The knight's screen position.** On every committed step his record is
first put back to one fixed floor point (50, 78, 50) and its screen
position there, and `ISO_MOVE` moves him from that; everything else is
moved from where it was ([`projection.md`](projection.md)).

**The first pass in a room** (bit 2 of `GAME_FLAGS`, set by the room's entry
and cleared by `MAIN_LOOP`): the direction is cleared but all three axis
bits are set, so the box test runs on a box one unit up x, two down and one
down z from where the object is, and whatever it meets is dealt with as
usual; the record is then only drawn.

**Animation** (`ANIM`, $F645): +17 holds the frame (bits 0-2), the last
frame (bits 3-5) and bit 7 while going back; the frame shown is HL + DE x
the frame. The run goes forward to the last and then back, but it goes back
by jumping to frame 1: a run of three goes 0, 1, 2, 1, 0, 1, 2 ...; of four
0, 1, 2, 3, 1, 0; of two 0, 1, 1, 0. Every run the game sets up is three
frames (+17 = $10 from the templates for states 4-10, and the knight's).

## How this was found

Read (stage 2, range 4) from $F645 to $F7AF, with the collision code (range
5). *Measured* in the simulator: the knight's jump and fall in room 29 (his
top from 78 to 94 in 8 passes and back, 2 a pass along z while rising, none
while falling -- falls are straight down); `ANIM` called directly on a
scratch record for runs of two, three and four; the drop's one pass up and
fall to the floor ([`carrying.md`](carrying.md)).

## Confidence

The tail, gravity and the air: *read*, with the jump, the fall and the
animation order *measured*. That the knight alone is re-projected because
the conversion rounds is *inferred*. Riding and climbing: *read*.

## Krumlinde

He places this code in the main loop's object handling but labels it
`Sub_...` throughout. His note that no code makes things fall ("no
unconditional per-tick Z decrement") misses `ADD_GRAVITY`: gravity is the
constant down bit ORed into every direction that is not rising, applied by
the ordinary step. That also answers his open question of how floors hold
things up: the floor is record 1, patched per room
([`object-records.md`](object-records.md)).

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `ANIM` | (inside $F595) | $F645 | The author's ANIM |
| `ANIMATE_AND_MOVE` | `SUBF65C` | $F65C | The rest of ANIM, then the shared tail |
| `SET_SPRITE_AND_MOVE` | (inside) | $F677 | The author's INPE |
| `MOVE_IN_DIRECTION` | (inside) | $F67D | The author's KON6 |
| `ADD_GRAVITY` | (inside) | $F67E | The author's NOPROP |
| `SKIP_GRAVITY` | (inside) | $F68C | The author's NOG |
| `TRY_STEP` | (inside) | $F6B5 | Step and test |
| `COMMIT_STEP` | (inside) | $F6D2 | Write the step back |
| `REDRAW_THIS_OBJECT` | (inside) | $F7AA | Into `REDRAW_OBJECT` |
| `WORKING_POSITION` | `SUBF7B0` | $F7B0 | The author's BUT |
| `WORKING_SIZES` | `SUBF7BA` | $F7BA | The author's BUT2 |
| `STEP_ALONG_X`, `_Y`, `_Z` | `SUBFC07`, `SUBFC1C`, `SUBFC2B` | $FC07-$FC3F | One axis of a step |
| `STEP_ALL_AXES` | `SUBFC40` | $FC40 | All three |

## Open questions

- What the offset box on a room's first pass is for.
- Why a diagonal step is one unit on each floor axis but a vertical step
  always two.
