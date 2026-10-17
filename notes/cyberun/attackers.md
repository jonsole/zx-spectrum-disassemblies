# Attackers: spawning, steering, firing and scoring

**Question this answers:** when and where attackers and clouds appear, how
each kind moves, what attackers and the ground objects fire or throw, what
is left when something is shot or the ship is wrecked, and what each is
worth.

**Short answer:** every eighth pass (and whenever the load is light) one
attacker is started in one of four records, the kinds taken in turn from a
ten-entry wave table. It appears at one of eight fixed spawn points of one of
the four map cells the view straddles -- a mask per tile says which points
that tile allows -- biased towards where the ship is heading, never in view,
and is then accelerated towards the view. Each kind steers by setting its
acceleration now and then; a speed clamp does the rest. Clouds have two
records of their own; a rare meteor shower swaps attackers for rocks and
comets aimed across the ship. Ground objects throw bullets and pick-ups one
pass in 16 while on the screen; only clouds and the tough attacker fire.

## How it works

### When

```
play loop -> spawn_tick $87AF                  nothing while the load is 8 or more
   meteor_shower $87F5: start when random_a = $6A and random_b AND 3 = 0
                        (one pass in 1024); then 128 passes, counted down
   spawn_countdown $8790: counts 8..0 a pass
      at 7 -> spawn_cloud $8792     view in page rows 3-9; records 7-8; kind 1
      at 0 -> spawn_attacker $87E7  find_free_record $87F6 among records 0-3
                -> start_attacker $89D3
update_objects $8D42, load below 4 -> spawn_cloud (half the time) or spawn_attacker
```

`find_free_record` refuses while the load (`object_load` $8E2B) is 7 or
more or the ship is dying, so the screen never fills: see
[objects.md](objects.md) for the load.

### Which kind: the wave table

`wave_counter` ($9932) steps round 0-5, or 0-7 once add-ons 4 and 5 (the two
jets, `addon_four` $F5F1 and `addon_five` $F5F2) are both fitted -- the
better-equipped ship meets the two extra kinds. Kind 4, the tough attacker,
is turned into kind 3 unless the refresh register's bits $32 are all clear
(about one in eight). Kinds 1 and 5 (clouds) become kind 0 outside page rows
3-9. `attacker_kind` ($89D2) holds the result.

`wave_table` ($990A), four bytes a kind: type, +$10 flags (top speed less
one, and bit 5 "already shot" for clouds, which cannot be hit), +$13 frame
byte, +$14 frame range.

| Kind | Type | Top speed | Steering (`steering_routines` $993B) | Points (`type_points` $929C) |
|---|---|---|---|---|
| 0 | $1A dome | 2 | `drift_at_random` $984D: +/-$20 each axis at random, every 1-32 passes | 90 |
| 1, 5 | $13 cloud | 2 | none (`update_cloud` $93F2) | 0, cannot be shot |
| 2 | $17 eye pod | 3 | `turn_at_ship` $9837: $C0 towards the ship, re-aimed every 10-25 passes | 150 |
| 3 | $18 pillar | 2 | `drift_at_random` | 100 |
| 4 | $19 tough attacker | 2 | `steer_tough_attacker` $995B: every 16-79 passes stop dead (one in four) or home at $30 until the next change | 75 a hit |
| 6 | $14 rotor craft | 3 | `home_on_ship` $97FF: after its first wait, $30 towards the ship every pass for good | 250 |
| 7 | $16 saucer | 3 | `home_on_ship` | 200 |
| 8, 9 | $1D rock, comet | 7 | none: the spawner aims it | 350 |

(Names by appearance.) `change_course` ($97DF) counts +$15 down and at 0
reloads it with 1-32 and jumps through the table; once `home_on_ship` sets
bit 7 of +$16 it runs every pass. `steer_towards` ($9341) sets +$0B and +$0E
to +/-$C0, choosing left or right by the pixel within the same page column,
otherwise by whether the object is in the column right of the view's.

