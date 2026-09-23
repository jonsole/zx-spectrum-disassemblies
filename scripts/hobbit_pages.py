"""The Hobbit's reference pages: locations, objects, characters and actions.

scripts/hobbit.ref lays out the HTML disassembly's index and its prose pages,
and is committed: it is addresses and prose. These four pages are different.
They are the game's own content -- every room's name and description, every
object's name, and a picture of each location that has one -- so, like the
decoded messages in the .skool file, they are generated from the game on every
build into game_disassembly/, which is gitignored, and never committed.

Everything is read from the game rather than written down: the rooms from
ROOM_POINTERS, the objects from OBJECT_INDEX, the characters from CHARACTERS,
the actions from ACTION_PATTERNS and ACTION_TABLE. Text is printed by the game
itself, captured at PRINT_CHAR (see Hobbit.message), and each picture is drawn
by the game's own DRAW_LOCATION_PICTURE in SkoolKit's simulator, then saved as
a PNG -- so what is shown is what the game draws, not a reimplementation of it.
"""
from __future__ import annotations

import html
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import build_hobbit as bh

DRAW_LOCATION_PICTURE = 0x7F78
RETURN_HERE = 0x0010            # a return address nothing in the game runs at
PICTURES_ON = 0xB707
PAGE_DIR = "reference"          # where [Paths] in hobbit.ref puts the pages
IMAGE_DIR = "images/locations"
# Where to put the stack for a call made from outside. Not in the game's
# data: the flood fill keeps its queue on the stack, and a stack at $BF00
# pushed it into the room records below and broke the next picture. $5E80 is
# below where the game's own stack runs (from $5EFF) and above the BASIC
# loader, which the game has finished with.
SCRATCH_STACK = 0x5E80

# The Spectrum's colours, indexed by BRIGHT * 8 + the colour number: bit 1 of
# the number is red, bit 2 green and bit 0 blue.
PALETTE = [((level if c & 2 else 0), (level if c & 4 else 0), (level if c & 1 else 0))
           for level in (0xD7, 0xFF) for c in range(8)]

FLAG_NAMES = {7: "present", 6: "character", 5: "open", 3: "dead or broken",
              2: "full", 1: "liquid", 0: "locked"}
SIDES = {0x10: "the player's", 0x20: "the goblins'", 0x40: "the elves'"}
PLACED = ["in", "on", "behind", "under", "tied to"]


def esc(text: str) -> str:
    """Text for a ref file section: HTML-escaped, and with nothing SkoolKit
    would read as a macro."""
    return html.escape(text).replace("#", "&#35;")


def _pattern_words(memory, code: int) -> str:
    start = 0xAB4B + 8 * code
    words = []
    for k in (0, 2, 4):
        reference = memory[start + k] | (memory[start + k + 1] << 8)
        if reference & 0x0FFF:
            words.append(bh.word_at(memory, reference).upper())
    if code <= 10:
        last = memory[start + 6] | (memory[start + 7] << 8)
        words.insert(0, bh.word_at(memory, last).upper())
    return " ".join(words)


def _object_names(memory, records) -> dict[int, str]:
    return {r["number"]: bh.name_of(memory, r["start"] + 8) for r in records}


# A frame of the animation per frame of the Spectrum: 69888 T-states, the
# 50 Hz interrupt the display refreshes on, so each frame of the animation
# is what a television showed at the time.
FRAME_TSTATES = 69888
FRAME_MS = 20
# How long the finished picture stays up before the drawing starts again.
HOLD_MS = 3000


