# ZX Spectrum game disassemblies

Reproducible disassemblies of six Spectrum games, built with
[SkoolKit](https://skoolkit.ca). Each is a script that takes an original tape
or snapshot and produces a commented disassembly, a browsable HTML version, and
a snapshot you can debug at source level.

| Game | Coverage | Build |
|---|---|---|
| Atic Atac (1983, Ultimate) | **100%** &mdash; 30208 of 30208 bytes, every routine, table and variable named, every address the code or the comments use a label or an equate, a map of the castle and every room drawn with what is in it | `scripts/build_aticatac.py` |
| Manic Miner (1983, Bug-Byte) | partial | `scripts/build_manicminer.py` |
| Fairlight (1985, The Edge) | **100%** &mdash; 42240 bytes from $5B00, the 41607 the protected tape loads (Release 2) and the loader's own; all 373 entries titled, described and labelled, the author's own names where his leftover source gives them; 3476 of 3545 instructions seen to run; the rooms, the parts they are drawn from, the object table, templates, font, textures, sprites and text laid out record by record from the game at build time (credit below) | `scripts/build_fairlight.py` |
| Knight Lore (1984, Ultimate) | **100%** &mdash; 40696 of 40696 bytes, all 844 entries titled and described, no placeholder names, the rooms laid out record by record from the game at build time (map credited below) | `scripts/build_knightlore.py` |
| Pentagram (1986, Ultimate) | **100%** &mdash; 41472 bytes from $5E00, the 31390 the tape loads and the buffers above; all 592 entries titled, described and labelled, 4089 of 4185 instructions seen to run; the rooms, templates and sprites laid out record by record from the game at build time | `scripts/build_pentagram.py` |
| Alien 8 (1985, Ultimate) | **100%** &mdash; 42240 bytes from $5B00, the 40195 the tape loads and the variables below; all 622 entries titled, described and labelled, 4550 of 4602 instructions seen to run; the rooms, templates, places and sprites laid out record by record from the game at build time | `scripts/build_alien8.py` |
| Nightshade (1985, Ultimate) | **100%** &mdash; 42240 bytes from $5B00, the 35328 the protected tape loads and unscrambles and the variables below; all 476 entries titled, described and labelled, 4705 of 4806 instructions seen to run; the town, its buildings, tiles and sprites laid out record by record from the game at build time | `scripts/build_nightshade.py` |
| The Hobbit (1982, Melbourne House) | **100%** &mdash; 40000 of 40000 bytes, every routine, table, variable and message named and described, every record field described, the character scripts decoded step by step, and every address the code or the comments use a label | `scripts/build_hobbit.py` |
| Ant Attack (1983, Sandy White / Quicksilva) | **100%** &mdash; 41984 of 41984 bytes, the system variables and the BASIC included; every routine named, described and commented, every address the code uses a label, every instruction but three seen to run; no placeholder titles, each sprite frame and each row of the city an entry of its own | `scripts/build_antattack.py` |

The Hobbit's, Atic Atac's, Ant Attack's, Knight Lore's, Pentagram's, Alien 8's, Nightshade's and Fairlight's HTML disassemblies are published at
**<https://jonsole.github.io/zx-spectrum-disassemblies/>**: The Hobbit with a
page on how the game works and deep dives on the parser, the characters,
fighting, the text and the pictures; a map with its layers, and pages for its
locations (with their pictures), objects, characters and actions; animations,
a page on its sound (there is none), and its bugs, tested pokes and trivia; Atic Atac with how it works (drawing,
movement, the monsters, doors and keys, the quest), the castle map with its layers,
its loader, room types, sprites, graphics, animations and sounds, and its bugs,
tested pokes and trivia; Ant Attack with how it works (drawing, movement,
the ants, grenades, rescue), the city map with its layers and drawn whole in
the game's own projection, its levels, sprites, animations, sounds and
scripts, and its bugs, pokes and trivia;
Knight Lore with how it works (drawing, the depth sort, collision, day and
night, the charms), the castle map with its layers, its graphics, animations
and sounds, and its bugs, pokes and trivia; and Pentagram with how it works (drawing, movement, rooms and
doorways, the quest, bolts and creatures), the whole world map with its
layers, every room, its graphics, animations and sounds, and its bugs,
tested pokes and trivia; and Alien 8 with how it works (drawing, the robot's
turning, rooms and doorways, the valves and chambers, the clock and the remote
robots), the station map with its layers, every room, its graphics,
animations and sounds, and its bugs, tested pokes and trivia; and Nightshade
with how it works (the protection, how the scrolling town is drawn,
movement, the creatures, the quest), the whole town map with its layers,
its buildings and cell types, its graphics, animations and sounds, and its
bugs, tested pokes and trivia; and Fairlight with how it works (the protected
loader, how a room is drawn from its commands, how a moving object is
composited, movement and collision, things and creatures), the castle map
with its layers, every room, its textures, parts, object types, sprites and
font, animations and the loading tune, and its bugs, tested pokes and trivia.

## What is committed where

The `master` branch holds no game bytes. What is here is addresses, structure
and prose &mdash; control files, ref files and the code that derives one from
the other. Point a build script at a tape you own and it produces the game's
bytes locally, under `game_disassembly/`, which is gitignored.

The one exception is the `gh-pages` branch, which publishes The Hobbit's,
Atic Atac's, Ant Attack's, Knight Lore's, Pentagram's, Alien 8's, Nightshade's and Fairlight's built HTML disassemblies for the site above. That output does quote the game &mdash; its
code, its text and its pictures &mdash; for the purpose of study, as other
published SkoolKit disassemblies do. It is built locally with
the game's build script and `--html`, and copied there by
`scripts/publish_pages.py` (`--game hobbit`, `aticatac`, `antattack` or `knightlore`, `--tape` to
build first -- Knight Lore's snapshot, for it -- `--dry-run` to see what would change); nothing on
`master` depends on it. The landing page's source is `pages/index.html`.

The same goes for `roms/48.rom`, which several builds need and which you supply
yourself.

## Building

You need Python 3.11+, SkoolKit, a 48K ROM at `roms/48.rom`, sjasmplus at
`tools/sjasmplus/`, and a tape image or snapshot.

```
pip install skoolkit
python scripts/build_aticatac.py --tape "Atic Atac.tap" --html
python scripts/build_knightlore.py --snapshot "Knight Lore (1984)(Ultimate).sna" --tape "Knight Lore (1984)(Ultimate).tzx" --html
python scripts/build_antattack.py --tape "Ant Attack.tzx" --html
python scripts/build_pentagram.py --tape "Pentagram.tzx" --html
python scripts/build_alien8.py --tape "Alien 8 (1985)(Ultimate).tap" --html
python scripts/build_nightshade.py --tape "Nightshade (1985)(Ultimate).tzx" --html
python scripts/build_fairlight.py --tape "Fairlight (1985)(The Edge)(Release 2).tzx" --html
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

### Knight Lore, Pentagram and Alien 8, rearranged

`python scripts/room_editor.py page` writes a room editor for the original
Knight Lore, Pentagram and Alien 8: one HTML file that opens a snapshot of your
copy of any of them, tells which it is, edits its rooms, templates, floor
shapes and starting rooms -- and Knight Lore's collectables and Alien 8's
valves -- in the room designer from the
[emulator](https://github.com/jonsole/zx-spectrum-emulator)'s Filmation
remakes, and downloads the game again with them packed into its own tables. It
holds none of any game's bytes, and it is on the site, one page for all three,
as [room-editor.html](https://jonsole.github.io/zx-spectrum-disassemblies/room-editor.html).
Alien 8's sprite layout and graphic table, which Knight Lore and Pentagram
take from their remakes, are `scripts/room_editor_art.py`'s.
[docs/room-editor-guide.md](docs/room-editor-guide.md) is the user guide, and
the page's **Help**; [docs/room-editor.md](docs/room-editor.md) says what each
original can hold and how it was checked.

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

## Notes

[notes/](notes/) holds a written account of each game, kept while it is being
worked out rather than written up afterwards: an overview to start from, a
note per subject answering one question each -- how it works, how that was
found, how sure it is and what is still open -- a journal, and how to drive
the game in the emulator. The HTML's prose pages are the polished form; the
notes keep the evidence and the dead ends. Like the control files they are
prose and addresses only, with no bytes of the game. So far:
[The Hobbit](notes/hobbit/README.md), [Atic Atac](notes/aticatac/README.md),
[Knight Lore](notes/knightlore/README.md),
[Ant Attack](notes/antattack/README.md), [Pentagram](notes/pentagram/README.md),
[Alien 8](notes/alien8/README.md), [Nightshade](notes/nightshade/README.md) and
[Fairlight](notes/fairlight/README.md).

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

Fairlight's disassembly was read beside **Ville Krumlinde**'s
([FairlightZ80](https://github.com/VilleKrumlinde/FairlightZ80)), from which
some names and facts are taken, each checked against the game; it carries no
licence, so none of its prose is reproduced. `scripts/build_fairlight_krumlinde.py`
assembles his source as it is, for stepping through in the emulator.

Knight Lore's code map &mdash; which bytes are instructions, which are data, and
what the routines are called &mdash; is derived from the disassembly by
**tcdev** (2017), as converted to SkoolKit form by **Michael R. Cook** (2019).
Only that factual layer is taken; neither work carries a licence, so none of
their prose is reproduced and the commentary here is written from the code.

Games are copyright their respective owners: Atic Atac, Knight Lore and the
Ultimate Play the Game name, Ultimate; Manic Miner, Bug-Byte/Software Projects;
Fairlight, The Edge.
