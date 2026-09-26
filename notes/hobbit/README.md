# The Hobbit -- notes

*The Hobbit* (1982, Beam Software for Melbourne House; Philip Mitchell and
Veronika Megler), a text adventure with pictures for the 48K Spectrum.
Disassembled from the **v1.2** tape by `scripts/build_hobbit.py`; the v1.0
tape has been loaded and compared, not disassembled.

These are the working notes: how the game works, how it was worked out, and
what is still open. The commented disassembly itself is the build's output,
published at <https://jonsole.github.io/zx-spectrum-disassemblies/hobbit/>,
and each routine's own description is there, not repeated here.

## Status

- **Disassembly:** 100% -- 40000 of 40000 bytes, every routine, table,
  variable and message named and described, every address a label; it
  reassembles byte-for-byte on every build.
- **Fast-draw patch:** pictures drawn 9.4 times faster, 387 bytes changed;
  see [`docs/hobbit-fast-draw-plan.md`](../../docs/hobbit-fast-draw-plan.md).
- **Inspector:** a VS Code extension showing the running game's state,
  [`hobbit-vscode/`](../../hobbit-vscode/).

## Index

| Note | What it covers |
|---|---|
| [`overview.md`](overview.md) | **Start here** -- a tour of the findings, each linked to its deep dive |
| [`journal.md`](journal.md) | What was investigated, when and how, and what turned out wrong |
| [`driving.md`](driving.md) | Driving the game in the emulator: breakpoints, injecting commands, staging states, traps |
| [`memory-map.md`](memory-map.md) | Where everything is, by address |
| [`scoring.md`](scoring.md) | Where the score comes from, and why 100% cannot be reached |
| [`hidden-roads.md`](hidden-roads.md) | The road shut at random each game, and Elrond reading the map to open it |
| [`versions.md`](versions.md) | v1.0, v1.1, v1.2 and the Sinclair re-release: which is which, and what differs |
