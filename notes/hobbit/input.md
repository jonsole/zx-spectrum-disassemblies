# The keyboard and the command line

**Question this answers:** how keys are read, what the command line accepts,
and the keys that do more than type a letter.

**Short answer:** the game reads the keyboard itself, with interrupts off:
`SCAN_KEYBOARD` reads all eight half-rows after a 7.4 ms busy wait and
reports only a key that has just gone down. `READ_LINE` keeps letters,
space, quote, comma and full stop, echoes them in the input window, and ends
at ENTER. On an empty line the cursor keys are whole moves and @ repeats the
last line; the game also waits for a key after each picture, at the title,
and after a death.

## How it works

**`SCAN_KEYBOARD` ($8B93)** (*read*): `DEBOUNCE_DELAY` first (1000 turns of a
four-instruction loop, about 26000 T-states), then `IN` on each half-row
from $FEFE, masking out the keys that never count on their own
(`KEY_STATE` $8B81: CAPS SHIFT, SYMBOL SHIFT, and 1, 3, 4 and 9), and
comparing with `KEYS_LAST_SEEN` ($8B8B). Only a key down now that was up
last time is reported, as half-row x 5 + bit, looked up in `KEY_MAP` ($8BFB)
or, with either shift held, `KEY_MAP_SHIFTED` ($8C23). A key held across
scans is reported once. With the game idle at its prompt, the busy wait is
nearly all it does.

The two maps (*read*, decoded from the tables):

| Key | Plain | With a shift |
|---|---|---|
| letters, SPACE, ENTER | themselves | themselves |
| 0 | backspace | clear the line ($18) |
| 5 | backspace (cursor left) | backspace |
| 6, 7, 8 | codes for S, N, E | the same |
| 2 | nothing | @ |
| P, M, N | P, M, N | quote, full stop, comma |
| 1, 3, 4, 9 | nothing | nothing |

**`READ_LINE` ($6DD6)** (*read*): sets `PATIENCE` to 3000
([`time-and-timers.md`](time-and-timers.md)), sets `INPUT_STYLE` so what is
printed goes to the input window, prints "> ", and points HL at `INPUT_LINE`
($6FF9) with B = 128. The cursor lives in HL and B only -- no variable says
how much has been typed, which is why a command can be injected at
`READ_LINE_READY` ($6DF3) by writing it into the line and moving HL and B
([`driving.md`](driving.md)). Then, per key from `GET_KEY`:

- **@ on an empty line** (`REPEAT_LAST`, $6E7A): returns Z, and
  `MAIN_LOOP` re-tokenises the old contents of `INPUT_LINE` -- the last
  command again.
- **The first key of a line** may be a move (`ONE_KEY_MOVES`, $6E4F): the
  codes from 7, 6 and 8 put N, S or E and a carriage return into the line,
  and 5 or 0 (backspace's code) puts W -- a single key moves the player.
  Later in the line 5 and 0 are backspace.
- **$18** (shift and 0) rubs the whole line out (`RUB_OUT_LINE`).
- **Backspace** steps back unless the line is empty.
- **Letters, space, quote, comma, full stop, ENTER** are kept and echoed;
  anything else is ignored. ENTER ends the line.

**The other waits** do not use `SCAN_KEYBOARD`; each polls port $FE for any
of the forty keys (*read*):

| Where | Waits for | Then |
|---|---|---|
| `TITLE_WAIT` $6C6D | any key down | N held: no pictures ([`loading.md`](loading.md)) |
| `WAIT_FOR_ANY_KEY` $969A | any key down | white border; after **every** picture drawn |
| `STORY_CHAR` $86D8-$86F8 | a key, or about 0.6 s; then all keys up | at the end of each story line (no wait for the first nine of a turn, but still all keys up) |
| `DO_PAUSE` $843A | a new key, then all up | green border meanwhile, white after |
| `WAIT_AND_RESTART` $90DF | any key down | a new game (after death or a win) |
| `DO_QUIT` $8394 | any key down | a new game |
| `NEW_KEYPRESS` $84B9 | all up, then one down | SAVE's tape prompts |

A key pressed while a picture draws is not read by anything; the first key
after the picture is taken by `WAIT_FOR_ANY_KEY` as "carry on", which is why
the first letter of a command typed during a picture used to go missing
(the build's `_session_script` has the measurements).

**ENTER held too long.** `STORY_CHAR`'s end-of-line wait at $86F8 does not
go on until every key is up, and a key held down from one breakpoint to the
next never is -- the game hangs there ([`driving.md`](driving.md)).

## How this was found

Read from the routines and the two key tables. The key-map decode was done
from the snapshot for these notes (2026-09-27). Two of the waits were found
the hard way while driving the game live on 2026-09-25: the wait after every
picture (not only the first, as the annotation then said) and the hang in
`STORY_CHAR` with a key held.

## Confidence

*Read* throughout. The wait after every picture and the `STORY_CHAR` hang
are *watched*. The one-key moves, @ and the masked keys are *read* only.

## Open questions

- Shift and SPACE gives $02 in `KEY_MAP_SHIFTED`, which `READ_LINE` does not
  keep; whether it was meant for anything is not known.
