# Drawing things: sprites, the buffer and the tables

**Question this answers:** how a thing's sprite gets onto the screen, and
what the buffers and lookup tables above the code are for.

**Short answer:** everything is drawn into a buffer of 112 lines of 24
bytes (`BUFFER`, $E5C4) whose row 0 is the bottom line of the play area,
and the whole of it is copied to the screen at the end of every turn with
PUSHes, bytes 2-23 of each row only, then cleared. Sprites are masked and
drawn by an unrolled loop entered through a patched `JR`; x moves in steps
of two pixels, so only shifts of 2, 4 and 6 are tabled. A sprite's data is
turned in place when an object wants it mirrored the other way.

## How it works

```
SORT_AND_DRAW_THINGS $CFF2  (back to front within a cell: depth-order.md)
  DRAW_SPRITE $E3D9
    PROJECT_THING $D4F3 -> DRAW_X, DRAW_Y
    x = DRAW_X + (+C), y = DRAW_Y + (+D) -> +E, +F     (reject off-screen)
  DRAW_SPRITE_AT $E3FF  (the ending's pictures enter here)
    TURN_SPRITE $E353        the sprite from GRAPHICS by +0, turned to match +7 bits 6-7
    x bits 1-2 = 0 -> SPRITE_ALIGNED_RUN $E49F, else SPRITE_SHIFTED_RUN $E4CD
    patch the JR at SPRITE_ROW ($E4C9) and the row step at SPRITE_NEXT_ROW ($E528)
    clip rows: the bottom, the top, or ARRIVING for the knight
    BUFFER_ADDRESS $E53A; SP -> the sprite data; the rows; SP back from SAVED_SP
...
END_OF_TURN: SHOW_PLAY_AREA $E200 = COPY_BUFFER $E148 + COPY_ATTR_BUFFER $E1AD,
             then CLEAR_BUFFER $E206 (FILL_BELOW_HL $E21D)
```

- **The sprite format**: a width byte (bits 0-3 the width in bytes, bit 6
  stored mirrored, bit 7 stored upside down), a height byte, then a mask
  and an image byte for each byte of each row, the bottom row first. A
  buffer byte becomes (byte AND NOT mask) OR image.
- **Turning in place** (`TURN_SPRITE`): where the object's +7 bits 6 and 7
  differ from the sprite's, the data is turned and the sprite's bit
  toggled -- so a thing that keeps facing one way costs nothing after the
  first time, while two things sharing a sprite and facing opposite ways
  turn it back and forth. Mirroring (`MIRROR_SPRITE_DATA`, $E3A4, also
  entered by `MIRROR_SPRITE`, $E3D6) reverses each row's pairs and the bits
  of every byte through `REVERSE_TABLE`. The upside-down half never runs:
  nothing sets bit 7 of a record's flags ([`object-records.md`](object-records.md)).

| Geometry (*measured*) | |
|---|---|
| buffer | 24 bytes by 112 rows; row 0 = screen line 127, row 111 = line 16 |
| shown | bytes 2-23 of each row = screen columns 7-28; bytes 0-1 a hidden margin |
| attributes | `ATTR_BUFFER` $F044, 24 by 14; row 0 = screen row 15 |
| y | upwards; y 72 is buffer row 0; drawn if y < 184 |
| x | x 16 is buffer byte 0; drawn if 16 <= x <= 202; bit 0 ignored |
| the knight | graphics 16-47 cut at `ARRIVING` lines above the bottom, so a new life shows him from the ground up |

- **The runs.** Each unrolled run has five units (8 bytes plain, 18
  shifted), entered as many units from the end as the sprite is wide. No
  sprite is wider than four bytes, so the first unit of each run, at $E49F
  and $E4CD, can never run -- which is why the code map took both for data.
- **The tables** (`MAKE_TABLES` $E0FB, at every new game; *measured*):

| Pages | Contents | Read by |
|---|---|---|
| $F2/$F3, $F4/$F5, $F6/$F7 (`MIRROR_TABLES`) | a bit-reversed byte shifted right 2/4/6: what stays, what falls out | tiles of a mirrored face |
| $F8 (`UNUSED_F800`) | nothing: the plain set's slot for a shift of 0 | never |
| $F9 (`REVERSE_TABLE`) | a bit-reversed byte | mirroring sprites; aligned mirrored tiles |
| $FA-$FF (`SHIFT_TABLES`) | a byte shifted right 2/4/6: what stays, what falls out | shifted sprites and tiles |

  A page is chosen as $F0 (mirrored) or $F8 (plain) plus x's bits 1-2,
  which is why $F8 is left empty; the mirrored set's shift-0 page would be
  $F0, inside the attribute buffer, but aligned drawing never looks either
  up.
- **The copy.** `COPY_BUFFER` points SP just past the end of a screen line
  and PUSHes eleven words of buffer a row, reading the buffer backwards from
  row 0 up; `COPY_ATTR_BUFFER` does the same for the 14 rows of
  attributes. `CLEAR_BUFFER` fills the attributes with bright white ink on
  the paper in `FLASH` and the pixels with zeros, also by PUSHes; its fill
  starts just below `ATTR_SPILL`, so that byte is never cleared.
