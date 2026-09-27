# Hand-written annotations for the Alien 8 disassembly.
#
# scripts/build_alien8.py generates a control file from a code-execution map
# (sna2ctl), puts the level data laid out by scripts/alien8_data.py in place
# of what sna2ctl guessed for those bytes, and layers THIS file on top. Never
# edit game_disassembly/alien8/*.ctl or *.asm by hand -- the next build
# overwrites both. Add what you learn here.
#
# Stage 1 (2026-09-27): the pipeline. What is here is thin on purpose: the
# entry points, the tables' titles and formats, labels for the variables the
# code names, the start records, and the buffers and leftovers above the
# game's code. Stage 2 describes every routine. A title here is a claim:
# each rests on a reading of the code, or on the game run in the simulator
# (the build's sessions), and nothing is named from a guess at intent. A
# variable read but not yet understood is UNKNOWN_<address>.
#
# Knight Lore's engine: the variables below sit in the same order as Knight
# Lore's, 160 bytes lower ($5B00 here for Knight Lore's $5BA0), and the
# object record is Knight Lore's 32 bytes. Where a label here is Knight
# Lore's name for the same offset, the Alien 8 code that uses it was read to
# check it does the same job; the Knight Lore annotations and
# game_disassembly/alien8/matches.txt (the build's cross-match, not
# committed) are the place to start for the rest.
#
# How far the code map can be trusted: all but 52 of the 4602 instructions
# were executed in SkoolKit's simulator by the build's own sessions (see
# game_disassembly/alien8/alien8-coverage.txt for the rest, which were found
# by following branches out of what ran).
#
# Format (SkoolKit control file):
#   @ $ADDR label=NAME     give the routine a name
#   c $ADDR Title          one-line title for the routine
#   D $ADDR Paragraph.     description under the title
#   R $ADDR HL What it is  an input/output register
#     $ADDR,N Comment      comment on the instruction(s) at $ADDR
#   E $ADDR Paragraph.     closing note under the routine
#   ; span $ADDR,LENGTH    a block that must stay whole (see the build)
#
# Draft instruction comments as ranges ("  $A-$B Comment") and let
# scripts/ctl_tools.py ranges fill in the lengths; never count them by hand.
# Never end a label with an underscore and a digit: skool2asm names jump
# targets NAME_0, NAME_1... and an explicit label of that shape collides.
#
# THE OBJECT RECORD. 56 records of 32 bytes at OBJECTS ($5B88): the robot's
# legs and top, two for what lies in the room from the table of places (the
# valves, and the extra lives), and 52 for the room itself, which the
# builder fills from ROOM_OBJECTS ($5C08) up. The fields, as the five
# describing agents read them (2026-09-27); each is described where the
# routine that uses it is:
#   +0 graphic (0: an empty record; 1: emptied when next drawn); it picks
#      the update routine (UPDATES, $A7EA) and the sprite (GRAPHICS, $7827)
#   +1 +2 +3 U, V, Z      +4 +5 the half-sizes in U and V   +6 the height
#   +7 flags: bit 0 in a doorway (walls off, exit armed); bit 1 out of
#      collisions; bit 2 pushable, and carried by what it stands on; bit 3
#      may use doorways; bit 4 to be drawn this turn (set at $CC01, cleared
#      at $D013); bit 5 wipe its old picture; bit 6 mirrored; bit 7 upside
#      down
#   +8 the room           +9 +A +B the step in U, V, Z this turn
#   +C bits 0-2 the move was stopped in U, V, Z (bit 2 either way: standing
#      on something, or a rising lift bumping its rider); bit 3 jumping;
#      bits 4-7 turns he walks on by himself after a doorway
#   +D bit 7 kills what it moves into; bit 5 kills what touches it; bit 6
#      killed; bit 3 met in Z by the robot or a mover of graphics 16-47;
#      bit 2 a lift's direction; on the legs, bit 0 the turn's direction and
#      bits 1-2 its count; bit 0 also set on a valve put down, which its
#      routine reads to redraw it
#   +E +F the doorway nudge
#   +10 +11 (a valve, an extra life) the address of its place (PLACES);
#      +10 is also a pacer's saved step, a scene object's colour, and the
#      real graphic kept while the robot appears
#   +12 +13 the drawing nudge   +14-+17 never used
#   +18 +19 the width and height drawn   +1A +1B the pixel position (for a
#      scene object, its screen x and line)   +1C-+1F last turn's copies,
#      kept to rub it out

# --------------------------------------------------------------------------
# Blocks that must stay whole: sna2ctl's guesses inside them are dropped
# (see declared_spans in build_alien8.py). Kept here together because a
# span inside an entry is lost when that entry is rewritten.
# --------------------------------------------------------------------------

; span $5B00,136
; span $5B88,1792
; span $6288,117
; span $C1D2,8
; span $C1DA,8
; span $C22D,8
; span $C235,8
; span $CA1D,64
; span $CA5D,16
; span $CA9E,4
; span $D1EB,21
; span $D200,6144
; span $EA00,1792
; span $F100,3840

# --------------------------------------------------------------------------
# Below the block: the variables and the object records
# --------------------------------------------------------------------------

# --------------------------------------------------------------------------
# Variables, object records and the first code
# --------------------------------------------------------------------------

# --------------------------------------------------------------------------
# Agent 1, part 1: $5B00-$62FC -- the variables and the object records.
# --------------------------------------------------------------------------

# Tables and buffers that must stay whole: sna2ctl's guesses inside them
# are dropped (see declared_spans in build_alien8.py). Kept here together
# because a span inside an entry is lost when that entry is rewritten.

