# The status panel, the clock and the score

**Question this answers:** what is on the parchment scroll down the right of
the screen, how each part is kept up to date, and where points come from.

**Short answer:** the scroll is a 94-character tile set laid out 8 by 24 at
x 192 once per game; over it go the inventory, the clock (hours, minutes,
seconds since the game began), the six-digit score, the roast that shows the
life force, and the spare lives. Its colour is the room's ink inverted. Points
come from two places only: 155 for every small creature destroyed, and 1000
more for Frankenstein's monster killed with the spanner. The end screens add
a percentage of the castle seen, scaled so that all 149 rooms make 99.

## How it works

**The scroll** (`DRAW_SCROLL` $A219, *read*): points the tile source at
`PANEL_TILES` ($B03A) and plots the 192 tile numbers of `PANEL_LAYOUT` ($B32A)
from x $C0, then draws the score. Only `START_GAME` calls it; nothing redraws
the scroll during a game.

**Its colour** (`PAINT_PANEL` $A240, *read*; the annotation's measurement):
every room change fills the panel's attributes with the room colour's ink
complemented (red room, cyan scroll), bright green where that would be black
or blue, then colours a few fixed areas: two small blocks in the room's own
colour, and fixed bands six cells wide: magenta at character row 7, white
at 8, cyan at 9, white at 10, yellow at 11-14 and white at 15-17.

**What is drawn on it** (*read*; positions are x, y of the drawing routine):

| Item | Routine | Where | When |
|---|---|---|---|
| inventory, three slots 16 px apart | `DRAW_INVENTORY` $A13B | $C8, $2C | room change, pick-up, drop |
| clock, h mm : ss | `TICK_CLOCK` $95DA -> `PRINT_CLOCK` $9607 | $C8, $40 | each second |
| score, six digits | `ADD_SCORE` $A19C / `DRAW_SCORE` $A1AE | $C8, $50 | when points are added |
| roast | `DRAW_FOOD` $8B8A | $C8, $77 | when the life force crosses a multiple of 8 |
| spare lives, up to three | `DRAW_LIVES` $A2CE | $C8, $8D | start of each life |

The clock counts up from 0:00:00 at `START_GAME` ([`main-loop.md`](main-loop.md));
it stops while paused. The score is three BCD bytes at `SCORE` ($5E2A-$5E2C).
The roast is the whole-roast picture ($B4) with rows removed from its top, one
eighth of the life force at a time, drawn over the picked-bones picture
($B5): `DRAW_FOOD` moves the roast's `SPRITE_TABLE` entry and shortens the
two pictures' height bytes for the draw and puts them back -- 30 steps from
240 to 0. At the start of every life `FLASH_SCORE` ($8C8C) sets the flash bit
of the score's six cells for 104 frames, with a pip every sixteenth
([`player.md`](player.md)).

**Points** (*read*; *measured*): `ADD_SCORE` has two callers. `KILL_MONSTER`
($877E) adds 155 whenever a small creature is destroyed -- shot, touched, or
wiped out while the player sinks or rises -- and `MOVE_FRANKENSTEIN` ($899C)
adds 1000 when he is killed, on top of the kill's 155. Nothing else scores:
not objects, keys, rooms or escaping. In the simulator: five touches, 775
points; the spanner kill, 1155.

**The end-of-game figures** (`DRAW_SUMMARY` $9641, *read*): three lines at the
left of the cleared play area, after GAME OVER or the congratulations: TIME
with the clock, SCORE with the score, and a percent sign with
`COUNT_ROOMS_EXPLORED`'s figure -- two for every three rooms whose bit is set
in `ROOMS_SEEN`, plus one, in BCD, so 149 rooms give 99. (In this font the
character "#" is drawn as a colon and "$" as a percent sign; the labels use
them.)

## How this was found

Read the routines above; the panel's layout was established when the build's
graphics page was made (2026-08-30: the "title picture" turned out to be this
scroll -- [`journal.md`](journal.md)). The font's "#", "$" and "%" were drawn
from `TEXT_FONT` in the simulator's memory on 2026-09-27.

## Confidence

*Read*, with the score sources *measured*.

## Renamed routines

Applied to the annotations on 2026-09-27; the build verified byte for byte.

| New name | Old name | Address | Role |
|---|---|---|---|
| `PERCENT_LABEL` | `TIME_LABEL` | $969F | the percentage line |
| `SOUND_LIFE_PIP` | `SOUND_BONUS` | $A3E0 | the pip during the score's flash |

## Disassembly corrections

All applied to the annotations, the ref and the build on 2026-09-27 (the old names are used below), except where marked.

- The labels at $968F and $969F: `SCORE_LABEL` is right, but `TIME_LABEL`
  ($969F) is the percentage line; the TIME label is the first, at
  `END_LABELS` ($967F).
- `COUNT_ROOMS_EXPLORED` and `DRAW_SUMMARY` do not mention that the figure is
  shown with a percent sign -- it is a percentage.
- `FLASH_SCORE` does not say when it runs: at the start of every life, from
  `MATERIALISING`, for the 104 frames `PLACE_PLAYER` sets.

## Open questions

- None.
