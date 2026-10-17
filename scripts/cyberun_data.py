"""Cyberun's level data and its pictures, laid out from the game at every build.

The things lying in the world, the places the pick-ups are dealt to, the
landscape map and its tiles are the game's level design. Described record by
record they are that design again in other words, so -- like Alien 8's rooms
in alien8_data.py -- they are not written into a committed file:
build_cyberun.py calls data_blocks() on the snapshot at every build and puts
what it returns into the control file in place of what sna2ctl guessed for
the same bytes (the ranges in OWNED). What each table *is* -- its label, its
title, its format -- is prose, and stays in scripts/cyberun_annotations.ctl,
which is laid over the top; that file has no sub-block lines inside OWNED.

The same lines carry a picture for every graphic the game has: a D paragraph
of #HTML(<img>) for the entry the graphic is in, so the .asm stays text. The
pictures themselves are drawn by draw_pictures() for the --html build, each
by the game's own drawing routine in SkoolKit's simulator, run on the
snapshot after the game's own start-up (which builds the shift tables, the
shifted landscape pieces and the bit-reversal table the drawers need):

  the sprites                the compositor, draw_sprite_pair (#R$A303), as it
                             draws a sky object or a ground object
  the add-ons                the same, as they lie on the planet; and the ship
                             with each fitted, built by #R$AFE9 and drawn by
                             the direct drawer #R$A59F
  the bare ship, the jets    the direct drawer #R$A59F (the jets' heights read
  and the trail              by #R$C7A3, their widths the drawer entries the
                             jets' own code loads)
  the special beam           expanded by #R$B8DB and drawn by #R$B336
  the font                   the string printer #R$A115
  the panel's bitmaps        draw_bitmap #R$C96F; and the whole panel by #R$CA3F
  the landscape pieces       the POP blitters, through the tables of blitters
                             and graphics by shift (#R$E37D, #R$E2BD, #R$E2FD,
                             #R$E33D)

Every layout below is the one the game's own code reads (the routines are
named in the comments), and each walk checks itself: a table that does not
tile its range, or a record that does not end where the next begins, stops
the build rather than quietly describing something else.
"""
from __future__ import annotations

from pathlib import Path

NEWLINE = "\n"


def _word(memory, address: int) -> int:
    return memory[address] | memory[address + 1] << 8


def _plural(count: int, word: str, plural: str | None = None) -> str:
    return f"{count} {word if count == 1 else (plural or word + 's')}"


def _and(items: list[str]) -> str:
    """a, b and c."""
    if len(items) < 2:
        return "".join(items)
    return ", ".join(items[:-1]) + " and " + items[-1]


def _numbers(values: list[int]) -> str:
    """1, 2, 3, 5 as '1-3 and 5'."""
    runs, start = [], None
    for index, value in enumerate(values):
        if start is None:
            start = value
        if index + 1 == len(values) or values[index + 1] != value + 1:
            if start == value:
                runs.append(str(start))
            elif start + 1 == value:
                runs += [str(start), str(value)]
            else:
                runs.append(f"{start}-{value}")
            start = None
    if len(runs) < 2:
        return "".join(runs)
    return ", ".join(runs[:-1]) + " and " + runs[-1]


# --------------------------------------------------------------------------
# The things lying in the world: three parallel tables, in map-column order
# (#R$E08F finds a column's first object by adding up the counts before it;
# #R$E114 unpacks each object into a slot).
# --------------------------------------------------------------------------

OBJECT_KINDS = 0x5C94       # a byte an object: bits 0-5 the kind, 6 and 7 gone marks
COLUMN_COUNTS = 0x5DB6      # a byte a map column, and column 0's again for the wrap
OBJECT_PLACES = 0x5E17      # two bytes an object
MAP_COLUMNS = 96


def column_counts(memory) -> list[int]:
    return [memory[COLUMN_COUNTS + column] for column in range(MAP_COLUMNS)]


def object_count(memory) -> int:
    total = sum(column_counts(memory))
    # The three tables abut: the kinds end where the counts begin, the
    # counts (with the wrap's extra byte) where the places begin.
    if OBJECT_KINDS + total != COLUMN_COUNTS:
        raise ValueError(f"{total} objects' kinds do not end at the counts")
    if COLUMN_COUNTS + MAP_COLUMNS + 1 != OBJECT_PLACES:
        raise ValueError("the counts do not end at the places")
    return total


def object_place(memory, number: int) -> tuple[int, int, int]:
    """(map row, x, y) of object `number`, as #R$E114 unpacks them: the first
    byte's bits 2-7 less one the y in the page (slot +5), its bits 0-1 bits
    3-4 of the x; the second byte's bits 5-7 bits 5-7 of the x (slot +2),
    its bits 0-4 the map row (slot +4)."""
    first, second = memory[OBJECT_PLACES + 2 * number:OBJECT_PLACES + 2 * number + 2]
    return second & 0x1F, (first & 3) << 3 | (second & 0xE0), (first & 0xFC) - 1


def _object_lines(memory) -> tuple[list[str], list[str], list[str]]:
    counts = column_counts(memory)
    total = object_count(memory)
    kinds, tally, places = [], [], []
    first = 0
    for column, count in enumerate(counts):
        numbers = range(first, first + count)
        if count:
            kind_list = [memory[OBJECT_KINDS + n] & 0x3F for n in numbers]
            gone = [n for n in numbers if memory[OBJECT_KINDS + n] & 0xC0]
            text = (f"Column {column}: kind{'s' if count > 1 else ''} "
                    + ", ".join(str(kind) for kind in kind_list))
            if gone:
                text += f" (gone marks set on the tape: objects {_numbers(gone)})"
            kinds.append(f"B ${OBJECT_KINDS + first:04X},{count},{count} {text}")
            where = []
            for n, kind in zip(numbers, kind_list):
                row, x, y = object_place(memory, n)
                where.append(f"kind {kind} in row {row} at x {x}, y {y}")
            places.append(f"B ${OBJECT_PLACES + 2 * first:04X},{2 * count},2 "
                          f"Column {column}: " + "; ".join(where))
        which = (f" (object {first})" if count == 1 else
                 f" (objects {first}-{first + count - 1})" if count else "")
        tally.append(f"B ${COLUMN_COUNTS + column:04X},1 Column {column}: "
                     f"{_plural(count, 'object')}{which}")
        first += count
    wrap = memory[COLUMN_COUNTS + MAP_COLUMNS]
    if wrap != counts[0]:
        raise ValueError("the count after column 95 is not column 0's")
    tally.append(f"B ${COLUMN_COUNTS + MAP_COLUMNS:04X},1 Column 0's count again "
                 f"({wrap}), read when the next column after 95 wraps round to 0")
    if OBJECT_PLACES + 2 * total != PLACE_POOL:
        raise ValueError("the places do not end at the pick-ups' pool")
    return kinds, tally, places


