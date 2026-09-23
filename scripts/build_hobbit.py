"""Disassemble The Hobbit (1982, Melbourne House / Beam Software) from its tape
into a loadable .sna + .sld pair for source-level debugging.

Like Atic Atac (scripts/build_aticatac.py) there is no published .skool source
for this game, so the disassembly is produced here from the tape itself. Three
things about this one are worth knowing before reading the code.

THE TAPE IS NOT PROTECTED, WHICH IS THE EASY PART. The BASIC loader is

     5 CLEAR 24575
    10 BORDER 0: PAPER 0: IF 0: CLS
    20 POKE 23659,0: PRINT AT 22,0;;
    30 LOAD "p" CODE 16384
    40 POKE 23659,0: PRINT AT 22,0;;
    50 LOAD "h" CODE
    60 PRINT USR 27648

so there is exactly one payload: the 40000-byte block "h", loaded at its
header address 24576 ($6000) and reaching to $FC3F, with the entry point at
27648 ($6C00). The bytes on the tape are the bytes the game runs, so no
decryptor has to be executed first to get a plaintext image.

The POKE 23659,0 either side of a LOAD is what hides the loader: zeroing DF-SZ
tells the ROM there are no lower-screen lines, so the "Bytes: p" message has
nowhere to print. Note also that line 30 loads the title picture to 16384 --
straight onto the screen -- even though the tape header says 32768. LOAD ...
CODE with an address overrides the header, so the picture costs the game
nothing but the tape it is stored on.

SEPARATING CODE FROM DATA IS THE HARD PART. Of the 40000 bytes, a large
fraction is Veronika Megler's database -- locations, objects, messages and the
line-drawn pictures -- and a static heuristic pass reads a great deal of that
as plausible-looking instructions. So, as with Atic Atac, this script *plays
the game* in SkoolKit's Z80 simulator and records the address of every
instruction actually executed, which is a code map that cannot contain a false
positive.

Unlike Atic Atac, mashing keys at random gets nowhere here: the game wants
sentences. WALKTHROUGH below is therefore typed in, one character at a time,
through the same port reads a real keyboard would produce. It is chosen to walk
the parser through its whole repertoire -- verbs, adjectives, adverbs,
prepositions, conjunctions, the pronoun IT, a character addressed by name -- as
much as to make progress in the story, because it is the parser and the
dispatcher that most need marking as code.

THE DICTIONARY, which is what the disassembly starts from. $6000 holds a
26-entry index (one 2-byte offset per initial letter, relative to $6000; X and
Z are zero because no word starts with them), and the word list itself runs
from $6040. Each entry is one 5-bit letter code per byte, A=1..Z=26, 0 for
none:

  - bytes 0 and 1 are always letters, because their top bits carry more: bits
    5-6 of each, taken together, are the word's four-bit class, and bit 7 of
    byte 1 marks a word that can take an -s -- so bit 7 there is not a
    terminator;
  - from byte 2 on, bit 7 marks the last letter of the word;
  - if that terminator also has bit 6 set, two more bytes follow: an offset
    from $6000 to another entry, and the word is a synonym of that one.

The synonyms are what prove the format rather than merely fitting it: every one
of the links lands exactly on another entry's first byte, and they say GET ->
TAKE, HIT -> ATTACK, KILL -> ATTACK, CAPTURE -> ATTACK, I -> INVENTORY, L ->
LOOK, D -> DOWN, E -> EAST, EVERYTHING -> ALL, BUT -> EXCEPT. An accident does
not produce that. The indexed list is 355 words in $6040-$67AA, ending exactly
where the Y bucket's one word, YOU, ends. decode_words() implements the format
and dictionary_blocks() turns it into control-file blocks, so every word in the
disassembly is named in a comment beside its own bytes.

The list is grouped by initial letter but only loosely sorted within a group
(BLOW before BLOOD, BOG before BODY, HELP before HEART), so lookup has to be a
linear scan of the bucket rather than a binary search. That is a fact about the
game, not a decoding error: those pairs were checked byte by byte.

A SECOND word list follows the indexed one at $67AB, running up the alphabet
again in the same letter encoding but with different class bits, and nothing in
the 26-letter index points into it. It is the vocabulary the game's messages are
composed from, as against the one it searches when you type: PRINT_WORD ($74BA)
is handed a 12-bit offset from $6000 and expands whatever entry it lands on, so
no pointer to the list's start exists anywhere and its words are only ever named
individually. Found with a read watchpoint over the range -- it stays untouched
through the opening, LOOK and INVENTORY, and is first read on a command that
composes a sentence about an object.

decode_words still stops at the boundary, because the two lists do not share a
part-of-speech encoding and running on labels 133 of them wrongly.

PRINT_WORD is also the authority for the rule above: it stops on a byte with bit
7 set unless only two letters have been emitted, which is the game's own way of
saying that the first two bytes carry class bits rather than a terminator.

THE CORRECTNESS SIGNAL. There is no reference disassembly to diff against, but
there is a better check than "it assembled": the .asm is fed back through
sjasmplus and the resulting bytes are compared against the loaded memory image
the disassembly was made from, byte for byte, before any .sna is written.

The game and everything built from it is copyrighted (Beam Software / Melbourne
House, 1982). Same treatment as the other games here: built locally under
game_disassembly/, gitignored, never committed. That output now includes the
game's text: the messages are decoded so that each one's words can be shown
beside its bytes, and like the bytes that stays in the local build. This
script and the annotations carry the decoder and at most a few words quoted to
identify a structure, never the messages themselves. Prior work consulted for addresses, and credited rather than copied:
pobtastic's SkoolKit disassembly at skoolkit.arcadegeek.co.uk/hobbit, the
data-format notes at icemark.com/dataformats/hobbit, and a complete annotated
SkoolKit disassembly of the v1.0 tape by an author it does not name, which
carries no licence for its annotations and so is used the same way as the
others: to know what exists and where to look, never as text to copy. It
documents v1.0, which is 37,888 bytes against this one's 40,000, so its
addresses do not transfer and everything here is re-derived against v1.2
anyway -- the two disagree about where almost everything lives.

Requires `skoolkit` (pip install skoolkit) and sjasmplus -- this repo ships one
at tools/sjasmplus/, which is used automatically.

Usage:
    python scripts/build_hobbit.py --tape "path/to/Hobbit v1.2.tzx"
"""
from __future__ import annotations

import argparse
import contextlib
import functools
import io
import re
import struct
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from sna import RAM_SIZE, Registers, write_sna

PROJECT_ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = PROJECT_ROOT / "game_disassembly" / "hobbit"
# Hand-written comments, layered over the generated control file. Source, not
# output: addresses and prose only, so it is committed rather than gitignored.
ANNOTATIONS = PROJECT_ROOT / "scripts" / "hobbit_annotations.ctl"
REF = PROJECT_ROOT / "scripts" / "hobbit.ref"
ROM = PROJECT_ROOT / "roms" / "48.rom"
SJASMPLUS = PROJECT_ROOT / "tools" / "sjasmplus" / "sjasmplus.exe"

# The one payload block: "h", 40000 bytes at $6000, entered at $6C00.
LOAD_ADDR = 0x6000
ENTRY = 0x6C00
GAME_END = 0xFC40
# The dictionary: a 2-byte offset per initial letter at $6000, the packed word
# list from $6040. Entry 0 is unused and 27-31 are zero padding, so the table is
# read as 32 words and only 1..26 mean anything.
WORD_INDEX = 0x6000
WORD_INDEX_ENTRIES = 32
WORD_LIST = 0x6040

# BASIC's stack lives just under RAMTOP, which CLEAR 24575 put at $5FFF, and the
# game is entered from BASIC by PRINT USR with interrupts on and IY still
# pointing at the system variables.
STACK = 0x5FF0
SYSVARS = 0x5C3A

TSTATES_PER_SECOND = 3500000
NEWLINE = chr(10)

LETTERS = " ABCDEFGHIJKLMNOPQRSTUVWXYZ"

# A word's class: bits 5-6 of its first byte, then bits 5-6 of its second,
# read as one four-bit number. It is what the tokeniser puts in the top nibble
# of each token -- every one of eighteen tokens captured from real sentences
# carried exactly the class this predicts -- and bit 7 of the second byte is
# not part of it: that marks the words PRINT_WORD may give an -s, which is why
# an earlier reading of three bits made verbs look unlike every other class.
# The names say what each class holds; 0, 2, 3, 5, 7, 8 and $A were also seen
# as tokens.
WORD_CLASSES = {
    0x0: "adverb",
    0x1: "in or into",
    0x2: "direction",
    0x3: "verb",
    0x4: "verb of motion",
    0x5: "noun",
    0x6: "adjective",
    0x7: "preposition",
    0x8: "article or the like",
    0x9: "quantifier, pronoun or game command",
    0xA: "and",
    0xB: "then",
}


def _log(message: str) -> None:
    print(message, flush=True)


# --------------------------------------------------------------------------
# Step 1: load the tape to get the memory image.
# --------------------------------------------------------------------------

@functools.lru_cache(maxsize=None)
def _read_snapshot(path: str) -> tuple:
    from skoolkit.snapshot import Snapshot

    return tuple(Snapshot.get(path).memory)


def game_memory(snapshot: Path) -> tuple:
    """The snapshot's 64K, read once and shared. Read-only."""
    return _read_snapshot(str(snapshot))


def machine_memory(snapshot: Path) -> list:
    """A fresh, writable 64K with the ROM in place, for running the game."""
    from skoolkit import read_bin_file

    memory = list(game_memory(snapshot))
    memory[:0x4000] = read_bin_file(str(ROM))
    return memory


def make_snapshot(tape: Path, out: Path) -> None:
    """Simulate the real LOAD, stopping when the loader reaches the game."""
    from skoolkit import tap2sna

    _log(f"Loading {tape.name} (simulated LOAD of the loader, \"p\" and \"h\")...")
    # tap2sna resolves its input as a URL, so a Windows path like C:\... is read
    # as scheme "c" and rejected. as_uri() gives it a file:// URL it
    # understands, with spaces and parentheses escaped.
    with contextlib.redirect_stdout(io.StringIO()):
        tap2sna.main(["--start", str(ENTRY), tape.resolve().as_uri(), str(out)])
    if not out.exists():
        sys.exit(f"error: tap2sna did not write {out}")
    memory = game_memory(out)
    if all(b == 0 for b in memory[ENTRY:ENTRY + 16]):
        sys.exit(f"error: nothing loaded at 0x{ENTRY:04X} -- wrong tape?")


# --------------------------------------------------------------------------
# Step 2: the dictionary, decoded.
# --------------------------------------------------------------------------

class Word:
    """One dictionary entry: where it is, what it says, and what it is."""

    def __init__(self, address: int, length: int, text: str,
                 cls: int, synonym_of: int | None):
        self.address = address
        self.length = length
        self.text = text
        self.cls = cls
        self.synonym_of = synonym_of

    @property
    def part_of_speech(self) -> str:
        return WORD_CLASSES.get(self.cls, f"class ${self.cls:X}")


def word_index(memory) -> list[int]:
    """The 32 raw offsets at $6000. Zero means no word starts with that letter."""
    return [struct.unpack("<H", bytes(memory[WORD_INDEX + 2 * i:
                                             WORD_INDEX + 2 * i + 2]))[0]
            for i in range(WORD_INDEX_ENTRIES)]


def decode_words(memory) -> list[Word]:
    """Every entry in the packed word list, in tape order.

    There is no count and no terminator. What ends the list is that a second
    one starts: past the last letter bucket the initial letters step backwards
    to A and run up the alphabet again, in entries whose class bits are not
    the ones the indexed list uses. So the first backwards step after the last
    bucket is the boundary, and everything from there is left alone -- see
    SECOND_LIST. Walking on regardless decodes 133 entries of the second list
    with the wrong part of speech and then two entries of whatever follows it
    as garbage, which is how this was noticed.

    The bucket offsets and the synonym links are checked against the entry
    boundaries afterwards rather than trusted.
    """
    index = word_index(memory)
    last_bucket = WORD_INDEX + max(index[1:27])
    words, address = [], WORD_LIST
    previous_initial = ""
    while address < GAME_END - 4:
        start = address
        codes = [memory[address] & 0x1F, memory[address + 1] & 0x1F]
        cls = ((memory[address] >> 5) & 3) * 4 + ((memory[address + 1] >> 5) & 3)
        address += 2
        synonym_of = None
        while address < GAME_END:
            byte = memory[address]
            address += 1
            codes.append(byte & 0x1F)
            if byte & 0x80:
                if byte & 0x40:
                    synonym_of = WORD_INDEX + struct.unpack(
                        "<H", bytes(memory[address:address + 2]))[0]
                    address += 2
                break
        text = "".join(LETTERS[c] if c < len(LETTERS) else "?"
                       for c in codes).strip()
        # Only an entry at or past the last bucket can be the one that ends the
        # list; inside the buckets, a non-word or a backwards letter would mean
        # the decode is wrong, and check_dictionary wants to say so rather than
        # have it quietly swallowed here.
        if start >= last_bucket:
            if not text.isalpha():
                break
            if previous_initial and text[0] < previous_initial:
                break
        previous_initial = text[0] if text else previous_initial
        words.append(Word(start, address - start, text, cls, synonym_of))
    return words


