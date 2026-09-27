# Loading

**Question this answers:** how the tape gets the game into memory and
running, and why BREAK cannot stop it.

**Short answer:** a one-line BASIC loader auto-runs and jumps into a few bytes
of machine code parked after its own line. That code loads one headerless
block of 41984 bytes to $5C00 -- over the system variables, over the running
loader, up to the top of memory -- by entering the ROM's LD-BYTES with its
own return address, `LOADED` ($9700). `LOADED` checks the load, switches to
interrupt mode 2 and types RUN for the game's own BASIC. Every interrupt then
goes through `INTERRUPT` ($9797), which turns any BASIC error, BREAK
included, into a fresh RUN.

## How it works

**The tape** (*read*, SkoolKit's `tapinfo` on `tapes/Ant Attack.tzx`,
2026-09-27):

| Block | What |
|---|---|
| 1 | TZX text: made with Ramsoft MakeTZX |
| 2 | program header, auto-run line 1, program length 76 |
| 3 | the loader: 76 bytes of BASIC (with flag and checksum, 78) |
| 4 | one headerless data block of 41984 bytes (41986 with flag and checksum) |

**The loader.** The program is a single line, line 1, which does RANDOMIZE
USR of PROG + 53 -- the address just past the line's own ENTER (4 bytes of
line header and 49 of line). The 23 bytes of machine code there (*read*,
from the build's own decoding in `scripts/build_antattack.py`):

- disable interrupts;
- IX = $5C00, DE = $A400 (41984), A = $FF with carry set: LD-BYTES's
  arguments for loading a data block;
- the stack to $5BF0, in the printer buffer, out of the load's way;
- push $9700, then jump into LD-BYTES at $0562 -- past the ROM's own
  instruction that pushes its exit routine SA/LD-RET ($053F).

So when the block is in, LD-BYTES returns straight to $9700 rather than
through SA/LD-RET, which would have restored the border and interrupts and
checked BREAK (*read*, the ROM). The block overwrites the loader that
started it and the BASIC program it was part of; that is fine because
nothing returns to either.

**`LOADED` ($9700)** (*read*): carry clear (a tape error) jumps to 0, which
resets the machine; DE not zero (a short block) does the same. Then I = $98
and IM 2, so every interrupt vectors through the table at `INTERRUPT_VECTORS`
($9800-$9901, all $97) to $9797; then DI and on to `RESTART_BASIC` ($97A0).

**`RESTART_BASIC` ($97A0)** (*read*): ERR_NR = $FF (no error), SP from
ERR_SP ($7FFC on the tape, whose top word is $1303, the ROM's error-report
entry MAIN-4), the RUN token and ENTER written into the edit line at
E_LINE, EI, and a jump into the ROM's main execution loop at $12B4 as if
ENTER had been pressed. The game's BASIC arrives inside the data block, with
no header of its own, so nothing would run it otherwise.

**`INTERRUPT` ($9797)** (*read*): DI, then if ERR_NR is $FF (no error) on to
the ROM's own routine at $0038; otherwise into `RESTART_BASIC`. BREAK in the
BASIC raises an error through RST 8, the ROM unwinds to the address on the
ERR_SP stack, MAIN-4, whose first instruction is a HALT -- so the very next
interrupt finds ERR_NR set and types RUN. The game restarts at line 10: the
title, "girl or boy", score and rescues back to zero (*read*; not tried
live). The same happens to any other BASIC error. During play the machine
code runs with interrupts disabled (`PLAY` starts with DI), so this only
applies while BASIC is running: between frames of play nothing checks BREAK
at all, and CAPS SHIFT is not one of the game's keys.

A stray second copy of the interrupt set-up (LD A,$98 / LD I,A / IM 2) sits
in the filler just before $9797, in `LOADED_PAD` (*read*); nothing runs it.

## How this was found

The loader was decoded while writing the build (its docstring has the
instructions). The build loads the tape with `tap2sna --start $9700`, which
runs the loader in the simulator and stops where LD-BYTES returns, so the
snapshot is exactly the machine as the load leaves it; the build's playthrough
then starts at $9708, past the two load checks, whose flags only a real load
sets. The TZX's block list was read with `tapinfo` on 2026-09-27, which showed
the header's auto-run line (see the correction below). ERR_SP's value and
the word it points at were read from the snapshot on 2026-09-27.

## Confidence

The loader, `LOADED`, `RESTART_BASIC` and `INTERRUPT` are *read*, and the
simulated load runs through them every build (*played*). That BREAK restarts
the game rests on reading the ROM's error path (RST 8, ERR_SP, the HALT at
MAIN-4); it has not been tried live.

## Disassembly corrections

- The annotations at `RESTART_BASIC` ($97A0) and the How-it-works page's
  loading section say the tape's program header has no auto-run line. It
  has: line 1, the loader (`tapinfo`, 2026-09-27). What has no auto-run is
  the game's own BASIC, which comes in the headerless block; hence the typed
  RUN. Reported to the lead for the annotation and the ref.

## Open questions

- Whether any BASIC error other than BREAK can happen in normal play (and so
  silently restart the game); none has been seen.
- The exact ROM routine at $12B4 was taken from the annotation ("the
  statement loop, as if ENTER had been pressed"), not re-read in the ROM
  listing.
