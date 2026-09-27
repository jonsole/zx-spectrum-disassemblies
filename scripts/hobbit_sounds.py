"""The Hobbit's sounds -- which is to say its silence, and the one noise the
ROM makes for it -- recorded from the game's own code at build time.

build_hobbit.py --html calls build(), which writes the only recording there is
into the HTML directory's audio/ folder and returns the Sounds section. Nothing
here is committed output: the recording is made from the game's bytes.

A 48K Spectrum has one bit of sound hardware, bit 4 of port $FE. The same port
sets the border (bits 0-2) and drives the MIC socket for saving (bit 3). The
Hobbit never sets bit 4. Its listing has six OUTs to port $FE, every one a
border colour; it has no beeper routine, calls no ROM routine but SA-BYTES and
LD-BYTES, and reads the keyboard itself with interrupts off, so it never runs
the ROM line editor that makes the 48K's key click. This module shows that
three ways and says which is which on the page:

- Read: every OUT in the listing and every call into the ROM, found in
  hobbit.skool at build time (a new one there fails the build rather than go
  unmentioned), and the border byte at the head of every picture stream.
- Run: the build's WALKTHROUGH driven through hobbit_drive's Hobbit in
  SkoolKit's simulator, then PAUSE and SAVE, with a tracer logging every OUT
  (T-state, PC, port, value) and an execution map of every address run. The
  count of changes of bit 4 is the answer: none.
- The only noise is SAVE's: the ROM's SA-BYTES toggling bit 3 for the tape.
  Its first block (leader, sync, flag, 29 bytes, parity) is recorded from the
  MIC edges to a 16-bit mono 44.1 kHz WAV, decoded back into bytes and compared
  with the memory it came from, and the whole four-block save is then played
  into the ROM's own verify through the EAR bit of port $FE, which must accept
  it. Nothing is synthesised: every edge in the file is an OUT the ROM made.

The machine is uncontended; the ROM's tape loops run from uncontended memory,
so the timings are the real machine's.
"""
from __future__ import annotations

import bisect
import html
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import build_hobbit as bh
import hobbit_drive as hd

SKOOL = bh.OUT_DIR / "hobbit.skool"
SNAPSHOT = bh.OUT_DIR / "hobbit.z80"
TSTATES_PER_SECOND = bh.TSTATES_PER_SECOND
AUDIO = "../audio"                 # the page is reference/sounds.html
SAVE_WAV = "save_block.wav"

BORDER_BITS = 0x07
MIC = 0x08
SPEAKER = 0x10
EAR = 0x40                          # bit 6 of a read of port $FE

# The game's OUTs to port $FE, and what each writes (see their entries). The
# listing is searched for OUTs at build time; one missing from here fails it.
OUTS = {
    0x6C66: ("$00", "Black, before the title screen waits for a key (every new game)."),
    0x6FD8: ("$07", "White, as #R$6FD3(CLEAR_SCREEN) wipes the screen to black on white."),
    0x821B: ("the picture's first byte, or $00",
             "The picture's border colour, the first byte of its stream; 0 (black) when "
             "#R$95ED says the player cannot see."),
    0x843C: ("$04", "Green, for PAUSE."),
    0x844C: ("$07", "White again, once PAUSE has had its key."),
    0x96A5: ("$07", "White, after the key that follows every picture."),
}
PRINTER_PORT = 0xFB
TROLLS_DAY_BORDER = 0x05           # what TROLLS_TURN_TO_STONE writes over the
                                   # trolls' clearing's border byte

# The ROM (the 48K ROM's own names).
BEEPER = 0x03B5
SA_BYTES = 0x04C2
SA_LD_RET = 0x053F
LD_BYTES = 0x0556
IM1_HANDLER = 0x0038
# SA-BYTES's OUTs, as the run logs them: the leader loop's, the two sync
# pulses', every half-wave of a bit's, and SA/LD-RET's border at the end.
SA_LEADER_OUT = 0x04DA
SA_SYNC_OUTS = (0x04EC, 0x04F4)
SA_BIT_OUT = 0x051C
SA_END_OUT = 0x0548
ROM_TOP = 0x4000
# Every half-wave SA-BYTES writes to the MIC bit, in T-states: its leader loop
# (DJNZ from $A4, then OUT, XOR, LD B, DEC L, JR NZ: 163 x 13 + 8 + 41), the two
# sync pulses, and the halves of a 0 and a 1 bit. They are the ROM's; the TZX
# format documents the same numbers, and 3223 leader pulses for a block whose
# flag byte is $80 or more.
LEADER_HALF = 2168
SYNC = (667, 735)
BIT_HALF = (855, 1710)
DATA_LEADER_PULSES = 3223

