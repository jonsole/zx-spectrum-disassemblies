# Graphic numbers

**Question this answers:** what each of the 158 graphic numbers is, which
update routine it runs, and which share their pictures.

**Short answer:** a record's graphic picks both its sprite (`GRAPHICS`,
$6E9E, 158 words) and its update routine (`UPDATES`, $D599, 158 words).
The numbers come in runs of four -- four frames or four facings of one kind
of thing -- and a run shares a routine. A thing changes what it is by
changing its own graphic: an object lying becomes one thrown, a monster
appearing becomes a monster, anything taken or killed becomes the
vanishing cloud. Two runs have no pictures of their own: a dying villain
borrows the cloud's, and a sparkle the finds'.

## How it works

| Graphics | Routine | What |
|---|---|---|
| 0, 1 | `NO_UPDATE` $D6D5 | an empty record (the empty sprite, `SPRITE0`) |
| 2, 3 | `SPEED_BONUS` $D727, `HITS_BONUS` $D74C | the bonuses: a faster walk; the hits back (a flask, as drawn) |
| 4-7 | `OBJECT_LYING` $D942 | the four objects lying in the town |
| 8-11 | `OBJECT_FLIGHT` $D80C | the same, thrown |
| 12-15 | `VANISHING` $D7D8 | the cloud anything leaves, a frame a turn |
| 16-21, 24-29 | `UPDATE_KNIGHT` $DA7A | the knight's legs, front and back (bit 3), six walking frames |
| 22, 30 | `UPDATE_TOP` $D9EB | his top against a wall, arms out (front, back) |
| 23, 31 | `NO_UPDATE` | nothing; the empty sprite |
| 32-47 | `TOP_FOLLOWS` $DA00 | his top: 32-37 front, 40-45 back, following the legs' frame; 38-39 and 46-47 poses of its own |
| 48-63 | `FIND_WANDER` $D9A3 | the four kinds of find (antibodies waiting to be taken), four frames each |
| 64-79 | `WANDERING_MONSTER` $CE89 | four kinds of wandering monster |
| 80-95 | `ANTIBODY_FLIGHT` $D7ED | the four kinds of antibody in flight |
| 96-111 | `VILLAIN_WANDER` $D94F | the four villains, four pictures each (front and back, two frames) |
| 112-127 | `MONSTER112_UPDATE` $C083 | four kinds of monster that steer |
| 128-131 | `APPEARING_UPDATE` $C164 | a monster appearing |
| 132-135 | `VILLAIN_DYING` $D847 | a villain dying: drawn with the cloud's pictures, 12-15 |
| 136-139 | `CREATURE_UPDATE` $BFF1 | the creature |
| 140-143 | `SPARKLE_FLY` $D70A | a dead villain's sparkles: drawn with the finds' first frames, 48, 52, 56, 60 |
| 144-151 | `ENDING_VILLAIN` $CD58 | the villains in the ending, two frames each |
| 152 | `ENDING_PIT_FRONT` $CD10 | the pit's front |
| 153-157 | `ENDING_PICTURE` $CD16 | the pit's back, five pictures |

- The **kind** of a find, an antibody or a monster is bits 2-3 of its
  graphic, and the four kinds line up: a find of kind *k* is taken up as
  antibody thing 5 + *k* and thrown as graphic 80 + 4*k*
  ([`antibodies-and-strikes.md`](antibodies-and-strikes.md)).
- The **sprites**: 94, every one reached by a graphic number (stage 1,
  *measured* by the generator walking the table); the pages draw each one.
  A sprite is a width byte (bits 0-3 the width in bytes, bit 6 stored
  mirrored, bit 7 stored upside down), a height, then mask and image pairs,
  the bottom row first ([`drawing-sprites.md`](drawing-sprites.md)). None is
  wider than four bytes.
- Several graphics share one sprite: 0, 1, 23 and 31 the empty one; 132-135
  are 12-15; 140-143 are 48, 52, 56 and 60 (*read* in `GRAPHICS`).

## How this was found

`UPDATES` laid out by the generator and its runs listed (stage 1); each
routine read in stage 2; the shared sprites checked in the graphic table
(range 3). The pictures named from the build's sprite drawings.

## Confidence

*Read*. Names of pictures ("a flask", "arms out") are descriptions of the
build's drawings, not the game's words.

## Filmation (Knight Lore, Alien 8, Pentagram)

The same design as all three: one number for the picture and the
behaviour, runs of four, and things that become other things by changing
it. Alien 8 has a graphic with a sprite and no routine (drawn only on the
panel); Nightshade's panel villains are drawn from their own graphics'
sprites ([`menu-and-panel.md`](menu-and-panel.md)).

## Open questions

- Why graphics 23 and 31 exist with no picture and no update, between the
  legs' runs: probably spare frames of the legs' runs of eight (16-23,
  24-31) of which only six walk. Nothing sets them (*inferred*: no code
  found writing them).
- What the four kinds of monster (64-79, 112-127) and the creature are
  called: stage 3's graphics pages draw them; the game's text names none.
