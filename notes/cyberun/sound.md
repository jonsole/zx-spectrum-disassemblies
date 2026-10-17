# Sound

**Question this answers:** how Cyberun makes its sounds with interrupts
off -- each beeper effect and what plays it, the tune player and its note
table, and the tunes.

**Short answer:** every sound is a timing loop that toggles the beeper
(OUT ($FE) with $10, then 0, so the border stays black) inside the pass
that asks for it, so a sound costs its own length in processor time. Two
building blocks -- a pulse with separate on and off lengths
(`beep_pulse`, $71D3) and a square-wave cycle (`beep_cycle`, $71E0) --
are driven by four kinds of loop: a rising sweep, a falling zap, a
two-note warble and a scrambled crackle. The tunes are a byte a note
(six bits of pitch, two of length) played through a 61-entry table of
semitones by `play_note` ($9AB4); the title tune is 250 notes long and
any key stops it.

## How it works

### The building blocks

| Routine | Does | Cost |
|---|---|---|
| `beep_pulse` $71D3 | speaker on for B loops, off for D loops | about 13 T-states a loop |
| `beep_cycle` $71E0 | on for B loops, off for B loops; B kept for the caller | about 26 x B T-states a cycle |
| `rising_sweep` $71F4 | C cycles, each of half period C + D, C counting down: the pitch rises | |
| `zap_sweep` $724E | C cycles of half period (NOT 4C) AND $7F, C counting down: the period grows, the pitch falls | |
| `warble` $7217 | for A of 0-6 or 9-15: four cycles alternating between B = 2A + $48 and B XOR $2A; nothing for 7, 8 or 16 and over | |
| `crackle` $7297 | C clicks, each B = 2(C XOR E) loops on and B AND $1F off: the XOR scrambles the lengths into noise, E picks the scramble | |

B or D of 0 counts 256 (DJNZ). All counted from the instruction timings,
without memory contention: the effects' code ($71D3-$731E) lies below
$8000, in the RAM the ULA contends while it draws the screen, so on a real
48K they would run somewhat slower and lower than counted. (The project's
emulator does not emulate contention yet, so it will not show this.)

### The effects

