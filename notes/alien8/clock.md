# The light-years clock

**Question this answers:** how the light years on the panel count down, how
fast, and what happens at zero.

**Short answer:** `CLOCK` ($5B36) is four bytes, the highest digit first,
each a digit in bits 4-7 and, in bits 0-2, how far it still has to roll into
place. A new game sets 6000. Once a turn `RUN_CLOCK` ($AD66) takes a light
year off when the last digit has finished rolling, borrowing up the digits,
and rolls the changed digits down into place a row a turn, like a
mechanical counter: a light year goes every seven turns (*measured*), so
6000 is 42,000 turns. At zero the game is over.

## How it works

- **The count** (*read*): `CLOCK_BORROW` ($ADC9) acts only when the last
  digit's roll count is 0. It takes one off the last digit, borrowing up the
  digits (a 0 becomes 9 and the next digit up loses one), and gives each
  changed digit a roll count of 7. `ROLL_CLOCK` ($ADE5) takes one off the
  roll counts, from the last digit up, while they are rolling.
- **The picture**: the four digits are printed into the buffer with
  `FONT_BASE` set to the font itself ($6308, so digit n is character n) by
  `PRINT_ROLLING_DIGIT` ($ADB0), which prints the eight bytes starting
  `count` rows into the digit's character (`PRINT_GLYPH` $BBFA) -- so a
  changed digit first shows mostly the character after it and scrolls down
  into place. The font's code $3A, the eleventh character, is a second
  nought, so a 9 after a borrow rolls in from a nought (the text printer
  sees the same character as a colon). The last digit is drawn inverted, and
  the 32 by 8 pixels are copied to the screen.
- **The end**: all four bytes zero ends the game (`GAME_ENDED` $B761,
  [`chambers-and-summary.md`](chambers-and-summary.md)).
- **When it runs**: in the main loop after the turn's wait, and not while
  the scene after a game runs ([`main-loop.md`](main-loop.md)).
- **How long** (*inferred*, not timed): a quiet turn is padded to at least
  six units of about 20,000 T-states, about 120,000 T-states or a
  twenty-ninth of a second, so 42,000 turns is at least about 24 minutes of
  play; busier rooms make it longer.
- **Poking it** (*measured*): set anywhere in the turn, the borrow half-done
  can wrap the count round to 9s. Poke it at `RUN_CLOCK`'s start
  ([`driving.md`](driving.md)).

## How this was found

Read (stage 2, range 1); the rate *measured*: 67 light years in 470 turns
from a game start (7.01 turns each). The panel's look seen in a simulator
screenshot: the box, 5999 with the last digit inverted, the label in green
over a cyan room. Stage 1's session ran the clock out (poked to 0, 0, 0, 1 at
`RUN_CLOCK`) and reached the game-over scene.

## Confidence

*Read* and *measured* as above. The minutes are an estimate from the wait
loop's instruction counts.

## Knight Lore and Pentagram

The clock and its rolling digits are Alien 8's own (no match in
`matches.txt`); Knight Lore's panel shows the day count and the sun and
moon ([`../knightlore/day-and-night.md`](../knightlore/day-and-night.md)),
Pentagram has no time limit.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `RUN_CLOCK` | `SUBAD66` | $AD66 | tick, draw, end at zero |
| `PRINT_ROLLING_DIGIT` | `SUBADB0` | $ADB0 | a digit offset by its roll count |
| `CLOCK_BORROW` | `SUBADC9` | $ADC9 | a light year off |
| `ROLL_CLOCK` | `SUBADE5` | $ADE5 | the rolling digits a row on |

## Open questions

- None for the clock. The RET at $ADE4 (a borrow run past the first digit)
  never ran, and cannot while the game ends at zero.