def check_dictionary(memory, words: list[Word]) -> None:
    """The decode's own proof: buckets and synonyms must land on entries.

    Both checks are all-or-nothing on purpose. A rule that is nearly right puts
    most words in the right place and quietly corrupts the rest, so "every
    bucket" and "every synonym" are the only results that rule that out.
    """
    index = word_index(memory)
    starts = {word.address: word for word in words}

    for i in range(1, 27):
        if not index[i]:
            continue
        address = WORD_INDEX + index[i]
        word = starts.get(address)
        if word is None:
            sys.exit(f"error: letter {LETTERS[i]} points at 0x{address:04X}, "
                     f"which is not the start of an entry")
        if not word.text.startswith(LETTERS[i]):
            sys.exit(f"error: letter {LETTERS[i]} points at {word.text!r}")
    buckets = sum(1 for i in range(1, 27) if index[i])
    missing = [LETTERS[i] for i in range(1, 27) if not index[i]]
    _log(f"  {len(words)} words; all {buckets} letter buckets land on entry "
         f"starts (nothing begins {', '.join(missing)})")

    synonyms = [w for w in words if w.synonym_of is not None]
    for word in synonyms:
        if word.synonym_of not in starts:
            sys.exit(f"error: {word.text} redirects to 0x{word.synonym_of:04X}, "
                     f"which is not the start of an entry")
    examples = ", ".join(f"{w.text}->{starts[w.synonym_of].text}"
                         for w in synonyms[:4])
    _log(f"  {len(synonyms)} synonyms, every one landing on an entry start "
         f"({examples}, ...)")


def dictionary_blocks(memory) -> tuple[str, list[tuple[int, int]]]:
    """Control-file blocks for the index and the word list."""
    words = decode_words(memory)
    check_dictionary(memory, words)
    starts = {word.address: word for word in words}
    end = words[-1].address + words[-1].length
    index = word_index(memory)

    out = ["; Generated by scripts/build_hobbit.py -- do not edit.", ""]
    out += [
        "@ $6000 label=WORD_INDEX",
        "b $6000 Dictionary: index by initial letter",
        "D $6000 One 2-byte offset per letter, relative to the start of this "
        "table, to the first word beginning with it. Entry 0 is unused; "
        "entries 27-31 are padding.",
    ]
    # One directive per entry rather than a single W covering all 64 bytes:
    # inside a data block a `  $ADDR,N` comment implies a sub-block of its
    # own, which would overlap the wider directive and be reported as such.
    out.append("W $6000,2")
    out.append("  $6000,2 Entry 0: unused")
    # The comment gives the offset as stored and the word it reaches, not the
    # absolute address: skool2asm tries to turn a $XXXX in a comment into a
    # label, and warns about every one it cannot place -- which is all of them
    # here, since these point into the middle of a data block.
    for i in range(1, 27):
        address = WORD_INDEX + 2 * i
        out.append(f"W ${address:04X},2")
        if index[i]:
            first = starts[WORD_INDEX + index[i]].text
            out.append(f"  ${address:04X},2 {LETTERS[i]}: "
                       f"+{index[i]}, first word {first}")
        else:
            out.append(f"  ${address:04X},2 {LETTERS[i]}: no words")
    out.append(f"W ${WORD_INDEX + 54:04X},10")
    out.append(f"  ${WORD_INDEX + 54:04X},10 Entries 27-31: padding, all zero")
    out += [
        "",
        "@ $6040 label=WORD_LIST",
        "b $6040 Dictionary: the words",
        "D $6040 One 5-bit letter code per byte (A=1..Z=26, 0 for none). Bits "
        "5-6 of the first two bytes together are the word's class, the top "
        "nibble of its token, and bit 7 of the second byte marks a word that "
        "can take an -s, so bit 7 is not a terminator there; from the third "
        "byte on, bit 7 marks the last letter. A terminator with bit 6 set is followed by a 2-byte "
        "offset, from the start of the index table, to the entry this word is "
        "a synonym of.",
    ]
    for word in words:
        note = word.part_of_speech
        if word.synonym_of is not None:
            note += f", synonym of {starts[word.synonym_of].text}"
        out.append(f"B ${word.address:04X},{word.length},{word.length}")
        out.append(f"  ${word.address:04X},{word.length} {word.text} ({note})")
    out.append("")
    return NEWLINE.join(out) + NEWLINE, [(WORD_INDEX, end)]


# --------------------------------------------------------------------------
# Step 2b: the pictures, decoded.
# --------------------------------------------------------------------------

# The picture table: L9DBD's format, [location, lo, hi] records ending at a
# location of $FF, each pointing at that location's picture stream.
PICTURE_TABLE = 0xCC00
# The action table, keyed by the action code in $B6E7: codes 1-10 are the
# directions, all handled by MOVE; the rest have handlers of their own.
ACTION_TABLE = 0xC730
# The sentence each action code stands for: 8-byte patterns, the code being
# the pattern's place, counted from 1.
ACTION_PATTERNS = 0xAB53
# The object index: every object and every character, keyed by object number.
OBJECT_INDEX = 0xC063


def keyed_table(memory, base: int) -> list[tuple[int, int, int]]:
    """[key, lo, hi] records up to a key of $FF, as L9DBD searches them."""
    records, address = [], base
    while memory[address] != 0xFF:
        records.append((memory[address],
                        memory[address + 1] | (memory[address + 2] << 8),
                        address))
        address += 3
    return records


def picture_boundaries(memory, start: int) -> list[int]:
    """Every opcode RUN_PICTURE visits in a stream, header skipped, to $00.

    The grammar is RUN_PICTURE's own, in its own order of tests: $00 ends,
    $08 moves (three bytes), bit 7 draws a line (two), bit 6 fills (three),
    and bit 5 paints attributes (three, then path items to an $FF).
    Anything else it skips a byte at a time -- and no real stream has one.
    """
    address, visited = start + 2, []
    while True:
        visited.append(address)
        op = memory[address]
        if op == 0x00:
            return visited
        if op == 0x08:
            address += 3
        elif op & 0x80:
            address += 2
        elif op & 0x40:
            address += 3
        elif op & 0x20:
            address += 3
            while memory[address] != 0xFF:
                address += 1
            address += 1
        else:
            address += 1


COLOURS = ["black", "blue", "red", "magenta", "green", "cyan", "yellow", "white"]


def picture_commands(memory, start: int, stop: int) -> list[str]:
    """A stream's header and each of its commands on a line of its own, in
    words, as RUN_PICTURE reads them.

    The header is the border colour and the attribute the canvas starts as.
    Then: $08 moves the pen to x, y; a byte with bit 7 draws a line -- its
    bits 0-2 the direction (bit 0 mostly vertical, bit 1 down, bit 2 left),
    the second byte's bits 0-5 the length less one, and the minor-axis step
    every n pixels, n less one being the first byte's bits 2-5 above the
    second's bits 6-7; bit 6 fills from x, y in the colour in bits 0-2; bit 5
    paints attributes in that colour along a path from an attribute address,
    stored high byte first, to an $FF; $00 ends. y is measured up from the
    bottom of the 128-line canvas.
    """
    out = [f"B ${start:04X},1,1", f"  ${start:04X},1 Border: {COLOURS[memory[start] & 7]}",
           f"B ${start + 1:04X},1,1",
           f"  ${start + 1:04X},1 The canvas starts {COLOURS[(memory[start + 1] >> 3) & 7]} "
           f"paper, {COLOURS[memory[start + 1] & 7]} ink"]
    for address in picture_boundaries(memory, start):
        if address >= stop:
            break
        op = memory[address]
        if op == 0x00:
            out += [f"B ${address:04X},1,1", f"  ${address:04X},1 End of the picture"]
            break
        if op == 0x08:
            length, text = 3, f"MOVE to {memory[address + 1]}, {memory[address + 2]}"
        elif op & 0x80:
            second = memory[address + 1]
            pixels = (second & 0x3F) + 1
            every = ((((op >> 1) & 0x3C) | (second >> 6)) + 1)
            across = "left" if op & 4 else "right"
            updown = "down" if op & 2 else "up"
            main, side = (updown, across) if op & 1 else (across, updown)
            if every == 1:
                how = f"diagonally {main} and {side}"
            else:
                how = f"{main}, stepping {side} every {every}"
            length, text = 2, f"LINE of {pixels} pixel{'s' if pixels != 1 else ''} {how}"
        elif op & 0x40:
            length = 3
            text = f"FILL with {COLOURS[op & 7]} from {memory[address + 1]}, {memory[address + 2]}"
        elif op & 0x20:
            length = 3
            while memory[address + length] != 0xFF:
                length += 1
            length += 1
            cell = ((memory[address + 1] << 8) | memory[address + 2]) - 0x5800
            text = (f"PAINT {COLOURS[op & 7]} ink from row {cell // 32}, column {cell % 32}, "
                    f"along a path of {length - 4} step{'s' if length - 4 != 1 else ''}")
        else:
            length, text = 1, "Skipped: not a command"
        if address + length > stop:
            length = stop - address
            text += " -- its last bytes are the next picture's start"
        out += [f"B ${address:04X},{length},{length}", f"  ${address:04X},{length} {text}"]
    return out


def picture_blocks(memory) -> tuple[str, list[tuple[int, int]]]:
    """Control-file blocks for the picture table and every stream it names.

    Two pairs of pictures overlap. Location 13's stream steps exactly onto
    location 31's first opcode and from there both walk the same opcodes to a
    shared $00, and 5 does the same with 28: the outer picture draws a few
    extra things and then runs straight on into the other's whole drawing. The
    inner picture's two header bytes are, from the outer one's point of view,
    the operands of its last private opcode. A disassembly cannot put two
    blocks over the same bytes, so the outer is described up to the point
    where it runs on, and says where it goes.
    """
    records = keyed_table(memory, PICTURE_TABLE)
    streams = []
    for location, start, _ in records:
        visited = picture_boundaries(memory, start)
        end = visited[-1] + 1
        counts = {"move": 0, "line": 0, "fill": 0, "paint": 0}
        for address in visited[:-1]:
            op = memory[address]
            kind = ("move" if op == 0x08 else "line" if op & 0x80 else
                    "fill" if op & 0x40 else "paint" if op & 0x20 else None)
            if kind:
                counts[kind] += 1
        streams.append((start, end, location, counts, set(visited)))
    streams.sort()

    table_end = PICTURE_TABLE + 3 * len(records) + 1
    out = ["; Generated by scripts/build_hobbit.py -- do not edit.", ""]
    out += [
        f"@ ${PICTURE_TABLE:04X} label=PICTURE_TABLE",
        f"b ${PICTURE_TABLE:04X} Pictures: which locations have one, and where",
        f"D ${PICTURE_TABLE:04X} {len(records)} records of a location number and "
        f"the address of its picture stream, ending at a location of $FF. "
        f"Searched by L9DBD, which walks it in order, so it does not need to "
        f"be sorted and is not.",
    ]
    for location, start, address in records:
        out.append(f"B ${address:04X},3,3")
        out.append(f"  ${address:04X},3 Location {location}")
    out.append(f"B ${table_end - 1:04X},1,1")
    out.append(f"  ${table_end - 1:04X},1 End of the table")
    out.append("")

    spans = [(PICTURE_TABLE, table_end)]
    for i, (start, end, location, counts, visited) in enumerate(streams):
        # The next stream by address may begin inside this one: that is the
        # overlap, and this block stops where the other takes over.
        inner = next((s for s, e, *_ in streams[i + 1:]
                      if start < s < end and s + 2 in visited), None)
        stop = inner if inner else end
        label = f"LOC{location}_PIC"
        summary = ", ".join(f"{n} {k}{'s' if n != 1 else ''}"
                            for k, n in counts.items() if n)
        out.append(f"@ ${start:04X} label={label}")
        rooms = room_records(memory)
        where = name_of(memory, rooms[location]["start"] + 2) if location in rooms else "?"
        out.append(f"b ${start:04X} Picture for location {location}: {where}")
        # The picture, as the game draws it: hobbit_pages.py renders it into
        # the HTML's images on each --html build. Only the HTML shows it.
        out.append(f"D ${start:04X} #HTML(<img src=\"../images/locations/{location:02d}.gif\" "
                   f"width=\"512\" height=\"256\" style=\"image-rendering: pixelated\" "
                   f"alt=\"{where}\"/><br/>As the game draws it, at the speed it draws it, "
                   f"pausing on the finished picture before it starts again.)")
        partner = (next(loc for s, _, loc, *_ in streams if s == inner)
                   if inner else None)
        ending = (f"counting the part it shares with location {partner}, and "
                  f"ending at the $00 the two have in common" if inner
                  else "ending at $00")
        out.append(f"D ${start:04X} A border colour and a starting attribute, "
                   f"then {summary}, {ending}.")
        if inner:
            out.append(f"D ${start:04X} Runs on into location {partner}'s "
                       f"picture rather than ending: the last opcode here "
                       f"takes that picture's border and attribute bytes as "
                       f"its operands, and from its first opcode on the two "
                       f"are one stream.")
        out += picture_commands(memory, start, stop)
        out.append("")
        spans.append((start, stop))
    return NEWLINE.join(out) + NEWLINE, spans


