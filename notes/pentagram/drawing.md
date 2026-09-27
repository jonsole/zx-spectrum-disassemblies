# Drawing

**Question this answers:** how an object's position becomes a picture on the
screen without flicker -- the projection, the buffer, turning a shared sprite,
drawing it through its mask, and copying only what changed.

**Short answer:** Knight Lore's renderer, nearly unchanged. `CALC_PIXEL_XY`
projects U, V, Z to a pixel x and y (with a clamp at the left edge Knight
Lore lacks); `FIND_SPRITE` turns a shared sprite in place to face the way its
object wants; `RENDER_DYNAMIC_OBJECTS` clears, in an off-screen buffer, the
area old-and-new of everything that moved, draws the marked objects there in
depth order, and copies only those areas to the screen. The room itself is
never redrawn after its first turn.

## How it works

One turn's drawing, from the end of the main loop (`OBJECT_DONE` $B00C):

```
update routines        a mover ends in SET_WIPE_AND_DRAW_FLAGS ($CCDE, the tail of HOMER):
                       bits 4+5 of +$07, then SET_DRAW_OBJS_OVERLAPPED $B9A7
LIST_DRAWN $B531       -> DRAW_LIST $B55A: record numbers with bit 4, then $FF
RENDER_DYNAMIC_OBJECTS $B19E
  for each listed record with bit 5: clear it; the rectangle covering its old
    (+$1C..+$1F) and new (+$18..+$1B) pictures; FILL_RECT $B6DD with 0 in the
    buffer; push it; WIPE_COUNT + 1
  SORT_AND_DRAW $B58A  back to front, DRAW_OBJECT $B3D3 for each (depth-order.md)
  SHOW_CARRIED $BA34   the panel's boxes, if PANEL_DUE
  DRAW_WORK += WIPE_COUNT
  pop each rectangle -> BLIT_TO_SCREEN $B278
```

- **The buffer.** `BUFFER` ($D88F-$F08E), 192 rows of 32 bytes, bottom row
  first, because the game's pixel y counts up from the bottom of the screen.
  `CALC_VIDBUF_ADDR` $B37F gives a buffer address, `CALC_VRAM_ADDR` $B394 a
  display address (through 255 - y, and 56 added to the high byte rather than
  64), `CALC_ATTRIB_ADDR` $B3B6 an attribute address. `SHOW_BUFFER` $B178
  copies all 192 rows on a room's first turn and for the text screens;
  `BLIT_TO_SCREEN` copies one rectangle, a row at a time up the screen
  (*read*).
- **The projection** (`CALC_PIXEL_XY` $B2C5): pixel x = U + V - 128 + the
  nudge at +$12; pixel y = (V - U + 128) / 2 + Z - 104 + the nudge at +$13.
  Carry out means y is below 192, on the screen. Pentagram adds a clamp: if
  adding the (negative) x nudge does not carry, x went below 0 and becomes 0.
  So a nudge of 0 would always draw at x 0; every update routine sets a
  negative one ([`graphic-numbers.md`](graphic-numbers.md)) (*read*; the
  nudges *measured* in room 100).
- **A sprite** is a width byte (bits 0-3 the width in bytes; bit 7 set while
  it is stored upside down, bit 6 while mirrored), a height byte, then a mask
  byte and an image byte for each byte of each row, bottom row first. A
  buffer byte is cleared where the mask is set and has the image ORed in
  (*read*; every sprite drawn by the build from its bytes this way).
- **Turning a sprite** (`FIND_SPRITE` $B2EE): the graphic indexes `GRAPHICS`
  for the sprite. A first byte of 0 draws nothing: the routine drops its own
  return address, so its caller returns too. Where bits 7 and 6 of the
  object's flags disagree with the sprite's, the data is turned in place --
  rows swapped end for end for upside down; each row's cells reversed and
  every byte's bits reversed through `REVERSED` ($F100) for mirrored -- and the
  sprite's bit toggled. Two objects sharing a sprite and facing opposite ways
  turn it back and forth every draw. This is why the build takes its
  snapshot before the game's first instruction: on the tape every sprite's
  flags are clear (stage 1) (*read*).
- **Drawing it** (`DRAW_OBJECT` $B3D3): graphic 1 is emptied instead of drawn;
  anything else loses bit 4, is projected, and unless its y is 192 or more is
  drawn by the entry point `DRAW_SPRITE` ($B3E7), which the panel also uses
  with no projection. The row loop is unrolled for the widest sprite, five
  bytes, twice: `SPRITE_ALIGNED_RUN` ($B44F, 8 bytes of code a unit) for x a
  multiple of 8, and `SPRITE_SHIFTED_RUN` ($B47D, 16 a unit) through the
  complemented shift tables. `PATCH_SPRITE_ROWS` patches the JR in
  `SPRITE_ROW` ($B479) to enter the right run as many units from its end as
  the sprite is wide, and the ADD at `SPRITE_NEXT_ROW` ($B4CE) with the step
  to the next row. SP reads the sprite: each POP DE gives a mask in E and an
  image in D, the real SP kept in `SAVED_SP` ($A717); the game runs with
  interrupts off, so nothing pushes onto the sprite. Only the top of the
  screen clips; +$18 and +$19 come back as the width drawn (one more when
  shifted) and the height below the top (*read*; the patches *measured*).
