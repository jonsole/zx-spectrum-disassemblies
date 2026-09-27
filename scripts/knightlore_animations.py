"""Knight Lore's animations, as GIFs of the game running its own code.

build_knightlore.py's HTML build calls build(), which writes the GIFs into
the HTML directory and returns the Animations section. Nothing here is
committed output: the frames are the game's.

In Knight Lore an object has no frame number. Its type -- byte 0 of its
32-byte record -- picks both its handler (through upd_sprite_jmp_tbl, $B096)
and its sprite (through sprite_tbl, $7112), so a handler animates its object
by changing its own type: a walk cycle is six consecutive types, a flicker is
the type's bit 0 turned over, and a sparkle counts its type up to the end of
a run and turns into something else.

The frames are not put together from the sprites. Each animation is a room
running in SkoolKit's simulator, set up the way knightlore_pages.Castle sets
the game up, and every frame is one real pass of the game's frame loop -- the
handlers run, the renderer wipes, depth-sorts and draws, and the rectangles
are copied to the display -- and the picture is read off the display. So a
composite character (Sabreman's legs and upper body, a guard's body and
legs, the wizard) is assembled by the game, each part at the pixel offsets
its own handler sets, facing the way the game turned it, and what one frame
shows next to the next is exactly what the game drew in that order.

What the simulation is given, and nothing more:

- A room. A one-off room record written first in the room table, where
  find_screen looks first (as Castle.draw does): the square room's walls
  round Sabreman, and nothing but the template or background being shown
  for anything else -- the cauldron in a room numbered $88, the wizard's,
  since that is what brings the bubbles.
- A controller. The control method at $5BA4 is set to Kempston, rotational,
  and the simulator's port reads answer port $1F with the stick held up --
  walk forward -- when Sabreman is to walk, and nothing otherwise.
- Sabreman, or no Sabreman. The player's two records are set to the types,
  facing and position wanted. Where he is not the subject, his legs are
  given type 134 (a panel piece, whose handler does nothing) high above the
  top of the screen, where the projection says there is nothing to draw:
  next_frame_or_die would take two empty player records for a death.
- For the transformation, the sun one pixel from setting; for the death,
  the kill bit the collision code sets on touching something deadly.

A GIF is cropped to what the game drew of its objects in those frames: the
rectangles in each record's +$1A/+$1B (the projected pixel position) and its
sprite's size, relative to where the projection puts the object's own X, Y,
Z -- so a walking figure stays in place in the picture while it walks across
the room -- or fixed, for the scenes. Each frame is shown for as long as the
game took over it, counted in T-states in the simulator (3.5MHz, with no
memory contention, so a little quicker than the real machine); a frame the
game drew identically to the one before is merged into it.
"""
from __future__ import annotations

import html
from pathlib import Path

import knightlore_data as kd
import knightlore_pages as kp

# Where the frames come from.
RAM_BASE = 0x4000          # a frame keeps the screen, the variables and the
RAM_END = 0x6108           # object table: everything up to the end of it
ATTRIBUTES = 0x5800
RECORD_SIZE = 32
RECORD_COUNT = 40
CONTROL_METHOD = 0x5BA4    # bits 1-2 the method, bit 3 directional
KEMPSTON = 1 << 1          # method 1, rotational
KEMPSTON_PORT = 0x1F
STICK_UP = 0x08            # Kempston bit 3: forward, in rotational control
SUN = 0xC44D               # the sun or moon's own record
SUN_X = SUN + 0x1A         # its pixel X across the window, 176 to 225
SUN_SETS = 224             # one step before toggle_day_night
NEXT_FRAME_OR_DIE = 0xB074  # where a frame ends: all drawn and copied, and
                           # the player's records not yet looked at for a death
HIDDEN = 134               # a type whose handler is a RET (see the docstring)
HIDDEN_Z = 250             # projects to pixel y 198: above the screen
WALLS = 12                 # the background of a square room's walls
SQUARE = 0                 # its size
KILLED = 0x40              # +$0D bit 6: has touched something deadly
MIRRORED = 0x40            # +$07 bit 6
T_STATES_PER_MS = 3500

# The window the sun and moon move across (display_frame): 48 by 31 pixels
# in the bottom right-hand corner, from column 23.
SUN_WINDOW = (184, 161, 232, 192)

# The Spectrum's colours, for a GIF palette the frames are mapped onto.
PALETTE = kp.SPECTRUM + kp.SPECTRUM_BRIGHT


def _esc(text: str) -> str:
    return html.escape(text, quote=False)


def _word(memory, address: int) -> int:
    return memory[address] | (memory[address + 1] << 8)


# --------------------------------------------------------------------------
# The game, running.
# --------------------------------------------------------------------------

