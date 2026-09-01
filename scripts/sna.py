"""Writing a 48K .sna, lifted out of the zx-spectrum-emulator repository.

These disassemblies used to import RAM_SIZE, Registers and write_sna from that
project's Python core. They live here instead because the dependency was only
three names deep, the package it came from is deprecated there, and a build
that has to reach into a second checkout to emit a snapshot is a worse thing
than seventy lines of format code. SkoolKit is no help: it writes .z80 and
.szx but not .sna, and .sna is what the emulator's debugger loads alongside
the .sld.

.sna has no PC field -- the format represents a machine paused as if by a
RETN, so PC lives on top of the stack at [SP] and is popped on load.
"""
from __future__ import annotations

from dataclasses import dataclass

RAM_SIZE = 0xC000
HEADER_SIZE = 27


@dataclass
class Registers:
    pc: int = 0
    sp: int = 0
    af: int = 0
    bc: int = 0
    de: int = 0
    hl: int = 0
    ix: int = 0
    iy: int = 0
    ir: int = 0
    af2: int = 0
    bc2: int = 0
    de2: int = 0
    hl2: int = 0
    wz: int = 0
    im: int = 0
    iff1: bool = False
    iff2: bool = False


def _lohi(word: int) -> tuple[int, int]:
    return word & 0xFF, (word >> 8) & 0xFF


def write_sna(regs: Registers, ram: bytes, border: int = 0) -> bytes:
    """Serialize registers + 48K RAM into .sna bytes -- the exact inverse of
    parse_sna(), field for field. PC isn't stored directly (the format's
    defining quirk): it's pushed onto the stack at regs.sp - 2, which is
    what the header's SP field ends up holding, mirroring exactly what
    parse_sna() expects to pop back off on load."""
    if len(ram) != RAM_SIZE:
        raise ValueError(f"ram must be exactly {RAM_SIZE} bytes, got {len(ram)}")

    ram = bytearray(ram)
    header_sp = (regs.sp - 2) & 0xFFFF
    stack_offset = header_sp - 0x4000
    if not (0 <= stack_offset < len(ram) - 1):
        raise ValueError(f".sna SP=0x{regs.sp:04X} would not point into RAM after pushing PC")
    ram[stack_offset] = regs.pc & 0xFF
    ram[stack_offset + 1] = (regs.pc >> 8) & 0xFF

    h = bytearray(HEADER_SIZE)
    h[20], h[0] = _lohi(regs.ir)
    h[1], h[2] = _lohi(regs.hl2)
    h[3], h[4] = _lohi(regs.de2)
    h[5], h[6] = _lohi(regs.bc2)
    h[7], h[8] = _lohi(regs.af2)
    h[9], h[10] = _lohi(regs.hl)
    h[11], h[12] = _lohi(regs.de)
    h[13], h[14] = _lohi(regs.bc)
    h[15], h[16] = _lohi(regs.iy)
    h[17], h[18] = _lohi(regs.ix)
    h[19] = 0x04 if regs.iff1 else 0x00
    h[21], h[22] = _lohi(regs.af)
    h[23], h[24] = _lohi(header_sp)
    h[25] = regs.im & 0xFF
    h[26] = border & 0x07

    return bytes(h) + bytes(ram)
