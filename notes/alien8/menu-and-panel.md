# The menu, the text and the panel

**Question this answers:** how the menu works, how text and numbers get on
the screen, and what draws and colours the panel and the border.

**Short answer:** `MENU` ($BA7E) draws an eight-line text list and loops
reading keys 1-5 and 0: 1-4 pick the control method, 5 toggles directional
control, 0 starts; every pass bumps the seed. All text goes through one list
printer (`DISPLAY_TEXT_LIST` $BC31) and one character printer
(`PRINT_CHAR` $BBEB) into the screen buffer; numbers are BCD, printed with
the font itself as the base so a digit is its own character code. The panel
under the room is twelve pieces drawn from `PANEL_DATA` ($CB5A) on a room's
first turn -- Knight Lore's slanting scroll-work, the edges and three icons
-- then coloured by `COLOUR_PANEL` ($A749): the room's ink everywhere, fixed
colours for the boxes, and a label colour that is never the room's. The text
screens get Knight Lore's border.

## How it works

**The menu** (*read*; the keys *measured* by the build's sessions):

- `MENU` ($BA7E), from `MAIN_NEW_GAME` before every game: clears
  `TEXT_SHOWN`, clears bit 7 (FLASH) of the eight line colours at
  `MENU_COLOURS` ($BB14), clears the buffer, draws the menu (`DISPLAY_MENU`
  $BC25) and flashes the choices (`FLASH_MENU` $BAFB).
- `MENU_LOOP` ($BA95): the text again, the tune once (`PLAY_TUNE_ONCE`
  $B4A1, cut short by a key), keys 1-5 (half-row $F7) into E. `CONTROL` is
  kept in `CONTROL_BEFORE`; keys 1-4 set bits 1-2 (0 keyboard, 1 Kempston,
  2 cursor, 3 Interface II; the highest held wins); key 5 toggles bit 3 once
  a press (`KEY5_HELD` latches it, `MENU_KEY5_RELEASED` $BAF7 clears the
  latch); a changed `CONTROL` beeps (`MENU_BEEP_IF_CHANGED` $BADE,
  `PLAIN_BEEP`); key 0 (half-row $EF) returns to start the game; otherwise
  `SEED` + 1, flash, round again.
- `FLASH_MENU` ($BAFB): `TOGGLE_SELECTED` ($BC15, `FLASH_THIS_ONE`,
  `FLASH_NEXT_ONE`, `UNFLASH_THIS_ONE`, `FLASH_LIST_STEP`) sets FLASH on the
  method's line among the four and clears the others; the fifth line's
  colour (directional control) follows bit 3 of `CONTROL`.
- **The menu's tables** run on as one block from $BB14: eight colours
  (bright magenta title, bright green methods, bright cyan directional
  control, bright white start and copyright), eight (x, y) positions from
  `MENU_XY` ($BB1C; y counts up from the bottom; the options at x 48, 16
  pixels apart from y 143), eight strings from `MENU_TEXT` ($BB2C), each
  ending with bit 7 set. sna2ctl cut them into 20 entries; the listing keeps
  the cut and labels each piece (`MENU_Y_TITLE` ... `MENU_COPYRIGHT_LAST`).
  The copyright line on the menu says 1985.

**The text**:

- `DISPLAY_MENU` ($BC25) loads DE' with the colours, HL the positions, DE
  the strings, B 8, and runs into `DISPLAY_TEXT_LIST` ($BC31): per line, the
  colour into `PRINT_ATTR`, the position into HL,
  `PRINT_TEXT_SINGLE_COLOUR`. The first list after `TEXT_SHOWN` is cleared
  sets it, draws the border (`PRINT_BORDER` $CB8A) and shows the whole
  buffer; later lists only redraw into the buffer and write attributes --
  which is how the menu's flashing lines change without a redraw. The
  summary and the arrival screen use it too.
- `PRINT_TEXT_SINGLE_COLOUR` ($BB9D) and `PRINT_TEXT` ($BBB1): `FONT_BASE`
  = the font ($6308) less 384, so a letter's code lands on its glyph; the
  position on the stack; HL its buffer address (`CALC_VIDBUF_ADDR`); the
  colour into A' -- from `PRINT_ATTR`, or from the string's first byte.
  `TEXT_ATTR_ADDR` ($BBC2) makes HL' the attribute address;
  `PRINT_TEXT_CHAR` ($BBCB) draws each character and colours its cell;
  `PRINT_TEXT_LAST` ($BBDE) the one with bit 7 set.
- `PRINT_CHAR` ($BBEB): a space becomes code $3D, a blank glyph; eight bytes
  from `FONT_BASE` + 8 x code, written from HL towards the start of the
  buffer (32 bytes a row); HL comes back one byte right. `PRINT_GLYPH`
  ($BBFA) is the entry with HL already 8 x code, used by the clock.
- **The font's punctuation** (drawn from its bytes): `;` is a full stop, `<`
  a dash, `>` the copyright sign, `=` blank, and code $3A a second nought
  ([`clock.md`](clock.md)).
- **Numbers**: `PRINT_BCD_NUMBER` ($BA62) sets `FONT_BASE` to the font
  itself, then `PRINT_BCD_BYTE` ($BA6A) prints both digits of B bytes from
  DE, high first; `PRINT_BCD_LSD` ($BA74) starts with the low digit only.
  `PRINT_LIVES` ($BA57): `LIVES` at pixel (128, 7). `PRINT_CHAMBERS`
  ($A7A3): `CHAMBERS` at byte column 4, pixel row 31.
  `PRINT_SUMMARY_COUNTS` ($BA36): the summary's counts.

**The panel** (*read*; the pieces *measured*):

- `TRANSFER_SPRITE_AND_PRINT` ($CB06): `TRANSFER_SPRITE` ($CAF1) copies a
  four-byte entry (graphic, flags, x, y) into +$00, +$07, +$1A, +$1B of
  `PANEL_RECORD` ($BD38), a spare object record, and `PRINT_SPRITE` draws it
  at that pixel position. `MULTIPLE_PRINT_SPRITE` ($BC56) draws one B times,
  stepping x by E and y by D.
- `DISPLAY_PANEL` ($CB0F), on a room's first turn: `PANEL_DATA`'s twelve
  entries (flags bit 6 mirrored, bit 7 upside down; y up from the bottom):

  | Entry | Graphic | At | Drawn |
  |---|---|---|---|
  | 0 | 9 | (16, 48) | five, 16 right and 8 down: the left slant |
  | 1 | 10 | (0, 0) | six, 8 apart up the left edge |
  | 2 | 7 | (0, 48) | once, the cap on the left edge |
  | 3 | 8 | (96, 0) | once, the foot of the left slant |
  | 4 | 9 mirrored | (224, 48) | five, 16 left and 8 down |
  | 5 | 10 mirrored | (248, 0) | six up the right edge |
  | 6 | 7 mirrored | (240, 48) | once |
  | 7 | 8 mirrored | (144, 0) | once |
  | 8 | 12 | (112, 0) | the robot, beside the lives |
  | 9 | 84 | (224, 9) | the right half of the light years' frame |
  | 10 | 84 mirrored | (200, 9) | the left half |
  | 11 | 131 | (8, 24) | the icon beside the chambers count |

- `COLOUR_PANEL` ($A749), then: every attribute = `ROOM_INK` with BRIGHT;
  the lives' cells bright white; `COLOUR_CLOCK_BOX` ($A7AE) paints three rows
  of six cells from `CLOCK_BOX_COLOURS` ($A7CA: red and white); the carried
  things (`SHOW_CARRIED_NOW`, [`picking-up.md`](picking-up.md)); the label
  colour 2 + (7 - ink) with BRIGHT written into the first byte of
  `LIGHT_YEARS_TEXT` ($A797, the printer's colour byte) and the label
  printed with `PRINT_TEXT`; the chambers count (`PRINT_CHAMBERS`) with its
  cells white; the chambers icon (3 by 3 cells) in the label's colour; the
  lives. Room inks are 3-6 on the tape and 7 once a chamber is activated,
  so the label is yellow, cyan, green, magenta or, in an activated chamber,
  red -- never the room's colour.
- **The border** (`PRINT_BORDER` $CB8A, from `BORDER_DATA` $CBC3): the
  corner (graphic 4, 32 by 32) four ways; top and bottom edges of 24
  graphic-6 pieces 8 apart from x 32; sides of 128 graphic-5 pieces a pixel
  apart from y 32 (graphic 5 is 24 pixels wide and one high). Drawn by the
  first text list of the menu and of the screens after a game.
- **Clearing** (`CLEAR_SCRN` $CE73): a black border, every attribute bright
  red on black ($42, `CLR_ATTRIBUTE_MEMORY` $CE68), the bitmap cleared.

## How this was found

Read, against Knight Lore's `do_menu_selection`, `flash_menu`,
`toggle_selected`, `display_text_list`, `print_text_single_colour`,
`print_text`, `print_8x8`, `print_BCD_number`, `display_panel` and
`print_border` (0.4 to 1.00) and Pentagram's `MENU` (0.87), `FLASH_MENU`
(1.00), `DISPLAY_MENU` (0.96) (stage 2, ranges 1, 3 and 5). The font's
punctuation drawn from its bytes. *Measured*: the panel -- `BUILD_LOOKUP_TBLS`,
`CLEAR_SCRN_BUFFER` and `DISPLAY_PANEL` run in the simulator on the
snapshot, the buffer's bottom 64 rows drawn to a picture, and the routine
run again twelve times with one entry's graphic made 0; the difference is
where that entry lands, all as read. A simulator screenshot of play showed
the panel coloured as described (the label green over a cyan room).
`FILL_BOX`'s self-modification worked through by hand for B = 3 and 8.

## Confidence

*Read*; the panel's pieces and colours *measured*. That graphic 131 is the
chambers icon rests on its place beside the count; what it is meant to
picture is not claimed.

## Knight Lore and Pentagram

The menu is Knight Lore's, key 5 and all: directional control is a menu
choice here, as in Knight Lore and not in Pentagram
([`../knightlore/status-and-menu.md`](../knightlore/status-and-menu.md),
[`../pentagram/menu-and-panel.md`](../pentagram/menu-and-panel.md)). A
changed choice beeps, as Knight Lore's does; Pentagram's is silent.
`PRINT_TEXT`, which Pentagram kept only as unreached bytes, is used here
(the panel's label, the ratings). The eight menu colours are all used
(Pentagram cleared one more flash bit than it had lines). Knight Lore's
`display_panel` draws six entries; Alien 8's twelve add the edges and the
three icons. `print_border` and its data are Knight Lore's shape (Pentagram's
border is 8 and 6 pieces 24 apart). Knight Lore's attribute default is
bright yellow, Alien 8's bright red. Knight Lore's `colour_panel` is still in
the block at $CBE3, never called ([`leftovers.md`](leftovers.md));
`COLOUR_PANEL` is Alien 8's own. `FILL_BOX` has no counterpart in either.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `COLOUR_PANEL` | `SUBA749` | $A749 | the screen's and the panel's colours |
| `LIGHT_YEARS_TEXT` (`_END`) | `TEXTA797`, `DATAA7A2` | $A797 | the colour byte and the label |
| `PRINT_CHAMBERS`, `COLOUR_CLOCK_BOX`, `CLOCK_BOX_COLOURS` | `SUBA7A3`, `SUBA7AE`, `TEXTA7CA` | $A7A3-$A7CA | |
| `PRINT_SUMMARY_COUNTS`, `PRINT_LIVES` | `SUBBA36`, `SUBBA57` | $BA36, $BA57 | numbers |
| `MENU` (`MENU_LOOP`, `MENU_BEEP_IF_CHANGED`, `MENU_KEY5_RELEASED`), `FLASH_MENU` | `SUBBA7E`, `SUBBAFB` | $BA7E, $BAFB | the menu |
| `MENU_COLOURS` ... `MENU_COPYRIGHT_LAST` | `TEXTBB14` ... `DATABB9C` | $BB14-$BB9C | its tables |
| `PRINT_TEXT_SINGLE_COLOUR`, `PRINT_TEXT` (`TEXT_ATTR_ADDR`, `PRINT_TEXT_CHAR`, `PRINT_TEXT_LAST`), `PRINT_CHAR` (`PRINT_GLYPH`) | `SUBBB9D`, `SUBBBB1`, `SUBBBEB` | $BB9D-$BBEB | text |
| `TOGGLE_SELECTED`, `FLASH_NEXT_ONE` | `SUBBC15`, `SUBBC1C` | $BC15, $BC1C | flash one of B colours |
| `DISPLAY_MENU` (`DISPLAY_TEXT_LIST`), `MULTIPLE_PRINT_SPRITE` | `SUBBC25`, `SUBBC56` | $BC25, $BC56 | |
| `TRANSFER_SPRITE_AND_PRINT`, `DISPLAY_PANEL`, `PANEL_DATA` | `SUBCB06`, `SUBCB0F`, `DATACB5A` | $CB06-$CB5A | the panel |
| `PRINT_BORDER`, `BORDER_DATA` | `SUBCB8A`, `DATACBC3` | $CB8A, $CBC3 | the border |

## Disassembly corrections

- `CLOCK_BOX_COLOURS` ($A7CA) was a text entry in stage 1 (its bytes read as
  letters): it is attributes, three rows of six (range 1).
- `LIGHT_YEARS_TEXT`'s first byte is a colour written at run time, now shown
  as a byte before the text (range 1).
