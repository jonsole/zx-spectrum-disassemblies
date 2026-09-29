"""Fairlight's sounds, recorded from the game's own code at build time.

build_fairlight.py --html calls build(), which writes a WAV of every sound
the game makes into the HTML directory's audio/ folder, draws the pictures
that explain them into images/sounds/, and returns the Sounds section.
Nothing here is committed output: the sounds, the notes and the pictures are
the game's.

A 48K Spectrum has one bit of sound hardware, bit 4 of port $FE, and a sound
is the program setting and clearing it with the processor counting in
between. So a sound is recorded by running the code that makes it in
SkoolKit's simulator with a tracer that notes the T-state of every OUT to an
even port that changes bit 4. Nothing is synthesised: every edge in every
file is an OUT the game executed.

What there is to record is short. The listing has three OUT instructions,
all in the loading tune's player (#R$C049), and the build's nine play
sessions -- half an hour of emulated play -- are run here again with every
OUT logged, to show that nothing else ever writes the port. So the page is:

- The loading tune, whole: the game run from its first instruction ($C47C)
  with no key pressed, a note at a time from TUNE_PLAY_NOTE's start to the
  next, until the notes left are all rests in both voices. Each note is
  checked edge by edge against a model of the player's loop worked out from
  its instruction timings (note_edges): where every OUT falls, and which of
  them change the speaker.
- The two voices on their own: the same run with the other voice's notes
  poked to rests, the opening only.
- The loader's warble: the Alkatraz loader's failure routine, which the
  snapshot keeps but a good load never runs, called on a machine of its own
  and checked against the ROM's BEEPER timing.

The WAVs are rendered here rather than by SkoolKit's writer, which averages
the speaker over each sample's 79 T-states: the tune switches the speaker
between its two voices every 48 T-states, and that 36 kHz switching, sampled
at 44100 Hz, folds back as a faint hiss around 7.5 kHz that no Spectrum
makes (on the opening notes, about 7 dB more there than this rendering has,
and some 18 dB under the notes).
Each sample here is the speaker averaged over one turn of the player's loop,
96 T-states centred on it, which removes the switching exactly.
"""
from __future__ import annotations

import html
import math
import re
from pathlib import Path

import build_fairlight as bf

TSTATES_PER_SECOND = 3_500_000
SAMPLE_RATE = 44100
SKOOL = bf.OUT_DIR / "fairlight.skool"

# The loading tune (see the entries).
LOADING_TUNE = 0xC000
TUNE_NEXT_NOTE = 0xC026
TUNE_PITCH = 0xC033
TUNE_RESTART_VOICE = 0xC041
TUNE_PLAY_NOTE = 0xC049
# In TUNE_PLAY_NOTE, both pitches looked up: H voice two's, D voice one's.
# Reached once for every note, played or not: where the run stops between
# notes.
NOTE_READY = 0xC069
VOICE_ONE_NOTE = 0xC01A
TUNE_PORT = 0xC01C
VOICE_ONE_AT = 0xC01D       # two words: the note last taken, where to go back to
VOICE_TWO_AT = 0xC021
NOTE_LENGTH = 0xC025
TUNE_VOICES = 0xC0B0
TUNE_NOTES = 0xC0B8         # TUNE_VOICES+8: the pitches, for notes -12 to 41
PITCHES = 54
LOWEST = -12
REST = 41
END_MARK = 0x40
VOICE_ONE_OUT = 0xC087
VOICE_TWO_OUTS = (0xC093, 0xC0A5)
SPEAKER = 0x10

# TUNE_PLAY_NOTE's timing, from its instructions. From NOTE_READY to $C072:
# LD A,H, CP 1 and the JR NZ that jumps (4+7+12) when voice two plays; when it
# rests, the JR falls through, LD A,D, CP 1 and a RET Z that does not return
# (4+7+7+4+7+5).
TO_PLAY_VOICE_TWO, TO_PLAY_VOICE_ONE = 23, 34
# $C072 to the first turn at $C085: three LD A,(nn), LD C,A, LD B,0, EX
# AF,AF', LD IXh,D, LD D,$10 and the two NOPs (13*3+4+7+4+8+7+8).
SET_UP = 77
# A turn, from $C085: EX AF,AF' and DEC E (8) to voice one's OUT, and 56 to
# voice two's either way round the loop (the tracer sees an OUT as it
# starts); 96 in all -- but the turn that ends a pass of 256, where the DJNZ
# falls through to INC C and JP NZ,$C085 (22 T-states where the DJNZ that
# jumps and the NOPs take 21), is 97.
VOICE_ONE_PHASE, VOICE_TWO_PHASE = 8, 56
TURN = 96
PASS = 256

# The loader's failure routine (see #R$DCC9), and the ROM's BEEPER.
LOADER_FAILED = 0xDCC9
FAILED_END = 0xDD1C         # its RST 0
LOADER_STACK = 0xDADE       # the loader's stack, near its table (#R$DAC0)
BEEPER = 0x03B5
# BEEPER's timing, worked out from its instructions ($03B5-$03F7): every
# half-wave, on or off, from one OUT to the next, is 4 HL + 118 T-states --
# the two ways back into the delay loop after the OUT take 55 and 71
# T-states, and the shorter one counts C one more turn of 16. So a wave is
# 8 HL + 236 (the ROM's own comment, HL = 437500 / f - 30.125, would make it
# 8 HL + 241). Its first OUT comes almost at once, turning the speaker on,
# and it stops after an OUT turning it off with DE counted down to 0: DE + 1
# waves.
BEEPER_HALF = (4, 118)

# Sharps written as HTML entities: the names go into ref sections, where a
# "#" starts a SkoolKit macro.
NAMES = ["C", "C&#35;", "D", "D&#35;", "E", "F", "F&#35;", "G", "G&#35;", "A", "A&#35;", "B"]

# The pictures' colours: the page's own (aticatac.css).
BACK = (16, 16, 60)
GRID = (30, 30, 96)
TEXT = (232, 232, 244)
DIM = (150, 150, 180)
ONE = (95, 215, 255)
TWO = (255, 255, 85)
BOTH = (124, 240, 124)
HEARD = (255, 140, 255)


def _esc(text: str) -> str:
    return html.escape(text, quote=False)


def _hz(tstates: float) -> float:
    return TSTATES_PER_SECOND / tstates


def _word(memory, address: int) -> int:
    return memory[address] | memory[address + 1] << 8


def _signed(value: int) -> int:
    return value - 256 if value > 127 else value


def note_name(hz: float) -> str:
    """The nearest note of the equal-tempered scale on A = 440 Hz, and how
    far off it the pitch is, in cents."""
    midi = 69 + 12 * math.log2(hz / 440)
    near = round(midi)
    cents = round((midi - near) * 100)
    name = f"{NAMES[near % 12]}{near // 12 - 1}"
    return name + (f" {cents:+d}" if cents else "")


