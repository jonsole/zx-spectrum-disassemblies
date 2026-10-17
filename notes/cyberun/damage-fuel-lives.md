# Damage, fuel and lives

**Question this answers:** what hurts the ship and what kills it, how fuel
is burnt and found, how lives are counted and given, and what happens
between the ship's death and the next one.

**Short answer:** two things set the death byte `death_count` ($8F53): a
third hit, and an empty fuel gauge. Hits come from touching attackers,
bullets and rocks, and from the flickering beams; a refuel pad repairs
them and fills the tank, the shield ball keeps them off for about 25
seconds. Fuel burns only while steering or thrusting. Once set, the death
byte counts up a pass at a time: everything explodes, the ship breaks up at
10, the death sequence runs from 12 to $50, and a life is taken from
`lives` ($F5ED), five at a new game, at most nine. Extra lives are thrown up
by the ground, more often the fewer the player has.

## How it works

### Hits

```
ship_contact $8E2D  (contact effect bit 6: attackers $50, rocks $51,
                     bullets, pellets, the dash)
  -> contact_damage $8F54   at most once per 16 passes per object (+$17 cool-down)
       shield up: an attacker ($50/$51) is destroyed instead, with a sound
     -> damage_ship $8F76
beam_hits_ship $9D0E (a flickering beam)  -> damage_ship, then 16 passes' grace
ship_hits_ground_objects $A8F4 (a refuel pad) -> hit_count := $FF -> damage_ship
```

`damage_ship` ($8F76, the second half of `contact_damage`) does nothing
while `shield_timer` ($896F) runs or the ship is already dying. Otherwise a
zap, `hit_count` ($8FC3) up by one, and the panel's ship icon recoloured by
the new count: **0 white ($47), 1 yellow ($46), 2 magenta ($43), 3 black**,
and the third hit sets the death byte to 1. The icon is a 4 by 2 cell patch
(`icon_patch_record` $8FBF, painted by `fill_attributes` $C991) at x $30 for
player 1 and $B0 for player 2 (`player_in_play` $CA1C;
[panel-and-menu.md](panel-and-menu.md) has the panel). The words at
`ship_icon_positions` ($8FBB) hold the same two places but nothing reads
them: the code loads constants. Ground objects never damage the ship; they
are solid, and it bounces off them ([ship.md](ship.md)).

**Repair.** The count of 3 colours the icon black and kills; a count of $FF
wraps to 0 and colours it white. `ship_hits_ground_objects` uses that: a
refuel pad sets `hit_count` to $FF and calls `damage_ship`, so the one
routine both damages and repairs.

### The shield

The shield ball (type $1C frame 9, `shield_ring` $98D8) is thrown up, one throw
in eight, by the spiky mounds that throw bullets (ground kind 3,
[attackers.md](attackers.md)). Its contact effect is $FF: `ship_contact` sets
`shield_timer` to $FF and frees the ball. `ship_pass` ($C374) counts it down on
odd passes: 510 passes, about 25 seconds at 20 passes a second (*computed*; 509
*measured* for the reference pages, the timer set as the pick-up sets it).
While it runs no damage is taken, an attacker that touches the ship dies
instead, and `colour_ship` ($F1BD) paints the ship cyan, flashing in the last
32 counts. Cleared at each life (`reset_for_life` $F311). A refuel pad touched
under the shield does not repair: it sets `hit_count` to $FF and calls
`damage_ship`, which does nothing while the shield is up, so the hits taken
stay, the icon keeps its colour, and the next hit after the shield counts the
$FF on to 0 -- a repair instead of a hit (*read*, and *watched* in SkoolKit's
simulator for the reference pages).

### Fuel

`fuel` ($CC4B), a word whose high byte is the gauge's level as a screen
row: $42 full, $BE empty, 124 steps. Only `add_fuel` ($CC4D) changes it,
keeping it between the two.

| What | Where | Change |
|---|---|---|
| steering or thrusting | `read_controls` $B115 (from $B149) | +8 a pass; +16 for both at once; halved with add-on 6 (`addon_six` $F5F3); halved again while `fuel_saver` ($5C40) is set |
| the refuel pick-up (type $1C frame 3, effect $28) | `contact_refuel` $8FC4 | -$1C00: 28 steps |
| the fuel thief (frame 6, effect $1C) | `contact_drain_fuel` $9015 | +$1000: 16 steps |
| a refuel pad | `ship_hits_ground_objects` $A8F4 | set to $4200, full |
| a new life | `start_landscape` | set full; the gauge refills from empty a row a pass |
| the death sequence | `play` $F440 | set empty ($BE) |

