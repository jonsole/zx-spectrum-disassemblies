# Drawing

**Question this answers:** How does Knight Lore get from an object's x, y, z to
pixels on the screen, and what is redrawn each frame?

**Short answer:** Every object is projected isometrically to a pixel x and y
(y counted up from the bottom of the screen) and drawn through its mask into a
6144-byte off-screen buffer at $D8F3. On entering a room the whole buffer is
composed and copied to the display at once; after that, each frame wipes only
the rectangles covering where moved objects were and are, redraws everything
that overlaps them in depth order, and copies just those rectangles to the
display.

## How it works

```
end_of_frame ($B000)
  handle_pause ($D50E)
  list_objects_to_draw ($CE62)        objects with byte 7 bit 4 -> list at $CE8B
  render_dynamic_objects ($D59F)
    [$5BB7 clear] wipe_next_object ($D5B2) for each listed object with bit 5
        ... wipe_rect ($D62C): calc_vram_addr, calc_vidbuf_addr,
            fill_window ($C515) with 0, push HL/DE/BC, $5BA8++
    draw_and_copy_rects ($D653)
      calc_display_order_and_render ($CEBB)  depth order
        render_obj ($D003) -> calc_pixel_XY_and_render ($D704)
          project_and_draw ($D710) -> calc_pixel_XY ($D6C9)
          print_sprite ($D718)
            flip_sprite ($D6EF) -> vflip_sprite_data ($D865)
                                  -> hflip_sprite_data ($D8A2)
            patch_sprite_rows ($D73C), draw_sprite_rows ($D75A)
            sprite_row ($D7AA) / sprite_row_jump ($D7AC) ... sprite_next_row ($D800)
      print_sun_moon ($C397), display_objects_carried ($BF45)
      copy_next_rect ($D666) -> blit_to_screen ($D67C) per rectangle
  [$5BB7 set, after the delay] fill_attr ($D556) with $5BAD, status panel,
      update_screen ($D56F) whole buffer, $5BB7 = 0
```

### Coordinates and the projection

`calc_pixel_XY` ($D6C9), from record bytes 1-3 (x, y, z) and the adjustments in
bytes $12/$13 (set by `set_pixel_adj`, $C72B):

- pixel x (byte $1A) = x + y - 128 + byte $12
- pixel y (byte $1B) = (y - x + 128) / 2 + z - 104 + byte $13

Pixel y counts **up** from the bottom of the screen. A step in x is one pixel
right and half down, a step in y one right and half up, z straight up. Carry
out says whether pixel y < 192; an object above the top is not drawn.

### The buffer

$D8F3-$F0F2, 32 bytes a row, 192 rows, **bottom row first** (row 0 is the
bottom line of the display), no attributes. `calc_vidbuf_addr` ($D811) is
$D8F3 + y * 32 + x / 8 -- just BC shifted right three times. `calc_vram_addr`
($D826) gets the display address by complementing y (255 - y is the line from
the top plus 64) and adding $38 rather than $40 to take the extra third back.
`calc_attrib_addr` ($D848) does the same for attributes, with $5700 in place of
$5800. Both copy routines step up the display with the standard
DEC D / fix-up-at-character-row pattern.

### Sprites and masked drawing

A sprite (table $7112 indexed by record byte 0, the graphic):

| Offset | Field |
|---|---|
| 0 | bits 0-3 width in bytes; bit 6 set = data currently mirrored; bit 7 set = data currently upside down |
| 1 | height in rows |
| 2.. | for each row, bottom row first, for each byte: a mask byte then an image byte |

Background byte := (background AND NOT mask) OR image (aligned case), or
(background AND NOT mask) XOR image (shifted case -- the same thing when the
image lies inside the mask).

`print_sprite` ($D718):

- The row loop is **unrolled for five bytes and patched per sprite**: the JR
  offset at $D7AD chooses how far into the unrolled code a row starts, and the
  ADD operand at $D801 how far BC then steps to the next row up (33 minus the
  bytes a row touches). Sprites are therefore at most five bytes (40 pixels)
  wide.
- Two unrolled runs: an aligned one ($D780-$D7A9, 8 bytes of code per sprite
  byte) for pixel x a multiple of 8, and a shifted one ($D7AE-$D7FE, 16 bytes
  per sprite byte) otherwise, which touches one more byte per row.
- **SP is borrowed as the data pointer**: SP is saved in $5BA9, set to the
  sprite's first pair, and each POP DE fetches mask (E) and image (D). The
  listing has no EI anywhere, so interrupts are off and nothing can push onto
  the sprite meanwhile (inferred from the absence of EI; the snapshot's
  interrupt state was not checked).