class Frame:
    """What one frame of the game left: its RAM from the screen to the end of
    the object table, and how long it took."""

    def __init__(self, ram: bytes, tstates: int):
        self.ram = ram
        self.tstates = tstates

    def byte(self, address: int) -> int:
        return self.ram[address - RAM_BASE]

    def record(self, index: int) -> bytes:
        start = kp.PLAYER + RECORD_SIZE * index - RAM_BASE
        return self.ram[start:start + RECORD_SIZE]

    def screen(self):
        from PIL import Image

        image = Image.new("RGB", (256, 192))
        pixels = image.load()
        for y in range(192):
            row = 0x4000 | ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2)
            for column in range(32):
                byte = self.byte(row + column)
                attr = self.byte(ATTRIBUTES + (y >> 3) * 32 + column)
                palette = kp.SPECTRUM_BRIGHT if attr & 0x40 else kp.SPECTRUM
                ink, paper = palette[attr & 7], palette[(attr >> 3) & 7]
                for bit in range(8):
                    pixels[column * 8 + bit, y] = ink if byte & (0x80 >> bit) else paper
        return image


def room_record(room: int, backgrounds: list[int], groups: list[tuple[int, list[int]]],
                ink: int = 7) -> list[int]:
    """A room record (see knightlore_pages._one_off_record) in a colour of
    its own. It must name a background: with none and no objects the room
    builder reads on past the record's end."""
    body = [(SQUARE << 3) | ink] + backgrounds
    if groups:
        body.append(0xFF)
        for template, positions in groups:
            body += [(template << 3) | (len(positions) - 1)] + positions
    return [room, len(body) + 1] + body


class Scene:
    """A room of the game, run one frame at a time in the simulator.

    `player` is None for no Sabreman (see the module's docstring), or a dict
    of the legs' type, `mirror`, `x`, `y`, and optionally `top` (the upper
    body's type; the legs' + 16 if not given)."""

    def __init__(self, castle, room: int, record: list[int] | None = None,
                 player: dict | None = None, setup=None):
        from skoolkit.simutils import PC, SP

        memory = list(castle.memory)
        if record is not None:
            memory[kd.ROOMS:kd.ROOMS + len(record)] = record
        legs, top = kp.PLAYER, kp.PLAYER_TOP
        for address in (legs, top):
            memory[address + kp.ROOM_OFFSET] = room
            memory[address + 0x0C] = 0          # no room-entry walk, no jump
            memory[address + 0x0D] = 0
            memory[address + 0x18:address + 0x20] = [0] * 8
        if player is None:
            memory[legs] = HIDDEN
            memory[legs + 3] = HIDDEN_Z
            memory[legs + 7] = 0x02             # out of every collision test
            memory[top] = 0
        else:
            memory[legs] = player["type"]
            memory[top] = player.get("top", player["type"] + 16)
            memory[legs + 1] = memory[top + 1] = player.get("x", 0x80)
            memory[legs + 2] = memory[top + 2] = player.get("y", 0x80)
            flags = memory[legs + 7] & ~MIRRORED
            memory[legs + 7] = flags | (MIRRORED if player.get("mirror") else 0)
        memory[CONTROL_METHOD] = KEMPSTON
        if setup is not None:
            setup(memory)
        memory, registers = castle._call(memory, kp.BUILD_SCREEN_OBJECTS, castle.registers)
        self.sim = castle._machine(memory)
        for index, value in enumerate(registers):
            self.sim.registers[index] = value
        self.sim.registers[SP] = kp.OBJECT_STACK
        self.sim.registers[PC] = kp.ONSCREEN_LOOP
        self.sim.set_tracer(self)
        self.stick = 0
        self.frames: list[Frame] = []

    def read_port(self, registers, port: int) -> int:
        """The simulator's IN: the Kempston stick, and no keys pressed."""
        if port & 0xFF == KEMPSTON_PORT:
            return self.stick
        return 0xFF

    def poke(self, address: int, value: int) -> None:
        self.sim.memory[address] = value

    def peek(self, address: int) -> int:
        return self.sim.memory[address]

    def run(self, count: int = 1) -> Frame:
        """Run `count` frames of the game, keeping each. A frame is taken as
        ending at next_frame_or_die, so that a death can be watched to its
        last frame without the next life starting."""
        from skoolkit.simutils import PC, T

        for _ in range(count):
            start = self.sim.registers[T]
            self.sim.run(self.sim.registers[PC], NEXT_FRAME_OR_DIE)
            self.frames.append(Frame(bytes(self.sim.memory[RAM_BASE:RAM_END]),
                                     self.sim.registers[T] - start))
        return self.frames[-1]

    def find(self, types) -> int:
        """The first record whose type is in `types`, in the last frame (or
        the room as built)."""
        for index in range(RECORD_COUNT):
            if self.peek(kp.PLAYER + RECORD_SIZE * index) in types:
                return index
        raise ValueError(f"no record of types {sorted(types)}")


