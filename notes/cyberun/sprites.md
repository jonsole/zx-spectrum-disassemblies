# Sprites

**Question this answers:** how Cyberun draws and rubs out everything that
moves -- the objects, the ship and its parts, the stars -- without masks,
without a back buffer and without flicker, and what the graphics look like
in memory.

**Short answer:** two drawers. The *compositor* `draw_sprite_pair` ($A303)
handles every object and star: it copies the screen rectangle covering an
object's old and new images into a small buffer at $F800, rubs the old image
out there (AND NOT the graphic), ORs the new one in, and copies the rectangle
back -- one write to the screen per object, graphics shifted as they are
drawn through 256-byte tables, in unrolled loops entered at patched
addresses. The *direct drawer* `draw_direct_pair` ($A59F) handles the ship,
its trail, its jets and the part it carries: no buffer, but a row of the old
image rubbed out and a row of the new drawn in turn, straight on the screen,
mirrored when the ship faces left by drawing right to left through a
bit-reversal table. Neither uses masks; colour comes from attribute patches.

## How it works

### Graphics formats

| Form | Layout | Used by |
|---|---|---|
| plain | width in bytes, height in lines, then the lines **bottom line first**, each the width in bytes left to right; no mask | almost every sprite ($731F-$8346), the trail, the stars, the panel bitmaps |
| add-on | a byte before (the ship height needed to show it), the plain form, then $FF (no mask) or a mask of the same size | the ship's add-ons 1-9 (`addon_graphics` $AF95) |
| height-first | height in lines, then 2 or 4 bytes a line; no width byte | the jets ($7846-$7904: side jet 2 bytes wide, lift jet 4) and the special beam's frames ($803B-$8072, 2 bytes) |
| bare | 6 bytes x 14 rows, no header | `bare_ship` ($C891) |
| landscape | zig-zag rows, three variants, a header for the start-up shifter | the terrain pieces ([landscape.md](landscape.md)) |

Everything is stored bottom line first because everything is drawn upwards
from its bottom line (`line_up_hl` $A1C3, `line_up_de` $A1B3); a position's
y is its bottom line. Which picture an object shows: `object_graphic_lists`
($AF3D) has a word per graphic number 0-$1E pointing at a list of frame
addresses, and bits 0-3 of the record's +$13 pick the frame
(`object_graphic` $ADBE; `graphic_frame_list` $A19F for the list).
`read_graphic_header` ($A223) reads a plain graphic and returns the index of
its row routine.

### The compositor (`draw_sprite_pair` $A303)

Every object goes through the same sequence each pass (the sky objects from
`update_objects` $8D42, the ground objects from `update_ground_objects`
$AC60, the stars from `draw_star_layer` $C032):

```
clear_sprite_pair $A2EA        no old image, no new image, no left clip
prepare_erase $AD27            if drawn last pass (+$10 bit 7): old image =
                               the graphic as it still is, at +$11/+$12;
                               clip_sprite_rows $A1FB; set_old_sprite $A234
  EXX                          the old image's graphic and shift page wait in
                               the alternate set
<the object's update>          sky objects: run_sky_object_handler $A18D
prepare_draw $AD48             place_on_screen $ADD8 (visible? where?);
                               set_new_sprite $A247; colour; dissolve step
draw_object_images $AD1B       -> draw_sprite_pair $A303 if either image exists
colour_sprite $AE98            the attribute patch
```

Inside `draw_sprite_pair`:

1. **The box.** The smallest rectangle, whole bytes wide, covering both
   images: left edge `piece_x` ($5C2C, reused), bottom line `piece_y`
   ($5C2D), width in bytes (at most 7) in `piece_dx` ($CE35) and rows + 1 in
   `piece_rise` ($CE37) -- landscape variables borrowed. A missing image
   takes the other's position.
