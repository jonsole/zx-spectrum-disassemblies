# Memory map

**Question this answers:** where everything is -- the tape's small blocks, the
game's variables, the template, the room lists, the code, the tables, the
graphics and fonts, and the runtime records -- and what is code, data and
unused.

**Short answer:** the decrypted game is $6000-$D5FF: a three-instruction entry,
the 5488-byte castle template, the room contents lists, about 10K of code
from $7C19 to $A4BD with small tables inside it, then the sprite tables and
graphics interleaved with the room table, the room shapes and the three
character sets, to 251 bytes of padding. The game's variables are at
$5E00-$5E6F below it, with the stack underneath; at run time the template's
copy fills $EA90 to the top of memory.

## Regions

| From | To | Label | What |
|---|---|---|---|
| $4000 | $5AFF | | screen: play area columns 0-23, the scroll 24-31; the loading screen before the game starts |
| $5B80 | $5B91 | | the decryptor (tape block 4), dead after loading ([`loading.md`](loading.md)) |
| $5C78 | $5C79 | `FRAMES` | poked $255E by the tape; checked at `ENTRY`; the game subtracts 50 from it each second |
| $5CB0 | | `JP_HL_POKE` | the `JP (HL)` every dispatch goes through (tape block 5) |
| below $5E00 | | | the machine stack; SP is reset to $5E00 every pass |
| $5E00 | $5E0F | `SELECTION` ... | the menu choice; the tile-source pointer ($5E01), `LAST_FRAME`, `IN_FRAME`, `RUNNING_SUM` ($5E05) -- cleared by `TITLE_SCREEN` |
| $5E10 | $5E6F | | the game's variables, cleared by `CLEAR_VARIABLES` at every `START_GAME` (below) |
| $5FFF | | | the first byte of the game block, not part of the game |
| $6000 | $600C | `ENTRY` | the FRAMES check, `JP TITLE_SCREEN` |
| $600D | $757C | `INITIAL_STATE` | the castle template, copied to $EA90 ([`records.md`](records.md)); one line per record in the listing |
| $757D | $76A8 | `ROOM_CONTENTS` | 150 pointers to room lists |
| $76A9 | $7C18 | `ROOM_LIST_00`... | the lists, one entry per room, ending on the byte before the code |
| $7C19 | $A4BD | `TITLE_SCREEN`... `SOUND_BOUNCE` | the code, with tables inside it (below) |
| $A4BE | $A69B | `SPRITE_TABLE`, `FURNITURE_SPRITES` $A600, `FURNITURE_COLOURS` $A64E | 161 sprite, 39 furniture and 39 colour-table pointers ([`drawing.md`](drawing.md)) |
| $A69C | $D504 | `GFX_...`, `ATTRS_...` | the graphics and colour tables, one entry each, with these among them: |
| $A854 | $A981 | `ROOM_TABLE` | 151 colour-and-shape pairs ([`castle.md`](castle.md)) |
| $A982 | $A9CF | `ROOM_SHAPES` | 13 shapes of six bytes |
| $A9D0 | $AD2D | `SHAPE_VERTI_..`, `SHAPE_EDGES_..` | the outlines (shape $0C's is in the code area, $97A9-$9869; $09 and $0A's at $BD7E-$BF4B) |
| $B03A | $B329 | `PANEL_TILES` | the scroll's 94 tiles |
| $B32A | $B3E9 | `PANEL_LAYOUT` | the scroll, 8 x 24 tile numbers |
| $BF4C | $C123 | `TEXT_FONT` | 59 characters, space to Z (`FONT_DIGITS` $BFCC is its "0") |
| $D505 | $D5FF | `TAIL_PADDING` | 251 bytes nothing reads |
| $D600 | $EA8F | | not loaded; no instruction addresses it (*read*) |
| $EA90 | $FFFF | `PLAYER`... `LIVE_DOORS` | the runtime copy of the template: player, weapon, sound slot, objects, the drop controller at $EE58, monsters at $EE60, doors from $EEE0 |

## Tables inside the code

| Address | Label | What |
|---|---|---|
| $7CEA | `MENU_DATA`, `MENU_ROWS`, `MENU_TEXT`, `COPYRIGHT_LINE`, `MENU_TITLE` | the title menu |
| $7EE6 | `ACTOR_HANDLERS` | 202 handler addresses; from $802A the room records' |
| $83CA | `STEP_VECTORS` | sixteen steps round a quarter circle |
| $8B6A | `MONSTER_TEMPLATE` | a new creature |
| $8B7A | `SPAWN_TYPES` (with `SPAWNABLE_SPRITES` $8B85) | what it becomes |
| $8C2D | `FOOD_RECORD` | scratch record for the roast |
| $8C59 | `GAME_OVER_TEXT` | |
| $925C | `DOOR_COLOURS` | the four key colours |
| $9481 | `PLAYER_TEMPLATE` | a new life |
| $94DD | `KEY_ROOM_SETS` | eight sets of rooms for the A.C.G. pieces |
| $967F | `END_LABELS`, `SCORE_LABEL`, `PERCENT_LABEL` | the three summary labels (the last is the percentage) |
| $9710 | `END_MESSAGES`, `ESCAPED_TEXT` | the escape messages (CONGRATULATIONT) |
| $97A9 | `SHAPE_VERTI_0C`, `SHAPE_EDGES_0C` | the trapdoor fall's rectangles |
| $9883 | `ARRIVAL_HEADINGS` | the arrival headings |
| $98C4 | `MUSHROOM_COLOURS` | |
| $990C | `RANDOM_ROOMS_ONE`...`THREE` | candidate rooms for the green, red (and mummy) and cyan keys |
| $9970, $9985 | `PIXEL_DRAWERS`, `COLOUR_DRAWERS` | the sixteen furniture drawers |
| $A064 | `COLOUR_FILLERS` | the nine attribute fillers (two entries harmless) |
| $A17D | `UI_RECORD` | scratch record for drawing non-actors |
| $A331 | `TITLE_ICONS` | the title screen's nine pictures |
| $A4A0 | `SWEEP_PITCHES` | sound $A0's pitches |