# DO_SAVE, and where the drive stops in it.
NEW_KEYPRESS_DOWN = 0x84C2         # NEW_KEYPRESS waiting for a key to go down
SAVE_KEY_TAKEN = 0x84E6            # past SAVE's first key: the four SA-BYTES next
SAVE_BLOCKS_DONE = (0x84F2, 0x84FE, 0x850A, 0x8516)   # after each CALL SA_BYTES
VERIFY_KEY_TAKEN = 0x851F
VERIFY_BLOCKS_DONE = (0x852C, 0x8539, 0x8546, 0x8553)  # after each VERIFY_BLOCK
VERIFY_FAILED = 0x855E
SAVED_BLOCKS = ((0xB6EB, 0x1D), (0xC11B, 0x615), (0xCA84, 0xBF), (0xBA8A, 0x5D9))
DO_PAUSE_KEY = 0x8441              # DO_PAUSE past NEW_KEYPRESS
TAPE_LEAD_IN = 0.5                 # seconds of silence before the tape plays back
LIMIT = 120                        # seconds of emulated time for any one wait


def _esc(text: str) -> str:
    return html.escape(text, quote=False)


# --------------------------------------------------------------------------
# The listing.
# --------------------------------------------------------------------------

class _Listing:
    """What the page needs from hobbit.skool: entry starts (the only
    addresses #R may link to), their labels and titles, and every OUT and
    call into the ROM."""

    def __init__(self, path: Path):
        lines = path.read_text(encoding="utf-8").splitlines() if path.exists() else []
        self.entries: dict[int, tuple[str, str]] = {}
        self.outs: dict[int, str] = {}
        self.rom_calls: dict[int, int] = {}
        comment, label = [], None
        for line in lines:
            if line.startswith("@label="):
                label = line[7:]
                continue
            if line.startswith(";"):
                comment.append(line[1:].strip())
                continue
            m = re.match(r"^([bcgistuw ]|\*)\$([0-9A-F]{4}) (.*)$", line)
            if not m:
                if not line.strip():
                    comment = []
                continue
            address = int(m.group(2), 16)
            if m.group(1) in "bcgistuw" and m.group(1) != " ":
                title = next((c for c in comment if c), "")
                self.entries[address] = (label or "", title)
            comment, label = [], None
            instruction = m.group(3).split(";")[0].strip()
            if instruction.startswith("OUT ("):
                self.outs[address] = instruction
            call = re.match(r"^(CALL|JP|RST)\b.*\$([0-9A-F]{2,4})$", instruction)
            if call and int(call.group(2), 16) < ROM_TOP and not instruction.startswith("JP (") \
                    and call.group(1) != "JR":
                self.rom_calls[address] = int(call.group(2), 16)

    def entry_of(self, address: int) -> int | None:
        starts = [a for a in self.entries if a <= address]
        return max(starts) if starts else None

    def link(self, address: int) -> str:
        """#R$ADDR(LABEL) to an entry start, else the plain address."""
        if address in self.entries:
            label = self.entries[address][0]
            return f"#R${address:04X}({label})" if label else f"#R${address:04X}"
        return f"${address:04X}"

    def grouped(self, addresses) -> str:
        """Instructions listed by the routine they are in: '$8498 in LOAD_BLOCK;
        $84EF and $84FB in DO_SAVE'."""
        by_entry: dict = {}
        for address in addresses:
            by_entry.setdefault(self.entry_of(address), []).append(address)
        parts = []
        for entry, group in by_entry.items():
            where = [f"${a:04X}" for a in group]
            if len(where) > 1:
                where = [", ".join(where[:-1]) + " and " + where[-1]]
            parts.append(f"{where[0]} in {self.link(entry)}")
        return "; ".join(parts)

    def within(self, address: int) -> str:
        """An instruction's address and the routine it is in, linked."""
        entry = self.entry_of(address)
        if entry is None or entry == address:
            return self.link(address)
        return f"${address:04X} in {self.link(entry)}"