2. **Copy in** (`copy_box_in` $A3F6, chain `copy_in_row` $A419): rows
   bottom-up into the buffer at $F800, packed at the box's width. The loop
   is `PUSH HL` (the row's screen address), a `DJNZ` whose *displacement* is
   patched to land 7 - width LDIs from the end of a 7-LDI chain, then `POP
   HL`, up a line, `JP` back to the PUSH. When B runs out the DJNZ falls
   through to a JP onwards, leaving one address on the stack for the next
   stage to drop. C is $FF so the LDIs' count never reaches B. A variable-
   width rectangle copy with no per-byte counter.
3. **Rub out the old image** (`erase_old_draw_new` $A43E): an unrolled row
   loop entered through IY at the step for the width, from
   `erase_row_routines` ($A294: widths 1-5 shifted, 1-6 aligned). Aligned
   (`erase_aligned_row` $A6B2): `LD A,(DE) / CPL / AND (HL) / LD (HL),A`.
   Shifted (`erase_row_shifted` $A6E1): each graphic byte looked up twice --
   page B for the part staying in this byte, page B+1 for the part spilling
   into the next -- each complemented and ANDed in. Each row ends `LD
   A,step / ADD A,L / LD L,A` with the step patched to the box width less the
   bytes covered, counts rows in A', and `JP (IY)` again.
4. **Draw the new image** the same way with OR (`draw_aligned_row` $A733,
   `draw_row_shifted` $A75C) through IX and `draw_row_routines` ($A2AA).
5. **Dissolve** (`dissolve_sprite` $A498), for a destroyed object: its new
   image's rows ANDed with that step's mask from `dissolve_mask_bits`
   ($A2FB: seven bits set, then six, down to one), rotated a bit per byte so
   the gaps do not line up in columns. One step a pass, counted in bits 0-2
   of +$17 (`dissolve_step` $A302); at the eighth `prepare_draw` frees the
   record.
6. **Copy back** (`copy_box_out` $A54B, `copy_out_row` $A557; clipped:
   `copy_out_part_row` $A524), the same PUSH / patched DJNZ / LDI chain.
   Column 0 is never written, nor anything right of x $E8 (columns 29-31
   are the fuel gauge's).

**Shifting.** x is always even (`place_on_screen` ANDs it with $FE), so there
are four positions. `shift_page` ($A25D) sets B = $F8 + (x AND 6): $FA, $FC
or $FE, the shift tables `build_shift_tables` ($F86B) makes at start-up
(page n = byte shifted right, page n+1 = the bits that fall into the next
byte). An aligned image never uses the table. A shifted image covers its
width + 1 bytes.

**The buffer** at $F800 is start-up code (`build_shifted_pieces` $F7EB on)
that has run once. The row loops address it by L alone, so a box can be at
most 256 bytes; the copy-in moves DE as a word, so a bigger box would run
into the bit-reversal table at $F900. Nothing checks. The special beam
borrows the same page for its expanded frames ($F800 and
`sprite_buffer_two` $F880, `expand_beam_frame` $B8DB), rebuilt whenever it
draws.

**Clipping.** Vertically, `clip_sprite_rows` ($A1FB) cuts an image to lines
$18-$B7: rows above $18 dropped from the height, rows below $B7 skipped in
the graphic (it is stored bottom row first, so DE moves on by width x rows)
and the y put at $B7. Horizontally only the copy back clips the right. The
left has a mode of its own: an image starting nine or more pixels left of
the play area (`place_on_screen` sets +$10 bit 6 and `sprite_left_clip`
$A2FA) has $60 taken off both x positions, which moves positions either
side of 0 into one unbroken 8-bit range, and only the bytes right of x 8 are
copied in and out (`copy_in_clipped` $A3CF, `copy_out_part_row` $A524).

**Erase is not restore.** AND NOT clears every pixel the graphic sets,
including the background and any other sprite under it. Overlapping sprites
punch holes in each other; the landscape survives only because it is
redrawn every pass. `scroll_landscape` runs `update_ground_objects` before
or after `draw_landscape` by the vertical scroll's sign, which decides
whether ground or object wins where they meet.

**Cost** (*counted* from the instruction timings, not measured): per shifted
graphic byte about 79 T-states to rub out and 71 to draw; per aligned byte
about 35 and 31; about 45 a row of loop overhead in each routine and about 150
for each 5-byte row copied in or out. A 3-byte-wide, 16-row shifted sprite that
moves (a 5-byte by 17-row box) costs about 2,500 (copy in) + 4,500 (rub out) +
4,100 (draw) + 2,500 (copy out) = 13,500 T-states, a fifth of a frame. Nine sky
records, six ground records and the stars go through it, Measured over 320
passes in SkoolKit's simulator for the How it works page, `update_objects`
($8D42) takes about 55% of a pass and `draw_landscape` about 20%; the "third of
the game" for the compositor that draft 4 quoted, from a run no note records,
is withdrawn.

### The direct drawer (`draw_direct_pair` $A59F)

For the ship (`draw_ship_image` $C421), its trail (`draw_trail` $C4ED), the
side jet (`side_jet` $C5FF), the lift jet (`lift_jet` $C6D2) and the pieces
of a carried part (`draw_carried_piece` $C27F). No buffer: the old image's
registers are in the alternate set (HL' screen, DE' graphic, IY its erase
routine, rows in `scratch_count` $5C1C), the new image's in the main set (HL,
DE, IX its draw routine, rows in `ground_cell` $5C1D); each image's column is
kept (`sprite_width` $5C28, `sprite_width_drawn` $5C29) to return to at every
row.

```
draw_direct_pair $A59F
  bottom lines differ (direct_old_line $A289, direct_new_line $A28A)?
    the lower image's extra rows first, alone
  direct_next_pair $A61C: old rows left? EXX, JP (IY) -> erase a row, up a line
  direct_then_new_row $A66F: new rows left? EXX, JP (IX) -> draw a row, up
  one runs out: direct_old_rows_only $A611 / direct_new_rows_only $A669
```

Each of the four row loops is six byte-steps that run into each other,
entered at the step for the image's width: `direct_erase_row` ($A629, then
`direct_erase_five` to `direct_erase_one`, $A62F-$A647), `direct_draw_row`
($A678; $A67D-$A691), and the mirrored pair `direct_erase_row_mirrored`
($A7A4; `mirrored_erase_five` $A7AC to `mirrored_erase_one` $A7CC) and
`direct_draw_row_mirrored` ($A7D6; $A7DD-$A7F9). Since a row of the old image
is rubbed out just before the matching row of the new one is drawn, only a
line or two is ever missing: no flicker without a buffer. Images here are
byte-aligned (the ship does not move on the screen).