def note_below(hz: float) -> str:
    """The note of the equal-tempered scale on A = 440 Hz at or below a
    pitch, and how far above it the pitch is, in cents: the tune's table
    stands about half a semitone above that scale, so naming each pitch by
    the nearest note would give neighbouring semitones the same name."""
    midi = 69 + 12 * math.log2(hz / 440)
    below = math.floor(midi)
    cents = round((midi - below) * 100)
    if cents == 100:
        below, cents = below + 1, 0
    return f"{NAMES[below % 12]}{below // 12 - 1} +{cents}"


def skool_entries() -> set:
    """The addresses that start an entry in the listing, the only ones #R can
    link to."""
    found = set()
    if SKOOL.exists():
        for line in SKOOL.read_text(encoding="utf-8").splitlines():
            match = re.match(r"^[bcgistuw]\$([0-9A-F]{4})", line)
            if match:
                found.add(int(match.group(1), 16))
    return found


def link(text: str, entries: set) -> str:
    """#R$ADDR where ADDR starts an entry; a plain $ADDR otherwise."""
    return re.sub(r"#R\$([0-9A-F]{4})",
                  lambda m: m.group(0) if int(m.group(1), 16) in entries else "$" + m.group(1),
                  text)


# --------------------------------------------------------------------------
# The tune's data.
# --------------------------------------------------------------------------

class Tune:
    """The loading tune as #R$C0B0 holds it: the pitch table, and each
    voice's notes from the byte after its start pointer to its $40."""

    def __init__(self, memory):
        self.pitches = [memory[TUNE_NOTES + n] for n in range(PITCHES)]
        self.voices = []
        self.first = []
        self.restart = []
        for voice in range(2):
            start = _word(memory, TUNE_VOICES + 4 * voice)
            self.restart.append(_word(memory, TUNE_VOICES + 4 * voice + 2))
            address = start + 1
            self.first.append(address)
            notes = []
            while memory[address] != END_MARK:
                notes.append(_signed(memory[address]))
                address += 1
            self.voices.append(notes)
        self.passes = (256 - memory[NOTE_LENGTH]) & 0xFF or 256
        self.port = memory[TUNE_PORT]
        pairs = list(zip(*self.voices))
        # The notes after the last one either voice plays: both resting,
        # TUNE_PLAY_NOTE returns at once, and the tune is over.
        self.played = max(n for n, (a, b) in enumerate(pairs) if a != REST or b != REST) + 1
        self.both_rest = [n for n, (a, b) in enumerate(pairs) if a == REST and b == REST]

    def pitch(self, note: int) -> int:
        """TUNE_PITCH: the byte at the note plus 12."""
        return self.pitches[(note - LOWEST) & 0xFF]

    def note_hz(self, note: int) -> float:
        """A voice toggles every `pitch` turns: a wave is twice that many
        turns of 96 T-states (the odd 97-T-state turn, one in 256, left
        out)."""
        return _hz(2 * TURN * self.pitch(note))

    def note_tstates(self) -> int:
        turns = PASS * self.passes
        return turns * TURN + (self.passes - 1)

    def repeated(self) -> tuple[int, int, int]:
        """The longest passage (both voices together) that is played twice:
        its length and where each copy starts."""
        pairs = list(zip(*self.voices))[:self.played]
        best = (0, 0, 0)
        count = len(pairs)
        for shift in range(1, count):
            run = 0
            for n in range(count - shift):
                if pairs[n] == pairs[n + shift]:
                    run += 1
                    if run > best[0]:
                        best = (run, n - run + 1, n - run + 1 + shift)
                else:
                    run = 0
        return best


def note_edges(start: int, one: int, two: int, passes: int, port: int,
               speaker: int) -> tuple[list[int], int]:
    """The edges TUNE_PLAY_NOTE makes for a note, worked out from its code:
    `start` is the T-state of the first turn ($C085), `one` and `two` the
    voices' pitches (turns between toggles), `speaker` the speaker bit
    before the note. Each voice starts from TUNE_PORT's byte with a countdown
    of 1; each turn voice one's byte goes out, its countdown is counted down
    and, run out, reloaded and its speaker bit toggled; then the same for
    voice two. Returns the edges and the speaker bit after the note."""
    edges = []
    count_one = count_two = 1
    byte_one = byte_two = port & SPEAKER
    t = start
    for turn in range(PASS * passes):
        if byte_one != speaker:
            speaker = byte_one
            edges.append(t + VOICE_ONE_PHASE)
        count_one -= 1
        if count_one == 0:
            count_one = one
            byte_one ^= SPEAKER
        if byte_two != speaker:
            speaker = byte_two
            edges.append(t + VOICE_TWO_PHASE)
        count_two -= 1
        if count_two == 0:
            count_two = two
            byte_two ^= SPEAKER
        t += TURN + (1 if turn % PASS == PASS - 1 else 0)
    return edges, speaker


# --------------------------------------------------------------------------
# Recording.
# --------------------------------------------------------------------------

def _tracer_class():
    from skoolkit.simutils import PC, T

    KeyTracer = bf._key_tracer_class()

    class SoundTracer(KeyTracer):
        """The build's key tracer (no key held), and the T-state of every
        change of the speaker bit (bit 4 of an OUT to an even port); every
        OUT's address and port counted; and, while `log` is a list, every
        OUT to an even port as (T-state, address, byte)."""

        def __init__(self, simulator):
            super().__init__(simulator)
            self.speaker = 0            # taken to be off as the recording starts
            self.edges = []
            self.outs = {}
            self.log = None
            self.write_port = self._write

        def _write(self, registers, port, value, offset=0):
            where = (registers[PC], port & 0xFF)
            self.outs[where] = self.outs.get(where, 0) + 1
            if port & 1 == 0:
                if self.log is not None:
                    self.log.append((registers[T], registers[PC], value))
                if (value & SPEAKER) != self.speaker:
                    self.speaker = value & SPEAKER
                    self.edges.append(registers[T])

    return SoundTracer


class Game:
    """Fairlight from its first instruction on build_fairlight's Machine,
    with the sound tracer."""

    def __init__(self, snapshot: Path, pokes=None):
        self.machine = bf.Machine(snapshot)
        self.sim = self.machine.simulator
        for where, value in (pokes or {}).items():
            self.sim.memory[where] = value
        self.tracer = _tracer_class()(self.sim)
        self.machine.tracer = self.tracer
        self.sim.set_tracer(self.tracer)

    @property
    def now(self) -> int:
        from skoolkit.simutils import T
        return self.sim.registers[T]

    def reg(self, name: str) -> int:
        import skoolkit.simutils as su
        return self.sim.registers[getattr(su, name)]

    def run_to(self, address: int, seconds: float = 2.0) -> None:
        self.machine.run(seconds, stop=address)
        if self.machine.pc != address:
            raise RuntimeError(f"${address:04X} was not reached (PC ${self.machine.pc:04X})")