# --------------------------------------------------------------------------
# The machine: the Hobbit, with every port write logged.
# --------------------------------------------------------------------------

def _tracer_class():
    from skoolkit.simutils import PC, T

    base = bh._key_tracer_class()

    class PortTracer(base):
        """The build's key tracer, logging every OUT and able to play a tape
        into the EAR bit."""

        def __init__(self, simulator):
            super().__init__(simulator)
            self.write_port = self._out
            self.outs = []                  # (T, PC, port & $FF, value)
            self.tape_times = None          # MIC level changes, in tape time
            self.tape_levels = None
            self.tape_offset = 0

        def _out(self, registers, port, value, *rest):
            self.outs.append((registers[T], registers[PC], port & 0xFF, value))

        def read_port(self, registers, port):
            result = super().read_port(registers, port)
            if port & 1 == 0 and self.tape_times is not None:
                i = bisect.bisect_right(self.tape_times, registers[T] - self.tape_offset) - 1
                if i < 0 or not self.tape_levels[i]:
                    result &= ~EAR & 0xFF
            return result

    return PortTracer


class _Game(hd.Hobbit):
    """hobbit_drive's Hobbit with the port-logging tracer from the first
    instruction, and a map of every address it runs."""

    def __init__(self, snapshot: Path):
        from skoolkit import CSimulator, read_bin_file
        from skoolkit.simulator import Simulator
        from skoolkit.snapshot import Snapshot

        memory = list(Snapshot.get(str(snapshot)).memory)
        memory[:0x4000] = read_bin_file(str(bh.ROM))
        self.sim = (CSimulator or Simulator)(
            memory, registers={"SP": bh.STACK, "IY": bh.SYSVARS},
            state={"iff": 1, "im": 1, "tstates": 0})
        self.tracer = _tracer_class()(self.sim)
        self.sim.set_tracer(self.tracer)
        self.memory = self.sim.memory
        self.executed: set[int] = set()
        self.pc = bh.ENTRY
        self.any_key_waits = 0
        # As Hobbit does: the title's key, then on to the first prompt.
        self.run([], 2.0)
        self.run(["SPACE"], 0.2)
        self.ready()

    def run(self, keys: list[str], seconds: float, stop: int = 0) -> None:
        from skoolkit.simutils import PC, T

        self.tracer.keys = set(keys)
        if stop and self.pc == stop:
            self.sim.trace(self.pc, 0, 1, 0, True, None, self.executed, None, None, None)
            self.pc = self.sim.registers[PC]
        self.sim.trace(self.pc, stop, 0,
                       self.sim.registers[T] + int(seconds * TSTATES_PER_SECOND),
                       True, None, self.executed, None, None, None)
        self.pc = self.sim.registers[PC]

    @property
    def t(self) -> int:
        from skoolkit.simutils import T
        return self.sim.registers[T]

    def until(self, stop: int, keys=(), what: str = "") -> int:
        """Run to `stop` with `keys` held; its T-state."""
        self.run(list(keys), LIMIT, stop=stop)
        if self.pc != stop:
            raise RuntimeError(f"{what}: stopped at ${self.pc:04X}, not ${stop:04X}")
        return self.t

    def enter(self, command: str) -> None:
        """Type a command and press ENTER, as say() does, without waiting for
        the next prompt (PAUSE and SAVE wait for keys of their own)."""
        from skoolkit.simutils import B, H, L

        self.ready()
        for i, char in enumerate(command):
            self.memory[hd.INPUT_LINE + i] = ord(char)
        cursor = hd.INPUT_LINE + len(command)
        registers = self.sim.registers
        registers[H], registers[L] = cursor >> 8, cursor & 0xFF
        registers[B] = hd.LINE_LENGTH - len(command)
        self.run([], 0.05)
        self.run(["ENTER"], 0.10)
        self.run([], 0.10)


