# Sound

**Question this answers:** what makes each sound and tune, and who plays
it when.

**Short answer:** everything goes through `CLICK` ($C471), one square wave
of half-length B, with interrupts off. Six tunes through Pentagram's and
Alien 8's tune player; four short effects a note a turn; and blips, bumps,
footsteps, the throw, puffs, and notes for things appearing. Most of the
routines are Pentagram's, three of them Pentagram's unused code put to
use. The villains' hum was meant to have four tables of its own and plays
ROM bytes instead.

## How it works

**Tunes.** A tune is a byte a note -- the note in bits 0-5, the length less
one in bits 6-7, in units -- ended by $FF. `NOTES` ($C6B9) has 61 notes of
three bytes: two counts of the timing loop for a half cycle (B + 256 * (C -
1) passes) and the cycles in one unit. Notes 1-60 are semitones over five
octaves (2548 and 2405 passes for notes 1 and 2, a ratio of the twelfth
root of two), and each unit lasts about 41,000 passes whatever the pitch, a
little under a sixth of a second. Note 0 is a rest (`NOTE_REST`, $C6A3), a
fixed delay; no tune uses it.

| Tune | Notes | Played by | When |
|---|---|---|---|
| `TUNE_MENU` $C770 | 131 | `PLAY_TUNE_ONCE` $C63D, from `MENU_LOOP` | the first pass of the menu after the start or a game, until a key (`TUNE_PLAYED`) |
| `TUNE_CONTROL_CHOSEN` $C7F4 | 3 | `MENU` | a key 1-5 changes the control method |
| `TUNE_GAME_START` $C7F8 | 10 | `NEW_GAME` | 0 pressed |
| `TUNE_GAME_OVER` $C803 | 22 | `GAME_OVER` | after the percentage and the score |
| `TUNE_ENDING` $C81A | 30 | `ENDING_PIT_FRONT` | the last villain has sunk into the pit |
| `TUNE_NEW_LIFE` $C839 | 5 | `NEW_LIFE` | a life follows a death |

**Effects and the rest.**

| Routine | Address | Sound | Played by |
|---|---|---|---|
| `EFFECT_NOTE` | $C3BD | a note a turn from `EFFECT_TABLE` ($C3D8), last first | the main loop, while `EFFECT_TIME` lasts |
| `BLIP_BY_TURN` | $C332 | 12 waves, pitch from `BLIP_PITCHES` by `TURNS` & 15, if drawn last turn | the creature |
| `BLIP_FROM_TABLE` | $C335 | the same from a table in BC | the villains -- broken, below |
| `ENDING_BEEP` | $C39D | 12 waves, a little lower each time | the ending's villains |
| `BUMP_SOUND` | $C3AA | 16 waves, a warble | the knight's top, walkers at walls, if on the screen |
| `FIRE_SOUND` | $C3F4 | 32 alternating waves | a throw |
| `FOOTSTEP` | $C400 | 4 waves every 4th step (every 2nd when fast) | the walk |
| `PUFF_SOUND` | $C435 | 16 waves pitched by ROM bytes | the cloud's last frame, on the screen |
| `APPEAR_SOUND` | $C455 | 6 waves, rising with the graphic | a monster appearing |
| `ARRIVE_SOUND` | $C463 | 8 waves, rising with `ARRIVING` | the knight appearing |
| `BEEP`, `CLICK` | $C46A, $C471 | C waves at B; one wave | everything |

- **The effects** (`EFFECT`, `EFFECT_TIME`): 0 a new cell with a building,
  four notes; 1 the faster walk, five; 2 the hits back, seven; 3 an object
  taken up, four. Played backwards from the end, so the byte at each
  effect's address is the previous effect's first note -- and effect 3's
  first note is read from past the table, the first byte of `FIRE_SOUND`'s
  code: a squeak before three low notes.
