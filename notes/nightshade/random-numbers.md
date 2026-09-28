# Random numbers

**Question this answers:** where the game's random numbers come from, and
how random they are.

**Short answer:** `RANDOM` ($BBAA), a word, is stirred after every record's
update and before most random choices: the low byte becomes R plus itself
plus the turn counter's low byte, and the high byte adds the counter's high
byte. Several routines also use it as an address and read the ROM's bytes
there as random numbers.

## How it works

- `NEXT_TURN` ($C5B4) counts `TURNS` on; `STIR_RANDOM` ($C5BB), the rest of
  it, is the stir. R counts the instructions run, which depends on
  everything the game has done, so the low byte is hard to predict; the
  high byte gets no carry from the low and adds only the counter's high
  byte -- the same step for 256 turns at a time.
- `TURNS` itself starts from the frozen FRAMES at every game
  ([`protection.md`](protection.md)), and the menu counts it on once a pass,
  so the time spent on the menu is what makes one game's start differ from
  another's.
- **The ROM as a table**: `STOCK_BUILDINGS` (bytes from the first 4K),
  `PLACE_OBJECTS` and `PLACE_VILLAINS` (pairs of bytes from the first 4K as
  a column and a row), `PUFF_SOUND` (pitches from the first 8K). The
  villains' hum reads the ROM too, by mistake ([`sound.md`](sound.md)).
- R is also read directly for some counts (`WANDER_STEP`'s new count, the
  top's pose length).

## How this was found

Read (stage 2, ranges 1 and 4).

## Confidence

*Read*. How evenly the choices fall was not measured.

## Filmation (Knight Lore, Alien 8, Pentagram)

The earlier games also stir a seed and read the ROM for pitches; stirring
with R after every record is Nightshade's.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `NEXT_TURN`, `STIR_RANDOM` | `SUBC5B4` | $C5B4, $C5BB | count a turn; stir |

## Disassembly corrections

- Stage 1's annotation said `RANDOM` is "stirred with R once a turn": it is
  stirred after every record's update, 23 times a turn in the loop alone,
  and before most random choices besides (range 1).

## Open questions

- Whether the high byte's fixed step makes the row choices (monsters,
  bonuses) visibly less random than the column choices. Not measured.