def _play(snapshot: Path) -> dict:
    """The walkthrough, PAUSE and SAVE, with everything written to a port."""
    game = _Game(snapshot)
    first_prompt = list(game.memory)
    for command in bh.WALKTHROUGH:
        game.say(command)
    commands = len(bh.WALKTHROUGH)

    # PAUSE: its key, then on to the next prompt.
    game.enter("PAUSE")
    game.until(NEW_KEYPRESS_DOWN, what="PAUSE's key")
    game.until(DO_PAUSE_KEY, ["SPACE"], "PAUSE's key")
    game.run([], 0.05)
    game.ready()
    commands += 1

    # SAVE: the key after its prompt, let go at once -- SA/LD-RET ends every
    # block by looking for BREAK, and SPACE still held there is BREAK.
    game.enter("SAVE")
    game.until(NEW_KEYPRESS_DOWN, what="SAVE's first key")
    save_start = game.until(SAVE_KEY_TAKEN, ["SPACE"], "SAVE's first key")
    blocks = [list(game.memory[a:a + n]) for a, n in SAVED_BLOCKS]
    block_ends = [game.until(stop, what="a SAVE block") for stop in SAVE_BLOCKS_DONE]

    # The tape as it was written: every change of the MIC bit.
    level, times, levels = 0, [0], [0]
    for t, pc, port, value in game.tracer.outs:
        if port & 1 == 0 and save_start <= t < block_ends[-1] and (value & MIC) != level:
            level = value & MIC
            times.append(t - save_start)
            levels.append(level)

    # The verify: its key, let go, and the tape played back half a second on.
    game.until(NEW_KEYPRESS_DOWN, what="the verify's key")
    verify_start = game.until(VERIFY_KEY_TAKEN, ["SPACE"], "the verify's key")
    game.tracer.tape_times, game.tracer.tape_levels = times, levels
    game.tracer.tape_offset = verify_start + int(TAPE_LEAD_IN * TSTATES_PER_SECOND)
    verified = 0
    for stop in VERIFY_BLOCKS_DONE:
        game.run([], LIMIT, stop=stop)
        if game.pc != stop:
            break
        verified += 1
    game.tracer.tape_times = None
    game.run([], 0.5)
    return {"game": game, "first_prompt": first_prompt, "commands": commands,
            "save_start": save_start,
            "block_ends": block_ends, "blocks": blocks, "verified": verified,
            "seconds": game.t / TSTATES_PER_SECOND, "tape_edges": len(times) - 1}


# --------------------------------------------------------------------------
# The tape signal.
# --------------------------------------------------------------------------

def _mic_edges(outs, t0: int, t1: int) -> list[int]:
    """The T-states, from t0, of every change of the MIC bit in [t0, t1)."""
    level, edges = 0, []
    for t, pc, port, value in outs:
        if port & 1 or t < t0:
            if port & 1 == 0 and t < t0:
                level = value & MIC
            continue
        if t >= t1:
            break
        if (value & MIC) != level:
            level = value & MIC
            edges.append(t - t0)
    return edges


def _analyse(outs, t0: int, t1: int) -> dict:
    """SA-BYTES's OUTs for one block, taken apart: the leader loop's, the two
    sync OUTs, then the data -- two OUTs a bit, whose spacing says 0 or 1 --
    read back into bytes as LD-BYTES would read them."""
    block = [(t, pc, value) for t, pc, port, value in outs
             if port & 1 == 0 and t0 <= t < t1 and pc < ROM_TOP]
    leader = [t for t, pc, value in block if pc == SA_LEADER_OUT]
    sync_outs = [t for t, pc, value in block if pc in SA_SYNC_OUTS]
    data = [t for t, pc, value in block if pc in (SA_SYNC_OUTS[1], SA_BIT_OUT)]
    end = [t for t, pc, value in block if pc == SA_END_OUT]
    halves = [b - a for a, b in zip(data, data[1:])]
    bits = [1 if halves[k] + halves[k + 1] > BIT_HALF[0] + BIT_HALF[1] else 0
            for k in range(0, len(halves) - 1, 2)]
    data_bytes = [sum(bit << (7 - k) for k, bit in enumerate(bits[n:n + 8]))
                  for n in range(0, len(bits) - len(bits) % 8, 8)]
    expected = [BIT_HALF[bit] for bit in bits for _ in range(2)]
    # How far each byte's first half-wave is from a bit's, and whether any
    # other half-wave is off at all.
    firsts = [halves[k] - expected[k] for k in range(0, len(halves), 16)]
    others_off = sum(1 for k, (h, e) in enumerate(zip(halves, expected))
                     if k % 16 and h != e)
    return {"leader_outs": len(leader),
            "leader": [b - a for a, b in zip(leader, leader[1:])],
            "sync": (sync_outs[0] - leader[-1], sync_outs[1] - sync_outs[0]),
            "halves": halves, "bits": bits, "data": data_bytes, "firsts": firsts,
            "others_off": others_off, "end_gap": end[0] - data[-1] if end else None,
            "end_value": [v for t, pc, v in block if pc == SA_END_OUT][:1]}


