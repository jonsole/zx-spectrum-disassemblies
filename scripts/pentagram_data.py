"""Pentagram's level data and graphics, laid out a record per line from the game.

The room directory, the scenery and object templates, the graphic table, the
sprites and the font are the game's own design. Described record by record
they are that design again in other words, so -- like Knight Lore's rooms in
knightlore_data.py -- they are not written into a committed file:
build_pentagram.py calls data_blocks() on the snapshot at every build, and
puts what it returns into the control file in place of what sna2ctl guessed
for the same bytes. What each table *is* -- its label, its description, its
format -- is prose, and stays in scripts/pentagram_annotations.ctl, which is
laid over the top.

Every layout below is the one the game's own code reads (the addresses are in
the comments), and each walk checks itself: a record that does not end where
its length says, or a table that does not tile its range, stops the build
rather than quietly describing something else.
"""
from __future__ import annotations

NEWLINE = "\n"

SIZES = 0x5E07              # 3 entries of U, V and Z extents
ROOMS = 0x5E10              # the room directory, searched by #R$C92F
ROOMS_END = 0x696D          # ...up to the scenery template table (the BC it compares with)
SCENERY_TABLE = 0x696D      # 32 words, one per scenery template (index = the entry's first byte)
SCENERY_COUNT = 32
OBJECT_TABLE = 0x6CE5       # 31 words, one per object template (index = header bits 3-7)
OBJECT_COUNT = 31
OBJECT_TEMPLATES = 0x6D23   # the object templates, 6 bytes each
GRAPHICS = 0x6DD7           # 172 words: graphic number -> sprite (#R$B2EE)
GRAPHIC_COUNT = 172
SPRITES = 0x6F2F            # the sprites, end to end, with the font among them
SPRITES_END = 0xA709        # the first of the game's variables
FONT = 0x8355               # 43 characters of 8 bytes, codes $30-$5A
FONT_CHARS = 43
FONT_FIRST = 0x30
HANDLERS = 0xAE2F           # 172 words: graphic number -> update routine (#R$AFE1)
# Bytes among the sprites that are not one: eight after the spider sprite,
# which no graphic number and no code reaches, before the next sprite.
NOT_SPRITES = {0x853F: 8}

INKS = ["black", "blue", "red", "magenta", "green", "cyan", "yellow", "white"]
SIDES = ["north", "east", "south", "west"]


def _word(memory, address: int) -> int:
    return memory[address] | memory[address + 1] << 8


def _sprite_length(memory, address: int) -> int:
    """A sprite is a width byte (bits 0-3, as #R$B2EE masks it; bits 6 and 7
    are flags), a height byte, then a mask byte and an image byte for each
    cell of each row."""
    return 2 + (memory[address] & 0x0F) * memory[address + 1] * 2


def sprite_picture_name(address: int) -> str:
    """By address, so this file can name a picture before there is a listing
    to take a label from; build_pentagram.py draws it under that name."""
    return f"sprite{address:04x}.png"


def room_size(memory, index: int) -> tuple[int, int, int]:
    base = SIZES + 3 * index
    return memory[base], memory[base + 1], memory[base + 2]


# --------------------------------------------------------------------------
# The rooms.
# --------------------------------------------------------------------------

def room_records(memory) -> list[dict]:
    """Each room record as #R$C92F reads it.

    +0 is the room number and +1 the count of bytes that follow it; +2 has
    the room's ink in bits 0-2 and its size, an index into #R$5E07, in bits
    3-7. Then the scenery, two bytes an entry -- a template number and the
    room a doorway leads to -- until an $FF; then the object groups, a header
    (bits 0-2 the count less one, bits 3-7 the template) and a position byte
    for each copy. Nothing marks the end: the builder counts the bytes left in
    B, and stops when it runs out, even partway through a group.
    """
    records = []
    address = ROOMS
    while address < ROOMS_END:
        number, length, attribute = memory[address:address + 3]
        end = address + 1 + length
        record = {"address": address, "number": number, "length": length,
                  "ink": attribute & 7, "size": attribute >> 3, "end": end,
                  "scenery": [], "marker": None, "groups": []}
        left = length - 2                       # $C97D: DEC B twice
        part = address + 3
        # Scenery (#R$C981): a template and a destination, B down by two.
        while left:
            if memory[part] == 0xFF:
                break
            record["scenery"].append((part, memory[part], memory[part + 1]))
            part += 2
            left -= 2
        if left:
            record["marker"] = part             # the $FF (#R$C9B6: DEC B)
            part += 1
            left -= 1
            # Object groups (#R$C9BC): the header costs a byte, and so does
            # each position; B running out ends the record wherever it is.
            while left > 0:
                header = memory[part]
                count = (header & 7) + 1
                template = header >> 3
                left -= 1
                positions = []
                start = part
                part += 1
                while True:
                    positions.append(memory[part])
                    part += 1
                    left -= 1
                    if left == 0 or len(positions) == count:
                        break
                record["groups"].append((start, template, count, positions))
        if part != end:
            raise ValueError(f"room {number} at ${address:04X} ends at ${part:04X}, "
                             f"not ${end:04X} as its length says")
        records.append(record)
        address = end
    if address != ROOMS_END:
        raise ValueError(f"the room directory runs to ${address:04X}, past ${ROOMS_END:04X}")
    return records


