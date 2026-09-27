"""Ant Attack's animations, as GIFs of the game running its own code.

build_antattack.py's HTML build calls build(), which writes the GIFs into the
HTML directory and returns the Animations section. Nothing here is committed
output: the frames are the game's, drawn when the pages are built.

In Ant Attack an object's picture is one number, worked out afresh every
frame by PROJECT_SPRITES ($8600): the object's first frame (+3 in its record)
plus four times its animation frame (+8) plus its facing turned for the view
-- or, when +8 has bit 7 set, +8 itself, outright. So an animation is
whatever writes +8: CHOOSE_FRAME ($8980) for the two people, MOVE_ANT ($8A00)
for the ants, BLAST_FRAME ($82E0) and THROW_GRENADE ($8D00) for the grenade
and anything exploding.

The frames are not put together from the sprites. Each animation is a game
in progress, running in SkoolKit's simulator from the title screen on (the
build's own _start sequence, boy or girl), with the pieces put where the
scene needs them at a frame boundary -- the player on open ground, an ant a
few cells off, the ants that are not wanted parked outside the walls and
paralysed -- and then one real frame of the game after another: the game's
own movement, frame choice, projection, painter and copy to the screen, with
the picture read off the screen memory. Where the scene is staged, only the
starting positions are; everything after is the game's doing.

Each frame of a GIF lasts as long as the game took over it: the T-states
from the copy to the screen that put the picture there to the next one,
counted in the simulator at 3.5MHz with no memory contention (a real
Spectrum is a little slower). While a script plays -- a tune with letters
between the notes -- the screen is read every fiftieth of a second instead,
so the words appear as they did; FLASH is drawn in the phase the ULA would be
in at that T-state. Consecutive identical pictures are one frame of the GIF.
A GIF is cropped to what the game drew of the objects it is about: each
sprite's 16 x 16 box, from its place in PLANES through PLANE_TO_BUFFER
($8130) -- a table made by running that routine for all 512 places -- since
COPY_TO_SCREEN puts buffer row r, byte c at screen line r, column c.
"""
from __future__ import annotations

import functools
import html
import re
from pathlib import Path

import build_antattack as ba

IMAGE_DIR = "images/animations"

# --------------------------------------------------------------------------
# Addresses. See their entries in the listing.
# --------------------------------------------------------------------------

DRAW_VIEW = 0x84A0          # where the frame's drawing starts, from the view
                            # origin as it is then
FRAME_END = 0x801D          # PLAY, just after the frame's three calls: every
                            # frame reaches it, the last one too
PROJECTED = 0x84B8          # DRAW_VIEW, after PROJECT_SPRITES has filled the
                            # sprite list in object order, before it is sorted
COPIED = 0x84C7             # DRAW_VIEW's RET, after COPY_TO_SCREEN
COPY_TO_SCREEN = (0x8100, 0x812F)
PLANE_TO_BUFFER = 0x8130
PLANES = 0xB500
RENDER_BUFFER = 0xA000
SPRITE_LIST = 0xB450        # eight entries of place (2 bytes) and frame
VIEW_ORIGIN = 0xB420
VIEW = 0xB422
PLAYER_ENERGY_LOW = 0xB432
RESCUEE_ENERGY_LOW = 0xB434
TIME = 0xB436
FRAMES_LEFT = 0xB438
OBJECTS = 0xB480
RECORD = 16
SPRITE_BASE = 0x8000        # frame f is the 64 bytes at $8000 + 64f
WAIT_KEY = 0x8097
PPC = 23621                 # the system variable: the BASIC line running
ENDING_LINE = 3600

# The objects, in record order.
PLAYER, RESCUEE, GRENADE = 0, 1, 2
ANTS = [3, 4, 5, 6, 7]
# Record fields.
X, Y, HEIGHT, FIRST, FACING, FALL, STUN, FLAGS, ANIM, BLAST = range(10)
STATE = 0x0D                # an ant's speed; the rescued person's state
COUNT = 0x0E
PARALYSED = 0xFF

# The simulator and the screen.
ULA_FRAME = 69888           # T-states from one interrupt to the next
FLASH_FRAMES = 16           # the ULA swaps FLASH ink and paper every 16 frames
T_STATES_PER_MS = 3500
RUN_LIMIT = 20_000_000      # a bound on any one frame's run, in T-states
PLAY_AREA = (8, 12, 248, 128)   # what COPY_TO_SCREEN writes: lines 12-127,
                                # columns 1-30
# Where parked objects go: outside the walls and far from where the scenes
# are, so that PROJECT_SPRITES finds them out of view (checked every frame).
PARKING = (0x10, 0x40)
PALETTE = ba.SPECTRUM + ba.SPECTRUM_BRIGHT


def _esc(text: str) -> str:
    return html.escape(text, quote=False)


# --------------------------------------------------------------------------
# The game, running.
# --------------------------------------------------------------------------

class _Tracer:
    """The simulator's ports: the keys held down, no Kempston joystick, and
    the border colour the game last sent out."""

    def __init__(self):
        from skoolkit.kbtracer import KEY_BITS
        self.key_bits = KEY_BITS
        self.keys: set[str] = set()
        self.border = 0

    def read_port(self, registers, port):
        if port & 0xFF == 0x1F:
            return 0
        if port & 1:
            return 0xFF
        result = 0xFF
        for key in self.keys:
            half_row, bits = self.key_bits[key]
            if port & half_row == 0:
                result &= bits
        return result

    def write_port(self, registers, port, value, offset=0):
        if port & 1 == 0:
            self.border = value & 7


def _simulator(memory, registers=None):
    from skoolkit import CSimulator
    from skoolkit.simulator import Simulator

    simulator = (CSimulator or Simulator)(list(memory), state={"iff": 0, "im": 1, "tstates": 0})
    if registers is not None:
        for index, value in enumerate(registers):
            simulator.registers[index] = value
    tracer = _Tracer()
    simulator.set_tracer(tracer)
    return simulator, tracer


def _run(simulator, stop: int, limit: int, interrupts: bool = False) -> bool:
    """Run to `stop` or to the T-state `limit`, whichever is first; True if
    it stopped at `stop`."""
    from skoolkit.simutils import PC

    if hasattr(simulator, "trace"):
        condition, _ = simulator.trace(simulator.registers[PC], stop, 0, limit, interrupts,
                                       None, None, None, None, None)
        return condition == 3
    from skoolkit.simutils import T
    while simulator.registers[T] < limit:           # the pure-Python simulator
        simulator.run(simulator.registers[PC])
        if simulator.registers[PC] == stop:
            return True
    return False


@functools.lru_cache(maxsize=None)
def _game(snapshot: str, sex: str) -> tuple:
    """A game just started, boy ("b") or girl ("g"): the build's own way from
    the title screen into play (build_antattack._start), then on to the end
    of a frame. Its memory and registers, to start scenes from."""
    from skoolkit import read_bin_file
    from skoolkit.simutils import SP, T

    memory = list(ba.game_memory(Path(snapshot)))
    memory[:0x4000] = read_bin_file(str(ba.ROM))
    simulator, tracer = _simulator(memory)
    simulator.registers[SP] = ba.LOADER_STACK
    pc = ba.PAST_LOAD_CHECKS
    from skoolkit.simutils import PC
    simulator.registers[PC] = pc
    for keys, seconds in ba._start(sex):
        tracer.keys = set(keys)
        _run(simulator, 0, simulator.registers[T] + int(seconds * ba.TSTATES_PER_SECOND), True)
    tracer.keys = set()
    if not _run(simulator, FRAME_END, simulator.registers[T] + RUN_LIMIT):
        raise RuntimeError("the game did not reach the end of a frame")
    return bytes(simulator.memory), tuple(simulator.registers)


@functools.lru_cache(maxsize=None)
def _plane_to_buffer(snapshot: str) -> tuple:
    """Where PLANE_TO_BUFFER puts each of the 512 places: the render buffer
    address of the top left of what is drawn there. Run with the carry clear,
    as DRAW_SPRITE calls it (its ADD A,$80 cannot carry)."""
    from skoolkit.simutils import F, H, L, SP

    memory = list(ba.game_memory(Path(snapshot)))
    memory[0x5B80:0x5B82] = [0x00, 0x5B]            # a return to $5B00
    simulator, _ = _simulator(memory)
    table = []
    for place in range(512):
        address = PLANES + place
        simulator.registers[H], simulator.registers[L] = address >> 8, address & 0xFF
        simulator.registers[F] = 0
        simulator.registers[SP] = 0x5B80
        simulator.run(PLANE_TO_BUFFER, 0x5B00)
        table.append(simulator.registers[H] * 256 + simulator.registers[L])
    return tuple(table)


