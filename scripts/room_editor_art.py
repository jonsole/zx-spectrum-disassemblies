#!/usr/bin/env python3
"""The sprite layout and graphic table the room editor draws Alien 8 with.

    python scripts/room_editor_art.py alien8 [--snapshot FILE]

Knight Lore and Pentagram have Filmation remakes in the emulator repository,
and the room editor carries each one's sprites.json and graphics.json. Alien 8
has no remake, so this writes the two for it, into
scripts/room_editor_art/alien8/, from the snapshot build_alien8.py leaves:

  sprites.json   where each sprite sits on the sheet the editor paints: one
                 rectangle a sprite, the sprite's own width and height, in
                 address order. The editor paints the pixels from the copy of
                 the game it is given; this holds only the rectangles.
  graphics.json  for each graphic number, the sprite it draws (from the game's
                 GRAPHICS table at $7827), its drawing nudge, and its box.

The nudge is harvested, not typed in: every graphic's update routine (the
UPDATES table at $A7EA) begins by setting a pixel nudge in +$12 and +$13 of
the object's record, through one of the short DRAW_AT_... routines that end
at SET_PIXEL_ADJ ($BF77) -- see notes/alien8/graphic-numbers.md. Each routine
is run in SkoolKit's simulator on a record of that graphic until it reaches
SET_PIXEL_ADJ, once facing each way (bit 6 of the flags), and HL there is the
nudge: L the x, H the y, as signed bytes. A graphic whose routine never sets
one -- the empty ones, the panel's -- has none. The box is the commonest one
the templates that place the graphic give it, the way graphics.py folds the
remakes' boxes, stored the unmirrored way round.

None of it is a byte of the game: numbers, names and rectangles, as the
remakes' own files are.
"""
from __future__ import annotations

import argparse
import collections
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "scripts" / "room_editor_art"

ALIEN8 = {
    "snapshot": ROOT / "game_disassembly" / "alien8" / "alien8.z80",
    "graphics": 0x7827,             # GRAPHICS: a word a graphic, its sprite
    "graphic_count": 132,
    "updates": 0xA7EA,              # UPDATES: a word a graphic, its update routine
    "update_count": 131,            # graphic 131 has no routine: the panel's icon
    "set_pixel_adj": 0xBF77,        # the shared end of every nudge routine
    "object_table": 0x73C8,         # two pages of object templates
    "object_slots": 40,
    "background_table": 0x7519,
    "background_count": 14,
}

MIRROR = 0x40
RECORD = 0x6000                     # where the harvest puts its one record: in
                                    # the room directory, which it does not need
STACK = 0x5F00
TRAP = 0x0000                       # a return address that stops a run
TIME_LIMIT = 3500000                # a second of the machine's time


def signed(byte: int) -> int:
    return byte - 256 if byte > 127 else byte


def read_memory(snapshot: Path) -> list[int]:
    from skoolkit.snapshot import Snapshot

    return list(Snapshot.get(str(snapshot)).memory)


def word(memory, address: int) -> int:
    return memory[address] | (memory[address + 1] << 8)


def harvest(memory, routine: int, graphic: int, flags: int):
    """Run a graphic's update routine on a record of it until it sets its
    nudge; the nudge as (x, y), or None if it never does."""
    from skoolkit import CSimulator
    from skoolkit.simulator import Simulator
    from skoolkit.simutils import PC, SP, T

    ram = list(memory)
    ram[RECORD:RECORD + 32] = [0] * 32
    ram[RECORD] = graphic
    ram[RECORD + 1] = ram[RECORD + 2] = 0x80
    ram[RECORD + 3] = 0x40
    ram[RECORD + 7] = flags
    ram[STACK - 2:STACK] = [TRAP & 0xFF, TRAP >> 8]
    from skoolkit.trace import Tracer

    simulator = (CSimulator or Simulator)(ram, state={"iff": 0, "im": 1, "tstates": 0})
    simulator.set_tracer(Tracer(simulator, 0, 0, 0, [0] * 16, 0, False))
    simulator.registers[SP] = STACK - 2
    simulator.registers[8], simulator.registers[9] = RECORD >> 8, RECORD & 0xFF   # IX
    simulator.trace(routine, ALIEN8["set_pixel_adj"], 0, TIME_LIMIT, False,
                    None, None, None, None, None)
    if simulator.registers[PC] != ALIEN8["set_pixel_adj"]:
        return None
    del T
    h, l = simulator.registers[6], simulator.registers[7]                         # H, L
    return signed(l), signed(h)


