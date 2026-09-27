# Monsters

**Question this answers:** where the creatures come from, how each kind
moves, what touching or shooting them does, and what the five big monsters
want.

**Short answer:** small creatures are not placed in the castle: they are
spawned into the player's room, up to three at a time, half a second after
arrival and then at random, and they wander, bounce off the walls and time
out once the player has left. Touching one costs 32 of the life force but
destroys it for 155 points, the same as shooting it. The five big monsters --
the mummy, Dracula, the devil, Frankenstein's monster and the humpback -- live
in fixed rooms, cannot be shot, drain 8 (the humpback 16) every pass they
touch you, and each has its own rule: the mummy guards the red key,
Dracula roams the halls and fears the crucifix, the spanner kills
Frankenstein, the humpback steals objects, and nothing stops the devil.

## How it works

**Spawning** (`SPAWN_MONSTER_INTO_ROOM` $83EA, *read*; *measured*). Called
once a frame from `PLAYER_TICK`, so only while the player is in play. A new
room resets `SPAWN_ROOM` ($5E26) and a 32-frame countdown (`SPAWN_COUNTDOWN`
$5E27); when it runs out a creature appears, and after that one appears on
any frame where the refresh register's low nibble is zero (1 in 16), if one
of the first three monster slots ($EE60, $EE70, $EE80) is free. The slot gets
`MONSTER_TEMPLATE` ($8B6A), the player's room, a type from `SPAWN_TYPES`
($8B7A) by FRAMES' low nibble, a position of $60 plus or minus a random
amount within the walk area less 8 (`RANDOM_POSITION` $8598), and a random
velocity. It shows as the arrival animation $58-$5B (`SPAWN_MONSTER` $85F7)
for 32 passes, then becomes its type. The sixteen entries of `SPAWN_TYPES`:

