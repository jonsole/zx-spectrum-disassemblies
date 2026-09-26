# How a moving object is drawn

**Question this answers:** what the Filmation engine does, from start to
finish, when an object moves -- how the new picture gets onto the screen
without redrawing the room and without flicker.

**Short answer:** it never redraws the room. The handler moves the object and
flags it; the object marks every other object whose picture overlaps the
rectangle covering its old and new pictures. At the end of the frame that
rectangle is cleared in an off-screen buffer, every marked object is drawn
into the buffer whole, back to front, and only the rectangle is copied to the
display. Nothing is ever erased on the display, and nothing outside the
rectangles changes. The site's page
[How a moving object is drawn](https://jonsole.github.io/zx-spectrum-disassemblies/knightlore/MovingObjects.html)
shows a real frame doing it, stage by stage.

## How it works

```
onscreen_loop ($AFBD)                    every frame, all forty records
  update_sprite_loop ($AFC7)             per object: SP = $5BA0
    save_2d_info ($CE49)                 picture now (+$18..+$1B) -> +$1C..+$1F
    handler, by type through $B096
      dec_dZ_and_update_XYZ ($C700)      gravity: DEC dZ
        adj_for_out_of_bounds ($CB45)    shorten dZ, dX, dY against walls and objects
        add_dXYZ ($C706)                 position += velocity
      set_wipe_and_draw_flags ($C692)    +$07 |= $30 (bit 5 wipe, bit 4 draw)
        set_draw_objs_overlapped ($CD4D)
          calc_2d_info ($CD33)           project: new +$1A/+$1B and +$18/+$19
          union of old and new rectangle
          test_overlap_obj ($CD9B) x 40  anything overlapping it: bit 4
end_of_frame ($B000)
  list_objects_to_draw ($CE62)           bit-4 objects -> $CE8B
  render_dynamic_objects ($D59F)
    for each with bit 5: clear the union in the buffer, push it     (the wipe)
    calc_display_order_and_render ($CEBB) draw all listed, back to front
    copy_next_rect ($D666) -> blit_to_screen ($D67C)  each rectangle to the display
  game_delay ($B035)                     six units less the work done
```

| Stage | Where | What it leaves |
|---|---|---|
| Keep the old picture | `save_2d_info` | +$1C-$1F: width in bytes, height in rows, pixel x, pixel y (up from the bottom) |
| Move | the handler, `adj_for_out_of_bounds`, `add_dXYZ` | new X, Y, Z in +$01-$03 (see [`collision.md`](collision.md)) |
| Flag | `set_wipe_and_draw_flags` | +$07 bits 5 and 4 on the mover |
| Mark | `set_draw_objs_overlapped` | bit 4 on every object overlapping the union of old and new |
| Wipe | `render_dynamic_objects` | the union cleared in the buffer at $D8F3; (buffer, display, size) pushed; $5BA8 counts them |
| Draw | `calc_display_order_and_render` | every marked object drawn whole, in depth order (see [`depth-order.md`](depth-order.md)) |
| Copy | `copy_next_rect`, `blit_to_screen` | only the rectangles, buffer to display |
| Pace | `end_of_frame` | $5BBE = objects drawn + rectangles; the wait is six units less |

Consequences worth knowing:

- **The display is the only lasting picture.** The buffer is not kept up to
  date: objects are drawn into it whole, but only the rectangles are copied,
  so outside them it holds leftovers of earlier frames that are never copied.
  `blit_to_screen` copies without clearing; only `update_screen`, on a new
  room, clears the buffer as it copies all of it.
- **Marking one level deep is enough.** An object is redrawn if its picture
  overlaps the mover's rectangle. One that overlaps a redrawn object but not
  the rectangle cannot put a pixel inside the rectangle, and nothing outside
  it is copied -- so nothing is missed. (This settles the open question
  [`depth-order.md`](depth-order.md) had raised.)
- **An object that changes picture without moving** is flagged the same way:
  the guard marking time in the example changes type every frame and gets a
  rectangle each time.
- **Entering a room** skips the wipe: the builder flags everything, the
  cleared buffer takes the whole room in depth order, and `no_delay` copies
  all of it with `update_screen` after the panel is drawn in.

## How this was found

The stages were read from the code -- `update_sprite_loop`,
`set_wipe_and_draw_flags`, `render_dynamic_objects`, `copy_next_rect` and
`blit_to_screen` -- after the agents that described the ranges had written up
the pieces ([`main-loop.md`](main-loop.md), [`depth-order.md`](depth-order.md),
[`drawing.md`](drawing.md)). Then a frame was traced: `knightlore_pages.py`
runs the game in SkoolKit's simulator to room $01 (a ghost, a guard, the
player materialising), past the room's first frame, and stops frame 3 at each
stage -- after the object walk, after the wipe, at every `render_obj` (to read
IX, the object being drawn), and after the copy. It reads the rectangles off
the stack where the wipe pushed them.

In that frame, *traced*:

- 3 objects had bit 5: the ghost (record 32), which moved, and the guard's
  body and legs (30 and 31), which changed picture. So 3 rectangles.
- 11 more had only bit 4: three wall pieces, three blocks, three gargoyles and
  the player's two records, all overlapping one of the rectangles.
- The depth sort drew them walls first, then the ghost (behind the blocks),
  the blocks and gargoyles in front of it, the guard's legs, the player, the
  guard's body, and the nearest block and gargoyle last.

The page regenerates this at every build, so its pictures and tables are the
game's own behaviour, not a transcription.

A first attempt to trace it hung the game on a different room: records 0 and 1
had been emptied to keep the player out of the pictures, and
`next_frame_or_die` read the empty types as a death and started a life in the
start room. The trace keeps the player, materialising.

## Confidence

The pipeline is *read* and every stage is *traced* in the simulator on a real
room. That one-level marking is sufficient is argued from the code (only the
rectangles are copied, and only objects overlapping them can touch them); it
does not rest on the example.

## Open questions

- Several objects moving close together make overlapping rectangles, which are
  wiped and copied separately; whether the game ever merges them is not
  traced (the example's two guard rectangles overlap and are copied twice).
