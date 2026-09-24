# The Hobbit: faster pictures, as a separate patch

Done: [patches/hobbit_fast_draw.s](../patches/hobbit_fast_draw.s), built by
`build_hobbit.py --fast-draw` and checked by `scripts/check_fast_draw.py`. What
came of it is at the end, under "What it did"; the rest is the plan as it was
written, with the places it turned out wrong marked. The disassembly stays
byte-exact; the speed-up is a file of its own, assembled on top of it.

## What costs the time

Entering a new location spends about 6.9 s drawing its picture, and the game
reads no keys meanwhile. Sampled in the simulator, every 1000 T-states:

| Routine | Time | Share |
|---|---|---|
| PIXEL_ADDRESS ($81DE) | 3.59 s | 52% |
| FLOOD_FILL ($8071) | 0.93 s | 13% |
| PLOT_PIXEL ($81B5) | 0.81 s | 12% |
| PIXEL_SET ($80EE) | 0.54 s | 8% |
| INC_Y ($812B) | 0.53 s | 8% |
| everything else | 0.40 s | 6% |

The cause is one pattern. Both drawers step a point (D,E) one pixel at a time,
so they always know where the next pixel is, and then rebuild its screen
address from scratch: DRAW_LINE once per pixel, through PLOT_PIXEL; FLOOD_FILL
four times per pixel filled -- the pixel above, the pixel below, the plot, and
the next pixel along -- and PLOT_PIXEL rebuilds the attribute address each
time as well. PIXEL_ADDRESS itself then spends a third of its 269 T-states
rotating a bit into place one position at a time.

## The idea

Same algorithm, same order, cheaper addressing.

The new drawers visit exactly the pixels the old ones do, in the same order,
and push exactly the same fill seeds onto the stack. Only how they find a
pixel's byte changes: the address and the bit mask are carried along with the
point and stepped with it, rather than recomputed from it.

That choice is what makes it safe. The picture that comes out is identical by
construction, not merely by test; the fill's stack use -- which is its queue,
growing down from the game's stack under $5EFF -- is unchanged; and
every quirk of the original, such as where a line stops at the canvas edge or
how an ink is flipped when it would match the paper, survives because the
logic that decides them is kept, not rewritten. D and E are still stepped
alongside the address, so the existing edge tests keep working.

### Stepping the address

- Right and left: rotate the mask; when it wraps, INC or DEC L. The low five
  bits of L are x / 8, and x cannot pass 255 because INC_X stops it first, so
  L never carries into the row bits.
