# Input: the menu and the controls

**Question this answers:** how a game is set up on the title screen, and
which keys do what in play.

**Short answer:** the menu takes 1-3 for keyboard, Kempston joystick or cursor
keys, 4-6 for knight, wizard or serf, and 0 to start. In play, movement and
fire come through one routine that makes all three methods look like a
Kempston joystick: Q left, W right, E down, R up, T fire on the keyboard; 5,
6, 7, 8 and 0 as cursor keys. Whatever the method, SYMBOL SHIFT picks up and
drops, and SPACE on its own pauses.

## How it works

**The menu** (`TITLE_SCREEN` $7C19, *read*): clears the screen, draws the
nine title pictures (`DRAW_TITLE_ICONS`) and loops redrawing the seven menu
lines (`DRAW_MENU`), reading the 1-5 and 6-0 half-rows. Keys 1-3 set bits 1-2
of `SELECTION` ($5E00) to 0, 2 or 4; 4-6 set bits 3-4 to 0, 8 or $10; the
chosen lines flash (bit 7 of their colour bytes in `MENU_DATA`, set and
cleared by `HIGHLIGHT_LINE`); 0 jumps to `START_GAME`. The defaults are
keyboard and knight (the byte is cleared at $7C19); after a game ends the
title is re-entered at `TITLE_AGAIN` ($7C29), past the clearing, so the last
choices stand. Interrupts are off
throughout ([`loading.md`](loading.md)).

**Movement and fire** (`READ_CONTROLS` $93BE, *read*; the keyboard map was
confirmed live by the annotations' author): one byte, bit 0 right, 1 left,
2 down, 3 up, 4 fire, 0 meaning pressed.

| Method | How |
|---|---|
| keyboard | half-row Q-T; W and Q swapped into bits 0 and 1: Q left, W right, E down, R up, T fire |
| Kempston | port $1F, complemented |
| cursor (`READ_CURSOR_KEYS` $9398) | 5 left, 6 down, 7 up, 8 right, 0 fire, gathered from two half-rows |

Diagonals are two bits at once. Fire is acted on each frame it is held, but
only one weapon exists at a time ([`player.md`](player.md)).

**Pick up / drop** (`READ_PICKUP_KEY` $938B, *read*, then *measured*): once a
pass, bit 1 of the B-N-M-SYMBOL SHIFT-SPACE half-row -- SYMBOL SHIFT -- into
`PICKUP_KEY` ($5E20). One press does one thing
([`objects-and-inventory.md`](objects-and-inventory.md)). Measured: holding
SYMBOL SHIFT on the yellow key picked it up.

**Pause** (`PAUSE` $9489, *read*, then *measured*): SPACE with none
of B, N, M, SYMBOL SHIFT: wait for release, then for a press, then for
release, all with interrupts off, so the clock stops.

## How this was found

Read the menu loop and the three readers. The build's code map was made by
playing through each character and control method (`SESSIONS` in the build),
which is also how the Kempston and cursor paths are known to run. Pick-up
and pause were staged in the simulator on 2026-09-27.

## Confidence

*Read*; pick-up and pause *measured*.

## Renamed routines

Applied to the annotations on 2026-09-27; the build verified byte for byte.

| New name | Old name | Address | Role |
|---|---|---|---|
| `PAUSE` | `CHECK_KEY_HELD` | $9489 | SPACE pauses and resumes |
| `READ_PICKUP_KEY` | `READ_FIRE_ROW` | $938B | SYMBOL SHIFT into `PICKUP_KEY` |
## Disassembly corrections

All applied to the annotations, the ref and the build on 2026-09-27 (the old names are used below), except where marked.

- `CHECK_KEY_HELD`: "Look at a key with interrupts off ... Returns at once
  unless the key is down" -- it is the pause.
- `READ_FIRE_ROW` names fire; fire is bit 4 of `READ_CONTROLS`.
- `READ_CONTROLS` R line and `TITLE_SCREEN`'s note are right; the TITLE_SCREEN
  comment at $7C32 ("the OUT to $FD is inert on a 48K") likewise.

## Open questions

- The Kempston path was run by the build's playthrough with "nothing pressed"
  only; the joystick bit order is taken from the standard, not tested.
