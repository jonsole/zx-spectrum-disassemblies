# The start-up, and interrupts

**Question this answers:** what happens between the loader's hand-over and
the title page -- and whether the game runs with interrupts.

**Short answer:** `START` ($C47C) puts the stack at the top of the leftover
text at $617C, plays the loading tune until a key is pressed, sets IY to
the variables, **turns interrupts off for good** (the `DI` at $C487), copies
the object table and the templates to where the game reads them, makes the
master copy a new game starts from, and jumps to the title routine at
$F065. From then on no interrupt is ever accepted: the sprites at $5B00 up
lie over the ROM's system variables, which the ROM's interrupt routine
would write to fifty times a second.

## How it works

```
START $C47C
  LD HL,$639A : LD SP,HL        STACK_TOP, two bytes below the end of SOURCE_AND_STACK
  CALL LOADING_TUNE $C000       DI ... a note at a time until a key ... EI ; RET
  LD IY,$FF80                   the variables (the author's V)
  DI                            $C487 -- nothing turns interrupts on again
  LDIR $C4E0 -> $A924, 3420     OBJECTS_TAPE -> OBJECTS (the table and 263 bytes of text after it)
  LDIR $D2F0 -> $B734,  932     TEMPLATES_TAPE -> TEMPLATES (templates and patches)
  LDIR $A924 -> $639C, 1200     MASTER_OBJECTS: the object table's first 1200 bytes
  LDIR $FF80 -> $684C,   61     MASTER_VARIABLES: a new game's variables
  LDIR $BC90 -> $6889,   20     MASTER_KNIGHT: the knight's record
  JP $F065                      TITLE_SCREEN
```

The 1200 bytes of the master copy are the first 183 object-table records and
part of the 184th: all 163 six-byte records at the start of the table -- the
things whose room the game changes -- and some doors
([`object-table.md`](object-table.md)). A new game (`NEW_GAME`, $F089)
copies the master object table and variables back, and `TELE` ($F09B) the
knight's record, all but its +14 ([`turning-sprites.md`](turning-sprites.md)).

**Interrupts.** The whole program holds three interrupt instructions
(*searched*: every `EI` and `DI` in the listing): `DI` at $C00B as the
tune starts, `EI` at $C018 as it returns, and `DI` at $C487. The `EI` lasts
two instructions -- the tune's `RET` and `START`'s `LD IY` -- before the
`DI` at $C487 turns them off for the rest of the game. The game calls no
ROM routine that turns them on: only KEY-SCAN ($028E, from the tune) and
PIXEL-ADD (entered at $22B0, from the compositor). The loader's failure
routine calls BEEPER, which does, but that never runs on a good load.

Why it must: the sprite at $5C64 lies over FRAMES ($5C78-$5C7A) and the
sprite at $5BE8 over KSTATE and LAST_K ($5C00-$5C08), which the ROM's
interrupt routine writes (its frame count and its keyboard scan). The game
paces nothing by the frame: a pass of the main loop takes as long as it
takes ([`main-loop.md`](main-loop.md)).

## How this was found

Read, in stage 2 (range 1). The `DI` at $C487 came to light because it
sits three instructions after the tune's `EI`; a search of the whole
listing for `EI` and `DI` found only those three. Then *measured* in
SkoolKit's simulator: IFF is 0 during the tune and in the main loop, and the
ROM's FRAMES counter did not move in a second of play, though the simulator
was asked to deliver interrupts (the build's `Machine.run` passes
`interrupts=True`, which only offers them; with IFF clear none is taken).

## Confidence

Interrupts off: *read* and *measured*. That they must be off: *read* (the
sprites' addresses against the system variables').

## Disassembly corrections

- Stage 1's notes (`journal.md`, `loading.md`, `krumlinde.md`, `driving.md`)
  said the game runs with interrupts on, in IM 1, the ROM's routine fifty
  times a second, turned on by the `EI` at $C018, and that the sessions had
  measured it. Wrong: the `DI` at $C487 turns them off three instructions
  later, for good. The sessions "ran with interrupts" only in that the
  simulator offered them. The files are corrected and the journal says so.
- Stage 1's description of `START` said nothing of the `DI`; the listing's
  now does. The build script's comments in `Machine` (that the game runs
  with the ROM's interrupt routine on) still say the old thing: reported.

## Krumlinde

He could not see the start-up: in his snapshot these bytes are the clean
copy of the screen. His `screen_compositing.md` reads the snapshot's IM 1 as
"a standard 50 Hz interrupt ... serviced by the ROM"; for this game none is
accepted after $C487. His entry at $F065 and his SP and IY are
reconstructions ([`krumlinde.md`](krumlinde.md), [`loading.md`](loading.md)).

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `START` | `START` | $C47C | kept; described |
| `SOURCE_AND_STACK` | `TEXT617C` | $617C | the leftover text the stack sits in |

## Open questions

- Between the tune's `EI` and `START`'s `DI` an interrupt could be accepted
  (two instructions, some 24 T-states of a 69888-T-state frame). If one
  were, the ROM would write FRAMES and the keyboard variables into two
  sprites before the game draws anything. Not tested; harmless in practice
  (*inferred*).
- Whether the game ever changes an object-table record beyond the first 1200
  bytes (a door's); if it did, a new game would not restore it. The room-19
  bug does exactly that ([`carrying.md`](carrying.md)).
