# Drawing the view

**Question this answers:** how a frame of the city, with the people, the ants
and the grenade in it, gets onto the screen -- the projection, the order
things are painted in, and what makes it cheap enough.

**Short answer:** `DRAW_VIEW` ($84A0) redraws the whole view every frame, in
an off-screen render buffer, by a painter's algorithm done with tables. The
map is read along diagonals into `VIEW_CELLS`; `BUILD_PLANES` turns that into
`PLANES`, 512 screen slots each holding the height of the one block seen
there (a block hidden behind a taller one on screen is never drawn at all);
the objects are projected into the same slots; and `DRAW_SCENE` paints the
slots height by height with CPIR, threading the sprites in by counting. The
block is a routine that paints itself. Rows 12-127 of the buffer are then
copied to the screen.

## How it works

```
DRAW_VIEW $84A0
  GATHER_VIEW $83B0            the map along diagonals -> VIEW_CELLS $B180 (21 x 32)
    GATHER_VIEW0-3 $8681...    one per view, the same with the signs turned
      READ_MAP_CELL $8380      outside the walls -> 0
  BUILD_PLANES $81B0           CLEAR_PLANES ($FF), then MARK_PLANE x 6 -> PLANES $B500
  CLEAR_BUFFER_ROWS $8300 x 4  rows 12-127 of RENDER_BUFFER $A000, every fourth row a call
  PROJECT_SPRITES $8600        each object -> a place and a frame in SPRITE_LIST $B450
  SCROLL_VIEW $8460            player near the edge -> move VIEW_ORIGIN (shows next frame)
  SORT_SPRITES $8580           bubble sort by place
  SPRITE_DISTANCES $85D0       places -> gaps between them
  SELECT_BLOCK_DRAWER $8570    IY = DRAW_BLOCK (views 0, 2) or DRAW_BLOCK_TURNED (1, 3)
  DRAW_SCENE $8500             7 passes of CPIR over PLANES; blocks via JP (IY),
                               sprites via DRAW_HERE -> DRAW_SPRITE $80A0
  COPY_TO_SCREEN $8100         rows 12-127, bytes 1-30 -> the screen
```

(*read*; all *played*.)

**The view and its origin.** Four views, one per key (0, P, ENTER, SPACE ->
views 3, 2, 1, 0; `READ_VIEW_KEYS`), each looking at the city from a
different corner. `VIEW_ORIGIN` ($B420) is the map cell the gather starts
from; choosing a view re-centres it on the player less a per-view offset.
The facing and the projected position are turned for the view, so the same
record is drawn facing the right way from any corner (*read*).

**Gathering** (`GATHER_VIEW0`, *read*): 21 rows; each row is 16 cells along a
diagonal (x + 1, y + 1 each step) and 16 more from the cell beside the start,
and each row starts one cell further back. That is 672 bytes -- the 512 cells
of the visible slots plus five more rows, because a block at height h is read
h rows further on (below). The other views swap and negate the steps.

**Planes: one height per slot** (`BUILD_PLANES`, `MARK_PLANE`, *read*). A
block one higher is drawn one slot-row further up the screen, so for height h
`MARK_PLANE` reads the gathered cells 32h bytes on and writes the height's bit
($01 for 0 up to $20 for 5) into every slot whose cell has that bit. Heights
go lowest first, so a higher block overwrites a lower one in the same slot --
and since a slot is exactly one block's picture, the lower block would be
completely covered: it is simply never drawn. `PLANES` ends up as, for each
slot, the one height of block to paint there, or $FF for none.

**Slots on the screen** (`PLANE_TO_BUFFER`, *read*; the annotation says it was
also measured by running it): 32 half-rows of 16 slots, each slot 16 pixels
wide; the two half-rows of a row are offset by 8 pixels across and 4 down, so
the slots interlock like bricks, and a whole row of slots is 8 pixel rows.

**Projecting the objects** (`PROJECT_SPRITES`, *read*). For each object, last
to first: (u, v) = its position less the view origin, 8-bit, turned for the
view; with h its height, the half-row is v - u - 2h and the column (u + v)/2,
either out of range (or overflowing) meaning out of view -- a place of $FFxx,
past anything the painter reaches (`OFF_VIEW`). The place is h x 512 +
half-row x 16 + column, plus one, and the frame is chosen as in
[`objects.md`](objects.md). The list is then sorted and turned into gaps.