def _cell(position: int) -> str:
    """A position byte as #R$C9DB unpacks it: U in bits 0-2, V in bits 3-5,
    the level (12 units of Z each) in bits 6-7."""
    return f"({position & 7},{position >> 3 & 7},{position >> 6})"


# The scenery templates that are doorways: three sets of four, one for each
# wall (template AND 3: 0 north, 1 east, 2 south, 3 west). A doorway's second
# byte is the room it leads to -- which can be 0, so it is the template, not
# the byte, that says a piece is a doorway (room 147's south doorway leads to
# room 0; the world page walks the player through every one).
DOORWAY_TEMPLATES = set(range(8)) | {24, 25, 26, 27}


def _room_lines(memory, records: list[dict]) -> list[str]:
    out = []
    for record in records:
        address, number = record["address"], record["number"]
        u, v, z = room_size(memory, record["size"])
        exits = [destination for _, template, destination in record["scenery"]
                 if template in DOORWAY_TEMPLATES]
        # The size table holds half-sizes about the room's centre.
        title = (f"Room {number}: {2 * u} by {2 * v}, {INKS[record['ink']]}"
                 + (f"; doorways to {', '.join(str(d) for d in exits)}" if exits else ""))
        # Each room is an entry of its own, labelled by its number; the first
        # is also the table's, and the annotations describe the format there.
        out.append(f"@ ${address:04X} label=ROOM{number}")
        out.append(f"b ${address:04X} {title}")
        pieces = len(record["scenery"])
        copies = sum(len(positions) for _, _, _, positions in record["groups"])
        out.append(f"D ${address:04X} {pieces} piece{'s' if pieces != 1 else ''} of scenery "
                   f"and {copies} object{'s' if copies != 1 else ''} in "
                   f"{len(record['groups'])} group{'s' if len(record['groups']) != 1 else ''}. "
                   f"Positions are cells (U, V, level): U and V 0-7, sixteen units a cell "
                   f"from 72; each level twelve units up from the floor.")
        out.append(f"B ${address:04X},3 Room {number}; {record['length']} bytes follow; "
                   f"ink {record['ink']}, size {record['size']}")
        for part, template, destination in record["scenery"]:
            text = f"Scenery template {template}"
            if template in DOORWAY_TEMPLATES:
                text += f": a doorway to room {destination}"
            out.append(f"B ${part:04X},2 {text}")
        if record["marker"] is not None:
            out.append(f"B ${record['marker']:04X},1 End of the scenery")
        for start, template, count, positions in record["groups"]:
            if template == 31:
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


# --------------------------------------------------------------------------
# The templates.
# --------------------------------------------------------------------------

def scenery_templates(memory) -> dict[int, list[int]]:
    """Where each scenery template starts, and the indices that reach it."""
    starts: dict[int, list[int]] = {}
    for index in range(SCENERY_COUNT):
        starts.setdefault(_word(memory, SCENERY_TABLE + 2 * index), []).append(index)
    return starts


