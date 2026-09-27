# The menu, the panel and the end screens

**Question this answers:** how the game draws its menu, the panel under a
room (lives, score, carried things), the border, and the winning and
game-over screens; and how the menu chooses a control method.

**Short answer:** one list printer, `DISPLAY_TEXT_LIST` (in `DISPLAY_MENU`
$BCB4), prints a list of strings, each at a pixel position in its own colour,
into the screen buffer; the first list after `FRAME_DRAWN` is cleared also
draws the border and shows the buffer. The menu, the win and the game over are
each three tables (colours, positions, strings) handed to it. Fixed pictures
-- the border, the panel's scroll-work, the lives icon, the carried things --
are sprites drawn through a spare object record, `PANEL_RECORD` ($BACA).
Nearly all of it is Knight Lore's code.

## How it works

**Text.** Strings are ASCII with bit 7 set on the last character. `PRINT_CHAR`
($BAEA) draws eight bytes from `FONT_BASE` + 8 x code down the buffer,
overwriting; a space is printed as code $3D. For text `FONT_BASE` is 384
bytes below `FONT` ($8355), so codes $30-$5A land in its 43 characters; for
numbers it is `FONT` itself, so digits are codes 0-9. The font draws the code
of `<` as a copyright sign and `:` as a full stop (*read*; seen in the
simulator's render of the menu). `PRINT_TEXT_SINGLE_COLOUR` ($BC66) selects
the text font and the buffer address and runs on into `TEXT_ATTR_ADDR`
($BC8B), which colours each character's cell directly in the attribute file
with `PRINT_ATTR` ($A736). Positions are pixels, y counting up from the
bottom.

**The list printer** (`DISPLAY_TEXT_LIST`, the end of `DISPLAY_MENU`): for
each line, the colour into `PRINT_ATTR` and the string printed. At the end,
if `FRAME_DRAWN` ($A734) is 0 it is set, the border drawn (`PRINT_BORDER`
$BD59) and the whole buffer shown (`SHOW_BUFFER`). Later lists only redraw
into the buffer and write attributes -- which is how the menu's flashing line
changes every pass of its loop without the screen being redrawn. The menu
and the win clear the flag first.

**The menu** (`MENU` $BB74, before every game): clear the flash on the
colours, clear the buffer, clear `FRAME_DRAWN`, draw the lines
(`DISPLAY_MENU`), flash the chosen method (`FLASH_MENU` $BBD8). Then a loop:
reprint, play `TUNE_MENU` once per game (`PLAY_TUNE_ONCE` $D69C, which any key
cuts short; `TUNE_HEARD` $A747), read keys 1-4 into bits 1-2 of `CONTROL`
(the highest held wins, each being applied in turn), key 0 returns, and count
`MENU_PASSES`. The tables: seven colours at `MENU_COLOURS` ($BBF1: magenta for
the title, green for the four methods, white for the start and copyright
lines), seven (x, y) pairs from `MENU_XY` ($BBF8), seven strings from
`MENU_TEXT` ($BC06) -- split into many small entries only because the code
map could not see where the text starts. Key 5 is not read.

**The flashing** (`FLASH_MENU`, with `TOGGLE_SELECTED` $BB64 and
`FLASH_NEXT_ONE` $BB6B): FLASH on the chosen method's colour and off the
other three; then off the next colour and on again if bit 3 of `CONTROL` is
set. In Knight Lore that next line is the directional-control option; in
Pentagram it is the start line, and since no menu choice sets bit 3 the start
line never flashes. `MENU` likewise clears FLASH on eight colour bytes, the
eighth being the first position byte, as Knight Lore's menu has eight lines
(*read*).

**Leftovers in the menu**: `LD HL` of `MENU_SPARE` ($A735) overwritten by the
next instruction, and a compare with `CONTROL_BEFORE` ($A70C) whose flags
nothing reads -- perhaps once a test for whether the choice had changed
([`leftovers.md`](leftovers.md)).

**The border** (`PRINT_BORDER`, from `BORDER_DATA` $BD98, ten four-byte
entries: graphic, flags, x, y): graphic 5 in the four corners, turned by flag
bits 6 and 7; graphic 4 eight times along the top and bottom, 24 pixels apart,
and graphic 3 to close each; graphic 2 six times up each side. It frames the
menu and the end screens; a room has none. The helpers: `TRANSFER_SPRITE`
($BDC0, four bytes into +$00, +$07, +$1A, +$1B of `PANEL_RECORD`),
`TRANSFER_SPRITE_AND_PRINT` ($BDD5) and `MULTIPLE_PRINT_SPRITE` ($BDDE, B
copies stepping E in x and D in y).

**The panel** under a room, drawn on its first turn by the main loop:

- `DISPLAY_PANEL` ($BCE5) from `PANEL_DATA` ($BD31): a slanting run of five
  of graphic 62 on each side, graphics 61 and 60 up each edge, graphics 58 and
  59 once each side, the left the right mirrored, in the room's colour.
- `DRAW_LIVES` ($C29A): graphic 22, a little Sabreman, at (16, 32), six bright
  white attribute cells, and `LIVES` as two digits in character row 19; again
  when a quest item adds a life.
- `SHOW_CARRIED` ($BA34, every turn from `RENDER_DYNAMIC_OBJECTS`, acting only
  when `PANEL_DUE` $A720 is set; the main loop enters at `SHOW_CARRIED_NOW`
  $BA3D on a new room): `CARRIED_SHOWN`'s two entries and `CARRIED_LAST` in
  three 24-pixel boxes at pixel x 16, 40 and 64 along the bottom -- each
  cleared (`FILL_RECT`), the sprite drawn through `PANEL_RECORD` with no flip
  bits (so it is turned back to its stored way), copied to the screen
  (`BLIT_TO_SCREEN`), and its 3 x 3 attribute cells coloured by the graphic's
  low three bits from `CARRIED_COLOURS` ($BAC2: bright ink on black -- blue,
  red, magenta, green, cyan, yellow, white, white).
- The score: `PRINT_SCORE` ($BB14) prints the heading (`SCORE_TEXT` $BB24) at
  (192, 31) in bright white and the six digits at (184, 16), at a game's or a
  room's start and again after the main loop's attribute fill. `ADD_SCORE`
  ($BB29) adds C to the last byte of `SCORE`, B to the middle, with the carries,
  and prints the digits (`PRINT_SCORE_DIGITS` $BB3B, `PRINT_BCD` $BB48,
  `PRINT_BCD_LSD` $BB5A, which the lives and the percentage share);
  `SHOW_SCORE` ($B145) copies them to the screen
  ([`bolts-and-sky.md`](bolts-and-sky.md)).

**The winning screen** (`WON` $C302, from the fifth collectable): clear the
buffer, bright cyan attributes, six lines from `WON_CONGRATULATIONS` ($C38B)
with `WON_XY` ($C3DD) and `WON_COLOURS` ($C3E9), `FRAME_DRAWN` cleared so the
list draws the border and shows the screen, `TUNE_WON` played through; the
text names the next Sabreman game, Mire Mare, which was never released, and
spells "completed" with an extra A. Then on into:

**The game-over screen** (`GAME_OVER` $C323): yellow attributes, the border,
three lines (`OVER_COLOURS` $C35D, `OVER_XY` $C360, strings from
`OVER_GAME_OVER` $C366), the percentage after the third (`PERCENTAGE`
$C6EA, [`percentage.md`](percentage.md)), the screen shown, `TUNE_OVER`, a
wait of about four seconds (64 times 8192 turns of a 26 T-state loop, with
interrupts off), one return address dropped and a jump to `AFTER_GAME`
($AF93): the menu again.

## How this was found

Read, each routine against its Knight Lore counterpart in `kl_matches.txt`
(`display_text_list` 0.92; `print_text_single_colour`, `transfer_sprite`,
`transfer_sprite_and_print`, `multiple_print_sprite` and `flash_menu` 1.00;
`print_border` 0.76; `display_panel` 0.59; `show_carried_slot` and
`display_object` 0.55-0.66 for `SHOW_CARRIED`) -- stage 2, ranges 2 and 3.
The menu and a room were drawn by running the game in SkoolKit's simulator
and rendering the screen: the copyright sign and full stops, the border, the
panel's scroll-work, the lives icon and digits as described. The table
layouts were read from the code that walks them and checked against the drawn
menu. The panel's box positions and attribute rows were worked out from
`CALC_VIDBUF_ADDR`, `CALC_VRAM_ADDR` and `CALC_ATTRIB_ADDR`.

## Confidence

*Read*; the menu and the panel *measured* (drawn in the simulator). The win
and game-over screens are read here, and were reached by the build's quest
and game-over sessions.

## Knight Lore

([`../knightlore/status-and-menu.md`](../knightlore/status-and-menu.md))

- Knight Lore's menu has eight lines; Pentagram's seven -- the directional
  control line went, but its flashing and clearing did not (above).
- Knight Lore's strings could carry a colour byte (`print_text_std_font`,
  `print_text`). Pentagram's do not, but the code is still there, unreached,
  at `PRINT_TEXT_STD_FONT` ($BC7A), running into `TEXT_ATTR_ADDR`.
