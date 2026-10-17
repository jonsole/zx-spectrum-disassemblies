# The rocket and the ore: the game's goal

**Question this answers:** what the player has to do to finish a planet --
where the rocket's parts are, how they are carried and delivered, what the
ore is for -- and what happens at the launch and after.

**Short answer:** build a rocket of eight parts at a fixed place (page
column $52, row 10). The parts lie at places dealt at random to each player
at a new game; with the hook fitted (add-on 1) the ship picks up only the
part due next, carries it hanging below, and lets it go over the rocket's
place, where it falls into its slot. Part 6 is an ore tank and must first
be filled with 18 units of ore, mined from ore deposits with the special
beam. With all eight built, the ship flies into the rocket; it docks, the
rocket rises off the top of the screen, and the planet is secured: 50,000
points and the next of five planets -- the same landscape in new colours,
with six parts already standing and the empty tank aboard.

## How it works

### The parts

`rocket_part_frames` ($AF7B), type $1E's frame list, by appearance: 0 a
section of bars, 1 a checked section, 2 and 3 crate-like sections, 4 and 5
fins, 6 the ore tank (`rocket_tank_graphic` $76E9), 7 the nose cone; frame 8
the tank full (`rocket_tank_full_graphic` $7745).

`rocket_part_table` ($96B0), five bytes a part in delivery order: the
flags and drawn x and line that `draw_rocket` keeps between passes, then the
part's offset from the base (`rocket_x` $96AC, `rocket_y` $96AE: pixel $68
of column $52, line $73 of row 10). The Y offsets are 0, -9, -18, -34, -30,
-30, -47, -63 and X 0 except part 4 (14 left) and part 5 (22 right): a
stack with a fin either side.

### Where they are: the dealing

At a new game `new_game` ($F3BD) calls `deal_places` ($6113) for each player
record (`score` $F5E7 and `other_player_record` $F650). It walks
`dealing_list` ($61A9) and writes 19 four-byte places into the record from
+$1D (`player_places` $F604): map column, map row, x and y within the cell.

The pool (`place_pool_kind3` $605B and on) has five groups, one for each
value in the list; within a group the places are in column order. A value
of 1-5 deals a place at random from that group, (random AND (size-1)) times
4, retrying while it is taken, so the group sizes are powers of two; 0 deals
nothing ($FF, no place) -- unless the next value is 3, when it copies the
place before it, 16 right and 35 up (*read*):

| Places | Value | Group (size) | What lies there |
|---|---|---|---|
| 0 | 1 | $609B (16) | add-on 1, the hook |
| 1, 2 | 0 | none | add-ons 2 and 3 never lie anywhere |
| 3, 4 | 5 | $60DB (2) | add-ons 4 and 5, the two jets: one place each, in random order |
| 5, 7 | 2 | $60E3 (8, the first and third never dealt) | add-ons 6 and 8 |
| 6, 8, 9 | 1 | $609B (16) | add-on 7, add-on 9, the slab (kind 9) |
| 10 | 0, then 3 | copy of place 9 | the spire (kind 10), beside the slab |
| 11-17 | 3 | $605B (16) | rocket parts 0-6 |
| 18 | 4 | $6103 (4) | rocket part 7, the nose |

