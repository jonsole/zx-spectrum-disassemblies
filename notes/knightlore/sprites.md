# Sprites

**Question this answers:** how are sprites stored, how does an object find its sprite, and which sprite is what?

**Short answer:** `sprite_tbl` ($7112) is 188 words, one per object type (byte +0 of an object record); animation is done by changing the type. Each of the 103 sprites is a 2-byte header (width in bits 0-3, current mirror/flip state in bits 6/7; height) followed by rows of (mask, image) byte pairs, bottom row first. Mirroring and flipping are done to the sprite data in place, so the header bits are run-time state.

## How it works

```
print_sprite $D718
  flip_sprite $D6EF          HL = sprite_tbl + 2 * (IX+0); DE = sprite
                             header byte 0 = 0 -> pop caller, draw nothing (types $00, $01)
    vflip_sprite_data $D865  if header bit 7 != (IX+7) bit 7: swap rows top<->bottom in place, toggle bit 7
    loc_D8A2                 if header bit 6 != (IX+7) bit 6: reverse pair order in each row and
                             bit-reverse each byte through the $F1xx table ($F100), toggle bit 6
  (IX+$1A) AND 7 = 0 -> loc_D76F: width = byte0 AND $0F  (unshifted)
  else width = (byte0 AND 7) + 1 bytes via the pre-shifted tables in pages $F2-$FF
  loc_D73C: height -> IX+$19, clipped so Y + height <= $C0
  per pair: buffer = (buffer AND NOT mask) OR image; next row = buffer address + 32 (upwards)
```

### Sprite format

| Offset | Field |
|---|---|
| 0 | bits 0-3 width in bytes (1-5 in this game); bit 6 set while stored mirrored; bit 7 set while stored upside down; bits 4-5 unused |
| 1 | height in rows |
| 2 .. | height rows, each width pairs of (mask, image). Mask 1 = clear the pixel behind; image ORed in after. Pixel = transparent / black / ink. |

Rows are stored bottom first: the screen buffer at $D8F3 has y growing upwards (`calc_vidbuf_addr` $D811 = $D8F3 + y*32 + x/8), and `calc_vram_addr` ($D826) and `blit_to_screen` complement y when copying to the display. Size of every sprite = 2 + 2 * width * height, true for all 103.

The flip state is the explanation for spr_014 (the border corner, $7B5A) having header $84: `print_border` ($D296) prints its four corners with flags $00, $40, $C0, $80 (`border_data` $D2CF), so after the last corner the data is left upside down and not mirrored. The existing annotation's "width AND $7F" and "bit 7 is an unknown flag" were wrong: the width is bits 0-3 and bits 6-7 are state.

### Types -> sprites

`sprite_tbl` and the handler table `upd_sprite_jmp_tbl` ($B096) are both indexed by the type directly (x2). The existing annotation's "type times eight plus a frame" was wrong. Walk cycles are six consecutive types naming sprites 1 2 3 4 3 2; `animate_human_legs` ($C97F) steps the low three bits 0..5.

