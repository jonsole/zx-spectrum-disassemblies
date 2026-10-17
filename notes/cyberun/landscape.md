# The landscape

**Question this answers:** how the planet's surface is stored, and how it is
drawn and scrolled so smoothly with nothing ever scrolled in memory.

**Short answer:** the world is a ring of 96 by 28 map cells, each a page the
size of the play area (224 x 160), each holding a tile number; a tile is a
short list of *pieces*, straight runs of identical *steps* in one of 16
*directions*. Every pass, `draw_landscape` ($D0BD) redraws every visible step
of the four cells the view straddles straight onto the screen with POP
blitters, from graphics pre-shifted at start-up for 0, 2, 4 and 6 pixels. The
screen is never cleared: black sky and the $55/$AA checker inside the ground
both look the same after a 2-pixel move, so only the thin strips a moving
edge uncovers are painted.

## How it works

### The world, the map and the window

The world is a grid of pages, each exactly the play area: 224 pixels across
(x 8 to $E7, byte columns 1-28) and 160 lines down (y $18 to $B7). Across, 96
pages make a ring; down, 28 rows plus the sky, not wrapping. A position is a
page and a pixel in it (see
[world-and-objects-in-it.md](world-and-objects-in-it.md) and
[landscape-collision.md](landscape-collision.md)).

`landscape_map` ($61BC) is 96 x 28 bytes, a row after another; row R (1-28)
starts at $61BC + (R-1) x 96 (`map_cell_address` $E216, which also wraps the
column: -1 is 95, 96 is 0). Row 0 is the sky and is not stored:
`read_map_cell` ($E235) returns tile 0 for it. Below the map, tile $20 is
used (rows 29 and 30). Tiles $00, $20, $2A and $A6 all point at an empty
record and fill most of the map: "sky", "solid rock" and "inside a hill" are
the same tile, and only what is already on the screen tells them apart (see
the fills below). Map rows 0-2 hold no landscape at all.

The view straddles at most four cells, two across and two down. Whenever it
crosses into a new cell, `load_map_window` ($DF08) rebuilds the *window*:

