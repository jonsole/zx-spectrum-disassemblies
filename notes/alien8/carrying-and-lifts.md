# Blocks that carry, sink and lift

**Question this answers:** what the room's moving blocks do, turn by turn --
pushable blocks, shuttles, conveyors, the blocks that sink or collapse when
stood on, lifts and bobbing blocks -- and how the engine lets a thing carry
or lift what stands on it.

**Short answer:** most are Knight Lore's movers with Alien 8's graphic
numbers. Nothing here has code of its own for carrying: the collision code
hands a lander's Z step to what it lands on, lets the lander take that
thing's U and V steps, and marks it "landed on" (bit 3 of +$0D) when the
lander is the robot or another carried block. A conveyor just sets its own
step every turn and never moves; whatever stands on it takes the step. A
lift moves only while ridden; a bobbing block always. The two share one top
height per room, `LIFT_TOP` ($5B25).

## How it works

Every routine sets its drawing nudge first ([`graphic-numbers.md`](graphic-numbers.md))
and most end in `SET_WIPE_AND_DRAW_FLAGS` ($BFAB) or `SOUND_AND_DRAW` ($B3BF:
a note pitched by U + V + Z, then the redraw). Moving is
`DEC_DZ_AND_UPDATE_UVZ` ($BFB6): the Z step less one (gravity), the
collision cut (`ADJ_FOR_OUT_OF_BOUNDS` $C442), then the steps added.

| Graphic | Template | Routine | What it does |
|---|---|---|---|
| 28 / 29 | 2 / 3 | `PUSHABLE` $B2FF / `PUSHABLE_INVERTED` $B31A | pushed a step at a time (the pusher's step, cleared after one move), falls; `SAVE_UVZ` $B2D9 and `SAME_UVZ` $B2EB tell whether it moved |
| 66 / 67 | 13 / 14 | `SHUTTLE_U` $B224 / `SHUTTLE_V` $B21C | Knight Lore's shuttle (`SHUTTLE_BLOCK` $B22A): a triangle wave on the turn counter, a span of 16, odd records half a cycle behind even ones |
| 68, 69, 70, 71 | 8-11 | `CONVEYOR_PLUS_V` $B267 (`CONVEYOR` $B26B), `CONVEYOR_PLUS_U` $B27A, `CONVEYOR_MINUS_V` $B280, `CONVEYOR_MINUS_U` $B286 | +V, +U, -V, -U: a step of 2 set every turn; never move; a beep (`HIGH_BEEP` $B6BB) when something lands (their +$0B non-zero) |
| 45 | 6 | `COLLAPSING_BLOCK` $B28C | landed on: graphic 64, then 65, then gone -- the short sparkle, a turn each |
| 44 | 5 | `DROPPING_BLOCK` $B2B6 | sinks one unit a turn while landed on |
| 47 | 12 | `LIFT` $B31F (`LIFT_MOVE` $B34E) | still until ridden; then up to its top and down to the floor |
| 31 | 4 | `BOBBER` $B33F | always moving, up to its top and down |

**The lift and the bobbing block** (*read*). The state is bit 2 of +$0D,
which the kill bits leave free: clear going down, one unit a turn; set
going up, two a turn, and a move stopped by the rider is tried again at 4,
which lifts him ($B37E). Going down it turns round when it is stopped (bit 2
of +$0C, set whenever a move in Z is stopped, down or up); going up, when its
Z passes `LIFT_TOP`. `BUILD_ROOM` clears `LIFT_TOP`, and the first lift or
bobbing block updated in the room sets it -- a lift its own Z plus 48, a
bobbing block its own Z -- so every one in the room shares it. The lift
waits for bit 3 of +$0D, "landed on", before it moves. No room has both
kinds (*read* from the data: lifts in $23, $34, $43, $93, $A6, $D6; bobbing
blocks in $1D, $36, $39, $4A, $54, $86, $B9, $C6, $E7).

**The collapsing block's end** writes a zero to ROM address 0: it has no
place, so its +$10/+$11 are 0 and `SPARKLE_END_PLACE` ($B3B0) empties "the
place" there. Harmless (*read*; *measured*: the block went and nothing else
changed).

## How this was found

