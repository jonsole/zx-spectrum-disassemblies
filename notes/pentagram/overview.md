# Pentagram -- overview

A tour of the findings. Each section is a summary; the link has the routines,
the addresses, how it was found and what is still open.

## Knight Lore's engine, edited

Most of Pentagram is Knight Lore's code: the renderer, the depth sort, the
collision code, the player's movement, the arches, picking up, the text and
the tune player, often instruction for instruction -- with Knight Lore's
leftovers still in it: a directional-control mode no menu choice selects, a
menu line's flashing with no line to flash, the tests for sounds that were
taken out. What is new is firing and scoring, things falling from the sky, a
quest table that follows its things from room to room, and a map made of
doorway bytes instead of a grid. [`knight-lore.md`](knight-lore.md),
[`leftovers.md`](leftovers.md)

## Everything is an object record, and the graphic is the behaviour

54 records of 32 bytes: the player's legs and body, two bolts, two things
from the sky and 48 for the room. The graphic number picks both the sprite
and the update routine, so a thing animates -- or turns into something else,
a rough stone into a pillar, a bolt into a puff -- by changing its own
graphic. Most of the 172 numbers run a routine that only sets a drawing
nudge. [`object-records.md`](object-records.md),
[`graphic-numbers.md`](graphic-numbers.md)

## A turn, and an even speed

`START` is three loops: a life, a room, a turn. A turn runs every record's
update routine, then redraws what changed and waits six units less the
drawing work it has done, so a quiet room runs no faster than one where six
things change; a busier one runs slower. The random number is stirred with R
after every object, so it depends on how long each update took.
[`main-loop.md`](main-loop.md)

## Drawing only what changed

A mover marks everything its old and new pictures touch; at the end of the
turn those areas are cleared in an off-screen buffer, the marked objects
drawn into it back to front through their masks, and only those areas copied
to the screen. Sprites are shared and turned in place to face the way each
object wants. The draw list is still Knight Lore's 48 bytes for 54 records --
whether a turn can overflow it is open.
[`drawing.md`](drawing.md), [`depth-order.md`](depth-order.md)

## Collision, and the platforms it makes

A move is cut one axis at a time, Z, U, V, a unit at a time, which lets a
blocked diagonal slide along a wall. Harm passes both ways through two bits.
The player's "mobile" flag makes him hand his Z step to what he lands on and
ride what moves under him -- which is all a sinking block, a lift or a pacing
block needs. Pentagram adds conveyors, which push what stands on them two
units every other turn, and a "stood on" mark for lifts and crumbling blocks.
[`collision.md`](collision.md), [`movers.md`](movers.md)

## The player

Rotational control only: turn a quarter, walk 3 units a turn the way he
faces, jump at 8 a turn with gravity taking 2 (1 while jump is held on the
way up). Four facings stored in two bits, the mirror bit and bit 2 of the
graphic; a four-frame walk with a footstep every fourth step. His legs are
his whole collision box; the body just follows. [`player.md`](player.md),
[`input.md`](input.md)

## Doorways are a table

Each doorway's scenery entry carries the room it leads to, so the rooms are
linked by bytes, not numbered on a grid. The arch's first pillar decides the
exit from his position after his move; he arrives in the facing doorway of
the new room, lined up with its arch, and his records are saved there so a
lost life restarts at the doorway he came in by. All 290 doorways are
answered by one back, and all were walked through with the game's own code
at build time (*measured*).
[`doorways-and-rooms.md`](doorways-and-rooms.md),
[`room-building.md`](room-building.md),
[`lives-and-starting.md`](lives-and-starting.md)

## A world that does not fit on a plan

139 rooms, 116 square and 23 narrow corridors. Placed by their doorways they
make a grid of 19 by 18 in which every loop closes -- except three small
groups that land on the same squares as other rooms. Three wells, four quest
items, the pentagram in room 82, and something deadly in 92 rooms.
[`world.md`](world.md)

## The quest, and records that follow their things

Shoot a well until it gives a bucket (32 turns of a bolt touching it, in
one visit); carry the bucket to each of four quest items, where it flies over
the item and finishes it, with a life added; then the pentagram appears in
room 82 and the five collectables, carried there, glide to their places --
the fifth wins. The quest's 18 things live in their own records, copied into
a room when he enters and back when he leaves, so they stay where they were
put. [`quest.md`](quest.md), [`quest-records.md`](quest-records.md),
[`carrying.md`](carrying.md)

## Shooting, and a timer bug

Bolts can hit only the two things from the sky, and that is the only way to
score: the points are three digits made from the thing's graphic number.
Things fall in rooms without the well, a quest item or a pentagram piece,
when a timer runs out -- meant to depend on the quest items left, but a
register never added makes it 80 turns until the first item is done and 8
after (*measured*). Homers, most of what falls, fly at the player but do not
kill. [`bolts-and-sky.md`](bolts-and-sky.md)

## The percentage, and 56 for nothing

Rooms seen halved (at most 54), 4 per quest item, 6 per collectable: 100 at
most. Counted into BCD by a DJNZ, so a sum of 0 shows 56 per cent -- a player
who never leaves the first room is told he is more than half done
(*measured*). [`percentage.md`](percentage.md)

## The menu, the panel, the end screens

One list printer for all the text, a spare object record for all the fixed
pictures. The winning screen names the next Sabreman game, Mire Mare, which
was never released. [`menu-and-panel.md`](menu-and-panel.md)

## Sound

Knight Lore's note player and note table, byte for byte; five tunes played
and a sixth never; short beeps for the jump, the shot, the footsteps and the
puff; and a small sequencer that plays a note of an effect each turn. A blip,
two beeps and 80 bytes of pitches are never reached. [`sound.md`](sound.md)

## Would it run on a 128K?

Knight Lore's keyboard routine writes to port $xxFD before every read. On a
128K in 128 mode that is the paging port whenever the half-row has bit 7
clear, which Pentagram's first turn produces: the top 16K, where more than
half the code is, would be paged out (*inferred*, not tried). [`input.md`](input.md)

## Driving it

The build plays the game in SkoolKit's simulator from a snapshot taken before
the first instruction; a room is changed by poking the player template's room
and killing him. Recipes for staging the quest, the movers and the drops are
in [`driving.md`](driving.md); the addresses are in
[`memory-map.md`](memory-map.md).
