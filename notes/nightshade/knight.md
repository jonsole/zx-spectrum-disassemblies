# The knight

**Question this answers:** how the knight is driven -- how the controls
turn him, walk him and throw, why he is two records, and what his top
does on its own.

**Short answer:** his legs' record (`KNIGHT`, $BC8E) carries the whole of
him: `UPDATE_KNIGHT` ($DA7A) reads the controls, turns, walks and throws.
His top (`KNIGHT_TOP`, $BC9E) copies the legs' place each turn and picks a
matching picture, or strikes a pose of its own. He speeds up halfway to his
top speed each turn, rounded down to even, so he never quite reaches it,
and when the walk control is let go he slows onto an eight-unit grid.

## How it works

```
UPDATE_KNIGHT $DA7A          (legs, graphics 16-21 from behind, 24-29 front)
  ARRIVING < 76? -> SET_KNIGHT_LOOK $DC14, ARRIVE_SOUND $C463, done
  SPEED_TIME counts down; at 0: TOP_SPEED 10, speed 8
  READ_CONTROLS $E241 -> E
  TURN_TOWN    $DB68   bit 5: the town turned round, on release
  TURN_KNIGHT  $DB89   bits 0-1 (and 2, 4 with directional control)
                       -> SET_KNIGHT_LOOK (FACING_LOOKS $DCDC)
  KNIGHT_WALKS $DC60   bit 2: WALK_ON $DCA8, else COAST_TABLE $DC71
                       -> WALK_STEP $DCB5: SET_STEP, MOVE_CLIPPED, APPLY_STEP,
                          VISIT_CELL $BF48, FOOTSTEP $C400, next frame (0-5)
  KNIGHT_THROWS $DAB7  bit 3
```

- **Arriving.** A new life sets `ARRIVING` to 40; it goes up by two a turn,
  and at 76 is set to 112 ($70): 18 turns of appearing, drawn from the
  ground up ([`drawing-sprites.md`](drawing-sprites.md)), during which he
  cannot move and nothing can touch him.
- **Turning** (`TURN_KNIGHT`). The facing's low three bits are a turn
  delay; a turn sets 1, so a held key turns him a quarter every other turn.
  With the keyboard, or a stick with rotational control, left subtracts $40
  from the facing and right adds it. With a stick and directional control
  (`CONTROL` bits 1-2 not 0, bit 3 set) the stick's direction is a facing
  -- up +V, right +U, down -V, left -U -- and he turns a quarter towards it,
  a random way if it is behind him, and walks only once he faces it. The
  stick is read up (unless left too), right, down, left, so a diagonal
  counts as one of its two. With the town turned round `SWAP_STICK` ($DC43)
  turns the directions end for end so the stick still means the same way
  on the screen. The keyboard cannot be directional.
- **His look** (`SET_KNIGHT_LOOK`, `FACING_LOOKS`): four bytes by facing,
  index bit 1 flipped when the town is turned round; bit 6 the mirror, bit
  3 the view from the front, face showing (24-29). +V is from behind
  mirrored, +U the front, -V the front mirrored, -U from behind: two
  pictures and a mirror make four facings. Facing +U or -V he comes
  towards the viewer (further back is smaller U, larger V). *Drawn*: the
  four facings rendered by the game's own code for the graphics page show
  the face on 24/40 and the back of the helmet on 16/32 (see the
  correction below).
- **Walking** (`WALK_ON`): speed = (speed + (`TOP_SPEED` - speed) / 2) AND
  $FE. From a standstill with `TOP_SPEED` 10: 4, 6, 8, 8 ... he never
  reaches 10. With the bonus's 18: 8, 12, 14, 16, 16 ... never 18. When
  the bonus runs out his speed is set to 8 and `TOP_SPEED` to 10, where he
  would have been anyway.
- **Stopping** (`COAST_TABLE`, `COAST_PLUS_V` ... `COAST_MINUS_U`): the
  distance to the next multiple of 8 along his facing, from U's or V's low
  three bits (negated for the minus facings); steps of 4, then 2, then 1
  until it is 0, then speed 0 (`STAND_ON_GRID`). He always comes to rest on
  an eight-unit grid.
- **The step of 1 never happens.** His U and V start at 128, every speed is
  even, and a step cut at a wall is cut by twice an overlap
  ([`collision.md`](collision.md)): his position stays even, so the
  distance to the grid is 2, 4 or 6 and the "last 1" at $DC8E is never
  taken. That byte is in the coverage file's list of code that never ran
  (*read*; *inferred* that nothing else makes his position odd).
