# Memory map

**Question this answers:** where everything is -- the variables, the object
records, the level data, the code and its tables, the buffers -- by address
and label, what each variable means, and which bytes the tape carries that
are not the game's.

**Short answer:** the game's variables ($5B00-$5B87) and 56 object records
($5B88-$6287) sit below the block, over the printer buffer, the system
variables and the loader. The block loads from $62FD to $FFFF: the entry at
$6300, the font, the level data and the sprites ($6308-$A630), then the
code with its tables ($A631-$D1EA), Knight Lore's old copyright line, and
space the game writes before it reads: the screen buffer ($D200-$E9FF), the
stack (down from $F100) and the drawing tables ($F100-$FFFF) -- which on the
tape hold leftovers from the machine it was saved on. Every byte from $5B00
to $FFFF is in a described, labelled entry.

Everything here is *read* from the code, and each level-data table's extent
is checked by `scripts/alien8_data.py` walking it the way the code does,
unless it says *measured* or *searched*. Labels are the listing's
(`game_disassembly/alien8/alien8.skool`), as of the end of stage 2.

## Regions

| From | To | Label | What |
|---|---|---|---|
| $4000 | $5AFF | | the display; the loading screen goes here |
| $5B00 | $5B87 | `SEED` ... | the game's variables (below), over the printer buffer and the system variables |
| $5B88 | $6287 | `OBJECTS` ... | 56 object records of 32 bytes ([`object-records.md`](object-records.md)) |
| $6288 | $62FC | `BELOW_BLOCK` | unused: the loader's stack under RAMTOP (nothing refers to it, *searched*); the builder's clearing stops here |
| $62FD | $62FF | `BLOCK_START` | the block's first three bytes, before the entry; unused |
| $6300 | $6307 | `ENTRY` | DI, LD SP,$F100, NOP, JP `START` |
| $6308 | $645F | `FONT` | 43 characters, codes $30-$5A |
| $6460 | $6468 | `ROOM_SIZES` | three sizes: U half-size, V half-size, floor -- (64, 64, 64), (32, 64, 64), (64, 32, 64) |
| $6469 | $73C7 | `ROOM02` ... `ROOMF8` | the room directory: 128 records, labelled by room number ([`room-building.md`](room-building.md)) |
| $73C8 | $7417 | `OBJECT_TABLE` | 40 words, two pages of object templates |
| $7418 | $7518 | `OBJECT1` ... `OBJECT39` | 37 object templates, five-byte pieces to a zero |
| $7519 | $7534 | `BACKGROUND_TABLE` | 14 words |
| $7535 | $76E2 | `BACKGROUND0` ... `BACKGROUND13` | 14 backgrounds, eight-byte pieces to a zero |
| $76E3 | $7826 | `PLACES` | 36 places of 9 bytes ([`valves-and-sockets.md`](valves-and-sockets.md)) |
| $7827 | $792E | `GRAPHICS` | 132 words: graphic number to sprite |
| $792F | $A630 | `SPRITE0` ... | 78 sprites end to end; `SPARE_SPRITEA` ($88B3) reached by no graphic |
| $A631 | $D1EA | `START` ... | the code, with its tables (below) |
| $D1EB | $D1FF | `OLD_COPYRIGHT` | unused: Knight Lore's copyright line naming 1984 ([`leftovers.md`](leftovers.md)) |
| $D200 | $E9FF | `BUFFER` | the screen buffer, 32 bytes a line, bottom line first; leftovers on the tape |
| $EA00 | $F0FF | `STACK_SPACE` | the stack, down from $F100; SP is reset to $F100 before every object's update |
| $F100 | $FFFF | `MIRROR_TABLE` | built by `BUILD_LOOKUP_TBLS` ($CFA7): the byte bit-reversed at $F100, then for a shift s = 1-7 page $F0 + 2s the byte shifted right s and page $F1 + 2s the bits shifted out, both complemented; leftovers on the tape |

## The variables

Knight Lore's layout 160 bytes lower up to `NO_HEADROOM` ($5B33), where the
job is the same; Alien 8's own from `ROOM_COLOUR_AT` on.

