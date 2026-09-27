# Loading and starting

**Question this answers:** how the game gets from the tape into memory, what
runs first, and what happens between the title screen and the first prompt.

**Short answer:** a short BASIC loader loads a title picture straight onto
the screen and then one 40000-byte block at $6000, and calls it at $6C00
(`START`). `START` copies the whole changeable world aside once; every new
game (`NEW_GAME`, $6C27) copies it back, waits on the title screen for a key
(N held there turns the pictures off), sets up the two text windows, makes
this game's random choices and types LOOK for the player.

## How it works

**The tape** (*read*, from the loader as `build_hobbit.py`'s docstring lists
it): a BASIC program that does `CLEAR 24575` (RAMTOP $5FFF), loads block "p"
as CODE at 16384 -- onto the screen, overriding the address in its header --
then block "h", 40000 bytes at its header address $6000, and runs
`PRINT USR 27648`. The `POKE 23659,0` around each LOAD sets DF_SZ to 0 so the
ROM's "Bytes:" messages have no lower screen to print in. The tape is not
protected: the bytes on it are the bytes the game runs, $6000-$FC3F.

**`START` ($6C00)** (*read*): `DI` -- interrupts stay off for the rest of the
game (the only `EI`s are the ROM's, at the end of SAVE and LOAD, and the game
disables them again straight after) -- then two block copies that are the
game's restart mechanism:

| From | Bytes | To | What |
|---|---|---|---|
| $C11B | $0615 | $F400 | the 61 object records |
| $BA8A | $05D9 | $FA15 | the 80 room records (the copy ends at $FFED) |
| $B6EB | $001D | $5F00 | the variables that make up a game (score, riddle, flags...) |
| $CA84 | $00BF | $5F1D | `TIMERS` and `CHARACTERS` |

`WORLD_COPY` ($F400) is zeros on the tape; the room copy runs past the end of
the loaded block into memory the tape never wrote. Nothing is copied from the
characters' scripts ($C82D-$CA83), which matters later: see
[`save-load.md`](save-load.md).

**`NEW_GAME` ($6C27)** is where `START` falls through to, and where every
death, win, QUIT and failed LOAD comes back to (*read*):

1. `DI`, `LD SP,$5EFF` -- the stack sits just under the saved variables.
2. Put the trolls' clearing's picture back to its night colours (the first
   two bytes of location 5's picture stream to 0; see
   [`pictures.md`](pictures.md)).
3. Copy the four blocks above back.
4. Black border; `TITLE_WAIT` ($6C6D) polls port $FE until any key is down.
   On the first game the screen still shows the loading picture, so this is
   the title screen; after a death it is whatever the last game left.
5. Read the N key: held, `PICTURES_ON` ($B707) is 0 and no picture is ever
   drawn this game. The same key press that ends a game's final wait also
   gets through this one, so pressing N there turns the pictures off too.
6. Set the input window's and the story window's cursors, clear `ORDERS`,
   seed `RANDOM_LAST` from R, clear the score and the drunk and printer flags.
7. Clear the screen (`CLEAR_SCREEN`) and draw the wavy `DIVIDER` between the
   story and the input window at $5140.
8. `NO_PAUSE_LINES` = 17: the opening description scrolls without the
   end-of-line pauses (see [`screen-and-printer.md`](screen-and-printer.md)).
9. `NEW_GAME_CHOICES` ($97AD): shut one road and pick Gollum's riddle
   ([`hidden-roads.md`](hidden-roads.md), [`chance.md`](chance.md)).
10. Print `FIRST_COMMAND` ("> LOOK") in the input window, copy LOOK into
    `INPUT_LINE`, and join the main loop past `READ_LINE`: the game's first
    turn is a LOOK nobody typed ([`main-loop.md`](main-loop.md)).

Step 9 sits behind a test of `COMMAND_FRAMES` ($B706) at $6CF1 that is never
false: see [`leftovers.md`](leftovers.md).

**Memory below the game** (*read*): the BASIC loader and its variables from
$5CCB, the stack from $5EFF down, the saved variables from $5F00 to $5FDB.
The printer buffer at $5B00 is untouched: the game's own printer routine reads
the screen directly ([`screen-and-printer.md`](screen-and-printer.md)).

## How this was found

Read from the loader, `START` and `NEW_GAME`. The build loads the tape with
`tap2sna --start $6C00`, which simulates the real LOAD and stops at the
entry point; the snapshot `hobbit.z80` is the machine at that moment, with
everything as the tape left it (the map still held by Gandalf, the scripts
at their first steps). The key-press behaviour of steps 4-5 was *measured* in
the simulator on 2026-09-27: after QUIT, one held key both ended QUIT's wait
and passed `TITLE_WAIT`, and the game went straight on to draw Bag End.

## Confidence

The loader and the copies are *read* and exercised by every build (the
simulator plays from `START`). Interrupts off throughout is *read*: the
disassembly has `DI` at $6C00, $6C27, $8488 and $8553 and no `EI` at all.

## Disassembly corrections

- `START`'s comment at $6C2B says "Not yet worked out: zeroes two bytes found
  through picture 5's entry". They are the trolls' clearing picture's border
  and paper, put back to night for the new game; `TROLLS_TURN_TO_STONE`
  writes the day's. *Measured* 2026-09-27; corrected in the annotations 2026-09-27. See
  [`pictures.md`](pictures.md).
- `DRAW_LOCATION_PICTURE`'s description calls $B707 "believed the graphics
  flag". It is settled: `TITLE_WAIT`'s code at $6C76 sets it from the N key.

## Open questions

- None about the order. What the tape header's own address for "p" (32768)
  was meant for is not something the code can say.
