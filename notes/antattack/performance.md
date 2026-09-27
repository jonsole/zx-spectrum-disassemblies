# Performance

**Question this answers:** how long a frame takes, where the time goes, and
what sets the game's speed.

**Short answer:** about 500,000-585,000 T-states a frame, six or seven
frames a second. Nearly all of it is drawing the view from scratch: marking
the planes (110k), the copy to the screen (82k), the CPIR scan (81-85k),
gathering the map (80-93k), clearing the buffer (44k) and the blocks
themselves (48k-123k, with how many are in view). Interrupts are off and
nothing waits for the 50 Hz frame, so the game's speed is its drawing speed:
anything that draws faster plays faster, and a busy view plays slower.

## How it works

**Measured live** (2026-09-24, a private `zx_server`, its profiler over 118
frames of walking at each of four places in the city; the script was in that
session's scratchpad and not kept): 498k-585k T-states per frame, which is
6.0-7.0 frames a second at 3.5 MHz.

| Routine | Per frame | Why that much (*worked out* from the instruction timings) |
|---|---|---|
| `MARK_PLANE` x 6 | 110k, the same every frame | 6 x 512 slots, each a load, AND, jump and maybe a store: about 18k a call |
| `COPY_TO_SCREEN` | 82k | 116 rows of a 30-byte LDIR (about 625 T each) plus the row stepping |
| `DRAW_SCENE`'s CPIR | 81-85k | 7 passes x 512 slots x 21 T is 75k, plus a stop for each block and sprite |
| `GATHER_VIEW` + `READ_MAP_CELL` | 80-93k | 672 cells, each a CALL with its own outside test |
| `CLEAR_BUFFER_ROWS` x 4 | 44k | 116 rows of 32 unrolled stores |
| `DRAW_BLOCK` | 48k-123k | 76-188 blocks in view, about 640 T each |
| `PLANE_TO_BUFFER` | 7-17k | once per block and sprite drawn |

The first five are fixed costs, about 400k together, whatever the view
holds; only the blocks and sprites vary.

**Measured in the simulator** (2026-09-27, SkoolKit's simulator stepping from
one `GAME_FRAME` to the next): 538k-551k T-states a frame at the gate, walking
and standing alike. Every third frame is about 9000 T-states longer: the
clock's tick, printed through the ROM's RST $10 and OUT-NUM-2. Neither the
simulator nor the emulator models contended memory; on a real Spectrum the
copy to the screen and anything else touching $4000-$7FFF would be slower
(*assumed*; the game's code and buffers are all above $8000, so most of the
frame is uncontended).

**No pacing** (*read*): `PLAY` runs with interrupts disabled from start to
end, reads the keyboard itself, and never HALTs or counts FRAMES. The frame
rate is therefore whatever the drawing allows, and it varies with the view;
the clock ticks by frames, not seconds, so a busier view makes a level's 3003
frames last longer in real time.

**Scripts stop everything.** A message's notes are played inside the frame
([`scripts.md`](scripts.md)): the found-them tune alone is about four
seconds with nothing moving.

**Ideas priced on 2026-09-24** (proposals only; none has been tried in a
patch):

- `BUILD_PLANES` as one ascending pass over the gathered cells that scatters
  each cell's bits into the slots, later (higher) heights simply overwriting
  -- no per-height compare. `PLANES` could then start at 0 instead of $FF,
  since `DRAW_SCENE` never searches for 0.
- The copy and the clear together, with POP and PUSH instead of LDIR and
  stores.
- The gather inlined, stepping the map address by +129 along a diagonal
  instead of calling `READ_MAP_CELL` per cell.

## How this was found

The live figures came from `zx_server`'s profiler, run on a throwaway server
over repeated walks (2026-09-24). The simulator figures and the per-routine
arithmetic were done for these notes on 2026-09-27; the arithmetic agrees
with the live figures to within the loop overheads.

## Confidence

*Measured* twice, live and in the simulator, and consistent with the
instruction timings. The live figures cover four places in the city only.

## Open questions

- The slowest view in the city: the most blocks in view was not searched for.
- How much a real, contended Spectrum loses to the screen copy (the emulator
  does not model contention).
