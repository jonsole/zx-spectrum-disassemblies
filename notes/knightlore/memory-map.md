# Memory map

**Question this answers:** where everything is -- the program, its tables,
the variables, the object records and the buffers -- and what each variable
means.

**Short answer:** the game's variables sit at $5BA0-$5C07, over the top of
the ROM's system variables, and forty 32-byte object records follow from
$5C08 to $6107; the stack grows down from $5BA0. The disassembled program is
$6108-$D8F2, data first ($6108-$AF6B) and code after. Above it are the screen
buffer ($D8F3-$F0F2) and tables built at start-up ($F100-$FFFF).

Everything here is *read* from the code by the agents that described each
range (their notes are the topic files); the few things confirmed in a running
game say *watched*.

## Regions

| From | To | What |
|---|---|---|
| $4000 | $5AFF | the display; the game writes attributes directly for the panel, the days and lives, and the finale's colour cycling |
| $5B00 | $5B9F | stack. SP is reset to $5BA0 for every object; the wipe pass pushes 6 bytes per rectangle here (inferred) |
| $5BA0 | $5C07 | the game's variables (below) -- on top of the ROM's system variables, which the game never uses once running |
| $5C08 | $6107 | the object table: 40 records of 32 bytes (layout below) |
| $6108 | $AF6B | data: the status font, room sizes, the room table, block types, backgrounds, the special-object table, the sprite table and the 103 sprites -- see [`room-format.md`](room-format.md), [`sprites.md`](sprites.md) |
| $AF6C | $D8F2 | the code, with small tables among it (tunes, the handler table at $B096, text, the wanted list at $C27D, the depth-order table at $CF69 ...) |
| $D8F3 | $F0F2 | the screen buffer the room is composed in, bottom line first ([`drawing.md`](drawing.md)) |
| $F100 | $FFFF | tables built by `build_lookup_tbls`: bit reversal at $F100, then fourteen pages of shifted bytes from $F200 |

## The object records

Forty records of 32 bytes from $5C08, walked every frame by `onscreen_loop`.

| Record | Address | Holds |
|---|---|---|
| 0 | $5C08 | the player's legs -- the whole collision box *(watched: room at $5C10)* |
| 1 | $5C28 | the player's top half; height 0, copies the legs' position |
| 2, 3 | $5C48, $5C68 | the room's special objects (charms, the extra life); in the wizard's room $5C68 holds the cauldron bubbles |
| 4-39 | $5C88-$60E8 | the room's own objects, filled by the room builder: walls and arches first, then everything placed in the room |

| Offset | Field |
|---|---|
| +$00 | graphic number: the index into the sprite table and the handler table. 0 empty, 1 empty after this draw |
| +$01-$03 | x, y, z |
| +$04-$06 | half-size in x, in y, and height |
| +$07 | flags: b0 in a doorway (may leave the room), b1 skip collision this frame, b2 pushable (the player: carried by what it stands on), b3 uses arches, b4 draw this frame, b5 wipe the old image, b6 mirrored, b7 upside down |
| +$08 | room |
| +$09-$0B | dx, dy, dz (an arch's first pillar keeps its doorway's middle here instead) |
| +$0C | status: b0/b1/b2 blocked in x/y/z (b2: landed), b3 jumping, b4-7 frames left walking in after entering a room |
| +$0D | contact: b0 just dropped, b3 landed on, b5 deadly to touch, b6 touched by something deadly (what the player dies of), b7 deadly to what it moves into |
| +$0E, +$0F | the player's pending x and y nudge from an arch |
| +$10, +$11 | special objects: the address of their entry in the table at $6FF2. The player: the saved type during a transformation or while materialising |
| +$12, +$13 | pixel offsets added after projection |
| +$18, +$19 | the sprite's width in bytes and height in rows as drawn |
| +$1A, +$1B | pixel x, and pixel y counted up from the bottom |
| +$1C-$1F | last frame's +$18-$1B, for wiping |

## Variables

