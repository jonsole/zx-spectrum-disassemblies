# The ship

**Question this answers:** how the player's ship moves -- its physics, top
speeds and the scroll it makes -- how its picture is built from the add-ons
it picks up and what each add-on does, and where the next ship starts.

**Short answer:** the ship never moves across the screen: steering and
thrust become this pass's scroll steps, 2 or 4 pixels, and the world moves
the other way. Across, a push of $40 against a drag of 12; up, thrust $50
or gravity $40 (one or the other), all in 256ths of a speed unit, a unit
being 2 pixels a pass. Its picture is rebuilt in RAM whenever an add-on is
fitted: the bare ship with each add-on masked and drawn in, hanging below
it (or, for one, standing on top). Every fourth pass, if the place is safe,
it is saved as the restart point.

## How it works

### The record

`ship_record` ($C8E5), 32 bytes in the objects' layout
([objects.md](objects.md)), reset each life from `ship_record_start`
($C906). Because the ship stays put on the screen, its world position is
the view's:

| Offset | Label | Field |
|---|---|---|
| +1, +2 +3 | `view_page_column` $C8E6, `view_page_x` $C8E7 | map column; x in the page and fraction |
| +4, +5 +6 | `view_page_row` $C8E9, `view_page_y` $C8EA | map row; y and fraction |
| +7 +8, +9 +A | `ship_dx` $C8EC, `ship_dy` $C8EE | this pass's step across and down (minus the scroll), high byte first |
| +$18 | `ship_facing` $C8FD | bit 7 facing left |
| +$19 +$1A | `ship_across_speed` $C8FE | speed across, 8.8, high byte first |
| +$1B +$1C | `ship_down_speed` $C900 | climb speed |
| +$1D, +$1E | `ship_screen_x` $C902, `ship_screen_y` $C903 | the ship's place on the screen: x $60, bottom line |
| +$1F | `part_being_fitted` $C904 | an add-on (its number) or a rocket part ($C0 + part) being fitted |

The byte after it, `ore` ($C905), is the ore in the tank.

### One pass

```
play loop -> ship_pass $C374
  count the pass (pass_counter $9A64); odd passes: shield_timer - 1
  every 4th pass: save_restart_point $C33C
  dying (death byte $0B+) or launching: skip the movement
  move_ship $B234
    read_controls $B115 -> read_control_method $B16F (controls_now $5C37); burn fuel
    across: push / drag -> accelerate_across $C7FC -> speed_to_scroll $C81F -> scroll_across $CCBB
    up: thrust or gravity -> clamp_climb $B322 -> climb_fraction $B320 -> scroll_down $CCBA
  ship_speed_from_scroll $B9EC   the record's step = minus the scroll
  collide_with_landscape $BA21   box 48 wide, its height + 4 (+0 with add-on 9)
  ship_hits_ground_objects $A8F4
  move_object $BF66
  update_shots $B706; JP scroll_landscape $DDF8 ... JP draw_ship $C3E3
```

### Across

`move_ship` builds the push in DE, in 256ths of a speed unit a pass a pass:
`push_left` ($B318) +$40 steering left, `push_right` ($B316) -$40 steering
right (the speed is kept in the scroll's sense, opposite to the ship's way
through the world). The drag, `drag_going_right` ($B31E) +12 or
`drag_going_left` ($B31C) -12, is set against last pass's step across. When
steering the way the ship already goes, the drag is ignored; steering
against it, the drag is added -- so reversing is quicker than speeding up.
The drag goes by last pass's step, not the speed: with nothing held a speed of
-0.031 was left once the step had come to 0 (*run*, the How it works page).
Nothing pushed, the drag alone slows the ship, and `accelerate_across` turns a
speed that would change sign into 0: the drag never reverses the ship. No push
at all while `fuel_saver` ($5C40) says the ship is being knocked sideways.

