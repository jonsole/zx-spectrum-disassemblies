#!/usr/bin/env python3
"""Knight Lore's rooms, edited in the Filmation room designer and put back into
the original game.

    python scripts/knightlore_rooms.py page    [--out FILE]
    python scripts/knightlore_rooms.py extract [--snapshot FILE] [--force]
    python scripts/knightlore_rooms.py design  [--port N] [--no-browser]
    python scripts/knightlore_rooms.py build   [--out FILE]

The emulator repository's Filmation remake of Knight Lore already decodes the
original's room tables into JSON, and its room designer draws them the way the
game does. Neither ever goes back: the remake builds its own engine from the
JSON. This is the way back, into Ultimate's own code.

  page     writes the standalone editor: one HTML file, no server and no
           Python, that opens a snapshot you give it, edits the rooms in the
           designer, and downloads the patched game. knightlore_rooms.js is its
           half of this script, knightlore_rooms.html its page; it carries the
           remake's sprites.json and graphics.json, which are names, rectangles
           and numbers, and no byte of the game.

  extract  reads a snapshot of the game you own -- by default the one
           build_knightlore.py leaves in game_disassembly/knightlore -- and
           writes the castle into game_disassembly/knightlore/rooms/ as the
           designer's files: rooms.json, templates.json, specials.json, and the
           artwork to draw them with. It keeps a copy of the snapshot there as
           original.sna, which every build starts from. It then packs the JSON
           straight back and requires the tables it gets to be the game's own,
           byte for byte, so the packer is proved before anything is edited.
           It refuses to overwrite a castle that is already there without
           --force, since that would throw the edits away.

  design   opens the room designer (examples/filmation/vscode/room_designer.py)
           on that castle, in a browser. Its Build button runs build.

  build    packs the castle into the original's tables, patches them into
           original.sna, and writes knightlore_rooms.sna beside it: the real
           game, with your rooms, ready to load into any emulator.

Everything under game_disassembly/ is gitignored, as the rest of this
repository's game bytes are. What is committed is this script.

The tables, read off the code rather than assumed (see find_screen and its
neighbours at $D3C6-$D4EA in the disassembly):

  $6248  room_size_tbl         three floor shapes, three bytes each
  $6251  location_tbl          the rooms: number, skip, attribute, then the
                               scenery indices, an $FF, and the object groups
  $6BD1  block_type_tbl        a pointer to each object template ...
  $6CE2  background_type_tbl   ... and to each scenery template, whose bodies
                               follow their own pointers
  $6FF2  special_objs_tbl      32 nine-byte rows, where the collectables start

There is no slack. The four tables fill $6248-$6FF1 exactly, and the rest of
memory is spoken for too: code and sprites below, the screen buffer and the
lookup tables that build_lookup_tbls writes from $F100 above. So an edit that
adds bytes has to be paid for by one that takes some away. What makes that
workable is that the room tables' boundaries are only named in three places --
the operands at $D3CA and $D462 (block_type_tbl) and $D42B
(background_type_tbl) -- so build moves the boundaries and patches the three,
and the whole 3,498 bytes is one budget rather than three. room_size_tbl and
location_tbl stay where they are.

The limits the game's code puts on a room, each checked:

  - A room expands into 32-byte object records from $5C88 up to the font at
    $6108: thirty-six of them. zero_end_of_graphic_objs_tbl then clears
    records until it meets the font exactly, so a thirty-seventh would not only
    overwrite the font but run on through the room tables. The busiest room in
    the castle as shipped fills all thirty-six.
  - The skip byte counts from itself, so a record is at most 255 bytes.
  - The $FF between scenery and objects is written only when objects follow,
    and a room has to have something in it: the walk counts its body down with
    the skip, and a room with no body, or an $FF with nothing after it, sets it
    reading the next room's record as this one's objects.
  - An object group's first byte holds the template in five bits and the count
    less one in three: 32 object templates, eight positions a group.
  - A scenery index of $FF is the terminator, so 255 scenery templates at most.
  - A template is a list of entries ending in a zero graphic, so no entry may
    place graphic 0.
"""
from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = PROJECT_ROOT / "game_disassembly" / "knightlore"
CASTLE = OUT_DIR / "rooms"
DEFAULT_SNAPSHOT = OUT_DIR / "knightlore.sna"
BASE = CASTLE / "original.sna"
PATCHED = CASTLE / "knightlore_rooms.sna"
BUILD_STUB = CASTLE / "build.py"
PAGE_TEMPLATE = Path(__file__).resolve().parent / "knightlore_rooms.html"
PAGE_MODULE = Path(__file__).resolve().parent / "knightlore_rooms.js"
PAGE_OUT = OUT_DIR / "knightlore_room_editor.html"

