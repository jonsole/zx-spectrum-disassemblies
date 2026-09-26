# Depth order: how the scene is redrawn and sorted

**Question this answers:** How does Knight Lore decide which objects to redraw
each frame, and in what order, so that nearer things cover farther ones?

**Short answer:** Every object is an axis-aligned box. An object that moves
marks every object whose screen rectangle overlaps the union of its old and new
rectangles; those are the only ones redrawn. The marked objects are then drawn
by a repeated "find one with nothing undrawn behind it" search, where "behind"
is decided per pair by classifying the two boxes on each of X, Y and Z as
separated one way, overlapping, or separated the other way, and looking the
27 combinations up in a table at `$CF69`.

## How it works

### Geometry the sort relies on

An object record (32 bytes at `$5C08 + 32*n`) holds, among other things:

| Offset | Field |
|---|---|
| +$00 | type (0 = empty record, 1 = delete when next drawn) |
| +$01, +$02 | X and Y of the box's centre |
| +$03 | Z of the box's base |
| +$04, +$05 | half-size along X and along Y |
| +$06 | height, upwards from the base |
| +$07 | flags: bit 1 ignored by collision tests, bit 4 redraw this frame, bit 5 wipe this frame, bit 6 mirror the sprite, bit 7 turn it upside down |
| +$12, +$13 | pixel offset of the sprite from the projected point |
| +$18, +$19 | sprite size on screen now: width in bytes, height in pixel rows |
| +$1A, +$1B | pixel x, and pixel row counted up from the bottom |
| +$1C..+$1F | +$18..+$1B as they were at the start of this frame |

The projection (`calc_pixel_XY`, `$D6C9`, not in this range) is
x = X + Y - 128 + adj, row = (Y - X + 128)/2 + Z - 104 + adj, with rows
counted from the bottom (`calc_vram_addr` complements the row). So +X goes down
and right on the screen, +Y up and right, +Z up, and a step of (+1, -1, +1) in
(X, Y, Z) does not move the projected point at all: that is the direction
towards the viewer. "Further back" therefore means smaller X, larger Y, lower Z.

### Per object, during the update pass

```
update_sprite_loop ($AFC7)
  save_2d_info ($CE49)            +$18..+$1B -> +$1C..+$1F  (last frame's rectangle)
  handler for the type
    ... moves the object ...
    set_wipe_and_draw_flags ($C692)     sets bits 4 and 5 of +$07
      set_draw_objs_overlapped ($CD4D)
        calc_2d_info ($CD33)            new +$1A/+$1B (projection) and +$18/+$19 (size)
        union of old and new rectangle  E = first column, D = width in columns,
                                        L = bottom row, H = height in rows
        test_overlap_obj ($CD9B) x 40   any live object whose current rectangle
                                        overlaps the union gets bit 4 of +$07
```

The rectangles are in byte columns horizontally (a sprite not on a byte
boundary is counted one byte wider) and pixel rows vertically. An object's
own record is among the forty, so it is marked too. The player's head
(`upd_player_top`, `$CDE2`) copies the legs' flags, including bits 4 and 5,
so it is wiped and redrawn with them, and then runs the same marking for its
own rectangle.

Marking goes one level only: an object redrawn because it overlaps the mover
does not mark the objects that overlap *it*.

When an object's sprite is the empty one (types 0 and 1 use `spr_nul`, whose
header is 0), `flip_sprite` pops `calc_2d_info`'s return address and returns
to its caller, so the size bytes stay as they were -- a vanishing object's
union still covers where it was.

### At the end of the frame

```
end_of_frame ($B000)
  list_objects_to_draw ($CE62)    indices of live objects with bit 4 -> $CE8B, $FF-terminated
  render_dynamic_objects ($D59F)  (not in this range)
    for each listed object with bit 5: clear the union of +$1C.. and +$18.. in the
    screen buffer, and remember the window to copy to the screen
    calc_display_order_and_render ($CEBB)
  ... copy the remembered windows to the screen
```

A room's first frame (`$5BB7` set by `build_screen_objects`) skips the wiping:
the buffer was cleared when the room was built, every room object's data
sets bit 4, so the whole room goes through the same sort, and the whole buffer
is then copied.

### The sort (`calc_display_order_and_render`, `$CEBB`)

