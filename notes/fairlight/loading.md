# Loading

**Question this answers:** what is on the tape, how the loader gets the
game into memory, what it checks, and where the game begins.

**Short answer:** a BASIC program carrying the Alkatraz Protection System's
loader (June 1985), a 3092-byte block and a 48538-byte block, the last two
at a turbo speed. The loader decrypts itself in layers, loads the loading
screen a line at a time in its own order and the game in pieces, XORing
every byte with a key that changes as it goes, checks a checksum, clears
itself and returns to **$C47C**, the game's first instruction. The build
stops there (`tap2sna --start 50300`), and redoes the decryption itself on
the tape's block to check the snapshot (`check_loader()`).

## The blocks

`tapinfo` on each tape (*read*):

| Release 1 | Release 2 | What |
|---|---|---|
| -- | `FL` BASIC, LINE 1, 219 bytes | Clears the screen, prints a warning against copying, `LOAD ""` |
| BASIC (name hidden by control codes), LINE 0, 1373 bytes | the same | The loader |
| turbo, 3092 bytes | turbo, 3092 bytes | The loader's second stage |
| turbo, 48538 bytes | turbo, 48538 bytes | The loading screen and the game |

The two releases' turbo blocks have different timings (pilot and sync
pulses) and differ in content (the game changed; see
[`versions.md`](versions.md)).

The loader's BASIC (`tapinfo -b`, *read*): a line-0 REM whose control
codes print the protection system's name and date; POKEs that hide the
listing; a check that the program starts where a bare 48K Spectrum puts it
(PROG = 23755) -- with an Interface 1's maps paged in it would not, and the
program asks for a rewind and resets; the screen coloured, "LOADING" and a
counter printed on the bottom line; and `RANDOMIZE USR 24194` ($5E82), into
machine code held in a second REM.

## The stages

What tap2sna's simulated load ran, from its trace and from snapshots taken
at each stage's first instruction (*measured*):

1. **$5E82**, in the BASIC: XORs the 851 bytes from $5E9C with the ROM's
   bytes from $1399, then goes through further layers of its own (the loops
   at $5E8F, $5F01, $6000), and puts a second stage at $D115-$D2AD.