- Up and down: the standard Spectrum next-line and previous-line arithmetic on
  H and L (INC or DEC H within a character row, with a fix-up to L at each character
  row's edge and to H at each third of the screen). y is
  measured upwards here, so up the canvas is up the screen.
- The attribute cell only changes when H's third-bits or L change, so its
  address is recomputed only then.

### DRAW_LINE

Carry HL and the mask through both halves -- the x-major and the y-major
stepper -- and plot with the pixel OR and the attribute fix-up inline. The
attribute write is idempotent within a cell: after the first pixel has set the
ink, a second pixel in the same cell keeps the paper, compares the same wanted
ink against it and writes the same result. So it can be done once per cell
entered instead of once per pixel, with no difference to the screen.

### FLOOD_FILL

The fill is a scanline fill. It walks left from each popped seed until it
meets a set pixel, then sweeps right, and at each pixel tests the one above
and the one below, pushing a new seed at the start of each unset run it
finds. The rewrite keeps that exactly, but at the start of a sweep it works
out three addresses -- this row, the row above, the row below -- and moves all
three with one shared mask. A pixel filled then costs three byte tests and a
write against the old four full address calculations, and the attribute is
touched once per cell.

### PIXEL_ADDRESS

Still needed where a line or a sweep starts and after each pop. Replace the
rotate loop with an 8-byte mask table, so a call costs a little over half of
what it does now.

## Where the new code goes

The whole plotting block, $8071 to $820A, is called from nowhere but the
picture interpreter (RUN_PICTURE, $7FA7): checked by searching every CALL, JP
and JR in the image. So it can be rewritten in place: 410 bytes. (As built:
less than that, since the four ATTR_ routines in the middle of it, $80F5-$812A,
are RUN_PICTURE's PAINT and have to stay put -- 356 bytes either side of them.) FLOOD_FILL
and DRAW_LINE keep their addresses, or the two CALLs in RUN_PICTURE are
re-pointed. The fill's flags at $806F-$8070 and PLOT_INK at $824E stay where
they are, since RUN_PICTURE uses them.

If 410 bytes is not enough, the printer buffer at $5B00-$5BFF is unused -- the
game never prints, and nothing on a 48K Spectrum writes there otherwise --
and is page-aligned, which suits the mask table. (Wrong: the game has a PRINT
command that copies its text to a ZX Printer through the ROM, which uses that
buffer. What was used instead is special word slot 0's handler, $82FD-$8390,
148 bytes that nothing can run.) The gap between the BASIC
loader and the stack ($5CCB up to the stack under $5EFF) is not safe to use
until the fill's worst-case stack depth has been measured.

## The file

`patches/hobbit_fast_draw.s`, committed; it contains only new code and
addresses, no game bytes, in keeping with the rest of this repository.

```
    INCLUDE "../game_disassembly/hobbit/hobbit.asm"   ; the original, all labels
    ORG FLOOD_FILL
    ... the new fill, line drawer and helpers, to $820A at most ...
    ORG $5B00
    ... the mask table, and anything that did not fit ...
    SAVESNA "hobbit_fast.sna", START
```

`build_hobbit.py --fast-draw` assembles it after the usual byte-exact check,
and writes `hobbit_fast.sna` and `.z80` beside the plain build, with an SLD so
the patched game can be debugged at source level. It also checks that every
byte outside the declared patched ranges is identical to the original, so the
patch cannot quietly spill into anything else.

## How it is checked

1. **Identical pictures.** For each of the 22 picture streams, run
   RUN_PICTURE in the simulator from the same starting state in both the
   original and the patched image, and compare the canvas ($4000-$4FFF), the
   attributes ($5800-$59FF) and the border. Every one must match exactly.
2. **Stack use.** The lowest SP reached during each fill, in both images.
   It must not go lower in the patched game.
3. **Speed.** T-states per picture, before and after, from the same runs.
4. **Play.** The walkthrough so far -- Bag End to the green forest -- in the
   patched game, on the live server, to see the drawing and hear the result.

## What to expect

The addressing work is about 80% of the drawing time (the table above, less
the fill's own loop and the rest). Carrying the address removes most of it,
so a picture should take something like a third of the time it does now --
roughly 2 seconds instead of 7. That is an estimate from the profile, not a
measurement; step 3 gives the real figure.

## Not in this plan

- **Keys typed while drawing.** The game ignores the keyboard while it draws.
  Polling it from the fill's outer loop and keeping what is typed for
  READ_LINE would stop keys being lost. Small, and a natural second step in the
  same file.
- **Drawing in the background,** so play goes on while the picture draws.
  That means an IM 2 interrupt handler doing the drawing a slice at a time,
  with the interpreter's state kept between slices, and the text window kept
  from being drawn over. It is a much larger change, and with the pictures
  three times faster it may not be wanted.

## Decisions wanted

- The file's name and place: `patches/hobbit_fast_draw.s`?
- Whether to go on to the keyboard polling straight afterwards.
- Whether the patched game should also be written as a tape (`.tzx`) as well
  as a snapshot.

## What it did

Built as planned, with three changes: the new code sits either side of the
ATTR_ routines and in slot 0's handler rather than the printer buffer; the
line drawer carries its address and mask in HL' and C', so that D, E, B, C and
L keep their meanings and the line's own logic is untouched; and the attribute
is still fixed on every pixel -- with the ink, its flipped form and its shifted
form worked out once per line or fill and written into the comparison's
immediates, it costs little enough that doing it once per cell was not worth
the extra code.

427 bytes change, all within $8071-$80F4, $812B-$820A and $82FD-$8390.
`check_fast_draw.py`, drawing each picture from the same machine in both:

- **Identical, all 22.** Not only the screen: the whole of RAM afterwards,
  every variable included, except the patched code and the stack's scratch.
- **Stack.** Never deeper; two to four bytes shallower in every picture, the
  deepest 56 bytes below where the picture was called.
- **Speed.** 126.1 s of drawing for the 22 pictures before, 33.1 s after:
  3.81x overall, from 1.67x for the two-second picture at location 43 to 4.17x
  for location 4's. Bag End, the first thing a game shows, 6.7 s to 1.7 s; the
  slowest, location 6, 11.7 s to 2.9 s.
- **Play.** Recorded on the emulator at real speed from the title screen:
  Bag End finished after 7.0 s in the original and 1.9 s patched, the last
  frames of the two the same picture.

Still not done: the two further steps under "Not in this plan", and a tape
image of the patched game.
