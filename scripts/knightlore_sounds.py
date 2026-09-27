"""Knight Lore's sounds, recorded from the game's own code at build time.

build_knightlore.py --html calls build(), which writes a WAV of every tune and
sound effect into the HTML directory's audio/ folder and returns the HTML of
the Sounds section. Nothing here is committed output: the sounds are the
game's.

A 48K Spectrum has one bit of sound hardware, bit 4 of port $FE, and every
noise Knight Lore makes is its code toggling that bit and counting. So a sound
is recorded by running the routine that makes it in SkoolKit's simulator and
noting the T-state of every write that changes bit 4 (SkoolKit's Tracer does
this when told to watch port $FE); the gaps between those edges are the
waveform, which SkoolKit's audio writer renders to a WAV at 44100 Hz. Nothing
is synthesised: every edge in every file is an OUT the game executed.

Two kinds of recording, both on fresh machines:

- A call. One routine, called on a machine of its own built from the snapshot
  with the ROM in place, the registers and variables it reads set to the
  values given below, and a return address that stops the run (the thirteen
  unused bytes at $F0F3, as knightlore_pages.py's Castle uses). A fresh
  machine for every call matters: run one after another on a shared machine,
  each effect inherits what the last left behind -- the Atic Atac build once
  measured an eight-millisecond rasp as a second of sweep that way.
- A room. Many effects are a blip a frame from an object that is moving, and
  what makes them sound the way they do is the frame between the blips. For
  those the game itself is run: the castle set up as knightlore_pages.py's
  Castle sets it up, Sabreman put into a room chosen because the effect's
  object is the only thing in it that makes a noise, and the frame loop run
  from onscreen_loop for a stretch of frames. Every room starts with the
  player materialising, so the stretch recorded begins after that (except for
  the materialising sound itself). The frame windows were found by running
  every room and counting the edges in each frame against what each routine
  makes; they depend only on the snapshot, which is fixed.

The machine is uncontended, so these are a little faster and higher than a
real Spectrum, where the ULA holds up the OUTs and the screen writes.
"""
from __future__ import annotations

import html
import re
from pathlib import Path

import knightlore_pages as kp

SKOOL = (Path(__file__).resolve().parent.parent / "game_disassembly" / "knightlore"
         / "knightlore.skool")
TSTATES_PER_SECOND = 3_500_000
CALL_STACK = 0x5B9E       # SP for a call: the return address goes at $5B9E, just
                          # under the object stack the frame loop uses
CALL_LIMIT = 30           # seconds of emulated time before a call is given up on

# Routines and data (see their entries).
START_GAME_TUNE = 0xB20E
GAME_OVER_TUNE = 0xB218
GAME_COMPLETE_TUNE = 0xB239
MENU_TUNE = 0xB253
PLAY_AUDIO_UNTIL_KEYPRESS = 0xB2BE
PLAY_AUDIO = 0xB2CF
FREQ_TBL = 0xB332
SOUND_MOVABLE_BLOCK = 0xB3E9
SOUND_SPARKLE = 0xB403
SOUND_MATERIALISE = 0xB419
SOUND_THUD = 0xB42E
SOUND_JUMP = 0xB441
SOUND_PITCH_FROM_Z = 0xB451
SOUND_PITCH_FROM_A = 0xB454
SOUND_PITCH_FROM_X = 0xB45D
SOUND_PITCH_FROM_Y = 0xB462
SOUND_PITCH_FROM_XYZ = 0xB467
SOUND_TRANSFORM = 0xB472
SOUND_PORTCULLIS_CRASH = 0xB489
BEEP_X16 = 0xB4A3
BEEP_X24 = 0xB4A8
AUDIO_GUARD_WIZARD = 0xB4AD
SOUND_WALK_STEP = 0xB4BB
SOUND_FOOTSTEP = 0xB4C1
END_OF_FRAME = 0xB000
CYCLE_COLOURS_WITH_SOUND = 0xC2A5

FRAME_COUNTER = 0x5BA2
CONTROL_METHOD = 0x5BA4   # 0: keyboard, rotational
RECORD = kp.PLAYER        # a call's object record: record 0, on a machine of its own
FORWARD_ROW, FORWARD_BIT = 1, 0x01   # A, on the A-G half-row: walk forward