def object_records(memory) -> list[dict]:
    """Every object record, parsed by the grammar FIND_OBJECT_HANDLER uses.

    A record is a 16-byte head; byte 0 of it is the length of a list that
    follows the head; and after the list comes a FIND_RECORD table of
    [action, lo, hi] triples ending at $FF -- the object's own handlers.
    FIND_OBJECT_HANDLER ($9B81) states it outright: it adds byte 0 and 16 to
    IX and calls FIND_RECORD. The proof that nothing is missing is that every
    record, parsed this way, ends exactly where the next begins, and the last
    exactly where the action table starts.
    """
    records = []
    for number, start, _ in keyed_table(memory, OBJECT_INDEX):
        listed = memory[start]
        address = start + 16 + listed
        handlers = []
        while memory[address] != 0xFF:
            handlers.append((address, memory[address],
                             memory[address + 1] | (memory[address + 2] << 8)))
            address += 3
        records.append({"number": number, "start": start, "listed": listed,
                        "handlers": handlers, "end": address + 1})
    records.sort(key=lambda r: r["start"])
    for record, following in zip(records, records[1:]):
        if record["end"] != following["start"]:
            sys.exit(f"error: object {record['number']:02X}'s record ends at "
                     f"${record['end']:04X}, not where the next begins "
                     f"(${following['start']:04X}) -- the grammar is wrong")
    if records[-1]["end"] != ACTION_TABLE:
        sys.exit(f"error: the last object record ends at "
                 f"${records[-1]['end']:04X}, not at the action table")
    return records


def object_handlers(memory) -> set[int]:
    """The handler addresses the object records name, as code seeds.

    Zero is not one: a handler of $0000 is a record saying the object does
    nothing special for that action, and the address is the ROM's reset, not
    anything in the game.
    """
    return {handler for record in object_records(memory)
            for _, _, handler in record["handlers"]
            if ENTRY <= handler < GAME_END}


# How an object's byte 7 reads, bit by bit (see OBJECT_INDEX).
OBJECT_FLAGS = {7: "present", 6: "a character", 5: "open, or can be seen into",
                4: "a light (bit 4, with bit 2)", 3: "dead or broken", 2: "full",
                1: "a liquid", 0: "locked"}
# Byte 4: bits 0-3 how things sit with it, bits 4-6 its sides.
OBJECT_PLACED = ["in", "on", "behind", "under", "tied to"]
OBJECT_SIDES = {0x10: "the player's", 0x20: "the goblins'", 0x40: "the elves'"}


def object_labels(memory) -> dict[int, str]:
    """A label for every object record, from its name: STRONG_PORTCULLIS.

    Two pairs share a name -- the waters and the black waters -- so the
    second of each also carries its number, after letters so that it never
    ends in an underscore and a digit, which skool2asm keeps for itself.
    """
    labels, used = {}, set()
    for record in sorted(object_records(memory), key=lambda r: r["number"]):
        n = record["number"]
        label = "PLAYER" if n == 0 else _label_word(name_of(memory, record["start"] + 8))
        if label in used:
            label += f"_OBJ{n:02X}"
        used.add(label)
        labels[record["start"]] = label
    return labels


def object_blocks(memory) -> tuple[str, list[tuple[int, int]]]:
    """Control-file blocks for the object index, every object record, and the
    entries of ACTION_TABLE, which follows them.

    Every field is said in words beside its bytes -- where the object starts,
    what holds it, its size and weight, how things sit with it and its side,
    its strength and defence, its flags, its name -- and every address in them
    is a DEFW, a label in the source: the index's records, a handler's routine.
    """
    records = object_records(memory)
    by_number = {r["number"]: r for r in records}
    labels = object_labels(memory)
    names = {r["number"]: name_of(memory, r["start"] + 8) for r in records}
    rooms = room_records(memory)
    room_name = {k: name_of(memory, r["start"] + 2) for k, r in rooms.items() if k}
    count = len(records)
    index_end = OBJECT_INDEX + 3 * count + 1
    out = ["; Generated by scripts/build_hobbit.py -- do not edit.", ""]

    # The index: a number and the record, for each.
    out += [f"b ${OBJECT_INDEX:04X} Every object and every character, by number"]
    for number, record, at in keyed_table(memory, OBJECT_INDEX):
        out += [f"B ${at:04X},1,1", f"  ${at:04X},1 ${number:02X}: {names[number]}",
                f"W ${at + 1:04X},2,2"]
    out += [f"B ${index_end - 1:04X},1,1", f"  ${index_end - 1:04X},1 End of the index", ""]
    spans = [(OBJECT_INDEX, index_end)]

    def place(location: int) -> str:
        return (f"{location}, {room_name[location]}" if location in room_name
                else f"{location}, nowhere" if location == 0 else str(location))

    for record in records:
        n, start = record["number"], record["start"]
        kind = ("the player" if n == 0 else
                f"character ${n:02X}" if n >= 0x3C else f"object ${n:02X}")
        called = "you" if n == 0 else names[n]
        places = [memory[start + 16 + i] for i in range(record["listed"])]
        holder = memory[start + 1]
        size, weight = memory[start + 2], memory[start + 3]
        placed_sides = memory[start + 4]
        strength, defence, flags = memory[start + 5], memory[start + 6], memory[start + 7]
        # Bits 2 and 4 together are a light -- TOO_DARK reads them on the
        # sword and the torch -- and bit 2 alone, on a container, is full.
        flag_words = [w for bit, w in OBJECT_FLAGS.items() if flags & (1 << bit)
                      and not (bit == 2 and flags & 0x10)]
        sides = [w for bit, w in OBJECT_SIDES.items() if placed_sides & bit]
        handlers = [(address, action, handler) for address, action, handler in record["handlers"]]

        # The summary at the top.
        where = (" and ".join(room_name.get(p, str(p)) for p in places if p)
                 or "nowhere, until something puts it somewhere")
        held = ("" if holder == 0xFF else
                f", held by {'the player' if holder == 0 else names.get(holder, holder)}")
        doings = sorted({pattern_sentence(memory, a) for _, a, h in handlers if a and h})
        summary = (f"{called[0].upper() + called[1:]}: {kind}. It starts in {where}{held}. "
                   + (f"It is {', '.join(flag_words)}. " if flag_words else "")
                   + (f"It has its own handling for {', '.join(doings)}." if doings
                      else "It has no handlers of its own: every action on it is the ordinary one."))
        out.append(f"@ ${start:04X} label={labels[start]}")
        out.append(f"b ${start:04X} {called[0].upper() + called[1:]} ({kind})")
        out.append(f"D ${start:04X} {summary}")
        out.append(f"D ${start:04X} A record is a 16-byte head -- where it is, what holds it, "
                   f"its size, weight, strength and defence, its flags, its name and its "
                   f"description -- then the places it is in, then its own handlers, ending "
                   f"at $FF. OBJECT_INDEX describes each field.")

        # The head, a field at a time.
        out += [f"B ${start:04X},1,1",
                f"  ${start:04X},1 In {len(places)} place{'s' if len(places) != 1 else ''}",
                f"B ${start + 1:04X},1,1",
                f"  ${start + 1:04X},1 " + ("Held by nothing" if holder == 0xFF else
                                             f"Held by {'the player' if holder == 0 else names.get(holder)}"
                                             + (f" (#R${by_number[holder]['start']:04X})"
                                                if holder in by_number else "")),
                f"B ${start + 2:04X},1,1",
                f"  ${start + 2:04X},1 Size {size}" + (": nothing can hold it" if size == 0xFF else ""),
                f"B ${start + 3:04X},1,1",
                f"  ${start + 3:04X},1 " + (f"Carries up to {weight}" if n == 0 or n >= 0x3C else
                                             f"Weight {weight}" + (": too heavy for anyone to lift"
                                                                   if weight == 0xFF else "")),
                f"B ${start + 4:04X},1,1",
                f"  ${start + 4:04X},1 Things are {OBJECT_PLACED[placed_sides & 15] if (placed_sides & 15) < 5 else '?'} it"
                + (f"; on {', '.join(sides)} side" if sides else "")
                + ("; the window's bit 7" if placed_sides & 0x80 else ""),
                f"B ${start + 5:04X},1,1", f"  ${start + 5:04X},1 Strength {strength}",
                f"B ${start + 6:04X},1,1", f"  ${start + 6:04X},1 Defence {defence}",
                f"B ${start + 7:04X},1,1",
                f"  ${start + 7:04X},1 Flags: {', '.join(flag_words) or 'none'}"]
        name_words = [word_at(memory, memory[start + 8 + i] | (memory[start + 9 + i] << 8)) or "-"
                      for i in (0, 2, 4)]
        out += [f"B ${start + 8:04X},6,6",
                f"  ${start + 8:04X},6 Its name: {name_words[0].upper()}, then "
                f"{', '.join(w.upper() for w in name_words[1:] if w != '-') or 'no adjectives'}"]
        described = memory[start + 14] | (memory[start + 15] << 8)
        out += [f"B ${start + 14:04X},2,2",
                f"  ${start + 14:04X},2 " + (f"Its own description: #R${described:04X}"
                                              if described else "No description of its own")]
        if record["listed"]:
            out += [f"B ${start + 16:04X},{record['listed']},{record['listed']}",
                    f"  ${start + 16:04X},{record['listed']} "
                    + ("In location " if len(places) == 1 else "In locations ")
                    + "; ".join(place(p) for p in places)]
        previous = None
        for address, action, handler in handlers:
            if action:
                what = f"On {pattern_sentence(memory, action)} (action ${action:02X})"
                previous = pattern_sentence(memory, action)
            else:
                what = f"Key 0: after {previous or 'the handler before'}, as well"
            if handler == 0:
                what += ": nothing"
            out += [f"B ${address:04X},1,1", f"  ${address:04X},1 {what}",
                    f"W ${address + 1:04X},2,2"]
        out += [f"B ${record['end'] - 1:04X},1,1",
                f"  ${record['end'] - 1:04X},1 End of its handlers", ""]
        spans.append((start, record["end"]))

    # ACTION_TABLE: the action and its handler, the handler a label.
    for action, handler, at in keyed_table(memory, ACTION_TABLE):
        what = pattern_sentence(memory, action) if action else "Key 0: after the one before"
        out += [f"B ${at:04X},1,1", f"  ${at:04X},1 {what} (action ${action:02X})",
                f"W ${at + 1:04X},2,2"]
    table_end = next(at for _, _, at in [(0, 0, a) for a in [ACTION_TABLE]])
    return NEWLINE.join(out) + NEWLINE, spans


ROOM_POINTERS = 0xB9E0      # a 2-byte pointer per location, 0-79
ROOM_COUNT = 0x50           # GET_ROOM refuses anything from $50 up
ROOM_HEAD = 10
# The exits' direction codes, which are also the action codes 1-10 that
# ACTION_TABLE sends to MOVE. 1-4 and 9-10 were watched in MOVE and 3, 1 and 5
# read off location 4's "Visible exits are: east north northeast"; 7 and 8 off
# the trolls' clearing's "southwest southeast north", which leaves 6.
DIRECTIONS = {1: "north", 2: "south", 3: "east", 4: "west", 5: "northeast",
              6: "northwest", 7: "southeast", 8: "southwest", 9: "up", 10: "down"}


