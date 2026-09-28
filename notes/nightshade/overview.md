# Nightshade -- overview

A tour of the findings. Each section is a summary; the link has the
routines, the addresses, how it was found and what is still open.

## The first Filmation II game, and little of Filmation I

Knight Lore, Alien 8 and Pentagram are flip-screen rooms of blocks, each
block an object, sorted and collided in three dimensions. Nightshade keeps
their tune player, menu, key reading, pause, sound effects and sprite row
code nearly instruction for instruction, and their ideas -- a graphic that
is both picture and behaviour, masked sprites in a buffer -- but everything
about its town is new: 124 of its 164 larger routines match nothing in the
three. [`knight-lore-alien8-pentagram.md`](knight-lore-alien8-pentagram.md)

## A protected tape

The game loads scrambled, and three tiny blocks set things the game later
checks: FRAMES' middle byte (at the start), a `JP (HL)` in the system
variable `NMIADD` (which every table of routines jumps through), and bit 7
of R (at every new game; the refresh counter never changes it). A fourth
check resets the machine if the instruction that takes a life is poked,
and the number of lives is read from the main loop's own `JR` opcode.
[`protection.md`](protection.md)

## A crash after 156 games

`GAME_OVER` is jumped into from called routines and jumps out again, so
every game over leaves two bytes on the stack. It creeps down through the
BASIC area and after 156 games overwrites `NMIADD`: the next game's first
update jumps into the screen (*measured* in the simulator).
[`protection.md`](protection.md)

## A town of 1024 cells

The town is a 32 by 32 map of cell types: open ground, two kinds of solid
block, and 33 kinds of building to walk into, each with two definitions
(one for each side it can be seen from) and a list of boxes that are its
walls. 625 cells can be stood in. Two building types are on no cell.
[`town.md`](town.md)

## Drawing without sorting walls

Only the nine cells round the knight can be on the screen. The buildings
behind him are drawn nearest first, and each column of wall claims its
16-pixel screen column so nothing further back is drawn there -- no sort;
the buildings in front of him get only their outline on the ground, so he
is never hidden. A table of 32 orders, chosen by which neighbours are built
on, puts each cell's things between the walls behind and in front of them;
within a cell, a small depth sort.
[`drawing-order.md`](drawing-order.md), [`drawing-the-town.md`](drawing-the-town.md),
[`depth-order.md`](depth-order.md)

## A scrolling view that turns round

Everything is projected relative to the knight, so he stays in the middle
and the town moves; the Z key shows the town from the other side, by
turning every cell, position and building definition round.
[`projection.md`](projection.md)

## A buffer drawn upside down

The play area is a buffer whose row 0 is the bottom line, redrawn whole
every turn and copied to the screen with PUSHes, then cleared; sprites are
drawn by an unrolled loop entered through a patched `JR`, at even pixels
only, through plain shift tables.
[`drawing-sprites.md`](drawing-sprites.md)

## 23 records, and the order is the quest

23 object records of 16 bytes: the knight's legs and top, two antibodies,
four finds, a bonus, four objects, four villains, six monsters. The graphic
picks the update routine. A thrown object tests only the villain 64 bytes
on: object *n* kills villain *n*, and nothing else can.
[`object-records.md`](object-records.md), [`graphic-numbers.md`](graphic-numbers.md),
[`quest.md`](quest.md)

## The knight

He accelerates halfway to his top speed each turn, rounded down to even,
so he never reaches it; let go, he slows onto an eight-unit grid. His top
is a second record that follows his legs and now and then strikes a pose.
Stick users can have directional control, which has to follow the town
when it is turned round.
[`knight.md`](knight.md), [`input.md`](input.md)

## Walls are boxes

A step is trimmed against the boxes of the cells under the mover's leading
edge, now and after the step, and cut exactly to touch; a flag in the
record says a wall was met. Walkers turn at walls and at random; monsters
spawned in the first half of a 256-turn cycle turn towards the knight
instead; the villains never do.
[`collision.md`](collision.md), [`movement.md`](movement.md), [`touching.md`](touching.md)

## Monsters from the nearest villain

Every fourth turn a monster appears next to the knight, of the kind of the
villain nearest to it; left behind, it is forgotten. Antibodies come in
four kinds, from the cells' types, and a walker struck is destroyed,
changed, split or demoted by the two kinds' sum: each villain's walkers die
to one kind. Every 256 turns a creature comes for the knight, and dies if
led into a wall.
[`monsters.md`](monsters.md), [`antibodies-and-strikes.md`](antibodies-and-strikes.md),
[`creature.md`](creature.md)

## Finds, bonuses and eleven pockets

A building of each type holds a stock of finds (antibodies) shared by all
its cells, handed out every sixteen turns while the knight is inside. A
bonus -- speed, or his hits back -- is nearly always somewhere near. He
carries eleven things and throws the last first; a carried object's icon
flashes when its villain is near, the game's only hint.
[`finds-and-bonuses.md`](finds-and-bonuses.md), [`carrying.md`](carrying.md)

## Lives, game over and the ending

Six lives, one taken as each starts; a new game starts in a random cell,
a new life where the last one ended. With the four villains gone the
ending is object records again: the villains carried over a pit one at a
time and sunk into it.
[`lives-and-starting.md`](lives-and-starting.md), [`game-over-and-ending.md`](game-over-and-ending.md)

## A percentage that cannot print 100

One unit a cell visited and three a villain, each worth 10288/65536 of a
per cent, so 625 cells and 12 make exactly 100 -- which the game then
prints as three garbage characters, because the print jumps past the
instruction that selects the digits.
[`percentage.md`](percentage.md)

## The panel, the sounds, the random numbers

The panel is printed straight to the screen; its villains are outlines
until destroyed, then pictures in their object's colour, and every score
ends in two zeros that nothing writes. The sounds are Pentagram's, some
unused there, and the villains' hum reads the ROM instead of its own four
tables. The random number is stirred with R after every record's update.
[`menu-and-panel.md`](menu-and-panel.md), [`sound.md`](sound.md),
[`random-numbers.md`](random-numbers.md)

## Bugs and leftovers

Eleven bugs, from the 100% print to the crash, each argued in its topic
file; twelve runs of code that never ran, seven of them dead; unread
tables and unused memory.
[`bugs.md`](bugs.md), [`leftovers.md`](leftovers.md)
