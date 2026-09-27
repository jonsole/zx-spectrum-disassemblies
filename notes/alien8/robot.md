# The robot: turning, walking, jumping

**Question this answers:** how the robot turns, walks, jumps and falls, how
his two records make one robot, and why he stands still for three turns at
every turn.

**Short answer:** Knight Lore's player movement -- a step of 3 a turn the
way he faces, a jump of 8 a turn with gravity taking 2 (1 while jump is held
on the way up), four facings from two bits -- with one thing of its own: a
quarter turn goes through an in-between view (graphics 24-27) held for two
turns. A slip in the routine that ends the turn loses the step that turn was
meant to take, so a walking robot stands still for three turns at every
quarter turn, not two. His legs are his collision box, 23 high while he
moves; the top copies the legs every turn and sits 12 above them.

## How it works

Each turn the legs' update routine runs -- `PLAYER_LEGS` ($C0BE) for
graphics 16-23, `TURNING_LEGS` ($C1E2) for 24-27 -- and then, as record 1,
the top's, `TOP_FOLLOWS_LEGS` ($C6E4).

```
PLAYER_LEGS $C0BE           nudge -16, -7 (DRAW_AT_L16_D7)
  killed (+$0D bit 6)?      the top killed too; the legs to the sparkle (START_SPARKLE $B39A)
  legs 23 high, top 0
  READ_CONTROLS $C8FF       C = the controls ([input.md])
  TAKE_OR_LEAVE $BD6B       pick up or put down ([picking-up.md])
  HANDLE_LEFT_RIGHT $C13C   turn
  HANDLE_JUMP $C23D         start a jump
  HANDLE_FORWARD $C25E      step the legs' frame
  in a doorway (CHK_PLYR_OOB $C117 no carry): a rising Z step zeroed -- fall, not rise
  PLAYER_LEGS_MOVE $C0EA    the top out of the tests; MOVE_PLAYER $C296; the top back;
                            the walk-in count (bits 4-7 of +$0C) down one
  PLAYER_LEGS_DONE $C0FF    heights back to 12 and 11; SET_WIPE_AND_DRAW_FLAGS
```

- **The legs' graphics.** 16-23 are two views (bit 2 of the graphic) of four
  step frames (bits 0-1): a stride, legs together, the other stride,
  together again; frames 1 and 3 share a drawing (*read*, `GRAPHICS`).
  `GET_SPRITE_DIR` ($C319) makes the facing mirror x 2 + bit 2, and by the
  steps in `WALK_STEP_TBL` ($C32F) facing 0 is lower U, 1 higher U, 2 higher
  V, 3 lower V (*read*). The top is the legs' graphic + 16 (32-39, and 40-43
  for the in-between views).
- **Turning** (`HANDLE_LEFT_RIGHT`, $C13C). Rotational steering (the
  keyboard, or a joystick without directional control, `ROTATIONAL_TURN`
  $C18F): bit 0 of the controls turns left, bit 1 right, but not during the
  walk into a room nor a jump. Directional steering (a joystick with bit 3
  of `CONTROL`): up faces 2, right 1, down 3, left 0; already facing that
  way, walk (`FACING_THAT_WAY` $C18C); otherwise turn the short way
  (`TURN_BY_PARITY` $C172); nothing pushed, no walk -- only when standing
  and not walking in. A turn (`START_TURN_LEFT` $C1A2, `START_TURN_RIGHT`
  $C1AB, `START_TURN` $C1B2) puts bit 0 of +$0D for its direction (1 right)
  and a count of 1 in bits 1-2, and the in-between graphic and mirror bit
  from `TURN_RIGHT_VIEWS` ($C1D2) or `TURN_LEFT_VIEWS` ($C1DA) by the facing
  (`SET_TURN_GRAPHIC` $C1BD).
- **The in-between views.** A right turn goes 0, 2, 1, 3, 0 -- lower U,
  higher V, higher U, lower V -- which on the screen is clockwise (the
  projection puts +U down-right and +V up-right); left the other way. 24 is
  between facings 0 and 2, the two away from the viewer (so seen from
  behind); 25 between 1 and 3, towards him (from the front); 26 between 2
  and 1, side-on facing right; 27, the same drawing mirrored, between 3 and
  0. Each serves both directions (*read* from the tables and the
  projection; which of 24 and 25 is front and which back is *inferred* from
  the geometry -- their drawings are symmetric).
- **Ending a turn** (`TURNING_LEGS`, $C1E2). The first turn it counts the
  count down and only falls (`APPLY_GRAVITY` $C2BC). The next it gives the
  standing graphic of the new facing (17 or 21 and a mirror bit) from
  `TURN_RIGHT_ENDS` ($C22D) or `TURN_LEFT_ENDS` ($C235) by the in-between
  graphic's low two bits, plays the turn's sound (`FOOTSTEP_NOW` $B6D4), and
  calls `MOVE_IF_WALKING` ($C2B3) to step if walk is held.
