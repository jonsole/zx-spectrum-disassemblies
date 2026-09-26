# Leaving a room

**Question this answers:** When and how does the player go from one room into the
next?

**Short answer:** Only through an archway, and only walking the way he faces: when
an arch has flagged the player as near it, the exit routine for his facing checks
whether this frame's move takes his whole footprint past that wall line. If so he
gets the neighbouring room number and a position marker, the rest of the frame is
abandoned, a respawn copy of the player is saved, and the new room is built.

## How it works

```
move_player_apply ($C9CD)
  handle_exit_screen ($CA70)   not in entry walk; +$07 bit 0 (near arch) set -> clear it
    dispatch_on_facing ($CA17) through screen_move_tbl ($CA92)
      screen_west  ($CA9A)  X+dX+w  <  $80-xsize  -> X=$00, column-1
      screen_east  ($CAF3)  X+dX-w  >= $80+xsize  -> X=$FF, column+1
      screen_north ($CB0E)  Y+dY-d  >= $80+ysize  -> Y=$FF, row+1 (+16)
      screen_south ($CB29)  Y+dY+d  <  $80-ysize  -> Y=$00, row-1 (-16)
        screen_e_w ($CAB3)  column change wraps within the row
        exit_screen ($CABA)
          +$08 = new room; +$0C |= $30 (entry walk, 3 frames)
          type 16-79 (the player): drop 2 return addresses,
            copy records 0-1 to $D161/$D181, real types to +$10, types = 120
          JP game_loop ($AFBA) -> build_screen_objects -> adjust_plyr_xyz_for_room_size ($D320)
```

- The room number is a row (high nibble, N-S) and a column (low nibble, E-W): a
  16 by 16 grid.
- X/Y of $00 or $FF are markers, not positions: `adjust_plyr_xyz_for_room_size`
  ($D320, read for context) turns X=0 into "at the east wall" (and $FF west,
  Y=$FF south, Y=0 north), placing the player in the doorway at the arch's
  height.
- The entry walk: +$0C top nibble = 3, decremented once a frame in
  `player_move_and_draw`. While non-zero, the controls are ignored, the player
  walks straight on (3 units a frame, legs moving, footsteps), and the wall clip
  is off.
- The respawn copy: `lose_life` ($D12A) copies $D161-$D1A0 back to $5C08, so a
  lost life restarts at the door the player came in by, as the materialising
  sparkle (type 120 on), which `upd_127` ($BF11) turns back into the saved type.
  Because the saved X/Y are the markers, the respawn also goes through the
  arrival placement.

## How this was found

Read $CA70-$CB44, then followed the markers into $D320 and the respawn copy into
$D12A, $D1B1 and $BF11, and the stack at the moment of the exit (CALL move_player,
CALL handle_exit_screen, PUSH HL popped by the exit routine) to see what the four
INC SPs drop.

## Confidence

Read. The type check in `exit_screen` only matters for non-player objects, and in
this build only the player's handler reaches `move_player`, so the other branch
is never taken (read from the callers of $C9A1 and $CA70).

## Renamed routines

None: `handle_exit_screen`, `screen_west/east/north/south`, `screen_e_w`,
`exit_screen` and `screen_move_tbl` keep tcdev's names.

## Open questions

- Whether the respawn really replays the three-frame entry walk (the saved +$0C
  carries $30) -- inferred, not watched.
