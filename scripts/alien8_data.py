"""Alien 8's level data and graphics, laid out a record per line from the game.

The room directory, the object and background templates, the places the
valves can lie, the graphic table, the sprites and the font are the game's
own design. Described record by record they are that design again in other
words, so -- like Knight Lore's rooms in knightlore_data.py and Pentagram's
in pentagram_data.py -- they are not written into a committed file:
build_alien8.py calls data_blocks() on the snapshot at every build, and puts
what it returns into the control file in place of what sna2ctl guessed for
the same bytes. What each table *is* -- its label, its description, its
format -- is prose, and stays in scripts/alien8_annotations.ctl, which is
laid over the top.

Every layout below is the one the game's own code reads (the addresses are in
the comments), and each walk checks itself: a record that does not end where
its length says, or a table that does not tile its range, stops the build
rather than quietly describing something else.

The snapshot is taken at $6300, before the game has run: the game rewrites
some of these tables as it plays (the rooms' colour bits at the start of
every game, #R$CAD2; the sprites turned round in place; the places' second
halves), so what is described here is the tape's image of them.
"""
from __future__ import annotations

NEWLINE = "\n"

FONT = 0x6308               # 43 characters of 8 bytes, codes $30-$5A (#R$BA62)
FONT_CHARS = 43
FONT_FIRST = 0x30
SIZES = 0x6460              # 3 entries of U and V half-sizes and the floor (#R$CCA7)
SIZE_COUNT = 3
ROOMS = 0x6469              # the room directory, searched by #R$CCA7
ROOMS_END = 0x73C8          # ...up to the object template table (the BC it compares with)
OBJECT_TABLE = 0x73C8       # 40 words: two pages of 32 and 8, indexed by header bits 3-7
OBJECT_COUNT = 40
OBJECT_TEMPLATES = 0x7418   # the object templates, 5-byte pieces ended by a zero
BACKGROUND_TABLE = 0x7519   # 14 words, one per background (index = the room's byte)
BACKGROUND_COUNT = 14
BACKGROUNDS = 0x7535        # the backgrounds, 8-byte pieces ended by a zero
PLACES = 0x76E3             # 36 records of 9 bytes (#R$AE99, #R$AF3F)
PLACE_COUNT = 36
PLACE_SIZE = 9
GRAPHICS = 0x7827           # 132 words: graphic number -> sprite
GRAPHIC_COUNT = 132
SPRITES = 0x792F            # the sprites, end to end
SPRITES_END = 0xA631        # the first instruction of the game proper
HANDLERS = 0xA7EA           # 131 words: graphic number -> update routine (#R$A692)
HANDLER_COUNT = 131

INKS = ["black", "blue", "red", "magenta", "green", "cyan", "yellow", "white"]


def _word(memory, address: int) -> int:
    return memory[address] | memory[address + 1] << 8


def _sprite_length(memory, address: int) -> int:
    """A sprite is a width byte (bits 0-3; bits 6 and 7 are the mirrored
    and upside-down flags the drawing code toggles), a height byte, then a
    mask byte and an image byte for each cell of each row."""
    return 2 + (memory[address] & 0x0F) * memory[address + 1] * 2


def sprite_picture_name(address: int) -> str:
    """By address, so this file can name a picture before there is a listing
    to take a label from; build_alien8.py draws it under that name."""
    return f"sprite{address:04x}.png"


def room_size(memory, index: int) -> tuple[int, int, int]:
    base = SIZES + 3 * index
    return memory[base], memory[base + 1], memory[base + 2]


# --------------------------------------------------------------------------
# The rooms.
# --------------------------------------------------------------------------