# --------------------------------------------------------------------------
# Cropping and saving.
# --------------------------------------------------------------------------

def _sprite_size(memory, kind: int) -> tuple[int, int]:
    sprite = _word(memory, kp.SPRITE_TABLE + 2 * kind)
    return memory[sprite] & 0x0F, memory[sprite + 1]


def _drawn_box(memory, record: bytes):
    """Where the renderer last put this record's picture, as a box of screen
    pixels: +$1A is the left pixel and +$1B the bottom row counted up from the
    bottom of the screen (calc_pixel_XY), and the sprite goes up from there."""
    if record[0] < 2:
        return None
    width, height = _sprite_size(memory, record[0])
    x, y = record[0x1A], record[0x1B]
    if not width or y >= 192 or (x, y) == (0, 0):
        return None
    top = max(0, 191 - (y + height - 1))
    return x, top, min(256, x + 8 * width), 192 - y


def _anchor(record: bytes, z: int | None = None) -> tuple[int, int]:
    """The projection of the record's X, Y, Z without its drawing offsets
    (calc_pixel_XY, $D6C9), as a screen pixel from the top."""
    x, y = record[1], record[2]
    z = record[3] if z is None else z
    px = (x + y - 128) & 0xFF
    py = ((((y - x + 128) & 0xFF) >> 1) + z - 104) & 0xFF
    return px, 191 - py


def crop(memory, frames: list[Frame], records: list[int], anchor: int | None = None,
         fixed_z: bool = False, margin: int = 3) -> list:
    """Each frame's picture, cut down to the union of what `records` drew in
    all of them. With `anchor`, the box moves with that record's position (and
    with fixed_z, only across the floor: a bouncing ball is seen to bounce)."""
    z = frames[0].record(anchor)[3] if anchor is not None and fixed_z else None
    offsets, union = [], None
    for frame in frames:
        ox, oy = _anchor(frame.record(anchor), z) if anchor is not None else (0, 0)
        offsets.append((ox, oy))
        for index in records:
            box = _drawn_box(memory, frame.record(index))
            if box is None:
                continue
            box = (box[0] - ox, box[1] - oy, box[2] - ox, box[3] - oy)
            union = box if union is None else (min(union[0], box[0]), min(union[1], box[1]),
                                               max(union[2], box[2]), max(union[3], box[3]))
    if union is None:
        raise ValueError("nothing was drawn")
    left, top, right, bottom = (union[0] - margin, union[1] - margin,
                                union[2] + margin, union[3] + margin)
    pictures = []
    for frame, (ox, oy) in zip(frames, offsets):
        pictures.append(frame.screen().crop((left + ox, top + oy, right + ox, bottom + oy)))
    return pictures


def _duration(tstates: int) -> int:
    """A frame's time in milliseconds, to the 10ms a GIF can say."""
    return max(20, round(tstates / T_STATES_PER_MS / 10) * 10)


def merge(pictures: list, durations: list[int], labels: list[str]) -> list[tuple]:
    """Consecutive identical pictures as one frame shown for their total
    time: (picture, milliseconds, label)."""
    out = []
    for picture, duration, label in zip(pictures, durations, labels):
        if out and out[-1][0].tobytes() == picture.tobytes():
            out[-1] = (out[-1][0], out[-1][1] + duration, out[-1][2])
        else:
            out.append((picture, duration, label))
    return out


def save_gif(path: Path, frames: list[tuple]) -> None:
    """Frames (picture, milliseconds, label) as a looping GIF in the
    Spectrum's colours."""
    from PIL import Image

    palette = Image.new("P", (1, 1))
    flat = [c for colour in PALETTE for c in colour]
    palette.putpalette(flat + [0] * (768 - len(flat)))
    images = [picture.quantize(palette=palette, dither=Image.Dither.NONE)
              for picture, _, _ in frames]
    images[0].save(path, save_all=True, append_images=images[1:], loop=0,
                   duration=[duration for _, duration, _ in frames], disposal=1,
                   optimize=False)


# --------------------------------------------------------------------------
# The animations.
# --------------------------------------------------------------------------

def _types_label(frame: Frame, records: list[int]) -> str:
    return "+".join(str(frame.record(i)[0]) for i in records if frame.record(i)[0] > 1) or "-"


