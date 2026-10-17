# The panel and the menu

**Question this answers:** how the menu works and what it stores, how the
panel round the play area -- scores, lives, frame, fuel gauge -- is drawn
and kept up to date, how text is printed, and how the planet-secured
screen is put together.

**Short answer:** all of it is drawn from data by a handful of small
routines: `print_string` ($A115) prints a record of x, y, attribute, count
and character codes in the game's own 45-character font; `draw_bitmap`
($C96F) and `fill_attributes` ($C991) copy a byte-aligned bitmap and paint
a rectangle of attributes, both bottom row first; `draw_frame` ($CACB)
draws a frame from a 17-byte description, one for the menu and one for the
game. The panel is drawn once a life; after that only the score, the
lives and the fuel gauge change, the gauge's column moved one row a pass
by toggling two rows with XOR.

## How it works

### Drawing primitives

Everything on this screen draws upwards from its bottom row, as the
game's graphics are stored bottom row first.

| Routine | Takes | Does |
|---|---|---|
| `pixel_to_screen` $A149 | L = x, H = y (from the top) | the standard screen address |
| `pixel_to_attribute` $A170 | the same | $5800 + 32 x (y/8) + x/8 |
| `line_up_hl` $A1C3, `line_up_de` $A1B3 | a screen address | one pixel line up, crossing character rows and thirds; about 47 T-states with the CALL |
| `draw_bitmap` $C96F | H = bottom y, L = x, DE = a bitmap: width in bytes, height, rows bottom first | copies it, overwriting; returns DE past it |
| `fill_attributes` $C991 | H, L the bottom-left pixel, DE = width in cells, height, attribute | paints the rectangle upwards; returns DE past it |
| `print_string` $A115 | DE = a text record | prints it; returns DE at the next record |
| `print_strings` $83CE | DE, B | B records in a row |

A **text record** is: x in pixels, y (the line the characters' bottom
rows go on), an attribute byte (bit 7 set for double size, the other seven
the colour, so text can never FLASH), a count, and that many character
codes. Lists of them follow one another, so a whole screen of text is one
call of `print_strings`.

### The font and the printer

