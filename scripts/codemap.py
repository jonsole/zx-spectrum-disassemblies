"""Find code by following the game's own control flow, rather than by running it.

The build scripts here get their code maps by playing the game and recording
what executes. That map cannot contain a false positive -- every address in it
was fetched as an instruction by a CPU -- but it is only ever as complete as
the playthrough, and for an adventure game driven by typed sentences that is
not very complete at all.

This is the other half. Starting from addresses already known to be code, it
decodes instructions and follows every branch, call and fall-through it finds,
marking what it reaches. It never guesses: an address is only marked if some
instruction already marked as code jumps to it, calls it or falls into it.

WHY NOT A HEURISTIC. The obvious alternative -- scan the block and mark
anything that decodes as plausible instructions -- is what the build scripts'
docstrings reject, and it is worth being clear that the round-trip check is no
defence against it. Data disassembled as instructions reassembles to exactly
the same bytes, so `Verified: N bytes reassemble byte-for-byte` stays green
while the listing fills with nonsense. The round trip catches structure that
does not line up; it cannot catch a DEFB run dressed as code. So the safety
here has to come from the method, and the method is: follow edges, invent
nothing.

WHAT IT CANNOT DO. Recursive descent stops dead at an indirect jump -- JP (HL),
JP (IX), a dispatch table, a routine called through a pointer -- because the
target is a value, not a constant in the instruction. That is exactly where an
execution map is strong, since a real CPU followed the real target. The two
are complements, which is why seeds() takes the execution map as its starting
point: descending from every address that actually ran means every indirect
target that was ever taken is already a seed, for free.

What is left uncovered after both is code reached only by an indirect jump that
the playthrough never took. There is no sound way to find that short of
executing it, and guessing at it is how a disassembly quietly fills with
fiction.

THE CHECK THAT MAKES IT TRUSTWORTHY. The instruction lengths below are a hand
written table, and a single wrong entry would desynchronise the decode and
silently invent instructions from the middle of real ones. So verify() takes
the execution map -- thousands of addresses a real CPU fetched as instructions
-- and requires every one of them to come out of this decoder as an
instruction start too. Any disagreement is a bug here, and it is reported as
one rather than folded into the output.
"""
from __future__ import annotations

# Instruction lengths for unprefixed opcodes. Index is the opcode byte.
_BASE = [
    1, 3, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1,   # 00-0F
    2, 3, 1, 1, 1, 1, 2, 1, 2, 1, 1, 1, 1, 1, 2, 1,   # 10-1F
    2, 3, 3, 1, 1, 1, 2, 1, 2, 1, 3, 1, 1, 1, 2, 1,   # 20-2F
    2, 3, 3, 1, 1, 1, 2, 1, 2, 1, 3, 1, 1, 1, 2, 1,   # 30-3F
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,   # 40-4F
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,   # 50-5F
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,   # 60-6F
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,   # 70-7F
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,   # 80-8F
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,   # 90-9F
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,   # A0-AF
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,   # B0-BF
    1, 1, 3, 3, 3, 1, 2, 1, 1, 1, 3, 2, 3, 3, 2, 1,   # C0-CF
    1, 1, 3, 2, 3, 1, 2, 1, 1, 1, 3, 2, 3, 3, 2, 1,   # D0-DF
    1, 1, 3, 1, 3, 1, 2, 1, 1, 1, 3, 1, 3, 3, 2, 1,   # E0-EF
    1, 1, 3, 1, 3, 1, 2, 1, 1, 1, 3, 1, 3, 3, 2, 1,   # F0-FF
]

# ED-prefixed opcodes are two bytes except these four pairs, which carry a
# 16-bit address: LD (nn),BC/DE/HL/SP and LD BC/DE/HL/SP,(nn).
_ED_LONG = {0x43, 0x4B, 0x53, 0x5B, 0x63, 0x6B, 0x73, 0x7B}

# The opcodes that reference (HL). A DD or FD prefix turns each of them into
# (IX+d) or (IY+d), which carries a displacement byte, so the prefixed form is
# two bytes longer than the plain one rather than one. Getting this wrong is
# not subtle in its effects but is very quiet in its cause: the decode lands
# one byte early and every instruction after it is invented from the middle of
# a real one. $76 is absent because that encoding is HALT, not LD (HL),(HL).
_HL_FORMS = ({0x34, 0x35, 0x36, 0x46, 0x4E, 0x56, 0x5E, 0x66, 0x6E, 0x7E}
             | {0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x77}
             | {0x86, 0x8E, 0x96, 0x9E, 0xA6, 0xAE, 0xB6, 0xBE})

# Conditional jumps: follow the target, and carry on afterwards.
_JR_COND = {0x20, 0x28, 0x30, 0x38}
_JP_COND = {0xC2, 0xCA, 0xD2, 0xDA, 0xE2, 0xEA, 0xF2, 0xFA}
_CALL_COND = {0xC4, 0xCC, 0xD4, 0xDC, 0xE4, 0xEC, 0xF4, 0xFC}
# Unconditional returns and jumps: nothing follows them in a straight line.
_RET_UNCOND = {0xC9}
_RET_ED = {0x45, 0x4D, 0x55, 0x5D, 0x65, 0x6D, 0x75, 0x7D}   # RETN / RETI


