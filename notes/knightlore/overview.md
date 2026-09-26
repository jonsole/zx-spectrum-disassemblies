# Knight Lore -- overview

A tour of the findings. Each section is a summary; the link has the routines,
the addresses, how it was found and what is still open.

## Everything is an object record

Forty 32-byte records from $5C08 hold everything that is drawn: the player
(two records, legs and top half), the room's two charm slots, and up to 36
objects the room builder makes from the room's record -- walls, arches, blocks,
guards, fire. The main loop dispatches each on its first byte through a table
of 188 handlers, and that same byte indexes the sprite table: there is no
separate frame number, so an object animates by changing its own type.
[`main-loop.md`](main-loop.md), [`object-types.md`](object-types.md),
[`memory-map.md`](memory-map.md)

## A moving object is redrawn in a rectangle, off screen

The room is never redrawn. An object that moves flags itself and marks every
object whose picture overlaps the rectangle covering its old and new pictures;
at the end of the frame that rectangle is cleared in an off-screen buffer,
every marked object is drawn into it whole, back to front, and only the
rectangle is copied to the display -- so nothing flickers and nothing else
changes. A frame of room $01, traced in the game's own code, shows each stage.
[`moving-objects.md`](moving-objects.md)

## The depth sort is an exact rule for this projection

Objects are drawn back to front by a comparison that codes each axis as
clear-on-one-side, overlapping or clear-on-the-other, and looks the 27
combinations up in a table: the other object goes first exactly when it is
further back or overlapping on every axis and strictly further back on one.
Pairs separated in opposite senses on two axes can never overlap on screen in
this projection, so those entries rightly impose no order. Cycles are caught
and broken. Only rectangles that changed are redrawn.
[`depth-order.md`](depth-order.md), [`drawing.md`](drawing.md)

## Sprites are flipped in place

A sprite is stored once and turned to face the way an object wants by
rewriting the data: rows reversed for upside down, byte pairs reversed through
a bit-reversal table for mirrored. Two header bits record which way the data
lies now, so a snapshot catches each sprite as it was last drawn. Every sprite
carries its own mask, which is what lets objects overlap in depth.
[`sprites.md`](sprites.md), [`drawing.md`](drawing.md)

## A room is a few dozen bytes

128 rooms on a 16 by 16 grid, each a variable-length record: its number, its
size (one of three), its colour, a list of backgrounds (walls, arches,
doorways) and groups of objects placed by grid cell and level. The largest
rooms fill all 36 object records exactly.
[`room-format.md`](room-format.md), [`room-building.md`](room-building.md)

## Collision works one axis at a time

A move is resolved Z first, then X, then Y, shortening each axis a unit at a
time, which is what makes a blocked move slide along a wall. Contact also
passes harm between objects through flag bits, and hands a pusher's velocity
to anything pushable -- but whether it moves is up to its own handler: tables
step once per frame of contact, and the block the game calls *moveable* clears
the push before moving, so it never moves (watched).
[`collision.md`](collision.md), [`player.md`](player.md),
[`object-behaviours.md`](object-behaviours.md)

## Day, night and the werewolf

The sun or moon is an object of its own crossing the panel's window; each
change sets a transformation pending, which the player's handler starts when
he is neither jumping nor entering a room. Each dawn adds a day, and the game
ends when forty have passed. Some objects care which form he is in: the
bouncing balls chase the werewolf and flee the man, and the cauldron's bubbles
turn deadly to a werewolf. [`day-and-night.md`](day-and-night.md)

## The charms and the cauldron

32 places for charms, dealt the eight kinds in rotation from a random start.
The wizard wants fourteen, in the order of a list that is rotated in place at
each new game and never reset. A wrong charm put in the cauldron is destroyed,
not returned. The percentage at the end is rooms visited plus twice the
charms delivered, scaled by 100/156 without a divide.
[`winning.md`](winning.md), [`special-objects.md`](special-objects.md),
[`inventory.md`](inventory.md)

## Timing

Each frame is padded to six units of drawing, so a room with a handful of
things changing runs at an even speed and a busier one slows down.
[`main-loop.md`](main-loop.md)

## Driving it

The menu loop, the per-frame breakpoint (`onscreen_loop`, not `game_loop`),
the input byte bit by bit and the pause, all watched.
[`driving.md`](driving.md), [`input.md`](input.md)
