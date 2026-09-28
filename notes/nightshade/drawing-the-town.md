# Drawing the town

**Question this answers:** how Nightshade draws a town of solid buildings
round a knight who must never be hidden by them -- what is drawn as walls
and what as an outline, how one wall hides another, and how the colour is
laid.

**Short answer:** only the nine cells round the knight can be on the
screen. The buildings behind him are drawn as solid walls of tiles, nearest
first, each column of wall claiming the 16-pixel screen column it covers so
nothing further back is drawn there; the buildings in front of him (his
own cell and the three nearer the viewer) get only the line where their
walls meet the ground. A wall is two tiles high and its colour runs from
its foot to the top of the play area. There is no sorting of walls at all.

## How it works

The play area is `BUFFER` ($E5C4), 112 lines of 24 bytes whose lines run
**up** the screen ([`drawing-sprites.md`](drawing-sprites.md)); the drawing
y is $48 at the bottom of the play area and $B7 at the top.

```
DRAW_CELLS $CF08  (the order: drawing-order.md)
  +-- DRAW_WALLS $D372         a cell behind him: two faces of 8 columns
  |     +-- DRAW_WALL_COLUMN $D3C2   claim the screen column, or skip it
  |           +-- PUT_TILE $D425     lower tile (CLIP_TILE $D415 below the bottom)
  |           +-- COLOUR_WALL $D356  attributes up to the top (COLOUR_STRIP $C889)
  |           +-- PUT_TILE           upper tile, 64 lines up
  +-- DRAW_OUTLINE $D19D        a cell in front: the edges of all four faces
  |     +-- OUTLINE_NEAR_FACES $D1FA / OUTLINE_FAR_FACES $D1B5
  |           +-- DRAW_EDGE $D273 -> PUT_EDGE $D2B2 (CLIP_EDGE $D2A2)
  +-- LIST_THINGS_IN_CELL $CFAF + SORT_AND_DRAW_THINGS $CFF2 (depth-order.md)
```

- **Walls.** `DRAW_WALLS` looks up the cell's definition (`BUILDING_TABLE`,
  type * 2 + view, [`town.md`](town.md)), projects the cell's corner
  (`PROJECT_CELL`, $D508), and steps a column at a time 16 pixels right and
  8 lines down along the first face (`STEP_RIGHT_DOWN`, $D250), then up 8
  and 16 right and 8 up along the second (`STEP_RIGHT_UP`, $D22D), which is
  drawn mirrored (`DRAW_PASS` = 1).
- **Column claims.** A tile is written over the buffer, not masked
  (`PUT_TILE` keeps only the pixels outside the tile's 16, by `TILE_MASKS`
  $D4EF patched into four ANDs, `TILE_MASK_FIRST` $D47B and its siblings),
  and a wall reaches from its foot to the top of the play area, so once a
  column of wall is drawn nothing behind it there could show.
  `COLUMNS_DRAWN` ($BBBB) has a bit per 16-pixel screen column;
  `DRAW_WALL_COLUMN` patches the column's bit into a `BIT` at `TEST_COLUMN`
  ($D3E2) and a `SET` at `CLAIM_COLUMN` ($D3E6), skips a claimed column,
  and claims and draws a free one. The turn starts with $E001 (the columns
  off the buffer's sides claimed), so the claims clip at the sides too, and
  `DRAW_WALLS` stops as soon as all sixteen are claimed. The cells' corners
  are 128 pixels apart, so every column of wall lines up with a screen
  column.
- **Tiles.** A height byte (56 or 64) and two bytes a row, bottom first,
  read with SP (the real SP in `SAVED_SP`; interrupts are never on). x's
  bits 1-2 give the shift (bit 0 ignored); a shifted row covers three buffer
  bytes through a pair of pages built by `MAKE_TABLES` ($E0FB) --
  `SHIFT_TABLES` ($FA00) for the first face, `MIRROR_TABLES` ($F200), which
  also reverse the bits, for the mirrored second face; an aligned mirrored
  row goes through `REVERSE_TABLE` ($F900). Rows above the top are cut,
  rows below the bottom skipped (`CLIP_TILE`, `CLIP_EDGE`).
- **Colour.** `COLOUR_WALL` fills two attribute bytes a row from the row of
  the lower tile's foot to the top: bright ink 4-7 (green, cyan, yellow,
  white) by the low two bits of `CELL_TYPE` ($BBC0), on this turn's paper
  (`LAST_FLASH`, $BBFC -- black, or the colour a dying villain flashes).
  When the column is in a row's last byte the pair runs one byte past its
  row: into the next row's hidden margin, or on the top row into
  `ATTR_SPILL` ($F194).
- **Outlines.** For the four front cells, `DRAW_OUTLINE` draws the edge
  picture under every column of all four faces: the near two from this
  view's definition (`OUTLINE_NEAR_FACES`), left to right, and the far two
  from the other view's definition, right to left from the far corner
  (`OUTLINE_FAR_FACES`, stepping with `EDGE_LEFT_UP` and `EDGE_LEFT_DOWN`).
  `TILE_EDGES` gives each tile its edge picture through `EDGE_TABLE`: 0 and
  1 a plain diagonal line 16 pixels long, 2 and 3 a stub at one end, for the
  archway tiles, so a doorway leaves a gap in the outline. On the far faces
  C = 1 is XORed in, swapping 2 and 3, since those faces are seen from
  behind. Edges are ORed in and claim no columns.

