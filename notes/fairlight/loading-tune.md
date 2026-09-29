# The loading tune

**Question this answers:** what plays over the loading screen, and how two
voices come out of the beeper.

**Short answer:** a two-voice tune of 418 notes a voice (415 heard), 52.6
seconds, played once and then silence, until a key is pressed. It is the
only sound the game makes ([`sounds.md`](sounds.md)). Each voice is a square
wave kept in its own copy of the port byte (A' and A); both are sent to port
$FE in turn in a loop whose two paths take the same 96 T-states, so neither
voice's pitch depends on the other's.

## How it works

```
LOADING_TUNE $C000     the four pointers from TUNE_VOICES; DI
  loop: TUNE_PLAY_NOTE $C049; KEY-SCAN ($028E); until a key; EI; RET
TUNE_PLAY_NOTE $C049
  TUNE_NEXT_NOTE $C026 for each voice   -> VOICE_ONE_NOTE, VOICE_TWO_NOTE
  TUNE_PITCH $C033 for each             -> H its period, L 1 (the first countdown)
  both resting: return at once
  18 x 256 turns: OUT voice one's byte, count E; OUT voice two's byte, count L;
                  a countdown's end reloads it and flips bit 4 of that voice's byte
TUNE_NEXT_NOTE: pointer + 1; at $40, TUNE_RESTART_VOICE $C041 (the second word)
```

The variables, $C01A-$C025: `VOICE_ONE_NOTE`, `VOICE_TWO_NOTE`, `TUNE_PORT`
(0: border black, speaker off), `VOICE_ONE_AT` and `VOICE_TWO_AT` (each two
words: the note last played, and where to go back to), `NOTE_LENGTH` ($EE:
256 less it is 18 passes of 256 turns).

`TUNE_VOICES` ($C0B0, 972 bytes):

| Offset | What |
|---|---|
| 0 | Four words: each voice's start (the byte before its first note) and its restart |
| 8 | `TUNE_NOTES`: 54 periods, for notes -12 to 40 ($FF down to $0C, each about 0.944 of the last: a semitone) and 1 for the rest (41) |
| 62 | Voice one's unplayed first byte; 63-480 its 418 notes; 481 its $40 |
| 482 | Voice two's unplayed first byte; 483-900 its 418 notes; 901 its $40 |
| 902-971 | Leftover source text (the object table's last lines), then ten bytes that are not text |

A note is a signed number of semitones ($FB is -5). Both restart pointers
point at the voice's own last note, a rest, so after the tune each voice
rests for ever, and with both resting a note returns at once -- so the last
three notes, rests in both voices, take no time, and 415 are heard. A rest's
period is 1: a toggle every turn, 18.2 kHz, too high to be a note. A note of
period P sounds at 3500000 / (192 x P) Hz.

From the first room on, $C000 is part of the clean copy of the screen, so
the tune cannot be played again.

## How this was found

Read (stage 2, range 1); timings counted from the instructions -- 96
T-states each way round the loop, so a note is 18 x 256 x 96 = 442368
T-states, 0.1267 s. The tune's end was found by following the pointers
from $C0B0 to each $40, which settled stage 1's open question of where the
tune ends and the leftover text begins ($C436).

## Confidence

*Read*. The length, 52.59 s, and the pitches were *measured* by stage 3's
sounds page, recording the player in the simulator and checking it edge by
edge against the timings. The restart ($C041), the both-resting return and the end
of a note by way of the first `DJNZ` never ran in the sessions, which press
a key after half a second (`fairlight-coverage.txt`).

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `TUNE_NEXT_NOTE` | `SUBC026` | $C026 | A voice's next note |
| `TUNE_PITCH` | `SUBC033` | $C033 | A note's period |
| `TUNE_RESTART_VOICE` | `SUBC041` | $C041 | A voice's end: back to its restart |
| `TUNE_PLAY_NOTE` | `SUBC049` | $C049 | One note, both voices |
| `VOICE_ONE_NOTE` ... `NOTE_LENGTH` | `TUNE_A` ... `TUNE_F` | $C01A-$C025 | The tune's variables |
| `TUNE_VOICES` | `DATAC0B0` | $C0B0 | Pointers, periods, the two voices |

## Open questions

- None about the player. The tune's name, if it has one, is not in the game.
