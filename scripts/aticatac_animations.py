"""Atic Atac's animations, as GIFs of the game running its own code.

build_aticatac.py's HTML build calls build(), which writes the GIFs into the
HTML directory and returns the Animations section. Nothing here is committed
output: the frames are the game's, drawn when the pages are built.

Atic Atac draws straight onto the screen. There is no buffer and no copy:
each thing is XORed off at its old place and on at its new one, a row of each
at a time (REDRAW_MOVED, $9FCA), and its colour cells are painted as it goes.
The game runs at two speeds (MAIN_LOOP, $7DC3): the player, the weapon and
the sound slot move once a 50Hz frame, in FRAME_TICK ($7EB2), which the loop
calls between records whenever FRAMES has moved; everything else moves once a
pass of the loop, which in a quiet room takes about 1.7 frames.

So the screen is read at the top of FRAME_TICK, every frame: at that moment
no record is half drawn -- the loop calls it between records, never inside
one -- and the player stands where the last frame put him. Each picture
lasts until the next reading, in T-states counted by SkoolKit's simulator at
3.5MHz with no memory contention (a real Spectrum is a little slower), and
identical pictures in a row are one frame of the GIF. Where the game leaves
its loop -- the fall through a trapdoor, the ends of the game -- the screen is
read every fiftieth of a second instead. FLASH is drawn in the phase the ULA
would be in at that T-state.

Every scene is a game started the way build_aticatac.render_rooms starts one,
from the title screen with the character's key, run until the character has
materialised in room $00; then whatever the scene needs is staged at a frame
boundary -- a room (through ARRIVE_IN_ROOM, as the room pictures are drawn), a
creature, an object, a food level -- and the game plays on, its own code
doing everything after. Scenes that are not about the creatures keep them
from arriving by holding the spawner's countdown up at every frame.
"""
from __future__ import annotations

import functools
import html
import re
from pathlib import Path

import build_aticatac as ba

IMAGE_DIR = "images/animations"

# --------------------------------------------------------------------------
# Addresses. See their entries in the listing.
# --------------------------------------------------------------------------

FRAME_TICK = 0x7EB2
MAIN_LOOP = 0x7DC3
ARRIVE_IN_ROOM = 0x9147
TITLE_AGAIN = 0x7C29
GAME_OVER = 0x8C35
SHOW_END_SCREEN = 0x96EC
TRAPDOOR_FALL_START = 0x973A    # TRAPDOOR_FALL past its "is he on it" test
FRAMES = 0x5C78
TICKS = 0x5E12
LIVES = 0x5E21
SPAWN_COUNTDOWN = 0x5E27
FOOD_LEVEL = 0x5E28
SCORE = 0x5E2A
CARRIED = 0x5E30
FLASH_COUNT = 0x5E3C
PLAYER = 0xEA90
WEAPON = 0xEA98
ROOM = PLAYER + 1
MONSTER_SLOTS = [0xEE60, 0xEE70, 0xEE80]
BIG_SLOTS = [0xEE90, 0xEEA0, 0xEEB0, 0xEEC0, 0xEED0]
OBJECTS = (0xEAA8, 0xEE58)      # the eight-byte records dispatched by room
DOORS = (0xEEE0, 0xEEE0 + 274 * 16)
SPRITE_TABLE = 0xA4BE
SPAWN_TYPES = 0x8B7A
TEMPLATE_OFFSET = 0xEA90 - 0x600D   # runtime record less its place in INITIAL_STATE

ULA_FRAME = 69888           # T-states from one interrupt to the next
FLASH_FRAMES = 16           # the ULA swaps FLASH ink and paper every 16 frames
T_STATES_PER_MS = 3500
SECOND = ba.TSTATES_PER_SECOND
FRAME_LIMIT = 4 * SECOND    # a bound on the run to any one frame's stop
PLAY_AREA = (0, 0, 192, 192)    # the 24 x 24 cells a room is drawn in
IN_PLAY = range(0x01, 0x31)     # the player's sprite while he is himself

SPECTRUM = [(0, 0, 0), (0, 0, 205), (205, 0, 0), (205, 0, 205),
            (0, 205, 0), (0, 205, 205), (205, 205, 0), (205, 205, 205)]
SPECTRUM_BRIGHT = [(0, 0, 0), (0, 0, 255), (255, 0, 0), (255, 0, 255),
                   (0, 255, 0), (0, 255, 255), (255, 255, 0), (255, 255, 255)]
PALETTE = SPECTRUM + SPECTRUM_BRIGHT

# The characters: the menu key, the first sprite code, the weapon's codes.
CHARACTERS = {
    "knight": {"key": "4", "base": 0x01, "weapon": range(0x40, 0x48)},
    "wizard": {"key": "5", "base": 0x11, "weapon": range(0x34, 0x38)},
    "serf": {"key": "6", "base": 0x21, "weapon": range(0x38, 0x40)},
}


def _esc(text: str) -> str:
    return html.escape(text, quote=False)


def _word(memory, address: int) -> int:
    return memory[address] + 256 * memory[address + 1]


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
    """A simulator on `memory`; with `registers` (all of them, the interrupt
    state included) carried over from another."""
    from skoolkit import CSimulator
    from skoolkit.simulator import Simulator

    simulator = (CSimulator or Simulator)(list(memory), state={"iff": 0, "im": 1, "tstates": 0})
    if registers is not None:
        for index, value in enumerate(registers):
            simulator.registers[index] = value
    tracer = _Tracer()
    simulator.set_tracer(tracer)
    return simulator, tracer


def _run(simulator, stop: int, limit: int) -> bool:
    """Run with interrupts to `stop` or to the T-state `limit`, whichever is
    first; True if it stopped at `stop`. The simulator runs at least one
    instruction before it looks at the stop, so a run from a stop to the same
    address goes round once."""
    from skoolkit.simutils import PC, T

    if hasattr(simulator, "trace"):
        condition, _ = simulator.trace(simulator.registers[PC], stop, 0, limit, True,
                                       None, None, None, None, None)
        return condition == 3
    while simulator.registers[T] < limit:           # the pure-Python simulator
        simulator.run(simulator.registers[PC])
        if simulator.registers[PC] == stop:
            return True
    return False


@functools.lru_cache(maxsize=None)
def _started(snapshot: str, character: str) -> tuple:
    """A game started from the title screen with the character chosen, the
    way the build's room pictures start one, stopped at the first FRAME_TICK:
    its memory and registers."""
    from skoolkit.simutils import PC, T

    memory = ba.machine_memory(Path(snapshot))
    simulator, tracer = _simulator(memory)
    simulator.registers[PC] = ba.ENTRY
    for keys, seconds in [([], 3.0), (["1"], 0.3), ([], 0.5),
                          ([CHARACTERS[character]["key"]], 0.3), ([], 0.5), (["0"], 0.3)]:
        tracer.keys = set(keys)
        _run(simulator, 0, simulator.registers[T] + int(seconds * SECOND))
    tracer.keys = set()
    if not _run(simulator, FRAME_TICK, simulator.registers[T] + 10 * SECOND):
        raise RuntimeError("the game did not start")
    return bytes(simulator.memory), tuple(simulator.registers)


@functools.lru_cache(maxsize=None)
def _in_play(snapshot: str, character: str) -> tuple:
    """The same game run on, a frame at a time, until the character has
    materialised and is in play in room $00; the spawner held off meanwhile.
    Its memory and registers at that FRAME_TICK."""
    scene = Scene(Path(snapshot), character, from_start=True)
    scene.no_creatures = True
    for _ in range(400):
        scene.frame()
        if scene.peek(PLAYER) in IN_PLAY:
            scene.frame()
            return bytes(scene.sim.memory), tuple(scene.sim.registers)
    raise RuntimeError("the character did not materialise")


class Capture:
    """The screen at a T-state, with the sprite codes of the records the
    scene watches, and the life force."""

    def __init__(self, t: int, screen: bytes, sprites: tuple, food: int):
        self.t, self.screen, self.sprites, self.food = t, screen, sprites, food


