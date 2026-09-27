# Picking up and putting down

**Question this answers:** what the pick-up key does, what can be carried,
and how carried things are kept.

**Short answer:** `TAKE_OR_LEAVE` ($BF79), every turn from the legs' routine:
one press picks up the bucket or a collectable he is on or beside; failing
that, puts down the oldest thing he carries, under himself, lifting him 12
onto it; and if there is nothing in the oldest slot, moves what he carries one
place along. He carries three, first in first out, and the panel shows them.

## How it works

- **One press, one action**: `TAKE_HELD` ($A740) latches the key;
  `WAIT_TAKE_RELEASE` ($C00E) clears it when the key is up.
- **Only** inside the room's walls (`CHK_PLYR_OOB` $C4A3 -- not in a
  doorway), not jumping (+$0C bit 3) and standing on something (+$0C bit 2).
- **Headroom**: his Z is raised by 12 and `DO_ANY_OBJS_INTERSECT` ($BF1B)
  asked whether anything overlaps him; if so `NO_HEADROOM` ($A741) is set and
  nothing will be put down.
- **Looking**: his half-sizes are enlarged by 4 (restored at `TAKE_DONE`
  $BFFC) and the 48 room records searched with `CAN_PICK_UP` ($C0D4): graphic
  90 (the bucket) or 144-148 (the collectables), overlapping in U and V, and in
  Z with him 4 lower, so that a thing he stands on counts.
- **Picking up** (`PICK_UP` $C0A7): the graphic, the flags and the quest-record
  link go into `CARRIED` ($A722), a staging slot in front of the three; the
  quest record's graphic is zeroed (it is carried, in no room); the object is
  marked (`SET_WIPE_AND_DRAW_IY` $BF56) and made graphic 1, which the drawing
  code rubs out and empties. Then `SHIFT_CARRIED` ($C091) moves the twelve
  bytes from $A722 up by four and clears the front slot. With three already
  carried, the oldest falls out of `CARRIED_LAST` into the same record in the
  same press: a swap (*read*; not run).
- **Putting down** (`PUT_DOWN` $C017), when there is nothing to take: into the
  first empty room record, the graphic from `CARRIED_LAST` ($A72E) and the rest
  of his legs' record; both his records are lifted 12; the thing is let fall a
  turn; `FILL_PUT_DOWN` ($C061) gives it half-sizes 5, 5, 12, the slot's flags,
  his room and the quest-record link, writes the graphic back into the quest
  record, and sets bit 0 of its +$0D (which nothing reads).
- **Nothing to put down**: `SHIFT_CARRIED` alone, so repeated presses walk
  what he carries along to the last slot.
- Every press that gets past the checks sets `PANEL_DUE` ($A720) and starts
  sound effect 1, five notes (`SOUND_COUNT` $A749).

| Address | Label | Slot |
|---|---|---|
| $A722 | `CARRIED` | staging: a thing just picked up, empty between presses |
| $A726, $A72A | `CARRIED_SHOWN` | the newest two; the panel's first two boxes |
| $A72E | `CARRIED_LAST` | the oldest, put down next; the panel's third box |

Each slot is four bytes: the graphic, the flags from +$07, and the address of
the thing's record in `QUEST_RECORDS` ([`quest-records.md`](quest-records.md)).
Only quest things can be carried, so every carried thing has one.

## How this was found

Read against Knight Lore's `handle_pickup_drop` and the routines after it,
which Pentagram joins into one (stage 2, range 3); readers of bit 0 of +$0D
were looked for through every `(IX+$0D)` and `(IY+$0D)` in the listing. The
build's quest session measured the pick-up of the bucket, the shuffle along
the slots (three presses to bring it to `CARRIED_LAST`) and the put-down in
room 122 ([`driving.md`](driving.md)).

## Confidence

*Read*; the pick-up of the bucket, the shuffle and the put-down *measured*
by the build's quest session. The swap with three carried and the
no-headroom branch never ran in the sessions (`pentagram-coverage.txt`).

## Knight Lore

The same design: the latch, inside the walls, standing, the headroom, the
enlarged box, a queue of three with a staging slot
([`../knightlore/inventory.md`](../knightlore/inventory.md)). Knight Lore
searches its two special-object records; Pentagram all 48 room records.
Knight Lore has a cauldron case in the drop; Pentagram none. Knight Lore sets
bit 0 of +$0D ("just dropped") on a charm put down and its charms' routine
clears it when the charm settles; Pentagram sets it and nothing touches it
again.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `DO_ANY_OBJS_INTERSECT` | `SUBBF1B` | $BF1B | does IX overlap anything? |
| `SET_WIPE_AND_DRAW_IY` | `SUBBF56` | $BF56 | mark IY to be redrawn |
| `TAKE_DONE`, `WAIT_TAKE_RELEASE`, `PUT_DOWN`, `FILL_PUT_DOWN`, `SHIFT_CARRIED`, `PICK_UP` | (entry points) | $BFFC-$C0A7 | parts of `TAKE_OR_LEAVE` |
| `CAN_PICK_UP` | `SUBC0D4` | $C0D4 | the bucket or a collectable, touching |
| `CLEAR_COPY_BITS` | `SUBBF0D` | $BF0D | clear bit 5 of every record's flags |

## Open questions

- A thing put down gets its turn's fall with the player's enlarged
  half-sizes still in its record (5, 5, 12 are set only after). Whether that
  has any effect was not looked for.