- **The turn bug** (*read* and *measured*). `FOOTSTEP_NOW` is called without
  keeping BC, and the sound's loop leaves C at zero -- C, which holds this
  turn's controls. So `MOVE_IF_WALKING` never sees walk held and the step
  meant for the end of a turn never happens; gravity also ignores a held
  jump that turn. `HANDLE_FORWARD` keeps BC round the same sound. A quarter
  turn while walking therefore costs three turns without a step: the turn it
  starts (no step with an in-between graphic), the count's turn, and the
  last turn, whose step is lost.
- **Stepping** (`HANDLE_FORWARD`, $C25E): the legs go through their four
  frames while he walks, jumps or walks into a room, with a footstep
  (`FOOTSTEP` $B6CE) on leaving a stride (frames 0 and 2); otherwise they go
  on silently to frame 1 and stop. Nothing on the turn a turn starts.
- **Jumping** (`HANDLE_JUMP`, $C23D): jump held, the walk into a room over,
  not already jumping (bit 3 of +$0C), and not falling -- a Z step of -2 or
  less. The jump starts at 8 up a turn.
- **Moving** (`MOVE_PLAYER`, $C296): a forward step of 3 in the facing, plus
  the doorway nudge in +$0E/+$0F, from `CALC_PLYR_DUV` ($C2F6) through
  `DISPATCH_ON_FACING` and `STEP_U_DOWN`, `STEP_U_UP`, `STEP_V_UP`,
  `STEP_V_DOWN` ($C337-$C350) -- while jumping, walking into a room or
  holding walk, and not with an in-between graphic. Gravity: 2 off the Z
  step, 1 if rising or level with jump held. The Z step goes to `PLAYER_DZ`
  ($5B21); a fall faster than 2 plays Knight Lore's falling sound
  (`BEEP_BY_Z` $B63C); `ADJ_FOR_OUT_OF_BOUNDS` ($C442) cuts the move
  ([`collision.md`](collision.md)); `HANDLE_EXIT_SCREEN` ($C36D) may leave
  the room ([`doorways-and-rooms.md`](doorways-and-rooms.md)); the steps are
  added; a move stopped going down ends the jump. `CLEAR_DUV` ($C2EE) zeroes
  the U and V steps; the Z step carries over as speed.
- **One box for the robot.** While the legs move, both legs routines make
  the legs 23 high and the top 0 high, and set bit 1 of the top's flags so
  the scans pass over it; after the move, 12 and 11. The top copies +$01 to
  +$07 from the legs, takes a height of 11, Z + 12 and the legs' graphic +
  16, and marks what it overlaps for redrawing. So between moves the top is
  a box of its own that things can land on. The top's height of 0 during
  the legs' update also keeps the pick-up's headroom test from finding the
  top itself ([`picking-up.md`](picking-up.md)). Either record killed kills
  the other, and both turn into the death sparkle.
- **Inside the walls** (`CHK_PLYR_OOB` $C117): |U - 128| < `ROOM_HALF_U`
  less his half-size, and the same in V; no carry means he is in a doorway.

## How this was found

Read against `matches.txt`'s pairs: Knight Lore's `handle_jump` 1.00,
`upd_120_to_126` 1.00, `move_player_apply` 0.55; Pentagram's
`CHK_PLYR_OOB` 1.00, `CALC_PLYR_DUV` 1.00, `GET_SPRITE_DIR` 0.90,
`MOVE_PLAYER` 0.85, `HANDLE_JUMP` 0.84, `PLAYER_LEGS` 0.79,
`HANDLE_FORWARD` 0.78, `HANDLE_LEFT_RIGHT` 0.75 (stage 2, ranges 3 and 4).
The turning tables decoded by hand and checked against the projection;
sprites 16, 17, 20 and 24-26 rendered from their bytes.

*Measured*, in the simulator from the start room $4E with the keyboard,
running to `MAIN_END_OF_TURN` ($A6DC) each turn and reading the legs'
graphic, mirror bit and +$0D and the top's graphic:

- Z (turn left) held from graphic 21 (facing 1): 26, 26, 17 mirrored, 24,
  24, 17, 27m, 27m, 21m, 25, 25, 21; +$0D 2 then 0 on each in-between pair.
  X (right): 25, 25, 21m, 27m, 27m, 17, 24, 24, 17m, 26, 26, 21; +$0D 3
  then 1. The top's graphic was the legs' + 16 throughout (range 3).
