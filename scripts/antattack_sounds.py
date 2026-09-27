"""Ant Attack's sounds, recorded from the game's own code at build time.

build_antattack.py --html calls build(), which writes a WAV of every sound the
game makes into the HTML directory's audio/ folder and returns the Sounds
section. Nothing here is committed output: the sounds are the game's, and the
BASIC lines and messages the page quotes are read from the game at build time.

A 48K Spectrum has one bit of sound hardware, bit 4 of port $FE, and every
noise Ant Attack makes is code toggling that bit and counting. A sound is
recorded by running the code that makes it in SkoolKit's simulator with a
tracer that notes the T-state of every OUT to port $FE that changes bit 4; the
gaps between those edges are the waveform, which SkoolKit's audio writer
renders to a 16-bit mono WAV at 44100 Hz. Nothing is synthesised: every edge
in every file is an OUT the game or the ROM executed.

The machine code has exactly four OUTs to port $FE, two in TONE ($8B80) and
two in NOISE ($8B4A), and only two routines call those: RUN_SCRIPT ($8E0D),
which plays the sound bytes in a script, and HANDLE_EVENTS ($8F00), which
clicks for a footstep. The BASIC has four BEEP statements, played by the ROM.
So there are three kinds of recording:

- The BASIC's BEEPs, from one run of the game from the end of its loader
  with the key presses build_antattack's playing_machine() uses (SPACE let
  go as soon as its BEEP has played): the title screen's logo flashing and rising scale, the BEEP
  after the key on the story card, and -- on a copy of the machine once play
  has started, with the clock poked down to two ticks -- the falling run
  after "out of time". Every BEEP goes through the ROM's BEEPER, and the
  recording stops at each entry to it to read the DE and HL the ROM worked
  out from BASIC's duration and pitch, so the edges can be checked against
  them. The silences between the BEEPs are the BASIC's own: the logo being
  printed, the FOR loop going round.
- The scripts, each run by PLAY_SCRIPT ($8E02) on a copy of that machine at
  the start of play, as render_scripts() in the build runs them for their
  pictures. The game does nothing else while a script plays (PLAY runs with
  interrupts off, and the frame waits for the script to finish), so a call
  is the whole of it; the silences inside are the letters being printed and
  the play area being recoloured between the notes. The ending (script 17)
  runs through FINAL_SCRIPT ($8EF2) on the cleared screen with BORDER set to
  5, as BASIC line 3600 runs it.
- The footsteps: the game itself, on a copy of the same machine, with the
  player put on open ground and V held for a dozen frames, so the gaps
  between the clicks are the game's real frames.

The machine is uncontended, so everything here is a touch faster than on a
real Spectrum. The machine code's timing loops run in uncontended memory
above $8000 (only the OUTs themselves would be held up), so the scripts are
very close; the ROM's BEEPER also runs from the uncontended ROM.
"""
from __future__ import annotations

import html
import math
import re
from pathlib import Path

import build_antattack as ba

SKOOL = ba.OUT_DIR / "antattack.skool"
TSTATES_PER_SECOND = 3_500_000
RETURN_TRAP = 0x5B00        # a return address nothing else executes (the
CALL_STACK = 0x5B80         # printer buffer), as build_antattack.call_routine
CALL_LIMIT = 60 * TSTATES_PER_SECOND
RUN_LIMIT = 120 * TSTATES_PER_SECOND

# The machine code's sound (see their entries).
NOISE = 0x8B4A
NOISE_OUTS = (0x8B58, 0x8B5D)      # the random bit; the speaker left on at the end
TONE = 0x8B80
TONE_OUTS = (0x8BA6, 0x8BAE)       # each half-wave; the speaker off at the end
TONES = 0x8BB1                     # 16 notes: pitch delay E, then half-waves B
NOTE_COUNT = 16
NOISE_NOTE = 0x0F                  # RUN_SCRIPT plays note $0F as noise
TONE_LOOP = 14                     # DEC A (4) + JP NZ (10), E times a half-wave
TONE_OVERHEAD = 84                 # the rest of a half-wave: LD A,E, ten NOPs,
                                   # LD A,C, XOR, LD C,A, OUT, DEC B, JP NZ
PLAY_SCRIPT = 0x8E02
RUN_SCRIPT = 0x8E0D
FINAL_SCRIPT = 0x8EF2
HANDLE_EVENTS = 0x8F00
NOISE_STEP = 194                   # a random bit: CALL RANDOM (17), RANDOM (142),
                                   # AND (7), XOR (4), OUT (11), DJNZ (13)
NOISE_LAST = 23                    # OUT (11), DJNZ falling through (8), LD A,C (4)
CLICK_LENGTH = 5                   # the B HANDLE_EVENTS passes NOISE for a step
NOISE_LENGTH = 256                 # the B RUN_SCRIPT passes it (B = 0)
PRINT_COUNTERS = 0x81E4
GAME_FRAME = 0x8E80
BORDER = 0xB42C
ENDING_BORDER = 5                  # BASIC line 3600 POKEs this before the ending
SCRIPT_COUNT = ba.SCRIPT_COUNT
TIME = ba.TIME                     # the clock, two bytes big-endian

# The ROM.
BEEPER = 0x03B5
# A half-wave of BEEPER, OUT to OUT, counted from its instructions: 60 T-states
# after the OUT on the way that counts DE down, or 44 plus one more 16 T-state
# turn of the inner loop (its INC C) on the other, so both halves match; then
# L AND 3 NOPs, INC B and INC C (8), the inner DEC C / JR NZ loop run L/4 + 1
# times (16 each, 5 fewer for the last), H more passes of 63 turns with their
# LD C / DEC B / JP NZ (21 each, 1024 a pass in all), and XOR and OUT (18).
# That comes to 4 * HL + 118.
BEEPER_HALF = 4
BEEPER_OVERHEAD = 118
GIRL_OR_BOY = 0x8090               # USR 32912: BASIC is asking girl or boy

