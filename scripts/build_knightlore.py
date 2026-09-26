#!/usr/bin/env python3
"""Knight Lore (1984, Ultimate Play the Game) -- a reproducible disassembly.

Run it against a snapshot you own:

    python scripts/build_knightlore.py --snapshot "Knight Lore (1984)(Ultimate).sna"

Unlike the Atic Atac build there is no tape stage and no simulator. That game's
tape carried its own decryptor and had to be run to get at the code, and the map
of which bytes are instructions had to be discovered by playing it. Here the
input is already a post-load image and the map is known: see
scripts/knightlore_structure.ctl for where it comes from and what is taken from
it.

What this does, in order:

  1. Reads the code map -- which bytes are instructions, which are data, and
     what the routines are called -- from scripts/knightlore_structure.ctl.
  2. Lays scripts/knightlore_annotations.ctl over the top. That file is the
     hand-written half and the only one to edit.
  3. Disassembles, assembles the result back with sjasmplus, and compares it
     with the snapshot. A run that finishes has proved its own output byte for
     byte, which is what keeps the map honest: a boundary in the wrong place
     shows up as a mismatch rather than as quiet nonsense.

The memory map, read off the snapshot rather than assumed:

  $5BA0..$6107  the game's variables, with the stack below them (SP was
                $5B96). Live state rather than program, so it is documented
                rather than disassembled -- disassembling it would only record
                what one moment happened to hold.
  $6108..$D8F2  code and data, 30699 bytes. It opens with the status font.
  $D8F3..$F0F2  the screen buffer the drawing code composes rooms into.
  $F100..$FFFF  lookup tables built at run time. $F100 is reverse_bits(n),
                which is what mirroring a sprite horizontally needs.

Everything from $6108 up is disassembled, buffers and all: they are part of the
map even when a snapshot catches them empty.

To rebuild the code map from a SkoolKit disassembly:

    python scripts/build_knightlore.py --from-skool PATH/TO/knightlore.skool

This shares a good deal of its shape with build_aticatac.py -- the round trip,
the snapshot handling. That duplication is deliberate for now. Factoring the
harness out is worth doing once this build has settled, with both games as the
test that the extraction did not change anything.
"""
from __future__ import annotations

import argparse
import contextlib
import functools
import io
import re
import subprocess
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = PROJECT_ROOT / "game_disassembly" / "knightlore"
STRUCTURE = PROJECT_ROOT / "scripts" / "knightlore_structure.ctl"
ANNOTATIONS = PROJECT_ROOT / "scripts" / "knightlore_annotations.ctl"
REF = PROJECT_ROOT / "scripts" / "knightlore.ref"
SJASMPLUS = PROJECT_ROOT / "tools" / "sjasmplus" / "sjasmplus.exe"

sys.path.insert(0, str(Path(__file__).resolve().parent))

from sna import RAM_SIZE, Registers, write_sna  # noqa: E402

# The game occupies everything from here to the top of memory. Below it are the
# system variables, the game's own variables and the stack, which hold state
# rather than program.
ENTRY = 0x6108
GAME_END = 0x10000

NEWLINE = chr(10)


def _log(message: str) -> None:
    print(message, flush=True)


@functools.lru_cache(maxsize=None)
def _read_snapshot(path: str) -> tuple:
    from skoolkit.snapshot import Snapshot

    return tuple(Snapshot.get(path).memory)


def game_memory(snapshot: Path) -> tuple:
    """The snapshot's 64K, read once and shared. Read-only."""
    return _read_snapshot(str(snapshot))


def snapshot_state(snapshot: Path):
    """The snapshot's registers, as SkoolKit reads them."""
    from skoolkit.snapshot import Snapshot

    return Snapshot.get(str(snapshot))


def _capture(func, args) -> str:
    buffer = io.StringIO()
    with contextlib.redirect_stdout(buffer):
        func(args)
    return buffer.getvalue()


# --------------------------------------------------------------------------
# The code map.
# --------------------------------------------------------------------------

