"""Knight Lore's level data, laid out a record per line from the game itself.

The rooms, the pieces the backgrounds are built from, and the places the
charms lie are the game's own level design. Described record by record they
are the level data again in other words, so -- like the Hobbit's rooms --
they are not written into a committed file: build_knightlore.py calls
data_blocks() on the snapshot at every build and passes the result to
sna2skool between the map and the annotations. What each table *is* (its
title, its description, its format) is prose, and stays in
scripts/knightlore_annotations.ctl.

The names below are ours, worked out from the code that reads each table; the
formats are described on the tables' own entries in the annotations.
"""
from __future__ import annotations

ROOMS = 0x6251            # the room records, end to end
ROOMS_END = 0x6BD1        # ...up to the block-type table
BACKGROUNDS = 0x6CE2      # 24 words, one per background
BACKGROUND_COUNT = 24
CHARM_PLACES = 0x6FF2     # 32 records of 9 bytes
CHARM_PLACE_COUNT = 32
CHARM_PLACE_SIZE = 9

COLOURS = {3: "magenta", 4: "green", 5: "cyan", 6: "yellow"}
SHAPES = {0: "square", 1: "narrow in x", 2: "narrow in y"}
# What each background number is, by the pieces its list holds.
BACKGROUND_NAMES = [
    "arch N", "arch E", "arch S", "arch W", "forest exit N", "forest exit E",
    "forest exit S", "forest exit W", "portcullis N", "portcullis E",
    "portcullis S", "portcullis W", "walls (square room)",
    "walls (room narrow in y)", "walls (room narrow in x)", "forest walls",
    "trees closing the W gap", "trees closing the N gap", "the wizard",
    "the cauldron", "high arch E", "high arch S", "step to high arch E",
    "step to high arch S"]
# What each block type is, by its type byte and handler.
BLOCK_NAMES = [
    "block", "fire", "ball (half a cell along y)", "rock", "gargoyle", "spikes",
    "chest", "table", "guard (type $96)", "ghost", "fire (type $B5)",
    "raised block", "ball (half a cell along x and y)", "guard (type $1E)",
    "block (type $36)", "block (type $37)", "block (type $3E)", "raised spikes",
    "spiked ball", "raised spiked ball", "fire (type $56)", "block (type $5B)",
    "block (type $8F)", "ball (type $B6)", "ball", "sparkle (type $A4)",
    "portcullis along x", "portcullis along y", "ball (half a cell along x)"]
# The object types background pieces use.
PIECE_NAMES = {
    0x02: "arch piece $02", 0x03: "arch piece $03", 0x04: "tree trunk $04",
    0x05: "tree trunk $05", 0x07: "block $07", 0x08: "portcullis $08",
    0x0A: "wall slab $0A", 0x0B: "wall slab $0B", 0x0C: "wall slab $0C",
    0x0D: "wall column $0D", 0x0E: "wall column $0E", 0x0F: "wall end $0F",
    0x80: "tree $80", 0x81: "tree $81", 0x82: "tree $82",
    0x8D: "cauldron $8D", 0x8E: "cauldron's top $8E", 0x90: "legs $90",
    0x9E: "wizard's body $9E"}


def _word(memory, address: int) -> int:
    return memory[address] | (memory[address + 1] << 8)


def _first_upper(text: str) -> str:
    return text[:1].upper() + text[1:]


def _room_lines(memory) -> list[str]:
    """A line per part of each room record: its head, its backgrounds, and
    each group of objects."""
    out = []
    address = ROOMS
    while address < ROOMS_END:
        room, length, attribute = memory[address:address + 3]
        end = address + 1 + length
        out.append(f"B ${address:04X},3 Room ${room:02X} (row {room >> 4}, "
                   f"column {room & 15}): {SHAPES[attribute >> 3]}, "
                   f"{COLOURS[attribute & 7]}")
        part = address + 3
        backgrounds = []
        while part < end and memory[part] != 0xFF:
            backgrounds.append(BACKGROUND_NAMES[memory[part]])
            part += 1
        closed = part < end
        if closed:
            part += 1                      # the $FF
        text = "Backgrounds: " + ", ".join(backgrounds)
        out.append(f"B ${address + 3:04X},{part - address - 3} {text}"
                   + ("" if closed else "; no objects"))
        while part < end:
            group = memory[part]
            copies = (group & 7) + 1
            name = BLOCK_NAMES[group >> 3]
            out.append(f"B ${part:04X},{1 + copies} "
                       + _first_upper(f"{name} x{copies}" if copies > 1 else name))
            part += 1 + copies
        if part != end:
            raise ValueError(f"room ${room:02X} at ${address:04X} does not end "
                             f"where its length says")
        address = end
    return out


def _background_lines(memory) -> list[str]:
    """A line per 8-byte piece of every background's list."""
    out = []
    lists = sorted({_word(memory, BACKGROUNDS + 2 * i) for i in range(BACKGROUND_COUNT)})
    for start in lists:
        piece = start
        while memory[piece]:
            kind, x, y, z, size_x, size_y, height, flags = memory[piece:piece + 8]
            out.append(f"B ${piece:04X},8 {PIECE_NAMES[kind]} at x ${x:02X}, y ${y:02X}, "
                       f"z ${z:02X}; {size_x} by {size_y}, {height} high; flags ${flags:02X}")
            piece += 8
        out.append(f"B ${piece:04X},1 End of list")
    return out


def _charm_lines(memory) -> list[str]:
    out = []
    for i in range(CHARM_PLACE_COUNT):
        place = CHARM_PLACES + CHARM_PLACE_SIZE * i
        x, y, z, room = memory[place + 1:place + 5]
        out.append(f"B ${place:04X},{CHARM_PLACE_SIZE} Place {i}: room ${room:02X}, "
                   f"x ${x:02X}, y ${y:02X}, z ${z:02X}")
    return out


def data_blocks(memory) -> str:
    """The control-file lines for all three tables."""
    lines = ["; Generated by scripts/knightlore_data.py from the snapshot -- do not edit.", ""]
    lines += _room_lines(memory) + [""]
    lines += _background_lines(memory) + [""]
    lines += _charm_lines(memory) + [""]
    return "\n".join(lines)