- Clipped only at the top of the screen (height cut so y + height <= 192); not
  at the sides or bottom.
- Writes the drawn width in bytes (w, or w + 1 when shifted) to byte $18 and the
  drawn height to byte $19.

**Shift tables** built by `build_lookup_tbls` ($D69E): for a right shift s of
1-7, page $F0 + 2s holds NOT (n >> s) and page $F1 + 2s holds NOT of the bits
that fall into the next byte, for every n. The shifted unit looks both mask and
image up on the same page: AND clears the background under the shifted mask,
XOR with the complemented image followed by CPL puts the image in. Page $F1 is
the bit-reversal table. Page $F0 is not written by this routine.

### Flipping

`flip_sprite` ($D6EF) finds the sprite; a header byte of 0 means "nothing to
draw" and it discards its own return address so the caller returns too.
`vflip_sprite_data` ($D865) compares header bits 7 and 6 with bits 7 and 6 of
the object's byte 7, and **flips the sprite data in place** where they differ,
toggling the header bit: vertically by swapping rows end for end, horizontally
(`hflip_sprite_data`, $D8A2) by pushing each row's pairs with both bytes
bit-reversed through $F100 and popping them back in reverse order. So the sprite
data is a cache of the last orientation asked for: an object that keeps its
facing costs nothing, while two objects sharing a sprite and facing opposite
ways flip it every time each is drawn.

This answers the existing annotation's open point about spr_014: bit 7 of its
width byte is not part of the width and not an artwork flag -- it records that
the snapshot caught spr_014's data upside down. The existing annotation's "width
AND $7F" is also inexact: the drawing code takes the width from bits 0-3.

### What is redrawn each frame

Object byte 7 bit 5 = "needs wiping" (set with bit 4 by `set_wipe_and_draw_flags`,
$C692, when an object changes); bit 4 = "needs drawing" (also set by
`set_draw_objs_overlapped`, $CD4D, on every object whose picture overlaps the
changed one). `list_objects_to_draw` puts every bit-4 object in the list at
$CE8B.

`wipe_next_object` ($D5B2), for each listed object with bit 5: clears bit 5,
and takes the smallest rectangle covering both last frame's picture (bytes
$1C-$1F, copied from $18-$1B by `save_2d_info`, $CE49, before each object's
handler) and this frame's (bytes $18-$1B), in whole bytes across and rows up,
cut off at line 192. It clears that rectangle in the buffer and pushes it on
the stack (HL buffer, DE display, BC size); $5BA8 counts them. Then everything
flagged is drawn in depth order (bit 4 is cleared as each is drawn), and the
rectangles are popped and copied with `blit_to_screen`. Nothing is ever erased
on the display, so there is no flicker, and nothing outside the rectangles is
copied -- which is why `update_screen` can clear the buffer while copying it:
the next frame only ever copies areas it has just wiped and redrawn.

On entering a room ($5BB7 set) the wipe is skipped, all objects are drawn into
the cleared buffer, and `end_of_frame` paints the attributes with the room's
colour and copies the whole buffer with `update_screen`.

$5BBE counts the frame's work (objects drawn plus rectangles copied) and sets
how long `end_of_frame` delays, so busy frames wait less.

### Pause

`handle_pause` ($D50E), once a frame: SPACE alone in half-row $7E (B N M SYMBOL
SHIFT SPACE) pauses; another key of that half-row held with it does not. Wait
for release, sound ($B4A8), wait for press, wait for release, sound. The whole
game stops inside the routine.

### Screen clearing

`clear_scrn` ($D55F): black border, attributes $46 (bright yellow on black),
bitmap cleared. `fill_attr` ($D556) sets all 768 attributes to A -- the room
colour from $5BAD, so a room is one colour throughout. `clear_scrn_buffer`
($D567) clears the buffer.

## How this was found

Read every routine from $D3B5 to $D8F2, and the callers and callees needed to
place them: `end_of_frame`/`no_delay` ($B000/$B03F), `list_objects_to_draw`
($CE62), `calc_display_order_and_render`/`render_obj` ($CEBB/$D003),
`save_2d_info` ($CE49), `calc_2d_info` and `set_draw_objs_overlapped`
($CD33/$CD4D), `set_wipe_and_draw_flags` ($C692), `fill_window` ($C515),
`build_screen_objects` ($D1E6/$D1EF). The unrolled-code entry points were worked
out by computing the patched JR target for widths 1 to 5 and checking each lands
on a unit boundary ($D7A8 - 8w aligned, $D7FE - 16w shifted), and the row step
by counting INC BCs per row. The shift-table page arithmetic was checked by
matching the page `print_sprite` puts in H against the pages the builder
writes. The listing's current JR operand ($D790) and step ($1E) are consistent
with the last sprite drawn before the snapshot being an aligned, three-byte one.