- **The villains' hum is broken twice.** `VILLAIN_WANDER` means to give each
  villain its own sixteen pitches from `VILLAIN_PITCHES` ($C35D, four tables
  filling $C35D-$C39C). It loads the table's address into HL, which
  `BLIP_FROM_TABLE` overwrites with the turn's four bits before adding BC;
  and the offset it puts in BC, the graphic turned left two bits and cut to
  its top four, keeps graphic bit 5, giving $80, $90, $A0 or $B0 rather than
  0-48. So the villains hum at ROM bytes $0080-$00BF and the four tables
  are never read. (`AND $30` and the right order would have worked; which
  was meant cannot be told.)
- `FIRE_SOUND` starts from B, which `KNIGHT_THROWS` leaves as the carried
  place the thing came from.

## How this was found

Read against Pentagram's annotations of the same routines (stage 2, ranges
1 and 2; `matches.txt`). The note table checked by hand for a few notes (the
semitone, the equal unit); each tune's player found by the `LD DE` before
each call. The hum *measured* (range 4): each villain in turn put beside the
knight, the routine stopped at the pitch read, HL $00BB, $00AD, $009F and
$0081 for the villains of 108, 104, 100 and 96.

## Confidence

*Read*; the hum's source *measured*. The unit's length ignores the loop's
small overheads. That the four tables were meant for the villains is
*inferred* from their size and place.

## Filmation (Knight Lore, Alien 8, Pentagram)

The tune player is Pentagram's and Alien 8's (1.00). The effects are
Pentagram's, by address: `BLIP_BY_TURN` (unused there), the pitch tables
(the same 80 bytes), `PAUSE_BEEP` (here the ending's note; Nightshade's
pause is silent), the jump sound (here the bump), `EFFECT_NOTE`,
`FIRE_SOUND`, `FOOTSTEP` (two waves there, four here), `PUFF_SOUND` (four
waves there, sixteen here), `BEEP`, `CLICK`, and the beeps by graphic
(data there, `APPEAR_SOUND` and `ARRIVE_SOUND` code here). Nightshade is
the older game, so Pentagram's unused bytes are Nightshade's leftovers,
not the other way round (*inferred* from the dates).

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `BLIP_BY_TURN`, `BLIP_FROM_TABLE` | `SUBC332` | $C332, $C335 | blips |
| `BLIP_PITCHES`, `VILLAIN_PITCHES` | `TEXTC34D` and more sna2ctl blocks | $C34D, $C35D | five tables of 16 |
| `ENDING_BEEP`, `BUMP_SOUND` | `SUBC39D`, `SUBC3AA` | | |
| `EFFECT_NOTE`, `EFFECT_TABLE` | `SUBC3BD`, `DATAC3D8` | | the effects |
| `FIRE_SOUND`, `FOOTSTEP`, `PUFF_SOUND` | `SUBC3F4`, `SUBC400`, `SUBC435` | | |
| `APPEAR_SOUND`, `ARRIVE_SOUND`, `BEEP`, `CLICK` | `SUBC455`, `SUBC463`, (entry), `SUBC471` | | |
| `PLAY_TUNE_ONCE`, `PLAY_TUNE`, `PLAY_NOTE`, `NOTE_REST` | `SUBC63D`, `SUBC656`, `SUBC661`, (entry) | | the tune player |
| `TUNE_MENU` ... `TUNE_NEW_LIFE` | `TUNEC770` ... `TUNEC839` | $C770-$C839 | named in `nightshade_data.py` by what they are for |

## Also found for the stage 3 pages (2026-09-28)

- The villains' hum as it is: 96-99 hum ROM code at $0080-$008F; the other three hum mostly the letters of BASIC keywords from the ROM's keyword table. The sounds page records both what plays and what the four tables would have played (*measured*).
- The pause is silent: waiting in its loop it makes no edge at all (*measured*).
- Effects 2 and 3 are started here; Pentagram has the same table but starts only 0 and 1, so the pick-up's squeak (a byte of FIRE_SOUND's code) is heard only in Nightshade.
- None of the six tunes is in Knight Lore, Alien 8 or Pentagram; CLICK and the note table are identical in all three, the tune player differs only in addresses (byte-compared).

## Open questions

- Did the villains ever hum from their own tables in another version? Only
  this tape has been looked at.
