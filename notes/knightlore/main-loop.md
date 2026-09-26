# Main loop

**Question this answers:** How does Knight Lore start a game, run a frame,
move between rooms and lose a life -- and what does an object record hold?

**Short answer:** A game is set up once (`main`, $AF88), then falls into the
same "start a life" code a death uses. Entering a room builds up to 40 object
records at $5C08; each frame walks all 40, dispatching on the type byte through
`upd_sprite_jmp_tbl`, then draws what changed and pads the frame with a delay
loop to six "units" of drawing. When both of Sabreman's records have emptied,
a life goes.

## How it works

```
START $AF6C            wipe $5BA0-$6107, keep FRAMES as the seed
  main $AF88           tables, menu, tune, rotate wanted list, start room,
                       sun, deal the charms
  player_dies $AFB7    lose_life: restore the saved player records, take a life
  game_loop $AFBA      build_screen_objects: the room into the object table
  onscreen_loop $AFBD  one frame starts; IX = $5C08
    update_sprite_loop $AFC7   SP=$5BA0, push ret_from_tbl_jp, save_2d_info
    jump_to_upd_object $AFD5   type -> upd_sprite_jmp_tbl -> handler
    ret_from_tbl_jp $AFE4      stir R into $5BA5; IX += 32; until IX = $6108
  end_of_frame $B000   frame counter, pause, cauldron bubbles, list and render,
                       finale tone, delay
    game_delay $B035 / delay_loop $B038
    no_delay $B03F     first frame in a room only: redraw the whole screen
  next_frame_or_die $B074   objects 0 and 1 both empty -> player_dies,
                            else onscreen_loop
exit_screen $CABA      (leaving a room) saves the player records as type 120,
                       then JP game_loop
game over              BA22 ... BA87 -> start_menu $AF7F (clears from $5BA8)
                       -> main
```

Three loops, nested: `main` runs once per game; `game_loop` once per room (it is
where `exit_screen` jumps back to); `onscreen_loop` once per frame. The
existing title for $AFBA ("One frame") was wrong on that point and is now
"Enter a room"; $AFB7 ("The player has died") is also the start of every game,
now "Start a life".

**Starting a game.** `main` clears $5BB2 (no room played yet), sets five lives,
adds the frame counter to the game seed $5BA0, shows the menu (whose loop adds
one to $5BA0 every time round), plays the start tune, then:

- `shuffle_objects_required` ($B544) rotates the 14-entry list at $C27D left by
  4 + (seed AND 3) places. The list is in the code, not the variables, so the
  rotations accumulate from game to game; every game asks for the same cyclic
  sequence from a different starting point.
- `init_start_location` ($D1B1) picks one of four start rooms by the same
  seed AND 3. So on the first game after loading, the start room and the order
  the cauldron will ask in are tied together.
- `init_sun`, then `init_special_objects` deals types 96-103 round the 32
  special-object records in cyclic order from seed + R.

