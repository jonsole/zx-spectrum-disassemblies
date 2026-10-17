"""Cyberun's sounds, recorded from the game's own code at build time.

build_cyberun.py --html calls build(), which writes a WAV of every tune and
sound effect into the HTML directory's sounds/ folder and returns the Sounds
section. Nothing here is committed output: the sounds are the game's, and
every byte this reads comes from the snapshot.

A 48K Spectrum has one bit of sound hardware, bit 4 of port $FE, and every
noise Cyberun makes is its code setting and clearing that bit (OUT ($FE) with
$10, then 0, so the border stays black) with the processor counting in
between: there is no interrupt, so a sound plays in full, at once, inside the
pass that asks for it. A sound is recorded by running the code that makes it
in SkoolKit's simulator with a tracer that notes the T-state of every OUT to
port $FE that changes bit 4. The gaps between those edges are the waveform,
which SkoolKit's audio writer renders to a WAV at 44100 Hz. Nothing is
synthesised: every edge in every file is an OUT the game executed.

Two kinds of recording:

- A call. The routine that makes the sound, called on a machine of its own:
  the snapshot run through its start-up to the menu (so that everything the
  start-up builds is in place), then the registers and bytes the routine
  reads set, and a return address that stops the run. A fresh copy of that
  machine for each call. Every effect and every tune is recorded this way,
  and each recording is checked wave by wave against what the code says it
  should make: the half-wave counts the routine works out from its inputs
  (a Python model of each routine, below), turned into T-states by the
  instruction timings of the loops that time them.
- A run. The game itself, played in the simulator by the build's own
  sessions (build_cyberun's _start, new_life_at, restart_at and the rest):
  a game starting, a flight with every add-on, a death, a game over, the
  rocket's launch. Each OUT is noted with the return addresses on the stack,
  which split the edges into the bursts each call of an effect made; every
  burst is then matched against the models of every effect, over all the
  inputs it could have, and against the tunes' call recordings -- so a run
  says which effects it holds and that each is, wave for wave, one the code
  can make.

The simulator has no memory contention. The effects' code ($71D3-$731E) lies
below $8000, in the RAM the ULA contends while it draws the screen, so on a
real 48K they run somewhat slower and lower than recorded here; the tune
player and its table ($9A9A-$9BC2) are above $8000 and are not slowed.
"""
from __future__ import annotations

import html
import math
import re
from pathlib import Path

import build_cyberun as bc

TSTATES_PER_SECOND = bc.TSTATES_PER_SECOND
SKOOL = bc.OUT_DIR / "cyberun.skool"
SOUNDS_DIR = "sounds"

# --------------------------------------------------------------------------
# The sound code (see the entries).
# --------------------------------------------------------------------------

BEEP_PULSE = 0x71D3
BEEP_CYCLE = 0x71E0
SOUND_RISING_WHINE = 0x71F0
RISING_SWEEP = 0x71F4
SOUND_PICK_UP = 0x71FE
SOUND_UNUSED = 0x7204
SOUND_DEBRIS = 0x720A
WARBLE = 0x7217
SOUND_FLUTTER = 0x7234
SOUND_ZAP = 0x724C
ZAP_SWEEP = 0x724E
SOUND_SHIP_COLOUR = 0x725C
SOUND_BUZZ = 0x7263
SOUND_HUM = 0x7275
SOUND_CRACKLE = 0x7293
CRACKLE = 0x7297
SOUND_TICK = 0x72A5
SOUND_DEATH = 0x72AB
SOUND_BEAMS = 0x72CF
SOUND_CRACKLE_B = 0x72F2
SOUND_LAUNCH = 0x7303
SOUND_FIRE = 0x7311
SOUND_COLLECT = 0x7318
SOUND_CODE_END = 0x731F        # the first byte after sound_collect

# The OUTs: which of them made an edge says which building block it was.
PULSE_OUTS = (0x71D5, 0x71DA)  # beep_pulse's on and off
CYCLE_OUTS = (0x71E2, 0x71E9)  # beep_cycle's
NOTE_OFF_OUT, NOTE_ON_OUT = 0x9ADC, 0x9AE7   # play_note's

PLAY_TUNE_UNTIL_KEY = 0x9A9A
PLAY_TUNE = 0x9AA9
PLAY_NOTE = 0x9AB4
NOTE_TABLE = 0x9B0C
NOTE_ROWS = 61
PLAYERS_END = NOTE_TABLE       # the tune players run from $9A9A up to the table

DEATH_COUNT = bc.DYING         # death_count, $8F53
PASS_COUNTER = 0x9A64          # pass_counter: its low byte is what the sounds read

# The tunes, and who plays them.
TITLE_TUNE = 0x70D8
START_TUNE = 0xF4E4
DEATH_TUNE = 0xF4DD
LEVEL_TUNE = 0xF56A
GAME_OVER_TUNE = 0xF580

# A scratch record for the routines that read one through IX (the debris
# piece's +$15, the beam's +0 to +2, the shot's and the attacker's +$16):
# in the printer buffer's top, which nothing in a call touches.
SCRATCH_RECORD = 0x5BC0

# A call's stack, and the return address that stops it: below the game's
# own stack in the printer buffer, and an address no sound code runs.
CALL_STACK = 0x5BB0
STOP = 0x0001
CALL_LIMIT = 120 * TSTATES_PER_SECOND

# An effect's half-waves are at most 13 x 256 T-states and the loops' own
# instructions; a gap longer than this between two edges with the same
# return addresses is two calls of the effect, not one.
BURST_GAP = 5000

# --------------------------------------------------------------------------
# The building blocks' timing, from the instruction timings (Z80 T-states:
# DJNZ 13 taken and 8 not, so B turns of it take 13B - 5; OUT (n),A 11; CALL
# 17; RET 10; JR 12 taken and 7 not; RET Z 5 not taken). An edge-to-edge
# interval is everything executed from one OUT to the next.
# --------------------------------------------------------------------------
#
# beep_cycle ($71E0) on: LD A,B, B turns of DJNZ, LD B,A, XOR A and the OUT
# that turns it off: 13B + 18. Off: LD A,B, DJNZ, LD B,A, RET, the caller's
# loop, its CALL, and LD A,$10 and the OUT that turns it on: 13B + 48 plus
# the caller's loop.
CYCLE_ON = 18
CYCLE_OFF = 48
# beep_pulse ($71D3) on: DJNZ, XOR A, OUT: 13B + 10. Off: LD B,D, D turns of
# DJNZ, RET, the caller's loop, its CALL, LD A,$10 and OUT: 13D + 44 plus
# the caller's loop.
PULSE_ON = 10
PULSE_OFF = 44
# The callers' loops between one CALL's return and the next CALL:
# rising_sweep: DEC C, JR NZ, LD A,C, ADD A,D, LD B,A.
SWEEP_LOOP = 4 + 12 + 4 + 4 + 4
# warble: DEC C, JR NZ, LD A,B, XOR $2A, LD B,A.
WARBLE_LOOP = 4 + 12 + 4 + 7 + 4
# sound_flutter: DEC D, RET Z, DEC D, RET Z, JR, LD A,D, XOR 7, INC A, LD B,A.
FLUTTER_LOOP = 4 + 5 + 4 + 5 + 12 + 4 + 7 + 4 + 4
# zap_sweep: DEC C, JR NZ, LD A,C, ADD A,A twice, CPL, AND $7F, LD B,A.
ZAP_LOOP = 4 + 12 + 4 + 4 + 4 + 4 + 7 + 4
# sound_buzz: DEC C, JR NZ, LD A,C, XOR 2, AND 4, ADD A,A three times, LD B,A.
BUZZ_LOOP = 4 + 12 + 4 + 7 + 7 + 4 + 4 + 4 + 4
# crackle: DEC C, JR NZ, LD A,C, XOR E, ADD A,A, LD B,A, AND $1F, LD D,A.
CRACKLE_LOOP = 4 + 12 + 4 + 4 + 4 + 4 + 7 + 4
# sound_beams: DEC C, JR NZ, LD A,C, ADD A,E, AND 15, ADD A,A, LD B,A, LD A,E,
# ADD A,B, ADD A,A, SUB B, LD D,A.
BEAMS_LOOP = 4 + 12 + 4 + 4 + 7 + 4 + 4 + 4 + 4 + 4 + 4 + 4
# play_note ($9AB4) times each half-wave with B turns of DJNZ, then C - 1
# more passes of 256 turns, each with DEC C and JR NZ: D = 13B + 3339C -
# 3333. Off is D + 39 (POP BC, PUSH BC, LD A,$10, OUT) and on is D + 62 (POP
# BC, DEC HL, LD A,H, OR L, JR NZ, PUSH BC, XOR A, OUT).
NOTE_OFF, NOTE_ON = 10 + 11 + 7 + 11, 10 + 6 + 4 + 4 + 12 + 11 + 4 + 11
# A rest: BC from $430B down to 0 in a loop of DEC BC, LD A,B, OR C and JR NZ.
REST_COUNT = 0x430B
REST_LOOP = 6 + 4 + 4 + 12

