# Text, messages and the panel's box

**Question this answers:** how the game prints -- the title page, the
message line, LIFE, the closing lines of the quest -- and how the panel's
box shows the thing in use.

**Short answer:** all of it is `PRINT` ($EBFE, the author's own name): the
string follows the `CALL`, a character is an 8 by 8 picture from the
40-character `FONT` ($BAD8) put down through the compositor, $C8 x y moves
the printing position and $A4 ends. `TITLE_PAGE_TEXT` ($B686) is the whole
title page in one call; `SHOW_MESSAGE` ($E038) shows BLOCKED, LOCKED or TOO
HEAVY for ten passes over LIFE's digits; `MESS2` ($DFF2, the author's name)
prints the two closing lines of either ending. The panel's box for the
thing in use is cleared by `CLEAR_THING_BOX` ($EC75, the author's INFO0)
and filled by `SHOW_THING_IN_USE` ($EC4C, INFOR).

## How it works

**The printer.** `PRINT` sets `DRAW_WIDTH` to one byte, clears pages $D8
and $D9 ($D800-$D9FF) and bit 1 of IY+$71 (nothing behind to merge), then
for each byte after the `CALL`: $A4 returns past it; $C8 loads `PRINT_X`
and `PRINT_Y` from the next two; anything else is a character, found at
`FONT` + 8 x n (`PRINT_FIND_GLYPH`, $EC3B), drawn at the printing position
through `COMPOSITE_FROM_IX` ([`compositing.md`](compositing.md)), and x
moves on 8. A character replaces the 8 by 8 pixels under it, and x need not
be a multiple of 8. The characters: 0 a space, 1-26 the letters, 27-36 the
digits, 37 a full stop, 38 a dash. `PRINT_CHAR` ($EBF5) pokes A into a
one-character string of its own and calls `PRINT`; LIFE's two digits use it
after a string that only moves the position.

The strings are laid out in the listing as their text, generated from the
glyph numbers (`fairlight_data.inline_strings()`), and the build fails if
any string byte ever runs as code. There are 16.

**The title page** (`TITLE_PAGE_TEXT`, $B686): called by `TITLE_SCREEN`
once room 79 is drawn and coloured -- the game's name and subtitle, the
author and publisher, the keys and what each does, each at its place; then
"9-JOY" in Release 2 ([`versions.md`](versions.md)).

**The message line** (`SHOW_MESSAGE`, $E038, once a pass from `MAIN_LOOP`
at the author's ST9, $FF42). A message is asked for by putting its number in
`MESSAGE` ($FF87): 1 BLOCKED (a drop that will not fit, $F4AD; a door's far
side occupied, $F8E3), 2 LOCKED ($F7F8), 3 TOO HEAVY ($F54F). A new one sets
`MESSAGE_TIMER` to 10, bit 6 of `GAME_FLAGS`, clears `MESSAGE`, and prints
at x 28, y 12 -- message 1 prints a B and then shares message 2's word. Each
pass with bit 6 set counts the timer down; at 0 nine spaces clear it, bit 6
is cleared and bit 0 set, and `START_PASS` ($FF21) prints LIFE again at x
55, y 12 (the message covers it).

**The closing lines** (`MESS2`, $DFF2): called at $FD96 after either
ending's verdict in room 81, then `JP WAIT` ([`quest.md`](quest.md)): that
the quest goes on, and the title of the sequel.

**The panel's box.** 24 by 32 at x 20, row 40 (rows counted from the
bottom), with the number of the place in use (1-5, from `SELECTED`) at x
10, y 50. `CLEAR_THING_BOX` fills page $D9 with $FF, which makes the
compositor take every pixel from the clean copy, and page $D8 with 0, puts
the box back, and prints the number. `SHOW_THING_IN_USE` then draws the
thing's image (no mask) into it with both pages clear. `SHOW_THING_IN_USE`
runs after a pick-up ($F52A) and when a place holding a thing is chosen
(`SHOW_IN_USE`, $FF0E, the author's STE3); `CLEAR_THING_BOX` alone after a
drop and for an empty place.

## How this was found

Read (stage 2, ranges 1 and 2). The author's names come from the leftover
source text, matched instruction for instruction: the choose-a-place code
at $FF0E-$FF3F is there with `CALL INFO0`, `CALL INFOR` and `CALL PRINT`
where the code calls $EC75, $EC4C and $EBFE; the end of `ROOMST` with
`CALL MESS2` and `JP WAIT` where it has $DFF2 and $F0D2
([`symbols.md`](symbols.md)).

## Confidence

*Read*. The box's place and size are the code's constants; that it is the
panel's "thing in use" box follows from its callers.

## Krumlinde

`RTN_Print_Icon_String` for `PRINT` is fair. His `RTN_Init_Sprite_Sort`
($EC75) is this box's clear; it has nothing to do with sorting. The "two
glyphs before GAME OVER" he could not read are the $C8 command's position
bytes, x 90 and y 100 (stage 1, $F0B9). He did not have the author's names.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `TITLE_PAGE_TEXT` | `SUBB686` | $B686 | The title page's string |
| `MESS2` | `SUBDFF2` | $DFF2 | The author's name |
| `SHOW_MESSAGE` | `SUBE038` | $E038 | The message line |
| `BYTE_BEFORE_PRINT_CHAR` | `SPACEEBF4` | $EBF4 | A zero byte nothing reads |
| `PRINT_CHAR` | `SUBEBF5` | $EBF5 | Print the character in A |
| `PRINT` | `PRINT` | $EBFE | The author's; kept |
| `PRINT_NEXT_CHAR` | (entry) | $EC0E | Its loop |
| `PRINT_FIND_GLYPH` | `SUBEC3B` | $EC3B | Its continuation |
| `SHOW_THING_IN_USE` | `SUBEC4C` | $EC4C | The author's INFOR |
| `CLEAR_THING_BOX` | `SUBEC75` | $EC75 | The author's INFO0 |

## Open questions

- None about the printer. A note on the listing: the first bytes of each
  string after a `CALL` (its $C8 x y, and the short strings of
  `SHOW_MESSAGE` and `PRINT_CHAR`) are shown as instructions with the text
  in the comment, and the stage-2 coverage report now counts them as code
  that never ran -- nine of its 31 runs ($B689, $DFF5, $E058, $E076, $E081,
  $E08F, $EBFB, $F07D, $F0BC; 38 bytes). They are string bytes and never
  run by design. The `JR Z` that $DFF5-$DFF6 decode to also gives $E048 a
  false "entry point used by $DFF2" in the listing. Reported to the lead
  ([`journal.md`](journal.md)).