def _write_wav(path: Path, edges: list[int], length: int) -> None:
    """Render the MIC edges to a WAV. SkoolKit's writer takes the gaps between
    flips, from a start with the signal off."""
    from skoolkit.audio import BeeperOptions
    from skoolkit.components import get_audio_writer

    delays = [edges[0]] + [b - a for a, b in zip(edges, edges[1:])]
    if length > edges[-1]:
        delays.append(length - edges[-1])
    delays = [max(d, 1) for d in delays]
    with open(path, "wb") as f:
        get_audio_writer().write_audio(f, delays, BeeperOptions(100, False, False, 0, False))


# --------------------------------------------------------------------------
# The page.
# --------------------------------------------------------------------------

def _colours(values) -> str:
    return ", ".join(f"{bh.COLOURS[v & 7]} ({v})" for v in sorted(set(values)))


def _hex(values) -> str:
    return ", ".join(f"${v:02X}" for v in sorted(set(values)))


def _count(values: list[int]) -> str:
    """'855 T-states (all 480)' or each value with how many."""
    seen = sorted(set(values))
    if len(seen) == 1:
        return f"{seen[0]:,} T-states (all {len(values):,})"
    return ", ".join(f"{v:,} ({values.count(v):,})" for v in seen)


def _section(listing: _Listing, memory, run: dict, save: dict, pictures) -> str:
    game = run["game"]
    outs = game.tracer.outs
    ula = [o for o in outs if o[2] & 1 == 0]
    printer = [o for o in outs if o[2] == PRINTER_PORT]
    by_pc: dict[int, list[int]] = {}
    for t, pc, port, value in ula:
        by_pc.setdefault(pc, []).append(value)
    speaker_edges, level = 0, 0
    for t, pc, port, value in ula:
        if value & SPEAKER != level:
            level = value & SPEAKER
            speaker_edges += 1
    game_ula = {pc: v for pc, v in by_pc.items() if pc >= ROM_TOP}
    rom_ula = [o for o in ula if o[1] < ROM_TOP]
    rom_in_save = all(o[0] >= run["save_start"] for o in rom_ula)
    ran = []
    for a in sorted(a for a in game.executed if a < ROM_TOP):
        if ran and a <= ran[-1][1] + 8:
            ran[-1][1] = a
        else:
            ran.append([a, a])
    tape_ran = [r for r in ran if r[0] >= SA_BYTES]
    other_ran = [r for r in ran if r[0] < SA_BYTES]

    def spans(rs) -> str:
        return ", ".join(f"${a:04X}-${b:04X}" for a, b in rs)
    if other_ran and other_ran[0][0] == IM1_HANDLER:
        other_text = (f" and {spans(other_ran)} -- the ROM's interrupt routine and the "
                      "keyboard scan it calls. SA-BYTES ends, as every ROM tape routine does, "
                      "with EI, and #R$84CC(DO_SAVE) does not DI again until "
                      "#R$8553(TAPE_DONE), so interrupts are on from the end of the fourth "
                      "block, through the \"REWIND\" prompt and its key, until the verify's "
                      "LD-BYTES turns them off; the ROM's keyboard scan runs fifty times a "
                      "second there. It only reads the keyboard; the click is the editor's")
    elif other_ran:
        other_text = f" and {spans(other_ran)}"
    else:
        other_text = ""
    borders = [memory[p] for _, p, _ in pictures] + [TROLLS_DAY_BORDER]

    lines = [
        "<p>The Hobbit makes no sound. A 48K Spectrum has one bit of sound hardware, bit 4 "
        "of port $FE, and nothing in the game ever sets it: there is no beeper routine, "
        "no tune and no click. The pictures draw, the characters come and go and the "
        "fights are fought in silence. The only noise the machine makes while the game "
        "runs is SAVE's tape signal, and that is the ROM's.</p>",
        "<h3>What the game writes to port $FE</h3>",
        f"<p>The listing has {len(listing.outs)} OUT instructions. "
        f"{len(OUTS)} write to port $FE, and each writes a border colour -- bits 0-2 -- "
        "with the MIC bit (3) and the speaker bit (4) clear:</p>",
        '<table class="default">',
        "<tr><th>OUT</th><th>Writes</th><th>What for</th><th>Seen in the run</th></tr>",
    ]
    for address, (value, what) in OUTS.items():
        seen = by_pc.get(address, [])
        seen_text = (f"{len(seen):,} &times; {_hex(seen)}" if seen else "not reached")
        lines.append(f"<tr><td>{listing.within(address)}</td><td>{value}</td>"
                     f"<td>{what}</td><td>{seen_text}</td></tr>")
    lines.append("</table>")
    lines += [
        f"<p>The picture border bytes, read from the {len(pictures)} streams in "
        f"{listing.link(bh.PICTURE_TABLE)}, are {_colours(borders[:-1])}; "
        f"{listing.link(0xA971)} writes {TROLLS_DAY_BORDER} (cyan) over the trolls' "
        "clearing's when day dawns. None has bit 3 or 4 set, so no picture moves the "
        "speaker or the MIC line either.</p>",
    ]
    others = sorted(set(listing.outs) - set(OUTS))
    if others:
        lines.append(
            f"<p>The other {len(others)} OUTs, "
            + listing.grouped(others)
            + ", are to port $FB, the ZX Printer, which PRINT drives a pixel at a time. "
            "Bit 0 of that port number is set, and the ULA only answers even ports, so "
            "they do nothing to the speaker; the whirr of a real printer is the printer's "
            "own.</p>")
    rom_calls = sorted(set(listing.rom_calls.values()))
    lines += [
        "<p>No key click either. The 48K ROM's click is made by its line editor (ED-LOOP), "
        "which calls BEEPER for every key; the game never goes near it. It reads the keyboard "
        "itself (#R$8B93(SCAN_KEYBOARD) and the waits that poll port $FE directly), with "
        "interrupts off -- #R$6C00(START) begins with DI -- and its only calls into the ROM "
        "are "
        + " and ".join(f"${a:04X}" for a in rom_calls)
        + " -- SA-BYTES and LD-BYTES, for SAVE, its verify and LOAD: "
        + listing.grouped(sorted(listing.rom_calls))
        + ".</p>",
        "<h3>Checked by running it</h3>",
        f"<p>The game run in SkoolKit's simulator from #R$6C00(START): the title, the "
        f"opening, the {len(bh.WALKTHROUGH)} commands of the build's walkthrough, then PAUSE "
        f"and SAVE with its verify -- {run['seconds'] / 60:.0f} minutes of emulated time, "
        f"with every port write logged and every address run recorded. It wrote port $FE "
        f"{len(ula):,} times: {sum(len(v) for v in game_ula.values()):,} from the six OUTs "
        f"above, with the values in the table, and {len(rom_ula):,} from the ROM. "
        "The speaker bit changed "
        + ("<b>not once</b>" if speaker_edges == 0 else f"{speaker_edges:,} times")
        + ". The ZX Printer's port was "
        + (f"written {len(printer):,} times" if printer else "never written")
        + " (the walkthrough never turns PRINT on). The ROM wrote "
        + _hex(o[3] for o in rom_ula)
        + (", all during SAVE and its verify" if rom_in_save else "")
        + ", every value with bit 4 clear. The ROM code that ran was the tape "
        f"routines, {spans(tape_ran)},"
        + other_text
        + (f". BEEPER (${BEEPER:04X}) never ran." if BEEPER not in game.executed
           else f". <b>BEEPER (${BEEPER:04X}) ran.</b>")
        + "</p>",
    ]

    # The tape signal.
    edges, length, decoded = save["edges"], save["length"], save["decoded"]
    block = save["block"]
    flag, body, parity = decoded["data"][0], decoded["data"][1:-1], decoded["data"][-1]
    xor = 0
    for byte in decoded["data"][:-1]:
        xor ^= byte
    leader_ok = set(decoded["leader"]) == {LEADER_HALF}
    firsts = decoded["firsts"]
    middle = sorted(set(firsts[1:-1]))
    leader_hz = TSTATES_PER_SECOND / (2 * sum(decoded["leader"]) / len(decoded["leader"]))
    ones = [h for h, bit in zip(decoded["halves"][1::2], decoded["bits"]) if bit]
    zeros = [h for h, bit in zip(decoded["halves"][1::2], decoded["bits"]) if not bit]
    ends = save["block_ends"]
    later = ", ".join(f"{(b - a) / TSTATES_PER_SECOND:.1f} s" for a, b in zip(ends, ends[1:]))
    lines += [
        "<h3>The one noise: SAVE</h3>",
        f"<p>SAVE (#R$84CC(DO_SAVE)) writes four headerless blocks -- the variables, the "
        f"objects, the timers and characters, the rooms -- through the ROM's SA-BYTES "
        f"(${SA_BYTES:04X}) and then reads them back through LD-BYTES (${LD_BYTES:04X}) in "
        "verify mode. SA-BYTES makes the tape signal by flipping bit 3 of port $FE, the "
        "MIC socket, with the border going red and cyan for the leader and blue and "
        "yellow for the data. It never touches bit 4, so this is the signal on the lead "
        "to the tape recorder, not the speaker; a real 48K plays it quietly through its "
        "speaker as well, because the MIC and speaker lines share a pin of the ULA "
        "(that is the hardware, not measured here). LOAD and the verify only read: "
        "LD-BYTES writes port $FE to flash the border with bit 3 set and bit 4 clear, "
        "so what is heard while loading is the tape itself.</p>",
        "<p>The recording is SAVE's first block, the 29 bytes at #R$B6EB, from the "
        "first OUT of SA-BYTES to its return: the leader, the two sync pulses, the flag "
        "byte, the block and the parity byte. The other three blocks follow at once and "
        f"sound the same, only longer ({later}).</p>",
        f'<div id="save" style="margin:1.2em 0">',
        "<h4>SAVE's first block</h4>",
        "<p>Recorded: the walkthrough's game in the simulator, SAVE typed at the prompt "
        f"and a key pressed for its \"start TAPE\" message; the T-state of every change of "
        "bit 3 of port $FE logged, and rendered as 16-bit mono at 44100 Hz. Nothing is "
        "synthesised.</p>",
        f"<p>{length / TSTATES_PER_SECOND:.2f} s, {len(edges):,} edges; the leader "
        f"{leader_hz:.0f} Hz, the data {TSTATES_PER_SECOND / (2 * sum(ones) / len(ones)):.0f} "
        f"Hz for a 1 and {TSTATES_PER_SECOND / (2 * sum(zeros) / len(zeros)):.0f} Hz for a "
        "0, as measured.</p>",
        f'<audio controls preload="none" src="{AUDIO}/{SAVE_WAV}">'
        f'<a href="{AUDIO}/{SAVE_WAV}">{SAVE_WAV}</a></audio>',
        "<p>Checked against the ROM's loops and the timings the TZX tape format documents "
        f"for them. The leader loop (a DJNZ from $A4, 163 turns of 13 T-states and a last "
        f"of 8, and 41 more around it: {LEADER_HALF:,}) made "
        f"{decoded['leader_outs']:,} OUTs, so {len(decoded['leader']):,} pulses, "
        + ("every one" if leader_ok else "<b>not every one</b>")
        + f" {LEADER_HALF:,} T-states (documented: {DATA_LEADER_PULSES:,} of "
        f"{LEADER_HALF:,} for a data block). The first is at the level the line was "
        "already at, so the recording hears one fewer. The sync pulses were "
        f"{decoded['sync'][0]} and {decoded['sync'][1]} T-states (documented {SYNC[0]} and "
        f"{SYNC[1]}). Then {len(decoded['bits']):,} bits, "
        f"{len(decoded['halves']):,} half-waves, "
        + ("every one" if not decoded["others_off"] else
           f"all but {decoded['others_off']} of them")
        + f" exactly {BIT_HALF[0]} or {BIT_HALF[1]:,} T-states except the first of each "
        "byte, which is out by a few while the ROM fetches the byte: "
        f"{firsts[0]:+d} for the flag byte, "
        + " or ".join(f"{d:+d}" for d in middle)
        + f" for each of the {len(firsts) - 2} bytes of the block, and {firsts[-1]:+d} "
        "for the parity byte"
        + (f"; then SA/LD-RET wrote ${decoded['end_value'][0]:02X} (the white border "
           f"BORDCR holds, and the line low) {decoded['end_gap']:,} T-states on"
           if decoded["end_gap"] else "")
        + f". Read back as LD-BYTES reads it, the signal carries the flag byte "
        f"${flag:02X}, "
        + (f"the {len(body)} bytes that were at #R$B6EB when SAVE ran"
           if body == block else f"<b>{len(body)} bytes that differ from #R$B6EB</b>")
        + f", and a parity byte ${parity:02X}"
        + (", the exclusive-or of all the others" if parity == xor else " (wrong)")
        + ".</p>",
        f"<p>And the whole save, all four blocks ({run['tape_edges']:,} edges), played "
        "back into the EAR bit of port $FE half a second after the key for the "
        "verify: the ROM's own LD-BYTES "
        + ("accepted all four blocks and the game carried on"
           if run["verified"] == 4 else
           f"accepted {run['verified']} of the four blocks")
        + ", with no \"TAPE ERROR\".</p>",
        "</div>",
    ]
    body_html = "\n".join(lines)
    for line in body_html.splitlines():
        if line.startswith((";", "[")):
            raise RuntimeError(f"a section line starts with {line[0]!r}: {line[:40]}")
    return _unlink(body_html, listing)


