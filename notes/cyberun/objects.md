# Objects: the records and the update loop

**Question this answers:** how Cyberun keeps its moving things -- attackers,
clouds, bullets, pick-ups, debris -- and what one pass does with each.

**Short answer:** nine 24-byte records at `object_records` ($9974), each with
a type byte ($13-$1E) that picks an update routine from `object_handlers`
($AF25) and a frame list from `object_graphic_lists` ($AF3D).
`update_objects` ($8D42) runs over the nine once a pass: rub out last pass's
picture, run the type's routine (which accelerates, animates, moves, places
and draws), test the object against the ship, then against the player's
shots. What touching an object does is one byte of effect bits, set by the
update routine. A "load" counted over the same loop throttles spawning.

## How it works

### The record

The same 24-byte layout serves the nine sky records, the ship's record
(`ship_record` $C8E5, 32 bytes), the four shot records (`shot_records`
$B37A), the rocket's drawing record (`rocket_record` $9A4C), and the first
$18 bytes of the six 26-byte ground-object records (`ground_objects` $A80B),
so one set of routines moves, places and draws all of them (*read*). The
ground objects themselves are in
[world-and-objects-in-it.md](world-and-objects-in-it.md).

| Offset | Field |
|---|---|
| +0 | type: $FF free; $13-$1E for the sky objects; the index into `object_graphic_lists` |
| +1 +2 +3 | X: page column (0-$5F, wrapping), pixel in the page ($08-$E7), fraction |
| +4 +5 +6 | Y: page row, pixel ($18-$B7, the thing's bottom line), fraction; Y grows downwards |
| +7 +8 | X velocity, signed 8.8 pixels a pass, **high byte first** |
| +9 +A | Y velocity, the same |
| +B +C | X acceleration, the same form |
| +D | two colours: bits 0-2 ink and bit 3 BRIGHT on odd passes, bits 4-6 and 7 on even passes, black paper (`prepare_draw` $AD48); $FF is steady bright white, $77 white |
| +E +F | Y acceleration |
| +10 | flags: bits 0-2 top speed less one; bit 3 skip one placing; bit 4 free it next pass; bit 5 shot; bit 6 straddles the view's left edge; bit 7 drawn |
| +11 +12 | where it was drawn: screen x, bottom line |
| +13 | frame: bits 0-3 the frame in the type's list, bits 4-5 a count, bits 6-7 the count's reload |
| +14 | frame range: high nibble the first frame, low nibble the last |
| +15 +16 | the type's own: a timer, a path step, a hit count, a target place |
| +17 | high nibble: contact cool-down, or a missile's target record ($F none); bit 3 exploding; bits 0-2 the explosion's step |

Positions are page + pixel + fraction. The world is a ring of $60 page
columns by 28 page rows, a page the size of the play area (224 by 160).
`move_object` ($BF66) adds +7 and +9 to the position through `move_across`
($B980) and `move_down` ($B9BB), which carry into the next page.

### Who uses which record

| Records | Use |
|---|---|
| 0-3 | attackers (`spawn_attacker` $87E7, through `attacker_records` $8791, always 4) |
| 4-6 (`drop_records` $99D4) | what attackers and ground objects fire or throw (`fire_from` $882B) |
| 7-8 (`cloud_records` $9A1C) | clouds from `spawn_cloud` ($8792) |
| 0-6 | a homing missile's possible targets (`find_missile_target` $92B4) |
| all nine | the ship's wreck (`wreck_ship` $8CB2) |
| any | a rocket part falling into place (`find_record_for_part` $97BD: a free one, else one not drawn, else the ninth) |

Clouds also come through the wave table into records 0-3 (see
[attackers.md](attackers.md)).

### One pass

```
update_objects $8D42
  count the death byte (death_count $8F53); at 10 wreck_ship; from 10 sound_death
  load := rocket_parts_load ($8D3C)
  for each of the nine records not free:
    count the contact cool-down (+$17 high nibble) down
    death byte 1-3: every object starts exploding (+$17 bit 3)
    contact_effect := $50; load += 1
    clear_sprite_pair $A2EA
    drawn last pass (+$10 bit 7): count_and_erase $8E21 (load += 1, prepare_erase)
    EXX; run_sky_object_handler $A18D -> JP (object_handlers + 2*(type - $13))
    ship_contact $8E2D
    clouds, $1C (not wreck pieces), $1D: drawn last pass but not now -> freed
    not shot, not exploding: object_box $9143, test_player_shots $917C
  load < 4: half the time spawn_cloud (view rows 3-10), else spawn_attacker
```

The update routines run with the erase set up in the other register set,
and end in the shared tail of `update_attacker` ($9507), entered at its
several points (`animate_move_draw` $9512, `move_draw` $9518, `place_draw`
$951B, `draw_object` $951E):

```
check_shot $9035        shot (+$10 bit 5)? score it and become debris
change_course $97DF     the type's steering now and then (steering_routines $993B)
accelerate $8C05        velocity += acceleration, held to the top speed
animate_object $910A
move_bouncing $909A     or move_or_explode $90A7: landscape test, then move_object
place_object $90EC      free if marked; prepare_draw; steer_to_view $8C58
draw_object_images $AD1B, colour_sprite $AE98
```

### The types

`object_handlers` ($AF25): twelve words for types $13-$1E. Type $1B's word
points at `type1b_graphics` ($AFCB), a graphic list, not code. Harmless:
type $1B is used only by ground objects, which never go through the table
(*read*).

| Type | Routine | What | Box (w x h) |
|---|---|---|---|
| $13 | `update_cloud` $93F2 | cloud: slows the ship, cannot be shot | 48 x 32 |
| $14, $16, $17, $18, $1A | `update_attacker` $9507 | the attackers ([attackers.md](attackers.md)) | 34 x 35 |
| $15 | `update_debris` $96D8 | a shot attacker's debris, and four wreck pieces | 34 x 35 |
| $19 | `update_tough_attacker` $94A8 | takes 14 hits | 48 x 24 |
| $1B | (data) | ground objects only | -- |
| $1C | `update_small_object` $9457 | bullets, pick-ups, wreck pieces | 24 x 24 (42 x 24 for frames 8, 9) |
| $1D | `update_rammer` $9494 | the rocks and comets of a meteor shower | 32 x 32 |
| $1E | `update_rocket_part` $9524 | a rocket part falling into place ([rocket-and-ore.md](rocket-and-ore.md)) | none |

The graphic numbers below $13 are not sky objects but share
`object_graphic_lists` (31 words, types 0-$1E): 0 the missile, 1-6 the
ship's trail, 7-11 the stars, $0C the add-ons lying on the planet, $0D the
ground objects, $0E-$12 the jets' puffs (these five words point at a graphic,
not a list) and $1B the animated ground objects (*read*).