def room_records(memory) -> list[dict]:
    """Each room record as #R$CCA7 reads it.

    +0 is the room number and +1 the count of bytes from +1 to the end of
    the record; +2 has the size, an index into #R$6460, in bits 6-7, and the
    room's colour in bits 3-5 (copied into bits 0-2 at the start of every
    game by #R$CAD2; on the tape bits 0-2 are clear). Then the backgrounds,
    a byte each, until an $FF; then the object groups, a header (bits 0-2
    the count less one, bits 3-7 the template) and a position byte for each
    copy -- where template 0 is not a template but sets the placement nudge
    from the byte after it, and template 31 moves on to the second page of
    templates and skips the byte after it. Nothing marks the end: the
    builder counts the bytes left in B, and stops when it runs out, even
    partway through a group.
    """
    records = []
    address = ROOMS
    while address < ROOMS_END:
        number, length, attribute = memory[address:address + 3]
        end = address + 1 + length
        record = {"address": address, "number": number, "length": length,
                  "colour": attribute >> 3 & 7, "ink": attribute & 7,
                  "size": attribute >> 6, "end": end,
                  "backgrounds": [], "marker": None, "groups": []}
        left = length - 2                       # #R$CD08: DEC B twice
        part = address + 3
        # Backgrounds (#R$CD0C): a byte each, DJNZ on B.
        while left:
            if memory[part] == 0xFF:
                break
            record["backgrounds"].append((part, memory[part]))
            part += 1
            left -= 1
        if left:
            record["marker"] = part             # the $FF (#R$CD3A: DEC B)
            part += 1
            left -= 1
            # Object groups (#R$CD40): the header costs a byte, and so does
            # each position; B running out ends the record wherever it is.
            while left > 0:
                header = memory[part]
                count = (header & 7) + 1
                template = header >> 3
                left -= 1
                start = part
                part += 1
                if template in (0, 31):
                    # The nudge, or the page: one byte after the header,
                    # whatever the count says (#R$CE00, #R$CDF0).
                    record["groups"].append((start, template, count, [memory[part]]))
                    part += 1
                    left -= 1
                    continue
                positions = []
                while True:
                    positions.append(memory[part])
                    part += 1
                    left -= 1
                    if left == 0 or len(positions) == count:
                        break
                record["groups"].append((start, template, count, positions))
        if part != end:
            raise ValueError(f"room ${number:02X} at ${address:04X} ends at ${part:04X}, "
                             f"not ${end:04X} as its length says")
        records.append(record)
        address = end
    if address != ROOMS_END:
        raise ValueError(f"the room directory runs to ${address:04X}, past ${ROOMS_END:04X}")
    return records


def _cell(position: int) -> str:
    """A position byte as #R$CD81 unpacks it: U in bits 0-2 and V in bits
    3-5, sixteen units a cell from 72; the level (12 units of Z each) in
    bits 6-7."""
    return f"({position & 7},{position >> 3 & 7},{position >> 6})"


def _plural(count: int, word: str) -> str:
    return f"{count} {word}{'' if count == 1 else 's'}"


def _room_lines(memory, records: list[dict]) -> list[str]:
    out = []
    for record in records:
        address, number = record["address"], record["number"]
        u, v, _ = room_size(memory, record["size"])
        title = (f"Room ${number:02X} (row {number >> 4}, column {number & 15}): "
                 f"{2 * u} by {2 * v}, {INKS[record['colour']]}")
        # Each room is an entry of its own, labelled by its number in hex --
        # the rooms are a 16 by 16 grid, as in Knight Lore; the first is also
        # the table's, and the annotations describe the format there.
        out.append(f"@ ${address:04X} label=ROOM{number:02X}")
        out.append(f"b ${address:04X} {title}")
        backgrounds = len(record["backgrounds"])
        copies = sum(len(positions) for _, template, _, positions in record["groups"]
                     if template not in (0, 31))
        groups = sum(1 for _, template, _, _ in record["groups"] if template not in (0, 31))
        out.append(f"D ${address:04X} {_plural(backgrounds, 'background')} and "
                   f"{_plural(copies, 'object')} in {_plural(groups, 'group')}. "
                   f"Positions are cells (U, V, level): U and V 0-7, sixteen units a cell "
                   f"from 72; each level twelve units up from the floor.")
        out.append(f"B ${address:04X},3 Room ${number:02X}; {record['length']} bytes from "
                   f"the next; size {record['size']}, colour {record['colour']}")
        for part, background in record["backgrounds"]:
            out.append(f"B ${part:04X},1 Background {background}")
        if record["marker"] is not None:
            out.append(f"B ${record['marker']:04X},1 End of the backgrounds")
        for start, template, count, positions in record["groups"]:
            if template == 0:
                text = f"Placement nudge ${positions[0]:02X} for the objects that follow"
            elif template == 31:
                text = "Switch to the second page of object templates"
            else:
                text = (f"Object template {template} x{len(positions)}"
                        if len(positions) > 1 else f"Object template {template}")
                text += " at " + ", ".join(_cell(p) for p in positions)
                if len(positions) < count:
                    text += (f" -- the header says {count}, but the record's byte count "
                             f"runs out first")
            out.append(f"B ${start:04X},{1 + len(positions)} {text}")
    return out


