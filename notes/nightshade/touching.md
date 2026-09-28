# Touching

**Question this answers:** how the game decides two things touch, and who
is tested against whom.

**Short answer:** one overlap test, `TOUCH_TEST` ($C572), on the full 16-bit
positions: the first record's half-size plus half the second's, on both
axes. Each update routine tests only the pairs that matter to it: the
knight, the first antibody record, or its own villain. The antibody test
means to try both antibody records and tries the first one twice.

## How it works

| Test | Address | Who calls it | Tests IX against |
|---|---|---|---|
| `TOUCHING_KNIGHT` | $C55F | objects lying, finds, bonuses, villains, all monsters, the creature | the knight's legs -- never while `ARRIVING` is short of $70, nor unless his legs are 16-47 |
| `ANTIBODY_STRIKE` | $C538 | the creature, both kinds of monster | the antibody records (in intent), via `ANTIBODY_TOUCHING` $C54A |
| `OBJECT_STRIKE` | $C554 | a thrown object | the record 64 bytes on: its own villain |
| `TOUCH_TEST` | $C572 | the three above | -- |
| `NEAR_KNIGHT` | $C069 | spawning, forgetting, bonuses, the panel's hint | a coarse test by cells: both differences under C |

- **`TOUCH_TEST`**: along U, |IX's U - IY's U| < IX's half-size + half of
  IY's; the same along V; carry if both. The positions carry the cell, so
  things meet across the line between cells.
- **The second antibody is harmless** (a bug): `ANTIBODY_STRIKE` loads DE
  with 16, a record's size, and never adds it to IY, so the first antibody
  record is tried twice and the second never. An antibody thrown while the
  first is still flying (it takes the second record, `KNIGHT_THROWS`) passes
  through monsters and the creature.
- **The pairs** of objects and villains are fixed by record order: object
  record *n* ($BD1E + 16*n*) against villain record *n* ($BD5E + 16*n*), and
  nothing else ([`quest.md`](quest.md)).
- Nothing tests a monster against a villain, an antibody against a
  villain, or an object against a monster: those pass through each other.

## How this was found

Read (stage 2, range 1); the antibody bug *measured*: an antibody placed on
a monster in the first record gave carry, in the second none, IY still on
the first.

## Confidence

*Read* and *measured*. Why the second half-size is halved: not known.

## Filmation (Knight Lore, Alien 8, Pentagram)

The earlier games find what a mover meets inside the collision code
itself, in three dimensions, and pass harm through flag bits. Nightshade's
harm is decided by whoever runs the test, in two dimensions, on the town's
coordinates.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `ANTIBODY_STRIKE`, `ANTIBODY_TOUCHING` | `SUBC538`, `SUBC54A` | $C538, $C54A | struck by an antibody? |
| `OBJECT_STRIKE` | `SUBC554` | $C554 | a thrown object and its villain |
| `TOUCHING_KNIGHT`, `TOUCH_TEST` | `SUBC55F` | $C55F, $C572 | the overlap test |
| `NEAR_KNIGHT` | `SUBC069` | $C069 | within C cells? |

## Open questions

- Was the halved second half-size deliberate -- a smaller target for the
  knight, say? The callers put the knight or the antibody in IY, so the
  thing being hit reaches further than the thing hitting it.
