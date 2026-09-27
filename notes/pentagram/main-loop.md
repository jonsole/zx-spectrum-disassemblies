# The main loop

**Question this answers:** what runs, in what order, from the moment the game
is loaded -- a game, a life, a room, a turn -- and what sets the speed.

**Short answer:** `START` ($AF87) is three loops, one inside another: a life
(`RESTART`), a room (`GAME_LOOP`) and a turn (`MAIN_LOOP`). A turn runs the
update routine of every one of the 54 object records, found by graphic in
`UPDATES` ($AE2F); then `OBJECT_DONE` ($B00C) draws what changed and burns
six units of time less the turn's drawing work, so a quiet room runs no
faster than one where six things change. It is Knight Lore's loop, less the
per-object stack reset.

## How it works

```
ENTRY $5E00            DI, SP $5E00, JP START
START $AF87            clear $A709-$AE2E (variables and every object record)
AFTER_GAME $AF93       (the game over returns here) clear again from BUCKET_OUT
  CLEAR_SCREEN, FILL_ATTRS, MAKE_TABLES $B29A, LIVES = 5, RANDOM += R
  MENU $BB74           until 0 is pressed
  PLAY_TUNE TUNE_START, NEW_QUEST $D16F, CHOOSE_START $C2CE
RESTART $AFC5          RESTART_PLAYER $C2EC: template over his records, a life taken
GAME_LOOP $AFC8        QUEST_OUT_OF_ROOM $B115, ENTER_ROOM $C6B6, QUEST_INTO_ROOM $B097,
                       BAN_DROPS $CB89, PRINT_SCORE $BB14, RESET_DROP_TIMER $CC31
MAIN_LOOP $AFDA        SKY_DROP $CBAB; IX = OBJECTS
  NEXT_OBJECT $AFE1    push OBJECT_DONE; +$18..+$1B -> +$1C..+$1F;
                       UPDATE_OBJECT $B000 / JUMP_TO_TBL_ENTRY $B003 through UPDATES
  OBJECT_DONE $B00C    RANDOM += R + ...; next record, until all 54
    end of turn:       TURNS + 1, LIST_DRAWN $B531, RENDER_DYNAMIC_OBJECTS $B19E,
                       SP -> MAIN_SP, PAUSE $B4E0, the wait,
                       first turn in a room: the whole screen (below),
                       EFFECT_NOTE $D5F2, both player records empty? -> RESTART
                       else -> MAIN_LOOP
```

- **What survives a game.** `START` clears 1830 bytes from `CONTROL` up to
  the update table; `AFTER_GAME`, where the game over comes back, clears only
  from `BUCKET_OUT` ($A70E). So `CONTROL`, `MENU_PASSES`, the unused byte at
  $A70B, `CONTROL_BEFORE` and `RANDOM` carry over: the menu shows the method
  chosen last time and the next game continues the random sequence (*read*).
  `MAKE_TABLES` runs at every new game, not just the first (*read*).
- **A life.** `RESTART_PLAYER` copies the 64-byte `PLAYER_TEMPLATE` over the
  legs and body and takes a life; with none left it jumps to `GAME_OVER`
  ($C323). It runs at the start of every game too, which is why five lives
  show as 04 ([`lives-and-starting.md`](lives-and-starting.md)).
- **A room.** `GAME_LOOP` files the quest things of the room being left back
  in their records before the builder overwrites them, then builds the room
  and puts in the quest things that are there
  ([`quest-records.md`](quest-records.md)). A doorway (`EXIT_SCREEN`, $C854)
  copies his records to the template and jumps back to `GAME_LOOP`, dropping
  two return addresses by hand ([`doorways-and-rooms.md`](doorways-and-rooms.md)).
- **The dispatch.** A routine is entered with IX on the record, BC on the
  table and `OBJECT_DONE`'s address on the stack, so it ends with RET; it
  animates by changing its own graphic. `JUMP_TO_TBL_ENTRY` (jump through word
  table BC by index L) is shared: `SORT_AND_DRAW` ($B58A), `CALC_PLYR_DUV`
  ($C66A) and `HANDLE_EXIT_SCREEN` ($C802) jump into it with tables of their
  own. Graphic 0, an empty record, goes to `NOTHING` ($C43F), a RET: every
  record is visited every turn, empty or not
  ([`graphic-numbers.md`](graphic-numbers.md)).