# This repository is a submodule of the emulator's, and the designer and the
# Filmation remake's decoders live there. They are used as they stand rather
# than copied: the remake's rooms.json is this same castle, and two decoders
# would be two chances to disagree about it.
EMULATOR_ROOT = PROJECT_ROOT.parent
FILMATION = EMULATOR_ROOT / "examples" / "filmation"
REMAKE = FILMATION / "knightlore"
DESIGNER = FILMATION / "vscode" / "room_designer.py"

sys.path.insert(0, str(Path(__file__).resolve().parent))

from sna import Registers, write_sna  # noqa: E402

SNA_HEADER = 27
RAM_START = 0x4000

ROOM_SIZE_TBL = 0x6248
ROOM_SIZE_LIMIT = 32              # what bits 3-7 of the attribute byte can name
LOCATION_TBL = 0x6251             # where the game has it; a build may move it
# retrieve_screen's LD HL,location_tbl at $D3CC: the one operand that names
# where the rooms start, one past the opcode. The room sizes run up to it, so a
# castle with more shapes moves the rooms down and patches this.
LOCATION_OPERAND = 0xD3CD
# A half-size keeps $80 plus and minus it inside a byte; a floor is any height.
SHAPE_RANGE = {"u": (1, 127), "v": (1, 127), "z": (0, 255)}
BLOCK_TYPE_TBL = 0x6BD1           # where the game has it; build may move it
BACKGROUND_TYPE_TBL = 0x6CE2      # likewise
ORIGINAL_OBJECT_TEMPLATES = 29    # the pointers in the game's own tables
ORIGINAL_SCENERY_TEMPLATES = 24
REGION_END = 0x6FF2               # exclusive: special_objs_tbl starts here

# The operands that name the two template tables, from the disassembly:
# retrieve_screen's LD BC,block_type_tbl at $D3C9 (the end of the room walk),
# next_fg_obj's LD HL,block_type_tbl at $D461, and next_bg_obj's
# LD BC,background_type_tbl at $D42A. Each address is the instruction's plus
# one, past the opcode.
BLOCK_TYPE_OPERANDS = (0xD3CA, 0xD462)
BACKGROUND_TYPE_OPERANDS = (0xD42B,)

# The rooms a game can start in: init_start_location picks one of these four
# with the bottom two bits of the seed at $5BA0.
START_LOCATIONS = 0xD1E2
START_LOCATION_COUNT = 4
# Where Sabreman stands when a game starts, whichever room: plyr_spr_init_data
# at $D1A1 puts him in the middle of the floor, U $80, V $80, Z $80, in a box
# 5 either way and $17 high. A starting room needs that box empty.
START_SPOT = {"u": 0x80, "v": 0x80, "z": 0x80, "sizeU": 5, "sizeV": 5, "sizeZ": 0x17}
# room_unpack's arithmetic for an object's place, as room_model.js has it.
CELL, CELL_ORIGIN, HALF_CELL, LEVEL_Z, Z_MASK = 16, 72, 8, 12, 0xFC
FIRST_REAL_GRAPHIC = 2          # graphic 1 is a blank the game steps over

SPECIALS_TBL = 0x6FF2
SPECIALS_ROWS = 32
SPECIALS_STRIDE = 9               # bytes 1-4 are U, V, Z and the room
OBJECTS_REQUIRED = 0xC27D
OBJECTS_REQUIRED_COUNT = 14

# The object table a room is expanded into: 32-byte records from $5C88, where
# the two before it (from $5C48) are the specials', up to the font.
OBJECT_RECORDS_FROM = 0x5C88
FONT = 0x6108
OBJECT_RECORD = 32
POOL_LIMIT = (FONT - OBJECT_RECORDS_FROM) // OBJECT_RECORD      # 36

SCENERY_STRIDE = 8                # graphic, U, V, Z, size U, V, Z, flags
OBJECT_STRIDE = 6                 # graphic, size U, V, Z, flags, offsets
SCENERY_END = 0xFF                # ends a room's scenery indices
OBJECT_TEMPLATE_LIMIT = 32        # five bits of the group byte
GROUP_LIMIT = 8                   # three bits, stored less one
CELLS, LEVELS = 8, 4              # a position byte: U 0-2, V 3-5, Z 6-7
INKS = 8
RECORD_LIMIT = 255                # the skip byte

GAME_MIRROR = 0x40
GAME_PASSABLE = 0x02
HALF_U, HALF_V, RAISE_Z = 0x01, 0x02, 0xFC

# What a castle this script writes says about itself, for the designer: the
# grid and the scenery count are Knight Lore's own already, and the pool is
# what the game's object table holds.
RULES = {"poolLimit": POOL_LIMIT, "shapeLimit": ROOM_SIZE_LIMIT}


class CastleError(Exception):
    """Something in the castle the original cannot hold, said so the person
    who put it there can find it."""