**Mirroring.** Facing left (bit 7 of `ship_facing` $C8FD),
`mirror_ship_sprite` ($BF85) and `set_mirrored_drawer` ($BFB8) move the
start to the row's last byte, pick the mirrored routine for the width, and
set B = $F9: each byte is then turned round through `bit_reverse_table`
($F900, `LD C,A / LD A,(BC)`) and the row worked right to left. One stored
picture serves both facings.

**Cost** (*counted*): a 6-byte row about 210 T-states to rub out and 190 to
draw, plus about 60 a row each for the loop: about 10,000 T-states for a
20-row ship erased and redrawn.

**Draw over itself.** The ship never moves on the screen -- the world moves
under it ([landscape.md](landscape.md)) -- so `draw_ship` ($C3E3) usually
draws its image over itself with OR and no erase, on odd passes: that
costs half and puts back any pixels an object's AND NOT took out. The old
image is rubbed out only when the picture changes: a turn (the steering
`steer_push` $5C36 against the facing), a part being fitted
(`part_being_fitted` $C904), or docking with the finished rocket (death
byte 10). The carried part and the trail use the same rule. Even passes
draw the carried part and the lift jet, odd passes the ship and the side
jet.

### The ship's picture, built from add-ons

The ship is drawn from `ship_picture` ($F6B9), a RAM buffer of 40 rows of 6
bytes (300 bytes cleared at a life's start), built by `build_ship_sprite`
($AFE9) whenever an add-on is fitted:

```
build_ship_sprite $AFE9
  bare_ship $C891 (14 rows) -> the buffer's last 14 rows (the picture's top)
  for each add-on fitted (addon_slots $F5EE-$F5F6, add-on n's slot n or 0):
    fit_addon $B09C: its graphic from addon_graphics $AF95, its place from
                     addon_places $AFD7; ship_height $C1A9 = max(height byte)
      addon_mask_and_draw $B0E4: mask ANDed on (unless $FF), picture ORed on
  ship_graphic $C1AA = start of the rows drawn; ship_screen_y $C903 moves
  down by the rows added (the top stays put), the world position with it
  ship_line $5C38 (shots come out there) = 8 below the top; speeds; ore
```

Because the buffer is drawn bottom row first, its last rows are the top of
the picture: the bare ship sits at the top, the add-ons hang below it, and
the sprite grows downwards. The catch in `fit_addon`: a mask whose first
byte is $FF is taken as no mask. The effects of the add-ons (speed, climb,
fuel, beam, missiles) are in the ship's own notes; for drawing, add-on 9
adds 11 rows into which `load_ore` ($A8A5) draws the ore collected, one row
of `ore_rows_graphic` ($7721) per unit into bytes 2-3 of each row.

**A hanging rocket part.** `toggle_carried_part` ($AA37) XORs a rocket
part's graphic (type $1E's frame list `rocket_part_frames` $AF7B, by the
part number in bits 0-3 of `part_being_fitted` $C904) into the picture's
bottom rows, shifted 4 pixels through the shift tables and one byte in --
so the same call puts it in and takes it out -- and clears the same place on
the screen. It then sets the height and start by bit 6 of $C904 (a part
hangs): five rows taller and `ship_graphic` = $F6B9, or five fewer and 30
bytes on, $F6D7. That is the rocket part, not the facing.

