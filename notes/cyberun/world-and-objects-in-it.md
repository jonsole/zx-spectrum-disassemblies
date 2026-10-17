# The things lying in the world

**Question this answers:** how the objects at fixed places in the landscape
-- installations, ore deposits, refuel pads, add-ons and rocket parts lying
on the planet -- are stored, how they are brought on screen as the view
moves and freed when they leave, and how each player's "gone" marks are
kept.

**Short answer:** 290 objects in three parallel tables sorted by map column:
a kind byte each (`map_object_kinds` $5C94), two packed position bytes each
(`map_object_places` $5E17) and a count per column (`map_objects_per_column`
$5DB6). Whenever the view crosses into a new map cell, `load_map_window`
($DF08) frees the object slots whose objects have left the 2x2 window and
`spawn_column_objects` ($E08F) brings in the objects of the window's two
columns and two rows into four slots at `ground_objects` ($A80B). The
pick-ups are separate: each player is dealt 19 places at random at a new
game, kept in the player's record and brought into two more slots. A taken
or destroyed object is marked in its kind byte -- bit 7 for player 1, bit 6
for player 2 -- and never comes back until a new game or the next planet.

## How it works

### The tables

| Address | Label | Size | Per object |
|---|---|---|---|
| $5C94 | `map_object_kinds` | 290 | bits 0-5 the kind (0-16); bit 7 gone for player 1; bit 6 gone for player 2 |
| $5DB6 | `map_objects_per_column` | 96 + 1 | the number of objects in each map column; the 97th repeats column 0's for the wrap from 95 |
| $5E17 | `map_object_places` | 290 x 2 | byte 0: bits 2-7 the y in the page plus one, bits 0-1 bits 3-4 of the x; byte 1: bits 5-7 bits 5-7 of the x, bits 0-4 the map row (1-28) |

The objects are in map-column order, so column C's first object is the sum
of the counts of the columns before it. The tables abut ($5C94 + 290 =
$5DB6, $5E17 + 580 = $605B) and the counts add up to exactly 290 (*read*,
and checked in Python). Positions are on an 8-pixel grid across (x 8 to 208)
and a 4-line grid down (y 39 to 183). They are level data: a generator should
sort the objects by column, count them per column (repeating column 0's
count at the end), and pack each position into the two bytes above.

By kind, the 290 are 12 of kind 0, 9 of 1, 33 of 2, 6 of 3 (the mounds that
throw bullets, the shield ball and extra lives), 48 of 4, 23 of 5, 18 each of 6
and 7, 24 ore deposits (9, 5 and 10 of kinds 8, 9 and $0A, 34 units), 14 of
$0B, 10 of $0C, 22 of $0D, 18 refuel pads (kind $0E), 20 of $0F and 15 of $10;
and the map has 76 cells of tile $A6, the flickering beams' (*read*, counted
from the snapshot; the reference pages' Facts agree).

### The slots