# --------------------------------------------------------------------------
# The pick-ups' places: a pool in five groups, dealt from by #R$6113 by the
# dealing list. The groups are not in a table: #R$6113's own code picks the
# group's start (LD HL) and a mask one less than its size (LD C) by the
# dealing list's entry (CP), so they are read from those operands.
# --------------------------------------------------------------------------

PLACE_POOL = 0x605B
PLACE_SIZE = 4              # map column, map row, x, y (#R$6113 copies four bytes)
DEAL_PLACES = 0x6113        # the code, which follows the pool
POOL_START_OPERAND = 0x6118  # LD HL,the pool: marking every place free
POOL_COUNT_OPERAND = 0x611B  # LD B,its size
NEVER_DEALT_STORES = (0x6128, 0x612B)   # LD (nn),A with A = $FF: marked dealt first
GROUP_CHOICE = 0x6152       # LD C / LD HL / CP / JR Z ... up to the pick
GROUP_CHOSEN = 0x6179
DEALING_LIST = 0x61A9
DEALING_COUNT = 19          # the player record's nineteen places (#R$6113)
# #R$DF08 brings in places 0-10 as add-ons lying on the planet (graphic $0C,
# the place's number its frame: add-on n + 1) and 11-18 as the rocket parts
# 0-7 (graphic $1E).
ADDON_PLACES = 11


def pool_groups(memory) -> dict[int, tuple[int, int]]:
    """The dealing list's entry (1-5) -> (the group's first place, its size),
    read from #R$6113's code."""
    groups, c, hl, kind, pending = {}, None, None, None, None
    address = GROUP_CHOICE
    while address < GROUP_CHOSEN:
        opcode = memory[address]
        if opcode == 0x0E:                  # LD C,n
            c = memory[address + 1]
            address += 2
        elif opcode == 0x21:                # LD HL,nn
            hl = _word(memory, address + 1)
            address += 3
        elif opcode == 0xFE:                # CP n
            pending = memory[address + 1]
            address += 2
        elif opcode == 0x28:                # JR Z: this kind's group is chosen
            groups[pending] = (hl, c + 1)
            address += 2
        else:
            raise ValueError(f"unexpected opcode ${opcode:02X} at ${address:04X} "
                             f"in the group choice")
    # The kind no CP matched falls through to the last LD HL and LD C.
    left = sorted(set(range(1, 6)) - set(groups))
    if len(left) != 1:
        raise ValueError(f"the group choice leaves {left} unmatched")
    kind = left[0]
    groups[kind] = (hl, c + 1)
    return groups


def never_dealt(memory) -> set[int]:
    places = set()
    for store in NEVER_DEALT_STORES:
        if memory[store] != 0x32:
            raise ValueError(f"no LD (nn),A at ${store:04X}")
        places.add(_word(memory, store + 1))
    return places


def _place_name(place: int) -> str:
    if place < ADDON_PLACES:
        return f"add-on {place + 1}'s"
    return f"rocket part {place - ADDON_PLACES}'s"


def _pool_lines(memory) -> list[str]:
    groups = pool_groups(memory)
    if _word(memory, POOL_START_OPERAND) != PLACE_POOL:
        raise ValueError("the pool is not where #R$6113 marks it free")
    size = memory[POOL_COUNT_OPERAND]
    by_start = sorted((start, count, kind) for kind, (start, count) in groups.items())
    address = PLACE_POOL
    for start, count, kind in by_start:
        if start != address:
            raise ValueError(f"group {kind} starts at ${start:04X}, not ${address:04X}")
        address += PLACE_SIZE * count
    if address != PLACE_POOL + PLACE_SIZE * size or address != DEAL_PLACES:
        raise ValueError("the groups do not fill the pool up to #R$6113")
    skipped = never_dealt(memory)
    dealt_for: dict[int, list[int]] = {}
    for place in range(DEALING_COUNT):
        entry = memory[DEALING_LIST + place]
        if entry:
            dealt_for.setdefault(entry, []).append(place)
    out = []
    for start, count, kind in by_start:
        for index in range(count):
            place = start + PLACE_SIZE * index
            column, row, x, y = memory[place:place + PLACE_SIZE]
            if place in skipped:
                text = (f"Group {kind}, place {index}: never dealt, since #R$6113 marks it "
                        f"dealt before it starts (its bytes: ${column:02X}, row {row}, "
                        f"x {x}, y {y})")
            else:
                text = f"Group {kind}, place {index}: column {column}, row {row}, x {x}, y {y}"
            if index == 0:
                users = dealt_for.get(kind, [])
                if users:
                    text += (f"; a player's place{'s' if len(users) > 1 else ''} "
                             f"{_numbers(users)} {'are' if len(users) > 1 else 'is'} "
                             f"dealt from this group")
            out.append(f"B ${place:04X},{PLACE_SIZE} {text}")
    return out


def _dealing_lines(memory) -> list[str]:
    out = []
    for place in range(DEALING_COUNT):
        entry = memory[DEALING_LIST + place]
        following = memory[DEALING_LIST + place + 1] if place + 1 < DEALING_COUNT else None
        what = f"Place {place} ({_place_name(place)}): "
        if entry:
            what += f"a place from group {entry}"
        elif following == 3:
            what += ("a copy of the place before, 16 to the right and 35 up "
                     "(the entry is 0 and the next is 3)")
        else:
            what += "none: its four bytes are left $FF, no place"
        if place == DEALING_COUNT - 1:
            what += "; the last, dealt again at the end of a planet (#R$83D6)"
        out.append(f"B ${DEALING_LIST + place:04X},1 {what}")
    return out


# --------------------------------------------------------------------------
# The landscape: the map, the tile table and the tile records (#R$DF08,
# #R$D0BD).
# --------------------------------------------------------------------------