**Separate pieces drawn beside the ship** with the direct drawer, at places
fixed relative to it and mirrored with it: the **side jet** (add-on 4,
graphics $0E-$10 through the flicker sequence `side_jet_frames` $C7A9,
record `side_jet_record` $C6C2, behind the ship while it steers), the
**lift jet** (add-on 5, graphic $12, $11 while thrusting, under the ship,
drawn mirrored on alternate draws so it seems to spin; record
`lift_jet_record` $C78F; only erased once dying, which is why the death
sequence calls it once), and the **carried part** in two pieces
(`carried_part` $C1CE, `addon_slab_picture` $7438 and `addon_spire_picture`
$74E9). The jets' graphics are in the height-first form: `sprite_graphic_width`
($C7A3) returns their first byte, which is their height, and the drawer is
entered at a fixed width.

**The trail** (`draw_trail` $C4ED, record `trail_frame` $C7BC to
`trail_hold` $C7C1): a one-byte-wide line behind the ship whose bend follows
the speed across. Its frame is 1 + twice the whole pixels + the half, at most
the top speed + 1, from `trail_images` ($C7C8, graphics 1-6, 8 down to 4
rows, leaning further each step); mirrored with the direction
(`trail_mirror` $C7B1). It is erased only when the frame changes, the ship
turns, or the collision code asks (`trail_collision` $D0BC); `trail_hold`
keeps it straight for four passes after the ship hits a ceiling.

### Colour

No sprite has colour of its own: `colour_sprite` ($AE98) works out the
character cells an object's image covers inside the play area (x 8-$E7,
lines $18-$B7) into `colour_patch` ($AF01: width, height in cells,
attribute) and `fill_attributes` ($C991) paints them, bottom row first. A
cell holding only the image's top line is rounded away. The attribute comes
from the record's +$0D, **two colours in one byte**: `prepare_draw` uses
ink bits 0-2 and BRIGHT bit 3 on odd passes, ink bits 4-6 and BRIGHT bit 7
on even passes, always on black paper -- so $77 is steady white, $55 steady
cyan, and two different nibbles flash between two colours at the pass rate.
`trim_colour_patch` ($ACDD) shortens some ground objects' patches.

