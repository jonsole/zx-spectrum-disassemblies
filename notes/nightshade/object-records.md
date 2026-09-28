# The object records

**Question this answers:** what each of the 16 bytes of an object record
means, and which of the 23 records holds what.

**Short answer:** a graphic (which also picks the update routine), two
16-bit positions whose high bytes are the town's column and row, a speed,
a facing with a count in its low bits, flags, half-sizes, this turn's step,
a drawing offset and where it was last drawn. 23 records in a fixed order
from `KNIGHT` ($BC8E): the knight's legs and top, two antibodies, four
finds, a bonus, four objects, four villains, six monsters. The order is
meaningful: the object in record *n* kills the villain in record *n*.

## How it works

| Offset | Field |
|---|---|
| +0 | graphic: picks the sprite (`GRAPHICS`, $6E9E) and the update routine (`UPDATES`, $D599); 0 an empty record |
| +1, +2 | U, a word: +2 the town's column, +1 the place across the cell (256 to a cell) |
| +3, +4 | V, the same: +4 the row |
| +5 | speed; in a find, the type of the cell it came from (`SPAWN_FIND`, $C5CE) |
| +6 | bits 6-7 the facing: $00 +V, $40 +U, $80 -V, $C0 -U (bit 6 along U, bit 7 backwards); the low bits a count -- the knight's bits 0-2 a turn delay (`TURN_KNIGHT`), a walker's or find's bits 0-5 the turns to its next change of course (`WANDER_STEP`, `STEER`), the top's its pose |
| +7 | flags: bit 0 stopped by a wall this turn (`MOVE_CLIPPED`, $DE59); bit 1 drawn (set by `DRAW_SPRITE`, $E3D9; cleared by whoever needs to know, the sound routines that play only for things on the screen and `SPARKLE_FLY`); bit 5 a monster that turns towards the knight (`STEER`, $DD28; set only by `SPAWN_MONSTER`); bit 6 drawn mirrored; bit 7 drawn upside down (`TURN_SPRITE`, $E353; never set) |
| +8, +9 | half-size in U and V, centre to edge |
| +A, +B | this turn's step in U and V, signed bytes |
| +C, +D | the drawing offset, added to the projected position |
| +E, +F | where it was last drawn: the sprite's bottom left, x and y |

Subtracting $40 from the facing is a turn left, adding it a turn right.

| Record(s) | Label | Graphics |
|---|---|---|
| $BC8E | `KNIGHT` | his legs: 16-21 from behind, 24-29 from the front; 12-15 vanishing; 0 time for a new life |
| $BC9E | `KNIGHT_TOP` | his top: 22 and 30 (at a wall), 32-47 |
| $BCAE, $BCBE | `ANTIBODIES` | antibodies in flight, 80-95; only the first can strike ([`touching.md`](touching.md)) |
| $BCCE-$BCFE | `FINDS` | finds, 48-63; all four become a dead villain's sparkles, 140-143 |
| $BD0E | `BONUS` | 2 a faster walk, 3 the hits back |
| $BD1E-$BD4E | `OBJECTS` | record *n*: graphic 7 - *n* lying, 11 - *n* thrown |
| $BD5E-$BD8E | `VILLAINS` | record *n*: graphics 108 - 4*n* to 111 - 4*n*; 132-135 dying |
| $BD9E-$BDEE | `MONSTERS` | appearing 128-131, then 64-79 or 112-127; the creature, 136-139 |

The knight's legs' fields have labels of their own: `KNIGHT_U` ($BC8F),
`KNIGHT_COLUMN` ($BC90), `KNIGHT_V` ($BC91), `KNIGHT_ROW` ($BC92),
`KNIGHT_SPEED` ($BC93), `KNIGHT_FACING` ($BC94), `KNIGHT_FLAGS` ($BC95).
The ending reuses the records with its own meanings: +A and +B hold a
screen place ([`game-over-and-ending.md`](game-over-and-ending.md)).

Templates: `START_RECORDS` ($CC36, the knight's two), `MONSTER_RECORD`
($CE79), `OBJECT_RECORD` ($D8D7), `VILLAIN_RECORD` ($D932),
`ENDING_RECORDS` ($CCE4). A thrown thing is a copy of the legs' record
(`KNIGHT_THROWS`, $DAB7), a sparkle is built field by field
(`VILLAIN_SPARKLES`, $D6D6).

## How this was found

Read from the movement, drawing, touching and update routines' use of each
field (stage 2, all five ranges); the half-size reading from the clip
routines (`CLIP_PLUS_V`, $DE72: the front edge is at V plus +9, the corners
at U minus and plus +8) and the touch test (`TOUCH_TEST`, $C572). The
facing encoding from `SET_STEP` ($DCE0), checked against
`KNIGHT_DIRECTION`'s results and `MOVE_SPLIT`'s choices (range 4).
"Nothing sets bit 7": every write to a record's +7 was read (range 5).

## Confidence

*Read*. That bit 7 of +7 is never set: *read* (every write enumerated,
templates hold 0, the look table's four bytes have bit 7 clear) and agrees
with the sessions, in which the upside-down flip never ran; writes through
HL into a record were not all enumerated.

## Filmation (Knight Lore, Alien 8, Pentagram)

Knight Lore's, Alien 8's and Pentagram's records are 32 bytes and carry a
height, a room and many more flags; here there is no height at all, and the
position's high byte is the town cell, so a thing's "room" is simply where
it is. The centre-and-half-size box, the graphic as behaviour, and the
mirror and upside-down flags read by the sprite turner are the family's.

## Disassembly corrections

- Stage 1's memory map gave +8 and +9 as "sizes"; they are half-sizes,
  centre to edge (range 4, from the clip routines; range 1, from the touch
  test). The generator's record lines (`nightshade_data.py`, `FIELDS`) still
  call them "size in U" and "size in V" -- reported to the lead.
- Stage 1's "+6 facing (bits 6-7) and turn count (bits 0-2)": bits 0-2 are
  only the knight's; walkers and finds count on bits 0-5 (range 2).
- +5 in a find is the cell type, not a speed (range 1).

## Open questions

- Why the touch test halves the second record's half-size again
  ([`touching.md`](touching.md)).
