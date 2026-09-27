# Graphic numbers

**Question this answers:** what each graphic number runs every turn, what
the drawing nudges are, and which graphics have no update routine.

**Short answer:** 132 graphic numbers (0-131) index the sprite table
`GRAPHICS` ($7827); 131 of them (0-130) also index the update table
`UPDATES` ($A7EA). The number is the behaviour: a thing animates, or turns
into something else -- a valve into a seated valve, anything into a sparkle
-- by changing its own graphic. Graphic 131 has a sprite and no update
routine: it is drawn only on the panel, as the icon beside the chambers
count. Many routines are nothing but a drawing nudge.

## How it works

**What each graphic runs** (*read*: the 131 words at `UPDATES` decoded from
the snapshot, each matched to its entry):

| Graphics | Routine | What it is |
|---|---|---|
| 0, 1, 4-10, 84 | `NO_UPDATE` $A8F0 | empty, emptied, and the panel's and border's pieces (drawn only there) |
| 2 | `FIRST_PILLAR` $BFEA | a doorway's first pillar: the doorway ([`doorways-and-rooms.md`](doorways-and-rooms.md)) |
| 3 | `SECOND_PILLAR` $BFD8 | its second pillar: a nudge only |
| 11 | `LOWER_HALF` $B055 | the lower half of a two-record creature ([`creatures.md`](creatures.md)) |
| 12 | `EXTRA_LIFE` $BEE0 | an extra life ([`lives-and-starting.md`](lives-and-starting.md)) |
| 13, 14, 15 | `DRAW_AT_L12_D7`, `DRAW_AT_L4_D3`, `DRAW_AT_L8_D5` | the thin pieces backgrounds 4-9 are made of: a nudge only |
| 16-23 | `PLAYER_LEGS` $C0BE | the robot's legs ([`robot.md`](robot.md)) |
| 24-27 | `TURNING_LEGS` $C1E2 | the legs part way through a turn |
| 28 / 29 | `PUSHABLE` $B2FF / `PUSHABLE_INVERTED` $B31A | pushable blocks ([`carrying-and-lifts.md`](carrying-and-lifts.md)) |
| 30 | `DRAW_AT_L16_D9` | object template 1's only piece and backgrounds 12 and 13's: a nudge only |
| 31 | `BOBBER` $B33F | the bobbing block |
| 32-43 | `TOP_FOLLOWS_LEGS` $C6E4 | the robot's top |
| 44 | `DROPPING_BLOCK` $B2B6 | sinks while stood on |
| 45 | `COLLAPSING_BLOCK` $B28C | vanishes when stood on |
| 46 | `SPIKES` $B2A4 | deadly, still |
| 47 | `LIFT` $B31F | the lift |
| 48-54, 64 | `SPARKLE_STEP` $B3A4 | the sparkles things vanish in ([`lives-and-starting.md`](lives-and-starting.md)) |
| 55 | `SPARKLE_END` $B3B8 | the death sparkle's last frame |
| 56-62 | `PLAYER_APPEARING` $BC70 | the robot materialising |
| 63 | `PLAYER_APPEARED` $BC83 | ... and taking his real graphic |
| 65 | `SPARKLE_END_PLACE` $B3B0 | the short sparkle's end: empties the thing's place |
| 66 / 67 | `SHUTTLE_U` $B224 / `SHUTTLE_V` $B21C | shuttling blocks |
| 68, 69, 70, 71 | `CONVEYOR_PLUS_V` $B267, `CONVEYOR_PLUS_U` $B27A, `CONVEYOR_MINUS_V` $B280, `CONVEYOR_MINUS_U` $B286 | conveyors |
| 72, 75 | `STILL_DEADLY` $B29F | deadly, still, never redrawn |
| 73 | `CEILING_DROP` $AD13 | drops from the ceiling ([`creatures.md`](creatures.md)) |
| 74 | `CRYONAUT` $AE96 | the frozen crew in a chamber: a nudge only ([`chambers-and-summary.md`](chambers-and-summary.md)) |
| 76-79 | `SPARK_CHASER` $B19C | a crackle of sparks that heads for the robot |
| 80 | `SCENE_SPARKS` $ABF5 | the re-programming scene ([`scenes.md`](scenes.md)) |
| 81-83 | `SCENE_TOOL` $AB61 | the glove, the hammer, the hook |
| 85, 88-91 | `COLOUR_SCENE_OBJECT` $AC21 | the scenes' still pieces: colour only |
| 86, 87 | `PACER` $B110 | a two-record creature that paces |
| 92 / 93 | `OILED_ROBOT` $A971 / `SCENE_ROBOT_TOP` $A95A | the winning scene's robot |
| 94, 95 | `WANDERER` $B06B | a two-record creature that wanders |
| 96-99 | `LOOSE_VALVE` $AF79 | the four kinds of valve ([`valves-and-sockets.md`](valves-and-sockets.md)) |
| 100-103 | `SEATED_VALVE` $AE5D | a valve on its socket |
| 104-107 | `WANTED_VALVE` $AE17 | the picture of the valve a socket wants |
| 108-111 | `SOCKET_SPARKLE` $AE33 | the sparkle over a socket |
| 112-115 | `SOCKET` $AE68 | a chamber's socket, one per kind |
| 116-119 | `CLOCKWORK_MOUSE` $AAA1 | clockwork mice |
| 120, 121 | `SLOW_CHASER` $AA89 | a deadly thing that homes in one unit a turn |
| 122, 123 | `REMOTE_BUTTON` $AA63 | the remote robots' buttons ([`remote-robots.md`](remote-robots.md)) |
| 124-127 | `REMOTE_ROBOT` $A9C7 | the remote-controlled robots |
| 128 | `REMOTE_PAD` $AA4D | their stop pad |
| 129 | `FRAGILE` $A9B1 | deadly, breaks when moved |
| 130 | `LEAPER` $A8F9 | deadly, leaps 48 up |
| 131 | (none) | the panel's chambers icon, drawn by `DISPLAY_PANEL` ([`menu-and-panel.md`](menu-and-panel.md)) |

