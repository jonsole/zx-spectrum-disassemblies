"""Publish the built HTML disassemblies to the gh-pages branch, and so the site.

The site is https://jonsole.github.io/zx-spectrum-disassemblies/. It cannot be
built by GitHub: every build needs a tape and a ROM that are not in the
repository. So it is built here, with a build script's --html, and this copies
the result onto the gh-pages branch and pushes it.

The Hobbit, Atic Atac, Ant Attack and Knight Lore are published, each with --game. The master branch
holds no game bytes; gh-pages is the one place that does, and the README says so.

The working tree is never touched. The gh-pages branch is cloned into a
temporary directory, the published game's directory there is replaced whole
with the fresh build -- so a page that no longer exists does not linger -- the
game's commented source (the build's .asm, which reassembles with sjasmplus to
the original bytes) goes in beside it for the landing page to link to, the
landing page is copied from pages/index.html, and the result is committed
with the master commit it was built from, and pushed.

    python scripts/publish_pages.py                    # publish what is built
    python scripts/publish_pages.py --tape Hobbit.tzx  # build it first
    python scripts/publish_pages.py --game aticatac --tape "Atic Atac.tap"
    python scripts/publish_pages.py --dry-run          # show what would change
"""
from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BRANCH = "gh-pages"
SITE = "https://jonsole.github.io/zx-spectrum-disassemblies/"
LANDING = ROOT / "pages" / "index.html"

# What is published: the directory name on the site, where its build puts the
# HTML, the build script that makes it, and the commented source it writes.
GAMES = {
    "hobbit": (ROOT / "game_disassembly" / "hobbit" / "html" / "hobbit",
               ROOT / "scripts" / "build_hobbit.py",
               ROOT / "game_disassembly" / "hobbit" / "hobbit.asm"),
    "aticatac": (ROOT / "game_disassembly" / "aticatac" / "html" / "aticatac",
                 ROOT / "scripts" / "build_aticatac.py",
                 ROOT / "game_disassembly" / "aticatac" / "aticatac.asm"),
    "antattack": (ROOT / "game_disassembly" / "antattack" / "html" / "antattack",
                  ROOT / "scripts" / "build_antattack.py",
                  ROOT / "game_disassembly" / "antattack" / "antattack.asm"),
    "knightlore": (ROOT / "game_disassembly" / "knightlore" / "html" / "knightlore",
                   ROOT / "scripts" / "build_knightlore.py",
                   ROOT / "game_disassembly" / "knightlore" / "knightlore.asm"),
}
# What each build is given to build from. Knight Lore is built from a snapshot
# of the loaded game, not a tape; --tape passes it on under its own name.
SOURCE_OPTION = {"knightlore": "--snapshot"}

# Pages a game's directory carries besides its disassembly, each written fresh
# by a command as it is published: the directory is replaced whole, so a page
# put there any other way is gone the next time the game is published -- which
# is how the room editor was lost once. The command is run from ROOT with
# "{out}" standing for where the page goes. Knight Lore's room editor holds
# none of the game's bytes; it is made from scripts and the emulator
# repository's room designer, and the landing page links to it.
EXTRA_PAGES = {
    "knightlore": [
        ("room-editor.html",
         [sys.executable, "scripts/knightlore_rooms.py", "page", "--out", "{out}"]),
    ],
}


def git(*args: str, cwd: Path = ROOT, capture: bool = True) -> str:
    result = subprocess.run(["git", *args], cwd=cwd, text=True,
                            capture_output=capture)
    if result.returncode != 0:
        sys.exit(f"error: git {' '.join(args)} failed:\n{result.stderr or ''}")
    return (result.stdout or "").strip()


def main() -> None:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--game", default="hobbit", choices=sorted(GAMES),
                        help="which disassembly to publish (default hobbit)")
    parser.add_argument("--tape", type=Path,
                        help="build the HTML from this tape first; without it, "
                             "what is already built is published")
    parser.add_argument("--dry-run", action="store_true",
                        help="show what would change, and do not commit or push")
    args = parser.parse_args()

    html, build, asm = GAMES[args.game]
    if args.tape:
        print(f"Building {args.game} from {args.tape}...", flush=True)
        option = SOURCE_OPTION.get(args.game, "--tape")
        subprocess.run([sys.executable, str(build), option, str(args.tape), "--html"],
                       cwd=ROOT, check=True)
    if not (html / "index.html").exists():
        sys.exit(f"error: nothing built at {html} -- run {build.name} --html, "
                 f"or pass --tape")
    # The landing page links to it, so a site without it has a dead link.
    if not asm.exists():
        sys.exit(f"error: no {asm.name} at {asm.parent} -- run {build.name}, "
                 f"or pass --tape")

    source = git("rev-parse", "--short", "HEAD")
    dirty = git("status", "--porcelain", "--", "scripts", "pages")
    if dirty:
        print("note: scripts/ or pages/ has uncommitted changes; the site will "
              "not match any commit exactly", flush=True)
    origin = git("remote", "get-url", "origin")

    with tempfile.TemporaryDirectory(prefix="gh-pages-") as temp:
        site = Path(temp) / "site"
        print(f"Cloning {BRANCH}...", flush=True)
        git("clone", "--quiet", "--depth", "1", "--branch", BRANCH, "--single-branch",
            origin, str(site), cwd=Path(temp))

        target = site / args.game
        if target.exists():
            shutil.rmtree(target)
        shutil.copytree(html, target)
        shutil.copy2(asm, target / asm.name)
        for leaf, command in EXTRA_PAGES.get(args.game, []):
            out = target / leaf
            done = subprocess.run([str(out) if part == "{out}" else part for part in command],
                                  cwd=ROOT, text=True, capture_output=True)
            # The landing page links to it, so publishing without it would be
            # publishing a dead link.
            if done.returncode != 0 or not out.exists():
                sys.exit(f"error: could not write {args.game}/{leaf}:\n"
                         f"{done.stdout}{done.stderr}")
            print(f"Wrote {args.game}/{leaf}", flush=True)
        shutil.copy2(LANDING, site / "index.html")
        (site / ".nojekyll").touch()

        git("add", "--all", cwd=site)
        changed = git("status", "--porcelain", cwd=site)
        if not changed:
            print("Nothing has changed: the site is already up to date.")
            return
        stat = git("diff", "--cached", "--shortstat", cwd=site)
        print(f"Changes: {stat}")
        if args.dry_run:
            print("\n".join(changed.splitlines()[:40]))
            print("Dry run: nothing committed or pushed.")
            return

        message = (f"Update the published {args.game} disassembly\n\n"
                   f"Built from master at {source}"
                   + (" with uncommitted changes to scripts/ or pages/" if dirty else "")
                   + " by scripts/publish_pages.py.")
        git("commit", "--quiet", "-m", message, cwd=site)
        print(f"Pushing to {BRANCH}...", flush=True)
        git("push", "--quiet", "origin", BRANCH, cwd=site, capture=False)
    print(f"Published. GitHub Pages rebuilds in a minute or so: {SITE}")


if __name__ == "__main__":
    main()