| Address | Label | What |
|---|---|---|
| $CE57, $CE58 | `view_column`, `view_row` | the upper-left cell (the view's page) |
| $DDF7 | `right_map_column` | the column to its right, wrapped |
| $DC89 | `map_window_tiles` | four tile-record addresses: the view's cell, below, right, below-right |
| $DC87 | `map_window_pointer` | walks $DC89 as the cells are drawn |
| $DC91-$DC94 | `map_window_tile_bytes` | the four tile numbers (the collision, spawning and beam code read them too) |
| $DC95, $DC96 | `ground_attr_above`, `ground_attr_below` | this planet's two landscape colours |
| $5B80, $5BA5, $5BCA, $5BEF | `loader_entry` (reused), `ground_cell_bottom_left`, `ground_cell_top_right`, `ground_cell_bottom_right` | the four cells' collision-box lists, same order ([landscape-collision.md](landscape-collision.md)) |

During the fly-in (`map_rebuild` $5C3C bit 7), tile $3E is drawn as tile $AA,
two of its six pieces (*read*; why is open).

### Tiles, pieces, steps

`tile_table` ($6C3C) holds 171 words, tile n's record at word n.
`tile_records` ($6D92-$70D7) are read by `draw_landscape`:

| Bytes | Meaning |
|---|---|
| optional $99 | the tile is **upside down**: floors become ceilings. Directions 0-6 swap with 7-13 (and 14 with 15) through `upside_down_table` ($CE14); a flat piece's y is XORed with $0C (4 lines) and its end codes with 1 |
| optional $FF | the tile is **mirrored left-right**: directions through `mirror_table` ($CE04: 1-3 with 4-6, 8-10 with 11-13, 14 with 15); x reflected (complement of x plus the x step plus $0F); a flat piece's end codes swapped and XORed with 2, and the run started from its other end |
| optional byte >= $95 | padding, skipped |
| count | pieces, 0 for an empty tile; at most 7 (the box list's room) |
| per piece: x, y | the piece's start in the page: its lowest point; y counts down from the page's top |
| per piece: direction and steps | high nibble the direction 0-15, low nibble the steps (0 means 16) |
| per flat piece (directions 0 and 7) only: two end codes | `piece_extra_a` ($5C33) for the first step, `piece_extra_b` ($5C34) for the last; see "end caps" below |

The padding rule lets four tiles share one record: a plain record at A is
preceded by $99 (A-1: upside down), $FF $99 (A-2: mirrored; the $99 is now
padding) and $99 $FF $99 (A-3: both). So 72 records serve all 171 tiles: 74
plain (four of them empty), 27 upside down, 51 mirrored, 19 both, and every
byte of $6D92-$70D7 is used but one (*read*, and confirmed by decoding every
record in Python).

Directions and their steps, from `piece_shapes` ($E3BD) by `set_piece_shape`
($E3D8): run in pixels (`piece_dx` $CE35), run in screen bytes
(`piece_dcolumn` $CE36), rise in rows (`piece_rise` $CE37).

| Direction | Shape | Run | Bytes | Rise |
|---|---|---|---|---|
| 0 | flat floor | 24 | 3 | 0 |
| 1 | gentle slope, climbs right | 16 | 2 | 8 |
| 2 | 45 degrees, climbs right | 8 | 1 | 8 |
| 3 | steep, climbs right | 8 | 1 | 16 |
| 4, 5, 6 | 1, 2, 3 climbing left | -16, -8, -8 | -2, -1, -1 | 8, 8, 16 |
| 7-13 | 0-6 as ceilings (rock above, sky below) | as 0-6 | | |
| 14, 15 | a wall, stepping right / left | 0 | +1 / -1 | 16 |

Directions 7 and up use the record seven lower and set `piece_ceiling`
($5C35) to $80. `direction_flag` ($E41B) is $FF for a piece stepping right, 1
for one stepping left, and the same routine patches a JR in
`landscape_step_loop` ($D319) to match. A piece is a chained line: the
pieces of a tile meet end to end, and tiles meet at their edges (tile 1's
flat run, gentle slope and 45-degree slope end where tile 2 starts).

### Graphics: nine stored, four shifts, three variants

Each direction has, per fine-scroll shift, a blitter and a graphic: four
tables of 16 four-byte entries, `piece_blitters_shift0` ($E37D),
`piece_blitters_shift2` ($E2BD), `piece_blitters_shift4` ($E2FD),
`piece_blitters_shift6` ($E33D).
`draw_landscape` picks one by `origin_x` ($CE41) AND 7 into `shift_table`
($CCBD).

- **Bottom row first, zig-zag.** The blitters climb the screen with `DEC H` and
  each POP fetches two bytes, so a graphic is stored exactly as written: the
  bottom row left to right, the row above right to left, and so on up. They fix
  the screen address up for crossing a character row only after each row *pair*
  (`blit_flat_step` $E24D: the first `DEC H` of a pair has no fix-up), so a
  pair must never start on the top line of a character row: a step's bottom
  line has to be odd, and every bottom line in the landscape is (*read*; the
  decoded tiles checked for the Graphics page).
- **Three variants.** Each graphic holds three versions of its step one above
  the other (9 or 17 rows each for slopes and the wall, 4 for a flat step).
  `column_varieties` ($CE24) is a fixed jumble of 0, 1 and 2, walked one a
  step; `graphic_offsets` ($CCBF, six bytes per shape, unshifted and shifted
  interleaved) turns the variety into an offset into the graphic. A long flat
  run therefore shows three stretches of texture in no visible order.
- **Only nine graphics stored** ($E581-$E749, about 460 bytes): the two flat
  pieces (floor `flat_piece_gfx` $E581, ceiling `flat_piece_two_gfx` $E5D7),
  slopes 1-3, their ceilings 8-10, and the wall `wall_gfx` ($EC60). A step
  climbing left is its partner's graphic *started one row later* and drawn by
  a blitter that mirrors every byte through `bit_reverse_table` ($F900, `LD
  C,E / LD A,(BC)` with B = $F9). Because of the zig-zag, starting a row
  later makes every row's bytes arrive in the opposite order; reversing each
  byte's bits finishes the mirror. A mirrored shifted step uses the
  partner's graphic at the opposite shift (climbing left at 2 = climbing right
  at 6, mirrored).
- **The flat steps also carry four end caps** after their three variants
  (offset $24 + 12n), drawn instead of a variant at a run's ends.
- **Shifted at start-up.** `build_shift_tables` ($F86B) makes six pages at
  $FA00-$FFFF: for shifts 2, 4 and 6, page $FA/$FC/$FE + n is n shifted right
  and the next page the bits that fall off, at the top of the byte. Then
  `build_shifted_pieces` ($F7EB) makes each graphic's copies shifted by 2, 4
  and 6 (`slope_2_shifted` $E74A to `slope_10_shifted` $EFB1, about 2.4K, zeros
  on the tape): `shift_slope_piece` ($F939) makes a slope one byte wider and
  pads the open side of each row with the checker's bits ($55 on rows made left
  to right, $AA on the others), on the right for floors and the left for
  ceilings; `shift_flat_piece` ($F8E2) *rotates* the flat rows instead (the
  flat ground tiles every 24 pixels), so they stay three bytes wide. Finally
  `build_bit_reverse` ($F856) writes the reversal table over the routines that
  are now dead. Only the first 12 rows of each flat copy -- its three variants
  -- are made; the other 16, the four end caps, came on the tape already
  shifted (*simulated*), presumably because a cap does not tile and would not
  survive the rotation (*assumed*).