| Address | Label | What | Evidence |
|---|---|---|---|
| $5B00 | `SEED` | the ROM's frame counter at first run; + `TURNS`' low byte at every new game; + 1 each pass of the menu. Bits 0-1 pick the start room; with R, the first kind of valve dealt | `START`, `MAIN_NEW_GAME`, `MENU`, `NEW_GAME_START`, `INIT_SPECIAL_OBJECTS` |
| $5B01 | -- | nothing refers to it (spare in Knight Lore too) | *searched* |
| $5B02, $5B03 | `TURNS`, `TURNS_HIGH` | the turn counter, a word, never cleared after the first game; times the scene's sparks, the mice, the shuttles, the appearing, the footstep's pitch and the sounds | `MAIN_END_OF_TURN`; `CLOCKWORK_MOUSE`, `SCENE_SPARKS`, `SHUTTLE_BLOCK`, `PLAYER_APPEARING` |
| $5B04 | `CONTROL` | bits 1-2 the control method (0 keyboard, 1 Kempston, 2 cursor, 3 Interface II); bit 3 directional control (key 5); kept from game to game | `MENU`, `FLASH_MENU`, `READ_CONTROLS`, `CHK_PICKUP_DROP`, `HANDLE_LEFT_RIGHT` |
| $5B05 | `RANDOM` | the random number: R added after every object; the turn counter and the byte it points at at the end of every turn. Read by the drops, the leapers, the mice, the wanderer, the scene's tools, the dealing | `OBJECT_DONE`, `MAIN_END_OF_TURN` |
| $5B06 | `CONTROL_BEFORE` | `CONTROL` before this pass's keys, for the menu's beep | `MENU` |
| $5B07 | -- | nothing refers to it | *searched* |
| $5B08 | `WIPE_COUNT` | areas the turn's drawing wiped and left on the stack; added to `DRAW_WORK`. The first byte cleared after a game | `RENDER_DYNAMIC_OBJECTS`, `AFTER_GAME` |
| $5B09 | `SAVED_SP` | SP while a sprite is read with POP | `PRINT_SPRITE`, `SPRITE_SHIFTED_RUN` |
| $5B0B, $5B0C | `ROOM_HALF_U`, `ROOM_HALF_V` | the room's half-sizes: the walls, the exits, the arrival | `BUILD_ROOM`; `ADJ_DU_FOR_OUT_OF_BOUNDS`, `CHK_PLYR_OOB`, `HANDLE_EXIT_SCREEN`, `ADJUST_PLYR_UVZ_FOR_ROOM_SIZE` |
| $5B0D | `ROOM_INK` | the room's ink; 7 once its chamber is activated | `BUILD_ROOM`, `COLOUR_PANEL`, `LOOSE_VALVE` |
| $5B0E | `FLOOR` | the floor's height, 64 | `BUILD_ROOM`, `ADJ_DZ_FOR_OUT_OF_BOUNDS` |
| $5B0F-$5B11 | -- | nothing refers to them: Knight Lore's portcullis and transformation bytes | *searched* |
| $5B12 | `PLAYED` | bit 0 set at the end of every turn, cleared at a new game; while set, entering a room writes the old room's valves back first | `MAIN_END_OF_TURN`, `MAIN_NEW_GAME`, `ENTER_ROOM` |
| $5B13 | `TAKE_HELD` | the pick-up latch | `TAKE_OR_LEAVE` |
| $5B14 | `PANEL_DUE` | set on every pick-up press that passes the first checks; `SHOW_CARRIED` redraws and clears it | `TAKE_OR_LEAVE`, `SHOW_CARRIED` |
| $5B15 | `INPUT` | this turn's controls: bits 0, 1 turn, 2 walk, 3 jump, 4 pick up or put down, 5 a letter key (the pick-up under directional control) | `READ_CONTROLS` |
| $5B16 | `PRINT_ATTR` | a text list's line colour | `DISPLAY_TEXT_LIST`, `PRINT_TEXT_SINGLE_COLOUR` |
| $5B17 | `NEW_ROOM` | a room just built, or the scene after a game set up: nothing wiped, the whole screen redrawn | `ENTER_ROOM`, `GAME_ENDED`, `RENDER_DYNAMIC_OBJECTS`, `MAIN_END_OF_TURN` |
| $5B18 | `TEXT_SHOWN` | 0 until a text list has been printed and the screen copied once; the menu and the arrival screen clear it | `DISPLAY_TEXT_LIST`, `MENU`, `ARRIVAL_SCREEN` |
| $5B19 | `PLACE_NUDGE` | the builder's position nudge, from a template-0 header: bit 0 +8 in U, bit 1 +8 in V, the rest added to Z; $30 in 41 headers | `BUILD_ROOM` |
| $5B1A | `LIVES` | lives, binary, printed as BCD; 5 at a new game, one taken as each life starts | `MAIN_NEW_GAME`, `NEW_LIFE`, `EXTRA_LIFE`, `PRINT_LIVES` |
| $5B1B-$5B1D | `SAVED_UVZ` | a pushable block's position before its move | `SAVE_UVZ`, `SAME_UVZ` |
| $5B1E | `DRAW_WORK` | the turn's drawing work: objects drawn plus areas wiped; the loop waits six units less | `SORT_AND_DRAW`, `DRAW_CANDIDATE`, `RENDER_DYNAMIC_OBJECTS`, `MAIN_END_OF_TURN` |
| $5B1F | -- | nothing refers to it: Knight Lore's "a spiked ball is falling" | *searched* |
| $5B20 | `TEMPLATES_AT` | the object template page the builder reads, a word; template 31 moves it on 64 | `BUILD_ROOM` |
| $5B21 | `PLAYER_DZ` | the robot's Z step this turn -- and `TEMPLATES_AT`'s high byte while a room is built | `MOVE_PLAYER` |
| $5B22 | -- | nothing refers to it: Knight Lore's bouncing ball's step | *searched* |
| $5B23 | `WON` | the twenty-fourth chamber: the arrival screen, the better ratings, the oiling scene; no controls, no panel redraw | `LOOSE_VALVE`, `GAME_ENDED`, `READ_CONTROLS`, `SHOW_CARRIED` |
| $5B24 | `GAME_OVER` | 1 while the scene after a game runs: no projection, no wait, no clock, no controls | `GAME_ENDED`, `CALC_PIXEL_XY`, `MAIN_END_OF_TURN`, `READ_CONTROLS` |
| $5B25 | `LIFT_TOP` | the room's lifts' shared top: 0 when a room is built, set by the first lift (its Z + 48) or bobbing block (its Z) to run; *measured* 112 in room $23, 100 in $1D and $36 | `BUILD_ROOM`, `LIFT` |
| $5B26 | -- | nothing refers to it: Knight Lore's rooms visited | *searched* |
| $5B27 | `FONT_BASE` | the printer's base, a word: `FONT` less 384 for text, `FONT` for numbers | `PRINT_TEXT_SINGLE_COLOUR`, `PRINT_BCD_NUMBER`, `RUN_CLOCK` |
| $5B29, $5B2A | -- | nothing refers to them: Knight Lore's percentage | *searched* |
| $5B2B | `SEQUENCE_AT` | where the wipe loop is in `DRAW_LIST`, a word | `RENDER_DYNAMIC_OBJECTS` |
| $5B2D, $5B2F | `SORT_FIRST`, `SORT_SECOND` | just past the candidate's and the compared object's entries in `DRAW_LIST` | `SORT_AND_DRAW`, `IY_GOES_FIRST`, `DRAW_CANDIDATE` |
| $5B31 | `TUNE_HEARD` | bit 0: the menu's tune has played at this menu | `PLAY_TUNE_ONCE` |
| $5B32 | `KEY5_HELD` | the menu's key-5 latch | `MENU` |
| $5B33 | `NO_HEADROOM` | nothing may be put down: no room above him | `TAKE_OR_LEAVE` |
| $5B34 | `ROOM_COLOUR_AT` | the address of the room record's colour byte, a word; an activated chamber's white goes there | `BUILD_ROOM`, `LOOSE_VALVE` |
| $5B36-$5B39 | `CLOCK` (2 bytes), `CLOCK_LOW`, `CLOCK_LAST` | the light years, four digits with roll counts; 6000 at a new game ([`clock.md`](clock.md)) | `MAIN_NEW_GAME`, `RUN_CLOCK`, `CLOCK_BORROW`, `ROLL_CLOCK` |
| $5B3A | `DROPPING` | a ceiling drop is falling; cleared on entering a room | `CEILING_DROP`, `ENTER_ROOM` |
| $5B3B | `DROP_LATCH` | nothing drops: set on entering an even room, cleared by a pick-up or an extra life | `ENTER_ROOM`, `CEILING_DROP`, `PICK_UP_VALVE`, `EXTRA_LIFE` |
| $5B3C, $5B3D | `SUMMARY_LOST`, `SUMMARY_LOST_LOW` | the crew lost, a BCD word, high byte first; 132 with none activated (*measured*) | `SUMMARISE_CHAMBERS`, `PRINT_SUMMARY_COUNTS` |
| $5B3E, $5B3F | `SUMMARY_ACTIVE`, `SUMMARY_IDLE` | chambers activated and not, BCD | the same |
| $5B40 | `CHAMBERS` | chambers activated this game, BCD; the twenty-fourth wins | `LOOSE_VALVE`, `PRINT_CHAMBERS` |
| $5B41 | `SCENE_STATE` | the re-programming: 0 while the sparks flash, then 1; bit 7 a tool swinging, bits 0-6 the swings, 16 ends it | `SCENE_SPARKS`, `SCENE_TOOL` |
| $5B42 | `REMOTE_ORDERS` | bit 7 a robot has control; bits 0-6 the order (1 the pad, 2-5 a button); cleared on entering a room (*measured*) | `REMOTE_ROBOT`, `REMOTE_PAD`, `REMOTE_BUTTON`, `ENTER_ROOM` |
| $5B43 | `LEAPING` | a leaper is in the air; cleared on entering a room (*measured* in room $97) | `LEAPER`, `ENTER_ROOM` |
| $5B44-$5B57 | -- | nothing refers to them | *searched* |
| $5B58-$5B77 | `ROOMS_SEEN` | a bit per room number, byte room/8, bit room AND 7 | `MARK_ROOM_SEEN`, `COUNT_ROOMS_SEEN` |
| $5B78 | `CARRIED_NEW` | the slot a thing picked up goes to, empty between presses | `TAKE_OR_LEAVE` |
| $5B7C, $5B80 | `CARRIED` | the newest two carried (graphic, flags, place address) | `TAKE_OR_LEAVE`, `SHOW_CARRIED` |
| $5B84 | `CARRIED_LAST` | the oldest, put down next | the same |

