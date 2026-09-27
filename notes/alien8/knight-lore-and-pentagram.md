# Alien 8, Knight Lore and Pentagram: the shared engine

**Question this answers:** how much of Alien 8 is Knight Lore's engine, how
much it shares with Pentagram, where it differs from each, and what is its
own.

**Short answer:** Alien 8 sits between the two, in code as in time. Its
rooms are Knight Lore's 16 by 16 grid, and it keeps Knight Lore's special
objects (as the places of the valves), exits, menu with directional control,
movers, ceiling drops, per-object stack reset and rating. Its renderer,
depth sort, collision code, player movement, room builder and text printer
are the forms Pentagram also has -- often instruction for instruction --
so those were reorganised from Knight Lore's before Alien 8, and Pentagram
took them on. What is Alien 8's own: the valves and sockets, the 24
cryogenic chambers and the summary's counts, the remote-controlled robots,
the light-years clock, the turning animation, the two-record creatures, the
lifts' shared top, and the two scenes after a game.

## How it works

**The cross-match** (stage 1, *measured* by instruction pattern with 16-bit
numbers and jump targets ignored; `game_disassembly/alien8/matches.txt`, not
committed): of 168 routine entries of five instructions or more, 56 match a
Knight Lore routine at 0.80 or better (93 at 0.60), 65 a Pentagram routine
at 0.80 (87 at 0.60), and 89 one or the other at 0.80 (122 at 0.60). Of those
at 0.60, 45 are closer to Knight Lore by more than 0.05, 54 closer to
Pentagram, the rest level; 46 match neither. A match is a hint; each claim
below rests on stage 2's side-by-side reading.

