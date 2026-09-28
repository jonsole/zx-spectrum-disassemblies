# Memory map

**Question this answers:** where everything is -- the game's code and
tables, its variables and object records, its buffers -- and which bytes the
tape and the load leave that are not the game's.

**Short answer:** the loader moves the game to $5E00-$E5FF. The level data
and graphics come first ($5E04-$BBA9), then the variables and 23 object
records ($BBAA-$BDFD), then the code with its tables, tunes and text
($BDFE-$E5C3). Above it the game builds its buffers ($E5C4-$F193) and
lookup tables ($F200-$FFFF), which hold only leftovers of the load until it
does. Below $5E00 are the printer buffer with the loader's routine, the
system variables (two of which the game reads, both set by the tape) and
the rest of the BASIC program, into which the game's stack grows.

Every label here is the final listing's (`game_disassembly/nightshade/nightshade.skool`,
stage 2): no placeholder names are left. Everything is *read* from the code,
and each level-data table's extent is checked by `scripts/nightshade_data.py`
walking it the way the code does, unless it says *measured*.

## Regions

| From | To | Label | What |
|---|---|---|---|
| $4000 | $5AFF | | the display; the loading screen goes here |
| $5B00 | $5B7F | `PRINTER_BUFFER` | zeros, unused |
| $5B80 | $5BAA | `LOADER` | the tape's block `1`: R's bit 7, unscramble, move, jump to $5E00 ([`protection.md`](protection.md)) |
| $5BAB | $5BFF | `PRINTER_BUFFER_END` | zeros, unused |
| $5C00 | $5CAF | `SYSTEM_VARIABLES` | the ROM's; `FRAMES` ($5C78, `FRAMES_MIDDLE` $5C79) from the tape's block `3` |
| $5CB0 | $5CB0 | `NMIADD` | `JP (HL)`, from block `2`: every table of routines jumps through it |
| $5CB1 | $5CCA | `NMIADD_HIGH` | the rest of the system variables |
| $5CCB | $5DFF | `BASIC_PROGRAM` | the loader's BASIC, cut short by the game block; the stack grows down from $5E00 into it (to $5DE8 in play, *measured*; two bytes more at every game over) |
| $5E00 | $5E03 | `ENTRY` | `DI`, `JP START` |
| $5E04 | $6203 | `TOWN` | the town map, 32 rows of 32 cells ([`town.md`](town.md)) |
| $6204 | $62A3 | `DRAW_ORDER` | 32 records of five steps ([`drawing-order.md`](drawing-order.md)) |
| $62A4 | $6333 | `BUILDING_TABLE` | 72 words: cell type * 2 + view |
| $6334 | $637B | `BOX_TABLE` | 36 words: cell type to box list |
| $637C | $6541 | `BOXES0` ... | the box lists, four bytes a box, ended by 0 |
| $6542 | $6575 | `TILE_EDGES` | a byte per tile: its edge picture |
| $6576 | $6CB5 | `BUILDING14` ... | 58 building definitions of 32 bytes |
| $6CB6 | $6CDD | `PANEL_CHARS` | 5 characters of the panel's frame |
| $6CDE | $6E35 | `FONT` | 43 characters, codes $30-$5A |
| $6E36 | $6E9D | `TILE_TABLE` | 52 words: tile number to tile |
| $6E9E | $6FD9 | `GRAPHICS` | 158 words: graphic number to sprite |
| $6FDA | $6FDB | `SPRITE0` | the empty sprite of graphics 0, 1, 23, 31 |
| $6FDC | $6FE3 | `EDGE_TABLE` | 4 words: the edge pictures |
| $6FE4 | $7016 | `EDGE0`, `EDGE2`, `EDGE3` | 3 edge pictures |
| $7017 | $7570 | `SPRITE152` ... | sprites |
| $7571 | $7690 | `ICONS` | 36 characters: nine icons of four -- the blank one and things 1-8 |
| $7691 | $7A6E | `SPRITE118` ... | sprites |
| $7A6F | $7B2E | `PANEL_ICONS` | 24 characters: the compass, `HEADING_CHARS` ($7AAF), `HEADING_TURNED_CHARS` ($7ACF), `LIFE_CHARS` ($7AEF) |
| $7B2F | $A256 | `SPRITE12` ... | sprites (95 labels in all, `SPRITE<first graphic>`: 94 pictures and the empty one) |
| $A257 | $BB09 | `TILE0` ... `TILE49` | 51 tiles: a height, then two bytes a row |
| $BB0A | $BBA9 | `BORDER_CHARS` | 20 characters of the frames |
| $BBAA | $BC8D | `RANDOM` ... | the variables (below) |
| $BC8E | $BDFD | `KNIGHT` ... | 23 object records of 16 bytes (below) |
| $BDFE | $E5C3 | `START` ... | the code, with its tables, tunes and text (below) |
| $E5C4 | $F043 | `BUFFER` | the play area's pixels, 24 bytes by 112 lines, row 0 the bottom; it contains `LOADER_LEFTOVER` ($E600-$E7FF: in the snapshot a copy of $E400-$E5FF, the source side of the loader's move, *compared*) and `BUFFER_REST` ($E800-$F043) |
| $F044 | $F193 | `ATTR_BUFFER` | its attributes, 24 by 14 |
| $F194 | $F194 | `ATTR_SPILL` | written one byte past the attributes by `COLOUR_STRIP`; never read or cleared (*measured*) |
| $F195 | $F1FF | `UNUSED_F195` | never touched (*measured*) |
| $F200 | $F7FF | `MIRROR_TABLES` | bit-reversed bytes shifted 2, 4, 6 bits, a page for each half (`MAKE_TABLES`) |
| $F800 | $F8FF | `UNUSED_F800` | the plain set's shift-0 slot, never built or read (*measured*) |
| $F900 | $F9FF | `REVERSE_TABLE` | each byte reversed |
| $FA00 | $FFFF | `SHIFT_TABLES` | bytes shifted 2, 4, 6 bits; in the snapshot zeros, the ROM's machine stack from $FF18 and its UDGs in the last 168 bytes |

