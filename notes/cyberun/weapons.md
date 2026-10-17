# Weapons and beams

**Question this answers:** how the ship's weapons work -- the laser, the
homing missiles, the special beam -- and how the flickering beams that
cross some screens work.

**Short answer:** four shot records at `shot_records` ($B37A). A laser is a
one-line beam drawn straight on the screen that grows out of the ship's
nose, head 16 pixels a pass and tail 8, until a probe running ahead through
the world meets the landscape or the head reaches the edge; then the tail
catches up. It is drawn with OR and erased by ANDing exactly what was drawn,
so nothing under it is lost. With add-on 8 every other shot is a homing
missile, an ordinary object. With add-on 7 the special key, while the ship
is still, fires a pulsing band that holds the ship still, destroys what it
touches outright -- ground objects included -- and mines ore. The
flickering beams are lines across screens of tile $A6, random in pattern
and colour, that damage the ship until the thing making them is destroyed.

## How it works

### Firing

```
draw_ship $C3E3 -> draw_trail -> fire $B731
  special_beam_key $B833      launch or end the special beam
  gun_cooling $5C39 not 0: count it down, no shot
  fire held (controls bit 4): gun_cooling := 6; shot_alternator $B730 bit 0 flips
  first free of the four shot records (a missile's when +0 = $FF, a beam's when +B = 0)
    free_object; +0 := facing; place_shot $B90A (the ship's world place, the shot line)
    special (shot_alternator bit 2)   -> the special beam
    bit 0 set and add-on 8 fitted     -> a missile
    otherwise                         -> a laser, moved ahead of the nose, sound_crackle_b
ship_pass -> update_shots $B706 every pass
    missile (+$16 bit 7) -> update_missile $9307
    beam (+B not 0)      -> update_shot $B483 / update_left_shot $B628 / update_special_beam $B414
```

The cooling count is set to 6 and counted down on the passes that follow,
so the gun fires at most every seventh pass (about three shots a second),
and no more than four shots are ever in flight.

### The shot record

The objects' 24-byte layout ([objects.md](objects.md)) for +1 to +A, with
the beams' own fields (*read*, from the shot routines):