def _log(message: str) -> None:
    print(message, flush=True)


# --- the emulator repository's half ---------------------------------------

def filmation():
    """The remake's modules, imported from where they live.

    kl_extract, rooms and sprite_sheet each write beside themselves -- a module
    global HERE -- and each reads it at call time, so pointing HERE at the
    castle directory is what makes them write there instead. Nothing of the
    remake's own is touched: the one file read from it, graphics.json, is
    copied, not opened for writing.
    """
    if not (REMAKE / "rooms.py").is_file() or not DESIGNER.is_file():
        sys.exit(f"The room designer and the Filmation decoders are not at "
                 f"{FILMATION}.\nThis script is used from the "
                 f"zx-spectrum-emulator checkout this repository is a "
                 f"submodule of.")
    for path in (FILMATION, REMAKE):
        if str(path) not in sys.path:
            sys.path.insert(0, str(path))
    import castle                                               # noqa: E402
    import graphics                                             # noqa: E402
    import kl_extract                                           # noqa: E402
    import rooms                                                # noqa: E402
    import sheet                                                # noqa: E402
    import sprite_sheet                                         # noqa: E402
    return castle, graphics, kl_extract, rooms, sheet, sprite_sheet


# --- snapshots ------------------------------------------------------------

def read_sna(path: Path) -> bytearray:
    """A 48K .sna as it is on disk: the header, then RAM from $4000."""
    raw = bytearray(path.read_bytes())
    if len(raw) != SNA_HEADER + 0xC000:
        sys.exit(f"{path} is not a 48K .sna ({len(raw)} bytes)")
    return raw


def peek(sna: bytearray, addr: int, count: int = 1) -> bytes:
    at = SNA_HEADER + addr - RAM_START
    return bytes(sna[at:at + count])


def poke(sna: bytearray, addr: int, data: bytes) -> None:
    at = SNA_HEADER + addr - RAM_START
    sna[at:at + len(data)] = data


def word(sna: bytearray, addr: int) -> int:
    lo, hi = peek(sna, addr, 2)
    return lo | (hi << 8)


def as_sna(snapshot: Path) -> bytes:
    """Any snapshot SkoolKit reads, as a .sna -- what the emulator loads with
    the disassembly's .sld, and what build patches by offset.

    A .sna is taken as it is. Anything else goes through SkoolKit and
    write_sna(), the way build_knightlore.py writes its own: every register
    carried across, and SP taken back from after PC was pushed to before it,
    since write_sna() does the pushing itself.
    """
    if snapshot.suffix.lower() == ".sna":
        return snapshot.read_bytes()
    from skoolkit.snapshot import Snapshot

    state = Snapshot.get(str(snapshot))
    ram = bytes(bytearray(state.memory[RAM_START:0x10000]))
    regs = Registers(
        pc=state.pc, sp=(state.sp + 2) & 0xFFFF,
        af=(state.a << 8) | state.f, bc=state.bc, de=state.de, hl=state.hl,
        ix=state.ix, iy=state.iy, ir=(state.i << 8) | state.r,
        af2=(state.a2 << 8) | state.f2, bc2=state.bc2, de2=state.de2,
        hl2=state.hl2, im=state.im,
        iff1=bool(state.iff1), iff2=bool(state.iff2))
    return write_sna(regs, ram, border=state.border)


def check_original(sna: bytearray) -> None:
    """That this is Knight Lore with its tables where the disassembly says.

    The three operands name the two template tables, and the room walk lands
    exactly on the first of them. A different release, or a copy someone has
    already patched, fails here rather than being taken apart wrongly.
    """
    wrong = []
    for addr in BLOCK_TYPE_OPERANDS:
        if word(sna, addr) != BLOCK_TYPE_TBL:
            wrong.append(f"${addr:04X} holds ${word(sna, addr):04X}, "
                         f"not ${BLOCK_TYPE_TBL:04X}")
    for addr in BACKGROUND_TYPE_OPERANDS:
        if word(sna, addr) != BACKGROUND_TYPE_TBL:
            wrong.append(f"${addr:04X} holds ${word(sna, addr):04X}, "
                         f"not ${BACKGROUND_TYPE_TBL:04X}")
    if word(sna, LOCATION_OPERAND) != LOCATION_TBL:
        wrong.append(f"${LOCATION_OPERAND:04X} holds ${word(sna, LOCATION_OPERAND):04X}, "
                     f"not ${LOCATION_TBL:04X}")
    p = LOCATION_TBL
    while p < BLOCK_TYPE_TBL:
        p += peek(sna, p + 1)[0] + 1
    if p != BLOCK_TYPE_TBL:
        wrong.append(f"the room walk ends at ${p:04X}, not ${BLOCK_TYPE_TBL:04X}")
    if wrong:
        sys.exit("This does not look like the Knight Lore the disassembly "
                 "describes:\n  " + "\n  ".join(wrong))