def _animation(memory, key: str, frames: list[Frame], records: list[int], **options) -> dict:
    pictures = crop(memory, frames, records, **options)
    return {"key": key,
            "frames": merge(pictures, [_duration(f.tstates) for f in frames],
                            [_types_label(f, records) for f in frames])}


def _walk_cycle(scene: Scene, legs: int = 0, top: int | None = 1) -> list[Frame]:
    """Six frames of a walk, from the legs' frame 0: the cycle the game
    repeats, so the GIF loops as it does. A cycle in which the upper body
    took one of its occasional frames is passed over for the next."""
    for _ in range(40):
        scene.run()
        cycle = scene.frames[-6:]
        if len(cycle) < 6 or cycle[0].record(legs)[0] & 7 != 0:
            continue
        steps = [f.record(legs)[0] & 7 for f in cycle]
        if steps != [0, 1, 2, 3, 4, 5]:
            continue
        if top is not None and any(f.record(top)[0] != f.record(legs)[0] + 16 for f in cycle):
            continue
        return cycle
    raise ValueError("no clean walk cycle")


def sabreman_walking(castle, memory, werewolf: bool, view_b: bool) -> dict:
    """Sabreman or Sabrewulf walking. View A unmirrored faces -X (W) and view B
    unmirrored +X (E), so each walks from one side of the room towards the
    other."""
    legs = 16 + (32 if werewolf else 0) + (8 if view_b else 0)
    room = castle.empty_room
    scene = Scene(castle, room, room_record(room, [WALLS], [], 5 if werewolf else 6),
                  {"type": legs, "x": 0x58 if view_b else 0xA8})
    scene.stick = STICK_UP
    cycle = _walk_cycle(scene)
    key = ("sabrewulf" if werewolf else "sabreman") + ("-b" if view_b else "-a")
    return _animation(memory, key, cycle, [0, 1], anchor=0)


def transformation(castle, memory) -> dict:
    """Sabreman standing as the sun sets: chk_and_init_transform sees
    $5BB1, and eight steps of four frames later he is Sabrewulf."""
    room = castle.empty_room

    def sunset(ram):
        ram[SUN_X] = SUN_SETS

    scene = Scene(castle, room, room_record(room, [WALLS], [], 6),
                  {"type": 18}, setup=sunset)
    scene.run(2)
    for _ in range(40):
        scene.run()
        if 92 <= scene.frames[-1].record(0)[0] <= 95:
            break
    start = len(scene.frames) - 3
    for _ in range(60):
        scene.run()
        if 48 <= scene.frames[-1].record(0)[0] <= 61:
            break
    scene.run(6)
    return _animation(memory, "transformation", scene.frames[start:], [0, 1], anchor=0)


def materialising(castle, memory) -> dict:
    """Sabreman arriving: both records type 120, as lose_life leaves them,
    with the real types at +$10."""
    room = castle.empty_room

    def arriving(ram):
        ram[kp.PLAYER] = ram[kp.PLAYER_TOP] = 120
        ram[kp.PLAYER + 0x10], ram[kp.PLAYER_TOP + 0x10] = 18, 34

    scene = Scene(castle, room, room_record(room, [WALLS], [], 6), {"type": 18},
                  setup=arriving)
    for _ in range(40):
        scene.run()
        if scene.frames[-1].record(0)[0] < 120 and scene.frames[-1].record(1)[0] < 120:
            break
    scene.run(4)
    # The room's first frame draws everything at once; it is the first
    # sparkle frame all the same.
    return _animation(memory, "materialising", scene.frames, [0, 1], anchor=0)


def dying(castle, memory) -> dict:
    """Sabreman killed: the legs' kill bit set, as the collision code sets it
    on touching something deadly; both halves sparkle out."""
    room = castle.empty_room
    scene = Scene(castle, room, room_record(room, [WALLS], [], 6), {"type": 18})
    scene.run(3)
    start = len(scene.frames) - 1
    scene.poke(kp.PLAYER + 0x0D, scene.peek(kp.PLAYER + 0x0D) | KILLED)
    for _ in range(20):
        scene.run()
        if scene.frames[-1].record(0)[0] == 0 and scene.frames[-1].record(1)[0] == 0:
            break                    # next_frame_or_die would start a new life
    return _animation(memory, "dying", scene.frames[start:], [0, 1], anchor=0)


