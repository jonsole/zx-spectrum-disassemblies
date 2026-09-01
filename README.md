# ZX Spectrum game disassemblies

Reproducible disassemblies of three Spectrum games, built with
[SkoolKit](https://skoolkit.ca). Each is a script that takes the original tape
and produces a commented disassembly, a browsable HTML version, and a snapshot
you can debug at source level.

| Game | Coverage | Build |
|---|---|---|
| Atic Atac (1983, Ultimate) | **100%** &mdash; 30208 of 30208 bytes, 631 named entries | `scripts/build_aticatac.py` |
| Manic Miner (1983, Bug-Byte) | partial | `scripts/build_manicminer.py` |
| Fairlight (1985, The Edge) | partial | `scripts/build_fairlight.py` |

## Nothing copyrighted is committed here

No game bytes are in this repository, and none ever will be. What is here is
addresses, structure and prose &mdash; control files, ref files and the code
that derives one from the other. Point a build script at a tape you own and it
produces the game's bytes locally, under `game_disassembly/`, which is
gitignored.

The same goes for `roms/48.rom`, which several builds need and which you supply
yourself.

## Building

You need Python 3.11+, SkoolKit, a 48K ROM at `roms/48.rom`, sjasmplus at
`tools/sjasmplus/`, and a tape image.

```
pip install skoolkit
python scripts/build_aticatac.py --tape "Atic Atac.tap" --html
```

The build ends by reassembling what it disassembled and comparing it with the
tape, so a run that finishes has proved its own output:

```
401 spans, no overlaps, every sub-block accounted for
Verified: 30208 bytes reassemble byte-for-byte
```

`--html` additionally writes a browsable disassembly to
`game_disassembly/aticatac/html/`: every routine on its own page, memory maps,
and pages covering the tape protection, how the game is put together, where the
data goes, the room types, the sprites, the graphics, the sounds, and the bugs.

## How it is put together

[docs/game-examples.md](docs/game-examples.md) is the long version: how the tape
protection is defeated by running it, how code is told from data by playing the
game, how sprite formats are measured rather than guessed, and a running list of
the mistakes that produced &mdash; several of which stood for a while before
something contradicted them.

The short version is that as little as possible is asserted by hand. Sprite
extents are measured by watching the game's own drawing code. Room pictures are
drawn by running the game's own redraw routine. Sounds are recorded off port
`$FE`. Colours are read from the game's own attribute tables. Where something
genuinely cannot be derived &mdash; which way the player's four walk cycles
face, say &mdash; it is written down as told rather than dressed up as
measured.

## Debugging

Each build writes a `.sna` and a `.sld`. Load the ROM, then the snapshot and the
source-level debug info, into an emulator that reads them &mdash;
[zx-spectrum-emulator](https://github.com/jonsole/zx-spectrum-emulator) does,
over DAP or MCP &mdash; and you can step through the game against the
disassembly, with labels.

## Credit

The Atic Atac graphics names, and the technique of rendering sprites from the
game's own bytes with `#UDGARRAY` rather than pasting in screenshots, are from
[pobtastic's Atic Atac disassembly](https://skoolkit.arcadegeek.co.uk/ultimate/aticatac/).
Comparing the two corrected several things here.

Games are copyright their respective owners: Atic Atac and the Ultimate Play the
Game name, Ultimate; Manic Miner, Bug-Byte/Software Projects; Fairlight, The
Edge.