### Where

`start_attacker` falls into `start_at_edge` ($8A28):

1. **Which of the four cells.** The view straddles four map cells (pages):
   its own, the one right (`right_map_column` $DDF7), the one below, and the
   one below and right. Bit 1 of `scratch_count` picks right, bit 0 below.
   B says which bits may be random, C which are forced: when the ship moves
   a whole pixel or more a pass across (`ship_across_speed` $C8FE not 0 or
   $FF), the cell ahead in X is forced; likewise in Y. So new attackers come
   from where the ship is going.
2. **Which point.** The cell's tile number (from the four kept by
   `load_map_window` $DF08) indexes `spawn_point_masks` ($855C, one byte
   for each tile $00-$A8): bit n allows point n of `spawn_points` ($8605,
   eight x and line pairs). A random start point is followed round to the
   first allowed one, through a `BIT n,A` whose operand byte is rewritten
   each time (the instruction the listing shows at $8A8A). No point
   allowed: next cell.
3. **Fill.** Clear the record (`free_object` $AC34), copy the kind's four
   bytes from the wave table, set the colour (below), put it in the cell's
   column and row.
4. **Never in view.** `place_on_screen` ($ADD8) is run on it: if it would be
   visible it is freed and the next cell tried (four tries,
   `speed_limit_down` $8C04 doubling as the count). Otherwise
   `head_for_view` ($8C67) stops it and sets $20 of acceleration towards the
   view: right if it is in the view's own column, else left; down if it is
   in the view's row above the view's top, up if in another row below it.

The visibility test is passed DE pointing into the ROM's first bytes (the
tile byte's address with D = 0), not at a graphic, so it measures with a
large size: attackers start well away from the view whatever their real
size (*read*; whether meant is open).

Colour: $FF, or $77 (white) one time in four; for every type but the cloud
it is then replaced by one of the eight in `attacker_colours` ($9933), only
the first four in page rows 4-11. So a white cloud is one in four.

A cloud takes frame 0 or, about one in eight, the big cloud (which counts twice
in the load). In page rows 0-4 it is put at line $1F of row 4, level with the
view, flags $23 (top speed 4, which `update_cloud` reads as "keep your
height"), not tested for visibility (*read*, and *run* in the build's
sessions). A cloud explodes when it drifts below line $A0 of row 10 or into row
3.

**For a new game:** fixed spawn points per cell, a per-tile mask of which
are usable (laid out with the map; a build-time generator should make it),
direction bias from the ship's speed, a rotating kind counter, the
"never in view" retry, and a global load throttle. Cheap and effective.

### Meteor showers

While `meteor_shower` runs and the view is above page row $0B (above the
caverns), `start_attacker` puts a rock or comet near the ship instead: the
ship's position copied (`copy_position` $898E), moved once by an X offset of
-$30 to +$48 and a Y offset of $10 less the ship's screen line (so it starts
at the top of the play area), then given wave entry 9 (a comet) if in the
view's own column, else 8 (a rock). Type $1D then falls 2 or 4 pixels a pass
and drifts 2 or 4 sideways -- right for a comet, left for a rock -- at top
speed 7, damages the ship and dies on contact ($51), and explodes on the
landscape (`update_rammer` $9494).

### What the attackers fire

