# The player: turning, walking, jumping, the body

**Question this answers:** what the player's update routine does each turn --
how he turns, walks, jumps and falls, and how his body follows his legs.

**Short answer:** `PLAYER_LEGS` ($C440) reads the controls, turns
(`HANDLE_LEFT_RIGHT`), steps the legs (`HANDLE_FORWARD`), starts a jump
(`HANDLE_JUMP`), picks up or puts down, moves (`MOVE_PLAYER`) and fires. He
faces one of four ways, walks 3 units a turn, jumps at 8 a turn upwards, and
gravity takes 2 a turn (1 while rising with jump held). The body
(`PLAYER_TOP`) copies the legs every turn. It is Knight Lore's code with the
turning and falling sounds, the head's random frames and the exit check taken
out.

## How it works

```
PLAYER_LEGS $C440                 nudge (-12, -6); killed? -> body killed, legs a puff
  READ_CONTROLS $BDF8 -> C        (input.md)
  HANDLE_LEFT_RIGHT $C4C8         turn (or, directional, turn and walk)
  HANDLE_FORWARD    $C58D         next leg frame, footstep
  HANDLE_JUMP       $C56C         start a jump
  TAKE_OR_LEAVE     $BF79         (carrying.md)
  LEGS_IN_DOORWAY $C495           outside the walls (CHK_PLYR_OOB $C4A3): may fall, not rise
  LEGS_MOVE $C46B                 body out of collisions; Z capped at 240
  MOVE_PLAYER       $C61D
    CALC_PLYR_DUV $C66A -> WALK_STEP_TBL $C68D -> STEP_U_DOWN / STEP_U_UP / STEP_V_UP / STEP_V_DOWN
    gravity; Z_STEP
    ADJ_FOR_OUT_OF_BOUNDS $B6ED   cut the move (collision.md)
    EXIT_STUB $C6B5               a RET where Knight Lore checks for leaving the room
    ADD_DUVZ $B97F                make the move; a stopped move down ends the jump
  FIRE $C126                      (bolts-and-sky.md)
  clear bit 0 of +$07; +$0C's top nibble - 1; redraw
```

**Facing** (`GET_SPRITE_DIR` $C5BD): 2 if the mirror bit (6 of +$07) is
clear, plus bit 2 of the graphic. The steps (`WALK_STEP_TBL`, through
`DISPATCH_ON_FACING` $C686):

| Facing | Step | On screen |
|---|---|---|
| 0 | U - 3 | up and left |
| 1 | U + 3 | down and right |
| 2 | V + 3 | up and right |
| 3 | V - 3 | down and left |

The screen directions follow from the projection (x grows with U + V, y
upwards with V - U and Z) (*read*, not seen). Facings 0 and 2 have graphic bit
2 clear; they are called the back view from the geometry only.

**Turning, rotational** -- the keyboard's, and every joystick's as the menu
leaves them: bit 0 of the controls turns left, 0, 3, 1, 2, 0; bit 1 right, the
reverse (*measured*, every facing both ways). A quarter turn always toggles
the mirror bit and, for a left turn from a mirrored sprite or a right turn from
an unmirrored one, bit 2 of the graphic too. After a turn a pause of 2 goes
into bits 0-2 of the legs' +$0D, so a held key turns on every third turn.
Nothing turns during the walk into a room (+$0C bits 4-7) or in a jump (+$0C
bit 3). The body's graphic is set at once, so both halves turn together.

**Turning, directional** -- only with a joystick method and bit 3 of
`CONTROL`, which no menu choice sets. Up faces 2, right 1, down 3, left 0,
turning the short way (two turns for an about-face) and walking once he faces
that way (*measured*: every facing and direction). Two quirks: up is the walk
bit, so pushing up walks during the turn too; and down is tested as bit 4,
which `READ_CONTROLS` sets only from the pick-up keys -- every joystick maps
its down to jump, bit 3 -- so a stick alone can never face 3 (*read*, all
three joystick branches). The code is Knight Lore's, where bit 4 was the
stick's down ([`input.md`](input.md)).

**Jumping** (`HANDLE_JUMP`): jump held, the walk into a room over, not already
jumping, and standing on something (bit 2 of +$0C: a move down was stopped).
Sets bit 3 of +$0C and a Z step of 8, and plays `JUMP_SOUND` ($D5E4).

