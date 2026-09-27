"""Knight Lore's "How it works" pages: the depth sort, collision, day and
night, and the charms.

build() returns each page's HTML for knightlore-pages.ref and writes the
pictures into the HTML directory. Like knightlore_pages.py, it takes nothing
from a committed transcription: the tables are read from the game's memory as
the page is built, and the scenes and the collision examples are the game's
own code, run in SkoolKit's simulator through knightlore_pages.Castle. The
prose is written from the checked notes in notes/knightlore/ (depth-order,
collision, player, day-and-night, special-objects, inventory, winning).
"""
from __future__ import annotations

from pathlib import Path

import knightlore_data as kd
import knightlore_pages as kp

IMAGE_URL = "images/howitworks"

# --------------------------------------------------------------------------
# Addresses read or run here (see their entries in the listing).
# --------------------------------------------------------------------------

DEPTH_ORDER_TBL = 0xCF69      # 27 words, indexed by Z code + Y code + X code
ORDER_UNCONSTRAINED = 0xCF9F  # the four places the table can send the sort
CANDIDATE_ALREADY_FIRST = 0xCFA2
IY_GOES_FIRST = 0xCFA5
OBJS_COINCIDE = 0xCFE1
SORT_DONE = 0xD656            # in draw_and_copy_rects, just after the sort

ADJ_FOR_OUT_OF_BOUNDS = 0xCB45
ROOM_HALF_X, ROOM_HALF_Y, FLOOR = 0x5BAB, 0x5BAC, 0x5BAE
OBJECT_TABLE_END = kp.PLAYER + 40 * 32

SUN_MOON = 0xC44D             # the sun or moon's own object record
SUN_MOON_YOFF = 0xC440        # 13 heights
DISPLAY_SUN_MOON_FRAME = 0xC3A4
COLOUR_PANEL = 0xD2EF
COLOUR_SUN_MOON = 0xD30D
GAME_COMPLETE = 0x5BC3
SUN, MOON = 88, 89
SUN_START, SUN_END = 176, 225
WINDOW = (184, 161, 232, 192)   # the window on the screen: x 184-231, the bottom 31 rows

OBJECTS_REQUIRED = 0xC27D     # 14 kinds
OBJECT_ATTRIBUTES = 0xBFD3    # 8 panel colours, by type AND $0F
RATING_TBL = 0xBBB7           # 8 words
WIZARDS_ROOM = 0x88
CHARM, EXTRA_LIFE = 96, 103

OUTCOMES = {
    IY_GOES_FIRST: ("iy", "other first"),
    CANDIDATE_ALREADY_FIRST: ("cand", "candidate first"),
    ORDER_UNCONSTRAINED: ("free", "no order"),
    OBJS_COINCIDE: ("coincide", "the boxes intersect"),
}


def _sprite_address(memory, object_type: int) -> int:
    return kp._word(memory, kp.SPRITE_TABLE + 2 * object_type)


def _signed(byte: int) -> int:
    return byte - 256 if byte & 0x80 else byte


def _img(name: str, image, css: str = "kl-piece", alt: str = "", scale: int = 2) -> str:
    """An <img> for a picture saved at its own size and shown `scale` times
    larger (pixelated by the style sheet)."""
    return (f'<img class="{css}" src="{IMAGE_URL}/{name}" alt="{kp._esc(alt)}" '
            f'width="{image.width * scale}" height="{image.height * scale}">')


def _sprite(memory, object_type: int, image_dir: Path, tint=None) -> tuple[str, object]:
    """The sprite of an object type, saved once; its file name and picture.
    With `tint`, the white of the image is drawn in that colour instead, the
    way the panel colours a carried charm."""
    image = kp.sprite_image(memory, _sprite_address(memory, object_type), scale=1)
    if tint is not None:
        pixels = image.load()
        for y in range(image.height):
            for x in range(image.width):
                if pixels[x, y] == (255, 255, 255, 255):
                    pixels[x, y] = tint + (255,)
        name = f"type{object_type:03d}_{tint[0]:02x}{tint[1]:02x}{tint[2]:02x}.png"
    else:
        name = f"type{object_type:03d}.png"
    image.save(image_dir / name)
    return name, image


def _attribute_colour(attribute: int) -> tuple:
    palette = kp.SPECTRUM_BRIGHT if attribute & 0x40 else kp.SPECTRUM
    return palette[attribute & 7]


# --------------------------------------------------------------------------
# The depth sort.
# --------------------------------------------------------------------------

# The two boxes in the table's pictures: the candidate at the origin, the
# other object placed by the three answers. Sizes are in the game's units.
BOX_HALF, BOX_HEIGHT = 8, 14
APART = 2 * BOX_HALF + 6        # centres this far apart leave a gap of 6
# A wider gap in Z than across, so that a box straight in front of or behind
# the other along the line of sight still shows beside it.
ABOVE = BOX_HEIGHT + 12
# Overlapping offsets, chosen so that the all-overlap case does not lie on the
# line of sight (+1, -1, +1), where the two pictures would coincide exactly.
OVERLAP_X, OVERLAP_Y, OVERLAP_Z = 6, 6, 5
PAIR_SCALE = 2
Z_CODES = ((0, "candidate wholly above"), (1, "overlapping in height"),
           (2, "other wholly above"))
Y_CODES = ((0, "candidate wholly further back"), (3, "overlapping"),
           (6, "other wholly further back"))
X_CODES = ((0, "other wholly further back"), (9, "overlapping"),
           (18, "candidate wholly further back"))
CANDIDATE_SHADES = ((0, 255, 255), (0, 176, 176), (0, 112, 112))   # top, +X, -Y
OTHER_SHADES = ((255, 255, 0), (176, 176, 0), (112, 112, 0))


def depth_table(memory) -> list[str]:
    """The 27 entries of the table at $CF69, as outcome keys."""
    out = []
    for index in range(27):
        target = kp._word(memory, DEPTH_ORDER_TBL + 2 * index)
        if target not in OUTCOMES:
            raise ValueError(f"depth_order_tbl entry {index} is ${target:04X}")
        out.append(target)
    return out


def _other_box(z_code: int, y_code: int, x_code: int) -> tuple:
    x = {0: -APART, 9: OVERLAP_X, 18: APART}[x_code]      # further back is smaller X
    y = {0: -APART, 3: OVERLAP_Y, 6: APART}[y_code]       # further back is larger Y
    z = {0: -ABOVE, 1: OVERLAP_Z, 2: ABOVE}[z_code]
    return x, y, z


def _box_faces(x: int, y: int, z: int) -> list[list[tuple]]:
    """The three faces that face the viewer -- the top, +X and -Y -- as
    (X, Y, Z) corners."""
    x0, x1, y0, y1 = x - BOX_HALF, x + BOX_HALF, y - BOX_HALF, y + BOX_HALF
    z0, z1 = z, z + BOX_HEIGHT
    return [[(x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)],
            [(x1, y0, z0), (x1, y1, z0), (x1, y1, z1), (x1, y0, z1)],
            [(x0, y0, z0), (x1, y0, z0), (x1, y0, z1), (x0, y0, z1)]]


def _screen_point(point: tuple) -> tuple:
    """The game's projection (calc_pixel_XY), with y counted down the page."""
    x, y, z = point
    return PAIR_SCALE * (x + y), -PAIR_SCALE * ((y - x) / 2 + z)


