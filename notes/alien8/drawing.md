# Drawing

**Question this answers:** how a turn's picture gets from the object records
to the screen.

**Short answer:** everything is drawn into a buffer at `BUFFER` ($D200), 32
bytes a line, bottom line first. On the first turn in a room the whole
buffer is copied (`SHOW_BUFFER`, $CE85); after that `RENDER_DYNAMIC_OBJECTS`
($CEAB) wipes, in the buffer, the box round each moved object's old and new
pictures, redraws every listed object back to front, and copies only the
wiped boxes to the screen. Sprites are masked, drawn through pre-shifted
complemented tables, and turned in place to face the way their objects do.
It is Pentagram's code instruction for instruction, which is Knight Lore's
reorganised.

## How it works

```
MAIN_END_OF_TURN $A6DC
  LIST_DRAWN $C71C            records with bit 4 of +$07 -> DRAW_LIST ($C745), $FF
  RENDER_DYNAMIC_OBJECTS $CEAB
    WIPE_COUNT = 0
    unless NEW_ROOM: for each listed record with bit 5 of +$07 (cleared here):
      the union of this turn's and last turn's rectangles, cut at line 192,
      cleared in the buffer (FILL_BOX $BF83), and pushed: buffer address,
      display address, size
    SORT_AND_DRAW $C785       back to front ([depth-order.md]); each object:
      CALC_PIXEL_XY_AND_RENDER $D013
        graphic 1 -> 0 (the record freed); else bit 4 of +$07 cleared,
        CALC_PIXEL_XY $CFD2, and unless off the top, PRINT_SPRITE $D027
    SHOW_CARRIED $BC9D        the panel's carried things, when due
    DRAW_WORK += WIPE_COUNT
    each pushed box -> BLIT_TO_SCREEN $CF85
```

- **The projection** (`CALC_PIXEL_XY`, $CFD2, *read*): pixel x = U + V -
  128 + the nudge x (+$12); pixel y = (V - U + 128)/2 + Z - 40 + the nudge y
  (+$13), counted up from the bottom; carry if y < 192. So +U runs down and
  right on the screen, +V up and right. While `GAME_OVER` is set it returns
  at once with carry set: the scene after a game places its pieces in
  pixels itself ([`scenes.md`](scenes.md)). `CALC_PIXEL_XY_IY` ($AE8A) is
  the same for the record at IY.
- **The screen rectangle** (`CALC_2D_INFO` $C63D): +$1A/+$1B from the
  projection (not moved while `GAME_OVER` is set), +$18 the width in bytes
  (one more if the x is not byte-aligned), +$19 the height. The main loop
  copies +$18-+$1B to +$1C-+$1F before every update, so the wipe knows where
  the object was ([`depth-order.md`](depth-order.md) for the marking).
- **Finding and turning a sprite** (`FLIP_SPRITE` $CFFE): the graphic's
  sprite from `GRAPHICS`; bit 7 of the sprite's width byte against bit 7 of
  the object's flags -- if they differ, the rows are swapped end for end in
  place (`VFLIP_SPRITE_DATA` $D174); bit 6 against bit 6 -- each row's
  cells and each byte's bits reversed through the table at $F100
  (`HFLIP_SPRITE_DATA` $D1AF). The sprite stays turned until an object
  facing the other way needs it, which is why a snapshot taken after play
  has some sprites turned; the build's is taken before the first
  instruction.
- **The draw** (`PRINT_SPRITE` $D027): shifted (x AND 7 non-zero) or
  aligned; the JR at `SPRITE_ROW_JUMP` ($D0BB) and the ADD operand at $D110
  are patched for the sprite's width so the jump lands on the right number
  of unrolled units (`SPRITE_ALIGNED_RUN` $D08F, five 8-byte units;
  `SPRITE_SHIFTED_RUN` $D0BD, five 16-byte units; `SPRITE_NEXT_ROW`
  $D10E); the height is cut at the top of the screen; SP is borrowed
  (`SAVED_SP`, $5B09) to POP mask and image pairs. The buffer gets (screen
  AND NOT mask) OR image. +$18/+$19 come out as the width and height drawn.
- **The tables** (`BUILD_LOOKUP_TBLS` $CFA7, at every new game before the
  menu): $F100 the byte bit-reversed; pages $F2-$FF, for a shift s = 1 to 7,
  page $F0 + 2s the byte shifted right s and page $F1 + 2s the bits that
  fall out, both complemented. The label `MIRROR_TABLE` ($F100) covers all
  fifteen pages.
- **The address arithmetic**: `CALC_VIDBUF_ADDR` ($D120, $D200 + 32y +
  x/8), `CALC_VRAM_ADDR` ($D135, through 255 - y and +$38),
  `CALC_ATTRIB_ADDR` ($D157, through 255 - y and $5700).