def word_at(memory, reference: int) -> str | None:
    """The word a 12-bit reference names, expanded by PRINT_WORD's own rule.

    Rooms and objects are named this way -- a noun and up to two adjectives,
    each a reference into the dictionary -- so a record's name is read out of
    the game rather than written down here.
    """
    offset = reference & 0x0FFF
    if not offset:
        return None
    address, letters = WORD_INDEX + offset, []
    while len(letters) < 16:
        byte = memory[address]
        address += 1
        code = byte & 0x1F
        if not code:
            break
        letters.append(LETTERS[code] if code < len(LETTERS) else "?")
        if byte & 0x80:
            if len(letters) == 2:
                continue
            if len(letters) == 3 and memory[address - 2] & 0x80:
                continue
            break
    return "".join(letters).lower()


def name_of(memory, start: int) -> str:
    """The adjectives in the order stored, then the noun, which is stored first.

    That is the order the game prints them in: object 5 is stored door, round,
    green and printed "round green door"; the sword is stored sword, short,
    strong and is the "short strong sword".
    """
    noun, *adjectives = [word_at(memory, memory[start + i] | (memory[start + i + 1] << 8))
                         for i in (0, 2, 4)]
    return " ".join(w for w in adjectives + [noun] if w)


# Messages: RUN_MESSAGE's bytecode, stored end to end from just after the
# common-word table, and the two tables it needs.
COMMON_WORDS = 0xAD3D       # 32 two-byte word references, reached by $60-$7F
MESSAGES = 0xAD7D
CONTROL_CODES = 0x7295      # a handler per control code, $00-$16
CONTROL_COUNT = 0x17
# The two control codes that take a byte after them: $02 jumps by that signed
# distance, and $0B runs a sub-message that far away. Their handlers read it
# from (IX+1) and step past it; everything else is one byte.
CODES_WITH_OPERAND = {0x02, 0x0B}
# The parser's handlers, one per token class from adverbs ($0) to the end of
# the line ($C); an unknown word ($D) never reaches the parser.
PARSER_CLASSES = 0x75D2
PARSER_CLASS_COUNT = 13
# PARSE_SPECIAL's words and, 26 bytes on, a handler for each. Slot 0 holds no
# word, so its handler cannot be reached through the table and is not a seed.
SPECIAL_WORDS = 0x8271
SPECIAL_COUNT = 13
# The timers END_OF_TURN counts down: 7-byte entries ending at $FF, each a
# length, a count (0 when the timer is not running), the routine to run when
# the count reaches 0, how many turns before that to warn, and the routine to
# warn with. Both routines are reached through $9B80's JP (HL).
TIMERS = 0xCA84
TIMER_SIZE = 7
# The other characters' slots: 7 bytes each, ending at $FF, with where the
# character's script has got to at bytes 2-3 and its table of scripts -- a
# FIND_RECORD table -- at bytes 4-5. Seventeen of them.
CHARACTERS = 0xCACB
CHARACTER_SIZE = 7
# MOVE's FIND_RECORD table of routines to run when the player arrives in a
# location, keyed by the location: they start the bog's and the web's timers,
# and bring characters into the story.
ARRIVAL_HOOKS = 0xC78E
# Messages entered part-way through, with how the entry fits. Three begin at
# an element boundary of another message, so the two share a tail; one begins
# on the second byte of the word that ends the message before it, reading
# that byte as a control code -- one byte doing two jobs, as at $8113.
# The fourth tail is the last room description: location 67, "the east bank
# of a black river", is the end of location 66's description of the other bank.
MESSAGE_TAILS = {0xADA9: "a tail", 0xB018: "a tail", 0xB143: "a tail",
                 0xB6CF: "a tail", 0xAFB5: "an overlap"}


def message_elements(memory, address: int) -> tuple[list[int], int]:
    """The elements of one message and the address after it, by RUN_MESSAGE's
    own tests: bit 7 starts a two-byte word reference, and flags 2, 3 or 6 in
    its top nibble end the message; below $20 is a control code, and $14 or
    above ends it; $60-$7F is a common word, and the rest a literal character.
    """
    elements = []
    while True:
        elements.append(address)
        byte = memory[address]
        if byte & 0x80:
            address += 2
            if ((byte & 0x7F) >> 4) in (2, 3, 6):
                return elements, address
        else:
            address += 1
            if byte in CODES_WITH_OPERAND:
                address += 1
            if byte < 0x14:
                continue
            if byte < 0x20:
                return elements, address


def message_text(memory, address: int) -> str:
    """A message as the game would print it, near enough to read beside it.

    Control codes, which print things chosen at run time -- a character's name,
    HIS or YOUR -- show as {n}. Endings the flags would add are not applied.
    """
    elements, _ = message_elements(memory, address)
    out = []
    for at in elements:
        byte = memory[at]
        if byte & 0x80:
            reference = ((byte & 0x7F) << 8) | memory[at + 1]
            out.append(word_at(memory, reference) or "?")
            if (reference >> 12) == 3:
                out[-1] += "."
        elif byte in CODES_WITH_OPERAND:
            distance = memory[at + 1] - (256 if memory[at + 1] > 127 else 0)
            out.append(f"{{{'jump' if byte == 2 else 'sub-message'} {distance:+d}}}")
        elif byte < 0x20:
            out.append("" if byte >= 0x14 else f"{{{byte}}}")
        elif byte >= 0x60:
            slot = COMMON_WORDS + 2 * (byte - 0x60)
            out.append(word_at(memory, memory[slot] | (memory[slot + 1] << 8)) or "?")
        else:
            out.append(chr(byte))
    return " ".join(w for w in out if w)


def message_starts(memory) -> list[int]:
    """Every stored message, walked end to end.

    The walk stops after the message holding the last room description, which
    is the last thing anything points at; what follows is zeros and then the
    game's variables.
    """
    last = max(memory[r["start"] + 8] | (memory[r["start"] + 9] << 8)
               for n, r in room_records(memory).items() if n)
    starts, address = [], MESSAGES
    while address <= last:
        starts.append(address)
        _, address = message_elements(memory, address)
    return starts


def check_messages(memory, starts: list[int], pointers: set[int]) -> None:
    """Every message pointer must land on a message, or on a known way into one."""
    known = set(starts)
    end = message_elements(memory, starts[-1])[1]
    for pointer in sorted(pointers):
        if not MESSAGES <= pointer < end or pointer in known:
            continue
        if pointer not in MESSAGE_TAILS:
            sys.exit(f"error: a message pointer to ${pointer:04X} lands inside "
                     f"a message and is not a known tail or overlap")
    _log(f"  {len(starts)} messages end to end from ${MESSAGES:04X}; all "
         f"{len(pointers)} pointers to them land on a start or a known way in")


def message_pointers(memory, code_starts: set[int]) -> set[int]:
    """Messages named from outside: room descriptions, and LD HL,msg shortly
    before a call or jump into RUN_MESSAGE, found by decoding the code map's
    own instructions rather than by reading a listing back."""
    import codemap

    pointers = {memory[r["start"] + 8] | (memory[r["start"] + 9] << 8)
                for n, r in room_records(memory).items() if n}
    pointers.discard(0)
    entries = {0x72D3, 0x72DD, 0x72CE}
    for start in code_starts:
        if memory[start] != 0x21:                # LD HL,nn
            continue
        target = memory[start + 1] | (memory[start + 2] << 8)
        if not MESSAGES <= target < ROOM_POINTERS:
            continue
        address = start + 3
        for _ in range(3):
            instruction = codemap.decode(memory, address)
            if entries & set(instruction.targets):
                pointers.add(target)
                break
            address += instruction.length
    return pointers


def message_blocks(memory, pointers: set[int]) -> tuple[str, list[tuple[int, int]]]:
    """Control-file blocks for the common words, the control codes and every
    message, each titled with its own text."""
    starts = message_starts(memory)
    check_messages(memory, starts, pointers)
    out = ["; Generated by scripts/build_hobbit.py -- do not edit.", "",
           f"@ ${COMMON_WORDS:04X} label=COMMON_WORDS",
           f"b ${COMMON_WORDS:04X} The 32 commonest words in messages",
           f"D ${COMMON_WORDS:04X} A message byte from $60 to $7F stands for one "
           f"of these, which is how the small glue words cost a byte each.",
           f"W ${COMMON_WORDS:04X},64,2"]
    for i in range(32):
        slot = COMMON_WORDS + 2 * i
        out.append(f"  ${slot:04X},2 ${0x60 + i:02X}: "
                   f"{word_at(memory, memory[slot] | (memory[slot + 1] << 8))}")
    out.append("")
    spans = [(COMMON_WORDS, MESSAGES)]
    starts_set = set(starts)
    for i, start in enumerate(starts):
        _, end = message_elements(memory, start)
        text = message_text(memory, start)
        entered = [p for p in MESSAGE_TAILS if start < p < end]
        label = f"MSG_{start:04X}"
        out.append(f"@ ${start:04X} label={label}")
        out.append(f"b ${start:04X} Message: {text[:60]}")
        out.append(f"D ${start:04X} {text}")
        for p in entered:
            out.append(f"D ${start:04X} Also entered at ${p:04X} ({MESSAGE_TAILS[p]}): "
                       f"{message_text(memory, p)}")
        out.append(f"B ${start:04X},{end - start}")
        out.append("")
        spans.append((start, end))
    return NEWLINE.join(out) + NEWLINE, spans


def control_handlers(memory) -> set[int]:
    """RUN_MESSAGE's control-code handlers, as code seeds."""
    return {memory[CONTROL_CODES + 2 * i] | (memory[CONTROL_CODES + 2 * i + 1] << 8)
            for i in range(CONTROL_COUNT)}


def timer_handlers(memory) -> set[int]:
    """The routines each timer runs when it fires or warns, as code seeds.

    A warning routine is only one when the entry has a warning span; the
    entries without one leave a zero there, which $9B6C skips.
    """
    seeds, entry = set(), TIMERS
    while memory[entry] != 0xFF:
        seeds.add(memory[entry + 2] | (memory[entry + 3] << 8))
        if memory[entry + 4]:
            seeds.add(memory[entry + 5] | (memory[entry + 6] << 8))
        entry += TIMER_SIZE
    seeds.discard(0)
    return seeds


def script_routines(memory) -> set[int]:
    """The routines the characters' scripts call, as code seeds.

    A script step's low four bits are its opcode (see CHARACTERS_ACT): 0-3
    take four bytes and 4 takes two, each with a 2-byte fallback address after
    it when bit 4 is set; $0E is a jump to the address after it, $0C and $0F
    switch to a script from the character's table, and anything else sends
    it back to its first script -- so after any of those four the walk stops. Opcodes 1 and 3 name a routine in bytes 1 and 2, which SCRIPT_DO
    runs through $9B80's JP (HL). Every script is walked from every place a
    character can enter one -- where it is now, and each entry in its table --
    following fallbacks and jumps, which is the same set of places the game
    itself can reach.
    """
    def length(address):
        op = memory[address]
        fallback = 2 if op & 0x10 else 0
        if op & 0x0F < 4:
            return 4 + fallback
        if op & 0x0F == 4:
            return 2 + fallback
        return 3 if op & 0x0F == 0x0E else 2

    word = lambda a: memory[a] | (memory[a + 1] << 8)
    pending, seen, routines = [], set(), set()
    slot = CHARACTERS
    while memory[slot] != 0xFF:
        pending.append(word(slot + 2))
        entry = word(slot + 4)
        while memory[entry] != 0xFF:
            pending.append(word(entry + 1))
            entry += 3
        slot += CHARACTER_SIZE
    while pending:
        address = pending.pop()
        if address in seen:
            continue
        seen.add(address)
        op = memory[address] & 0x0F
        if op == 0x0E:
            pending.append(word(address + 1))
            continue
        if op > 4:
            # $0C and $0F switch scripts through the table, which is walked
            # already; nothing after them, or after the rest, is reached.
            continue
        if op < 4 and op & 1:
            routines.add(word(address + 1))
        if memory[address] & 0x10 and op <= 4:
            pending.append(word(address + length(address) - 2))
        pending.append(address + length(address))
    return routines


# The characters' scripts, $C82D up to TIMERS: each character's script table
# (a FIND_RECORD table of [key, script]), and the scripts, one step after
# another. CHARACTERS_ACT and SCRIPT_DO/SCRIPT_BARE are what run them.
SCRIPTS_START = 0xC82D
SCRIPTS_END = TIMERS
CHARACTER_COUNT = 17
# The three slots empty at the start, and whose they become: the arrival
# hooks write these characters' numbers in -- AT_BEORNS_HOUSE the butler,
# AT_ELVENKINGS_CELLAR the dragon and Bard.
EMPTY_SLOT_OWNERS = {0xCAE7: 0x42, 0xCAFC: 0x46, 0xCB03: 0x3C}
# The script step BARD_TAKES_ORDER rewrites with the order Bard is given.
BARD_ORDER_STEP = 0xC9E2