def sprites_of(memory):
    """Each sprite the graphic table reaches, in address order: (address,
    width in bytes, height). An empty record -- width or height 0 -- draws
    nothing and is left out."""
    seen = {}
    for graphic in range(ALIEN8["graphic_count"]):
        at = word(memory, ALIEN8["graphics"] + 2 * graphic)
        width, height = memory[at] & 0x1F, memory[at + 1]
        if width and height:
            seen[at] = (width, height)
    return [(at,) + seen[at] for at in sorted(seen)]


def lay_out(sprites, sheet_width=640, gap=3):
    """Rectangles in rows across the sheet, a gap between, as sheet.py does
    it without the bands."""
    x, y, tallest = 1, 1, 0
    out = []
    for at, width, height in sprites:
        pixels = width * 8
        if x > 1 and x + pixels + 1 > sheet_width:
            x, y, tallest = 1, y + tallest + gap, 0
        out.append((at, x, y, pixels, height))
        x += pixels + gap
        tallest = max(tallest, height)
    return out


def template_boxes(memory):
    """graphic -> every box a template piece gives it, unmirrored."""
    boxes = collections.defaultdict(list)

    def walk(at, stride, box_at, flags_at):
        while memory[at]:
            box = tuple(memory[at + box_at:at + box_at + 3])
            if memory[at + flags_at] & MIRROR:
                box = (box[1], box[0], box[2])
            boxes[memory[at]].append(box)
            at += stride

    for slot in range(ALIEN8["object_slots"]):
        at = word(memory, ALIEN8["object_table"] + 2 * slot)
        if at:
            walk(at, 5, 1, 4)
    for index in range(ALIEN8["background_count"]):
        walk(word(memory, ALIEN8["background_table"] + 2 * index), 8, 4, 7)
    return boxes


def write_alien8(snapshot: Path) -> None:
    memory = read_memory(snapshot)
    placed = lay_out(sprites_of(memory))
    sprite_name = {}
    rects = {}
    for n, (at, x, y, w, h) in enumerate(placed, start=1):
        sprite_name[at] = "sprites.%d" % n
        rects[str(n)] = {"x": x, "y": y, "w": w, "h": h, "trim": 0}
    sheet = {
        "sheet": {"file": "sprites.png", "colours": {
            "ink": [255, 255, 255, 255], "paper": [0, 0, 0, 255],
            "transparent": [0, 0, 0, 0], "stray": [255, 0, 0, 255],
            "border": [255, 0, 255, 255]}},
        "bytes": {"header": ["width", "height"], "rows": "bottom-up",
                  "interleaved": True, "first": "mask", "maskBit": "covers"},
        "group": {"sprites": {"sprites": rects}},
    }

    boxes = template_boxes(memory)
    graphics = {}
    harvested = 0
    for graphic in range(ALIEN8["graphic_count"]):
        at = word(memory, ALIEN8["graphics"] + 2 * graphic)
        entry = {"number": graphic}
        if at in sprite_name:
            entry["sprite"] = sprite_name[at]
        if graphic < ALIEN8["update_count"]:
            routine = word(memory, ALIEN8["updates"] + 2 * graphic)
            plain = harvest(memory, routine, graphic, 0)
            turned = harvest(memory, routine, graphic, MIRROR)
            if plain:
                harvested += 1
                entry["x"], entry["y"] = plain
                if turned and turned != plain:
                    entry["mirrored"] = {"x": turned[0], "y": turned[1]}
        if boxes.get(graphic):
            counts = collections.Counter(boxes[graphic])
            box = max(counts, key=lambda b: (counts[b], b))
            entry["size"] = {"u": box[0], "v": box[1], "z": box[2]}
        if len(entry) > 1:
            graphics["graphic_%03d" % graphic] = entry

    out = OUT / "alien8"
    out.mkdir(parents=True, exist_ok=True)
    (out / "sprites.json").write_text(json.dumps(sheet, indent=1) + "\n", encoding="utf-8")
    (out / "graphics.json").write_text(
        json.dumps({"sprites": "sprites.json", "graphics": graphics}, indent=1) + "\n",
        encoding="utf-8")
    print(f"Wrote {out}: {len(placed)} sprites, {len(graphics)} graphics, "
          f"{harvested} nudges harvested", flush=True)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("game", choices=["alien8"])
    parser.add_argument("--snapshot", type=Path, default=ALIEN8["snapshot"])
    args = parser.parse_args()
    if not args.snapshot.is_file():
        sys.exit(f"No snapshot at {args.snapshot} -- run build_alien8.py first.")
    write_alien8(args.snapshot)


if __name__ == "__main__":
    main()
