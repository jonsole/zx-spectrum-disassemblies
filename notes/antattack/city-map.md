# The city map

**Question this answers:** how Antescher is stored, what is outside it, and
how the rest of the game reads and changes it.

**Short answer:** the city is 128 x 128 cells at `CITY_MAP` ($C000-$FFFF),
one byte a cell and one bit a height: bit 0 a block on the ground up to bit 5
a block five up. Any combination is allowed, so arches, bridges and floating
walkways are just cells with a gap in their bits. Coordinates run $80-$FF;
the game's arithmetic is 8-bit and wraps, so the world is really 256 x 256
cells with the city in one quarter and open, empty ground everywhere else.
The five ants are bits in this map too, moved as they walk.

## How it works

**Addressing** (*read*, `READ_MAP_CELL` $8380, `TEST_MAP_BIT` $8920,
`TOGGLE_MAP_BIT` $8940): cell (x, y) is at $C000 + 128(y - $80) + (x - $80).
Each routine first tests bit 7 of x and of y; if either is clear the cell is
outside and reads as empty (and `TOGGLE_MAP_BIT` writes nothing). Rows are
entries of their own in the listing from 2026-09-27: `CITY_Y81` at $C080 up
to `CITY_YFF` at $FF80, the first row keeping the label `CITY_MAP`.

**Heights** (`TEST_MAP_BIT`, *read*):

| Height asked | Answer |
|---|---|
| -1 ($FF) | solid: the ground holds everything up |
| 0-5 | the cell's bit |
| 6 | empty: the open air above the tallest block |
| 7 and above | solid: a ceiling |

So an object can stand on top of a six-high column (at height 6) but cannot
jump from there (`RISE` tests 7). Outside the walls every height is empty,
but -1 still holds things up, since the height test comes before the
outside test.

**The world wraps.** Positions are single bytes and every difference is taken
mod 256 (`DISTANCE`, `PROJECT_SPRITES`, the view origin). So the ground
outside runs from $00 to $7F in both directions and meets the city's far
edges. The player's home, the gate, is x $B9, y $04 -- five cells past the
city's y = $FF edge. Walking y-down from there takes y through $00 to $FF and
into the city: in the simulator the player walked from y $02 to $FB and
stopped against a wall (*measured*, 2026-09-27). Nothing solid is out there,
so anyone -- ants included -- can walk anywhere outside; the grenade's home at
(0, $40) is out there too ([`grenades.md`](grenades.md)).

**The walls and the gate** (*read* from the map, 2026-09-27): every cell on
the city's four edges has blocks at heights 0 and 1 at least -- a wall two
or more high that nobody can jump -- except a gap of fourteen empty cells on the y = $FF edge, x $AE to $BB -- the gate. The gate
opens onto a short court: a height-5 wall stands at y $FA straight in front of
the player's home column.

**What is in it** (*read*, counted from the snapshot): 5560 blocks in 16384
cells; 13882 cells empty; 836 cells have a gap below some block (arches,
lintels, bridges) and 723 have their lowest block above the ground. Every
place the person to be rescued waits is a free cell at the given height with
a block, the ground or nothing directly below -- some of them on
walkways six high. The City page draws the whole map from above (with the
waiting places ringed) and in the game's own projection, with the block
`DRAW_BLOCK` paints; the Levels page lists the places.

**The map changes during play.** `MOVE_ANT` XORs each ant's height bit out of
its cell before moving it and back in where it ends up, so everything else
collides with ants exactly as with walls ([`ants.md`](ants.md)). After a
second of play the map differed from the tape in exactly five cells, the five
ants' (*measured*, simulator, 2026-09-27). The XOR is also why the ants'
positions must never be set without moving their bits
([`movement-and-collision.md`](movement-and-collision.md)).

**Who reads it:** `GATHER_VIEW` (through `READ_MAP_CELL`) for drawing, 672
cells a frame; `TEST_MAP_BIT` for every move (standing, bites, walking,
climbing); `TEST_BELOW` adds the other person as something to stand on.
**Who writes it:** only `TOGGLE_MAP_BIT`, for the ants (*read*: no other
store into $C000-$FFFF in the code).

## How this was found

The addressing and height rules are read from the three map routines. The
edge, gate and cell counts were computed from the loaded snapshot with a
scratch script on 2026-09-27; the wrap was seen when the simulator's player,
walking from the gate, arrived inside at y $FB.

## Confidence

*Read*, and the counts *measured* from the snapshot. The walk through the
gate ran in the simulator, not live. That the gate is the only gap is
*read* for the four edges only; whether any inner wall can be climbed round
from outside was not looked at.

## Open questions

- Whether the ants ever leave the city in play, and what they do outside
  where nothing blocks them (nothing in the code stops them; not observed).
- A few cells hold bits that look out of place -- the fast ant's home cell has
  a ground block under the roof of the ants' row ([`ants.md`](ants.md)).
  Whether any other stray bits are ants left in the map when the tape was
  saved has not been checked.
