# Collisions

**Question this answers:** How does a move get stopped by the walls, the floor
and other objects, and what counts as solid?

**Short answer:** `adj_for_out_of_bounds` ($CB45) takes an object's dX, dY, dZ and
shortens each, one axis at a time (Z, then X, then Y), one unit at a time, until
the box no longer ends up in the floor, a wall or another object's box. Every
non-empty record not flagged "ignore" (+$07 bit 1) is solid. Contact also passes
harm between objects, pushes pushable ones and lets a carried object ride what it
stands on.

## How it works

```
adj_for_out_of_bounds ($CB45)       IX = mover; skip if +$07 bit 1; set it (ignore self)
  clear +$0C bits 0-2
  H = dZ: adj_dZ_for_out_of_bounds ($CA5A, floor)  then adj_dZ_for_obj_intersect ($CC38)
  C = dX: adj_dX_for_out_of_bounds ($CCDD, walls)  then adj_dX_for_obj_intersect ($CB9A)
  L = dY: adj_dY_for_out_of_bounds ($CD08, walls)  then adj_dY_for_obj_intersect ($CBE9)
  store C, L, H; clear +$07 bit 1   (store_clipped_move, $CB8C)
```

Each axis uses the moves already accepted on the earlier ones and zero for the
later ones. So the Z test is made on the object's current footprint, and a
diagonal move into a wall keeps the component along it (sliding).

**The box test on each axis** (`do_objs_intersect_on_x/y/z`, also used by $B510
and `is_on_or_near_obj` $C17A):

- X: overlap if |X + dX - X'| < w + w' (half-widths at +$04). Y the same with +$05.
  Exactly touching is not overlapping.
- Z: Z is the base and +$06 the full height, so the test is
  |Z + dZ - Z'| < height of the lower of the two.

**How a move is shortened.** `shorten_delta` ($CA89) steps A one unit towards
zero and sets Z when nothing is left. Each clip loop re-tests after every step;
the object scans re-test the same obstacle until clear, then go on to the next,
and stop the whole scan once the delta is zero. Cost is proportional to the
overlap, not a single subtraction.

**Room bounds.** Floor only in Z: Z + dZ must stay >= $5BAE ($80 in all three
room sizes); no ceiling. In X and Y the footprint must stay strictly inside
$80 +- the half-size ($5BAB, $5BAC). The wall clip is skipped during the
room-entry walk (+$0C top nibble) and when an archway has flagged the object as
near (+$07 bit 0) -- that is how the player gets into an arch at all; the arch's
pillars, being objects, still stop him.

**What happens on contact** (object scans only):

| Effect | Rule |
|---|---|
| stopped | mover's +$0C bit 0/1/2 for X/Y/Z |
| harm | obstacle +$0D bit 6 |= mover bit 7; mover bit 6 |= obstacle bit 5 |
| pushed (X, Y) | if obstacle +$07 bit 2, obstacle's dX/dY = mover's whole intended dX/dY |
| landed on (Z) | obstacle +$0D bit 3 set (up or down); `upd_91` ($B683) waits for it |
| carried (Z) | if mover +$07 bit 2, mover's zero dX/dY take the obstacle's |

Bit 6 of +$0D is what `upd_player_bottom` and `upd_player_top` die of. The
portcullis (`upd_9`, $C6BD) sets bit 7 on itself, so it harms what it comes down
on.

## Pushing, tested

The collision code only *copies* the pusher's dX or dY into an obstacle that
has +$07 bit 2 set; the obstacle moves when its own handler runs, later in the
same frame's object walk (the player is record 0, so always first). What
happens then is up to the handler:

| Object | Handler | What a push does |
|---|---|---|
| table (84) | moves by its velocity, *then* clears it (`dec_dZ_upd_XYZ_wipe_if_moving`) | one step per frame of contact, stops when the pushing stops |
| chest (85) | moves by its velocity and keeps it | read: slides on; not tested |
| "moveable" block (62) | clears its velocity *before* moving (`upd_62`) | nothing: the push is always cancelled |

*Watched* in room $8E with the ghost removed: a table placed in the player's
path was pushed from x 157 to 129 in 20 frames of walking into it, and stayed
at 129 when he stopped. The same table with its type changed to $3E (62) did
not move at all in 20 frames, and the player stopped against it. So the block
called moveable cannot be moved; whether that was intended is not known.

## How this was found

Read $CB45-$CD32 and the callers `move_player_apply` ($C9CD) and
`dec_dZ_and_update_XYZ` ($C700); `is_object_not_ignored` ($B538) for what is
skipped; the rotate-and-mask sequence at $CBB8 worked through bit by bit;
grepped the listing for writes to +$0D bits 3, 6, 7.

## Confidence

The mechanics are read. The names "harms what it runs into / what runs into it"
for bits 7 and 5 are inferred from the transfer rule plus the portcullis setting
bit 7; nothing in the listing sets bit 5 with a SET instruction, so it presumably
comes from object data -- not traced.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| shorten_delta | adj_d_for_out_of_bounds | $CA89 | steps a delta towards zero; used by every clip loop, objects as well as bounds, and checks no bounds itself |
| shorten_delta_dec | loc_CA90 | $CA90 | its DEC |
| clip_dZ_to_floor | loc_CA5E | $CA5E | floor loop |
| dX_done | loc_CB7B | $CB7B | the Y stage of adj_for_out_of_bounds |
| store_clipped_move | loc_CB8C | $CB8C | write back |
| dX_obj_loop / dY_obj_loop / dZ_obj_loop | loc_CBA0 / loc_CBEF / loc_CC3E | | in line on the other two axes? |
| dX_obj_hit_test / dY_obj_hit_test / dZ_obj_hit_test | loc_CBAF / loc_CBFE / loc_CC4D | | overlap on this axis, and its effects |
| dX_obj_shorten / dY_obj_shorten / dZ_obj_shorten | loc_CBD9 / loc_CC28 / loc_CC8D | | shorten and retry |
| dX_obj_next / dY_obj_next / dZ_obj_next | loc_CBE1 / loc_CC30 / loc_CC95 | | next record |
| dZ_ride_dY | loc_CC81 | $CC81 | carried in Y |
| intersect_x_result / intersect_y_result / intersect_z_result | loc_CCB0 / loc_CCC5 / loc_CCD6 | | the compare |
| intersect_z_above | loc_CCD8 | $CCD8 | other object is lower |
| clip_dX_to_walls / clip_dX_test | loc_CCEC / loc_CCF6 | | wall loop, X |
| clip_dY_to_walls / clip_dY_test | loc_CD17 / loc_CD21 | | wall loop, Y |

`adj_for_out_of_bounds` keeps its name, though it handles objects as well as
bounds.

## Open questions

- Where bit 5 of +$0D (and bit 7 on hazards other than the portcullis) comes from.
- Whether the player ever has +$0D bit 7 (it would harm what it walks into).
- The high nibble of +$0C is the room-entry countdown for the player; whether any
  other object type uses those bits (and so escapes the wall clip) is not
  checked.
