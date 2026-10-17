# The main loop

**Question this answers:** what runs, in what order, from the moment the
game is loaded -- a game, a life, a pass of play -- how a death and the end
of a level are handled, and what sets the speed.

**Short answer:** `start` ($9A66) builds the shift tables and falls into
`game` ($F422), the outer loop: the menu, a new game, the panel, then
`play` ($F440), which runs once per life. A life is a fly-in
(`start_landscape`, $DCA1) and then the play loop at $F46C: five calls a
pass -- the ship and everything drawn with the landscape (`ship_pass`), the
fuel gauge, the spawner, the nine sky objects, the random numbers. Nothing
paces it: the game runs with interrupts off and never waits for a frame, so
a pass takes as long as its work, about two or three frames (some 20
passes a second). A death byte (`death_count`, $8F53) counting up a pass at
a time drives the death sequence; `launch_state` ($96AB) reaching $FF ends
the level.

## How it works

### From loading to the menu

```
game_entry $5C80   DI; JP start           (the loader jumps here)
start $9A66        SP = $5B80 (loader_entry); border black;
                   build_shift_tables $F86B; JP game
game $F422         every game starts here
  menu $F26C            title tune until a key, menu_loop $8615 until 0,
                        start tune
  new_game $F3BD        both player records cleared, 5 lives each,
                        control methods copied from the menu, places dealt
  clear_attributes $9A72, clear_pixels $9A7E, draw_panel $CA3F
  show_player $F4EE     PLAYER 1
  six calls of delay $A802, clear_play_area $9F2C
  JR play_0 $F44C       into the first life, past reset_for_life
play $F440         every later life (after a death, after a level)
  reset_for_life $F311  the per-life tables and records reset
  lives 0?  -> JP game  (back to the menu)
  draw_panel $CA3F
play_0 $F44C
  ore = ore_kept        the ore aboard comes back from the player record
  patch $E118, $A9B8, $ABDE   BIT/SET 7 for player 1, 6 for player 2
  start_landscape $DCA1 the fly-in; returns when play starts
play_2 $F46C       the play loop (below), until
  death_count >= 12     -> the death sequence at $F48B
  launch_state = $FF    -> level_done $F52A -> play
```

The first life of a game enters at `play_0` and skips `reset_for_life`; it
relies on the reset having run at the end of the last game (`play` resets
before it finds no lives and goes back to the menu) or, after loading, on
the tape's own values. *read*

Interrupts are never enabled: `loader_entry` ($5B80) and `game_entry`
($5C80) both execute DI and nothing executes EI. There is no HALT and no
interrupt routine, and the game's stack is the 128 bytes under $5B80
(see [`memory-map.md`](memory-map.md)). *read*

### One pass of the play loop

```
play_2 $F46C
  ship_pass $C374
    pass_counter +1; shield_timer -1 on odd passes
    save_restart_point $C33C           every fourth pass
    [death_count < 11]
      move_ship $B234
        read_controls $B115 -> read_control_method $B16F   (input.md)
                            -> add_fuel $CC4D              the burn
        accelerate_across $C7FC, clamp_climb $B322         scroll steps
      [not launching]
      ship_speed_from_scroll $B9EC     the ship record moves against them
      collide_with_landscape $BA21
      ship_hits_ground_objects $A8F4
      move_object $BF66
    update_shots $B706
    JP scroll_landscape $DDF8
      [a map cell crossed] load_map_window $DF08, set_landscape_colours
      update_ground_objects $AC60      before or after the landscape, by
                                       the sign of scroll_down;
                                       draws the rocket (draw_rocket)
      draw_landscape $D0BD             not in map rows 0-2
      draw_beams $9BDA, draw_stars $BFE3
      JP draw_ship $C3E3               (POPs the IY ship_pass pushed)
        [dying or launching: RET]
        drop_part $9724
        odd pass, or the image changed: draw_ship_image $C421, draw_trail
        even pass: carried_part $C1CE
        check_pause_in_play $9F54, fire $B731
        even: lift_jet $C6D2 / odd: side_jet $C5FF
        RET                            back to the play loop
  update_fuel_gauge $CC77
    flash_fuel_gauge $CAA7; check_fuel_empty $CC63
  spawn_tick $87AF                     spawn_cloud / spawn_attacker
  update_objects $8D42
    death_count +1 if not 0; wreck_ship $8CB2 at 10; sound_death from 10
    for each of the 9 sky records in use:
      count_and_erase $8E21, run_sky_object_handler $A18D,
      ship_contact $8E2D, test_player_shots $917C
    light load: a cloud or an attacker
  random $F23B
  death_count >= 12?  launch_state = $FF?
```

`ship_pass` does not return to the loop itself: it jumps to
`scroll_landscape`, which jumps on to `draw_ship`, whose RET returns to the
play loop. IY, pushed by `ship_pass`, is popped by `draw_ship`; the push
also puts the stack at the depth the landscape renderer assumes when it
reloads SP with $5B7A after each piece (`stack_top`): `CALL ship_pass`,
`PUSH IY`, `CALL draw_landscape` leave SP at exactly $5B7A, and the fly-in
path (`CALL start_landscape`, `PUSH BC`, `CALL draw_landscape`) does too.
*read; the depth worked out from the two call chains*

