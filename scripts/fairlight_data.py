"""Fairlight's level data and graphics, laid out a record per line from the game.

The rooms and the shared pieces they are drawn from, the objects in the rooms,
the object templates, the textures, the font, the sprites and the game's text
are the game's design. Described record by record they are that design again
in other words, so -- like Nightshade's in nightshade_data.py -- they are not
written into a committed file: build_fairlight.py calls data_blocks() on the
snapshot at every build, and puts what it returns into the control file in
place of what sna2ctl guessed for the same bytes. What each table *is* -- its
label, its description, its format -- is prose, and stays in
scripts/fairlight_annotations.ctl, which is laid over the top.

Every layout below is the one the game's own code reads (the routines are
named in the comments), and each walk checks itself: a room whose commands do
not end on its length, a table that does not tile its range, a pointer into
the middle of a record, stops the build rather than quietly describing
something else.

Two things are particular to Fairlight:

- The snapshot is the tape, stopped where the loader hands over ($C47C).
  Release 2's start-up then copies two blocks into place: $C4E0-$D23B to
  $A924 (the object table among them) and $D2F0-$D693 to $B734 (the object
  templates). The code reads them at $A924 and $B734; the listing lays them
  out where the tape has them, and says where each goes.
- Which sprites there are is not in any one table. The object templates
  point at some; the rest are chosen by code as things animate. The build
  records the sprite every object shows at each point the sessions stop
  (Machine.note_sprites in build_fairlight.py), and data_blocks() is given that
  list together with the templates'. Frames between two seen frames of the
  same size, where the gap is a whole number of frames, are laid out as
  frames too, and say that they were not seen.
"""
from __future__ import annotations

NEWLINE = "\n"

# Each address is where the code named beside it reads the table (and, for
# the tables the start-up moves, where the tape has it).
ROOMS = 0x68B0              # 81 rooms: a length word, then the room (#R$E55B)
ROOM_COUNT = 81
PARTS = 0x758C              # 56 parts rooms are drawn from (#R$EA1D, through $FFB5)
PART_COUNT = 56
PARTS_END = 0x7CCB
PRINT = 0xEBFE              # prints the string after its own CALL
STRING_END = 0xA4
STRING_AT = 0xC8            # followed by an x and a y
GLYPHS = 0xBAD8             # 40 characters of 8 bytes (#R$EC35)
GLYPH_COUNT = 40
TEXTURES = 0xE0A4           # 26 textures of 32 bytes, fill codes $E6-$FF (#R$E70D)
TEXTURE_COUNT = 26
ROOM_DEFAULTS = 0xE582      # 20 bytes copied to $FFDF at a room's start (#R$E55B)
# The start-up's copies (#R$C47C): (tape, runtime, length).
OBJECTS_TAPE, OBJECTS_HOME, OBJECTS_COPY = 0xC4E0, 0xA924, 0x0D5C
TEMPLATES_TAPE, TEMPLATES_HOME, TEMPLATES_COPY = 0xD2F0, 0xB734, 0x03A4
SMALL_HOME, SMALL_SIZE, SMALL_COUNT = 0xB734, 11, 57    # types 0-$38 (#R$EB1A)
LARGE_HOME, LARGE_SIZE, LARGE_FIRST, LARGE_COUNT = 0xB9AA, 9, 0x46, 15   # types $46-$54
PATCHES_HOME, PATCH_SIZE, PATCH_FIRST = 0xBA3E, 6, 0xE5  # op $E6 is entry 1 (#R$E605)
# The development assembler's symbol table, left in the tape's image: nodes
# of a tree, each a left and a right link, a byte 1, the name (bit 7 set on
# its last letter) and the value.
SYMBOLS = 0xDD39
SYMBOLS_END = 0xDFF2
# The sprites: a width in pixels and a height come from the object's record;
# the image, a row at a time, then a mask of the same size (#R$EE8D).
SPRITE_AREAS = [(0x5B00, 0x617C), (0x7D00, 0xA91E)]

INKS = ["black", "blue", "red", "magenta", "green", "cyan", "yellow", "white"]


def _word(memory, address: int) -> int:
    return memory[address] | memory[address + 1] << 8


