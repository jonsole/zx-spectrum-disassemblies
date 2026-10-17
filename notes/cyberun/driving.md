# Driving Cyberun

**Question this answers:** how to run the game where it can be watched --
in SkoolKit's simulator, the way the build does, and live in the emulator --
and how to stage the states play takes too long to reach.

**Short answer:** load the snapshot the build makes (PC $5C80, the game
decoded and not yet run). The title tune plays first and any key cuts it
short; the menu's loop `menu_loop` ($8615) and the play loop (inside
`play`, at $F46C) are each reached once a pass, so a script waits on those
rather than on time. Keep the ship alive for long runs by zeroing the hit
counter and refilling the fuel between slices, or with the pokes.

## The simulator

`Machine` in `scripts/build_cyberun.py`: SkoolKit's C simulator over the
snapshot with the 48K ROM below it, interrupts off (the game never enables
them), and a tracer whose `read_port` reports held keys and a Kempston stick
on port $1F. Session steps are `(keys, seconds[, stick])`, a function of
memory (a poke), `Until(what, test, seconds, keys)` and `At(what, address,
seconds, keys)`, which runs until PC reaches the address while holding the
keys, then lets them go.

## Starting a game

`_start(control, players)`: `At` `menu_loop` ($8615) holding ENTER (to cut
the tune short), poke the menu's control choices -- the third byte of
`player1_pointer` ($8708) and `player2_pointer` ($870B), i.e. $870A and $870D
(0 keyboard, 1 Kempston, 2 cursor, 3 Interface II) -- and `player_count`
($F2E2: 0 one player, 1 two), press 0, and `At` the play loop at $F46C.

**Don't hold SPACE or CAPS SHIFT to skip the tune.** They are the pause
keys (`test_pause_keys` $9EE3, `pause` $9F5B), tested during play and the
death sequence: holding SPACE paused the game there indefinitely (found when
the build's game-over session never got back to the menu). ENTER is safe: in
play it only thrusts.

## Keys in play

| Keys | Action |
|---|---|
| A S D F G H J K L ENTER | thrust (bit 3) |
| Q W E R T Y U I O P | fire (bit 4) |
| X V N SYMBOL SHIFT | right (bit 0) |
| Z C B M | left (bit 1) |
| 1-0 | bit 5, the special key: the special beam, with add-on 7 fitted and the ship still |
| SPACE, CAPS SHIFT | pause; again to go on |

## Variables worth watching

| Address | What |
|---|---|
| `death_count` $8F53 | 0 alive; counts up through a death; 12 starts the death sequence, $50 ends it (10 for a moment while docking) |
| `hit_count` $8FC3 | hits taken; the third kills |
| `fuel` $CC4B | a word: high byte $42 full, $BE empty |
| `lives` $F5ED | the current player's lives (5 at a new game) |
| `control_method` $F603 | the current player's control method |
| `launch_state` $96AB | non-zero while the finished rocket rises; $FF ends the level |

[`memory-map.md`](memory-map.md) has every variable.

## Staging

| To | Do |
|---|---|
| put the next life anywhere | `new_life_at(restart_at(column, row, view_x, view_y, pokes={...}))`: empty the tank, and when the death byte reaches $50 -- after the death sequence's last `save_restart_point` -- write the restart point (`restart_scroll` $F5FA, `restart_view` $F5FC, `restart_fine` $F5FE) and any other bytes; the next life flies in there, built by the game. Writing it any earlier is undone: the restart point is saved every fourth pass, death sequence included |
| start the launch | `restart_at(*ROCKET_VIEW, pokes={PARTS_BUILT: 8})`: the ship starts at page column $52 x $5C, row $0A, inside the rocket, which `draw_rocket` ($9672) waits for |
| deliver a part | the same place, with the hook (add-ons 1 and 2: `ADDON_SLOTS`) and `PART_CARRIED` set; part 6 also wants `ORE` = 18 |
| fit every add-on | `all_addons` at the end of a death sequence |
| keep the ship alive | between slices, `$8FC3` = 0 and `$CC4B` = $4200 (`_keep_alive`) |
| kill the ship at once | `$CC4B` = $BE00: the gauge empties and $CC63 sets $8F53 within a pass or two |
| end the game | `$F5ED` = 1, then kill the ship |

**Stage only at places the game would save.** `save_restart_point` keeps only a
place whose bottom row is the ground's dither or whose four cells are sky, and
the fly-in assumes one. Given another, it can write outside the screen:
`restart_at(9, 3, $80, $80)`, in the sky, hung, writing in 256-byte strides
over $5C00-$F8FF and into the code at $D45B, looping at $D435-$D45B;
`restart_at(9, 4, $80, $60)` left checker strips above the play area and in the
panel (*run*, 2026-10-17). The build's own tours (column $20, rows 3, 12, 16,
20 and 22, at $80/$60) were checked the same day: the only code bytes they
change beyond ordinary play are the known patch points ($BD16, $BD2B, $DB92,
$DBC1, $DBC6, $A4C5), so no stray writes.

Two staging hazards in the build, noted here and not changed: `ROCKET_VIEW` can
leave the ship at x $5E rather than $5C, depending on the life before, and
`draw_rocket` docks only at $5C (the build's own sessions do dock,
deterministically); and `new_life_at`'s 10-second wait for the fuel death can
be too short -- about 12 seconds were needed once -- so 30 would be safer.

## Live, in the emulator

A private `zx_server` on ports 14711/18000/18500 with `--no-audio` (see the
`zx-live-verify` skill). Load the tape (`load_tape`), uncapped until the
menu shows, press 0. Snapshots saved on the pad after the first death are a
good fixed starting point for repeatable runs. The pokes in
[`pokes.md`](pokes.md) keep a live run going indefinitely.

**Don't start a life inside rock in the deepest caverns.** A tour staged at
map row 24 put the ship, probably inside rock, where nothing stopped it
falling (*inferred*; not investigated further); it sank past the
map's last row and the game ran into the frame's corner bitmaps and stopped
on a HALT. The build now fails on that (`check_executed_in_code`); the tour
starts at row 22.
