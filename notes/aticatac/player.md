# The player: knight, wizard and serf

**Question this answers:** how the player moves and fires, and what really
differs between the three characters.

**Short answer:** all three walk at the same top speed, two pixels a frame,
and share one movement routine. They differ in four things: how far they
coast when the keys are let go (the wizard stops dead, the knight slides 5
pixels, the serf 16), their weapon (the knight's spinning axe, the wizard's
flickering spell, the serf's sword that points where it flies), its firing
sound, and which secret passages they can use (clocks for the knight,
bookcases for the wizard, barrels for the serf).

## How it works

**The three handlers** (*read*): `UPDATE_KNIGHT` ($8E26), `UPDATE_WIZARD`
($80D2) and `UPDATE_SERF` ($8DC4) run once a frame from `FRAME_TICK`, for
sprites $01-$10, $11-$20 and $21-$30. Each loads BC, DE and HL and calls
`MOVE_PLAYER` ($8D77), animates, fires if fire is held, and goes on to
`PLAYER_TICK` ($8E78; the knight falls into it, the others jump): the
spawner, the life-force drain, and the redraw.

| | Knight | Wizard | Serf |
|---|---|---|---|
| step (B) | $20 | $20 | $20 |
| decay per frame (DE) | 3 | 32 | 1 |
| HL passed | $0707 | $2020 | $0707 -- popped and never used |
| coast after release (*measured*) | 5 px | 0 | 16 px |
| weapon | axe, sprites $40-$47 | spell, $34-$37 | sword, $38-$3F |
| fire routine | `KNIGHT_FIRE` $8134 | `WIZARD_FIRE` $814B | `SERF_FIRE` $8283 |
| fire sound | $A41B, twelve falling steps | $A438, eight steps | $A427, sixteen rising steps |
| passage | clock (type $10) | bookcase ($17) | barrel ($1A) |

**Movement** (*read*, then *measured*). `MOVE_PLAYER` reads the controls
(`READ_CONTROLS`, [`input.md`](input.md)) into a wanted change of 32 on each
axis, lets the heading at +$06/+$07 decay towards zero by the character's
amount (`DECAY_HEADING` $8F96), adds the wanted change and clamps to 32
(`STEER` $8EEF), and converts the heading to a step by dividing by sixteen
(`SCALE_SIGNED` $8F80): 32 is two pixels, 16-31 one, under 16 none. Held
keys therefore give two pixels a frame at once for everyone; let go, the
heading falls by the decay each frame. In the simulator, after eight frames
holding W, the knight moved 1 pixel a frame for five more frames and
stopped, the serf for sixteen, the wizard not at all. Then the step is
tested ([`collision.md`](collision.md)) and applied (`APPLY_HEADING`).

While the low nibble of the player's +$02 is set -- fifteen frames after
coming through a door, one frame after being caught -- `DECAY_HEADING` does
nothing and `STEER` ignores the controls, moving the player two pixels along
the heading's sign ([`doors.md`](doors.md)).

**Pictures** (*read*). Sixteen codes per character: base + 0-3 walking left,
+4-7 right, +8-11 up, +12-15 down. While moving, on frames where FRAMES AND 3
is zero, the frame cycles through the four, the heading is chosen by the
larger of |dx| and |dy|, and `SOUND_FOOTSTEP` is called (which sounds every
other call, low and high notes in turn). The heading order is confirmed by
`FIRE_WEAPON` ($817C): a player standing still fires left for base + 0-3,
right for +4-7, up (y - 4) for +8-11, down for +12-15.

**Firing** (*read*). Only when the weapon slot ($EA98) is empty and the
player is inside the room's walk area (`IN_DOORWAY` $5E2D clear, so not in
a doorway). The weapon gets +/-4 on each axis the heading is non-zero along,
or the facing direction if standing still, the player's room and position,
and a lifetime of 48 frames at $EAA7. `FRAME_TICK` then dispatches it each
frame: the axe (`SPIN_AXE`) takes its frame from FRAMES, so it turns through
eight angles as it flies, drawn red; the spell (`SPIN_SPELL`) steps through
its four frames, alternating cyan and white; the sword (`AIM_SWORD`) is
drawn at whichever of eight angles matches its velocity (`SIGN_TO_DIRECTION`),
yellow, and changes only when it bounces. All three then run `SPIN_WEAPON`
($8209): it bounces off the walk area's edges (with `SOUND_BOUNCE`, $A4B0),
and ends -- erased, with `SOUND_WEAPON_GONE` ($A445) -- when its 48 frames are up,
when it has hit something, or at once if the player has left the room.

