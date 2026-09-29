# Leftovers: what the tape carries besides the game

**Question this answers:** which bytes of the image are not the game, what
they are, and what the game's own unused bytes are.

**Short answer:** about 9 KB of the image is the development machine's
memory as it was when the tape was made: the author's assembler source text
in three runs (lines 3130-4940, the object table's source, across
$A8FC-$C47B; lines 12860-17190 across $C4BA-$DABF; lines 6240-6890 at
$617C-$64C0), all with the game's own bytes lying over the gaps; part of the
assembler's symbol table ($DD39-$DFF1, and two scraps from another state of
it); the loader's table, stack and failure routine; the ends of the ROM's
user-defined graphics; and some bytes nobody has identified. Among the
game's own bytes, three stretches between sprites and one after the parts
are unused.

## How it works

**The source text.** Each line is a carriage return, a two-byte line number
and the text with tabs between the fields. It is matched to the code by
searching the snapshot for the encoding of its instructions (`LD (IY+7),3`
found at $F54F, `LD A,247 : CALL INPUT` at $FEF1, and so on). The author's labels it gives are in
[`symbols.md`](symbols.md).

| Where | Lines | The source of |
|---|---|---|
| $617C-$639B (`SOURCE_AND_STACK`) | 6240-6670 | The end of the pick-up (WEI3, and calls of ROMM, DOE, SRP, INFOR) and the start of the keyboard and joystick reading (I88 on). The game's stack lives at its top |
| $639C-$64C0 (under `MASTER_OBJECTS`) | 6680-6890 | More of the keyboard reading, to INP5 and a little after |
| $A8FC-$A923 (`SOURCE_BEFORE_OBJECTS`) | 3130 | A DEFB line of the object table |
| $A924-$B67F (under `OBJECTS`) | 3140-3920 | The object table's DEFB lines, which the table copied over them repeats byte for byte |
| $B680-$B685 (`SOURCE_BEFORE_TITLE`) | | Six bytes of a DEFB line |
| $B734-$BAD7 (under `TEMPLATES`) | 3970-4180 | More DEFB lines |
| $BCA4-$BFFF (under `RECORDS`) | 4300-4510 | More, and the comment heading the table's second part |
| $C436-$C471 (end of `TUNE_VOICES`) | 4920-4940 | The table's last lines (DEFB 255) |
| $C4BA-$C4DF (`SOURCE_AFTER_START`) | 12860-12870 | Code that stores IY+$71 after an `AND 5`, labels BT32 and BT33: like `MEET_DECOY` ($FA83) but not line for line |
| $D135-$D2EF (`SOURCE_AFTER_OBJECTS`) | 15380-15690 | The end of `ROOMST` (a message's glyphs, `CALL MESS2`, `JP WAIT`) and `LOAD_ROOM` (ROS, OBJD, OB2; DATLEN = 20) |
| $D694-$DABF (`SOURCE_AFTER_TEMPLATES`) | 16370-17190 | The use-and-choose code of `MAIN_LOOP` (STAR2, ST3-ST9, ST20-ST22, STE3, USE4-USE6; calls of INPUT, EEN, TELE, INFO0, INFOR, PRINT) |

99 of the 101 whole DEFB lines are records of the object table, byte for
byte (*compared*, stage 1). The variable bases in the text: V = $FF80 (`V+18`
is $FF92), T = $FFE4 (`T+20` is $FFF8; `LD (T),HL` is `LD ($FFE4),HL` at
$FDA5).

**After the text at $639C** on the tape (from 293 bytes in) come bytes
that are not text: code, by the look of it, whose calls and jumps go to
addresses in $63xx-$67xx and which reads `LD HL,$5C6A`, a ROM system
variable -- something that ran at that address on the development machine.
Not identified. The master copy is laid over it at start-up.

**The symbol table** ($DD39-$DFF1, `SYMBOL_TABLE`): [`symbols.md`](symbols.md).
The scraps: $E026 (`SYMBOLS_AFTER_MESS2`) holds a whole node named I62
whose value is 43 more than the main table's I62 ($F354) -- two symbols of
one name cannot be in one tree, so an earlier state of the table: an
earlier assembly or an earlier pass. $E09A (`SYMBOLS_BEFORE_TEXTURES`)
reads as a node with flag 0 and a one-letter name, J, whose value is a jump
target in `CREATURE_UPDATE` ($F43C); the parse is uncertain.

**The loader's leftovers** ($DAC0-$DD38, never loaded from the tape):
`LOADER_TABLE` (its table of pieces, its stack, the checksum bytes),
`LOADER_CLEARED` (the turbo stage, cleared by itself: an `LD (HL),0 : LDIR`
whose own first byte is the last cleared, so the processor re-fetches it as
a `NOP` and runs on through `OR B` to the `RET` after, which pops $C47C --
488 bytes cleared, the last two not), `LOADER_FAILURE` ($DCC9: clear
$5B00 up to itself with `LDDR`, a 24-character line asking for the tape to
be rewound, bright flashing yellow on the bottom line, border black, BEEPER
233 times twice over, `RST 0`), and at $DD35 the decryption key and at
$DD36-$DD38 the countdown's counters ([`loading.md`](loading.md)).

**The ROM's user-defined graphics** (`UDG_LEFTOVERS`, $FF6A, and bytes
among the variables that nothing uses): the ends of the letters C, D and E,
which the ROM puts at the top of memory when it starts.