# --- the castle, packed ---------------------------------------------------

def start_blocker(atlas, room, known, sizes, graphics):
    """What stands where Sabreman starts in a room, as a name to say, or None.

    The first solid piece -- not passable, not the blank graphic 1 -- whose
    box meets START_SPOT's. The room designer's startBlockers makes the same
    test, and knightlore_rooms.js's startBlocker.
    """
    s = START_SPOT
    floor_z = atlas["roomDimensions"][room["dimensions"]]["z"]

    def meets(u, v, z, box):
        return (abs(u - s["u"]) < box["u"] + s["sizeU"]
                and abs(v - s["v"]) < box["v"] + s["sizeV"]
                and z < s["z"] + s["sizeZ"] and z + box["z"] > s["z"])

    def solid(entry, whose):
        return (not entry["flags"]["passable"]
                and graphics.number_of(known, entry["graphic"], whose) >= FIRST_REAL_GRAPHIC)

    for ref in room["scenery"]:
        for entry in atlas["sceneryTemplates"][ref["template"]]:
            if solid(entry, ref["template"]) and meets(
                    entry["u"], entry["v"], entry["z"],
                    graphics.box_of(sizes, entry, ref["template"])):
                return ref["template"]
    for group in room["objects"]:
        for entry in atlas["objectTemplates"][group["template"]]:
            if not solid(entry, group["template"]):
                continue
            box = graphics.box_of(sizes, entry, group["template"])
            nudge = entry["offsets"]
            for p in group["positions"]:
                u = p["u"] * CELL + (HALF_CELL if nudge["halfU"] else 0) + CELL_ORIGIN
                v = p["v"] * CELL + (HALF_CELL if nudge["halfV"] else 0) + CELL_ORIGIN
                z = floor_z + ((p["z"] * LEVEL_Z + nudge["raiseZ"]) & Z_MASK)
                if meets(u, v, z, box):
                    return "%s at %d,%d,%d" % (group["template"], p["u"], p["v"], p["z"])
    return None


def flags_byte(flags: dict) -> int:
    return ((GAME_MIRROR if flags["mirrored"] else 0)
            | (GAME_PASSABLE if flags["passable"] else 0)
            | flags["rest"]) & 0xFF


def offsets_byte(offsets: dict) -> int:
    return ((HALF_U if offsets["halfU"] else 0)
            | (HALF_V if offsets["halfV"] else 0)
            | (offsets["raiseZ"] & RAISE_Z))


def is_byte(value) -> bool:
    return isinstance(value, int) and not isinstance(value, bool) and 0 <= value <= 0xFF


def template_bodies(atlas, known, sizes, graphics, group, stride):
    """Each template's bytes, zero-terminated, in the order the file keys them
    -- which is the index a room names it by."""
    out = {}
    for name, pieces in atlas[group].items():
        body = bytearray()
        for n, entry in enumerate(pieces):
            whose = f"{name}, entry {n + 1}"
            number = graphics.number_of(known, entry["graphic"], whose)
            if number == 0:
                raise CastleError(f"{whose} places graphic 0, which is the "
                                  f"marker that ends a template")
            box = graphics.box_of(sizes, entry, whose)
            if stride == SCENERY_STRIDE:
                fields = [number, entry["u"], entry["v"], entry["z"],
                          box["u"], box["v"], box["z"], flags_byte(entry["flags"])]
            else:
                fields = [number, box["u"], box["v"], box["z"],
                          flags_byte(entry["flags"]), offsets_byte(entry["offsets"])]
            if not all(is_byte(f) for f in fields):
                raise CastleError(f"{whose} has a field that is not a byte: {fields}")
            body += bytes(fields)
        body.append(0)
        out[name] = bytes(body)
    return out


