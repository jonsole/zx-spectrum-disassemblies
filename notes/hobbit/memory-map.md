# Memory map

**Question this answers:** what is where in the 40000 bytes the tape loads,
$6000-$FFFF.

**Short answer:** words at the bottom, then code up to $AB52, then the tables
that drive the game (actions, messages, variables, rooms, objects, scripts),
then the pictures, and at the top a copy of the world kept for starting
again. Every byte is accounted for in the disassembly; this is the outline,
taken from its block list. Blocks of the same kind are summarised as one row.

| From | To | What |
|---|---|---|
| $6000 | $603F | `WORD_INDEX`: the dictionary, indexed by initial letter |
| $6040 | $67AA | `WORD_LIST`: the words the parser reads |
| $67AB | $6BFF | `SECOND_LIST`: the words the game prints but does not read |
| $6C00 | $6FF1 | START and the line reader (`READ_LINE`, `TOKENISE`) |
| $6FF9 | $7078 | `INPUT_LINE`: the line being typed |
| $709C | $70DB | `TOKENS`: the line being obeyed |
| $70E2 | $806E | the parser, narration and message printing |
| $8071 | $824D | the picture interpreter and its drawing code (what the fast-draw patch replaces) |
| $8251 | $82A4 | `PARSE_SPECIAL` and `SPECIAL_WORDS`: SAVE, LOAD, QUIT, SCORE and the rest |
| $82A5 | $8821 | the special words' handlers, the story printer (`STORY_CHAR`) |
| $8822 | $8B21 | `FONT`: the story's six-pixel font |
| $8B22 | $AB52 | the game: moving, `VISIT_SCORES` ($8D6E), the actions, `CHARACTERS_ACT`, END_OF_TURN, winning |
| $AB53 | $AD2C | `ACTION_PATTERNS`: the sentence each action code stands for |
| $AD3D | $AD7C | `COMMON_WORDS` |
| $AD7D | $B6D9 | 177 messages |
| $B6DA | $B737 | the game's variables -- `ACTING` $B6EA, `SCORE` $B6F7; $B6EB-$B707 is the block START keeps and SAVE writes |
| $B738 | $B7FF | `ORDERS`: what the player has told characters to do |
| $B800 | $B9C7 | `FRAMES`: the parsed commands |
| $B9E0 | $BA7F | `ROOM_POINTERS` |
| $BA8A | $C062 | 80 room records, `ROOM0`-`ROOM79` |
| $C063 | $C11A | `OBJECT_INDEX` |
| $C11B | $C72F | 61 object records, the player's first |
| $C730 | $C78D | `ACTION_TABLE` |
| $C7A4 | $C7FB | routines kept among the tables |
| $C7FC | $C80D | `RIDDLES` |
| $C80E | $C82C | `HIDDEN_ROADS` |
| $C82D | $CA83 | the characters' scripts |
| $CA84 | $CACA | `TIMERS` |
| $CACB | $CBFF | `CHARACTERS` |
| $CC00 | $CC42 | `PICTURE_TABLE`: which locations have a picture |
| $CC43 | $F35A | 22 pictures |
| $F35B | $F3FF | unused |
| $F400 | $FFFF | `WORLD_COPY`: the objects and rooms as loaded, for NEW_GAME to copy back |

The variables and timers are copied to $5F00 by START, below the game.

## Open questions

- None about the layout; see the individual notes for what the tables mean.