# When each script plays, and what plays it: prose for the page, read from the
# callers (see each routine's entry).
SCRIPT_WHEN = {
    1: "The player lands after falling for five frames or more: #R$8860 records a "
       "bad fall in the player's event byte, and #R$8F00 plays this through #R$8E00.",
    2: "The same for the rescued person: #R$8F00.",
    3: "A grenade's blast kills an ant: #R$8FD0, from bit 2 of #R$B42D. Notes, "
       "noise, and the play area flashing through colours (#R$8B00) around the words.",
    4: "A grenade is thrown: #R$8FD0 (bit 0 of #R$B42D) plays it to reprint the "
       "count. #R$81E4 plays it too, at the start of every call of #R$8000 -- so the "
       "same blip sounds twice as each level begins, once as the city is drawn behind "
       "the ready prompt and once as play starts.",
    5: "A grenade goes off: #R$8FD0 (bit 1 of #R$B42D). Four bursts of noise, the "
       "only sound a grenade makes.",
    6: "The player is caught in their own blast: #R$8F00 sets their energy to 0 and "
       "plays this.",
    7: "An ant bites the player, taking a point of energy: #R$8F00.",
    9: "The rescued person is caught in the player's blast: #R$8F00.",
    10: "An ant bites the rescued person: #R$8F00.",
    12: "The player comes within three cells of the person waiting, at the same "
        "height: #R$8F80. The letters are typed out between the notes, so the tune "
        "and the message arrive together.",
    13: "The player and the rescued person are both outside the walls: #R$8EA0. "
        "Towards the end the play area is refilled in a new colour (#R$8B00) before "
        "each run of notes as the scale climbs.",
    14: "An ant bites the player's last point of energy away: #R$8F00.",
    15: "An ant bites the rescued person's last point of energy away: #R$8F00.",
    16: "The player lands on top of an ant that is neither exploding nor already "
        "paralysed, and #R$8BD1 paralyses it for good.",
    17: "The tenth rescue: BASIC line 3600 clears the screen (line 2000, which also "
        "sets BORDER 5), POKEs 5 into #R$B42C to match, and calls #R$8EF2 (USR 36594). "
        "The whole tribute types itself out a letter or two a note.",
}

# What to call the scripts that print no words.
SCRIPT_UNWORDED = {4: "a grenade thrown", 5: "a grenade going off",
                   8: "the player's energy", 11: "the rescued person's energy"}

# The BASIC's BEEPs: line, what BASIC passes (seconds, semitones above middle
# C), described in the page in words and checked against the ROM's DE and HL.
TITLE_LINE, SCALE_LINE, KEY_LINE, TIMEOUT_LINE = 3110, 3120, 960, 3220
TITLE_BEEPS = [(0.05, 1)] * 4 + [(0.05, 0)] * 4      # INT (i/4), i from 7 to 0...
TITLE_REPEATS = 5                                     # ...five times over
SCALE_BEEPS = [(0.02, p) for p in range(0, 61, 3)]
KEY_BEEPS = [(0.01, 40)]
TIMEOUT_BEEPS = [(0.2, p) for p in range(40, -1, -3)]
TIMEOUT_TICKS = 2          # the clock poked down to this, to reach the end quickly
MIDDLE_C = 440 * 2 ** (-9 / 12)

# The footsteps.
WALK_FRAMES = 12
FACING_X_UP = 1            # the player's facing at +4, as _good_shot sets it
MOVE_KEY = "v"


def _esc(text: str) -> str:
    return html.escape(text, quote=False)


# --------------------------------------------------------------------------
# The listing: which addresses #R can link to, and the BASIC lines.
# --------------------------------------------------------------------------

def _skool_lines() -> list[str]:
    return SKOOL.read_text(encoding="utf-8").splitlines() if SKOOL.exists() else []


def _entries(lines: list[str]) -> set:
    """The addresses that start an entry in the listing, the only ones #R can
    link to."""
    found = set()
    for line in lines:
        m = re.match(r"^[bcgistuw]\$([0-9A-F]{4})", line)
        if m:
            found.add(int(m.group(1), 16))
    return found


def _basic_lines(lines: list[str]) -> dict[int, tuple[int, str]]:
    """Each BASIC line's entry address and listing, from the skool, where the
    build writes every line as a block titled "BASIC line N" whose
    description is the line itself."""
    found, title, text, capturing = {}, None, [], False
    for line in lines:
        m = re.match(r"^; BASIC line (\d+)$", line)
        if m:
            title, text, capturing = int(m.group(1)), [], True
            continue
        if title is None:
            continue
        if capturing and line.startswith(";"):
            body = line[1:].strip()
            if body and body != ".":
                text.append(body)
            continue
        if line.startswith("@"):
            continue
        m = re.match(r"^[bcgistuw]\$([0-9A-F]{4})", line)
        if m:
            found[title] = (int(m.group(1), 16), " ".join(text))
        title, capturing = None, False
    return found


# --------------------------------------------------------------------------
# The machine and its speaker.
# --------------------------------------------------------------------------

def _tracer_class():
    """The build's key-reading tracer, logging every OUT to the ULA as well."""
    from skoolkit.simutils import B, E, PC, T

    base = ba._key_tracer_class()

    class SoundTracer(base):
        def __init__(self, simulator, speaker=0):
            super().__init__(simulator)
            self.write_port = self._out
            self.speaker = speaker
            # (T-state, PC, value, B, E) for every OUT to port $FE, and the
            # T-state of every one that changed the speaker bit.
            self.outs = []
            self.edges = []

        def _out(self, registers, port, value, *rest):
            if port & 1 == 0:
                t = registers[T]
                self.outs.append((t, registers[PC], value, registers[B], registers[E]))
                if value & 0x10 != self.speaker:
                    self.speaker = value & 0x10
                    self.edges.append(t)

    return SoundTracer


def _simulator(memory, registers=None, speaker=0):
    from skoolkit import CSimulator
    from skoolkit.simulator import Simulator

    simulator = (CSimulator or Simulator)(list(memory), state={"iff": 0, "im": 1, "tstates": 0})
    if registers is not None:
        for index, value in enumerate(registers):
            simulator.registers[index] = value
    tracer = _tracer_class()(simulator, speaker)
    simulator.set_tracer(tracer)
    return simulator, tracer