*Measured* (stage 1): the Python simulator with a memory recording the first
access to every address of $5B00-$5DFF and $E5C4-$FFFF, from the start
through the menu, a game, a new cell and more play: the only first reads
below $5E00 are `FRAMES`' two bytes and `NMIADD`; the stack reached $5DE8;
above the code nothing is read before it is written; $F195-$F1FF and
$F800-$F8FF are never touched.

## The code, by subject

| From | To | What | Notes |
|---|---|---|---|
| $BDFE | $BEDE | `START`, `NEW_GAME`, `MAIN_LOOP` ... `LIVES_BYTE` | [`main-loop.md`](main-loop.md) |
| $BEDF | $BF94 | `PERCENTAGE`, `PRINT_PERCENTAGE`, `VISIT_CELL` | [`percentage.md`](percentage.md) |
| $BF95 | $C068 | `SPAWN_CREATURE`, `CREATURE_UPDATE`, `STEER_AT_KNIGHT`, `CLEAR_MONSTERS`, `KNIGHT_COLOURS` | [`creature.md`](creature.md) |
| $C069 | $C1DA | `NEAR_KNIGHT`, the walkers and strikes, `APPEARING_UPDATE`, `NEAREST_VILLAIN` | [`monsters.md`](monsters.md), [`antibodies-and-strikes.md`](antibodies-and-strikes.md) |
| $C1DB | $C1FC | `STOCK_BUILDINGS`, `RESET` | [`protection.md`](protection.md) |
| $C1FD | $C331 | the panel: villains, heading, compass, score, BCD | [`menu-and-panel.md`](menu-and-panel.md) |
| $C332 | $C480 | the sounds | [`sound.md`](sound.md) |
| $C481 | $C537 | carrying | [`carrying.md`](carrying.md) |
| $C538 | $C5B3 | touching | [`touching.md`](touching.md) |
| $C5B4 | $C63C | `NEXT_TURN`, `SPAWN_FIND` | [`random-numbers.md`](random-numbers.md), [`finds-and-bonuses.md`](finds-and-bonuses.md) |
| $C63D | $C83E | the tune player, `NOTES`, the six tunes | [`sound.md`](sound.md) |
| $C83F | $CB7A | the panel's frame, attributes, the menu, the printer, the frames | [`menu-and-panel.md`](menu-and-panel.md) |
| $CB7B | $CC55 | the start cell, `NEW_LIFE`, `START_RECORDS` | [`lives-and-starting.md`](lives-and-starting.md) |
| $CC56 | $CDE7 | game over and the ending | [`game-over-and-ending.md`](game-over-and-ending.md) |
| $CDE8 | $CF07 | `SPAWN_MONSTER`, `WANDERING_MONSTER`, `NEXT_FRAME_MOD4` | [`monsters.md`](monsters.md) |
| $CF08 | $CFAE | `DRAW_CELLS` | [`drawing-order.md`](drawing-order.md) |
| $CFAF | $D17C | the depth sort, `DRAW_LIST` | [`depth-order.md`](depth-order.md) |
| $D17D | $D19C | `TURN_CELL`, `TURN_POSITION` | [`projection.md`](projection.md) |
| $D19D | $D4F2 | outlines, walls, tiles | [`drawing-the-town.md`](drawing-the-town.md) |
| $D4F3 | $D588 | the projection, `LOOK_UP_CELL` | [`projection.md`](projection.md) |
| $D589 | $D6D5 | `TABLE_WORD`, `DISPATCH`, `UPDATES`, `NO_UPDATE` | [`main-loop.md`](main-loop.md), [`graphic-numbers.md`](graphic-numbers.md) |
| $D6D6 | $D9A2 | sparkles, bonuses, the cloud, antibodies, objects, villains | [`quest.md`](quest.md), [`finds-and-bonuses.md`](finds-and-bonuses.md) |
| $D9A3 | $D9EA | `FIND_WANDER` | [`finds-and-bonuses.md`](finds-and-bonuses.md) |
| $D9EB | $DCDF | the knight | [`knight.md`](knight.md) |
| $DCE0 | $DE0C | steps and steering | [`movement.md`](movement.md) |
| $DE0D | $E0C3 | `MOVE_SPLIT`, clipping at the boxes | [`collision.md`](collision.md) |
| $E0DD | $E238 | helpers, `MAKE_TABLES`, the copy and the clear | [`drawing-sprites.md`](drawing-sprites.md) |
| $E239 | $E352 | `READ_KEYS`, `READ_CONTROLS`, `PAUSE` | [`input.md`](input.md) |
| $E353 | $E5C3 | sprites, addresses, clearing | [`drawing-sprites.md`](drawing-sprites.md) |