| Routine | Made of | Played by, and when |
|---|---|---|
| `sound_rising_whine` $71F0 | sweep, 32 cycles, half period $90 down to $71 (about 106,000 T-states) | `fly_in_step`, as play begins after a life's fly-in |
| `sound_pick_up` $71FE | sweep, 16 cycles from $50 to $41 (about 30,000) | `collect_pickup`: an add-on or rocket part taken |
| `sound_unused` $7204 | crackle, C = E = $17 | nothing calls it |
| `sound_debris` $720A | warble, the note the debris piece's path step (+$15) halved | `update_debris`, for each debris piece each pass while `death_count` is below 10 |
| `sound_flutter` $7234 | 4-32 cycles of (D XOR 7) + 1 as D counts down by two from 8 x (1 + the pass counter's low three bits) | `update_special_beam` while the special beam is out |
| `sound_zap` $724C | zap, 16 cycles, half period $3F up to $7B (about 37,000-39,000: half a frame) | the commonest: damage and a shielded ship ramming (`contact_damage`), the shield starting (`ship_contact`), the fuel thief (`contact_drain_fuel`), an extra life (`contact_extra_life`), shots hitting (`test_player_shots`), the tough attacker destroyed (`update_tough_attacker`), docking with the rocket (`draw_rocket`), each 5000 of the planet bonus (`planet_secured`) |
| `sound_ship_colour` $725C | sweep, 10 cycles from $8A to $81 | `colour_ship`, when the ship's colour changes |
| `sound_buzz` $7263 | 15 cycles of half period 32 or 256 loops, in runs of four (about 53,000) | `hit_block` (the ship hits a wall) and `ship_on_slope_response` (the ship's first pass on a slope) |
| `sound_hum` $7275 | sweep, 4 cycles from $13 to $10, odd passes only; a second branch, with +$16 bit 6 set, would play 3 cycles from $1E to $1C when the pass count AND 3 is 0 -- which no odd pass gives, so it never sounds (see Corrections) | `update_tough_attacker` (type $19), every pass |
| `sound_crackle` $7293 | crackle, 28 clicks, scramble $27 | `hit_block`: the ship bumps a floor or ceiling |
| `sound_tick` $72A5 | crackle, 8 clicks, scramble 3 | `move_or_explode` (an object blows up on the landscape), `probe_shot` (a laser meets the landscape) |
| `sound_death` $72AB | warble with the death byte less 10, then on every eighth count a 7-cycle zap, on other odd counts 11 clicks scrambled by the death byte halved | `update_objects` while `death_count` is 10 to $2C: the 35 passes after the ship breaks up |
| `sound_beams` $72CF | ((+0 XOR +1) AND 15) + 8 pulses, lengths from the beam record's bytes | the end of `draw_beams`, when a beam was drawn |
| `sound_crackle_b` $72F2 | crackle: 15 clicks scramble $17, or 23 clicks scramble $20 for a record with +$16 bit 7 | `fire`: a laser shot, or a homing missile |
| `sound_launch` $7303 | crackle, 4(A + 2) clicks (8-20) with A the pass counter's low two bits, the scramble from the count | `draw_rocket`, each pass of the launch |
| `sound_fire` $7311 | crackle, 10 clicks, scramble $22 | `fire_from` (in `ground_object_fires`): a ground object or attacker fires or throws |
| `sound_collect` $7318 | sweep, 10 cycles from $22 to $19 | `contact_collect`: an object collected by touch |

The costs in brackets are counted; the others are short (a few thousand
T-states) except the death sound, which adds a warble of about 9,000 and
a zap or a crackle to each of its passes.

**What it means for a game.** With no interrupt there is nothing to play
a sound over time, so each effect is played in full, at once, in the pass
that triggers it, and that pass is longer by the sound's length. Short
effects (a crackle of a few dozen clicks, a hum of four cycles) cost
little; the zap is half a frame, the whine a frame and a half. The game
leans on per-pass effects -- the hum, the flutter, the death sound, the
launch -- whose variation from pass to pass (the pass counter, a record's
bytes) makes them sound continuous and alive.

### The tune player

```
play_tune_until_key $9A9A   before each note: any key down (read_keyboard
                            with all half-rows)? return NZ
play_tune $9AA9             to the $FF that ends the tune
play_note $9AB4             one note
```

A note is one byte: bits 0-5 the note number (0 a rest), bits 6-7 its
length less one, 1-4 units. Its entry in `note_table` ($9B0C, 61 entries of
three bytes) gives the half-period as a DJNZ count B and a pass count C --
about 256(C - 1) + B loops of 13 T-states -- and the cycles in one unit.
`play_note` multiplies the cycles by the length and toggles the speaker,
$00 then $10. A rest counts BC down from $430B in a 26 T-state loop, about
0.13 seconds a unit.

Entries 1-60 rise a semitone at a time -- in loop counts: 256(C - 1) + B is
equal-tempered to within 7 cents. Each half-wave also spends a fixed time
outside its loops, so the scale actually played bends from 37 cents sharp at
entry 1 to 34 cents flat at entry 60 against the best-fitting semitone series;
the top note is 1524 Hz (*measured* from recordings of the game's own
`play_note` in SkoolKit's simulator, which match its timing to the T-state; the
Sounds page has the table). That the table was worked out as loop counts is an
inference. The cycle counts rise with the pitch so that a unit lasts about 0.15
seconds whatever the note. One slip: entry 18 has the same delay as entry 17
(only its cycle count differs), so note 18 sounds as note 17 and the step from
17 to 19 is two semitones. No tune uses note 18.

### The tunes

| Tune | Address | Notes | Played by |
|---|---|---|---|
| title | `title_tune` $70D8 | 250 and the $FF, notes 25-49 | `menu`, until a key (`play_tune_until_key`) |
| start | `start_tune` $F4E4 | 9 | `menu`, as the menu ends |
| death | `death_tune` $F4DD | 6 | `play`, at the end of the death sequence |
| level | `level_tune` $F56A | 21 | `level_done`, after the planet-secured screen |
| game over | `game_over_tune` $F580 | 16 | `game_over` |

Only the title tune can be cut short; the others hold the game until they
end.

## How this was found

Read from the code in the stage 2 description of the listing
(2026-10-16): every routine from $71D3 to $731E, `play_tune_until_key`,
`play_tune`, `play_note` and the tunes, each effect's parameters worked
out by hand from its constants and its callers from the listing's
cross-references. The note table's pitches and the tunes' note ranges were
computed from the snapshot's bytes with a script for these notes.

## Confidence

*Read*, and since the Sounds page (2026-10-17) *measured*: every effect and
tune was recorded from the game's own routines in SkoolKit's simulator and
matched wave by wave against a model of its routine, and eight real runs (game
start, all add-ons, the shield running out, tours of map rows 3 and 16, out of
fuel, game over, the launch) had every edge identified. Heard in those runs: 14
of the 17 effects, among them `sound_beams` and `sound_launch` (the launch),
`sound_flutter` (the add-ons), `sound_ship_colour` (the shield), `sound_buzz`
and `sound_fire` (the row-3 tour) and `sound_hum` (the row-16 tour). Not heard:
the pick-up, `sound_unused` (nothing calls it) and the collect. The build's own
sessions (`cyberun-executed.map`) run every effect but `sound_unused` and
`sound_ship_colour` -- none of them has the shield or a full tank -- the
pick-up, the collect and `sound_crackle_b`'s second branch (a missile's)
included. Never run anywhere: the second branch of `sound_hum` (it cannot
sound, below) and the rest in `play_note` -- none of the five tunes has a rest.

## Corrections

- `sound_hum`'s second branch can never sound: the routine returns on even
  passes, and the branch then wants the pass count AND 3 to be 0, which no
  odd pass gives. Eight calls with +$16 bit 6 set were all silent
  (*measured*, the Sounds page). These notes and the listing said it played
  one pass in four.
- The note table's top pitch is 1524 Hz, not "about 1.6 kHz"; the played
  scale bends against the table (above).
- The range-2 draft and the listing's description of `sound_death` say it
  also sounds "at once" when the ship docks with the finished rocket,
  which sets the death byte to 10. `draw_rocket` puts the byte back to 0
  before `update_objects` -- the only caller -- runs, so it never does; the
  docking's sound is a zap.
- The listing says `sound_buzz` alternates "two of each in turn"; the half
  periods come in runs of four (32, 32, 32, 32, 256, ...).
- The listing's `note_table` says entries 1-60 each rise a semitone;
  entry 18 repeats entry 17's pitch.
- This file's Confidence said the build's staged sessions run
  `sound_ship_colour` and that `sound_crackle_b`'s second branch never ran. By
  the build's executed map it is the other way round: no session has the shield
  or a full tank, so `sound_ship_colour` was heard only in the Sounds page's
  own shield run, and the every-add-on session's missiles play the crackle's
  second branch (*run*).

## Open questions

- How much slower and lower the effects are on a real 48K, where their
  code is in contended memory: a recording from real hardware, or the
  emulator once it emulates contention.
- What the tough attacker's second hum (+$16 bit 6) marks.