def _trace(simulator, stop: int, limit: int, what: str) -> None:
    from skoolkit.simutils import PC, T

    simulator.trace(simulator.registers[PC], stop, 0, simulator.registers[T] + limit,
                    True, None, None, None, None, None)
    if simulator.registers[PC] != stop:
        raise RuntimeError(f"{what}: stopped at ${simulator.registers[PC]:04X}, "
                           f"not ${stop:04X}")


def _run_for(simulator, tracer, keys, seconds: float) -> None:
    from skoolkit.simutils import PC, T

    tracer.keys = set(keys)
    simulator.trace(simulator.registers[PC], -1, 0,
                    simulator.registers[T] + int(seconds * TSTATES_PER_SECOND),
                    True, None, None, None, None, None)


def _beeps(simulator, tracer, count: int, what: str) -> list[dict]:
    """Run on through `count` calls of the ROM's BEEPER: each call's DE and HL,
    and where it began and ended."""
    from skoolkit.simutils import D, E, H, L, SP, T

    calls = []
    for _ in range(count):
        _trace(simulator, BEEPER, RUN_LIMIT, what)
        r, m = simulator.registers, simulator.memory
        back = m[r[SP]] | m[r[SP] + 1] << 8
        call = {"start": r[T], "DE": r[D] << 8 | r[E], "HL": r[H] << 8 | r[L]}
        _trace(simulator, back, RUN_LIMIT, what)
        call["end"] = r[T]
        calls.append(call)
    return calls


# --------------------------------------------------------------------------
# Recording.
# --------------------------------------------------------------------------

def _window(tracer, t0: int, t1: int) -> tuple[list[int], list[tuple]]:
    """The edges and OUTs from t0 up to t1, measured from t0."""
    edges = [t - t0 for t in tracer.edges if t0 <= t < t1]
    outs = [(t - t0, *rest) for t, *rest in tracer.outs if t0 <= t < t1]
    return edges, outs


def _basic(snapshot: Path) -> tuple[list[dict], object, dict]:
    """The title screen's two runs of BEEPs, the story card's, and the
    machine at the start of play (registers, memory) for everything else."""
    from skoolkit import read_bin_file
    from skoolkit.simutils import PC, SP, T

    memory = list(ba.game_memory(snapshot))
    memory[:0x4000] = read_bin_file(str(ba.ROM))
    simulator, tracer = _simulator(memory)
    simulator.registers[SP] = ba.LOADER_STACK
    simulator.registers[PC] = ba.PAST_LOAD_CHECKS

    out = []
    title = _beeps(simulator, tracer, len(TITLE_BEEPS) * TITLE_REPEATS, "the title")
    scale = _beeps(simulator, tracer, len(SCALE_BEEPS), "the title's scale")
    _trace(simulator, GIRL_OR_BOY, RUN_LIMIT, "the girl-or-boy question")
    # The title recording runs to where the scale begins, so it ends with the
    # last redraw of the logo; the scale's ends with its last BEEP.
    out.append(_basic_sound(tracer, "title", "The title screen's logo", TITLE_LINE, title,
                            TITLE_BEEPS * TITLE_REPEATS, title[0]["start"], scale[0]["start"]))
    out.append(_basic_sound(tracer, "title_scale", "The title screen's scale", SCALE_LINE,
                            scale, SCALE_BEEPS, scale[0]["start"], scale[-1]["end"]))

    # On as the build's playing_machine() goes: B for boy, then the story card,
    # whose key is followed by line 960's BEEP.
    steps = ba._start("b")
    first_after = None
    for keys, seconds in steps[1:]:
        if keys == ["SPACE"] and first_after is None:
            tracer.keys = {"SPACE"}
            key = _beeps(simulator, tracer, len(KEY_BEEPS), "the story card's key")
            first_after = key
            out.append(_basic_sound(tracer, "any_key", "A key pressed on a card", KEY_LINE,
                                    key, KEY_BEEPS, key[0]["start"], key[-1]["end"]))
            continue
        _run_for(simulator, tracer, keys, seconds)
    tracer.keys = set()
    playing = (list(simulator.registers), list(simulator.memory), tracer.speaker)
    # What sounded between the story card's key and the start of play: the
    # two calls of PLAY (lines 700 and 720) each print the counters.
    since = [o for o in tracer.outs if o[0] >= first_after[-1]["end"]]
    level_start = {"notes": sum(1 for o in since if o[1] == TONE_OUTS[1]),
                   "tone_outs": sum(1 for o in since if o[1] in TONE_OUTS),
                   "clicks": sum(1 for o in since if o[1] == NOISE_OUTS[1]),
                   "rom_outs": sum(1 for o in since if o[1] < 0x4000),
                   "rom_speaker": any(o[2] & 0x10 for o in since if o[1] < 0x4000),
                   "other_outs": sum(1 for o in since if o[1] not in TONE_OUTS + NOISE_OUTS
                                     and o[1] >= 0x4000),
                   "delays": sorted({o[4] or 256 for o in since if o[1] == TONE_OUTS[0]})}

    # Out of time: the clock nearly run down on a copy, then on until the
    # BEEPs of line 3220 have all played.
    registers, memory, speaker = playing
    memory = list(memory)
    memory[TIME:TIME + 2] = [0, TIMEOUT_TICKS]
    simulator, tracer = _simulator(memory, registers, speaker)
    timeout = _beeps(simulator, tracer, len(TIMEOUT_BEEPS), "running out of time")
    out.append(_basic_sound(tracer, "out_of_time", "Out of time", TIMEOUT_LINE, timeout,
                            TIMEOUT_BEEPS, timeout[0]["start"], timeout[-1]["end"]))
    return out, playing, level_start


def _basic_sound(tracer, name, title, line, calls, asked, t0, t1) -> dict:
    edges, outs = _window(tracer, t0, t1)
    # Each call's edges on their own, for its pitch.
    groups = [[t - t0 for t in tracer.edges if c["start"] <= t < c["end"]] for c in calls]
    return {"name": name, "title": title, "kind": "basic", "line": line, "calls": calls,
            "asked": asked, "edges": edges, "outs": outs, "groups": groups,
            "length": t1 - t0}