### One pass of drawing

```
play loop $F46C -> ship_pass $C374 (steps) -> JP scroll_landscape $DDF8
  move origins and view, wrap into new cells        (see "Scrolling" below)
  crossed a cell: load_map_window $DF08, set_landscape_colours $DEE1
  update_ground_objects $AC60 first if the landscape moves up
  draw_landscape $D0BD                              (not in map rows 0-2)
    shift table; for each cell 0-3 (ground_cell $5C1D):
      tile record: markers, count; for each piece:
        load_piece_steps $CD08 -> set_piece_shape $E3D8
        piece_ends $CD6B: end codes, mirroring
        collision box, while record_ground $5C3D    ([landscape-collision.md])
        whole piece off the view?  $D292/$D2C0 across, $D2DA/$D2E1 down -> next
        landscape_step_loop $D319, per step:
          advance; cull the step; edge-exact cases -> $CE5B / $CEDB
          first drawn step: IY = blitter, $CE47 = graphic, screen address
          flat -> flat_step_clip $D588; slope -> $D464 / $D4CB
          draw_step $D672: SP = graphic; trim rows past the top/bottom
            patched JR -> step_dispatch $D703: JP (IY) or an edge blitter
              blitter ... JP after_step_drawn $D711 (HL = next step)
        after the last step: SP = stack_top $5B7A
          lip $D86A; fills $E41C / $D8DA / $D9A8; colour_piece $CF38
  update_ground_objects $AC60 now if it did not run first
  draw_beams $9BDA, draw_stars $BFE3; JP draw_ship $C3E3
```