| Code | Creature (the annotations' names) | Chance in 16 | Mover |
|---|---|---|---|
| $5C | spider | 2 | `MOVE_ACTOR` $845F |
| $5E | a spiky creature (drawn 2026-09-27) | 2 | `MOVE_HOPPER` $8672 |
| $98 | bat, a third kind | 2 | `MOVE_FACING_FLYER` $8A80 |
| $90 | witch | 2 | `MOVE_WITCH` $8A2F |
| $94 | a cloaked figure | 2 | `MOVE_FACING_FLYER` |
| $60 | a small face with two eyes | 1 | `MOVE_FACE` $871A |
| $62 | ghost | 1 | `MOVE_GHOST` $87A6 |
| $4C | pumpkin | 1 | `MOVE_ACTOR` |
| $4E | bat | 1 | `MOVE_BAT` $862E |
| $68 | ghost, a second kind | 1 | `MOVE_HOPPER` |
| $6A | bat, a second kind | 1 | `MOVE_ARCS` $8301 |

Standing still in room $00 at the start of a game, five creatures reached
the player in ten seconds (*measured*).

**How the small ones move** (*read*). All bounce off the room's walk
rectangle through `STEP_ACTOR` ($84CD) and ignore doors and furniture, so they
never leave their room. Most animate by flipping bit 0 of the sprite. The
differences:

- pumpkin, spider (`MOVE_ACTOR`) and ghost (`MOVE_GHOST`): a random pair of
  direction bits every 16 passes (the ghost every 8), the velocity eased one
  step a pass towards +/-2;
- bat (`MOVE_BAT`): a new random velocity (1 or 2 each way, `RANDOM_VELOCITY`
  $86F2) every 256 passes;
- second bat (`MOVE_ARCS`): every 16 passes a random direction, then steps
  taken from `STEP_VECTORS` ($83CA) in order -- sixteen steps that swing from
  horizontal to vertical -- so it flies in arcs;
- spiky creature and second ghost (`MOVE_HOPPER`): a counter from -7 to 7
  halved into the vertical velocity, reset with a new random velocity each
  time it tops out: it hops;
- the face (`MOVE_FACE`): a new random velocity every 17 passes;
- witch (`MOVE_WITCH`) and the bat and cloaked figure of `MOVE_FACING_FLYER`: a new
  random velocity every 16 or 32 passes with the vertical part halved, and a
  picture facing the way they fly.

**Leaving them behind** (*read*): a small creature not in the player's room
only counts down its +$0F (`ACTOR_TICK_TIMER` $85F0), which it zeroes on
every pass in the room; 256 passes after the player leaves, about eleven
seconds, it is removed and its slot freed.

**Touch, shot and burst** (*read*; *measured*). Each small mover calls
`CHECK_SHOT_HIT` and `CHECK_HIT` ([`collision.md`](collision.md)). Caught:
`MONSTER_CAUGHT_PLAYER` ($85EA) takes 32 of the life force (`LOSE_FOOD_THIRTY_TWO`)
and jumps to `KILL_MONSTER` ($875F; `DRAW_MONSTER` before 2026-09-27). Shot: the same
kill. The kill erases the creature, turns it into the burst $6C-$6F for 16
passes (`COUNTDOWN_ACTOR` $8787) and adds 155 to the score; the burst ends in
`WEAPON_GONE` with its sound and frees the slot. In the simulator, a knight
left standing in room $00 lost 32 and gained 155 at each of five contacts.
And while the player is not in play -- sinking or rising -- every small
creature in the room is killed on its next move, with the 155 points: a
spider staged in the room burst as soon as the player started sinking, and
the score went up by 155 (*measured*). The humpback and the big four are
exempt from that test (the mask at $8530).

**The big five** (slots $EE90-$EED0, dispatched every pass wherever they
are; *read* unless marked). Each uses `HOME_IN` ($882D) -- velocity +/-1 per
axis towards a target, so a pixel a pass -- and a slightly smaller walk
rectangle. While the player is not in play, the four hunters turn their
velocity round and move away instead (`BIG_MONSTER_STEP` $89BB). None tests
for the weapon.

- **The mummy** (`MOVE_MUMMY` $8862), put in the red key's room by
  `PLACE_KEYS`. If object $80 is in its room it walks to it and, on reaching
  it, moves it to room $6B. Otherwise, while the red key is in its room, it
  walks back and forth between two points; once the key has gone it sets bit 7
  of +$06 and hunts the player for the rest of the game. Touch: 8 a pass.
- **Dracula** (`MOVE_DRACULA` $8906), starting in room $6D. Touch: 8 a pass.
  Carrying the yellow crucifix ($8A) makes him run from the player. In the
  player's room he hunts. Elsewhere, on a pass that falls in the frame when
  FRAMES is 0, he picks a random room 0-127 and moves there if it is a
  square, cave or octagonal room ($00-$02) and not the player's -- so he
  wanders the castle unseen.
- **Frankenstein's monster** (`MOVE_FRANKENSTEIN` $8988), room $55: hunts.
  Touched while the player carries the cyan spanner ($8B): 1000 points and the
  kill (155 more) -- and his slot is never refilled. Otherwise 8 a pass
  (*measured*: 1155 points and a burst with the spanner staged in the first
  inventory slot; with it absent, 90 units lost in 0.6 seconds and no kill).
- **The devil** (`MOVE_DEVIL` $89ED), room $43: hunts; 8 a pass; nothing in the
  code stops him.
- **The humpback** (`MOVE_HUMPBACK` $8AFF), room $56: if one of the eight
  collectables $82-$89 is in its room it walks to it and takes it (the
  record is emptied -- the object is gone for good); otherwise it stands
  still. Touch: 16 a pass (`LOSE_FOOD_SIXTEEN`). While the player is not in play it
  walks to the top of the room.

The hunters head for the player's x and y even from another room, so they
are wherever the player was last standing, relative to the room, when he
comes back (*read*).

## How this was found

Read the spawner, the handler table's creature runs, every mover, `HOME_IN`,
the kill and the burst. The spawning, contact, death-clearing and
Frankenstein results were measured in the simulator
(`aticatac_t5.py`, `t10.py`, `t12.py` in the scratchpad), staging records
directly in the monster slots.

## Confidence

The table of spawns is *read* from `SPAWN_TYPES`; the costs, the kills and the
spanner *measured*. The creature names are the annotations'; three were
looked at as drawn by the game's own sprite routine and described, not named.

## Renamed routines

Applied to the annotations on 2026-09-27; the build verified byte for byte.

| New name | Old name | Address | Role |
|---|---|---|---|
| `KILL_MONSTER` | `DRAW_MONSTER` | $875F | burst and 155 points |
| `RANDOM_POSITION` | `RANDOM_CHANCE` | $8598 | $60 plus or minus a random amount |
| `RANDOM_VELOCITY` | `RANDOM_VERTICAL` | $86F2 | a random velocity on both axes |
| `MOVE_HOPPER` | `MOVE_GHOST_ALT` | $8672 | the hopping movers |
| `MOVE_ARCS` | `MOVE_BAT_ALT` | $8301 | the second bat, along `STEP_VECTORS` |
| `ARC_STEP` | `VELOCITY_LOOKUP` | $83BA | its next step |
| `MOVE_FACE` | `MOVE_871A` | $871A | the small face |
| `MOVE_FACING_FLYER` | `MOVE_8A80` | $8A80 | the cloaked figure and the third bat |
| `LOSE_FOOD_EIGHT, LOSE_FOOD_SIXTEEN, LOSE_FOOD_THIRTY_TWO` | `LOSE_FOOD_8, LOSE_FOOD_16, LOSE_FOOD_32` | $8A1E, $8A15, $8ED7 | no label may end in a digit |
| `MUMMY_LURE, LIVE_MUMMY_LURE` | `COLLECTABLE_80, LIVE_COLLECTABLE_80` | $605D, $EAE0 | object $80 |
## Disassembly corrections

All applied to the annotations, the ref and the build on 2026-09-27 (the old names are used below), except where marked.

- `MONSTER_CAUGHT_PLAYER`: "Cost the player thirty-two and carry on ... then
  back into the creature's movement. Being caught is expensive but not, on
  its own, fatal." It jumps to the kill: the creature bursts and the player
  scores 155 (measured).
- `DRAW_MONSTER` ($875F) is the kill routine, not a draw.
- `MOVE_ACTOR` at $8530: the exempt kinds are exempt from being killed when
  the player is not in play; the comment does not say what the test does.
- `RANDOM_CHANCE`: "a yes or no with roughly known odds". It returns a
  coordinate: $60 plus or minus (R modulo the limit less 8).
- `RANDOM_VERTICAL`: "drops the result into the vertical velocity". It sets
  both velocities, each +/-1 or +/-2.
- `VELOCITY_LOOKUP` "Index a table by a creature's vertical speed": for the one
  creature that uses it, +$09 is a step counter 0-15 and bit 2 of +$08 swaps
  the axes.
- `MOVE_BAT_ALT`: "What it does differently from MOVE_BAT has not been
  established" -- it flies arcs (above).
- `LOSE_FOOD_8`: "What touching most monsters costs". It is the four big
  hunters; small creatures cost 32, the humpback 16.
- `MONSTER_TEMPLATE`: "+$02 holds $5C, the spider". The spawner always
  overwrites +$02 from `SPAWN_TYPES`; the template's value is never used.

## Open questions

- Room $6B, where the mummy sends object $80: whether anything is there for
  the player (not looked at).
- `MOVE_DRACULA` at $8952 stores the room centre as his target in +$0B/+$0C
  but calls `HOME_IN` with DE still holding the crucifix test's $468A, so
  off-screen he heads for x $8A, y $46. Harmless, since he is not drawn;
  a slip, or meant?
- The humpback's walk limits ($3C, 60) exceed the square hall's 56; whether it
  can be seen standing in a wall has not been checked.