Read each routine against `matches.txt`'s Knight Lore and Pentagram matches;
which graphics use which routine from `UPDATES`; which templates and rooms
from `alien8_data.py`'s walkers (stage 2, range 2). Then each run in the
simulator, the robot put in a room with `_go` and dropped on the thing with
`_onto`, watching the records turn by turn (*measured*):

- room $0D: on graphic 68 he was carried two units a turn in V;
- room $12: the collapsing block became 65, then 1, then empty, a turn
  each, and he fell;
- room $82: the dropping block sank one a turn from Z 100 with him on it
  (the build's sessions had never stood on one);
- room $23: the lifts stayed put until ridden; ridden, up one a turn to 113
  (top 112), down one a turn to the floor, and up again;
- room $36: two bobbing blocks, top 100, down one a turn to Z 76 and up two
  a turn to 102, half a cycle apart. Range 1 read `LIFT_TOP` as 100 in room
  $1D too.

## Confidence

*Read*, and *measured* for the conveyors, the collapsing and dropping
blocks, the lifts and the bobbing blocks. The pushable blocks and the
shuttles: *read* only, and Knight Lore's. That a lift left in mid-air stays
there: *inferred* from the code.

## Knight Lore and Pentagram

Knight Lore's: the shuttle (`upd_55`, `shuttle_block`, the patched IX
displacements), the dropping block (`upd_91`), the collapsing block
(`upd_143`), the pushables (`upd_85`)
([`../knightlore/moving-objects.md`](../knightlore/moving-objects.md)).
Pentagram has conveyors too, but pushes what stands on them every other
turn from a table; Alien 8's carry by the step the lander takes over.
Pentagram's lift keeps its state in +$17 and a fixed top of 176
([`../pentagram/movers.md`](../pentagram/movers.md)). The shared
`LIFT_TOP` is like Knight Lore's bouncing balls' shared turning height.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `SHUTTLE_V`, `SHUTTLE_U` (`SHUTTLE_BLOCK`) | `SUBB21C`, `SUBB224` | $B21C, $B224 | graphics 67, 66 |
| `CONVEYOR_PLUS_V` (`CONVEYOR`), `CONVEYOR_PLUS_U`, `CONVEYOR_MINUS_V`, `CONVEYOR_MINUS_U` | `SUBB267` ... `SUBB286` | $B267-$B286 | graphics 68-71 |
| `COLLAPSING_BLOCK` | `SUBB28C` | $B28C | graphic 45 |
| `DROPPING_BLOCK` | `SUBB2B6` | $B2B6 | graphic 44 |
| `SAVE_UVZ`, `SAME_UVZ` | `SUBB2D9`, `SUBB2EB` | $B2D9, $B2EB | position kept and compared |
| `PUSHABLE` (`PUSHABLE_MOVE`), `PUSHABLE_INVERTED` | `SUBB2FF`, `SUBB31A` | $B2FF, $B31A | graphics 28, 29 |
| `LIFT` (`BOBBER`, `LIFT_MOVE`) | `SUBB31F` | $B31F | graphics 47 and 31 |
| `LIFT_TOP` | `UNKNOWN_5B25` | $5B25 | the room's shared top height |

## Disassembly corrections

- `$5B25` was `UNKNOWN_5B25` in stage 1: the lifts' top, renamed `LIFT_TOP`
  at the merge (ranges 1 and 2 agreed; range 5 saw only the builder clear
  it).

## Also found for the stage 3 pages (2026-09-28)

- A lift with him on it rises one unit a turn, not two -- it passes its step to him -- and peaks at `LIFT_TOP` + 1 (113) (*measured*). Leapers rise 49, not 48: one extra unit as the rising step runs out (*measured*).

## Open questions

- `PUSHABLE`'s "no step, but moved" branch ($B30D-$B311) never ran and by
  the reading cannot: is there anything (a conveyor under it?) that moves a
  record without its step?
- Bit 3 of +$0D is set on a conveyor when landed on and never cleared: no
  effect found.
- The dropping block's sinking ($B2C2-$B2D8) and the lift's retry at 4
  ($B37E-$B38B) never ran in the build's sessions; the first ran in range
  2's staged scene.