**The legs** (`HANDLE_FORWARD`): four frames in the graphic's low two bits;
frame 2 is standing. Walking, jumping or walking into a room: step on.
Otherwise step on until frame 2. Each step calls `FOOTSTEP` ($D635), which
beeps on every fourth call, the pitch alternating ([`sound.md`](sound.md)).

**Moving** (`MOVE_PLAYER`): a step forward (plus an arch's nudge from +$0E,
+$0F) when walk is held, and also during a jump or the walk into a room.
Gravity: the Z step less 2, or less 1 if it is 0 or more and jump is held.
The Z step goes into `Z_STEP` ($A739) before the collision code cuts it, so
that afterwards "stopped while going down" can be told apart: that is a
landing, and clears bit 3 of +$0C. The U and V steps are cleared after the
move; the Z step carries over as his vertical speed. Only record 0 moves:
the body is kept out of the collision tests while the legs move (*read*).

**The body** (`PLAYER_TOP` $C5D3): copies +$01 to +$07 from the legs, takes a
height of 0 and bit 1 of +$07 (out of the collision tests -- the legs' box,
half-sizes 5, 5 and 23, is the whole man), graphic = legs + 8, Z = legs + 12
from behind (facings 0 and 2) or + 8 from the front, and a nudge of (-12, -8).
A count in bits 0-3 of the body's +$0D would hold its graphic for that many
turns, but nothing sets it and it never ran. A body marked killed becomes a
puff (*read*).

## How this was found

Read against Knight Lore's `handle_left_right`, `handle_jump`,
`handle_forward`, `move_player`, `calc_plyr_dXY`, `get_sprite_dir` and
`upd_player_top`, line by line (stage 2, range 4). `HANDLE_LEFT_RIGHT` was run
in SkoolKit's simulator from every facing with each turn bit, and in
directional mode with each direction.

## Confidence

The turning tables and the directional mapping: *measured*. Everything else
*read*; the screen directions of the facings are *read* from the projection,
not seen.

## Knight Lore

([`../knightlore/player.md`](../knightlore/player.md))

- Facing uses bit 2 of the graphic, not bit 3 of the type.
- A four-frame walk with one standing pose (frame 2); Knight Lore has six
  frames and two standing poses and carries on to them silently -- Pentagram's
  steps to the standing pose count towards a footstep.
- The turning sound is gone, leaving `BIT 2,C / JR NZ` to the very next
  instruction ($C535).
- The falling sound is gone, leaving an `ADD A,$02` ($C646) whose result
  nothing reads.
- The exit check (Knight Lore's CALL at its $CA70) is now a CALL to
  `EXIT_STUB`, a RET: the arch decides ([`doorways-and-rooms.md`](doorways-and-rooms.md)).
- A jump tests "standing" (+$0C bit 2), not the Z step.
- The head's random frames are gone; its hold count remains, with no setter.
- One form only: no man-and-werewolf switch.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `HANDLE_LEFT_RIGHT` | `SUBC4C8` | $C4C8 | turn |
| `HANDLE_JUMP` | `SUBC56C` | $C56C | start a jump |
| `HANDLE_FORWARD` | `SUBC58D` | $C58D | step the legs |
| `GET_SPRITE_DIR` | `SUBC5BD` | $C5BD | facing 0-3 |
| `MOVE_PLAYER` | `SUBC61D` | $C61D | step, gravity, collide, move |
| `CALC_PLYR_DUV` | `SUBC66A` | $C66A | nudge plus 3 the way he faces |
| `DISPATCH_ON_FACING` | (entry point) | $C686 | jump through a 4-entry table by facing |
| `WALK_STEP_TBL` | `DATAC68D` | $C68D | the four steps (now words) |
| `STEP_U_DOWN` ... `STEP_V_DOWN` | `SUBC695` ... `SUBC6AE` | $C695-$C6AE | the four steps |
| `EXIT_STUB` | `SUBC6B5` | $C6B5 | where Knight Lore checks the exit |
| `LEGS_MOVE`, `LEGS_IN_DOORWAY` | (entry points) | $C46B, $C495 | parts of `PLAYER_LEGS` |
| `CHK_PLYR_OOB` | `SUBC4A3` | $C4A3 | inside the room's walls? |

## Open questions

- What the two views of the legs look like: draw graphics 32 and 36 (the
  Sprites page) to confirm which is the back.
