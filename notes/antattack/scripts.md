# Scripts: the messages

**Question this answers:** how the machine code puts its messages on the
screen, what shows each one, and what a script can do besides print.

**Short answer:** every message the machine code shows -- and every sound it
makes, apart from the footstep click -- is a *script*: a byte string in
`SCRIPTS` ($9000-$93B9) run by `RUN_SCRIPT` ($8E0D). Printable bytes and
control codes go to the ROM's print routine, bytes of $80 and up play notes
or noise, $7D floods the play area with a colour and $7E prints a number
from the variables. Seventeen scripts, found by counting end markers; the
game stops while one runs. The audio side (notes, noise, what the recordings
show) is in [`sounds.md`](sounds.md).

## How it works

**Finding a script** (*read*): `PLAY_SCRIPT` ($8E02) takes the number in A,
saves IX and calls `RUN_SCRIPT` with it in D. `RUN_SCRIPT` CPIRs for $FF from
$9000, D times, giving up after 2K; script n starts after the nth $FF, so the
$FF at $9000 itself ends an empty "script 0" and the first real one is at
$9001. The build labels them `SCRIPT1` ($9001) to `SCRIPT17` ($9210), each
titled with its words (generated at build time, since the words are the
game's).

**The format** (*read*):

| Byte | Meaning |
|---|---|
| first | the stream to print to: 1 or 2 (all seventeen use 2, the upper screen); anything else, do nothing |
| $80-$FE | a sound: bits 0-3 a note from `TONES` ($8BB1), $0F meaning a burst of noise; bits 4-6 one less than the number of repeats |
| $7D, a | fill the play area's attributes (rows 1-15, columns 1-30) with a (`FILL_PLAY_ATTRIBUTES` $8B00) |
| $7E, n | print the two-byte big-endian number at $B400 + n with the ROM's OUT-NUM-2 |
| $FF | the end |
| anything else | RST $10: letters, AT, PAPER, INK, FLASH and the rest |

So a message and its tune are one string: letters with notes between them,
printed and played in step. Most scripts end with $7D and $38 -- the play
area back to black on white -- after flashing it another colour.

**What shows each** (*read*, from the callers; the Scripts page shows each
one's screen, run in the simulator on a game in progress):

| No. | Called by | When |
|---|---|---|
| 1 | `HANDLE_EVENTS` via `PLAY_SCRIPT_ONE` | the player lands from a bad fall |
| 2 | `HANDLE_EVENTS` | the rescued person does |
| 3 | `GRENADE_SOUNDS` | a blast blows up an ant |
| 4 | `GRENADE_SOUNDS`, `PRINT_COUNTERS` | a throw, and the start of each `PLAY`: reprint the grenades (`$7E` at $B42F), with a beep |
| 5 | `GRENADE_SOUNDS` | a grenade explodes: noise only |
| 6 | `HANDLE_EVENTS` | the player is blown up |
| 7 | `HANDLE_EVENTS` | the player is bitten |
| 8 | `HANDLE_EVENTS`, `PRINT_COUNTERS` | reprint the player's energy ($B431); no sound |
| 9 | `HANDLE_EVENTS` | the rescued person is blown up |
| 10 | `HANDLE_EVENTS` | the rescued person is bitten |
| 11 | `HANDLE_EVENTS`, `PRINT_COUNTERS` | reprint their energy ($B433); no sound |
| 12 | `MOVE_RESCUEE` | the person is found: their thanks, and the longest tune in play |
| 13 | `CHECK_RESCUED` | both are out of the city |
| 14 | `HANDLE_EVENTS` | a bite takes the player's last point of energy |
| 15 | `HANDLE_EVENTS` | the same for the rescued person |
| 16 | `PARALYSE_ANT` | someone lands on an ant |
| 17 | `FINAL_SCRIPT` (BASIC line 3600, USR 36594) | the tenth rescue: the ending, drawn letter by letter over the whole screen with notes between |

**The game stops while a script runs** (*read*): `RUN_SCRIPT` plays each note
in full before going on, inside the frame, and nothing else happens
meanwhile -- no movement, no key reading, no clock. Adding up the notes from
the note table's lengths, script 12 is about 3.9 seconds of tones, 13 about
3.7, 6 and 9 about 1.8-1.9, 16 about 1.1, 14 and 15 about 0.85, and the
ending about 9.4, each plus its noise (worked out from the Z80's documented
timings, 2026-09-27; [`sounds.md`](sounds.md) has the per-note figures and
the recordings that confirm them). The build's staged grenade throws wait
out script 12 for this reason.

**Messages from BASIC** are ordinary PRINTs: the title, the story cards
(lines 1000-1090), the score card, the retry, out-of-time and new-game
messages, and the ending's medal ([`basic-and-levels.md`](basic-and-levels.md)).

## How this was found

Read `PLAY_SCRIPT` and `RUN_SCRIPT`, then each caller. The scripts were
decoded with a scratch script on 2026-09-27 (stream, positions, how many
letters, notes with repeats, colours, numbers) without writing their text
anywhere; the durations are the sums of each note's half-cycles times its
half-period, 84 + 14 x delay T-states, from `TONE`'s loop.

## Confidence

*Read*. Every script ran: the build's playthrough and scenes reach all the
callers (*played*), and the Scripts page runs each of the seventeen on its own
in the simulator (*measured*). The durations are worked out from the
instruction timings, and the sounds agent's recordings agree with the
arithmetic ([`sounds.md`](sounds.md)).

## Disassembly corrections

- The unused script at $8B60 is not quite in this format: it has no stream
  byte in front (so `RUN_SCRIPT` would take its AT for a stream and print
  nothing), and an end marker after its third letter, so even given a stream
  it prints only the first three letters. See [`leftovers.md`](leftovers.md).
  Found reading the bytes for these notes and confirmed live by the agent
  testing pokes (*watched*); the lead is correcting the annotation
  (2026-09-27).

## Open questions

- Why `RUN_SCRIPT` accepts stream 1 (the lower screen) when no script uses
  it.
