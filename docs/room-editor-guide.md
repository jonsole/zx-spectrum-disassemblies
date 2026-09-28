# Room editor: user guide

The room editor lets you rearrange the rooms of three of Ultimate's Filmation
games -- **Knight Lore** (1984), **Alien 8** (1985) and **Pentagram** (1986) --
and then play them. You open a snapshot of your own copy of the game, change
its rooms, and download the game again with your changes in it. The result
runs in any ZX Spectrum emulator.

It is a single web page:
[jonsole.github.io/zx-spectrum-disassemblies/room-editor.html](https://jonsole.github.io/zx-spectrum-disassemblies/room-editor.html).
Everything happens in your browser. Nothing is uploaded, and the page contains
none of the games themselves: every room and picture you see comes from the
copy you open.

## Getting started

### What you need

A **snapshot** of the game, taken at its menu, before a game has started: a
48K `.sna` or `.z80` file. The editor takes snapshots rather than tapes because
a tape's contents are only the game once it has loaded -- Knight Lore's tape is
even scrambled until its loader has run.

To make one, load your copy of the game in an emulator, wait for the menu,
and save a snapshot. In Fuse it is **File > Save Snapshot**; in the
[ZX Spectrum emulator for VS Code](https://github.com/jonsole/zx-spectrum-emulator)
the command **ZX Spectrum: Save Snapshot...** does it. Most emulators have
something similar.

Use the **original** game. A snapshot the editor has already changed can only
be opened again if its tables did not move; if they did, it is refused (see
[Carrying on later](#carrying-on-later) for how to keep working instead).

### Opening a game

Drop the snapshot onto the page, or click the box and choose it. The editor
tells which of the three games it is and opens it. The bar across the top
then says which game you are editing and which file.

If you have saved work in this browser before, the first screen offers to
**Continue** with it. **Forget it** clears it.

## The screen

The bar at the top has everything that is not about one room:

| | |
|---|---|
| **Rooms** / **Templates** | The two editors: the rooms, and the templates they are built from. |
| **Undo** / **Redo** | Step back and forward through your changes, in either editor. Ctrl+Z and Ctrl+Shift+Z do the same. |
| **Save** | Keep your work in this browser (Ctrl+S). |
| **Download .sna** | Build the game with your changes and download it. |
| **Export** / **Import** | Save your work to a file, and load it back. |
| **Close** | Go back to the first screen. |

Messages from Save and Download appear under the bar, in green when all is
well and red when something needs fixing. The word **unsaved** appears beside
the buttons when you have changes you have not saved.

### The map

On the left is the map of every room. Knight Lore's and Alien 8's rooms sit
where their numbers put them, on a 16 by 16 grid. Pentagram's numbers are not
places, so its map is laid out by following the doorways from the first room;
any room the doorways never reach is listed under the map. The room you are
editing is highlighted.

- **Click a room** to go to it.
- **Click an empty square** (Knight Lore and Alien 8) to pick it, then
  **Add room** to make a new, empty room there. In Pentagram, type a number
  and press **Add room**.
- **Delete room** removes the room you are on. It first says what would be
  left pointing nowhere -- doorways that lead in, collectables that start
  there. The last room, and a starting room, cannot be deleted. Undo brings a
  deleted room back.

**Starting rooms** lists the rooms a game can begin in -- each game picks one
of four at random. Click one to go there. To change one, go to it, press
**Change**, then click the room on the map to use instead; rooms that cannot
be a starting room are dimmed, and hovering over one says why. **Cancel** or
Esc stops choosing. A starting room needs the middle of its floor clear,
because that is where the player appears.

**Ways out** lists the room's doorways. In Knight Lore and Alien 8 the room a
doorway leads to follows from where the room is on the map, so each is a
button that goes there. In Pentagram each doorway says which room it leads to,
and you can change that number; **go** goes there.

### The room

In the middle is the room, drawn as the game draws it.

- **Click** anything to select it; the tab where you edit it opens on the
  right.
- **Drag** an object to move it across the floor. Collectables can be dragged
  too.
- With an object selected, the **arrow keys** move it a square, **Ctrl+Up**
  and **Ctrl+Down** (or **[** and **]**) lift and lower it a level, and
  **Delete** removes it.
- With a collectable selected, the arrows move it one step (eight with
  Shift), and Ctrl+Up and Ctrl+Down change its height.

A selected object or collectable is marked on the floor beneath it, with a
dotted line up to it when it is above the floor, and anything in front of it
is drawn see-through.

Under the picture:

- **Ink** -- the room's colour.
- **Shape** -- which floor shape the room stands on (see [Shapes](#shapes)).
- **Floor**, **Boxes**, **Scenery** -- show the floor grid, the box each piece
  takes up, and the walls and arches.
- **Zoom** -- the size of the picture.
- **pool** -- how many of the game's object records the fullest room uses, out
  of how many the game has, and which room that is.

### Checks

Under the room, **Checks** lists anything wrong with the castle. An error
(red) would stop the game being built -- a room with too many pieces, a
doorway to a room that is not there, a starting room with something in the
middle. A warning (yellow) builds, but is worth knowing about -- a doorway
with no way back, or walls that no longer match a room's floor. Each one names
its room; click the room number to go there.

### The panel on the right

**Objects** lists the room's objects in groups: one kind of object, and the
squares it stands on. Change a group's kind with its dropdown, and click a
square's coordinates to select that object. To add objects, choose a kind in
the bottom dropdown and press **Place**; the new object appears in the middle
of the floor, ready to drag. Clicking an object in the room sets the dropdown
to its kind, so Place adds another of the same. A group holds up to eight.

In **Alien 8**, each group also has a **raise**: the game can lift a group of
objects up by a number of units, and 48 -- four levels -- is what it uses.

**Scenery** lists the room's walls, arches and other fixed pieces. Change one
with its dropdown, remove one with **×**, and add one from the dropdown at the
bottom with **Add**.

**Collectables** (Knight Lore and Alien 8) lists the things that start in this
room -- Knight Lore's charms, Alien 8's valves -- with their position and
room, which you can type in. **Show as kind** only changes how they are
drawn: the game decides at random which kind each one is when a game starts.
A room shows at most two.

**Shapes** lists the floor shapes every room stands on: how far the floor
reaches from the middle across and along, and how high it is. Changing a
shape changes every room that uses it. See [Shapes](#shapes).

## Templates

Rooms are not built piece by piece. Each is a list of **templates** -- "a
north arch", "a wall", "a block" -- and a template is a set of pieces. Change
a template and every room that uses it changes too.

Press **Templates** in the bar to edit them. The list on the left has every
scenery and object template, with how many rooms use each. Pick one to see
it:

- **Rename**, **Duplicate** and **Delete** at the top. A template in use
  cannot be deleted.
- The picture shows the template on its own, or in a room using it (**show
  it**).
- **Pieces** lists what it is made of: each piece's graphic, and for scenery
  its position; whether it is **mirrored**; and whether things can pass
  through it (**passable**; Knight Lore only). The arrows reorder pieces and
  **✕** removes one. **Add piece** adds one with the graphic chosen beside it.
- Drag a piece in the picture, or use the arrow keys, to move it; Ctrl+Up and
  Ctrl+Down (or **[** and **]**) lift it, Shift makes the steps bigger, and
  Delete removes it.
- **Placed in** lists the rooms using the template; click one to go to it in
  the Rooms editor.

**New** at the foot of each list makes a new, empty template.

## Shapes

A room's **shape** is its floor: how far it reaches from the middle in each
direction, and its height. Every game has three: square, and narrow each way.
The **Shapes** tab lets you change them and add more -- up to 32 in Knight
Lore and Pentagram, and 4 in Alien 8.

Changing a shape changes where the game stops you walking and where you
arrive through a doorway -- but not the walls and arches you see, which are
scenery. If they no longer line up, Checks warns you about each room, and the
fix is to move or add wall pieces (see [Templates](#templates)).

## Playing your version

Press **Download .sna**. If the castle is fine, a `.sna` file downloads and
the message under the bar says how much space is used and free. Open that file
in any Spectrum emulator and start a game from the menu as usual: choose your
controls with the number keys the menu lists, then press **0**.

If something is wrong, nothing downloads and the message says what -- see
[Limits](#limits).

## Limits

The editor puts your rooms back into the game's own memory, which has no room
to spare. Download refuses anything the game could not cope with, and says
why.

- **Space.** The games' room tables are completely full: 3,498 bytes in Knight
  Lore, 4,739 in Alien 8 and 4,048 in Pentagram. Anything you add has to be
  paid for by removing something else -- an object costs one or two bytes, a
  new room at least four. The Download message says how many bytes are free.
- **Pieces in a room.** A room can hold 36 pieces in Knight Lore, 52 in Alien
  8 and 48 in Pentagram, counting every piece of every template it places. The
  **pool** under the picture shows the fullest room, and Checks names any room
  over the limit.
- **Starting rooms** need the middle of the floor clear.
- **In Pentagram** every doorway has to lead to a room that exists: the game
  would crash looking for one that does not.
- **Groups** hold up to eight objects, and a room has to have something in it.
- **Templates**: up to 32 object templates in Knight Lore, 31 in Pentagram and
  60 in Alien 8.

The game itself does not check most of these -- a room with one piece too
many overwrites other parts of the game -- so the editor does.

## Carrying on later

- **Save** keeps everything -- rooms, templates, collectables -- in this
  browser. Next time you open the page, it offers to **Continue**. Private
  windows, and browsers set to clear site data, do not keep it.
- **Export** writes your castle to a `.json` file, to keep, share or move to
  another computer. **Import** reads one back into an open game; it has to be
  the same game.

To carry on from a castle you have downloaded, open your **original**
snapshot again and **Import** the castle you exported -- the downloaded game
itself cannot always be opened again.

## Good to know

- **Undo** covers everything in both editors, in the order you did it.
- The editor shows the **starting position** of things. Once a game is running,
  some move, some are picked up, and the collectables' kinds are dealt at
  random.
- **Pentagram's** unused scenery slots appear as templates with no pieces.
  Leave them be: the game points them at its own tables.
- In **Alien 8**, the end-of-game count of cryogenic chambers recognises a
  chamber by its first object templates being the frozen crew. Deleting an
  object template that comes before them in the list upsets that count.
- Downloads are `.sna` snapshots; the editor does not make tapes.

## Something went wrong

| Message | What to do |
|---|---|
| *This is not an original copy of ... that the editor knows* | Use a snapshot of the original game, taken at the menu. Other releases and hacked copies are not recognised. |
| *This copy ... has had its rooms changed already* | Open the original snapshot, and Import your castle. |
| *Not built: ... needs N bytes and the original has M* | Remove something -- objects, scenery, template pieces -- to free the bytes it says. |
| *Not built: room ... fills N object records* | That room has too many pieces; remove some. |
| *Not built: ... is a starting room, and ... stands in the middle* | Move what stands in the middle, or choose another starting room. |
| *Not built: ... leads to room N, which there is not* | Point the doorway at a room that exists (Pentagram). |
| *This browser would not keep it* | Your browser is not letting the page save. Use **Export** instead. |

For how the editor works inside -- the tables it rewrites and how it was
checked against each game -- see
[docs/room-editor.md](https://github.com/jonsole/zx-spectrum-disassemblies/blob/master/docs/room-editor.md).