LANDSCAPE_MAP = 0x61BC      # rows 1-28 of 96 tile numbers (#R$E216); row 0 is not stored
MAP_ROWS = 28
CAVERN_ROW = 12             # from map row 12 down the planet's second colour (#R$DEE1)
TILE_TABLE = 0x6C3C         # a word a tile: its record
TILE_RECORDS = 0x6D92
TILE_RECORDS_END = 0x70D8   # the title tune
UPSIDE_DOWN = 0x99          # #R$D0BD's markers, in this order
MIRRORED = 0xFF
PADDING = 0x95              # one byte from here up is skipped
FLAT_DIRECTIONS = (0, 7)    # the flat pieces, with two end codes (#R$CD6B)


def tile_count() -> int:
    return (TILE_RECORDS - TILE_TABLE) // 2


def read_tile(memory, address: int) -> dict:
    """A tile's record read the way #R$D0BD reads it: an empty tile is a
    zero; otherwise $99 (upside down), then $FF (mirrored), then one byte
    of $95 or more skipped; then the count of pieces, and each piece's x, y
    and direction-and-steps byte, and two end codes for a flat one."""
    tile = {"pointer": address, "upside": False, "mirrored": False, "pieces": []}
    p = address
    if memory[p]:
        if memory[p] == UPSIDE_DOWN:
            tile["upside"] = True
            p += 1
        if memory[p] == MIRRORED:
            tile["mirrored"] = True
            p += 1
        if memory[p] >= PADDING:
            p += 1
    tile["count_at"] = p
    count = memory[p]
    p += 1
    for _ in range(count):
        x, y, packed = memory[p:p + 3]
        direction, steps = packed >> 4, packed & 15 or 16
        size = 5 if direction in FLAT_DIRECTIONS else 3
        ends = tuple(memory[p + 3:p + 5]) if size == 5 else ()
        tile["pieces"].append({"at": p, "x": x, "y": y, "direction": direction,
                               "steps": steps, "ends": ends, "size": size})
        p += size
    tile["end"] = p
    return tile


def tile_pointers(memory) -> list[int]:
    return [_word(memory, TILE_TABLE + 2 * tile) for tile in range(tile_count())]


def tile_groups(memory) -> list[dict]:
    """The records end to end: each a run of marker bytes ($95 and up), then
    a count and its pieces. Up to four tiles share one, pointing at its
    count or into its markers. Checked to tile the range, and every tile's
    reading checked to land on its group's count."""
    groups = []
    p = TILE_RECORDS
    while p < TILE_RECORDS_END:
        start = p
        while memory[p] >= PADDING:
            p += 1
        plain = read_tile(memory, p)
        groups.append({"start": start, "count_at": p, "plain": plain, "end": plain["end"],
                       "tiles": []})
        p = plain["end"]
    if p != TILE_RECORDS_END:
        raise ValueError(f"the tile records run to ${p:04X}, not ${TILE_RECORDS_END:04X}")
    for tile, pointer in enumerate(tile_pointers(memory)):
        group = next((g for g in groups if g["start"] <= pointer <= g["count_at"]), None)
        if group is None:
            raise ValueError(f"tile ${tile:02X} points at ${pointer:04X}, inside a record")
        reading = read_tile(memory, pointer)
        if reading["count_at"] != group["count_at"]:
            raise ValueError(f"tile ${tile:02X} does not read its group's count")
        group["tiles"].append((tile, reading))
    return groups


def _reading(tile: dict) -> str:
    if tile["upside"] and tile["mirrored"]:
        return "upside down and mirrored left-right"
    if tile["upside"]:
        return "upside down"
    if tile["mirrored"]:
        return "mirrored left-right"
    return "as it is"


def _pieces_text(pieces: list[dict]) -> str:
    if not pieces:
        return "no pieces"
    parts = []
    for piece in pieces:
        text = (f"({piece['x']},{piece['y']}) direction {piece['direction']} "
                f"x {_plural(piece['steps'], 'step')}")
        if piece["ends"]:
            text += f", ends ${piece['ends'][0]:02X} ${piece['ends'][1]:02X}"
        parts.append(text)
    return f"{_plural(len(pieces), 'piece')}: " + "; ".join(parts)


def _tile_record_lines(memory, groups: list[dict]) -> list[str]:
    out = []
    for group in groups:
        start, count_at = group["start"], group["count_at"]
        subs = [1] * (count_at - start) + [1] + [piece["size"] for piece in
                                                 group["plain"]["pieces"]]
        # Each marker a statement of its own, so that every tile's pointer
        # lands on one.
        used = set()
        for _, reading in group["tiles"]:
            used.update(range(reading["pointer"], reading["count_at"]))
        tiles = sorted(group["tiles"], key=lambda item: (-item[1]["pointer"], item[0]))
        if tiles:
            names = [f"${tile:02X}" + ("" if reading["pointer"] == count_at
                                       else " " + _reading(reading))
                     for tile, reading in tiles]
            text = "Tile" + ("s " if len(names) > 1 else " ") + _and(names)
        else:
            text = "No tile reads this record"
        unread = [a for a in range(start, count_at) if a not in used]
        if unread:
            text += (f" (the marker{'s' if len(unread) > 1 else ''} "
                     + " ".join(f"${memory[a]:02X}" for a in unread)
                     + f" at its start {'are' if len(unread) > 1 else 'is'} read by no tile)")
        pieces = _pieces_text(group["plain"]["pieces"])
        text += ". " + pieces[0].upper() + pieces[1:]
        sub = ",".join(str(s) for s in subs)
        out.append(f"B ${start:04X},{group['end'] - start},{sub} {text}")
    return out


def _map_cell_tiles(memory) -> list[list[int]]:
    return [[memory[LANDSCAPE_MAP + MAP_COLUMNS * row + column] for column in range(MAP_COLUMNS)]
            for row in range(MAP_ROWS)]


def _tile_lines(memory, groups: list[dict]) -> list[str]:
    uses: dict[int, int] = {}
    for row in _map_cell_tiles(memory):
        for tile in row:
            uses[tile] = uses.get(tile, 0) + 1
    plain_of = {}
    for group in groups:
        for tile, reading in group["tiles"]:
            if reading["pointer"] == group["count_at"]:
                plain_of.setdefault(group["count_at"], tile)
    out = []
    for tile, pointer in enumerate(tile_pointers(memory)):
        reading = read_tile(memory, pointer)
        count = len(reading["pieces"])
        text = f"Tile ${tile:02X}: {_plural(count, 'piece')}" if count else \
            f"Tile ${tile:02X}: no pieces"
        if count and reading["pointer"] != reading["count_at"]:
            text += ", " + _reading(reading)
            plain = plain_of.get(reading["count_at"])
            if plain is not None:
                text += f" (the pieces of tile ${plain:02X})"
        times = uses.get(tile, 0)
        text += f"; in the map {_plural(times, 'time')}" if times else "; not in the map"
        out.append(f"W ${TILE_TABLE + 2 * tile:04X},2 {text}")
    return out