`clamp_speed_across` ($C868) keeps the speed's whole part to half the top speed
`top_speed` ($5C3E, 2, or 4 with add-on 4) one way and one more the other.
`speed_to_scroll` adds the speed to `ship_position_across` ($C7FA) and the step
is twice the change in its high byte: **the screen moves in 2-pixel steps**, up
to the top speed (2 or 4 pixels a pass). A 4-pixel step from a fine scroll of 2
or 6 is halved, so 4-pixel steps start only on 0 or 4 -- the landscape has
copies pre-shifted by 0, 2, 4 and 6 pixels ([landscape.md](landscape.md)). In
SkoolKit's simulator, steady flight without add-on 4 never stepped more than 2
pixels, but after the ship struck a hillside 4-pixel steps came (*run*, for the
Animations page): the clamp's one more unit the other way, or a slope's
reflection of the speed -- not checked.

`steer_push` ($5C36) records the steering: $80 left, 3 right, 0 none.
`draw_ship` turns the ship's facing towards it.

### Up and down

DE is `gravity` ($B312, -$40) or, while thrusting, `thrust` ($B314, +$50): one
or the other, so thrust beats gravity by only $10 a pass. The climb speed
(+$1B) is clamped by `clamp_climb`: no faster than -3 down and half `top_climb`
($5C3F; 2, or 4 with add-on 5) up. Both this clamp and `clamp_speed_across`
hold only the whole part, the high byte, and keep the fraction: with thrust
held the climb speed saws between 1.0 and 1.94, and the speed across likewise
(*read*, and *run* in SkoolKit's simulator for the How it works page). It is
added to `climb_fraction`, and twice the change in the whole part is the step
up: 2 or 4 lines a pass climbing, and a fall of 6 is cut to 4. At a step of 4
either way, every other fine-scroll position (`origin_y` $CE42 bit 1) moves
only 2.

The keyboard never sets "down"; the ship comes down by gravity alone. Three
overrides in `read_controls`:

- **The ceiling.** No thrust while the view is on page row 5 (row 0 with
  add-on 5) and its line within the page (`view_y` $CE46) is above $60.
  Without the lift jet the ship cannot climb into the top five rows of sky,
  where the stars are.
- **The special beam.** While it is out (`special_beam_on` $B832) only fire
  and the special key are read, and the ship hangs still: no climb, no fall
  ([weapons.md](weapons.md)).
- **Docked with the finished rocket** (`launch_state` $96AB set): nothing is
  read; `move_ship` holds thrust on at the fast climb until the view reaches
  page row 0, then stops ([rocket-and-ore.md](rocket-and-ore.md)).

The constants as a table, for reuse (*read*):

| Label | Value | Meaning |
|---|---|---|
| `gravity` $B312 | -$40 | a quarter unit (half a pixel a pass) each pass, down |
| `thrust` $B314 | +$50 | replaces gravity while thrusting |
| `push_right`, `push_left` $B316, $B318 | -$40, +$40 | steering |
| `no_push` $B31A | 0 | |
| `drag_going_left`, `drag_going_right` $B31C, $B31E | -12, +12 | against the way across |
| `top_speed` $5C3E | 2 or 4 | pixels a pass across |
| `top_climb` $5C3F | 2 or 4 | pixels a pass up; down at most 4 |

### Meeting the landscape and the ground objects

The ship's landscape box is 48 pixels wide and its picture's height plus 4.
`collide_with_landscape` tests it against the four on-screen pages'
collision-box lists ($5B80, $5BA5, $5BCA, $5BEF): a floor or ceiling
reverses and halves the climb speed, clamps it to -3..+2 and drops it to 0
in a dead band (`dead_band` $BA0B, -0.65 to 0.39), with a bump; a wall
reverses and halves the speed across, with a buzz; a slope reflects the two
speeds into each other, stops the scroll that pass and, on a second pass in
a row on a slope, slides the ship 2 pixels downhill. Details are in
[landscape-collision.md](landscape-collision.md).

`ship_hits_ground_objects` ($A8F4) boxes the ship (40 wide from x $64, its
height) against the first four ground objects: a refuel pad refuels and
repairs ([damage-fuel-lives.md](damage-fuel-lives.md)); anything else is
solid, `bounce_across` ($AA01) or `bounce_up_down` ($AA15) reversing and
halving the step (`reverse_speed` $AA27).

### The picture and the add-ons

`build_ship_sprite` ($AFE9) rebuilds the picture whenever a part is fitted
(`draw_ship` sees `part_being_fitted`) and at each life's start. The buffer
`ship_picture` ($F6B9) is 300 bytes, 50 rows of 6, drawn from its first row
upwards (bottom row first, like every graphic). The bare ship (`bare_ship`
$C891, 84 bytes, 14 rows) goes in rows 26-39. Each fitted add-on is drawn
in by `fit_addon` ($B09C) at its place from `addon_places` ($AFD7): its mask
ANDed on first, unless the byte after the picture is $FF (so a mask whose
first byte is $FF counts as none), then the picture ORed on
(`addon_mask_and_draw` $B0E4). Each add-on's graphic in `addon_graphics`
($AF95) is preceded by the picture height it needs (40 less its starting
row); the highest wins, the picture starts 40 - height rows in
(`ship_graphic` $C1AA), and `ship_height` ($C1A9) holds it. The ship's top
stays where it was on the screen; its bottom line (`ship_screen_y`) moves
down by the rows added, and the record's world position with it, so nothing
jumps. `ship_line` ($5C38), the line the shots fly along, is 8 lines below
the picture's top row.

The add-ons are the nine bytes from `addon_slots` ($F5EE) in the player
record, add-on n's slot holding n or 0. Picked up by `collect_pickup`
($AAD7) as place n-1 of the player's dealt places
([rocket-and-ore.md](rocket-and-ore.md) has the dealing):

| Add-on | Slot | Picture (by appearance) | Effect (*read*) |
|---|---|---|---|
| 1 | `addon_slots` $F5EE | hook, 23 rows below the ship | needed to pick up a rocket part |
| 2 | `addon_two` $F5EF | second hook | never picked up: set with add-on 1 (twice its slot); stops `hit_block` hiding the lift jet near a box below |
| 3 | $F5F0 | the ore tank | never fitted: its place is never dealt (the tank comes as rocket part 6) |
| 4 | `addon_four` $F5F1 | block | the side jet; top speed across 4 |
| 5 | `addon_five` $F5F2 | arches | the lift jet; top climb 4; the ceiling moves from page row 5 to row 0 |
| 6 | `addon_six` $F5F3 | mound | fuel burn halved |
| 7 | `addon_seven` $F5F4 | post | the special beam ([weapons.md](weapons.md)) |
| 8 | `addon_eight` $F5F5 | bar | every other shot a homing missile |
| 9 | `addon_nine` $F5F6 | figure | stands on top: 11 more rows upwards; can lift the two-piece load (below); the landscape box gets no extra 4; no trail hold on bit-3 boxes |

With both jets fitted the wave table also opens its last two kinds
([attackers.md](attackers.md)). Add-on 9 is the one that grows upwards: its 15
rows start at row 36, inside the bare ship, and `build_ship_sprite` adds 11 to
the height without moving the start, so the picture runs on to row 50 -- one
row past the 300-byte buffer, into the six bytes the listing calls spare
(`spare_after_ship` $F7E5) (*read*; it runs in the build's every-add-on
session). With every add-on fitted the picture is 51 rows, rows 0-50
(*simulated* for the Graphics page).

The add-ons lying on the planet are type $0C objects whose frames are the
same graphics; add-ons 10 and 11 (`addon_slab` $7436, `addon_spire`
$74E7) are the two-piece load below.

### The jets and the trail

Drawn separately, by `draw_direct_pair` ($A59F) like the ship, on
alternate passes (*read*; both run in the build's every-add-on session,
the side jet never steering left, the lift jet never at a lift-off):

- **Side jet** (`side_jet` $C5FF, record `side_jet_record` $C6C2): with
  add-on 4, flickers behind the ship while it steers, graphics $0E-$10
  through `side_jet_frames` ($C7A9), a 2 by 2 colour patch cycling through
  `jet_colours` ($C79B). Odd passes.
- **Lift jet** (`lift_jet` $C6D2, record `lift_jet_record` $C78F): with
  add-on 5, under the ship, graphic $12, or $11 while thrusting, mirrored
  every other draw so it seems to spin, white. Even passes. `lift_jet_skip`
  ($C6D0), set by `hit_block` when a box with kind bit 2 lies 0-40 lines
  below the ship, skips it for a pass (not with add-on 2). Dying, it
  is only erased: that is why the death sequence calls it once.
- **Trail** (`draw_trail` $C4ED, record `trail_frame` $C7BC): always
  there, a one-byte-wide line behind the ship whose bend follows the speed
  across -- frame 1 + twice the whole pixels + the half, at most one past
  the top speed, mirrored with the direction, from `trail_images` ($C7C8).
  Redrawn only when the frame changes, the ship turns (`ship_turned`
  $C7C0) or a collision asks (`trail_collision` $D0BC). `trail_hold`
  ($C7C1) holds it straight for 4 passes after the ship touches a bit-3
  box without add-on 9.

### Drawing the ship

The ship does not use the compositor's buffer. `draw_ship` ($C3E3) redraws
the image over itself on odd passes and erases it only when it changes: a
turn, a part being fitted, docking. `draw_ship_image` ($C421) then
`draw_direct_pair` interleave an erase row of the old image with a draw
row of the new, bottom up, so little is ever missing. Facing left,
`mirror_ship_sprite` ($BF85) starts at the right-hand byte and draws right
to left through `bit_reverse_table` ($F900). `colour_ship` ($F1BD) paints
it white; yellow once the tank holds 18 ore; cyan while the shield runs,
flashing in its last 32 counts. Each pass the ship costs about 10,000
T-states for a 20-row picture (counted from instruction timings, not
measured; [sprites.md](sprites.md) has the drawers).

### Carrying things

- **A rocket part** hangs below the hook: `toggle_carried_part` ($AA37)
  XORs the part's graphic (from `rocket_part_frames` $AF7B) into the
  picture's bottom rows, so the same call puts it on and takes it off, and
  moves `ship_graphic` to the buffer's start with 5 more rows. Part 6, the
  ore tank, fills with ore drawn into bytes 2-3 of the bottom rows
  (`load_ore` $A8A5). See [rocket-and-ore.md](rocket-and-ore.md).
- **The two-piece load** (`carried_part` $C1CE): the slab and spire, add-on
  graphics 10 and 11, lie on the planet as places 9 and 10 of the dealt places,
  the spire dealt 16 to the right of and 35 above the slab. With add-on 9
  fitted, touching the slab (kind 9) picks both up: `player_count_nine` ($F5F7)
  := 9, and the second pick-up record is emptied. They ride on top of the ship
  (5 by $23 and 3 by $2F: the slab's bottom line $0D above `ship_line`, five
  lines above the top of the ship's picture, the spire $23 higher, on the slab;
  drawn by `draw_carried_piece` $C27F on even passes, bright white by
  `colour_carried_parts` $AF04) until the view comes down to page row $0B, the
  lowest row of the surface, at y $A7 or more; then `place_dropped_part`
  ($C1AC) puts them down as two pick-ups at the ship's place, the same distance
  apart, where they can be lifted again. A cloud touching the load pushes the
  ship sideways. What carrying it is *for* does not show in the code (*read*;
  none of it ran).

### The restart point

Every fourth pass `save_restart_point` ($C33C) saves the view's place --
`view_column`/`view_row` ($CE57) to `restart_scroll` ($F5FA), `view_x`/
`view_y` ($CE45) to `restart_view` ($F5FC), `origin_x`/`origin_y` ($CE41) to
`restart_fine` ($F5FE) -- if it is safe: the play area's bottom pixel row (28
bytes from $57C1) is nothing but the ground's $55 dither, or all four on-screen
tiles are empty sky (0) or $A6. Bit 0 of the saved x says which (0 over ground,
1 in the sky). A new game starts from `start_position` ($F3B7), whose y pair
sums to $F7, not the $B7 that `view_y` and `origin_y` otherwise keep between
them, until the fly-in's first vertical wrap sets them afresh (*read*; see the
listing's $F3B7). `start_landscape` restores it at each life, paints the dither
along the bottom first for a ground restart, and flies the landscape in four
lines a pass until the ship's place is clear.