**Unused game bytes:**

| Where | Label | What |
|---|---|---|
| $5D14, 288 bytes | `TYPE48_FRAMES` | Not unused: frames 1 and 2 of type 48's strike (24 by 24), which the build's sessions never showed ([`object-states.md`](object-states.md)) |
| $689D, 19 bytes | `ZEROS_BEFORE_ROOMS` | Zeros between the master copy and the rooms; nothing reads them |
| $7CCB, 53 bytes | `BYTES_AFTER_PARTS` | Nine bytes that parse as drawing commands (not ended by $E5), then six groups of a byte and a word whose words are addresses inside the block: made for this address, perhaps a table from an earlier version. Nothing points at it |
| $8736, 36 bytes | `BYTES_AFTER_TYPE49` | Not a sprite at any width that divides it (the image's bits fall where the mask says the background shows); diagonal stripes 16 wide. Nothing points at it |
| $9E68, 96 bytes | `DIAGONAL_SPRITE` | A 24 by 16 sprite, image and mask agreeing: a thick diagonal shaft like a staff or lance. Nothing points at it |
| $EBF4, 1 byte | `BYTE_BEFORE_PRINT_CHAR` | A zero nothing reads |
| $FA74, 5 bytes | `SKIPPED_REMOVAL` | Code no jump reaches ([`meeting.md`](meeting.md)) |
| $E596, 1 byte | (in `ROOM_DEFAULTS`) | The 21st byte, not copied |

## How this was found

Stage 1 found the text by eye and the load map; stage 2 (range 1) decoded
the text line by line with a scratch script, read the line numbers, and
matched the text's instructions to the code by byte search. The loader:
disassembled from a snapshot stopped where its turbo stage starts
(`tap2sna --start 0xDADF`), and the failure routine from the game's
snapshot. The stretches between sprites: drawn as text at each width.
Type 48's +17 *measured* in room 45.

## Confidence

Line numbers and matches: *read*. The loader's end: *read*. $9E68 as a
sprite: *drawn*. $5D14: *read* and *measured* (range 3 staged the strike).

## Krumlinde

His `data_sections.md` calls $DC00-$E025 a "debug-menu table"; it is the
loader's cleared bytes, its failure routine and the symbol table. His $617C
text "artifact" is one of several stretches of the game's own source. His
decoration type 40, whose bitmap at $6104 he renders as noise and calls
invalid, is a 16 by 10 sprite the game draws (stage 1, *measured*).

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| `TYPE48_FRAMES` | `DATA5D14` | $5D14 | Type 48's strike frames |
| `SOURCE_AND_STACK` | `TEXT617C` | $617C | Source text; the stack at its top |
| `ZEROS_BEFORE_ROOMS` | `UNUSED689D` | $689D | 19 zeros |
| `BYTES_AFTER_PARTS` | `DATA7CCB` | $7CCB | Not identified |
| `BYTES_AFTER_TYPE49` | `DATA8736` | $8736 | Not identified |
| `DIAGONAL_SPRITE` | `DATA9E68` | $9E68 | An unused sprite |
| `SOURCE_BEFORE_OBJECTS` | `TEXTA8FC` | $A8FC | Source text |
| `SOURCE_BEFORE_TITLE` | `TEXTB680` | $B680 | Source text |
| `SOURCE_AFTER_START` | `TEXTC4BA` | $C4BA | Source text |
| `SOURCE_AFTER_OBJECTS` | `TEXTD135` | $D135 | Source text |
| `SOURCE_AFTER_TEMPLATES` | `TEXTD694` | $D694 | Source text |
| `LOADER_TABLE` | `DATADAC0` | $DAC0 | The loader's table and stack |
| `LOADER_CLEARED` | `SPACEDADF` | $DADF | The loader, cleared |
| `LOADER_FAILURE` | `DATADCC9` | $DCC9 | The loader's failure routine |
| `SYMBOLS_AFTER_MESS2` | `DATAE026` | $E026 | Symbol-table scrap |
| `SYMBOLS_BEFORE_TEXTURES` | `DATAE09A` | $E09A | Symbol-table scrap |
| `UDG_LEFTOVERS` | `DATAFF6A` | $FF6A | The ROM's UDGs |

## Open questions

- $7CCB and $8736: what they are. $9E68: whose picture.
- The code at $639C + 293 on the tape: which development tool.
- The symbol scraps: an earlier pass or an earlier assembly? The $E09A
  parse is uncertain.
