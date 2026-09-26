# Object behaviours

**Question this answers:** what does each kind of self-moving object in Knight
Lore do every frame, and how do its handler, the movement deltas and the
wipe/draw flags fit together?

**Short answer:** each object record carries signed deltas dX, dY, dZ at +9,
+10, +11; a handler sets them and calls the common move (`dec_dZ_and_update_XYZ`,
$C700), which first subtracts 1 from dZ (that is all gravity is), then shrinks
each delta until the object no longer runs into the room's walls, floor or
another solid object, recording which axes were blocked in +12, and finally
adds them to X, Y, Z. The handler then reads +12 to decide what to do next
(turn round, bounce, stop falling), and ends by setting bits 5 and 4 of +7
("wipe the old place", "draw the new one") and, for anything harmful, bits 7
and 5 of +13, which the collision code turns into the victim's "touched
something deadly" bit.

## How it works

### The dispatch

The object loop (`onscreen_loop` $AFBD) jumps through `upd_sprite_jmp_tbl`
($B096) on +0. +0 is also the index into the sprite table at $7112 -- one word
per type, 188 of them, looked up as type times 2 (`flip_sprite`, $D6EF). So an
object's "type" and its current animation frame are the same byte: animating
means changing +0, and a handler that serves several types (upd_160_to_163) is
serving several frames of one thing. (The existing annotation on $7112 says the
table is indexed by type times eight plus a facing; the code at $D6EF indexes
it by +0 alone. That entry is outside this range -- flagged for whoever owns
it.)

### The common move ($C700 -> $CB45 -> $C706)

```
handler
  set +9/+10/+11 (dX dY dZ)
  dec_dZ_and_update_XYZ ($C700)
    DEC +11                       gravity: every call pulls dZ down by one
    $CB45                          skipped entirely if +7 bit 1 is set
      clear +12 bits 0-2
      dZ: clip against the floor ($5BAE) and every solid object -> +12 bit 2
      dX: clip against the room's X extent ($5BAB) and objects  -> +12 bit 0
      dY: clip against the room's Y extent ($5BAC) and objects  -> +12 bit 1
      (a contact also exchanges the deadly bits of +13; see below)
    add_dXYZ ($C706): X += dX, Y += dY, Z += dZ
  look at +12, decide
  set_wipe_and_draw_flags ($C692): +7 |= $30
```

Because the clipped deltas are written back, a handler that wants an object to
keep its heading after hitting something must save and restore them
(upd_182_183 does). Because dZ is decremented on every call, a handler that
wants no gravity sets dZ to 1 before the call (the fires, the shuttling
blocks), and one that wants a steady climb sets it to one more than the climb
every frame (the bouncing-on-the-spot ball sets 3 to rise 2; the cauldron
bubbles set 2 to rise 1).

### What each handler in $B5F7-$BA21 serves

Types are decimal. "Layout" is the room-building record that creates the
object (block types at $6BD1, backgrounds at $6CE2).