def _unlink(text: str, listing: _Listing) -> str:
    """#R only where the address starts an entry; otherwise plain."""
    def one(m):
        if int(m.group(1), 16) in listing.entries:
            return m.group(0)
        return m.group(2)[1:-1] if m.group(2) else "$" + m.group(1)
    return re.sub(r"#R\$([0-9A-F]{4})(\([^()]*\))?", one, text)


def _check_listing(listing: _Listing) -> None:
    """Every OUT to port $FE in the listing is one the page describes."""
    to_fe = {a for a, i in listing.outs.items() if "$FE" in i}
    if to_fe != set(OUTS):
        raise RuntimeError("OUTs to port $FE changed: "
                           + ", ".join(f"${a:04X}" for a in sorted(to_fe ^ set(OUTS))))
    others = {i for a, i in listing.outs.items() if a not in OUTS}
    if any(f"${PRINTER_PORT:02X}" not in i for i in others):
        raise RuntimeError(f"an OUT to neither $FE nor $FB: {sorted(others)}")
    if set(listing.rom_calls.values()) - {SA_BYTES, LD_BYTES}:
        raise RuntimeError("a call into the ROM other than SA-BYTES and LD-BYTES: "
                           + ", ".join(f"${a:04X}" for a in listing.rom_calls))


