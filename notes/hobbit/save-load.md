# SAVE, LOAD, and starting again

**Question this answers:** what SAVE writes and LOAD reads, what a new game
puts back, and what neither of them covers.

**Short answer:** SAVE writes four headerless blocks through the ROM -- the
game's variables, the objects, the timers with the character slots, and the
rooms -- and verifies them; LOAD reads the same four. They are the same four
blocks `START` keeps a copy of for every new game. What none of them covers
is the characters' scripts, where the game keeps two bits of state it
changes as it runs, and the hidden road's choice, which lives in an
instruction's operand -- so a loaded game can lose its shut road for good.

## How it works

**The four blocks** (*read*; `DO_SAVE` $84CC, `DO_LOAD` $8451, `START`
$6C00):

| Block | From | Bytes | Holds |
|---|---|---|---|
| 1 | $B6EB | $1D | `SAVED_STATE` to `PICTURES_ON`: the score, the riddle, the flags that make a game |
| 2 | $C11B | $615 | the 61 object records |
| 3 | $CA84 | $BF | `TIMERS` and `CHARACTERS` |
| 4 | $BA8A | $5D9 | the 80 room records |

**SAVE** (the special word; *read*): copy the three bytes of Bard's order
step ($C9E2) into `SAVED_STATE` ($B6EB); a prompt to start the tape, in
the input window; `NEW_KEYPRESS`; the four blocks through SA-BYTES ($04C2)
with A = $FF, no headers; a prompt to rewind for the verify, a
key; each block through LD-BYTES ($0556) in verify mode. A block that fails
to verify reports a tape error, waits for a key and gives up; either
way `DI` (the ROM's tape routines end with `EI`) and back to the parser for
the rest of the sentence.

**LOAD** (*read*): the four blocks through LD-BYTES; then `DI`, Bard's three
bytes back into his step, and back to the parser. Nothing is described: the
player is where the saved game was, but the screen says so only at the next
LOOK or move. A block that fails leaves the game half loaded, so
`LOAD_BLOCK` does not go back: a tape error message that says the
program will restart, a key, `NEW_GAME`.

**A new game** (`NEW_GAME` $6C27, after a death, a win, QUIT or a failed
LOAD) copies the same four blocks back from where `START` put them ($F400
and $5F00; see [`loading.md`](loading.md)), puts the trolls' clearing's
picture back to night, and makes new choices (`NEW_GAME_CHOICES`).

**What is not saved, loaded or restored** (*read*, from the block ranges):

- **The characters' scripts** ($C82D-$CA83). The game writes into them in
  two places: `BARD_TAKES_ORDER` rewrites Bard's step at $C9E2 with his
  latest order -- which is why SAVE and LOAD carry those three bytes by hand
  -- and `SCRIPT_DO` spends a step with bit 5 by zeroing it (only Thorin's
  remark about the key has the bit; [`characters.md`](characters.md)). A new
  game restores neither: Bard keeps his last order into the next game, and
  Thorin's remark stays spent (*measured* for Thorin: still $00 after QUIT
  and a new game).
- **The hidden road** ([`hidden-roads.md`](hidden-roads.md)). Which road
  this game shut is kept only in the operand of `ELROND_READS_MAP`'s
  `LD IY` ($A7D1), which no block includes; the shut exit itself is in the
  rooms block. So SAVE in one session and LOAD in another -- after reloading
  the game from tape, which shuts a road of its own choosing -- brings back
  the saved game's rooms, with its road shut, while $A7D1 names the new
  session's road. When Elrond reads the map he rewrites the new session's
  road, which the loaded rooms already have open, and names it; the loaded
  game's road stays shut. It is the same if the two choices differ within one
  session: a LOAD after dying and starting again. (*read*; not tried with a
  real tape. The two can only agree when the random choice happens to.)
- **`RANDOM`'s state** (`RANDOM_LAST`, `RANDOM_POINTER`): outside block 1,
  so a loaded game does not replay the saved game's luck.
- **`PICTURES_ON`** *is* in block 1: LOAD brings back the saved game's
  choice of pictures or none, whatever N did at this session's title.

**BREAK during a tape block** (*measured* 2026-09-27 in the simulator): with
SPACE held from SAVE's key press on, the ROM's check at the end of the first
block found BREAK and took its error exit (`RST 8`), and within a few
seconds the machine was at address 0 -- a restart, the game gone. The game
never points IY back at the system variables, which the ROM's error handling
relies on (*assumed* as the cause).

## How this was found

Read from the two routines and the block ranges; the copies' ranges were
checked against `START`'s. The script and hidden-road gaps came from
comparing those ranges with where the game writes: the only instructions
that write an address in $C82D-$CA83 by name are `BARD_TAKES_ORDER`'s
three, the only one that writes $A7D1 is `NEW_GAME_CHOICES`', and
`SCRIPT_DO`'s indexed write reaches the scripts through IX (other indexed
writes were not searched). The Thorin case and the BREAK case were run in
the simulator for these notes.

## Confidence

The blocks are *read*. The two gaps are *read*; Thorin's side is
*measured*. The hidden road's loss after a LOAD follows from the code but was
not played through with a tape.

## Interrupts during SAVE's rewind prompt (2026-09-27)

*Measured* (the sounds page's run of a whole SAVE and its verify): `DO_SAVE` does
not disable interrupts again until `TAPE_DONE` ($8553), so from the end of the
fourth SA-BYTES block, through the rewind prompt and its key wait, to the
verify's LD-BYTES, the ROM's IM 1 handler and keyboard scan run -- with IY at
$B9C8, not the system variables. Holding a key there for 0.2 s changed nothing
but the stack (LAST_K and $B9C9 untouched), so no harm was seen; but it is not
true that the game disables them straight after the ROM's `EI`.

## Open questions

- Whether a LOAD in the same session and the same game (no new game in
  between) is safe: then $A7D1 still names the road the rooms were saved
  with, and it should be.
- What a verify failure after a good save leaves: the player is told and
  play goes on, which is right.
