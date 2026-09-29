# Driving Fairlight

**Question this answers:** how to run the game where it can be watched --
in SkoolKit's simulator, the way the build does -- and how to stage what
play takes too long to reach.

**Short answer:** load the snapshot the build makes
(`game_disassembly/fairlight/fairlight.z80`, PC $C47C, before the game has
run) with all its registers, hold keys through a tracer, and wait on the
game's own addresses and variables, never on time. Stop at **`START_PASS`,
$FF21** (once a pass of the main loop) to poke. The build's sessions reach a
room by writing it to **`ROOM`, $FFB4**, setting SP to **$639A** and
carrying on at **`TELE`, $F09B** -- a shortcut that skips EEN, which the
game's own ways out of a room run. Interrupts are off for the whole game.
Nothing has been driven in a live emulator yet.

## The simulator

`Machine` in `scripts/build_fairlight.py`: SkoolKit's C simulator over the
snapshot with the 48K ROM below it and the registers as the loader left
them (the game sets SP and IY itself), and a tracer whose `read_port`
reports held keys and a Kempston stick on port $1F. The simulator is asked
for interrupts, but none is ever taken: `START` turns them off at $C487
([`start-up.md`](start-up.md)). (The comments in `Machine` still say the
game runs with the ROM's interrupt routine on; reported.)

A session's steps are `(keys, seconds[, stick])`; a function of memory (a
poke); `Until(what, test, seconds, keys, during=, required=)`;
`Repeat(what, steps, test, times)`; `At(what, address)` (run until PC
reaches it, keys released); `Jump(what, address, stack)` (carry on at an
address with SP set); and `Then(what, make)` (steps made from memory when
reached). After every run the machine notes the sprite each object record
in use shows (`note_sprites`), which is how the build knows which sprites
there are. The C simulator runs the game twenty to forty times faster than
a Spectrum.

## Addresses

| Address | Label | What |
|---|---|---|
| $C47C | `START` | The snapshot's PC: the game's first instruction |
| $C000 | `LOADING_TUNE` | The loading tune; any key ends it |
| $F065 | `TITLE_SCREEN` | The title page, then a key |
| $F0D8 | `PAUS` | The wait for a key: under the title, after GAME OVER and after the end of the quest. A stop here means "waiting" |
| $F089 | `NEW_GAME` | After the title's key: the master tables back |
| $F09B | `TELE` | A new game's entry into its room: the knight's record reset from the master copy (all but +14), then `ROOMST` |
| $FD20 | `ROOMST` | Enter the room in `ROOM`; room 81 is the end of the quest |
| $FDEF | (in `ROOMST`) | Just after the room is drawn (stage 2 stopped here to compare pictures) |
| $E5A6 | `RUN_ROOM_COMMANDS` | The fetch of each room command |
| $ED44 | (end of `REDRAW_OBJECT`) | The four compositing pages filled, before the compositor |
| $FF21 | `START_PASS` | Once a pass of the main loop -- the place to poke |
| $F0AF | (in `TITLE_SCREEN`) | `ROOMST` has returned: the game is over |
| $FFB4 | `ROOM` | The room |
| $FF95, $FF96 | `LIFE_TENS`, `LIFE_UNITS` | LIFE; both 0 and the main loop returns: game over |
| $FF97 | `GAME_FLAGS` | Bit 7: the creatures frozen |
| $FF98-$FF9D | `STRIKES_LEFT` | Strikes left for six fighters (4 on entry) |
| $FF9E | `SELECTED` | The place in use ($9F, $A1 ... $A7) |
| $FF9F-$FFA8 | `CARRIED` | The five carried things' records |
| $FF80 | `OBJECT_COUNT` | Object records in use |
| $BC90 | `KNIGHT` | His record: +6 x, +7 top, +8 z |
| $A924 | `OBJECTS` | The object table: a thing's entry is $A91E + 6 x its number, room first |

## Keys

The title page lists them (*read* from its string, and *measured*):

| Keys | Does |
|---|---|
| Y-P, H-ENTER, Q-T, A-G | Walk +x, -x, +z, -z |
| SYMBOL SHIFT, SPACE | Jump (both together: pause until a key) |
| B-M | Fight |
| X-V | Pick up |
| CAPS SHIFT, Z | Drop |
| 1-5 | Choose the place a thing is carried in |
| 6, 7 | Use the chosen thing |
| SYMBOL SHIFT with 0 | Quit: the game over |
| 9 | Kempston joystick on and off (Release 2 only) |

Any key ends the loading tune and passes the title.

## Staging

- **Life**: write 9 to $FF95 and $FF96 before each step (`_alive`): rooms
  are dangerous, and some things kill at a touch.
- **A room**: `_enter(room)` -- at $FF21, write the room to $FFB4, then
  `Jump` to $F09B with SP = $639A (what it is at $F065 and all the way
  there), and wait for $FF21 again. His record is reset from the master
  copy, so he stands where the game starts him, sometimes inside another
  room's furniture.