- **Throwing** (`KNIGHT_THROWS`): `FIRE_DELAY` holds two turns between
  throws. The last thing taken up is thrown first: `CARRIED` is searched
  from its eleventh place back. An antibody (thing 5-8) takes a free
  `ANTIBODIES` record as graphic 80, 84, 88 or 92; with both busy, the one
  `THROW_TOGGLE` points at is ended if it is still flying, and the throw
  waits for the next press. An object (thing 1-4) goes back into its own
  record, `OBJECTS` + 16 x (4 - thing), as graphic 8-11. The thrown record
  is a copy of the legs' (place, facing, flags), speed 12, half-size 16;
  the panel place is redrawn empty (`DRAW_CARRIED`, whose places count the
  other way), and `FIRE_SOUND` plays.
- **His top** (`UPDATE_TOP` $D9EB, entered at `TOP_FOLLOWS` $DA00 for 32-47):
  copies +1 to +5 from the legs and shows the legs' frame + 16 (16-21 ->
  32-37, 24-29 -> 40-45). One turn in 32 when he is not turning (the random
  number's low byte under 8) it starts a pose of its own for 2-9 turns:
  graphic 38 or 39 from behind, 46 or 47 from the front. When the legs
  meet a wall the top becomes 22 or 30 (drawn: arms thrown out) with the
  bump sound, and while it shows 22 or 30 and the legs are still against
  the wall it does not copy their place.

## How this was found

Read, routine by routine (stage 2, range 4), the controls' bits from
`READ_CONTROLS` (range 5). *Measured* in the simulator (the build's
`Machine`, keyboard control, pokes only at `MAIN_LOOP`): with the walk key
held from a standstill his speed went 4, 6, 8 and stayed at 8 (never past 8
in a 3000-turn walk); with `SPEED_TIME` and `TOP_SPEED` poked as the bonus
sets them, 8, 12, 14, 16 and stayed at 16. Letting go of the walk key twelve
times, in four facings, he came to rest each time with U and V multiples
of 8. The "step of 1" reasoning is from these notes' check of the coverage
file against the code.

## Confidence

The control flow and the tables *read*; the speed ceilings and resting on
the grid *measured*.

## Filmation (Knight Lore, Alien 8, Pentagram)

`matches.txt` finds no counterpart above chance for any of these
routines. The earlier games' player moves by fixed steps, jumps and falls
under gravity; Nightshade's knight walks in four directions with
acceleration and has no height. Alien 8's robot is also two records, legs
and a top that follows them; here the top has poses of its own. Directional
control is on Alien 8's and Pentagram's menus too; the turned-round view
that it has to follow is new.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `UPDATE_TOP`, `TOP_FOLLOWS` | `SUBD9EB` | $D9EB, $DA00 | the top |
| `UPDATE_KNIGHT` | `SUBDA7A` | $DA7A | the legs: his whole update |
| `KNIGHT_THROWS` | `SUBDAB7` | $DAB7 | throw the last thing taken up |
| `TURN_TOWN`, `TURN_KNIGHT`, `SET_KNIGHT_LOOK` | `SUBDB68`, `SUBDB89` | $DB68, $DB89, $DC14 | turning |
| `SWAP_STICK` | `SUBDC43` | $DC43 | the stick's directions, turned round |
| `KNIGHT_WALKS` | `SUBDC60` | $DC60 | walk, or come to a stop |
| `COAST_TABLE` | `WALK_TABLE` | $DC71 | renamed: its routines run when he is *not* walking |
| `COAST_PLUS_V`, `COAST_TO_GRID`, `COAST_PLUS_U`, `COAST_MINUS_V`, `COAST_BACKWARDS`, `COAST_MINUS_U`, `STAND_ON_GRID` | `SUBDC79` ... `SUBDCA3` | $DC79-$DCA3 | stopping on the grid |
| `WALK_ON`, `WALK_STEP` | `SUBDCA8` | $DCA8, $DCB5 | speed up; the step |
| `FACING_LOOKS` | `DATADCDC` | $DCDC | mirror and front view by facing |

## Disassembly corrections

- Stage 1 named $DC71 `WALK_TABLE`; its routines are for coming to a stop
  (range 4).
- Stage 2 had the knight's views the wrong way round: bit 3 of his graphic
  (24-29 legs, 40-45 top, 30, poses 46-47) was called the back view. The
  graphics page drew his four facings with the game's own code, and 24/40
  show his face, 16/32 the back of his helmet: bit 3 is the view from the
  front. Corrected at $D9EB, $DB89, $DC35, $DCD3 and $DCDC (stage 3,
  2026-09-28).

## Open questions

- Why a grid of 8? Perhaps so he stands square in a doorway; nothing in
  the code says.
- What the top's poses (38-39, 46-47) are meant to show: stage 3's
  animation pages draw them.
