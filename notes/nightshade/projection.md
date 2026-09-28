# The projection and the turned-round view

**Question this answers:** how a position in the town becomes a place on
the screen, why the town scrolls, and what turning the town round (the Z
key) changes.

**Short answer:** everything is placed relative to the knight, so he stays
in the middle and the town moves under him: x = (dU + dV + $F0) / 2 and
y = (dV - dU + $1B0) / 4, y counting up the screen. Turned round, every
column, row and position is replaced by its distance from the far edge of
the town, and each building uses its other definition.

## How it works

- `PROJECT_CELL` ($D508) projects the corner of the cell last looked up
  (`CELL_LOOKED_UP`, $BBB4 column, $BBB5 row); `PROJECT_POINT` ($D515) any
  U and V; `PROJECT_THING` ($D4F3) an object record's +1 to +4. dU and dV
  are the distances from `KNIGHT_U` and `KNIGHT_V` ($BC8F, $BC91), 16-bit,
  256 units a cell. The results go to `DRAW_X` ($BBB6) and `DRAW_Y`
  ($BBB8), signed words; anything whose high byte is not 0 is not drawn.
- So U runs right and down the screen and V right and up. A cell is a
  diamond 256 pixels wide and 128 lines high -- bigger than the shown play
  area (176 by 112) -- and the knight's own point is at x 120, the middle of
  the shown part (x 32-207), and line 108.
- `LOOK_UP_CELL` ($D564): the type of the cell at column L, row H, from
  `TOWN`; Z for open ground; keeps the cell for the projection.
  `TOWN_CELL` ($E051) is the plain look-up the movement code uses.
- **The turned view** (`VIEW` bit 0, toggled by `TURN_TOWN`, $DB68):
  `TURN_CELL` ($D17D) maps column *c* to 31 - *c* and row *r* to 31 - *r*;
  `TURN_POSITION` ($D18E) maps a U or V to 8191 less it. Both are their own
  inverses. The drawing order works in turned terms throughout;
  `LOOK_UP_CELL` reads the map backwards (the offset complemented and added
  to the address one past the map's end -- written `TOWN+$0400` in the
  listing, since the plain address would be `DRAW_ORDER`);
  `LIST_THINGS_IN_CELL` turns the cell back to compare with the records,
  which always hold the town's own U and V; the projection turns the
  knight's and each thing's positions; the building table's index gains 1;
  the depth sort's index gains 9. The knight's look and the stick's
  directions are turned too ([`knight.md`](knight.md)), and the panel's
  heading says south instead of north ([`menu-and-panel.md`](menu-and-panel.md)).

## How this was found

Read (stage 2, range 3). Checked in the simulator: the knight's record at
the start of a game and the screenshots put walls and outlines where the
formula says; pressing Z turned the view (the compass reads the other way
and the walls change to the other definitions).

## Confidence

*Read* and *measured* (screens). The constants $F0 and $1B0 are read;
their meaning (the middle of the shown area, line 108) is worked out from
the buffer's layout.

## Filmation (Knight Lore, Alien 8, Pentagram)

Alien 8's projection (`$CFD2`) is x = U + V - 128, y = (V - U + 128) / 2 +
Z - 40. Nightshade's is the same at half the scale, measured from the
knight rather than a room's corner, and with no Z. The axes and "further
back is smaller U, larger V" are the same. Seeing the scene from the other
side has no counterpart: the earlier games' rooms are always seen one way.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `TURN_CELL`, `TURN_POSITION` | `SUBD17D`, `SUBD18E` | $D17D, $D18E | turned round with the town |
| `PROJECT_THING`, `PROJECT_CELL`, `PROJECT_POINT` | `SUBD4F3`, `SUBD508`, (new) | $D4F3, $D508, $D515 | places on the screen |
| `LOOK_UP_CELL` | `SUBD564` | $D564 | the type of a cell |

## Open questions

- None found here.