def check_coverage(ctl_text: str) -> None:
    """The map's blocks must run in order from $6108 up.

    A control file that leaves a hole disassembles to an asm file with a hole
    in it, and sjasmplus fills the gap with zeros rather than complaining. The
    round trip then fails somewhere far from the cause. Checking here says
    which block is out of place instead.
    """
    starts = []
    for line in ctl_text.splitlines():
        if len(line) > 2 and line[0] in "bcgistuw" and line[1] == " ":
            text = line[2:].split()[0]
            starts.append(int(text[1:], 16) if text.startswith("$")
                          else int(text))
    if not starts:
        sys.exit("error: the code map declares no blocks at all")
    if sorted(starts) != starts:
        sys.exit("error: the code map's blocks are not in address order")
    if starts[0] != ENTRY:
        sys.exit(f"error: the code map starts at ${starts[0]:04X}, expected "
                 f"${ENTRY:04X}")
    _log(f"  {len(starts)} blocks, ${starts[0]:04X}..${GAME_END - 1:04X}, "
         f"in order")


_SKOOL_ADDRESS = re.compile(r"^[ bcgistuw*]\$([0-9A-F]{4}) ")
_CTL_LABEL = re.compile(r"^@ \$([0-9A-F]{4}) label=")
_CTL_COMMENT = re.compile(r"^  \$([0-9A-F]{4}),(\d+) ")


def check_alignment(skool_text: str) -> None:
    """Nothing in either control file may land in the middle of an instruction.

    An instruction comment written as `  $ADDR,N` claims N bytes. If N stops
    short of the end of an instruction, SkoolKit does not complain: it starts
    decoding again from wherever the count ran out, reading the tail of one
    instruction as the head of another. The disassembly from there on is
    plausible, differently sized, and wrong.

    It does eventually fail -- the round trip cannot come out the right length
    -- but it fails as an assembler error about the last line of the file,
    thousands of lines away from the annotation that caused it. Checking here
    names the annotation instead.
    """
    starts = set()
    for line in skool_text.splitlines():
        match = _SKOOL_ADDRESS.match(line)
        if match:
            starts.add(int(match.group(1), 16))

    problems = []
    for address in sorted(_directives(STRUCTURE, _CTL_LABEL)):
        if address not in starts:
            problems.append(f"  ${address:04X} is labelled but is not the "
                            f"start of anything")
    for line in _lines(ANNOTATIONS):
        match = _CTL_COMMENT.match(line)
        if not match:
            continue
        address, length = int(match.group(1), 16), int(match.group(2))
        if address not in starts:
            problems.append(f"  ${address:04X} is commented but is not the "
                            f"start of an instruction")
        elif address + length not in starts:
            problems.append(f"  ${address:04X},{length} ends mid-instruction "
                            f"at ${address + length:04X}")
    if problems:
        sys.exit("error: control file entries do not line up with the code:"
                 + NEWLINE + NEWLINE.join(problems))
    _log(f"  {len(starts)} instruction and data starts; every label and "
         f"comment lands on one")


_CTL_SUBBLOCK = re.compile(r"^([BCSTW]) \$([0-9A-F]{4}),")
_CTL_DATA = re.compile(r"^([BW]) \$([0-9A-F]{4}),(\d+)")


def trim_overlaps(ctl_text: str, generated: str = "") -> tuple[str, int]:
    """Drop map sub-blocks that a hand-written comment cuts across.

    The map describes runs of instructions in one directive, carrying the
    number base each operand should print in. An instruction comment inside
    such a run describes the same bytes a second way, and SkoolKit warns about
    the overlap on every build. Since a later control file can add boundaries
    but never remove them, the run has to go before the merge rather than
    after; the only thing lost with it is the operand base, and the whole
    disassembly is generated in hex anyway.
    """
    spans = [(int(m.group(1), 16), int(m.group(1), 16) + int(m.group(2)))
             for m in (_CTL_COMMENT.match(line) for line in _lines(ANNOTATIONS))
             if m]
    # The generated level data lays its tables out a record per line, which
    # cuts across the map's rows the same way a comment does.
    spans += [(int(m.group(2), 16), int(m.group(2), 16) + int(m.group(3)))
              for m in (_CTL_DATA.match(line) for line in generated.splitlines())
              if m]
    if not spans:
        return ctl_text, 0
    commented = {start for start, _ in spans}
    lines = ctl_text.splitlines()
    # A sub-block runs until the next directive of any kind.
    extent = []
    for index, line in enumerate(lines):
        match = _CTL_SUBBLOCK.match(line)
        if match:
            extent.append((index, int(match.group(2), 16)))
    bounds = {}
    for position, (index, address) in enumerate(extent):
        following = (extent[position + 1][1] if position + 1 < len(extent)
                     else GAME_END)
        bounds[index] = (address, following)
    # Two ways to clash: the map's run swallows a comment's first byte, or the
    # run begins partway through what a comment already describes.
    drop = {index for index, (start, end) in bounds.items()
            if any(start < address < end for address in commented)
            or any(low < start < high for low, high in spans)}
    kept = [line for index, line in enumerate(lines) if index not in drop]
    return NEWLINE.join(kept), len(drop)