## Tables and data in the code

| Address | Label | What |
|---|---|---|
| $C065 | `KNIGHT_COLOURS` | the knight's attribute by `HITS` |
| $C0D1 | `MONSTER_HIT_TABLE` | 4 routines: a walker struck, by kind sum |
| $C2C4, $C2DF | `HEADING_ORDER`, `COMPASS_ORDER` | the panel's characters in print order |
| $C2E7 | `SCORE_TEXT` | the panel's heading (text) |
| $C34D, $C35D | `BLIP_PITCHES`, `VILLAIN_PITCHES` | five tables of 16 pitches; the last four never read |
| $C3D8 | `EFFECT_TABLE` | the four sound effects |
| $C52F | `THING_COLOURS` | the carried things' and destroyed villains' colours |
| $C6B9 | `NOTES` | 61 notes of three bytes |
| $C770-$C83E | `TUNE_MENU`, `TUNE_CONTROL_CHOSEN`, `TUNE_GAME_START`, `TUNE_GAME_OVER`, `TUNE_ENDING`, `TUNE_NEW_LIFE` | the six tunes |
| $C962-$C9EE | `MENU_COLOURS` (`MENU_CONTROL_COLOURS` $C963), `MENU_PLACES` $C96A, `MENU_TEXT` $C97A | the menu's eight lines |
| $CAE5 | `FRAME_PIECES` | the frames' corners and edges |
| $CC2E | `LIFE_ICON_CODES` | a life's eight codes |
| $CC36 | `START_RECORDS` | the knight's two records at a new life: `START_U_LOW` $CC37, `START_U_CELL` $CC38, `START_V_LOW` $CC39, `START_V_CELL` $CC3A, `START_FACING` $CC3C, `START_FLAGS` $CC3D |
| $CCE4 | `ENDING_RECORDS` | the ending's ten pictures and places |
| $CDAF | `END_TEXT` | the text after a game |
| $CE79 | `MONSTER_RECORD` | what a monster starts as |
| $D0A0 | `DEPTH_TABLE` | 18 routines for the depth sort's outcomes |
| $D15D | `DRAW_LIST` | 32 bytes: the records in a cell, to be drawn (an `s` entry) |
| $D4EF | `TILE_MASKS` | masks for a shifted tile's first byte |
| $D599 | `UPDATES` | 158 words: graphic to update routine |
| $D8D7 | `OBJECT_RECORD` | what each object starts as |
| $D932 | `VILLAIN_RECORD` | what each villain starts as |
| $DC71 | `COAST_TABLE` | 4 routines by facing: coming to a stop |
| $DCDC | `FACING_LOOKS` | the knight's mirror and back view by facing |
| $DD6A | `TURN_TO_KNIGHT_TABLE` | 4 routines: turning a chaser towards the knight |
| $DE6A | `MOVE_TABLE` | 4 routines by facing: trimming a step at the walls |

