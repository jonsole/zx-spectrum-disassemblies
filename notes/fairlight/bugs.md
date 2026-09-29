# Bugs

**Question this answers:** what is wrong in the game's code, each argued
from the code and, where it could be, shown in the simulator.

**Short answer:** one real bug in play -- picking up either of room 19's
two unnumbered things corrupts a door in room 25 -- one lock-up fixed
between the releases, and a handful of slips that do no visible harm. None
has been watched live in the emulator yet.

## The list

| Bug | Where | Effect | Known by | Deep dive |
|---|---|---|---|---|
| Room 19's two things have no object-table number, and picking one up writes $FE into the x of record 214 (the door from room 25 to room 21); carrying it out of a room would also overwrite that door's destination, key and arrival x | `SET_THING_ROOM` $F4E6, `SAVE_OBJECT_POSITIONS` $F906 | Room 25 can no longer be left that way | *measured* (the pick-up); *read* (the carrying out) | [`carrying.md`](carrying.md) |
| Release 1: a jump during the freeze (a kind-5 thing used) is treated as a still state, and the knight's controls never come back | Release 1's `JR I00` where Release 2 has `CP 5 : JR NZ,I00` ($F263) | The game locks up; fixed in Release 2 | *played* in the simulator, both releases | [`object-states.md`](object-states.md) |
| A stale record number: after something vanishes, the other's redraw takes its number from `FOUND_RECORD` after the mover's redraw has reused that byte | $FA0D in `OBJECTS_MEET` | The wrong record is left out of the redraw; harmless while the other is hidden, possibly visible with the helmet | *measured* (3 instead of 19) | [`meeting.md`](meeting.md) |
| The pit's removal is skipped: the `LD C,$FE : CALL $F4E6` after the kind-7 case's `JR` is never reached | $FA74 | A thing lost in a pit keeps its object-table room and is there again next time (*inferred*) | *read* | [`meeting.md`](meeting.md) |
| At I01 the decoy test compares A, which holds the kind only until a decoy is known and the state after | $F245 in `CHE3D` | A book met after a decoy in the same pass is missed; a state-11 creature can count as a book | *read* | [`object-states.md`](object-states.md) |
| Table numbers past 255 wrap in the one-byte counter | `PLACED_NUMBER` $FFDB | The late doors' and still things' +19 are their number less 256; harmless while none is saved (*inferred*) | *read* | [`object-table.md`](object-table.md) |
| The draw list has room for 30 records and nothing checks | `SORT_AND_DRAW_BEHIND` $EDC6 | Not reached in any room measured (37 records at most, not all behind one object) | *read* | [`drawing-objects.md`](drawing-objects.md) |
| The chaser's short re-aim tests the z distance even when x won | `AIM_AT` $FC66 | A chaser close along z looks again every 3 passes whatever its heading | *read*; whether it is meant is open | [`chasing.md`](chasing.md) |

## Confidence

As tagged in each row. Nothing here has been watched live in the emulator;
the pages' Bugs entries will say which are demonstrated.