def build(html_dir: Path, log=print) -> dict[str, str]:
    """Record SAVE's first block into html_dir/audio, check the rest is
    silence, and return the Sounds section."""
    audio = html_dir / "audio"
    audio.mkdir(parents=True, exist_ok=True)
    listing = _Listing(SKOOL)
    _check_listing(listing)

    log("Running The Hobbit for its sounds...")
    run = _play(SNAPSHOT)
    game = run["game"]
    memory = run["first_prompt"]
    pictures = bh.keyed_table(memory, bh.PICTURE_TABLE)

    t0, t1 = run["save_start"], run["block_ends"][0]
    edges = _mic_edges(game.tracer.outs, t0, t1)
    if not edges:
        raise RuntimeError("SAVE made no MIC edges")
    length = t1 - t0
    ends = list(edges)
    if len(ends) % 2:
        ends.append(length)
    _write_wav(audio / SAVE_WAV, ends, length)
    save = {"edges": edges, "length": length,
            "decoded": _analyse(game.tracer.outs, t0, t1),
            "block": run["blocks"][0], "block_ends": run["block_ends"]}
    log(f"  {SAVE_WAV} written to {audio}")
    return {"Sounds": _section(listing, memory, run, save, pictures)}


if __name__ == "__main__":
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else bh.OUT_DIR / "html" / "hobbit"
    sections = build(out)
    (out / "sounds_section.html").write_text(sections["Sounds"], encoding="utf-8")