# The frame windows of the room recordings: room, first frame, last frame
# (counted from the first frame in the room, which is 0).
MATERIALISE_ROOM, MATERIALISE_FRAMES = 0x0B, (0, 14)   # an empty room
IDLE_FRAMES = (15, 19)                                  # ...and after it
WALK_FROM = 20                                          # hold A from here
WALK_FRAMES = (20, 39)
DEATH_ROOM, DEATH_FRAMES = 0xF7, (15, 22)
BLOCK_ROOM, BLOCK_FRAMES = 0xA3, (14, 37)
SLIDE_X_ROOM, SLIDE_X_FRAMES = 0x2D, (14, 45)
SLIDE_Y_ROOM, SLIDE_Y_FRAMES = 0x48, (14, 45)
GUARD_ROOM, GUARD_FRAMES = 0xD1, (14, 37)
PORTCULLIS_ROOM, PORTCULLIS_FRAMES = 0x3F, (81, 119)
FRAME_LIMIT = 5_000_000   # T-states before a frame is given up on


def _esc(text: str) -> str:
    return html.escape(text, quote=False)


def _entries() -> set:
    """The addresses that start an entry in the listing, which are the only
    ones #R can link to."""
    found = set()
    if SKOOL.exists():
        for line in SKOOL.read_text(encoding="utf-8").splitlines():
            m = re.match(r"^[bcgistuw]\$([0-9A-F]{4})", line)
            if m:
                found.add(int(m.group(1), 16))
    return found


# --------------------------------------------------------------------------
# Recording.
# --------------------------------------------------------------------------

def _machine(memory):
    """A simulator over `memory` that logs the speaker bit, with the speaker
    taken to start off -- so an OUT that leaves it off is not an edge."""
    from skoolkit import CSimulator
    from skoolkit.simulator import Simulator
    from skoolkit.trace import Tracer

    simulator = (CSimulator or Simulator)(memory, state={"iff": 0, "im": 1, "tstates": 0})
    tracer = Tracer(simulator, 0, 0, 0, [0] * 16, 0, True)   # port_fe: log the beeper
    tracer.spkr = 0
    simulator.set_tracer(tracer)
    return simulator, tracer


def _call(base, address: int, registers=None, pokes=None):
    """Call the routine at `address` on a fresh machine: its speaker edges,
    in T-states from the call, and how long it ran until it returned."""
    from skoolkit.simutils import PC, SP, T
    import skoolkit.simutils as su

    memory = list(base)
    for where, value in (pokes or {}).items():
        memory[where] = value
    memory[CALL_STACK:CALL_STACK + 2] = [kp.TRAP & 0xFF, kp.TRAP >> 8]
    simulator, tracer = _machine(memory)
    for name, value in (registers or {}).items():
        if name in ("IX", "DE", "HL", "BC"):
            high, low = {"IX": ("IXh", "IXl")}.get(name, (name[0], name[1]))
            simulator.registers[getattr(su, high)] = value >> 8
            simulator.registers[getattr(su, low)] = value & 0xFF
        else:
            simulator.registers[getattr(su, name)] = value
    simulator.registers[SP] = CALL_STACK
    simulator.trace(address, kp.TRAP, 0, CALL_LIMIT * TSTATES_PER_SECOND,
                    False, None, None, None, None, None)
    if simulator.registers[PC] != kp.TRAP:
        raise RuntimeError(f"the call to ${address:04X} did not return")
    edges = [t for t, register, _ in tracer.audio_log if register == 0xFF]
    return edges, simulator.registers[T]


def _in_a_row(calls, gap: int):
    """Several calls' recordings end to end, `gap` T-states of silence after
    each: a blip a frame, with a frame's worth of quiet between."""
    edges, now = [], 0
    for call_edges, length in calls:
        edges += [now + t for t in call_edges]
        if len(call_edges) % 2:
            # Left on: a later call's first edge would read as turning it off.
            edges.append(now + length)
        now += length + gap
    return edges, now - gap


