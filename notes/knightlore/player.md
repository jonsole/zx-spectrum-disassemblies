# The player

**Question this answers:** How does the code turn the controls into the knight's
movement -- turning, walking, jumping -- and why is the player two objects?

**Short answer:** The player is object records 0 and 1 ($5C08 and $5C28): the
legs, which carry the collision box for the whole knight, and a top half that is
only a picture and copies the legs' position every frame. Each frame the legs'
handler reads the controls into one byte, turns, jumps and steps the legs, then
builds this frame's dX/dY/dZ, has the collision code cut it short, and applies
it. Turning is either rotational (left and right turn a quarter) or, with a
joystick and the menu's option 5, directional (push the way you want to go).

## How it works

```
upd_16_to_21_24_to_29 ($C823, man) / upd_48_to_53_56_to_61 ($C828, werewolf)
 -> upd_player_bottom ($C82B)        dead? (+$0D bit 6) -> death sparkle, both halves
    player_controls ($C83E)
      chk_and_init_transform ($C306) man <-> werewolf
      check_user_input ($D022)       C = controls
      handle_pickup_drop ($C00E)
      handle_left_right ($C89F)      rotational ($C8F2) or directional ($C8BE..$C8EF)
      handle_jump ($C948)
      handle_forward ($C969)         leg animation ($C97F), rest poses ($C994)
      chk_plyr_OOB ($C87A)           in a doorway? -> plyr_OOB ($C86D): no rising
    player_move_and_draw ($C855)
      move_player ($C9A1)
        calc_plyr_dXY ($C9FB)        arch nudge + 3 units in the facing direction
        apply_gravity ($C9C1)        dZ -= 2 (or 1 rising with jump held)
        adj_for_out_of_bounds ($CB45)   -- see "Collisions"
        handle_exit_screen ($CA70)      -- see "Leaving a room"
        add_dXYZ ($C706)
        landed? clear the jump flag; clear dX, dY ($C9F3)
      room-entry countdown -1
      set_wipe_and_draw_flags ($C692)
```

**The controls as the code sees them** -- the byte in C built by
`check_user_input` (outside this range, read for context) and kept in $5BB5:

| Bit | Meaning |
|---|---|
| 0 | left |
| 1 | right |
| 2 | forward (keyboard) / up (joystick) |
| 3 | jump |
| 4 | pick up / drop (keyboard) / down (joystick) |
| 5 | any other key (`finished_input`); `chk_pickup_drop` uses it as pick-up/drop in directional mode |

While $5BC3 (game won) or $5BC4 (object rising into the cauldron) is non-zero the
controls read as nothing.

**Directional vs rotational.** $5BA4 bits 1-2 are the control method (0
keyboard, 1 Kempston, 2 cursor, 3 Interface II) and bit 3 is directional
control. `handle_left_right` goes rotational if the method is 0 -- so the
keyboard is always rotational -- or bit 3 is clear.

- *Rotational* (`left_right_rotational`): right turns W->N->E->S (clockwise),
  left the other way. A pause in +$0D bits 0-2 (set to 2 after a turn) means a
  held key turns once every third frame. A turn needs the room-entry walk over
  and no jump in progress; it makes its own sound only when not also walking.
- *Directional* (`handle_left_right` from $C8AB): only when standing (+$0C bit 2)
  and not in the room-entry walk. The stick is read up (unless left is held),
  right, down, left. If the player already faces that way, bit 2 of C is set and
  he walks; otherwise he turns a quarter the short way, at once, with no pause and
  no sound. A half-turn takes two frames.

**How a facing is stored.** Two bits: bit 3 of the type (0 = seen from behind,
1 = from the front) and bit 6 of +$07 (sprite mirrored). `get_sprite_dir`
($CA1E) packs them as mirror*2 + view: 0 W, 1 E, 2 N, 3 S. So W and N share
artwork (one mirrored), as do E and S. A quarter turn always toggles the mirror
bit and toggles the view half the time. `turn_toggle_mirror` also sets the top
half's type to the legs' type + 16 so both halves turn in the same frame.

