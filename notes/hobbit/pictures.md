# The pictures

**Question this answers:** how the location pictures are stored and drawn,
why they are slow, what the fast-draw patch changes, and the one picture the
game changes as it runs.

**Short answer:** 22 locations have a picture, each a stream of drawing
commands -- move, line, flood fill, paint attribute cells -- run by
`RUN_PICTURE` into a 256 x 128 canvas at the top of the screen. The game does
nothing else while one draws (up to nearly 12 seconds), then waits for a
key. Most of that time is spent working out screen addresses one pixel at a
time; the fast-draw patch carries them along instead and draws the same
pixels 9.4 times faster. The trolls' clearing is drawn in night colours
until the trolls turn to stone, and in day colours after.

## How it works

**Which places** (`PICTURE_TABLE` $CC00, a `FIND_RECORD` table of location
and stream address; *read*): Bag End (1), the lonelands (4), the trolls'
clearing, path and cave (5, 6, 7), the running river (8), the narrow place
(11), the goblins' dungeon (13), the big goblins' cavern (16), the forest
gate (24), the bewitched gloomy place (25), the spider threads place (26),
the levelled elvish clearing (28), the dark dungeon (31), the elvenking's
cellar (32), lake town (35), the dragon's desolation (37), Dale valley (38),
the front gate (39), the lower halls (41), the smooth straight passage (43)
and the great river (49). The streams fill $CC43-$F35A, about 10 KB -- a
quarter of the game.

**Drawing one** (`DRAW_LOCATION_PICTURE` $7F78; *read*): nothing if
`PICTURES_ON` is 0 (N held at the title); otherwise look the location up and
run its stream. `PICTURE_SHOWN` ($7F77) records the lookup, and
`DESCRIBE_LOCATION` waits in `WAIT_FOR_ANY_KEY` after any picture. Only a
full description draws one -- a first visit or LOOK -- never a return visit.

**The stream** (`RUN_PICTURE` $7FA7; *read*, and decoded command by command
in the listing):

| Bytes | Command |
|---|---|
| 2 | header: the border colour, and the attribute the canvas is cleared to (`CLEAR_CANVAS`) |
| $00 | end |
| $08 x y | move the pen |
| 2, bit 7 set | a line: direction in bits 0-2 (which axis leads, up or down, left or right), length 1-64 in the second byte's bits 0-5, and the minor-axis step split across both bytes -- a Bresenham line in 16 bits (`DRAW_LINE`) |
| 3, bit 6 set | flood fill in the colour in bits 0-2 from x, y (`FLOOD_FILL`) |
| 3+, bit 5 set | paint attribute cells in a colour along a path from an attribute address (high byte first): each path byte two bits of direction and six of count, to $FF |

y counts up from the bottom of the canvas; a stream that draws before it
moves starts at (127, 63). Every pixel plotted also colours its cell's ink,
flipped if it would equal the paper, so a line is never invisible
(`PLOT_PIXEL`). The canvas is exactly rows 0-15 and their attributes; the
story below is untouched ([`screen-and-printer.md`](screen-and-printer.md)).

