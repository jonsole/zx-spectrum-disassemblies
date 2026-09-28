#!/usr/bin/env python3
"""Write the room editor for Ultimate's Filmation games: one HTML file.

    python scripts/room_editor.py page [--out FILE]

The page opens a snapshot of your own copy of Knight Lore, Pentagram or Alien 8, tells
which game it is, draws the castle in the Filmation room designer and
templates editor, and downloads the game again with your rooms packed into
its own tables. Nothing runs behind it: this writes it once, and a browser is
all it needs after that.

What it is made of:

  room_editor.html   the page: the snapshot, the two editors' frames, Save,
                     Download, Export and Import
  room_editor.js     the games: telling them apart, reading a snapshot,
                     painting the sprite sheet out of it, decoding the castle
                     and packing it back -- one profile a game
  the designer       room_view.html and templates_view.html from the emulator
                     repository's examples/filmation/vscode, with their models
                     inlined, run unchanged with a host of the page's own
  each game's art    sprites.json and graphics.json: Knight Lore's and
                     Pentagram's from their Filmation remakes in
                     examples/filmation/<game>, Alien 8's from
                     room_editor_art.py -- names, rectangles, boxes and pixel
                     nudges

None of it is a byte of any game. Every pixel, room and template on the page
comes from the copy the person using it gives it, so the page can be shared
as it is; publish_pages.py puts it at the top of the site, as room-editor.html,
every time it publishes a game, and each game's entry links to it there.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCRIPTS = ROOT / "scripts"
TEMPLATE = SCRIPTS / "room_editor.html"
MODULE = SCRIPTS / "room_editor.js"
OUT = ROOT / "game_disassembly" / "room-editor.html"

# The designer and the remakes live in the emulator repository this one is a
# submodule of, and are used as they stand rather than copied.
FILMATION = ROOT.parent / "examples" / "filmation"
DESIGNER = FILMATION / "vscode"

# The games the page serves, by the id room_editor.js gives them, and where
# the sprite layout and graphic table it carries for each come from: the
# Filmation remakes' own, or -- Alien 8 has no remake -- what
# room_editor_art.py harvests from the disassembly.
ART = {
    "knightlore": FILMATION / "knightlore",
    "pentagram": FILMATION / "pentagram",
    "alien8": SCRIPTS / "room_editor_art" / "alien8",
}
GAMES = tuple(ART)


def script_json(value) -> str:
    """A value as JSON that can sit inside a <script>: the designer's page is
    itself HTML, and its own </script> would end the one it is carried in."""
    return json.dumps(value, ensure_ascii=False).replace("</", "<\\/")


def inlined(leaf: str) -> str:
    """A designer page with its models in, the way its hosts inline it.

    Every /*@name.js@*/ marker it holds is that file from the designer's
    directory, so a model a page comes to need is picked up without this
    knowing. The /*@host@*/ marker is left for the editor to fill in once a
    snapshot is open.
    """
    html = (DESIGNER / leaf).read_text(encoding="utf-8")
    for name in sorted(set(re.findall(r"/\*@([a-z_]+\.js)@\*/", html))):
        html = html.replace("/*@%s@*/" % name, (DESIGNER / name).read_text(encoding="utf-8"))
    if html.count("/*@host@*/") != 1:
        sys.exit(f"{leaf} has no single /*@host@*/ marker to put a host into")
    return html


def page(out: Path) -> None:
    if not DESIGNER.is_dir():
        sys.exit(f"The room designer is not at {DESIGNER}.\nThis is used from the "
                 f"zx-spectrum-emulator checkout this repository is a submodule of.")
    art = {}
    for game in GAMES:
        remake = ART[game]
        art[game] = {key: json.loads((remake / leaf).read_text(encoding="utf-8"))
                     for key, leaf in (("sprites", "sprites.json"), ("graphics", "graphics.json"))}

    html = TEMPLATE.read_text(encoding="utf-8")
    for marker, value in (
            ("/*@room_editor.js@*/", MODULE.read_text(encoding="utf-8")),
            ('/*@designer@*/""', script_json(inlined("room_view.html"))),
            ('/*@templates@*/""', script_json(inlined("templates_view.html"))),
            ("/*@art@*/null", script_json(art))):
        if html.count(marker) != 1:
            sys.exit(f"{TEMPLATE.name} has {html.count(marker)} of {marker}, not one")
        html = html.replace(marker, value, 1)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(html, encoding="utf-8")
    print(f"Wrote {out} ({len(html.encode('utf-8')) // 1024} KB), for "
          f"{', '.join(GAMES)}. Open it in a browser and give it a snapshot; "
          f"nothing else runs.", flush=True)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    commands = parser.add_subparsers(dest="command", required=True)
    p = commands.add_parser("page", help="write the editor page")
    p.add_argument("--out", type=Path, default=OUT)
    args = parser.parse_args()
    page(args.out)


if __name__ == "__main__":
    main()