def screen_image(memory):
    """The top 128 scanlines of the screen -- the picture canvas -- as a PIL
    image, in the Spectrum's colours.

    Done with PIL's own operations rather than a pixel at a time, since an
    animation takes a few hundred of these per picture: the bitmap is put back
    into scanline order and made a mask, the attributes are blown up into an
    ink layer and a paper layer, and the mask chooses between them.
    """
    from PIL import Image

    rows = bytearray()
    for y in range(128):
        row = 0x4000 | ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2)
        rows += bytes(memory[row:row + 32])
    mask = Image.frombytes("1", (256, 128), bytes(rows)).convert("L")
    attributes = bytes(memory[0x5800:0x5800 + 16 * 32])
    ink = Image.new("RGB", (32, 16))
    paper = Image.new("RGB", (32, 16))
    ink.putdata([PALETTE[(8 if a & 0x40 else 0) + (a & 7)] for a in attributes])
    paper.putdata([PALETTE[(8 if a & 0x40 else 0) + ((a >> 3) & 7)] for a in attributes])
    ink = ink.resize((256, 128), Image.NEAREST)
    paper = paper.resize((256, 128), Image.NEAREST)
    return Image.composite(ink, paper, mask)


def _render_picture(game, location: int, room_start: int, player_start: int,
                    clean: list):
    """Draw one location's picture with the game's own code, and return the
    finished picture and the frames of it being drawn, one at each frame
    interrupt of the game's own time -- so the animation runs at the speed the
    game draws, slow fills and all.

    Each picture starts from the same clean machine, `clean`: drawing one
    leaves enough behind -- the flood fill's queue on the stack among it --
    that the next, drawn straight after, can fail to finish.
    """
    from skoolkit.simutils import A, PC, SP, T

    memory, registers = game.memory, game.sim.registers
    memory[:] = clean
    # The picture is drawn only if the player could see it: stand the player
    # there, with the room lit, for the length of the call.
    memory[room_start] |= 0x80
    memory[player_start + 16] = location
    memory[PICTURES_ON] = 1
    stack = SCRATCH_STACK
    memory[stack], memory[stack + 1] = RETURN_HERE & 0xFF, RETURN_HERE >> 8
    registers[SP], registers[A] = stack, location
    frames = []
    pc, limit = DRAW_LOCATION_PICTURE, registers[T] + 60 * bh.TSTATES_PER_SECOND
    while registers[T] < limit:
        # To the next frame boundary, as the ULA counts them.
        frame_end = (registers[T] // FRAME_TSTATES + 1) * FRAME_TSTATES
        game.sim.trace(pc, RETURN_HERE, 0, frame_end,
                       False, None, None, None, None, None)
        pc = registers[PC]
        frames.append(screen_image(memory))
        if pc == RETURN_HERE:
            break
    if pc != RETURN_HERE:
        raise RuntimeError(f"location {location}'s picture did not finish")
    return frames[-1], frames


def save_animation(frames, path: Path) -> float:
    """Save the drawing as a GIF that loops, holding the finished picture for
    HOLD_MS before it starts again. Frames that show no change are merged into the one before, so
    the long pause while a fill runs costs nothing. Returns the seconds it
    takes to draw."""
    kept, durations = [frames[0]], [FRAME_MS]
    for frame in frames[1:]:
        if frame.tobytes() == kept[-1].tobytes():
            durations[-1] += FRAME_MS
        else:
            kept.append(frame)
            durations.append(FRAME_MS)
    durations[-1] += HOLD_MS
    kept[0].save(path, save_all=True, append_images=kept[1:], duration=durations,
                 optimize=True, disposal=1, loop=0)
    return len(frames) * FRAME_MS / 1000


# The map: where each location goes on a grid, and how big things are drawn.
# Up and down have no place on a flat map, so they borrow the diagonals a
# staircase would be drawn on: up is north-east, down south-west.
STEP = {1: (0, -1), 2: (0, 1), 3: (1, 0), 4: (-1, 0), 5: (1, -1), 6: (-1, -1),
        7: (1, 1), 8: (-1, 1), 9: (1, -1), 10: (-1, 1)}
CELL_W, CELL_H = 190, 118       # one grid cell
THUMB_W, THUMB_H = 128, 64      # a picture, at half the canvas's size


def map_layout(rooms: dict, first: int = 1) -> dict[int, tuple[int, int]]:
    """A grid position for every location, found by walking out from `first`.

    Each location reached goes one step from the place it was reached from,
    in the direction of the exit -- north up, east right. The Hobbit's map is
    not consistent enough for that always to be free (the goblins' gate sends
    nearly every direction to one cavern), so a taken cell gives way to the
    nearest free one. Anything the walk never reaches is laid out the same
    way below the rest.
    """
    placed: dict[int, tuple[int, int]] = {}
    taken: set[tuple[int, int]] = set()

    def put(location: int, want: tuple[int, int]) -> None:
        x0, y0 = want
        for radius in range(0, 40):
            ring = [(x0 + dx, y0 + dy) for dx in range(-radius, radius + 1)
                    for dy in range(-radius, radius + 1)
                    if max(abs(dx), abs(dy)) == radius]
            ring.sort(key=lambda c: (abs(c[0] - x0) + abs(c[1] - y0), c[1], c[0]))
            for cell in ring:
                if cell not in taken:
                    placed[location] = cell
                    taken.add(cell)
                    return

    def walk(start: int, at: tuple[int, int]) -> None:
        put(start, at)
        queue = [start]
        while queue:
            here = queue.pop(0)
            # Cardinal directions first: they are the ones worth keeping true.
            for _, direction, _, there in sorted(rooms[here]["exits"], key=lambda e: e[1]):
                if there and direction and there in rooms and there not in placed:
                    dx, dy = STEP[direction]
                    put(there, (placed[here][0] + dx, placed[here][1] + dy))
                    queue.append(there)

    walk(first, (0, 0))
    for location in sorted(rooms):
        if location not in placed:
            bottom = max(y for _, y in placed.values()) + 2
            walk(location, (0, bottom))
    return tidy_layout(rooms, placed)


def tidy_layout(rooms: dict, placed: dict[int, tuple[int, int]]) -> dict[int, tuple[int, int]]:
    """Move places about until the map stops getting better.

    The walk puts each place where the first exit it met says, and a
    collision early on can leave a place a long way from its neighbours, with
    long lines across the map to show for it. This looks at every place in
    turn and tries it in each cell nearby -- or swapped with whatever is there
    -- and keeps the change if the exits come out closer to their compass
    directions and the lines shorter. A handful of passes is enough for it to
    settle.
    """
    links = []
    for here, room in rooms.items():
        for _, direction, _, there in room["exits"]:
            if direction and there and there != here and there in placed:
                links.append((here, there, STEP[direction]))
    touching: dict[int, list] = {}
    for link in links:
        touching.setdefault(link[0], []).append(link)
        touching.setdefault(link[1], []).append(link)

    def cost(link, where) -> float:
        a, b, (dx, dy) = link
        (ax, ay), (bx, by) = where[a], where[b]
        # How far b is from where the exit says it should be, and how long
        # the line is: the first keeps the compass true, the second keeps
        # the map from sprawling.
        miss = abs(bx - (ax + dx)) + abs(by - (ay + dy))
        length = max(abs(bx - ax), abs(by - ay))
        return 2.0 * miss + 1.0 * length

    def local(location, where) -> float:
        return sum(cost(link, where) for link in touching.get(location, []))

    at = {cell: location for location, cell in placed.items()}
    for _ in range(12):
        improved = False
        for location in sorted(placed):
            x, y = placed[location]
            for nx in range(x - 2, x + 3):
                for ny in range(y - 2, y + 3):
                    if (nx, ny) == (x, y):
                        continue
                    other = at.get((nx, ny))
                    before = local(location, placed) + (local(other, placed) if other else 0)
                    placed[location] = (nx, ny)
                    if other:
                        placed[other] = (x, y)
                    after = local(location, placed) + (local(other, placed) if other else 0)
                    if after < before - 1e-9:
                        del at[(x, y)]
                        at[(nx, ny)] = location
                        if other:
                            at[(x, y)] = other
                        x, y = nx, ny
                        improved = True
                    else:
                        placed[location] = (x, y)
                        if other:
                            placed[other] = (nx, ny)
        if not improved:
            break
    return placed


def map_svg(rooms: dict, room_name: dict, pictures: set, placed: dict) -> str:
    """The map as inline SVG: a thumbnail or a named box per location, linked
    to its entry, and a line per way between two places -- a head at each end
    it can be taken towards, dashed where it goes through something."""
    xs = [x for x, _ in placed.values()]
    ys = [y for _, y in placed.values()]
    left, top = min(xs), min(ys)
    width = (max(xs) - left + 1) * CELL_W + 40
    height = (max(ys) - top + 1) * CELL_H + 40
    HASH = "&#35;"

    def box(location: int) -> tuple[float, float]:
        x, y = placed[location]
        return (20 + (x - left) * CELL_W + (CELL_W - THUMB_W) / 2, 20 + (y - top) * CELL_H + 8)

    def centre(location: int) -> tuple[float, float]:
        px, py = box(location)
        return px + THUMB_W / 2, py + THUMB_H / 2

    out = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" '
           'style="background: white; font-family: sans-serif">',
           '<defs><marker id="head" viewBox="0 0 10 10" refX="10" refY="5" markerWidth="7" '
           f'markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="{HASH}444"/>'
           '</marker></defs>']

    ways: dict[tuple[int, int], dict] = {}
    for here, room in rooms.items():
        if here not in placed:
            continue
        for _, direction, via, there in room["exits"]:
            if not direction or not there or there not in placed or there == here:
                continue
            way = ways.setdefault((min(here, there), max(here, there)), {"to": set(), "through": False})
            way["to"].add(there)
            way["through"] |= bool(via)
    for (a, b), way in sorted(ways.items()):
        (x1, y1), (x2, y2) = centre(a), centre(b)
        dx, dy = x2 - x1, y2 - y1
        # Stop each end at the edge of the box it meets.
        fx = (THUMB_W / 2 + 2) / abs(dx) if dx else float("inf")
        fy = (THUMB_H / 2 + 14) / abs(dy) if dy else float("inf")
        f = min(fx, fy, 0.45)
        heads = ""
        if a in way["to"]:
            heads += f' marker-start="url({HASH}head)"'
        if b in way["to"]:
            heads += f' marker-end="url({HASH}head)"'
        dash = ' stroke-dasharray="6,4"' if way["through"] else ""
        out.append(f'<line x1="{x1 + dx * f:.0f}" y1="{y1 + dy * f:.0f}" x2="{x2 - dx * f:.0f}" '
                   f'y2="{y2 - dy * f:.0f}" stroke="{HASH}444" stroke-width="1.5"{dash}{heads}/>')

    for location in sorted(placed):
        px, py = box(location)
        name = esc(room_name.get(location, "?"))
        out.append(f'<a href="locations.html{HASH}loc{location}"><title>{location}: {name}</title>')
        if location in pictures:
            out.append(f'<image href="../{IMAGE_DIR}/{location:02d}.png" x="{px:.0f}" y="{py:.0f}" '
                       f'width="{THUMB_W}" height="{THUMB_H}"/>')
            out.append(f'<rect x="{px:.0f}" y="{py:.0f}" width="{THUMB_W}" height="{THUMB_H}" '
                       f'fill="none" stroke="{HASH}222"/>')
        else:
            out.append(f'<rect x="{px:.0f}" y="{py:.0f}" width="{THUMB_W}" height="{THUMB_H}" '
                       f'fill="{HASH}eef" stroke="{HASH}667"/>')
        out.append(f'<text x="{px + THUMB_W / 2:.0f}" y="{py + THUMB_H + 13:.0f}" font-size="11" '
                   f'text-anchor="middle">{location} {name}</text></a>')
    out.append("</svg>")
    return "\n".join(out)