def _scripts(playing) -> list[dict]:
    """Every script, called on its own copy of the machine at the start of play."""
    from skoolkit.simutils import A, PC, SP, T

    registers, base, _ = playing
    out = []
    for number in range(1, SCRIPT_COUNT + 1):
        memory = list(base)
        entry = PLAY_SCRIPT
        if number == SCRIPT_COUNT:
            # As BASIC line 3600 runs it: GO SUB 2000 clears the screen to
            # PAPER 6, BORDER 5 is poked into BORDER, and FINAL_SCRIPT is
            # called (build_antattack.render_scripts clears it the same way).
            memory[0x4000:0x5800] = [0] * 0x1800
            memory[0x5800:0x5B00] = [0x30] * 0x300
            memory[BORDER] = ENDING_BORDER
            entry = FINAL_SCRIPT
        memory[CALL_STACK:CALL_STACK + 2] = [RETURN_TRAP & 0xFF, RETURN_TRAP >> 8]
        # The speaker starts off, as every TONE and BEEP leaves it.
        simulator, tracer = _simulator(memory, registers, 0)
        simulator.registers[SP] = CALL_STACK
        simulator.registers[A] = number
        simulator.registers[PC] = entry
        start = simulator.registers[T]
        _trace(simulator, RETURN_TRAP, CALL_LIMIT, f"script {number}")
        length = simulator.registers[T] - start
        edges, outs = _window(tracer, start, start + length + 1)
        borders = sorted({value & 7 for _, pc, value, _, _ in outs})
        out.append({"name": f"script{number:02d}", "number": number, "kind": "script",
                    "edges": edges, "outs": outs, "length": length, "borders": borders})
    return out


def _footsteps(playing) -> dict:
    """The game running with the player walking across open ground."""
    from skoolkit.simutils import PC, T

    registers, base, speaker = playing
    memory = list(base)
    x, y = ba._open_ground(memory)
    memory[ba.PLAYER:ba.PLAYER + 3] = [x, y + 5, 0]
    memory[ba.PLAYER + 4] = FACING_X_UP
    simulator, tracer = _simulator(memory, registers, speaker)
    # To the start of a frame, then V held for the frames recorded.
    _trace(simulator, GAME_FRAME, RUN_LIMIT, "the first frame")
    tracer.keys = {MOVE_KEY}
    starts = []
    for frame in range(WALK_FRAMES):
        starts.append(simulator.registers[T])
        _trace(simulator, GAME_FRAME, RUN_LIMIT, f"frame {frame}")
    starts.append(simulator.registers[T])
    t0, t1 = starts[0], starts[-1]
    edges, outs = _window(tracer, t0, t1)
    frames = []
    for f in range(len(starts) - 1):
        a, b = starts[f] - t0, starts[f + 1] - t0
        frames.append(len([o for o in outs if a <= o[0] < b]))
    return {"name": "footsteps", "kind": "footsteps", "edges": edges, "outs": outs,
            "length": t1 - t0, "frames": frames, "start": (x, y + 5),
            "end": tuple(simulator.memory[ba.PLAYER:ba.PLAYER + 2]),
            "frame_lengths": [starts[f + 1] - starts[f] for f in range(len(starts) - 1)]}


# --------------------------------------------------------------------------
# What the code says each sound should be.
# --------------------------------------------------------------------------

def _notes(memory) -> list[dict]:
    """The note table, and what TONE makes of each entry."""
    notes = []
    for n in range(NOTE_COUNT):
        delay = memory[TONES + 2 * n] or 256          # DEC A from 0 goes round 256 times
        halves = memory[TONES + 2 * n + 1]
        half = TONE_LOOP * delay + TONE_OVERHEAD
        hz = TSTATES_PER_SECOND / (2 * half)
        notes.append({"n": n, "E": delay, "B": halves, "half": half, "hz": hz,
                      "ms": halves * half / TSTATES_PER_SECOND * 1000})
    return notes


def _script_sounds(memory, address: int) -> list[tuple[int, int]]:
    """The sound bytes of the script at `address`, as (note, times), in the
    order RUN_SCRIPT plays them: past the stream byte, stepping over AT's two
    operands and the one operand of a colour, $7D and $7E."""
    out = []
    address += 1
    while memory[address] != 0xFF:
        byte = memory[address]
        address += 1
        if byte & 0x80:
            out.append((byte & 0x0F, (byte >> 4 & 7) + 1))
        elif byte in (0x16, 0x17):
            address += 2
        elif 0x10 <= byte <= 0x15 or byte in (0x7D, 0x7E):
            address += 1
    return out


def _expected_script(sounds, notes) -> dict:
    """The OUTs and edges RUN_SCRIPT should make of a script's sound bytes.

    TONE starts from the border with the speaker bit set, but flips it before
    its first OUT, so its first OUT turns the speaker off: an edge only if the
    speaker was on. Each of the other B - 1 half-waves is an edge, and the OUT
    after the loop, speaker off, is one more when B is even (the last half-wave
    left it on). NOISE's edges depend on the random bits; its OUTs do not: B
    random ones and one more, speaker on, at the end.
    """
    outs = edges = 0
    speaker = 0
    tone_outs = noise_outs = 0
    for note, times in sounds:
        for _ in range(times):
            if note == NOISE_NOTE:
                noise_outs += NOISE_LENGTH + 1
                speaker = 1
            else:
                b = notes[note]["B"]
                tone_outs += b + 1
                edges += speaker + (b - 1) + (1 if b % 2 == 0 else 0)
                speaker = 0
    return {"tone_outs": tone_outs, "noise_outs": noise_outs, "tone_edges": edges,
            "notes": sorted({note for note, _ in sounds if note != NOISE_NOTE}),
            "noise": sum(times for note, times in sounds if note == NOISE_NOTE),
            "count": sum(times for _, times in sounds)}


def _tone_periods(outs) -> dict[int, list[int]]:
    """Every whole wave TONE played, by its pitch delay E: the time from one
    of its half-wave OUTs to the next but one, within one note (B counts down
    by one each OUT, so a note ends where B goes back up)."""
    by_delay: dict[int, list[int]] = {}
    run = []
    for t, pc, value, b, e in outs:
        if pc != TONE_OUTS[0]:
            run = []
            continue
        if run and b != run[-1][1] - 1:
            run = []
        run.append((t, b, e or 256))
        if len(run) >= 3:
            by_delay.setdefault(run[-1][2], []).append(run[-1][0] - run[-3][0])
    return by_delay