What runs every other pass: the ship's image and trail are redrawn on odd
passes (or on any pass where they change), the carried part on even ones;
the lift jet on even passes, the side jet on odd; the shield timer counts
on odd passes; the fuel gauge's colour on odd passes. Every fourth pass
`save_restart_point` offers the place as the next life's start.

### Timing

There is no frame lock. A pass is as long as its work: the landscape, the
compositor's rub-out-and-redraw of up to fifteen objects and the stars, and
the beeper sounds, which are timing loops inside the pass (a zap is about
37,000 T-states, half a frame; see [`sound.md`](sound.md)).

| | |
|---|---|
| passes a second | about 20, a pass every two or three frames (*measured* in stage 0 from 16 consecutive frames of flight) |
| the landscape | about 14,000 T-states a frame (*measured* in stage 0 with the profiler) |
| a pass, on average | about 145,000 T-states, some 2.1 frames: about 24 passes a second (*measured* in SkoolKit's simulator over 320 passes for the How it works page; the reference pages' shield trial gave 22.3) |
| where it goes | `update_objects` ($8D42) about 55%, `draw_landscape` ($D0BD) about 20%, some 29,400 T-states a pass -- the stage-0 figure again (*measured*, the same 320 passes) |
| the start-up | 571,650 T-states from $5C80 (*measured*, the How it works page) |

So a busy screen plays slower, and a sound effect stalls the pass it is
played in. Counts kept in passes (the shield, the death sequence, the fuel
grace) are therefore not fixed lengths of time.

### The death byte

`death_count` ($8F53) is the whole of the death's state.

| Value | What |
|---|---|
| 0 | alive |
| 1 | set by `contact_damage` on the third hit (from an attacker or a beam), or by `check_fuel_empty` once the gauge shows empty and the low seven bits of `pass_counter` are 0 -- up to 128 passes' grace |
| +1 a pass | counted by `update_objects` while not 0 |
| 1-3 | every sky object explodes (+$17 bit 3) |
| 10 | `wreck_ship` fills all nine sky records with the wreck; `sound_death` plays from 10 to $2C |
| 11 on | `ship_pass` reads no controls and moves nothing; `draw_ship` draws nothing |
| 12 | the play loop leaves for the death sequence |
| $50 | the death sequence ends |

While it is not 0, `ship_contact` ignores every touch and
`find_free_record` starts nothing new.

`draw_rocket` also writes 10 into it when the ship docks with the finished
rocket, for the length of two calls (`draw_ship_image` and `draw_trail`,
which then erase the ship), and puts 0 back at once. That is not a death,
and `update_objects` never sees the 10. *read*

### The death sequence ($F48B)

```
$F48B   scroll_across = scroll_down = 0; fuel = $BE00 (empty)
        draw_trail $C4ED (dying: erases the trail, and runs on through
        the pause test, fire and side_jet), lift_jet $C6D2 (dying: erases
        the lift jet)
$F49E   ship_pass, check_pause $9F4E, update_fuel_gauge, update_objects,
        carried_part, update_fuel_gauge         until death_count = $50
        play_tune death_tune $F4DD
        dissolve_and_clear $9EF5
        lose_life $F4C6
        JP play
```

From death byte 1 to 12 is eleven passes of play with the wreck flying;
12 to $50 is 68 passes more with the landscape still. The gauge is called
twice a pass here, so it drains two rows a pass to empty. *read*

**The wipe.** `dissolve_play_area` ($9EFE) ANDs every byte of the play area (28
bytes by 160 lines, from x 8, line $B7, upwards) with the next of nine masks at
`dissolve_masks` ($9F44), each with one bit clear (one with none), the walk
through the masks running on from byte to byte and line to line. Sixteen
sweeps, so pixels vanish in a scattered pattern rather than line by line; then
`clear_play_area` ($9F2C) zeroes it. About 4.9 million T-states, some 1.4
seconds (*counted* from the instruction timings). Run in SkoolKit's simulator
for the Animations page, each sweep took about 317,376 T-states (some 91 ms),
and the play area was black from the ninth of the sixteen (*run*).
`clear_play_area` alone is also used before the first life, after a game over,
at a level's end and at a change of player.

`lose_life` ($F4C6) keeps the ore aboard in the record (`ore_kept`), takes
a life (`lives`, $F5ED), and with none left goes to `game_over` ($F4FC);
otherwise, with two players, `swap_players` ($F591) hands over
([`players.md`](players.md)).

### Pause

`test_pause_keys` ($9EE3): SPACE or CAPS SHIFT. `check_pause_in_play`
($9F54, from `draw_ship` every pass of play) and `check_pause` ($9F4E, from
the death sequence) go to `pause` ($9F5B): wait for the key to be let go,
then for a second press, then for that to be let go, testing every
`pause_delay` (a `delay` of $40). Before waiting, the in-play entry calls
`side_jet`. Nothing else stops while paused, because nothing else runs.

