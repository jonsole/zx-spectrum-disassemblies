# Antibodies and what they do

**Question this answers:** what an antibody does when it strikes a monster
or the creature, and why the kind of antibody matters.

**Short answer:** finds, taken up, are antibodies of four kinds; thrown,
one flies straight at speed 12, twice a turn, until it hits a wall or a
target. A wanderer (64-79) or the creature dies to any kind. A walker
(112-127) is destroyed, changed, split or demoted according to its kind
plus the antibody's, mod 4: each villain's walkers die to one kind of
antibody. The split does not do what it was meant to, and the second
antibody record never strikes anything.

## How it works

- **The kinds.** A find is made of the kind given by its cell type's low
  two bits (`SPAWN_FIND`, $C5CE); taken up it is thing 5 + *k*
  (`PICK_UP_FIND`, $C481); thrown it is graphic 80 + 4*k*
  (`KNIGHT_THROWS`). The panel colours the four magenta, green, cyan and
  yellow ([`carrying.md`](carrying.md)).
- **In flight** (`ANTIBODY_FLIGHT`, $D7ED, 80-95): `SET_STEP`, then
  `MOVE_CLIPPED` and `MOVE_CLIPPED_AGAIN`, each followed by the move, so it
  goes 24 units a turn; a wall makes it burst. One facing a close wall
  bursts in the turn it is thrown, unseen. It is the target's update that
  looks for it (`ANTIBODY_STRIKE`, [`touching.md`](touching.md)), and only
  the first antibody record is ever found.
- **A walker struck** (`MONSTER112_UPDATE`, $C083): its kind is bits 2-3 of
  its graphic, the antibody's the same bits of its own; `STRIKE_OUTCOME`
  ($C0B9) adds them, mod 4, into `MONSTER_HIT_TABLE` ($C0D1). The antibody
  bursts in every case (`ANTIBODY_SPENT`, $C0E8).

| Sum | Routine | The monster | Points |
|---|---|---|---|
| 0 | `HIT_DESTROYS` $C0DE | bursts | 2500 |
| 1 | `HIT_CHANGES` $C0ED | the next kind round, 124-127 to 112-115, its frame kept | 2000 |
| 2 | `HIT_SPLITS` $C101 | copied (see below) | 1500 |
| 3 | `HIT_DEMOTES` $C152 | graphic 64 or 68, by bit 2 of its own: a wanderer any antibody kills | 1000 |

  A villain in record *n* brings monsters of kind 3 - *n*, so its walkers
  are destroyed by antibodies of kind (*n* + 1) mod 4 -- from the cells of
  types whose low bits are that.
- **The split** (a bug). Meant, by the look of it, to copy the monster into
  an empty monster record and send the two off at right angles. Its search
  tests IY for an empty record, but IY is the antibody's record and then
  the records after it -- the second antibody, the finds, the bonus -- while
  the nearness test reads IX, which stays on the first monster record. So
  the struck monster is copied over the first monster record, whatever is
  there -- another monster, the creature -- if that record is not within a
  cell of the knight, or, if it is, when any of the five records after the
  antibody's is empty. Only when none is does no copy happen (the branch at
  $C121, which no build session reached). A monster already in the first
  record copies itself onto itself, its facing turned one way and back: no
  split. 1500 points in every case.
- **A wanderer struck** (`WANDERING_MONSTER`): both vanish, 500.
- **The creature struck** (`CREATURE_UPDATE`): both burst, 1000.
- **Villains** are not struck by antibodies at all: only their own object
  hurts them ([`quest.md`](quest.md)).

## How this was found

Read (stage 2, range 1). The split *measured* by calling it in the
simulator with a monster in the fourth record: a monster far off in the
first was replaced by the copy; with one beside the knight in the first and
the second antibody record empty, the same; with it beside him and the five
records after the antibody's all busy, no copy and 1500 all the same. The
build's "finds and antibodies" session throws each kind of antibody at a
walker, and one each at a wanderer and at the creature.

## Confidence

The kind arithmetic *read*; the split's behaviour *measured*. That the
split is a slip, not a design, is *inferred*: a copy that destroys another
monster, or the creature, and depends on whether a find happens to be
lying about, cannot have been meant.

## Filmation (Knight Lore, Alien 8, Pentagram)

Knight Lore's and Alien 8's player cannot harm anything; Pentagram's
wizard throws bolts ([`../pentagram/bolts-and-sky.md`](../pentagram/bolts-and-sky.md)).
None of them has projectiles of different kinds, or decides a hit's result
from two kinds.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `ANTIBODY_FLIGHT` | `SUBD7ED` | $D7ED | an antibody in flight |
| `STRIKE_OUTCOME`, `ANTIBODY_SPENT` | (entry points) | $C0B9, $C0E8 | kinds to outcome; the antibody bursts |
| `HIT_DESTROYS`, `HIT_CHANGES`, `HIT_SPLITS`, `HIT_DEMOTES` | `SUBC0DE`, `SUBC0ED`, `SUBC101`, `SUBC152` | | the four outcomes |
| `PICK_UP_FIND` | `SUBC481` | $C481 | a find's antibody kind |

`MONSTER_HIT_TABLE` is stage 1's and stands.

## Disassembly corrections

- Stage 1's journal said a strike on a monster of 112-127 "may kill,
  change or split it (`$C0D1`)". There are four outcomes, the fourth
  turning it into a wanderer, and the "split" copies over the first
  monster record (range 1, *measured*).

## Open questions

- How often, in real play, a split wipes out another monster or the
  creature.
- A fix (the search stepping IX through the monster records) is a
  candidate for the Pokes page; not worked out or tested.
