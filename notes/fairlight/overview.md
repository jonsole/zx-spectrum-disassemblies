# Fairlight -- overview

A tour of the findings. Each section is a summary; the link has the
routines, the addresses, how it was found and what is still open.

## A protected tape, and a tune

Two BASIC programs (Release 2 adds a copyright warning), then two
turbo-speed blocks under the Alkatraz Protection System: a loader that
decrypts itself in layers, reads the loading screen a line at a time in its
own order, reads the game in pieces with each byte XORed with a changing
key, the count left and its own address, checks that the decrypted checksum
byte equals the sum of everything before it, clears itself -- running on
through its own last instruction as it does -- and returns to $C47C. The
build redoes the decryption on the tape's bytes and checks the result.
[`loading.md`](loading.md)

The game begins by playing a two-voice tune over the loading screen, two
square waves sent to the beeper alternately in a loop balanced to 96
T-states: 52.6 seconds, and the only sound in the game.
[`loading-tune.md`](loading-tune.md), [`sounds.md`](sounds.md)

## Interrupts off, for good

The start-up turns interrupts off three instructions after the tune turns
them on, and nothing turns them on again: the game's sprites lie over the
ROM's system variables, which the ROM's interrupt routine would scribble
on. Nothing is paced by the frame. (Stage 1 had this wrong.)
[`start-up.md`](start-up.md)

## A tape full of leftovers, and the author's own names

About 9 KB of the image is the development machine's memory: the author's
assembler source in numbered lines -- among it the object table's DEFB
lines and whole stretches of the main loop, the room set-up and the
keyboard reading -- and part of the assembler's symbol table. Between them
they give Bo Jangeborg's own names for about a hundred places in the code:
CHE3D, ROOMST, ZOOMIN, EEN, MIWRAI and MITRO (which read as mirror wraith
and mirror troll),
PAUS, TELE, and the variable bases V and T.
[`symbols.md`](symbols.md), [`leftovers.md`](leftovers.md)

## Rooms are programs

A room is a colour byte and a stream of drawing commands run each time it
is entered: points (row, column), a second point, lines, eight mode bits
(relative, mirrored, joined, erase, flip ...), repeats, 56 shared parts,
and flood fills with 26 textures -- two of which are Swedish letters rather
than patterns. The fill is bounded not by the screen but by a clean copy of
it, which a room can draw an invisible outline into first. The room is drawn
black on black and coloured all at once when ready.
[`rooms.md`](rooms.md), [`textured-fill.md`](textured-fill.md)

## One record for everything

The knight, the things he carries, creatures, doors, furniture and the
invisible steps of staircases are all twenty-byte records: a sprite, a box
(a corner and three lengths), a kind, a state, a direction, a count, a
weight, an animation, a number in the object table. The first six records
have no sprite: they are the room's floor, ceiling and walls, moved for
each room by a patch code.
[`object-records.md`](object-records.md)

## The object table remembers the castle

381 records: 163 things that can move between rooms, 174 doors, 44 still
things. A thing's room byte is where it is now ($FE while carried) and its
position is written back whenever the knight leaves a room, so things stay
where they were left. A room's records are made from the table and the
templates by projecting from the one point, (50, 50, 50), for which each
template's screen position is drawn.
[`object-table.md`](object-table.md), [`projection.md`](projection.md)

## Drawing a moving thing without redrawing the room

Only the rectangle a moving object covers is rebuilt, straight onto the
screen, from four 256-byte pages: its own mask, the cover of whatever stands
in front (the screen keeps those pixels), and the objects behind -- sorted,
with a move limit that breaks cycles -- drawn over the clean copy of the
room. Things that never move are drawn once into the clean copy as the room
is entered. Krumlinde missed that two of the four pages reach the screen,
because in his snapshot the self-modified jumps skipped them.
[`compositing.md`](compositing.md), [`drawing-objects.md`](drawing-objects.md)

## States, gravity and a freeze

Each pass, every object's state picks a direction: things lie or bounce,
guards patrol or chase, the troll and the wraith chase, guards rise out of
the floor, things float and flicker, a ghost wanders and steals, the figure
of room 61 waits for a book. Gravity is nothing but a down bit forced onto
every move that is not rising. Using one thing freezes every creature until
the next room -- and Release 1 forgot to exempt the knight's jump, so a jump
while frozen locked the game.
[`object-states.md`](object-states.md), [`movement.md`](movement.md),
[`versions.md`](versions.md)

## Boxes, pushes and fights

A blocked move is taken apart axis by axis against what it hit: turn back
or stop on the axes that collide, climb an invisible step, ride a moving
thing, push anything no more than five heavier. When things meet, their
kind bytes settle it: 10 LIFE for a touch of something that hurts, 1 for
running into a fighter, four sword strikes to kill a guard (which leaves
its helmet), a ghost that steals, two kinds of thing that destroy a wraith,
pit floors that kill.
[`collision.md`](collision.md), [`meeting.md`](meeting.md),
[`chasing.md`](chasing.md)

## Four ways from two views

The sprites face four ways by being mirrored in place in memory. Because
the frames are shared, the game has to turn a troll's or wraith's frames
back on every way out of a room -- and the build's shortcut into a room,
which skips that, can carry them mirrored into the next.
[`turning-sprites.md`](turning-sprites.md)

## The knight, his load and the doors

He walks four ways, jumps sixteen units, fights in two phases, and loses a
point of LIFE for every pass of a fall past twenty. He carries five things,
a load of at most 7. Doors are records too: a way through, a key, an
arrival point, and a check that nothing stands there on the other side.
Room 19 holds two things with no number in the object table; picking one
up corrupts the door from room 25 to room 21.
[`knight.md`](knight.md), [`carrying.md`](carrying.md), [`doors.md`](doors.md),
[`bugs.md`](bugs.md)

## The loop inside the room

The main loop runs inside the routine that enters a room and returns from
it only when the game ends; a door jumps back into it. There is no frame
wait. The quest is won by carrying thing 5 of the object table into room
81.
[`entering-rooms.md`](entering-rooms.md), [`main-loop.md`](main-loop.md),
[`game-cycle.md`](game-cycle.md), [`quest.md`](quest.md), [`printing.md`](printing.md)

## Two releases, and Krumlinde's

Ville Krumlinde's disassembly is of Release 2. Release 1 has the Kempston
joystick switched off, sets up its tables in the title routine, draws room
67 differently, has three doors a little different -- and the freeze's
lock-up. Krumlinde's map agrees with this one on nearly every instruction;
his readings differ in a couple of dozen places, each checked.
[`versions.md`](versions.md), [`krumlinde.md`](krumlinde.md)