| Handler | Types | Layout | What it does each frame |
|---|---|---|---|
| upd_182_183 $B5FF | 182, 183 | ball_bounce $6C5F | Falls under gravity; on landing jumps with dZ 4 (even room number) or 4-7 (odd room), thuds if it was falling, and takes a new heading of 2 a frame along X or Y (coin toss on R bit 0). The heading points away from Sabreman and towards Sabrewulf (two JR opcodes patched at $B65D/$B676). Keeps its heading through the air. Flips frame each frame; deadly. |
| upd_91 $B683 | 91 | dropping_block $6C2E | Only while something stands on it (+13 bit 3): sinks one unit a frame until it lands, with a sound. Otherwise not even redrawn. |
| upd_143 $B6A2 | 143 | collapsing_block $6C35 | When something stands on it, becomes type 184; $BF2B steps it to 185 with a sound and 185's handler ($BF37) makes it vanish. |
| upd_54 $B6B9 / upd_55 $B6B1 | 54 / 55 | block_ew $6C19 / block_ns $6C20 | Shuttles one unit a frame along X (54) or Y (55), following a triangle wave of the frame counter: 0-15-0 over 32 frames, half a cycle apart for odd and even record slots. No gravity. One routine for both, by patching IX displacements at $B6E0 and $B6F1. |
| upd_144_to_149_152_to_157 $B6F9 | 144-149, 152-157 | second record of guard_ew, guard_square, wizard | The legs of a guard or the wizard. Never moves itself; the body copies X, Y, dX, dY into it. If moving: footstep, choose view (bit 3 of type) and mirror (+7 bit 6) from the direction, step the 6-frame walk cycle ($C97F). |
| upd_150_151 $B73C | 150, 151 | guard_ew $6C9E | Walks 2 a frame along X; reverses when blocked (+13 bit 0 is the direction). Copies dX and X to its legs. Deadly. |
| set_guard_wizard_sprite $B76C | (30/31, 150/151, 158/159) | -- | Bit 0 of the type = view, +7 bit 6 = mirror, from dX/dY. |
| upd_22 $B7A3 | 22 | gargoyle $6C6D | Static; deadly; pixel offsets only. |
| upd_63 $B7A9 | 63 | spike_ball_fall $6C82 | Hangs; lets go with chance 1/16 a frame if no other ball is falling ($5BBF) and $5BC0 is 0; falls to the ground with a sound pitched by height, then stays. Deadly. |
| upd_23 $B7E7 | 23 | spike $6C74, spike_high $6C7B | Static; deadly. |
| upd_86_87 $B7ED | 86, 87 | fire_ew $6CC6 | Floats; 2 a frame along X; reverses with a thud when blocked (+13 bit 0). Flickers 86/87. Deadly. |
| upd_180_181 $B80F | 180, 181 | fire_ns $6CBF | The same along Y (+13 bit 1). |
| upd_176_177 $B83F | 176, 177 | fire $6C3C | Static; every other frame (by $5BBC bit 0) flips 176/177 and randomly toggles its mirroring. Deadly. |
| upd_178_179 $B865 | 178, 179 | ball_ud $6C51 and the shifted variants $6C43, $6C4A, $6C58 | Straight up and down: rises 2 a frame to a ceiling shared by all balls in the room ($5BBD = first ball's Z + 32), falls under gravity, bounces up with a thud on landing (+13 bit 2 = rising). Flips frame; deadly. |
| init_cauldron_bubbles $B8A9 | (160) | cauldron_bubbles $B8C8 | Called from end_of_frame: in room $88, puts the bubbles in record 3 if it is free and the game is not won. |
| upd_160_to_163 $B8DA | 160-163 | -- | Rises (not solid) from the cauldron to Z $A0, cycling four frames, then hovers; every fifth frame shows the next wanted object instead (type 168 + its number, from `ret_next_obj_required` $C274). If the player is Sabrewulf, turns into 164-167 and becomes solid. Vanishes while record 2 is in use. |
| upd_168_to_175 $B923 | 168-175 | -- | The wanted object's picture: lasts one frame, back to 160. |
| upd_164_to_167 $B92C | 164-167 | repel_spell $6CCD, and hostile bubbles | Heads straight for the player at 4 a frame on each of X and Y (1 while the player is in an archway, outside room $88), under gravity, cycling four frames. In room $88, vanishes when the player's legs are no longer type 16-79. Harmful only if +13 says so: the bubbles' record has $A0, a room's repel_spell record 0. |
| upd_111 $B95E | 111 | -- | Sets type 1 ("wipe once, then free": $D704 turns 1 into 0 after drawing). Also the common "vanish" exit. |
| upd_141 $B99C / upd_142 $B99F | 141 / 142 | cauldron $6FBF | The cauldron and its top: static, pixel offsets only. |
| upd_30_31_158_159 $B9A5 | 30, 31, 158, 159 | guard_square $6CAB, wizard $6FAE | Moves with its current deltas, then turns a quarter when that move was blocked on its axis: -X, +Y, +X, -Y and round again (+13 bits 0-1), 2 a frame -- so it walks round the walls. Copies X, Y, dX, dY to its legs. Deadly. |

The small helpers: `move_towards_plyr` $B965 (dX = +/-C, dY = +/-B towards
object 0), `toggle_next_prev_sprite` $B985 (type XOR 1),
`next_graphic_no_mod_4` $B98C (low two bits of the type + 1),
`set_deadly_wipe_and_draw_flags` $B856 and `set_both_deadly_flags` $B85C.
`p4_m4`, `save_dX_dY` and `dec_dZ_wipe_and_draw` ($B593-$B5B4) sit just below
this range; `dec_dZ_wipe_and_draw` ($B5AF, move then set wipe and draw) is the
exit the shuttling blocks use.

### Deadly contact

`set_both_deadly_flags` ORs $A0 into +13. When the collision code finds the
moving object IX touching IY, it does

```
IY.+13 |= (IX.+13 bit 7) moved to bit 6
IX.+13 |= (IY.+13 bit 5) moved to bit 6
```

so bit 7 means "hurts what I run into", bit 5 "hurts what runs into me", and
bit 6 is "has touched something deadly" -- the bit the player's handler
tests ($C82B). Setting both means it does not matter which of the two moved.
Objects with +7 bit 1 set are skipped by the collision scan
(`is_object_not_ignored` $B538), so the rising bubbles, though their +13 is
$A0 from the start, hurt nobody until they turn solid.

### Two-record creatures

A guard or the wizard is two consecutive records: the body, then the legs.
The legs have height 0 and +7 = $12 (not solid, draw). The body's handler
writes its results straight into the legs' record at IX+33 (X), IX+34 (Y),
IX+41 (dX), IX+42 (dY), before the loop reaches it in the same frame. The
pixel offsets put the body 9 pixels (guard_square, wizard) or 13 pixels
(guard_ew) above the legs. The legs use the same sprites as the player's own
legs (types 16-29 use spr_055-spr_062, as 144-157 do).

### Object record fields used by this code

| Offset | Field |
|---|---|
| +0 | type, which is also the sprite index into $7112 (the animation frame) |
| +1 | X |
| +2 | Y |
| +3 | Z |
| +4, +5, +6 | size along X, Y, Z (collision extents); 0 height = not solid in Z |
| +7 | flags: bit 0 may leave the room's bounds (set on the player near an arch by $C7DB); bit 1 not solid -- skipped by collision scans, and $CB45 does no clipping for it (also set on itself while it runs); bit 2 pushed by what runs into it and carried by what it lands on; bit 3 may use arches (the player); bit 4 draw this frame; bit 5 wipe the previous position this frame; bit 6 mirror left-right; bit 7 flip top-bottom ($D865) |
| +8 | room number |
| +9 | dX, signed |
| +10 | dY, signed |
| +11 | dZ, signed; decremented by every move call |
| +12 | result of the last move: bit 0 blocked along X, bit 1 blocked along Y, bit 2 blocked along Z (landed); set by $CB45, which clears bits 0-2 first. Higher bits are the player's (not used here) |
| +13 | per-type state: bit 0 direction (fire_ew, guard_ew; 1 = +X); bit 1 direction (fire_ns; 1 = +Y); bits 0-1 heading (guard_square, wizard: 0 -X, 1 +Y, 2 +X, 3 -Y); bit 2 falling (spiked ball) or rising (ball_ud); bit 3 something landed on me (set by $CC6B, cleared by upd_91); bit 5 hurts what runs into me; bit 6 has touched something deadly; bit 7 hurts what I run into |
| +16, +17 | pointer cleared when some objects vanish ($BF37, $C265); zero for room-built objects -- not used in this range |
| +18 | pixel X offset added to the projected position ($D6C9); set by the adj_* routines at $C4D3-$C513 and $C72B |
| +19 | pixel Y offset (positive is up the screen) |
| +24 to +31 | drawing: sprite width and height, projected pixel X and Y, and the previous frame's copies of those four (not written here) |

## How this was found

Read the listing for $B5F7-$BA21 and everything it calls: the move and
collision chain ($C700, $CB45 and its helpers $CA5A, $CA89, $CB9A, $CBE9,
$CC38, $CCDD, $CD08, $B538), the draw-flag setters ($C692, $CD4D, $D59F's use
of +7 bit 5, $D704/$D710's use of type 1 and bit 4), the pixel-offset setters
($C4D3-$C513, $C72B) and $D6C9 which consumes them, and the sound routines.
Types were tied to objects by dumping the handler table $B096 and the sprite
table $7112 from the snapshot for every type whose handler lies in the range,
and matching them against the first byte of each block-type layout at
$6C0B-$6CDB and the backgrounds at $6FAE and $6FBF. The layout format came
from the room builder at $D41E (backgrounds: type X Y Z w d h flags) and
$D46C (blocks: type w d h flags, then a position byte: bit 0 +8 on X, bit 1
+8 on Y, bits 2-7 added to Z). Object 0 as the player's legs comes from
`plyr_spr_init_data` $D1A1 (two records, the second 12 higher with no height)
and the type ranges: 16-29 human legs, 48-61 wolf legs.

## Confidence

All read from the code, not run. Inferred rather than read:

- that types 16-29 in object 0 mean Sabreman and 48-61 Sabrewulf (from the
  handler table and the sprites the two ranges use; the code only tests the
  ranges), and so the "flees Sabreman, chases Sabrewulf" reading of the
  bouncing balls and the Sabrewulf trigger for the bubbles;
- "legs" for 144-157: from their zero height, their lower pixel offset, the
  shared sprites with the player's legs, and tcdev's label
  `animate_human_legs` on $C97F;
- that bit 0 of +7 is "in an archway" for the player: from $C7DB setting it
  for objects with +7 bit 3 near an arch, and the bounds checks skipping it;
- the 128K consequence of the OUT in `read_port`: from the port decode, not
  tested.

## Renamed routines

| New name | Old name | Address | Role |
|---|---|---|---|
| bounce_ball_set_sense | loc_B626 | $B626 | patch the chase/flee jumps; work out the bounce dZ |
| bounce_ball_on_landing | loc_B63C | $B63C | on landing, bounce and thud |
| bounce_ball_pick_axis | loc_B64F | $B64F | coin toss for X or Y; compare Y |
| bounce_ball_y_sense | loc_B65D | $B65D | the patched JR for Y |
| bounce_ball_set_dy | loc_B661 | $B661 | dY = +/-2, dX = 0 |
| bounce_ball_animate | loc_B668 | $B668 | flip frame, deadly, draw |
| bounce_ball_x_axis | loc_B66E | $B66E | compare X |
| bounce_ball_x_sense | loc_B676 | $B676 | the patched JR for X |
| bounce_ball_set_dx | loc_B67A | $B67A | dX = +/-2, dY = 0 |
| drop_block_draw | loc_B69F | $B69F | dropping block: draw |
| shuttle_block | loc_B6BF | $B6BF | shuttling blocks, both axes |
| shuttle_block_target | loc_B6DB | $B6DB | target within the 16-unit span |
| shuttle_block_step | loc_B6DE | $B6DE | step towards the target (patched read) |
| shuttle_block_move | loc_B6EF | $B6EF | set the delta (patched write), move |
| legs_unmirrored | loc_B716 | $B716 | legs: mirror off |
| legs_animate_and_draw | loc_B71A | $B71A | legs: walk cycle, draw |
| legs_face_minus_x | loc_B720 | $B720 | legs: -X |
| legs_moving_in_y | loc_B726 | $B726 | legs: along Y |
| legs_mirrored | loc_B730 | $B730 | legs: mirror on |
| legs_face_plus_y | loc_B736 | $B736 | legs: +Y |
| guard_unmirrored | loc_B783 | $B783 | body: mirror off |
| guard_face_minus_x | loc_B788 | $B788 | body: -X |
| guard_moving_in_y | loc_B78E | $B78E | body: along Y |
| guard_mirrored | loc_B798 | $B798 | body: mirror on |
| guard_face_plus_y | loc_B79D | $B79D | body: +Y |
| spiked_ball_landed | loc_B7DC | $B7DC | spiked ball down: release the lock |
| fire_ew_move | loc_B7FE | $B7FE | fire east-west: move |
| fire_ns_move | loc_B820 | $B820 | fire north-south: move |
| fire_turn_if_blocked | loc_B82F | $B82F | reverse on a blocked axis |
| fire_flicker_and_draw | loc_B83A | $B83A | flip frame, deadly, draw |
| ud_ball_rise_or_fall | loc_B876 | $B876 | ball_ud: choose rise or fall |
| ud_ball_draw | loc_B892 | $B892 | ball_ud: deadly, draw |
| bubbles_draw | loc_B916 | $B916 | bubbles: draw |
| bubbles_turn_hostile | loc_B919 | $B919 | bubbles become 164-167, solid |
| chaser_speed_fast | loc_B942 | $B942 | speed 4 |
| chaser_chase | loc_B945 | $B945 | aim, move, maybe vanish |
| sound_wipe_and_draw | loc_B962 | $B962 | jump to $C232 |
| towards_plyr_y | loc_B973 | $B973 | move_towards_plyr, Y half |
| towards_plyr_set_dy | loc_B981 | $B981 | move_towards_plyr, store dY |

No meaningful tcdev name was changed. `guard_NSEW_tbl` ($B9D8) is kept, but
note its order is W, N, E, S (headings 0-3), with tcdev's W = -X, N = +Y,
E = +X, S = -Y.

Corrections to existing annotations:

- `read_port` ($B5F7): the old text said the OUT selects the half-row. It does
  not; `IN A,($FE)` puts A on the high address byte by itself. The OUT writes
  to port A*256+$FD, which nothing on a 48K answers. The inputs were also thin:
  callers pass 0 (every row, for "any key") and multi-row masks like $7E, $99,
  $BD, not only single half-rows $FE-$7F.
- `$7112` (not in this range): it is indexed by +0 times 2, one word per type,
  not "type times eight plus a frame".

## Open questions

- `$5BC0` holds bit 0 of the room number from room entry until the player picks
  something up, and while it is non-zero spiked balls never fall. Why odd rooms?
  Not yet worked out whether that bit means something else about a room.
- The bouncing ball's jump height also depends on the room number's bit 0 (4 in
  even rooms, 4-7 in odd). Same question.
- The cauldron bubbles' record ($B8C8) says room $B4, not $88. The only thing
  here that reads a moving object's room is upd_164_to_167's test for $88, so
  hostile bubbles take the "other room" path (slow in archways, never vanish on
  the player's death). Whether $B4 is deliberate, and whether any other code
  (the renderer, room change) cares about an object's +8, is not yet worked out.
- guard_ew's body is drawn 13 pixels above its legs, guard_square's and the
  wizard's 9. Whether that is visible, or compensated somewhere, is not checked.
- When a collapsing block vanishes, $BF37 writes 0 through its +16/+17 pointer,
  which is 0 for a room-built object, so the write lands on ROM address 0 and
  does nothing. Harmless, but worth knowing if +16 is ever given a meaning for
  blocks.
- The sounds ($B42E, $B451, $B45D, $B462, $B4AD) are only described by what
  pitches them here; their own entries are in another part.
