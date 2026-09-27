# Ant Attack -- overview

A tour of the findings. Each section is a summary; the link has the routines,
the addresses, how it was found and what is still open.

## Half BASIC, half machine code

The tape's loader pulls in one block over the whole of RAM from the system
variables up, including the BASIC that is running it, and returns into the
game's own code, which types RUN. From then on BASIC runs the title, the
girl-or-boy question, the story and score cards and the setting up of each
level -- POKEing eight object records and a page of variables from DATA --
and the machine code runs the city, entered through four USRs. BREAK, or any
BASIC error, silently restarts the game.
[`loading.md`](loading.md), [`basic-and-levels.md`](basic-and-levels.md)

## One record for everything

The player, the person to be rescued, the grenade and five ants are the same
16-byte record, moved by the same routine and drawn by the same projection;
a few flag bits make the difference (who can step up, who may stand on whom,
who is walking). An "explosion countdown" doubles as the respawn: at zero an
object goes home, which is also how every level starts.
[`objects.md`](objects.md), [`main-loop.md`](main-loop.md)

## The city is a byte per cell, a bit per height

128 x 128 cells, six height bits each, so arches and walkways are just gaps
in the bits. Outside the walls is not an edge but open ground: coordinates
are bytes and wrap, making a 256 x 256 world with the city in one corner.
The player starts outside, beyond the gate in the one gap of the outer
wall. [`city-map.md`](city-map.md)

## Drawing: the whole view, every frame, by tables

The map is read along diagonals into 672 cells; six passes mark, for each
of 512 screen slots, the one height of block seen there, so blocks hidden
behind taller ones are never drawn. Then seven CPIR passes paint the slots
back to front, and the sprites are threaded in without a test: CPIR's own
count is the gap to the next sprite, so running out of count means "draw a
sprite now". The block is code that paints itself.
[`drawing.md`](drawing.md)

## The ants are part of the map

The only solid thing is the map, and each ant XORs itself out of it before
moving and back in after. So an ant stops you exactly as a wall does, and a
bite is nothing but an ant walking into your cell, where your next move
finds a block. Ants chase greedily -- one step, closer or not, turn at random
if not -- with no path-finding; on the first four levels the first ant is nearly
twice as fast as the others.
[`ants.md`](ants.md), [`movement-and-collision.md`](movement-and-collision.md)

## A jump is a fall's grace frame

With nothing underneath, an object may still walk for one frame before it
drops. A jump is one block up; the grace frame is what carries a jumping
player forward onto a one-block step. A drop of four blocks or more is a bad
fall -- a long stun, but no energy lost -- and a fall that ends while stunned,
or on the other person's head, is never landed at all.
[`falling.md`](falling.md), [`movement-and-collision.md`](movement-and-collision.md)

## Grenades: flight time is distance

S, D, F, G throw for 2, 4, 8, 16 frames, and the grenade moves a cell a frame.
The blast blows up ants within four cells at its height and stuns them within
seven -- which also wakes a paralysed ant. People are hurt only by the grenade
entering their own cell; and because the player moves before the grenade
each frame, throwing while walking blows the player up on the second frame
(measured in the simulator and watched live).
[`grenades.md`](grenades.md)

## Energy, events, and a lost bite

The movers record what happened as event bits; one routine turns them into
energy loss and messages after the frame is drawn. A bad fall by one person
in the same frame as a bite or blast on the other loses the other's event
entirely -- the bite costs nothing (measured and watched).
[`energy-and-events.md`](energy-and-events.md)

## Finding, following, getting out

The waiting person is never moved: they lie where the level put them while a
green-or-red scanner says only "warmer" or "colder". Within three cells at
the same height they are found, then follow at two to five cells, stepping
up what the player had to jump. Both outside the walls, anywhere, is a
rescue, scored as time left times rescues so far. Distance wraps: a player
exactly 128 cells away in both directions counts as next to them (watched).
There are no lives; only the clock ends the game.
[`rescue-and-scoring.md`](rescue-and-scoring.md)

## Messages are scripts, and scripts stop the game

Every message the machine code shows is one byte string with its sound in
it: letters, control codes, notes and colour floods, printed and played in
step. They run inside the frame, so the found-them tune halts the city for
about four seconds. [`scripts.md`](scripts.md)

## Sound: two routines, four OUTs

All the machine code's sound comes from four OUT instructions in two
routines: `TONE`, one note of a sixteen-entry table that turns out to be a
chromatic scale (about 477 Hz to 1.08 kHz, some 39 ms a note), and `NOISE`,
speaker bits taken from the random generator. Only the scripts and the
footstep click (five noise bits a step) call them; the BASIC adds its BEEPs
on the title and the cards. The recordings on the Sounds page match the
code's arithmetic exactly. [`sounds.md`](sounds.md)

## No frame pacing

Interrupts are off during play and nothing waits for the 50 Hz frame: the
game runs as fast as it draws, 500-585 thousand T-states a frame, six or
seven frames a second, most of it fixed costs of redrawing the whole view.
[`performance.md`](performance.md)

## Leftovers

The author's signature three times, a script fragment nothing runs, ant
frames nothing draws, a flag nothing sets, NOPs where code was cut, five
variables nothing reads. [`leftovers.md`](leftovers.md)

## Driving it

Break at `GET_KEY`, `WAIT_KEY` and `PLAY`'s CALL of `GAME_FRAME`; hold keys
between frame stops; move ants with their map bits. Tried live.
[`driving.md`](driving.md), [`memory-map.md`](memory-map.md)
