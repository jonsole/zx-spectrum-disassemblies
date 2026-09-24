"""Check the fast-draw patch against the original game, picture by picture.

The patch (patches/hobbit_fast_draw.s) claims to draw every picture exactly as
the original does, only faster, and to change nothing but the plotting code.
This checks each claim rather than trusting the construction:

1. Only the declared ranges differ between the original image and the patched.
2. For every location with a picture, DRAW_LOCATION_PICTURE is run from the same
   clean machine in each, and the whole of RAM is compared afterwards -- the
   screen, the attributes and every variable -- except the patched code itself
   and the stack below where the picture started.
3. The stack goes no deeper in the patched game than in the original: the area
   below it is filled with a marker first, and the lowest byte overwritten is
   the lowest the stack reached. Two markers, so a pushed byte that happens to
   equal one cannot hide.
4. The T-states each picture takes, before and after.

Run after build_hobbit.py and the patch have been built:

    python scripts/check_fast_draw.py
"""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import build_hobbit as bh
import hobbit_pages as hp

PATCHED = bh.FAST_DRAW_RANGES
FAST_BIN = bh.OUT_DIR / "hobbit_fast.bin"
STACK_TOP = hp.SCRATCH_STACK            # where the picture's call starts from
STACK_AREA = (0x5D00, STACK_TOP)        # checked for the deepest the stack went: below
                                        # the system variables, above the BASIC loader


def in_patch(address: int) -> bool:
    return any(start <= address < end for start, end in PATCHED)


def draw(game, clean, location, room_start, player_start, marker):
    """Draw one location's picture; return (memory after, T-states, lowest SP)."""
    from skoolkit.simutils import A, PC, SP, T

    memory, registers = game.memory, game.sim.registers
    memory[:] = clean
    for address in range(*STACK_AREA):
        memory[address] = marker
    memory[room_start] |= 0x80
    memory[player_start + 16] = location
    memory[hp.PICTURES_ON] = 1
    memory[STACK_TOP], memory[STACK_TOP + 1] = hp.RETURN_HERE & 0xFF, hp.RETURN_HERE >> 8
    registers[SP], registers[A] = STACK_TOP, location
    start = registers[T]
    game.sim.trace(hp.DRAW_LOCATION_PICTURE, hp.RETURN_HERE, 0,
                   start + 120 * bh.TSTATES_PER_SECOND, False, None, None, None, None, None)
    if registers[PC] != hp.RETURN_HERE:
        raise RuntimeError(f"location {location}'s picture did not finish")
    lowest = next((a for a in range(*STACK_AREA) if memory[a] != marker), STACK_TOP)
    return list(memory), registers[T] - start, lowest


def main() -> None:
    from hobbit_drive import Hobbit

    original = bytes(bh.game_memory(bh.OUT_DIR / "hobbit.z80")[bh.LOAD_ADDR:bh.GAME_END])
    fast = FAST_BIN.read_bytes()
    if len(fast) != len(original):
        sys.exit(f"error: {FAST_BIN.name} is {len(fast)} bytes, not {len(original)}")
    outside = [bh.LOAD_ADDR + i for i, (a, b) in enumerate(zip(original, fast))
               if a != b and not in_patch(bh.LOAD_ADDR + i)]
    if outside:
        sys.exit(f"error: the patch changes {len(outside)} byte(s) outside its ranges, "
                 f"first at ${outside[0]:04X}")
    changed = sum(1 for a, b in zip(original, fast) if a != b)
    print(f"1. {changed} bytes changed, all inside the patched ranges")

    game = Hobbit()
    memory = list(bh.game_memory(bh.OUT_DIR / "hobbit.z80"))
    records = bh.object_records(memory)
    player = next(r for r in records if r["number"] == 0)["start"]
    rooms = bh.room_records(memory)
    pictures = [key for key, _, _ in bh.keyed_table(memory, bh.PICTURE_TABLE)]
    clean_original = list(game.memory)
    # The live machine has played its first turn, so its variables are not the
    # tape's: only the patched code goes in, not the whole patched image.
    clean_fast = list(clean_original)
    for start, end in PATCHED:
        clean_fast[start:end] = fast[start - bh.LOAD_ADDR:end - bh.LOAD_ADDR]

    total_before = total_after = 0
    worst_depth = 0
    print(" loc  original T  patched T  speed-up  stack (orig/fast)  result")
    for location in pictures:
        start = rooms[location]["start"]
        results = []
        for clean in (clean_original, clean_fast):
            runs = [draw(game, clean, location, start, player, m) for m in (0xAA, 0x55)]
            after, tstates, _ = runs[0]
            lowest = min(r[2] for r in runs)
            results.append((after, tstates, lowest))
        (before_mem, before_t, before_sp), (after_mem, after_t, after_sp) = results
        differ = [a for a in range(0x4000, 0x10000)
                  if before_mem[a] != after_mem[a] and not in_patch(a)
                  and not (min(before_sp, after_sp) <= a < STACK_TOP)]
        deeper = after_sp < before_sp
        worst_depth = max(worst_depth, STACK_TOP - after_sp)
        total_before += before_t
        total_after += after_t
        verdict = ("identical" if not differ else
                   f"DIFFERS at {len(differ)} bytes, first ${differ[0]:04X}")
        if deeper:
            verdict += "; STACK DEEPER"
        print(f" {location:3}  {before_t:10}  {after_t:9}  {before_t / after_t:7.2f}x"
              f"  {STACK_TOP - before_sp:5} / {STACK_TOP - after_sp:<5}      {verdict}")
        if differ or deeper:
            sys.exit(1)
    print(f"all {len(pictures)} identical; {total_before / bh.TSTATES_PER_SECOND:.1f} s "
          f"before, {total_after / bh.TSTATES_PER_SECOND:.1f} s after, "
          f"{total_before / total_after:.2f}x overall; deepest stack {worst_depth} bytes")


if __name__ == "__main__":
    main()
