# Special objects

**Question this answers:** How are the collectable objects placed at the start of
a game, and how does the game keep track of them as they are moved, carried and
used?

**Short answer:** A fixed table of 32 places ($6FF2, nine bytes each) is given
objects in rotation -- kinds 96 to 103, four of each -- starting from a random
kind, so the same places hold different things each game. Entering a room
copies the objects whose current room matches into object records 2 and 3;
leaving it writes their positions back through a pointer the record carries.
Collecting an object zeroes its table type.

## How it works

```
AF88 set up and play -> init_special_objects ($C47E) -> init_obj_loop ($C489) x32
game_loop -> build_screen_objects ($D1E6)
   bit 0 of $5BB2 set? -> update_special_objs ($C591)   write records 2,3 back
   loc_D1EF -> retrieve_screen (room's own objects from $5C88)
            -> find_special_objs_here ($C525)             records 2,3 from the table
```

The table at $6FF2, 32 entries of 9 bytes, ending where the sprite table starts
at $7112:

| Offset | Field |
|---|---|
| +0 | type, 96 to 103; 0 once collected (pickup_object and add_obj_to_cauldron zero it) |
| +1..+4 | starting x, y, z, room (fixed data) |
| +5..+8 | current x, y, z, room (copied from +1..+4 at game start, written back on leaving a room) |

init_special_objects: kind = ($5BA0 + R) at the start, then type = $60 + (kind
AND 7) and kind + 1 for each entry. So consecutive entries get consecutive
kinds, and each of the eight appears four times. The 32 starting rooms are all
different.

Kinds: 96 to 102 are the seven things the cauldron needs (objects_required at
$C27D gives the order, compared against type AND 7); 103 gives an extra life
when touched (upd_103, $C1AB, increments $5BBA). can_pickup_spec_obj ($C172)
accepts only 96 to 102.

An object record built by find_special_objs_here (records 2 and 3, $5C48 and
$5C68):

| Offset | Value |
|---|---|
| +$00 | type from the table |
| +$01..+$03 | x, y, z from the table's current position |
| +$04..+$06 | 5, 5, 12 (size; drop_object at $C106 uses the same) |
| +$07 | $14: bit 4 draw, bit 2 pushable (the collision code copies a pusher's velocity into a record with this bit) |
| +$08 | room |
| +$09..+$0F | 0 |
| +$10/+$11 | address of the table entry |
| +$12..+$1F | 0 |

The scan keeps its output pointer in the alternate register set (EXX) so that B
can hold the room and DE the table step at the same time. Unused parts of
records 2 and 3 are cleared 32 bytes at a time until the pointer reaches $5C88.

update_special_objs writes type, x, y, z and room back for each of records 2
and 3 that is non-empty. It is skipped on the first room build of a game (bit 0
of $5BB2 is set only once end_of_frame has run).

## How this was found

Read $C47E-$C4A9, $C525-$C5C7 and their callers (loc_D1EF, build_screen_objects,
pickup_object, drop_object, add_obj_to_cauldron, upd_103). Counted the entries
from the bounds of the loop ($6FF2 to $7112 is 288 bytes = 32 x 9) and checked
the starting rooms in the listing for duplicates (none).

## Confidence

Read. The only inference is that records 2 and 3 are reserved for special
objects throughout; the code here only fills and clears those two, and the
cauldron-bubbles routine at $B8A9 borrows record 3 when it is empty.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| find_spec_obj_loop | loc_C530 | $C530 | test one table entry and build its record |
| next_spec_obj_slot | loc_C572 | $C572 | nine bytes on |
| clear_spare_spec_records | loc_C583 | $C583 | zero what is left of records 2 and 3 |
| save_spec_obj_loop | loc_C595 | $C595 | write one record back to the table |
| save_spec_obj_next | loc_C5B7 | $C5B7 | next record |
| fill_window_row | loc_C518 | $C518 | (fill_window's row loop) |
| fill_window_byte | loc_C51A | $C51A | (fill_window's byte loop) |

## Open questions

- The existing annotation on $6FF2 in knightlore_annotations.ctl says "#R$B2CF
  picks a set from this table"; $B2CF is play_audio. The table is filled by
  init_special_objects ($C47E) and its layout is the one above -- whoever owns
  $6FF2 should correct it.
- If three special objects ever share a room, find_special_objs_here would
  overwrite record 4 and clear_spare_spec_records would never reach $5C88
  exactly. How the drop code prevents a third was not checked here.
- The cauldron bubbles, when placed in record 3, have zero at +$10/+$11, so
  update_special_objs would write into $0000-$0008 (ROM, harmless) if it saw
  them on leaving the room. Not tested.
- update_special_objs copies the type back too, so an extra-life object that
  has turned into type 111 (upd_103 sets bit 3) would have 111 written into
  its entry if the record were still live when the room is left. Whether that
  can happen was not followed.