Six records of 26 bytes at `ground_objects` ($A80B): four for the map's
objects, then `pickup_record` ($A873) and `second_pickup_record` ($A88D) for
the pick-ups (bit 7 of +3 set). The first $18 bytes are laid out as the sky
objects' records, and the same routines place and draw both
([sprites.md](sprites.md)). Six records of 26 bytes are 156, but `load_ore`
($A8A5) starts 154 bytes on: the second pick-up record's +$18 and +$19 are its
first instruction. Latent: those two bytes are a ground object's number in
$5C94, given only to the first four records and read only for objects that are
not pick-ups (*read*, as the reference pages' Bugs page has it).

| Offset | Field |
|---|---|
| +0 | graphic number: $0D an ordinary object, $1B an animated one, $0C an add-on lying on the planet, $1E a rocket part; $FF free |
| +1, +2 | page column, x in the page |
| +3 | bit 7: a pick-up |
| +4, +5 | page row, y of the bottom line in the page |
| +$0D | two colours, shown on alternate passes |
| +$10 | bit 7 drawn last pass, bit 6 drawn straddling the left edge, bit 4 rub out and free |
| +$11, +$12 | screen x and y it was drawn at |
| +$13 | bits 0-3 the frame -- for a graphic-$0D object also its kind; bits 4-7 the animation count |
| +$14 | the frame range (high nibble first, low last), for an animated object |
| +$15 | bit 7: animate it (`animate_object` $910A) |
| +$17 | bit 3 dissolving, bits 0-2 the step |
| +$18 | bits 1-3 the kind of shot it fires (0 none); bit 0 with +$19 the object's number, its byte in $5C94 |

The last record runs two bytes into the code at `load_ore` ($A8A5): its
+$18/+$19 are only read for objects that are not pick-ups, and it is a
pick-up slot.

### Bringing objects in

```
scroll_landscape $DDF8: a page edge crossed -> load_map_window $DF08
  the four tile numbers and records (see landscape.md)
  (nothing more while the view is being built, map_rebuild $5C3C)
  drop_far_objects $E062 on the two pick-up slots
  the current player's 19 places (player_places $F604):
     skip if gone (bit 7) or not in the window's columns and rows,
     or already in a pick-up slot (same_item_in_slot $E03D);
     else into the first pick-up slot if free, otherwise the second:
     places 0-10 as graphic $0C (an add-on) with +$13 = the place number,
     places 11-18 as graphic $1E (a rocket part) with +$13 = 0-7; colours $FF
  drop_far_objects $E062 on the four ground slots
  JP spawn_column_objects $E08F
    first object = sum of the counts before view_column $CE57 (to $CE3A)
    counts of this column and the next: left_column_objects $DDF5,
      right_column_objects $DDF6
    spawn_objects_from_list $E114: this column, then right_map_column $DDF7
      (back to object 0 when that wraps to column 0)
    slots still free: +$10 cleared
```

`spawn_objects_from_list` ($E114), for each object of a column: skip it if
its gone bit is set for the current player, if its map row is neither the
view's row nor the next, or if a slot already holds it (same column and row);
otherwise take the first free of the first three slots -- the fourth if none
is, whatever it holds -- clear it (`free_object` $AC34), and fill it:

- graphic $0D, +$13 the kind, +$0D the kind's colours from
  `object_kind_bytes` ($E205, one byte per kind);
- +$18 from `object_kind_flags` ($E0FD, one byte per kind): its bits 5-7
  become the shot kind in +$18 bits 1-3 (six of the seventeen kinds fire;
  `ground_object_fires` $8820 does the firing);
- if that byte's bit 4 is set, the object is animated instead: graphic $1B,
  +$13 and +$14 a frame byte and a frame range from `object_part_pairs`
  ($E10E, at the offset in the byte's low nibble), and +$15 = $80 so it
  animates between two frames (a lamp, a domed robot, the fuel station);
- the object's number into +$18 bit 0 and +$19, and its column, x and y
  unpacked from the two position bytes.

The cost is a sum of up to 95 counts, made only when the view crosses into
a new cell -- never per pass.

### Freeing objects that leave

Two ways. When the window moves, `drop_far_objects` ($E062) frees any slot
whose column is neither of the window's two columns or whose row is neither
of its two rows. And every pass, `place_on_screen` ($ADD8) frees an object
that has left the two pages the view spans, while an object still in range
but not in sight is simply not drawn that pass
([sprites.md](sprites.md)). Nothing is lost by freeing: the object's byte in
$5C94 and its position are still in the tables, and it is brought in again
the next time the window reaches it.

### Gone, per player

Taking or destroying an object sets its gone bit in $5C94, found again from
+$18 bit 0 and +$19: `ship_hits_ground_objects` ($A8F4) when a refuel pad is
used up, `beam_hits_ground_object` ($ABA8) when the special beam destroys
one. Which bit is the current player's is decided once a life by `play`
($F440): it patches the test in `spawn_objects_from_list` ($E117, the opcode
byte at $E118: `BIT 7,(HL)` for player 1, `BIT 6,(HL)` for player 2) and the
two `SET` instructions ($A9B8, $ABDE) to match. So one table serves both
players with no other code knowing which is playing.

`mask_world_objects` ($9A8A) ANDs all 290 bytes with a mask: $3F at a new
game (`new_game` $F3BD: everything back for both players), and at the end of
a planet (`planet_secured` $83D6) a mask worked out from `player_in_play`
($CA1C): $7F for player 1, $BF for player 2, so only the current player's
objects come back. The five planets share the one map and these tables;
what changes between them is the landscape's colours
(`planet_ground_colours` $DC97) and one re-dealt pick-up place (below).

### The pick-ups' places

The pick-ups are not in the tables above. At a new game `deal_places`
($6113) deals each player 19 places from the pool (`place_pool_kind3` $605B
and the groups after it: 46 places of four bytes -- map column, map row, x, y
-- in five groups), following `dealing_list` ($61A9): each entry 1-5 deals a
random place not yet dealt from that group (the random byte `random_a`
$9BCB, stirred by `random` $F23B); an entry of 0 deals nothing, leaving the
four bytes $FF (no place), unless the next entry is 3, when it copies the
place before it 16 to the right and 35 up. The places go into the player's
record from +$1D (`player_places` $F604 for the player in play,
`other_player_record` $F650 for the other). Every pool place is free again at
each call, so the two players may be dealt the same places. At the end of a
planet the last place is dealt again from its group (`dealing_list_last`
$61BB into `place_last` $F64C).

The first eleven places are the add-ons lying on the planet: place n shows
add-on n + 1's graphic (`addon_graphics` $AF95). Places 1 and 2 are never
dealt (add-on 2 always comes with add-on 1). Places 9 and 10 are the pair --
the second placed 16 right and 35 up of the first -- because they are the
two pieces of the part the ship carries in two pieces (`carried_part` $C1CE,
which lets it go as kinds 9 and 10 at exactly that offset). The last eight
are the rocket parts 0-7. Taking one (`collect_pickup` $AAD7) marks bit 7 of
its place's first byte, in the player's own record: these marks are per
player by construction.

### For a game of your own

- Keep fixed objects in tables sorted by map column with a count per column:
  finding a column's objects is one running sum, and nothing per pass.
- Keep only as many live slots as can be on screen (four here), filled when
  the view crosses a cell boundary and freed when they leave; the tables
  stay the truth.
- One bit per player in each object's byte, with the test and the set
  patched at the start of each life, gives two-player "gone" marks for free.
- Pick-ups dealt at random from a pool per kind give each game different
  places with a fixed level.

## How this was found

Stage 2 (2026-10-16): read from the code in the stage 2 description of the
listing (`cyberun.skool`: `load_map_window`, `spawn_column_objects`,
`spawn_objects_from_list` and its bit unpacking, `deal_places`, `play`,
`mask_world_objects`, `planet_secured`, `collect_pickup`,
`beam_hits_ground_object`, `ship_hits_ground_objects`); the tables decoded
in Python (the counts sum to 290, rows 1-28, x 8-208 in steps of 8, y
39-183; the pool's places in column order, rows 3-$1A). For this note the
patched opcodes at $F452-$F466 were checked against the Z80 encodings ($7E
and $76 are `BIT 7` and `BIT 6,(HL)`; OR $F0 makes `SET`), the end-of-planet
mask worked through for both players, and `object_kind_flags` and
`object_part_pairs` read against the frame lists of graphic $1B.

## Confidence

- *Read*: the tables, the spawning and freeing, the per-player bits, the
  dealing.
- *Read and inferred*: that $E205 holds colours (its bytes go into +$0D,
  which `prepare_draw` uses as the two colours; the values are colour pairs
  such as $EE, $DD, $FF, $CD), and that the $E10E bytes are frame and range
  (they go into +$13 and +$14 with +$15 = $80, which `animate_object` reads
  that way, and the frames they pick are the pairs in graphic $1B's list).
- Never ran in the build's sessions: the cells below the map (no tour went
  deeper than row 22), the wrap from the last object column to object 0
  ($E0CF-$E0D8), the second pick-up record ($DFF4) and the taking of a rocket
  part or the slab ($AAE3-$AAEE, $AB4A-$AB5C, $AB7E-$AB97). The animated
  (graphic $1B) objects ($E1A6-$E1C3) are spawned since the staged tours,
  though no refuel pad was ever used ($A993-$A9C1).
- The game meanings of the kinds are partly known: ore deposits are kinds 8-$0A
  (the special beam sends their ore to the tank), kinds 6 and 7 set their map
  square's bit in the player's record (`map_square_bit` $AC08, which
  `draw_beams` $9BDA tests -- the flickering beams' generators, as draft 3
  reads it), and the refuel pad is the fuel station (graphic $1B, frames 4-5).
  Kind $0B is the one kind the special beam cannot destroy
  (`beam_hits_ground_object` skips it) and the ship never collides with
  (`ship_hits_ground_objects`). The others are named by appearance: kind 1 a
  pedestal, 2 a cloud, $0B a ringed planet, $0F a saucer, $10 a lamp (animated,
  frames 0 and 1, like kind 4), from the pictures drawn for the pages.

## Corrections

- **$5C94 bit 6.** Draft 1 left it unknown and the listing's description
  says bit 6 "is not read anywhere else". It is player 2's gone bit: `play`
  patches the test and the two SETs to bit 6 for player 2.
- **The end-of-planet mask.** The listing's description of $5C94 derives it
  from "the byte $F3BD sets to $99"; it comes from `player_in_play` ($CA1C,
  0 or 1 in play) and clears only the current player's bit.
- **+$0D.** Draft 1 said the colour pair is "chosen at random from the table
  at $E205"; it is one byte per kind, no randomness. The listing's
  description of `object_kind_bytes` ($E205) calls it the contact-effect
  byte; the contact effect is `contact_effect` ($8E2C), and $E205 is the
  colours.
- **"Two-part objects."** The listing's descriptions of `object_kind_flags`
  and `object_part_pairs` read bit 4 as a two-part object and $E10E as the
  two parts' kinds. The two bytes are the animation's frame byte and frame
  range; bit 4 makes an animated graphic-$1B object. For those, +$13 is the
  animated frame, so `ship_hits_ground_objects`' "graphic $1B of kind 4 or
  5" means the fuel station's two frames.
- **Places 9 and 10.** Draft 1 asked why they come as a pair: they are the
  two pieces of the part the ship carries in two pieces.
- **Coverage** (2026-10-17): this file said the animated objects never ran in
  the build's sessions; the staged tours spawn them. The listing's description
  of `object_kind_flags` left kind $10 out of the animated kinds; its flag
  byte, $10, has bit 4 set.

## Open questions

- What the kinds are for in the game: their pictures name them (pedestal,
  cloud, ringed planet, saucer, lamp, robots), but play to a few and watch +$13
  to see what each does.
- Whether the pick-ups' taken marks (bit 7 of a place's first byte) are
  cleared at the end of a planet, or only by the deal at a new game.
- The second pick-up slot is used when the first is busy, even if it is busy
  too; can two pick-ups be in the window at once, and does one then vanish?
