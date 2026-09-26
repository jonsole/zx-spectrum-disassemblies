# ZX Spectrum game disassemblies

Reproducible disassemblies of six Spectrum games, built with
[SkoolKit](https://skoolkit.ca). Each is a script that takes an original tape
or snapshot and produces a commented disassembly, a browsable HTML version, and
a snapshot you can debug at source level.

| Game | Coverage | Build |
|---|---|---|
| Atic Atac (1983, Ultimate) | **100%** &mdash; 30208 of 30208 bytes, every routine, table and variable named, every address the code or the comments use a label or an equate, a map of the castle and every room drawn with what is in it | `scripts/build_aticatac.py` |
| Manic Miner (1983, Bug-Byte) | partial | `scripts/build_manicminer.py` |
| Fairlight (1985, The Edge) | partial | `scripts/build_fairlight.py` |
| Knight Lore (1984, Ultimate) | **100%** &mdash; 40696 of 40696 bytes, all 844 entries titled and described, no placeholder names, the rooms laid out record by record from the game at build time (map credited below) | `scripts/build_knightlore.py` |
| The Hobbit (1982, Melbourne House) | **100%** &mdash; 40000 of 40000 bytes, every routine, table, variable and message named and described, every record field described, the character scripts decoded step by step, and every address the code or the comments use a label | `scripts/build_hobbit.py` |
| Ant Attack (1983, Sandy White / Quicksilva) | **100%** &mdash; 41984 of 41984 bytes, the system variables and the BASIC included; every routine named, described and commented, every address the code uses a label, every instruction but three seen to run; pages on how it works, the city drawn whole in the game's own projection, the levels, sprites and scripts | `scripts/build_antattack.py` |

The Hobbit's, Atic Atac's and Ant Attack's HTML disassemblies are published at
**<https://jonsole.github.io/zx-spectrum-disassemblies/>**: The Hobbit with a
page on how the game works, a map, and pages for its locations (with their
pictures), objects, characters and actions; Atic Atac with its loader, room
types, sprites, graphics and sounds; Ant Attack with how it works, the whole
city drawn in the game's own projection, its levels, sprites and scripts.

## What is committed where

The `master` branch holds no game bytes. What is here is addresses, structure
and prose &mdash; control files, ref files and the code that derives one from
the other. Point a build script at a tape you own and it produces the game's
bytes locally, under `game_disassembly/`, which is gitignored.

The one exception is the `gh-pages` branch, which publishes The Hobbit's,
Atic Atac's and Ant Attack's built HTML disassemblies for the site above. That output does quote the game &mdash; its
code, its text and its pictures &mdash; for the purpose of study, as other
published SkoolKit disassemblies do. It is built locally with
the game's build script and `--html`, and copied there by
`scripts/publish_pages.py` (`--game hobbit`, `--game aticatac` or `--game antattack`, `--tape` to
build first, `--dry-run` to see what would change); nothing on
`master` depends on it. The landing page's source is `pages/index.html`.

The same goes for `roms/48.rom`, which several builds need and which you supply
yourself.

## Building

You need Python 3.11+, SkoolKit, a 48K ROM at `roms/48.rom`, sjasmplus at
`tools/sjasmplus/`, and a tape image or snapshot.

```
pip install skoolkit
python scripts/build_aticatac.py --tape "Atic Atac.tap" --html
python scripts/build_knightlore.py --snapshot "Knight Lore (1984)(Ultimate).sna" --html
python scripts/build_antattack.py --tape "Ant Attack.tzx" --html
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

### The Hobbit, drawing faster

`build_hobbit.py --fast-draw` also assembles
[patches/hobbit_fast_draw.s](patches/hobbit_fast_draw.s) on top of the verified
source and writes `game_disassembly/hobbit/hobbit_fast.sna`: the same game, with
its pictures drawn about nine times faster -- Bag End in about half a second
rather than 6.7. The patch replaces only the plotting code, and the build
refuses one that changes a byte anywhere else. `scripts/check_fast_draw.py` then draws all
22 pictures in both and compares the whole of memory afterwards: every one is
identical, and the stack never goes deeper.
[docs/hobbit-fast-draw-plan.md](docs/hobbit-fast-draw-plan.md) says how.

### The Hobbit, watched while it runs

[hobbit-vscode/](hobbit-vscode/) is a VS Code extension, after
[Wilderland](https://github.com/efa/Wilderland), for The Hobbit running in the
[emulator](https://github.com/jonsole/zx-spectrum-emulator)'s debugger: a map
with every character where it is, every object with its place and flags, and a
log of everything the game says -- including what the other characters do
where the player cannot see, and what they only try out before deciding. It
reads it all from the running game; its README says how to install it.

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

Knight Lore's code map &mdash; which bytes are instructions, which are data, and
what the routines are called &mdash; is derived from the disassembly by
**tcdev** (2017), as converted to SkoolKit form by **Michael R. Cook** (2019).
Only that factual layer is taken; neither work carries a licence, so none of
their prose is reproduced and the commentary here is written from the code.

Games are copyright their respective owners: Atic Atac, Knight Lore and the
Ultimate Play the Game name, Ultimate; Manic Miner, Bug-Byte/Software Projects;
Fairlight, The Edge.
