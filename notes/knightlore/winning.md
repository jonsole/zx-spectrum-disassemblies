# Winning: the charms, the cauldron, and the end-of-game rating

**Question this answers:** What does the wizard want, how does a charm get into
the cauldron, what ends the game, and how are the percentage and the rating on
the summary screen worked out?

**Short answer:** The wizard wants fourteen charms in a fixed order -- seven
kinds, each twice -- taken from a list that is rotated at the start of each
game. A charm dropped while standing high up in the wizard's room ($88) flies
to the centre and falls into the cauldron; the right kind is counted, the wrong
kind is destroyed. The fourteenth starts the ending. The summary's percentage is
(rooms visited + 2 x charms) x 100 / 156, and the rating is one of eight words
chosen by completion and by rooms visited, in steps of 32.

## How it works

Call chain for a charm going in:

    handle_pickup_drop ($C00E)          player presses pick-up/drop
      -> room_to_drop ($C0B2)           room $88 and player z >= $98:
                                        type |= 8 ($60-$66 -> $68-$6E), $5BC4 = 1
    upd_104_to_110 ($C1F1)              each frame: step 1 unit in x and y towards
                                        ($80,$80), rise to z = $98
      -> centre_of_room ($C238)         over the centre: fall, collisions off
      -> add_obj_to_cauldron ($C245)    at z <= $80:
           ret_next_obj_required ($C274) -> objects_required[$5BBB]
           match (type AND 7): $5BBB += 1, cycle_colours_with_sound ($C2A5)
           $5BBB = 14: prepare_final_animation ($C2CC), sets $5BC3 = 1
         -> cauldron_consume ($C265)    $5BC4 = 0, table entry cleared, vanish

- **The list.** `objects_required` ($C27D) is fourteen bytes, the kinds 0 to 6
  (a charm's type AND 7), each twice. `shuffle_objects_required` ($B544)
  rotates it left by (seed AND 3) + 4 places, seed at $5BA0. The rotation is
  done in place and never undone, so the first game after loading can ask for
  only four orders; each later game rotates on from where the previous one
  left it. The set asked for never changes, only the order.
- **Showing what is wanted.** The cauldron's bubbles (`upd_160_to_163`,
  $B8DA) also call `ret_next_obj_required` and turn into type $A8 + kind,
  which is how the next charm wanted is shown above the cauldron.
- **Getting it in.** The drop has to happen in room $88 with the player's z at
  $98 or more, while standing on something and not jumping (the general drop
  conditions). $5BC4 then locks out the controls (`check_user_input` at $D022
  treats it like the game being over) and `move_player` holds the player's
  vertical speed while it is set. The charm rises to $98, homes on the room
  centre one unit per frame on each axis, and when exactly over ($80,$80)
  falls with collisions switched off (bit 1 of +$07) until z <= $80.
- **Right or wrong.** Only a match with the kind wanted next counts. Either
  way the charm is used up: its entry in the special-object table at $6FF2 has
  its type byte zeroed and the record becomes type 1. A wrong charm is lost,
  not returned.
- **The ending.** At fourteen, `prepare_final_animation` ($C2CC) sets $5BC3,
  clears eleven object records from $5C68, and turns every remaining record of
  type 7 into type $83. That type's handler (`upd_131_to_133`, $B566) climbs
  to z $A4 and then homes on the player; within 6 units in x and y it jumps to
  `game_over` ($BA22).
- **Other ways to end.** `inc_days` ($C419) calls `game_over` when the BCD day
  count at $5BB9 reaches $40 (the fortieth day); `lose_life` ($D12A) does when
  the life count at $5BBA goes negative.
- **The screens.** `game_over` checks $5BC3: if set, `game_complete_msg`
  ($BAAB) shows the six-line completion message and plays its tune through,
  then waits (up to about 14 seconds, or a key). Both paths then show the
  summary (`game_over_summary`, $BA29), wait for keys to be released, play the
  game-over tune until a key, wait again, and restart at $AF7F.
- **The percentage** (`calc_and_display_percent`, $BC10). Rooms visited = the
  number of set bits in the 32-byte map at $5BE8 (one bit per room number,
  set by `flag_room_visited` at $D219). Points = rooms + 2 x charms ($5BBB).
  Result = points x 100 / 156, where 156 = 128 rooms + 14 charms x 2. It is a
  fixed-point multiply: HL accumulates $A41A (= 100/156 of 65536) per point
  and every carry out of HL adds one, in BCD, to A. A final $0028 is added
  because 156 x $A41A falls exactly 40 short of 100 x 65536; without it a
  perfect game would show 99. That final add is also the only step that can
  carry into the hundreds ($5BC9). Printed right-aligned: three digits if the
  hundreds is non-zero, otherwise two, one column further right.
