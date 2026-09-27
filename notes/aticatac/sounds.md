# Sounds

**Question this answers:** every sound the game makes, what plays it and
when, and how the two kinds -- played at once, and spread over frames -- work.

**Short answer:** everything is `BEEP` ($A3A8): toggle bit 4 of port $FE with a
busy wait of B for C cycles, the border written black each time. Most sounds
are short runs of `BEEP` played inside the routine that wants them (a few
milliseconds; the game stops meanwhile). Three -- being caught, entering a
room, eating -- are started in the sound slot at $EAA0 and play a slice each
frame for 10 or 16 frames, their pitch following the count so they glide.

## How it works

**The sound slot** (*read*): `PLAY_SOUND_CAUGHT` ($A3E5), `PLAY_SOUND_NEW_ROOM` ($A403) and
`PLAY_SOUND_EATING` ($A485) write a type and a length into $EAA0; `FRAME_TICK`
dispatches it each frame, the handler counts down, beeps once from the count,
and zeroes the type at the end (`END_SOUND` $A3FE). There is one slot: a new
sound replaces one still playing.

| Sound | Started by | Frames | Shape |
|---|---|---|---|
| $64 (`SOUND_CAUGHT` $A3EF) | `CHECK_HIT` -- a creature touches the player; each pass on a mushroom | 16 | C = count cycles at half-period count XOR $43: a short glide |
| $65 (`SOUND_NEW_ROOM` $A408) | `ARRIVE_IN_ROOM` -- every room entered | 10 | pitch from the count along another curve |
| $A0 (`SOUND_EATING` $A48B) | `EAT_FOOD` | 16 | pitches from `SWEEP_PITCHES` ($A4A0) read from its end: falling from high to a note that wavers between two |

**Played at once** (*read*; lengths and pitches from the build's Sounds page,
which records each routine on a fresh machine):

| Routine | Played by | What |
|---|---|---|
| `SOUND_FOOTSTEP` $A3C7 | the three characters, every fourth frame while walking | every other call; low ($6004, ~1360 Hz) and high ($4004, ~2005 Hz) in turn: a click every eight frames |
| `SOUND_SWEEP_A41B` $A41B | the knight firing | twelve steps, falling |
| `SOUND_SWEEP_DOWN` $A438 | the wizard firing | eight steps |
| `SOUND_SWEEP_UP` $A427 | the serf firing | sixteen steps, rising |
| `SOUND_BOUNCE` $A4B0 | any weapon bouncing off a wall (`SPIN_WEAPON`) | a low blip |
| `SOUND_WEAPON_GONE` $A445 | any weapon's flight ending, and any burst ending (`WEAPON_GONE`) | a quick sweep whose start depends on how many creatures are in the room (`ACTORS_HERE`) |
| `BEEP_ENTRIES` $A3BD | picking an object up | 64 cycles, half-period $40, ~30 ms |
| `SHORT_HIGH_BEEP` $A3C2 | an object falling out of the inventory | 128 cycles, half-period $20: an octave higher, as long |
| `SOUND_LIFE_PIP` $A3E0 | `FLASH_SCORE`, every sixteenth of the 104 frames at the start of a life | a steady ~1030 Hz pip, 93 ms |
| `SOUND_RISE_SINK` $A45F | `DYING` and `MATERIALISING`, every frame | pitch from +$06, the number of rows still showing: the note moves as the figure sinks or rises |
| `SOUND_NOISE_BURST` $A46E | a timed door or trapdoor changing state | eight bits of each of 48 ROM bytes from $0000 to the speaker: a rasp |
| in `TRAPDOOR_FALL` $9731 | falling through a trapdoor | 128 frames of `BEEP` with a pitch from the loop count, falling |

## How this was found

Read `BEEP`, every caller of it and of the three slot starters (searched as
operands). The recordings, lengths and frequencies are the build's
(`record_sounds`, 2026-08-30), captured from the port writes; the footstep's
pace was recorded in a real run of the walking handler.

## Confidence

*Read*; the numbers *measured* by the build. The slot sounds, the pick-up and
drop beeps, the rise-and-sink note and the fall are not on the Sounds page and
have not been recorded.

## Renamed routines

Applied to the annotations on 2026-09-27; the build verified byte for byte.

| New name | Old name | Address | Role |
|---|---|---|---|
| `SOUND_WEAPON_GONE` | `SOUND_SPELL` | $A445 | a weapon's flight or a burst ending |
| `SOUND_BOUNCE` | `SOUND_SPELL_2` | $A4B0 | a weapon bouncing |
| `SOUND_RISE_SINK` | `SOUND_FROM_HEADING` | $A45F | sinking and rising |
| `SOUND_LIFE_PIP` | `SOUND_BONUS` | $A3E0 | the start-of-life pip |
| `SOUND_CAUGHT, SOUND_NEW_ROOM, SOUND_EATING` | `SOUND_64, SOUND_65, SOUND_A0` | $A3EF, $A408, $A48B | the slot sounds' handlers |
| `PLAY_SOUND_CAUGHT, PLAY_SOUND_NEW_ROOM, PLAY_SOUND_EATING` | `PLAY_SOUND, PLAY_SOUND_65, PLAY_SOUND_A0` | $A3E5, $A403, $A485 | their starters |

## Disassembly corrections

All applied to the annotations, the ref and the build on 2026-09-27 (the old names are used below), except where marked.

- `SOUND_SPELL` ("The wizard's spell ... Called from SPIN_SPELL") and
  `SOUND_SPELL_2` ("The spell's second noise"): both are in `SPIN_WEAPON`,
  shared by all three weapons -- the end of a flight or a burst, and a bounce.
  The Sounds page repeats the names.
- `SOUND_FROM_HEADING`: "the noise a thing makes depends on which way it is
  going". Its only caller is the dying/rising colour step; +$06 there is the
  row count.
- `SOUND_NOISE_BURST`: reached from `RESTART_WAIT` (the timed doors) and the
  trapdoors' tail, not from $917D as the Sounds page says; it reads ROM bytes
  for its noise.
- `SWEEP_PITCHES`: "wavers on one note and then climbs away from it". The
  handler reads it from the last entry down, so in time it falls from a high
  pitch and ends wavering.
- `BEEP`'s annotation at $A3B3: the OUT writes 0 to the border bits, so the
  border is black -- right; `CLEAR_SCREEN` sets it black as well.

## Open questions

- Record the three slot sounds and the fall for the Sounds page, from a game
  in progress rather than a fresh machine (they need `FRAME_TICK` to play).