def _map_lines(memory) -> list[str]:
    pieces = [len(read_tile(memory, pointer)["pieces"]) for pointer in tile_pointers(memory)]
    out = []
    for row, cells in enumerate(_map_cell_tiles(memory), 1):
        where = "the surface" if row < CAVERN_ROW else "the caverns"
        full = sum(1 for tile in cells if pieces[tile])
        out.append(f"B ${LANDSCAPE_MAP + MAP_COLUMNS * (row - 1):04X},{MAP_COLUMNS},12 "
                   f"Row {row}, {where}: {full} of the {MAP_COLUMNS} cells have pieces")
    if LANDSCAPE_MAP + MAP_COLUMNS * MAP_ROWS != TILE_TABLE:
        raise ValueError("the map does not end at the tile table")
    return out


# --------------------------------------------------------------------------
# The pictures.
# --------------------------------------------------------------------------

SPRITES = 0x731F            # the sprite graphics, to the code at #R$8347
SPRITES_END = 0x8347
ADDON_GRAPHICS = 0xAF95     # eleven words: add-ons 1-11 (#R$B09C, type $0C's frames)
ADDON_COUNT = 11
SHIP_ADDONS = 9             # add-ons 1-9 are fitted to the ship (#R$AFE9's nine slots)
ROCKET_PART_FRAMES = 0xAF7B  # type $1E's nine frames; the last the full ore tank
ROCKET_FRAME_COUNT = 9
GRAPHIC_LISTS = 0xAF3D      # a word per type: a graphic, or a list of frames
TRAIL_TYPES = range(1, 7)   # types 1-6 are the trail's images themselves (#R$C4ED)
STAR_TYPES = range(7, 12)   # types 7-11 the stars' (#R$C032)
JET_TYPES = range(0x0E, 0x13)   # $0E-$10 the side jet's, $11 and $12 the lift jet's
SIDE_JET_DRAWER = 0xC66A    # the LD IX,draw-row operand in #R$C5FF
LIFT_JET_DRAWER = 0xC75F    # the same in #R$C6D2
MISSILE_FRAMES = 0xB936     # type 0's list: two words
DASH = 0x89CF               # the attackers' shot, type $1C's frame 10
BEAM_FRAMES = 0xB8CF        # six words, four frames
BEAM_FRAME_SLOTS = 6
ORE_ROWS = 0x7721           # the ore graphic #R$A8D9 copies into the ship
BARE_SHIP = 0xC891
FONT = 0x9F76
FONT_CHARS = 45             # 7 bytes each, to #R$A0B1
FONT_LETTERS = 26
BITMAPS = [0x870E, 0x874F, 0xC927, 0xC94D, 0xC955, 0xCB66, 0xCBD1, 0xCBDB]
CORNER_BITMAPS = 0xCC14     # four, one after another
CORNER_COUNT = 4
COPYRIGHT_GLYPHS = 0xF2E3   # two, one after another
DRAW_PANEL = 0xCA3F

# The landscape's pieces: the four tables of blitter and graphic by
# direction, one per fine shift, and the variants' offsets.
SHIFT_TABLES = ((0, 0xE37D), (2, 0xE2BD), (4, 0xE2FD), (6, 0xE33D))
PLAIN_DIRECTIONS = (0, 7, 1, 8, 2, 9, 3, 10, 14)  # the nine with graphics of their own
GRAPHIC_OFFSETS = 0xCCBF    # six bytes a shape: unshifted and shifted offsets interleaved
PIECE_SHAPES = 0xE3BD       # three bytes a shape: run, width, rise
FLAT_HEADER = 2             # the header #R$F8E2 reads before a flat piece
SLOPE_HEADER = 3            # the header #R$F939 reads before a slope or the wall
FLAT_ROW_PAIRS = 2          # a flat step is four rows (#R$E24D)
FLAT_CAPS = 4               # the flat pieces' four end caps follow the variants
VARIANTS = 3
PLANET_COLOURS = 0xDC97     # planet 0's pair first: the surface's colour, the caverns'


def picture_name(address: int, suffix: str = "") -> str:
    """By address, so the lines can name a picture before it is drawn."""
    return f"{address:04x}{'-' + suffix if suffix else ''}.png"


def _shape(direction: int) -> int:
    """The shape record (#R$E3BD) and offsets row (#R$CCBF) of a direction:
    0-6 their own, 7-13 seven less, the walls 14 and 15 records 7 and 8."""
    if direction < 7:
        return direction
    return direction - 7


def _plain_graphics(memory, start: int, end: int) -> list[int]:
    """The plain form, end to end: a width, a height, the rows."""
    found = []
    address = start
    while address < end:
        found.append(address)
        address += 2 + memory[address] * memory[address + 1]
    if address != end:
        raise ValueError(f"the graphics from ${start:04X} run to ${address:04X}, not ${end:04X}")
    return found


def sprite_graphics(memory) -> dict:
    """Every graphic from #R$731F to the code, by form, read from the game's
    own pointers where it has them and walked end to end where it does not."""
    addons = [_word(memory, ADDON_GRAPHICS + 2 * n) for n in range(ADDON_COUNT)]
    fitted = addons[:SHIP_ADDONS]
    rocket = [_word(memory, ROCKET_PART_FRAMES + 2 * n) for n in range(ROCKET_FRAME_COUNT)]
    full_tank = rocket[-1]
    jets = [_word(memory, GRAPHIC_LISTS + 2 * t) for t in JET_TYPES]
    beams = []
    for slot in range(BEAM_FRAME_SLOTS):
        frame = _word(memory, BEAM_FRAMES + 2 * slot)
        if frame not in beams:
            beams.append(frame)
    # Plain graphics before the add-on form (rocket parts, add-ons 10 and 11,
    # which have no height byte or mask), up to the height byte before the
    # first add-on; after the full tank; between the jets and the beam; and
    # after the beam to the code.
    first_addon = min(fitted)
    plain = _plain_graphics(memory, SPRITES, first_addon - 1)
    after_tank = full_tank + 2 + memory[full_tank] * memory[full_tank + 1]
    plain += _plain_graphics(memory, after_tank, min(jets))
    jet_end = max(jets) + 1 + memory[max(jets)] * 4
    plain += _plain_graphics(memory, jet_end, min(beams))
    beam_end = max(beams) + 1 + 2 * memory[max(beams)]
    plain += _plain_graphics(memory, beam_end, SPRITES_END)
    plain.append(full_tank)
    return {"addons": addons, "fitted": fitted, "rocket": rocket, "jets": jets,
            "beams": beams, "plain": sorted(set(plain))}