NAMES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]


def _esc(text: str) -> str:
    return html.escape(text, quote=False)


def _hz(tstates: float) -> float:
    return TSTATES_PER_SECOND / tstates


def _count(value: int) -> int:
    """A DJNZ counter's value as a number of turns: 0 is 256."""
    value &= 0xFF
    return value or 256


def _length(tstates: int) -> str:
    seconds = tstates / TSTATES_PER_SECOND
    return f"{seconds * 1000:.0f}&nbsp;ms" if seconds < 1 else f"{seconds:.2f}&nbsp;s"


# --------------------------------------------------------------------------
# The models: what each routine makes, worked out from its code. A wave is
# (on, off) in T-states; the last wave of a call, and the last of each part
# of a call made of several (the death sound), has off None, because it runs
# on into whatever the code does next.
# --------------------------------------------------------------------------

def _cycles(halves: list[int], loop: int) -> list:
    waves = [(13 * _count(b) + CYCLE_ON, 13 * _count(b) + CYCLE_OFF + loop) for b in halves]
    if waves:
        waves[-1] = (waves[-1][0], None)
    return waves


def _pulses(lengths: list[tuple[int, int]], loop: int) -> list:
    waves = [(13 * _count(b) + PULSE_ON, 13 * _count(d) + PULSE_OFF + loop) for b, d in lengths]
    if waves:
        waves[-1] = (waves[-1][0], None)
    return waves


def sweep(c: int, d: int) -> list:
    """rising_sweep ($71F4): C cycles of half period C + D, C counting down."""
    return _cycles([(k + d) & 0xFF for k in range(c, 0, -1)], SWEEP_LOOP)


def zap(c: int) -> list:
    """zap_sweep ($724E): C cycles of half period (NOT 4C) AND $7F."""
    return _cycles([~(4 * k) & 0x7F for k in range(c, 0, -1)], ZAP_LOOP)


def warble(a: int) -> list:
    """warble ($7217): nothing for 16 and over, nor 7 and 8; else four
    cycles, B toggled by $2A before each, from 2A + $48."""
    if a >= 16 or a in (7, 8):
        return []
    b = (2 * (a & 15) + 0x48) & 0xFF
    halves = []
    for _ in range(4):
        b ^= 0x2A
        halves.append(b)
    return _cycles(halves, WARBLE_LOOP)


def flutter(passes: int) -> list:
    """sound_flutter ($7234): D = 8 x (1 + the pass's low three bits), a
    cycle of (D XOR 7) + 1 for each D as it counts down by two."""
    d = 8 * ((passes & 7) + 1)
    halves = []
    while True:
        halves.append(((d ^ 7) + 1) & 0xFF)
        d -= 1
        if d == 0:
            break
        d -= 1
        if d == 0:
            break
    return _cycles(halves, FLUTTER_LOOP)


def buzz() -> list:
    """sound_buzz ($7263): 15 cycles of ((C XOR 2) AND 4) x 8, C 15 down."""
    return _cycles([((k ^ 2) & 4) * 8 for k in range(15, 0, -1)], BUZZ_LOOP)


def crackle(c: int, e: int) -> list:
    """crackle ($7297): C clicks, B = 2(C XOR E) on and B AND $1F off."""
    lengths = []
    for k in range(c, 0, -1):
        b = (2 * (k ^ e)) & 0xFF
        lengths.append((b, b & 0x1F))
    return _pulses(lengths, CRACKLE_LOOP)


def hum(passes: int, bit6: bool) -> list:
    """sound_hum ($7275): odd passes only; four cycles from $13, or with +$16
    bit 6 three from $1E when the pass's low two bits are 0."""
    if passes & 1 == 0:
        return []
    if not bit6:
        return sweep(4, 0x0F)
    if passes & 3:
        return []
    return sweep(3, 0x1B)


def death(count: int) -> list:
    """sound_death ($72AB): nothing from $2D; the warble with the count less
    10, then on a multiple of 8 a seven-cycle zap, on other odd counts
    eleven clicks scrambled by the count halved."""
    if count >= 0x2D:
        return []
    waves = warble((count - 10) & 0xFF)
    if count & 7 == 0:
        waves += zap(7)
    elif count & 1:
        waves += crackle(11, count >> 1)
    return waves


def debris(step: int) -> list:
    """sound_debris ($720A), alive (death_count below 10): the warble with
    the piece's path step (+$15, bits 0-5) halved."""
    return warble((step & 0x3F) >> 1)


def beams(mix: int, e: int) -> list:
    """sound_beams ($72CF): mix = (+0 XOR +1) AND 15 and e = +2 AND $1F;
    mix + 8 pulses of B = ((C + E) AND 15) x 2 on and 2(E + B) - B off."""
    lengths = []
    for k in range(mix + 8, 0, -1):
        b = ((k + e) & 15) * 2
        lengths.append((b, (2 * (e + b) - b) & 0xFF))
    return _pulses(lengths, BEAMS_LOOP)


def launch(a: int) -> list:
    """sound_launch ($7303): C = 4(A + 2) clicks, scramble (NOT C + 6) AND $1F."""
    c = 4 * (a + 2)
    return crackle(c, (~c + 6) & 0x1F)


# --------------------------------------------------------------------------
# The effects. For each: the file it is written to, its entry, what the
# listing calls it, what plays it and when (read from the listing: every
# CALL or JP to it), the calls that record it, and the inputs it can have,
# which the runs' bursts are matched over.
# --------------------------------------------------------------------------

class Effect:
    def __init__(self, name, entry, title, played, calls, domain, how):
        self.name, self.entry, self.title, self.played = name, entry, title, played
        # Each call: (registers, pokes, the inputs, for the model).
        self.calls = calls
        # Every input the effect can have -> its model's waves.
        self.domain = domain
        self.how = how


