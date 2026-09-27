# Memory map

**Question this answers:** what is where -- the 40000 bytes the tape loads at
$6000-$FC3F, and what the game uses below and above them.

**Short answer:** words at the bottom, then the code up to $AB52 with small
tables and work bytes among it, then the tables that drive the game (action
patterns, messages, variables, command frames, rooms, objects, scripts,
timers, characters), then the pictures, and at the top the copy of the world
kept for starting again. Below the game: the title screen (loaded straight
onto the display), the BASIC loader, the stack from $5EFF down, and the
saved variables at $5F00. Every loaded byte is accounted for in the
disassembly; this is the outline, from its entry list, grouped.

## The loaded block, $6000-$FC3F

| From | To | Label | What |
|---|---|---|---|
| $6000 | $603F | `WORD_INDEX` | the dictionary's index by initial letter |
| $6040 | $67AA | `WORD_LIST` | the 355 words the parser reads ([`dictionary.md`](dictionary.md)) |
| $67AB | $6BEE | `SECOND_LIST` | the 207 words only the messages print |
| $6BEF | $6BFF | | zeros |
| $6C00 | $6DD5 | `START`, `NEW_GAME`, `MAIN_LOOP` | start-up and the main loop ([`loading.md`](loading.md), [`main-loop.md`](main-loop.md)); `DIVIDER` at $6DCC |
| $6DD6 | $6FF1 | `READ_LINE`, `TOKENISE`, `MATCH_WORD` | the line reader and the tokeniser ([`input.md`](input.md)) |
| $6FF2 | $70E1 | `FIRST_COMMAND`, `INPUT_LINE` ($6FF9), `TYPED_WORD`, `TOKENS` ($709C), `MESSAGE_A` | the line and its tokens |
| $70E2 | $7584 | `PATTERN_OF`, `NARRATE_ACTION`, `NAME_MATCHES`, `GET_KEY`, `RUN_MESSAGE`, `CONTROL_CODES` ($7295), `PRINT_WORD` | narration, messages and words ([`messages.md`](messages.md)); `WORD_BUFFER` at $74A6, `AND_TOKENS` and `PHRASE` at $7574 |
| $7585 | $7F76 | `PARSE_COMMAND` ... `CANCEL_ORDERS` | the parser, `OBEY`, pattern matching and object matching ([`parser.md`](parser.md), [`actions.md`](actions.md)); `PARSER_CLASSES` at $75D2, `PHRASES` at $793D |
| $7F77 | $824D | `DRAW_LOCATION_PICTURE`, `RUN_PICTURE`, `FLOOD_FILL`, `DRAW_LINE`, `PIXEL_ADDRESS`, `CLEAR_CANVAS` | the picture interpreter ([`pictures.md`](pictures.md)); what the fast-draw patch rewrites |
| $824E | $8250 | `PLOT_INK`, `ORDER_SAVED_D`, `ORDER_FIRST_FRAME` | work bytes |
| $8251 | $85B2 | `PARSE_SPECIAL`, `SPECIAL_WORDS` ($8271), their handlers, `HELP_HINTS` ($83CD), `SHOW_SCORE`, `DO_SAVE`, `DO_LOAD`, `PRINT_CHAR` | the special words, SAVE and LOAD ([`save-load.md`](save-load.md)) |
| $85B3 | $8821 | `INPUT_CHAR`, `STORY_CHAR`, `SCROLL_STORY`, `NARROW_CHAR` | the two text windows ([`screen-and-printer.md`](screen-and-printer.md)) |
| $8822 | $8B21 | `FONT` | the story's six-pixel font |
| $8B22 | $8C4A | `LINE_TO_PRINTER`, `SCAN_KEYBOARD`, `KEY_STATE`, `KEY_MAP`, `KEY_MAP_SHIFTED` | the printer and the keyboard |
| $8C4B | $AB52 | `DO_LOOK` ... `EYES_STING` | the game: the handlers, `MOVE` ($8D9D), `VISIT_SCORES` ($8D6E), `CHARACTERS_ACT` ($980E), `END_OF_TURN` ($96B3), `DO_ACTION` ($950F), the lookups, the objects' and characters' own routines, and six unreached stretches ([`leftovers.md`](leftovers.md)); small tables among them: `WOUNDS` $9226, `SECOND_FIRST` $A20B, `DIRECTION_WORDS` $A210, `STATE_WORDS` $A224, `GOBLIN_HOMES` $A49C |
| $AB53 | $AD2C | `ACTION_PATTERNS` | the 59 sentence shapes |
| $AD2D | $AD3C | `ARTICLES` | THE, A, AN, SOME, twice |
| $AD3D | $AD7C | `COMMON_WORDS` | the 32 one-byte words |
| $AD7D | $B6D9 | `MSG_...` | the 177 messages |
| $B6DA | $B71E | `VARIABLES` ... | the game's variables; $B6EB-$B707 is the block SAVE writes and a new game restores (`SCORE` $B6F7, `ACTING` $B6EA, `ACTOR` $B70C) |
| $B71F | $B737 | `ENDINGS`, `ORDER_COUNT` | word endings |
| $B738 | $B7FF | `ORDERS` | eight 25-byte slots of orders |
| $B800 | $B9DF | `FRAMES`, `NEXT_FRAME` ($B9B0), `COMMAND_FRAME` ($B9C8) | the command frames |
| $B9E0 | $BA7F | `ROOM_POINTERS` | a pointer per location |
| $BA80 | $BA89 | `ROOM_PREPOSITIONS` | OUTSIDE, INSIDE, IN, ON, AT |
| $BA8A | $C062 | `ROOM0`-`ROOM79` | the room records ([`locations.md`](locations.md)) |
| $C063 | $C11A | `OBJECT_INDEX` | 61 objects by number |
| $C11B | $C72F | `PLAYER` ... | the object records ([`objects.md`](objects.md)) |
| $C730 | $C78D | `ACTION_TABLE` | the ordinary handlers |
| $C78E | $C7FB | `ARRIVAL_HOOKS` and their routines ($C7A4-$C7FB) | |
| $C7FC | $C80D | `RIDDLES` | two riddles, each twice; two $FF |
| $C80E | $C82C | `HIDDEN_ROADS` | five roads ([`hidden-roads.md`](hidden-roads.md)) |
| $C82D | $CA83 | `..._SCRIPTS` | the characters' script tables and scripts ([`characters.md`](characters.md)) |
| $CA84 | $CACA | `TIMERS` | ten timers ([`time-and-timers.md`](time-and-timers.md)) |
| $CACB | $CB42 | `CHARACTERS` | seventeen slots |
| $CB43 | $CBFF | | zeros |
| $CC00 | $CC42 | `PICTURE_TABLE` | which 22 locations have a picture |
| $CC43 | $F35A | `LOC..._PIC` | the 22 picture streams |
| $F35B | $F3FF | `AFTER_PICTURES` | zeros (the fast-draw patch uses them) |
| $F400 | $FC3F | `WORLD_COPY` | zeros on the tape; `START` copies the objects and rooms here |

