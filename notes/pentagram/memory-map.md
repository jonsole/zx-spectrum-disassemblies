# Memory map

**Question this answers:** where everything is -- the level data, the
sprites, the variables, the object records, the code and its tables, the
buffers -- by address and label, and what each variable means.

**Short answer:** the tape's one block is $5E00-$D89D: a jump to the code,
then the level data and the sprites ($5E07-$A708), the variables and the 54
object records, all zero on the tape ($A709-$AE2E), the update-routine table
($AE2F-$AF86), and the code with its tables ($AF87-$D88E). The screen buffer
starts in the block's last bytes, at $D88F, and runs to $F08E; the drawing
tables the game builds are at $F100-$FFFF. The stack grows down from $5E00.
Every byte from $5E00 to $FFFF is in a described, labelled entry.

Everything here is *read* from the code, and each level-data table's extent
is checked by `scripts/pentagram_data.py` walking it the way the code does,
unless it says *measured* (run in the simulator). Labels are the listing's
(`game_disassembly/pentagram/pentagram.skool`), as of stage 2.

## Regions

| From | To | What | Label |
|---|---|---|---|
| $4000 | $5AFF | the display; the loading screen goes here (`LOAD ""SCREEN$`, whatever its header says) | |
| $5B00 | $5DFF | the printer buffer, the ROM's system variables and the loader's BASIC; the stack grows down from $5E00 into it (how deep has not been measured), and the system variables are used only by the ROM's interrupt while paused (`PAUSE` points IY at them) | |
| $5E00 | $5E06 | DI, LD SP,$5E00, JP `START` | `ENTRY` |
| $5E07 | $5E0F | three room sizes: U half-size, V half-size, floor height -- (64, 64, 128), (32, 64, 128), (64, 32, 128) | `ROOM_SIZES` |
| $5E10 | $696C | the room directory: 139 records, rooms numbered 0-149 with eleven numbers unused ([`room-building.md`](room-building.md)) | `ROOMS`, `ROOM<n>` |
| $696D | $69AC | the scenery template table: 32 words, four pointing back at the table (unused) | `SCENERY_TABLE` |
| $69AD | $6CE4 | 28 scenery templates, 8-byte pieces up to a zero; the one at $6ABD has no zero and runs on into the next | `SCENERY<n>` |
| $6CE5 | $6D22 | the object template table: 31 words | `OBJECT_TABLE` |
| $6D23 | $6DD6 | 30 object templates, 5 bytes and a zero each | `OBJECT<n>` |
| $6DD7 | $6F2E | the graphic table: 172 words, graphic number to sprite | `GRAPHICS` |
| $6F2F | $A708 | 90 sprite records end to end, with the font (43 characters, $8355-$84AC) among them; see below | `SPRITE<n>`, `FONT`, `SPARE_SPRITEA`-`C` |
| $A709 | $A76E | the game's variables (below) | `CONTROL` ... |
| $A76F | $AE2E | 54 object records of 32 bytes ([`object-records.md`](object-records.md)) | `OBJECTS` ... |
| $AE2F | $AF86 | 172 words: each graphic's update routine ([`graphic-numbers.md`](graphic-numbers.md)) | `UPDATES` |
| $AF87 | $D88E | the code, with its tables (below) | `START` ... |
| $D88F | $F08E | the screen buffer: 192 rows of 32 bytes, bottom row first; its first 15 bytes are the tape block's last | `BUFFER` |
| $F08F | $F0FF | between the buffer and the tables; nothing uses it | `SPARE` |
| $F100 | $F1FF | every byte bit-reversed, built by `MAKE_TABLES` ($B29A) | `REVERSED` |
| $F200 | $FFFF | seven pairs of pages, the complemented shift tables: page $F0 + 2s holds each byte shifted right s, the page above the bits shifted out. `SHIFTEDn` counts the build's left shifts: `SHIFTED7` $F200 is a right shift of 1, ..., `SHIFTED1` $FE00 of 7 ([`drawing.md`](drawing.md)) | `SHIFTED7` ... `SHIFTED1` |

## The sprites

Each sprite is a width byte (bits 0-3; bit 7 set while its rows are stored
reversed, bit 6 while mirrored), a height byte, then a mask byte and an image
byte per cell, bottom row first. The drawing does (screen AND NOT mask) OR
image. 87 addresses are reached from the graphic table; many graphic numbers
share one, and $9395, whose width and height are zero, is what 28 graphic
numbers draw: nothing. Not reached from the graphic table, nor by any address
in the code: $853F-$8546 (eight bytes, no sprite), and the sprites at $8547
(32 by 24) and $8A17 (16 by 16). The game turns sprites in place, so a
snapshot taken after play has some of them turned; the build's is taken
before the first instruction, when all are as on the tape.

