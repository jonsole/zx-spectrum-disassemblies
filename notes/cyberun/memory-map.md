# Memory map

**Question this answers:** where everything is -- code, tables, graphics,
variables, buffers, the stack -- by address and label; what the start-up
overwrites; what is unused; and what each variable means.

**Short answer:** the game runs from $5B00 to $FFFF. Below the loaded
block are the stack (in the printer buffer, down from $5B80), the four
on-screen map cells' collision-box lists (over the loader's entry) and
some forty scratch variables in the system variables' area. The block
from $5C80 holds the world's level data first ($5C94-$70D7: objects,
pick-up places, the map, the tiles), then the title tune, the sound
effects and the sprite graphics ($731F-$8346), then the code with its
tables and variables interleaved to $F0FA, the landscape pieces' graphics
($E581-$F0FA) at its end. Above it: the menu and game-flow code, the two
player records, the ship's picture, the start-up code that becomes a
sprite buffer and a bit-reversal table, and six pages of shift tables
built over the loader's leftovers. Every byte is in a labelled, described
entry of the listing; a handful are unused.

Labels are the listing's (`game_disassembly/cyberun/cyberun.asm`, stage
2, 2026-10-16). Everything is *read* unless it says otherwise.

## Regions

| From | To | Label | What |
|---|---|---|---|
| $4000 | $5AFF | | the display; the play area is 28 bytes by 160 lines from x 8, line $18-$B7 |
| $5B00 | $5B79 | `stack_space` | the stack, down from $5B80; interrupts are off, so nothing else lands on it |
| $5B7A | $5B7F | `stack_top` | the stack's top six bytes: three return addresses when the landscape is drawn, where the renderer reloads SP ($5B7A) after each piece ([`main-loop.md`](main-loop.md)) |
| $5B80 | $5B98 | `loader_entry` | the loader's entry ([`loading.md`](loading.md)); after the start, the first 25 bytes of the view's page's collision-box list |
| $5B99 | $5BA4 | `ground_cell_top_left_rest` | the rest of that list |
| $5BA5 | $5BC9 | `ground_cell_bottom_left` | the collision boxes of the page below the view's |
| $5BCA | $5BEE | `ground_cell_top_right` | the page right of it |
| $5BEF | $5C13 | `ground_cell_bottom_right` | the page below and right; $5C14 unused |
| $5C15 | $5C40 | `saved_step_x` ... `fuel_saver` | scratch variables (below), in the system variables |
| $5C41 | $5C7F | `basic_leftovers` | unused: the system variables put through the loader's nibble shift |
| $5C80 | $5C83 | `game_entry` | DI; JP `start` |
| $5C84 | $5C93 | `double_bits` | a nibble's bits doubled, for double-size text; must stay inside page $5C |
| $5C94 | $5DB5 | `map_object_kinds` | 290 bytes, one per object lying in the world, in map-column order: bits 0-5 the kind, bit 7 gone for player 1, bit 6 for player 2 ([`players.md`](players.md)) |
| $5DB6 | $5E16 | `map_objects_per_column` | 96 counts, and column 0's again for the wrap |
| $5E17 | $605A | `map_object_places` | 290 positions of two packed bytes |
| $605B | $6112 | `place_pool_kind3`, `place_pool_kind1` $609B, `place_pool_kind5` $60DB, `place_pool_kind2` $60E3 (`place_pool_kind2_third` $60EB), `place_pool_kind4` $6103 | the 46 places pick-ups can be dealt to, in five groups, 4 bytes each |
| $6113 | $61A8 | `deal_places` | code: dealing a player their 19 places |
| $61A9 | $61BB | `dealing_list` (`dealing_list_last` $61BB) | the group each place is dealt from |
| $61BC | $6C3B | `landscape_map` | the world: 96 columns by 28 rows of tile numbers |
| $6C3C | $6D91 | `tile_table` | 171 words: tile number to tile record |
| $6D92 | $70D7 | `tile_records` | the tiles' pieces, records sharing bytes through their markers; one byte ($6D94) unused |
| $70D8 | $71D2 | `title_tune` | 250 notes and $FF ([`sound.md`](sound.md)) |
| $71D3 | $731E | `beep_pulse` ... `sound_collect` | the sound effects' code |
| $731F | $8346 | `rocket_bars_graphic` ... `ringed_planet_graphic` | the sprite graphics: width, height, rows bottom first; the ship's add-ons with a height byte before and $FF or a mask after |
| $8347 | $83CD | `landscape_end_pieces`, `last_piece_width`, `first_piece_shift` | code: the ends of landscape fill runs |
| $83CE | $855B | `print_strings`, `planet_secured`, `planet_names` $8459 ... `next_planet_lines_end` $8536 | code and text: the planet-secured screen ([`panel-and-menu.md`](panel-and-menu.md)) |
| $855C | $8614 | `spawn_point_masks`, `spawn_points` $8605 | which spawn points each kind of screen allows, and the eight points |
| $8615 | $878F | `menu_loop` ... `pointer_p2_graphic` | the menu's loop, keys and arrows |
| $8790 | $8C02 | `spawn_countdown` ... `start_in_screen` | spawning attackers and clouds, ground objects and attackers firing, the shot kinds' tables ($89A7, $89AF) |
| $8C03 | $8D41 | `speed_limit` ... `skip_free_record` | acceleration and the speed limit, steering back to the view, the ship's wreck |
| $8D42 | $9233 | `update_objects` ... `test_shot_list` | the sky objects' pass, contact with the ship and its effects, the death byte, the player's shots against objects |
| $9234 | $9306 | `score_object`, `add_score` $925E, `type_points` $929C, `find_missile_target`, `missile_target_values`, `set_facing` | scoring and homing |
| $9307 | $9523 | `update_missile` ... `place_draw`, `draw_object` | the sky objects' update routines |
| $9524 | $96D7 | `update_rocket_part`, `put_rocket_record`, `draw_rocket`, `launch_state` ... `rocket_part_table` $96B0 | the rocket |
| $96D8 | $9973 | `update_debris` ... `steer_tough_attacker` | debris, dropping a rocket part, steering, the frame lists, `wave_table` $990A |
| $9974 | $9A4B | `object_records` (`drop_records` $99D4, `cloud_records` $9A1C) | nine sky-object records of 24 bytes: 0-3 attackers, 4-6 what they drop, 7-8 clouds |
| $9A4C | $9A63 | `rocket_record` (`rocket_record_flags` $9A5C) | the record every rocket part is drawn with |
| $9A64 | $9A65 | `pass_counter` | a word, +1 a pass |
| $9A66 | $9BCA | `start` ... `note_table` $9B0C, `read_keyboard` $9BC3 | the start, screen clearing, `mask_world_objects`, the tune player and its notes |
| $9BCB | $9BCE | `random_a`, `random_b`, `random_pointer` | the random numbers |
| $9BCF | $9BD5 | `add_a_to_hl` | |
| $9BD6 | $9DB0 | `beam_state` ... `flicker_beam_patterns` | the flickering beams |
| $9DB1 | $9EE2 | `boxes_overlap` ... `test_slope_both_ways` | box overlap and slope tests |
| $9EE3 | $9F75 | `test_pause_keys` ... `pause_delay` | the pause, the dissolve and the play-area clear |
| $9F76 | $A0B0 | `font` | 45 characters of 7 bytes |
| $A0B1 | $A1D2 | `print_char` ... `line_up_hl` | text, screen addresses, the sky objects' dispatch |
| $A1D3 | $A801 | `old_sprite_x` ... `mirrored_draw_one` | the sprite compositor and the direct (ship) drawer, with their variables and patched loops |
| $A802 | $A80A | `delay` | |
| $A80B | $A8A6 | `ground_objects` (`pickup_record` $A873, `second_pickup_record` $A88D) | six ground-object records of 26 bytes; the last two bytes overlap the code of `load_ore` (never read for a pick-up) |
| $A8A5 | $AF24 | `load_ore` ... `colour_carried_parts` | ore, the ship against ground objects, pick-ups, the special beam's hits, the ground objects' pass, placing and colouring sprites |
| $AF25 | $AFE8 | `object_handlers` ... `addon_places` | the object tables: update routines by type, graphic lists, the add-ons' graphics and places |
| $AFE9 | $B114 | `build_ship_sprite`, `fit_addon`, `addon_mask_and_draw` | building the ship's picture |
| $B115 | $B335 | `read_controls` ... `clamp_climb` | the controls and the ship's movement, with its constants (`gravity` $B312 ... `climb_fraction` $B320) |
| $B336 | $B945 | `draw_beam` ... `empty_box_list` | the player's shots: lasers, missiles, the special beam; `shot_records` $B37A (four of 24 bytes) |
| $B946 | $BF84 | `find_page_boxes` ... `sprite_screen_pos` | moving through the world (`move_object` $BF66) and colliding with the landscape |
| $BF85 | $C1A8 | `mirror_ship_sprite` ... `star_frames` | mirrored drawing; the parallax stars |
| $C1A9 | $C373 | `ship_height` ... `save_restart_point` | the ship's picture pointers, the carried part, the restart point |
| $C374 | $C890 | `ship_pass` ... `clamp_object_speed` | the ship's pass, its drawing, trail and jets, its speed across |
| $C891 | $C8E4 | `bare_ship` | the ship's own picture, 14 rows of 6 bytes |
| $C8E5 | $C904 | `ship_record` and its fields | the ship's record (below) |
| $C905 | $C905 | `ore` | |
| $C906 | $C926 | `ship_record_start` | the ship record at a life's start, copied by `reset_for_life`; $C926 unused |
| $C927 | $C96E | `score_bitmap`, `edge_ornament`, `side_ornament`, `panel_leftovers` | the ship icon, the frame's ornaments, 18 unused bytes |
| $C96F | $C9D9 | `draw_bitmap`, `fill_attributes`, `unused_attribute_bitmap` | |
| $C9DA | $CA1C | `score_labels` ... `player_in_play` | the panel's text records |
| $CA1D | $CC4A | `frame_description` ... `fill_edge_rows` | the panel, the frame and the fuel gauge's drawing |
| $CC4B | $CCB9 | `fuel` ... `update_fuel_gauge` | the fuel and its gauge |
| $CCBA | $CE5A | `scroll_down` ... `piece_rows` | the landscape's variables and tables (`graphic_offsets` $CCBF, `mirror_table` $CE04, `upside_down_table` $CE14, `column_varieties` $CE24) |
| $CE5B | $DC86 | `column_clipped` ... `blit_mirrored_right_clip` | the landscape renderer, with `piece_classes` $D0AC and the lips $D851-$D85E |
| $DC87 | $DCA0 | `map_window_pointer` ... `planet_ground_colours` | the four map cells on screen; the planets' colours |
| $DCA1 | $DDF7 | `start_landscape`, `fly_in_step` ... `right_map_column` | a life's start |
| $DDF8 | $E248 | `scroll_landscape` ... `read_map_cell` | the scroll, the map window, bringing objects in from the map (`object_kind_flags` $E0FD, `object_part_pairs` $E10E, `object_kind_bytes` $E205) |
| $E249 | $E580 | `flat_blit_lose_first` ... `blit_mirror_one` | the POP blitters, the pieces' tables by shift ($E2BD-$E3BC), `piece_shapes` $E3BD |
| $E581 | $E749 | `flat_piece_gfx` ... `slope_3_gfx` | the stored landscape pieces |
| $E74A | $F0FA | `slope_2_shifted` ... `slope_10_shifted` | their shifted copies, made at the start (zeros on the tape but for part of the flat pieces') |
| $F0FB | $F10E | `spare_after_pieces` | 20 unused bytes (the first two read by one shifted slope) |
| $F10F | $F111 | `play_area_colour` | a colour patch: 28 by 20 cells and the level's attribute |
| $F112 | $F1BC | `menu_text` | the menu's twelve text records |
| $F1BD | $F201 | `colour_ship`, `ship_colour_patch` | |
| $F202 | $F23A | `menu_frame_corners`, `menu_frame_ticks`, `menu_frame` | |
| $F23B | $F26B | `random` | |
| $F26C | $F2E1 | `menu` | |
| $F2E2 | $F2E2 | `player_count` | |
| $F2E3 | $F30A | `copyright_glyphs` | |
| $F30B | $F5E6 | `clear_bytes` ... `player_digit` | the game's flow: new game, lives, levels, game over, swapping players, the tunes and messages |
| $F5E7 | $F64F | `score` ... `place_last` | the current player's record |
| $F650 | $F6B8 | `other_player_record` | the other player's |
| $F6B9 | $F7E4 | `ship_picture` | the ship's picture as built, 300 bytes |
| $F7E5 | $F7EA | `spare_after_ship` | 6 unused bytes |
| $F7EB | $F8FF | `build_shifted_pieces` ... `shift_flat_piece` | start-up code; afterwards $F800-$F8FF is the sprite compositor's buffer (`sprite_buffer_two` at $F880) |
| $F900 | $F9FF | `bit_reverse_table`, `bit_reverse_table_end` $F9AC | start-up code; afterwards the bit-reversal table |
| $FA00 | $FFFF | `shift_tables`, `loader_copy` $FC00, `loader_leftover` $FC0C, `loader_stack` $FDFE, `loader_leftover_charset` $FE00 | the loader's leftovers in the snapshot; afterwards the shift tables (2, 4 and 6 bits) |

## What the start overwrites

| Area | In the snapshot | After the start |
|---|---|---|
| $5B80-$5C13 | the loader's entry, zeros | the four collision-box lists |
| $E74A-$F0FA | zeros (part of the flat pieces' copies) | the shifted landscape pieces |
| $F800-$F8FF | start-up code | the sprite buffer |
| $F900-$F9FF | start-up code | the bit-reversal table |
| $FA00-$FFFF | the loader's leftovers | the shift tables |

## The variables

Merged from the eight range drafts' tables and checked against the
listing's labels; the meaning is the listing's where they differ. Fields
of records and tables are in the topic notes; the player record's fields
are in [`players.md`](players.md).

### The scratch area, $5C15-$5C40

Many of these are shared: one routine's counter is another's flag. Each is
named by its main use.

| Address | Label | Meaning |
|---|---|---|
| $5C15 | `saved_step_x` | a word: a moving record's step across (+7, +8) through `three_eighths`, kept and added back during a slope bounce |
| $5C17 | `saved_step_y` | the same for the step down (+9, +10) |
| $5C1A | `touch_depth` | how far into a slope a part went (`test_landscape_piece`); read negated as the step out (`leave_slope`) |
| $5C1C | `scratch_count` | the busiest scratch byte: 1 on a touch (`boxes_overlap`, the slope tests), the pick-up kind `load_map_window` gives ($0C, $1E), the old image's rows in `draw_direct_pair`, the shot kind while firing |
| $5C1D | `ground_cell` | the map cell `draw_landscape` is drawing, 0-3 (bit 0 the lower row, bit 1 the right column); the new image's rows in `draw_direct_pair`; scratch |
| $5C1E | `row_count` | a row count (the shift builders), a line (`start_attacker`, `object_box`) |
| $5C1F | `row_count_spare` | the copy `row_count` is reloaded from; scratch |
| $5C20 | `pieces_left` | pieces left to draw in the tile; scratch |
| $5C22 | `piece_steps` | steps in the piece, 1-16 |
| $5C24 | `piece_step_y` | the piece's step in y; a fill or colour width elsewhere |
| $5C25 | `piece_step_x` | the piece's step in x; the collision routines' mode: $FF the ship, $80 a shot (stop at the first hit), 0 an object (bounce); the generator's ceiling flag |
| $5C26 | `tile_upside_down` | $99 while the tile is turned upside down |
| $5C27 | `piece_kept` | a step kept for the column fill |
| $5C28 | `sprite_width` | a width less one in bytes; the old image's column in `draw_direct_pair` |
| $5C29 | `sprite_width_drawn` | the width a sprite was drawn with (in pixels after `draw_sprite_pair`) |
| $5C2A | `stick_out_right` | how far a collision box sticks out past its page's right |
| $5C2B | `stick_out_up` | how far it sticks out above |
| $5C2C | `piece_x` | the x of the piece's step; the compositor's box left |
| $5C2D | `piece_y` | the y of the step; the compositor's box bottom |
| $5C2E | `move_across_kept` | a word with $5C2F: the move across `place_collision_box` keeps |
| $5C2F | `piece_steps_done` | steps of the piece drawn |
| $5C30 | `tile_mirrored_left_right` | $FF while the tile is mirrored left-right |
| $5C31 | `edge_flags` | which edges of the view a step crossed; a placed object's +$10 |
| $5C32 | `piece_clip` | the piece's steps reverse at an edge |
| $5C33 | `piece_extra_a` | a flat piece's first end code |
| $5C34 | `piece_extra_b` | its second |
| $5C35 | `piece_ceiling` | $80 for directions 7 and up; in the collision code this pass's events (bit 7 a block hit, 6 bounced, 4 a slope) |
| $5C36 | `steer_push` | $80 pushed left, 3 right, 0 not |
| $5C37 | `controls_now` | this pass's controls ([`input.md`](input.md)) |
| $5C38 | `ship_line` | the ship's line on the screen, along which its shots fly |
| $5C39 | `gun_cooling` | 6 after a shot, counted down |
| $5C3A | `map_row_colour` | the upper cells' landscape attribute |
| $5C3B | `map_row_colour_next` | the lower cells' |
| $5C3C | `map_rebuild` | $FF in the fly-in, 3 its last pass, 0 in play; bit 7 draws tile $3E as $AA; while set no beams and no objects |
| $5C3D | `record_ground` | make the collision boxes this pass (a cell crossed, or a rebuild) |
| $5C3E | `top_speed` | the ship's top speed across: 2, 4 with add-on 4 |
| $5C3F | `top_climb` | the top climb: 2, 4 with add-on 5 or while launching |
| $5C40 | `fuel_saver` | a cloud touched what the ship carries this pass: the fuel burn halved, no push |

### Objects, spawning and contact

| Address | Label | Meaning |
|---|---|---|
| $8790 | `spawn_countdown` | 8 down to 0: a cloud may start at 7, an attacker at 0 |
| $8791 | `attacker_records` | always 4: the records attackers may use |
| $87F5 | `meteor_shower` | 0, or the passes left of a shower (128) |
| $896E | `extra_life_countdown` | throws left before the extra-life icon; restarts at lives x 4 |
| $896F | `shield_timer` | the shield: $FF when picked up, -1 every other pass |
| $89D2 | `attacker_kind` | the kind being started, 0-9 |
| $8C03 | `speed_limit` | n, the accelerating record's top speed |
| $8C04 | `speed_limit_down` | -(n+1); also the spawner's count of tries |
| $8CB1 | `last_pass_contact` | last pass's `fuel_saver` |
| $8D3C | `rocket_parts_load` | half the parts delivered, rounded up, while the rocket is drawn |
| $8E2B | `object_load` | the load: a record in use 1, drawn last pass +1, a big cloud +1, plus the parts' share. Spawn below 4; `spawn_tick` stops at 8, `find_free_record` at 7 |
| $8E2C | `contact_effect` | the current object's effect on touching the ship, a bit each; $FF the shield |
| $8F53 | `death_count` | the death byte ([`main-loop.md`](main-loop.md)) |
| $8FC3 | `hit_count` | hits on this ship, 0-3; $FF before a repair |
| $9932 | `wave_counter` | the `wave_table` entry spawned next |
| $9A64 | `pass_counter` | a word, +1 a pass (and a menu pass) |
| $9BCB | `random_a` | a random byte, stirred once a pass by `random` |
| $9BCC | `random_b` | a second |
| $9BCD | `random_pointer` | a big-endian pointer walking the ROM and the code, for `random` |
| $9BD6 | `beam_state` | the beams' pattern, colour, timer, and whether one was drawn |
| $9D2F | `beam_grace` | passes before a beam can hurt again (16 after a hit) |

### The rocket

| Address | Label | Meaning |
|---|---|---|
| $96AB | `launch_state` | 0 in play; set when the ship docks with the finished rocket; $FF once it has left the screen, ending the level |
| $96AC | `rocket_x` | the rocket's base: pixel, column ($68 in column $52) |
| $96AE | `rocket_y` | line, row |

### Sprites and drawing

| Address | Label | Meaning |
|---|---|---|
| $A1D3 | `old_sprite_x` | the old image's screen x |
| $A1D4 | `old_sprite_y` | its bottom line, clipped |
| $A1D5 | `new_sprite_x` | the new image's x |
| $A1D6 | `new_sprite_y` | its bottom line |
| $A1D7 | `old_sprite_rows` | the old image's height, 0 none |
| $A1D8 | `new_sprite_rows` | the new image's |
| $A289 | `direct_old_line` | the direct drawer's old bottom line, then rows left |
| $A28A | `direct_new_line` | the same for the new image |
| $A2F8 | `old_sprite_width` | the old image's width in bytes |
| $A2F9 | `new_sprite_width` | the new image's |
| $A2FA | `sprite_left_clip` | the pair straddles the play area's left edge |
| $A302 | `dissolve_step` | 0, or bit 7 and a step 1-7 while an object dissolves |
| $ABA4 | `collision_box` | a box: x, bottom line |
| $ABA6 | `collision_box_size` | its width, height |
| $AD46 | `current_object` | the record being drawn |
| $AF01 | `colour_patch` | a colour patch: width and height in cells, attribute |
| $BA09 | `collision_object` | the record tested against the landscape; in the renderer, the box pointer |
| $BA8D | `saved_speed` | a word kept for a moment (a speed, a screen address) |
| $BF83 | `sprite_screen_pos` | a sprite's screen x and line |
| $CE35 | `piece_dx` | a piece's step in x; also the compositor's box width in bytes |
| $CE36 | `piece_dcolumn` | its step in screen bytes |
| $CE37 | `piece_rise` | its rise in rows; also the compositor's box rows + 1 |

### The ship

| Address | Label | Meaning |
|---|---|---|
| $B320 | `climb_fraction` | the fraction of the ship's vertical position |
| $B625 | `shot_colour_patch` | a laser's strip of colour |
| $B730 | `shot_alternator` | bit 0 flips each shot (every other a missile with add-on 8); bit 2 the special beam, for one call |
| $B832 | `special_beam_on` | $80 while the special beam is out |
| $BC12 | `ship_on_slope` | $80 after the ship touches a slope |
| $BE8D | `last_speed_across` | a speed's whole part, for the block tests |
| $BE8E | `last_speed_up` | the same up and down |
| $BF7F | `moved_x` | x and page after a move |
| $BF81 | `moved_y` | line and page row after a move |
| $C1A9 | `ship_height` | the ship's picture's height in rows |
| $C1AA | `ship_graphic` | where in `ship_picture` drawing starts: set by `build_ship_sprite` from the height, and moved five rows (30 bytes) earlier by `toggle_carried_part` while a rocket part hangs (bit 6 of `part_being_fitted`, not the facing) |
| $C279 | `carried_part_facing` | the carried part's facing when drawn; bit 6 dropped |
| $C27A | `carried_part_redraw` | force the carried part to be redrawn |
| $C27B | `carried_big_x` | the carried part's bigger piece: x ($C27C its y) |
| $C27D | `carried_small_x` | the smaller piece: x ($C27E its y) |
| $C6C2 | `side_jet_record` | the side jet: graphic, screen address, flags, x, y, flicker count |
| $C6D0 | `lift_jet_skip` | erase the lift jet without redrawing, for a pass ($C6D1 unused) |
| $C78F | `lift_jet_record` | the lift jet, laid out the same |
| $C7BC | `trail_frame` | the trail's frame ($C7BD `trail_x`, $C7BE `trail_y`, $C7BF `trail_direction`) |
| $C7C0 | `ship_turned` | bit 7: the ship turned this pass |
| $C7C1 | `trail_hold` | a countdown holding the trail straight after a bit-3 box |
| $C7FA | `ship_position_across` | a running position word; its change is the step across |
| $C8E5 | `ship_record` | the ship's record, the shape of an object record; it holds the view's place in the world |
| $C8E6 | `view_page_column` | +1, the map column |
| $C8E7 | `view_page_x` | +2, x in the page (+3 the fraction) |
| $C8E9 | `view_page_row` | +4, the map row |
| $C8EA | `view_page_y` | +5, y in the page |
| $C8EC | `ship_dx` | +7, the step across (minus the scroll; a speed during the collision tests) |
| $C8EE | `ship_dy` | +9, the step down |
| $C8F0 | `ship_record_middle` | +$0B to +$17 |
| $C8FD | `ship_facing` | +$18, bit 7 left |
| $C8FE | `ship_across_speed` | +$19, the speed across, 8.8, high byte first |
| $C900 | `ship_down_speed` | +$1B, the speed down |
| $C902 | `ship_screen_x` | +$1D, the ship's x on the screen ($60) |
| $C903 | `ship_screen_y` | +$1E, its bottom line |
| $C904 | `part_being_fitted` | +$1F: an add-on's number, or a rocket part with bits 6 and 7 (bit 6 it hangs) |
| $C905 | `ore` | ore aboard, 0-18 |
| $D0BC | `trail_collision` | redraw the trail (set by the collision code) |

### The landscape

| Address | Label | Meaning |
|---|---|---|
| $CCBA | `scroll_down` | this pass's vertical scroll, signed pixels |
| $CCBB | `scroll_across` | the horizontal scroll |
| $CCBC | `star_drawn` | bit 0: the star has something to erase or draw |
| $CCBD | `shift_table` | this pass's table of blitters and graphics, by the fine scroll |
| $CE38 | `landscape_spare` | two bytes nothing refers to |
| $CE3A | `box_x` | an object's collision box: x ($CE3B `box_bottom`, $CE3C `box_height`, $CE3D `box_width`); as a word, a list pointer |
| $CE3E | `attribute_rows` | attribute rows per step |
| $CE3F | `vertical_step_size` | 2 or 4 |
| $CE40 | `half_rows` | a step's height in row pairs |
| $CE41 | `origin_x` | the screen x of the page's origin; AND 7 is the fine scroll; with `view_x` always 8 |
| $CE42 | `origin_y` | the same in y; with `view_y` always $B7 |
| $CE43 | `piece_page_x` | the current step's x in its page |
| $CE44 | `piece_page_y` | its y; the line a fill has reached |
| $CE45 | `view_x` | the page x at the play area's left edge |
| $CE46 | `view_y` | the page y at the play area's bottom edge |
| $CE47 | `piece_graphic` | the piece's graphic at this shift |
| $CE49 | `column_address` | the screen address for the next step |
| $CE4B | `offsets_start` | `graphic_offsets` or one on, unshifted or shifted |
| $CE4D | `next_piece` | the next piece in the tile record |
| $CE4F | `first_step_address` | the first step's screen address |
| $CE51 | `piece_offsets` | this direction's row of variant offsets |
| $CE53 | `first_step_y` | |
| $CE54 | `clipped_columns` | steps visited, edge cases included |
| $CE55 | `first_step_x` | where the vertical fill starts ($CE56 `first_step_y_drawn`) |
| $CE57 | `view_column` | the map column of the view's page |
| $CE58 | `view_row` | its map row |
| $CE59 | `piece_dx_copy` | the step in x again, 0 for a wall |
| $CE5A | `piece_rows` | rows per step |
| $D85D | `last_step_in_border` | a flat piece's last step hangs into the border |
| $DC87 | `map_window_pointer` | a pointer into `map_window_tiles` ($DC89, the four cells' tile records) |
| $DC91 | `map_window_tile_bytes` | the four cells' tile numbers ($DC92 below, $DC93 right, $DC94 below-right) |
| $DC95 | `ground_attr_above` | the planet's landscape attribute above ground |
| $DC96 | `ground_attr_below` | below ground, map rows 12 on |
| $DDF2 | `start_filled` | 1 if the play area was filled with the checker at the life's start |
| $DDF3 | `unused_landscape_bytes` | two bytes nothing reads or writes |
| $DDF5 | `left_column_objects` | objects in the view's map column |
| $DDF6 | `right_column_objects` | in the next |
| $DDF7 | `right_map_column` | the next map column, wrapped |
| $DEDC | `current_piece` | five bytes: the latest step's screen x, y, steps drawn, direction |
| $E41B | `direction_flag` | $FF a piece climbing right, 1 left; also a flag of `place_collision_box` |

### Stars, panel, fuel, players

| Address | Label | Meaning |
|---|---|---|
| $C0E6 | `star_layer_pointer` | the stars' layer pointer |
| $C0E8 | `star_pointer` | the star pointer |
| $C184 | `star_offsets` | three layers' offsets ($C18A `star_offsets_before`, last pass's) |
| $C9F0 | `p1_score_digits` | the current player's score as six digit codes |
| $C9FB | `p1_lives_digit` | the current player's lives less one, as a digit code |
| $CA00 | `p2_score_digits` | the waiting player's score |
| $CA0B | `p2_lives_digit` | the waiting player's lives |
| $CA16 | `hiscore_digits` | the high score's six digit codes |
| $CA1C | `player_in_play` | 0 or 1; $99 while `new_game` reorders the score lines |
| $CBAD | `gauge_colour` | the gauge's attribute: yellow, or red when low |
| $CC4B | `fuel` | a word, the high byte the level: $42 full, $BE empty |
| $CC62 | `fuel_shown` | the line the gauge's column reaches |
| $F2E2 | `player_count` | 0 one player, 1 two |
| $F5E6 | `player_digit` | the digit in the PLAYER message |
| $F5E7-$F6B8 | `score` ... `other_player_record` | the two player records ([`players.md`](players.md)) |

### Bytes inside other entries

Variables and self-modified operands that have no label of their own:

| Address | Inside | Meaning |
|---|---|---|
| $868F | `player_line_colour` | the one/two-player line patch's attribute |
| $8384 | `landscape_end_pieces` | an `LD A,n` operand: a fill run's width base less one, written by `fill_behind_moving_piece` |
| $8A8B | `start_in_screen` | the bit of a `BIT n,A`, written with the random first spawn point |
| $8FC1 | `icon_patch_record` | the ship icon's colour |
| $9C9F | `draw_beams` | a `BIT n,(HL)` opcode byte written from `map_square_bit` |
| $A0CA | `print_char` | the JR's displacement: 0 normal size, $10 double |
| $A3CB, $A415, $A520, $A553 | the compositor's copies | `DJNZ` displacements: the copy widths |
| $A3DC, $A4C5, $A531, $A6D6, $A728, $A751, $A799 | the compositor's row loops | `LD A,n` operands: the row steps |
| $A9B8, $ABDE, $E118 | `ship_hits_ground_objects`, `beam_hits_ground_object`, `spawn_objects_from_list` | the gone bit's SETs and BIT, by player ([`players.md`](players.md)) |
| $AC06 | `beam_hits_ground_object` | the SET's bit, from `map_square_bit` |
| $D463, $D480, $D4B7, $D702, $DB92, $DBC1, $DBC6, $DC0C, $DC14, $DC5A | the landscape step loop and clipping blitters | `JR` displacements: which blitter or clip |
| $E25A, $E25E, $E262, $E2A5, $E2AA | `blit_flat_step` | `JR` displacements: the flat pieces' clipping |
| $F111 | `play_area_colour` | the play area's attribute for the level |
| $F200, $F201 | `ship_colour_patch` | the ship's colour patch depth and attribute (the last colour used) |

## What is unused

Nothing refers to these (searched in the listing):

| Address | What |
|---|---|
| $5C14, $5C19, $5C1B, $5C21, $5C23 | single bytes after scratch variables |
| $5C41-$5C7F | `basic_leftovers` |
| $6D94 | one byte inside the tile records (a $99) |
| $7204 | `sound_unused`, a six-byte crackle nothing calls |
| $8FBB-$8FBE | `ship_icon_positions`: the icons' positions as words; the code loads constants |
| $8FC2 | the fourth byte of `icon_patch_record`, a $C9 |
| $A2C0 | `add_record_size`: two small routines nothing calls |
| $C6D1 | the byte after `lift_jet_skip` |
| $C926 | the byte after `ship_record_start` |
| $C95D | `panel_leftovers`, 18 bytes like the remains of text records |
| $C9B3 | `unused_attribute_bitmap`, a routine nothing calls |
| $CE38-$CE39 | `landscape_spare` |
| $DDF3-$DDF4 | `unused_landscape_bytes` |
| $F0FB-$F10E | `spare_after_pieces` (the first two bytes are read by one shifted slope's edge) |
| $F5F8, $F661 | +17 of each player record |
| $F7E5-$F7EA | `spare_after_ship` |
| $F8C2 | `unused_inc_hl`, start-up code nothing reaches |

## How this was found

The regions are the listing's entries, from the label list of
`cyberun.skool` (924 labels) and the eight range descriptions of stage 2
(2026-10-16); the variables are the eight drafts' "Variables used" tables,
merged and checked label by label against `cyberun.asm`. The order of the
level data was confirmed by the range-1 draft's arithmetic ($61BC + 28 x
96 = $6C3C; $5C94 + 290 = $5DB6; $5E17 + 580 = $605B) and its parse of the
tile records.

## Confidence

*Read*. "Nothing refers to it" means the listing's search of the code;
the drafts that searched also looked for the addresses as little-endian
words.

## Corrections

- Stage 0's `landscape.md` called $5B80, $5BA5, $5BCA and $5BEF "per-strip
  work areas". They are the collision-box lists of the four map cells on
  the screen: the view's page, below, right, below-right.
- Range 1's first pass read $5C94 as a bit table; it is 290 bytes, one per
  object.
- The range-4 draft put `view_y` ($CE46) at the play area's top edge; it
  is the page y at the bottom edge ($B7 less `origin_y`), as
  `scroll_landscape` keeps it.
- The range-5 draft read $C7C1 as a "scrape count" set on a bit-3 box. It
  is `trail_hold`: set to 4 on such a box, it holds the trail straight
  while it counts down.
- The drafts' proposed labels differ in places from the listing's
  (`tile_mirrored` and `tile_flipped` are `tile_upside_down` and
  `tile_mirrored_left_right`, `cell_records` are the `ground_cell_*`
  lists, `view_page` is `view_column`/`view_row`, `ship_sprite_buffer` is
  `ship_picture`); the tables above use the listing's.

## Open questions

- Whether the 128-byte stack is ever close to full.
- What wrote `panel_leftovers` and `ship_icon_positions`: an earlier
  panel, by the look of them.