def _effects() -> list[Effect]:
    fixed = lambda waves: {(): waves}
    plain = lambda: [({}, {}, ())]
    effects = [
        Effect("whine", SOUND_RISING_WHINE, "Rising whine",
               "#R$DD79 jumps to it as the fly-in of a new life ends and play begins.",
               plain(), fixed(sweep(0x20, 0x70)),
               "called once"),
        Effect("pick_up", SOUND_PICK_UP, "Pick-up chirp",
               "#R$AAD7, when the ship takes an add-on or a rocket part.",
               plain(), fixed(sweep(0x10, 0x40)),
               "called once"),
        Effect("unused", SOUND_UNUSED, "Unused crackle",
               "Nothing: no CALL or JP in the game reaches it.",
               plain(), fixed(crackle(0x17, 0x17)),
               "called once"),
        Effect("debris", SOUND_DEBRIS, "Debris",
               "#R$96D8, for each piece of debris each pass while #R$8F53 is below 10: "
               "the piece's path step (+$15) halved picks the note.",
               [({"IX": SCRATCH_RECORD}, {SCRATCH_RECORD + 0x15: 2 * n, DEATH_COUNT: 0}, (2 * n,))
                for n in range(16)],
               {(step,): debris(step) for step in range(64)},
               "called sixteen times, a pass apart, with the path step giving notes 0 "
               "to 15 in turn (7 and 8 are silent)"),
        Effect("flutter", SOUND_FLUTTER, "Special beam flutter",
               "#R$B414, each pass while the special beam is out (its record's +$0E not 0).",
               [({}, {PASS_COUNTER: p}, (p,)) for p in range(8)],
               {(p,): flutter(p) for p in range(8)},
               "called eight times, a pass apart, with the pass counter's low bits 0 to 7"),
        Effect("zap", SOUND_ZAP, "Falling zap",
               "The commonest: #R$8F54 (damage, and a shielded ship ramming), #R$8E2D (the "
               "shield starting), #R$9015 (the fuel thief), #R$9020 (an extra life), #R$917C "
               "(a shot hits), #R$94A8 (the tough attacker destroyed), #R$9572 (the ship "
               "docks with the rocket), and #R$83D6 for each 5000 of the planet bonus.",
               plain(), fixed(zap(16)),
               "called once"),
        Effect("ship_colour", SOUND_SHIP_COLOUR, "Ship colour",
               "#R$F1BD, when the ship's colour changes: white, yellow with the ore tank "
               "full, cyan with the shield on.",
               plain(), fixed(sweep(0x0A, 0x80)),
               "called once"),
        Effect("buzz", SOUND_BUZZ, "Buzz",
               "#R$BA8F when the ship hits a wall, and #R$BCD1 on its first pass on a slope.",
               plain(), fixed(buzz()),
               "called once"),
        Effect("hum", SOUND_HUM, "Tough attacker's hum",
               "#R$94A8, the update routine of the tough attacker (type $19), every pass.",
               [({"IX": SCRATCH_RECORD}, {PASS_COUNTER: p, SCRATCH_RECORD + 0x16: 0}, (p, False))
                for p in range(8)],
               {(p, bit6): hum(p, bit6) for p in range(8) for bit6 in (False, True)},
               "called eight times, a pass apart, with the pass counter's low bits 0 "
               "to 7 and the record's +$16 bit 6 clear: the even passes are silent"),
        Effect("crackle", SOUND_CRACKLE, "Crackle",
               "#R$BA8F, when the ship bumps a floor or a ceiling.",
               plain(), fixed(crackle(0x1C, 0x27)),
               "called once"),
        Effect("tick", SOUND_TICK, "Tick",
               "#R$90A7 when an object blows up on the landscape, and #R$B6F2 when a laser "
               "shot meets it.",
               plain(), fixed(crackle(8, 3)),
               "called once"),
        Effect("death", SOUND_DEATH, "Death",
               "#R$8D42 each pass while #R$8F53 runs from 10 to $2C: the 35 passes after "
               "the ship breaks up.",
               [({}, {DEATH_COUNT: d}, (d,)) for d in range(10, 0x2D)],
               {(d,): death(d) for d in range(10, 0x2D)},
               "called 35 times, a pass apart, with #R$8F53 from 10 to $2C as the "
               "passes of a death give it"),
        Effect("beams", SOUND_BEAMS, "Beams",
               "The end of #R$9BDA, on a pass when it has drawn a beam: the beam's record "
               "(+0, +1, +2) sets the sound.",
               None,    # set by build() from the beams heard in the add-ons run
               {(mix, e): beams(mix, e) for mix in range(16) for e in range(32)},
               ""),
        Effect("crackle_b", SOUND_CRACKLE_B, "Shot",
               "#R$B731 when it fires: a laser shot, or with bit 7 of the record's +$16 "
               "set (a homing missile) a longer one.",
               [({"IX": SCRATCH_RECORD}, {SCRATCH_RECORD + 0x16: 0}, (False,)),
                ({"IX": SCRATCH_RECORD}, {SCRATCH_RECORD + 0x16: 0x80}, (True,))],
               {(False,): crackle(0x0F, 0x17), (True,): crackle(0x17, 0x20)},
               "called twice, a pass apart: the laser shot (+$16 bit 7 clear), then the "
               "missile's (set)"),
        Effect("launch", SOUND_LAUNCH, "Launch",
               "#R$9572 each pass while the rocket rises, with the pass counter's low two "
               "bits in A.",
               [({"A": a & 3}, {}, (a & 3,)) for a in range(8)],
               {(a,): launch(a) for a in range(4)},
               "called eight times, a pass apart, with A from 0 to 3 twice over"),
        Effect("fire", SOUND_FIRE, "Fire",
               "#R$882B, when a ground object or an attacker fires a bullet or throws a "
               "pick-up.",
               plain(), fixed(crackle(0x0A, 0x22)),
               "called once"),
        Effect("collect", SOUND_COLLECT, "Collect",
               "#R$900B, when an object is collected by touch (contact effect bit 3).",
               plain(), fixed(sweep(0x0A, 0x18)),
               "called once"),
    ]
    return effects


TUNES = [
    ("tune_title", TITLE_TUNE, PLAY_TUNE_UNTIL_KEY, "Title",
     "#R$F26C, as the menu is first shown, through #R$9A9A: any key stops it between "
     "two notes."),
    ("tune_start", START_TUNE, PLAY_TUNE, "Start of a game",
     "#R$F26C, as the menu ends with 0 pressed, through #R$9AA9: the game waits for it."),
    ("tune_death", DEATH_TUNE, PLAY_TUNE, "Death",
     "#R$F440, at the end of the death sequence, before the next life."),
    ("tune_level", LEVEL_TUNE, PLAY_TUNE, "Planet secured",
     "#R$F52A, after the planet-secured screen, before the next planet."),
    ("tune_game_over", GAME_OVER_TUNE, PLAY_TUNE, "Game over",
     "#R$F4FC, under PLAYER n GAME OVER."),
]


# --------------------------------------------------------------------------
# Recording.
# --------------------------------------------------------------------------

def _tracer_class():
    from skoolkit.simutils import D, E, PC, SP, T

    base = bc._key_tracer_class()

    class SoundTracer(base):
        """bc's KeyTracer, which reports held keys and a stick, and also
        every change of the speaker bit: its T-state, the OUT's address, DE
        (the tune pointer, in play_note) and the top of the stack (the return
        addresses that say which call made it)."""

        def __init__(self, simulator):
            super().__init__(simulator)
            self.memory = simulator.memory
            self.speaker = 0
            self.edges = []
            self.write_port = self._write

        def _write(self, registers, port, value, offset=0):
            if port & 1 == 0 and (value & 0x10) != self.speaker:
                self.speaker = value & 0x10
                sp = registers[SP]
                memory = self.memory
                stack = tuple(memory[(sp + 2 * i) & 0xFFFF] | memory[(sp + 2 * i + 1) & 0xFFFF] << 8
                              for i in range(4))
                self.edges.append((registers[T], registers[PC],
                                   registers[D] << 8 | registers[E], stack))

    return SoundTracer


def _menu_machine(snapshot: Path) -> list:
    """The snapshot run through its start-up to the menu, the title tune cut
    short: the memory every call starts from."""
    machine = bc.Machine(snapshot)
    machine.play([bc.At("the menu", bc.MENU_LOOP, 120.0, bc.TUNE_KEYS)], "sounds: the menu")
    return list(machine.memory)