def _img(css: str, name: str, alt: str) -> str:
    return f'#HTML(<img class="{css}" src="../images/graphics/{name}" alt="{alt}">)'


def pictures(memory) -> list[dict]:
    """Every picture: the entry it goes in, the file, what draws it, and the
    caption. One dict per entry, with its images in order."""
    graphics = sprite_graphics(memory)
    addons, fitted = graphics["addons"], graphics["fitted"]
    entries: dict[int, dict] = {}

    def add(entry: int, image: dict, caption: str) -> None:
        item = entries.setdefault(entry, {"entry": entry, "images": [], "caption": caption})
        item["images"].append(image)

    compositor = ("As the compositor #R$A303 draws it in play (three times the size; "
                  "sprites have no colour of their own).")
    for address in graphics["plain"]:
        entry = address
        if address in addons[SHIP_ADDONS:]:
            # Add-ons 10 and 11: a size entry, then the picture's own.
            entry = address + 2
        add(entry, {"name": picture_name(address), "css": "cy-sprite", "alt": "A sprite",
                    "draw": ("compositor", address)}, compositor)
    for number, address in enumerate(fitted, 1):
        caption = ("Lying on the planet, as the compositor #R$A303 draws a type $0C "
                   "object; and fitted to the ship: #R$AFE9 builds the ship's picture "
                   "with it (its mask, if it has one, ANDed on first by #R$B0E4) and the "
                   "direct drawer #R$A59F draws the ship.")
        if number == 2:
            caption += " Add-on 2 comes and goes with add-on 1, so the ship has both."
        add(address, {"name": picture_name(address), "css": "cy-sprite",
                      "alt": f"Add-on {number}", "draw": ("compositor", address)}, caption)
        add(address, {"name": picture_name(address, "ship"), "css": "cy-sprite",
                      "alt": f"The ship with add-on {number}",
                      "draw": ("ship", 1 if number == 2 else number, 0)}, caption)
    add(ORE_ROWS, {"name": picture_name(ORE_ROWS, "ship"), "css": "cy-sprite",
                   "alt": "The ship with its tank full of ore",
                   "draw": ("ship", 3, 18)},
        "The ship with the ore tank (add-on 3) fitted and 18 units of ore aboard: "
        "#R$AFE9 builds the ship's picture and draws the ore into it (#R$A8D9), and the "
        "direct drawer #R$A59F draws the ship.")
    for index, address in enumerate(graphics["jets"]):
        kind = JET_TYPES[index]
        operand = SIDE_JET_DRAWER if kind < 0x11 else LIFT_JET_DRAWER
        add(address, {"name": picture_name(address), "css": "cy-sprite", "alt": "A jet",
                      "draw": ("jet", kind, _word(memory, operand))},
            "As the direct drawer #R$A59F draws it, at the width the jet's own code "
            f"gives it ({'#R$C5FF' if kind < 0x11 else '#R$C6D2'}), three times the size.")
    for address in graphics["beams"]:
        frame = [_word(memory, BEAM_FRAMES + 2 * s) for s in range(BEAM_FRAME_SLOTS)].index(address)
        add(address, {"name": picture_name(address), "css": "cy-sprite",
                      "alt": "A frame of the special beam", "draw": ("beam", frame)},
            "Eight cells of the special beam in this frame: expanded by #R$B8DB and "
            "drawn by #R$B336, as the beam is drawn in play (three times the size).")
    add(BARE_SHIP, {"name": picture_name(BARE_SHIP), "css": "cy-sprite",
                    "alt": "The bare ship", "draw": ("ship", 0, 0)},
        "The ship with nothing fitted: #R$AFE9 builds its picture from these rows and "
        "the direct drawer #R$A59F draws it, as in play (three times the size).")
    for kinds, entry, what in ((TRAIL_TYPES, 0xC7C8, "trail"), (STAR_TYPES, 0xC190, "star")):
        for kind in kinds:
            address = _word(memory, GRAPHIC_LISTS + 2 * kind)
            draw = ("direct_plain", address) if what == "trail" else ("compositor", address)
            add(entry, {"name": picture_name(address), "css": "cy-sprite",
                        "alt": f"Graphic {kind}", "draw": draw},
                ("Graphics 1 to 6, as the direct drawer #R$A59F draws the trail "
                 "(three times the size).") if what == "trail" else
                ("Graphics 7 to 11, as the compositor #R$A303 draws the stars "
                 "(three times the size)."))
    for slot in range(2):
        address = _word(memory, MISSILE_FRAMES + 2 * slot)
        add(address, {"name": picture_name(address), "css": "cy-sprite",
                      "alt": "The missile", "draw": ("compositor", address)}, compositor)
    add(DASH, {"name": picture_name(DASH), "css": "cy-sprite", "alt": "The dash",
               "draw": ("compositor", DASH)}, compositor)
    add(FONT, {"name": picture_name(FONT), "css": "cy-sprite", "alt": "The font",
               "draw": ("font",)},
        f"The {FONT_CHARS} characters in order, printed by #R$A115 (three times the size).")
    bitmap = "As #R$C96F draws it (three times the size)."
    for address in BITMAPS:
        add(address, {"name": picture_name(address), "css": "cy-sprite", "alt": "A bitmap",
                      "draw": ("bitmap", address)}, bitmap)
    address = CORNER_BITMAPS
    for _ in range(CORNER_COUNT):
        add(CORNER_BITMAPS, {"name": picture_name(address), "css": "cy-sprite",
                             "alt": "A corner", "draw": ("bitmap", address)},
            "The four corners in turn, as #R$C96F draws them (three times the size).")
        address += 2 + memory[address] * memory[address + 1]
    address = COPYRIGHT_GLYPHS
    for _ in range(2):
        add(COPYRIGHT_GLYPHS, {"name": picture_name(address), "css": "cy-sprite",
                               "alt": "A glyph", "draw": ("bitmap", address)},
            "The two, as #R$C96F draws them (three times the size).")
        address += 2 + memory[address] * memory[address + 1]
    add(DRAW_PANEL, {"name": picture_name(DRAW_PANEL), "css": "cy-picture",
                     "alt": "The panel and the frame", "draw": ("panel",)},
        "What it draws on a clear screen, run in the simulator after the game's start-up "
        "(twice the size).")
    for direction in PLAIN_DIRECTIONS:
        shape = _shape(direction)
        flat = direction in FLAT_DIRECTIONS
        steps = []
        for shift, table in SHIFT_TABLES:
            blitter = _word(memory, table + 4 * direction)
            graphic = _word(memory, table + 4 * direction + 2)
            offsets = [memory[GRAPHIC_OFFSETS + 6 * shape + 2 * v + (1 if shift else 0)]
                       for v in range(VARIANTS)]
            if flat:
                size = offsets[1] - offsets[0]
                offsets += [offsets[-1] + size * (n + 1) for n in range(FLAT_CAPS)]
                pairs = FLAT_ROW_PAIRS
            else:
                pairs = memory[PIECE_SHAPES + 3 * shape + 2] // 2
            steps.append((shift, blitter, graphic, offsets, pairs))
        stored = steps[0][2] - (FLAT_HEADER if flat else SLOPE_HEADER)
        shifted = steps[1][2]
        each = (" and its four end caps" if flat else "")
        jumps = (" (its clipping jumps set to draw every column, as #R$D588 sets them "
                 "for a step clear of the edges)" if flat else "")
        add(stored, {"name": picture_name(stored), "css": "cy-picture",
                     "alt": f"Direction {direction}", "draw": ("pieces", [steps[0]])},
            f"Its three variants{each}, each drawn as one step of direction {direction} "
            f"at shift 0 by the blitter #R$E37D gives it{jumps}, in planet 0's surface "
            f"colour (four times the size).")
        add(shifted, {"name": picture_name(shifted), "css": "cy-picture",
                      "alt": f"Direction {direction} shifted", "draw": ("pieces", steps[1:])},
            f"As the game's start-up makes them (run in the simulator): the variants{each} "
            f"at shifts 2, 4 and 6, a row each, each drawn as one step of direction "
            f"{direction} by the blitter #R$E2BD, #R$E2FD or #R$E33D gives it{jumps}, in "
            f"planet 0's surface colour (four times the size).")
    return [entries[entry] for entry in sorted(entries)]


