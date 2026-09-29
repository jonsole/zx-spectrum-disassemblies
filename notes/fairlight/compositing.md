# Compositing onto the screen

**Question this answers:** how a moving object, a character of text or the
panel's box gets onto the screen without disturbing what is round it.

**Short answer:** everything drawn after a room is drawn goes through
`COMPOSITE_TO_SCREEN` ($E3E4), which rewrites a rectangle of the screen
byte by byte from an image and four 256-byte pages at $D800-$DBFF: page $D8
says "leave the screen as it is"; page $D9 is the image's mask (clear: the
image shows; set: what is behind shows); what is behind is page $DB where
page $DA is set (other objects behind this one) and otherwise the clean
copy of the room at $C000. The image is shifted to its pixel by jumping into
a run of `RRCA`s. The callers fill the pages ([`drawing-objects.md`](drawing-objects.md)).

## How it works

Inputs (IY offsets): +$64, +$65 the rectangle's x and top row (rows counted
up from the bottom); `DRAW_WIDTH` (+$73) its width in bytes; +$67 its height
in rows; the word at +$68 the image (at $E3E4 the routine starts three rows
before it; at `COMPOSITE_FROM_IX`, $E3F3, HL gives the start); bit 1 of
+$71: pages $DA and $DB in use. Each row takes width + 1 screen bytes and
width + 1 page entries, one index (C') running through the pages across all
rows. For each screen byte:

```
v = image AND NOT D9   OR   clean AND D9          clean = the byte 32 KB above the screen byte
if bit 1 of IY+$71:  v = DB where (D9 AND DA), v elsewhere
screen = v AND NOT D8   OR   screen AND D8
```

The shift: the start rewrites the operand of the `JR` at $E46B, which lands
on one of seven `RRCA`s (x AND 7 of them run). It also rewrites the `JR`s at
$E486 and $E4BC round the steps for pages $DA and $DB (skipped unless they
are in use), and the one at $E4AC that skips a row's last byte when x is on
a byte boundary. The routine itself ORs into page $D8, in each row's first
byte, the bits left of x, so they stay as they are. Rows above 191 are
skipped (the image and the index advanced past them); it stops at the
bottom of the screen. The screen address comes from the ROM's PIXEL-ADD
entered at $22B0 (its `LD B,A`), with A = 191 less the row, skipping the
ROM's own range check.

The callers:

| Caller | Pages |
|---|---|
| `REDRAW_OBJECT` $ECBD, a moving object | Filled from the objects that overlap it: its mask into $D9, the cover of what is in front into $D8, what is behind into $DA/$DB. It widens the rectangle by three rows above and below, which is why $E3E4 starts the image three rows early |
| `CLEAR_THING_BOX` $EC75 | $D9 all set, $D8 clear: the panel's box put back from the clean copy |
| `SHOW_THING_IN_USE` $EC4C | Both clear: the carried thing's image drawn in the box as it is |
| `PRINT` $EBFE, by way of $EC3B | $D8 and $D9 cleared: an 8 by 8 character put down as it is |

The pages lie over leftover source text and, for $DB, the loader's cleared
bytes: `BUFFER_D800`, `BUFFER_D900`, `BUFFER_DA00` and, at the end of the
512 bytes below it, `BUFFER_DC00` ([`memory-map.md`](memory-map.md)).
Nothing can interrupt the routine while it uses them: the game runs with
interrupts off ([`start-up.md`](start-up.md)).

## How this was found

Read (stage 2, range 1), instruction by instruction, with the ROM's bytes
at $22AA-$22CF read to be sure of the entry. The page fills were read in the
callers: the fills at $F052/$F055 fill *downwards* from HL (`LD HL,$DA00 :
LD B,$40 : CALL $F052` clears $D800-$D9FF, not $DA00 up). *Measured* in
stage 2's range 3: the four pages rendered at the compositor's entry in room
2, with the knight beside the state-7 creature, once in front of it and once
behind ([`drawing-objects.md`](drawing-objects.md)).

## Confidence

The per-byte formula: *read*. What each caller puts in the pages: *read*,
and *measured* for the moving object.

## Krumlinde

His `screen_compositing.md` has the self-modifying shift, the live read of
the clean copy (his `PRISTINE_BUFFER`) and the callers right, and
`COMPOSITE_TO_SCREEN` is his name shortened. Where it differs:

- **Pages $DA and $DB do reach the screen.** He concluded that $E3E4 is
  "physically incapable of reading page $DA/$DB" because it loads `B,$D8`,
  and that no second compositor exists for his `SPRITE_BACKBUFFER`. It loads
  $D8 and then `INC B` steps to $D9, $DA and $DB ($E479, $E489, $E491, and
  again at $E4AF, $E4BF, $E4C7). The steps for $DA/$DB are exactly the
  bytes whose `JR`s the routine rewrites, $E488-$E494 and $E4BE-$E4CA -- the
  ranges stage 1 found decode differently in his snapshot, where the `JR`
  operands held skip values. In his snapshot those bytes were jumped over,
  so he never saw them as the $DA/$DB path.
- "Data_D800 has no reset at all": `REDRAW_OBJECT` clears $D800-$D8FF
  before every object's redraw ($F04C), and `PRINT` and $EC4C clear
  $D800-$D9FF.
- The interrupt he describes is never taken ([`start-up.md`](start-up.md)).

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `COMPOSITE_TO_SCREEN` | `SUBE3E4` | $E3E4 | Krumlinde's name, shortened |
| `COMPOSITE_FROM_IX` | (entry) | $E3F3 | The printer's and $EC4C's way in |

## Open questions

- None in this routine.