def _periods(edges) -> list[int]:
    """Whole waves (edge to next-but-one edge)."""
    return [edges[i + 2] - edges[i] for i in range(len(edges) - 2)]


def _all(count: int, of: list) -> str:
    """' in all 21', ' in 19 of the 21', and for a single case '' or ' (not so)'."""
    if len(of) == 1:
        return "" if count == 1 else " (not so)"
    if count == len(of):
        return f" in all {count}"
    return f" in {count} of the {len(of)}"


def _n(count: int, word: str) -> str:
    return f"{count} {word}" + ("" if count == 1 else "s")


def _hz(tstates: float) -> float:
    return TSTATES_PER_SECOND / tstates


def _note_name(hz: float) -> str:
    """The nearest equal-tempered note, and how far off, in cents."""
    names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    semis = 12 * math.log2(hz / 440) + 69
    nearest = round(semis)
    cents = round((semis - nearest) * 100)
    name = f"{names[nearest % 12]}{nearest // 12 - 1}"
    if cents == 0:
        return name
    return f"{abs(cents)} cents {'above' if cents > 0 else 'below'} {name}"


# --------------------------------------------------------------------------
# Writing.
# --------------------------------------------------------------------------

def _write_wav(path: Path, edges, length: int) -> None:
    """Render the speaker edges to a WAV. SkoolKit's writer takes the gaps
    between flips, starting from the speaker off: the first gap is the quiet
    before the first edge, the last the quiet after the final one."""
    from skoolkit.audio import BeeperOptions
    from skoolkit.components import get_audio_writer

    delays = [edges[0]] + [b - a for a, b in zip(edges, edges[1:])]
    if length > edges[-1]:
        delays.append(length - edges[-1])
    delays = [max(d, 1) for d in delays]
    with open(path, "wb") as f:
        get_audio_writer().write_audio(f, delays, BeeperOptions(100, False, False, 0, False))


def _length(tstates: int) -> str:
    seconds = tstates / TSTATES_PER_SECOND
    return f"{seconds * 1000:.0f} ms" if seconds < 1 else f"{seconds:.2f} s"


def _range(values: list[float]) -> str:
    low, high = min(values), max(values)
    if round(low) == round(high):
        return f"{low:.0f} Hz"
    return f"{low:.0f} to {high:.0f} Hz"


# --------------------------------------------------------------------------
# The page.
# --------------------------------------------------------------------------

class _Page:
    def __init__(self, entries: set):
        self.entries = entries

    def link(self, text: str) -> str:
        """#R only where the address starts an entry; otherwise plain."""
        def one(m):
            if int(m.group(1), 16) in self.entries:
                return m.group(0)
            return m.group(2)[1:-1] if m.group(2) else "$" + m.group(1)
        return re.sub(r"#R\$([0-9A-F]{4})(\([^()]*\))?", one, text)


def _item(page, name, title, paragraphs, stats) -> list[str]:
    file = f"audio/{name}.wav"
    lines = [f'<div id="{name}" style="margin:1.2em 0;padding-bottom:0.8em;'
             'border-bottom:1px solid silver">',
             f"<h4>{title}</h4>"]
    lines += [f"<p>{page.link(p)}</p>" for p in paragraphs]
    lines.append(f"<p>{stats}</p>")
    lines.append(f'<audio controls preload="none" src="{file}"><a href="{file}">'
                 f"{name}.wav</a></audio>")
    lines.append("</div>")
    return lines