### The end of a level

When the eighth rocket part is in place and the ship docks at its fixed
spot, `draw_rocket` sets `launch_state`; the rocket rises, and once part 0
has left the screen `launch_state` becomes $FF. The play loop then jumps
to `level_done` ($F52A):

```
level_done $F52A   clear_play_area
                   planet_secured $83D6   the planet-secured screen
                                          (panel-and-menu.md), 10 x 5000
                                          points with a zap each, the next
                                          planet
                   play_tune level_tune $F56A; 14 calls of delay
                   clear_play_area; player_flag_bits cleared (+3 to +5)
                   JP play                the same player's next life
```

`planet_secured` moves `level` (+$12 of the record, 0-4, the fifth wrapping
to the first) on. Nothing else in the game reads `level` but the planet's
name and its two landscape colours (`planet_ground_colours`, $DC97): the
next planet is the same map in other colours. It also sets
`rocket_part_carried` and `parts_built` to 6, deals the last pick-up place
(rocket part 7's, `place_last`) again from its group of four, and clears
the current player's gone bit in all 290 world objects
(`mask_world_objects` with $7F for player 1, $BF for player 2), so every
deposit, pad and beam maker is back. So a later planet starts with six
parts standing and the seventh -- part 6, the ore tank -- aboard: it needs
18 ore mined into the tank and the last part found. *read*; `level_done`
and `planet_secured` *run* in the build's launch session, which goes on to
the next planet's first pass, but what this means in play is inferred

### The end of the game

```
game_over $F4FC    show_player, the GAME OVER message
                   check_high_score $F54D   digit by digit against the HI
                   play_tune game_over_tune $F580
                   12 calls of delay, or until 0 is pressed
                   clear_play_area; two players: swap_players
```

`game_over` returns through `lose_life` to `play`, which resets, finds the
current player with no lives (the other one's, if `swap_players` did
nothing because they have none either) and jumps to `game`: the menu.

## How this was found

Read from the code in the stage 2 description of the listing
(2026-10-16): `start`, `game`, `play` and its neighbours to `swap_players`,
`ship_pass`, `draw_ship`, `update_objects`, `death_count`, `draw_rocket`'s
docking, `planet_secured`, the pause and the wipe. Stage 0 found the death
byte and the play loop live: memory diffed across a death led to the lives
at $F5ED, the code changing them to the death byte, and a watchpoint on it
to the fuel death. The pass rate and the landscape's cost were measured
then too.

## Confidence

The order of everything is *read*. The pass rate and the landscape's cost are
*measured* (stage 0); the wipe's length and the sound costs are *counted* from
instruction timings. The death by hits and by fuel were *watched* in stage 0;
the build's sessions also ran the death sequence, `game_over`, `swap_players`
and the menu, and since the staged launch `draw_rocket`'s docking and launch,
`level_done` and `planet_secured` (`cyberun-executed.map`). Never run in the
build's sessions: `check_fuel_empty`'s setting of the byte (stage 0 watched it
live instead), `check_pause`'s jump to the pause (the pause itself ran, from
`check_pause_in_play`) and `planet_secured`'s wrap from the fifth planet to the
first.

## Corrections

- Stage 0 (`damage-fuel-lives.md`) took $968D's write of 10 into
  `death_count` for "possibly the end of a stage". It is the docking with
  the finished rocket, held for two calls and put back to 0 at once; the
  level ends later, when `launch_state` reaches $FF.
- Stage 0 (`driving.md`) said holding SPACE through a death sequence
  "stopped the game there indefinitely". That is the pause: SPACE or CAPS
  SHIFT pauses, and the game waits for the key's release and then a
  second press.
- The range-2 draft said the death sound plays "at once on docking".
  `draw_rocket` puts the byte back to 0 before `update_objects` runs, so
  it does not (the listing's description of `sound_death` repeats the
  mistake; see [`sound.md`](sound.md)).
- The range-2 draft said the session coverage shows `planet_secured` ran; the
  build's executed map has none of it (nor `level_done`), and
  `cyberun-coverage.txt` leaves `planet_secured` out of its list. (That was
  before the staged launch; the build's sessions run both now.)
- The brief's first version had `lift_jet` ($C6D2) as part of the death
  sequence; the death sequence calls it once, to erase the lift jet.
- **Coverage** (2026-10-17): this file said `level_done`, `planet_secured` and
  `draw_rocket`'s docking and launch never ran in the build's sessions; the
  staged launch runs them all.
- **The compositor's "third of the time".** This table quoted it from a stage-0
  profile that no note records. The How it works page's measurement over 320
  passes replaces it: `update_objects` takes about 55% of a pass and
  `draw_landscape` about 20%.

## Open questions

- How long a pass really takes in a quiet place and a busy one: break at
  $F46C in the emulator and read the T-state count between hits.
- Whether anything ever runs the stack below $5B00 (128 bytes is a lot
  for this call depth, but nothing checks).
- What a later planet is like in play: the build's launch session plays a short
  round on the next planet, but nothing there was checked, so the six parts
  standing and the tank aboard are not yet seen.