`START` clears $5B00 up to the end of the object records once; `AFTER_GAME`
clears from $5B08 after every game, so the first eight bytes carry over.
The only indirect accesses to the variables are those clears and the
carried list's LDDR ($5B83 to $5B87), so the bytes marked "nothing refers to
it" are unused (*searched* as little-endian words in the block too; the one
hit, in the scene data at $B847, is a coincidence).

## The object records

| Record | Address | Label | Holds |
|---|---|---|---|
| 0 | $5B88 | `OBJECTS` | the robot's legs; `PLAYER_U` $5B89, `PLAYER_FLAGS` $5B8F, `PLAYER_ROOM` $5B90 |
| 1 | $5BA8 | `PLAYER_TOP` | his top |
| 2, 3 | $5BC8, $5BE8 | `VALVES`, `VALVE_SECOND` | what lies in the room from the places |
| 4-55 | $5C08-$6268 | `ROOM_OBJECTS` | the room; `FRAMES` ($5C78, inside record 7) is the ROM's frame counter, read once before the area is cleared |

Every field and flag: [`object-records.md`](object-records.md).

## The code's tables and work areas

| Address | Label | What |
|---|---|---|
| $A797 | `LIGHT_YEARS_TEXT` (`_END` $A7A2) | the panel's label, its first byte the colour written at run time |
| $A7CA | `CLOCK_BOX_COLOURS` | three rows of six attributes |
| $A7EA | `UPDATES` | 131 words: each graphic's update routine ([`graphic-numbers.md`](graphic-numbers.md)) |
| $A8F8 | `JP_HL_LEFTOVER` | a stray JP (HL) byte |
| $AA43 | `REMOTE_STEPS` | five pairs of U, V steps |
| $B108 | `FACING_STEPS` | a creature's step by its direction bits |
| $B3C5-$B4A0 | `TUNE_START`, `TUNE_WON` $B3D7, `TUNE_GAME_OVER` $B3F7 (and its pieces to `_END` $B436), `TUNE_ARRIVAL` $B437, `TUNE_MENU` $B451 | the tunes |
| $B51D | `NOTES` | 61 notes of three bytes, then unused code ($B5D4-$B5ED) |
| $B6A9 | `WARBLE_COUNTS` | the warble's counts |
| $B7F5 | `REPROGRAMMING` (`_TEXT`, `_END`) | the lost scene's flashing text |
| $B82A-$B862 | `SCENE_LOST` ... `SCENE_WON` $B853 ... `SCENE_WON_END` | the scenes' lists |
| $B8D0-$B94E | `ARRIVAL_COLOURS`, `ARRIVAL_XY` $B8D7, `ARRIVAL_TEXT` $B8E5 and their pieces | the arrival screen |
| $B94F-$B9DC | `SUMMARY_COLOURS`, `SUMMARY_XY` $B956, `SUMMARY_TEXT` $B964 and their pieces | the summary screen |
| $B9DD | `RATINGS` | eight words: the ratings, `RATING_POOR` $B9ED ... `RATING_ADVENTURER_LAST` $BA35 |
| $BB14-$BB9C | `MENU_COLOURS`, `MENU_XY` $BB1C, `MENU_TEXT` $BB2C and their pieces | the menu |
| $BD34 | `CARRIED_COLOURS` | the carried valves' colours by kind |
| $BD38 | `PANEL_RECORD` | a spare 32-byte object record for the panel, the border and the carried things |
| $BF96 | (in `FILL_BOX_ROW` $BF95) | `FILL_BOX`'s JR displacement, rewritten |
| $C048 | `NUDGE_ROUTINES` | the doorway nudge's routines by facing |
| $C1D2, $C1DA | `TURN_RIGHT_VIEWS`, `TURN_LEFT_VIEWS` | the in-between view of a turn, by facing |
| $C22D, $C235 | `TURN_RIGHT_ENDS`, `TURN_LEFT_ENDS` | the facing a turn ends in |
| $C32F | `WALK_STEP_TBL` | four step routines by facing |
| $C38F | `SCREEN_MOVE_TBL` | four exit routines by facing |
| $C745 | `DRAW_LIST` | 64 bytes: the records to draw this turn, bit 7 when drawn, $FF |
| $C833 | `DEPTH_ORDER` | 27 words, the outcomes of a box comparison |
| $C8EF | `CANDIDATE_CHAIN` | 16 bytes: the sort's candidates since the last draw |
| $CA1D, $CA3D | `START_LEGS` (`START_LEGS_ROOM` $CA25, `START_LEGS_NEXT` $CA2D), `START_TOP` (`START_TOP_ROOM` $CA45, `START_TOP_NEXT` $CA4D) | the robot as a life starts; rewritten at every doorway |
| $CA5D | `START_TEMPLATE` | 16 bytes: the robot as a game starts |
| $CA9E | `START_ROOMS` | $13, $4E, $88, $D7 |
| $CB5A | `PANEL_DATA` | the panel's twelve pieces |
| $CBC3 | `BORDER_DATA` | the border's pieces, then Knight Lore's unreached `colour_panel` ($CBE3; `COLOUR_PANEL_RED` $CBF6, `COLOUR_PANEL_TAIL` $CBF9) |
| $D0BB, $D110 | `SPRITE_ROW_JUMP`, (operand) | the JR and the ADD patched for every sprite |

