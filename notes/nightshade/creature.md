# The creature

**Question this answers:** where the creature of graphics 136-139 comes
from, what it does, and how to be rid of it.

**Short answer:** every 256 turns it is put in the knight's own cell, in
the first monster record not in or next to his cell -- replacing whatever
monster was there. It steps straight at him two units a turn on each axis,
blipping while on the screen; led into a wall it bursts for 1000 points,
an antibody bursts it for 1000, and touching him it bursts and takes a
hit. Left more than two cells behind, it is forgotten.

## How it works

- **`SPAWN_CREATURE`** ($BF95, from the main loop): when `TURNS`' low byte
  comes round to 0, the first of the six monster records that is not within
  a cell of the knight (`NEAR_KNIGHT`, C = 2) becomes graphic 136 in his
  cell, at a random place 64-191 across it each way, half-size 16 -- empty
  or not: a monster further off is simply replaced. If that place already
  touches him it is a harmless puff (graphic 12) instead. If all six are
  within a cell of him, the first becomes the creature wherever it is, with
  only its graphic changed.
- **`CREATURE_UPDATE`** ($BFF1, 136-139): `BLIP_BY_TURN` ($C332) if it was
  drawn last turn; `STEER_AT_KNIGHT` ($C02C) sets its steps to +2 or -2 on
  each axis towards him; `MOVE_SPLIT` clips them; then:
  - stopped by a wall: it bursts, 1000 points -- the reward for leading it
    into one;
  - more than two cells from him in column or row: the record is emptied
    (the branch at $C019, which no build session reached);
  - struck by an antibody (the first antibody record only): both burst,
    1000;
  - touching him: it bursts and takes one of his hits
    (`MONSTER_HITS_KNIGHT`, $CEBB).

## How this was found

Read (stage 2, range 1), then *measured* in the simulator: in a game left
running, a monster record held the creature every time the turn counter's
low byte was 0; with all six records empty (so at cell (0,0)) beside a
knight in cell (1,1), the first record got graphic 136 and nothing else;
the creature put five columns away was emptied by its own update, running
$C019 for the first time.

## Confidence

The timing, the fallback and the "left behind" branch *measured*; the
rest *read*.

## Filmation (Knight Lore, Alien 8, Pentagram)

Knight Lore's sparks home in on Sabreman (`spark_home_in`), and Alien 8's
spark chaser moves four a turn; this one moves two a turn on each axis and
can be killed by walking it into a wall. Its blip is Pentagram's
`BLIP_BY_TURN`, which Pentagram itself never calls.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `SPAWN_CREATURE` | `SUBBF95` | $BF95 | every 256 turns |
| `CREATURE_UPDATE` | `SUBBFF1` | $BFF1 | graphics 136-139 |
| `STEER_AT_KNIGHT` | `SUBC02C` | $C02C | steps of two towards him |

## Disassembly corrections

- Stage 1's journal listed `$C019` as "a strike on the creature ... that the
  session's stage did not reach". It is the creature left behind, more than
  two cells from the knight, not a strike (range 1, *measured*).

## Open questions

- What the creature is meant to be: the build's session code calls it a
  ghost, which is a guess from its picture; the game's text does not name
  it. Stage 3's graphics pages draw it; the inlay, if found, may name it.