- **The shift tables** (`MAKE_TABLES` $B29A, every new game): for each shift
  s of 1-7, page $F0 + 2s holds every byte shifted right s places and the page
  above it the bits that fall out, both complemented, so one value both clears
  under the mask and lets the image in. The loop builds them by shifting left
  across two bytes, from the top page down: the labels `SHIFTED1` ($FE00) to
  `SHIFTED7` ($F200) count those left shifts, so `SHIFTEDn` is a right shift
  of 8 - n. Stage 1's "shifted left n at $FE - 2(n-1)" and Knight Lore's
  "shifted right s at $F0 + 2s" describe the same layout (*read*).
- **The score's corner** (`SHOW_SCORE` $B145) copies the 6 x 8 byte area at
  pixel (184, 9), where `ADD_SCORE` prints the digits, straight to the screen
  when something shot scores ([`menu-and-panel.md`](menu-and-panel.md)).

## How this was found

Read against Knight Lore's `render_dynamic_objects`, `blit_to_screen`,
`calc_pixel_XY`, `flip_sprite` / `vflip_sprite_data` / `hflip_sprite_data`,
`calc_*_addr`, `print_sprite` and `build_lookup_tbls` (stage 2, ranges 1 and
2). Then in SkoolKit's simulator on the snapshot, after running `MAKE_TABLES`:
`DRAW_SPRITE` on graphic 32 (3 bytes wide, 15 high) at pixel x 100 and 96 and
pixel y 50 and 185 gave a JR offset of 32 (shifted) and -30 (aligned), a row
step of 29 and 30, +$18 of 4 and 3, and at y 185 the height cut to 7 -- all as
the arithmetic says. The nudges were read from all 38 records in use in room
100, one second into a game.

## Confidence

*Read*: all of it. *Measured* (simulator): the patch values, the top clip, the
nudges' sign.

## Knight Lore

The same routines ([`../knightlore/drawing.md`](../knightlore/drawing.md),
[`../knightlore/moving-objects.md`](../knightlore/moving-objects.md)); the
address routines match Knight Lore's instruction for instruction and
`BLIT_TO_SCREEN` at 0.95. Differences: the x clamp in `CALC_PIXEL_XY`; one
routine for all three of Knight Lore's sprite-turning routines;
`SHOW_BUFFER` does not clear the buffer as it copies; `SHOW_SCORE` is
Pentagram's own.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `SHOW_SCORE` | `SUBB145` | $B145 | copy the score's digits to the screen |
| `RENDER_DYNAMIC_OBJECTS` | `SUBB19E` | $B19E | wipe what moved, draw, copy the changes |
| `BLIT_TO_SCREEN` | `SUBB278` | $B278 | copy a rectangle of the buffer to the screen |
| `CALC_PIXEL_XY` | `SUBB2C5` | $B2C5 | the projection |
| `CALC_VIDBUF_ADDR`, `CALC_VRAM_ADDR`, `CALC_ATTRIB_ADDR` | `SUBB37F`, `SUBB394`, `SUBB3B6` | $B37F-$B3B6 | buffer, display, attribute address |
| `SPRITE_ALIGNED_RUN`, `SPRITE_ROW`, `SPRITE_SHIFTED_RUN` | `SUBB44F`, `SUBB479`, `SUBB47D` | $B44F-$B47D | the unrolled rows |
| `FILL_RECT` | `SUBB6DD` | $B6DD | fill a rectangle of bytes |
| `WIPE_COUNT` | `UNKNOWN_A710` | $A710 | areas wiped this turn |

New entry points: `PATCH_SPRITE_ROWS` $B40B, `DRAW_SPRITE_ROWS` $B429,
`SPRITE_ALIGNED` $B43E, `SPRITE_NEXT_ROW` $B4CE.

## Also found for the stage 3 pages (2026-09-27)

- The x clamp in `CALC_PIXEL_XY` never fires for anything as rooms are built; it does for Sabreman pressed into the left corner (U = V = 69), drawn at x 0 instead of 254 (*measured*, the Drawing page).
- The draw list overflows in play: rooms list at most 45 on their first turn (room 87); three quest things left there make 48, the $FF lands on `SORT_AND_DRAW` as RST $38, and the game halts within 20 s (*measured* in the simulator; *watched* live by the pokes agent: 47 ran 300 turns, 48 hung). Putting three things down there would do it; not played through.

## Open questions

- A sprite exactly one row high would make the upside-down swap loop run 256
  times (half the height, 0, before a DEC); Knight Lore's loop has the same
  shape. Whether any sprite is one row high has not been checked.
- The player's body ($C5D3) calls `SET_DRAW_OBJS_OVERLAPPED` without setting
  its own bit 5, so only the legs' rectangle is wiped through bit 5; whether
  the body's old picture is ever left behind has not been looked at.