def tape_address(runtime: int) -> int:
    """Where the tape has a byte the start-up copies to `runtime`."""
    if OBJECTS_HOME <= runtime < OBJECTS_HOME + OBJECTS_COPY:
        return runtime - OBJECTS_HOME + OBJECTS_TAPE
    if TEMPLATES_HOME <= runtime < TEMPLATES_HOME + TEMPLATES_COPY:
        return runtime - TEMPLATES_HOME + TEMPLATES_TAPE
    return runtime


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


# --------------------------------------------------------------------------
# Text.
# --------------------------------------------------------------------------

def glyph_text(code: int) -> str:
    """A character of the font as the game's text uses it: 0 a space, 1-26
    the letters, 27-36 the digits, 37 a full stop and 38 a dash. What 39 is
    was drawn (#R$BAD8's picture) rather than guessed."""
    if code == 0:
        return " "
    if 1 <= code <= 26:
        return chr(0x40 + code)
    if 27 <= code <= 36:
        return chr(0x30 + code - 27)
    return {37: ".", 38: "-"}.get(code, f"[{code}]")


def inline_strings(memory, start: int = 0x5B00, end: int = 0x10000) -> list[tuple[int, int, int]]:
    """(call, first byte, end) for every CALL to the printer followed by a
    string it would print: bytes up to and including $A4, $C8 taking two
    more. The printer (#R$EBFE) takes its return address as the string and
    returns past it. A byte pattern that looks like such a CALL in data may
    be found too; the build checks that no string it finds ever ran as
    code, and lays out only those whose CALL is code."""
    out = []
    for address in range(start, end - 3):
        if memory[address] == 0xCD and _word(memory, address + 1) == PRINT:
            at = address + 3
            while at < end and memory[at] != STRING_END:
                at += 3 if memory[at] == STRING_AT else 1
            if at < end:
                out.append((address, address + 3, at + 1))
    return out


def string_pieces(memory, start: int, end: int) -> list[tuple[int, int, str]]:
    """A string as (address, length, what): each run of characters, each
    move of the print position, and the end."""
    pieces, at, text, text_at = [], start, "", start
    def flush():
        if text:
            pieces.append((text_at, len(text), f'"{text}"'))
    while at < end:
        code = memory[at]
        if code == STRING_AT:
            flush()
            text = ""
            pieces.append((at, 3, f"Print at x {memory[at + 1]}, y {memory[at + 2]}"))
            at += 3
            text_at = at
        elif code == STRING_END:
            flush()
            text = ""
            pieces.append((at, 1, "End of the string"))
            at += 1
        else:
            if not text:
                text_at = at
            text += glyph_text(code)
            at += 1
    return pieces


def _string_lines(memory, code: set[int]) -> tuple[list[str], list[tuple[int, int]]]:
    lines, ranges = [], []
    for call, start, end in inline_strings(memory):
        if call not in code:
            continue
        for address, length, what in string_pieces(memory, start, end):
            lines.append(f"B ${address:04X},{length},{min(length, 8)} {what}")
        # The code goes on after the string, in the same routine.
        lines.append(f"C ${end:04X}")
        ranges.append((start, end))
    return lines, ranges


def _glyph_lines(memory) -> list[str]:
    out = [f"@ ${GLYPHS:04X} label=FONT",
           f"b ${GLYPHS:04X} The font",
           f"D ${GLYPHS:04X} #HTML(#UDGARRAY{GLYPH_COUNT // 2},$47,3(${GLYPHS:04X}-"
           f"${GLYPHS + 8 * (GLYPH_COUNT - 1):04X}-8)(font))",
           f"D ${GLYPHS:04X} The game's text is in these characters' numbers, not in ASCII: "
           f"0 a space, 1-26 the letters, 27-36 the digits, 37 a full stop and 38 a dash. "
           f"#R$EBFE prints them."]
    for code in range(GLYPH_COUNT):
        shown = glyph_text(code)
        name = "space" if code == 0 else (shown if len(shown) == 1 else "not a letter")
        out.append(f"B ${GLYPHS + 8 * code:04X},8,8 Character {code}: {name}")
    return out


# --------------------------------------------------------------------------
# Rooms and parts.
# --------------------------------------------------------------------------