class Frame:
    """What one frame of the game left: the screen at its end, the sprite
    list as PROJECT_SPRITES left it (in object order), the object records,
    and when the picture was copied to the screen."""

    def __init__(self, screen: bytes, border: int, t_start: int, t_copy: int, t_end: int,
                 sprites: bytes, objects: bytes, view: int, origin: tuple[int, int]):
        self.screen, self.border = screen, border
        self.t_start, self.t_copy, self.t_end = t_start, t_copy, t_end
        self.sprites, self.objects, self.view = sprites, objects, view
        self.origin = origin

    def record(self, index: int) -> bytes:
        return self.objects[RECORD * index:RECORD * (index + 1)]

    def sprite(self, index: int) -> tuple[int, int]:
        """The object's place and frame. The list runs from the fifth ant back
        to the player, three bytes each."""
        entry = 3 * (7 - index)
        return self.sprites[entry] + 256 * self.sprites[entry + 1], self.sprites[entry + 2]

    def in_view(self, index: int) -> bool:
        place, _ = self.sprite(index)
        return place >> 8 != 0xFF


class Capture:
    """A picture of the screen at a T-state, and the frame it belongs to."""

    def __init__(self, t: int, screen: bytes, border: int, frame_index: int):
        self.t, self.screen, self.border, self.frame_index = t, screen, border, frame_index


