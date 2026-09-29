# The knight

**Question this answers:** what each key does to the knight, how he jumps
and fights, and what a fall costs.

**Short answer:** Y-P, H-ENTER, Q-T and A-G walk +x, -x, +z and -z (no
diagonals: a later test wins); SPACE or SYMBOL SHIFT jumps 16 units up over
8 passes, going the way he walked, and he falls straight down; B-M fights
(three passes with the sword out, standing, then three stepping forward);
X-V picks up, CAPS SHIFT and Z drop ([`carrying.md`](carrying.md)). A fall
of more than 20 passes (40 units) costs a LIFE point for each pass over. The
keys between passes -- 1-5, 6, 7, 9, pause and quit -- are the main loop's
([`main-loop.md`](main-loop.md)).

## How it works

`KNIGHT_UPDATE` ($F3CD, in `CREATURE_UPDATE`, the author's I8) runs on
passes when he is not in the air (in the air `CHE3D` carries him on):

1. **A fall.** `FALL_COUNT` ($FF94, counted by `COMMIT_STEP` while he
   falls) less 20, if not negative, comes off LIFE (`DECLIF`, $F1B6), and
   the count restarts.
2. **Keys.** Port $18FE -- every half-row but 1-5 and 6-0 -- any key: on to
   the action keys (`PICK_OR_DROP`, $F441). Otherwise the Kempston joystick
   (`IN31`, if 9 has turned it on). Otherwise he stands.
3. **Standing.** C = 1, +17 back to frame 0, and +18 counts a stance timer:
   a fidget (bit 3 of `GAME_FLAGS`) of 14 passes after a random wait of 128
   to 255. Frames $91CA / $99C8 facing the viewer, $93F8 / $9A82 away. On a
   moving object he goes with it (state bit 4, $F418).
4. **Action keys**, the CAPS SHIFT to V row: X, C, V pick up (`PICK_UP`,
   $F4F4); CAPS SHIFT, Z drop (`DROP_THING`, $F452); nothing on that row:
   `KNIGHT_CONTROLS` ($F595, the author's I88).
5. **The way to go**: the joystick (`STICK_DIRECTION` $F59A, the author's
   I89 and I82-I85: right, left, down, up; fire fights at once) or the
   keyboard (`WALK_KEYS` $F5B3, I80 and INP2-INP4: Y-P, H-ENTER, A-G, Q-T).
   Later tests win: Q-T beats A-G beats H-ENTER beats Y-P.
6. **Turning** (`KNIGHT_TURN` $F5D7, INP5): `MIMAN` mirrors his frames to
   face the way ([`turning-sprites.md`](turning-sprites.md)). Mid-jump
   (state 5) he just walks on. Else SPACE or SYMBOL SHIFT jumps; B, N or M
   fights (`KNIGHT_FIGHT` $F5F3, INP59); else he walks, three frames of 186
   bytes from $9110 (facing the viewer) or $933E (away).
7. **The jump** (`KNIGHT_JUMP`, $F629): his direction with $12 (up, rising),
   +15 = 8, +18 = that direction, state 5. `CHE3D`'s state-5 case counts +15
   down and runs INP5 with the kept direction; at 0 he is state 8 again and
   falls.
8. **The fight**: bit 1 of `GAME_FLAGS` is "sword out". Out: he stands 3
   passes (frame $96E0, or $9854 facing away). In: he steps forward 3
   passes ($979A / $990E). The sword is what lets him strike a creature he
   meets ([`meeting.md`](meeting.md)).

The knight's record is record 7 (`KNIGHT`, $BC90); his +16 is 18, weight 2,
so he pushes things of weight 7 or less ([`collision.md`](collision.md)).

## How this was found

Read (stage 2, range 4); then keys held in the simulator in room 29 and his
record logged each pass (jump, jump with Q, fight); and he was dropped from
30, 40, 50 and 60 units above the floor: LIFE unchanged, unchanged, less 5,
less 10.

## Confidence

The keys, the jump, the fight and the fall's cost: *measured*. The fidget's
timing: *read*.

## Krumlinde

He has no reading of I8's keys: his `main_loop.md` names the dispatch but
not the jump, the fight's two phases or the fall's cost. The source text at
$617C and $639C (on the tape) has the author's own lines for I88 to INP5,
which settle those labels ([`symbols.md`](symbols.md)).

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `KNIGHT_UPDATE` | (inside $F309) | $F3CD | The author's I8 |
| `PICK_OR_DROP` | (inside) | $F441 | Krumlinde's `MainLoop_DropItemCheck` |
| `KNIGHT_CONTROLS` | `SUBF595` | $F595 | The author's I88 |
| `STICK_DIRECTION` | (inside) | $F59A | The author's I89 |
| `WALK_KEYS` | (inside) | $F5B3 | The author's I80 |
| `KNIGHT_TURN` | (inside) | $F5D7 | The author's INP5 |
| `KNIGHT_FIGHT` | (inside) | $F5F3 | The author's INP59 |
| `KNIGHT_JUMP` | (inside) | $F629 | |
| `FALL_COUNT` | (none) | $FF94 | Passes falling |
| `GAME_FLAGS` | `VARFF97` | $FF97 | Bit 1 the sword; bit 3 the fidget |

## Open questions

- None of substance; the fidget is cosmetic (*inferred*).