def _lines(path: Path) -> list[str]:
    return (path.read_text(encoding="utf-8").splitlines()
            if path.exists() else [])


def _directives(path: Path, pattern: re.Pattern) -> list[int]:
    return [int(m.group(1), 16) for m in
            (pattern.match(line) for line in _lines(path)) if m]


# The reference disassembly stops at $D8F2 and marks the rest ignored: the
# screen buffer and the lookup tables the game builds at run time. We
# disassemble those too, so each becomes a data block on the way in.
IGNORED_BLOCKS = {
    "i $D8F3": ("# Screen buffer. The drawing code composes a room here, and "
                "the copy to display reads it back.", "b $D8F3"),
    "i $F0F3": (None, "b $F0F3"),
    "i $F100": ("# Built at run time: shifted-sprite and bit-reversed-byte "
                "lookups.", "b $F100"),
}

# The reference's last byte is a lone DEFB at the very top of memory; it belongs
# to the $F100 table block rather than standing on its own.
ABSORBED = ("b $FFFF", "B $FFFF,1,h1")


def regenerate(reference: Path) -> None:
    """Rewrite the code map from a SkoolKit disassembly.

    Only the factual layer is taken -- "-w abs" is ASM directives, block types
    and addresses, and sub-block types and addresses. No titles, no
    descriptions, no instruction comments. The header of
    scripts/knightlore_structure.ctl says why, and is preserved across a
    regeneration.
    """
    from skoolkit import skool2ctl

    if not reference.exists():
        sys.exit(f"error: no skool file at {reference}")
    text = _capture(skool2ctl.main,
                    ["-h", "-b", "-w", "abs", "-S", str(ENTRY), str(reference)])
    # The header is the leading run of comment lines and nothing else. Taking
    # every '#' line instead would drag the comments that sit against a block
    # up to the top, away from what they describe.
    header = []
    for line in STRUCTURE.read_text(encoding="utf-8").splitlines():
        if not line.startswith("#"):
            break
        header.append(line)
    header = NEWLINE.join(header)
    # Without a start directive skool2asm treats the whole file as excluded and
    # writes nothing at all, silently and in no time. Without org there is
    # nothing to tell sjasmplus where the bytes go.
    body = [f"@ ${ENTRY:04X} start", f"@ ${ENTRY:04X} org"]
    for line in text.splitlines():
        if line in IGNORED_BLOCKS:
            comment, block = IGNORED_BLOCKS[line]
            if comment:
                body.append(comment)
            body.append(block)
        elif line in ABSORBED:
            continue
        elif line.startswith("i "):
            sys.exit(f"error: unhandled ignored block {line!r} -- decide what "
                     f"it is before letting the build past it")
        else:
            body.append(line)
    STRUCTURE.write_text(header + NEWLINE * 2 + NEWLINE.join(body) + NEWLINE,
                         encoding="utf-8")
    _log(f"Wrote {STRUCTURE} ({len(body)} directives)")


# --------------------------------------------------------------------------
# Map -> skool -> asm -> bytes.
# --------------------------------------------------------------------------

