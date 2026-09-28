# The menu, the printer and the panel

**Question this answers:** how the menu works, how text and frames are
printed, and what the panel shows and how each part is drawn.

**Short answer:** the menu is Alien 8's, instruction for instruction, but
for a tune in place of its beep, the random number stirred on each pass,
and a clear of the play area's buffers. Unlike the earlier games, all text,
frames and the panel are printed straight onto the screen: only the play
area is buffered. The panel shows the carried things in a column at the
left, the lives, the score, the four villains (an outline while alive, the
picture in colour once destroyed), a compass and the heading.

## How it works

```
NEW_GAME
  MENU $C8CA        clear MENU_SHOWN, unflash, CLEAR_BUFFER
    MENU_LOOP $C8E1 DISPLAY_MENU $CA2B (8 lines; PRINT_BORDER the first time)
                    PLAY_TUNE_ONCE (TUNE_MENU); NEXT_TURN; keys 1-5, 0
    FLASH_MENU $C949 -- TOGGLE_SELECTED $CA1B / FLASH_NEXT_ONE $CA22
  TUNE_GAME_START; CLEAR_SCREEN
  DRAW_PLAY_FRAME $CA55, DRAW_PANEL_FRAME $C83F, SCORE_TEXT, PRINT_SCORE,
  PRINT_COMPASS, PRINT_HEADING ... (NEW_LIFE: the lives; DRAW_VILLAINS)
```

- **The menu**: keys 1-4 set bits 1-2 of `CONTROL` (keyboard, Kempston,
  cursor, Interface II; the highest held wins); key 5 toggles bit 3
  (directional control) once a press, by `KEY_LATCH`; a change against
  `LAST_CONTROL` plays `TUNE_CONTROL_CHOSEN`; 0 starts. The chosen lines
  flash (`MENU_COLOURS`, bit 7). Each pass counts a turn and stirs the
  random number, so the time spent on the menu decides the start cell. The
  menu's colours, places and text are laid out by the generator
  (`MENU_COLOURS` $C962, `MENU_PLACES` $C96A, `MENU_TEXT` $C97A).
- **Text** (`PRINT_TEXT_SINGLE_COLOUR` $C9EF, `PRINT_TEXT` $C9FC, whose
  string starts with its colour): positions are pixel x and y with y up
  from the bottom (`CALC_VRAM_ADDR`); `FONT_BASE` is set 384 below `FONT`
  so codes $30-$5A land on it. Each character goes straight to the screen
  by `PRINT_CHAR` ($CB19; a space is printed as code $3C, blank in the
  font; `PRINT_CODE` $CB1F skips that test for icons) and is coloured by
  `PRINT_CHAR_COLOURED` ($CB5B). `NEXT_CHAR_ROW` ($CB71) steps a character
  row down.
- **Frames** are pieces two characters square from `BORDER_CHARS` ($BB0A):
  `PRINT_BLOCK` ($CB3E), repeated by `PRINT_BLOCK_ROW` ($CAFD) and
  `PRINT_BLOCK_COLUMN` ($CB09); `FRAME_PIECES` ($CAE5) lists four corners,
  an edge and a side in those codes. `PRINT_BORDER` ($CA9D) frames the
  whole screen in bright yellow on blue (the menu, the game-over screen);
  `DRAW_PLAY_FRAME` ($CA55) frames the play area, rows 2-15 and columns
  7-28, in yellow on red.
- **The panel's frame** (`DRAW_PANEL_FRAME`): the five `PANEL_CHARS` in
  bright magenta, two uprights in columns 1 and 4 from row 0 to 22 joined
  along row 23: the case the eleven carried things are drawn in
  ([`carrying.md`](carrying.md)).
- **The score** (`ADD_SCORE` $C2ED, `PRINT_SCORE` $C2FF, `PRINT_SCORE_AT`
  $C305): BCD; B is added to the middle byte of `SCORE` ($BBCA), C to
  `SCORE_LOW` ($BBCB). Printed as the lower digit of `SCORE`'s first byte,
  the next two bytes, and `SCORE_ZEROS` ($BBCC), which nothing writes, so
  every score ends 00 and what shows is a hundred times what is added.
  Points: a villain 250000; a walker 2500 (destroyed or touching the
  knight), 2000 (changed), 1500 (split), 1000 (demoted); the creature 1000;
  a wanderer 500 (struck or touching).
- **The heading** (`PRINT_HEADING` $C29A): four characters, north in cyan,
  or south in magenta with the town turned round (`HEADING_CHARS`,
  `HEADING_TURNED_CHARS`, `HEADING_ORDER`); redrawn by `TURN_TOWN`.
- **The compass** (`PRINT_COMPASS` $C2C8): eight characters in yellow as two
  2x2 blocks, `COMPASS_ORDER` ($C2DF) picking them out of the stored 4x2
  picture.