def room_records(atlas, castle, scenery_index, object_index, pieces_of):
    """location_tbl's bytes, one record a room, in the file's order.

    Also returns the fullest room, which is what the object table has to hold.
    """
    out = bytearray()
    seen = set()
    fullest = (0, None)
    for room in atlas["rooms"]:
        n = room["number"]
        where = f"room ${n:02X} ({n})"
        if not is_byte(n) or n in seen:
            raise CastleError(f"{where} is not a room number, or is there twice")
        seen.add(n)
        shape = castle.shape_index(atlas, room["dimensions"], where)
        if not (0 <= room["ink"] < INKS):
            raise CastleError(f"{where} has ink {room['ink']}; there are eight")

        body = bytearray()
        used = 0
        for ref in room["scenery"]:
            body.append(scenery_index[ref["template"]])
            used += pieces_of[ref["template"]]
        if room["objects"]:
            body.append(SCENERY_END)
        for group in room["objects"]:
            name = group["template"]
            spots = group["positions"]
            if not 1 <= len(spots) <= GROUP_LIMIT:
                raise CastleError(f"{where} has a group of {len(spots)} {name}; "
                                  f"a group holds one to eight")
            body.append(object_index[name] << 3 | (len(spots) - 1))
            for p in spots:
                if not (0 <= p["u"] < CELLS and 0 <= p["v"] < CELLS
                        and 0 <= p["z"] < LEVELS):
                    raise CastleError(f"{where} places {name} at "
                                      f"{p['u']},{p['v']},{p['z']}, off the grid")
                body.append(p["u"] | p["v"] << 3 | p["z"] << 6)
            used += pieces_of[name] * len(spots)

        if not body:
            raise CastleError(f"{where} has nothing in it, which the game's "
                              f"walk cannot take: it would read the next "
                              f"room's record as this one's")
        if used > POOL_LIMIT:
            raise CastleError(f"{where} fills {used} object records; the "
                              f"game's table holds {POOL_LIMIT}, and one more "
                              f"overwrites the font and the room tables")
        skip = 2 + len(body)
        if skip > RECORD_LIMIT:
            raise CastleError(f"{where} is {skip} bytes; the skip byte holds 255")
        fullest = max(fullest, (used, n))
        out += bytes([n, skip, room["ink"] | shape << 3]) + body
    return bytes(out), fullest


def body_order(names, original_pointers):
    """The order to lay the bodies out in: the original's, by where its
    pointer for the same index sat, then any template it did not have.

    That is what lets the castle as extracted come back byte for byte -- the
    game's bodies are not in table order -- while an edited one is still laid
    out whole, with no gaps.
    """
    def where(i):
        return (0, original_pointers[i]) if i < len(original_pointers) else (1, i)
    return sorted(range(len(names)), key=where)


def lay_table(at, bodies, order):
    """A pointer table at `at` and the bodies after it. Identical bodies share
    one copy, which is what a duplicated template costs nothing for."""
    names = list(bodies)
    table = bytearray(2 * len(names))
    data = bytearray()
    placed = {}
    for i in order:
        body = bodies[names[i]]
        if body not in placed:
            placed[body] = at + len(table) + len(data)
            data += body
        table[2 * i] = placed[body] & 0xFF
        table[2 * i + 1] = placed[body] >> 8
    return bytes(table + data)