### Frames and animation

A graphic is a byte of width in bytes, a byte of height in lines, then the
rows, bottom row first; no masks. `object_graphic` ($ADBE) indexes the
type's list by the low nibble of +$13. The sky types' lists overlap:
`attacker_frames` ($9894) holds types $15-$1A and runs on into
`cloud_frames` ($98BE); `small_thing_frames` ($98C2) is type $1C's eleven
frames (0-2 the bullet, 3 the refuel pick-up, 4, 5 and 7 pellets, 6 the
fuel thief, 8 the ship icon, 9 the shield ring `shield_ring` $98D8, 10 the
attackers' dash); `rammer_frames` ($98FA) is type $1D's eight.

`animate_object` ($910A) is a one-byte animator worth reusing: bits 4-5 of
+$13 count down each call; when they read 1 the frame (bits 0-3) steps on,
from the last of the range (+$14 low nibble) back to the first (high
nibble), and the count reloads from bits 6-7. Frame, rate and phase in one
byte, the range in another (*read*).

### The contact effect

Each update routine leaves a byte in `contact_effect` ($8E2C), $50 unless it
says otherwise. `ship_contact` ($8E2D) tests the object's drawn box against
the ship's fixed box -- 40 pixels wide from x=100, 16 lines high, its bottom
8 lines below `ship_line` ($5C38) -- with `boxes_overlap` ($9DB1), only for
an object drawn this pass between x $28 and $8D, not exploding, and not
while the rocket launches or the ship dies. On a touch the bits are acted on
from bit 7 down:

| Bit | Routine | Effect |
|---|---|---|
| 7 | `contact_slow_ship` $8F1E | halve each ship velocity component that agrees in sign with the object's (clouds) |
| 6 | `contact_damage` $8F54 | damage, at most once per 16 passes per object (cool-down in +$17) |
| 5 | `contact_refuel` $8FC4 | refuel: 28 of the gauge's 124 steps |
| 4 | `contact_push` $8FCA | the object's velocity halved and reversed, the same added to the ship's |
| 3 | `contact_collect` $900B | the object freed next pass, with `sound_collect` |
| 2 | `contact_drain_fuel` $9015 | fuel taken: 16 steps |
| 1 | `contact_extra_life` $9020 | a life, at most 9 |
| 0 | `contact_destroy` $9030 | the object counts as shot |
| all ($FF) | in `ship_contact` | the shield: `shield_timer` $896F := $FF, the object freed |

The values in use: $50 (damage and push) for every attacker; $80 for
clouds; $51 for type $1D (damages and dies); 0 for debris; $10 (push) for a
falling rocket part; and type $1C by frame from `small_object_effects`
($944C): $50 the bullets and wreck pieces, $28 the refuel pick-up, $58
(damage, push, collect) the pellets and the dash, $1C the fuel thief, $1A
the ship icon (an extra life), $FF the shield ring. What each does to the
ship is in [damage-fuel-lives.md](damage-fuel-lives.md).

A cloud may also touch a part the ship carries: then the ship's X velocity
becomes minus half the cloud's and `fuel_saver` ($5C40) is set, which
halves the fuel burn this pass and stops `contact_slow_ship` the next
(*read*; never ran).

### Finding a free record, and the load

`find_free_record` ($87F6) looks along A records from IX for type $FF, and
gives up at once while the load is 7 or more or the ship is dying.
`object_load` ($8E2B) is recounted every pass: one for each record in use,
one more for each drawn last pass, one more for a big cloud, plus
`rocket_parts_load` (half the parts delivered, rounded up, while the rocket
is drawn). `update_objects` spawns below 4, `spawn_tick` ($87AF) not at 8
or more, `find_free_record` not at 7 or more. It is a cheap stand-in for
"how busy is this pass": things on the screen weigh double because drawing
is what costs.

### Acceleration with a speed limit

`accelerate` ($8C05) adds +B/+C to +7/+8 and +E/+F to +9/+A, then
`limit_speed` ($8C3F) holds each to the top speed n = (+$10 AND 7) + 1
whole pixels a pass, through `speed_limit` ($8C03, n) and
`speed_limit_down` ($8C04, -(n+1)): a velocity past n.0 becomes exactly
n.0. Steering never sets a velocity, only an acceleration -- $20 (an eighth
of a pixel a pass, each pass) to drift or head back for the view, $30 to
home in, $C0 to turn hard -- so every attacker swings smoothly and the clamp
keeps it from running away (*read*).

Placing one thing relative to another uses the same fields: `copy_position`
($898E) copies +1, +2, +4 and +5; the offset goes in the velocity for one
`move_object`, which carries it across page edges; then the real velocity
is set (`fire_from`, `place_at_ship` $8D29, the meteor shower).

### Costs

Drawing dominates. By the compositor's instruction timings (counted, not
measured; see [sprites.md](sprites.md)), a moving sprite 3
bytes wide and 16 rows high costs about 13,500 T-states to rub out and
redraw, a fifth of a frame. Nine sky records, six ground records and the
stars all go through it, which is what the load counts.

