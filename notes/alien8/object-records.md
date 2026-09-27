# The object records

**Question this answers:** what the 56 object records are, and what every
field and flag bit of one means.

**Short answer:** everything the game draws or moves is a 32-byte record,
Knight Lore's layout, at `OBJECTS` ($5B88): the robot's legs and top, two
for what lies in the room from the table of places (the valves and the
extra lives), and 52 for the room, which the builder fills. The graphic in
+0 picks both the sprite and the update routine; the other fields are the
box (position, half-sizes, height), flags, the step this turn, what the
collision code found, harm, and where it was drawn. Four bytes, +$14 to
+$17, are never used.

## How it works

**The records** (*read*; the builder's range *measured* by every room built
in the tour):

| Record | Address | Label | Holds |
|---|---|---|---|
| 0 | $5B88 | `OBJECTS` | the robot's legs -- the whole of his collision box; `PLAYER_U` $5B89, `PLAYER_FLAGS` $5B8F, `PLAYER_ROOM` $5B90 |
| 1 | $5BA8 | `PLAYER_TOP` | his top, copied from the legs every turn and sitting 12 above them ([`robot.md`](robot.md)) |
| 2, 3 | $5BC8, $5BE8 | `VALVES`, `VALVE_SECOND` | what lies in this room from `PLACES`: a valve, loose or seated, or an extra life; built by `FIND_SPECIAL_OBJS_HERE` ($AE99), written back by `UPDATE_SPECIAL_OBJS` ($AF05) ([`valves-and-sockets.md`](valves-and-sockets.md)) |
| 4-55 | $5C08-$6268 | `ROOM_OBJECTS` | the room's backgrounds and objects, filled by `BUILD_ROOM` ($CCA7) from record 4 up; the rest cleared up to `BELOW_BLOCK` ($6288) |

In the scene after a game the same records hold the scene's pieces
(`SET_UP_SCENE`, $B804, [`scenes.md`](scenes.md)). `CLEAR_OBJECTS` ($CE4E)
clears all 56 (1792 bytes) when a game ends.

**The fields** (*read*, by the five describing agents together; the header
of `scripts/alien8_annotations.ctl` and the `$5B88` entry carry the same
table):

| Offset | Field |
|---|---|
| +$00 | graphic: 0 an empty record; 1 rubbed out and emptied when next drawn (`CALC_PIXEL_XY_AND_RENDER` $D013 turns 1 into 0). It indexes `UPDATES` ($A7EA) and `GRAPHICS` ($7827) |
| +$01, +$02, +$03 | U, V, Z: the box's centre in U and V, its base in Z |
| +$04, +$05, +$06 | half-sizes in U and V; the height |
| +$07 | flags: bit 0 in a doorway (walls off, the exit armed); bit 1 out of the collision tests; bit 2 pushable, and carried by what it stands on; bit 3 may use doorways (the legs); bit 4 to be drawn this turn (set by `SET_DRAW_OBJS_OVERLAPPED` and `ADJUST_PLYR_UVZ_FOR_ROOM_SIZE`, cleared by `CALC_PIXEL_XY_AND_RENDER`); bit 5 moved -- wipe the old picture and copy the area out (`SET_WIPE_AND_DRAW_FLAGS` $BFAB sets 4 and 5, `RENDER_DYNAMIC_OBJECTS` clears 5); bit 6 mirrored; bit 7 upside down |
| +$08 | the room |
| +$09, +$0A, +$0B | the step in U, V, Z this turn; the Z step carries over as speed |
| +$0C | bits 0-2: the move was stopped in U, V, Z (bit 2 either way: standing on something, or bumping something above -- which is what keeps a ridden lift rising); bit 3 jumping; bits 4-7 turns he walks on by himself after a doorway |
| +$0D | bit 7 kills what it moves into; bit 5 kills what touches it (`MAKE_DEADLY` $B2A7 sets both); bit 6 killed; bit 3 met in Z by a carried mover of graphics 16-47 (the robot, the pushable and bobbing blocks, the lift); bit 2 a kind's own (a ceiling drop falling, a lift's direction); bit 0 set on a valve just put down (`LOOSE_VALVE` reads it); on the legs, bit 0 the turn's direction and bits 1-2 its count |
| +$0E, +$0F | the legs' nudge from a doorway, used once (`CALC_PLYR_DUV` $C2F6); +$0F is also a ceiling drop's "was standing" (`THUD_ON_LANDING` $AD54) and a scene tool's steps (`SCENE_TOOL` $AB61) |
| +$10, +$11 | for records 2 and 3, the address of the thing's place in `PLACES`; for other kinds, their own: the real graphic kept while the robot appears (and in the start records), a pacer's saved step, a leaper's flags and target height, a mouse's turns to walk, a remote robot's control bits, a scene piece's colour |
| +$12, +$13 | the drawing nudge in pixels, set each turn by the update routine ([`graphic-numbers.md`](graphic-numbers.md)) |
| +$14-+$17 | never used: no IX or IY offset $14-$17 in the listing (*searched*) |
| +$18, +$19 | the sprite's width in bytes and height in rows as drawn (`CALC_2D_INFO` $C63D) |
| +$1A, +$1B | its pixel x and y, y counted up from the bottom; in the scene after a game set directly, not projected |
| +$1C-+$1F | +$18-+$1B as they were before this turn's update (copied by `MAIN_NEXT_OBJECT`), kept to rub out last turn's picture |

## How this was found

Every IX and IY offset in the listing was gathered per routine by the five
stage 2 agents, each from its own range; the lead merged their readings
into the annotations' header. The unused +$14-+$17 were searched for as
offsets in the whole listing (range 1).

## Confidence

*Read*. Several bits also *measured* in staged scenes: +$0C bit 2 and +$0D
bit 3 with the lifts (room $23), +$0D bits 0-2 on the legs while turning,
+$10 bit 7 moving between the two remote robots of room $0B
([`driving.md`](driving.md)).

## Knight Lore and Pentagram

Knight Lore's 32-byte record, field for field where the job is the same
([`../knightlore/object-types.md`](../knightlore/object-types.md),
[`../pentagram/object-records.md`](../pentagram/object-records.md)).
Knight Lore has 40 records, Pentagram 54, Alien 8 56. Records 2 and 3 are
Knight Lore's special objects, in the same slots; Pentagram uses its 2-5 for
bolts and things from the sky. Knight Lore's +$0D bit 3 is set on every
obstacle met in Z; Alien 8's only by a carried mover of graphics 16-47
([`collision.md`](collision.md)).

## Disassembly corrections

- The annotations' header, written in stage 1 from the fields read so far,
  was rewritten by the lead at the stage 2 merge from all five agents'
  readings. Stage 1 had +$0C bit 2 as "standing on something"; it is set
  whenever a move in Z is stopped, down or up (`ADJ_DZ_FOR_OBJ_INTERSECT`,
  $C54F), which a lift relies on. +$0D bits 0, 2 and 3, +$10's other uses,
  +$12/+$13 and +$1A/+$1B were missing.
- The listing's comment at $C577 ("The robot has met the obstacle in Z")
  is narrower than the code: the test is on graphics 16-47 with bit 2 of
  +$07, which the object templates give the pushable blocks (28, 29), the
  bobbing block (31) and the lift (47) as well as the robot (*read* at
  $C568-$C577 and in the templates' flags). Range 2's draft said so; range
  4's said "the robot's legs". To tidy in the annotations.

## Open questions

- Whether bit 3 of +$0D set on a conveyor (which never clears it) or on a
  thing no routine reads it for has any effect: none found.