The pool is freed at the start of each call, so the two players' worlds are
dealt independently and may coincide. As the view moves, `load_map_window`
($DF08) puts any of the current player's places lying in the view's four
cells, not yet taken (bit 7 of the place's first byte), into the two
pick-up records (`pickup_record` $A873, `second_pickup_record` $A88D):
places 0-10 as kind $0C (an add-on: graphic = the add-on's picture), 11-18
as kind $1E (a rocket part, numbered 0-7 in +$13). So at most two pick-ups
show at once ([world-and-objects-in-it.md](world-and-objects-in-it.md) has
the bringing in). **For a new game** the pool and the dealing list are level
data to be generated with the map.

### Picking a part up

`collect_pickup` ($AAD7), for each pick-up record every pass: drawn last
pass, between line $28 and the bottom and x $30-$90, touching a box 16
pixels wide from x $70, the ship's height less ten (the hook's reach under
the middle of the ship). A rocket part is taken only with add-on 1 fitted
(`addon_slots` $F5EE) and only if it is the part due next: its number
against `parts_built` ($F602). Then 1000 points, `sound_pick_up`, its
place marked taken (+$49 of the record, `place_eleven` $F630, onwards), the
part number in `rocket_part_carried` ($F601) and $C0 + part in
`part_being_fitted` ($C904), which makes `draw_ship` hang it below the hook
(`toggle_carried_part` $AA37: the part's graphic XORed into the bottom rows
of the ship's picture, five rows more) -- see [ship.md](ship.md).

### Delivering it

`drop_part` ($9724), each pass from `draw_ship`, carrying a part: when the
ship's place (`view_page_column` $C8E6, `view_page_x` $C8E7,
`view_page_row` $C8E9) is column $52, x exactly $5C, row 10 or above, the
part is let go -- but part 6 only when the tank holds 18 ore (`ore` $C905).
`find_record_for_part` ($97BD) takes an object record; the part becomes a
type $1E object at column $52 x $68, the ship's height, falling with the
ship's own vertical speed reversed and a slight downward acceleration,
flashing white, marked shot (it cannot be hit), with its stopping place
(row 10, line $73 plus its Y offset) in +$15/+$16. The tank falls with
frame 8 (full), and `ore` and `ore_kept` ($F600) are emptied.
`rocket_part_carried` := $FF.

`update_rocket_part` ($9524, a routine the first code map took for data, the
last word of `object_handlers`) lets it fall without testing the landscape; at
its place it is freed -- as soon as it is in its row with its line at or below
its slot's, so a part let go no higher than its slot is freed at once, without
falling (*read*, and *run* in SkoolKit's simulator for the Animations page) --
`parts_built` goes up by one and the player scores 1500. Touching it only
pushes the ship (effect $10).

### Drawing the rocket

`draw_rocket` ($9572), first thing in `update_ground_objects` each pass,
only while the view is in columns $51-$52 and rows 9-10 (or during the
launch): every delivered part is drawn in turn through the one record
`rocket_record` ($9A4C), its position the base plus the part's offset, its
flags and drawn place copied in from `rocket_part_table` and back out after
(so last pass's picture can be rubbed out). Part 6 is drawn with frame 8.
Half the number of parts, rounded up, goes into the load
(`rocket_parts_load` $8D3C), since drawing them costs.

### Ore

- **Where:** ground objects of graphic $0D, kinds 8, 9 and $0A (pictures that
  look like rubble). The world holds 24 deposits, 9, 5 and 10 of them (*read*,
  by counting `map_object_kinds` $5C94): 34 units in all, for a tank of 18.
- **Mining:** only the special beam (add-on 7) touches ground objects
  ([weapons.md](weapons.md)). `beam_hits_ground_object` ($ABA8) dissolves a
  deposit it hits, marks it gone for this player and writes its kind into
  the beam's record; when the beam has gone, `draw_shot` jumps to
  `load_ore` ($A8A5), which adds 1 unit (kinds 8 and 9) or 2 ($0A), at most
  18 -- and only while the part carried is 6, the tank. One firing mines one
  deposit's worth, the last it hit. The tough attacker, destroyed by the
  special beam once worn down, also gives 1 or 2 units.
- **Showing it:** `load_ore`'s tail draws the ore into bytes 2 and 3 of the
  bottom rows of the ship's picture, one row of `ore_rows_graphic` ($7721)
  a unit, so the tank hanging below the ship fills as it is mined.
  `colour_ship` ($F1BD) turns the ship yellow at 18.
- **Delivering it:** the tank is hung as frame 6 and let go as frame 8, the
  full tank, XORed out of the picture; frame 8 is not quite frame 6 with 18
  rows of ore -- its top row lacks one pixel the ore's top row has -- so one
  pixel stays in the picture (row 12, byte 3) until it is next built (*watched*
  in SkoolKit's simulator for the reference pages).
- **Keeping it:** `lose_life` ($F4C6) keeps the ore in the record
  (`ore_kept` $F600), and `play` puts it back at the next life.

### Docking and the launch

With all eight parts built, `draw_rocket` waits for the ship at column $52,
x $5C, row 10, line $63 or lower -- inside the rocket. Then:

```
draw_rocket $9572
  launch_state $96AB := non-zero
  death_count $8F53 := 10 for two calls   draw_ship_image and draw_trail erase the ship
  death_count := 0                          (docking, not a death)
  carried_part, the ship's X speed 0, a sound
each pass after:
  ship_contact, beam_hits_ship: nothing touches the ship
  read_controls: nothing read; move_ship: thrust at the fast climb to page row 0
  draw_rocket: the base rises at the view's vertical scroll (4 lines a pass
               in page row 0); lift_jet drawn at the rocket's height; sound_launch
  part 0 no longer drawn (its flags' bit 7 clear): launch_state := $FF
play $F440: launch_state $FF -> level_done $F52A
```

The death byte is back to 0 before `update_objects` next looks at it, so
the docking does not start `wreck_ship` or `sound_death` ($72AB): the 10 is
only for `draw_ship_image` and `draw_trail`, which erase the ship at 10.

In the staged launch for the Animations page (*run*) the launch took about 390
passes: the rocket kept its place on the screen while the view climbed from
page row 10 to row 0, its base moving up by the view's own scroll each pass,
and then rose 4 lines a pass off the top.

### The end of a level

`level_done` ($F52A): clear the play area, `planet_secured` ($83D6), the
level tune (`level_tune` $F56A), a wait, clear again, clear
`player_flag_bits` ($F5EA, the flickering beams' generators), and back to
`play` for the next life on the new planet.

`planet_secured`:

- prints the planet-secured screen: a few lines of congratulation with the
  finished planet's name, then the next planet's (five names of 16
  characters at `planet_names` $8459, in the game's character codes);
- counts `level` ($F5F9, +$12) on, the fifth coming round to the first;
- resets the rocket's base;
- sets `rocket_part_carried` and `parts_built` to 6;
- adds ten times 5000 to the score, each with a zap and a pause;
- deals the last place again (`deal_places`'s second entry, from
  `dealing_list_last` $61BB into `place_last` $F64C): the nose cone moves
  to a new place in its group;
- clears this player's "gone" bit in all 290 world objects
  (`mask_world_objects` $9A8A with $7F for player 1, $BF for player 2,
  worked out from `player_in_play` $CA1C), so every ground object --
  deposits, pads, generators -- is back.

So the next planet starts with parts 0-5 standing in the rocket, the empty
tank hanging below the ship, and part 7 somewhere new: fill the tank,
deliver it, fetch the nose, dock. `level` is read only for the planet's
colours (`planet_ground_colours` $DC97, in `start_landscape`) and its name:
**every planet is the same map** (*read*). After the fifth the first comes
round again; the game has no end but the last life.

## How this was found

Read from the code in the stage 2 description of the listing (2026-10-16):
stage 0's "$96AB ends the loop another way" led to `draw_rocket`, whose
position constants matched `drop_part`'s; `update_rocket_part` was found as
the type $1E word of `object_handlers`; the dealing from `deal_places` and
the pool decoded from the snapshot; the planet-to-planet hand-over from
`planet_secured`'s two stores of 6 and its re-deal. The ore deposits were
counted from `map_object_kinds` in the listing.

## Confidence

All *read*. Since the staged sessions (the launch, and part 0 and the full ore
tank delivered) most of it runs in the build (`cyberun-executed.map`):
`drop_part`, `update_rocket_part`, `draw_rocket`, `toggle_carried_part`,
`deal_places`, the docking, the launch, `level_done` and `planet_secured`.
Never ran: the part-taking path of `collect_pickup` ($AAE3-$AAEE, $AB4A-$AB5C:
the deliveries start with the part already aboard), `find_record_for_part` past
the first record it looks at ($97CB-$97DE: record 0 was always free),
`load_ore`'s loading ($A8AA-$A8D7: no session mined) and the wrap from the
fifth planet to the first ($83F9). The names of the parts and of the rocket
itself are inferences from pictures and behaviour (eight stacked pieces that
fly up off the screen).

## Corrections

- Stage 0 ([damage-fuel-lives.md](damage-fuel-lives.md)) took the store of
  10 into the death byte at $968D for a stage's end or a death; it is the
  docking, undone two calls later. `launch_state` ($96AB) is the launch.
- Draft 3 read `rocket_part_carried` ($F601) as "parts carried"; it is the
  one part carried, $FF none. The listing still calls `parts_built` ($F602)
  "a second byte about the rocket's parts ... not yet worked out": it is the
  number delivered, which is also the part due next.
- Draft 8 asked why the end of a level sets the carried part to 6: the next
  planet starts with six parts built and the tank aboard.
- The listing's `sound_death` and draft 2 say docking plays the death
  sound, the byte being set "straight to 10". `draw_rocket` puts it back to
  0 within the same call, before `update_objects` (the only caller of
  `sound_death`) runs, so it cannot (*read*).
- Draft 4 called kinds 9 and $0A "the two pieces of a part let go"; they
  are the slab and spire load ([ship.md](ship.md)), not rocket parts.
- **Coverage** (2026-10-17): this file said almost none of it ran in the
  build's sessions -- `drop_part`, `update_rocket_part`, `draw_rocket` and the
  launch never, only `planet_secured`'s printing. The staged launch and
  deliveries run all of those; what still never ran is listed above.
- **`find_record_for_part`.** The first batch of these notes said it never ran
  past "its first free record"; the instructions never run are its step past
  record 0, which was always free.

## Open questions

- What `load_ore`'s clearing loop was meant to do: it moves DE up a line but
  writes through HL, so it clears the same two bytes every time. The reference
  pages' staged load answers whether the picture is left dirty: a two-unit load
  leaves the second new row showing the empty tank's pixels and the ore's
  together until the ship turns (*watched*).
- Whether the docking test (line $63 or lower, x exactly $5C) is hard to
  meet in play: steps are 2 pixels, so x $5C is reachable, but only from an
  even position.
- Whether anything happens on a planet past the fifth beyond the colours
  coming round again.