| Offset | Field |
|---|---|
| +0 | the facing ($FF free; a missile's type, 0) |
| +1 ... +A | world position and speed, as every record |
| +B | screen x of the beam's left end (0 none) |
| +C | screen line |
| +D | attribute |
| +E | length in cells |
| +F | offset into the beam pattern |
| +10 | bit 7 head stopped, bit 6 tail moving, bit 5 probe hit |
| +11 | age; +12 a step |
| +15 | bit 7 the special beam; low bits its frame (a missile: its life) |
| +16 | bit 7 a missile |

### The laser

`update_shot` (going right) and `update_left_shot` (mirrored):

- **First pass** (+E = 0): the line is `ship_line` ($5C38) less this
  pass's climb, plus a random -1, 0 or +1 (`random_jitter` $B403), so a
  stream of shots is slightly ragged; the colour is random bright cyan,
  yellow, white or magenta (`random_beam_colour` $B3F2).
- **Growing**: the head moves 16 pixels a pass, the tail 8, the length (+E,
  in cells) one more each pass.
- **The probe**: the record's world position moves 16 pixels a pass ahead
  of the ship (+7 is the ship's speed plus 16), and each pass
  `probe_laser` ($B6EC) tests a 24 by 12 box there against the landscape
  (`probe_shot` $B6F2, `test_landscape_at` $9056, mode $80: stop at the
  first box touched) with a tick on a hit. When the probe hits, or the head
  reaches the play area's edge (x $B8 for the left end going right, 8 going
  left), the head stops (+$10 bit 7).
- **Ending**: the pattern offset (+F) counts down to 0, then the tail
  catches up a cell a pass (bit 6) until the beam is gone and the record
  freed. While stopped, the beam moves with the vertical scroll, so it stays
  on what it hit.

The drawing (`draw_shot` $B5AF) is worth reusing. A pattern of 8 bytes,
rows 8 bytes apart (`laser_pattern_right` $B3DA, ragged at the tail and
solid at the head; `laser_pattern_left` $B3E2, mirrored): a beam of n cells
takes n bytes from offset +F, so as the beam grows and +F falls the head
stays solid and the tail stays ragged -- 16 bytes give a beam of any length
that looks as if it is moving. `draw_beam` ($B336) ORs it on;
`erase_laser` ($B356) ANDs the inverted pattern from last pass's width,
pattern and address, kept in the alternate registers before the shot
moved, so it removes exactly what was drawn and nothing under it. The
colour is a strip of attribute cells one high (`shot_colour_patch` $B625,
`fill_attributes` $C991).

**Hitting things.** `test_player_shots` ($917C), called by
`update_objects` for each object, tests the object's box against each laser
as a line (x +B, line +C, length +E cells). A hit marks the shot (+$10
bit 7) and the object shot (+$10 bit 5); the object's own update scores it
and makes debris next pass. Only the first shot to hit counts. Lasers do
not touch ground objects.

### Missiles

With add-on 8, every other shot (`shot_alternator` bit 0 set): type 0,
graphic `missile_frames` ($B936, two frames by facing), bright cyan, from
32 pixels ahead of the nose and 3 lines up, 8 pixels a pass the way the
ship faces, top speed 8, a life of 127 passes (+$15), +$16 = $80.

`update_missile` ($9307): with no target (+$17 high nibble $F) it calls
`find_missile_target` ($92B4), which takes the best-rated type among
records 0-6 drawn this pass from `missile_target_values` ($92EE). With a
target it steers at it (`steer_towards` $9341, $C0 each axis), and gives
it up when the target's record is freed. `move_missile` ($938D) rubs it
out, accelerates, faces it the way it moves (`set_facing` $92FA), counts its
life, moves it bouncing off the landscape in a 16 by 11 box, and draws it.
For the hit test it is an 8 by 5 box at its drawn place; a hit frees it,
and on the tough attacker counts one hit directly.

**The target table ranks by points.** `find_missile_target` tests the type for
a free record with `INC A` before its `SUB $14`, so the table is indexed by the
type less $13, as `type_points` ($929C) is, and its bytes rank the rotor craft
8, saucer 7, eye pod 6, pillar 5, dome 4, tough attacker 2 and rocks 9 -- the
order of their points, the tough attacker last because it takes many hits.
Clouds, debris, thrown things and falling rocket parts rate 0 and are never
chosen (*read*). In 240 seconds of simulated flying with missiles, run for the
reference pages, all 285 targets chosen were the best on the screen by that
ranking (*run*); clouds, debris and bullets were passed over. See
[attackers.md](attackers.md).

`move_missile` also has an unexplained case: over a landscape piece $3E,
with its line between $18 and $D7, a missile's line is set to $6A.

### The special beam

`special_beam_key` ($B833): the special key (bit 5 of the controls: the
number row on the keyboard, any letter but CAPS SHIFT and SPACE with a
joystick) fires it if add-on 7 is fitted (`addon_seven` $F5F4) and the ship
is still -- both speeds last pass inside the dead band (`dead_band` $BA0B,
-0.65 to 0.39). It goes through `fire` with `shot_alternator` bit 2 set:
+$15 = $80, bright magenta, its left end at x $90 going right or $60 going
left, its line 9 below the shot line. `special_beam_on` ($B832) := $80, and
while it is set `read_controls` reads only fire and the special key and
`move_ship` holds the ship still.

`update_special_beam` ($B414):

- a band 5 to 8 lines high, its frame from `beam_frames` ($B8CF) cycling 0,
  1, 2, 3, 2, 1 -- each frame a height and a 16-pixel pattern a line --
  expanded by `expand_beam_frame` ($B8DB) into an 8-byte-wide pattern in
  the sprite buffer at $F800 (last pass's, for rubbing out:
  `old_beam_frame` $B897) or `sprite_buffer_two` ($F880, this pass's:
  `new_beam_frame` $B8B5), so `draw_beam` and `erase_laser` handle it as a
  laser of several lines;
- grows a cell every other pass up to 8, its probe (a 24 by 16 box,
  `probe_special_beam` $B6F0) 8 pixels further each time; stops growing when
  the probe meets the landscape. Fired with the ship on the ground the probe is
  in the landscape at once: the cell just grown is taken off again, the length
  is back to 0, and `draw_shot` frees the record in the same pass, so the beam
  shows only in the air (*read*, and *run* in SkoolKit's simulator for the
  Animations page);
- after 22 passes (+$11 = $16), or when the key is let go
  (`end_special_beam` $B889), shrinks a cell a pass until gone, and the
  ship is free again;
- a flutter every pass (`sound_flutter` $7234).

What it hits:

- **Sky objects**: in `test_player_shots` a shot with +$15 bit 7 destroys
  outright (+$17 bit 3, the dissolve) instead of marking the object shot,
  and scores double. The tough attacker dies this way only once worn down
  (+$D = $FF), and then credits one or two units of ore (from the refresh
  register) to a carried ore tank.
- **Ground objects**, the only weapon that touches them:
  `update_ground_objects` calls `beam_hits_ground_object` ($ABA8) for each
  ground object on the screen, not a pick-up, not dissolving, not of kind
  $0B. `find_special_beam` ($B870) finds the beam's record and the same line
  test is run (`test_shot_box` $AC29). An object it starts dissolving is
  marked gone in `map_object_kinds` ($5C94) for this player and scores 250.
  For graphic $0D: an ore deposit (kinds 8-$0A) writes its kind into the
  beam's +$13, and when the beam has gone `draw_shot` jumps to `load_ore`
  ($A8A5), which adds one unit (kinds 8, 9) or two ($0A) to the tank -- so
  one firing mines one deposit's worth, the last it hit
  ([rocket-and-ore.md](rocket-and-ore.md)); kinds 6 and 7 set their map
  square's bit, switching off the flickering beams (below).

`find_special_beam` looks only at the first three shot records and leaves
IY at the fourth unchecked if none matches; harmless as long as the beam
is always found in the first three (*read*, not checked).

### The flickering beams

`draw_beams` ($9BDA), from `scroll_landscape` each pass (not while the
screen is being built). For each of the four on-screen cells whose tile is
$A6, a one-line beam crosses the cell's full width at a fixed height --
unless its bit is set in the player's `player_flag_bits` ($F5EA): 24 bits,
one for each of twelve page rows and the two halves of the map (columns
below $30, and from $30), found by `map_square_bit` ($AC08) and tested by a
`BIT` instruction `draw_beams` writes into itself. Destroying a ground
object of kind 6 or 7 with the special beam sets the bit: these are the
beams' generators, and one switches off every beam in its row and half of
the world for the rest of the level (`level_done` clears the bits).

- `beam_state` ($9BD6): the pattern, colour, timer, and whether one was
  drawn (for `sound_beams` $72CF). When the timer runs out: half the time
  a pattern from `flicker_beam_patterns` ($9DA9) in a random bright colour
  for 1-32 passes, else none for 1-16.
- Each pass the old beams are rubbed out (`erase_flicker_beam` $9D25, from
  `flicker_beam_records` $9D43) and drawn again (`place_flicker_beam` $9D53
  works out the place and rotates the pattern by the fine scroll so it does not
  slide; `draw_flicker_beam` $9D30 ORs it on and records it), and coloured. A
  beam lies at page y $21, 9 lines below the top of its tile-$A6 cell, in
  whichever row of the window the cell is (`place_flicker_beam`, *read*).
- A beam touching the ship's box (40 by 16) damages it (`beam_hits_ship`
  $9D0E, then `damage_ship`), and `beam_grace` ($9D2F) gives 16 passes
  before it can again. Nothing during the launch.

