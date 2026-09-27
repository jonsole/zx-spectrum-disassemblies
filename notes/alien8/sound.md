# Sound

**Question this answers:** what makes each sound, and where the tunes are.

**Short answer:** Knight Lore's tune player and note table, byte for byte
(and Pentagram's); five tunes, all played; and the effects, which are Knight
Lore's beeper routines with a few new ones, each played directly by the
thing that makes it -- there is no effect sequencer. Knight Lore's
werewolf-transformation sound is still in the block with no caller, and an
eight-step ticking fragment follows the note table, reached by nothing.

## How it works

**The tunes** (*read*): `PLAY_NOTE` ($B4C5) reads `NOTES` ($B51D, 61 rows of
three bytes, Knight Lore's scale, row 18 a copy of row 17's pitch).
`PLAY_TUNE` ($B4BA) plays a tune to its end; `PLAY_TUNE_ONCE` ($B4A1) plays
once per menu (`TUNE_HEARD`) and stops at any key; its second entry
`PLAY_TUNE_TILL_KEY` ($B4A9) skips the once-only test.

| Tune | Label | Played by | Notes, units |
|---|---|---|---|
| a game starting | `TUNE_START` $B3C5 | `MAIN_NEW_GAME` | 17, 18 |
| the end of the winning scene | `TUNE_WON` $B3D7 | `OILED_ROBOT` | 31, 32 (it begins as the start tune) |
| game over | `TUNE_GAME_OVER` $B3F7 | `SUMMARY_SCREEN`, until a key | 63, 64 |
| the arrival | `TUNE_ARRIVAL` $B437 | `ARRIVAL_SCREEN` | 25, 27 |
| the menu | `TUNE_MENU` $B451 | `MENU` through `PLAY_TUNE_ONCE` | 79, 79 |

A unit is about 0.155 seconds (Pentagram's measured unit, the same code). No
tune has a rest; the rest code ($B507-$B51C) never ran.

**The effects**, all ending in `BEEP` ($B6FB: C waves of half-wave B) or
`CLICK` ($B702, one wave):

| Routine | Address | Played by |
|---|---|---|
| `SPARKLE_SOUND` | $B5EE | the sparkles (`START_SPARKLE`, `SPARKLE_STEP`), a chamber activating: blips from the ROM at $1234 on, as many as the complement of the graphic's low five bits |
| `MATERIALISE_SOUND` | $B604 | the robot appearing, a falling sweep by the frame |
| `THUD_SOUND` | $B619 | the wanderer and the pacer stopped, a scene tool starting |
| `JUMP_SOUND` | $B62C | the jump |
| `BEEP_BY_Z` | $B63C | a note by height: the robot falling fast, a leaper, a remote robot, a ceiling drop, the wanderer, the dropping block, the lift |
| `BEEP_BY_A` | $B63F | the same with the pitch in A: the oiled robot |
| `BEEP_BY_U`, `BEEP_BY_V` | $B64A, $B64F | the shuttles |
| `BEEP_BY_UVZ` | $B654 | `SOUND_AND_DRAW` ($B3BF): the valves and the other movers that end there |
| `CRASH_SOUND` | $B676 | a ceiling drop landing, a scene tool striking |
| `WARBLE_SOUND` (`WARBLE_COUNTS` $B6A9) | $B690 | the remote robots, the slow chaser |
| `PLAIN_BEEP` | $B6B1 | the menu's choice changing, a pick-up press, an extra life, the scene's sparks |
| `PAUSE_BEEP` | $B6B6 | the pause |
| `HIGH_BEEP` | $B6BB | something landing on a conveyor; the mice turning |
| `FOOTSTEP` (`FOOTSTEP_NOW` $B6D4, `FOOTSTEP_PITCH` $B6D9) | $B6CE | the robot's steps; `FOOTSTEP_NOW` the end of his turn |
| `LOWER_HALF_STEP` | $B6C0 | a creature's lower half -- never heard (graphic 11 is odd) |

## How this was found

Read (stage 2, range 2); `NOTES` compared with Pentagram's table (183 bytes,
equal); the unused routine at $B65F found in Knight Lore's snapshot by
searching for its bytes (Knight Lore's `sound_transform`, $B472 there); the
fragment at $B5D4 searched for in both elder games and not found; no caller
of either in the code map's descent or the listing's cross-references. The
tunes decoded note by note (lengths, ranges, no rests) by a scratch script.

## Confidence

*Read*, and *compared* byte for byte where it says. The durations use
Pentagram's measured unit; no Alien 8 sound was recorded or timed in this
stage (the sounds page is recording them).

## Knight Lore and Pentagram

The note player and its table are Knight Lore's and Pentagram's byte for
byte ([`../knightlore/sound.md`](../knightlore/sound.md),
[`../pentagram/sound.md`](../pentagram/sound.md)). Pentagram adds a per-turn
effect sequencer; Alien 8 has none. The effects are Knight Lore's routines
with Alien 8's callers; `TRANSFORM_SOUND` is Knight Lore's werewolf sound,
left with no caller.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `TUNE_START` (`_END`), `TUNE_WON` (`_END`), `TUNE_GAME_OVER` ... `TUNE_GAME_OVER_END`, `TUNE_ARRIVAL`, `TUNE_MENU` | `TEXTB3C5` ... `DATAB436` | $B3C5-$B4A0 | the tunes, in sna2ctl's pieces |
| `PLAY_TUNE_ONCE` (`PLAY_TUNE_TILL_KEY`), `PLAY_TUNE`, `PLAY_NOTE`, `NOTES` | `SUBB4A1`, `SUBB4BA`, `SUBB4C5`, `DATAB51D` | $B4A1-$B51D | the player |
| `SPARKLE_SOUND`, `MATERIALISE_SOUND`, `THUD_SOUND`, `JUMP_SOUND` | `SUBB5EE` ... `SUBB62C` | $B5EE-$B62C | effects |
| `BEEP_BY_Z`, `BEEP_BY_U`, `BEEP_BY_V`, `BEEP_BY_UVZ` | `SUBB63C` ... `SUBB654` | $B63C-$B654 | pitched notes |
| `TRANSFORM_SOUND` | `DATAB65F` | $B65F | unused Knight Lore code, now declared code |
| `CRASH_SOUND`, `WARBLE_SOUND`, `WARBLE_COUNTS` | `SUBB676`, `SUBB690`, `DATAB6A9` | $B676-$B6A9 | |
| `PLAIN_BEEP`, `PAUSE_BEEP`, `HIGH_BEEP`, `LOWER_HALF_STEP`, `FOOTSTEP`, `CLICK` | `SUBB6B1` ... `SUBB702` | $B6B1-$B702 | |

## Disassembly corrections

- `$B65F` was data in stage 1: it is (unused) code, declared `c`; it decodes
  cleanly.
- The tunes were sna2ctl's text guesses; they are bytes.

## Open questions

- What the fragment at the end of `NOTES` ($B5D4-$B5ED: 18 bytes of code,
  four waves at a pitch chosen by the turn counter's low three bits from an
  8-byte table) was for; it would suit an eight-step ticking.
- None about the callers: the table's are the listing's "Used by" lines,
  checked for these notes.
