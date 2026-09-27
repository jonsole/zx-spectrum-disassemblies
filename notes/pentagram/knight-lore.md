# Pentagram and Knight Lore: the shared engine

**Question this answers:** how much of Pentagram is Knight Lore's engine,
what is changed in it, and what is Pentagram's own.

**Short answer:** the renderer, the depth sort, the collision code, the
player's movement, the arch checks, the pick-up queue, the text and border
printing and the tune player are Knight Lore's, often instruction for
instruction, with Knight Lore's leftovers still in them. Pentagram grew the
object table from 40 records to 54 (without growing every buffer), replaced
the grid of rooms with a doorway table, and added its own firing, scoring,
things from the sky, homers, conveyors, a lift, a persistent quest table,
the well and the bucket, and a per-turn sound effect sequencer. There is no
day and night and no transformation.

## How it works

**Knight Lore's, nearly unchanged** (match score from `kl_matches.txt` where
it says; the routines read side by side in stage 2):

| Pentagram | Knight Lore | Notes |
|---|---|---|
| `CALC_VIDBUF_ADDR`, `CALC_VRAM_ADDR`, `CALC_ATTRIB_ADDR` | `calc_vidbuf_addr` etc. | 1.00 |
| `BLIT_TO_SCREEN` | `blit_to_screen` | 0.95 |
| `CALC_PIXEL_XY` | `calc_pixel_XY` | 0.90, plus a clamp at x 0 ([`drawing.md`](drawing.md)) |
| `DRAW_OBJECT`, `DRAW_SPRITE` and the unrolled runs | `print_sprite` | the same patched unrolled loop, POP-read sprites |
| `MAKE_TABLES` | `build_lookup_tbls` | the same layout at $F100-$FFFF |
| `SORT_AND_DRAW`, `DEPTH_ORDER` | `calc_display_order_and_render` and its table | the table entry for entry ([`depth-order.md`](depth-order.md)) |
| `SET_DRAW_OBJS_OVERLAPPED`, `CALC_2D_INFO` | `set_draw_objs_overlapped`, `calc_2d_info` | |
| `ADJ_FOR_OUT_OF_BOUNDS` and the per-axis tests | `adj_for_out_of_bounds` family | 0.5-0.94 ([`collision.md`](collision.md)) |
| `HANDLE_LEFT_RIGHT`, `HANDLE_JUMP`, `HANDLE_FORWARD`, `MOVE_PLAYER`, `CALC_PLYR_DUV`, `GET_SPRITE_DIR`, `PLAYER_TOP` | `handle_left_right` etc., `upd_player_top` | sounds and the exit check taken out ([`player.md`](player.md)) |
| `IS_NEAR_TO`, `ARCH_NUDGE_TO_CENTRE`, `ADJUST_PLYR_UVZ_FOR_ROOM_SIZE` | the arch and arrival code | the markers and placement the same |
| `TAKE_OR_LEAVE`, `CAN_PICK_UP`, `DO_ANY_OBJS_INTERSECT`, `CHK_PICKUP_DROP` | `handle_pickup_drop` and those after it | joined into one ([`carrying.md`](carrying.md)) |
| `READ_KEYS` | the same | byte for byte, stray `OUT ($FD),A` included ([`input.md`](input.md)) |
| `DISPLAY_TEXT_LIST`, `PRINT_TEXT_SINGLE_COLOUR`, `FLASH_MENU`, `TRANSFER_SPRITE` and friends, `PRINT_BORDER` | `display_text_list` etc. | 0.76-1.00 ([`menu-and-panel.md`](menu-and-panel.md)) |
| `PLAY_NOTE`, `NOTES`, `CLICK` | `play_note`, its note table, the one-wave routine | byte for byte ([`sound.md`](sound.md)) |
| `START_PUFF`, `PUFF` | `init_death_sparkles` and the sparkle | |
| `MAKE_DEADLY` | `set_both_deadly_flags` | |
| the drawing-offset routines | the same short LD HL / JR routines | ([`graphic-numbers.md`](graphic-numbers.md)) |
| the object record | the same 32-byte layout and flag bits | ([`object-records.md`](object-records.md)) |
| the main loop and its timing | `main`, `onscreen_loop`, the six-unit wait | ([`main-loop.md`](main-loop.md)) |

**Changed in the shared code:**

- 54 object records instead of 40, but `DRAW_LIST` still 48 bytes, Knight
  Lore's size -- a possible overflow ([`depth-order.md`](depth-order.md)). The
  candidate chain was doubled to 16.
- The main loop keeps one stack instead of resetting SP per object, saves SP
  every turn in `MAIN_SP` and never reads it; stirs `RANDOM` once per object;
  counts wiped areas in `DRAW_WORK`.
- `SHOW_BUFFER` does not clear the buffer as it copies.
- `FIND_SPRITE` is one routine for Knight Lore's three.
- `BOXES_INTERSECT` does nothing; Knight Lore destroys a collectable there.
- The Z collision test adds conveyors, the "stood on" mark and passing the
  mover's Z step ([`collision.md`](collision.md)); the floor is read from the
  room size rather than a constant.
- Doorways: the pillar decides the exit from the position after the move, and
  the next room is a byte in the scenery entry, not a step on a 16 by 16 grid
  ([`doorways-and-rooms.md`](doorways-and-rooms.md)). Only record 0 can leave.
- The player: one form, a four-frame walk, facing from bit 2 of the graphic,
  a jump that tests "standing".
- The object templates are five bytes, not six (no placement nudge; the code
  to set one survives, unreached, [`room-building.md`](room-building.md)).

**Knight Lore's leftovers still in Pentagram** ([`leftovers.md`](leftovers.md)):
the directional-control code and the sixth menu line's flashing with no line
to flash; the pick-up bit 5 for a directional joystick; the colour-byte text
printer; the turning sound's `BIT / JR` to the next instruction; the falling
sound's `ADD A,2`; `EXIT_STUB` where the exit check was; the head's frame
hold count; the movable block's blip, gated and unused; the menu's colour
clear over eight lines.

**Pentagram's own**: firing, bolts and scoring; things from the sky and the
drop timer; homers; the lift, the bobber, the pacers, the sinking and
crumbling blocks and the conveyors as written; the persistent quest records
and the quest chain (well, bucket, items, pentagram, collectables); the
doorway table; the percentage's weighting; the effect sequencer; the carried
things' colours on the panel; the lives number.

**Knight Lore's own, gone**: day and night and the transformation, the
cauldron and the wizard, the charms and their special-object records,
ghosts, portcullises, the materialising respawn, the rating.

## How this was found

Stage 1 compared every Pentagram routine entry with every Knight Lore routine
by instruction pattern, 16-bit numbers and jump targets ignored
(`game_disassembly/pentagram/kl_matches.txt`, not committed): of 140 entries
of five instructions or more, 37 matched a Knight Lore routine at 0.80 or
better and 62 at 0.60 or better. Stage 2's agents then read each pair side by
side, and every difference above is from that reading; the note player and
note table were compared byte for byte.

## Confidence

*Read*, with the byte-for-byte comparisons *measured*. A match score is only
a hint; each claim here rests on the reading.

## Open questions

- Whether Knight Lore's other released successor on this engine, Alien 8, is
  closer to Pentagram in the parts Pentagram changed (the 54 records, the
  doorway byte): not looked at.