2. **$D128**: loads the 3092-byte block over $D125-$DD38 (*inferred* from
   which bytes change and the block's length) and decrypts it in place.
3. **$DADF**, the turbo loader. It pushes the addresses of the 216 lines of
   the loading screen -- per character row, from the top, the attribute
   row and then the eight pixel lines -- and pops them as it loads, 32
   bytes each, so the picture appears a band at a time. Then it pops a
   table of pieces from $DAC3: the first piece (14 bytes at $DAC9) extends
   that very table ahead of where it is being read, and the others are the
   game, $5B00-$DABF (32704 bytes) and $DD39-$FFFF (8903 bytes), and 3
   bytes at $DAD9: the address the loader's last `RET` goes to, $C47C, and
   the checksum byte. A two-byte header, $03F6, comes first
   and is checked. While it loads, a countdown is drawn over the bottom of
   the loading screen, in the ROM's characters.

   Each byte read from the tape, L, is stored at IX as
   `key XOR D XOR E XOR IXh XOR IXl XOR L`, where DE counts down the bytes
   left in the piece. After each byte the key (at $DD35) gains $67, and
   before that $8A + E - D when bit 4 of E is set. A running sum of the
   bytes as read from the tape, before decryption, is kept at $DADC, and H
   keeps the last of them. (*read*, from the loader's code at
   $DB41-$DB89; *measured*: `check_loader()` does exactly this with the key
   and table taken from a second simulated load stopped at $DADF, and the
   result is the snapshot's $5B00-$DABF and $DD39-$FFFF, byte for byte. The
   16 bytes of the screen it does not match are the countdown's digits.)
4. **$DCB2**: the checksum test, `LD A,H : ADD A,($DADB) : CP ($DADC)` --
   the last byte read, plus the decrypted checksum byte the last piece put
   at $DADB, against the running sum: so the decrypted checksum byte must
   equal the sum of every tape byte before it (*read*, stage 3, from the
   loader in a snapshot stopped at $DADF). If it fails, the loader jumps to
   $DCC9 (`LOADER_FAILURE`), which clears memory from itself down to $5B00,
   prints a line asking for the tape to be rewound, and resets. If it
   holds, it clears $DADF-$DCC8 -- itself -- and its `RET` pops the last
   piece's first two bytes, $C47C ([`leftovers.md`](leftovers.md) has how
   the clearing runs on through its own last instruction). The failure
   routine and the loader's table and stack remain in the snapshot at
   $DAC0-$DADE and $DCC9-$DD38; the tape never loads those bytes.

## The hand-over

**$C47C** (`START`, Release 2, *read* and *measured*): `LD HL,$639A : LD
SP,HL`; `CALL $C000`, which plays a two-voice tune on the beeper over the
loading screen (calling the ROM's KEY-SCAN between notes) until a key is
pressed ([`loading-tune.md`](loading-tune.md)); `LD IY,$FF80`; `DI`, for
the rest of the game; then the copies (*read*; *measured* in the simulator
by stepping until the bytes at $A924, $B734, $639C first changed):

| From | To | Bytes | What |
|---|---|---|---|
| $C4E0 | $A924 | 3420 | The object table, and what follows it |
| $D2F0 | $B734 | 932 | The object templates and the patches |
| $A924, $FF80, $BC90 | $639C | 1200 + 61 + 20 | The master copy a new game restores |

and `JP $F065`, the title screen. The tape's own bytes at $A924, $B734 and
$639C are leftover source text ([`memory-map.md`](memory-map.md)).

Release 1 is different here: its $C47C sets SP to $6392, calls the tune and
jumps to $F065, where the same copies are made at the start of the title
routine instead ([`versions.md`](versions.md)).

The game runs with **interrupts off**. The tune's routine turns them off
($C00B) while it plays and on ($C018) as it returns, and `START` turns them
off again three instructions later ($C487), for good: no other `EI` is in
the game (*read*; *measured*: IFF stays clear in the simulator and the
ROM's frame counter never moves). It has to: the sprites at $5B00 up lie
over the ROM's system variables. See [`start-up.md`](start-up.md).

## How this was found

tap2sna's plain simulated load stopped at the end of the tape, at $DBF6, in
the loader. Continuing that snapshot in SkoolKit's simulator showed it
return to $C47C and call $C000 in a loop with the ROM's KEY-SCAN
([`journal.md`](journal.md)); `tap2sna --start 0xC47C` then gave the
snapshot. `--sim-load-config accelerator=list` names the accelerator used:
`alkatraz`. A trace (`--sim-load-config trace=`, with IX in each line)
gave, from every execution of the store at $DB66, the address of each byte
loaded: the load map above.

## Confidence

- The decryption and the load map: *measured*, every byte, every build.
- The stage addresses: *measured* (snapshots at each stage's first
  instruction); the 3092-byte block's address is *inferred*.
- What the BASIC does: *read*.
- The checksum test and the loader's end: *read* (stages 2 and 3).

## Disassembly corrections

- Stage 1 said `START`'s tune "then enables interrupts" and that the game
  runs with interrupts on, in IM 1, the ROM's routine fifty times a second,
  *measured* by the sessions. Wrong: `START` turns them off at $C487, three
  instructions after the tune's `EI`, and the sessions only offered
  interrupts that were never taken. Found in stage 2 (range 1) by reading
  `START` and measuring IFF and FRAMES in the simulator.
- Stage 1 called the last piece "3 bytes of its checksum": they are the
  loader's return address ($C47C) and one checksum byte.

## Open questions

- The first stage's later layers ($5F01, $6000) are not described step by
  step. Nothing depends on it; the load map is measured.