def pack(castle_dir: Path, original: bytearray):
    """The castle -> every byte build writes, as {address: bytes}, and a
    report of how the region was spent."""
    castle, graphics, *_ = filmation()
    atlas = castle.read_castle(castle_dir)
    known = graphics.numbers(castle_dir)
    sizes = graphics.sizes(castle_dir)

    scenery = template_bodies(atlas, known, sizes, graphics,
                              "sceneryTemplates", SCENERY_STRIDE)
    objects = template_bodies(atlas, known, sizes, graphics,
                              "objectTemplates", OBJECT_STRIDE)
    if len(objects) > OBJECT_TEMPLATE_LIMIT:
        raise CastleError(f"{len(objects)} object templates; a room names one "
                          f"in five bits, which holds {OBJECT_TEMPLATE_LIMIT}")
    if len(scenery) >= SCENERY_END:
        raise CastleError(f"{len(scenery)} scenery templates; ${SCENERY_END:02X} "
                          f"ends a room's list, so {SCENERY_END} is the most")

    pieces_of = {name: len(p) for name, p in atlas["sceneryTemplates"].items()}
    pieces_of.update({name: len(p) for name, p in atlas["objectTemplates"].items()})
    scenery_index = {name: i for i, name in enumerate(scenery)}
    object_index = {name: i for i, name in enumerate(objects)}
    for room in atlas["rooms"]:
        for ref in room["scenery"]:
            if ref["template"] not in scenery_index:
                raise CastleError(f"room {room['number']} names the scenery "
                                  f"template {ref['template']!r}, which there is not")
        for group in room["objects"]:
            if group["template"] not in object_index:
                raise CastleError(f"room {room['number']} names the object "
                                  f"template {group['template']!r}, which there is not")

    # The room sizes, as many as the castle has: the rooms follow them, so a
    # shape more is three bytes more before the rooms and the operand that
    # names where they start moves with them.
    shapes = atlas["roomDimensions"]
    if not 1 <= len(shapes) <= ROOM_SIZE_LIMIT:
        raise CastleError(f"{len(shapes)} floor shapes; a room names one in five "
                          f"bits, so 1 to {ROOM_SIZE_LIMIT}")
    for name, shape in shapes.items():
        for field, (low, high) in SHAPE_RANGE.items():
            value = shape.get(field)
            if not (isinstance(value, int) and low <= value <= high):
                raise CastleError(f"the shape {name}: {field} is {low} to {high}")
    sizes_bytes = bytes(s[f] for s in shapes.values() for f in ("u", "v", "z"))
    location_tbl = ROOM_SIZE_TBL + len(sizes_bytes)

    locations, fullest = room_records(atlas, castle, scenery_index,
                                      object_index, pieces_of)

    # Where the original's bodies sat, which is the order to keep them in.
    old_objects = [word(original, BLOCK_TYPE_TBL + 2 * i)
                   for i in range(ORIGINAL_OBJECT_TEMPLATES)]
    old_scenery = [word(original, BACKGROUND_TYPE_TBL + 2 * i)
                   for i in range(ORIGINAL_SCENERY_TEMPLATES)]

    block_tbl = location_tbl + len(locations)
    object_part = lay_table(block_tbl, objects,
                            body_order(list(objects), old_objects))
    background_tbl = block_tbl + len(object_part)
    scenery_part = lay_table(background_tbl, scenery,
                             body_order(list(scenery), old_scenery))
    end = background_tbl + len(scenery_part)
    if end > REGION_END:
        raise CastleError(
            f"the castle needs {end - ROOM_SIZE_TBL} bytes and the original "
            f"has {REGION_END - ROOM_SIZE_TBL}: {end - REGION_END} too many.\n"
            f"  rooms {len(locations)}, object templates {len(object_part)}, "
            f"scenery templates {len(scenery_part)}")

    # What is left over sits between the scenery bodies and the specials,
    # where nothing points and the room walk never reaches.
    region = sizes_bytes + locations + object_part + scenery_part
    region += bytes(REGION_END - end)

    writes = {ROOM_SIZE_TBL: region,
              LOCATION_OPERAND: bytes([location_tbl & 0xFF, location_tbl >> 8])}
    for addr in BLOCK_TYPE_OPERANDS:
        writes[addr] = bytes([block_tbl & 0xFF, block_tbl >> 8])
    for addr in BACKGROUND_TYPE_OPERANDS:
        writes[addr] = bytes([background_tbl & 0xFF, background_tbl >> 8])
    writes.update(specials(castle_dir, original))
    if "startRooms" in atlas:
        starts = atlas["startRooms"]
        numbers = {room["number"] for room in atlas["rooms"]}
        if len(starts) != START_LOCATION_COUNT:
            raise CastleError(f"{len(starts)} starting rooms; the game picks "
                              f"one of {START_LOCATION_COUNT}")
        by_number = {room["number"]: room for room in atlas["rooms"]}
        for n in starts:
            if n not in numbers:
                raise CastleError(f"the game can start in room {n}, which is not a room")
            blocker = start_blocker(atlas, by_number[n], known, sizes, graphics)
            if blocker:
                raise CastleError(f"room ${n:02X} is a starting room, and {blocker} "
                                  f"stands in the middle of the floor, where Sabreman starts")
        writes[START_LOCATIONS] = bytes(starts)

    report = {
        "rooms": len(atlas["rooms"]),
        "shapes": len(shapes),
        "room_bytes": len(locations),
        "object_bytes": len(object_part),
        "scenery_bytes": len(scenery_part),
        "free": REGION_END - end,
        "fullest": fullest,
        "block_type_tbl": block_tbl,
        "background_type_tbl": background_tbl,
    }
    return writes, report


def specials(castle_dir: Path, original: bytearray):
    """specials.json's positions into special_objs_tbl, and the wanted list
    into objects_required. The rest of each row -- which kind it is dealt, and
    the game's running state -- is the original's, as special_init expects."""
    path = castle_dir / "specials.json"
    if not path.is_file():
        return {}
    said = json.loads(path.read_text(encoding="utf-8"))
    rows = said["collectables"]
    wanted = said["wanted"]
    if len(rows) != SPECIALS_ROWS or len(wanted) != OBJECTS_REQUIRED_COUNT:
        raise CastleError(f"specials.json has {len(rows)} collectables and "
                          f"{len(wanted)} wanted; the game has {SPECIALS_ROWS} "
                          f"and {OBJECTS_REQUIRED_COUNT}")
    table = bytearray(peek(original, SPECIALS_TBL, SPECIALS_ROWS * SPECIALS_STRIDE))
    for i, row in enumerate(rows):
        fields = [row["u"], row["v"], row["z"], row["room"]]
        if not all(is_byte(f) for f in fields):
            raise CastleError(f"collectable {i + 1} has a field that is not a byte")
        table[i * SPECIALS_STRIDE + 1:i * SPECIALS_STRIDE + 5] = bytes(fields)
    if not all(is_byte(k) and k < 8 for k in wanted):
        raise CastleError("the wanted list holds kinds 0 to 7")
    return {SPECIALS_TBL: bytes(table), OBJECTS_REQUIRED: bytes(wanted)}