**Walking.** `calc_plyr_dXY` adds +$0E/+$0F (a +-1 nudge an archway leaves, to
steer the player onto the arch's centre line, via $C791) then dispatches on the
facing through `walk_step_tbl` ($CA32) to add 3 to dX or dY. X grows east, Y
north (tcdev's direction names; which way that is on screen is not checked
here). The player moves when forward is held, and also throughout a jump and
during the room-entry walk.

**Legs.** The type's low three bits are a six-frame walk cycle
(`animate_human_legs`, $C97F, also used by $B71A). With forward released the
legs carry on silently to frame 2 or 4, the two standing poses. Footsteps sound
on even frames only (`audio_B4BB` returns on odd types).

**Jumping.** `handle_jump`: jump held, no room-entry walk, jump flag (+$0C bit 3)
clear, and dZ >= -1 (not already falling). Sets the flag and dZ = 8. Gravity in
`apply_gravity` takes 2 a frame, but only 1 while dZ >= 0 and jump is still held,
so holding jump gives a higher, floatier arc. The flag is cleared in
`move_player_apply` when a move was stopped in Z (+$0C bit 2) while the intended
dZ ($5BC1) was negative -- a landing, not a bumped head. Nothing in this code
limits the speed of a fall; faster than 2 a frame plays a falling sound pitched
by the height. The test is on dZ, not on standing, and the collision code leaves
dZ at 0 for a player who is on the ground.

**In a doorway.** `chk_plyr_OOB` gives no carry when the player's footprint
reaches or crosses a wall line (possible only in an arch, since the walls clip
everyone else). `plyr_OOB` then zeroes any non-negative dZ: no jumping in a
doorway; a jump started there is cancelled before it moves.

**The two-part player.** Record 0 (legs, types 16-21/24-29 as the man,
48-53/56-61 as the werewolf) is the only one that moves or collides; its height
+$06 is 23, the whole knight. Record 1 (top, types 32-47 / 64-79, i.e. legs + 16)
is updated by `upd_player_top` ($CDE2, outside this range, read for context): it
copies the legs' X, Y, Z, sizes and flags, sets its own height to 0 and bit 1 of
+$07 (ignored by collision scans), and sits 12 above the legs. When either half
is found dead (+$0D bit 6), both become the death sparkle. `player_move_and_draw`
sets the top half's ignore bit explicitly around the move so the legs cannot
collide with their own head.

| Offset | Field (player bottom) |
|---|---|
| +$00 | type: bits 0-2 walk frame, bit 3 front/back view, +32 for the werewolf |
| +$01-$03 | X, Y, Z (Z is the base; floor is $80) |
| +$04/$05 | half-width X / half-depth Y (5 and 5 in the start data) |
| +$06 | height (23) |
| +$07 | bit 0 near an archway, bit 1 ignore in collisions / being moved, bit 2 moves with others: pushed when bumped, carried when standing on a mover (see Collisions), bit 3 recognised by archways, bit 4 drawn, bit 6 sprite mirrored |
| +$08 | room: high nibble row (N-S), low nibble column (E-W) |
| +$09-$0B | dX, dY, dZ (dX/dY cleared after each move; dZ carries over as speed) |
| +$0C | bits 0-2 stopped in X/Y/Z this move, bit 3 jumping, bits 4-7 room-entry walk countdown |
| +$0D | bits 0-2 turn pause, bit 3 landed on, bit 5 harms what runs into it, bit 6 has been harmed, bit 7 harms what it runs into |
| +$0E/$0F | arch nudge to dX/dY |
| +$10 | after a respawn, the real type to restore once the sparkle ends |

## How this was found

Read the listing from $C82B to $CD32 and the routines around it for context:
`check_user_input` and its four readers ($D022-$D125) for the bit layout of C;
the menu at $BD23-$BD85 for $5BA4; `upd_player_top` ($CDE2) for the top half;
`plyr_spr_init_data` ($D1A1) for the start-of-game sizes and flags;
`lose_life` ($D12A) and `upd_127` ($BF11) for the respawn copy; the arch code at
$C785-$C820 for +$07 bit 0 and the +$0E/+$0F nudge. The rotation table was worked
through by hand for all four facings, both directions, and both control schemes.

## Confidence

All read. The meanings of the compass names (X east, Y north) are tcdev's labels
checked for internal consistency (exits, arrival markers), not against the
screen. The werewolf types are inferred from `lose_life` adding 32 to the type by
the sun/moon state. That a held key turns once every third frame and that
directional turns take effect at once are from reading the counters, not timed.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| player_controls | loc_C83E | $C83E | read the controls and act on them |
| player_move_and_draw | loc_C855 | $C855 | move, count the entry walk down |
| player_redraw | loc_C86A | $C86A | tail call to set_wipe_and_draw_flags |
| oob_test_x | loc_C891 | $C891 | part of chk_plyr_OOB |
| oob_test_y | loc_C89D | $C89D | part of chk_plyr_OOB |
| directional_pick | loc_C8BE | $C8BE | right/down/left in directional mode |
| chk_facing_ne_result | loc_C8D2 | $C8D2 | walk or turn, N/E |
| turn_by_parity | loc_C8D5 | $C8D5 | pick left or right turn |
| chk_facing_sw_result | loc_C8E5 | $C8E5 | walk or turn, S/W |
| rotational_turn | loc_C8FD | $C8FD | start a rotational turn |
| start_turn_delay | loc_C915 | $C915 | set the pause between turns |
| turn_toggle_view | loc_C927 | $C927 | back/front view bit |
| turn_toggle_mirror | loc_C92F | $C92F | mirror bit, top half follows |
| turn_right | loc_C940 | $C940 | right-turn branch |
| walk_step_sound | loc_C97A | $C97A | footstep then next leg frame |
| store_leg_frame | loc_C98B | $C98B | write the frame into the type |
| legs_to_rest | loc_C994 | $C994 | finish the stride |
| move_player_xy | loc_C9AB | $C9AB | is the player moving forward? |
| move_player_walk | loc_C9BC | $C9BC | take a step |
| apply_gravity | loc_C9C1 | $C9C1 | gravity, 1 or 2 |
| gravity_extra | loc_C9CC | $C9CC | the second unit |
| move_player_apply | loc_C9CD | $C9CD | resolve and apply the move |
| dispatch_on_facing | lookup_plyr_dXY | $CA17 | not only the player's dXY: also room exits and the archways' own logic |
| walk_step_tbl | off_CA32 | $CA32 | table of step routines |
| store_plyr_dX | loc_CA3F | $CA3F | shared tail |
| store_plyr_dY | loc_CA4F | $CA4F | shared tail |

(Collision and room-exit renames are in their sections.)

## Open questions

- Why `player_move_and_draw` clears the top half's ignore bit again after the
  move, when `upd_player_top` sets it again straight away.
- While $5BC4 holds the player still, a jump flag left set would keep
  `calc_plyr_dXY` walking him forward; whether that can happen in play is not
  checked.
- There appears to be a one-frame window to jump after walking off a ledge
  (dZ is still 0 from the last supported frame); read, not tried.
- Records 2 and 3: the archways look at the first four records with +$07 bit 3;
  what the other two hold is outside this range.