def _room_run(castle, room: int, frames: int, forward_from: int | None = None):
    """Put Sabreman into `room` and run the game's frame loop for `frames`
    frames. The speaker edges, and each frame's start in T-states (with the
    end of the last as one more), all measured from the first frame."""
    from skoolkit.simutils import PC, SP, T

    memory = list(castle.memory)
    # As knightlore_pages.trace_frame does: the player back in, materialising
    # (lose_life's type), in the room wanted.
    memory[kp.PLAYER] = memory[kp.PLAYER_TOP] = kp.MATERIALISING
    memory[kp.PLAYER + kp.ROOM_OFFSET] = memory[kp.PLAYER_TOP + kp.ROOM_OFFSET] = room
    memory[CONTROL_METHOD] = 0
    memory[kp.OBJECT_STACK - 2:kp.OBJECT_STACK] = [kp.TRAP & 0xFF, kp.TRAP >> 8]
    simulator, tracer = _machine(memory)
    for index, value in enumerate(castle.registers):
        simulator.registers[index] = value
    simulator.registers[SP] = kp.OBJECT_STACK - 2
    simulator.trace(kp.BUILD_SCREEN_OBJECTS, kp.TRAP, 0, FRAME_LIMIT,
                    False, None, None, None, None, None)
    if simulator.registers[PC] != kp.TRAP:
        raise RuntimeError(f"room ${room:02X} was not built")
    # From here the loop keeps its own stack, reset for every object.
    simulator.registers[SP] = kp.OBJECT_STACK
    tracer.audio_log.clear()
    # A keyboard of its own, so a held key can be read: nothing held yet.
    tracer.keyboard = [0] * 8
    start = simulator.registers[T]
    starts = []
    pc = kp.ONSCREEN_LOOP
    for frame in range(frames):
        if frame == forward_from:
            tracer.keyboard[FORWARD_ROW] = FORWARD_BIT
        starts.append(simulator.registers[T] - start)
        simulator.trace(pc, kp.ONSCREEN_LOOP, 0, simulator.registers[T] + FRAME_LIMIT,
                        False, None, None, None, None, None)
        pc = simulator.registers[PC]
        if pc != kp.ONSCREEN_LOOP:
            raise RuntimeError(f"frame {frame} in room ${room:02X} did not end")
    starts.append(simulator.registers[T] - start)
    edges = [t - start for t, register, _ in tracer.audio_log if register == 0xFF]
    return edges, starts


def _window(run, first: int, last: int):
    """Frames `first` to `last` of a room run: their edges from the start of
    `first`, and the window's length."""
    edges, starts = run
    t0, t1 = starts[first], starts[last + 1]
    inside = [t - t0 for t in edges if t0 <= t < t1]
    if len(inside) % 2:
        inside.append(t1 - t0)      # never happens: every effect ends off
    return inside, t1 - t0


# --------------------------------------------------------------------------
# Measuring and writing.
# --------------------------------------------------------------------------

def _periods(edges):
    """The length of each whole wave (two edges), in T-states, leaving out
    the silences between blips and between frames."""
    waves = [edges[i + 2] - edges[i] for i in range(0, len(edges) - 2, 2)]
    # Nothing the game plays is below 50 Hz (freq_tbl's lowest row is about
    # 52.6 Hz, 66,500 T-states a wave), so anything longer is a gap.
    return [w for w in waves if w < 70_000]


def _hz(tstates: float) -> float:
    return TSTATES_PER_SECOND / tstates


def _write_wav(path: Path, edges, length: int) -> None:
    """Render the speaker edges to a WAV. SkoolKit's writer takes the gaps
    between flips, starting from the speaker off; the first gap is the quiet
    before the first edge and the last the quiet after the final one."""
    from skoolkit.audio import BeeperOptions
    from skoolkit.components import get_audio_writer

    delays = [edges[0]] + [b - a for a, b in zip(edges, edges[1:])]
    if length > edges[-1]:
        delays.append(length - edges[-1])
    delays = [max(d, 1) for d in delays]
    with open(path, "wb") as f:
        get_audio_writer().write_audio(f, delays, BeeperOptions(100, False, False, 0, False))


# --------------------------------------------------------------------------
# What is recorded.
# --------------------------------------------------------------------------

