# Drawing objects

**Question this answers:** how Fairlight puts a moving object on the screen
without redrawing the room, and how it decides what is in front of what.

**Short answer:** it rebuilds only the rectangle the object covers (three
rows taller above and below), straight onto the screen, from four 256-byte
pages at $D800-$DBFF and the clean copy of the room at $C000. The object's
own mask goes in page $D9; objects in front of it leave their cover in $D8,
where the screen keeps what it has; objects behind are sorted and drawn,
cover and image, into $DA and $DB. Every one of those drawings is done by
one routine, `DRAW_SPRITE` ($EE8D), which clips, shifts to the pixel through
a patched `JR`, and never touches the screen. Things that never move, and
doors, are drawn once as the room is entered and become part of the clean
copy.

## How it works

`REDRAW_OBJECT` ($ECBD, the author's SRP) is the whole redraw of one
object; `CHE3D` ends every object's update with it (by way of
`REDRAW_THIS_OBJECT`, $F7AA), and the pick-up uses it to rub a thing out.

```
REDRAW_OBJECT $ECBD   copy +0..+11 to $FFE4 on; no sprite: return; clear page $D8
  |                   its mask into $D9 (DRAW_SPRITE mode $80) -- or, if it is carried
  |                   or gone (+16 bit 5) and the room is not being entered, $D9 all set
  |                   so the clean copy shows (it is rubbed out); rectangle +3 rows each way
  +- FAR_CORNER $F036            D, E, C: its far edges along x and z, and its floor
  +- CULL_OBJECT $ED47           each record from the knight's (7) to the last, but itself:
  |    IS_IN_FRONT $EE73 -> in front: its cover into $D8 (mode 0)
  |                      -> behind:   its number onto the list at $DA00
  +- SORT_AND_DRAW_BEHIND $EDC6  only if bit 1 of IY+$71 (something behind):
  |    sort the list; copy it to DRAW_LIST ($FFC6); clear $DA and $DB;
  |    from the back: cover into $DA (mode 4), image into $DB (mode 8)
  +- COMPOSITE_TO_SCREEN $E3E4   each screen byte from the pages and the clean copy
```

**The region and the pages.** The region is the object's screen box: x
(IY+$64), top row (IY+$65), width in pixels (IY+$66), height (IY+$67). Each
page is laid out as that region: rows one byte wider than `DRAW_WIDTH`
(IY+$73), in one 256-byte page (the pointer wraps).

| Page | Holds | Drawn by |
|---|---|---|
| $D8 | The cover (a bit set where something shows) of the objects in front | `DRAW_SPRITE` mode 0, from `CULL_OBJECT` |
| $D9 | The moving object's mask (a bit set where the background shows), shifted, with three rows of $FF above and below | Mode $80, from `REDRAW_OBJECT` |
| $DA | The cover of the objects behind | Mode 4, from `SORT_AND_DRAW_BEHIND` |
| $DB | The image of the objects behind, nearer over farther | Mode 8 (mode 4 first clears its cover out of $DB) |

The compositor's rule, which defines what the pages mean, is in
[`compositing.md`](compositing.md).

**In front or behind.** `IS_IN_FRONT` sets bit 0 of IY+$71 when object IX
is not wholly beyond the other on any axis: its x less than the other's far
x (+6 plus +9), its top above the other's floor (+7 less +10), its z less
than the other's far z (+8 plus +11). Greater x and z are further from the
viewer.

**The sort.** For each place in the list in turn, if any later entry is in
front of the entry there, that entry is moved to the end (the list closes
up) and the place looked at again, at most 50 times a place (IY+$7E) --
which is what stops three objects that each overlap the next from looping
for ever. The list is then drawn from its end back.

**Still things and doors.** An object whose +16 has bits 0-4 clear is still:
`DRAW_STILL_THINGS` ($FE15) draws each one, and each door, as the room is
entered, with bit 4 of `GAME_FLAGS` set, and then `RESTOR` ($F10B) copies
the screen into the clean copy, so they are background
([`entering-rooms.md`](entering-rooms.md)). In an ordinary redraw, still
things behind the moving object are skipped until the first live object in
the drawing order -- the clean copy already shows them -- and drawn after
that, since they must cover it. In the still-things pass, live objects are
left out altogether.

**`DRAW_SPRITE`'s mode** (C): bit 7, mode $80 (the source inverted, so the
zeros the shift brings in mean "nothing covered", and inverted back when
stored); bit 3, mode 8 (the image plane; every other mode takes the mask,
one plane on); bit 2, mode 4 (also clear page $DB under the cover); bit 4
the sprite starts left of the region; bit 5 the first column only primes
the spill; bit 6 no spill column after the last. The shift: 7 less (x mod 8)
goes into the displacement of the `JR` at $EFD0, which jumps into a run of
seven `RRCA`s; the masks for a shifted byte's two halves go into the
operands of the three `AND`s at $EFE3, $EFF4 and $F008. The listing shows
the tape's values of those four bytes.