def _basic_item(page, sound, basic) -> list[str]:
    """One BASIC sound: its line, what the ROM was asked for and made."""
    line = sound["line"]
    address, text = basic.get(line, (None, ""))
    where = f"#R${address:04X}(BASIC line {line})" if address is not None else f"BASIC line {line}"
    calls, asked = sound["calls"], sound["asked"]
    if "#" in text:
        raise RuntimeError(f"BASIC line {line} has a # the page would read as a macro")
    quoted = f"<code>{_esc(text)}</code>" if text else ""

    # What the ROM made of BASIC's numbers: DE is the number of whole waves
    # less one, and HL is the ROM's 437500/f - 30.125, both rounded.
    worked = 0
    for call, (seconds, pitch) in zip(calls, asked):
        f = MIDDLE_C * 2 ** (pitch / 12)
        if (call["DE"] == round(f * seconds) - 1
                and call["HL"] == round(437500 / f - 30.125)):
            worked += 1
    # What each call played: its edges, and every half-wave's length.
    edges_ok = halves_ok = 0
    worst = 0.0
    measured = []
    for call, group, (seconds, pitch) in zip(calls, sound["groups"], asked):
        if len(group) == 2 * (call["DE"] + 1):
            edges_ok += 1
        if all(b - a == BEEPER_HALF * call["HL"] + BEEPER_OVERHEAD
               for a, b in zip(group, group[1:])):
            halves_ok += 1
        periods = _periods(group)
        hz = _hz(sum(periods) / len(periods))
        measured.append(hz)
        worst = max(worst, abs(1200 * math.log2(hz / (MIDDLE_C * 2 ** (pitch / 12)))))
    pitches = sorted({p for _, p in asked})
    asked_hz = [MIDDLE_C * 2 ** (p / 12) for p in pitches]
    total_edges = sum(2 * (c["DE"] + 1) for c in calls)

    what = {
        "title": f"{where}, at the title screen: the logo is "
                 f"printed eight times over in inks 7 down to 0, five times round, and "
                 f"each printing is preceded by a BEEP of 0.05 s -- pitch 1 (C#4) for "
                 f"the first four inks and 0 (middle C) for the last four, from "
                 f"<code>INT (i/4)</code>. {len(calls)} BEEPs; the silences between are "
                 f"the logo being printed.",
        "title_scale": f"{where}, straight after: "
                       f"{len(calls)} BEEPs of 0.02 s climbing from middle C in steps of "
                       f"three semitones (a diminished-seventh arpeggio) to pitch 60, five "
                       f"octaves up, before the girl-or-boy question appears.",
        "any_key": f"{where}, the end of every story card and score "
                   f"card: #R$8097 waits for a key, then one BEEP of 0.01 s at pitch 40 "
                   f"(E7). Recorded after the key on the first story card.",
        "out_of_time": f"{where}, the end of the \"out of time\" card "
                       f"(lines 3200-3220, reached from line 60 when the clock at "
                       f"#R$B436 reads 0): {len(calls)} BEEPs of 0.2 s falling from pitch "
                       f"40 to 1, three semitones at a time.",
    }[sound["name"]]
    how = {
        "title": "The game run from the end of its loader with the key presses the "
                 "build's playing_machine() uses, from the first BEEP of the title to the "
                 "first of the scale.",
        "title_scale": "The same run, from the scale's first BEEP to the end of its last.",
        "any_key": "The same run, on through \"b\" for boy to the first story card, and "
                   "SPACE pressed there; from the entry to BEEPER to its return.",
        "out_of_time": f"A copy of the same run once play has started, with the clock at "
                       f"#R$B436 poked down to {TIMEOUT_TICKS} (one tick is three frames) "
                       "and no key held, run on until the fourteen BEEPs have played: from "
                       "the first BEEP to the end of the last. The silences are BASIC "
                       "going round its FOR loop.",
    }[sound["name"]]
    at = f"the {len(calls)} entries" if len(calls) > 1 else "the entry"
    check = (f"Checked: at {at} to the ROM's BEEPER ($03B5), read in "
             f"the simulator, DE was round(f &times; t) &minus; 1 and HL was round(437500/f "
             f"&minus; 30.125){_all(worked, calls)} -- f being middle C &times; 2<sup>p/12</sup>, t "
             f"and p the BEEP's duration and pitch, the ROM's own sums. Every call made "
             f"2(DE + 1) edges, DE + 1 whole waves{_all(edges_ok, calls)}; and every "
             f"half-wave lasted {BEEPER_HALF} &times; HL + {BEEPER_OVERHEAD} T-states, as "
             f"BEEPER's instructions imply{_all(halves_ok, calls)}. "
             f"That is {4 * 30.125 - BEEPER_OVERHEAD:.1f} T-states shorter than the "
             f"{BEEPER_HALF} &times; (HL + 30.125) the ROM's constant allows for, which, "
             f"with HL rounded, left the pitches within {worst:.1f} cents of what BASIC "
             f"asked for" + (" -- sharpest at the top, where a half-wave is only a few "
                            "hundred T-states" if worst > 5 else "") + ".")
    stats = (f"{_length(sound['length'])}, {len(sound['edges'])} edges "
             f"(2(DE + 1) summed over the calls: {total_edges}); asked "
             f"{_range(asked_hz)}, measured {_range(measured)}.")
    paragraphs = [what, f"The line: {quoted}" if quoted else "",
                  f"Recorded: {how}", check]
    return _item(page, sound["name"], sound["title"],
                 [p for p in paragraphs if p], stats)


def _script_item(page, sound, memory, notes, addresses, level_start) -> list[str]:
    number = sound["number"]
    address = addresses[number - 1]
    words = ba.script_text(memory, address)
    if "#" in words:
        raise RuntimeError(f"script {number} has a # the page would read as a macro")
    expected = _expected_script(_script_sounds(memory, address), notes)
    tone_outs = sum(1 for o in sound["outs"] if o[1] in TONE_OUTS)
    noise_outs = sum(1 for o in sound["outs"] if o[1] in NOISE_OUTS)
    other = [o for o in sound["outs"] if o[1] not in TONE_OUTS + NOISE_OUTS]
    title = f"Script {number}: " + (_esc(words) if words else SCRIPT_UNWORDED[number])
    what = SCRIPT_WHEN[number]
    how = (f"#R$8E02 called with A = {number} on a copy of the machine at the start of "
           "play, the speaker off; to its return." if number != SCRIPT_COUNT else
           "#R$8EF2 called on a copy of the machine at the start of play, with the "
           f"screen cleared to PAPER 6 and #R$B42C set to {ENDING_BORDER}, as BASIC "
           "line 3600 leaves them; to its return.")
    notes_used = expected["notes"]
    stats = f"{_length(sound['length'])}, {len(sound['edges'])} edges"
    periods = _tone_periods(sound["outs"])
    check = []
    if notes_used:
        hz_expected = [notes[n]["hz"] for n in notes_used]
        hz_measured = [_hz(sum(v) / len(v)) for v in periods.values()]
        stats += (f"; notes {', '.join(str(n) for n in notes_used)}: "
                  f"{_range(hz_expected)} from the table, {_range(hz_measured)} measured")
        exact = all(p == 2 * (TONE_LOOP * e + TONE_OVERHEAD)
                    for e, v in periods.items() for p in v)
        tone_edges = _tone_edge_count(sound)
        check.append(
            f"TONE made {tone_outs} OUTs (the script's notes imply "
            f"{expected['tone_outs']}: B + 1 each) and {tone_edges} edges (implied "
            f"{expected['tone_edges']}); every whole wave measured "
            + ("was exactly" if exact else "was NOT always")
            + f" 2(14E + 84) T-states for its note's E")
    if expected["noise"]:
        stats += (f"; {expected['noise']} burst{'s' if expected['noise'] > 1 else ''} "
                  "of noise")
        check.append(f"NOISE made {noise_outs} OUTs (implied {expected['noise_outs']}: "
                     f"257 a burst), " + _noise_spacing(sound["outs"])
                     + "; its edges depend on the random bits")
    if other:
        check.append(f"{len(other)} OUTs came from elsewhere")
    if number == 4:
        seen = level_start
        check.append(
            f"and in the run the BASIC recordings come from, between the story card's key "
            f"and the start of play, TONE played {seen['notes']} notes "
            f"({seen['tone_outs']} OUTs) with pitch delay "
            + ", ".join(str(e) for e in seen["delays"])
            + f" (note 12's is {notes[12]['E']}); the only other sounds were "
            f"{_n(seen['clicks'], 'footstep click')} as the run's V walked the player in, "
            f"and the ROM wrote the port "
            + ("once" if seen["rom_outs"] == 1 else _n(seen["rom_outs"], "time"))
            + (" with the speaker bit clear (line 300's BORDER 0)"
               if not seen["rom_speaker"] else "")
            + ("" if not seen["other_outs"] else
               f", with {seen['other_outs']} OUTs from elsewhere"))
    if sound["borders"]:
        check.append("every OUT wrote border colour "
                     + " and ".join(str(b) for b in sound["borders"])
                     + " (bits 0-2, from #R$B42C)")
    paragraphs = [what, f"Recorded: {how}"]
    if check:
        paragraphs.append("Checked: " + "; ".join(check) + ".")
    return _item(page, sound["name"], title, paragraphs, stats + ".")