## How this was found

Read from the code in the stage 2 description of the listing (2026-10-16):
`move_ship` and its constants, `accelerate_across`, `speed_to_scroll`,
`build_ship_sprite`, `fit_addon` and the add-on graphics' height bytes and
places (decoded from the snapshot to place each add-on in the buffer),
`collect_pickup`, `carried_part`, `draw_ship` and its jets. The keyboard
mapping and the 2-pixel scroll were also *played* and *measured* at stage 0
([input.md](input.md), [landscape.md](landscape.md)).

## Confidence

The physics and the add-on effects are *read*; the 2-pixel step and the ship's
steering were *watched* at stage 0. Since the staged every-add-on session,
add-on 9 and the rest of `build_ship_sprite`, both jets, the ship-on-slope code
and the ceiling test ($B128-$B132) run in the build (`cyberun-executed.map`).
Never ran there: the carried load (`carried_part` past its first test,
`draw_carried_piece`, `place_dropped_part`), the part-fitting branch of
`draw_ship_image` ($C485-$C4A9), the side jet steering left and the lift jet at
a lift-off. The add-ons' names are by appearance.

## Corrections

- Stage 0's [input.md](input.md) left bit 5 of the controls unknown: it is
  the special key (the number row on the keyboard, any letter but CAPS
  SHIFT and SPACE with a joystick), which fires the special beam with
  add-on 7.