**Coordinates.** Screen x = page x + `origin_x` ($CE41) for the left cells,
+ $E0 more for the right (8-bit sums, so a screen x of $F0 or more is "off
the left"). Screen y = page y + `origin_y` ($CE42) for the lower cells, and
$A0 less for the upper (`draw_landscape` adds $60 for cell 0 and
`after_step_drawn` $A0 back for cell 1). Each piece's state lives in
`current_piece` ($DEDC: screen x and y of the first step, steps drawn,
direction).

**A trap for anyone drawing a view by hand.** `draw_landscape` decides whether
a piece can be seen from the piece's collision box in its cell's list ($5B80
and on: `piece_off_left_edge` and its three partners read the box), and it
writes that box only while `record_ground` ($5C3D) is set, when the window has
just been rebuilt. A view put in place by poking the map position and the
origins draws nothing -- every piece is tested against stale or empty boxes --
until a pass with `map_rebuild` ($5C3C) set has filled the lists (*read*; met
drawing the world in SkoolKit's simulator for the pages, *run*).

**The stack.** Interrupts are off for the whole game, so the blitters borrow
SP freely; instead of saving it, `after_step_drawn` reloads SP from the fixed
`stack_top` ($5B7A) after each piece. That works only because the landscape
is always reached at the same depth -- the play loop's CALL to `ship_pass`,
its PUSH IY, and the CALL to `draw_landscape` -- and the fly-in reaches it at
the same depth too (*read*).

### The blitters, and clipping by patched jumps

Every blitter is entered with A = row pairs, HL = the screen address less
the step's byte advance, SP = the graphic, and ends `JP $D711` with HL where
the next step starts -- so consecutive steps need no address arithmetic.
Each row pair is POP, write, sideways, write; up a row; POP, write back the
other way; up a row with the character-row fix-up (`DEC H`; if that crossed
a cell, L - $20 and, unless that crossed a third, H + 8).

| Blitter | Width | Used for | T-states per row pair |
|---|---|---|---|
| `blit_flat_step` $E24D | 3 | flat floor and ceiling at every shift | about 170 |
| `blit_one` $E48B | 1 | slopes 2, 3, 9, 10 at shift 0; wall 14 one instruction on | about 75 |
| `blit_two` $E4CF | 2 | slope 1/8 at shift 0; 1-byte slopes shifted; wall shifted | about 105 |
| `blit_three` $E4A7 | 3 | slope 1/8 shifted | about 125 |
| `blit_mirror_one` $E55B | 1 | 5, 6, 12, 13 at shift 0; wall 15 | |
| `blit_mirror_two` $E52C | 2 | 4/11 at shift 0; 5, 6, 12, 13 shifted; wall 15 shifted | about 150 |
| `blit_mirror_three` $E4F1 | 3 | 4/11 shifted | |

(Counted from the instruction timings, not measured. The mirror lookups cost
about 40 T-states a row pair more.) A whole flat step is about 400 T-states
-- less than the deciding done for it in `landscape_step_loop` and
`flat_step_clip`.

**Clipping at the sides** is done by patching jump displacements, never by
per-byte tests:

- The flat blitter has three patchable JRs in its loop ($E259, $E25D, $E261)
  and two on its cut path. `flat_step_clip` ($D588) resets them and patches
  by the step's start column: start in column 0 or 31 sends the first JR to
  `flat_blit_left_edge` ($E28E), which skips one or two graphic bytes with
  `INC SP` and repatches the first JR so later row pairs go straight to the
  cut path; columns 27-29 send the third JR to `flat_blit_left_two` ($E289,
  two columns), 28-30 the second to `flat_blit_one_column` ($E283). The cut
  paths still POP the bytes they do not write, so SP stays in step.
- Sloped steps choose among five jumps at `step_dispatch` ($D703) through a
  JR at the end of `draw_step` whose displacement is 0, 2, 5, 8 or 11: the
  step's own blitter, or one of four clipping blitters with their own patched
  JRs -- `blit_right_clip` ($DB89), `blit_mirrored_right_clip` ($DC47),
  `blit_left_clip` ($DBB7), `blit_mirrored_left_clip` ($DBFD). They keep one
  or two columns, skip graphic bytes with `INC SP`, and POP the rest away.
- **Top and bottom** are clipped in `draw_step` before the dispatch: rows
  below line $B7 are popped away (the step's width in POPs per row pair) and
  drawing starts at $B7; rows above $18 are dropped from the count, and a
  slope is cut short there, since pieces only climb.
- A whole piece wholly outside the view is skipped by its collision box
  before any step is walked; a step exactly on an edge goes to
  `column_clipped` ($CE5B) or `edge_column` ($CEDB), which set `edge_flags`
  ($5C31) and count it without drawing.

### Why the screen is never cleared, and what is filled

Nothing clears the play area. The sky is black and the inside of the ground
is the checker $55/$AA, and both are unchanged by a move of 2 pixels across
or 2 rows up or down: that is why every scroll step is 2 pixels (or 4, two
steps at once). Most of the play area is therefore already right after a
move, and only the strips a moving edge uncovers are painted, at the end of
each piece in `after_step_drawn`:

- **Up or down** (`scroll_down` $CCBA, size in `vertical_step_size` $CE3F):
  `fill_behind_moving_piece` ($D9A8) walks the piece's drawn steps from the
  first (`first_step_x` $CE55) and paints the 2 or 4 rows just below each step
  (landscape moving up) or just above (moving down), with `fill_two_rows`
  ($DB41) or `fill_four_rows` ($DB49) through `fill_row_pair` ($DB5B), clipped
  to columns 1-28 and lines $18-$B7. The pattern is the checker ($55AA) or
  black, chosen by the scroll's sign XOR the ceiling flag. A flat piece is
  filled as one strip as wide as its steps, adjusted for its end caps by
  `landscape_end_pieces` ($8347).
- **Across** (`scroll_across` $CCBB): a shifted step is drawn one byte wider
  than its run, so it covers its own old place -- except when the fine
  position comes back to a byte boundary and every step moves into the next
  byte column. Only then (`origin_x` AND 7 = 0) the column left behind is
  filled: by `fill_under_slope` ($E41C) for a slope, one byte-wide column a
  step, as tall as the step, checker or black by the scroll's direction, the
  piece's direction and the ceiling flag; by `fill_flat_end_column` ($D8DA)
  for the drop at an end of a flat run.
- **End caps** on flat runs (bit 4 of an end code: act on it; low two bits:
  one of four cap graphics; $16: only the first column; odd: a drop at that
  end; $13 at the right: a one-byte lip from `floor_lip_bytes` $D851 or
  `ceiling_lip_bytes` $D85E, drawn by `draw_flat_end_lip` $D86A). The values
  seen in the data are $00, $10, $11, $12, $13 and $16.

Because only the edges repair what lies behind them, the play area has to
start in a known state, and the fly-in is what gets it there.

### Colour

`colour_piece` ($CF38) colours a column of attribute cells per step (1-3
cells wide, `colour_one_cell` $D04F, `colour_two_cells` $D063,
`colour_three_cells` $D082), moving up by the rise and across by the column
step; a flat piece three cells wide and about two deep. Only play-area cells
are touched (`in_play_area` $CF14, rows 3-22, columns 1-28). The colour is
`map_row_colour` ($5C3A) for the upper cells and `map_row_colour_next`
($5C3B) for the lower, set by `set_landscape_colours` ($DEE1) from the
planet's pair in `planet_ground_colours` ($DC97, five pairs, copied to $DC95
and $DC96 by `start_landscape` $DCA1): the first colour above map row 12, the
second from row 12 down -- the caverns. Where the surface meets the caverns
(map row $0B below, $0C above) the deeper colour is used, or the upper one for
a piece starting above y $67. Planet 0's pair is bright magenta, then yellow
on black (the "olive checker" seen live in stage 0).

### Scrolling: the origins and the window moving

`scroll_landscape` ($DDF8) is jumped to at the end of `ship_pass` with this
pass's steps in `scroll_down` ($CCBA, signed, up positive) and
`scroll_across` ($CCBB). It adds the steps to the origins and takes them from
the view's in-page edges, `view_x` ($CE45 = 8 - `origin_x`, the view's page x
at the play area's left edge) and `view_y` ($CE46 = $B7 - `origin_y`, the
lower page's y at the play area's bottom line, one less than the view's
page's y at its top). When an edge position leaves its page it wraps by a
page -- $B7/$17 and origin 0/$A0 vertically, $E8/$08 and origin $20/0
across -- and the map row or column moves by one; the wraps are counted into
`record_ground` ($5C3D), which makes `load_map_window` rebuild the window and
`draw_landscape` record the new pages' collision boxes. Ship physics keeps a
step at 2 or 4, and a 4 only from a fine position of 0 or 4 (`speed_to_scroll`
$C81F and the vertical rule in `move_ship` $B234), so the fine position is
always even.

### A life starts: the fly-in, and the restart point

`save_restart_point` ($C33C), every fourth pass, saves the view's cell,
in-page position and origins into the player's record (+$13 to +$18), but
only at a safe place: the bottom pixel row of the play area all checker
($55: over flat ground), or all four window tiles sky (0) or cloud ($A6).
Bit 0 of the saved x says which.

`start_landscape` ($DCA1) uses that place at the start of a life: fuel full,
play area black, planet colours, and the view put one map row *below* the
saved one (same in-page position), the play area first filled with the
checker if it was saved over ground (`start_filled` $DDF2). Then, with
`map_rebuild` at $FF, the view rises 4 rows a pass through
`scroll_landscape` (2 on the first if that brings the origin to a multiple
of 4), the moving edges' fills painting the sky in from the top;
`fly_in_step` ($DD79) ends it when the six bytes at the ship's screen place
are clear, or after 40 passes -- one page, back at the saved place -- when
the area was not filled. One more pass is drawn with `map_rebuild` = 3,
then the window is rebuilt with its objects (`map_rebuild` 0) and play
begins. While `map_rebuild` is non-zero the collision boxes are recorded
every pass, no objects are brought in, and nothing is coloured.

### Ceilings and caverns

The caverns are the map from row 12 down, coloured with the planet's second
colour. Their roofs are ceiling pieces, directions 7-13, which come two ways:
written directly into a tile's record (45 tiles have some), or by turning a
floor tile upside down with $99 (46 tiles, used only in map rows 14-27) --
*read* from a decode of every record and the map. A ceiling step is the same
shape as a floor step, padded with the checker on the other side when shifted,
filled the other way round when scrolling (the ceiling flag flips checker and
black), and its collision box class has bit 7 or bit 3 set. Row $0B is the
surface's lowest row. In stage 0, flying right, the magenta surface was seen to
continue overhead as a ceiling while an olive second ground rose beneath: a
cavern, both scrolling together (*played*). The upside-down path ($D13B) runs
in the build's tours of the deeper map rows.

### Measured costs (stage 0)

| | |
|---|---|
| step | 2 pixels |
| passes | one every two or three frames; about 20 a second |
| landscape cost | about 14,000 T-states a frame (`draw_landscape` and what it calls) |

From 16 consecutive frames of flight right, the ground's edge rows
cross-correlated frame to frame (*measured*); the cost from the emulator's
profiler over two seconds (*measured*).

### For a game of your own

- The world is data the size of a level editor's grid: a byte per page, a
  tile list of pieces, and nine small graphics. A generator should build the
  map, `tile_table` and `tile_records` together (sharing reversed tiles'
  bytes by the marker trick, or not: the engine does not need it).
- Draw everything visible every pass, straight to the screen, but choose a
  background that is invariant under your scroll step (black and a 2-pixel
  checker here) so nothing needs clearing; repair only the strips moving
  edges uncover.
- Pre-shift at start-up into memory that held the start-up code, and keep
  one 256-byte bit-reversal page: with zig-zag storage it halves the slope
  art.
- Clip with patched jump displacements chosen once per step, and let the
  cut paths POP the bytes they skip so SP stays aligned.

## How this was found

Stage 0 (2026-10-16), live in a private `zx_server`, before any listing: a
write watchpoint on one pixel row across the ground's top edge stopped at
$E267, $E26A and $E26C, writing right to left, with $DEB6 (just after `CALL
$D0BD`) on the stack (*watched*); the tables at $E2BD-$E37D were first
printed as bitmaps by mistake -- they are words. The step, the pass rate and
the cost were measured then (above), and a two-minute flight with the
no-damage and no-fuel pokes showed the cliffs, slopes and the cavern.

Stage 2 (2026-10-16): read from the code in the stage 2 description of the
listing (`cyberun.skool`, ranges $D0BD-$E57E and the start-up code); every
tile record decoded in Python with the format read from $D132-$D1A7 and
`piece_ends`, checked by the pieces joining end to end; `build_shift_tables`
run in SkoolKit's simulator on the snapshot and the stored and made graphics
drawn as text to see the zig-zag, the variants and the mirroring; the
code-typed-as-data blitters ($DB89-$DC86, $E48B-$E57E) disassembled and every
self-modified JR followed to its writers.

## Confidence

- *Read*: the map, tile and piece formats (and confirmed by the full decode),
  the window, the dispatch and its patches, the culling, the fills and their
  pattern choice, the colouring, the fly-in, the restart point.
- *Simulated*: the start-up shifting (what it writes, and which flat rows
  came on the tape).
- *Measured* in stage 0: the step, the pass rate, the cost. The blitter costs
  are *counted* from instruction timings.
- *Inferred*: that the checker's invariance is the reason for 2-pixel steps
  (it fits everything, and the listing's `after_step_drawn` says so too).
- Ran in the build's sessions since the staged tours at five depths
  (`cyberun-executed.map`): the upside-down tiles ($D13B), walls ($D20A-$D22C
  and their blitter entries), the left-edge clipping of slopes ($D4E8-$D538,
  $DBB7, $DB89), the mirrored three-byte blitter ($E4F2-$E52B) and the vertical
  fill ($D9D2-$DA00) -- all of `draw_landscape` and its blitters but what
  follows. Never ran, so *read* only: the cells below the map ($DF42-$DF55),
  the map's wrap between columns 95 and 0 ($DF10, $DF16, $E22A, $E231), tile
  $3E's swap during a fly-in ($DF6A), the lip's cut at the play area's bottom
  ($D8BD-$D8C9), `adjust_fill_for_scroll`'s second half ($D9A5), and the first
  instruction of each three-byte blitter ($E4A7, $E4F1), always entered past
  it.

## Corrections

- **The four lists at $5B80, $5BA5, $5BCA and $5BEF.** Stage 0 called them
  "per-strip work areas" chosen by $5C1D. They are the four on-screen pages'
  collision-box lists (the view's page, below, right, below-right), and
  $5C1D (`ground_cell`) is which of the four cells is being drawn. Shown by
  `draw_landscape` writing boxes into them and `find_page_boxes` ($B946)
  reading them.
- **$DC87.** Stage 0: "a list of words, each the address of a strip record".
  It points into `map_window_tiles` ($DC89), the tile records of the four
  cells on screen.
- **The 16-entry tables.** Stage 0 said one entry per "terrain piece type
  (the high nibble of a map byte)". It is one per piece *direction*, the
  high nibble of a piece's third byte in a tile record; a map byte is a tile
  number. (The listing's description of `piece_blitters_shift2` still says
  "map byte".)
- **The markers.** Stage 0 and the first pass of draft 1 had $99 and $FF the
  other way round: $99 turns a tile upside down, $FF mirrors it left-right.
- **Screen cleared?** Stage 0's open question: never; see above.
- **Flat blitter cost.** Draft 8 gave about 125 T-states a row pair for
  `blit_flat_step`; counted again from its loop (three POPs, six writes, the
  three patchable JRs at 12 each, the fix-up and DJNZ) it is about 170, as
  the listing says.
- **`fill_under_slope` "one column a piece".** The listing's description of
  $E41C counts its columns as pieces; B is `piece_steps_done` ($5C2F), the
  steps drawn, so it is one column a *step*, which is how the column left
  behind by every step gets filled.
- **Listing slip:** the descriptions of `draw_landscape` and
  `piece_blitters_shift2` say the chosen table is kept in $CCBA; the code
  stores it in `shift_table` ($CCBD).
- **Coverage.** This file said the upside-down path never ran, and its
  Confidence listed walls, most of the left-edge clipping, the mirrored
  three-byte blitter and parts of the vertical fill as read only. The staged
  tours run them all (`cyberun-executed.map`, 2026-10-17).
- **The flat pieces' shifted rows.** The open question asked why only 12 of
  each flat copy's 28 rows are made at start-up: the 12 are the step's three
  variants, which tile and can be rotated; the 16 that came on the tape are the
  four end caps (*simulated* for the Graphics page).

## Open questions

- Why tile $3E is drawn as tile $AA (two of its six pieces) during the
  fly-in. Tile $3E stands 25 times along map row 12, where the surface meets
  the caverns (decoded from the map); watch a fly-in that starts there.
- What the two bytes `shift_flat_piece` patches after making the flat copies
  ($EB34, $EC30) mend. Compare the simulated copy with the tape's rows.
- What the extra stored row of each sloped graphic is for (rows stored are
  rise + 1, rows drawn are rise).
- Why "$FF $99" tiles exist, i.e. why the >= $95 skip rather than simply
  pointing a mirrored tile two bytes back -- perhaps only to let all four
  variants share one record.
- The top clip in `fill_under_slope` ($E442-$E454) runs in the build's tours
  but was not traced; `adjust_fill_for_scroll` ($D990)'s second half looks dead
  (it needs a step of -128).
- Why a sloped piece gets a column fill when there is no horizontal scroll
  ($D741 makes up a direction from the piece's own).
- What exactly the edge-exact handlers ($CE5B, $CEDB) buy over plain
  clipping.