The ship's colour is its own patch, `ship_colour_patch` ($F1FF, 6 cells
wide), painted by `colour_ship` ($F1BD) each pass: white; yellow with 18 ore
aboard; cyan while the shield (`shield_timer` $896F) runs, flashing every 8
passes in its last 32; a short sound when it changes. The jets have 2x2
patches (the side jet's colour cycling through `jet_colours` $C79B, the lift
jet's white); the carried pieces are coloured white by
`colour_carried_parts` ($AF04).

### Parallax stars

`draw_stars` ($BFE3), called from `scroll_landscape` after the landscape,
only while the view is in map rows 0-3 (open sky). Three layers of six
stars: `star_positions` ($C0EA, 18 x (x, y); bit 0 of x is the "drawn last
pass" flag, so every x is even), each layer's x and y offset in
`star_offsets` ($C184, far, middle, near) and last pass's in
`star_offsets_before` ($C18A). Each pass the offsets move by the scroll
steps scaled by `parallax_step` ($C152): a quarter, a half and the whole.
A plain arithmetic shift would turn -2 into -1 but +2 into 0 for the far
layer, so it would only drift one way; instead it takes 0 and -1, or 1 and
0, on alternate passes. A star's place is its position plus its layer's
offset, wrapping at 256 both ways. `draw_star_layer` ($C032) erases and
draws each star through the compositor; `star_in_sight` ($C10E) keeps it to
x 8-$E7 and y $18-$B8, and in map row 3 hides it at or below the top of the
landscape. Images (`star_images` $C190, graphics 7-11): a pixel, a 2x2 dot,
a cross, each also one pixel right for an odd x (the layer's base graphic in
`star_frames` $C1A3 plus bit 0 of the offset x). Six additions a pass make
three-layer parallax.

### The beams

A laser is a one-line beam ORed onto the screen (`draw_beam` $B336) from an
8-byte pattern (`laser_pattern_right` $B3DA, `laser_pattern_left` $B3E2):
a beam of n cells takes n bytes from a moving offset, so the head stays
solid and the tail ragged as it grows. `erase_laser` ($B356) ANDs the same
pattern inverted, from the alternate registers saved before the shot moved,
so it removes exactly what was drawn.

### Dissolves

Two. A destroyed object crumbles over seven passes in the compositor
(`dissolve_sprite`, above). At the end of the death sequence the whole play
area dissolves to black: `dissolve_play_area` ($9EFE) ANDs every byte of the
28 x 160 area sixteen times with the next of nine one-bit-clear masks
(`dissolve_masks` $9F44), the masks running on from byte to byte and line
to line so the picture loses its pixels in a scattered pattern; then
`dissolve_and_clear` ($9EF5) clears it.

### For a game of your own

- "Erase and draw in a scratch rectangle, then one blit" buys flicker-free
  sprites without masks or a back buffer. Its limits: holes where sprites
  overlap, the background destroyed under the old image (fine over black
  sky), a 256-byte box, widths up to 6 bytes, and four shift positions.
- For a sprite that stays put on the screen, draw it over itself with OR
  each pass and erase only when its picture changes; interleave erase and
  draw rows when it does.
- One 256-byte bit-reversal page plus right-to-left row routines mirror any
  byte-aligned sprite for free in memory.
- Build the player's sprite in RAM from parts with masks, so pick-ups can
  change its shape at no drawing cost.
- Two colours per object in one byte, alternated per pass, give flashing for
  nothing.

## How this was found

Stage 0 (2026-10-16): a watchpoint on $AF02 found it written by the
attribute code at $AEF6 -- a colour patch's height, mistaken at first for
the lives (*watched*). Stage 2 (2026-10-16): read from the code in the stage
2 description of the listing (`cyberun.skool`, $A0B1-$A80A, $AD1B-$B114,
$BF85-$C7FB, $F1BD): the jump tables at $A294/$A2AA land on the byte-steps
of the unrolled loops, the self-modifying stores go into `LD A,n` operands
and `DJNZ` displacements, and the buffer's page is start-up code. The
graphics were walked with a script (the [width][height] chain runs cleanly
from $731F to $7577, $7905 to $803B and $8073 to $8347; the height-first
pieces land exactly on the next pointer) and rendered to a scratch file, not
committed: drawn upright only after flipping, which is how the bottom-first
order showed.

## Confidence

- *Read*: both drawers, the formats, the ship's picture, the colour rules, the
  stars, the dissolves. *Counted*: the costs. The split of a pass's time is
  *measured* (above); the compositor's own share was not measured apart.
- Ran in the build's sessions since the staged ones (`cyberun-executed.map`):
  the stars ($BFE9-$C068, $C10E-$C168, in the tour at map row 3), fitting
  add-ons ($B091-$B114), hanging a rocket part ($AA37) and the jets. Never ran,
  so *read* only: the carried part ($C1D3-$C2E0), the direct drawer's
  unequal-bottoms case ($A5EB-$A60E), the six-byte aligned compositor rows
  ($A6B2, $A733), the side jet drawn mirrored ($C62F, $C67B), and parts of the
  mirrored path ($BFA5-$BFB7, $BFD0-$BFE2).

## Corrections

- **$C1AA.** A first-pass note said it picks $F6B9 or $F6D7 by the ship's
  facing. It goes by bit 6 of `part_being_fitted` ($C904): a rocket part
  hanging under the ship.
- **The height-first pictures.** Draft 2 and the listing's description of
  `puff_graphic` ($7846) say what draws them was not found. They are the
  jets: `side_jet` uses graphics $0E-$10 and `lift_jet` $11 and $12, both
  through `sprite_graphic_width` ($C7A3), whose first byte they read as the
  height (into $5C1D) -- the listing's description of $C7A3 calls it the
  width. The frames at $803B ("ring") are the special beam's.
- **$C6D2** is the lift jet, not the death sequence (stage 0); the death
  sequence calls it once to erase it.
- **Listing slips**, all in descriptions, not code: `draw_sprite_pair` says
  the box's size is kept in $CE04 (it is $CE35 and $CE37);
  `place_on_screen` says the view is kept in $CE04 and the right-hand page
  column in $DDF2 (they are $CE57/$CE58, $CE45/$CE46 and $DDF7);
  `prepare_draw` says the pass counter is in $9974 (it is `pass_counter`
  $9A64); `toggle_carried_part`, `build_ship_sprite`, `load_ore` and
  `fly_in_step` refer to the ship's record as "in $C891" (`bare_ship`; the
  record is `ship_record` $C8E5, the ore `ore` $C905); `draw_star_layer`
  calls $A303 "the mover for small images" (it is the compositor);
  `draw_stars` gives the star positions as $C0E6 (`star_layer_pointer`; the
  table is $C0EA).
- **Coverage** (2026-10-17): this file's Confidence listed the stars, fitting
  add-ons, hanging a rocket part and the jets as never run; the staged sessions
  run them.
- **The compositor's share.** Draft 4's "a third of the game", from an
  unrecorded profile, is replaced by the How it works page's measurement:
  `update_objects` 55% and `draw_landscape` 20% of a pass.
- **Add-on 9's spare row** was read as harmless; the reference pages watched
  it: the figure's top row puts $30 in the third of the six bytes after the
  buffer ($F7E5) and nothing else, and nothing else uses them.

## Open questions

- Whether the order of ground objects and landscape (set by the vertical
  scroll's sign) is meant to decide which wins where they overlap; watch an
  object at the ground's edge while climbing and diving.
- `add_record_size` ($A2C0) and the routine after it, inside the table
  block, are referenced from nowhere: leftovers?
- `load_ore`'s clearing loop moves DE up a line but writes through HL, so it
  clears the same two bytes every time. Watched in SkoolKit's simulator for the
  reference pages: after a two-unit load the second new row shows the empty
  tank's pixels and the ore's together until the ship turns and its picture is
  rubbed out. What the loop was meant to clear is still open.
- What `trim_colour_patch`'s 4 rows and 7 lines are for.
