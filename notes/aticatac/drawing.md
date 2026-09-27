# Drawing

**Question this answers:** how a room, its furniture and the things moving
in it get on the screen, and how the game keeps colours from clashing.

**Short answer:** a room is an attribute flood in its colour and a vector
outline. Doors and furniture are wide graphics drawn once per visit in one of
eight orientations -- the four ways to flip a picture and the same four
turned through a right angle -- with a colour table per graphic whose $00
means "leave the cell" and $FF "the room's colour"; their colours are
repainted every pass. Creatures, objects and the player are sixteen-pixel
sprites XORed on at any pixel x through an unrolled shift chain; each is
erased at its old place and drawn at its new one row by row, interleaved, and
its attribute cells are painted in its colour while the cells it has just
left are given back the room's.

## How it works

**The room** (*read*): `CLEAR_PLAY_AREA` ($8093) blanks the 24 columns of the
play area; `DRAW_ROOM` ($9BEA) fills its 24 x 24 attributes with the room
colour and draws the outline pixel by pixel (`DRAW_LINE`, OR into the
screen); `PAINT_PANEL` ($A240) recolours the scroll to match
([`status-panel.md`](status-panel.md)).

**Two graphics formats** (*read*; the second found by comparison with
pobtastic's disassembly, 2026-08-30). `SPRITE_TABLE` ($A4BE) is three tables
end to end: 161 creature and object pictures (codes 1-161), then from $A600
39 furniture graphics, then from $A64E 39 colour tables, entry for entry with
the furniture. A creature picture is a height byte and that many rows of two
bytes, bottom row first. A furniture graphic and its colour table each start
with a width in bytes and a height, in pixel rows for the graphic and in
cells for the colours.

**Furniture and doors** (*read*). `DRAW_DOOR` ($91FE) calls
`DRAW_SPRITE_COLOURS` every pass, and on the first pass in the room only
(`ROOM_DRAWN` clear) `DRAW_SPRITE_PIXELS` as well. Both take the record's
type as the graphic number and the top three bits of +$05 as a mode, and jump
through a table of eight routines (`PIXEL_DRAWERS` $9970, `COLOUR_DRAWERS`
$9985) by way of the `JP (HL)` at $5CB0:

| Mode | Pixels | Colours | The picture |
|---|---|---|---|
| 0 | `BLIT_SPRITE` $99C9 | `COLOURS_AS_STORED` $9D25 | as stored |
| 1 | `BLIT_SPRITE_MIRRORED` $99E5: each row read backwards, each byte bit-reversed (`REVERSE_BITS`) | `COLOURS_MIRRORED` $9D47 | mirrored |
| 2 | `DRAW_TURNED_RIGHT` $9A0A: each screen byte gathered from one bit of eight successive rows, starting at the right-hand column | `COLOURS_TURNED_RIGHT` $9D6F | turned a quarter clockwise |
| 3 | `DRAW_FLIP_ANTIDIAGONAL` $9A50: the same from the left-hand column | `COLOURS_FLIP_ANTIDIAGONAL` $9DA0 | mirrored across the bottom-left to top-right diagonal |
| 4 | `DRAW_UPSIDE_DOWN` $9ACB: from the last row back (`START_AT_LAST_ROW`) | `COLOURS_UPSIDE_DOWN` $9DCE | upside down |
| 5 | `BLIT_SPRITE_FLIPPED` $9AEF: mirrored and upside down | `COLOURS_HALF_TURN` $9DF8 | a half turn |
| 6 | `DRAW_FLIP_DIAGONAL` $9B14: mode 2's gathering, rows read top down | `COLOURS_FLIP_DIAGONAL` $9E21 | mirrored across the top-left to bottom-right diagonal: a transpose |
| 7 | `DRAW_TURNED_LEFT` $9B5D: mode 3's gathering, rows read top down | `COLOURS_TURNED_LEFT` $9E55 | turned a quarter anticlockwise |

(Modes 2, 3, 6 and 7 are now *measured*: the how-it-works build drew the suit
of armour and a door through each drawer and matched the result pixel for pixel
against the eight symmetries of the stored picture. That showed the diagonals
the other way round from the old names, so mode 3's routines are now
`DRAW_FLIP_ANTIDIAGONAL` / `COLOURS_FLIP_ANTIDIAGONAL` (were `DRAW_TRANSPOSED` /
`COLOURS_TRANSPOSED`) and mode 6's `DRAW_FLIP_DIAGONAL` / `COLOURS_FLIP_DIAGONAL`
(were `DRAW_ANTI_TRANSPOSED` / `COLOURS_ANTI_TRANSPOSED`). Modes 1 and 6 appear in
no template record. The last column was first worked out on 2026-09-27 by following where each loop
puts the source's corners: in mode 2 the source's bottom edge, its first row,
becomes the left edge and its right-hand column the bottom row; *read*. The
colour drawers walk their tables in the same orders.)

So one door graphic serves every wall: a door's orientation is its wall
(0 north, 4 south, 3 east, 7 west in the data) and bit 6 -- set for the
transposed modes -- is also what `PLAYER_AT_DOOR` reads as "in a side wall".
The low two bits of +$05 choose how pixels meet the screen, written by
`SPRITE_COMBINE_OPCODE` ($9D19) over a NOP in each drawer's loop: 0 plain
store, 1 OR, 2 or 3 XOR. A colour-table byte of $00 leaves the cell alone,
$FF writes the room's colour, anything else is written as it is; the four
locked doors are one graphic with four colour tables.

**Creatures, objects, the player** (*read*). A handler starts with
`ACTOR_TO_WORKSPACE`, saving x, y and sprite in `WORK_X`, `WORK_Y`,
`WORK_SPRITE` ($5E16, $5E17, $5E15), moves the record, and ends at
`REDRAW_ACTOR` ($8E8E):

```
REDRAW_MOVED $9FCA
  SETUP_SPRITE_DRAW $9F9F   new place: screen address, graphic, height;
                            patch DRAW_JR's displacement with 2 x ((x-1) AND 7)
  SETUP_ERASE $9F80         (other register bank) old place, old sprite; patch ERASE_JR
  ALIGN_ROWS $9FD1         old y - new y: first erase (or draw) the rows the
                            two do not share, then
  ERASE_DRAW_ROWS $9E9B           alternately erase one row of the old and draw one of the new,
                            bottom up, each through SHIFT_CHAIN / SHIFT_CHAIN_2 and XOR
DRAW_FROM_RECORD $A01A      the attributes
```

A row is two bytes loaded into HL and shifted left through A by jumping part
way into seven unrolled `ADD HL,HL / ADC A,A` pairs, so no counter is kept;
the three resulting bytes are XORed onto the screen, and drawing a thing
twice rubs it out. Doing the erase and the draw a row at a time, aligned on
the same screen lines, keeps the gap between a row vanishing and reappearing
short. `DRAW_THING` ($9F4A) and `ERASE_THING` ($9F56) are the same loop with
one side's count zero.

**Colours for moving things** (`DRAW_FROM_RECORD`, *read*): the block is two
cells wide (three when x is not on a cell boundary) and as tall as the
sprite; D is the thing's +$05, E the room colour. Comparing the old and new
position picks one of nine fillers from `COLOUR_FILLERS` ($A064) -- still,
right, left, down, up and the four diagonals -- each of which paints the
block in D and the column or row the thing has just moved out of in E. So a
creature carries its colour with it and leaves the room's behind; where two
overlap, the last painted wins.

**Panels and text** use a third path: `PLOT_TILE` ($A1D3) copies eight-byte
characters from a tile source whose base is repointed -- the text font less
$100, the digits, or the panel's own tile set
([`status-panel.md`](status-panel.md)).

## How this was found

Read the two drawer tables and all sixteen entries, `DRAW_DOOR`,
`REDRAW_MOVED` and the loop from $9E9B to $9FF8, `DRAW_FROM_RECORD` and its
fillers. The earlier history of these formats -- three sprite tables
mistaken for one, furniture read as sprites, pictures upside down -- is in
[`journal.md`](journal.md) and `docs/game-examples.md`.

## Confidence

*Read*. The rotations were derived from the loops, not drawn out.

## Renamed routines

Applied to the annotations on 2026-09-27; the build verified byte for byte.

| New name | Old name | Address | Role |
|---|---|---|---|
| `REDRAW_MOVED` | `DRAW_CLIPPED` | $9FCA | set up the erase and the draw and interleave them |
| `ERASE_DRAW_ROWS` | `CLIP_ROWS` | $9E9B | the interleaved row loop |
| `ALIGN_ROWS` | `CLIP_BOTTOM` | $9FD1 | does the rows the old and new pictures do not share |
| `ROWS_TOGETHER`, `ROWS_TOGETHER_SWAP`, `ROWS_DRAW_ONLY` | `CLIP_TOP`, `CLIP_SWAP`, `CLIP_STORE` | $9EB5, $9EB4, $9EC8 | entry points of the loop |
| `ERASE_ROWS`, `DRAW_ROWS` (equates) | `CLIP_COUNT`, `CLIP_LIMIT` | $5E18, $5E19 | rows still to erase and to draw |
| `ERASE_SHIFT_CHAIN` | `SHIFT_CHAIN_2` | $9EE6 | the erase path's shifts |
| `ERASE_UNSHIFTED`, `DRAW_UNSHIFTED` | `PLOT_XOR`, `PLOT_XOR_2` | $9ECE, $9F13 | where the patched jumps land when no shift is needed |
| `DRAW_TURNED_RIGHT`, `DRAW_FLIP_ANTIDIAGONAL`, `DRAW_UPSIDE_DOWN`, `DRAW_FLIP_DIAGONAL`, `DRAW_TURNED_LEFT` | `DRAW_PIXELS_2`, `_3`, `_4`, `_6`, `_7` | $9A0A, $9A50, $9ACB, $9B14, $9B5D | furniture pixels in modes 2, 3, 4, 6, 7 (and their `_OP` labels) |
| `COLOURS_AS_STORED` ... `COLOURS_TURNED_LEFT` | `DRAW_COLOURS_0` ... `_7` | $9D25-$9E55 | furniture colours in the eight modes |
| `COLOUR_FILLERS` | `FILL_HANDLERS` | $A064 | the nine attribute fillers, by direction of movement |
| `COLOUR_STILL`, `COLOUR_MOVED_RIGHT`, `COLOUR_MOVED_LEFT`, `COLOUR_MOVED_DOWN`, `COLOUR_MOVED_DOWN_RIGHT`, `COLOUR_MOVED_DOWN_LEFT`, `COLOUR_MOVED_UP`, `COLOUR_MOVED_UP_RIGHT`, `COLOUR_MOVED_UP_LEFT` | `FILL_ATTRS`, `FILL_ATTRS_BACK`, `FILL_ATTRS_2`, `FILL_ATTRS_3`, `FILL_ATTRS_ALT`, `FILL_ATTRS_4`, `FILL_ATTRS_ROW`, `FILL_ATTRS_ROW_3`, `FILL_ATTRS_ROW_2` | $A07A, $A08D, $A0A3, $A0B7, $A0D2, $A110, $A0EC, $A127, $A0FE | the fillers |
| `PLOT_PIXEL` | `PIXEL_MASK` | $9C61 | `DRAW_LINE`'s plot |

## Disassembly corrections

All applied to the annotations and the ref on 2026-09-27 (the old names are
used here).

- The annotations at `BLIT_SPRITE_FLIPPED` and the ref's "Eight ways to draw a
  sprite" said the eight modes are four orientations -- as stored, mirrored,
  upside down, both -- each twice. Modes 2, 3, 6 and 7 turn or transpose the
  picture; the eight are the eight symmetries of a rectangle. The titles of
  `DRAW_PIXELS_2`, `_3` ("the right way up") and `_6`, `_7` undersold them.
- The eight modes are used only for furniture and doors (through
  `DRAW_DOOR` / `DRAW_RECORD`); creatures are drawn by `DRAW_THING` and friends,
  for which +$05 is simply the attribute. The ref's "a creature that faces
  four ways is one set of bytes and a number in +$05" did not hold: the
  characters' and creatures' headings are separate pictures.
- `CLIP_ROWS` ("Draw only the rows that fit ... rather than letting the
  blitter run past the end of the play area") and `DRAW_CLIPPED` ("Draw a
  sprite that may not fit"): nothing is clipped against the play area. The
  two register banks hold the erase of the old position and the draw of the
  new, and the loop interleaves them.
- `FILL_ATTRS_ALT` ("Writes from E rather than D, so a sprite ... comes out in
  its alternate colour") and its neighbours ("for a different drawing mode"):
  they are chosen by the direction of movement, not a drawing mode, and E is
  the room colour, written into the vacated column or row.
- The ref's Data page said "A few hundred bytes scattered through the region
  are pictures that nothing points at", which its own Fact "Code and data that
  nothing reaches" contradicts; and "all 235 that draw read exactly one plus
  twice the row count" was the retracted measurement that read furniture as
  sprites. Both reworded. (Its "fourteen graphics below $AD2E" was not
  re-checked and is left.)
- `PIXEL_MASK` also plotted the pixel; now `PLOT_PIXEL`.

## Also found for the how-it-works pages (2026-09-27)

- `DRAW_FROM_RECORD`'s colour block can be a cell short: the knight is 18 rows tall and gets three cells of colour, so at y $88, straddling four cells, his top line stays in the room's colour (two pixels seen) (*measured*).
- A room's arrival costs about 1.56M T-states, 40% of it the outline and 342k the A.C.G. door alone; a pass of ordinary play about 165k, 35% of it the player's, led by `TEST_ROOM_BOXES` (*measured*, no contention).

## Open questions

- Draw a door graphic in modes 2, 3, 6 and 7 to confirm the rotations by eye.