def _label_word(text: str) -> str:
    return re.sub(r"[^A-Z0-9]+", "_", text.upper()).strip("_")


def pattern_sentence(memory, code: int) -> str:
    """The sentence an action code stands for, from ACTION_PATTERNS."""
    start = ACTION_PATTERNS - 8 + 8 * code
    words = []
    for k in (0, 2, 4):
        reference = memory[start + k] | (memory[start + k + 1] << 8)
        if reference & 0x0FFF:
            words.append(word_at(memory, reference).upper())
    if 1 <= code <= 10:
        last = memory[start + 6] | (memory[start + 7] << 8)
        words.insert(0, word_at(memory, last).upper())
    return " ".join(words)


def script_step(memory, address: int) -> dict:
    """One step of a character's script, as CHARACTERS_ACT reads it.

    The low four bits of its first byte are the opcode: 0-3 an action with
    objects, or with bit 0 a routine (SCRIPT_DO); 4 an action with none, or a
    pause for $FF (SCRIPT_BARE); $0C switch by key, $0E go to, $0F switch at
    random; anything else back to the first script. Bit 4 adds a 2-byte
    fallback, bit 5 ends the character's part on success, bit 6 keeps an
    order from interrupting.
    """
    op = memory[address]
    code = op & 0x0F
    step = {"address": address, "op": op, "code": code, "fallback": None,
            "target": None, "routine": None, "ends": False}
    word = lambda a: memory[a] | (memory[a + 1] << 8)
    if code < 4:
        length = 4
        if code & 1:
            step["routine"] = word(address + 1)
        else:
            step["action"] = memory[address + 1]
            step["objects"] = (memory[address + 2], memory[address + 3])
    elif code == 4:
        length = 2
        step["action"] = memory[address + 1]
    elif code == 0x0E:
        length, step["target"], step["ends"] = 3, word(address + 1), True
    elif code in (0x0C, 0x0F):
        length, step["ends"] = 2, True
        step["operand"] = memory[address + 1]
    else:
        length, step["ends"] = 1, True
    if code <= 4 and op & 0x10:
        step["fallback"] = word(address + length)
        length += 2
    step["length"] = length
    return step


def script_program(memory) -> dict:
    """Every script table and every script step, with the labels they get.

    Walked from every place a character can enter a script -- where each slot
    has got to, and each table entry -- following jumps and fallbacks, which
    is the set of places the game itself can reach. Every byte from
    SCRIPTS_START to SCRIPTS_END must come out as part of a table or a step:
    a gap or an overlap stops the build, since it would mean the grammar is
    wrong.
    """
    word = lambda a: memory[a] | (memory[a + 1] << 8)
    names = {r["number"]: name_of(memory, r["start"] + 8) for r in object_records(memory)}
    slots = []
    for i in range(CHARACTER_COUNT):
        slot = CHARACTERS + CHARACTER_SIZE * i
        who = memory[slot] or EMPTY_SLOT_OWNERS[slot]
        slots.append({"address": slot, "character": who, "empty": not memory[slot],
                      "limit": memory[slot + 1], "current": word(slot + 2),
                      "table": word(slot + 4), "orders": memory[slot + 6]})

    tables: dict[int, dict] = {}
    for slot in slots:
        table = tables.setdefault(slot["table"], {"owners": [], "entries": [], "end": None})
        table["owners"].append(slot["character"])
    for address, table in tables.items():
        at = address
        while memory[at] != 0xFF:
            table["entries"].append((at, memory[at], word(at + 1)))
            at += 3
        table["end"] = at

    steps: dict[int, dict] = {}
    pending = [slot["current"] for slot in slots]
    pending += [target for t in tables.values() for _, _, target in t["entries"]]
    while pending:
        address = pending.pop()
        if address in steps:
            continue
        step = script_step(memory, address)
        steps[address] = step
        if step["target"] is not None:
            pending.append(step["target"])
        if step["fallback"] is not None:
            pending.append(step["fallback"])
        if not step["ends"]:
            pending.append(address + step["length"])

    covered: dict[int, int] = {}
    def cover(start: int, length: int) -> None:
        for a in range(start, start + length):
            if a in covered:
                sys.exit(f"error: script byte ${a:04X} is claimed twice "
                         f"(${covered[a]:04X} and ${start:04X})")
            covered[a] = start
    for address, table in tables.items():
        cover(address, table["end"] + 1 - address)
    for address, step in steps.items():
        cover(address, step["length"])
    missing = [a for a in range(SCRIPTS_START, SCRIPTS_END) if a not in covered]
    if missing:
        sys.exit(f"error: {len(missing)} script byte(s) are neither a table nor a "
                 f"step, from ${missing[0]:04X} -- the script grammar is wrong")

    # Labels. A table is named after its first owner; an ordinary script
    # after the table's owner and its place in it (A, B, ...); a reaction
    # after the action it answers, and the owner too unless several
    # characters share it; anything else a jump or a fallback leads to by its
    # address. Letters, not numbers, after an underscore: skool2asm's own
    # labels are NAME_0, NAME_1 and so on.
    labels: dict[int, str] = {}
    def owner(table) -> str:
        return _label_word(names[table["owners"][0]])
    shared = {}
    for table in tables.values():
        for _, key, target in table["entries"]:
            shared.setdefault(target, set()).add(id(table))
    for address, table in sorted(tables.items()):
        labels[address] = owner(table) + "_SCRIPTS"
    for address, table in sorted(tables.items()):
        ordinary = 0
        for _, key, target in table["entries"]:
            if target in labels:
                continue
            if key == 0:
                labels[target] = f"{owner(table)}_{chr(ord('A') + ordinary)}"
                ordinary += 1
            else:
                action = _label_word(pattern_sentence(memory, key))
                if len(shared[target]) == 1:
                    name = f"{owner(table)}_ON_{action}"
                else:
                    # Shared: by a kind of character if they are all one
                    # kind -- the goblins -- and otherwise by the action
                    # alone; the address if even that is taken.
                    sharers = {_label_word(names[o]).split("_")[-1]
                               for t in tables.values() if id(t) in shared[target]
                               for o in t["owners"]}
                    name = (f"{sharers.pop()}S_ON_{action}" if len(sharers) == 1
                            else f"ON_{action}")
                if name in labels.values():
                    name += f"_AT_{target:04X}"
                labels[target] = name
    for address, step in steps.items():
        for target in (step["target"], step["fallback"]):
            if target is not None and target not in labels:
                labels[target] = f"SCRIPT_{target:04X}"
    for slot in slots:
        if slot["current"] not in labels:
            labels[slot["current"]] = f"SCRIPT_{slot['current']:04X}"
    return {"slots": slots, "tables": tables, "steps": steps, "labels": labels,
            "names": names}


def describe_step(memory, program: dict, step: dict, link) -> str:
    """A step in words. `link(address)` renders a reference to a script or
    a routine -- #R$ADDR in the control file, a hyperlink on the pages."""
    names = program["names"]
    def thing(number: int) -> str:
        return "anything" if number == 0xFF else ("the player" if number == 0
                                                 else names.get(number, f"${number:02X}"))
    code = step["code"]
    if code < 4 and step["routine"] is not None:
        text = f"Call {link(step['routine'])}"
    elif code < 4:
        first, second = step["objects"]
        text = pattern_sentence(memory, step["action"])
        objects = [thing(n) for n in (first, second) if n != 0xFF]
        if objects:
            text += ": " + ", ".join(objects)
    elif code == 4:
        text = ("Pause: nothing this turn" if step["action"] == 0xFF
                else pattern_sentence(memory, step["action"]))
    elif code == 0x0E:
        text = f"Go to {link(step['target'])}"
    elif code == 0x0F:
        text = f"Switch to one of its first {step['operand']} scripts at random"
    elif code == 0x0C:
        text = f"Switch to its script for {pattern_sentence(memory, step['operand'])}"
    else:
        text = "Back to its first script"
    notes = []
    if step["op"] & 0x40:
        notes.append("an order cannot interrupt it")
    if step["op"] & 0x20:
        notes.append("then its part in the story is over")
    if notes:
        text += " (" + "; ".join(notes) + ")"
    return text


def script_blocks(memory) -> tuple[str, list[tuple[int, int]]]:
    """Control-file blocks for the script tables and every script step, and
    for the CHARACTERS slots that point into them.

    Every address in them -- a table's scripts, a step's fallback, a jump, a
    routine a step calls, a slot's table and place -- is a DEFW, which
    skool2asm turns into a label: so a script can be edited in the generated
    source and reassembled, and the addresses follow it.
    """
    program = script_program(memory)
    labels, names = program["labels"], program["names"]
    tables, steps = program["tables"], program["steps"]
    link = lambda address: f"#R${address:04X}"
    out = ["; Generated by scripts/build_hobbit.py -- do not edit.", ""]

    # Block starts: each table, and the scripts shared by several tables,
    # which the game keeps together after the last table's own.
    starts = sorted(tables)
    shared = sorted(a for a, lab in labels.items() if lab.startswith("ON_"))
    shared_start = min((a for a in shared if a > starts[-1]), default=None)
    if shared_start is not None:
        starts.append(shared_start)

    # A heading for each script: what it is, and in brief what it does, up to
    # where it ends or runs on into another script with a heading of its own.
    purpose: dict[int, str] = {}
    for table in tables.values():
        for _, key, target in table["entries"]:
            if target not in purpose:
                purpose[target] = ("An ordinary script" if key == 0 else
                                   f"The reaction to {pattern_sentence(memory, key)}")
    for slot in program["slots"]:
        purpose.setdefault(slot["current"], "Where the script starts")
    for step in steps.values():
        for target in (step["target"], step["fallback"]):
            if target is not None:
                purpose.setdefault(target, "Where a jump or a refusal goes on")
    # Routines a step calls are named by the annotations, scripts by `labels`.
    routine_names = {int(a, 16): name for a, name in re.findall(
        r"^@ \$([0-9A-F]{4}) label=(\S+)",
        ANNOTATIONS.read_text(encoding="utf-8") if ANNOTATIONS.exists() else "", re.M)}
    name_of_address = lambda a: labels.get(a) or routine_names.get(a) or f"${a:04X}"
    headings: dict[int, str] = {}
    for start, what in purpose.items():
        brief, at = [], start
        for _ in range(40):
            step = steps[at]
            brief.append(describe_step(memory, program, step, name_of_address)
                         .split(" (")[0].replace("Call ", "")
                         .replace("Switch to one of its first ", "switch at random among its first ")
                         .replace(" scripts at random", ""))
            if step["ends"]:
                break
            at += step["length"]
            if at in purpose:
                brief.append(f"then on as {labels[at]}")
                break
        headings[start] = f"{labels[start]} -- {what}: " + ", ".join(brief) + "."

    items = [(a, "table") for a in tables] + [(a, "step") for a in steps]
    for address, kind in sorted(items):
        if address in starts:
            if address == shared_start:
                out.append(f"b ${address:04X} Scripts several characters share")
                out.append(f"D ${address:04X} What they do when attacked, "
                           f"captured or given something.")
            else:
                who = ", ".join(names[n] for n in tables[address]["owners"])
                out.append(f"b ${address:04X} Scripts: {who}")
                out.append(f"D ${address:04X} What {who} does, turn by turn. "
                           f"CHARACTERS_ACT runs one step of a character's script "
                           f"each turn it can, and a step is an action the character "
                           f"tries as if it had typed it: RUN, TAKE, GIVE TO. A step "
                           f"that names nothing acts on whatever fits.")
                out.append(f"D ${address:04X} First comes the script table: one "
                           f"entry per script, a key and the script's address. Key "
                           f"0 is an ordinary script -- the ones a character "
                           f"wanders between, picked at random by a 'switch at "
                           f"random' step. Any other key is an action code, and "
                           f"that script is the character's reaction when that is "
                           f"done to it: attacked, given something, captured.")
                out.append(f"D ${address:04X} Then the scripts, one step to a "
                           f"line. A step's first byte says what it is: its low "
                           f"four bits $00-$03 an action with objects (or, $01 and "
                           f"$03, a routine to call), $04 an action with none, "
                           f"$0E go to, $0F switch at random, $0C switch to a "
                           f"reaction. $10 added means an address follows, where "
                           f"the script goes on if the step is refused; $20 that "
                           f"the character's part is over once it works; $40 "
                           f"that an order from the player cannot interrupt it. "
                           f"So $14 is an action with no objects, with somewhere "
                           f"to go if it is refused. The Characters page has "
                           f"every script written out.")
        if address in labels:
            out.append(f"@ ${address:04X} label={labels[address]}")
        if kind == "step" and address in headings:
            out.append(f"N ${address:04X} {headings[address]}")
        if kind == "table":
            table = tables[address]
            for at, key, target in table["entries"]:
                what = (f"Key 0, an ordinary script: {labels[target]}" if key == 0 else
                        f"Key ${key:02X}, {pattern_sentence(memory, key)}: "
                        f"its reaction, {labels[target]}")
                out.append(f"B ${at:04X},1,1")
                out.append(f"  ${at:04X},1 {what}")
                # No comment line for the word: one would turn it back into
                # bytes. Its operand becomes the script's label anyway.
                out.append(f"W ${at + 1:04X},2,2")
            out.append(f"B ${table['end']:04X},1,1")
            out.append(f"  ${table['end']:04X},1 End of the table")
            continue
        step = steps[address]
        text = describe_step(memory, program, step, link)
        if address == BARD_ORDER_STEP:
            text += " -- rewritten by BARD_TAKES_ORDER with each order Bard is given"
        code = step["code"]
        if code < 4 and step["routine"] is not None:
            out += [f"B ${address:04X},1,1", f"  ${address:04X},1 {text}",
                    f"W ${address + 1:04X},2,2", f"B ${address + 3:04X},1,1",
                    f"  ${address + 3:04X},1 Not used"]
            body = 4
        elif code == 0x0E:
            out += [f"B ${address:04X},1,1", f"  ${address:04X},1 {text}",
                    f"W ${address + 1:04X},2,2"]
            body = 3
        else:
            body = step["length"] - (2 if step["fallback"] is not None else 0)
            out += [f"B ${address:04X},{body},{body}", f"  ${address:04X},{body} {text}"]
        if step["fallback"] is not None:
            out.append(f"W ${address + body:04X},2,2 If it is refused: {link(step['fallback'])}")
    out.append("")

    # The slots, field by field, so that where each points is a label too.
    for slot in program["slots"]:
        a = slot["address"]
        who = names[slot["character"]]
        first = (f"Empty at the start: {who}'s, once an arrival hook writes it in"
                 if slot["empty"] else who.capitalize())
        out += [f"B ${a:04X},1,1", f"  ${a:04X},1 {first}",
                f"B ${a + 1:04X},1,1",
                f"  ${a + 1:04X},1 How many of its scripts it chooses among at random",
                f"W ${a + 2:04X},2,2 Where its script has got to",
                f"W ${a + 4:04X},2,2 Its script table",
                f"B ${a + 6:04X},1,1", f"  ${a + 6:04X},1 How many orders it takes at once"]
    out.append("")
    return NEWLINE.join(out) + NEWLINE, [(SCRIPTS_START, SCRIPTS_END)]