def collecting(castle, memory) -> dict:
    """An extra life picked up: one of the four $67 entries in the charm table
    moved into Sabreman's path; he walks into it."""
    room = castle.empty_room
    entry = next(kd.CHARM_PLACES + kd.CHARM_PLACE_SIZE * i for i in range(kd.CHARM_PLACE_COUNT)
                 if castle.memory[kd.CHARM_PLACES + kd.CHARM_PLACE_SIZE * i] == 0x67)

    def place(ram):
        ram[entry + 5:entry + 9] = [0x80, 0x80, 0x80, room]

    scene = Scene(castle, room, room_record(room, [WALLS], [], 3),
                  {"type": 16, "x": 0xA8}, setup=place)
    scene.stick = STICK_UP
    life = scene.find({0x67})
    scene.run(2)
    start = len(scene.frames)
    for _ in range(30):
        scene.run()
        if scene.frames[-1].record(life)[0] == 0:
            break
    scene.stick = 0
    scene.run(3)
    return _animation(memory, "collecting", scene.frames[start:], [0, 1, life])


def _object_scene(castle, backgrounds, groups, ink, types) -> tuple[Scene, int]:
    """A room with just this in it: no walls, so that nothing else is drawn
    near it (a room record with objects needs no background)."""
    room = castle.empty_room
    scene = Scene(castle, room, room_record(room, backgrounds, groups, ink))
    return scene, scene.find(types)


def guard(castle, memory) -> dict:
    """The guard that walks back and forth along X (template 8): body 150/151,
    legs 144-157 in the next record."""
    scene, body = _object_scene(castle, [], [(8, [0x1B])], 4, {150, 151})
    scene.run(2)
    return _animation(memory, "guard", _walk_cycle(scene, body + 1, None),
                      [body, body + 1], anchor=body)


def wizard(castle, memory) -> dict:
    """The wizard (background 18): body 158/159, legs in the next record."""
    scene, body = _object_scene(castle, [18], [], 3, {158, 159})
    scene.run(2)
    return _animation(memory, "wizard", _walk_cycle(scene, body + 1, None),
                      [body, body + 1], anchor=body)


def ghost(castle, memory) -> dict:
    """A ghost (template 9), drifting until it meets the room's edge."""
    scene, index = _object_scene(castle, [], [(9, [0x1B])], 5, set(range(80, 84)))
    scene.run(2)
    start = len(scene.frames)
    scene.run(16)
    return _animation(memory, "ghost", scene.frames[start:], [index], anchor=index)


def fire(castle, memory) -> dict:
    """The fire that stays put (template 1, type 176)."""
    scene, index = _object_scene(castle, [], [(1, [0x1B])], 6, {176, 177})
    scene.run(2)
    start = len(scene.frames)
    scene.run(16)
    return _animation(memory, "fire", scene.frames[start:], [index], anchor=index)


def flame(castle, memory) -> dict:
    """The flame that runs along X (template 20, type 86)."""
    scene, index = _object_scene(castle, [], [(20, [0x1B])], 6, {86, 87})
    scene.run(2)
    start = len(scene.frames)
    scene.run(8)
    return _animation(memory, "flame", scene.frames[start:], [index], anchor=index)


def ball(castle, memory) -> dict:
    """The ball bouncing up and down (template 24): one bounce, from a
    landing to the next."""
    scene, index = _object_scene(castle, [], [(24, [0x1B])], 4, {178, 179})
    landings = []
    for _ in range(160):
        before = scene.peek(kp.PLAYER + RECORD_SIZE * index + 0x0D) & 4
        scene.run()
        if not before and scene.frames[-1].record(index)[0x0D] & 4:
            landings.append(len(scene.frames) - 1)
            if len(landings) == 3:
                break
    # Not the first bounce, which begins in the room's first frame.
    frames = scene.frames[landings[1]:landings[2]]
    return _animation(memory, "ball", frames, [index], anchor=index, fixed_z=True)


def bubbles(castle, memory) -> dict:
    """The cauldron alone in a room numbered $88, the wizard's, which is what
    init_cauldron_bubbles looks for: the bubbles rise out of it and show the
    charm the wizard wants."""
    scene = Scene(castle, 0x88, room_record(0x88, [19], [], 6))
    cauldron = [scene.find({141}), scene.find({142})]
    bubble = 3                               # init_cauldron_bubbles uses record 3
    scene.run(1)
    start = len(scene.frames)
    for _ in range(120):
        scene.run()
        if 168 <= scene.frames[-1].record(bubble)[0] <= 174:
            break
    scene.run(15)
    return _animation(memory, "bubbles", scene.frames[start:], cauldron + [bubble])


def crumbling(castle, memory) -> dict:
    """A crumbling block (template 22, type 143) with a chest (template 6)
    set two levels above it, which falls onto it."""
    scene, block = _object_scene(castle, [], [(22, [0x1B]), (6, [0x9B])], 5, {143})
    chest = scene.find({85})
    start = 1                                # not the room's first frame
    for _ in range(30):
        scene.run()
        if scene.frames[-1].record(block)[0] == 0:
            break
    scene.run(4)
    frames = scene.frames[start:]
    for index, frame in enumerate(frames):   # from a few frames before it goes
        if frame.record(block)[0] != 143:
            frames = frames[max(0, index - 4):]
            break
    return _animation(memory, "crumbling", frames, [block, chest])


