# Object types

**Question this answers:** What is each of the 188 object types, and which
handler runs it?

**Short answer:** The type byte is both the handler index into
`upd_sprite_jmp_tbl` ($B096) and the sprite number in `sprite_tbl` ($7112), so
types come in runs, one per animation frame or facing. 0 and 1 are slot states;
about fifteen types are panel artwork that never enter the object table; the
rest are Sabreman, the room's fixtures and creatures, the charms, and the
sparkle effects.

## How it works

Types were identified from three things: the block and background definitions
at $6C0B-$6FE1 (whose first byte is the type they place: block 7, fire 176,
guard 150 + 144, wizard 158 + 144, cauldron 141 + 142 and so on), the code that
writes a type (for example `init_death_sparkles` writes 112,
`init_special_objects` 96-103, `init_cauldron_bubbles` 160, `exit_screen` 120),
and the handlers themselves.

| Types | What | Handler |
|---|---|---|
| 0 | empty slot | no_update (RET) |
| 1 | gone: draws nothing so the old image is wiped, then the renderer sets 0 | no_update |
| 2, 3 | stone arch halves; 2 also nudges Sabreman into line with the doorway | upd_2_4 / upd_3_5 |
| 4, 5 | tree-room arch halves | upd_2_4 / upd_3_5 |
| 6 | rock | upd_6_7 |
| 7 | plain block | upd_6_7 |
| 8 | portcullis at rest, choosing when to move; one moves at a time ($5BAF) | upd_8 |
| 9 | portcullis moving; kills what it lands on; crash on landing | upd_9 |
| 10-15 | wall pieces | upd_10, upd_11, upd_12_to_15 |
| 16-21, 24-29 | Sabreman's legs, human: six walking frames x two facing pairs (bit 3); mirroring (+7 bit 6) gives four facings | upd_16_to_21_24_to_29 -> upd_player_bottom |
| 22 | gargoyle, deadly | upd_22 |
| 23 | spikes, deadly | upd_23 |
| 30, 31 | guard that patrols round the room, upper body | upd_30_31_158_159 |
| 32-47 | Sabreman's upper body, human: legs type + 16; 38/39 and 46/47 are random idle frames held for eight frames | upd_32_to_47 -> upd_player_top |
| 48-53, 56-61 | Sabreman's legs, werewolf (human + 32) | upd_48_to_53_56_to_61 |
| 54, 55 | blocks sliding back and forth along X / Y, on a 32-frame triangle wave | upd_54, upd_55 |
| 62 | "movable" block: stops each frame, falls, blips every frame | upd_62 |
| 63 | spiked ball: drops once at random (1 in 16 per frame, one at a time) | upd_63 |
| 64-79 | werewolf upper body | upd_64_to_79 |
| 80-83 | ghost, random wandering, deadly | upd_80_to_83 |
| 84, 85 | table, chest | upd_84, upd_85 |
| 86, 87 | flame running along X, deadly | upd_86_87 |
| 88, 89, 90 | sun, moon, left end of their frame -- panel only | upd_88_to_90 |
| 91 | block that sinks while stood on | upd_91 |
| 92-95 | Sabreman mid-transformation | upd_92_to_95 |
| 96-102 | the seven charms, lying in a room | upd_96_to_102 |
| 103 | extra life (4 of the 32 special-object records) | upd_103 |
| 104-110 | a charm dropped high in the cauldron room, drifting to the cauldron | upd_104_to_110 |
| 111 | extra life just collected | upd_111 |
| 112-119 | death sparkles | upd_112_to_118_184, upd_119 |
| 120-127 | Sabreman materialising; 127 restores the type saved at +$10 | upd_120_to_126, upd_127 |
| 128-130 | tree-trunk wall pieces | upd_128_to_130 |
| 131-133 | finale sparks | upd_131_to_133 |
| 134-140 | panel pieces, border corner and edges, lives icon -- panel only | no_update |
| 141, 142 | cauldron, and its second sprite | upd_141, upd_142 |
| 143 | block that crumbles when stood on | upd_143 |
| 144-149, 152-157 | legs of a guard or the wizard | upd_144_to_149_152_to_157 |
| 150, 151 | guard that walks back and forth along X, upper body | upd_150_151 |
| 158, 159 | wizard, upper body | upd_30_31_158_159 |
| 160-163 | cauldron bubbles | upd_160_to_163 |
| 164-167 | repel spell, homing on Sabreman | upd_164_to_167 |
| 168-174 | picture over the cauldron of the charm it wants next; 175 is never made | upd_168_to_175 |
| 176, 177 | flickering fire, deadly | upd_176_177 |
| 178, 179 | ball bouncing up and down, deadly | upd_178_179 |
| 180, 181 | flame running along Y, deadly | upd_180_181 |
| 182, 183 | ball hopping towards the werewolf and away from the man | upd_182_183 |
| 184, 185 | crumbling block vanishing | upd_112_to_118_184, upd_185_187 |
| 186 | right end of the sun/moon frame -- panel only | no_update |
| 187 | a charm destroyed where it met another object | upd_185_187 |

