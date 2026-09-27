# Driving Pentagram in the simulator

**Question this answers:** how the build plays the game in SkoolKit's
simulator to map its code -- where each session starts, what it waits on,
what it pokes -- so a session can be added or a scene reproduced.

**Short answer:** every session starts from
`game_disassembly/pentagram/pentagram.z80` at $5E00 on a fresh simulator
with the 48K ROM, presses a control key and 0 at the menu, and waits until
the player's legs record ($A76F) has a graphic and the killed bit of $A77C
is clear. Rooms are changed by the game's own restart: the room goes into
$A777 and into the player template at $C407, then bit 6 of $A77C kills
him. Lives are topped up at $A721 before every step.

For the live emulator -- the keys, the original's addresses, recipes for
rooms, the bucket, the ending and game over, and the remake's symbols --
see the emulator repo's `examples/filmation/pentagram/driving.md`, which
predates the disassembly (one slip there: `RANDOM`, $A70D, is a byte, not a
word; `PUFF_SOUND` reads it as a word with `BUCKET_OUT`). What was tried live
is in [Live driving](#live-driving) at the end.

## Key addresses

| Address | Label | For |
|---|---|---|
| $5E00 | `ENTRY` | where the snapshot starts |
| $AFC5, $AFC8, $AFDA | `RESTART`, `GAME_LOOP`, `MAIN_LOOP` | a life, a room, a turn begins |
| $B00C | `OBJECT_DONE` | every update returns here; the end of a turn follows the 54th |
| $BB74 | `MENU` | the menu; keys 1-4 and 0 |
| $C440 | `PLAYER_LEGS` | the player's turn |
| $A76F-$A77C | `OBJECTS` ... `PLAYER_STATE` | the legs: graphic, `PLAYER_U`, `PLAYER_V`, Z, sizes, `PLAYER_FLAGS`, `PLAYER_ROOM` $A777, steps, `PLAYER_BUMPED`, `PLAYER_STATE` (bit 6 kills him) |
| $C3FF, $C407 | `PLAYER_TEMPLATE`, `START_ROOM` | what a life starts from; its room |
| $A721 | `LIVES` | BCD |
| $A715 | `TURNS` | the turn counter, a word |
| $A73D, $A742 | `DROP_TIMER`, `DROP_BAN` | things from the sky |
| $A70E, $A70F | `BUCKET_OUT`, `PENTAGRAM_ON` | the quest's switches |
| $A74B, $A74C | `PLACED`, `QUEST_DONE` | the quest's counts |
| $A722-$A731 | `CARRIED` ... `CARRIED_LAST` | what he carries |
| $D432 | `QUEST_RECORDS` | the 18 quest things, 16 bytes each, room at +8 |
| $A74F | `ROOMS_SEEN` | a bit per room, for the percentage |

The whole map is in [`memory-map.md`](memory-map.md).

## The machine

- `Machine` in `scripts/build_pentagram.py`: `CSimulator` over the snapshot's
  64K with the ROM in, SP $5E00, interrupts off (the game runs with them
  off; only the pause enables them), and a tracer whose `read_port` reports
  the held keys by half-row and a Kempston stick on port $1F.
- A step is `(keys, seconds[, stick])`, a function of memory (a poke), an
  `Until(what, test, seconds)` -- run in 0.05 s slices until `test(memory)`,
  or stop the build naming `what` -- or a `Repeat(what, steps, test, times)`.
- The C simulator runs the game far faster than a Spectrum would: the
  nine sessions, 27 minutes of play (measured by T-states), take about 25
  seconds.

## What the sessions wait on

| Test | Means | Read from |
|---|---|---|
| `_playing` | in a room and alive: $A76F non-zero, bit 6 of $A77C clear | $C2EC copies the template in; bit 6 is set by a killer |
| `_in_room(n)` | the above, and $A777 = n | |
| `_at_menu` | $A76F and the turn counter $A715 both zero | $AF93 clears $A70E-$AE2E after a game |
| `BUCKET_OUT` | $A70E non-zero: the well has put out the bucket | `WELL` $CFD2 |
| carried | $A72E = 90: the bucket is in the last of the four slots at $A722, next to be put down | `TAKE_OR_LEAVE` $BF79 |
| `QUEST_DONE` | $A74C counts the quest items done | `QUEST_ITEM` $CF68 |
| `PENTAGRAM_ON` | $A70F set: all four done | `ALL_FOUR_DONE` $D13A |
| `PLACED` | $A74B counts collectables in their places; the fifth wins | `COLLECTABLE` $CD16 |

## The sessions

| Session | What it does |
|---|---|
| keyboard | menu 1, then rounds of every keyboard control: walk (A-G, H-ENTER), turn (CAPS-V row, SPACE-B row, SYMBOL SHIFT), jump (Q E T U O), fire (W R Y I P), pick up (1-0), and a pause (SPACE alone, twice) |
| Kempston joystick | menu 2; up walks, left and right turn, down jumps, fire fires, bottom-row keys pick up |
| cursor joystick | menu 3; 5 left, 8 right, 7 walk, 6 jump, 0 fire |
| Interface II | menu 4; 6-0 and 1-5 |
| every room | all 139 rooms in directory order, by restart, a few seconds of walking in each |
| game over | $A721 = 0 and the killed bit: the game-over screen, the menu again, a new game |
| things from the sky | room 30 (empty, nothing bans a drop), $A73D = 1 repeatedly, firing |
| the quest and the ending | below |
| directional joystick | menu 2, then bit 3 of $A709 set: the joystick turns him to face the way pushed (`HANDLE_LEFT_RIGHT` $C4C8) |

## The quest, staged

For each quest item in turn (rooms 122, 128, 17, 33, where the records at
$D312 put them):

1. Restart into room 71: a well with no monsters, inside a ring of still
   hazards. Stand him at U 120, V 148, inside the ring.
2. Fire twelve times (W, 0.15 s held, 0.25 s released: fire is taken once a
   press), turn a quarter (Z), and again, until $A70E is set. In the run the
   sessions were worked out from, the bucket came after the fourth volley.
3. Wait two seconds (the bucket falls), stand him 14 units short of it in V,
   and press 1 until $A72E is 90 (three presses: the first picks it up into
   the second slot, each further press moves it one slot on).
4. Restart into the quest item's room and press 1 until $A72E is clear: the
   bucket is put down, rises, flies to the item, and the item's graphic goes
   up by 4 (*measured*: 112 to 116 in room 122, with a life added).

Then, with all four done and $A70F set: restart into room 82 (the pieces of
the pentagram are there), move quest records 4-8 (the collectables, $D472)
into room 82 at +8, each 16 units from its place in the table at $D562
towards the middle of the room, restart into room 82 again, and wait for
$A74B to reach 5. The game runs the win, the game-over screen with the
percentage, and returns to the menu (*measured*).

## Pitfalls

- A restart costs a life, and the rooms kill quickly: the build pokes five
  lives back before every step. Without that the "every room" session ran
  out of lives by room 2 and sat in the game-over tune.
- `_playing` is true during the game-over tune (the player's graphic is
  still there); check lives first if a session stalls.
- The screen is drawn from the buffer at $D88F; a screenshot straight after
  a restart can show the last room.
- The simulator is deterministic: the same steps give the same game. A
  change to an earlier step (even a longer wait) changes the random numbers
  for everything after it, which is why every step that matters waits on
  the game's state rather than on time. `RANDOM` is stirred with R after
  every object's update, so even a change in how long an update takes
  changes the sequence.
- Sprites are turned in place: a snapshot taken after play has some of them
  mirrored or upside down in memory. Take pictures of sprites from
  `pentagram.z80` (before the first instruction), or draw them through the
  game's own `FIND_SPRITE`.

## Staged scenes (stage 2)

Recipes the describing agents used to settle questions, each a scratch
script on the build's `Machine` (in the stage 2 scratchpad, not committed).
Restart into a room as above, then:

| To see | Do | Expect (as measured) |
|---|---|---|
| a quest thing lifted onto what it was left on | poke quest record 0 (graphic 112, $D432) into room 100 at U 184, V 152, Z 128, where a hazard stands; restart into 100 | it comes in at record 6 ($A82F) with Z 140 and +$10 = $D432; poke its V to 150, restart into 51, and record 0 reads back U 184, V 150, Z 140, room 100 |
| a bolt's flight | keyboard, room 100, W for 0.03 s; log record $A7AF each turn | graphic 150, 149, 151, 150...; U 112 then 8 less a turn; Z 132; at U 70 it bumps the wall and puffs, 64 to 71, then 1, 0 |
| the lift | room 2; stand him above graphic 84 | it rises one a turn with him 12 above, to 176; he falls, pushing it down; at the floor it starts again |
| the crumbling block | room 4; stand him on it | 136, 137, 138, 139, gone, a turn each |
| the sinking block | room 15 | down one a turn from Z 152 while he stands on it |
| the bobbing head | room 11 (graphic 86) | up one a turn to 176, back down one a turn, repeating |
| conveyors | room 37; stand him on graphic 140, then 142 | +2 U every other turn; +2 V |
| the conveyor push alone | after `MAKE_TABLES`, a legs record (graphic 32) falling with dZ -2 onto a record of graphic 140-143; call `ADJ_FOR_OUT_OF_BOUNDS` on an odd and an even `TURNS`, then with the block's bit 3 of +$0D set | +2 U, -2 U, +2 V, -2 V on odd turns only; nothing with bit 3 set |
| the drop timer | copy `QUEST_START` over `QUEST_RECORDS`, add 4 to the graphics of the items to count as done, call `RESET_DROP_TIMER` | `DROP_TIMER` 80 unless record 0 is done, then 8 |
| the percentage | set bits in `ROOMS_SEEN`, set `QUEST_DONE` and `PLACED`, call `PERCENTAGE` | 0/0/0 and 1/0/0 give 56; 108/4/5 gives 100; 107/4/5 gives 99 |
| turning | set the legs' facing (mirror bit, graphic bit 2), `INPUT` bit 0 or 1, call `HANDLE_LEFT_RIGHT` | left 0, 3, 1, 2; right the reverse; with bit 3 of `CONTROL` and a joystick method, the stick's directions |
| arriving | put a marker (U or V 0 or $FF) in the legs, call `ENTER_ROOM` for a start room | U or V 195 or 61, the other 128, Z 128, the body at Z 140 |
| leaving | room 51: legs at U 198, V 128, Z 128, graphic 36 mirrored (facing 1); run the pillar at U 197, V 115 | `PLAYER_ROOM` 52, U $FF, +$0C $30, `PLAYER_TEMPLATE` the same |
| drawing a sprite | after `MAKE_TABLES`, `DRAW_SPRITE` on graphic 32 at pixel x 100 or 96, y 50 or 185 | JR offset 32 or -30, row step 29 or 30, +$18 4 or 3; at y 185 the height cut to 7 |
| the depth order | two overlapping records in the list; `SORT_AND_DRAW` with `DRAW_OBJECT`'s call patched to log IX | smaller U, larger V or the lower base drawn first |

Worth adding to the build's sessions: standing on graphic 140 in room 37
would run `CONVEYOR_PUSH`, which no session reaches (`pentagram-coverage.txt`).

## Live driving

*Watched* (2026-09-27, the pokes agent: a private `zx_server` on ports
14711/18000/18500 with `--no-audio`, loaded with `pentagram.z80`, driven turn
by turn over MCP; killed by PID afterwards).

**Breakpoints.** `MAIN_LOOP` $AFDA stops once a turn (confirmed over thousands
of stops); `GAME_LOOP` $AFC8 on each room entry; `RESTART` $AFC5 on each life;
`GAME_OVER` $C323; $AF93 (`AFTER_GAME`) with the game-over screen still up;
$BB94 on each menu pass, after the tune; $AFB9 when the menu has returned.

**Starting a game.** Load `pentagram.z80`, run to $BB94; hold 1, step, run to
$BB94 again, release; hold 0, run to $AFB9, release; run to $AFDA. The first
game after loading is always room 92, with the collectables in rooms 16, 129,
18, 146 and 27 (a 128K snapshot, with R = 0, started in room 100).

**Changing room.** Write the room to $A777 and $C407, set bit 6 of $A77C, run
to $AFC8 and then $AFDA. It costs a life, and does not work with the immunity
poke in -- apply that afterwards.

**Timing.** About 170k T-states (2.4 frames) a turn standing in room 92; draw
work is 9 units a turn there, 4 in room 30.

**Keys.** Fire is W held for one turn, then released for at least one (the
fire latch). Z held for one turn is a quarter turn.

**Logpoints.** `get_log` returns oldest first, paged: find the end by paging
with `since` before a trial. Holes like `{(IX+20):d}` and `{(0xA715):w}` work.

**Staging.**
- A repeatable death: stand at the middle of room 6; he dies every 16 turns.
- The well: room 71, player at U 120, V 148, clear bit 6 of $A776 to face it.
- Drops: room 30; the drop timer is 80 on arrival.
- A bucket in a room: write quest record 17 at $D542 as graphic 90, U, V, Z,
  8, 8, 12, $14, room, then enter the room. To carry it instead: $A72E =
  5A 14 42 D5 and $A70E = 1.
- Collectables into a room: set U, V, Z and the room (+8) of $D472 + 16k.
- 128K: build a v3 `.z80` from `pentagram.z80` with $7FFD = $10 (SkoolKit's
  `Z80` class) and `load_rom` the 128 ROM first. After a locked-paging crash
  restart the server: loading a 128K `.z80` while the paging is locked keeps
  the lock (an emulator bug, reported to the lead).