| Types | What | Sprites |
|---|---|---|
| $00-$01 | nothing / being removed | spr_nul |
| $02, $03 | arch pillars | spr_071, spr_072 |
| $04, $05 | forest-exit tree trunks | spr_023, spr_024 |
| $06 | rock | spr_008 |
| $07, $36, $37, $3E, $5B, $8F | stone block (plain, moving x2, movable, dropping, collapsing) | spr_020 |
| $08, $09 | portcullis (still, moving) | spr_043 |
| $0A-$0C | wall slabs | spr_076-078 |
| $0D, $0E, $0F | wall columns, wall end | spr_069, spr_070, spr_073 |
| $10-$15, $18-$1D | Sabreman's legs, view A / view B | spr_055-058 / spr_059-062 |
| $16 | gargoyle | spr_009 |
| $17 | spikes | spr_002 |
| $1E-$1F, $96-$97 | guard's body | spr_005, spr_004 |
| $20-$25, $28-$2D | Sabreman's head and shoulders, views A/B | spr_050,051,046,049 / spr_052,047,054,053 |
| $26-$27, $2E-$2F | occasional upper-body frames | spr_048, 063 / spr_065, 064 |
| $30-$35, $38-$3D | werewulf legs | spr_079-082 / spr_083-086 |
| $3F | spiked ball | spr_003 |
| $40-$4F | werewulf head and shoulders | spr_087-090, 095, 096 / spr_094-091, 097, 098 |
| $50-$53 | ghost | spr_039-042 |
| $54 / $55 | table / chest | spr_045 / spr_044 |
| $56-$57, $B0-$B1, $B4-$B5 | fire (x-mover, still, y-mover) | spr_010, spr_011 |
| $58 / $59 | sun / moon | spr_037 / spr_038 |
| $5A / $BA | ends of the sun/moon window | spr_000 / spr_001 |
| $5C-$5F | man/wolf transformation | spr_099-102 |
| $60-$66 | the seven charms | spr_031, 032, 022, 033, 034, 035, 036 |
| $67 | extra-life charm | spr_021 |
| $68-$6E | charm flying into the cauldron | same as $60-$66 |
| $6F, $70-$77, $78-$7F, $83-$85, $A0-$A7, $B8, $B9, $BB | sparkles (vanish = big to small, appear = small to big) | spr_025-030 |
| $80-$82 | forest trees | spr_066-068 |
| $86-$88 | status panel scroll | spr_019, spr_017, spr_018 |
| $89 / $8A / $8B | border corner / side line / top column | spr_014 / spr_015 / spr_016 |
| $8C | lives icon | spr_021 |
| $8D / $8E | cauldron / its top | spr_074 / spr_075 |
| $90-$95, $98-$9D | legs of guards and wizard | Sabreman's leg sprites |
| $9E-$9F | wizard's body | spr_013, spr_012 |
| $A8-$AF | charm shown over the cauldron as wanted next | charm sprites |
| $B2-$B3, $B6-$B7 | ball | spr_006, spr_007 |

Evidence for the groupings: the player is initialised as legs + upper object (`plyr_spr_init_data` $D1A1, `byte_D171` = $12, `byte_D191` = $22); `set_top_sprite` ($CE22) sets the upper type to the legs' type + $10, or (legs AND $F8) OR 6/7 at random; `lose_life` ($D12A) adds $20 to both types by night; `rand_legs_sprite` ($C357) picks $5C-$5F; `init_death_sparkles` ($BF21) sets $70; appear sparkles start at $78 and `upd_127` ($BF11) turns into the type saved at +$10; `init_sun` ($C46D) sets $58 and `toggle_day_night` ($C3FF) XORs bit 0; `display_frame` ($C3C3) prints $5A and $BA; `panel_data` ($D27E), `border_data` ($D2CF), `print_lives_gfx` ($BC7A, type $8C); `init_special_objects` ($C47E) makes $60-$67; `upd_103` ($C1AB) gives a life for $67; `upd_104_to_110` ($C1F1) steers $68-$6E to the room centre; `upd_160_to_163` ($B8DA) sets $A8 + wanted kind, or $A4.. when the player is the werewulf; `prepare_final_animation` ($C2CC/$C2EE) turns $07 into $83; `objs_coincide` ($CFE1) turns a charm into $BB.

## How this was found

Read `flip_sprite`, `print_sprite`, `vflip_sprite_data` and the hflip half at $D8A2, `calc_vidbuf_addr` and `calc_vram_addr`. Wrote a scratchpad script that dumped `sprite_tbl` against the handler table's labels, then rendered every sprite as text (mask/image to transparent/black/ink), bottom row first, to check orientation (a table's legs hang down only that way up) and to see which frames belong together.

## Confidence

Format, flip mechanism, table indexing and the type groupings: read from the code. Which view (A = type bit 3 clear, B = set) faces the viewer, and what the seven charm sprites depict (gem, flask, boot, goblet, cup, bottle, ball), are inferred from the pixels only and said so in the titles' descriptions.

## Renamed routines

None: the spr_NNN labels are kept (tcdev's numbering, referred to by other sources); their titles now say what each is.

## Open questions

- Which of views A and B is the back and which the front.
- The real names of the seven charms (the pixel shapes are only suggestive).
- Whether the guard/wizard "legs" object ($90-$9D, flags bit 1) is drawn above or below the body -- both parts are laid at the same x, y, z with different pixel offsets.