## The variables

| Address | Label | What | Evidence |
|---|---|---|---|
| $A709 | `CONTROL` | bits 1-2 the control method (0 keyboard, 1 Kempston, 2 cursor, 3 Interface II); bit 3 directional joystick, set by no menu choice; kept from game to game | `MENU`, `READ_CONTROLS`, `FLASH_MENU`, `CHK_PICKUP_DROP`, `HANDLE_LEFT_RIGHT` |
| $A70A | `MENU_PASSES` | counted up each pass of the menu's loop; never read | $BBCE only |
| $A70B | -- | nothing refers to it | searched |
| $A70C | `CONTROL_BEFORE` | `CONTROL` before this pass's keys; compared, the result thrown away | `MENU` |
| $A70D | `RANDOM` | the random byte: R added at every new game and after every object's update; read for the start room, the drops, the collectables' places, the spider's turns; read as a word with $A70E by `PUFF_SOUND` | `OBJECT_DONE`, `CHOOSE_START`, `SKY_DROP`, `NEW_QUEST`, `SPIDER` |
| $A70E | `BUCKET_OUT` | 1 while the well's bucket exists; the first byte a new game clears | `WELL`, `BUCKET` |
| $A70F | `PENTAGRAM_ON` | all four quest items done: the pieces come into room 82, the collectables glide | `ALL_FOUR_DONE`, `QUEST_INTO_ROOM`, `COLLECTABLE` |
| $A710 | `WIPE_COUNT` | areas `RENDER_DYNAMIC_OBJECTS` has wiped this turn and left on the stack | $B19E |
| $A711 | `NEW_ROOM` | a room has just been built: nothing wiped; the whole screen redrawn | `ENTER_ROOM`, `RENDER_DYNAMIC_OBJECTS`, `OBJECT_DONE` |
| $A712 | `LIST_POINTER` | a place in `DRAW_LIST` | $B19E |
| $A714 | `DRAW_WORK` | the turn's drawing work: objects drawn plus areas wiped; the main loop waits six units less it | `SORT_AND_DRAW`, `DRAW_CANDIDATE`, `OBJECT_DONE` |
| $A715 | `TURNS` | the turn counter, a word; bit 0 times the conveyors and the spider's flip | `OBJECT_DONE`, `CONVEYOR_PUSH`, `SPIDER` |
| $A717 | `SAVED_SP` | SP while `DRAW_SPRITE` reads a sprite with POP | $B3D3 |
| $A719 | `SORT_FIRST` | just past the candidate's entry in `DRAW_LIST` | `SORT_AND_DRAW` |
| $A71B | `SORT_SECOND` | just past the compared object's entry | `SORT_AND_DRAW` |
| $A71D-$A71F | `ROOM_EXTENT` | the room's U half-size, V half-size (64 or 32, about the middle at 128) and floor height (128), from `ROOM_SIZES` | `BUILD_ROOM`; the walls, the floor, `CHK_PLYR_OOB`, the exits, `FIRE` |
| $A720 | `PANEL_DUE` | the panel's carried things need redrawing | `TAKE_OR_LEAVE`, `SHOW_CARRIED` |
| $A721 | `LIVES` | lives in hand, BCD (never above 9, so DEC and INC agree) | `START`, `RESTART_PLAYER`, `QUEST_ITEM`, `DRAW_LIVES` |
| $A722 | `CARRIED` | the staging slot for a thing just picked up, empty between presses (4 bytes: graphic, flags, quest-record link) | `TAKE_OR_LEAVE` |
| $A726, $A72A | `CARRIED_SHOWN` | the two newest carried; the panel's first two boxes | `SHOW_CARRIED` |
| $A72E | `CARRIED_LAST` | the oldest, put down next; the third box | `TAKE_OR_LEAVE` |
| $A732 | `FONT_BASE` | the print base: 384 below `FONT` for text, `FONT` for digits | `PRINT_CHAR` and its callers |
| $A734 | `FRAME_DRAWN` | 0 until the text screen's border is drawn and the buffer shown | `DISPLAY_TEXT_LIST`, `MENU`, `WON` |
| $A735 | `MENU_SPARE` | unused: only an `LD HL` overwritten at once | `MENU` |
| $A736 | `PRINT_ATTR` | a string's colour | `PRINT_TEXT_SINGLE_COLOUR`, `DISPLAY_TEXT_LIST`, `PRINT_SCORE` |
| $A737 | `INPUT` | this turn's controls: bit 0 turn left, 1 right, 2 walk, 3 jump, 4 pick up or put down, 6 fire | `READ_CONTROLS` |
| $A738 | `ROOM_ATTR` | the room's ink with BRIGHT | `BUILD_ROOM`, `OBJECT_DONE` |
| $A739 | `Z_STEP` | the player's intended Z step this turn, kept past the collision cut | `MOVE_PLAYER` |
| $A73A | `TEMPLATES_AT` | the object template table the builder reads (template 31 moves it on 64) | `BUILD_ROOM` |
| $A73C | `PLACE_NUDGE` | the builder's position nudge; always 0 (its setter is unreachable) | `BUILD_ROOM` |
| $A73D | `DROP_TIMER` | turns until something may fall; 80 or 8 (*measured*) | `RESET_DROP_TIMER`, `SKY_DROP` |
| $A73E | `MAIN_SP` | SP saved every turn; never read | `OBJECT_DONE` only |
| $A740 | `TAKE_HELD` | the pick-up latch | `TAKE_OR_LEAVE` |
| $A741 | `NO_HEADROOM` | nothing may be put down: no room above him | `TAKE_OR_LEAVE` |
| $A742 | `DROP_BAN` | nothing falls in this room | `BAN_DROPS`, `SKY_DROP` |
| $A743 | `FIRE_HELD` | the fire latch | `FIRE` |
| $A744-$A746 | `SCORE` | six BCD digits, the highest first | `ADD_SCORE` |
| $A747 | `TUNE_HEARD` | the menu's tune has played this game | `PLAY_TUNE_ONCE` |
| $A748 | `STEP_SOUND` | counts his steps; every fourth clicks | `FOOTSTEP` |
| $A749, $A74A | `SOUND_COUNT` | an effect's notes left, then which effect (0 room, 1 pick-up) | `EFFECT_NOTE`, `OBJECT_DONE`, `TAKE_OR_LEAVE`, `PAUSE_BEEP` |
| $A74B | `PLACED` | collectables in their places; 6 per cent each; the fifth wins | `COLLECTABLE`, `PERCENTAGE` |
| $A74C | `QUEST_DONE` | quest items done; 4 per cent each | `QUEST_ITEM`, `PERCENTAGE` |
| $A74D, $A74E | `PERCENT` | the percentage, BCD: hundreds, then tens and units | `PERCENTAGE` |
| $A74F-$A76D | `ROOMS_SEEN` | a bit per room, bit 7 of the first byte for room 0; 31 bytes counted, 19 usable | `MARK_ROOM_SEEN`, `PERCENTAGE` |
| $A76E | -- | nothing refers to it | searched |