- **The shortcut skips EEN.** A door, the thing of kind 9 and the end of a
  game all run `SAVE_OBJECT_POSITIONS` ($F906) before the next room; the
  jump to `TELE` does not. Two effects: things moved in the room left are
  not saved into the object table; and a troll's or wraith's frames that
  were turned round stay turned, so the next room's troll or wraith walks
  with its record saying unmirrored and its frames mirrored (*measured*:
  room 5 left mirrored, room 22's creature then wrong). Where the picture
  matters, leave the room by the game's own ways -- a door, or call $F906
  first ([`turning-sprites.md`](turning-sprites.md)).
- **Release 1**: to jump to its TELE ($F0C3), set B to 0 first
  ([`versions.md`](versions.md)).
- **A thing picked up**: the pick-up ($F4F4) searches a box his size four
  units ahead: put the thing's +6 and +8 at his, or up to 10 ahead of his
  corner, its floor (+7 less +10) at his, and press X (`_onto_knight`).
- **A thing used**: choose its place (1-5) and press 6. Kind 4 adds 10 to
  LIFE (at 90 or more it makes 99), so the sessions set LIFE to 59 first.
- **Too heavy**: pick up several things into places 1-5 without dropping
  (`_load_up`); a load of 8 or more is refused.
- **The end of the quest**: enter room 81 -- "failed". To succeed, first
  fetch thing 5 of the object table (it lies in room 33; its record has +19
  = 5) and carry it into room 81 ([`quest.md`](quest.md)).
- **Game over**: write 0 to both LIFE bytes at $FF21.
- **Doors**: put him at a door's +6 and +8 and walk each way
  (`_try_doors`); a door may say LOCKED or take him through.
- **Everything else in a room**: put each record that is neither a door nor
  a thing where he stands (`_touch_others`), and if LIFE runs out, go
  through GAME OVER and the title and back in (`_back_in`).

Stage 2's scenes (scratch scripts, not in the build):

| Scene | Recipe | Reaches |
|---|---|---|
| A winged creature's strike | Room 45: the knight 12 below a state-4 creature's x | $F28B-$F29E; LIFE -3 a pass; frames at $5D14 |
| A guard killed | Room 29: `STRIKES_LEFT` all 1, the guard against his +x side, B and Y held | $F9C7-$FA00: the guard becomes the helmet ($A4B8) |
| A wraith destroyed | Room 28: the kind-6 thing dropped just above the wraith | $FA40 |
| The troll's touch | Room 2: the troll's record put on the knight | LIFE -10; the stale number at $FA0D |
| The freeze and the jump | Room 24: its kind-5 thing picked up and used, SPACE, then Q | Release 2 walks on; Release 1 locks |
| The decoy | Room 20 | A state-9 guard takes the kind-8 thing |
| A far side taken | Thing 1 moved to room 30 at the arrival point of room 29's door | BLOCKED ($F8DD-$F8E9) |
| Room 61 | Write 61 into thing 7's object-table room first | The figure wakes; the hole down works |
| Room 19's bug | Stand 10 short of one of its two things, press X | Record 214's x becomes $FE; room 25's door to room 21 dead |
| The four pages | Stop at $ED44 for the knight's record, near room 2's troll, with the freeze on | Pages $D8-$DB |

## The sessions

`sessions()` in the build: the keyboard (four rounds of every key); the
Kempston joystick (9, then stick rounds); every room 2-80 but the title's
79, with a round of play, every thing picked up, used and dropped, and a
wait; every door of every room; game over and the title again; the end of
the quest failed and succeeded; too heavy in rooms 20, 34 and 49; and every
other object met. About 40 seconds in all. They execute 3476 instructions;
what they never reach is listed in `fairlight-coverage.txt` (see
[`README.md`](README.md) for how to read it).

Things the sessions meet that are worth knowing:

- A death in the room tour goes to GAME OVER, and the keys the next round
  holds pass the title and start a new game; the tour carries on from the
  next `_enter`. Harmless, but it cuts a room's handling short.
- The keys held when the loading tune ends also pass the title if held long
  enough: `_start` presses a key, waits for $F0D8, then presses another.

## Checking the room parser against the game

`fl_roomcheck.py` (scratchpad, stage 1) entered every room in turn and
stopped at `RUN_ROOM_COMMANDS`' fetch ($E5A6) for every command, collecting
IX: 2348 command addresses, every one a command start in
`fairlight_data.room_commands()`'s parse; the 55 parsed commands never
fetched are exactly those of the five parts no room draws (*measured*).

## Live

Not yet. For the emulator: `zx_server` with `roms/48.rom`, the build's
`fairlight.z80` and `fairlight.sld`; break at $FF21 for a pass, $F0D8 for
"waiting for a key".