def play_tune(snapshot: Path, tune: Tune, pokes=None, notes: int | None = None,
              log_note: int | None = None) -> dict:
    """The tune played from the game's first instruction with no key held,
    note by note -- stopped at NOTE_READY in each -- and each note's edges
    checked against note_edges. `notes` stops it early; `log_note` keeps
    every OUT of that note."""
    game = Game(snapshot, pokes)
    game.run_to(LOADING_TUNE)
    t0 = game.now
    last = min(tune.played, notes or tune.played)
    matched, skipped, gaps, logged, mismatch = 0, 0, [], None, None
    speaker = game.tracer.speaker
    end_of_last = None
    # The simulator runs at least one instruction before it looks at the
    # stop address, so each run_to below goes on to the next note's.
    game.run_to(NOTE_READY)
    while True:
        index = _word(game.sim.memory, VOICE_ONE_AT) - tune.first[0]
        if _word(game.sim.memory, VOICE_TWO_AT) - tune.first[1] != index:
            raise RuntimeError("the voices are out of step")
        if index >= last:
            end = game.now
            break
        one, two = game.reg("D"), game.reg("H")
        if (one, two) != (tune.pitch(tune.voices[0][index]), tune.pitch(tune.voices[1][index])):
            raise RuntimeError(f"note {index}: pitches {one}, {two} are not the table's")
        ready = game.now
        before = len(game.tracer.edges)
        if log_note == index:
            game.tracer.log = []
        if one == 1 and two == 1:
            skipped += 1
            expected, after = [], speaker
        else:
            begin = ready + (TO_PLAY_VOICE_TWO if two != 1 else TO_PLAY_VOICE_ONE) + SET_UP
            if end_of_last is not None:
                gaps.append(begin + VOICE_ONE_PHASE - end_of_last)
            expected, after = note_edges(begin, one, two, tune.passes, tune.port, speaker)
            # The note's last OUT: voice two's, in its last turn.
            end_of_last = begin + tune.note_tstates() - TURN + VOICE_TWO_PHASE
        game.run_to(NOTE_READY)
        measured = game.tracer.edges[before:]
        if log_note == index:
            logged = {"outs": game.tracer.log, "start": ready, "one": one, "two": two,
                      "notes": (tune.voices[0][index], tune.voices[1][index]),
                      "index": index}
            game.tracer.log = None
        if measured == expected:
            matched += 1
        elif mismatch is None:
            where = next((n for n, (a, b) in enumerate(zip(measured, expected)) if a != b),
                         min(len(measured), len(expected)))
            mismatch = (index, len(measured), len(expected), where,
                        [t - ready for t in measured[where:where + 3]],
                        [t - ready for t in expected[where:where + 3]])
        speaker = after
    edges = [t - t0 for t in game.tracer.edges]
    tail = None
    if last == tune.played:
        # The tune over: a second more of the loop, which should be silent
        # -- both voices resting, TUNE_PLAY_NOTE returns at once.
        before = len(game.tracer.edges)
        game.machine.run(1.0)
        tail = len(game.tracer.edges) - before
    return {"edges": edges, "length": end - t0, "matched": matched, "skipped": skipped,
            "notes": last, "gaps": gaps, "mismatch": mismatch, "log": logged,
            "outs": dict(game.tracer.outs), "tail": tail}


# --------------------------------------------------------------------------
# Writing a WAV.
# --------------------------------------------------------------------------

def render(edges: list[int], length: int, window: int = TURN):
    """The speaker as 16-bit samples at 44100 Hz: each sample the fraction of
    the `window` T-states centred on it that the speaker was on (it starts
    off, and each edge flips it)."""
    import numpy as np

    times = np.asarray(edges, dtype=np.float64)
    # The time the speaker has been on up to each edge.
    on = np.zeros(len(times) + 1)
    if len(times) > 1:
        spans = np.diff(times)
        spans[1::2] = 0             # on from an even-numbered edge to the next
        on[2:] = np.cumsum(spans)
    count = int(length * SAMPLE_RATE / TSTATES_PER_SECOND)
    centres = np.arange(count) * (TSTATES_PER_SECOND / SAMPLE_RATE)

    def on_until(t):
        n = np.searchsorted(times, t, side="right")    # the edges at or before t
        total = on[n]
        # After an odd number of edges the speaker is on: add the time since.
        odd = (n % 2) == 1
        last = times[np.maximum(n - 1, 0)] if len(times) else np.zeros_like(t)
        return total + np.where(odd, t - last, 0.0)

    level = (on_until(centres + window / 2) - on_until(centres - window / 2)) / window
    return np.round(level * 0xFFFF - 0x8000).astype("<i2")