`font` ($9F76): 45 characters of seven bytes, bottom row first, bit 0 of every
row clear for the gap between characters; the eighth line of the cell is left
blank. Codes: 0-25 the letters, 26-35 ($1A-$23) the digits (a digit's code is
$1A plus the digit, which is how the score is printed), 36 and 38 spaces, 37
the "II" of "INTERFACE II" (both letters in one cell, *read* from the menu's
text), 39 a full stop, 40 a dash, 41-44 four pieces of a small picture (the
rule under the menu's title).

`print_char` ($A0B1) finds a character at `font` + 7n (worked out as 8n -
n) and ends in a JR whose displacement (the byte at $A0CA) `print_string`
writes before every string: 0 reaches `print_char_rows` ($A0CB), $10
reaches `print_char_double` ($A0DB). In the snapshot the displacement is
$FE, a jump to itself, but it is always written first.

- Normal size: seven rows up the screen, then the colour from the other
  register set (B' the attribute, HL' its address, which moves on a cell).
- Double size: each row's two nibbles are doubled to a byte each through
  `double_bits` ($5C84, sixteen bytes; B holds $5C and C = $84 + the
  nibble, so the table must not cross a page), each written on two lines:
  16 by 14 pixels, and a 2 by 2 block of attributes. It steps lines with a
  plain DEC H inside each pair, which is safe only because a string starts
  on an odd line of its cell.

### The menu

```
menu $F26C
  clear_pixels, clear_attributes
  draw_frame from menu_frame $F22A    (corners $F202, ticks $F21E, set here)
  print_strings: 12 records at menu_text $F112
  draw_bitmap: the two glyphs of the copyright line (copyright_glyphs $F2E3)
  a rule under the title, written straight to the screen
  move_method_arrow for each player       the arrows at their methods
  menu_show_players                       the chosen line white
  play_tune_until_key title_tune          any key stops it (sound.md)
  menu_loop $8615                         until 0
  menu_show_players; play_tune start_tune $F4E4
menu_loop $8615, each pass
  random $F23B; pass_counter + 1
  move_method_arrow $8690 for player 1, then player 2
  colour_player_line $8666 for the one- and two-player lines
  delay with D = $18 (about 100,000 T-states)
  key 0 (half-row $EF, bit 0)? return
  menu_keys $86B9
```

The twelve records are the title (double size), the one- and two-player
lines, the start line, the four control methods (the two joystick lines in
two parts each), the copyright line and the rule.

**The keys** (`menu_keys`): A chooses one player, B two (`player_count`,
$F2E2: 0 or 1); 1 and 2 step player 1's and player 2's control method on
through 0-3 -- Keyboard, Kempston, Cursor, Interface II -- but
`cycle_method` ($86E4) steps only while that player's arrow stands at the
line of the method it has, so a held key steps once per arrival rather
than once a pass. 0 starts. Every read goes through `OUT ($FD),A` first
([`input.md`](input.md)).

**The arrows.** Each player has a pointer record: `player1_pointer`
($8708) and `player2_pointer` ($870B), three bytes each -- x ($38 and $B8),
the line it stands at, and the control method. `method_lines` ($8704)
holds the four methods' lines ($6F, $83, $9B, $AF). `move_method_arrow`
moves the arrow one line a pass down towards its method's line, or four
lines a pass up, and draws it with `draw_bitmap` at its x and line. The
graphics -- `pointer_p1_graphic` ($870E, an arrow pointing right marked
P1) and `pointer_p2_graphic` ($874F, pointing left, P2) -- are 3 bytes by
21 lines with four blank lines at the foot and one at the head: drawing
over the old arrow, the blank lines are exactly what is needed to rub out
what it leaves behind moving up four or down one, so there is no erase.
The methods chosen are what `new_game` copies into each player record
(+28, from $870A and $870D).

**The one- and two-player lines.** `colour_player_line` paints a 9 by 1
patch (`player_line_colour`, $868D, its attribute rewritten each time):
bright magenta, or bright white when it is the chosen line and bit 2 of
`pass_counter` is set, so the choice flashes every four passes.
`menu_show_players` sets that bit, so the choice is steady white while the
tunes play.

### Frames

`draw_frame` ($CACB) draws a frame from a 17-byte description in IX:

| Offset | Field |
|---|---|
| +0, +2 | the screen addresses of the bottoms of the left and right sides |
| +4 | their height in rows (a $66 byte each row) |
| +5, +7 | the screen addresses of the two horizontal edges (two rows of $FF, a gap of two, two rows: `fill_edge_rows` $CC38) |
| +9 | the corner list: four entries of seven bytes -- the corner bitmap's place, a colour patch's place, its width, height and attribute; the bitmaps follow one another |
| +11 | the number of ornament pairs |
| +12 | their list: an x for the top and bottom edges, a y for the sides |
| +14 | the y of the bottom edge's ornaments (the top's is $BE) |
| +15 | the x of the right side's (the left's is 0) |
| +16 | the edges' width in bytes |

The menu's is `menu_frame` ($F22A), with `menu_frame_corners` ($F202) and
`menu_frame_ticks` ($F21E); the game's is `frame_description` ($CA1D),
with `frame_corners` ($CBF8: the corner patches are the frame's colour,
bright cyan on blue, the edges 30 cells by 1 and the sides 1 by 20),
`corner_bitmaps` ($CC14), `ornament_places` ($CBE5), `edge_ornament`
($C94D) and `side_ornament` ($C955). The callers set +9 and +12 before
the call.

### The panel

