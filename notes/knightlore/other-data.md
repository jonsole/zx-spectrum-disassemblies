# The other data

**Question this answers:** what else lies between $6108 and $AF6B?

**Short answer:** the 40-character font, the charm placement table, and 12 unused bytes.

## How it works

### Font ($6108, 320 bytes)

40 characters, 8 bytes, top row first. Codes: $00-$09 digits, $0A-$23 A-Z, $24 full stop, $25 copyright, $26 space, $27 percent. `print_8x8` ($BE7F) indexes code * 8 from the address in $5BC7; `print_text` ($BE4C) and `print_text_single_colour` stop after a byte with bit 7 set. Codes checked against `menu_text` (e.g. $26 as the space between words, $25 before "1984").

### Charm places (`special_objs_tbl`, $6FF2, 32 x 9 bytes)

| Offset | Field |
|---|---|
| 0 | type $60-$67; 0 in the file, filled by `init_special_objects` ($C47E); written back 0 when the charm is picked up (`pickup_object` $C141), used in the cauldron (`add_obj_to_cauldron` $C245) or destroyed (`upd_185_187` $BF37) |
| 1-4 | start x, y, z, room (the only bytes filled in the file) |
| 5-8 | current x, y, z, room: copied from 1-4 at game start, written back by `update_special_objs` ($C591) |

`init_special_objects`: E = ($5BA0) + R; for each entry type = $60 + (E AND 7), E += 1. So the kinds cycle in order and each appears exactly 4 times; only the starting kind is random. `find_special_objs_here` ($C525) builds records from $5C48 for entries whose +0 != 0 and +8 = current room: +0 type, +1..+3 from entry +5..+7, sizes 5,5,12, flags $14, +8 room, +16/+17 = address of the entry. No room has more than one entry (all 32 rooms distinct), so the two slots $5C48 and $5C68 suffice. Which charms the wizard wants is a separate list, `objects_required` ($C27D), rotated by `shuffle_objects_required` ($B544). The existing annotation pointed at $B2CF, which is `play_audio`.

### $7D98: twelve zero bytes

Between spr_017 and spr_018. No reference in the code or in `sprite_tbl`.

## How this was found

Read the routines named above; decoded the table with a script to check the 32 rooms against `location_tbl`.

## Confidence

Read from the code. That the $7D98 bytes are unused rests on there being no reference to $7D98-$7DA3 anywhere in the listing.

## Renamed routines

None.

## Open questions

- Why 12 bytes are left between two sprites (alignment? a deleted sprite?).
