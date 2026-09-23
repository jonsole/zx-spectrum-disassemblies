"""Drive The Hobbit in SkoolKit's simulator by handing it whole commands.

Typing a command a key at a time is fragile: the reader only takes a key when
it is waiting for one, the first key after the opening picture is swallowed by
a press-any-key wait, and a key pressed while the game is still printing the
last turn is simply lost -- which is how OPEN THE DOOR once arrived as R.

So this does what the game does itself for its opening move. On the first turn
the main loop copies LOOK and a carriage return into the input line at $6FF9
and goes straight on to the tokeniser; every later turn it calls READ_LINE
($6DD6) to fill that line from the keyboard. READ_LINE keeps its cursor in
registers only -- HL walks the line, B counts the room left in it -- so a
command is put in by stopping just after it sets them ($6DF3), writing the
text, moving HL and B past it, and pressing ENTER, which the reader then files
exactly as if the rest had been typed.

Waiting is done with breakpoints, never with the clock: run until the reader
asks for a line, and if the game stops in WAIT_FOR_ANY_KEY on the way, tap a
key there and carry on.

    from hobbit_drive import Hobbit
    game = Hobbit()          # loaded, past the title, at its first prompt
    game.say("OPEN THE DOOR")
    game.say("EAST")
    game.memory[...]         # read the game's state between turns
"""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import build_hobbit as bh

INPUT_LINE = 0x6FF9         # the line the tokeniser reads, ended by $0D
READ_LINE_READY = 0x6DF3    # READ_LINE with HL and B just set, before any key
WAIT_FOR_ANY_KEY = 0x969A
LINE_LENGTH = 0x80          # what READ_LINE starts B at


class Hobbit:
    """One game, in the simulator, taking commands whole."""

    def __init__(self, snapshot: Path | None = None):
        from skoolkit import CSimulator, read_bin_file
        from skoolkit.simulator import Simulator
        from skoolkit.snapshot import Snapshot

        snap = Snapshot.get(str(snapshot or bh.OUT_DIR / "hobbit.z80"))
        memory = list(snap.memory)
        memory[:0x4000] = read_bin_file(str(bh.ROM))
        self.sim = (CSimulator or Simulator)(
            memory, registers={"SP": bh.STACK, "IY": bh.SYSVARS},
            state={"iff": 1, "im": 1, "tstates": 0})
        self.tracer = bh._key_tracer_class()(self.sim)
        self.sim.set_tracer(self.tracer)
        self.memory = self.sim.memory
        self.pc = bh.ENTRY
        self.any_key_waits = 0
        # The title screen waits for a key of its own; after that, the first
        # prompt comes only once the opening picture is drawn and its
        # press-any-key wait has been answered.
        self.run([], 2.0)
        self.run(["SPACE"], 0.2)
        self.ready()

    @property
    def seconds(self) -> float:
        """Emulated time so far -- what to time anything by."""
        from skoolkit.simutils import T
        return self.sim.registers[T] / bh.TSTATES_PER_SECOND

    def run(self, keys: list[str], seconds: float, stop: int = 0) -> None:
        """Run with `keys` held, for up to `seconds`, or until PC is `stop`."""
        from skoolkit.simutils import PC, T

        self.tracer.keys = set(keys)
        if stop and self.pc == stop:
            # A trace that starts on its own stop address ends at once.
            self.sim.trace(self.pc, 0, 1, 0, True, None, None, None, None, None)
            self.pc = self.sim.registers[PC]
        self.sim.trace(self.pc, stop, 0,
                       self.sim.registers[T] + int(seconds * bh.TSTATES_PER_SECOND),
                       True, None, None, None, None, None)
        self.pc = self.sim.registers[PC]

    def ready(self) -> None:
        """Run until the game asks for a line."""
        for _ in range(10):
            self.run([], 60, stop=READ_LINE_READY)
            if self.pc == READ_LINE_READY:
                return
            if WAIT_FOR_ANY_KEY <= self.pc < WAIT_FOR_ANY_KEY + 14:
                self.any_key_waits += 1
                self.run(["SPACE"], 0.05)
                self.run([], 0.05)
                continue
        raise RuntimeError(f"the game never asked for a line (PC ${self.pc:04X})")

    def say(self, command: str) -> None:
        """Give the game one command, and run until it wants the next."""
        from skoolkit.simutils import B, H, L

        self.ready()
        text = command.upper()
        if len(text) >= LINE_LENGTH:
            raise ValueError("longer than the input line")
        for i, char in enumerate(text):
            self.memory[INPUT_LINE + i] = ord(char)
        cursor = INPUT_LINE + len(text)
        registers = self.sim.registers
        registers[H], registers[L] = cursor >> 8, cursor & 0xFF
        registers[B] = LINE_LENGTH - len(text)
        self.run(["ENTER"], 0.10)
        self.run([], 0.10)
        self.ready()


if __name__ == "__main__":
    game = Hobbit()
    player = next(r for r in bh.object_records(game.memory) if r["number"] == 0)
    where = player["start"] + 16
    print(f"at the first prompt after {game.seconds:.1f}s; location {game.memory[where]}")
    for command in sys.argv[1:] or ["OPEN THE DOOR", "EAST", "WEST"]:
        game.say(command)
        print(f"  {command:<16} location {game.memory[where]:3d}  "
              f"picture looked up {game.memory[0x7F77]:3d}  at {game.seconds:.1f}s")
