# The projection

**Question this answers:** how an object's place in the room becomes a
place on the screen.

**Short answer:** it is never computed from scratch. `ISO_MOVE` ($E4F7)
moves a record to a new x, y, z (+6, +7, +8) and moves its sprite's screen
position (+0, +1) by the projected difference: a step along +x moves the
sprite one pixel right and half a row up, along +z one pixel left and half
a row up, up in y one row up. So, give or take a constant, screen x is +6
less +8, and the row is (+6 plus +8) / 2 plus +7 -- the far corner of a room
at the top of the screen. The anchor is the template: a template's screen
position is right for an object standing at (50, 50 + its height, 50).

## How it works

`ISO_MOVE`: IX the record, B the new +6, D the new +7, H the new +8. Each
field's change is projected and added to +0 and +1. Half rows round towards
zero, and C remembers whether +6's half was rounded, so that two odd moves
the same way on +6 and +8 make a whole row between them; an odd move along
one axis alone would lose its half row.

Its callers:

- **Making a record** (`PLACE_FROM_TEMPLATE`, $EB4C): the record's place is
  first set to (50, 50 + its height, 50), where its template's screen
  position is drawn for, and moved from there to the object table's (or the
  room command's) place plus the room's origin, `ORIGIN` ($FFDF-$FFE1)
  ([`object-table.md`](object-table.md)).
- **Every committed step** (`COMMIT_STEP`, in $F65C): for the knight, the
  record is first put back to one fixed floor point (50, 78, 50) and its
  screen position there, and moved from that; everything else is moved from
  where it was ([`movement.md`](movement.md)).
- **A drop** ($F309) and **a door** ($F7C4), which move a record to where
  it lands or arrives.

## How this was found

Read (stage 2, range 1), then *measured*: walking in the simulator (Q, Y,
Q+Y, A+H), the knight's +6 and +8 change by 2 a step and his screen x by 2,
his row by 1. He never makes an odd move (every step is 2 on one axis or 1
on each of two, [`collision.md`](collision.md)), so the rounding never
loses him a row.

## Confidence

*Read* and *measured*. Why only the knight is re-projected from a fixed
point each step is *inferred*: the step-by-step conversion rounds, and he
moves most.

## Krumlinde

Agrees: his `RTN_Iso_Project` for $E4F7.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `ISO_MOVE` | `SUBE4F7` | $E4F7 | Move a record, and project the move |

## Open questions

- Whether any object other than the knight ever moves an odd amount along
  one floor axis alone, and so drifts half a row on the screen.
