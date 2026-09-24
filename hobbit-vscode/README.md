# The Hobbit Inspector

A VS Code extension that shows what The Hobbit (v1.2, 1982) is doing while it
runs in the [ZX Spectrum emulator](https://github.com/jonsole/zx-spectrum-emulator)'s
debugger, after [Wilderland](https://github.com/efa/Wilderland), which does the
same with an emulator of its own:

- **What happens**: everything the game says, line by line, with who it was
  about. The game composes the other characters' sentences whether or not the
  player is there to see them -- "Thorin sits down and starts singing about
  gold" in a room the player left long ago -- and they all pass through
  PRINT_CHAR. The log catches them there. Lines about a character somewhere
  else than the player are shown greyed: nobody playing ever sees them.
- **Objects**: every one of the 61, the player and the characters included --
  where it is (at a place, in something, or carried), how many places it is in
  at once, its size, weight, strength and defence, and its flags: `v` visible,
  `c` a character, `o` open, `*` gives light, `x` dead or broken, `f` full,
  `l` a liquid, `k` locked. Filter by name or place, or show only what is
  where you are.
- **Map**: every location, laid out as on the
  [disassembly's map](https://jonsole.github.io/zx-spectrum-disassemblies/hobbit/reference/map.html),
  with a coloured dot for each character where it is now, the dark places
  shaded and the ones not yet visited dashed. Hover over a place for what and
  who is there, and its exits.

![The Hobbit Inspector in VS Code, with the game running: the log, the objects
and the map](https://jonsole.github.io/zx-spectrum-disassemblies/hobbit/images/inspector.png)

*Early in a game: Gandalf deciding what to do ("is not carrying it", in
italics, only considered), the warg following the wood elf, and the goblins
moving about their passages, none of it where the player can see; the map with
Thorin beside the player at Bag End, and the trolls in their clearing. The
screenshot quotes the game, so it is on the disassembly's site rather than
here.*

It needs the emulator's extension, a debug session with The Hobbit v1.2
loaded -- `build_hobbit.py` writes `hobbit.sna`, and the fast-drawing
`hobbit_fast.sna` works too -- and, for the log, an emulator with logpoints
(from September 2026 on). Everything it shows is read from the running game:
the memory through the debug adapter's `readMemory`, a few times a second, and
the text through a logpoint on PRINT_CHAR (`setLogpoints`, reports as `zxLog`
events). Nothing of the game is in this folder but addresses, and the map's
layout, `map_layout.json`, which `scripts/hobbit_map_layout.py` writes from the
site map's.

Open it with **The Hobbit: Open Inspector** from the Command Palette.

## Installing

There is no build step and there are no dependencies. Link the folder into VS
Code's extensions folder, then run **Developer: Reload Window**:

```powershell
$dest = "$env:USERPROFILE\.vscode\extensions\jonsole.hobbit-inspector-0.0.1"
New-Item -ItemType Junction -Path $dest -Target (Resolve-Path .\hobbit-vscode)
```

## How it is put together

- `hobbit_model.js` reads the game's state out of its memory -- the
  dictionary, the locations and their exits, the objects -- and turns the
  logpoint's reports into lines. It does not import `vscode`, and is tested
  from plain Node: `node hobbit-vscode/tests/hobbit_model_test.js` (the part
  that reads the game uses `game_disassembly/hobbit/hobbit.sna`, and skips
  without it).
- `extension.js` finds the debug session, reads memory while the panel is
  open, sets and clears the logpoint, and hands everything to the page.
- `inspector.html`, `inspector.css` and `inspector_page.js` are the page.

**Not yet:** the characters' scripts -- what each is about to do -- and the
timers; v1.0, whose addresses differ; and a way to act on the game from the
panel, as Wilderland's command window does.