class Scene:
    """A game in progress, from a frame boundary, run a frame at a time."""

    def __init__(self, snapshot: Path, sex: str = "b", setup=None):
        memory, registers = _game(str(snapshot), sex)
        self.snapshot = snapshot
        self.sim, self.tracer = _simulator(memory, registers)
        self.buffer_table = _plane_to_buffer(str(snapshot))
        self.frames: list[Frame] = []
        self.captures: list[Capture] = []
        self.finished = False
        if setup is not None:
            setup(self.sim.memory)

    # The machine.
    def peek(self, address: int) -> int:
        return self.sim.memory[address]

    def poke(self, address: int, value: int) -> None:
        self.sim.memory[address] = value

    def record(self, index: int) -> list[int]:
        start = OBJECTS + RECORD * index
        return list(self.sim.memory[start:start + RECORD])

    def _t(self) -> int:
        from skoolkit.simutils import T
        return self.sim.registers[T]

    def _screen(self) -> bytes:
        return bytes(self.sim.memory[0x4000:0x5B00])

    def _run_to(self, stop: int, fine: bool) -> None:
        """Run to `stop`, reading the screen every ULA frame on the way when
        `fine` -- except in the middle of COPY_TO_SCREEN, which would catch a
        half-copied picture."""
        from skoolkit.simutils import PC

        limit = self._t() + RUN_LIMIT
        while True:
            if fine:
                slice_end = (self._t() // ULA_FRAME + 1) * ULA_FRAME
                if _run(self.sim, stop, min(slice_end, limit)):
                    return
                pc = self.sim.registers[PC]
                if not COPY_TO_SCREEN[0] <= pc <= COPY_TO_SCREEN[1]:
                    self.captures.append(Capture(self._t(), self._screen(), self.tracer.border,
                                                 len(self.frames)))
                if self._t() < limit:
                    continue
            elif _run(self.sim, stop, limit):
                return
            raise RuntimeError(f"no ${stop:04X} within {RUN_LIMIT} T-states "
                               f"(PC ${self.sim.registers[PC]:04X})")

    def frame(self, keys=(), fine: bool = False) -> Frame:
        """One frame of the game with `keys` held; kept, and returned."""
        if self.finished:
            raise RuntimeError("the game has stopped")
        self.tracer.keys = set(keys)
        t_start = self._t()
        self._run_to(DRAW_VIEW, fine)
        view = self.peek(VIEW)
        origin = (self.peek(VIEW_ORIGIN), self.peek(VIEW_ORIGIN + 1))
        self._run_to(PROJECTED, fine)
        sprites = bytes(self.sim.memory[SPRITE_LIST:SPRITE_LIST + 24])
        objects = bytes(self.sim.memory[OBJECTS:OBJECTS + 8 * RECORD])
        self._run_to(COPIED, fine)
        t_copy = self._t()
        self._run_to(FRAME_END, fine)
        frame = Frame(self._screen(), self.tracer.border, t_start, t_copy, self._t(),
                      sprites, objects, view, origin)
        self.frames.append(frame)
        self.captures.append(Capture(frame.t_end, frame.screen, frame.border,
                                     len(self.frames) - 1))
        # $B438 at 1 here means PLAY returns to BASIC instead of starting
        # another frame.
        if self.peek(FRAMES_LEFT) == 1:
            self.finished = True
        return frame

    def run(self, count: int, keys=(), fine: bool = False) -> list[Frame]:
        return [self.frame(keys, fine) for _ in range(count)]

    def box(self, frame: Frame, index: int):
        """Where the object's sprite was drawn, as a box of screen pixels, or
        None if it was out of view."""
        place, _ = frame.sprite(index)
        if place >> 8 == 0xFF or place == 0 or place > 7 * 512:
            return None
        address = self.buffer_table[(place - 1) & 0x1FF] - RENDER_BUFFER
        x, y = 8 * (address % 32), address // 32
        return x, y, x + 16, y + 16


# --------------------------------------------------------------------------
# Staging.
# --------------------------------------------------------------------------

def _cell(x: int, y: int) -> int:
    return 0xC000 + 128 * (y - 0x80) + (x - 0x80)


def _inside(x: int, y: int) -> bool:
    return x >= 0x80 and y >= 0x80


def _map_bit(memory, x: int, y: int, height: int) -> None:
    """TOGGLE_MAP_BIT's XOR, for an ant being moved (see _move)."""
    if _inside(x, y) and height < 6:
        memory[_cell(x, y)] ^= 1 << height


def _move(memory, index: int, x: int, y: int, height: int = 0, facing: int | None = None) -> None:
    """Put an object somewhere. An ant carries its bit in the city map with it
    (MOVE_ANT takes it out and puts it back each move), so moving one moves
    the bit too; nothing else is in the map."""
    record = OBJECTS + RECORD * index
    if index in ANTS:
        _map_bit(memory, *memory[record:record + 3])
    memory[record:record + 3] = [x, y, height]
    if index in ANTS:
        _map_bit(memory, x, y, height)
    if facing is not None:
        memory[record + FACING] = facing


def _park(memory, index: int) -> None:
    """Out of the way: outside the walls, far off, and -- for an ant --
    paralysed, which ANT_TURN takes as nothing to do; for the rescued person,
    still waiting."""
    record = OBJECTS + RECORD * index
    _move(memory, index, PARKING[0] + 2 * index, PARKING[1], 0)
    memory[record + BLAST] = 0
    if index in ANTS:
        memory[record + STUN] = PARALYSED
    elif index == RESCUEE:
        memory[record + STATE] = 0
        memory[record + STUN] = 0


def _park_all(memory, keep=()) -> None:
    for index in [RESCUEE] + ANTS:
        if index not in keep:
            _park(memory, index)


def _open_ground(memory, size: int = 19) -> tuple[int, int]:
    """The middle of the first empty square of `size` cells inside the walls."""
    x, y = ba._open_ground(memory, size)
    return x + size // 2, y + size // 2


def _centre_view(memory, x: int, y: int) -> None:
    """View 0, with its origin where READ_VIEW_KEYS puts it for SPACE: the
    player's cell less ($FD, $12)."""
    memory[VIEW] = 0
    memory[VIEW_ORIGIN] = (x - 0xFD) & 0xFF
    memory[VIEW_ORIGIN + 1] = (y - 0x12) & 0xFF


def _stand(memory, index: int) -> None:
    """Steady on its feet: not falling, stunned or exploding, and in its
    first animation frame. (The flags are left alone: an ant's move bit is
    always set, and the people's are set afresh every frame.)"""
    record = OBJECTS + RECORD * index
    memory[record + FALL] = memory[record + STUN] = memory[record + BLAST] = 0
    memory[record + ANIM] = 0


def _full_energy(memory) -> None:
    memory[PLAYER_ENERGY_LOW] = memory[RESCUEE_ENERGY_LOW] = 20
    memory[TIME + 1] = 200


# The four directions (STEP): 0 y up, 1 x up, 2 y down, 3 x down.
STEPS = [(0, 1), (1, 0), (0, -1), (-1, 0)]


def _player_on_open_ground(facing: int, back: int = 0):
    """The player alone on open ground, facing `facing`, `back` cells behind
    the middle, with the view centred on them."""
    def setup(memory):
        _park_all(memory)
        _full_energy(memory)
        x, y = _open_ground(memory)
        dx, dy = STEPS[facing]
        x, y = x - back * dx, y - back * dy
        _move(memory, PLAYER, x, y, 0, facing)
        _stand(memory, PLAYER)
        _centre_view(memory, x, y)
    return setup


# --------------------------------------------------------------------------
# Pictures.
# --------------------------------------------------------------------------

def _picture(screen: bytes, t: int, border: int | None = None):
    """The screen as a PIL image, FLASH in the phase the ULA has at T-state
    `t`; with a border of that colour if one is given."""
    from PIL import Image

    flash = (t // ULA_FRAME // FLASH_FRAMES) & 1
    image = Image.new("RGB", (256, 192))
    pixels = image.load()
    for y in range(192):
        row = ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2)
        for column in range(32):
            byte = screen[row + column]
            attr = screen[0x1800 + (y >> 3) * 32 + column]
            palette = ba.SPECTRUM_BRIGHT if attr & 0x40 else ba.SPECTRUM
            ink, paper = palette[attr & 7], palette[(attr >> 3) & 7]
            if attr & 0x80 and flash:
                ink, paper = paper, ink
            for bit in range(8):
                pixels[column * 8 + bit, y] = ink if byte & (0x80 >> bit) else paper
    if border is None:
        return image
    framed = Image.new("RGB", (256 + 32, 192 + 32), ba.SPECTRUM[border])
    framed.paste(image, (16, 16))
    return framed


def _union(boxes):
    boxes = [b for b in boxes if b is not None]
    if not boxes:
        return None
    return (min(b[0] for b in boxes), min(b[1] for b in boxes),
            max(b[2] for b in boxes), max(b[3] for b in boxes))


def _signed(value: int) -> int:
    return value - 256 if value & 0x80 else value


def _shift(frame: Frame, first: Frame) -> tuple[int, int]:
    """How far the view has scrolled since `first`, in screen pixels: in
    view 0 a cell (u, v) from the origin is drawn 8(u + v) across and
    4(v - u) down (the projection #R$8600 and the city page use), so moving
    the origin moves everything the other way."""
    du = _signed((frame.origin[0] - first.origin[0]) & 0xFF)
    dv = _signed((frame.origin[1] - first.origin[1]) & 0xFF)
    return 8 * (du + dv), 4 * (dv - du)


def crop_boxes(scene: Scene, frames: list[Frame], objects: list[int], margin: int = 4) -> list:
    """A box for each frame, fixed on the ground rather than on the screen --
    where the view scrolls to follow the player (#R$8460) the box scrolls with
    it -- round everything `objects` drew in all of them, with a margin.
    Every frame must be in view 0."""
    if any(frame.view != 0 for frame in frames):
        raise ValueError("a box fixed on the ground is worked out for view 0 only")
    shifts = [_shift(frame, frames[0]) for frame in frames]
    boxes = []
    for frame, (sx, sy) in zip(frames, shifts):
        for index in objects:
            box = scene.box(frame, index)
            if box is not None:
                boxes.append((box[0] + sx, box[1] + sy, box[2] + sx, box[3] + sy))
    union = _union(boxes)
    if union is None:
        raise ValueError("nothing was drawn")
    left, top, right, bottom = (union[0] - margin, union[1] - margin,
                                union[2] + margin, union[3] + margin)
    return [(left - sx, top - sy, right - sx, bottom - sy) for sx, sy in shifts]


def scrolled(frames: list[Frame]) -> int:
    """How many times the view moved in these frames."""
    return sum(1 for a, b in zip(frames, frames[1:]) if a.origin != b.origin)


def _label(frame: Frame, objects: list[int]) -> str:
    frames = [f"${frame.sprite(i)[1]:02X}" for i in objects if frame.in_view(i)]
    return "+".join(frames) or "-"


def _ms(tstates: int) -> float:
    return tstates / T_STATES_PER_MS


def _crop_play(picture, box, screen: bytes):
    """`box` out of the picture, with anything beyond the play area -- a box
    fixed on the ground can run past it once the view has scrolled -- filled
    with the play area's paper, the colour of open ground."""
    from PIL import Image

    left, top, right, bottom = PLAY_AREA
    if box[0] >= left and box[1] >= top and box[2] <= right and box[3] <= bottom:
        return picture.crop(box)
    attr = screen[0x1800 + 32 * (top // 8 + 1) + 2]
    palette = ba.SPECTRUM_BRIGHT if attr & 0x40 else ba.SPECTRUM
    out = Image.new("RGB", (box[2] - box[0], box[3] - box[1]), palette[(attr >> 3) & 7])
    inner = (max(box[0], left), max(box[1], top), min(box[2], right), min(box[3], bottom))
    if inner[0] < inner[2] and inner[1] < inner[3]:
        out.paste(picture.crop(inner), (inner[0] - box[0], inner[1] - box[1]))
    return out


def frames_by_frame(scene: Scene, frames: list[Frame], box, objects: list[int]) -> list[tuple]:
    """A picture for each game frame, lasting from the copy that put it on
    the screen to the next copy (the last, for its own frame's length).
    `box` is one crop for all, or a list of one per frame."""
    out = []
    for index, frame in enumerate(frames):
        crop = box[index] if isinstance(box, list) else box
        if index + 1 < len(frames):
            tstates = frames[index + 1].t_copy - frame.t_copy
        else:
            tstates = frame.t_end - frame.t_start
        picture = _crop_play(_picture(frame.screen, frame.t_end), crop, frame.screen)
        out.append((picture, tstates, _label(frame, objects)))
    return out


def frames_by_time(scene: Scene, first: int, box, objects: list[int],
                   hold: int = 0) -> list[tuple]:
    """A picture for every reading of the screen from the start of frame
    `first` on (a scene run with fine=True), each lasting until the next;
    the last one for `hold` T-states."""
    t0 = scene.frames[first].t_start
    captures = [c for c in scene.captures if c.t > t0]
    out = []
    for index, capture in enumerate(captures):
        end = captures[index + 1].t if index + 1 < len(captures) else capture.t + hold
        picture = _picture(capture.screen, capture.t).crop(box)
        frame = scene.frames[min(capture.frame_index, len(scene.frames) - 1)]
        out.append((picture, end - capture.t, _label(frame, objects)))
    return out


def merge(frames: list[tuple]) -> list[tuple]:
    """Consecutive identical pictures as one, for their total time; T-states
    to milliseconds, to the 10ms a GIF can say (20ms at the least)."""
    out = []
    for picture, tstates, label in frames:
        if out and out[-1][0].tobytes() == picture.tobytes():
            out[-1][1] += tstates
        else:
            out.append([picture, tstates, label])
    return [(picture, max(20, round(_ms(t) / 10) * 10), label) for picture, t, label in out]


def save_gif(path: Path, frames: list[tuple]) -> None:
    from PIL import Image

    palette = Image.new("P", (1, 1))
    flat = [c for colour in PALETTE for c in colour]
    palette.putpalette(flat + [0] * (768 - len(flat)))
    images = [picture.quantize(palette=palette, dither=Image.Dither.NONE)
              for picture, _, _ in frames]
    images[0].save(path, save_all=True, append_images=images[1:], loop=0,
                   duration=[ms for _, ms, _ in frames], disposal=1, optimize=False)


def _animation(key: str, frames: list[tuple], sprites: list[int], scale: int = 3,
               facts: dict | None = None) -> dict:
    return {"key": key, "frames": merge(frames), "sprites": sprites, "scale": scale,
            "facts": facts or {}}


def _sprites_seen(scene: Scene, frames: list[Frame], objects: list[int]) -> list[int]:
    seen = []
    for frame in frames:
        for index in objects:
            if frame.in_view(index) and frame.sprite(index)[1] not in seen:
                seen.append(frame.sprite(index)[1])
    return seen


# --------------------------------------------------------------------------
# The animations.
# --------------------------------------------------------------------------

WALK_STEPS = 8


def walking(snapshot: Path, sex: str, facing: int) -> dict:
    """The player alone on open ground, walking WALK_STEPS cells with V held."""
    scene = Scene(snapshot, sex, _player_on_open_ground(facing, back=WALK_STEPS // 2))
    scene.frame()                                   # a frame standing, first
    frames = scene.run(WALK_STEPS, ["v"])
    box = crop_boxes(scene, frames, [PLAYER])
    key = f"{'boy' if sex == 'b' else 'girl'}-walking-{facing}"
    return _animation(key, frames_by_frame(scene, frames, box, [PLAYER]),
                      _sprites_seen(scene, frames, [PLAYER]),
                      facts={"scrolled": scrolled(frames)})


def jumping(snapshot: Path, sex: str = "b") -> dict:
    """C held on open ground: a jump, and another."""
    scene = Scene(snapshot, sex, _player_on_open_ground(1))
    scene.frame()
    frames = scene.run(10, ["c"])
    frames += scene.run(2)
    box = crop_boxes(scene, frames, [PLAYER])
    heights = [f.record(PLAYER)[HEIGHT] for f in frames]
    return _animation("jumping", frames_by_frame(scene, frames, box, [PLAYER]),
                      _sprites_seen(scene, frames, [PLAYER]), facts={"heights": heights})




def climbing(snapshot: Path, sex: str = "b") -> dict:
    """Over a one-block wall: walk up to it, V and C together for a frame to
    rise, and walk on over the top and down the other side."""
    wall = _low_wall(ba.game_memory(snapshot))

    def setup(memory):
        _park_all(memory)
        _full_energy(memory)
        x, y = wall
        _move(memory, PLAYER, x, y - 2, 0, 0)
        _stand(memory, PLAYER)
        _centre_view(memory, x, y)
    scene = Scene(snapshot, sex, setup)
    scene.frame()
    frames = []
    for keys in (["v"], ["v", "c"], ["v"], ["v"], ["v"], [], [], [], []):
        frames.append(scene.frame(keys))
    box = crop_boxes(scene, frames, [PLAYER], margin=6)
    heights = [f.record(PLAYER)[HEIGHT] for f in frames]
    return _animation("climbing", frames_by_frame(scene, frames, box, [PLAYER]),
                      _sprites_seen(scene, frames, [PLAYER]),
                      facts={"heights": heights, "wall": wall})


def _low_wall(memory) -> tuple[int, int]:
    """A cell with one block on the ground, with open cells either side of it
    along y: somewhere to climb over."""
    for y in range(0xF0, 0x84, -1):
        for x in range(0x88, 0xF8):
            if (memory[_cell(x, y)] == 1
                    and all(memory[_cell(x, y + d)] == 0 for d in (-3, -2, -1, 1, 2, 3))
                    and all(memory[_cell(x + dx, y + d)] == 0
                            for dx in (-1, 1) for d in (-2, -1, 1, 2))):
                return x, y
    raise RuntimeError("no one-block wall with room either side")


def falling(snapshot: Path, sex: str = "b") -> dict:
    """The player five blocks up over open ground: a bad fall."""
    def setup(memory):
        _player_on_open_ground(0)(memory)
        memory[OBJECTS + HEIGHT] = 5
    scene = Scene(snapshot, sex, setup)
    frames, stunned = [], False
    for _ in range(120):
        frames.append(scene.frame())
        stun = frames[-1].record(PLAYER)[STUN]
        stunned = stunned or stun > 0
        if stunned and stun == 0:
            break
    frames += scene.run(2)
    box = crop_boxes(scene, frames, [PLAYER])
    return _animation("falling", frames_by_frame(scene, frames, box, [PLAYER]),
                      _sprites_seen(scene, frames, [PLAYER]),
                      facts={"falls": max(f.record(PLAYER)[FALL] for f in frames),
                             "stun": max(f.record(PLAYER)[STUN] for f in frames),
                             "frames": len(frames)})


# The ants. The first ant is the fast one (+$0D 20, line 140's DATA), and
# it is the one each scene uses; the others are parked.
ANT = ANTS[0]


def _ant_scene(snapshot: Path, ant_at, player_at, ant_facing: int, player_facing: int,
               centre, extra=None, ant: int = ANT) -> Scene:
    def setup(memory):
        _park_all(memory, keep=[ant])
        _full_energy(memory)
        x, y = _open_ground(memory)
        _move(memory, PLAYER, x + player_at[0], y + player_at[1], 0, player_facing)
        _stand(memory, PLAYER)
        _move(memory, ant, x + ant_at[0], y + ant_at[1], 0, ant_facing)
        _stand(memory, ant)
        record = OBJECTS + RECORD * ant
        memory[record + COUNT] = memory[record + STATE]      # a full count to its skip
        _centre_view(memory, x + centre[0], y + centre[1])
        if extra is not None:
            extra(memory, x, y)
    return Scene(snapshot, "b", setup)


def ant_walking(snapshot: Path, facing: int) -> dict:
    """The fast ant walking at the player, ten cells off, the way it faces."""
    dx, dy = STEPS[facing]
    scene = _ant_scene(snapshot, (-4 * dx, -4 * dy), (6 * dx, 6 * dy), facing, facing,
                       (-1 * dx, -1 * dy))
    scene.frame()
    frames = scene.run(6)
    box = crop_boxes(scene, frames, [ANT])
    return _animation(f"ant-walking-{facing}", frames_by_frame(scene, frames, box, [ANT]),
                      _sprites_seen(scene, frames, [ANT]))


HOLD = ba.TSTATES_PER_SECOND // 2      # the last picture of a scene read by time


def ant_biting(snapshot: Path) -> dict:
    """The fast ant two cells from the player, facing them, and walking in."""
    scene = _ant_scene(snapshot, (2, 0), (0, 0), 3, 1, (1, 0))
    scene.frame()
    for _ in range(14):
        scene.frame(fine=True)
    frames = scene.frames[1:]
    events = [(f.record(PLAYER)[HEIGHT], f.record(ANT)[X] - f.record(PLAYER)[X])
              for f in frames]
    return _animation("ant-biting", frames_by_time(scene, 1, PLAY_AREA, [PLAYER, ANT],
                                                   hold=HOLD),
                      _sprites_seen(scene, frames, [PLAYER, ANT]), scale=2,
                      facts={"events": events})


def grenade(snapshot: Path) -> dict:
    """F, the eight-frame throw, across open ground: the flight and the blast,
    until the grenade has gone home."""
    scene = Scene(snapshot, "b", _player_on_open_ground(1, back=5))
    scene.frame()
    frames = [scene.frame(["f"])]
    for _ in range(40):
        frames.append(scene.frame())
        if not frames[-1].in_view(GRENADE):
            break
    frames.append(scene.frame())
    box = crop_boxes(scene, frames, [PLAYER, GRENADE])
    blast = [f.record(GRENADE)[BLAST] for f in frames]
    return _animation("grenade", frames_by_frame(scene, frames, box, [PLAYER, GRENADE]),
                      _sprites_seen(scene, frames, [PLAYER, GRENADE]), scale=2,
                      facts={"blast": blast, "frames": len(frames)})


def _grenade_at_ant(snapshot: Path, start: int, ant: int, frames_after: int = 60):
    """The ant walking at the player from `start` cells, and a grenade thrown
    at it with D (four frames) on the first frame. Runs until the ant is
    neither stunned nor exploding again, or out of view; the scene and its
    frames from the throw."""
    scene = _ant_scene(snapshot, (start // 2, 0), (-(start - start // 2), 0), 3, 1, (0, 0),
                       ant=ant)
    scene.frame()
    frames = [scene.frame(["d"])]
    hit = False
    for _ in range(frames_after):
        frames.append(scene.frame())
        record = frames[-1].record(ant)
        busy = record[STUN] > 0 or record[BLAST] > 0
        hit = hit or busy
        if hit and (not busy or not frames[-1].in_view(ant)):
            break
    frames += scene.run(3)
    return scene, frames


def _first_hit(snapshot: Path, ant: int, want_blast: bool):
    """The nearest start from which the grenade stuns the ant (or, with
    want_blast, blows it up): found by running the throw from each."""
    for start in range(6, 20):
        scene, frames = _grenade_at_ant(snapshot, start, ant)
        blasted = any(f.record(ant)[BLAST] for f in frames)
        stunned = any(f.record(ant)[STUN] for f in frames)
        if blasted if want_blast else (stunned and not blasted):
            return start, scene, frames
    raise RuntimeError("no start distance gives that")


def ant_stunned(snapshot: Path) -> dict:
    """The fast ant walking at the player, and a grenade bursting five to
    seven cells short of it: stunned for 24 frames, then on again."""
    start, scene, frames = _first_hit(snapshot, ANT, False)
    box = crop_boxes(scene, frames, [ANT, GRENADE])
    return _animation("ant-stunned", frames_by_frame(scene, frames, box, [ANT, GRENADE]),
                      _sprites_seen(scene, frames, [ANT, GRENADE]), scale=2,
                      facts={"start": start,
                             "stun": [f.record(ANT)[STUN] for f in frames],
                             "facing": [f.record(ANT)[FACING] & 3 for f in frames]})


def ant_blown_up(snapshot: Path, ant: int = ANTS[1]) -> dict:
    """A grenade bursting within four cells of an ant, which is blown up and
    sent home. A slow ant (+$0D 2, from BASIC's sp), which skips every other
    frame -- and it matters: see the text."""
    start, scene, frames = _first_hit(snapshot, ant, True)
    box = crop_boxes(scene, frames, [ant, GRENADE])
    key = "ant-blown-up" if ant != ANT else "ant-blown-up-fast"
    return _animation(key, frames_by_frame(scene, frames, box, [ant, GRENADE]),
                      _sprites_seen(scene, frames, [ant, GRENADE]), scale=2,
                      facts={"start": start,
                             "blast": [f.record(ant)[BLAST] for f in frames],
                             "anim": [f.record(ant)[ANIM] for f in frames],
                             "drawn": [f.sprite(ant)[1] if f.in_view(ant) else None
                                       for f in frames]})


def paralysing(snapshot: Path) -> dict:
    """The player three blocks up over a stunned ant, as the build's
    _drop_on_ant stages it: the landing paralyses the ant for good."""
    def stunned_ant(memory, x, y):
        memory[OBJECTS + HEIGHT] = 3
        memory[OBJECTS + RECORD * ANT + STUN] = 0x40
    scene = _ant_scene(snapshot, (0, 0), (0, 0), 2, 1, (0, 0), stunned_ant)
    scene.frame()
    for _ in range(9):
        scene.frame(fine=True)
    frames = scene.frames[1:]
    return _animation("paralysing", frames_by_time(scene, 1, PLAY_AREA, [PLAYER, ANT],
                                                   hold=HOLD),
                      _sprites_seen(scene, frames, [PLAYER, ANT]), scale=2,
                      facts={"stun": [f.record(ANT)[STUN] for f in frames],
                             "height": [f.record(PLAYER)[HEIGHT] for f in frames]})


VIEW_KEYS = [("0", 3), ("p", 2), ("ENTER", 1), ("SPACE", 0)]


def view_turning(snapshot: Path) -> dict:
    """A game just started, at the city gate: the four view keys in turn."""
    scene = Scene(snapshot, "b")
    scene.frame()
    frames = [scene.frame()]
    for key, _ in VIEW_KEYS:
        frames.append(scene.frame([key]))
        frames += scene.run(4)
    views = [f.view for f in frames]
    return _animation("view-turning", frames_by_frame(scene, frames, PLAY_AREA, [PLAYER]),
                      _sprites_seen(scene, frames, [PLAYER]), scale=2,
                      facts={"views": views})


def rescue(snapshot: Path) -> list[dict]:
    """The person waiting on open ground, the player walking up to them:
    found (script 12), then followed about, round a corner."""
    def setup(memory):
        _park_all(memory)
        _full_energy(memory)
        x, y = _open_ground(memory)
        _move(memory, PLAYER, x, y - 4, 0, 0)
        _stand(memory, PLAYER)
        _move(memory, RESCUEE, x, y + 3, 0, 2)
        _stand(memory, RESCUEE)
        memory[OBJECTS + RECORD * RESCUEE + STATE] = 0
        _centre_view(memory, x, y)
    scene = Scene(snapshot, "b", setup)
    scene.frame()
    first = len(scene.frames)
    for _ in range(6):
        scene.frame(["v"], fine=True)
        if scene.peek(OBJECTS + RECORD * RESCUEE + STATE):
            break
    found = len(scene.frames) - 1
    scene.run(2, fine=True)
    hero = _animation("my-hero", frames_by_time(scene, first, PLAY_AREA, [PLAYER, RESCUEE],
                                                hold=HOLD),
                      _sprites_seen(scene, scene.frames[first:], [PLAYER, RESCUEE]), scale=2,
                      facts={"found": found - first})
    start = len(scene.frames)
    for keys in [["v"]] * 5 + [["SS"]] + [["v"]] * 6 + [[]] * 3:
        scene.frame(keys)
    frames = scene.frames[start:]
    box = crop_boxes(scene, frames, [PLAYER, RESCUEE])
    follow = _animation("following", frames_by_frame(scene, frames, box, [PLAYER, RESCUEE]),
                        _sprites_seen(scene, frames, [PLAYER, RESCUEE]), scale=2,
                        facts={"scrolled": scrolled(frames),
                               "distance": [abs(f.record(PLAYER)[X] - f.record(RESCUEE)[X])
                                            + abs(f.record(PLAYER)[Y] - f.record(RESCUEE)[Y])
                                            for f in frames]})
    return [hero, follow]


GATE = (0xB9, 0xFD)         # inside the gate, on the line the player starts on


def walking_out(snapshot: Path) -> dict:
    """The player a step inside the gate, the rescued person following two
    cells behind, walking out: script 13, and the game stops."""
    def setup(memory):
        _park_all(memory)
        _full_energy(memory)
        x, y = GATE
        _move(memory, PLAYER, x, y, 0, 0)
        _stand(memory, PLAYER)
        _move(memory, RESCUEE, x, y - 2, 0, 0)
        _stand(memory, RESCUEE)
        memory[OBJECTS + RECORD * RESCUEE + STATE] = 1
        _centre_view(memory, x, y)
    scene = Scene(snapshot, "b", setup)
    scene.frame()
    for _ in range(12):
        scene.frame(["v"], fine=True)
        if scene.finished:
            break
    frames = scene.frames[1:]
    return _animation("walking-out", frames_by_time(scene, 1, PLAY_AREA, [PLAYER, RESCUEE],
                                                    hold=2 * ba.TSTATES_PER_SECOND),
                      _sprites_seen(scene, frames, [PLAYER, RESCUEE]), scale=2,
                      facts={"finished": scene.finished, "frames": len(frames)})


ENDING_LIMIT = 120 * ba.TSTATES_PER_SECOND      # BASIC's ending, as a bound
ENDING_HOLD = 3 * ba.TSTATES_PER_SECOND         # the last screen, flashing
PLAY_RETURNS = 0x8033       # PLAY's RET to BASIC
KEY_HOLD = int(0.2 * ba.TSTATES_PER_SECOND)


def _basic_number(memory, name: str, value: int) -> None:
    """Set a BASIC numeric variable with a name of two letters or more to a
    small integer: the name's first letter with bits 5 and 7 set, the middle
    letters, the last with bit 7 set, then the five bytes of the number (as
    build_antattack._one_rescue_to_win does for fin)."""
    code = (bytes([0xA0 + ord(name[0]) - 0x60]) + name[1:-1].encode("ascii")
            + bytes([ord(name[-1]) | 0x80]))
    start, end = ba._word(memory, ba.VARS), ba._word(memory, 23641)
    at = bytes(memory[start:end]).find(code)
    if at < 0:
        raise RuntimeError(f"no variable {name} in the BASIC variables")
    number = start + at + len(code)
    memory[number:number + 5] = [0, 0, value & 0xFF, value >> 8, 0]


def _lead_out(scene: Scene) -> None:
    """Both people outside the walls, the one to be rescued following: the
    rescue, in one frame."""
    ba._both_outside(scene.sim.memory)
    scene.poke(OBJECTS + RECORD * RESCUEE + STATE, 1)
    scene.frame()
    if not scene.finished:
        raise RuntimeError("the rescue did not stop the game")


def _through_basic_to_play(scene: Scene) -> None:
    """From PLAY's return, through BASIC's score card and the next level's
    story and READY, each key wait answered with SPACE, into the next
    level's play."""
    sim, t = scene.sim, scene._t
    for _ in range(2):
        if not _run(sim, WAIT_KEY, t() + ENDING_LIMIT, True):
            raise RuntimeError("BASIC did not wait for a key")
        scene.tracer.keys = {"SPACE"}
        _run(sim, 0, t() + KEY_HOLD, True)
        scene.tracer.keys = set()
    if not _run(sim, FRAME_END, t() + ENDING_LIMIT, True):
        raise RuntimeError("the next level did not start")
    scene.finished = False


def ending(snapshot: Path) -> dict:
    """The tenth rescue, with BASIC's variables as a real one leaves them:
    a first rescue made by putting both people outside the walls, then
    BASIC's sg (the rescues so far) set to 8 as PLAY returns, so that line
    90 counts it to 9 and BASIC sets up the tenth level itself -- its story
    card, its variables. Then a second rescue, which line 95 takes for the
    tenth; BASIC runs, with interrupts, from line 3600 -- GO SUB 2000's
    screen, script 17 through USR 36594, the medal drawn with CIRCLE --
    until it waits for a key after line 2600's prompt."""
    scene = Scene(snapshot, "b")
    _lead_out(scene)
    if not _run(scene.sim, PLAY_RETURNS, scene._t() + RUN_LIMIT):
        raise RuntimeError("PLAY did not return")
    _basic_number(scene.sim.memory, "sg", 8)
    _through_basic_to_play(scene)
    _lead_out(scene)
    sim, t = scene.sim, scene._t
    limit = t() + ENDING_LIMIT
    captures = []
    started = False
    while True:
        if t() >= limit:
            raise RuntimeError("the ending did not reach its key wait")
        slice_end = (t() // ULA_FRAME + 1) * ULA_FRAME
        at_key = _run(sim, WAIT_KEY, slice_end, True)
        line = scene.peek(PPC) + 256 * scene.peek(PPC + 1)
        started = started or line == ENDING_LINE
        if started:
            captures.append(Capture(t(), scene._screen(), scene.tracer.border, 0))
        if at_key and started:
            break
    # The key wait loops for ever; hold the last screen, flashing.
    end = t() + ENDING_HOLD
    while t() < end:
        _run(sim, 0, (t() // ULA_FRAME + 1) * ULA_FRAME, True)
        captures.append(Capture(t(), scene._screen(), scene.tracer.border, 0))
    frames = []
    for index, capture in enumerate(captures[:-1]):
        picture = _picture(capture.screen, capture.t, capture.border)
        frames.append((picture, captures[index + 1].t - capture.t, "-"))
    return _animation("ending", frames, [], scale=2,
                      facts={"seconds": (captures[-1].t - captures[0].t) / ba.TSTATES_PER_SECOND})


# --------------------------------------------------------------------------
# The page.
# --------------------------------------------------------------------------

_ENTRY_RE = re.compile(r"^[bcgistuw]\$([0-9A-F]{4})")


@functools.lru_cache(maxsize=None)
def _entry_starts(skool: str) -> frozenset:
    starts = set()
    path = Path(skool)
    if path.exists():
        for line in path.read_text(encoding="utf-8").splitlines():
            match = _ENTRY_RE.match(line)
            if match:
                starts.add(int(match.group(1), 16))
    return frozenset(starts)


def _links(text: str, starts: frozenset) -> str:
    """#R$ADDR only where ADDR starts an entry in the listing; plain $ADDR
    elsewhere."""
    return re.sub(r"#R\$([0-9A-F]{4})",
                  lambda m: m.group(0) if int(m.group(1), 16) in starts else "$" + m.group(1),
                  text)


def _frame_link(frame: int) -> str:
    return f"${frame:02X} (#R${SPRITE_BASE + 64 * frame:04X})"


MAX_LISTED = 16


def _order(frames: list[tuple]) -> str:
    """The sprite frames in each picture of the GIF with how long it lasts;
    pictures in a row showing the same frames as one run."""
    runs = []
    for _, ms, label in frames:
        if runs and runs[-1][0] == label:
            runs[-1][1] += 1
            runs[-1][2] += ms
        else:
            runs.append([label, 1, ms])
    parts = [f"{label} ({ms}ms)" if count == 1 else f"{label} x{count} ({ms}ms)"
             for label, count, ms in runs]
    total = sum(ms for _, ms, _ in frames) / 1000
    if len(parts) > MAX_LISTED:
        parts = parts[:MAX_LISTED - 2] + ["and so on"]
    return ", ".join(parts) + f": {len(frames)} pictures, {total:.1f}s in all"


def _script(memory, number: int) -> str:
    """A script by number, with its words as the game has them (read from the
    game as the page is built)."""
    words = ba.script_text(memory, ba.script_addresses(memory)[number - 1])
    if not words:
        return f"script {number}, a sound with no words"
    return f"script {number} (<em>{_esc(words)}</em>)"


def _bites(heights: list[int]) -> int:
    return sum(1 for a, b in zip(heights, heights[1:]) if b > a)


def _ordinal(n: int) -> str:
    return {1: "first", 2: "second", 3: "third", 4: "fourth", 5: "fifth"}.get(n, f"{n}th")


def _words(key: str, animation: dict, memory) -> tuple[str, str]:
    """The title and the paragraph for an animation, with what its run
    measured written in."""
    facts = animation["facts"]
    frames = animation["frames"]
    if key.startswith(("boy-walking", "girl-walking")):
        who = "boy" if key.startswith("boy") else "girl"
        first = 0xDC if who == "boy" else 0x6C
        return (f"The {who} walking", (
            f"V held (#R$8060 sets the move bit, +7 bit 2) on open ground, the view at 0, the "
            f"other people and the ants parked out of the way. #R$8800 steps the {who} a cell "
            f"a frame, and #R$8980 turns the animation frame (+8) over, 0, 1, 0, 1, while the "
            f"move bit is set: the standing pose (${first:02X} + facing) and the walking pose "
            f"(${first + 4:02X} + facing) take turns, one cell each. The facing added is the "
            f"{who}'s own plus the view (#R$8600), so in view 0 it is the direction walked: 0 "
            f"is y up, 1 x up, 2 y down, 3 x down. Each facing is its own GIF, eight steps "
            f"from a frame standing; each picture is one frame of the game, about "
            f"{frames[0][1]}ms. The picture is fixed on the ground: where the view scrolls "
            f"to keep the {who} near the middle (#R$8460) the picture scrolls with it."))
    if key == "jumping":
        return ("Jumping", (
            f"C held on open ground. Standing, #R$8800 takes the jump bit to #R$88D0, which "
            f"lifts the boy a block if the cell above is clear; with nothing under him, "
            f"#R$8880 lets him have one frame where he is and then drops him a block; "
            f"#R$8860 lands him after two frames of falling, which stuns him for two frames "
            f"(the arms-out pose, #R$8980) and counts as a step (a click, #R$8F00). Then, C "
            f"still held, again. His height frame by frame: "
            f"{', '.join(str(h) for h in facts['heights'])}. A jump is one block up, and "
            f"nothing sideways unless V is held too."))
    if key == "climbing":
        x, y = facts["wall"]
        return ("Climbing over a wall", (
            f"A wall one block high at ${x:02X}, ${y:02X}. V to walk up to it, then V and C "
            f"together for one frame: #R$88D0 lifts the boy a block, and #R$8880's frame of "
            f"grace lets him walk forward in the air -- onto the top of the wall. V again "
            f"walks him off the far side, where the same grace carries him a cell out before "
            f"he drops, and #R$8860 stuns him for two frames on landing. His height frame by "
            f"frame: {', '.join(str(h) for h in facts['heights'])}."))
    if key == "falling":
        return ("A bad fall", (
            f"The boy put five blocks up over open ground. #R$8880 gives him a frame where he "
            f"is, then drops him a block a frame; #R$8980 shows the arms-up pose (4) from the "
            f"second frame of falling. He lands after {facts['falls']} frames: five or more "
            f"is a bad fall (#R$8860), stunned for eight frames for each frame fallen -- "
            f"{facts['stun']} here -- and {_script(memory, 1)}. While the stun is five or "
            f"more he lies flat (pose 3), then for the last four frames stands with his arms "
            f"out (pose 2), then gets up: the whole thing took {facts['frames']} frames of the "
            f"game."))
    if key.startswith("ant-walking"):
        return ("An ant walking", (
            "The fast ant (the first, +$0D 20, line 140's DATA) walking at the boy along "
            "each of the four directions. #R$8A00 moves it and, when the move brought it "
            "closer to him, turns its animation frame over, 0, 1, 0, 1: $F8 + facing and "
            "$FC + facing, one foot and the other. That is the only thing that writes an "
            "ant's +8 apart from the blast (below), so an ant has two poses. #R$8A5D skips "
            "the move one frame in every +$0D: 20 for this ant, 2 -- every other frame -- "
            "for the others until the fourth rescue."))
    if key == "ant-biting":
        heights = [h for h, _ in facts["events"]]
        return ("An ant biting", (
            f"The fast ant two cells from the boy, facing him. Nothing is solid but the map, "
            f"and the boy is not in it, so the ant walks straight into his cell (#R$8800). The "
            f"ant is in the map (#R$8940), so on the boy's next move #R$8800 finds a block in "
            f"his own cell: #R$88A0, a bite, pushes him up a block, and #R$8F00 takes a point "
            f"of energy and runs {_script(memory, 7)}. He falls back into the ant's cell and "
            f"is bitten again: {_bites(heights)} bites in {len(heights)} frames. The screen "
            f"is read every fiftieth of a second, so the words appear as the script prints "
            f"them; the next frame's copy wipes them. The whole play area is shown, since "
            f"that is where the words go."))
    if key == "ant-stunned":
        stunned = sum(1 for n in facts["stun"] if n)
        return ("An ant stunned by a grenade", (
            f"The fast ant walking at the boy from {facts['start']} cells, and a grenade "
            f"thrown at it with D, four frames' flight. It bursts five to seven cells short "
            f"of the ant -- the nearest start that does, found by running each -- and "
            f"#R$87A0 stuns it for 24 frames (+6), and again on each frame the blast lasts. "
            f"#R$8800 does not move a stunned object, "
            f"so #R$8A00 finds the ant no closer each frame: it puts the animation frame "
            f"back to 0 and turns the ant left or right at random (#R$8360). A stunned ant "
            f"spins on the spot. It was stunned for {stunned} frames of the game in all here "
            f"(the count goes down only on the frames it moves), then came on again."))
    if key == "grenade":
        blast = [n for n in facts["blast"] if n]
        return ("A grenade thrown", (
            f"F, the eight-frame throw, on open ground. #R$8D00 puts the boy in the arms-out "
            f"pose for the frame of the throw (+8 = 2, at $8D22), starts the grenade in his "
            f"cell and sets its frame outright to $F4 ($8D32); it then moves like anything "
            f"else, a cell a frame. When the time runs out it stops and its explosion count "
            f"(+9) is set to 5, with {_script(memory, 5)}. #R$89D0 counts +9 down before "
            f"#R$82E0 picks the frame, $F4 + (count AND 3), so the counts drawn are "
            f"{', '.join(str(n) for n in blast)}: $F4 -- the flight frame again, for the "
            f"frame it bursts -- then $F7, $F6 and $F5. At 0 the grenade goes home, to "
            f"$00, $40, out of view."))
    if key in ("ant-blown-up", "ant-blown-up-fast"):
        drawn = ", ".join(f"${d:02X}" for d in facts["drawn"] if d is not None)
        if key == "ant-blown-up":
            return ("An ant blown up", (
                f"A slow ant (+$0D 2, as four of the five are on the first levels) walking "
                f"at the boy from {facts['start']} cells, and a grenade thrown with D bursting "
                f"within four cells of it: #R$87A0 sets its explosion count, and "
                f"{_script(memory, 3)}. #R$8A5D calls #R$82E0 for the blast frame -- but then "
                f"#R$8A00, which moves the ant, writes its animation frame again (0 or 1) "
                f"after it. So the blast is drawn only in the frames the ant skips, when "
                f"#R$8A00 is not called: every other frame for a slow ant, which flickers "
                f"between ant and blast; and the count goes down only when it moves, so it "
                f"lasts twice as long. What was drawn for the ant, frame by frame: {drawn}. "
                f"Then it is sent home, out of view."))
        return ("An ant blown up: the fast one", (
            f"The same for the fast ant, from {facts['start']} cells. It skips only one "
            f"frame in twenty, so #R$8A00 overwrites the blast frame every time: what was "
            f"drawn for it was {drawn} -- an ant, spinning on the spot, never the blast -- "
            f"and then it vanishes home. Read from the code and seen here; the grenade's own "
            f"blast is drawn beside it."))
    if key == "paralysing":
        return ("Landing on an ant", (
            f"The boy three blocks up over a stunned ant (as the build's own scene stages "
            f"it). He lands at height 1, on the ant's back: #R$8860 calls #R$8BD1, which "
            f"sets the ant's stun to $FF for good and runs {_script(memory, 16)}. From then "
            f"on #R$8A5D does nothing for it, so it stays in the frame it had, and he stands "
            f"on it."))
    if key == "view-turning":
        views = []
        for view in facts["views"]:
            if not views or views[-1] != view:
                views.append(view)
        return ("Turning the view", (
            f"The first frames of a game, at the city gate, with 0, P, ENTER and SPACE "
            f"pressed in turn for a frame each: #R$8400 sets the view to 3, 2, 1 and 0 and "
            f"moves its origin (#R$B420) so the boy is in the same place on the screen. "
            f"Views in the run: {', '.join(str(v) for v in views)}. The boy has not moved, "
            f"but his frame changes with the view, since #R$8600 adds the view to his "
            f"facing; the blocks are drawn by #R$8203 or #R$8703, one for each pair of "
            f"views (#R$8570). Nothing animates a turn: each view is drawn whole, the next "
            f"frame."))
    if key == "my-hero":
        return ("Found", (
            f"The girl waiting on open ground, stood up (BASIC starts her lying down, "
            f"stunned), and the boy walking up to her. #R$8F80 measures the distance every "
            f"frame; within three cells at the same height she is found -- her +$0D goes to "
            f"1 -- and {_script(memory, 12)} plays with its letters between the notes, "
            f"inside that one frame of the game (read here every fiftieth of a second). "
            f"Found on the {_ordinal(facts['found'] + 1)} step. The whole play area, since "
            f"that is where the words go."))
    if key == "following":
        return ("Following", (
            f"After that, V held with one frame of SYMBOL SHIFT to turn the corner. "
            f"#R$8AB6 sets the girl's move bit while she is two to five cells from the boy "
            f"and faces her along her way if one more step would leave her beside him, "
            f"otherwise towards him; #R$8980 animates her as it does him. She keeps one cell "
            f"behind all the way: the distance, frame by frame, was "
            f"{', '.join(str(d) for d in facts['distance'])}. The view scrolled "
            f"{facts['scrolled']} times to follow them (#R$8460); the picture stays fixed on "
            f"the ground."))
    if key == "walking-out":
        return ("Leading her out", (
            f"The boy just inside the gate, the girl following two cells behind, and V held. "
            f"Outside the walls a coordinate is below $80; once both are out, #R$8EA0 sets "
            f"her +$0D to 2 (BASIC's w), runs {_script(memory, 13)} -- its letters coloured "
            f"one by one and the play area filled with colour after colour by the script's "
            f"$7D codes -- and stores 1 in #R$B438, so PLAY returns to BASIC at the end of "
            f"that frame. {facts['frames']} frames of the game from the first step."))
    if key == "ending":
        return ("The ending", (
            f"After the tenth rescue BASIC's line 95 runs line 3600: GO SUB 2000 clears the "
            f"screen, POKE 46124,5 sets the border colour the sound routines use, and USR "
            f"36594 (#R$8EF2) runs {_script(memory, 17)}; then BASIC draws the medal with "
            f"CIRCLE, prints the score and waits, PAUSE 500, before line 2600's prompt and "
            f"the wait for a key. This is BASIC running with interrupts on, read off the "
            f"screen every fiftieth of a second, border and all: "
            f"{facts['seconds']:.1f}s from line 3600 to the key wait, and three seconds more "
            f"to show the flashing. To get there, a first rescue is made by putting both "
            f"people outside the walls, and as PLAY returns BASIC's sg is set to 8, so that "
            f"line 90 counts it to 9 and BASIC sets up the tenth level itself; the second "
            f"rescue is then the tenth. (Staged the quicker way, with fin set to 1 on the "
            f"first level, the ending runs out of memory in line 3610's CIRCLE -- the first "
            f"level's long story card is still in c$ -- and #R$9797 restarts the game.)"))
    raise KeyError(key)


def _make_all(snapshot: Path, log) -> list[list[dict]]:
    """Every animation, in page order, grouped where several GIFs share one
    heading."""
    groups = []
    for sex in ("b", "g"):
        log(f"  {'boy' if sex == 'b' else 'girl'} walking")
        groups.append([walking(snapshot, sex, facing) for facing in range(4)])
    for make in (jumping, climbing, falling):
        log(f"  {make.__name__}")
        groups.append([make(snapshot)])
    log("  ants")
    groups.append([ant_walking(snapshot, facing) for facing in range(4)])
    for make in (ant_biting, grenade, ant_stunned, ant_blown_up):
        log(f"  {make.__name__}")
        groups.append([make(snapshot)])
    groups.append([ant_blown_up(snapshot, ANT)])
    for make in (paralysing, view_turning):
        log(f"  {make.__name__}")
        groups.append([make(snapshot)])
    log("  rescue")
    hero, follow = rescue(snapshot)
    groups += [[hero], [follow]]
    log("  walking_out")
    groups.append([walking_out(snapshot)])
    log("  ending")
    groups.append([ending(snapshot)])
    return groups


FACING_CAPTIONS = ["facing 0, y up", "facing 1, x up", "facing 2, y down", "facing 3, x down"]
SPRITE_FRAMES = set(range(0x68, 0x80)) | set(range(0xDC, 0x100))   # the two sprite blocks


def build(snapshot: Path, html_dir: Path, log=print) -> dict[str, str]:
    """Write the GIFs into html_dir/images/animations and return the
    Animations section."""
    out_dir = html_dir / IMAGE_DIR
    out_dir.mkdir(parents=True, exist_ok=True)
    log("Running the animations in the game's own code...")
    memory = ba.game_memory(snapshot)
    starts = _entry_starts(str(Path(snapshot).with_name("antattack.skool")))
    groups = _make_all(Path(snapshot), log)
    drawn = set()
    for group in groups:
        for animation in group:
            drawn.update(animation["sprites"])
    if drawn & set(range(0xF0, 0xF4)):
        raise RuntimeError("a frame in $F0-$F3 was drawn after all: the page says not")
    never = sorted(SPRITE_FRAMES - drawn)
    lines = [
        '<div class="aa-animations">',
        "<p>An object's picture in Ant Attack is one number, worked out afresh every frame by "
        "#R$8600: the first frame in its record (+3: the boy $DC, the girl $6C, an ant $F8), "
        "plus four times its animation frame (+8), plus its facing turned by the view -- or, "
        "when +8 has bit 7 set, +8 itself, outright. Frame f is the 64 bytes at $8000 + 64f "
        "(#R$80A0). So an animation is whatever writes +8: #R$8980 for the two people, whose "
        "five poses -- standing, walking, arms out, lying, arms up -- are the animation frames "
        "0 to 4; #R$8A00 for an ant, which has only 0 and 1; #R$8D00 for the grenade in "
        "flight ($F4 outright, and the thrower's arms-out pose); and #R$82E0 and #R$8980 for "
        "anything exploding ($F4 to $F7 outright).</p>",
        "<p>Every animation below was made by running the game's own code in SkoolKit's "
        "simulator when these pages were built: a game started the way the build starts one, "
        "from the title screen, with the pieces put where the scene needs them at the end of a "
        "frame -- the player on open ground, an ant a few cells off, the ants not wanted parked "
        "outside the walls and paralysed -- and then one real frame of the game after "
        "another, each picture read off the screen. Only the starting positions are staged; "
        "the moving, the frame choices, the projection, the painting and the copy are the "
        "game's. Each picture lasts as long as the game took over it: the T-states from the "
        "copy to the screen that put it there to the next copy, at 3.5MHz and without the "
        "memory contention of a real Spectrum, which would be a little slower. A game frame "
        "takes about 140ms, some 500,000 T-states. Where a script plays -- a tune with its "
        "letters between the notes, all inside one frame of the game -- the screen is read "
        "every fiftieth of a second instead, and FLASH is drawn in the phase the ULA would be "
        "in. Identical pictures in a row are one. Each GIF is cropped to the 16 by 16 boxes "
        "the game drew its sprites in (from their places in #R$B500, through #R$8130), or "
        "shows the whole play area where words appear in it; under each, the sprite frames in "
        "each picture and how long it lasts.</p>",
        f"<p>Frames $F0-$F3 are never drawn. Nothing can produce them: +3 is only ever $DC, "
        f"$6C, $68 or $F8 (BASIC's POKEs and DATA), the writers of +8 above give 0-4, $F4-$F7 "
        f"or $F4, and no first frame plus 4 x (0 to 4) plus a facing lands in $F0-$F3 (the "
        f"boy's would need animation frame 5, an ant's -2). That is read from the code; and "
        f"the runs on this page, which between them draw {len(drawn & SPRITE_FRAMES)} of the "
        f"{len(SPRITE_FRAMES)} frames in the two sprite blocks, never draw one of the four. "
        f"Of the others they do not draw, the grenade's own frames $68-$6B would be shown "
        f"only at its home, $00, $40, far out of view; the rest ("
        f"{', '.join(f'${f:02X}' for f in never if not 0xF0 <= f <= 0xF3 and not 0x68 <= f <= 0x6B)}) "
        f"are poses and facings of the two people that these scenes happen not to show.</p>",
    ]
    for group in groups:
        first = group[0]
        title, words = _words(first["key"], first, memory)
        lines += [f'<div class="aa-animation" id="{first["key"]}">', f"<h3>{_esc(title)}</h3>"]
        pictures = []
        for index, animation in enumerate(group):
            frames = animation["frames"]
            save_gif(out_dir / f"{animation['key']}.gif", frames)
            width, height = frames[0][0].size
            scale = animation["scale"]
            caption = FACING_CAPTIONS[index] if len(group) == 4 else ""
            alt = f"{title}, {caption}" if caption else title
            image = (f'<img class="aa-picture" src="{IMAGE_DIR}/{animation["key"]}.gif" '
                     f'alt="{_esc(alt)}" width="{width * scale}" height="{height * scale}">')
            if caption:
                image = (f'<span style="display:inline-block;margin:0 12px 8px 0;'
                         f'vertical-align:top;text-align:center">{image}<br>{caption}</span>')
            pictures.append(image)
        lines.append("<p>" + "".join(pictures) + "</p>")
        lines.append(f"<p>{words}</p>")
        sprites = sorted({f for animation in group for f in animation["sprites"]})
        if sprites:
            lines.append("<p>Sprite frames drawn: "
                         + ", ".join(_frame_link(f) for f in sprites) + ".</p>")
        for index, animation in enumerate(group):
            prefix = f"{FACING_CAPTIONS[index].capitalize()}: i" if len(group) == 4 else "I"
            if animation["key"] == "ending":
                seconds = sum(ms for _, ms, _ in animation["frames"]) / 1000
                lines.append(f"<p>In the picture: {len(animation['frames'])} pictures, "
                             f"{seconds:.1f}s in all.</p>")
            else:
                lines.append(f"<p>{prefix}n the picture: {_order(animation['frames'])}.</p>")
        lines.append("</div>")
    lines.append("</div>")
    body = _links("\n".join(lines), starts)
    for line in body.splitlines():
        if line.startswith((";", "[")):
            raise RuntimeError(f"a section line may not start with that: {line[:40]}")
    return {"Animations": body}