def sun_and_moon(castle, memory) -> dict:
    """The window in the panel over a whole day and night: a frame each time
    the sun or moon moves, which is every eighth game frame."""
    room = castle.empty_room
    scene = Scene(castle, room, room_record(room, [WALLS], [], 6))
    scene.run(1)
    pictures, labels, states = [], [], []
    for _ in range(2 * 49 * 8 + 16):
        frame = scene.run()
        scene.frames.clear()                 # 800 frames of RAM are not needed
        state = (scene.peek(SUN), scene.peek(SUN_X))
        if states and state == states[-1]:
            continue
        if len(states) > 2 and state == states[0]:
            break                            # round to the start again
        states.append(state)
        pictures.append(frame.screen().crop(SUN_WINDOW))
        labels.append(str(state[0]))
    # Eight game frames to a step would be a 40-second GIF: shown at one step
    # every 60ms instead, eight times the game's speed or so.
    return {"key": "sun-moon", "frames": [(p, 60, l) for p, l in zip(pictures, labels)]}


# --------------------------------------------------------------------------
# The page.
# --------------------------------------------------------------------------

def _sprite_links(memory, types) -> str:
    """Each type with the sprite it indexes in sprite_tbl."""
    parts = []
    for kind in types:
        parts.append(f"{kind} (#R${_word(memory, kp.SPRITE_TABLE + 2 * kind):04X})")
    return ", ".join(parts)


MAX_LISTED = 14            # runs of types listed before "and so on"


def _order(frames: list[tuple]) -> str:
    """The types shown in the GIF, frame by frame, with how long each lasts;
    frames in a row with the same types (a figure moving, the sun rising) as
    one run."""
    runs = []
    for _, ms, label in frames:
        if runs and runs[-1][0] == label:
            runs[-1][1] += 1
            runs[-1][2] += ms
        else:
            runs.append([label, 1, ms])
    parts = [f"{label} ({ms}ms)" if count == 1 else f"{label} x{count} ({ms}ms)"
             for label, count, ms in runs]
    if len(parts) > MAX_LISTED:
        total = sum(ms for _, ms, _ in frames) / 1000
        parts = parts[:MAX_LISTED - 2] + [f"and so on: {len(frames)} frames, {total:.1f}s in all"]
    return ", ".join(parts)


