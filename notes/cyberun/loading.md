# Loading

**Question this answers:** what the tape holds, how the game gets from it
into memory, and what the loader leaves behind -- and what the game builds
over it when it starts.

**Short answer:** three standard-speed files. The BASIC loads a small block
at $6000 and calls it, which (among things not yet read) leaves a 16-byte
copy routine at $FC00, then loads the game at $5E80 and calls $5B80. That
entry moves the game down 512 bytes to $5C80 and rotates the whole block a
nibble with `RRD`, undoing a simple obfuscation, then jumps to $5C80: `DI`
and `JP start`. The start builds six pages of shift tables over the
loader's leftovers at $FA00-$FFFF, the landscape pieces' shifted copies,
and a bit-reversal table over its own start-up code.

## How it works

### The tape

| Block | Header | Loads at | Length |
|---|---|---|---|
| 1 | Program `CYBER` | -- | 141 |
| 2 | Bytes `PIC` | $6000 (24576) | 6990 |
| 3 | Bytes `CY` | $5E80 (24192) | 40300, to $FBEB |

The BASIC, one line: `LOAD "" CODE`, `RANDOMIZE USR 24576`, `LOAD "" CODE`,
`RANDOMIZE USR 23424`, plus a `CLEAR` and some `PRINT AT 19,0`s. *read*
(the tokens were decoded by hand; the CLEAR's value is still to be
checked).

### PIC

`PIC` starts with `LD HL,$6022 / LD DE,$FC00 / LD BC,16 / LDIR`, so its
first job is to put 16 bytes at $FC00 *read*. The rest of it (presumably
the loading picture) is not read: it lies at $6000-$7B4D, which the game
block loads over, so the disassembly never sees it.

The 16 bytes, as they stand in the snapshot:

| Address | Label | What |
|---|---|---|
| $FC00 | `loader_copy` | `LD HL,$5E80 / LD DE,$5C80 / LD BC,$9D80 / LDIR / RET`: the copy routine, 12 bytes |
| $FC0C | `loader_leftover` | `LD SP,$FE00 / DI`: the same as the first two instructions of the entry at $5B80, not run here; then what lies below the loader's stack |

### The entry

`loader_entry` ($5B80, 25 bytes, in the printer buffer where
`USR 23424` finds it) *read*:

```
$5B80 LD SP,$FE00 / DI / CALL $FC00    the block down 512 bytes to $5C80
$5B87 LD HL,$FA00 / XOR A / LD BC,$9E00
$5B8E RRD / DEC HL / DEC C / JR NZ / DJNZ   $9E00 bytes, from $FA00 down
$5B96 JP $5C80
```

The copy moves $9D80 (40,320) bytes from $5E80 to $5C80-$F9FF: the 40,300
the tape loaded and the 20 bytes after them. `RRD` moves the low nibble of
(HL) into A and A's old low nibble into the high nibble of (HL), so walking
down the block each byte becomes the low nibble of the byte above it and
its own high nibble: the whole block shifts four bits as one long number,
and the tape holds the game four bits out of step. The walk covers
$9E00 bytes, from $FA00 down to $5C01 -- one byte above the block and the
system variables from $5C01 below it, which is why those
(`basic_leftovers`, $5C41-$5C7F, nothing refers to them) look like
nonsense in the snapshot.

`game_entry` ($5C80): `DI / JP start`. Interrupts stay off for good.

### What the loader leaves at the top of memory

The snapshot is taken at $5C80, after the entry and before the game has
run, so the top of memory still holds the loader's work:

| From | To | Label | What |
|---|---|---|---|
| $FA00 | $FBFF | `shift_tables` | the top of the game block where it loaded (to $FBEB), left behind by the copy and not decoded |
| $FC00 | $FC0F | `loader_copy`, `loader_leftover` | PIC's 16 bytes |
| $FC10 | $FDFD | (in `loader_leftover`) | what lies below the loader's stack |
| $FDFE | $FDFF | `loader_stack` | $5B87: the return address pushed when the entry called the copy routine, left below the loader's stack pointer $FE00 |
| $FE00 | $FFFF | `loader_leftover_charset` | zeros, then a character set from the loading |