def apply(sna: bytearray, writes) -> int:
    """Every write into the snapshot; how many bytes it changed."""
    changed = 0
    for addr, data in writes.items():
        changed += sum(a != b for a, b in zip(peek(sna, addr, len(data)), data))
        poke(sna, addr, data)
    return changed


def describe(report) -> str:
    used, where = report["fullest"]
    return (f"{report['rooms']} rooms in {report['room_bytes']} bytes, "
            f"{report['shapes']} floor shapes, object "
            f"templates {report['object_bytes']}, scenery templates "
            f"{report['scenery_bytes']}; {report['free']} bytes free.\n"
            f"The fullest room is ${where:02X}, at {used} of {POOL_LIMIT} "
            f"object records.")


# --- the commands ---------------------------------------------------------

STUB = '''"""Build the original Knight Lore with these rooms.

Written by knightlore_rooms.py extract so that the room designer's Build
button, which runs the build.py beside the rooms.json it is editing, runs
knightlore_rooms.py build.
"""
import runpy
import sys

sys.argv = [{script!r}, "build"]
runpy.run_path({script!r}, run_name="__main__")
'''


def extract(snapshot: Path, force: bool) -> None:
    if (CASTLE / "rooms.json").is_file() and not force:
        sys.exit(f"{CASTLE / 'rooms.json'} is already there, and extracting "
                 f"again would throw away any edits in it. Use --force to "
                 f"start again from the game's own rooms.")
    if not snapshot.is_file():
        sys.exit(f"No snapshot at {snapshot}.\nRun build_knightlore.py "
                 f"--snapshot on your copy first, or give one with --snapshot.")
    castle, graphics, kl_extract, rooms, sheet, sprite_sheet = filmation()

    CASTLE.mkdir(parents=True, exist_ok=True)
    original = bytearray(as_sna(snapshot))
    check_original(original)
    BASE.write_bytes(original)
    _log(f"original.sna     from {snapshot}")

    # The artwork, the way the remake's own extraction makes it, into the
    # castle directory. graphics.json is seeded from the remake's because it
    # holds the one thing no snapshot can give back: the per-graphic pixel
    # nudges, which adj.py harvested from the running game. The names come
    # with it, so the two castles call every graphic the same thing. The
    # nudges are stored with each sprite's blank rows taken off, and
    # sprites.json is where those trims are recorded, so it comes too: without
    # it every trimmed sprite's nudge would be moved a second time.
    for module in (kl_extract, sprite_sheet, rooms):
        module.HERE = CASTLE
    ram = kl_extract.load_ram(BASE)
    packed, addresses = kl_extract.sprites(ram)
    (CASTLE / sheet.PACKED_FILE).write_bytes(packed)
    gmap, _ = kl_extract.graphic_map(ram, addresses)
    kl_extract.write_graphic_map(gmap)
    for leaf in (sheet.GRAPHICS_FILE, sheet.SPRITES_FILE):
        shutil.copyfile(REMAKE / leaf, CASTLE / leaf)
    sheet.make(sprite_sheet)
    # Only the sheet wanted those two; the files the designer reads are
    # everything that is left.
    (CASTLE / sheet.PACKED_FILE).unlink()
    (CASTLE / sheet.GRAPHIC_MAP_FILE).unlink()
    kl_extract.write_specials(ram)

    # The rooms, by the remake's decoder, then told what the original holds.
    rooms.data = bytes(peek(original, ROOM_SIZE_TBL, REGION_END - ROOM_SIZE_TBL))
    rooms.write_json(rooms.rooms())
    atlas = castle.read_castle(CASTLE)
    atlas["meta"]["comment"] = ("Written by knightlore_rooms.py from the "
                                "original game; its build packs it back into "
                                "the original's own tables.")
    atlas["meta"]["rules"] = dict(RULES)
    atlas["startRooms"] = list(peek(original, START_LOCATIONS, START_LOCATION_COUNT))
    castle.write_castle(CASTLE, atlas)

    BUILD_STUB.write_text(STUB.format(script=str(Path(__file__).resolve())),
                          encoding="utf-8")

    # The proof: the castle as written packs back into exactly the tables it
    # came from, operands and specials included.
    writes, report = pack(CASTLE, original)
    again = bytearray(original)
    changed = apply(again, writes)
    if changed:
        sys.exit(f"The castle does not pack back into the game's own tables: "
                 f"{changed} bytes differ. That is a fault in this script, "
                 f"not in your copy.")
    _log(f"Verified: the castle packs back into the original's "
         f"{REGION_END - ROOM_SIZE_TBL} bytes of tables byte for byte.")
    _log(describe(report))
    _log(f"\nEdit it with:  python {Path(__file__).relative_to(PROJECT_ROOT)} design")


