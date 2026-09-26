# Driving Knight Lore

**Question this answers:** how to run the original game from a script in the
emulator -- get past the menu, step it a frame at a time, move the player --
without timing anything.

**Short answer:** break at the menu loop, hold 0 until the first frame of
play, then break at `onscreen_loop` ($AFBD), which starts every frame. Hold a
key across a counted number of those stops to move. The room is byte 8 of the
player's record, $5C10.

## The snapshot

`snapshots/Knight Lore (1984)(Ultimate).sna` (with `roms/48.rom`), the one the
disassembly is built from; `game_disassembly/knightlore/knightlore.sna` is a
byte-for-byte copy the build writes. It is taken mid-frame on the menu with a
tune playing ($B304, in the note player), so it resumes rather than starts
cold. Load `game_disassembly/knightlore/knightlore.sld` with `load_debug_info`
(`sld_path` and `asm_path`, both) to get the labels.

## The breakpoints

| Address | Label | Stopped here means |
|---|---|---|
| $BD23 | `menu_loop` | the control-method menu is up and polling the keys *(watched)* |
| $AFBA | `game_loop` | a room is being entered: it runs once per room, since `exit_screen` jumps back to it *(watched: once at the start of play; read: per room)* |
| $AFBD | `onscreen_loop` | a frame is starting: the object walk begins *(watched: stops every frame)* |
| $B000 | `end_of_frame` | the objects are updated; drawing and the frame delay follow *(read)* |
| $D525 | `wait_for_space` (via `handle_pause`) | the game is paused -- Caps Shift or Space held *(watched: Caps Shift held stops the frames in `debounce_space_press`)* |

**Starting a game:** from `menu_loop`, hold 0 and run; let go at the first
stop at $AFBD *(watched)*. The first frame of play still shows the menu on the
screen: the room is drawn during that frame, after the breakpoint.

**Moving:** hold a key and run to $AFBD N times. Holding A for 40 frames
walked the player out of room $8F into $8E *(watched)*.

The controls land in the input byte `$5BB5` each frame. *Watched*, holding
each key for two frames on the keyboard control method:

| Bit | Keys | Does |
|---|---|---|
| 0 | Z, C, B, M | turn left |
| 1 | X, V, N, Symbol Shift | turn right (V and Symbol Shift *read*, not tried) |
| 2 | the middle row (A ... Enter) | walk forward |
| 3 | the top row (Q ... P) | jump |
| 4 | the number keys | pick up or drop |
| 5 | any key but the number keys, Caps Shift and Space | (the pick-up key for a joystick in directional mode) |

Caps Shift and Space pause the game instead. The keyboard is always
rotational: directional control (menu option 5) only changes the joysticks.

## Variables worth watching

| Address | What |
|---|---|
| $5C08 | object 0, the player's legs (32 bytes); byte 8 ($5C10) is the room *(watched: $8F, one of the four start rooms, at the first frame)* |
| $5C28 | object 1, the player's top half *(read)* |
| $5BB5 | the input byte, above *(watched)* |

## Traps

- **The frame loop is not `game_loop`.** A breakpoint there fires once per
  room, and a script waiting for the next frame hangs; use $AFBD.
- **Don't hold Caps Shift or Space** in a script unless you mean to pause: the
  frame breakpoint then never comes.
- **Keys stay held across a snapshot load**; release them first.
- **Labels need the SLD loaded**; without it `resolve_address` answers with
  ROM symbols.
- **Screenshots at a breakpoint:** draw them from screen memory, not
  `get_screen`.
- The addresses in `examples/filmation/knightlore/driving.md` come from the
  remake's comments and two of them are off: `jump_to_upd_object` is $AFD5,
  not $B25C (inside the menu tune), and `animate_human_legs` is $C97F, not
  $C983.
