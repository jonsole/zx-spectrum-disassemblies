# Ghosts

**Question this answers:** How does a ghost move and choose its sprite?

**Short answer:** A ghost (types 80 to 83) drifts on a diagonal at 3 or 4 units
a frame on each axis, picks a new random diagonal whenever it has no speed or
bumps into something across the floor, faces the way it is going using two
views and a mirror bit, and is deadly both to what it moves into and to what
moves into it.

## How it works

```
upd_80_to_83 ($C5C8)
   adj_m6_m12; dec_dZ_and_update_XYZ (gravity, collision, move)
   dx|dy == 0 or +$0C bits 0/1 (blocked in x or y)?
       ghost_new_direction ($C5DD)
          dx = delta_tbl[4 + (seed AND 3)]      -3, +3, -4, +4
          dy = delta_tbl[4 + (frame AND 3)]
          calc_ghost_sprite ($C603); sound (pitch from x+y+z)
   ghost_animate ($C5FD): type XOR 1 (two-frame animation), deadly bits 7 and 5
                          of +$0D, wipe and redraw
```

calc_ghost_sprite: whichever of |dx| and |dy| is larger decides.

| Mostly | Sign | Type bit 1 | Mirrored (+$07 bit 6) |
|---|---|---|---|
| x | + | 0 | yes |
| x | - | 1 | yes |
| y | + | 1 | no |
| y | - | 0 | no |

Ties (|dx| = |dy|) count as mostly y. Ghosts in the room data start as type 82
with no velocity, so the first frame always picks a direction.

delta_tbl ($C64E) holds 16 bytes, -1/+1 up to -8/+8, of which only entries 4 to
7 are ever read (get_delta_from_tbl has one caller).

## How this was found

Read $C5C8-$C65D; the ghost record's type from the block-type entry `ghost` at
$6BD1's table; the meaning of +$0C bits 0-2 from adj_for_out_of_bounds's SETs;
the deadly bits from the collision code at $CBAF and $CBFE (bit 7 of the mover
becomes bit 6 of what it hits; bit 5 of what is hit becomes bit 6 of the mover).

## Confidence

Read. "Deadly both ways" rests on reading the bit transfer at $CBAF, not on
testing.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| ghost_new_direction | loc_C5DD | $C5DD | random diagonal |
| ghost_animate | loc_C5FD | $C5FD | swap frame, set deadly and draw flags |
| ghost_abs_dy | loc_C60C | $C60C | size of dy |
| ghost_pick_view | loc_C616 | $C616 | mostly x or mostly y |
| ghost_x_negative | loc_C629 | $C629 | moving towards -x |
| ghost_mostly_y | loc_C62F | $C62F | moving mostly along y |
| ghost_y_negative | loc_C63F | $C63F | moving towards -y |

## Open questions

- Which view (bit 1 of the type) is the front and which the back was not
  looked at in the sprites.