## Confidence

Read from the code throughout, except where marked inferred: interrupts being
off (from the absence of EI); graphic 1 as a removal marker (only the effect in
`calc_pixel_XY_and_render` is read).

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| mult_step | loc_D4FF | $D4FF | one bit of HL = DE * A |
| mult_next_bit | loc_D504 | $D504 | loop of the multiply |
| update_screen_row | loc_D578 | $D578 | one row of the whole-screen copy |
| update_screen_byte | loc_D57B | $D57B | copy and clear a row, step up a display line |
| update_screen_next_row | loc_D59A | $D59A | next row of the whole-screen copy |
| wipe_right_edge | loc_D5DB | $D5DB | right edge of the wipe rectangle |
| wipe_width | loc_D5F6 | $D5F6 | width and bottom edge |
| wipe_top_edge | loc_D60B | $D60B | top edge |
| wipe_height | loc_D61C | $D61C | height, clipped at line 192 |
| wipe_rect | loc_D62C | $D62C | clear the rectangle in the buffer, push it |
| wipe_left_is_new | loc_D649 | $D649 | new x is the left edge |
| wipe_bottom_is_new | loc_D64E | $D64E | new y is the bottom edge |
| draw_and_copy_rects | loc_D653 | $D653 | draw everything, then copy the rectangles |
| copy_next_rect | loc_D666 | $D666 | pop and blit one rectangle |
| copy_rects_done | loc_D679 | $D679 | return |
| blit_next_row | loc_D69A | $D69A | row loop of blit_to_screen |
| shift_tbl_value | loc_D6A0 | $D6A0 | shift tables: next byte value |
| shift_tbl_entry | loc_D6A7 | $D6A7 | shift tables: store one shift |
| reverse_tbl_value | loc_D6BB | $D6BB | reversal table: next byte value |
| reverse_tbl_bit | loc_D6BE | $D6BE | reversal table: one bit |
| project_and_draw | loc_D710 | $D710 | project, then draw if on screen |
| patch_sprite_rows | loc_D73C | $D73C | patch the unrolled loop, clip height |
| draw_sprite_rows | loc_D75A | $D75A | set BC and SP, enter the loop |
| sprite_aligned | loc_D76F | $D76F | aligned case and first two aligned units |
| sprite_aligned_tail | loc_D790 | $D790 | last three aligned units |
| sprite_row | loc_D7AA | $D7AA | start of a row |
| sprite_row_jump | loc_D7AC | $D7AC | patched JR and the shifted units |
| sprite_row_end | loc_D7FF | $D7FF | end of a row |
| sprite_next_row | loc_D800 | $D800 | patched row step, row count, SP back |
| vflip_row_pair | loc_D88C | $D88C | next pair of rows to swap |
| hflip_sprite_data | loc_D8A2 | $D8A2 | mirror the sprite data in place |
| hflip_read_row | loc_D8BF | $D8BF | push a row's pairs bit-reversed |
| hflip_write_row | loc_D8CD | $D8CD | pop them back in reverse |
| flip_done | loc_D8DC | $D8DC | return with DE on the header |
| copyright_notice | aCopyright1984A_c_g_ | $D8DE | the copyright text |

(Plus zero_fg_obj_tail and end_of_fg_objs under room building. No meaningful
tcdev name was changed.)

## Open questions

- Why SPACE pauses only when B, N, M and SYMBOL SHIFT are all up.
- Stack room for the wipe rectangles: each takes 6 bytes on the stack, which
  sits just below $5BA0. About 26 fit in the printer buffer before the stack
  would reach the attribute file at $5AFF -- if many objects moved in one frame
  the rectangles would be written over the bottom rows of attributes. Not
  checked whether that can happen.
- What sets graphic 1 on an object (see `calc_pixel_XY_and_render`).
- Why the aligned and shifted cases combine the image differently (OR versus
  XOR). They agree when image bits lie inside the mask; a sprite that breaks
  that would draw differently at different x.
- A sprite of height 1 would make the vertical flip loop 256 times (SRL C gives
  0); presumably no sprite is one row high and flipped.
