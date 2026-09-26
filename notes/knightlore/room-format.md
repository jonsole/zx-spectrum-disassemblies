# Room format

**Question this answers:** how is a Knight Lore room stored, and how does the game turn a room number into the objects on screen?

**Short answer:** `location_tbl` ($6251) holds 128 variable-length room records packed end to end, found by a linear walk. Each record is a room number, a length, a shape-and-colour byte, a list of background indexes into `background_type_tbl` ($6CE2), an optional $FF, and groups of objects placed on an 8 x 8 x 4 cell grid through `block_type_tbl` ($6BD1). `retrieve_screen` ($D3C6) expands the record into up to 36 object records of 32 bytes at $5C88-$6107.

## How it works

Call chain, from `loc_D1EF` ($D1EF, called by `build_screen_objects` $D1E6 on entering a room):

```
loc_D1EF
  clear_scrn_buffer
  retrieve_screen $D3C6      DE=$5C88, BC=block_type_tbl (end of rooms), HL=location_tbl
    find_screen $D3CF        walk records until byte 0 = (IX+8), the player's room
      -> zero_end_of_graphic_objs_tbl $D3E2 if not found (clears $5C88..$6107)
    found_screen $D3F0       colour -> $5BAD, shape -> $5BAB/$5BAC/$5BAE
    next_bg_obj $D41E        per background byte: look up background_type_tbl
      next_bg_obj_sprite $D432   copy 8 bytes per piece, +8 = room, clear +9..+31
    find_fg_objs $D44C       after the $FF
      next_fg_obj $D452      group byte: type index + count
        next_fg_obj_in_count $D46B / next_fg_obj_sprite $D46C   per copy, per part
    loc_D4EA / zero_end_of_graphic_objs_tbl   clear the unused records up to $6108
  find_special_objs_here $C525   charms into $5C48/$5C68
  adjust_plyr_xyz_for_room_size $D320
  ...
```

### Room record (`location_tbl`, $6251-$6BD0)

| Offset | Field |
|---|---|
| 0 | Room number = row * 16 + column on a 16 x 16 grid. East/west exits change the low nibble by 1 (`screen_east` $CAF3, `screen_west` $CA9A, with the high nibble kept); north/south add/subtract $10 (`screen_north` $CB0E, `screen_south` $CB29). |
| 1 | N = distance from this byte to the next record (record length - 1). `find_screen` adds it to skip a record. |
| 2 | Bits 0-2: ink colour (3, 4, 5 or 6 in the data); `found_screen` stores `ink OR $40` (bright, black paper) at $5BAD. Bits 3-7: shape index into `room_size_tbl` (0, 1 or 2 in the data). |
| 3 .. | Background indexes (0-23) into `background_type_tbl`, one byte each. |
| next | $FF ends the backgrounds -- only if objects follow. 24 rooms have no $FF and end after their backgrounds (the byte count in B runs out, `DJNZ next_bg_obj` falls through). |
| then | Object groups: a group byte, then one position byte per copy. |

Group byte: bits 3-7 = index into `block_type_tbl` (0-28; `next_fg_obj` does RRCA, RRCA, AND $3E to get index*2); bits 0-2 = copies - 1 (1 to 8 copies).

Position byte, decoded in `next_fg_obj_sprite` ($D46C):