def _size_lines(memory) -> list[str]:
    out = []
    for index in range(SIZE_COUNT):
        u, v, z = room_size(memory, index)
        out.append(f"B ${SIZES + 3 * index:04X},3 Size {index}: half-sizes {u} in U and "
                   f"{v} in V; floor at {z}")
    return out


# --------------------------------------------------------------------------
# The templates.
# --------------------------------------------------------------------------

def object_templates(memory) -> dict[int, list[int]]:
    """Where each object template starts, and the indices that reach it."""
    starts: dict[int, list[int]] = {}
    for index in range(OBJECT_COUNT):
        target = _word(memory, OBJECT_TABLE + 2 * index)
        if target:
            starts.setdefault(target, []).append(index)
    return starts


def _template_name(index: int) -> str:
    """Page 1's indices are the header's template numbers; page 2's are the
    same numbers after a template-31 header, written 2:n."""
    return f"{index}" if index < 32 else f"2:{index - 32}"


def _object_lines(memory) -> list[str]:
    """The pointer table, then an entry per template: pieces of graphic, the
    three sizes and the flags, to +0 and +4-+7 of a record (#R$CD62), for as
    long as the byte after a piece is not zero; every piece at the object's
    position."""
    out = []
    for index in range(OBJECT_COUNT):
        target = _word(memory, OBJECT_TABLE + 2 * index)
        name = _template_name(index)
        if target:
            out.append(f"W ${OBJECT_TABLE + 2 * index:04X},2 Template {name}")
        elif index == 0:
            out.append(f"W ${OBJECT_TABLE + 2 * index:04X},2 Template 0: none (a header "
                       f"with template 0 sets the placement nudge)")
        elif index == 31:
            out.append(f"W ${OBJECT_TABLE + 2 * index:04X},2 Template 31: none (a header "
                       f"with template 31 moves on to the second page)")
        else:
            out.append(f"W ${OBJECT_TABLE + 2 * index:04X},2 Template {name}: none (the "
                       f"second page's template 0 is the nudge)")
    starts = object_templates(memory)
    address = OBJECT_TEMPLATES
    while address < BACKGROUND_TABLE:
        if address not in starts:
            raise ValueError(f"nothing points at the object template at ${address:04X}")
        indices = starts[address]
        names = [_template_name(i) for i in indices]
        which = (f"template {names[0]}" if len(names) == 1
                 else "templates " + ", ".join(names))
        # Labelled by the table entry, so the second page's are OBJECT33 on.
        out.append(f"@ ${address:04X} label=OBJECT{indices[0]}")
        pieces = []
        piece = address
        while True:
            pieces.append(piece)
            piece += 5
            if memory[piece] == 0:
                break
        graphics = ", ".join(str(memory[p]) for p in pieces)
        out.append(f"b ${address:04X} Object {which}: graphic{'s' if len(pieces) > 1 else ''} "
                   f"{graphics}")
        for p in pieces:
            graphic, su, sv, sz, flags = memory[p:p + 5]
            out.append(f"B ${p:04X},5 Graphic {graphic}; half-sizes {su}, {sv}, height {sz}; "
                       f"flags ${flags:02X}")
        out.append(f"B ${piece:04X},1 End of the template")
        address = piece + 1
    if address != BACKGROUND_TABLE:
        raise ValueError("the object templates do not end at the background table")
    return out


def backgrounds(memory) -> dict[int, list[int]]:
    starts: dict[int, list[int]] = {}
    for index in range(BACKGROUND_COUNT):
        starts.setdefault(_word(memory, BACKGROUND_TABLE + 2 * index), []).append(index)
    return starts


