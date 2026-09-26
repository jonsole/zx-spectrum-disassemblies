# Hand-written annotations for the Knight Lore disassembly.
#
# scripts/build_knightlore.py reads the code map from
# scripts/knightlore_structure.ctl -- which bytes are instructions, which are
# data, and what things are called -- and then layers THIS file on top of it.
# Keeping the two apart is what makes the annotations survive: the map is
# regenerated from its source, this one is not.
#
# So: never edit game_disassembly/knightlore/*.asm or *.skool by hand -- the
# next build overwrites both. Add what you learn here instead.
#
# On provenance: the map's block boundaries and labels come from the
# disassembly by tcdev (2017) as converted to SkoolKit by Michael R. Cook
# (2019), with credit and nothing copied beyond that factual layer. The prose
# below is ours. Everything it asserts was checked against the code in this
# build or measured from the snapshot; where a claim is a guess it says so.
#
# Format (SkoolKit control file):
#   @ $ADDR label=NAME     give the routine a name
#   c $ADDR Title          one-line title for the routine
#   D $ADDR Paragraph.     description under the title
#   R $ADDR HL What it is  an input/output register
#     $ADDR,N Comment      comment on the instruction(s) at $ADDR
#   E $ADDR Paragraph.     closing note under the routine
#
# One rule about names: never end one with an underscore and a digit.
# skool2asm invents NAME_0, NAME_1 and so on for the jump targets inside a
# routine called NAME, and an explicit label of that shape collides with them.

# --------------------------------------------------------------------------
# Where the game lives
# --------------------------------------------------------------------------

# --------------------------------------------------------------------------
# Data: fonts, rooms, block types, backgrounds, sprites
# --------------------------------------------------------------------------

# --------------------------------------------------------------------------
# The data below the code: font, rooms, sprites ($6108-$AF6B)
# --------------------------------------------------------------------------

b $6108 The font
D $6108 Forty characters of 8 by 8 pixels, eight bytes each with the top row first.
. A character's code is its position here: $00 to $09 are the digits, $0A to
. $23 the letters A to Z, $24 a full stop, $25 a copyright sign, $26 a space
. and $27 a percent sign. There is no lower case. Strings are lists of these
. codes with bit 7 set on the last one (#R$BE4C).
D $6108 #R$BE7F finds a character by multiplying its code by eight and adding the
. address held at $5BC7, which every caller of it sets to this table first.
. All the game's text comes from here: the menu, the day and lives counters
. and the messages.
E $6108 This is the first byte of the disassembly. Below it, $5BA0 to $6107 holds
. the game's variables and its forty object records, which #R$AF6C clears at
. start-up.
B $6108,8 Code $00: 0
B $6110,8 Code $01: 1
B $6118,8 Code $02: 2
B $6120,8 Code $03: 3
B $6128,8 Code $04: 4
B $6130,8 Code $05: 5
B $6138,8 Code $06: 6
B $6140,8 Code $07: 7
B $6148,8 Code $08: 8
B $6150,8 Code $09: 9
B $6158,8 Code $0A: A
B $6160,8 Code $0B: B
B $6168,8 Code $0C: C
B $6170,8 Code $0D: D
B $6178,8 Code $0E: E
B $6180,8 Code $0F: F
B $6188,8 Code $10: G
B $6190,8 Code $11: H
B $6198,8 Code $12: I
B $61A0,8 Code $13: J
B $61A8,8 Code $14: K
B $61B0,8 Code $15: L
B $61B8,8 Code $16: M
B $61C0,8 Code $17: N
B $61C8,8 Code $18: O
B $61D0,8 Code $19: P
B $61D8,8 Code $1A: Q
B $61E0,8 Code $1B: R
B $61E8,8 Code $1C: S
B $61F0,8 Code $1D: T
B $61F8,8 Code $1E: U
B $6200,8 Code $1F: V
B $6208,8 Code $20: W
B $6210,8 Code $21: X
B $6218,8 Code $22: Y
B $6220,8 Code $23: Z
B $6228,8 Code $24: full stop
B $6230,8 Code $25: copyright sign
B $6238,8 Code $26: space
B $6240,8 Code $27: percent sign

b $6248 Room shapes
D $6248 Three records of three bytes, one for each shape of room. Bits 3 to 7 of
. byte 2 of a room record (#R$6251) pick one, and #R$D3F0 copies its three
. bytes into variables: byte 0 is half the room's width along x, to $5BAB;
. byte 1 is half its depth along y, to $5BAC; byte 2 is the height of the
. floor, to $5BAE.
D $6248 Every room is centred on x = $80, y = $80, so shape 0 is a square room
. reaching from $40 to $C0 both ways, shape 1 is half as wide along x and
. shape 2 half as deep along y. The half sizes are what the movement code
. tests objects against to keep them inside the room (#R$C87A, and the exits
. at #R$CA9A onwards). The floor is at $80 in all three: the third byte is a
. height, not a size. Of the castle's 128 rooms, 70 are shape 0, 34 shape 1
. and 24 shape 2.
B $6248,3 Shape 0: square, $40 either side of the centre both ways; floor at $80
B $624B,3 Shape 1: narrow in x ($20 either side), full depth in y; floor at $80
B $624E,3 Shape 2: full width in x, narrow in y ($20 either side); floor at $80

b $6251 The rooms
D $6251 Every room in the castle: 128 records of varying length packed end to end,
. the last ending where #R$6BD1 begins. There is no index and no terminator.
. #R$D3CF finds a room by walking the records from the start, comparing each
. room number with the player's; byte 1 of a record is the distance from
. itself to the next record, and the walk gives up when it reaches the address
. of #R$6BD1.
D $6251 Byte 0 is the room number. The castle is a grid of 16 by 16 squares, and the
. number is the square's row times 16 plus its column: walking out through the
. east or west side adds or subtracts 1 in the low four bits only, and north
. or south adds or subtracts 16 (#R$CA9A to #R$CB29). Only 128 of the 256
. squares are rooms. Byte 1 is the record's length less one. Byte 2 holds the
. room's ink colour in bits 0 to 2 -- magenta, green, cyan or yellow -- which
. #R$D3F0 makes into bright ink on black paper at $5BAD, and its shape in bits
. 3 to 7, an index into #R$6248.
D $6251 Next come the room's backgrounds, one byte each, indexes into #R$6CE2:
. walls, arches, doorways and the other fixed scenery. A byte of $FF ends
. them. A room with nothing more in it has no $FF and simply ends; 24 rooms
. are like that.
D $6251 After the $FF come groups of objects. A group begins with a byte whose bits
. 3 to 7 are an index into #R$6BD1 and whose bits 0 to 2 are the number of
. copies less one, and carries one position byte per copy. A position byte
. names a cell in the room's grid of 8 by 8 cells on four levels: bits 0 to 2
. the x cell, bits 3 to 5 the y cell and bits 6 and 7 the level. #R$D46C turns
. it into coordinates: x is $48 plus 16 times the x cell, y likewise, and z is
. the floor height plus 12 times the level, to which the block type can add
. half a cell in x or y and extra height.
D $6251 #R$D3C6 builds the room as object records, 32 bytes each, from $5C88
. upwards, and clears whatever is left up to #R$6108. That is room for 36
. objects, and six rooms in this table need exactly 36.
E $6251 The comments give each record's room number, its square in the grid (row,
. column), its shape and colour, then what it contains. Where the listing's
. rows do not line up with the records, a comment covers the parts that begin
. in its row.

b $6BD1 Block types
D $6BD1 29 addresses, one for each kind of object a room record can place: bits 3 to
. 7 of a group byte in #R$6251, doubled, index this table (#R$D452). Each
. address points at a list of 6-byte parts ended by a 0 byte, laid out as
. described at #R$6C0B. Most kinds are one part; the two guards are two.
D $6BD1 The table is not in address order: the records it points at are grouped by
. what they are (blocks, then fire and balls, then spikes and so on), while
. the index order is simply the order the kinds were numbered in.
W $6BD1,2 0: block
W $6BD3,2 1: fire
W $6BD5,2 2: ball (half a cell along y)
W $6BD7,2 3: rock
W $6BD9,2 4: gargoyle
W $6BDB,2 5: spikes
W $6BDD,2 6: chest
W $6BDF,2 7: table
W $6BE1,2 8: guard (type $96)
W $6BE3,2 9: ghost
W $6BE5,2 10: fire (type $B5)
W $6BE7,2 11: raised block
W $6BE9,2 12: ball (half a cell along x and y)
W $6BEB,2 13: guard (type $1E)
W $6BED,2 14: block (type $36)
W $6BEF,2 15: block (type $37)
W $6BF1,2 16: block (type $3E)
W $6BF3,2 17: raised spikes
W $6BF5,2 18: spiked ball
W $6BF7,2 19: raised spiked ball
W $6BF9,2 20: fire (type $56)
W $6BFB,2 21: block (type $5B)
W $6BFD,2 22: block (type $8F)
W $6BFF,2 23: ball (type $B6)
W $6C01,2 24: ball
W $6C03,2 25: sparkle (type $A4)
W $6C05,2 26: portcullis along x
W $6C07,2 27: portcullis along y
W $6C09,2 28: ball (half a cell along x)

b $6C0B Block type 0: stone block
D $6C0B A block type is a list of parts, six bytes each, ended by a 0 byte. For
. every copy a room asks for, #R$D46C makes one object record from each part.
D $6C0B Byte 0 goes to +0, the object type -- which is also its sprite, through
. #R$7112, and its handler, through #R$B096. Bytes 1 to 4 go to +4 to +7: size
. along x, size along y, height, and flags. Byte 5 is not stored; it adjusts
. the position. Its bit 0 adds 8 to x, bit 1 adds 8 to y, and the rest, with
. bits 0 and 1 masked off, is added to z. The record's +8 gets the room number
. and bytes +9 to +31 are cleared.
D $6C0B Of the flags, bit 6 draws the sprite mirrored left to right and bit 7 draws
. it upside down (#R$D865); the other bits are the business of the object
. handlers.
D $6C0B This one is the plain stone block, type $07: 8 by 8 and 12 high, one cell of
. the grid, and the commonest thing in the castle.
B $6C0B,7,6,1 Type, size x, size y, height, flags, offset; then the end marker

b $6C12 Block type 11: stone block, raised
D $6C12 The same block with $30 added to its height, which lifts it four levels (12
. units each) above the level its position byte names. The raised spikes and
. the raised spiked ball do the same.
B $6C12,7,6,1 Type, size x, size y, height, flags, offset; then the end marker

b $6C19 Block type 14: stone block (type $36)
D $6C19 Type $36, a block with a handler of its own that moves it; the label
. (tcdev's) says east-west, and #R$6C20 is its north-south twin.
B $6C19,7,6,1 Type, size x, size y, height, flags, offset; then the end marker

b $6C20 Block type 15: stone block (type $37)
D $6C20 Type $37: the twin of #R$6C19, with a handler of its own.
B $6C20,7,6,1 Type, size x, size y, height, flags, offset; then the end marker

b $6C27 Block type 16: stone block (type $3E)
D $6C27 Type $3E, a block with a handler of its own; flags $14 rather than $10.
B $6C27,7,6,1 Type, size x, size y, height, flags, offset; then the end marker

b $6C2E Block type 21: stone block (type $5B)
D $6C2E Type $5B, a block with a handler of its own.
B $6C2E,7,6,1 Type, size x, size y, height, flags, offset; then the end marker

b $6C35 Block type 22: stone block (type $8F)
D $6C35 Type $8F. Its handler (#R$B6A2) turns it into sparkles (type $B8) when bit 3
. of its +13 is set, which is how the block collapses.
B $6C35,7,6,1 Type, size x, size y, height, flags, offset; then the end marker

b $6C3C Block type 1: fire (type $B0)
D $6C3C Type $B0 animates by stepping between $B0 and $B1, the two frames of
. #R$7926.
B $6C3C,7,6,1 Type, size x, size y, height, flags, offset; then the end marker

b $6C43 Block type 2: ball, half a cell along y
D $6C43 Byte 5 is 2, which moves the ball half a cell (8 units) along y from the
. centre of its cell. The four placements of type $B2 differ only in this
. byte; the label names are tcdev's.
B $6C43,7,6,1 Type, size x, size y, height, flags, offset; then the end marker

b $6C4A Block type 12: ball, half a cell along x and y
D $6C4A Byte 5 is 3: half a cell along both x and y.
B $6C4A,7,6,1 Type, size x, size y, height, flags, offset; then the end marker

b $6C51 Block type 24: ball
D $6C51 Byte 5 is 0: the ball sits in the centre of its cell.
B $6C51,7,6,1 Type, size x, size y, height, flags, offset; then the end marker

b $6C58 Block type 28: ball, half a cell along x
D $6C58 Byte 5 is 1: half a cell along x.
B $6C58,7,6,1 Type, size x, size y, height, flags, offset; then the end marker

b $6C5F Block type 23: ball (type $B6)
D $6C5F Type $B6: the same two sprites as the other balls under a different handler.
B $6C5F,7,6,1 Type, size x, size y, height, flags, offset; then the end marker

b $6C66 Block type 3: rock
D $6C66 Type $06.
B $6C66,7,6,1 Type, size x, size y, height, flags, offset; then the end marker

b $6C6D Block type 4: gargoyle
D $6C6D Type $16; its handler marks it deadly to touch.
B $6C6D,7,6,1 Type, size x, size y, height, flags, offset; then the end marker

b $6C74 Block type 5: spikes
D $6C74 Type $17, deadly to touch. Flags $50: drawn mirrored.
B $6C74,7,6,1 Type, size x, size y, height, flags, offset; then the end marker

b $6C7B Block type 17: spikes, raised
D $6C7B As #R$6C74, raised four levels.
B $6C7B,7,6,1 Type, size x, size y, height, flags, offset; then the end marker

b $6C82 Block type 18: spiked ball
D $6C82 Type $3F, whose handler drops it on the player.
B $6C82,7,6,1 Type, size x, size y, height, flags, offset; then the end marker

b $6C89 Block type 19: spiked ball, raised
D $6C89 As #R$6C82, raised four levels.
B $6C89,7,6,1 Type, size x, size y, height, flags, offset; then the end marker

b $6C90 Block type 6: chest
D $6C90 Type $55, 9 by 6.
B $6C90,7,6,1 Type, size x, size y, height, flags, offset; then the end marker

b $6C97 Block type 7: table
D $6C97 Type $54, 6 by 10.
B $6C97,7,6,1 Type, size x, size y, height, flags, offset; then the end marker

b $6C9E Block type 8: guard (type $96)
D $6C9E Two parts at the same place: type $96, the guard's body, 24 high, and type
. $90, its legs, 0 high with bit 1 of its flags set. The body's handler
. (#R$B73C) moves it along x and copies its x into the next object record, so
. the two parts must be laid out one after the other, which this list
. guarantees. Both parts are half a cell along y.
B $6C9E,13,6,6,1 Two parts (type, size x, size y, height, flags, offset), then the end marker

b $6CAB Block type 13: guard (type $1E)
D $6CAB Two parts at the same place: type $1E, the guard's body, and type $90, its
. legs. The body's handler (#R$B9A5) walks it in each of the four directions
. in turn and copies its x and y into the next record, for the legs.
B $6CAB,13,6,6,1 Two parts (type, size x, size y, height, flags, offset), then the end marker

b $6CB8 Block type 9: ghost
D $6CB8 Type $52, one of the ghost's four frames ($50 to $53).
B $6CB8,7,6,1 Type, size x, size y, height, flags, offset; then the end marker

b $6CBF Block type 10: fire (type $B5)
D $6CBF Type $B5; the label (tcdev's) says north-south, and its handler moves it
. along y.
B $6CBF,7,6,1 Type, size x, size y, height, flags, offset; then the end marker

b $6CC6 Block type 20: fire (type $56)
D $6CC6 Type $56; its handler moves it along x.
B $6CC6,7,6,1 Type, size x, size y, height, flags, offset; then the end marker

b $6CCD Block type 25: sparkle (type $A4)
D $6CCD Type $A4, 5 by 5: a sparkle. Type $A4 is also what the sparkle over the
. cauldron becomes when the player is the werewulf (#R$B8DA); the label is
. tcdev's name for it.
B $6CCD,7,6,1 Type, size x, size y, height, flags, offset; then the end marker

@ $6CD4 label=portcullis_along_x
b $6CD4 Block type 26: portcullis along x
D $6CD4 Type $08, the portcullis, 12 by 1 and 32 high. Byte 5 is 1: half a cell
. along x, which puts its middle on a cell boundary. Renamed from tcdev's
. gate_ud_1, a name that ended in a digit and did not say which way the gate
. lies.
B $6CD4,7,6,1 Type, size x, size y, height, flags, offset; then the end marker

@ $6CDB label=portcullis_along_y
b $6CDB Block type 27: portcullis along y
D $6CDB Type $08 lying the other way, 1 by 12; byte 5 is 2, half a cell along y.
. Renamed from tcdev's gate_ud_2.
B $6CDB,7,6,1 Type, size x, size y, height, flags, offset; then the end marker

b $6CE2 Backgrounds
D $6CE2 24 addresses, one for each background a room record can name. Each points at
. a list of 8-byte records ended by a 0 byte, and #R$D432 copies each record
. as it stands into bytes 0 to 7 of a new object record: type, x, y, z, size
. along x, size along y, height and flags. It sets +8 to the room number and
. clears the rest. Unlike a block type, a background carries its own
. coordinates, so it is always in the same place in a room.
D $6CE2 North is towards larger y and east towards larger x: the north arch stands
. at y = $C4, just beyond the far side of a full-depth room, and the east arch
. at x = $C4. Only the north and west sides have walls; the south and east
. sides are open towards the viewer.
W $6CE2,2 0: arch N
W $6CE4,2 1: arch E
W $6CE6,2 2: arch S
W $6CE8,2 3: arch W
W $6CEA,2 4: forest exit N
W $6CEC,2 5: forest exit E
W $6CEE,2 6: forest exit S
W $6CF0,2 7: forest exit W
W $6CF2,2 8: portcullis N
W $6CF4,2 9: portcullis E
W $6CF6,2 10: portcullis S
W $6CF8,2 11: portcullis W
W $6CFA,2 12: walls (square room)
W $6CFC,2 13: walls (room narrow in y)
W $6CFE,2 14: walls (room narrow in x)
W $6D00,2 15: forest walls
W $6D02,2 16: trees closing the W gap
W $6D04,2 17: trees closing the N gap
W $6D06,2 18: the wizard
W $6D08,2 19: the cauldron
W $6D0A,2 20: high arch E
W $6D0C,2 21: high arch S
W $6D0E,2 22: step to high arch E
W $6D10,2 23: step to high arch S

b $6D12 Background 0: arch in the north side
D $6D12 Two pieces, types $02 and $03 (#R$9ACA and #R$9C04), $0D either side of x =
. $80 at y = $C4, each 3 by 5 and 40 high. An arch is a gap between two
. pillars rather than a hole in a wall. The other arches are the same pair
. moved and turned; flags $50 draws them mirrored where the arch faces along
. x. Named by 63 rooms.

b $6D23 Background 1: arch in the east side
D $6D23 The pair of #R$6D12 turned to face along x, at x = $C4. Named by 40 rooms.

b $6D34 Background 20: high arch in the east side
D $6D34 As #R$6D23 but with its floor at $B0, 48 units up. Every room that has it
. also has #R$6FD0, the two blocks that make the step up to it. Named by 10
. rooms.

b $6D45 Background 2: arch in the south side
D $6D45 The pair of #R$6D12 at y = $3B. Named by 46 rooms.

b $6D56 Background 21: high arch in the south side
D $6D56 As #R$6D45 at z = $B0; always paired with #R$6FE1. Named by 16 rooms.

b $6D67 Background 3: arch in the west side
D $6D67 The pair of #R$6D23 at x = $3B. Named by 50 rooms.

b $6D78 Background 4: forest exit, north
D $6D78 The forest version of #R$6D12: two tree trunks, types $04 and $05 (#R$7FB0
. and #R$80A2), either side of the way out. Named by 13 rooms.

b $6D89 Background 5: forest exit, east
D $6D89 Two tree trunks either side of the east way out. Named by 17 rooms.

b $6D9A Background 6: forest exit, south
D $6D9A Two tree trunks either side of the south way out. Named by 14 rooms.

b $6DAB Background 7: forest exit, west
D $6DAB Two tree trunks either side of the west way out. Named by 17 rooms.

b $6DBC Background 8: portcullis in the north doorway
D $6DBC One piece, type $08, 12 by 1 and 32 high, at z = $A0: 32 units above a floor
. at $80, so it starts raised. Its handler, for type $08, is what lets it
. down. Named by 1 room.

b $6DC5 Background 9: portcullis in the east doorway
D $6DC5 The portcullis turned to lie along y, at x = $BE. Named by 2 rooms.

b $6DCE Background 10: portcullis in the south doorway
D $6DCE The portcullis at y = $41. Named by 1 room.

b $6DD7 Background 11: portcullis in the west doorway
D $6DD7 The portcullis along y at x = $41. Named by 2 rooms.

@ $6DE0 label=walls_square
b $6DE0 Background 12: walls of a square room
D $6DE0 Thirteen pieces along the west side (x = $3F) and the north side (y = $C0)
. of a room of shape 0. Types $0D and $0E are the columns where the two walls
. meet, $0F the wall ends, stacked two high, and $0A to $0C slabs of three
. lengths that fill the wall between them, leaving the gaps where arches go.
. Renamed from tcdev's wall_size_1: the three wall sets serve room shapes 0, 2
. and 1 in that order, so numbered names mislead. Named by 46 rooms.

@ $6E49 label=walls_narrow_y
b $6E49 Background 13: walls of a room narrow in y
D $6E49 Fourteen pieces for a room of shape 2, only $20 deep either side of the
. centre, so the west wall runs from y = $63 to $98. Renamed from tcdev's
. wall_size_2. Named by 24 rooms.

@ $6EBA label=walls_narrow_x
b $6EBA Background 14: walls of a room narrow in x
D $6EBA Fourteen pieces for a room of shape 1, only $20 wide either side of the
. centre: its west wall stands at x = $5F. Renamed from tcdev's wall_size_3.
. Named by 34 rooms.

@ $6F2B label=tree_walls
b $6F2B Background 15: the trees round a forest room
D $6F2B Twelve trees, types $80, $81 and $82 in turn (#R$9700, #R$97C2 and #R$9884),
. six along the west side and six along the north, with a gap in the middle of
. each for a way out. Used by the 24 forest rooms, all of shape 0. Renamed
. from tcdev's tree_room_size_1: there is only one size. Named by 24 rooms.

b $6F8C Background 16: trees closing the west gap
D $6F8C Two trees, $80 and $81, at y = $78 and $88 on the west side. A forest room
. with no way out to the west names this to close the gap #R$6F2B leaves; it
. never appears with #R$6DAB. Named by 7 rooms.

b $6F9D Background 17: trees closing the north gap
D $6F9D The same for the north side: used by the forest rooms that have no #R$6D78.
. Named by 11 rooms.

b $6FAE Background 18: the wizard
D $6FAE Two pieces: type $9E, the wizard's body (#R$7A92), and type $90, legs, with
. bit 1 of its flags set, built as the guards are. Only room $88 has it. Named
. by 1 room.

b $6FBF Background 19: the cauldron
D $6FBF Two pieces: type $8D, the cauldron itself (#R$9D54), 10 by 10, and type $8E
. (#R$9E5E), with no size and bit 1 of its flags set. Only room $88 has it,
. beside the wizard. Named by 1 room.

b $6FD0 Background 22: step up to the high east arch
D $6FD0 Two stone blocks, type $07, at x = $C8, y = $78 and $88, z = $A4: the step
. below #R$6D34. Named by 10 rooms.

b $6FE1 Background 23: step up to the high south arch
D $6FE1 Two stone blocks at y = $38, z = $A4, below #R$6D56. Named by 16 rooms.

b $6FF2 Where the charms lie
D $6FF2 32 records of 9 bytes, each a place where a charm lies. In the game as
. loaded only bytes 1 to 4 are filled: x, y, z and room number. #R$C47E fills
. in the rest when a game starts. Byte 0 becomes the charm's type, $60 to $67,
. taken in turn, so the eight kinds go round the table in a fixed order and
. each lies in exactly four places; only the starting kind varies, from the
. seed at $5BA0 plus the refresh register. Bytes 5 to 8 get a copy of bytes 1
. to 4, and from then on they, not 1 to 4, say where the charm is now: x, y, z
. and room.
D $6FF2 On entering a room, #R$C525 makes an object record, from $5C48 upwards, for
. every entry whose type is not 0 and whose byte 8 is this room. It gives the
. object a size of 5 by 5 by 12 and flags $14, and stores the address of the
. entry itself at +16 and +17 of the record, so the object can find its entry
. again. On leaving, #R$C591 writes the object's type and position back into
. bytes 0 and 5 to 8, which is how a charm that has been carried and dropped
. stays where it was put. Picking a charm up, feeding it to the cauldron or
. losing it writes 0 to byte 0, which takes that entry out of the game
. (#R$C141, #R$C245, #R$BF37).
D $6FF2 This table only says where the charms lie. Which of them the wizard wants,
. and in what order, is the separate list at #R$C27D, which #R$B544 rotates at
. the start of a game.
D $6FF2 No room holds more than one entry, so the two object slots from $5C48 to
. $5C87 are always enough. The 32 rooms are all different, and all exist in
. #R$6251.

b $7112 Sprite for each object type
D $7112 188 addresses, one for each object type. The type is byte 0 of an object
. record, and #R$D6EF doubles it to index this table, just as #R$AFD5 indexes
. the handlers at #R$B096 with it. There is no separate frame number: an
. object animates by changing its own type, so an animation is a run of
. consecutive types, and a walk cycle is six types whose entries name four
. sprites in the order 1 2 3 4 3 2. The same sprite often serves several
. types, for things that look alike but behave differently.
D $7112 Several runs are laid out in parallel. Sabreman is two objects, legs ($10 to
. $15 and $18 to $1D) and head and shoulders ($20 to $2F); the upper half's
. type is the legs' type plus $10 (#R$CE22), except that now and then it is
. given the frame at $x6 or $x7 instead. Bit 3 of the type chooses between two
. sets of art for two views of him, and mirroring (bit 6 of the flags) gives
. the other two directions. By night the whole set moves up by $20, to the
. werewulf's types $30 to $4F (#R$D12A). The guards and the wizard stand on
. Sabreman's leg frames, under types $90 to $9D.
D $7112 Types $00 and $01 have the empty sprite at #R$728A, which is never drawn:
. $00 is an unused record and $01 one that is about to be removed.
W $7112,16 Types $00-$01 nothing; $02-$03 arch piece; $04-$05 tree trunk; $06 rock; $07 block
W $7122,16 Types $08-$09 portcullis; $0A-$0C wall slab; $0D-$0E wall column; $0F wall end
W $7132,16 Types $10-$15 Sabreman's legs; $16 gargoyle; $17 spikes
W $7142,16 Types $18-$1D Sabreman's legs; $1E-$1F guard's body
W $7152,16 Types $20-$27 Sabreman's head and shoulders
W $7162,16 Types $28-$2F Sabreman's head and shoulders
W $7172,16 Types $30-$35 werewulf's legs; $36-$37 block
W $7182,16 Types $38-$3D werewulf's legs; $3E block; $3F spiked ball
W $7192,16 Types $40-$47 werewulf's head and shoulders
W $71A2,16 Types $48-$4F werewulf's head and shoulders
W $71B2,16 Types $50-$53 ghost; $54 table; $55 chest; $56-$57 fire
W $71C2,16 Types $58 sun; $59 moon; $5A window end; $5B block; $5C-$5F transformation
W $71D2,16 Types $60-$66 charm; $67 extra-life charm
W $71E2,16 Types $68-$6E charm going into the cauldron; $6F sparkle
W $71F2,16 Types $70-$77 vanishing sparkle
W $7202,16 Types $78-$7F appearing sparkle
W $7212,16 Types $80-$82 tree; $83-$85 sparkle; $86-$87 panel scroll
W $7222,16 Types $88 panel scroll; $89 border corner; $8A border side; $8B border top; $8C lives icon; $8D cauldron; $8E cauldron's top; $8F block
W $7232,16 Types $90-$95 legs; $96-$97 guard's body
W $7242,16 Types $98-$9D legs; $9E-$9F wizard's body
W $7252,16 Types $A0-$A7 cauldron sparkle
W $7262,16 Types $A8-$AF wanted charm
W $7272,16 Types $B0-$B1 fire; $B2-$B3 ball; $B4-$B5 fire; $B6-$B7 ball
W $7282,8 Types $B8-$B9 sparkle; $BA window end; $BB sparkle

b $728A No sprite; the sprite format
D $728A Every sprite from here to #R$AE98 is two header bytes followed by its rows.
. Header byte 0 holds the width in bytes in bits 0 to 3; bit 6 is set while
. the rows are stored mirrored left to right and bit 7 while they are stored
. upside down. Header byte 1 is the height in rows. A row is a pair of bytes
. for each byte of width: a mask, then an image. #R$D718 clears the pixels
. behind where the mask has a bit set and then ORs in the image, so each pixel
. is transparent, black or ink. The rows run from the bottom of the sprite
. upwards, because y in the screen buffer runs up the screen (#R$D826 turns it
. the right way up).
D $728A Mirroring is done to the sprite itself. Before drawing, #R$D865 compares
. bits 6 and 7 of the header with bits 6 and 7 of the object's flags (+7);
. where they differ it reverses the rows, or the pairs in each row
. (bit-reversing each byte through #R$F100), in place, and toggles the header
. bit. So one set of pixels serves both ways round, and a snapshot catches
. each sprite in whichever way it was last drawn: of the 103, only #R$7B5A,
. the border corner, was caught upside down. The header bits are state, not
. part of the width.
D $728A This first one is empty: its width is 0, and #R$D6EF, seeing the 0, returns
. from its caller without drawing anything. Types $00 and $01 use it.
B $728A,2 Width 0, height 0

b $728C Sun and moon window, left end
D $728C #R$C3C3 draws the window in the status panel through which the sun and moon
. cross the sky, and prints this at its left end, at x = $B8. Type $5A.
B $728C,2 Width 3, height 31
B $728E,186,6 31 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $7348 Sun and moon window, right end
D $7348 The right-hand end of the window #R$C3C3 draws, at x = $D0. Type $BA.
B $7348,2 Width 3, height 31
B $734A,186,6 31 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $7404 Spikes
D $7404 A bed of spikes, deadly to touch (block types 5 and 17). Type $17.
B $7404,2 Width 4, height 28
B $7406,224,8 28 rows, bottom first; a mask byte then an image byte for each of the 4 columns

b $74E6 Spiked ball
D $74E6 The spiked ball that drops on the player (block types 18 and 19). Type $3F.
B $74E6,2 Width 4, height 25
B $74E8,200,8 25 rows, bottom first; a mask byte then an image byte for each of the 4 columns

b $75B0 Guard's body, second frame
D $75B0 The second of the two frames of a guard's body; see #R$763C. Types $1F, $97.
B $75B0,2 Width 3, height 23
B $75B2,138,6 23 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $763C Guard's body, first frame
D $763C A guard is two objects at the same place: a body of this sprite or #R$75B0,
. and legs that borrow Sabreman's leg frames (types $90 to $9D). Types $1E and
. $1F walk north, east, south and west in turn (block type 13), and $96 and
. $97 back and forth along x (block type 8). Types $1E, $96.
B $763C,2 Width 3, height 23
B $763E,138,6 23 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $76C8 Ball, first frame
D $76C8 The ball of block types 2, 12, 23, 24 and 28. Types $B2 and $B3 share one
. handler and $B6 and $B7 another. Types $B2, $B6.
B $76C8,2 Width 3, height 19
B $76CA,114,6 19 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $773C Ball, second frame
D $773C The ball's second frame; see #R$76C8. Types $B3, $B7.
B $773C,2 Width 3, height 18
B $773E,108,6 18 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $77AA Rock
D $77AA Block type 3. Type $06.
B $77AA,2 Width 4, height 29
B $77AC,232,8 29 rows, bottom first; a mask byte then an image byte for each of the 4 columns

b $7894 Gargoyle
D $7894 Block type 4; deadly to touch. Type $16.
B $7894,2 Width 3, height 24
B $7896,144,6 24 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $7926 Fire, first frame
D $7926 The flame of block types 1, 10 and 20: types $56 and $57 move along x, $B4
. and $B5 along y, and $B0 and $B1 stay put. Types $56, $B0, $B4.
B $7926,2 Width 2, height 15
B $7928,60,4 15 rows, bottom first; a mask byte then an image byte for each of the 2 columns

b $7964 Fire, second frame
D $7964 The flame's second frame; see #R$7926. Types $57, $B1, $B5.
B $7964,2 Width 2, height 16
B $7966,64,4 16 rows, bottom first; a mask byte then an image byte for each of the 2 columns

b $79A6 Wizard's body, second frame
D $79A6 The second frame of #R$7A92. Type $9F.
B $79A6,2 Width 3, height 39
B $79A8,234,6 39 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $7A92 Wizard's body, first frame
D $7A92 The wizard of room $88 (#R$6FAE), built like a guard: this body, type $9E or
. $9F, over legs of type $90. Type $9E.
B $7A92,2 Width 3, height 33
B $7A94,198,6 33 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $7B5A Screen border, corner
D $7B5A #R$D296 prints this at all four corners of the play area, with the flags
. listed at #R$D2CF asking for each corner mirrored or flipped as it needs.
. The last corner it prints is flipped upside down, which is why this is the
. one sprite whose header the snapshot catches with bit 7 set: its rows are
. stored upside down at the moment. Its width is 4. Type $89.
B $7B5A,2 Width 4, height 32 (bit 7 set: stored upside down just now)
B $7B5C,256,8 32 rows, bottom first; a mask byte then an image byte for each of the 4 columns

b $7C5C Screen border, one line of a side
D $7C5C #R$D296 repeats this one-row sprite 128 times, a line apart, up each side.
. Type $8A.
B $7C5C,2 Width 3, height 1
B $7C5E,6,6 1 row, bottom first; a mask byte then an image byte for each of the 3 columns

b $7C64 Screen border, one column of the top and bottom
D $7C64 #R$D296 repeats this 24 times, a byte apart, along the top and the bottom.
. Type $8B.
B $7C64,2 Width 1, height 24
B $7C66,48,2 24 rows, bottom first; a mask byte then an image byte

b $7C96 Status panel scroll, rolled end
D $7C96 #R$D255 draws the scroll round the status panel from three sprites, listed
. at #R$D27E; this is the tall rolled end, printed once plain and once
. mirrored. Type $87.
B $7C96,2 Width 2, height 64
B $7C98,256,4 64 rows, bottom first; a mask byte then an image byte for each of the 2 columns

b $7D98 Twelve unused bytes
D $7D98 Zeros between two sprites. Nothing in the code refers to them, and no entry
. in #R$7112 points here; they are the only bytes between #R$728A and #R$AF6C
. that are not part of a sprite.
B $7D98,12 Unused

b $7DA4 Status panel scroll, curl
D $7DA4 A curl of the scroll, printed by #R$D255 at each end. Type $88.
B $7DA4,2 Width 2, height 16
B $7DA6,64,4 16 rows, bottom first; a mask byte then an image byte for each of the 2 columns

b $7DE6 Status panel scroll, slanting edge
D $7DE6 An 8-row slanting line, printed five times in a row by #R$D255 to make each
. slanting edge of the scroll. Type $86.
B $7DE6,2 Width 2, height 8
B $7DE8,32,4 8 rows, bottom first; a mask byte then an image byte for each of the 2 columns

b $7E08 Stone block
D $7E08 One cell's worth of stone block, the most used sprite in the game: type $07
. is the plain block, and $36, $37, $3E, $5B and $8F are blocks with handlers
. of their own that move, drop or collapse (see #R$6BD1). The end-of-game
. animation turns the plain blocks into type $83 (#R$C2EE). Types $07, $36,
. $37, $3E, $5B, $8F.
B $7E08,2 Width 4, height 28
B $7E0A,224,8 28 rows, bottom first; a mask byte then an image byte for each of the 4 columns

b $7EEA Extra-life charm and lives icon
D $7EEA Type $67 is the eighth kind of charm (#R$6FF2), the one the wizard never
. asks for: touching it adds a life (#R$C1AB). #R$BC7A prints the same sprite,
. as type $8C, as the lives icon in the status panel. Type $AF is the shape
. the cauldron would show for it (#R$B8DA). Types $67, $8C, $AF.
B $7EEA,2 Width 2, height 17
B $7EEC,68,4 17 rows, bottom first; a mask byte then an image byte for each of the 2 columns

b $7F30 Charm, type $62
D $7F30 One of the seven charms the wizard asks for. By its outline (read from the
. pixels, not the code), a boot. It is type $6A as the charm travelling into
. the cauldron (#R$C1F1), and $AA when the cauldron shows it as the one wanted
. next (#R$B8DA). Types $62, $6A, $AA.
B $7F30,2 Width 3, height 21
B $7F32,126,6 21 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $7FB0 Tree trunk beside a forest exit, first
D $7FB0 Type $04, the first of the two trunks that flank a way out of a forest room
. (#R$6D78 to #R$6DAB). Type $04.
B $7FB0,2 Width 2, height 60
B $7FB2,240,4 60 rows, bottom first; a mask byte then an image byte for each of the 2 columns

b $80A2 Tree trunk beside a forest exit, second
D $80A2 Type $05, the second trunk. Type $05.
B $80A2,2 Width 2, height 48
B $80A4,192,4 48 rows, bottom first; a mask byte then an image byte for each of the 2 columns

b $8164 Sparkle, size 1 of 6
D $8164 One of six sizes of sparkle, smallest first, shared by every kind of
. appearing and vanishing. Types $70 to $77 run from big to small as something
. vanishes (#R$BF21 starts a death this way); $78 to $7F run from small to big
. as the player appears, at the start of a life or in a new room; the rest are
. the sparkles over the cauldron, of the end-of-game animation, of a
. collapsing block and of a charm that is lost. Types $77, $78.
B $8164,2 Width 3, height 20
B $8166,120,6 20 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $81DE Sparkle, size 2 of 6
D $81DE One of six sizes of sparkle, smallest first, shared by every kind of
. appearing and vanishing. Types $70 to $77 run from big to small as something
. vanishes (#R$BF21 starts a death this way); $78 to $7F run from small to big
. as the player appears, at the start of a life or in a new room; the rest are
. the sparkles over the cauldron, of the end-of-game animation, of a
. collapsing block and of a charm that is lost. Types $76, $79.
B $81DE,2 Width 3, height 21
B $81E0,126,6 21 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $825E Sparkle, size 3 of 6
D $825E One of six sizes of sparkle, smallest first, shared by every kind of
. appearing and vanishing. Types $70 to $77 run from big to small as something
. vanishes (#R$BF21 starts a death this way); $78 to $7F run from small to big
. as the player appears, at the start of a life or in a new room; the rest are
. the sparkles over the cauldron, of the end-of-game animation, of a
. collapsing block and of a charm that is lost. Types $75, $7A.
B $825E,2 Width 3, height 23
B $8260,138,6 23 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $82EA Sparkle, size 4 of 6
D $82EA One of six sizes of sparkle, smallest first, shared by every kind of
. appearing and vanishing. Types $70 to $77 run from big to small as something
. vanishes (#R$BF21 starts a death this way); $78 to $7F run from small to big
. as the player appears, at the start of a life or in a new room; the rest are
. the sparkles over the cauldron, of the end-of-game animation, of a
. collapsing block and of a charm that is lost. Types $74, $7B, $85, $A2, $A6.
B $82EA,2 Width 3, height 24
B $82EC,144,6 24 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $837C Sparkle, size 5 of 6
D $837C One of six sizes of sparkle, smallest first, shared by every kind of
. appearing and vanishing. Types $70 to $77 run from big to small as something
. vanishes (#R$BF21 starts a death this way); $78 to $7F run from small to big
. as the player appears, at the start of a life or in a new room; the rest are
. the sparkles over the cauldron, of the end-of-game animation, of a
. collapsing block and of a charm that is lost. Types $71, $73, $7C, $7E, $84,
. $A1, $A3, $A5, $A7, $B9.
B $837C,2 Width 3, height 24
B $837E,144,6 24 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $840E Sparkle, size 6 of 6
D $840E One of six sizes of sparkle, smallest first, shared by every kind of
. appearing and vanishing. Types $70 to $77 run from big to small as something
. vanishes (#R$BF21 starts a death this way); $78 to $7F run from small to big
. as the player appears, at the start of a life or in a new room; the rest are
. the sparkles over the cauldron, of the end-of-game animation, of a
. collapsing block and of a charm that is lost. Types $6F, $70, $72, $7D, $7F,
. $83, $A0, $A4, $B8, $BB.
B $840E,2 Width 3, height 24
B $8410,144,6 24 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $84A0 Charm, type $60
D $84A0 One of the seven charms the wizard asks for. By its outline (read from the
. pixels, not the code), a cut gem. It is type $68 as the charm travelling
. into the cauldron (#R$C1F1), and $A8 when the cauldron shows it as the one
. wanted next (#R$B8DA). Types $60, $68, $A8.
B $84A0,2 Width 3, height 19
B $84A2,114,6 19 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $8514 Charm, type $61
D $8514 One of the seven charms the wizard asks for. By its outline (read from the
. pixels, not the code), a round-bodied flask. It is type $69 as the charm
. travelling into the cauldron (#R$C1F1), and $A9 when the cauldron shows it
. as the one wanted next (#R$B8DA). Types $61, $69, $A9.
B $8514,2 Width 3, height 22
B $8516,132,6 22 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $859A Charm, type $63
D $859A One of the seven charms the wizard asks for. By its outline (read from the
. pixels, not the code), a goblet. It is type $6B as the charm travelling into
. the cauldron (#R$C1F1), and $AB when the cauldron shows it as the one wanted
. next (#R$B8DA). Types $63, $6B, $AB.
B $859A,2 Width 3, height 23
B $859C,138,6 23 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $8626 Charm, type $64
D $8626 One of the seven charms the wizard asks for. By its outline (read from the
. pixels, not the code), a cup with a handle. It is type $6C as the charm
. travelling into the cauldron (#R$C1F1), and $AC when the cauldron shows it
. as the one wanted next (#R$B8DA). Types $64, $6C, $AC.
B $8626,2 Width 3, height 18
B $8628,108,6 18 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $8694 Charm, type $65
D $8694 One of the seven charms the wizard asks for. By its outline (read from the
. pixels, not the code), a bottle. It is type $6D as the charm travelling into
. the cauldron (#R$C1F1), and $AD when the cauldron shows it as the one wanted
. next (#R$B8DA). Types $65, $6D, $AD.
B $8694,2 Width 3, height 24
B $8696,144,6 24 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $8726 Charm, type $66
D $8726 One of the seven charms the wizard asks for. By its outline (read from the
. pixels, not the code), a ball. It is type $6E as the charm travelling into
. the cauldron (#R$C1F1), and $AE when the cauldron shows it as the one wanted
. next (#R$B8DA). Types $66, $6E, $AE.
B $8726,2 Width 3, height 21
B $8728,126,6 21 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $87A6 Sun
D $87A6 Type $58. #R$C3FF changes the type between $58 and $59 as day turns to night
. and back. Type $58.
B $87A6,2 Width 2, height 16
B $87A8,64,4 16 rows, bottom first; a mask byte then an image byte for each of the 2 columns

b $87E8 Moon
D $87E8 Type $59; see #R$87A6. Type $59.
B $87E8,2 Width 2, height 16
B $87EA,64,4 16 rows, bottom first; a mask byte then an image byte for each of the 2 columns

b $882A Ghost, frame 1
D $882A The ghost of block type 9, four frames under types $50 to $53. Type $50.
B $882A,2 Width 3, height 20
B $882C,120,6 20 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $88A4 Ghost, frame 2
D $88A4 The ghost of block type 9, four frames under types $50 to $53. Type $51.
B $88A4,2 Width 3, height 19
B $88A6,114,6 19 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $8918 Ghost, frame 3
D $8918 The ghost of block type 9, four frames under types $50 to $53. Type $52.
B $8918,2 Width 3, height 20
B $891A,120,6 20 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $8992 Ghost, frame 4
D $8992 The ghost of block type 9, four frames under types $50 to $53. Type $53.
B $8992,2 Width 3, height 20
B $8994,120,6 20 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $8A0C Portcullis
D $8A0C Type $08, the portcullis of the doorways (#R$6DBC to #R$6DD7) and of block
. types 26 and 27; type $09 is the same thing while it moves. Types $08, $09.
B $8A0C,2 Width 3, height 42
B $8A0E,252,6 42 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $8B0A Chest
D $8B0A Block type 6. Type $55.
B $8B0A,2 Width 4, height 29
B $8B0C,232,8 29 rows, bottom first; a mask byte then an image byte for each of the 4 columns

b $8BF4 Table
D $8BF4 Block type 7. Type $54.
B $8BF4,2 Width 4, height 31
B $8BF6,248,8 31 rows, bottom first; a mask byte then an image byte for each of the 4 columns

b $8CEE Sabreman's head and shoulders, view A, frame 3
D $8CEE Sabreman's head and shoulders, types $20 to $2F, drawn 12 units above the
. legs. The type follows the legs' type plus $10 (#R$CE22); the two occasional
. frames, $x6 and $x7, are given instead now and then, at random, and held for
. eight frames. Types $22, $24.
B $8CEE,2 Width 3, height 24
B $8CF0,144,6 24 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $8D80 Sabreman's head and shoulders, view B, frame 2
D $8D80 Sabreman's head and shoulders, types $20 to $2F, drawn 12 units above the
. legs. The type follows the legs' type plus $10 (#R$CE22); the two occasional
. frames, $x6 and $x7, are given instead now and then, at random, and held for
. eight frames. Types $29, $2D.
B $8D80,2 Width 3, height 25
B $8D82,150,6 25 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $8E18 Sabreman's head and shoulders, view A, occasional frame
D $8E18 Sabreman's head and shoulders, types $20 to $2F, drawn 12 units above the
. legs. The type follows the legs' type plus $10 (#R$CE22); the two occasional
. frames, $x6 and $x7, are given instead now and then, at random, and held for
. eight frames. Type $26.
B $8E18,2 Width 3, height 25
B $8E1A,150,6 25 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $8EB0 Sabreman's head and shoulders, view A, frame 4
D $8EB0 Sabreman's head and shoulders, types $20 to $2F, drawn 12 units above the
. legs. The type follows the legs' type plus $10 (#R$CE22); the two occasional
. frames, $x6 and $x7, are given instead now and then, at random, and held for
. eight frames. Type $23.
B $8EB0,2 Width 3, height 24
B $8EB2,144,6 24 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $8F42 Sabreman's head and shoulders, view A, frame 1
D $8F42 Sabreman's head and shoulders, types $20 to $2F, drawn 12 units above the
. legs. The type follows the legs' type plus $10 (#R$CE22); the two occasional
. frames, $x6 and $x7, are given instead now and then, at random, and held for
. eight frames. Type $20.
B $8F42,2 Width 3, height 24
B $8F44,144,6 24 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $8FD4 Sabreman's head and shoulders, view A, frame 2
D $8FD4 Sabreman's head and shoulders, types $20 to $2F, drawn 12 units above the
. legs. The type follows the legs' type plus $10 (#R$CE22); the two occasional
. frames, $x6 and $x7, are given instead now and then, at random, and held for
. eight frames. Types $21, $25.
B $8FD4,2 Width 3, height 24
B $8FD6,144,6 24 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $9066 Sabreman's head and shoulders, view B, frame 1
D $9066 Sabreman's head and shoulders, types $20 to $2F, drawn 12 units above the
. legs. The type follows the legs' type plus $10 (#R$CE22); the two occasional
. frames, $x6 and $x7, are given instead now and then, at random, and held for
. eight frames. Type $28.
B $9066,2 Width 3, height 25
B $9068,150,6 25 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $90FE Sabreman's head and shoulders, view B, frame 4
D $90FE Sabreman's head and shoulders, types $20 to $2F, drawn 12 units above the
. legs. The type follows the legs' type plus $10 (#R$CE22); the two occasional
. frames, $x6 and $x7, are given instead now and then, at random, and held for
. eight frames. Type $2B.
B $90FE,2 Width 3, height 25
B $9100,150,6 25 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $9196 Sabreman's head and shoulders, view B, frame 3
D $9196 Sabreman's head and shoulders, types $20 to $2F, drawn 12 units above the
. legs. The type follows the legs' type plus $10 (#R$CE22); the two occasional
. frames, $x6 and $x7, are given instead now and then, at random, and held for
. eight frames. Types $2A, $2C.
B $9196,2 Width 3, height 25
B $9198,150,6 25 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $922E Legs, view A, frame 1
D $922E Sabreman's legs by day, and the legs of the guards and the wizard (types $90
. to $9D). A walk plays frames 1 2 3 4 3 2: #R$C97F steps the low three bits
. of the type round 0 to 5. View A is the types with bit 3 clear, view B those
. with it set. Types $10, $90.
B $922E,2 Width 3, height 16
B $9230,96,6 16 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $9290 Legs, view A, frame 2
D $9290 Sabreman's legs by day, and the legs of the guards and the wizard (types $90
. to $9D). A walk plays frames 1 2 3 4 3 2: #R$C97F steps the low three bits
. of the type round 0 to 5. View A is the types with bit 3 clear, view B those
. with it set. Types $11, $15, $91, $95.
B $9290,2 Width 3, height 16
B $9292,96,6 16 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $92F2 Legs, view A, frame 3
D $92F2 Sabreman's legs by day, and the legs of the guards and the wizard (types $90
. to $9D). A walk plays frames 1 2 3 4 3 2: #R$C97F steps the low three bits
. of the type round 0 to 5. View A is the types with bit 3 clear, view B those
. with it set. Types $12, $14, $92, $94.
B $92F2,2 Width 3, height 16
B $92F4,96,6 16 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $9354 Legs, view A, frame 4
D $9354 Sabreman's legs by day, and the legs of the guards and the wizard (types $90
. to $9D). A walk plays frames 1 2 3 4 3 2: #R$C97F steps the low three bits
. of the type round 0 to 5. View A is the types with bit 3 clear, view B those
. with it set. Types $13, $93.
B $9354,2 Width 3, height 16
B $9356,96,6 16 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $93B6 Legs, view B, frame 1
D $93B6 Sabreman's legs by day, and the legs of the guards and the wizard (types $90
. to $9D). A walk plays frames 1 2 3 4 3 2: #R$C97F steps the low three bits
. of the type round 0 to 5. View A is the types with bit 3 clear, view B those
. with it set. Types $18, $98.
B $93B6,2 Width 3, height 16
B $93B8,96,6 16 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $9418 Legs, view B, frame 2
D $9418 Sabreman's legs by day, and the legs of the guards and the wizard (types $90
. to $9D). A walk plays frames 1 2 3 4 3 2: #R$C97F steps the low three bits
. of the type round 0 to 5. View A is the types with bit 3 clear, view B those
. with it set. Types $19, $1D, $99, $9D.
B $9418,2 Width 3, height 16
B $941A,96,6 16 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $947A Legs, view B, frame 3
D $947A Sabreman's legs by day, and the legs of the guards and the wizard (types $90
. to $9D). A walk plays frames 1 2 3 4 3 2: #R$C97F steps the low three bits
. of the type round 0 to 5. View A is the types with bit 3 clear, view B those
. with it set. Types $1A, $1C, $9A, $9C.
B $947A,2 Width 3, height 16
B $947C,96,6 16 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $94DC Legs, view B, frame 4
D $94DC Sabreman's legs by day, and the legs of the guards and the wizard (types $90
. to $9D). A walk plays frames 1 2 3 4 3 2: #R$C97F steps the low three bits
. of the type round 0 to 5. View A is the types with bit 3 clear, view B those
. with it set. Types $1B, $9B.
B $94DC,2 Width 3, height 16
B $94DE,96,6 16 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $953E Sabreman's head and shoulders, view A, second occasional frame
D $953E Sabreman's head and shoulders, types $20 to $2F, drawn 12 units above the
. legs. The type follows the legs' type plus $10 (#R$CE22); the two occasional
. frames, $x6 and $x7, are given instead now and then, at random, and held for
. eight frames. Type $27.
B $953E,2 Width 3, height 24
B $9540,144,6 24 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $95D0 Sabreman's head and shoulders, view B, second occasional frame
D $95D0 Sabreman's head and shoulders, types $20 to $2F, drawn 12 units above the
. legs. The type follows the legs' type plus $10 (#R$CE22); the two occasional
. frames, $x6 and $x7, are given instead now and then, at random, and held for
. eight frames. Type $2F.
B $95D0,2 Width 3, height 25
B $95D2,150,6 25 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $9668 Sabreman's head and shoulders, view B, occasional frame
D $9668 Sabreman's head and shoulders, types $20 to $2F, drawn 12 units above the
. legs. The type follows the legs' type plus $10 (#R$CE22); the two occasional
. frames, $x6 and $x7, are given instead now and then, at random, and held for
. eight frames. Type $2E.
B $9668,2 Width 3, height 25
B $966A,150,6 25 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $9700 Tree, first kind
D $9700 Type $80: one of the three trees that alternate round a forest room
. (#R$6F2B). Type $80.
B $9700,2 Width 2, height 48
B $9702,192,4 48 rows, bottom first; a mask byte then an image byte for each of the 2 columns

b $97C2 Tree, second kind
D $97C2 Type $81; see #R$9700. Type $81.
B $97C2,2 Width 2, height 48
B $97C4,192,4 48 rows, bottom first; a mask byte then an image byte for each of the 2 columns

b $9884 Tree, third kind
D $9884 Type $82; see #R$9700. Type $82.
B $9884,2 Width 2, height 48
B $9886,192,4 48 rows, bottom first; a mask byte then an image byte for each of the 2 columns

b $9946 Wall column, west wall
D $9946 Type $0D, a 48-row column of stone wall: in every wall set it stands at the
. north end of the west wall (#R$6DE0). Type $0D.
B $9946,2 Width 2, height 48
B $9948,192,4 48 rows, bottom first; a mask byte then an image byte for each of the 2 columns

b $9A08 Wall column, north wall
D $9A08 Type $0E, the column at the west end of the north wall. Type $0E.
B $9A08,2 Width 2, height 48
B $9A0A,192,4 48 rows, bottom first; a mask byte then an image byte for each of the 2 columns

b $9ACA Arch, first piece
D $9ACA Type $02, the taller of the two pieces of an arch (#R$6D12), 52 rows. Type
. $02.
B $9ACA,2 Width 3, height 52
B $9ACC,312,6 52 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $9C04 Arch, second piece
D $9C04 Type $03, the other pillar of an arch. Type $03.
B $9C04,2 Width 2, height 35
B $9C06,140,4 35 rows, bottom first; a mask byte then an image byte for each of the 2 columns

b $9C92 Wall end
D $9C92 Type $0F, the column that ends a wall towards the viewer, stacked two high.
. Type $0F.
B $9C92,2 Width 2, height 48
B $9C94,192,4 48 rows, bottom first; a mask byte then an image byte for each of the 2 columns

b $9D54 Cauldron
D $9D54 Type $8D, the cauldron in the wizard's room (#R$6FBF). Type $8D.
B $9D54,2 Width 4, height 33
B $9D56,264,8 33 rows, bottom first; a mask byte then an image byte for each of the 4 columns

b $9E5E Cauldron's top
D $9E5E Type $8E, the second piece of the cauldron: a flat oval, 11 rows high. Type
. $8E.
B $9E5E,2 Width 4, height 11
B $9E60,88,8 11 rows, bottom first; a mask byte then an image byte for each of the 4 columns

b $9EB8 Wall slab, long
D $9EB8 Type $0A, the longest of the three slabs that fill a stone wall between its
. columns: 20 units long and 20 high. Type $0A.
B $9EB8,2 Width 5, height 25
B $9EBA,250,10 25 rows, bottom first; a mask byte then an image byte for each of the 5 columns

b $9FB4 Wall slab, medium
D $9FB4 Type $0B, 12 units long and 20 high. Type $0B.
B $9FB4,2 Width 3, height 24
B $9FB6,144,6 24 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $A046 Wall slab, short
D $A046 Type $0C, 12 units long and 12 high. Type $0C.
B $A046,2 Width 3, height 18
B $A048,108,6 18 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $A0B4 Werewulf's legs, view A, frame 1
D $A0B4 The werewulf's legs, the night-time form of Sabreman's (#R$922E onwards):
. types $30 to $3D, the day types plus $20. Type $30.
B $A0B4,2 Width 3, height 16
B $A0B6,96,6 16 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $A116 Werewulf's legs, view A, frame 2
D $A116 The werewulf's legs, the night-time form of Sabreman's (#R$922E onwards):
. types $30 to $3D, the day types plus $20. Types $31, $35.
B $A116,2 Width 3, height 16
B $A118,96,6 16 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $A178 Werewulf's legs, view A, frame 3
D $A178 The werewulf's legs, the night-time form of Sabreman's (#R$922E onwards):
. types $30 to $3D, the day types plus $20. Types $32, $34.
B $A178,2 Width 3, height 16
B $A17A,96,6 16 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $A1DA Werewulf's legs, view A, frame 4
D $A1DA The werewulf's legs, the night-time form of Sabreman's (#R$922E onwards):
. types $30 to $3D, the day types plus $20. Type $33.
B $A1DA,2 Width 3, height 16
B $A1DC,96,6 16 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $A23C Werewulf's legs, view B, frame 1
D $A23C The werewulf's legs, the night-time form of Sabreman's (#R$922E onwards):
. types $30 to $3D, the day types plus $20. Type $38.
B $A23C,2 Width 3, height 16
B $A23E,96,6 16 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $A29E Werewulf's legs, view B, frame 2
D $A29E The werewulf's legs, the night-time form of Sabreman's (#R$922E onwards):
. types $30 to $3D, the day types plus $20. Types $39, $3D.
B $A29E,2 Width 3, height 16
B $A2A0,96,6 16 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $A300 Werewulf's legs, view B, frame 3
D $A300 The werewulf's legs, the night-time form of Sabreman's (#R$922E onwards):
. types $30 to $3D, the day types plus $20. Types $3A, $3C.
B $A300,2 Width 3, height 16
B $A302,96,6 16 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $A362 Werewulf's legs, view B, frame 4
D $A362 The werewulf's legs, the night-time form of Sabreman's (#R$922E onwards):
. types $30 to $3D, the day types plus $20. Type $3B.
B $A362,2 Width 3, height 16
B $A364,96,6 16 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $A3C4 Werewulf's head and shoulders, view A, frame 1
D $A3C4 The werewulf's head and shoulders, types $40 to $4F: the night-time form of
. Sabreman's, drawn 12 units above the legs. Type $40.
B $A3C4,2 Width 3, height 29
B $A3C6,174,6 29 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $A474 Werewulf's head and shoulders, view A, frame 2
D $A474 The werewulf's head and shoulders, types $40 to $4F: the night-time form of
. Sabreman's, drawn 12 units above the legs. Types $41, $45.
B $A474,2 Width 3, height 29
B $A476,174,6 29 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $A524 Werewulf's head and shoulders, view A, frame 3
D $A524 The werewulf's head and shoulders, types $40 to $4F: the night-time form of
. Sabreman's, drawn 12 units above the legs. Types $42, $44.
B $A524,2 Width 3, height 29
B $A526,174,6 29 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $A5D4 Werewulf's head and shoulders, view A, frame 4
D $A5D4 The werewulf's head and shoulders, types $40 to $4F: the night-time form of
. Sabreman's, drawn 12 units above the legs. Type $43.
B $A5D4,2 Width 3, height 29
B $A5D6,174,6 29 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $A684 Werewulf's head and shoulders, view B, frame 4
D $A684 The werewulf's head and shoulders, types $40 to $4F: the night-time form of
. Sabreman's, drawn 12 units above the legs. Type $4B.
B $A684,2 Width 3, height 30
B $A686,180,6 30 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $A73A Werewulf's head and shoulders, view B, frame 3
D $A73A The werewulf's head and shoulders, types $40 to $4F: the night-time form of
. Sabreman's, drawn 12 units above the legs. Types $4A, $4C.
B $A73A,2 Width 3, height 30
B $A73C,180,6 30 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $A7F0 Werewulf's head and shoulders, view B, frame 2
D $A7F0 The werewulf's head and shoulders, types $40 to $4F: the night-time form of
. Sabreman's, drawn 12 units above the legs. Types $49, $4D.
B $A7F0,2 Width 3, height 30
B $A7F2,180,6 30 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $A8A6 Werewulf's head and shoulders, view B, frame 1
D $A8A6 The werewulf's head and shoulders, types $40 to $4F: the night-time form of
. Sabreman's, drawn 12 units above the legs. Type $48.
B $A8A6,2 Width 3, height 30
B $A8A8,180,6 30 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $A95C Werewulf's head and shoulders, view A, occasional frame
D $A95C The werewulf's head and shoulders, types $40 to $4F: the night-time form of
. Sabreman's, drawn 12 units above the legs. Type $46.
B $A95C,2 Width 3, height 29
B $A95E,174,6 29 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $AA0C Werewulf's head and shoulders, view A, second occasional frame
D $AA0C The werewulf's head and shoulders, types $40 to $4F: the night-time form of
. Sabreman's, drawn 12 units above the legs. Type $47.
B $AA0C,2 Width 3, height 29
B $AA0E,174,6 29 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $AABC Werewulf's head and shoulders, view B, occasional frame
D $AABC The werewulf's head and shoulders, types $40 to $4F: the night-time form of
. Sabreman's, drawn 12 units above the legs. Type $4E.
B $AABC,2 Width 3, height 30
B $AABE,180,6 30 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $AB72 Werewulf's head and shoulders, view B, second occasional frame
D $AB72 The werewulf's head and shoulders, types $40 to $4F: the night-time form of
. Sabreman's, drawn 12 units above the legs. Type $4F.
B $AB72,2 Width 3, height 30
B $AB74,180,6 30 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $AC28 Transformation, frame 1
D $AC28 When day turns to night or back, #R$C306 removes Sabreman's upper half and
. turns his legs into one of types $5C to $5F, chosen at random every fourth
. frame and never the same twice running (#R$C357), eight times over; then he
. comes back in his other form. Type $5C.
B $AC28,2 Width 3, height 32
B $AC2A,192,6 32 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $ACEA Transformation, frame 2
D $ACEA When day turns to night or back, #R$C306 removes Sabreman's upper half and
. turns his legs into one of types $5C to $5F, chosen at random every fourth
. frame and never the same twice running (#R$C357), eight times over; then he
. comes back in his other form. Type $5D.
B $ACEA,2 Width 3, height 33
B $ACEC,198,6 33 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $ADB2 Transformation, frame 3
D $ADB2 When day turns to night or back, #R$C306 removes Sabreman's upper half and
. turns his legs into one of types $5C to $5F, chosen at random every fourth
. frame and never the same twice running (#R$C357), eight times over; then he
. comes back in his other form. Type $5E.
B $ADB2,2 Width 3, height 38
B $ADB4,228,6 38 rows, bottom first; a mask byte then an image byte for each of the 3 columns

b $AE98 Transformation, frame 4
D $AE98 When day turns to night or back, #R$C306 removes Sabreman's upper half and
. turns his legs into one of types $5C to $5F, chosen at random every fourth
. frame and never the same twice running (#R$C357), eight times over; then he
. comes back in his other form. Type $5F.
B $AE98,2 Width 3, height 35
B $AE9A,210,6 35 rows, bottom first; a mask byte then an image byte for each of the 3 columns

# --------------------------------------------------------------------------
# Start-up, the main loop, object dispatch, sound
# --------------------------------------------------------------------------

# --------------------------------------------------------------------------
# Agent 2: $AF6C-$B5F6 -- starting up, the main loop, the object handlers
# table, the tunes and sound effects, and the object helpers.
# --------------------------------------------------------------------------

c $AF6C Cold start
D $AF6C Wipes the game's whole RAM -- $5BA0 to $6107, 1384 bytes -- and falls
. into #R$AF88. The one thing it keeps is the ROM's frame counter, which it
. reads before the wipe and writes back afterwards as the first random seed. A
. machine that has been switched on for a different length of time therefore
. gets a different castle.
D $AF6C The read has to come first for a second reason: FRAMES, at $5C78, lies
. inside the object table (it is byte 16 of object 3), so the wipe destroys it.
  $AF6C,6 $5BA0 to $6107: the variables and all 40 object records
  $AF72,4 FRAMES, the ROM's 50Hz counter, as the seed
  $AF76,4 clear them, and take the seed back
  $AF7A,3 put it back where the wipe cannot reach it
  $AF7D,2 and set up a game

c $AF7F Restart after a game
D $AF7F Clears from $5BA8 rather than $5BA0, which leaves $5BA0 to $5BA7 alone:
. the game seed, the frame counter, the random byte and the chosen control
. method. That is deliberate: the next game should carry on the random sequence
. rather than replay the last one, and should not ask again which keys you
. wanted. It falls into #R$AF88.
D $AF7F Reached by a jump from #R$BA87 once the game-over screen has been seen.
  $AF7F,9 $5BA8 to $6107

c $AF88 Set up and play
D $AF88 Builds the lookup tables, shows the menu, and then does the four
. things that make a game different from the last one: shuffles which objects
. the wizard will ask for, chooses a starting room, sets the sun and moon
. running, and places the special objects. Then it falls into #R$AFB7, which
. brings Sabreman on exactly as it does after a death.
D $AF88 Three of those choices come from the game seed at $5BA0, and two of
. them from the same two bits of it: bits 0 and 1 pick the starting room in
. #R$D1B1 and also how far #R$B544 rotates the wizard's list. So on the first
. game after loading, the starting room tells you the order the cauldron will
. ask in. The charms' placing adds the refresh register, so that one is not tied.
  $AF88,3 the tables at #R$F100 -- see #R$D69E
  $AF8B,4 no room has been played yet, so the first room entry has nothing to save back
  $AF8F,3 clear byte 12 of the player record saved at #R$D161
  $AF92,5 five lives; the first pass through #R$AFB7 takes one of them
  $AF97,8 stir the frame counter into the game seed; it is zero on the first game after loading
  $AF9F,3 clear the screen
  $AFA2,3 the control menu; the seed also goes up by one every time round its loop
  $AFA5,6 the tune that plays as the game starts
  $AFAB,3 rotate the list of objects the cauldron wants
  $AFAE,3 pick one of four starting rooms, and make the player records
  $AFB1,3 the sun starts at the left of its frame
  $AFB4,3 deal the charms and extra lives out to their places

c $AFB7 Start a life
D $AFB7 Reached at the start of a game and whenever both halves of Sabreman
. have gone from the object table. #R$D12A copies back the two player records
. that were saved when he entered the room, takes a life (ending the game when
. there are none), and makes him man or werewolf by whether it is day or night.
. The records come back as type 120, so he materialises where he came in.
  $AFB7,3 restore Sabreman and take a life

c $AFBA Enter a room
D $AFBA Builds the room Sabreman is in -- its walls and objects into the object
. table, and the flag that tells #R$B03F to redraw the whole screen -- then
. falls into #R$AFBD, which runs frames until something jumps out. Leaving
. a room comes back here from #R$CABA, so this is the loop over rooms and
. #R$AFBD the loop over frames.
  $AFBA,3 build the room's objects and clear the screen buffer

c $AFBD Walk the object table
D $AFBD The start of one frame. IX steps through 40 object records of 32 bytes
. each, from $5C08 up to #R$6108 -- the byte just below the font. The game
. deliberately puts its object table on top of the ROM's system variables: from
. $5BA0 upwards nothing the ROM keeps there is wanted, and Knight Lore does not
. call the ROM once it is running. LAST-K, at $5C08, is the first byte of
. object zero.
D $AFBD Objects 0 and 1 are Sabreman's legs and upper body, and objects 2 and 3
. the slots for the charms that lie in the current room. The rest are the
. room's walls, blocks and creatures in the order the room was built.
  $AFBD,6 $5BBC starts the frame at the frame counter's low byte and goes up by one for each object
  $AFC3,4 IX = the first object record

c $AFC7 Next object
D $AFC7 The stack is reloaded to $5BA0 for every object, so it grows downwards
. into the printer buffer below and nothing a handler leaves on it can leak
. into the next one. The loop pushes its own continuation, #R$AFE4, before
. dispatching, so an object handler ends with a plain RET -- and a handler can
. jump away mid-routine, to another handler or out to the game-over code,
. without tidying the stack.
D $AFC7 $5BBC counts up by one per object, so two objects of the same kind see
. opposite parities in the same frame; #R$B83F uses that to make neighbouring
. fires flicker out of step.
  $AFC7,3 reset the stack for this object
  $AFCA,4 this object's phase: the frame counter plus its place in the table
  $AFCE,4 push the return address the handler will RET to
  $AFD2,3 keep last frame's screen rectangle so the old image can be wiped

c $AFD5 Dispatch on object type
D $AFD5 Byte 0 of an object record is its type, which is also its sprite
. number. This looks the type up in #R$B096 and jumps to the handler. Handlers
. animate an object by changing this byte, so the same object passes through
. several types -- and several handlers -- as it moves.
  $AFD5,6 the type indexes the table of handlers

c $AFDB Jump through a table of addresses
R $AFDB L the index
R $AFDB BC the base of a table of words
D $AFDB Doubles the index, adds the base, loads the word there and jumps to
. it. The object dispatch uses it, and so do the other tables of routines:
. the finale sparks' directions at #R$B58B, the guards' patrol directions, the
. arch nudges and the player's movement.
  $AFDB,4 HL = base + 2 * index
  $AFDF,5 fetch the address and go

c $AFE4 One object done
D $AFE4 Every handler returns here. It stirs the refresh register into the
. random byte at $5BA5 -- so the sequence depends on how much work the frame
. did -- then advances IX by 32 and goes round again until it reaches the
. font, when the frame is finished.
  $AFE4,10 R changes with every instruction fetched
  $AFEE,5 32 bytes per object record
  $AFF3,3 HL = IX
  $AFF6,8 the end of the object table is the start of the font
  $AFFE,2 not there yet

@ $B000 label=end_of_frame
c $B000 End of frame
D $B000 Draws everything the object walk decided on and then burns whatever
. time is left, so the game runs at an even speed rather than at whatever speed
. the room happens to allow.
D $B000 The time is counted in units of drawing. The renderer counts at $5BBE
. every object it draws and every rectangle it wipes, and this waits for six
. units less that count. One unit of waiting is 1280 turns of a 26-cycle loop,
. about 33,300 T-states, just under half a 50Hz frame. So a room where fewer than six
. things change runs at the same speed as one where six do, and a room busier
. than that runs slower -- the delay can only pad, never take time back.
  $B000,7 the 16-bit frame counter
  $B007,9 stir it into the random byte, with whatever memory it happens to address
  $B010,5 a frame has been played: the next room entry saves the charms' places back
  $B015,3 SPACE pauses
  $B018,3 bubbles in the cauldron room
  $B01B,3 list the objects flagged to be drawn
  $B01E,3 wipe, draw in depth order into the buffer at #R$D8F3, and copy the changes to the screen
  $B021,7 during the finale, a tone pitched by the last spark's height
  $B028,7 six units, less what this frame already used
  $B02F,6 none left to wait

c $B035 Wait one unit
D $B035 1280 turns of the loop at #R$B038.
R $B035 B the number of units still to wait
  $B035,3 1280 turns of 26 T-states each

c $B038 Frame delay loop
D $B038 Counts HL down, then goes back to #R$B035 for another unit until B runs
. out.
  $B038,5 26 T-states a turn
  $B03D,2 the next unit

c $B03F Redraw the whole screen on entering a room
D $B03F Only on the first frame in a room, which #R$D1E6 flags at $5BB7. Every
. other frame draws only what changed; this one paints the room's colour over
. the whole screen, redraws the panel, the carried objects, the sun or moon
. and the counters, and then copies the whole buffer to the display.
  $B03F,6 not a new room: on to the next frame
  $B045,4 once only
  $B049,6 the whole attribute file in the room's colour
  $B04F,3 the three objects being carried
  $B052,9 the panel's colours and its artwork
  $B05B,7 the sun or moon in its frame
  $B062,12 the day, the days, the lives icon and the lives
  $B06E,3 the whole buffer to the display
  $B071,3 nothing drawn so far needs wiping

@ $B074 label=next_frame_or_die
c $B074 Next frame, or lose a life
D $B074 When both player records are empty -- they become empty when the death
. sparkles finish -- a life is lost; otherwise the next frame starts.
  $B074,4 the finale tone is set again each frame by the sparks
  $B078,16 objects 0 and 1 both gone? Then a life is lost; otherwise the next frame

c $B088 Clear every object's wipe flag
D $B088 Bit 5 of byte 7 marks an object whose old image must be wiped. After
. the whole screen has just been redrawn there is nothing to wipe.
  $B088,8 all 40 records, starting at byte 7 of object 0

@ $B090 label=clear_wipe_flag_loop
c $B090 Clear one wipe flag
  $B090,6 bit 5 of byte 7, then the next record

b $B096 Object handlers, indexed by type
D $B096 188 words, one per object type. The type byte of an object record is
. also its sprite number -- #R$7112 has one word per type in the same order --
. so one byte chooses both what an object does and what it looks like, and a
. handler animates its object by changing its type. #R$AFD5 jumps through this.
D $B096 Several types are drawn only in the status panel and never occupy the
. object table: the sun, the moon, the ends of their frame, the panel and border
. pieces and the lives icon. Their entries point at a bare RET or at a routine
. that only sets drawing offsets. Types 0 and 1 are not objects at all but the
. states of a free slot.
E $B096 Objects made of two records -- Sabreman, the guards and the wizard --
. keep the second at the next record up: a guard's upper body is followed by
. its legs, and its handler writes the legs' position and motion 32 bytes on.
. Sabreman is the other way round, legs first at object 0.
W $B096,2 Type 0: empty slot
W $B098,2 Type 1: an object that has just gone; it draws as nothing so its old image is wiped, and the renderer then frees the slot
W $B09A,2 Type 2: stone arch, the half that also nudges Sabreman into line with the doorway
W $B09C,2 Type 3: stone arch, the other half
W $B09E,2 Type 4: tree-room arch, the half that nudges Sabreman into the doorway
W $B0A0,2 Type 5: tree-room arch, the other half
W $B0A2,2 Type 6: rock, static
W $B0A4,2 Type 7: plain block, static; at the end of the game each one left in the room becomes type 131
W $B0A6,2 Type 8: portcullis at rest, deciding when to start moving (one moves at a time)
W $B0A8,2 Type 9: portcullis moving; it kills what it lands on and crashes when it reaches the floor
W $B0AA,2 Type 10: a piece of room wall, static
W $B0AC,2 Type 11: a piece of room wall, static
W $B0AE,2 Type 12: a piece of room wall, static
W $B0B0,2 Type 13: a piece of room wall, static
W $B0B2,2 Type 14: a piece of room wall, static
W $B0B4,2 Type 15: a piece of room wall, static
W $B0B6,2 Type 16: Sabreman's legs, human, walking frame 0, first pair of facings
W $B0B8,2 Type 17: Sabreman's legs, human, walking frame 1, first pair of facings
W $B0BA,2 Type 18: Sabreman's legs, human, walking frame 2, first pair of facings
W $B0BC,2 Type 19: Sabreman's legs, human, walking frame 3, first pair of facings
W $B0BE,2 Type 20: Sabreman's legs, human, walking frame 4, first pair of facings
W $B0C0,2 Type 21: Sabreman's legs, human, walking frame 5, first pair of facings
W $B0C2,2 Type 22: gargoyle, static and deadly
W $B0C4,2 Type 23: spikes, static and deadly
W $B0C6,2 Type 24: Sabreman's legs, human, walking frame 0, second pair of facings
W $B0C8,2 Type 25: Sabreman's legs, human, walking frame 1, second pair of facings
W $B0CA,2 Type 26: Sabreman's legs, human, walking frame 2, second pair of facings
W $B0CC,2 Type 27: Sabreman's legs, human, walking frame 3, second pair of facings
W $B0CE,2 Type 28: Sabreman's legs, human, walking frame 4, second pair of facings
W $B0D0,2 Type 29: Sabreman's legs, human, walking frame 5, second pair of facings
W $B0D2,2 Type 30: upper body of the guard that walks round the room, one frame per facing
W $B0D4,2 Type 31: upper body of the guard that walks round the room, one frame per facing
W $B0D6,2 Type 32: Sabreman's upper body, human, walking frame 0, first pair of facings
W $B0D8,2 Type 33: Sabreman's upper body, human, walking frame 1, first pair of facings
W $B0DA,2 Type 34: Sabreman's upper body, human, walking frame 2, first pair of facings
W $B0DC,2 Type 35: Sabreman's upper body, human, walking frame 3, first pair of facings
W $B0DE,2 Type 36: Sabreman's upper body, human, walking frame 4, first pair of facings
W $B0E0,2 Type 37: Sabreman's upper body, human, walking frame 5, first pair of facings
W $B0E2,2 Type 38: Sabreman's upper body, human, an occasional frame held for eight frames, first pair of facings
W $B0E4,2 Type 39: Sabreman's upper body, human, an occasional frame held for eight frames, first pair of facings
W $B0E6,2 Type 40: Sabreman's upper body, human, walking frame 0, second pair of facings
W $B0E8,2 Type 41: Sabreman's upper body, human, walking frame 1, second pair of facings
W $B0EA,2 Type 42: Sabreman's upper body, human, walking frame 2, second pair of facings
W $B0EC,2 Type 43: Sabreman's upper body, human, walking frame 3, second pair of facings
W $B0EE,2 Type 44: Sabreman's upper body, human, walking frame 4, second pair of facings
W $B0F0,2 Type 45: Sabreman's upper body, human, walking frame 5, second pair of facings
W $B0F2,2 Type 46: Sabreman's upper body, human, an occasional frame held for eight frames, second pair of facings
W $B0F4,2 Type 47: Sabreman's upper body, human, an occasional frame held for eight frames, second pair of facings
W $B0F6,2 Type 48: Sabreman's legs, werewolf, walking frame 0, first pair of facings
W $B0F8,2 Type 49: Sabreman's legs, werewolf, walking frame 1, first pair of facings
W $B0FA,2 Type 50: Sabreman's legs, werewolf, walking frame 2, first pair of facings
W $B0FC,2 Type 51: Sabreman's legs, werewolf, walking frame 3, first pair of facings
W $B0FE,2 Type 52: Sabreman's legs, werewolf, walking frame 4, first pair of facings
W $B100,2 Type 53: Sabreman's legs, werewolf, walking frame 5, first pair of facings
W $B102,2 Type 54: block that slides back and forth along X
W $B104,2 Type 55: block that slides back and forth along Y
W $B106,2 Type 56: Sabreman's legs, werewolf, walking frame 0, second pair of facings
W $B108,2 Type 57: Sabreman's legs, werewolf, walking frame 1, second pair of facings
W $B10A,2 Type 58: Sabreman's legs, werewolf, walking frame 2, second pair of facings
W $B10C,2 Type 59: Sabreman's legs, werewolf, walking frame 3, second pair of facings
W $B10E,2 Type 60: Sabreman's legs, werewolf, walking frame 4, second pair of facings
W $B110,2 Type 61: Sabreman's legs, werewolf, walking frame 5, second pair of facings
W $B112,2 Type 62: the block tcdev called movable: stops every frame, falls, and blips the speaker every frame
W $B114,2 Type 63: spiked ball that drops once, at random, one at a time; deadly
W $B116,2 Type 64: werewolf upper body, walking frame 0, first pair of facings
W $B118,2 Type 65: werewolf upper body, walking frame 1, first pair of facings
W $B11A,2 Type 66: werewolf upper body, walking frame 2, first pair of facings
W $B11C,2 Type 67: werewolf upper body, walking frame 3, first pair of facings
W $B11E,2 Type 68: werewolf upper body, walking frame 4, first pair of facings
W $B120,2 Type 69: werewolf upper body, walking frame 5, first pair of facings
W $B122,2 Type 70: werewolf upper body, an occasional frame, first pair of facings
W $B124,2 Type 71: werewolf upper body, an occasional frame, first pair of facings
W $B126,2 Type 72: werewolf upper body, walking frame 0, second pair of facings
W $B128,2 Type 73: werewolf upper body, walking frame 1, second pair of facings
W $B12A,2 Type 74: werewolf upper body, walking frame 2, second pair of facings
W $B12C,2 Type 75: werewolf upper body, walking frame 3, second pair of facings
W $B12E,2 Type 76: werewolf upper body, walking frame 4, second pair of facings
W $B130,2 Type 77: werewolf upper body, walking frame 5, second pair of facings
W $B132,2 Type 78: werewolf upper body, an occasional frame, second pair of facings
W $B134,2 Type 79: werewolf upper body, an occasional frame, second pair of facings
W $B136,2 Type 80: ghost, wandering at random; deadly (bit 1 facing, bit 0 flapping)
W $B138,2 Type 81: ghost, wandering at random; deadly (bit 1 facing, bit 0 flapping)
W $B13A,2 Type 82: ghost, wandering at random; deadly (bit 1 facing, bit 0 flapping)
W $B13C,2 Type 83: ghost, wandering at random; deadly (bit 1 facing, bit 0 flapping)
W $B13E,2 Type 84: table: falls, and stops after each push
W $B140,2 Type 85: chest: falls; unlike the table, its handler does not stop it after a push
W $B142,2 Type 86: flame that runs back and forth along X; deadly
W $B144,2 Type 87: flame that runs back and forth along X; deadly
W $B146,2 Type 88: the sun (drawn in the panel, never in the object table)
W $B148,2 Type 89: the moon (drawn in the panel, never in the object table)
W $B14A,2 Type 90: left end of the sun and moon frame (panel only)
W $B14C,2 Type 91: block that sinks while something stands on it
W $B14E,2 Type 92: Sabreman changing between man and werewolf
W $B150,2 Type 93: Sabreman changing between man and werewolf
W $B152,2 Type 94: Sabreman changing between man and werewolf
W $B154,2 Type 95: Sabreman changing between man and werewolf
W $B156,2 Type 96: charm 0 of the seven, lying in a room
W $B158,2 Type 97: charm 1 of the seven, lying in a room
W $B15A,2 Type 98: charm 2 of the seven, lying in a room
W $B15C,2 Type 99: charm 3 of the seven, lying in a room
W $B15E,2 Type 100: charm 4 of the seven, lying in a room
W $B160,2 Type 101: charm 5 of the seven, lying in a room
W $B162,2 Type 102: charm 6 of the seven, lying in a room
W $B164,2 Type 103: extra life, lying in a room
W $B166,2 Type 104: charm 0 dropped in the cauldron room, drifting to the cauldron
W $B168,2 Type 105: charm 1 dropped in the cauldron room, drifting to the cauldron
W $B16A,2 Type 106: charm 2 dropped in the cauldron room, drifting to the cauldron
W $B16C,2 Type 107: charm 3 dropped in the cauldron room, drifting to the cauldron
W $B16E,2 Type 108: charm 4 dropped in the cauldron room, drifting to the cauldron
W $B170,2 Type 109: charm 5 dropped in the cauldron room, drifting to the cauldron
W $B172,2 Type 110: charm 6 dropped in the cauldron room, drifting to the cauldron
W $B174,2 Type 111: extra life just collected; vanishes next frame
W $B176,2 Type 112: death sparkle, frame 0
W $B178,2 Type 113: death sparkle, frame 1
W $B17A,2 Type 114: death sparkle, frame 2
W $B17C,2 Type 115: death sparkle, frame 3
W $B17E,2 Type 116: death sparkle, frame 4
W $B180,2 Type 117: death sparkle, frame 5
W $B182,2 Type 118: death sparkle, frame 6
W $B184,2 Type 119: death sparkle, last frame; vanishes next frame
W $B186,2 Type 120: Sabreman materialising, frame 0
W $B188,2 Type 121: Sabreman materialising, frame 1
W $B18A,2 Type 122: Sabreman materialising, frame 2
W $B18C,2 Type 123: Sabreman materialising, frame 3
W $B18E,2 Type 124: Sabreman materialising, frame 4
W $B190,2 Type 125: Sabreman materialising, frame 5
W $B192,2 Type 126: Sabreman materialising, frame 6
W $B194,2 Type 127: Sabreman materialising, done: becomes the type saved at +16
W $B196,2 Type 128: tree-trunk piece of a tree room's walls, static
W $B198,2 Type 129: tree-trunk piece of a tree room's walls, static
W $B19A,2 Type 130: tree-trunk piece of a tree room's walls, static
W $B19C,2 Type 131: finale spark: rises circling the room, then homes on Sabreman and ends the game
W $B19E,2 Type 132: finale spark: rises circling the room, then homes on Sabreman and ends the game
W $B1A0,2 Type 133: finale spark: rises circling the room, then homes on Sabreman and ends the game
W $B1A2,2 Type 134: a piece of the status panel (panel only)
W $B1A4,2 Type 135: a piece of the status panel (panel only)
W $B1A6,2 Type 136: a piece of the status panel (panel only)
W $B1A8,2 Type 137: a corner of the screen border (panel only)
W $B1AA,2 Type 138: an edge of the screen border (panel only)
W $B1AC,2 Type 139: an edge of the screen border (panel only)
W $B1AE,2 Type 140: the lives icon (panel only)
W $B1B0,2 Type 141: the cauldron
W $B1B2,2 Type 142: the cauldron's second sprite, with no size of its own
W $B1B4,2 Type 143: block that crumbles away when stood on
W $B1B6,2 Type 144: legs of a guard or the wizard, walking frame 0, first pair of facings
W $B1B8,2 Type 145: legs of a guard or the wizard, walking frame 1, first pair of facings
W $B1BA,2 Type 146: legs of a guard or the wizard, walking frame 2, first pair of facings
W $B1BC,2 Type 147: legs of a guard or the wizard, walking frame 3, first pair of facings
W $B1BE,2 Type 148: legs of a guard or the wizard, walking frame 4, first pair of facings
W $B1C0,2 Type 149: legs of a guard or the wizard, walking frame 5, first pair of facings
W $B1C2,2 Type 150: upper body of the guard that walks back and forth along X, one frame per facing
W $B1C4,2 Type 151: upper body of the guard that walks back and forth along X, one frame per facing
W $B1C6,2 Type 152: legs of a guard or the wizard, walking frame 0, second pair of facings
W $B1C8,2 Type 153: legs of a guard or the wizard, walking frame 1, second pair of facings
W $B1CA,2 Type 154: legs of a guard or the wizard, walking frame 2, second pair of facings
W $B1CC,2 Type 155: legs of a guard or the wizard, walking frame 3, second pair of facings
W $B1CE,2 Type 156: legs of a guard or the wizard, walking frame 4, second pair of facings
W $B1D0,2 Type 157: legs of a guard or the wizard, walking frame 5, second pair of facings
W $B1D2,2 Type 158: the wizard's upper body, one frame per facing
W $B1D4,2 Type 159: the wizard's upper body, one frame per facing
W $B1D6,2 Type 160: bubbles rising from the cauldron
W $B1D8,2 Type 161: bubbles rising from the cauldron
W $B1DA,2 Type 162: bubbles rising from the cauldron
W $B1DC,2 Type 163: bubbles rising from the cauldron
W $B1DE,2 Type 164: repel spell, homing on Sabreman
W $B1E0,2 Type 165: repel spell, homing on Sabreman
W $B1E2,2 Type 166: repel spell, homing on Sabreman
W $B1E4,2 Type 167: repel spell, homing on Sabreman
W $B1E6,2 Type 168: picture of charm 0 over the cauldron, the one it wants next
W $B1E8,2 Type 169: picture of charm 1 over the cauldron, the one it wants next
W $B1EA,2 Type 170: picture of charm 2 over the cauldron, the one it wants next
W $B1EC,2 Type 171: picture of charm 3 over the cauldron, the one it wants next
W $B1EE,2 Type 172: picture of charm 4 over the cauldron, the one it wants next
W $B1F0,2 Type 173: picture of charm 5 over the cauldron, the one it wants next
W $B1F2,2 Type 174: picture of charm 6 over the cauldron, the one it wants next
W $B1F4,2 Type 175: would be the extra life over the cauldron; the code never makes it
W $B1F6,2 Type 176: flickering fire; deadly
W $B1F8,2 Type 177: flickering fire; deadly
W $B1FA,2 Type 178: ball bouncing up and down; deadly
W $B1FC,2 Type 179: ball bouncing up and down; deadly
W $B1FE,2 Type 180: flame that runs back and forth along Y; deadly
W $B200,2 Type 181: flame that runs back and forth along Y; deadly
W $B202,2 Type 182: ball that hops towards the werewolf and away from the man; deadly
W $B204,2 Type 183: ball that hops towards the werewolf and away from the man; deadly
W $B206,2 Type 184: crumbling block, vanishing
W $B208,2 Type 185: crumbling block, last frame: zeroes the byte its +16 points at, then vanishes
W $B20A,2 Type 186: right end of the sun and moon frame (panel only)
W $B20C,2 Type 187: a charm destroyed where it met another object: zeroes its record, then vanishes

b $B20E The tune played as a game starts
D $B20E Played in full by #R$AF88 once a control method has been chosen.
D $B20E A tune is a string of note bytes ended by $FF. The low six bits of a
. note are an index into #R$B332, with 0 meaning a rest; the top two bits are
. its length less one, so a note lasts one to four units of about 0.155
. seconds. The comments name each note by the step of the table's own scale
. it uses and give lengths over one unit as x2, x3 or x4.
  $B20E,8 G#3 x2, B3 x2, A#3 x2, D#3 x2, G#3, F#3, D#3, F#3
  $B216,2 G#3 x4, end

b $B218 The game-over tune
D $B218 Played by #R$BA87 under the game-over screen until a key is pressed.
. It fakes two voices by alternating a moving upper note with a held bass,
. one unit each. The format is described at #R$B20E.
  $B218,8 F5, F#3, A#4, F#3, F5, F#3, A#4, F#3
  $B220,8 D#5, G#3, A#4, G#3, D#5, G#3, A#4, G#3
  $B228,8 C#5, A#3, A#4, A#3, C#5, A#3, A#4, A#3
  $B230,8 C#5, A#3, A#4, A#3, C#5, A#3, A#4, A#3
  $B238,1 end

b $B239 The tune for completing the game
D $B239 Played in full by #R$BAAB under the closing message. The format is
. described at #R$B20E.
  $B239,8 A#3, C4, C#4, A#3, C4, C#4, D#4, C4
  $B241,8 C#4, D#4, F4, C#4, C4, C#4, D#4, C4
  $B249,8 A#3, C4, C#4, A#3, A3, A#3, C4, A3
  $B251,2 A#3 x3, end

b $B253 The menu tune
D $B253 Played under the control menu by #R$BD0C, once per visit to the menu
. and only until a key is pressed (see #R$B2B6). Like the game-over tune it
. alternates two lines, one unit per note. The format is described at
. #R$B20E.
  $B253,8 A#3, A#4, A#3, A#4, A#3, C#5, F5, A#3
  $B25B,8 A#4, A#3, A#4, A#3, C#5, A#3, F5, F3
  $B263,8 G#4, F3, G4, F3, F4, F3, F4, F3
  $B26B,8 G#4, F3, G4, F3, F4, F3, F4, F3
  $B273,8 F4, A#3, A#4, A#3, A#4, A#3, C#5, F5
  $B27B,8 A#3, A#4, A#3, A#4, A#3, C#5, A#3, F5
  $B283,8 F3, G#4, F3, G4, F3, F4, F3, F4
  $B28B,8 F3, G#4, F3, G4, F3, F4, F3, F4
  $B293,8 F3, F4, F#3, F5, F#3, F5, F#3, F5
  $B29B,8 F#3, F5, G#3, F5, G#3, F5, G#3, F5
  $B2A3,8 G#3, F5, A#3, F5, A#3, F5, A#3, F5
  $B2AB,8 A#3, F5, A#3, F5, A#3, F5, A#3, F5
  $B2B3,3 A#3, F5, end

c $B2B6 Play the menu tune once per visit
R $B2B6 DE the tune
D $B2B6 The menu loop calls this every time round. $5BD1 remembers that the
. tune has been played, so it plays only the first time; #R$AF7F clears the
. flag with the rest of the game's variables, so it plays again after the next
. game. Falls into #R$B2BE.
  $B2B6,6 played already?
  $B2BC,2 not again until the variables are next cleared

c $B2BE Play a tune until a key is pressed
R $B2BE DE the tune
D $B2BE Checks the keyboard before every note and stops at once if any key is
. down. Used for the menu and game-over tunes, which the player may want to
. skip.
  $B2BE,4 A=0 selects every half-row at once, so any key at all counts
  $B2C2,3 a key: stop

@ $B2C5 label=keypress_tune_note
c $B2C5 Play one note of a tune that a key can stop
  $B2C5,5 $FF ends the tune
  $B2CA,5 play the note, then look at the keyboard again

c $B2CF Play a tune
R $B2CF DE the tune
D $B2CF Plays the whole tune and returns. Nothing else happens while it
. plays: the sound is made by timing loops, so the tune has the machine to
. itself.
  $B2CF,5 $FF ends the tune
  $B2D4,5 play the note, and the next

c $B2D9 End of a tune
  $B2D9,1 DE is left pointing at the $FF

c $B2DA Play one note
R $B2DA A the note byte
R $B2DA DE the address of the note byte; on exit, the next one
D $B2DA Looks up the note's three bytes in #R$B332: two loop counts that set
. how long each half of a wave lasts, and how many waves make one unit. The
. length bits multiply the wave count by one to four. It then drives the
. speaker directly, off for one half-wave and on for the other, with the
. border held black.
D $B2DA The wave count in the table rises with the pitch, which keeps every
. unit close to 0.155 seconds whatever the note.
  $B2DA,4 index 0 is a rest
  $B2DE,11 HL = #R$B332 + 3 * index
  $B2E9,7 B and C time the half-wave; HL = the number of waves in one unit
  $B2F0,6 the top two bits: the length, one to four units
  $B2F6,3 DE = the waves in one unit, to add up

c $B2F9 Multiply the waves by the length
  $B2F9,6 HL = HL * A

@ $B2FF label=restore_tune_ptr
c $B2FF Restore the tune pointer
  $B2FF,1 the tune pointer back in DE

@ $B300 label=note_wave
c $B300 One wave
D $B300 Speaker off for one half, on for the other. Each half is the loop at
. #R$B304 or #R$B30F: B turns first, then 256 turns for each further count in
. C, at 13 T-states a turn.
  $B300,4 speaker off, border black

@ $B304 label=note_first_half
c $B304 First half-wave
  $B304,5 wait
  $B309,6 speaker on

@ $B30F label=note_second_half
c $B30F Second half-wave
  $B30F,5 wait
  $B314,6 until all the waves are done
  $B31A,2 on to the next note byte

c $B31C Rest
R $B31C DE the address of the note byte; on exit, the next one
D $B31C Silence for one to four units, each 17163 turns of a 26 T-state loop:
. about 0.127 seconds, a little shorter than a note's unit. None of the four
. tunes uses a rest.
  $B31C,8 the length, one to four units
  $B324,3 17163 turns per unit

@ $B327 label=rest_unit
c $B327 One unit of rest
  $B327,1 keep the count

@ $B328 label=rest_countdown
c $B328 Rest countdown
  $B328,5 26 T-states a turn
  $B32D,5 the next unit

b $B332 Note table
D $B332 61 rows of three bytes, indexed by the low six bits of a note: the
. first two are the B and C counts that time each half-wave in #R$B300, and
. the third is how many waves make one unit of length. Row 0 stands for a rest
. and is never read.
D $B332 The rows go up a semitone at a time for five octaves. The comments give
. each row's pitch as worked out from the loop timings at 3.5MHz, and the step
. of an equal-tempered scale it stands for -- G#1 at row 1, A4 (440Hz) at row
. 38. The timing drifts across the range: the low rows come out about a fifth
. of a semitone sharp and the top rows up to half a semitone flat. Part of the
. flatness at the top is the 101 T-states each wave spends outside its two
. waits, which weigh more as the waits get shorter; why the bottom is sharp
. has not been worked out. Row 18 is the one real fault, noted below.
  $B332,3 index 0 is a rest, so this row is never read
  $B335,3 1: about 52.6 Hz, G#1; 8 cycles
  $B338,3 2: about 55.7 Hz, A1; 9 cycles
  $B33B,3 3: about 59.0 Hz, A#1; 9 cycles
  $B33E,3 4: about 62.5 Hz, B1; 10 cycles
  $B341,3 5: about 66.2 Hz, C2; 10 cycles
  $B344,3 6: about 70.1 Hz, C#2; 11 cycles
  $B347,3 7: about 74.3 Hz, D2; 12 cycles
  $B34A,3 8: about 78.7 Hz, D#2; 12 cycles
  $B34D,3 9: about 83.4 Hz, E2; 13 cycles
  $B350,3 10: about 88.4 Hz, F2; 14 cycles
  $B353,3 11: about 93.6 Hz, F#2; 15 cycles
  $B356,3 12: about 99.1 Hz, G2; 15 cycles
  $B359,3 13: about 105 Hz, G#2; 16 cycles
  $B35C,3 14: about 111 Hz, A2; 17 cycles
  $B35F,3 15: about 118 Hz, A#2; 18 cycles
  $B362,3 16: about 125 Hz, B2; 19 cycles
  $B365,3 17: about 132 Hz, C3; 21 cycles
  $B368,3 18: the same pitch bytes as 17, so C#3 is missing -- probably a slip, since the cycle count carries on as for C#3; 22 cycles
  $B36B,3 19: about 148 Hz, D3; 23 cycles
  $B36E,3 20: about 157 Hz, D#3; 25 cycles
  $B371,3 21: about 166 Hz, E3; 26 cycles
  $B374,3 22: about 176 Hz, F3; 28 cycles
  $B377,3 23: about 187 Hz, F#3; 29 cycles
  $B37A,3 24: about 198 Hz, G3; 31 cycles
  $B37D,3 25: about 209 Hz, G#3; 33 cycles
  $B380,3 26: about 222 Hz, A3; 35 cycles
  $B383,3 27: about 235 Hz, A#3; 37 cycles
  $B386,3 28: about 248 Hz, B3; 39 cycles
  $B389,3 29: about 263 Hz, C4; 41 cycles
  $B38C,3 30: about 279 Hz, C#4; 44 cycles
  $B38F,3 31: about 296 Hz, D4; 46 cycles
  $B392,3 32: about 313 Hz, D#4; 49 cycles
  $B395,3 33: about 331 Hz, E4; 52 cycles
  $B398,3 34: about 350 Hz, F4; 55 cycles
  $B39B,3 35: about 371 Hz, F#4; 58 cycles
  $B39E,3 36: about 393 Hz, G4; 62 cycles
  $B3A1,3 37: about 415 Hz, G#4; 65 cycles
  $B3A4,3 38: about 440 Hz, A4; 69 cycles
  $B3A7,3 39: about 465 Hz, A#4; 73 cycles
  $B3AA,3 40: about 493 Hz, B4; 78 cycles
  $B3AD,3 41: about 523 Hz, C5; 82 cycles
  $B3B0,3 42: about 553 Hz, C#5; 87 cycles
  $B3B3,3 43: about 584 Hz, D5; 93 cycles
  $B3B6,3 44: about 619 Hz, D#5; 98 cycles
  $B3B9,3 45: about 656 Hz, E5; 104 cycles
  $B3BC,3 46: about 696 Hz, F5; 110 cycles
  $B3BF,3 47: about 734 Hz, F#5; 117 cycles
  $B3C2,3 48: about 777 Hz, G5; 123 cycles
  $B3C5,3 49: about 824 Hz, G#5; 131 cycles
  $B3C8,3 50: about 872 Hz, A5; 139 cycles
  $B3CB,3 51: about 920 Hz, A#5; 147 cycles
  $B3CE,3 52: about 973 Hz, B5; 156 cycles
  $B3D1,3 53: about 1033 Hz, C6; 165 cycles
  $B3D4,3 54: about 1091 Hz, C#6; 175 cycles
  $B3D7,3 55: about 1147 Hz, D6; 185 cycles
  $B3DA,3 56: about 1220 Hz, D#6; 196 cycles
  $B3DD,3 57: about 1290 Hz, E6; 208 cycles
  $B3E0,3 58: about 1355 Hz, F6; 220 cycles
  $B3E3,3 59: about 1442 Hz, F#6; 233 cycles
  $B3E6,3 60: about 1524 Hz, G6; 247 cycles

@ $B3E9 label=sound_movable_block
c $B3E9 Sound: the movable block's blip
R $B3E9 IX the object
D $B3E9 Four waves at one of eight pitches from #R$B3FB, chosen by the frame
. counter. Called by the type 62 handler every frame, so a room with one of
. these blocks has a quiet buzz under everything else.
  $B3E9,13 B = one of eight half-wave counts, by the frame counter
  $B3F6,5 four waves

@ $B3FB label=block_blip_pitches
b $B3FB Pitches for the movable block's blip
D $B3FB Eight half-wave counts for #R$B4E6, one per value of the frame
. counter's bottom three bits. The larger the count, the lower the note.

@ $B403 label=sound_sparkle
c $B403 Sound: sparkle
R $B403 IX the object; its type sets the length
D $B403 A burst of short blips whose pitches are read from the ROM at $1234,
. so the burst sounds random but is the same every time. The number of blips
. is the bottom five bits of the complemented type: fifteen for the first death
. sparkle (type 112), falling by one each frame as the sparkle runs down. Also
. used by #R$C2A5 as each wanted charm goes into the cauldron.
  $B403,7 E = the number of blips
  $B40A,3 pitches from the ROM

@ $B40D label=sparkle_blip
c $B40D One blip of the sparkle
  $B40D,3 the next ROM byte is the half-wave count
  $B410,5 two waves
  $B415,4 until E runs out

@ $B419 label=sound_materialise
c $B419 Sound: materialising
R $B419 IX the object, types 120 to 126
D $B419 A rising sweep, one wave per step from a low note upwards. The number
. of steps comes from the type, so each frame of the materialising sweep is
. longer than the last: 3, 7, 11 and so on up to 27 steps.
  $B419,10 C = the number of steps

@ $B423 label=materialise_sweep
c $B423 One step of the materialising sweep
  $B423,7 half-wave count 4 * C: shorter, so higher, as C falls
  $B42A,4 until C runs out

@ $B42E label=sound_thud
c $B42E Sound: thud
D $B42E Four low blips of three waves each, their pitches taken from the
. first four bytes of the ROM with the top two bits forced on so they are all
. long. Played when a bouncing ball lands or a moving flame turns.
  $B42E,5 pitches from the start of the ROM; four blips

@ $B433 label=thud_blip
c $B433 One blip of the thud
  $B433,10 three waves at the next ROM byte, made low
  $B43D,4 until E runs out

@ $B441 label=sound_jump
c $B441 Sound: jump
D $B441 A rising sweep of 32 single waves, played by #R$C948 as Sabreman
. leaves the ground.
  $B441,2 32 steps

@ $B443 label=jump_sweep
c $B443 One step of the jump sweep
D $B443 Five right-rotations are three left ones, so the half-wave count is
. 8 * C: shorter, so higher, as C falls. The very first step, with C = 32,
. wraps round to a count of 1.
  $B443,10 half-wave count 8 * C, one wave
  $B44D,4 until C runs out

@ $B451 label=sound_pitch_from_z
c $B451 Sound: a note pitched by height
R $B451 IX the object
D $B451 Six waves whose pitch rises with the object's height. Used for things
. that fall or rise: a sinking block, a dropping spiked ball, a bouncing ball,
. and Sabreman falling.
  $B451,3 A = Z

@ $B454 label=sound_pitch_from_a
c $B454 Sound: a note pitched by A
R $B454 A the value to turn into a pitch; the larger, the higher
D $B454 Six waves with a half-wave count of four times the complement of A
. (rotated, so the top two bits wrap round). #R$B000 calls this directly
. during the finale with the last spark's height.
  $B454,4 B = the half-wave count
  $B458,5 six waves

@ $B45D label=sound_pitch_from_x
c $B45D Sound: a note pitched by X
R $B45D IX the object
D $B45D For the things that move along X: the sliding block and the flame.
  $B45D,5 A = X

@ $B462 label=sound_pitch_from_y
c $B462 Sound: a note pitched by Y
R $B462 IX the object
D $B462 For the things that move along Y: the sliding block and the flame.
  $B462,5 A = Y

@ $B467 label=sound_pitch_from_xyz
c $B467 Sound: a note pitched by position
R $B467 IX the object
D $B467 The pitch follows the sum of X, Y and Z, so it changes whichever way the
. object moves. Used for charms, tables and chests on the move, ghosts
. turning, a portcullis rising, the repel spell, and anything that vanishes
. through the type 111 handler.
  $B467,11 A = X + Y + Z

@ $B472 label=sound_transform
c $B472 Sound: changing between man and werewolf
R $B472 IX the object, types 92 to 95
D $B472 A warble of 16 to 40 single waves, the number set by which of the four
. transformation frames is showing, each at a pitch scrambled from the step
. count with an XOR.
  $B472,11 C = 16, 24, 32 or 40 steps

@ $B47D label=transform_warble
c $B47D One step of the warble
  $B47D,8 half-wave count (C XOR $55) + C, one wave
  $B485,4 until C runs out

@ $B489 label=sound_portcullis_crash
c $B489 Sound: the portcullis lands
R $B489 IX the portcullis
D $B489 Sixteen blips of two waves each, their pitches read from somewhere in
. the first 8K -- the ROM -- chosen by the random byte and the frame counter,
. so each crash sounds different.
  $B489,12 HL = a random address below $2000; 16 blips

@ $B495 label=crash_blip
c $B495 One blip of the crash
  $B495,10 two waves at the next byte, less its top bit
  $B49F,4 until E runs out

c $B4A3 Sound: a plain beep of 16 waves
D $B4A3 Used when an object is picked up or dropped, when an extra life is
. collected, and when the control menu's choice changes.
  $B4A3,5 16 waves at half-wave count 128

c $B4A8 Sound: a plain beep of 24 waves
D $B4A8 The pause beep, as #R$D50E pauses and again as it lets go.
  $B4A8,5 24 waves at half-wave count 80

c $B4AD Sound: a guard's or the wizard's footstep
R $B4AD IX the legs object
D $B4AD Plays on every other frame of the walk cycle. It alternates between a
. fixed pitch and one set by the walker's height, by bit 1 of the complemented
. frame counter, which gives the tick-tock of two feet; the number of waves
. comes from X and Y. Sabreman's steps, #R$B4BB, use the frame counter
. uncomplemented, so his two pitches alternate the other way round.
  $B4AD,6 only on even walking frames
  $B4B3,8 a fixed pitch, and the frame counter, inverted

@ $B4BB label=sound_walk_step
c $B4BB Sound: Sabreman's footstep while walking
R $B4BB IX Sabreman's legs
D $B4BB Plays on every other frame of the walk cycle, then as #R$B4C1.
  $B4BB,6 only on even walking frames

@ $B4C1 label=sound_footstep
c $B4C1 Sound: Sabreman's footstep
R $B4C1 IX Sabreman's legs
D $B4C1 Called directly when he turns on the spot, and through #R$B4BB when he
. walks.
  $B4C1,5 a fixed pitch, and the frame counter

@ $B4C6 label=footstep_pitch
c $B4C6 Footstep pitch
D $B4C6 On alternate pairs of frames the pitch is replaced by one from the
. walker's height.
R $B4C6 A the frame counter, or its complement
R $B4C6 B the fixed half-wave count
  $B4C6,4 keep the fixed pitch
  $B4CA,7 or take half the complement of Z

@ $B4D1 label=footstep_length
c $B4D1 Footstep length
D $B4D1 The number of waves is (X/2 + (256-Y)/2)/16, which over the floor
. of a room comes to between 3 and 12: longer as X grows and shorter as Y
. grows. Falls into #R$B4E6.
  $B4D1,21 C = the number of waves

c $B4E6 Sound: C waves at one pitch
R $B4E6 B the half-wave count
R $B4E6 C the number of waves
D $B4E6 The common tail of most of the effects. #R$B4ED leaves B as it found
. it, so every wave has the same pitch.
  $B4E6,7 C waves

c $B4ED Sound: one wave
R $B4ED B the half-wave count, kept
D $B4ED Speaker bit on for B turns of a 13 T-state loop, then off for as long,
. with the border black throughout. A count of 128 comes out at about 1kHz.
  $B4ED,5 speaker on; keep B

@ $B4F2 label=speaker_on_wait
c $B4F2 First half of the wave
  $B4F2,7 wait, then speaker off

@ $B4F9 label=speaker_off_wait
c $B4F9 Second half of the wave
  $B4F9,4 wait, and give B back

c $B4FD Does this object overlap any other?
R $B4FD IX the object
R $B4FD F on exit: carry set if another object's box overlaps IX's where it stands
D $B4FD Tests IX against all 40 records with the per-axis tests at #R$CC9D,
. #R$CCB2 and #R$CCC7, with no offset on any axis. Empty slots are skipped, and
. so is any object with bit 1 of byte 7 set -- which is how IX avoids finding
. itself: it sets its own bit 1 for the duration. Only #R$C00E uses it, to see
. whether there is room above Sabreman's head for a dropped object.
E $B4FD The exit clears IX's bit 1 unconditionally, so an object that had the
. bit set before the call loses it. The only caller passes Sabreman's legs,
. which do not normally carry it.
  $B4FD,11 save the registers; IY walks all 40 records
  $B508,8 no offset on X, Y or Z; and IX out of its own way

@ $B510 label=overlap_test_obj
c $B510 Test one object for overlap
  $B510,5 an empty slot, or one that takes no part in collisions
  $B515,15 overlapping on X, Y and Z?

@ $B524 label=overlap_done
c $B524 Overlap found, or none
  $B524,10 restore, and let IX take part in collisions again; carry says which

@ $B52E label=overlap_next_obj
c $B52E Next object
  $B52E,7 the next record, until all 40 are done
  $B535,3 none overlap: carry clear

c $B538 Does this object take part in collisions?
R $B538 IY the object
R $B538 F on exit: Z if the slot is empty or bit 1 of byte 7 is set, NZ for an object things can collide with
D $B538 Bit 1 of byte 7 takes an object out of collision tests. Objects set it
. on themselves while they are being moved, and some keep it: Sabreman's upper
. half, the legs of the guards and the wizard, the cauldron bubbles and the
. finale sparks.
  $B538,5 empty?
  $B53D,7 or bit 1 of byte 7 set?

c $B544 Rotate the list of objects the cauldron wants
D $B544 The cauldron asks for fourteen objects in the order of the list at
. #R$C27D. This rotates that list left by 4 to 7 places, the number chosen by
. bits 0 and 1 of the game seed. The list itself never changes order, so
. every game asks for the same cycle of objects starting at a different point
. -- and since the list is in the game's code rather than its variables, the
. rotations add up from one game to the next.
  $B544,8 C = 4 to 7 rotations

@ $B54C label=rotate_wanted_once
c $B54C Rotate once
  $B54C,9 13 moves; E = the first entry

@ $B555 label=rotate_wanted_entry
c $B555 Move one entry down
  $B555,10 each entry down one place
  $B55F,3 the first entry goes on the end
  $B562,4 until done

c $B566 Handler: the finale sparks (types 131 to 133)
R $B566 IX the spark
D $B566 When the fourteenth object goes into the cauldron, #R$C2CC clears
. away objects 3 to 13 and turns every plain block from object 14 on into one
. of these. Below height $A4 a spark rises
. two a frame while moving four a frame round the middle of the room: which
. quarter of the room it is in picks a direction from #R$B58B, and each
. direction carries it into the next quarter round. Once it is high enough it
. flies at Sabreman instead, and when it comes within 6 of him on both X and Y
. the game ends -- through #R$BA22, which sees the finale flag at $5BC3 and
. shows the closing message.
D $B566 Every frame each spark takes a random one of the three frames, and
. leaves its height at $5BC5 for #R$B000 to turn into a tone.
  $B566,3 drawing offsets
  $B569,7 high enough: go for Sabreman
  $B570,4 dZ = 3; gravity takes one, so it rises two a frame
  $B574,17 L = which quarter: bit 1 from X, bit 0 from Y
  $B585,6 go and set that quarter's direction

b $B58B Finale spark directions, by quarter of the room
D $B58B Indexed by bit 7 of X times two plus bit 7 of Y. Each routine loads H
. with dY and L with dX, so the names read dY first: p4_m4 is dY +4, dX -4.
W $B58B,2 X low, Y low: dX -4, dY +4
W $B58D,2 X low, Y high: dX +4, dY +4
W $B58F,2 X high, Y low: dX -4, dY -4
W $B591,2 X high, Y high: dX +4, dY -4

c $B593 Spark direction: dX -4, dY +4
  $B593,3 H = dY, L = dX

c $B596 Store the spark's direction and pick a frame
R $B596 H dY
R $B596 L dX
  $B596,6 the new dX and dY
  $B59C,8 a random frame, 1 to 3

@ $B5A4 label=set_spark_frame
c $B5A4 Set the spark's frame
  $B5A4,5 type 131, 132 or 133

@ $B5A9 label=spark_tone_and_move
c $B5A9 Leave the spark's height for the finale tone
  $B5A9,6 read by #R$B000

c $B5AF Move under gravity and flag for redrawing
R $B5AF IX the object
D $B5AF Takes one off the object's dZ, moves it by dX, dY and dZ as far as the
. collision code allows, and marks it to be wiped and drawn. Also used by the
. sliding blocks and the movable block.
  $B5AF,3 gravity, collisions and the move
  $B5B2,3 wipe and redraw

c $B5B5 Spark direction: dX +4, dY +4
  $B5B5,5 H = dY, L = dX

c $B5BA Spark direction: dX -4, dY -4
  $B5BA,5 H = dY, L = dX

c $B5BF Spark direction: dX +4, dY -4
  $B5BF,5 H = dY, L = dX

@ $B5C4 label=spark_near_player
c $B5C4 Is the spark near Sabreman?
D $B5C4 Distance on X first; $5C09 and $5C0A are X and Y of object 0,
. Sabreman's legs.
  $B5C4,11 A = |Sabreman's X - the spark's X|

@ $B5CF label=spark_check_y
c $B5CF Near on X; and on Y?
  $B5CF,4 not within 6 on X: keep flying
  $B5D3,11 A = |Sabreman's Y - the spark's Y|

@ $B5DE label=spark_touch
c $B5DE Near on X; near on Y?
  $B5DE,5 within 6 on both: the game is complete

@ $B5E3 label=spark_home_in
c $B5E3 Fly at Sabreman
D $B5E3 Level flight at four a frame towards him on both axes. Bit 1 of byte 7
. takes the spark out of collisions, so it flies through whatever is in the
. way. It also sets bit 7 of byte 13, the flag that elsewhere makes an
. object kill whatever it lands on; with collisions off it seems to do nothing
. here.
  $B5E3,8 the killing flag, and out of collisions
  $B5EB,4 dZ = 1: after gravity, level
  $B5EF,6 dX and dY of 4 towards Sabreman
  $B5F5,2 tone, move and draw

# --------------------------------------------------------------------------
# Moving objects, guards and the wizard
# --------------------------------------------------------------------------

# --------------------------------------------------------------------------
# Part 3: $B5F7-$BA21 -- the keyboard port, and the handlers for the things
# that move on their own: blocks, spikes, spiked balls, fire, balls, guards,
# the wizard, the cauldron and its bubbles.
#
# Object record fields named below (offset from IX): +0 type, +1/+2/+3 X/Y/Z,
# +4/+5/+6 size, +7 drawing and collision flags, +8 room, +9/+10/+11 dX/dY/dZ,
# +12 what the last move bumped into, +13 per-type state, +18/+19 pixel
# offsets. See the notes for the bits.
# --------------------------------------------------------------------------

c $B5F7 Read one or more keyboard half-rows
D $B5F7 The IN does the selecting on its own: IN A,($FE) puts A on the top
. half of the address bus, so each 0 bit in A selects one half-row, and A=0
. reads all eight at once -- which is how the "press any key" waits call it.
. Callers also pass $7E, $99, $BD and so on to read several rows in one go.
. The CPL turns the Spectrum's active-low keys the right way up, and the AND
. keeps the five that mean anything.
D $B5F7 The OUT before it is not needed for the read. It writes A to port
. A*256+$FD, which nothing on a 48K Spectrum answers because address line 0 is
. high. A 128K machine's paging port would decode it whenever A has bit 7
. clear, and 0, $7E and $7F are all among the values callers pass.
R $B5F7 A the half-rows to select, a 0 bit for each
R $B5F7 A on exit, the five key bits, 1 for pressed
  $B5F7,2 not what selects the row: see above
  $B5F9,2 reads port A*256+$FE
  $B5FB,3 set bits now mean pressed keys; keep the five

c $B5FF Bouncing ball (types 182 and 183)
D $B5FF The ball_bounce block (#R$6C5F). Falls under gravity, and every time
. it lands it jumps again and picks a new heading: two units a frame along X
. or along Y, chosen at random, pointing towards the player if the player is
. Sabrewulf and away if he is Sabreman. It keeps that heading all the way
. through the air, however often a wall stops it. The frame flips between the
. two types every frame, and it kills on contact.
D $B5FF Which way "towards" means is decided by patching two JR instructions
. rather than by testing: see #R$B626.
  $B5FF,3 pixel offsets for the ball sprite
  $B602,7 keep dX and dY
  $B609,6 remember dZ from before the move, for the bounce sound
  $B60F,3 gravity, then move, clipped against the room and other objects
  $B612,7 put dX and dY back: the clipping may have cut them, but the ball keeps its heading until it bounces
  $B619,13 object 0's type is the player's legs: 16 to 29 for Sabreman gives $38 (JR C), anything else $30 (JR NC)

c $B626 Bouncing ball: set the chase direction and the bounce height
D $B626 Writes the opcode chosen in #R$B5FF into the two conditional jumps at
. #R$B65D and #R$B676. With JR C a ball flees the player; with JR NC it
. chases him.
D $B626 Then works out how hard it will bounce: a dZ of 4 in an
. even-numbered room, and 4 plus a random 0 to 3 in an odd-numbered one.
R $B626 A $30 or $38, the JR opcode
  $B626,6 patch both jumps
  $B62C,9 even room: bounce with dZ 4
  $B635,7 odd room: 4 to 7

c $B63C Bouncing ball: on landing, bounce
D $B63C Nothing changes while the ball is in the air. When the last move
. left it standing on something, dZ is set to the bounce value and a new
. heading is chosen in #R$B64F.
R $B63C A the bounce dZ
  $B63C,6 not on the ground: keep flying
  $B642,3 landed: jump
  $B645,10 thud only if it was falling, not if it was already resting

c $B64F Bouncing ball: choose X or Y and compare with the player
D $B64F Bit 0 of the refresh register is the coin toss. Heads, the new
. heading is along Y and is worked out here and at #R$B65D; tails, along X at
. #R$B66E.
  $B64F,6 R register bit 0: 0 goes along X
  $B655,8 carry if the player's Y is less than the ball's

c $B65D Bouncing ball: the patched jump for Y
D $B65D The JR here is rewritten every frame by #R$B626: JR NC to head
. towards the player, JR C to head away. Falling through negates the step.
  $B65D,2 JR NC or JR C, patched
  $B65F,2 step -2

c $B661 Bouncing ball: head along Y
R $B661 A the step, +2 or -2
  $B661,7 dY = A, dX = 0

c $B668 Bouncing ball: animate and draw
D $B668 Flips between types 182 and 183 and hands over to #R$B856, which
. makes the ball deadly and marks it to be wiped and redrawn.
  $B668,3 flip bit 0 of the type
  $B66B,3 deadly, wipe and draw

c $B66E Bouncing ball: compare X with the player
  $B66E,8 carry if the player's X is less than the ball's; A = 2

c $B676 Bouncing ball: the patched jump for X
D $B676 The same patched jump as #R$B65D, for the X axis.
  $B676,2 JR NC or JR C, patched
  $B678,2 step -2

c $B67A Bouncing ball: head along X
R $B67A A the step, +2 or -2
  $B67A,7 dX = A, dY = 0
  $B681,2 animate and draw

c $B683 Dropping block (type 91)
D $B683 The dropping_block (#R$6C2E). It sinks while something stands on
. it, one unit a frame, and stops when it lands on what is underneath. Bit 3
. of +13 is set by the collision code (#R$CB45) on whatever an object lands
. on, so it is the "someone is standing on me" flag; this handler clears it
. every frame, so the block stops sinking the moment the weight steps off.
  $B683,3 pixel offsets
  $B686,5 nothing on it: nothing to do, not even a redraw
  $B68B,4 clear the flag; a rider will set it again next frame
  $B68F,7 dZ = 0, which the DEC in the move makes -1
  $B696,9 grinding sound while it is still moving down

c $B69F Dropping block: draw
  $B69F,3 wipe and draw

c $B6A2 Collapsing block (type 143)
D $B6A2 The collapsing_block (#R$6C35). It sits still until something lands
. on it, then crumbles: it becomes type 184, which #R$BF2B steps on to 185
. with a sound, and type 185's handler (#R$BF37) makes it vanish the frame
. after. Rebuilding the room brings it back.
  $B6A2,3 pixel offsets
  $B6A5,5 wait for something to stand on it
  $B6AA,7 crumble

c $B6B1 Shuttling block, north-south (type 55)
D $B6B1 The block_ns block (#R$6C20). Sets up #R$B6BF to work on Y and dY.
  $B6B1,3 sound pitched by Y
  $B6B4,5 H = 2 (Y), L = 10 (dY)

c $B6B9 Shuttling block, east-west (type 54)
D $B6B9 The block_ew block (#R$6C19). Sets up #R$B6BF to work on X and dX.
  $B6B9,3 sound pitched by X
  $B6BC,3 H = 1 (X), L = 9 (dX)

c $B6BF Shuttling block: the common part
D $B6BF One routine serves both axes by patching the displacement bytes of
. two IX instructions: the read of the position at #R$B6DE and the write of
. the step at #R$B6EF.
D $B6BF The block follows the frame counter. Folding the counter at bit 4
. gives a triangle wave, 0 up to 15 and back down over 32 frames, and the
. block steps one unit a frame towards that position within a 16-unit span.
. Blocks in odd-numbered object records add 16 to the counter first, which
. puts them half a cycle out of step with their even-numbered neighbours: one
. is at the far end while the next is at the near one.
R $B6BF H the offset of the axis to follow, 1 (X) or 2 (Y)
R $B6BF L the offset of the delta to set, 9 (dX) or 10 (dY)
  $B6BF,8 patch the two displacements
  $B6C7,3 pixel offsets
  $B6CA,8 C = 16 if IX is an odd-numbered record, else 0
  $B6D2,9 frame counter plus C, folded when bit 4 is set

c $B6DB Shuttling block: the target
  $B6DB,3 C = where in its span the block should be, 0 to 15

c $B6DE Shuttling block: step towards the target
D $B6DE The first instruction's displacement is patched by #R$B6BF to read
. X or Y. Adding 8 is because a block built on a cell's centre line sits at 8
. past a multiple of 16, so this is its distance along its span.
  $B6DE,3 the position: IX+1 or IX+2, patched
  $B6E1,5 where in its span it is now; is that the target?
  $B6E6,3 yes: stand still this frame, but redraw
  $B6E9,6 no: +1 if short of it, -1 if past it

c $B6EF Shuttling block: move
D $B6EF The first instruction's displacement is patched by #R$B6BF to set
. dX or dY. dZ is set to 1 so that the DEC in the move leaves it at 0: the
. block floats rather than falling.
R $B6EF A the step, +1 or -1
  $B6EF,3 dX or dY, patched
  $B6F2,4 no gravity
  $B6F6,3 move, wipe and draw

c $B6F9 Walking legs (types 144 to 149 and 152 to 157)
D $B6F9 The lower half of a guard or of the wizard: the second record in the
. guard_ew (#R$6C9E), guard_square (#R$6CAB) and wizard (#R$6FAE) layouts. It
. is 6 pixels lower on the screen than the body it goes with (compare
. #R$C4DD with #R$C510), has no height and is not solid, and uses the same
. sprites as the player's own legs, types 16 to 29.
D $B6F9 The legs never move themselves: the body's handler, which runs just
. before, copies its X, Y and deltas into this record (at IX+33 onwards from
. its point of view). This handler only animates. Standing still, it does
. nothing at all. Walking, it plays a footstep, chooses one of two views --
. types 144-149 or 152-157, bit 3 of the type -- and whether to mirror it,
. from the direction of travel, and steps the six-frame walk cycle
. (#R$C97F).
D $B6F9 The direction test compares dX and dY as unsigned bytes, which works
. because only one of them is ever non-zero and a negative step is a large
. number. +X and -Y use the second view, -X and +Y the first; +Y and -Y are
. drawn mirrored.
  $B6F9,3 pixel offsets
  $B6FC,7 not moving: no step, no redraw
  $B703,3 footstep
  $B706,8 moving along Y?
  $B70E,4 moving -X?
  $B712,4 +X: second view

c $B716 Walking legs: unmirrored
  $B716,4 +X or -X: not mirrored

c $B71A Walking legs: animate and draw
  $B71A,3 next frame of the walk cycle
  $B71D,3 wipe and draw

c $B720 Walking legs: facing -X
  $B720,6 first view, not mirrored

c $B726 Walking legs: moving along Y
  $B726,6 moving +Y?
  $B72C,4 -Y: second view

c $B730 Walking legs: mirrored
  $B730,4 +Y or -Y: mirrored
  $B734,2 animate and draw

c $B736 Walking legs: facing +Y
  $B736,6 first view, mirrored

c $B73C Guard walking east-west (types 150 and 151)
D $B73C The body of a guard_ew guard (#R$6C9E). It walks two units a frame
. along X, turning round whenever the move leaves it blocked. Bit 0 of +13 is
. the direction, 1 for +X; the layout starts it at 0, heading -X. Its legs
. are the next record, and get its dX and X each frame; it never moves along
. Y, so their dY stays 0. Deadly to touch.
  $B73C,3 pixel offsets: 13 pixels above the legs
  $B73F,10 dX = +2 or -2 from bit 0 of +13

@ $B749 label=guard_ew_move
c $B749 Guard east-west: move and turn
R $B749 A dX
  $B749,6 set the guard's dX and its legs'
  $B74F,3 pick the frame and mirroring from the direction
  $B752,3 gravity and move
  $B755,14 blocked along X: turn round

@ $B763 label=guard_ew_legs
c $B763 Guard east-west: take the legs along
  $B763,6 the legs' X = the guard's X
  $B769,3 deadly, wipe and draw

c $B76C Choose a guard's or the wizard's frame from its direction
D $B76C The body's version of the facing logic in #R$B6F9. Bit 0 of the
. type chooses one of the two drawings -- 30 or 31, 150 or 151, 158 or 159 --
. and bit 6 of +7 mirrors it. +X and -Y set bit 0, -X and +Y clear it; +Y
. and -Y are mirrored. With both deltas 0 nothing changes, so a guard that
. stops keeps facing the way it was.
D $B76C The dX and dY comparison is unsigned, as in #R$B6F9.
  $B76C,7 not moving: leave it
  $B773,8 moving along Y?
  $B77B,4 moving -X?
  $B77F,4 +X: bit 0 set

c $B783 Guard or wizard: unmirrored
  $B783,5 not mirrored

c $B788 Guard or wizard: facing -X
  $B788,6 bit 0 clear, not mirrored

c $B78E Guard or wizard: moving along Y
  $B78E,6 moving +Y?
  $B794,4 -Y: bit 0 set

c $B798 Guard or wizard: mirrored
  $B798,5 mirrored

c $B79D Guard or wizard: facing +Y
  $B79D,6 bit 0 clear, mirrored

c $B7A3 Gargoyle (type 22)
D $B7A3 The gargoyle block (#R$6C6D). It never moves and is never redrawn
. on its own account; all its handler does is make it deadly and set its
. pixel offsets.
  $B7A3,3 deadly both ways
  $B7A6,3 pixel offsets, and return

c $B7A9 Spiked ball (type 63)
D $B7A9 The spike_ball_fall block (#R$6C82). Deadly to touch. It hangs
. where the room put it until it is let go, then falls under gravity to
. whatever is below and stays there.
D $B7A9 Only one spiked ball in a room falls at a time: $5BBF is set while
. one is on its way down, and a waiting ball lets go with a chance of 1 in 16
. each frame when it is clear. None falls at all while $5BC0 is non-zero.
. That byte is set on entering a room to bit 0 of the room number and is
. cleared when the player picks something up, so in odd-numbered rooms the
. balls wait until then.
  $B7A9,6 deadly both ways; pixel offsets
  $B7AF,5 held in this room
  $B7B4,6 already falling
  $B7BA,6 another ball is falling
  $B7C0,6 1 in 16: let go
  $B7C6,7 falling, and claim the one-at-a-time flag

c $B7CD Spiked ball: fall
  $B7CD,3 gravity and move
  $B7D0,9 landed? if not, a sound pitched by the height

c $B7D9 Spiked ball: draw
  $B7D9,3 wipe and draw

c $B7DC Spiked ball: landed
  $B7DC,4 no longer falling
  $B7E0,5 let the next ball go
  $B7E5,2 draw

c $B7E7 Spike (type 23)
D $B7E7 The spike and spike_high blocks (#R$6C74 and #R$6C7B). Like the
. gargoyle: never moves, deadly to touch.
  $B7E7,3 deadly both ways
  $B7EA,3 pixel offsets, and return

c $B7ED Fire moving east-west (types 86 and 87)
D $B7ED The fire_ew block (#R$6CC6). Two units a frame along X, turning
. round with a thud when blocked; bit 0 of +13 is the direction, 1 for +X.
. It floats, flickers between types 86 and 87 every frame, and kills on
. contact.
  $B7ED,7 pixel offsets; dZ = 1, which the move's DEC makes 0: no gravity
  $B7F4,10 dX = +2 or -2 from bit 0 of +13

c $B7FE Fire east-west: move
R $B7FE A dX
  $B7FE,6 set dX; a sound pitched by X
  $B804,3 move
  $B807,8 blocked along X? A = the direction bit to flip

c $B80F Fire moving north-south (types 180 and 181)
D $B80F The fire_ns block (#R$6CBF). The same as #R$B7ED along Y, with bit 1
. of +13 as the direction, 1 for +Y.
  $B80F,7 pixel offsets; no gravity
  $B816,10 dY = +2 or -2 from bit 1 of +13

c $B820 Fire north-south: move
R $B820 A dY
  $B820,6 set dY; a sound pitched by Y
  $B826,3 move
  $B829,6 blocked along Y? A = the direction bit to flip

c $B82F Fire: turn round if blocked
R $B82F A the direction bit in +13
R $B82F F Z clear if the move was blocked
  $B82F,2 not blocked
  $B831,9 turn round, with a thud

c $B83A Fire: flicker and draw
  $B83A,3 flip bit 0 of the type
  $B83D,2 deadly, wipe and draw

c $B83F Fire standing still (types 176 and 177)
D $B83F The fire block (#R$6C3C). It stays put and flickers: every other
. frame it flips between types 176 and 177 and, at random, mirrors itself.
D $B83F The every-other-frame test uses $5BBC, which the object loop sets to
. the frame counter and then increments before each object. Its bit 0
. therefore alternates from frame to frame and from one record to the next,
. so neighbouring fires take turns.
  $B83F,3 pixel offsets
  $B842,6 not this frame: no change, no redraw
  $B848,14 flip the mirroring bit if a random bit is set; flip the type

c $B856 Make an object deadly and mark it to be wiped and redrawn
D $B856 The usual ending for a hostile object's handler.
  $B856,3 bits 7 and 5 of +13
  $B859,3 bits 5 and 4 of +7

c $B85C Make an object deadly both ways
D $B85C Sets bits 7 and 5 of +13. The collision code (#R$CB45) passes bit 7
. of a moving object on to whatever it runs into, and bit 5 of an object on to
. whatever runs into it, as bit 6 -- the "has touched something deadly" flag
. the player's handler checks. With both set, it does not matter who moved.
  $B85C,8 +13 OR $A0

c $B865 Ball bouncing on the spot (types 178 and 179)
D $B865 The ball_ud blocks (#R$6C51 and its three shifted variants). The ball
. goes straight up and down: rising at two units a frame to a ceiling, then
. falling under gravity until it lands, which sends it up again with a thud.
. Bit 2 of +13 is set while it is rising. It flips between its two frames
. every frame and kills on contact.
D $B865 The ceiling is shared. $5BBD is cleared on entering a room, and the
. first ball to run sets it to 32 above its own height; every ball in the
. room then turns at that same height.
  $B865,3 pixel offsets
  $B868,6 ceiling already set
  $B86E,8 32 above this ball

c $B876 Ball bouncing on the spot: rise or fall
  $B876,3 flip the frame
  $B879,3 a sound pitched by the height
  $B87C,6 rising
  $B882,3 falling: gravity and move
  $B885,13 landed: go up, with a thud

c $B892 Ball bouncing on the spot: draw
  $B892,2 deadly, wipe and draw

c $B894 Ball bouncing on the spot: rise
D $B894 dZ is set to 3 every frame, so after the move's DEC it rises a
. steady two units. Once above the ceiling it is marked as falling, and
. gravity takes over from the next frame.
  $B894,7 up two units
  $B89B,14 above the ceiling? start falling

c $B8A9 Start the cauldron bubbles
D $B8A9 Called once a frame from #R$B000. In the wizard's room, room $88, it
. puts the bubbles into object record 3 if that record is empty and the game
. is not already won ($5BC3). Records 2 and 3 are where the special objects
. found in a room go; in this room the code that drops an object only
. considers record 2, which leaves 3 for the bubbles.
  $B8A9,6 not the wizard's room
  $B8AF,6 record 3 already in use
  $B8B5,5 the game has been won
  $B8BA,11 copy the bubbles' first 18 bytes in; IX = record 3
  $B8C5,3 set their pixel offsets, and return

b $B8C8 The cauldron bubbles' starting record
D $B8C8 The first 18 bytes of an object record, copied into record 3 by
. #R$B8A9; the rest of the record is already zero.
D $B8C8 The room byte is $B4, not the wizard's room $88. Nothing about the
. bubbles depends on it except the room tests in #R$B92C, which therefore
. treat bubbles that have turned hostile as being in some other room.
B $B8C8,8,8 type 160; X, Y and Z $80, in the cauldron; 5 by 5 by 12; +7 = $10, draw
B $B8D0,10,10 room $B4; no movement; +13 = $A0, deadly both ways

c $B8DA Cauldron bubbles (types 160 to 163)
D $B8DA The bubbles rise out of the cauldron, cycling through four frames,
. and they are not solid on the way up (bit 1 of +7 is set, so the collision
. code ignores them). At height $A0 they hover, and every fourth frame they
. are replaced by a picture of the next object the wizard wants -- type 168
. plus that object's number -- for one frame in every five: the picture, then
. 160, 161, 162 and 163, then the picture again.
D $B8DA If the player is Sabrewulf -- his legs are type 48 to 63 -- the bubbles
. turn hostile instead: they become types 164 to 167 (#R$B92C), solid, and
. still carry the deadly bits their starting record gave them.
D $B8DA They vanish while object record 2 is occupied, which is while an
. object has been dropped into the cauldron and is being taken. #R$B8A9 puts
. them back once the record is free again.
  $B8DA,3 pixel offsets
  $B8DD,7 an object is in the cauldron: vanish
  $B8E4,4 not solid
  $B8E8,6 move; next of four frames
  $B8EE,11 still below $A0: dZ = 2, so rise one unit
  $B8F9,4 at the top: dZ = 1, so hover
  $B8FD,9 the player is Sabrewulf
  $B906,7 only when the cycle comes back round to 160
  $B90D,9 show the object wanted: type 168 plus its number

c $B916 Cauldron bubbles: draw
  $B916,3 wipe and draw

c $B919 Cauldron bubbles: turn hostile
D $B919 Setting bit 2 of the type turns 160-163 into 164-167, and clearing
. bit 1 of +7 makes them solid, so they can now touch the player.
  $B919,8 types 164-167; solid
  $B921,2 draw

c $B923 The object the wizard wants, shown in the bubbles (types 168 to 175)
D $B923 Lasts one frame: goes straight back to the first bubble frame.
  $B923,7 pixel offsets; type 160
  $B92A,2 draw

c $B92C Chasing sparkles (types 164 to 167)
D $B92C The repel_spell block (#R$6CCD), and the cauldron bubbles once they
. have turned on Sabrewulf. They fly straight at the player, four units a
. frame along each of X and Y, cycling through four frames. They slow to one
. unit a frame while the player is in an archway (bit 0 of the player's +7,
. set by #R$C7DB), except in the wizard's room. Gravity still applies.
D $B92C In the wizard's room they vanish once the player is no longer either
. form of the knight -- object 0's type outside 16 to 79, as it is once he
. has died. Because the bubbles' record says room $B4 (#R$B8C8), in practice
. this test is only made for sparkles built into room $88 itself, if any are.
D $B92C Whether they do harm depends on +13: the bubbles' starting record
. makes them deadly, but a room's repel_spell record starts with +13 clear.
  $B92C,3 pixel offsets
  $B92F,7 in the wizard's room: always fast
  $B936,7 the player is not in an archway: fast
  $B93D,5 slow

c $B942 Chasing sparkles: fast
  $B942,3 four units a frame

c $B945 Chasing sparkles: chase
R $B945 BC the speed along Y (B) and X (C)
  $B945,3 aim at the player
  $B948,6 gravity and move; next of four frames
  $B94E,7 not the wizard's room: carry on
  $B955,9 the player's legs are still type 16 to 79: carry on

c $B95E Make an object vanish (type 111)
D $B95E Also reached from #R$B8DA, #R$BF3F and #R$C265. Type 1 has no
. handler; the renderer (#R$D704) wipes a type 1 object one last time and
. then sets its type to 0, freeing the record.
  $B95E,4 type 1

c $B962 Play a sound, then wipe and draw
  $B962,3 see #R$C232

c $B965 Point an object at the player
D $B965 Sets dX and dY to plus or minus the given speeds, each pointing from
. the object towards the player along its axis. The sign is taken from the
. difference, so it is right as long as the two are less than 128 apart.
. When they are level the object steps back the negative way, so a chaser
. jitters about the player rather than stopping on him.
R $B965 IX the object
R $B965 C the speed along X
R $B965 B the speed along Y
  $B965,7 own X minus the player's X
  $B96C,7 C if the player is further along X, else -C

c $B973 Point at the player: Y
R $B973 A the step along X
  $B973,6 dX; own Y
  $B979,8 minus the player's Y: B if the player is further along Y, else -B

c $B981 Point at the player: set dY
R $B981 A the step along Y
  $B981,4 dY

c $B985 Flip between an object's two frames
D $B985 Toggles bit 0 of the type. Used for the fires and the balls, whose
. two frames are a pair of types differing only in bit 0.
  $B985,5 type XOR 1

c $B98C Step an object through four frames
D $B98C Increments the low two bits of the type and leaves the rest alone,
. so 160 goes to 161, 162, 163 and back to 160.
  $B98C,12 type with its low two bits plus 1, modulo 4

c $B998 Store an object's type
R $B998 A the new type
  $B998,4 type

c $B99C The cauldron (type 141)
D $B99C The cauldron layout (#R$6FBF). It stands still; all its handler does
. is set its pixel offsets.
  $B99C,3 pixel offsets, and return

c $B99F The cauldron's top (type 142)
D $B99F The second record of the cauldron layout: a sprite with no size, drawn
. 24 pixels left of and 12 above its position. Never moves.
  $B99F,6 pixel offsets, and return

c $B9A5 Guard walking round the room, and the wizard (types 30, 31, 158 and 159)
D $B9A5 The body of a guard_square guard (#R$6CAB), and the wizard
. (#R$6FAE). Each frame it moves with the deltas it already has, then picks
. its next deltas from whether that move was blocked: it walks two units a
. frame in a straight line until it hits something, then turns a quarter and
. carries on. The turns always go the same way round, -X, +Y, +X, -Y, so it
. follows the walls of the room. It is deadly to touch.
D $B9A5 Its legs are the next record: they get its X, Y, dX and dY every
. frame.
  $B9A5,3 pixel offsets: 9 pixels above the legs
  $B9A8,3 gravity and move
  $B9AB,3 the next heading, in H (dY) and L (dX)
  $B9AE,12 set its deltas and the legs'
  $B9BA,12 the legs go where it went
  $B9C6,3 choose its frame and mirroring
  $B9C9,3 deadly, wipe and draw

c $B9CC Choose a walking guard's next heading
D $B9CC Bits 0 and 1 of +13 are the heading, and the handler for each is in
. #R$B9D8. Each one returns the deltas for carrying on the same way, or, if
. the last move was blocked along that heading's axis, the deltas for the
. next heading and a step on of the heading bits.
R $B9CC HL on exit, the new dY (H) and dX (L)
  $B9CC,12 jump on bits 0 and 1 of +13

b $B9D8 Walking guard's headings
D $B9D8 Four handlers indexed by the heading in bits 0 and 1 of +13, in the
. order they are walked: tcdev's names call -X west, +Y north, +X east and
. -Y south.
W $B9D8,2 0: heading -X
W $B9DA,2 1: heading +Y
W $B9DC,2 2: heading +X
W $B9DE,2 3: heading -Y

c $B9E0 Walking guard heading -X
  $B9E0,8 dX = -2; not blocked along X, keep going
  $B9E8,3 blocked: dY = +2, and turn

c $B9EB Walking guard: next heading
D $B9EB Adds 1 to bits 0 and 1 of +13, wrapping round, and leaves the other
. bits alone.
  $B9EB,15 heading + 1, modulo 4

c $B9FB Walking guard heading +Y
  $B9FB,8 dY = +2; not blocked along Y, keep going
  $BA03,5 blocked: dX = +2, and turn

c $BA08 Walking guard heading +X
  $BA08,8 dX = +2; not blocked along X, keep going
  $BA10,5 blocked: dY = -2, and turn

c $BA15 Walking guard heading -Y
  $BA15,8 dY = -2; not blocked along Y, keep going
  $BA1D,5 blocked: dX = -2, and turn

@ $B626 label=bounce_ball_set_sense
@ $B63C label=bounce_ball_on_landing
@ $B64F label=bounce_ball_pick_axis
@ $B65D label=bounce_ball_y_sense
@ $B661 label=bounce_ball_set_dy
@ $B668 label=bounce_ball_animate
@ $B66E label=bounce_ball_x_axis
@ $B676 label=bounce_ball_x_sense
@ $B67A label=bounce_ball_set_dx
@ $B69F label=drop_block_draw
@ $B6BF label=shuttle_block
@ $B6DB label=shuttle_block_target
@ $B6DE label=shuttle_block_step
@ $B6EF label=shuttle_block_move
@ $B716 label=legs_unmirrored
@ $B71A label=legs_animate_and_draw
@ $B720 label=legs_face_minus_x
@ $B726 label=legs_moving_in_y
@ $B730 label=legs_mirrored
@ $B736 label=legs_face_plus_y
@ $B783 label=guard_unmirrored
@ $B788 label=guard_face_minus_x
@ $B78E label=guard_moving_in_y
@ $B798 label=guard_mirrored
@ $B79D label=guard_face_plus_y
@ $B7DC label=spiked_ball_landed
@ $B7FE label=fire_ew_move
@ $B820 label=fire_ns_move
@ $B82F label=fire_turn_if_blocked
@ $B83A label=fire_flicker_and_draw
@ $B876 label=ud_ball_rise_or_fall
@ $B892 label=ud_ball_draw
@ $B916 label=bubbles_draw
@ $B919 label=bubbles_turn_hostile
@ $B942 label=chaser_speed_fast
@ $B945 label=chaser_chase
@ $B962 label=sound_wipe_and_draw
@ $B973 label=towards_plyr_y
@ $B981 label=towards_plyr_set_dy

# --------------------------------------------------------------------------
# Game over and complete, the panel, the menu, carrying, the cauldron
# --------------------------------------------------------------------------

# --------------------------------------------------------------------------
# Game over and game complete ($BA22-$BC65)
# --------------------------------------------------------------------------

c $BA22 Game over
D $BA22 The one way out of a game, whichever way it ended: #R$C419 comes here
. when the fortieth day begins, #R$D12A when the last life is lost, and
. #R$B566 when the final animation reaches the player after the fourteenth
. object has gone into the cauldron. The last case has set $5BC3, and the
. player sees the completion message at #R$BAAB before the same summary
. screen everyone else gets.
  $BA22,7 $5BC3 is non-zero only once the quest is complete

@ $BA29 label=game_over_summary
c $BA29 The game-over summary screen
D $BA29 Clears the screen and its buffer and writes the six-line summary --
. time taken, percentage of the quest completed, charms collected and an
. overall rating -- then fills in the numbers. The text goes into the buffer
. at #R$D8F3 while the attributes go straight to the screen, so nothing
. shows until #R$BA79 copies the buffer across.
D $BA29 The rating is one of eight words from #R$BBB7. Bit 0 of $5BC3 (the
. quest finished) picks the better four; bits 5 and 6 of $5BC6, the number
. of rooms visited less one, pick one of those four. So the rating moves up a
. step for every 32 rooms seen, and a player who finishes having seen more
. of the castle is rated higher than one who took a short cut.
  $BA29,6 blank the buffer and the screen
  $BA2F,15 six lines: colours from #R$BB4C, positions from #R$BB52, text from #R$BB5E
  $BA3E,11 the days taken, two BCD digits from $5BB9, into the buffer at y=127, column 15
  $BA49,3 count the rooms visited and print the percentage
  $BA4C,7 bits 6 and 5 of rooms-visited-less-one, moved up to bits 7 and 6
  $BA53,6 add the quest-complete flag as bit 0
  $BA59,5 rotate into place: complete*8 + visited bits * 2, a word offset
  $BA5E,10 DE = the rating text's address from #R$BBB7
  $BA68,6 print it at x=$58, y=$27; its first byte is its colour
  $BA6E,11 the charms count is kept in binary (0 to 14): turn 10 to 14 into BCD for printing -- harmless, since the game is over

@ $BA79 label=print_charms_and_show
c $BA79 Print the charms count and show the summary
D $BA79 The last number on the summary, then the border and the copy of the
. finished buffer to the screen.
  $BA79,8 two BCD digits from $5BBB, at y=79, column 23 of the buffer
  $BA81,6 draw the border and copy the buffer to the display

@ $BA87 label=await_restart
c $BA87 Wait, play the game-over tune, and start again
D $BA87 Waits for every key to be let go -- the player is probably still
. holding one down from the moment of death -- then plays the game-over tune
. until a key is pressed, lingers for a while longer or until a key, and
. restarts at #R$AF7F, which keeps the control method and the random seeds.
  $BA87,6 all eight half-rows at once: loop while anything is held
  $BA8D,6 the tune at #R$B218, cut short by any key
  $BA93,5 about 14 seconds, or until a key
  $BA98,3 new game, without the menu's reset of everything

c $BA9B Wait a while or until a key is pressed
R $BA9B B how long: B times 65536 polls of the keyboard
D $BA9B Polls all eight half-rows through #R$B5F7 until one shows a key or
. the count runs out. Each poll costs about 95 T-states, so B=8 -- what both
. callers pass -- is roughly 14 seconds.
  $BA9B,3 HL counts 65536 polls before B is decremented

@ $BA9E label=wait_key_poll
c $BA9E One poll of the keyboard
  $BA9E,5 A=0 selects every half-row; return as soon as any key is down
  $BAA3,5 inner count
  $BAA8,2 outer count

c $BAAB The quest is complete
D $BAAB Shown in place of nothing else: blanks the screen, writes the six-line
. completion message, plays the completion tune to its end (no key cuts it
. short), waits up to 14 seconds or for a key, and then goes on to the
. ordinary summary at #R$BA29.
  $BAAB,6 blank the buffer and the screen
  $BAB1,12 colours from #R$BAD2, positions from #R$BAD8, text from #R$BAE4
  $BABD,7 clearing $5BB8 makes #R$BEBF draw the border and show the screen as soon as the text is written
  $BAC4,6 the completion tune at #R$B239, played in full
  $BACA,8 then the same summary as a failed game

b $BAD2 Completion message: the colour of each line
D $BAD2 Six attribute bytes, one per line of #R$BAE4, used in order by
. #R$BEBF: bright ink on black, running from white down through yellow,
. cyan, green and magenta to red.

b $BAD8 Completion message: where each line goes
D $BAD8 Six (x, y) pairs in pixels, one per line of #R$BAE4. x counts from
. the left edge; y counts up from the bottom of the screen and is the top row
. of the characters. x is a multiple of 8, so each line starts on a
. character column.
B $BAD8,12,2

@ $BAE4 label=complete_text
b $BAE4 Completion message: the text
D $BAE4 Six strings in the game's text code (see #R$BE4C): one byte per
. character, the index of its glyph in the font at #R$6108 -- 0 to 9 are the
. digits, $0A to $23 the letters, $26 a space -- with bit 7 set on the last
. character of each string. These have no colour byte of their own; the
. colours come from #R$BAD2.
B $BAE4,16,8 Line 1
B $BAF4,16,8 Line 2
B $BB04,20,8 Line 3
B $BB18,20,8 Line 4
B $BB2C,12,8 Line 5
B $BB38,20,8 Line 6

b $BB4C Game-over summary: the colour of each line
D $BB4C Six attribute bytes, one per line of #R$BB5E, all bright on black.

b $BB52 Game-over summary: where each line goes
D $BB52 Six (x, y) pairs in pixels, in the same form as #R$BAD8.
B $BB52,12,2

@ $BB5E label=gameover_text
b $BB5E Game-over summary: the text
D $BB5E Six strings in the game's text code (see #R$BAE4 for the format),
. without colour bytes. Four of them leave blank space where a number is
. printed afterwards straight into the buffer: the days (#R$BA29), the
. percentage (#R$BC10) and the charms (#R$BA79). The fourth line ends in
. character $27, the percent sign.
B $BB5E,10,8 Heading
B $BB68,12,8 Time taken, with room for the days
B $BB74,19,8 First half of the percentage line
B $BB87,15,8 Second half, with room for the number, and the percent sign
B $BB96,19,8 Charms collected, with room for the count
B $BBA9,14,8 Overall rating; the word itself comes from #R$BBB7

b $BBB7 The ratings
D $BBB7 Eight addresses of rating words, picked by #R$BA29: index =
. 4 if the quest was completed, plus (rooms visited - 1) / 32, so the second
. number runs 0 to 3 for up to 128 rooms.
W $BBB7,8,2 Quest not completed, fewest rooms first: #R$BBC7, #R$BBCF, #R$BBD8, #R$BBE0
W $BBBF,8,2 Quest completed, fewest rooms first: #R$BBE8, #R$BBF2, #R$BBFD, #R$BC05

@ $BBC7 label=rating_poor
b $BBC7 Rating: 1 to 32 rooms, not completed
D $BBC7 A rating string: a colour byte (bright red), then the word in the
. text code, padded on the left with spaces so that every rating ends in the
. same column. Bit 7 marks the last character.
@ $BBCF label=rating_average
b $BBCF Rating: 33 to 64 rooms, not completed
D $BBCF Same form as #R$BBC7. Oddly, this word ranks below the next one.
@ $BBD8 label=rating_fair
b $BBD8 Rating: 65 to 96 rooms, not completed
D $BBD8 Same form as #R$BBC7.
@ $BBE0 label=rating_good
b $BBE0 Rating: 97 rooms or more, not completed
D $BBE0 Same form as #R$BBC7: the best rating a player can get without
. finishing.
@ $BBE8 label=rating_excellent
b $BBE8 Rating: 1 to 32 rooms, completed
D $BBE8 Same form as #R$BBC7.
@ $BBF2 label=rating_marvellous
b $BBF2 Rating: 33 to 64 rooms, completed
D $BBF2 Same form as #R$BBC7.
@ $BBFD label=rating_hero
b $BBFD Rating: 65 to 96 rooms, completed
D $BBFD Same form as #R$BBC7.
@ $BC05 label=rating_adventurer
b $BC05 Rating: 97 rooms or more, completed
D $BC05 Same form as #R$BBC7. The top rating needs the quest finished and
. most of the castle explored.

c $BC10 Count the rooms visited and print the percentage of the quest
D $BC10 Counts the set bits in the 32-byte visited-room map at $5BE8 --
. one bit per room number, set by #R$D219 whenever a room is entered -- and
. keeps that count less one in $5BC6 for the rating.
D $BC10 The percentage is (rooms + 2 x charms) x 100 / 156, and 156 is 128
. rooms plus 14 charms counted twice, so visiting every room and filling the
. cauldron is exactly 100. There is no divide: HL is a 16-bit fraction and A
. a BCD whole part, and adding 100/156 as a 16-bit fraction once per point
. carries into A, with DAA keeping A decimal. The final $28 is exactly what
. a perfect score falls short of 100 x 65536, so the maximum comes out as 100
. rather than 99; it is also the only step that can carry into the hundreds.
R $BC10 E on exit, rooms + 2 x charms
  $BC10,8 E = the count; B = 8 bits, C = 32 bytes, from $5BE8

c $BC18 Count the visited bits in one byte
  $BC18,3 next byte of the map

@ $BC1B label=count_visited_bit
c $BC1B Test one bit of the visited map
  $BC1B,4 count it if set

@ $BC1F label=next_visited_bit
c $BC1F Next bit, next byte, then work out the percentage
  $BC1F,6 eight bits per byte, 32 bytes
  $BC25,5 rooms visited less one, for the rating in #R$BA29
  $BC2A,7 charms count double
  $BC31,7 HL = fraction, A = BCD whole part

@ $BC38 label=scale_to_percent
c $BC38 Add 100/156 per point
  $BC38,4 the carry out of the fraction is a whole 1 per cent
  $BC3F,7 the correction that lets 156 points reach 100
  $BC46,3 tens and units, BCD
  $BC49,8 the hundreds digit, 0 or 1
  $BC51,8 into the buffer at y=95, column 19
  $BC59,8 three digits when it is 100: the low digit of $5BC9, then $5BCA

@ $BC61 label=print_percent_two_digits
c $BC61 Print a percentage under 100
D $BC61 One column to the right and one byte on, so the two digits line up
. with the last two of a three-digit number.

# --------------------------------------------------------------------------
# The status panel ($BC66-$BD0B)
# --------------------------------------------------------------------------

c $BC66 Print the day count on the panel
D $BC66 Two BCD digits from $5BB9 into the buffer at the bottom of the
. panel (y=7, column 15), then makes their two attribute cells bright white
. directly on the screen. #R$C419 copies the digits to the display.
  $BC71,8 bottom character row, columns 15 and 16

c $BC7A Draw the lives icon on the panel
D $BC7A Uses the object record at #R$BFDB to draw sprite type $8C at x=16,
. y=32 in the buffer, then makes six attribute cells bright white: two in
. character row 18 and four in row 19, from column 2 -- the icon and the two
. cells where #R$BCA3 prints the number.
  $BC7A,23 the icon, unflipped
  $BC91,18 two cells of row 18 and four of row 19, from column 2

c $BCA3 Print the number of lives
D $BCA3 $5BBA as two BCD digits at y=39, column 4 of the buffer. The game
. counts lives in binary (it starts with 5; #R$D12A decrements and
. #R$C1AB increments), so the display is right only while there are fewer
. than 10.

c $BCAE Print BCD numbers in the standard font
R $BCAE DE the first byte of the number
R $BCAE B how many bytes: two digits each, high digit first
R $BCAE HL where in the buffer at #R$D8F3 the first digit's top row goes
D $BCAE Points the font pointer at $5BC7 at the standard font and prints
. each nibble as a character -- the digits are the first ten glyphs, so a BCD
. nibble is its own character code. No attributes are touched.

@ $BCB6 label=print_BCD_byte
c $BCB6 Print both digits of one BCD byte
  $BCB6,10 high digit

c $BCC0 Print the low digit of a BCD byte
D $BCC0 Also an entry point: starting here skips a leading digit, which is
. how #R$BC10 prints the 1 of 100.
  $BCC6,3 next byte

c $BCCA Draw the day label on the panel
D $BCCA Prints #R$BCE7 with the four-glyph font at #R$BCEC, at x=$70, y=$0F.
. Its colour is worked out from the room's colour in $5BAD: the ink is
. (1 - room ink) mod 8, bright, on black, so the label changes colour with
. the room.
  $BCCA,13 the label's colour byte, written into the string itself
  $BCD7,6 the private font
  $BCE0,7 print_text takes its position from the stack

b $BCE7 The day label
D $BCE7 A string in the text code with a colour byte at the front (filled in
. by #R$BCCA), followed by the four glyphs of #R$BCEC in order, the last
. with bit 7 set.

b $BCEC The day label's font
D $BCEC Four 8x8 glyphs, eight bytes each, top row first, that together make
. one small hand-lettered word four cells wide. Nothing else uses them.
B $BCEC,32,8

# --------------------------------------------------------------------------
# The menu ($BD0C-$BE30)
# --------------------------------------------------------------------------

c $BD0C The control-method menu
D $BD0C Reads the keyboard directly rather than through the ROM: #R$B5F7 OUTs
. a half-row and INs port $FE. Keys 1 to 4 choose keyboard, Kempston, cursor
. or Interface II, 5 toggles directional control, and 0 starts the game. The
. options chosen are shown by the FLASH bit of their line's colour.
D $BD0C The control method is bits 1 and 2 of $5BA4 (0 keyboard, 1 Kempston,
. 2 cursor, 3 Interface II) and bit 3 is directional control. The menu tune
. plays only on the first pass and blocks until it ends or a key is pressed
. (see #R$BD23), so the menu does not respond to keys until then.
E $BD0C Worth knowing if you are driving the game from a script: nothing here
. goes through LAST-K, so poking the ROM's key buffer has no effect at all.
. The keys have to be presented at the port.
  $BD0C,4 $5BB8=0: the first list drawn will show the screen

@ $BD15 label=clear_menu_flash
c $BD15 Clear the FLASH bit on every menu line, then draw the menu
  $BD15,5 all eight colours in #R$BDA2
  $BD1A,6 draw into the buffer; #R$BEBF shows it this first time
  $BD20,3 flash the lines already selected

c $BD23 The menu loop
D $BD23 One pass: redraws the menu (only its attributes change on screen
. after the first time), plays the tune if it has not played yet, and reads
. keys 1 to 5 into E. The control byte is kept in A through the key tests
. that follow and saved in $5BA6 first, so that #R$BD6C can click when it
. changes.
  $BD26,6 #R$B253; $5BD1 makes this a no-op after the first pass
  $BD2C,6 half-row $F7 is 1 2 3 4 5, key 1 in bit 0
  $BD32,6 A = control byte; remember it as it was
  $BD38,6 key 1: method 0, keyboard

c $BD3E Key 2: Kempston joystick
  $BD3E,8 method 1

c $BD46 Key 3: cursor joystick
  $BD46,8 method 2

c $BD4E Key 4: Interface II joystick
  $BD4E,6 method 3

c $BD54 Store the method, then key 5: directional control
D $BD54 Key 5 flips bit 3 of $5BA4, once per press: bit 0 of $5BD2 remembers
. that the key is down, and #R$BD85 clears it when the key is let go.
  $BD54,3 the method chosen by keys 1 to 4
  $BD5A,4 key 5 not pressed: clear the latch
  $BD5E,4 still held since last pass: do nothing
  $BD62,10 new press: latch it and toggle directional control

c $BD6C Start the game?
D $BD6C Clicks if the control byte changed this pass, then returns to start
. the game if 0 is pressed. Otherwise it bumps the seed at $5BA0 --
. so the time spent in the menu shapes the game that follows -- updates the
. flashing lines and goes round again.
  $BD6C,7 A is the new control byte here, whichever way we arrived
  $BD73,5 half-row $EF is 0 9 8 7 6; bit 0 is the 0 key
  $BD78,2 CPL in #R$B5F7 means a set bit is a pressed key
  $BD7B,4 one more step of the seed per pass of the menu
  $BD7F,6 show the new selection and loop

c $BD85 Key 5 released
  $BD85,2 clear the latch in $5BD2

c $BD89 Flash the selected menu lines
D $BD89 Sets the FLASH bit on the colour of the line for the chosen control
. method and clears it on the other three, then sets or clears it on the
. directional-control line to match bit 3 of $5BA4. The colours are in
. #R$BDA2; the first byte is the title's and is left alone.
  $BD89,3 the colour of the first option line: the second byte of #R$BDA2
  $BD8C,11 method 0 to 3 selects one of four lines
  $BD97,11 HL is now at the directional-control line

b $BDA2 Menu: the colour of each line
D $BDA2 Eight attribute bytes for the lines of #R$BDBA: the title, the four
. control methods, directional control, start, and the copyright line. Bit 7
. (FLASH) marks a selected option; #R$BD89 sets and clears it, and the
. initial value flashes the first method, keyboard.

b $BDAA Menu: where each line goes
D $BDAA Eight (x, y) pixel pairs, in the same form as #R$BAD8.
B $BDAA,16,2

b $BDBA Menu: the text
D $BDBA Eight strings in the game's text code, without colour bytes (see
. #R$BAE4). The option lines start with their key's digit. The last line
. uses the two glyphs beyond the letters and space: $24, a full stop, and
. $25, the copyright sign.
B $BDBA,11,8 Title
B $BDC5,10,8 Key 1: keyboard
B $BDCF,19,8 Key 2: Kempston joystick
B $BDE2,19,8 Key 3: cursor joystick
B $BDF5,14,8 Key 4: Interface II
B $BE03,21,8 Key 5: directional control
B $BE18,12,8 Key 0: start
B $BE24,13,8 Copyright line

# --------------------------------------------------------------------------
# Printing text ($BE31-$BEE3)
# --------------------------------------------------------------------------

c $BE31 Print a string in one given colour
R $BE31 HL the position: L = x, H = y, in pixels, y counting up from the bottom
R $BE31 DE the string, in the text code; on exit, the byte after it
D $BE31 For strings that carry no colour byte: the colour is whatever
. #R$BEBF left in $5BB6. Selects the standard font, works out the buffer
. address, and joins #R$BE4C where the attribute address is found.
  $BE31,7 the standard font
  $BE38,7 BC = the position again; HL = its buffer address
  $BE3F,4 the colour into A'

c $BE45 Print a string with its colour byte, in the standard font
R $BE45 HL the position (see #R$BE31)
R $BE45 DE the string: a colour byte, then characters in the text code
  $BE45,7 the position stays on the stack for print_text

c $BE4C Print a string with its colour byte
R $BE4C DE the string: a colour byte, then characters in the text code
D $BE4C The game's one text printer. The position is on the stack, the font
. pointer in $5BC7 selects the glyphs, and each character is an index into
. that font. The first byte is the attribute for every cell the string
. covers; the characters follow, and bit 7 marks the last. Glyphs go into
. the buffer at #R$D8F3 and the colours straight into attribute memory, one
. cell per character.
D $BE4C The position is a pixel (x, y) with y counting up from the bottom of
. the screen, the same convention as the rest of the drawing code, so a
. string's top edge is at y and it extends eight rows below.
  $BE4C,7 BC = the position, left on the stack; HL = its buffer address
  $BE53,3 the colour byte into A'

@ $BE56 label=text_attr_addr
c $BE56 Find the attribute address for the string
D $BE56 In the alternate registers: HL' becomes the attribute address of the
. first cell. DE' is kept, because #R$BEBF uses it to walk its colour list.
  $BE57,1 take the position off the stack

@ $BE5F label=print_text_char
c $BE5F Print one character of a string
  $BE60,5 bit 7: the last character
  $BE65,6 draw it; print_8x8 leaves HL one cell to the right
  $BE6B,5 colour its cell and move one cell right

@ $BE72 label=print_text_last
c $BE72 Print the last character of a string
  $BE72,8 without its end marker; DE ends past the string
  $BE7A,5 colour it and return

c $BE7F Print one 8x8 character into the buffer
R $BE7F A the character code
R $BE7F HL the buffer address of its top row; on exit, one cell to the right
D $BE7F The glyph is at $5BC7 plus eight times the code. Rows go downwards on
. the screen, which in the buffer is 32 bytes lower each time. Rather than
. keep the start address, it adds $0101 at the end: eight rows of -32 is
. -256, so +257 lands on the next cell to the right of where it began.
  $BE82,12 DE = the glyph
  $BE9C,5 -256 + 257: one cell right of the start

@ $BE91 label=print_8x8_row
c $BE91 Copy one row of the glyph
  $BE95,4 one row down the screen

c $BEA3 Set the FLASH bit on one of a list of colours
R $BEA3 A which one to set, from 0
R $BEA3 B how many colours
R $BEA3 HL the first colour; on exit, the byte after the last
D $BEA3 Sets bit 7 of the Ath byte and clears it on the others.
  $BEA3,3 A=0: this first one is the chosen one

@ $BEA6 label=flash_this_one
c $BEA6 Flash this colour
@ $BEAA label=flash_next_one
c $BEAA Count down to the chosen colour
@ $BEAD label=unflash_this_one
c $BEAD Do not flash this colour
@ $BEAF label=flash_list_step
c $BEAF Next colour in the list

c $BEB3 Draw the menu
D $BEB3 Sets up #R$BEBF with the menu's eight colours, positions and strings.

c $BEBF Print a list of strings
R $BEBF B how many
R $BEBF DE' the colours, one byte per string
R $BEBF HL the positions, an (x, y) pair per string
R $BEBF DE the strings, one after another, in the text code without colour bytes
D $BEBF Prints each string at its position in its colour. The first list
. printed after $5BB8 is cleared also draws the border and copies the buffer
. to the screen; later calls only redraw into the buffer (and write the
. attributes directly), which is how the menu can update its flashing lines
. every pass without redrawing the screen.
  $BEBF,7 this string's colour, for print_text_single_colour
  $BEC6,8 L = x, H = y; HL advanced to the next pair
  $BED5,5 already shown once: leave the screen alone
  $BEDA,10 first time: flag it, draw the border and show the buffer

c $BEE4 Print a sprite several times in a line
R $BEE4 IX an object record holding the sprite type and position
R $BEE4 B how many times
R $BEE4 E the step in x between copies
R $BEE4 D the step in y between copies
D $BEE4 Used to build the border and the panel out of repeated pieces.
  $BEED,14 move the record's pixel position by (E, D)

# --------------------------------------------------------------------------
# Transient objects: appearing, sparkling and vanishing ($BEFE-$BF44)
# --------------------------------------------------------------------------

c $BEFE Player appearing, frames 120 to 126
D $BEFE When the player enters a room (or comes back after losing a life)
. both of the player's records start as type 120 with their real type saved
. at +$10 (see #R$CABA and #R$D12A). This handler steps the type on by one
. every other frame, with a sound whose pitch follows the frame, and
. #R$BF11 finishes the effect.
  $BEFE,3 sprite drawing offset for this kind of object
  $BF01,7 only on alternate frames of the counter at $5BA2
  $BF08,9 next frame of the effect, a sound, and redraw

c $BF11 Player appearing, last frame
D $BF11 Turns the record back into what it was -- the type saved at +$10 --
. and runs that type's handler at once.
  $BF14,4 clear bit 6 of +$0D
  $BF18,9 restore the saved type and dispatch on it

c $BF21 Start the sparkle an object vanishes in
D $BF21 Turns the object in IX into type 112, the first frame of the
. sparkle, and sets bit 1 of +$07 so the collision code leaves it alone. Used
. by the player's own handlers when the player dies, and by #R$C337 (types 92
. to 95).
  $BF25,4 bit 1 of +$07: no collision checks for this object

c $BF2B Sparkle, frames 112 to 118 (and type 184)
D $BF2B Advances the type by one every frame, with a noise burst that gets
. shorter as the frames go on. Type 119 (#R$BF3F) ends it. Type 184 comes
. here too and steps to 185 (#R$BF37), which removes the object from the
. special-object table as it vanishes.

@ $BF31 label=sparkle_sound_and_draw
c $BF31 Sparkle sound and redraw
  $BF31,3 noise burst; its length depends on the type

c $BF37 Vanish and leave the special-object table
D $BF37 For types 185 and 187: clears the type byte of the object's entry in
. the table at #R$6FF2 (its address is at +$10 and +$11), so the object is
. gone for good, then vanishes as #R$BF3F does.

c $BF3F Sparkle, last frame: vanish
D $BF3F Hands over to #R$B95E, which makes the record type 1 -- an empty
. placeholder that is wiped from the screen and then does nothing.

# --------------------------------------------------------------------------
# The objects carried ($BF45-$BFFA)
# --------------------------------------------------------------------------

c $BF45 Redraw the carried objects if they changed
D $BF45 Called every frame; does the work only when $5BB4 has been set by a
. pick-up or a drop, and clears it.

c $BF4E Draw the three carried objects on the panel
D $BF4E The inventory is four 4-byte slots from $5BD8 (see #R$C141); the
. first is only a staging slot, so the three shown are the ones at $5BDC,
. $5BE0 and $5BE4, drawn left to right at x = 16, 40 and 64 along the
. bottom of the screen. The rightmost is the one the next drop will put
. down.
  $BF4E,11 the scratch record at #R$BFDB, three slots from $5BDC

c $BF59 Draw one carried object
D $BF59 Clears a box three cells wide and 24 rows high in the buffer, draws
. the object's sprite in it if the slot is not empty, copies the box to the
. screen and colours its nine cells from #R$BFD3.
  $BF5B,24 x = 24 x (slot number) + 16, y = 0
  $BF73,19 blank the box in the buffer
  $BF87,10 an empty slot has type 0: nothing to draw

@ $BF91 label=show_carried_slot
c $BF91 Show one carried object and colour it
  $BF91,20 copy the 3 x 24 box from the buffer to the screen
  $BFA9,11 the colour for this type, from the table at #R$BFD3
  $BFB4,20 3 x 3 attribute cells, from the top of the box
  $BFCA,6 next 4-byte slot

b $BFD3 Colours of the carried objects
D $BFD3 Eight attribute bytes indexed by the object type AND $0F. The things
. that can be carried are types $60 to $66, so entries 0 to 6 are the seven
. kinds of charm; entry 0 also colours an empty slot, which has nothing to
. show.

b $BFDB Scratch object record for the panel
D $BFDB A 32-byte object record, laid out like those in the object table,
. that the panel code fills in to draw a sprite on its own: type at +$00,
. the flip flags at +$07, the pixel position at +$1A (x) and +$1B (y).
. print_sprite writes the drawn width and height back to +$18 and +$19.
. Used for the border, the panel, the lives icon and the carried objects.

# --------------------------------------------------------------------------
# Picking up and dropping ($BFFB-$C1AA)
# --------------------------------------------------------------------------

c $BFFB Is the pick-up/drop control pressed?
R $BFFB F on exit, Z clear if it is pressed
D $BFFB The input bits in $5BB5 have pick-up/drop in bit 4 for every control
. method. With a joystick and directional control, though, the stick's
. down direction is a direction rather than pick-up, so bit 5 -- set by
. keys on the keyboard -- is used instead.
  $BFFB,11 joystick (method not 0)...
  $C006,5 ...and directional control: use bit 5

@ $C00B label=test_pickup_bit
c $C00B Test the pick-up bit

c $C00E Pick up or drop an object
D $C00E Called from the player's handler with IX on the player's lower
. record at $5C08. One press does one thing: pick up a charm the player is
. on or beside if there is one; otherwise put down the oldest charm carried.
. $5BB3 latches the press so holding the key down does nothing more.
D $C00E Nothing happens unless the player is inside the room (not in an
. arch), not jumping, and standing on something. It also checks whether
. there is an object within 12 units above the player's head; if so,
. $5BD3 is set and a drop is refused, because a drop lifts the player 12
. units onto the dropped object.
  $C00E,7 still held from the last press: wait for release
  $C019,4 only inside the room's walls
  $C01D,10 not while jumping (+$0C bit 3), only when standing on something (bit 2)
  $C027,21 anything within 12 units above? The player's z is raised to look, then put back
  $C03C,5 yes: there is no room to stand on a dropped object

@ $C041 label=start_pickup_drop
c $C041 Look for a charm to pick up
D $C041 Clicks, latches the key, flags the panel for redraw, and enlarges the
. player's box by 4 in each dimension -- the old sizes go on the stack for
. #R$C09D -- so that a charm just out of reach still counts. The special
. objects in a room are always in the two records at $5C48 and $5C68.
  $C04E,29 width, depth and height +4 each; the originals are pushed
  $C06B,4 the first special-object record

@ $C06F label=try_pickup_loop
c $C06F Try each special-object record
  $C06F,6 a charm, and touching the player: take it
  $C075,7 next record
  $C07C,5 this can only be non-zero here: $5BB5 has not changed since the first test
  $C081,11 room for two special objects, but only one in the wizard's room, $88, where the second record is the cauldron's bubbles

@ $C08C label=find_free_record
c $C08C Nothing to pick up: find a free record to drop into

@ $C093 label=find_free_record_loop
c $C093 Is this record free?
  $C093,6 type 0 is free
  $C099,4 none free: the room already has its quota; drop nothing

c $C09D Pick-up or drop done
D $C09D Puts back the player's width, depth and height saved by #R$C041.

@ $C0A9 label=wait_pickup_release
c $C0A9 Wait for the pick-up key to be released
  $C0A9,9 clear the latch once it is up

c $C0B2 Drop the oldest charm carried
D $C0B2 IY is a free special-object record. The charm dropped is the one in
. the last slot, $5BE4. If that slot is empty the slots are shifted along
. anyway, which brings the next charm into the dropping position.
D $C0B2 In the wizard's room, with the player standing high (z of $98 or
. more, which in that room means standing on the cauldron -- inferred from
. the height), the charm becomes type $68 to $6E instead
. of $60 to $66, which #R$C1F1 carries into the cauldron, and $5BC4 is set
. to lock out the controls until it arrives.
  $C0B2,8 last slot empty: just move the slots along
  $C0BA,6 something above the player's head: no drop
  $C0C0,6 the charm's type into the free record
  $C0C6,14 in the wizard's room and high up?
  $C0D4,9 yes: into the cauldron, and freeze the player's controls

@ $C0DD label=place_under_player
c $C0DD Put the charm under the player
D $C0DD The charm takes the player's x, y and z, and the player -- both
. records, at $5C08 and $5C28 -- goes up 12 units, the height
. of a charm, so the player ends up standing on it. This is how charms can
. be stacked into steps.
  $C0DD,1 HL = $5BE5: the rest of the slot, for drop_object
  $C0DE,13 copy x, y, z from the player to the charm
  $C0EB,16 lift both of the player's records by 12
  $C0FB,11 the charm's screen position

c $C106 Fill in a dropped charm's record
R $C106 IY the record, its type and position already set
D $C106 The size is 5 x 5 x 12; the flags byte and the address of its entry
. in #R$6FF2 come back from the carried slot; the room is the player's.
. Bit 0 of +$0D tells #R$C28B it has just been put down.
  $C106,12 width, depth, height
  $C112,6 +$07 flags from the slot
  $C118,6 the room: the player's
  $C11E,9 +$10: its entry in the special-object table
  $C127,4 just dropped

c $C12B Shift the carried slots along
D $C12B Moves slots 0 to 2 ($5BD8 to $5BE3) up one to slots 1 to 3 and empties
. slot 0. Whatever was in slot 3 has already been put down, so the carried
. objects behave as a queue: first picked up, first dropped.
  $C12B,11 12 bytes up by 4, copied from the top down so they do not overwrite themselves
  $C136,8 slot 0 is now free

c $C141 Pick up a charm
R $C141 IY the charm's record
D $C141 Copies the charm into the staging slot at $5BD8 -- type, flags, and
. the address of its entry in #R$6FF2, whose type byte is then zeroed so the
. charm will not be put back in its room when the player leaves. The record
. becomes type 1 and is wiped from the screen.
D $C141 If three charms are already carried, the oldest is dropped where
. the new one was, using the same record: picking up swaps.
D $C141 A carried slot is four bytes:
. +0 the type ($60 to $66), +1 the flags byte from +$07, +2 and +3 the
. address of the charm's entry in the special-object table.
  $C144,4 clear $5BC0
  $C148,21 type, flags and table pointer into slot 0; zero the table entry's type
  $C15D,7 wipe it; type 1 leaves an empty record
  $C164,8 carrying fewer than three: just shift the slots
  $C16C,6 otherwise the oldest takes the new one's place

c $C172 Can this special object be picked up?
R $C172 IY the object
R $C172 F on exit, carry set if it can
D $C172 Only types $60 to $66, the seven kinds of charm, and only when the
. player (IX) is on or beside it. $67, the extra life, is not picked up but
. collected by touching (#R$C1AB).

c $C17A Is the player on or next to this object?
R $C17A IX the player
R $C17A IY the object
R $C17A F on exit, carry set if their boxes overlap in x and y, and in z with the player lowered by 4
D $C17A Lowering the player by 4 makes an object the player stands on count as
. touching.
  $C18A,21 z test with the player 4 units lower, then put back

@ $C19F label=near_obj_done
c $C19F Result of the touch test

c $C1A1 Is the object moving?
R $C1A1 IX the object
R $C1A1 F on exit, Z set if its dX, dY and dZ (+$09 to +$0B) are all zero

# --------------------------------------------------------------------------
# The extra life and the cauldron ($C1AB-$C2CB)
# --------------------------------------------------------------------------

c $C1AB Special object $67: the extra life
D $C1AB Tests whether the player touches it, with the player's box widened
. by 1 in x and y. If so the object changes to type $6F (#R$B95E, vanish),
. its entry in the special-object table is cleared so it never comes back,
. and the lives count at $5BBA goes up by one, is reprinted and copied to
. the screen.
  $C1AE,27 test against the player at $5C08, widened by 1 in x and y
  $C1CB,4 set bit 3: type $6F
  $C1D2,8 gone from the table for good
  $C1DA,4 one more life
  $C1DE,4 clear $5BC0
  $C1E2,12 click, print and show the new count

@ $C1EE label=extra_life_fall
c $C1EE Fall and settle like any other object

c $C1F1 A charm on its way into the cauldron, types $68 to $6E
D $C1F1 A charm dropped from high up in the wizard's room (#R$C0B2) becomes one of these.
. Each frame it moves one unit in x and one in y towards the centre of the
. room, $80,$80, and rises to a height of $98; once over the centre it
. falls straight down into the cauldron (#R$C238).
  $C1F4,14 dX = +1, -1 or 0 towards x = $80

@ $C202 label=steer_to_centre_y
c $C202 Steer towards the centre in y
  $C205,14 dY = +1, -1 or 0 towards y = $80

@ $C213 label=check_over_centre
c $C213 Over the centre yet?
  $C216,12 x = $80 and y = $80: go down

@ $C222 label=rise_over_cauldron
c $C222 Rise to a height of $98
  $C222,10 dZ = 2 below $98, 1 from there up; gravity takes one off each frame

@ $C22C label=store_rise_speed
c $C22C Set the vertical speed

@ $C22F label=move_charm_to_cauldron
c $C22F Move it

@ $C232 label=click_wipe_and_draw
c $C232 Click and redraw
D $C232 A short click whose pitch depends on the object's position (#R$B467),
. then flags the object to be wiped and redrawn.

c $C238 Over the centre: fall into the cauldron
D $C238 Keeps falling, with collisions switched off so the charm drops
. through the cauldron's top, until z is down to $80.
  $C238,7 reached $80?
  $C23F,6 bit 1 of +$07: no collision checks this frame

c $C245 A charm lands in the cauldron
D $C245 If the charm's kind (type AND 7) is the one the wizard wants next, the
. count at $5BBB goes up and the screen's colours cycle; the fourteenth
. starts the ending. Either way the charm is used up: its entry in the
. special-object table is cleared and it vanishes. So the wrong charm is
. not given back -- it is lost.
  $C249,11 the kind wanted next, from #R$C27D
  $C254,7 right one: count it and flash the screen
  $C25B,10 fourteen: the quest is done

@ $C265 label=cauldron_consume
c $C265 Use the charm up
  $C265,4 give the player back the controls
  $C269,8 gone from the special-object table
  $C271,3 and from the room

c $C274 Which charm the wizard wants next
R $C274 HL on exit, the address of the entry in #R$C27D for the count in $5BBB
D $C274 Also used by the cauldron's bubbles (#R$B8DA) to show the next charm
. wanted above the cauldron.

b $C27D The charms the wizard wants, in order
D $C27D Fourteen kinds, 0 to 6 (the charm's type AND 7), each appearing
. twice. #R$B544 rotates the list left by 4 to 7 places at the start of a
. game, choosing by the seed at $5BA0. The list is rotated in place and never
. put back, so the first game after loading can ask for only four orders,
. and later games rotate on from wherever the last one left it. Every game
. wants the same fourteen, two of each kind; only the order changes. #R$C274 indexes it by the number already added.
B $C27D,7 First seven as stored
B $C284,7 Second seven as stored

c $C28B Special objects $60 to $66: a charm lying in a room
D $C28B Falls under gravity and comes to rest. When it has just been put
. down (bit 0 of +$0D, set by #R$C106) or has moved, its horizontal speed is
. stopped and it is redrawn with a click.
  $C291,10 just dropped, or moving: stop it

@ $C29B label=settle_charm
c $C29B Stop the charm and redraw it
  $C29B,10 clear the just-dropped flag and dX, dY; click and redraw

c $C2A5 Cycle the screen's colours with a sound
D $C2A5 Sixteen times: steps the ink of every attribute cell on by one
. (paper, BRIGHT and FLASH kept), makes a noise burst and waits briefly. The
. effect a correct charm makes in the cauldron.
  $C2A5,2 sixteen passes

@ $C2A7 label=cycle_colours_pass
c $C2A7 One pass over the attributes
  $C2A7,6 all 768 cells

c $C2AD Step one cell's ink
  $C2AD,10 ink + 1 mod 8, the rest unchanged
  $C2BD,3 noise burst, sized by the charm's type
  $C2C0,3 a short pause

@ $C2C3 label=cycle_colours_pause
c $C2C3 Pause between passes

c $C2CB Handler that does nothing
D $C2CB The handler for the object types that stay still and need no update.

# --------------------------------------------------------------------------
# The final sequence, day and night, special objects, ghosts, portcullises
# --------------------------------------------------------------------------

# --------------------------------------------------------------------------
# $C2CC-$C82A: the end of the game, day and night, the transformation, the
# special objects, ghosts, portcullises, drawing offsets and arches
# (agent 5)
# --------------------------------------------------------------------------

c $C2CC Start the final animation
D $C2CC Called by #R$C245 when the fourteenth object has gone into the
. cauldron. It sets the game-complete flag at $5BC3, which from now on stops
. the sun and moon (#R$C3A4) and with them any further transformation, the
. player's input (#R$D022) and death.
. Then it clears the room for the ending: object records 3 to 13 are marked
. for erasing and given type 1, which the renderer turns into an empty record
. once the old image has been wiped (see #R$D704), and every plain stone block
. (type 7) further up the table becomes type 131, whose handler (#R$B566)
. lifts it into the air.
R $C2CC IX the object that has just reached the cauldron (preserved)
  $C2CC,5 the game is complete
  $C2D3,9 from record 3 at $5C68, eleven records of 32 bytes
E $C2CC Which things records 3 to 13 hold in the wizard's room depends on the
. room data and has not been worked out record by record.

@ $C2DC label=final_clear_loop
c $C2DC Erase the next of records 3 to 13
D $C2DC One pass of the loop in #R$C2CC: flag the record's image to be wiped and
. set its type to 1 so that it is freed once the wipe has happened.
  $C2DC,7 wipe and redraw it (and whatever it overlaps)
  $C2E3,4 type 1: erase, then free
  $C2EB,3 the end of the object table, for the scan that follows

@ $C2EE label=blocks_to_rising
c $C2EE Turn a stone block into a rising block
D $C2EE The second loop of #R$C2CC walks the rest of the object table, from
. record 14 to the end, and turns every plain block (type 7, the first entry of
. the block types at #R$6BD1) into type 131.
  $C2EE,7 a plain block?
  $C2F5,4 type 131: rises

@ $C2F9 label=final_next_record
c $C2F9 Next record in the stone-block scan
D $C2F9 Steps IX on by 32 and loops while it is below the font at #R$6108, the end
. of the object table. Then IX is restored for the caller.
  $C2FB,8 IX less the font's address, #R$6108, without disturbing IX
  $C303,2 back to the object that reached the cauldron

c $C306 Start the transformation if one is due
D $C306 The first thing the player's handler (#R$C83E) does each frame. The
. variable at $5BB1 is set to 1 by #R$C3FF at every sunrise and sunset; if it
. is set, and the player is neither in the settling time just after entering a
. room (the top nibble of +$0C) nor in the middle of a jump (bit 3 of +$0C),
. the change from knight to werewolf or back begins now.
D $C306 Starting it replaces the rest of the player's frame: the two INC SPs
. throw away the return address into #R$C83E, so the final RET of
. #R$C357 returns straight to the object loop and the player neither reads the
. keys nor moves. $5BB1 now holds the player's type, which is how the end of
. the transformation (#R$C377) knows which way to change. The top half of the
. player is erased; the bottom half becomes one of the spinning transformation
. sprites, types 92 to 95, handled from now on by #R$C337.
R $C306 IX the player's bottom (legs) record, $5C08
  $C306,5 no transformation pending
  $C30B,6 still settling into a new room
  $C311,5 in mid-jump
  $C316,2 drop the return into the player handler
  $C318,6 remember the knight or werewolf type
  $C31E,4 +$10 counts eight steps of four frames each
  $C322,11 the top half: type 1, erase and free
  $C32D,5 and draw that
  $C332,5 the transformation sprite's drawing offset, and the first sprite

c $C337 The transformation in progress (types 92 to 95)
D $C337 The handler for the player's bottom record while it is changing. The
. player can still be killed during the change: if bit 6 of +$0D says
. something deadly has touched it, and the game is not complete, the death
. sparkles start.
R $C337 IX the player's bottom record
  $C337,3 draw 12 pixels left and 2 down
  $C33A,6 touched by something deadly?
  $C340,6 not once the game is complete
  $C346,3 die

@ $C349 label=transform_step
c $C349 One step of the transformation
D $C349 Every fourth frame: a sound, a step off the counter at +$10, and either
. the end of the transformation (#R$C377) or a new random sprite
. (#R$C357). Eight steps, so the change takes 32 frames.
  $C349,6 only on every fourth frame
  $C34F,3 a sound that depends on which sprite is showing
  $C352,5 the last step?

c $C357 Show a random transformation sprite
D $C357 Picks one of the four transformation sprites (types 92 to 95) at random,
. never the one already showing, so the figure always changes.
R $C357 IX the player's bottom record
  $C357,7 the refresh register plus the random seed
  $C35E,4 92 to 95
  $C362,7 if it is the current one, take its neighbour

@ $C369 label=set_transform_sprite
c $C369 Set the transformation sprite
D $C369 Stores the new type and mirrors the sprite each time, which makes the
. figure appear to spin.
  $C369,3 the new sprite
  $C36C,8 flip it left for right
  $C374,3 draw it

@ $C377 label=finish_transform
c $C377 End the transformation
D $C377 Flips bit 5 of the saved type, which swaps a knight's legs (types 16
. to 29) for the matching werewolf's (48 to 61) or back, and puts the top half
. back as that type plus 16. $5BB1 is cleared, so nothing is pending until the
. next sunrise or sunset.
D $C377 The drawing offset is set here too, one pixel lower for the werewolf,
. which is what the new type's own handler (#R$C823 or #R$C828) will set
. on the next frame anyway; setting it now keeps the first frame in the right
. place.
R $C377 IX the player's bottom record
  $C377,8 knight to werewolf or werewolf to knight
  $C37F,5 the top half is the bottom's type plus 16
  $C384,4 no transformation pending
  $C388,3 X -12, Y -6: the knight's legs
  $C38B,9 Y -7 for the werewolf's

@ $C394 label=transform_done_draw
c $C394 Draw the finished player
D $C394 Flags the player for redrawing in its new form.

c $C397 Move the sun or moon on
D $C397 Called by the renderer (#R$D653) as it finishes a frame; every eighth
. frame it moves the
. sun or moon one pixel to the right across its window in the bottom right of
. the screen and redraws the window. The object doing the moving is the
. 32-byte record at #R$C44D, laid out like an entry in the object table.
  $C397,6 every eighth frame
  $C39D,7 one pixel right (+$1A is the pixel X)

c $C3A4 Place the sun or moon, and redraw its window
D $C3A4 Once the sun or moon reaches pixel X 225 its half of the day is over
. and #R$C3FF swaps them. Before that, its height comes from the arc at
. #R$C440, one entry for every four pixels across: it climbs, levels off and
. sinks. Also called directly from #R$B03F when a room is entered, to draw
. the window afresh.
R $C3A4 IX #R$C44D
  $C3A4,5 the sun stops once the game is complete
  $C3A9,7 reached the right-hand edge?
  $C3B0,19 height = the table entry for ((X + 16) / 4) mod 16; X runs 176 to 224, so the index runs 0 to 12

c $C3C3 Draw the sun and moon window
D $C3C3 Builds the window in the screen buffer and copies it to the screen: a
. patch 48 pixels wide and 31 high in the bottom right corner, cleared, the
. sun or moon drawn at its current position, and the two halves of the window
. frame (types 90 and 186) drawn over it using the scratch record at
. #R$BFDB. Because the frame is drawn last, the sun or moon rises from
. behind its left side and sets behind its right.
R $C3C3 IX #R$C44D
  $C3C3,15 clear 6 bytes by 31 rows of the buffer, from column 23 of the bottom row
  $C3D2,3 the sun or moon
  $C3D5,23 the frame's left half, type 90, at pixel (184, 0)
  $C3EC,11 and its right half, type 186, at (208, 0)
  $C3F7,8 copy the 31 rows to the screen, upwards from the bottom line

c $C3FF Swap the sun and moon
D $C3FF The end of a day or a night. Type 88 is the sun and type 89 the moon;
. flipping bit 0 swaps them, recolours the window (#R$D30D) and starts the new
. one at the left again. Setting $5BB1 to 1 asks the player's handler to
. transform (#R$C306): knight by day, werewolf by night. When the moon has
. just given way to the sun a new day has begun, and #R$C419 counts it.
R $C3FF IX #R$C44D
  $C3FF,8 sun to moon or moon to sun
  $C407,3 yellow for the sun, white for the moon
  $C40A,4 back to the left of the window
  $C40E,5 the player must transform
  $C413,6 moon: nothing more to do

c $C419 A new day
D $C419 Adds one to the day count at $5BB9, which is kept in binary-coded
. decimal for printing. Reaching day 40 ends the game (#R$BA22); otherwise the
. new number is printed and copied to the screen, and the sun's window
. redrawn.
  $C419,8 days + 1, in BCD
  $C421,5 forty days: game over
  $C426,9 copy the 16 by 8 pixel patch holding the number, at pixel (120, 0), to the screen
  $C42F,3 redraw the window with the new sun

c $C432 Copy a 16 by 8 pixel patch from the buffer to the screen
R $C432 B the pixel row, counted from the bottom of the screen
R $C432 C the pixel column
D $C432 Converts the pixel position into a screen address (#R$D826) and an
. address in the buffer (#R$D811), then copies 8 rows of 2 bytes. Used for the
. day count and the lives count, which change without the whole screen being
. redrawn.
  $C43A,6 8 rows of 2 bytes

b $C440 The sun's and moon's heights
D $C440 Thirteen pixel heights, one for every four pixels the sun or moon has
. moved across its window: up from 5 to 10 and back down to 5. Read by
. #R$C3A4.
B $C440,13,13

b $C44D The sun or moon, as an object record
D $C44D Thirty-two bytes laid out like a record in the object table, so that the
. ordinary sprite printer (#R$D718) can draw the sun or moon. The fields that
. matter: +$00 the type, 88 for the sun or 89 for the moon, and +$1A and
. +$1B the pixel position. Set up by #R$C46D, moved by #R$C397,
. swapped by #R$C3FF. Other code reads +$00 to know whether it is day or night:
. #R$D30D for the window's colour, and #R$D12A to bring the player back as a
. knight or a werewolf.
B $C44D,32,8

c $C46D Start the first day
D $C46D The sun (type 88) at the left of its window. The height of 9 does not
. survive: the first call to #R$C3A4 replaces it from the table at #R$C440.
  $C46D,16 the sun, pixel X 176, pixel Y 9

c $C47E Shuffle the special objects
D $C47E Gives each of the 32 places in #R$6FF2 an object, and puts each one at
. its starting position. The places are fixed by the table; what changes from
. game to game is which object is where. The kinds are handed out in rotation,
. 96 to 103 and round again, so there are four of each, but the rotation
. starts at a random point: the seed saved at switch-on ($5BA0) plus the
. refresh register.
D $C47E Types 96 to 102 are the seven things the wizard's cauldron needs
. (#R$C27D lists the order he asks for them); type 103 is the one that gives
. an extra life when touched (#R$C1AB).
  $C47E,3 the first of 32 nine-byte entries
  $C481,8 a random starting kind

c $C489 Set up one special-object entry
D $C489 A table entry is nine bytes: +0 the type, 0 once the object has been
. collected; +1 to +4 where it starts, as x, y, z and room; +5 to +8 where it is
. now, in the same order. Here the type is written and the starting position
. copied to the current one.
R $C489 HL the entry
R $C489 E the rotating kind
  $C489,6 type 96 + (kind mod 8)
  $C48F,2 on to +1, and the next kind
  $C491,13 copy +1..+4, where it starts, to +5..+8, where it is
  $C49E,11 until the sprite table at #R$7112, which follows the last entry

c $C4AA The block type called moveable (type 62)
D $C4AA Clears its horizontal velocity, clicks the speaker with a pitch taken
. from the frame counter, and lets gravity act on it. Clearing the velocity
. before moving undoes any push the collision code gave it earlier in the
. frame -- the player is always the first object -- so the block can only
. fall, never be pushed. Watched in the emulator: a table placed in the
. player's path was pushed a step per frame, and the same table given this
. type did not move at all. Compare the table's handler,
. #R$C4C3, which moves first and clears the velocity afterwards. Whether a
. block that cannot be moved was meant is not known.
  $C4AA,3 draw 16 left and 8 down
  $C4AD,3 no horizontal movement

c $C4B6 A chest (type 85)
D $C4B6 Falls and moves by its velocity, and makes a sound and redraws only when
. it is actually moving. Unlike the table (#R$C4C3) it keeps its horizontal
. velocity from one frame to the next.
  $C4B6,3 draw 16 left and 8 down
  $C4B9,3 gravity, then move
  $C4BC,4 still: nothing to draw

c $C4C3 A table (type 84)
D $C4C3 The drawing offset, then the shared code that follows.
  $C4C3,3 draw 16 left and 8 down

c $C4C6 Move under gravity, and redraw if moved
D $C4C6 Applies gravity and moves the object; if it moved, its horizontal
. velocity is cleared (so a push moves it one step, not a slide), a sound is
. made and it is redrawn. Shared by the table (#R$C4C3) and the extra-life
. object (#R$C1AB).
  $C4C6,3 gravity, then move
  $C4C9,4 still: nothing to draw
  $C4CD,3 one step per push

c $C4D3 Drawing offset X -8, Y -2 (types 128 to 130)
D $C4D3 This is the whole handler for types 128 to 130: they only need their
. drawing offset set. #R$C1AB calls it too.
D $C4D3 A note that applies to all the routines from here to #R$C510: +$12 and
. +$13 of an object record are added to the pixel position that
. #R$D6C9 projects from its x, y and z, to line the sprite's picture up with
. the object's position in the room. X is pixels right and Y pixels up, so the
. usual negative values move the sprite left and down. The tcdev names that
. start adj_ give the Y value first: adj_m6_m12 is Y -6, X -12.

c $C4D8 Drawing offset X -12, Y -4
D $C4D8 The offset used by most small objects: the special objects, the
. cauldron's contents and a dozen more.

c $C4DD Drawing offset X -12, Y -6
D $C4DD Used by the knight's legs, the ghosts, the portcullis and others.

c $C4E0 Jump to set the drawing offset
D $C4E0 The offset routines from #R$C4D3 to #R$C510 all end by jumping here,
. because #R$C72B is too far away for a relative jump and a JR plus one shared
. JP is shorter than a JP in every one of them.

c $C4E3 Drawing offset X -16, Y -8 (types 6 and 7)
D $C4E3 The whole handler for types 6 and 7 -- type 7 is the plain stone block
. -- and the offset for chests, tables and several others.

c $C4E8 Drawing offset X -20, Y -1 (type 10)
D $C4E8 The whole handler for type 10.

c $C4ED Drawing offset X -12, Y -2 (type 11)
D $C4ED The whole handler for type 11; also the offset of the transformation
. sprites (#R$C306, #R$C337).

c $C4F2 Drawing offset X -8, Y -4 (types 12 to 15)
D $C4F2 The whole handler for types 12 to 15, and used by several others.

c $C4F7 Drawing offset X -12, Y -8
D $C4F7 The knight's top half.

c $C4FC Drawing offset X -12, Y -7
D $C4FC The werewolf's legs (#R$C828) and one other.

c $C501 Drawing offset X -12, Y -12
D $C501 The werewolf's top half.

c $C506 Drawing offset X -16, Y -12 (types 88 to 90)
D $C506 The whole handler for types 88 to 90, and used by one other. The sun,
. the moon and the left half of their window's frame are drawn with these
. type numbers, but through their own records (#R$C44D, #R$BFDB), not the
. object table.

c $C50B Drawing offset X -12, Y +7

c $C510 Drawing offset X -12, Y +3

c $C515 Fill a rectangle of bytes
R $C515 HL the top-left byte, in the screen buffer or the attributes
R $C515 B the width in bytes
R $C515 C the number of rows
R $C515 A the value to fill with
D $C515 Rows are 32 bytes apart, which suits both the buffer at #R$D8F3 and the
. attribute file.

@ $C518 label=fill_window_row
c $C518 Fill one row
D $C518 The row loop of #R$C515.

@ $C51A label=fill_window_byte
c $C51A Fill one byte
D $C51A The inner loop of #R$C515, then on to the next row 32 bytes down.

c $C525 Bring in the special objects for a new room
D $C525 Called while a room is built (#R$D1EF). Looks through the 32 entries of
. #R$6FF2 for objects not yet collected whose current room is the one being
. entered, and builds an object record for each in records 2 and 3 ($5C48 and
. $5C68) -- the two slots the game keeps for special objects. Whatever is
. left of those two records is cleared.
D $C525 The 32 starting rooms in the table are all different, so at the start
. no room has more than one. A third match would build a record over $5C88,
. the room's first object, and #R$C583 would then never stop clearing; how
. the drop code keeps it to two has not been checked here.
R $C525 IX the player's record; +$08 is the room being entered
  $C525,4 DE', the record being built, in the alternate set
  $C52D,3 the room

@ $C530 label=find_spec_obj_loop
c $C530 Check one special-object entry
D $C530 If the entry is still in play and in this room, copy it into the next
. special-object record: type; x, y and z from where it is now; size 5 by 5 by
. 12 and flags $14 (drawn, and can be pushed); the room; nothing moving; and at
. +$10 the address of the table entry, so the record can be written back to
. it by #R$C591 when the room is left.
  $C530,6 collected: skip
  $C536,6 in another room: skip
  $C53C,5 HL = the entry; its address is kept on the stack
  $C541,4 the type
  $C545,9 x, y and z from +5..+7, where it is now
  $C54E,14 5 by 5 by 12, flags $14
  $C55C,4 the room
  $C560,5 +$09..+$0F: no velocity or status
  $C565,7 +$10: the address of the table entry
  $C56C,5 +$12..+$1F cleared
  $C571,1 back to the scan's registers

@ $C572 label=next_spec_obj_slot
c $C572 Next special-object entry
D $C572 Nine bytes on, until the sprite table at #R$7112.

@ $C583 label=clear_spare_spec_records
c $C583 Clear the unused special-object records
D $C583 Zeroes 32 bytes at a time until DE reaches record 4 at $5C88, the first
. of the room's own objects.
R $C583 DE the first unused byte of records 2 and 3

c $C591 Remember where the special objects were left
D $C591 Called before a new room is built (#R$D1E6), once a frame of the game
. has run (bit 0 of $5BB2). For
. each of records 2 and 3 that is in use, writes its type and its x, y, z and
. room back into its entry in #R$6FF2, through the pointer at +$10. That is how
. an object pushed or dropped somewhere stays there when you come back.
  $C591,4 record 2

@ $C595 label=save_spec_obj_loop
c $C595 Write back one special object
  $C595,6 empty
  $C59B,10 the type, through the pointer at +$10
  $C5A5,5 on to +5
  $C5AA,9 x, y and z
  $C5B3,4 the room

@ $C5B7 label=save_spec_obj_next
c $C5B7 Next special-object record
D $C5B7 Until record 4, at $5C88.

c $C5C8 A ghost (types 80 to 83)
D $C5C8 A ghost drifts diagonally at a speed of 3 or 4 in each direction, and
. picks a new random diagonal whenever it has no speed (as when it has just
. been created) or runs into something across the floor. It animates on
. every frame and is deadly both ways: to what it runs into, and to what runs
. into it.
R $C5C8 IX the ghost's record
  $C5C8,3 draw 12 left and 6 down
  $C5CB,3 gravity, then move
  $C5CE,8 not moving: new direction
  $C5D6,7 blocked in x or y (bits 0 and 1 of +$0C): new direction

@ $C5DD label=ghost_new_direction
c $C5DD Give a ghost a new direction
D $C5DD Each of dx and dy is taken from entries 4 to 7 of #R$C64E -- -3, +3, -4
. or +4 -- one chosen by the random seed and the other by the frame counter.
. Then the sprite is chosen to match, and a sound played.
  $C5DD,13 dx
  $C5EA,13 dy
  $C5F7,3 face the way it is going
  $C5FA,3 the sound's pitch comes from x + y + z

@ $C5FD label=ghost_animate
c $C5FD Animate a ghost
D $C5FD Swaps between the two frames of its sprite (bit 0 of the type) and sets
. the deadly flags and the redraw flags.

c $C603 Choose a ghost's sprite from its direction
D $C603 A ghost has two views, chosen by bit 1 of its type, and each can be
. mirrored (bit 6 of +$07); together they give four directions. Whichever of
. dx and dy is larger in size decides: mostly along x, the view is mirrored;
. mostly along y, it is not. The sign then picks the view.
R $C603 IX the ghost's record
  $C603,9 the size of dx

@ $C60C label=ghost_abs_dy
c $C60C The size of dy
  $C60C,1 C = the size of dx

@ $C616 label=ghost_pick_view
c $C616 Mostly along x, or mostly along y?
  $C616,3 |dy| >= |dx|: mostly along y
  $C619,7 which way along x
  $C620,4 +x: view 0

c $C624 Mirror the ghost
D $C624 Mirrored when moving mostly along x.

@ $C629 label=ghost_x_negative
c $C629 Moving towards -x
D $C629 View 1, mirrored.

@ $C62F label=ghost_mostly_y
c $C62F Moving mostly along y
  $C62F,7 which way along y
  $C636,4 +y: view 1

c $C63A Don't mirror the ghost
D $C63A Not mirrored when moving mostly along y.

@ $C63F label=ghost_y_negative
c $C63F Moving towards -y
D $C63F View 0, not mirrored.

c $C645 Look up a speed
R $C645 A the index into #R$C64E
R $C645 A on exit, the speed
D $C645 A plain byte lookup in #R$C64E.

b $C64E Speeds, negative and positive
D $C64E Sixteen signed bytes in pairs: -1 and +1, -2 and +2, up to -8 and +8.
. The ghosts (#R$C5DD) only read entries 4 to 7, the pairs for 3 and 4; no other
. use of the table has been found.
B $C64E,16,2

c $C65E A portcullis at rest (type 8)
D $C65E A portcullis moves between the floor and 32 above it. Only one in a room
. moves at a time: $5BAF counts the one moving, and while it is non-zero
. nothing here happens. A portcullis anywhere below the top starts to rise
. at a random moment, on average once every 32 frames. One at the top
. drops at once for its first four falls after the room is entered (counted
. in $5BB0); after that it too waits for a 1-in-32 chance on each frame.
. Setting bit 0 of the type makes it type 9, handled by #R$C6BD while it moves.
R $C65E IX the portcullis's record
  $C65E,3 draw 12 left and 6 down
  $C661,6 another portcullis is moving
  $C667,8 on the floor ($5BAE is the floor's height): rise
  $C66F,7 anywhere below the floor + 31: rise
  $C676,7 fewer than four falls so far: fall now
  $C67D,6 otherwise a 1-in-32 chance
  $C683,2 $80 + 1 is stored as the count; any value from 4 up would do the same

c $C685 Start a portcullis falling
R $C685 A the number of falls so far
R $C685 HL $5BAF
  $C685,4 one more fall
  $C689,4 type 9: moving
  $C68D,4 dz = -1

@ $C691 label=count_moving_portcullis
c $C691 Count the moving portcullis
D $C691 Sets $5BAF so that no other portcullis in the room starts to move.

c $C692 Mark an object to be wiped and redrawn
D $C692 Sets bit 5 of +$07 (erase the old image) and bit 4 (draw the new one),
. then goes on to #R$CD4D to mark whatever the object overlaps on the screen
. for redrawing too. Nearly every moving object's handler ends here.
R $C692 IX the object's record

c $C69D Mark the object at IY to be wiped and redrawn
D $C69D #R$C692 for the record at IY instead of IX, with both preserved. Used
. when an object is picked up (#R$C141).
R $C69D IY the object's record

c $C6AD Start a portcullis rising
D $C6AD Only on one frame in 32 or so, chosen by the random seed.
  $C6AD,6 a 1-in-32 chance
  $C6B3,4 type 9: moving
  $C6B7,4 dz = +1

c $C6BD A moving portcullis (type 9)
D $C6BD Rising, it climbs one unit a frame with a sound whose pitch follows its
. height, until it is more than 31 above the floor. Falling, it gets an extra
. unit of downward speed each frame on top of gravity, so it falls with twice
. the pull of anything else, and lands with a crash of noise. While it moves
. it has bit 7 of +$0D set, which passes the deadly mark (bit 6) to whatever it
. moves into: a falling portcullis kills. It stays still while the player is
. settling into the room.
R $C6BD IX the portcullis's record
  $C6BD,3 draw 12 left and 6 down
  $C6C0,4 deadly to what it moves into
  $C6C4,6 wait while the player's +$0C counts down after entering the room
  $C6CA,7 rising
  $C6D1,6 extra speed down, then gravity and move
  $C6D7,6 not landed yet
  $C6DD,3 the crash: noise from bytes of the ROM chosen by the seed and the frame counter

c $C6E0 Stop a portcullis
D $C6E0 Frees the room for another portcullis to move and makes this one
. type 8 again.
  $C6E0,4 no portcullis moving
  $C6E4,4 type 8: at rest

c $C6EA Raise a portcullis
D $C6EA dz of 2 less one for gravity: one unit a frame upwards.
  $C6EA,4 dz = 2
  $C6EE,3 a sound whose pitch follows its height
  $C6F1,3 gravity, then move
  $C6F4,10 still at or below the floor + 31: keep going

c $C700 Apply gravity and move
D $C700 Takes one off dz, then lets #R$CB45 cut the velocity down to what the
. room's walls and floor and the other objects allow (and set the blocked bits
. in +$0C), and moves the object by what is left.
R $C700 IX the object's record

c $C706 Move by the velocity
D $C706 Adds dx, dy and dz (+$09 to +$0B) to x, y and z (+$01 to +$03).
R $C706 IX the object's record

c $C722 The second pillar of an arch (types 3 and 5)
D $C722 An arch is two pillars, built together from one background entry
. (#R$6CE2). This one only needs its drawing offset: X -9, Y -3, or X -7, Y -2
. when mirrored. The work of the doorway is done by the other pillar
. (#R$C73C).
R $C722 IX the pillar's record
  $C722,9 mirrored for the arches in the north and south walls

c $C72B Set the drawing offset
R $C72B L the X offset in pixels, stored at +$12
R $C72B H the Y offset in pixels, stored at +$13
R $C72B IX the object's record
D $C72B The end of all the offset routines; see #R$C4D3.

c $C732 The second pillar, mirrored
D $C732 X -7, Y -2.

c $C737 The first pillar of a tree arch, facing east or west
D $C737 Type 4 uses X +1, Y -3 where the stone arch's type 2 uses X -7, Y -3;
. the doorway itself is worked out the same way.

c $C73C The first pillar of an arch (types 2 and 4)
D $C73C This pillar handles the doorway. It works out the point in the middle of
. the arch, 13 units from itself, and keeps it in its own +$09 to +$0B -- the
. velocity fields, which an arch never needs, borrowed because #R$C7FE compares
. +$09 to +$0B of one record with +$01 to +$03 of another. Then two passes
. over the player: #R$C7DB, which marks it as allowed to leave the room if it
. is right in the doorway, and #R$C785, which nudges it towards the arch's
. centre line if it is anywhere near.
D $C73C Arches in the north and south walls are mirrored (bit 6 of +$07) and
. lead along y; those in the east and west walls are not, and lead along x.
R $C73C IX the pillar's record
  $C73C,6 north or south wall
  $C742,7 a tree arch has its own offset

@ $C74C label=arch_ew_doorway
c $C74C The middle of an east or west arch
D $C74C The other pillar is 13 further along y; the doorway is 15 deep (along x)
. and 6 either side of the middle (along y).
  $C74C,3 the drawing offset in HL
  $C74F,8 y of the middle: this pillar's y + 13
  $C757,6 x of the middle: this pillar's
  $C75D,3 the doorway: x within 15, y within 6

@ $C760 label=arch_check_doorway
c $C760 Check the player against the doorway
  $C760,6 z of the middle: the pillar's base
  $C766,3 in the doorway: may leave the room
  $C769,3 near it: nudge towards the middle

c $C76C The first pillar, mirrored: a north or south arch
D $C76C X -17, Y -2. The other pillar is 13 back along x; the doorway is 15
. deep along y and 6 either side along x.
  $C76C,6 the drawing offset
  $C772,8 x of the middle: this pillar's x - 13
  $C77A,6 y of the middle: this pillar's
  $C780,3 the doorway: x within 6, y within 15

@ $C785 label=arch_nudge_to_centre
c $C785 Nudge the player towards the middle of an arch
D $C785 For each of records 0 to 3 with bit 3 of +$07 set -- only the player's
. two records have it -- within 15 of the arch's middle along both x and y
. and within 4 of its z, set a nudge of one unit towards the centre line.
. The nudge goes in +$0E (x) or +$0F (y), which the player's movement adds to
. its velocity (#R$C9FB) when it next walks. This is why the knight slides
. into line with an arch as he walks through.
R $C785 IX the pillar's record, holding the arch's middle at +$09 to +$0B
  $C785,3 15 either way along x and y
  $C788,9 records 0 to 3

@ $C791 label=arch_nudge_loop
c $C791 Nudge one record
  $C791,6 empty record
  $C797,6 not one that uses arches
  $C79D,5 not near
  $C7A2,7 which way the arch runs: #R$CA17 reads the mirror bit of the arch at IX, giving entry 0 or 2

b $C7A9 How to nudge, by the arch's direction
D $C7A9 Four words indexed as the player's facing would be; an arch only ever
. produces 0 (east or west wall, not mirrored) or 2 (north or south, mirrored).
W $C7A9,4 East or west arch: nudge along y
W $C7AD,4 North or south arch: nudge along x

c $C7B1 Nudge along y, for an east or west arch
R $C7B1 IX the arch's record
R $C7B1 IY the player's record
  $C7B1,8 already on the centre line
  $C7B9,6 +1 if the middle is at a greater y, else -1

@ $C7BF label=nudge_y_store
c $C7BF Store the y nudge
  $C7BF,3 the y nudge

c $C7C4 Nudge along x, for a north or south arch
R $C7C4 IX the arch's record
R $C7C4 IY the player's record
  $C7C4,8 already on the centre line
  $C7CC,6 +1 if the middle is at a greater x, else -1

@ $C7D2 label=nudge_x_store
c $C7D2 Store the x nudge
  $C7D2,3 the x nudge

@ $C7D5 label=arch_nudge_done
c $C7D5 Nudge done
D $C7D5 Recovers the loop counter pushed at #R$C791.

@ $C7D6 label=arch_nudge_next
c $C7D6 Next record to nudge
  $C7D6,5 32 bytes on, four records

c $C7DB Is the player in the doorway?
D $C7DB For each of records 0 to 3 that is in use and has bit 3 of +$07 set (the
. player's two records), sets bit 0 of +$07 if it is within the doorway's
. limits. #R$CA70 will let the player leave the room only while that bit is
. set, and clears it when it does.
R $C7DB IX the pillar's record, holding the arch's middle at +$09 to +$0B
R $C7DB L how near along x
R $C7DB H how near along y
  $C7DB,9 records 0 to 3

@ $C7E4 label=near_arch_loop
c $C7E4 Check one record against the doorway
  $C7E4,6 empty record
  $C7EA,6 not one that uses arches
  $C7F0,5 not in the doorway
  $C7F5,4 in the doorway: allowed to leave

@ $C7F9 label=near_arch_next
c $C7F9 Next record for the doorway check

c $C7FE Is an object near a point?
R $C7FE IX a record whose +$09 to +$0B hold the point's x, y and z
R $C7FE IY the object's record
R $C7FE L the limit along x
R $C7FE H the limit along y
R $C7FE F on exit, carry set if the object's x, y and z are all within the limits (z within 4)
  $C7FE,10 the distance along x

@ $C808 label=near_check_y
c $C808 Within the limit along x?
  $C808,2 no: carry clear
  $C80A,10 the distance along y

@ $C814 label=near_check_z
c $C814 Within the limit along y?
  $C814,2 no: carry clear
  $C816,10 the distance along z

@ $C820 label=near_z_compare
c $C820 Within 4 along z?
  $C820,3 carry set if so

c $C823 The knight's legs (types 16 to 21 and 24 to 29)
D $C823 Sets the drawing offset and goes into the player's handler
. (#R$C82B).
  $C823,3 draw 12 left and 6 down

c $C828 The werewolf's legs (types 48 to 53 and 56 to 61)
D $C828 One pixel lower than the knight's, then the same handler, which follows.
  $C828,3 draw 12 left and 7 down

# --------------------------------------------------------------------------
# The player, leaving a room, collision
# --------------------------------------------------------------------------

# Knight Lore, part 6: $C82B-$CD32 -- the player's legs, turning, jumping,
# walking, leaving a room, and the collision system every moving object uses.
#
# Object record fields named below (offsets into a 32-byte record): +$00 type,
# +$01/+$02/+$03 X/Y/Z (Z is the base of the object, up is larger), +$04/+$05
# half-width in X and Y, +$06 full height, +$07 flags, +$08 room, +$09/+$0A/+$0B
# this frame's dX/dY/dZ, +$0C movement flags, +$0D contact flags,
# +$0E/+$0F a nudge to add to dX/dY. See kl_notes_6.md for the bits.

# --------------------------------------------------------------------------
# The player, bottom half
# --------------------------------------------------------------------------

c $C82B Update the player's legs
D $C82B The handler for the bottom of the two records that make up the player:
. the legs, whose box is the whole knight's for collisions. #R$C823 and #R$C828
. arrive here for the man and for the werewolf. IX is always the first object
. record, $5C08, and the top half is the record after it.
D $C82B First, death: bit 6 of +$0D is set by the collision code when the player
. touches something harmful. Unless the end-of-game sequence is running ($5BC3),
. the legs and the top half both turn into the death sparkle.
R $C82B IX the player's bottom record
  $C82B,6 has something harmful touched us?
  $C831,6 not once the game has been won: nothing kills the player then
  $C837,4 mark the top half (the next record) dead too
  $C83B,3 and become the death sparkle

@ $C83E label=player_controls
c $C83E Read the controls and act on them
D $C83E The player's turn, in order: change between man and werewolf if the sun
. or moon says so, read the controls into C (bit 0 left, 1 right, 2 forward or
. up, 3 jump, 4 pick up or drop, or down on a joystick), pick up or drop, turn,
. jump, and step the legs. Then, if the player is standing in a doorway -- past
. the line of the room's walls -- #R$C86D forbids any upward movement before
. the move is made.
  $C83E,3 day or night may change the player's form
  $C841,3 C = the controls this frame
  $C847,9 turn, jump, and walk
  $C850,5 no carry: in a doorway, beyond the walls

@ $C855 label=player_move_and_draw
c $C855 Move the player and count down the room-entry walk
D $C855 Moves the player through #R$C9A1. For the length of the move the top
. half's "ignore me" bit is set, so the collision scan does not find the
. player's own head in the way of its legs.
D $C855 The top nibble of +$0C is a count set to 3 by #R$CABA when the player
. walks into a new room; while it runs the controls are ignored and the player
. walks straight on. It drops by one here each frame.
  $C855,4 top half out of the collision scan...
  $C859,3 move
  $C85C,4 ...and back in
  $C860,10 count the room-entry walk down, unless it is already zero

@ $C86A label=player_redraw
c $C86A Have the player redrawn
D $C86A Hands over to #R$C692, which marks the player to be wiped and redrawn,
. and which returns to the object loop.

c $C86D In a doorway: allow no rising
D $C86D Reached when #R$C87A finds the player at or beyond the line of a wall,
. which in practice means in an archway. A falling player keeps falling, but
. any upward speed -- a jump just started included -- is cancelled, so the player
. cannot rise inside a doorway. Then on to the move.
  $C86D,7 dZ negative: falling is fine
  $C874,4 otherwise no vertical movement at all
  $C878,2 move

c $C87A Is the player inside the room's walls?
D $C87A Compares the player's distance from the room's centre, $80 on each axis,
. with the room's half-size less the player's own half-width. Carry means the
. whole of the player's footprint is inside on both X and Y; no carry means it
. touches or crosses the line of a wall, which only an archway allows.
D $C87A Also used by #R$C00E.
R $C87A IX the player's bottom record
R $C87A F carry set on exit if inside the walls
  $C87A,13 L = X half-size less our half-width, H = the same for Y
  $C887,10 A = |X - $80|

@ $C891 label=oob_test_x
c $C891 Test X, then work out the Y distance
D $C891 Part of #R$C87A: fails (no carry) if the X distance is too great,
. otherwise measures the Y distance.
  $C891,2 too far from the centre in X: no carry
  $C893,10 A = |Y - $80|

@ $C89D label=oob_test_y
c $C89D Test Y
D $C89D The last step of #R$C87A: carry if the Y distance is inside the room.

# --------------------------------------------------------------------------
# Turning
# --------------------------------------------------------------------------

c $C89F Turn the player
D $C89F Two control schemes. Rotational control, the only one the keyboard has,
. uses left and right to turn a quarter at a time: see #R$C8F2. Directional
. control, which a joystick gets when option 5 on the menu is on (bit 3 of
. $5BA4), treats the stick as four compass points: pushing one turns the
. player towards it and, once facing it, walks that way.
D $C89F In directional mode nothing happens during the room-entry walk or in
. the air -- bit 2 of +$0C, set by the collision code when a downward move is
. stopped, is what "standing on something" means here. Otherwise the stick
. is read in the order up (unless left is also held), right, down, left.
R $C89F C the controls: bit 0 left, 1 right, 2 up, 3 jump, 4 down
R $C89F C on exit, bit 2 set if the player should walk forward
  $C89F,8 bits 1-2 of $5BA4 are the control method; 0, the keyboard, is always rotational
  $C8A7,4 directional control switched off
  $C8AB,6 not during the room-entry walk
  $C8B1,5 not in the air
  $C8B6,8 left pressed: skip the test for up; up: face N

@ $C8BE label=directional_pick
c $C8BE Directional control: right, down or left
D $C8BE The rest of the stick in #R$C89F: right faces E, down faces S, left
. faces W. With nothing pressed, no walking.
  $C8BE,4 right: E
  $C8C2,4 down: S
  $C8C6,4 left: W
  $C8CA,3 nothing: stand still

c $C8CD Directional control: face N
D $C8CD Facing codes, from #R$CA1E: 0 W, 1 E, 2 N, 3 S. If already facing N
. the player walks; if not, #R$C8D5 picks the shorter way round -- a right
. turn from W, a left turn from E, and from S a left turn now and another on
. the next frame.
  $C8CD,5 facing N is code 2

@ $C8D2 label=chk_facing_ne_result
c $C8D2 Directional control: walk, or turn towards N or E
D $C8D2 Shared by #R$C8CD and #R$C8D9. Zero means the player already faces the
. way the stick points. Otherwise the facing code is inverted, so that bit 0
. is set for the facings from which a right turn is the short way.
  $C8D2,2 already facing that way: walk
  $C8D4,1 flip bit 0 for #R$C8D5

@ $C8D5 label=turn_by_parity
c $C8D5 Directional control: turn left or right
D $C8D5 Bit 0 of A chooses: set for a right turn, clear for a left. The turn
. itself is #R$C91F, which does it at once, without the pause and the sound
. that rotational turning has.
  $C8D5,4 Z for left, NZ for right

c $C8D9 Directional control: face E
D $C8D9 As #R$C8CD for E, code 1: right from W (via N) and N, left from S.
  $C8D9,7 facing E is code 1

c $C8E0 Directional control: face S
D $C8E0 As #R$C8CD for S, code 3. Here the code is used as it is: left from W,
. right from E, and from N a left turn now (to W) and another next frame.
  $C8E0,5 facing S is code 3

@ $C8E5 label=chk_facing_sw_result
c $C8E5 Directional control: walk, or turn towards S or W
D $C8E5 Shared by #R$C8E0 and #R$C8E9: walk if already facing that way, or
. turn by bit 0 of the facing code without inverting it.
  $C8E5,4 already facing: walk; otherwise turn

c $C8E9 Directional control: face W
D $C8E9 As #R$C8CD for W, code 0: left from N, right from S, and from E a right
. turn to S now and another to W on the next frame.
  $C8E9,6 facing W is code 0

c $C8EF Directional control: walk
D $C8EF The player already faces the way the stick is pushed, so set the
. "forward" bit for #R$C969 and #R$C9A1.

c $C8F2 Rotational control: turn a quarter
D $C8F2 Left and right turn the player a quarter at a time: right goes W, N, E,
. S (clockwise), left the other way. Bits 0-2 of +$0D are a pause between
. turns; while it counts down nothing else happens here, so holding a key
. turns the player once every third frame rather than every frame.
R $C8F2 C the controls: bit 0 left, 1 right, 2 forward
  $C8F2,7 pause still running?
  $C8F9,4 count it down and do nothing else

@ $C8FD label=rotational_turn
c $C8FD Rotational control: start a turn
D $C8FD A turn needs left or right held, the room-entry walk over, and no jump
. in progress. It makes a sound of its own only when the player is not also
. walking -- the footstep covers it otherwise.
  $C8FD,4 neither left nor right
  $C901,6 not during the room-entry walk
  $C907,5 not in the middle of a jump
  $C90C,9 turning on the spot: the turning sound

@ $C915 label=start_turn_delay
c $C915 Rotational control: set the pause and choose the direction
D $C915 Sets the pause between turns (two frames' wait) and leaves NZ for a right
. turn, Z for a left one, for #R$C91F.
  $C915,8 bit 1 of the pause count
  $C91D,2 NZ: right

c $C91F Turn the player one quarter
D $C91F How a facing is stored explains the shape of this. Bit 3 of the type
. chooses the sprite seen from behind (clear: W or N) or from the front (set: E
. or S), and bit 6 of +$07 mirrors it (clear: W or E; set: N or S). A quarter
. turn always toggles the mirror bit; half the time it also toggles the view.
. For a left turn that is when the sprite is not mirrored.
R $C91F F Z for a left turn, NZ for a right turn
  $C91F,2 right turn
  $C921,6 left: mirrored sprites only change mirror (N to W, S to E)

@ $C927 label=turn_toggle_view
c $C927 Turn: change between back and front view
D $C927 Toggles bit 3 of the type -- behind to in front, or back -- and goes on
. to toggle the mirror bit too.
  $C927,8 type bit 3: back or front view

@ $C92F label=turn_toggle_mirror
c $C92F Turn: mirror the sprite, and turn the top half to match
D $C92F Toggles the mirror bit, then sets the top half's type to the legs' type
. plus 16 so the body turns in the same frame; #R$CDE2 would otherwise only
. catch up on its own update.
  $C92F,8 mirror bit
  $C937,9 top half's type = our type + 16

@ $C940 label=turn_right
c $C940 Turn right
D $C940 A right turn toggles the view as well only when the sprite is already
. mirrored (N to E, S to W); from W or E it only mirrors (to N or S).
  $C940,8 mirrored: view and mirror; otherwise mirror only

# --------------------------------------------------------------------------
# Jumping and walking
# --------------------------------------------------------------------------

c $C948 Start a jump
D $C948 Jump starts only when the jump control is held, the room-entry walk is
. over, no jump is already in progress (bit 3 of +$0C, cleared on landing by
. #R$C9CD), and the player is not already falling. The launch speed is 8 units
. up; #R$C9C1 then takes it away again frame by frame.
D $C948 The test is on the speed, not on standing: a dZ of -1 or more is enough,
. and the collision code leaves dZ at 0 for a player on the ground.
R $C948 C the controls
  $C948,3 jump not held
  $C94B,6 not during the room-entry walk
  $C951,5 not while a jump is in progress
  $C956,5 dZ -2 or less: already falling
  $C95B,8 jumping, 8 units a frame upwards
  $C963,6 the jump sound; C, the controls, kept

c $C969 Step the legs
D $C969 While the player is walking forward, jumping, or on the room-entry walk,
. the legs cycle and a footstep sounds. When none of those applies the legs do
. not simply stop: #R$C994 carries the stride on to one of the two standing
. frames.
R $C969 C the controls
  $C969,13 room-entry walk or jump: step
  $C976,4 forward not held: finish the stride

@ $C97A label=walk_step_sound
c $C97A Footstep, then the next leg frame
D $C97A The footstep sound (#R$B4BB), then #R$C97F.
  $C97A,5 C, the controls, kept

c $C97F Next frame of a walk cycle
D $C97F The low three bits of the type are the frame of a six-frame walk
. cycle; this steps to the next, wrapping 5 to 0. Also used by #R$B71A.
R $C97F IX the object
  $C97F,12 frame + 1, and 6 wraps to 0

@ $C98B label=store_leg_frame
c $C98B Store the new leg frame
D $C98B Puts the new frame into the low three bits of the type.
  $C98B,9 keep the type's other bits

@ $C994 label=legs_to_rest
c $C994 Bring the legs to rest
D $C994 Frames 2 and 4 are the two standing poses. From any other frame the
. cycle carries on, silently, until it reaches one.
  $C994,11 standing already
  $C99F,2 keep stepping

# --------------------------------------------------------------------------
# Moving
# --------------------------------------------------------------------------

c $C9A1 Move the player
D $C9A1 Works out this frame's move, has the collision code cut it short where
. it must, lets the player leave the room if that is what the move does, and
. applies it.
D $C9A1 While an object is floating up into the wizard's cauldron ($5BC4 set)
. the controls are off and dZ is forced to 2 here, which the two units of
. gravity below bring back to 0: the player hangs where he is.
R $C9A1 IX the player's bottom record
R $C9A1 C the controls
  $C9A1,10 an object on its way into the cauldron: hold the player still

@ $C9AB label=move_player_xy
c $C9AB Is the player moving forward?
D $C9AB The player moves in the direction he faces when forward is held, and
. also, without it, throughout a jump and during the room-entry walk.
  $C9AB,17 jumping, entering a room, or forward held

@ $C9BC label=move_player_walk
c $C9BC Take a step forward
D $C9BC #R$C9FB adds a step in the facing direction to dX and dY.
  $C9BC,5 C, the controls, kept

@ $C9C1 label=apply_gravity
c $C9C1 Gravity
D $C9C1 Gravity takes 2 from dZ every frame. The exception is a player going up
. or level with jump still held, who loses only 1: holding jump makes a higher,
. slower jump. Nothing limits the speed of a fall.
  $C9C1,11 rising and jump held: one unit only

@ $C9CC label=gravity_extra
c $C9CC Gravity's second unit
D $C9CC The extra unit taken off for a player falling, or not holding jump.

@ $C9CD label=move_player_apply
c $C9CD Resolve and apply the move
D $C9CD Stores the new dZ, and keeps a copy in $5BC1: the collision code will
. shorten dZ, and the copy is what says afterwards which way the player was
. trying to go. A fall faster than two units a frame has a sound pitched by the
. height.
D $C9CD Then #R$CB45 shortens the move against the walls and the other objects,
. #R$CA70 checks for a walk out of the room (and does not come back if there
. is one), and #R$C706 adds what is left to the position. A move downwards
. that was stopped (bit 2 of +$0C) is a landing, and ends the jump.
  $C9CD,1 the first unit
  $C9CE,6 new dZ, and the intended dZ in $5BC1
  $C9D4,5 falling faster than 2: the falling sound
  $C9D9,3 cut the move short where it must be
  $C9DC,3 out of the room?
  $C9DF,3 X, Y, Z += dX, dY, dZ
  $C9E2,13 stopped while moving down?
  $C9EF,4 then landed: the jump is over

c $C9F3 Clear dX and dY
D $C9F3 dX and dY are one frame's movement, so once applied they go back to
. zero. Also the end of several other objects' updates.

c $C9FB Add a step in the facing direction
D $C9FB First adds in the nudge in +$0E and +$0F, which an archway leaves there
. (#R$C791) to steer the player towards the middle of the arch, and clears
. it. Then dispatches on the facing to add 3 units in that direction. The
. nudge is only ever used when the player is walking.
  $C9FB,18 dX += nudge X, dY += nudge Y
  $CA0D,7 the nudge is used up
  $CA14,3 the table of steps, #R$CA32

@ $CA17 label=dispatch_on_facing
c $CA17 Jump by the object's facing
D $CA17 Jumps to the entry in the table of four addresses at BC chosen by the
. facing of the object at IX, in the order W, E, N, S. Used for the player's
. step (#R$CA32), for leaving a room (#R$CA92), and by the archways
. (#R$C791), which have facings of their own.
R $CA17 BC a table of four routine addresses
R $CA17 IX the object
  $CA17,7 A = 0 W, 1 E, 2 N, 3 S

c $CA1E Which way does the object face?
D $CA1E Builds the facing code from the two bits that store it: bit 6 of +$07
. (the sprite is mirrored) becomes bit 1, and bit 3 of the type (front view)
. becomes bit 0. So 0 is W, 1 E, 2 N and 3 S.
R $CA1E IX the object
R $CA1E A on exit, the facing: 0 W, 1 E, 2 N, 3 S
  $CA1E,8 mirror bit to bit 4
  $CA26,5 with type bit 3
  $CA2B,7 down to bits 1 and 0

@ $CA32 label=walk_step_tbl
b $CA32 A step in each direction
D $CA32 Four addresses, one per facing, used through #R$CA17 by #R$C9FB. Each
. adds 3 to or takes 3 from dX or dY: X grows eastwards and Y northwards.
W $CA32,2 W: dX - 3
W $CA34,2 E: dX + 3
W $CA36,2 N: dY + 3
W $CA38,2 S: dY - 3

c $CA3A Step west
D $CA3A dX - 3.
  $CA3A,5 -3

@ $CA3F label=store_plyr_dX
c $CA3F Store dX
D $CA3F Shared end of #R$CA3A and #R$CA43.

c $CA43 Step east
D $CA43 dX + 3.
  $CA43,7 +3

c $CA4A Step north
D $CA4A dY + 3.
  $CA4A,5 +3

@ $CA4F label=store_plyr_dY
c $CA4F Store dY
D $CA4F Shared end of #R$CA4A and #R$CA53.

c $CA53 Step south
D $CA53 dY - 3.
  $CA53,7 -3

# --------------------------------------------------------------------------
# The floor
# --------------------------------------------------------------------------

c $CA5A Shorten dZ at the floor
D $CA5A The floor is the only limit on Z: there is no ceiling. $5BAE holds the
. floor's height, $80 in all three room sizes. A move that would take the
. object's base below it is shortened a unit at a time until it would not, and
. bit 2 of +$0C records that the move was stopped.
R $CA5A IX the object
R $CA5A H dZ
R $CA5A H on exit, dZ shortened
  $CA5A,4 D = the floor

@ $CA5E label=clip_dZ_to_floor
c $CA5E Shorten dZ at the floor: the loop
D $CA5E The loop for #R$CA5A.
  $CA5E,6 Z + dZ at or above the floor: done
  $CA64,4 stopped in Z
  $CA68,7 one unit shorter, and try again unless nothing is left
  $CA6F,1 no move left

# --------------------------------------------------------------------------
# Leaving the room
# --------------------------------------------------------------------------

c $CA70 Has the player walked out of the room?
D $CA70 A room can be left only through an archway, and only walking the way
. the player faces. An archway sets bit 0 of +$07 on the player while he is
. close to it (#R$C7DB); this clears it and dispatches through #R$CA92 on the
. facing. Each of the four routines there decides whether this frame's move
. carries the player wholly past the line of the wall.
D $CA70 The room's half-sizes from $5BAB are pushed for them, because the
. dispatch uses HL.
R $CA70 IX the player's bottom record
  $CA70,6 not during the room-entry walk
  $CA76,9 not near an archway; the flag is used once
  $CA7F,10 the room's X and Y half-sizes, for the exit routines

@ $CA89 label=shorten_delta
c $CA89 Shorten a movement by one unit
D $CA89 Moves A one step towards zero -- down if positive, up if negative -- and
. leaves Z set if nothing is left. Every loop in the collision code uses it to
. cut a move short one unit at a time and try again.
R $CA89 A a dX, dY or dZ
R $CA89 A on exit, one unit closer to zero; Z set if zero
  $CA89,2 already zero
  $CA8B,5 negative: +2 and then -1

@ $CA90 label=shorten_delta_dec
c $CA90 Shorten a movement: subtract one
D $CA90 The DEC that sets the zero flag for #R$CA89.

b $CA92 Leaving a room, by facing
D $CA92 Four addresses in facing order, used through #R$CA17 by #R$CA70.
W $CA92,2 W: #R$CA9A
W $CA94,2 E: #R$CAF3
W $CA96,2 N: #R$CB0E
W $CA98,2 S: #R$CB29

c $CA9A Leave by the west wall?
D $CA9A Out if the player's east edge, after this frame's move, is west of the
. west wall at $80 less the room's X half-size. The new room is one west: the
. low nibble of the room number less one, wrapping within its row.
D $CA9A X is set to 0, which is not a position but a marker: #R$D320 sees it
. when the new room is built and puts the player in the doorway of that room's
. east wall, at the height of the arch there. The Y markers work the same way, $FF for the south wall and 0 for the
. north.
R $CA9A HL the room's half-sizes (pushed by #R$CA70)
  $CA9A,5 L = the west wall
  $CA9F,11 X + dX + half-width still at or beyond it: stay
  $CAAA,4 arrive at the east wall
  $CAAE,5 room - 1

@ $CAB3 label=screen_e_w
c $CAB3 Keep an east-west move within the row
D $CAB3 Room numbers are a row in the high nibble and a column in the low. The
. column is changed on its own so that it wraps without disturbing the row.
  $CAB3,7 the new column with the old row

c $CABA Go into the next room
D $CABA Gives the object its new room number and starts the room-entry walk:
. 3 in the top nibble of +$0C, three frames of walking straight in with the
. controls and the room's walls ignored, so the player clears the archway.
D $CABA For the player -- type 16 to 79, both forms and both halves -- the rest
. of this frame is abandoned. The two return addresses on the stack, to
. #R$C9CD and #R$C855, are dropped, and both player records are copied to
. #R$D161 and #R$D181: the player as he entered this room, which #R$D12A
. copies back when a life is lost, so he reappears at the door he came in by.
. The copies' types are replaced by 120, the first frame of the materialising
. sparkle, with the real types kept in +$10 for #R$BF11 to restore. Then the
. new room is built from #R$AFBA.
D $CABA Only the player reaches this code in this build, so the return for other
. types is never taken.
R $CABA A the new room number
  $CABA,3 new room
  $CABD,8 the room-entry walk: three frames
  $CAC5,8 anything but the player: carry on
  $CACD,4 drop the returns to the rest of this frame
  $CAD1,11 both player records to the respawn copy
  $CADC,12 each copy's real type kept in its +$10
  $CAE8,8 and replaced by the materialising sparkle
  $CAF0,3 build the new room and start its frames

c $CAF3 Leave by the east wall?
D $CAF3 As #R$CA9A the other way: out if the west edge after the move is at or
. past the east wall at $80 plus the X half-size. X is set to the marker $FF
. (arrive at the west wall) and the room number goes up one within the row.
R $CAF3 HL the room's half-sizes (pushed by #R$CA70)
  $CAF3,5 L = the east wall
  $CAF8,11 X + dX - half-width short of it: stay
  $CB03,4 arrive at the west wall
  $CB07,7 room + 1

c $CB0E Leave by the north wall?
D $CB0E Out if the south edge after the move is at or past the north wall at
. $80 plus the Y half-size. Y becomes the marker $FF (arrive at the south
. wall) and the room number goes up a row, 16.
R $CB0E HL the room's half-sizes (pushed by #R$CA70)
  $CB0E,5 H = the north wall
  $CB13,11 Y + dY - half-depth short of it: stay
  $CB1E,4 arrive at the south wall
  $CB22,7 room + 16

c $CB29 Leave by the south wall?
D $CB29 Out if the north edge after the move is south of the south wall at $80
. less the Y half-size. Y becomes the marker 0 (arrive at the north wall) and
. the room number goes down a row.
R $CB29 HL the room's half-sizes (pushed by #R$CA70)
  $CB29,5 H = the south wall
  $CB2E,11 Y + dY + half-depth still at or beyond it: stay
  $CB39,4 arrive at the north wall
  $CB3D,8 room - 16

# --------------------------------------------------------------------------
# Collisions
# --------------------------------------------------------------------------

c $CB45 Cut a move short against the room and the other objects
D $CB45 Every moving object's move comes through here, the player's from
. #R$C9CD and everyone else's from #R$C700. It takes dX, dY and dZ from the
. record and shortens each where the object would otherwise end up inside the
. floor, a wall, or another object, then writes them back.
D $CB45 The axes are done one at a time, Z first, then X, then Y, and each test
. uses the moves already accepted on the earlier axes (the later ones count as
. zero). That is what lets a blocked move slide: walking diagonally into a wall
. keeps the part of the move that runs along it.
D $CB45 While it works, bit 1 of the object's +$07 is set, which is what makes
. the object scans (#R$B538) pass over the object itself; found already set,
. it means the object is not to be moved this way at all. Bits 0-2 of +$0C
. are cleared at the start and set for each axis whose move was cut.
R $CB45 IX the object
  $CB45,9 not for objects marked to be ignored; and ignore ourself while we work
  $CB4E,8 clear the three "stopped" bits
  $CB56,3 dY and dX count as zero while Z is tested
  $CB59,7 H = dZ; nothing to do if zero
  $CB60,7 the floor first; nothing left means no objects to test
  $CB67,3 then the other objects

c $CB6A Cut a move short: X
D $CB6A The X part of #R$CB45, with C as the working dX. dZ is final by now,
. and may have been changed by landing on a moving object (#R$CC4D), so dX is
. read from the record only here.
  $CB6A,7 C = dX; nothing to do if zero
  $CB71,7 the walls first; nothing left means no objects to test
  $CB78,3 then the other objects

@ $CB7B label=dX_done
c $CB7B Cut a move short: Y
D $CB7B The Y part of #R$CB45, with L as the working dY and the final dX and dZ
. in C and H.
  $CB7B,7 L = dY; nothing to do if zero
  $CB82,7 the walls first; nothing left means no objects to test
  $CB89,3 then the other objects

@ $CB8C label=store_clipped_move
c $CB8C Store the move as cut
D $CB8C Writes back the three shortened movements and takes the object's
. "ignore me" bit off again.
  $CB8C,9 dX, dY, dZ
  $CB95,5 other objects' scans may find us again

c $CB9A Shorten dX against the other objects
D $CB9A Tries the object's box against every one of the forty records. For
. each one it already overlaps in Y and Z -- with the moves accepted so far --
. an overlap in X after the move means dX has to be shortened, a unit at a
. time, until the boxes no longer meet. If dX reaches zero the scan stops.
D $CB9A Every such meeting also passes harm between the two (see #R$CBAF) and,
. if the obstacle can be pushed (bit 2 of its +$07), gives it the mover's
. whole intended dX, so it moves off on its own next update.
R $CB9A IX the moving object
R $CB9A C dX
R $CB9A L dY so far (zero)
R $CB9A H dZ as accepted
R $CB9A C on exit, dX shortened
  $CB9A,6 IY = the first record; forty of them

@ $CBA0 label=dX_obj_loop
c $CBA0 Shorten dX: is this object in line?
D $CBA0 Skips empty records and those marked to be ignored, and those not
. overlapping in Y and in Z. Only an object in line on both can stop an X move.
  $CBA0,5 empty, or marked to be ignored
  $CBA5,10 not overlapping in Y or not in Z

@ $CBAF label=dX_obj_hit_test
c $CBAF Shorten dX: does the move hit it?
D $CBAF If the boxes would overlap in X too, the move is stopped (bit 0 of
. +$0C) and harm passes. Bit 6 of +$0D means "has been harmed": the obstacle
. gets it if the mover has bit 7 (harms what it runs into), and the mover
. gets it if the obstacle has bit 5 (harms what runs into it). This is how
. the player dies of a guard or of spikes: #R$C82B watches bit 6.
  $CBAF,5 no overlap in X: next object
  $CBB4,4 stopped in X
  $CBB8,12 mover's bit 7 becomes the obstacle's bit 6
  $CBC4,9 obstacle's bit 5 becomes the mover's bit 6
  $CBCD,12 a pushable obstacle takes on our dX

@ $CBD9 label=dX_obj_shorten
c $CBD9 Shorten dX by one and try the same object again
D $CBD9 Returns from the whole scan once nothing of dX is left.
  $CBD9,8 shorter by a unit; none left, done

@ $CBE1 label=dX_obj_next
c $CBE1 Shorten dX: the next object
D $CBE1 Steps IY on to the next 32-byte record.
  $CBE1,8 next of forty

c $CBE9 Shorten dY against the other objects
D $CBE9 #R$CB9A for Y: an object has to overlap in X (after the accepted dX)
. and in Z to be in the way. Stopping sets bit 1 of +$0C.
R $CBE9 IX the moving object
R $CBE9 L dY
R $CBE9 C dX as accepted
R $CBE9 H dZ as accepted
R $CBE9 L on exit, dY shortened
  $CBE9,6 IY = the first record; forty of them

@ $CBEF label=dY_obj_loop
c $CBEF Shorten dY: is this object in line?
D $CBEF Skips empty and ignored records, and those not overlapping in X and Z.
  $CBEF,5 empty, or marked to be ignored
  $CBF4,10 not overlapping in X or not in Z

@ $CBFE label=dY_obj_hit_test
c $CBFE Shorten dY: does the move hit it?
D $CBFE As #R$CBAF, for Y: stopped in Y is bit 1 of +$0C, harm passes the same
. way, and a pushable obstacle takes on the mover's dY.
  $CBFE,5 no overlap in Y: next object
  $CC03,4 stopped in Y
  $CC07,12 mover's bit 7 becomes the obstacle's bit 6
  $CC13,9 obstacle's bit 5 becomes the mover's bit 6
  $CC1C,12 a pushable obstacle takes on our dY

@ $CC28 label=dY_obj_shorten
c $CC28 Shorten dY by one and try the same object again
D $CC28 Returns from the whole scan once nothing of dY is left.
  $CC28,8 shorter by a unit; none left, done

@ $CC30 label=dY_obj_next
c $CC30 Shorten dY: the next object
D $CC30 Steps IY on to the next 32-byte record.
  $CC30,8 next of forty

c $CC38 Shorten dZ against the other objects
D $CC38 #R$CB9A for Z, done before X and Y so it tests the object where it
. stands: an object has to overlap in X and in Y (with no horizontal move yet)
. to be above or below it. Stopping sets bit 2 of +$0C, whether the move was
. up or down.
R $CC38 IX the moving object
R $CC38 H dZ
R $CC38 C dX, zero here
R $CC38 L dY, zero here
R $CC38 H on exit, dZ shortened
  $CC38,6 IY = the first record; forty of them

@ $CC3E label=dZ_obj_loop
c $CC3E Shorten dZ: is this object above or below?
D $CC3E Skips empty and ignored records, and those not overlapping in X and Y.
  $CC3E,5 empty, or marked to be ignored
  $CC43,10 not overlapping in X or not in Y

@ $CC4D label=dZ_obj_hit_test
c $CC4D Shorten dZ: does the move hit it?
D $CC4D As #R$CBAF, and two things more. The obstacle gets bit 3 of its +$0D:
. something has come down on it (or up against it). A block that gives way
. when stood on, #R$B683, waits for that bit. And a mover that can be carried
. -- bit 2 of +$07, which the player has -- takes on the obstacle's dX and dY
. wherever its own are zero, so standing on something that moves carries it
. along.
  $CC4D,5 no overlap in Z: next object
  $CC52,4 stopped in Z
  $CC56,21 harm passes both ways, as in X
  $CC6B,4 the obstacle has been landed on
  $CC6F,6 not a mover that can be carried
  $CC75,12 no dX of our own: ride with the obstacle's

@ $CC81 label=dZ_ride_dY
c $CC81 Shorten dZ: ride with the obstacle's dY
D $CC81 The Y half of being carried by the object underneath.
  $CC81,12 no dY of our own: ride with the obstacle's

@ $CC8D label=dZ_obj_shorten
c $CC8D Shorten dZ by one and try the same object again
D $CC8D Returns from the whole scan once nothing of dZ is left.
  $CC8D,8 shorter by a unit; none left, done

@ $CC95 label=dZ_obj_next
c $CC95 Shorten dZ: the next object
D $CC95 Steps IY on to the next 32-byte record.
  $CC95,8 next of forty

c $CC9D Do two objects overlap in X?
D $CC9D Boxes are centred on X and Y, with +$04 and +$05 the half-sizes. They
. overlap in X if the distance between the centres, after the mover's dX, is
. less than the two half-widths added: exactly touching is not overlapping.
. Also used by #R$B510 and #R$C17A.
R $CC9D IX the moving object
R $CC9D IY the other object
R $CC9D C the mover's dX
R $CC9D F carry set on exit if they overlap
  $CC9D,7 D = the two half-widths
  $CCA4,12 A = |X + dX - other X|

@ $CCB0 label=intersect_x_result
c $CCB0 Overlap in X: compare
D $CCB0 Carry if the distance is less than the sum.

c $CCB2 Do two objects overlap in Y?
D $CCB2 #R$CC9D for Y, with the mover's dY in L and the half-depths at +$05.
R $CCB2 IX the moving object
R $CCB2 IY the other object
R $CCB2 L the mover's dY
R $CCB2 F carry set on exit if they overlap
  $CCB2,7 D = the two half-depths
  $CCB9,12 A = |Y + dY - other Y|

@ $CCC5 label=intersect_y_result
c $CCC5 Overlap in Y: compare
D $CCC5 Carry if the distance is less than the sum.

c $CCC7 Do two objects overlap in Z?
D $CCC7 Not centred like X and Y: Z is an object's base and +$06 its whole
. height. So the test takes the gap between the two bases and compares it
. with the height of whichever object is lower. The player's top half has
. a height of 0, which is why it is kept out of the scans while the legs move
. (#R$C855): the legs, 23 high, would find it inside them.
R $CCC7 IX the moving object
R $CCC7 IY the other object
R $CCC7 H the mover's dZ
R $CCC7 F carry set on exit if they overlap
  $CCC7,7 A = Z + dZ - other Z
  $CCCE,8 we are the lower one: our height

@ $CCD6 label=intersect_z_result
c $CCD6 Overlap in Z: compare
D $CCD6 Carry if the gap between the bases is less than the lower object's
. height.

@ $CCD8 label=intersect_z_above
c $CCD8 Overlap in Z: the other object is lower
D $CCD8 Uses the other object's height.
  $CCD8,5 its height

c $CCDD Shorten dX at the walls
D $CCDD Keeps the whole of the object's footprint between the room's east and
. west walls, $80 plus and minus the X half-size in $5BAB, shortening dX a unit
. at a time and setting bit 0 of +$0C if it had to.
D $CCDD Two things switch the walls off: the room-entry walk (the top nibble of
. +$0C) and being near an archway (bit 0 of +$07, set by #R$C7DB). That is
. how the player walks into an arch at all -- and why only the arch's own
. pillars, which are objects, then stop him.
R $CCDD IX the object
R $CCDD C dX
R $CCDD C on exit, dX shortened
  $CCDD,6 not during the room-entry walk
  $CCE3,5 not near an archway
  $CCE8,4 B = the X half-size

@ $CCEC label=clip_dX_to_walls
c $CCEC Shorten dX at the walls: distance from the centre
D $CCEC The loop for #R$CCDD, from the distance from the room's centre after
. the move.
  $CCEC,10 A = |X + dX - $80|

@ $CCF6 label=clip_dX_test
c $CCF6 Shorten dX at the walls: test and shorten
D $CCF6 Inside if the distance plus the half-width is less than the half-size.
  $CCF6,6 inside: done
  $CCFC,4 stopped in X
  $CD00,7 one unit shorter, and again unless nothing is left

c $CD07 Shorten dX at the walls: done
D $CD07 The end of #R$CCDD, with C the dX that fits.

c $CD08 Shorten dY at the walls
D $CD08 #R$CCDD for Y: the north and south walls from $5BAC, the half-depth at
. +$05, and bit 1 of +$0C.
R $CD08 IX the object
R $CD08 L dY
R $CD08 L on exit, dY shortened
  $CD08,6 not during the room-entry walk
  $CD0E,5 not near an archway
  $CD13,4 B = the Y half-size

@ $CD17 label=clip_dY_to_walls
c $CD17 Shorten dY at the walls: distance from the centre
D $CD17 The loop for #R$CD08.
  $CD17,10 A = |Y + dY - $80|

@ $CD21 label=clip_dY_test
c $CD21 Shorten dY at the walls: test and shorten
D $CD21 Inside if the distance plus the half-depth is less than the half-size.
  $CD21,6 inside: done
  $CD27,4 stopped in Y
  $CD2B,7 one unit shorter, and again unless nothing is left

c $CD32 Shorten dY at the walls: done
D $CD32 The end of #R$CD08, with L the dY that fits.

# --------------------------------------------------------------------------
# Depth order, input, lives, starting, the panel, arches
# --------------------------------------------------------------------------

# Knight Lore, $CD33-$D3B4: screen rectangles, redraw marking, the player's
# head, the draw list and depth sort, the controls, lives and start, building
# a room, the panel and border, and entering through an arch.

# --------------------------------------------------------------------------
# Where an object is on the screen, and what its move uncovers
# --------------------------------------------------------------------------

c $CD33 Work out an object's screen rectangle
D $CD33 Fills in the four bytes that say where an object's sprite lands in the
. screen buffer: the pixel position at +$1A and +$1B (from #R$D6C9) and the
. size at +$18 (width in bytes) and +$19 (height in pixel rows). The width is
. the sprite's own, plus one byte when the x position is not a multiple of
. eight, because a sprite shifted across a byte boundary spills into the next
. byte.
D $CD33 #R$D6EF also turns the sprite the way the object's flip bits ask
. for. When the object's sprite is the empty one (types 0 and 1 both use it),
. #R$D6EF discards this routine's return address and goes straight back to
. the caller, so the size bytes keep their previous values. That is what an
. object that is vanishing wants: the area it last covered is still the area
. to clear.
R $CD33 IX the object
  $CD33,6 pixel position into +$1A/+$1B; DE = the sprite, flipped to match
  $CD39,5 Z set if the sprite starts on a byte boundary
  $CD3E,2 the sprite's width byte (flip flags in the top bits)
  $CD40,3 one byte wider when shifted

@ $CD43 label=store_2d_size
c $CD43 Store the sprite's width and height
D $CD43 The tail of #R$CD33: masks the flip flags off the width and stores the
. width and the sprite's height.
  $CD43,5 +$18 = width in bytes
  $CD48,5 +$19 = height in pixel rows

c $CD4D Mark every object the moving object's old or new rectangle touches
D $CD4D Called once an object has moved or changed sprite. It works out the
. object's new screen rectangle, forms the smallest rectangle that covers both
. that and the one it had at the start of the frame (saved at +$1C to +$1F by
. #R$CE49), and then walks all forty object records setting the redraw flag,
. bit 4 of +$07, on every live object whose current rectangle overlaps it --
. including the moving object itself, if it is not marked already.
D $CD4D Horizontally the rectangles are measured in byte columns (pixel x
. divided by 8), vertically in pixel rows counted up from the bottom. At the
. end of this entry E is the union's first column and D its width in columns;
. #R$CD6C to #R$CD99 go on to put its lowest row in L and its height in H.
D $CD4D Only the moving object's own rectangle is used. An object that is
. redrawn because it overlaps it does not in turn mark the objects that overlap
. it.
R $CD4D IX the object that has moved
  $CD4D,7 IY = object 0; new rectangle into +$18 to +$1B
  $CD54,2 forty objects to test
  $CD56,9 L = the new first column
  $CD5F,9 H = the old first column
  $CD68,4 A = whichever is further left

@ $CD6C label=union_right_edge
c $CD6C Union rectangle: right-hand edge
D $CD6C Part of #R$CD4D. Keeps the left edge in E and finds the further right
. of the two right-hand edges.
  $CD6C,6 E = left edge; L = new right edge
  $CD72,4 A = old right edge
  $CD76,4 take the larger

@ $CD7A label=union_width_bottom
c $CD7A Union rectangle: width, and the lower edge
D $CD7A Part of #R$CD4D. D becomes the union's width in columns; then the
. lower of the two bottom rows is chosen.
  $CD7A,2 D = width in byte columns
  $CD7C,6 new bottom row lower than the old one?
  $CD82,5 no: use the old one

@ $CD87 label=union_top_edge
c $CD87 Union rectangle: the upper edge
D $CD87 Part of #R$CD4D. L holds the union's bottom row; this finds the higher
. of the two top rows.
  $CD87,8 H = new top (bottom row plus height)
  $CD8F,6 A = old top
  $CD95,4 take the larger

@ $CD99 label=union_height
c $CD99 Union rectangle: the height
D $CD99 Part of #R$CD4D. H becomes the union's height in pixel rows, and the
. walk through the objects begins.
  $CD99,2 H = height

c $CD9B Test one object against the union rectangle
D $CD9B IY is the object under test. An empty record (type 0) is skipped, and
. so is one already marked for redrawing. Otherwise its current rectangle is
. compared with the union: in each direction, if the object starts inside the
. union its offset from the union's start must be less than the union's size,
. and if it starts before the union the distance back must be less than the
. object's own size. Both directions overlapping means the object must be
. redrawn.
R $CD9B IY the object to test
R $CD9B E the union's first column, D its width in columns
R $CD9B L the union's bottom row, H its height in rows
  $CD9B,6 skip empty records
  $CDA1,6 skip objects already marked for redrawing
  $CDA7,8 A = the object's first column
  $CDAF,3 columns from the union's left edge; negative if it starts to the left
  $CDB2 does it start beyond the union's right edge?

@ $CDB3 label=overlap_x_decided
c $CDB3 Horizontal overlap decided
D $CDB3 Part of #R$CD9B, and where #R$CDCC rejoins it: no carry from the last
. comparison means no horizontal overlap. Then the same for the rows.
  $CDB3 clear of the union horizontally
  $CDB5,4 rows from the union's bottom edge; negative if it starts below
  $CDB9,3 does it start above the union's top?

@ $CDBC label=overlap_y_decided
c $CDBC Vertical overlap decided: mark the object
D $CDBC Part of #R$CD9B, and where #R$CDD3 rejoins it. An object that
. overlaps in both directions gets the redraw flag.
  $CDBC clear of the union vertically
  $CDBE,4 bit 4 of +$07: draw this object again this frame

c $CDC2 Next object for the overlap test
D $CDC2 Part of #R$CD9B. The union rectangle lives in D, E, H and L, so the
. step to the next record is done in the other register set.
  $CDC2,7 IY += 32, without disturbing DE and HL
  $CDC9,3 round all forty

@ $CDCC label=obj_starts_left
c $CDCC Object starts to the left of the union
D $CDCC Part of #R$CD9B. The object's first column is before the union's; it
. overlaps if the gap is less than its own width in columns.
  $CDCC,5 columns by which it starts to the left, against its width
  $CDD1 carry means overlap

@ $CDD3 label=obj_starts_below
c $CDD3 Object starts below the union
D $CDD3 Part of #R$CD9B. The object's bottom row is below the union's; it
. overlaps if the gap is less than its own height.
  $CDD3,5 rows by which it starts below, against its height
  $CDD8 carry means overlap

# --------------------------------------------------------------------------
# The player's head
# --------------------------------------------------------------------------

c $CDDA Object types 32 to 47: the knight's head
D $CDDA The player is two objects: legs in record 0 and head in record 1. Types
. 32 to 47 are the knight's heads. This sets the head sprite's pixel offset
. (-8, -12) and joins the shared head code at #R$CDE2.
R $CDDA IX the head object (record 1)
  $CDDA,5 offsets to +$12/+$13

c $CDDF Object types 64 to 79: the werewolf's head
D $CDDF As #R$CDDA for the werewolf's heads, with a pixel offset of (-12, -12);
. falls into #R$CDE2.
R $CDDF IX the head object (record 1)
  $CDDF offsets to +$12/+$13

c $CDE2 Update the player's head
D $CDE2 The head has no movement of its own: it copies the legs. First, unless
. the game has been won ($5BC3), a head whose kill flag (bit 6 of +$0D) has
. been set -- by the legs' handler at #R$C82B when the legs are killed -- turns
. into the death sparkle at #R$BF21.
R $CDE2 IX the head object (record 1)
  $CDE2,6 once the game is won the player cannot die
  $CDE8,7 killed: become the sparkle

@ $CDEF label=head_follows_legs
c $CDEF The head follows the legs
D $CDEF Copies the legs' position, size and flags into the head -- so the head
. inherits the legs' redraw, wipe and flip bits and is wiped and redrawn with
. them -- then gives the head a height of zero and sets its bit 1, which takes
. it out of every collision test. The legs' record carries the whole body's
. height, so the head never needs to collide with anything.
D $CDEF Then the choice of head sprite. The low nibble of +$0D is a countdown:
. while it is running the head keeps the sprite it has.
  $CDEF,10 DE = the head; IY = HL = the legs, one record below
  $CDF9,7 copy +$01 to +$07: X, Y, Z, the three half-sizes, flags
  $CE00,4 height 0
  $CE04,4 bit 1: ignored by collision tests
  $CE08,5 countdown running?
  $CE0D,7 yes: count it down and keep the current head

@ $CE14 label=choose_head_sprite
c $CE14 Choose the head sprite
D $CE14 Normally the head is the legs' type plus 16: the same creature, facing
. and animation frame. About one frame in 64 (the random byte at $5BA5 being
. 0 or 1, or $FE or $FF) the head is given one of two other frames of its type
. group instead -- frame 6 or frame 7 -- which it then holds for eight frames.
. The legs only ever use frames 0 to 5, so frames 6 and 7 exist only as heads.
. What the two look like has not been checked against the sprites.
  $CE14,7 random byte below 2: frame 6
  $CE1B,4 $FE or above: frame 7
  $CE1F,3 otherwise the legs' type

c $CE22 Set the head's sprite
D $CE22 Adds 16 to a legs type to make the matching head type, and stores it.
R $CE22 A a legs type
  $CE22,5 head type = legs type + 16

@ $CE27 label=head_on_shoulders
c $CE27 Put the head on the shoulders
D $CE27 The head's Z is twelve above the legs'. Then the rectangle work of
. #R$CD4D, so the head and whatever it overlaps are redrawn.
  $CE27,8 Z = legs' Z + 12
  $CE2F,4 mark what the head's old and new rectangles touch

@ $CE33 label=head_frame_six
c $CE33 Head frame 6
D $CE33 Part of #R$CE14: the legs' type with the frame replaced by 6.
  $CE33,7 the legs' type group, frame 6

@ $CE3A label=hold_head_frame
c $CE3A Hold the chosen head frame
D $CE3A Part of #R$CE14: starts the eight-frame countdown and sets the head.
  $CE3A,6 hold it for eight frames

@ $CE40 label=head_frame_seven
c $CE40 Head frame 7
D $CE40 Part of #R$CE14: the legs' type with the frame replaced by 7.
  $CE40,9 the legs' type group, frame 7

c $CE49 Remember an object's screen rectangle
D $CE49 Called by the main loop at #R$AFC7 for every object before its handler
. runs: copies the current width, height and pixel position (+$18 to +$1B) to
. +$1C to +$1F. Whatever the handler then does, #R$CD4D can compare the new
. rectangle with the one the object had at the start of the frame, and
. #R$D59F knows which area to wipe.
R $CE49 IX the object
  $CE49,25 +$18..+$1B to +$1C..+$1F

# --------------------------------------------------------------------------
# Drawing in depth order
# --------------------------------------------------------------------------

c $CE62 List the objects to be drawn this frame
D $CE62 At the end of a frame, writes to #R$CE8B the index (0 to 39) of every
. live object whose redraw flag is set, in table order, and an $FF after the
. last. #R$D59F wipes from this list and #R$CEBB draws from it.
  $CE62,16 IX = object 0, HL = the list, C = index

@ $CE72 label=list_test_obj
c $CE72 Test one object for the draw list
D $CE72 Part of #R$CE62: an object is listed if its record is in use and
. its redraw flag is set.
  $CE72,6 empty record?
  $CE78,6 redraw flag (bit 4 of +$07) clear?
  $CE7E,2 add this index

@ $CE80 label=list_next_obj
c $CE80 Next object for the draw list
D $CE80 Part of #R$CE62.
  $CE80,5 on to the next record
  $CE85,6 terminate the list

b $CE8B The objects to draw this frame
D $CE8B Filled by #R$CE62: object indices (0 to 39), then $FF. While
. #R$CEBB works through the list it sets bit 7 of each entry as that object is
. drawn, so the same list says what is still to do. 48 bytes leaves room for
. all forty and the terminator.
B $CE8B,48,8

c $CEBB Draw the listed objects, back to front
D $CEBB This is where Knight Lore decides what is in front of what. Every
. listed object is an axis-aligned box in the room: centre X and Y with
. half-sizes at +$04 and +$05, and a base Z with a height at +$06. On the screen
. +X runs down and to the right and +Y up and to the right, so the far side of
. anything is towards smaller X, larger Y and smaller Z.
D $CEBB It repeatedly takes the first object in #R$CE8B not yet drawn as the
. candidate (IX) and compares it with every other undrawn one (IY). If some IY
. has to be drawn before the candidate, IY becomes the candidate and the
. comparison starts again from the top of the list; when a candidate survives
. a full pass it is drawn, marked done, and the whole thing starts over. So
. each draw is of an object with nothing undrawn behind it.
D $CEBB The comparison classifies the two boxes on each axis into IX clear on
. the near side, overlapping, or IY clear on the near side, and combines the
. three into an index 0 to 26 into #R$CF69. The rule the table encodes: IY must
. go first when, on every axis, IY is either further back than IX or
. overlapping it, and is further back on at least one. Any other arrangement
. places no constraint on the pair.
D $CEBB The order found need not be consistent -- three boxes can each be
. behind the next -- so the chain of candidates is recorded in #R$D01A, and
. meeting an object already in it breaks the cycle by drawing that object at
. once (#R$CFCE).
D $CEBB $5BBE counts the objects drawn; #R$B000 uses it to pace the frame.
  $CEBB,8 no objects drawn yet

c $CEC3 Start a pass: find the first object not yet drawn
D $CEC3 Re-entered after every object is drawn. Every entry before the first
. undrawn one is drawn, so comparing the candidate with only the entries after
. it covers every undrawn object.
  $CEC3,3 from the top of the list

@ $CEC6 label=skip_drawn_entries
c $CEC6 Skip entries already drawn
D $CEC6 Part of #R$CEC3. The end of the list means everything is drawn.
  $CEC6,7 end of the list: finished
  $CECD,4 bit 7: already drawn
  $CED1,10 IX = the candidate; $5BCD points just past its entry

@ $CEDB label=compare_next_obj
c $CEDB Compare the candidate with the next undrawn object
D $CEDB IY is each other undrawn object in turn. If the end of the list is
. reached nothing has to be drawn before the candidate, and it is drawn by
. #R$D000.
D $CEDB C collects the comparison. On the Z axis (base +$03, height +$06): 0
. if the candidate's base is at or above IY's top, 2 if IY's base is at or
. above the candidate's top, otherwise 1.
R $CEDB IX the candidate
R $CEDB DE the next entry to compare with
  $CEDB,7 end of the list: nothing is behind the candidate
  $CEE2,4 already drawn: skip
  $CEE6,13 IY = this object; $5BCF points just past its entry
  $CEF3,5 the candidate itself: skip
  $CEF8,8 L = IY's top
  $CF00,7 candidate's base at or above IY's top: Z code 0
  $CF07,7 L = the candidate's top
  $CF0E,7 IY's base at or above it: Z code 2

@ $CF15 label=z_code_overlap
c $CF15 Z code: the boxes overlap in height
D $CF15 Part of #R$CEDB. Reached with C at 0 for overlap, or at 1 to make 2.
  $CF15 Z code 1 (or 2)

@ $CF16 label=compare_along_y
c $CF16 Compare the boxes along Y
D $CF16 Part of #R$CEDB. Along Y (centre +$02, half-size +$05) the code adds
. 0 if the candidate's low-Y edge is at or beyond IY's high-Y edge -- the
. candidate lies wholly further back -- 6 if IY lies wholly further back, and
. 3 if they overlap.
  $CF16,6 L = IY's high-Y edge
  $CF1C,10 candidate's low-Y edge at or beyond it: add 0
  $CF26,6 L = the candidate's high-Y edge
  $CF2C,13 IY's low-Y edge at or beyond it: add 6, otherwise 3

@ $CF39 label=add_y_code
c $CF39 Add the Y code
D $CF39 Part of #R$CF16: entered with 3 already added for the separated
. case, or not for the overlapping one.
  $CF39,3 Y code 3 (or 6)

@ $CF3C label=compare_along_x
c $CF3C Compare the boxes along X
D $CF3C Part of #R$CEDB. Along X (centre +$01, half-size +$04) the code adds
. 0 if the candidate's low-X edge is at or beyond IY's high-X edge -- IY lies
. wholly further back -- 18 if the candidate lies wholly further back, and 9
. if they overlap.
  $CF3C,6 L = IY's high-X edge
  $CF42,10 candidate's low-X edge at or beyond it: add 0
  $CF4C,6 L = the candidate's high-X edge
  $CF52,13 IY's low-X edge at or beyond it: add 18, otherwise 9

@ $CF5F label=add_x_code
c $CF5F Add the X code
D $CF5F Part of #R$CF3C: entered with 9 already added for the separated
. case, or not for the overlapping one.
  $CF5F,3 X code 9 (or 18)

@ $CF62 label=act_on_comparison
c $CF62 Act on the comparison
D $CF62 Part of #R$CEDB. C is now Z code + Y code + X code, 0 to 26; jump
. through #R$CF69.
  $CF62,7 via #R$AFDB

@ $CF69 label=depth_order_tbl
b $CF69 What to do about a pair of boxes
D $CF69 27 addresses, indexed by Z code (0 candidate above, 1 overlap, 2 IY
. above) + Y code (0 candidate further back, 3 overlap, 6 IY further back) + X
. code (0 IY further back, 9 overlap, 18 candidate further back). "Further
. back" means further from the viewer: smaller X, larger Y, lower Z.
D $CF69 Three outcomes. #R$CFA5 when IY is behind or level with the candidate
. on all three axes and strictly behind on at least one: IY must be drawn
. first. #R$CFA2 for the mirror image, where the candidate is behind IY -- it
. is already being drawn first, so nothing to do. #R$CF9F where each is in
. front of the other on some axis, which says nothing about their order. The
. last two are the same instruction; the table distinguishes them only in
. which entry it names. Index 13, overlapping on every axis, goes to #R$CFE1.
W $CF69,2 0: Z0 Y0 X0 -- no constraint
W $CF6B,2 1: Z1 Y0 X0 -- no constraint
W $CF6D,2 2: Z2 Y0 X0 -- no constraint
W $CF6F,2 3: Z0 Y3 X0 -- IY first
W $CF71,2 4: Z1 Y3 X0 -- IY first
W $CF73,2 5: Z2 Y3 X0 -- no constraint
W $CF75,2 6: Z0 Y6 X0 -- IY first
W $CF77,2 7: Z1 Y6 X0 -- IY first
W $CF79,2 8: Z2 Y6 X0 -- no constraint
W $CF7B,2 9: Z0 Y0 X9 -- no constraint
W $CF7D,2 10: Z1 Y0 X9 -- candidate first
W $CF7F,2 11: Z2 Y0 X9 -- candidate first
W $CF81,2 12: Z0 Y3 X9 -- IY first
W $CF83,2 13: Z1 Y3 X9 -- the boxes intersect
W $CF85,2 14: Z2 Y3 X9 -- candidate first
W $CF87,2 15: Z0 Y6 X9 -- IY first
W $CF89,2 16: Z1 Y6 X9 -- IY first
W $CF8B,2 17: Z2 Y6 X9 -- no constraint
W $CF8D,2 18: Z0 Y0 X18 -- no constraint
W $CF8F,2 19: Z1 Y0 X18 -- candidate first
W $CF91,2 20: Z2 Y0 X18 -- candidate first
W $CF93,2 21: Z0 Y3 X18 -- no constraint
W $CF95,2 22: Z1 Y3 X18 -- candidate first
W $CF97,2 23: Z2 Y3 X18 -- candidate first
W $CF99,2 24: Z0 Y6 X18 -- no constraint
W $CF9B,2 25: Z1 Y6 X18 -- no constraint
W $CF9D,2 26: Z2 Y6 X18 -- no constraint

@ $CF9F label=order_unconstrained
c $CF9F Pair with no order between them
D $CF9F Each box is in front of the other along some axis, so neither has to
. be drawn first. Go on to the next object.
  $CF9F,3 next comparison

@ $CFA2 label=candidate_already_first
c $CFA2 Candidate is behind the other object
D $CFA2 The candidate is to be drawn before IY, which is what will happen
. anyway. Identical to #R$CF9F.
  $CFA2,3 next comparison

@ $CFA5 label=iy_goes_first
c $CFA5 The other object must be drawn first
D $CFA5 IY is behind the candidate, so it becomes the candidate instead -- unless
. it is already in the chain of objects that have been candidates since the
. last draw (#R$D01A), in which case the order has gone round in a circle and
. #R$CFCE draws it straight away.
  $CFA5,5 C = IY's index, from its entry in the list
  $CFAA,3 search the chain

@ $CFAD label=search_chain
c $CFAD Search the candidate chain
D $CFAD Part of #R$CFA5.
  $CFAD,5 end of the chain: IY is new to it
  $CFB2,3 already in the chain: a cycle
  $CFB5,3 next

@ $CFB8 label=iy_becomes_candidate
c $CFB8 IY becomes the candidate
D $CFB8 Part of #R$CFA5: adds IY to the chain, makes it the candidate, and
. compares it with the whole list from the top, since it may not be the first
. undrawn entry.
D $CFB8 Nothing checks the chain's length. #R$D01A has room for seven indices
. and the terminator; an eighth link would put its $FF terminator over
. the first byte of #R$D022. How long a chain real rooms can produce has not been measured.
  $CFB8,6 append IY's index and a new terminator
  $CFBE,10 IX = IY; $5BCD = $5BCF
  $CFC8,6 compare from the top of the list

@ $CFCE label=break_order_cycle
c $CFCE Break a cycle in the order
D $CFCE Part of #R$CFA5. IY has been the candidate before in this chain, so
. there is no order that satisfies every pair; draw IY now. The search below
. only finds IY's own entry in the list again -- $5BCF - 1 already addressed it
. -- and so its exit on reaching the end cannot be taken.
  $CFCE,3 from the top of the list

@ $CFD1 label=find_iy_entry
c $CFD1 Find IY's entry and draw it
D $CFD1 Part of #R$CFCE.
  $CFD1,7 not found at all: start a new pass
  $CFD8,3 look for IY's index
  $CFDB,6 IX = IY, and draw it; HL points just past its entry

c $CFE1 Two boxes occupy the same space
D $CFE1 Index 13 of #R$CF69: the boxes overlap on all three axes. Order does
. not come into it. If either is one of the seven collectable objects (types 96
. to 102), that object is turned into type 187, whose handler at #R$BF37 removes
. it from the list of special objects for good and makes it vanish. The
. candidate is checked first; only one of the pair is changed.
  $CFE1,9 candidate a collectable?
  $CFEA,6 yes: destroy it

@ $CFF0 label=check_iy_collectable
c $CFF0 Is the other one a collectable?
D $CFF0 Part of #R$CFE1.
  $CFF0,9 IY a collectable?
  $CFF9,4 yes: destroy it

@ $CFFD label=coincide_done
c $CFFD Continue after two boxes intersect
D $CFFD Part of #R$CFE1: carry on comparing, with no order imposed.
  $CFFD,3 next comparison

c $D000 Draw the candidate
D $D000 The end of the list was reached with nothing found that has to be
. drawn before the candidate: draw it. HL is the pointer just past its entry,
. which #R$D003 marks.
  $D000,3 HL = just past the candidate's entry

c $D003 Draw an object and start the next pass
D $D003 Marks the object's entry drawn, empties the candidate chain, counts
. the object in $5BBE, and draws it with #R$D704 -- which clears its redraw
. flag, or deletes it if it is of type 1. Then back to the top of the list for
. the next.
R $D003 IX the object to draw
R $D003 HL just past its entry in #R$CE8B
  $D003,3 bit 7 of the entry: drawn
  $D006,5 the chain is empty again
  $D00B,4 one more object drawn this frame
  $D00F,6 draw it; then the next pass

c $D015 All listed objects drawn
D $D015 Part of #R$CEBB.
  $D015,5 restore the caller's IX and IY

@ $D01A label=candidate_chain
b $D01A The chain of candidates since the last draw
D $D01A Object indices, ended by $FF, of every object that #R$CFB8 has made
. the candidate since #R$D003 last drew something. #R$CFA5 looks for an object
. here before making it the candidate: finding it means the depth order has a
. cycle. The first byte is set to $FF after every draw, so between frames the
. list is always empty. The object the pass began with is not recorded, so a
. cycle back to it is caught one step later, at the next object in the loop.
B $D01A,8,8

# --------------------------------------------------------------------------
# The controls
# --------------------------------------------------------------------------

c $D022 Read the controls
D $D022 Reads whichever control method the menu chose (bits 1 and 2 of $5BA4:
. 0 keyboard, 1 Kempston, 2 cursor keys, 3 Interface II) into one byte of
. bits that means the same whichever it came from, and stores it at $5BB5.
. The legs' handler at #R$C82B calls this every frame and also uses the byte
. as it is returned, in C.
D $D022 The bits: 0 turn left, 1 turn right, 2 walk forward, 3 jump, 4 pick
. up or drop, 5 any key but the number keys, Caps Shift and
. Space. On a joystick with the
. menu's directional option set (bit 3 of $5BA4), bits 0, 1, 2 and 4 are
. instead the four directions of the stick, and bit 5 takes over picking up
. and dropping -- see #R$BFFB and #R$C89F. The directional option has no effect
. with the keyboard method.
D $D022 While the game is won ($5BC3) or an object is falling into the cauldron
. ($5BC4) the controls are ignored: the byte is 0 apart from bit 5.
R $D022 C on exit, the control bits (also at $5BB5)
  $D022,10 C = 0; A non-zero if the controls are frozen
  $D02C,3 frozen: straight to the end, where only bit 5 is read
  $D02F,6 A = the control method, 0 to 3
  $D035,9 0 keyboard, 1 Kempston, 2 cursor, 3 falls through

c $D03E Interface II joysticks
D $D03E Both of the Interface II's joysticks are read, and either will do. The
. one is the keys 1 to 5 (left, right, down, up, fire) and the other 6 to 0
. in the same order. The two half-rows come in with their keys in
. opposite orders, so the 1 to 5 bits are reversed first to line up with 6 to
. 0.
  $D03E,5 half-row 1 to 5
  $D043,3 five bits to reverse, keeping B

@ $D046 label=reverse_if2_bits
c $D046 Reverse the 1 to 5 bits
D $D046 Part of #R$D03E. After this, bit 0 is 5 (fire), 1 is 4 (up), 2 is 3
. (down), 3 is 2 (right), 4 is 1 (left) -- the same meanings as the 0 to 6
. half-row's bits.
  $D046,5 one bit out of A into the bottom of C
  $D04B,3 C = the reversed bits
  $D04E,6 combine with half-row 0 to 6
  $D054,8 fire (5 or 0): jump, bit 3

@ $D05C label=if2_up
c $D05C Interface II up
D $D05C Part of #R$D03E.
  $D05C,6 up (4 or 9): forward, bit 2

@ $D062 label=if2_down
c $D062 Interface II down
D $D062 Part of #R$D03E.
  $D062,6 down (3 or 8): bit 4

@ $D068 label=if2_right
c $D068 Interface II right
D $D068 Part of #R$D03E.
  $D068,6 right (2 or 7): bit 1

@ $D06E label=if2_left
c $D06E Interface II left
D $D06E Part of #R$D03E.
  $D06E,6 left (1 or 6): bit 0

@ $D074 label=if2_done
c $D074 Interface II done
D $D074 Part of #R$D03E.
  $D074,3 on to the common ending

c $D077 Kempston joystick
D $D077 The Kempston interface answers on port $1F with the stick's switches
. active high: bit 0 right, 1 left, 2 down, 3 up, 4 fire.
  $D077,4 read the stick
  $D07B,6 right: bit 1

@ $D081 label=kempston_left
c $D081 Kempston left
D $D081 Part of #R$D077.
  $D081,6 left: bit 0

@ $D087 label=kempston_down
c $D087 Kempston down
D $D087 Part of #R$D077.
  $D087,6 down: bit 4

@ $D08D label=kempston_up
c $D08D Kempston up
D $D08D Part of #R$D077.
  $D08D,6 up: forward, bit 2

@ $D093 label=kempston_fire
c $D093 Kempston fire
D $D093 Part of #R$D077.
  $D093,6 fire: jump, bit 3

@ $D099 label=kempston_done
c $D099 Kempston done
D $D099 Part of #R$D077.
  $D099,3 on to the common ending

c $D09C Cursor keys
D $D09C The cursor keys on the number row: 5 left, 6 down, 7 up, 8 right, with
. 0 as fire.
  $D09C,7 half-row 1 to 5
  $D0A3,6 5 (left): bit 0

@ $D0A9 label=cursor_second_row
c $D0A9 Cursor keys: the 6 to 0 half-row
D $D0A9 Part of #R$D09C.
  $D0A9,5 half-row 0 to 6
  $D0AE,6 0 (fire): jump, bit 3

@ $D0B4 label=cursor_up
c $D0B4 Cursor up
D $D0B4 Part of #R$D09C.
  $D0B4,6 7 (up): forward, bit 2

@ $D0BA label=cursor_right
c $D0BA Cursor right
D $D0BA Part of #R$D09C.
  $D0BA,6 8 (right): bit 1

@ $D0C0 label=cursor_down
c $D0C0 Cursor down
D $D0C0 Part of #R$D09C.
  $D0C0,8 6 (down): bit 4

c $D0C8 Keyboard
D $D0C8 The whole keyboard is in use, a pair of half-rows to each action. The
. bottom row alternates: Z, C, B and M turn left, X, V, N and Symbol Shift turn
. right. A to G and H to Enter walk forward, Q to T and Y to P jump, and the
. number keys pick up and drop. Caps Shift and Space are left alone -- they are
. the pause keys (#R$D50E).
  $D0C8,6 half-row Caps..V; Z to bit 0, X to bit 1, C to bit 2, V to bit 3
  $D0CE,3 Z and X
  $D0D1,7 fold C onto Z and V onto X
  $D0D8,6 C = left and right so far; half-row B..Space
  $D0DE,6 Symbol Shift: right

@ $D0E4 label=keyboard_m
c $D0E4 Keyboard: M
D $D0E4 Part of #R$D0C8.
  $D0E4,6 M: left

@ $D0EA label=keyboard_n
c $D0EA Keyboard: N
D $D0EA Part of #R$D0C8.
  $D0EA,6 N: right

@ $D0F0 label=keyboard_b
c $D0F0 Keyboard: B
D $D0F0 Part of #R$D0C8.
  $D0F0,6 B: left

@ $D0F6 label=keyboard_forward
c $D0F6 Keyboard: walk forward
D $D0F6 Part of #R$D0C8. $BD selects two half-rows at once, A to G and H to
. Enter; any key in either sets the bit.
  $D0F6,9 any of A..G, H..Enter: forward, bit 2

@ $D0FF label=keyboard_jump
c $D0FF Keyboard: jump
D $D0FF Part of #R$D0C8.
  $D0FF,9 any of Q..T, Y..P: jump, bit 3

@ $D108 label=keyboard_pickup
c $D108 Keyboard: pick up and drop
D $D108 Part of #R$D0C8.
  $D108,9 any number key: bit 4

c $D111 Finish reading the controls
D $D111 Common to every method. Bit 5 is set if any key is down other than the
. number keys, Caps Shift and Space. It is the
. pick-up key for a joystick in directional mode, where bit 4 is a direction.
. The byte is stored at $5BB5.
  $D111,7 bottom two half-rows together, less Caps Shift and Space
  $D118,9 or'd with the A..G, Q..T, Y..P and H..Enter half-rows
  $D121,4 any of them: bit 5

@ $D125 label=store_input
c $D125 Store the control bits
D $D125 Part of #R$D111.
  $D125,5 $5BB5 = the control bits, also left in C

# --------------------------------------------------------------------------
# Lives and where the player starts
# --------------------------------------------------------------------------

c $D12A Start a life
D $D12A Reached at the start of every game and after every death (#R$AFB7).
. Puts the player's two saved records from #R$D161 back into object records 0
. and 1 -- the legs and head as they were on entering the current room, but
. with the materialising type -- and takes a life from $5BBA. When the count
. goes below zero the game is over.
D $D12A The game begins with $5BBA at 5, and this first call takes it to 4, so
. the player has five lives: the fifth death ends the game. Touching the
. extra-life object (type 103, #R$C1AB) adds one.
D $D12A The saved records say what the legs and head become once they have
. materialised (+$10). That is corrected here for the time of day: knight by
. day, werewolf by night (bit 0 of the sun and moon's type at #R$C44D).
. Werewolf types are the knight's plus 32, so the creature bit is replaced and
. the frame and facing kept. A transformation that was pending ($5BB1) is
. cancelled, as the new body is already the right one.
  $D12A,14 copy both 32-byte records; IX = object 0
  $D138,4 no transformation pending
  $D13C,7 one life fewer; below zero is game over
  $D143,9 C = 32 at night, 0 by day
  $D14C,9 legs: knight legs type (16 to 31), plus 32 at night
  $D155,12 head: knight head type (32 to 47), plus 32 at night

b $D161 The saved legs record: bytes 0 to 7
D $D161 This block and the next four, up to #R$D1A1, are two 32-byte object records -- the player's
. legs and head -- that #R$D12A copies over records 0 and 1 to start a life.
. #R$D1B1 fills them at the start of a game; each time the player leaves a
. room, #R$CABA saves the live
. records here, with the type moved to +$10 and the materialising type 120 put
. in its place. So after a death the player reappears in the room he last
. entered, where he entered it.
D $D161 This block is bytes 0 to 7 of the legs: type, X, Y, Z, the X and Y
. half-sizes, height, flags.
B $D161,8,8

b $D169 The saved legs record: room and movement
D $D169 Bytes 8 to 11 of the saved legs record at #R$D161: the room number,
. then three bytes (+$09 to +$0B) that the movement code uses for its X, Y and
. Z steps. #R$D1B1 sets the room.
B $D169,4,4

b $D16D The saved legs record: bytes 12 to 15
D $D16D Bytes 12 to 15 of the saved legs record at #R$D161. +$0C holds
. movement state bits. #R$CABA sets its top nibble to 3 before saving, and the
. legs' handler counts it down by one a frame: while it is non-zero the turn
. and jump controls are ignored, the legs keep walking, and the room-boundary
. check at #R$CCDD is skipped -- which is presumably what walks him in through
. the doorway. #R$AF88 clears this byte for each new game.
B $D16D,4,4

@ $D171 label=plyr_spr_1_tail
b $D171 The saved legs record: bytes 16 to 31
D $D171 The rest of the saved legs record at #R$D161. The first byte (+$10) is
. the type the legs take once they have materialised: #R$D1B1 sets 18, knight
. legs standing, and #R$D12A adjusts it for the time of day.
B $D171,16,8

b $D181 The saved head record: bytes 0 to 7
D $D181 The head's saved record, laid out as the legs' at #R$D161: type, X,
. Y, Z, the X and Y half-sizes, height, flags.
B $D181,8,8

b $D189 The saved head record: bytes 8 to 15
D $D189 +$08 is the room number, set by #R$D1B1 to match the legs.
B $D189,8,8

@ $D191 label=plyr_spr_2_tail
b $D191 The saved head record: bytes 16 to 31
D $D191 The first byte (+$10) is the type the head takes once it has
. materialised: #R$D1B1 sets 34, and #R$D12A adjusts it for the time of day.
B $D191,16,8

b $D1A1 The player's records at the start of a game
D $D1A1 The first eight bytes of the legs' and head's records, copied to
. #R$D161 and #R$D181 by #R$D1B1. Both start as type 120, the first frame of
. materialising, in the middle of the room ($80, $80). The legs stand on Z $80
. with half-sizes of 5 and a height of 23 -- the whole knight -- and the head
. sits 12 higher with a height of 0. Flags: both redraw (bit 4), and the head
. is ignored by collisions (bit 1); bits 2 and 3 are set in both and are not
. yet worked out here.
B $D1A1,8,8 legs: type, X, Y, Z, X half-size, Y half-size, height, flags
B $D1A9,8,8 head: type, X, Y, Z, X half-size, Y half-size, height, flags

c $D1B1 Set up the player for a new game
D $D1B1 Fills the saved records at #R$D161 and #R$D181 that #R$D12A starts
. each life from: the initial values from #R$D1A1, knight legs and head as the
. types to become after materialising, and one of four starting rooms, chosen
. by the low two bits of the random seed at $5BA0.
  $D1B1,19 the first eight bytes of each record
  $D1C4,10 become knight legs (18) and knight head (34)
  $D1CE,12 one of four rooms
  $D1DA,8 into both records

b $D1E2 The four starting rooms
D $D1E2 Room numbers, one of which #R$D1B1 picks at random. A room number is
. its Y position in the castle grid in the high nibble and its X position in
. the low nibble.
B $D1E2,4,4

# --------------------------------------------------------------------------
# Building a room
# --------------------------------------------------------------------------

c $D1E6 Build the room the player is in
D $D1E6 Called at the start of each life and whenever the player walks into
. another room (#R$AFBA). Before the old room's objects are thrown away, the
. collectable objects in records 2 and 3 are written back to the special
. object table (#R$C591) -- unless no frame of this game has been played yet
. ($5BB2), in which case there is no old room.
R $D1E6 IX object 0, the player's legs; its +$08 is the room to build
  $D1E6,9 skip the save on the first build of a game

@ $D1EF label=build_room
c $D1EF Fill the object table for the new room
D $D1EF Clears the screen buffer; builds the room's walls, arches and fixed
. objects into records 4 onwards (#R$D3C6); puts any collectable objects in
. this room into records 2 and 3 (#R$C525); and places the player in the
. doorway he came through (#R$D320). Then resets the per-room state and asks
. for the whole room to be drawn and copied to the screen ($5BB7).
D $D1EF $5BAF is the portcullis-moving flag and $5BB0 a count the portcullis
. code keeps; $5BBD is the bouncing ball's turning height and $5BBF the
. spiked-ball-falling flag. $5BC0 takes bit 0 of the room number: the
. dropping spiked balls (#R$B7A9) stay put while it is non-zero; picking an
. object up (#R$C141) or collecting an extra life (#R$C1AB) clears it.
  $D1EF,12 build the room
  $D1FB,13 clear the per-room flags
  $D208,5 draw the whole room this frame
  $D20D,8 odd rooms hold their spiked balls
  $D215,4 the room counts as visited

c $D219 Mark the player's room as visited
D $D219 $5BE8 to $5C07 is a 256-bit map of the castle, a bit per room number.
. The byte is the room number divided by 8; the bit number is the bottom
. three bits, and since SET takes its bit number in the opcode, the second opcode byte of
. the SET n,(HL) near the end of this routine is rewritten before it runs. #R$BC10 counts the bits
. for the percentage shown when the game ends.
  $D219,12 HL = room / 8
  $D225,11 opcode byte for SET (room AND 7),(HL)
  $D230,7 set the bit in the map

# --------------------------------------------------------------------------
# The panel and the border
# --------------------------------------------------------------------------

c $D237 Copy a sprite's four bytes into the drawing record
D $D237 Loads a sprite type, flags (for the flip bits), pixel x and pixel y
. from a four-byte entry into the object record at IX -- the spare record at
. #R$BFDB -- ready for #R$D718.
R $D237 HL the four-byte entry
R $D237 IX the record to draw with
R $D237 HL on exit, the next entry
  $D237,21 type, +$07 flags, +$1A x, +$1B y

c $D24C Copy a sprite's four bytes and draw it
D $D24C #R$D237 and then #R$D718, keeping HL on the next entry.
R $D24C HL the four-byte entry
R $D24C IX the record to draw with
  $D24C,9 load, draw, keep HL

c $D255 Draw the scroll-work at the foot of the screen
D $D255 Draws the panel artwork under the room from #R$D27E: a slanting run of
. five of one piece on each side, and two more pieces on each side, the right
. side the left mirrored. The picture of the sun and moon and the lives and
. days are drawn over it by other routines.
  $D255,10 the first entry
  $D25F,8 left run: five copies, each 16 pixels right and 8 down
  $D267,6 two more pieces, drawn once each
  $D26D,3 the right run's piece
  $D270,8 five copies, each 16 pixels right and 8 up
  $D278,6 two more pieces, drawn once each

b $D27E The panel artwork
D $D27E Six four-byte entries for #R$D255: sprite type, flags (bit 6 mirrors
. the sprite), pixel x, pixel y counted up from the bottom.
B $D27E,4,4 type 134 at (16, 52): the first of the left-hand run
B $D282,4,4 type 135 at (240, 0)
B $D286,4,4 type 136 at (144, 4)
B $D28A,4,4 type 134 mirrored at (160, 20): the first of the right-hand run
B $D28E,4,4 type 135 mirrored at (0, 0)
B $D292,4,4 type 136 mirrored at (96, 4)

c $D296 Draw the border round the play area
D $D296 From #R$D2CF: one corner sprite drawn four times, flipped each way,
. then the top and bottom edges as 24 pieces 8 pixels apart and the two sides
. as 128 pieces a pixel apart.
  $D296,19 the four corners
  $D2A9,11 the top edge: 24 pieces, 8 pixels apart
  $D2B4,8 the bottom edge
  $D2BC,11 the left edge: 128 pieces, stepping up a pixel at a time
  $D2C7,8 the right edge

b $D2CF The border pieces
D $D2CF Eight four-byte entries for #R$D296: sprite type, flags (bit 6
. mirrors, bit 7 turns upside down), pixel x, pixel y counted up from the
. bottom.
B $D2CF,4,4 type 137, corner at (0, 160)
B $D2D3,4,4 type 137 mirrored, corner at (224, 160)
B $D2D7,4,4 type 137 mirrored and upside down, corner at (224, 0)
B $D2DB,4,4 type 137 upside down, corner at (0, 0)
B $D2DF,4,4 type 139, top edge from (32, 168)
B $D2E3,4,4 type 139, bottom edge from (32, 0)
B $D2E7,4,4 type 138, left edge from (0, 32)
B $D2EB,4,4 type 138, right edge from (232, 32)

c $D2EF Colour the sun and moon window's frame
D $D2EF Attributes only. Blacks out the columns either side of the window
. (columns 22 and 29, rows 21 to 23) and colours its frame bright red (columns
. 23 to 28, rows 20 to 23). #R$D30D then colours the inside.
  $D2EF,7 black: column 22, rows 21 to 23
  $D2F6,12 black: column 29, rows 21 to 23
  $D302,11 bright red: columns 23 to 28, rows 20 to 23

c $D30D Colour the sun or the moon
D $D30D Colours the inside of the window (columns 24 to 27, rows 21 and 22)
. bright yellow while the sun shows and bright white for the moon. Bit 0 of
. the type in #R$C44D is 0 for the sun and 1 for the moon.
  $D30D,10 yellow on black, or white for the moon

@ $D317 label=fill_sun_moon_colour
c $D317 Fill the window's colour
D $D317 Part of #R$D30D.
  $D317,9 columns 24 to 27, rows 21 and 22

# --------------------------------------------------------------------------
# Coming into a room
# --------------------------------------------------------------------------

c $D320 Put the player in the doorway he came through
D $D320 When the player walks out of a room, the exit code (#R$CA9A and its
. three neighbours, ending at #R$CABA) moves him to the next room number and
. sets the coordinate he left by to an extreme -- X to 0 on leaving towards -X, $FF towards +X, and
. the same for Y. That extreme says which side of the new room he enters from,
. and this routine moves him to that side, with his inner side two units
. inside the room's edge and the rest of him in the doorway. His Z is then set
. to the floor of the arch there (#R$D38C).
D $D320 The names follow the compass used for the arches: +X is east, +Y
. north. If no coordinate is at an extreme -- the start of a life -- nothing
. is changed.
D $D320 $5BAB and $5BAC are the room's X and Y half-sizes, measured from the
. centre, $80.
R $D320 IX object 0, the player's legs
  $D320,12 L and H: the half-sizes less 2
  $D32C,4 X = 0: came in on the east side
  $D330,5 X = $FF: the west side
  $D335,4 Y = 0: the north side
  $D339,6 Y = $FF: the south side; otherwise stay put

c $D33F Enter through the south arch
D $D33F The player left the last room northwards (Y was $FF) and arrives at
. the low-Y side of this one.
  $D33F,5 Z from the arch whose X+Y is $C8
  $D344,6 Y = $80 - (half-size - 2) - his Y half-size

c $D34A Set the player's Y
D $D34A Part of #R$D33F and #R$D362.
  $D34A,3 the new Y

@ $D34D label=plyr_redraw_copy_xy
c $D34D Redraw the player and line the head up with the legs
D $D34D Sets the redraw flag on both of the player's records and copies the
. legs' new X and Y to the head.
  $D34D,8 redraw legs and head
  $D355,13 head X and Y = legs X and Y

c $D362 Enter through the north arch
D $D362 The player left the last room southwards (Y was 0) and arrives at the
. high-Y side of this one.
  $D362,5 Z from the arch whose X+Y is $51
  $D367,8 Y = $80 + (half-size - 2) + his Y half-size

c $D36F Enter through the west arch
D $D36F The player left the last room eastwards (X was $FF) and arrives at
. the low-X side of this one.
  $D36F,5 Z from the arch whose X+Y is $AE
  $D374,6 X = $80 - (half-size - 2) - his X half-size

c $D37A Set the player's X
D $D37A Part of #R$D36F and #R$D37F.
  $D37A,5 the new X, and on to the head

c $D37F Enter through the east arch
D $D37F The player left the last room westwards (X was 0) and arrives at the
. high-X side of this one.
  $D37F,5 Z from the arch whose X+Y is $37
  $D384,8 X = $80 + (half-size - 2) + his X half-size

c $D38C Stand the player on the floor of the arch
D $D38C The code expects a room's arches to be its first background objects, each two records (the
. two pillars, types 2 to 5), so the first pillars are records 4, 6, 8 and
. 10. The side an arch is on is recognised by the X+Y of its first pillar --
. $51 north, $37 east, $C8 south, $AE west, from the arch data at #R$6D12 on.
. The player takes that pillar's Z, which is what puts him at the right
. height in a raised arch; the head goes 12 above.
D $D38C The search stops at the first record that is not an arch pillar; if
. no arch matches, Z is left alone.
R $D38C C X+Y of the arch wanted
R $D38C IX object 0, the player's legs
  $D38C,9 IY = record 4; step two records; four arches at most

@ $D395 label=check_next_arch
c $D395 Look at the next arch
D $D395 Part of #R$D38C.
  $D395,6 type 6 or more: no more arches
  $D39B,9 X+Y matches: this is the one
  $D3A4,5 next arch

c $D3A9 Take the arch's Z
D $D3A9 Part of #R$D38C.
  $D3A9,6 legs' Z = the pillar's Z
  $D3AF,6 head's Z = 12 higher

# --------------------------------------------------------------------------
# Rooms, pause, the screen, drawing
# --------------------------------------------------------------------------

# --------------------------------------------------------------------------
# Rooms into objects, and drawing ($D3B5-$D8F2)
# --------------------------------------------------------------------------

c $D3B5 Object index to record address
R $D3B5 A the object index; bit 7 is ignored
R $D3B5 HL the address of its 32-byte record
D $D3B5 Five doublings is a multiply by 32, and $5C08 is the base of the
. object table. The AND $7F is the counterpart of the flag bit that callers
. carry in the top of the index: #R$D003 sets bit 7 of an entry in the list at
. #R$CE8B once that object has been drawn, and the list is read again later
. in the same frame.
  $D3B6,10 HL = index * 32
  $D3C0,4 plus the start of the object table

c $D3C6 Build the objects of the room the player has entered
R $D3C6 IX the object whose byte 8 names the room: the player's record at $5C08
D $D3C6 Turns one room record from #R$6251 into object records, filling the
. object table from record 4 ($5C88) upwards and clearing whatever is left
. after the last one. Records 0 to 3 are not touched here. The first two are
. the player's; #R$D1EF calls #R$C525 next, which fills from record 2 ($5C48)
. with the special objects that are in this room.
D $D3C6 Every fixed part of the room -- walls, arches, doors, blocks, spikes
. -- becomes an ordinary 32-byte object, the same as a guard or a ghost. There
. is no separate background picture: the room is drawn by drawing its objects.
  $D3C6,3 the first record the room may use
  $D3C9,3 the end of the room table, where #R$6BD1 begins
  $D3CC,3 the first room record

c $D3CF Find the room's record
R $D3CF HL a room record's first byte, its room number
R $D3CF BC the end of the room table
D $D3CF Walks the room table from the start, since records vary in length
. and there is no index. A room that is not in the table gets no objects at
. all: the table is cleared from DE and the routine returns.
  $D3CF,7 this record's room number against the one the player is in
  $D3D6,4 not it: the second byte is the record's length counted from that
. byte itself, so adding it lands on the next record's room number
  $D3DA,8 past the end of the table: no such room; otherwise go round again

c $D3E2 Clear the object records from DE to the end of the table
R $D3E2 DE the first record to clear, a whole number of records below #R$6108
D $D3E2 Every way out of the room builder ends here, so the records a room
. did not fill are left empty -- byte 0, the graphic, is 0 -- and the object
. walk at #R$AFBD skips them.
  $D3E2,7 done when DE has reached #R$6108, the end of the object table
  $D3E9,7 clear one 32-byte record and go round

c $D3F0 Take the room's colour and size from its record
R $D3F0 HL the record's length byte
D $D3F0 The byte after the length is the room's attribute byte. Its bits 0
. to 2 are the ink colour the whole room is drawn in, and its bits 3 to 7
. pick one of the entries in #R$6248, which give the room's half-widths in x
. and y and the height of its floor. After this B counts the bytes that remain
. in the record, so that the lists that follow can end on it as well as on
. their own markers.
  $D3F0,2 B = the record's length; HL on the attribute byte
  $D3F2,8 ink colour, BRIGHT, black paper: kept in $5BAD for #R$D556 to
. paint the room with
  $D3FA,9 bits 3 to 7 index the size table
  $D403,9 three bytes an entry in #R$6248
  $D40C,14 half-width in x into $5BAB, in y into $5BAC, and the floor
. height into $5BAE
  $D41A,4 the length counted itself and the attribute byte; HL on the
. list of backgrounds, DE on the next free record again

c $D41E Next background in the room's list
R $D41E HL the next byte of the room record
R $D41E DE the next free object record
R $D41E B the bytes left in the room record
D $D41E The room record starts with a list of background numbers, ended by
. $FF. Each one is looked up in #R$6CE2 to find its list of templates.
  $D41E,6 $FF ends the backgrounds and starts the foreground list
  $D424,14 look the background up in #R$6CE2; HL = its template list

c $D432 Copy one background template into an object record
D $D432 A background template is eight bytes that become bytes 0 to 7 of the
. record unchanged: graphic, x, y, z, the half-sizes in x and y, the height,
. and the flags. Byte 8 is the room, and the rest of the record is cleared.
. A background's templates follow one another and end at a 0 byte, where the
. next graphic number would be; graphic 0 is never an object.
  $D432,5 bytes 0 to 7 straight from the template
  $D437,5 byte 8: the room it belongs to
  $D43C,5 bytes 9 to 31 cleared
  $D441,4 more templates for this background until a 0
  $D445,4 one byte of the room record used; next background
  $D449,3 a record with only backgrounds: clear the rest of the table

c $D44C Start on the room's foreground objects
D $D44C After the $FF come the foreground groups. IY becomes the pointer to
. the next free record here, because D is about to hold a location byte and
. HL and DE are both in use.
  $D44C,1 count the $FF
  $D44D,5 IY = the next free record; the caller's IY kept on the stack

c $D452 Read a foreground group: its type, count and first location
R $D452 HL the group's first byte
D $D452 A group is a type byte followed by one location byte per object. The
. type byte's bits 3 to 7 index #R$6BD1, and its bits 0 to 2 are one less than
. the number of locations that follow. So one room record can scatter eight
. identical blocks in nine bytes.
  $D452,5 C = how many of this type
  $D457,5 D = the first location; each type and location byte counts off B
  $D45C,11 bits 3 to 7 of the type byte, already doubled by the RRCAs, index
. the word table at #R$6BD1
  $D467,4 HL = the type's template list

c $D46B Place one more of the same type
D $D46B Keeps the start of the template list on the stack, so it can be read
. again for the next location of the same type.

c $D46C Build one object record from a foreground template and a location
R $D46C HL the template
R $D46C D the location byte
R $D46C IY the record to fill
D $D46C A foreground template is six bytes: the graphic, four bytes that
. become bytes 4 to 7 of the record (half-sizes, height, flags), and an
. offset byte. The position comes from the room's location byte, which is a
. cell on a grid: bits 0 to 2 the x cell, bits 3 to 5 the y cell, bits 6
. and 7 the level. Cells are 16 units apart starting at $48, and levels 12
. units apart starting at the floor height in $5BAE. The offset byte's bits 0
. and 1 add half a cell in x and y, and the rest of it, a multiple of 4, is
. added to the height -- which is how something can stand on top of a block
. or sit between two cells.
  $D46C,25 graphic into byte 0, then four template bytes into bytes 4 to 7
  $D485,6 byte 8: the room
  $D48B,20 x = $48 + 16 * the x cell, plus 8 if bit 0 of the offset byte
. is set
  $D49F,16 y = $48 + 16 * the y cell, plus 8 if bit 1 is set
  $D4AF,22 z = the floor height + (12 * the level + the offset byte) AND
. $FC
  $D4C5,8 on to byte 9 of the record; 23 bytes to clear
@ $D4CD label=zero_fg_obj_tail
c $D4CD Clear the rest of a foreground record, then carry on
D $D4CD A type's template list can hold more than one template, ended by a
. 0, so one location can build several records -- each the next template
. placed at the same cell.
  $D4CD,8 zero bytes 9 to 31, leaving IY on the next record
  $D4D5,5 more templates for this location until a 0
  $D4DA,2 DE = the start of the template list; HL on the room record
  $D4DC,3 each location counts off B; at zero the room record is used up
  $D4DF,4 all the locations of this type placed: read the next type byte
  $D4E3,7 another location of the same type: D = its byte, and HL back on
. the template list
@ $D4EA label=end_of_fg_objs
c $D4EA The room record is used up
D $D4EA Hands the next free record back in DE, restores the caller's IY and
. clears the rest of the table.

c $D4F2 Add A to HL
R $D4F2 A the amount to add
R $D4F2 HL the address to add it to
D $D4F2 An unsigned 8-bit add with the carry taken into H. A comes back
. holding H.

c $D4F9 HL = DE * A
R $D4F9 DE the multiplicand
R $D4F9 A the multiplier
R $D4F9 HL on exit, the product
D $D4F9 Shift and add, taking the bits of A from the top. Eight RLCAs bring A
. back to what it was, and BC is kept.
@ $D4FF label=mult_step
c $D4FF One bit of the multiply
D $D4FF Doubles the running total, and adds DE if this bit of A is set.
@ $D504 label=mult_next_bit
c $D504 Next bit of the multiply
D $D504 Eight passes, one for each bit of A.

c $D508 Clear B bytes at DE
R $D508 DE the first byte
R $D508 B the count
D $D508 Falls into #R$D509 with A = 0. DE is left after the last byte, which
. is how the room builder moves on to the next record.

c $D509 Fill B bytes at DE with A
R $D509 DE the first byte
R $D509 B the count
R $D509 A the value
D $D509 DE is left after the last byte.

c $D50E Pause if SPACE is pressed
D $D50E Called once a frame. The half-row $7E is B, N, M, SYMBOL SHIFT and
. SPACE, and #R$B5F7 returns SPACE as bit 0. Only SPACE on its own pauses:
. with any other key of that half-row held as well the routine returns. Why
. that matters has not been worked out.
D $D50E The pause itself is a busy wait inside this routine: nothing moves,
. nothing is drawn and the frame counter stops until SPACE is pressed and let
. go again. #R$B4A8 sounds on the way in and on the way out.
  $D50E,8 SPACE not pressed: carry on
  $D516,3 another key of the half-row is held too: not a pause

c $D519 Wait for SPACE to be let go, then sound
D $D519 Without this the press that paused the game would also end the
. pause.
  $D519,9 wait until SPACE is up
  $D522,3 the pause sound

c $D525 Paused: wait for SPACE again

c $D52E Wait for SPACE to be let go, sound, and carry on
D $D52E The release is waited for so that the unpausing press does not pause
. the game again on the next frame.
  $D537,3 the sound again, and back to the game

c $D53A Clear BC bytes at HL
R $D53A HL the first byte
R $D53A BC the count

c $D53C Fill BC bytes at HL with E
R $D53C HL the first byte
R $D53C BC the count
R $D53C E the value

c $D544 Clear the display bitmap
D $D544 All 6144 bytes from $4000.

c $D54C Set every attribute to bright yellow on black
D $D54C $46 is BRIGHT, black paper, yellow ink: the colour of the menu and
. the status line.

c $D556 Set every attribute to A
R $D556 A the attribute
D $D556 Called with the room's colour from $5BAD when a new room is shown:
. the game area is one colour throughout, which is why a room's objects all
. take the room's ink.

c $D55F Clear the screen and make the border black
D $D55F Black border, the attributes to bright yellow on black, and then the
. bitmap cleared.
  $D55F,3 black border

c $D567 Clear the screen buffer
D $D567 Blanks all of #R$D8F3 before a room is built into it.

c $D56F Copy the whole buffer to the display, clearing it as it goes
D $D56F Used when a new room is shown: the whole room is composed in #R$D8F3
. first and then appears at once. The buffer runs the other way up from the
. display -- its first row is the bottom line of the screen -- because the
. game's pixel y counts up from the bottom; so the copy starts at the
. display's bottom-left byte, $57E0, and works up a line at a time.
D $D56F Clearing as it copies leaves the buffer blank. That is safe because
. from here on only the areas #R$D59F wipes and redraws are ever copied out
. of it, so what the rest of the buffer holds does not matter.
  $D56F,9 from the start of the buffer to the bottom-left of the display;
. B = 32 bytes a row, C = 192 rows
@ $D578 label=update_screen_row
c $D578 One row of the whole-screen copy
@ $D57B label=update_screen_byte
c $D57B Copy and clear a row, then step to the display line above
  $D57B,8 copy a byte and clear it behind
  $D583,6 the next buffer row is 32 bytes on
  $D589,7 up a display line: DEC D is enough unless the low three bits of D
. have wrapped round to 7, which means the line crossed into the character
. row above
  $D590,10 crossing a character row: back 32 in E; if that borrows the line
. is the bottom of the third above, which is where DEC D left it; if not, D
. goes back up by 8 to stay in this third
@ $D59A label=update_screen_next_row
c $D59A Next row of the whole-screen copy

c $D59F Redraw what changed and copy it to the display
D $D59F Called at the end of every frame. The list at #R$CE8B holds every
. object that is to be drawn this frame: those that moved or changed, which
. #R$C692 flagged with bits 4 and 5 of byte 7, and those whose picture
. overlaps them, which #R$CD4D flagged with bit 4 only. First, for each object
. that moved, the rectangle covering both where it was last frame and where
. it is now is cleared in the buffer and remembered on the stack. Then every
. flagged object is drawn into the buffer in depth order, and finally the
. remembered rectangles -- and only those -- are copied to the display.
D $D59F Nothing is ever erased on the display itself, so nothing flickers;
. and since the background is made of objects too, a wall behind a moving
. knight is simply drawn again.
D $D59F In the frame a room is entered the wiping is skipped altogether: the
. buffer has just been cleared, and #R$B000 copies all of it to the display
. with #R$D56F once the objects are drawn.
  $D59F,4 no rectangles yet: $5BA8 counts them
  $D5A5,7 a room just built ($5BB7 set by #R$D1EF): nothing to wipe
  $D5AC,6 walk the list that #R$CE62 made; $5BCB is the place in it

c $D5B2 Wipe the next object that moved
D $D5B2 Bytes $18 and $19 of a record are the width in bytes and height in
. rows of its sprite as last drawn, and $1A and $1B its pixel x and y;
. #R$CE49 copies all four to bytes $1C to $1F before the object's handler
. runs, so they hold last frame's picture while $18 to $1B are about to get
. this frame's. The rectangle wiped is the smallest one that covers both.
  $D5B2,8 the next index from the list
  $D5BA,5 $FF ends it
  $D5BF,12 bit 5 of byte 7 means it needs wiping; the others in the list
. are only being drawn again
  $D5CB,4 only once
  $D5CF,12 C = whichever of the new (byte $1A) and old (byte $1E) pixel x
. is further left
@ $D5DB label=wipe_right_edge
c $D5DB Find the right edge of the area to wipe
  $D5DB,12 the old right edge in bytes: old x / 8 + old width (byte $1C)
  $D5E7,15 the new one: new x / 8 + new width (byte $18); E = the further
. right
@ $D5F6 label=wipe_width
c $D5F6 The width of the area, and its bottom edge
  $D5F6,10 H = the width in bytes, from the left byte to the right edge
  $D600,11 B = the lower of the new (byte $1B) and old (byte $1F) pixel y
@ $D60B label=wipe_top_edge
c $D60B Find the top edge of the area to wipe
  $D60B,7 the old top: old y + old height (byte $1D)
  $D612,10 the new top: new y + new height (byte $19); A = the higher
@ $D61C label=wipe_height
c $D61C The height of the area, cut off at the top of the screen
  $D61C,2 L = the height in rows
  $D61E,5 an area that starts above the top of the screen has nothing to
. wipe
  $D623,9 if it runs past line 192, keep only the part below
@ $D62C label=wipe_rect
c $D62C Wipe the area in the buffer and remember it
  $D62C,6 DE = its display address, BC = its buffer address
  $D632,6 rearrange: HL = buffer address, B = width, C = height
  $D638,7 one more rectangle to copy
  $D63F,3 on the stack until the objects have been drawn
  $D642,4 cleared in the buffer: #R$C515 fills B bytes by C rows with A
  $D646,3 the next object
@ $D649 label=wipe_left_is_new
c $D649 The new x is the further left
@ $D64E label=wipe_bottom_is_new
c $D64E The new y is the lower
@ $D653 label=draw_and_copy_rects
c $D653 Draw the objects, then copy the wiped areas to the display
  $D653,3 every flagged object into the buffer, in depth order
  $D656,3 the sun or moon in the status area
  $D659,3 the objects the player carries
  $D65C,10 the rectangles count towards $5BBE, the frame's work, which
. sets how long #R$B000 waits
@ $D666 label=copy_next_rect
c $D666 Copy the next wiped area to the display
D $D666 They come off the stack last first, which does not matter: each is
. copied whole.
  $D666,7 none left
  $D66D,7 pop one, with width and height swapped into the order #R$D67C
. takes them
@ $D679 label=copy_rects_done
c $D679 All copied

c $D67C Copy a rectangle of the buffer to the display
R $D67C HL the buffer address of its bottom-left byte
R $D67C DE the display address of the same byte
R $D67C B the height in rows
R $D67C C the width in bytes
D $D67C Works up the screen a row at a time, the same way as #R$D56F, but
. leaves the buffer as it is. Used for the wiped areas at the end of a frame
. and by the status area, which draws into the buffer and copies its own
. parts out.
  $D67C,7 one row: B is cleared so that LDIR copies C bytes
  $D683,6 the buffer row above is 32 bytes on
  $D689,7 up a display line, unless that crossed a character row
  $D690,10 crossing a character row: back 32 in E, and back into this third
. unless that borrowed
@ $D69A label=blit_next_row
c $D69A Next row of the rectangle

c $D69E Build the lookup tables
D $D69E Fills #R$F100 and the fourteen pages above it at start-up with tables the drawing code needs
. every frame and would otherwise have to compute. At #R$F100 itself is the
. bit-reversal of every byte value. Reversing bits is how a sprite is mirrored
. horizontally, which is how the game gets a knight facing west out of one
. facing east.
D $D69E The fourteen pages from #R$F200 up are the shifted bytes, in pairs:
. for each shift s from 1 to 7, page $F0 + 2s holds every byte shifted right s
. places, and the page above it the bits that fall out into the next byte.
. Both are stored complemented. #R$D7AC uses one value from such a table to
. do two jobs: ANDed with the background it clears the bits under the mask,
. and XORed with the result and then complemented it adds the image.
  $D69E,2 every byte value, L from 0
@ $D6A0 label=shift_tbl_value
c $D6A0 Start on one byte value
  $D6A0,7 DE = the value; H on the top page; seven shifts
@ $D6A7 label=shift_tbl_entry
c $D6A7 Store the value shifted one place further
  $D6A7,4 one more place left across D and E: after k shifts E is the
. value shifted right 8 - k, and D what spills out of it
  $D6AB,3 E complemented on this page
  $D6AE,5 D complemented on the page below
  $D6B5,3 the next value
  $D6B8,3 from here up: reverse_bits(n) for n = 0 to 255
@ $D6BB label=reverse_tbl_value
c $D6BB Start reversing one byte value
@ $D6BE label=reverse_tbl_bit
c $D6BE Move one bit across
  $D6BE,4 a bit out of the bottom of D into the bottom of E: after eight, E
. is the value reversed
  $D6C4,4 store it; the next value, until L wraps to 0

c $D6C9 Project an object's position onto the screen
R $D6C9 IX the object
R $D6C9 F on exit, carry set if the pixel y is below 192, that is on the
. screen
D $D6C9 The isometric projection. The object's x, y and z (bytes 1 to 3)
. become a pixel x in byte $1A and a pixel y in byte $1B, counted up from the
. bottom of the screen:
D $D6C9 pixel x = x + y - 128, and pixel y = (y - x + 128) / 2 + z - 104.
D $D6C9 So a step in x moves one pixel right and half a pixel down, a step in
. y one pixel right and half a pixel up, and a step in z one pixel straight up
. -- the two-to-one slopes of the view. Bytes $12 and $13 are added on top:
. set by #R$C72B, they shift an object's picture without moving the object,
. for sprites whose artwork does not sit where the object stands.
  $D6C9,14 pixel x
  $D6D7,18 pixel y
  $D6E9,6 carry set if it is on the screen

c $D6EF Find an object's sprite and make it face the right way
R $D6EF IX the object
R $D6EF DE on exit, the sprite's header
D $D6EF Byte 0 of the record indexes #R$7112 for the sprite. A sprite whose
. first header byte is 0 is not drawn: the routine then throws away its own
. return address, so its RET leaves its caller too. Otherwise #R$D865 turns
. the stored data to match the object's flip bits and returns here with DE
. still on the header.
  $D6EF,13 DE = the sprite, from #R$7112
  $D6FC,5 a real sprite: see that it faces the right way
  $D701,3 no sprite: return from the caller as well

c $D704 Draw one object from the render list
R $D704 IX the object
D $D704 Called by #R$D003 for each object in depth order. Graphic 1 is not
. drawn: the record is emptied instead, by setting its graphic to 0, which
. frees the slot. That makes graphic 1 look like a marker for an object on its
. way out, but what sets it has not been traced from this range.
  $D704,7 graphic 1?
  $D70B,5 empty the record
@ $D710 label=project_and_draw
c $D710 Project the object and draw it if it is on the screen
  $D710,4 no longer waiting to be drawn
  $D714,4 above the top of the screen: nothing to draw

c $D718 Draw an object's sprite into the buffer, through its mask
R $D718 IX the object: its graphic in byte 0, its pixel position in bytes $1A
. and $1B, its flip bits in byte 7
D $D718 A sprite is a header -- width in bytes in bits 0 to 3, the flip state
. in bits 6 and 7, then the height in rows -- and then a pair of bytes for
. every byte of every row: a mask and an image. Rows are drawn from the bottom
. up. Each background byte is cleared where the mask is set and then has the
. image put in, so a sprite punches its own shape out of whatever was drawn
. before it and objects can overlap in depth.
D $D718 The row loop at #R$D7AA is unrolled for the widest sprite, five bytes,
. and this routine patches it for the one in hand: the offset of the JR at #R$D7AC
. decides how far into the unrolled code a row starts, and the operand of the
. ADD at #R$D800 how far BC must then move to reach the next row up. There are two unrolled
. runs. A sprite whose pixel x is a multiple of 8 uses the plain one; any
. other uses the shifted one, which reads its bytes through the tables from
. #R$F200 up and so touches one byte more per row.
D $D718 The stack pointer is borrowed to read the sprite: SP is pointed at
. the data and each POP DE fetches a mask byte into E and its image byte into
. D. The real SP is kept in $5BA9 meanwhile. The listing has no EI anywhere,
. so the game runs with interrupts off and nothing can push onto the sprite
. while SP is borrowed.
D $D718 Bytes $18 and $19 come out as the width and height actually drawn,
. which #R$D5B2 uses next frame to wipe the picture away. Only the top of the
. screen is clipped; nothing is clipped at the sides.
  $D718,3 DE = the sprite, turned the way byte 7 asks
  $D71B,7 x within its byte; 0 goes to the aligned case at #R$D76F
  $D722,6 H = $F0 + 2 * the shift, the page pair #R$D69E built for it
  $D728,9 the width from the header, plus one: the bytes a shifted row
. touches, into byte $18
  $D731,11 the JR offset for #R$D7AC: 16 bytes of code per byte of width,
. counted back from the end of the shifted run
@ $D73C label=patch_sprite_rows
c $D73C Patch the row loop for this width, and cut the height to the screen
R $D73C A the JR offset
R $D73C B the bytes a row touches
  $D73C,3 the JR at #R$D7AC
  $D73F,7 the step to the next row, into the ADD at #R$D800: 33 less the bytes touched,
. since a row moves BC on one fewer than that
  $D746,5 the height, into byte $19
  $D74B,15 if the sprite would run past the top of the screen, draw only
. the rows below it
@ $D75A label=draw_sprite_rows
c $D75A Draw the rows
  $D75A,9 BC = the buffer address of the sprite's bottom-left byte
  $D763,7 SP onto the pixel data, just after the two header bytes
  $D76A,5 A = the rows to draw; into the loop
@ $D76F label=sprite_aligned
c $D76F The byte-aligned case, and the start of its unrolled run
D $D76F For a sprite on a byte boundary each byte of a row is one unit of
. eight bytes of code: the background byte, cleared under the
. mask with CPL / OR E / CPL, has the image ORed in and is stored. Five units
. run on from the POP below, and the JR at #R$D7AC is set to enter them as
. many units from the end as the sprite is wide.
  $D76F,7 the width from the header, into byte $18
  $D776,8 the JR offset: 8 bytes of code per byte of width, back from the
. end of the aligned run
  $D780,16 the first two units of the aligned run
@ $D790 label=sprite_aligned_tail
c $D790 The last three units of an aligned row
  $D790,23 three more units the same, the last without the INC BC
  $D7A7,3 on to the next row
@ $D7AA label=sprite_row
c $D7AA Start a row
D $D7AA The row count goes to A', and A takes the first background byte:
. the shifted units expect the byte they are finishing to be in A already.
@ $D7AC label=sprite_row_jump
c $D7AC Jump into the row, then the shifted run
D $D7AC The JR's offset byte is patched by #R$D73C: back into the
. aligned run for a byte-aligned sprite, into the shifted run below for any
. other. Each shifted unit is 16 bytes of code for one source byte. The left
. part of the mask and image, looked up on page H, finishes the byte in A,
. which is stored; the right part, on page H + 1, starts the next buffer byte,
. which is left in A for the next unit. The last spill is stored after the
. fifth unit.
  $D7AC,2 offset set by #R$D73C
  $D7AE,8 the background byte in A, cleared under the mask shifted right
. and with the image shifted right put in; stored
  $D7B6,8 the bits that fall out, into the next buffer byte, left in A
  $D7BE,64 four more units the same
  $D7FE,1 store the last spilled byte
@ $D7FF label=sprite_row_end
c $D7FF Step to the row above
@ $D800 label=sprite_next_row
c $D800 Move BC up a row, and loop
  $D800,2 the step, its operand patched by #R$D73C
  $D802,5 carried into B
  $D807,5 the next row, until the height runs out
  $D80C,5 the real stack pointer back

c $D811 Buffer address of a pixel position
R $D811 C the pixel x
R $D811 B the pixel y, counted up from the bottom of the screen
R $D811 BC on exit, the address in #R$D8F3
D $D811 The buffer is plain rows of 32 bytes, the bottom line first, so the
. address is y * 32 + x / 8 from its start: BC shifted right three times.
  $D811,13 BC / 8 = y * 32 + x / 8
  $D81E,7 plus the start of the buffer

c $D826 Display address of a pixel position
R $D826 C the pixel x
R $D826 B the pixel y, counted up from the bottom of the screen
R $D826 DE on exit, the display address of that byte
D $D826 Turns the game's upward y into the display's line counted from the
. top by complementing it: 255 - y is that line plus 64, and the extra 64 is
. one third of the screen too many in the top bits, taken back by adding $38
. instead of $40.
  $D826,7 E = x / 8, the column
  $D82D,4 the line within the character row, from bits 0 to 2 of 255 - y,
. kept in A'
  $D832,8 bits 3 to 5, the character row within the third, into the top
. of E
  $D83A,13 bits 6 and 7, the third, with the line within the row, and $38
. for the extra third

c $D848 Attribute address of a pixel position
R $D848 H the pixel y, counted up from the bottom of the screen
R $D848 L the pixel x
R $D848 DE on exit, the attribute address
D $D848 HL is kept.
  $D849,9 H = (255 - y) / 8: the character row counted from the top,
. plus 8
  $D852,12 three more shifts across H and L: row * 32 + x / 8
  $D85E,5 $5700 is the attribute file less those 8 rows

c $D865 Turn a sprite's stored data to face the way its object wants
R $D865 DE the sprite's header
R $D865 IX the object
D $D865 Sprites are flipped in place, and the header remembers which way
. round the data now is: bit 7 of its first byte for upside down, bit 6 for
. mirrored. Bits 7 and 6 of the object's byte 7 say which way it wants to be
. drawn. Where they disagree the data is turned and the header bit toggled.
. An object that keeps facing one way therefore costs nothing after the first
. frame; two objects that share a sprite but face opposite ways turn it back
. and forth every time each is drawn.
D $D865 This part does the vertical flip, swapping whole rows end for end;
. #R$D8A2 does the mirror. DE is kept.
  $D865,9 the header's bit 7 against the object's: the same means no
. vertical flip
  $D86E,4 toggle the header's bit
  $D872,4 B = bytes per row: the width in bits 0 to 3, times two for the
. mask and image bytes
  $D876,4 C = the height in rows
  $D87A,10 HL = the data's length; DE = one past the end of the data, and
. HL its start
  $D884,6 DE on the last byte of the last row, HL on the last byte of the
. first
  $D88A,2 swap rows in pairs: half the height
@ $D88C label=vflip_row_pair
c $D88C Swap the next pair of rows

c $D88D Swap two rows byte by byte, working backwards
  $D88D,7 swap a byte of each row
  $D896,9 HL on to the end of the next row down; DE is already at the end
. of the row before its last
  $D89F,3 the next pair
@ $D8A2 label=hflip_sprite_data
c $D8A2 Mirror the sprite if its object wants it the other way round
D $D8A2 Mirroring a row is two things at once: the order of its bytes is
. reversed, and so are the bits of each byte. The bytes of a row are pushed as
. mask and image pairs, each byte reversed through the table at #R$F100 on the
. way; popped off again they come back last first, and are written over the
. same row.
  $D8A2,10 the header's bit 6 against the object's
  $D8AC,8 toggle the header's bit; B and C = the width in bytes
  $D8B4,4 the height into A'
  $D8B8,7 HL' reads and HL writes, both from the first row; B' = $F1,
. the page of the bit-reversal table
@ $D8BF label=hflip_read_row
c $D8BF Push a row's pairs, each byte reversed
  $D8BF,9 E' = the mask byte reversed, D' = the image byte reversed
  $D8C8,1 onto the stack, to come back last first
  $D8CC,1 the width again for the writing
@ $D8CD label=hflip_write_row
c $D8CD Write the row back in the reverse order
  $D8CD,7 a pair back, still mask then image
  $D8D4,8 the next row, until the height runs out
@ $D8DC label=flip_done
c $D8DC Return with DE on the header
@ $D8DE label=copyright_notice
b $D8DE Copyright notice
D $D8DE Twenty-one characters of plain text: the year and the initials of
. Ashby Computers and Graphics, the company behind Ultimate. No instruction
. in the listing refers to its address; it sits between the last routine and
. the screen buffer for anyone who looks through the memory.

@ $D8F3 label=screen_buffer
b $D8F3 The screen buffer
D $D8F3 6144 bytes -- one screen's worth of bitmap, no attributes. The drawing
. code composes a whole room here and then copies it to the display in one go,
. so a half-drawn room is never visible.

@ $F0F3 label=spare_bytes
b $F0F3 Thirteen bytes nothing uses
D $F0F3 Zeros between the end of the screen buffer and the page-aligned tables
. at #R$F100. Nothing in the code refers to them: the tables start on a page
. boundary, and these are what is left of the page the buffer ends in.

@ $F100 label=reverse_bits_tbl
b $F100 Bit reversal, built at run time
D $F100 A page holding every byte value with its bits reversed, which is how
. a sprite is mirrored left to right (#R$D8A2). Empty in a freshly loaded game
. and filled by #R$D69E. The disassembly
. covers the region anyway: it is part of the map, and a snapshot taken during
. play catches it holding real values.

@ $F200 label=shift_tbls
b $F200 Shift tables, built at run time
D $F200 Fourteen pages, a pair for each shift from 1 to 7: page $F0 + 2s holds
. every byte shifted right s places and the page above it the bits that fall
. out into the next byte, both stored complemented, so that one lookup serves
. to clear the bits under a sprite's mask and to add its image (#R$D7AC).
. Filled by #R$D69E; empty in a freshly loaded game.

# --------------------------------------------------------------------------
# Constants that look like addresses
# --------------------------------------------------------------------------
# These instructions load numbers that are not addresses -- pixel offsets and
# negative steps ($FE00 is -512, $FFE0 is -32) -- or, for the three LDs, an
# address SkoolKit rightly turns into a label. nowarn keeps skool2asm from
# reporting each one on every build.
@ $AFCE nowarn
@ $B626 nowarn
@ $B629 nowarn
@ $BA10 nowarn
@ $BA15 nowarn
@ $BE95 nowarn
@ $C4D3 nowarn
@ $C4E3 nowarn
@ $C4F2 nowarn
@ $C506 nowarn
@ $CDF2 nowarn
@ $D25F nowarn