| Address | Meaning | Where it is set and read |
|---|---|---|
| $5BA0 | the seed: FRAMES at a cold start, plus the frame counter at each new game, plus one per pass of the menu. Bits 0-1 choose the start room and the rotation of the wanted list | START, main, `check_for_start_game`; `init_start_location`, `shuffle_objects_required`, `init_special_objects` |
| $5BA2-$5BA3 | frame counter, +1 per frame | `end_of_frame`; read all over for timing |
| $5BA4 | control options: bits 1-2 the method (0 keyboard, 1 Kempston, 2 cursor, 3 Interface II), bit 3 directional control | the menu; `check_user_input`, `handle_left_right` |
| $5BA5 | random byte, stirred with R after every object and with the frame counter each frame | `ret_from_tbl_jp`, `end_of_frame` |
| $5BA6 | the control options before this pass of the menu | `menu_loop`, `check_for_start_game` |
| $5BA0-$5BA7 | kept over a restart: `start_menu` clears from $5BA8 | |
| $5BA8 | wipe rectangles pushed this frame | `render_dynamic_objects`, `wipe_rect` |
| $5BA9-$5BAA | the real SP while `print_sprite` borrows it | `print_sprite` |
| $5BAB, $5BAC | the room's half-size in x and in y about its centre, 128 | `found_screen`; the bounds checks and exits |
| $5BAD | the room's attribute | `found_screen`; `no_delay` fills the screen with it |
| $5BAE | the floor's height, $80 in every room | `found_screen`; collision in z, the room builder, portcullises |
| $5BAF | a portcullis is moving (one at a time) | `upd_8`, `stop_portcullis` |
| $5BB0 | portcullis falls in this room | `upd_8`, `init_portcullis_down` |
| $5BB1 | transformation: 0 none, 1 pending, else the legs' type saved while changing | `toggle_day_night`, `chk_and_init_transform`, `lose_life` |
| $5BB2 | bit 0: a frame has been played, so leaving a room saves its special objects' places | main, `end_of_frame`, `build_screen_objects` |
| $5BB3 | pick-up/drop key latch | `handle_pickup_drop` |
| $5BB4 | the carried charms need redrawing | `display_objects_carried` |
| $5BB5 | the input byte: b0 left, b1 right, b2 forward, b3 jump, b4 pick up/drop, b5 any other key *(watched)* | `check_user_input`; see [`input.md`](input.md) |
| $5BB6 | colour of the text being printed | `display_text_list` |
| $5BB7 | a new room: copy the whole buffer out this frame | `build_screen_objects`, `no_delay` |
| $5BB8 | a text list is already on screen | `display_text_list` |
| $5BB9 | days, BCD; the game ends at $40 | `inc_days` |
| $5BBA | lives in reserve, binary (printed as BCD): 5 at the start | main, `lose_life`, `upd_103` |
| $5BBB | charms put in the cauldron in the right order, 0-14 | `add_obj_to_cauldron`, `ret_next_obj_required` |
| $5BBC | per-object phase: frame counter + object slot + 1 | `onscreen_loop`, `update_sprite_loop` |
| $5BBD | the height at which bouncing balls turn in this room | `upd_178_179` |
| $5BBE | drawing done this frame (objects drawn plus rectangles), which shortens the frame delay | the renderer; `end_of_frame` |
| $5BBF | a spiked ball is falling (one at a time) | `upd_63` |
| $5BC0 | bit 0 of the room number on entry: while set, spiked balls stay put. Cleared by a pick-up or the extra life | the room builder, `upd_63`, `pickup_object` |
| $5BC1 | the player's intended dz this frame, before collisions | `move_player_apply` |
| $5BC2 | the bouncing ball's dz before this frame's move | `upd_182_183` |
| $5BC3 | the quest is complete: the finale is running | `prepare_final_animation` |
| $5BC4 | a charm is rising into the cauldron: controls locked | `room_to_drop`, `cauldron_consume` |
| $5BC5 | the last finale spark's height: play its tone | `spark_tone_and_move`, `end_of_frame` |
| $5BC6 | rooms visited - 1 | `calc_and_display_percent` |
| $5BC7-$5BC8 | the font the printer uses | the print routines |
| $5BC9, $5BCA | the percentage: hundreds, then tens and units in BCD | `calc_and_display_percent` |
| $5BCB-$5BD0 | the depth sort's pointers into the render list | the sort, the wipe pass |
| $5BD1 | the menu tune has played | `play_audio_wait_key` |
| $5BD2 | key 5 held on the menu | `check_for_directional_control` |
| $5BD3 | something within 12 units above the player's head: no drop | `handle_pickup_drop`, `room_to_drop` |
| $5BD8-$5BE7 | the carried charms: a staging slot and three slots of type, flags and table pointer | `pickup_object`, `adjust_carried` |
| $5BE8-$5C07 | rooms visited, a bit per room number (byte room/8, bit room AND 7) | `flag_room_visited`, `calc_and_display_percent` |

Outside this area but written as variables: the wanted list at $C27D
(rotated in place, never reset), and the two saved player records at
$D161-$D1A0 (the respawn point, saved at every room exit).

## Open questions

- Whether the stack below $5BA0 can overrun into the display with many wipe
  rectangles (about 26 fit): see [`drawing.md`](drawing.md).