# The mode byte's bits (at $FFEB, IY+$6B), set and cleared by the codes
# $C1-$CE (#R$E941).
FLAG_SET = {0xCB: 0, 0xCD: 1, 0xC3: 2, 0xC5: 3, 0xC1: 4, 0xC7: 5, 0xC9: 6}
FLAG_CLEAR = {0xCC: 0, 0xCE: 1, 0xC4: 2, 0xC6: 3, 0xC2: 4, 0xC8: 5, 0xCA: 6}


def room_commands(memory, start: int, end: int) -> list[tuple[int, int, str]]:
    """A room's or a part's drawing commands, from `start` to its $E5, as
    (address, length, what) -- the lengths the interpreter (#R$E5A6,
    #R$E5E8) takes. After $E4 $04 the rest of the stream is objects: five
    bytes each below $E4, one byte (a patch, #R$E605) above $E5."""
    out, at, objects = [], start, False
    while True:
        if at >= end:
            raise ValueError(f"the room commands from ${start:04X} run past ${end:04X}")
        op = memory[at]
        if op == 0xE5:
            out.append((at, 1, "End"))
            if at + 1 != end:
                raise ValueError(f"the room commands from ${start:04X} end at ${at:04X}, "
                                 f"short of ${end:04X}")
            return out
        if objects:
            if op < 0xE4:
                out.append((at, 5, f"Object: type {op}; +12 value {memory[at + 1]}, along "
                                   f"{memory[at + 2]}, top {memory[at + 3]}, across {memory[at + 4]}"))
                at += 5
            elif op == 0xE4:
                out.append((at, 1, "$E4: nothing, in object mode"))
                at += 1
            else:
                out.append((at, 1, f"Patch {op - PATCH_FIRST}"))
                at += 1
            continue
        if op < 0xC0:
            out.append((at, 2, f"Point: row {op}, column {memory[at + 1]}"))
            at += 2
        elif op == 0xC0:
            out.append((at, 3, f"Second point: row {memory[at + 1]}, column {memory[at + 2]}"))
            at += 3
        elif op in FLAG_SET:
            out.append((at, 1, f"Mode bit {FLAG_SET[op]} on"))
            at += 1
        elif op in FLAG_CLEAR:
            out.append((at, 1, f"Mode bit {FLAG_CLEAR[op]} off"))
            at += 1
        elif op == 0xCF:
            out.append((at, 1, "Second point to the first"))
            at += 1
        elif op == 0xD0:
            out.append((at, 1, "Swap the points"))
            at += 1
        elif op == 0xD2:
            out.append((at, 1, "Line between the points"))
            at += 1
        elif op == 0xD5:
            out.append((at, 2, f"Repeat what follows {memory[at + 1]} times"))
            at += 2
        elif op == 0xD6:
            out.append((at, 1, "End of the repeat"))
            at += 1
        elif op in (0xE0, 0xE1):
            part = memory[at + 1]
            keep = ", keeping the points" if op == 0xE1 else ""
            out.append((at, 2, f"Part {part} (#R${part_address(memory, part):04X}){keep}"))
            at += 2
        elif op == 0xE2:
            out.append((at, 1, "Keep a clean copy of the screen"))
            at += 1
        elif op == 0xE4:
            sub = memory[at + 1]
            if sub == 5:
                out.append((at, 5, f"$E4 $05: origin {memory[at + 2]}, {memory[at + 3]}, "
                                   f"{memory[at + 4]}"))
                at += 5
            else:
                # $00 and $01 send the lines that follow into the clean copy (so
                # they bound a fill without being drawn) and back to the screen
                # (range 2's reading of #R$E89B, measured in room 2).
                what = {0: "$E4 $00: clean copy cleared; lines go into it",
                        1: "$E4 $01: lines onto the screen again",
                        4: "Objects follow"}.get(sub, f"$E4 ${sub:02X}")
                out.append((at, 2, what))
                objects = objects or sub == 4
                at += 2
        elif op >= 0xE6:
            out.append((at, 1, f"Fill with texture {op - 0xE6} "
                               f"(#R${TEXTURES + 32 * (op - 0xE6):04X})"))
            at += 1
        else:
            out.append((at, 1, f"${op:02X}: nothing"))
            at += 1