**The fills** (`CLEAR_256_BELOW` $F04C, `CLEAR_512_BELOW` $F050, and its
entries `CLEAR_BELOW` $F052 and `FILL_BELOW` $F055) push DE with SP
borrowed, filling B x 8 bytes *below* HL: `REDRAW_OBJECT` clears page $D8
with HL at $D900, `SORT_AND_DRAW_BEHIND` clears $DA and $DB with HL at
$DC00. SP is kept in `WORK_HEADING` ($FFF6) meanwhile.

## How this was found

Read (stage 2, ranges 2 and 3) from $ECBD to $F064 with the compositor.
*Measured* in the simulator: a stop at $ED44 (the end of `REDRAW_OBJECT`,
before the compositor) for the knight's record, the four pages rendered with
the region's stride. With the knight 4 less than room 2's state-7 creature
on both x and z, the creature's cover was in $DA and its image in $DB and
$D8 was empty: behind him. With him 16 more on both, its cover was in $D8:
in front. The freeze (bit 7 of `GAME_FLAGS`) kept the creature still while
measuring.

## Confidence

The data flow and the pages: *read*, and *measured* for all four. The
ordering rule: *read*, one arrangement each way *measured*. That the
50-move limit is there to break cycles: *inferred* (nothing else needs it).

## Krumlinde

He traced the blit well -- the patched `JR` into the `RRCA`s, the three
patched masks, the spill column, bit 5 as "prime the carry", bit 2 as
touching the other plane -- and several names here are his (`DRAW_SPRITE`,
`CULL_OBJECT` from his `Cull_TestObject`). Where his reading differs:

- **Which plane each mode draws.** He has mode 4 drawing plane 0 and mode 8
  plane 1. The plane offset is added when bit 3 is *clear*: mode 8 draws
  plane 0, the image, and modes $80, 0 and 4 plane 1, the mask (image then
  mask is stage 1's finding from the sprites themselves).
- **"No known path to the screen" for modes 4 and 8**: the compositor reads
  all four pages ([`compositing.md`](compositing.md)); *measured* above.
- **Mode $80's object "most likely the player"**: it is whichever object is
  redrawn.
- **Page $D8 "the room-descriptor buffer, repurposed"**: it is the cover of
  the objects in front.
- **`IS_IN_FRONT`'s "special case" in the cull** is not special: every
  overlapping object in front goes to $D8 that way.
- **IY+$72 "not otherwise referenced"**: it is `CHE3D`'s copy of +14, which
  `MIRROR` writes the new facing into and the pick-up reads.
- **`RTN_Cull_Sprites`** names one step of `REDRAW_OBJECT`, which is the
  whole redraw of one object; **`RTN_Init_Sprite_Sort`** ($EC75) is the
  panel box's clear and has nothing to do with sorting.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `REDRAW_OBJECT` | `SUBECBD` | $ECBD | The author's SRP |
| `CULL_OBJECT` | `SUBED47` | $ED47 | One object: out of the region, in front, or behind |
| `RECORD_FROM_NUMBER` | `SUBEDB8` | $EDB8 | IX = record number B |
| `RECORD_FROM_NUMBER_STEP` | `SUBEDC1` | $EDC1 | Its loop, split off by the jump into it |
| `SORT_AND_DRAW_BEHIND` | `SUBEDC6` | $EDC6 | Sort the list, draw it into $DA and $DB |
| `IS_IN_FRONT` | `SUBEE73` | $EE73 | The ordering test |
| `DRAW_SPRITE` | `SUBEE8D` | $EE8D | Draw an object into a page (Krumlinde's name) |
| `DRAW_SPRITE_SKIP_COLUMNS` | `SUBEF4E` | $EF4E | Part of it |
| `DRAW_SPRITE_CLIP_LEFT` | `SUBEF53` | $EF53 | Part of it: a sprite left of the region |
| `DRAW_SPRITE_ROWS` | `SUBEF6C` | $EF6C | Part of it: the drawing loop |
| `FAR_CORNER` | `SUBF036` | $F036 | D, E, C for the ordering |
| `CLEAR_256_BELOW` | `SUBF04C` | $F04C | 256 bytes below HL |
| `CLEAR_512_BELOW` | `SUBF050` | $F050 | 512 bytes; `CLEAR_BELOW`, `FILL_BELOW` inside |

## Open questions

- The three rows added above and below: presumably the most a thing moves
  up or down the screen in a pass, so the old image is wiped. Nothing wipes
  more than one byte column sideways; whether a fast sideways mover leaves a
  trail was not tested.
- The list at $DA00 has room for 30 entries (`DRAW_LIST` is 30 bytes) and
  nothing checks; whether a room can put more than 30 objects behind one
  region was not measured (the most records a room made was 37, in room 71).
- `LD HL,$D800` at $EC94 is dead (the compositor loads HL itself): a
  leftover of an earlier version?