def _noise_spacing(outs) -> str:
    """Whether NOISE's OUTs came at the pace its instructions set."""
    random_gaps, last_gaps = set(), set()
    for (t0, pc0, *_), (t1, pc1, *_) in zip(outs, outs[1:]):
        if pc0 == NOISE_OUTS[0] and pc1 == NOISE_OUTS[0]:
            random_gaps.add(t1 - t0)
        elif pc0 == NOISE_OUTS[0] and pc1 == NOISE_OUTS[1]:
            last_gaps.add(t1 - t0)
    ok = random_gaps == {NOISE_STEP} and last_gaps == {NOISE_LAST}
    return (f"every random bit {NOISE_STEP} T-states after the last and the final OUT "
            f"{NOISE_LAST} after that, as its instructions imply" if ok else
            f"random bits {sorted(random_gaps)} T-states apart and the final OUT "
            f"{sorted(last_gaps)} after (implied {NOISE_STEP} and {NOISE_LAST})")


def _tone_edge_count(sound) -> int:
    """Edges made by TONE's OUTs: those at the T-state of a TONE OUT."""
    times = {o[0] for o in sound["outs"] if o[1] in TONE_OUTS}
    return sum(1 for t in sound["edges"] if t in times)


def _footsteps_item(page, sound) -> list[str]:
    clicks = [n for n in sound["frames"] if n]
    per_frame = sorted(set(sound["frames"]))
    lengths = sound["frame_lengths"]
    noise_outs = sum(1 for o in sound["outs"] if o[1] in NOISE_OUTS)
    other = [o for o in sound["outs"] if o[1] not in NOISE_OUTS]
    what = ("#R$8F00, every frame the player or the rescued person takes a step: "
            "#R$8800 sets the object's event byte (+$0F) to 1 for a step and for a "
            "short landing, and when that is all that happened to either of them "
            f"#R$8F00 calls #R$8B4A with B = {CLICK_LENGTH} -- five random speaker bits "
            "and the speaker left on, a click. A frame that also has a bite, a blast or "
            "a bad fall plays that script instead, and no click.")
    how = (f"A copy of the machine at the start of play, the player moved to open "
           f"ground (x ${sound['start'][0]:02X}, y ${sound['start'][1]:02X}, facing x "
           f"up) and V held, run frame by frame from #R$8E80; recorded over "
           f"{len(sound['frames'])} frames from the first step.")
    check = (f"Checked: {len(clicks)} of the {len(sound['frames'])} frames clicked, "
             f"each with {', '.join(str(n) for n in per_frame if n)} OUTs "
             f"(implied {CLICK_LENGTH + 1}: B random ones and one to leave the speaker "
             f"on); all {noise_outs} came from #R$8B4A"
             + (f", and {len(other)} from elsewhere" if other else "")
             + f", {_noise_spacing(sound['outs'])}. The player ended "
             f"{sound['end'][0] - sound['start'][0]} cells further along x. The frames "
             f"were {min(lengths):,} to {max(lengths):,} T-states, so "
             f"{_hz(sum(lengths) / len(lengths)):.1f} steps a second; a click itself "
             f"is over in {(CLICK_LENGTH - 1) * NOISE_STEP + NOISE_LAST:,} T-states, "
             f"{((CLICK_LENGTH - 1) * NOISE_STEP + NOISE_LAST) / 3500:.2f} ms.")
    stats = f"{_length(sound['length'])}, {len(sound['edges'])} edges."
    return _item(page, "footsteps", "A click a step", [what, f"Recorded: {how}", check],
                 stats)


def _notes_table(page, notes, heard: dict[int, list[int]]) -> list[str]:
    lines = ['<table class="default">',
             "<tr><th>Note</th><th>E</th><th>B</th><th>Half-wave</th><th>Pitch</th>"
             "<th>Semitones up</th><th>Length</th><th>Measured</th></tr>"]
    for note in notes:
        waves = heard.get(note["E"], [])
        if note["n"] == NOISE_NOTE:
            measured = "never played: noise"
        elif waves:
            measured = f"{_hz(sum(waves) / len(waves)):.1f} Hz, {len(waves):,} waves"
        else:
            measured = "not in any script"
        lines.append(f"<tr><td>{note['n']}</td><td>{note['E']}</td><td>{note['B']}</td>"
                     f"<td>{note['half']:,} T</td><td>{note['hz']:.1f} Hz</td>"
                     f"<td>{12 * math.log2(note['hz'] / notes[0]['hz']):.2f}</td>"
                     f"<td>{note['ms']:.1f} ms</td>"
                     f"<td>{measured}</td></tr>")
    lines.append("</table>")
    return lines