Behaviours worth knowing, all read from the handlers:

- **Wrong charm in the cauldron.** `add_obj_to_cauldron` consumes the charm
  whether or not it is the one wanted: only a match advances $5BBB and cycles
  the colours, but either way the charm's special-object record is zeroed and
  the object vanishes.
- **The cauldron's hint.** The bubbles (160-163) rise to height $A0; every
  fourth frame at the top they show the wanted charm (168-174) for a frame. If
  Sabreman is a werewolf they become the repel spell (164-167) instead and turn
  solid.
- **The chasing ball (182/183)** self-modifies two JRs by whether Sabreman's
  legs type is human or werewolf, so it hops away from the man and towards the
  wolf. Its hop height is 4, or 4-7 at random in odd-numbered rooms.
- **The finale.** When the fourteenth charm goes in, `prepare_final_animation`
  sets $5BC3, empties objects 3-13 and turns every type-7 block from object 14
  on into a finale spark. Sparks rise two a frame round the middle of the room
  (direction by quarter, from `dX_dY_tbl`), then from height $A4 fly level at
  Sabreman with collisions off. One coming within 6 on X and Y jumps to
  `game_over`, which sees $5BC3 and shows the closing message.
- **Crumbling blocks come back.** Type 185 zeroes the byte its +$10/+$11
  points at, which removes a charm from the game for good (type 187). A
  crumbling block's +$10/+$11 is zero, so for it the write lands on ROM
  address 0 and does nothing: the block is back next time the room is built.
- **Spiked balls in odd rooms wait.** `upd_63` never starts a drop while $5BC0 is set;
  `build_screen_objects` sets it to the room number's bit 0, and picking up an
  object or an extra life clears it.

## How this was found

Read each of the 188 table entries' handlers, the block and background
definitions, and every instruction that writes a literal type. Sprite sharing in
`sprite_tbl` confirmed the groupings (the legs of guards and wizard use the same
sprites as Sabreman's human legs; 88/89/90/186 and 134-140 are only ever drawn
through `print_sprite` from a scratch record).

## Confidence

The groupings and handlers are read. The names of what things look like (rock,
table, gargoyle and so on) come from the block-definition labels and were not
checked against the sprites' pixels. Walls 10-15: which piece is which was not
worked out. Deadliness is read from the +$0D bits (7 and 5) and the collision
code's use of them; the repel spell's deadliness is not set by its handler and
was not traced further.

## Renamed routines

None of the handlers were renamed; their tcdev names are the type ranges.

## Open questions

- Type 62's handler blips the speaker every frame. Rooms $08, $40, $58, $86,
  $A3, $BB, $BF and $C7 place it (block type 16, from the generated room
  lines). That it cannot be pushed is *watched*: see
  [`collision.md`](collision.md).
- Type 85 (chest) does not stop itself after a push, unlike the table (84).
  Whether the collision code stops it instead was not traced.
- Types 10-15: which wall piece each is.
- Type 111 is reached from 103 by setting bit 3; nothing else makes it.