def build_asm(snapshot: Path, skool: Path, asm: Path) -> None:
    from skoolkit import skool2asm, sna2skool

    _log("Reading the code map...")
    if not STRUCTURE.exists():
        sys.exit(f"error: no code map at {STRUCTURE}")
    check_coverage(STRUCTURE.read_text(encoding="utf-8"))

    _log("Generating skool file...")
    merged = OUT_DIR / "knightlore-map.ctl"
    # The rooms, the background pieces and the charms' places, a record per
    # line, generated from the snapshot rather than committed: see
    # knightlore_data.py.
    from knightlore_data import data_blocks
    data_ctl = OUT_DIR / "knightlore-data.ctl"
    generated = data_blocks(game_memory(snapshot))
    data_ctl.write_text(generated, encoding="utf-8")
    trimmed, dropped = trim_overlaps(STRUCTURE.read_text(encoding="utf-8"), generated)
    merged.write_text(trimmed + NEWLINE, encoding="utf-8")
    if dropped:
        _log(f"  dropped {dropped} map sub-block(s) that an annotation "
             f"comments across")
    ctls = ["-c", str(merged), "-c", str(data_ctl)]
    if ANNOTATIONS.exists():
        ctls += ["-c", str(ANNOTATIONS)]
    else:
        _log(f"  (no annotations file at {ANNOTATIONS} -- output will be bare)")
    # ListRefs=2: every entry gets its "Used by the routines at ..." line.
    # sna2skool's default writes it only for an entry with no comment of its
    # own, so each routine described here would lose its callers.
    skool_text = _capture(sna2skool.main,
                          ["-H", "-I", "ListRefs=2", *ctls, str(snapshot)])
    skool.write_text(skool_text, encoding="utf-8")
    check_alignment(skool_text)

    _log("Generating assembly...")
    text = _capture(skool2asm.main, ["-H", "-c", str(skool)])
    # sjasmplus needs a DEVICE directive to know the memory layout, and
    # skool2asm has no reason to emit one.
    lines = text.splitlines()
    for index, line in enumerate(lines):
        if line.strip().startswith("ORG"):
            lines.insert(index, "  DEVICE ZXSPECTRUM48")
            break
    asm.write_text(NEWLINE.join(lines) + NEWLINE, encoding="utf-8")
    _log(f"Wrote ASM ({len(lines)} lines)")


def assemble(asm: Path, sld: Path) -> bytes:
    sjasmplus = str(SJASMPLUS) if SJASMPLUS.exists() else "sjasmplus"
    raw = OUT_DIR / "knightlore.rawbin"
    _log("Assembling with sjasmplus...")
    result = subprocess.run(
        [sjasmplus, asm.name, f"--sld={sld.name}", "--fullpath",
         f"--raw={raw.name}"],
        cwd=OUT_DIR, text=True, capture_output=True)
    if result.returncode != 0:
        sys.exit(f"error: sjasmplus failed:{NEWLINE}{result.stdout}"
                 f"{NEWLINE}{result.stderr}")
    game_bytes = raw.read_bytes()
    raw.unlink()
    return game_bytes


def build_html(skool: Path, out: Path) -> None:
    """Render the skool file as a browsable HTML disassembly.

    -a makes the pages use the labels from the code map rather than bare
    addresses, so a call reads as CALL START there too, and the #R macros in
    the ref file's prose resolve to links with those same names.
    """
    from skoolkit import skool2html

    _log("Writing HTML disassembly...")
    args = ["-H", "-a", "-d", str(out), str(skool)]
    if REF.exists():
        args.append(str(REF))
    else:
        _log(f"  (no ref file at {REF} -- pages will be untitled)")
    _capture(skool2html.main, args)
    _log(f"  {out / 'knightlore' / 'index.html'}")


# The Spectrum's colours, normal and BRIGHT, for drawing the screen.
SPECTRUM = [(0, 0, 0), (0, 0, 0xD7), (0xD7, 0, 0), (0xD7, 0, 0xD7),
            (0, 0xD7, 0), (0, 0xD7, 0xD7), (0xD7, 0xD7, 0), (0xD7, 0xD7, 0xD7)]
SPECTRUM_BRIGHT = [(0, 0, 0), (0, 0, 0xFF), (0xFF, 0, 0), (0xFF, 0, 0xFF),
                   (0, 0xFF, 0), (0, 0xFF, 0xFF), (0xFF, 0xFF, 0), (0xFF, 0xFF, 0xFF)]


def render_menu(snapshot: Path, out_dir: Path) -> None:
    """The picture on the site's landing page: the control-method menu, which
    is what the snapshot holds on the screen -- the game's own drawing, read
    out of screen memory, not a capture."""
    from PIL import Image

    memory = game_memory(snapshot)
    image = Image.new("RGB", (256, 192))
    pixels = image.load()
    for y in range(192):
        row = 0x4000 | ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2)
        for column in range(32):
            byte = memory[row + column]
            attr = memory[0x5800 + (y >> 3) * 32 + column]
            palette = SPECTRUM_BRIGHT if attr & 0x40 else SPECTRUM
            ink, paper = palette[attr & 7], palette[(attr >> 3) & 7]
            for bit in range(8):
                pixels[column * 8 + bit, y] = ink if byte & (0x80 >> bit) else paper
    out_dir.mkdir(parents=True, exist_ok=True)
    image.resize((512, 384), Image.NEAREST).save(out_dir / "menu.png")
    _log(f"  {out_dir / 'menu.png'}")


