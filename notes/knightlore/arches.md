# Arches and drawing offsets

**Question this answers:** How does the game decide the player is in a doorway,
why does the knight slide into line with arches, and what are the many adj_
routines?

**Short answer:** Each arch is two pillar objects; the first pillar (type 2, or
4 for a tree arch) stores the doorway's middle in its own unused velocity
fields and each frame marks the player as allowed to leave (bit 0 of +$07) if he
is within 6 across and 15 along the doorway, and nudges him one unit towards the
centre line if he is within 15 either way. The adj_ and offset-only upd_
routines just store a pixel offset at +$12/+$13 that lines the sprite up with
the object's position.

## How it works

```
upd_2_4 ($C73C)   first pillar
   mirrored (N/S wall)? adj_2_4_hflip ($C76C): middle = (x-13, y), limits x 6, y 15
   else                 arch_ew_doorway ($C74C): middle = (x, y+13), limits x 15, y 6
   arch_check_doorway ($C760): middle z = pillar z
      chk_plyr_spec_near_arch ($C7DB): records 0-3 with +$07 bit 3 and near -> +$07 bit 0
      arch_nudge_to_centre ($C785): limits 15,15; near -> via lookup_plyr_dXY on the ARCH
           -> adj_ew ($C7B1): +$0F = +/-1 towards middle y
           -> adj_ns ($C7C4): +$0E = +/-1 towards middle x
upd_3_5 ($C722)   second pillar: drawing offset only
is_near_to ($C7FE): carry if |dx| < L, |dy| < H, |dz| < 4 (point in IX+9..B, object at IY+1..3)
```

Only the player's two records have bit 3 of +$07 ($1C and $1E in
plyr_spr_init_data), so in practice only the player is affected. The nudges
are added to the player's velocity by calc_plyr_dXY ($C9FB) when he next moves,
and bit 0 of +$07 is what handle_exit_screen ($CA70) requires before it lets
him leave the room.

A neat reuse: arch_nudge_to_centre jumps through its table with
lookup_plyr_dXY, which reads the facing of the record in IX -- here the arch --
so the arch's mirror bit (N/S) picks entry 2 and its absence (E/W) entry 0.

Drawing offsets: +$12 is added to the pixel X and +$13 to the pixel Y that
calc_pixel_XY ($D6C9) projects from x, y, z. Pixel Y counts up from the bottom
of the screen (the buffer's row 0 is copied to the bottom line). The tcdev
names adj_mY_mX give Y first.

| Routine | X | Y | Used for |
|---|---|---|---|
| upd_128_to_130 $C4D3 | -8 | -2 | types 128-130, upd_103 |
| adj_m4_m12 $C4D8 | -12 | -4 | special objects, cauldron items, many others |
| adj_m6_m12 $C4DD | -12 | -6 | knight's legs, ghosts, portcullis |
| upd_6_7 $C4E3 | -16 | -8 | types 6-7 (stone block), chest, table, moveable block |
| upd_10 $C4E8 | -20 | -1 | type 10 |
| upd_11 $C4ED | -12 | -2 | type 11, transformation sprites |
| upd_12_to_15 $C4F2 | -8 | -4 | types 12-15 and others |
| adj_m8_m12 $C4F7 | -12 | -8 | knight's top |
| adj_m7_m12 $C4FC | -12 | -7 | werewolf's legs |
| adj_m12_m12 $C501 | -12 | -12 | werewolf's top |
| upd_88_to_90 $C506 | -16 | -12 | types 88-90 |
| adj_p7_m12 $C50B | -12 | +7 | one caller ($B73C) |
| adj_p3_m12 $C510 | -12 | +3 | one caller ($B9A5) |
| upd_3_5 $C722 | -9 / -7 mirrored | -3 / -2 | second arch pillar |
| upd_2_4 $C73C | -7 (type 4: +1) / -17 mirrored | -3 / -2 | first arch pillar |

They all JR to a JP at $C4E0 because set_pixel_adj ($C72B) is out of JR range.

## How this was found

Read $C4D3-$C514 and $C722-$C82A; calc_pixel_XY for how +$12/+$13 are used;
blit_to_screen for which way pixel Y runs; the background table at $6CE2 for
the arch entries (arch_n: type 2 at x $8D, type 3 at x $73, both mirrored;
arch_e: type 2 at y $73, type 3 at y $8D, not mirrored), which confirms the
13-unit half-width.

## Confidence

Read.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| arch_ew_doorway | loc_C74C | $C74C | middle and limits of an E/W arch |
| arch_check_doorway | loc_C760 | $C760 | the two passes over the player |
| arch_nudge_to_centre | loc_C785 | $C785 | nudge pass |
| arch_nudge_loop | loc_C791 | $C791 | one record of it |
| nudge_y_store | loc_C7BF | $C7BF | store +$0F |
| nudge_x_store | loc_C7D2 | $C7D2 | store +$0E |
| arch_nudge_done | loc_C7D5 | $C7D5 | pop the counter |
| arch_nudge_next | loc_C7D6 | $C7D6 | next record |
| near_arch_loop | loc_C7E4 | $C7E4 | doorway test for one record |
| near_arch_next | loc_C7F9 | $C7F9 | next record |
| near_check_y | loc_C808 | $C808 | is_near_to, x limit and y distance |
| near_check_z | loc_C814 | $C814 | y limit and z distance |
| near_z_compare | loc_C820 | $C820 | z within 4 |

## Open questions

- ~~upd_62 ($C4AA), the "moveable block", can only fall~~ -- settled,
  *watched*: see [`collision.md`](collision.md), "Pushing, tested". A table
  is pushed a step per frame of contact; the same table retyped as $3E did not
  move at all.
- upd_85 (chest) keeps its horizontal velocity between frames while upd_84
  (table) clears it after each step; whether a pushed chest really slides on
  was not tested.