def _stream_records(memory, base: int, count: int) -> list[tuple[int, int]]:
    """(address, length) of each record of a room or parts table."""
    out, address = [], base
    for _ in range(count):
        length = _word(memory, address)
        if length < 3:
            raise ValueError(f"a record at ${address:04X} is {length} bytes long")
        out.append((address, length))
        address += length
    return out


def part_address(memory, part: int) -> int:
    records = _stream_records(memory, PARTS, PART_COUNT)
    if not 1 <= part <= len(records):
        raise ValueError(f"a room draws part {part}, and there are {len(records)}")
    return records[part - 1][0]


def room_address(memory, room: int) -> int:
    return _stream_records(memory, ROOMS, ROOM_COUNT)[room - 1][0]


def _attribute(value: int) -> str:
    return (f"{'bright ' if value & 0x40 else ''}{INKS[value & 7]} on "
            f"{INKS[value >> 3 & 7]}")


def _room_lines(memory) -> list[str]:
    out = []
    records = _stream_records(memory, ROOMS, ROOM_COUNT)
    if records[-1][0] + records[-1][1] != PARTS:
        raise ValueError("the rooms do not end where the parts begin")
    for room, (address, length) in enumerate(records, 1):
        out.append(f"@ ${address:04X} label=ROOM{room}")
        out.append(f"b ${address:04X} Room {room}")
        out.append(f"B ${address:04X},2,2 Length: {length} bytes")
        out.append(f"B ${address + 2:04X},1,1 Colour: {_attribute(memory[address + 2])}")
        for at, n, what in room_commands(memory, address + 3, address + length):
            out.append(f"B ${at:04X},{n},{n} {what}")
    return out


def _part_lines(memory) -> list[str]:
    out = []
    records = _stream_records(memory, PARTS, PART_COUNT)
    if records[-1][0] + records[-1][1] != PARTS_END:
        raise ValueError("the parts do not end where expected")
    used = set()
    for base, count in ((ROOMS, ROOM_COUNT), (PARTS, PART_COUNT)):
        for address, length in _stream_records(memory, base, count):
            first = address + (3 if base == ROOMS else 2)
            for at, n, what in room_commands(memory, first, address + length):
                if memory[at] in (0xE0, 0xE1) and what.startswith("Part"):
                    used.add(memory[at + 1])
    for part, (address, length) in enumerate(records, 1):
        out.append(f"@ ${address:04X} label=PART{part}")
        out.append(f"b ${address:04X} Part {part}" + ("" if part in used else
                                                      " (no room draws it)"))
        out.append(f"B ${address:04X},2,2 Length: {length} bytes")
        for at, n, what in room_commands(memory, address + 2, address + length):
            out.append(f"B ${at:04X},{n},{n} {what}")
    return out


# --------------------------------------------------------------------------
# Objects: the table of what is in each room, and the templates.
# --------------------------------------------------------------------------

def object_records(memory) -> list[tuple[int, int, int, int]]:
    """(tape address, length, room, type) for each record of the object
    table, as #R$EACC walks it at $A924: a room, a type, and four more bytes
    for a type below $46, nine for the others; $FF ends it."""
    out, address = [], OBJECTS_TAPE
    while memory[address] != 0xFF:
        kind = memory[address + 1]
        length = 6 if kind < 0x46 else 11
        out.append((address, length, memory[address], kind))
        address += length
        if address >= OBJECTS_TAPE + OBJECTS_COPY:
            raise ValueError("the object table runs past what the start-up copies")
    return out


def _object_lines(memory) -> tuple[list[str], int]:
    records = object_records(memory)
    end = records[-1][0] + records[-1][1]
    out = [f"@ ${OBJECTS_TAPE:04X} label=OBJECTS_TAPE",
           f"b ${OBJECTS_TAPE:04X} The object table, as the tape has it",
           f"D ${OBJECTS_TAPE:04X} {len(records)} records: "
           f"{sum(1 for r in records if r[3] < 0x46)} of six bytes and "
           f"{sum(1 for r in records if r[3] >= 0x46)} of eleven."]
    for number, (address, length, room, kind) in enumerate(records, 1):
        rest = ", ".join(str(memory[a]) for a in range(address + 2, address + length))
        out.append(f"B ${address:04X},{length},{length} {number}: room {room}, type {kind}; {rest}")
    out.append(f"B ${end:04X},1,1 End of the table")
    return out, end + 1