def write_wav(path: Path, edges: list[int], length: int) -> None:
    import wave

    samples = render(edges, length)
    with wave.open(str(path), "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(SAMPLE_RATE)
        out.writeframes(samples.tobytes())


# --------------------------------------------------------------------------
# The loader's warble.
# --------------------------------------------------------------------------

def _base(snapshot: Path) -> list:
    from skoolkit import read_bin_file

    memory = list(bf.game_memory(snapshot))
    memory[:0x4000] = read_bin_file(str(bf.ROM))
    return memory


def warble_plan(memory) -> dict:
    """What the failure routine's loop gives BEEPER, read from its
    instructions: B warbles of (DE, HL) and (E, HL)."""
    expect = {0xDD05: 0x06, 0xDD08: 0x11, 0xDD0B: 0x21, 0xDD0E: 0xCD, 0xDD11: 0x1E,
              0xDD13: 0x21, 0xDD16: 0xCD, 0xDD1A: 0x10, 0xDD1C: 0xC7}
    for address, opcode in expect.items():
        if memory[address] != opcode:
            raise RuntimeError(f"the failure routine is not as expected at ${address:04X}")
    if _word(memory, 0xDD0F) != BEEPER or _word(memory, 0xDD17) != BEEPER:
        raise RuntimeError("the failure routine does not call BEEPER")
    # The second call's D is what the first BEEPER left, 0: it counts DE down to 0.
    return {"times": memory[0xDD06] or 256,
            "calls": [(_word(memory, 0xDD09), _word(memory, 0xDD0C)),
                      (memory[0xDD12], _word(memory, 0xDD14))]}


def beeper_hz(hl: int) -> float:
    return _hz(2 * (BEEPER_HALF[0] * hl + BEEPER_HALF[1]))


def record_warble(snapshot: Path) -> dict:
    """The failure routine run on a machine of its own, from its first
    instruction to its RST 0, with the ROM's interrupt routine running as it
    would (BEEPER turns interrupts on as it returns), checked against the
    BEEPER's timing: each call DE + 1 waves, every half-wave 4 HL + 118."""
    from skoolkit import CSimulator
    from skoolkit.simulator import Simulator
    from skoolkit.simutils import PC, SP, T

    memory = _base(snapshot)
    plan = warble_plan(memory)
    simulator = (CSimulator or Simulator)(memory, state={"iff": 0, "im": 1, "tstates": 0})
    tracer = _tracer_class()(simulator)
    simulator.set_tracer(tracer)
    simulator.registers[SP] = LOADER_STACK
    simulator.trace(LOADER_FAILED, FAILED_END, 0, 60 * TSTATES_PER_SECOND, True,
                    None, None, None, None, None)
    if simulator.registers[PC] != FAILED_END:
        raise RuntimeError("the failure routine did not reach its RST 0")
    edges = list(tracer.edges)
    # The edges in the order the calls make them: DE + 1 waves each, every
    # half-wave inside a call 4 HL + 118.
    expected = [(de + 1, BEEPER_HALF[0] * hl + BEEPER_HALF[1]) for de, hl in plan["calls"]]
    count = plan["times"] * sum(2 * waves for waves, _ in expected)
    ok = len(edges) == count
    wrong, at, calls, gaps = 0, 0, 0, []
    while ok and at < len(edges):
        for waves, half in expected:
            call = edges[at:at + 2 * waves]
            if at:
                gaps.append(call[0] - edges[at - 1])
            if {b - a for a, b in zip(call, call[1:])} != {half}:
                wrong += 1
            at += 2 * waves
            calls += 1
    return {"edges": edges, "length": simulator.registers[T], "calls": calls,
            "plan": plan, "expected": expected, "ok": ok and not wrong, "wrong": wrong,
            "gaps": gaps,
            "outs": dict(tracer.outs)}


# --------------------------------------------------------------------------
# Silence in play.
# --------------------------------------------------------------------------

def listing_ports(skool: Path) -> tuple[list[tuple[int, str]], list[tuple[int, str]]]:
    """Every instruction in the listing that writes a port, and every one
    that calls or jumps into the ROM or restarts: (address, instruction).
    Data (DEFB and the rest) is not looked at: only instructions."""
    outs, rom = [], []
    if not skool.exists():
        return outs, rom
    for line in skool.read_text(encoding="utf-8").splitlines():
        match = re.match(r"^[c* ]\$([0-9A-F]{4}) ([A-Z]+)(?: ([^;]*?))?\s*(?:;|$)", line)
        if not match:
            continue
        address, op, operands = int(match.group(1), 16), match.group(2), match.group(3) or ""
        text = f"{op} {operands}".strip()
        if op in ("OUT", "OUTI", "OUTD", "OTIR", "OTDR"):
            outs.append((address, text))
        elif op in ("CALL", "JP") and re.search(r"(^|,)\$[0-3][0-9A-F]{3}$", operands):
            rom.append((address, text))
        elif op == "RST":
            rom.append((address, text))
    return outs, rom


def play_sessions(snapshot: Path, cycles: int = 4) -> list[dict]:
    """The build's own play sessions (build_fairlight.sessions) run again
    with every OUT logged: for each, the emulated seconds and which
    instructions wrote which ports how often."""
    out = []
    for label, steps in bf.sessions(snapshot, cycles):
        game = Game(snapshot)
        start = game.now
        game.machine.play(steps, label)
        out.append({"label": label, "seconds": (game.now - start) / TSTATES_PER_SECOND,
                    "outs": dict(game.tracer.outs), "edges": len(game.tracer.edges)})
    return out


# --------------------------------------------------------------------------
# Pictures.
# --------------------------------------------------------------------------

def _font(size: int = 12):
    from PIL import ImageFont
    return ImageFont.load_default(size=size)


def draw_roll(tune: Tune, note_seconds: float, path: Path) -> tuple[int, int]:
    """Both voices over the whole tune in two rows, the first half above the
    second, four pixels a note and four a semitone: voice one cyan, voice
    two yellow, green where they play the same note; rests left out."""
    from PIL import Image, ImageDraw

    step, row = 4, 4
    played = [v[:tune.played] for v in tune.voices]
    notes = [n for v in played for n in v if n != REST]
    low, high = min(notes), max(notes)
    per_row = (tune.played + 1) // 2
    left, top, right, label = 104, 26, 12, 24
    strip = row * (high - low + 1)
    width = left + step * per_row + right
    height = top + 2 * (strip + label) + 4
    image = Image.new("RGB", (width, height), BACK)
    draw = ImageDraw.Draw(image)
    font = _font(11)
    draw.text((left, 6), "voice one", fill=ONE, font=font)
    draw.text((left + 80, 6), "voice two", fill=TWO, font=font)
    draw.text((left + 160, 6), "both on the same note", fill=BOTH, font=font)
    for half in range(2):
        y0 = top + half * (strip + label)
        first = half * per_row
        # A line every twelve semitones up from the lowest note, with its
        # number and pitch.
        for note in range(low, high + 1):
            if (note - low) % 12 == 0:
                y = y0 + row * (high - note) + row // 2
                draw.line([(left, y), (width - right, y)], fill=GRID)
                draw.text((4, y - 7), f"{note:+d}: {tune.note_hz(note):.0f} Hz", fill=DIM,
                          font=font)
        # A mark every five seconds.
        mark = 0
        while mark <= tune.played * note_seconds:
            n = mark / note_seconds - first
            if 0 <= n <= per_row:
                x = left + step * n
                draw.line([(x, y0), (x, y0 + strip)], fill=GRID)
                draw.text((x - 8, y0 + strip + 5), f"{mark} s", fill=DIM, font=font)
            mark += 5
        for n in range(first, min(first + per_row, tune.played)):
            a, b = played[0][n], played[1][n]
            for voice, note in ((0, a), (1, b)):
                if note == REST:
                    continue
                colour = BOTH if a == b else (ONE if voice == 0 else TWO)
                y = y0 + row * (high - note)
                x = left + step * (n - first)
                draw.rectangle([x, y, x + step - 2, y + row - 2], fill=colour)
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)
    return width, height


def _steps(outs) -> tuple[list, list, list]:
    """From a note's OUTs: voice one's byte, voice two's and the speaker's,
    each as [(T-state, level)], a level from every OUT."""
    one, two, speaker = [], [], []
    for t, pc, value in outs:
        level = 1 if value & SPEAKER else 0
        if pc == VOICE_ONE_OUT:
            one.append((t, level))
        elif pc in VOICE_TWO_OUTS:
            two.append((t, level))
        speaker.append((t, level))
    return one, two, speaker


def _level_at(steps, t: float) -> int:
    level = 0
    for when, value in steps:
        if when > t:
            break
        level = value
    return level


def _square(draw, steps, y, band, x_of, start, end, colour) -> None:
    """A step function as a square wave between y + band (0) and y (1)."""
    level = _level_at(steps, start)
    points = [(x_of(start), y + band * (1 - level))]
    for t, value in steps:
        if start < t <= end and value != level:
            points.append((x_of(t), y + band * (1 - level)))
            level = value
            points.append((x_of(t), y + band * (1 - level)))
    points.append((x_of(end), y + band * (1 - level)))
    draw.line(points, fill=colour, width=2)


def _on_time(edges: list[int], t: float) -> float:
    """How long the speaker had been on by T-state t, given its edges (it
    starts off, each edge flips it)."""
    total = 0.0
    for i in range(0, len(edges), 2):
        if edges[i] >= t:
            break
        off = edges[i + 1] if i + 1 < len(edges) else t
        total += min(off, t) - edges[i]
    return total