def _picture_lines(memory) -> list[str]:
    out = []
    for item in pictures(memory):
        images = " ".join(_img(image["css"], image["name"], image["alt"])
                          for image in item["images"])
        out.append(f"D ${item['entry']:04X} {images} {item['caption']}")
    return out


# --------------------------------------------------------------------------
# Together.
# --------------------------------------------------------------------------

# The ranges the generated lines describe completely: build_cyberun.py drops
# whatever sna2ctl put inside them. (start, end), end exclusive.
OWNED = [(OBJECT_KINDS, COLUMN_COUNTS), (COLUMN_COUNTS, OBJECT_PLACES),
         (OBJECT_PLACES, PLACE_POOL), (PLACE_POOL, DEAL_PLACES),
         (DEALING_LIST, LANDSCAPE_MAP), (LANDSCAPE_MAP, TILE_TABLE),
         (TILE_TABLE, TILE_RECORDS), (TILE_RECORDS, TILE_RECORDS_END)]


def data_blocks(memory) -> str:
    """The control-file lines for every table above, in address order, and
    the picture paragraphs. The entries' titles and prose are the
    annotations'; these give each block its type and its sub-blocks."""
    if DEALING_LIST + DEALING_COUNT != LANDSCAPE_MAP:
        raise ValueError("the dealing list does not end at the map")
    kinds, tally, places = _object_lines(memory)
    groups = tile_groups(memory)
    lines = ["; Generated by scripts/cyberun_data.py from the snapshot -- do not edit.", ""]
    lines += [f"b ${OBJECT_KINDS:04X}"] + kinds + [""]
    lines += [f"b ${COLUMN_COUNTS:04X}"] + tally + [""]
    lines += [f"b ${OBJECT_PLACES:04X}"] + places + [""]
    lines += [f"b ${PLACE_POOL:04X}"] + _pool_lines(memory) + [""]
    lines += [f"b ${DEALING_LIST:04X}"] + _dealing_lines(memory) + [""]
    lines += [f"b ${LANDSCAPE_MAP:04X}"] + _map_lines(memory) + [""]
    lines += [f"b ${TILE_TABLE:04X}"] + _tile_lines(memory, groups) + [""]
    lines += [f"b ${TILE_RECORDS:04X}"] + _tile_record_lines(memory, groups) + [""]
    lines += ["; The pictures (drawn by draw_pictures for the --html build)."]
    lines += _picture_lines(memory) + [""]
    return NEWLINE.join(lines) + NEWLINE


# --------------------------------------------------------------------------
# Drawing the pictures, by the game's own code in the simulator.
# --------------------------------------------------------------------------

