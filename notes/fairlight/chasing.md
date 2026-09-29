# Chasing

**Question this answers:** how the creatures home in on the knight.

**Short answer:** a chaser keeps its course (+18) for a few passes and then
looks again: when its count (+15) runs out, `ZOOMIN` ($FC48, the author's
name) takes the knight -- or, for a state-9 guard, a decoy lying in the room
-- as its target, and `AIM_AT` ($FC66) points it along the one floor axis
the target is further off on, with the next look in 10 passes, or 3 when it
is close along z. So creatures walk in straight lines and turn corners; they
never walk diagonally at the knight.

## How it works

`STEER` ($F2F7, the author's ZZ1) takes one off +15 each pass and calls
`ZOOMIN` when it reaches 0. The chasers: states 6 and 10 (guards, within
30 of the knight), 7 (the troll), 9 (guards, always), 11 (the wraith) and
15 once woken ([`object-states.md`](object-states.md)).

`ZOOMIN` points IY at the target's record -- the knight's (`KNIGHT`, $BC90),
or `DECOY` when the chaser's state is 9 and bit 0 of `THINGS_NOTED` is set
(read by its address, as IY is not the variables just then) -- calls
`AIM_AT`, and sets IY back to $FF80.

`AIM_AT`: dx is the target's x plus 2 less the chaser's x, giving 8 (+x)
or 4 (-x); dz likewise, $40 (+z) or $80 (-z); the larger distance wins, z
on a tie; A is the direction, D the distance. +15 becomes 10, or 3 if |dz|
is under 14 -- the z distance even when x won.

## How this was found

Read (stage 2, ranges 4 and 5); the callers from $F2F2, $F311, $F35E and
$F3B9. The decoy target *measured* in room 20 ([`object-states.md`](object-states.md)).

## Confidence

*Read*; the decoy *measured* once.

## Krumlinde

His comment on $FC48 has it reached from the shared movement code ($FC40)
for every object; it is called only from `STEER`, the chasers' timer. He
did not identify the other target: the decoy, whose record `CHE3D` notes in
$FF8F.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `STEER` | `SUBF2F7` | $F2F7 | The author's ZZ1 |
| `ZOOMIN` | `SUBFC48` | $FC48 | Choose the target (the author's name) |
| `AIM_AT` | `SUBFC66` | $FC66 | Heading and distance to it |
| `DECOY` | `VARFF8F` | $FF8F | The decoy's record |
| `THINGS_NOTED` | `VARFF91` | $FF91 | A decoy, and the kind-11 thing, in the room |

## Open questions

- Whether the z-only test for the short re-aim is meant, or should have
  used the distance that won.