@ $5B00 label=SEED
g $5B00 Game variables
D $5B00 Below the game block, where the BASIC loader's CLEAR left the printer buffer, the system variables and the loader itself: the bytes the snapshot holds here are those, not the game's. The first thing the game does (#R$A631) is read the ROM's frame counter into SEED and clear everything from here to the end of the object records; after every game it clears again from WIPE_COUNT on (#R$A647), so the first eight bytes -- the seed, the turn counter, the control method and the random number -- carry over from one game to the next.
D $5B00 Up to NO_HEADROOM this is Knight Lore's layout, 160 bytes lower, and where Alien 8 does the same job it keeps the same byte. The bytes nothing refers to are Knight Lore's variables for things Alien 8 does not have: the three after FLOOR the portcullises and the werewolf's change, the one after DRAW_WORK one spiked ball falling (Alien 8 keeps its own at DROPPING), the one after PLAYER_DZ the bouncing ball's step, the one after LIFT_TOP the rooms visited, the two after FONT_BASE the percentage. From CLOCK on the variables are Alien 8's own, and the rooms seen and the carried things sit at other places than Knight Lore's.
B $5B00,1 The seed. The ROM's frame counter when the game is first run (#R$A631), plus the turn counter's low byte at every new game (#R$A647), plus one each time round the menu (#R$BA7E). Bits 0-1 pick the start room (#R$CA6D); with the refresh register it picks the first kind of valve dealt (#R$AF3F)
B $5B01,1 Nothing refers to this byte (searched): as in Knight Lore, the byte after the seed is spare
@ $5B02 label=TURNS
B $5B02,1 The turn counter, a word, counted up at the end of every turn (#R$A6C0) and never cleared after the first game. Its low bits time things: the sparks of the scene after a game (#R$ABF5), the clockwork mice's speed (#R$AAA1), the sounds (#R$B690, #R$B676)
@ $5B03 label=TURNS_HIGH
B $5B03,1 Its high byte; the clockwork mice mix it with the random number for how far to walk (#R$AAA1)
@ $5B04 label=CONTROL
B $5B04,1 Control method, set on the menu (#R$BA7E): bits 1-2 are 0 keyboard, 1 Kempston, 2 cursor, 3 Interface II; bit 3 directional control, toggled by key 5
@ $5B05 label=RANDOM
B $5B05,1 The random number: R is added in after every object's update, and the turn counter and a byte of memory it points at at the end of every turn (#R$A6C0). Read wherever the game wants chance: a thing dropping (#R$AD13), a leaper starting (#R$A8F9), a mouse's turn (#R$AAA1), a tool's swing (#R$AB61), the dealing of the valves (#R$AF3F)
@ $5B06 label=CONTROL_BEFORE
B $5B06,1 The control method as it was before the menu read the keys this time round (#R$BA7E)
B $5B07,1 Nothing refers to this byte (searched); spare in Knight Lore too
@ $5B08 label=WIPE_COUNT
B $5B08,1 How many areas the drawing of a turn (#R$CEAB) has wiped and left on the stack to be copied to the screen; added to DRAW_WORK. The first byte cleared after a game (#R$A647)
@ $5B09 label=SAVED_SP
B $5B09,2 The stack pointer, while the sprite drawing borrows it (#R$D013, #R$D0BD)
@ $5B0B label=ROOM_HALF_U
B $5B0B,1 The room's half-size in U, from #R$6460 (#R$CCA7)
@ $5B0C label=ROOM_HALF_V
B $5B0C,1 The room's half-size in V
@ $5B0D label=ROOM_INK
B $5B0D,1 The room's ink, bits 0-2 of its record's third byte (#R$CCA7); white once its chamber is activated (#R$AF79). #R$A749 fills the screen's attributes with it, and colours the panel's label and chamber icon from it
@ $5B0E label=FLOOR
B $5B0E,1 The floor's height, from #R$6460 (#R$CCA7)
B $5B0F,3 Nothing refers to these bytes (searched): Knight Lore's portcullis and werewolf variables
@ $5B12 label=PLAYED
B $5B12,1 Bit 0 set at the end of every turn (#R$A6C0), cleared at a new game (#R$A647); while it is set, entering a room first writes what lies in the one being left back to its places (#R$CAA2, #R$AF05)
@ $5B13 label=TAKE_HELD
B $5B13,1 1 while the pick-up key is held, so one press does one thing (#R$BD6B)
@ $5B14 label=PANEL_DUE
B $5B14,1 Set on every press of the pick-up key that gets past #R$BD6B's first checks, whether or not anything changes hands; #R$BC9D then redraws the carried things on the panel and clears it
@ $5B15 label=INPUT
B $5B15,1 This turn's controls (#R$C8FF): bits 0 and 1 turn, 2 walk, 3 jump, 4 pick up or put down; bit 5 any letter key, ENTER or SYMBOL SHIFT, which is the pick-up when a joystick is used with directional control (#R$BD58). None are read while the game is won or over
@ $5B16 label=PRINT_ATTR
B $5B16,1 The colour byte a text list gives each line (#R$BC25), read by the printer (#R$BB9D)
@ $5B17 label=NEW_ROOM
B $5B17,1 Set when a room has been built (#R$CAA2) and when the scene after a game is set up (#R$B761). The turn's drawing (#R$CEAB) then wipes nothing, and the main loop (#R$A6C0) draws the panel, colours the screen, copies the whole buffer out and clears it
@ $5B18 label=TEXT_SHOWN
B $5B18,1 0 until a text list has been printed and the screen copied once (#R$BC25); the menu and the arrival screen clear it
@ $5B19 label=PLACE_NUDGE
B $5B19,1 Added to the objects' positions by the builder (#R$CCA7); set by a template-0 header in a room's record
@ $5B1A label=LIVES
B $5B1A,1 Lives, counted in binary but printed on the panel as though BCD (#R$BA57): five at a new game (#R$A647), one taken at the start of every life (#R$CA07), so the one in play and four more; the game is over when there is none to take. An extra life adds one (#R$BEE0)
@ $5B1B label=SAVED_UVZ
B $5B1B,3 An object's U, V and Z before its move, saved by #R$B2D9 and compared after it by #R$B2EB, so #R$B2FF can tell whether it was moved
@ $5B1E label=DRAW_WORK
B $5B1E,1 The turn's drawing work: #R$C785 zeroes it and counts every object it draws, #R$CEAB adds the areas it wiped, and the main loop (#R$A6C0) waits six units less this
B $5B1F,1 Nothing refers to this byte (searched): Knight Lore's "a spiked ball is falling"
@ $5B20 label=TEMPLATES_AT
B $5B20,1 The object template table the builder reads, a word with the next byte (#R$73C8, #R$CCA7): a template-31 header moves it on to the second page
@ $5B21 label=PLAYER_DZ
B $5B21,1 The player's step in Z this turn (#R$C296) -- and the high byte of TEMPLATES_AT while a room is being built
B $5B22,1 Nothing refers to this byte (searched): Knight Lore's bouncing ball's step
@ $5B23 label=WON
B $5B23,1 Set when the twenty-fourth chamber is activated (#R$AF79). The game then ends with the arrival screen (#R$B761, #R$B8A9) and the robot's oiling (#R$A971) instead of the re-programming; while it is set the panel's carried things are not redrawn (#R$BC9D)
@ $5B24 label=GAME_OVER
B $5B24,1 1 while the scene after a game runs in the main loop (#R$B761): objects are then placed in pixels rather than projected (#R$CFD2), the main loop neither waits nor runs the clock (#R$A6C0), and no controls are read (#R$C8FF). Cleared with the rest when the scene ends (#R$A647)
@ $5B25 label=LIFT_TOP
B $5B25,1 The height the room's lifts rise to, one for them all: zero when a room is built (#R$CCA7), then set by the first lift or bobbing block to run (#R$B31F) -- a lift (graphic 47) its own Z plus 48, a bobbing block (graphic 31) its own Z. Measured: 112 in room $23, 100 in room $1D. Knight Lore keeps its bouncing balls' turning height the same way
B $5B26,1 Nothing refers to this byte (searched): Knight Lore's count of rooms visited
@ $5B27 label=FONT_BASE
B $5B27,2 The base the printer adds eight times a character's code to (#R$BA57, #R$BB9D): #R$6308 less 384 for text, #R$6308 itself for numbers (#R$AD66)
B $5B29,2 Nothing refers to these bytes (searched): Knight Lore's percentage
@ $5B2B label=SEQUENCE_AT
B $5B2B,2 Where the turn's drawing (#R$CEAB) is in the list of records to draw at #R$C745, which #R$C71C makes and ends with $FF
@ $5B2D label=SORT_FIRST
B $5B2D,2 A place in the depth sort's list (#R$C785)
@ $5B2F label=SORT_SECOND
B $5B2F,2 Another (#R$C785)
@ $5B31 label=TUNE_HEARD
B $5B31,1 Bit 0 set once the menu's tune has played (#R$B4A1), so it plays once each time the menu is shown, not at every pass of the menu's loop; the clear after a game (#R$A647) lets it play again
@ $5B32 label=KEY5_HELD
B $5B32,1 1 while key 5 is held on the menu, so one press toggles directional control once (#R$BA7E)
@ $5B33 label=NO_HEADROOM
B $5B33,1 1 when there is no room above him to stand on what he puts down (#R$BD6B)
@ $5B34 label=ROOM_COLOUR_AT
B $5B34,2 The address of the room record's third byte, its size and colours (#R$CCA7); an activated chamber's white ink is written there (#R$AF79), so the room stays white until the next game
@ $5B36 label=CLOCK
B $5B36,2 The light years left, four bytes, the highest digit first: each a digit in bits 4-7 and, in bits 0-2, how far it still has to roll into place. 6000 at a new game (#R$A647); counted down by #R$AD66 every turn, a light year every seven turns; the game is over when all four are zero
@ $5B38 label=CLOCK_LOW
B $5B38,1 The third digit
@ $5B39 label=CLOCK_LAST
B $5B39,1 The last digit: #R$ADC9 takes a light year off when it has finished rolling
@ $5B3A label=DROPPING
B $5B3A,1 1 while one of the things that drop from the ceiling is falling, so only one falls at a time (#R$AD13); cleared on entering a room (#R$CAA2)
@ $5B3B label=DROP_LATCH
B $5B3B,1 While it is set nothing drops from the ceiling (#R$AD13): set on entering an even-numbered room (#R$CAA2), cleared by a pick-up (#R$BD6B) or an extra life (#R$BEE0). As Knight Lore's spiked balls
@ $5B3C label=SUMMARY_LOST
B $5B3C,1 The summary after a game (#R$AC6B), worked out from the room directory and the places. The cryonauts lost -- the frozen crew, object templates 21 and 22 (graphic 74), in the chambers not activated -- a BCD word, high byte first; 132 when none is activated. #R$BA36 prints three digits
@ $5B3D label=SUMMARY_LOST_LOW
B $5B3D,1 Its low byte
@ $5B3E label=SUMMARY_ACTIVE
B $5B3E,1 Chambers activated, BCD: the crew rooms where a seated valve (graphics 100-103) lies (#R$AC6B)
@ $5B3F label=SUMMARY_IDLE
B $5B3F,1 Chambers not activated, BCD (#R$AC6B)
@ $5B40 label=CHAMBERS
B $5B40,1 Chambers activated in this game, BCD (#R$AF79), printed on the panel (#R$A7A3); the twenty-fourth wins
@ $5B41 label=SCENE_STATE
B $5B41,1 The re-programming after a lost game. 0 while the sparks over the robot flash; 1 when they stop (#R$ABF5); then bit 7 is set while one of the three tools swings (#R$AB61) and bits 0-6 count the swings, the scene ending at 16
@ $5B42 label=REMOTE_ORDERS
B $5B42,1 The remote-controlled robots' orders. Bit 7: one robot has taken control (#R$A9C7). Bits 0-6: what he stands on this turn -- 1 the pad (#R$AA4D), 2-5 a button (#R$AA63), each a step in U or V (#R$AA43) -- taken by the robot in control as it moves; cleared on entering a room (#R$CAA2)
@ $5B43 label=LEAPING
B $5B43,1 1 while one of the room's leapers (graphic 130) is in the air, so they leap one at a time (#R$A8F9): set when one starts, cleared when it lands and on entering a room (#R$CAA2)
B $5B44,20 Nothing refers to these bytes (searched)
@ $5B58 label=ROOMS_SEEN
B $5B58,32,8 A bit per room number, set on entering the room (#R$B863): 256 bits, byte room/8, bit room AND 7. Counted for the rating after a game (#R$B881)
@ $5B78 label=CARRIED_NEW
B $5B78,4 What he carries -- only valves can be picked up -- in entries of four bytes: the graphic, the flags and the address of its place. This one is where a thing being picked up is put (#R$BD6B) before the list moves on one; empty between presses
@ $5B7C label=CARRIED
B $5B7C,8,4 The things he carries, newest first (drawn on the panel by #R$BC9D)
@ $5B84 label=CARRIED_LAST
B $5B84,4 The oldest, which the next press puts down (#R$BD6B)

@ $5B88 label=OBJECTS
b $5B88 The object records
D $5B88 Everything in the room: 56 records of 32 bytes. The first four have fixed jobs -- the robot's legs and top, and two for what lies in the room from the table of places (#R$76E3) -- and the other 52 are the room's, filled by the builder (#R$CCA7). The main loop (#R$A647) runs every record's update routine once a turn, in order, empty ones included. In the scene after a game the same records hold the scene's pieces (#R$B804).
D $5B88 A record is Knight Lore's 32 bytes. +0 the graphic, which picks the update routine (#R$A7EA) and the sprite (#R$7827): 0 an empty record, 1 one to be rubbed out and emptied when next drawn. +1 +2 +3 U, V and Z. +4 +5 +6 the half-sizes in U and V and the height. +7 flags: bit 0 in a doorway, bit 1 out of the collision tests, bit 2 can be pushed and rides what it stands on, bit 3 may use doorways (the legs), bit 4 to be drawn this turn, bit 5 moved: wipe it and copy it to the screen (#R$BFAB sets both), bit 6 mirrored, bit 7 upside down. +8 the room. +9 +A +B the step in U, V and Z this turn.
D $5B88 +C: bits 0-2 the move was stopped in U, V, Z -- bit 2 either way, standing on something or bumping something above -- bit 3 jumping, bits 4-7 turns of walking in after a doorway. +D: bit 7 kills what it moves into and bit 5 kills what touches it (#R$B2A4 sets both), bit 6 killed, bit 3 landed on, by the robot or a mover of graphics 16-47, bit 0 just put down (a valve reads it, #R$AF79); bit 2 is a kind's own (a dropping thing falling, a lift's direction), and on the legs bits 1-2 keep his turning. +E +F the player's nudge from a doorway; +F is also a dropping thing's "was standing" (#R$AD54) and a scene tool's steps (#R$AB61). +10 +11: for what lies in the room from the places, the address of its place (#R$AE99); for other kinds their own counters and states, described with each update routine (in the robot's records and the start records, #R$CA1D, the real graphic kept while he is appearing; a pacer's saved step, a leaper's height, a mouse's turns, a scene piece's colour ...). +12 +13 the drawing nudge in pixels (#R$BF3D and the entries beside it). +14 to +17: no instruction was found using them. +18 +19 the sprite's width in bytes and height in rows as drawn; +1A +1B its pixel x and y, counted up from the bottom -- in the scene after a game set directly, as the scene is not projected (#R$B804); +1C to +1F the same four as they were before this turn's update (the main loop, #R$A647).
D $5B88 Below the game block, like the variables: the bytes the snapshot holds here are the ROM's system variables and the BASIC loader, which the game clears before it uses them (#R$A631).
B $5B88,1 Record 0, the robot's legs, the whole of his collision box: graphic (16-23 walking, 48 on the dying sparkle, 56-62 materialising)
@ $5B89 label=PLAYER_U
B $5B89,1 U, read by the things that home in on him (#R$B165)
B $5B8A,5 V, Z, the half-sizes and the height
@ $5B8F label=PLAYER_FLAGS
B $5B8F,1 Flags; the first of the 56 bytes whose bit 5 #R$A7DC clears
@ $5B90 label=PLAYER_ROOM
B $5B90,1 The room he is in: what the builder builds (#R$CCA7), what #R$AE99 matches the places against, and the bit set in ROOMS_SEEN (#R$B863)
B $5B91,23,8 The rest of the legs' record
@ $5BA8 label=PLAYER_TOP
B $5BA8,32,8 Record 1, the robot's top, which copies the legs every turn and sits 12 above them; the main loop starts a new life when both it and the legs are empty (#R$A6C0)
@ $5BC8 label=VALVES
B $5BC8,32,8 Record 2: the first thing from the table of places in this room -- a valve, loose or seated, or an extra life -- built by #R$AE99 and written back by #R$AF05; a thing put down goes into whichever of the two is empty (#R$BD6B)
@ $5BE8 label=VALVE_SECOND
B $5BE8,32,8 Record 3: the second
@ $5C08 label=ROOM_OBJECTS
B $5C08,112,8 Records 4 to 55, the room's: backgrounds and objects, filled by the builder from here up (#R$CCA7)
@ $5C78 label=FRAMES
B $5C78,3 In the snapshot, the ROM's frame counter: the game reads its low byte for the seed (#R$A631) before it clears this area
B $5C7B,1549,8 The rest of the room's records

@ $6288 label=BELOW_BLOCK
u $6288 Unused
D $6288 Between the object records and the game block. Nothing in the game refers to these bytes (searched), and none was touched in the simulator from the entry into play; what the snapshot holds is what the BASIC loader left on its stack under RAMTOP.

# --------------------------------------------------------------------------
# Agent 1, part 2: $A631-$B054 -- starting, the main loop, the panel's
# colours and counts, the update routines of the chambers, the valves, the
# remote-controlled robots and the scenes after a game, the summary, the
# clock, and the places the valves lie.
# --------------------------------------------------------------------------

@ $A631 label=START
c $A631 Start the game
D $A631 Entered from #R$6300 when the game is first run. Clears the variables and all 56 object records, from #R$5B00 up to #R$6288, keeping only the ROM's frame counter, which becomes the seed (#R$5B00): a machine switched on for a different time gets a different game. The frame counter has to be read first because it lies inside the object records (FRAMES, in record 7), which the clear wipes.
D $A631 As Knight Lore's cold start, but for the call to #R$A8F1, which does nothing that lasts.
  $A631,6 from #R$5B00 up to #R$6288: the variables and the 56 object records
  $A637,4 FRAMES, the ROM's frame counter, kept on the stack
  $A63B,7 clear them, and the counter becomes the seed
  $A642,3 a leftover that returns at once
  $A645,2 and set up a game

@ $A647 label=AFTER_GAME
@ $A650 label=MAIN_NEW_GAME
@ $A688 label=MAIN_NEW_LIFE
@ $A68B label=MAIN_NEW_ROOM
@ $A68E label=MAIN_NEXT_TURN
@ $A692 label=MAIN_NEXT_OBJECT
@ $A695 nowarn
@ $A6B1 label=MAIN_DISPATCH
@ $A6B7 label=JUMP_THROUGH_TABLE
c $A647 Back to the menu after a game, set up a game, and run it
D $A647 Reached when the scene after a game ends (#R$AB61, #R$A971). Clears from WIPE_COUNT to the end of the object records, so the seed, the turn counter, the control method and the random number carry over, and falls into the setting up of a game at MAIN_NEW_GAME, where #R$A631 joins.
D $A647 A new game builds the drawing tables, has five lives, 6000 light years, and no room played yet; stirs the last game's turn count into the seed; clears the screen and shows the menu (#R$BA7E); plays the start tune; puts the robot in one of four start rooms (#R$CA6D); deals the valves and extra lives to their places (#R$AF3F); and gives every room back its colour (#R$CAD2), undoing the white of the chambers activated last game.
D $A647 Then three loops, one inside the other, each with its own entry: MAIN_NEW_LIFE starts a life (#R$CA07) and falls into MAIN_NEW_ROOM, which builds the room he is in (#R$CAA2) -- leaving a room comes back here from #R$C397 -- and falls into MAIN_NEXT_TURN, the start of a turn. MAIN_NEXT_OBJECT runs one record's update routine: the stack is reset to #R$F100 for every object, the address of #R$A6C0 is pushed for the routine's RET to go to, and the record's last drawn size and place are kept (+18 to +1B into +1C to +1F) so that its old picture can be wiped. MAIN_DISPATCH jumps through #R$A7EA by the graphic; JUMP_THROUGH_TABLE jumps through any table of words by the index in L and the table in BC, and #R$C2F6 and #R$C785 use it too.
D $A647 Knight Lore's main and its object walk, with the clock where the sun and moon were and nothing for the cauldron; the stack is Alien 8's own, above the screen buffer, where Knight Lore's is below its variables.
  $A647,9 from WIPE_COUNT up to #R$6288
  $A650,3 the tables at #R$F100
  $A653,4 no room played yet, so the first room built has nothing to write back
  $A657,3 clear the start legs' +C: not jumping, not standing
  $A65A,5 five lives: the first life takes one
  $A65F,12 6000 light years: the first digit 6, the rest 0, none rolling
  $A66B,8 stir the turn counter into the seed; it is zero on the first game after loading
  $A673,3 clear the screen, border black
  $A676,3 the menu, until 0 is pressed
  $A679,6 the tune that plays as a game starts
  $A67F,3 the start records and the start room
  $A682,3 deal the valves and the extra lives
  $A685,3 every room's colour from its record
  $A688,3 a life: the robot from the start records, a life fewer
  $A68B,3 build the room he is in
  $A68E,4 the first record
  $A692,3 a fresh stack for every object
  $A695,4 its update routine returns to #R$A6C0
  $A699,24 keep last turn's size and place on the screen, to wipe
  $A6B1,6 the graphic indexes #R$A7EA
  $A6B7,9 HL = BC + 2 * L; jump to the word there

@ $A6C0 label=OBJECT_DONE
@ $A6DC label=MAIN_END_OF_TURN
c $A6C0 After each object's update routine; the end of a turn
D $A6C0 Every update routine returns here: the main loop pushes this address before it jumps to one. The refresh register is stirred into the random number, so the sequence depends on how much work the turn did, and the loop goes on to the next record -- or, after the last, ends the turn.
D $A6C0 The end of a turn, MAIN_END_OF_TURN: count the turn, stir the random number again, note that a turn has been played, list and draw what changed, and then pad the turn out: the drawing counts its work in DRAW_WORK, and the loop waits six units less that, a unit being 768 turns of a 26 T-state loop, about 20,000 T-states. A room where little moves runs at the speed of one where six things are drawn; a busier room runs slower. Then the clock, which can end the game (#R$AD66).
D $A6C0 On the first turn in a room the panel is drawn and coloured (#R$CB0F, #R$A749) and the whole buffer copied to the screen. Then the pause key (#R$CE22), and a new life if both of the robot's records have emptied -- they do when his dying sparkle ends -- or the next turn.
D $A6C0 While the scene after a game runs (GAME_OVER) there is no waiting and no clock.
  $A6C0,10 R changes with every instruction fetched
  $A6CA,14 the next record, until #R$6288, the end of the records
  $A6D8,4 not there yet: the next object
  $A6DC,7 count the turn
  $A6E3,9 stir in the turn counter and whatever byte it addresses
  $A6EC,5 a turn has been played: the next room built writes back the valves
  $A6F1,3 list the records flagged to be drawn
  $A6F4,3 wipe, draw in depth order and copy the changes to the screen
  $A6F7,7 the scene after a game: no delay, no clock
  $A6FE,13 six units, less the turn's drawing; none if that is six or more
  $A70B,3 about 20,000 T-states a unit
  $A70E,7 26 T-states a turn
  $A715,3 the light years: may end the game
  $A718,6 not the first turn in a room
  $A71E,6 draw the panel, and colour the screen and the panel
  $A724,7 once only; the whole buffer to the screen
  $A72B,3 nothing drawn so far needs wiping
  $A72E,3 pause, if SPACE or CAPS SHIFT alone is pressed
  $A731,13 his legs and top both empty: start a life
  $A73E,3 the next turn
  $A741,8 in the scene: only the whole-screen copy of its first turn

@ $A749 label=COLOUR_PANEL
c $A749 Colour the screen and the panel for the room
D $A749 On the first turn in a room (#R$A6C0) and when a chamber is activated (#R$AF79). The whole attribute file gets the room's ink, bright on black, and then the panel its colours: the lives bright white, the light-years box red round white digits (#R$A7AE), the carried things (#R$BC9D, part way in), the LIGHT YEARS label and the chamber icon in a colour chosen from the room's ink, and the count of chambers and of lives.
D $A749 The label's colour is 2 plus 7 less the room's ink, bright on black: never the room's own colour for the inks the rooms use (3 to 6 on the tape, and 7 once a chamber is activated), and red in an activated chamber. It is written into the first byte of the label's text (#R$A797), where the printer takes a line's colour from, and read back from there for the icon.
  $A749,8 the whole screen in the room's ink, bright on black
  $A751,18 the lives, bright white
  $A763,3 the light-years box
  $A766,3 the carried things
  $A769,11 2 + (7 - ink), bright: the label's colour, into its text
  $A774,9 print LIGHT YEARS at the foot of the screen, right of centre
  $A77D,3 the count of chambers
  $A780,8 its two digits bright white
  $A788,12 the chamber icon, three by three cells at the left, in the label's colour
  $A794,3 and the lives

@ $A797 label=LIGHT_YEARS_TEXT
t $A797 The panel's label
D $A797 The words LIGHT YEARS for the panel, in the printer's form (#R$BBB1): a colour byte, then the text, the last character with bit 7 set (#R$A7A2). The colour byte is written by #R$A749 before every printing; on the tape it is 'E'.
T $A797,11,h1:10 The colour, then LIGHT YEAR

@ $A7A2 label=LIGHT_YEARS_TEXT_END
b $A7A2 The end of the panel's label
D $A7A2 The last letter of #R$A797, S with bit 7 set to end the string.
B $A7A2,1 S, the last

@ $A7A3 label=PRINT_CHAMBERS
c $A7A3 Print the count of chambers activated
D $A7A3 The two BCD digits of CHAMBERS into the buffer at the panel's left, beside the chamber icon, with the digits of the font (#R$BA57 sets the base so that digit n is character n).
  $A7A3,11 one byte, two digits

@ $A7AE label=COLOUR_CLOCK_BOX
c $A7AE Colour the light-years box
D $A7AE Three rows of six attribute cells at the right of the panel, from #R$A7CA: a bright red frame round the four digits in bright white.
  $A7AE,9 row 20, column 25; three rows of six
  $A7B7,8 a row
  $A7BF,6 the next row down
  $A7C5,5 three rows

@ $A7CA label=CLOCK_BOX_COLOURS
b $A7CA The light-years box's colours
D $A7CA Read by #R$A7AE. They happen to be the codes of the letters B and G: $42 bright red, $47 bright white.
B $A7CA,18,6 Three rows of six: red round the edge, white behind the digits

@ $A7DC label=CLEAR_WIPE_FLAGS
c $A7DC Clear every object's wipe flag
D $A7DC Bit 5 of +7 marks an object whose old picture must be wiped. After the whole screen has just been copied out (#R$A6C0) there is nothing to wipe.
  $A7DC,14 all 56 records, from the legs' flags

w $A7EA Update routines, by graphic
D $A7EA A word per graphic number, 0 to 130: the routine the main loop (MAIN_DISPATCH, in #R$A647) jumps to for a record holding that graphic. Graphic 131 has a sprite (#R$7827) but no entry here.
D $A7EA This table is the only way in to the update routines, so they have no "Used by" line; each one's title names the graphics that reach it. A routine changes what an object does, as well as how it looks, by changing its graphic: a valve seated on its socket goes from 96-99 to 100-103, and a dying thing runs through the sparkle's graphics.

@ $A8F0 label=NO_UPDATE
c $A8F0 An update routine that does nothing
D $A8F0 Reached through #R$A7EA for graphics 0 and 1 (an empty record), 4 to 10, and 84.

@ $A8F1 label=R_CHECK_LEFTOVER
c $A8F1 A leftover that returns at once
D $A8F1 Called once, by #R$A631. It loads HL with 0 and rotates R's top bit into the carry, and nothing uses either. With the byte after it, #R$A8F8, a JP (HL), it reads like the remains of a check that jumped to address 0 -- a reset -- when bit 7 of R was set, which only an LD R,A can do; with a plain RET where a conditional return would be, it never jumps.

@ $A8F8 label=JP_HL_LEFTOVER
b $A8F8 An unused JP (HL)
D $A8F8 The opcode of JP (HL), after the RET of #R$A8F1 and never reached: see there.
B $A8F8,1 JP (HL)

@ $A8F9 label=LEAPER
c $A8F9 A leaper (graphic 130)
D $A8F9 Reached through #R$A7EA. A deadly thing that now and then leaps 48 units straight up and falls back. Only one in a room is in the air at a time (LEAPING); when none is, each on its turn has a chance of one in four of going. It rises two units a turn until it is 48 above where it started or meets something above it, then falls under gravity, with a sound pitched by its height all the while, and lands.
D $A8F9 +10: bit 0 in the air, bit 1 falling. +11: the height to leap to. Rooms $97, $A9 and $B7 have them (object template 39).
  $A8F9,3 draw 16 left and 9 down
  $A8FC,3 deadly both ways
  $A8FF,6 in the air
  $A905,5 another is in the air
  $A90A,7 one turn in four
  $A911,16 leap: the flag, and the height to reach, 48 up
  $A921,6 not falling yet
  $A927,3 fall
  $A92A,13 landed: on the floor again, and another may leap
  $A937,6 a sound pitched by its height; redraw
  $A93D,7 rising: two units a turn (3, less one for gravity)
  $A944,16 not yet at the top, and nothing above
  $A954,6 now fall

@ $A95A label=SCENE_ROBOT_TOP
c $A95A The robot's top in the ending (graphic 93)
D $A95A Reached through #R$A7EA. In the scene after the twenty-fourth chamber (#R$B761) the robot is two records, legs (graphic 92, #R$A971) and top; the top keeps 16 pixels above the legs, in their colour and with their flags, so it is wiped and redrawn with them, and colours its cells (COLOUR_SCENE_OBJECT, in #R$ABF5).
  $A95A,8 16 pixels above the legs (the record before: -5 is its +1B)
  $A962,6 its colour
  $A968,6 its flags
  $A96E,3 colour the cells it covers

@ $A971 label=OILED_ROBOT
c $A971 The robot being oiled, in the ending (graphic 92)
D $A971 Reached through #R$A7EA: the scene after the twenty-fourth chamber, set up by #R$B761 in pixels (the scene is not projected). The robot waits 64 turns, is lowered three pixels a turn into the can of oil (graphic 85) until it is below 40, stays there while its count runs on to 128, then rises three pixels a turn, now bright white, to 128, with a sound pitched by its height as it moves. Then a tune, and back to the menu (#R$A647).
D $A971 +11 counts: 0 to 63 waiting; 64 going down and then counting at the bottom; 128 and over going up. +10 is its colour (COLOUR_SCENE_OBJECT, in #R$ABF5).
  $A971,7 the first 64 turns: wait
  $A978,4 128 on: going up
  $A97C,7 at the bottom: count
  $A983,5 three pixels down
  $A988,6 a sound pitched by its height; redraw
  $A98E,3 colour its cells
  $A991,5 count on
  $A996,7 at the top: done
  $A99D,9 three pixels up, now bright white
  $A9A8,9 a tune, and back to the menu

@ $A9B1 label=FRAGILE
c $A9B1 A thing that breaks when moved (graphic 129)
D $A9B1 Reached through #R$A7EA. Deadly both ways, and pushable (its template, 38, gives it flags $14), but it never moves itself: as long as nothing has given it a step it stays. Once something moves it, it turns into graphic 54, the last frame of the sparkle a thing dies in (#R$B3A4), and so vanishes. The player cannot push one and live; the remote-controlled robots (#R$A9C7), harmless, can, and six of the seven rooms that have these have a robot to clear them. The seventh, room $72, has some two dozen and two clockwork mice (#R$AAA1), which run into them and break them: 28 in the room's record and on its first turn -- the mice break some while the robot is still appearing, so 24 were counted once he was playing -- and 10 left after 30 seconds of play in the simulator (measured).
  $A9B1,3 draw 12 left and 4 down
  $A9B4,12 not moved: deadly, and that is all
  $A9C0,7 moved: the end of the sparkle

@ $A9C7 label=REMOTE_ROBOT
c $A9C7 A remote-controlled robot (graphics 124 to 127)
D $A9C7 Reached through #R$A7EA. One in each of eight rooms, two in room $0B, each room with four buttons (#R$AA63) and a pad (#R$AA4D) that the player stands on to drive it. One robot at a time is in control: bit 7 of REMOTE_ORDERS says one has it, and bit 7 of its own +10 which. The first robot to run while no one has control takes it. While the player stands on a button the robot in control steps two units a turn in the button's direction (#R$AA43), animating through its four graphics, with a sound; on the pad it animates on the spot. When he steps off, it gives control up and the next robot to run takes it -- so the two in room $0B take turns, one for each time he steps off a button or the pad (measured there).
D $A9C7 Otherwise a robot falls under gravity, with a sound pitched by its height while it moves. They are harmless, and there to push things: the rooms that have them are the rooms of the things that break when moved (#R$A9B1), all but room $0B.
D $A9C7 +10: bit 7 in control, waiting; bit 6 in control, moving.
  $A9C7,3 draw 16 left and 9 down
  $A9CA,8 no robot in control: take it
  $A9D2,7 not this one: just fall
  $A9D9,6 waiting for an order
  $A9DF,5 moving, and another order
  $A9E4,13 no order: give control up, and stop
  $A9F1,3 fall, and move by the step
  $A9F4,4 not moving: done
  $A9F8,6 a sound pitched by its height; redraw
  $A9FE,8 take control
  $AA06,5 waiting, and still no order
  $AA0B,10 an order: from waiting to moving
  $AA15,3 take the order; control stays taken
  $AA18,10 the order's pair of steps
  $AA22,10 the step in U and in V
  $AA2C,3 the next of its four graphics
  $AA2F,11 a step to take: take it
  $AA3A,9 its sound; redraw

@ $AA43 label=REMOTE_STEPS
b $AA43 The remote-controlled robots' steps
D $AA43 A pair of steps in U and V for each order in REMOTE_ORDERS, 1 to 5 (#R$A9C7): the pad stands still; the buttons, graphic 122 and 123 each plain and mirrored (#R$AA63), step two units along one axis.
B $AA43,10,2 Order 1 (the pad) none; 2 -2 in U; 3 +2 in V; 4 +2 in U; 5 -2 in V

@ $AA4D label=REMOTE_PAD
c $AA4D The remote-control pad (graphic 128)
D $AA4D Reached through #R$A7EA. When something lands on it -- the collision code gives what it lands on its step in Z, so a non-zero step means something is standing on it this turn -- it takes the step back and orders the robot in control to stand still (order 1). Stepping off it passes control to the other robot, as stepping off a button does (#R$A9C7).
  $AA4D,3 draw 16 left and 9 down
  $AA50,5 nothing on it
  $AA55,4 it does not move
  $AA59,10 order 1, keeping bit 7

@ $AA63 label=REMOTE_BUTTON
c $AA63 A remote-control button (graphics 122 and 123)
D $AA63 Reached through #R$A7EA. As the pad (#R$AA4D), but the order is 2 to 5, from which of the two graphics it is and whether it is mirrored: four buttons, a direction each (#R$AA43).
  $AA63,3 draw 16 left and 9 down
  $AA66,5 nothing on it
  $AA6B,4 it does not move
  $AA6F,7 bit 6 of its flags, mirrored, to bit 7
  $AA76,10 order = 2 + 2 * (graphic AND 1) + mirrored
  $AA80,9 into the orders, keeping bit 7

@ $AA89 label=SLOW_CHASER
c $AA89 A thing that homes in on the player (graphics 120 and 121)
D $AA89 Reached through #R$A7EA. Deadly both ways; every turn it steps one unit towards the player in U and in V (#R$B165), falls under gravity, flips between its two graphics, and makes its sound. Rooms $5E and $D8 have them (object template 29).
  $AA89,3 draw 12 left and 4 down
  $AA8C,6 one unit towards him in U and V
  $AA92,3 fall, and move
  $AA95,3 the other graphic
  $AA98,6 its sound
  $AA9E,3 deadly both ways; redraw

@ $AAA1 label=CLOCKWORK_MOUSE
c $AAA1 A clockwork mouse (graphics 116 to 119)
D $AAA1 Reached through #R$A7EA. Deadly both ways. It runs straight along U or V at two to five units a turn, flipping between two graphics as it goes, for a random number of turns up to 15 (none left counts as 256); when it is stopped, is blocked, or has run its turns it beeps and turns a quarter, left or right at random, with a new speed and a new count.
D $AAA1 The way it faces is its mirror flag (bit 6 of +7: clear along U, set along V) and bit 1 of its graphic (which way along it); a turn always flips the mirror flag, so always changes the axis, and flips bit 1 or not by the random number. The speed is the turn counter's low two bits plus two. +10 counts the turns left. Rooms $3F, $42, $45, $4D, $72, $A9 and $D8 have them (object template 28).
  $AAA1,3 draw 12 left and 6 down
  $AAA4,3 fall, and move
  $AAA7,8 not moving: turn
  $AAAF,7 blocked in U or V: turn
  $AAB6,5 its turns run out: turn
  $AABB,3 the other of its two graphics
  $AABE,3 deadly both ways; redraw
  $AAC1,3 a beep
  $AAC4,13 a new count of turns, 0 to 15
  $AAD1,8 always the other axis
  $AAD9,13 by the random number, flip its way along the axis or not
  $AAE6,8 flip bit 1: the other way
  $AAEE,15 two to five units, the way bit 1 says
  $AAFD,15 along U
  $AB0C,8 the other half of the random choice
  $AB14,11 along V

@ $AB1F label=FACE_BY_STEP_UNUSED
c $AB1F Unused: face by the signs of the steps
D $AB1F Nothing calls or jumps here (searched), and the build's sessions never ran it; stage 1 took it for data. It is code, and ends where #R$AB61 begins: it sets bit 1 of the graphic and the mirror flag, the two bits a clockwork mouse (#R$AAA1) faces by, from the signs of the steps in U (+9) and V (+A). The signs agree with the mice's way of facing, but the axis does not: as written it faces along V when the step in U is the larger, and along U otherwise -- across the larger step rather than along it -- so it was either for sprites that face another way or left unfinished.

@ $AB61 label=SCENE_TOOL
c $AB61 A tool in the re-programming (graphics 81 to 83)
D $AB61 Reached through #R$A7EA: the scene after a lost game (#R$B761), with the robot (graphics 88 to 91) on its stand in the middle, sparks over its head (#R$ABF5), and three tools round it -- a glove at the right (81), a hammer above (82) and a hook at the left (83). Once the sparks have stopped (SCENE_STATE not zero) the tools take turns: when none is swinging, each on its turn has a chance of one in four to start, with a thud. A swing is six steps towards the robot -- eight pixels across for the glove and the hook, four down for the hammer -- a crash, and six steps back. Fifteen swings end the scene and go back to the menu (#R$A647); so does any of the keys 1 to 0.
D $AB61 +11: bit 0 swinging, bit 7 on the way back. +F the steps left. +10 the colour, which every turn paints the cells it covers (COLOUR_SCENE_OBJECT, in #R$ABF5).
  $AB61,7 the sparks still flashing: only colour its cells
  $AB68,8 keys 1 to 0: back to the menu
  $AB70,6 swinging
  $AB76,4 another is swinging
  $AB7A,8 one turn in four
  $AB82,5 a thud
  $AB87,10 swing: this one, one at a time, six steps
  $AB91,7 the hammer (even) swings down; the glove and hook across
  $AB98,20 eight pixels towards the middle of the screen, or back
  $ABAC,5 steps left
  $ABB1,16 six more, the other way
  $ABC1,5 at the robot: a crash
  $ABC6,6 back where it started: the swing is over
  $ABCC,8 count it: fifteen swings
  $ABD4,3 and back to the menu
  $ABD7,3 redraw
  $ABDA,3 colour its cells
  $ABDD,24 the hammer: four pixels towards the middle, or back

@ $ABF5 label=SCENE_SPARKS
@ $AC21 label=COLOUR_SCENE_OBJECT
c $ABF5 The sparks over the robot (graphic 80)
D $ABF5 Reached through #R$A7EA: the first part of the re-programming (#R$AB61). Every eighth turn the sparks change colour, bright yellow or black by bit 3 of the turn counter, with a beep; after sixteen changes they go (graphic 1: rubbed out and emptied) and set SCENE_STATE to 1, which lets the tools swing.
D $ABF5 COLOUR_SCENE_OBJECT is the update routine of the scene's pieces that do not move (graphics 85, 88 to 91: the can of oil, the robot's stand, its legs and top) and the last step of the others'. The scene's screen is bright red on black (#R$B761), the colour of its frame, and each piece has its own colour: this paints the attribute cells a piece's picture covers (its width and height as last drawn, at its pixel place) with its colour at +10, bottom row first -- except any cell already bright green ($44), the hammer's colour, so the hammer stays green where it is over the robot. Nothing puts those cells back, so the robot's head is left green after the hammer's blows (seen in the simulator). It does nothing for a piece not drawn yet.
  $ABF5,8 not an eighth turn: only colour
  $ABFD,9 bright yellow, or black
  $AC06,3 a beep
  $AC09,10 sixteen changes
  $AC13,8 the tools may start; the sparks go
  $AC1B,6 colour its cells; redraw
  $AC21,7 not drawn yet
  $AC28,12 the cells across: its width, one more if it starts inside a cell
  $AC34,23 the rows of cells from its bottom to its top
  $AC4B,10 the bottom-left cell's attribute; the colour
  $AC55,3 a row
  $AC58,9 each cell but a bright green one
  $AC61,10 up a row, for each row

@ $AC6B label=SUMMARISE_CHAMBERS
c $AC6B Count the chambers and the cryonauts for the summary
D $AC6B Called by #R$B761 at the end of a game, after the valves in the room have been written back to their places (#R$AF05). Walks the room directory (#R$6469). A room is a chamber if the first object groups after its backgrounds are the frozen crew, object templates 21 and 22 (graphic 74) -- exactly the 24 rooms with a socket. A chamber with a seated valve lying in it (graphics 100-103, looked for in the places, #R$76E3) counts in SUMMARY_ACTIVE; any other in SUMMARY_IDLE, and its crew -- a group's count, for each group of templates 21 and 22 in a row -- in SUMMARY_LOST. All three are BCD. The game's summary calls them the activated and unactivated cryogenic chambers and the cryonauts lost: with none activated, 24 and 132 (measured: the summary screen in the simulator, and the room data counted the same way).
D $AC6B A record is read as the builder reads it: the byte count at +1 bounds the walk, the backgrounds end with $FF, and a group is a header and a position for each copy.
  $AC6B,8 the three counts to zero
  $AC73,3 the first room
  $AC76,3 C = the room, B = the count of its bytes
  $AC79,7 look for the $FF after the backgrounds; the count running out first means no objects
  $AC80,7 the next room, until the end of the directory at #R$73C8
  $AC8A,1 the bytes left after the $FF
  $AC8B,11 the first group crew (template 21 or 22)?
  $AC96,6 no: skip the rest of the record
  $AC9C,4 a chamber: look for a place in this room
  $ACA0,6 in this room?
  $ACA6,28 nine bytes on, to the end of the places at #R$7827
  $ACC2,9 a seated valve? If not, look on
  $ACCB,11 activated: count it, and on to the next room
  $ACD6,17 not activated: add the group's crew to those lost
  $ACE7,10 past the group: its header and a position a copy
  $ACF1,7 the record's bytes used up
  $ACF8,11 another group of crew: count it too
  $AD03,4 skip the rest of the record
  $AD07,12 count the chamber not activated

@ $AD13 label=CEILING_DROP
c $AD13 A thing that drops from the ceiling (graphic 73)
D $AD13 Reached through #R$A7EA. Knight Lore's spiked ball: deadly both ways, it hangs until a turn when the random number is under 16 (one in sixteen), no other is falling (DROPPING), and the drop latch (DROP_LATCH) is clear -- which in an even-numbered room it is not until something has been picked up. Then it falls, with a sound pitched by its height, lands with a thud (#R$AD54), and lets the next one go.
D $AD13 Bit 2 of +D: falling. Once on the floor it can be let go again, but it has nowhere to fall and makes no second thud. Rooms $0C, $1C, $58 and $84 have them (object template 20).
  $AD13,3 deadly both ways
  $AD16,3 draw 12 left and 8 down
  $AD19,5 latched: nothing drops
  $AD1E,6 falling
  $AD24,6 another is falling
  $AD2A,6 one turn in sixteen
  $AD30,7 let go
  $AD37,3 fall
  $AD3A,3 a thud if it has just landed
  $AD3D,6 landed
  $AD43,3 a sound pitched by its height
  $AD46,3 redraw
  $AD49,9 landed: another may fall

@ $AD54 label=THUD_ON_LANDING
c $AD54 A thud, once, when it lands
D $AD54 Used by #R$AD13. +F remembers whether it was standing last time; the crash sound (#R$B676) plays when it changes to standing.
  $AD54,7 not standing on anything
  $AD5B,10 standing now and not before: the sound

@ $AD66 label=RUN_CLOCK
c $AD66 Count down the light years, and show them
D $AD66 Once a turn from the main loop (#R$A6C0). CLOCK is four digits, a byte each, the highest first; each byte is the digit in bits 4-7 and, in bits 0-2, how far it still has to roll. A digit that changes is drawn rows out of line: the eight rows from its count down its character, so that it shows mostly the next digit up with a count of 7 and rolls down into place as the count runs out, like a mechanical counter's wheel (#R$ADB0). Every turn the rolling digits roll one row (#R$ADE5); when the last has finished, a light year is taken off (#R$ADC9) and the digits it changes start rolling. So a light year takes seven turns.
D $AD66 The four digits are printed into the buffer at the right of the panel, the last one inverted, and copied to the screen; when all four bytes are zero the game is over (#R$B761).
D $AD66 The font's character after 9 (code $3A, 11th of #R$6308) is a second nought, so a 9 that follows a 0 rolls in from a nought.
  $AD66,3 a light year off, if the last digit has rolled into place
  $AD69,3 roll the rolling digits a row
  $AD6C,16 the four digits, at the right of the panel, with the font's digits as characters 0 to 9
  $AD7C,7 each digit, rolled
  $AD83,14 invert the last digit
  $AD91,17 copy the four digits' 32 by 8 pixels to the screen
  $ADA2,10 all four bytes
  $ADAC,3 zero: the game is over

@ $ADB0 label=PRINT_ROLLING_DIGIT
c $ADB0 Print a digit rolled
D $ADB0 Used by #R$AD66. Prints the eight bytes from the digit's character plus its count, so a digit with count c shows its own last 8-c rows at the top and the next character's first c rows below them. The printer's #R$BBEB does the printing, entered part way, from the base in FONT_BASE.
R $ADB0 A the digit (bits 4-7) and its count (bits 0-3)
R $ADB0 HL where in the buffer
R $ADB0 O:HL the next place along
  $ADB0,3 as #R$BBEB keeps them
  $ADB3,14 the digit's character, eight bytes a character
  $ADC1,5 plus the count: rolled that many rows
  $ADC6,3 print it

@ $ADC9 label=CLOCK_BORROW
c $ADC9 Take a light year off
D $ADC9 Used by #R$AD66, but only when the last digit has finished rolling (its count is 0). Takes one off the last digit, borrowing from the digits above it as a 0 becomes a 9; each digit that changes is given a count of 7, to roll into place.
  $ADC9,9 the last digit still rolling: nothing
  $ADD2,12 not 0: one less, and roll
  $ADDE,6 0: 9, rolling, and borrow from the next digit up

@ $ADE5 label=ROLL_CLOCK
c $ADE5 Roll the clock's digits a row
D $ADE5 Used by #R$AD66. From the last digit up, takes one off each count until it meets a digit that is not rolling: the digits changed by one borrow always roll together.
  $ADE5,14 the last digit first

@ $ADF3 label=SET_WIPE_AND_DRAW_IY
c $ADF3 Mark the object at IY to be wiped and redrawn
D $ADF3 #R$BFAB for the record at IY rather than IX. Used by #R$BD6B. Knight Lore's routine of the same name.
R $ADF3 IY the record
  $ADF3,11 IX = IY, and mark it
  $ADFE,5 IX and IY back

@ $AE03 label=FIND_GRAPHIC_HERE
c $AE03 Find the room's first object with a graphic in a range
D $AE03 Looks through the room's 52 records, #R$5B88's records 4 to 55, for a graphic from L to L+H-1. Used by #R$AF79 to find the room's socket.
R $AE03 L the first graphic
R $AE03 H how many
R $AE03 O:IY the record found
R $AE03 O:F carry set if one was found
  $AE03,9 records 4 to 55
  $AE0C,6 graphic - L < H: found
  $AE12,5 the next; none found, no carry

@ $AE17 label=WANTED_VALVE
c $AE17 The picture of the valve a socket wants (graphics 104 to 107)
D $AE17 Reached through #R$A7EA. A chamber's socket (#R$AE68) is built with a record after it for its sparkle (#R$AE33), which from time to time becomes, for two turns, a picture of the valve the socket takes (graphics 104-107 share the valves' sprites, 96-99), hovering 13 above the socket. Whenever anything lies in the room from the places -- a valve, even a seated one, or an extra life -- it goes, rubbed out and emptied, so a chamber once activated has none.
D $AE17 +10 counts the two turns; then it is the sparkle again (graphic 4 more).
  $AE17,3 draw 12 left and 5 down
  $AE1A,6 anything from the places in the room: go
  $AE20,8 13 above the socket, the record before
  $AE28,4 two turns
  $AE2C,7 then the sparkle, redrawn

@ $AE33 label=SOCKET_SPARKLE
c $AE33 A socket's sparkle (graphics 108 to 111)
D $AE33 Reached through #R$A7EA. The sparkle over a chamber's socket, built with it (object templates 24 to 27, flags $12: out of the collision tests). It hovers 13 above the socket and steps through four frames (graphics 108-111 share the sprites of the sparkle a thing dies in), and when the frame comes round to the socket's kind it shows the valve wanted (#R$AE17) for two turns: about two turns in six. Like the picture, it goes when anything lies in the room from the places.
  $AE33,3 draw 12 left and 5 down
  $AE36,6 anything from the places in the room: go
  $AE3C,8 13 above the socket, the record before
  $AE44,6 the next frame
  $AE4A,8 the socket's kind?
  $AE52,8 yes: the valve wanted, for two turns
  $AE5A,3 redraw

@ $AE5D label=SEATED_VALVE
c $AE5D A valve seated in its socket (graphics 100 to 103)
D $AE5D Reached through #R$A7EA. What a valve becomes when it activates its chamber (#R$AF79): it stays where it is, never falling, and cannot be picked up (#R$BD6B takes only graphics 96-99). The summary after a game counts a chamber activated by finding one of these in its room (#R$AC6B).
  $AE5D,3 draw 12 left and 5 down
  $AE60,8 no step in U or V

@ $AE68 label=SOCKET
c $AE68 A chamber's socket (graphics 112 to 115)
D $AE68 Reached through #R$A7EA. The socket a valve of its kind (its graphic less 16, 96-99) is put on to activate the chamber; the valve does the work (#R$AF79). This only brings the sparkle back: when nothing lies in the room from the places and the record after the socket is empty -- as when the sparkle went because a valve lay here, and the valve has been picked up -- it puts the sparkle there again (graphic 108 plus the socket's kind).
D $AE68 The record keeps the sparkle's old position, which is what makes it appear in the right place: the projection it then asks for (#R$AE8A) is of the record at IY, which here is whatever an earlier routine left there -- the legs' record, in the simulator -- rather than the new sparkle's. The build's sessions never ran this; a scene staged in room $0C, with a valve in the room and then taken away, did (measured): the sparkle came back over the socket.
  $AE68,3 draw 16 left and 7 down
  $AE6B,4 anything from the places in the room: nothing to do
  $AE6F,5 the sparkle is there
  $AE74,10 put it back, of the socket's kind
  $AE7E,3 project the record at IY

@ $AE81 label=ANY_SPECIAL_HERE
c $AE81 Is anything lying in the room from the places?
D $AE81 The graphics of the two records the places fill (#R$5B88's records 2 and 3) ORed: zero when both are empty. Used by the socket and its sparkle (#R$AE17, #R$AE33, #R$AE68).
R $AE81 O:F zero flag set if nothing is there
  $AE81,9 VALVES or VALVE_SECOND

@ $AE8A label=CALC_PIXEL_XY_IY
c $AE8A Project the object at IY onto the screen
D $AE8A #R$CFD2 for the record at IY rather than IX. Used by #R$BD6B for a thing put down, and by #R$AE68.
R $AE8A IY the record
  $AE8A,12 IX = IY for the projection

@ $AE96 label=CRYONAUT
c $AE96 A frozen cryonaut (graphic 74)
D $AE96 Reached through #R$A7EA. The frozen crew in the cryogenic chambers only stand: this sets the drawing nudge and nothing more. They are what the summary after a game counts (#R$AC6B).
  $AE96,3 draw 12 left and 4 down

@ $AE99 label=FIND_SPECIAL_OBJS_HERE
c $AE99 Bring in what lies in the room from the places
D $AE99 Called while a room is built (#R$CAA2), after the builder. Looks through the 36 places at #R$76E3 for any in use (a graphic) whose current room (+8) is the one he is in, and builds an object record for each in records 2 and 3 (VALVES and VALVE_SECOND) -- the two kept for them: the graphic; U, V and Z from where it is now; the half-sizes 5 by 5 and the height 12; flags $14 (drawn, can be pushed); the room; nothing moving; and at +10 the address of the place, so that the record can be written back (#R$AF05). Whatever is left of the two records is cleared.
D $AE99 Knight Lore's find_special_objs_here, instruction for instruction; only the addresses differ. As there, nothing here stops at two: a third place in one room would be built over record 4, the room's first, and the clearing after the loop would then never meet record 4 again and would run on through memory. The 36 places start in 36 different rooms, and a thing is put down only into an empty one of the two records (#R$BD6B), so it does not happen (read; inferred for every way a valve can travel).
R $AE99 IX the legs' record, whose +8 is the room being entered
  $AE99,4 DE', the record being built, in the alternate set
  $AE9D,7 the first place; the room
  $AEA4,6 not in use: skip
  $AEAA,6 in another room: skip
  $AEB0,5 HL = the place; its address is kept on the stack
  $AEB5,4 the graphic
  $AEB9,9 U, V and Z from +5 to +7, where it is now
  $AEC2,14 5 by 5 by 12, flags $14
  $AED0,4 the room
  $AED4,5 +9 to +F: no step, nothing met
  $AED9,7 +10 and +11: the place
  $AEE0,5 +12 to +1F cleared
  $AEE5,1 back to the scan's registers
  $AEE6,16 nine bytes on, until the graphic table at #R$7827 that follows the last place
  $AEF6,1 DE = the next record to build
  $AEF7,7 up to record 4, ROOM_OBJECTS
  $AEFE,7 clear the rest of the two

@ $AF05 label=UPDATE_SPECIAL_OBJS
c $AF05 Write the valves in the room back to their places
D $AF05 Called before a new room is built, once a turn has been played (PLAYED: #R$CAA2), and at the end of a game (#R$B761), so that the summary sees where the valves are. For each of records 2 and 3 holding a valve, loose or seated (graphics 96 to 103), writes its graphic, its U, V and Z and its room back to its place through the address at +10: that is how a valve moved, carried in or seated stays where it was left.
D $AF05 Knight Lore's update_special_objs writes back whatever the records hold; this writes back only the valves. An extra life (graphic 12) never moves, and taking one empties its place (#R$BEE0).
  $AF05,4 record 2
  $AF09,9 not a valve: skip
  $AF12,6 the place
  $AF18,4 the graphic
  $AF1C,5 on to +5
  $AF21,9 U, V and Z
  $AF2A,4 the room
  $AF2E,16 record 3, then stop at record 4, ROOM_OBJECTS

@ $AF3F label=INIT_SPECIAL_OBJECTS
c $AF3F Deal the valves and the extra lives to their places
D $AF3F At every new game (#R$A647). Gives each of the 36 places at #R$76E3 a graphic and puts it where it starts, copying +1 to +4 (U, V, Z, room) to +5 to +8. The kinds of valve go round in order, 96, 97, 98, 99 and again, from a random starting kind -- the seed plus the refresh register -- so there are nine of each or near it -- but see the extra lives below: they fall 16 places apart and the kinds repeat every 4, so every extra life replaces a valve of the same kind, and a deal gives 9, 9, 9 and 7 of the four kinds, or 9, 9, 9 and 6 in a game with three extra lives (one in four). Then one kind has exactly the six its sockets need, and losing one valve (#R$C8AB) leaves the game unwinnable (the counts measured; the consequence inferred). Every sixteenth place by a second count, started from the random number, gets an extra life (graphic 12) instead, and the kind that would have gone there is skipped: two or three extra lives a game.
D $AF3F Knight Lore's init_special_objects, which deals eight kinds in turn, the eighth its extra life; here four kinds, and the extra lives by a count of their own. The chambers want six valves of each kind (#R$AE68: six sockets of each).
  $AF3F,3 the first place
  $AF42,8 E: the kind to deal next, from the seed and R
  $AF4A,4 D: the count for the extra lives, from the random number
  $AF4E,6 every sixteenth: an extra life
  $AF54,5 a valve of the next kind, 96-99
  $AF59,3 its graphic; the next kind
  $AF5C,12 +1 to +4, where it starts, to +5 to +8, where it is
  $AF68,12 until the graphic table at #R$7827, after the last place
  $AF75,4 an extra life

@ $AF79 label=LOOSE_VALVE
c $AF79 A valve (graphics 96 to 99), and activating a chamber
D $AF79 Reached through #R$A7EA. A valve falls under gravity, can be pushed, and is the one thing that can be picked up and carried (#R$BD6B), and makes a sound pitched by its position each turn it moves. In a chamber whose socket is of its kind (the socket's graphic less 16) it also steers itself, a unit a turn in U and V, towards the socket; when it sits exactly on it -- the same U and V, and 12 above the socket's base -- it activates the chamber.
D $AF79 Activating: the valve becomes a seated one (graphic 4 more, #R$AE5D); the screen's inks run through all eight colours twice, with a sparkle's sound; the room's ink becomes white for the rest of the game (through ROOM_COLOUR_AT) and the screen and panel are recoloured (#R$A749); CHAMBERS goes up by one, and the twenty-fourth sets WON and ends the game (#R$B761). Otherwise the new count is printed and copied to the screen.
D $AF79 The second test of the kinds, after the valve is found sitting on the socket, can never fail: the valve would have steered only to a socket of its kind. Had it failed, the valve would have become graphic 64, the dying sparkle, and been lost (#R$B3A4). Nothing reaches it (read; never run).
  $AF79,3 draw 12 left and 5 down
  $AF7C,8 find the room's socket, graphics 112 to 115
  $AF84,14 not of this valve's kind: only a valve
  $AF92,18 a step of one in U towards the socket
  $AFA4,18 and in V
  $AFB6,16 not over it yet
  $AFC6,10 sitting on it: activate
  $AFD0,3 fall, and move
  $AFD3,6 just put down: its sound
  $AFD9,4 not moving: done
  $AFDD,10 no step left in U or V; a sound pitched by where it is; redraw
  $AFE7,10 the kinds again
  $AFF1,7 never: the sparkle, and the valve lost
  $AFF8,8 seated: graphic 100-103
  $B000,3 a sound; redraw
  $B003,2 sixteen times
  $B005,22 every attribute's ink one on
  $B01B,3 a sparkle's sound
  $B01E,8 and a pause
  $B026,3 sixteen times: the inks back where they were
  $B029,12 the room's ink white, in its record and for now
  $B035,3 recolour the screen and the panel
  $B038,8 one more chamber
  $B040,4 not the twenty-fourth
  $B044,8 won: the end
  $B04C,3 print the count
  $B04F,6 and copy its 16 by 8 pixels to the screen

@ $62FD label=BLOCK_START
u $62FD The block's first three bytes
D $62FD The block loads from one past the loader's CLEAR, but the loader enters it three bytes in, at #R$6300. Nothing refers to these bytes.

@ $6300 label=ENTRY
@ $6301 nowarn
c $6300 Where the BASIC loader enters the game
D $6300 The loader's last line is a RANDOMIZE USR to this address. The stack goes to #R$F100, the top of the space above the screen buffer, and the game starts at #R$A631.

D $6308 43 characters of 8 bytes, the codes $30 to $5A. The printer adds eight times a code to #R$5B27: for text, 384 bytes below this one, so that code $30 lands here; for the light years (#R$AD66), this address itself, so that the digits are codes 0-9.

D $6460 Three entries: the half-size in U, the half-size in V (about the room's centre at 128), and the floor's height. Bits 6-7 of a room record's third byte pick one, and the builder (#R$CCA7) copies it to #R$5B0B.

D $6469 The room directory: 128 records, one per room, end to end up to #R$73C8. #R$CCA7 finds a room by stepping from one record to the next until the number matches; the rooms are numbered on a 16 by 16 grid, as in Knight Lore.
D $6469 A record is +0 the room number, +1 the count of bytes from +1 to the end of the record, +2 the room's size (bits 6-7, an index into #R$6460) and its colour: bits 3-5 on the tape, copied into bits 0-2 at the start of every game (#R$CAD2) because bits 0-2 are the ink in use, which an activated chamber turns white (#R$AF79). Then the backgrounds, a byte each (an index into #R$7519), up to an $FF; then the objects in groups, a header byte (bits 0-2: how many, less one; bits 3-7: the object template, #R$73C8) and a position byte for each: U in bits 0-2, V in bits 3-5, the level in bits 6-7. A header with template 0 sets the placement nudge (#R$5B19) from the byte after it, and one with template 31 moves on to the second page of templates. Nothing ends a record but the count at +1 running out, and a group can be cut short by it.
D $6469 Each room is an entry of its own, laid out from the game's data when the disassembly is built.

D $73C8 A word per object template, the group header's bits 3-7 doubled as the index (#R$CCA7), in two pages: the builder keeps the page it is reading in #R$5B20, and template 31 moves it on by 64 bytes, to the second, which has seven. Templates 0 and 31 of each page are not templates, so their words are zero.
D $73C8 A template is a list of five-byte pieces -- graphic, the half-sizes in U and V, the height, flags -- each copied to +0 and +4 to +7 of an object record at the group's position, for as long as the byte after a piece is not zero.

D $7519 A word per background, a room's background byte doubled as the index (#R$CCA7). A background is a list of eight-byte pieces -- graphic, U, V, Z, the half-sizes, the height, flags -- each copied to +0 to +7 of an object record, ended by a zero.

D $76E3 Thirty-six records of nine bytes: the places a valve can lie. At a new game #R$AF3F gives each a graphic -- a valve of one of the four kinds (96-99, chosen from the random number), or, now and then, an extra life (graphic 12) -- and copies the place in +1 to +4 (U, V, Z and room, from the tape) to +5 to +8, where it is kept from then on: #R$AE99 puts what lies in a room into the two records at #R$5BC8 as the room is built, and #R$AF05 writes them back when it is left. On the tape the graphics and the second halves are zero.

D $7827 A word per graphic number, the address of its sprite. Numbers 0 and 1 share a sprite whose width and height are both zero, which draws nothing.

D $792F The sprites, end to end from here to the code at #R$A631. Each is a width byte (bits 0-3 the width in bytes; bits 6 and 7 the mirrored and upside-down flags, toggled in place as objects face about), a height byte, then a mask byte and an image byte for each cell, the bottom row first. On the tape every sprite is the right way round.

# --------------------------------------------------------------------------
# The code: entry points
# --------------------------------------------------------------------------

# --------------------------------------------------------------------------
# Range 2
# --------------------------------------------------------------------------

# Range 2: $B055-$B94E. Stage 2 description, agent 2.

# --------------------------------------------------------------------------
# The two-part creatures: an upper half on a lower half (graphic 11)
# --------------------------------------------------------------------------

@ $B055 label=LOWER_HALF
c $B055 The update routine for the lower half of a two-part creature (graphic 11)
D $B055 Object templates 17, 18 and 19 are two pieces at one place: a creature (graphic 94, 86 or 87) and under it graphic 11, its lower half, in the next record. The lower half does nothing of its own: it is put straight under the record before it -- the same U and V, 12 lower -- after that record's update has moved it, and is redrawn whenever the upper half has any step.
D $B055 The footstep it asks for never sounds: #R$B6C0 plays only on an even graphic, and 11 is odd. The simulator sessions never ran that part of #R$B6C0 (see the coverage report).
R $B055 IX the lower half's record; the upper half's is 32 bytes below it
  $B055,3 the drawing nudge
  $B058,3 under the upper half
  $B05B,10 the upper half has no step in U, V or Z this turn: nothing to draw
  $B065,6 a footstep (never, see above), and redraw it

@ $B06B label=WANDERER
c $B06B The update routine for a creature that wanders at random (graphics 94 and 95)
D $B06B The upper half of object template 17 (the lower half is #R$B055's). It walks two units a turn in one of four directions, and when it is stopped, or has no step yet, it turns a quarter to the left or to the right, chosen by bit 0 of the random number, and sets off the new way on the next turn. It is deadly both ways (#R$B2A4).
D $B06B The direction is kept in bit 0 of the graphic and bit 6 of the flags, the mirror bit (#R$B0E7 has the four combinations), so turning also turns the picture. For the move the two halves are made one box (#R$B1FA); afterwards they are parted again (#R$B20B).
D $B06B Measured in the simulator in room $2F: two units a turn in V, then, stopped, a quarter turn and two units a turn in U, the lower half following it each turn.
R $B06B IX the upper half's record
  $B06B,3 the drawing nudge
  $B06E,3 the two halves as one box
  $B071,8 no step yet: choose a direction
  $B079,3 move
  $B07C,7 a thud whenever it has a step in Z (falling, or just landed)
  $B083,7 not stopped in U or V: done
  $B08A,3 a thud as it turns
  $B08D,7 bit 0 of the random number: which way to turn
  $B094,3 1: a quarter turn the other way (#R$B0DD)
  $B097,11 set off in the direction it now faces, two units a turn
  $B0A2,6 part the halves; deadly both ways, and redraw it
  $B0A8,5 0: a quarter turn one way (#R$B0AD)

@ $B0AD label=TURN_QUARTER
c $B0AD Turn a creature a quarter
D $B0AD The four directions are the four combinations of bit 0 of the graphic and bit 6 of the flags (the mirror bit): taking them as a pair, this steps (0,0) to (1,1) to (1,0) to (0,1) and back to (0,0), which by #R$B0E7's table is minus U, minus V, plus U, plus V -- always the same way round. #R$B0DD toggles bit 0 first, which makes the same step the other way round.
R $B0AD IX the creature
  $B0AD,12 which of the four is it?
  $B0B9,9 (0,0): to (1,1)
  $B0C2,12 (1,0): to (0,1)
  $B0CE,9 (0,1): to (0,0)
  $B0D7,6 (1,1): to (1,0)

@ $B0DD label=TURN_QUARTER_BACK
c $B0DD Turn a creature a quarter the other way
D $B0DD Toggling bit 0 of the graphic before #R$B0AD's step makes the step go the other way round: (0,0) to (0,1), (0,1) to (1,0), (1,0) to (1,1), (1,1) to (0,0).
R $B0DD IX the creature
  $B0DD,10 graphic XOR 1, then on into the quarter turn

@ $B0E7 label=STEP_FROM_FACING
c $B0E7 Set a creature's step from the way it faces
D $B0E7 Makes an index of bit 6 of the flags (the mirror bit) and bit 0 of the graphic, and copies the step in U and V from #R$B108: one unit in the direction it faces. The callers double it.
R $B0E7 IX the creature
  $B0E7,9 bit 6 of the flags, turned into bit 1
  $B0F0,8 with bit 0 of the graphic: 0 to 3, doubled
  $B0F8,6 its pair in the table
  $B0FE,10 its steps in U and V

@ $B108 label=FACING_STEPS
b $B108 The step in U and V for each way a creature can face
D $B108 Four pairs of a step in U and a step in V, indexed by bit 6 of the flags (the mirror bit) times two plus bit 0 of the graphic (#R$B0E7).
B $B108,8,2 Unmirrored, graphic even: minus U; odd: plus U. Mirrored, even: plus V; odd: minus V

@ $B110 label=PACER
c $B110 The update routine for a creature that paces to and fro (graphics 86 and 87)
D $B110 The upper half of object templates 18 and 19 (the lower half is #R$B055's). It walks two units a turn along one axis, and when it is stopped it turns round, with a thud, and walks back the other way. It keeps its step in U or V in +10 while it moves, since a blocked move leaves the step zero. With no step at all, as when the room has just been built, it takes the way it faces (#R$B0E7). It is deadly both ways.
D $B110 Measured in the simulator in room $A6: from U 180 down two units a turn to 168, then back up to 184 and down again, the picture turning with it, and the lower half following.
R $B110 IX the upper half's record
  $B110,3 the drawing nudge
  $B113,3 the two halves as one box
  $B116,6 a step in U?
  $B11C,6 yes: keep it, and move
  $B122,6 not stopped in U: done
  $B128,8 stopped: walk back the other way
  $B130,6 a thud, and face the new way
  $B136,6 part the halves; deadly both ways, and redraw it
  $B13C,6 a step in V?
  $B142,6 yes: keep it, and move
  $B148,6 not stopped in V: done
  $B14E,10 stopped: walk back the other way
  $B158,13 no step: take the way it faces, two units a turn, and go again

@ $B165 label=MOVE_TOWARDS_PLAYER
c $B165 Point an object at the player
D $B165 Sets the step in U and V to plus or minus the given speeds, each pointing from the object towards the robot's legs (PLAYER_U and the V after it) along its axis. The sign comes from the difference, so it is right while the two are less than 128 apart; level with him, the object steps the negative way. Knight Lore's move_towards_plyr, byte for byte in its logic.
R $B165 IX the object
R $B165 C the speed in U
R $B165 B the speed in V
  $B165,7 own U less his U
  $B16D,9 +C if he is further along U, else -C
  $B176,5 own V less his V
  $B17B,9 +B if he is further along V, else -B

@ $B185 label=TOGGLE_FRAME
c $B185 Flip between an object's two frames
D $B185 Toggles bit 0 of the graphic, for things whose two frames are a pair of graphics differing only in bit 0. Knight Lore's toggle_next_prev_sprite.
R $B185 IX the object
  $B185,7 graphic XOR 1, stored by #R$B18C's last instruction

@ $B18C label=NEXT_FRAME_MOD4
c $B18C Step an object through four frames
D $B18C Adds one to the low two bits of the graphic and leaves the rest alone, so 76 goes to 77, 78, 79 and back to 76. Knight Lore's next_graphic_no_mod_4.
R $B18C IX the object
  $B18C,12 the graphic with its low two bits plus 1, modulo 4
  $B198,3 store it (#R$B185 comes here too)

@ $B19C label=SPARK_CHASER
c $B19C The update routine for the thing that chases the player (graphics 76 to 79)
D $B19C Object template 16: a crackle of sparks that heads for the robot at four units a turn in U and in V, falls, and runs through its four frames every turn, with a note pitched by its position. Nothing here makes it deadly; it pushes what it runs into like anything else that moves.
D $B19C Measured in the simulator in room $9C: it came at him four units a turn along U, pushed him before it until both were stopped, and went on cycling its frames there.
R $B19C IX the object
  $B19C,3 the drawing nudge
  $B19F,6 four units a turn at the player, in U and in V
  $B1A5,3 fall, and move
  $B1A8,3 the next of its four frames
  $B1AB,3 a note pitched by U, V and Z, and redraw it

@ $B1AE label=FACE_ALONG_STEP
c $B1AE Turn a creature to face the way it is stepping
D $B1AE Sets bit 0 of the graphic and bit 6 of the flags (the mirror bit) to the pair #R$B0E7 would turn back into this step. The comparison of the two steps is unsigned, which works because one of them is always zero. With no step it leaves them alone. Knight Lore's set_guard_wizard_sprite does the same for its guards.
R $B1AE IX the creature
  $B1AE,7 not stepping: leave it
  $B1B5,8 stepping in V (the U step is the smaller)?
  $B1BD,13 in U, and plus: (1,0)
  $B1CA,6 minus: (0,0)
  $B1D0,15 in V, and minus: (1,1)
  $B1DF,6 plus: (0,1)

@ $B1E5 label=PUT_UNDER_UPPER
c $B1E5 Put a lower half under its upper half
D $B1E5 Copies U and V from the record before, and puts Z 12 below it: the height of one piece.
R $B1E5 IX the lower half; the upper half's record is 32 bytes below it
  $B1E5,12 U and V as the upper half's
  $B1F1,9 Z 12 lower

@ $B1FA label=JOIN_HALVES
c $B1FA Make a two-part creature one box for its move
D $B1FA Lowers the upper half's Z by 12 to where its lower half stands and doubles its height, so that the move and the collision code treat the two as one object; the lower half, in the next record, is taken out of the collision tests (bit 1 of its flags) meanwhile. #R$B20B undoes it.
R $B1FA IX the upper half
  $B1FA,8 down to the lower half's Z
  $B202,4 twice the height
  $B206,4 the lower half out of collisions

@ $B20B label=PART_HALVES
c $B20B Part a two-part creature again after its move
D $B20B Undoes #R$B1FA: the upper half back up 12 at its own height, and the lower half back in the collision tests.
R $B20B IX the upper half
  $B20B,8 up 12
  $B213,4 its own height
  $B217,4 the lower half back in collisions

# --------------------------------------------------------------------------
# Blocks that move by themselves, carry, sink, collapse, kill or are pushed
# --------------------------------------------------------------------------

@ $B21C label=SHUTTLE_V
c $B21C The update routine for a block that shuttles to and fro in V (graphic 67)
D $B21C Object template 14. A note pitched by V every turn, then #R$B224's common part, set up for V: it reads +2 and sets +A. Knight Lore's upd_55.
R $B21C IX the block
  $B21C,3 a note pitched by V
  $B21F,5 H = 2 (V), L = 10 (its step)

@ $B224 label=SHUTTLE_U
@ $B22A label=SHUTTLE_BLOCK
c $B224 The update routine for a block that shuttles to and fro in U (graphic 66)
D $B224 Object template 13. The block follows the turn counter: folding its low five bits at bit 4 gives a triangle wave, 0 up to 15 and back over 32 turns, and the block steps one unit a turn towards that place in a span of 16. The blocks in odd-numbered records add 16 first, so they run half a cycle out of step with those in even-numbered ones. Knight Lore's shuttle_block, with the same trick of one routine for both axes: the two IX displacements of the read of the position and the write of the step are patched before they run.
D $B224 The position used is 8 more than the block's own, because a block stands on the centre line of a cell, 8 past a multiple of 16. Its Z step is set to 1 so that the move's fall (#R$BFB6) leaves it at 0: a shuttling block never falls.
R $B224 IX the block
  $B224,3 a note pitched by U
  $B227,3 H = 1 (U), L = 9 (its step)
  $B22A,8 patch the displacements of the read below and of the write of the step
  $B232,3 the drawing nudge
  $B235,8 C = 16 in an odd-numbered record, 0 in an even one (bit 5 of the record's address)
  $B23D,12 the turn counter plus C, folded at bit 4: the place to be, 0 to 15
  $B249,7 where it is now in its span: U or V (the displacement patched) plus 8, modulo 16
  $B250,4 there: stand still, but redraw it
  $B254,9 one unit towards it: plus if short of it, minus if past it, as its U or V step (patched)
  $B25D,4 a Z step of 1, which the fall makes 0
  $B261,6 move, and redraw it

@ $B267 label=CONVEYOR_PLUS_V
@ $B26B label=CONVEYOR
c $B267 The update routine for a conveyor that carries things forwards in V (graphic 68)
D $B267 Object template 8, and #R$B27A, #R$B280 and #R$B286 for the other three directions (graphics 69, 70 and 71, templates 9 to 11). A conveyor never moves itself: it only sets its own step, two units a turn, every turn (the room builder copies no steps from the templates). What stands on it is carried by the collision code: when something lands on anything, and has no step of its own in U or V, it takes the step of the thing it has landed on (#R$C535).
D $B267 The same code copies the lander's Z step into the conveyor's, which is how a conveyor knows something has landed on it: this routine then beeps (#R$B6BB) and clears it.
D $B267 Measured in the simulator in room $0D, a ring of the four: standing on graphic 68, he went up two units in V every turn.
R $B267 IX the conveyor
  $B267,4 its step: two units in V
  $B26B,3 the drawing nudge
  $B26E,7 something has landed on it: a beep
  $B275,5 and its Z step cleared; no redraw, as nothing about it changes

@ $B27A label=CONVEYOR_PLUS_U
c $B27A The update routine for a conveyor that carries things forwards in U (graphic 69)
D $B27A Object template 9; the rest as #R$B267.
R $B27A IX the conveyor
  $B27A,6 two units in U

@ $B280 label=CONVEYOR_MINUS_V
c $B280 The update routine for a conveyor that carries things back in V (graphic 70)
D $B280 Object template 10; the rest as #R$B267.
R $B280 IX the conveyor
  $B280,6 minus two units in V

@ $B286 label=CONVEYOR_MINUS_U
c $B286 The update routine for a conveyor that carries things back in U (graphic 71)
D $B286 Object template 11; the rest as #R$B267.
R $B286 IX the conveyor
  $B286,6 minus two units in U

@ $B28C label=COLLAPSING_BLOCK
c $B28C The update routine for a block that collapses when landed on (graphic 45)
D $B28C Object template 6. It sits still until the robot, or something else of graphics 16 to 47 that moves, lands on it -- bit 3 of +D, which the collision code sets on what such a thing lands on (#R$C535) -- and then it vanishes in the sparkle (#R$B3A4, #R$B3B0): graphic 64 is set and stepped to 65 in the same turn, so what is seen is 45, 65, gone (measured). Rebuilding the room brings it back. As Knight Lore's collapsing block (upd_143).
D $B28C Graphic 65's routine empties the place the record's +10 and +11 point to, which for a block is address 0 in the ROM: the write does nothing.
D $B28C Measured in the simulator in room $12: dropped on it, he stood on it for a turn; it became 65, then 1, then an empty record, and he fell.
R $B28C IX the block
  $B28C,3 the drawing nudge
  $B28F,9 landed on? (and ready for the next time)
  $B298,7 yes: graphic 64, and on into the sparkle's next frame

@ $B29F label=STILL_DEADLY
c $B29F The update routine for things that kill but never move (graphics 72 and 75)
D $B29F Object templates 15 and 23: sets the drawing nudge and makes the thing deadly both ways (#R$B2A4). It is not marked for redrawing, as nothing about it changes. As Pentagram's routine of the same name.
R $B29F IX the object
  $B29F,5 the drawing nudge; deadly both ways, and return from there

@ $B2A4 label=SPIKES
@ $B2A7 label=MAKE_DEADLY
c $B2A4 The update routine for the spikes (graphic 46)
D $B2A4 Object template 7. As #R$B29F with another drawing nudge. The entry at MAKE_DEADLY is the common part, used by many update routines: bits 7 and 5 of +D, so that the thing kills what it moves into and what touches it, whichever of them moved -- Knight Lore's set_both_deadly_flags.
R $B2A4 IX the object
  $B2A4,3 the drawing nudge
  $B2A7,9 +D OR $A0: deadly both ways

@ $B2B0 label=DEADLY_AND_DRAW
c $B2B0 Make an object deadly both ways, and redraw it
R $B2B0 IX the object
  $B2B0,6 deadly (#R$B2A4), and mark it to be redrawn

@ $B2B6 label=DROPPING_BLOCK
c $B2B6 The update routine for a block that sinks while something stands on it (graphic 44)
D $B2B6 Object template 5. Each turn something is on it -- bit 3 of +D, set by the collision code on what the robot or another mover of graphics 16 to 47 lands on (#R$C535), and cleared here -- it sinks one unit, with a grinding note, until it lands on what is under it. As Knight Lore's dropping block (upd_91).
D $B2B6 Measured in the simulator in room $82: with him on it, it went down one unit a turn from Z 100. On the floor, as in room $12, it cannot sink and stays put. The sessions of the build had never stood on one (the coverage report).
R $B2B6 IX the block
  $B2B6,3 the drawing nudge
  $B2B9,9 nothing on it: nothing to do, not even a redraw
  $B2C2,7 a Z step of 0, which the fall makes -1: down one
  $B2C9,4 no Z step kept
  $B2CD,9 still moving down: a grinding note pitched by Z
  $B2D6,3 redraw it

@ $B2D9 label=SAVE_UVZ
c $B2D9 Keep an object's position
D $B2D9 Copies U, V and Z to SAVED_UVZ, for #R$B2EB to compare after a move.
R $B2D9 IX the object
  $B2D9,18 U, V and Z to SAVED_UVZ

@ $B2EB label=SAME_UVZ
c $B2EB Is an object where it was?
D $B2EB Compares U, V and Z with SAVED_UVZ (#R$B2D9).
R $B2EB IX the object
R $B2EB O:F Z set if it has not moved
  $B2EB,20 U, V and Z each as they were

@ $B2FF label=PUSHABLE
@ $B302 label=PUSHABLE_MOVE
c $B2FF The update routine for a block that can be pushed (graphic 28)
D $B2FF Object template 2. Its flags have bit 2 set, and the collision code gives a thing with that bit the step of whatever pushes into it (#R$C497, #R$C4E6). Each turn it falls and moves by its steps; if it moved, its steps in U and V are cleared, so that a push moves it once and not on and on (the end of #R$C296 does the clearing), and it sounds a note pitched by its position and is redrawn. As Knight Lore's chest (upd_85) and table.
D $B2FF The position is kept before the move and compared after it, for the case where it has no step left but has moved. By the reading that cannot happen -- with every step zero the move adds nothing -- and the sessions never ran it.
R $B2FF IX the block
  $B2FF,3 the drawing nudge
  $B302,3 keep its place
  $B305,3 fall, and move
  $B308,5 any step left in U, V or Z?
  $B30D,7 none: redraw it only if it has moved (never, see above)
  $B314,6 moving: one step per push; a note pitched by U, V and Z, and redraw it

@ $B31A label=PUSHABLE_INVERTED
c $B31A The update routine for the other block that can be pushed (graphic 29)
D $B31A Object template 3: #R$B2FF with another drawing nudge. Its sprite is graphic 28's shape upside down.
R $B31A IX the block
  $B31A,5 the drawing nudge, and on as graphic 28

@ $B31F label=LIFT
@ $B33F label=BOBBER
@ $B34E label=LIFT_MOVE
c $B31F The update routines for the lift (graphic 47) and the bobbing block (graphic 31)
D $B31F The lift is object template 12 and the bobbing block template 4. Both keep their state in bit 2 of +D, which the kill bits leave free: clear while it goes down, one unit a turn, and set while it goes up, two a turn. Going down, it turns round when it is stopped (bit 2 of +C, set by the collision code whenever a move in Z is stopped, down or up); going up, it turns round when its Z passes the top, LIFT_TOP, the variable stage 1 called UNKNOWN_5B25, which the first of them updated after the room is built sets and every lift and block in the room then shares.
D $B31F The lift (entry here) waits on the floor: LIFT_TOP is its first Z plus 48, and it moves only in a turn the robot or another mover of graphics 16 to 47 lands on it (bit 3 of +D, set by #R$C535 and cleared here), or while its last move was stopped in Z -- as it is each turn it pushes a rider up. Left alone in mid-air it would stay where it is (by the reading; not tried). The bobbing block (entry at BOBBER) moves every turn, and LIFT_TOP is its first Z: it starts at the top.
D $B31F Going up, a stopped move is tried again at a step of 4: the collision code passes the lift's Z step to what it pushes into (#R$C535), so the rider is lifted.
D $B31F Measured in the simulator. Room $23: two lifts at Z 64 stayed put; dropped on one, he rode it up one unit a turn to Z 113 (LIFT_TOP 112), and it came down with him one unit a turn to the floor, and up again. Room $36: two bobbing blocks, LIFT_TOP 100, each falling one unit a turn to what is under it at Z 76 and rising two a turn to 102, half a cycle apart.
R $B31F IX the lift or the block
  $B31F,3 the drawing nudge
  $B322,14 the first lift in the room sets the top: its Z plus 48
  $B330,10 landed on this turn? (cleared for the next)
  $B33A,5 no: only move if the last move was stopped in Z
  $B33F,3 the drawing nudge (the bobbing block's entry)
  $B342,12 the first bobbing block in the room sets the top: its Z
  $B34E,3 a note pitched by Z
  $B351,7 no step in U or V
  $B358,6 going up?
  $B35E,6 down: a Z step of 0, which the fall makes -1
  $B364,10 stopped: go up from the next turn
  $B36E,3 redraw it
  $B371,7 up: a Z step of 3, which the fall makes 2
  $B378,6 not stopped: see if it is past the top
  $B37E,14 stopped by what is on it: try again at 4, which lifts the rider
  $B38C,8 not past the top: redraw it
  $B394,6 past it: go down from the next turn

# --------------------------------------------------------------------------
# The sparkle things vanish in
# --------------------------------------------------------------------------

@ $B39A label=START_SPARKLE
@ $B3AA label=SPARKLE_SOUND_AND_DRAW
c $B39A Start the sparkle an object vanishes in
D $B39A Turns the object into graphic 48, the first frame of the sparkle, and takes it out of the collision tests (bit 1 of its flags); #R$B3A4 runs it on through 49 to 54 a frame a turn, and #R$B3B0's graphic 55 ends it. Used by the robot's update routines (#R$C0BE, #R$C6E4) when he dies. Knight Lore's init_death_sparkles; Pentagram's START_PUFF.
R $B39A IX the object
  $B39A,10 graphic 48, out of collisions
  $B3AA,6 the sparkle's sound, and redraw it

@ $B3A4 label=SPARKLE_STEP
c $B3A4 The update routine for a frame of the sparkle (graphics 48 to 54, and 64)
D $B3A4 Moves the sparkle on a frame each turn: 48 to 54 run to 55, and 64 (a collapsing block, #R$B28C, or a touched extra life, #R$BEE0) goes to 65. The sound (#R$B5EE) is shorter at each frame.
R $B3A4 IX the object
  $B3A4,3 the drawing nudge
  $B3A7,3 the next frame

@ $B3B0 label=SPARKLE_END_PLACE
@ $B3B8 label=SPARKLE_END
@ $B3BB label=VANISH
@ $B3BF label=SOUND_AND_DRAW
c $B3B0 The update routines for the last frame of a sparkle (graphics 65 and 55)
D $B3B0 Graphic 65 is the end of the sparkle an extra life vanishes in (#R$BEE0): it first clears the graphic of its place in #R$76E3, whose address is in +10 and +11, so the extra life is gone for good. A collapsing block (#R$B28C) comes here too, with 0 in +10 and +11, and writes its zero into the ROM. Graphic 55, the end of a death's sparkle, comes in at SPARKLE_END. Either way the record becomes graphic 1, which the drawing empties when it next draws it, with a note pitched by the position. Knight Lore's upd_185_187.
D $B3B0 Two more entries serve other routines: VANISH, which turns any object into graphic 1 (#R$AE17, #R$AE33), and SOUND_AND_DRAW, a note pitched by U, V and Z and a redraw, the common end of many update routines.
R $B3B0 IX the object
  $B3B0,8 empty its place
  $B3B8,3 the drawing nudge (graphic 55's entry)
  $B3BB,4 graphic 1: gone when next drawn
  $B3BF,6 a note pitched by U, V and Z, and redraw it

# --------------------------------------------------------------------------
# The tunes
# --------------------------------------------------------------------------

@ $B3C5 label=TUNE_START
b $B3C5 The tune as a game starts
D $B3C5 Played to its end by #R$A647 between the menu and the first room. Seventeen notes, 18 units of about 0.155 seconds; the notes are 37 to 45 of #R$B51D.
D $B3C5 A tune is a string of note bytes ended by $FF: the low six bits of a note index the notes (#R$B51D, 0 would be a rest, and no tune has one), and the top two bits are its length less one, so a note lasts one to four units. The other tunes are in the same format. The winning tune (#R$B3D7) begins with these seventeen notes.
B $B3C5,17,8 Note bytes

@ $B3D6 label=TUNE_START_END
b $B3D6 The end of the start tune
B $B3D6,1 $FF ends the tune

@ $B3D7 label=TUNE_WON
b $B3D7 The tune at the end of the winning scene
D $B3D7 Played to its end by #R$A971 (graphic 92) as the scene after a won game finishes, before the menu. Thirty-one notes, 32 units: the start tune (#R$B3C5) and fourteen more.
B $B3D7,31,8 Note bytes

@ $B3F6 label=TUNE_WON_END
b $B3F6 The end of the winning tune
B $B3F6,1 $FF ends the tune

@ $B3F7 label=TUNE_GAME_OVER
b $B3F7 The game-over tune
D $B3F7 Played by #R$B761 under the summary after every game, won or lost, until a key is pressed (#R$B4A1's second entry). Sixty-three notes, 64 units, about ten seconds; notes 30 to 44. It runs on through the next eight entries to the $FF at #R$B436: sna2ctl took some of its bytes for text.
B $B3F7,20,8 Note bytes

@ $B40B label=TUNE_GAME_OVER_B
b $B40B The game-over tune, continued
B $B40B,1 A note

@ $B40C label=TUNE_GAME_OVER_C
b $B40C The game-over tune, continued
B $B40C,3 Note bytes

@ $B40F label=TUNE_GAME_OVER_D
b $B40F The game-over tune, continued
B $B40F,1 A note

@ $B410 label=TUNE_GAME_OVER_E
b $B410 The game-over tune, continued
B $B410,27,8 Note bytes

@ $B42B label=TUNE_GAME_OVER_F
b $B42B The game-over tune, continued
B $B42B,1 A note

@ $B42C label=TUNE_GAME_OVER_G
b $B42C The game-over tune, continued
B $B42C,3 Note bytes

@ $B42F label=TUNE_GAME_OVER_H
b $B42F The game-over tune, continued
B $B42F,1 A note

@ $B430 label=TUNE_GAME_OVER_I
b $B430 The game-over tune, continued
B $B430,6 Note bytes

@ $B436 label=TUNE_GAME_OVER_END
@ $B437 label=TUNE_ARRIVAL
@ $B451 label=TUNE_MENU
b $B436 The end of the game-over tune; the arrival tune; the menu tune
D $B436 Three things in one entry. The first byte is the $FF that ends the game-over tune (#R$B3F7). The arrival tune that follows is Knight Lore's game-completed tune, byte for byte (compared against its snapshot).
D $B436 TUNE_ARRIVAL, the next 26 bytes: the tune #R$B8A9 plays to its end when the game is won, as the arrival text is shown. Twenty-five notes and its $FF, 27 units; notes 26 to 34.
D $B436 TUNE_MENU, the last 80 bytes: the menu's tune (#R$BA7E, through #R$B4A1), played the first time the menu is shown after a game, until a key is pressed. Seventy-nine notes and its $FF, 79 units, about twelve seconds; notes 23 to 47.
B $B436,107,1,8,8,8,2,8,8,8,8,8,8,8,8,8,8 The game-over tune's $FF; the arrival tune and its $FF; the menu tune and its $FF

# --------------------------------------------------------------------------
# Playing tunes
# --------------------------------------------------------------------------

@ $B4A1 label=PLAY_TUNE_ONCE
@ $B4A9 label=PLAY_TUNE_TILL_KEY
c $B4A1 Play the menu's tune, once, until a key is pressed
D $B4A1 The menu (#R$BA7E) calls this every time round its loop with the tune at DE. TUNE_HEARD remembers that it has been played, so it plays only the first time; #R$A647 clears the variable with the rest after every game, so it plays again then. Before each note the whole keyboard is read, and any key stops the tune at once.
D $B4A1 #R$B761 comes in at PLAY_TUNE_TILL_KEY for the game-over tune, which plays after every game, until a key. The same routine as Pentagram's PLAY_TUNE_ONCE.
R $B4A1 DE the tune
  $B4A1,6 played already: done
  $B4A7,2 not again
  $B4A9,7 A = 0 reads every half-row at once: any key stops it
  $B4B0,10 $FF ends the tune; play a note, and look at the keys again

@ $B4BA label=PLAY_TUNE
c $B4BA Play the tune at DE
D $B4BA Plays the whole tune and returns; nothing else happens meanwhile, since the sound is made by timing loops. Used for the start tune (#R$A647), the winning tune (#R$A971) and the arrival tune (#R$B8A9). Knight Lore's play_audio; Pentagram's PLAY_TUNE.
R $B4BA DE the tune
  $B4BA,10 $FF ends it; play the note, and the next
  $B4C4,1 DE is left pointing at the $FF

@ $B4C5 label=PLAY_NOTE
c $B4C5 Play one note
D $B4C5 A note byte's low six bits index #R$B51D, with 0 a rest; its top two bits are its length less one, one to four units. A note's three bytes are two loop counts that time each half of a wave and how many waves make one unit, and the wave count rises with the pitch, which keeps every unit close to 0.155 seconds whatever the note. The speaker is driven directly, off for one half-wave and on for the other, with the border black.
D $B4C5 The routine and #R$B51D are byte for byte Knight Lore's play_note and its table, and Pentagram's PLAY_NOTE.
R $B4C5 A the note byte
R $B4C5 DE the address of the note byte; on exit, the next one
  $B4C5,4 index 0 is a rest
  $B4C9,11 HL = #R$B51D + 3 * index
  $B4D4,7 B and C time the half-wave; HL = the number of waves in one unit
  $B4DB,6 the top two bits: the length, one to four units
  $B4E1,10 HL = the waves in one unit times the length
  $B4EB,10 speaker off, border black; wait
  $B4F5,11 speaker on; wait
  $B500,5 until all the waves are done
  $B505,2 on to the next note byte
  $B507,7 a rest: one to four units...
  $B50E,15 ...each 17163 turns of a 26 T-state loop, about 0.127 seconds (no tune has a rest, and the sessions never played one)

@ $B51D label=NOTES
b $B51D The notes: 61 of three bytes
D $B51D Indexed by the low six bits of a note byte (#R$B4C5): the first two bytes are the B and C counts that time each half-wave, the third how many waves make one unit of length. Row 0 stands for a rest and is never read.
D $B51D The same 183 bytes as Knight Lore's and Pentagram's note tables (compared byte for byte), and so the same scale: a semitone a row for five octaves, about G#1 at row 1 and A4 (440Hz) at row 38 by Pentagram's working, with row 18 a copy of row 17's pitch where C#3 should be. The tunes here use rows 23 to 47 only.
B $B51D,183,3 Rows 0 to 60
E $B51D The last 26 bytes are not notes. The first 18 are code that nothing reaches -- no instruction or table holds an address in it, and no session ran it: LD A,(TURNS); AND 7; LD L,A; LD H,0; LD BC, the address of the eight bytes after it; ADD HL,BC; LD B,(HL); LD C,4; JP to BEEP (in #R$B6CE) -- four waves at a pitch from those eight bytes, chosen by the low three bits of the turn counter. The last eight are that table of half-wave counts. It is Knight Lore's blip for its moveable block, byte for byte apart from its three addresses (the turn counter, the table and BEEP), with the same eight pitches -- compared against Knight Lore's loaded snapshot; stage 2 had searched and missed it because the addresses differ.

# --------------------------------------------------------------------------
# Sound effects
# --------------------------------------------------------------------------

@ $B5EE label=SPARKLE_SOUND
c $B5EE The sparkle's sound
D $B5EE Short blips at pitches read from the ROM, from $1234 on: two waves each, and as many blips as the complement of the graphic's low five bits, so a sparkle's sound shortens as its frames go by -- 15 at graphic 48, 9 at 54, 31 at 64. Used by #R$B39A and #R$B3A4, and by #R$AF79 as a chamber is activated. As Knight Lore's sound_sparkle.
R $B5EE IX the object
  $B5EE,7 E = the complement of the graphic's low five bits
  $B5F5,3 the pitches: ROM bytes from $1234
  $B5F8,12 two waves at each, E times

@ $B604 label=MATERIALISE_SOUND
c $B604 The sound of the robot materialising
D $B604 A rising sweep, one wave a step, for graphics 56 to 62 (#R$BC70), the sparkle run backwards as a life starts. It starts from four times the graphic's low three bits, plus 3 -- 3 at graphic 56, 27 at 62 -- and steps down to 1, the half-wave count four times the step: higher as it goes. As Knight Lore's sound_materialise.
R $B604 IX the object
  $B604,10 C = 4 * (graphic AND 7) + 3 (the rotation brings bits 6-7 in as bits 0-1, but they are 0 here)
  $B60E,7 one wave at a half-wave count of 4 * C
  $B615,4 until C runs out

@ $B619 label=THUD_SOUND
c $B619 The sound of a thud
D $B619 Four blips of three waves at pitches read from the start of the ROM, made low by setting their top two bits. Used as the creatures turn (#R$B06B, #R$B110) and by #R$AB61. As Knight Lore's sound_thud.
  $B619,5 four, from the ROM's first bytes
  $B61E,7 three waves at the next ROM byte OR $C0
  $B628,4 until E runs out

@ $B62C label=JUMP_SOUND
c $B62C The sound of a jump
D $B62C A rising sweep of 32 single waves: five right rotations are three left ones, so the half-wave count is 8 times the step, which falls from 32 to 1 (the first, 256, wraps round to 1). Used by #R$C23D. As Knight Lore's sound_jump.
  $B62C,9 half-wave count 8 * C
  $B635,3 one wave
  $B638,4 until C runs out

@ $B63C label=BEEP_BY_Z
@ $B63F label=BEEP_BY_A
c $B63C A note pitched by an object's Z
D $B63C Six waves at a half-wave count of the complement of 64 more than Z, rotated left twice (so the top two bits wrap round): the higher the object, the higher the note. The entry at BEEP_BY_A takes the value in A; #R$B64A, #R$B64F and #R$B654 use it for U, V and all three. Knight Lore's sound_pitch_from_z and sound_pitch_from_a.
R $B63C IX the object
  $B63C,3 Z
  $B63F,6 B = the half-wave count
  $B645,5 six waves

@ $B64A label=BEEP_BY_U
c $B64A A note pitched by an object's U
R $B64A IX the object
  $B64A,5 U, then as #R$B63C

@ $B64F label=BEEP_BY_V
c $B64F A note pitched by an object's V
R $B64F IX the object
  $B64F,5 V, then as #R$B63C

@ $B654 label=BEEP_BY_UVZ
c $B654 A note pitched by an object's position
D $B654 The pitch follows the sum of U, V and Z, so it changes whichever way the object moves. Knight Lore's sound_pitch_from_xyz.
R $B654 IX the object
  $B654,11 U + V + Z, then as #R$B63C

@ $B65F label=TRANSFORM_SOUND
c $B65F Unused: Knight Lore's werewolf sound
D $B65F Code nothing reaches: no instruction or table holds its address, and no session ran it. sna2ctl left it as data; it decodes cleanly to its RET. It is Knight Lore's sound_transform byte for byte (found by searching Knight Lore's snapshot for these bytes): a warble of 16 to 40 single waves, the number set by the low two bits of the graphic -- the four frames of Sabreman changing into the werewolf and back -- each at a half-wave count of the step XOR $55, plus the step. Alien 8 kept the routine and dropped its only caller.
R $B65F IX the object
  $B65F,23 C = 16, 24, 32 or 40 by the graphic's bits 0-1; one wave at (C XOR $55) + C for each C down to 1

@ $B676 label=CRASH_SOUND
c $B676 The sound of a crash
D $B676 Sixteen blips of two waves at pitches read from the first 8K of the ROM, less their top bits: the address is the random number in the low byte and the turn counter's low five bits in the high one, so it differs every time. Used by #R$AB61 and #R$AD54. As Knight Lore's crash sound.
  $B676,12 HL = an address in the ROM; sixteen
  $B682,14 two waves at each ROM byte, less its top bit

@ $B690 label=WARBLE_SOUND
c $B690 A warble for the remote-controlled robots
D $B690 A few single waves, their pitch scrambled from the turn counter and the step count with an XOR. How many is read from a table at HL, indexed by the turn counter's low two bits: #R$A9C7 passes #R$B6A9, #R$AA89 the fifth byte of it, so the two run through different parts of the same rise and fall.
R $B690 HL the table of wave counts (#R$B6A9, or four bytes into it)
  $B690,9 C = the table's entry for the turn counter's low two bits
  $B699,12 one wave at half-wave count 64 + ((turns XOR C) AND 31)
  $B6A5,4 until C runs out

@ $B6A9 label=WARBLE_COUNTS
b $B6A9 How many waves each warble has
D $B6A9 Read four at a time by #R$B690, from the start or from the fifth byte.
B $B6A9,8,8 Wave counts, rising and falling

@ $B6B1 label=PLAIN_BEEP
c $B6B1 A plain beep: 16 waves at half-wave count 128
D $B6B1 Used as the control method changes on the menu (#R$BA7E), as a thing is picked up or put down (#R$BD6B), for an extra life (#R$BEE0) and by #R$ABF5.
  $B6B1,5 16 waves at 128

@ $B6B6 label=PAUSE_BEEP
c $B6B6 A beep: 24 waves at half-wave count 80
D $B6B6 The pause's beep (#R$CE22). Knight Lore's pause beep is the same.
  $B6B6,5 24 waves at 80

@ $B6BB label=HIGH_BEEP
c $B6BB A beep: 32 waves at half-wave count 48
D $B6BB As something lands on a conveyor (#R$B267), and for #R$AAA1.
  $B6BB,5 32 waves at 48

@ $B6C0 label=LOWER_HALF_STEP
c $B6C0 A footstep for a creature's lower half
D $B6C0 Called by #R$B055 with its own record, whose graphic is always 11: odd, so the RET at the top is always taken and the footstep never sounds (the sessions never ran the rest). What it would play is #R$B6CE's footstep at a fixed pitch of 128 on alternate pairs of turns, the complement of the turn counter where the robot's uses the counter itself. Knight Lore's audio_guard_wizard, where the walkers' graphics change.
R $B6C0 IX the object
  $B6C0,6 only on an even graphic: never
  $B6C6,8 a pitch of 128, and the turn counter inverted

@ $B6CE label=FOOTSTEP
@ $B6D4 label=FOOTSTEP_NOW
@ $B6D9 label=FOOTSTEP_PITCH
@ $B6FB label=BEEP
c $B6CE The robot's footstep
D $B6CE For the legs (#R$C25E), on every other frame of the walk: those with bit 0 of the graphic clear. FOOTSTEP_NOW skips that test (#R$C1E2). The pitch alternates by bit 1 of the turn counter between a fixed half-wave count of 96 and one from the height, the tick-tock of two feet; the number of waves is (U/2 + (256-V)/2)/16, which comes out longer towards plus U and shorter towards plus V. Knight Lore's sound_footstep.
D $B6CE BEEP, its end, is the common tail of the sound effects: C waves at a half-wave count of B. A C of 0 would mean 256 waves.
R $B6CE IX the legs
  $B6CE,6 only on even walking frames
  $B6D4,5 a pitch of 96, and the turn counter
  $B6D9,13 on alternate pairs of turns, a pitch from the height instead
  $B6E6,21 C = the number of waves, from U and V
  $B6FB,7 C waves of half-wave count B

@ $B702 label=CLICK
c $B702 One wave
D $B702 Speaker bit on for B turns of a 13 T-state loop, then off for as long, with the border black throughout; B is kept. Knight Lore's routine, and Pentagram's CLICK.
R $B702 B the half-wave count, kept
  $B702,8 speaker on; wait
  $B70A,8 speaker off; wait; B back

# --------------------------------------------------------------------------
# Collision helpers and the keyboard
# --------------------------------------------------------------------------

@ $B712 label=DO_ANY_OBJS_INTERSECT
c $B712 Does this object overlap any other?
D $B712 Tests IX against all 56 records with the tests on each axis at #R$C5A9, #R$C5BE and #R$C5D3, with no offset on any axis. Empty records are skipped, and so is any with bit 1 of its flags set (#R$B74D) -- which is how IX avoids finding itself: it sets its own bit 1 for the duration. Used by #R$BD6B, to see whether what he puts down has room. Knight Lore's do_any_objs_intersect and Pentagram's DO_ANY_OBJS_INTERSECT.
E $B712 The exit clears IX's bit 1 whatever it was before.
R $B712 IX the object
R $B712 O:F carry set if another object's box overlaps IX's where it stands
R $B712 O:IY the one it overlaps, when carry is set
  $B712,11 save the registers; IY walks all 56 records
  $B71D,8 no offset on U, V or Z; and IX out of its own way
  $B725,5 empty, or out of collisions: next
  $B72A,15 overlapping in U, V and Z: found, with carry set
  $B739,10 put the registers back and IX's bit 1 clear; the carry is kept
  $B743,10 next record; none: clear carry

@ $B74D label=IS_OBJECT_NOT_IGNORED
c $B74D Does this object take part in collisions?
D $B74D Z set for an empty record, or one with bit 1 of its flags set: the object moving now (#R$C442 sets it on itself), a lower half while its upper half moves (#R$B1FA), or one marked to be passed over, like a sparkle. Knight Lore's is_object_not_ignored.
R $B74D IY the object
R $B74D O:F Z set if it is to be skipped
  $B74D,5 an empty record
  $B752,7 bit 1 of the flags

@ $B759 label=READ_KEYS
c $B759 Read a half-row of the keyboard
D $B759 Knight Lore's routine, byte for byte. The IN does the selecting on its own: IN A,($FE) puts A on the top half of the address bus, so each 0 bit in A selects a half-row, and A = 0 reads all eight at once. The CPL turns the keys' active-low bits the right way up.
D $B759 The OUT before it is not needed for the read. It writes A to port A*256+$FD, which nothing on a 48K Spectrum answers; a 128K machine's paging port would decode it whenever A has bit 7 clear (see Pentagram's READ_KEYS, where that was tried). Not tried with Alien 8.
R $B759 A the half-rows to read, as the port's high byte
R $B759 O:A the keys pressed, bits 0-4, a set bit for a key down
R $B759 O:F Z set if none is
  $B759,2 not what selects the row: see above
  $B75B,2 reads port A*256+$FE
  $B75D,4 set bits now mean pressed keys; keep the five

# --------------------------------------------------------------------------
# The end of a game
# --------------------------------------------------------------------------

@ $B761 label=GAME_ENDED
@ $B76B label=SUMMARY_SCREEN
c $B761 The game is over
D $B761 Jumped to when the last life is lost (#R$CA07), when the clock runs out (#R$AD66), and when the twenty-fourth chamber is activated (#R$AF79). The valves in the room are put back in their places first (#R$AF05). A won game shows the arrival screen (#R$B8A9) first, which comes back to SUMMARY_SCREEN.
D $B761 The summary: the buffer cleared, the screen blanked with bright red attributes, and seven lines from the text list at #R$B94F -- the heading, the activated and unactivated chambers, the crew lost, and the overall rating -- then the rating, one of eight from the table after it, printed at x 88, line 39 of the buffer; then the counts are worked out (#R$AC6B) and printed (#R$BA36), the border drawn and the whole shown. The game-over tune plays until a key is pressed (after any key held is let go), and then the summary stays up for about fourteen seconds more or until another key.
D $B761 The rating: bit 0 of WON picks the better four of the eight, and bits 5 and 6 of the number of rooms seen less one (#R$B881) one of those four -- so it goes up a step for every 32 rooms seen, and a player who wins is rated above any who does not. As Knight Lore's game_over_summary.
D $B761 Then the scene: GAME_OVER is set, the buffer and the object records are cleared, the attributes made bright red, and the scene's objects put in the records (#R$B804) -- the re-programming of the robot (#R$B82A) after a lost game, with the flashing text RE-PROGRAMMING (#R$B7F5) at x 72, line 159; the robot and an oil can (the list at SCENE_WON in #R$B852) after a won one. NEW_ROOM is set and the main loop takes over: the scene's update routines run it, and one of them returns to the menu (#R$A647).
R $B761 O:SP the main loop resets it
  $B761,3 the valves in the room back in their places
  $B764,7 won: the arrival screen first
  $B76B,6 clear the buffer; the border black, the attributes bright red, the screen blank
  $B771,15 colours from #R$B94F, then positions and strings from the two tables after it: seven lines. The screen was shown once this game already, so the list only draws into the buffer
  $B780,7 the rooms seen less one: bits 5 and 6, as bits 6 and 7
  $B787,6 with WON as bit 0
  $B78D,8 rotated into a word offset: WON * 8 + the rooms' bits * 2
  $B795,7 DE = the rating's text, from the table of ratings in #R$B9DC
  $B79C,6 print it at x 88, line 39; its first byte is its colour
  $B7A2,6 work out the summary's counts, and print them into the buffer
  $B7A8,6 the border; show it all
  $B7AE,6 wait until no key is held
  $B7B4,6 the game-over tune, until a key
  $B7BA,5 then about 14 seconds more, or until a key
  $B7BF,5 the scene after a game is on
  $B7C4,9 clear the buffer; the border; show it
  $B7CD,3 clear the object records
  $B7D0,3 the attributes bright red
  $B7D3,6 won?
  $B7D9,9 lost: RE-PROGRAMMING at x 72, line 159
  $B7E2,3 the lost game's scene
  $B7E5,3 its objects into the records
  $B7E8,8 a new room: the main loop redraws it all, and runs the scene
  $B7F0,5 won: the won game's scene

@ $B7F5 label=REPROGRAMMING
b $B7F5 The text shown over the scene after a lost game
D $B7F5 A string in the printer's form (#R$BBB1): a colour byte, then the characters, the last with bit 7 set. The colour is flashing bright yellow on black. The less-than sign is the font's dash, so the text reads RE-PROGRAMMING.
B $B7F5,1 Flashing, bright, yellow ink

@ $B7F6 label=REPROGRAMMING_TEXT
t $B7F6 The re-programming text
T $B7F6,13

@ $B803 label=REPROGRAMMING_END
b $B803 The re-programming text's last character
B $B803,1 G, with bit 7 set

@ $B804 label=SET_UP_SCENE
c $B804 Put the scene's objects in the object records
D $B804 From the first record on, one record for each five-byte entry of the list at DE until a zero: the graphic to +0, the flags to +7, the colour to +10, and the place on the screen to +1A and +1B, x and line of the buffer. The scene's update routines draw from there and colour what they draw with +10 (the second entry of #R$ABF5). The records were cleared before (#R$CE4E).
R $B804 DE the list: #R$B82A after a lost game, or the one at SCENE_WON after a won one (#R$B852)
  $B804,7 IY at the first record
  $B80B,4 zero ends the list
  $B80F,23 graphic, flags, colour, x, line
  $B826,4 the next record

@ $B82A label=SCENE_LOST
b $B82A The objects of the scene after a lost game
D $B82A Eight entries of five bytes -- graphic, flags, colour, x, line -- ended by a zero, read by #R$B804. The list runs through the next eight entries to the zero at the start of #R$B852 (sna2ctl took some of its bytes for text). In order: graphic 81 in bright red at x 184, line 80; 83, bright white, 32, 80; 82, bright green, 120, 124; 88, bright cyan, 104, 64; 89, bright cyan, 128, 64; 90 and 91, drawn with the robot's own sprites (those of graphics 25 and 41), bright cyan, at 112, lines 69 and 85; and 80, bright yellow, 116, 104. Their update routines are #R$AB61 (81 to 83), #R$ABF5 (80), and the second entry of #R$ABF5 (88 to 91); every flags byte is $10.
B $B82A,7,5,2 Graphic 81; and the start of graphic 83's entry

@ $B831 label=SCENE_LOST_B
b $B831 The scene after a lost game, continued
B $B831,4,3,1 The rest of graphic 83's entry; graphic 82's first byte

@ $B835 label=SCENE_LOST_C
b $B835 The scene after a lost game, continued
B $B835,16,4,5,5,2 Graphic 82's entry, 88's, 89's, and the start of 90's

@ $B845 label=SCENE_LOST_D
b $B845 The scene after a lost game, continued
B $B845,4,3,1 The rest of graphic 90's entry; graphic 91's first byte

@ $B849 label=SCENE_LOST_E
b $B849 The scene after a lost game, continued
B $B849,1 Graphic 91's flags

@ $B84A label=SCENE_LOST_F
b $B84A The scene after a lost game, continued
B $B84A,4,3,1 The rest of graphic 91's entry; graphic 80's first byte

@ $B84E label=SCENE_LOST_G
b $B84E The scene after a lost game, continued
B $B84E,1 Graphic 80's flags

@ $B84F label=SCENE_LOST_H
b $B84F The scene after a lost game, continued
B $B84F,3 Graphic 80's colour, x and line

@ $B852 label=SCENE_LOST_END
@ $B853 label=SCENE_WON
b $B852 The end of the lost game's scene; the scene after a won game
D $B852 The zero that ends #R$B82A, and then SCENE_WON, the list #R$B804 reads after a won game: graphics 92 and 93, drawn with the same two sprites as 90 and 91, in white at x 112, lines 128 and 144, and graphic 85, the oil can, in bright green at x 108, line 32 -- run by #R$A971, #R$A95A and the second entry of #R$ABF5. It is ended by the zero at #R$B862.
B $B852,13,1,5,5,2 The end of the lost scene; graphic 92; 93; the start of 85's entry

@ $B85F label=SCENE_WON_B
b $B85F The scene after a won game, continued
B $B85F,3 Graphic 85's colour, x and line

@ $B862 label=SCENE_WON_END
b $B862 The end of the won game's scene
D $B862 The zero that ends the list at SCENE_WON (#R$B852). The stage-1 annotations had this byte as unused; it is read by #R$B804 at the end of every won game.
B $B862,1 End of the list

# --------------------------------------------------------------------------
# The rooms seen, and waiting
# --------------------------------------------------------------------------

@ $B863 label=MARK_ROOM_SEEN
c $B863 Mark the robot's room as seen
D $B863 ROOMS_SEEN is a 256-bit map, a bit per room number: the byte is the room number divided by 8, the bit its low three bits. SET takes its bit number in the opcode, so the second byte of the SET instruction at the end is rewritten before it runs. Called as a room is entered (#R$CAA2); #R$B881 counts the bits for the rating. Knight Lore's flag_room_visited, byte for byte in its logic.
  $B863,12 HL = the room / 8
  $B86F,11 the opcode byte for SET (room AND 7),(HL)
  $B87A,7 set the bit in the map

@ $B881 label=COUNT_ROOMS_SEEN
c $B881 Count the rooms seen
D $B881 Counts the set bits in the 32 bytes of ROOMS_SEEN, less one. Used for the rating after a game (#R$B761).
R $B881 O:A the number of rooms seen, less one
  $B881,8 E counts; 8 bits in each of 32 bytes
  $B889,9 count this byte's bits
  $B892,4 the next byte
  $B896,3 less one

@ $B899 label=WAIT_KEY_OR_TIME
c $B899 Wait for a key, or for a while
D $B899 Reads the whole keyboard B times 65536 times, and returns as soon as a key is down. At 95 T-states a read (counted from the instructions), B = 8 is about 14 seconds. Knight Lore's wait_key_poll.
R $B899 B how long to wait, in units of 65536 reads
R $B899 O:F NZ if a key was pressed
  $B899,3 the inner count
  $B89C,5 any key: done
  $B8A1,5 the inner count
  $B8A6,3 the outer count

@ $B8A9 label=ARRIVAL_SCREEN
c $B8A9 The game is won: the arrival screen
D $B8A9 Jumped to from #R$B761 when WON is set. Clears the buffer, blanks the screen with bright red attributes, prints the seven lines of the arrival text -- the station arrived and slowed, the activation circuits held, all crew systems go -- clearing TEXT_SHOWN first so that the list also draws the border and shows the screen, then plays the arrival tune to its end, waits about fourteen seconds or for a key, and goes on to the summary as for a lost game. As Knight Lore's game_complete_msg.
  $B8A9,6 clear the buffer; the border black, the attributes bright red, the screen blank
  $B8AF,12 colours from #R$B8D0, positions from ARRIVAL_XY, strings from ARRIVAL_TEXT: seven lines
  $B8BB,7 the first list since the flag was cleared: border and screen too
  $B8C2,6 the arrival tune, in full
  $B8C8,5 about 14 seconds, or until a key
  $B8CD,3 then the summary

@ $B8D0 label=ARRIVAL_COLOURS
@ $B8D7 label=ARRIVAL_XY
b $B8D0 The arrival screen's text: colours
D $B8D0 A text list for #R$BC25's printing loop (entered at #R$BC25's second entry by #R$B8A9) is three tables: a colour byte for each line; two bytes for each line's place, x and then the line of the buffer counted up from the bottom; and the strings, each ended by bit 7 set on its last character. Here seven lines: colours, from this entry; places from ARRIVAL_XY; strings from ARRIVAL_TEXT (in #R$B8DF). The whole list runs to #R$B94E; sna2ctl split it into pieces, some taken for text.
D $B8D0 The colours are bright cyan for the first two lines, then bright green, bright magenta, bright magenta, bright red and bright red. The places are x 32, line 143; 88, 127; 40, 111; 72, 95; 72, 79; 72, 63; and 88, 47.
B $B8D0,8,7,1 The seven lines' colours; then the first line's x

@ $B8D8 label=ARRIVAL_XY_B
b $B8D8 The arrival screen's text: places, continued
B $B8D8,3,1,2 The first line's line; the second's x and line

@ $B8DB label=ARRIVAL_XY_C
b $B8DB The arrival screen's text: places, continued
B $B8DB,3,2,1 The third line's place; the fourth's x

@ $B8DE label=ARRIVAL_XY_D
b $B8DE The arrival screen's text: places, continued
B $B8DE,1 The fourth line's line

@ $B8DF label=ARRIVAL_XY_E
@ $B8E5 label=ARRIVAL_TEXT
t $B8DF The arrival screen's text: the last places and the first string
D $B8DF The places of lines five to seven, then ARRIVAL_TEXT, the strings, which #R$B8A9 points at. The last character of each string, with bit 7 set, is an entry of its own.
B $B8DF,6,2 Lines five, six and seven: x and line

@ $B8FB label=ARRIVAL_TEXT_B
b $B8FB The arrival text, continued
B $B8FB,1 D, with bit 7 set

@ $B8FC label=ARRIVAL_TEXT_C
t $B8FC The arrival text, continued

@ $B905 label=ARRIVAL_TEXT_D
b $B905 The arrival text, continued
B $B905,1 E, with bit 7 set

@ $B906 label=ARRIVAL_TEXT_E
t $B906 The arrival text, continued

@ $B91A label=ARRIVAL_TEXT_F
b $B91A The arrival text, continued
B $B91A,1 W, with bit 7 set

@ $B91B label=ARRIVAL_TEXT_G
t $B91B The arrival text, continued

@ $B928 label=ARRIVAL_TEXT_H
b $B928 The arrival text, continued
B $B928,1 N, with bit 7 set

@ $B929 label=ARRIVAL_TEXT_I
t $B929 The arrival text, continued

@ $B936 label=ARRIVAL_TEXT_J
b $B936 The arrival text, continued
B $B936,1 D, with bit 7 set

@ $B937 label=ARRIVAL_TEXT_K
t $B937 The arrival text, continued

@ $B944 label=ARRIVAL_TEXT_L
b $B944 The arrival text, continued
B $B944,1 T, with bit 7 set

@ $B945 label=ARRIVAL_TEXT_M
t $B945 The arrival text, continued

@ $B94E label=ARRIVAL_TEXT_N
b $B94E The arrival text's last character
B $B94E,1 O, with bit 7 set

# --------------------------------------------------------------------------
# Range 3
# --------------------------------------------------------------------------

# --------------------------------------------------------------------------
# Range 3
# --------------------------------------------------------------------------

# Alien 8, stage 2, agent 3: $B94F-$C1D1 -- the summary screen's text and
# ratings, the panel's numbers, the menu and its text, the text printer, the
# carried things on the panel, picking up and putting down, the extra life,
# the drawing nudges, a box filler, the doorway pillars and their nudges, and
# the player's legs, turning included.

# --------------------------------------------------------------------------
# The summary after a game: its text list and the ratings ($B94F-$BA35)
# --------------------------------------------------------------------------

@ $B94F label=SUMMARY_COLOURS
b $B94F The summary screen: the colour of each line
D $B94F The summary shown after every game (#R$B761), won or lost, is a text list printed by DISPLAY_TEXT_LIST (#R$BC25) from three tables that run on from here: seven colours, one per line (this entry's first seven bytes); seven (x, y) pixel positions from the eighth byte (SUMMARY_XY), y counting up from the bottom of the screen; and the seven strings from SUMMARY_TEXT, in #R$B960, to #R$B9DC, ASCII with bit 7 set on the last character of each. sna2ctl split them into many entries, because the positions and colours are the codes of letters.
D $B94F The colours are bright white for the title, bright yellow for the two lines about the activated chambers, bright cyan for the two about the unactivated ones, bright magenta for the crew lost and bright green for the rating's heading. The three counts (#R$BA36) and the rating itself (in the routine at #R$B761, from #R$B9DC) are printed over the list afterwards.
B $B94F,8,7,1 The seven lines' colours; then the title's x, 88 (character column 11), the first byte of the positions
@ $B956 label=SUMMARY_XY

@ $B957 label=SUMMARY_Y_TITLE
b $B957 The summary screen: where the lines go (the title's y; lines 2 and 3)
D $B957 The positions go on from SUMMARY_XY, #R$B94F's last byte, an (x, y) pair per line; each line's characters cover the eight pixel rows from y down.
B $B957,5,1,2,2 The title's y, 159 (character row 4); "ACTIVATED CRYOGENIC" at (48, 143); the first "CHAMBERS" line at (48, 127)

@ $B95C label=SUMMARY_XY_UNACTIVATED
b $B95C The summary screen: where the lines go (line 4; line 5's x)
B $B95C,3,2,1 "UNACTIVATED CRYOGENIC" at (40, 111); x of the second "CHAMBERS" line, 48

@ $B95F label=SUMMARY_Y_CHAMBERS
b $B95F The summary screen: where the lines go (line 5's y)
B $B95F,1 y of the second "CHAMBERS" line: 95

@ $B960 label=SUMMARY_XY_LOST
t $B960 The summary screen: where the last two lines go, and the title
D $B960 The last two positions, then the list's strings begin, at SUMMARY_TEXT, the fifth byte of this entry.
B $B960,4,2 "CRYONAUGHTS LOST" at (40, 79); "OVERALL RATING" at (72, 55)
@ $B964 label=SUMMARY_TEXT

@ $B96C label=SUMMARY_TITLE_LAST
b $B96C The summary screen: the title's last letter
B $B96C,1 R, with bit 7 set to end the string

@ $B96D label=SUMMARY_ACTIVATED
t $B96D The summary screen: "ACTIVATED CRYOGENIC"

@ $B97F label=SUMMARY_ACTIVATED_LAST
b $B97F The summary screen: "ACTIVATED CRYOGENIC", its last letter
B $B97F,1 C, with bit 7 set

@ $B980 label=SUMMARY_CHAMBERS_ACTIVE
t $B980 The summary screen: the first "CHAMBERS" line
D $B980 "CHAMBERS" and a row of dots, which the font draws for the semicolon, then two spaces for the count (SUMMARY_ACTIVE) that #R$BA36 prints over them.

@ $B992 label=SUMMARY_CHAMBERS_ACTIVE_LAST
b $B992 The summary screen: the first "CHAMBERS" line, its last character
B $B992,1 A space, with bit 7 set

@ $B993 label=SUMMARY_UNACTIVATED
t $B993 The summary screen: "UNACTIVATED CRYOGENIC"

@ $B9A7 label=SUMMARY_UNACTIVATED_LAST
b $B9A7 The summary screen: "UNACTIVATED CRYOGENIC", its last letter
B $B9A7,1 C, with bit 7 set

@ $B9A8 label=SUMMARY_CHAMBERS_IDLE
t $B9A8 The summary screen: the second "CHAMBERS" line
D $B9A8 As #R$B980; the count printed over the spaces is SUMMARY_IDLE.

@ $B9BA label=SUMMARY_CHAMBERS_IDLE_LAST
b $B9BA The summary screen: the second "CHAMBERS" line, its last character
B $B9BA,1 A space, with bit 7 set

@ $B9BB label=SUMMARY_CRYONAUGHTS
t $B9BB The summary screen: "CRYONAUGHTS LOST."
D $B9BB Three spaces after the full stop (a semicolon in the code), where #R$BA36 prints the last three digits of SUMMARY_LOST.

@ $B9CE label=SUMMARY_CRYONAUGHTS_LAST
b $B9CE The summary screen: "CRYONAUGHTS LOST.", its last character
B $B9CE,1 A space, with bit 7 set

@ $B9CF label=SUMMARY_RATING
t $B9CF The summary screen: "OVERALL RATING"

@ $B9DC label=SUMMARY_RATING_LAST
b $B9DC The summary screen: "OVERALL RATING", its last letter; and the eight ratings
D $B9DC The heading's last letter, then, from RATINGS, the second byte of this entry, eight words: the addresses of the ratings, #R$B9ED to #R$BA2B. The summary (#R$B761) picks one by the rooms seen and by whether the game was won: the rooms seen (ROOMS_SEEN, counted by #R$B881) less one, divided by 32, is 0 to 3, and a won game adds 4. So a lost game rates POOR up to 32 rooms seen, AVERAGE up to 64, FAIR up to 96 and GOOD above; a won one EXCELLENT, MARVELLOUS, HERO and ADVENTURER the same way. AVERAGE ranks below FAIR. The eight words, their order and the way one is picked are Knight Lore's (its ratings table); only the colour differs.
D $B9DC The ratings are printed at (88, 39) by #R$BBB1, which takes a string's colour from its first byte: every rating starts with G, bright white.
B $B9DC,1 G, with bit 7 set
@ $B9DD label=RATINGS
W $B9DD,2 0: lost, up to 32 rooms seen: #R$B9ED
W $B9DF,2 1: lost, up to 64: #R$B9F5
W $B9E1,2 2: lost, up to 96: #R$B9FE
W $B9E3,2 3: lost, more: #R$BA06
W $B9E5,2 4: won, up to 32 rooms seen: #R$BA0E
W $B9E7,2 5: won, up to 64: #R$BA18
W $B9E9,2 6: won, up to 96: #R$BA23
W $B9EB,2 7: won, more: #R$BA2B

@ $B9ED label=RATING_POOR
t $B9ED Rating 0: "POOR"
D $B9ED The first byte is the colour, bright white; some words are padded on the left with spaces. The same form for all eight.
B $B9ED,1 The colour

@ $B9F4 label=RATING_POOR_LAST
b $B9F4 Rating 0, its last letter
B $B9F4,1 R, with bit 7 set

@ $B9F5 label=RATING_AVERAGE
t $B9F5 Rating 1: "AVERAGE"
B $B9F5,1 The colour

@ $B9FD label=RATING_AVERAGE_LAST
b $B9FD Rating 1, its last letter
B $B9FD,1 E, with bit 7 set

@ $B9FE label=RATING_FAIR
t $B9FE Rating 2: "FAIR"
B $B9FE,1 The colour

@ $BA05 label=RATING_FAIR_LAST
b $BA05 Rating 2, its last letter
B $BA05,1 R, with bit 7 set

@ $BA06 label=RATING_GOOD
t $BA06 Rating 3: "GOOD"
B $BA06,1 The colour

@ $BA0D label=RATING_GOOD_LAST
b $BA0D Rating 3, its last letter
B $BA0D,1 D, with bit 7 set

@ $BA0E label=RATING_EXCELLENT
t $BA0E Rating 4, the first for a won game: "EXCELLENT"
B $BA0E,1 The colour

@ $BA17 label=RATING_EXCELLENT_LAST
b $BA17 Rating 4, its last letter
B $BA17,1 T, with bit 7 set

@ $BA18 label=RATING_MARVELLOUS
t $BA18 Rating 5: "MARVELLOUS"
B $BA18,1 The colour

@ $BA22 label=RATING_MARVELLOUS_LAST
b $BA22 Rating 5, its last letter
B $BA22,1 S, with bit 7 set

@ $BA23 label=RATING_HERO
t $BA23 Rating 6: "HERO"
B $BA23,1 The colour

@ $BA2A label=RATING_HERO_LAST
b $BA2A Rating 6, its last letter
B $BA2A,1 O, with bit 7 set

@ $BA2B label=RATING_ADVENTURER
t $BA2B Rating 7, a won game with more than 96 rooms seen: "ADVENTURER"
B $BA2B,1 The colour

@ $BA35 label=RATING_ADVENTURER_LAST
b $BA35 Rating 7, its last letter
B $BA35,1 R, with bit 7 set

# --------------------------------------------------------------------------
# Numbers on the screen ($BA36-$BA7D)
# --------------------------------------------------------------------------

@ $BA36 label=PRINT_SUMMARY_COUNTS
c $BA36 Print the summary's three counts
D $BA36 Prints the counts #R$AC6B has worked out over the spaces the summary's text list (#R$B94F) leaves for them, into the buffer, in the digits' font: the activated chambers (SUMMARY_ACTIVE) at pixel x 184, y 127; the unactivated ones (SUMMARY_IDLE) at x 184, y 95; the crew lost (SUMMARY_LOST, four BCD digits of which the last three are printed) at x 176, y 79. Called by the summary (#R$B761), before it draws the border and shows the buffer.
  $BA36,6 the font itself as the base, so that a BCD digit is its own character code
  $BA3C,11 SUMMARY_LOST: its low digit, then both digits of the byte after
  $BA47,8 SUMMARY_ACTIVE, the next byte: both digits
  $BA4F,8 SUMMARY_IDLE, the byte after that

@ $BA57 label=PRINT_LIVES
@ $BA5C nowarn
c $BA57 Print the number of lives
D $BA57 LIVES as two BCD digits into the buffer at pixel x 128, y 7, on the panel. Called when the panel is drawn (#R$A749) and when an extra life is taken (#R$BEE0), which then copies the two characters to the screen (#R$BF2F).
D $BA57 LIVES counts in binary (#R$A631 sets 5, #R$CA07 takes one, #R$BEE0 adds one), so the display is right only while he has fewer than ten -- as in Knight Lore.
  $BA57,11 one byte, LIVES, into the buffer at pixel row 7, byte column 16
@ $BA62 label=PRINT_BCD_NUMBER
N $BA62 Print B bytes of BCD from DE into the buffer at HL, two digits each, the high digit first. Also used by #R$A7A3 for the chambers activated.
  $BA62,8 the font itself as FONT_BASE: digits are codes 0 to 9
@ $BA6A label=PRINT_BCD_BYTE
  $BA6A,10 the high digit
@ $BA74 label=PRINT_BCD_LSD
  $BA74,6 the low digit; coming in here prints only the low digit of the first byte (#R$BA36)
  $BA7A,4 the next byte

# --------------------------------------------------------------------------
# The menu ($BA7E-$BB9C)
# --------------------------------------------------------------------------

@ $BA7E label=MENU
c $BA7E The menu
D $BA7E Called by #R$A647 before every game. It clears TEXT_SHOWN, so that the first list printed draws the border and shows the buffer, stops every line's flash, clears the buffer, draws the menu (#R$BC25) and flashes the lines chosen (#R$BAFB). Then round a loop: print the text again (only its attributes, with the flashing, reach the screen), play the tune if it has not been heard (#R$B4A1, which a key cuts short), and read the keys.
D $BA7E Keys 1 to 4 set bits 1 and 2 of CONTROL to 0 keyboard, 1 Kempston, 2 cursor, 3 Interface II; if several are held the highest wins, since each is applied in turn. Key 5 toggles bit 3, directional control, once a press (KEY5_HELD). A change to CONTROL beeps (#R$B6B1). Key 0 starts the game. Every pass counts SEED up by one, so the time spent on the menu goes into the choice of start room (#R$CA6D).
D $BA7E As Knight Lore's menu, key 5 and all; Pentagram's is this code without key 5 and without the beep.
  $BA7E,4 no list shown yet
  $BA82,10 no line flashing: all eight colours in #R$BB14
  $BA8C,9 a clear buffer; the text, the border and the whole screen; the lines chosen
@ $BA95 label=MENU_LOOP
  $BA95,9 the text again; the tune, once
  $BA9E,6 E = keys 1-5, key 1 in bit 0
  $BAA4,6 A = CONTROL, and as it was into CONTROL_BEFORE
  $BAAA,6 1: keyboard
  $BAB0,8 2: Kempston
  $BAB8,8 3: cursor keys
  $BAC0,6 4: Interface II
  $BAC6,3 the new method
  $BAC9,7 key 5 not held: clear its latch (at the end)
  $BAD0,4 still held since the last pass: nothing
  $BAD4,10 a new press: latch it, and toggle directional control
@ $BADE label=MENU_BEEP_IF_CHANGED
  $BADE,7 A is the new CONTROL whichever way this is reached: beep if it has changed
  $BAE5,8 key 0 (bit 0 of the 6-0 half-row): start the game
  $BAED,4 one more to the seed each pass
  $BAF1,6 flash the choice; round again
@ $BAF7 label=MENU_KEY5_RELEASED
  $BAF7,4 key 5 is up: clear the latch

@ $BAFB label=FLASH_MENU
c $BAFB Flash the chosen lines on the menu
D $BAFB Sets the FLASH bit on the colour of the line for the method in bits 1-2 of CONTROL and clears it on the other three (#R$BC15), then sets or clears it on the next colour -- the "5 DIRECTIONAL CONTROL" line's -- to match bit 3 of CONTROL. The colours are #R$BB14's; the title's, the first, is left alone. As Knight Lore's flash_menu, instruction for instruction.
  $BAFB,14 the four method lines, from the second colour: flash the one for bits 1-2
  $BB09,11 HL is now on the directional-control line's colour: flash it if bit 3 is set

@ $BB14 label=MENU_COLOURS
t $BB14 The menu: the colour of each line
D $BB14 The menu's three tables run on from here as one block, as the summary's do (#R$B94F): eight colours, one per line; eight (x, y) pixel positions from the ninth byte (MENU_XY), y counting up from the bottom of the screen; and the eight strings from MENU_TEXT, in #R$BB26, to #R$BB9C, ASCII with bit 7 set on the last character of each. #R$BC25 hands the three addresses to DISPLAY_TEXT_LIST.
D $BB14 The colours are bright magenta for the title, bright green for the four control methods, bright cyan for directional control and bright white for the start and copyright lines. #R$BAFB sets bit 7 (FLASH) of the chosen method's and of directional control's; #R$BA7E clears bit 7 of all eight before the menu is drawn.
B $BB14,9,8,1 The eight lines' colours; then the title's x, 104 (character column 13), the first byte of the positions
@ $BB1C label=MENU_XY

@ $BB1D label=MENU_Y_TITLE
b $BB1D The menu: where the lines go (the title's y; keys 1 and 2)
D $BB1D The positions go on from MENU_XY, #R$BB14's last byte, an (x, y) pair per line. The option lines start at x 48, character column 6, and step down 16 pixels, two character rows, from y 143.
B $BB1D,5,1,2,2 The title's y, 159 (character row 4); "1 KEYBOARD" at (48, 143); "2 KEMPSTON JOYSTICK" at (48, 127)

@ $BB22 label=MENU_XY_KEY3
b $BB22 The menu: where the lines go (key 3; key 4's x)
B $BB22,3,2,1 "3 CURSOR JOYSTICK" at (48, 111); x of "4 INTERFACE II", 48

@ $BB25 label=MENU_Y_KEY4
b $BB25 The menu: where the lines go (key 4's y)
B $BB25,1 y of "4 INTERFACE II": 95

@ $BB26 label=MENU_XY_KEY5
t $BB26 The menu: where the last three lines go, and the title
D $BB26 The last three positions, then the menu's strings begin, at MENU_TEXT, the seventh byte of this entry, with the title.
B $BB26,6,2 "5 DIRECTIONAL CONTROL" at (48, 79); "0 START GAME" at (48, 63); the copyright line at (80, 39)
@ $BB2C label=MENU_TEXT

@ $BB32 label=MENU_TITLE_LAST
b $BB32 The menu: the title's last character
B $BB32,1 8, with bit 7 set to end the string

@ $BB33 label=MENU_KEYBOARD
t $BB33 The menu: "1 KEYBOARD"

@ $BB3C label=MENU_KEYBOARD_LAST
b $BB3C The menu: "1 KEYBOARD", its last letter
B $BB3C,1 D, with bit 7 set

@ $BB3D label=MENU_KEMPSTON
t $BB3D The menu: "2 KEMPSTON JOYSTICK"

@ $BB4F label=MENU_KEMPSTON_LAST
b $BB4F The menu: "2 KEMPSTON JOYSTICK", its last letter
B $BB4F,1 K, with bit 7 set

@ $BB50 label=MENU_CURSOR
t $BB50 The menu: "3 CURSOR JOYSTICK"

@ $BB60 label=MENU_CURSOR_LAST
b $BB60 The menu: "3 CURSOR JOYSTICK", its last letter
B $BB60,1 K, with bit 7 set

@ $BB61 label=MENU_INTERFACE
t $BB61 The menu: "4 INTERFACE II"

@ $BB6E label=MENU_INTERFACE_LAST
b $BB6E The menu: "4 INTERFACE II", its last letter
B $BB6E,1 I, with bit 7 set

@ $BB6F label=MENU_DIRECTIONAL
t $BB6F The menu: "5 DIRECTIONAL CONTROL"

@ $BB83 label=MENU_DIRECTIONAL_LAST
b $BB83 The menu: "5 DIRECTIONAL CONTROL", its last letter
B $BB83,1 L, with bit 7 set

@ $BB84 label=MENU_START
t $BB84 The menu: "0 START GAME"

@ $BB8F label=MENU_START_LAST
b $BB8F The menu: "0 START GAME", its last letter
B $BB8F,1 E, with bit 7 set

@ $BB90 label=MENU_COPYRIGHT
t $BB90 The menu: the copyright line
D $BB90 Reads on the screen as a copyright sign, then "1985 A.C.G.": the font (#R$6308) draws the copyright sign for the code of the greater-than sign, and a full stop for the semicolon (drawn from the font's bytes).

@ $BB9C label=MENU_COPYRIGHT_LAST
b $BB9C The menu: the copyright line's last character
B $BB9C,1 The last full stop (a semicolon in the code), with bit 7 set

# --------------------------------------------------------------------------
# The text printer ($BB9D-$BC55)
# --------------------------------------------------------------------------

@ $BB9D label=PRINT_TEXT_SINGLE_COLOUR
@ $BB9E nowarn
c $BB9D Print a string in one colour
R $BB9D HL the position: L = x, H = y, in pixels, y counting up from the bottom of the screen
R $BB9D DE the string, ASCII with bit 7 set on the last character
R $BB9D O:DE the byte after the string
D $BB9D Prints into the screen buffer (#R$D120) in the text font, colouring each character's cell straight into the attribute file with PRINT_ATTR. Each character covers the pixel rows from y down to y-7. As Knight Lore's print_text_single_colour, instruction for instruction; the rest is in #R$BBB1.
  $BB9D,7 the text font: FONT_BASE 384 bytes below the font at #R$6308, so that a letter's code lands on its glyph
  $BBA4,7 BC = the position again, left on the stack for TEXT_ATTR_ADDR; HL = its address in the buffer
  $BBAB,6 the colour into A'

@ $BBB1 label=PRINT_TEXT
@ $BBB2 nowarn
c $BBB1 Print a string whose first byte is its colour
R $BBB1 HL the position: L = x, H = y, in pixels, y counting up from the bottom
R $BBB1 DE the colour byte, then the string, bit 7 set on its last character
R $BBB1 O:DE the byte after the string
D $BBB1 As #R$BB9D, but the colour is the string's own first byte. The panel's "LIGHT YEARS" (#R$A749, which writes that byte first) and the summary's rating (#R$B761, #R$B9ED) are printed with it. Knight Lore's print_text; Pentagram has these bytes too, but nothing reaches them there.
D $BBB1 TEXT_ATTR_ADDR, the entry after the colour is in A', takes the position off the stack: in the alternate registers HL' becomes the attribute address of the first cell, while DE' is kept, since the list printer (#R$BC25) walks its colours with it. Then each character is drawn into the buffer by #R$BBEB, which leaves HL one cell to the right, and its cell in the attribute file is given the colour.
E $BBB1 The PUSH DE and POP DE round each call of #R$BBEB are not needed: it keeps DE itself.
  $BBB1,7 the text font
  $BBB8,7 BC = the position, left on the stack; HL = its address in the buffer
  $BBBF,3 the colour, from the string's first byte, into A'
@ $BBC2 label=TEXT_ATTR_ADDR
  $BBC2,2 take the position off the stack into HL'
  $BBC4,7 HL' = the attribute address of the position (#R$D157); DE' kept
@ $BBCB label=PRINT_TEXT_CHAR
  $BBCB,6 bit 7 marks the last character
  $BBD1,6 draw it, and move on in the string
  $BBD7,7 colour its cell, one cell right, and loop
@ $BBDE label=PRINT_TEXT_LAST
  $BBDE,8 the last character, without its end marker; DE ends past the string
  $BBE6,5 colour its cell

@ $BBEB label=PRINT_CHAR
@ $BC07 nowarn
c $BBEB Print a character into the screen buffer
R $BBEB A the code
R $BBEB HL the buffer address of the character's top row
R $BBEB O:HL one byte to the right
D $BBEB A character is eight bytes from FONT_BASE plus eight times its code, the top row first; they overwrite eight rows of the buffer going down from HL (32 bytes a row, down being towards the start of the buffer). HL comes back one byte to the right, on the same top row, ready for the next character. A space is printed as code $3D, whose glyph is blank.
D $BBEB For text FONT_BASE is 384 bytes below the font (#R$BB9D), so the codes $30 to $5A land in it; for numbers it is the font itself (PRINT_BCD_NUMBER, in #R$BA57), so that digits are codes 0 to 9. The light years (#R$ADB0) come in at PRINT_GLYPH with HL already eight times the code.
  $BBEB,6 a space is code $3D
  $BBF1,9 HL = 8 * the code
@ $BBFA label=PRINT_GLYPH
  $BBFA,6 DE = FONT_BASE + HL, the glyph
  $BC00,14 eight rows, each written 32 bytes below the one before
  $BC0E,7 back up the eight rows and one byte right

@ $BC15 label=TOGGLE_SELECTED
c $BC15 Flash one of B attributes, and steady the rest
D $BC15 Sets bit 7, FLASH, on the A'th of B attribute bytes from HL, counting from 0, and clears it on the others. #R$BAFB marks the chosen control method on the menu with it. This entry deals with the first byte; the loop is #R$BC1C. HL comes back just past the last byte. As Knight Lore's toggle_selected.
R $BC15 HL the first attribute
R $BC15 B how many
R $BC15 A which one flashes
  $BC15,3 not the first
@ $BC18 label=FLASH_THIS_ONE
  $BC18,4 flash this one

@ $BC1C label=FLASH_NEXT_ONE
c $BC1C The rest of #R$BC15
D $BC1C Counts A down a byte at a time, flashing the byte where it reaches zero.
  $BC1C,3 this is the one
@ $BC1F label=UNFLASH_THIS_ONE
  $BC1F,2 steady
@ $BC21 label=FLASH_LIST_STEP
  $BC21,4 the next byte, until B runs out

@ $BC25 label=DISPLAY_MENU
c $BC25 Draw the menu
D $BC25 Hands DISPLAY_TEXT_LIST, the rest of this routine, the menu's eight colours (#R$BB14), positions and strings. Called at the start of the menu and on every pass of its loop (#R$BA7E).
  $BC25,4 DE' = the colours
  $BC29,3 HL = the positions, MENU_XY
  $BC2C,3 DE = the strings, MENU_TEXT
  $BC2F,2 eight lines
@ $BC31 label=DISPLAY_TEXT_LIST
N $BC31 Print a list of strings. B how many; DE' their colours, a byte each; HL their positions, an (x, y) pair each; DE the strings, end to end. Also used by the summary (#R$B761) and the arrival screen (#R$B8A9).
  $BC31,7 this string's colour into PRINT_ATTR, for #R$BB9D
  $BC38,8 L = x, H = y; HL moved on to the next pair and kept
  $BC40,7 print it, and loop
  $BC47,5 the first list since TEXT_SHOWN was cleared...
  $BC4C,4 ...sets it...
  $BC50,6 ...draws the border (#R$CB8A) and shows the whole buffer (#R$CE85); later lists only redraw into the buffer and write the attributes, which is how the menu's flashing lines change without the screen being redrawn

@ $BC56 label=MULTIPLE_PRINT_SPRITE
c $BC56 Draw a sprite several times in a line
R $BC56 IX the record: the graphic at +0, the flags at +7, the pixel position at +$1A and +$1B
R $BC56 B how many times
R $BC56 E the step in x between copies
R $BC56 D the step in y between copies
D $BC56 Used to build the border (#R$CB8A) and the panel's frame (#R$CB0F) out of repeated pieces, drawn through the spare record at #R$BD38. As Knight Lore's multiple_print_sprite.
  $BC56,9 draw it (the entry into #R$D013 past the projection), keeping the registers
  $BC5F,14 move the record's x by E and y by D
  $BC6D,3 and again

# --------------------------------------------------------------------------
# The robot appearing ($BC70-$BC9C)
# --------------------------------------------------------------------------

@ $BC70 label=PLAYER_APPEARING
c $BC70 The update routine for the robot appearing (graphics 56 to 62)
D $BC70 Reached through #R$A7EA. As a life starts or he comes through a doorway both of the robot's records begin as graphic 56 with their real graphic kept at +$10 (#R$C397, #R$CA6D; the start records at #R$CA1D). This steps the graphic on by one every other turn, on the turns TURNS is odd, with a sound worked out from the frame (#R$B604), until #R$BC83 finishes. Seven frames of two turns each. As Knight Lore's upd_120_to_126.
R $BC70 IX the record
  $BC70,3 the drawing nudge: X -12, Y -8
  $BC73,7 only when bit 0 of TURNS is set
  $BC7A,9 the next frame, its sound, and mark it to be drawn

@ $BC83 label=PLAYER_APPEARED
c $BC83 The update routine for the robot's last frame of appearing (graphic 63)
D $BC83 Reached through #R$A7EA. Turns the record back into what it was -- the graphic kept at +$10 -- with no step in U, V or Z and bit 6 of +$0D, the killed flag, clear, and runs that graphic's update routine at once, through the main loop's dispatch (#R$A647). As Knight Lore's upd_127. Why the killed flag is cleared here is not certain: perhaps so that something deadly he touched while appearing does not count.
R $BC83 IX the record
  $BC83,3 the drawing nudge: X -12, Y -8
  $BC86,10 no step in U, V or Z
  $BC90,4 not killed
  $BC94,9 the real graphic back, and its update routine now

# --------------------------------------------------------------------------
# The carried things on the panel ($BC9D-$BD57)
# --------------------------------------------------------------------------

@ $BC9D label=SHOW_CARRIED
c $BC9D Show the carried things on the panel, if they have changed
D $BC9D Called every turn by #R$CEAB; it acts only when PANEL_DUE is set, as #R$BD6B sets it when what he carries changes, and not once the game is won. The panel's drawing (#R$A749) comes in at SHOW_CARRIED_NOW to draw them regardless.
D $BC9D The panel shows the three slots CARRIED, the one after it, and CARRIED_LAST (four bytes each: the graphic first), in three boxes 24 pixels square at the bottom left of the screen, at pixel x 8, 32 and 56, y 0. For each, the box is cleared in the buffer (#R$BF83), the thing's sprite drawn there through the spare record at #R$BD38 (by the entry into #R$D013 past the projection, with the mirror bit clear), and the box copied to the screen (#R$CF85); then its three by three attribute cells are coloured by the graphic's low four bits, from #R$BD34, which gives each of the four kinds of valve its own colour. An empty slot is cleared, and coloured as if graphic 0. As Pentagram's SHOW_CARRIED; Knight Lore's does the same with more routines.
  $BC9D,5 not once the game is won
  $BCA2,9 nothing has changed; or clear the flag
@ $BCAB label=SHOW_CARRIED_NOW
  $BCAB,11 IX = the spare record; three boxes; HL = the first slot shown
@ $BCB6 label=SHOW_CARRIED_BOX
  $BCB6,26 the box's pixel x: 8 + 24 times its number; pixel y 0, the bottom of the screen
  $BCD0,19 clear three bytes by 24 rows of the buffer
  $BCE3,15 something there: its sprite into the buffer, not mirrored
  $BCF2,20 copy the box from the buffer to the screen
  $BD06,15 C = the colour for the slot's graphic
  $BD15,13 DE = the attribute address of the box's top row, 23 pixels up
  $BD22,7 colour three cells by three
  $BD29,8 the next slot, four bytes on
  $BD31,3 IX back

@ $BD34 label=CARRIED_COLOURS
b $BD34 The colours of the carried things
D $BD34 Four attributes, indexed by the low four bits of a carried thing's graphic (#R$BC9D): bright red, magenta, cyan and white ink on black, for the valves of graphics 96 to 99. Only valves can be carried (#R$BEA7). sna2ctl took them for text, since they are the codes of four capital letters.
B $BD34,4,4 Graphics 96, 97, 98 and 99

@ $BD38 label=PANEL_RECORD
s $BD38 A spare object record, for drawing on the panel and the border
D $BD38 Never one of the room's objects: #R$BC9D draws the carried things through it, and #R$CB0F and #R$CB8A the panel's frame and the border. They set its graphic (+0), its flags (+7) and its pixel position (+$1A, +$1B), and the sprite drawing (the entry into #R$D013 past the projection) writes +$18 and +$19. Zero on the tape.

# --------------------------------------------------------------------------
# Picking up and putting down ($BD58-$BED5)
# --------------------------------------------------------------------------

@ $BD58 label=CHK_PICKUP_DROP
c $BD58 Is the pick-up control pressed?
R $BD58 O:F Z clear if it is
R $BD58 O:A bit 4 set if it is
D $BD58 The pick-up bit is bit 4 of INPUT, except with a joystick and bit 3 of CONTROL (directional control) set, when it is taken from bit 5: then a joystick's down is a direction, and #R$C8FF sets bit 5 from any key but the number keys, CAPS SHIFT and SPACE instead. As Knight Lore's chk_pickup_drop.
  $BD58,6 the method, bits 1-2 of CONTROL
  $BD5E,5 this turn's controls; the keyboard: bit 4 as it is
  $BD63,4 a joystick without directional control: bit 4 as it is
  $BD67,1 a joystick with it: bit 5 moves into bit 4
  $BD68,3 the pick-up bit

@ $BD6B label=TAKE_OR_LEAVE
c $BD6B Pick up, or put down
R $BD6B IX the robot's legs (#R$5B88)
D $BD6B Called from the legs' update routine (#R$C0BE) every turn. One press does one thing: pick up a valve he is on or beside; failing that, put down the last of the things he carries (CARRIED_LAST), under himself, so that he stands on it; and if there is nothing in that slot, move what he carries one slot along towards it. TAKE_HELD latches the press, so holding the key does nothing more, and every press that gets past the tests below beeps (#R$B6B1). Knight Lore's handle_pickup_drop and the routines after it, joined into one, as in Pentagram.
D $BD6B Nothing happens unless he is inside the room's walls (#R$C117, not in a doorway), not jumping (bit 3 of +$0C) and standing on something (bit 2). Before anything else it looks for an object in the space he would fill if he were lifted 12 units (#R$B712): if there is one, NO_HEADROOM is set and nothing is put down, because putting something down lifts him 12 units onto it.
D $BD6B Only the two records at VALVES are looked at, for a thing to pick up and for a record to put one down in: the records that hold what lies in the room from the table of places (#R$76E3). So only a valve that lies in its place can be picked up, and a thing can be put down only while one of the two is empty: a room holds at most two valves.
D $BD6B He carries up to three things, in the four-byte slots CARRIED (the newest), the one after, and CARRIED_LAST (the oldest, put down next): the graphic, the flags from +7, and the address of the thing's place (#R$76E3). CARRIED_NEW is a fourth slot in front of them, where a thing just picked up waits for the slots to be moved along. They behave as a queue, and a press that puts nothing down moves them along: one thing carried takes three presses to reach CARRIED_LAST and a fourth to be put down (measured by the build's sessions: see the notes' driving recipe).
  $BD6B,7 the key is still held from the last press: wait for it to go up
  $BD72,4 not pressed: nothing to do
  $BD76,4 only inside the room's walls
  $BD7A,10 not while jumping (bit 3 of +$0C); only when standing on something (bit 2)
  $BD84,21 anything in the space he would fill lifted by 12? His Z is raised to look, with the legs as high as the whole robot (#R$C0BE), then put back
  $BD99,5 yes: there is no room for him to stand on what he puts down
  $BD9E,11 beep; latch the key, and have the panel's carried things redrawn (#R$BC9D)
  $BDA9,31 each half-size 4 more, so that a thing just out of reach counts; the old ones go on the stack
  $BDC8,17 the two records of what lies in the room: the first that can be picked up (#R$BEA7) is taken
  $BDD9,5 nothing to pick up. This test cannot fail: INPUT has not changed since the same test at the start
  $BDDE,19 the first empty record of the two, to put a thing down in; none: nothing is put down
@ $BDF1 label=TAKE_DONE
  $BDF1,12 his half-sizes back
@ $BDFD label=WAIT_TAKE_RELEASE
  $BDFD,9 clear the latch once the key is up
@ $BE06 label=PUT_DOWN_LAST
N $BE06 Put down the last thing he carries, into the empty record at IY.
  $BE06,8 nothing in the last slot: just move the slots along
  $BE0E,6 no headroom: put nothing down
  $BE14,6 the thing's graphic into the empty record; HL on to the slot's flags
  $BE1A,14 U, V and Z from the robot's legs, so that it goes down where he stands
  $BE28,16 lift both of his records by 12, the thing's height, so that he stands on it
  $BE38,3 its place on the screen (#R$AE8A)
@ $BE3B label=FILL_PUT_DOWN
N $BE3B Fill in the record of a thing put down: IY the record, its graphic and position already set; the slot's flags byte on the stack.
  $BE3B,12 half-sizes 5, 5 and 12
  $BE47,12 +7 the flags from the slot; +8 the room, the robot's
  $BE53,9 +$10 and +$11: the address of its place, from the slot. The place itself is not written: when he leaves the room #R$AF05 copies where the valve now lies into it
  $BE5C,4 bit 0 of +$0D: just put down, which the valve's update routine (#R$AF79) reads once
@ $BE60 label=SHIFT_CARRIED
N $BE60 Move the carried things one slot along.
  $BE60,11 twelve bytes up by four, copied from the top down so that they do not overwrite themselves: CARRIED_NEW moves into CARRIED, and so on to CARRIED_LAST
  $BE6B,11 CARRIED_NEW is empty
@ $BE76 label=PICK_UP_VALVE
N $BE76 Pick up the valve at IY.
  $BE76,7 picking something up lets the things on the ceiling drop (DROP_LATCH)
  $BE7D,21 graphic, flags and place's address into CARRIED_NEW; the place's graphic zeroed, so that the valve is not put back in its room when he leaves or comes back
  $BE92,7 mark it to be rubbed out (#R$ADF3), and make it graphic 1, which the drawing code rubs out and then empties
  $BE99,8 carrying nothing in the last slot: move the slots along
  $BEA1,6 three: the oldest goes down where this one was, in the same record -- picking up swaps (this never ran in the build's sessions)

@ $BEA7 label=CAN_PICK_UP
c $BEA7 Can this thing be picked up?
R $BEA7 IX the robot's legs
R $BEA7 IY the thing
R $BEA7 O:F carry set if it can
D $BEA7 Only a valve (graphics 96 to 99), and only when he is on or beside it: IS_ON_OR_NEAR_OBJ, their boxes overlapping in U and V, and in Z with him lowered by 4, so that a thing he stands on counts as touching. The caller (#R$BD6B) has made his box 4 bigger each way. Knight Lore's can_pickup_spec_obj and is_on_or_near_obj together; #R$BEE0 uses the second alone.
  $BEA7,8 a valve, graphic 96 to 99; otherwise no carry
@ $BEAF label=IS_ON_OR_NEAR_OBJ
  $BEAF,16 overlapping in U and V (#R$C5A9, #R$C5BE), with no offset
  $BEBF,21 in Z (#R$C5D3), with him 4 lower, then put back
  $BED4,2 BC kept

@ $BED6 label=IS_OBJ_MOVING
c $BED6 Is the object moving?
R $BED6 IX the object
R $BED6 O:F Z set if its steps in U, V and Z (+$09 to +$0B) are all zero
D $BED6 As Knight Lore's is_obj_moving.

# --------------------------------------------------------------------------
# The extra life ($BEE0-$BF3C)
# --------------------------------------------------------------------------

@ $BEE0 label=EXTRA_LIFE
c $BEE0 The update routine for an extra life (graphic 12)
D $BEE0 Reached through #R$A7EA. A place given graphic 12 at a new game (#R$AF3F) is an extra life, put in one of the two place records as its room is built (#R$AE99). If the robot's legs touch it -- their box widened by 1 in U and V -- it becomes graphic 64, the first of a two-frame vanish (#R$B3A4, #R$B3B0), its place is emptied so it never comes back, the drop latch is cleared, and LIVES goes up by one, is reprinted on the panel and copied to the screen. Either way it then falls and settles like other things. As Knight Lore's upd_103, the extra life, but through the table of places rather than Knight Lore's special-object table.
R $BEE0 IX the extra life's record
  $BEE0,3 the drawing nudge: X -8, Y -2
  $BEE3,8 IY = the extra life; IX = the robot's legs
  $BEEB,21 touching, with the legs 1 wider in U and V? The legs back as they were, and IX back
  $BF00,7 graphic 64, the vanish, with its drawing nudge
  $BF07,8 its place emptied for good
  $BF0F,3 the things on the ceiling may drop again
  $BF12,4 one more life
  $BF16,12 beep, print the lives into the buffer and copy them to the screen, at pixel x 128, y 0 (#R$BF2F)
@ $BF22 label=EXTRA_LIFE_FALL
  $BF22,7 fall and move; not moving: done
  $BF29,6 moving: no step in U or V next turn; a sound and a redraw (#R$B3B0)

@ $BF2F label=BLIT_2X8
c $BF2F Copy a 16 by 8 pixel patch from the buffer to the screen
R $BF2F B the pixel row of its bottom, counted from the bottom of the screen
R $BF2F C the pixel column
D $BF2F Works out the screen address (#R$D135) and the buffer address (#R$D120) of the position, then copies 8 rows of 2 bytes (#R$CF85). Used for the lives (#R$BEE0) and the chambers activated (#R$AF79), which change without the whole screen being redrawn. As Knight Lore's blit_2x8.

# --------------------------------------------------------------------------
# Drawing nudges ($BF3D-$BF82)
# --------------------------------------------------------------------------

@ $BF3D label=DRAW_AT_L16_D9
@ $BF3D nowarn
c $BF3D Drawing nudge X -16, Y -9 (graphic 30)
D $BF3D A note for all the nudge routines from here to #R$BF7E: +$12 and +$13 of an object record are added to the pixel position the projection (#R$CFD2) works out from the object's U, V and Z, to line the sprite up with the object's position. X is pixels right and Y pixels up, so the usual negative values move the sprite left and down. For a still object that is all its update routine does; others call one to set the nudge before they move. They all end at SET_PIXEL_ADJ, in #R$BF74. Knight Lore calls these drawing offsets.
D $BF3D This one is the whole update routine for graphic 30 (#R$A7EA), the only piece of object template 1 and of backgrounds 12 and 13, and is called by the update routines of graphics 28, 44, 45, 47, 66, 68, 72, 75, 122 to 128 and 130.
  $BF3D,3 Left 16, down 9

@ $BF42 label=UNUSED_NUDGE_L12_D9
@ $BF42 nowarn
b $BF42 Unreached code: drawing nudge X -12, Y -9
D $BF42 A LD HL and a JR to SET_PIXEL_ADJ (#R$BF74) like the routines round it, which nothing calls, jumps to or lists in the update table (#R$A7EA); the code map leaves it as data.
B $BF42,5,3,2 LD HL: left 12, down 9; JR to SET_PIXEL_ADJ

@ $BF47 label=DRAW_AT_L12_D8
@ $BF47 nowarn
c $BF47 Drawing nudge X -12, Y -8
D $BF47 The robot appearing (#R$BC70, #R$BC83), and the things that drop from the ceiling (#R$AD13).
  $BF47,3 Left 12, down 8

@ $BF4C label=DRAW_AT_L16_D7
@ $BF4C nowarn
c $BF4C Drawing nudge X -16, Y -7
D $BF4C The robot's legs (#R$C0BE, #R$C1E2), and the sockets (#R$AE68).
  $BF4C,3 Left 16, down 7

@ $BF51 label=DRAW_AT_L12_D7
@ $BF51 nowarn
c $BF51 Drawing nudge X -12, Y -7 (graphic 13)
D $BF51 The whole update routine for graphic 13 (#R$A7EA), the longest of the thin pieces -- a half-size of 12 along, none across, 48 high -- that backgrounds 4 to 9 are built of.
  $BF51,3 Left 12, down 7

@ $BF56 label=DRAW_AT_L16_D6
@ $BF56 nowarn
c $BF56 Drawing nudge X -16, Y -6
D $BF56 Graphic 29 (#R$B31A).
  $BF56,3 Left 16, down 6

@ $BF5B label=DRAW_AT_L12_D6
@ $BF5B nowarn
c $BF5B Drawing nudge X -12, Y -6
D $BF5B The update routines of graphics 11, 86, 87, 94, 95 and 116 to 119 (#R$B055, #R$B110, #R$B06B, #R$AAA1).
  $BF5B,3 Left 12, down 6

@ $BF60 label=DRAW_AT_L12_D5
@ $BF60 nowarn
c $BF60 Drawing nudge X -12, Y -5
D $BF60 The valves (#R$AF79) and graphics 100 to 111 (#R$AE5D, #R$AE17, #R$AE33).
  $BF60,3 Left 12, down 5

@ $BF65 label=DRAW_AT_L8_D5
@ $BF65 nowarn
c $BF65 Drawing nudge X -8, Y -5 (graphic 15)
D $BF65 The whole update routine for graphic 15 (#R$A7EA), a short thin piece of backgrounds 8 and 9.
  $BF65,3 Left 8, down 5

@ $BF6A label=DRAW_AT_L12_D4
@ $BF6A nowarn
c $BF6A Drawing nudge X -12, Y -4
D $BF6A The sparkle (#R$B3A4, #R$B3B0), the vanishing extra life (#R$BEE0), and the update routines of graphics 46, 74, 76 to 79, 120, 121 and 129.
  $BF6A,3 Left 12, down 4

@ $BF6F label=DRAW_AT_L16_D3
@ $BF6F nowarn
c $BF6F Drawing nudge X -16, Y -3
D $BF6F The robot's top (#R$C6E4).
  $BF6F,3 Left 16, down 3

@ $BF74 label=DRAW_AT_L4_D3
@ $BF74 nowarn
c $BF74 Drawing nudge X -4, Y -3 (graphic 14)
D $BF74 The whole update routine for graphic 14 (#R$A7EA), the short thin piece at the end of a row of #R$BF51's in backgrounds 4, 5, 8 and 9.
  $BF74,3 Left 4, down 3
@ $BF77 label=SET_PIXEL_ADJ
  $BF77,7 The shared end of all the nudge routines: L to +$12, H to +$13

@ $BF7E label=DRAW_AT_L8_D2
@ $BF7E nowarn
c $BF7E Drawing nudge X -8, Y -2
D $BF7E The extra life (#R$BEE0).
  $BF7E,3 Left 8, down 2

# --------------------------------------------------------------------------
# Filling a box ($BF83-$BFAA)
# --------------------------------------------------------------------------

@ $BF83 label=FILL_BOX
c $BF83 Fill a box of bytes, B wide and C rows high, with A
R $BF83 HL the first byte: the box's bottom-left in the buffer, or its top-left in the attribute file
R $BF83 A the byte to fill with
R $BF83 B the width in bytes, 1 to 8
R $BF83 C how many rows
D $BF83 Fills B bytes along from HL, then moves 32 bytes on to the next row, C times: in the buffer that is up the screen, in the attribute file down. The row is eight unrolled stores (#R$BF97), and the routine rewrites the displacement of the JR at FILL_BOX_ROW so that it lands on the last B of them -- on the tape the JR jumps to itself, and it is always rewritten before it runs. Used to clear the carried things' boxes and colour them (#R$BC9D), for the panel (#R$A749) and by #R$CEAB.
  $BF83,10 the displacement: twice (8 - B) modulo 8, into the JR's second byte
  $BF8D,6 DE = 32 - B, from the end of one row to the start of the next
  $BF93,2 B = the rows
@ $BF95 label=FILL_BOX_ROW
  $BF95,2 into the stores, B from the end (rewritten above)

@ $BF97 label=FILL_BOX_STORES
c $BF97 The eight stores of #R$BF83
D $BF97 Entered only by the JR at the end of #R$BF83, part way down, so that the last B stores run. The DJNZ goes back to that JR for the next row.
  $BF97,16 eight stores, each one byte on
  $BFA7,4 on to the next row; C rows in all

# --------------------------------------------------------------------------
# Redrawing and moving ($BFAB-$BFD7)
# --------------------------------------------------------------------------

@ $BFAB label=SET_WIPE_AND_DRAW_FLAGS
c $BFAB Mark an object to be rubbed out and redrawn
R $BFAB IX the object
D $BFAB Sets bits 4 and 5 of +7 -- draw it, and rub out where it was -- and marks every object its old or new rectangle touches (#R$C657). The end of most update routines that move or change their object. As Knight Lore's set_wipe_and_draw_flags; #R$ADF3 does the same for the record at IY.

@ $BFB6 label=DEC_DZ_AND_UPDATE_UVZ
c $BFB6 Fall, and move
R $BFB6 IX the object
D $BFB6 Takes one off the step in Z -- the pull of gravity -- then lets #R$C442 cut the steps down to what fits, and adds what is left to the position. The player's move (#R$C296) comes in at ADD_DUVZ, having cut the move itself. As Pentagram's DEC_DZ_AND_UPDATE_UVZ; Knight Lore's add_dXYZ.
  $BFB6,3 gravity
  $BFB9,3 cut the move short where it has to be
@ $BFBC label=ADD_DUVZ
  $BFBC,28 U, V and Z (+$01 to +$03) plus the step in each (+$09 to +$0B)

# --------------------------------------------------------------------------
# The doorways' pillars ($BFD8-$C116)
# --------------------------------------------------------------------------

@ $BFD8 label=SECOND_PILLAR
c $BFD8 The update routine for the second pillar of a doorway (graphic 3)
D $BFD8 Reached through #R$A7EA. A doorway is two pillars, graphics 2 and 3, from one background (#R$7519: backgrounds 0 to 3, 10 and 11), and this one only sets its drawing nudge: the first pillar (#R$BFEA) does the work. A doorway in a wall of constant V is mirrored (bit 6 of its flags); one in a wall of constant U is not. As Knight Lore's upd_3_5 and Pentagram's SECOND_PILLAR.
R $BFD8 IX the pillar's record
  $BFD8,6 Mirrored?
@ $BFDE nowarn
  $BFDE,6 Not mirrored: X -16, Y -5
@ $BFE4 label=SECOND_PILLAR_MIRRORED
@ $BFE4 nowarn
  $BFE4,6 Mirrored: X -8, Y -4

@ $BFEA label=FIRST_PILLAR
c $BFEA The update routine for the first pillar of a doorway (graphic 2)
D $BFEA Reached through #R$A7EA. This pillar is the doorway. It works out the point in the middle of the doorway, 13 from itself along the wall, and keeps it in its own +$09 to +$0B -- the step fields, which a pillar never needs, borrowed because #R$C099 compares +$09 to +$0B of one record with +$01 to +$03 of another. Then #R$C082 marks the robot's legs as in the doorway if they are near enough, which lets them past the line of the wall (#R$C36D), and ARCH_NUDGE_TO_CENTRE nudges him onto the doorway's middle line if he is near it and facing through.
D $BFEA A doorway in a wall of constant U (not mirrored) has its other pillar 13 further along V, and reaches 15 either way in U and 6 in V; one in a wall of constant V (mirrored) has its other pillar 13 back along U, and reaches 6 in U and 15 in V. The backgrounds put the middle of every doorway at 128 along its wall.
D $BFEA As Knight Lore's adj_2_4_hflip and the routines after it, and Pentagram's FIRST_PILLAR. The nudge differs from both: see #R$C050.
R $BFEA IX the pillar's record
  $BFEA,6 Mirrored: a doorway in a wall of constant V
@ $BFF0 nowarn
  $BFF0,6 Not mirrored: X -6, Y -7
  $BFF6,8 V of the middle: this pillar's plus 13
  $BFFE,6 U of the middle: this pillar's
  $C004,3 In the doorway: U within 15, V within 6
@ $C007 label=ARCH_CHECK_DOORWAY
  $C007,6 Z of the middle: the pillar's base
  $C00D,3 In the doorway: the legs may cross the line of the wall
  $C010,3 Near it: nudge towards the middle
@ $C013 label=ARCH_ALONG_V
@ $C013 nowarn
  $C013,6 Mirrored: X -10, Y -6
  $C019,8 U of the middle: this pillar's less 13
  $C021,6 V of the middle: this pillar's
  $C027,5 In the doorway: U within 6, V within 15
@ $C02C label=ARCH_NUDGE_TO_CENTRE
N $C02C Nudge the robot towards the middle line of the doorway: if his legs, record 0, are in use, use doorways (bit 3 of +7), and are within 15 of the middle in U and V and 4 in Z, one of the routines in #R$C048 is run, picked by the pillar's own facing (#R$C319). Knight Lore does this for each of records 0 to 3; here only the legs are nudged, as in Pentagram.
  $C02C,3 15 either way in U and V
  $C02F,9 the robot's legs, if there are any
  $C038,5 not one that uses doorways
  $C03D,4 not near
  $C041,7 the nudge routine for the pillar's facing; the BC pushed here is taken off again at NUDGE_DONE

@ $C048 label=NUDGE_ROUTINES
b $C048 The doorway's nudge routines, by the pillar's facing
D $C048 Four words indexed by the first pillar's facing (#R$C319, used by #R$BFEA): 0 and 1 not mirrored, 2 and 3 mirrored. A pillar is graphic 2, whose bit 2 is clear, so only entries 0 and 2 are ever used; 1 and 3 repeat them.
W $C048,8,2 Facings 0 and 1, not mirrored: #R$C050, along V; 2 and 3, mirrored: #R$C069, along U

@ $C050 label=NUDGE_ALONG_V
c $C050 Nudge along V
D $C050 For a doorway in a wall of constant U: nothing if the robot faces along V (his legs mirrored) or is on the middle line already, otherwise +1 or -1 into +$0F of his legs, towards it, which the walk (#R$C2F6) adds to his step in V when he next walks. This is why he slides into line with a doorway as he walks through.
D $C050 Only while he faces through the doorway: Knight Lore (adj_ew) and Pentagram (NUDGE_ALONG_V) nudge whichever way he faces.
R $C050 IX the pillar, holding the middle at +$09 to +$0B
R $C050 IY the robot's legs
  $C050,6 facing along V: no nudge
  $C056,8 on the middle line already
  $C05E,6 +1 if the middle is at a greater V, else -1
  $C064,5 the V nudge

@ $C069 label=NUDGE_ALONG_U
c $C069 Nudge along U
D $C069 For a doorway in a wall of constant V: +1 or -1 into +$0E of his legs, towards the middle line, while he faces along V (his legs mirrored) and is not on it.
R $C069 IX the pillar, holding the middle at +$09 to +$0B
R $C069 IY the robot's legs
  $C069,6 facing along U: no nudge
  $C06F,8 on the middle line already
  $C077,6 +1 if the middle is at a greater U, else -1
  $C07D,3 the U nudge
@ $C080 label=NUDGE_DONE
  $C080,2 drop the BC #R$BFEA pushed, and back to the main loop

@ $C082 label=CHK_PLYR_NEAR_ARCH
c $C082 Is the robot in the doorway?
R $C082 IX the first pillar, holding the middle at +$09 to +$0B
R $C082 L how near in U
R $C082 H how near in V
D $C082 If the robot's legs, record 0, are in use, use doorways (bit 3 of +7) and are within the doorway's limits (#R$C099), sets bit 0 of their flags: while it is set the collision code lets him past the line of the wall, and his move (#R$C36D) sees whether he has walked out of the room, and clears it. Knight Lore's chk_plyr_spec_near_arch, which looks at records 0 to 3.
  $C082,9 the robot's legs, if there are any
  $C08B,5 not one that uses doorways
  $C090,4 not in the doorway
  $C094,5 in it: he may cross the line of the wall

@ $C099 label=IS_NEAR_TO
c $C099 Is an object near a point?
R $C099 IX a record whose +$09 to +$0B hold the point's U, V and Z
R $C099 IY the object
R $C099 L the limit in U
R $C099 H the limit in V
R $C099 O:F carry set if near
D $C099 Carry set if the object's U, V and Z are all within the limits of the point: strictly less than L in U, H in V and 4 in Z. As Knight Lore's is_near_to.
  $C099,12 U
  $C0A5,12 V
  $C0B1,13 Z: within 4 sets the carry

# --------------------------------------------------------------------------
# The robot's legs ($C0BE-$C1D1)
# --------------------------------------------------------------------------

@ $C0BE label=PLAYER_LEGS
c $C0BE The update routine for the robot's legs (graphics 16 to 23)
R $C0BE IX the legs' record, #R$5B88
D $C0BE Reached through #R$A7EA. The robot's turn, in order: read the controls (#R$C8FF), pick up or put down (#R$BD6B), turn (#R$C13C), start a jump (#R$C23D), step the legs' frame (#R$C25E). Then, if he stands in a doorway -- past the line of the room's walls (#R$C117) -- he may not rise, only fall. The move is resolved and made (#R$C296) with the top out of the collision tests; the count of turns he walks on by himself after coming through a doorway goes down, and he is marked to be redrawn.
D $C0BE While this runs the legs' height is 23, the whole robot's, and the top's is 0, so that the legs stand for the robot in the headroom test and in the move; at the end they are put back to 12 and 11, the top standing on the legs. The top's height of 0 is what keeps the headroom test from finding the top itself: #R$B712 takes only the legs out of its own way, and its test in Z (#R$C5D3) never finds an overlap with a thing of no height whose base is at or below the legs'. For the move the top is taken out of the collision tests as well (bit 1 of its +7).
D $C0BE If he has been killed (bit 6 of +$0D), the top is killed too and the legs become the sparkle (#R$B39A). Graphics 24 to 27, the legs part way through a turn, have their own update routine (#R$C1E2), which comes back in at PLAYER_LEGS_DONE.
D $C0BE As Pentagram's PLAYER_LEGS and Knight Lore's player_controls, in a different order: pick-up comes before the turn here.
  $C0BE,3 the legs' drawing nudge: X -16, Y -7
  $C0C1,13 killed: the top too (+$0D of the next record), and the sparkle
  $C0CE,8 the legs as high as the whole robot, the top of no height
  $C0D6,15 the controls into C; pick up or put down, turn, jump, step
  $C0E5,5 in a doorway, beyond the walls?
@ $C0EA label=PLAYER_LEGS_MOVE
  $C0EA,11 the top (+7 of the next record) out of the collision tests while the legs move
  $C0F5,10 count down the top four bits of +$0C: the turns he walks on by himself after coming through a doorway
@ $C0FF label=PLAYER_LEGS_DONE
  $C0FF,8 the heights back: legs 12, top 11
  $C107,3 mark him to be redrawn
@ $C10A label=PLAYER_LEGS_IN_DOORWAY
  $C10A,7 in a doorway: falling is allowed...
  $C111,6 ...rising is not

@ $C117 label=CHK_PLYR_OOB
c $C117 Is he inside the room's walls?
R $C117 IX the object, the robot's legs
R $C117 O:F carry set if it is
D $C117 Compares the object's distance from the room's centre, 128 on U and V, with the room's half-size in each (ROOM_HALF_U, ROOM_HALF_V) less its own half-size. Carry means the whole of its footprint is inside on both; no carry, that it touches or crosses the line of a wall, which only a doorway allows. As Knight Lore's chk_plyr_OOB.
  $C117,13 L = the room's half-size in U less his; H = the same for V
  $C124,12 |U - 128|: no carry, outside
  $C130,12 |V - 128|

@ $C13C label=HANDLE_LEFT_RIGHT
c $C13C Turn the robot
R $C13C IX the robot's legs
R $C13C C the controls (INPUT): bits 0 and 1 turn, 2 walk, 3 jump, 4 pick up
R $C13C O:C bit 2 set if he is to walk
D $C13C Two ways of steering. Rotational control -- the keyboard's always, and a joystick's unless directional control is chosen -- turns a quarter at a time on the two turn controls: bit 0 of C left, bit 1 right. Directional control, a joystick with bit 3 of CONTROL set (key 5 on the menu), treats the controls as four points of the compass instead: pushing one turns the robot towards it and, once he faces it, walks him that way.
D $C13C Facings, as #R$C319 gives them: bit 2 of the graphic and bit 6 of the flags, the mirror bit, make a number 0 to 3 (the mirror bit the high bit); a left turn goes 0, 3, 1, 2 and round, a right turn the other way. Directional control reads up (bit 2) -- which faces 2 -- unless left is also held, then right (1), down (bit 4; 3) and left (0), and goes the short way round, or two turns for an about-face.
D $C13C A turn is not made at once, as in Knight Lore and Pentagram. The legs become one of four part-way graphics, 24 to 27, from #R$C1D2 for a right turn or #R$C1DA for a left one, by the facing; bit 0 of +$0D records which way, and bits 1-2 a count of one. Their update routine (#R$C1E2) holds that frame for two turns and then puts in the new facing's standing graphic (17 or 21, with its mirror bit), so a quarter turn takes three turns (measured: holding a turn key, the legs' graphic at the end of each turn went 26, 26, then 17 mirrored, and so on round). The top follows the legs' graphic, 16 higher (#R$C6E4). No turn is started during the walk into a room, or in a jump; directional control also waits until he stands on something.
  $C13C,8 bits 1-2 of CONTROL: 0, the keyboard, always turns rotationally
  $C144,4 directional control not chosen
  $C148,6 directional: nothing during the walk into a room (the count in bits 4-7 of +$0C)...
  $C14E,5 ...nor in the air: bit 2 of +$0C, standing on something
  $C153,8 left held: skip up; up held: face 2
@ $C15B label=DIRECTIONAL_NOT_UP
  $C15B,12 right: face 1; down: face 3; left: face 0
  $C167,3 nothing pushed: no walking
@ $C16A label=DIRECTIONAL_UP
  $C16A,5 up: facing 2 already?
  $C16F,3 yes: walk; otherwise invert the facing, so that its bit 0 set means a right turn is the short way
@ $C172 label=TURN_BY_PARITY
  $C172,4 the facing's bit 0 picks the turn
@ $C176 label=DIRECTIONAL_RIGHT
  $C176,7 right: facing 1 already? The same test as up
@ $C17D label=DIRECTIONAL_DOWN
  $C17D,9 down: facing 3 already? Walk if so; otherwise the facing's own bit 0 picks the turn
@ $C186 label=DIRECTIONAL_LEFT
  $C186,6 left: facing 0 already? The same test as down
@ $C18C label=FACING_THAT_WAY
  $C18C,3 facing the way pushed: walk
@ $C18F label=ROTATIONAL_TURN
  $C18F,4 rotational: neither turn control held
  $C193,6 not during the walk into a room
  $C199,5 not in the middle of a jump
  $C19E,2 bit 1: right
  $C1A0,2 NZ for a right turn, Z for a left
@ $C1A2 label=START_TURN_LEFT
  $C1A2,9 left: bit 0 of +$0D clear, and the left turn's part-way graphics
@ $C1AB label=START_TURN_RIGHT
  $C1AB,7 right: bit 0 of +$0D set, and the right turn's
@ $C1B2 label=START_TURN
  $C1B2,8 a count of one in bits 1-2 of +$0D, for #R$C1E2
  $C1BA,3 A = the facing
@ $C1BD label=SET_TURN_GRAPHIC
N $C1BD Set the graphic and the mirror bit from the pair A selects in the table at HL, A taken modulo 4. Also used by #R$C1E2, with the part-way graphic as A.
  $C1BD,6 HL = the pair: A times 2
  $C1C3,5 the graphic
  $C1C8,10 the mirror bit (bit 6 of +7) from the pair's second byte


# --------------------------------------------------------------------------
# Range 4
# --------------------------------------------------------------------------

# --------------------------------------------------------------------------
# Range 4 ($C1D2-$CB05): the robot's turning, jumping, stepping and moving,
# leaving a room, the per-axis collision, the screen rectangle and the
# redraw marks, the robot's top, the draw list and the depth sort, reading
# the controls, a new life, the start records and rooms, entering a room.
# --------------------------------------------------------------------------

@ $C1D2 label=TURN_RIGHT_VIEWS
b $C1D2 The in-between views of a right turn
D $C1D2 Read by #R$C13C as a quarter turn to the right starts: indexed by the facing, two bytes each, the graphic the legs take for the turn and the mirror bit (bit 6 of the flags). Graphics 24-27 are the views between the diagonal ones the robot walks in: the facing either side of each says which -- 24 from behind, 25 from the front, 26 side-on facing right, and 27, 26's drawing, used mirrored for facing left. The left turn's four follow at #R$C1DA; #R$C1E2 ends the turn from #R$C22D.
B $C1D2,2 Facing 0 (lower U) to 2: graphic 24, from behind
B $C1D4,2 Facing 1 (higher U) to 3: graphic 25, from the front
B $C1D6,2 Facing 2 (higher V) to 1: graphic 26, side-on
B $C1D8,2 Facing 3 (lower V) to 0: graphic 27, mirrored

@ $C1DA label=TURN_LEFT_VIEWS
b $C1DA The in-between views of a left turn
D $C1DA As #R$C1D2, for a quarter turn to the left (#R$C13C); #R$C1E2 ends it from #R$C235.
B $C1DA,2 Facing 0 (lower U) to 3: graphic 27, mirrored
B $C1DC,2 Facing 1 (higher U) to 2: graphic 26
B $C1DE,2 Facing 2 (higher V) to 0: graphic 24, from behind
B $C1E0,2 Facing 3 (lower V) to 1: graphic 25, from the front

@ $C1E2 label=TURNING_LEGS
c $C1E2 The robot's legs while he turns (graphics 24 to 27)
D $C1E2 The update routine (#R$A7EA) of the in-between views a quarter turn passes through. #R$C13C starts a turn by giving the legs one of them (#R$C1D2, #R$C1DA) and a count of one in bits 1-2 of +$0D, with bit 0 set for a right turn. While the count runs this routine only lets the robot fall; once it has run out it gives the legs the standing graphic of the new facing (#R$C22D, #R$C235), with a sound. So the in-between view is on the screen for two turns, and a walking robot stands still for three: the turn a turn starts (#R$C296 takes no step with an in-between graphic), and these two (measured in the simulator: a left turn from facing 1 showed graphic 26 for two turns and then 17 mirrored, facing 2; with walk held through a right turn U did not change until the turn after the new facing).
D $C1E2 Like the legs' own routine (#R$C0BE) it reads the controls, gives the legs the whole robot's height, 23, and the top none while he moves, keeps the top out of the collision scans meanwhile, and ends in that routine's tail: heights 12 and 11, and a redraw. Unlike it, it does not look at the killed bit of +$0D, nor count down the walk into a room.
D $C1E2 The finishing branch means to take a step if walk is held: it comes into #R$C296 at MOVE_IF_WALKING, which tests bit 2 of C. But the sound it makes first (#R$B6CE, at the entry that skips the frame test) counts C down to zero, so the step is never taken and gravity takes its full two units whatever is held. #R$C25E keeps BC around the same sound.
R $C1E2 IX the legs' record
  $C1E2,3 Drawn 16 left and 7 down
  $C1E5,8 While he moves, the legs' box is the whole robot's, 23 high, and the top has no height
  $C1ED,3 C = the controls
  $C1F0,7 The turn's count, bits 1-2 of +$0D, still running?
  $C1F7,8 Count it down
  $C1FF,9 The top out of the scans; fall, without a step
  $C208,9 Bit 0: a right turn ends from #R$C22D...
  $C211,6 ...the standing graphic and mirror bit of the new facing, by the in-between graphic's low two bits
  $C217,3 The turn's sound; it leaves C at zero
  $C21A,7 The top out of the scans; a step if walk is held (never, C being zero), then fall
  $C221,7 The top back in the scans; heights 12 and 11 and the redraw, in the tail of #R$C0BE
  $C228,5 A left turn ends from #R$C235

@ $C22D label=TURN_RIGHT_ENDS
b $C22D The facings a right turn ends in
D $C22D Read by #R$C1E2 when the in-between view of a right turn has been shown: indexed by the in-between graphic's low two bits, the graphic and mirror bit of the new facing. Graphics 17 and 21 are the legs standing (frame 1) in the two views bit 2 of the graphic chooses; the mirror bit makes the other two facings. The left turn's four follow at #R$C235.
B $C22D,2 After graphic 24: 17 mirrored, facing 2 (higher V)
B $C22F,2 After 25: 21 mirrored, facing 3 (lower V)
B $C231,2 After 26: 21, facing 1 (higher U)
B $C233,2 After 27: 17, facing 0 (lower U)

@ $C235 label=TURN_LEFT_ENDS
b $C235 The facings a left turn ends in
D $C235 As #R$C22D, for a left turn (#R$C1E2).
B $C235,2 After graphic 24: 17, facing 0 (lower U)
B $C237,2 After 25: 21, facing 1 (higher U)
B $C239,2 After 26: 17 mirrored, facing 2 (higher V)
B $C23B,2 After 27: 21 mirrored, facing 3 (lower V)

@ $C23D label=HANDLE_JUMP
c $C23D Start a jump
D $C23D Called by the legs (#R$C0BE) every turn. A jump needs the jump control held, the walk into a room over (the count in bits 4-7 of +$0C), no jump already under way (bit 3 of +$0C, cleared on landing by #R$C296), and the robot not falling: a Z step of -2 or less says he is. That is Knight Lore's test, on the speed; Pentagram tests bit 2 of +$0C, standing, instead. The jump starts at 8 units up a turn, with a rising sound (#R$B62C); gravity in #R$C296 takes it away again.
R $C23D IX the legs' record
R $C23D C the controls
  $C23D,3 Jump not held
  $C240,6 Not during the walk into a room
  $C246,5 Already jumping
  $C24B,5 A Z step of -2 or less: falling
  $C250,8 Jumping, 8 up
  $C258,6 The jump's sound, the controls kept

@ $C25E label=HANDLE_FORWARD
c $C25E Step the legs
D $C25E The legs' graphics 16-23 are two views (bit 2) of four frames (bits 0-1): a stride, legs together, the other stride, together again -- frames 1 and 3 share a drawing (#R$7827). While the robot walks, jumps or walks into a room the legs step on through the four, with a sound (#R$B6CE) on leaving a stride, frames 0 and 2. Otherwise they carry on, silently, to frame 1 and stop there. Nothing happens on the turn a turn starts: #R$C13C, called just before, has given the legs an in-between view, 24-27.
D $C25E Pentagram's is the same with frame 2 the standing pose and a footstep every fourth frame; Knight Lore's walk has six frames.
R $C25E IX the legs' record
R $C25E C the controls
  $C25E,8 Graphics 24-27: a turn has just started
  $C266,7 Walking into a room: step
  $C26D,6 Jumping: step
  $C273,4 Walk not held: on to the standing frame
  $C277,5 The step's sound, on frames 0 and 2 only; the controls kept
  $C27C,16 The next frame of four, in the graphic's low two bits
  $C28C,8 Frame 1, legs together: stand
  $C294,2 Otherwise step on towards it, silently

@ $C296 label=MOVE_PLAYER
c $C296 Move the robot
D $C296 Called by the legs (#R$C0BE) every turn, with the top kept out of the collision scans. He steps forward -- 3 units the way he faces, plus any nudge a doorway has left (#R$C2F6) -- while jumping, during the walk into a room, or when walk is held; but not on the turn a turn starts, when the legs have an in-between graphic (bit 3 set: 24-27). Then gravity: 2 off the Z step every turn, or 1 while he is still rising (or level) with jump held, so that holding jump jumps higher. The Z step is copied to PLAYER_DZ, a fall faster than 2 a turn makes a sound pitched by the height (#R$B63C), and #R$C442 cuts the move short against the floor, the walls and the other objects. #R$C36D takes him out of the room if the move carries him through a doorway, and does not come back; otherwise the move is made (the second half of #R$BFB6). A move down that was stopped (bit 2 of +$0C) is a landing, and ends the jump. The U and V steps are then cleared; the Z step carries over as his speed.
D $C296 While the scene after a game runs (GAME_OVER) the Z step is set to 2 every turn, which gravity brings back to 0: the robot hangs where he is. Knight Lore does the same while something floats into its cauldron.
D $C296 This is Knight Lore's routine, the falling sound and the exit check included; Pentagram keeps neither. The turning legs (#R$C1E2) come in at MOVE_IF_WALKING and APPLY_GRAVITY, and #R$AF79, #R$B2FF and #R$BEE0 end their own updates at CLEAR_DUV.
R $C296 IX the legs' record
R $C296 C the controls
  $C296,10 The scene after a game: a Z step of 2, to hang still
  $C2A0,6 Jumping: forward
  $C2A6,7 Walking into a room: forward
  $C2AD,6 An in-between graphic: a turn has just started, so no step
@ $C2B3 label=MOVE_IF_WALKING
  $C2B3,4 Walk not held: no step
  $C2B7,5 A step forward, the controls kept
@ $C2BC label=APPLY_GRAVITY
  $C2BC,7 The Z step negative: falling, two off
  $C2C3,4 Rising or level with jump held: one off
  $C2C7,2 Gravity: two off, or one
  $C2C9,6 The new Z step, and a copy that says afterwards which way he was going
  $C2CF,5 Falling faster than 2: the falling sound, pitched by Z
  $C2D4,3 Cut the move short where it must be
  $C2D7,3 Through a doorway: into the next room, and no return
  $C2DA,3 U, V and Z plus the steps
  $C2DD,13 Stopped while moving down?
  $C2EA,4 Then landed: the jump is over
@ $C2EE label=CLEAR_DUV
  $C2EE,8 The U and V steps are one turn's; the Z step carries over as the speed

@ $C2F6 label=CALC_PLYR_DUV
c $C2F6 Add a step in the direction he faces
D $C2F6 First adds the nudge in +$0E and +$0F, which a doorway leaves to steer the robot onto its middle line (#R$C050, #R$C069), to the U and V steps, and clears it; then adds 3 in the direction he faces, through #R$C32F. So the nudge acts only while he walks.
D $C2F6 DISPATCH_ON_FACING, the last three instructions, jumps through a table of four addresses at BC by the facing of the object at IX (#R$C319), using the main loop's jump through the update table (in #R$A647). The exit check (#R$C36D) and a doorway's first pillar (#R$BFEA) use it too.
R $C2F6 IX the legs' record
  $C2F6,18 The U and V steps plus the nudge
  $C308,7 The nudge is used up
  $C30F,3 The table of steps
@ $C312 label=DISPATCH_ON_FACING
  $C312,7 Jump to the table's entry for the facing

@ $C319 label=GET_SPRITE_DIR
c $C319 Which way an object faces
D $C319 The facing, 0 to 3, from the two bits that store it: bit 6 of the flags (the sprite mirrored) gives 2, and bit 2 of the graphic adds 1. By the steps each facing is given (#R$C32F), 0 faces lower U, 1 higher U, 2 higher V and 3 lower V. Knight Lore's is the same with bit 3 of the graphic; Pentagram's counts 2 for a sprite not mirrored.
R $C319 IX the object
R $C319 O:A the facing
  $C319,10 L = 8 if the sprite is mirrored
  $C323,6 With the graphic's bit 2
  $C329,6 Down to bits 1 and 0; HL kept

@ $C32F label=WALK_STEP_TBL
b $C32F A step in each direction
D $C32F Four routine addresses, one per facing, used through DISPATCH_ON_FACING by #R$C2F6. Each adds 3 to, or takes 3 from, the U or V step.
W $C32F,8,2 Facing 0: U - 3 (#R$C337); 1: U + 3 (#R$C340); 2: V + 3 (#R$C347); 3: V - 3 (#R$C350)

@ $C337 label=STEP_U_DOWN
c $C337 Step towards lower U
D $C337 The U step less 3, for facing 0.
R $C337 IX the legs' record
  $C337,5 -3
@ $C33C label=STORE_PLYR_DU
  $C33C,4 Store the U step (#R$C340 ends here too)

@ $C340 label=STEP_U_UP
c $C340 Step towards higher U
D $C340 The U step plus 3, for facing 1.
R $C340 IX the legs' record
  $C340,7 +3, and store it

@ $C347 label=STEP_V_UP
c $C347 Step towards higher V
D $C347 The V step plus 3, for facing 2.
R $C347 IX the legs' record
  $C347,5 +3
@ $C34C label=STORE_PLYR_DV
  $C34C,4 Store the V step (#R$C350 ends here too)

@ $C350 label=STEP_V_DOWN
c $C350 Step towards lower V
D $C350 The V step less 3, for facing 3.
R $C350 IX the legs' record
  $C350,7 -3, and store it

@ $C357 label=ADJ_DZ_FOR_OUT_OF_BOUNDS
c $C357 Shorten dZ at the floor
D $C357 The floor is the only limit on Z: there is no ceiling. FLOOR is 64 in all three room sizes (#R$6460). A move that would take the object's base below it is shortened a unit at a time until it would not, and bit 2 of +$0C records that the move was stopped. Called by #R$C442 before the other objects are tried.
R $C357 IX the object
R $C357 H dZ
R $C357 O:H dZ, shortened
  $C357,4 D = the floor
@ $C35B label=CLIP_DZ_TO_FLOOR
  $C35B,6 Z + dZ at or above the floor: done
  $C361,4 Stopped in Z
  $C365,8 A unit shorter, and again unless nothing is left

@ $C36D label=HANDLE_EXIT_SCREEN
c $C36D Has the robot walked out of the room?
D $C36D Called by #R$C296 once the move has been cut short and before it is made. A room is left only through a doorway, and only walking the way the robot faces: a doorway's first pillar sets bit 0 of the legs' flags while he is in it (#R$C082), which also lets him past the line of the wall (#R$C5E9, #R$C613). This clears the bit -- it is used once, and the pillar sets it again on its next update if he is still there -- and jumps through #R$C38F by the facing; each of the four decides whether this turn's move takes him wholly past the wall he faces.
D $C36D Knight Lore's, instruction for instruction. The room's half-sizes are pushed for the four, because the dispatch uses HL.
R $C36D IX the legs' record
  $C36D,6 Not during the walk into a room
  $C373,5 Not in a doorway
  $C378,4 The flag is used once
  $C37C,10 The four exits, the room's half-sizes pushed for them, and the jump by facing

@ $C386 label=SHORTEN_DELTA
c $C386 Shorten a move by one unit
D $C386 Moves A one step towards zero -- down if positive, up if negative -- and leaves Z set if nothing is left. Every loop in the collision code uses it to cut a move short a unit at a time and try again.
R $C386 A a dU, dV or dZ
R $C386 O:A one unit closer to zero; Z set if zero
  $C386,2 Already zero
  $C388,5 Negative: +2 here and -1 below
@ $C38D label=SHORTEN_DELTA_DEC
  $C38D,2 The step down that sets Z

@ $C38F label=SCREEN_MOVE_TBL
b $C38F Leaving a room, by facing
D $C38F Four routine addresses in facing order, used through DISPATCH_ON_FACING by #R$C36D.
W $C38F,8,2 Facing 0: out at low U? (#R$C397); 1: at high U? (#R$C3F0); 2: at high V? (#R$C40B); 3: at low V? (#R$C426)

@ $C397 label=EXIT_LOW_U
c $C397 Out through the wall at low U?
D $C397 Out if the robot's far edge after this turn's move -- U plus the step plus his half-size -- is below the wall at 128 less the room's U half-size. U is then set to 0: not a position but a marker, which #R$CC01 sees when the next room is built and puts him in the doorway of its wall at high U. The other exits use $FF and 0 the same way. The new room is the one before in the same row: room numbers are a row in the high four bits and a column in the low four, and the column is changed on its own so that it wraps within the row.
D $C397 EXIT_SCREEN is the way on for all four. It gives the legs the new room and starts the walk into it: 4 in bits 4-7 of +$0C, four turns of walking straight on with the controls and the walls ignored (Knight Lore's is three). For anything but the robot -- graphics 16 to 79 -- it returns, but only he gets here. For him the rest of the turn is abandoned: the returns into #R$C296 and to the legs' update are dropped, and both his records are copied to the start records (#R$CA1D), so that a life lost in the new room starts again at this doorway. In the copies the graphic is moved to +$10 and replaced by 56, the first of the appearing robot's (#R$BC70). Then the new room is built and the main loop starts over (#R$A647).
R $C397 IX the legs' record
R $C397 HL the room's half-sizes (pushed by #R$C36D)
  $C397,5 L = the wall
  $C39C,11 U + dU + half-size still at or beyond it: stay
  $C3A7,4 Arrive at the wall at high U
  $C3AB,5 Room - 1...
@ $C3B0 label=EXIT_WITHIN_ROW
  $C3B0,7 ...the new column with the old row
@ $C3B7 label=EXIT_SCREEN
  $C3B7,3 The new room
  $C3BA,8 The walk into the room: four turns
  $C3C2,8 Anything but the robot: carry on
  $C3CA,4 Drop the returns into #R$C296 and to the legs' update
  $C3CE,11 Both his records to the start records
  $C3D9,12 Each copy's graphic kept in its +$10...
  $C3E5,8 ...and replaced by the appearing robot's first
  $C3ED,3 Build the new room and start its turns

@ $C3F0 label=EXIT_HIGH_U
c $C3F0 Out through the wall at high U?
D $C3F0 As #R$C397 the other way: out if the near edge after the move -- U plus the step less the half-size -- is at or past the wall at 128 plus the room's U half-size. U becomes the marker $FF, to arrive at the wall at low U, and the room is the next in the row.
R $C3F0 IX the legs' record
R $C3F0 HL the room's half-sizes (pushed by #R$C36D)
  $C3F0,5 L = the wall
  $C3F5,11 U + dU - half-size short of it: stay
  $C400,4 Arrive at the wall at low U
  $C404,7 Room + 1, within the row

@ $C40B label=EXIT_HIGH_V
c $C40B Out through the wall at high V?
D $C40B Out if the near edge in V after the move is at or past the wall at 128 plus the room's V half-size. V becomes the marker $FF, to arrive at the wall at low V, and the room is the one 16 on: the next row, wrapping from the last row to the first.
R $C40B IX the legs' record
R $C40B HL the room's half-sizes (pushed by #R$C36D)
  $C40B,5 H = the wall
  $C410,11 V + dV - half-size short of it: stay
  $C41B,4 Arrive at the wall at low V
  $C41F,7 Room + 16

@ $C426 label=EXIT_LOW_V
c $C426 Out through the wall at low V?
D $C426 Out if the far edge in V after the move is below the wall at 128 less the room's V half-size. V becomes the marker 0, to arrive at the wall at high V, and the room is the one 16 back: the row before.
R $C426 IX the legs' record
R $C426 HL the room's half-sizes (pushed by #R$C36D)
  $C426,5 H = the wall
  $C42B,11 V + dV + half-size still at or beyond it: stay
  $C436,4 Arrive at the wall at high V
  $C43A,8 Room - 16

@ $C442 label=ADJ_FOR_OUT_OF_BOUNDS
c $C442 Cut a move short against the room and the other objects
D $C442 Every moving object's move comes through here: the robot's from #R$C296, everything else's from #R$BFB6. It takes the steps in U, V and Z (+$09 to +$0B) and shortens each where the object would otherwise end up below the floor, through a wall, or inside another object, then writes them back. The code is Knight Lore's and Pentagram's.
D $C442 The axes are done one at a time, Z first, then U, then V, and each test counts the moves already accepted on the earlier axes and the later ones as zero. That is what lets a blocked move slide: walking diagonally into a wall keeps the part of the move that runs along it.
D $C442 While it works, bit 1 of +$07 is set, which makes the object scans (#R$B74D) pass over the object itself; found already set, it returns at once. Bits 0-2 of +$0C are cleared at the start and set for each axis whose move was cut.
R $C442 IX the object
  $C442,9 Not while already set; and ignore ourself while we work
  $C44B,8 Clear the three "stopped" bits
  $C453,3 dV and dU count as zero while Z is tested
  $C456,7 H = dZ; nothing to do if zero
  $C45D,7 The floor first; nothing left means no objects to test
  $C464,3 Then the other objects
  $C467,7 C = dU; nothing to do if zero
  $C46E,7 The walls first; nothing left means no objects to test
  $C475,3 Then the other objects
  $C478,7 L = dV; nothing to do if zero
  $C47F,7 The walls first; nothing left means no objects to test
  $C486,3 Then the other objects
  $C489,9 The three moves as cut
  $C492,5 Other objects' scans may find us again

@ $C497 label=ADJ_DU_FOR_OBJ_INTERSECT
c $C497 Shorten dU against the other objects
D $C497 Tries the object's box against all 56 records. For each one it already overlaps in V and Z, with the moves accepted so far, an overlap in U after the move means dU has to be shortened, a unit at a time, until the boxes no longer meet; if dU reaches zero the scan stops.
D $C497 Every such meeting sets bit 0 of +$0C and passes harm between the two: bit 6 of +$0D means killed, and the obstacle gets it if the mover has bit 7 (kills what it moves into), the mover if the obstacle has bit 5 (kills what touches it). An obstacle with bit 2 of its flags set, a thing that can be pushed, is given the mover's whole intended dU, which its own update then moves it by.
R $C497 IX the moving object
R $C497 C dU
R $C497 L dV so far (zero)
R $C497 H dZ as accepted
R $C497 O:C dU, shortened
  $C497,6 IY = the first record; 56 of them
  $C49D,5 Empty, or out of the collision tests
  $C4A2,10 Not overlapping in V, or not in Z
@ $C4AC label=DU_OBJ_HIT_TEST
  $C4AC,5 No overlap in U after the move: the next object
  $C4B1,4 Stopped in U
  $C4B5,12 The mover's bit 7 becomes the obstacle's bit 6
  $C4C1,9 The obstacle's bit 5 becomes the mover's bit 6
  $C4CA,12 A pushable obstacle takes on our dU
  $C4D6,8 A unit shorter; none left, done; else the same object again
@ $C4DE label=DU_OBJ_NEXT
  $C4DE,8 The next of 56

@ $C4E6 label=ADJ_DV_FOR_OBJ_INTERSECT
c $C4E6 Shorten dV against the other objects
D $C4E6 #R$C497 for V: an object has to overlap in U, after the accepted dU, and in Z to be in the way. Stopping sets bit 1 of +$0C; harm passes the same way, and a pushable obstacle takes on the mover's dV.
R $C4E6 IX the moving object
R $C4E6 L dV
R $C4E6 C dU as accepted
R $C4E6 H dZ as accepted
R $C4E6 O:L dV, shortened
  $C4E6,6 IY = the first record; 56 of them
  $C4EC,5 Empty, or out of the collision tests
  $C4F1,10 Not overlapping in U, or not in Z
@ $C4FB label=DV_OBJ_HIT_TEST
  $C4FB,5 No overlap in V after the move: the next object
  $C500,4 Stopped in V
  $C504,21 Harm passes both ways, as in U
  $C519,12 A pushable obstacle takes on our dV
  $C525,8 A unit shorter; none left, done; else the same object again
@ $C52D label=DV_OBJ_NEXT
  $C52D,8 The next of 56

@ $C535 label=ADJ_DZ_FOR_OBJ_INTERSECT
c $C535 Shorten dZ against the other objects
D $C535 #R$C497 for Z, done before U and V so it tests the object where it stands: an object has to overlap in U and in V to be above or below it. Stopping sets bit 2 of +$0C, whether the move was up or down, and harm passes as in U.
D $C535 A mover with bit 2 of its flags -- the robot's legs have it -- is carried: it gives its intended dZ to the obstacle and, wherever its own dU or dV is zero, takes on the obstacle's, so standing on something that moves carries it along. When that mover is one of graphics 16 to 47, which takes in the robot's legs, the obstacle also gets bit 3 of its +$0D: the robot has stood on it, or come up against it from below. The update routines of graphics 44, 45 and 47 (#R$B2B6, #R$B28C, #R$B31F) read and clear that bit.
D $C535 Knight Lore sets the obstacle's bit 3 for any mover and passes no dZ; Pentagram passes the dZ and sets bit 3 for any mover too, with more of its own (the conveyors, the marks its lift reads). Here the bit is kept for the robot.
R $C535 IX the moving object
R $C535 H dZ
R $C535 C dU, zero here
R $C535 L dV, zero here
R $C535 O:H dZ, shortened
  $C535,6 IY = the first record; 56 of them
  $C53B,5 Empty, or out of the collision tests
  $C540,10 Not overlapping in U, or not in V
@ $C54A label=DZ_OBJ_HIT_TEST
  $C54A,5 No overlap in Z after the move: the next object
  $C54F,4 Stopped in Z
  $C553,21 Harm passes both ways, as in U
  $C568,6 Not a mover that is carried
  $C56E,9 Not graphics 16-47
  $C577,4 The mover (flags bit 2 and graphics 16-47: the robot, the pushable blocks, the bobbing block and the lift) has met the obstacle in Z
  $C57B,6 The obstacle takes our dZ
  $C581,12 No dU of our own: ride with the obstacle's
  $C58D,12 No dV of our own: ride with the obstacle's
  $C599,8 A unit shorter; none left, done; else the same object again
@ $C5A1 label=DZ_OBJ_NEXT
  $C5A1,8 The next of 56

@ $C5A9 label=DO_OBJS_INTERSECT_ON_U
c $C5A9 Do two objects overlap in U?
D $C5A9 Boxes are centred in U and V, with +$04 and +$05 the half-sizes. They overlap in U if the distance between the centres, after the mover's dU, is less than the two half-sizes added: exactly touching is not overlapping. The distance is taken as a signed byte, so centres 128 or more apart would be misjudged; no room is that big. Also used by #R$B712 and #R$BEA7.
R $C5A9 IX the moving object
R $C5A9 IY the other object
R $C5A9 C the mover's dU
R $C5A9 O:F carry set if they overlap
  $C5A9,7 D = the two half-sizes
  $C5B0,12 A = |U + dU - the other's U|
  $C5BC,2 Carry if less than D

@ $C5BE label=DO_OBJS_INTERSECT_ON_V
c $C5BE Do two objects overlap in V?
D $C5BE #R$C5A9 for V, with the mover's dV in L and the half-sizes at +$05. Also used by #R$B712 and #R$BEA7.
R $C5BE IX the moving object
R $C5BE IY the other object
R $C5BE L the mover's dV
R $C5BE O:F carry set if they overlap
  $C5BE,7 D = the two half-sizes
  $C5C5,12 A = |V + dV - the other's V|
  $C5D1,2 Carry if less than D

@ $C5D3 label=DO_OBJS_INTERSECT_ON_Z
c $C5D3 Do two objects overlap in Z?
D $C5D3 Not centred like U and V: Z is an object's base and +$06 its whole height. So the test takes the gap between the two bases, after the mover's dZ, and compares it with the height of whichever object is lower. The robot's top has no height while the legs move (#R$C0BE), and is kept out of the scans then; the legs, 23 high meanwhile, stand for the whole robot. Also used by #R$B712 and #R$BEA7.
R $C5D3 IX the moving object
R $C5D3 IY the other object
R $C5D3 H the mover's dZ
R $C5D3 O:F carry set if they overlap
  $C5D3,10 A = Z + dZ - the other's Z; the mover higher, use the other's height
  $C5DD,5 The mover lower: the distance, and its own height
  $C5E2,2 Carry if the gap is less than the lower one's height
  $C5E4,5 The other's height

@ $C5E9 label=ADJ_DU_FOR_OUT_OF_BOUNDS
c $C5E9 Shorten dU at the walls
D $C5E9 Keeps the object's whole footprint within the room: its U after the move no further from 128 than the room's U half-size (ROOM_HALF_U, 64 or 32) less its own half-size. dU is shortened a unit at a time, and bit 0 of +$0C set if it had to be.
D $C5E9 Two things switch the walls off, as in Knight Lore: the count in bits 4-7 of +$0C, the walk into a room, which the legs' update runs down a turn at a time (#R$C0BE); and bit 0 of the flags, which a doorway sets on the robot while he is in it (#R$C082). That is how he walks through one at all.
R $C5E9 IX the object
R $C5E9 C dU
R $C5E9 O:C dU, shortened
  $C5E9,6 Not while the count in +$0C runs
  $C5EF,5 Not in a doorway
  $C5F4,4 B = the room's U half-size
@ $C5F8 label=CLIP_DU_TO_WALLS
  $C5F8,10 A = |U + dU - 128|
  $C602,5 Inside if that plus the half-size is less than the room's: done
  $C607,4 Stopped in U
  $C60B,8 A unit shorter, and again unless nothing is left

@ $C613 label=ADJ_DV_FOR_OUT_OF_BOUNDS
c $C613 Shorten dV at the walls
D $C613 #R$C5E9 for V: the room's V half-size (ROOM_HALF_V), the object's at +$05, and bit 1 of +$0C.
R $C613 IX the object
R $C613 L dV
R $C613 O:L dV, shortened
  $C613,6 Not while the count in +$0C runs
  $C619,5 Not in a doorway
  $C61E,4 B = the room's V half-size
@ $C622 label=CLIP_DV_TO_WALLS
  $C622,10 A = |V + dV - 128|
  $C62C,5 Inside if that plus the half-size is less than the room's: done
  $C631,4 Stopped in V
  $C635,8 A unit shorter, and again unless nothing is left

@ $C63D label=CALC_2D_INFO
c $C63D Work out an object's screen rectangle
D $C63D Fills in where an object's sprite lands in the screen buffer: the pixel position at +$1A and +$1B (#R$CFD2), and the size -- +$18 the width in bytes, one more when the pixel x is not a multiple of 8, and +$19 the height in rows. #R$CFFE also turns the sprite the way the object faces.
D $C63D Two cases leave things as they were. While the scene after a game runs (GAME_OVER), #R$CFD2 does not move the position. And when the object's sprite is the empty one (graphics 0 and 1 use it), #R$CFFE returns straight to this routine's caller, so +$18 and +$19 keep what they held: the area the object last covered is still the area to clear.
R $C63D IX the object
  $C63D,3 The pixel position
  $C640,3 DE = the sprite, turned the way the object faces
  $C643,12 The width, bits 0-3 of the sprite's first byte, and one more for a shifted sprite
  $C64F,3 +$18: the width in bytes
  $C652,5 +$19: the height

@ $C657 label=SET_DRAW_OBJS_OVERLAPPED
c $C657 Mark every object the moving object's old or new rectangle touches
D $C657 Called once an object has moved or changed its drawing: by the robot's top (#R$C6E4), and through #R$BFAB -- which sets bits 4 and 5 of the object's flags first -- by the legs and most other update routines. It works out the object's new screen rectangle (#R$C63D), forms the smallest rectangle covering that and the one it had at the start of the turn (+$1C to +$1F, copied there by the main loop, #R$A647), and walks all 56 records setting the draw flag, bit 4 of +$07, on every live object whose rectangle meets it -- the moving object itself included.
D $C657 Across, the rectangles are measured in byte columns (pixel x over 8); up, in pixel rows from the bottom of the screen. E is the union's first column and D its width in columns; L its lowest row and H its height. Only the moving object's rectangle is used: an object redrawn because it meets it does not in turn mark the objects that meet it. Pentagram's routine, instruction for instruction.
R $C657 IX the object that has moved
  $C657,7 IY = the first record; the new rectangle into +$18 to +$1B
  $C65E,2 56 records
  $C660,9 L = the new first column
  $C669,9 H = the old first column
  $C672,5 E = whichever is further left
  $C677,15 D = the further right-hand edge, less E: the width in columns
  $C686,12 L = the lower of the two bottom rows
  $C692,19 H = the higher of the two tops, less L: the height
@ $C6A5 label=OVERLAP_TEST_OBJ
  $C6A5,6 An empty record: next
  $C6AB,6 Already to be drawn: next
  $C6B1,11 Its first column, less E; left of the union, see below
  $C6BC,3 Not left of the union: it meets it across if it starts inside
  $C6BF,6 Its bottom row, less L; below the union, see below
  $C6C5,3 Not below: it meets it up and down if it starts inside
  $C6C8,4 Draw it this turn
  $C6CC,10 The next record, D and E kept across the step
  $C6D6,7 To the left: it meets the union if the union starts inside its width
  $C6DD,7 Below: it meets the union if the union starts inside its height

@ $C6E4 label=TOP_FOLLOWS_LEGS
@ $C6F7 nowarn
c $C6E4 The robot's top (graphics 32 to 43)
D $C6E4 The top has no movement of its own. Each turn it copies the legs' U, V, Z, half-sizes, height and flags, takes a height one less, sits 12 above the legs, and takes the legs' graphic plus 16 -- so it turns and steps with them: legs 16-23 and 24-27, top 32-39 and 40-43. Then it and whatever its old or new rectangle meets are marked to be drawn (#R$C657). The flags it copies carry the legs' mirror bit, and their draw bits, which the legs' update has just set (#R$BFAB).
D $C6E4 The legs' height is 12 by now (the tail of #R$C0BE), so the top's is 11, from 12 up to 23: the robot's box is 23 high in all, the height the legs take on their own while he moves. Unlike Pentagram's body, the top is kept out of the collision tests only while the legs move (#R$C0BE sets bit 1 of its flags around the move), so other things can land on it and meet it.
D $C6E4 A top marked killed (bit 6 of +$0D) marks the legs killed too and turns into the sparkle he dies in (#R$B39A); the legs' update does the same the other way.
R $C6E4 IX the top's record
  $C6E4,3 Drawn 16 left and 3 down
  $C6E7,6 Killed?
  $C6ED,7 Then the legs are too; become the sparkle
  $C6F4,10 IY = HL = the legs, the record below (-32)
  $C6FE,7 U, V, Z, the half-sizes, the height and the flags from the legs
  $C705,3 One less high
  $C708,8 The legs' graphic plus 16
  $C710,8 12 above the legs
  $C718,4 Have it and whatever it overlaps redrawn

@ $C71C label=LIST_DRAWN
c $C71C List the objects to be drawn
D $C71C Called by the main loop (#R$A6C0) at the end of every turn, once every record has been updated. Writes into #R$C745 the number (0-55) of every record in use whose draw flag, bit 4 of +$07, is set, in record order, and an $FF after the last. #R$CEAB wipes the objects' old places from this list and #R$C785 draws from it.
  $C71C,16 56 records from the first; HL = the list; C = the number; IX kept
  $C72C,6 An empty record: not listed
  $C732,6 Not to be drawn this turn
  $C738,2 List its number
  $C73A,5 The next record
  $C73F,6 End the list

@ $C745 label=DRAW_LIST
s $C745 The objects to draw this turn
D $C745 Filled by #R$C71C every turn: record numbers, then $FF. While #R$C785 works through the list it sets bit 7 of each entry as that object is drawn, so the list also says what is still to do; #R$CEAB reads it first to wipe what moved. All zero on the tape.
D $C745 64 bytes: room for all 56 records and the $FF, with seven to spare. Pentagram's list, 48 bytes for 54 records, can overflow into the code after it; this one cannot. Measured in the simulator over the build's room tour (every room in turn, a few seconds of walking in each): the longest list was 51, first reached around room $74.

@ $C785 label=SORT_AND_DRAW
c $C785 Draw the listed objects, back to front
D $C785 Called by #R$CEAB every turn. This is where the game decides what is in front of what; the code is Knight Lore's and Pentagram's. Every listed object is a box in the room: centre U and V with half-sizes at +$04 and +$05, a base Z with its whole height at +$06. The far side of anything is towards smaller U, larger V and lower Z (measured in Pentagram, whose code this is).
D $C785 It takes the first object in #R$C745 not yet drawn as the candidate (IX) and compares it with every other undrawn one (IY). If some IY has to be drawn before the candidate, IY becomes the candidate and the comparison starts again from the top of the list; a candidate that survives a whole pass is drawn, marked done, and the whole thing starts over. So each object drawn has nothing undrawn behind it.
D $C785 The comparison classifies the two boxes on each axis -- IX clear on one side, overlapping, IY clear on one side -- and adds the three into an index 0-26 into #R$C833. The order found need not be consistent (three boxes can each be behind the next), so the chain of candidates is kept in #R$C8EF, and meeting an object already in it breaks the circle by drawing that object at once.
D $C785 DRAW_WORK counts the objects drawn; #R$CEAB adds the rectangles it wiped, and the main loop waits less the more work a turn has done. SORT_FIRST and SORT_SECOND point just past the candidate's entry and the compared object's.
R $C785 O:IX kept
R $C785 O:IY kept
  $C785,8 No objects drawn yet; keep IX and IY
@ $C78D label=SORT_PASS
  $C78D,3 A pass: from the top of the list
  $C790,7 The end of the list: everything is drawn
  $C797,4 Bit 7: already drawn
  $C79B,10 IX = the candidate; SORT_FIRST just past its entry
@ $C7A5 label=COMPARE_NEXT_OBJ
  $C7A5,7 The end of the list: nothing is behind the candidate, so draw it
  $C7AC,4 Already drawn: skip
  $C7B0,10 IY = this object; SORT_SECOND just past its entry
  $C7BA,8 The candidate itself: skip
  $C7C2,15 Z: code 0 if the candidate's base is at or above IY's top
  $C7D1,15 Code 2 if IY's base is at or above the candidate's top, 1 if they overlap
@ $C7E0 label=COMPARE_ALONG_V
  $C7E0,16 V: add 0 if the candidate's low-V edge is at or beyond IY's high-V edge, the candidate lying wholly further back
  $C7F0,22 Add 6 if IY lies wholly further back, 3 if they overlap
@ $C806 label=COMPARE_ALONG_U
  $C806,16 U: add 0 if the candidate's low-U edge is at or beyond IY's high-U edge, IY lying wholly further back
  $C816,22 Add 18 if the candidate lies wholly further back, 9 if they overlap
@ $C82C label=ACT_ON_COMPARISON
  $C82C,7 Jump through #R$C833, as the main loop jumps through the update table

@ $C833 label=DEPTH_ORDER
b $C833 What to do about a pair of boxes
D $C833 27 routine addresses, indexed by the Z code (0 the candidate above, 1 overlapping, 2 IY above) + the V code (0 the candidate further back, 3 overlapping, 6 IY further back) + the U code (0 IY further back, 9 overlapping, 18 the candidate further back), as #R$C785 works them out. "Further back" is smaller U, larger V, lower Z. The table is Knight Lore's and Pentagram's, entry for entry.
D $C833 Four outcomes. #R$C86F when IY is behind or level with the candidate on all three axes and strictly behind on at least one: IY must be drawn first. #R$C86C for the mirror image, where the candidate is behind IY and is being drawn first anyway. #R$C869 where each is in front of the other on some axis, which says nothing about their order. #R$C8AB, index 13, for boxes that overlap on every axis.
W $C833,8,2 0 (Z0 V0 U0): no constraint; 1 (Z1 V0 U0): no constraint; 2 (Z2 V0 U0): no constraint; 3 (Z0 V3 U0): IY first
W $C83B,8,2 4 (Z1 V3 U0): IY first; 5 (Z2 V3 U0): no constraint; 6 (Z0 V6 U0): IY first; 7 (Z1 V6 U0): IY first
W $C843,8,2 8 (Z2 V6 U0): no constraint; 9 (Z0 V0 U9): no constraint; 10 (Z1 V0 U9): candidate first; 11 (Z2 V0 U9): candidate first
W $C84B,8,2 12 (Z0 V3 U9): IY first; 13 (Z1 V3 U9): the boxes intersect; 14 (Z2 V3 U9): candidate first; 15 (Z0 V6 U9): IY first
W $C853,8,2 16 (Z1 V6 U9): IY first; 17 (Z2 V6 U9): no constraint; 18 (Z0 V0 U18): no constraint; 19 (Z1 V0 U18): candidate first
W $C85B,8,2 20 (Z2 V0 U18): candidate first; 21 (Z0 V3 U18): no constraint; 22 (Z1 V3 U18): candidate first; 23 (Z2 V3 U18): candidate first
W $C863,6,2 24 (Z0 V6 U18): no constraint; 25 (Z1 V6 U18): no constraint; 26 (Z2 V6 U18): no constraint

@ $C869 label=ORDER_UNCONSTRAINED
c $C869 A pair with no order between them
D $C869 Reached through #R$C833. Each box is in front of the other along some axis, so neither has to be drawn first: on to the next object.
  $C869,3 Next comparison

@ $C86C label=CANDIDATE_ALREADY_FIRST
c $C86C The candidate is behind the other object
D $C86C Reached through #R$C833. The candidate is to be drawn before IY, which is what will happen anyway. The same instruction as #R$C869.
  $C86C,3 Next comparison

@ $C86F label=IY_GOES_FIRST
c $C86F The other object must be drawn first
D $C86F Reached through #R$C833. IY is behind the candidate, so it becomes the candidate instead -- unless it is already in the chain of objects that have been candidates since the last draw (#R$C8EF), in which case the order has gone round in a circle and IY is drawn straight away.
  $C86F,5 C = IY's number, from its entry in the list
  $C874,14 Search the chain for it
@ $C882 label=IY_BECOMES_CANDIDATE
  $C882,6 Not there: add it, with a new $FF after it
  $C888,10 IX = IY, and SORT_FIRST = SORT_SECOND
  $C892,6 Compare it with the whole list from the top, since it need not be the first undrawn entry
@ $C898 label=BREAK_ORDER_CYCLE
  $C898,13 A circle: find IY's entry in the list (its number is certain to be there, so the exit to a new pass is never taken)
  $C8A5,6 IX = IY; draw it, HL just past its entry

@ $C8AB label=BOXES_INTERSECT
c $C8AB Two boxes occupy the same space
D $C8AB Index 13 of #R$C833: the boxes overlap on all three axes, and order does not come into it. As in Knight Lore, this is where a valve that shares its space with something else is destroyed. Unless either is out of the collision tests (bit 1 of the flags), a loose valve -- graphics 96 to 99 -- is turned into graphic 64, whose update (#R$B3A4) steps it to 65, whose update (#R$B3B0) empties its place in #R$76E3 and then the record: the valve is gone for the rest of the game. The candidate is checked first; only one of the pair is changed. Knight Lore does this to its collectables (types 96-102); Pentagram does nothing here.
D $C8AB Measured in the simulator: a valve put in the start room where the robot appears, inside his box, was gone -- record and place emptied -- once he had appeared, with this routine's IY branch run; the same valve put above him came to rest on his top.
  $C8AB,11 Either out of the collision tests: nothing to do
  $C8B6,9 The candidate a loose valve?
  $C8BF,6 Yes: destroy it
  $C8C5,9 The other a loose valve?
  $C8CE,4 Yes: destroy it
  $C8D2,3 Next comparison

@ $C8D5 label=DRAW_CANDIDATE
c $C8D5 Draw the candidate and start the next pass
D $C8D5 The end of the list was reached with nothing found that has to be drawn before the candidate. Its entry is marked drawn (bit 7), the candidate chain emptied, the object counted in DRAW_WORK and drawn (#R$D013); then back to the top of the list for the next. #R$C86F comes in at DRAW_AND_NEXT_PASS to draw an object that closes a circle.
R $C8D5 IX the object
  $C8D5,3 HL = just past the candidate's entry
@ $C8D8 label=DRAW_AND_NEXT_PASS
  $C8D8,3 Its entry: drawn
  $C8DB,5 The chain is empty again
  $C8E0,4 One more object drawn this turn
  $C8E4,6 Draw it; then the next pass

@ $C8EA label=ALL_DRAWN
c $C8EA All the listed objects are drawn
D $C8EA The end of #R$C785: its caller's IX and IY back.

@ $C8EF label=CANDIDATE_CHAIN
b $C8EF The chain of candidates since the last draw
D $C8EF Record numbers, ended by $FF, of every object #R$C86F has made the candidate since #R$C8D5 last drew something; #R$C8D5 empties it by putting an $FF in the first byte. All $FF on the tape.
D $C8EF Nothing checks the chain's length: sixteen bytes hold fifteen numbers and the $FF, twice Knight Lore's eight, and a sixteenth link would put its $FF on the first byte of #R$C8FF. Measured in the simulator over the build's room tour: the longest chain was 8, first reached around room $12 -- one more than Knight Lore's eight bytes could have held.
B $C8EF,16,8

@ $C8FF label=READ_CONTROLS
c $C8FF Read the controls
D $C8FF Reads the keyboard or a joystick, by the method in bits 1-2 of CONTROL, into one byte for this turn: the legs' update routines (#R$C0BE, #R$C1E2) use it in C, and it is kept in INPUT for the pick-up (#R$BD58).
D $C8FF The keyboard: Z, C, M and B turn left and X, V, SYMBOL SHIFT and N right; the whole of the A-G and H-ENTER rows walk; the whole of the Q-T and Y-P rows jump; any number key picks up or puts down. CAPS SHIFT and SPACE do nothing here (SPACE pauses, #R$CE22). The joysticks: left and right turn, up walks, fire jumps and down picks up or puts down. The Kempston is read from port 31; the cursor keys are 5 left, 8 right, 7 up, 6 down and 0 fire; Interface II is the keys 6-0 for one stick and 1-5 for the other, read together.
D $C8FF Bit 5 is set, whatever the method, by any letter key, ENTER or SYMBOL SHIFT -- everything but CAPS SHIFT, SPACE and the number keys. With directional control on a joystick, where down is a direction, it is the pick-up in place of bit 4 (#R$BD58), as in Knight Lore. While the game is won or the scene after a game runs (WON, GAME_OVER) only bit 5 is read: the robot takes no orders.
D $C8FF Pentagram's is the same but for its fire button, and it has no bit 5.
R $C8FF O:A the controls: bit 0 turn left, 1 turn right, 2 walk, 3 jump, 4 pick up or put down, 5 any letter key
R $C8FF O:C the same
  $C8FF,13 Won, or the scene after a game: nothing but bit 5
  $C90C,15 Bits 1-2 of CONTROL: 0 keyboard, 1 Kempston, 2 cursor keys...
  $C91B,16 ...3 Interface II: keys 1-5, their order reversed into C, so that 5 is bit 0 and 1 is bit 4, as 0 and 6 are on the other half-row
  $C92B,6 OR in keys 6-0: bit 0 fire (0 or 5), 1 up (9 or 4), 2 down (8 or 3), 3 right (7 or 2), 4 left (6 or 1)
  $C931,8 Fire: jump
  $C939,6 Up: walk
  $C93F,6 Down: pick up or put down
  $C945,6 Right: turn right
  $C94B,9 Left: turn left; then bit 5
@ $C954 label=READ_KEMPSTON
  $C954,10 The Kempston joystick: bit 0, right, turns right
  $C95E,6 Bit 1, left: turn left
  $C964,6 Bit 2, down: pick up or put down
  $C96A,6 Bit 3, up: walk
  $C970,9 Bit 4, fire: jump; then bit 5
@ $C979 label=READ_CURSOR
  $C979,13 The cursor keys: 5 turns left
  $C986,11 0: jump
  $C991,6 7: walk
  $C997,6 8: turn right
  $C99D,8 6: pick up or put down; then bit 5
@ $C9A5 label=READ_KEYBOARD
  $C9A5,17 The keyboard. CAPS SHIFT to V: Z and C brought down to bit 0, turn left, and X and V to bit 1, turn right; CAPS SHIFT dropped
  $C9B6,11 SYMBOL SHIFT turns right...
  $C9C1,6 ...M left...
  $C9C7,6 ...N right...
  $C9CD,6 ...B left
  $C9D3,9 Any key on the A-G or H-ENTER rows (both half-rows at once): walk
  $C9DC,9 Any on the Q-T or Y-P rows: jump
  $C9E5,9 Any number key: pick up or put down
@ $C9EE label=READ_LETTER_KEYS
  $C9EE,20 Any of Z, X, C, V, SYMBOL SHIFT, M, N and B, or of the four other letter half-rows: bit 5
  $CA02,5 This turn's controls into INPUT, and in A and C

@ $CA07 label=NEW_LIFE
c $CA07 Start a life
D $CA07 Called by the main loop at the start of every game and after every death (#R$A647, #R$A6C0). Copies the two start records (#R$CA1D) over the robot's -- as a game starts (#R$CA6D), or as he last came through a doorway (#R$C397) -- and takes a life. The copies' graphic is 56, so he appears through graphics 56-63 (#R$BC70) and then takes the graphic kept at +$10 (#R$BC83).
D $CA07 The first call of a game takes the five lives to four; below zero, after the fifth death, the game is over (#R$B761).
R $CA07 O:IX the legs' record
  $CA07,14 Both records, legs and top; IX on the legs
  $CA15,8 A life fewer; below zero, the game is over

@ $CA1D label=START_LEGS
b $CA1D The start records
D $CA1D Two object records of 32 bytes, the robot's legs and top as a life starts: #R$CA07 copies them over #R$5B88. All zero on the tape. At a new game #R$CA6D fills the first eight bytes of each, the room and the graphic kept at +$10, and #R$A647 clears the legs' +$0C; as the robot comes through a doorway #R$C397 copies his whole records here, walk into the room and all, so a life starts where he last came in. Whatever else a record holds is what the last doorway left.
B $CA1D,8 The legs: graphic, U, V, Z, half-sizes, height, flags
@ $CA25 label=START_LEGS_ROOM
B $CA25,1 The room
B $CA26,7 The step in U, V and Z; +C, the walk into a room (bits 4-7) and the jump (bit 3), which a doorway leaves set and #R$A647 clears at every new game; +D, +E, +F
@ $CA2D label=START_LEGS_NEXT
B $CA2D,16,8 +10: the legs' own graphic, which the appearing robot takes at the end (#R$BC83); then the rest of the record
@ $CA3D label=START_TOP
B $CA3D,8 The top: graphic, U, V, Z, half-sizes, height, flags
@ $CA45 label=START_TOP_ROOM
B $CA45,1 The room
B $CA46,7 The step in U, V and Z, +C, +D, +E, +F
@ $CA4D label=START_TOP_NEXT
B $CA4D,16,8 +10: the top's own graphic, as for the legs; then the rest of the record

@ $CA5D label=START_TEMPLATE
b $CA5D The start of the robot's records at a new game
D $CA5D Eight bytes for each of the two records, copied into the first eight bytes of the two start records (#R$CA1D) by #R$CA6D: graphic 56, the first of the appearing robot's; U and V 128, the middle of the room; Z 64, the floor, and 76 for the top, 12 above; half-sizes 7 and 7; heights 12 and 11; and flags with bits 2, 3 and 4 set -- carried by what he stands on (#R$C535), able to use a doorway (#R$C082), and drawn.
B $CA5D,8 The legs
B $CA65,8 The top

@ $CA6D label=NEW_GAME_START
c $CA6D Set the start records for a new game
D $CA6D Called at every new game (#R$A647), before the first #R$CA07. Copies #R$CA5D into the first eight bytes of each start record, gives each the graphic it takes once it has appeared -- 22 for the legs, facing higher U, and 38 for the top -- and picks the start room from #R$CA9E by bits 0-1 of SEED.
  $CA6D,19 Graphic, position, sizes and flags of each
  $CA80,10 The graphics they take once they have appeared
  $CA8A,12 One of four rooms, by bits 0-1 of SEED
  $CA96,8 Into both records

@ $CA9E label=START_ROOMS
b $CA9E The four start rooms
D $CA9E Indexed by bits 0-1 of SEED (#R$CA6D). In the simulator the seed is always the same, and a game starts in room $4E.
B $CA9E,1 Room $13: row 1, column 3
B $CA9F,1 Room $4E: row 4, column 14
B $CAA0,1 Room $88: row 8, column 8
B $CAA1,1 Room $D7: row 13, column 7

@ $CAA2 label=ENTER_ROOM
c $CAA2 Build the room he is in
D $CAA2 Called from the main loop (#R$A647) at the start of every life and after every walk through a doorway (#R$C397), with IX on the legs. Puts the valves of the room being left back into their places (#R$AF05) -- unless no turn has been played since the game began (PLAYED) -- builds the room's records (#R$CCA7), clears the screen buffer (#R$CE7B), fills the two valve records from the places (#R$AE99), and puts the robot in the doorway he came in by if he came through one (#R$CC01).
D $CAA2 Then the room's state: nothing dropping from the ceiling (DROPPING), no orders for the remote-controlled robots (REMOTE_ORDERS), LEAPING cleared, and DROP_LATCH set in an even-numbered room, so that nothing drops there until something is picked up. NEW_ROOM tells the main loop to redraw the whole screen, and the room is marked seen (#R$B863).
R $CAA2 IX the legs' record
  $CAA2,9 A turn has been played: the valves in the room being left back into their places
  $CAAB,3 Build the room
  $CAAE,3 Clear the screen buffer
  $CAB1,3 The valves in this room into their records
  $CAB4,3 In by a doorway: stand him in it
  $CAB7,10 Nothing dropping, no orders for the remote-controlled robots, LEAPING cleared
  $CAC1,9 DROP_LATCH: 1 in an even-numbered room
  $CACA,5 NEW_ROOM
  $CACF,3 Mark the room seen

@ $CAD2 label=RESET_ROOM_COLOURS
c $CAD2 Give every room back its own colour
D $CAD2 Called at every new game (#R$A647). A room's third byte holds its colour twice: bits 3-5 as the tape has it, and bits 0-2, the ink in use, which an activated chamber turns white (#R$AF79). This copies bits 3-5 into bits 0-2 in every record of the room directory (#R$6469), stepping from one to the next by the count at +1, so a new game starts with no chamber activated.
  $CAD2,7 The room directory and its end; HL on the first record's count
  $CAD9,2 E = the count; HL on the third byte
  $CADB,12 Bits 3-5 into bits 0-2
  $CAE7,3 On to the next record's count
  $CAEA,7 Until the end of the directory

@ $CAF1 label=TRANSFER_SPRITE
c $CAF1 Copy a sprite's four bytes into the drawing record
D $CAF1 Graphic, flags, x and y into +0, +7, +$1A and +$1B, where the sprite drawing (#R$D013) finds them. Used by #R$CB06, #R$CB0F and #R$CB8A to draw the panel and the border piece by piece. As Knight Lore's transfer_sprite and Pentagram's TRANSFER_SPRITE.
R $CAF1 HL the four-byte entry
R $CAF1 IX the record to draw with
R $CAF1 O:HL the next entry
  $CAF1,10 The graphic; the flags (bit 6 mirrored)
  $CAFB,11 X and y, in pixels

# --------------------------------------------------------------------------
# The last code, the buffers and the leftovers
# --------------------------------------------------------------------------

# Alien 8, stage 2, agent 5: $CB06-$FFFF -- the panel and the border, coming
# into a room, the room builder, memory helpers, the pause, clearing and
# showing the buffer, wiping what moved, the blit, the lookup tables, drawing
# a sprite, the address arithmetic, turning sprites round; and the leftovers
# above the code.

# --------------------------------------------------------------------------
# The panel and the border
# --------------------------------------------------------------------------

@ $CB06 label=TRANSFER_SPRITE_AND_PRINT
c $CB06 Copy a sprite's four bytes and draw it
D $CB06 #R$CAF1 puts the graphic, the flags, x and y of a four-byte entry into +0, +7, +$1A and +$1B of the record at IX, and PRINT_SPRITE (in #R$D013) draws it at that pixel position, with no projection. HL is kept on the next entry. As Knight Lore's transfer_sprite_and_print.
R $CB06 HL the four-byte entry
R $CB06 IX the record to draw with, the spare one at #R$BD38
R $CB06 O:HL the next entry
  $CB06,3 Graphic, flags, x and y into the record
  $CB09,5 Draw it, keeping HL

@ $CB0F label=DISPLAY_PANEL
@ $CB19 nowarn
@ $CB35 nowarn
c $CB0F Draw the panel's scroll-work and icons at the foot of the screen
D $CB0F Draws the twelve pieces of #R$CB5A into the buffer through the spare record at #R$BD38: on each side a slanting run of five of graphic 9, stepping 16 pixels in and 8 down, a column of six of graphic 10 up the edge, and graphics 7 and 8 at the ends, the right side the left mirrored; then three icons -- the robot (graphic 12) beside the lives, the frame round the light years (graphic 84, in two mirrored halves), and graphic 131 beside the count of chambers activated, which #R$A7A3 prints at (32, 31). That is the only place graphic 131 is drawn, which is why it has a sprite but no update routine. Where each entry lands was measured: the routine run in the simulator, and run again with each entry's graphic made 0, the difference being that entry's pixels.
D $CB0F Called from the main loop (#R$A6C0) on the first turn in a new room, before #R$A749 colours the panel and prints its numbers and #R$CE85 shows the whole buffer. Knight Lore's display_panel draws the same kind of scroll-work from six entries; the icons are Alien 8's.
  $CB0F,10 IX = the spare record; the first entry
  $CB19,8 The left run: five, each 16 pixels right and 8 down
  $CB21,11 Six up the left edge, 8 pixels apart
  $CB2C,6 Graphic 7 above the edge, and graphic 8 at the foot of the run
  $CB32,11 The right run: five, each 16 pixels left and 8 down
  $CB3D,11 Six up the right edge
  $CB48,6 Graphics 7 and 8 on the right, mirrored
  $CB4E,3 The robot beside the lives
  $CB51,6 The two halves of the frame round the light years
  $CB57,3 The icon beside the chambers count

@ $CB5A label=PANEL_DATA
b $CB5A The pieces of the panel
D $CB5A Twelve entries of four bytes, as #R$CAF1 reads them: the graphic, the flags (bit 6 mirrored, bit 7 upside down), then x and y in pixels, y counting up from the bottom of the screen. #R$CB0F draws some once and repeats others along a line. Two entries a line.
B $CB5A,8,4 Graphic 9 at (16, 48), the left run's first, five of them; graphic 10 at (0, 0), six up the left edge
B $CB62,8,4 Graphic 7 at (0, 48), once; graphic 8 at (96, 0), once
B $CB6A,8,4 Graphic 9 mirrored at (224, 48), the right run's first; graphic 10 mirrored at (248, 0), six up the right edge
B $CB72,8,4 Graphic 7 mirrored at (240, 48); graphic 8 mirrored at (144, 0)
B $CB7A,8,4 Graphic 12, the robot, at (112, 0); graphic 84, the right half of the light years' frame, at (224, 9)
B $CB82,8,4 Graphic 84 mirrored, the left half, at (200, 9); graphic 131, the chambers icon, at (8, 24)

@ $CB8A label=PRINT_BORDER
c $CB8A Draw the border round the screen
D $CB8A From #R$CBC3, into the buffer through the spare record at #R$BD38: the corner sprite (graphic 4) drawn four times, turned each way; the top and bottom edges as 24 pieces of graphic 6, 8 pixels apart; and the sides as 128 of graphic 5 -- a sprite one pixel high -- a pixel apart. It frames the menu (#R$BC25, the first text list printed) and the screens after a game (#R$B761); a room has none. Knight Lore's print_border, with the same counts and steps.
  $CB8A,7 IX = the spare record; the first entry
  $CB91,12 The four corners
  $CB9D,11 The top edge: 24 pieces, 8 pixels apart
  $CBA8,8 The bottom edge, the same upside down
  $CBB0,11 The left edge: 128 pieces, a pixel apart going up
  $CBBB,8 The right edge, mirrored

@ $CBC3 label=BORDER_DATA
b $CBC3 The pieces of the border, and unreached code from Knight Lore
D $CBC3 Eight entries of four bytes for #R$CB8A, as in #R$CB5A: graphic, flags (bit 6 mirrored, bit 7 upside down), x, y. The screen is 256 by 192; the corner is 32 pixels square.
D $CBC3 Then, from the 33rd byte, code that nothing calls or jumps to (the loaded block searched for its address): Knight Lore's colour_panel, which coloured the frame of that game's sun and moon window, byte for byte the same but for the address of the fill routine, here #R$BF83. It blacks out columns 22 and 29 of rows 21 to 23 and makes columns 23 to 28 of rows 20 to 23 bright red. Alien 8 has no such window; its panel is coloured by #R$A749. The code runs on across #R$CBF6 and #R$CBF9, entries of their own only because the disassembler took those bytes for text and data.
B $CBC3,8,4 Graphic 4, the corner, at (0, 160); mirrored at (224, 160)
B $CBCB,8,4 Graphic 4 mirrored and upside down at (224, 0); upside down at (0, 0)
B $CBD3,8,4 Graphic 6 at (32, 168), the top edge's first; upside down at (32, 0), the bottom's
B $CBDB,8,4 Graphic 5 at (0, 32), the left edge's first; mirrored at (232, 32), the right's
C $CBE3,19 Unreached: black, one byte wide and three rows deep, at column 22 of row 21 and at column 29 (#R$BF83 fills B bytes by C rows with A)

@ $CBF6 label=COLOUR_PANEL_RED
b $CBF6 Unreached code, continued
D $CBF6 The part of the unreached code at #R$CBC3 that colours the frame bright red: LD A,$42, then the first byte of LD HL,$5A97 (row 20, column 23), whose other two bytes are the first of #R$CBF9.
B $CBF6,3,3

@ $CBF9 label=COLOUR_PANEL_TAIL
b $CBF9 The rest of the unreached code
D $CBF9 The last two bytes of LD HL,$5A97; LD BC,$0604 (six bytes wide, four rows deep); JP to the fill routine at #R$BF83. See #R$CBC3.
B $CBF9,8,8

# --------------------------------------------------------------------------
# Coming into a room
# --------------------------------------------------------------------------

@ $CC01 label=ADJUST_PLYR_UVZ_FOR_ROOM_SIZE
c $CC01 Put the robot in the doorway he came in by
D $CC01 Called when a room has been built (#R$CAA2). The exit code leaves a U or V of 0 or $FF as a marker of the wall he walked out through: 0 in U means he left by a wall at low U and comes in by this room's wall at high U, $FF the other way, and the same for V. He is put with his inner edge 2 inside the wall's line, the rest of him in the doorway, and #R$CC6D finds the arch in that wall and stands him on its floor. Without a marker -- a new game, or a life started where he last came in -- he stays where his record says.
D $CC01 Both his records are flagged to be drawn, and the top is put at the legs' U and V. The walls are where the room's size puts them, so the doorway's place is worked out from ROOM_HALF_U and ROOM_HALF_V. As Knight Lore's adjust_plyr_xyz_for_room_size, with the same four U+V values for the arches.
R $CC01 IX the robot's legs
  $CC01,12 L, H = the room's half-sizes in U and V, less 2
  $CC0D,6 U 0: in at high U
  $CC13,3 U $FF: in at low U
  $CC16,6 V 0: in at high V
  $CC1C,4 V $FF: in at low V; no marker, nothing to do
  $CC20,11 At low V: Z from the arch whose U+V is $C8, and V puts his inner edge 2 inside the wall
  $CC2B,3 Store V
  $CC2E,8 Both his records to be drawn (bit 4 of the flags)
  $CC36,13 The top at the legs' U and V
  $CC43,13 At high V: the arch whose U+V is $52
  $CC50,11 At low U: the arch whose U+V is $AE
  $CC5B,5 Store U
  $CC60,13 At high U: the arch whose U+V is $38

@ $CC6D label=ADJUST_PLYR_Z_FOR_ARCH
c $CC6D Stand the robot on the floor of the arch he comes in by
D $CC6D The code takes a room's doorways to be its first backgrounds, two pieces each, a pillar of graphic 2 and one of graphic 3 (#R$7535 and the three after it). The first pillars are then records 4, 6, 8 and 10, and the wall an arch is in is told by its first pillar's U + V (mod 256): $52 at high V, $38 at high U, $C8 at low V, $AE at low U. The one wanted gives the legs its Z, and the top goes 12 above; that is what puts him at the right height in a raised doorway.
D $CC6D The search stops at the first record that is not an arch pillar (graphic 4 or more) or after four; with no match Z is left alone. The RET after the fourth was never reached in the build's sessions. As Knight Lore's adjust_plyr_Z_for_arch, whose pillars are graphics 2 to 5.
R $CC6D C the U + V of the arch wanted
R $CC6D IX the robot's legs
  $CC6D,9 Record 4, and every other record from there: four doorways at most
  $CC76,6 Not an arch pillar: no more doorways
  $CC7C,9 This arch?
  $CC85,5 The next; none matched
  $CC8A,12 The legs' Z = the pillar's; the top 12 above

@ $CC96 label=GET_PTR_OBJECT
c $CC96 The address of the object record numbered A
D $CC96 Bit 7 of A is ignored: the draw list (#R$C745) sets it on entries already drawn. BC is kept. As Knight Lore's get_ptr_object, from #R$5B88 here.
R $CC96 A the record's number, 0-55
R $CC96 O:HL the record
  $CC97,2 Drop bit 7
  $CC99,12 Times 32, plus the first record

# --------------------------------------------------------------------------
# Building a room
# --------------------------------------------------------------------------

@ $CCA7 label=BUILD_ROOM
@ $CCD0 label=BUILD_CLEAR_REST
@ $CD0C label=BUILD_NEXT_BACKGROUND
@ $CD20 label=BUILD_BACKGROUND_PIECE
@ $CD3A label=BUILD_OBJECTS
@ $CD40 label=BUILD_NEXT_GROUP
@ $CD61 label=BUILD_NEXT_OBJECT
@ $CD62 label=BUILD_OBJECT_PIECE
@ $CDE8 label=BUILD_OBJECTS_DONE
@ $CDF0 label=BUILD_TEMPLATE_PAGE
@ $CE00 label=BUILD_SET_NUDGE
c $CCA7 Build a room's object records from the room directory
D $CCA7 Finds the robot's room in #R$6469, stepping from record to record by the count at +1, and takes its ink (ROOM_INK), the address of its colour byte (ROOM_COLOUR_AT), and its half-sizes and floor from #R$6460. Then it fills the records from record 4 (ROOM_OBJECTS) up, backgrounds first, then objects, and clears every record after the last it filled. A room that is not in the directory gets no records at all. Called by #R$CAA2 on entering a room; the first four records -- the robot's two and the two for the places -- are not touched.
D $CCA7 Backgrounds: a byte each, up to an $FF. A background (#R$7519) is a list of eight-byte pieces -- graphic, U, V, Z, the half-sizes, the height, flags -- ended by a zero, each piece its own record, with this room as its +8.
D $CCA7 Objects: groups, each a header byte (bits 0-2 how many less one, bits 3-7 the template) and a position byte for each. A template (#R$73C8) is a list of five-byte pieces -- graphic, the half-sizes, the height, flags -- ended by a zero, each piece its own record at the same place: U = 72 + 16 times bits 0-2 of the position, V = 72 + 16 times bits 3-5, and Z = the floor + 12 times bits 6-7.
D $CCA7 Two templates are not templates. Template 31 moves TEMPLATES_AT on 64 bytes, to the second page, and the byte after it is skipped (twelve times in the rooms). Template 0 makes the byte after it the placement nudge (PLACE_NUDGE) for the groups that follow: its bit 0 adds 8 to U, bit 1 adds 8 to V, and the rest is added to Z. The rooms use it 42 times, 41 of them with $30, which raises the objects that follow by 48 -- four levels -- and once with 0. Pentagram's builder has the same code for the nudge but no jump reaches it; in Alien 8 it is live.
D $CCA7 The count at +1 of the room's record, of the bytes from there to the end, is what stops the build, not the data: the backgrounds can use it up, or a group be cut short. Nothing checks that the 52 records are enough; if a room overran them the clearing loop, which stops only when it reaches the end of the records exactly, would not stop. None does: every room was built in the build's sessions.
R $CCA7 IX the robot's legs, whose +8 is the room
  $CCA7,13 The first page of object templates, no nudge; LIFT_TOP cleared
  $CCB4,9 DE = the first record to fill; BC = the end of the directory; HL = its first room
  $CCBD,7 This room?
  $CCC4,12 No: on by the count, until the end of the directory
  $CCD0,14 Clear the records from DE to the last; every way out of the builder ends here
  $CCDE,2 B = the count
  $CCE0,9 The room's ink, and where its colour byte is
  $CCE9,11 Bits 6-7 of the colour byte: which of the three sizes, times three
  $CCF4,20 The half-sizes in U and V, and the floor
  $CD08,4 Two of the count used; HL on the backgrounds, DE the record
  $CD0C,6 The backgrounds end at an $FF
  $CD12,14 HL = the background, the place in the room's record kept
  $CD20,5 A piece: graphic, U, V, Z, half-sizes, height, flags into +0 to +7
  $CD25,5 +8: this room
  $CD2A,5 +9 to +31 cleared; DE on the next record
  $CD2F,4 Another piece?
  $CD33,4 The next background, while the count lasts
  $CD37,3 The count ran out
  $CD3A,1 The $FF counted
  $CD3B,5 IY = the next record; the caller's IY kept
  $CD40,5 C = how many in this group
  $CD45,6 The header counted; D = the first position; the place kept
  $CD4B,7 The template number doubled; template 0 sets the nudge
  $CD52,5 Template 31 moves to the second page
  $CD57,10 HL = the template, from the page in TEMPLATES_AT
  $CD61,1 Kept for the next object of the group
  $CD62,25 A piece: graphic into +0, half-sizes and height into +4 to +6, flags into +7
  $CD7B,6 +8: this room
  $CD81,22 U from bits 0-2 of the position, and 8 more for bit 0 of the nudge
  $CD97,18 V from bits 3-5, and 8 more for bit 1 of the nudge
  $CDA9,25 Z from bits 6-7, 12 a level, plus the nudge less its bits 0-1, on the floor
  $CDC2,17 +9 to +31 cleared; IY on the next record
  $CDD3,4 Another piece?
  $CDD7,2 DE = the template, HL = the place in the room's record
  $CDD9,3 The position counted; the end of the count ends the room
  $CDDC,4 The end of the group: the next header
  $CDE0,8 The next position, the same template
  $CDE8,8 DE = the next free record; the caller's IY back; clear the rest
  $CDF0,11 Template 31: the next page of templates
  $CDFB,5 The byte after the header counted and skipped; the next group
  $CE00,6 Template 0: the byte after it is the nudge

# --------------------------------------------------------------------------
# Small helpers, the pause, clearing
# --------------------------------------------------------------------------

@ $CE06 label=ADD_HL_A
c $CE06 HL = HL + A
D $CE06 A is treated as unsigned, and comes back holding H. As Knight Lore's add_HL_A.
R $CE06 HL a number
R $CE06 A what to add

@ $CE0D label=HL_EQUALS_DE_X_A
c $CE0D HL = DE * A
D $CE0D Shift and add, taking the bits of A from the top; eight RLCAs bring A back to what it was, and BC is kept. Used only to find the length of a sprite's data (#R$D174). As Knight Lore's HL_equals_DE_x_A.
R $CE0D DE the multiplicand
R $CE0D A the multiplier
R $CE0D O:HL the product
  $CE0E,5 HL = 0; eight bits
  $CE13,7 Double the total, and add DE if the next bit of A is set

@ $CE1C label=ZERO_DE
@ $CE1D label=FILL_DE
c $CE1C Clear B bytes from DE
D $CE1C DE is left just past the last byte, which is how the room builder (#R$CCA7) moves on to the next record. The entry point FILL_DE fills with A instead: #R$A749 colours parts of the panel with it. As Knight Lore's zero_DE and fill_DE.
R $CE1C DE the first byte
R $CE1C B how many
R $CE1C O:DE just past the last
  $CE1C,1 Zero
  $CE1D,4 Fill B bytes with A

@ $CE22 label=HANDLE_PAUSE
c $CE22 Pause, when SPACE is pressed on its own
D $CE22 Called once a turn by the main loop (#R$A6C0). #R$B759 is given $7E, which selects two half-rows at once -- SPACE to B, and CAPS SHIFT to V -- read with a key pressed as a set bit; SPACE and CAPS SHIFT share bit 0, so either on its own pauses. A beep (#R$B6B6), a wait for the key to be let go, then for a press and a release, and a beep again.
D $CE22 The pause is a busy wait with interrupts off: the game has no EI anywhere, so nothing runs while it waits. Pentagram's pause turns interrupts on while it waits; Knight Lore's and this one do not.
  $CE22,8 SPACE not pressed: no pause
  $CE2A,3 Another key of the half-row with it: no pause
  $CE2D,9 Wait for it to be let go
  $CE36,3 A beep
  $CE39,9 Wait for a press
  $CE42,9 And for it to be let go
  $CE4B,3 A beep, and back to the game

@ $CE4E label=CLEAR_OBJECTS
@ $CE56 label=CLR_MEM
@ $CE58 label=CLR_BYTE
c $CE4E Clear all 56 object records
D $CE4E 1792 bytes from #R$5B88, the robot's records included: used when a game has ended (#R$B761). The entry point CLR_MEM clears BC bytes from HL, and CLR_BYTE fills them with E; the start of a game clears the variables and records with CLR_MEM (#R$A631, #R$A647). As Knight Lore's clr_mem and clr_byte.
R $CE4E HL (CLR_MEM, CLR_BYTE) the first byte
R $CE4E BC (CLR_MEM, CLR_BYTE) how many
R $CE4E E (CLR_BYTE) the value
  $CE4E,8 All the records
  $CE56,2 Zero
  $CE58,8 One at a time: BC is a 16-bit count

@ $CE60 label=CLR_BITMAP_MEMORY
c $CE60 Clear the display bitmap
D $CE60 6144 bytes from 16384, through CLR_MEM (#R$CE4E). As Knight Lore's clr_bitmap_memory.

@ $CE68 label=CLR_ATTRIBUTE_MEMORY
@ $CE6A label=FILL_ATTR
c $CE68 Set every attribute to bright red on black
D $CE68 $42 is BRIGHT, black paper, red ink. The entry point FILL_ATTR sets every attribute to A: #R$A749 fills the screen with the room's ink, BRIGHT, on black, as a room is first shown. Knight Lore's clr_attribute_memory sets bright yellow; its fill_attr is the same.
R $CE68 A (FILL_ATTR) the attribute

@ $CE73 label=CLEAR_SCRN
c $CE73 Clear the screen and make the border black
D $CE73 A black border, the attributes bright red on black (#R$CE68), and the bitmap cleared (#R$CE60). Used at the start of every game (#R$A647) and by the screens after a game (#R$B761, #R$B8A9). As Knight Lore's clear_scrn.

@ $CE7B label=CLEAR_SCRN_BUFFER
c $CE7B Clear the screen buffer
D $CE7B 6144 bytes of #R$D200, through CLR_BYTE (#R$CE4E): on entering a room (#R$CAA2), on the menu (#R$BA7E) and on the screens after a game. As Knight Lore's clear_scrn_buffer.

# --------------------------------------------------------------------------
# Showing the buffer, wiping what moved
# --------------------------------------------------------------------------

@ $CE85 label=SHOW_BUFFER
c $CE85 Copy the screen buffer to the screen
D $CE85 All 192 rows of 32 bytes from #R$D200. The buffer runs the other way up from the display -- its first row is the bottom line of the screen -- because the game's pixel y counts up from the bottom; so the copy starts at the display's bottom-left byte and works up a line at a time. Used on the first turn in a room (#R$A6C0) and for the text screens (#R$BC25, #R$B761). Knight Lore's update_screen clears the buffer as it copies; this one, like Pentagram's, leaves it as it is.
  $CE85,9 From the buffer's first row to the display's bottom line; 192 rows
  $CE8E,7 A row of 32 bytes; HL runs on to the next row by itself
  $CE95,7 Up a display line, unless that crossed a character row
  $CE9C,10 Crossing a character row: back 32 in E, and back into this third unless that borrowed
  $CEA6,4 The next row

@ $CEAB label=RENDER_DYNAMIC_OBJECTS
c $CEAB Redraw what changed and copy it to the screen
D $CEAB Called at the end of every turn (#R$A6C0). The draw list (#R$C745) holds the number of every record to be drawn this turn, up to an $FF, and SEQUENCE_AT steps through it. First, for each one that moved -- bit 5 of its flags, cleared here -- the area covering both where it was drawn last turn (+1C to +1F) and where it is now (+18 to +1B) is cleared in the buffer and remembered on the stack, WIPE_COUNT counting them. Then every listed object is drawn into the buffer in depth order (#R$C785), and the carried things on the panel if they changed (#R$BC9D); and last the remembered areas -- and only those -- are copied to the screen.
D $CEAB Nothing is ever rubbed out on the screen itself, so nothing flickers: the scenery is made of objects too, so what stood behind a moving thing is simply drawn again. On the first turn in a room (NEW_ROOM set) nothing is wiped: the buffer is freshly built and the main loop shows all of it. The areas count towards the turn's drawing work (DRAW_WORK), which sets how long the main loop waits. Pentagram's routine, instruction for instruction; Knight Lore's does the same in more pieces.
  $CEAB,4 No areas yet
  $CEAF,2 Kept for the caller
  $CEB1,7 The first turn in a room: nothing to wipe
  $CEB8,6 From the start of the draw list
  $CEBE,13 The next record's number; $FF ends the list
  $CECB,6 IX = the record
  $CED1,6 Bit 5 of the flags: it moved; the others in the list are only being drawn again
  $CED7,4 Only once
  $CEDB,12 C = the further left of the new pixel x (+1A) and the old (+1E)
  $CEE7,12 The old right edge in bytes: old x / 8 + old width (+1C)
  $CEF3,15 The new one: new x / 8 + new width (+18); E = the further right
  $CF02,10 H = the width in bytes, from the left edge's byte to the right edge
  $CF0C,11 B = the lower of the new pixel y (+1B) and the old (+1F)
  $CF17,7 The old top: old y + old height (+1D)
  $CF1E,10 The new top: new y + new height (+19); A = the higher
  $CF28,2 L = the height in rows
  $CF2A,5 An area that starts above the top of the screen has nothing to wipe
  $CF2F,9 If it runs past line 192, keep only the part below
  $CF38,6 DE = its display address, BC = its buffer address
  $CF3E,6 Rearranged: HL = the buffer address, B = the width, C = the height
  $CF44,7 One more area
  $CF4B,3 On the stack until the objects have been drawn
  $CF4E,4 Cleared in the buffer: #R$BF83 fills B bytes by C rows with A
  $CF52,3 The next record
  $CF55,5 The new x is the further left
  $CF5A,5 The new y is the lower
  $CF5F,3 Every listed object into the buffer, in depth order
  $CF62,3 The carried things on the panel, if they changed
  $CF65,10 The areas count towards the turn's drawing work
  $CF6F,7 None left to copy
  $CF76,7 Take one off the stack, with the width and height swapped into the order #R$CF85 takes them
  $CF7D,5 Copy it to the screen; the next
  $CF82,3 Done

@ $CF85 label=BLIT_TO_SCREEN
c $CF85 Copy a rectangle of the buffer to the screen
R $CF85 HL the buffer address of its bottom-left byte
R $CF85 DE the display address of the same byte
R $CF85 B the height in rows
R $CF85 C the width in bytes
D $CF85 Works up the screen a row at a time, as #R$CE85 does: for the areas #R$CEAB wiped, the carried things on the panel (#R$BC9D), and pieces of the panel redrawn in place (#R$AD66, #R$BF2F). As Knight Lore's blit_to_screen.
  $CF85,7 One row: B is cleared so that LDIR copies C bytes
  $CF8C,5 The buffer row above is 32 bytes on
  $CF91,8 Up a display line, unless that crossed a character row
  $CF99,10 Crossing a character row: back 32 in E, and back into this third unless that borrowed
  $CFA3,3 The next row

# --------------------------------------------------------------------------
# The drawing tables, the projection, drawing a sprite
# --------------------------------------------------------------------------

@ $CFA7 label=BUILD_LOOKUP_TBLS
@ $CFA9 label=SHIFT_TBL_VALUE
@ $CFB0 label=SHIFT_TBL_ENTRY
@ $CFC4 label=REVERSE_TBL_VALUE
@ $CFC7 label=REVERSE_TBL_BIT
c $CFA7 Build the drawing tables
D $CFA7 Fills the fifteen pages from #R$F100 up with tables the sprite drawing needs every turn, run at the start of every game before the menu (#R$A647).
D $CFA7 The fourteen above #R$F100 are the shifted bytes, in pairs: for each shift s from 1 to 7, page $F0 + 2s holds every byte value shifted right s places, and the page above it the bits that fall out into the next byte. Both are stored complemented, so that one value both clears the buffer under a sprite's mask and lets its image in (#R$D0BD). The loop builds them the other way about: it shifts each value left across two bytes, one place at a time, and stores the pair after each shift from the top page down, so shift s is the value shifted left 8 - s.
D $CFA7 #R$F100 itself is every byte value with its bits in the opposite order, which is how a sprite is mirrored (#R$D174). The layout is Knight Lore's build_lookup_tbls.
  $CFA7,2 Every byte value, L from 0
  $CFA9,7 DE = the value; H on the top page; seven shifts
  $CFB0,4 One more place left across D and E
  $CFB4,4 E complemented, on this page
  $CFB8,4 D complemented, on the page below
  $CFBC,2 The next shift
  $CFBE,3 The next value, until L wraps to 0
  $CFC1,3 Then the bit reversal
  $CFC4,9 Eight bits out of the bottom of D into the bottom of E: E is the value reversed
  $CFCD,4 Store it; the next value, until L wraps to 0

@ $CFD2 label=CALC_PIXEL_XY
c $CFD2 Project an object's position onto the screen
R $CFD2 IX the object
R $CFD2 O:F carry set if the pixel y is below 192, that is on the screen
D $CFD2 The isometric projection. U, V and Z (+1 to +3) become a pixel x in +1A and a pixel y in +1B, counted up from the bottom of the screen: pixel x = U + V - 128, and pixel y = (V - U + 128) / 2 + Z - 40, each with the drawing nudge (+12, +13) added. Knight Lore takes 104 where this takes 40, since its floors are lower; and Pentagram's version stops a pixel x below 0 at 0, which this does not.
D $CFD2 While GAME_OVER is set nothing is projected, and carry comes back set: the scene after a game (#R$AB61) places its sprites by pixel, writing +1A and +1B itself.
  $CFD2,6 After a game: no projection, and drawn wherever +1A and +1B say
  $CFD8,14 Pixel x: U + V - 128, plus the nudge
  $CFE6,21 Pixel y: (V - U + 128) / 2 + Z - 40, plus the nudge
  $CFFB,3 Carry set if it is on the screen

@ $CFFE label=FLIP_SPRITE
c $CFFE Find an object's sprite and make it face the right way
R $CFFE IX the object
R $CFFE O:DE the sprite's width byte
D $CFFE The graphic (+0) indexes #R$7827 for the sprite. A sprite whose first byte is 0 draws nothing: the routine then drops its own return address, so its RET leaves its caller too. Otherwise it jumps to #R$D174, which turns the sprite's data to match the object's flags and returns to the caller with DE on the width byte. As Knight Lore's flip_sprite.
  $CFFE,13 DE = the sprite, from the graphic table
  $D00B,5 A real sprite: turn it, and return from there
  $D010,3 None: return from the caller as well

@ $D013 label=CALC_PIXEL_XY_AND_RENDER
@ $D01F label=PROJECT_AND_DRAW
@ $D027 label=PRINT_SPRITE
@ $D04B label=PATCH_SPRITE_ROWS
@ $D069 label=DRAW_SPRITE_ROWS
@ $D07E label=SPRITE_ALIGNED
c $D013 Draw one object from the draw list
D $D013 Called by the depth sort (#R$C8D5) for each listed object in turn, back to front. Graphic 1 marks an object on its way out of the room's records -- a thing picked up (#R$BD6B), or at the end of #R$B3B0 -- and is not drawn: its record is emptied instead, which frees it. Anything else loses its draw flag (bit 4 of +7), is projected onto the screen by #R$CFD2, and is drawn by the entry point PRINT_SPRITE unless its pixel y is 192 or more, wholly above the screen.
D $D013 PRINT_SPRITE draws whatever sprite IX's graphic names at the pixel position already in +1A and +1B, with no projection: the panel and the border (#R$CB06, #R$BC56) and the carried things (#R$BC9D) are drawn with it, through the spare record at #R$BD38.
D $D013 A sprite is a width byte (bits 0-3 the width in bytes, bits 6 and 7 how it is stored now, turned or not), a height byte, and then a mask byte and an image byte for each byte of each row, the bottom row first. Each buffer byte is cleared where the mask is set and has the image put in, so an object punches its own shape out of whatever was drawn behind it.
D $D013 The row loop is unrolled for the widest sprite, five bytes, twice: a plain run for a sprite whose pixel x is a multiple of 8 (#R$D08F), and a shifted run that reads its bytes through the tables above #R$F100 and so touches one byte more per row (#R$D0BD). This routine patches the offset of the JR in #R$D0B9 to enter the right run as many units from its end as the sprite is wide, and the operand of the ADD at the foot of #R$D0BD with the step from the end of one row to the start of the next. The stack pointer reads the sprite: SP is pointed at the data and each POP DE fetches a mask into E and its image into D, the real SP kept in SAVED_SP meanwhile. The game never enables interrupts, so nothing pushes onto the sprite.
D $D013 On the way out +18 holds the width in bytes that was drawn (one more than the sprite's own when shifted) and +19 the height, cut to the rows below the top of the screen; the main loop copies them and the pixel position to +1C to +1F before the next turn's update, so #R$CEAB knows what to rub out. Nothing is clipped at the sides or the bottom. As Knight Lore's calc_pixel_XY_and_render and print_sprite.
R $D013 IX the object
  $D013,12 Graphic 1: empty the record instead
  $D01F,4 Drawn now: off the draw list's flag
  $D023,4 Pixel position into +1A and +1B; above the screen, nothing to draw
  $D027,3 DE = the sprite's width byte, the sprite turned the way the object faces; an empty sprite returns from here at once
  $D02A,7 The pixel x within its byte; 0 goes to the aligned case, SPRITE_ALIGNED
  $D031,6 H = $F0 + 2 * the shift: the page pair of #R$CFA7's tables for that shift
  $D037,9 The width from the width byte (bits 0-2 here), plus one: the bytes a shifted row touches, into +18
  $D040,11 The JR's offset: 16 bytes of code per byte of width, back from the end of the shifted run at #R$D0BD
  $D04B,3 The offset, into the JR in #R$D0B9
  $D04E,7 The step to the next row, into the ADD at the foot of #R$D0BD: 33 less the bytes touched, since a row moves BC on one fewer than that
  $D055,5 The height, into +19
  $D05A,15 If the sprite would run past the top of the screen, only the rows below it: 192 less the pixel y
  $D069,9 BC = the buffer address of the sprite's bottom-left byte (#R$D120)
  $D072,7 SP onto the mask and image bytes, the real one kept in SAVED_SP
  $D079,5 A = the rows to draw; into the loop
  $D07E,8 The aligned case: the width (bits 0-3), into +18; B = the bytes a row touches
  $D086,9 The JR's offset: 8 bytes of code per byte of width, back from the end of the aligned run at #R$D08F

@ $D08F label=SPRITE_ALIGNED_RUN
c $D08F The unrolled row of a byte-aligned sprite
D $D08F Entered by the JR in #R$D0B9, as many 8-byte units from the end as the sprite is wide. Each unit takes the next mask and image pair off the stack and does one buffer byte: cleared under the mask (CPL, OR E, CPL), the image ORed in, stored. The last unit has no INC BC, so a row leaves BC on its last byte, which is what the step patched into #R$D0BD allows for. Knight Lore's sprite_aligned and sprite_aligned_tail.
R $D08F BC the buffer byte to start at
R $D08F SP the sprite's next mask and image bytes
R $D08F A' the rows left
  $D08F,8 The first of five units
  $D097,24 Three more the same
  $D0AF,7 The fifth, without the INC BC
  $D0B6,3 On to the next row

@ $D0B9 label=SPRITE_ROW
@ $D0BB label=SPRITE_ROW_JUMP
c $D0B9 Start a row of a sprite
D $D0B9 The row count goes to A', and A takes the first buffer byte: the shifted units of #R$D0BD expect the byte they are finishing to be in A already. The JR's offset is patched by #R$D013 for every sprite, into the aligned run at #R$D08F or the shifted one at #R$D0BD; as it stands in the listing, an offset of $FE, it is a JR to itself. Knight Lore's sprite_row and sprite_row_jump.
R $D0B9 A the rows left
R $D0B9 BC the buffer byte the row starts at
  $D0B9,2 The count to A'; the first buffer byte
  $D0BB,2 Offset patched: into one of the unrolled runs

@ $D0BD label=SPRITE_SHIFTED_RUN
@ $D10E label=SPRITE_NEXT_ROW
c $D0BD The unrolled row of a shifted sprite
D $D0BD Entered by the JR in #R$D0B9, as many 16-byte units from the end as the sprite is wide. H is the first of the two pages #R$CFA7 built for this shift. The tables hold complements, so each byte is ANDed with the complement of the mask shifted, and XORed with the complement of the image shifted and complemented again -- which comes to the buffer byte cleared under the shifted mask with the shifted image put in. Page H gives the part of a mask or image byte that stays in the current buffer byte, which is finished and stored; page H + 1 the part that falls into the next, which is begun and left in A for the next unit. The byte the last unit begins is stored after the fifth.
D $D0BD Then, for both runs, BC steps up to the next row by the amount patched into the ADD below, and the loop goes round until A' runs out. The real stack pointer comes back from SAVED_SP, and the RET is the return from #R$D013.
R $D0BD A the buffer byte the row starts with
R $D0BD BC its address
R $D0BD H the shift's first table page
R $D0BD SP the sprite's next mask and image bytes
  $D0BD,8 The first unit: the buffer byte cleared under the mask and with the image put in, shifted right, and stored
  $D0C5,8 The bits that fall out, into the next buffer byte, left in A
  $D0CD,64 Four more units the same
  $D10D,1 Store the last spilled byte
  $D10E,8 BC up a row: the ADD's operand patched by #R$D013 to 33 less the bytes a row touches
  $D116,5 The next row, until the height runs out
  $D11B,5 The real stack pointer back; return from #R$D013

# --------------------------------------------------------------------------
# Address arithmetic
# --------------------------------------------------------------------------

@ $D120 label=CALC_VIDBUF_ADDR
c $D120 Buffer address of a pixel position
R $D120 C the pixel x
R $D120 B the pixel y, counted up from the bottom of the screen
R $D120 O:BC the address in #R$D200
D $D120 The buffer is plain rows of 32 bytes, the bottom line first, so the address is y * 32 + x / 8 from its start: BC shifted right three times. HL is kept. As Knight Lore's calc_vidbuf_addr.
  $D121,12 BC / 8 = y * 32 + x / 8
  $D12D,6 Plus the start of the buffer

@ $D135 label=CALC_VRAM_ADDR
c $D135 Display address of a pixel position
R $D135 C the pixel x
R $D135 B the pixel y, counted up from the bottom of the screen
R $D135 O:DE the display address of that byte
D $D135 Turns the game's upward y into the display's line counted from the top by complementing it: 255 - y is that line plus 64, one third of the screen too many in the top bits, which is taken back by adding 56 rather than 64 to the high byte. A' is changed. As Knight Lore's calc_vram_addr.
  $D135,7 E = x / 8, the column
  $D13C,5 The line within the character row, from bits 0-2 of 255 - y, kept in A'
  $D141,8 Bits 3-5, the character row within the third, into the top of E
  $D149,13 Bits 6-7, the third, with the line within the row, and 56 for the extra third

@ $D157 label=CALC_ATTRIB_ADDR
c $D157 Attribute address of a pixel position
R $D157 H the pixel y, counted up from the bottom of the screen
R $D157 L the pixel x
R $D157 O:DE the attribute address
D $D157 HL is kept. As Knight Lore's calc_attrib_addr.
  $D157,1 Kept
  $D158,9 H = (255 - y) / 8: the character row counted from the top, plus 8
  $D161,12 Three more shifts across H and L: row * 32 + x / 8
  $D16D,5 The attribute file less those 8 rows

# --------------------------------------------------------------------------
# Turning a sprite round
# --------------------------------------------------------------------------

@ $D174 label=VFLIP_SPRITE_DATA
@ $D19B label=VFLIP_ROW_PAIR
@ $D19C label=VFLIP_SPRITE_LINE_PAIR
@ $D1AF label=HFLIP_SPRITE_DATA
@ $D1CC label=HFLIP_READ_ROW
@ $D1DA label=HFLIP_WRITE_ROW
@ $D1E9 label=FLIP_DONE
c $D174 Turn a sprite's stored data the way its object faces
R $D174 DE the sprite's width byte
R $D174 IX the object
R $D174 O:DE the sprite's width byte
D $D174 Reached by a jump from #R$CFFE, so its RET goes back to #R$CFFE's caller. Sprites are turned in place, and the width byte remembers which way round the data now is: bit 7 set while it is stored upside down, bit 6 while mirrored. Bits 7 and 6 of the object's flags (+7) say how it wants to be drawn. Where they disagree the data is turned and the sprite's bit toggled, so an object that keeps facing one way costs nothing after the first time, while two objects sharing a sprite and facing opposite ways turn it back and forth every time each is drawn.
D $D174 Upside down is done by swapping whole rows end for end; mirroring (HFLIP_SPRITE_DATA) by reversing the order of each row's cells and the bits of every byte, through #R$F100. The row swap halves the height: a sprite one row high would make that 0 and the loop run 256 times. The only such sprite is graphic 5, the border's sides, which is mirrored but never turned upside down (#R$CBC3). As Knight Lore's vflip_sprite_data and hflip_sprite_data.
  $D174,1 Kept
  $D175,8 The sprite's bit 7 against the object's: the same means no turning over
  $D17D,4 Toggle the sprite's bit
  $D181,4 B = bytes a row: the width times two, for the mask and image bytes
  $D185,4 C = the height in rows; DE on the data
  $D189,10 HL = B * C, the data's length, plus the start: one past the end
  $D193,4 DE one past the end; HL one past the first row
  $D197,2 DE on the last byte of the last row, HL on the last byte of the first
  $D199,2 Swap rows in pairs: half the height
  $D19B,1 Kept
  $D19C,9 Swap the two rows byte by byte, working backwards
  $D1A5,7 HL on to the end of the next row down; DE is already at the end of the row before its last
  $D1AC,3 The next pair
  $D1AF,10 The sprite's bit 6 against the object's
  $D1B9,8 Toggle the sprite's bit; B and C = the width in cells
  $D1C1,3 The height into A'
  $D1C4,8 HL' reads and HL writes, both from the first row; B' = the page of the bit reversal table
  $D1CC,13 Push a row's pairs, each byte reversed: E' the mask, D' the image
  $D1D9,1 The width again, for the writing
  $D1DA,7 Pop them back over the row: last first, so the cells come back in the reverse order
  $D1E1,8 The next row, until the height runs out
  $D1E9,2 DE = the sprite

# --------------------------------------------------------------------------
# Above the code: bytes that are not the game's, and the buffers
# --------------------------------------------------------------------------

@ $D1EB label=OLD_COPYRIGHT
t $D1EB Unused: Knight Lore's copyright line
D $D1EB "COPYRIGHT 1984 A.C.G." -- the same 21 characters Knight Lore has in the same place, just after its last routine (flip_done) and before its screen buffer, carried over with the engine: Alien 8 is from 1985, and its menu prints its own notice from its text list. Nothing refers to it (the loaded block searched for its address), and the game never reads or writes it (measured, as for #R$D200).
T $D1EB,21

@ $D200 label=BUFFER
b $D200 The screen buffer
D $D200 6144 bytes, a byte for each eight pixels of the play area, 32 to a line, the bottom line first: the room is drawn here (#R$D013) and copied to the screen, all of it on the first turn in a room (#R$CE85) and only what changed after that (#R$CEAB). #R$D120 finds a place in it. The buffer is cleared (#R$CE7B) before anything is drawn in it.
D $D200 What the tape loads here is not the game's: the block runs on to the top of memory, and the machine it was saved from had these bytes in it. Every one is overwritten before it is read (measured: the loaded game run in the simulator from #R$6300 into its first room, noting the first access to each address). They are, in order: zeros; stack debris -- words that look like addresses in the ROM and the display; the Spectrum ROM's capital letters A to U; the first 1464 bytes of the Interface 1's ROM; and zeros.
D $D200 The Interface 1 code starts 328 bytes in. Disassembled as if at address 0 it is that ROM's restart table: RST 0 at offset 0 (POP HL, then LD (IY+124),0 -- the Interface 1's FLAGS3 -- and JP $0700), RST 8 at 8, RST 16 at 16 (which stores HL into its SBRT routine among the system variables), EI and RET at $38, RETN at $66; and read from address 0 its absolute jumps and calls into itself land on the starts of its instructions, which they do not when it is read from 1 or 2. The system variables it uses beyond the Spectrum's own exist only with an Interface 1 attached, and the error reports at offset $02B8 are the Interface 1's own, each between two numbers counting from 0 to 24. The ROM itself was not compared byte for byte.
B $D200,96,8 Zeros
B $D260,64,8 Stack debris: words that look like ROM and display addresses
B $D2A0,168,8 The Spectrum ROM's letters A to U, eight bytes each
B $D348,696,8 The Interface 1's ROM from its first byte: the restart table and the code after it; the last byte is the number 0 that comes before the first report
T $D600,461,24 The Interface 1's error reports, each followed by its number
B $D7CD,307,8 The ROM continued, from the number after the last report to offset $05B7
B $D900,4352,8 A byte of $0D, then zeros

@ $EA00 label=STACK_SPACE
s $EA00 The stack
D $EA00 From here up to #R$F100, where #R$6300 puts the stack pointer; the main loop puts it back there before every object's update routine (#R$A647), so nothing is left on the stack from one object to the next. The deepest use is #R$CEAB, which keeps three words for every area it wipes until they are copied to the screen. Zeros on the tape.
S $EA00,1792

@ $F100 label=MIRROR_TABLE
b $F100 Lookup tables
D $F100 Built by #R$CFA7 at the start of every game, before the menu: here every byte value with its bits reversed, for mirroring sprites (#R$D174); and on the fourteen pages above it, in pairs, every byte value shifted right one to seven places and the bits that fall out of it, complemented, for drawing a sprite at any pixel (#R$D0BD).
D $F100 What the tape loads here is zeros, stack debris like the buffer's, and a font of capital letters A to U of some other program -- none of it the game's, all overwritten before it is read (measured, as for #R$D200).
B $F100,3608,8 Zeros on the tape
B $FF18,64,8 Stack debris
B $FF58,168,8 A font's letters A to U