## How this was found

Read from the code in the stage 2 description of the listing (2026-10-16):
`update_objects` followed call by call, the type table decoded, the record
layout gathered from the fields each routine touches, the effect values
matched from each routine's store to `contact_effect` and from
`small_object_effects`. Nothing here was watched live at stage 0.

## Confidence

The record, the loop, the types and the effect bits are *read*. The meaning of
each type comes from its behaviour in the code and its pictures (names by
appearance). Never ran in the build's sessions (`cyberun-coverage.txt`): the
fuel-drain and extra-life effects ($9015, $9020), the shield's start ($8E94)
and the cloud-and-carried-part branch ($8ED5-$8F1D). The refuel effect ($8FC4),
`update_rocket_part` and nearly all of `test_player_shots` run since the staged
sessions (the deliveries, every add-on); of the last, only a missile hitting
the tough attacker ($9202) and the tough attacker's worn-down score ($9227)
never did.

## Corrections

- The first pass of draft 3 gave records 0-8 to the attackers: the spawner
  looks only at the first four (`attacker_records` = 4); clouds have 7 and
  8, thrown things 4-6.
- The listing's note on `object_kind_bytes` ($E205) calls it a
  contact-effect byte, and draft 1 said a ground object's +$0D is picked at
  random from it. It is neither: `spawn_objects_from_list` ($E114) copies
  the byte for the object's kind into +$0D, which `prepare_draw` reads as
  the two flashing colours. Ground objects have no contact effect; the ship
  meets them through `ship_hits_ground_objects` ($A8F4).
- The listing's note on `missile_target_values` ($92EE) said a cloud would
  index the byte before the table, and the first version of this bullet that it
  indexes $93ED, 255 bytes on, whose $1B outranks every real value. Both missed
  the `INC A` before the `SUB $14`: a cloud (type $13) indexes the table's
  first byte, 0, and is never chosen -- in the reference pages' trial no cloud
  was, though clouds do reach records 0-3 through the wave table
  ([weapons.md](weapons.md)).
- **Coverage.** This file listed the refuel effect, `update_rocket_part` and
  most of `test_player_shots` as never run, and asked about "two-part" ground
  objects that never ran. The staged sessions run all three
  (`cyberun-executed.map`, 2026-10-17), and the objects are animated ones, not
  two-part ([world-and-objects-in-it.md](world-and-objects-in-it.md)), spawned
  in the tours.

## Open questions

- `update_tough_attacker`, as read, scores again on each pass of its
  explosion; a watch on the score while one dies would settle it.
- The animated ground objects (graphic $1B, `object_part_pairs` $E10E) are
  spawned in the build's staged sessions now; watching one animate would
  confirm the frames read from the table.