```
$5BBE = 0
pass:     candidate IX = first entry of $CE8B without bit 7      ($CEC3/$CEC6)
          none left -> done ($D015)
compare:  for each other entry without bit 7 (IY)               ($CEDB)
            C = Zcode + Ycode + Xcode ; jump through $CF69
              "IY first"   -> $CFA5: if IY already in chain ($D01A) -> draw IY ($CFCE)
                                     else add IY to chain, IX = IY, compare again from the top
              "coincide"   -> $CFE1: a collectable (types 96-102) in the pair is destroyed
              otherwise    -> next IY
          end of list -> draw IX ($D000/$D003): set bit 7 of its entry, empty the chain,
                         $5BBE += 1, calc_pixel_XY_and_render ($D704), next pass
```

Because every entry before the first undrawn one is drawn, the first candidate
of a pass is compared only with the entries after it; after a switch the new
candidate is compared with the whole list. `$5BCD` and `$5BCF` hold the
list pointers just past the candidate's and IY's entries.

The three codes, with all arithmetic 8-bit unsigned and "at or beyond"
meaning no borrow from the final subtraction (so touching boxes count as
separated):

| Axis | 0 | middle | high |
|---|---|---|---|
| Z (C += ) | 0: IX.z >= IY.z + IY.h (candidate wholly above) | 1: overlap | 2: IY.z >= IX.z + IX.h (IY wholly above) |
| Y (C += ) | 0: IX.y - IX.d >= IY.y + IY.d (candidate wholly further back) | 3: overlap | 6: IY.y - IY.d >= IX.y + IX.d (IY wholly further back) |
| X (C += ) | 0: IX.x - IX.w >= IY.x + IY.w (IY wholly further back) | 9: overlap | 18: IY.x - IY.w >= IX.x + IX.w (candidate wholly further back) |

(w, d, h are +$04, +$05, +$06.) The table at `$CF69`, laid out by Z code:

```
Z0: candidate above      X0 (IY back)   X9 (overlap)   X18 (cand back)
    Y0 (cand back)       free           free           free
    Y3 (overlap)         IY first       IY first       free
    Y6 (IY back)         IY first       IY first       free
Z1: overlap in height
    Y0                   free           cand first     cand first
    Y3                   IY first       COINCIDE       cand first
    Y6                   IY first       IY first       free
Z2: IY above
    Y0                   free           cand first     cand first
    Y3                   free           cand first     cand first
    Y6                   free           free           free
```

"IY first" (`iy_goes_first`, `$CFA5`) is exactly: on every axis IY is further
back than the candidate or overlapping it, and strictly further back on at
least one. "cand first" (`candidate_already_first`, `$CFA2`) is the mirror
image, and "free" (`order_unconstrained`, `$CF9F`) is every case where each
box is in front of the other on some axis. The last two are both a bare
`JP $CEDB`; the table only names them differently.

The "free" cases are safe, not a shortcut: since (+1, -1, +1) is the
direction of view, two boxes that are separated with opposite senses on two
axes cannot both be crossed by one line of sight, so their pictures cannot
overlap and their order does not matter. The table is the exact occlusion rule
for boxes under this projection. What it cannot handle is a cycle -- three or
more boxes each partly behind the next -- and boxes that interpenetrate (index
13).

**Cycles.** `$D01A` (renamed `candidate_chain`) holds the indices made
candidate since the last draw. If an object that must go first is already in
it, the order has looped, and that object is drawn at once. The pass's first
candidate is not recorded, so a loop back to it is caught one link later. The
chain has room for seven indices and the terminator and nothing checks it.

**Interpenetrating boxes.** Index 13 (`objs_coincide`, `$CFE1`) imposes no
order. If the candidate, or failing that IY, is one of the seven collectable
objects (types 96 to 102), it becomes type 187, whose handler (`$BF37`) zeroes
its entry in the special object table -- removing it from the game -- and sets
type 1, so it is deleted when next drawn.

**Pacing.** `$5BBE` counts objects drawn (and `render_dynamic_objects` adds the
windows copied); `end_of_frame` delays for (6 - `$5BBE`) units, so a frame with
little to draw is padded out.

## How this was found

Read from the listing: `$CD33`-`$CE8A` and `$CEBB`-`$D021` in full, plus
`calc_pixel_XY`, `flip_sprite`, `calc_pixel_XY_and_render`, `print_sprite`'s
header handling, `calc_vidbuf_addr`/`calc_vram_addr` (for which way rows
count), `render_dynamic_objects`, the main loop and `end_of_frame`, and the
collision tests at `$CC9D`-`$CCD7` (which confirm X/Y are centres with
half-sizes and Z a base with a height). The 27 table entries were decoded by
hand into (Z, Y, X) codes; the "IY first" set turned out to be exactly
{X0, X9} x {Y3, Y6} x {Z0, Z1} minus the all-overlap case.