# The words for each animation: title, the types to list with their sprites,
# and what drives the frames. #R links only to addresses that start entries.
TEXT = {
    "sabreman-a": (
        "Sabreman walking, view A", list(range(16, 22)) + list(range(32, 38)),
        "Legs 16-21 in record 0 and the upper body 32-37 in record 1: the legs' "
        "handler (#R$C823, into #R$C82B) steps the low three bits of the type 0, 1, "
        "... 5, 0 every frame while forward is held (#R$C97F), and "
        "#R$CDE2 then sets the upper body to the legs' type + 16 (#R$CE22), so the "
        "two halves change together. The six legs types name only four sprites, "
        "1 2 3 4 3 2; the upper body's six name four more. View A is type bit 3 "
        "clear; this one is unmirrored, walking towards -X."),
    "sabreman-b": (
        "Sabreman walking, view B", list(range(24, 30)) + list(range(40, 46)),
        "The same cycle with type bit 3 set: legs 24-29 and upper body 40-45, "
        "unmirrored, walking towards +X. Mirroring (+$07 bit 6) makes the other two "
        "of the four facings out of these two views (#R$CA1E)."),
    "sabrewulf-a": (
        "Sabrewulf walking, view A", list(range(48, 54)) + list(range(64, 70)),
        "The werewolf is the man's types + 32: legs 48-53 run by #R$C828 (drawn a "
        "pixel lower than the man's) and the upper body 64-69 by #R$CDDF, stepped "
        "the same way every frame."),
    "sabrewulf-b": (
        "Sabrewulf walking, view B", list(range(56, 62)) + list(range(72, 78)),
        "Legs 56-61 and upper body 72-77, unmirrored, walking towards +X."),
    "transformation": (
        "Man into werewolf", [18, 34, 92, 93, 94, 95, 50, 66],
        "The sun was set one pixel from the edge of its window, so the game's own "
        "#R$C3FF turns it to the moon and sets $5BB1. The legs' handler sees it "
        "(#R$C306): the upper body becomes type 1 and is wiped, and the legs take "
        "one of types 92-95 at random, never the one showing, mirrored each time "
        "(#R$C357). #R$C337 changes it every fourth frame, by the frame counter, "
        "eight times; then #R$C377 flips bit 5 of the saved type -- legs 18 to 50 "
        "-- and puts the upper body back as that + 16. The four sprites are chosen "
        "at random, so another run gives another order."),
    "materialising": (
        "Sabreman appearing", list(range(120, 128)) + [18, 34],
        "On every new life (#R$D12A) and every room entered, both of Sabreman's "
        "records are type 120 with the real type kept at +$10. #R$BEFE counts the "
        "type up on alternate frames of the counter at $5BA2, 120 to 127, and "
        "#R$BF11 then restores the saved type and runs its handler at once. The "
        "eight types are the sparkle sprites growing, small to large. The first "
        "frame is long because it is the room's first, when the game draws and "
        "copies the whole screen."),
    "dying": (
        "Sabreman dying", list(range(112, 120)),
        "Something deadly sets bit 6 of the legs' +$0D; the legs' handler (#R$C82B) "
        "marks the upper body too, and both become type 112 (#R$BF21). #R$BF2B adds "
        "one every frame, with a noise that shortens as it goes; 119 (#R$BF3F) "
        "makes the record type 1, which is wiped and freed. When both records are "
        "empty the life is over. The sprites are the materialising ones, large to "
        "small."),
    "collecting": (
        "An extra life collected", [0x67, 111],
        "An extra life (type 103, #R$C1AB) tests itself against Sabreman every "
        "frame; touching, it sets bit 3 of its type, making 111, adds a life and "
        "shows it, and takes itself out of #R$6FF2. Type 111 (#R$B95E) is drawn "
        "for one frame as a sparkle and then becomes type 1. A charm picked up "
        "does not sparkle: it goes straight to the carried objects."),
    "guard": (
        "A guard walking", [150, 151] + list(range(144, 150)) + list(range(152, 158)),
        "Two records: the body, 150 or 151 (#R$B73C), and the legs in the record "
        "after it, 144-149 or 152-157 (#R$B6F9), which use Sabreman's own legs "
        "sprites. The body walks 2 a frame along X and writes its position and "
        "velocity into the legs; the legs pick view and mirroring from that and "
        "step the same six-frame cycle as Sabreman's, every frame they move. The "
        "body's view is bit 0 of its type, set by #R$B76C."),
    "wizard": (
        "The wizard walking", [158, 159] + list(range(144, 150)) + list(range(152, 158)),
        "Built the same way as a guard: the body, 158 or 159 (#R$B9A5, which walks "
        "him round the edge of the room, turning a quarter whenever he is blocked), "
        "one frame per view, over the same legs (#R$B6F9)."),
    "ghost": (
        "A ghost", [80, 81, 82, 83],
        "#R$C5C8 turns the type's bit 0 over every frame, a two-frame flicker; bit 1 "
        "and the mirroring give the view, chosen from its direction whenever it "
        "picks a new one (#R$C603). Here it drifts one way, flickering between 82 "
        "and 83, until the edge of the room turns it, and the new directions show "
        "the other view."),
    "fire": (
        "A fire", [176, 177],
        "#R$B83F flips the type's bit 0 on alternate frames -- by bit 0 of $5BBC, "
        "the frame counter plus the object's place in the table, so fires side by "
        "side flicker out of step -- and on each flip toggles the mirroring when a "
        "bit of the random byte at $5BA5 is set."),
    "flame": (
        "A flame running along X", [86, 87],
        "#R$B7ED moves it 2 a frame and flips bit 0 of the type every frame, over "
        "the same two sprites as the fire; the flame along Y (180, 181, #R$B80F) is "
        "the same."),
    "ball": (
        "A ball bouncing", [178, 179],
        "#R$B865 flips the type every frame while the ball rises 2 a frame to a "
        "ceiling 32 above the first ball in the room and falls back under gravity. "
        "One bounce, from a landing to the next; the picture stays put while the "
        "ball moves in it. The ball that hops at Sabrewulf (182, 183, #R$B5FF) uses "
        "the same two sprites, also a frame each."),
    "bubbles": (
        "The cauldron's bubbles", [160, 161, 162, 163] + list(range(168, 175)),
        "In the wizard's room, $88, #R$B8A9 puts the bubbles in record 3, type 160 "
        "(here the cauldron is alone in a room of that number). "
        "#R$B8DA adds one to the type's low two bits every frame (#R$B98C: 160, "
        "161, 162, 163, sprites of the sparkle, small, smaller, smallest, smaller) "
        "while they rise one unit a frame; at the top, each time the cycle comes "
        "back to 160 they show the charm wanted next (168 + its number) for one "
        "frame, and #R$B923 puts them back to 160 -- one frame in five. If "
        "Sabreman is the werewolf they turn into the repel spell, 164-167, the "
        "same four sprites."),
    "crumbling": (
        "A block crumbling", [143, 184, 185],
        "Type 143 (#R$B6A2) waits for something to land on it -- here a chest "
        "placed above it. Then it makes itself 184 and goes straight on into "
        "#R$BF2B, which adds one with a noise, so the first thing drawn is 185; the "
        "next frame 185 (#R$BF37) vanishes. One frame of sparkle, and the chest "
        "falls through. The block is back when the room is next built."),
    "sun-moon": (
        "The sun and the moon", [88, 89],
        "Not an animation of the sprite: the sun (88) or moon (89) is a record of "
        "its own at #R$C44D that #R$C397 moves one pixel right every eighth frame "
        "along an arc, drawn behind the two ends of the window frame; after 49 "
        "steps #R$C3FF flips it to the other one. Shown here eight times faster "
        "than the game: a day and a night, 98 steps, are 784 game frames."),
}