def call(base: list, address: int, registers=None, pokes=None) -> tuple[list[int], int]:
    """Call the routine at `address` on a fresh copy of `base`: its speaker
    edges, in T-states from the call, and how long it ran until it
    returned."""
    from skoolkit import CSimulator
    from skoolkit.simulator import Simulator
    from skoolkit.simutils import PC, SP, T
    import skoolkit.simutils as su

    memory = list(base)
    for where, value in (pokes or {}).items():
        memory[where] = value
    memory[CALL_STACK:CALL_STACK + 2] = [STOP & 0xFF, STOP >> 8]
    simulator = (CSimulator or Simulator)(memory, state={"iff": 0, "im": 1, "tstates": 0})
    tracer = _tracer_class()(simulator)
    simulator.set_tracer(tracer)
    for name, value in (registers or {}).items():
        if name in ("IX", "DE", "HL", "BC"):
            high, low = {"IX": ("IXh", "IXl")}.get(name, (name[0], name[1]))
            simulator.registers[getattr(su, high)] = value >> 8
            simulator.registers[getattr(su, low)] = value & 0xFF
        else:
            simulator.registers[getattr(su, name)] = value
    simulator.registers[SP] = CALL_STACK
    simulator.trace(address, STOP, 0, CALL_LIMIT, False, None, None, None, None, None)
    if simulator.registers[PC] != STOP:
        raise RuntimeError(f"the call to ${address:04X} did not return")
    return [edge[0] for edge in tracer.edges], simulator.registers[T]


def in_a_row(calls: list, gap: int) -> tuple[list[int], int]:
    """Several calls' recordings end to end, each starting `gap` T-states
    after the one before started (a pass apart), or when it ended if it ran
    longer than that."""
    edges, start, length = [], 0, 0
    for call_edges, call_length in calls:
        edges += [start + t for t in call_edges]
        length = start + call_length
        start += max(gap, call_length)
    return edges, length


def halves(edges: list[int]) -> tuple[list[int], list[int]]:
    """The on and off half-waves: the speaker starts off, so edges go on,
    off, on... An off half-wave is measured to the next on edge."""
    on = [edges[i + 1] - edges[i] for i in range(0, len(edges) - 1, 2)]
    off = [edges[i + 1] - edges[i] for i in range(1, len(edges) - 1, 2)]
    return on, off


def matches(edges: list[int], waves: list) -> bool:
    """Whether a call's edges are exactly the model's waves: every on
    half-wave, and every off half-wave the model times."""
    if len(edges) != 2 * len(waves):
        return False
    on, off = halves(edges)
    for i, (want_on, want_off) in enumerate(waves):
        if on[i] != want_on:
            return False
        if want_off is not None and i < len(off) and off[i] != want_off:
            return False
    return True


def _pitch_range(edges: list[int], waves: list) -> tuple:
    """The lowest and highest pitch of the waves inside a call, each wave on
    plus off, measured from the edges: (tones, clicks), the square waves of
    beep_cycle and the pulses of beep_pulse apart, each (low, high) or None.
    Which block made a wave its on half-wave says: 13B + 18 or 13B + 10."""
    on, off = halves(edges)
    tones, clicks = [], []
    for i, (want_on, want_off) in enumerate(waves):
        if want_off is None or i >= len(off):
            continue
        hz = _hz(on[i] + off[i])
        (tones if (want_on - CYCLE_ON) % 13 == 0 else clicks).append(hz)
    return ((min(tones), max(tones)) if tones else None,
            (min(clicks), max(clicks)) if clicks else None)


def _widen(a, b):
    if a is None:
        return b
    if b is None:
        return a
    return min(a[0], b[0]), max(a[1], b[1])


def _write_wav(path: Path, edges: list[int], length: int) -> None:
    """Render the speaker edges to a WAV. SkoolKit's writer takes the gaps
    between flips, starting from the speaker off; a recording that ends with
    the speaker on (every tune does: play_note ends each wave on) is turned
    off where it ends."""
    from skoolkit.audio import BeeperOptions
    from skoolkit.components import get_audio_writer

    edges = list(edges)
    if len(edges) % 2:
        edges.append(max(length, edges[-1] + 1))
    delays = [max(edges[0], 1)] + [b - a for a, b in zip(edges, edges[1:])]
    if length > edges[-1]:
        delays.append(length - edges[-1])
    delays = [max(d, 1) for d in delays]
    with open(path, "wb") as f:
        get_audio_writer().write_audio(f, delays, BeeperOptions(100, False, False, 0, False))


# --------------------------------------------------------------------------
# The tunes.
# --------------------------------------------------------------------------

def note_rows(memory) -> list[tuple[int, int, int]]:
    """Each entry of the note table: B and C, which time a half-wave, and
    the cycles in a unit."""
    return [tuple(memory[NOTE_TABLE + 3 * row:NOTE_TABLE + 3 * row + 3]) for row in range(NOTE_ROWS)]


def note_d(b: int, c: int) -> int:
    return 13 * _count(b) + 3339 * _count(c) - 3333


def note_period(b: int, c: int) -> int:
    return 2 * note_d(b, c) + NOTE_OFF + NOTE_ON


def tune_notes(memory, address: int) -> list[tuple[int, int]]:
    """(entry, units) for each note byte up to the $FF."""
    notes = []
    while memory[address] != 0xFF:
        notes.append((memory[address] & 0x3F, (memory[address] >> 6) + 1))
        address += 1
    return notes


def _repeats(rows) -> list[int]:
    """The entries whose B and C are the entry before's: the same pitch."""
    return [row for row in range(2, NOTE_ROWS) if rows[row][:2] == rows[row - 1][:2]]


def _scale(rows) -> tuple[int, float]:
    """The equal-tempered scale (A4 = 440 Hz) the table is nearest: the
    MIDI number of entry 0, so that entry n is note n + offset, and the
    worst error of entries 1-60 from it, in cents, leaving out the entries
    that repeat the one before."""
    repeats = _repeats(rows)
    best = None
    for offset in range(0, 60):
        worst = 0.0
        for row in range(1, NOTE_ROWS):
            if row in repeats:
                continue
            worst = max(worst, abs(_cents(_hz(note_period(*rows[row][:2])), row + offset)))
        if best is None or worst < best[1]:
            best = (offset, worst)
    return best


def _cents_from_scale(values: dict[int, float]) -> dict[int, float]:
    """Each entry's distance in cents from the semitone series that fits
    the values (pitches, or the reciprocals of periods) best, worst error
    least."""
    first = min(values)
    raw = {row: 1200 * math.log2(value / values[first]) - 100 * (row - first)
           for row, value in values.items()}
    middle = (max(raw.values()) + min(raw.values())) / 2
    return {row: cents - middle for row, cents in raw.items()}


def _loop_scale(rows) -> tuple[float, float, float]:
    """How the table looks counted in loops, as its own description has it
    (256(C - 1) + B turns of a DJNZ): the worst distance in cents from a
    semitone series; and, for the pitches played, how far entry 1 and
    entry 60 lie from the series that fits them."""
    repeats = _repeats(rows)
    loops = {row: 1 / (256 * (rows[row][1] - 1) + _count(rows[row][0]))
             for row in range(1, NOTE_ROWS) if row not in repeats}
    played = {row: _hz(note_period(*rows[row][:2])) for row in loops}
    by_loops = _cents_from_scale(loops)
    by_pitch = _cents_from_scale(played)
    return (max(abs(c) for c in by_loops.values()), by_pitch[1], by_pitch[NOTE_ROWS - 1])


def note_name(midi: int) -> str:
    return f"{NAMES[midi % 12]}{midi // 12 - 1}"


def _cents(hz: float, midi: int) -> float:
    return 1200 * math.log2(hz / (440 * 2 ** ((midi - 69) / 12)))


def _tune_waves(notes, rows) -> list:
    """The waves play_note makes for a tune: each note's half-waves from its
    B and C; the last wave of each note runs into the next note's set-up."""
    waves = []
    for row, units in notes:
        if row == 0:
            continue
        b, c, per_unit = rows[row]
        d = note_d(b, c)
        count = per_unit * units
        # Off then on: the first OUT of a note turns the speaker off.
        waves += [(d + NOTE_OFF, d + NOTE_ON)] * (count - 1) + [(d + NOTE_OFF, None)]
    return waves


