# The textured fill

**Question this answers:** how a room's areas are filled with a pattern --
what the codes $E6-$FF, the clean copy at $C000 and the whole-byte shortcut
have to do with it, and how a texture is laid out.

**Short answer:** a fill code floods the area round the point with one of
26 textures, a run at a time, with the machine stack as its list of runs
still to do. What bounds it is not the screen but the clean copy of the
screen at $C000, which a room fills with its outline (code $E2, or `$E4 $00`
for an outline that is never seen) and which the fill marks as it goes; the
texture replaces whatever was on the screen. Where a whole byte needs no
decision it is painted in one write. A texture is a 16 by 16 tile anchored
to the screen's character cells, so neighbouring fills join seamlessly and
the pattern lines up with the colours.

## How it works

```
DO_ROOM_COMMAND $E5E8, code $E6-$FF  -> FILL_SEED $E73D: texture address, the point,
                                        a sentinel word ($FExx) pushed
FILL_NEXT_SEED $E734   pop a run (C column, B row); drop rows off the screen or set in
                       the map; scan right to the run's end; map pointers for this row,
                       above and below; the row's two texture bytes
  FILL_NEXT_PIXEL $E7B2 (entry FILL_THIS_PIXEL $E7BD)   paint leftwards, push new runs
    FILL_BYTE_TO_LEFT $E834   at each byte boundary: pointers a byte left, texture bytes swapped
      FILL_WHOLE_BYTE $E806   eight pixels in one write when nothing can change
```

- **The map.** Every test is against the clean copy, 32 KB above the screen
  (a screen address with bit 7 set in its high byte: `BUFFER_PIXEL` $E864).
  A set pixel there stops the fill; each pixel painted is set there, so no
  pixel is painted twice, and a second fill in the same area does nothing
  (its first point is already set). The screen only receives the texture.
- **Runs.** A run is the stretch of a row between set pixels. $E734 scans
  right from the popped point to the run's end, then `FILL_NEXT_PIXEL` walks
  left to its other end. Bits 0 and 1 of E say whether a run is open in the
  row above and below; a place is pushed when a run opens, not per pixel.
  Pushes from the top or bottom row name rows 192 or 255, which the pop
  throws away (`CP $C0`); their pointers meanwhile read the leftover symbol
  table ($DFxx) and a buffer page ($D8xx), harmlessly.
- **Whole bytes.** At each byte boundary `FILL_WHOLE_BYTE` checks that this
  row's byte is all clear in the map and that the rows above and below are
  each the same all along the byte (all clear where a run is open, all set
  where none is). If so one write marks eight pixels in the map and one puts
  the texture byte on the screen, and the loop jumps back to its top.
- **The texture.** 32 bytes at `TEXTURES` ($E0A4) + 32 x (code - $E6):

| Bytes | Cell |
|---|---|
| 0-7 | Left 8 pixels, for the character rows whose y has bit 3 set |
| 8-15 | Right 8 pixels, the same rows |
| 16-23 | Left 8 pixels, the other character rows |
| 24-31 | Right 8 pixels, the other rows |

  Each cell's bytes run from the top of its character row. Screen line bit
  3 picks the pair, column bit 3 the cell; B' and C' hold the row's two
  bytes and are swapped at each byte boundary, E' the one for the current
  byte. The fill keeps the texture's address in `FOUND_RECORD` ($FFF8, the
  same byte `CLEAR_ROOM_SCREEN` keeps SP in), and the map pointers of this
  row, the row above and the row below in `STEP_AXES` ($FFFB), `WORK_RECORD`
  ($FFFD) and `WORK_HEADING` ($FFF6), stepping their low bytes as IY+$7B
  and IY+$7D.

Only 14 of the 26 fill codes occur in any room or part: $E6, $E7, $E9, $EC,
$ED, $EF, $F0, $F1, $F3-$F7 and $FB (*measured* with the build's parser).
Drawn by this layout, textures 6-8 are bricks (their left and right cells
shifted copies of each other, as a 16-pixel pattern must be), texture 2 is
vertical stripes, and textures 22 and 23 are not patterns at all but the
Swedish capitals and small letters with rings and dots -- the author was
Swedish -- which no room uses. The pictures are on the listing's texture
entries.

## How this was found

Read (stage 2, ranges 1 and 2) from $E70D to $E86E, with Krumlinde's
`textured_fill.md` beside it. The layout read from $E787-$E7A7 and checked
by drawing the textures with it (`fairlight_data.texture_image` does the
same), and against the bricks. *Measured*: room 2 drawn to the end of its
commands shows the clean copy holding exactly the filled area after a fill.

## Confidence

The algorithm, the map and the texture layout: *read*, the layout also
*drawn*. That a fill marks the map and paints the screen: *measured* (room
2). That the off-screen pushes are harmless: *read* (dropped on the pop; the
whole-byte test only chooses the fast road or the slow).

## Krumlinde

He has the algorithm right -- a span fill on the machine stack, the clean
copy as the visited map, the 32 KB offset, the whole-byte shortcut, the lazy
row addresses -- and `FILL_NEXT_PIXEL` keeps his `Fill_NextPixel`. Where he
differs:

- **The texture format.** He has bytes 0-15 for "even scanline groups" and
  byte n as pixel row n. The code adds 16 when bit 3 of the row counted from
  the bottom is clear (bit 3 of the screen line set, since the line is 191
  less the row), and bytes 8-15 are the right-hand 8 pixels of the same
  rows, not rows 8-15 (*read*; the bricks confirm it).
- **"Solid" textures.** His table calls $E8 solid $55: $55 on every row is
  vertical stripes. And none of $E8, $F9, $FE, $FF is used by any room.
- **`Fill_CheckRowBounds`** tests all three rows, for the whole-byte
  shortcut, not only the row below.
- **Entries with B >= $C0** are not stale: they are runs in rows off the
  top or bottom of the screen.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `FILL_NEXT_SEED` | `SUBE734` | $E734 | Take the next run off the stack |
| `FILL_SEED` | (entry) | $E73D | Where a fill code starts |
| `FILL_NEXT_PIXEL` | `SUBE7B2` | $E7B2 | Paint a run leftwards (Krumlinde's name) |
| `FILL_THIS_PIXEL` | (entry) | $E7BD | Where a run starts |
| `FILL_WHOLE_BYTE` | `SUBE806` | $E806 | Eight pixels in one write |
| `FILL_BYTE_TO_LEFT` | `SUBE834` | $E834 | Every pointer a byte left, texture bytes swapped |
| `PIXEL_ADDRESS` | `SUBE849` | $E849 | Screen byte of a pixel (rows from the bottom) |
| `BUFFER_PIXEL` | `SUBE864` | $E864 | The same in the clean copy, with the mask |
| `SCREEN_PIXEL` | `SUBE86E` | $E86E | Screen byte and mask |

## Open questions

- How deep the stack goes in the worst fill. Over all the sessions the
  stack reached 150 bytes below its top, fills included; the stack lies in
  leftover text ([`memory-map.md`](memory-map.md)), so there is room.
