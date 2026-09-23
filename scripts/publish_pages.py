"""Publish the built HTML disassemblies to the gh-pages branch, and so the site.

The site is https://jonsole.github.io/zx-spectrum-disassemblies/. It cannot be
built by GitHub: every build needs a tape and a ROM that are not in the
repository. So it is built here, with a build script's --html, and this copies
the result onto the gh-pages branch and pushes it.

Only The Hobbit is published. The master branch holds no game bytes; gh-pages
is the one place that does, and the README says so.

The working tree is never touched. The gh-pages branch is cloned into a
temporary directory, the published game's directory there is replaced whole
with the fresh build -- so a page that no longer exists does not linger -- the
landing page is copied from pages/index.html, and the result is committed
with the master commit it was built from, and pushed.

    python scripts/publish_pages.py                    # publish what is built
    python scripts/publish_pages.py --tape Hobbit.tzx  # build it first
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
# HTML, and the build script that makes it.
GAMES = {
    "hobbit": (ROOT / "game_disassembly" / "hobbit" / "html" / "hobbit",
               ROOT / "scripts" / "build_hobbit.py"),
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

    html, build = GAMES[args.game]
    if args.tape:
        print(f"Building {args.game} from {args.tape}...", flush=True)
        subprocess.run([sys.executable, str(build), "--tape", str(args.tape), "--html"],
                       cwd=ROOT, check=True)
    if not (html / "index.html").exists():
        sys.exit(f"error: nothing built at {html} -- run {build.name} --html, "
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