def _background_lines(memory) -> list[str]:
    """The pointer table, then an entry per background: 8-byte pieces copied
    to +0-+7 of a record (#R$CD20), for as long as the byte after a piece is
    not zero."""
    out = []
    for index in range(BACKGROUND_COUNT):
        out.append(f"W ${BACKGROUND_TABLE + 2 * index:04X},2 Background {index}")
    starts = backgrounds(memory)
    address = BACKGROUNDS
    while address < PLACES:
        if address not in starts:
            raise ValueError(f"nothing points at the background at ${address:04X}")
        indices = starts[address]
        which = (f"background {indices[0]}" if len(indices) == 1
                 else "backgrounds " + ", ".join(str(i) for i in indices))
        out.append(f"@ ${address:04X} label=BACKGROUND{indices[0]}")
        out.append(f"b ${address:04X} {which[0].upper()}{which[1:]}")
        piece = address
        count = 0
        while memory[piece]:
            graphic, u, v, z, su, sv, sz, flags = memory[piece:piece + 8]
            out.append(f"B ${piece:04X},8 Graphic {graphic} at U {u}, V {v}, Z {z}; "
                       f"half-sizes {su}, {sv}, height {sz}; flags ${flags:02X}")
            piece += 8
            count += 1
        out.append(f"D ${address:04X} {_plural(count, 'piece')}.")
        out.append(f"B ${piece:04X},1 End of the background")
        address = piece + 1
    if address != PLACES:
        raise ValueError("the backgrounds do not end at the table of places")
    return out


# --------------------------------------------------------------------------
# The places a valve can lie.
# --------------------------------------------------------------------------

def _place_lines(memory) -> list[str]:
    """Nine bytes each: +0 the graphic, given at every new game (#R$AF3F);
    +1-+4 the starting U, V, Z and room, from the tape; +5-+8 where it is
    now, copied from +1-+4 at a new game and written back when it leaves a
    room (#R$AF05)."""
    out = []
    for number in range(PLACE_COUNT):
        place = PLACES + PLACE_SIZE * number
        graphic, u, v, z, room = memory[place:place + 5]
        out.append(f"B ${place:04X},{PLACE_SIZE},1,4,4 Place {number}: room ${room:02X}, "
                   f"U {u}, V {v}, Z {z}")
    return out


# --------------------------------------------------------------------------
# The graphics.
# --------------------------------------------------------------------------

def sprite_users(memory) -> dict[int, list[int]]:
    """Each sprite's address, and the graphic numbers that draw it."""
    users: dict[int, list[int]] = {}
    for graphic in range(GRAPHIC_COUNT):
        users.setdefault(_word(memory, GRAPHICS + 2 * graphic), []).append(graphic)
    return users


def _numbers(values: list[int]) -> str:
    """1, 2, 3, 5 as '1-3, 5'."""
    runs, start = [], None
    for index, value in enumerate(values):
        if start is None:
            start = value
        if index + 1 == len(values) or values[index + 1] != value + 1:
            runs.append(str(start) if start == value else f"{start}-{value}")
            start = None
    return ", ".join(runs)


def sprite_entries(memory) -> list[tuple[int, int, list[int]]]:
    """(address, length, graphic numbers) for every sprite from #R$792F to
    the code; a sprite no graphic number reaches has an empty list. Checked
    to tile the range exactly."""
    users = sprite_users(memory)
    entries = []
    address = SPRITES
    while address < SPRITES_END:
        length = _sprite_length(memory, address)
        entries.append((address, length, users.get(address, [])))
        address += length
    if address != SPRITES_END:
        raise ValueError(f"the sprites run to ${address:04X}, not ${SPRITES_END:04X}")
    missing = set(users) - {a for a, _, _ in entries}
    if missing:
        raise ValueError(f"graphics point inside a sprite: {sorted(missing)}")
    return entries


def _sprite_lines(memory) -> list[str]:
    out = []
    spare = 0
    for address, length, graphics in sprite_entries(memory):
        width, height = memory[address] & 0x0F, memory[address + 1]
        if graphics:
            label = f"SPRITE{graphics[0]}"
            what = (f"graphic {graphics[0]}" if len(graphics) == 1
                    else f"graphics {_numbers(graphics)}")
            title = f"Sprite for {what}"
        else:
            spare += 1
            label = f"SPARE_SPRITE{'ABCDEFGH'[spare - 1]}"
            title = "Sprite no graphic number reaches"
        out.append(f"@ ${address:04X} label={label}")
        out.append(f"b ${address:04X} {title}")
        if width and height:
            out.append(f'D ${address:04X} #HTML(<img class="a8-sprite" '
                       f'src="../images/sprites/{sprite_picture_name(address)}" '
                       f'alt="The sprite at ${address:04X}">)')
            out.append(f"D ${address:04X} {width * 8} by {height} pixels.")
            out.append(f"B ${address:04X},2 Width in bytes, and height in rows")
            out.append(f"B ${address + 2:04X},{length - 2},{2 * width} Mask and image "
                       f"bytes, a pair per cell, the bottom row first")
        else:
            out.append(f"D ${address:04X} Width and height both zero: the drawing code "
                       f"sees the zero and draws nothing.")
            out.append(f"B ${address:04X},2 Width and height")
    return out