def _tune_check(edges: list[int], notes, rows) -> tuple[bool, str]:
    """Every half-wave of a tune's recording against the note table and
    play_note's timing."""
    waves = _tune_waves(notes, rows)
    # The very first OUT turns off a speaker already off: no edge. From the
    # next, an edge on, then off, ... each note's first off edge ends the
    # last note's on half-wave.
    ok = len(edges) == 2 * len(waves) - 1
    if ok:
        intervals = [b - a for a, b in zip(edges, edges[1:])]
        # intervals[0] is the first note's first on; then off, on, ...
        expect = []
        for i, (off, on) in enumerate(waves):
            if i:
                expect.append(off)
            expect.append(on)
        expect = expect[:len(intervals)]
        ok = all(want is None or got == want for got, want in zip(intervals, expect))
    return ok, (f"{len(waves):,} waves, {len(edges):,} edges, "
                + ("every half-wave the length the note table and #R$9AB4's loops give it"
                   if ok else "NOT every half-wave the length the note table gives"))


def _note_measurements(edges: list[int], notes, rows) -> dict[int, list[float]]:
    """The recorded pitch of every note of a tune, by entry: the mean of its
    whole waves, measured from the edges."""
    out = {}
    position = 0      # index into edges of the note's first on edge
    for index, (row, units) in enumerate(notes):
        if row == 0:
            continue
        count = rows[row][2] * units
        # The note's edges: on, off, on ... from `position`; its first
        # off edge belongs to the previous note's boundary (none for the
        # first note).
        first = position if index == 0 else position
        periods = []
        for k in range(count - 1):
            a = first + 2 * k
            if a + 2 < len(edges):
                periods.append(edges[a + 2] - edges[a])
        if periods:
            out.setdefault(row, []).append(_hz(sum(periods) / len(periods)))
        position += 2 * count
    return out


# --------------------------------------------------------------------------
# Runs of the game: bursts, and what each one is.
# --------------------------------------------------------------------------

def _return_address(edge) -> int:
    """The first return address on the stack outside the sound code and the
    tune players: where the call that made this edge goes back to in the
    game."""
    _, pc, _, stack = edge
    words = stack[1:] if pc in (NOTE_OFF_OUT, NOTE_ON_OUT) else stack   # play_note pushed BC
    for word in words:
        if not (BEEP_PULSE <= word < SOUND_CODE_END or PLAY_TUNE_UNTIL_KEY <= word < PLAYERS_END):
            return word
    return -1


def _tune_at(pointer: int, tunes: list) -> str | None:
    for tune in tunes:
        if tune["entry"] <= pointer <= tune["end"]:
            return tune["name"]
    return None


def bursts(edges: list, tunes: list) -> list[dict]:
    """Split a run's edges into the calls that made them: a new burst where
    the return address on the stack changes, where a tune changes, or where
    an effect's edges are further apart than any of its half-waves."""
    out = []
    for edge in edges:
        t, pc, de, _ = edge
        tune = _tune_at(de, tunes) if pc in (NOTE_OFF_OUT, NOTE_ON_OUT) else None
        key = ("tune", tune) if pc in (NOTE_OFF_OUT, NOTE_ON_OUT) else ("effect", _return_address(edge))
        last = out[-1] if out else None
        if (last is None or last["key"] != key
                or (key[0] == "effect" and t - last["edges"][-1] > BURST_GAP)):
            out.append({"key": key, "edges": [t], "pcs": [pc]})
        else:
            last["edges"].append(t)
            last["pcs"].append(pc)
    return out


# CALL nn and the conditional CALLs.
CALL_OPCODES = {0xCD, 0xC4, 0xCC, 0xD4, 0xDC, 0xE4, 0xEC, 0xF4, 0xFC}
# The routines that end by jumping to an effect rather than calling it:
# called themselves, they are what the stack shows.
JUMPS_TO = {0xDD79: SOUND_RISING_WHINE, 0x8E2D: SOUND_ZAP, 0x9572: SOUND_ZAP,
            0x9BDA: SOUND_BEAMS, 0xB731: SOUND_CRACKLE_B}


def _called(memory, ret: int) -> tuple[int | None, int | None]:
    """The CALL that pushed a return address: (its target, its address)."""
    site = (ret - 3) & 0xFFFF
    if ret > 0 and memory[site] in CALL_OPCODES:
        return memory[site + 1] | memory[site + 2] << 8, site
    return None, None


def identify(burst: dict, effects: list[Effect], tunes: list, tune_edges: dict,
             memory) -> tuple:
    """(effect or tune name, inputs, the address of the CALL that made it or
    None) for a burst, or (None, None, None)."""
    kind, what = burst["key"]
    edges = burst["edges"]
    if kind == "tune":
        if what is None:
            return None, None, None
        # A tune that starts with the speaker on (after another tune) has
        # an off edge first, which a call's recording does not.
        if burst["pcs"][0] == NOTE_OFF_OUT:
            edges = edges[1:]
        want = tune_edges[what]
        got = [b - a for a, b in zip(edges, edges[1:])]
        exp = [b - a for a, b in zip(want, want[1:])]
        if got == exp[:len(got)] and len(got) > 0:
            return what, ("whole" if len(got) == len(exp) else "in part"), None
        return None, None, None
    # The stack says which effect, where the CALL it returns to is one to an
    # effect, or to a routine that jumps to one: only that effect's models
    # are tried (the debris piece's warble and a quiet pass of the death
    # sound are the same waves). Otherwise, all of them.
    target, site = _called(memory, what)
    entry = target if any(e.entry == target for e in effects) else JUMPS_TO.get(target)
    candidates = [e for e in effects if e.entry == entry] if entry is not None else effects
    if target in JUMPS_TO:
        caller = target
    elif entry is not None:
        caller = site
    else:
        caller = None
    # An effect that starts with the speaker still on from a tune makes no
    # edge with its first OUT: its first on half-wave cannot be measured, and
    # the rest is compared.
    already_on = burst["pcs"][0] in (PULSE_OUTS[1], CYCLE_OUTS[1])
    for effect in candidates:
        for inputs, waves in effect.domain.items():
            if not waves:
                continue
            if already_on:
                if len(waves) > 1 and matches(edges[1:], waves[1:]):
                    return effect.name, inputs, caller
            elif matches(edges, waves):
                return effect.name, inputs, caller
    return None, None, None


class Run:
    def __init__(self, name, title, what, setup, recorded):
        self.name, self.title, self.what = name, title, what
        self.setup, self.recorded = setup, recorded


ADDON_FLIGHT = [([], 1.0), (["1"], 2.0), ([], 1.0), (["1"], 2.0), (["q"], 1.0),
                (["q", "x"], 2.0), (["a"], 3.0), (["a", "x"], 3.0)]
# The build's tours: right along a map row, climbing and dropping.
TOUR = [(["x", "q"], 2.0), (["x", "a", "q"], 0.4), (["x"], 1.0), (["z", "a"], 0.6)]

# The hit-immunity timer: $FF when the shield is taken (#R$8E2D), counted
# down every other pass; colour_ship ($F1BD) shows the ship cyan while it
# runs, flashing in its last 32. Set to $28 for the run below, the shield's
# last stretch: 8 counts steady, then the flashing, then white.
HIT_IMMUNITY = 0x896F
SHIELD_TAIL = 0x28


def _shield_tail(memory) -> None:
    memory[HIT_IMMUNITY] = SHIELD_TAIL


