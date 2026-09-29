# The object table, and placing a room's objects

**Question this answers:** what the object table holds, and how a room's
object records are made from it, from the templates and from the room's own
object list.

**Short answer:** the object table (`OBJECTS`, $A924 while the game runs;
`OBJECTS_TAPE`, $C4E0, on the tape) lists everything that belongs to a room
rather than to its drawing: 381 records -- 163 six-byte records (the things
that can move between rooms), then 174 eleven-byte records (the doors),
then 44 more six-byte records (still things) -- and $FF. When a room is
drawn, `PLACE_ROOM_OBJECTS` ($EACC) walks the whole table for entries in
this room, and `PLACE_OBJECT` ($EB1A) makes each a record from its type's
template, then moves it into place by projecting from the point (50, 50,
50) at which the template's screen position is right. A room's object list
(after `$E4 $04`) makes more records the same way, and its patch codes set
the room's floor, ceiling and walls.

## How it works

**The table.** Each entry is a room, a type, and then:

| Type | Bytes after the type | Makes |
|---|---|---|
| Below $46 | 4: +12 (the kind byte), x, top, z | A thing (163 at the start, 44 at the end) |
| $46 up | 9: x, top, z, then +13 to +18 | A door (kind 1): the room behind, the key, the arrival x, top and z, the way through ([`doors.md`](doors.md)) |

(*compared*: the table walked from $C4E0, 3157 bytes with the $FF; the
sizes run 163 x 6, 174 x 11, 44 x 6.) 78 rooms have entries. The table's
room byte is the thing's room *now*: picking a thing up writes $FE (no
room), dropping it writes the room it is dropped in (`SET_THING_ROOM`,
$F4E6), and the things that vanish for good are moved to $FE too. Its
bytes 3-5 are where it is *now*: `SAVE_OBJECT_POSITIONS` ($F906, the
author's EEN) copies each thing's x, top and z back when the knight leaves a
room ([`entering-rooms.md`](entering-rooms.md)). The source text left on the
tape heads the last 44 "STATIC OBJ".

`SET_THING_ROOM` finds a thing's entry as $A91E + 6 x its number: that only
works because every record before it is six bytes long, so only the first
163 -- the things that can move -- can be reached. The master copy
(`MASTER_OBJECTS`, $639C) keeps the first 1200 bytes of the table, which
takes in all 163 and the first doors, for each new game
([`start-up.md`](start-up.md)).

**Placing.** `PLACE_ROOM_OBJECTS` first zeroes every record from
`FREE_RECORD` to $BFFF, then numbers every entry it passes (`PLACED_NUMBER`,
$FFDB, a byte) and makes a record for each in this room (`ROOM`), giving
+19 the number for types below $46 (`PLACED_TYPE`, $FFDA, keeps the type).
It runs once in each drawing of a room, from the room's `$E4 $04` or `$E4
$05` ([`rooms.md`](rooms.md)). Then the room's own object list, in object
mode: each code below $E4 is a type followed by the same four bytes (the
kind byte and a place), made into a record the same way with +19 = 0;
codes $E6 up are patches ([`object-records.md`](object-records.md)).

`PLACE_OBJECT` and `PLACE_FROM_TEMPLATE` ($EB4C), for the record at IX:

| Offset | Type below $46 | Type $46 up |
|---|---|---|
| +0 to +5 | Template bytes 0-5: screen x and top row; sprite width and height; the sprite | The same |
| +6 to +8 | The place given (plus `ORIGIN`) | The same |
| +9 to +11 | Template bytes 6-8: the lengths | The same |
| +12 | The kind byte from the table or the list | 1 |
| +13 | 5 for states 2 and 4-10; $45 for state 3 | The table's +13 to +18 |
| +14 | Template byte 9: its state | |
| +15 | 1 | |
| +16 | Template byte 10: 0 still, else 16 plus its weight | |
| +17 | 16 for states 4-10 (a run of three frames) | |
| +19 | Its number (table things only) | 0 |

The templates: 57 of eleven bytes at `TEMPLATES` ($B734, types 0-$38) and
15 of nine bytes at `LARGE_TEMPLATES` ($B9AA, types $46-$54), then
`PATCHES` ($BA3E); copied there from $D2F0 at start-up. The states the
templates give: 0, 3 (type 2), 4 (48), 6 (26), 7 (13), 9 (27), 10 (33), 11
(45), 12 (51), 13 (52), 14 (40), 15 (56). **State 2 is in no template**, so
the one stretch that sets it up ($EBC4) never runs.

Placing a record: its +6 to +8 are first set to (50, 50 + its height, 50),
then `ISO_MOVE` moves it to the wanted place plus the origin, shifting +0,
+1 by the projection of the change ([`projection.md`](projection.md)). So a
template's screen position is where the sprite goes for an object whose
floor is at 50 and which stands at x 50, z 50.

## How this was found

Read (stage 2, range 2): $EACC-$EBE9 and `DO_ROOM_COMMAND`'s object-mode
branch. Template fields listed from the tape's copy at $D2F0; object types
in rooms' object lists counted with the build's parser (154 objects written
into rooms and parts, types 0-54, all below $46). *Measured*: every room
1-80 entered in the simulator and `OBJECT_COUNT` read after drawing -- at
most 37 records, in room 71 (30 of the room's own), against room for 43 at
$BCA4-$BFFF. The three parts of the table *compared* in stage 3 by walking
it (163 + 174 + 44).

## Confidence

The layout and the flow: *read*. State 2 absent: *read* from the templates.
Counts: *measured*.

## Disassembly corrections

- Stage 1's notes said the table is 163 six-byte records and then 218
  eleven-byte ones. It is 163 six-byte, 174 eleven-byte (the doors) and 44
  six-byte records; the listing's generated entries were always right.
- Stage 2's range 2 had the template's lengths (bytes 6-8) as half-width,
  height, half-depth: they are lengths from the corner.

## Krumlinde

He calls these "decorations" and $EB1A `RTN_Place_Decoration`; they are all
the room's objects -- things to carry, doors, invisible boxes. `FREE_RECORD`
is a pointer to the next record, not a list of free slots; ($FFBA) is the
object table itself, not a coincidence. The four bytes his
`Room_PlaceObjectRef` reads ("layout not traced") are +12, x, top, z. His
shape table at $A91E/$A921 is the object table less six and three
(`SET_THING_ROOM`'s base, and $F7C4's and $F906's); its bytes are only laid
there by the start-up (stage 1's finding). His account of the template copy
and of the projection helper agrees.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `PLACE_ROOM_OBJECTS` | `SUBEACC` | $EACC | The object table's entries for this room |
| `PLACE_OBJECT` | `SUBEB1A` | $EB1A | One record from a type, its bytes, its template |
| `PLACE_FROM_TEMPLATE` | `SUBEB4C` | $EB4C | Its continuation |
| `COPY_TO_RECORD` | `SUBEBEA` | $EBEA | B bytes from HL to IX |

## Open questions

- `PLACED_NUMBER` is a byte, so entries past 255 (the later doors and the
  still things) get their number less 256 in +19. Harmless if none of them
  is ever saved or moved (only the first 163 are), *inferred*.
