# Monsters

**Question this answers:** when and where monsters appear, what decides
their kind, what each of the two families does, and what they cost the
knight.

**Short answer:** every fourth turn, if one of the six `MONSTERS` records
is free, a monster starts appearing in the knight's cell or one of the
eight round it. After four turns it becomes either a wanderer (graphics
64-79) or a walker that steers (112-127), of the kind of the villain
nearest to it -- so each villain's part of the town has its own monsters.
Touching the knight, a monster takes one of his three hits; more than two
cells away, it is forgotten.

## How it works

- **Spawning** (`SPAWN_MONSTER`, $CDE8, every turn but in the ending): not
  while the knight appears; only when `TURNS`' bits 0-1 are both set; the
  first empty monster record gets `MONSTER_RECORD` ($CE79: graphic 128,
  speed 6, half-size 16). Column and row are the knight's, one more or one
  less, each by a third of the random number's low or high byte. A solid
  cell (types 1, 2): return. Otherwise a random place 32-223 across the
  cell each way; flags bit 5 when `TURNS`' low byte is under 128 (the
  monster will chase, [`movement.md`](movement.md)).
- **The stray** (a slip): the template is copied before the cell is
  tested, so a rejected spawn leaves graphic 128 in the record at U 0, V 0
  -- cell (0,0), which is solid. After its four turns of appearing, its own
  update finds it more than two cells from the knight and empties it. It
  only keeps a record from a real monster for about five turns.
- **Appearing** (`APPEARING_UPDATE`, $C164, 128-131): four turns with a
  rising note (`APPEAR_SOUND`); then the kind *k* = `NEAREST_VILLAIN`
  ($C19C: by columns plus rows apart, 3 for villain record 0 down to 0 for
  record 3; 3 with no villain left) and, by the random number, graphic
  64 + 4*k* or 112 + 4*k*. Graphic 76 gets a half-size of 24 in V.
- **Wanderers** (`WANDERING_MONSTER`, $CE89, 64-79): a random step now and
  then (`WANDER_STEP`, up to 14 each way), clipped an axis at a time
  (`MOVE_SPLIT`), moved, four frames (`NEXT_FRAME_MOD4`), mirrored with the
  view. More than two cells from the knight in column or row:
  `MONSTER_OUT_OF_RANGE`, emptied. Struck by an antibody (`MONSTER_SHOT`):
  both vanish, 500 points -- any kind of antibody will do. Touching the
  knight: 500 points as well, the monster vanishes, and
  `MONSTER_HITS_KNIGHT` ($CEBB) takes a hit; at none left,
  `KNIGHT_KILLED` ($CEC4).
- **Walkers** (`MONSTER112_UPDATE`, $C083, 112-127): walk at their speed,
  warble at a wall on the screen (`BUMP_SOUND`), steer (`STEER`), take their
  picture from their facing (`FACING_PICTURE`). Three cells or more away:
  forgotten (`MONSTER_TOO_FAR`, $C0D9). Touching the knight: 2500 points,
  it bursts, and he loses a hit. Struck by an antibody, the result depends
  on both kinds ([`antibodies-and-strikes.md`](antibodies-and-strikes.md)).
- **Hits**: `HITS` ($BBF3) is 3 at each life; the knight is coloured white,
  yellow, green at three, two, one (`KNIGHT_COLOURS`, $C065); the last hit
  ends the life. A villain's touch ends it at once, whatever his hits
  ([`quest.md`](quest.md)); the creature takes one hit, like a monster
  ([`creature.md`](creature.md)).
- **Points** show a hundred times what is added: 5 on the score prints as
  500 ([`menu-and-panel.md`](menu-and-panel.md)).

## How this was found

Read (stage 2, ranges 1 and 2). The stray *measured*: `SPAWN_MONSTER`
called with the knight's cell set to the corner, every neighbour solid,
left graphic 128 at U 0, V 0. A 3000-turn run with the knight standing
about saw 30 spawns, and only kinds 72 and 120 -- the nearest villain did
not change.

## Confidence

*Read*; the stray and the spawn rate *measured*. The step's range is
*read* from `RANDOM_STEP` with B = 7.

## Filmation (Knight Lore, Alien 8, Pentagram)

The earlier games' rooms hold a fixed set of creatures placed by the room's
template. Monsters spawning round the player on a timer, forgotten once
left behind, and taking their kind from the nearest villain have no
counterpart. `NEXT_FRAME_MOD4` is Alien 8's name (Knight Lore's
`next_graphic_no_mod_4`).

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `SPAWN_MONSTER` | `SUBCDE8` | $CDE8 | a monster appearing near the knight |
| `WANDERING_MONSTER` | `SUBCE89` | $CE89 | graphics 64-79 (entries `MONSTER_HITS_KNIGHT`, `KNIGHT_KILLED`, `MONSTER_SHOT`, `MONSTER_SCORE`, `MONSTER_OUT_OF_RANGE`) |
| `MONSTER112_UPDATE` | `SUBC083` | $C083 | graphics 112-127 |
| `MONSTER_TOO_FAR` | `SUBC0D9` | $C0D9 | forget a far monster |
| `APPEARING_UPDATE` | `SUBC164` | $C164 | graphics 128-131 |
| `NEAREST_VILLAIN`, `VILLAIN_DISTANCE` | `SUBC19C`, `SUBC1B9` | | the kind from the nearest villain |
| `CLEAR_MONSTERS` | `SUBC057` | $C057 | empty the six records (at each new life) |
| `NEXT_FRAME_MOD4` | `SUBCEF8` | $CEF8 | four frames round |

## Also found for the stage 3 pages (2026-09-28)

- Spawned monsters are often put inside a building's cell (only types 1 and 2 are refused), where they are never drawn and walk on the spot; standing still, the six records fill with these and nothing new appears (*measured*, the animations page).
- Near the top-left corner the stray from a refused spawn lives: it walks off the map to column or row 255, which the nearness test's byte subtraction counts as close (*measured*: 1463 of 1500 turns with three or four such records, knight in 1,1).
- A dying villain lasts seven or six turns, not eight: its frames step on odd turns only (*measured* in both parities).

## Open questions

- What the four kinds of each family look like, and which villain each
  belongs to (kind *k* comes from villain record 3 - *k*): stage 3's
  graphics and animation pages.
- How often the stray happens in play: only when a neighbour of the
  knight's cell is solid, which near the town's walls is often.