def _tunes(memory) -> list[dict]:
    """The four tunes, each played through by the routine the game uses."""
    out = []
    for name, tune, player, title, what in (
        ("start_game_tune", START_GAME_TUNE, PLAY_AUDIO, "The start of a game",
         "Played in full by #R$AF88 once a control method has been chosen, before "
         "Sabreman first appears."),
        ("menu_tune", MENU_TUNE, PLAY_AUDIO_UNTIL_KEYPRESS, "The menu tune",
         "Played under the control menu, once per visit, until a key is pressed "
         "(#R$B2B6). Two lines, one unit a note, alternating."),
        ("game_over_tune", GAME_OVER_TUNE, PLAY_AUDIO_UNTIL_KEYPRESS, "Game over",
         "Played by #R$BA87 under the game-over screen until a key is pressed: a "
         "moving upper note alternating with a held bass."),
        ("game_complete_tune", GAME_COMPLETE_TUNE, PLAY_AUDIO, "The game completed",
         "Played in full by #R$BAAB under the closing message."),
    ):
        edges, length = _call(memory, player, {"DE": tune})
        notes = []
        address = tune
        while memory[address] != 0xFF:
            notes.append(memory[address])
            address += 1
        how = (f"#R{_hex(player)} called with DE = {_hex(tune)}"
               + (" and no key down, so it plays to the end, as it does for a player "
                  "who waits" if player == PLAY_AUDIO_UNTIL_KEYPRESS else "")
               + f". {len(notes)} notes, {sum((n >> 6) + 1 for n in notes)} units.")
        out.append({"name": name, "entry": tune, "title": title, "what": what,
                    "how": how, "edges": edges, "length": length, "tune": notes})
    return out


def _calls(memory, quiet_frame: int) -> list[dict]:
    """The effects that are one call, or a few calls a known number of frames
    apart."""
    out = []

    def one(name, entry, title, what, how, registers=None, pokes=None):
        edges, length = _call(memory, entry, registers, pokes)
        out.append({"name": name, "entry": entry, "title": title, "what": what,
                    "how": how, "edges": edges, "length": length})

    one("pick_up", BEEP_X16, "Picking up, dropping, an extra life",
        "#R$B4A3: 16 waves at a half-wave count of 128. Played when an object is "
        "picked up or dropped, when an extra life is collected, and when the menu's "
        "choice changes.",
        "One call; it sets its own pitch and length.")
    one("pause", BEEP_X24, "Pause",
        "#R$B4A8: 24 waves at a half-wave count of 80, as SPACE pauses the game and "
        "again as it lets go.",
        "One call; it sets its own pitch and length.")
    one("jump", SOUND_JUMP, "Jumping",
        "#R$B441: a rising sweep of 32 single waves, played as Sabreman leaves the "
        "ground.",
        "One call; it sets its own pitch and length.")
    one("thud", SOUND_THUD, "A thud",
        "#R$B42E: four low blips of three waves, their pitches the first four bytes "
        "of the ROM with the top two bits set. A bouncing ball landing, a flame "
        "turning at a wall.",
        "One call; it takes its pitches from the ROM, so it is the same every time.")
    one("footstep", SOUND_FOOTSTEP, "Turning on the spot",
        "#R$B4C1: one of Sabreman's footsteps, played by itself when he turns "
        "without walking.",
        "One call with Sabreman's legs (IX) at X $80, Y $80, Z $80 -- the middle of "
        "the floor, so 8 waves -- and the frame counter at 0, which picks the fixed "
        "pitch (half-wave count $60); on the other frames of the pair it takes its "
        "pitch from his height instead. The walking recording below has both.",
        {"IX": RECORD}, {RECORD + 1: 0x80, RECORD + 2: 0x80, RECORD + 3: 0x80,
                         FRAME_COUNTER: 0})
    one("cauldron", CYCLE_COLOURS_WITH_SOUND, "A charm into the cauldron",
        "#R$C2A5: sixteen passes, each stepping the ink of every attribute cell on "
        "by one, making a burst with #R$B403 and pausing. The colour cycling and "
        "noise when the right charm lands in the cauldron.",
        "One call with the charm (IX) of type 104, the first of the types a charm "
        "takes as it falls in (104-110), so each burst is (NOT 104) AND 31 = 23 "
        "blips; a charm of type 110 makes 17. The silences are the attribute "
        "passes and the pauses, which are part of the routine.",
        {"IX": RECORD}, {RECORD: 104})
    one("finale_tone", SOUND_PITCH_FROM_A, "The finale's tone",
        "#R$B454: six waves at a half-wave count from A. During the finale "
        "#R$B000 plays it at the end of every frame, pitched by the last spark's "
        "height at $5BC5.",
        "One call with A = $A4, the height a spark climbs to before homing on "
        "Sabreman (half-wave count $6D). In the game it sounds once a frame for "
        "the whole finale.",
        {"A": 0xA4})

    # The transformation: a step every fourth frame, eight of them, each with
    # the frame showing at the time -- which the game picks at random. Here the
    # four frames in turn, twice, four quiet frames apart.
    calls = [_call(memory, SOUND_TRANSFORM, {"IX": RECORD}, {RECORD: 92 + (i & 3)})
             for i in range(8)]
    edges, length = _in_a_row(calls, 4 * quiet_frame)
    out.append({
        "name": "transform", "entry": SOUND_TRANSFORM,
        "title": "Man to werewolf, and back",
        "what": "#R$B472: a warble of 16 to 40 single waves at pitches scrambled "
                "from the step count, played by #R$C349 every fourth frame for "
                "the eight steps of the change at sunset and sunrise.",
        "how": "Eight calls with the legs (IX) of types 92, 93, 94, 95, 92, 93, 94, "
               "95 -- 16, 24, 32 and 40 waves -- where the game picks each frame at "
               "random; four quiet frames apart (four times the frame measured in "
               f"room ${MATERIALISE_ROOM:02X}, {4 * quiet_frame:,} T-states).",
        "edges": edges, "length": length})

    # A dropping block sinks one unit a frame while something stands on it.
    heights = list(range(0x98, 0x7F, -1))
    calls = [_call(memory, SOUND_PITCH_FROM_Z, {"IX": RECORD}, {RECORD + 3: z})
             for z in heights]
    edges, length = _in_a_row(calls, quiet_frame)
    out.append({
        "name": "sinking_block", "entry": SOUND_PITCH_FROM_Z,
        "title": "A block sinking",
        "what": "#R$B451: six waves pitched by the object's height -- higher when "
                "higher. A dropping block sinking under Sabreman, a spiked ball "
                "falling, a bouncing ball, and Sabreman falling fast.",
        "how": f"{len(heights)} calls with the object's Z falling one a frame from "
               f"${heights[0]:02X} to ${heights[-1]:02X} (the floor), as a dropping "
               "block sinks, a quiet frame apart (measured in room "
               f"${MATERIALISE_ROOM:02X}, {quiet_frame:,} T-states).",
        "edges": edges, "length": length})
    return out