class Instruction:
    """Where an instruction is, how long, and where it can go next."""

    __slots__ = ("address", "length", "targets", "falls_through", "indirect")

    def __init__(self, address, length, targets, falls_through, indirect=False):
        self.address = address
        self.length = length
        self.targets = targets              # constant addresses it can reach
        self.falls_through = falls_through  # whether the next address runs too
        self.indirect = indirect            # jumped somewhere we cannot know


def decode(memory, address):
    """One instruction, with its length and where control can go from it."""
    op = memory[address]

    if op == 0xCB:
        return Instruction(address, 2, (), True)
    if op == 0xED:
        sub = memory[(address + 1) & 0xFFFF]
        length = 4 if sub in _ED_LONG else 2
        if sub in _RET_ED:
            return Instruction(address, length, (), False)
        return Instruction(address, length, (), True)
    if op in (0xDD, 0xFD):
        sub = memory[(address + 1) & 0xFFFF]
        if sub == 0xCB:
            return Instruction(address, 4, (), True)
        if sub == 0xE9:                     # JP (IX) / JP (IY)
            return Instruction(address, 2, (), False, indirect=True)
        # Otherwise the prefix re-points HL at IX or IY. An opcode that names
        # (HL) becomes (IX+d) and carries a displacement byte, so it grows by
        # two; anything else grows by one, and a prefix on something that
        # cannot be indexed is a no-op that still occupies its byte.
        inner = decode(memory, (address + 1) & 0xFFFF)
        extra = 2 if sub in _HL_FORMS else 1
        return Instruction(address, inner.length + extra, inner.targets,
                           inner.falls_through, inner.indirect)

    length = _BASE[op]
    word = lambda: memory[(address + 1) & 0xFFFF] | (memory[(address + 2) & 0xFFFF] << 8)
    def relative():
        offset = memory[(address + 1) & 0xFFFF]
        return (address + 2 + (offset - 256 if offset > 127 else offset)) & 0xFFFF

    if op == 0xC3:                          # JP nn
        return Instruction(address, length, (word(),), False)
    if op == 0x18:                          # JR d
        return Instruction(address, length, (relative(),), False)
    if op == 0xE9:                          # JP (HL)
        return Instruction(address, length, (), False, indirect=True)
    if op in _RET_UNCOND:
        return Instruction(address, length, (), False)
    if op in _JP_COND:
        return Instruction(address, length, (word(),), True)
    if op in _JR_COND or op == 0x10:        # JR cc,d and DJNZ d
        return Instruction(address, length, (relative(),), True)
    if op == 0xCD or op in _CALL_COND:      # CALL nn / CALL cc,nn
        return Instruction(address, length, (word(),), True)
    # RST goes to the ROM, which is not part of the game and is not mapped
    # here; it returns, so the fall-through is what matters.
    return Instruction(address, length, (), True)


def walk(memory, seeds, start, end, barriers=(), forbidden=()):
    """Every instruction start reachable from `seeds` by following edges.

    `barriers` are (lo, hi) ranges known to be data -- the packed dictionary,
    say. Control flow into one of those means this decoder has gone wrong, so
    they are not entered, and each one that is hit is reported.

    `forbidden` are addresses that must not be treated as instruction starts,
    however the walk arrives at them. Data decoded as code is the one failure
    this cannot avoid by itself -- a byte in the game's variables happens to
    read as CALL NZ,$7874, and following that phantom call lands the decode one
    byte out for everything after it -- so the caller settles those cases with
    the execution map, whose boundaries came from a CPU, and walks again.
    """
    forbidden = set(forbidden)
    trusted = set(seeds)
    in_range = lambda a: (start <= a < end and a not in forbidden
                          and not any(lo <= a < hi for lo, hi in barriers))
    blocked, code, indirect = set(), set(), set()
    pending = [(a, True) for a in seeds if in_range(a)]
    while pending:
        address, believed = pending.pop()
        if address in code:
            continue
        code.add(address)
        instruction = decode(memory, address)
        if instruction.indirect:
            indirect.add(address)

        # Branches are followed only out of an instruction a CPU really
        # executed. Past that the walk goes straight on and stops at the first
        # RET or unconditional jump, because chaining speculation is what turns
        # one wrong byte into thousands: a byte in the game's variables reads
        # as a CALL, and following its "branches" manufactures a whole database
        # of instructions that no round-trip check can tell from real ones.
        following = []
        if believed:
            following += [(t, t in trusted) for t in instruction.targets]
        if instruction.falls_through:
            following.append(((address + instruction.length) & 0xFFFF, believed))

        for target, target_believed in following:
            if target in code:
                continue
            if in_range(target):
                pending.append((target, target_believed))
            elif start <= target < end:
                blocked.add(target)
    return code, indirect, blocked


def verify(memory, code, executed, start, end):
    """Every address the CPU really executed must be an instruction start here.

    The lengths in this module are a hand-written table, and one wrong entry
    would desynchronise the decode and invent instructions out of the middle
    of real ones. An execution map is thousands of addresses that a CPU
    fetched as instructions, so agreeing with all of them is a real test of
    the table rather than a formality.
    """
    ran = {a for a in executed if start <= a < end}
    missed = sorted(a for a in ran if a not in code)
    return ran, missed
