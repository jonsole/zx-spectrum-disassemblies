# The main loop

**Question this answers:** what runs from the loader's jump to the first
turn, what one turn does and in what order, and how the game reaches its
tables of routines.

**Short answer:** `START` checks FRAMES, sets the stack and clears every
variable; `NEW_GAME` runs the menu, draws the panel, places the knight, the
villains and the objects and stocks the buildings; then `MAIN_LOOP` is one
turn: every one of the 23 object records is updated by the routine its
graphic picks, through `DISPATCH` and the `JP (HL)` at `NMIADD`; then the
once-a-turn jobs (spawning, the sound effect, the panel), the whole town
drawn into a buffer, the knight coloured, a new life or the ending if due,
and the buffers copied to the screen. There is no wait: a turn takes as
long as its work.

## How it works

```
ENTRY $5E00        DI (already off), JP START
START $BDFE        protection check 1 (FRAMES); SP = $5E00;
                   clear $BBAA-$BDFD (variables and records)
NEW_GAME $BE0F     (also from GAME_OVER, and from the ending's end)
  clear $BBB4-$BDFD; TURNS = FRAMES; CLEAR_SCREEN; MAKE_TABLES ($E0FB)
  MENU ($C8CA) until 0; TUNE_GAME_START; CLEAR_SCREEN
  DRAW_PLAY_FRAME, DRAW_PANEL_FRAME; SCORE_TEXT; PRINT_SCORE;
  PRINT_COMPASS; PRINT_HEADING; CLEAR_BUFFER
  TOP_SPEED = 10; LIVES = the opcode at LIVES_BYTE >> 2 (6)
  RANDOM_START_CELL; START_FACING = $40; FIRST_LIFE ($CBC5)
  PLACE_VILLAINS; PLACE_OBJECTS; DRAW_VILLAINS
  STOCK_BUILDINGS (protection check 3)
MAIN_LOOP $BE71    one turn
  NEXT_OBJECT: for each record, KNIGHT ($BC8E) to the last monster:
     A = graphic; DISPATCH through UPDATES ($D599); STIR_RANDOM
  NEXT_TURN ($C5B4)
  ENDING set? -> END_OF_TURN
  SPAWN_FIND ($C5CE)   SPAWN_MONSTER ($CDE8)   SPAWN_CREATURE ($BF95)
  PLACE_BONUS ($D76C)  EFFECT_NOTE ($C3BD)     COLOUR_CARRIED ($C4DC)
  DRAW_CELLS ($CF08)   -- the town and every thing in it, into BUFFER
  COLOUR_KNIGHT ($C898) by HITS through KNIGHT_COLOURS ($C065)
  NEW_LIFE ($CBAC)     CHECK_QUEST_DONE ($D865)
END_OF_TURN $BECD
  SHOW_PLAY_AREA ($E200): buffers to the screen, then CLEAR_BUFFER
  LAST_FLASH = FLASH; FLASH = 0
  PAUSE ($E32C)
  JR MAIN_LOOP        (the JR at LIVES_BYTE, $BEDD)
```

- **What survives from one game to the next** (*read*): the clear at
  `NEW_GAME` starts at `CELL_LOOKED_UP` ($BBB4), so `RANDOM`, `FONT_BASE`,
  `SAVED_SP`, `CONTROL` and `LAST_CONTROL` carry over. `TURNS` is outside
  the cleared part but is set from the frozen FRAMES at every game
  ([`protection.md`](protection.md)). `START_RECORDS` is code-space data and
  keeps the last death's cell, facing and flags; `NEW_GAME` resets the
  facing and `RANDOM_START_CELL` the cell
  ([`lives-and-starting.md`](lives-and-starting.md)).
- **Updating is separate from drawing.** Every record is updated first;
  only then does `DRAW_CELLS` walk the nine cells round the knight and draw
  each record in its cell's turn ([`drawing-order.md`](drawing-order.md)).
  A record's update decides its graphic and position for the turn; the
  drawing reads them.
- **The dispatch.** `DISPATCH` ($D593) takes A as an index into the table
  at BC (`TABLE_WORD`, $D589: the word at BC + 2A), puts the routine in HL
  and jumps to `NMIADD` ($5CB0), where the tape put `JP (HL)`. The routine
  returns to `DISPATCH`'s caller. Six tables go this way: `UPDATES` by
  graphic ([`graphic-numbers.md`](graphic-numbers.md)); `DEPTH_TABLE` ($D0A0)
  in the depth sort; `MONSTER_HIT_TABLE` ($C0D1) in a strike;
  `COAST_TABLE` ($DC71), `TURN_TO_KNIGHT_TABLE` ($DD6A) and `MOVE_TABLE`
  ($DE6A), by facing.
- **The ending** is object records too: while `ENDING` is set the loop only
  updates records and shows the buffer
  ([`game-over-and-ending.md`](game-over-and-ending.md)).
- **The random number** is stirred after every record's update: 23 times a
  turn in the loop alone ([`random-numbers.md`](random-numbers.md)).
- **Pacing.** The once-a-turn jobs pace themselves by `TURNS`' low bits:
  a find every 16th turn, a monster every 4th, the creature every 256th.
  Nothing evens out the speed of a turn (Alien 8 pads its turns; Nightshade
  does not), so a busy view runs slower (*read*; not timed).

## How this was found

*Read*: the order of the once-a-turn calls, and what each paces itself by,
from each callee's first instructions (stage 2, range 1). The dispatch and
the tables from `DISPATCH` and its six callers (range 3).

## Confidence

*Read* throughout. The creature's pacing *measured* ([`creature.md`](creature.md)).
That nothing evens out a turn's time is *read* (no wait or frame count in
the loop); how much a turn's time varies was not measured.

## Filmation (Knight Lore, Alien 8, Pentagram)

The earlier games' main loops update a room's records and redraw on a
room change; Nightshade updates a fixed set of 23 records wherever the
knight is and redraws the whole view every turn. The dispatch by graphic
through a table of routines is the family's (`TABLE_WORD` is Pentagram's
name, Knight Lore's `jump_to_tbl_entry`); the jump through a system
variable is Nightshade's own. Alien 8 pads each turn to an even amount of
drawing work; Nightshade does not.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `NEXT_TURN` | `SUBC5B4` | $C5B4 | count a turn, then stir |
| `STIR_RANDOM` | (entry point) | $C5BB | stir the random number |
| `TABLE_WORD` | `SUBD589` | $D589 | the word at BC + 2A (Pentagram's name) |
| `NO_UPDATE` | `SUBD6D5` | $D6D5 | an update that does nothing (Alien 8's name) |
| `KNIGHT_COLOURS` | `TEXTC065` | $C065 | the knight's colour by hits |

`START`, `NEW_GAME`, `MAIN_LOOP`, `NEXT_OBJECT`, `END_OF_TURN`,
`LIVES_BYTE` and `DISPATCH` are stage 1's and stand.

## Open questions

- How much a turn's time varies between a quiet street and a busy one
  (a timing run in the simulator, T-states per turn over a tour, would say).