## Around it

| From | To | What |
|---|---|---|
| $0000 | $3FFF | the ROM: the game calls only SA-BYTES ($04C2) and LD-BYTES ($0556), and reads its font at $3D00 |
| $4000 | $5AFF | the display: the title picture ("p") is loaded straight onto it; then the picture canvas (rows 0-15), the story, the divider and the input window |
| $5B00 | $5BFF | the printer buffer: never used (the game drives the printer itself) |
| $5C00 | $5E84 | the system variables ($5C00-$5CB5), then the BASIC loader from $5CCB and what it used; the running game never touches this, and the fast-draw patch puts code at $5D00-$5DB1. `ERR_SP` still points into BASIC's stack, at $5FFC |
| $5E85 | $5EFF | the game's stack, from `LD SP,$5EFF`; the deepest seen in play was $5E85 |
| $5F00 | $5FDB | `START`'s copy of the variables ($5F00) and of `TIMERS` and `CHARACTERS` ($5F1D) |
| $FC40 | $FFFF | not loaded by the tape: the ROM's user-defined graphics and whatever else was there; `START`'s copy of the rooms runs from $FA15 to $FFED over it |

## How this was found

The block list is the disassembly's own (`build_hobbit.py` accounts for
every byte and reassembles it exactly); the regions around it from the
loader, `START`'s copies, `NEW_GAME`'s `LD SP` and the fast-draw work's
stack measurements. The ranges were rechecked against the skool file for
these notes.

## Disassembly corrections

- This note used to say the tape loads "the 40000 bytes ... $6000-$FFFF".
  40000 bytes from $6000 end at $FC3F; the rest is only written by `START`.
  Corrected 2026-09-27.

## Open questions

- None about the layout.