Coasting and falling cost nothing. A full tank is 124 x 256 / 8 = 3,968
passes of steering or thrusting, about three and a third minutes
(*computed*).

The refuel pick-up is thrown straight up by the flasks (ground kind 0); the
fuel thief is sprayed up by a kind of domed robot (kind $0C)
([attackers.md](attackers.md)). The refuel pad is ground kind $0E, an
animated object (graphic $1B, the fuel station's two frames), which
`ship_hits_ground_objects` recognises by graphic $1B with frame 4 or 5. A
pad is
used up by one visit: freed and marked gone in `map_object_kinds` for this
player until the planet is secured or a new game begins. The world has 18
(*read*, counted from the table).

**The gauge** (`update_fuel_gauge` $CC77, each pass): `fuel_shown` ($CC62)
moves one row a pass towards the fuel's level, each step XORing two rows of a
column that is five pixels wide with a three-pixel top, so the gauge is kept up
to date by touching two rows a pass. `flash_fuel_gauge` ($CAA7) turns it red on
two passes in four once the fuel's own level -- the high byte of `fuel`, not
`fuel_shown` -- reaches $98, about seven tenths used, so the flash follows the
fuel and not the column on the gauge (*read*, and *run* in SkoolKit's simulator
for the Animations page).

**Running out** (`check_fuel_empty` $CC63): once the gauge *shows* empty ($BE)
and the ship is alive, the death byte is set to 1 the next time the low seven
bits of `pass_counter` ($9A64) are zero -- up to 128 passes, about six seconds,
of grace. `update_fuel_gauge` runs before `update_objects` in the pass, which
counts the byte on at once, so it is first seen as 2 (*read*, and *run* for the
How it works page). In one run the gauge took 123 passes to show empty and the
grace was 74 passes (*run*).

### Lives

`lives` ($F5ED, +6 of the player record): 5 each at a new game
(`new_game` $F3BD, at $F3CE); one taken by `lose_life` ($F4C6, the
`DEC A` at $F4CF) after the death sequence; at 0 `game_over` ($F4FC), and
`play` then goes back to the menu once neither player has lives. With two
players `lose_life` hands over through `swap_players` ($F591), which swaps
the two 105-byte records so the current one is always at $F5E7. The panel
shows lives less one (`print_lives` $CA31): the ship in play is not
counted.

**Extra lives** (`contact_extra_life` $9020): the ship-icon pick-up (type
$1C frame 8, effect $1A) adds one, to at most 9, with a sound and the
panel redrawn. It is thrown by the same mounds that throw bullets, every
(lives x 4)th bullet throw (`extra_life_countdown` $896E): one throw in
twenty with five lives, one in four with one -- the game helps a player who
is losing (*read*; never seen).

The ore aboard survives a death: `lose_life` keeps it in `ore_kept`
($F600) and `play` restores it ([rocket-and-ore.md](rocket-and-ore.md)).

### The death byte and the death sequence

`death_count` ($8F53): 0 while alive. Set to 1 by the third hit or the empty
gauge, then counted up a pass by `update_objects` ($8D42):

| Death byte | What happens |
|---|---|
| 1-3 | every object starts exploding (+$17 bit 3) |
| not 0 | nothing touches the ship (`ship_contact`), nothing new spawns (`find_free_record` $87F6), no damage, no fuel death |
| 10 | `wreck_ship` ($8CB2): the ship breaks into four debris and five falling pieces ([attackers.md](attackers.md)) |
| 10-$2C | `sound_death` ($72AB) each pass: a warble, a zap on every eighth count, clicks on the other odd ones |
| $0B on | `ship_pass` no longer moves the ship |
| 12 | the play loop (`play`, at $F46C) goes to the death sequence ($F48B) |
| $50 | the sequence ends |

The wreck comes on the pass the byte reaches 10: nine passes after an
attacker's hit sets it (in `update_objects`, after the count) and eight after a
beam's hit or an empty gauge does (both before it). In a run for the Animations
page it appeared nine passes after the byte was set (*run*). The death
sequence: the landscape stops (`scroll_down` cleared), the fuel is set empty,
part of `draw_ship` runs once and `lift_jet` ($C6D2) erases the lift jet; then
a shorter loop -- `ship_pass`, `check_pause` ($9F4E), the gauge,
`update_objects`, `carried_part`, the gauge again -- until the byte reaches
$50, about 70 passes (some three and a half seconds). Then `death_tune`
($F4DD), the play area dissolved to black and cleared (`dissolve_and_clear`),
`lose_life`, and round to `play` ([main-loop.md](main-loop.md)), whose
`reset_for_life` clears the death byte, the hit count, the shield and the
launch state for the next ship, which starts at the restart point
([ship.md](ship.md)).

The store of 10 by `draw_rocket` when the ship docks with the finished
rocket is not a death: it lasts two calls and is undone before
`update_objects` sees it ([rocket-and-ore.md](rocket-and-ore.md)).

## How this was found

Stage 0 (2026-10-16), live in a private `zx_server`: memory diffed across a
death for bytes that fell by one -- the only one read by game code was
`lives` (4 to 3 across the respawn, *watched*); the code changing it led to
the death sequence, the death byte and the two places that set it. In an
untouched run the hit count rose and the ship died on the third hit
(*watched*). With hits poked off, a long run still died: a watchpoint on
the death byte stopped at $CC73 in `check_fuel_empty` with the gauge empty
(*watched*), which led to the fuel word and the burn. Stage 2 (2026-10-16)
read the rest from the listing: the colours, the repair, the shield, the
pick-ups, the extra-life rule and the death byte's steps.

## Confidence

The third-hit death, the fuel death and the lives *watched* at stage 0; the
rest *read*. Never ran in the build's sessions: the refuel pad's repair
($A993-$A9C3), the fuel thief and the extra life ($9015, $9020), the shield's
start ($8E94) and its destroying an attacker ($8F68-$8F75). The refuel pick-up
($8FC4) runs since the staged sessions. The times in seconds assume 20 passes a
second (stage 0 measured a pass every two or three frames).

## Corrections

Stage 0's version of this file said otherwise in these places:

- **The hit colours** were given as white, yellow, magenta. The count is
  incremented before the colour is chosen: yellow, magenta, then black on
  the third hit; white is the repair (count 0). And it is the panel's ship
  icon that changes colour, not the ship. Shown by reading `damage_ship`.
- **"Hits -- $8F76, reached from $A9BE (CALL) and $9D22 (JP)"**: $A9BE is the
  refuel pad's repair, not a hit. Hits reach `damage_ship` by falling
  through from `contact_damage` ($8F54) and from `beam_hits_ship` ($9D22).
- **"What `$896F` is: a shield after a respawn, or the demo?"** It is the
  shield picked up from the shield ball; it is cleared, not set, at a
  respawn.
- **"What gives fuel ($8FC4) and what takes $1000 ($9015)"**: the refuel
  pick-up thrown by the flasks, and the fuel thief thrown by domed robots.
- **"The event at $968D"**, a store of 10 into the death byte that stage 0
  thought might be a stage's end: it is the docking with the finished
  rocket, undone at once.
- Stage 0's [pokes.md](pokes.md) is right but for its infinite-lives poke,
  `POKE 62671,0`, which sends every death to `game_over` (corrected there); the
  routines are named there now.
- **Coverage** (2026-10-17): this file's Confidence listed the refuel pick-up
  as never run; the staged sessions run it (`cyberun-executed.map`).
- **The gauge's red flash** was said to come once "the level" reaches $98,
  which could be read as the level shown. `flash_fuel_gauge` compares the
  fuel's high byte, so it follows the fuel itself.
- **The wreck's timing.** The first batch of these notes said only "nine passes
  after the byte was set"; that holds for an attacker's hit. A beam's hit or an
  empty gauge sets the byte before `update_objects` counts it, so the byte is
  first seen as 2 and the wreck comes eight passes later.

## Open questions

- How often refuel pads and flasks are met on a normal route, against the
  burn of about three minutes a tank: a played session would say whether
  fuel is the real limit.
- The death sequence's length in frames was not measured.