**Self-modifying code**: the visited bit's `BIT` and `SET` in
`MARK_VISITED` ($BF66); the column's `BIT` and `SET` at `TEST_COLUMN`
($D3E2) and `CLAIM_COLUMN` ($D3E6); the tile masks' four ANDs
(`TILE_MASK_FIRST` $D47B, `TILE_MASK_LAST` $D489, `TILE_MASK_FIRST_TURNED`
$D4A2, `TILE_MASK_LAST_TURNED` $D4B1); the sprite drawer's `JR` in
`SPRITE_ROW` ($E4C9) and row step at `SPRITE_NEXT_ROW` ($E528). And one
instruction read as data: the `DEC (HL)` at $CBDD (`TAKE_LIFE`) by
`NEW_LIFE`, and the `JR` at `LIVES_BYTE` by `NEW_GAME`.

## Variables

Cleared from $BBAA at the first start, from $BBB4 at every new game.

| Address | Label | What |
|---|---|---|
| $BBAA | `RANDOM` | the random number, stirred after every record's update |
| $BBAC | `FONT_BASE` | the printer's code-0 address |
| $BBAE | `SAVED_SP` | SP while the drawing, the copy and the clear borrow it |
| $BBB0 | `CONTROL` | bits 1-2 the control method, bit 3 directional control |
| $BBB1 | `LAST_CONTROL` | `CONTROL` before the last menu key |
| $BBB2 | `TURNS` | the turn counter, a word, from `FRAMES` at every game |
| $BBB4 | `CELL_LOOKED_UP` | the column and row last looked up |
| $BBB6, $BBB8 | `DRAW_X`, `DRAW_Y` | projected screen x and y, signed words |
| $BBBA | `VIEW` | bit 0: the town turned round |
| $BBBB | `COLUMNS_DRAWN` | a bit per 16-pixel screen column claimed by a wall this turn |
| $BBBD | `KEY_LATCH` | set while a once-a-press key is held |
| $BBBE | `TOP_SPEED` | 10, or 18 with the bonus |
| $BBBF | `MENU_SHOWN` | the menu's frame has been drawn |
| $BBC0 | `CELL_TYPE` | the type of the cell whose walls are drawn |
| $BBC1 | `TUNE_PLAYED` | the menu's tune has played |
| $BBC2, $BBC3 | `SPRITE_WIDTH`, `SPRITE_ROWS` | the last sprite drawn: bytes a row, rows |
| $BBC4, $BBC6 | `DRAW_LIST_AT`, `DRAW_LIST_NEXT` | pointers into `DRAW_LIST` |
| $BBC8 | `FIRE_DELAY` | turns before another throw |
| $BBC9-$BBCB | `SCORE`, `SCORE_LOW` | the score, BCD |
| $BBCC | `SCORE_ZEROS` | printed as the score's last two digits; never written |
| $BBCD | `LIVES` | lives in hand besides the one being played |
| $BBCE | `STOCKS` | 36 bytes: finds left, by cell type |
| $BBF2 | `DRAW_PASS` | which face of a building is drawn: 1 the mirrored |
| $BBF3 | `HITS` | hits left this life |
| $BBF4 | `THROW_TOGGLE` | which antibody record a full pair loses |
| $BBF5 | `SPEED_TIME` | turns left of the faster walk |
| $BBF6 | `LAST_CELL` | the cell last marked visited |
| $BBF8 | `FOOTSTEPS` | the footstep counter |
| $BBF9, $BBFA | `EFFECT_TIME`, `EFFECT` | the sound effect: notes left, which |
| $BBFB | `FLASH` | the play area's paper for the next clear; a dying villain's flash |
| $BBFC | `LAST_FLASH` | the paper this turn was cleared to |
| $BBFD, $BBFE | `PERCENT`, `PERCENT_LOW` | the percentage, BCD |
| $BBFF | `ENDING` | set while the ending plays |
| $BC00 | `ENDING_COLOUR` | the colour an ending picture is drawn in |
| $BC01 | `CONTROLS` | the controls this turn |
| $BC02 | `ARRIVING` | 40 up by two while the knight appears; $70 once he has |
| $BC03-$BC0D | `CARRIED`, `CARRIED_LAST` | the eleven carried things |
| $BC0E | `VISITED` | 128 bytes, a bit per cell |