| Bits | Meaning | Coordinate |
|---|---|---|
| 0-2 | x cell 0-7 | x = $48 + 16 * cell (+8 if bit 0 of the part's offset byte) |
| 3-5 | y cell 0-7 | y = $48 + 16 * cell (+8 if bit 1 of the offset byte) |
| 6-7 | level 0-3 | z = ($5BAE floor) + 12 * level + (offset byte AND $FC) |

$48 is the centre of cell 0 in a full-size room ($40 edge + 8). The walk ends when HL reaches `block_type_tbl`; there is no terminator. All 128 records walk exactly to $6BD1 (checked by decoding every one).

### Room shapes (`room_size_tbl`, $6248)

| Index | Byte 0 -> $5BAB | Byte 1 -> $5BAC | Byte 2 -> $5BAE | Rooms |
|---|---|---|---|---|
| 0 | $40 half-width in x | $40 half-depth in y | $80 floor z | 70 (46 stone, 24 forest) |
| 1 | $20 | $40 | $80 | 34 |
| 2 | $40 | $20 | $80 | 24 |

Rooms are centred on x = y = $80. $5BAB/$5BAC are read by `chk_plyr_OOB` ($C87A: `LD HL,($5BAB)` then subtracts the object's sizes), `adj_dX_for_out_of_bounds` / `adj_dY_for_out_of_bounds`, the exit tests at $CA9A-$CB29 and `adjust_plyr_xyz_for_room_size` ($D320). The third byte is a floor height, not a size.

### Block types (`block_type_tbl` $6BD1 -> 6-byte parts, 0-terminated)

| Part byte | Goes to | Meaning |
|---|---|---|
| 0 | +0 | object type (sprite via `sprite_tbl`, handler via `upd_sprite_jmp_tbl` $B096) |
| 1 | +4 | size along x |
| 2 | +5 | size along y |
| 3 | +6 | height |
| 4 | +7 | flags (bit 6 mirror, bit 7 upside-down; others belong to handlers) |
| 5 | not stored | bit 0: x += 8; bit 1: y += 8; AND $FC added to z |

Every record also gets +8 = room number and +9..+31 = 0. A part list continues while the next byte (the next part's type) is non-zero. Two kinds have two parts: the guards (`guard_ew` $6C9E: $96 body + $90 legs; `guard_square` $6CAB: $1E body + $90 legs). The body's handler copies its x (and y) into the *next* record (+$21, +$22), so part order in the list matters.

Index -> kind: 0 block $07, 1 fire $B0, 2 ball $B2 (+8 y), 3 rock $06, 4 gargoyle $16, 5 spikes $17, 6 chest $55, 7 table $54, 8 guard $96/$90, 9 ghost $52, 10 fire $B5, 11 block raised ($30), 12 ball (+8 x, +8 y), 13 guard $1E/$90, 14 block $36, 15 block $37, 16 block $3E, 17 spikes raised, 18 spiked ball $3F, 19 spiked ball raised, 20 fire $56, 21 block $5B, 22 block $8F, 23 ball $B6, 24 ball, 25 sparkle $A4, 26 portcullis 12x1 (+8 x), 27 portcullis 1x12 (+8 y), 28 ball (+8 x). The four `ball_ud*` entries differ only in the offset byte: tcdev's _x/_y/_xy suffixes are the half-cell shifts.

### Backgrounds (`background_type_tbl` $6CE2 -> 8-byte pieces, 0-terminated)

Each piece is copied verbatim to object bytes +0..+7: type, x, y, z, size x, size y, height, flags. Backgrounds therefore carry absolute coordinates (z = $80 etc., not relative to $5BAE -- harmless because every floor is $80).

| Index | Label | Pieces | Rooms using it |
|---|---|---|---|
| 0-3 | arch_n/e/s/w | $02 + $03 pillars at y=$C4 / x=$C4 / y=$3B / x=$3B, $0D either side of $80 | 63 / 40 / 46 / 50 |
| 4-7 | tree_arch_n/e/s/w | $04 + $05 trunks, same places | 13 / 17 / 14 / 17 |
| 8-11 | gate_n/e/s/w | one $08 portcullis at z=$A0 (starts 32 up) | 1 / 2 / 1 / 2 |
| 12 | walls_square (was wall_size_1) | 13 pieces: $0D/$0E corner columns, $0F ends (two high), $0A/$0B/$0C slabs | 46 |
| 13 | walls_narrow_y (was wall_size_2) | 14 pieces, for shape 2 | 24 |
| 14 | walls_narrow_x (was wall_size_3) | 14 pieces, for shape 1 | 34 |
| 15 | tree_walls (was tree_room_size_1) | 12 trees $80/$81/$82, gaps in the middle of each wall | 24 |
| 16 | tree_filler_w | 2 trees closing the west gap | 7 |
| 17 | tree_filler_n | 2 trees closing the north gap | 11 |
| 18 | wizard | $9E body + $90 legs | 1 (room $88) |
| 19 | cauldron | $8D + $8E | 1 (room $88) |
| 20/21 | high_arch_e/s | arch at z=$B0 | 10 / 16 |
| 22/23 | high_arch_e_base/s_base | two $07 blocks at z=$A4 below the high arch | 10 / 16 |

The wall set always matches the shape: shape 0 + set 12 (46 rooms) or forest set 15 (24), shape 1 + set 14 (34), shape 2 + set 13 (24). Only the north (y = $C0) and west (x = $3F) sides have walls. `tree_filler_w` appears exactly in forest rooms without `tree_arch_w`, `tree_filler_n` in those without `tree_arch_n`. High arches always come with their step.

### Capacity

Objects are laid from $5C88 to $6107: 36 records. Counting background pieces plus parts x copies for every room, the maximum is exactly 36, reached by six rooms ($21, $46, $78, $A3, $BF, $F0). `zero_end_of_graphic_objs_tbl` stops only on DE = $6108 exactly, so one more object would run the clear past the table.

### Numbers

128 rooms, ids 0-255 with no duplicates. Colours: 39 magenta, 23 green, 27 cyan, 39 yellow. The 4 start rooms in `start_locations` ($D1E2: $2F, $44, $B3, $8F) and the 32 charm rooms all exist.

## How this was found

Read `retrieve_screen` .. `loc_D4EA` ($D3C6-$D4F1) instruction by instruction, then wrote a decoder in the scratchpad that follows the same rules and checked it against all 2432 bytes: every record's contents end exactly at the next record, the last at $6BD1. Room-number arithmetic from `screen_west`/`screen_east`/`screen_north`/`screen_south`. Room-size variables from their readers listed above. Background/wall pairings, filler rules and the 36-object maximum from the same decoder.

## Confidence

All of the format is read from the code and confirmed by decoding the whole table. The names "north/east/south/west" follow the exit routines (north = +y, east = +x). What the $0A-$0C slabs and the $0D-$0F columns look like is inferred from their sprites and positions.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| walls_square | wall_size_1 | $6DE0 | wall set for room shape 0 |
| walls_narrow_y | wall_size_2 | $6E49 | wall set for room shape 2 ($40 x $20) |
| walls_narrow_x | wall_size_3 | $6EBA | wall set for room shape 1 ($20 x $40) |
| tree_walls | tree_room_size_1 | $6F2B | trees round a forest room (only one size exists) |
| portcullis_along_x | gate_ud_1 | $6CD4 | block type 26, 12 x 1 |
| portcullis_along_y | gate_ud_2 | $6CDB | block type 27, 1 x 12 |

The old wall names were numbered 1-3 but serve shapes 0, 2, 1, and all six ended in _digit.

## Open questions

- The flags byte (+7) values used here are $10, $12, $14, $1C/$1E (player), $50. Bits 6 and 7 are the drawing flips; bit 1 is set on the second half of every two-part thing (guard/wizard legs, cauldron top, player's upper half) and bit 4 is cleared by the drawer (`RES 4` at $D710). The rest is for the handler agents.
- The existing annotation said the room records "end at $FF"; they do not -- $FF separates backgrounds from objects and is absent when there are no objects.