- X and walk held from facing 2: 26 for two turns, then 21 (facing 1) with U
  unchanged, and U grew by 3 a turn only from the turn after that (range 4).
- A valve put above him came to rest at Z 87: the top of a 23-high robot on
  the floor at 64 (range 4).

## Confidence

The routines *read*; the turn's length, the lost step and the top as a
landing place *measured*. Which in-between view is front and which back:
*inferred*. The directional paths ran in the build's Kempston sessions.

## Knight Lore and Pentagram

The jump test on the speed, the falling sound, gravity and the exit check
inside the move are Knight Lore's (Pentagram dropped the last two; its jump
tests bit 2 of +$0C). The facing code is Knight Lore's with graphic bit 2
for its bit 3; Pentagram inverts the mirror bit. New here: the in-between
views and their count -- Knight Lore and Pentagram turn a quarter at once
and hold two turns before the next -- a four-frame walk with frame 1
standing (Knight Lore six frames, Pentagram four with frame 2), and the top
kept out of the scans only during the legs' move (Pentagram's body is out
for good; Knight Lore's head as here). Pentagram's legs set the body's
graphic; here the top follows by itself. The order differs from both:
pick-up before the turn. [`../knightlore/player.md`](../knightlore/player.md),
[`../pentagram/player.md`](../pentagram/player.md)

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `PLAYER_LEGS` | `SUBC0BE` | $C0BE | graphics 16-23 (`PLAYER_LEGS_MOVE`, `PLAYER_LEGS_DONE`, `PLAYER_LEGS_IN_DOORWAY`) |
| `CHK_PLYR_OOB` | `SUBC117` | $C117 | inside the walls |
| `HANDLE_LEFT_RIGHT` | `SUBC13C` | $C13C | turning, both ways of steering (`DIRECTIONAL_*`, `TURN_BY_PARITY`, `FACING_THAT_WAY`, `ROTATIONAL_TURN`, `START_TURN_*`, `SET_TURN_GRAPHIC`) |
| `TURN_RIGHT_VIEWS`, `TURN_LEFT_VIEWS` | `PAIRS_C1D2`, `PAIRS_C1DA` | $C1D2, $C1DA | the in-between view by facing |
| `TURNING_LEGS` | `SUBC1E2` | $C1E2 | graphics 24-27 |
| `TURN_RIGHT_ENDS`, `TURN_LEFT_ENDS` | `PAIRS_C22D`, `PAIRS_C235` | $C22D, $C235 | the facing a turn ends in |
| `HANDLE_JUMP`, `HANDLE_FORWARD` | `SUBC23D`, `SUBC25E` | $C23D, $C25E | start a jump; step the legs |
| `MOVE_PLAYER` | `SUBC296` | $C296 | the move (`MOVE_IF_WALKING`, `APPLY_GRAVITY`, `CLEAR_DUV`) |
| `CALC_PLYR_DUV`, `GET_SPRITE_DIR`, `WALK_STEP_TBL` | `SUBC2F6`, `SUBC319`, `DATAC32F` | $C2F6-$C32F | a step in the facing (`DISPATCH_ON_FACING`) |
| `STEP_U_DOWN`, `STEP_U_UP`, `STEP_V_UP`, `STEP_V_DOWN` | `SUBC337` ... `SUBC350` | $C337-$C350 | the four steps (`STORE_PLYR_DU`, `STORE_PLYR_DV`) |
| `TOP_FOLLOWS_LEGS` | `SUBC6E4` | $C6E4 | graphics 32-43 |

## Disassembly corrections

- The comment on `LEGS` in `scripts/build_alien8.py` was corrected at the
  stage 2 merge: graphics 16-23 are two views of four step frames, the four
  facings from bit 2 and the mirror bit.
- Range 4's draft left `TAKE_OR_LEAVE` out of the legs' order; range 3's and
  the code put it after the controls and before the turn.
- Range 4 read `MOVE_PLAYER`'s first lines ($C296-$C29C: while `GAME_OVER`
  is set, a Z step of 2 each turn so he hangs still) as live, Knight Lore's
  cauldron trick. It never ran in the build's sessions
  (`alien8-coverage.txt`), and cannot in play: the records are cleared
  before `GAME_OVER` is set, and the scenes' pieces do not use the legs'
  routine (*inferred*; [`leftovers.md`](leftovers.md)).

## Open questions

- Whether the killed bit set on the legs while they turn is acted on:
  `TURNING_LEGS` does not test it, `PLAYER_LEGS` does once the turn is over.
  Stage 1 found that setting the killed bit by hand does not kill him --
  something clears it before the legs' routine sees it -- and did not find
  what ([`driving.md`](driving.md)).
- The saved start records (copied mid-move at a doorway) hold that turn's U
  and V steps; what a new life does with them was not checked.