## How this was found

Read `$CF08`-`$D4EF` and the copy routines (stage 2, range 3). The first
reading had the screen upside down: y = (V - U) / 4 + 108 put further back
lower on the screen, contradicting the depth table; `COPY_BUFFER` ($E148)
settled it -- buffer row 0 goes to screen line 127. Then in the simulator
(the build's `Machine`, the knight moved by `_go`): screenshots at cells
chosen by their neighbours; the same scene with `DRAW_OUTLINE`'s first byte
made a `RET` (the lines in front of him vanish) and with `DRAW_WALLS`' (the
walls behind him vanish); a stop at `COLOUR_STRIP` from `COLOUR_WALL`, 752
times over 25 random cells (28 fills reached the byte past the attribute
buffer, all at the right-hand edge); a stop at `COLOUR_WALL`, 877 times over
25 more (wall feet from line 126 to 222, x from 19 to 207). The tiles and
edges drawn with the build's `tile_image`.

## Confidence

*Read*: the whole mechanism. *Measured*: which routine draws walls and
which outlines; the colour fill's reach; the range of wall feet.
*Inferred*: that C = 1 on the far faces is there because they are seen
from behind (the stubs' pictures fit; no archway outline was compared with
its wall on screen).

## Filmation (Knight Lore, Alien 8, Pentagram)

In the earlier games walls and blocks are sprites like everything else,
sorted in three dimensions and drawn into a buffer whose lines also count
up from the bottom. Nightshade keeps the buffer, the SP-read rows and the
shift and reverse pages (the same idea as Alien 8's tables at $CFA7, laid
out differently) but draws the town from tiles that are never sorted:
occlusion between buildings is the column claim, and the knight is never
hidden because what stands in front of him is only an outline. There is no
height at all.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `DRAW_OUTLINE` | `SUBD19D` | $D19D | a building in front: its outline |
| `OUTLINE_FAR_FACES` | (new label) | $D1B5 | its far two faces |
| `OUTLINE_NEAR_FACES` | `SUBD1FA` | $D1FA | a definition's two faces as edges |
| `STEP_RIGHT_UP`, `EDGE_RIGHT_UP`, `STEP_ACROSS` | `SUBD22D`, `SUBD232`, (new) | $D22D, $D232, $D239 | a column right and up |
| `EDGE_RIGHT_DOWN`, `STEP_RIGHT_DOWN` | `SUBD24B`, `SUBD250` | $D24B, $D250 | a column right and down |
| `EDGE_LEFT_UP`, `STEP_BACK`, `EDGE_LEFT_DOWN` | `SUBD255`, (new), `SUBD26E` | $D255, $D258, $D26E | a column left |
| `DRAW_EDGE`, `CLIP_EDGE`, `PUT_EDGE` | `SUBD273`, `SUBD2A2`, `SUBD2B2` | | one column's edge picture |
| `COLOUR_WALL` | `SUBD356` | $D356 | a wall column's attributes |
| `DRAW_WALLS`, `DRAW_WALL_COLUMN` | `SUBD372`, `SUBD3C2` | | a building behind: its walls |
| `TEST_COLUMN`, `CLAIM_COLUMN` | (new labels) | $D3E2, $D3E6 | the patched `BIT` and `SET` |
| `CLIP_TILE`, `PUT_TILE`, `TILE_MASKS` | `SUBD415`, `SUBD425`, `DATAD4EF` | | a tile of wall |
| `COLOUR_STRIP` | `SUBC889` | $C889 | two cells wide, B rows of attributes |

## Disassembly corrections

- `ATTR_SPILL` ($F194) was described as written "when a building's colour
  runs down to the bottom of the play area". The attribute rows run up the
  screen; it is written when a wall column in a row's last byte is coloured
  up to the top row -- the top right-hand corner (*measured*, 28 of 752).

## Also found for the stage 3 pages (2026-09-28)

- The pre-claimed columns ($E001 in COLUMNS_DRAWN) also keep walls inside the buffer: with the claim test NOPped out, tiles went to x 0, 224 and 240, wrapping into the next row and off the top into the attribute buffer's first row (*watched* instruction by instruction).
- Every lower tile is 64 lines high and every upper tile 56, so a wall is 120 lines tall (*measured*, the graphics page).
- A turn is about 12 a second (7.7 to 20 over 392 turns in 49 cells); drawing is about 59% of it, and the buffer copy a fixed 80,759 T-states. There is no pacing: no HALT, no EI (*measured*, the how-it-works page).

## Open questions

- A wall column is claimed before its y is checked, so a column whose foot
  is off the 0-255 range claims its screen column without drawing. Whether
  that ever hides anything was not looked for.
- The upper tile is drawn only when its line is under 256; nothing else
  checks it against the play area's top but `PUT_TILE` itself. Harmless as
  far as read.
