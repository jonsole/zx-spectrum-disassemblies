# Sounds

**Question this answers:** every sound Ant Attack makes -- what makes it,
when, and whether the recordings on the Sounds page are what the code says
they should be.

**Short answer:** the machine code has four OUTs to port $FE, two in `TONE`
($8B80) and two in `NOISE` ($8B4A). `TONE` plays one entry of a 16-note
table (`TONES`, $8BB1); `NOISE` flips the speaker from `RANDOM`'s working.
Only two routines call them: `RUN_SCRIPT` ($8E0D), for the sound bytes in
the 17 scripts, and `HANDLE_EVENTS` ($8F00), for a five-bit click on every
footstep. The BASIC adds four BEEP statements (title logo, title scale, the
key on a card, out of time), played by the ROM. There is no other sound: a
grenade in flight, an ant, a fall are silent except through a script, and
the game stands still while a script plays. Every recording matched the
code's arithmetic exactly (OUT counts, edge counts, every half-wave's
T-states); the BEEPs are a few cents sharp of what BASIC asks, because of
the ROM, not the game.

## How it works

```
GAME_FRAME $8E80
  ...
  HANDLE_EVENTS $8F00   event 1 only (a step, a short landing): NOISE, B = 5
                        bad fall / blast / bite: PLAY_SCRIPT with its number
  GRENADE_SOUNDS $8FD0  thrown: script 4; exploded: script 5; hit an ant: 3
MOVE_RESCUEE $8F80      found: script 12
CHECK_RESCUED $8EA0     both out: script 13
PARALYSE_ANT $8BD1      script 16
PRINT_COUNTERS $81E4    scripts 4, 8, 11 at the start of every PLAY call
FINAL_SCRIPT $8EF2      script 17, from BASIC line 3600

PLAY_SCRIPT $8E02 -> RUN_SCRIPT $8E0D
  byte $80-$FE: note = bits 0-3, times = bits 4-6 + 1
                note $0F: NOISE with B = 0 (256 random bits), else TONE
  $7D colour, $7E number, anything else printed (RST $10)
```

| Routine | Timing (T-states) | Leaves the speaker |
|---|---|---|
| `TONE` | half-wave = 14 E + 84 (E = 0 means 256); B OUTs, then one more | off |
| `NOISE` | a random bit every 194 (CALL `RANDOM` 17 + 142, AND, XOR, OUT, DJNZ); the last OUT 23 after | **on** |
| ROM `BEEPER` $03B5 | half-wave = 4 HL + 118, both halves alike; 2(DE + 1) edges | off |