## Confidence

Everything above is read from the code except: the claim that "free" pairs
cannot overlap on screen, which is worked out from the projection formula
(sound for the formula as written; the per-sprite pixel offsets at +$12/+$13
and sprite artwork that spills outside its box are not accounted for); and
the consequence of one-level marking (see open questions), which is inferred.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| store_2d_size | loc_CD43 | $CD43 | tail of calc_2d_info: store width and height |
| union_right_edge | loc_CD6C | $CD6C | union rectangle: right edge |
| union_width_bottom | loc_CD7A | $CD7A | union rectangle: width, lower edge |
| union_top_edge | loc_CD87 | $CD87 | union rectangle: top edge |
| union_height | loc_CD99 | $CD99 | union rectangle: height |
| overlap_x_decided | loc_CDB3 | $CDB3 | overlap test: horizontal verdict |
| overlap_y_decided | loc_CDBC | $CDBC | overlap test: vertical verdict, mark |
| obj_starts_left | loc_CDCC | $CDCC | overlap test: object starts left of union |
| obj_starts_below | loc_CDD3 | $CDD3 | overlap test: object starts below union |
| head_follows_legs | loc_CDEF | $CDEF | copy legs' position and flags to the head |
| choose_head_sprite | loc_CE14 | $CE14 | legs type + 16, or a random idle head frame |
| head_on_shoulders | loc_CE27 | $CE27 | head Z = legs Z + 12, mark overlaps |
| head_frame_six | loc_CE33 | $CE33 | idle head frame 6 |
| hold_head_frame | loc_CE3A | $CE3A | start the eight-frame hold |
| head_frame_seven | loc_CE40 | $CE40 | idle head frame 7 |
| list_test_obj | loc_CE72 | $CE72 | draw list: test one object |
| list_next_obj | loc_CE80 | $CE80 | draw list: next object |
| skip_drawn_entries | loc_CEC6 | $CEC6 | sort: find first undrawn entry |
| compare_next_obj | loc_CEDB | $CEDB | sort: compare candidate with next object; Z code |
| z_code_overlap | loc_CF15 | $CF15 | sort: Z code 1 |
| compare_along_y | loc_CF16 | $CF16 | sort: Y code |
| add_y_code | loc_CF39 | $CF39 | sort: add 3 |
| compare_along_x | loc_CF3C | $CF3C | sort: X code |
| add_x_code | loc_CF5F | $CF5F | sort: add 9 |
| act_on_comparison | loc_CF62 | $CF62 | sort: dispatch through the table |
| depth_order_tbl | off_CF69 | $CF69 | the 27-entry ordering table |
| order_unconstrained | continue_1 | $CF9F | pair needs no order |
| candidate_already_first | continue_2 | $CFA2 | candidate is behind; nothing to do |
| iy_goes_first | d_3467121516 | $CFA5 | IY is behind: switch candidate (tcdev's name listed the table indices) |
| search_chain | loc_CFAD | $CFAD | look for IY in the candidate chain |
| iy_becomes_candidate | loc_CFB8 | $CFB8 | append to chain, switch, rescan |
| break_order_cycle | loc_CFCE | $CFCE | cycle found: draw IY now |
| find_iy_entry | loc_CFD1 | $CFD1 | find IY's list entry and draw it |
| check_iy_collectable | loc_CFF0 | $CFF0 | coincide: is IY a collectable? |
| coincide_done | loc_CFFD | $CFFD | coincide: carry on |
| candidate_chain | render_list | $D01A | not a list of things to render but the chain of candidates, for cycle detection |
| plyr_redraw_copy_xy | copy_spr_1_xy_2 | $D34D | old name ended in _digit, and the routine also sets both redraw flags |

The input, lives and room renames are listed under those subjects.

## Open questions

- Can a real room produce a candidate chain longer than seven? If so the
  terminator lands on the first byte of `check_user_input` (`$D022`). Not
  measured.
- One-level marking: if A moves, B overlaps A's union and is redrawn, and C
  overlaps B but not A's union and is in front of B, B's full sprite is drawn
  over C without C being redrawn. Whether this shows in play (or whether room
  design avoids it) has not been tested.
- The candidate chain lookup in `break_order_cycle` re-finds an entry that
  `$5BCF - 1` already addresses; its "not found" exit looks unreachable.
