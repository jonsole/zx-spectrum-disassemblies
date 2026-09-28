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
  the user guide     docs/room-editor-guide.md, made HTML for the page's Help

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
GUIDE = ROOT / "docs" / "room-editor-guide.md"

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


# The guide is written once, as Markdown for the repository, and the page's
# Help is made from it here -- so the two cannot drift apart. The venv has no
# Markdown library, and the guide needs only a little of it: headings,
# paragraphs, one level of bullets, tables, and bold, italic, code and links
# inside them. Anything else would come out as the text it is.
INLINE_CODE = re.compile(r"`([^`]+)`")
LINK = re.compile(r"\[([^\]]+)\]\(([^)\s]+)\)")
BOLD = re.compile(r"\*\*(.+?)\*\*")
ITALIC = re.compile(r"(?<![*\w])\*([^*]+)\*(?![*\w])")


def escaped(text: str) -> str:
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def inline(text: str) -> str:
    """One line's worth of Markdown as HTML. Code spans are set aside first,
    so nothing inside one is taken for emphasis or a dash."""
    codes = []

    def keep(match):
        codes.append("<code>" + escaped(match.group(1)) + "</code>")
        return "\0%d\0" % (len(codes) - 1)

    text = escaped(INLINE_CODE.sub(keep, text))

    def link(match):
        href = match.group(2)
        # A link within the guide stays in the page; any other opens beside
        # it, so following one does not close the editor and its work.
        outside = "" if href.startswith("#") else ' target="_blank" rel="noopener"'
        return '<a href="%s"%s>%s</a>' % (href.replace('"', "&quot;"), outside, match.group(1))

    text = LINK.sub(link, text)
    text = BOLD.sub(r"<strong>\1</strong>", text)
    text = ITALIC.sub(r"<em>\1</em>", text)
    text = text.replace("--", "&mdash;")
    return re.sub("\0(\\d+)\0", lambda m: codes[int(m.group(1))], text)


def slug(heading: str) -> str:
    """A heading's anchor, the way GitHub makes it, so a #link in the guide
    goes to the same place on GitHub and in the page."""
    text = re.sub(r"[^\w\- ]", "", heading.lower())
    return text.replace(" ", "-")


def guide_html(markdown: str) -> str:
    """The guide as HTML for the page: its own heading left out, since the
    Help window has one, and a list of its sections put first."""
    lines = markdown.replace("\r\n", "\n").split("\n")
    body = []
    sections = []
    i = 0
    while i < len(lines):
        line = lines[i]
        if not line.strip():
            i += 1
            continue
        heading = re.match(r"(#{1,6}) (.*)", line)
        if heading:
            level = len(heading.group(1))
            text = heading.group(2).strip()
            if level > 1:
                anchor = slug(text)
                if level == 2:
                    sections.append((anchor, text))
                body.append('<h%d id="%s">%s</h%d>' % (level, anchor, inline(text), level))
            i += 1
            continue
        if line.startswith("|"):
            rows = []
            while i < len(lines) and lines[i].startswith("|"):
                cells = [c.strip() for c in lines[i].strip().strip("|").split("|")]
                # The line of dashes under the header is not a row.
                if not all(re.fullmatch(r":?-+:?", c) for c in cells):
                    rows.append(cells)
                i += 1
            html = ["<table>"]
            # A header with nothing in it is only there because Markdown wants
            # one; the page has no use for an empty row.
            if any(rows[0]):
                html.append("<tr>" + "".join("<th>%s</th>" % inline(c) for c in rows[0]) + "</tr>")
            for row in rows[1:]:
                html.append("<tr>" + "".join("<td>%s</td>" % inline(c) for c in row) + "</tr>")
            html.append("</table>")
            body.append("\n".join(html))
            continue
        if line.startswith("- "):
            items = []
            while i < len(lines) and (lines[i].startswith("- ") or lines[i].startswith("  ")):
                if lines[i].startswith("- "):
                    items.append(lines[i][2:].strip())
                else:
                    items[-1] += " " + lines[i].strip()
                i += 1
            body.append("<ul>\n" + "\n".join("<li>%s</li>" % inline(item) for item in items) + "\n</ul>")
            continue
        paragraph = []
        while (i < len(lines) and lines[i].strip() and not lines[i].startswith("#")
               and not lines[i].startswith("|") and not lines[i].startswith("- ")):
            paragraph.append(lines[i].strip())
            i += 1
        body.append("<p>%s</p>" % inline(" ".join(paragraph)))
    contents = ('<nav class="contents">' +
                "".join('<a href="#%s">%s</a>' % (anchor, inline(text)) for anchor, text in sections) +
                "</nav>")
    return contents + "\n" + "\n".join(body)


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
            ("/*@art@*/null", script_json(art)),
            ("<!--@guide@-->", guide_html(GUIDE.read_text(encoding="utf-8")))):
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