def build(html_dir: Path, out_ref: Path) -> None:
    """Render the pictures into html_dir and write the pages' ref file."""
    from hobbit_drive import Hobbit

    bh._log("Building the reference pages (locations, objects, characters, actions)...")
    game = Hobbit()
    # The live machine, at its first prompt, is used only to print and to
    # draw, each picture from this clean copy of it. Printing and drawing move
    # things in it -- the action patterns were once found zeroed after a run
    # of both.
    clean = list(game.memory)
    # Every table is read from the tape's own data instead, as it is before
    # the game starts. By the first prompt the game has already moved on a
    # turn: Gandalf's first script step gives the player the curious map, so
    # the live machine would say the map starts with the player.
    memory = list(bh.game_memory(bh.OUT_DIR / "hobbit.z80"))
    records = bh.object_records(memory)
    by_number = {r["number"]: r for r in records}
    names = _object_names(memory, records)
    rooms = bh.room_records(memory)
    room_name = {k: bh.name_of(memory, r["start"] + 2) for k, r in rooms.items() if k}
    player = by_number[0]["start"]

    pictures = {key: stream for key, stream, _ in bh.keyed_table(memory, bh.PICTURE_TABLE)}
    scores = {key: value for key, value, _ in bh.keyed_table(memory, 0x8D6E)}
    hooks = {key: value for key, value, _ in bh.keyed_table(memory, 0xC78E)}
    hints = {key: value for key, value, _ in bh.keyed_table(memory, 0x83CD)}
    action_handlers = {key: value for key, value, _ in bh.keyed_table(memory, bh.ACTION_TABLE)}

    # Where each object starts: in which places, or held by what.
    starts_in: dict[int, list[int]] = {}
    for r in records:
        if r["number"] == 0:
            continue
        for i in range(memory[r["start"]]):
            starts_in.setdefault(memory[r["start"] + 16 + i], []).append(r["number"])

    image_dir = html_dir / "hobbit" / IMAGE_DIR
    image_dir.mkdir(parents=True, exist_ok=True)

    def loc_link(location: int) -> str:
        if location == 0 or location not in room_name:
            return "nowhere"
        return f'<a href="locations.html&#35;loc{location}">{esc(room_name[location])}</a>'

    def obj_link(number: int) -> str:
        page = "characters" if number >= 0x3C else "objects"
        return f'<a href="{page}.html&#35;obj{number}">{esc(names.get(number, "?"))}</a>'

    # ------------------------------------------------------------ locations
    loc = ['<div class="hobbit-list">',
           f'<p>The {len(room_name)} places of the game, in the order of ROOM_POINTERS. '
           f'{len(pictures)} have a picture, drawn here by the game\'s own '
           'DRAW_LOCATION_PICTURE (#R$7F78) and shown as it draws, at the speed it draws -- '
           'pausing on the finished picture before it starts again. The rest show only text in the game too. '
           'Each is named as the game names it, and described as it describes it on a '
           'first visit.</p>', '<p>']
    loc.append(" &middot; ".join(f'<a href="&#35;loc{k}">{k}</a>' for k in sorted(room_name)))
    loc.append("</p>")
    drawing_time: dict[int, float] = {}
    for location in sorted(room_name):
        room = rooms[location]
        start = room["start"]
        described = memory[start + 8] | (memory[start + 9] << 8)
        text = game.message(described) if described else ""
        loc.append(f'<h3 id="loc{location}">{location}: {esc(room_name[location])}</h3>')
        loc.append('<table class="hobbit-entry"><tr>')
        if location in pictures:
            image, frames = _render_picture(game, location, start, player, clean)
            image.resize((512, 256)).save(image_dir / f"{location:02d}.png")
            drawing_time[location] = save_animation(frames, image_dir / f"{location:02d}.gif")
            # The animation loops, holding the finished picture a few
            # seconds each time round; a click starts it again at once.
            loc.append(f'<td style="vertical-align: top; width: 520px">'
                       f'<img src="../{IMAGE_DIR}/{location:02d}.gif" width="512" height="256" '
                       f'style="image-rendering: pixelated; cursor: pointer" '
                       f'title="Click to draw it again" '
                       f'onclick="this.src=this.src.split(\'?\')[0]+\'?\'+Date.now()" '
                       f'alt="{esc(room_name[location])}"/></td>')
        loc.append('<td style="vertical-align: top">')
        if text:
            loc.append(f"<p><i>{esc(text)}</i></p>")
        facts = [("Record", f"#R${start:04X}"),
                 ("Light", "lit" if memory[start] & 0x80 else "dark"),
                 ("Placed", ["outside", "inside", "in", "on", "at"][(memory[start] >> 1) & 7]
                  if (memory[start] >> 1) & 7 < 5 else "?")]
        if memory[start + 1] != 0xFF:
            facts.append(("Capacity", str(memory[start + 1])))
        exits = []
        for _, direction, via, destination in room["exits"]:
            if not direction:
                continue
            what = loc_link(destination) if destination else "nowhere yet"
            through = f" (through {obj_link(via)})" if via else ""
            exits.append(f"{bh.DIRECTIONS[direction]}: {what}{through}")
        facts.append(("Exits", "<br/>".join(exits) or "none"))
        here = starts_in.get(location, [])
        things = [obj_link(n) for n in here if n < 0x3C]
        people = [obj_link(n) for n in here if n >= 0x3C]
        if things:
            facts.append(("Objects", ", ".join(things)))
        if people:
            facts.append(("Characters", ", ".join(people)))
        if location in scores:
            facts.append(("First visit", f"{scores[location] / 10:.1f}% (VISIT_SCORES)"))
        if location in hooks:
            facts.append(("On arrival", f"#R${hooks[location]:04X}"))
        if location in hints:
            facts.append(("HELP", f"<i>{esc(game.message(hints[location]))}</i>"))
        if location in pictures:
            facts.append(("Picture", f"#R${pictures[location]:04X} -- drawn in "
                                     f"{drawing_time[location]:.1f} seconds"))
        loc.append("<table>" + "".join(
            f'<tr><td style="vertical-align: top; padding-right: 1em"><b>{k}</b></td><td>{v}</td></tr>'
            for k, v in facts) + "</table>")
        loc.append("</td></tr></table>")
    loc.append("</div>")

    # ------------------------------------------------------------ objects
    def flags_of(value: int) -> str:
        return ", ".join(name for bit, name in FLAG_NAMES.items() if value & (1 << bit)) or "none"

    def handlers_of(r) -> str:
        out, previous = [], None
        for _, code, handler in r["handlers"]:
            if not handler:
                continue
            action = _pattern_words(memory, code) if code else f"after {previous}"
            out.append(f"{esc(action)}: #R${handler:04X}")
            previous = _pattern_words(memory, code) if code else previous
        return "<br/>".join(out) or "none"

    def where_of(r) -> str:
        holder = memory[r["start"] + 1]
        places = [loc_link(memory[r["start"] + 16 + i]) for i in range(memory[r["start"]])]
        text = ", ".join(places) or "nowhere"
        if holder != 0xFF:
            text += f", held by {obj_link(holder)}"
        return text

    def description_of(r) -> str:
        pointer = memory[r["start"] + 14] | (memory[r["start"] + 15] << 8)
        return f"<i>{esc(game.message(pointer))}</i>" if pointer else ""

    obj = ['<p>Every object that is not a character, from OBJECT_INDEX (#R$C063). '
           'Size and weight are bytes 2 and 3 of the record, strength and defence bytes 5 and 6 '
           '(see DO_ATTACK, #R$9171); the flags are byte 7. Handlers are the object\'s own, '
           'which DO_ACTION (#R$950F) asks before the ordinary one.</p>',
           '<table class="hobbit-table"><tr><th>No.</th><th>Object</th><th>Starts</th>'
           '<th>Size</th><th>Weight</th><th>Str</th><th>Def</th><th>Flags</th><th>Own handlers</th></tr>']
    for r in sorted(records, key=lambda r: r["number"]):
        n, s = r["number"], r["start"]
        if n == 0 or n >= 0x3C:
            continue
        obj.append(f'<tr id="obj{n}"><td>${n:02X}</td><td>#R${s:04X}({esc(names[n])})'
                   f'{"<br/>" + description_of(r) if description_of(r) else ""}</td>'
                   f'<td>{where_of(r)}</td><td>{memory[s + 2]}</td><td>{memory[s + 3]}</td>'
                   f'<td>{memory[s + 5]}</td><td>{memory[s + 6]}</td><td>{flags_of(memory[s + 7])}</td>'
                   f'<td>{handlers_of(r)}</td></tr>')
    obj.append("</table>")

    # ------------------------------------------------------------ characters
    # A slot's byte 0 is its character, or 0 while empty; the three empty at
    # the start are the ones the arrival hooks fill.
    slots = {}
    for i in range(17):
        slot = 0xCACB + 7 * i
        if memory[slot]:
            slots[memory[slot]] = slot
    for slot, who in ((0xCAE7, 0x42), (0xCAFC, 0x46), (0xCB03, 0x3C)):
        slots.setdefault(who, slot)
    chars = ['<p>The player and the other characters. Each but the player runs a script '
             'from a slot in CHARACTERS (#R$CACB), the orders it will take at once are byte 6 '
             'of that slot (DO_TALK, #R$9034), and its reactions are the entries of its script '
             'table keyed by an action (REACT, #R$9AA0). Carrying capacity is byte 3 of the '
             'record.</p>',
             '<table class="hobbit-table"><tr><th>No.</th><th>Character</th><th>Starts</th>'
             '<th>Side</th><th>Str</th><th>Def</th><th>Carries</th><th>Script slot</th>'
             '<th>Orders</th><th>Reacts to</th><th>Own handlers</th></tr>']
    for r in sorted(records, key=lambda r: r["number"]):
        n, s = r["number"], r["start"]
        if n and n < 0x3C:
            continue
        side = ", ".join(v for k, v in SIDES.items() if memory[s + 4] & k) or "-"
        slot = slots.get(n)
        if slot is not None:
            table = memory[slot + 4] | (memory[slot + 5] << 8)
            reacts = [esc(_pattern_words(memory, key)) for key, _, _ in bh.keyed_table(memory, table) if key]
            slot_text = f"#R${slot:04X}"
            orders = str(memory[slot + 6])
        else:
            reacts, slot_text, orders = [], "-", "-"
        chars.append(f'<tr id="obj{n}"><td>${n:02X}</td><td>#R${s:04X}({esc(names[n])})</td>'
                     f'<td>{where_of(r)}</td><td>{side}</td><td>{memory[s + 5]}</td>'
                     f'<td>{memory[s + 6]}</td><td>{memory[s + 3]}</td><td>{slot_text}</td>'
                     f'<td>{orders}</td><td>{", ".join(reacts) or "-"}</td><td>{handlers_of(r)}</td></tr>')
    chars.append("</table>")

    # The scripts themselves, table by table, in words. A script that runs on
    # into another one with a name of its own says so and stops, rather than
    # repeating it: Gandalf's five ordinary scripts are one list entered at
    # five places.
    program = bh.script_program(memory)
    labels, steps = program["labels"], program["steps"]
    # A walk stops where it runs into another of a table's own scripts --
    # not at every label, since a fallback or a jump target is labelled too.
    entry_points = {target for t in program["tables"].values() for _, _, target in t["entries"]}
    # Routines the scripts call are named by the annotations.
    routine_names = dict(re.findall(r"^@ \$([0-9A-F]{4}) label=(\S+)",
                                    bh.ANNOTATIONS.read_text(encoding="utf-8"), re.M))
    def link(a: int) -> str:
        name = labels.get(a) or routine_names.get(f"{a:04X}") or f"${a:04X}"
        return f"#R${a:04X}({name})"

    def walk(start: int) -> list[str]:
        out, at = [], start
        for _ in range(60):
            step = steps[at]
            out.append(f"<li>{bh.describe_step(memory, program, step, link)}"
                       + (f" -- if refused, {link(step['fallback'])}" if step["fallback"] else "")
                       + "</li>")
            if step["ends"]:
                break
            at += step["length"]
            if at in entry_points and at != start:
                out.append(f"<li><i>then on as {link(at)}</i></li>")
                break
        return out

    chars.append('<h2 id="scripts">The scripts</h2>')
    chars.append('<p>Each character works through a script a step at a time, each step an '
                 'action it tries as if it had typed it (CHARACTERS_ACT, #R$980E). A step that '
                 'names no object acts on whatever fits. "Switch to one of its first N scripts '
                 'at random" is how a character wanders: its ordinary scripts are often one list '
                 'entered at different places. The reactions are the scripts REACT (#R$9AA0) sends '
                 'a character to when something is done to it.</p>')
    tables = program["tables"]
    for address in sorted(tables):
        table = tables[address]
        who = ", ".join(esc(names[n]) for n in table["owners"])
        current = [s_["current"] for s_ in program["slots"] if s_["table"] == address]
        chars.append(f'<h3 id="scripts{address:04X}">{who} -- #R${address:04X}({labels[address]})</h3>')
        if current:
            chars.append("<p>At the start: " + ", ".join(sorted({link(c) for c in current})) + "</p>")
        for at, key, target in table["entries"]:
            what = ("An ordinary script" if key == 0 else
                    f"On {esc(_pattern_words(memory, key))}")
            chars.append(f"<p><b>{what}</b>: {link(target)}</p><ol>")
            chars += walk(target)
            chars.append("</ol>")
        for c in sorted(set(current)):
            if all(c != target for _, _, target in table["entries"]):
                chars.append(f"<p><b>Where it starts</b>: {link(c)}</p><ol>")
                chars += walk(c)
                chars.append("</ol>")

    # ------------------------------------------------------------ actions
    carriers: dict[int, list[int]] = {}
    for r in records:
        for _, code, handler in r["handlers"]:
            if code and handler:
                carriers.setdefault(code, []).append(r["number"])
    act = ['<p>The 59 sentences the parser understands, from ACTION_PATTERNS (#R$AB53): the '
           'action code is the place in that table. The ordinary handler comes from '
           'ACTION_TABLE (#R$C730); an action with none is only ever done by the objects '
           'that carry a handler for it. "Needs light", "a place" and the rest are the '
           'pattern\'s options (PATTERN_OPTIONS, #R$7B78).</p>',
           '<table class="hobbit-table"><tr><th>Code</th><th>Sentence</th><th>Handler</th>'
           '<th>Options</th><th>Objects with their own</th></tr>']
    for code in range(1, 60):
        a = 0xAB4B + 8 * code
        b71e = (memory[a + 7] & 0xF0) | (memory[a + 5] >> 4)
        b71d = (memory[a + 3] & 0xF0) | (memory[a + 1] >> 4)
        options = [name for test, name in ((b71e & 0x40, "needs light"), (b71d & 0x80, "a place"),
                                            (b71d & 0x10, "not narrated"), (b71d & 0x08, "first object"),
                                            (b71d & 0x04, "second object")) if test]
        handler = action_handlers.get(code)
        own = ", ".join(obj_link(n) for n in sorted(set(carriers.get(code, []))))
        act.append(f'<tr id="act{code}"><td>{code} (${code:02X})</td><td>{esc(_pattern_words(memory, code))}</td>'
                   f'<td>{f"#R${handler:04X}" if handler else "-"}</td><td>{", ".join(options) or "-"}</td>'
                   f'<td>{own or "-"}</td></tr>')
    act.append("</table>")

    # ------------------------------------------------------------ map
    real_rooms = {k: r for k, r in rooms.items() if k}
    placed = map_layout(real_rooms)
    mapped = ['<p>Every location, placed by the compass direction of the exits between them '
              '-- north up, east right, and up and down on the diagonals -- and moved aside '
              "where the game's geography will not fit a grid. A line is a way between two "
              'places, with a head at each end it can be taken towards; dashed, it goes '
              'through something, a door or a river. Click a place for its entry.</p>',
              '<div style="overflow: auto">',
              map_svg(real_rooms, room_name, set(pictures), placed), '</div>']
    sections = {"Map": mapped, "Locations": loc, "Objects": obj, "Characters": chars, "Actions": act}
    lines = ["; Generated by scripts/hobbit_pages.py -- the game's own content, not committed.", ""]
    for name, body in sections.items():
        lines += [f"[{name}]"] + body + [""]
    out_ref.write_text("\n".join(lines), encoding="utf-8")
    bh._log(f"  {len(pictures)} pictures, {len(room_name)} locations, "
            f"{sum(1 for r in records if 0 < r['number'] < 0x3C)} objects, "
            f"{sum(1 for r in records if r['number'] >= 0x3C) + 1} characters, 59 actions")