**Shared drawings** (*read*, found by the build's decode): location 13's
stream runs straight on into location 31's, and 5's into 28's -- the last
private command of the first takes the second's two header bytes as its
operands, and from then on they are one stream. The goblins' dungeon is the
dark dungeon with a few more commands first, and the trolls' clearing is the elvish
clearing with a few more commands first.

**The flood fill** (`FLOOD_FILL` $8071; *read*): a scanline fill with its
queue on the machine stack -- $0080 pushed first as the end marker (a y of
$80 cannot occur), seeds pushed as it finds runs to fill above and below
(`SEEDED_ABOVE`, `SEEDED_BELOW`), popped until the marker comes back.
Every neighbour test goes through `PIXEL_SET` and `PIXEL_ADDRESS`, which
rebuilds the screen address from x and y and rotates the bit mask into place
one position at a time.

**What it costs** (*measured* in the simulator, 2026-09-24, sampling every
1000 T-states while Bag End drew): `PIXEL_ADDRESS` 52%, `FLOOD_FILL` 13%,
`PLOT_PIXEL` 12%, `PIXEL_SET` 8%, `INC_Y` 8%, the rest 6%. The 22 pictures
take 126.1 s between them; the slowest are the trolls' path (11.7 s) and the
lonelands (11.5 s), Bag End 6.7 s. Interrupts are off and nothing reads the
keyboard meanwhile.

**In the dark** `CLEAR_CANVAS` blacks out the border and the canvas and
abandons the stream -- but the key wait still follows. Six of the pictured
places are dark (7, 13, 16, 31, 32, 43): the player sees their pictures only
with the sword ([`light-and-dark.md`](light-and-dark.md)).

**Night and day in the trolls' clearing.** The first two bytes of location
5's stream are $00 $00 on the tape: black border, black paper and ink.
`TROLLS_TURN_TO_STONE` writes $05 $28 there -- cyan border, cyan paper,
black ink -- when day dawns, and `NEW_GAME` writes $00 $00 back before every
game (*read*). *Measured* 2026-09-27: $00 $00 at the start, $05 $28 after
the dawn. So the clearing is drawn by night until the trolls are stone, and
by day after -- the only picture the game changes. Drawn both ways with the
game's own `DRAW_LOCATION_PICTURE` in the simulator (*measured*, the
pictures not kept): by night the lines come out white on black -- the black
ink would match the black paper, so `PLOT_PIXEL` flips it -- with the
ground filled red; by day the same lines are black on cyan. The Locations
page shows the night version, since it draws from the tape's state.

## The fast-draw patch

`patches/hobbit_fast_draw.s`, built by `build_hobbit.py --fast-draw` into
`hobbit_fast.sna`; its own record is
[`docs/hobbit-fast-draw-plan.md`](../../docs/hobbit-fast-draw-plan.md) and the
site's Patches page. In short:

- **The same pixels, in the same order, with the same fill seeds**; only the
  addressing changes. The address and mask travel with the point and are
  stepped with it, and are worked out from scratch (with an 8-byte mask
  table) only where a line or a sweep starts. The line drawer keeps them in
  the alternate registers.
- **The fill's own work** then dominated, and three changes took it away:
  the rows above and below the sweep in IX and IY (the game never enables
  interrupts, so IY is free), each cell's colour written once, and whole
  bytes filled at once where pixel-by-pixel could only have filled them.
- **Where it fits**: rewritten in place either side of the four `ATTR_`
  routines, plus the 165 unused bytes after the last picture ($F35B-$F3FF)
  and memory below the game at $5D00-$5DBF that the BASIC loader used and
  the game never touches. *Measured* 2026-09-27 by comparing the two
  snapshots: 387 bytes of the game differ ($807A-$81E8 and $F35B-$F3DE), and
  159 bytes of new code sit at $5D00-$5DB1.
- **Checked** by `scripts/check_fast_draw.py`: every picture drawn from the
  same machine in both games, the whole of memory compared afterwards --
  identical for all 22; the stack never deeper. 126.1 s of drawing becomes
  13.4 s: 9.4x, from 1.7x (the smooth straight passage's small picture) to
  24.1x (the lonelands). Bag End takes 0.55 s.
- **Two lessons** from its history are in the journal: the patch's first
  home, special word slot 0's handler, turned out to be the quote mark's
  (SAY "..." crashed the patched game), and a keyboard-under-interrupt patch
  was written and then removed as no longer worth its cost.

## How this was found

The picture table and every stream were decoded on 2026-09-18 (`4a8093a`);
the command grammar is `RUN_PICTURE`'s own order of tests, and the build
draws every picture with the game's own code in the simulator for the
Locations page, animated at the game's own speed. The profile and the patch
are 2026-09-24's work. The night and day bytes were noticed in `NEW_GAME`'s
"not yet worked out" and checked for these notes.

## Confidence

*Read* and *measured* throughout; the patch's identity with the original is
checked on every build.

## Disassembly corrections

- `TROLLS_TURN_TO_STONE`'s description says the clearing's "picture is
  patched to show them as stone". What changes is the picture's two colour
  bytes, night to day; the drawing is the same. And `START`'s $6C2B comment
  ("Not yet worked out") is the reverse. Corrected in the annotations 2026-09-27.

## Open questions

- None about the format. Why the clearing alone has a day and a night (the
  book's trolls are caught by the dawn) is story, not code.
