# The main loop

**Question this answers:** what runs, in what order, from the moment the game
is loaded -- a game, a life, a room, a turn -- and what sets the speed.

**Short answer:** Knight Lore's main loop almost unchanged: `START` ($A631)
is three loops one inside another -- a life (`MAIN_NEW_LIFE`), a room
(`MAIN_NEW_ROOM`) and a turn (`MAIN_NEXT_TURN`) -- around a walk over all 56
object records, each record's update routine found by its graphic in
`UPDATES` ($A7EA) and returning to `OBJECT_DONE` ($A6C0). The end of a turn
(`MAIN_END_OF_TURN`, $A6DC) draws what changed and pads the turn to six units
of drawing work, a unit being about 20,000 T-states, so a quiet room runs no
faster than one where six things are drawn; a busier one runs slower. Then
the light-years clock, which can end the game.

## How it works

```
ENTRY $6300            DI, LD SP,$F100, NOP, JP START
START $A631            FRAMES -> SEED; clear $5B00-$6287 (variables and records);
                       R_CHECK_LEFTOVER $A8F1 (returns at once)
AFTER_GAME $A647       (every game comes back here) clear from WIPE_COUNT $5B08
MAIN_NEW_GAME $A650    BUILD_LOOKUP_TBLS $CFA7, PLAYED = 0, the start legs'
                       +$0C cleared ($CA29), LIVES = 5, CLOCK = 6000,
                       SEED += TURNS, CLEAR_SCRN $CE73, MENU $BA7E,
                       PLAY_TUNE TUNE_START $B3C5, NEW_GAME_START $CA6D,
                       INIT_SPECIAL_OBJECTS $AF3F, RESET_ROOM_COLOURS $CAD2
MAIN_NEW_LIFE $A688    NEW_LIFE $CA07: the start records over his, a life taken
MAIN_NEW_ROOM $A68B    ENTER_ROOM $CAA2 (a doorway, EXIT_SCREEN $C3B7, jumps here)
MAIN_NEXT_TURN $A68E   IX = OBJECTS
  MAIN_NEXT_OBJECT $A692   SP = $F100; push OBJECT_DONE; +$18..+$1B -> +$1C..+$1F
  MAIN_DISPATCH $A6B1      JUMP_THROUGH_TABLE $A6B7 through UPDATES by graphic
  OBJECT_DONE $A6C0        RANDOM += R; next record, until $6288
  MAIN_END_OF_TURN $A6DC   TURNS + 1; RANDOM += (TURNS) + L + H; PLAYED bit 0;
                           LIST_DRAWN $C71C; RENDER_DYNAMIC_OBJECTS $CEAB;
                           [GAME_OVER: skip the wait and the clock]
                           wait 6 - DRAW_WORK units; RUN_CLOCK $AD66;
                           [NEW_ROOM: DISPLAY_PANEL $CB0F, COLOUR_PANEL $A749,
                            SHOW_BUFFER $CE85, CLEAR_WIPE_FLAGS $A7DC];
                           HANDLE_PAUSE $CE22;
                           legs and top both empty -> MAIN_NEW_LIFE, else MAIN_NEXT_TURN
```

- **What survives a game** (*read*). `START` clears everything from `SEED`
  to the end of the object records once, after reading the ROM's frame
  counter (`FRAMES`, $5C78, inside what will be record 7) into `SEED`.
  `AFTER_GAME` clears again only from `WIPE_COUNT` ($5B08), so `SEED`,
  `TURNS`, `CONTROL`, `RANDOM` and `CONTROL_BEFORE` carry over: the menu
  shows the method chosen last time and the random sequence goes on.
  `TUNE_HEARD` is cleared with the rest, so the menu's tune plays once at
  every menu, not only after loading. `BUILD_LOOKUP_TBLS` runs at every new
  game, not just the first.
- **The dispatch.** A routine is entered with IX on its record and
  `OBJECT_DONE` on the stack, so it ends with RET; it animates by changing
  its own graphic ([`graphic-numbers.md`](graphic-numbers.md)).
  `JUMP_THROUGH_TABLE` is shared: `CALC_PLYR_DUV` ($C2F6, through
  `DISPATCH_ON_FACING`) and `SORT_AND_DRAW` ($C785) jump through tables of
  their own with it. Graphic 0, an empty record, goes to `NO_UPDATE` ($A8F0),
  a RET: every record is visited every turn, empty or not.