## The variables, $5E10-$5E6F

(*read*; the build's equates, with the meanings these notes found.)

| Address | Label | Meaning |
|---|---|---|
| $5E10, $5E11 | `DRAW_WIDTH`, `DRAW_SHIFT` | drawing workspace |
| $5E12-$5E13 | `TICKS` | main-loop passes |
| $5E14 | `ROOM_DRAWN` | bit 0: the room's first pass is done |
| $5E15-$5E17 | `WORK_SPRITE`, `WORK_X`, `WORK_Y` | the current record's sprite and position before it moved |
| $5E18, $5E19 | `ERASE_ROWS`, `DRAW_ROWS` | rows left to erase and to draw |
| $5E1A | `ROOM_COLOUR` | |
| $5E1B | `LIST_POINTER` | the room-list walk |
| $5E1D, $5E1E | `ROOM_HALF_WIDTH`, `ROOM_HALF_HEIGHT` | the walk rectangle |
| $5E1F | `PICKUP_USED` | pick-up key used (bit 1), picked up this pass (bit 0) |
| $5E20 | `PICKUP_KEY` | SYMBOL SHIFT held |
| $5E21 | `LIVES` | spare lives, 3 at the start |
| $5E22 | `MENU_COLOUR` | |
| $5E23, $5E24 | `LINE_WORK` | line drawing |
| $5E25 | `ACTORS_HERE` | creatures counted in the room this pass |
| $5E26, $5E27 | `SPAWN_ROOM`, `SPAWN_COUNTDOWN` | the spawner |
| $5E28, $5E29 | `FOOD_LEVEL`, `FOOD_DRAWN` | the life force, and as last drawn |
| $5E2A-$5E2C | `SCORE` | six BCD digits |
| $5E2D | `IN_DOORWAY` | the player is outside the walk rectangle (in a doorway) |
| $5E2E | `DOOR_WAIT` | the timed doors' shared countdown |
| $5E2F | `STEP_COUNTER` | footsteps |
| $5E30-$5E3B | `CARRIED` | three slots: record address, sprite, colour |
| $5E3C | `FLASH_COUNT` | the score's flash at the start of a life |
| $5E3D-$5E3F | `CLOCK` | hours, minutes, seconds (BCD) |
| $5E40-$5E52 | `ROOMS_SEEN` | a bit per room |
| $5E54 | `ROOMS_EXPLORED` | the percentage figure |
| $5E55-$5E56 | `REGROW_CURSOR` | the food-regrowth cursor |

## Code, data, unused

- **Code:** $6000-$600C and $7C19-$A4BD less the tables above: every
  instruction in the build's code map ran in its playthroughs, plus the
  routines declared code from the handler and drawer tables (the collectables,
  locked cave doors, trapdoors, the characters' doors, the end screen) and
  checked by the round trip.
- **Unused:** `NEXT_PIXEL_ROW` ($9BC1) and `SETUP_BOTH_BANKS` ($9F74), called
  from nowhere; shapes $06 and $07; `TAIL_PADDING`; handler entries pointing
  at `INERT_SPRITE`; the HL each character handler passes to `MOVE_PLAYER`
  (popped and dropped, [`player.md`](player.md)); `LD IX,$EEE0` at $7DD6
  ([`main-loop.md`](main-loop.md)).

## How this was found

The regions are the skool's entries (2026-09-27); the variables' meanings
come from the topic notes, each from reading every access.

## Renamed routines

Applied to the annotations on 2026-09-27. The routines are tabled in the
topic notes; the variables and tables named here:

| New name | Old name | Address | Role |
|---|---|---|---|
| `PICKUP_USED` | `CARRYING` | $5E1F | the pick-up key's used bits |
| `ERASE_ROWS`, `DRAW_ROWS` | `CLIP_COUNT`, `CLIP_LIMIT` | $5E18, $5E19 | rows left to erase and to draw |
| `IN_DOORWAY` | `FIRE_BLOCKED` | $5E2D | the player is outside the walk rectangle |
| `REGROW_CURSOR` | `CURSOR` | $5E55 | the food-regrowth cursor |
| `DROP_CONTROL_ROOM` | `MOVE_ROOM` | $EE59 | the drop controller's room |
| `WEAPON_LIFE` | (new) | $EAA7 | the weapon's lifetime |
| `LIVE_MUMMY_LURE`, `MUMMY_LURE` | `LIVE_COLLECTABLE_80`, `COLLECTABLE_80` | $EAE0, $605D | object $80 |
| `PERCENT_LABEL` | `TIME_LABEL` | $969F | the percentage line |
| `ARRIVAL_HEADINGS` | `DRIFT_OFFSETS` | $9883 | arrival headings |
| `COLOUR_FILLERS` | `FILL_HANDLERS` | $A064 | the attribute fillers |

## Disassembly corrections

All applied to the annotations, the ref and the build on 2026-09-27 (the old names are used below), except where marked.

- `CARRYING`, `CLIP_COUNT`/`CLIP_LIMIT`, `FIRE_BLOCKED` and `TIME_LABEL` are
  misleading names; see the topic notes.

## Open questions

- None about the layout.
