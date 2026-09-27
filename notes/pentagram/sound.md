# Sound

**Question this answers:** how the game makes its sounds, what plays each
one, and which are never used.

**Short answer:** everything is the speaker toggled by timing loops, the
border kept black. Tunes go through a note player and note table identical
byte for byte to Knight Lore's; the in-game sounds are short beeps from one
wave routine, and a small sequencer plays one note of an effect a turn. About
a hundred bytes of sound code and pitch tables are never reached, and one
tune is never played.

## How it works

- **One wave** (`CLICK` $D682): the speaker on for B turns of a 13 T-state
  loop, off for as long; B kept. `BEEP` ($D67B): C waves at B. About 26 x B +
  99 T-states a wave, so B = 128 is about 1 kHz (*read*, from the timings).
- **Tunes** (`PLAY_TUNE` $D6B5, `PLAY_NOTE` $D6C0, `NOTES` $D718): a note byte's
  low six bits index 61 rows of three bytes (the two half-wave loop counts and
  the waves in one unit); its top two bits are the length less one, 1-4 units
  of about 0.155 s; 0 would be a rest, and no tune has one. $FF ends a tune. The
  scale is a semitone a row for five octaves, G#1 at row 1 and A4 at row 38,
  with row 18 a copy of row 17's pitch where C#3 should be -- Knight Lore's
  table, whose per-row pitch comments were carried over. `PLAY_TUNE_ONCE`
  ($D69C) is the menu's: only while `TUNE_HEARD` is clear, and any key stops
  it. Nothing else happens while a tune plays.
- **The tunes:** `TUNE_MENU` $D7CF (the menu, once per game); `TUNE_START`
  $D833 (a game starting); `TUNE_QUEST` $D847 (the bucket reaching a quest
  item); `TUNE_OVER` $D853 (game over); `TUNE_WON` $D86F (the quest complete);
  and `TUNE_UNUSED` $D824, which nothing refers to. Each note is named in the
  listing.
- **The effects** (`EFFECT_NOTE` $D5F2, every turn from `OBJECT_DONE`):
  `SOUND_COUNT` ($A749) is two bytes, notes left and which effect. While the
  count is not zero it is taken down by one and twelve waves are played at the
  byte at the effect's address (from `EFFECTS` $D60D) plus the count: the notes
  run backwards from the end. Effect 0, four notes, on entering a room (the
  main loop); effect 1, five notes, on each pick-up press (`TAKE_OR_LEAVE`).
  Effects 2 and 3 have notes but nothing starts them.
- **One-shot sounds:**

| Sound | Routine | What |
|---|---|---|
| pause and resume | `PAUSE_BEEP` $D5D7 | twelve waves at the effect count's first byte + 64, after adding one to it -- so a resumed game gets an extra note or two of the last effect |
| a jump | `JUMP_SOUND` $D5E4 | sixteen single waves, the count scrambled from the step with an XOR ($A5) |
| a bolt fired | `FIRE_SOUND` $D629 | 32 single waves, each count the step less the one before; entered from an LDIR that leaves B zero, so a short count falling from 32 and a long one falling from 255 alternate: a high note and a low one, interleaved |
| a footstep | `FOOTSTEP` $D635 | `STEP_SOUND` ($A748) counts his steps; every fourth plays two waves, at 64 and 96 by turns |
| a puff | `PUFF_SOUND` $D64E | four single waves at pitches read from the ROM, at the word at `RANDOM` with its high byte cut to five bits -- the byte after `RANDOM` is `BUCKET_OUT`, 0 or 1, so the pitches come from the first 512 bytes of the ROM |

- `TABLE_WORD` ($D692): HL = the word at BC + 2A, for the effects' table.

**Never reached** (no code or table holds any address in them, and no
session ran them; [`leftovers.md`](leftovers.md)): `BLIP_BY_TURN` ($D56C, if
bit 1 of an object's flags was set, clear it and play twelve waves at one of
sixteen pitches from `BLIP_PITCHES` $D587 by the turn counter); 64 more bytes
of pitch tables after those sixteen that nothing reads (`SWEEP_PITCHES`,
`MORE_PITCHES`: a run of 32 climbing from $20 to $90 and back two at a time,
and two of 16); and `BEEP_BY_GRAPHIC` ($D665: six waves pitched by an
object's graphic; then eight pitched by a spare byte at $D673, zero and
written by nothing).

## How this was found

Read (stage 2, range 5). `PLAY_NOTE` ($D6C0-$D717) and `NOTES` compared byte
for byte with Knight Lore's (its $B2DA and $B332, from its snapshot):
identical, so Knight Lore's per-row pitches hold. The tunes' note names
computed from the table's scale. Every address of the unreached code was
searched for in the loaded block as a little-endian word: no references (two
chance matches inside other instructions).

## Confidence

*Read* throughout; the tune player's equivalence with Knight Lore's
*measured* (the byte comparison). Pitches in Hz are Knight Lore's
calculation, valid because the code is the same. No recording has been made
from these notes; the Sounds page records them from the game's own routines.

## Knight Lore

([`../knightlore/sound.md`](../knightlore/sound.md)) The same: the note
player, the note table, the one-wave routine. Close: `JUMP_SOUND` is Knight
Lore's werewolf warble with $A5 for $55; `PUFF_SOUND` its ROM-byte crash;
`BLIP_BY_TURN` its movable block's blip (four waves at one of eight pitches by
the frame counter), here gated on a flag and never called. New: the per-turn
effect sequencer. Gone: the turning and falling sounds (their tests are left
in the player's code, [`player.md`](player.md)).

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `BLIP_BY_TURN` | `DATAD56C` | $D56C | unused blip; now code |
| `BLIP_PITCHES`, `_B` to `_G` | `TEXTD587` ... `TEXTD595` | $D587-$D59A | its sixteen pitches, cut up by sna2ctl |
| `SWEEP_PITCHES`, `_B` | `DATAD59B`, `TEXTD5B3` | $D59B, $D5B3 | an unread run |
| `MORE_PITCHES`, `_B` to `_D` | `DATAD5B7` ... `TEXTD5D2` | $D5B7-$D5D6 | unread tables |
| `PAUSE_BEEP` | `SUBD5D7` | $D5D7 | pause and resume |
| `JUMP_SOUND` | `SUBD5E4` | $D5E4 | a jump |
| `EFFECT_NOTE` | `SUBD5F2` | $D5F2 | this turn's effect note |
| `EFFECTS` (and `EFFECT_PITCHES` $D615) | `DATAD60D` | $D60D | the effects' addresses and notes |
| `EFFECT_PITCHES_B`, `_C` | `TEXTD618`, `DATAD61B` | $D618, $D61B | effect notes |
| `FIRE_SOUND` | `SUBD629` | $D629 | a bolt fired |
| `FOOTSTEP` | `SUBD635` | $D635 | a step |
| `PUFF_SOUND` | `SUBD64E` | $D64E | a puff |
| `BEEP_BY_GRAPHIC` | `DATAD665` | $D665 | unused beeps (left as data) |
| `TABLE_WORD` | `SUBD692` | $D692 | HL = the word at BC + 2A |

## Disassembly corrections

- `STEP_SOUND` was "a count $D635 keeps for a sound": it counts his steps,
  and every fourth beeps.

## Open questions

- What the unreached blip and its tables were for; bit 1 of the flags, its
  gate, is the collision code's "being moved" bit, and a puff's.
- Whether `TUNE_UNUSED` was ever played in some version (only one tape looked
  at).
