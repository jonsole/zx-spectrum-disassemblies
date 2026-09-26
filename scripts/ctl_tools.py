"""Tools for writing annotation control files against a game's listing.

    python scripts/ctl_tools.py ranges SKOOL DRAFT OUT
    python scripts/ctl_tools.py check SKOOL FRAGMENT START END

An instruction comment in a control file is written `  $ADDR,N Comment`,
where N is a byte count. Get N wrong and sna2skool neither complains nor
stops: it resumes decoding wherever the count ran out, and every address after
it shifts. Counting bytes by eye is how that happens (see docs/game-examples.md,
Knight Lore).

ranges -- write the draft with instruction ranges instead, `  $A-$B Comment`
          covering the instructions from $A to $B inclusive, or `  $A Comment`
          for one instruction, and this turns each into `$A,N` with N read
          from the listing. It also reports any #R$ADDR that is not the start
          of an entry, since those make dead links.

check   -- the checks to run on a fragment before merging it: every instruction
          comment starts on an instruction and ends on one; every block and
          sub-block starts where the listing has something; every entry in
          [START, END) has a title line; no label ends in _<digit> (skool2asm
          makes NAME_0, NAME_1 for jump targets), none is used twice or
          clashes with the listing's; nothing lies outside the range. It ends
          "OK" or with the number of problems.

SKOOL is the game's generated listing (game_disassembly/<game>/<game>.skool).
Knight Lore's description work was split across eight agents, and three of
them wrote the range converter for themselves -- which is why it is here.
"""
from __future__ import annotations

import bisect
import re
import sys
from pathlib import Path


def read_listing(skool: Path) -> tuple[list[int], set[int], dict[str, int]]:
    """Every instruction or row start (sorted), the entry starts, and labels."""
    starts, entries, labels = set(), set(), {}
    label = None
    for line in skool.read_text(encoding="utf-8").splitlines():
        if line.startswith("@label="):
            label = line[7:].strip()
            continue
        m = re.match(r"^([bcgistuw* ])\$([0-9A-F]{4})", line)
        if m:
            address = int(m.group(2), 16)
            starts.add(address)
            if m.group(1) in "bcgistuw":
                entries.add(address)
            if label:
                labels[label] = address
                label = None
    ordered = sorted(starts)
    return ordered, entries, labels


def next_start(ordered: list[int], address: int) -> int:
    """The address after the instruction at `address` (or $10000 at the end)."""
    i = bisect.bisect_right(ordered, address)
    return ordered[i] if i < len(ordered) else 0x10000


def ranges(skool: Path, draft: Path, out: Path) -> int:
    ordered, entries, _ = read_listing(skool)
    starts = set(ordered)
    problems, lines = [], []
    for n, line in enumerate(draft.read_text(encoding="utf-8").splitlines(), 1):
        span = re.match(r"^  \$([0-9A-F]{4})-\$([0-9A-F]{4}) (.*)$", line)
        single = re.match(r"^  \$([0-9A-F]{4}) (.*)$", line)
        if span:
            first, last = int(span.group(1), 16), int(span.group(2), 16)
            for address in (first, last):
                if address not in starts:
                    problems.append(f"line {n}: ${address:04X} is not an instruction start")
            line = f"  ${first:04X},{next_start(ordered, last) - first} {span.group(3)}"
        elif single:
            address = int(single.group(1), 16)
            if address not in starts:
                problems.append(f"line {n}: ${address:04X} is not an instruction start")
            line = f"  ${address:04X},{next_start(ordered, address) - address} {single.group(2)}"
        for target in re.findall(r"#R\$([0-9A-F]{4})", line):
            if int(target, 16) not in entries:
                problems.append(f"line {n}: #R${target} is not the start of an entry")
        lines.append(line)
    out.write_text("\n".join(lines) + "\n", encoding="utf-8")
    for problem in problems:
        print(problem)
    print(f"wrote {out}" + (f"; {len(problems)} problem(s)" if problems else ""))
    return 1 if problems else 0


def check(skool: Path, fragment: Path, lo: int, hi: int) -> int:
    ordered, entries, labels = read_listing(skool)
    starts = set(ordered)
    problems, titled, new_labels = [], set(), {}
    for n, line in enumerate(fragment.read_text(encoding="utf-8").splitlines(), 1):
        if not line.strip() or line.startswith("#"):
            continue
        m = re.match(r"^@ \$([0-9A-F]{4}) label=(\S+)$", line)
        if m:
            address, name = int(m.group(1), 16), m.group(2)
            if re.search(r"_\d+$", name):
                problems.append(f"line {n}: label {name} ends in _<digit>")
            if name in new_labels and new_labels[name] != address:
                problems.append(f"line {n}: label {name} used twice")
            if name in labels and labels[name] != address:
                problems.append(f"line {n}: label {name} already names ${labels[name]:04X}")
            new_labels[name] = address
            if not lo <= address < hi:
                problems.append(f"line {n}: ${address:04X} is outside the range")
            continue
        m = re.match(r"^([bcgistuw]) \$([0-9A-F]{4})\b", line)
        if m:
            address = int(m.group(2), 16)
            if address not in entries:
                problems.append(f"line {n}: {m.group(1)} ${address:04X} is not an entry start")
            if not lo <= address < hi:
                problems.append(f"line {n}: ${address:04X} is outside the range")
            titled.add(address)
            continue
        m = re.match(r"^[BCSTW] \$([0-9A-F]{4})", line)
        if m:
            if int(m.group(1), 16) not in starts:
                problems.append(f"line {n}: sub-block ${m.group(1)} is not an instruction or row start")
            continue
        m = re.match(r"^  \$([0-9A-F]{4})(?:,(\d+))?", line)
        if m:
            address = int(m.group(1), 16)
            if address not in starts:
                problems.append(f"line {n}: comment at ${address:04X} is not an instruction start")
            if m.group(2):
                end = address + int(m.group(2))
                if end not in starts and end not in entries and end != 0x10000:
                    problems.append(f"line {n}: ${address:04X},{m.group(2)} ends at "
                                    f"${end:04X}, in the middle of an instruction")
            if not lo <= address < hi:
                problems.append(f"line {n}: ${address:04X} is outside the range")
            continue
        if re.match(r"^[DERN@] \$[0-9A-F]{4}", line) or line.startswith(". "):
            continue
        problems.append(f"line {n}: not a control-file line: {line[:60]}")
    for address in sorted(entries):
        if lo <= address < hi and address not in titled:
            problems.append(f"entry ${address:04X} has no title line")
    for problem in problems:
        print(problem)
    print("OK" if not problems else f"{len(problems)} problem(s)")
    return 1 if problems else 0


def main() -> int:
    if len(sys.argv) == 5 and sys.argv[1] == "ranges":
        return ranges(Path(sys.argv[2]), Path(sys.argv[3]), Path(sys.argv[4]))
    if len(sys.argv) == 6 and sys.argv[1] == "check":
        return check(Path(sys.argv[2]), Path(sys.argv[3]),
                     int(sys.argv[4], 16), int(sys.argv[5], 16))
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main())