def _scenery_lines(memory) -> list[str]:
    """The pointer table, then an entry per template: 8-byte pieces copied to
    +0-+7 of a record (#R$C995), for as long as the byte after a piece is not
    zero -- so a template with no zero after it runs on into the next."""
    out = []
    starts = scenery_templates(memory)
    for index in range(SCENERY_COUNT):
        target = _word(memory, SCENERY_TABLE + 2 * index)
        note = " (the table itself: not a template)" if target == SCENERY_TABLE else ""
        out.append(f"W ${SCENERY_TABLE + 2 * index:04X},2 Template {index}{note}")
    templates = sorted(a for a in starts if a != SCENERY_TABLE)
    if templates[0] != SCENERY_TABLE + 2 * SCENERY_COUNT:
        raise ValueError("the scenery templates do not start straight after their table")
    for number, start in enumerate(templates):
        end = templates[number + 1] if number + 1 < len(templates) else OBJECT_TABLE
        indices = starts[start]
        label = f"SCENERY{indices[0]}"
        which = (f"template {indices[0]}" if len(indices) == 1
                 else "templates " + ", ".join(str(i) for i in indices))
        out.append(f"@ ${start:04X} label={label}")
        out.append(f"b ${start:04X} Scenery {which}")
        piece = start
        count = 0
        while piece + 8 <= end:
            graphic, u, v, z, su, sv, sz, flags = memory[piece:piece + 8]
            out.append(f"B ${piece:04X},8 Graphic {graphic} at U {u}, V {v}, Z {z}; "
                       f"half-sizes {su}, {sv}, height {sz}; flags ${flags:02X}")
            count += 1
            piece += 8
            if piece < end and memory[piece] == 0:
                break
        if piece == end:
            out.append(f"D ${start:04X} {count} piece{'s' if count != 1 else ''}, and no "
                       f"zero after the last: #R$C92C's piece loop reads on into the next template's.")
        elif piece + 1 == end and memory[piece] == 0:
            out.append(f"D ${start:04X} {count} piece{'s' if count != 1 else ''}.")
            out.append(f"B ${piece:04X},1 End of the template")
        else:
            raise ValueError(f"scenery template at ${start:04X} does not tile to ${end:04X}")
    return out


def object_templates(memory) -> dict[int, list[int]]:
    starts: dict[int, list[int]] = {}
    for index in range(OBJECT_COUNT):
        starts.setdefault(_word(memory, OBJECT_TABLE + 2 * index), []).append(index)
    return starts


def _object_lines(memory) -> list[str]:
    """The pointer table, then an entry per template: graphic, the three
    sizes and the flags, to +0 and +4-+7 of a record (#R$C9DB), and a zero
    graphic where another part would begin (#R$CA51)."""
    out = []
    for index in range(OBJECT_COUNT):
        out.append(f"W ${OBJECT_TABLE + 2 * index:04X},2 Template {index}")
    starts = object_templates(memory)
    address = OBJECT_TEMPLATES
    while address < GRAPHICS:
        if address not in starts:
            raise ValueError(f"nothing points at the object template at ${address:04X}")
        indices = starts[address]
        which = (f"template {indices[0]}" if len(indices) == 1
                 else "templates " + ", ".join(str(i) for i in indices))
        graphic, su, sv, sz, flags, end = memory[address:address + 6]
        if end:
            raise ValueError(f"object template at ${address:04X} has more than one part")
        out.append(f"@ ${address:04X} label=OBJECT{indices[0]}")
        out.append(f"b ${address:04X} Object {which}: graphic {graphic}")
        out.append(f"B ${address:04X},5 Graphic {graphic}; half-sizes {su}, {sv}, height {sz}; "
                   f"flags ${flags:02X}")
        out.append(f"B ${address + 5:04X},1 End of the template")
        address += 6
    if address != GRAPHICS:
        raise ValueError("the object templates do not end at the graphic table")
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
    """(address, length, graphic numbers) for every sprite from #R$6F2F to
    the variables, the font skipped; a sprite no graphic number reaches has
    an empty list. Checked to tile the range exactly."""
    users = sprite_users(memory)
    entries = []
    address = SPRITES
    while address < SPRITES_END:
        if address == FONT:
            address += 8 * FONT_CHARS
            continue
        length = NOT_SPRITES.get(address) or _sprite_length(memory, address)
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
            title = "Sprite no graphic number reaches" if length > 8 else "Unused"
        out.append(f"@ ${address:04X} label={label}")
        out.append(f"b ${address:04X} {title}")
        if width and height:
            out.append(f'D ${address:04X} #HTML(<img class="pg-sprite" '
                       f'src="../images/sprites/{sprite_picture_name(address)}" '
                       f'alt="The sprite at ${address:04X}">)')
            out.append(f"D ${address:04X} {width * 8} by {height} pixels.")
            out.append(f"B ${address:04X},2 Width in bytes, and height in rows")
            out.append(f"B ${address + 2:04X},{length - 2},{2 * width} Mask and image "
                       f"bytes, a pair per cell, the bottom row first")
        elif length == 2:
            out.append(f"D ${address:04X} Width and height both zero: #R$B2EE sees the "
                       f"zero and draws nothing.")
            out.append(f"B ${address:04X},2 Width and height")
        else:
            out.append(f"B ${address:04X},{length}")
    return out


def _graphic_lines(memory) -> list[str]:
    return [f"W ${GRAPHICS + 2 * graphic:04X},2 Graphic {graphic}"
            for graphic in range(GRAPHIC_COUNT)]


def _handler_lines(memory) -> list[str]:
    return [f"W ${HANDLERS + 2 * graphic:04X},2 Graphic {graphic}"
            for graphic in range(GRAPHIC_COUNT)]


