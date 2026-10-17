# Collision with the landscape

**Question this answers:** how the ship, the objects and the shots meet the
ground -- where the ground's solid shapes come from, how a move is tested
against them, and what a touch does to the speed.

**Short answer:** while the screen is being built into new pages,
`draw_landscape` ($D0BD) writes a 5-byte box for every piece it draws into a
list per on-screen page ($5B80, $5BA5, $5BCA, $5BEF). `collide_with_landscape`
($BA21) places a record's box where this pass's speed would take it, cuts it
into the parts lying in each page (1, 2 or 4), and tests each part against
that page's boxes. Flat floors, flat ceilings and walls are blocks: the
speed into them is reversed and halved, with a dead band that stops small
bounces. Slopes reflect: 45-degree ones swap the two speeds, the others mix
them with factors of 3/8 and 3/4.

## How it works

### The boxes, made while drawing

Each page on the screen has a list of 37 bytes: a count, then up to seven
5-byte boxes, one per piece of the page's tile.

| Address | Label | Page |
|---|---|---|
| $5B80 (+$5B99) | `loader_entry`, `ground_cell_top_left_rest` | the view's page (`view_column` $CE57, `view_row` $CE58); written over the dead loader |
| $5BA5 | `ground_cell_bottom_left` | the page below |
| $5BCA | `ground_cell_top_right` | the page to the right |
| $5BEF | `ground_cell_bottom_right` | below and right |
| $B944 | `empty_box_list` | a count of 0, for a page off the screen |

The count is rewritten every pass. The boxes are written only while
`record_ground` ($5C3D) is set: when `scroll_landscape` ($DDF8) has wrapped
into a new page this pass, or while the screen is built after a restart
(`map_rebuild` $5C3C). The pages do not change between, so neither do their
boxes. In map rows 0-2 (no landscape) all four counts are zeroed. The
pointer to the next box is `collision_object` ($BA09) while drawing.

A box, as `draw_landscape` writes it (positions in the page, y counting
down; a box spans its height *upwards* from its bottom line):

| Offset | Flat piece (0, 7) | Wall (14, 15) | Slope |
|---|---|---|---|
| +0 | x | x (16 less for direction 15) | x of one end (a slope running left starts a step further right) |
| +1 | bottom line: y + 16 for a floor, y for a ceiling | y | that end's y |
| +2 | width: 24 x steps | $18 | x of the far end |
| +3 | height: $14 (20) | height: 16 x steps | y of the far end |
| +4 | class | class | class |

So a floor's box is a 20-line slab whose top is the surface's top line.
The class comes from `piece_classes` ($D0AC), one byte per direction:

| Bits | Meaning | Directions |
|---|---|---|
| 0-1 | slope steepness: 1 gentle (2 across per line), 2 45 degrees, 3 steep (half across per line) | 1-6, 8-13 |
| 2 | flat floor ($04) | 0 |
| 3 | flat ceiling ($08) | 7 |
| 4 | wall ($10) | 14 |
| 5 | wall ($20) | 15 |
| 6 | the slope climbs to the left | 4-6, 11-13 |
| 7 | the slope is a ceiling | 8-13 |

Any of bits 2-5 makes a *block*; none, a *slope*.

### Testing a move

```
collide_with_landscape $BA21 (IX record, C width, B height, $5C25 who)
  place_collision_box $BE8F
    where the record will be: move_across $B980, move_down $B9BB (not stored)
    the speeds for the bounce rules (see "The speeds' signs")
    find_page_boxes $B946: the page's list by comparing with the view's page
    the part inside the page; what sticks out right ($5C2A) and above ($5C2B)
    the number of parts, 1, 2 or 4, into $5C1D
  next_part_boxes $BA2E: for each box of the part's page:
    any of class bits 2-5?  hit_block $BA8F  else  hit_slope $BC13
  next_box $BA4D: after a bounce stop; next box; next part (next_part $BE43:
    part_right $BE26, part_above $BE10, then above and right)
```

The record's box is placed by its bottom-left corner, so it can only stick
out of its page to the right and above: the part in its own page, the part in
the page to the right (from x 8), the part in the page above (from line
$B7), and, when both, the part above and right. Each part is tested only
against its own page's boxes.

