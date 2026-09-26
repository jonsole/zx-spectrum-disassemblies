# Inventory: carrying, picking up and dropping

**Question this answers:** How does the knight pick things up and put them
down, how many can be carried, and why can dropping be used to climb?

**Short answer:** Up to three charms are carried in a queue: the first picked
up is the first dropped. One press of the pick-up/drop control picks up a charm
the player is touching; if there is none, it puts down the oldest carried charm
under the player's feet and lifts the player 12 units onto it -- which is how
charms become steps. Only two special objects can lie in a room (one in the
wizard's room).

## How it works

    handle_pickup_drop ($C00E)       from the player's handler, IX = $5C08
      latch $5BB3 held?  -> wait_pickup_release ($C0A9)
      chk_pickup_drop ($BFFB)        is the control pressed?
      chk_plyr_OOB ($C87A)           inside the room, not in an arch
      +$0C bit 3 clear, bit 2 set    not jumping, standing on something
      do_any_objs_intersect at z+12  -> $5BD3 = 1 if something above the head
      start_pickup_drop ($C041)      click, latch, $5BB4 = 1, player box +4
        try_pickup_loop ($C06F)      records $5C48, $5C68:
          can_pickup_spec_obj ($C172) type $60-$66 and is_on_or_near_obj ($C17A)
            -> pickup_object ($C141)
        find_free_record ($C08C)     a type-0 record among $5C48 (and $5C68
                                     unless in room $88)
          -> room_to_drop ($C0B2) -> place_under_player ($C0DD)
             -> drop_object ($C106) -> adjust_carried ($C12B)
      done_pickup_drop ($C09D)       restore the player's box

**The carried slots**, four of four bytes at $5BD8:

| Offset | Field |
|---|---|
| +0 | type, $60 to $66 (0 = empty) |
| +1 | the object's flags byte (+$07) |
| +2, +3 | address of its entry in the special-object table at $6FF2 |

Slot 0 ($5BD8) is a staging slot, never shown. Slots 1 to 3 ($5BDC, $5BE0,
$5BE4) are drawn on the panel left to right; slot 3 is the next to be dropped.
`adjust_carried` moves slots 0-2 up to 1-3 (LDDR of 12 bytes) and clears slot 0.

- **Picking up.** The player's width, depth and height are each enlarged by 4
  for the test, and the z test lowers the player by 4, so a charm beside the
  player or under the player's feet counts. The charm goes into slot 0, its
  table entry's type byte is zeroed (so leaving the room will not put it
  back), and its record becomes type 1 and is wiped. If three were already
  carried, the oldest (slot 3) is put down in the same record, at the same
  place -- a swap -- otherwise the slots just shift. Picking up clears $5BC0.
- **Dropping.** Needs a free record, nothing within 12 units above the head
  ($5BD3), and something in slot 3. If slot 3 is empty the slots shift anyway,
  bringing the next charm to the drop position. The charm takes the player's
  x, y and z; both player records ($5C08 and $5C28, via IX+$03 and IX+$23)
  are raised by 12, the charm's height (charms are 5 x 5 x 12); it gets the
  player's room, its flags and table pointer back from the slot, and bit 0 of
  +$0D ("just dropped"), which `upd_96_to_102` ($C28B) clears when it settles
  it. In room $88 at z >= $98 the type gets bit 3 set -- see Winning.
- **The control.** `chk_pickup_drop` reads bit 4 of the input byte $5BB5. With
  a joystick and directional control ($5BA4 bits 1-2 non-zero and bit 3 set),
  the stick's down is a direction, so bit 5 is used instead: `finished_input`
  sets it for keys on half-rows $7E (minus SPACE) and $99, i.e. most of the
  keyboard.
- **The panel.** `display_objects` ($BF4E) draws slots 1-3 at x = 16, 40, 64,
  y = 0 using the scratch record at $BFDB, each in a 3-cell by 24-row box
  copied to the screen and coloured from `object_attributes` ($BFD3), indexed
  by type AND $0F. `display_objects_carried` ($BF45) does it each frame only
  when $5BB4 is set.
- **The extra life** (type $67, `upd_103` at $C1AB) is not picked up: touching
  it (player box widened by 1 in x and y) adds a life, prints it, clears its
  table entry and makes it type $6F, which vanishes.
- **A charm lying in a room** (types $60-$66, `upd_96_to_102`) falls under
  gravity and, when it has just been dropped or has moved, has its horizontal
  motion stopped and is redrawn with a click.

Special-object table entry (9 bytes at $6FF2 on), as far as this range needs
it -- read from `find_special_objs_here` ($C525) and `update_special_objs`
($C591): +0 type (0 = not in the world, e.g. carried or used), +5 to +7 x, y,
z, +8 room. +1 to +4 were not worked out.

## How this was found

Read `handle_pickup_drop` through `pickup_object` instruction by instruction,
following IY and the stack (the player's saved sizes, and the slot pointer
pushed before `drop_object`). The slot layout comes from `pickup_object`'s
stores and `drop_object`'s loads. The two-record limit and the $88 exception
from the B=2/B=1 loop and `init_cauldron_bubbles` putting the bubbles at $5C68
in room $88. The bit-5 input from `check_user_input` and `finished_input`.

## Confidence

Read, except: +$0C bit 2 meaning "standing on something" and bit 3 "jumping"
are inferred from `handle_jump` ($C948, sets bit 3 and dZ = 8) and the
collision code clearing bits 0-2 before testing; not traced through every
collision case.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| show_carried_slot | loc_BF91 | $BF91 | Copies one carried object's box to the screen and colours it |
| test_pickup_bit | loc_C00B | $C00B | AND $10 on the chosen input bit |
| start_pickup_drop | loc_C041 | $C041 | Click, latch, enlarge the player, look for a charm |
| try_pickup_loop | loc_C06F | $C06F | Tests the two special-object records |
| find_free_record | loc_C08C | $C08C | Looks for a free record to drop into |
| find_free_record_loop | loc_C093 | $C093 | Its loop |
| wait_pickup_release | loc_C0A9 | $C0A9 | Clears the latch once the key is up |
| place_under_player | loc_C0DD | $C0DD | Puts the charm at the player's feet and lifts the player |
| near_obj_done | loc_C19F | $C19F | Common exit of is_on_or_near_obj |

## Open questions

- $5BC0: set on entering a room to bit 0 of the room number ($D1EF), cleared
  by a pick-up and by collecting the extra life, and while it is non-zero the
  spiked ball (`upd_63`, $B7A9) does nothing. What it stands for is not yet
  worked out.
- Bits of +$07 carried in slot +1 -- which ones matter for a charm (flip?) --
  not worked out.