FONT_ATTR = 0x46            # bright yellow on black, as the panel prints


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
# The quest's things: where they start, and where they go.
# --------------------------------------------------------------------------

QUEST_START = 0xD312        # 18 records of 16 bytes, copied to $D432 at a new game (#R$D16F)
QUEST_COUNT = 18
QUEST_SIZE = 16
SPOTS = 0xD1A5              # 20 places a collectable can start: room, U, V, Z
SPOT_COUNT = 20
TARGETS = 0xD562            # where each collectable settles in room 82: U, V
TARGET_COUNT = 5
# What each record is, by number: the quest's order, not the game's text.
QUEST_KINDS = (["quest item"] * 4 + ["collectable"] * 5 + ["piece of the pentagram"] * 8
               + ["the bucket"])


def _quest_lines(memory) -> list[str]:
    out = []
    for number in range(QUEST_COUNT):
        record = QUEST_START + QUEST_SIZE * number
        graphic, u, v, z, su, sv, sz, flags, room = memory[record:record + 9]
        kind = QUEST_KINDS[number]
        if graphic:
            text = (f"Record {number}, {kind}: graphic {graphic} at U {u}, V {v}, Z {z} "
                    f"in room {room}; half-sizes {su}, {sv}, height {sz}; flags ${flags:02X}")
        else:
            text = f"Record {number}, {kind}: empty until the well gives one"
        out.append(f"B ${record:04X},{QUEST_SIZE},8 {text}")
    return out


def _spot_lines(memory) -> list[str]:
    out = []
    for number in range(SPOT_COUNT):
        spot = SPOTS + 4 * number
        room, u, v, z = memory[spot:spot + 4]
        out.append(f"B ${spot:04X},4 Spot {number}: room {room}, U {u}, V {v}, Z {z}")
    return out


def _target_lines(memory) -> list[str]:
    out = []
    for index in range(TARGET_COUNT):
        target = TARGETS + 2 * index
        out.append(f"B ${target:04X},2 Graphic {144 + index}: U {memory[target]}, "
                   f"V {memory[target + 1]}")
    return out


# --------------------------------------------------------------------------
# Together.
# --------------------------------------------------------------------------

# The ranges the generated lines describe completely: build_pentagram.py
# drops whatever sna2ctl put inside them. (start, end), end exclusive.
OWNED = [(ROOMS, ROOMS_END), (SCENERY_TABLE, OBJECT_TABLE), (OBJECT_TABLE, GRAPHICS),
         (GRAPHICS, SPRITES), (SPRITES, SPRITES_END), (HANDLERS, HANDLERS + 2 * GRAPHIC_COUNT),
         (SPOTS, SPOTS + 4 * SPOT_COUNT),
         (QUEST_START, QUEST_START + QUEST_SIZE * QUEST_COUNT),
         (TARGETS, TARGETS + 2 * TARGET_COUNT)]


def data_blocks(memory) -> str:
    """The control-file lines for every table above, in address order."""
    records = room_records(memory)
    lines = ["; Generated by scripts/pentagram_data.py from the snapshot -- do not edit.", ""]
    lines += _room_lines(memory, records) + [""]
    lines += [f"b ${SCENERY_TABLE:04X} Scenery template table"]
    lines += _scenery_lines(memory) + [""]
    lines += [f"b ${OBJECT_TABLE:04X} Object template table"]
    lines += _object_lines(memory) + [""]
    lines += [f"b ${GRAPHICS:04X} Graphic table"]
    lines += _graphic_lines(memory) + [""]
    sprites = _sprite_lines(memory)
    # The font sits among the sprites, after the one that ends at $8355.
    font_at = next(i for i, line in enumerate(sprites)
                   if line.startswith("@ $") and int(line[3:7], 16) > FONT)
    lines += sprites[:font_at] + [f"@ ${FONT:04X} label=FONT", f"b ${FONT:04X} The font"]
    lines += _font_lines(memory) + sprites[font_at:] + [""]
    lines += [f"w ${HANDLERS:04X} Update routines, by graphic"]
    lines += _handler_lines(memory) + [""]
    lines += [f"b ${SPOTS:04X} Where the collectables can start"]
    lines += _spot_lines(memory) + [""]
    lines += [f"b ${QUEST_START:04X} The quest's things, as a game starts"]
    lines += _quest_lines(memory) + [""]
    lines += [f"b ${TARGETS:04X} Where the collectables settle in room 82"]
    lines += _target_lines(memory) + [""]
    return NEWLINE.join(lines) + NEWLINE


def picture_sprites(memory) -> list[int]:
    """The sprites that get a picture: every one with a width and a height."""
    return [address for address, _, _ in sprite_entries(memory)
            if memory[address] & 0x0F and memory[address + 1]]