- **Addresses**: `BUFFER_ADDRESS` ($E53A, the buffer byte for x, y),
  `ATTR_ADDRESS` ($E579, the attribute buffer's), `CALC_VRAM_ADDR` ($E556,
  a display address for text and the panel, y up from the screen's bottom
  line -- a different origin from the buffer's).

## How this was found

Read, then checked in SkoolKit's simulator (stage 2, range 5):
`MAKE_TABLES` run and every table byte compared with the reading; a
monster's sprite (graphic 64) drawn with `DRAW_SPRITE_AT` into an empty
buffer at several x and y, with and without the mirror flag, and the
knight's graphic 16 with `ARRIVING` at 16 -- rows, columns, `SPRITE_WIDTH`,
`SPRITE_ROWS`, the patched offset and step all as read; `COPY_BUFFER` and
`COPY_ATTR_BUFFER` run on a numbered buffer and the screen read back.
Pentagram's `DRAW_OBJECT` and `SPRITE_*` annotations were the template.

## Confidence

*Measured* for the geometry, the tables, the patching and the clipping.
*Read* for "nothing sets bit 7" (every write to +7 read; see
[`object-records.md`](object-records.md)).

## Filmation (Knight Lore, Alien 8, Pentagram)

- `TURN_SPRITE` is Pentagram's `FIND_SPRITE` and Alien 8's
  `VFLIP_SPRITE_DATA`, without Pentagram's empty-sprite escape. The
  upside-down half is dead code here; Knight Lore's objects do turn upside
  down.
- The runs and `SPRITE_ROW` are the earlier games' structure, but the
  shifted tables are plain and for even shifts only (three pairs instead of
  seven), and the shifted unit uses CPL/OR/CPL like the aligned one, where
  Pentagram's tables are complemented and its unit ANDs and XORs.
- The buffer is used differently: the earlier games redraw only the areas
  that changed and copy those out; Nightshade redraws the whole play area
  every turn, since the town scrolls under the knight, copies all of it,
  and clears it.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `NEGATE_HL`, `SIGN_EXTEND_A`, `ADD_HL_A` | `SUBE0DD`, `SUBE0E5`, `SUBE596` | | helpers |
| `HL_EQUALS_DE_X_A` | `SUBE0EE` | $E0EE | multiply (Alien 8's name); only the dead upside-down flip uses it |
| `MAKE_TABLES` | `SUBE0FB` | $E0FB | Pentagram's name |
| `COPY_BUFFER`, `COPY_ATTR_BUFFER`, `SHOW_PLAY_AREA` | `SUBE148`, `SUBE1AD`, `SUBE200` | | the copy; `CLEAR_BUFFER`, `FILL_BELOW_HL` entries |
| `MIRROR_SPRITE` | `SUBE3D6` | $E3D6 | mirror a sprite for the panel's villains |
| `MIRROR_SPRITE_DATA`, `DRAW_SPRITE_AT` | (new labels) | $E3A4, $E3FF | entries |
| `SPRITE_ALIGNED_RUN`, `SPRITE_SHIFTED_RUN` | `DATAE49F`, `DATAE4CD` | | retyped as code |
| `SPRITE_ALIGNED_FOUR`, `SPRITE_SHIFTED_FOUR` | `SUBE4A7`, `SUBE4DF` | | the rest of each run |
| `SPRITE_ROW` | `SUBE4C9` | $E4C9 | Pentagram's name |
| `BUFFER_ADDRESS`, `CALC_VRAM_ADDR`, `ATTR_ADDRESS` | `SUBE53A`, `SUBE556`, `SUBE579` | | addresses |
| `CLEAR_SCREEN`, `CLR_BITMAP_MEMORY`, `CLR_ATTRIBUTE_MEMORY`, `CLEAR_MEMORY` | `SUBE59D`, `SUBE5A8`, `SUBE5B0`, `SUBE5BA` | | Alien 8's and Pentagram's names |

`TURN_SPRITE` and `DRAW_SPRITE` are stage 1's and stand.

## Disassembly corrections

- $E49F and $E4CD were data blocks; they are the first units of the two
  unrolled runs, code no sprite reaches.
- Stage 1's list of code that never ran put `$E3D6` with the upside-down
  flip. It is the mirroring entry, used by the panel's villains
  (`DRAW_VILLAINS`, $C1FD) when a villain's sprite is stored mirrored; it
  did not run because that never happened in the sessions. The upside-down
  flip is $E366-$E399, with `HL_EQUALS_DE_X_A`.

## Open questions

- A sprite starting in a row's last byte runs on into the first bytes of
  the row above. The two margin bytes hide two; a four-byte sprite drawn
  shifted at x 200-202 would show two bytes at the left edge, one line up
  (the simulator shows the run-on). Whether any thing reaches that x in play
  is not known.
- A sprite with a zero width (the empty sprite of graphics 0, 1, 23, 31)
  would draw through a zero row count; presumably no such record is ever
  listed (empty records are skipped by `LIST_THINGS_IN_CELL`; 23 and 31 are
  never set). Not checked.