- **Copying out**: `BLIT_TO_SCREEN` ($CF85) copies a rectangle;
  `SHOW_BUFFER` ($CE85) all of it, without clearing the buffer as it goes;
  `BLIT_2X8` ($BF2F) a 16 by 8 patch, for the lives and the chambers count,
  which change without a redraw. `FILL_BOX` ($BF83) clears or fills a box of
  bytes -- it rewrites the displacement of its own JR (`FILL_BOX_ROW`
  $BF95) so the jump lands on the last B of eight unrolled stores
  (`FILL_BOX_STORES` $BF97); on the tape that JR jumps to itself and is
  always rewritten before it runs.
- **Marking** (`SET_WIPE_AND_DRAW_FLAGS` $BFAB, `SET_WIPE_AND_DRAW_IY`
  $ADF3): bits 4 and 5 of +$07 and everything the object's rectangle meets
  marked ([`depth-order.md`](depth-order.md)).

## How this was found

Read against Pentagram's descriptions of the same code (matches 0.74 to
1.00, most 1.00) and Knight Lore's (stage 2, range 5). Every instruction
ran in the build's sessions. The sprite sizes read from `GRAPHICS` for the
whole table: widths 0-5, no width byte with bits 4-5 set, heights 0, 1, then
8 up. The panel's drawing was also run on its own in the simulator
([`menu-and-panel.md`](menu-and-panel.md)).

## Confidence

*Read*, and *measured* in that all of it ran.

## Knight Lore and Pentagram

Pentagram's code ([`../pentagram/drawing.md`](../pentagram/drawing.md)),
which is Knight Lore's reorganised
([`../knightlore/drawing.md`](../knightlore/drawing.md)). Differences, all
*read*:

- `CALC_PIXEL_XY` subtracts 40 where Knight Lore subtracts 104, has the
  `GAME_OVER` early return, which neither has, and lacks Pentagram's clamp
  of a negative x to 0.
- `SHOW_BUFFER` does not clear the buffer as it copies (Knight Lore's
  `update_screen` does; Pentagram's does not either).
- The shifted path reads the width from bits 0-2 of the width byte, the
  aligned path from bits 0-3; with widths of at most 5 it makes no
  difference.
- The row swap halves the height: a one-row sprite would loop 256 times.
  Graphic 5 is the only one-row sprite, and it is only ever mirrored (the
  border's flags are $00 and $40), never turned upside down, so it never
  happens.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `SHOW_BUFFER` | `SUBCE85` | $CE85 | copy the whole buffer |
| `RENDER_DYNAMIC_OBJECTS` | `SUBCEAB` | $CEAB | wipe, draw, copy what changed |
| `BLIT_TO_SCREEN` | `SUBCF85` | $CF85 | copy a rectangle |
| `BUILD_LOOKUP_TBLS` | `SUBCFA7` | $CFA7 | the drawing tables (`SHIFT_TBL_VALUE`, `SHIFT_TBL_ENTRY`, `REVERSE_TBL_VALUE`, `REVERSE_TBL_BIT`) |
| `CALC_PIXEL_XY` | `SUBCFD2` | $CFD2 | the projection |
| `FLIP_SPRITE` | `SUBCFFE` | $CFFE | find the sprite and turn it |
| `CALC_PIXEL_XY_AND_RENDER` | `SUBD013` | $D013 | draw one object (`PROJECT_AND_DRAW`, `PRINT_SPRITE`, `PATCH_SPRITE_ROWS`, `DRAW_SPRITE_ROWS`, `SPRITE_ALIGNED`) |
| `SPRITE_ALIGNED_RUN`, `SPRITE_ROW` (`SPRITE_ROW_JUMP`), `SPRITE_SHIFTED_RUN` (`SPRITE_NEXT_ROW`) | `SUBD08F`, `SUBD0B9`, `SUBD0BD` | $D08F-$D10E | the unrolled rows |
| `CALC_VIDBUF_ADDR`, `CALC_VRAM_ADDR`, `CALC_ATTRIB_ADDR` | `SUBD120`, `SUBD135`, `SUBD157` | $D120-$D157 | addresses |
| `VFLIP_SPRITE_DATA` | `SUBD174` | $D174 | turn the sprite (`VFLIP_ROW_PAIR`, `VFLIP_SPRITE_LINE_PAIR`, `HFLIP_SPRITE_DATA`, `HFLIP_READ_ROW`, `HFLIP_WRITE_ROW`, `FLIP_DONE`) |
| `SET_WIPE_AND_DRAW_FLAGS`, `DEC_DZ_AND_UPDATE_UVZ` (`ADD_DUVZ`) | `SUBBFAB`, `SUBBFB6` | $BFAB, $BFB6 | mark to redraw; fall and move |
| `SET_WIPE_AND_DRAW_IY`, `CALC_PIXEL_XY_IY` | `SUBADF3`, `SUBAE8A` | $ADF3, $AE8A | the same for IY |
| `BLIT_2X8`, `FILL_BOX`, `FILL_BOX_STORES` | `SUBBF2F`, `SUBBF83`, `SUBBF97` | $BF2F-$BF97 | patches and boxes |

## Open questions

None of substance.