```
draw_panel $CA3F           by game before a game, by play every life
  score line colours: $C9EE yellow (the current player), $C9FE red
  panel_patch $CA2E        white, 20 by 2 cells, behind the top
  print_lives $CA31        the current player's lives digit
  p2_lives_digit           the waiting player's
  print_strings: 8 records from score_labels $C9DA
  draw_bitmap score_bitmap $C927 under each score (x $30 and $B0)
  draw_frame frame_description
  flash_fuel_gauge (always yellow here), draw_fuel_gauge $CBAE
  fuel_label_patch $CBA8 (cyan) and fuel_label $CB66 beside the gauge
```

The eight text records: SCORE twice (`score_labels`), player 1's score
(`p1_score_text` $C9EC, digits `p1_score_digits` $C9F0), player 1's lives
(`p1_lives_text` $C9F6, digit $C9FB), player 2's score and lives
(`p2_score_text` $C9FC, `p2_lives_text` $CA06), HI (`hi_label` $CA0C) and
the high score (`hiscore_text` $CA12, digits `hiscore_digits` $CA16). A
score line and its lives are one 16-byte block, which `swap_players`
swaps whole -- position included -- so the current player's is always at
$C9EC ([`players.md`](players.md)).

The lives shown: a '0' and a digit. The current player's digit is `lives`
+ $19, so the ship in play is not counted (`print_lives`, also called by
`contact_extra_life`); the waiting player's is all their lives, + $1A.

`score_bitmap` (4 bytes by 9 rows) is the ship icon under each score --
the same picture is frame 8 of type $1C, the extra-life pick-up. Damage
recolours it, a 4 by 2 attribute patch at x $30 or $B0 by
`player_in_play` (`icon_patch_record` $8FBF): yellow after the first hit,
magenta after the second, black after the third; white again after a
repair on a refuel pad.

### The fuel gauge

The fuel is a word, `fuel` ($CC4B), its high byte the gauge's level as a
screen line: $42 full, $BE empty, so burning makes it larger. Only
`add_fuel` ($CC4D) changes it, clamping the high byte between the two.

| Change | Amount (per pass, in 256ths of a line) |
|---|---|
| steering or thrusting (`read_controls`) | +8; +16 doing both; halved with add-on 6, halved again while `fuel_saver` is set |
| the refuel pick-up (`contact_refuel`) | -$1C00: 28 lines |
| the fuel thief (`contact_drain_fuel`) | +$1000: 16 lines |
| a refuel pad (`ship_hits_ground_objects`) | set to $4200, full |
| a life's start (`start_landscape`) | $4200; the shown level from $BE |
| the death sequence | $BE00, empty |

So a full gauge lasts 124 lines x 32 passes = 3,968 passes of steady
steering or thrust -- over three minutes at 20 passes a second -- and half
that doing both (*counted*, not timed).

**The outline** (`draw_fuel_gauge`): a tube at x $F0-$FF, two single-pixel
walls (a $10 in each of two bytes) for 120 rows, and a 2 by 4 cap at each
end, drawn at line $BF (the foot, from `gauge_top_cap`) and line $43 (the
top, from `gauge_bottom_cap`).

**The column** (`update_fuel_gauge` $CC77, once a pass, twice in the death
sequence). `fuel_shown` ($CC62) is the line the column reaches; each call
moves it one line towards the fuel's level by toggling two rows with XOR:
$03,$80 -- three pixels, x $F6-$F8 -- at one row and $04,$40 -- the two
either side, $F5 and $F9 -- at the row below. Two neighbouring steps
overlap, so every row inside the column ends with all five pixels and the
top row with the middle three: a rounded top, kept up to date by writing
two rows a pass, never redrawing the column. Filling, the toggled rows are
the new level and the one under it; burning, the old level and the one
under it, which takes the top's three pixels away and leaves the next
row's middle three as the new top. At a life's start the shown level
climbs from empty to full a line a pass, 124 passes. When the shown level
is already the fuel's, `check_fuel_empty` ($CC63) runs instead
([`main-loop.md`](main-loop.md)).