**Painting** (`DRAW_SCENE`, *read*): seven passes, for the bits $01, $02 ...
$40. Each pass plants its own bit in the last slot as a sentinel and CPIRs
from the first slot. BC is not the length of `PLANES` but the gap to the next
sprite, carried across passes. So CPIR stops for one of three reasons: it
found a block of this height (draw it by `JP (IY)`; the drawer jumps back to
`BLOCK_DRAWN`), it found the sentinel (next pass), or BC ran out -- which
means the next sprite is due, at the slot just before, and `DRAW_HERE` draws
it and loads the next gap. Because a sprite's place counts h whole passes of
512, a sprite at height h is painted in pass h: after every block of a lower
height, and among the blocks of its own height in scan order (back to
front). The seventh pass, $40, has no blocks: it is there for anything
standing on top of a six-high column.

**The block is code** (`DRAW_BLOCK` $8203, `DRAW_BLOCK_TURNED` $8703,
*read*). Eight steps, each painting one pixel row of the block's outline
(two bytes, masked into what is already there so the background shows beside
the sloping edges) and, eight rows below, one row of the solid dithered faces
outright: a 16 x 16 block from 8 unrolled steps. The two drawers differ in
shading, since a quarter turn swaps the light and dark faces. Each ends by
jumping back into `DRAW_SCENE`. Each is entered three bytes in: the three
bytes before it (in the `_PAD` filler) are `LD DE,31`, its "first
instruction", never run because `DRAW_SCENE` has set DE already
([`leftovers.md`](leftovers.md)).

**Sprites** (`DRAW_SPRITE` $80A0, *read*): frame f is 64 bytes at
$8000 + 64f, 16 rows of mask, graphic, mask, graphic; each byte of the buffer
is ANDed with the mask and ORed with the graphic. The frame number *is* the
address, which puts the two sprite banks where the memory map had room:
frames $68-$7F (the grenade's own and the girl) at $9A00-$9FFF, and $DC-$FF
(the boy, the grenade in flight, the ants) at $B700-$BFFF. Every frame is an
entry of its own in the listing from 2026-09-27 (`FRAMEnn`); the Sprites page
draws them.

**Clearing and copying** (*read*). `CLEAR_BUFFER_ROWS` clears 29 rows, four
apart, from a starting row that `CLEAR_PHASE` ($B44F) moves on each call, so
`DRAW_VIEW`'s four calls clear rows 12-127 -- the rows `COPY_TO_SCREEN`
copies to screen lines 12-127, bytes 1-30 (a play area of 240 x 116 pixels).
The buffer's other rows and its first and last columns are margins that
blocks and sprites can overhang into. The whole view is redrawn and copied
every frame; nothing is kept from the last.

**Scrolling** (`SCROLL_VIEW`, *read*): from the player's place this frame, if
the column is outside 4-11 of 16 or the half-row outside 8-23 of 32, the
origin moves one cell the way the player is facing -- unless the player is
jumping or falling. The gather has already happened, so the scroll shows next
frame; the view trails a walking player by a cell at the edge of the window.

## How this was found

Read `DRAW_VIEW` and each routine in turn. The annotations record two runs made
while writing them: `COPY_TO_SCREEN` with the buffer's rows filled with their
own numbers, and `PLANE_TO_BUFFER` over a range of places. The whole-city
picture on the City page is `DRAW_BLOCK` run on its own, twice (on a cleared
and on a filled buffer, to tell the block's pixels from the background), and
placed by the same projection.

## Confidence

The pipeline is *read* and runs every frame of the playthrough (*played*).
The costs are in [`performance.md`](performance.md) (*measured*).

## Also found for the how-it-works pages (2026-09-27)

- An ant is a block at its own place in PLANES: the sprite place's "+1" makes CPIR's count run out on that same byte, and running out wins (JP PO), so the sprite is drawn instead of the block. Four ants' places held $01 and no block was drawn there (*measured*, the Drawing page's traced frame).
- A whole frame came to about 548k T-states over 32 frames, 6.4 frames a second, drawing measured over 24 views -- in line with [performance.md](performance.md) (*measured*, no contention).

## Open questions

- Whether the pass order ever draws a sprite wrongly: a sprite at height h is
  painted before every block at height h + 1 and above, including one that is
  behind it but overlaps its top on screen. Not worked through or looked for
  in pictures.
- The sentinel overwrites the last slot of `PLANES` in every pass, so a block
  there is never drawn; whether that slot is ever on the copied part of the
  screen was not checked.