def _pair_pictures(memory, image_dir: Path, log) -> dict[int, tuple[str, object]]:
    """A small picture for each entry of the table: the two boxes, drawn in
    the order the entry asks for. Also checks the claim the page makes about
    the "no order" entries: that their two pictures never overlap."""
    from PIL import Image, ImageChops, ImageDraw

    table = depth_table(memory)
    cases = []
    for z_code, _ in Z_CODES:
        for y_code, _ in Y_CODES:
            for x_code, _ in X_CODES:
                cases.append((z_code + y_code + x_code, _other_box(z_code, y_code, x_code)))
    points = [_screen_point(p) for _, other in cases
              for box in ((0, 0, 0), other) for face in _box_faces(*box) for p in face]
    left = min(p[0] for p in points) - 4
    top = min(p[1] for p in points) - 4
    width = int(max(p[0] for p in points) - left) + 5
    height = int(max(p[1] for p in points) - top) + 5

    def layer(box, shades, alpha=255):
        image = Image.new("RGBA", (width, height), (0, 0, 0, 0))
        draw = ImageDraw.Draw(image)
        for face, shade in zip(_box_faces(*box), shades):
            corners = [(sx - left, sy - top) for sx, sy in map(_screen_point, face)]
            draw.polygon(corners, fill=shade + (alpha,), outline=(0, 0, 0, alpha))
        return image

    pictures = {}
    for index, other in cases:
        outcome = table[index]
        candidate_layer = layer((0, 0, 0), CANDIDATE_SHADES)
        other_layer = layer(other, OTHER_SHADES)
        if OUTCOMES[outcome][0] == "free":
            overlap = ImageChops.multiply(candidate_layer.getchannel("A"),
                                          other_layer.getchannel("A")).getbbox()
            if overlap:
                log(f"  depth table entry {index}: 'no order', but the pictures overlap")
        if OUTCOMES[outcome][0] == "coincide":
            first, second = (layer(other, OTHER_SHADES, 170),
                             layer((0, 0, 0), CANDIDATE_SHADES, 170))
        elif OUTCOMES[outcome][0] == "iy":
            first, second = other_layer, candidate_layer
        else:
            first, second = candidate_layer, other_layer
        image = Image.alpha_composite(first, second)
        name = f"depth_pair{index:02d}.png"
        image.save(image_dir / name)
        pictures[index] = (name, image)
    return pictures


# The scene: stone blocks placed by a one-off room record, listed nearest
# first so that the sort has to turn the list round. Position bytes are cells
# of the room's 8 by 8 grid and a level: x + 8y + 64 * level.
SCENE_BLOCKS = [(4, 2, 0), (5, 3, 0), (4, 3, 1), (4, 3, 0), (3, 3, 0), (4, 4, 0)]
BLOCK_TEMPLATE = 0
NEW_INK = (255, 255, 0)


def _buffer_bits(memory) -> list[int]:
    return list(memory[kp.BUFFER:kp.BUFFER + 192 * 32])


def _buffer_picture(bits: list[int], before: list[int] | None):
    """The buffer as a picture: white, with the pixels the last draw changed
    that are now set in yellow."""
    from PIL import Image

    image = Image.new("RGB", (256, 192))
    pixels = image.load()
    for y in range(192):
        row = (191 - y) * 32
        for column in range(32):
            byte = bits[row + column]
            changed = byte ^ before[row + column] if before is not None else 0
            for bit in range(8):
                mask = 0x80 >> bit
                if byte & mask:
                    pixels[column * 8 + bit, y] = NEW_INK if changed & mask else (255, 255, 255)
    return image


