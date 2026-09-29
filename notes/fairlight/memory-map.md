# Memory map

**Question this answers:** where everything is -- on the tape (the snapshot
at $C47C) and once the game runs -- by address and label, what is code, what
is data, what is leftover, and what is still unaccounted for.

**Short answer:** the tape loads $4000-$DABF (the screen included) and
$DD39-$FFFF; the loader's own bytes lie between. The code is 7 KB,
$E3E4-$FF69, with a few routines below it (the tune and the start-up at
$C000, the title page's and the messages' strings, `MESS2`, `SHOW_MESSAGE`).
Most of the rest is 89 sprites, 81 rooms and 56 parts, the object table,
the templates, the font and 26 textures. The start-up moves the object
table and the templates over leftover source text and makes a master copy;
once the game runs, $C000-$DBFF is the clean copy of the screen and the four
compositing pages, over the tune and the tables' tape copies. About 9 KB of
the image is leftover from the development machine.

Labels are the final listing's (`game_disassembly/fairlight/fairlight.skool`,
2026-09-29). Every entry is titled, described and labelled.

## By address

| Address | Label | What | Game or leftover |
|---|---|---|---|
| $4000-$5AFF | | The loading screen (not disassembled) | Screen; the loader's countdown digits over it |
| $5B00-$617B | `SPRITE5B00` ... `SPRITE6154` | 17 sprites, image then mask (they lie over the ROM's system variables, which is why interrupts are off: [`start-up.md`](start-up.md)) | Game |
| $5D14-$5E33 | `TYPE48_FRAMES` | Frames 1 and 2 of type 48's strike | Game (never shown in the sessions) |
| $617C-$639B | `SOURCE_AND_STACK`, `STACK_TOP` ($639A) | Source text (lines 6240-6670); the stack grows down from $639A (150 bytes at most in the sessions) | Leftover; the stack |
| $639C-$689C | `MASTER_OBJECTS`, `MASTER_VARIABLES` ($684C), `MASTER_KNIGHT` ($6889) | The master copy a new game restores: the object table's first 1200 bytes, the 61 bytes of variables, the knight's record | Made at start-up; source text and unidentified code on the tape |
| $689D-$68AF | `ZEROS_BEFORE_ROOMS` | 19 zeros | Unused |
| $68B0-$758B | `ROOM1` ... `ROOM81` | The 81 rooms: a length word, a colour byte, drawing commands ([`rooms.md`](rooms.md)) | Game |
| $758C-$7CCA | `PART1` ... `PART56` | The 56 parts; 9, 11, 12, 33 and 52 are drawn by none | Game |
| $7CCB-$7CFF | `BYTES_AFTER_PARTS` | 53 bytes nothing reaches | Not identified |
| $7D00-$A8FB | `SPRITE7D00` ... `SPRITEA860` | 72 sprites | Game |
| $8736-$8759 | `BYTES_AFTER_TYPE49` | 36 bytes, not a sprite | Not identified |
| $9E68-$9EC7 | `DIAGONAL_SPRITE` | A 24 by 16 sprite nothing uses | Game, unused |
| $A8FC-$A923 | `SOURCE_BEFORE_OBJECTS` | Source text; `SET_THING_ROOM`, `BUMPED` and EEN use $A91E, $A91F and $A921 as bases into the table | Leftover |
| $A924-$B67F | `OBJECTS` | The object table while the game runs (3420 bytes from $C4E0: the table and 263 bytes of text) ([`object-table.md`](object-table.md)) | Made at start-up; source text on the tape |
| $B680-$B685 | `SOURCE_BEFORE_TITLE` | Source text | Leftover |
| $B686-$B733 | `TITLE_PAGE_TEXT` | A `CALL PRINT`, the title page's string, `RET` | Game |
| $B734-$BAD7 | `TEMPLATES`, `LARGE_TEMPLATES` ($B9AA), `PATCHES` ($BA3E) | The templates (57 of 11 bytes, 15 of 9) and the patches, while the game runs | Made at start-up; source text on the tape |
| $BAD8-$BC17 | `FONT` | 40 characters of 8 bytes | Game |
| $BC18-$BC8F | `FIXED_RECORDS` | Records 1-6: the room's floor, ceiling and walls ([`object-records.md`](object-records.md)) | Game |
| $BC90-$BCA3 | `KNIGHT`, `KNIGHT_SPRITE` ($BC94), `KNIGHT_FLAGS` ($BC9E) | Record 7, the knight | Game |
| $BCA4-$BFFF | `RECORDS` | Records 8-50: the room's objects | Made per room; source text on the tape |
| $C000-$C019 | `LOADING_TUNE` | Play the tune until a key ([`loading-tune.md`](loading-tune.md)) | Game, run once |
| $C01A-$C025 | `VOICE_ONE_NOTE`, `VOICE_TWO_NOTE`, `TUNE_PORT`, `VOICE_ONE_AT`, `VOICE_TWO_AT`, `NOTE_LENGTH` | The tune's variables | Game, run once |
| $C026-$C0AF | `TUNE_NEXT_NOTE`, `TUNE_PITCH`, `TUNE_RESTART_VOICE`, `TUNE_PLAY_NOTE` | The player | Game, run once |
| $C0B0-$C47B | `TUNE_VOICES`, `TUNE_NOTES` ($C0B8) | Pointers, 54 periods, two voices of 418 notes; from $C436 source text | Game, then leftover |
| $C47C-$C4B9 | `START` | The game's first instruction ([`start-up.md`](start-up.md)) | Game, run once |
| $C4BA-$C4DF | `SOURCE_AFTER_START` | Source text (lines 12860-12870) | Leftover |
| $C4E0-$D134 | `OBJECTS_TAPE` | The object table as the tape has it: 381 records and $FF | Game (copied to $A924) |
| $D135-$D2EF | `SOURCE_AFTER_OBJECTS` | Source text (lines 15380-15690) | Leftover |
| $D2F0-$D693 | `TEMPLATES_TAPE`, `LARGE_TEMPLATES_TAPE` ($D566), `PATCHES_TAPE` ($D600) | Templates and patches as the tape has them | Game (copied to $B734) |
| $D694-$DABF | `SOURCE_AFTER_TEMPLATES`; `BUFFER_D800`, `BUFFER_D900`, `BUFFER_DA00` | Source text (lines 16370-17190) | Leftover; buffers at runtime |
| $DAC0-$DADE | `LOADER_TABLE` | The loader's table of pieces, its stack, the checksum bytes | Loader |
| $DADF-$DCC8 | `LOADER_CLEARED`; `BUFFER_DC00` | The loader, cleared by itself | Loader; page $DB at runtime |
| $DCC9-$DD38 | `LOADER_FAILURE` | The loader's failure routine, its key ($DD35) and countdown ($DD36-$DD38) | Loader |
| $DD39-$DFF1 | `SYMBOL_TABLE` | 64 symbols of the assembler's table ([`symbols.md`](symbols.md)) | Leftover |
| $DFF2-$E025 | `MESS2` | Print the quest's closing lines | Game |
| $E026-$E037 | `SYMBOLS_AFTER_MESS2` | A scrap of another state of the symbol table | Leftover |
| $E038-$E099 | `SHOW_MESSAGE` | The message line ([`printing.md`](printing.md)) | Game |
| $E09A-$E0A3 | `SYMBOLS_BEFORE_TEXTURES` | Another scrap | Leftover |
| $E0A4-$E3E3 | `TEXTURES`, `TEXTURE1` ... `TEXTURE25` | 26 textures of 32 bytes ([`textured-fill.md`](textured-fill.md)) | Game |
| $E3E4-$E4F6 | `COMPOSITE_TO_SCREEN` | The compositor ([`compositing.md`](compositing.md)) | Game |
| $E4F7-$E55A | `ISO_MOVE` | The projection ([`projection.md`](projection.md)) | Game |
| $E55B-$EACB | `DRAW_CURRENT_ROOM`, `ROOM_DEFAULTS` ($E582, data), `DRAW_ROOM_RECORD`, `CLEAR_ROOM_SCREEN`, `DO_ROOM_COMMAND`, `FILL_NEXT_SEED` ... `SCREEN_PIXEL`, `PLOT_LINE_START`, `MORE_ROOM_COMMANDS` | Drawing a room, and the fill | Game |
| $EACC-$EBF3 | `PLACE_ROOM_OBJECTS`, `PLACE_OBJECT`, `PLACE_FROM_TEMPLATE`, `COPY_TO_RECORD` | Placing objects | Game |
| $EBF4-$ECBC | `BYTE_BEFORE_PRINT_CHAR`, `PRINT_CHAR`, `PRINT`, `PRINT_FIND_GLYPH`, `SHOW_THING_IN_USE`, `CLEAR_THING_BOX` | The printer and the panel's box | Game |
| $ECBD-$F064 | `REDRAW_OBJECT`, `CULL_OBJECT`, `RECORD_FROM_NUMBER`(`_STEP`), `SORT_AND_DRAW_BEHIND`, `IS_IN_FRONT`, `DRAW_SPRITE` and its parts, `FAR_CORNER`, `CLEAR_256_BELOW`, `CLEAR_512_BELOW` | Drawing objects ([`drawing-objects.md`](drawing-objects.md)) | Game |
| $F065-$F116 | `TITLE_SCREEN`, `WAIT`, `INPUT`, `IN31`, `ATTRI`, `RESTOR` | The game cycle and small routines ([`game-cycle.md`](game-cycle.md)) | Game |
| $F117-$F1DF | `MIMAN`, `MIWRAI`, `MITRO`, `MW`, `FACING`, `DECLI1`, `DE1` | Mirroring; LIFE | Game |
| $F1E0-$F7AF | `CHE3D`, `STEER`, `CREATURE_UPDATE`, `SET_THING_ROOM`, `PICK_UP`, `PICK_UP_LOOK_ON`, `KNIGHT_CONTROLS`, `ANIMATE_AND_MOVE` | The object update ([`object-states.md`](object-states.md), [`movement.md`](movement.md), [`knight.md`](knight.md), [`carrying.md`](carrying.md)) | Game |
| $F7B0-$F905 | `WORKING_POSITION`, `WORKING_SIZES`, `BUMPED` | Doors ([`doors.md`](doors.md)) | Game |
| $F906-$F958 | `SAVE_OBJECT_POSITIONS` | EEN ([`entering-rooms.md`](entering-rooms.md)) | Game |
| $F959-$FC06 | `OBJECTS_MEET`, `SKIPPED_REMOVAL` ($FA74, five dead bytes), `MOVER_VANISHES`, `MEET_DECOY` | Meeting and blocked moves ([`meeting.md`](meeting.md), [`collision.md`](collision.md)) | Game |
| $FC07-$FD1F | `STEP_ALONG_X` ... `STEP_ALL_AXES`, `ZOOMIN`, `AIM_AT`, `TEST_OTHER`, `FIND_OBSTACLE`, `TEST_ONE_RECORD` | Steps, chasing, the collision search | Game |
| $FD20-$FF69 | `ROOMST`, `DRAW_STILL_THINGS`, `MAIN_LOOP` | Entering a room, the main loop ([`main-loop.md`](main-loop.md)) | Game |
| $FF6A-$FF7F | `UDG_LEFTOVERS` | The ends of the ROM's UDGs | Leftover |
| $FF80-$FFFF | `OBJECT_COUNT` ... | The variables (below) | Game |

**At runtime**, from the first room on: $C000-$D7FF is the clean copy of
the screen (`RESTOR` and room code $E2 put it there; the fill uses it as its
map), and $D800-$DBFF the four compositing pages $D8-$DB
([`compositing.md`](compositing.md)); `BUFFER_DC00` names the end of the 512
bytes `SORT_AND_DRAW_BEHIND` clears, and `BUFFER_D900` is also where
`ROOMST` stages a carried record. The stack is at $639A down, in the
leftover text.

## The variables

IY holds $FF80 (the author's `V`) throughout, except inside `ZOOMIN` and
`ROOMST`'s carried-things loop. $FF80-$FFBC (61 bytes) are the game's state
proper, restored from `MASTER_VARIABLES` at a new game. From $FFE4 up the
bytes have several lives, one at a time: the room drawing's state, the
working copy of the record being updated (the author's `T`, +0 at $FFE4),
and the sprite drawing's rectangle and counters. The labels follow the
object code's use where it reads a byte by address, the drawing's otherwise.

| Address | IY+ | Label | What |
|---|---|---|---|
| $FF80 | $00 | `OBJECT_COUNT` | Records in use from $BC18 (7 = up to the knight) |
| $FF82 | $02 | `STRIKES_AT` | The low byte of the strike counter of the fighter last passed ($98-$9D) |
| $FF83 | $03 | `THIS_RECORD` | The number of the record being updated or drawn (knight 7) |
| $FF85 | $05 | `GRAVITY` | $23, never written: ORed into a direction not rising (down) |
| $FF86 | $06 | `OPTIONS` | Bit 3: the Kempston joystick in use (9 flips it) |
| $FF87 | $07 | `MESSAGE` | The message to show: 1 BLOCKED, 2 LOCKED, 3 TOO HEAVY |
| $FF88 | $08 | `MESSAGE_TIMER` | Passes it stays (10) |
| $FF8B | $0B | `NO_RISE_MASK` | $EF, never written: ANDed with a direction not rising (no up) |
| $FF8E | $0E | `ROOM_COLOUR` | The room's colour byte |
| $FF8F | $0F | `DECOY` | The record of a decoy (kind 8) in the room |
| $FF91 | $11 | `THINGS_NOTED` | Bit 0 a decoy in the room; bit 1 the kind-11 thing |
| $FF92 | $12 | `CARRIED_WEIGHT` | The load, 0-7 |
| $FF94 | $14 | `FALL_COUNT` | Passes the knight has been falling |
| $FF95, $FF96 | $15, $16 | `LIFE_TENS`, `LIFE_UNITS` | LIFE, two decimal digits |
| $FF97 | $17 | `GAME_FLAGS` | 0 LIFE to print; 1 sword out; 2 the room's first pass; 3 the fidget; 4 still things being drawn; 6 a message showing; 7 the creatures frozen |
| $FF98-$FF9D | $18 | `STRIKES_LEFT` | Six fighters' strikes left, 4 each on entry |
| $FF9E | $1E | `SELECTED` | The low byte of the place in use ($9F-$A7) |
| $FF9F-$FFA8 | $1F | `CARRIED` | Five words: the records of the things carried |
| $FFB4 | $34 | `ROOM` | The room (29 at a new game) |
| $FFB5 | $35 | `PARTS_TABLE` | $758C |
| $FFB8 | $38 | `FREE_RECORD` | The next free object record |
| $FFBA | $3A | `OBJECT_TABLE_AT` | $A924 |
| $FFBC | $3C | `OBJECTS_PLACED` | Bit 0: the table's things placed in this drawing |
| $FFC6-$FFE3 | $46 | `DRAW_LIST` | 30 bytes: the sorted list of records to draw, over what follows |
| $FFCB | $4B | `ARRIVAL_BOX` | IX base for a door's far side: +5 to +11 are $FFD0-$FFD6 |
| $FFD0, $FFD1 | $50, $51 | `PRINT_X`, `PRINT_Y` | The printing position |
| $FFDA | $5A | `PLACED_TYPE` | The type being placed |
| $FFDB | $5B | `PLACED_NUMBER` | Counts the object table's entries; becomes +19 |
| $FFDF-$FFE1 | $5F-$61 | `ORIGIN`, `ORIGIN_Y`, `ORIGIN_Z` | Added to placed objects (room code `$E4 $05`) |
| $FFE2 | $62 | `AWAY_FRAMES` | The knight's facing-away frames' offset (186 stooping, 372 fighting) |
| $FFE4, $FFE5 | $64, $65 | `POINT`, `POINT_ROW` | The drawing's point; +0, +1 of the working copy; the region's x and top; `ROOMST`'s staging pointer |
| $FFE6, $FFE7 | $66, $67 | `SECOND_POINT`, `SECOND_POINT_ROW` | The second point; the region's width and height; $FFE7 the state when the update began |
| $FFE8 | $68 | `WORK_SPRITE` | +4, +5 (a word); 0, the clear's attribute byte, while a room is drawn |
| $FFEA | $6A | `LINE_PAGE` | 0 lines to the screen, $80 into the clean copy; the working x (+6) |
| $FFEB | $6B | `MODE` | The drawing's mode bits; the working y (+7) |
| $FFEC | $6C | `REPEATS` | The repeat count; the working z (+8) |
| $FFED | $6D | | Kept with `REPEATS` by $E1; the working x length (+9) |
| $FFEE | $6E | `REPEAT_FROM` | The repeat's address; the working height and z length (+10, +11) |
| $FFF0 | $70 | `WORK_KIND` | +12 |
| $FFF1 | $71 | `WORK_DIRECTION` | +13; bit 0 `IS_IN_FRONT`'s answer and bit 1 "something behind" in the sprite drawing |
| $FFF2 | $72 | `WORK_BEHAVIOUR` | +14; `MIRROR`'s new facing |
| $FFF3 | $73 | `DRAW_WIDTH` | A sprite's width in bytes; the working +15 |
| $FFF4 | $74 | `WORK_WEIGHT` | +16; the draw list's length |
| $FFF5 | $75 | `WORK_ANIMATION` | +17; rows to draw |
| $FFF6 | $76 | `WORK_HEADING` | +18 (a word); SP while `CLEAR_512_BELOW` borrows it; the fill's row below |
| $FFF8 | $78 | `FOUND_RECORD` | The number of the record `FIND_OBSTACLE` found (the author's T+20); SP while `CLEAR_ROOM_SCREEN` borrows it; the fill's texture; a sprite row's bytes |
| $FFF9 | $79 | `DRAW_INDEX` | The record `REDRAW_OBJECT` is looking at |
| $FFFA | $7A | `CLEAR_END` | Where `CLEAR_ROOM_SCREEN`'s clearing stopped |
| $FFFB | $7B | `STEP_AXES` | A move's axes (bit 0 x, 1 y, 2 z; 5 landed, 6 a climb, 7 a door); the fill's row |
| $FFFC | $7C | `ASKED_DIRECTION` | The direction asked, before collisions |
| $FFFD | $7D | `WORK_RECORD` | The record being updated (a word); the fill's row above |
| $FFFE | $7E | `DRAW_COUNT` | The draw list's count; the sort's move limit |
| $FFFF | $7F | `RIDE_DIRECTION` | The direction of what the mover rides; the list's last index |

Not used in Release 2 (*read*: nothing reads them): $FF81, $FF84, $FF89,
$FF8A, $FF8C, $FF8D, $FF93, $FFA9-$FFB3, $FFB7, $FFBD-$FFC5. On the tape
many hold ends of the ROM's UDGs.

## The records and the table

The twenty-byte object record, the kind byte, the direction byte and the
fixed records: [`object-records.md`](object-records.md). The object table
(163 six-byte records, 174 eleven-byte doors, 44 six-byte records, $FF) and
the templates: [`object-table.md`](object-table.md).

## How this was found

The load map from the loader's trace ([`loading.md`](loading.md)); the
start-up's copies by reading `START` and stepping the simulator until each
destination changed; what is leftover by reading the bytes and by what the
sessions wrote; the stack's depth by comparing $6000-$6399 before and after
each session. The variables by a cross-reference of every absolute and IY+n
reference in the listing, each read in place (stage 2, range 5), with the
author's `(V+n)` and `(T+n)` from the source text.

## Disassembly corrections

- **$FFF8 was `SAVED_SP`.** SP is kept there only by `CLEAR_ROOM_SCREEN`;
  the object code reads it as the number of the record found (the author's
  `T+20`), and it is `FOUND_RECORD` now. Krumlinde's `VAR_Saved_SP` made the
  same mistake. (`CLEAR_512_BELOW` keeps SP at $FFF6 instead.)
- **The object table** is 163 six-byte, 174 eleven-byte and 44 six-byte
  records, not 163 and 218 as stage 1's notes said.
- **+9 to +11** are lengths from a corner, not half-sizes.
- **$BC18's six records** are the room's floor, ceiling and walls (stage 1
  left them open).
- Stage 1's placeholder names (`VARFFxx`, `SUBxxxx`, `DATAxxxx`,
  `TEXTxxxx`) are all gone; the topic files' "Renamed routines" tables give
  old and new.

## Open questions

- $7CCB, $8736 and $9E68: what they are.
- The code at $639C + 293 on the tape.
- Whether the draw list's 30 entries can be exceeded.