**Shared with both** (the match scores are stage 2's pairs):

| Alien 8 | Knight Lore | Pentagram | Notes |
|---|---|---|---|
| the main loop and its six-unit wait | `main`, `onscreen_loop` | `START`, `OBJECT_DONE` | a shorter unit; Knight Lore's per-object stack reset ([`main-loop.md`](main-loop.md)) |
| the object record | the same 32 bytes | the same | 56 records (40, 54) ([`object-records.md`](object-records.md)) |
| `CALC_PIXEL_XY_AND_RENDER`, the sprite runs, `FLIP_SPRITE`, `BUILD_LOOKUP_TBLS`, the address arithmetic | `print_sprite` etc., reorganised | the same code, 1.00 | ([`drawing.md`](drawing.md)) |
| `SORT_AND_DRAW`, `DEPTH_ORDER` | its table entry for entry | 1.00 | the list grown to 64 ([`depth-order.md`](depth-order.md)) |
| the collision tests | the `adj_for_out_of_bounds` family | 0.78-1.00 | the Z test differs from both ([`collision.md`](collision.md)) |
| `HANDLE_JUMP`, `MOVE_PLAYER`, `CALC_PLYR_DUV`, `GET_SPRITE_DIR` | `handle_jump` 1.00 | 0.84-1.00 | with Knight Lore's exit check and falling sound ([`robot.md`](robot.md)) |
| `READ_KEYS` | byte for byte | byte for byte | the stray OUT ([`input.md`](input.md)) |
| `HANDLE_PAUSE` | the same, interrupts off | turns interrupts on while it waits | |
| `PLAY_NOTE`, `NOTES` | byte for byte | byte for byte | ([`sound.md`](sound.md)) |
| the text list printer, `FLASH_MENU`, `PRINT_CHAR` | `display_text_list` etc. | 0.82-1.00 | ([`menu-and-panel.md`](menu-and-panel.md)) |
| `BUILD_ROOM` | `retrieve_screen` | 0.90 | fills upwards; the nudge live ([`room-building.md`](room-building.md)) |
| `ADJUST_PLYR_UVZ_FOR_ROOM_SIZE`, `ADJUST_PLYR_Z_FOR_ARCH` | `adjust_plyr_xyz_for_room_size` 0.58, `check_next_arch` 0.62 | 1.00; `FIND_ENTRY_ARCH` 0.47 | the placement Pentagram's form, the arch found Knight Lore's way, by U + V ([`doorways-and-rooms.md`](doorways-and-rooms.md)) |
| `TAKE_OR_LEAVE`, `CAN_PICK_UP`, `SHOW_CARRIED` | `handle_pickup_drop` | 0.86-0.95 | searches only the two place records ([`picking-up.md`](picking-up.md)) |
| the doorway pillars and nudge | `upd_3_5`, `adj_ew`/`adj_ns` | `FIRST_PILLAR`, `IS_NEAR_TO` 1.00 | the nudge only while facing through ([`doorways-and-rooms.md`](doorways-and-rooms.md)) |
| the drawing-nudge routines | the same short routines | `DRAW_AT_...` | Alien 8's own values ([`graphic-numbers.md`](graphic-numbers.md)) |

**Knight Lore's, where Pentagram differs:**

- The grid of rooms and the exits by room arithmetic (`handle_exit_screen`,
  `screen_east`/`north`/`south` at 1.00), the exit decided inside the
  player's move; Pentagram's rooms are linked by a byte in each doorway.
- The special objects (`init_special_objects`, `find_special_objs_here`
  identical, `update_special_objs`) as the places; the destruction of a
  collectable in the depth sort, for the valves.
- The menu's directional control (key 5), and the pick-up on bit 5 under it.
- The movers: the shuttle, the dropping and collapsing blocks, the
  pushables, the spiked ball as the ceiling drop (`upd_63` 0.83) with its
  latch, `move_towards_plyr` and the frame helpers; the extra life
  (`upd_103`); the death sparkle.
- The per-object stack reset; the exit check and falling sound in the
  player's move; the jump test on the speed.
- The rating after a game: the same eight words, order and rule.
- The panel's scroll-work and `print_border`'s shape; Knight Lore's
  `colour_panel`, left in unreached ([`leftovers.md`](leftovers.md)).
- The rooms-seen bits (`MARK_ROOM_SEEN` with its self-modified SET).

**Pentagram's forms, where Knight Lore differs:** the renderer
reorganised (`SHOW_BUFFER` not clearing the buffer; one `FIND_SPRITE`-like
routine), `DRAW_WORK` counting wiped areas, `RANDOM` stirred per object, the
16-byte candidate chain, the Z step handed on in the Z collision test, the
room builder's shape, the legs doing the work for the robot's box.

**Changed from both:**

- 56 records, with the draw list grown to 64 bytes -- enough (Knight Lore's
  48 for 40; Pentagram's 48 for 54 can overflow).
- The Z test marks "landed on" only from a carried mover of graphics 16-47.
- A quarter turn through an in-between view held two turns, and a lost step
  at its end ([`robot.md`](robot.md)).
- The projection subtracts 40 (Knight Lore 104) and returns at once in the
  scene after a game.
- The walk into a room is four turns (Knight Lore three).
- The lifts share a top height per room; the conveyors carry by their own
  step.

**Alien 8's own**: the valves, the sockets and their sparkle, the chambers,
the summary's counts ([`valves-and-sockets.md`](valves-and-sockets.md),
[`chambers-and-summary.md`](chambers-and-summary.md)); the clock
([`clock.md`](clock.md)); the remote-controlled robots
([`remote-robots.md`](remote-robots.md)); the two-record creatures, the
chasers as written, the mice, the leapers, the fragile things
([`creatures.md`](creatures.md)); the scenes after a game
([`scenes.md`](scenes.md)); `COLOUR_PANEL` and `FILL_BOX`.

**Knight Lore's own, gone**: day and night and the transformation (its
sound left in, [`sound.md`](sound.md)), the cauldron and the wizard, the
charms, ghosts, portcullises, the percentage; their variables' bytes are
still there, unreferenced ([`memory-map.md`](memory-map.md)).

**Pentagram's own, not here yet**: firing and scoring, things from the sky
and the drop timer, homers, the persistent quest records, the doorway
table, the effect sequencer.

## How this was found

Stage 1's cross-match, then each pair read side by side by the stage 2 agent
whose range held it; the note table and the pause and key routines compared
byte for byte, the copyright line and `colour_panel` against Knight Lore's
listing, `TRANSFORM_SOUND` found in Knight Lore's snapshot by its bytes.

## Confidence

*Read*, with the byte-for-byte comparisons *measured*. The order of
invention -- that the forms Alien 8 shares with Pentagram were made for
Alien 8 -- is *inferred* from the release order and the code, not from any
record.

## Open questions

- Pentagram's notes asked whether Alien 8 is closer to Pentagram in the
  parts Pentagram changed: in records yes (56, with a list that fits), in
  the map no (Knight Lore's grid, not Pentagram's doorway byte).
- Knight Lore's variables' layout holds up to $5B33, 160 bytes lower; how
  much of Alien 8's own layout from $5B36 Pentagram kept was not compared.