- **The random number.** `OBJECT_DONE` adds R, the turn counter's low byte
  plus one, and the ROM byte at that address to `RANDOM` after every object's
  update. R counts instructions, so the numbers depend on how long each update
  took (*read*).
- **The wait.** `DRAW_WORK` ($A714) is zeroed by `SORT_AND_DRAW`, counts one
  per object drawn (`DRAW_CANDIDATE` $B6B3) and gains the number of areas
  `RENDER_DYNAMIC_OBJECTS` wiped. The loop then waits 6 less that many units;
  a unit is 1280 turns of a 26 T-state loop, 33,280 T-states, just under half
  a 50 Hz frame; at 6 or more there is no wait. So the wait only pads: a busy
  turn is not made up for (*read*; the T-states from the instruction timings,
  LD A,L 4, OR H 4, JR NZ 12, DEC HL 6).
- **The first turn in a room** (`NEW_ROOM`, set by `ENTER_ROOM`): the room's
  colour over every attribute (`FILL_ATTRS`), the carried things
  (`SHOW_CARRIED_NOW` $BA3D), the panel's scroll-work (`DISPLAY_PANEL`
  $BCE5), the lives (`DRAW_LIVES` $C29A), the whole buffer to the screen
  (`SHOW_BUFFER` $B178), the score again (`PRINT_SCORE`, since the fill painted
  over its heading's colour), every copy bit cleared (`CLEAR_COPY_BITS`
  $BF0D), and effect 0 started in `SOUND_COUNT` ([`sound.md`](sound.md)).
- **A death.** When his dying puff has finished, both player records have
  graphic 0, and the loop goes to `RESTART` instead of `MAIN_LOOP`
  ([`lives-and-starting.md`](lives-and-starting.md)).
- **The pause.** `PAUSE` is the only place interrupts are enabled; see
  [`input.md`](input.md).

## How this was found

Read from the listing, compared line by line with Knight Lore's `main`,
`player_dies`, `game_loop`, `onscreen_loop`, `update_sprite_loop`,
`jump_to_tbl_entry`, `ret_from_tbl_jp` and `end_of_frame`. Every reference to
every variable in $A709-$A76E was listed from the skool file, and the loaded
block was searched for the raw little-endian address of those with no reader
($A70A, $A70B, $A735, $A73E, $A76E), to rule out a use the disassembly hides
(stage 2, range 1).

## Confidence

*Read* throughout. The order of a turn and the restart path are also
exercised by every one of the build's sessions (*measured* in the sense that
they ran; nothing was timed live).

## Knight Lore

The same shape and the same timing loop ([`../knightlore/main-loop.md`](../knightlore/main-loop.md)).
Differences: Knight Lore reloads SP for every object and keeps its object
table over the system variables; Pentagram keeps one stack and saves SP in
`MAIN_SP` every turn without ever reading it back. Knight Lore's whole-screen
copy clears the buffer as it goes; `SHOW_BUFFER` does not. Knight Lore stirs
its random byte once a frame, Pentagram once per object. Pentagram's
`DRAW_WORK` counts wiped areas as well as objects drawn.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `GAME_LOOP` | (none; entry point) | $AFC8 | Enter a room |
| `JUMP_TO_TBL_ENTRY` | (none; entry point) | $B003 | Jump through word table BC by index L |
| `DRAW_WORK` | `SLOWDOWN` | $A714 | The turn's drawing work; the wait is six less it |
| `WIPE_COUNT` | `UNKNOWN_A710` | $A710 | Areas wiped this turn |

## Disassembly corrections

- `SLOWDOWN` read the wrong way round: the variable holds work done, and the
  wait is six *less* it. Renamed `DRAW_WORK` (stage 2).

## Open questions

- Why `MAIN_SP` is saved every turn and never read: nothing in the code or
  the loaded bytes reads $A73E. Perhaps a leftover of Knight Lore's per-object
  stack reset.
- `MENU_PASSES` ($A70A) is only ever counted up; Knight Lore's menu stirs its
  seed in the same place, but here nothing reads the count.