def build(out: Path) -> None:
    if not BASE.is_file() or not (CASTLE / "rooms.json").is_file():
        sys.exit(f"No castle at {CASTLE} -- run extract first.")
    original = read_sna(BASE)
    check_original(original)
    try:
        writes, report = pack(CASTLE, original)
    except CastleError as err:
        sys.exit(f"Not built: {err}")
    patched = bytearray(original)
    changed = apply(patched, writes)
    out.write_bytes(patched)
    _log(describe(report))
    if report["block_type_tbl"] != BLOCK_TYPE_TBL:
        _log(f"The template tables moved: block_type_tbl to "
             f"${report['block_type_tbl']:04X}, background_type_tbl to "
             f"${report['background_type_tbl']:04X}.")
    _log(f"Wrote {out}: {changed} byte{'' if changed == 1 else 's'} "
         f"different from the original.")


def script_json(value) -> str:
    """A value as JSON that can sit inside a <script>: the designer's page is
    itself HTML, and its own </script> would end the one it is carried in."""
    return json.dumps(value, ensure_ascii=False).replace("</", "<\\/")


def page(out: Path) -> None:
    """The standalone editor, from its template and the two designer pages.

    Each page is inlined the way its hosts inline it: every /*@name.js@*/
    marker it holds is that file from the designer's directory, so a model a
    page comes to need is picked up without this knowing. Each is left with
    its /*@host@*/ marker, for the editor to fill in once a snapshot is open.
    """
    filmation()
    vscode = DESIGNER.parent

    def inlined(leaf):
        html = (vscode / leaf).read_text(encoding="utf-8")
        for name in sorted(set(re.findall(r"/\*@([a-z_]+\.js)@\*/", html))):
            source = (vscode / name).read_text(encoding="utf-8")
            html = html.replace("/*@%s@*/" % name, source)
        if html.count("/*@host@*/") != 1:
            sys.exit(f"{leaf} has no single /*@host@*/ marker to put a host into")
        return html

    carried = {}
    for leaf in ("sprites.json", "graphics.json"):
        carried[leaf] = json.loads((REMAKE / leaf).read_text(encoding="utf-8"))

    html = PAGE_TEMPLATE.read_text(encoding="utf-8")
    for marker, value in (
            ("/*@knightlore_rooms.js@*/", PAGE_MODULE.read_text(encoding="utf-8")),
            ('/*@designer@*/""', script_json(inlined("room_view.html"))),
            ('/*@templates@*/""', script_json(inlined("templates_view.html"))),
            ("/*@sprites@*/null", script_json(carried["sprites.json"])),
            ("/*@graphics@*/null", script_json(carried["graphics.json"]))):
        if html.count(marker) != 1:
            sys.exit(f"{PAGE_TEMPLATE.name} has {html.count(marker)} of {marker}, not one")
        html = html.replace(marker, value, 1)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(html, encoding="utf-8")
    _log(f"Wrote {out} ({len(html.encode('utf-8')) // 1024} KB). Open it in a "
         f"browser and give it a snapshot of the game; nothing else runs.")


def design(port, no_browser: bool) -> None:
    if not (CASTLE / "rooms.json").is_file():
        sys.exit(f"No castle at {CASTLE} -- run extract first.")
    filmation()
    command = [sys.executable, str(DESIGNER), str(CASTLE / "rooms.json")]
    if port:
        command += ["--port", str(port)]
    if no_browser:
        command.append("--no-browser")
    try:
        subprocess.run(command, check=False)
    except KeyboardInterrupt:
        pass


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    commands = parser.add_subparsers(dest="command", required=True)
    p = commands.add_parser("page", help="write the standalone editor page")
    p.add_argument("--out", type=Path, default=PAGE_OUT)
    p = commands.add_parser("extract", help="write the castle from a snapshot")
    p.add_argument("--snapshot", type=Path, default=DEFAULT_SNAPSHOT,
                   help=f"a snapshot of Knight Lore you own (default: "
                        f"{DEFAULT_SNAPSHOT.relative_to(PROJECT_ROOT)})")
    p.add_argument("--force", action="store_true",
                   help="overwrite a castle that is already there")
    p = commands.add_parser("design", help="open the room designer on it")
    p.add_argument("--port", type=int)
    p.add_argument("--no-browser", action="store_true")
    p = commands.add_parser("build", help="write the patched snapshot")
    p.add_argument("--out", type=Path, default=PATCHED)
    args = parser.parse_args()

    if args.command == "page":
        page(args.out)
    elif args.command == "extract":
        extract(args.snapshot, args.force)
    elif args.command == "design":
        design(args.port, args.no_browser)
    else:
        build(args.out)


if __name__ == "__main__":
    main()