def _runs() -> list[Run]:
    start = bc._start(0)
    return [
        Run("run_begin", "A game begins",
            "From the menu: 0 pressed, the start tune, the new life's fly-in and its whine, "
            "then the build's keyboard round of flying (thrust, steering both ways, firing), "
            "with the damage and the fuel undone between its steps.",
            start[:1], start[1:] + bc._alive(bc.KEYBOARD_ROUND)),
        Run("run_addons", "Flying with every add-on",
            "All nine add-ons fitted at a new life, then the special beam (the number row, "
            "the ship still), thrust and steering, with the damage and the fuel undone "
            "between the steps.",
            start + bc.new_life_at(bc.all_addons), bc._alive(ADDON_FLIGHT)),
        Run("run_shield", "The shield running out",
            f"A second into a game, the hit-immunity timer (#R${HIT_IMMUNITY:04X}) set to "
            f"${SHIELD_TAIL:02X} -- the last stretch of the shield a pick-up gives, which "
            "starts it at $FF -- and the ship left alone until it reaches 0: cyan, then "
            "flashing, then white.",
            start + [([], 1.0)],
            [_shield_tail,
             bc.Until("the shield gone", lambda m: m[HIT_IMMUNITY] == 0, 40.0), ([], 0.5)]),
        Run("run_tour_high", "A tour near the top of the map",
            "A new life put at map row 3 by the game's own restart, then the build's tour: "
            "east, climbing and dropping, firing, three times over, with the damage and the "
            "fuel undone between the steps.",
            start + bc.new_life_at(bc.restart_at(0x20, 3, 0x80, 0x60)), bc._alive(TOUR * 3)),
        Run("run_tour_caverns", "A tour of the caverns",
            "The same at map row 16, four times over; a crash inside a step can still kill, "
            "and does.",
            start + bc.new_life_at(bc.restart_at(0x20, 16, 0x80, 0x60)), bc._alive(TOUR * 4)),
        Run("run_death", "Out of fuel",
            "The tank emptied in flight: the grace passes, the ship breaking up, the death "
            "sequence, the death tune, and the next life's fly-in.",
            start + [(["a", "x"], 0.5)],
            [bc._kill_by_fuel,
             bc.Until("a death from empty fuel", lambda m: m[bc.DYING] != 0, 10.0),
             bc.Until("the next ship", bc._dead_and_back, 30.0), ([], 1.5)]),
        Run("run_game_over", "The last life lost",
            "The last life's tank emptied: the death, then the game-over tune, until the "
            "menu (where ENTER, held, cuts the title tune short at once).",
            start + [(["a", "x"], 0.5), bc._last_life],
            [bc._kill_by_fuel,
             bc.Until("a death from empty fuel", lambda m: m[bc.DYING] != 0, 10.0),
             bc.At("the menu after the game", bc.MENU_LOOP, 300.0, bc.TUNE_KEYS)]),
        Run("run_launch", "The rocket launched",
            "A new life put inside the finished rocket by the game's own restart (all eight "
            "parts built): the fly-in, the docking, the launch, the planet-secured screen with "
            "its bonus count, the planet tune, and the next planet's first pass.",
            start + bc.new_life_at(bc.restart_at(*bc.ROCKET_VIEW, pokes={bc.PARTS_BUILT: 8})),
            [bc.Until("the launch", lambda m: m[bc.LAUNCH] != 0, 10.0),
             bc.Until("the rocket gone", lambda m: m[bc.LAUNCH] == 0xFF, 60.0),
             bc.At("the next planet's first pass", bc.PLAY_LOOP, 120.0, bc.TUNE_KEYS)]),
    ]


def _play_run(snapshot: Path, run: Run) -> tuple[list, int, object]:
    """The run's edges (T-states from the start of its recorded part) and its
    length."""
    from skoolkit.simutils import T

    machine = bc.Machine(snapshot)
    machine.tracer = _tracer_class()(machine.simulator)
    machine.simulator.set_tracer(machine.tracer)
    machine.play(run.setup, f"sounds: {run.name}")
    start = machine.simulator.registers[T]
    first = len(machine.tracer.edges)
    machine.play(run.recorded, f"sounds: {run.name}")
    edges = [(t - start, pc, de, stack) for t, pc, de, stack in machine.tracer.edges[first:]]
    return edges, machine.simulator.registers[T] - start, machine


