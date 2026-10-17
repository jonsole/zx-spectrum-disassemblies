# Cyberun -- overview

**Start here.** A tour of what is worth knowing about how Cyberun works,
a short section per subject, each ending in the note that goes into it.
Everything here is *read* from the listing unless it says otherwise.

## The game in one paragraph

A ship flies over and under the surface of a planet, a world of 96 by 28
screens that wraps round from east to west. Eight parts of a rocket lie
about it, at places dealt at random to each player. The ship picks them up
one at a time, in order, and drops each over the rocket's place. One part
is an ore tank that must first be filled by mining ore with a special beam.
With the rocket built, the ship docks, the rocket lifts off and the planet
is secured -- and the next planet is the same landscape in new colours. On
the way the ship gathers add-ons that change how it flies and fights, and
burns fuel whenever it steers or thrusts.
[rocket-and-ore.md](rocket-and-ore.md)

## The landscape: redrawn every pass, never scrolled

The thing Cyberun is known for. The screen is never scrolled in memory:
every pass the landscape of the up to four screens the view straddles is
drawn again, straight onto the screen, from tile records -- each a short
list of straight runs of a sloped or flat step -- with POP blitters and
graphics pre-shifted for 0, 2, 4 and 6 pixels. Only nine graphics are
stored for the 16 piece directions at four shifts: a ceiling is a tile
marked upside down, a left-climbing slope is the right-climbing graphic
read a row later through a bit-reversal table, and the shifted copies are
built at start-up by code that is then overwritten. The background is
never cleared at all: black sky and the ground's checker look the same
after a 2-pixel move, so only the strip a moving edge uncovers is painted.
That is why the scroll steps by 2.
[landscape.md](landscape.md)

## Collision with the landscape: boxes per screen

While a screen is first drawn, each piece also writes a 5-byte box into
that screen's list. A moving thing's box is placed where its speed would
take it, cut into the parts that lie in each screen, and tested against the
boxes. Floors, ceilings and walls reverse and halve the speed into them;
slopes reflect it, 45-degree ones by swapping the two speeds, the others by
mixing them in eighths. The ship's bouncing off hillsides is all this.
[landscape-collision.md](landscape-collision.md)

## Sprites without masks

Objects are drawn by a compositor: the screen rectangle under the old and
new images is copied into a small buffer, the old image rubbed out there,
the new one drawn in, and the rectangle copied back -- one write to the
screen, so nothing flickers, and no masks at all. The ship has a drawer of
its own that rubs out and redraws row by row straight on the screen,
mirrored through the bit-reversal table when it faces left; and the ship's
picture itself is rebuilt in RAM from the add-ons it carries.
[sprites.md](sprites.md)

## The ship never moves

The ship stays where it is on the screen; its speed becomes the world's
scroll. Thrust or gravity, a push across and a drag, all in 256ths of a
2-pixel step a pass, with the constants in one small table. Add-ons double
its speed or its climb, halve its fuel burn, add a special beam or
missiles, or a lift jet that lets it climb out of the sky's ceiling.
[ship.md](ship.md), [weapons.md](weapons.md)

## Objects, attackers and things in the world

Nine 24-byte records fly in the sky, each typed, with its update routine
from a table; what touching one does is a byte of effect bits (damage,
push, refuel, collect, drain fuel, extra life, destroy, shield). Attackers
spawn out of sight at fixed points per tile and accelerate towards the
view. On the ground lie 290 fixed objects in tables sorted by map column,
brought in and freed as the view moves, each remembered as gone per player.
Ground objects throw bullets and pick-ups; extra lives are thrown more
often the fewer lives the player has.
[objects.md](objects.md), [attackers.md](attackers.md),
[world-and-objects-in-it.md](world-and-objects-in-it.md)

## Damage, fuel and dying

Three hits kill (the panel's ship icon changes colour with each), and so
does an empty tank, after a grace of up to 128 passes. A refuel pad both
fills the tank and repairs the ship -- by setting the hit count to $FF so
that the damage routine wraps it to zero. A shield pick-up keeps hits off
for about 25 seconds.
[damage-fuel-lives.md](damage-fuel-lives.md)

## The frame of the game

No interrupts, no frame sync: a pass takes as long as its work, two or
three frames. Two players never need to know which one is playing -- their
whole 105-byte records are swapped at each turn, and the one shared table
(the objects in the world) gets its per-player bit by patching the BIT and
SET instructions that test it.
[main-loop.md](main-loop.md), [players.md](players.md),
[panel-and-menu.md](panel-and-menu.md), [sound.md](sound.md),
[input.md](input.md)

## Loading and memory

The game block is moved down 512 bytes and nibble-shifted back into shape
by its own loader. Then the start builds six pages of shift tables over the
loader's leftovers and a bit-reversal table and a sprite buffer over its
own start-up code.
[loading.md](loading.md), [memory-map.md](memory-map.md)

## Bugs and quirks found so far

- On a 128K in 128 mode the `OUT ($FD),A` before every keyboard read pages
  memory: the menu's $7F pages RAM bank 7 in at $C000 and locks the paging, and
  the game crashes on the menu's first pass (*watched* in SkoolKit's 128K
  memory for the reference pages). A ten-byte poke takes out the five OUTs that
  can do it ([input.md](input.md), [pokes.md](pokes.md)).
- Every planet is the same map: only the colours and the name change
  ([rocket-and-ore.md](rocket-and-ore.md)).
- A load of two units of ore leaves pixels on the tank until the ship turns,
  because the ore-loading routine's clearing loop writes the same two bytes
  each time; and the full tank's picture is not quite the empty tank with 18
  rows of ore, so delivering it leaves one pixel behind
  ([rocket-and-ore.md](rocket-and-ore.md), *watched* in the simulator).
- A refuel pad touched under the shield leaves the hit count at $FF, so the
  hits are not repaired and the next hit after the shield is a repair
  ([damage-fuel-lives.md](damage-fuel-lives.md), *watched* in the simulator).
- Add-on 9 draws one row past the ship's 300-byte picture, into six bytes
  nothing else uses; and the second pick-up record runs two bytes into
  `load_ore` -- both harmless ([sprites.md](sprites.md),
  [world-and-objects-in-it.md](world-and-objects-in-it.md)).
- Not a bug, though an earlier reading said so: the missiles' target table
  ranks the attackers by their points ([weapons.md](weapons.md)).

## Pokes

No damage, no fuel used, infinite lives (`POKE 62671,183`; stage 0's `POKE
62671,0` keeps the lives but sends every death to the game-over screen), a 128K
poke and others, each tested. [pokes.md](pokes.md)
