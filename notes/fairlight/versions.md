# The two releases

**Question this answers:** how the two 48K tapes in ZXDB differ, which one
Krumlinde's `fairlight.sna` was taken from, and so which one this
disassembly is of.

**Short answer:** Krumlinde's snapshot is **Release 2**: every byte of the
game's code in his image is Release 2's, and every place they differ is a
byte the running game writes. This disassembly is of Release 2. Release 1
has the joystick switched off in its code, sets up its tables at the start
of the title routine rather than in the throwaway start-up, draws room 67
with two more pieces, has three door records a little different, and
locks the knight up if he jumps while the creatures are frozen -- which is
surely why Release 2 was made.

## Which release Krumlinde's snapshot is

His `fairlight.asm` was assembled with sjasmplus (in the scratchpad) to its
49152 bytes from $4000, and compared with each release as loaded by
tap2sna and stopped at $C47C (*compared*):

| Compared | Bytes that differ | Where |
|---|---|---|
| Release 1 : Release 2 | 8426 | 21 runs, among them $F065-$FF73 (the code) |
| Release 1 : Krumlinde | 26824 | 28 runs, among them $F065-$FF73 |
| Release 2 : Krumlinde | 19827 | 22 runs, none in the resident code but single bytes |

Release 2 against his image differs only where the running game writes:
the screen; the stack and the master copy ($636E-$689B); the object table's
and templates' homes, which the start-up fills ($A924-$B67F, $B734-$BAD7);
the object records and the buffers ($BC91-$D9FF, with three bytes of the
six fixed records the room codes patch); single bytes inside instructions
that the code rewrites as it runs ($E46C, $E487, $E4BD, $EBFB, $ECB4,
$EFD1, $EFE3, $EFF4, $F008 -- each the operand of an instruction some
routine stores to, *read*); and the variables ($FF80 up). Running Release 2
in the simulator writes every one of those regions before the title screen
or in the first room (*measured*). His snapshot was taken mid-game, in a
room, with the start-up long since done.

Release 1 against him differs in the code itself: $F065-$FF73 is laid out
differently (below).

## What Release 2 changes

From the two snapshots at $C47C, compared region by region and aligned with
Python's `difflib` where code moved (*compared*, then *read*):

- **The joystick.** Release 1's Kempston routine (its $F10D) is `XOR A :
  RET` followed by the port reads it never reaches: the joystick is
  switched off. Release 2's ($F0E6) reads the port only when bit 3 of
  $FF86 is set, and the main loop ($FE47) flips that bit when 9 is
  pressed; the title screen prints "9-JOY" beside the controls (a string
  added at $F07A). So Release 2 makes the joystick an option; Release 1
  has none. Why it was off in Release 1 is not known: a Kempston port read
  on a Spectrum without the interface returns whatever the bus holds, which
  would read as movement, and switching it off is one way round that
  (*inferred*).
- **The start-up.** Release 1's hand-over ($C47C) is `LD HL,$6392 : LD
  SP,HL : CALL $C000 : JP $F065`, and its title routine at $F065 begins by
  setting IY, turning interrupts off (its `DI` at $F069) and making the
  copies of the object table and templates.
  Release 2 moves those 52 bytes into the hand-over, in the $C000 buffer
  area that the game overwrites once it runs, and puts the stack 8 bytes
  higher ($639A). The resident code is 52 bytes shorter for it.
- **The freeze and the jump.** In `CHE3D` (the author's name; Krumlinde's
  `Sub_F1E0`), Release 1 has `JR I00` after its test for state 8; Release 2
  has `CP 5 : JR NZ,I00` there (at $F263). While the creatures are frozen
  (a thing of kind 5 used), every state but the knight's is treated as
  state 0, still. State 5 is the knight's jump: Release 1 treats it as still
  too, so nothing counts the jump down and his controls (state 8) never
  come back -- the game locks up. *Played* in the simulator in both
  releases in stage 2: room 24, the kind-5 thing used, SPACE, then Q.
  Release 2: state 5 for eight passes, then 8, and he walked on. Release 1:
  state 5 for every pass after, and he never moved again
  ([`object-states.md`](object-states.md)).
- **`TELE`.** Release 1's (at $F0C3) has `LD C,$14` where Release 2 has `LD
  BC,$0014`, relying on B being 0 from the `LDIR` before it (and from
  $FEAB's `LD B,0` on the kind-9 path). To enter a room in Release 1 by
  jumping to its TELE, B must be set to 0 first.
- **Room 67.** Release 1 draws part 22, sets the object origin ($E4 $05)
  and draws part 51; Release 2 draws only part 22. Every other room and all
  56 parts are the same, the parts 7 bytes lower in Release 2.
- **Three door records** in the object table (its entries 235, 239 and 323,
  eleven-byte records) differ in one byte each, the eighth or the eleventh.
- **Everything else** that differs is leftover: the source text left in
  memory, the assembler's symbol table (whose values follow the code), and
  the loader's checksum.

The rooms, the parts but room 67, the sprites and the templates in use are
the same in both.

## How this was found

`fl_cmp.py` and `fl_align.py` (scratchpad) compared the three images and
aligned the differing regions; the room, part and object tables were
compared record by record with `fairlight_data.py`'s own walkers.

## Confidence

The identification of Krumlinde's release rests on every byte of code:
*compared*. The list of changes is complete for the loaded images:
*compared*. What the joystick and start-up changes do in play is *read*;
the lock-up is *played* in the simulator.

## Open questions

- Whether Release 1's switched-off joystick, or the freeze's lock-up, or
  both, were the reason for Release 2. (Stage 1's other question, what the
  state-5 change does in play, is answered above.)