None of it is used: all of it is overwritten as the game starts.

### What the start builds over it

```
start $9A66            SP = $5B80; border black
  build_shift_tables $F86B
    $FA00-$FFFF        three pairs of pages, for shifts of 2, 4 and 6 bits:
                       page + n is n shifted right, the next page's byte n
                       the bits that fall off, at the top of a byte
    build_shifted_pieces $F7EB
                       the landscape pieces' copies shifted 2, 4 and 6
                       pixels, ORed into $E74A-$F0FA (zeros on the tape),
                       with shift_slope_piece $F939 and shift_flat_piece
                       $F8E2
    JP build_bit_reverse $F856
                       $F900-$F9FF: n with its bits reversed
  JP game
```

The start-up routines from $F7EB to $F9AB run once and are then reused as
memory:

| From | To | Label | After the start |
|---|---|---|---|
| $F800 | $F8FF | (starts inside a CALL's operand in `build_shifted_pieces`; `sprite_buffer_two` at $F880) | the sprite compositor's buffer, and the special beam's two frame buffers ($F800, $F880) |
| $F900 | $F9FF | `bit_reverse_table`, `bit_reverse_table_end` | the bit-reversal table, over the end of `shift_flat_piece` and all of `shift_slope_piece` |
| $FA00 | $FFFF | `shift_tables` | the shift tables, read by the sprite routines (B = $F8 + (x AND 6) picks a pair) and by `toggle_carried_part`, `clamp_climb` and `clamp_object_speed` |

The flat landscape pieces' copies are only partly made by the start; the
rest of them came on the tape already shifted.

The disassembly covers $5B00-$FFFF as the snapshot holds it, so the
listing shows the start-up code at $F7EB-$F9FF and the loader's leftovers
at $FA00-$FFFF; the HTML's memory maps and
[`memory-map.md`](memory-map.md) say what each becomes.

## How this was found

Stage 0 (2026-10-16): listed the TZX blocks with a scratch parser, decoded
the BASIC, then `tap2sna --start 23424` stopped the simulated load at the
entry, where the code above was read. Stopping instead at $5C80
(`--start 23680`) gives the image the game runs: compared with a snapshot
of the game in play, 18794 of the 20480 bytes from $A000 to $EFFF are the
same, the rest being variables and self-modified code *measured*. The
stage 2 description of the listing (2026-10-16) read the copy routine's
16 bytes, the leftovers above it and the start-up builders; the range-8
draft also ran `build_shift_tables` in SkoolKit's simulator on a copy of
the snapshot and listed every byte it changed ($E74A-$F0FA, $F900-$F9FF,
$FA00-$FFFF).

## Confidence

The entry and the copy routine are *read*; they ran only inside the
simulated load, which the build does not trace, but the snapshot after it
agrees. The start-up builders are *read* and *simulated*; they ran in
every session.

## Corrections

- Stage 0 said the RRD walk shifts "every byte from $FA00 down", meaning
  the block. It also covers $5C01-$5C7F, the system variables, which is
  why they are nonsense; and $FA00, one byte above the moved block.
- Stage 0 said PIC leaves "a copy routine at $FC00 (among other things not
  yet read)". Of the 16 bytes it copies, 12 are the copy routine and 4 a
  duplicate of the entry's first two instructions.
- In `cyberun.asm` the copy routine's `LD BC,$9D80` comes out as
  `LD BC,place_flicker_beam_3`: a length rendered as a label because an
  instruction happens to sit at $9D80. The `.skool` has the number; the
  annotation wants the operand kept as a number.

## Open questions

- What else `PIC` does: draw the loading screen (from 6,974 more bytes),
  and is any of it used later? Disassembling the `PIC` block on its own
  would settle it.
- The `CLEAR` value in the BASIC.
- `shift_flat_piece` makes only the first 12 rows of the flat pieces'
  shifted copies, the other 16 coming on the tape already shifted, and it
  patches two bytes afterwards ($EB34 = $5C, $EC30 = $40). Why the
  shifted copies are part-made and part-stored is not known.