- **The stack.** SP is set back to $F100, the top of `STACK_SPACE`, before
  every object's update, as Knight Lore does (Knight Lore's is below its
  variables). A routine that abandons the turn -- `EXIT_SCREEN` -- can
  therefore just jump back into the loop.
- **The random number** (*read*). `OBJECT_DONE` adds R after every object's
  update; the end of the turn adds the byte the turn counter points at and
  both of the counter's bytes. R counts instructions fetched, so the numbers
  depend on how long each update took.
- **The wait** (*read*; the T-states counted from the instructions, not
  timed). `DRAW_WORK` ($5B1E) is zeroed by `SORT_AND_DRAW`, counts one per
  object drawn (`DRAW_CANDIDATE` $C8D5) and gains the areas
  `RENDER_DYNAMIC_OBJECTS` wiped (`WIPE_COUNT`). The loop then waits six
  units less that: a unit is `LD HL,$0300` and 768 turns of a 26 T-state
  loop, 19,968 T-states, about 20,000 -- Knight Lore's and Pentagram's unit
  is 1280 turns. At six or more there is no wait. So the wait only pads; a
  busy turn is not made up for.
- **The clock** (`RUN_CLOCK`, $AD66) runs once a turn after the wait, and at
  zero ends the game ([`clock.md`](clock.md)).
- **The first turn in a room** (`NEW_ROOM`, set by `ENTER_ROOM`): after the
  wait, the panel's scroll-work and icons (`DISPLAY_PANEL`), the room's ink
  over the screen and the panel's own colours and numbers (`COLOUR_PANEL`,
  [`menu-and-panel.md`](menu-and-panel.md)), the whole buffer to the screen
  (`SHOW_BUFFER`), and bit 5 cleared in all 56 records (`CLEAR_WIPE_FLAGS`
  $A7DC) since nothing drawn so far needs wiping.
- **A death.** When his sparkle has run out, both of his records have
  graphic 0 and the loop goes to `MAIN_NEW_LIFE` instead of the next turn
  ([`lives-and-starting.md`](lives-and-starting.md)).
- **The pause** is checked once a turn ([`input.md`](input.md)).
- **The scene after a game** runs in this same loop with `GAME_OVER` set:
  no wait, no clock, no controls; only its first turn copies the whole
  buffer ([`scenes.md`](scenes.md)).

## How this was found

Read against Knight Lore's `START`, `main`, `onscreen_loop` and
`end_of_frame` (`matches.txt`: 0.94 for `START`) and Pentagram's `START`
and `OBJECT_DONE` (stage 2, range 1). Every reference to every variable in
$5B00-$5C07 was listed from the skool file; the ones with no reader were
searched for in the loaded block as little-endian words (only a
coincidence in the scene data at $B847).

## Confidence

*Read* throughout. The order of a turn and the restart path run in every one
of the build's sessions (*measured* in the sense that they ran); nothing
was timed live.

## Knight Lore and Pentagram

The same shape as both ([`../knightlore/main-loop.md`](../knightlore/main-loop.md),
[`../pentagram/main-loop.md`](../pentagram/main-loop.md)). Alien 8 keeps
Knight Lore's per-object stack reset (Pentagram dropped it), has no
per-object phase counter, and a shorter wait unit (768 turns against 1280).
Like Pentagram it stirs `RANDOM` once per object and counts wiped areas in
`DRAW_WORK`. The clock replaces Knight Lore's sun and moon; the whole-screen
redraw of a new room happens after the wait.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `MAIN_NEW_GAME`, `MAIN_NEW_LIFE`, `MAIN_NEW_ROOM`, `MAIN_NEXT_TURN`, `MAIN_NEXT_OBJECT`, `MAIN_DISPATCH`, `JUMP_THROUGH_TABLE`, `MAIN_END_OF_TURN` | (entry points) | $A650, $A688, $A68B, $A68E, $A692, $A6B1, $A6B7, $A6DC | the loops' labels |
| `NO_UPDATE` | `SUBA8F0` | $A8F0 | graphics 0, 1, 4-10, 84: a RET |
| `CLEAR_WIPE_FLAGS` | `SUBA7DC` | $A7DC | bit 5 of +$07 off in all 56 records |
| `R_CHECK_LEFTOVER` | `SUBA8F1` | $A8F1 | returns at once ([`leftovers.md`](leftovers.md)) |

## Open questions

- Nothing timed: how long a turn really takes in a quiet room and a busy one
  wants a live run (break at `MAIN_END_OF_TURN` and read the T-state count).
