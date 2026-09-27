# The screen: two windows, two fonts, and the printer

**Question this answers:** how the screen is laid out, how text gets onto it
and scrolls, why a busy turn slows down, and how PRINT copies the story to a
ZX Printer.

**Short answer:** the top 16 character rows are the picture; the story is
printed on row 17 in the game's own six-pixel font, 42 columns, and scrolls
up over the picture; a wavy divider sits on row 18; rows 19-23 are the input
window, in the ROM's font and capitals. After the first nine lines of a
turn, each new story line waits about half a second (or until a key) before
it scrolls. PRINT sends each story line to a ZX Printer by driving port $FB
directly.

## How it works

**The layout** (*read*, from `NEW_GAME`'s cursor set-up and the scrolling
routines):

| Rows | What | Routines |
|---|---|---|
| 0-15 | the picture's canvas, 256 x 128 ([`pictures.md`](pictures.md)) | `CLEAR_CANVAS`, `RUN_PICTURE` |
| 0-17 | the story: new lines on row 17, scrolling up over the picture | `STORY_CHAR`, `SCROLL_STORY` |
| 18 | the divider, five two-byte patterns repeated across pixel rows | `DIVIDER`, drawn by `NEW_GAME` at $5140 |
| 19-23 | the input window: the prompt, what is typed, the parser's replies, the tape messages | `INPUT_CHAR`, `SCROLL_INPUT` |

`CLEAR_SCREEN` makes the whole screen black on white with a white border;
a picture sets its own border and colours for its rows.

**The story window** (`STORY_CHAR` $86A1; *read*): characters are drawn by
`NARROW_CHAR` from `FONT` ($8822, 96 characters of 8 bytes, six pixels
wide), shifted to the pixel where the last one ended, so a character often
straddles two screen bytes; `STORY_CURSOR` and `STORY_PIXEL` keep the place,
`STORY_COLUMNS` counts down from 42. Every letter is made lower case and the
first after a carriage return or full stop a capital (`CAPITAL_NEXT`), so the
messages' own capitals mean nothing. A new line starts at `INDENT` -- how
`LIST_HELD` shows what is inside what. `PRINT_WORD` starts a new line before
a word that would not fit, so words are never split.

**The pause at the end of a line** ($86D1-$8701; *read*): at each carriage
return the finished line goes to the printer if PRINT is on; then

- if `NO_PAUSE_LINES` ($B716) is not 0, it is counted down and there is no
  pause;
- otherwise the game polls the keyboard up to 32768 times, 62 T-states a
  time -- about 0.58 s -- and stops early if a key is pressed;

and in both cases, if a key was pressed or the count was not 0, it waits
until every key is up before scrolling. `NEW_GAME` sets `NO_PAUSE_LINES` to
17 and `MAIN_LOOP` to 9 before every line, so each turn's first nine lines
come out at once and the rest at a readable pace; holding a key skips the
pauses, but the scroll then waits for it to be let go -- which is the hang a
driver that holds a key across story output runs into
([`driving.md`](driving.md)).

**The input window** (`INPUT_CHAR` $85B7; *read*): `INPUT_STYLE` ($B701)
set sends `PRINT_CHAR`'s output here instead: the ROM's character set at
$3D00, eight pixels wide, 32 columns, lower case made capitals, a + as the
cursor. A carriage return blanks the rest of the line and scrolls rows 20-23
up to 19-22; a backspace past the start of a line scrolls them back down.
The prompt, the typed line, the WAIT the game types, the parser's refusals
and "which ... ?", HELP's hints and the tape messages all appear here.

**The printer** (*read*): PRINT (`PRINTER_ON` $82A5) sets `TO_PRINTER` only
if bit 6 of port $FB reads low -- a ZX Printer answering; NOPRINT clears it.
`LINE_TO_PRINTER` ($8B22) then sends row 17's eight pixel rows out of port
$FB a pixel at a time, as the ROM's COPY does but with its own code, reading
the screen directly; a printer that stops, or is not there, ends it. The
game calls no ROM printing routine and never touches the printer buffer at
$5B00.

## How this was found

Read from the routines named; the half-second pause is the loop's own count
times its documented instruction timings (4+11+7+7+7+6+4+4+12 T-states,
contention ignored). The annotation's "about a third of a second" and "what
sets it [`NO_PAUSE_LINES`] is not yet traced" were checked against the code
for these notes.

## Confidence

*Read*. The pause length is computed, not timed; the printer was not tried
(the emulator has no ZX Printer).

## Disassembly corrections

- `STORY_CHAR`'s description: the wait is about 0.58 s, not "about a third
  of a second", and `NO_PAUSE_LINES` is set by `NEW_GAME` (17, at $6CEC) and
  `MAIN_LOOP` (9, at $6D18), not "not yet traced". Corrected in the annotations 2026-09-27.
- `docs/hobbit-fast-draw-plan.md` says the printer buffer was not free
  because "the game has a PRINT command that copies its text to a ZX Printer
  through the ROM, which uses that buffer". The game's printing is its own
  code on port $FB and reads the screen; the only ROM routines the game
  calls are SA-BYTES and LD-BYTES (and it reads the ROM's font). The buffer
  was free after all -- though the patch no longer needs it. Likewise
  `PIXEL_ADDRESS`'s closing note says "nothing here prints", which PRINT
  contradicts, though its conclusion about the buffer stands. Both
  corrected 2026-09-27.

## Also found for the animations page (2026-09-27)

- The story is printed one character every 4543 T-states (1.3 ms), up to 15 in one frame, so a line appears in two or three frames; the end-of-line pauses measured 0.58-0.60 s; the input cursor never flashes, and no frame the game draws uses FLASH (*measured*, the Animations page).

## Open questions

- None about the layout. Whether the printer output was ever seen on real
  hardware is outside what the code can say.