- **The villains** (`DRAW_VILLAINS` $C1FD, at a new game and at each
  strike): each villain's first standing sprite, drawn up from the bottom
  line at columns 15, 18, 21, 24 (records 0-3). Alive: the first byte of
  each pair less the second -- its outline -- in white. Destroyed: the
  second bytes, its picture, coloured from `THING_COLOURS`, three by six
  cells: its object's colour. A sprite stored mirrored is first turned
  back (`MIRROR_SPRITE`, $E3D6).
- **The lives**: five places at row 18 from column 5 (`NEW_LIFE`,
  [`lives-and-starting.md`](lives-and-starting.md)).
- **The play area's attributes**: `COLOUR_STRIP` ($C889, the walls),
  `COLOUR_KNIGHT` ($C898: four rows of two cells at the knight's place, the
  left one bright and the right one not), `FILL_ATTR_RECT` ($C8B2, the
  ending). All mix in `LAST_FLASH`, this turn's paper.

## How this was found

Read against Alien 8's annotated menu and printer (`matches.txt`: `MENU`
0.96, `FLASH_MENU`, `TOGGLE_SELECTED`, `FLASH_NEXT_ONE` 1.00,
`DISPLAY_MENU` 0.75) (stage 2, range 2); the panel by range 1. The frames'
rows and columns worked out from the screen addresses and checked on a
rendered screenshot of a game in progress; the score *measured* ($0025
printed 0002500, $2500 printed 0250000); the villains *measured* (four
outlines at the start; record 0 emptied and redrawn gave its picture in
cyan); the heading and compass drawn from their characters to name them.

## Confidence

*Read*; the layout, the score and the villains *measured*.

## Filmation (Knight Lore, Alien 8, Pentagram)

The menu is Alien 8's; the printer and BCD printing are the family's
(Pentagram's `ADD_SCORE` is the nearest match). The earlier games print
into a screen buffer and copy it; Nightshade prints straight to the
display. Alien 8's `PRINT_CHAR` moves HL on a character; Nightshade's
leaves it, and its callers step L. The space code is $3C here, $3D in
Alien 8. Villains drawn as outlines until destroyed have no counterpart.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `MENU`, `FLASH_MENU`, `TOGGLE_SELECTED`, `FLASH_NEXT_ONE`, `DISPLAY_MENU` | `SUBC8CA`, `SUBC949`, `SUBCA1B`, `SUBCA22`, `SUBCA2B` | | the menu (Alien 8's names) |
| `PRINT_TEXT_SINGLE_COLOUR`, `PRINT_TEXT` | `SUBC9EF`, `SUBC9FC` | | strings |
| `DRAW_PLAY_FRAME`, `PRINT_BORDER`, `FRAME_PIECES` | `SUBCA55`, `SUBCA9D`, `DATACAE5` | | frames |
| `PRINT_BLOCK_ROW`, `PRINT_BLOCK_COLUMN`, `PRINT_BLOCK` | `SUBCAFD`, `SUBCB09`, `SUBCB3E` | | pieces |
| `PRINT_CHAR`, `PRINT_CHAR_COLOURED`, `NEXT_CHAR_ROW` | `SUBCB19`, `SUBCB5B`, `SUBCB71` | | characters |
| `DRAW_PANEL_FRAME`, `COLOUR_KNIGHT` | `SUBC83F`, `SUBC898` | | the panel's case; the knight's colour |
| `DRAW_VILLAINS`, `SCREEN_LINE_UP` | `SUBC1FD`, `SUBC28A` | | the villains on the panel |
| `PRINT_HEADING`, `HEADING_ORDER`, `PRINT_COMPASS`, `COMPASS_ORDER` | `SUBC29A`, `DATAC2C4`, `SUBC2C8`, `DATAC2DF` | | heading and compass |
| `ADD_SCORE`, `PRINT_SCORE`, `PRINT_SCORE_AT` | `SUBC2ED` | $C2ED, $C2FF, $C305 | the score |
| `SCORE_ZEROS` | `UNKNOWN_BBCC` | $BBCC | the score's last two digits |

New labels inside routines: `PANEL_UPRIGHTS`, `MENU_TUNE_IF_CHANGED`,
`MENU_KEY5_RELEASED`, `PRINT_TEXT_CHAR`, `PRINT_TEXT_LAST`,
`FLASH_THIS_ONE`, `UNFLASH_THIS_ONE`, `FLASH_LIST_STEP`,
`DISPLAY_MENU_LINE`, `PRINT_CODE`.

## Disassembly corrections

- `UNKNOWN_BBCC` is the score's last two digits, never written
  (`SCORE_ZEROS`).

## Also found for the stage 3 pages (2026-09-28)

- The font is Knight Lore's, every one of the 39 drawn characters byte for byte, rearranged into ASCII order; Pentagram has all but five of them (byte-compared). No sprite is shared with any of the three earlier games.
- The semicolon prints a copyright sign, the colon a full stop and the equals sign a per cent sign (*drawn* by PRINT_CODE).

## Open questions

- Why the knight's right-hand column is coloured without BRIGHT: a shading
  effect, presumably; not looked at closely on the screen.