def _template_lines(memory) -> tuple[list[str], int]:
    small = tape_address(SMALL_HOME)
    large = tape_address(LARGE_HOME)
    patches = tape_address(PATCHES_HOME)
    out = [f"@ ${small:04X} label=TEMPLATES_TAPE",
           f"b ${small:04X} Templates for object types 0-{SMALL_COUNT - 1}, as the tape has them"]
    for kind in range(SMALL_COUNT):
        address = small + SMALL_SIZE * kind
        out.append(f"B ${address:04X},{SMALL_SIZE},{SMALL_SIZE} Type {kind}: "
                   + _template_fields(memory, address))
    spare = small + SMALL_SIZE * SMALL_COUNT
    if spare < large:
        out.append(f"B ${spare:04X},{large - spare},{large - spare} Between the tables")
    out += [f"@ ${large:04X} label=LARGE_TEMPLATES_TAPE",
            f"b ${large:04X} Templates for object types ${LARGE_FIRST:02X}-"
            f"${LARGE_FIRST + LARGE_COUNT - 1:02X}, as the tape has them"]
    for index in range(LARGE_COUNT):
        address = large + LARGE_SIZE * index
        out.append(f"B ${address:04X},{LARGE_SIZE},{LARGE_SIZE} Type "
                   f"${LARGE_FIRST + index:02X}: " + _template_fields(memory, address))
    after = large + LARGE_SIZE * LARGE_COUNT
    first = patches + PATCH_SIZE
    out.append(f"B ${after:04X},{first - after},8 Between the tables")
    used = patch_codes(memory)
    last = max(used) - PATCH_FIRST
    out += [f"@ ${first:04X} label=PATCHES_TAPE",
            f"b ${first:04X} Patches for the codes ${PATCH_FIRST + 1:02X} up in a room's "
            f"object list, as the tape has them"]
    for entry in range(1, last + 1):
        address = patches + PATCH_SIZE * entry
        values = ", ".join(str(memory[a]) for a in range(address, address + PATCH_SIZE))
        note = "" if PATCH_FIRST + entry in used else " (no room uses it)"
        out.append(f"B ${address:04X},{PATCH_SIZE},{PATCH_SIZE} Code "
                   f"${PATCH_FIRST + entry:02X}: {values}{note}")
    end = patches + PATCH_SIZE * (last + 1)
    copy_end = TEMPLATES_TAPE + TEMPLATES_COPY
    out.append(f"B ${end:04X},{copy_end - end},{min(8, copy_end - end)} The rest of what the "
               f"start-up copies (no room uses a code that reads it)")
    return out, copy_end


def _template_fields(memory, address: int) -> str:
    width, height, sprite = memory[address + 2], memory[address + 3], _word(memory, address + 4)
    if not sprite:
        return "no sprite"
    return f"{width} by {height}, sprite #R${sprite:04X}"


def patch_codes(memory) -> set[int]:
    codes = set()
    for base, count in ((ROOMS, ROOM_COUNT), (PARTS, PART_COUNT)):
        for address, length in _stream_records(memory, base, count):
            first = address + (3 if base == ROOMS else 2)
            for at, n, what in room_commands(memory, first, address + length):
                if what.startswith("Patch"):
                    codes.add(memory[at])
    return codes


def template_sprites(memory) -> list[tuple[int, int, int, str]]:
    """(address, width, height, whose) for every sprite a template names."""
    out = []
    small = tape_address(SMALL_HOME)
    for kind in range(SMALL_COUNT):
        address = small + SMALL_SIZE * kind
        if _word(memory, address + 4):
            out.append((_word(memory, address + 4), memory[address + 2], memory[address + 3],
                        f"type {kind}"))
    large = tape_address(LARGE_HOME)
    for index in range(LARGE_COUNT):
        address = large + LARGE_SIZE * index
        if _word(memory, address + 4):
            out.append((_word(memory, address + 4), memory[address + 2], memory[address + 3],
                        f"type ${LARGE_FIRST + index:02X}"))
    return out


