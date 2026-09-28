# Bugs

**Question this answers:** what in the game does not do what it seems
meant to, and where each is argued.

**Short answer:** eleven, from a wrong 100% to a crash after 156 games. Each
is argued from the code in its topic file; most are *measured* in
SkoolKit's simulator, none yet *watched* live. The Bugs page is written
from this list.

## How it works

| Bug | What happens | Evidence | Where |
|---|---|---|---|
| 100% prints garbage | `PRINT_PERCENTAGE` jumps past the instruction that selects the digits: three meaningless characters for "100" | read, measured | [`percentage.md`](percentage.md) |
| the stack leak | two bytes lost at every game over, four at an ending; after 156 games `NMIADD` is overwritten and the game crashes | read, measured once | [`protection.md`](protection.md) |
| the split | `HIT_SPLITS` tests IY and reads IX: the copy lands over the first monster record, whatever it holds | read, measured | [`antibodies-and-strikes.md`](antibodies-and-strikes.md) |
| the second antibody | `ANTIBODY_STRIKE` never steps IY: a second antibody in flight passes through everything | read, measured | [`touching.md`](touching.md) |
| the villains' hum | the table's address lost and the offset keeps bit 5: ROM bytes $0080-$00BF instead of four tables | read, measured | [`sound.md`](sound.md) |
| the stray monster | a rejected spawn leaves a monster in cell (0,0) for five turns | read, measured | [`monsters.md`](monsters.md) |
| bonuses four columns over | the column offset is 0 or 4; those at 4 vanish the next turn | read, measured | [`finds-and-bonuses.md`](finds-and-bonuses.md) |
| the bonus row look-up | the row is wrapped only after the map look-up, so near the top and bottom the cell tested lies outside the map | read | [`finds-and-bonuses.md`](finds-and-bonuses.md) |
| `ATTR_SPILL` | a wall's colour runs one byte past the attribute buffer | read, measured | [`drawing-the-town.md`](drawing-the-town.md) |
| `STEER`'s count | set on six bits, tested on five; the wall case ORs into the old count | read | [`movement.md`](movement.md) |
| sprite run-on | a sprite drawn in a row's last byte continues into the row above's first, maybe visibly at the left edge | read, measured (not seen in play) | [`drawing-sprites.md`](drawing-sprites.md) |

Not bugs, though they look like them: effect 3's first note read from past
its table (it plays, as a squeak); a new game keeping the last death's
start flags (harmless, [`lives-and-starting.md`](lives-and-starting.md));
the start cell's uneven odds (by design or not, it works).

## How this was found

Stage 2's five ranges, each in its topic file; checked against the final
listing for these notes.

## Confidence

As in the table.

## Filmation (Knight Lore, Alien 8, Pentagram)

The villains' hum tables are the same 80 bytes Pentagram has, read the
same way; the others are Nightshade's own.

## Open questions

- **Stage 3 is checking live**: the 100% garbage (a screenshot) and the
  156-game crash, in a private `zx_server`.

Each of these was re-run for the published Bugs page, with two more found there (the stray monster near the top-left corner, the pick-up sound's first note), and the pokes tested: [`bugs-and-pokes.md`](bugs-and-pokes.md).
