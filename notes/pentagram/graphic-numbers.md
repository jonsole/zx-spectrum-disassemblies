# Graphic numbers and update routines

**Question this answers:** what an object's graphic number decides, and which
update routine each of the 172 graphic numbers runs.

**Short answer:** the graphic (+$00 of a record) is at once the sprite, looked
up in `GRAPHICS` ($6DD7), and the behaviour, looked up in `UPDATES` ($AE2F):
an object animates, and can change what it is, by changing its own graphic.
Most numbers run a routine that does nothing but set a drawing nudge; the rest
are the player, the movers, the quest's things, bolts, puffs and the things
from the sky.

## How it works

`UPDATES` is 172 words, one per graphic, generated record by record by
`scripts/pentagram_data.py`; the main loop jumps through it for every record
every turn ([`main-loop.md`](main-loop.md)). The table, grouped by routine
(*read* from the table at build time):

| Graphics | Routine | What they are |
|---|---|---|
| 0-5, 18-22, 24-27, 29, 31, 58, 59, 61, 62, 83, 94-111 | `NOTHING` $C43F | empty (0), on its way out (1), the border's and panel's pieces (2-5, 58-62), the lives icon (22), scenery that never changes, and numbers that draw nothing |
| 6, 8 / 7, 9 | `FIRST_PILLAR` $C7AD / `SECOND_PILLAR` $C789 | the two kinds of arch; the first pillar is the doorway ([`doorways-and-rooms.md`](doorways-and-rooms.md)) |
| 10, 11, 76, 82, 152-159 | `JUMP_L16_D8` $CB4E | still things; 152-156 are the collectables once placed |
| 12-15, 52 | `DRAW_AT_L8_D2` $C784 | still things |
| 53-56 | `DRAW_AT_L8_D4` $C77F | still things |
| 57 | `DRAW_AT_L8` $C74B | a still thing |
| 77 | `JUMP_L16_D12` $CB51 | no template has it; never ran |
| 16, 17 / 80, 81 | `ROAMER` $D1F5 / `SKY_ROAMER` $D1FD | the straight-running spider; a creature from the sky ([`movers.md`](movers.md)) |
| 23, 30, 74, 75 | `STILL_DEADLY` $C285 | things that kill and never move |
| 28 | `SPIKES` $CD70 | a bed of spikes: deadly, pushable |
| 32-39 | `PLAYER_LEGS` $C440 | the player's legs: bits 0-1 the frame, bit 2 the view ([`player.md`](player.md)) |
| 40-47 | `PLAYER_TOP` $C5D3 | his body, the legs' graphic plus 8 |
| 48-51, 160-167 | `HOMER` $CC4B | homers |
| 60 | `BOLT` $C1C5 | a panel piece given the bolt's routine; no room object has it ([`leftovers.md`](leftovers.md)) |
| 63, 72, 79 | `PUSHABLE` $CD81 | blocks and a tree stump that fall and can be pushed |
| 64-70, 71 | `PUFF` $C111, `END_PUFF` $C11D | the puff of smoke ([`bolts-and-sky.md`](bolts-and-sky.md)) |
| 73 | `SLIDING_TABLE` (in `HEAVY_BLOCK` $CD75) | the table: pushable |
| 78 | `SINKING_BLOCK` $CDA0 | sinks while stood on |
| 84 | `LIFT` $CDBB | the lift |
| 85, 86 | `BOBBER` $CE31, `DEADLY_BOBBER` $CE9A | a bobbing thing (85 is in no room); the deadly bobbing head |
| 87, 92 / 88, 93 | `PACER_U`, `DEADLY_PACER_U` $CEA0 / `PACER_V`, `DEADLY_PACER_V` $CEDA | blocks and deadly heads pacing along U / V |
| 89 | `SPIDER` $CF22 | the spider that scuttles diagonally at random |
| 90 | `BUCKET` $D0AC | the well's bucket ([`quest.md`](quest.md)) |
| 91 | `HEAVY_BLOCK` $CD75 | a block that only falls |
| 112-119 | `QUEST_ITEM` $CF68 | the four quest items, rough (112-115) and finished (116-119) |
| 120 | `WELL` $CFD2 | the well |
| 121-135 | `PENTAGRAM_PIECE` $CF14 | the pentagram's eight pieces (128-135); 121-127 are used by nothing |
| 136-139 | `CRUMBLING_BLOCK` $D2AD | a block's four stages of crumbling |
| 140-143 | `CONVEYOR_PLUS_U` ... `CONVEYOR_MINUS_V` $D2DE-$D2FF | conveyors (the plain block's sprite) |
| 144-148 | `COLLECTABLE` $CD16 | the five collectables |
| 149-151 | `BOLT` $C1C5 | a bolt's three frames |
| 168-171 | `SKY_WALKER` $D251 | the walker from the sky |

**The drawing nudge.** Every routine sets +$12 and +$13, the offset
`CALC_PIXEL_XY` ($B2C5) adds to the projected position to line the sprite up
with the object's box; for a still thing that is the whole routine. They are
LD HL / JR pairs ending at `SET_PIXEL_ADJ` ($C76E) (*read*; X is pixels right,
Y pixels up):

| Routine | Address | X, Y | Used for |
|---|---|---|---|
| `DRAW_AT_L8` | $C74B | -8, 0 | graphic 57 |
| `DRAW_AT_L16_D8` | $C75F | -16, -8 | most moving things, and through `JUMP_L16_D8` several still ones |
| `DRAW_AT_L12_D8` | $C764 | -12, -8 | the body |
| `DRAW_AT_L16_D12` | $C769 | -16, -12 | through `JUMP_L16_D12` (graphic 77), and `HEAVY_BLOCK`/`SLIDING_TABLE` |
| `DRAW_AT_L12_D6` | $C775 | -12, -6 | the legs, bolts, homers |
| `DRAW_AT_L12_D4` | $C77A | -12, -4 | the puff |
| `DRAW_AT_L8_D4` | $C77F | -8, -4 | graphics 53-56 |
| `DRAW_AT_L8_D2` | $C784 | -8, -2 | graphics 12-15, 52 |
| arch pillars | $C789, $C7A8, $C7AD | graphic 6: -5, -5 (mirrored -17, -6); 8: -8, -5 (mirrored -16, -5); 7: -7, -5 (mirrored -7, -4); 9: -16, -5 (mirrored -7, -4) | the arches |
| `UNUSED_OFFSETS` | $C750 | -4, -12; -36, -4; -20, -8 | nothing ([`leftovers.md`](leftovers.md)) |

A nudge of 0 would draw the thing at pixel x 0, because of a clamp
`CALC_PIXEL_XY` adds ([`drawing.md`](drawing.md)); every routine sets a
negative one (*measured* in room 100: all 38 records in use).

**Sprites that draw nothing.** 28 graphic numbers (0, 1, 24-27, 83, 94-111,
157-159) point at the sprite at $9395, whose width and height are zero:
`FIND_SPRITE` sees the zero and returns from its caller too, so nothing is
drawn (*read*; stage 1).

## How this was found

The table was generated from the snapshot by `pentagram_data.py` and grouped
by routine for this note; each routine was read by the agent whose range it
fell in (stage 2), and the sprites of the graphics named here were looked at
in the build's sprite pictures before naming them (the well, the bucket, the
rough stone and the finished pillar, the spiders, the blocks, the table, the
spikes, the heads). The flags in the templates were read from the template
tables.