def draw_voices(log: dict, path: Path) -> dict:
    """One note's OUTs as the recording has them, in two panels: a stretch as
    long as two of the lower voice's waves, and a close-up of a dozen turns.
    Rows: voice one's byte (the OUT at $C087), voice two's (the OUT at $C093
    or $C0A5), the speaker, and the speaker averaged over a turn."""
    from PIL import Image, ImageDraw

    outs = log["outs"]
    one, two, speaker = _steps(outs)
    first = outs[0][0]
    long = 4 * max(log["one"], log["two"]) * TURN
    wide = (first + 16 * TURN, first + 16 * TURN + long)
    # The close-up: a dozen turns from four before voice one's first change
    # of level in the wide view.
    change = next(t for (t, a), (_, b) in zip(one, one[1:])
                  if b != a and t > wide[0] + 4 * TURN)
    change = next(t for t, value in one if t > change)       # the OUT that shows it
    close_start = change - 4 * TURN - VOICE_ONE_PHASE
    close = (close_start, close_start + 12 * TURN)
    edges, level = [], 0
    for t, value in speaker:
        if value != level:
            edges.append(t)
            level = value
    left, width = 180, 880
    band, gap = 26, 16
    labels = [("voice one's byte (OUT at $C087)", ONE), ("voice two's byte (OUT at $C093/$C0A5)", TWO),
              ("the speaker (bit 4)", BOTH), ("averaged over a turn", HEARD)]
    panel = 24 + len(labels) * (band + gap)
    image = Image.new("RGB", (left + width + 16, 2 * panel + 16), BACK)
    draw = ImageDraw.Draw(image)
    font = _font(12)
    for p, (start, end) in enumerate((wide, close)):
        span = end - start

        def x_of(t, start=start, span=span):
            return left + (t - start) * width / span

        y = p * panel + 8
        us = span / TSTATES_PER_SECOND * 1e6
        draw.text((left, y), (f"{us / 1000:.1f} ms of the note" if p == 0 else
                              f"Close-up: 12 turns of the loop, {us:.0f} microseconds; "
                              "a tick at every OUT"), fill=TEXT, font=font)
        y += 22
        for n, (label, colour) in enumerate(labels):
            draw.text((6, y + 6), label, fill=colour, font=font)
            if n < 2:
                _square(draw, (one, two)[n], y, band, x_of, start, end, colour)
                if p == 1:
                    for t, _ in (one, two)[n]:
                        if start <= t <= end:
                            draw.line([(x_of(t), y + band + 3), (x_of(t), y + band + 8)],
                                      fill=DIM)
            elif n == 2 and p == 0:
                # Too fine for a line here: a column is drawn full height where
                # the speaker switched inside it.
                for column in range(width):
                    a = start + span * column / width
                    b = start + span * (column + 1) / width
                    inside = [t for t in edges if a <= t < b]
                    if inside:
                        draw.line([(left + column, y), (left + column, y + band)], fill=colour)
                    else:
                        level = _level_at(speaker, a)
                        yy = y + band * (1 - level)
                        draw.line([(left + column, yy), (left + column, yy)], fill=colour)
            elif n == 2:
                _square(draw, speaker, y, band, x_of, start, end, colour)
            else:
                points = []
                for column in range(width + 1):
                    t = start + span * column / width
                    heard = (_on_time(edges, t + TURN / 2) - _on_time(edges, t - TURN / 2)) / TURN
                    points.append((left + column, y + band * (1 - heard)))
                draw.line(points, fill=colour, width=2)
            y += band + gap
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)
    return {"wide": wide, "close": close, "size": image.size}


# --------------------------------------------------------------------------
# Writing the page.
# --------------------------------------------------------------------------

SOLO_NOTES = 64             # the opening, for the voices on their own
KRUMLINDE = "https://github.com/VilleKrumlinde/FairlightZ80"


def _length(tstates: int) -> str:
    seconds = tstates / TSTATES_PER_SECOND
    return f"{seconds * 1000:.0f} ms" if seconds < 1 else f"{seconds:.2f} s"


def _table(header: list[str], rows: list[list[str]]) -> list[str]:
    lines = ['<table class="kl-table">',
             "<tr>" + "".join(f"<th>{h}</th>" for h in header) + "</tr>"]
    for row in rows:
        lines.append("<tr>" + "".join(f"<td>{cell}</td>" for cell in row) + "</tr>")
    lines.append("</table>")
    return lines


def _item(name: str, title: str, paragraphs: list[str], stats: str) -> list[str]:
    file = f"audio/{name}.wav"
    lines = [f'<div class="kl-item" id="{name}">', f"<h4>{_esc(title)}</h4>"]
    lines += [f"<p>{p}</p>" for p in paragraphs if p]
    lines += [f"<p>{stats}.</p>",
              f'<audio controls preload="none" src="{file}"><a href="{file}">{name}.wav</a>'
              "</audio>", "</div>"]
    return lines