- A first-pass reading had `ship_graphic` ($C1AA) choose between $F6B9 and
  $F6D7 by the ship's facing. It is chosen by bit 6 of `part_being_fitted`:
  a rocket part hanging adds five rows and starts the picture at the
  buffer's start (`toggle_carried_part`, from $AA94).
- Draft 5 read gravity and thrust as acting together; `move_ship` loads one
  or the other.
- The listing's `build_ship_sprite` speaks of a 40-row buffer; the buffer is
  300 bytes, 50 rows, and add-on 9 uses the top ten (and one beyond).
- `$C6D2` is the lift jet, not part of the death sequence (stage 0's
  reading); the death sequence calls it once to erase the jet.
- Draft 8 left `player_count_nine` ($F5F7) unexplained ("a count"); it is 9
  while the two-piece load is carried, 0 otherwise.
- **The slab and spire** were said to hang below the ship. `draw_carried_piece`
  puts the slab's bottom line $0D above `ship_line`, which is eight below the
  ship's top, and the spire $23 higher still: the load rides on top of the
  ship.
- **Coverage** (2026-10-17): this file said add-on 9, the jets, the
  ship-on-slope code and the ceiling test never ran in the build's sessions;
  the staged sessions run them. The open question whether add-on 9's top row
  reaches $F7E5 is answered: with every add-on the picture is rows 0-50
  (*simulated*).

## Open questions

- What the two-piece load is for: nothing in the code rewards carrying it.
  A live session with add-on 9 staged could show whether putting it down
  somewhere particular matters.
- Why the start of a life underground (`start_landscape`'s branch at $DCC6)
  resets places 9 and 10 and `player_count_nine`.
- Why steps of 4 pixels came after the ship struck a hillside without add-on 4
  (above): `clamp_speed_across`'s extra unit one way, or the slope bounce?
  Watch the speed across before and after a hit.
- Why `start_position`'s y pair sums to $F7, not $B7, and whether the first
  passes of a new game draw the landscape $40 lines out until the first
  vertical wrap.
