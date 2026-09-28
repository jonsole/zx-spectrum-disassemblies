# Movement and steering

**Question this answers:** how the things that are not the knight decide
which way to go and how far -- walkers that turn, wanderers that drift,
and the ones that make for the knight.

**Short answer:** a record's step comes either from its speed along its
facing (`SET_STEP`) or from a random two-way step (`WANDER_STEP`). Walkers
-- the villains and the monsters of 112-127 -- turn a quarter left or right
at random at a wall and every so often; a monster spawned in the first half
of a 256-turn cycle turns towards the knight instead. The villains never
chase. Wanderers -- finds and the monsters of 64-79 -- take a new random
step now and then. The creature steps straight at the knight.

## How it works

| Mover | Step | Walls | Turns |
|---|---|---|---|
| villains 96-111 (speed 4) | `SET_STEP` | `MOVE_CLIPPED` | `STEER`, at random only |
| monsters 112-127 (speed 6) | `SET_STEP` | `MOVE_CLIPPED` | `STEER`; towards the knight with flags bit 5 |
| monsters 64-79 | `WANDER_STEP`, B = 7 | `MOVE_SPLIT` | -- |
| finds 48-63 | `WANDER_STEP`, B = 4 | `MOVE_SPLIT` | -- |
| the creature 136-139 | `STEER_AT_KNIGHT` $C02C, two a turn each way | `MOVE_SPLIT` | -- |
| antibodies, thrown objects, sparkles (speed 12) | `SET_STEP` | twice a turn | none: they fly straight |
| the knight | [`knight.md`](knight.md) | | |

- **`SET_STEP`** ($DCE0): the speed (+5) into +A or +B by the facing's bit
  6, negated for bit 7. **`APPLY_STEP`** ($DD01) adds both (signed) to U
  and V -- after `MOVE_CLIPPED` has trimmed them ([`collision.md`](collision.md)).
- **`STEER`** ($DD28): stopped by a wall (flags bit 0), a quarter turn left
  or right at random, and a new count of up to 63 turns. Otherwise the
  count in the facing's low bits runs down, and when its low five bits
  reach 0 the same random turn -- or, with flags bit 5, a turn towards the
  knight: `KNIGHT_DIRECTION` ($DD99) gives the facing along the axis on
  which he is further away (0 +V, 1 +U, 2 -V, 3 -U, the facings' order),
  and `TURN_TO_KNIGHT_TABLE` ($DD6A), indexed by that less the present
  facing, keeps on (`STEER_ON`), turns left (`STEER_LEFT`) or right
  (`STEER_RIGHT`), or, when he is straight behind, either way at random
  (`STEER_EITHER`); a new count of 1-16.
- **Bit 5** is set only by `SPAWN_MONSTER` ($CDE8), for a monster spawned
  while `TURNS`' low byte is under 128. `VILLAIN_RECORD` has flags 0 and
  nothing sets the bit, so **the villains wander and never chase**; the
  monsters of 64-79 keep the bit but never look at it.
- **`WANDER_STEP`** ($DDCF): a new step when the count (the low six bits of
  +6) runs out or the step is 0 both ways. `RANDOM_STEP` ($DDFC) makes each
  part two for each 0 among B random bits, signed by the next bit: 0 to 2B
  either way, near B likeliest. A new count of 0-63 from R.
- **`MOVE_SPLIT`** ($DE0D): a two-way step clipped as a U move and then a V
  move, the facing set to each in turn; the facing ends as the V part's.
- **`FACING_PICTURE`** ($D978), for villains and the monsters of 112-127:
  bit 1 of the graphic for the facing (front for +V and -U), flipped with
  the view, bit 0 toggled each turn (two frames), and the mirror flag for
  the U facings.

## How this was found

Read (stage 2, range 4): the facing encoding from `SET_STEP`, checked
against `KNIGHT_DIRECTION` and `MOVE_SPLIT`'s choices. The villains' flags
from `VILLAIN_RECORD` and every write to +7 (range 5). Range 2 watched 30
spawns in a 3000-turn run.

## Confidence

*Read*. "The villains never chase" rests on reading every write to a
record's +7 (range 5) and the template.

## Filmation (Knight Lore, Alien 8, Pentagram)

The earlier games' movers are many kinds of scripted behaviour -- bouncers,
chasers that home in step by step, patrols -- each its own routine. Here
there are three shared movers (steer, wander, fly straight), a random step
built from coin flips, and a chase by quarter turns. `NEXT_FRAME_MOD4`
($CEF8) is Alien 8's name and job.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `SET_STEP`, `APPLY_STEP` | `SUBDCE0`, `SUBDD01` | $DCE0, $DD01 | step from speed and facing; the move |
| `STEER` | `SUBDD28` | $DD28 | turn at walls, at random, or towards the knight |
| `TURN_TO_KNIGHT_TABLE` | `STEP_TABLE` | $DD6A | renamed: its routines turn, they do not step |
| `STEER_EITHER`, `STEER_LEFT`, `STEER_ON`, `STEER_RIGHT` | `SUBDD72` and new labels | $DD72, $DD79, $DD81, $DD92 | the four turns |
| `KNIGHT_DIRECTION` | `SUBDD99` | $DD99 | the facing towards the knight |
| `WANDER_STEP`, `RANDOM_STEP` | `SUBDDCF`, `SUBDDFC` | | a random step now and then |
| `MOVE_SPLIT` | `SUBDE0D` | $DE0D | a two-way step, an axis at a time |
| `FACING_PICTURE` | `SUBD978` | $D978 | picture and mirror by facing |
| `NEXT_FRAME_MOD4` | `SUBCEF8` | $CEF8 | bits 0-1 of the graphic round |
| `STEER_AT_KNIGHT` | `SUBC02C` | $C02C | two units towards him on each axis |

## Disassembly corrections

- Stage 1 named $DD6A `STEP_TABLE`; its routines turn a chaser, so it is
  `TURN_TO_KNIGHT_TABLE` (range 4).

## Open questions

- The count in `STEER` is set on six bits and tested on five, so counts of
  32-63 run out after the count less 32; and the wall case ORs the new
  count into what is left of the old. Both look like slips, harmless.