def _rooms(castle) -> tuple[list[dict], int]:
    """The effects recorded by running the game in a room, and the length of
    a quiet frame, for spacing the calls above."""
    out = []

    def add(name, entry, title, what, how, run, frames):
        edges, length = _window(run, *frames)
        out.append({"name": name, "entry": entry, "title": title, "what": what,
                    "how": how, "edges": edges, "length": length,
                    "frames": frames[1] - frames[0] + 1})

    run = _room_run(castle, MATERIALISE_ROOM, WALK_FRAMES[1] + 1, WALK_FROM)
    starts = run[1]
    idle = sorted(starts[f + 1] - starts[f] for f in range(IDLE_FRAMES[0], IDLE_FRAMES[1] + 1))
    quiet_frame = idle[len(idle) // 2]
    add("materialise", SOUND_MATERIALISE, "Sabreman appearing",
        "#R$B419: a rising sweep, one wave a step. Both of Sabreman's records "
        "materialise together, stepping their type from 120 to 127 every other "
        "frame (#R$BEFE), and each plays the sweep for its new type -- so every "
        "other frame the sweep sounds twice, and each pair is longer than the "
        "last. It starts every life and follows him into every room.",
        f"The game running in room ${MATERIALISE_ROOM:02X}, which has nothing in "
        "it, from the first frame to the last of the effect. The types passed are "
        "121 to 127, so the sweeps are 7, 11, 15 ... 31 steps (the type is "
        "stepped before the call, so type 120's 3 steps are never heard).",
        run, MATERIALISE_FRAMES)
    add("walking", SOUND_WALK_STEP, "Sabreman walking",
        "#R$B4BB: a footstep on every other frame of the walk cycle, alternating a "
        "fixed pitch with one from his height -- the tick-tock of two feet -- with "
        "fewer waves the further he is to the west or north.",
        f"The game running in room ${MATERIALISE_ROOM:02X} with A held (walk "
        "forward, on the keyboard) from the frame after he has appeared, as he "
        "walks from the middle of the room towards the west wall.",
        run, WALK_FRAMES)

    add("death", SOUND_SPARKLE, "Sabreman dying",
        "#R$B403: bursts of short blips pitched by bytes of the ROM from $1234. "
        "When Sabreman is killed both his records turn to sparkles (types 112-119, "
        "#R$BF21) and each plays a burst every frame, one blip shorter each frame. "
        "A crumbling block makes the same noise, briefly, as it goes.",
        f"The game running in room ${DEATH_ROOM:02X}, where he is killed as soon as "
        "he has formed, over the eight frames of the sparkle: bursts of 15 down to "
        "8 blips, twice a frame.",
        _room_run(castle, DEATH_ROOM, DEATH_FRAMES[1] + 1), DEATH_FRAMES)
    add("movable_block", SOUND_MOVABLE_BLOCK, "The movable block's buzz",
        "#R$B3E9: four waves, at one of eight pitches (#R$B3FB) chosen by the "
        "frame counter. The type 62 block plays it every frame, so a room with "
        "one has a buzz under everything else.",
        f"The game running in room ${BLOCK_ROOM:02X}, where the block is the only "
        f"thing making a noise, for {BLOCK_FRAMES[1] - BLOCK_FRAMES[0] + 1} frames "
        "(three turns of the eight pitches).",
        _room_run(castle, BLOCK_ROOM, BLOCK_FRAMES[1] + 1), BLOCK_FRAMES)
    add("sliding_block_x", SOUND_PITCH_FROM_X, "A block sliding east and west",
        "#R$B45D: six waves pitched by X. A sliding block (type 54) plays it every "
        "frame as it shuttles one unit a frame, 15 units each way; a flame moving "
        "along X uses it too. The half-wave count is four times the bottom six bits "
        "of NOT X, so the pitch climbs as X rises and drops back to the bottom "
        "every 64 units -- which this block's run crosses at X = $80, where a "
        "whine far above hearing becomes the lowest note.",
        f"The game running in room ${SLIDE_X_ROOM:02X}, whose sliding block is its "
        "only noise, for 32 frames: one shuttle there and back.",
        _room_run(castle, SLIDE_X_ROOM, SLIDE_X_FRAMES[1] + 1), SLIDE_X_FRAMES)
    add("sliding_block_y", SOUND_PITCH_FROM_Y, "A block sliding north and south",
        "#R$B462: the same, pitched by Y. A sliding block of type 55, and flames "
        "moving along Y.",
        f"The game running in room ${SLIDE_Y_ROOM:02X}, whose sliding block is its "
        "only noise, for 32 frames: one shuttle there and back.",
        _room_run(castle, SLIDE_Y_ROOM, SLIDE_Y_FRAMES[1] + 1), SLIDE_Y_FRAMES)
    add("guard", AUDIO_GUARD_WIZARD, "A guard walking",
        "#R$B4AD: the guards' and the wizard's footsteps, on every other frame of "
        "the walk cycle, their two pitches alternating the opposite way round to "
        "Sabreman's.",
        f"The game running in room ${GUARD_ROOM:02X}, which holds a guard and "
        f"spikes, for {GUARD_FRAMES[1] - GUARD_FRAMES[0] + 1} frames of the guard "
        "walking round the walls.",
        _room_run(castle, GUARD_ROOM, GUARD_FRAMES[1] + 1), GUARD_FRAMES)
    add("portcullis", SOUND_PORTCULLIS_CRASH, "A portcullis rising and crashing down",
        "#R$B467 while it rises: six waves pitched by X + Y + Z, a frame at a time "
        "as it climbs one unit a frame -- the sound charms, tables and chests make "
        "when pushed, too. Then #R$B489 as it lands: sixteen blips of two waves "
        "pitched by bytes from a random address in the ROM, so no two crashes are "
        "alike.",
        f"The game running in room ${PORTCULLIS_ROOM:02X}, whose portcullis is its "
        f"only noise, from frame {PORTCULLIS_FRAMES[0]} after arriving: its second "
        "rise, 32 frames to the top, the fall, and the crash.",
        _room_run(castle, PORTCULLIS_ROOM, PORTCULLIS_FRAMES[1] + 1), PORTCULLIS_FRAMES)
    return out, quiet_frame


# --------------------------------------------------------------------------
# The page.
# --------------------------------------------------------------------------

def _hex(address: int) -> str:
    return f"${address:04X}"


def _describe(sound: dict) -> str:
    """Length, and pitch where it has one."""
    seconds = sound["length"] / TSTATES_PER_SECOND
    length = f"{seconds * 1000:.0f} ms" if seconds < 1 else f"{seconds:.2f} s"
    periods = _periods(sound["edges"])
    detail = f"{length}, {len(sound['edges'])} edges"
    if sound.get("frames"):
        detail += f", {sound['frames']} frames"
    if periods and not sound.get("tune"):
        low, high = _hz(max(periods)), _hz(min(periods))
        if round(low) == round(high):
            detail += f", {low:.0f} Hz"
        else:
            detail += f", {low:.0f} to {high:.0f} Hz"
        if high > 20_000:
            # A half-wave count of 1 or 2 is a wave of a few dozen
            # microseconds: the game makes it, but nobody hears it, and at
            # 44100 Hz the WAV can only average it to a click.
            detail += " (the top of that is above hearing)"
    return detail


def _section(sounds: list[dict], quiet_frame: int, entries: set) -> str:
    def link(text: str) -> str:
        # #R only where the address starts an entry; otherwise plain.
        return re.sub(r"#R\$([0-9A-F]{4})",
                      lambda m: m.group(0) if int(m.group(1), 16) in entries
                      else "$" + m.group(1), text)

    lines = [
        '<div class="kl-list">',
        "<p>A 48K Spectrum has one bit of sound hardware -- bit 4 of port $FE, the "
        "speaker -- and Knight Lore makes every sound by setting and clearing it "
        "with the processor counting in between. Nothing else happens while a "
        "sound plays: the tunes and effects are timing loops, and they take the "
        "machine. Every effect comes down to #R$B4ED, which turns the speaker on "
        "for B turns of a 13 T-state loop and off for as long; #R$B4E6 repeats it "
        "C times. A half-wave count of 128 is about 1 kHz.</p>",
        "<p>A tune is a string of note bytes ended by $FF (#R$B20E). The low six bits "
        "index #R$B332, a table of five octaves of semitones from G#1 to G6, 0 being a "
        "rest; each row holds two counts that time the half-wave and the number of "
        "waves in one unit of length, scaled so a unit lasts about 0.155 s whatever "
        "the pitch. The top two bits are the length less one, one to four units. "
        "#R$B2CF plays a tune through; #R$B2BE stops at a key.</p>",
        "<p>Every recording here is the game's own code running in SkoolKit's "
        "simulator, with each change of the speaker bit logged to the T-state and "
        "rendered at 44100 Hz; nothing is synthesised. A sound made by one call was "
        "recorded by calling its routine on a machine of its own, with the values "
        "it reads set as given. A sound that is a blip a frame from something moving "
        "was recorded by running the game itself, with Sabreman put into a room "
        "where that thing is the only source of noise, so the gaps between the "
        "blips are the game's real frames. The simulator has no memory contention, "
        "so all of this runs a little faster, and sounds a little higher, than on "
        f"a real Spectrum. A quiet frame (room ${MATERIALISE_ROOM:02X}, nothing "
        f"moving) lasts {quiet_frame:,} T-states, "
        f"{quiet_frame / TSTATES_PER_SECOND * 1000:.0f} ms.</p>",
    ]
    heading = None
    for sound in sounds:
        group = "Tunes" if sound.get("tune") else "Effects"
        if group != heading:
            lines.append(f"<h3>{group}</h3>")
            heading = group
        file = f"audio/{sound['name']}.wav"
        lines += [
            f'<div class="kl-item" id="{sound["name"]}">',
            f"<h4>{_esc(sound['title'])}</h4>",
            f"<p>{link(sound['what'])}</p>",
            f"<p>Recorded: {link(sound['how'])}</p>",
            f"<p>{_describe(sound)}.</p>",
            f'<audio controls preload="none" src="{file}"><a href="{file}">'
            f"{sound['name']}.wav</a></audio>",
            "</div>",
        ]
    lines.append("</div>")
    return "\n".join(lines)


def build(memory, html_dir: Path, log=print) -> str:
    """Record every tune and effect into html_dir/audio, and return the Sounds
    section's HTML."""
    from skoolkit import read_bin_file

    audio = html_dir / "audio"
    audio.mkdir(parents=True, exist_ok=True)
    base = list(memory)
    base[:0x4000] = read_bin_file(str(kp.ROM))

    log("Recording Knight Lore's sounds...")
    castle = kp.Castle(memory)
    rooms, quiet_frame = _rooms(castle)
    sounds = _tunes(base) + _calls(base, quiet_frame) + rooms
    for sound in sounds:
        if not sound["edges"]:
            raise RuntimeError(f"{sound['name']}: no sound was made")
        _write_wav(audio / f"{sound['name']}.wav", sound["edges"], sound["length"])
    log(f"  {len(sounds)} sounds written to {audio}")
    return _section(sounds, quiet_frame, _entries())
