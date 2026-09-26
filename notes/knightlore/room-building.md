# Room building

**Question this answers:** How does a room record in the room table become the
objects the game moves and draws?

**Short answer:** When the player enters a room, `retrieve_screen` ($D3C6)
walks the room table at $6251 until it finds the record with the player's room
number, takes the room's colour and size from it, and then turns its two lists
-- backgrounds and foreground groups -- into ordinary 32-byte object records
from record 4 ($5C88) upwards. Whatever the room does not fill is cleared.
There is no background picture: walls, arches and blocks are objects like
everything else.

## How it works

```
build_screen_objects ($D1E6) -> $D1EF
  clear_scrn_buffer ($D567)
  retrieve_screen ($D3C6)          DE=$5C88, BC=$6BD1, HL=$6251
    find_screen ($D3CF)            match byte 0 against player's byte 8 ($5C10)
      [not found] zero_end_of_graphic_objs_tbl ($D3E2)
    found_screen ($D3F0)           colour -> $5BAD, size -> $5BAB/$5BAC/$5BAE
    next_bg_obj ($D41E)            each background number until $FF
      next_bg_obj_sprite ($D432)   each 8-byte template until a 0
    find_fg_objs ($D44C)           IY = next free record
      next_fg_obj ($D452)          type byte: type index + count
        next_fg_obj_in_count ($D46B)   once per location byte
          next_fg_obj_sprite ($D46C)   each 6-byte template until a 0
          zero_fg_obj_tail ($D4CD)
      end_of_fg_objs ($D4EA)
    zero_end_of_graphic_objs_tbl ($D3E2)   clear the rest, up to $6108
  find_special_objs_here ($C525)   fills from record 2 ($5C48)
  adjust_plyr_xyz_for_room_size ($D320)
  $5BB7 = 1                         new-room flag for the drawing code
```

### The room record, as the reader expects it

The table runs from $6251 to $6BD0 and ends where the foreground type table
$6BD1 begins; the reader stops when it passes $6BD1. Records are variable
length and can only be walked from the start.

| Offset | Field |
|---|---|
| 0 | room number, compared with byte 8 of the object in IX (the player) |
| 1 | length: the number of bytes in the record from this byte to its end (so record size is length + 1) |
| 2 | attribute byte: bits 0-2 the room's ink colour (drawn BRIGHT on black paper, into $5BAD); bits 3-7 the index into the size table $6248 |
| 3.. | background numbers, one byte each, ended by $FF |
| then | foreground groups to the end of the record: a type byte, then one location byte per object |

The reader also counts the bytes: B starts as length - 2 (the bytes after the
attribute byte) and every background number, the $FF, every type byte and
every location byte count one off. Either the end of a list or B reaching 0
finishes. A record with no $FF is all backgrounds.

**Size table $6248**, three bytes an entry, chosen by the attribute byte's bits
3-7: half-width in x into $5BAB, half-width in y into $5BAC, floor height into
$5BAE. The three entries in the snapshot are 64/64, 32/64 and 64/32 around the
room centre of 128, all with floor height 128. (The existing annotation calls
the three bytes "x, y and z"; the third is the floor height, and it is the same
in all three.)

**Background number** -> word at $6CE2 + 2 * number -> a list of 8-byte
templates ended by a 0 byte. Each template becomes bytes 0-7 of a record
unchanged:

| Template byte | Record byte | Meaning |
|---|---|---|
| 0 | 0 | graphic (0 is never an object, hence the 0 terminator) |
| 1-3 | 1-3 | x, y, z -- absolute, not relative to the floor |
| 4-7 | 4-7 | half-sizes, height and flags (see Variables used) |
| -- | 8 | the room number |
| -- | 9-31 | cleared |

**Foreground type byte**: bits 3-7 index the word table $6BD1 (the RRCA, RRCA,
AND $3E gives the doubled index directly); bits 0-2 are the number of location
bytes that follow, less one. So one type byte can place up to eight copies.

**Location byte** (one per copy): bits 0-2 x cell, bits 3-5 y cell, bits 6-7
level.

**Foreground template** (the list at the type's address, 6 bytes each, ended by
a 0): graphic, four bytes into record bytes 4-7, and an offset byte. A type
can have more than one template, and every template is placed at every
location, so one location can build a stack of records.

The position is worked out as:

- x = $48 + 16 * x cell + (8 if offset bit 0)
- y = $48 + 16 * y cell + (8 if offset bit 1)
- z = floor ($5BAE) + ((12 * level + offset byte) AND $FC)

So cells are 16 units, $48 to $B8 in each direction around the centre $80;
levels are 12 units; the offset byte gives half-cell shifts in x and y and a
height in steps of 4.

Worked example from the first record (room 0): length 25, attribute 3 (magenta,
size 0), backgrounds 0, 1 and 12, then type 0 with eight locations, type 0 with
seven, and type 21 with one -- 25 bytes after the room number, as the length
says.

Records 0 to 3 of the object table are never written by the room builder; 4 to
39 are the room's. There is no check that a room fits in 36 records.

## How this was found

Read `retrieve_screen` through `end_of_fg_objs` in the listing, and checked the
record layout against the first room record at $6251 by hand (the byte count
matches the length byte exactly). The size table's values and the floor meaning
of $5BAE come from its uses outside this range: `adjust_plyr_xyz_for_room_size`
($D320) and the out-of-bounds checks at $CCDD/$CD08 compare |x - 128| plus a
half-size against $5BAB/$5BAC, and $C667/$C6F4/$CA5A compare z against $5BAE.
IX being the player comes from `loc_D1EF` reading $5C10 (record 0, byte 8)
straight after.

## Confidence

All read from the code. The meaning of the template bytes 4-7 (half-sizes,
height, flags) is from how other ranges use record bytes 4-7, not from this
range. "Records 2 and 3 are the special objects" rests only on `find_special_objs_here`
starting at $5C48.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| zero_fg_obj_tail | loc_D4CD | $D4CD | clear bytes 9-31 of a foreground record, then the next template/location/type |
| end_of_fg_objs | loc_D4EA | $D4EA | room record used up: clear the rest of the table |

## Open questions

- What the offset byte's bits 5-7 are for: they are added into z (32, 64, 128)
  with the rest of the byte, so either no template sets them or some object
  really is placed that high.
- Nothing stops a room overflowing record 39; presumably no room does.
