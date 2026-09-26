# Day and night

**Question this answers:** How does the sun-and-moon timer work, what makes the
knight turn into a werewolf and back, and where does the 40-day limit come from?

**Short answer:** The sun or moon is an object record of its own at $C44D that
moves one pixel right every eight game frames; after 49 pixels it swaps (sun to
moon or back), which sets a "transform now" flag at $5BB1 and, at each dawn,
adds one to a BCD day count at $5BB9. The player's handler picks the flag up at
the first moment the player is not jumping or just entering a room, and spends
32 frames spinning through four random transformation sprites before swapping
knight for werewolf. Day 40 is game over.

## How it works

```
init_sun ($C46D)                     at game start: sun (type 88), X 176
renderer loc_D653 -> print_sun_moon ($C397)      every frame; acts every 8th
                  -> display_sun_moon_frame ($C3A4)
                       X == 225? -> toggle_day_night ($C3FF)
                                      type ^= 1, colour_sun_moon, X = 176
                                      $5BB1 = 1   (transform pending)
                                      became sun? -> inc_days ($C419)
                                                       $5BB9 += 1 (BCD)
                                                       == $40 -> game_over
                                                       print_days, blit_2x8
                                                       display_frame
                       else height from sun_moon_yoff ($C440)
                          -> display_frame ($C3C3)   clear, sun/moon, frame halves, blit

player legs handler ($C823/$C828) -> upd_player_bottom -> loc_C83E
   -> chk_and_init_transform ($C306)
        $5BB1 == 0, settling (+$0C top nibble) or jumping (+$0C bit 3)? return
        else: drop return address (rest of player frame skipped)
              $5BB1 = player's type; +$10 = 8; top record type 1 (erase)
              -> rand_legs_sprite ($C357): type 92..95, not the current one, mirror toggled
upd_92_to_95 ($C337)   the player's bottom record while changing
   touched by something deadly (+$0D bit 6) and game not complete -> death sparkles
   every 4th frame: sound, --(+$10); zero? -> finish_transform ($C377)
                                         else -> rand_legs_sprite
finish_transform ($C377)
   type = $5BB1 XOR $20 (knight legs 16-29 <-> werewolf legs 48-61)
   top = type + 16; $5BB1 = 0; drawing offset (werewolf one pixel lower)
```

The sun/moon record ($C44D, 32 bytes, laid out like an object record):

| Offset | Field |
|---|---|
| +$00 | type: 88 sun, 89 moon (bit 0 is day/night for everyone who asks) |
| +$1A | pixel X, 176 to 225 |
| +$1B | pixel Y, from the arc table at $C440 |

Timing: one day or one night is 49 steps of 8 game frames = 392 game frames.
The height arc is 13 entries (5,6,...,10,10,...,5), indexed by
((X + 16) / 4) mod 16, which runs 0 to 12 over X = 176 to 224.

The window is 48 by 31 pixels in the bottom right corner of the screen buffer
(from column 23 of the bottom row); display_frame clears it, draws the sun or
moon, then draws types 90 (at pixel X 184) and 186 (at 208) over it through the
scratch record at $BFDB, and copies the patch to the screen. Because the frame
is drawn last, the sun comes out from behind the left side and sets behind the
right.

Who reads bit 0 of the sun/moon type besides this code: colour_sun_moon ($D30D:
attribute $46 for the sun, $47 for the moon) and lose_life ($D12A), which
brings the player back as a werewolf if it is night. lose_life also clears
$5BB1, so dying cancels a pending or half-done transformation.

The days limit: $5BB9 starts at 0 (the RAM wipe), is incremented at each dawn
with DAA, and inc_days jumps to game_over when it reads $40 -- that is, at the
dawn that would begin day 40.

When the fourteenth object reaches the cauldron, prepare_final_animation ($C2CC)
sets $5BC3; display_sun_moon_frame then returns at once, so the sun stops and no
further transformation is ever requested. The same routine erases records 3 to
13 and turns every plain block (type 7) in the room into type 131, which rises.

## How this was found

Read the code in $C2CC-$C44C and $C46D, followed the callers into
end_of_frame / no_delay ($B000-$B074), loc_D653, lose_life ($D12A), game_over
($BA22) and print_days ($BC66). The type numbers are the jump table at $B096
read as decimal (upd_92_to_95 is types $5C-$5F, which is what
`AND 3; OR $5C` in rand_legs_sprite produces). Sun = 88 is inferred from three
things together: init_sun sets 88 at the start of a game, the day counter
advances when the type becomes 88 again, and 88 gets the yellow attribute.

## Confidence

Everything is read from the code except: "88 is the sun" (inferred as above);
"types 90 and 186 are the two halves of the window frame" (inferred from where
they are drawn); "392 game frames" is exact in frames, but what a game frame is
in 50Hz ticks varies (end_of_frame pads to about six), so no wall-clock figure
is given.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| final_clear_loop | loc_C2DC | $C2DC | erase records 3 to 13 for the ending |
| blocks_to_rising | loc_C2EE | $C2EE | turn type 7 blocks into type 131 |
| final_next_record | loc_C2F9 | $C2F9 | the loop step of that scan |
| transform_step | loc_C349 | $C349 | one step, every fourth frame, of the transformation |
| set_transform_sprite | loc_C369 | $C369 | store the random sprite and mirror it |
| finish_transform | loc_C377 | $C377 | knight to werewolf or back |
| transform_done_draw | loc_C394 | $C394 | redraw the finished player |

## Open questions

- Which objects records 3 to 13 are in the wizard's room when the ending wipes
  them (depends on the room data for room $88).
- The initial pixel Y of 9 set by init_sun is always overwritten before it is
  drawn, as far as the code shows; whether any path draws the sun before
  display_sun_moon_frame runs was not checked.