- **The rating** (`game_over_summary`). $5BC6 = rooms visited - 1.
  Index = 4 x (quest complete) + ((rooms - 1) >> 5) AND 3, into `rating_tbl`
  ($BBB7):

  | Rooms visited | Not completed | Completed |
  |---|---|---|
  | 1-32 | poor | excellent |
  | 33-64 | average | marvellous |
  | 65-96 | fair | hero |
  | 97-128 | good | adventurer |

  Two oddities: "average" sits below "fair", and the top word for a completed
  game needs most of the castle explored. Visiting more than 128 rooms would
  wrap bit 7 away, but the 156 in the percentage says the castle has 128.
- **The charms count on the summary** is converted from binary to BCD in
  place ($BA6E): 10 to 14 become $10 to $14. It overwrites $5BBB, which is
  harmless since the restart clears it.

Colour cycling (`cycle_colours_with_sound`, $C2A5): sixteen passes, each adding
one to the ink of all 768 attribute cells (paper, BRIGHT and FLASH kept), a
noise burst whose length comes from the charm's type, and a pause of $2000
loop iterations.

## How this was found

Read from the listing: the routines from $BA22 to $C2CB in full, plus the
callers and callees needed to pin the variables -- `init_cauldron_bubbles`
($B8A9), `upd_160_to_163`, `shuffle_objects_required`, `prepare_final_animation`,
`upd_131_to_133`, `inc_days`, `lose_life`, `check_user_input`, `flag_room_visited`
(its self-modifying SET n,(HL)) and the handler table at $B096 (to map type
numbers to handlers). The percentage constant was checked by arithmetic:
156 x 42010 = 6553560 and 100 x 65536 = 6553600, a difference of exactly $28.
The rating index was worked through bit by bit from the RLCA/AND sequence.

## Confidence

All read from the code, except:
- that z $98 in room $88 means standing on the cauldron -- inferred from the
  height the charm rises to and falls from; the cauldron's size was not checked.
- that the castle has 128 rooms -- inferred from the 156 divisor, not counted.
- what the type-7 objects turned into $83 at the end look like -- not worked out.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| game_over_summary | loc_BA29 | $BA29 | Draws the game-over summary and works out the rating |
| print_charms_and_show | loc_BA79 | $BA79 | Prints the charms count, border, shows the buffer |
| await_restart | loc_BA87 | $BA87 | Waits for release, plays the game-over tune, restarts |
| wait_key_poll | loc_BA9E | $BA9E | Inner poll of wait_for_key_press |
| complete_text | the_potion_casts | $BAE4 | Completion message strings (old name quoted the text) |
| gameover_text | a_GAME_OVER | $BB5E | Summary strings (lower case, like menu_text) |
| rating_poor ... rating_adventurer | a_POOR ... a_ADVENTURER | $BBC7-$BC05 | The eight rating strings |
| count_visited_bit | loc_BC1B | $BC1B | Tests one bit of the visited-room map |
| next_visited_bit | loc_BC1F | $BC1F | Bit/byte loop, then sets up the percentage |
| scale_to_percent | loc_BC38 | $BC38 | Fixed-point multiply by 100/156 |
| print_percent_two_digits | loc_BC61 | $BC61 | Right-aligns a percentage under 100 |
| rise_over_cauldron | loc_C222 | $C222 | Sets dZ to rise to $98 |
| store_rise_speed | loc_C22C | $C22C | Stores dZ |
| move_charm_to_cauldron | loc_C22F | $C22F | Moves the charm |
| click_wipe_and_draw | audio_B467_wipe_and_draw | $C232 | Position-pitched click, then wipe and redraw |
| steer_to_centre_y | loc_C202 | $C202 | Stores dX, works out dY |
| check_over_centre | loc_C213 | $C213 | Stores dY, tests for ($80,$80) |
| cauldron_consume | loc_C265 | $C265 | Uses up a charm, right or wrong |
| settle_charm | loc_C29B | $C29B | Stops a charm lying in a room and redraws it |
| cycle_colours_pass | loc_C2A7 | $C2A7 | One pass over the attributes |
| cycle_colours_pause | loc_C2C3 | $C2C3 | Delay between passes |
| extra_life_fall | loc_C1EE | $C1EE | The extra life falls and settles |

## Open questions

- What are the type-7 objects that `prepare_final_animation` turns into type
  $83, and what does the ending look like on screen?
- The existing annotation for the special-object table at $6FF2 says
  `#R$B2CF` picks a set from it; $B2CF is `play_audio`. The shuffling of the
  wanted order is `shuffle_objects_required` at $B544; what picks where the
  charms start was not looked at here (outside this range).