# The game's start jumps here once #R$F86B has built the shift tables, the
# shifted landscape pieces and the bit-reversal table; nothing is drawn yet.
START_DONE = 0xF422
# A place in the ROM where nothing runs (the 48K ROM's spare bytes from
# $386E are all $FF): a routine called on its own returns here.
RETURN = 0x386E
CALL_LIMIT = 3_500_000      # a second: more is a hang
PIXELS, ATTRIBUTES, SCREEN_END = 0x4000, 0x5800, 0x5B00
SPRITE_X, SPRITE_Y = 0x60, 0xA0     # byte-aligned, clear of every clip
SCRATCH = 0xF800            # the compositor's buffer: free between drawings
SHOT_RECORD = 0xB37A        # the first of the player's shot records
SHOT_FRAME = 0x15           # its frame (#R$B8C3)
BEAM_CELLS = 8              # the most #R$B336 draws from one expanded row
JET_RECORD = 0xC6C2         # the side jet's record: +0 the graphic (#R$C7A3)
DIRECT_DRAW_ROW = 0xA678    # six byte-steps of five bytes, entered by the width
DIRECT_STEP = 5
ADDON_SLOTS = 0xF5EE        # nine: add-on n's slot n, or 0
PART_FITTED = 0xC904
ORE = 0xC905
SHIP_HEIGHT = 0xC1A9
SHIP_GRAPHIC = 0xC1AA
SHIP_CLEARED = 0xDD41       # in #R$DCA1: clear the 300 bytes of the picture...
SHIP_BUILT = 0xDD52         # ...and CALL #R$AFE9 to build it; back from that here
DIRECT_DRAW = 0xA59F
DIRECT_OLD_ROWS = 0x5C1C
DIRECT_NEW_ROWS = 0x5C1D
FLAT_JRS = (0xE25A, 0xE25E, 0xE262)  # #R$D588 sets them 0 for a step clear of the edges
STEP_DONE = 0xD711          # where a blitter goes when its step is drawn
FLAT_STEP_DONE = 0xD714
FONT_ATTRIBUTE = 0x47
INK = (255, 255, 255, 255)
CLEAR = (0, 0, 0, 0)
SPRITE_SCALE, PIECE_SCALE, PANEL_SCALE = 3, 4, 2

SPECTRUM = [(0, 0, 0), (0, 0, 0xD7), (0xD7, 0, 0), (0xD7, 0, 0xD7),
            (0, 0xD7, 0), (0, 0xD7, 0xD7), (0xD7, 0xD7, 0), (0xD7, 0xD7, 0xD7)]
BRIGHT = [tuple(0xFF if v else 0 for v in rgb) for rgb in SPECTRUM]


def _colours(attribute: int) -> tuple[tuple, tuple]:
    table = BRIGHT if attribute & 0x40 else SPECTRUM
    return table[attribute & 7] + (255,), table[attribute >> 3 & 7] + (255,)


def _screen_address(column: int, line: int) -> int:
    return PIXELS | (line & 0xC0) << 5 | (line & 7) << 8 | (line & 0x38) << 2 | column