## Confidence

*Read*. The behaviours are *measured* where [`movers.md`](movers.md),
[`quest.md`](quest.md) and [`bolts-and-sky.md`](bolts-and-sky.md) say.

## Knight Lore

Knight Lore does the same with 188 types and one table for both
([`../knightlore/object-types.md`](../knightlore/object-types.md)); its drawing
offsets are the same short routines ([`../knightlore/arches.md`](../knightlore/arches.md)).
The three unused offsets at $C750 are offsets for graphics this version no
longer has (*inferred*).

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `STRAY_RET_OFFSETS` | `DATAC74A` | $C74A | a lone RET before the offsets |
| `DRAW_AT_L8` | `SUBC74B` | $C74B | offset -8, 0 |
| `UNUSED_OFFSETS` | `DATAC750` | $C750 | three unused offsets |
| `DRAW_AT_L16_D8` ... `DRAW_AT_L8_D2` | `SUBC75F` ... `SUBC784` | $C75F-$C784 | the offsets |
| `SET_PIXEL_ADJ` | (entry point) | $C76E | their shared end |
| `JUMP_L16_D8`, `JUMP_L16_D12` | `SUBCB4E`, `SUBCB51` | $CB4E, $CB51 | the same offsets by a JP |

(`NOTHING` kept its stage 1 name.)

## Open questions

- Why graphic 60, a panel piece, has the bolt's routine; and what 121-127
  (a block's sprite, the pentagram piece's routine) and 85 were for.