## What is still open

Nothing is unaccounted for: every byte is in an entry, every entry has a
title, a description and a label (622 entries). What is unused is listed in
[`leftovers.md`](leftovers.md).

## Disassembly corrections

Stage 1's version of this map, corrected by stage 2:

- `UNKNOWN_5B25` is `LIFT_TOP` and `UNKNOWN_5B43` is `LEAPING` (ranges 1 and
  2, *measured*).
- "Not referred to by name: $5B01, $5B07, $5B0F-$5B11, $5B1F, $5B22, $5B26,
  $5B29-$5B2A, $5B44-$5B57 -- stage 2 to rule out": ruled out, and the
  Knight Lore bytes identified (range 1).
- "What draws graphic 131": `DISPLAY_PANEL`, the panel's chambers icon
  (range 5).
- $D348-$D8FF is one piece of the Interface 1 ROM, not code, messages and
  more code (range 5).
- `LIVES` is binary, not BCD; `TUNE_HEARD` is cleared after every game;
  `PANEL_DUE` is set on every accepted press; `SEQUENCE_AT` points into the
  draw list (range 1).
- `$C745` and `$BD38`, left by sna2ctl as unused space, are `DRAW_LIST` and
  `PANEL_RECORD`; `$A7CA` is attributes, not text; `$B862` ends the won
  scene's list.