# --------------------------------------------------------------------------
# Sprites and textures.
# --------------------------------------------------------------------------

def sprite_length(width: int, height: int) -> int:
    return 2 * (width // 8) * height


def plausible_sprite(address: int, width: int, height: int) -> bool:
    return (width and width % 8 == 0 and width <= 64 and 0 < height <= 64
            and any(start <= address and address + sprite_length(width, height) <= end
                    for start, end in SPRITE_AREAS))


def sprite_frames(memory, seen: list[tuple[int, int, int]]) -> list[tuple[int, int, int, str]]:
    """(address, width, height, how known) for every sprite: named by a
    template, seen on an object in the sessions, or lying between two seen
    frames of its size a whole number of frames apart."""
    known: dict[tuple[int, int, int], str] = {}
    for address, width, height, whose in template_sprites(memory):
        if plausible_sprite(address, width, height):
            known.setdefault((address, width, height), f"the template for {whose}")
    for frame in seen:
        if plausible_sprite(*frame):
            known.setdefault(frame, "seen")
    frames = sorted(known)
    filled = {}
    for (a1, w1, h1), (a2, w2, h2) in zip(frames, frames[1:]):
        length = sprite_length(w1, h1)
        gap = a2 - a1
        if (w1, h1) == (w2, h2) and gap > length and gap % length == 0:
            for address in range(a1 + length, a2, length):
                filled[(address, w1, h1)] = "between"
    known.update(filled)
    out = [(a, w, h, how) for (a, w, h), how in sorted(known.items())]
    for (a1, w1, h1, _), (a2, _, _, _) in zip(out, out[1:]):
        if a1 + sprite_length(w1, h1) > a2:
            raise ValueError(f"the sprite at ${a1:04X} ({w1} by {h1}) runs into ${a2:04X}")
    return out


def sprite_picture_name(address: int) -> str:
    return f"sprite{address:04x}.png"


def texture_picture_name(index: int) -> str:
    return f"texture{index:02d}.png"


def _sprite_lines(memory, frames) -> list[str]:
    out = []
    template_names = {}
    for address, width, height, whose in template_sprites(memory):
        template_names.setdefault(address, []).append(whose)
    for address, width, height, how in frames:
        size = (width // 8) * height
        whose = template_names.get(address)
        title = f"Sprite, {width} by {height}"
        if whose:
            title += f" (the template for {', '.join(whose)})"
        out.append(f"@ ${address:04X} label=SPRITE{address:04X}")
        out.append(f"b ${address:04X} {title}")
        out.append(f'D ${address:04X} #HTML(<img class="fl-sprite" '
                   f'src="../images/sprites/{sprite_picture_name(address)}" '
                   f'alt="The sprite at ${address:04X}">)')
        seen = {"seen": "Seen on an object in the build's sessions.",
                "between": "Not seen in the sessions: it lies between two frames of its size "
                           "that were, a whole number of frames from each."}.get(how, "")
        if seen:
            out.append(f"D ${address:04X} {seen}")
        out.append(f"B ${address:04X},{size},{width // 8} Image, the top row first")
        out.append(f"B ${address + size:04X},{size},{width // 8} Mask: a bit set where "
                   f"the background shows through")
    return out


def _texture_lines(memory) -> list[str]:
    out = [f"@ ${TEXTURES:04X} label=TEXTURES"]
    for index in range(TEXTURE_COUNT):
        address = TEXTURES + 32 * index
        if index:
            out.append(f"@ ${address:04X} label=TEXTURE{index}")
        out.append(f"b ${address:04X} Texture {index} (fill code ${0xE6 + index:02X})")
        out.append(f'D ${address:04X} #HTML(<img class="fl-texture" '
                   f'src="../images/textures/{texture_picture_name(index)}" '
                   f'alt="Texture {index}">)')
        out.append(f"B ${address:04X},32,8 Four columns of eight rows")
    return out


# --------------------------------------------------------------------------
# The symbol table left on the tape.
# --------------------------------------------------------------------------

def symbols(memory) -> tuple[list[tuple[int, int, str, int]], int, int]:
    """(address, length, name, value) of each whole node of the symbol
    table: a left and a right link, a byte 1, the name with bit 7 set on its
    last letter, and the value. The first node on the tape is cut off before
    its name; it is found by where the second begins. Returns the nodes,
    where the first whole one starts and where the last one ends."""
    out, address = [], None
    for start in range(SYMBOLS, SYMBOLS_END - 5):
        if memory[start + 4] == 1 and 0x41 <= memory[start + 5] <= 0x5A:
            address = start
            break
    if address is None:
        raise ValueError("no symbol table where expected")
    first = address
    while address + 5 < SYMBOLS_END:
        at = address + 5
        while at < SYMBOLS_END and not memory[at] & 0x80:
            at += 1
        if at + 2 >= SYMBOLS_END or memory[address + 4] != 1:
            break
        name = "".join(chr(memory[a] & 0x7F) for a in range(address + 5, at + 1))
        out.append((address, at + 3 - address, name, _word(memory, at + 1)))
        address = at + 3
    return out, first, address


def _symbol_lines(memory, code: set[int]) -> list[str]:
    nodes, first, end = symbols(memory)
    ran = sum(1 for _, _, _, value in nodes if value in code)
    out = [f"@ ${SYMBOLS:04X} label=SYMBOL_TABLE",
           f"b ${SYMBOLS:04X} What is left of the development assembler's symbol table",
           f"D ${SYMBOLS:04X} {len(nodes)} whole symbols, {ran} of them the address of an "
           f"instruction in this listing's code.",
           f"B ${SYMBOLS:04X},{first - SYMBOLS},{first - SYMBOLS} The end of a symbol whose "
           f"start the loader's bytes replaced: its last letter and its value"]
    for address, length, name, value in nodes:
        target = f"#R${value:04X}" if value in code else f"${value:04X}"
        out.append(f"B ${address:04X},{length},4,1,{length - 7},2 {name} = {target}")
    if end < SYMBOLS_END:
        out.append(f"B ${end:04X},{SYMBOLS_END - end},{SYMBOLS_END - end} The links of the "
                   f"next symbol, cut off by the game's code")
    return out


# --------------------------------------------------------------------------
# Together.
# --------------------------------------------------------------------------

def owned(memory, frames, code: set[int]) -> list[tuple[int, int]]:
    """The ranges the generated lines describe completely: build_fairlight.py
    drops whatever sna2ctl put inside them. (start, end), end exclusive."""
    ranges = [(ROOMS, PARTS), (PARTS, PARTS_END), (GLYPHS, GLYPHS + 8 * GLYPH_COUNT),
              (TEXTURES, TEXTURES + 32 * TEXTURE_COUNT)]
    objects_end = object_records(memory)[-1][0] + object_records(memory)[-1][1] + 1
    ranges.append((OBJECTS_TAPE, objects_end))
    ranges.append((TEMPLATES_TAPE, TEMPLATES_TAPE + TEMPLATES_COPY))
    ranges.append((SYMBOLS, SYMBOLS_END))
    for address, width, height, _ in frames:
        ranges.append((address, address + sprite_length(width, height)))
    return sorted(ranges)


def strings(memory, code: set[int]) -> tuple[str, list[tuple[int, int]]]:
    """The strings after CALLs to the printer: the sub-block lines that lay
    each out in its routine, and their ranges (start, end). They are kept
    apart from data_blocks(): they belong inside code entries, not in
    entries of their own."""
    lines, ranges = _string_lines(memory, code)
    return NEWLINE.join(lines) + NEWLINE, ranges


def data_blocks(memory, frames, code: set[int]) -> str:
    """The control-file lines for every table above, in address order."""
    lines = ["; Generated by scripts/fairlight_data.py from the snapshot -- do not edit.", ""]
    lines += _room_lines(memory) + [""]
    lines += _part_lines(memory) + [""]
    lines += _sprite_lines(memory, frames) + [""]
    lines += _glyph_lines(memory) + [""]
    object_lines, _ = _object_lines(memory)
    lines += object_lines + [""]
    template_lines, _ = _template_lines(memory)
    lines += template_lines + [""]
    lines += _symbol_lines(memory, code) + [""]
    lines += _texture_lines(memory) + [""]
    return NEWLINE.join(lines) + NEWLINE


# --------------------------------------------------------------------------
# Pictures.
# --------------------------------------------------------------------------

SCALE = 3


def sprite_image(memory, address: int, width: int, height: int, scale: int = SCALE):
    """The sprite as #R$EE8D draws it and the compositor (#R$E3E4) shows
    it: where the mask has a bit set the background shows (clear here),
    whatever the image says -- 37 pixels of nine sprites have both set, and
    the room shows through them; elsewhere the image's bit set is ink and
    clear is solid black."""
    from PIL import Image

    columns = width // 8
    size = columns * height
    image = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    pixels = image.load()
    for row in range(height):
        for column in range(columns):
            bits = memory[address + row * columns + column]
            mask = memory[address + size + row * columns + column]
            for bit in range(8):
                if mask & (0x80 >> bit):
                    continue
                pixels[column * 8 + bit, row] = ((255, 255, 255, 255) if bits & (0x80 >> bit)
                                                 else (0, 0, 0, 255))
    return image.resize((width * scale, height * scale), Image.NEAREST)


def texture_image(memory, index: int, scale: int = SCALE):
    """A texture's four columns of eight bytes drawn as a 16 by 16 tile, the
    first two columns side by side above the other two, and the tile
    repeated twice each way so that the pattern can be seen."""
    from PIL import Image

    base = TEXTURES + 32 * index
    tile = Image.new("RGB", (16, 16), (0, 0, 0))
    pixels = tile.load()
    for half in range(2):
        for side in range(2):
            for row in range(8):
                bits = memory[base + 16 * half + 8 * side + row]
                for bit in range(8):
                    if bits & (0x80 >> bit):
                        pixels[8 * side + bit, 8 * half + row] = (255, 255, 255)
    image = Image.new("RGB", (32, 32))
    for x in (0, 16):
        for y in (0, 16):
            image.paste(tile, (x, y))
    return image.resize((32 * scale, 32 * scale), Image.NEAREST)


def draw_pictures(memory, frames, images) -> int:
    count = 0
    (images / "sprites").mkdir(parents=True, exist_ok=True)
    for address, width, height, _ in frames:
        sprite_image(memory, address, width, height).save(
            images / "sprites" / sprite_picture_name(address))
        count += 1
    (images / "textures").mkdir(parents=True, exist_ok=True)
    for index in range(TEXTURE_COUNT):
        texture_image(memory, index).save(images / "textures" / texture_picture_name(index))
        count += 1
    return count


def write_logo(memory, path, log=print) -> bool:
    """The title from the loading screen: the scroll across the top with
    "Fairlight" and "a prelude" on it. It spans character columns 4-27 of
    the top seven rows; there the scroll's yellow and red and the black of
    the letters (the paper of its middle cells) are kept, and the blue of
    the sky behind it is left clear. The scroll with "Fairlight" on it is
    one piece; the letters of "a prelude" are pieces of their own below row
    40; anything else (the corners of the pillars either side) goes."""
    from PIL import Image

    import filmation_logos

    screen = filmation_logos.Screen(bytes(memory[0x4000:0x5B00]))
    coloured = {(x, y) for y in range(0, 56) for x in range(32, 224)
                if screen.number[(x, y)] in (filmation_logos.YELLOW, filmation_logos.RED,
                                             filmation_logos.BLACK)}
    pieces = filmation_logos.pieces(coloured, True)
    chosen = pieces[:1] + [piece for piece in pieces[1:] if min(y for _, y in piece) >= 40]
    kept = {p: screen.rgb[p] for piece in chosen for p in piece}
    xs = [x for x, _ in kept]
    ys = [y for _, y in kept]
    margin, scale = filmation_logos.MARGIN, filmation_logos.SCALE
    left, top = min(xs) - margin, min(ys) - margin
    width, height = max(xs) - left + 1 + margin, max(ys) - top + 1 + margin
    image = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    for (x, y), rgb in kept.items():
        image.putpixel((x - left, y - top), rgb + (255,))
    path.parent.mkdir(parents=True, exist_ok=True)
    image.resize((width * scale, height * scale), Image.NEAREST).save(path)
    log(f"  logo cut from the loading screen: {width * scale}x{height * scale}")
    return True
