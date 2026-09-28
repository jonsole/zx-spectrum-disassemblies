# Finds and bonuses

**Question this answers:** what the knight finds in buildings and lying in
the streets, where and when it appears, and what it does for him.

**Short answer:** every sixteen turns, a find -- an antibody of the kind the
cell type gives -- appears in the building the knight stands in, if that
type has stock left; it wanders about his cell while he is in it and is
given back to the stock if he leaves. A bonus -- graphic 2, a faster walk
for 255 turns, or 3, his three hits back -- is placed near him whenever
there is none, and goes when he is more than three cells away. In practice
there is nearly always one about.

## How it works

- **Finds made** (`SPAWN_FIND`, $C5CE, every 16th turn): not while he
  appears; a free `FINDS` record; the type of his cell has stock in
  `STOCKS` ($BBCE). Open ground has none, so finds come only in buildings.
  Graphic 48 + 4 x (type AND 3), a random place 64-191 across the cell, half-size 8;
  +5 keeps the type.
- **The stock** (`STOCK_BUILDINGS`, $C1DB, at every new game): types 2-35
  get 16-31 each, the low four bits of ROM bytes read from a random place
  in the first 4K, plus 16; shared by every cell of the type. (Type 2 is
  solid and one cell, so its stock is never used.)
- **A find** (`FIND_WANDER`, $D9A3, 48-63): if the knight is not alive, or
  has left the cell, it vanishes and goes back to the stock. Otherwise it
  wanders (`WANDER_STEP` with B = 4: up to 8 each way), animates, and at a
  touch is taken up as thing 5-8 and vanishes -- with all eleven places
  full it vanishes anyway and is lost, not returned.
- **Bonuses placed** (`PLACE_BONUS`, $D76C, every turn): when `BONUS` is
  empty it picks a column 0 or 4 to the right of the knight's (the random
  number's bits 0-2 masked with $FC) and a row from four above to three
  below his; unless that cell is solid or within one cell of him, the bonus
  goes there at a random place in the middle half of the cell, graphic 2
  on even turns and 3 on odd.
- **Bonuses kept** (`SPEED_BONUS` $D727, `HITS_BONUS` $D74C): a bonus lies
  only while he is within three cells both ways, so one placed four columns
  over, or four rows up, goes on its first update. In practice the bonus
  that lasts is in his own column two or three rows away, and there is one
  almost all the time (*measured*).
- **Bonuses taken**: graphic 2 sets `SPEED_TIME` 255 and `TOP_SPEED` 18,
  sound effect 1 for five turns ([`knight.md`](knight.md) for what the
  speed does); graphic 3 sets `HITS` to 3, sound effect 2 for seven turns.
  Drawn, graphic 3 is a flask.
- **A slip in the placing**: the row is wrapped to 0-31 only for the stored
  position; the map is looked up with the row unwrapped, so near the town's
  top or bottom edge the cell tested is read from outside the map, which may
  let a bonus into a solid cell or keep one out of an open one.

## How this was found

Read (stage 2, ranges 1 and 4). *Measured* in the simulator with the knight
moved to cell (16,16) by the game's own restart and pokes only at
`MAIN_LOOP`: the bonus record emptied 400 times, one turn run, the placement
noted, then one more turn to see whether it stayed. 70 tries placed nothing
(solid, or too near); of 330 placements, 185 were four columns over (all
gone after a turn), 66 four rows up in his column (all gone), and 54 two or
three rows away in his column (all stayed). Left alone standing still for
300 turns, a bonus was there in all 300.

## Confidence

*Read*; the placing and the near-permanent bonus *measured*, in one cell
and one run. The out-of-map look-up is *read*, not staged.

## Filmation (Knight Lore, Alien 8, Pentagram)

Nothing like either in the earlier games: none makes pick-ups appear
round the player on a timer, or takes them away when he walks off.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `SPAWN_FIND` | `SUBC5CE` | $C5CE | finds in buildings |
| `FIND_WANDER` | `SUBD9A3` | $D9A3 | graphics 48-63 |
| `SPEED_BONUS`, `HITS_BONUS` | `SUBD727`, `SUBD74C` | | graphics 2, 3 |
| `PLACE_BONUS` | `SUBD76C` | $D76C | every turn |

`STOCK_BUILDINGS` is stage 1's and stands.

## Open questions

- The column offset of 0 or 4 (`AND $07` then `AND $FC`) looks like a slip
  for the row's pattern (`AND $07`, `ADD A,$FC`): as written, the bonuses
  placed four columns over vanish the next turn.
- What graphic 2's picture is meant to be: stage 3's graphics pages.
- Which kind of antibody each cell type gives, over the town: a layer for
  stage 3's map.
