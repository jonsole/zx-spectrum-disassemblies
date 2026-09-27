# Things that move: blocks, lifts, conveyors, heads, creatures, homers

**Question this answers:** what each moving thing in the rooms does each
turn, and how it moves.

**Short answer:** they share a pattern -- set the drawing nudge, move through
the collision code (`DEC_DZ_AND_UPDATE_UVZ` to fall, or its entry
`CLIP_AND_MOVE` not to), and then either return (nothing to redraw) or end at
`SET_WIPE_AND_DRAW_FLAGS` ($CCDE). Between them: things that fall and can be
pushed, a block that only falls, a lift, a sinking block, a bobbing head,
pacers along U and V, two kinds of spider, two creatures from the sky, homers,
a crumbling block and conveyors. Most of the platform behaviour comes from
the collision code, not the routines: the player's mobile flag passes his Z
step to what he lands on and lets him ride what moves under him.

## How it works

| Routine | Graphics | Does |
|---|---|---|
| `PUSHABLE` $CD81 | 63, 79 (blocks), 72 (a tree stump) | falls one unit a turn; a push (the collision code copies the pusher's step into a mobile thing) moves it that far this turn; `STOP_MOVING` ($CD87) clears the steps and redraws only if it moved, so a thing at rest costs nothing to draw |
| `SPIKES` $CD70 | 28 | deadly both ways (`MAKE_DEADLY`), then as `PUSHABLE` |
| `HEAVY_BLOCK` $CD75 | 91 | clears its U and V steps, so pushes are lost, and only falls; with the player, the one thing that sets +$17 bit 7 on what it lands on |
| `SLIDING_TABLE` (in $CD75) | 73 | the table: pushable, keeps a push's step, falls |
| `SINKING_BLOCK` $CDA0 | 78 | never falls by itself; any Z step it is given (by him landing) becomes one unit down: it sinks while stood on |
| `LIFT` $CDBB | 84 | state in +$17: bit 0 moving, bit 1 going down, bit 7 stood on. At rest it waits; his landing passes his Z step down, it bumps the floor and, marked, starts up: asking two units a turn, giving him a Z step of 3 and telling his code he stands (bit 2 of `PLAYER_BUMPED`); it rises only while something above stops it -- him -- so if he steps off it turns round. At 176 it stops and gives him -2; going down it sinks one a turn to whatever is below |
| `BOBBER` $CE31 | 85 (in no room) | state in bit 2 of +$0D: falls one a turn; landed, rises (two the first turn, then one) to 176, then falls again; stopped from above, falls at once; with him (or block 91) on top, rises three a turn, and a jump by him clears that |
| `DEADLY_BOBBER` $CE9A | 86 | a head: deadly, then as `BOBBER` |
| `PACER_U` / `DEADLY_PACER_U` $CEA0 | 87 (a block) / 92 (a head, deadly) | two units a turn along U, the way bit 0 of +$10 says, turning at any bump; never falls; the player on the block rides with it |
| `PACER_V` / `DEADLY_PACER_V` $CEDA | 88 / 93 | the same along V |
| `SPIDER` $CF22 | 89 | deadly; falls; flipped every other turn (its scuttle); four units a turn diagonally, a new diagonal at random (U by bit 3 of `RANDOM`, V by bit 3 of R) on a bump or with no step |
| `ROAMER` $D1F5 | 16, 17 (a spider, the same sprite as 89) | deadly; falls, faster each turn since its steps are never cleared, but kept at Z 129 or more; runs straight at four a turn, and when a bump clears its step picks a new way, along U after a bump in V and otherwise along V, the sign from bit 3 of R; flips its picture every turn; bit 0 of the graphic and the mirror bit make four facings from two pictures |
| `SKY_ROAMER` (in $D1F5) | 80, 81 | a creature from the sky: as `ROAMER` without the flip |
| `SKY_WALKER` $D251 | 168-171 | the walker from the sky: as `ROAMER`, with a two-frame walk in bit 0 and the facing in bit 1 |
| `HOMER` $CC4B | 48-51, 160-167 | below |
| `CRUMBLING_BLOCK` $D2AD | 136-139 | needs both bit 7 of +$17 (him or block 91 on it) and bit 3 of +$0D (something landed); clears both and moves up a graphic, from 139 to graphic 1, rubbed out and emptied |
| `CONVEYOR_PLUS_U` ... `CONVEYOR_MINUS_V` $D2DE-$D2FF | 140-143 (the plain block's sprite) | only clear bit 3 of +$0D so the conveyor can push again next turn; the push is `CONVEYOR_PUSH` in the collision code, two units every other turn from `CONVEYOR_STEPS` ($D30A) ([`collision.md`](collision.md)); no room has 141 |
| `PENTAGRAM_PIECE` $CF14 | 121-135 | moves by whatever steps it has without falling, but only a mobile thing goes on to be redrawn; nothing gives the pieces a step, so they never move |

**Homers** (`HOMER` $CC4B): speeds in U, V and Z in sixteenths of a unit in
+$14, +$15, +$16. Each turn each gains 3 towards the player -- U and V towards
his legs (`PLAYER_U`, `PLAYER_V`), Z towards his body's Z -- through
`ACCEL_PLUS` ($CD04, capped at +56) and `ACCEL_MINUS` ($CD0D, capped at -72);
a velocity still going the wrong way is only turned gradually. The step is
(speed + 8) >> 4, arithmetic, so both caps come to a step of 4 either way.
Gravity takes one off the Z step (`DEC_DZ_AND_UPDATE_UVZ`). A move stopped in
U or V reverses that speed (`BOUNCE_U` $CCE9, `BOUNCE_V` $CCF2), so a homer
bounces off walls and objects; one stopped in Z keeps its speed -- `BOUNCE_Z`
($CCFB) exists and nothing calls it. The half-sizes in U and V are set to 10
every turn over the template's 8; the four frames are the graphic's low two
bits from a count in +$10. Homers do not kill: nothing in `HOMER` sets the
kill bits. Most fall from the sky; object template 2 is graphic 48, so a room
can start with one too (*read*).

**Where they are** (rooms used for the measured scenes): a lift in room 2, a
crumbling block in 4, a bobbing head in 11, a sinking block in 15, conveyors
140 and 142 in 37.

## How this was found

Read (stage 2, range 5; the homer in range 4); each graphic's sprite looked at
in the build's pictures (blocks, a tree stump, a table, spikes, a head,
spiders, two creatures from the sky) before naming; the rooms that place each
template found from the data. Staged scenes in SkoolKit's simulator with the
build's own `Machine` class: restart into the room, stand him above the
object, and log the object and his position every turn (*measured*):

- Lift, room 2: he landed on it at Z 128; it rose one unit a turn with him 12
  above it to 176; then he fell and pushed it down with him, faster each turn;
  at the floor it started up again.
- Crumbling block, room 4: 136, 137, 138, 139, gone, one a turn; he fell.
- Sinking block, room 15: down one a turn from Z 152 while he stood on it.
- Bobbing head, room 11 (graphic 86, nothing on it): up one a turn to 176,
  down one a turn to where it had landed, over and over.
- Conveyors, room 37: on 140 he moved +2 in U every other turn; on 142, +2 in
  V. This ran `CONVEYOR_PUSH`, which the build's sessions never did.

## Confidence

*Measured* as above; the rest *read*. The bobber's three-a-turn rise with him
on it rests on BIT 7 setting the sign flag (the JP P at $CE79 tests it) --
*read*, not run, and reachable only on the deadly head. The homers' motion is
*read* only.

## Knight Lore

Knight Lore has the same kinds of thing -- crumbling blocks, sinking blocks,
moving blocks, bouncing balls and guards -- written differently
([`../knightlore/object-behaviours.md`](../knightlore/object-behaviours.md));
`kl_matches.txt` has little above 0.5 in this range. Pentagram's conveyors,
lift and homers have no Knight Lore counterpart the match found. The pattern
nudge / move / redraw-if-moved is the same.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `BOUNCE_U`, `BOUNCE_V` | `SUBCCE9`, `SUBCCF2` | $CCE9, $CCF2 | reverse a homer's U or V speed |
| `BOUNCE_Z` | `DATACCFB` | $CCFB | the same for Z; unused, now code |
| `ACCEL_PLUS`, `ACCEL_MINUS` | `SUBCD04`, `SUBCD0D` | $CD04, $CD0D | speed +3 / -3, capped |
| `SPIKES` | `SUBCD70` | $CD70 | 28 |
| `HEAVY_BLOCK` (and `SLIDING_TABLE` $CD7C) | `SUBCD75` | $CD75 | 91 (and 73) |
| `PUSHABLE` (and `FALL` $CD84, `STOP_MOVING` $CD87) | `SUBCD81` | $CD81 | 63, 72, 79 |
| `SINKING_BLOCK` | `SUBCDA0` | $CDA0 | 78 |
| `LIFT` | `SUBCDBB` | $CDBB | 84 |
| `BOBBER`, `DEADLY_BOBBER` | `SUBCE31`, `SUBCE9A` | $CE31, $CE9A | 85, 86 |
| `DEADLY_PACER_U` (and `PACER_U` $CEA3) | `SUBCEA0` | $CEA0 | 92 (87) |
| `DEADLY_PACER_V` (and `PACER_V` $CEDD) | `SUBCEDA` | $CEDA | 93 (88) |
| `PENTAGRAM_PIECE` | `SUBCF14` | $CF14 | 121-135 |
| `SPIDER` | `SUBCF22` | $CF22 | 89 |
| `ROAMER` (and `SKY_ROAMER` $D1FD) | `SUBD1F5` | $D1F5 | 16, 17 (80, 81) |
| `SKY_WALKER` | `SUBD251` | $D251 | 168-171 |
| `CRUMBLING_BLOCK` | `SUBD2AD` | $D2AD | 136-139 |
| `CONVEYOR_PLUS_U` ... `CONVEYOR_MINUS_V` | `SUBD2DE` ... `SUBD2FF` | $D2DE-$D2FF | 140-143 |
| `CONVEYOR_STEPS` | `DATAD30A` | $D30A | what each conveyor adds |

## Disassembly corrections

- The remake's memory note has "$CE31 hopper (86)": 86 goes to $CE9A, which
  makes it deadly and runs on into $CE31; $CE31 is graphic 85's, and no room
  places 85. "$CDBB lift? (84)": a lift, confirmed (*measured*). "$D1FD
  (80/81) and $D251 (168-171) fall-then-roam deadly creatures": right; $D1F5
  itself is the straight-running spider, 16 and 17.

## Also found for the stage 3 pages (2026-09-27)

- The bobbing head rises one unit a turn from the first -- the 2 stored on landing is overwritten before use (*measured*, room 88; the annotation said two, corrected). In room 54 he hovered six turns before landing on the lift; why is an open question.

## Open questions

- Graphics 121-127 and 85 appear in no template, room or quest record:
  leftovers? ([`leftovers.md`](leftovers.md))
- The roamers are kept at Z 129 or above rather than the floor's 128; why 129
  is not worked out.
- The lift gives him its Z step whatever is on top of it; whether anything but
  him can ride it in practice was not tried.