**What a weapon can hit** (*read*): the small creatures' movers call
`CHECK_SHOT_HIT` ($8566), a 12-pixel box around the weapon; a hit sets the
weapon's hit flag and destroys the creature for 155 points
([`monsters.md`](monsters.md)). The five big monsters never test for the
weapon: the axe, spell and sword pass through them.

**Starting and restarting** (*read*, then *measured*). `PLACE_PLAYER` ($9443)
copies `PLAYER_TEMPLATE` into $EA90 with the current room patched in and the
character's code $08, $18 or $28 (a right-facing frame) in +$07; the sprite is $66,
at ($60, $68). It sets the life force to 240, redraws the roast and lives,
and starts a 104-frame countdown during which `MATERIALISING` ($8CB7) flashes
the score instead of rising. Then the figure rises one row every four frames
(18 rows for the knight, 72 frames) and becomes the character again. Death
runs the other way ([`food-and-health.md`](food-and-health.md)). While the
sprite is $66 or $67 the player is not "in play": no door, object, hit or
pick-up registers.

## How this was found

Read the three handlers and everything `MOVE_PLAYER` calls; the unused HL
came from following the three PUSHes and three POPs. The coasting was
measured in the simulator (`aticatac_t4.py`): the player's x logged at each
`FRAME_TICK` while holding W for eight frames and after letting go, once per
character; the weapon types came from the annotations' live check and the
code.

## Confidence

Movement and coasting *measured*; weapons and pictures *read*.

## Renamed routines

Applied to the annotations on 2026-09-27; the build verified byte for byte.

| New name | Old name | Address | Role |
|---|---|---|---|
| `KNIGHT_FIRE` | `TRY_FIRE_THIRD` | $8134 | the knight's axe |
| `WIZARD_FIRE` | `TRY_FIRE_ALT` | $814B | the wizard's spell |
| `SERF_FIRE` | `TRY_FIRE` | $8283 | the serf's sword |
| `AIM_SWORD` | `SPIN_SWORD` | $82F1 | points the sword along its flight |
| `SOUND_WEAPON_GONE` | `SOUND_SPELL` | $A445 | any weapon or burst ending |
| `SOUND_BOUNCE` | `SOUND_SPELL_2` | $A4B0 | any weapon bouncing |
| `WEAPON_LIFE` (equate) | `SOUND_SLOT+7` | $EAA7 | the weapon's lifetime |
## Disassembly corrections

All applied to the annotations, the ref and the build on 2026-09-27 (the old names are used below), except where marked.

- `TRY_FIRE_THIRD` "Fire, for the third character" is the knight's (the first
  on the menu); `TRY_FIRE` is the serf's, `TRY_FIRE_ALT` the wizard's.
- `SPIN_SWORD`: "cycling through them is what makes it appear to spin". The
  sword's frame is chosen from its velocity; it does not spin.
- `SOUND_SPELL` "The wizard's spell ... Called from SPIN_SPELL" and
  `SOUND_SPELL_2` "The spell's second noise": both are in `SPIN_WEAPON`, which
  all three weapons share -- the end of a flight (also the end of every
  burst, via `COUNTDOWN_ACTOR`) and a bounce.
- `SCALE_SIGNED` "Divide a signed value by eight": four rotations and
  AND $0F -- by sixteen.
- `MOVE_PLAYER`: "the player accelerates into a direction and coasts out of
  it". The heading reaches its maximum in one frame; only the coasting is
  gradual, and it is the character's decay.
- `UPDATE_KNIGHT` at $8E3C: "the walk cycle advances every fourth frame" is
  right, but "the life force runs down ... Only every sixteenth tick" counts
  main-loop passes (TICKS), not frames ([`food-and-health.md`](food-and-health.md)).
- The build's comment at `PLAYER_HEADINGS` says the left/right/up/down order
  "is not derived from anything here". `FIRE_WEAPON` and the three handlers
  derive it.
- `FIRE_WEAPON` at $817F "Mark the weapon as in flight": it sets the 48-frame
  lifetime.

## Open questions

- Why the handlers pass an HL that `MOVE_PLAYER` discards -- a limit meant for
  `STEER` that lost its place in the POP order? (`STEER` is given the BC value
  instead, $2020.)