def _graphic_lines(memory) -> list[str]:
    return [f"W ${GRAPHICS + 2 * graphic:04X},2 Graphic {graphic}"
            for graphic in range(GRAPHIC_COUNT)]


def _handler_lines(memory) -> list[str]:
    return [f"W ${HANDLERS + 2 * graphic:04X},2 Graphic {graphic}"
            for graphic in range(HANDLER_COUNT)]


FONT_ATTR = 0x47            # bright white on black


def _font_lines(memory) -> list[str]:
    # #FONT counts characters from a space, so its base is the address a
    # space would have: 16 characters before '0'.
    base = FONT - 8 * (FONT_FIRST - 0x20)
    text = "".join(chr(FONT_FIRST + i) for i in range(FONT_CHARS))
    out = [f"D ${FONT:04X} #HTML(#FONT${base:04X},0,{FONT_ATTR},3({text})(font))"]
    for index in range(FONT_CHARS):
        code = FONT_FIRST + index
        name = chr(code) if chr(code).isalnum() else f"${code:02X}"
        out.append(f"B ${FONT + 8 * index:04X},8,1 Character {name}")
    return out


# --------------------------------------------------------------------------
# Together.
# --------------------------------------------------------------------------

# The ranges the generated lines describe completely: build_alien8.py drops
# whatever sna2ctl put inside them. (start, end), end exclusive.
OWNED = [(FONT, SIZES), (SIZES, ROOMS), (ROOMS, ROOMS_END),
         (OBJECT_TABLE, BACKGROUND_TABLE), (BACKGROUND_TABLE, PLACES),
         (PLACES, GRAPHICS), (GRAPHICS, SPRITES), (SPRITES, SPRITES_END),
         (HANDLERS, HANDLERS + 2 * HANDLER_COUNT)]


def data_blocks(memory) -> str:
    """The control-file lines for every table above, in address order."""
    records = room_records(memory)
    lines = ["; Generated by scripts/alien8_data.py from the snapshot -- do not edit.", ""]
    lines += [f"@ ${FONT:04X} label=FONT", f"b ${FONT:04X} The font"]
    lines += _font_lines(memory) + [""]
    lines += [f"@ ${SIZES:04X} label=ROOM_SIZES", f"b ${SIZES:04X} Room sizes"]
    lines += _size_lines(memory) + [""]
    lines += _room_lines(memory, records) + [""]
    lines += [f"@ ${OBJECT_TABLE:04X} label=OBJECT_TABLE",
              f"b ${OBJECT_TABLE:04X} Object template table"]
    lines += _object_lines(memory) + [""]
    lines += [f"@ ${BACKGROUND_TABLE:04X} label=BACKGROUND_TABLE",
              f"b ${BACKGROUND_TABLE:04X} Background table"]
    lines += _background_lines(memory) + [""]
    lines += [f"@ ${PLACES:04X} label=PLACES", f"b ${PLACES:04X} Where the valves can lie"]
    lines += _place_lines(memory) + [""]
    lines += [f"@ ${GRAPHICS:04X} label=GRAPHICS", f"b ${GRAPHICS:04X} Graphic table"]
    lines += _graphic_lines(memory) + [""]
    lines += _sprite_lines(memory) + [""]
    lines += [f"@ ${HANDLERS:04X} label=UPDATES", f"w ${HANDLERS:04X} Update routines, by graphic"]
    lines += _handler_lines(memory) + [""]
    return NEWLINE.join(lines) + NEWLINE


def picture_sprites(memory) -> list[int]:
    """The sprites that get a picture: every one with a width and a height."""
    return [address for address, _, _ in sprite_entries(memory)
            if memory[address] & 0x0F and memory[address + 1]]