**The colour** (`flash_fuel_gauge` $CAA7, odd passes): the 2 by 16 cell patch
`gauge_patch` ($CBAB) at x $F0, its attribute `gauge_colour` ($CBAD): yellow,
or with the fuel's high byte at $98 or more (seven tenths used) red on two
passes in four. It is the fuel's level, not the level shown (`fuel_shown`
$CC62), so the flash can start or stop while the column is still moving
(*read*, and *run* in SkoolKit's simulator for the Animations page).
`draw_panel` enters near the end for plain yellow.

### The planet-secured screen

Drawn by `planet_secured` ($83D6), called by `level_done` after a clear
of the play area:

```
print_strings: four records at planet_secured_lines $84A9
               (white, then three lines yellow)
copy the planet's name (16 characters) from planet_names $8459
  into planet_secured_name_text $8505
the next planet's name (15 characters; after the fifth, the first)
  into next_planet_name_text $8527
print_string planet_secured_name $8501         the name, white
rocket_x, rocket_y reset; level + 1
print_strings: four records from next_planet_lines $8515
               (a line, the next name in green, the two lines at
                next_planet_lines_end $8536)
rocket_part_carried = parts_built = 6
10 times: 5000 points (add_score), sound_zap, delay with D = $FF
deal place_last again; mask_world_objects for the current player
```

`planet_names` holds the five names, 16 codes each, centred with spaces.
The planet's records are filled in by copying a name into the middle of a
fixed list of records, which then prints with the rest in one call: the
same trick a new game could use for any templated message.

## How this was found

Read from the code in the stage 2 description of the listing
(2026-10-16): `menu`, `menu_loop`, `menu_keys`, `move_method_arrow`,
`colour_player_line`, `draw_panel`, `draw_frame`, `draw_fuel_gauge`,
`update_fuel_gauge`, `flash_fuel_gauge`, `add_fuel`, the printer and
`planet_secured`. The range-6 draft checked the text records' decoding by
rendering the font from the snapshot. Stage 0 played the menu (the
control keys and 0) in a live session.

## Confidence

*Read*, with the menu and the panel also run in the build's sessions -- every
routine above, and since the staged launch `planet_secured` too, which draws
the planet-secured screen (`cyberun-executed.map`). Only its wrap from the
fifth planet's name to the first ($83F9) never ran. The fuel's lasting time is
counted from the code's numbers, not timed.

## Corrections

- Stage 0 (`damage-fuel-lives.md`) had the hits recolour the ship white,
  yellow, magenta. They recolour the panel's ship icon, yellow, magenta,
  black (the count goes up before the colour is chosen); white is the
  repair. The ship's own colour is `colour_ship` ($F1BD): white, yellow
  with 18 ore aboard, cyan while the shield lasts.
- Stage 0's `input.md` asked where the control method is chosen and
  stored: the menu's pointer records, copied to +28 of each player record.
- The listing's descriptions of `draw_panel` and `draw_frame` (and of
  `contact_damage` and `add_score`) refer to `unused_attribute_bitmap`
  ($C9B3) where they mean the panel's text records, `score_labels`,
  `frame_description`, `player_in_play` or `p1_score_digits`: their
  annotations still say #R$C9B3 from before that block was split into
  entries. To fix in `cyberun_annotations.ctl`.
- The gauge's caps are labelled the other way up: `gauge_top_cap` is
  drawn at the foot of the tube (line $BF), `gauge_bottom_cap` at its top
  (line $43).
- Font code 37 was called "a symbol"; it is the "II" of "INTERFACE II", the
  only place it is used in the menu's text.
- **Coverage** (2026-10-17): this file said the planet-secured screen was never
  drawn in any session; the staged launch draws it.

## Open questions

- `scroll_landscape` makes four rows of the frame below the play area's
  bottom-left corner solid again every pass: what keeps overwriting them?
  A write watchpoint on that byte would say.
- `panel_leftovers` ($C95D, 18 bytes, nothing refers to them) look like
  the remains of text records, and `unused_attribute_bitmap` is a routine
  nothing calls; `ship_icon_positions` ($8FBB) holds the icons' positions
  as words nothing reads. Leftovers of an earlier panel?
