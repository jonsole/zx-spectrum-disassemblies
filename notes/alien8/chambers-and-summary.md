# The chambers, the ending and the summary

**Question this answers:** how a chamber is activated, how the game ends --
won or lost -- and how the summary after a game counts the chambers and the
crew and picks a rating.

**Short answer:** a valve seated on its socket activates the chamber: the
screen's inks cycle, the room turns white for the rest of the game, and
`CHAMBERS` ($5B40) counts one up in BCD; the twenty-fourth sets `WON`
($5B23) and ends the game. A game ends in `GAME_ENDED` ($B761) -- from the
last life, the clock, or the twenty-fourth chamber -- which puts the room's
valves back, shows the arrival screen first if the game was won, then the
summary: chambers activated and not, the frozen crew lost in the ones not
activated, and a rating from the rooms seen and whether the game was won --
Knight Lore's rule and words exactly. Then a scene runs in the main loop
([`scenes.md`](scenes.md)) and the menu comes back.

## How it works

**Activating** (the end of `LOOSE_VALVE` $AF79, *read*): the valve's graphic
+ 4 (100-103, seated), a sound; sixteen passes of every attribute's ink one
on, each with a sparkle's sound (`SPARKLE_SOUND` $B5EE) and a pause -- the
inks run through all eight colours twice and end where they were; white (7)
written into the room record's ink through `ROOM_COLOUR_AT` ($5B34) and into
`ROOM_INK`; `COLOUR_PANEL` ($A749) recolours the screen and the panel;
`CHAMBERS` + 1 in BCD. At $24 `WON` is set and `GAME_ENDED` runs; otherwise
`PRINT_CHAMBERS` ($A7A3) prints the count and `BLIT_2X8` copies it out. The
room stays white until the next game's `RESET_ROOM_COLOURS`.

**The chambers.** 24 rooms, each with one socket (object templates 24-27)
and its frozen crew, the cryonauts -- object templates 21 and 22, graphic 74,
`CRYONAUT` ($AE96), a drawing nudge only -- 132 of them in all (*read* from
the data; *measured*, below). The rooms by kind are in
[`valves-and-sockets.md`](valves-and-sockets.md).

```
NEW_LIFE $CA07 (no life to take) / RUN_CLOCK $AD66 (zero) / LOOSE_VALVE (the 24th)
  GAME_ENDED $B761     UPDATE_SPECIAL_OBJS $AF05: the room's valves back to their places
    WON?  ARRIVAL_SCREEN $B8A9: a text list (ARRIVAL_COLOURS $B8D0 ...), TUNE_ARRIVAL,
          WAIT_KEY_OR_TIME 8
  SUMMARY_SCREEN $B76B the list at SUMMARY_COLOURS $B94F; the rating (PRINT_TEXT);
                       SUMMARISE_CHAMBERS $AC6B; PRINT_SUMMARY_COUNTS $BA36;
                       PRINT_BORDER, SHOW_BUFFER; TUNE_GAME_OVER until a key;
                       WAIT_KEY_OR_TIME 8 (about 14 s)
  GAME_OVER = 1; CLEAR_OBJECTS; SET_UP_SCENE $B804 from SCENE_LOST $B82A (with the
  flashing REPROGRAMMING text, $B7F5) or SCENE_WON $B853; NEW_ROOM = 1;
  into the main loop -> the scene's routines -> AFTER_GAME $A647 -> the menu
```

- **The counts** (`SUMMARISE_CHAMBERS` $AC6B, *read*): it walks the room
  directory; a room whose first groups after the backgrounds are templates
  21 or 22 (the crew) is a chamber. If a place in that room holds a seated
  valve (graphics 100-103) the chamber counts as activated
  (`SUMMARY_ACTIVE`, $5B3E); otherwise as not (`SUMMARY_IDLE`, $5B3F), and
  the counts of its crew groups are added to `SUMMARY_LOST` ($5B3C, a BCD
  word, high byte first). `GAME_ENDED` puts the room's valves back first so
  a chamber activated in the last room counts.
- **The summary screen** (*read*): seven lines (`SUMMARY_COLOURS` $B94F,
  `SUMMARY_XY` $B956, `SUMMARY_TEXT` $B964): the title in white, the
  activated chambers' lines in yellow, the unactivated in cyan, the crew
  lost in magenta, the rating's heading in green. The game spells the crew
  "cryonaughts". `PRINT_SUMMARY_COUNTS` prints `SUMMARY_ACTIVE` at (184,
  127) and `SUMMARY_IDLE` at (184, 95), two digits each, and the last three
  digits of `SUMMARY_LOST` at (176, 79), over spaces the text leaves for
  them.