def _number(count: int) -> str:
    words = ["no", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine"]
    return words[count] if count < len(words) else str(count)


def _entry_of(address: int, entries: set) -> int:
    return max((e for e in entries if e <= address), default=address)


def _tune_check(result: dict, tune: Tune) -> str:
    skipped = result["skipped"]
    text = (f"all {result['notes']} notes"
            + (f" ({skipped} of them rests in both voices, which #R$C049 skips at once)"
               if skipped else "")
            + " were compared, edge by edge, with a model of "
            "#R$C049's loop worked out from its instructions: each voice starting from "
            f"TUNE_PORT's byte ({tune.port}) with a countdown of 1; voice one's OUT "
            f"{VOICE_ONE_PHASE} T-states into each {TURN}-T-state turn and voice two's at "
            f"{VOICE_TWO_PHASE}; a turn of {TURN + 1} at the end of each pass of {PASS} but "
            "the last; each "
            "voice's bit toggled when its countdown runs out. ")
    if result["matched"] == result["notes"]:
        text += (f"Every one of the {len(result['edges']):,} edges was where the model puts it, "
                 "to the T-state")
    else:
        index, got, want, where, measured, expected = result["mismatch"]
        text += (f"Only {result['matched']} notes matched: NOT note {index + 1}, "
                 f"{got} edges where the model has {want}, first differing at edge {where} "
                 f"({measured} against {expected} T-states from the note's start)")
    if result["gaps"]:
        low, high = min(result["gaps"]), max(result["gaps"])
        text += (f". From one note's last OUT to the next note's first, {low:,}"
                 + (f" to {high:,}" if high != low else "")
                 + " T-states: the ROM's KEY-SCAN and the next note's set-up"
                 + (", with another KEY-SCAN for each note skipped" if skipped else ""))
    if result.get("tail") is not None:
        text += (". After the last note, a further second of the loop made "
                 + ("no edge" if result["tail"] == 0 else f"{result['tail']} edges -- NOT silent"))
    return text


def _pitch_rows(tune: Tune) -> list[list[str]]:
    counts = [{}, {}]
    for voice in range(2):
        for note in tune.voices[voice][:tune.played]:
            counts[voice][note] = counts[voice].get(note, 0) + 1
    rows = []
    for note in sorted(set(counts[0]) | set(counts[1])):
        pitch = tune.pitch(note)
        hz = tune.note_hz(note)
        rows.append([f"{note:+d}" if note != REST else f"{REST} (rest)",
                     f"${(note - LOWEST) & 0xFF:02X}", str(pitch),
                     f"{hz:,.1f}&nbsp;Hz", note_below(hz) if note != REST else "--",
                     str(counts[0].get(note, "")), str(counts[1].get(note, ""))])
    return rows


def _sharp(tune: Tune) -> tuple[int, int]:
    """How far from the equal-tempered scale on A = 440 Hz the notes -12 to
    24 are, in cents above the nearest note below them."""
    offsets = []
    for note in range(LOWEST, 25):
        midi = 69 + 12 * math.log2(tune.note_hz(note) / 440)
        offsets.append(round((midi - math.floor(midi)) * 100))
    offsets.sort()
    return offsets[0], offsets[len(offsets) // 2], offsets[-1]


def _sessions_rows(sessions: list[dict]) -> tuple[list[list[str]], set, float]:
    rows, writers, total = [], set(), 0.0
    for session in sessions:
        total += session["seconds"]
        tune_outs = sum(n for (pc, port), n in session["outs"].items()
                        if TUNE_PLAY_NOTE <= pc < TUNE_VOICES)
        other = {(pc, port): n for (pc, port), n in session["outs"].items()
                 if not TUNE_PLAY_NOTE <= pc < TUNE_VOICES}
        writers |= {pc for pc, _ in session["outs"]}
        rows.append([_esc(session["label"]), f"{session['seconds']:,.0f} s", f"{tune_outs:,}",
                     ", ".join(f"${pc:04X} (port ${port:02X}): {n}"
                               for (pc, port), n in sorted(other.items())) or "none"])
    return rows, writers, total


def _bass_end(notes: list[int]) -> int:
    """Where voice one stops holding notes four or more at a time: the start
    of its first short run after the two notes it opens with."""
    at, runs = 0, []
    while at < len(notes):
        length = 1
        while at + length < len(notes) and notes[at + length] == notes[at]:
            length += 1
        runs.append((at, length))
        at += length
    return next(start for start, length in runs[2:] if length < 4)


def _stretches(notes: list[int], note_seconds: float) -> str:
    """Note numbers grouped where they lie within eight of each other, as
    'three places (at about 20, 37 and 41 s, 18 notes in all)'."""
    groups = []
    for n in notes:
        if groups and n - groups[-1][-1] <= 8:
            groups[-1].append(n)
        else:
            groups.append([n])
    words = ["no", "one", "two", "three", "four", "five", "six"]
    count = words[len(groups)] if len(groups) < len(words) else str(len(groups))
    times = [f"{g[0] * note_seconds:.0f}" for g in groups]
    at = ", ".join(times[:-1]) + (" and " if len(times) > 1 else "") + times[-1]
    return (f"{count} place{'s' if len(groups) != 1 else ''} (at about {at} s, "
            f"{len(notes)} notes in all)")


def _section(tune: Tune, full: dict, solos: list[dict], logged: dict, voices_picture: dict,
             roll_size, warble: dict, sessions: list[dict], listing, entries: set) -> str:
    note_seconds = full["length"] / full["notes"] / TSTATES_PER_SECOND
    outs, rom_calls = listing
    session_rows, writers, total = _sessions_rows(sessions)
    only_tune = all(VOICE_ONE_OUT <= pc <= VOICE_TWO_OUTS[1] for pc in writers)
    one, two = tune.voices[0][:tune.played], tune.voices[1][:tune.played]
    lows = [min(n for n in v if n != REST) for v in (one, two)]
    highs = [max(n for n in v if n != REST) for v in (one, two)]
    rests = [v.count(REST) for v in (one, two)]
    run, at_one, at_two = tune.repeated()
    sharp_low, sharp_mid, sharp_high = _sharp(tune)
    top = [tune.pitch(40), tune.pitch(39)]
    top_gap = 12 * math.log2(top[1] / top[0])
    pick = logged["index"]
    bass_end = _bass_end(one)
    above = [n for n in range(tune.played)
             if REST not in (one[n], two[n]) and one[n] > two[n]]
    plan = warble["plan"]
    (de1, hl1), (de2, hl2) = plan["calls"]

    lines = [
        '<div class="kl-list">',
        "<p>Fairlight has one piece of music and no sound effects. The loading tune -- "
        "music by Mark Alexander, as <a href=\"https://spectrumcomputing.co.uk/entry/1712\">"
        "ZXDB</a> credits it -- plays once over the loading screen, "
        f"{_length(full['length'])} of it in two voices, until a key is pressed; from the "
        "title screen on the game makes no sound at all. No footsteps, no jumps, no blows, no "
        "doors, no pick-ups, no chime for a message: nothing.</p>",
        "<p>That is a finding, not an omission here, and it rests on two things. A 48K "
        "Spectrum makes sound only by an OUT to port $FE that changes its bit 4. The listing "
        f"has {_number(len(outs))} instructions that write a port, "
        + ", ".join(f"${a:04X}" for a, _ in outs)
        + (", all of them in the tune's player #R$C049" if all(
            TUNE_PLAY_NOTE <= a < TUNE_VOICES for a, _ in outs) else ", NOT all in the tune's player")
        + ", and reaches the ROM only through "
        + "; ".join(f"{_esc(text)} at ${a:04X} (in #R${_entry_of(a, entries):04X})"
                    for a, text in rom_calls)
        + " -- KEY-SCAN and PIXEL-ADD, neither of which writes a port; and interrupts are "
        "off from start-up on (#R$C47C), so the ROM's interrupt routine does not run "
        "(<em>read</em>). And the build's own nine play sessions, "
        f"{total / 60:.0f} minutes of emulated play between them -- every room entered "
        "and the keys tried in it, every door walked through, every thing picked up, used "
        "and dropped, everything in every room met, a game lost and the quest done -- were "
        "run again for this page "
        "with every OUT to any port logged: "
        + ("the only ones were the tune's, in the half-second each session lets it play "
           "before its first key" if only_tune else
           "NOT only the tune's: see the table")
        + " (<em>measured</em>). Ville Krumlinde's "
        f'<a href="{KRUMLINDE}">disassembly</a> says the same of the game in play: his notes '
        "on the close-range strike observe that nothing in it outputs to port $FE. His "
        "snapshot was taken mid-game, after the room buffers had been written over the tune "
        "at $C000, so the tune itself is not in his listing.</p>",
    ]
    lines += _table(["Session", "Emulated", "OUTs by the tune", "Any other OUT"], session_rows)

    # The tune.
    stats = (f"{_length(full['length'])}, {full['notes']} notes, {len(full['edges']):,} edges, "
             f"{tune.note_hz(max(highs)):.0f} Hz at the highest, "
             f"{tune.note_hz(min(lows)):.0f} Hz at the lowest")
    lines += ["<h3>The loading tune</h3>"]
    lines += _item(
        "tune", "The loading tune, whole",
        [f"#R$C47C, the game's first instruction, calls #R$C000 while the loading screen is "
         "still up. It sets both voices to the start of the tune, turns interrupts off, and "
         "then plays a note (#R$C049) and calls the ROM's KEY-SCAN, over and over, until a "
         "key is down; the note under way finishes first, so a key stops the tune within an "
         f"eighth of a second. Each voice has {len(tune.voices[0])} notes, but the last "
         f"{len(tune.voices[0]) - tune.played} are rests in both, and a note both voices "
         "rest is not played at all (#R$C049 returns at once), so "
         f"{tune.played} notes are heard. After them each voice goes back to its own last "
         "note, a rest (#R$C041), for ever: a player who waits hears the tune once and then "
         "silence, while the loop goes on reading the keyboard.",
         "Recorded: the game run from its first instruction in SkoolKit's simulator, no key "
         "held, stopped at TUNE_PLAY_NOTE's look-up of the two pitches ($C069) in each note "
         "and on to the next; from the call of #R$C000 to the first note both voices rest.",
         "Checked: " + _tune_check(full, tune) + "."],
        stats)

    # Two voices.
    lines += [
        "<h4>Two voices from one speaker</h4>",
        "<p>The speaker is one bit: on or off. #R$C049 makes two voices of it by taking turns. "
        f"Its loop runs {PASS * tune.passes:,} times a note, {TURN} T-states a time, and "
        "keeps two copies of the port byte, voice one's in A' and voice two's in A, each with "
        "its own countdown (E and L). Each turn it sends voice one's byte to port $FE, counts "
        "its countdown down and, if it has run out, reloads it from the voice's pitch and "
        "flips bit 4 in that voice's copy; 48 T-states later it does the same for voice two. "
        "So each voice is a square wave that flips every so many turns -- its pitch -- and "
        "the speaker spends the first half of every turn showing voice one's level and the "
        "second half voice two's. Where the voices agree the speaker stays put; where they "
        "differ it switches every 48 T-states, 36,458 times a second, far faster than the "
        "speaker cone or an ear can follow, and what is heard is the average: half. The "
        "result is the sum of the two square waves, each at half the volume -- a mix made "
        "in time rather than in voltage. For the mix to be fair both halves of the turn "
        "must be the same length whatever the countdowns do, and they are: the loop has two "
        "ways round (voice one's countdown run out or not), padded to 96 T-states each by "
        "two NOPs and a JR Z at $C09E that can never jump, and voice two's OUT comes at the "
        "same point on both.</p>",
        f'<p><img class="fl-diagram" src="images/sounds/voices.png" '
        f'width="{voices_picture["size"][0]}" height="{voices_picture["size"][1]}" '
        f'alt="The two voices\' port bytes, the speaker and its average over a turn"></p>',
        f"<p>Note {pick + 1} of the tune, drawn from its OUTs as the recording logged them: "
        f"voice one on note {logged['notes'][0]:+d} (a pitch of {logged['one']} turns, "
        f"{tune.note_hz(logged['notes'][0]):.0f} Hz) and voice two on note "
        f"{logged['notes'][1]:+d} ({logged['two']} turns, "
        f"{tune.note_hz(logged['notes'][1]):.0f} Hz). In the upper panel the speaker row is "
        "solid where it switches too fast to draw; in the close-up each tick is an OUT, and "
        "the switching shows turn by turn. The lowest row is the speaker averaged over one "
        "turn, which is how the recordings on this page are rendered (below).</p>",
        "<p>A voice that rests is not silent: its pitch is 1, so it flips every turn, a "
        "square wave at 18.2 kHz, above most people's hearing. In the mix it is there at "
        "half volume like any other note. The two recordings below are the opening with one "
        "voice resting throughout.</p>",
    ]
    for voice, solo in enumerate(solos):
        other = "two" if voice == 0 else "one"
        name = ("one", "two")[voice]
        lines += _item(
            f"voice_{name}", f"Voice {name} alone (the first {SOLO_NOTES} notes)",
            [f"Recorded: as the whole tune, with voice {other}'s "
             f"{len(tune.voices[1 - voice])} note bytes poked to {REST}, a rest, before the "
             f"game started, and stopped after {SOLO_NOTES} notes.",
             "Checked: " + _tune_check(solo, tune) + "."],
            f"{_length(solo['length'])}, {len(solo['edges']):,} edges")

    # The notes.
    lines += [
        "<h4>The notes</h4>",
        "<p>The tune's data is #R$C0B0. Its first eight bytes are two words for each "
        "voice: the address before its first note, which #R$C000 copies into the voice's "
        "pointer, VOICE_ONE_AT or VOICE_TWO_AT among #R$C01A(the tune's variables), and "
        "the address it goes back to after its end (its last note). "
        f"Then the pitch table (TUNE_NOTES, offset 8, {PITCHES} bytes), then voice one's "
        f"notes ended by ${END_MARK:02X}, then voice two's, "
        f"{len(tune.voices[0])} each. A note is one byte, a signed number of semitones "
        f"from {LOWEST} to 40 ($FB is -5), or {REST} for a rest, and every note lasts the "
        "same time: there are no lengths, a held note is the same note written again, and "
        "both voices step on together a note at a time, so the two lists are read side by "
        "side. #R$C026 takes a voice's next note and #R$C033 looks up its pitch, the byte at "
        "the note plus 12 in the table: the number of turns between two flips of the "
        "voice's bit. A wave is twice that, so a note of pitch P sounds at "
        f"3,500,000 / ({2 * TURN} P) Hz. A note lasts {tune.passes} passes of {PASS} turns "
        f"(256 less NOTE_LENGTH, ${256 - tune.passes:02X}), {tune.note_tstates():,} "
        f"T-states, and with the ROM's KEY-SCAN and the next note's set-up comes round every "
        f"{note_seconds:.4f} s -- {60 / note_seconds:.0f} a minute.</p>",
        f"<p>The pitches fall by about a semitone a step ($FF, $F0, $E3 ...), each close to "
        "0.944 of the one before, and whoever made the table rounded them to whole turns, so "
        "the highest notes, where a turn is a large part of the wave, are the least exact "
        f"(the top two, {top[0]} and {top[1]} turns, are {top_gap:.1f} semitones apart). "
        "Against the equal-tempered scale on A = 440 Hz, notes -12 to +24 come out "
        f"{sharp_low} to {sharp_high} cents (half of them {sharp_mid} or more) above the "
        "nearest note of it below them here -- close to half a semitone sharp. That is the simulator's "
        "Spectrum, which never holds up an OUT; a real one's ULA holds up every OUT to port "
        "$FE made while it is drawing the screen, which stretches the turns and flattens "
        "every note by an amount this page does not measure (the emulator this project "
        "uses does not model the delay either).</p>",
    ]
    lines += _table(["Note", "Index", "Pitch (turns)", "Frequency", "Scale note below it, cents above",
                     "Voice one plays it", "Voice two"], _pitch_rows(tune))
    lines += [
        f'<p><img class="fl-diagram" src="images/sounds/roll.png" width="{roll_size[0]}" '
        f'height="{roll_size[1]}" alt="Both voices of the loading tune, note by note"></p>',
        f"<p>The whole tune from its data, the first half above and the second below, a "
        f"column for each of the {tune.played} notes and a row for each semitone; a line "
        "every twelve semitones up from the lowest note, with its pitch. Voice two is the "
        f"upper voice, from note {lows[1]:+d} to {highs[1]:+d} ({rests[1]} rests); voice one "
        f"ranges from {lows[0]:+d} to {highs[0]:+d} ({rests[0]} rests): after two single "
        "notes it holds each note for eight, and then four, a slow bass up to note "
        f"{bass_end} (about {bass_end * note_seconds:.0f} s), and then moves more often with "
        "rests between, rising above voice two in "
        + _stretches(above, note_seconds)
        + f". The longest passage played twice is {run} notes long: notes "
        f"{at_one + 1} to {at_one + run} come again, both voices, as notes {at_two + 1} to "
        f"{at_two + run}.</p>",
    ]

    # The warble.
    lines += [
        "<h3>Never heard: the loader's warble</h3>",
    ]
    gaps = warble["gaps"]
    lines += _item(
        "warble", "The loading error",
        ["#R$DCC9 belongs to the loader, not the game: the Alkatraz loader jumps to it when "
         "the game's checksum does not match, which a good load never does, and it is left "
         "in memory only because the loader clears its own code and not this. It clears "
         "memory from itself down to $5B00, prints a request to rewind and reload the tape "
         "on the bottom line in flashing yellow, sets the border colour in BORDCR to black, "
         f"and then warbles {plan['times']} times: the ROM's BEEPER with DE = {de1} and "
         f"HL = {hl1}, {de1 + 1} waves at {beeper_hz(hl1):.1f} Hz "
         f"({note_name(beeper_hz(hl1))}), then with DE = {de2} and HL = {hl2}, {de2 + 1} "
         f"waves at {beeper_hz(hl2):.1f} Hz ({note_name(beeper_hz(hl2))}); then RST 0 "
         "resets the machine.",
         "Recorded: the routine called on a machine of its own built from the snapshot, "
         f"with the stack at ${LOADER_STACK:04X} in the loader's space (its real value at "
         "that point is not known; nothing in the routine depends on it) and the ROM's "
         "interrupt routine running, as it would once BEEPER turns interrupts on; from its "
         "first instruction to its RST 0.",
         f"Checked: {warble['calls']} calls of BEEPER, "
         + ("each" if warble["ok"] else "NOT each")
         + f" DE + 1 waves with every half-wave 4 HL + {BEEPER_HALF[1]} T-states "
         f"({BEEPER_HALF[0] * hl1 + BEEPER_HALF[1]:,} and {BEEPER_HALF[0] * hl2 + BEEPER_HALF[1]:,}),"
         " the timing worked out from BEEPER's instructions -- 5 T-states a wave less than "
         "the ROM's own comment on it (HL = 437500 / f - 30.125) implies. Each call's last "
         "wave is cut short: its off half ends when the next call's first OUT, which comes "
         f"almost at once, turns the speaker on again, {min(gaps):,} to {max(gaps):,} "
         "T-states later."],
        f"{_length(warble['length'])} (the clearing and printing included), "
        f"{len(warble['edges']):,} edges")

    lines += [
        "<h3>How these were recorded</h3>",
        "<p>Every recording is the game's own code running in SkoolKit's simulator, each "
        "change of bit 4 of port $FE logged to the T-state and rendered at 44100 Hz; nothing "
        "is synthesised. Each sample is the fraction of the 96 T-states centred on it (one "
        "turn of the tune's loop) that the speaker was on. Averaging over exactly one turn "
        "removes the 36 kHz switching between the voices completely, as the speaker would; "
        "SkoolKit's own writer averages over each sample's 79 T-states instead, and the "
        "switching then folds back into the audible range as a faint hiss near 7.5 kHz. "
        "The simulator has no contention, so on a real Spectrum everything here is a "
        "little slower and lower.</p>",
        "</div>",
    ]
    body = "\n".join(link(line, entries) for line in lines)
    for line in body.splitlines():
        if line.startswith((";", "[")):
            raise RuntimeError(f"a section line starts with {line[0]!r}: {line[:40]}")
    return body


def build(snapshot: Path, html_dir: Path, log=print) -> dict[str, str]:
    """Record the tune, its voices and the loader's warble into
    html_dir/audio, draw the pictures into html_dir/images/sounds, run the
    build's sessions to show that play is silent, and return the Sounds
    section."""
    audio = html_dir / "audio"
    images = html_dir / "images" / "sounds"
    audio.mkdir(parents=True, exist_ok=True)
    images.mkdir(parents=True, exist_ok=True)
    skool = snapshot.parent / "fairlight.skool"
    global SKOOL
    SKOOL = skool
    memory = list(bf.game_memory(snapshot))
    tune = Tune(memory)
    log("Recording Fairlight's sounds...")
    full = play_tune(snapshot, tune)
    # The note drawn: the first where both voices play and neither pitch is
    # a multiple of the other.
    pick = next(n for n in range(tune.played)
                if REST not in (tune.voices[0][n], tune.voices[1][n])
                and tune.pitch(tune.voices[0][n]) % tune.pitch(tune.voices[1][n])
                and tune.pitch(tune.voices[1][n]) % tune.pitch(tune.voices[0][n]))
    logged = play_tune(snapshot, tune, notes=pick + 1, log_note=pick)["log"]
    solos = []
    for voice in range(2):
        quiet = 1 - voice
        pokes = {tune.first[quiet] + n: REST for n in range(len(tune.voices[quiet]))}
        poked = list(memory)
        for where, value in pokes.items():
            poked[where] = value
        solos.append(play_tune(snapshot, Tune(poked), pokes, notes=SOLO_NOTES))
    warble = record_warble(snapshot)
    log("  playing the build's sessions for any other sound...")
    sessions = play_sessions(snapshot)
    listing = listing_ports(skool)
    recordings = [("tune", full), ("voice_one", solos[0]), ("voice_two", solos[1]),
                  ("warble", warble)]
    for name, result in recordings:
        if not result["edges"]:
            raise RuntimeError(f"{name}: no sound was made")
        write_wav(audio / f"{name}.wav", result["edges"], result["length"])
    voices_picture = draw_voices(logged, images / "voices.png")
    note_seconds = full["length"] / full["notes"] / TSTATES_PER_SECOND
    roll_size = draw_roll(tune, note_seconds, images / "roll.png")
    failed = [name for name, result in recordings[:3] if result["matched"] != result["notes"]]
    if not warble["ok"]:
        failed.append("warble")
    if full.get("tail"):
        failed.append("tune (not silent after its end)")
    others = sorted({pc for s in sessions for pc, _ in s["outs"]
                     if not TUNE_PLAY_NOTE <= pc < TUNE_VOICES})
    if others:
        failed.append("sessions (OUTs outside the tune: "
                      + ", ".join(f"${pc:04X}" for pc in others) + ")")
    if failed:
        log(f"  WARNING: recordings that did not match the code: {', '.join(failed)}")
    log(f"  {len(recordings)} sounds written to {audio}")
    return {"Sounds": _section(tune, full, solos, logged, voices_picture, roll_size, warble,
                               sessions, listing, skool_entries())}