## The object records

| Address | Label | Records | What |
|---|---|---|---|
| $BC8E | `KNIGHT` | 1 | his legs; fields `KNIGHT_U` $BC8F, `KNIGHT_COLUMN` $BC90, `KNIGHT_V` $BC91, `KNIGHT_ROW` $BC92, `KNIGHT_SPEED` $BC93, `KNIGHT_FACING` $BC94, `KNIGHT_FLAGS` $BC95 |
| $BC9E | `KNIGHT_TOP` | 1 | his top |
| $BCAE | `ANTIBODIES` | 2 | antibodies in flight |
| $BCCE | `FINDS` | 4 | finds, or a dead villain's sparkles |
| $BD0E | `BONUS` | 1 | a bonus |
| $BD1E | `OBJECTS` | 4 | the four objects |
| $BD5E | `VILLAINS` | 4 | the four villains, 64 bytes after their objects |
| $BD9E | `MONSTERS` | 6 | monsters and the creature |

The fields and the graphics each record holds: [`object-records.md`](object-records.md).

## Open

- Nothing unaccounted for: every byte from $5B00 to $FFFF is in a
  described, labelled entry. Two labels stage 1 had were lost in the stage
  2 merge -- `TAKE_LIFE` ($CBDD) and `DRAW_STEP_DONE` ($CF8D) -- and are
  reported to the lead.