- Knight Lore's `print_lives_gfx` draws only the icon; `DRAW_LIVES` also
  prints the number.
- The score and the carried things' colours are Pentagram's own.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `SHOW_CARRIED` | `SUBBA34` | $BA34 | the panel's carried things |
| `CARRIED_COLOURS` | `TEXTBAC2` | $BAC2 | attribute by graphic (was taken for text) |
| `PANEL_RECORD` | `SPACEBACA` | $BACA | the spare drawing record |
| `PRINT_SCORE` | `SUBBB14` | $BB14 | heading and digits |
| `SCORE_TEXT`, `SCORE_TEXT_END` | `TEXTBB24`, `DATABB28` | $BB24, $BB28 | the heading |
| `TOGGLE_SELECTED`, `FLASH_NEXT_ONE` | `SUBBB64`, `SUBBB6B` | $BB64, $BB6B | flash one of B attributes |
| `FLASH_MENU` | `SUBBBD8` | $BBD8 | flash the chosen line |
| `MENU_COLOURS`, `MENU_XY`, `MENU_TEXT` and the pieces between | `TEXTBBF1`, `DATABBF9` ... `DATABC65` | $BBF1-$BC65 | the menu's tables |
| `PRINT_TEXT_SINGLE_COLOUR` | `SUBBC66` | $BC66 | print a string in `PRINT_ATTR` |
| `PRINT_TEXT_STD_FONT` | `DATABC7A` | $BC7A | unreached: a string with a colour byte |
| `TEXT_ATTR_ADDR` (and `PRINT_TEXT_CHAR`, `PRINT_TEXT_LAST`) | `SUBBC8B` | $BC8B | the printer's body |
| `DISPLAY_MENU` (and `DISPLAY_TEXT_LIST` $BCC0) | `SUBBCB4` | $BCB4 | the menu; the list printer |
| `DISPLAY_PANEL`, `PANEL_DATA` | `SUBBCE5`, `DATABD31` | $BCE5, $BD31 | the scroll-work |
| `PRINT_BORDER`, `BORDER_DATA` | `SUBBD59`, `DATABD98` | $BD59, $BD98 | the border |
| `TRANSFER_SPRITE`, `TRANSFER_SPRITE_AND_PRINT`, `MULTIPLE_PRINT_SPRITE` | `SUBBDC0`, `SUBBDD5`, `SUBBDDE` | $BDC0-$BDDE | drawing through the spare record |
| `DRAW_LIVES` | `SUBC29A` | $C29A | the lives icon and number |
| `OVER_COLOURS` ... `OVER_COMPLETED_LAST` | `TEXTC35D` ... `DATAC38A` | $C35D-$C38A | the game-over tables |
| `WON_CONGRATULATIONS` ... `WON_COLOURS` | `TEXTC38B` ... `TEXTC3E9` | $C38B-$C3EE | the winning tables |
| `FRAME_DRAWN` | `UNKNOWN_A734` | $A734 | the text screen's frame is drawn |
| `MENU_SPARE` | `UNKNOWN_A735` | $A735 | an unused variable |

## Disassembly corrections

- `PRINT_ATTR` was "the attribute the print routine colours with":
  `PRINT_CHAR` never reads it; the text printer `PRINT_TEXT_SINGLE_COLOUR`
  does.
- `CARRIED_COLOURS` was taken by sna2ctl for text (the codes of eight
  capitals).
- Two drafts suggested `FRAME_DRAWN` and `SCREEN_SHOWN` for $A734; the merge
  took `FRAME_DRAWN`.

## Open questions

- The menu, game-over and winning tables stay split into many entries; a
  `; span` over each would make them one block with sub-blocks. Kept split by
  decision at the merge.
- The score's digits sit at pixel rows 9-16, which straddle two attribute
  rows; what colour they show in has not been looked at.