It then falls into `player_dies`, so the first appearance goes through the same
path as a death: lives go 5 -> 4 at once. `lose_life` copies back the 64 bytes
saved at $D161 (objects 0 and 1), whose type is 120 (materialising) with the
real type kept at +$10, and adds $20 to that real type at night (from bit 0 of
the sun/moon sprite's type) to make him a werewolf.

**The object walk.** The stack pointer is reset to $5BA0 for every object, and
the return address `ret_from_tbl_jp` is pushed before the jump, so handlers end
with RET and may jump anywhere without tidying the stack. $5BBC is the frame
counter's low byte plus the object's position in the table plus one: the
per-object phase, which makes adjacent fires flicker out of step. After every
object R is added into the random byte $5BA5; at the end of the frame the
16-bit frame counter, both its bytes and the byte of memory at the address it
holds are added in as well.

**End of frame and timing.** `end_of_frame` increments the frame counter, sets
bit 0 of $5BB2, polls SPACE for pause (`handle_pause`), adds cauldron bubbles
if due, lists objects flagged for drawing (bit 4 of +7), and calls
`render_dynamic_objects`, which wipes old rectangles, draws in depth order into
the buffer at $D8F3 and copies the changes to the screen. That renderer counts
each object drawn and each rectangle wiped into $5BBE. The frame then waits
6 - $5BBE units (nothing if negative or zero). A unit is 1280 turns of
DEC HL / LD A,L / OR H / JR NZ, 26 T-states each: 33,280 T-states plus the
DJNZ, about 9.5ms, just under half a 50Hz frame (69,888 T). So the game's speed
is even for rooms where up to six things change per frame and slows beyond
that. (Worked out from the documented instruction timings, without memory
contention; the loop is in uncontended memory.)

**New room.** `build_screen_objects` ($D1E6) sets $5BB7; on the next frame end
`no_delay` ($B03F) clears it and redraws everything: attributes in the room
colour ($5BAD), carried objects, panel, sun/moon, day, days, lives, then the
whole buffer to the screen, and clears every object's wipe flag.

**Losing a life.** A killed Sabreman turns into death sparkles (types 112-119),
then type 1, which the renderer frees to type 0. When `next_frame_or_die` finds
both object 0 and object 1 at type 0 it jumps to `player_dies`.

### The object record (32 bytes, 40 of them from $5C08)

As far as this range's code and the handlers it dispatches to show it:

| Offset | Field |
|---|---|
| +$00 | type, which is also the sprite number (sprite_tbl has one word per type); handlers animate by changing it. 0 = empty slot, 1 = gone, to be wiped then freed |
| +$01, +$02, +$03 | X, Y, Z. Room floors span roughly $40-$C0 in X and Y; the room centre is $80,$80 |
| +$04, +$05 | half-widths in X and Y (the overlap tests add both objects' values) |
| +$06 | height |
| +$07 | flags: bit 1 = take no part in collisions (also set by an object on itself while it is being moved); bit 2 = set on chests, tables, the movable block and charms (meaning inferred: can be pushed); bit 3 = set on Sabreman's records (the arches nudge objects 0-3 that have it); bit 4 = draw this frame; bit 5 = wipe the old image; bit 6 = mirror left-right |
| +$08 | room number |
| +$09, +$0A, +$0B | dX, dY, dZ. Gravity takes one off dZ each move. For an arch these hold a reference point instead |
| +$0C | collision results from the last move: bit 0 blocked on X, bit 1 blocked on Y, bit 2 landed; bit 3 and the top nibble are used by the player code (jumping; a countdown set on entering a room) |
| +$0D | per-type state. Common bits: 7 = kills what it lands on, 5 = kills what lands on it, 6 = has been killed, 3 = something is standing on it. Low bits are directions (guards, flames) or timers (Sabreman's upper body) |
| +$0E, +$0F | nudges from an arch towards the doorway's line |
| +$10, +$11 | for a charm: the address of its record in special_objs_tbl ($6FF2). For Sabreman: +$10 holds the real type while he materialises; for the transformation, a countdown. Zero for room objects |
| +$12, +$13 | drawing offsets, set by each handler through `set_pixel_adj` |
| +$18-$1B | this frame's screen rectangle (size in +$18/$19, position in +$1A/$1B) |
| +$1C-$1F | last frame's, copied by `save_2d_info` at $AFD2, used for wiping |

Objects 0 and 1 are Sabreman's legs and upper body; objects 2 and 3 ($5C48,
$5C68) the slots for charms in the current room (object 3 also carries the
cauldron bubbles). Guards and the wizard are two records, upper body first and
legs at +$20; Sabreman is legs first.

## How this was found

Read the listing from $AF6C to $B5F6 and followed every call and table out of
it: `lose_life`, `init_start_location`, `exit_screen`, `build_screen_objects`,
`render_dynamic_objects` and its wipe loop (for $5BBE and $5BA8),
`calc_pixel_XY_and_render` (type 1 -> 0), `find_fg_objs` (what a room object's
record gets), `adj_for_out_of_bounds` and `adj_dZ_for_obj_intersect` (the +$0D
kill bits), `do_objs_intersect_on_x/y/z`. The delay was timed from the Z80's
documented instruction timings.

Corrections to the existing annotations carried into this range: $AFBA and
$AFB7 retitled (above); the note that the per-object stack "grows into the 32
bytes below" $5BA0 had no support in the code and now says only that it grows
down into the printer buffer, and it moved from $AFBD to $AFC7 where the reset
happens; the $B028 comment ("six frames' worth") now says six units of drawing,
about half a frame each; the $B01B comment now covers the copy to the screen
as well as the composing.

## Confidence

*Watched:* a breakpoint at `onscreen_loop` ($AFBD) stops once every frame;
one at `game_loop` ($AFBA) stopped once as play began and not again while the
player stayed in the room, as its being re-entered only from `exit_screen`
predicts.

All read from the code. Inferred rather than read: the meaning of +$07 bit 2
("pushable"), the exact role of the top nibble of +$0C. The frame-time figures
are computed, not measured.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| next_frame_or_die | loc_B074 | $B074 | after a frame: lose a life if both player records are empty |
| clear_wipe_flag_loop | loc_B090 | $B090 | inner loop of reset_objs_wipe_flag |
| end_of_frame | loc_B000 | $B000 | carried from the existing annotations |

Kept but retitled: `game_loop` ($AFBA, "Enter a room"), `player_dies` ($AFB7,
"Start a life"), `no_delay` ($B03F, "Redraw the whole screen on entering a
room").

## Open questions

- Why a delay of six units: a guess is that six moving things was the design
  budget, but nothing in the code says so.
- The existing annotation on $7112 says the sprite table is indexed by "type
  times eight plus a frame". `flip_sprite` ($D6EF) indexes it by type times two:
  one word per type. That entry is outside this range; whoever owns it should
  correct it.
- The existing annotation on $6FF2 says "#R$B2CF picks a set from this table".
  $B2CF is `play_audio`; the routine that fills that table is
  `init_special_objects` ($C47E). Also outside this range.
