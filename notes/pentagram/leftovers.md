# Leftovers: what is in the game but unused

**Question this answers:** which code, data and variables are unreached or
unused, and what each suggests about how the game was made.

**Short answer:** a handful of unreachable routines (a Z bounce, a blip, two
beeps, a builder nudge, a deadly update, three drawing offsets, two lone
RETs, a colour-byte text printer), 80 bytes of pitch tables, a tune, three
sprites no graphic reaches and graphics no room uses, seven variables or
fields nothing reads, and a trail of Knight Lore features cut out of the code
with the code around them left in place.

## How it works

| What | Where | Status |
|---|---|---|
| A lone RET | `STRAY_RET_LEGS` $C4A2 | between `PLAYER_LEGS` and `CHK_PLYR_OOB`; nothing reaches it; left as data (*read*) |
| A lone RET | `STRAY_RET_OFFSETS` $C74A | before the drawing offsets; nothing calls it or is it; now code (*read*, *searched*) |
| Three drawing offsets (-4, -12; -36, -4; -20, -8) | `UNUSED_OFFSETS` $C750 | no update-table entry or call reaches them: offsets for graphics this version no longer has (*searched*; the reason *inferred*) |
| An update routine: make deadly, then redraw | `DEADLY_AND_DRAW` $C28B | no graphic's entry points at it; left as data (*read*) |
| Set the builder's nudge | `SET_PLACE_NUDGE` $CA7C, `SET_PLACE_NUDGE_END` $CA7F | six bytes no jump reaches, so `PLACE_NUDGE` is always 0; a header code like template 31's once led there (*searched*; the history *inferred*) ([`room-building.md`](room-building.md)) |
| Template 31, a second page of templates | `TEMPLATE_PAGE` $CA6C | code that works, but no room uses it; never ran (*read*, *measured* by coverage) |
| Bounce in Z | `BOUNCE_Z` $CCFB | the third of the homer's bounces; `HOMER` tests only U and V; now code (*read*) |
| A blip by the turn counter | `BLIP_BY_TURN` $D56C | Knight Lore's movable-block blip, gated on bit 1 of the flags; no reference; now code (*searched*) |
| 16 + 64 bytes of pitches | $D587-$D5D6, `BLIP_PITCHES` to the end of `MORE_PITCHES_D` | the blip's sixteen, then 64 no code reads (*searched*) |
| Two beeps, by graphic and by a spare byte | `BEEP_BY_GRAPHIC` $D665, the byte at $D673 | no reference; kept as data because the spare byte in its middle would become a NOP an LD reads (*searched*) |
| Effects 2 and 3 | `EFFECTS` $D60D, `EFFECT_PITCHES_C` $D61B | notes and addresses, never started (*read*) |
| A tune | `TUNE_UNUSED` $D824 | nothing refers to it (*searched*) |
| A text printer with a colour byte | `PRINT_TEXT_STD_FONT` $BC7A | Knight Lore's `print_text_std_font`/`print_text`, running on into `TEXT_ATTR_ADDR`; unreached, left as data (*read*) |
| Graphic 77 | `JUMP_L16_D12` $CB51 | no template has it; never ran (*read*) |
| Graphic 85 | `BOBBER` $CE31 | reached only through graphic 86's routine; no room places 85 (*read* from the data) |
| Graphics 121-127 | `PENTAGRAM_PIECE` $CF14 | in no template, room or quest record (*read* from the data) |
| Graphic 141 | `CONVEYOR_MINUS_U` $D2E9 | has a template, but no room places it; never ran (*read*, coverage) |
| Graphic 60's update routine | `UPDATES`, entry 60 -> `BOLT` | a panel piece given the bolt's routine; no room object has it (*read*) |
| Three sprites | `SPARE_SPRITEA` $853F (eight bytes, no sprite), `SPARE_SPRITEB` $8547 (32 by 24), `SPARE_SPRITEC` $8A17 (16 by 16) | no graphic number or code address reaches them (stage 1, *read*) |
| The nineteenth quest record | $D552-$D561 | the block at `QUEST_RECORDS` has room for 19; 18 are used (*read*) |
| Collectables' start places in `QUEST_START` | records 4-8 at $D352 | overwritten by `NEW_QUEST` every game (*read*) |
| The room byte in `PLAYER_START` | $C3F7 | replaced at once by `CHOOSE_START` (*read*) |
| $A70B, $A76E | variables | nothing refers to them; the loaded block was searched for their addresses (*searched*) |
| `MENU_SPARE` $A735 | variable | only an `LD HL` the next instruction overwrites (*read*) |
| `MENU_PASSES` $A70A | variable | counted up, never read (*read*, *searched*) |
| `CONTROL_BEFORE` $A70C | variable | compared by the menu, the result thrown away (*read*) |
| `MAIN_SP` $A73E | variable | saved every turn, never read (*searched*) |
| +$0D bit 0 | a thing put down | set by `FILL_PUT_DOWN`, read by nothing (*read*) |
| The body's graphic hold, bits 0-3 of its +$0D | `PLAYER_TOP` | read, never set; never ran (*read*) |
| Bit 0 of +$11 set by `ALL_FOUR_DONE` | the quest item's link | points it 256 bytes on; seems to do nothing ([`quest.md`](quest.md)) |
| `LD B,A` $BECD, `LD E,A` $BED7 | `READ_CONTROLS` | values nothing uses (*read*) |
| `SPARE` $F08F-$F0FF | between the buffer and the tables | nothing uses it (*read*) |

**Knight Lore features cut out, their code left** (*read*; each compared with
Knight Lore's routine):

- Directional joystick control: `HANDLE_LEFT_RIGHT` still has it, behind bit 3
  of `CONTROL`, which no menu choice sets; `FLASH_MENU` still flashes a sixth
  line for it, which in Pentagram is the start line; `MENU` still clears the
  flash on eight lines; `CHK_PICKUP_DROP` still takes pick-up from bit 5 in
  that mode, which nothing sets ([`input.md`](input.md)).
- The turning sound: `BIT 2,C / JR NZ` to the next instruction ($C535).
- The falling sound: an `ADD A,$02` ($C646) whose result nothing reads.
- The exit check: `EXIT_STUB` ($C6B5), a RET where Knight Lore's move calls
  it.
- The head's random frames: the body's hold count, with no setter.
- The movable block's blip: `BLIP_BY_TURN`, above.
- Strings with colour bytes: `PRINT_TEXT_STD_FONT`, above.
- The object template's sixth byte: `SET_PLACE_NUDGE`, above.

**What they suggest** (*inferred*): Pentagram was made by editing Knight
Lore's source (the leftovers sit where Knight Lore's code was, in the same
order) rather than by rewriting the engine; the unused offsets, graphics
121-127, 85 and 77, and the spare sprites, belong to things designed and then
dropped; the unused tune and effects to sounds that went with them.

## How this was found

The build's coverage file lists the code that never ran in its sessions
(`pentagram-coverage.txt`, 196 bytes in 25 runs), and each stage 2 agent read
every placeholder data block in its range as possible code; every address of
the unreached code and of the unread variables was searched for in the loaded
block as a little-endian word (*searched*: no references beyond chance
matches inside other instructions). Graphics no room uses were found from the
generated room and template data.

## Confidence

*Read* and *searched* for each row as tagged. The history is *inferred*.

## Open questions

- Which header value reached `SET_PLACE_NUDGE`, and what graphics the unused
  offsets were for.
- Whether `TUNE_UNUSED` and effects 2 and 3 were played in another version
  (only one tape looked at).
