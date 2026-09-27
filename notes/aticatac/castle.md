# The castle: rooms, shapes and layout

**Question this answers:** what a room is, how the 149 rooms are stored,
what is in each, and how they fit together into floors.

**Short answer:** a room is two bytes in `ROOM_TABLE` ($A854): a colour and a
shape number. The shape (`ROOM_SHAPES` $A982) gives how far from the centre
the player may walk and a vector outline to draw. What is in a room is a
separate list of the door and furniture records it holds (`ROOM_CONTENTS`
$757D); objects and monsters are found by their own room byte. The game has
no map and no idea of a floor: the build's map puts the castle together from
the doors, and finds five floors -- the top 5 rooms, 32, 42 (where the game
starts), 24, and 46 caverns at the bottom.

## How it works

**`ROOM_TABLE`** (*read*): 151 two-byte entries, indexed by room number.
Rooms $00-$94 are the 149 the player walks in; entry $95 is black on black
and entry $96 is shape $0C, the nested rectangles `TRAPDOOR_FALL` draws while
the player drops ([`doors.md`](doors.md)). The colours, counted over the 149:
$42 red 15 rooms, $43 magenta 29, $44 green 28, $45 cyan 30, $46 yellow 30,
$47 white 17 (*measured* from the table).

**`ROOM_SHAPES`** (*read*): thirteen entries of six bytes -- half-width and
half-height of the walk area, a pointer to a vertex table (x, y pairs), a
pointer to an edge list. `DRAW_ROOM` ($9BEA) floods the 24 x 24 play area's
attributes with the room's colour, copies the half-extents to
`ROOM_HALF_WIDTH`/`ROOM_HALF_HEIGHT` ($5E1D/$5E1E) and draws the outline.

| Shape | Name (the build's) | Walk area from centre ($58, $68) | Rooms |
|---|---|---|---|
| $00 | square hall | 56 x 56 | 54 (+ entry $95) |
| $01 | cave | 40 x 40 | 31 |
| $02 | octagonal hall | 56 x 56 | 8 |
| $03 | wide hall | 56 x 24 | 16 |
| $04 | tall hall | 24 x 56 | 18 |
| $05 | staircase, head-on | 16 x 48 | 5 |
| $06, $07 | the same staircase, two more orientations | -- | none |
| $08 | staircase, side-on | 48 x 16 | 1 |
| $09 | cavern, wide | 48 x 24 | 8 |
| $0A | cavern, tall | 24 x 48 | 7 |
| $0B | passage | 56 x 56 | 1: room $8E, the way out |
| $0C | trapdoor fall | 56 x 56 | entry $96 |

(From the build's Room types page, which reads the table; *measured* there.)
Shapes share edge lists -- $00, $03 and $04 one; $05-$08 one; $09 and $0A one
-- so a wide or tall hall is the square hall's lines over other corners. The
play area is 192 pixels square; the walk area is the rectangle centre plus or
minus the half-extents, exclusive ([`collision.md`](collision.md)).

**Drawing the outline** (`DRAW_OUTLINE` $9C2F, *read*): the edge list is
groups of vertex numbers, a group's first vertex joined to each of the rest,
$FF ending a group and a second $FF the list. The vertex number is patched
into the displacement of `LD r,(IX+d)` before each fetch, and `DRAW_LINE`
($9C79) draws with a slope worked out by a shift-and-subtract division
(`DIVIDE_SLOPE`, $A379 -- see the corrections).

**The room lists** (*read*): `ROOM_CONTENTS` is 150 words (every room and the
black entry $95; the fall has none), each pointing at a $0000-ended list of
template addresses plus $757D. A door appears in the lists of both rooms it
joins, by the address of the half that belongs there; furniture pairs are
stored the same way ([`doors.md`](doors.md)). The lists run from $76A9 to
$7C18, the byte before `TITLE_SCREEN`.

**Visiting** (*read*): `ARRIVE_IN_ROOM` ($9147) sets the room's bit in
`ROOMS_SEEN` ($5E40, 19 bytes) by patching a `SET b,(HL)`; the end-of-game
figure is two per three rooms seen, plus one, so all 149 read 99 -- a
percentage ([`status-panel.md`](status-panel.md)).

**Floors and the map** (the build's `castle_floors` and `castle_layout`;
*measured* from the data, not from any game code): doors are placed on the
wall their +$05 says; a trapdoor drops a floor; each staircase (the six rooms
of shapes $05 and $08) rises from its door end to its big door frame, the
reading that leaves the fewest doors inconsistent. Starting from room $00
that gives five floors -- 5, 32, 42, 24 and 46 rooms -- and six doors that no
choice of floors satisfies, drawn as links elsewhere. The bottom floor is
all caves and caverns (31 + 8 + 7 = 46, exactly the cave shapes' rooms).
The map page draws each floor with every room's own picture.

**The starting room** (*read*; *measured*): `PLACE_PLAYER` puts the player in
whatever room $EA91 holds, which after `LOAD_INITIAL_STATE` is 0. Room $00 is
a red square hall on the middle floor, and holds the A.C.G. door.

## How this was found

Read `DRAW_ROOM`, `DRAW_OUTLINE`, `DRAW_LINE`, the room lists'
readers. The counts are from the snapshot and the build's generated pages
(Room types, Map). The table's length was the subject of a correction on
2026-08-30 ([`journal.md`](journal.md)).

## Confidence

The formats are *read*; the counts *measured* from the data. The floors are
the build's reading of the doors, not anything the game knows.

## Renamed routines

Applied to the annotations on 2026-09-27; the build verified byte for byte.

| New name | Old name | Address | Role |
|---|---|---|---|
| `DIVIDE_SLOPE` | `MULTIPLY_2` | $A379 | a line's slope |
| `PLOT_PIXEL` | `PIXEL_MASK` | $9C61 | `DRAW_LINE`'s plot |
| `TEST_ROOM_BOXES` | `POPULATE_ROOM` | $902B | the player's collision against doorways and tables |

## Disassembly corrections

All applied to the annotations, the ref and the build on 2026-09-27 (the old names are used below), except where marked.

- `ROOM_TABLE`'s annotation: "With 152 rooms sharing a much smaller set of
  outlines". The table has 151 entries and the castle 149 rooms (152 is the
  bit count of `ROOMS_SEEN`).
- `MULTIPLY_2` ($A379): "Another multiply... kept separately for the sound
  routines". Its only callers are `DRAW_LINE` ($9CA2, $9CE3), and it divides:
  eight rounds of shift, trial subtract and set a quotient bit, giving the
  shorter side over the longer as an 8-bit fraction -- the line's slope.
- `MULTIPLY` ($9AAD): "START_AT_LAST_ROW uses it ..., and DRAW_ROOM to index
  the six-byte shape entries". `DRAW_ROOM` multiplies by six with ADDs; the
  second caller is `DRAW_FOOD` ($8BB9).
- `PIXEL_MASK` ($9C61) does not only build a mask: it ORs the pixel into the
  screen. It is `DRAW_LINE`'s plot.
- `POPULATE_ROOM` ($902B) does not set a room up; see
  [`collision.md`](collision.md). The ref's "What is in a room" repeats it.

## Open questions

- Nothing in the game says which way a staircase goes; the floors are an
  inference.