Only two kinds do, through `attacker_fires` ($8813), one pass in 32 and
only when drawn last pass: a white cloud drops shot kind 3 (a pellet,
falling 5 a pass with half the cloud's speed across), and the tough
attacker fires kind 7 or 8 by its facing, a dash flying straight across at
6 pixels a pass.

### What the ground objects fire

`ground_object_fires` ($8820), from `update_ground_objects` ($AC60): a
ground object whose +$18 bits 1-3 name a shot kind fires one pass in 16 at
random, only while on the screen. The kind comes from `object_kind_flags`
($E0FD), bits 7-5 of each kind's byte (*read* from the table):

| Ground kind | Picture | Throws |
|---|---|---|
| 0 | flask | kind 2: the refuel pick-up, straight up |
| 3 | spiky mound | kind 1: bullets, the shield ring, extra lives |
| 4 | lamp (animated) | kind 6: a spray, downwards from high up |
| 5 | domed robot (animated) | kind 4: a spray upwards |
| $0C | domed robot (animated) | kind 5: the fuel thief, sprayed upwards |
| $0D | pylon craft | kind 3: pellets, straight down from high up |

The rest throw nothing. The animated objects (kinds 4, 5, $0C, $0E and $10) are
set up by a path that runs in the build's staged sessions
(`spawn_objects_from_list`, $E1A6); their frames are read from
`object_part_pairs` ($E10E). Kinds 6 and 7 power the flickering beams
([weapons.md](weapons.md)), kinds 8-$0A are ore
([rocket-and-ore.md](rocket-and-ore.md)), kind $0E is the refuel pad
([damage-fuel-lives.md](damage-fuel-lives.md)); how the ground objects are
stored and brought in is in
[world-and-objects-in-it.md](world-and-objects-in-it.md).

`fire_from` ($882B) needs a free record among 4-6 and the shooter between
screen x $18 and $BF; `shot_kind_flags` ($89A7) may want it above line $58
(bit 7, and such shots go down) or from line $50 down (bit 6), and gives
the colour. The new record is type $1C at the shooter's place, given the
kind's template from `shot_kind_templates` ($89AF) -- the gun's mouth as an
offset, used for one `move_object` -- marked shot (so the player's shots
pass through it), and given 56 passes to live. Then its velocity:

| Kind | Frame | Velocity |
|---|---|---|
| 1 | 0-2 bullet | a random spray up (Y 0, -2, -4 or -6; X -6 to +6; nothing or the top value is cancelled), gravity $0020 a pass; one in eight becomes the shield ring (frame 9); every (lives x 4)th becomes the extra-life icon (frame 8) |
| 2 | 3 refuel pick-up | half the shooter's X velocity (0 for a ground object), 5 a pass up |
| 3 | 4 pellet | the same, 5 a pass down |
| 4 | 5 | a random spray up |
| 5 | 6 fuel thief | a random spray up |
| 6 | 7 | a spray, turned downwards when the shooter is above line $67 (`fire_spray_down` $8970, which the code map first took for data) |
| 7, 8 | 10 dash | 6 a pass, right (7) or left (8) |

**Extra lives** come from `extra_life_countdown` ($896E): each kind-1 throw
counts it down, and at 0 the throw is the extra-life icon and the count is
reloaded with lives x 4. So with five lives one bullet throw in twenty is a
life, with one life one in four: the game is kinder the worse it goes
(*read*; never watched).

### Debris, and the ship's wreck

A shot attacker becomes debris through `check_shot` ($9035) and its second
entry `make_debris` ($903D): type $15, frames 0-5, harmless (effect 0), with
`sound_debris`. `update_debris` ($96D8) takes its velocity each pass from
`debris_path` ($9873) -- sixteen X,Y pairs, out and up, round and down, a
loop of about 60 by 40 pixels, $80 ending it -- the step in +$15 bits 0-5
going on by two, mirrored in X by bit 7 and in Y by bit 6. A shot attacker
starts in a random quarter.

When the death byte reaches 10, `wreck_ship` ($8CB2) takes all nine records:
four debris 28 pixels right of the ship and half its height up, with +$15
0, $40, $80, $C0 -- the four mirror images at once, a burst -- and five type
$1C bullets (+$14 = 2 marks them as wreck) thrown out by `wreck_velocities`
($8D1F) (two left, one up, two right, all upwards) under gravity $0020.

### Missiles' targets

`find_missile_target` ($92B4) looks at records 0-6 drawn this pass and takes
the one whose type rates highest in `missile_target_values` ($92EE), storing
its record number in the missile's +$17 high nibble; 0 is never chosen. Its
`INC A`, the test for a free record, comes before the `SUB $14`, so the index
is the type less $13, as for `type_points`: rotor 8, saucer 7, eye pod 6,
pillar 5, dome 4, tough attacker 2, rocks 9 -- the order of their points, the
tough attacker last because it takes many hits -- and clouds, debris, thrown
things and rocket parts 0 (*read*). In 240 seconds of simulated flying with
missiles, run for the reference pages, all 285 targets chosen were the best on
the screen by that ranking (*run*); clouds, debris and bullets were passed
over. See [weapons.md](weapons.md).

### Scoring

`score_object` ($9234, inside `test_player_shots`) adds by type from
`type_points`: $14 250, $16 200, $17 150, $18 100, $1A 90, $1D 350, $19 75 a
hit; ground objects (types $0D and $1B) 250; doubled when destroyed outright
by the special beam (+$17 bit 3). `add_score` ($925E) adds BC in BCD to the
three score bytes of the player record (`score` $F5E7, low first) and
reprints the six digits ([players.md](players.md)). Other sources: a
pick-up 1000, a rocket part delivered 1500, a planet secured ten times 5000
([rocket-and-ore.md](rocket-and-ore.md)).

The tough attacker counts a laser hit only on a pass whose pass-counter
bits 0-2 are clear (`update_tough_attacker` $94A8): seven hits in eight are
thrown away. A missile counts one directly. It flashes white from ten hits
and explodes at fourteen. With the special beam it dies only once worn down
(+$D = $FF), and then credits one or two units of ore to the tank
([rocket-and-ore.md](rocket-and-ore.md)).

## How this was found

Read from the code in the stage 2 description of the listing (2026-10-16):
the spawners, `start_attacker` and `start_at_edge` instruction by
instruction (the rewritten `BIT n,A` found from its writer), the wave,
colour, mask and point tables, the steering routines, `fire_from` and its
two tables, and `object_kind_flags` decoded by hand for the ground kinds.
Nothing here was watched live.

## Confidence

*Read*, all of it. The attackers' names are from their pictures. The staged
sessions run the clouds in rows 0-4 ($8B2E-$8B57), the missile target finder
($92B4-$92ED), the meteor shower's placement and the cloud-drops path
($8820-$882A). Never ran in the build's sessions: `fire_spray_down` ($8970) and
the frame-0 throw ($892E-$896D: the bullets' spray, the shield ball and the
extra life), so the extra-life rule rests on reading alone.

## Corrections

- Draft 2 called `spawn_point_masks` "one mask per screen kind". The kind is
  the cell's tile number from the map: the table has one byte per tile,
  $00-$A8.
- Draft 3's first pass called type $1D a "rammer" that attacks on its own;
  it is only ever the meteor shower's rock or comet (wave kinds 8 and 9),
  aimed by the spawner. The label `update_rammer` keeps the old name.
- Draft 3 asked what clouds drop: white clouds drop pellets (kind 3).
- **The missile target table** was read as off by one (indexed by the type less
  $14), so that missiles chased debris and clouds. The free-record test's `INC
  A` before the `SUB $14` makes the index the type less $13, the points' order;
  the reference pages' trial of 285 choices bears it out.
- **Coverage.** This file said the clouds in rows 0-4, the missile target
  finder and the cloud drops never ran, and that the animated ("two-part")
  objects' path never ran. The staged sessions run them
  (`cyberun-executed.map`, 2026-10-17); still never run are `fire_spray_down`
  and the frame-0 throw.

## Open questions

- Whether the ROM-sized visibility box at spawning is meant.
- Whether the tough attacker scores on every pass of its explosion.
- `spawn_point_masks` has 169 bytes, tiles $00-$A8, but the map uses tile
  $A9 once (and $AA is swapped in for tile $3E while the screen is built):
  both read their mask from `spawn_points` itself ($10 for $A9). A slip, or
  room for a tile added late? Harmless either way; not checked live.