- **The note table** is a chromatic scale from 477 Hz (about 40 cents above
  A#4) to 1078 Hz (about 50 cents below C#6), each note about 39 ms: B
  rises with the pitch to keep the length. Entry 15 is never played; note
  $0F means noise. (*read*; every pitch *measured* exactly in the scripts.)
- **TONE's first half-wave is silent** after another note or a BEEP: it
  flips the border-plus-$18 value to speaker off before its first OUT. After
  NOISE, which leaves the speaker on, that first OUT is an edge. Edges per
  note = (speaker was on) + B - 1 + (B even). (*read*, and the edge count
  predicted this way matched every script's recording exactly.)
- **`BORDER` ($B42C) is the border colour for the sound routines.** Every OUT
  to $FE sets the border too, so both routines OR the border colour with $18
  (MIC and speaker). BASIC sets it: 0 for play (line 200's DATA into
  $B420-$B438, matching line 300's BORDER 0) and 5 before the ending (line
  3600, matching line 2000's BORDER 5). Nothing in the machine code writes
  it: the only references to $B42C in the code are the two reads, and no
  LD L,$2C builds its address. (*read*, and searched; the recordings show every script's OUTs wrote border 0, and
  script 17's wrote 5.)
- **Script 4's blip sounds twice at the start of every level**: `PRINT_COUNTERS`
  runs scripts 4, 8 and 11 at the start of every `PLAY`, and BASIC calls
  `PLAY` twice a level (lines 700 and 720). Scripts 8 and 11 have no sound
  bytes. (*read*, and *watched* in the simulator: between the story card's
  key and play, TONE played exactly two notes of note 12.)
- **NOISE's random bit** is bit 4 of what `RANDOM` ($8360) leaves in A, not
  the carry `RANDOM` returns: that is bit 2 of `RANDOM_BITS`' first byte
  ($B428) before the shift, XOR the carry on entry -- which is always clear
  in `NOISE` (its AND, XOR and OR clear it). (*measured*: `RANDOM` run for
  all 256 values of that byte, both carries.) So a burst is a new random
  bit every 194 T-states, about 18,000 a second.
- **The footstep click**: `MOVE_OBJECT` sets the event byte (+$0F) to 1 on a
  step and on a landing from under five frames' fall; `HANDLE_EVENTS` clicks
  only when the two event bytes OR to 1, so a frame with a bite, blast or bad
  fall plays that script and no click. (*read*; *measured*: 12 steps, 12
  clicks of 6 OUTs, one a frame at about 6.5 frames a second.)

The BEEPs in the BASIC: line 3110 (40 BEEPs of 0.05 s at pitch 1 then 0,
four each, between redraws of the title logo), line 3120 (21 BEEPs of
0.02 s rising by three semitones from 0 to 60), line 960 (one of 0.01 s at
40, after the key on every story and score card) and line 3220 (14 of 0.2 s
falling by three from 40 to 1, on the out-of-time card).

## How this was found

- Searched the listing for every OUT: four, all in `TONE` and `NOISE`;
  their callers are `RUN_SCRIPT` and `HANDLE_EVENTS` only. So footsteps and
  throws were checked in the code, not guessed: a step is `NOISE` with
  B = 5; a throw is script 4's one note.
- Decoded each script's sound bytes against `RUN_SCRIPT`'s format and
  counted `TONE`'s loop from its instructions (14 E + 84) before running
  anything; the recordings then matched to the T-state.
- Counted the ROM's `BEEPER` loop from its bytes: 60 T-states after the OUT
  on the DE path, 44 on the other plus one extra inner turn from its INC C,
  L AND 3 NOPs, the inner loop 16 a turn, 1024 per H: 4 HL + 118 a
  half-wave. The ROM's own sums (`HL = 437500/f - 30.125`) allow 120.5, so
  BEEP is 2.5 T-states a half-wave short: sharp by 25 cents at pitch 60
  (8.4 kHz), under 1 cent at middle C. DE and HL at each BEEPER entry were
  round(f t) - 1 and round(437500/f - 30.125) every time.
- Recorded with `scripts/antattack_sounds.py`: a tracer on SkoolKit's
  simulator logging every OUT to $FE with PC, B and E, so each edge could be
  put down to the instruction and note that made it.

## Confidence

- *Measured* (deterministic; the module checks each at build time): every
  TONE OUT count and edge count, every whole wave's T-states, every NOISE
  OUT count and spacing, every BEEPER's DE, HL, edges and half-wave.
- *Read*: what calls each script and when (the callers' code).
- The simulator is uncontended. The machine code's loops run above $8000
  and the ROM is uncontended too, so only the OUTs would be delayed on a
  real 48K, by a few T-states at most; not measured on hardware.
- The out-of-time recording pokes the clock to 2 ticks rather than waiting
  it out; the BEEPs after it are BASIC's, unaffected.

## Disassembly corrections

- `RANDOM` ($8360)'s description says `NOISE` ($8B4A) uses the carry out to
  make its hiss. It uses bit 4 of A instead (`AND $10` after the call), which
  is bit 2 of $B428 before the shift (see above). Reported to the lead
  2026-09-27; the annotation is theirs to change.

## Open questions

- None about the sounds themselves. Not recorded: the score card's key BEEP
  separately (it is the same line 960 as the story card's).
