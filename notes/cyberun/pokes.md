# Pokes

**Question this answers:** pokes that change the game, each tested.

| Poke | Address | Effect |
|---|---|---|
| `POKE 36726,201` | $8F76 `RET` | No damage: the hit handler returns at once |
| `POKE 45385,201` | $B149 `RET` | No fuel used: the burn returns before adding to the gauge; refuelling still works |
| `POKE 62671,183` | $F4CF `OR A` | Infinite lives: the `DEC A` after the death sequence becomes a test of the lives, which are stored back unchanged (stage 0 tested `POKE 62671,0`, which is wrong: see Corrections) |

## How they were tested

Live, in a private `zx_server`, from one snapshot of the ship on its pad,
flying a fixed six-step cycle of keys (right and thrust, right and fire,
left and fire, left and thrust, right, left) in half-second slices at
uncapped speed, reading `$8F53`, `$8FC3`, `$F5ED` and `$CC4C` after each.

| Run | Length | Result |
|---|---|---|
| no pokes | about 4,900 frames | four deaths, each after the third hit |
| `$8F76` only | about 13,700 frames | no hits counted; one death, with the gauge empty, caught by a watchpoint at $CC73 |
| both | about 37,700 frames | no deaths, hits never counted, the gauge stayed at $42 |
| `$F4CF` only | about 3,600 frames | four deaths, each on the third hit; the lives stayed at 4 throughout |

These runs read the four bytes and nothing else: the `$F4CF` run watched only
the lives byte, not the screen, which is how the game-over screens it caused
went unseen (see Corrections).

## What the listing adds

The stage 2 listing (2026-10-16) names the routine each poke changes:

| Poke | Label | What it does to the routine |
|---|---|---|
| `POKE 36726,201` | `damage_ship` ($8F76), the second half of `contact_damage` ($8F54) | Every hit -- from an attacker, a bullet, a rock or a flickering beam (`beam_hits_ship` $9D0E) -- returns before the hit count `hit_count` ($8FC3) is touched. Side effect: a refuel pad's repair goes through the same routine, so it now leaves `hit_count` at $FF; harmless, since nothing else counts it up. |
| `POKE 45385,201` | inside `read_controls` ($B115), the fuel burn from $B149 | The burn returns before loading its 8 or 16. Pick-ups and pads still change `fuel` ($CC4B) through `add_fuel` ($CC4D). |
| `POKE 62671,183` | `lose_life` ($F4C6), the `DEC A` at $F4CF | `lives` ($F5ED) is stored back unchanged, and the `JR Z` after it tests the flags `OR A` set from them, so it never goes to `game_over` while a life is left. |

### Further pokes the listing suggests

*Read* from the listing, each one byte but the last; since tried in
SkoolKit's simulator for the reference pages, whose pokes page has the trials.

| Poke | Address | Effect |
|---|---|---|
| `POKE 35283,201` | `start_attacker` ($89D3) `RET` | No attackers and no meteor showers: `spawn_attacker` jumps here with a free record and it is left free. Clouds still come (`spawn_cloud` goes straight to `start_at_edge`), and the ground objects still fire. |
| `POKE 40206,201` | `beam_hits_ship` ($9D0E) `RET` | The flickering beams no longer hurt the ship. |
| `POKE 50053,0` | `ship_pass` ($C374), the `DEC A` at $C385 | Once picked up, the shield (`shield_timer` $896F) never runs down. |
| `POKE 46918,0` | `fire` ($B731), the operand of `LD A,$06` at $B745 | No gun cooling: a shot every pass while fire is held and a shot record is free (four at most in flight). |
| `POKE 43746,0` | `collect_pickup` ($AAD7), the `RET Z` at $AAE2 | Rocket parts can be picked up without the hook (add-on 1). The ship then vanishes and only the part is drawn: `toggle_carried_part` starts the picture at $F6B9 with five rows more, which covers the hook's rows and the part but not the bare ship's, higher up; after the delivery the picture stays blank until it is next built (*run* for the reference pages; *read* from `toggle_carried_part`). |
| `POKE 47171,0` | `special_beam_key` ($B833), the `RET Z` at $B843 | The special beam without add-on 7 (the number row on the keyboard, with the ship still). |
| `POKE 38720,24` | `drop_part` ($9724), the `JR NZ` at $9740 made a `JR` | Part 6, the ore tank, is delivered without its 18 ore. It still falls as frame 8, the full tank (`drop_part` sets that for part 6 whatever the ore), and the ore aboard is emptied and lost; in the reference trial, with 12 units aboard, 7 ore rows stayed in the picture under the hook (*run*). |
| `POKE 62415,n` | `new_game` ($F3BD), the operand of `LD A,$05` at $F3CE | n lives at a new game, for n from 1 to 9 (the panel prints one digit, lives less one). |
| `POKE 34504,0: POKE 34505,0: POKE 39875,0: POKE 39876,0: POKE 40677,0: POKE 40678,0: POKE 45535,0: POKE 45536,0: POKE 45563,0: POKE 45564,0` | the `OUT ($FD),A` at $86C8, $9BC3 (`read_keyboard`), $9EE5 (`test_pause_keys`), $B1DF and $B1FB, two NOPs each | The game runs on a 128K in 128 mode: these are the five keyboard reads that can write a value with bit 7 clear to the paging port; the IN after each selects its half-rows by itself. With them gone the menu, a new game and a round of play ran in SkoolKit's 128K memory with no paging write, and on a 48K the game played as before (*run* for the reference pages). |

With the no-damage and no-fuel pokes above (which already make the beams
harmless, since they hurt through `damage_ship`), the `start_attacker` poke
should give a quiet run for exploring the map or staging the rocket; worth
testing the same way as the table above before relying on it.

## Corrections

- **Infinite lives.** Stage 0 gave `POKE 62671,0` (a NOP for the `DEC A`) and
  the listing's reading said the `JR Z` after it never went to `game_over` in
  the test runs. It does at every death: the `LD` instructions around it leave
  the flags alone, so the `JR Z` picks up the zero flag of `clear_play_area`'s
  last `DEC C` ($9F40), which the death sequence has just run. Each death shows
  GAME OVER, plays its tune and checks the high score, and play then goes on
  with the lives kept (*read*, and *run* for the reference pages). The stage-0
  test watched only the lives byte, not the screen. `POKE 62671,183` (`OR A`)
  is the working poke.
- **`POKE 38720,24`** was said to deliver the tank as frame 6, the ore count
  left as it was; `drop_part` gives part 6 frame 8 and empties the ore whatever
  was aboard.
- **`POKE 43746,0`**: the open question of how the ship looks with a part and
  no hook is answered above.
