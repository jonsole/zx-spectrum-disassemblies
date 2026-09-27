# Alien 8 -- overview

A tour of the findings. Each section is a summary; the link has the routines,
the addresses, how it was found and what is still open.

## Between Knight Lore and Pentagram

Alien 8 is Knight Lore's engine a year on, and the code shows it half way to
Pentagram. Its rooms are Knight Lore's 16 by 16 grid, its valves live in
Knight Lore's special-object slots, and it keeps Knight Lore's exits, menu,
movers and rating. Its renderer, depth sort, collision code, player movement
and room builder are the forms Pentagram also has, often instruction for
instruction. Its own: the valves and sockets, the 24 chambers and the
summary, the remote-controlled robots, the light-years clock, the turning
animation and the scenes after a game.
[`knight-lore-and-pentagram.md`](knight-lore-and-pentagram.md)

## Everything is an object record, and the graphic is the behaviour

56 records of 32 bytes: the robot's legs and top, two for what lies in the
room from the table of places, and 52 for the room. The graphic number picks
both the sprite and the update routine, so a valve becomes a seated valve,
or anything a sparkle, by changing its own graphic. Graphic 131 has a sprite
and no routine: it is only ever drawn on the panel.
[`object-records.md`](object-records.md), [`graphic-numbers.md`](graphic-numbers.md)

## A turn, and an even speed

`START` is three loops: a life, a room, a turn. A turn runs all 56 records'
update routines, draws what changed, and pads the turn to six units of
drawing work, about 20,000 T-states a unit, so a quiet room runs no faster
than one where six things are drawn. Then the clock takes its tick.
[`main-loop.md`](main-loop.md)

## Drawing only what changed, and a list that fits

A mover marks everything its old and new pictures touch; at the end of the
turn those areas are wiped in an off-screen buffer, the marked objects drawn
into it back to front through their masks, and only those areas copied out.
Unlike Pentagram's, the draw list was grown with the object table: 64 bytes
for 56 records, the longest seen 51. And the sort still destroys what it
finds sharing space -- here, a valve.
[`drawing.md`](drawing.md), [`depth-order.md`](depth-order.md)

## Collision, riding and lifting

A move is cut one axis at a time, Z, U, V, a unit at a time. A carried
mover hands its Z step to what it lands on and rides that thing's U and V
steps, and the robot and the movable blocks mark what they land on. That is
all the engine does; a conveyor just sets its own step and never moves, a
lift waits to be stood on, a dropping block sinks and a collapsing block
vanishes when marked. All the lifts in a room share one top height.
[`collision.md`](collision.md), [`carrying-and-lifts.md`](carrying-and-lifts.md)

## The robot, and a lost step at every turn

Knight Lore's movement -- 3 units a step, a jump of 8 with gravity 2 -- with
a quarter turn shown through an in-between view held for two turns. The
routine that ends the turn calls its sound without saving the controls, so
the step it means to take is lost: a walking robot stands still three turns
at every quarter turn (*measured*). His legs are his collision box; the top
follows them and is something to stand on. [`robot.md`](robot.md),
[`input.md`](input.md)

## Doorways on a grid

A doorway is a pair of pillars that marks the robot "in the doorway" and
nudges him to its middle while he faces through. Walking out moves the room
number by 1 within its row or by 16; he arrives at the matching doorway,
raised ones included, and his records are saved there, so a lost life starts
at the last doorway. [`doorways-and-rooms.md`](doorways-and-rooms.md),
[`room-building.md`](room-building.md),
[`lives-and-starting.md`](lives-and-starting.md)

## Valves, sockets and a game that can be short of one

36 places are dealt at every new game: valves of four kinds in rotation and
two or three extra lives. A valve of the right kind in a chamber steers
itself onto the socket; seated, it activates the chamber -- the screen's
colours cycle, the room turns white -- and the twenty-fourth wins. The
socket's sparkle shows the valve it wants. Because the extra lives fall
sixteen places apart, they all replace one kind, and a game with three
leaves that kind exactly the six its sockets need (*read*; not played).
Only the two place records are searched when picking up, so only valves can
be carried, three at a time, first in first out.
[`valves-and-sockets.md`](valves-and-sockets.md),
[`picking-up.md`](picking-up.md),
[`chambers-and-summary.md`](chambers-and-summary.md)

## The light years

Four digits that roll into place like a mechanical counter: a light year
every seven turns, 6000 of them, and the game ends at zero.
[`clock.md`](clock.md)

## Robots on remote control

Standing on a button sends the robot in control two units a turn one way; a
pad stops it; stepping off hands control to the other robot, if there is
one. The robots push, and the deadly fragile things break when pushed.
[`remote-robots.md`](remote-robots.md)

## Creatures and dangers

Creatures made of two records that wander or pace, a deadly thing that
homes in slowly and a harmless crackle that comes fast, clockwork mice,
leapers that jump 48 units one at a time, and Knight Lore's spiked balls as
things that drop from the ceiling -- only once something has been picked up
in the room. [`creatures.md`](creatures.md)

## The end: a summary, a rating and a scene

The summary counts the chambers activated and the frozen crew lost in the
rest, and rates the game by rooms seen and success exactly as Knight Lore
did. Then a scene runs in the main loop: the robot re-programmed by a glove,
a hammer and a hook, or, after a win, dipped in oil.
[`chambers-and-summary.md`](chambers-and-summary.md), [`scenes.md`](scenes.md)

## The menu, the panel, the sound

Knight Lore's menu with its directional-control choice, one list printer for
all the text, twelve pieces of panel with a label coloured never to match the
room. Knight Lore's note player byte for byte, five tunes, and its effects.
[`menu-and-panel.md`](menu-and-panel.md), [`sound.md`](sound.md)

## Would it run on a 128K?

Every turn the keyboard routine's stray OUT writes $7E to a port a 128K
decodes as its paging port: the code above $C000 would be paged out in the
first turn (*inferred*, as Pentagram's was before it was watched).
[`input.md`](input.md)

## What was left in

Knight Lore's werewolf sound, its panel-colouring routine and its copyright
line from 1984; a check of R that no longer jumps; a sprite and a drawing
nudge nothing uses. Above the code, the tape carries the mastering machine's
leftovers, among them the first 1464 bytes of the Interface 1's ROM.
[`leftovers.md`](leftovers.md)

## Driving it

The build plays the game in SkoolKit's simulator from a snapshot taken before
the first instruction; a room is changed by poking the start records and
killing the robot. Recipes for the chambers, the ending, the clock, the
robots, the drops and the movers are in [`driving.md`](driving.md); the
addresses in [`memory-map.md`](memory-map.md).