def depth_scene(castle):
    """Build the scene's room and follow its first frame through the sort:
    the buffer before each object is drawn and after the last, and which
    record each draw was."""
    from skoolkit.simutils import IXh, IXl, PC, SP

    room = castle.empty_room
    positions = [x + 8 * y + 64 * level for x, y, level in SCENE_BLOCKS]
    record = kp._one_off_record(room, 0, [], [(BLOCK_TEMPLATE, positions)])
    memory = list(castle.memory)
    memory[kp.PLAYER + kp.ROOM_OFFSET] = room
    memory[kp.PLAYER_TOP + kp.ROOM_OFFSET] = room
    memory[kd.ROOMS:kd.ROOMS + len(record)] = record
    memory, registers = castle._call(memory, kp.BUILD_SCREEN_OBJECTS, castle.registers)
    sim = castle._machine(memory)
    for index, value in enumerate(registers):
        sim.registers[index] = value
    sim.registers[SP] = kp.OBJECT_STACK
    # On a room's first frame everything is flagged and the buffer is clear,
    # so the whole room goes through the sort.
    sim.run(kp.ONSCREEN_LOOP, kp.END_OF_FRAME)
    sim.run(kp.END_OF_FRAME, kp.DRAW_AND_COPY_RECTS)
    listed = []
    address = kp.OBJECTS_TO_DRAW
    while sim.memory[address] != 0xFF:
        listed.append(sim.memory[address])
        address += 1
    snapshots, order = [], []
    for _ in listed:
        sim.run(sim.registers[PC], kp.RENDER_OBJ)
        snapshots.append(_buffer_bits(sim.memory))
        ix = (sim.registers[IXh] << 8) | sim.registers[IXl]
        order.append((ix - kp.PLAYER) // 32)
    sim.run(sim.registers[PC], SORT_DONE)
    snapshots.append(_buffer_bits(sim.memory))
    places = {}
    for i in range(40):
        base = kp.PLAYER + 32 * i
        if sim.memory[base]:
            places[i] = tuple(sim.memory[base + 1:base + 4])
    return {"listed": listed, "order": order, "snapshots": snapshots, "places": places}


def _depth_page(memory, castle, image_dir: Path, log) -> str:
    table = depth_table(memory)
    pairs = _pair_pictures(memory, image_dir, log)
    counts = {key: sum(1 for t in table if OUTCOMES[t][0] == key)
              for key in ("iy", "cand", "free", "coincide")}

    grids = []
    for z_code, z_text in Z_CODES:
        rows = [f'<table class="kl-table"><tr><th>Z: {z_text} (Z code {z_code})</th>'
                + "".join(f"<th>X: {x_text} ({x_code})</th>" for x_code, x_text in X_CODES)
                + "</tr>"]
        for y_code, y_text in Y_CODES:
            cells = []
            for x_code, _ in X_CODES:
                index = z_code + y_code + x_code
                name, image = pairs[index]
                word = OUTCOMES[table[index]][1]
                cells.append(f"<td>{_img(name, image, scale=1)}<br>{index}: <b>{word}</b> "
                             f"(#R${table[index]:04X})</td>")
            rows.append(f"<tr><th>Y: {y_text} ({y_code})</th>" + "".join(cells) + "</tr>")
        rows.append("</table>")
        grids.append("".join(rows))

    log("  following a scene through the sort...")
    scene = depth_scene(castle)
    # Every step is cut to the finished scene, with a margin, so the pictures
    # line up.
    bbox = _buffer_picture(scene["snapshots"][-1], None).convert("L").getbbox()
    margin = 6
    crop = (max(0, bbox[0] - margin), max(0, bbox[1] - margin),
            min(256, bbox[2] + margin), min(192, bbox[3] + margin))
    steps = []
    for step, record in enumerate(scene["order"], 1):
        before = scene["snapshots"][step - 1]
        after = scene["snapshots"][step]
        image = _buffer_picture(after, before).crop(crop)
        name = f"depth_step{step}.png"
        image.save(image_dir / name)
        x, y, z = scene["places"].get(record, (0, 0, 0))
        cell = ((x - 0x48) // 16, (y - 0x48) // 16, (z - 0x80) // 12)
        steps.append((step, record, cell, name, image))
    listed_text = ", ".join(str(i) for i in scene["listed"])
    step_items = "".join(
        f'<div class="kl-item">{_img(name, image)}<p>Drawn {step}: record {record}, the '
        f"block in cell x {cell[0]}, y {cell[1]} at level {cell[2]}.</p></div>"
        for step, record, cell, name, image in steps)
    order_text = ", ".join(str(record) for _, record, _, _, _ in steps)

    return "\n".join([
        '<div class="kl-list">',
        "<p>Knight Lore draws a room by laying whole objects over one another in an "
        "off-screen buffer, each through its own mask, so that whatever is drawn last is "
        "in front. The order is everything: an object has to be drawn after everything it "
        "partly hides. This page shows how the game decides that order -- by comparing "
        "boxes, never pictures -- and draws the table it decides with straight out of the "
        'game. Which objects are redrawn in a frame at all is on <a href="MovingObjects.html">'
        "how a moving object is drawn</a>.</p>",

        "<h3>Every object is a box</h3>",
        "<p>An object record holds a box as well as a picture: the centre in X and Y at "
        "+$01 and +$02, with half-sizes at +$04 and +$05, and the base in Z at +$03 with "
        'the full height at +$06. It is the same box <a href="Collision.html">collisions'
        "</a> use. The picture is placed by #R$D6C9: pixel x = X + Y - 128 and, counting "
        "up from the bottom of the screen, pixel y = (Y - X + 128)/2 + Z - 104. So a step "
        "of +X moves a picture right and down, +Y right and up, +Z straight up -- and a "
        "step of (+1, -1, +1) does not move it at all. That is the line of sight, pointing "
        "at the viewer. Further back therefore means smaller X, larger Y and lower Z, and "
        "the game can order two objects from their boxes alone.</p>",

        "<h3>Comparing two boxes</h3>",
        "<p>#R$CEBB compares two boxes at a time: the candidate, the object it is "
        "thinking of drawing next, and one other object not yet drawn. On each axis it "
        "asks one question with three answers -- the candidate wholly on one side, the two "
        "overlapping, or the other wholly on the other side -- and each answer is a number, "
        "chosen so that the three add up to a different total for every one of the 27 "
        "combinations (#R$CEDB, #R$CF16, #R$CF3C):</p>",
        '<table class="kl-table"><tr><th>Axis</th><th>Code</th><th>Code</th><th>Code</th></tr>'
        "<tr><td>Z (base +$03, height +$06)</td><td>0: candidate wholly above</td>"
        "<td>1: overlap</td><td>2: other wholly above</td></tr>"
        "<tr><td>Y (centre +$02, half-size +$05)</td><td>0: candidate wholly further back</td>"
        "<td>3: overlap</td><td>6: other wholly further back</td></tr>"
        "<tr><td>X (centre +$01, half-size +$04)</td><td>0: other wholly further back</td>"
        "<td>9: overlap</td><td>18: candidate wholly further back</td></tr></table>",
        "<p>\"Wholly\" is plain 8-bit subtraction: one box's edge at or beyond the "
        "other's. Boxes that exactly touch therefore count as apart. The total, 0 to 26, "
        "picks one of 27 addresses from the table at #R$CF69, and the sort jumps there "
        "(#R$CF62).</p>",

        "<h3>The table</h3>",
        "<p>Here is the table as it was read from the game when this page was built, one "
        "grid for each Z answer. In each picture the candidate is cyan and the other "
        "object yellow, placed as the three answers say and drawn in the order the entry "
        "asks for. There are four outcomes:</p>",
        '<table class="kl-table"><tr><th>Entry</th><th>How many</th><th>Meaning</th></tr>'
        f"<tr><td>#R${IY_GOES_FIRST:04X}: other first</td><td>{counts['iy']}</td><td>The "
        "other object is further back than the candidate, or level with it, on every axis, "
        "and further back on at least one. It has to be drawn first, so it becomes the "
        "candidate.</td></tr>"
        f"<tr><td>#R${CANDIDATE_ALREADY_FIRST:04X}: candidate first</td><td>{counts['cand']}"
        "</td><td>The mirror image: the candidate is the one behind. It is going to be "
        "drawn first anyway, so there is nothing to do.</td></tr>"
        f"<tr><td>#R${ORDER_UNCONSTRAINED:04X}: no order</td><td>{counts['free']}</td><td>"
        "Each box is in front of the other along some axis. Either may be drawn first."
        "</td></tr>"
        f"<tr><td>#R${OBJS_COINCIDE:04X}: the boxes intersect</td><td>{counts['coincide']}"
        "</td><td>Overlapping on all three axes: the boxes share space and cannot be "
        "ordered (see below).</td></tr></table>",
        "<p>\"Candidate first\" and \"no order\" are the same single instruction, a jump "
        "back to the next comparison; the table only names them differently. So a pair "
        "is given an order only when one box is behind the other, or level with it, on "
        "every axis -- which is exactly when one can hide part of the other under this "
        "projection.</p>",
        *grids,

        "<h3>Why \"no order\" is safe</h3>",
        "<p>Every \"no order\" entry is a pair apart on two axes in opposite senses: say "
        "the candidate is further back in Y but the other is further back in X. For one "
        "picture to cover part of the other, some line of sight would have to pass through "
        "both boxes. Along a line of sight X and Y change by equal and opposite amounts. "
        "Going from the candidate to the other, Y has to fall, since the other has the "
        "smaller Y; so X rises -- but X has to fall, since the other has the smaller X. No "
        "line of sight meets both, so neither picture can cover the other, and the order "
        "between them does not matter. The pictures above bear it out: in every \"no "
        "order\" grid square the two boxes are apart on the screen as well (the build "
        "checks that each time).</p>",
        "<p>That argument is worked out from the projection, and holds for the boxes. It "
        "takes no account of the pixel offsets each object adds to its picture (+$12 and "
        "+$13), or of artwork that spills outside its object's box.</p>",

        "<h3>Finding the order</h3>",
        "<p>#R$CEBB works through the list of objects to be drawn this frame (#R$CE8B, "
        "made by #R$CE62) in passes, and each pass draws one object:</p>",
        "<ol><li>The candidate is the first entry not yet drawn (#R$CEC3).</li>"
        "<li>It is compared with every other undrawn entry (#R$CEDB). If the table says "
        "the other must go first, the other becomes the candidate and the comparisons "
        "start again from the top of the list (#R$CFB8).</li>"
        "<li>When a candidate reaches the end of the list with nothing found that must go "
        "before it, it is drawn (#R$D003): bit 7 of its entry marks it drawn, #R$D704 "
        "draws it into the buffer, $5BBE counts it, and the next pass begins.</li></ol>",
        "<p>Every entry before the first undrawn one has been drawn, so the first "
        "candidate of a pass need only be compared with the entries after it; a candidate "
        "taken on after a switch is compared with the whole list. It is a search, not a "
        "sort in one sweep: each pass hunts for an object with nothing undrawn behind it, "
        "and may change its mind several times on the way.</p>",

        "<h3>Cycles</h3>",
        "<p>Boxes can be placed so that no order works -- three or more, each partly "
        "behind the next and the last partly behind the first. The search would then "
        "switch candidates for ever. #R$D01A guards against it: it holds every object "
        "made the candidate since the last one was drawn. Before switching, #R$CFA5 looks "
        "for the new object there, and if it is already in the list the order has gone "
        "round in a circle: #R$CFCE draws that object at once. No order satisfies every "
        "pair of a cycle, so wherever it is broken one pair is drawn the wrong way round; "
        "breaking it just keeps the frame moving.</p>",
        "<p>Two details. The object a pass starts with is not put in the list, so a loop "
        "back to it is caught one step later, at the next object in the loop. And the "
        "list has room for seven objects and its end marker, and nothing checks its "
        "length: an eighth would write its end marker over the first byte of #R$D022. "
        "Whether a real room can make a chain that long has not been measured.</p>",

        "<h3>Boxes that intersect</h3>",
        "<p>Entry 13, overlap on every axis, means the two boxes occupy the same space. "
        "#R$CFE1 imposes no order and carries on -- but if either of the pair is one of "
        "the seven charms (types 96 to 102) it destroys it, checking the candidate first "
        "and changing only one of the two. The charm becomes type 187, whose handler "
        "#R$BF37 zeroes its entry in the special-object table at #R$6FF2 and makes it "
        'vanish: it is gone from the game for good. See <a href="Charms.html">the '
        "charms</a>.</p>",

        "<h3>A scene, drawn by the game</h3>",
        f"<p>Six stone blocks placed by a one-off room record and drawn by the game's own "
        "code in a simulator when this page was built: four on the floor round a fifth, "
        "with a sixth on top of the middle one. The record lists them nearest first, so "
        "the list the sort starts from is the wrong way round for drawing. The room "
        f"builder made them records {min(scene['listed'])} to {max(scene['listed'])}, and "
        f"the draw list held {listed_text}. The "
        f"sort drew them in the order {order_text}. Each picture is the buffer after one "
        "more draw, with the pixels that draw changed in yellow -- including where a "
        "nearer block's mask cut into the ones already there.</p>",
        step_items,
        "</div>"])


# --------------------------------------------------------------------------
# Collision.
# --------------------------------------------------------------------------

def _record(object_type, x, y, z, w, d, h, flags=0x10, dx=0, dy=0, dz=0,
            status=0, contact=0) -> list[int]:
    record = [0] * 32
    record[0:14] = [object_type, x, y, z, w, d, h, flags, 0,
                    dx & 0xFF, dy & 0xFF, dz & 0xFF, status, contact]
    return record


# Each case: what it shows, the mover (record 0), the other objects (records
# 4 on). The mover stands on the floor unless it says otherwise; gravity has
# already taken 1 off its dZ, as dec_dZ_and_update_XYZ does before the call.
LEGS, BLOCK, TABLE, SHUTTLE, GARGOYLE, MOVEABLE = 18, 7, 84, 54, 22, 62
COLLISION_CASES = [
    ("Walking diagonally into a block",
     _record(LEGS, 100, 100, 128, 5, 5, 23, dx=3, dy=3, dz=-1),
     [("block", _record(BLOCK, 113, 100, 128, 8, 8, 12))]),
    ("Walking into the room's wall at X = 192",
     _record(LEGS, 185, 128, 128, 5, 5, 23, dx=3, dz=-1), []),
    ("Falling onto a block from 3 units above it",
     _record(LEGS, 100, 100, 143, 5, 5, 23, dz=-5),
     [("block", _record(BLOCK, 100, 100, 128, 8, 8, 12))]),
    ("Walking into a table",
     _record(LEGS, 100, 100, 128, 5, 5, 23, dx=3, dz=-1),
     [("table", _record(TABLE, 111, 100, 128, 6, 10, 12, flags=0x14))]),
    ("Walking into the block called moveable",
     _record(LEGS, 100, 100, 128, 5, 5, 23, dx=3, dz=-1),
     [("block", _record(MOVEABLE, 113, 100, 128, 8, 8, 12, flags=0x14))]),
    ("Standing on a shuttling block that is moving +1 in X",
     _record(LEGS, 100, 100, 140, 5, 5, 23, flags=0x14, dz=-1),
     [("block", _record(SHUTTLE, 100, 100, 128, 8, 8, 12, dx=1))]),
    ("Walking into a gargoyle (+$0D = $A0: harms both ways)",
     _record(LEGS, 100, 100, 128, 5, 5, 23, dx=3, dz=-1),
     [("gargoyle", _record(GARGOYLE, 111, 100, 128, 6, 6, 12, contact=0xA0))]),
]


def try_collision(castle, mover: list[int], others: list[list[int]],
                  sizes=(64, 64, 0x80)) -> tuple[list[int], list[list[int]]]:
    """Put the mover in record 0 and the others from record 4 in an otherwise
    empty object table, and run adj_for_out_of_bounds on the mover. The
    records afterwards."""
    from skoolkit.simutils import IXh, IXl

    memory = list(castle.memory)
    memory[kp.PLAYER:OBJECT_TABLE_END] = [0] * (OBJECT_TABLE_END - kp.PLAYER)
    memory[kp.PLAYER:kp.PLAYER + 32] = mover
    for i, other in enumerate(others):
        base = kp.PLAYER + 32 * (4 + i)
        memory[base:base + 32] = other
    memory[ROOM_HALF_X], memory[ROOM_HALF_Y], memory[FLOOR] = sizes
    registers = list(castle.registers)
    registers[IXh], registers[IXl] = kp.PLAYER >> 8, kp.PLAYER & 0xFF
    memory, _ = castle._call(memory, ADJ_FOR_OUT_OF_BOUNDS, registers)
    after = list(memory[kp.PLAYER:kp.PLAYER + 32])
    rest = [list(memory[kp.PLAYER + 32 * (4 + i):kp.PLAYER + 32 * (5 + i)])
            for i in range(len(others))]
    return after, rest


def _move(record) -> str:
    return ", ".join(f"{_signed(record[9 + k]):+d}" for k in range(3))


def _collision_rows(castle) -> list[str]:
    rows = []
    for text, mover, others in COLLISION_CASES:
        after, rest = try_collision(castle, mover, [o for _, o in others])
        effects = []
        stopped = [axis for bit, axis in ((0, "X"), (1, "Y"), (2, "Z")) if after[12] & (1 << bit)]
        if stopped:
            effects.append("mover stopped in " + " and ".join(stopped) + " (+$0C)")
        if after[13] & 0x40 and not mover[13] & 0x40:
            effects.append("mover harmed (+$0D bit 6)")
        for (name, before), now in zip(others, rest):
            if now[9:11] != before[9:11]:
                effects.append(f"the {name}'s dX, dY became {_signed(now[9]):+d}, "
                               f"{_signed(now[10]):+d}")
            if now[13] & 0x08 and not before[13] & 0x08:
                effects.append(f"the {name} marked as landed on (+$0D bit 3)")
            if now[13] & 0x40 and not before[13] & 0x40:
                effects.append(f"the {name} harmed (+$0D bit 6)")
        rows.append(f"<tr><td>{kp._esc(text)}</td><td>{_move(mover)}</td>"
                    f"<td>{_move(after)}</td><td>{'; '.join(effects) or 'nothing'}</td></tr>")
    return rows


def _collision_page(memory, castle, image_dir: Path, log) -> str:
    sizes = [memory[kp.SIZES + 3 * s:kp.SIZES + 3 * s + 3] for s in range(3)]
    size_rows = "".join(
        f"<tr><td>{kd.SHAPES.get(i, i)}</td><td>{hx}</td><td>{hy}</td><td>{128 - hx} to "
        f"{128 + hx}</td><td>{128 - hy} to {128 + hy}</td><td>${floor:02X}</td></tr>"
        for i, (hx, hy, floor) in enumerate(sizes))
    pushable = []
    for index in range(kp.BLOCK_TYPE_COUNT):
        _, parts = kp.block_type_parts(memory, index)
        if any(p[4] & 0x04 for p in parts):
            types = ", ".join(str(p[0]) for p in parts if p[4] & 0x04)
            pushable.append(f'<a href="Templates.html#template{index}">'
                            f"{kp._esc(kd.BLOCK_NAMES[index])}</a> (type {types})")
    log("  running the collision code on some set pieces...")
    rows = _collision_rows(castle)
    figures = []
    for object_type, what in ((TABLE, "The table, type 84"), (85, "The chest, type 85"),
                              (MOVEABLE, "The block called moveable, type 62")):
        name, image = _sprite(memory, object_type, image_dir)
        figures.append(f'<div class="kl-item">{_img(name, image, "kl-sprite")}'
                       f"<p>{what}.</p></div>")

    return "\n".join([
        '<div class="kl-list">',
        "<p>Everything that moves in Knight Lore moves the same way. Its handler sets a "
        "velocity -- dX, dY and dZ, in bytes +$09 to +$0B of its record -- and #R$CB45 "
        "cuts that velocity short wherever it would carry the object's box into the floor, "
        "a wall or another object's box; #R$C706 then adds what is left to the position. "
        "Most handlers get there through #R$C700, which first takes one off dZ: that is "
        "all gravity is. The player's legs get there through #R$C9CD. The same routine is "
        "where objects push, carry and harm one another.</p>",

        "<h3>Z, then X, then Y, a unit at a time</h3>",
        "<p>#R$CB45 takes the three parts of a move in a fixed order, Z first, and each "
        "one twice: against the room (#R$CA5A for the floor, #R$CCDD and #R$CD08 for the "
        "walls), then against every other object (#R$CC38, #R$CB9A, #R$CBE9). Each test "
        "counts the parts already accepted and none of the later ones. So Z is tested "
        "where the object stands now, before it has moved sideways; X with the Z move made; "
        "Y with both.</p>",
        "<p>A part is shortened one unit at a time (#R$CA89), with the test made again "
        "after every unit, until the box fits or nothing is left; the cost grows with the "
        "overlap. Because the axes are separate, a diagonal step into a wall keeps the "
        "part along the wall and loses the part into it: blocked moves slide.</p>",
        "<p>While it works, the mover sets bit 1 of its own +$07 -- \"leave me out of "
        "collisions\" -- so it does not collide with itself, and clears it at the end "
        "(#R$CB8C). An object that has the bit set already is skipped by every scan "
        "(#R$B538) and is not clipped at all: the player's top half, which only follows "
        "the legs, and the cauldron's bubbles while they rise.</p>",

        "<h3>The room</h3>",
        "<p>The floor is the only limit in Z: Z + dZ may not go below the floor's height, "
        "$5BAE. There is no ceiling. Across the room the footprint -- the centre, plus or "
        "minus the half-size -- has to stay strictly inside the room's half-width either "
        "side of its centre, 128. The three room sizes, from #R$6248 (see "
        '<a href="RoomStructure.html">room structure</a>):</p>',
        '<table class="kl-table"><tr><th>Size</th><th>Half x</th><th>Half y</th>'
        "<th>X from</th><th>Y from</th><th>Floor</th></tr>" + size_rows + "</table>",
        "<p>Two things switch the wall test off: the player's walk into a new room (the "
        "top four bits of +$0C, counting down) and bit 0 of +$07, which an archway sets on "
        "the player while he is close to it (#R$C7DB). That is how he gets into an arch at "
        "all. The arch's pillars are objects, so they still stop him.</p>",

        "<h3>Other objects</h3>",
        "<p>Another box stops a move along one axis if it overlaps the mover on the other "
        "two and would overlap on this one after the move. On X and Y, overlapping means "
        "the centres are closer than the two half-sizes added (#R$CC9D, #R$CCB2); on Z, "
        "that the bases are closer than the height of the lower box (#R$CCC7). Exactly "
        "touching is not overlapping, so things can stand flush against each other and on "
        "top of each other. Every record that is not empty and not marked with bit 1 of "
        "+$07 is solid -- walls, blocks, creatures and charms alike. A part cut short "
        "sets a bit in the mover's +$0C: bit 0 for X, 1 for Y and 2 for Z. Bit 2 is how "
        "an object knows it is standing on something.</p>",

        "<h3>The game's code, tried</h3>",
        "<p>Each row is a situation set up in an otherwise empty object table and handed "
        "to #R$CB45 in a simulator when this page was built, in a square room; the answer "
        "is whatever the game's code made of it. Moves are dX, dY, dZ.</p>",
        '<table class="kl-table"><tr><th>Situation</th><th>Asked for</th>'
        "<th>Allowed</th><th>What else changed</th></tr>" + "".join(rows) + "</table>",

        "<h3>Harm</h3>",
        "<p>Contact is also how harm passes, through three bits of +$0D: bit 7, harms what "
        "it runs into; bit 5, harms what runs into it; bit 6, has been harmed. Whenever a "
        "scan finds the mover touching an obstacle, on any axis, the mover's bit 7 becomes "
        "the obstacle's bit 6 and the obstacle's bit 5 becomes the mover's bit 6. Bit 6 is "
        "what the player dies of: his legs' handler (#R$C82B) looks at it every frame. "
        "Guards, fires, spikes and the like set both 7 and 5 (#R$B85C), so it makes no "
        "difference which of the two moved; the portcullis (#R$C6BD) sets bit 7 on itself, "
        "so it harms what it comes down on. The names for bits 7 and 5 are inferred from "
        "that rule and the portcullis, and where else bit 5 comes from has not been "
        "traced.</p>",

        "<h3>Pushing</h3>",
        "<p>If the obstacle has bit 2 of +$07 set, a blocked X or Y move also copies the "
        "mover's whole intended dX or dY into the obstacle's velocity. That is all the "
        "collision code does: it does not move the obstacle, and it stops the mover just "
        "the same. The obstacle moves when its own handler runs, later in the same pass "
        "over the object table -- the player is record 0, so he always goes first -- and "
        "what it does then is up to the handler:</p>",
        '<table class="kl-table"><tr><th>Object</th><th>Handler</th><th>What a push does'
        "</th></tr>"
        "<tr><td>table (84)</td><td>#R$C4C3</td><td>Moves by its velocity, then clears it: "
        "one step for every frame it is pushed, and it stops when the pushing stops.</td></tr>"
        "<tr><td>chest (85)</td><td>#R$C4B6</td><td>Moves by its velocity and keeps it, "
        "so by the code it slides on. Not tried.</td></tr>"
        "<tr><td>the block called moveable (62)</td><td>#R$C4AA</td><td>Clears its velocity "
        "before moving, so every push is cancelled.</td></tr>"
        "<tr><td>a charm (96 to 102)</td><td>#R$C28B</td><td>Moves, and stops again once it "
        "has moved: a step per push, like the table.</td></tr></table>",
        "<p>Watched in a running game, in room $8E with the ghost removed: a table put in "
        "the player's path was pushed from x 157 to 129 in 20 frames of walking into it, "
        "and stayed at 129 when he stopped. The same table with its type changed to 62 did "
        "not move at all in 20 frames, and the player stopped against it. So the block "
        "the game calls moveable cannot be moved; whether that was meant is not known.</p>",
        "<p>The templates that set bit 2, read from #R$6BD1: " + ", ".join(pushable)
        + ". Charms get it from #R$C525, which gives their records the flags $14.</p>",
        *figures,

        "<h3>Landing and being carried</h3>",
        "<p>A blocked Z move does two things more. The obstacle gets bit 3 of +$0D, "
        "something has landed on it; the block that sinks while it is stood on (#R$B683) "
        "waits for that bit. And if the mover has bit 2 of +$07 -- the player does -- it "
        "takes on the obstacle's dX and dY wherever its own are zero. Because Z is "
        "settled first, that borrowed velocity is then tested against the walls and the "
        "other objects like any other and made in the same move: standing on something "
        "that moves carries you with it.</p>",
        "</div>"])


# --------------------------------------------------------------------------
# Day and night.
# --------------------------------------------------------------------------

def sun_window(castle, sun_type: int, x: int):
    """The sun or moon's window as the game draws it with the sun or moon at
    pixel x: display_sun_moon_frame, then the window's colours."""
    from skoolkit.simutils import IXh, IXl

    memory = list(castle.memory)
    memory[SUN_MOON] = sun_type
    memory[SUN_MOON + 0x1A] = x
    memory[GAME_COMPLETE] = 0
    registers = list(castle.registers)
    registers[IXh], registers[IXl] = SUN_MOON >> 8, SUN_MOON & 0xFF
    memory, registers = castle._call(memory, DISPLAY_SUN_MOON_FRAME, registers)
    memory, registers = castle._call(memory, COLOUR_PANEL, registers)
    memory, registers = castle._call(memory, COLOUR_SUN_MOON, registers)
    return kp._screen(memory).crop(WINDOW)


def _strip(images, gap: int = 4):
    from PIL import Image

    width = sum(i.width for i in images) + gap * (len(images) - 1)
    height = max(i.height for i in images)
    strip = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    x = 0
    for image in images:
        strip.paste(image, (x, 0))
        x += image.width + gap
    return strip


def _daynight_page(memory, castle, image_dir: Path, log) -> str:
    heights = list(memory[SUN_MOON_YOFF:SUN_MOON_YOFF + 13])
    steps = SUN_END - SUN_START
    log("  drawing the sun's window with the game's code...")
    positions = list(range(SUN_START, SUN_END, 8))
    if positions[-1] != SUN_END - 1:
        positions.append(SUN_END - 1)
    sun_strip = _strip([sun_window(castle, SUN, x) for x in positions])
    sun_strip.save(image_dir / "sun_path.png")
    moon = sun_window(castle, MOON, 200)
    moon.save(image_dir / "moon_window.png")

    sprites = []
    for object_type, what in ((SUN, "The sun, type 88"), (MOON, "The moon, type 89")):
        name, image = _sprite(memory, object_type, image_dir)
        sprites.append(f'<div class="kl-item">{_img(name, image, "kl-sprite")}'
                       f"<p>{what}.</p></div>")
    spin = []
    for object_type in range(92, 96):
        name, image = _sprite(memory, object_type, image_dir)
        spin.append(_img(name, image, "kl-sprite", f"type {object_type}"))
    bodies = []
    for legs, what in ((18, "the knight"), (18 ^ 0x20, "the werewolf")):
        cells = []
        for object_type in (legs + 16, legs):
            name, image = _sprite(memory, object_type, image_dir)
            cells.append(_img(name, image, "kl-sprite", f"type {object_type}"))
        bodies.append(f'<div class="kl-item">{" ".join(cells)}<p>{what.capitalize()}: '
                      f"the top half (type {legs + 16}) and the legs (type {legs}).</p></div>")
    positions_text = ", ".join(str(x) for x in positions)

    return "\n".join([
        '<div class="kl-list">',
        "<p>Knight Lore's clock is a picture: the sun or the moon crossing a small window "
        "at the bottom right of the screen. When one has crossed, the other takes its "
        "place; at sunset the knight turns into a werewolf and at sunrise back again. "
        "Every sunrise is a new day, and the fortieth ends the game.</p>",

        "<h3>The sun and the moon</h3>",
        "<p>The sun or moon is not one of the forty objects but a 32-byte record of its "
        "own at #R$C44D, laid out like one so that the ordinary sprite printer (#R$D718) "
        "can draw it. Its type is 88 for the sun and 89 for the moon, and bit 0 of that "
        "byte is how the rest of the game tells night from day. (That 88 is the sun is "
        "inferred: it is the one every game starts with, the one whose return adds a day, "
        "and the one coloured yellow.) #R$C46D puts the sun at the left of the window at "
        "the start of a game.</p>",
        *sprites,
        "<p>Every eighth frame, as the renderer finishes (#R$D653 calls #R$C397), the "
        "record moves one pixel to the right, and #R$C3A4 gives it a height from the "
        "thirteen bytes at #R$C440 -- " + ", ".join(str(h) for h in heights) + " -- one "
        "for every four pixels across, so it climbs, levels off and sinks. #R$C3C3 then "
        "clears the window in the buffer, draws the sun or moon, draws the two halves of "
        "the window's frame (types 90 and 186) over it, and copies the window to the "
        "screen. Because the frame goes on last, the sun rises from behind the frame's "
        "left side and sets behind its right.</p>",
        f'<div class="kl-item">{_img("sun_path.png", sun_strip)}<p>The window drawn by '
        f"#R$C3A4 in a simulator with the sun at pixel x {positions_text}.</p></div>",
        f'<div class="kl-item">{_img("moon_window.png", moon)}<p>And with the moon, at '
        "200.</p></div>",
        f"<p>It starts at pixel x {SUN_START}. When it reaches {SUN_END}, after {steps} "
        f"steps -- {steps * 8} frames -- #R$C3FF swaps the type, recolours the window "
        "(#R$D30D: yellow for the sun, white for the moon) and starts the other at "
        f"{SUN_START}. A frame here is one pass of the game's loop, and that varies with "
        "how much there is to draw (#R$B000 pads a quiet frame out to a minimum), so a "
        "day has no fixed length in seconds.</p>",

        "<h3>The change</h3>",
        "<p>Every swap sets $5BB1 to 1: a change is due. Nothing happens at once. The "
        "player's legs handler calls #R$C306 first thing every frame, and it starts the "
        "change only when the player is not walking into a new room (the top four bits of "
        "+$0C) and not in the middle of a jump (bit 3). When it does start:</p>",
        "<ul><li>it throws away its own return address, so the rest of the player's frame "
        "is skipped: no controls and no movement for as long as the change lasts;</li>"
        "<li>it saves the player's type in $5BB1 and sets +$10 to 8, a count of steps;</li>"
        "<li>it erases the top half (type 1) and turns the legs into one of four spinning "
        "figures, types 92 to 95.</li></ul>",
        f'<div class="kl-item">{" ".join(spin)}<p>Types 92 to 95, the figures of the '
        "change.</p></div>",
        "<p>From then on the legs are run by #R$C337. Every fourth frame (#R$C349) it "
        "makes a sound, counts a step off, and shows another of the four figures at random "
        "-- never the one already showing -- mirrored each time, which makes it spin "
        "(#R$C357). After eight steps, 32 frames, #R$C377 flips bit 5 of the saved type: "
        "XOR $20 turns the knight's legs (types 16 to 29) into the werewolf's (48 to 61) "
        "or back, keeping the walking frame and the way he faces. The top half comes back "
        "as the new type plus 16, and $5BB1 is cleared.</p>",
        *bodies,
        "<p>He can still die while he changes: #R$C337 looks at the harm bit (bit 6 of "
        '+$0D; see <a href="Collision.html">collision</a>) just as the legs\' own handler '
        "does. Dying cancels the change: #R$D12A, which starts every life, clears $5BB1 "
        "and brings him back as knight or werewolf by bit 0 of the sun or moon's type, so "
        "the new body already suits the time of day.</p>",

        "<h3>Days</h3>",
        "<p>When the moon gives way to the sun, #R$C419 adds one to the day count at "
        "$5BB9, kept in binary-coded decimal for printing. The count starts at 0, with the "
        "rest of the variables. The dawn that takes it to 40 jumps to #R$BA22, game over; "
        "any other prints the new number (#R$BC66) and copies it to the screen. The "
        "summary at the end shows the same count as the days taken.</p>",
        "<p>Once the fourteenth charm is in the cauldron, $5BC3 is set and #R$C3A4 returns "
        "at once: the sun stops where it is, so no more days pass and no more changes are "
        'asked for (see <a href="Charms.html">the charms</a>).</p>',

        "<h3>What cares which he is</h3>",
        "<p>The body is the type of object 0, the player's legs, and anything that wants "
        "to know reads that. (That types 16 to 29 are the knight and 48 to 61 the werewolf "
        "comes from how the handler table groups them; the code only ever tests "
        "ranges.)</p>",
        "<ul><li>The bouncing balls (types 182 and 183, #R$B5FF) test it every frame and "
        "patch two jumps in their own code (#R$B65D, #R$B676) to suit: while the legs are "
        "the knight's the balls hop away from him, and otherwise -- the werewolf, or the "
        "knight part-way through changing -- they hop towards him.</li>"
        "<li>The bubbles over the cauldron (types 160 to 163, #R$B8DA) rise harmlessly and "
        "show the next charm the wizard wants. If the legs are the werewolf's they set "
        "bit 2 of their type instead, becoming types 164 to 167, turn solid and fly at "
        "the player; their starting record (#R$B8C8) made them deadly both ways, so now "
        "they kill.</li>"
        "<li>A new life takes its body from the time of day, as above.</li></ul>",
        "</div>"])


# --------------------------------------------------------------------------
# The charms and the cauldron.
# --------------------------------------------------------------------------

def _decode_text(memory, address: int) -> str:
    """A string in the game's text code: $00-$09 digits, $0A-$23 letters,
    $26 a space; bit 7 on the last character."""
    out = []
    while True:
        byte = memory[address]
        code = byte & 0x7F
        if code <= 0x09:
            out.append(chr(ord("0") + code))
        elif code <= 0x23:
            out.append(chr(ord("a") + code - 0x0A))
        else:
            out.append(" ")
        if byte & 0x80:
            return "".join(out).strip()
        address += 1


def ratings(memory) -> list[str]:
    """The eight rating words, in the order of the table at $BBB7 (each
    string starts with its colour byte)."""
    return [_decode_text(memory, kp._word(memory, RATING_TBL + 2 * i) + 1) for i in range(8)]


def _charms_page(memory, castle, image_dir: Path, log) -> str:
    colours = list(memory[OBJECT_ATTRIBUTES:OBJECT_ATTRIBUTES + 8])
    kinds = []
    for kind in range(8):
        object_type = CHARM + kind
        name, image = _sprite(memory, object_type, image_dir)
        cells = [_img(name, image, "kl-sprite", f"type {object_type}")]
        if kind < 7:
            tint = _attribute_colour(colours[object_type & 0x0F])
            tinted, tinted_image = _sprite(memory, object_type, image_dir, tint)
            cells.append(_img(tinted, tinted_image, "kl-sprite", "as carried"))
            what = (f"Charm {kind}, type {object_type}: as it lies in a room, and in its "
                    f"colour on the panel (attribute ${colours[object_type & 0x0F]:02X}).")
        else:
            what = f"The extra life, type {object_type}."
        kinds.append(f'<div class="kl-item">{" ".join(cells)}<p>{what}</p></div>')

    thumbs = {}
    for object_type in range(CHARM, EXTRA_LIFE + 1):
        name, image = _sprite(memory, object_type, image_dir)
        thumbs[object_type] = f'<img class="kl-thumb" src="{IMAGE_URL}/{name}" alt="type {object_type}">'

    # One deal: the table as init_special_objects left it when the simulator
    # ran the game's set-up for these pages.
    deal_rows = []
    for i in range(kd.CHARM_PLACE_COUNT):
        entry = kd.CHARM_PLACES + kd.CHARM_PLACE_SIZE * i
        object_type, x, y, z, room = castle.memory[entry:entry + 5]
        what = "extra life" if object_type == EXTRA_LIFE else f"charm {object_type - CHARM}"
        deal_rows.append(f"<tr><td>{i}</td><td>{kp._room_link(room)}</td><td>{x}</td>"
                         f"<td>{y}</td><td>{z}</td><td>{thumbs.get(object_type, '')} "
                         f"{object_type}: {what}</td></tr>")
    rooms_used = {castle.memory[kd.CHARM_PLACES + kd.CHARM_PLACE_SIZE * i + 4]
                  for i in range(kd.CHARM_PLACE_COUNT)}

    wanted = list(memory[OBJECTS_REQUIRED:OBJECTS_REQUIRED + 14])
    wanted_cells = "".join(f"<td>{n + 1}<br>{thumbs[CHARM + k]}<br>charm {k}</td>"
                           for n, k in enumerate(wanted))

    log("  drawing the wizard's room...")
    wizard = castle.draw(WIZARDS_ROOM)
    wizard.save(image_dir / "wizards_room.png")

    words = ratings(memory)
    rating_rows = "".join(
        f"<tr><td>{32 * band + 1} to {32 * band + 32}</td><td>{words[band]}</td>"
        f"<td>{words[4 + band]}</td></tr>" for band in range(4))
    room_count = len(kp.rooms(memory))

    return "\n".join([
        '<div class="kl-list">',
        "<p>The quest in Knight Lore is to bring the wizard fourteen charms, in the order "
        "he asks for them, and drop each into his cauldron. This page follows a charm from "
        "where the game puts it at the start to the end of the game.</p>",

        "<h3>Eight kinds, 32 places</h3>",
        "<p>The special-object table at #R$6FF2 has 32 entries of nine bytes: the type "
        "(0 once the object has left the world), where it starts -- x, y, z and room -- and "
        "where it is now, in the same order. The places are fixed; what lies in each is "
        "not. At the start of every game #R$C47E deals the kinds in rotation from a "
        "starting kind taken from the seed at $5BA0 plus the refresh register: entry n "
        "gets type 96 + ((start + n) AND 7). So neighbouring entries hold neighbouring "
        "kinds and each of the eight appears four times, but which place gets which "
        f"changes from game to game. The 32 places are in {len(rooms_used)} different "
        "rooms.</p>",
        "<p>Types 96 to 102 are the seven charms the wizard wants; 103 is an extra "
        "life.</p>",
        *kinds,
        "<p>One deal -- the one the game made when a simulator ran its set-up for these "
        "pages:</p>",
        '<table class="kl-table"><tr><th>Entry</th><th>Room</th><th>x</th><th>y</th>'
        "<th>z</th><th>What lies there</th></tr>" + "".join(deal_rows) + "</table>",

        "<h3>In a room</h3>",
        "<p>The charms are not in the room records. On entering a room, #R$C525 looks "
        "through the table for objects whose current room is this one and builds a record "
        "for each in records 2 and 3 ($5C48 and $5C68): 5 by 5 by 12, with the flags $14 "
        "(draw it; it can be pushed), and the address of its table entry at +$10. On "
        "leaving, #R$C591 writes each one's position back through that address, so a "
        "charm stays where it was pushed or dropped. A charm lying in a room (#R$C28B) "
        "falls under gravity, and when it has just been dropped or has moved it is stopped "
        "and redrawn with a click. Those two records are all there is for special objects, "
        "and in the wizard's room record 3 is taken by the cauldron's bubbles "
        "(#R$B8A9).</p>",

        "<h3>Carrying</h3>",
        "<p>Up to three charms are carried, in four-byte slots at $5BD8: slot 0 for "
        "staging, never shown, and slots 1 to 3, drawn on the panel from left to right "
        "(#R$BF4E) in the colours at #R$BFD3. A slot keeps the charm's type, its flags "
        "and the address of its table entry. They form a queue: the first picked up is "
        "the first put down.</p>",
        "<p>One press of pick up / drop does one thing (#R$C00E), and only when the "
        "player is inside the room's walls, not jumping and standing on something:</p>",
        "<ul><li><b>Picking up</b> comes first. A charm counts as touching if it overlaps "
        "the player's box enlarged by 4 in width, depth and height and lowered by 4 "
        "(#R$C17A), so one under his feet or beside him will do. #R$C141 puts it in slot "
        "0, zeroes the type in its table entry -- so leaving the room will not put it back "
        "-- and wipes its record. Then #R$C12B moves the slots along. With three already "
        "carried, the oldest is put down where the new one was, in the same record: "
        "picking up swaps.</li>"
        "<li><b>Dropping</b> happens when there is nothing to pick up and one of the two "
        "records is free -- in the wizard's room only record 2 (#R$C08C). #R$C0B2 puts "
        "the oldest charm, in slot 3, at the player's x, y and z, and lifts both of his "
        "records by 12, a charm's height, so that he ends up standing on it: that is how "
        "charms become steps. It is refused if anything lies within 12 units above his "
        "head ($5BD3, found with #R$B4FD before the drop), since he would be lifted into "
        "it. If slot 3 is empty the slots just move along, bringing the next charm to the "
        "front.</li></ul>",
        "<p>The extra life (#R$C1AB) is never carried: touching it -- the player's box "
        "widened by 1 -- adds a life, clears its table entry and makes it vanish.</p>",

        "<h3>What the wizard wants</h3>",
        "<p>The order is the fourteen bytes at #R$C27D: the kinds 0 to 6 (a charm's type "
        "AND 7), each twice. As the game is loaded it reads:</p>",
        f'<table class="kl-table"><tr>{wanted_cells}</tr></table>',
        "<p>At the start of every game #R$B544 rotates the list left by 4 to 7 places, "
        "chosen by the seed. The rotation is made in place and never undone, so the first "
        "game after loading can ask for only four orders, and each later game carries on "
        "from where the last one left it; the fourteen never change, only where they "
        "start. $5BBB counts the right ones delivered, and #R$C274 uses it to find the "
        "next one wanted. The cauldron's bubbles use the same lookup to show that charm "
        "above the cauldron, for one frame in five (#R$B8DA, as types 168 to 175).</p>",
        f'<div class="kl-item"><img class="kl-scene" src="{IMAGE_URL}/wizards_room.png" '
        f"alt=\"Room ${WIZARDS_ROOM:02X}\"><p>The wizard's room, "
        f"{kp._room_link(WIZARDS_ROOM)}, drawn by the game.</p></div>",

        "<h3>Into the cauldron</h3>",
        "<p>A charm goes in by being dropped in the wizard's room with the player's z at "
        "$98 or more. (That this means standing on the cauldron is inferred from the height "
        "the charm then rises to; the cauldron's size was not checked.) #R$C0B2 sets bit 3 "
        "of its type, making it one of types 104 to 110, and sets $5BC4, which makes "
        "#R$D022 read no controls until the charm is used up. The new type's handler "
        "(#R$C1F1) steers it a unit a frame in x and y towards the middle of the room, "
        "(128, 128), rising to $98; once it is over the middle it falls with collisions "
        "switched off, through the cauldron's top, until z is $80 (#R$C238). Then "
        "#R$C245 compares its kind with the one wanted next:</p>",
        "<ul><li>the right one adds to $5BBB and the screen's colours cycle -- sixteen "
        "passes, each stepping the ink of every attribute cell on by one, with a burst of "
        "noise (#R$C2A5);</li>"
        "<li>a wrong one counts for nothing.</li></ul>",
        "<p>Either way it is used up (#R$C265): its table entry is zeroed, it vanishes, "
        "and the controls come back. A wrong charm is lost, not returned. There are four "
        "of each kind and the wizard wants two. A charm can also be lost by being pushed "
        "or dropped into the same space as something else: the depth sort destroys a "
        'charm whose box intersects another (see <a href="DepthSort.html">the depth '
        "sort</a>).</p>",

        "<h3>The end</h3>",
        "<p>The fourteenth right charm calls #R$C2CC. It sets $5BC3, the game won, which "
        "stops the sun (#R$C3A4), keeps the controls dead and stops the player dying. It "
        "erases records 3 to 13 and turns every stone block still in the room (type 7) "
        "into type 131, and their handler (#R$B566) climbs to z $A4 and then flies at the "
        "player; the first to come within 6 units of him in x and y calls #R$BA22. With "
        "$5BC3 set, game over first shows the completion message and plays its tune "
        "(#R$BAAB), then the summary as for any other ending. The other two ways to end "
        'are the fortieth day (see <a href="DayNight.html">day and night</a>) and the '
        "lives running out (#R$D12A).</p>",

        "<h3>The percentage and the rating</h3>",
        "<p>The summary (#R$BA29) shows the days taken, the charms delivered, a percentage "
        "and a rating. #R$BC10 counts the rooms visited -- the set bits of the 32-byte map "
        "at $5BE8, one bit per room number, set on entering each room (#R$D219) -- and "
        "works out (rooms + 2 x charms) x 100 / 156, where 156 is 128 rooms plus the 14 "
        f"charms counted twice. (The castle has {room_count} room records.) There is no "
        "divide: 100/156 as a 16-bit fraction, $A41A, is added once for every point, and "
        "each carry out adds one to a decimal total. 156 of those fall exactly $28 short "
        "of 100, so a final $28 is added; without it a perfect game would show 99.</p>",
        "<p>The rating is chosen by whether the quest was completed and by the rooms "
        "visited, in steps of 32 -- the index is 4 for a completed quest, plus (rooms - "
        "1) / 32 -- into the eight words at #R$BBB7:</p>",
        '<table class="kl-table"><tr><th>Rooms visited</th><th>Not completed</th>'
        "<th>Completed</th></tr>" + rating_rows + "</table>",
        "<p>As the table shows, the second word ranks below the third, and the best "
        "rating of all needs most of the castle explored as well as the quest done.</p>",
        "</div>"])


# --------------------------------------------------------------------------

def build(memory, html_dir: Path, log=print) -> dict[str, str]:
    """Draw the pictures into html_dir/images/howitworks and return the four
    pages' HTML by section name."""
    image_dir = Path(html_dir) / "images" / "howitworks"
    image_dir.mkdir(parents=True, exist_ok=True)
    log("Writing the how-it-works pages...")
    castle = kp.Castle(memory)
    return {
        "DepthSort": _depth_page(memory, castle, image_dir, log),
        "Collision": _collision_page(memory, castle, image_dir, log),
        "DayNight": _daynight_page(memory, castle, image_dir, log),
        "Charms": _charms_page(memory, castle, image_dir, log),
    }
