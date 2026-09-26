# Sound

**Question this answers:** How does Knight Lore make its music and effects?

**Short answer:** Everything is the beeper, driven by timing loops that hold
the CPU: nothing else runs while a sound plays. Tunes are strings of note bytes
(six-bit pitch index, two-bit length) played through a 61-row semitone table.
Effects are short bursts built from one routine that toggles the speaker for C
waves of half-period B, with pitches taken from object positions, ROM bytes or
small formulas.

## How it works

```
play_audio $B2CF ----------------+
play_audio_wait_key $B2B6        |      (once per menu visit, flag $5BD1)
  play_audio_until_keypress $B2BE+-- play_note $B2DA
    keypress_tune_note $B2C5          calc_duration $B2F9 (waves x length)
                                      note_wave $B300: off, wait; on, wait
                                      snd_delay $B31C: a rest

effects -> toggle_audio_hw_xC $B4E6 (C waves) -> toggle_audio_hw $B4ED (one wave)
```

**Note format.** Bits 0-5: index into `freq_tbl` ($B332), 0 = rest. Bits 6-7:
length - 1 (one to four units). $FF ends a tune.

**freq_tbl.** Row n (1-60) is three bytes: B, C, cycles. Each half-wave waits B
turns of DJNZ, then 256 more for each further count of C, at 13 T-states a turn;
one wave is two half-waves plus 101 T-states of loop. The third byte is the
number of waves in one unit, scaled with the pitch so a unit lasts about 0.155
seconds for every note. Row 1 is about 52.6 Hz and row 38 about 440 Hz; the
rows are equal-tempered semitones from G#1 to G6, drifting from about a fifth of
a semitone sharp at the bottom to half a semitone flat at the top. Row 18 has
the same pitch bytes as row 17 (C3 twice, no C#3) while its cycle count
continues the progression -- a slip in the table. No tune uses row 18, so it is
never heard. A rest unit is 17163 turns of a 26 T-state loop, about 0.127 s;
no tune uses one.

**Tunes.**

| Label | Address | Where | Notes |
|---|---|---|---|
| start_game_tune | $B20E | `main`, in full | 9 notes, lengths 1-4 |
| game_over_tune | $B218 | $BA87, until a key | 32 notes alternating a moving upper line and a held bass |
| game_complete_tune | $B239 | `game_complete_msg`, in full | 25 notes |
| menu_tune | $B253 | menu loop, once per visit, until a key | 98 notes alternating two lines |

The key check in `play_audio_until_keypress` does OUT ($FD) with A=0, which
selects every half-row at once, so any key stops it.

**Effects.** One wave is `toggle_audio_hw`: speaker bit on for B DJNZ turns,
off for B turns, border black; B is preserved so `toggle_audio_hw_xC` repeats
the same pitch C times. A half-wave count of 128 is about 1 kHz.

| Label | Address | Sound | Used by |
|---|---|---|---|
| sound_movable_block | $B3E9 | 4 waves, pitch from `block_blip_pitches` by frame | type 62, every frame |
| sound_sparkle | $B403 | (~type AND 31) blips of 2 waves, pitches = ROM bytes from $1234 | death sparkles; charm into cauldron (with the colour cycling) |
| sound_materialise | $B419 | rising sweep, 3 to 27 steps, longer each frame | types 120-126 |
| sound_thud | $B42E | 4 low blips of 3 waves from ROM $0000-$0003 OR $C0 | balls landing, flames turning |
| sound_jump | $B441 | 32-step rising sweep | Sabreman jumping |
| sound_pitch_from_z | $B451 | 6 waves, higher when higher | sinking block, dropping spiked ball, bouncing ball, Sabreman falling |
| sound_pitch_from_a | $B454 | 6 waves, B = (~A) rotated left twice | the above three; the finale tone from $5BC5 |
| sound_pitch_from_x / _y | $B45D / $B462 | as above, from X or Y | sliding blocks, moving flames |
| sound_pitch_from_xyz | $B467 | as above, from X+Y+Z | charms, table and chest moving; ghosts turning; portcullis rising; repel spell; type 111 vanishing |
| sound_transform | $B472 | 16-40 steps of pitch (C XOR $55)+C | types 92-95 |
| sound_portcullis_crash | $B489 | 16 blips of 2 waves, pitches from a random address below $2000 | portcullis landing |
| toggle_audio_hw_x16 | $B4A3 | 16 waves at 128 | pick up / drop, extra life, menu choice |
| toggle_audio_hw_x24 | $B4A8 | 24 waves at 80 | pause and unpause |
| audio_guard_wizard | $B4AD | footstep: every other walk frame; pitch alternates fixed/height; 3-12 waves by X and Y | guard and wizard legs |
| sound_walk_step / sound_footstep | $B4BB / $B4C1 | the same for Sabreman, opposite phase | walking; turning on the spot |

## How this was found

Read `play_note` and counted T-states from the Z80's documented timings for
both wait loops and the surrounding code; turned each `freq_tbl` row into a
frequency with a small script (3.5 MHz, no contention) and each tune into note
names. Callers of each effect found by searching the listing for the call.

## Confidence

Read, apart from the frequencies, which are computed from instruction timings
rather than measured; OUT to the ULA port is contended on a real machine, which
would move them slightly.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| keypress_tune_note | loc_B2C5 | $B2C5 | play one note of a tune a key can stop |
| restore_tune_ptr | loc_B2FF | $B2FF | POP DE after the length multiply |
| note_wave | loc_B300 | $B300 | one wave of a note |
| note_first_half | loc_B304 | $B304 | first half-wave wait |
| note_second_half | loc_B30F | $B30F | second half-wave wait |
| rest_unit | loc_B327 | $B327 | one unit of a rest |
| rest_countdown | loc_B328 | $B328 | the rest's wait loop |
| sound_movable_block | audio_B3E9 | $B3E9 | type 62's blip |
| block_blip_pitches | byte_B3FB | $B3FB | its eight pitches |
| sound_sparkle | audio_B403 | $B403 | ROM-byte burst |
| sparkle_blip | loc_B40D | $B40D | one blip of it |
| sound_materialise | audio_B419 | $B419 | materialising sweep |
| materialise_sweep | loc_B423 | $B423 | one step of it |
| sound_thud | audio_B42E | $B42E | four low blips |
| thud_blip | loc_B433 | $B433 | one blip of it |
| sound_jump | audio_B441 | $B441 | jump sweep |
| jump_sweep | loc_B443 | $B443 | one step of it |
| sound_pitch_from_z | audio_B451 | $B451 | pitch by height |
| sound_pitch_from_a | audio_B454 | $B454 | pitch by A |
| sound_pitch_from_x | audio_B45D | $B45D | pitch by X |
| sound_pitch_from_y | audio_B462 | $B462 | pitch by Y |
| sound_pitch_from_xyz | audio_B467 | $B467 | pitch by X+Y+Z |
| sound_transform | audio_B472 | $B472 | transformation warble |
| transform_warble | loc_B47D | $B47D | one step of it |
| sound_portcullis_crash | audio_B489 | $B489 | portcullis landing |
| crash_blip | loc_B495 | $B495 | one blip of it |
| sound_walk_step | audio_B4BB | $B4BB | Sabreman's footstep, even frames only |
| sound_footstep | audio_B4C1 | $B4C1 | Sabreman's footstep |
| footstep_pitch | loc_B4C6 | $B4C6 | fixed or height pitch |
| footstep_length | loc_B4D1 | $B4D1 | wave count from X and Y |
| speaker_on_wait | loc_B4F2 | $B4F2 | first half of a wave |
| speaker_off_wait | loc_B4F9 | $B4F9 | second half of a wave |

Also renamed in this range, outside the three subjects:

| New name | Old name | Address | Role |
|---|---|---|---|
| overlap_test_obj | loc_B510 | $B510 | do_any_objs_intersect: test one record |
| overlap_done | loc_B524 | $B524 | its exit |
| overlap_next_obj | loc_B52E | $B52E | its loop step |
| rotate_wanted_once | loc_B54C | $B54C | shuffle_objects_required: one rotation |
| rotate_wanted_entry | loc_B555 | $B555 | one entry moved down |
| set_spark_frame | loc_B5A4 | $B5A4 | finale spark: random frame 131-133 |
| spark_tone_and_move | loc_B5A9 | $B5A9 | finale spark: height to $5BC5, then move |
| spark_near_player | loc_B5C4 | $B5C4 | finale spark: distance on X |
| spark_check_y | loc_B5CF | $B5CF | ... and on Y |
| spark_touch | loc_B5DE | $B5DE | within 6 on both: game complete |
| spark_home_in | loc_B5E3 | $B5E3 | fly level at Sabreman |

`p4_m4`, `p4_p4`, `m4_m4`, `m4_p4` are kept; note that they name dY first
(H), then dX (L): `p4_m4` is dY +4, dX -4.

## Open questions

- Why the bottom of `freq_tbl` runs sharp.