def room_records(memory) -> dict[int, dict]:
    """Every location's record: a 10-byte head, then [direction, via,
    destination] exits ending at $FF, as $9E95 and $9B93 walk them.

    Location 0 is not a room. Its record is 13 bytes -- an empty head and a
    lone $00 $00 $FF -- and nothing walks its exits; it is kept apart rather
    than parsed, because parsing it as a room runs straight into Bag End.
    """
    rooms = {}
    for location in range(ROOM_COUNT):
        start = memory[ROOM_POINTERS + 2 * location] | (
            memory[ROOM_POINTERS + 2 * location + 1] << 8)
        exits, address = [], start + ROOM_HEAD
        if location:
            while memory[address] != 0xFF:
                exits.append((address, memory[address], memory[address + 1],
                              memory[address + 2]))
                address += 3
            end = address + 1
        else:
            end = start + 13
        rooms[location] = {"start": start, "exits": exits, "end": end}
    return rooms


def check_rooms(memory, rooms: dict[int, dict]) -> None:
    """The room table's own proof, all or nothing."""
    objects = {number for number, _, _ in keyed_table(memory, OBJECT_INDEX)}
    ordered = sorted(rooms.values(), key=lambda r: r["start"])
    for record, following in zip(ordered, ordered[1:]):
        if record["end"] != following["start"]:
            sys.exit(f"error: a room record ends at ${record['end']:04X}, not "
                     f"where the next begins (${following['start']:04X})")
    if ordered[-1]["end"] != OBJECT_INDEX:
        sys.exit("error: the last room record does not end at the object index")
    for location, room in rooms.items():
        for _, direction, via, destination in room["exits"]:
            if direction not in DIRECTIONS:
                sys.exit(f"error: location {location} has an exit coded {direction}")
            # Zero is allowed, as FIND_EXIT allows it: it passes over any exit
            # whose destination is zero, so such an exit is one that leads
            # nowhere yet -- a way the game opens later by writing a location in.
            if not destination < ROOM_COUNT:
                sys.exit(f"error: location {location} leads to {destination}")
            if via and via not in objects:
                sys.exit(f"error: location {location} has an exit through "
                         f"{via:02X}, which is not an object")
    exits = sum(len(r["exits"]) for r in rooms.values())
    _log(f"  {ROOM_COUNT - 1} rooms and {exits} exits; every record ends where "
         f"the next begins, every exit leads to a room, and every door on one "
         f"is an object")


def room_blocks(memory) -> tuple[str, list[tuple[int, int]]]:
    """Control-file blocks for the room pointers and every room record."""
    rooms = room_records(memory)
    check_rooms(memory, rooms)
    out = ["; Generated by scripts/build_hobbit.py -- do not edit.", "",
           f"@ ${ROOM_POINTERS:04X} label=ROOM_POINTERS",
           f"b ${ROOM_POINTERS:04X} Where each location's record is",
           f"D ${ROOM_POINTERS:04X} One 2-byte pointer per location, 0 to 79, "
           f"indexed directly by GET_ROOM.",
           f"W ${ROOM_POINTERS:04X},{2 * ROOM_COUNT},2", ""]
    spans = [(ROOM_POINTERS, ROOM_POINTERS + 2 * ROOM_COUNT)]
    for location, room in sorted(rooms.items(), key=lambda kv: kv[1]["start"]):
        start = room["start"]
        out.append(f"@ ${start:04X} label=ROOM{location}")
        if not location:
            out.append(f"b ${start:04X} Location 0: not a room")
            out.append(f"D ${start:04X} An empty head and no real exits. "
                       f"Nothing walks it.")
            out.append(f"B ${start:04X},13,13")
            out.append("")
            spans.append((start, room["end"]))
            continue
        name = name_of(memory, start + 2)
        lit = "lit" if memory[start] & 0x80 else "dark"
        out.append(f"b ${start:04X} Location {location}: {name}")
        ways = ", ".join(DIRECTIONS[d] for _, d, _, _ in room["exits"]) or "none"
        out.append(f"D ${start:04X} A 10-byte head -- {lit}, named {name} -- "
                   f"then its exits: {ways}.")
        # Byte 0: bit 7 lit, bit 6 visited (MOVE sets it), bits 1-3 the
        # word for how the player is placed there (ROOM_PREPOSITIONS). Byte
        # 1: how much it holds, against the sizes of what is in it (ROOM_LEFT
        # and CAN_PASS); $FF for no limit, which is nearly every room.
        room_capacity = memory[start + 1]
        room_holds = ("holds any amount" if room_capacity == 0xFF
                      else f"holds {room_capacity}")
        out.append(f"B ${start:04X},1,1")
        out.append(f"  ${start:04X},1 Flags: {lit} (bit 7), visited (bit 6), "
                   f"and how the player is placed there (bits 1-3)")
        out.append(f"B ${start + 1:04X},1,1")
        out.append(f"  ${start + 1:04X},1 Capacity: {room_holds}")
        out.append(f"B ${start + 2:04X},6,6")
        out.append(f"  ${start + 2:04X},6 Its name: noun, then adjectives")
        out.append(f"B ${start + 8:04X},2,2")
        described = memory[start + 8] | (memory[start + 9] << 8)
        out.append(f"  ${start + 8:04X},2 " + (f"A longer description, at ${described:04X}"
                   if described else "No longer description"))
        for address, direction, via, destination in room["exits"]:
            through = f" through object {via}" if via else ""
            to = (f"to location {destination}" if destination else
                  "to nowhere yet: FIND_EXIT passes over it until a location "
                  "is written in")
            out.append(f"B ${address:04X},3,3")
            out.append(f"  ${address:04X},3 {DIRECTIONS[direction].capitalize()}"
                       f"{through} {to}")
        out.append(f"B ${room['end'] - 1:04X},1,1")
        out.append(f"  ${room['end'] - 1:04X},1 End of the exits")
        out.append("")
        spans.append((start, room["end"]))
    return NEWLINE.join(out) + NEWLINE, spans


# --------------------------------------------------------------------------
# Step 3: play the game to find out which addresses are code.
# --------------------------------------------------------------------------

# Typed at the parser, in order. The point is coverage of the parser and the
# command dispatcher rather than finishing the story: every sentence shape the
# game documents is here (two verbs joined by THEN, a list joined by AND, an
# adverb, an adjective, a preposition, the pronoun IT, a character addressed by
# name), alongside enough movement and object handling to reach the routines
# that draw rooms, move the other characters and run a fight. The last-but-one
# is deliberate nonsense, to walk the "I don't understand" path.
WALKTHROUGH = [
    "LOOK",
    "INVENTORY",
    "EXAMINE THE CURIOUS MAP",
    "TAKE THE MAP AND THE KEY",
    "I",
    "OPEN THE DOOR",
    "WEST",
    "LOOK",
    "GANDALF, TAKE THE SWORD",
    "WAIT",
    "EAST",
    "DROP THE MAP THEN TAKE THE MAP",
    "GO WEST",
    "DOWN",
    "UP",
    "NORTH",
    "SOUTH",
    "CARRY THE LAMP",
    "ATTACK THE TROLL WITH THE SWORD",
    "VICIOUSLY ATTACK THE TROLL",
    "TAKE ALL",
    "DROP ALL EXCEPT THE SWORD",
    "LOOK AT IT",
    "CLIMB THE TREE",
    "OPEN THE WINDOW",
    "LIGHT THE LAMP",
    "GO THROUGH THE DOOR QUICKLY",
    "WEAR THE RING",
    "SCORE",
    "HELP",
    "FLIBBERTIGIBBET",
    "LOOK",
]


def verb_drill(memory) -> list[str]:
    """A command for every verb in the game's own dictionary.

    WALKTHROUGH above is written by hand, and a hand-written list of commands
    goes stale the moment it is not re-read against the game: it was typing 11
    of the 53 verbs, so two thirds of the command dispatcher was never entered
    and no amount of following branches could reach it, because a dispatch
    table is exactly what recursive descent cannot see through.

    So the drill is derived rather than written. Every verb the dictionary
    holds gets typed twice, bare and with an object, which reaches both the
    intransitive and the transitive paths -- and because the list comes out of
    the game, a verb can never be missed by an oversight here.

    The object is the map, which is in the player's reach from the first turn.
    Most of these sentences are refusals rather than actions; that is fine,
    since what is being exercised is the dispatcher rather than the story.
    """
    verbs = [w.text for w in decode_words(memory) if w.part_of_speech == "verb"]
    already = set()
    for command in WALKTHROUGH:
        already.update(command.replace(",", " ").split())
    commands = []
    for verb in verbs:
        if verb in already:
            continue
        commands.append(verb)
        commands.append(f"{verb} THE MAP")
    return commands


def _keys_for(char: str) -> list[str]:
    """The keys held down to produce one typed character."""
    if char == " ":
        return ["SPACE"]
    if char == "\n":
        return ["ENTER"]
    if char == ",":
        return ["SS", "n"]
    return [char.lower()]


def _key_tracer_class():
    from skoolkit.kbtracer import KEY_BITS
    from skoolkit.trace import Tracer

    class KeyTracer(Tracer):
        """A Tracer whose read_port reports a set of held-down keys."""

        def __init__(self, simulator):
            super().__init__(simulator, 0, 0, 0, [0] * 16, 0, False)
            self.keys = set()

        def read_port(self, registers, port):
            if port == 0x1F:        # Kempston joystick: nothing pressed
                return 0
            if port & 1:            # not the ULA
                return 0xFF
            result = 0xFF
            for key in self.keys:
                half_row, bits = KEY_BITS[key]
                if port & half_row == 0:
                    result &= bits
            return result

    return KeyTracer


