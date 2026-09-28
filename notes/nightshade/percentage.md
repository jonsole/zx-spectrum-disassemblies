# The percentage

**Question this answers:** how the percentage shown after a game is worked
out, why exactly 100% is reachable, and whether 100 is shown right.

**Short answer:** one unit for every cell visited and three for each
villain destroyed, each unit worth 10288/65536 of one per cent, with 144
added at the end so that 637 units -- the 625 cells a knight can stand in
and 12 for the villains -- make exactly 100. But at 100 the print jumps past
the line that selects the digits, and the game shows three meaningless
characters instead of "100".

## How it works

- **Visiting** (`VISIT_CELL`, $BF48, from the knight's walk): a new cell
  becomes `LAST_CELL` ($BBF6) and its bit in `VISITED` ($BC0E: a byte for
  eight columns, four to a row, the column's low three bits the bit) is set
  by `MARK_VISITED` ($BF66), which writes the bit number into its own `BIT`
  and `SET` instructions. A newly visited cell with a building also starts
  sound effect 0. `NEW_LIFE` enters at `ENTER_CELL` ($BF56) to mark the
  cell a life starts in.
- **Counting** (`PERCENTAGE`, $BEDF, from `GAME_OVER`): the set bits of
  `VISITED`; plus three for each villain record not holding a live villain
  (96-111), so empty or dying; each unit adds 10288 to a 16-bit fraction,
  the carries counted in BCD with `DAA`; 144 more at the end. 637 x 10288 +
  144 = 100 x 65536. The result is in `PERCENT` ($BBFD, hundreds) and
  `PERCENT_LOW` ($BBFE).
- **Past 637** the BCD count wraps from 99 to 0 and loses its carry, so the
  count would start again -- impossible in play, since only 625 cells can
  be visited (setting all 1024 bits gave 62%).
- **The bug** (`PRINT_PERCENTAGE`, $BF36): under 100 it prints the two
  digits through the whole of `PRINT_BCD` ($C314), which first points
  `FONT_BASE` at the digits (`FONT`, $6CDE). At 100 it jumps to
  `PRINT_BCD_LOW` ($C327), past that instruction. `GAME_OVER` has just
  printed its text, leaving `FONT_BASE` at the text font's base, 384 bytes
  lower, where codes 0 and 1 are bytes of a building's graphics: three
  meaningless characters where "100" should be.

## How this was found

Read (stage 1 for the arithmetic, stage 2 range 1 for the print), then
*measured*: stage 1 set every standable cell's bit and destroyed the four
villains (100) and set all 1024 bits (62%); range 1 ran the build's quest
session (every standable cell visited, the four objects thrown at their
villains) to the instruction after the call in `GAME_OVER` -- `PERCENT` held
1 and 0, `FONT_BASE` the text font's, and the three character cells matched
no digit; the same call with `FONT_BASE` at the digits printed 100.

## Confidence

The arithmetic and the bug *read* and *measured* in SkoolKit's simulator.
That the real game shows the garbage is *inferred* from the simulator; not
yet seen live or on a real machine.

## Filmation (Knight Lore, Alien 8, Pentagram)

Pentagram's `PERCENTAGE` counts the parts of its quest
([`../pentagram/percentage.md`](../pentagram/percentage.md)); Knight Lore and
Alien 8 end with a rating of their own. A count of
every cell of a map, weighted to make exactly 100, is Nightshade's own.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `PERCENTAGE` | `SUBBEDF` | $BEDF | work out the percentage |
| `PRINT_PERCENTAGE` | `SUBBF36` | $BF36 | print it (wrong at 100) |
| `VISIT_CELL`, `ENTER_CELL`, `MARK_VISITED` | `SUBBF48` and new labels | $BF48, $BF56, $BF66 | mark a cell visited |
| `PRINT_BCD`, `PRINT_BCD_LOW` | `SUBC314` | $C314, $C327 | BCD digits |

## Open questions

- **The 100% garbage live** -- stage 3 is checking it in a private
  `zx_server` (the quest recipe in [`driving.md`](driving.md)), with a
  screenshot for the Bugs page.
- A poke that fixes it (pointing `FONT_BASE` at the digits before the jump)
  is a candidate for the Pokes page; not worked out.