ORDER = ["sabreman-a", "sabreman-b", "sabrewulf-a", "sabrewulf-b", "transformation",
         "materialising", "dying", "collecting", "guard", "wizard", "ghost", "fire",
         "flame", "ball", "bubbles", "crumbling", "sun-moon"]
# The sprite-sized ones, at three times the size; the scenes at twice.
SPRITE_SIZED = {"sabreman-a", "sabreman-b", "sabrewulf-a", "sabrewulf-b", "transformation",
                "materialising", "dying", "guard", "wizard", "ghost", "fire", "flame",
                "sun-moon"}


def animations(memory, log=print) -> list[dict]:
    castle = kp.Castle(memory)
    game = castle.memory
    out = []
    for werewolf in (False, True):
        for view_b in (False, True):
            out.append(sabreman_walking(castle, game, werewolf, view_b))
    for make in (transformation, materialising, dying, collecting, guard, wizard, ghost,
                 fire, flame, ball, bubbles, crumbling, sun_and_moon):
        log(f"  {make.__name__}")
        out.append(make(castle, game))
    return out


def build(memory, html_dir: Path, log=print) -> str:
    """Write the GIFs into html_dir/images/animations and return the
    Animations section's HTML."""
    out_dir = html_dir / "images" / "animations"
    out_dir.mkdir(parents=True, exist_ok=True)
    log("Running the animations in the game's own code...")
    made = {a["key"]: a for a in animations(memory, log)}
    game = list(memory)
    lines = ['<div class="kl-list">',
             "<p>Knight Lore has no animation frames as such. An object's type -- the "
             "first byte of its 32-byte record -- chooses both the routine that runs it "
             "each frame, through #R$B096, and the sprite it is drawn with, through "
             "#R$7112, so an object animates by changing its own type: a walk is six "
             "types in a row, a flicker is bit 0 of the type turned over, a sparkle "
             "counts its type up and at the end of its run turns into something else. "
             "The runs of types, and how fast each handler steps through them, are "
             "the animations.</p>",
             "<p>Each animation below was made by running the game's own code in a "
             "simulator when these pages were built: a room with the thing in it, one "
             "real frame of the game after another -- the handlers, the renderer and "
             "the copy to the screen -- with each picture read off the screen. So "
             "Sabreman, the guards and the wizard are put together by the game from "
             "their two records, the frames come in the game's order, and each is shown "
             "for as long as the game took over it (counted in the simulator, without "
             "the memory contention of a real Spectrum). A figure that walks is kept in "
             "the middle of its picture. Under each, the types in each frame of the "
             "picture and how long it lasts; a type that stays on screen for several "
             "game frames is one frame of the picture.</p>"]
    for key in ORDER:
        animation = made[key]
        title, types, words = TEXT[key]
        frames = animation["frames"]
        save_gif(out_dir / f"{key}.gif", frames)
        width, height = frames[0][0].size
        scale = 3 if key in SPRITE_SIZED else 2
        css = "kl-sprite" if key in SPRITE_SIZED else "kl-piece"
        lines += [f'<div class="kl-item" id="{key}">',
                  f"<h3>{_esc(title)}</h3>",
                  f'<img class="{css}" src="images/animations/{key}.gif" alt="{_esc(title)}" '
                  f'width="{width * scale}" height="{height * scale}">',
                  f"<p>{words}</p>",
                  f"<p>Types and their sprites: {_sprite_links(game, types)}.</p>",
                  f"<p>In the picture: {_order(frames)}.</p>",
                  "</div>"]
    lines.append("</div>")
    return "\n".join(lines)