Who is testing, in `piece_step_x` ($5C25, a landscape variable borrowed):

| Value | Who | Caller | Box |
|---|---|---|---|
| $FF | the ship | `ship_pass` ($C374) | 48 wide, the ship's height + 4 (+ 0 with add-on 9) |
| $80 | a shot's probe, stops at the first hit | `probe_shot` ($B6F2) | 24 x 12, 24 x 16 for the special beam |
| 0 | an object that bounces | `move_bouncing` ($909A) via `test_landscape_at` ($9056) | by type (below) |
| $80 | an object that explodes on touch | `move_or_explode` ($90A7) via `test_landscape_at` | by type |

`test_landscape_at` moves the object 4 left and 4 down for the test (lining
the box up with its sprite) and back afterwards. The box sizes passed (width
x height, from draft 3's reading of the callers): attackers 34 x 35, clouds
48 x 32, the tough attacker 48 x 24, the rammer 32 x 32, small things 24 x
24 (42 x 24 for the ship icon and the shield ring), missiles 16 x 11.

`piece_ceiling` ($5C35) keeps what has happened this pass: bit 7 a block hit
(no more blocks tested), bit 6 a bounce (no more boxes at all), bit 4 a
slope hit (no more slopes). `scratch_count` ($5C1C) is non-zero for a
hit. A shot stops at its first hit; the ship and the objects stop at a
bounce -- except an object once the death byte `death_count` ($8F53) is 10
or more (docking with the finished rocket, or dying), which goes on testing.

### The overlap test

`boxes_overlap` ($9DB1) is the engine's one box test, for the landscape and
for every sprite contact too (the ship's touches $8E2D, the shots $917C, the
ship against the ground objects $A8F4). The box at IX is x, bottom line,
width, height; the other is L, H, D, E. `x_overlap` ($9DBB): the box's x is
within D after L, or L within the box's width after its x. `y_overlap`
($9DD8): the same for the lines, each box spanning its height upwards from its
bottom line. `$5C1C` = 1 for an overlap. A handful of 8-bit compares; with at
most seven boxes a page and four parts, a record makes at most 28 tests a
pass.

### The speeds' signs inside the bounce rules

`place_collision_box` puts the speeds into the form the rules use: for an
object it negates both (`negate_velocity` $90CD, which `move_bouncing` undoes
afterwards); for the ship it puts back last pass's speeds, `ship_across_speed`
($C8FE, where a push right is negative) and `ship_down_speed` ($C900, the
climb speed: thrust positive, gravity negative). Either way, inside the rules
the speed across (+7 +8) is positive moving left and the speed up and down
(+9 +A) positive moving up. `last_speed_across` ($BE8D) is the whole part of
+7; `last_speed_up` ($BE8E) is the whole part of +9 *negated* -- so, despite
its name, it is positive while the record moves down.

### Blocks: floors, ceilings, walls (`hit_block` $BA8F)

A block is tested only if the record is moving into it or still:

| Class | Tested while | Then |
|---|---|---|
| floor (bit 2) | `last_speed_up` >= 0: moving down, or still | the speed up and down reversed and halved |
| ceiling (bit 3) | `last_speed_up` <= 0: moving up, or still | the same |
| wall $10 | moving right, or still | the speed across reversed |
| wall $20 | moving left, or still | the same |

Then `boxes_overlap`. On a hit:

- **Floors and ceilings.** The speed (+9 +A) is negated, halved
  (`halve_hl` $BE03), clamped (`clamp_object_speed` $C880: whole part from
  -3 to +2) and put through the dead band (`dead_band` $BA0B: anything from
  -$A8 to +$63 in 256ths, about -0.65 to +0.39, becomes 0). Still moving:
  a bounce (bit 6), and the test ends. An object also has its screen fields
  cleared; on a floor its bottom line is set 20 above the box's bottom, so it
  sits on the surface; one that stops against a ceiling is given 2 pixels a
  pass downwards. The ship's new speed sets this pass's step at once (the
  second entry of `move_ship`, $B2D5) with a bump (`sound_crackle` $7293);
  on a flat floor (class exactly 4) with the ship sunk more than 20 lines
  in, this pass's step is 2 up. The ship touching a ceiling without add-on 9
  sets `trail_hold` ($C7C1) to 4, which holds its trail straight for four
  passes.
- **Walls.** The speed across is negated. For the ship it is also halved,
  clamped and dead-banded, the step across worked out again
  (`speed_to_scroll` $C81F), a sound (`sound_buzz` $7263), and
  `trail_collision` ($D0BC) set; for an object only its screen fields are
  cleared.
- **Before any of this, for the ship:** a floor box whose bottom line is 0
  to 40 lines below the ship's and which spans part of x+4 to x+40 sets
  `lift_jet_skip` ($C6D0), so the lift jet under the ship (add-on 5) is not
  drawn into the ground -- unless add-on 2 is fitted.

### Slopes (`hit_slope` $BC13)

One slope a pass. `test_landscape_piece` ($9E35) tests the part against the
slope's shape by class bits 6-7: as stored, mirrored left to right
(`test_slope_reversed` $9EA5, which swaps the two x bounds,
`test_slope_swapped` $9E7A), upside down (`test_slope_upside_down` $9EC0)
or both (`test_slope_both_ways` $9ED9). `test_slope` ($9DEE) finds, at the
part's line, how far it reaches under the slope's high edge, scaled by the
steepness (45 degrees as it is, steep halved, gentle doubled), and leaves the
depth in `touch_depth` ($5C1A). A shot stops; the ship sets `trail_collision`
to $FE. Then the speeds are reflected, with U the speed across (left
positive) and V up and down (up positive):

| Slope | Routine | New U | New V |
|---|---|---|---|
| 45 degrees, climbing right (bit 6 clear) | `bounce_45_negate` $BD04 | -V | -U |
| 45 degrees, climbing left (bit 6 set) | `bounce_45_swap_only` $BD3B | V | U |
| gentle, climbing right | `bounce_shallow_negate` $BD44 | 3/8 U - 3/8 V | -3/4 V - 3/4 U |
| gentle, climbing left | `bounce_shallow` $BDBD | 3/8 U + 3/8 V | -3/4 V + 3/4 U |
| steep | the same two | the gentle rule with U and V swapped before and after (`swap_speeds` $BDD8) | |

The 45-degree rows are exact reflections off the lines y = x and y = -x
(worked out from the signs above, *read*). The other rows are as the
listing reads the routines; the signs of the cross terms come from
`slope_negate` ($BDC8), which negates the whole word for a ceiling slope
(bit 7) or a steep one and only the whole part otherwise, so they are
approximate. All the factors are under 1: every slope bounce loses speed.
The negations are switched on or off by two JRs whose displacements each
routine patches (0 runs the CALL after it, 3 jumps it) -- self-modifying
code the first code map took for data. Each result is clamped
(`clamp_object_speed`).

After a slope (`leave_slope` $BC5B): an object is pushed across out of the
slope by `touch_depth`, through `move_across` with that as its speed for a
moment (a push of 16 or more sets bit 3 of +$10, skip the next placing); its
screen fields are cleared; and if both new speeds are too small to matter it
is set sliding a pixel a pass downhill (`downhill` $BCBF, by the slope's
facing). The ship (`ship_on_slope_response` $BCD1) stops scrolling this
pass, with a sound unless it is being knocked sideways (`fuel_saver` $5C40)
or was on the slope last pass; on its second pass in a row
(`ship_on_slope` $BC12) it slides 2 pixels downhill.

### The ship's pass, around the test

```
ship_pass $C374
  move_ship $B234                 controls -> speeds -> steps $CCBB, $CCBA
  piece_step_x $5C25 = $FF
  ship_speed_from_scroll $B9EC    ship record +7, +9 = minus the steps
  collide_with_landscape $BA21    may change the speeds and the steps
  ship_hits_ground_objects $A8F4
  keep the speeds (+7, +9 -> $C8FE, $C900)
  ship_speed_from_scroll; move_object $BF66   the record follows the steps
  JP scroll_landscape $DDF8       the landscape moves by the (new) steps
```

So a bounce changes the scroll itself before anything is drawn: the ship
never visibly enters the ground.

### For a game of your own

- Make the collision shapes as a by-product of the drawing data (one box per
  piece, from its start, steps and direction), and only when the set of
  visible pages changes.
- Keep shapes per page, and cut a moving box at page edges into at most four
  parts, so every comparison is 8-bit.
- Test only the faces a thing is moving into (floor while falling, a wall
  by the way it moves), reverse and halve, and zero anything in a small dead
  band so bounces die away instead of jittering.
- For slopes, swap the speeds for 45 degrees and mix them by cheap shifts
  (3/8, 3/4) for the others.

## How this was found

Stage 0 (2026-10-16): a two-minute flight ended pressed against a rising
slope (*played*), which suggested the ground was solid. Stage 2
(2026-10-16): read from the code in the stage 2 description of the listing
(`cyberun.skool`, $B946-$BF66 and the box writer in $D0BD); the class table
decoded by hand against the direction table; the signs inside the bounce
rules traced through `place_collision_box`, `move_ship` (thrust +$50,
gravity -$40, a push right -$40) and `ship_speed_from_scroll` for this
note.

## Confidence

- *Read*: the box lists and their format, the class table, the parts, the
  overlap test, the block and slope rules.
- *Read and reasoned*: which class is a floor and which a ceiling (from the
  signs; see Corrections). It fits every use: the lift jet is suppressed over
  a bit-2 box below the ship, an object on a bit-2 box is sat on top of it,
  one stopped against a bit-3 box is pushed down.
- Ran in the build's sessions, the staged tours included
  (`cyberun-executed.map`): all of it -- the ship's block and slope paths,
  objects bouncing, the bit-3 (ceiling) branches ($BB4A-$BB56, $BB98), the
  walls' direction tests and wall response ($BAFA-$BB0C, $BBC5-$BBE0), the
  ship-on-slope code ($BCD8-$BD04), the swap-only 45-degree bounce, the
  upside-down slope shape ($9EC0) and wall boxes ($D20A-$D22C). What each does
  is *read*. The swap-only 45-degree bounce was also *run* in SkoolKit's
  simulator for the How it works page: speeds of 2.25 across and 0.418 up came
  out swapped. The rest were not checked against the screen.

## Corrections

- **Floor and ceiling.** The listing's descriptions of
  `collide_with_landscape` and `hit_block` say a box with class bit 2 clear
  is a floor and one with bit 2 set a ceiling, and draft 5 left "the sense of
  bit 2" open. Bit 2 ($04) is the class of direction 0, the flat *floor*, and
  bit 3 ($08) that of direction 7, the flat ceiling. The code tests a bit-2
  box while `last_speed_up` ($BE8E) is zero or positive; that byte is the
  negated speed in a frame where up is positive (both the ship's climb
  speed and an object's negated velocity are up-positive there), so it is
  positive moving *down*. Floors are tested while falling, ceilings while
  rising. (`last_speed_up`'s name and the listing's "the climb speed it had
  last pass" have the sign the wrong way round.)
- **Bit 3.** Draft 5 called it a "special" block and `trail_hold` ($C7C1) a
  "scrape count". Bit 3 is the flat ceiling; $C7C1 holds the ship's trail
  straight for four passes after it hits one.
- **Stage 0's open question** "does the landscape act as solid?" -- yes,
  through these boxes.
- **Listing slip:** the description of `test_landscape_piece` ($9E35) says
  the object's box is in $CE04 (the mirror table); it is in `box_x` to
  `box_width` ($CE3A-$CE3D), made by `place_collision_box`.
- **Coverage.** This file's Confidence listed the ceiling branches, the walls,
  most of the ship-on-slope code, the swap-only bounce, the upside-down slope
  shape and wall boxes as never run. The staged tours run them all
  (`cyberun-executed.map`, 2026-10-17).

## Open questions

- The cross terms' signs in the non-45-degree bounces (which of `+` and `-`
  goes with which facing, and the whole-part-only negation): settle by
  watching a bounce off a gentle slope in the emulator, speeds before and
  after.
- Which side of a wall is rock: class $10 stops a thing moving right, $20 one
  moving left, and walls run in the staged tours, but which side stopped what
  was not watched; watch one.
- Why an object goes on testing every box once the death byte is 10 or more.
- What add-on 9 has to do with ceilings (it skips `trail_hold`) -- see the
  add-ons in [sprites.md](sprites.md).