def _session_script(commands: list[str], hold: float, gap: float, think: float,
                    settle: float):
    """(keys-held, seconds) steps: dismiss the title screen, then type.

    `settle` is not padding, though the reason for it was first misread. The
    opening picture takes about seven seconds to draw, during which nothing
    reads the keyboard -- and then the game waits in WAIT_FOR_ANY_KEY, so the
    first key after it is consumed as "carry on" rather than read as a letter.
    Measured: at a 2-second settle the first command is lost entirely (one LOOK
    finds 1 new instruction), at 5 still, and at 8 it lands and the same single
    LOOK finds 1392. hobbit_drive.py does without the timing altogether, by
    breakpoint; this keeps typing because typing is itself code worth mapping.
    """
    script = [([], settle), (["SPACE"], 0.2), ([], settle)]
    for command in commands:
        for char in command + "\n":
            script.append((_keys_for(char), hold))
            script.append(([], gap))
        # The game has to parse, move every other character, work out what
        # happened and redraw the picture before it will look at the keyboard
        # again; typing over the top of that loses the next command.
        script.append(([], think))
    return script


def extend_by_descent(memory: list, executed: set[int]) -> set[int]:
    """Follow the game's own branches out from everything that ran.

    The playthrough can only find code it managed to reach, and for a game
    driven by typed sentences that leaves a lot untouched. codemap.walk takes
    those addresses as seeds and follows every call, jump and fall-through
    from them, which finds routines the walkthrough never entered without
    guessing at anything: an address is only added because something already
    known to be code goes there.

    Seeding from the execution map rather than from the entry point alone is
    the point. Recursive descent stops dead at an indirect jump, and descent
    from $6C00 by itself reaches only about two thirds of what actually ran --
    so it cannot replace the execution map, only extend it. Whatever a real
    CPU reached through a dispatch table is already a seed here.

    The check afterwards is what makes the hand-written decoder in codemap.py
    trustworthy: every address the CPU executed must come out of it as an
    instruction start too. It found a real bug when first run -- DD/FD on an
    opcode naming (HL) carries a displacement byte, so it is two bytes longer
    than the plain form and not one -- and a wrong length there is invisible
    downstream, because the round-trip check cannot tell data disassembled as
    instructions from the real thing.
    """
    import codemap

    # The packed dictionary is data on the game's own evidence: nothing in it
    # is ever executed, and its format is decoded and self-checking. Control
    # flow into it would mean the decode had gone astray, so it is a barrier
    # rather than somewhere to follow.
    barriers = [(WORD_INDEX, ENTRY)]
    # The action table's handlers are code on the table's own evidence -- the
    # playthrough reached 29 of its 31 as routine entries -- and they sit
    # behind a dispatch, which is the one thing following branches cannot see
    # through. So they are seeds in their own right, not guesses.
    dispatched = {handler for _, handler, _ in keyed_table(memory, ACTION_TABLE)}
    # The same holds for the handlers each object record carries: the same
    # three-byte format, reached through FIND_OBJECT_HANDLER rather than
    # through a branch, and more than half of them reached by the playthrough.
    dispatched |= object_handlers(memory)
    # And RUN_MESSAGE's control codes: a handler per code in CONTROL_CODES, and
    # fifteen of the twenty-three reached in play.
    dispatched |= control_handlers(memory)
    # And the parser's handler per word class, which PARSE_COMMAND jumps to
    # through JP (HL): twelve of the thirteen were reached in play.
    dispatched |= {memory[PARSER_CLASSES + 2 * c] | (memory[PARSER_CLASSES + 2 * c + 1] << 8)
                   for c in range(PARSER_CLASS_COUNT)}
    # And PARSE_SPECIAL's, one per special word -- the game's own commands
    # among them, SAVE and LOAD included, which the playthrough never types.
    handlers = SPECIAL_WORDS + 2 * SPECIAL_COUNT
    dispatched |= {memory[handlers + 2 * i] | (memory[handlers + 2 * i + 1] << 8)
                   for i in range(1, SPECIAL_COUNT)}
    # And the timers' routines, which END_OF_TURN runs through $9B80's
    # JP (HL) -- the wine wearing off among them, at $AB0B.
    dispatched |= timer_handlers(memory)
    # And the routines the characters' scripts run, the same way.
    dispatched |= script_routines(memory)
    # And the arrival hooks, which MOVE runs through RUN_ROUTINE too.
    dispatched |= {hook for _, hook, _ in keyed_table(memory, ARRIVAL_HOOKS)}
    executed = executed | dispatched
    # Follow the branches, then let the CPU overrule the result. A byte in the
    # game's variables reads as CALL NZ,$7874, and following that phantom call
    # decodes everything after it one byte out -- so any instruction this
    # produces that straddles an address the CPU executed is wrong by
    # definition, is struck out, and the walk is done again without it. That
    # converges, and it cannot be argued with: those boundaries came from a
    # real processor, and these came from a table.
    forbidden: set[int] = set()
    for _ in range(12):
        code, indirect, blocked = codemap.walk(memory, executed | {ENTRY},
                                               LOAD_ADDR, GAME_END, barriers,
                                               forbidden)
        straddling = {a for a in code
                      if any((a + o) & 0xFFFF in executed
                             for o in range(1, codemap.decode(memory, a).length))}
        if not straddling:
            break
        forbidden |= straddling
    if forbidden:
        _log(f"  {len(forbidden)} decoded instruction(s) struck out for "
             f"straddling an address the CPU executed")

    # Last containment, and it only ever takes claims away. An instruction the
    # CPU never executed, sitting in a 256-byte page where it executed nothing
    # at all across every command typed, is far likelier to be the database
    # read as code than a routine the playthrough happened to miss -- the pages
    # this drops are $B3xx-$B6xx, which is where the game's own variables live.
    # It would also drop a genuinely unreached routine that happened to sit in
    # an otherwise untouched page, and that is the price: this disassembly
    # would rather be short of code than full of fiction, because nothing
    # downstream can tell the difference.
    hot_pages = {a >> 8 for a in executed}
    cold = {a for a in code if a not in executed and (a >> 8) not in hot_pages}
    if cold:
        code -= cold
        _log(f"  {len(cold)} start(s) dropped from pages the CPU never entered "
             f"({', '.join(f'${p:02X}xx' for p in sorted({a >> 8 for a in cold}))})")

    inside, aimed_at = set(), set()
    for address in code:
        instruction = codemap.decode(memory, address)
        aimed_at.update(instruction.targets)
        for offset in range(1, instruction.length):
            inside.add((address + offset) & 0xFFFF)
    # An executed address inside a decoded instruction is one of two things.
    # If something branches to it deliberately, the game is entering those
    # bytes two ways on purpose -- at $8113 a JR aims at the second byte of an
    # ED 52, so falling in runs SBC HL,DE and jumping in runs the $52 as a
    # one-byte no-op that skips it. That is real, and both readings are code.
    # If nothing aims at it, the decode has drifted out of step and every
    # instruction after it is invented, which nothing downstream would catch.
    disagreed = sorted(executed & inside - aimed_at)
    overlapped = sorted(executed & inside & aimed_at)
    if disagreed:
        sys.exit(
            f"error: {len(disagreed)} address(es) the CPU executed fall inside "
            f"an instruction codemap.py decoded and nothing branches to them, "
            f"first at ${disagreed[0]:04X} -- its instruction lengths are "
            f"wrong, and the disassembly it would produce is invented. Fix "
            f"codemap.py rather than skipping this check.")
    if overlapped:
        _log(f"  {len(overlapped)} address(es) entered both as part of an "
             f"instruction and as one of their own: "
             + ", ".join(f"${a:04X}" for a in overlapped[:4]))

    _log(f"  following branches from there: +{len(code - executed)} more "
         f"instruction starts ({len(indirect)} indirect jumps stopped it)")
    if blocked:
        _log(f"  {len(blocked)} branch(es) into the dictionary ignored -- "
             f"suspicious, since nothing should jump into data")
    return code


def build_code_map(snapshot_path: Path, out: Path, hold: float, gap: float,
                   think: float, settle: float) -> None:
    from skoolkit import CSimulator, read_bin_file
    from skoolkit.simulator import Simulator
    from skoolkit.simutils import PC, T
    from skoolkit.snapshot import Snapshot

    key_tracer_class = _key_tracer_class()
    snapshot = Snapshot.get(str(snapshot_path))
    rom_data = read_bin_file(str(ROM))
    if CSimulator is None:
        _log("  (no C simulator installed -- this will be slow)")

    memory = list(snapshot.memory)
    memory[:0x4000] = rom_data
    # Entered as BASIC enters it: interrupts on, IM 1, IY at the system
    # variables, SP just under RAMTOP. If the game reads the keyboard through
    # the ROM's own routine, all four of those have to be right.
    simulator = (CSimulator or Simulator)(
        memory, registers={"SP": STACK, "IY": SYSVARS},
        state={"iff": 1, "im": 1, "tstates": 0})
    tracer = key_tracer_class(simulator)
    simulator.set_tracer(tracer)

    executed: set[int] = set()
    pc, keystrokes = ENTRY, 0
    commands = WALKTHROUGH + verb_drill(snapshot.memory)
    for keys, seconds in _session_script(commands, hold, gap, think, settle):
        tracer.keys = set(keys)
        simulator.trace(pc, 0, 0,
                        simulator.registers[T] + int(seconds * TSTATES_PER_SECOND),
                        True, None, executed, None, None, None)
        pc = simulator.registers[PC]
        keystrokes += 1 if keys else 0

    ran = {a for a in executed if ENTRY <= a < GAME_END}
    code = extend_by_descent(list(snapshot.memory), ran)

    data = bytearray(65536)
    for address in executed | code:
        data[address] = 1
    out.write_bytes(bytes(data))

    reached = sum(1 for a in range(ENTRY, GAME_END) if data[a])
    _log(f"  {len(commands)} commands typed ({keystrokes} keystrokes); "
         f"{len(executed)} addresses executed, and {reached} instruction "
         f"starts known past the entry point once the branches are followed")
    if reached < 1000:
        _log("  WARNING: too few for a game this size -- the typing is "
             "probably not reaching the parser. Try --hold/--gap/--think.")


# --------------------------------------------------------------------------
# Step 4: map -> control file -> skool -> asm.
# --------------------------------------------------------------------------

def _capture(func, args) -> str:
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        func(args)
    return buf.getvalue()


_BLOCK_RE = re.compile(r"^[bctwsi] \$([0-9A-F]{4})")
_SPAN_RE = re.compile(r"^;\s*span\s+\$([0-9A-F]{4}),(\d+)\s*$")
_COMMENT_RE = re.compile(r"^\s{2}\$([0-9A-F]{4})(?:,(\d+))?\s")


def check_annotations(bare_skool: str) -> None:
    """Report instruction comments that do not line up with instructions.

    A `  $ADDR,N` directive whose address or end lands inside an instruction
    makes sna2skool cut that instruction in half and re-decode from the middle
    of it, which shifts every address after that point. verify() catches the
    damage, but only as a byte count a few too many and a first difference
    hundreds of bytes from the cause -- this says which line did it.

    Both ends are checked. A wrong length is the easy mistake to make, but a
    wrong start address is the one that comes of counting bytes by eye down a
    listing, and it does exactly the same damage.
    """
    if not ANNOTATIONS.exists():
        return
    # Lines are "c$8093 ...", " $8096 ..." or "*$809A ..." -- the star marks a
    # jump target, and those are instruction boundaries just as much as the
    # rest, so the pattern has to allow it.
    boundaries = {int(m.group(1), 16)
                  for m in (re.match(r"^[bctwsi ]?\*?\$([0-9A-F]{4})\s", line)
                            for line in bare_skool.split(NEWLINE)) if m}
    problems = []
    for number, line in enumerate(
            ANNOTATIONS.read_text(encoding="utf-8").split(NEWLINE), 1):
        match = _COMMENT_RE.match(line)
        if not match:
            continue
        address = int(match.group(1), 16)
        nearest = lambda a: min((b for b in boundaries if b >= a), default=None)
        if address not in boundaries:
            suggestion = nearest(address)
            problems.append(
                f"  {ANNOTATIONS.name}:{number}: ${address:04X} is not the "
                f"start of an instruction"
                + (f" -- the next one is ${suggestion:04X}" if suggestion else ""))
            continue
        if match.group(2) is None:
            continue
        end = address + int(match.group(2))
        if end not in boundaries:
            suggestion = nearest(end)
            problems.append(
                f"  {ANNOTATIONS.name}:{number}: ${address:04X},"
                f"{match.group(2)} ends mid-instruction"
                + (f" -- try ,{suggestion - address}" if suggestion else ""))
    # Fatal rather than a warning: a comment that ends mid-instruction makes
    # sna2skool start a new instruction there, which reassembles to the wrong
    # bytes, and the byte count mismatch that follows says nothing of which
    # line did it -- nor is a log line easy to see in the middle of a build.
    if problems:
        sys.exit(f"error: {len(problems)} annotation(s) not lined up with an "
                 f"instruction:" + NEWLINE + NEWLINE.join(problems))


