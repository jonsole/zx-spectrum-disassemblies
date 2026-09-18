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

  - bytes 0 and 1 are always letters, because their top three bits are used
    for the word's part of speech -- so bit 7 there is not a terminator;
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
game_disassembly/, gitignored, never committed. Nothing in this script exports
the game's prose -- the messages and location descriptions stay in the game's
own bytes. Prior work consulted for addresses, and credited rather than copied:
pobtastic's SkoolKit disassembly at skoolkit.arcadegeek.co.uk/hobbit and the
data-format notes at icemark.com/dataformats/hobbit.

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

# Part of speech, read off the top three bits of an entry's first two bytes.
# These are the groupings that are unambiguous -- every word in each one is the
# same kind of word. Pairs not listed here are left as a bare code in the
# comment rather than guessed at; see hobbit_annotations.ctl for what is open.
WORD_CLASSES = {
    (0, 7): "verb",
    (1, 1): "noun",
    (1, 2): "adjective",
    (0, 2): "direction",
    (1, 3): "preposition",
    (0, 0): "adverb",
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
                 cls: tuple[int, int], synonym_of: int | None):
        self.address = address
        self.length = length
        self.text = text
        self.cls = cls
        self.synonym_of = synonym_of

    @property
    def part_of_speech(self) -> str:
        return WORD_CLASSES.get(self.cls, f"class {self.cls[0]},{self.cls[1]}")


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
        cls = (memory[address] >> 5, memory[address + 1] >> 5)
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
        "D $6040 One 5-bit letter code per byte (A=1..Z=26, 0 for none). The "
        "top three bits of the first two bytes are the part of speech, so bit 7 "
        "is not a terminator there; from the third byte on, bit 7 marks the "
        "last letter. A terminator with bit 6 set is followed by a 2-byte "
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


def _session_script(hold: float, gap: float, think: float, settle: float):
    """(keys-held, seconds) steps: dismiss the title screen, then type.

    `settle` is not padding. The game answers the title screen by drawing Bag
    End and flood-filling it, and it does not look at the keyboard until that
    finishes, so anything typed before then is thrown away. Measured: at a
    2-second settle the first command is lost entirely (one LOOK finds 1 new
    instruction), at 5 seconds it is still being lost, and at 8 it lands and
    the same single LOOK finds 1392. Longer buys nothing.
    """
    script = [([], settle), (["SPACE"], 0.2), ([], settle)]
    for command in WALKTHROUGH:
        for char in command + "\n":
            script.append((_keys_for(char), hold))
            script.append(([], gap))
        # The game has to parse, move every other character, work out what
        # happened and redraw the picture before it will look at the keyboard
        # again; typing over the top of that loses the next command.
        script.append(([], think))
    return script


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
    for keys, seconds in _session_script(hold, gap, think, settle):
        tracer.keys = set(keys)
        simulator.trace(pc, 0, 0,
                        simulator.registers[T] + int(seconds * TSTATES_PER_SECOND),
                        True, None, executed, None, None, None)
        pc = simulator.registers[PC]
        keystrokes += 1 if keys else 0

    data = bytearray(65536)
    for address in executed:
        data[address] = 1
    out.write_bytes(bytes(data))

    reached = sum(1 for a in range(ENTRY, GAME_END) if data[a])
    _log(f"  {len(WALKTHROUGH)} commands typed ({keystrokes} keystrokes); "
         f"{len(executed)} addresses executed, {reached} of them past the "
         f"entry point")
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
    if problems:
        _log(f"{len(problems)} annotation(s) not lined up with an instruction:")
        for problem in problems:
            _log(problem)


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

    spans = dictionary_spans + declared_spans()
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
    ctls = ["-c", str(ctl), "-c", str(dictionary_ctl)]
    if ANNOTATIONS.exists():
        # Disassemble once without the annotations' prose first, purely to
        # learn where the instruction boundaries are, so a comment on the
        # wrong address is reported by line number rather than as a byte
        # count mismatch a long way downstream. The pass needs the block
        # directives -- a block forced from data to code has no instruction
        # boundaries without them, and every comment inside it then looks
        # misaligned -- so those are kept and everything else stripped.
        structure = OUT_DIR / "hobbit-structure.ctl"
        structure.write_text(NEWLINE.join(
            " ".join(line.split(" ", 2)[:2])
            for line in ANNOTATIONS.read_text(encoding="utf-8").splitlines()
            if re.match(r"^[bctwsi] \$[0-9A-F]{4}", line)), encoding="utf-8")
        check_annotations(_capture(sna2skool.main,
                                  ["-H", "-c", str(ctl), "-c", str(dictionary_ctl),
                                   "-c", str(structure), str(snapshot)]))
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

    _log("Building HTML disassembly...")
    args = ["-d", str(out), "-t"]
    if REF.exists():
        args.append(str(REF))
    args.append(str(skool))
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
