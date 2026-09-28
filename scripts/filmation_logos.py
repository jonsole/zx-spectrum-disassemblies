"""The Filmation games' logos, cut from their tapes' loading screens.

Knight Lore, Alien 8, Pentagram and Nightshade each put their title on the
loading screen among the rest of the picture. Each build cuts it out at build
time -- the tape is read, never the repository -- for the top of every page
(LogoImage in the game's ref) and the site's landing page, as Atic Atac's and
The Hobbit's builds do with theirs. What is kept is the title's own colours,
only where they belong to the title; each game's cut says how that is told
apart from the rest. The result is on a transparent background, so that it
sits on whatever the page's colour is, with a margin, at twice the size.
"""
from pathlib import Path

SCREEN_LENGTH = 6912
# A tape's data block is its flag byte, the bytes and a checksum.
SCREEN_BLOCK_LENGTH = SCREEN_LENGTH + 2
MARGIN = 4
SCALE = 2

BLACK, BLUE, RED, MAGENTA, GREEN, CYAN, YELLOW, WHITE = range(8)
PALETTE = [((level if c & 2 else 0), (level if c & 4 else 0), (level if c & 1 else 0))
           for level in (0xD7, 0xFF) for c in range(8)]


def loading_screen(tape: Path) -> bytes | None:
    """The first block on the tape the size of a whole screen, or None."""
    from skoolkit.tape import parse_tap, parse_tzx

    data = tape.read_bytes()
    parsed = parse_tzx(data) if tape.suffix.lower() == ".tzx" else parse_tap(data)
    for block in parsed.blocks:
        if block.data and len(block.data) == SCREEN_BLOCK_LENGTH:
            return bytes(block.data[1:1 + SCREEN_LENGTH])
    return None


class Screen:
    """A screen's pixels by colour: each pixel's colour number (ink where it
    is set, paper where not; brightness aside) and its colour as drawn."""

    def __init__(self, screen: bytes):
        self.number, self.rgb = {}, {}
        for y in range(192):
            for x in range(256):
                address = ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2) | (x >> 3)
                attribute = screen[6144 + (y >> 3) * 32 + (x >> 3)]
                on = screen[address] >> (7 - (x & 7)) & 1
                colour = attribute & 7 if on else (attribute >> 3) & 7
                self.number[(x, y)] = colour
                self.rgb[(x, y)] = PALETTE[(8 if attribute & 0x40 else 0) + colour]

    def pixels(self, box, colours) -> set:
        x0, y0, x1, y1 = box
        return {(x, y) for y in range(y0, y1) for x in range(x0, x1)
                if self.number[(x, y)] in colours}


def pieces(pixels: set, diagonal: bool) -> list[list]:
    """The pixels' connected pieces, largest first; diagonal neighbours count
    as touching only when asked."""
    steps = [(dx, dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1)
             if (dx or dy) and (diagonal or not (dx and dy))]
    seen, out = set(), []
    for start in pixels:
        if start in seen:
            continue
        piece, stack = [start], [start]
        seen.add(start)
        while stack:
            x, y = stack.pop()
            for dx, dy in steps:
                p = (x + dx, y + dy)
                if p in pixels and p not in seen:
                    seen.add(p)
                    piece.append(p)
                    stack.append(p)
        out.append(piece)
    out.sort(key=len, reverse=True)
    return out


def knightlore(screen: Screen) -> dict:
    """The white lettering alone. It is painted on a green cloud, between
    the wizard and the castle wall; only the letters are white there. Pieces
    of under ten pixels are specks of the cloud's edge."""
    white = screen.pixels((128, 32, 208, 112), {WHITE})
    kept = [p for piece in pieces(white, True) if len(piece) >= 10 for p in piece]
    return {p: screen.rgb[p] for p in kept}


def alien8(screen: Screen) -> dict:
    """The magenta badge, the letters worked into it. The badge is one piece
    of magenta against the black of space, the planet's yellow and red
    behind it; it is followed from its middle, and the black of the letters
    inside it is kept by filling each row between its ends."""
    box = (16, 80, 128, 152)
    magenta = screen.pixels(box, {MAGENTA})
    badge = pieces(magenta, False)[0]
    rows = {}
    for x, y in badge:
        low, high = rows.get(y, (x, x))
        rows[y] = (min(low, x), max(high, x))
    kept = [(x, y) for y, (low, high) in rows.items() for x in range(low, high + 1)]
    return {p: screen.rgb[p] for p in kept}


def pentagram(screen: Screen) -> dict:
    """The lettering across the emblem, without the emblem. The letters are
    yellow on the emblem's red, and so are the thorny vines round them; but
    the letters are one yellow piece, with a few inside it (the star's
    centre, the G's eye), while the vines are separate pieces that reach
    below the letters or past the M. Those are dropped, and the letters
    keep a rim of the emblem's red two pixels wide, as they sit on it."""
    yellow = screen.pixels((70, 63, 198, 99), {YELLOW})
    kept = set()
    for piece in pieces(yellow, False):
        if (len(piece) >= 10 and max(x for x, _ in piece) <= 183
                and min(y for _, y in piece) < 90):
            kept.update(piece)
    red = next(screen.rgb[p] for p in sorted(screen.pixels((70, 63, 198, 99), {RED})))
    rim = {(x + dx, y + dy) for x, y in kept for dx in range(-2, 3) for dy in range(-2, 3)} - kept
    out = {p: red for p in rim}
    out.update({p: screen.rgb[p] for p in kept})
    return out


def nightshade(screen: Screen) -> dict:
    """The magenta lettering and its antlers. Under the letters lie the
    skulls, one of them magenta and touching the lettering's box: every
    piece of the title starts above row 45, and the skull below it."""
    magenta = screen.pixels((88, 8, 184, 80), {MAGENTA})
    kept = [p for piece in pieces(magenta, True)
            if len(piece) >= 20 and min(y for _, y in piece) < 45 for p in piece]
    return {p: screen.rgb[p] for p in kept}


CUTS = {"knightlore": knightlore, "alien8": alien8, "pentagram": pentagram,
        "nightshade": nightshade}


def write_logo(game: str, tape: Path, path: Path, log=print) -> bool:
    """Cut `game`'s logo from the loading screen on `tape` into `path`."""
    from PIL import Image

    screen = loading_screen(tape)
    if screen is None:
        log(f"  (no loading screen on {tape.name}: no logo)")
        return False
    drawn = CUTS[game](Screen(screen))
    xs = [x for x, _ in drawn]
    ys = [y for _, y in drawn]
    left, top = min(xs) - MARGIN, min(ys) - MARGIN
    width, height = max(xs) - left + 1 + MARGIN, max(ys) - top + 1 + MARGIN
    image = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    for (x, y), rgb in drawn.items():
        # Black the title keeps (Alien 8's letters) stays opaque.
        image.putpixel((x - left, y - top), rgb + (255,))
    path.parent.mkdir(parents=True, exist_ok=True)
    image.resize((width * SCALE, height * SCALE), Image.NEAREST).save(path)
    log(f"  logo cut from the loading screen: {width * SCALE}x{height * SCALE}")
    return True