def verify(game_bytes: bytes, snapshot: Path) -> None:
    """The whole point: what came out must be what went in."""
    reference = bytes(game_memory(snapshot)[ENTRY:GAME_END])
    if game_bytes == reference:
        _log(f"Verified: {len(game_bytes)} bytes reassemble byte-for-byte")
        return
    if len(game_bytes) != len(reference):
        sys.exit(f"error: assembled {len(game_bytes)} bytes, expected "
                 f"{len(reference)}")
    bad = [i for i, (a, b) in enumerate(zip(game_bytes, reference)) if a != b]
    detail = ", ".join(f"${ENTRY + i:04X}" for i in bad[:8])
    sys.exit(f"error: {len(bad)} byte(s) differ, first at {detail}")


def write_snapshot(game_bytes: bytes, snapshot: Path, out: Path) -> None:
    """The assembled bytes spliced back into the snapshot's RAM.

    Starting from the real image rather than a blank one keeps what the game
    needs but the disassembly does not contain: the screen at $4000, the
    variables at $5BA0 and the system variables underneath them.

    Every register is carried across, not just PC. Atic Atac's build could get
    away with inventing them because it enters at the game's cold-start address
    with nothing live; this snapshot is taken mid-frame, and a machine resumed
    without its IX, IY and alternates does not carry on playing.

    Note what SP means in each place. The .sna header holds SP *after* PC has
    been pushed, which is what SkoolKit reports; write_sna() does the pushing
    itself and so wants the value from before. Passing SkoolKit's number
    straight through leaves the rebuilt machine two bytes into its own stack.
    """
    memory = list(game_memory(snapshot))
    memory[ENTRY:GAME_END] = game_bytes
    ram = bytes(bytearray(memory[0x4000:0x4000 + RAM_SIZE]))
    state = snapshot_state(snapshot)
    regs = Registers(
        pc=state.pc, sp=(state.sp + 2) & 0xFFFF,
        af=(state.a << 8) | state.f, bc=state.bc, de=state.de, hl=state.hl,
        ix=state.ix, iy=state.iy, ir=(state.i << 8) | state.r,
        af2=(state.a2 << 8) | state.f2, bc2=state.bc2, de2=state.de2,
        hl2=state.hl2, im=state.im,
        iff1=bool(state.iff1), iff2=bool(state.iff2))
    rebuilt = write_sna(regs, ram, border=state.border)
    out.write_bytes(rebuilt)

    # Since every byte of this file comes either from the disassembly or from
    # the snapshot it was made from, it should be that snapshot. Saying so
    # covers what verify() cannot: that the registers came across, and that SP
    # means the same thing here as it does in the header.
    original = snapshot.read_bytes()
    if rebuilt == original:
        _log(f"Verified: the snapshot it writes is the snapshot it read, "
             f"all {len(rebuilt)} bytes")
        return
    bad = [i for i, (a, b) in enumerate(zip(rebuilt, original)) if a != b]
    where = ", ".join(f"header byte {i}" if i < 27 else f"${0x4000 + i - 27:04X}"
                      for i in bad[:6])
    _log(f"warning: the snapshot differs from the one it was built from in "
         f"{len(bad)} byte(s): {where}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.split(NEWLINE)[0])
    parser.add_argument("--snapshot", type=Path,
                        help="a Knight Lore .sna you own")
    parser.add_argument("--from-skool", type=Path, metavar="FILE",
                        help="rebuild the code map from a SkoolKit "
                             "disassembly, then exit")
    parser.add_argument("--html", action="store_true",
                        help="also write a browsable HTML disassembly")
    args = parser.parse_args()

    if args.from_skool:
        regenerate(args.from_skool)
        return
    if not args.snapshot:
        sys.exit("error: --snapshot is required")
    if not args.snapshot.exists():
        sys.exit(f"error: no snapshot at {args.snapshot}")
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    skool = OUT_DIR / "knightlore.skool"
    asm = OUT_DIR / "knightlore.asm"
    sld = OUT_DIR / "knightlore.sld"
    sna = OUT_DIR / "knightlore.sna"

    build_asm(args.snapshot, skool, asm)
    game_bytes = assemble(asm, sld)
    verify(game_bytes, args.snapshot)
    write_snapshot(game_bytes, args.snapshot, sna)
    if args.html:
        build_html(skool, OUT_DIR / "html")
        render_menu(args.snapshot, OUT_DIR / "html" / "knightlore" / "images")
    _log(f"{NEWLINE}Wrote {asm}, {sld} and {sna}")


if __name__ == "__main__":
    main()
