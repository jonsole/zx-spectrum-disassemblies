# Knight Lore -- notes

*Knight Lore* (1984, Ultimate Play the Game; Tim and Chris Stamper), the first
Filmation game: an isometric adventure for the 48K Spectrum. Disassembled from
a snapshot of the loaded game (`snapshots/Knight Lore (1984)(Ultimate).sna`)
by `scripts/build_knightlore.py`, on a code map derived from tcdev's
disassembly (2017) as converted to SkoolKit by Michael R. Cook (2019) -- the
map's facts, credited, and none of its prose.

These are the working notes: how the game works, how it was worked out, and
what is still open. The disassembly itself is the build's output.

## Status

- **Disassembly:** every byte in a block, every entry titled and described,
  no placeholder labels left, 1894 of 4352 instructions commented; it
  reassembles byte-for-byte and writes back the snapshot it read, with no
  build warnings. The rooms, background pieces and charm places are laid out
  record by record from the game at build time (`scripts/knightlore_data.py`).
- **Checked live:** driving, the input byte, the pause, the room variable,
  and pushing (the table moves, the "moveable" block does not). Most else is
  *read*; each note says which.
- **Pages:** besides the architecture, the site has the castle's room
  structure (with a map and all 128 rooms drawn by the game), the scenery,
  the templates, the objects and the sprites, all generated from the game at
  build time (`scripts/knightlore_pages.py`).
- **Not yet:** a "how it works" page drawing on these notes.

## Index

| Note | What it covers |
|---|---|
| [`overview.md`](overview.md) | **Start here** -- a tour of the findings |
| [`journal.md`](journal.md) | What was investigated when, and what turned out wrong |
| [`driving.md`](driving.md) | Running the game from a script: breakpoints, keys, traps |
| [`memory-map.md`](memory-map.md) | Regions, the object record, every variable |
| [`main-loop.md`](main-loop.md) | Start-up, the object walk, the end of a frame and its timing |
| [`object-types.md`](object-types.md) | The 188 object types and their handlers |
| [`object-behaviours.md`](object-behaviours.md) | What the moving things do each frame: blocks, balls, guards, the wizard |
| [`player.md`](player.md) | Turning, walking, jumping, the two-part player |
| [`collision.md`](collision.md) | The per-axis box test, harm, pushing (tested) |
| [`leaving-a-room.md`](leaving-a-room.md) | Arches, exits and the respawn point |
| [`arches.md`](arches.md) | The arch checks and the per-type drawing offsets |
| [`input.md`](input.md) | The control methods and the input byte |
| [`lives-and-starting.md`](lives-and-starting.md) | Lives, start rooms, death and respawning |
| [`day-and-night.md`](day-and-night.md) | The sun and moon, the transformation, the forty days |
| [`special-objects.md`](special-objects.md) | The charm places and the room's two charm slots |
| [`inventory.md`](inventory.md) | Carrying, picking up and dropping |
| [`winning.md`](winning.md) | The cauldron, the wanted list, completing, the rating and percentage |
| [`ghosts.md`](ghosts.md) | Ghosts |
| [`portcullises.md`](portcullises.md) | Portcullises |
| [`status-and-menu.md`](status-and-menu.md) | The panel, the menu, the text format |
| [`sound.md`](sound.md) | The note player, the tunes and the effects |
| [`room-format.md`](room-format.md) | The room records, block types and backgrounds |
| [`room-building.md`](room-building.md) | How a room record becomes object records |
| [`depth-order.md`](depth-order.md) | Sorting the scene and what gets redrawn |
| [`drawing.md`](drawing.md) | The projection, the buffer, masked sprites, flipping |
| [`sprites.md`](sprites.md) | The sprite format and the table from type to sprite |
| [`other-data.md`](other-data.md) | The font and the smaller tables |