def _quiet_pass(snapshot: Path) -> int:
    """The length of a pass with no sound: the median of 40 passes of the
    ship still in the sky after a game's start, those that made none."""
    from skoolkit.simutils import T

    machine = bc.Machine(snapshot)
    machine.tracer = _tracer_class()(machine.simulator)
    machine.simulator.set_tracer(machine.tracer)
    machine.play(bc._start(0) + [([], 3.0), bc.At("a pass", bc.PLAY_LOOP, 5.0)], "sounds: quiet")
    lengths = []
    for _ in range(40):
        before, edges = machine.simulator.registers[T], len(machine.tracer.edges)
        machine.play([bc._keep_alive, ([], 0.0001), bc.At("a pass", bc.PLAY_LOOP, 5.0)],
                     "sounds: quiet")
        if len(machine.tracer.edges) == edges:
            lengths.append(machine.simulator.registers[T] - before)
    lengths.sort()
    return lengths[len(lengths) // 2]


# --------------------------------------------------------------------------
# Writing the page.
# --------------------------------------------------------------------------

def skool_entries() -> list[int]:
    found = []
    if SKOOL.exists():
        for line in SKOOL.read_text(encoding="utf-8").splitlines():
            match = re.match(r"^[bcgistuw]\$([0-9A-F]{4})", line)
            if match:
                found.append(int(match.group(1), 16))
    return sorted(found)


def link(text: str, entries: set) -> str:
    """#R$ADDR where ADDR starts an entry; a plain $ADDR otherwise."""
    return re.sub(r"#R\$([0-9A-F]{4})",
                  lambda m: m.group(0) if int(m.group(1), 16) in entries else "$" + m.group(1),
                  text)


def _audio(name: str) -> str:
    file = f"{SOUNDS_DIR}/{name}.wav"
    return (f'<audio controls preload="none" src="{file}"><a href="{file}">{name}.wav</a>'
            "</audio>")


def _frequency(hz: float) -> str:
    return f"{hz / 1000:.1f}&nbsp;kHz" if hz >= 10000 else f"{hz:.0f}&nbsp;Hz"


def _span(low: float, high: float) -> str:
    if round(low) == round(high):
        return _frequency(low)
    first = _frequency(low)
    if (low >= 10000) == (high >= 10000):
        first = first.split("&nbsp;")[0]      # one unit for both ends
    return f"{first}&ndash;{_frequency(high)}"


def _pitch_text(pitch) -> str:
    """The tones' range, and the clicks' rate for the crackles."""
    tones, clicks = pitch
    parts = []
    if tones:
        parts.append(_span(*tones))
    if clicks:
        parts.append(f"clicks at {_span(*clicks)}")
    return "; ".join(parts) if parts else "single clicks"


def _section(effects, recordings, tunes, rows, scale, runs, quiet, entries) -> str:
    offset, worst = scale
    lines = [
        '<div class="kl-list">',
        "<p>A 48K Spectrum has one bit of sound hardware, bit 4 of port $FE, and Cyberun "
        "makes every sound by setting and clearing it with the processor counting in "
        "between, OUT ($FE) with $10 and then 0 so that the border stays black. Interrupts "
        "are off throughout the game, so nothing plays a sound over time: each effect plays "
        "in full, at once, inside the pass that asks for it, and that pass is longer by the "
        "sound's length. Two building blocks make every effect: a pulse with separate on "
        "and off lengths (#R$71D3) and a square-wave cycle (#R$71E0), driven by a rising "
        "sweep (#R$71F4), a falling zap (#R$724E), a two-note warble (#R$7217) and a "
        "scrambled crackle (#R$7297). The tunes are a byte a note, played by #R$9AB4 from "
        "the semitones of #R$9B0C.</p>",
        "<p>Every recording here is the game's own code running in SkoolKit's simulator, "
        "each change of the speaker bit logged to the T-state and rendered at 44100 Hz; "
        "nothing is synthesised. Each effect was recorded by calling its routine on a "
        "machine of its own -- the snapshot run through its start-up to the menu, then the "
        "registers and bytes the routine reads set -- and checked wave by wave against what "
        "its code makes: the half-wave counts it works out from its inputs, turned into "
        "T-states by the instruction timings of its loops. An effect played once a pass is "
        f"called once for each of the inputs a run of passes gives it, the calls "
        f"{quiet:,} T-states ({quiet / TSTATES_PER_SECOND * 1000:.0f} ms) apart: the "
        "median length of a pass with no sound, measured with the ship still in the "
        "sky.</p>",
        "<p>The simulator has no memory contention. The effects' code ($71D3-$731E) lies "
        "below $8000, in the RAM the ULA holds up while it draws the screen, so on a real "
        "48K the effects run somewhat slower, and lower, than they are heard here; the tune "
        "player and its table lie above $8000 and are not slowed.</p>",
        "<h3>Effects</h3>",
        '<table class="kl-table">',
        "<tr><th>Sound</th><th>Routine</th><th>Played by, and when</th><th>Recorded</th>"
        "<th>Length</th><th>Pitch</th><th>Listen</th></tr>",
    ]
    for effect in effects:
        rec = recordings[effect.name]
        if rec["silent"]:
            listen = "silent"
        else:
            listen = _audio(effect.name)
        heard = rec.get("heard")
        played = effect.played
        if heard:
            played += " Heard in the runs below: " + "; ".join(heard)
            if rec.get("callers"):
                played += (", from " + ", ".join(f"#R${c:04X}" for c in rec["callers"])
                           + " by the stack")
            played += "."
        else:
            played += " Not heard in any of the runs below."
        how = (f"{effect.how}; " if effect.how else "") + rec["check"]
        lines.append(
            f"<tr><td>{_esc(effect.title)}</td><td>#R${effect.entry:04X}</td>"
            f"<td>{link(played, entries)}</td><td>{link(how, entries)}</td>"
            f"<td>{_length(rec['length'])}</td><td>{_pitch_text(rec['pitch'])}</td>"
            f"<td>{listen}</td></tr>")
    lines.append("</table>")

    lines += [
        "<h3>Tunes</h3>",
        "<p>A note is one byte: bits 0-5 its entry in #R$9B0C (0 a rest), bits 6-7 its "
        "length less one, one to four units. An entry gives the half-period as a DJNZ "
        "count B and a pass count C, and the cycles in one unit; #R$9AB4 multiplies the "
        "cycles by the length and toggles the speaker, off then on, for each. Each tune "
        "below was recorded by calling its player with DE at the tune and no key down, so "
        "that the title tune plays to its end, as it does for a player who waits.</p>",
        '<table class="kl-table">',
        "<tr><th>Tune</th><th>Notes</th><th>Played by, and when</th><th>Recorded</th>"
        "<th>Length</th><th>Pitch</th><th>Listen</th></tr>",
    ]
    for tune in tunes:
        low, high = tune["range"]
        lines.append(
            f"<tr><td>{_esc(tune['title'])}</td><td>#R${tune['entry']:04X}</td>"
            f"<td>{link(tune['what'], entries)}</td>"
            f"<td>{link(tune['how'], entries)}</td>"
            f"<td>{_length(tune['length'])}</td>"
            f"<td>{_hz(note_period(*rows[low][:2])):.0f}&ndash;"
            f"{_hz(note_period(*rows[high][:2])):.0f}&nbsp;Hz "
            f"({note_name(low + offset)}&ndash;{note_name(high + offset)})</td>"
            f"<td>{_audio(tune['name'])}</td></tr>")
    lines.append("</table>")

    # The pitches against the table and against equal temperament.
    used = {}
    measured = {}
    for tune in tunes:
        for row, _ in tune["notes"]:
            used.setdefault(row, []).append(tune["title"])
        for row, values in tune["measured"].items():
            measured.setdefault(row, []).extend(values)
    worst_rec = max(abs(_hz(note_period(*rows[row][:2])) - v) for row in measured
                    for v in measured[row])
    used_cents = [_cents(_hz(note_period(*rows[row][:2])), row + offset) for row in used]
    same = _repeats(rows)
    by_loops, bottom, top = _loop_scale(rows)
    lowest = _hz(note_period(*rows[1][:2]))
    highest = _hz(note_period(*rows[NOTE_ROWS - 1][:2]))
    lines += [
        f"<p>How the recorded pitches compare with the table. Every note the five tunes play "
        f"was measured from its recording, as the mean of its whole waves, and every one is "
        f"the pitch the note table gives it through #R$9AB4's loops -- a half period of 13B "
        f"+ 3339C - 3333 T-states, plus 39 for the off half and 62 for the on -- to within "
        f"{worst_rec:.3f}&nbsp;Hz, the rounding of the mean; the half-waves themselves match "
        f"to the T-state (the Recorded column above). The table runs from "
        f"{lowest:.1f}&nbsp;Hz (entry 1) to {highest:.0f}&nbsp;Hz (entry 60). Set against an "
        f"equal-tempered scale with A4 at 440 Hz it is nearest with entry 1 as "
        f"{note_name(1 + offset)} and entry 60 as {note_name(60 + offset)}, its notes lying "
        f"within {worst:.0f} cents of that scale, and the notes the tunes play within "
        f"{max(abs(c) for c in used_cents):.0f} (the table below). It is not quite a scale of "
        f"semitones as played: counted in loops, as 256(C - 1) + B turns of the DJNZ, its "
        f"entries step by a semitone to within {by_loops:.0f} cents (the rounding of B), but "
        f"each half-wave also spends a fixed hundred-odd T-states outside its loops, which "
        f"is a larger share of a short period than a long one, so the high notes come out "
        f"flatter than the low: from the semitone series that fits the played pitches best, "
        f"entry 1 lies {bottom:+.0f} cents and entry 60 {top:+.0f} (the table looks to have "
        f"been worked out as loop counts -- an inference from these numbers). "
        + (f"Entr{'ies' if len(same) > 1 else 'y'} "
           + ", ".join(str(r) for r in same)
           + f" repeat{'' if len(same) > 1 else 's'} the B and C of the entry before, so "
           f"note {same[0]} sounds as note {same[0] - 1} (only its cycle count differs) and "
           f"the step from {same[0] - 1} to {same[0] + 1} is two semitones; "
           + ("no tune plays it." if not any(r in used for r in same) else
              "a tune plays it.") if same else "")
        + "</p>",
        '<table class="kl-table">',
        "<tr><th>Entry</th><th>B</th><th>C</th><th>Cycles a unit</th><th>Table's pitch</th>"
        "<th>Recorded</th><th>Nearest note</th><th>Cents</th><th>A unit</th>"
        "<th>Played in</th></tr>",
    ]
    for row in sorted(used):
        b, c, per_unit = rows[row]
        period = note_period(b, c)
        hz = _hz(period)
        rec = measured.get(row, [])
        rec_text = (f"{min(rec):.2f}&nbsp;Hz" if rec and round(min(rec), 2) == round(max(rec), 2)
                    else (f"{min(rec):.2f}&ndash;{max(rec):.2f}&nbsp;Hz" if rec else "&ndash;"))
        titles = ", ".join(t for t in dict.fromkeys(used[row]))
        lines.append(
            f"<tr><td>{row}</td><td>{b}</td><td>{c}</td><td>{per_unit}</td>"
            f"<td>{hz:.2f}&nbsp;Hz</td><td>{rec_text}</td>"
            f"<td>{note_name(row + offset)}</td><td>{_cents(hz, row + offset):+.0f}</td>"
            f"<td>{per_unit * period / TSTATES_PER_SECOND:.3f}&nbsp;s</td>"
            f"<td>{_esc(titles)}</td></tr>")
    lines.append("</table>")

    lines += [
        "<h3>In the game</h3>",
        "<p>The game itself, played in the simulator the way the build's sessions play it, "
        "recorded from the moment named. Each run's edges were split into the calls that "
        "made them, by the return addresses on the stack at each OUT, and every call was "
        "matched against the models of every effect, over all the inputs it could have, "
        "and against the tunes' recordings above: the column says what each run holds.</p>",
        '<table class="kl-table">',
        "<tr><th>Run</th><th>What happens</th><th>What it holds</th><th>Length</th>"
        "<th>Listen</th></tr>",
    ]
    for run in runs:
        lines.append(
            f"<tr><td>{_esc(run['title'])}</td><td>{link(run['what'], entries)}</td>"
            f"<td>{link(run['holds'], entries)}</td><td>{_length(run['length'])}</td>"
            f"<td>{_audio(run['name'])}</td></tr>")
    lines.append("</table>")
    lines.append("</div>")
    body = "\n".join(lines)
    for line in body.splitlines():
        if line.startswith((";", "[")):
            raise RuntimeError(f"a section line starts with {line[0]!r}: {line[:40]}")
    return body


# --------------------------------------------------------------------------
# The build.
# --------------------------------------------------------------------------

def _record_effect(base, effect: Effect, quiet: int) -> dict:
    """The effect's calls, each checked against its model, end to end a pass
    apart."""
    recorded, mismatched, silent_calls, pitch = [], 0, 0, None
    for registers, pokes, inputs in effect.calls:
        edges, length = call(base, effect.entry, registers, pokes)
        waves = effect.domain[inputs]
        if not matches(edges, waves):
            mismatched += 1
        if not edges:
            silent_calls += 1
        recorded.append((edges, length))
        tones, clicks = _pitch_range(edges, waves)
        pitch = (tones, clicks) if pitch is None else (_widen(pitch[0], tones),
                                                       _widen(pitch[1], clicks))
    edges, length = in_a_row(recorded, quiet)
    total_waves = sum(len(effect.domain[inputs]) for _, _, inputs in effect.calls)
    if mismatched:
        check = (f"{mismatched} of the {len(effect.calls)} calls were NOT the waves "
                 f"#R${effect.entry:04X}'s code makes")
    else:
        check = (f"{total_waves:,} waves, every one of them the length "
                 f"#R${effect.entry:04X}'s code gives it, on half-waves and off")
        if silent_calls:
            check += f" ({silent_calls} of the calls silent, as the code has them)"
    return {"edges": edges, "length": length, "check": check, "pitch": pitch,
            "silent": not edges, "mismatched": mismatched}


def build(snapshot: Path, html_dir: Path, log=print) -> dict[str, str]:
    """Record every tune and effect into html_dir/sounds, and return the
    Sounds section."""
    out_dir = html_dir / SOUNDS_DIR
    out_dir.mkdir(parents=True, exist_ok=True)
    log("Recording Cyberun's sounds...")
    entry_list = skool_entries()
    entries = set(entry_list)
    base = _menu_machine(snapshot)
    rows = note_rows(base)
    scale = _scale(rows)
    quiet = _quiet_pass(snapshot)

    # The tunes, by calls.
    tunes = []
    for name, entry, player, title, what in TUNES:
        edges, length = call(base, player, {"DE": entry})
        notes = tune_notes(base, entry)
        ok, check = _tune_check(edges, notes, rows)
        if not ok:
            log(f"  warning: {name}: {check}")
        pitched = [row for row, _ in notes if row]
        player_name = "#R$9A9A" if player == PLAY_TUNE_UNTIL_KEY else "#R$9AA9"
        tunes.append({
            "name": name, "entry": entry, "end": entry + len(notes), "title": title,
            "what": what, "edges": edges, "length": length, "notes": notes,
            "range": (min(pitched), max(pitched)),
            "how": (f"{player_name} called with DE = ${entry:04X}"
                    + (" and no key down" if player == PLAY_TUNE_UNTIL_KEY else "")
                    + f": {len(notes)} notes, entries {min(pitched)}-{max(pitched)}, "
                    + (f"{sum(1 for r, _ in notes if r == 0)} rests, " if 0 in [r for r, _ in notes]
                       else "no rests, ")
                    + check + "."),
            "measured": _note_measurements(edges, notes, rows),
        })
        _write_wav(out_dir / f"{name}.wav", edges, length)
    tune_edges = {tune["name"]: tune["edges"] for tune in tunes}

    # The runs.
    effects = _effects()
    by_name = {effect.name: effect for effect in effects}
    heard = {}          # effect name -> {run title: count}
    callers = {}        # effect name -> the entries seen calling it
    beam_inputs = []
    runs = []
    for run in _runs():
        edges, length, _ = _play_run(snapshot, run)
        found, unknown = {}, 0
        for burst in bursts(edges, tunes):
            what, inputs, caller = identify(burst, effects, tunes, tune_edges, base)
            if what is None:
                unknown += len(burst["edges"])
                continue
            found[what] = found.get(what, 0) + 1
            if what in by_name:
                heard.setdefault(what, {})
                heard[what][run.title] = heard[what].get(run.title, 0) + 1
                if caller is not None:
                    entry = max((e for e in entry_list if e <= caller), default=None)
                    if entry is not None:
                        callers.setdefault(what, set()).add(entry)
                if what == "beams":
                    beam_inputs.append(inputs)
        titles = {**{e.name: e.title.lower() for e in effects},
                  **{t["name"]: f"the {t['title'].lower()} tune" for t in tunes}}
        parts = [f"{titles[name]}{' x' + str(n) if n > 1 else ''}" for name, n in found.items()]
        holds = ((", ".join(parts) if parts else "nothing") + ". "
                 + (f"{len(edges):,} edges, every one of them in a call that matched."
                    if not unknown else
                    f"{len(edges):,} edges, of which {unknown:,} were NOT in a call that "
                    "matched any effect or tune."))
        if unknown:
            log(f"  warning: {run.name}: {unknown} edges not identified")
        _write_wav(out_dir / f"{run.name}.wav", [e[0] for e in edges], length)
        runs.append({"name": run.name, "title": run.title, "what": run.what,
                     "holds": holds, "length": length})
        log(f"  {run.name}: {len(edges):,} edges, {length / TSTATES_PER_SECOND:.1f} s")

    # The beams: the inputs of the first eight beam calls heard in the
    # runs, in the order they came; or, had there been none, mixes 0 to 7
    # with +2 = 0.
    beam_effect = by_name["beams"]
    chosen = beam_inputs[:8] or [(mix, 0) for mix in range(8)]
    beam_effect.calls = [({"IX": SCRATCH_RECORD},
                          {SCRATCH_RECORD: mix, SCRATCH_RECORD + 1: 0, SCRATCH_RECORD + 2: e},
                          (mix, e)) for mix, e in chosen]
    beam_effect.how = (f"called {len(chosen)} times, a pass apart, with IX at a record whose "
                       "(+0 XOR +1) AND 15 and +2 AND $1F are "
                       + ("those of the first beams heard in the runs below"
                          if beam_inputs else "0 to 7 and 0")
                       + " (" + ", ".join(f"{m} and {e}" for m, e in chosen) + ")")

    # The effects, by calls.
    recordings = {}
    for effect in effects:
        rec = _record_effect(base, effect, quiet)
        if rec["mismatched"]:
            log(f"  warning: {effect.name}: {rec['check']}")
        counts = heard.get(effect.name, {})
        rec["heard"] = [f"{title.lower()}{' (' + str(n) + ' calls)' if n > 1 else ''}"
                        for title, n in counts.items()]
        rec["callers"] = sorted(callers.get(effect.name, ()))
        recordings[effect.name] = rec
    # The hum's second branch: the record's +$16 bit 6 set, on each of
    # eight passes.
    second = [call(base, SOUND_HUM, {"IX": SCRATCH_RECORD},
                   {PASS_COUNTER: p, SCRATCH_RECORD + 0x16: 0x40})[0] for p in range(8)]
    if any(second):
        recordings["hum"]["check"] += (
            "; with +$16 bit 6 set, " + str(sum(1 for e in second if e))
            + " of eight passes sounded")
    else:
        recordings["hum"]["check"] += (
            "; called eight more times with +$16 bit 6 set, it was silent on every pass: "
            "that branch is reached only on odd passes, and then waits for a pass whose low "
            "two bits are 0, which an odd pass never is, so it can never sound")
    for effect in effects:
        rec = recordings[effect.name]
        if not rec["silent"]:
            _write_wav(out_dir / f"{effect.name}.wav", rec["edges"], rec["length"])
    written = len(tunes) + len(runs) + sum(1 for r in recordings.values() if not r["silent"])
    log(f"  {written} sounds written to {out_dir}")
    return {"Sounds": _section(effects, recordings, tunes, rows, scale, runs, quiet, entries)}