class Scene:
    """A game in progress, stopped at the top of FRAME_TICK, run a frame at a
    time; the screen read at each stop."""

    def __init__(self, snapshot: Path, character: str = "knight", from_start: bool = False):
        if from_start:
            memory, registers = _started(str(snapshot), character)
        else:
            memory, registers = _in_play(str(snapshot), character)
        self.snapshot = snapshot
        self.character = character
        self.sim, self.tracer = _simulator(memory, registers)
        self.captures: list[Capture] = []
        self.watch: list[int] = [PLAYER, WEAPON]
        self.no_creatures = False

    # The machine.
    def peek(self, address: int) -> int:
        return self.sim.memory[address]

    def poke(self, address: int, *values: int) -> None:
        for offset, value in enumerate(values):
            self.sim.memory[address + offset] = value & 0xFF

    def t(self) -> int:
        from skoolkit.simutils import T
        return self.sim.registers[T]

    def pc(self) -> int:
        from skoolkit.simutils import PC
        return self.sim.registers[PC]

    def screen(self) -> bytes:
        return bytes(self.sim.memory[0x4000:0x5B00])

    def room(self) -> int:
        return self.peek(ROOM)

    def _sprites(self) -> tuple:
        out = []
        room = self.room()
        for address in self.watch:
            code = self.peek(address)
            here = address in (PLAYER, WEAPON) or self.peek(address + 1) == room
            out.append(code if code and here else 0)
        return tuple(out)

    def capture(self) -> None:
        self.captures.append(Capture(self.t(), self.screen(), self._sprites(),
                                     self.peek(FOOD_LEVEL)))

    def _hold_off(self) -> None:
        """Keep the spawner's countdown up, so nothing arrives."""
        if self.no_creatures:
            self.poke(SPAWN_COUNTDOWN, 0x20)

    def frame(self, keys=(), capture: bool = True) -> None:
        """On to the next FRAME_TICK with `keys` held, and read the screen."""
        self.tracer.keys = set(keys)
        if not _run(self.sim, FRAME_TICK, self.t() + FRAME_LIMIT):
            raise RuntimeError(f"no FRAME_TICK within {FRAME_LIMIT} T-states "
                               f"(PC ${self.pc():04X})")
        self._hold_off()
        if capture:
            self.capture()

    def run(self, count: int, keys=(), capture: bool = True) -> None:
        for _ in range(count):
            self.frame(keys, capture)

    def until(self, test, limit: int, keys=(), capture: bool = True) -> int:
        """Frames until `test(scene)` holds, at most `limit`; how many."""
        for count in range(1, limit + 1):
            self.frame(keys, capture)
            if test(self):
                return count
        raise RuntimeError(f"not within {limit} frames")

    def by_time(self, stop: int | None, seconds: float, keys=()) -> bool:
        """Read the screen every ULA frame for up to `seconds`, or until PC
        reaches `stop`; True if it did."""
        self.tracer.keys = set(keys)
        end = self.t() + int(seconds * SECOND)
        while self.t() < end:
            slice_end = min(end, (self.t() // ULA_FRAME + 1) * ULA_FRAME)
            stopped = _run(self.sim, stop if stop is not None else 0, slice_end)
            self.capture()
            if stopped:
                return True
        return False

    def go_to_room(self, room: int, x: int, y: int) -> None:
        """Into `room` at (x, y) the way the room pictures are drawn: the room
        and position written into the player's record at a FRAME_TICK stop,
        and on through ARRIVE_IN_ROOM, which draws it and goes back into
        MAIN_LOOP. (No arrival walk: ENTER_ROOM is skipped.)"""
        from skoolkit.simutils import PC
        self.poke(ROOM, room)
        self.poke(PLAYER + 3, x, y)
        self.poke(PLAYER + 6, 0, 0)
        self.sim.registers[PC] = ARRIVE_IN_ROOM
        self.frame(capture=False)
        self.frame(capture=False)

    def clear_creatures(self) -> None:
        for slot in MONSTER_SLOTS:
            self.poke(slot, *([0] * 16))


# --------------------------------------------------------------------------
# Pictures.
# --------------------------------------------------------------------------

def _row_address(y: int) -> int:
    return ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2)


def _flash_phase(t: int) -> int:
    return (t // ULA_FRAME // FLASH_FRAMES) & 1


def _uses_flash(screen: bytes, box) -> bool:
    left, top, right, bottom = box
    for row in range(top // 8, (bottom + 7) // 8):
        for column in range(left // 8, (right + 7) // 8):
            if screen[0x1800 + 32 * row + column] & 0x80:
                return True
    return False


def picture(screen: bytes, t: int, box):
    """The part of the screen in `box` (left, top, right, bottom, in pixels)
    as a PIL image, FLASH in the phase the ULA has at T-state `t`."""
    from PIL import Image

    left, top, right, bottom = box
    flash = _flash_phase(t)
    image = Image.new("RGB", (right - left, bottom - top))
    pixels = image.load()
    for y in range(top, bottom):
        row = _row_address(y)
        for x in range(left, right):
            byte = screen[row + (x >> 3)]
            attr = screen[0x1800 + (y >> 3) * 32 + (x >> 3)]
            palette = SPECTRUM_BRIGHT if attr & 0x40 else SPECTRUM
            ink, paper = palette[attr & 7], palette[(attr >> 3) & 7]
            if attr & 0x80 and flash:
                ink, paper = paper, ink
            pixels[x - left, y - top] = ink if byte & (0x80 >> (x & 7)) else paper
    return image


def _region_key(screen: bytes, t: int, box) -> bytes:
    """What decides how `box` looks: its pixel bytes, its attributes, and the
    FLASH phase if any of its cells flash."""
    left, top, right, bottom = box
    parts = []
    for y in range(top, bottom):
        row = _row_address(y)
        parts.append(screen[row + (left >> 3):row + ((right + 7) >> 3)])
    for row in range(top // 8, (bottom + 7) // 8):
        parts.append(screen[0x1800 + 32 * row + (left >> 3):0x1800 + 32 * row + ((right + 7) >> 3)])
    if _uses_flash(screen, box):
        parts.append(bytes([_flash_phase(t)]))
    return b"".join(parts)


def changed_box(captures: list[Capture], area, margin: int = 8):
    """The box round every pixel and colour cell in `area` that changes
    between the captures, widened by `margin`, squared to character cells and
    kept inside `area`; None if nothing changed."""
    left, top, right, bottom = area
    first = captures[0].screen
    xs, ys = [], []
    for capture in captures[1:]:
        screen = capture.screen
        if screen == first:
            continue
        for y in range(top, bottom):
            row = _row_address(y)
            for column in range(left >> 3, right >> 3):
                if screen[row + column] != first[row + column]:
                    xs.append(column * 8)
                    ys.append(y)
        for row in range(top >> 3, bottom >> 3):
            for column in range(left >> 3, right >> 3):
                at = 0x1800 + 32 * row + column
                if screen[at] != first[at]:
                    xs.append(column * 8)
                    ys.append(row * 8)
                    ys.append(row * 8 + 7)
    if not xs:
        return None
    box = [min(xs) - margin, min(ys) - margin, max(xs) + 8 + margin, max(ys) + 1 + margin]
    box[0] = max(left, box[0] // 8 * 8)
    box[1] = max(top, box[1] // 8 * 8)
    box[2] = min(right, (box[2] + 7) // 8 * 8)
    box[3] = min(bottom, (box[3] + 7) // 8 * 8)
    return tuple(box)


def around(x: int, y: int, width: int = 48, height: int = 48):
    """An area of the room round a thing standing at (x, y) -- sprites are
    drawn upwards from the point they stand on -- for changed_box to look in,
    so that a door opening elsewhere in the room does not widen the crop."""
    return (max(0, (x - width // 2) // 8 * 8), max(0, (y - height + 8) // 8 * 8),
            min(192, (x + width // 2 + 7) // 8 * 8), min(192, (y + 16) // 8 * 8))


GAP = 4                     # between the room and the scroll in a two-part picture
GAP_COLOUR = (40, 40, 60)


def frames_of(captures: list[Capture], boxes: list, end: int | None = None,
              label=None) -> list[list]:
    """A picture for each capture, of `boxes` side by side, lasting until the
    next capture (the last until `end`, or one ULA frame); consecutive
    identical pictures as one, for their total time. Each is [image,
    T-states, label]."""
    from PIL import Image

    out = []
    last_key = None
    for index, capture in enumerate(captures):
        if index + 1 < len(captures):
            tstates = captures[index + 1].t - capture.t
        else:
            tstates = (end - capture.t) if end is not None else ULA_FRAME
        key = b"|".join(_region_key(capture.screen, capture.t, box) for box in boxes)
        text = label(capture) if label is not None else ""
        if out and key == last_key:
            out[-1][1] += tstates
            if text and text not in out[-1][2].split(" / "):
                out[-1][2] += " / " + text
            continue
        parts = [picture(capture.screen, capture.t, box) for box in boxes]
        width = sum(p.size[0] for p in parts) + GAP * (len(parts) - 1)
        height = max(p.size[1] for p in parts)
        image = Image.new("RGB", (width, height), GAP_COLOUR)
        x = 0
        for part in parts:
            image.paste(part, (x, 0))
            x += part.size[0] + GAP
        out.append([image, tstates, text])
        last_key = key
    return out


def _ms(tstates: int) -> float:
    return tstates / T_STATES_PER_MS


def gif_times(frames: list[list]) -> list[int]:
    """T-states to milliseconds, to the 10ms a GIF can say, 20ms at least."""
    return [max(20, round(_ms(t) / 10) * 10) for _, t, _ in frames]


def save_gif(path: Path, frames: list[list]) -> None:
    from PIL import Image

    palette = Image.new("P", (1, 1))
    flat = [c for colour in PALETTE + [GAP_COLOUR] for c in colour]
    palette.putpalette(flat + [0] * (768 - len(flat)))
    images = [image.quantize(palette=palette, dither=Image.Dither.NONE)
              for image, _, _ in frames]
    images[0].save(path, save_all=True, append_images=images[1:], loop=0,
                   duration=gif_times(frames), disposal=1, optimize=False)


# --------------------------------------------------------------------------
# Staging.
# --------------------------------------------------------------------------

ROOM_CENTRE = (0x58, 0x68)      # the walk rectangle's middle, in every room
START_ROOM = 0x00

# The controls (keyboard): Q left, W right, E down, R up, T fire; SYMBOL
# SHIFT picks up and drops. Directions as (keys, dx, dy).
DIRECTIONS = [("left", ["q"], -1, 0), ("right", ["w"], 1, 0),
              ("up", ["r"], 0, -1), ("down", ["e"], 0, 1)]
FIRE = "t"
PICK_UP_KEY = "SS"


def quiet_scene(snapshot: Path, character: str = "knight", room: int = START_ROOM,
                at=ROOM_CENTRE) -> Scene:
    """The character in play, alone in `room` at `at`: no creatures, and the
    spawner held off."""
    scene = Scene(snapshot, character)
    scene.no_creatures = True
    scene.clear_creatures()
    scene.go_to_room(room, *at)
    scene.run(3, capture=False)
    return scene


def _label_codes(indices):
    def label(capture: Capture) -> str:
        codes = [capture.sprites[i] for i in indices if capture.sprites[i]]
        return "+".join(f"${c:02X}" for c in codes) or "-"
    return label


def _animation(key: str, frames: list[list], facts: dict | None = None,
               sprites=(), scale: int = 3) -> dict:
    return {"key": key, "frames": frames, "facts": facts or {}, "sprites": sorted(set(sprites)),
            "scale": scale}


def _seen(captures: list[Capture], indices) -> list[int]:
    seen = []
    for capture in captures:
        for index in indices:
            code = capture.sprites[index]
            if code and code not in seen:
                seen.append(code)
    return seen


# --------------------------------------------------------------------------
# The animations.
# --------------------------------------------------------------------------

WALK_FRAMES = 24


def walking(snapshot: Path, character: str, direction: int) -> dict:
    """The character alone in room $00, walking WALK_FRAMES frames one way
    across the middle."""
    name, keys, dx, dy = DIRECTIONS[direction]
    start = (ROOM_CENTRE[0] - dx * WALK_FRAMES, ROOM_CENTRE[1] - dy * WALK_FRAMES)
    scene = quiet_scene(snapshot, character, at=start)
    scene.frame()
    scene.run(WALK_FRAMES, keys)
    captures = scene.captures
    box = changed_box(captures, PLAY_AREA)
    frames = frames_of(captures, [box], label=_label_codes([0]))
    return _animation(f"{character}-walking-{name}", frames,
                      facts={"x": [scene.peek(PLAYER + 3)]},
                      sprites=_seen(captures, [0]))


COAST_HOLD = 12


def coasting(snapshot: Path, character: str) -> dict:
    """W held for COAST_HOLD frames, then let go: how far the character runs
    on. The heading at +$06 decays by the character's amount a frame
    (DECAY_HEADING), and a heading of 16-31 is still a pixel a frame."""
    scene = quiet_scene(snapshot, character, at=(ROOM_CENTRE[0] - 24, ROOM_CENTRE[1]))
    scene.frame()
    scene.run(COAST_HOLD, ["w"])
    released = scene.peek(PLAYER + 3)
    xs = []
    for _ in range(30):
        scene.frame()
        xs.append(scene.peek(PLAYER + 3))
    captures = scene.captures
    box = changed_box(captures, PLAY_AREA)
    frames = frames_of(captures, [box], label=_label_codes([0]))
    moving = sum(1 for a, b in zip([released] + xs, xs) if b != a)
    return _animation(f"{character}-coasting", frames,
                      facts={"coast": xs[-1] - released, "frames": moving},
                      sprites=_seen(captures, [0]))


def weapon(snapshot: Path, character: str) -> dict:
    """In room $00, W, R and T together for one frame -- right, up and fire --
    then nothing: the weapon flies off diagonally, bounces round the room
    until its 48 frames are up, and is gone."""
    scene = quiet_scene(snapshot, character)
    scene.frame()
    scene.frame(["w", "r", FIRE])
    flights = 0
    t_first = t_last = None
    velocity = (scene.peek(WEAPON + 6), scene.peek(WEAPON + 7))
    bounces = 0
    for _ in range(80):
        scene.frame()
        if scene.peek(WEAPON):
            flights += 1
            t_last = scene.t()
            t_first = t_first or scene.t()
            now = (scene.peek(WEAPON + 6), scene.peek(WEAPON + 7))
            bounces += (now[0] != velocity[0]) + (now[1] != velocity[1])
            velocity = now
        elif flights:
            break
    scene.run(3)
    captures = scene.captures
    frames = frames_of(captures, [PLAY_AREA], label=_label_codes([1]))
    return _animation(f"{character}-weapon", frames, scale=2,
                      facts={"frames": flights, "bounces": bounces,
                             "seconds": (t_last - t_first) / SECOND},
                      sprites=_seen(captures, [1]))


# The scroll, in screen pixels: the parts of it a scene may want beside the
# room (checked by eye against the scroll as the game draws it).
PANEL_INVENTORY = (192, 24, 256, 48)    # DRAW_INVENTORY's three slots
PANEL_SCORE_ROAST = (192, 72, 256, 128)  # SCORE, its digits, and the roast
PANEL_LIFE = (192, 72, 256, 152)        # the same and the spare lives

CORNER = (ROOM_CENTRE[0] - 40, ROOM_CENTRE[1] + 40)     # out of the way


def _spawn_index(memory, kind: int) -> int:
    table = list(memory[SPAWN_TYPES:SPAWN_TYPES + 16])
    return table.index(kind)


def spawn(scene: Scene, kind: int) -> None:
    """Make the spawner fire on this frame, into the first free slot, with a
    creature of `kind`: its countdown set to 1 and FRAMES to a value whose
    low nibble indexes SPAWN_TYPES at that kind. Everything else -- the
    template, the random place and speed, the arrival -- is the spawner's.
    Then nothing more arrives."""
    scene.no_creatures = False
    scene.poke(SPAWN_COUNTDOWN, 1)
    scene.poke(FRAMES, 16 + _spawn_index(scene.sim.memory, kind))
    scene.frame(capture=False)
    scene.no_creatures = True
    scene._hold_off()
    if scene.peek(MONSTER_SLOTS[0]) not in range(0x58, 0x5C):
        raise RuntimeError(f"no creature arrived for ${kind:02X}")


def _burst(code: int) -> bool:
    return 0x6C <= code <= 0x6F


CREATURE_FRAMES = 220


def creature(snapshot: Path, kind: int) -> dict:
    """A creature of `kind` made to arrive in room $00, with the knight
    standing in a corner, and CREATURE_FRAMES frames (about four seconds) of
    it moving about -- less if it finds him and bursts."""
    scene = quiet_scene(snapshot, at=CORNER)
    scene.watch.append(MONSTER_SLOTS[0])
    scene.frame()
    spawn(scene, kind)
    scene.capture()
    caught = False
    for _ in range(CREATURE_FRAMES):
        scene.frame()
        code = scene.peek(MONSTER_SLOTS[0])
        if _burst(code):
            caught = True
        if caught and code == 0:
            scene.run(3)
            break
    captures = scene.captures
    frames = frames_of(captures, [PLAY_AREA], label=_label_codes([2]))
    return _animation(f"creature-{kind:02X}", frames, scale=2,
                      facts={"caught": caught,
                             "arrival": _arrival_passes(captures)},
                      sprites=_seen(captures, [2]))


def _arrival_passes(captures: list[Capture]) -> float:
    """How long the arrival frames were on the screen, in seconds."""
    times = [c.t for c in captures if 0x58 <= c.sprites[2] <= 0x5B]
    if len(times) < 2:
        return 0.0
    return (times[-1] - times[0]) / SECOND


def _arrived(scene: Scene, kind: int, limit: int = 120) -> None:
    scene.until(lambda s: s.peek(MONSTER_SLOTS[0]) == kind, limit, capture=False)


def shot(snapshot: Path, kind: int = 0x4C) -> dict:
    """A creature that has arrived, and the knight put level with it, a few
    cells to its left, firing right: the axe flies, hits, and the creature
    bursts for 155 points."""
    for distance in (40, 32, 48, 24, 56):
        scene = quiet_scene(snapshot, at=CORNER)
        scene.frame(capture=False)
        spawn(scene, kind)
        _arrived(scene, kind)
        x, y = scene.peek(MONSTER_SLOTS[0] + 3), scene.peek(MONSTER_SLOTS[0] + 4)
        if x - distance < ROOM_CENTRE[0] - 48:
            continue
        scene.go_to_room(START_ROOM, x - distance, y)
        scene.watch.append(MONSTER_SLOTS[0])
        scene.captures = []
        scene.frame()
        score = bytes(scene.sim.memory[SCORE:SCORE + 3])
        scene.frame(["w", FIRE])
        hit = False
        for _ in range(60):
            scene.frame()
            code = scene.peek(MONSTER_SLOTS[0])
            hit = hit or _burst(code)
            if hit and code == 0:
                break
        scene.run(10)
        # A burst from the axe, not from the creature reaching the knight
        # first, which would have cost him 32.
        if not hit or any(step <= -32 for step in _food_steps(scene.captures)):
            continue
        captures = scene.captures
        box = changed_box(captures, PLAY_AREA, margin=12)
        frames = frames_of(captures, [box, PANEL_SCORE_ROAST], label=_label_codes([1, 2]))
        return _animation("shot", frames,
                          facts={"distance": distance, "kind": kind,
                                 "score": (score, bytes(scene.sim.memory[SCORE:SCORE + 3]))},
                          sprites=_seen(captures, [1, 2]))
    raise RuntimeError("the axe never hit")


def caught(snapshot: Path, kind: int = 0x4C) -> dict:
    """A creature that has arrived, and the knight put a little to its left,
    walking into it: 32 off the life force, and the creature bursts for 155
    points all the same."""
    scene = quiet_scene(snapshot, at=CORNER)
    scene.frame(capture=False)
    spawn(scene, kind)
    _arrived(scene, kind)
    x, y = scene.peek(MONSTER_SLOTS[0] + 3), scene.peek(MONSTER_SLOTS[0] + 4)
    scene.go_to_room(START_ROOM, max(ROOM_CENTRE[0] - 48, x - 28), y)
    scene.watch.append(MONSTER_SLOTS[0])
    scene.captures = []
    scene.frame()
    before = (scene.peek(FOOD_LEVEL), bytes(scene.sim.memory[SCORE:SCORE + 3]))
    touched = False
    for _ in range(80):
        code = scene.peek(MONSTER_SLOTS[0])
        touched = touched or _burst(code)
        scene.frame([] if touched else ["w"])
        if touched and scene.peek(MONSTER_SLOTS[0]) == 0:
            break
    scene.run(10)
    if not touched:
        raise RuntimeError("the creature was never touched")
    captures = scene.captures
    box = changed_box(captures, PLAY_AREA, margin=12)
    frames = frames_of(captures, [box, PANEL_SCORE_ROAST], label=_label_codes([0, 2]))
    after = (scene.peek(FOOD_LEVEL), bytes(scene.sim.memory[SCORE:SCORE + 3]))
    return _animation("caught", frames, facts={"before": before, "after": after, "kind": kind,
                                               "steps": _food_steps(captures)},
                      sprites=_seen(captures, [2]))


def _food_steps(captures: list[Capture]) -> list[int]:
    """Each change of the life force from one capture to the next."""
    return [b.food - a.food for a, b in zip(captures, captures[1:]) if b.food != a.food]


# The big five, told apart by their sprites.
BIG_FIVE = [("mummy", range(0x70, 0x74)), ("frankenstein", range(0x74, 0x78)),
            ("devil", range(0x78, 0x7C)), ("dracula", range(0x7C, 0x80)),
            ("humpback", range(0x9C, 0xA0))]
BIG_FRAMES = 320


def _big_slot(memory, name: str) -> int:
    codes = dict(BIG_FIVE)[name]
    for slot in BIG_SLOTS:
        if memory[slot] in codes:
            return slot
    raise RuntimeError(f"no {name} in the monster slots")


def _collectable(memory, codes) -> int:
    """The record of the first of `codes` still lying somewhere."""
    for address in range(OBJECTS[0], OBJECTS[1], 8):
        if memory[address] in codes and memory[address + 1] != 0:
            return address
    raise RuntimeError("no such object lying anywhere")


def _carry(scene: Scene, records: list[int]) -> None:
    """The inventory set to these objects, newest first -- each slot the
    record's address, sprite and colour, as REMEMBER_CARRIED writes it -- and
    each record emptied, as picking it up empties it."""
    for slot in range(3):
        at = CARRIED + 4 * slot
        if slot < len(records):
            record = records[slot]
            scene.poke(at, record & 0xFF, record >> 8, scene.peek(record), scene.peek(record + 5))
            scene.poke(record, 0)
        else:
            scene.poke(at, 0, 0, 0, 0)


def big_monster(snapshot: Path, name: str, carrying: int | None = None,
                player_at=CORNER, frames: int = BIG_FRAMES, monster_at=None) -> dict:
    """The knight in the room the monster is in, standing in a corner (or,
    with `player_at` None, close to the monster, which `monster_at` may have
    moved first), until the monster has
    touched him for 20 frames, or `frames` have passed. With `carrying`, that
    collectable is in his first inventory slot."""
    scene = Scene(snapshot)
    scene.no_creatures = True
    scene.clear_creatures()
    slot = _big_slot(scene.sim.memory, name)
    scene.watch.append(slot)
    if carrying is not None:
        _carry(scene, [_collectable(scene.sim.memory, [carrying])])
    extra = {}
    if name == "humpback":
        # Something for it to fetch: the first of $82-$89 put down in its room.
        record = _collectable(scene.sim.memory, range(0x82, 0x8A))
        scene.poke(record + 1, scene.peek(slot + 1))
        scene.poke(record + 3, ROOM_CENTRE[0] + 32, ROOM_CENTRE[1] + 24)
        scene.watch.append(record)
        extra["object"] = scene.peek(record)
    room = scene.peek(slot + 1)
    if monster_at is not None:
        scene.poke(slot + 3, *monster_at)
    if player_at is None:
        # Close to the monster, on the room's side of it.
        mx, my = scene.peek(slot + 3), scene.peek(slot + 4)
        player_at = (mx + (28 if mx < ROOM_CENTRE[0] else -28),
                     my + (28 if my < ROOM_CENTRE[1] else -28))
    extra["home"] = ba.game_memory(snapshot)[slot - TEMPLATE_OFFSET + 1]
    scene.go_to_room(room, *player_at)
    scene.run(2, capture=False)
    scene.frame()
    score = bytes(scene.sim.memory[SCORE:SCORE + 3])
    touching = 0
    for _ in range(frames):
        scene.frame()
        if scene.captures[-1].food < scene.captures[-2].food - 1 or touching:
            touching += 1
        if touching >= 20 or scene.peek(PLAYER) not in IN_PLAY:
            break
        if _burst(scene.peek(slot)) and "killed" not in extra:
            extra["killed"] = len(scene.captures)
        if "killed" in extra and len(scene.captures) > extra["killed"] + 30:
            break
        if name == "humpback" and not scene.peek(scene.watch[-1]) and "gone" not in extra:
            extra["gone"] = len(scene.captures)
        if "gone" in extra and len(scene.captures) > extra["gone"] + 60:
            break
    captures = scene.captures
    frames_ = frames_of(captures, [PLAY_AREA, PANEL_SCORE_ROAST],
                        label=_label_codes(list(range(2, len(scene.watch)))))
    key = name if carrying is None else f"{name}-carrying-{carrying:02X}"
    return _animation(key, frames_, scale=2,
                      facts=dict(extra, room=room, touched=touching > 0,
                                 steps=_food_steps(captures),
                                 score=(score, bytes(scene.sim.memory[SCORE:SCORE + 3]))),
                      sprites=_seen(captures, [2]))


# Door and furniture types (+$00 of a half): see DOOR's table in the listing.
TRAPDOOR_SHUT, TRAPDOOR_OPEN = 0x18, 0x19
TIMED_TYPES = (0x20, 0x21, 0x22, 0x23)
HOLD_CUT = int(1.0 * SECOND)        # a long wait, cut to this in the GIF


def _halves(memory, types) -> list[int]:
    return [a for a in range(DOORS[0], DOORS[1], 8) if memory[a] in types]


def _room_with_one(memory, types) -> int:
    """The first half of that type alone of its kind in its room, in a room
    of the square hall's shape (the room's second table byte, as
    ROOM_SHAPE_OF reads it, 0)."""
    counts = {}
    for half in _halves(memory, types):
        counts.setdefault(memory[half + 1], []).append(half)
    for room in sorted(counts):
        if len(counts[room]) == 1 and memory[ba.ROOM_TABLE + 2 * room + 1] == 0:
            return counts[room][0]
    raise RuntimeError("no room with one of those alone")


def cut_holds(frames: list[list], cut: int = HOLD_CUT) -> list[tuple]:
    """Each picture held longer than `cut` shortened to it; the pictures cut,
    with how long each really lasted."""
    cuts = []
    for index, frame in enumerate(frames):
        if frame[1] > cut:
            cuts.append((index, frame[1]))
            frame[1] = cut
    return cuts


def timed_door(snapshot: Path) -> dict:
    """The knight standing in the middle of a room with one timed door, until
    it has changed three times."""
    scene = Scene(snapshot)
    half = _room_with_one(scene.sim.memory, TIMED_TYPES)
    room = scene.peek(half + 1)
    scene.no_creatures = True
    scene.clear_creatures()
    scene.go_to_room(room, *ROOM_CENTRE)
    scene.watch.append(half)
    scene.frame()
    changes = []
    for _ in range(40 * 50):
        before = scene.peek(half)
        scene.frame()
        if scene.peek(half) != before:
            changes.append((len(scene.captures) - 1, scene.peek(half),
                            _word(scene.sim.memory, TICKS)))
            if len(changes) == 3:
                break
    scene.run(10)
    captures = scene.captures
    box = changed_box(captures[1:], PLAY_AREA, margin=16)
    frames = frames_of(captures, [box], label=_label_codes([2]))
    waits = [((b[2] - a[2]) & 0xFFFF, captures[b[0]].t - captures[a[0]].t)
             for a, b in zip(changes, changes[1:])]

    cuts = cut_holds(frames)
    return _animation("timed-door", frames, scale=3,
                      facts={"room": room, "changes": changes, "waits": waits, "cuts": cuts,
                             "at": (scene.peek(half + 3), scene.peek(half + 4))},
                      sprites=[])


def trapdoor(snapshot: Path) -> dict:
    """The knight in a room with one trapdoor, well away from it, until it has
    shut and opened again."""
    scene = Scene(snapshot)
    half = _room_with_one(scene.sim.memory, (TRAPDOOR_SHUT, TRAPDOOR_OPEN))
    room = scene.peek(half + 1)
    door = (scene.peek(half + 3), scene.peek(half + 4))
    # The corner of the room furthest from it.
    at = (ROOM_CENTRE[0] + (40 if door[0] < ROOM_CENTRE[0] else -40),
          ROOM_CENTRE[1] + (40 if door[1] < ROOM_CENTRE[1] else -40))
    scene.no_creatures = True
    scene.clear_creatures()
    scene.go_to_room(room, *at)
    scene.watch.append(half)
    scene.frame()
    changes = []
    for _ in range(90 * 50):
        before = scene.peek(half)
        scene.frame()
        if scene.peek(half) != before:
            changes.append((len(scene.captures) - 1, scene.peek(half)))
            if len(changes) == 2:
                break
    scene.run(10)
    captures = scene.captures
    # Only round the trapdoor: a timed door elsewhere in the room changes too.
    area = (max(0, door[0] - 24) // 8 * 8, max(0, door[1] - 40) // 8 * 8,
            min(192, door[0] + 48) // 8 * 8, min(192, door[1] + 24) // 8 * 8)
    box = changed_box(captures[1:], area, margin=16)
    frames = frames_of(captures, [box], label=_label_codes([2]))
    first = captures[changes[0][0]].t - captures[0].t
    waits = [captures[b[0]].t - captures[a[0]].t for a, b in zip(changes, changes[1:])]
    cuts = cut_holds(frames)
    return _animation("trapdoor", frames, scale=3,
                      facts={"room": room, "door": door, "changes": changes, "first": first,
                             "waits": waits, "cuts": cuts},
                      sprites=[])


def trapdoor_fall(snapshot: Path) -> dict:
    """The knight put beside an open trapdoor and walking onto it: the fall,
    read every fiftieth of a second, and the arrival in the room below."""
    scene = Scene(snapshot)
    half = _room_with_one(scene.sim.memory, (TRAPDOOR_SHUT, TRAPDOOR_OPEN))
    room = scene.peek(half + 1)
    x, y = scene.peek(half + 3), scene.peek(half + 4)
    scene.no_creatures = True
    scene.clear_creatures()
    if scene.peek(half) != TRAPDOOR_OPEN:
        raise RuntimeError("the trapdoor is not open")
    scene.go_to_room(room, x - 12, y - 4)
    scene.frame()
    fell = scene.by_time(TRAPDOOR_FALL_START, 2.0, ["w"])
    if not fell:
        raise RuntimeError("the knight did not fall")
    t_fall = scene.t()
    scene.by_time(ARRIVE_IN_ROOM, 4.0)
    fall = scene.t() - t_fall
    below = scene.room()
    scene.run(40)
    captures = scene.captures
    frames = frames_of(captures, [PLAY_AREA], label=_label_codes([0]))
    return _animation("trapdoor-fall", frames, scale=2,
                      facts={"room": room, "below": below, "fall": fall / SECOND,
                             "at": (x, y)},
                      sprites=[])


def materialising(snapshot: Path) -> dict:
    """The first frames of a game, from the first FRAME_TICK after START_GAME:
    the score flashing, then the knight rising out of the floor."""
    scene = Scene(snapshot, from_start=True)
    scene.no_creatures = True
    scene.capture()
    flash_end = rise_end = None
    for _ in range(400):
        scene.frame()
        if flash_end is None and scene.peek(FLASH_COUNT) == 0:
            flash_end = len(scene.captures) - 1
        if scene.peek(PLAYER) in IN_PLAY:
            rise_end = len(scene.captures) - 1
            break
    scene.run(15)
    captures = scene.captures
    box = changed_box(captures, around(scene.peek(PLAYER + 3), scene.peek(PLAYER + 4)), margin=4)
    frames = frames_of(captures, [box, PANEL_LIFE], label=_label_codes([0]))
    return _animation("materialising", frames,
                      facts={"flash": (captures[flash_end].t - captures[0].t) / SECOND,
                             "rise": (captures[rise_end].t - captures[flash_end].t) / SECOND,
                             "flash_frames": flash_end, "rise_frames": rise_end - flash_end},
                      sprites=_seen(captures, [0]))


def dying(snapshot: Path) -> dict:
    """The knight in the middle of room $00 with one unit of life force left:
    the ordinary drain takes it, he sinks, leaves a gravestone, and a new life
    flashes the score and rises in the same place."""
    scene = quiet_scene(snapshot)
    scene.frame()
    scene.poke(FOOD_LEVEL, 1)
    lives = scene.peek(LIVES)
    marks = {}
    for _ in range(600):
        scene.frame()
        code = scene.peek(PLAYER)
        n = len(scene.captures) - 1
        if code == 0x67 and "sink" not in marks:
            marks["sink"] = n
        if code == 0x66 and "sink" in marks and "flash" not in marks:
            marks["flash"] = n
        if "flash" in marks and scene.peek(FLASH_COUNT) == 0 and "rise" not in marks:
            marks["rise"] = n
        if "rise" in marks and code in IN_PLAY:
            marks["back"] = n
            break
    scene.run(15)
    captures = scene.captures
    box = changed_box(captures, around(scene.peek(PLAYER + 3), scene.peek(PLAYER + 4)), margin=4)
    frames = frames_of(captures, [box, PANEL_LIFE], label=_label_codes([0]))

    def seconds(a, b):
        return (captures[marks[b]].t - captures[marks[a]].t) / SECOND
    return _animation("dying", frames,
                      facts={"lives": (lives, scene.peek(LIVES)),
                             "sinking": seconds("sink", "flash"),
                             "flashing": seconds("flash", "rise"),
                             "rising": seconds("rise", "back"),
                             "marks": dict(marks)},
                      sprites=_seen(captures, [0]))


FOOD_START = 96             # twelve eighths of the roast


def eating(snapshot: Path) -> dict:
    """The knight three cells to the left of a piece of food, with the life
    force at 96, walking into it."""
    scene = Scene(snapshot)
    scene.no_creatures = True
    scene.clear_creatures()
    memory = scene.sim.memory
    record = None
    for address in range(OBJECTS[0], OBJECTS[1], 8):
        if 0x50 <= memory[address] <= 0x57 and memory[address + 1] != START_ROOM:
            x, y = memory[address + 3], memory[address + 4]
            if abs(x - ROOM_CENTRE[0]) < 32 and abs(y - ROOM_CENTRE[1]) < 32:
                record = address
                break
    if record is None:
        raise RuntimeError("no food near the middle of a room")
    room, x, y = scene.peek(record + 1), scene.peek(record + 3), scene.peek(record + 4)
    kind = scene.peek(record)
    scene.go_to_room(room, x - 24, y)
    scene.poke(FOOD_LEVEL, FOOD_START)
    scene.watch.append(record)
    scene.frame()
    scene.frame()
    before = scene.peek(FOOD_LEVEL)
    for _ in range(40):
        scene.frame(["w"] if scene.peek(record) else [])
        if not scene.peek(record):
            break
    scene.run(25)
    captures = scene.captures
    box = changed_box(captures, PLAY_AREA, margin=12)
    frames = frames_of(captures, [box, PANEL_SCORE_ROAST], label=_label_codes([0, 2]))
    return _animation("eating", frames,
                      facts={"room": room, "kind": kind, "before": before,
                             "after": scene.peek(FOOD_LEVEL), "steps": _food_steps(captures)},
                      sprites=[kind])


COLLECTABLES = (0xEB18, 0xEB58)     # the eight objects $82-$89


def picking_up(snapshot: Path) -> dict:
    """Two objects already carried; the knight walks onto a third and
    presses SYMBOL SHIFT, then walks on and presses it three times more with
    nothing underfoot, a few steps apart."""
    scene = Scene(snapshot)
    scene.no_creatures = True
    scene.clear_creatures()
    memory = scene.sim.memory
    mushrooms = {memory[a + 1] for a in range(OBJECTS[0], OBJECTS[1], 8) if memory[a] == 0xA1}
    monsters = {memory[a + 1] for a in BIG_SLOTS}
    lying = [a for a in range(*COLLECTABLES, 8) if memory[a]]
    # One lying in a room with no mushroom or big monster to spoil it.
    target = next(a for a in lying if memory[a + 1] not in mushrooms | monsters)
    carried = [a for a in lying if a != target][:2]
    codes = [memory[target]] + [memory[a] for a in carried]
    _carry(scene, carried)
    room, x, y = scene.peek(target + 1), scene.peek(target + 3), scene.peek(target + 4)
    scene.watch.append(target)
    scene.go_to_room(room, x - 24, y)
    scene.frame()
    slots = []

    def inventory():
        slots.append(tuple(scene.peek(CARRIED + 4 * i + 2) for i in range(3)))
    inventory()
    scene.until(lambda s: abs(s.peek(PLAYER + 3) - x) < 4, 30, ["w"])
    scene.run(4)
    # Steps away between presses: towards the middle of the room, across and
    # then down or up, so each press is on bare floor.
    across = ["w"] if x < ROOM_CENTRE[0] else ["q"]
    down = ["e"] if y < ROOM_CENTRE[1] else ["r"]
    for press in range(4):
        scene.run(3, [PICK_UP_KEY])
        scene.run(6)
        inventory()
        if press < 3:
            scene.run(10, across if press % 2 == 0 else down)
            scene.run(4)
    scene.run(10)
    captures = scene.captures
    box = changed_box(captures, PLAY_AREA, margin=12)
    frames = frames_of(captures, [box, PANEL_INVENTORY], label=_label_codes([0]))
    return _animation("picking-up", frames, facts={"room": room, "codes": codes, "slots": slots},
                      sprites=codes)


def mushroom(snapshot: Path) -> dict:
    """The knight put on a mushroom, full of life, and left there."""
    scene = Scene(snapshot)
    scene.no_creatures = True
    scene.clear_creatures()
    memory = scene.sim.memory
    record = next(a for a in range(OBJECTS[0], OBJECTS[1], 8) if memory[a] == 0xA1)
    room, x, y = scene.peek(record + 1), scene.peek(record + 3), scene.peek(record + 4)
    scene.go_to_room(room, x + 4, y)
    scene.watch.append(record)
    scene.frame()
    start = scene.peek(FOOD_LEVEL)
    t0 = scene.t()
    died = None
    for _ in range(50 * 30):
        scene.frame()
        if scene.peek(PLAYER) == 0x67 and died is None:
            died = scene.t()
        if died is not None and scene.peek(PLAYER) == 0x66:
            break
    scene.run(10)
    captures = scene.captures
    box = changed_box(captures, PLAY_AREA, margin=12)
    frames = frames_of(captures, [box, PANEL_SCORE_ROAST], label=_label_codes([0, 2]))
    return _animation("mushroom", frames,
                      facts={"room": room, "start": start, "seconds": (died - t0) / SECOND,
                             "gone": scene.peek(record) == 0},
                      sprites=[0xA1])


def drain_rate(snapshot: Path, frames: int = 1500) -> dict:
    """The knight standing alone in room $00 for `frames` frames: how much
    life force the time drain takes."""
    scene = quiet_scene(snapshot)
    scene.frame(capture=False)
    start, t0, ticks = scene.peek(FOOD_LEVEL), scene.t(), _word(scene.sim.memory, TICKS)
    scene.run(frames, capture=False)
    return {"lost": start - scene.peek(FOOD_LEVEL), "seconds": (scene.t() - t0) / SECOND,
            "passes": (_word(scene.sim.memory, TICKS) - ticks) & 0xFFFF}


WHOLE_SCREEN = (0, 0, 256, 192)
ACG_PIECES = [0xEAA8, 0xEAB0, 0xEAB8]   # $8C, $8D, $8E: the order the door wants


def winning(snapshot: Path) -> dict:
    """The three pieces of the A.C.G. key carried in the order the door wants
    them, and the knight a little way from the door in room $00, walking
    into it: the passage, room $8E, and the end screen until the title comes
    back."""
    scene = Scene(snapshot)
    scene.no_creatures = True
    scene.clear_creatures()
    _carry(scene, ACG_PIECES)
    scene.go_to_room(START_ROOM, 0x80, ROOM_CENTRE[1])
    scene.frame()
    if not scene.by_time(SHOW_END_SCREEN, 3.0, ["w"]):
        raise RuntimeError("the end screen did not come")
    t_end = scene.t()
    if not scene.by_time(TITLE_AGAIN, 15.0):
        raise RuntimeError("the title did not come back")
    frames = frames_of(scene.captures, [WHOLE_SCREEN])
    return _animation("winning", frames, scale=2,
                      facts={"end": (scene.t() - t_end) / SECOND}, sprites=[])


def game_over(snapshot: Path) -> dict:
    """The last life, with one unit of life force: game over, until the title
    comes back."""
    scene = quiet_scene(snapshot)
    scene.frame()
    scene.poke(LIVES, 0)
    scene.poke(FOOD_LEVEL, 1)
    if not scene.by_time(GAME_OVER, 3.0):
        raise RuntimeError("the game did not end")
    t_end = scene.t()
    if not scene.by_time(TITLE_AGAIN, 15.0):
        raise RuntimeError("the title did not come back")
    frames = frames_of(scene.captures, [WHOLE_SCREEN])
    return _animation("game-over", frames, scale=2,
                      facts={"end": (scene.t() - t_end) / SECOND}, sprites=[])


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


_SECTION_RE = re.compile(r"^\[Sprites:(s[0-9A-F]{2}):\$([0-9A-F]{2})(?:-\$([0-9A-F]{2}))?")


@functools.lru_cache(maxsize=None)
def _sprite_sections(ref: str) -> tuple:
    """The Sprites page's sections, as (anchor, first code, last code), from
    the ref file the build writes for it."""
    out = []
    path = Path(ref)
    if path.exists():
        for line in path.read_text(encoding="utf-8").splitlines():
            match = _SECTION_RE.match(line)
            if match:
                first = int(match.group(2), 16)
                last = int(match.group(3), 16) if match.group(3) else first
                out.append((match.group(1), first, last))
    return tuple(out)


class _Context:
    """What the words need from the game and the build: the snapshot's
    memory, the listing's entries, the Sprites page's sections, the sprite
    names from the annotations."""

    def __init__(self, snapshot: Path):
        self.memory = ba.game_memory(snapshot)
        self.starts = _entry_starts(str(Path(snapshot).with_name("aticatac.skool")))
        self.sections = _sprite_sections(str(Path(snapshot).with_name("aticatac-sprites.ref")))
        self.names = ba.sprite_names()

    def graphic(self, code: int) -> int:
        return _word(self.memory, SPRITE_TABLE + 2 * (code - 1))

    def handler(self, code: int) -> int:
        return _word(self.memory, ba.ACTOR_HANDLERS + 2 * code)

    def name(self, code: int) -> str:
        if code in UNNAMED:
            return UNNAMED[code]
        for low, high, name in self.names:
            if low <= code <= high:
                return name
        return f"sprite ${code:02X}"

    def section(self, code: int) -> str | None:
        for anchor, first, last in self.sections:
            if first <= code <= last:
                return anchor
        return None

    def frame_link(self, code: int) -> str:
        return f"${code:02X} (#R${self.graphic(code):04X})"


# A creature the annotations leave unnamed, described from its picture (the
# notes' description).
UNNAMED = {0x94: "A cloaked figure"}

MAX_LISTED = 18


def _order(frames: list[list]) -> str:
    """The sprite frames in each picture of the GIF with how long it lasts;
    pictures in a row with the same label as one run."""
    total = sum(gif_times(frames)) / 1000
    if not any(label for _, _, label in frames):
        return f"{len(frames)} pictures, {total:.1f}s in all"
    runs = []
    for (_, _, label), ms in zip(frames, gif_times(frames)):
        label = label or "-"
        if runs and runs[-1][0] == label:
            runs[-1][1] += 1
            runs[-1][2] += ms
        else:
            runs.append([label, 1, ms])
    parts = [f"{label} ({ms}ms)" if count == 1 else f"{label} x{count} ({ms}ms)"
             for label, count, ms in runs]
    if len(parts) > MAX_LISTED:
        parts = parts[:MAX_LISTED // 2] + ["..."] + parts[-(MAX_LISTED // 2 - 1):]
    return ", ".join(parts) + f": {len(frames)} pictures, {total:.1f}s in all"


def _s(seconds: float) -> str:
    return f"{seconds:.1f}s"


def _bcd(score: bytes) -> int:
    return int("".join(f"{b:02X}" for b in score))


CHARACTER_WORDS = {
    "knight": ("knight", 0x8E26, 3, "the axe", 0x8134, 0xA41B),
    "wizard": ("wizard", 0x80D2, 32, "the spell", 0x814B, 0xA438),
    "serf": ("serf", 0x8DC4, 1, "the sword", 0x8283, 0xA427),
}


def _words(animation: dict, ctx: _Context) -> tuple[str, str]:
    """The title and the paragraph for an animation, with what its run
    measured written in."""
    key, facts = animation["key"], animation["facts"]
    frames = animation["frames"]
    if key == "materialising":
        return ("Materialising", (
            f"A game just started: #R$7D9A has called #R$9443, which puts the character "
            f"into the player's record as sprite $66 at $60, $68, fills the life force, and "
            f"sets a count of 104 frames at $5E3C. While that runs out, #R$8CB7 does nothing "
            f"but #R$8C8C: the six cells of the score flash (their FLASH bit set), with a pip "
            f"every sixteenth frame. Then the figure rises out of the floor, one more row of "
            f"the character's own picture on each frame in four (FRAMES AND 3), drawn in a "
            f"colour that changes every four frames; at full height #R$8D32 turns it back "
            f"into the character. Here the flashing lasted {_s(facts['flash'])} and the rise "
            f"{_s(facts['rise'])}: more than 104 and 72 fiftieths, because a long pass of "
            f"the loop can swallow a frame, and FRAME_TICK only counts the ones it sees. "
            f"Sprite $66 has no picture: the rising figure is drawn with the character's "
            f"sprite (+$07), which is why the list below shows $66 until the end."))
    if "-walking-" in key:
        who = key.split("-")[0]
        name, handler, _, _, _, _ = CHARACTER_WORDS[who]
        return (f"The {name} walking", (
            f"Each direction held on its own in room $00, the {name} alone, {WALK_FRAMES} "
            f"frames from a frame standing. #R${handler:04X} moves him through #R$8D77 -- two "
            f"pixels a frame at once, whichever the character -- and, while he is moving, on "
            f"each frame when FRAMES AND 3 is 0 steps the low two bits of his sprite round "
            f"the four frames of the heading and calls #R$A3C7 for a footstep. The heading is "
            f"picked by the larger of the two speeds: the first four codes are left, then "
            f"right, up and down. The step every fourth frame comes out as a picture held "
            f"four or five frames here, because now and then a frame goes by without a "
            f"FRAME_TICK."))
    if key.endswith("-coasting"):
        return ("Coasting to a stop", (
            f"W held for {COAST_HOLD} frames in room $00, then nothing, for each character "
            f"in turn. The heading at +$06 reaches 32 -- two pixels a frame -- in one frame "
            f"of holding a key; let go, #R$8F96 takes the character's own amount off it each "
            f"frame (the knight 3, the wizard 32, the serf 1), and a heading of 16 to 31 is "
            f"still a pixel a frame (#R$8F80 divides by sixteen). So the wizard stops dead, "
            f"and the others slide on: measured here, the knight "
            f"{facts['knight']} pixels in {facts['knight_frames']} frames, the wizard "
            f"{facts['wizard']}, the serf {facts['serf']} in {facts['serf_frames']}. The "
            f"walking frame keeps turning over while he slides, since the heading is not yet "
            f"zero."))
    if key.endswith("-weapon"):
        who = key.split("-")[0]
        name, _, _, weapon, fire, sound = CHARACTER_WORDS[who]
        how = {
            "knight": ("#R$81DB takes the axe's frame from FRAMES -- NOT FRAMES, halved, "
                       "AND 7 -- so it turns through its eight angles, a new one every other "
                       "frame, and draws it red"),
            "wizard": ("#R$81F0 steps the spell on to its next frame every frame, round "
                       "four, and swaps its colour between cyan and white every frame too"),
            "serf": ("#R$82F1 draws the sword yellow at whichever of eight angles matches its "
                     "velocity (#R$82C3), so it changes only when it bounces: it does not "
                     "spin, whatever its sprites' name says"),
        }[who]
        return (f"The {name}'s weapon: {weapon}", (
            f"W, R and T together for one frame in the middle of room $00 -- right, up and "
            f"fire -- then nothing. #R${fire:04X} fires only when the weapon slot ($EA98) is "
            f"empty and the {name} is not in a doorway; it plays #R${sound:04X}, and "
            f"#R$817C gives the weapon four pixels a frame on each axis the heading has, and "
            f"48 frames to live. {how[0].upper() + how[1:]}. All three then go through "
            f"#R$8209: a bounce off the room's walk rectangle turns the velocity round with "
            f"#R$A4B0's click, and when the time is up it is rubbed out with #R$A445. Here it "
            f"flew for {_s(facts['seconds'])} and bounced {facts['bounces']} times."))
    if key == "shot":
        before, after = facts["score"]
        return ("Shot", (
            f"A {ctx.name(facts['kind']).lower()} made to arrive in room $00, and once it had, "
            f"the knight put {facts['distance']} pixels to its left, level with it (the "
            f"nearest of a few distances tried from which the axe hit), firing right. Every "
            f"small creature's mover calls #R$8566, a box twelve pixels each way round the "
            f"weapon: a hit sets the weapon's hit flag, which ends its flight at the next "
            f"frame, and jumps to #R$875F. That rubs the creature out, makes it sprite $6C "
            f"with a count of 16, adds 155 to the score (#R$A19C) and draws it; "
            f"#R$8787 then counts down once a pass, showing $6C + (count AND 3), and at 0 "
            f"rubs it out with #R$A445's sound and frees the slot. The score here went from "
            f"{_bcd(before)} to {_bcd(after)}. The burst is the same whatever was shot."))
    if key == "caught":
        (food0, score0), (food1, score1) = facts["before"], facts["after"]
        return ("Caught", (
            f"The same {ctx.name(facts['kind']).lower()}, and the knight put a little to its "
            f"left and walking into it. Every small creature's mover also calls #R$85B2, the "
            f"same twelve-pixel box round the player; a touch jumps to #R$85EA, which takes "
            f"32 off the life force (#R$8ED7) and then -- like a shot -- kills the creature "
            f"with #R$875F, for 155 points. The life force went from {food0} to {food1} here "
            f"(the drops were {', '.join(str(-d) for d in facts['steps'])}: the touch, and "
            f"the ordinary drain), and the score from {_bcd(score0)} to {_bcd(score1)}. The "
            f"roast on the scroll is redrawn a row shorter for each eighth gone (#R$8B8A)."))
    if key in ("mummy", "frankenstein", "devil", "dracula", "humpback") or "-carrying-" in key:
        return _big_words(animation, ctx)
    if key == "timed-door":
        waits = " and ".join(f"{_s(t / SECOND)} ({passes} passes)" for passes, t in facts["waits"])
        return ("A timed door", (
            f"Room ${facts['room']:02X} has one timed door (at ${facts['at'][0]:02X}, "
            f"${facts['at'][1]:02X}), the knight standing in the middle. At the start of the "
            f"game #R$94F5 turned about half the ordinary doors into these. The handlers "
            f"(#R$917D shut, #R$915F open) count one shared countdown, $5E2E, down on every "
            f"other pass; the door that finds it at 0 reloads it with 94 and #R$9193 swaps "
            f"it -- rubs its picture out, flips bit 0 of the type on both halves, shuts or "
            f"opens it and draws it again -- with #R$A46E's rasp. With one timed door in the "
            f"room that is every 190 passes -- the countdown's 94 and the pass that finds it "
            f"at 0, on even passes only; here the waits were {waits}. Those waits are cut to a second in the GIF; the list below gives "
            f"the cut pictures as they were shown."))
    if key == "trapdoor":
        return ("A trapdoor", (
            f"Room ${facts['room']:02X}, whose one trapdoor is at ${facts['door'][0]:02X}, "
            f"${facts['door'][1]:02X}, with the knight in the far corner. An open trapdoor's "
            f"handler (#R$91BC's other half, from $91C5) shuts it on a pass when the low byte "
            f"of #R$5E05 -- a running sum of FRAMES and TICKS -- is zero; a shut one "
            f"(#R$91BC) opens again on a pass when the low byte of TICKS is zero, every 256 "
            f"passes. Each change XORs the old picture off and the other on, with the rasp. "
            f"Here it shut after {_s(facts['first'] / SECOND)} and opened "
            f"{_s(facts['waits'][0] / SECOND)} later; waits longer than a second are cut to "
            f"one in the GIF. The yellow left at its middle after it opens is the game's: "
            f"compared with the screen before it shut, every pixel is back as it was, but the "
            f"four middle colour cells keep the grille's yellow -- presumably because the open "
            f"picture's colour table has $00, leave the cell alone, there (not checked "
            f"against the table)."))
    if key == "trapdoor-fall":
        return ("Falling through a trapdoor", (
            f"The knight put beside the same trapdoor, open, and walking onto it. #R$9731 "
            f"tests a box 24 by 12 at the trapdoor's corner; with him on it, it clears the "
            f"room, draws picture $96 -- twelve nested rectangles -- and for 128 frames plays "
            f"a falling tone, turning the middle four colour cells white one frame in eight "
            f"and black otherwise, and flooding that colour outwards round a spiral "
            f"(#R$9774), so the rectangles seem to rush past. It lasted {_s(facts['fall'])} "
            f"here. Then it goes through #R$9117 by the trapdoor's other half: room "
            f"${facts['below']:02X} below, where he walks in on his own for fifteen frames. "
            f"The screen was read every fiftieth of a second through all this, since the game "
            f"is out of its loop, and so shows the clearing half done."))
    if key == "dying":
        return ("Dying, and rising again", (
            f"The knight in the middle of room $00 with one unit of life force left. The "
            f"ordinary drain in #R$8E78 takes it and jumps to #R$8EA0: a life gone "
            f"(lives {facts['lives'][0]} to {facts['lives'][1]}), the character's code and "
            f"height kept in +$07 and +$06, and the sprite $67. #R$8D45 lowers him a row on "
            f"three frames in four and on the fourth only changes his colour; at the bottom "
            f"#R$95A9 leaves a gravestone ($8F) in the first free of four slots, and "
            f"#R$9443 starts the next life in the same place, exactly as a game starts "
            f"(above). Measured here: sinking {_s(facts['sinking'])}, the score flashing "
            f"{_s(facts['flashing'])}, rising {_s(facts['rising'])}. The new life rises "
            f"through the gravestone, and the two clash in colour."))
    if key == "eating":
        return ("Eating", (
            f"A piece of food (sprite ${facts['kind']:02X}) in "
            f"room ${facts['room']:02X}, the knight put three cells to its left with the life "
            f"force set to {FOOD_START}, and walking into it. #R$8C63 runs every pass for each "
            f"piece in the room; within twelve pixels (#R$90FB) it rubs the food out, empties "
            f"its record, starts the eating sound (#R$A485) and adds 64, capped at 240. The "
            f"life force went from {facts['before']} to {facts['after']} (the other change "
            f"is the ordinary drain), and #R$8B8A redrew the roast {64 // 8} eighths taller. "
            f"The slot fills again much later, with a random kind, when #R$9924 comes round "
            f"to it with the player elsewhere."))
    if key == "mushroom":
        return ("The roast draining: a mushroom", (
            f"The knight put on a mushroom in room ${facts['room']:02X}, the life force at "
            f"{facts['start']}, and left there. #R$988B takes a unit a pass while he is within "
            f"twelve pixels (#R$98B1), with a sound, and cycles its own colour every fourth "
            f"pass; #R$8B8A takes a row off the top of the roast on the scroll -- the whole "
            f"roast picture drawn over the picked bones -- for each eighth of the life force "
            f"gone. He was dead after {_s(facts['seconds'])}; the mushroom, its work done, "
            f"is removed (#R$98C8), and he sinks. Standing still with nothing near, the "
            f"ordinary drain is much slower: measured, {DRAIN['lost']} units in "
            f"{_s(DRAIN['seconds'])} ({DRAIN['passes']} passes) in room $00, so a full roast "
            f"lasts about {round(240 * DRAIN['seconds'] / DRAIN['lost'])} seconds."))
    if key == "picking-up":
        codes = facts["codes"]
        slots = facts["slots"]

        def inv(state):
            return "[" + ", ".join(f"${c:02X}" if c else "-" for c in state) + "]"
        return ("Picking up and putting down", (
            f"Two objects already carried ({ctx.frame_link(codes[1])} and "
            f"{ctx.frame_link(codes[2])}, their records emptied as a pick-up empties them), and "
            f"the knight walking onto a third, {ctx.frame_link(codes[0])}, in room "
            f"${facts['room']:02X}; then SYMBOL SHIFT for three frames, and three more presses "
            f"a few steps apart on bare floor. #R$938B reads the key once a pass. On an "
            f"object, #R$92F5: #R$9358 puts down whatever is in the third slot, #R$934C moves "
            f"the first two along, and #R$9326 puts the new one first and rubs it out of the "
            f"room; #R$A13B redraws the three slots on the scroll. On bare floor, the drop "
            f"controller's #R$93E3 does the same with nothing to put first -- so a press "
            f"moves the queue along, and only what falls off the end is put down, at his "
            f"feet. The slots, newest first, went {' then '.join(inv(s) for s in slots)}. "
            f"One press does one thing: the key must be let go before it acts again."))
    if key == "winning":
        return ("Winning", (
            f"The three pieces of the A.C.G. key carried in the order #R$961B wants -- $8C "
            f"newest, $8E oldest -- and the knight in room $00 walking at the great door. With "
            f"them the door is open and he walks through into room $8E, the passage; at the "
            f"end of that pass #R$7DC3 finds him there and jumps to #R$96EC, which prints "
            f"CONGRATULATIONT (the game's misspelling), a line saying he has escaped, and the summary "
            f"(#R$9641: the time, the score and the share of the castle seen), and waits in "
            f"#R$8C4A -- {_s(facts['end'])} here from the end screen to the title. The whole "
            f"screen is shown, read every fiftieth of a second. The scroll turns green in the "
            f"passage: #R$A240 colours it the room's ink complemented, and green where that "
            f"would be black, as it is for a white room."))
    if key == "game-over":
        return ("Game over", (
            f"No spare lives and one unit of life force, in room $00. The drain's jump to "
            f"#R$8EA0 finds no lives and goes to #R$8C35: the room is cleared, GAME OVER and "
            f"the same summary printed, and the same wait -- {_s(facts['end'])} here -- before "
            f"the title comes back. There is no sinking: the last life ends at once."))
    raise KeyError(key)


BIG_WORDS = {
    "mummy": ("The mummy", 0x8862),
    "frankenstein": ("Frankenstein's monster", 0x8988),
    "devil": ("The devil", 0x89ED),
    "dracula": ("Dracula", 0x8906),
    "humpback": ("The humpback", 0x8AFF),
}


def _big_words(animation: dict, ctx: _Context) -> tuple[str, str]:
    key, facts = animation["key"], animation["facts"]
    name = key.split("-")[0]
    title, mover = BIG_WORDS[name]
    common = (f"The knight put in the corner of room ${facts['room']:02X}, where the "
              f"monster was at that moment. The big five are dispatched every pass wherever "
              f"they are (#R$7E13); #R${mover:04X} moves this one a pixel a pass on each "
              f"axis towards a target (#R$882D) and shows the next of its four frames every "
              f"four passes (TICKS divided by four, AND 3). None of them can be shot. ")
    touched = ""
    if facts.get("touched"):
        drops = [-d for d in facts["steps"] if d < -1]
        touched = (f"Once it reached him the life force went down by "
                   f"{', '.join(str(d) for d in drops)} -- {8 if name != 'humpback' else 16} "
                   f"a pass in contact, plus the ordinary drain -- and the GIF stops twenty "
                   f"frames into that. ")
    if key == "mummy":
        return (title, common + (
            "While the red key is in its room it walks back and forth between two points, "
            "($68, $38) and ($8C, $68), and does not chase the player (though touching it "
            "still costs 8 a pass); once the key has gone it hunts him for the rest of the "
            "game. " + touched))
    if key == "frankenstein":
        return (title, common + ("It hunts the player. " + touched))
    if key == "frankenstein-carrying-8B":
        before, after = facts["score"]
        return ("Frankenstein's monster and the spanner", (
            f"The same, with the spanner ($8B) in the knight's first inventory slot. When "
            f"the monster touches him, #R$8988 finds the spanner (#R$9273), adds 1000 to "
            f"the score and kills it with #R$875F -- 155 more, and the same burst as a small "
            f"creature. Its slot is never filled again. The score went from {_bcd(before)} "
            f"to {_bcd(after)}; the life force lost nothing to it."))
    if key == "devil":
        return (title, common + ("It hunts the player, and nothing in the code stops "
                                 "it. " + touched))
    if key == "dracula":
        return (title, common + (
            "In the player's room he hunts; elsewhere he wanders the castle, now and then "
            "moving to a random square, cave or octagonal room (he was in room "
            f"${facts['room']:02X} by this point of the game, not the ${facts['home']:02X} "
            "#R$8D61 starts him in). "
            + touched))
    if key == "dracula-carrying-8A":
        return ("Dracula and the crucifix", (
            "The same, with the crucifix ($8A) in the knight's first inventory slot: "
            "#R$8906 finds it (#R$9273) and turns his velocity round. Dracula was moved to the "
            "middle of the room and the knight put a little way off; Dracula backs away a "
            "pixel a pass until the walls stop him, and stays there."))
    if key == "humpback":
        return (title, common + (
            f"It stands still unless one of the eight objects $82-$89 is in its room; here "
            f"{ctx.frame_link(facts['object'])} was put down in its room, and it walked to "
            f"it and took it -- the record emptied, the object gone for the game "
            f"(#R$8ADB finds it). Then it stood still again, not animating, since only its "
            f"walking turns the frames over. Its touch costs 16 a pass. " + touched))
    raise KeyError(key)


def _creature_words(group: list[dict], ctx: _Context) -> tuple[str, str]:
    animation = group[0]
    kind = int(animation["key"].split("-")[1], 16)
    table = list(ctx.memory[SPAWN_TYPES:SPAWN_TYPES + 16])
    chance = table.count(kind)
    mover = ctx.handler(kind)
    facts = animation["facts"]
    met = (" Here it found the knight in his corner, touched him and burst." if facts["caught"]
           else "")
    return (ctx.name(kind), (
        f"Sprite ${kind:02X}, {chance} in 16 of the spawns; moved by #R${mover:04X}. The "
        f"arrival lasted {_s(facts['arrival'])}.{met}"))


CREATURES_INTRO = (
    "<p>Small creatures are not kept anywhere in the castle: #R$83EA puts them into the "
    "player's room, three at most, the first 32 frames after he arrives and then at random. A "
    "new one takes the first free of the three slots at $EE60, a copy of #R$8B6A with the "
    "player's room, a kind from the sixteen entries of #R$8B7A picked by FRAMES, a random "
    "place and a random speed. For its first 32 passes it is the arrival, sprites $58-$5B "
    "counting down (#R$85F7); then it becomes its kind, and most kinds animate by flipping "
    "bit 0 of the sprite. They bounce off the room's walk rectangle (#R$84CD), ignore doors "
    "and furniture, and die the moment they touch the player or the weapon (below). Each "
    "kind here was made to arrive in room $00 with the knight standing in a corner -- "
    "{note} -- and followed for about four seconds.</p>")


SPAWN_NOTE = ("the spawner's countdown at $5E27 set to 1 and FRAMES to a value whose low "
              "nibble picks this creature from the table; the slot, the random place and "
              "speed are the spawner's own")

MOVER_NOTES = {
    0x845F: "a random pair of direction bits every 16 passes, the speed eased a step a pass "
            "towards two pixels",
    0x87A6: "the same as the pumpkin's but every 8 passes",
    0x862E: "a new random speed, one or two pixels each way, every 256 passes",
    0x8301: "every 16 passes a random direction, then sixteen steps from #R$83CA that swing "
            "from across to up and down: it flies in arcs",
    0x8672: "a counter from -7 to 7 halved into its vertical speed, and a new random speed "
            "each time it tops out: it hops",
    0x871A: "a new random speed every 17 passes",
    0x8A2F: "a new random speed every 16 passes with the vertical part halved, and a picture "
            "that faces the way it flies",
    0x8A80: "a new random speed every 32 passes with the vertical part halved, and a picture "
            "that faces the way it flies",
}


DRAIN: dict = {}


def _make_all(snapshot: Path, log) -> list[list[dict]]:
    """Every animation, in page order, grouped where several GIFs share one
    heading."""
    groups = []
    log("  materialising")
    groups.append([materialising(snapshot)])
    for character in CHARACTERS:
        log(f"  the {character} walking")
        groups.append([walking(snapshot, character, d) for d in range(4)])
    log("  coasting")
    groups.append([coasting(snapshot, character) for character in CHARACTERS])
    for character in CHARACTERS:
        log(f"  the {character}'s weapon")
        groups.append([weapon(snapshot, character)])
    memory = ba.game_memory(snapshot)
    kinds = []
    for kind in memory[SPAWN_TYPES:SPAWN_TYPES + 16]:
        if kind not in kinds:
            kinds.append(kind)
    for kind in kinds:
        log(f"  creature ${kind:02X}")
        groups.append([creature(snapshot, kind)])
    for make in (shot, caught):
        log(f"  {make.__name__}")
        groups.append([make(snapshot)])
    log("  the big five")
    groups.append([big_monster(snapshot, "mummy")])
    groups.append([big_monster(snapshot, "frankenstein"),
                   big_monster(snapshot, "frankenstein", carrying=0x8B)])
    groups.append([big_monster(snapshot, "devil")])
    groups.append([big_monster(snapshot, "dracula"),
                   big_monster(snapshot, "dracula", carrying=0x8A, player_at=None,
                               frames=150, monster_at=ROOM_CENTRE)])
    groups.append([big_monster(snapshot, "humpback")])
    for make in (timed_door, trapdoor, trapdoor_fall, dying, eating, mushroom, picking_up,
                 winning, game_over):
        log(f"  {make.__name__}")
        groups.append([make(snapshot)])
    DRAIN.update(drain_rate(snapshot))
    return groups


def _picture_tag(animation: dict, alt: str) -> str:
    frames = animation["frames"]
    width, height = frames[0][0].size
    scale = animation["scale"]
    return (f'<img src="{IMAGE_DIR}/{animation["key"]}.gif" alt="{_esc(alt)}" '
            f'width="{width * scale}" height="{height * scale}" '
            f'style="image-rendering:pixelated;max-width:100%;height:auto">')


def _captioned(image: str, caption: str) -> str:
    return (f'<span style="display:inline-block;margin:0 12px 8px 0;vertical-align:top;'
            f'text-align:center">{image}<br>{_esc(caption)}</span>')


def _sprite_line(codes, ctx: _Context) -> str:
    codes = sorted(c for c in set(codes) if c)
    if not codes:
        return ""
    anchors = []
    for code in codes:
        anchor = ctx.section(code)
        if anchor and anchor not in anchors:
            anchors.append(anchor)
    ranges = {anchor: (first, last) for anchor, first, last in ctx.sections}
    pages = ", ".join(
        f'<a href="Sprites.html#{a}">${ranges[a][0]:02X}'
        + (f'-${ranges[a][1]:02X}' if ranges[a][1] != ranges[a][0] else "") + "</a>"
        for a in anchors)
    drawn = [c for c in codes if ctx.section(c)]
    text = "Sprite frames drawn: " + ", ".join(ctx.frame_link(c) for c in drawn)
    others = [c for c in codes if not ctx.section(c)]
    if others:
        text += ("; and " + ", ".join(f"${c:02X}" for c in others)
                 + ", which has no picture of its own")
    if pages:
        text += f" (on the Sprites page: {pages})"
    return f"<p>{text}.</p>"


INTRO = [
    "<p>Every animation below is Atic Atac running its own code in SkoolKit's simulator, "
    "made when these pages were built. Each scene is a game started the way the build "
    "starts one for the room pictures -- from the title screen, with the character's key "
    "and 0 -- and run until the character has materialised in room $00. Then what the "
    "scene needs is put in place at the top of a frame, and said below: the player sent to "
    "another room through #R$9147 (the way the room pictures are drawn, which skips the "
    "walk in through a door), a creature made to arrive, an object laid down or put in the "
    "inventory, the life force set. After that everything is the game's: its movement, its "
    "animation, its drawing. In the scenes that are not about the creatures the spawner's "
    "countdown ($5E27) is held up at every frame so that none arrive. All of this is the "
    "first game after loading, whose layout -- the keys, the timed doors, where Dracula "
    "has got to -- is always the same, because FRAMES does not move on the title screen "
    "(see the Map page).</p>",
    "<p>The game draws straight onto the screen, XORing each thing off at its old place "
    "and on at its new one a row at a time (#R$9FCA), and it runs at two speeds (#R$7DC3): "
    "the player, the weapon and the sound move once a 50Hz frame, in #R$7EB2, which the "
    "loop calls between records whenever FRAMES has moved; the creatures, the big monsters, "
    "doors and food move once a pass of the loop, about every other frame in a quiet room. "
    "So the screen is read at the top of FRAME_TICK, when no record is half drawn, and each "
    "picture lasts until the next reading: the T-states between them, counted by the "
    "simulator at 3.5MHz with no memory contention (a real Spectrum is a little slower). "
    "Identical pictures in a row are one, for their total time; a GIF can only say "
    "hundredths, and 20ms at the least. Where the game leaves its loop -- a fall through a "
    "trapdoor, the ends of the game -- the screen is read every fiftieth of a second "
    "instead. FLASH is drawn in the phase the ULA would be in. Each GIF is cropped to what "
    "changed, or shows the room, with the part of the scroll that matters beside it; under "
    "each, the sprite frames of the things it follows in each picture and how long it "
    "lasted.</p>",
]

LEFT_OUT = (
    "<p>Left out: walking through an ordinary door, which is a new room drawn and fifteen "
    "frames of the player walking in on his own; the locked doors and the clocks, "
    "bookcases and barrels, which open for the right key or character without anything "
    "to see but the way through; the title screen's flashing menu lines; and Dracula's "
    "wandering, which happens where nobody can see it. The pictures of the characters "
    "walking diagonally are the same sixteen frames, chosen by the larger of the two "
    "speeds. Nothing here was checked on a real Spectrum or in the emulator; all of it is "
    "the simulator's.</p>")

WALK_CAPTIONS = ["left (Q)", "right (W)", "up (R)", "down (E)"]


def build(snapshot: Path, html_dir: Path, log=print) -> dict[str, str]:
    """Write the GIFs into html_dir/images/animations and return the
    Animations section."""
    snapshot = Path(snapshot)
    out_dir = Path(html_dir) / IMAGE_DIR
    out_dir.mkdir(parents=True, exist_ok=True)
    log("Running the animations in the game's own code...")
    ctx = _Context(snapshot)
    groups = _make_all(snapshot, log)
    lines = ['<div class="aa-animations">'] + INTRO
    creatures_started = False
    for group in groups:
        first = group[0]
        key = first["key"]
        for animation in group:
            save_gif(out_dir / f"{animation['key']}.gif", animation["frames"])
        if key.startswith("creature-"):
            if not creatures_started:
                lines += ["<h3>The creatures</h3>",
                          CREATURES_INTRO.format(note=SPAWN_NOTE)]
                creatures_started = True
            title, words = _creature_words(group, ctx)
            mover = ctx.handler(int(key.split("-")[1], 16))
            if mover in MOVER_NOTES:
                words += f" How it moves (read from #R${mover:04X}): {MOVER_NOTES[mover]}."
        elif key.endswith("-coasting"):
            facts = {}
            for animation in group:
                who = animation["key"].split("-")[0]
                facts[who] = animation["facts"]["coast"]
                facts[who + "_frames"] = animation["facts"]["frames"]
            title, words = _words(dict(first, facts=facts), ctx)
        else:
            title, words = _words(first, ctx)
        level = "h4" if key.startswith("creature-") else "h3"
        lines += [f'<div id="{key}">', f"<{level}>{_esc(title)}</{level}>"]
        if len(group) > 1 and (key.endswith("-coasting") or "-walking-" in key):
            captions = (WALK_CAPTIONS if "-walking-" in key
                        else [a["key"].split("-")[0] for a in group])
            lines.append("<p>" + "".join(
                _captioned(_picture_tag(a, f"{title}, {c}"), c)
                for a, c in zip(group, captions)) + "</p>")
            lines.append(f"<p>{words}</p>")
            lines.append(_sprite_line([c for a in group for c in a["sprites"]], ctx))
            for animation, caption in zip(group, captions):
                lines.append(f"<p>{_esc(caption.capitalize())}: {_order(animation['frames'])}.</p>")
        else:
            for index, animation in enumerate(group):
                if index:
                    title, words = _words(animation, ctx)
                    lines.append(f"<h4>{_esc(title)}</h4>")
                lines.append("<p>" + _picture_tag(animation, title) + "</p>")
                lines.append(f"<p>{words}</p>")
                lines.append(_sprite_line(animation["sprites"], ctx))
                lines.append(f"<p>In the picture: {_order(animation['frames'])}.</p>")
        lines.append("</div>")
    lines += [LEFT_OUT, "</div>"]
    body = _links("\n".join(line for line in lines if line), ctx.starts)
    for line in body.splitlines():
        if line.startswith((";", "[")):
            raise RuntimeError(f"a section line may not start with that: {line[:40]}")
    return {"Animations": body}
