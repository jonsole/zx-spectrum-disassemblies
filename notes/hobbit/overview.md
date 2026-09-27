# The Hobbit -- overview

A tour of the findings. Each section is a summary; the link has the
routines, the addresses, how it was found and what is still open.

## A small program driving a large database

Of the 40000 bytes, most are data: a dictionary, 59 sentence patterns, 61
object and character records, 80 room records, 177 messages, 22 pictures and
the characters' scripts. The code is a parser, an interpreter for each of
those formats, and one routine that carries out any action for anyone. The
tape loads the title picture straight onto the screen and the game at
$6000; `START` copies the world aside once, and every new game copies it
back. [`loading.md`](loading.md), [`memory-map.md`](memory-map.md)

## A turn, and time passing without you

Read a line, tokenise it, parse it into commands, and for each command that
works, the world's turn: the win test, every character, the timers. A
refused command costs nothing -- and if it was refused over an object, the
rest of the line is dropped. Real time enters only one way: 23 seconds with
no key and the game types WAIT for you. [`main-loop.md`](main-loop.md),
[`time-and-timers.md`](time-and-timers.md), [`input.md`](input.md)

## Words: two lists and a 12-bit reference

The words are packed a letter to a byte with the class in the spare bits:
355 the parser reads (29 of them synonyms -- READ is EXAMINE, SAY is TALK,
CAPTURE is ATTACK), 207 more that only the messages print. Everything names a
word by a 12-bit offset and four flag bits. Typed words may be shortened
freely and lengthened a little. [`dictionary.md`](dictionary.md)

## Sentences, frames and trying everything

The parser is a state machine over word classes, filling 24-byte frames laid
out exactly as objects' names are, so meaning is a byte comparison. An
action is a place in the pattern list. Names are not resolved up front: every
object that fits is *tried*, by running the real handler with a "test only"
flag down, and the first that would work is done. Quotes make orders for
characters. [`parser.md`](parser.md), [`actions.md`](actions.md)

## One set of rules for everyone

The player is object 0. The characters act through the same patterns, the
same `DO_ACTION` and the same narration -- so a door, a river or a rope
behaves the same whoever uses it, and "Thorin opens the door" is told by the
code that tells "you open the door". Objects may carry their own handlers,
which run before the ordinary ones. [`actions.md`](actions.md),
[`objects.md`](objects.md)

## The characters' scripts

Each character runs a small script every turn: actions tried as its own
sentences, routines, pauses, jumps, random switches, with a fallback when a
step is refused and one success per turn. Being attacked or given something
switches it to a reaction; an order replaces a step unless the step is marked
against it. Bard keeps his orders in a step of his own that the game
rewrites, and the one step marked "use once" -- Thorin's remark about the
key -- is spent by zeroing its opcode, not by removing Thorin, as the listing
had it (measured). Neither is reset by a new game.
[`characters.md`](characters.md)

## The map

79 rooms, 26 of them dark, 205 exits of which 42 are one-way; doors, rivers
and the web are objects the way goes through. The empty place at 47 can
never be entered: its capacity is exactly the size of the stone in it
(measured). [`locations.md`](locations.md)

## Light: one sword

Only the player is ever in the dark, and the only light is the sword --
carried or just lying in the room. In the dark moves go astray and the
seventh fall kills (measured), most actions are refused, and the picture is
blacked out. Shut inside a closed barrel the player is in the dark even in a
lit room, and cannot open it again without the sword -- the opposite of what
the listing said (measured). [`light-and-dark.md`](light-and-dark.md)

## Traps

The forest road is a trap with no exit: once on it, leaving kills and
staying kills; only pacing between its two rooms keeps the player alive
(measured four ways). The deep bog kills at the end of the turn of arrival.
The trolls turn to stone four turns after the player first meets them.
[`time-and-timers.md`](time-and-timers.md), [`bugs.md`](bugs.md)

## Fighting, and a rotate that should be a shift

A blow is strength plus weapon against defence, each jostled -- meant as
give or take ten, but a sign mistake in `JOSTLE` makes it plus 0 to 10, and
about one time in 25 zero, when any blow over 16 kills: more than 16 stronger
kills, less than the guard is wasted. Wounds wear the target
down -- erratically, because the margin is halved with `RRCA`: an odd margin
takes 129 or more off a strong target and nothing off a weak one (measured
on Thorin). The wound messages are read one entry late, so a margin of
exactly 16 prints a "message" from the ROM.
[`fighting-and-dying.md`](fighting-and-dying.md)

## Text: a bytecode, not strings

Messages are word references, one-byte common words, literals and control
codes that print the actor's name or YOU, IS or ARE, HIS or YOUR: about 5600
characters in 2400 bytes, and one message for the whole cast. Verbs agree
with their subject. The story scrolls over the picture in a six-pixel font;
past nine lines a turn it slows to about 0.6 s a line.
[`messages.md`](messages.md), [`screen-and-printer.md`](screen-and-printer.md)

## Pictures: programs, and one that changes

A picture is a stream of lines, fills and attribute paint, drawn into the top
of the screen at up to 12 seconds a picture, mostly spent recomputing screen
addresses; the fast-draw patch makes that 9.4 times faster with identical
results. The trolls' clearing is drawn by night until the trolls turn to
stone, then by day: the game rewrites the picture's colour bytes.
[`pictures.md`](pictures.md)

## The score only counts arrivals

One instruction raises `SCORE`: `ARRIVE`'s, the first time the player reaches
one of fourteen places worth 750 in all, so 75% is the most anyone can
score. Five of those places are dark and score only with the sword.
[`scoring.md`](scoring.md)

## One road is shut at random, and Elrond opens it

Each new game zeroes one of five exits; Elrond reading the map writes it
back. The choice lives in an instruction's operand, which SAVE does not
write -- so a game loaded after a new game can lose its road for good.
[`hidden-roads.md`](hidden-roads.md), [`save-load.md`](save-load.md),
[`chance.md`](chance.md)

## Bugs and leftovers

Beyond the score and the fight: FILL can never work (measured), JUMP ONTO
jumps into a message, five sentence shapes have no handler anywhere, BREAK
at the end of a tape block restarts the machine (measured). Six stretches of
code nothing reaches, a flag nothing sets, a start-up test that never fails.
[`bugs.md`](bugs.md), [`leftovers.md`](leftovers.md)

## Versions

The tape archived as v1.0 is the first release, which its authors called
v1.1; v1.2 is the fix, laid out differently but with the same scoring. The
Sinclair Research re-release is v1.0. [`versions.md`](versions.md)

## Driving it

Break at the key waits and at `READ_LINE_READY`, inject whole commands into
the line, capture text at $858F, never hold a key across story output.
[`driving.md`](driving.md)