def declared_spans() -> list[tuple[int, int]]:
    """`; span $ADDR,LENGTH` lines in the annotations, as (start, end)."""
    if not ANNOTATIONS.exists():
        return []
    spans = []
    for line in ANNOTATIONS.read_text(encoding="utf-8").splitlines():
        match = _SPAN_RE.match(line)
        if match:
            start = int(match.group(1), 16)
            spans.append((start, start + int(match.group(2))))
    return spans


def strip_spanned_blocks(ctl_text: str, spans: list[tuple[int, int]]) -> str:
    """Drop generated block boundaries that fall inside a declared span.

    A generated `b $ADDR` in the middle of a table the annotations describe as
    one thing splits it in two, and the halves then disagree with the comments.
    The generated file is rebuilt every run, so the fix belongs here rather than
    in the annotations.
    """
    kept = []
    for line in ctl_text.splitlines():
        match = _BLOCK_RE.match(line)
        if match:
            address = int(match.group(1), 16)
            if any(start < address < end for start, end in spans):
                continue
        kept.append(line)
    return NEWLINE.join(kept) + NEWLINE


def build_asm(snapshot: Path, code_map: Path, ctl: Path, skool: Path,
              asm: Path) -> None:
    from skoolkit import skool2asm, sna2ctl, sna2skool

    _log("Generating control file...")
    auto_ctl = _capture(sna2ctl.main, [
        "-m", str(code_map), "-h",
        "-s", str(LOAD_ADDR), "-e", str(GAME_END), str(snapshot),
    ])
    dictionary_ctl = OUT_DIR / "hobbit-dictionary.ctl"
    dictionary_text, dictionary_spans = dictionary_blocks(game_memory(snapshot))
    dictionary_ctl.write_text(dictionary_text, encoding="utf-8")
    pictures_ctl = OUT_DIR / "hobbit-pictures.ctl"
    pictures_text, pictures_spans = picture_blocks(game_memory(snapshot))
    pictures_ctl.write_text(pictures_text, encoding="utf-8")
    messages_ctl = OUT_DIR / "hobbit-messages.ctl"
    code_starts = {a for a, flag in enumerate(code_map.read_bytes()) if flag}
    messages_text, messages_spans = message_blocks(
        game_memory(snapshot), message_pointers(game_memory(snapshot), code_starts))
    messages_ctl.write_text(messages_text, encoding="utf-8")
    rooms_ctl = OUT_DIR / "hobbit-rooms.ctl"
    rooms_text, rooms_spans = room_blocks(game_memory(snapshot))
    rooms_ctl.write_text(rooms_text, encoding="utf-8")
    objects_ctl = OUT_DIR / "hobbit-objects.ctl"
    objects_text, objects_spans = object_blocks(game_memory(snapshot))
    objects_ctl.write_text(objects_text, encoding="utf-8")
    scripts_ctl = OUT_DIR / "hobbit-scripts.ctl"
    scripts_text, scripts_spans = script_blocks(game_memory(snapshot))
    scripts_ctl.write_text(scripts_text, encoding="utf-8")
    _log(f"  {objects_text.count('label=OBJ') + objects_text.count('label=PLAYER')} object records, every one ending "
         f"exactly where the next begins")
    _log(f"  {pictures_text.count('label=LOC')} location pictures, every one "
         f"parsed to its $00 by RUN_PICTURE's own grammar")

    spans = (dictionary_spans + pictures_spans + objects_spans + rooms_spans + scripts_spans
             + messages_spans + declared_spans())
    kept = strip_spanned_blocks(auto_ctl, spans)
    if spans:
        dropped = auto_ctl.count(NEWLINE) - kept.count(NEWLINE)
        _log(f"  {len(spans)} declared span(s); dropped {dropped} generated "
             f"block boundar{'y' if dropped == 1 else 'ies'} inside them")
    ctl.write_text(kept, encoding="utf-8")

    _log("Generating skool file...")
    # ANNOTATIONS is layered over the generated control file: sna2skool takes -c
    # more than once and merges them, later files winning. That split is what
    # lets the code/data map be regenerated from scratch on every run without
    # throwing away the hand-written comments.
    ctls = ["-c", str(ctl), "-c", str(dictionary_ctl), "-c", str(pictures_ctl),
            "-c", str(objects_ctl), "-c", str(rooms_ctl), "-c", str(messages_ctl),
            "-c", str(scripts_ctl)]
    if ANNOTATIONS.exists():
        # Disassemble once without the annotations' prose first, purely to
        # learn where the instruction boundaries are, so a comment on the
        # wrong address is reported by line number rather than as a byte
        # count mismatch a long way downstream. The pass needs the block
        # directives -- a block forced from data to code has no instruction
        # boundaries without them, and every comment inside it then looks
        # misaligned -- so those are kept and everything else stripped. The
        # sub-block directives are kept too: they set the boundaries of a data
        # block, and without them its comments look misaligned against the
        # default eight-byte lines.
        structure = OUT_DIR / "hobbit-structure.ctl"
        structure.write_text(NEWLINE.join(
            " ".join(line.split(" ", 2)[:2])
            for line in ANNOTATIONS.read_text(encoding="utf-8").splitlines()
            if re.match(r"^[bctwsiBCTWS] \$[0-9A-F]{4}", line)), encoding="utf-8")
        check_annotations(_capture(sna2skool.main,
                                  ["-H", "-c", str(ctl), "-c", str(dictionary_ctl),
                                   "-c", str(pictures_ctl), "-c", str(objects_ctl),
                                   "-c", str(rooms_ctl), "-c", str(messages_ctl),
                                   "-c", str(scripts_ctl),
                                   "-c", str(structure),
                                   str(snapshot)]))
        ctls += ["-c", str(ANNOTATIONS)]
    else:
        _log(f"  (no annotations file at {ANNOTATIONS} -- output will be bare)")
    skool.write_text(_capture(sna2skool.main, ["-H", *ctls, str(snapshot)]),
                     encoding="utf-8")

    _log("Generating assembly...")
    # -c invents a label for every entry point and jump target, so the listing
    # reads as `JP L6C00` rather than `JP 27648`.
    text = _capture(skool2asm.main, ["-H", "-c", str(skool)])
    # sjasmplus needs a DEVICE directive to know the memory layout, and
    # skool2asm has no reason to emit one. It goes into the .asm itself rather
    # than a build-only copy so that the .sld sjasmplus produces refers to this
    # file, at these line numbers -- which is what makes source-level debugging
    # against it work.
    asm.write_text("    DEVICE ZXSPECTRUM48\n" + text, encoding="utf-8")


# --------------------------------------------------------------------------
# Step 5: assemble it back and prove it round-trips.
# --------------------------------------------------------------------------

def assemble(asm: Path, sld: Path) -> bytes:
    sjasmplus = str(SJASMPLUS) if SJASMPLUS.exists() else "sjasmplus"
    raw = OUT_DIR / "hobbit.rawbin"
    _log("Assembling with sjasmplus...")
    result = subprocess.run(
        [sjasmplus, asm.name, f"--sld={sld.name}", "--fullpath",
         f"--raw={raw.name}"],
        cwd=OUT_DIR, text=True, capture_output=True)
    if result.returncode != 0:
        sys.exit(f"error: sjasmplus failed:\n{result.stdout}\n{result.stderr}")
    game_bytes = raw.read_bytes()
    raw.unlink()
    return game_bytes


def verify(game_bytes: bytes, snapshot: Path) -> None:
    reference = bytes(game_memory(snapshot)[LOAD_ADDR:GAME_END])
    if len(game_bytes) != len(reference):
        sys.exit(f"error: assembled {len(game_bytes)} bytes, expected "
                 f"{len(reference)}")
    if game_bytes != reference:
        differing = sum(1 for a, b in zip(game_bytes, reference) if a != b)
        first = next(i for i, (a, b) in enumerate(zip(game_bytes, reference))
                     if a != b)
        sys.exit(f"error: assembled output differs from the loaded game in "
                 f"{differing} bytes, first at 0x{LOAD_ADDR + first:04X} -- the "
                 f"disassembly is not faithful")
    _log(f"Verified: {len(game_bytes)} bytes reassemble byte-for-byte")


def write_snapshot(game_bytes: bytes, snapshot: Path, out: Path) -> None:
    """Splice the assembled bytes into the loaded RAM image.

    Starting from the real post-load image rather than a blank one keeps what
    the game needs but the disassembly does not contain: the title picture at
    $4000, and the system variables the BASIC loader set.
    """
    memory = list(game_memory(snapshot))
    memory[LOAD_ADDR:GAME_END] = game_bytes
    ram = bytes(bytearray(memory[0x4000:0x4000 + RAM_SIZE]))
    regs = Registers(pc=ENTRY, sp=STACK, iy=SYSVARS, im=1, iff1=True, iff2=True)
    out.write_bytes(write_sna(regs, ram, border=0))


def build_html(skool: Path, out: Path) -> None:
    from skoolkit import skool2html

    import hobbit_pages

    # The locations, objects, characters and actions pages carry the game's
    # own text and pictures, so they are generated into the output here rather
    # than kept with the committed ref file (see scripts/hobbit_pages.py).
    pages = OUT_DIR / "hobbit-pages.ref"
    hobbit_pages.build(out, pages)

    _log("Building HTML disassembly...")
    # -a: operands and links read GANDALF_A and DRAW_LINE, as the source
    # does, rather than $C8C2 and $8151.
    args = ["-d", str(out), "-t", "-a"]
    args.append(str(skool))
    if REF.exists():
        args.append(str(REF))
    args.append(str(pages))
    _capture(skool2html.main, args)


def main() -> None:
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--tape", required=True, type=Path,
                        help="the Hobbit .tzx or .tap to disassemble "
                             "(v1.2 is the one to use)")
    parser.add_argument("--html", action="store_true",
                        help="also write a browsable HTML disassembly under "
                             "game_disassembly/hobbit/html/")
    parser.add_argument("--hold", type=float, default=0.10,
                        help="seconds a key is held down (default 0.10)")
    parser.add_argument("--gap", type=float, default=0.06,
                        help="seconds between keys (default 0.06)")
    parser.add_argument("--think", type=float, default=3.0,
                        help="seconds given to the game after ENTER "
                             "(default 3.0)")
    parser.add_argument("--settle", type=float, default=8.0,
                        help="seconds either side of the title-screen keypress, "
                             "while the opening picture fills and the keyboard "
                             "is ignored (default 8.0; below 8 the first "
                             "command is lost)")
    args = parser.parse_args()

    if not args.tape.exists():
        sys.exit(f"error: {args.tape} not found")
    if not ROM.exists():
        sys.exit(f"error: {ROM} not found -- see README.md for where to get it")
    try:
        import skoolkit  # noqa: F401
    except ImportError:
        sys.exit("error: skoolkit not installed.\n"
                 "Install with: pip install skoolkit")

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    snapshot = OUT_DIR / "hobbit.z80"
    code_map = OUT_DIR / "hobbit.map"
    ctl = OUT_DIR / "hobbit.ctl"
    skool = OUT_DIR / "hobbit.skool"
    asm = OUT_DIR / "hobbit.asm"
    sld = OUT_DIR / "hobbit.sld"
    sna = OUT_DIR / "hobbit.sna"

    make_snapshot(args.tape, snapshot)
    _log("Playing the game to find out which addresses are code...")
    build_code_map(snapshot, code_map, args.hold, args.gap, args.think,
                   args.settle)
    build_asm(snapshot, code_map, ctl, skool, asm)
    game_bytes = assemble(asm, sld)
    verify(game_bytes, snapshot)
    write_snapshot(game_bytes, snapshot, sna)
    if args.html:
        build_html(skool, OUT_DIR / "html")

    _log("")
    _log(f"Entry point: 0x{ENTRY:04X} (PRINT USR 27648)")
    _log(f"Wrote {asm}, {sld}, and {sna}")
    _log("Load roms/48.rom first (write_sna doesn't touch it), then this "
         ".sna + .sld.")


if __name__ == "__main__":
    main()
