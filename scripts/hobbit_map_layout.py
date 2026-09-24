"""Write the Hobbit extension's map layout: a grid cell for every location.

The cells are the ones the site's map uses (hobbit_pages.map_layout), found by
walking the exits by their compass directions. They are this project's own
layout, not the game's bytes, so the extension can carry them; what is drawn
at each cell -- the names, the exits, who is there -- the extension reads from
the running game.

    python scripts/hobbit_map_layout.py
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import build_hobbit as bh
import hobbit_pages as hp

OUT = Path(__file__).resolve().parent.parent / "hobbit-vscode" / "map_layout.json"


def main() -> None:
    memory = bh.game_memory(bh.OUT_DIR / "hobbit.z80")
    rooms = {k: r for k, r in bh.room_records(memory).items() if k}
    placed = hp.map_layout(rooms)
    # One location a line, so a change to the layout reads as a diff of the
    # locations that moved.
    lines = [f'  "{location}": [{x}, {y}]' for location, (x, y) in sorted(placed.items())]
    OUT.write_text('{"cells": {\n' + ",\n".join(lines) + "\n}}\n", encoding="utf-8")
    json.loads(OUT.read_text(encoding="utf-8"))
    print(f"wrote {OUT} ({len(lines)} locations)")


if __name__ == "__main__":
    main()