**The drawing nudges** (*read*). Every update routine starts by putting a
pixel nudge in +$12/+$13 through one of these, which share their end
`SET_PIXEL_ADJ` ($BF77); the projection adds it (`CALC_PIXEL_XY` $CFD2: x =
U + V - 128 + nudge x; y = (V - U + 128)/2 + Z - 40 + nudge y). Several are
a graphic's whole routine.

| Address | Label | x, y | Used by |
|---|---|---|---|
| $BF3D | `DRAW_AT_L16_D9` | -16, -9 | 30 (whole routine); 28, 44, 45, 47, 66, 68, 72, 75, 122-128, 130 |
| $BF42 | `UNUSED_NUDGE_L12_D9` | -12, -9 | nothing: unreached code, left as data ([`leftovers.md`](leftovers.md)) |
| $BF47 | `DRAW_AT_L12_D8` | -12, -8 | 56-63 (appearing), 73 |
| $BF4C | `DRAW_AT_L16_D7` | -16, -7 | the legs (16-27), the sockets (112-115) |
| $BF51 | `DRAW_AT_L12_D7` | -12, -7 | 13 (whole routine) |
| $BF56 | `DRAW_AT_L16_D6` | -16, -6 | 29 |
| $BF5B | `DRAW_AT_L12_D6` | -12, -6 | 11, 86, 87, 94, 95, 116-119 |
| $BF60 | `DRAW_AT_L12_D5` | -12, -5 | the valves (96-99), 100-111 |
| $BF65 | `DRAW_AT_L8_D5` | -8, -5 | 15 (whole routine) |
| $BF6A | `DRAW_AT_L12_D4` | -12, -4 | the sparkles (48-54, 64, 65), 46, 74, 76-79, 120, 121, 129 |
| $BF6F | `DRAW_AT_L16_D3` | -16, -3 | the top (32-43) |
| $BF74 | `DRAW_AT_L4_D3` | -4, -3 | 14 (whole routine) |
| $BF7E | `DRAW_AT_L8_D2` | -8, -2 | the extra life (12) |

**The sprites** (*read* from `GRAPHICS` for the whole table): 78 sprite
records from $792F to $A630, end to end, many graphic numbers sharing one;
widths 0-5 bytes, heights 0, 1, then 8 up; graphic 5 (the border's side) is
the only sprite one row high. The first sprite (`SPRITE0`) is the empty one
graphics 0 and 1 use. The sprite at $88B3, a wedge-shaped block, is reached
by no graphic number (`SPARE_SPRITEA`, [`leftovers.md`](leftovers.md)).
The sprites' pictures are on each sprite's entry in the HTML listing.

## How this was found

`UPDATES` decoded from the snapshot and each word matched to its entry
(stage 2, range 3; checked again for these notes); the templates and
backgrounds walked for the users of graphics 13-15 and 30
(`scripts/alien8_data.py`); no word in $5B00-$FFFF equals $BF42-$BF46 and
no graphic's entry points there (*searched*).

## Confidence

*Read*. What a creature is meant to be is not claimed from its name: the
listing names them by what they do.

## Knight Lore and Pentagram

The same scheme -- the graphic as the behaviour, short nudge routines --
with Alien 8's own numbers and values
([`../pentagram/graphic-numbers.md`](../pentagram/graphic-numbers.md)).

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `DRAW_AT_...` (twelve), `UNUSED_NUDGE_L12_D9` | `SUBBF3D` ... `SUBBF7E` | $BF3D-$BF7E | the nudges above |
| `CRYONAUT` | `SUBAE96` | $AE96 | graphic 74 |

## Open questions

- None of substance. Stage 1's "what draws graphic 131" is answered: the
  panel (stage 2, range 5, *measured* by drawing the panel with each entry
  knocked out in turn).