## How this was found

Read from the code in the stage 2 description of the listing (2026-10-16):
`fire`, `update_shot`, `update_left_shot`, `update_special_beam`,
`draw_shot`, `update_missile`, `test_player_shots`,
`beam_hits_ground_object` and `draw_beams`; `place_flicker_beam` and
`draw_flicker_beam` were code the first map had as data. The laser was seen
firing at stage 0 (the top letter row fires).

## Confidence

The laser is *read* and ran in the build's sessions; since the staged
every-add-on session, so do the missile and its target finder, the special beam
and the beams' pattern change ($9C1E-$9C54) (`cyberun-executed.map`). Never ran
there: the special beam going left or with its probe in the landscape ($B44D,
$B45A, $B469), a missile fired facing left ($B7D8), `find_special_beam`'s
fall-back to the fourth record ($B884), the beam actually hitting a ground
object ($ABD0-$AC07: no deposit or beam maker destroyed) and `load_ore`'s
loading -- all read only. That kinds 6 and 7 are the beams' generators is
*inferred* from the bit they set being the bit the beams test.

## Corrections

- Draft 3 asked what sets bit 7 of a laser's +$15: it is the special beam,
  which is the "heavy shot" that destroys outright.
- Draft 3 called the special beam's effect on the tough attacker "credits
  1-2 ore to part 6": it credits the ore tank only while part 6 is the part
  carried (`load_ore` returns otherwise).
- The listing leaves `player_flag_bits` ($F5EA) unexplained; they are the
  beams' generators destroyed, per map row and half.
- **Coverage.** This file's Confidence said the missile, its target finder, the
  special beam and the beams' pattern change never ran; the staged every-add-on
  session runs them (`cyberun-executed.map`, 2026-10-17).
- **Listing slip:** the description of `place_flicker_beam` ($9D53) took the
  view's position and the fine scroll from $CE04 (the mirror table). They come
  from `view_x`/`view_y` ($CE45) in HL and the origins ($CE41) in DE, which
  `draw_beams` loads; fixed in `cyberun_annotations.ctl`.
- **The missile table is not off by one.** This file, attackers.md, objects.md,
  overview.md and the listing read `find_missile_target` as indexing by the
  type less $14 -- a probable bug that made missiles chase debris and clouds
  and pass over the attackers worth most. The `INC A` before the `SUB $14` was
  missed: the index is the type less $13 and the table follows the points, as
  the reference pages' trial of 285 choices bears out. The pillar the
  Animations page saw a missile choose fits either reading and decided nothing.

## Open questions

- The missile over piece $3E (line set to $6A).
- Why the laser's probe starts 8 or 24 pixels from the ship but moves 16
  ahead of it each pass; the geometry of the head against the probe is not
  worked out.
- Whether the flickering beams show in the sky: tile $A6 also lies in map rows
  1-3 (the world's map, drawn for the pages); unchecked.
