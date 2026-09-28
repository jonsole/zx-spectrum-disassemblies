# The town

**Question this answers:** how the town is stored -- the map, the cell
types, the buildings drawn on them, the boxes that stop things walking
through their walls, the tiles -- and how many cells a knight can reach.

**Short answer:** `TOWN` ($5E04) is a byte per cell, 32 rows of 32. A cell
is 0 (open ground), 1 or 2 (solid) or 3-35 (a type of building the knight
can walk into). Each type has two building definitions, one for each way
the town can be seen (`BUILDING_TABLE`, $62A4), each two faces of eight
columns of two tiles; and a list of boxes (`BOX_TABLE`, $6334) that are its
walls for movement. 625 of the 1024 cells can be stood in.

## How it works

| Table | Address | Layout |
|---|---|---|
| `TOWN` | $5E04-$6203 | a byte a cell; row = high byte of V, column = high byte of U; row *r*'s bytes at `TOWN` + 32*r* |
| `DRAW_ORDER` | $6204 | 32 records of five step bytes ([`drawing-order.md`](drawing-order.md)) |
| `BUILDING_TABLE` | $62A4 | 72 words, index type * 2 + the view (`VIEW` bit 0); 0 for open ground |
| `BOX_TABLE` | $6334 | 36 words, a box list per type |
| `BOXES0` ... | $637C-$6541 | box lists: four bytes a box -- centre U, centre V, half-size U, half-size V, in half units, the cell spanning 64-191 -- ended by 0 |
| `TILE_EDGES` | $6542 | a byte per tile: the edge picture drawn under it |
| `BUILDING14` ... | $6576-$6CB5 | 58 building definitions of 32 bytes: two faces of eight columns, each a lower and an upper tile number |
| `TILE_TABLE` | $6E36 | 52 words, tile number to tile |
| `EDGE_TABLE` | $6FDC | 4 words, edge number to picture (0 and 1 the same) |
| `EDGE0`, `EDGE2`, `EDGE3` | $6FE4-$7016 | 3 edge pictures in the tiles' format |
| `TILE0` ... | $A257-$BB09 | 51 tiles (tile 42 uses tile 0's): a height, 56 or 64, then two bytes a row, bottom row first |

- **The cell types** (*measured*, counted on the map): 346 cells of open
  ground, 398 of type 1, one of type 2 (column 28, row 16), and 279 of
  types 3-35. 1024 - 398 - 1 = 625 cells a knight can be in: the count the
  percentage is built on ([`percentage.md`](percentage.md)). Types 11 and
  26 appear nowhere on the map, so their buildings (`BUILDING22`,
  `BUILDING23`, `BUILDING52`, `BUILDING53`) are never drawn
  ([`leftovers.md`](leftovers.md)).
- **Solid cells.** Types 1 and 2 are the ones the random choices skip -- the
  start cell, the objects' and villains' cells, a monster's or a bonus's
  cell. Both have buildings (type 1 the block the town is mostly walled
  with) and the same box list, `BOXES1`: four thin boxes along the cell's
  edges, a wall on each side, so nothing walks in. What makes type 2
  different from type 1 is only its picture.
- **Buildings.** A definition describes the two faces that view sees -- the
  near edges of the cell's diamond -- so the other view's definition is the
  same building's other two faces. The labels are by the first table entry
  that reaches each: `BUILDING14` is type 7 seen the usual way. Several
  types share definitions.
- **Boxes** are what movement tests against
  ([`collision.md`](collision.md)); nothing else about a building stops a
  move. A doorway is a gap between a face's boxes (`BOXES7`, for one, has
  two short boxes on a face where `BOXES1` has one long one), and the tiles
  over it are archway tiles whose edge picture leaves a gap in the outline
  too (*read* from the lists; which box gap matches which archway was not
  checked tile by tile).
- **Finds.** `STOCKS` ($BBCE) gives each cell type (2-35) 16-31 finds at
  every new game, shared by every cell of that type
  ([`finds-and-bonuses.md`](finds-and-bonuses.md)); the kind of antibody a
  type gives is its low two bits.
- **Turned round**, the map is read backwards: cell (*c*, *r*) seen from the
  other side is (31 - *c*, 31 - *r*) ([`projection.md`](projection.md)).

## How this was found

Stage 1: `scripts/nightshade_data.py` walks each table the way the code
reads it and stops the build if a table does not tile its range; the
per-record lines (each building with its tiles, each box, each tile's
picture) are in the listing. Stage 2 read the users: `LOOK_UP_CELL`
($D564), `DRAW_WALLS` ($D372), `DRAW_OUTLINE` ($D19D), `PLACE_IN_CELL`
($E028). The cell-type counts and the unused types were counted on the
snapshot's map for these notes (a scratch script over `TOWN`).

## Confidence

The formats *read* and every table's extent *measured* by the generator.
The counts *measured*. That type 2 differs from type 1 only in its picture
is *read* (same box list, both skipped as solid); how it looks is for the
map page.

## Filmation (Knight Lore, Alien 8, Pentagram)

Nothing like it: the earlier games are rooms built from templates of
blocks, each block an object with a sprite, sorted and collided like any
other. Nightshade's town is a map of cell types, drawn from tiles and
collided against per-type boxes; only the things moving in it are objects.

## Also found for the stage 3 pages (2026-09-28)

- Buildings are rooms: a cell type's boxes are thin walls along the cell's edges with gaps for doorways, and the knight walks inside; only types 1 and 2 are closed on four sides. Finds come only when his own cell is built on -- inside a building (*read*, *measured* for the how-it-works pages).
- Every standable cell can be walked to from every other: of 1984 cell edges 738 are open, one region, and the knight was walked across all 1092 edges between cells he can be in and crossed exactly the 738 (*measured*, the town page's build).
- Type 1 (398 cells) is the solid ring round the town and the blocks inside it; type 2 is one solid cell at column 28, row 16, which still gets a stock of 16-31 finds nothing can take; types 11 and 26 have buildings and boxes but no cell on the map (*measured*).
- Wall ink is $44 OR (type AND 3) -- green, cyan, yellow, white -- read back from the attribute buffer; the same two bits give a cell's find, the antibody it becomes, and so which villain's monsters it can destroy (*measured*, checked in the code bytes by the how-it-works build).

## Open questions

- What the single type-2 cell is, on the map page (stage 3's town map will
  show it).
- Why types 11 and 26 were left in the tables: cut from the map late, or
  kept for a variant? Nothing in the code says.