class _Machine:
    """The game after its own start-up, with routines called on their own."""

    def __init__(self, snapshot: Path):
        import build_cyberun as bc
        from skoolkit.simutils import PC, REGISTERS, SP, T

        self.machine = bc.Machine(snapshot)
        self.machine.run_to(bc.At("the end of the start-up", START_DONE, 10.0), "pictures")
        self.sim = self.machine.simulator
        self.memory = self.sim.memory
        self.registers = self.sim.registers
        self.PC, self.SP, self.T, self.REG = PC, SP, T, REGISTERS
        self.stack = self.registers[SP]

    def set(self, **registers) -> None:
        pairs = {"IX": ("IXh", "IXl"), "IY": ("IYh", "IYl"), "HL": ("H", "L"),
                 "DE": ("D", "E"), "BC": ("B", "C")}
        for name, value in registers.items():
            if name in pairs:
                high, low = pairs[name]
                self.registers[self.REG[high]] = value >> 8
                self.registers[self.REG[low]] = value & 0xFF
            elif name == "SP":
                self.registers[self.SP] = value
            else:
                self.registers[self.REG[name]] = value

    def get(self, pair: str) -> int:
        high, low = {"DE": ("D", "E"), "HL": ("H", "L"), "BC": ("B", "C")}[pair]
        return self.registers[self.REG[high]] << 8 | self.registers[self.REG[low]]

    def run(self, address: int, stop: int) -> None:
        self.registers[self.PC] = address
        self.sim.trace(address, stop, 0, self.registers[self.T] + CALL_LIMIT, True,
                       None, None, None, None, None)
        if self.registers[self.PC] != stop:
            raise RuntimeError(f"${address:04X} did not reach ${stop:04X} "
                               f"(PC ${self.registers[self.PC]:04X})")

    def call(self, address: int, **registers) -> None:
        self.set(**registers)
        sp = (self.registers[self.SP] - 2) & 0xFFFF
        self.memory[sp], self.memory[sp + 1] = RETURN & 0xFF, RETURN >> 8
        self.registers[self.SP] = sp
        self.run(address, RETURN)

    def clear(self, attribute: int = 0) -> None:
        for address in range(PIXELS, ATTRIBUTES):
            self.memory[address] = 0
        for address in range(ATTRIBUTES, SCREEN_END):
            self.memory[address] = attribute

    def image(self, column: int, top: int, width: int, height: int, scale: int,
              ink=INK, paper=CLEAR, attributes: bool = False):
        """The screen's bytes in a box, ink and paper given or (attributes)
        each cell's own."""
        from PIL import Image

        picture = Image.new("RGBA", (8 * width, height), paper)
        pixels = picture.load()
        for row in range(height):
            line = top + row
            for byte in range(width):
                bits = self.memory[_screen_address(column + byte, line)]
                if attributes:
                    cell_ink, cell_paper = _colours(
                        self.memory[ATTRIBUTES + (line >> 3) * 32 + column + byte])
                else:
                    cell_ink, cell_paper = ink, paper
                for bit in range(8):
                    pixels[8 * byte + bit, row] = cell_ink if bits & 0x80 >> bit else cell_paper
        return picture.resize((picture.width * scale, picture.height * scale), Image.NEAREST)

    # The drawers.

    def compositor(self, graphic: int):
        """An object's new image with no old one, as #R$AD48 and #R$C032 set
        it up: #R$A2EA, the place, #R$A1D9 (header, clip), #R$A247 (row
        routine, shift page), then #R$A303."""
        self.clear()
        self.call(0xA2EA)
        self.memory[0xA1D5], self.memory[0xA1D6] = SPRITE_X, SPRITE_Y
        self.call(0xA1D9, DE=graphic)
        self.call(0xA247)
        self.call(0xA303)
        width, height = self.memory[graphic], self.memory[graphic + 1]
        return self.image(SPRITE_X // 8, SPRITE_Y - height + 1, width, height, SPRITE_SCALE)

    def direct(self, rows: int, width: int, height: int):
        """A new image straight onto the screen by #R$A59F, no old image."""
        self.call(0xA149, H=SPRITE_Y, L=SPRITE_X)
        screen = self.get("HL")
        self.memory[DIRECT_OLD_ROWS], self.memory[DIRECT_NEW_ROWS] = 0, height
        self.call(DIRECT_DRAW, HL=screen, DE=rows,
                  IX=DIRECT_DRAW_ROW + DIRECT_STEP * (6 - width))
        return self.image(SPRITE_X // 8, SPRITE_Y - height + 1, width, height, SPRITE_SCALE)

    def direct_plain(self, graphic: int):
        self.clear()
        return self.direct(graphic + 2, self.memory[graphic], self.memory[graphic + 1])

    def jet(self, kind: int, drawer: int):
        self.clear()
        self.memory[JET_RECORD] = kind
        self.call(0xC7A3, IX=JET_RECORD)
        height, rows = self.registers[self.REG["A"]], self.get("DE")
        return self.direct(rows, 6 - (drawer - DIRECT_DRAW_ROW) // DIRECT_STEP, height)

    def ship(self, addon: int, ore: int):
        self.clear()
        for slot in range(SHIP_ADDONS):
            self.memory[ADDON_SLOTS + slot] = 0
        if addon:
            self.memory[ADDON_SLOTS + addon - 1] = addon
        self.memory[PART_FITTED] = 0
        self.memory[ORE] = ore
        # A life's start in #R$DCA1: clear the picture, then build it.
        self.run(SHIP_CLEARED, SHIP_BUILT)
        return self.direct(_word(self.memory, SHIP_GRAPHIC), 6, self.memory[SHIP_HEIGHT])

    def beam(self, frame: int):
        self.clear()
        self.memory[SHOT_RECORD] = 0          # +0 bit 7 clear: going right
        self.memory[SHOT_RECORD + SHOT_FRAME] = frame
        self.call(0xB8B5, IX=SHOT_RECORD)
        pattern, height = self.get("DE"), self.memory[0xA1D8]
        self.call(0xB336, B=BEAM_CELLS, DE=pattern,
                  HL=_screen_address(SPRITE_X // 8, SPRITE_Y))
        return self.image(SPRITE_X // 8, SPRITE_Y - height + 1, BEAM_CELLS, height,
                          SPRITE_SCALE)

    def font(self):
        """Two string records into the scratch page -- x, y, attribute,
        count, the codes -- printed by #R$A115: the letters, then the rest."""
        self.clear()
        lines = [(0x40, range(FONT_LETTERS)), (0x50, range(FONT_LETTERS, FONT_CHARS))]
        record = SCRATCH
        for y, codes in lines:
            data = [8, y, FONT_ATTRIBUTE, len(codes)] + list(codes)
            for offset, byte in enumerate(data):
                self.memory[record + offset] = byte
            record += len(data)
        self.call(0xA115, DE=SCRATCH)
        self.call(0xA115)
        top = lines[0][0] - 6
        return self.image(1, top, FONT_LETTERS, lines[1][0] - top + 1, SPRITE_SCALE)

    def bitmap(self, address: int):
        self.clear()
        self.call(0xC96F, H=SPRITE_Y, L=SPRITE_X, DE=address)
        width, height = self.memory[address], self.memory[address + 1]
        return self.image(SPRITE_X // 8, SPRITE_Y - height + 1, width, height, SPRITE_SCALE)

    def panel(self):
        self.clear(FONT_ATTRIBUTE)
        self.call(DRAW_PANEL)
        return self.image(0, 0, 32, 192, PANEL_SCALE, attributes=True)

    def pieces(self, rows):
        """Each row a fine shift: its variants (and caps) side by side, each
        a step drawn by its blitter with SP at the graphic, as #R$D672 enters
        them, and stopped where the blitter jumps back to #R$D711."""
        self.clear()
        attribute = self.memory[PLANET_COLOURS]
        for address in FLAT_JRS:
            self.memory[address] = 0
        boxes = []
        # An odd line, as every step's bottom row is in play (#R$D672 ends a
        # piece on $B7): a blitter writes a pair's upper row after a plain
        # DEC H, and fixes up a crossing into the cell above only after it.
        bottom = 0x2F
        for shift, blitter, graphic, offsets, pairs in rows:
            # Far enough in that HL, entered left of the step, stays on the row.
            column = 4
            width = _blitter_width(self.memory, blitter)
            advance = _column_advance(self.memory, blitter)
            done = FLAT_STEP_DONE if blitter == BLITTERS[0][0] else STEP_DONE
            for offset in offsets:
                self.set(A=pairs, SP=graphic + offset,
                         HL=_screen_address(column - advance, bottom))
                self.run(blitter, done)
                self.set(SP=self.stack)
                boxes.append((column, bottom - 2 * pairs + 1, width, 2 * pairs))
                column += width + 1
            bottom += 2 * pairs + 8
        left = min(b[0] for b in boxes)
        top = min(b[1] for b in boxes)
        right = max(b[0] + b[2] for b in boxes)
        low = max(b[1] + b[3] for b in boxes)
        ink, paper = _colours(attribute)
        return self.image(left, top, right - left, low - top, PIECE_SCALE, ink, (0, 0, 0, 255))


# The blitters' widths in bytes, by the routine an entry is in (#R$E24D the
# flat step; #R$E48B one byte; #R$E4A7 three; #R$E4CF two).
BLITTERS = ((0xE24D, 3), (0xE48B, 1), (0xE4A7, 3), (0xE4CF, 2), (0xE4F1, 0))


def _blitter_width(memory, entry: int) -> int:
    width = None
    for start, bytes_wide in BLITTERS:
        if entry >= start:
            width = bytes_wide
    if not width:
        raise ValueError(f"no blitter width for ${entry:04X}")
    return width


def _column_advance(memory, entry: int) -> int:
    """The INC Ls a blitter does before its first write: it is entered with
    HL that many bytes left of the step (#R$E24D's three come after it moves
    #R$CE49 on). Counted up to its first POP DE or JR."""
    count = 0
    address = entry
    while memory[address] not in (0xD1, 0x18):
        if memory[address] == 0x2C:
            count += 1
        address += 1
    return count


def draw_pictures(snapshot: Path, out_dir: Path, log=print) -> int:
    """Draw every picture data_blocks() names into out_dir."""
    import build_cyberun as bc

    memory = bc.game_memory(snapshot)
    machine = _Machine(snapshot)
    out_dir.mkdir(parents=True, exist_ok=True)
    count = 0
    for item in pictures(memory):
        for image in item["images"]:
            how, *args = image["draw"]
            picture = getattr(machine, how)(*args)
            picture.save(out_dir / image["name"])
            count += 1
    return count