def _section(page, basic_sounds, scripts, footsteps, level_start, memory,
             basic_lines) -> str:
    notes = _notes(memory)
    heard: dict[int, list[int]] = {}
    for sound in scripts:
        for e, waves in _tone_periods(sound["outs"]).items():
            heard.setdefault(e, []).extend(waves)
    addresses = ba.script_addresses(memory)
    silent = [s["number"] for s in scripts if not s["edges"]]

    def bl(number: int) -> str:
        """A link to a BASIC line's entry, reading "line N"."""
        entry = basic_lines.get(number, (None, ""))[0]
        return f"#R${entry:04X}(line {number})" if entry is not None else f"line {number}"
    lines = [
        "<p>A 48K Spectrum has one bit of sound hardware, bit 4 of port $FE, and Ant "
        "Attack makes every sound by flipping it with the processor counting in between. "
        "The machine code has four OUTs to the port, two in #R$8B80 and two in #R$8B4A, "
        "and only two routines call those: #R$8E0D, which plays the sound bytes in a "
        "script, and #R$8F00, which clicks for a footstep. There is no other sound in a "
        "frame -- no sound for a thrown grenade in flight, an ant or a fall except "
        "through a script -- and while a script plays the game stands still. The BASIC "
        "adds four BEEP statements of its own, played by the ROM.</p>",
        "<p>The same port sets the border colour (bits 0-2) and the MIC output (bit 3), "
        "so an OUT that only meant to move the speaker would turn the border black. "
        "That is what #R$B42C is for: both routines start from it with bits 3 and 4 "
        "set, so the border stays whatever BASIC made it. BASIC sets it to 0 for play "
        f"(it is one of the variables from #R$B420 on that {bl(200)} POKEs from DATA, "
        "to go with "
        f"{bl(300)}'s BORDER 0) and to 5 before the ending ({bl(3600)}, to go with "
        f"{bl(2000)}'s BORDER 5); each recording below says which colour its OUTs "
        "wrote.</p>",
        "<p>#R$8B80 plays one entry of #R$8BB1: a pitch delay E and a count of "
        "half-waves B. Each half-wave is E turns of a 14 T-state loop (DEC A, JP NZ) "
        f"and {TONE_OVERHEAD} T-states more, the ten NOPs among them; E = 0 goes round "
        "256 times. B rises as the pitch does, so every note lasts about 39 ms. The "
        f"table is a chromatic scale, a semitone a step from {notes[0]['hz']:.0f} Hz "
        f"({_note_name(notes[0]['hz'])}) to {notes[14]['hz']:.0f} Hz "
        f"({_note_name(notes[14]['hz'])}), tuned to itself rather than to concert "
        "pitch. TONE's first OUT turns the speaker off. After another note or a BEEP it "
        "is off already, so the note begins with a half-wave of silence; after a burst "
        "of noise, which leaves it on, that first OUT is an edge. Note 15 is never played as a "
        "note: #R$8E0D takes it as noise, 256 turns of #R$8B4A. Its speaker bit is bit 4 "
        "of what #R$8360 leaves in A, not the carry #R$8360 returns: that is bit 2 of the "
        "generator's first byte (#R$B428) as it was before the step, the carry being clear "
        "on entry as it always is in #R$8B4A -- checked by running #R$8360 for all 256 "
        f"values of that byte. So a burst sets the speaker to a new random bit every "
        f"{NOISE_STEP} T-states, some {TSTATES_PER_SECOND // NOISE_STEP:,} a second: a "
        "hiss.</p>",
    ]
    lines += _notes_table(page, notes, heard)
    lines += [
        "<p>Pitch and half-wave are worked out from the table and the loop's T-states; "
        "Measured is from the recordings of all the scripts below, every whole wave "
        "timed from the OUT that started it to the next but one.</p>",
        "<p>A script's sound bytes are $80-$FE: bits 0-3 the note, bits 4-6 one less "
        "than how many times to play it. They sit among the letters of its message, so "
        "#R$8E0D prints a letter, plays a note, prints the next -- and a message types "
        "itself out to its own tune. See the #LINK(Scripts)(scripts page) for what each "
        "one says.</p>",
        "<p>Every recording here is the game's own code, or the ROM's, running in "
        "SkoolKit's simulator, with the T-state of each change of the speaker bit "
        "logged and rendered as 16-bit mono at 44100 Hz; nothing is synthesised. The "
        "simulated machine is uncontended; the machine code's loops are in uncontended "
        "memory anyway, so only the OUTs would be held up on a real Spectrum, by a few "
        "T-states each. Each recording says how its sound was checked against what the "
        "code implies.</p>",
        "<h3>The scripts</h3>",
    ]
    if silent:
        lines.append("<p>Scripts " + " and ".join(str(n) for n in silent)
                     + " have no sound bytes: they only reprint a number on the panel, and "
                     "are left out.</p>")
    for sound in scripts:
        if sound["edges"]:
            lines += _script_item(page, sound, memory, notes, addresses, level_start)
    lines.append("<h3>Footsteps</h3>")
    lines += _footsteps_item(page, footsteps)
    lines.append("<h3>BASIC's BEEPs</h3>")
    lines.append("<p>Played by the ROM's BEEP command (#R$03B5 is its BEEPER) from the "
                 "game's own BASIC, run in the simulator: the recordings are the ROM "
                 "working from the numbers BASIC gives it, not a reconstruction.</p>")
    for sound in basic_sounds:
        lines += _basic_item(page, sound, basic_lines)
    body = "\n".join(lines)
    # Any other mention of a BASIC line by number links to its entry.
    body = re.sub(r"(?<!\()BASIC line (\d+)",
                  lambda m: "BASIC " + bl(int(m.group(1))), body)
    body = page.link(body)
    for line in body.splitlines():
        if line.startswith((";", "[")):
            raise RuntimeError(f"a section line starts with {line[0]!r}: {line[:40]}")
    return body


def build(snapshot: Path, html_dir: Path, log=print) -> dict[str, str]:
    """Record every sound into html_dir/audio, and return the Sounds section."""
    audio = html_dir / "audio"
    audio.mkdir(parents=True, exist_ok=True)
    memory = ba.game_memory(snapshot)
    skool = _skool_lines()
    page = _Page(_entries(skool))

    log("Recording Ant Attack's sounds...")
    basic_sounds, playing, level_start = _basic(snapshot)
    scripts = _scripts(playing)
    footsteps = _footsteps(playing)
    written = 0
    for sound in basic_sounds + scripts + [footsteps]:
        if not sound["edges"]:
            continue
        edges = list(sound["edges"])
        if len(edges) % 2:
            # Left on: NOISE leaves the speaker on at the end of a burst, and the
            # next note's first OUT turns it off. The WAV turns it off where the
            # recording ends, rather than hold it on to the end of the file.
            edges.append(sound["length"])
        _write_wav(audio / f"{sound['name']}.wav", edges, sound["length"])
        written += 1
    log(f"  {written} sounds written to {audio}")
    return {"Sounds": _section(page, basic_sounds, scripts, footsteps, level_start, memory,
                               _basic_lines(skool))}
