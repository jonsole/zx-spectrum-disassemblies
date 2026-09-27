# Rooms: the directory and the builder

**Question this answers:** how a room is stored, and exactly how
`BUILD_ROOM` turns its record into object records.

**Short answer:** 139 variable-length records in the directory at `ROOMS`
($5E10), numbered 0-149 with eleven numbers unused. Each has its colour and
size, a list of scenery entries (a template number and a byte, which for a
doorway is the room it leads to) and groups of objects (a template and a
position byte per copy). `BUILD_ROOM` ($C92C) fills the 48 room records from
the top down: scenery first, each template piece a record, then objects.

## How it works

`ENTER_ROOM` ($C6B6): `CLEAR_BUFFER`, `BUILD_ROOM`,
`ADJUST_PLYR_UVZ_FOR_ROOM_SIZE` ([`doorways-and-rooms.md`](doorways-and-rooms.md)),
`MARK_ROOM_SEEN` ([`percentage.md`](percentage.md)), `NEW_ROOM` = 1.

**A room record** (laid out record by record, with its picture, by
`scripts/pentagram_data.py` at every build):

| Offset | Field |
|---|---|
| +0 | the room number |
| +1 | the count of bytes from here to the end of the record |
| +2 | bits 0-2 the ink; bits 3-7 the size, 0-2, an index into `ROOM_SIZES` ($5E07) |
| +3 on | scenery entries of two bytes up to an $FF; then object groups |

**Scenery**: a template number, indexing `SCENERY_TABLE` ($696D), and one
more byte. A scenery template is a list of 8-byte pieces -- graphic, U, V, Z,
the three half-sizes, flags -- ended by a zero; each piece becomes a record,
and every piece of the entry takes the entry's second byte as its +$08: for a
doorway the room it leads to, otherwise 0.

**Objects**: groups, each a header byte (bits 0-2 the count less one, bits
3-7 the template, indexing `OBJECT_TABLE` $6CE5) and one position byte per
copy. An object template is a list of 5-byte pieces -- graphic, the three
half-sizes, flags -- ended by a zero (every one Pentagram has is one piece
long). A position byte gives U = 72 + 16 x bits 0-2, V = 72 + 16 x bits 3-5
and Z = the floor + 12 x bits 6-7; the object's +$08 is this room.

**The sizes** (`ROOM_SIZES`): half-sizes (64, 64), (32, 64) and (64, 32) in
U and V about the room's middle at 128, and the floor at 128 in all three --
rooms of 128 by 128, 64 by 128 and 128 by 64 units. `BUILD_ROOM` copies the
room's three into `ROOM_EXTENT` ($A71D) and its ink, with BRIGHT, into
`ROOM_ATTR` ($A738) (*read*). 116 rooms are square, 13 and 10 narrow the two
ways; all 23 narrow rooms are corridors with a doorway at each end (*read*
from the data at build time by the world page's generator)
([`world.md`](world.md)).

**`BUILD_ROOM`** ($C92C), step by step:

1. `CLEAR_OBJECTS` ($CB54): the 52 records from `BOLTS`, everything but the
   player's two.
2. `TEMPLATES_AT` = `OBJECT_TABLE`, `PLACE_NUDGE` = 0.
3. Find the record: compare +0 with the room, else step on by +1 plus one.
   An `AND A / SBC HL,BC / ADD HL,BC` after the step compares with
   `SCENERY_TABLE` and nothing uses the flags: there is no end check, so a
   room number not in the directory would run on through memory (*read*;
   the consequence *inferred*, not tried).
4. Colour and size, as above. The count at +1 less two is the budget.
5. Scenery, until the $FF, each piece into the next record down, +$09 to +$1F
   cleared. If the budget runs out here, the room has no objects.
6. Objects: each piece of the template into a record at the position (plus
   `PLACE_NUDGE`: bit 0 +8 U, bit 1 +8 V, the rest to Z). Template 31 in a
   header is not a template: `TEMPLATE_PAGE` ($CA6C) moves `TEMPLATES_AT` on
   64 bytes, to a second page of templates, and the byte after it is counted
   and skipped. No room uses it; it never ran.
7. The budget counts every byte from +1, and running out stops the build
   wherever it is: in rooms 13 and 108 the last group's header asks for more
   copies than there are bytes left, and the builder stops partway through
   the group (stage 1, *read* from the data by the generator).

Nothing checks that 48 records are enough; the fullest room, 87, uses 43.

`PLACE_NUDGE` is always 0: the only code that would set it, six bytes at
`SET_PLACE_NUDGE` ($CA7C), is reached by nothing -- `LD A,D / LD
(PLACE_NUDGE),A / JR` back into the builder: a header like template 31's
that set the nudge from the byte after it for the objects that follow. No
word $CA7C appears anywhere in the loaded block (*searched*). Knight Lore's
object templates carry that nudge as a sixth byte; Pentagram's have five.

## How this was found

Read (stage 2, range 4); the positions checked against the arches' records in
the simulated start rooms. The record format was established in stage 1 by
`pentagram_data.py`, which walks every table the way the code reads it and
stops the build if a record does not end where its length says or a table
does not tile its range (all 139 do). The user's remake found the same format
by watching the builder read the data.

## Confidence

*Read*; positions *measured* only through the arches' records; the tables'
extents *measured* by the generator at every build.

## Knight Lore

Knight Lore's `build_room` is the closest match (0.45), and its rooms are
records of the same idea on a 16 by 16 grid, with no doorway byte: its exits
are arithmetic ([`../knightlore/room-format.md`](../knightlore/room-format.md),
[`../knightlore/room-building.md`](../knightlore/room-building.md)). Its
object templates are six bytes (the sixth the placement nudge) to Pentagram's
five, and its room size table is the same three sizes.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `NEXT_GROUP` | (entry point) | $C9BC | the next object group |
| `TEMPLATE_PAGE` | (entry point) | $CA6C | template 31 |
| `SET_PLACE_NUDGE` | `TEXTCA7C` | $CA7C | unreachable code, now data with a description |
| `SET_PLACE_NUDGE_END` | `DATACA7F` | $CA7F | its tail |
| `CLEAR_OBJECTS` | `SUBCB54` | $CB54 | clear records 2-53 |
| `MARK_ROOM_SEEN` | `SUBC6CC` | $C6CC | the rooms-seen bit |

Stage 1's entry-point label `NEXT_PIECE` ($C9AB, the loop over a template's
pieces) did not survive the stage 2 merge; the listing names the jump target
automatically.

## Disassembly corrections

- $CA7C was listed as text and $CA7F as data: they are code nothing reaches.
  Kept as data with a description, because the LD runs across the entry
  boundary at $CA7F; making them one code entry needs `; span $CA7C,6` in the
  annotations.

## Open questions

- Which header value used to reach $CA7C (presumably template 30).