- **The rating** (*read*): `COUNT_ROOMS_SEEN` ($B881) counts the bits of
  `ROOMS_SEEN` ($5B58, set by `MARK_ROOM_SEEN` $B863 on entering a room,
  through a self-modified SET) and returns the count less one; bits 5-6 of
  that give 0-3 (up to 32 rooms seen, 64, 96, more) and `WON` adds 4. The
  index picks one of eight strings through `RATINGS` ($B9DD): poor, average,
  fair, good for a lost game; excellent, marvellous, hero, adventurer for a
  won one -- average below fair, as in Knight Lore. Each starts with its
  colour byte, bright white, and is printed at (88, 39) by `PRINT_TEXT`
  ($BBB1).
- **The arrival screen** (`ARRIVAL_SCREEN` $B8A9, a won game only): a text
  list from `ARRIVAL_COLOURS` ($B8D0), `ARRIVAL_XY` ($B8D7) and
  `ARRIVAL_TEXT` ($B8E5) -- the arrival text -- `TUNE_ARRIVAL`, and a
  wait for a key or the time. It clears `TEXT_SHOWN` so its list draws the
  border and shows the screen.
- `WAIT_KEY_OR_TIME` ($B899): B x 65536 reads of the keyboard, about 95
  T-states each, or a key; 8 is about 14 seconds (counted from the
  instructions).

## How this was found

Read, with Knight Lore's `game_over_summary`, its ratings table and
`game_complete_msg` as the map (0.57); the list bytes decoded by a scratch
script; the rating's arithmetic in `SUMMARY_SCREEN` worked through by hand
(RLCA, AND $C0, OR won, three RLCAs, AND $0E: twice ((rooms - 1) >> 5 AND 3)
+ 8 x won); the buffer addresses turned into pixel positions with
`CALC_VIDBUF_ADDR`'s formula (stage 2, ranges 1, 2 and 3). *Measured*: the
summary of a game lost at once shows 00 activated, 24 not activated and 132
lost, and the same count made from the room data by
`alien8_data.room_records` gives 24 rooms and 132 crew, the crew rooms being
exactly the 24 socket rooms. Stage 1's sessions activated each kind of
chamber (the inks, the white room, the count) and the twenty-fourth with the
count staged at 23 (`WON`, the arrival screen, the summary).

## Confidence

*Read*, and *measured* for the activation, the win, and the summary's counts
of a lost game. The rating chosen in the sessions was not recorded.

## Knight Lore and Pentagram

The same shape as Knight Lore's end: a completion message, a summary with a
rating from the rooms visited and success, a wait for a key
([`../knightlore/winning.md`](../knightlore/winning.md)). The rating is
Knight Lore's exactly -- the words, the order, the rule -- but for the colour
(bright red there). The counts differ: Knight Lore shows days, the
percentage and charms; Pentagram a percentage
([`../pentagram/percentage.md`](../pentagram/percentage.md)). New: the
valves put back first, and the scene in the main loop after it.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `SUMMARISE_CHAMBERS` | `SUBAC6B` | $AC6B | the summary's three counts |
| `CRYONAUT` | `SUBAE96` | $AE96 | graphic 74 |
| `GAME_ENDED` (`SUMMARY_SCREEN`) | `SUBB761` | $B761 | the end of a game |
| `MARK_ROOM_SEEN`, `COUNT_ROOMS_SEEN` | `SUBB863`, `SUBB881` | $B863, $B881 | the rooms seen |
| `WAIT_KEY_OR_TIME`, `ARRIVAL_SCREEN` | `SUBB899`, `SUBB8A9` | $B899, $B8A9 | |
| `ARRIVAL_COLOURS` ... `ARRIVAL_TEXT_N` | `TEXTB8D0` ... `DATAB94E` | $B8D0-$B94E | the arrival screen's list, in sna2ctl's pieces |
| `SUMMARY_COLOURS` ... `SUMMARY_RATING_LAST`, `RATINGS`, `RATING_POOR` ... `RATING_ADVENTURER_LAST` | `TEXTB94F` ... `DATABA35` | $B94F-$BA35 | the summary's list and the ratings |
| `PRINT_SUMMARY_COUNTS` | `SUBBA36` | $BA36 | the counts |

## Open questions

- Whether average below fair is meant: carried over from Knight Lore
  unchanged, so at least not an Alien 8 slip.