`START` clears $A709-$AE2E once; after every game `AFTER_GAME` clears from
$A70E, so the first five bytes carry over.

## The object records

54 records of 32 bytes from `OBJECTS` ($A76F); the fields and flags are in
[`object-records.md`](object-records.md).

| Address | Label | Record |
|---|---|---|
| $A76F | `OBJECTS` | 0, the player's legs; `PLAYER_U` $A770, `PLAYER_V` $A771, `PLAYER_FLAGS` $A776, `PLAYER_ROOM` $A777 (*measured*), `PLAYER_BUMPED` $A77B (+$0C), `PLAYER_STATE` $A77C (+$0D: bit 6 killed) |
| $A78F | `PLAYER_BODY` | 1, his body |
| $A7AF, $A7CF | `BOLTS`, `BOLT_SECOND` | 2, 3 |
| $A7EF, $A80F | `FLYERS`, `FLYER_SECOND` | 4, 5, things from the sky |
| $A82F | `ROOM_OBJECTS` | 6-53, the room's; `ROOM_SECOND` $ADEF and `ROOM_FIRST` $AE0F are the builder's first two |

## The code's tables and work areas

| Address | Label | What |
|---|---|---|
| $B47C, $B4D0 | (operands) | the JR offset in `SPRITE_ROW` and the row step in `SPRITE_NEXT_ROW`, patched for every sprite |
| $B55A | `DRAW_LIST` | 48 bytes: the records to draw this turn, bit 7 when drawn, $FF |
| $B638 | `DEPTH_ORDER` | 27 words, the outcomes of a box comparison |
| $B6CD | `CANDIDATE_CHAIN` | 16 bytes: the sort's candidates since the last draw |
| $BAC2 | `CARRIED_COLOURS` | 8 attributes by graphic's low bits |
| $BACA | `PANEL_RECORD` | a spare 32-byte object record for drawing on the panel |
| $BB24 | `SCORE_TEXT` (`SCORE_TEXT_END` $BB28) | the score's heading |
| $BBF1-$BC65 | `MENU_COLOURS`, `MENU_XY` $BBF8, `MENU_TEXT` $BC06 and the pieces between | the menu's colours, positions and strings |
| $BC7A | `PRINT_TEXT_STD_FONT` | unreached code, left as data |
| $BD31 | `PANEL_DATA` | the panel's scroll-work, ten 4-byte entries |
| $BD98 | `BORDER_DATA` | the border, ten 4-byte entries |
| $C1BD | `BOLT_STEPS` | a bolt's step by facing |
| $C28B | `DEADLY_AND_DRAW` | unreached code, left as data |
| $C2E8 | `START_ROOMS` | 51, 92, 100, 12 |
| $C35D-$C38A | `OVER_COLOURS`, `OVER_XY` $C360 ... | the game-over screen's tables |
| $C38B-$C3EE | `WON_CONGRATULATIONS` ... `WON_XY` $C3DD, `WON_COLOURS` $C3E9 | the winning screen's tables |
| $C3EF | `PLAYER_START` | 16 bytes: the legs as a game starts |
| $C3FF | `PLAYER_TEMPLATE` (`START_ROOM` $C407) | 64 bytes: the player as he came into this room |
| $C4A2 | `STRAY_RET_LEGS` | a RET nothing reaches |
| $C68D | `WALK_STEP_TBL` | four step routines by facing |
| $C83B | `SCREEN_MOVE_TBL` | four exit routines by facing |
| $C8F7, $C8FF | `ROUTINES_BIT3_SET`, `ROUTINES_BIT3_CLEAR` | the arch nudge's two tables of four |
| $CA7C, $CA7F | `SET_PLACE_NUDGE`, `SET_PLACE_NUDGE_END` | unreached code, left as data |
| $CC09 | `DROP_GRAPHICS` | what may fall: eight graphics |
| $CC11 | `FLYER_TEMPLATE` | 32 bytes: a thing from the sky as it starts |
| $D1A5 | `SPOTS` | twenty places a collectable can start: room, U, V, Z |
| $D30A | `CONVEYOR_STEPS` | four pairs of U, V |
| $D312 | `QUEST_START` (`QUEST_START_BUCKET` $D422) | the 18 quest records as a game starts |
| $D432 | `QUEST_RECORDS` (`QUEST_COLLECTABLES` $D472, `QUEST_BUCKET` $D542) | the quest records now; 304 bytes, 18 used ([`quest-records.md`](quest-records.md)) |
| $D562 | `TARGETS` | five pairs of U, V: the collectables' places in room 82 |
| $D587-$D5D6 | `BLIP_PITCHES` ... `MORE_PITCHES_D` | unused pitch tables |
| $D60D | `EFFECTS` (`EFFECT_PITCHES` $D615, `_B` $D618, `_C` $D61B) | the sound effects' addresses and notes |
| $D665 | `BEEP_BY_GRAPHIC` | unreached code, left as data; $D673 its spare byte |
| $D718 | `NOTES` | 61 notes of three bytes, Knight Lore's table |
| $D7CF-$D88E | `TUNE_MENU`, `TUNE_UNUSED` $D824, `TUNE_START` $D833, `TUNE_QUEST` $D847, `TUNE_OVER` $D853, `TUNE_WON` $D86F | the tunes |

## What is still open

Nothing is unaccounted for: every byte is in an entry, every entry has a
title, a description and a label. What is unused is listed in
[`leftovers.md`](leftovers.md).

## Disassembly corrections

Stage 1's version of this map, corrected by stage 2:

- `SLOWDOWN` ($A714) is `DRAW_WORK`: work done, and the wait is six less it.
- `ROOM_EXTENT` was "the room's U, V, Z extents": the first two are
  half-sizes about the room's middle, the third the floor's height.
- "Not yet understood: $A70B, $A710, $A719, $A71B, $A734, $A735, $A76E":
  $A710 is `WIPE_COUNT`, $A719 and $A71B the sort's places, $A734
  `FRAME_DRAWN`, $A735 `MENU_SPARE` (unused); $A70B and $A76E are used by
  nothing.
- `CARRIED` was "four slots of four bytes": three carried slots and a staging
  slot in front of them.
- The tables among the code that stage 1 left to sna2ctl ($B638, $C68D,
  $C83B, $D60D, $BD31, $BD98, $B6CD and the text blocks) are all described
  and labelled; $D56C is code (`BLIP_BY_TURN`), and $CA7C is left as data
  with a description.
