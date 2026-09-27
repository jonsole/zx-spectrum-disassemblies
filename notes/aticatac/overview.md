# Atic Atac -- overview

A tour of the findings. Each section is a summary; the link has the routines,
the addresses, how it was found and what is still open.

## A tape that must be run

The game is on the tape encrypted: an 18-byte loop in the printer buffer drags
one nibble through all 30K with RRD, so the plaintext only ever exists in RAM.
Two one- and two-byte blocks are locks: FRAMES must still read $25xx at the
entry point, and every dispatch in the game jumps through a `JP (HL)` the tape
poked into the system variables. The build just runs the tape in the
simulator. Because interrupts stay off until play begins, the first game after
loading always hides the keys in the same rooms.
[`loading.md`](loading.md)

## One loop, two speeds

`MAIN_LOOP` dispatches the room's objects, all eight monster slots and the
room's doors and furniture as fast as it can -- about 23 passes a second in the
starting room -- and between records calls `FRAME_TICK` whenever the frame
counter has moved, to move the player, the weapon and the sound once a frame.
So a crowded room slows the monsters but never the player. A fifth of a pass
is the loop walking its records, and a seventh is a deliberate delay in empty
monster slots.
[`main-loop.md`](main-loop.md)

## Everything is a record, and its sprite is its type

Player, weapon, sounds, food, keys, creatures, doors and furniture are
eight- or sixteen-byte records whose first byte picks both the picture and
the handler. The whole castle is one template copied into place at the start
of a game. Even the drop key is a record: a blank sprite that follows the
player from room to room so the loop runs its handler.
[`records.md`](records.md)

## 149 rooms, ten outlines, five floors

A room is a colour and a shape; the shape is a walk rectangle and a vector
outline. What is in a room is a list of door and furniture halves. The game
has no map: the build puts one together from the doors -- five floors, the
lowest all caverns -- and draws every room with the game's own code.
[`castle.md`](castle.md)

## Doors: a record with two halves, and some that move

Walking through a door means reading its other half, eight bytes away; the
player then walks fifteen frames into the room on their own. Locked doors,
the clock, bookcase and barrel that only one character can pass, trapdoors
that open and close at random, and -- chosen at the start of each game --
about half the ordinary doors turned into doors that slam and reopen on a
shared timer.
[`doors.md`](doors.md), [`keys-and-locked-doors.md`](keys-and-locked-doors.md)

## Drawing: eight ways to lay a door, and a shift chain

Furniture is drawn once per visit in one of eight orientations -- including
the four turned through a right angle, which is how one door picture serves
every wall -- with colour tables where $00 means "leave it" and $FF "the
room's colour". Creatures are XORed on at any pixel by jumping part-way into
seven unrolled shifts; the old and new positions are erased and drawn a row
at a time, interleaved; and each carries its colour with it while giving the
room's colour back to the cells it leaves.
[`drawing.md`](drawing.md)

## The three characters differ in how they stop

Knight, wizard and serf share one movement routine and one top speed. The
wizard stops dead, the knight slides five pixels, the serf sixteen (measured);
and each has a weapon (the spinning axe, the flickering spell, the sword that
points where it flies), a firing sound, and a secret passage.
[`player.md`](player.md), [`input.md`](input.md)

## Monsters are spawned, and touching one kills it

Small creatures appear in the player's room, three at most, and fade away
once he leaves. Touching one costs 32 of the life force but destroys it for
155 points, exactly as shooting it does -- and dying or rising wipes the room
of them, points and all. The big five have rules of their own: the mummy
guards the red key, Dracula wanders the castle and fears the crucifix, the
spanner kills Frankenstein for 1000, the humpback steals objects, and nothing
touches the devil.
[`monsters.md`](monsters.md), [`collision.md`](collision.md)

## The roast, and a zero that is not

The life force drains on its own and from every contact; food restores 64 and
eaten food slowly grows back, one slot looked at every 512 passes. A big monster's touch
that lands the life force on exactly zero leaves the player alive, and the
next drain wraps it to 255 -- a full roast and more (measured).
[`food-and-health.md`](food-and-health.md)

## Three pieces, in the right order

The A.C.G. key's pieces are hidden in one of eight sets of rooms; the great
door is in the starting room and wants them in the inventory newest-first
$8C, $8D, $8E -- collected in reverse. Through it is a passage, room $8E, and
the main loop ends the game the moment the player is there, with
CONGRATULATIONT.
[`acg-key-and-winning.md`](acg-key-and-winning.md), [`objects-and-inventory.md`](objects-and-inventory.md)

## The scroll

Clock, score, roast, spare lives and inventory on a parchment made of tiles,
coloured the inverse of the room. Points come only from destroying creatures.
The end screens add a percentage of the castle seen, scaled so all 149 rooms
make 99.
[`status-panel.md`](status-panel.md)

## Sound

One square-wave routine; short effects played on the spot, and three that
glide over several frames from a sound slot that is a record like any other.
Two sounds the annotations give the wizard are every weapon's.
[`sounds.md`](sounds.md)

## Driving it

Break at `FRAME_TICK` ($7EB2) for frames and `MAIN_LOOP` ($7DC3) for passes;
the menu loop at $7C2F. Staging recipes for rooms, inventories, monsters and
winning -- tried in the simulator, not yet live.
[`driving.md`](driving.md), [`memory-map.md`](memory-map.md)
