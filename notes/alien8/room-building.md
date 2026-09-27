# Building a room

**Question this answers:** how a room record becomes object records.

**Short answer:** `BUILD_ROOM` ($CCA7) finds the room by its number in the
directory, takes its colour and size, copies each background's eight-byte
pieces into records from record 4 up, then each object group's five-byte
template pieces at 16-unit cells, and clears every record after. The
placement nudge -- dead code in Pentagram -- is live here: 41 headers raise
the objects after them by 48.

## How it works

- **The directory walk**: from `ROOM02` ($6469), +0 the room number
  compared with the legs' +$08, +1 the count of bytes from +1 to the
  record's end; the walk stops at `OBJECT_TABLE` ($73C8). A room not found
  gets no records (everything from record 4 is cleared).
- **Found**: `ROOM_INK` = bits 0-2 of +2; `ROOM_COLOUR_AT` = the address of
  +2 (where an activated chamber writes white, [`chambers-and-summary.md`](chambers-and-summary.md));
  bits 6-7 of +2 pick one of the three entries of `ROOM_SIZES` ($6460):
  `ROOM_HALF_U`, `ROOM_HALF_V`, `FLOOR` -- (64, 64, 64), (32, 64, 64) or (64,
  32, 64), rooms of 128 by 128, 64 by 128 and 128 by 64. `TEMPLATES_AT` =
  $73C8, `PLACE_NUDGE` = 0, `LIFT_TOP` = 0.
- **Backgrounds** (`BUILD_NEXT_BACKGROUND` $CD0C): a byte each up to $FF, a
  word index into `BACKGROUND_TABLE` ($7519); each eight-byte piece
  (graphic, U, V, Z, half-sizes, height, flags) to +0-+7 (`BUILD_BACKGROUND_PIECE`
  $CD20), the room to +8, +9-+$1F cleared; a zero ends the background.
- **Objects** (`BUILD_OBJECTS` $CD3A, `BUILD_NEXT_GROUP` $CD40): a header --
  bits 0-2 the count less one, bits 3-7 the template -- then a position byte
  per object. Template 0: the byte after is the new `PLACE_NUDGE`
  (`BUILD_SET_NUDGE` $CE00). Template 31: `TEMPLATES_AT` += 64, the second
  page of templates (`BUILD_TEMPLATE_PAGE` $CDF0). Otherwise each five-byte
  piece (graphic, half U, half V, height, flags) to +0 and +4-+7, the room
  to +8 (`BUILD_OBJECT_PIECE` $CD62), and the position: U = 72 + 16 x bits
  0-2 (+8 if the nudge's bit 0), V = 72 + 16 x bits 3-5 (+8 if its bit 1),
  Z = `FLOOR` + 12 x bits 6-7 + (nudge AND $FC).
- **The end**: the count at +1, decremented for every byte read, ends the
  build wherever it runs out (`BUILD_OBJECTS_DONE` $CDE8). Then
  `BUILD_CLEAR_REST` ($CCD0) clears records up to `BELOW_BLOCK` ($6288),
  stopping on equality only.
- `GET_PTR_OBJECT` ($CC96): a record number to its address.
- **The rooms' colours** (`RESET_ROOM_COLOURS` $CAD2, every new game): bits
  3-5 of each room's third byte copied to bits 0-2, undoing activated
  chambers' white ink. On the tape the inks are 3-6 (32, 28, 34 and 34
  rooms).

## How this was found

Read against Pentagram's `BUILD_ROOM` (0.90) and Knight Lore's
`retrieve_screen` and its pieces (stage 2, range 5). The nudge's use counted
from the level data as the build lays it out: 42 template-0 headers, 41 with
$30 and one with 0 (room $44, which sets $30 for one group and 0 again
before the next); twelve template-31 headers. `scripts/alien8_data.py` walks
every room the way this routine does and stops the build if a record does
not end where its count says (stage 1).

## Confidence

*Read*, and *measured* in that every room was built in the build's tour.

## Knight Lore and Pentagram

The same record layout and cell arithmetic
([`../knightlore/room-building.md`](../knightlore/room-building.md),
[`../pentagram/room-building.md`](../pentagram/room-building.md)).
Pentagram's builder has the nudge store only in unreached bytes and fills
downwards from its top record; Alien 8's fills upwards from record 4 and the
nudge is reached. The name is Pentagram's: Knight Lore's `retrieve_screen`
calls a room a screen. Alien 8's rooms have their ink reset at every game
because the chambers change it.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `BUILD_ROOM` | `SUBCCA7` | $CCA7 | the builder (`BUILD_CLEAR_REST`, `BUILD_NEXT_BACKGROUND`, `BUILD_BACKGROUND_PIECE`, `BUILD_OBJECTS`, `BUILD_NEXT_GROUP`, `BUILD_NEXT_OBJECT`, `BUILD_OBJECT_PIECE`, `BUILD_OBJECTS_DONE`, `BUILD_TEMPLATE_PAGE`, `BUILD_SET_NUDGE`) |
| `GET_PTR_OBJECT` | `SUBCC96` | $CC96 | record number to address |
| `RESET_ROOM_COLOURS` | `SUBCAD2` | $CAD2 | every room's ink back |

## Open questions

- If a room ever overran the 52 records the clearing loop would run through
  memory (it tests for equality with $6288). None does; not a live bug.
