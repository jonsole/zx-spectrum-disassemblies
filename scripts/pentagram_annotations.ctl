# Hand-written annotations for the Pentagram disassembly.
#
# scripts/build_pentagram.py generates a control file from a code-execution
# map (sna2ctl), puts the level data laid out by scripts/pentagram_data.py in
# place of what sna2ctl guessed for those bytes, and layers THIS file on top.
# Never edit game_disassembly/pentagram/*.ctl or *.asm by hand -- the next
# build overwrites both. Add what you learn here.
#
# Stage 1 (2026-09-27): the pipeline. What is here is thin on purpose: the
# entry points, the tables' titles, labels for the variables the code names,
# the buffers above the loaded block, and the addresses the remake's notes
# (examples/filmation/pentagram/driving.md) gave, each checked against the
# code before it went in. Stage 2 describes every routine. A title here is a
# claim: those resting on a reading of the code say what the code does, and
# nothing is named from a guess at intent.
#
# How far the code map can be trusted: all but 96 of the 4185 instructions
# were executed in SkoolKit's simulator by the build's own sessions (see
# game_disassembly/pentagram/pentagram-coverage.txt for the rest, which were
# found by following branches out of what ran).
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
# THE OBJECT RECORD. 54 records of 32 bytes at OBJECTS ($A76F), everything in
# a room: the player's legs and body, two bolts, two things from the sky, and
# 48 for the room's scenery, objects and quest things, which the room builder
# fills from the top ($AE0F) down. The fields the code has been read to use:
#   +0 graphic (0: an empty record)   +1 +2 +3 U, V, Z
#   +4 +5 the half-sizes in U and V   +6 the whole height, from the base at +3
#   +7 flags: bit 0 may cross the wall line this turn (set in a doorway);
#      bit 1 out of collisions; bit 2 mobile -- pushable in U and V, passes
#      its Z step to what it lands on, and rides what it stands on; bit 3 may
#      use doorways; bit 4 to be drawn (listed by $B531,
#      cleared once drawn); bit 5 copy its area of the buffer to the screen;
#      bit 6 mirrored
#   +8 the room -- for a doorway's scenery piece, the room it leads to
#   +9 +A +B the step in U, V, Z this turn
#   +C bits 0-2 the move was stopped in U, V, Z (bit 2: standing on
#      something); bit 3 jumping; bits 4-7 turns he walks on by himself
#      after a doorway
#   +D bit 7: kills what it moves into; bit 5: kills what touches it;
#      bit 6: killed; bit 0 set on a thing put down (nothing reads it)
#   +E +F an arch's nudge   +10 bit 0 a pacer's direction
#   +10 +11 (quest things) the address of the quest record it came from
#   +12 +13 the drawing nudge
#   +14 +15 +16 per-routine scratch: a homer's speeds, a bolt's step
#   +17 bit 7 set when the player's legs or block 91 land on it
#   +18-+1F where it was drawn, kept to rub it out next turn
# (Gathered from the five describing agents, 2026-09-27; each field is
# described where the routine that uses it is.)

# --------------------------------------------------------------------------
# The start
# --------------------------------------------------------------------------

# Tables and buffers that must stay whole: sna2ctl's guesses inside them
# are dropped (see declared_spans in build_pentagram.py). Kept here together
# because a span inside an entry is lost when that entry is rewritten.
; span $C3EF,16
; span $C3FF,64
; span $C8F7,16
; span $D432,304
; span $D718,183
; span $D7CF,85
; span $D824,15
; span $D833,20
; span $D847,12
; span $D853,28
; span $D86F,32
; span $D88F,6144

@ $5E00 label=ENTRY
@ $5E01 nowarn
c $5E00 Where the BASIC loader enters the game
D $5E00 The loader's last statement is a PRINT USR to this address. The stack goes just under this code, where the loader's CLEAR put RAMTOP anyway, and the game starts at #R$AF87.

@ $5E07 label=ROOM_SIZES
b $5E07 Room sizes
D $5E07 Three entries: the half-size in U, the half-size in V (about the room's centre at 128), and the floor's height, 128 in all three. Bits 3-7 of a room record's third byte pick one, and the builder (#R$C92C) copies it to #R$A71D.
B $5E07,3 Size 0
B $5E0A,3 Size 1
B $5E0D,3 Size 2

@ $5E10 label=ROOMS
D $5E10 The room directory: 139 records, one per room, end to end up to #R$696D. #R$C92C finds a room by stepping from one record to the next until the number matches.
D $5E10 A record is +0 the room number, +1 the count of bytes that follow it, +2 the room's ink (bits 0-2; the builder adds BRIGHT) and its size (bits 3-7, an index into #R$5E07). Then the scenery, two bytes an entry -- a scenery template (#R$696D) and, for a doorway, the room it leads to -- up to an $FF; then the objects in groups, a header byte (bits 0-2: how many, less one; bits 3-7: the object template, #R$6CE5) and a position byte for each: U in bits 0-2, V in bits 3-5, the level in bits 6-7. Nothing ends a record but the count at +1 running out, and a group can be cut short by it.
D $5E10 Each room is an entry of its own, laid out from the game's data when the disassembly is built.

@ $696D label=SCENERY_TABLE
D $696D A word per scenery template, the entry's first byte doubled as the index (#R$C92C). Four point back at the table itself, and no room uses them.

@ $6CE5 label=OBJECT_TABLE
D $6CE5 A word per object template, the group header's bits 3-7 as the index (#R$C92C). The builder keeps the table's address in #R$A73A: a template number of 31 moves it on by 64 bytes, to a second page of templates, though no room uses that.

@ $6DD7 label=GRAPHICS
D $6DD7 A word per graphic number, the address of its sprite: #R$B2EE looks up the graphic in +0 of an object's record here. Many numbers share a sprite, and a sprite whose width and height are both zero (#R$9395) draws nothing.

D $6F2F The sprites, end to end from here to #R$A709, with the font among them (#R$8355). Each is a width byte (bits 0-3 the width in bytes; bit 7 set while it is stored upside down, bit 6 while mirrored, both toggled in place by #R$B2EE as objects face about), a height byte, then a mask byte and an image byte for each cell, the bottom row first. On the tape every sprite is the right way round.

D $8355 43 characters of 8 bytes, the codes $30 to $5A. The print routine at #R$BAEA adds eight times the code to a base in #R$A732: for text, 384 bytes below this one, so that code $30 lands here, and this address itself for the digits of the score and lives, so that 0-9 are codes 0-9. A space is printed as code $3D.

# --------------------------------------------------------------------------
# The game's variables and the object records
# --------------------------------------------------------------------------

; span $A709,102

# --------------------------------------------------------------------------
# Variables, object records and the first code
# --------------------------------------------------------------------------

@ $A709 label=CONTROL
g $A709 Game variables
D $A709 All zero on the tape. When the game is first run, #R$AF87 clears everything from here to the end of the object records; after every game it clears again from BUCKET_OUT on. So the first five bytes -- the control method, the menu's two, an unused one and the random number -- carry over from one game to the next: the next game carries on the random sequence rather than replaying the last one, and the menu shows the method chosen before.
B $A709,1 Control method: bits 1-2 are 0 keyboard, 1 Kempston, 2 cursor, 3 Interface II (#R$BB74); bit 3 steers a joystick by direction (#R$C4C8), and no menu choice sets it. Kept from game to game
@ $A70A label=MENU_PASSES
B $A70A,1 Counted up each time round the menu's loop (#R$BB74); nothing reads it
B $A70B,1 Nothing refers to this byte
@ $A70C label=CONTROL_BEFORE
B $A70C,1 The control method as it was before the menu read the keys this time round; the menu compares the two and throws the result away
@ $A70D label=RANDOM
B $A70D,1 The random number: R is added in at every new game and after every object's update (#R$B00C). Read for the start room (#R$C2CE), the drops from the sky (#R$CBAB), the collectables' starting spots (#R$D16F) and by #R$CF22; #R$D64E reads it as a word with the byte after, masked to an address in the ROM, and plays the bytes there as pitches
@ $A70E label=BUCKET_OUT
B $A70E,1 1 while the well's bucket is out: the well gives no other (#R$CFD2); the bucket clears it when it reaches a quest item (#R$D0AC). The first byte a new game clears
@ $A70F label=PENTAGRAM_ON
B $A70F,1 1 once all four quest items are done (#R$D13A): from then on the pentagram's pieces are put into their room (#R$B097)
@ $A710 label=WIPE_COUNT
B $A710,1 How many areas #R$B19E has wiped this turn and left on the stack to be copied to the screen
@ $A711 label=NEW_ROOM
B $A711,1 Set by #R$C6B6 when it has built a room. While it is set #R$B19E wipes nothing; the main loop (#R$B00C) then redraws the whole screen and the panel and clears it
@ $A712 label=LIST_POINTER
B $A712,2 Where #R$B19E is in the list at #R$B55A
@ $A714 label=DRAW_WORK
B $A714,1 The turn's drawing work: #R$B58A zeroes it and counts every object it draws, #R$B19E adds every area it wiped, and the main loop (#R$B00C) waits six units less this
@ $A715 label=TURNS
B $A715,2 The turn counter, counted up at the end of every turn (#R$B00C); also read by #R$B866 and #R$CF22
@ $A717 label=SAVED_SP
B $A717,2 The stack pointer, while #R$B3D3 has it reading a sprite
@ $A719 label=SORT_FIRST
B $A719,2 Where #R$B58A is in the list at #R$B55A: the place after the object it has in hand
@ $A71B label=SORT_SECOND
B $A71B,2 The place after the object #R$B58A is comparing it with
@ $A71D label=ROOM_EXTENT
B $A71D,3 The room's size, from #R$5E07 (#R$C92C): how far from the middle of the room, 128, an object may reach in U, then in V -- the walls' tests (#R$B8E2, #R$B90D, #R$C4A3) compare the distance plus its half-size with them -- and the floor's height in Z, 128 in all three sizes, below which nothing falls (#R$B963) and on which the builder stands the objects
@ $A720 label=PANEL_DUE
B $A720,1 Set when what he carries changes (#R$BF79); #R$BA34 redraws the panel's items and clears it
@ $A721 label=LIVES
B $A721,1 Lives, in BCD. #R$AF87 gives five and every start of a life takes one (#R$C2EC), so five is the one in play and four more; the game ends when there is none to take
@ $A722 label=CARRIED
B $A722,4 What he carries: entries of four bytes, the graphic, the flags and the address of the thing's quest record. This one is a slot for the thing being picked up, empty between presses: #R$BF79 writes it here, then moves every entry along one
@ $A726 label=CARRIED_SHOWN
B $A726,8,4 The things he carries, newest first; these two and the next are the three #R$BA34 shows on the panel
@ $A72E label=CARRIED_LAST
B $A72E,4 The oldest, which the next press puts down
@ $A732 label=FONT_BASE
B $A732,2 The base the print routine (#R$BAEA) adds eight times a character's code to: 384 bytes below the font for text, the font itself for digits
@ $A734 label=FRAME_DRAWN
B $A734,1 0 until #R$BCB4 has drawn the text screen's frame and copied the whole buffer to the screen, which it then does not do again; the menu and the win clear it to have that done afresh (#R$BB74, #R$C302)
@ $A735 label=MENU_SPARE
B $A735,1 Nothing reads or writes it: its only mention is an LD HL the menu's next instruction overwrites (#R$BB74)
@ $A736 label=PRINT_ATTR
B $A736,1 The attribute #R$BC66 gives each cell of text it prints; set by #R$BB14 and #R$BCB4
@ $A737 label=INPUT
B $A737,1 This turn's controls (#R$BDF8): bits 0 and 1 turn, 2 walk, 3 jump, 4 pick up or put down, 6 fire
@ $A738 label=ROOM_ATTR
B $A738,1 The room's attribute, its ink with BRIGHT on black (#R$C92C); the main loop fills the screen's attributes with it on the first turn in a room (#R$B00C)
@ $A739 label=Z_STEP
B $A739,1 The player's step in Z this turn, kept past the move (#R$C61D)
@ $A73A label=TEMPLATES_AT
B $A73A,2 The object template table the builder reads (#R$6CE5, #R$C92C)
@ $A73C label=PLACE_NUDGE
B $A73C,1 Added to the objects' positions by the builder (#R$C92C); zero for every room
@ $A73D label=DROP_TIMER
B $A73D,1 Turns until something may fall from the sky (#R$CBAB); set on entering a room (#R$CC31)
@ $A73E label=MAIN_SP
B $A73E,2 The stack pointer, saved every turn by the main loop (#R$B00C); nothing reads it back
@ $A740 label=TAKE_HELD
B $A740,1 1 while the pick-up key is held, so one press does one thing (#R$BF79)
@ $A741 label=NO_HEADROOM
B $A741,1 1 when there is no room above him to stand on what he puts down (#R$BF79)
@ $A742 label=DROP_BAN
B $A742,1 1 in a room with the well, a quest item or a piece of the pentagram: nothing falls there (#R$CB89)
@ $A743 label=FIRE_HELD
B $A743,1 1 while fire is held, so one press is one shot (#R$C126)
@ $A744 label=SCORE
B $A744,3 The score, six BCD digits, the highest first (#R$BB29)
@ $A747 label=TUNE_HEARD
B $A747,1 Set once the menu's tune has played (#R$D69C)
@ $A748 label=STEP_SOUND
B $A748,1 Counted up by #R$D635, which clicks on every fourth count
@ $A749 label=SOUND_COUNT
B $A749,2 A sound effect under way: turns left, then which sound (#R$D5F2). The pause's click (#R$D5D7) counts the first byte up as well
@ $A74B label=PLACED
B $A74B,1 How many collectables have reached their places in room 82 (#R$CD16)
@ $A74C label=QUEST_DONE
B $A74C,1 How many quest items the bucket has reached (#R$CF68)
@ $A74D label=PERCENT
B $A74D,2 The percentage of the quest done, BCD, the hundreds first, worked out by #R$C6EA
@ $A74F label=ROOMS_SEEN
B $A74F,31,8 A bit for each room number, bit 7 of the first byte for room 0, set on entering it (#R$C6CC). #R$C6EA counts all 31 bytes for the percentage, though rooms go no higher than 149, so only the first 19 can hold a bit
B $A76E,1 Nothing refers to this byte

; span $A76F,1728
@ $A76F label=OBJECTS
b $A76F The object records
D $A76F Everything in the room: 54 records of 32 bytes, all zero on the tape. The first six have fixed jobs -- the player's legs and body, two bolts he fires, two things fallen from the sky -- and the other 48 are the room's: the builder (#R$C92C) fills them from the top down with scenery and objects, and #R$B097 puts the quest things in the lowest free ones. The main loop (#R$AF87) runs every record's update routine once a turn, in order, empty ones included.
D $A76F A record: +0 the graphic, which also picks the update routine (#R$AE2F) and the sprite (#R$6DD7); 0 is an empty record, and 1 one that is emptied when it is next drawn. +1 to +3 U, V and Z. +4 and +5 the half-sizes in U and V, +6 the whole height from the base at +3. +7 the flags: bit 1 is set, among other uses, on the record being tested for overlaps (#R$BF1B); bit 4 that it is to be drawn (#R$B531), bit 5 that it moved and its old picture must be wiped (#R$B19E), bit 6 mirrored and bit 7 upside down (#R$B2EE); the rest are described with the routines that use them. +8 the room -- except for scenery, where it is the scenery entry's second byte: for a doorway the room it leads to, otherwise 0. +9 to +B the step in U, V and Z this turn. +C what it bumped into. +D bit 7: kills what it moves into; bit 5: kills what touches it; bit 6: killed. +E and +F an extra step in U and V, added into the next move and cleared (#R$C66A); a doorway uses it to steer the player to its middle (#R$C907, #R$C91A).
D $A76F +10 and +11: for a quest thing, the address of its quest record (#R$B097); other kinds keep their own counters there. +12 and +13 the drawing nudge, signed, added to the pixel x and y (#R$B2C5); the update routines set it, through the short routines from #R$C74B on. +14 to +17 are each kind's own; bit 7 of +17 is set on a record that meets the player's legs, or graphic 91, in Z -- one on top of the other (#R$B890) -- and #R$CDBB, #R$CE31 and #R$D2AD read it. +18 and +19 the width in bytes and the height in rows of the sprite as last drawn, +1A and +1B its pixel x and y; +1C to +1F the same four from the turn before, copied there before each update (#R$AF87) so the old picture can be wiped.
B $A76F,1 The player's legs: graphic
@ $A770 label=PLAYER_U
B $A770,1 U
@ $A771 label=PLAYER_V
B $A771,1 V
B $A772,1 Z
B $A773,3 Half-sizes in U, V and Z
@ $A776 label=PLAYER_FLAGS
B $A776,1 Flags
@ $A777 label=PLAYER_ROOM
B $A777,1 The room
B $A778,3 The step in U, V and Z
@ $A77B label=PLAYER_BUMPED
B $A77B,1 What he bumped into
@ $A77C label=PLAYER_STATE
B $A77C,1 Bit 6: killed
B $A77D,18 The rest of the legs' record
@ $A78F label=PLAYER_BODY
B $A78F,32,8 The player's body
@ $A7AF label=BOLTS
B $A7AF,32,8 A bolt he fires (#R$C126)
@ $A7CF label=BOLT_SECOND
B $A7CF,32,8 The other
@ $A7EF label=FLYERS
B $A7EF,32,8 A thing fallen from the sky (#R$CBAB)
@ $A80F label=FLYER_SECOND
B $A80F,32,8 The other
@ $A82F label=ROOM_OBJECTS
B $A82F,1472,8 The room's 48: scenery, objects and quest things; the builder fills them from the top down, the quest things go in from the bottom up
@ $ADEF label=ROOM_SECOND
B $ADEF,32,8 The second from the top
@ $AE0F label=ROOM_FIRST
B $AE0F,32,8 The first the builder fills (#R$C92C)

@ $AE2F label=UPDATES
w $AE2F Update routines, by graphic
D $AE2F A word per graphic number: the routine the main loop runs for each object, every turn (#R$AF87). It is entered with IX on the object's record and with #R$B00C on the stack, so it ends with a plain RET, and it can change the object's graphic -- and so the routine it gets next turn -- to animate it. Many graphics share one; #R$C43F, a RET, is for what does nothing, the empty record's graphic 0 among them.

# Constants that only look like addresses, in the code from here to the top
# of memory: -32 and -64 (a record back, or two), and the drawing nudges, a
# signed pair of bytes loaded as one word. ($B0F2 is with its routine.)
@ $BB06 nowarn
@ $C5E0 nowarn
@ $C9A5 nowarn
@ $CA4B nowarn
@ $CAF2 nowarn
@ $BCEF nowarn
@ $BCFA nowarn
@ $C75F nowarn
@ $C769 nowarn
@ $C7A2 nowarn
@ $C7FD nowarn

@ $AF87 label=START
c $AF87 Start the game
D $AF87 Reached from #R$5E00 when the game has loaded. Clears the variables and the object records, and then does what every game does: clears the screen, builds the drawing tables (#R$B29A), gives five lives, stirs the random number, and runs the menu (#R$BB74) until 0 is pressed. Then the tune a game starts with, the quest's records afresh with the collectables placed (#R$D16F), and a start room chosen (#R$C2CE).
D $AF87 From there it is three loops, one inside another. RESTART starts a life: #R$C2EC copies the player template over his two records and takes a life, and ends the game when there are none. GAME_LOOP enters a room: it files the quest things of the room being left back in their records, builds the room he is in (#R$C6B6), puts the quest things that are there into it, decides whether anything may fall from the sky there, prints the score and sets the drop timer. #R$C843 jumps back to it when he walks through a doorway. MAIN_LOOP is a turn: a chance of something falling, then every one of the 54 object records' update routines in turn, and #R$B00C, which ends the turn, draws what changed and goes round again.
D $AF87 Each object's update routine is found in #R$AE2F by its graphic and entered by a jump, with the address of #R$B00C pushed first so that it ends with a RET. Unlike Knight Lore's loop, this one does not reset the stack pointer for each object: the routines keep the stack straight themselves.
  $AF87,3 A black border, and the speaker off
  $AF8A,9 Clear the variables and all 54 object records, up to the update table
@ $AF93 label=AFTER_GAME
  $AF93,9 After a game (#R$C302): the same from BUCKET_OUT on, which keeps the control method, the menu's bytes and the random number
  $AF9C,3 Clear the screen
  $AF9F,5 Bright magenta ink on black, the whole screen
  $AFA4,3 The shift tables and the bit reversal table
  $AFA7,5 Five lives: the first start of a life takes one
  $AFAC,10 Stir R into the random number, which then decides the rest
  $AFB6,3 The menu, until 0 is pressed
  $AFB9,6 The tune a game starts with
  $AFBF,3 The quest records afresh, and the collectables' starting spots
  $AFC2,3 One of four start rooms, into the player template
@ $AFC5 label=RESTART
  $AFC5,3 Start a life: the player template over both his records, and a life fewer; with none left the game is over
@ $AFC8 label=GAME_LOOP
  $AFC8,3 Enter a room: first the quest things of the room he was in go back to their records
  $AFCB,3 Build the room he is now in
  $AFCE,3 Put the quest things that are in it into the room's records
  $AFD1,3 Nothing falls from the sky in a room with the well, a quest item or a piece of the pentagram
  $AFD4,3 The score, and its heading
  $AFD7,3 Turns until something may fall
@ $AFDA label=MAIN_LOOP
  $AFDA,3 A turn: first, perhaps, something falls from the sky
  $AFDD,4 IX on the first record, the player's legs
@ $AFE1 label=NEXT_OBJECT
@ $AFE1 nowarn
  $AFE1,4 The update routine returns to #R$B00C
  $AFE5,3 The update routines
  $AFE8,24 Keep last turn's drawn width, height and position in +1C to +1F, so the old picture can be wiped
@ $B000 label=UPDATE_OBJECT
  $B000,3 The graphic is the index
@ $B003 label=JUMP_TO_TBL_ENTRY
  $B003,4 HL = BC + 2 * L: a word in a table of routines. #R$B58A, #R$C66A and #R$C802 jump in here with tables of their own
  $B007,5 Load the address, and go

@ $B00C label=OBJECT_DONE
c $B00C One object done; at the end of a turn, draw and wait
D $B00C Every update routine returns here. It stirs R into the random number -- R counts instructions, so the numbers depend on how long each update took -- and moves IX to the next record, going back to #R$AF87 until all 54 have had their turn.
D $B00C Then the turn is finished. The turn counter goes up, the objects to be drawn are listed (#R$B531), and #R$B19E wipes what moved, draws the objects in depth order and copies the changes to the screen. SPACE or CAPS SHIFT on its own pauses (#R$B4E0). Then it burns whatever time is left, so that the game runs at an even speed: it waits six units less the turn's drawing work (DRAW_WORK, #R$A709), which #R$B58A and #R$B19E count in objects drawn and areas wiped. A unit is 1280 turns of a 26 T-state loop, about 33,300 T-states, just under half a frame. So a room where fewer than six things change runs as fast as one where six do, and a busier one runs slower: the wait can only pad, never take time back.
D $B00C On the first turn in a room the whole screen is redrawn: the room's colour over every attribute, the carried things, the panel, the lives and the score, and the whole buffer copied to the screen, with a short sound. Last, if both of the player's records are empty -- they become so when his dying is over -- a life is lost; otherwise the next turn.
  $B00C,20 Stir R, the turn counter's low byte plus one, and the ROM byte at that address into the random number
  $B020,5 32 bytes a record
  $B025,12 Round again until IX reaches the update table, just past the last record
  $B031,7 The turn is over: count it
  $B038,3 List the records flagged to be drawn
  $B03B,3 Wipe what moved, draw in depth order into the buffer, and copy the changes to the screen
  $B03E,4 Kept, and never read back
  $B042,3 SPACE or CAPS SHIFT on its own pauses
  $B045,8 Six units, less what the turn's drawing already used
  $B04D,5 None left to wait
  $B052,8 One unit: 1280 turns of 26 T-states
  $B05A,2 The next unit
  $B05C,6 Not the first turn in the room: on to the sound
  $B062,4 Once only
  $B066,6 The room's colour over the whole screen
  $B06C,3 The three things he carries
  $B06F,3 The panel's artwork
  $B072,3 The lives icon, and the lives
  $B075,3 The whole buffer to the screen
  $B078,3 The score, and its heading
  $B07B,3 Nothing drawn so far needs wiping: bit 5 of every record's flags cleared
  $B07E,6 The sound of arriving: sound 0, for four turns
  $B084,3 A turn of the sound effect under way
  $B087,13 Both his records empty: a life is lost
  $B094,3 The next turn

@ $B097 label=QUEST_INTO_ROOM
c $B097 Put the quest things in this room into the object records
D $B097 The quest things -- the four quest items, the five collectables, the eight pieces of the pentagram and the bucket -- are not in the room directory. They live in 18 records of 16 bytes at #R$D432, each with its room at +8, and are copied into the object records when he enters a room, after the room is built (#R$AF87). #R$B115 copies them back when he leaves.
D $B097 Each thing in this room goes into the lowest free record of the room's 48, with its flag to be drawn set, the address of its quest record in +10 and +11, and the rest of the record zeroed. Two exceptions: the pieces of the pentagram stay out until all four quest items are done (PENTAGRAM_ON, #R$A709), and anything but a piece is lifted 12 at a time until it overlaps nothing (#R$BF1B), so that it stands on whatever it was left on top of -- in the sessions the lift never ran; poked in, a quest item put where a hazard stands came in 12 higher (measured). With no free record left it gives up on the rest.
  $B097,6 IY 16 bytes before the live quest records, since the loop adds 16 before it looks; 18 records
  $B09D,7 C = the room he is in
  $B0A4,8 The next record; graphic 0 has nothing to place: a thing being carried, or the bucket before the well gives it
  $B0AC,6 In this room?
  $B0B2,3 No: the next
  $B0B5,16 Find the lowest empty record of the room's 48
  $B0C5,2 None free: give up
  $B0C7,1 DE = the free record
  $B0C8,15 A piece of the pentagram (graphics 128 to 135) stays out until all four quest items are done
  $B0D7,4 To be drawn: set in the quest record itself, so the copy carries it
  $B0DB,8 The quest record's 16 bytes into the object record
  $B0E3,7 Its address into +10 and +11, so the thing can find its record again
  $B0EB,7 +12 to +1F zeroed
@ $B0F2 nowarn
  $B0F2,7 IX = the record: back 32 from its end
  $B0F9,9 A piece of the pentagram lies where it is
  $B102,5 Anything else: does it overlap something?
  $B107,10 Yes: lift it 12 and try again
  $B111,4 The next quest record

@ $B115 label=QUEST_OUT_OF_ROOM
c $B115 Copy the quest things in the room back to their records
D $B115 Runs as a room is entered, before the room is built over the records (#R$AF87), so it sees the room being left. Every one of the room's 48 records is looked up by its graphic among the 18 quest records at #R$D432, and where one matches, the object's first 16 bytes -- where it is now, its sizes, its flags and its room -- are copied back over the quest record. A quest thing that moved or was pushed in a room is found there again.
D $B115 The match is by graphic, not by the address kept at +10: a quest thing's graphic is unique among them, and #R$CF9E changes the quest record's graphic along with the object's when a quest item is done. An empty record's graphic 0 matches the record of a thing being carried, whose graphic is zeroed while he has it (#R$BF79), and copies the empty record's leftovers over it; that does no harm, since the graphic stays 0 and putting the thing down writes it back.
  $B115,6 IY a record before the room's first; 48 records
  $B11B,5 The next record
  $B120,3 Its graphic
  $B123,8 Against each of the 18 quest records' graphics
  $B12B,6 This one?
  $B131,4 The next object
  $B135,10 Found: the object's first 16 bytes back over the quest record
  $B13F,6 On to the next object

@ $B145 label=SHOW_SCORE
c $B145 Copy the score to the screen
D $B145 #R$BB29 prints the score's six digits into the buffer; this copies them to the screen: six bytes wide and eight rows high, from pixel x 184, y 9. Used when something shot scores (#R$C264).
  $B145,9 The bottom left of the digits: DE its display address, BC its buffer address
  $B14E,4 HL the buffer; eight rows
  $B152,7 A row: six bytes
  $B159,6 Up a display line: DEC D is enough unless the line crossed into the character row above
  $B15F,12 Crossing a character row: back 32 in E, and back into this third unless that borrowed
  $B16B,9 The buffer row above: 26 more after the six copied
  $B174,4 The next row

@ $B178 label=SHOW_BUFFER
c $B178 Copy the screen buffer to the screen
D $B178 All 192 rows of 32 bytes from #R$D88F. The buffer runs the other way up from the display -- its first row is the bottom line of the screen -- because the game's pixel y counts up from the bottom; so the copy starts at the display's bottom-left byte and works up a line at a time. Used on the first turn in a room (#R$B00C) and for the text screens (#R$BCB4, #R$C302). Knight Lore's copy clears the buffer as it goes; this one leaves it as it is.
  $B178,8 From the buffer's first row to the display's bottom line; 192 rows
  $B180,7 A row of 32 bytes; HL runs on to the next row by itself
  $B187,8 Up a display line, unless that crossed a character row
  $B18F,10 Crossing a character row: back 32 in E, and back into this third unless that borrowed
  $B199,5 The next row

@ $B19E label=RENDER_DYNAMIC_OBJECTS
c $B19E Redraw what changed and copy it to the screen
D $B19E Called at the end of every turn (#R$B00C). The list at #R$B55A holds every record flagged to be drawn this turn (#R$B531). First, for each one that moved -- bit 5 of its flags -- the area covering both where it was drawn last turn (+1C to +1F) and where it is now (+18 to +1B) is cleared in the buffer and remembered on the stack. Then every listed object is drawn into the buffer in depth order (#R$B58A), and the carried things on the panel if they changed (#R$BA34); and last the remembered areas -- and only those -- are copied to the screen.
D $B19E Nothing is ever rubbed out on the screen itself, so nothing flickers; the scenery is made of objects too, so what stood behind a moving thing is simply drawn again. On the first turn in a room nothing is wiped at all: the buffer is freshly built and #R$B00C copies all of it. The areas count towards the turn's drawing work (DRAW_WORK, #R$A709), which sets how long the main loop waits.
  $B19E,4 No areas yet
  $B1A2,2 Kept for the caller
  $B1A4,7 The first turn in a room: nothing to wipe
  $B1AB,6 From the start of the list
  $B1B1,13 The next record's number; $FF ends the list
  $B1BE,6 IX = the record
  $B1C4,6 Bit 5 of the flags: it moved; the others in the list are only being drawn again
  $B1CA,4 Only once
  $B1CE,12 C = the further left of the new pixel x (+1A) and the old (+1E)
  $B1DA,12 The old right edge in bytes: old x / 8 + old width (+1C)
  $B1E6,15 The new one: new x / 8 + new width (+18); E = the further right
  $B1F5,10 H = the width in bytes, from the left edge's byte to the right edge
  $B1FF,11 B = the lower of the new pixel y (+1B) and the old (+1F)
  $B20A,7 The old top: old y + old height (+1D)
  $B211,10 The new top: new y + new height (+19); A = the higher
  $B21B,2 L = the height in rows
  $B21D,5 An area that starts above the top of the screen has nothing to wipe
  $B222,9 If it runs past line 192, keep only the part below
  $B22B,6 DE = its display address, BC = its buffer address
  $B231,6 Rearranged: HL = the buffer address, B = the width, C = the height
  $B237,7 One more area
  $B23E,3 On the stack until the objects have been drawn
  $B241,4 Cleared in the buffer: #R$B6DD fills B bytes by C rows with A
  $B245,3 The next record
  $B248,5 The new x is the further left
  $B24D,5 The new y is the lower
  $B252,3 Every listed object into the buffer, in depth order
  $B255,3 The carried things on the panel, if they changed
  $B258,10 The areas count towards the turn's drawing work
  $B262,7 None left to copy
  $B269,7 Take one off the stack, with the width and height swapped into the order #R$B278 takes them
  $B270,3 Copy it to the screen
  $B273,2 The next
  $B275,3 Done

@ $B278 label=BLIT_TO_SCREEN
c $B278 Copy a rectangle of the buffer to the screen
R $B278 HL the buffer address of its bottom-left byte
R $B278 DE the display address of the same byte
R $B278 B the height in rows
R $B278 C the width in bytes
D $B278 Works up the screen a row at a time, as #R$B178 does, for the areas #R$B19E wiped and for the carried things on the panel (#R$BA34). The same as Knight Lore's.
  $B278,7 One row: B is cleared so that LDIR copies C bytes
  $B27F,5 The buffer row above is 32 bytes on
  $B284,8 Up a display line, unless that crossed a character row
  $B28C,10 Crossing a character row: back 32 in E, and back into this third unless that borrowed
  $B296,4 The next row

@ $B29A label=MAKE_TABLES
c $B29A Build the drawing tables
D $B29A Fills the fifteen pages from #R$F100 up with tables the sprite drawing needs every turn, run at every new game (#R$AF87).
D $B29A The fourteen from #R$F200 up are the shifted bytes, in pairs: for each shift s from 1 to 7, page $F0 + 2s holds every byte value shifted right s places, and the page above it the bits that fall out into the next byte. Both are stored complemented, so that one value both clears the screen under a sprite's mask and lets its image in. The loop builds them the other way about: it shifts each value left across two bytes, one place at a time, and stores the pair after each shift from the top page down, so shift s is the value shifted left 8 - s.
D $B29A #R$F100 itself is every byte value with its bits in the opposite order, which is how a sprite is mirrored (#R$B2EE). The layout is Knight Lore's.
  $B29A,2 Every byte value, L from 0
  $B29C,7 DE = the value; H on the top page; seven shifts
  $B2A3,4 One more place left across D and E
  $B2A7,3 E complemented, on this page
  $B2AA,5 D complemented, on the page below
  $B2AF,2 The next shift
  $B2B1,3 The next value, until L wraps to 0
  $B2B4,3 Then the bit reversal
  $B2B7,9 Eight bits out of the bottom of D into the bottom of E: E is the value reversed
  $B2C0,5 Store it; the next value, until L wraps to 0

@ $B2C5 label=CALC_PIXEL_XY
c $B2C5 Project an object's position onto the screen
R $B2C5 IX the object
R $B2C5 O:F carry set if the pixel y is below 192, that is on the screen
D $B2C5 The isometric projection. U, V and Z (+1 to +3) become a pixel x in +1A and a pixel y in +1B, counted up from the bottom of the screen: pixel x = U + V - 128, and pixel y = (V - U + 128) / 2 + Z - 104, each with the drawing nudge (+12, +13) added.
D $B2C5 Knight Lore's, with one addition: a picture whose x would come out below 0 is drawn from x 0. That rests on every nudge being negative -- adding one to an x that stays on the screen carries -- and so an object with a nudge of 0 would always be drawn at x 0. The update routines set the nudges, through the short routines from #R$C74B on; in room 100, measured, all 38 records in use had negative nudges.
  $B2C5,8 U + V - 128
  $B2CD,6 Plus the nudge: no carry means it went below 0, so 0
  $B2D3,3 Pixel x
  $B2D6,15 (V - U + 128) / 2 + Z - 104
  $B2E5,6 Plus the nudge: pixel y
  $B2EB,3 Carry set if it is on the screen

@ $B2EE label=FIND_SPRITE
c $B2EE Find an object's sprite, and turn it the way the object faces
R $B2EE IX the object
R $B2EE O:DE the sprite
D $B2EE The graphic (+0) indexes #R$6DD7 for the sprite. A sprite whose first byte is 0 draws nothing: the routine then drops its own return address, so its RET leaves its caller too.
D $B2EE Sprites are turned in place, and the width byte remembers which way round the data now is: bit 7 set while it is stored upside down, bit 6 while mirrored. Bits 7 and 6 of the object's flags (+7) say how it wants to be drawn. Where they disagree the data is turned and the sprite's bit toggled, so an object that keeps facing one way costs nothing after the first time, while two objects sharing a sprite and facing opposite ways turn it back and forth every time each is drawn.
D $B2EE Upside down is done by swapping whole rows end for end; mirroring by reversing the order of each row's cells and the bits of every byte, through #R$F100. Knight Lore does the same in three routines; here they are one.
  $B2EE,13 DE = the sprite, from the graphic table
  $B2FB,4 A real sprite
  $B2FF,3 None: return from the caller as well
  $B302,1 Kept
  $B303,8 The sprite's bit 7 against the object's: the same means no turning over
  $B30B,4 Toggle the sprite's bit
  $B30F,4 B = bytes a row: the width in bits 0 to 3, times two for the mask and image bytes
  $B313,4 C = the height in rows; DE on the data
  $B317,13 HL = B * C, the data's length, plus the start: one past the end
  $B324,5 DE one past the end; HL one past the first row
  $B329,2 DE on the last byte of the last row, HL on the last byte of the first
  $B32B,2 Swap rows in pairs: half the height
  $B32D,10 Swap the two rows byte by byte, working backwards
  $B337,9 HL on to the end of the next row down; DE is already at the end of the row before its last
  $B340,3 The next pair
  $B343,10 The sprite's bit 6 against the object's
  $B34D,8 Toggle the sprite's bit; B and C = the width in cells
  $B355,3 The height into A'
  $B358,8 HL' reads and HL writes, both from the first row; B' = the page of the bit reversal table
  $B360,13 Push a row's pairs, each byte reversed: E' the mask, D' the image
  $B36D,8 Pop them back over the row: last first, so the cells come back in the reverse order
  $B375,8 The next row, until the height runs out
  $B37D,2 DE = the sprite

@ $B37F label=CALC_VIDBUF_ADDR
c $B37F Buffer address of a pixel position
R $B37F C the pixel x
R $B37F B the pixel y, counted up from the bottom of the screen
R $B37F O:BC the address in #R$D88F
D $B37F The buffer is plain rows of 32 bytes, the bottom line first, so the address is y * 32 + x / 8 from its start: BC shifted right three times. HL is kept. The same as Knight Lore's.
  $B37F,13 BC / 8 = y * 32 + x / 8
  $B38C,8 Plus the start of the buffer

@ $B394 label=CALC_VRAM_ADDR
c $B394 Display address of a pixel position
R $B394 C the pixel x
R $B394 B the pixel y, counted up from the bottom of the screen
R $B394 O:DE the display address of that byte
D $B394 Turns the game's upward y into the display's line counted from the top by complementing it: 255 - y is that line plus 64, one third of the screen too many in the top bits, which is taken back by adding 56 rather than 64 to the high byte. A' is changed. The same as Knight Lore's.
  $B394,7 E = x / 8, the column
  $B39B,5 The line within the character row, from bits 0 to 2 of 255 - y, kept in A'
  $B3A0,8 Bits 3 to 5, the character row within the third, into the top of E
  $B3A8,14 Bits 6 and 7, the third, with the line within the row, and 56 for the extra third

@ $B3B6 label=CALC_ATTRIB_ADDR
c $B3B6 Attribute address of a pixel position
R $B3B6 H the pixel y, counted up from the bottom of the screen
R $B3B6 L the pixel x
R $B3B6 O:DE the attribute address
D $B3B6 HL is kept. The same as Knight Lore's.
  $B3B6,1 Kept
  $B3B7,9 H = (255 - y) / 8: the character row counted from the top, plus 8
  $B3C0,12 Three more shifts across H and L: row * 32 + x / 8
  $B3CC,7 The attribute file less those 8 rows

# --------------------------------------------------------------------------
# Range 2
# --------------------------------------------------------------------------

# Pentagram, stage 2, agent 2: $B3D3-$BBD7 -- drawing a sprite, the depth
# sort, the collision code that cuts a move short, the redraw marking, the
# panel's carried things, printing, the score and the menu.

# --------------------------------------------------------------------------
# Drawing an object
# --------------------------------------------------------------------------

@ $B3D3 label=DRAW_OBJECT
c $B3D3 Draw one object from the draw list
D $B3D3 Called by the depth sort (#R$B6B3) for each listed object in turn, back to front. Graphic 1 marks an object on its way out of the room's records -- #R$BF79 sets it on what is picked up, #R$C11D at the end of a puff -- and is not drawn: its record is emptied instead, which frees it. Anything else loses its draw flag (bit 4 of +$07), is projected onto the screen by #R$B2C5, and is drawn by the entry point below unless its pixel y is 192 or more, wholly above the screen.
D $B3D3 The entry point DRAW_SPRITE draws whatever sprite IX's graphic names at the pixel position already in +$1A and +$1B, with no projection: #R$BA34 draws the panel's carried things with it, and #R$C29A the lives icon, both through the spare record at #R$BACA.
D $B3D3 A sprite is a width byte (bits 0-3 the width in bytes, bits 6 and 7 how it is currently stored, flipped or not), a height byte, and then a mask byte and an image byte for each byte of each row, the bottom row first. Each buffer byte is cleared where the mask is set and has the image put in, so an object punches its own shape out of whatever was drawn behind it.
D $B3D3 The row loop is unrolled for the widest sprite, five bytes, twice: a plain run for a sprite whose pixel x is a multiple of 8 (#R$B44F), and a shifted run that reads its bytes through the mask tables from #R$F200 up and so touches one byte more per row (#R$B47D). This routine patches the offset of the JR in #R$B479 to enter the right run as many units from its end as the sprite is wide, and the operand of the ADD at the foot of #R$B47D with the step from the end of one row to the start of the next. The stack pointer reads the sprite: SP is pointed at the data and each POP DE fetches a mask into E and its image into D, the real SP kept in SAVED_SP meanwhile. The game runs with interrupts off (only #R$B4E0 turns them on, and only while paused), so nothing pushes onto the sprite.
D $B3D3 On the way out +$18 holds the width in bytes that was drawn (one more than the sprite's own when shifted) and +$19 the height, cut to the rows below the top of the screen; the main loop copies them to +$1C and +$1D before the next turn's update, so #R$B19E knows what to rub out. Nothing is clipped at the sides or the bottom.
R $B3D3 IX the object
  $B3D3,12 graphic 1: empty the record instead
  $B3DF,4 drawn now: off the draw list's flag
  $B3E3,4 pixel position into +$1A and +$1B; above the screen, nothing to draw
@ $B3E7 label=DRAW_SPRITE
  $B3E7,3 DE = the sprite's width byte, the sprite turned the way the object faces (#R$B2EE); an empty sprite returns from here at once
  $B3EA,7 the pixel x within its byte; 0 goes to the aligned case, SPRITE_ALIGNED
  $B3F1,6 H = $F0 + 2 * the shift: the page pair of #R$B29A's tables for that shift
  $B3F7,9 the width from the header, plus one: the bytes a shifted row touches, into +$18
  $B400,11 the JR's offset: 16 bytes of code per byte of width, back from the end of the shifted run at #R$B47D
@ $B40B label=PATCH_SPRITE_ROWS
  $B40B,3 the offset, into the JR in #R$B479
  $B40E,7 the step to the next row, into the ADD at the foot of #R$B47D: 33 less the bytes touched, since a row moves BC on one fewer than that
  $B415,8 the height, into +$19
  $B41D,12 if the sprite would run past the top of the screen, only the rows below it: 192 less the pixel y
@ $B429 label=DRAW_SPRITE_ROWS
  $B429,9 BC = the buffer address of the sprite's bottom-left byte (#R$B37F)
  $B432,7 SP onto the mask and image bytes, the real one kept in SAVED_SP
  $B439,5 A = the rows to draw; into the loop
@ $B43E label=SPRITE_ALIGNED
  $B43E,7 the aligned case: the width from the header, into +$18
  $B445,1 B = the bytes a row touches, the width itself
  $B446,9 the JR's offset: 8 bytes of code per byte of width, back from the end of the aligned run at #R$B44F

@ $B44F label=SPRITE_ALIGNED_RUN
c $B44F The unrolled row of a byte-aligned sprite
D $B44F Entered by the JR in #R$B479, as many 8-byte units from the end as the sprite is wide. Each unit takes the next mask and image pair off the stack and does one buffer byte: cleared under the mask (CPL, OR E, CPL), the image ORed in, stored. The last unit has no INC BC, so a row leaves BC on its last byte, which is what the step patched into #R$B47D allows for.
R $B44F BC the buffer byte to start at
R $B44F SP the sprite's next mask and image bytes
R $B44F A' the rows left
  $B44F,8 the first of five units
  $B457,24 three more the same
  $B46F,7 the fifth, without the INC BC
  $B476,3 on to the next row

@ $B479 label=SPRITE_ROW
c $B479 Start a row of a sprite
D $B479 The row count goes to A', and A takes the first buffer byte: the shifted units of #R$B47D expect the byte they are finishing to be in A already. The JR's offset is patched by #R$B3D3 for every sprite, into the aligned run at #R$B44F or the shifted one at #R$B47D; as it stands in the listing, an offset of $FE, it is a JR to itself.
R $B479 A the rows left
R $B479 BC the buffer byte the row starts at
  $B479,2 the count to A'; the first buffer byte
  $B47B,2 offset patched: into one of the unrolled runs

@ $B47D label=SPRITE_SHIFTED_RUN
c $B47D The unrolled row of a shifted sprite
D $B47D Entered by the JR in #R$B479, as many 16-byte units from the end as the sprite is wide. H is the first of the two pages #R$B29A built for this shift. The tables hold complements, so each byte is ANDed with the complement of the mask shifted, and XORed with the complement of the image shifted and complemented again -- which comes to the buffer byte cleared under the shifted mask with the shifted image put in. Page H gives the part of a mask or image byte that stays in the current buffer byte, which is finished and stored; page H + 1 the part that falls into the next, which is begun and left in A for the next unit. The byte the last unit begins is stored after the fifth.
D $B47D Then, for both runs, BC steps up to the next row by the amount patched into the ADD below, and the loop goes round until A' runs out. The real stack pointer comes back from SAVED_SP, and the RET is the return from #R$B3D3.
R $B47D A the buffer byte the row starts with
R $B47D BC its address
R $B47D H the shift's first table page
R $B47D SP the sprite's next mask and image bytes
  $B47D,8 the first unit: the buffer byte cleared under the mask and with the image put in, shifted right, and stored
  $B485,8 the bits that fall out, into the next buffer byte, left in A
  $B48D,64 four more units the same
  $B4CD,1 store the last spilled byte
@ $B4CE label=SPRITE_NEXT_ROW
  $B4CE,8 BC up a row: its operand patched by #R$B3D3 to 33 less the bytes a row touches
  $B4D6,5 the next row, until the height runs out
  $B4DB,5 the real stack pointer back; return from #R$B3D3

# --------------------------------------------------------------------------
# Pause, and small helpers
# --------------------------------------------------------------------------

@ $B4E0 label=PAUSE
c $B4E0 Pause, when SPACE or CAPS SHIFT is pressed on its own
D $B4E0 Called once a turn by the main loop (#R$B00C). Half-rows $7F and $FE are read together, so bit 0 is SPACE or CAPS SHIFT and bits 1-4 are the other eight keys of the two rows; the pause needs bit 0 and none of the others, so no key that plays the game can start one. The game beeps (#R$D5D7), waits for the key to be let go, then for a press and a release, and beeps again.
D $B4E0 While it waits, interrupts are on: IY is set to the ROM's system variables and EI lets the ROM's frame interrupt run, the only place the game allows it. DI turns them off again before the game goes on. IY is left pointing at the system variables; nothing that follows expects it to hold anything else.
  $B4E0,8 not SPACE or CAPS SHIFT: no pause
  $B4E8,3 another key with it: no pause
  $B4EB,3 a beep
  $B4EE,9 wait for it to be let go
  $B4F7,5 the ROM's interrupt routine may run while the game waits
  $B4FC,9 wait for a press
  $B505,9 and for it to be let go
  $B50E,5 interrupts off again; a beep

@ $B513 label=CLEAR_BYTES
c $B513 Clear B bytes from DE
D $B513 #R$BF79 and #R$C92C clear parts of object records with it. The entry point FILL_BYTES fills with A instead: #R$C29A colours the lives icon with it.
R $B513 DE the first byte
R $B513 B how many
R $B513 O:DE just past the last
  $B513,1 zero
@ $B514 label=FILL_BYTES
  $B514,5 fill B bytes with A

@ $B519 label=ADD_HL_A
c $B519 HL = HL + A
D $B519 A is treated as unsigned. A is left holding H.
R $B519 HL a number
R $B519 A what to add

@ $B520 label=RECORD_OF
c $B520 HL = the address of the object record numbered A
D $B520 Bit 7 of A is ignored: the draw list (#R$B55A) sets it on entries already drawn. BC is kept.
R $B520 A the record's number, 0-53
R $B520 O:HL the record, 32 bytes each from #R$A76F
  $B521,2 drop the drawn bit
  $B523,13 times 32, plus the first record

# --------------------------------------------------------------------------
# The draw list and the depth sort
# --------------------------------------------------------------------------

@ $B531 label=LIST_DRAWN
c $B531 List the objects to be drawn
D $B531 Called by the main loop (#R$B00C) once every object has been updated. Writes into #R$B55A the number (0-53) of every record in use whose draw flag, bit 4 of +$07, is set, in record order, and an $FF after the last. #R$B19E wipes the objects' old places from this list and #R$B58A draws from it.
  $B531,16 54 records from #R$A76F; HL = the list; C = the number
  $B541,6 an empty record: not listed
  $B547,6 not to be drawn this turn
  $B54D,2 list its number
  $B54F,5 the next record
  $B554,6 end the list

@ $B55A label=DRAW_LIST
s $B55A The objects to draw this turn
D $B55A Filled by #R$B531: record numbers, then $FF. While #R$B58A works through the list it sets bit 7 of each entry as that object is drawn, so the list also says what is still to do.
D $B55A 48 bytes: Knight Lore's size, for its forty records. Pentagram has 54, so a turn that listed more than 47 objects would write its later entries and the $FF over the start of #R$B58A. The fullest room (87) builds 43 records from the directory, and lists 45 on arrival. Watched in the emulator: with two collectables staged into it the list reached 47 and the game ran on for 300 turns; with three it reached 48, the $FF landed on #R$B58A's first byte as RST $38 -- which turns interrupts on -- frame interrupts then pushed onto sprite data mid-draw, and the game hung; with five, a hang after six turns. See the bugs page.

@ $B58A label=SORT_AND_DRAW
c $B58A Draw the listed objects, back to front
D $B58A Called by #R$B19E. This is where the game decides what is in front of what; the code is Knight Lore's. Every listed object is a box in the room: centre U and V with half-sizes at +$04 and +$05, a base Z with its whole height at +$06. The far side of anything is towards smaller U, larger V and lower Z (measured in the simulator with pairs of boxes: the one with smaller U, larger V or lower base was drawn first).
D $B58A It takes the first object in #R$B55A not yet drawn as the candidate (IX) and compares it with every other undrawn one (IY). If some IY has to be drawn before the candidate, IY becomes the candidate and the comparison starts again from the top of the list; a candidate that survives a whole pass is drawn, marked done, and the whole thing starts over. So each object drawn has nothing undrawn behind it.
D $B58A The comparison classifies the two boxes on each axis -- IX clear on one side, overlapping, IY clear on one side -- and adds the three into an index 0-26 into #R$B638. The order found need not be consistent (three boxes can each be behind the next), so the chain of candidates is kept in #R$B6CD, and meeting an object already in it breaks the circle by drawing that object at once.
D $B58A DRAW_WORK counts the objects drawn; #R$B19E adds the rectangles it wiped, and the main loop waits less the more work a turn has done. SORT_FIRST and SORT_SECOND point just past the candidate's entry and the compared object's.
R $B58A O:IX kept
R $B58A O:IY kept
  $B58A,8 no objects drawn yet
@ $B592 label=SORT_PASS
  $B592,3 a pass: from the top of the list
  $B595,7 the end of the list: everything is drawn
  $B59C,4 bit 7: already drawn
  $B5A0,10 IX = the candidate; SORT_FIRST just past its entry
@ $B5AA label=COMPARE_NEXT_OBJ
  $B5AA,7 the end of the list: nothing is behind the candidate, so draw it
  $B5B1,4 already drawn: skip
  $B5B5,10 IY = this object; SORT_SECOND just past its entry
  $B5BF,8 the candidate itself: skip
  $B5C7,15 Z: code 0 if the candidate's base is at or above IY's top
  $B5D6,15 code 2 if IY's base is at or above the candidate's top, 1 if they overlap
@ $B5E5 label=COMPARE_ALONG_V
  $B5E5,16 V: add 0 if the candidate's low-V edge is at or beyond IY's high-V edge, the candidate lying wholly further back
  $B5F5,22 add 6 if IY lies wholly further back, 3 if they overlap
@ $B60B label=COMPARE_ALONG_U
  $B60B,16 U: add 0 if the candidate's low-U edge is at or beyond IY's high-U edge, IY lying wholly further back
  $B61B,22 add 18 if the candidate lies wholly further back, 9 if they overlap
@ $B631 label=ACT_ON_COMPARISON
  $B631,7 jump through #R$B638, as the main loop jumps through the update table

@ $B638 label=DEPTH_ORDER
w $B638 What to do about a pair of boxes
D $B638 27 addresses, indexed by the Z code (0 the candidate above, 1 overlapping, 2 IY above) + the V code (0 the candidate further back, 3 overlapping, 6 IY further back) + the U code (0 IY further back, 9 overlapping, 18 the candidate further back), as #R$B58A works them out. "Further back" is smaller U, larger V, lower Z. The table is Knight Lore's, entry for entry.
D $B638 Four outcomes. #R$B674 when IY is behind or level with the candidate on all three axes and strictly behind on at least one: IY must be drawn first. #R$B671 for the mirror image, where the candidate is behind IY and is being drawn first anyway. #R$B66E where each is in front of the other on some axis, which says nothing about their order. #R$B6B0, index 13, for boxes that overlap on every axis. The last three do the same thing.
W $B638,8,2 0 (Z0 V0 U0) no constraint; 1 (Z1 V0 U0) no constraint; 2 (Z2 V0 U0) no constraint; 3 (Z0 V3 U0) IY first
W $B640,8,2 4 (Z1 V3 U0) IY first; 5 (Z2 V3 U0) no constraint; 6 (Z0 V6 U0) IY first; 7 (Z1 V6 U0) IY first
W $B648,8,2 8 (Z2 V6 U0) no constraint; 9 (Z0 V0 U9) no constraint; 10 (Z1 V0 U9) candidate first; 11 (Z2 V0 U9) candidate first
W $B650,8,2 12 (Z0 V3 U9) IY first; 13 (Z1 V3 U9) the boxes intersect; 14 (Z2 V3 U9) candidate first; 15 (Z0 V6 U9) IY first
W $B658,8,2 16 (Z1 V6 U9) IY first; 17 (Z2 V6 U9) no constraint; 18 (Z0 V0 U18) no constraint; 19 (Z1 V0 U18) candidate first
W $B660,8,2 20 (Z2 V0 U18) candidate first; 21 (Z0 V3 U18) no constraint; 22 (Z1 V3 U18) candidate first; 23 (Z2 V3 U18) candidate first
W $B668,6,2 24 (Z0 V6 U18) no constraint; 25 (Z1 V6 U18) no constraint; 26 (Z2 V6 U18) no constraint

@ $B66E label=ORDER_UNCONSTRAINED
c $B66E A pair with no order between them
D $B66E Reached through #R$B638. Each box is in front of the other along some axis, so neither has to be drawn first: on to the next object.
  $B66E,3 next comparison

@ $B671 label=CANDIDATE_ALREADY_FIRST
c $B671 The candidate is behind the other object
D $B671 Reached through #R$B638. The candidate is to be drawn before IY, which is what will happen anyway. The same instruction as #R$B66E.
  $B671,3 next comparison

@ $B674 label=IY_GOES_FIRST
c $B674 The other object must be drawn first
D $B674 Reached through #R$B638. IY is behind the candidate, so it becomes the candidate instead -- unless it is already in the chain of objects that have been candidates since the last draw (#R$B6CD), in which case the order has gone round in a circle and IY is drawn straight away.
D $B674 Nothing checks the chain's length: #R$B6CD has room for fifteen numbers and the $FF, twice Knight Lore's, and a sixteenth link would put its $FF on the first byte of #R$B6DD. Measured over every room's first turn: the longest chain is 9, in the four start rooms, and four rooms go past Knight Lore's 7 -- so Knight Lore's eight bytes would have overflowed here (that this is why it was doubled is an inference).
  $B674,5 C = IY's number, from its entry in the list
  $B679,14 search the chain for it
@ $B687 label=IY_BECOMES_CANDIDATE
  $B687,6 not there: add it, with a new $FF after it
  $B68D,10 IX = IY, and SORT_FIRST = SORT_SECOND
  $B697,6 compare it with the whole list from the top, since it need not be the first undrawn entry
@ $B69D label=BREAK_ORDER_CYCLE
  $B69D,13 a circle: find IY's entry in the list (its number is certain to be there, so the exit to a new pass is never taken)
  $B6AA,6 IX = IY; draw it, HL just past its entry

@ $B6B0 label=BOXES_INTERSECT
c $B6B0 Two boxes occupy the same space
D $B6B0 Index 13 of #R$B638: the boxes overlap on all three axes, and order does not come into it. On to the next object. In Knight Lore this entry is where a collectable met by another object is destroyed; Pentagram does nothing here.
  $B6B0,3 next comparison

@ $B6B3 label=DRAW_CANDIDATE
c $B6B3 Draw the candidate and start the next pass
D $B6B3 The end of the list was reached with nothing found that has to be drawn before the candidate. Its entry is marked drawn (bit 7), the candidate chain emptied, the object counted in DRAW_WORK and drawn (#R$B3D3); then back to the top of the list for the next. #R$B674 comes in at DRAW_AND_NEXT_PASS to draw an object that closes a circle.
R $B6B3 IX the object
  $B6B3,3 HL = just past the candidate's entry
@ $B6B6 label=DRAW_AND_NEXT_PASS
  $B6B6,3 its entry: drawn
  $B6B9,5 the chain is empty again
  $B6BE,4 one more object drawn this turn
  $B6C2,6 draw it; then the next pass

@ $B6C8 label=ALL_DRAWN
c $B6C8 All the listed objects are drawn
D $B6C8 The end of #R$B58A: its caller's IX and IY back.

@ $B6CD label=CANDIDATE_CHAIN
b $B6CD The chain of candidates since the last draw
D $B6CD Record numbers, ended by $FF, of every object #R$B674 has made the candidate since #R$B6B3 last drew something; #R$B6B3 empties it by putting an $FF in the first byte. Sixteen bytes, where Knight Lore has eight.
B $B6CD,16,8

# --------------------------------------------------------------------------
# A rectangle of bytes
# --------------------------------------------------------------------------

@ $B6DD label=FILL_RECT
c $B6DD Fill a rectangle of bytes with A
D $B6DD Rows are 32 bytes apart, each one on from the last: in the screen buffer (bottom row first) that is up the screen, in the attribute file down it. #R$B19E clears in the buffer the rectangle an object leaves; #R$BA34 clears a carried thing's place on the panel and then colours its attributes.
R $B6DD HL the first byte
R $B6DD B the bytes in a row
R $B6DD C the rows
R $B6DD A the value
  $B6DD,3 the row step
  $B6E0,6 fill a row
  $B6E6,6 on 32 bytes, for the next

# --------------------------------------------------------------------------
# Cutting a move short
# --------------------------------------------------------------------------

@ $B6ED label=ADJ_FOR_OUT_OF_BOUNDS
c $B6ED Cut a move short against the room and the other objects
D $B6ED Every moving object's move comes through here, from #R$B979 and its entry points and from the player's legs (#R$C61D). It takes the step in U, V and Z (+$09 to +$0B) and shortens each where the object would otherwise end up below the floor, through a wall, or inside another object, then writes them back. The code is Knight Lore's (#R$B8E2 and its neighbours are the walls; #R$B742, #R$B791 and #R$B7E0 the objects), with more done when two things meet in Z (#R$B7E0).
D $B6ED The axes are done one at a time, Z first, then U, then V, and each test counts the moves already accepted on the earlier axes and the later ones as zero. That is what lets a blocked move slide: walking diagonally into a wall keeps the part of the move that runs along it.
D $B6ED While it works, bit 1 of +$07 is set, which is what makes the object scans (#R$B99B) pass over the object itself; found already set, it returns at once. Bits 0-2 of +$0C are cleared at the start and set for each axis whose move was cut.
R $B6ED IX the object
  $B6ED,9 not while already set; and ignore ourself while we work
  $B6F6,8 clear the three "stopped" bits
  $B6FE,3 dV and dU count as zero while Z is tested
  $B701,7 H = dZ; nothing to do if zero
  $B708,7 the floor first; nothing left means no objects to test
  $B70F,3 then the other objects
  $B712,7 C = dU; nothing to do if zero
  $B719,7 the walls first; nothing left means no objects to test
  $B720,3 then the other objects
  $B723,7 L = dV; nothing to do if zero
  $B72A,7 the walls first; nothing left means no objects to test
  $B731,3 then the other objects
  $B734,9 the three moves as cut
  $B73D,5 other objects' scans may find us again

@ $B742 label=ADJ_DU_FOR_OBJ_INTERSECT
c $B742 Shorten dU against the other objects
D $B742 Tries the object's box against all 54 records. For each one it already overlaps in V and Z, with the moves accepted so far, an overlap in U after the move means dU has to be shortened, a unit at a time, until the boxes no longer meet; if dU reaches zero the scan stops.
D $B742 Every such meeting sets bit 0 of +$0C and passes harm between the two: bit 6 of +$0D means killed, and the obstacle gets it if the mover has bit 7 (kills what it moves into), the mover if the obstacle has bit 5 (kills what touches it). An obstacle that can be pushed (bit 2 of its +$07) is given the mover's whole intended dU, so it moves off on its own update.
R $B742 IX the moving object
R $B742 C dU
R $B742 L dV so far (zero)
R $B742 H dZ as accepted
R $B742 O:C dU, shortened
  $B742,6 IY = the first record; 54 of them
  $B748,5 empty, or marked to be ignored
  $B74D,10 not overlapping in V, or not in Z
@ $B757 label=DU_OBJ_HIT_TEST
  $B757,5 no overlap in U after the move: the next object
  $B75C,4 stopped in U
  $B760,12 the mover's bit 7 becomes the obstacle's bit 6
  $B76C,9 the obstacle's bit 5 becomes the mover's bit 6
  $B775,12 a pushable obstacle takes on our dU
  $B781,8 a unit shorter; none left, done; else the same object again
@ $B789 label=DU_OBJ_NEXT
  $B789,8 the next of 54

@ $B791 label=ADJ_DV_FOR_OBJ_INTERSECT
c $B791 Shorten dV against the other objects
D $B791 #R$B742 for V: an object has to overlap in U, after the accepted dU, and in Z to be in the way. Stopping sets bit 1 of +$0C; harm passes the same way, and a pushable obstacle takes on the mover's dV.
R $B791 IX the moving object
R $B791 L dV
R $B791 C dU as accepted
R $B791 H dZ as accepted
R $B791 O:L dV, shortened
  $B791,6 IY = the first record; 54 of them
  $B797,5 empty, or marked to be ignored
  $B79C,10 not overlapping in U, or not in Z
@ $B7A6 label=DV_OBJ_HIT_TEST
  $B7A6,5 no overlap in V after the move: the next object
  $B7AB,4 stopped in V
  $B7AF,21 harm passes both ways, as in U
  $B7C4,12 a pushable obstacle takes on our dV
  $B7D0,8 a unit shorter; none left, done; else the same object again
@ $B7D8 label=DV_OBJ_NEXT
  $B7D8,8 the next of 54

@ $B7E0 label=ADJ_DZ_FOR_OBJ_INTERSECT
c $B7E0 Shorten dZ against the other objects
D $B7E0 #R$B742 for Z, done before U and V so it tests the object where it stands: an object has to overlap in U and in V to be above or below it. Stopping sets bit 2 of +$0C, whether the move was up or down, and harm passes as in U.
D $B7E0 Pentagram does more here than Knight Lore. Bit 7 of +$17 is set on the obstacle when the mover is the player's legs or graphic 91 (#R$B890), and on the mover when the obstacle is the player's legs (graphics 32-39): the update routines #R$CDBB, #R$CE31 and #R$D2AD read it (the lift and the bobbing head, measured in staged rooms). An obstacle of graphic 140-143 carries the mover along (#R$B866). The obstacle gets bit 3 of its +$0D, something has met it in Z, as in Knight Lore. And a mover with bit 2 of +$07 gives its intended dZ to the obstacle and, wherever its own dU or dV is zero, takes on the obstacle's, so standing on something that moves carries it along (measured in the simulator: a mover with bit 2 falling on a block moving 3 in U and -1 in V took on both, and the block took the mover's -2 in Z).
R $B7E0 IX the moving object
R $B7E0 H dZ
R $B7E0 C dU, zero here
R $B7E0 L dV, zero here
R $B7E0 O:H dZ, shortened
  $B7E0,6 IY = the first record; 54 of them
  $B7E6,5 empty, or marked to be ignored
  $B7EB,10 not overlapping in U, or not in V
@ $B7F5 label=DZ_OBJ_HIT_TEST
  $B7F5,5 no overlap in Z after the move: the next object
  $B7FA,4 stopped in Z
  $B7FE,3 the player or graphic 91 has met the obstacle
  $B801,15 the obstacle is the player's legs: mark the mover
  $B810,9 graphics 140-143 carry the mover
  $B819,21 harm passes both ways, as in U
  $B82E,4 the obstacle has been met in Z
  $B832,6 not a mover that can be carried
  $B838,6 the obstacle takes our dZ
  $B83E,12 no dU of our own: ride with the obstacle's
  $B84A,12 no dV of our own: ride with the obstacle's
  $B856,8 a unit shorter; none left, done; else the same object again
@ $B85E label=DZ_OBJ_NEXT
  $B85E,8 the next of 54

@ $B866 label=CONVEYOR_PUSH
c $B866 Be carried along by a block of graphic 140-143
D $B866 Called by #R$B7E0 when the object met in Z is one of graphics 140-143. These four share the plain block's sprite but move what meets them, in practice what stands on them: on every other turn (bit 0 of TURNS set) the mover's step gets two units in the direction the graphic's low two bits pick from the table at #R$D30A -- 140 +U, 141 -U, 142 +V, 143 -V. Only the first mover in a turn is pushed: bit 3 of the block's +$0D, set by #R$B7E0 just after this, is cleared only by the block's own update routine (#R$D2DE and its three neighbours).
D $B866 None of this ran in the build's sessions. It was run in the simulator instead: the player's legs falling onto each of the four graphics were given +2 U, -2 U, +2 V and -2 V on an odd turn, nothing on an even one, and nothing with the block's bit 3 already set.
R $B866 A the obstacle's graphic
R $B866 IX the mover
R $B866 IY the block
  $B866,5 something has met the block already this turn
  $B86B,8 DE = the graphic's low two bits, times two
  $B873,7 only on odd turns
  $B87A,19 the table's dU and dV added to the mover's
  $B88D,3 DE and HL back

@ $B890 label=MARK_STOOD_ON
c $B890 Mark the obstacle, if the mover is the player's legs or graphic 91
D $B890 Called by #R$B7E0 when two objects meet in Z. Bit 7 of the obstacle's +$17 says the player or a graphic 91 block (#R$CD75) has met it -- in practice stood on it. #R$CDBB, #R$CE31 and #R$D2AD read and clear it.
R $B890 IX the mover
R $B890 IY the obstacle
  $B890,13 graphic 91, or 32-39: the player's legs
  $B89D,4 mark the obstacle

@ $B8A2 label=DO_OBJS_INTERSECT_ON_U
c $B8A2 Do two objects overlap in U?
D $B8A2 Boxes are centred in U and V, with +$04 and +$05 the half-sizes. They overlap in U if the distance between the centres, after the mover's dU, is less than the two half-sizes added: exactly touching is not overlapping. The distance is taken as a signed byte, so centres 128 or more apart would be misjudged; no room is that big. Also used by #R$BF1B and #R$C0D4.
R $B8A2 IX the moving object
R $B8A2 IY the other object
R $B8A2 C the mover's dU
R $B8A2 O:F carry set if they overlap
  $B8A2,7 D = the two half-sizes
  $B8A9,12 A = |U + dU - the other's U|
  $B8B5,1 carry if less than D

@ $B8B7 label=DO_OBJS_INTERSECT_ON_V
c $B8B7 Do two objects overlap in V?
D $B8B7 #R$B8A2 for V, with the mover's dV in L and the half-sizes at +$05.
R $B8B7 IX the moving object
R $B8B7 IY the other object
R $B8B7 L the mover's dV
R $B8B7 O:F carry set if they overlap
  $B8B7,7 D = the two half-sizes
  $B8BE,12 A = |V + dV - the other's V|
  $B8CA,1 carry if less than D

@ $B8CC label=DO_OBJS_INTERSECT_ON_Z
c $B8CC Do two objects overlap in Z?
D $B8CC Not centred like U and V: Z is an object's base and +$06 its whole height. So the test takes the gap between the two bases, after the mover's dZ, and compares it with the height of whichever object is lower.
R $B8CC IX the moving object
R $B8CC IY the other object
R $B8CC H the mover's dZ
R $B8CC O:F carry set if they overlap
  $B8CC,10 A = Z + dZ - the other's Z; the mover higher, use the other's height
  $B8D6,5 the mover lower: the distance, and its own height
  $B8DB,1 carry if the gap is less than the lower one's height
  $B8DD,5 the other's height

@ $B8E2 label=ADJ_DU_FOR_OUT_OF_BOUNDS
c $B8E2 Shorten dU at the walls
D $B8E2 Keeps the object's whole footprint within the room: its U, after the move, no further from 128 than the room's U half-size (the first byte of ROOM_EXTENT, 64 or 32) less its own half-size. dU is shortened a unit at a time, and bit 0 of +$0C set if it had to be (measured: an object with half-size 4 at 90 from the centre of a room of half-size 96, asked to move 5, moved 1).
D $B8E2 Two things switch the walls off, as in Knight Lore: a count in the top four bits of +$0C, which the player's routine (#R$C440) runs down by one a turn, and bit 0 of +$07, which #R$C802 sets on the player near a doorway. That is how he walks through one at all.
R $B8E2 IX the object
R $B8E2 C dU
R $B8E2 O:C dU, shortened
  $B8E2,6 not while the count in +$0C runs
  $B8E8,5 not near a doorway
  $B8ED,4 B = the room's U half-size
@ $B8F1 label=CLIP_DU_TO_WALLS
  $B8F1,10 A = |U + dU - 128|
  $B8FB,6 inside if that plus the half-size is less than the room's: done
  $B901,4 stopped in U
  $B905,7 a unit shorter, and again unless nothing is left

@ $B90D label=ADJ_DV_FOR_OUT_OF_BOUNDS
c $B90D Shorten dV at the walls
D $B90D #R$B8E2 for V: the room's V half-size from the second byte of ROOM_EXTENT, the object's at +$05, and bit 1 of +$0C.
R $B90D IX the object
R $B90D L dV
R $B90D O:L dV, shortened
  $B90D,6 not while the count in +$0C runs
  $B913,5 not near a doorway
  $B918,4 B = the room's V half-size
@ $B91C label=CLIP_DV_TO_WALLS
  $B91C,10 A = |V + dV - 128|
  $B926,6 inside if that plus the half-size is less than the room's: done
  $B92C,4 stopped in V
  $B930,7 a unit shorter, and again unless nothing is left

# --------------------------------------------------------------------------
# Where an object is on the screen
# --------------------------------------------------------------------------

@ $B938 label=CALC_2D_INFO
c $B938 Work out an object's screen rectangle
D $B938 Fills in where an object's sprite lands in the screen buffer: the pixel position at +$1A and +$1B (#R$B2C5), and the size at +$18, the width in bytes, one more when the pixel x is not a multiple of 8, and +$19, the height in rows, not cut at the top of the screen as #R$B3D3 cuts it. #R$B2EE also turns the sprite the way the object faces.
D $B938 When the object's sprite is the empty one (graphics 0 and 1 use it), #R$B2EE returns straight to this routine's caller, and +$18 and +$19 keep what they held: the area the object last covered is still the area to clear.
R $B938 IX the object
  $B938,6 the pixel position; DE = the sprite, turned the way the object faces
  $B93E,10 the width, and one more for a shifted sprite
  $B948,5 +$18: the width in bytes
  $B94D,5 +$19: the height

@ $B952 label=READ_KEYS
c $B952 Read a half-row of the keyboard
D $B952 Knight Lore's routine, byte for byte. The IN does the selecting on its own: IN A,($FE) puts A on the top half of the address bus, so each 0 bit in A selects a half-row. The CPL turns the keys' active-low bits the right way up.
D $B952 The OUT before it is not needed for the read. It writes A to port A*256+$FD, which nothing on a 48K Spectrum answers. A 128K machine's paging port would decode it whenever A has bit 7 clear, and the first such write comes as soon as the keyboard is read: $7F from the keyboard read in #R$BDF8 (RAM page 7), or $7E from a joystick's (#R$BEFD) and from #R$B4E0 every turn (page 6). In 128 mode that would put another RAM page at the top 16K, where much of the game lives, show the other screen and lock the paging. Tried on the emulator's 128K, from a 128K snapshot: at the first turn of play $7F went to the paging port, bank 7 appeared at the top, the paging locked, and the machine reset (the menu tune's key test had already paged the editor ROM in).
R $B952 A the half-rows to read, as the port's high byte
R $B952 O:A the keys pressed, bits 0-4, a set bit for a key down

# --------------------------------------------------------------------------
# Moving
# --------------------------------------------------------------------------

@ $B95A label=SHORTEN_DELTA
c $B95A Shorten a move by one unit
D $B95A Moves A one step towards zero -- down if positive, up if negative -- and leaves Z set if nothing is left. Every loop in the collision code uses it to cut a move short a unit at a time and try again.
R $B95A A a dU, dV or dZ
R $B95A O:A one unit closer to zero; Z set if zero
  $B95A,2 already zero
  $B95C,5 negative: +2 here and -1 below
@ $B961 label=SHORTEN_DELTA_DEC
  $B961,1 the step down that sets Z

@ $B963 label=ADJ_DZ_FOR_OUT_OF_BOUNDS
c $B963 Shorten dZ at the floor
D $B963 The floor is the only limit on Z: there is no ceiling. The floor's height is the third byte of ROOM_EXTENT, 128 in all three room sizes. A move that would take the object's base below it is shortened a unit at a time until it would not, and bit 2 of +$0C records that the move was stopped.
R $B963 IX the object
R $B963 H dZ
R $B963 O:H dZ, shortened
  $B963,4 D = the floor
@ $B967 label=CLIP_DZ_TO_FLOOR
  $B967,6 Z + dZ at or above the floor: done
  $B96D,4 stopped in Z
  $B971,7 a unit shorter, and again unless nothing is left

@ $B979 label=DEC_DZ_AND_UPDATE_UVZ
c $B979 Fall, and move
D $B979 Takes one off dZ -- the pull of gravity -- then lets #R$B6ED cut the step down to what fits, and adds what is left to the position. Most update routines come in at CLIP_AND_MOVE, to move without falling; the player's legs come in at ADD_DUVZ, having cut the move themselves (#R$C61D).
R $B979 IX the object
  $B979,3 gravity
@ $B97C label=CLIP_AND_MOVE
  $B97C,3 cut the move short where it has to be
@ $B97F label=ADD_DUVZ
  $B97F,28 U, V and Z (+$01 to +$03) plus the step in each (+$09 to +$0B)

@ $B99B label=IS_OBJECT_NOT_IGNORED
c $B99B Does this object take part in collisions?
D $B99B Z set for an empty record, or one with bit 1 of +$07 set: the object moving now (#R$B6ED sets it on itself), or one marked to be passed over.
R $B99B IY the object
R $B99B O:F Z set if it is to be skipped
  $B99B,5 an empty record
  $B9A0,7 bit 1 of the flags

# --------------------------------------------------------------------------
# Marking what has to be redrawn
# --------------------------------------------------------------------------

@ $B9A7 label=SET_DRAW_OBJS_OVERLAPPED
c $B9A7 Mark every object the moving object's old or new rectangle touches
D $B9A7 Called once an object has moved or changed its sprite: by the player's body (#R$C5D3), and by every update routine that ends in the tail of #R$CC4B, which sets bits 4 and 5 of the object's +$07 first. It works out the object's new screen rectangle (#R$B938), forms the smallest rectangle covering that and the one it had at the start of the turn (+$1C to +$1F, copied there by the main loop), and walks all 54 records setting the draw flag, bit 4 of +$07, on every live object whose rectangle meets it -- the moving object itself included.
D $B9A7 Across, the rectangles are measured in byte columns (pixel x over 8); up, in pixel rows from the bottom of the screen. E is the union's first column and D its width in columns; L its lowest row and H its height. Only the moving object's rectangle is used: an object redrawn because it meets it does not in turn mark the objects that meet it.
R $B9A7 IX the object that has moved
  $B9A7,7 IY = the first record; the new rectangle into +$18 to +$1B
  $B9AE,2 54 records
  $B9B0,9 L = the new first column
  $B9B9,9 H = the old first column
  $B9C2,5 E = whichever is further left
  $B9C7,15 D = the further right-hand edge, less E: the width in columns
  $B9D6,12 L = the lower of the two bottom rows
  $B9E2,19 H = the higher of the two tops, less L: the height
@ $B9F5 label=OVERLAP_TEST_OBJ
  $B9F5,6 an empty record: next
  $B9FB,6 already to be drawn: next
  $BA01,11 its first column, less E; left of the union, see below
  $BA0C,3 not left of the union: it meets it across if it starts inside
  $BA0F,6 its bottom row, less L; below the union, see below
  $BA15,3 not below: it meets it up and down if it starts inside
  $BA18,4 draw it this turn
  $BA1C,10 the next record, DE kept across the step
  $BA26,7 to the left: it meets the union if the union starts inside its width
  $BA2D,7 below: it meets the union if the union starts inside its height

# --------------------------------------------------------------------------
# The panel
# --------------------------------------------------------------------------

@ $BA34 label=SHOW_CARRIED
c $BA34 Show the carried things on the panel, if they have changed
D $BA34 Called every turn by #R$B19E; it acts only when PANEL_DUE is set, as #R$BF79 sets it when what he carries changes. The main loop comes in at SHOW_CARRIED_NOW on entering a room, to draw them regardless.
D $BA34 The panel shows three of the four carried entries, CARRIED_SHOWN's two and CARRIED_LAST (four bytes each: the graphic first), in three boxes 24 pixels square along the bottom of the screen, at pixel x 16, 40 and 64. For each, the box is cleared in the screen buffer, the thing's sprite drawn there through the spare record at #R$BACA (DRAW_SPRITE in #R$B3D3, with no projection, and no flip bits so the sprite is turned back to face its stored way), and the box copied to the screen (#R$B278); then its three by three attribute cells are coloured by the graphic's low three bits, from #R$BAC2. An empty entry is cleared, and coloured as if graphic 0.
  $BA34,9 nothing has changed; or clear the flag
@ $BA3D label=SHOW_CARRIED_NOW
  $BA3D,11 IX = the spare record; three boxes; HL = the first entry shown
  $BA48,22 the box's pixel x: 16 + 24 times its number
  $BA5E,4 pixel y 0: the bottom of the screen
  $BA62,19 clear three bytes by 24 rows of the buffer
  $BA75,11 something there: its sprite into the buffer
  $BA80,20 copy the box from the buffer to the screen
  $BA94,15 C = the colour for the entry's graphic
  $BAA3,12 DE = the attribute address of the box's top row
  $BAAF,8 colour three cells by three
  $BAB7,8 the next entry, four bytes on
  $BABF,3 IX back

@ $BAC2 label=CARRIED_COLOURS
b $BAC2 The colours of the carried things
D $BAC2 Eight attributes, indexed by the low three bits of a carried thing's graphic (#R$BA34): bright ink on black, blue, red, magenta, green, cyan, yellow, white and white again. sna2ctl took them for text, since they are the codes of eight capital letters.
B $BAC2,8,8

@ $BACA label=PANEL_RECORD
s $BACA A spare object record, for drawing on the panel
D $BACA Never one of the room's objects: #R$BA34 draws the carried things through it, #R$C29A the lives icon and #R$BCE5 another picture on the panel. They set its graphic (+0), its flags (+$07) and its pixel position (+$1A, +$1B), and DRAW_SPRITE (#R$B3D3) writes +$18 and +$19. Zero on the tape.

@ $BAEA label=PRINT_CHAR
c $BAEA Print a character into the screen buffer
D $BAEA A character is eight bytes from FONT_BASE plus eight times its code, the top row first; they overwrite eight rows of the buffer going down from HL (32 bytes a row, down being towards the start of the buffer). HL comes back one byte to the right, on the same top row, ready for the next character. A space is printed as code $3D.
D $BAEA For text FONT_BASE is 384 bytes below the font (#R$BC66), so the codes $30 to $5A land in it; for numbers it is the font itself (PRINT_BCD, in #R$BB29), so that digits are codes 0 to 9.
R $BAEA A the code
R $BAEA HL the buffer address of the character's top row
R $BAEA O:HL one byte to the right
  $BAED,6 a space is code $3D
  $BAF3,12 DE = FONT_BASE + 8 * the code
  $BB00,13 eight rows, each written 32 bytes below the one before
  $BB0E,4 back up the eight rows and one byte right

@ $BB14 label=PRINT_SCORE
c $BB14 Print the score, with its heading, on the panel
D $BB14 Called when a game or a room starts (#R$AF87) and again by the main loop after it has shown a new room (#R$B00C), since filling the attributes with the room's colour there has painted over the heading's. The heading goes into the buffer at pixel x 192, pixel y 31, in bright white (#R$BC66 writes the attributes to the screen as it goes); the six digits into the buffer below it at pixel x 184, pixel y 16.
  $BB14,14 the heading, in bright white
  $BB22,2 the digits

@ $BB24 label=SCORE_TEXT
t $BB24 The score's heading
D $BB24 One word, printed by #R$BB14; the text ends with bit 7 set on the last letter, which sna2ctl left as a byte on its own (#R$BB28).
T $BB24,4

@ $BB28 label=SCORE_TEXT_END
b $BB28 The last letter of the score's heading
D $BB28 With bit 7 set: the end of #R$BB24.
B $BB28,1

@ $BB29 label=ADD_SCORE
c $BB29 Add BC to the score, in BCD, and print it
D $BB29 C goes into the last two digits (the third byte of SCORE), B with the carry into the middle two and the carry into the first two. The score is then printed into the buffer; the only caller, #R$C264, copies it to the screen with #R$B145.
D $BB29 The entry point PRINT_BCD prints B bytes of BCD at DE, two digits each, into the buffer at HL; PRINT_BCD_LSD starts with only the second digit of the first byte. #R$C29A prints the lives with the first, #R$C6EA the percentage with both.
R $BB29 BC the points, BCD
  $BB29,7 the last two digits
  $BB30,5 the middle two, with the carry
  $BB35,6 the first two
@ $BB3B label=PRINT_SCORE_DIGITS
  $BB3B,13 HL = the buffer at pixel x 184, pixel y 16; three bytes from SCORE
@ $BB48 label=PRINT_BCD
  $BB48,8 the font's own address as the base: digits are codes 0-9
  $BB50,10 the first digit, from the high four bits
@ $BB5A label=PRINT_BCD_LSD
  $BB5A,6 the second, from the low four
  $BB60,4 the next byte

# --------------------------------------------------------------------------
# The menu
# --------------------------------------------------------------------------

@ $BB64 label=TOGGLE_SELECTED
c $BB64 Flash one of B attributes, and steady the rest
D $BB64 Sets bit 7, FLASH, on the A'th of B attribute bytes from HL, counting from 0, and clears it on the others. #R$BBD8 marks the chosen control method on the menu with it. This entry deals with the first byte; the loop is #R$BB6B. HL comes back just past the last byte.
R $BB64 HL the first attribute
R $BB64 B how many
R $BB64 A which one flashes
  $BB64,3 not the first
  $BB67,4 flash this one

@ $BB6B label=FLASH_NEXT_ONE
c $BB6B The rest of #R$BB64
D $BB6B Counts A down a byte at a time, flashing the byte where it reaches zero.
  $BB6B,3 this is the one
  $BB6E,2 steady
  $BB70,4 the next byte, until B runs out

@ $BB74 label=MENU
c $BB74 The menu
D $BB74 Called by #R$AF87 before every game. It stops every line's flash, clears the buffer, draws the menu's text and frame (#R$BCB4, which draws the frame and shows the buffer only the first time, as the flag cleared here tells it) and flashes the chosen control method (#R$BBD8). Then round a loop: print the text again (its attributes, with the flashing, go straight to the screen), play the tune if it has not been heard (#R$D69C, which a key cuts short), and read the keys.
D $BB74 Keys 1 to 4 set bits 1 and 2 of CONTROL to 0 keyboard, 1 Kempston, 2 cursor, 3 Interface II, and key 0 starts the game. If several are held the highest wins, since each is applied in turn. Key 5 is not read, and nothing here sets bit 3 of CONTROL, though #R$BBD8 flashes a sixth line of the menu when it is set.
D $BB74 Two leftovers do nothing: HL is loaded with one variable's address and at once with another's, and the CP after them sets flags nothing reads -- perhaps a test, once, for whether the choice had changed.
  $BB74,4 the menu's frame is still to be drawn
  $BB78,10 no line flashing; the loop takes in the byte after the seven attributes as well, whose bit 7 is clear anyway
  $BB82,9 a clear buffer; the text, the frame and the choice
  $BB8B,9 the text again; the tune, once
  $BB94,12 the keys 1 to 5; CONTROL as it was, into CONTROL_BEFORE
  $BBA0,6 1: keyboard
  $BBA6,8 2: Kempston
  $BBAE,8 3: cursor keys
  $BBB6,6 4: Interface II
  $BBBC,3 the new choice
  $BBBF,7 leftovers: a load at once overwritten, and a compare nothing reads
  $BBC6,8 key 0: start
  $BBCE,4 count the passes
  $BBD2,6 flash the choice; round again

# --------------------------------------------------------------------------
# Range 3
# --------------------------------------------------------------------------

# --------------------------------------------------------------------------
# The menu's lines and the text printer ($BBD8-$BCB3)
# --------------------------------------------------------------------------

@ $BBD8 label=FLASH_MENU
c $BBD8 Flash the chosen control method's line on the menu
D $BBD8 Sets the FLASH bit on the colour of the line for the method in bits 1-2 of CONTROL and clears it on the other three (#R$BB64), then clears it on the next colour and sets it again if bit 3 of CONTROL is set. That next colour is the "0 START GAME" line's: Knight Lore's menu (flash_menu) has a line for directional control there, which bit 3 selects, and Pentagram kept the code but not the line. No menu choice sets bit 3, so the start line never flashes from here.
D $BBD8 The colours are the first bytes of #R$BBF1; the title's, the first, is left alone. #R$BB74 calls this once before its loop and again after every pass, and the flash reaches the screen when #R$BCB4 rewrites the attributes.
  $BBD8,3 the colour of the "1 KEYBOARD" line, the second in #R$BBF1
  $BBDB,11 flash the Ath of the four method lines, A the method from bits 1-2 of CONTROL
  $BBE6,2 HL is now on the start line's colour: no flash...
  $BBE8,9 ...unless bit 3 of CONTROL (directional control) is set; this never ran in the build's sessions

@ $BBF1 label=MENU_COLOURS
b $BBF1 The menu: the colour of each line
D $BBF1 The menu's three tables run on from here as one block: seven colours, one per line (this entry's first seven bytes); seven (x, y) pixel positions from the eighth byte (MENU_XY), y counting up from the bottom of the screen; and the seven strings from the fifth byte of #R$BC02 (MENU_TEXT) to #R$BC65, ASCII with bit 7 set on the last character of each. #R$BCB4 hands the three addresses to its list printer, DISPLAY_TEXT_LIST. The bytes are split into several entries only because the code map could not see where the text starts.
D $BBF1 The colours are bright magenta for the title, bright green for the four control methods and bright white for the start and copyright lines. #R$BBD8 sets bit 7 (FLASH) of the chosen method's; #R$BB74 clears bit 7 of eight bytes from here before the menu is drawn, one more than there are lines, as Knight Lore's menu has eight.
B $BBF1,8,7,1 The seven lines' colours; then the title's x, 88 (character column 11), the first byte of the positions
@ $BBF8 label=MENU_XY

@ $BBF9 label=MENU_Y_TITLE
b $BBF9 The menu: where the lines go (the title's y; keys 1 and 2)
D $BBF9 The positions go on from MENU_XY, #R$BBF1's last byte, an (x, y) pair per line. The option lines start at x 48, character column 6, and step down 16 pixels, two character rows, from y 143.
B $BBF9,5,1,2,2 The title's y (159, character row 4); "1 KEYBOARD" at (48, 143); "2 KEMPSTON JOYSTICK" at (48, 127)

@ $BBFE label=MENU_XY_KEY3
b $BBFE The menu: where the lines go (key 3; key 4's x)
B $BBFE,3,2,1 "3 CURSOR JOYSTICK" at (48, 111); x of "4 INTERFACE II"

@ $BC01 label=MENU_Y_KEY4
b $BC01 The menu: where the lines go (key 4's y)
B $BC01,1 y of "4 INTERFACE II": 95

@ $BC02 label=MENU_XY_START
b $BC02 The menu: where the lines go (start, copyright), and the title's first eight letters
D $BC02 The last two positions, then the menu's strings begin, at MENU_TEXT, the fifth byte of this entry.
B $BC02,12,2,2,c8 "0 START GAME" at (48, 63); the copyright line at (80, 39); then the first string, the title, PENTAGRAM, up to its last letter
@ $BC06 label=MENU_TEXT

@ $BC0E label=MENU_TITLE_LAST
b $BC0E The menu: the title's last letter
B $BC0E,1,c1 M, with bit 7 set to end the string

@ $BC0F label=MENU_KEYBOARD
t $BC0F The menu: "1 KEYBOARD"

@ $BC18 label=MENU_KEYBOARD_LAST
b $BC18 The menu: "1 KEYBOARD", its last letter
B $BC18,1,c1 D, with bit 7 set

@ $BC19 label=MENU_KEMPSTON
t $BC19 The menu: "2 KEMPSTON JOYSTICK"

@ $BC2B label=MENU_KEMPSTON_LAST
b $BC2B The menu: "2 KEMPSTON JOYSTICK", its last letter
B $BC2B,1,c1 K, with bit 7 set

@ $BC2C label=MENU_CURSOR
t $BC2C The menu: "3 CURSOR JOYSTICK"
D $BC2C Three spaces after CURSOR line JOYSTICK up with the line above.

@ $BC3E label=MENU_CURSOR_LAST
b $BC3E The menu: "3 CURSOR JOYSTICK", its last letter
B $BC3E,1,c1 K, with bit 7 set

@ $BC3F label=MENU_INTERFACE
t $BC3F The menu: "4 INTERFACE II"

@ $BC4C label=MENU_INTERFACE_LAST
b $BC4C The menu: "4 INTERFACE II", its last letter
B $BC4C,1,c1 I, with bit 7 set

@ $BC4D label=MENU_START
t $BC4D The menu: "0 START GAME"

@ $BC58 label=MENU_START_LAST
b $BC58 The menu: "0 START GAME", its last letter
B $BC58,1,c1 E, with bit 7 set

@ $BC59 label=MENU_COPYRIGHT
t $BC59 The menu: the copyright line
D $BC59 Reads on the screen as a copyright sign, then "1986 A.C.G.": the font (#R$8355) draws the copyright sign for the code of the less-than sign, and a full stop for the colon.

@ $BC65 label=MENU_COPYRIGHT_LAST
b $BC65 The menu: the copyright line's last character
B $BC65,1,c1 The last full stop (a colon in the code), with bit 7 set

@ $BC66 label=PRINT_TEXT_SINGLE_COLOUR
c $BC66 Print a string in one colour
R $BC66 HL the position: L = x, H = y, in pixels, y counting up from the bottom of the screen
R $BC66 DE the string, ASCII with bit 7 set on the last character
R $BC66 O:DE the byte after the string
D $BC66 Prints into the screen buffer (#R$D88F) in the text font, colouring each character's cell directly in the attribute file with PRINT_ATTR. Each character covers the pixel rows from y down to y-7. As Knight Lore's print_text_single_colour, instruction for instruction.
  $BC66,7 the text font: FONT_BASE is 384 bytes below the font at #R$8355, so that the code of a letter lands on its glyph
  $BC6D,7 BC = the position again, left on the stack for #R$BC8B; HL = its address in the buffer (#R$B37F)
  $BC74,6 the colour goes into A'

@ $BC7A label=PRINT_TEXT_STD_FONT
b $BC7A Unreached code: print a string that starts with its colour byte
D $BC7A These bytes are the Z80 code of Knight Lore's print_text_std_font and print_text: select the text font, work out the buffer address, and take the colour from the string's first byte, running on into #R$BC8B. Nothing in Pentagram calls them, and they never ran in the build's sessions, so the code map leaves them as data; the comments give the instructions they encode. Pentagram's strings carry no colour byte: #R$BC66 takes the colour from PRINT_ATTR instead.
B $BC7A,8,1,3,3,1 PUSH HL; LD HL, the text font's base; LD into FONT_BASE; POP BC
B $BC82,8,1,3,1,1,1,1 PUSH BC; CALL #R$B37F; LD L,C; LD H,B; LD A,(DE), the colour byte; EX AF,AF'
B $BC8A,1 INC DE, past the colour byte, then on into #R$BC8B

@ $BC8B label=TEXT_ATTR_ADDR
c $BC8B Find the string's first attribute cell, and print the string
R $BC8B HL the string's address in the buffer
R $BC8B DE the string
R $BC8B A' the colour
D $BC8B The rest of #R$BC66. The position is on the stack. In the alternate registers HL' becomes the attribute address of the first cell, while DE' is kept: the list printer in #R$BCB4 walks its list of colours with it. Then each character is drawn into the buffer by #R$BAEA, which leaves HL one cell to the right, and its cell in the attribute file is given the colour.
E $BC8B The PUSH DE and POP DE round each call of #R$BAEA are not needed: it keeps DE itself.
  $BC8B,2 take the position off the stack into HL'
  $BC8D,7 HL' = the attribute address of the position (#R$B3B6); DE' kept
@ $BC94 label=PRINT_TEXT_CHAR
  $BC94,6 bit 7 marks the last character
  $BC9A,6 draw it, and move on in the string
  $BCA0,7 colour its cell, one cell right, and loop
@ $BCA7 label=PRINT_TEXT_LAST
  $BCA7,8 the last character, without its end marker; DE ends past the string
  $BCAF,5 colour its cell

# --------------------------------------------------------------------------
# Screens: the menu, the panel, the border ($BCB4-$BDF7)
# --------------------------------------------------------------------------

@ $BCB4 label=DISPLAY_MENU
c $BCB4 Draw the menu
D $BCB4 Hands DISPLAY_TEXT_LIST, at the end of this routine, the menu's seven colours (#R$BBF1), positions and strings. Called at the start of the menu and on every pass of its loop (#R$BB74).
  $BCB4,4 DE' = the colours
  $BCB8,3 HL = the positions, MENU_XY
  $BCBB,3 DE = the strings, MENU_TEXT
  $BCBE,2 seven lines
@ $BCC0 label=DISPLAY_TEXT_LIST
N $BCC0 Print a list of strings. B how many; DE' their colours, a byte each; HL their positions, an (x, y) pair each; DE the strings, end to end. Also used by #R$C302.
  $BCC0,7 this string's colour into PRINT_ATTR, for #R$BC66
  $BCC7,8 L = x, H = y; HL moved on to the next pair and kept
  $BCCF,7 print it, and loop
  $BCD6,5 the first list since the screen-shown flag (FRAME_DRAWN) was cleared...
  $BCDB,4 ...sets it...
  $BCDF,6 ...draws the border (#R$BD59) and shows the whole buffer (#R$B178); later lists only redraw into the buffer and write the attributes, which is how the menu's flashing line changes without the screen being redrawn

@ $BCE5 label=DISPLAY_PANEL
c $BCE5 Draw the scroll-work at the foot of the screen
D $BCE5 Draws the panel's pieces from #R$BD31 through the spare record at #R$BACA: a slanting run of five of graphic 62 on each side, stepping 16 pixels in and 8 down, four pieces up each edge, and four single pieces, the left side the right mirrored. The lives (#R$C29A), the score (#R$BB14) and the three carried things (#R$BA34) go in the spaces it leaves. Called from the main loop (#R$B00C) when a room has just been drawn, before the whole buffer is shown; it takes its colour from the room's, which the main loop has just filled the attributes with.
  $BCE5,10 IX = the spare record; the first entry
@ $BCEF nowarn
@ $BCFA nowarn
  $BCEF,8 the left run: five pieces, each 16 pixels right and 8 down
  $BCF7,11 the right run: five, each 16 left and 8 down
  $BD02,11 two up the left edge, 32 pixels apart
  $BD0D,8 two up the right edge
  $BD15,16 two more on each edge, between them
  $BD25,12 the four single pieces

@ $BD31 label=PANEL_DATA
b $BD31 The pieces of the panel's scroll-work
D $BD31 Ten entries of four bytes, as #R$BDC0 reads them: the graphic, the flags (bit 6 mirrored, bit 7 upside down), then x and y in pixels, y counting up from the bottom. #R$BCE5 draws some once and repeats others along a line. Each line here is a left and right pair.
B $BD31,8,4 Graphic 62 mirrored at (16, 52), and plain at (224, 52): the two slanting runs, five each
B $BD39,8,4 Graphic 61 mirrored at (0, 4), and plain at (240, 4): two each up the edges
B $BD41,8,4 Graphic 60 mirrored at (0, 20), and plain at (240, 20): two each, between those (60 and 61 share a sprite)
B $BD49,8,4 Graphic 58 mirrored at (96, 4), and plain at (144, 4): once each
B $BD51,8,4 Graphic 59 mirrored at (0, 52), and plain at (240, 52): once each

@ $BD59 label=PRINT_BORDER
c $BD59 Draw the border round the screen
D $BD59 From #R$BD98, into the buffer through the spare record at #R$BACA: the corner sprite drawn four times, turned each way, the top and bottom edges as eight pieces 24 pixels apart and a shorter one to close each, and the sides as six pieces 24 pixels apart. It frames the menu and the end screens (#R$BCB4, #R$C302); a room has none.
  $BD59,19 the four corners
  $BD6C,11 the top edge: eight pieces, 24 pixels apart
  $BD77,8 the bottom edge
  $BD7F,6 the short pieces that close the top and bottom
  $BD85,11 the left edge: six pieces, 24 pixels apart going up
  $BD90,8 the right edge

@ $BD98 label=BORDER_DATA
b $BD98 The pieces of the border
D $BD98 Ten entries of four bytes, as in #R$BD31: graphic, flags (bit 6 mirrored, bit 7 upside down), x, y. The screen is 256 by 192 and the pieces 24 pixels wide, so the right-hand ones are at x 232 and the top ones at y 168.
B $BD98,8,4 Graphic 5, the corner, at (0, 168); mirrored at (232, 168)
B $BDA0,8,4 Graphic 5 mirrored and upside down at (232, 0); upside down at (0, 0)
B $BDA8,8,4 Graphic 4 at (24, 168), the top edge's first; upside down at (24, 0), the bottom's
B $BDB0,8,4 Graphic 3 at (216, 168), closing the top edge; upside down at (216, 0)
B $BDB8,8,4 Graphic 2 at (0, 24), the left edge's first; mirrored at (232, 24), the right's

@ $BDC0 label=TRANSFER_SPRITE
c $BDC0 Copy a sprite's four bytes into the drawing record
R $BDC0 HL the four-byte entry
R $BDC0 IX the record to draw with, the spare one at #R$BACA
R $BDC0 O:HL the next entry
D $BDC0 Graphic, flags, x and y into +0, +7, +$1A and +$1B, where the sprite drawing (DRAW_SPRITE, in #R$B3D3) finds them. As Knight Lore's transfer_sprite.
  $BDC0,5 the graphic
  $BDC5,5 the flags: bit 6 mirrored, bit 7 upside down
  $BDCA,10 x and y, in pixels

@ $BDD5 label=TRANSFER_SPRITE_AND_PRINT
c $BDD5 Copy a sprite's four bytes and draw it
R $BDD5 HL the four-byte entry
R $BDD5 IX the record to draw with
R $BDD5 O:HL the next entry
D $BDD5 #R$BDC0, then DRAW_SPRITE (#R$B3D3), keeping HL on the next entry.

@ $BDDE label=MULTIPLE_PRINT_SPRITE
c $BDDE Draw a sprite several times in a line
R $BDDE IX the record, loaded by #R$BDC0
R $BDDE B how many times
R $BDDE E the step in x between copies
R $BDDE D the step in y between copies
D $BDDE Used to build the border and the panel out of repeated pieces. As Knight Lore's multiple_print_sprite.
  $BDDE,9 draw it, keeping the registers
  $BDE7,14 move the record's x by E and y by D
  $BDF5,2 and again

# --------------------------------------------------------------------------
# Controls ($BDF8-$BF0C)
# --------------------------------------------------------------------------

@ $BDF8 label=READ_CONTROLS
c $BDF8 Read the controls into INPUT
R $BDF8 O:A the controls: bit 0 turn left, 1 turn right, 2 walk, 3 jump, 4 pick up or put down, 6 fire
R $BDF8 O:C the same
D $BDF8 Reads the keyboard or a joystick, by the method in bits 1-2 of CONTROL, into one byte for this turn, kept in INPUT for the rest of the turn's code (#R$BF66, #R$C126). Bit 5 is never set, nor bit 7.
D $BDF8 The keyboard: Z, C, M and B turn left and X, V, SYMBOL SHIFT and N right; the whole of the A-G and H-ENTER rows walk; Q, E, T, U and O jump; W, R, Y, I and P fire; any number key picks up or puts down. Every key in a half-row does the same, except the top letter row, which is shared between jump and fire key by key. SPACE and CAPS SHIFT do nothing here; #R$B4E0 reads SPACE for the pause.
D $BDF8 A joystick: left and right turn, up walks, down jumps and fire fires, and any key on the bottom row but CAPS SHIFT and SPACE picks up or puts down. The Kempston stick is read from port 31; the cursor keys are 5 left, 8 right, 7 up, 6 down and 0 fire; Interface II is the 6-0 keys for one stick and 1-5 for the other, read together. Knight Lore's joysticks also had direction controls with pick-up moved to bit 5; Pentagram offers neither.
  $BDF8,15 bits 1-2 of CONTROL: 0 keyboard, 1 Kempston, 2 cursor keys...
N $BE07 Interface II: its two sticks are the keys 6-0 and 1-5.
  $BE07,16 ...3 Interface II: keys 1-5, their order reversed into C, so that 5 is bit 0 and 1 is bit 4, the same as 0 and 6 on the other half-row
  $BE17,6 OR in keys 6-0: bit 0 fire (0 or 5), 1 up (9 or 4), 2 down (8 or 3), 3 right (7 or 2), 4 left (6 or 1)
  $BE1D,8 fire
  $BE25,6 up: walk
  $BE2B,6 down: jump
  $BE31,6 right: turn right
  $BE37,9 left: turn left; then the bottom row for pick-up
@ $BE40 label=READ_KEMPSTON
N $BE40 The Kempston joystick: bit 0 right, 1 left, 2 down, 3 up, 4 fire.
  $BE40,10 right: turn right
  $BE4A,6 left: turn left
  $BE50,6 down: jump
  $BE56,6 up: walk
  $BE5C,9 fire; then the bottom row for pick-up
@ $BE65 label=READ_CURSOR
N $BE65 The cursor keys: 5 left, 6 down, 7 up, 8 right, 0 fire.
  $BE65,13 5: turn left
  $BE72,11 0: fire
  $BE7D,6 7: walk
  $BE83,6 8: turn right
  $BE89,8 6: jump; then the bottom row for pick-up
@ $BE91 label=READ_KEYBOARD
N $BE91 The keyboard.
  $BE91,17 CAPS SHIFT to V: bits 1 and 2 (Z and X) and bits 3 and 4 (C and V) are both brought down to bits 0 and 1, turn left and turn right; CAPS SHIFT is dropped
  $BEA2,11 SYMBOL SHIFT or N turns right...
  $BEAD,6 ...M turns left...
  $BEB3,6 ...N turns right...
  $BEB9,6 ...B turns left
  $BEBF,9 any key on the A-G or H-ENTER rows (both half-rows read at once): walk
  $BEC8,10 O or U: jump
  $BED2,12 or Q, E or T: jump
  $BEDE,9 any number key (both half-rows at once): pick up or put down
  $BEE7,9 P, I or Y: fire
  $BEF0,13 or W or R: fire; done, without the bottom row
@ $BEFD label=READ_BOTTOM_ROW
  $BEFD,11 the joysticks: any of Z, X, C, V, SYMBOL SHIFT, M, N and B (both half-rows at once, bits 1-4) picks up or puts down
  $BF08,5 this turn's controls into INPUT, and in A and C

@ $BF0D label=CLEAR_COPY_BITS
c $BF0D Clear bit 5 of every object's flags
D $BF0D Bit 5 of +7 asks #R$B19E to copy the object's part of the buffer to the screen. The main loop (#R$B00C) calls this after drawing a new room and copying the whole buffer to the screen at once, so that no object's part is copied again.
  $BF0D,8 all 54 records, from the flags (+7) of the first
  $BF15,5 clear bit 5 of each

# --------------------------------------------------------------------------
# Picking up and putting down ($BF1B-$C106)
# --------------------------------------------------------------------------

@ $BF1B label=DO_ANY_OBJS_INTERSECT
c $BF1B Does this object overlap any other?
R $BF1B IX the object
R $BF1B O:F carry set if another object's box overlaps IX's where it stands
R $BF1B O:IY the one it overlaps, when carry is set
D $BF1B Tests IX against all 54 records with the tests on each axis at #R$B8A2, #R$B8B7 and #R$B8CC, with no offset on any axis. Empty records are skipped, and so is any with bit 1 of its flags set (#R$B99B) -- which is how IX avoids finding itself: it sets its own bit 1 for the duration. Used by #R$BF79 to see whether there is room above the player's head, by #R$B097 as it puts the quest's things in a room, and by #R$CBAB as something falls from the sky. As Knight Lore's do_any_objs_intersect.
E $BF1B The exit clears IX's bit 1 whatever it was before, as Knight Lore's does.
  $BF1B,11 save the registers; IY walks all 54 records
  $BF26,8 no offset on U, V or Z; and IX out of its own way
  $BF2E,5 empty, or out of collisions: next
  $BF33,15 overlapping in U, V and Z: found, with carry set
  $BF42,10 put the registers back and IX's bit 1 clear; the carry is kept
  $BF4C,10 next record; none: clear carry

@ $BF56 label=SET_WIPE_AND_DRAW_IY
c $BF56 Mark the object at IY to be rubbed out and redrawn
R $BF56 IY the object's record
D $BF56 The redraw marking at the end of #R$CC4B (bits 4 and 5 of +7, and #R$B9A7 for whatever it overlaps on the screen), for the record at IY instead of IX, with both kept. Used as something is picked up or put down (#R$BF79). As Knight Lore's set_wipe_and_draw_IY.

@ $BF66 label=CHK_PICKUP_DROP
c $BF66 Is the pick-up control pressed?
R $BF66 O:F Z clear if it is
R $BF66 O:A bit 4 set if it is
D $BF66 The pick-up bit is 4 of INPUT, except with a joystick and bit 3 of CONTROL set, when it is taken from bit 5 -- as in Knight Lore (chk_pickup_drop), where a directional joystick uses down for a direction and keys set bit 5 instead. Pentagram's #R$BDF8 never sets bit 5, so in that mode, which no menu choice selects, nothing could be picked up or put down.
  $BF66,15 a joystick (method not 0)...
  $BF75,1 ...and directional control: bit 5 moves into bit 4
  $BF76,3 the pick-up bit

@ $BF79 label=TAKE_OR_LEAVE
c $BF79 Pick up, or put down
R $BF79 IX the player's legs (#R$A76F)
D $BF79 Called from the legs' update routine (#R$C440) every turn. One press does one thing: pick up the bucket or a collectable that he is on or beside; failing that, put down the last of the things he carries (CARRIED_LAST), under himself, so that he stands on it; and if he carries nothing there, move what he carries one place along towards it. TAKE_HELD latches the press, so holding the key does nothing more, and every press that gets that far plays the pick-up sound. Knight Lore's handle_pickup_drop and the routines after it, joined into one.
D $BF79 Nothing happens unless he is inside the room's walls (#R$C4A3, not in a doorway), not jumping (bit 3 of +$0C) and standing on something (bit 2). Before anything else it looks for an object up to 12 units above his head: if there is one, NO_HEADROOM is set and nothing is put down, because putting something down lifts him 12 units onto it.
D $BF79 He carries up to three things, in the four-byte slots CARRIED_SHOWN (the newest), the one after, and CARRIED_LAST (the oldest, put down next): the graphic, the flags from +7, and the address of the thing's quest record (#R$D432). CARRIED is a fourth slot in front of them, where a thing just picked up waits for the slots to be moved along. They behave as a queue: the first picked up is the first put down.
  $BF79,7 the key is still held from the last press: wait for it to go up
  $BF80,4 not pressed: nothing to do
  $BF84,4 only inside the room's walls
  $BF88,10 not while jumping (bit 3 of +$0C); only when standing on something (bit 2)
  $BF92,21 anything within 12 units above his head? His Z is raised to look, then put back
  $BFA7,5 yes: there is no room for him to stand on what he puts down (this never ran in the build's sessions)
  $BFAC,8 latch the key, and have the panel's carried things redrawn (#R$BA34)
  $BFB4,31 each half-size +4, so that a thing just out of reach counts; the old ones go on the stack
  $BFD3,17 the 48 records of the room's things: the first that can be picked up (#R$C0D4) is taken
  $BFE4,5 nothing to pick up. This test cannot fail: INPUT has not changed since the same test at the start
  $BFE9,19 the first free record among the room's 48, to put a thing down in; none: nothing is put down
@ $BFFC label=TAKE_DONE
  $BFFC,11 his half-sizes back
  $C007,7 the pick-up sound: sound 1, for five turns (#R$D5F2)
@ $C00E label=WAIT_TAKE_RELEASE
  $C00E,9 clear the latch once the key is up
@ $C017 label=PUT_DOWN
N $C017 Put down the last thing he carries, into the free record at IY.
  $C017,8 nothing in the last slot: just move the slots along
  $C01F,6 no headroom: put nothing down
  $C025,7 the thing's graphic into the free record; HL on to the slot's flags
  $C02C,13 the rest of the record from the player's legs: his position, so that it goes down where he stands
  $C039,16 lift both of his records by 12, the thing's height, so that he stands on it
  $C049,24 with IX on the thing: its drawing nudge (#R$C75F), its place on the screen (#R$B2C5), a turn's fall (#R$B979), and mark it to be drawn
@ $C061 label=FILL_PUT_DOWN
N $C061 Fill in the record of a thing put down: IY the record, its graphic and position already set; the slot's flags byte on the stack.
  $C061,12 half-sizes 5, 5 and 12
  $C06D,12 +7 the flags from the slot; +8 the room, the player's
  $C079,9 +$10 and +$11: the address of its quest record, from the slot
  $C082,8 the graphic back into the quest record, which picking it up had emptied: it is in this room again
  $C08A,4 bit 0 of +$0D: just put down. Nothing has been found that reads it (Knight Lore's charms have a use for it)
  $C08E,3 mark it to be drawn
@ $C091 label=SHIFT_CARRIED
N $C091 Move the carried things one slot along.
  $C091,11 twelve bytes up by four, copied from the top down so that they do not overwrite themselves: the slot in front moves into CARRIED_SHOWN, and so on to CARRIED_LAST
  $C09C,11 the slot in front is empty
@ $C0A7 label=PICK_UP
N $C0A7 Pick up the thing at IY.
  $C0A7,24 graphic, flags and quest record's address into the slot in front; the quest record's graphic zeroed, so that the thing is not put back in its room when he leaves
  $C0BF,7 mark it to be rubbed out, and make it graphic 1, which the drawing code rubs out and then empties (#R$B3D3)
  $C0C6,8 carrying fewer than three: move the slots along
  $C0CE,6 three: the oldest goes down where this one was, in the same record -- picking up swaps (this never ran in the build's sessions)

@ $C0D4 label=CAN_PICK_UP
c $C0D4 Can this thing be picked up?
R $C0D4 IX the player's legs
R $C0D4 IY the thing
R $C0D4 O:F carry set if it can
D $C0D4 Only the bucket (graphic 90) and the collectables (144 to 148), and only when he is on or beside it: their boxes overlap in U and V, and in Z with him lowered by 4, so that a thing he stands on counts as touching. The caller has made his box 4 bigger each way. Knight Lore's can_pickup_spec_obj and is_on_or_near_obj together.
  $C0D4,12 the bucket, or graphic 144 to 148; otherwise no carry
  $C0E0,16 overlapping in U and V, with no offset
  $C0F0,21 in Z, with him 4 lower, then put back

# --------------------------------------------------------------------------
# Puffs and bolts ($C107-$C28A)
# --------------------------------------------------------------------------

@ $C107 label=START_PUFF
c $C107 Make an object a puff of smoke
R $C107 IX the object
D $C107 Turns the object into graphic 64, the first frame of the puff that #R$C111 runs through, and sets bit 1 of its flags so that the collision code leaves it alone. Used when the player is killed (#R$C440, #R$C5D3), when a bolt hits a wall or an object (#R$C1C5), and by #R$D0AC. Knight Lore's init_death_sparkles.
  $C107,10 graphic 64, out of collisions, and mark it to be redrawn

@ $C111 label=PUFF
c $C111 The update routine for a puff (graphics 64 to 70)
D $C111 One frame a turn, with a burst of noise (#R$D64E); graphic 71 is the last (#R$C11D).
  $C111,3 its drawing nudge
  $C114,6 the noise, and the next frame
@ $C11A label=PUFF_DRAW
  $C11A,3 mark it to be redrawn

@ $C11D label=END_PUFF
c $C11D The update routine for a puff's last frame (graphic 71)
D $C11D Makes the object graphic 1, which the drawing code rubs out and then empties (#R$B3D3). #R$C264 comes in at VANISH to make a bolt vanish the same way.
  $C11D,3 its drawing nudge
@ $C120 label=VANISH
  $C120,6 graphic 1: rubbed out at the next drawing, then an empty record

@ $C126 label=FIRE
c $C126 Fire a bolt
R $C126 IX the player's legs
D $C126 On a new press of fire (bit 6 of INPUT, latched by FIRE_HELD), takes the first free of the two bolt records (BOLTS and BOLT_SECOND), copies the player's legs into it and makes it graphic 150, moving 8 units a turn the way he faces (#R$C1BD), starting 16 units ahead of him and 4 higher. If that start is outside the room's walls -- he stands in a doorway, or faces a wall close up -- the bolt is taken back; otherwise it makes the firing sound (#R$D629). #R$C1C5 flies it.
  $C126,3 the first bolt record
  $C129,12 fire not pressed: unlatch, and nothing more
  $C135,9 still held since the last shot: nothing; otherwise latch
  $C13E,11 the first bolt record if it is empty, else the second; both busy: no shot
  $C149,9 IY = the bolt; a copy of the legs' record
  $C152,4 graphic 150
  $C156,11 HL = the step for the way he faces (#R$C5BD) in #R$C1BD
  $C161,25 kept at +$14 and +$15, and twice it added to U and V: 16 units ahead
  $C17A,8 4 units higher
  $C182,12 flags $14 (bits 4 and 2), nothing bumped, half-height 8
  $C18E,39 inside the room's walls, as #R$C4A3 tests...
  $C1B5,3 ...the firing sound
  $C1B8,4 outside: no bolt after all

@ $C1BD label=BOLT_STEPS
b $C1BD A bolt's step in U and V, by the way the player faces
D $C1BD Four pairs of signed bytes, indexed by the direction from #R$C5BD (0 to 3). #R$C126 puts the pair at +$14 and +$15 of the bolt, and #R$C1C5 copies it into the bolt's step every turn.
B $C1BD,8,2 Facing 0: (-8, 0); 1: (8, 0); 2: (0, 8); 3: (0, -8)

@ $C1C5 label=BOLT
c $C1C5 The update routine for a bolt (graphics 149 to 151, and 60)
D $C1C5 Moves the bolt and cycles its graphic through 151, 150 and 149. Gravity is applied as to everything (#R$B979), but a bolt is held at Z 132, so one fired from the floor flies level, and one fired from higher up drops to that height. If it touches either thing from the sky (#R$C206) the thing is shot down (#R$C264); if its move was cut short in U or V by a wall or an object it goes up in a puff (#R$C107). Otherwise its step is set again from +$14 and +$15 for the next turn, and it is marked to be redrawn.
D $C1C5 The update-routine table (#R$AE2F) also gives this routine to graphic 60, which is one of the panel's pieces (#R$BD31); no room object has been seen with it.
  $C1C5,6 its drawing nudge; fall and move, cut short against the room and the other objects
  $C1CB,13 the next frame: 151, 150, 149, then 151 again
  $C1D8,15 never lower than Z 132, where it stops falling
  $C1E7,8 hit a thing from the sky: shoot it down
  $C1EF,8 bumped in U or V: a puff
  $C1F7,12 its step again, for the next turn
  $C203,3 mark it to be redrawn

@ $C206 label=BOLT_HIT
c $C206 Has the bolt hit either thing from the sky?
R $C206 IX the bolt
R $C206 O:D 0 if it has
R $C206 O:IY the thing it hit, if D is 0
D $C206 Tests the two records for things from the sky (FLYERS and FLYER_SECOND) with HIT_TEST, the second half of this routine. #R$CFB2 uses the test the other way round, for the two bolts against the well.
  $C206,9 the first thing from the sky
  $C20F,3 hit: done
  $C212,4 the second
@ $C216 label=HIT_TEST
N $C216 Is the object at IY touching the one at IX? D is set to 0 if it is, and left alone if not. IY's graphic must be 8 or more and not a puff (64 to 71). Each axis in turn: the distance between them no more than the sum of their half-sizes, plus 2.
  $C216,6 graphic 0 to 7: nothing there
  $C21C,2 graphic 64 to 71, a puff...
@ $C21E label=HIT_TEST_Z
  $C21E,1 ...no hit. #R$CFB2 comes in here for the first bolt with Z from its own test for an empty record, which skips the test for a puff: that bolt's puff still counts as touching the well
  $C21F,22 U
  $C235,22 V
  $C24B,22 Z
  $C261,2 touching

@ $C264 label=SHOOT_DOWN
c $C264 A bolt hits a thing from the sky
R $C264 IX the bolt
R $C264 IY the thing it hit
D $C264 Scores for it, from its graphic number: the points are three digits made of the number's bits -- the hundreds from bits 5-7, the tens from bits 2-4, the units from bits 6, 7 and 0 -- so that no digit goes past 7 and the sum stays BCD. The things that fall (#R$CC09) start as graphics 164, 160, 48, 80 and 168, which score 512, 502, 140, 241 and 522 at those frames. The score is shown at once (#R$B145). The thing becomes a puff (graphic 64) and the bolt vanishes.
  $C264,16 BC = the points: C its graphic rotated left twice, AND $77; B rotated left three times, AND 7
  $C274,6 add them, and copy the score to the screen
  $C27A,8 the thing: a puff, out of collisions
  $C282,3 the bolt: gone

@ $C285 label=STILL_DEADLY
c $C285 The update routine for things that kill but never move (graphics 23, 30, 74 and 75)
D $C285 Makes the thing deadly both ways (#R$C291) and sets its drawing nudge; it is not marked for redrawing, as nothing about it changes.
  $C285,6 deadly; the nudge (-16, -8), and return from there

@ $C28B label=DEADLY_AND_DRAW
b $C28B Unreached code: make a thing deadly, and redraw it
D $C28B Six bytes that are the code of an update routine -- CALL #R$C291, then a jump to the redraw marking at the end of #R$CC4B -- but no graphic's entry in #R$AE2F points here and nothing else reaches it, so the code map leaves it as data.
B $C28B,6,3 CALL #R$C291; JP to the redraw marking

@ $C291 label=MAKE_DEADLY
c $C291 Make an object deadly both ways
R $C291 IX the object
D $C291 Sets bits 7 and 5 of +$0D: it kills what it moves into and what touches it. As Knight Lore's set_both_deadly_flags.

# --------------------------------------------------------------------------
# Lives, the start and the end of a game ($C29A-$C3EE)
# --------------------------------------------------------------------------

@ $C29A label=DRAW_LIVES
c $C29A Draw the lives icon and the number of lives on the panel
D $C29A Draws graphic 22, a little Sabreman, at (16, 32) in the buffer through the spare record at #R$BACA, makes six attribute cells bright white -- columns 2 and 3 of character row 18, and 2 to 5 of row 19, the icon and the two digits -- and prints LIVES as two digits in columns 4 and 5 of row 19. Called when a room is drawn (#R$B00C) and when a quest item adds a life (#R$CF68). Knight Lore's print_lives_gfx draws only the icon.
  $C29A,23 graphic 22, unturned, at (16, 32)
  $C2B1,18 bright white on black: two cells of row 18, four of row 19, from column 2
  $C2C3,11 the two digits of LIVES, by the score's printer (#R$BB29)

@ $C2CE label=CHOOSE_START
c $C2CE Choose where the game starts
D $C2CE Puts the first sixteen bytes of the player's legs record back as they are at the start of a game (#R$C3EF, over the start of #R$C3FF), and sets the room by the random number: one of the four at #R$C2E8. Called once a game, from #R$AF87, before the first #R$C2EC.
  $C2CE,11 graphic, position, half-sizes, flags and room of a new game
  $C2D9,14 one of four rooms, by bits 0 and 1 of RANDOM

@ $C2E8 label=START_ROOMS
b $C2E8 The four rooms a game can start in
D $C2E8 #R$C2CE picks one by bits 0 and 1 of RANDOM.
B $C2E8,1 Room 51
B $C2E9,1 Room 92
B $C2EA,1 Room 100
B $C2EB,1 Room 12

@ $C2EC label=RESTART_PLAYER
c $C2EC Put the player back, a life fewer
D $C2EC Copies #R$C3FF over both his records -- the player as he came into this room, or as the game starts -- and takes a life. Reached at the start of every game and after every death (#R$AF87), so the first call takes the five lives the game gives to four; below zero, after the fifth death, the game is over (GAME_OVER, in #R$C302).
D $C2EC LIVES is treated as BCD elsewhere but decremented here as a plain number. It cannot go above 9 (five, and one for each of the four quest items, #R$CF68), so the two agree.
  $C2EC,14 both records, legs and body; IX on the legs
  $C2FA,8 a life fewer; below zero: game over

@ $C302 label=WON
c $C302 The quest is complete
D $C302 Jumped to by #R$CD16 when the fifth collectable reaches its place. Clears the buffer, fills the attributes with bright cyan, prints the six lines of #R$C38B -- congratulations, the quest done (with a misspelling), and the next adventure named as Mire Mare -- clearing the screen-shown flag (FRAME_DRAWN) first, so that the list also draws the border and shows the screen -- then plays #R$D86F to its end and goes on to the game-over screen.
D $C302 Mire Mare was to be the next Sabreman game; it was never released.
  $C302,8 clear the buffer; bright cyan on black
  $C30A,12 colours from #R$C3E9, positions from WON_XY, strings from #R$C38B: six lines
  $C316,7 the first list since the flag was cleared: border and screen too
  $C31D,6 the winning tune
@ $C323 label=GAME_OVER
N $C323 The game is over: from #R$C2EC when the last life is lost, and after the win.
  $C323,8 clear the buffer; bright yellow on black
  $C32B,3 border
  $C32E,15 GAME OVER, PERCENTAGE OF QUEST and COMPLETED: colours from #R$C35D, positions from OVER_XY, strings from #R$C366. The screen was shown once already this game, so the list only draws into the buffer
  $C33D,3 the percentage, into the buffer (#R$C6EA)
  $C340,7 show it all. Clearing the flag here is redundant: the menu clears it again
  $C347,6 the game-over tune
  $C34D,12 about four seconds: 64 times 8192 turns of a 26 T-state loop
  $C359,4 drop the return address -- the main loop's, or the one back into #R$AF87 -- and start again from the menu

@ $C35D label=OVER_COLOURS
b $C35D The game-over screen: the colour of each line
D $C35D The game-over screen's three tables, laid out as the menu's (#R$BBF1): three colours, three (x, y) positions from this entry's last byte (OVER_XY), and three strings from #R$C366, handed to DISPLAY_TEXT_LIST (#R$BCB4) by GAME_OVER (#R$C302).
B $C35D,4,3,1 Red, magenta and green, all bright; then the first line's x, the first byte of the positions
@ $C360 label=OVER_XY

@ $C361 label=OVER_Y_TITLE
b $C361 The game-over screen: where the lines go
B $C361,5,1,2,2 GAME OVER's y, 159, for (88, 159): character column 11, row 4; PERCENTAGE OF QUEST at (48, 111); COMPLETED at (64, 95)

@ $C366 label=OVER_GAME_OVER
t $C366 The game-over screen: GAME OVER

@ $C36E label=OVER_GAME_OVER_LAST
b $C36E The game-over screen: GAME OVER, its last letter
B $C36E,1,c1 R, with bit 7 set

@ $C36F label=OVER_PERCENTAGE
t $C36F The game-over screen: PERCENTAGE OF QUEST

@ $C381 label=OVER_PERCENTAGE_LAST
b $C381 The game-over screen: PERCENTAGE OF QUEST, its last letter
B $C381,1,c1 T, with bit 7 set

@ $C382 label=OVER_COMPLETED
t $C382 The game-over screen: COMPLETED
D $C382 #R$C6EA prints the percentage after it, at (144, 95).

@ $C38A label=OVER_COMPLETED_LAST
b $C38A The game-over screen: COMPLETED, its last letter
B $C38A,1,c1 D, with bit 7 set

@ $C38B label=WON_CONGRATULATIONS
t $C38B The winning screen: CONGRATULATIONS
D $C38B The winning screen's six strings run from here to #R$C3DC; their positions follow them, from WON_XY, the second byte of #R$C3DC, and their colours are #R$C3E9. #R$C302 hands the three to DISPLAY_TEXT_LIST (#R$BCB4).

@ $C399 label=WON_CONGRATULATIONS_LAST
b $C399 The winning screen: CONGRATULATIONS, its last letter
B $C399,1,c1 S, with bit 7 set

@ $C39A label=WON_COMPLEATED
t $C39A The winning screen: YOU HAVE COMPLEATED
D $C39A Spelt so on the screen.

@ $C3AC label=WON_COMPLEATED_LAST
b $C3AC The winning screen: YOU HAVE COMPLEATED, its last letter
B $C3AC,1,c1 D, with bit 7 set

@ $C3AD label=WON_PENTAGRAM
t $C3AD The winning screen: THE PENTAGRAM

@ $C3B9 label=WON_PENTAGRAM_LAST
b $C3B9 The winning screen: THE PENTAGRAM, its last letter
B $C3B9,1,c1 M, with bit 7 set

@ $C3BA label=WON_ADVENTURE
t $C3BA The winning screen: YOUR ADVENTURE

@ $C3C7 label=WON_ADVENTURE_LAST
b $C3C7 The winning screen: YOUR ADVENTURE, its last letter
B $C3C7,1,c1 E, with bit 7 set

@ $C3C8 label=WON_CONTINUES
t $C3C8 The winning screen: CONTINUES IN

@ $C3D3 label=WON_CONTINUES_LAST
b $C3D3 The winning screen: CONTINUES IN, its last letter
B $C3D3,1,c1 N, with bit 7 set

@ $C3D4 label=WON_MIRE_MARE
t $C3D4 The winning screen: MIRE MARE

@ $C3DC label=WON_MIRE_MARE_LAST
b $C3DC The winning screen: MIRE MARE's last letter, and where the first line goes
B $C3DC,3,c1,2 E, with bit 7 set; then the positions start: CONGRATULATIONS at (72, 143)
@ $C3DD label=WON_XY

@ $C3DF label=WON_XY_LINE2
b $C3DF The winning screen: where the lines go (the second; the third's x)
B $C3DF,3,2,1 YOU HAVE COMPLEATED at (56, 111); x of THE PENTAGRAM

@ $C3E2 label=WON_Y_LINE3
b $C3E2 The winning screen: where the lines go (the third's y)
B $C3E2,1 y of THE PENTAGRAM: 95

@ $C3E3 label=WON_XY_LINE4
b $C3E3 The winning screen: where the lines go (the fourth and fifth)
B $C3E3,4,2 YOUR ADVENTURE at (72, 79); CONTINUES IN at (80, 63)

@ $C3E7 label=WON_XY_LINE6
b $C3E7 The winning screen: where the lines go (the sixth)
B $C3E7,2,2 MIRE MARE at (96, 31)

@ $C3E9 label=WON_COLOURS
b $C3E9 The winning screen: the colour of each line
B $C3E9,6,6 Yellow, cyan, cyan, red, red and magenta, all bright

@ $C3EF label=PLAYER_START
b $C3EF The start of the player's legs record, as a game starts
D $C3EF Sixteen bytes that #R$C2CE copies over the start of #R$C3FF at every new game, putting back what his travels have changed there. The room is replaced at once by one of #R$C2E8.
B $C3EF,8,1,3,3,1 Graphic 32, the legs; U, V and Z 128, the middle of the room on the floor; half-sizes 5, 5 and 23 -- the legs' box is the height of the whole man; flags $5C: bit 6 mirrored, bit 4 drawn, and bits 3 and 2
B $C3F7,8,1,7 Room 98, never used; the rest zero

@ $C3FF label=PLAYER_TEMPLATE
b $C3FF The player, as he came into this room
D $C3FF His two records, legs and body, 64 bytes, which #R$C2EC copies over #R$A76F at the start of every life. Each time he goes through a doorway, #R$C843 and its neighbours copy his records here as he comes into the new room, so a life starts at the doorway he came in by; a new game puts the start of the legs' record back from #R$C3EF, and #R$C2CE sets the room. What is kept is the exit marker, not a position: after an exit it held the new room with V $FF, so a restart runs the arrival code again (measured).
B $C3FF,8,1,3,3,1 The legs: graphic 32; U, V, Z; half-sizes 5 and 5, height 23; flags $5C
@ $C407 label=START_ROOM
B $C407,1 The room
B $C408,8,8 The rest of the legs' record: zero
B $C410,8,8
B $C418,8,7,1 The body's record starts at the last byte: graphic 40
B $C420,8,3,3,1,1 U and V 128, Z 140 (12 higher than the legs); half-sizes 5, 5 and 0; flags $5E, as the legs' and out of collisions (bit 1); room 1, which nothing reads -- #R$C5D3 copies the legs' position into the body every turn
B $C428,8,8 The rest of the body's record: zero
B $C430,8,8
B $C438,7,7

# --------------------------------------------------------------------------
# The player's legs ($C43F-$C4C7)
# --------------------------------------------------------------------------

@ $C43F label=NOTHING
c $C43F The update routine for what does nothing
D $C43F Graphics 0 to 5 and many more in #R$AE2F: an empty record, scenery that never changes, and graphic 1, a record waiting to be rubbed out and emptied (#R$B3D3).

@ $C440 label=PLAYER_LEGS
c $C440 The player's update routine: legs (graphics 32 to 39)
R $C440 IX the legs' record, #R$A76F
D $C440 The player's turn, in order: read the controls (#R$BDF8), turn (#R$C4C8), step the legs' frame, with a footstep sound (#R$C58D), start a jump (#R$C56C), pick up or put down (#R$BF79). Then, if he stands in a doorway -- past the line of the room's walls -- he may not rise, only fall. The move is resolved and made (#R$C61D), with the body out of the way of the collision tests, and he may fire (#R$C126).
D $C440 If he has been killed (bit 6 of +$0D), the body is killed too and the legs become a puff.
  $C440,3 the legs' drawing nudge (-12, -6)
  $C443,13 killed: the body too (+$0D of the next record), and a puff
  $C450,10 this turn's controls in A and C; no step in U or V yet
  $C45A,12 turn, walk, jump, pick up or put down
  $C466,5 in a doorway, beyond the walls?
@ $C46B label=LEGS_MOVE
  $C46B,4 the body (+7 of the next record) out of the collision tests while the legs move
  $C46F,11 no higher than Z 240 (this never ran in the build's sessions)
  $C47A,6 make the move, and fire
  $C480,4 the body back in the collision tests
  $C484,4 bit 0 of his flags, set at a doorway to let the move cross the line of the walls (#R$C802), lasts one turn
  $C488,10 count down the top four bits of +$0C: the turns he walks on by himself after coming through a doorway (#R$C843 sets 3)
  $C492,3 mark him to be redrawn
@ $C495 label=LEGS_IN_DOORWAY
  $C495,7 in a doorway: falling is allowed...
  $C49C,6 ...rising is not

@ $C4A2 label=STRAY_RET_LEGS
b $C4A2 Unreached code: a RET
D $C4A2 One byte, a RET, between #R$C440 and #R$C4A3, which nothing reaches; the code map leaves it as data.
B $C4A2,1 RET

@ $C4A3 label=CHK_PLYR_OOB
c $C4A3 Is he inside the room's walls?
R $C4A3 IX the object, the player's legs
R $C4A3 O:F carry set if it is
D $C4A3 Compares the object's distance from the room's centre, 128 on U and V, with the room's reach in each (ROOM_EXTENT) less its own half-size. Carry means the whole of its footprint is inside on both; no carry, that it touches or crosses the line of a wall, which only a doorway allows. #R$C126 has the same test written out again for a bolt. As Knight Lore's chk_plyr_OOB.
  $C4A3,13 L = the reach in U less the half-size in U; H = the same for V
  $C4B0,12 |U - 128|: no carry, outside
  $C4BC,12 |V - 128|

# --------------------------------------------------------------------------
# Range 4
# --------------------------------------------------------------------------

# Pentagram, stage 2, agent 4: $C4C8-$CCE8 -- the player's turning, jumping,
# walking and body; the drawing offsets; the arches and leaving a room;
# building a room and arriving in it; the rooms-seen map and the percentage;
# the things that fall from the sky and the homers.

# --------------------------------------------------------------------------
# The player: turning, jumping, walking
# --------------------------------------------------------------------------

@ $C4C8 label=HANDLE_LEFT_RIGHT
c $C4C8 Turn the player
D $C4C8 Two ways of steering. Rotational control -- the keyboard's, and every joystick's as the menu leaves them -- turns a quarter at a time on the two turn controls: bit 0 of C turns left, bit 1 right. Directional control treats the controls as four points of the compass instead: pushing one turns the player towards it and, once he faces it, walks him that way. It needs a joystick method and bit 3 of #R$A709, which no menu choice sets (#R$BB74), so the game as sold never uses it.
D $C4C8 Facings, as #R$C5BD gives them: 0 is towards lower U (up and left on the screen), 1 higher U (down and right), 2 higher V (up and right), 3 lower V (down and left). A facing is stored as two bits -- bit 2 of the graphic and bit 6 of the flags, the mirror bit -- and a quarter turn always toggles the mirror bit and, half the time, the graphic's bit 2 as well. A left turn goes 0, 3, 1, 2 and round; a right turn the other way. The body's graphic is set to the legs' plus 8 at once, so the two turn in the same turn.
D $C4C8 Directional control reads up (bit 2) unless left is also held, then right, down (bit 4), left, and goes the short way round, or two turns for an about-face. Up is the walk bit itself, so pushing up walks even while turning; and down is bit 4, which #R$BDF8 sets only from the pick-up keys -- every joystick's down is jump, bit 3 -- so a joystick alone can never face 3. This is Knight Lore's code, where the stick's down was bit 4.
R $C4C8 IX The player's legs (#R$A76F)
R $C4C8 C The controls (INPUT): bits 0 and 1 turn, 2 walk, 3 jump, 4 pick up
R $C4C8 O:C Bit 2 set if the player is to walk
  $C4C8,8 Bits 1-2 of the control method: 0, the keyboard, always turns rotationally
  $C4D0,4 Directional control not switched on
  $C4D4,6 Directional: nothing during the walk into a room (the count in bits 4-7 of +$0C)
  $C4DA,5 Nor in the air: bit 2 of +$0C, set when a move down was stopped, means standing
  $C4DF,8 Left held: skip up; up held: face 2
  $C4E7,12 Right: face 1; down: face 3; left: face 0
  $C4F3,3 Nothing pushed: no walking (bit 2 is already clear by now)
  $C4F6,7 Up: facing 2 already, so walk
  $C4FD,5 Otherwise invert the facing, so that bit 0 set means a right turn is the short way
  $C502,7 Right: facing 1 already? The same test as up
  $C509,7 Down: facing 3 already? Walk if so
  $C510,2 Otherwise the facing's own bit 0 picks the turn
  $C512,6 Left: facing 0 already? The same test as down
  $C518,3 Facing the way pushed: walk
  $C51B,11 Rotational: while the pause between turns (bits 0-2 of +$0D) runs, count it down and do nothing else
  $C526,4 Neither turn control held
  $C52A,6 Not during the walk into a room
  $C530,5 Not in the middle of a jump
  $C535,4 A jump to the next instruction: Knight Lore plays a turning sound here when the player is not walking, and this is what is left of it
  $C539,8 A pause of two turns before the next quarter turn
  $C541,2 Bit 1: right
  $C543,2 NZ for a right turn, Z for a left
  $C545,6 Left turn: an unmirrored sprite only mirrors (2 to 0, 3 to 1)
  $C54B,8 Toggle the graphic's bit 2: the other view
  $C553,8 Toggle the mirror bit
  $C55B,9 The body's graphic is the legs' plus 8
  $C564,8 Right turn: a mirrored sprite only mirrors (0 to 2, 1 to 3); otherwise both

@ $C56C label=HANDLE_JUMP
c $C56C Start a jump
D $C56C A jump needs the jump control held, the walk into a room over, no jump already under way, and the player standing on something: bit 2 of +$0C, which the collision code (#R$B6ED) sets when it stops a move down. Knight Lore tests the Z step here instead. The jump starts at 8 units up a turn; #R$C61D's gravity takes it away again.
R $C56C IX The player's legs
R $C56C C The controls
  $C56C,3 Jump not held
  $C56F,6 Not during the walk into a room
  $C575,5 Already jumping
  $C57A,5 Not standing on anything
  $C57F,8 Jumping, 8 up
  $C587,5 The jump's sound (#R$D5E4), the controls kept

@ $C58D label=HANDLE_FORWARD
c $C58D Step the legs
D $C58D While the player walks, jumps or is walking into a room, the legs step on through their four frames -- the low two bits of the graphic -- and the footstep sound (#R$D635) counts, sounding every fourth step. When none of those applies the legs carry on stepping to frame 2, the standing pose, and stop there. Knight Lore's cycle is six frames with two standing poses, and it carries on to them in silence; here the steps to the standing pose count towards a footstep too.
R $C58D IX The player's legs
R $C58D C The controls
  $C58D,7 Walking into a room: step
  $C594,6 Jumping: step
  $C59A,4 Walk not held: go to the standing pose
  $C59E,15 The next frame of four, in the graphic's low two bits
  $C5AD,6 The footstep count and sound, the controls kept
  $C5B3,8 Frame 2 is the standing pose: done
  $C5BB,2 Otherwise step on towards it

@ $C5BD label=GET_SPRITE_DIR
c $C5BD Which way an object faces
D $C5BD The facing, 0 to 3, from the two bits that store it: bit 6 of the flags (mirrored) clear gives 2, and bit 2 of the graphic adds 1. So 0 faces lower U, 1 higher U, 2 higher V and 3 lower V (see #R$C4C8). Knight Lore's is the same with bit 3 of the type in place of bit 2.
R $C5BD IX The object
R $C5BD O:A The facing
  $C5BD,11 L = 8 if the sprite is not mirrored
  $C5C8,6 With the graphic's bit 2
  $C5CE,5 Down to bits 1 and 0

@ $C5D3 label=PLAYER_TOP
c $C5D3 The player's update routine: body
D $C5D3 The body (graphics 40 to 47) has no movement of its own: each turn it copies the legs' position, half-sizes and flags, takes a height of zero and sets bit 1 of its flags, which keeps it out of every collision test -- the legs' box is the whole player's. Its graphic is the legs' plus 8, the same facing and frame, and it sits 12 above the legs when seen from behind (facings 0 and 2) and 8 above when seen from the front.
D $C5D3 Bits 0-3 of the body's +$0D are a count that would hold its own graphic for that many turns. Knight Lore sets it when it gives the head a random other frame; no code was found in Pentagram that sets it for the body, and the count never ran in the build's sessions.
D $C5D3 A body marked killed (bit 6 of +$0D, set by #R$C440 when the legs are) turns into the puff instead (#R$C107).
R $C5D3 IX The body's record (PLAYER_BODY)
  $C5D3,3 Drawn 12 left and 8 down
  $C5D6,7 Killed: become the puff
  $C5DD,10 IY = HL = the legs, the record below
  $C5E7,7 U, V, Z, the half-sizes and the flags from the legs
  $C5EE,4 Height 0
  $C5F2,4 Bit 1: out of the collision tests
  $C5F6,7 The count running?
  $C5FD,5 Yes: count it down and keep the graphic
  $C602,8 Otherwise the legs' graphic plus 8
  $C60A,15 Z: the legs' plus 12 for the view from behind (bit 2 clear), plus 8 for the front
  $C619,4 Have it and whatever it overlaps redrawn (#R$B9A7)

@ $C61D label=MOVE_PLAYER
c $C61D Move the player
D $C61D The player steps forward when walk is held, and also without it during a jump and during the walk into a room: 3 units in the way he faces, plus any nudge an arch has left him (#R$C66A). Then gravity: 2 off the Z step every turn, or 1 while he is still rising (or level) with jump held, so that holding jump jumps higher. The Z step is kept in Z_STEP before #R$B6ED cuts the move short against the floor, the walls and the other objects, and then the move is made. A move down that was stopped (bit 2 of +$0C) is a landing, and ends the jump.
D $C61D Knight Lore's routine is the same with two calls taken out: the falling sound (the ADD A,2 before the collision code is its test, and nothing reads it now) and the check for walking out of the room, which here is an empty routine (#R$C6B5) because Pentagram's arches do that themselves (#R$C802).
R $C61D IX The player's legs
R $C61D C The controls
  $C61D,6 Jumping: forward
  $C623,7 Walking into a room: forward
  $C62A,4 Walk not held: no step
  $C62E,5 A step forward, the controls kept
  $C633,7 Z step negative: falling, two off
  $C63A,4 Rising or level with jump held: one off
  $C63E,2 Gravity: two off, or one
  $C640,6 The new Z step, and a copy that says afterwards which way he was going
  $C646,2 Left over from Knight Lore's falling sound: nothing reads A
  $C648,3 Cut the move short where it must be
  $C64B,3 Knight Lore's exit check, now a RET
  $C64E,3 U, V and Z plus the steps
  $C651,13 Stopped while moving down?
  $C65E,4 Then landed: the jump is over
  $C662,8 The U and V steps are one turn's; the Z step carries over as the speed

@ $C66A label=CALC_PLYR_DUV
c $C66A Add a step in the direction he faces
D $C66A First adds the nudge in +$0E and +$0F, which an arch leaves to steer the player onto its middle line (#R$C8D2), to the U and V steps, and clears it; then adds 3 in the direction of the facing, through #R$C68D. So the nudge only acts while he walks.
D $C66A The last three instructions are a jump through a table of four addresses by the facing of the object at IX; #R$C8D2 uses it too.
R $C66A IX The player's legs
  $C66A,18 The U and V steps plus the nudge
  $C67C,7 The nudge is used up
  $C683,3 The table of steps

@ $C686 label=DISPATCH_ON_FACING
  $C686,7 Jump to the entry for the facing (the main loop's own dispatch at #R$AF87 does the rest)

@ $C68D label=WALK_STEP_TBL
w $C68D A step in each direction
D $C68D Four routine addresses, one per facing, used through the jump at the end of #R$C66A. Each adds 3 to, or takes 3 from, the U or V step.
W $C68D,8,2 Facing 0: U - 3; 1: U + 3; 2: V + 3; 3: V - 3

@ $C695 label=STEP_U_DOWN
c $C695 Step towards lower U
D $C695 The U step less 3, for facing 0.
R $C695 IX The player's legs
  $C695,5 -3
  $C69A,3 Store the U step

@ $C69E label=STEP_U_UP
c $C69E Step towards higher U
D $C69E The U step plus 3, for facing 1.
R $C69E IX The player's legs

@ $C6A5 label=STEP_V_UP
c $C6A5 Step towards higher V
D $C6A5 The V step plus 3, for facing 2.
R $C6A5 IX The player's legs
  $C6AA,3 Store the V step

@ $C6AE label=STEP_V_DOWN
c $C6AE Step towards lower V
D $C6AE The V step less 3, for facing 3.
R $C6AE IX The player's legs

@ $C6B5 label=EXIT_STUB
c $C6B5 Where Knight Lore checks for walking out of the room
D $C6B5 A lone RET. #R$C61D calls it at the point in the move where Knight Lore calls its own exit check; in Pentagram the arch at the doorway decides that (#R$C802), so this does nothing.

# --------------------------------------------------------------------------
# Entering a room
# --------------------------------------------------------------------------

@ $C6B6 label=ENTER_ROOM
c $C6B6 Build the room he is in
D $C6B6 Clears the screen buffer, builds the room's object records (#R$C92C), puts the player in the doorway he came in by if he came through one (#R$CA82), marks the room seen (#R$C6CC) and sets NEW_ROOM for the main loop (#R$B00C), which redraws the panel and clears it.
  $C6B6,4 IX = the player's legs, whose room is the one to build
  $C6C6,6 The room is new: NEW_ROOM

@ $C6CC label=MARK_ROOM_SEEN
c $C6CC Mark the player's room as seen
D $C6CC Sets the room's bit in ROOMS_SEEN: byte room/8, bit 7 minus room mod 8, so room 0 is bit 7 of the first byte. The 31 bytes have room for 248 rooms. #R$C6EA counts them.
R $C6CC IX The player's legs
  $C6CC,9 E = the byte: the room number divided by 8
  $C6D5,12 A = the bit: a carry rotated in from the top, as far as the room number's low three bits say
  $C6E1,9 Set it in the map

@ $C6EA label=PERCENTAGE
c $C6EA Work out and print the percentage of the quest done
D $C6EA For the game-over screen (#R$C302). Two rooms seen count one per cent, up to 54 (108 rooms or more); each quest item the bucket has reached counts 4 (QUEST_DONE, four of them: 16); each collectable in its place in room 82 counts 6 (PLACED, five: 30). 54, 16 and 30 make 100. The sum is counted up in BCD into PERCENT -- the hundreds, 0 or 1, then the tens and units -- and printed at pixel row 95, column 144 of the buffer: three digits at 100, otherwise two, with a leading zero.
D $C6EA The count is a DJNZ loop, so a sum of 0 runs it 256 times and prints 56: measured in the simulator, a player who loses all five lives without leaving the room he started in is told 56 per cent. One room seen counts nothing, since the rooms are halved first, and two count 1.
  $C6EA,7 31 bytes of the rooms-seen map, E counting
  $C6F1,13 Count the set bits
  $C6FE,9 Half the rooms seen, 54 at most
  $C707,7 Plus 4 for each quest item done
  $C70E,9 Plus 6 for each collectable placed
  $C717,6 Count it up in BCD, one at a time
  $C71D,10 Tens and units; the carry out of the last is the hundreds
  $C727,1 Keep the hundreds
  $C728,8 The place in the buffer to print at
  $C730,9 Three digits or two
  $C739,12 100: the hundreds digit with the digits' font, then the other two (#R$BB29)
  $C745,5 Under 100: one place along, and the tens and units only

# --------------------------------------------------------------------------
# Drawing offsets
# --------------------------------------------------------------------------

@ $C74A label=STRAY_RET_OFFSETS
c $C74A An unused RET
D $C74A Nothing calls or jumps here, and no graphic's update routine is this address. One more lies before #R$C4A3.

@ $C74B label=DRAW_AT_L8
c $C74B Drawing offset X -8, Y 0 (graphic 57)
D $C74B The whole update routine for graphic 57.
D $C74B A note for all the offset routines from here to #R$C784: +$12 and +$13 of an object record are added to the pixel position #R$B2C5 works out from the object's U, V and Z, to line the sprite up with the object's position. X is pixels right and Y pixels up, so the usual negative values move the sprite left and down. For a still object that is all its update routine does; others call one to set the offset before they move. They all end at the end of #R$C769.
  $C74B,3 Left 8

@ $C750 label=UNUSED_OFFSETS
c $C750 Three drawing offsets no graphic uses
D $C750 X -4, Y -12 at this address, X -36, Y -4 five bytes on, and X -20, Y -8 five bytes after that, each a LD HL and a JR to the end of #R$C769 like the routines round them. No entry of the update table (#R$AE2F) points at any of the three, and nothing calls them: offsets for graphics this version of the engine no longer has.
  $C750,15 X -4, Y -12; X -36, Y -4; X -20, Y -8

@ $C75F label=DRAW_AT_L16_D8
@ $C75F nowarn
c $C75F Drawing offset X -16, Y -8
D $C75F The offset of most of the things that move by themselves -- the collectables, the quest items, the well, the bucket and more -- and, through #R$CB4E, the whole update routine of several still graphics.
  $C75F,3 Left 16, down 8

@ $C764 label=DRAW_AT_L12_D8
c $C764 Drawing offset X -12, Y -8
D $C764 The player's body (#R$C5D3).
  $C764,3 Left 12, down 8

@ $C769 label=DRAW_AT_L16_D12
@ $C769 nowarn
c $C769 Drawing offset X -16, Y -12
D $C769 Used through #R$CB51 (graphic 77) and by #R$CD75.
  $C769,3 Left 16, down 12

@ $C76E label=SET_PIXEL_ADJ
  $C76E,7 The shared end of all the offset routines: L to +$12, H to +$13

@ $C775 label=DRAW_AT_L12_D6
c $C775 Drawing offset X -12, Y -6
D $C775 The player's legs (#R$C440), the bolts (#R$C1C5) and the homers (#R$CC4B).
  $C775,3 Left 12, down 6

@ $C77A label=DRAW_AT_L12_D4
c $C77A Drawing offset X -12, Y -4
D $C77A The puff (#R$C111, #R$C11D).
  $C77A,3 Left 12, down 4

@ $C77F label=DRAW_AT_L8_D4
c $C77F Drawing offset X -8, Y -4 (graphics 53 to 56)
D $C77F The whole update routine for graphics 53 to 56.
  $C77F,3 Left 8, down 4

@ $C784 label=DRAW_AT_L8_D2
c $C784 Drawing offset X -8, Y -2 (graphics 12 to 15 and 52)
D $C784 The whole update routine for graphics 12 to 15 and 52.
  $C784,3 Left 8, down 2

# --------------------------------------------------------------------------
# Arches, and leaving a room
# --------------------------------------------------------------------------

@ $C789 label=SECOND_PILLAR
c $C789 The second pillar of an arch (graphics 7 and 9)
D $C789 A doorway is two pillars, and this one only sets its drawing offset: the first pillar (#R$C7AD) does the work. An arch in a wall of constant V is mirrored (bit 6 of its flags); one in a wall of constant U is not.
R $C789 IX The pillar's record
  $C789,6 Mirrored
  $C78F,7 Graphic 9 has an offset of its own
  $C796,6 Graphic 7, not mirrored: X -7, Y -5
  $C79C,6 Mirrored: X -7, Y -4
@ $C7A2 nowarn
  $C7A2,6 Graphic 9, not mirrored: X -16, Y -5

@ $C7A8 label=FIRST_PILLAR_EIGHT
c $C7A8 The first pillar of an arch: graphic 8, not mirrored
D $C7A8 X -8, Y -5, then the doorway as #R$C7AD works it out.
R $C7A8 IX The pillar's record
  $C7A8,5 Left 8, down 5

@ $C7AD label=FIRST_PILLAR
c $C7AD The first pillar of an arch (graphics 6 and 8)
D $C7AD This pillar is the doorway. It works out the point in the middle of the arch, 13 from itself along the wall, and keeps it in its own +$09 to +$0B -- the step fields, which a pillar never needs, borrowed because #R$C8AD compares +$09 to +$0B of one record with +$01 to +$03 of another. Then #R$C802 lets the player out of the room if he is in the doorway and past the wall, and #R$C8D2 nudges him onto the arch's middle line if he is near it.
D $C7AD An arch in a wall of constant U (not mirrored) has its other pillar 13 further along V, and its doorway reaches 15 either way in U and 6 in V; one in a wall of constant V (mirrored) has its other pillar 13 back along U, and a doorway 6 in U and 15 in V.
D $C7AD A pillar's +$08 is not the room it stands in: the builder (#R$C92C) gives every piece of a scenery entry the byte after the entry, which for a doorway is the room it leads to.
R $C7AD IX The pillar's record
  $C7AD,6 Mirrored: an arch in a wall of constant V
  $C7B3,7 Graphic 8 has an offset of its own
  $C7BA,3 Graphic 6, not mirrored: X -5, Y -5
@ $C7BD label=ARCH_ALONG_U
  $C7BD,3 Set the offset
  $C7C0,8 V of the middle: this pillar's plus 13
  $C7C8,6 U of the middle: this pillar's
  $C7CE,3 The doorway: U within 15, V within 6
@ $C7D1 label=ARCH_CHECK_DOORWAY
  $C7D1,6 Z of the middle: the pillar's base
  $C7D7,3 In the doorway and past the wall: out of the room, and no return
  $C7DA,3 Near it: nudge towards the middle
  $C7DD,7 Mirrored: graphic 8 has an offset of its own
  $C7E4,3 Graphic 6, mirrored: X -17, Y -6
@ $C7E7 label=ARCH_ALONG_V
  $C7E7,3 Set the offset
  $C7EA,8 U of the middle: this pillar's less 13
  $C7F2,6 V of the middle: this pillar's
  $C7F8,5 The doorway: U within 6, V within 15
@ $C7FD nowarn
  $C7FD,5 Graphic 8, mirrored: X -16, Y -5

@ $C802 label=HANDLE_EXIT_SCREEN
c $C802 Is the player in the doorway, and has he walked out of the room?
D $C802 Only the player's legs, record 0, can use a doorway, and only while their graphic is one of 16 to 47 -- which leaves out the puff he becomes when he dies -- and bit 3 of the flags is set. In the doorway (#R$C8AD, with the limits the pillar gives), bit 0 of the legs' flags is set: while it is, the collision code (#R$B6ED) lets him past the line of the wall, and #R$C440 clears it again at the end of his next update. Then one of four routines (#R$C83B), by the way he faces, decides whether he is wholly past the wall he faces.
D $C802 This is Knight Lore's doorway check and its exit check in one. Knight Lore marks the player in the doorway from the arch and decides the exit in the player's own move; Pentagram leaves the move alone (#R$C6B5) and decides here, from the player's position after his move rather than from his position plus the step. The room's half-sizes (ROOM_EXTENT) are pushed for the four, because the dispatch uses HL.
R $C802 IX The first pillar, holding the arch's middle at +$09 to +$0B
R $C802 L How near in U
R $C802 H How near in V
  $C802,12 The player's legs, graphics 16 to 47 only
  $C80E,5 Not one that uses doorways
  $C813,4 Not in the doorway
  $C817,4 In it: he may cross the line of the wall
  $C81B,7 The four exits, and the room's half-sizes in U and V for them
  $C822,25 Jump to the exit for the way he faces (#R$C5BD's sum, done here for IY)

@ $C83B label=SCREEN_MOVE_TBL
w $C83B Leaving a room, by facing
D $C83B Four routine addresses in facing order, used by #R$C802.
W $C83B,8,2 Facing 0: #R$C843; 1: #R$C874; 2: #R$C887; 3: #R$C89A

@ $C843 label=EXIT_LOW_U
c $C843 Out through the wall at low U?
D $C843 Out if the player's far edge -- U plus his half-size -- is below the wall at 128 less the room's half-size. U is then set to 0: not a position but a marker, which #R$CA82 sees when the next room is built and puts him in the doorway of its wall at high U. The other exits use $FF and 0 the same way.
R $C843 IY The player's legs
R $C843 IX The pillar
  $C843,5 L = the wall
  $C848,8 Still at or past it: stay
  $C850,4 Arrive at the wall at high U
@ $C854 label=EXIT_SCREEN
  $C854,6 The new room: the one the pillar's doorway leads to
  $C85A,8 The walk into a room: three turns (bits 4-7 of +$0C) of walking straight on
  $C862,11 Both player records to #R$C3FF, so that a life lost in the new room starts again at this doorway
  $C86D,4 Drop the returns to #R$C7AD and to the main loop
  $C871,3 Build the new room and carry on from there (#R$AF87)

@ $C874 label=EXIT_HIGH_U
c $C874 Out through the wall at high U?
D $C874 As #R$C843 the other way: out if the near edge, U less the half-size, is at or past the wall at 128 plus the room's half-size. U becomes the marker $FF: arrive at the wall at low U.
R $C874 IY The player's legs
R $C874 IX The pillar
  $C874,5 L = the wall
  $C879,8 Short of it: stay
  $C881,6 Arrive at the wall at low U

@ $C887 label=EXIT_HIGH_V
c $C887 Out through the wall at high V?
D $C887 Out if the near edge in V is at or past the wall at 128 plus the room's half-size in V. V becomes the marker $FF: arrive at the wall at low V.
R $C887 IY The player's legs
R $C887 IX The pillar
  $C887,5 H = the wall
  $C88C,8 Short of it: stay
  $C894,6 Arrive at the wall at low V

@ $C89A label=EXIT_LOW_V
c $C89A Out through the wall at low V?
D $C89A Out if the far edge in V is below the wall at 128 less the room's half-size in V. V becomes the marker 0: arrive at the wall at high V.
R $C89A IY The player's legs
R $C89A IX The pillar
  $C89A,5 H = the wall
  $C89F,8 Still at or past it: stay
  $C8A7,6 Arrive at the wall at high V

@ $C8AD label=IS_NEAR_TO
c $C8AD Is an object near a point?
D $C8AD Carry set if the object's U, V and Z are all within the limits of the point: strictly less than L in U, H in V and 4 in Z. As Knight Lore's.
R $C8AD IX A record whose +$09 to +$0B hold the point's U, V and Z
R $C8AD IY The object
R $C8AD L The limit in U
R $C8AD H The limit in V
R $C8AD O:F Carry set if near
  $C8AD,12 U
  $C8B9,12 V
  $C8C5,13 Z: within 4 sets the carry

@ $C8D2 label=ARCH_NUDGE_TO_CENTRE
c $C8D2 Nudge the player towards the middle of an arch
D $C8D2 If the player's legs are within 15 of the arch's middle in U and V and 4 in Z, sets a nudge of one unit towards its middle line in +$0E (U) or +$0F (V), which #R$C66A adds to his step when he next walks: this is why he slides into line with an arch as he walks through. An arch in a wall of constant U (not mirrored) nudges along V; one in a wall of constant V along U.
D $C8D2 The routine is picked from #R$C8F7, through the jump at the end of #R$C66A, by the pillar's own facing. Knight Lore does the same for each of the player's records; here only the legs are nudged.
R $C8D2 IX The first pillar, holding the arch's middle at +$09 to +$0B
  $C8D2,3 15 either way in U and V
  $C8D5,9 The player's legs, if there are any
  $C8DE,5 Not one that uses doorways
  $C8E3,4 Not near
  $C8E7,10 Graphic 8: the first table
  $C8F1,6 Graphic 6: the second

@ $C8F7 label=ROUTINES_BIT3_SET
w $C8F7 Two tables of four nudge routines
D $C8F7 #R$C8D2 picks the first for a pillar whose graphic has bit 3 set (graphic 8), the second for one without (graphic 6), and the entry by the pillar's facing (#R$C5BD). Graphic 8 has bit 2 clear, so it only ever looks up entries 0 (mirrored) and 2; graphic 6 has it set and only looks up 1 (mirrored) and 3. Each of those four gives the same answer -- mirrored: along U, not: along V -- and the other four are never used.
W $C8F7,2 Graphic 8, mirrored: #R$C91A
W $C8F9,2 Unused
W $C8FB,2 Graphic 8, not mirrored: #R$C907
W $C8FD,2 Unused
@ $C8FF label=ROUTINES_BIT3_CLEAR
W $C8FF,2 Unused
W $C901,2 Graphic 6, mirrored: #R$C91A
W $C903,2 Unused
W $C905,2 Graphic 6, not mirrored: #R$C907

@ $C907 label=NUDGE_ALONG_V
c $C907 Nudge along V
D $C907 For an arch in a wall of constant U: nothing if the player is on its middle line already, otherwise +1 or -1 into +$0F, towards it.
R $C907 IX The pillar, holding the arch's middle
R $C907 IY The player's legs
  $C907,8 On the middle line already
  $C90F,6 +1 if the middle is at a greater V, else -1
  $C915,5 The V nudge

@ $C91A label=NUDGE_ALONG_U
c $C91A Nudge along U
D $C91A For an arch in a wall of constant V: +1 or -1 into +$0E, towards its middle line.
R $C91A IX The pillar, holding the arch's middle
R $C91A IY The player's legs
  $C91A,8 On the middle line already
  $C922,6 +1 if the middle is at a greater U, else -1
  $C928,3 The U nudge

# --------------------------------------------------------------------------
# Building a room
# --------------------------------------------------------------------------

@ $C92C label=BUILD_ROOM
@ $C9AB label=NEXT_PIECE
c $C92C Build a room's object records from the room directory
D $C92C Clears every object record but the player's two, finds the player's room in #R$5E10, and sets the room's colour (ROOM_ATTR) and its half-sizes and floor (ROOM_EXTENT, from #R$5E07). Then fills the records from the top, ROOM_FIRST, downwards: first the scenery, then the objects. Nothing checks that the 48 records are enough.
D $C92C Scenery: each entry is a template number and one more byte, up to an $FF. A scenery template (#R$696D) is a list of 8-byte pieces -- graphic, U, V, Z, the three half-sizes, flags -- ended by a zero, each piece its own record. Every piece of the entry takes the entry's second byte as its +$08: for a doorway that is the room it leads to (#R$C7AD).
D $C92C Objects: groups, each a header byte (bits 0-2 how many less one, bits 3-7 the template) and a position byte for each. An object template (#R$6CE5) is a list of 5-byte pieces -- graphic, the three half-sizes, flags -- ended by a zero, each piece its own record, all at the same place. A position byte gives U = 72 + 16 times bits 0-2, V = 72 + 16 times bits 3-5, and Z = the floor + 12 times bits 6-7; the object's +$08 is this room.
D $C92C Template 31 in a header is not a template: it moves TEMPLATES_AT on 64 bytes, to a second page of templates, and the byte after it is skipped. No room uses it (it never ran). PLACE_NUDGE would add 8 to U (bit 0), 8 to V (bit 1) and the rest to Z; it is cleared here and nothing sets it but the unreached code at #R$CA7C.
D $C92C The count at +1 of the room's record, of the bytes from there to the end, is what stops the build, not the end of the data: the scenery can use it up, or a group be cut short.
R $C92C IX The player's legs, whose +$08 is the room
  $C92C,3 Clear the other object records
  $C92F,10 The first page of object templates, and no nudge
  $C939,9 The first record to fill, the scenery table, the directory
  $C942,7 This room?
  $C949,4 No: on by the count
  $C94D,4 A comparison with the scenery table, whose result nothing uses: the room is assumed to be there
  $C951,2 Next room
  $C953,1 B = the count
  $C954,9 The room's ink, BRIGHT, on black
  $C95D,10 The room's size, bits 3-7 of the same byte
  $C967,22 Three bytes of #R$5E07: the half-sizes in U and V, and the floor
  $C97D,4 Two of the count used; HL on the scenery, DE the record
  $C981,6 The scenery ends at an $FF
  $C987,14 HL = the scenery template, the entry kept on the stack
  $C995,5 A piece: graphic, U, V, Z, half-sizes, flags
  $C99A,5 +$08: the entry's second byte
  $C99F,5 +$09 to +$1F cleared
@ $C9A5 nowarn
  $C9A4,7 The record below
  $C9AB,4 Another piece?
  $C9AF,6 Past the entry's second byte; two of the count, and on to the next entry
  $C9B5,1 The count ran out
  $C9B6,1 The $FF counted
  $C9B7,5 IY = the next record
@ $C9BC label=NEXT_GROUP
  $C9BC,5 C = how many in this group
  $C9C1,6 The header counted; D = the first position
  $C9C7,9 The template number, doubled; 31 moves to the second page
  $C9D0,10 HL = the object template
  $C9DA,1 Kept for the next object of the group
  $C9DB,25 A piece: graphic, half-sizes, flags
  $C9F4,6 This room
  $C9FA,22 U from bits 0-2 of the position
  $CA10,18 V from bits 3-5
  $CA22,25 Z from bits 6-7, 12 a level, on the floor
  $CA3B,16 +$09 to +$1F cleared
@ $CA4B nowarn
  $CA4B,6 The record below
  $CA51,4 Another piece?
  $CA55,5 The position counted; the end of the count ends the room
  $CA5A,4 The end of the group
  $CA5E,8 The next position, the same template
  $CA66,6 DE = the next free record
@ $CA6C label=TEMPLATE_PAGE
  $CA6C,11 Template 31: the next page of templates
  $CA77,5 The byte after it counted and skipped

@ $CA7C label=SET_PLACE_NUDGE
b $CA7C Unreached code: set the builder's nudge
D $CA7C Six bytes no jump reaches: LD A,D, then LD (PLACE_NUDGE),A, then JR back to the step in #R$C92C after template 31 that counts the byte after the header and goes on to the next group. That is a header like template 31's which set PLACE_NUDGE from the byte after it, for the objects that follow. Nothing jumps here, so the nudge is always 0; the bytes are kept as data because their second instruction runs across #R$CA7F.
B $CA7C,3,3

@ $CA7F label=SET_PLACE_NUDGE_END
b $CA7F The rest of the unreached code
D $CA7F The last byte of LD (PLACE_NUDGE),A and a JR back to #R$C92C: see #R$CA7C.
B $CA7F,3,3

@ $CA82 label=ADJUST_PLYR_UVZ_FOR_ROOM_SIZE
c $CA82 Put the player in the doorway he came in by
D $CA82 Called when a room has been built. A U or V of 0 or $FF is the marker an exit (#R$C843 to #R$C89A) left: 0 in U means he left through a wall at low U and comes in by this room's wall at high U, $FF the other way, and the same for V. He is put with his inner edge 2 inside the wall's line, the rest of him in the doorway, and the walk into a room brings him in. #R$CAEE finds the arch in that wall and lines him up with its middle and its floor. Without a marker -- a new game, or a life lost where one began -- he stays where his record says.
D $CA82 Knight Lore does the same with the same markers; the walls are where the room's size (#R$5E07) puts them, so the doorway's place is worked out from ROOM_EXTENT.
R $CA82 IX The player's legs
  $CA82,12 L, H = the room's half-sizes in U and V, less 2
  $CA8E,6 U 0: came in at high U
  $CA94,3 U $FF: came in at low U
  $CA97,6 V 0: came in at high V
  $CA9D,4 V $FF: came in at low V; otherwise nothing to do
  $CAA1,11 At low V: the arch there, and V puts his inner edge 2 inside the wall
  $CAAC,3 Store V
  $CAAF,8 Draw both of his records
  $CAB7,13 The body at the same U and V
  $CAC4,13 At high V
  $CAD1,11 At low U
  $CADC,5 Store U
  $CAE1,13 At high U

@ $CAEE label=FIND_ENTRY_ARCH
c $CAEE Line the player up with the arch he comes in by
D $CAEE The code takes the room's doorways to be its first scenery entries, two pieces each, and each entry's second piece -- the first pillar, graphic 6 or 8, at the second record from the top and every other record down from there -- is what this looks at, until one is not an arch piece (graphics 6 to 9) or four have been tried. The one in the wall he comes in by (U or V at least 192 for a wall at the high end, below 64 for the low) gives him the middle of the arch along the wall and its Z; the body goes 12 above.
R $CAEE C The wall: 0 high U, 1 low U, 2 high V, 3 low V
R $CAEE IX The player's legs
@ $CAF2 nowarn
  $CAEE,9 Four doorways at most, two records apart
  $CAF7,8 Not an arch piece: no more doorways
  $CAFF,10 Which wall
@ $CB09 label=ARCH_AT_LOW_V
  $CB09,7 Low V: an arch with V below 64
@ $CB10 label=NEXT_ARCH
  $CB10,4 The next doorway
  $CB14,1 None in that wall: he keeps the U or V he left with

@ $CB15 label=ALIGN_V_TO_ARCH
c $CB15 Line up in V with an arch in a wall of constant U
D $CB15 V of the arch's middle, 13 on from the first pillar; then, from the fifth instruction on, Z.
R $CB15 IY The first pillar
R $CB15 IX The player's legs
  $CB15,8 V: the middle of the arch
@ $CB1D label=ALIGN_Z_TO_ARCH
  $CB1D,6 Z: the pillar's base
  $CB23,6 The body, 12 above

@ $CB29 label=ALIGN_U_TO_ARCH
c $CB29 Line up in U with an arch in a wall of constant V
D $CB29 U of the arch's middle, 13 back from the first pillar; then Z (#R$CB15).
R $CB29 IY The first pillar
R $CB29 IX The player's legs

@ $CB33 label=ARCH_AT_HIGH_U
c $CB33 An arch in the wall at high U?
D $CB33 Part of #R$CAEE: an arch with U 192 or more lines him up in V.
  $CB33,7 The wall at high U: this one
  $CB3A,2 Otherwise the next

@ $CB3C label=ARCH_AT_LOW_U
c $CB3C An arch in the wall at low U?
D $CB3C Part of #R$CAEE: U below 64.
  $CB3C,7 The wall at low U: this one
  $CB43,2 Otherwise the next

@ $CB45 label=ARCH_AT_HIGH_V
c $CB45 An arch in the wall at high V?
D $CB45 Part of #R$CAEE: V 192 or more lines him up in U.
  $CB45,7 The wall at high V: this one
  $CB4C,2 Otherwise the next

@ $CB4E label=JUMP_L16_D8
c $CB4E Drawing offset X -16, Y -8, by a jump (graphics 10, 11, 76, 82 and 152 to 159)
D $CB4E The whole update routine for these still graphics: a JP to #R$C75F, which is a routine of its own rather than a table entry pointing there directly.

@ $CB51 label=JUMP_L16_D12
c $CB51 Drawing offset X -16, Y -12, by a jump (graphic 77)
D $CB51 A JP to #R$C769. No scenery or object template has graphic 77, and this never ran in the build's sessions.

# --------------------------------------------------------------------------
# Clearing
# --------------------------------------------------------------------------

@ $CB54 label=CLEAR_OBJECTS
c $CB54 Clear every object record but the player's
D $CB54 52 records of 32 bytes from BOLTS: the bolts, the things from the sky and the room's 48.
  $CB54,8 Through #R$CB77

@ $CB5C label=CLEAR_SCREEN
c $CB5C Clear the screen's pixels
D $CB5C 6144 bytes from 16384.

@ $CB6A label=FILL_ATTRS
c $CB6A Fill the screen's attributes with A
D $CB6A 768 bytes from 22528.
R $CB6A A The attribute

@ $CB77 label=CLEAR_MEMORY
c $CB77 Clear BC bytes from HL
R $CB77 HL The first byte
R $CB77 BC How many
  $CB79,7 One at a time: BC is a 16-bit count

@ $CB81 label=CLEAR_BUFFER
c $CB81 Clear the screen buffer
D $CB81 6144 bytes of #R$D88F.

# --------------------------------------------------------------------------
# Things from the sky
# --------------------------------------------------------------------------

@ $CB89 label=BAN_DROPS
c $CB89 Decide whether things may fall from the sky in this room
D $CB89 Sets DROP_BAN to 1 if any of the room's 48 records holds the well (graphic 120), a quest item (112 to 119) or a piece of the pentagram (128 to 135), and to 0 otherwise. #R$CBAB drops nothing while it is 1.
  $CB89,5 IY, B, DE: the room's 48 records (#R$D071)
  $CB8E,7 The well
  $CB95,5 A quest item, done or not
  $CB9A,4 A piece of the pentagram
  $CB9E,8 None of them: things may fall
  $CBA7,4 One of them: nothing falls

@ $CBAB label=SKY_DROP
c $CBAB Perhaps drop something from the sky
D $CBAB Once a turn, from the main loop. When DROP_TIMER runs out it stays at 1, so from then on there is a one-in-four chance each turn (two bits of RANDOM). A drop resets the timer (#R$CC31) whether or not it comes to anything, then takes a free one of the two records at FLYERS, copies #R$CC11 into it, and gives it a U and a V at random and one of the eight graphics at #R$CC09. If the new thing overlaps anything already in the room it is taken away again.
D $CBAB The random U and V are 104 plus a number masked with $2F: 104 to 119 or 136 to 151, never within 8 of the room's middle line. It falls from Z 216.
  $CBAB,5 Nothing falls in this room
  $CBB0,5 Count the timer down
  $CBB5,2 Then try every turn
  $CBB7,6 One chance in four
  $CBBD,3 The timer starts again
  $CBC0,9 The first of the two records, and the template
  $CBC9,8 Both in use: nothing falls
  $CBD1,6 IX = the free record, filled from the template
  $CBD7,10 U at random
  $CBE1,9 V from the refresh register
  $CBEA,19 One of the eight graphics, by bits 3-5 of the random number
  $CBFD,3 Its place on the screen (#R$B2C5)
  $CC00,4 Nothing in the way: it falls (#R$BF1B)
  $CC04,5 Something there: no drop after all

@ $CC09 label=DROP_GRAPHICS
b $CC09 What may fall from the sky: eight graphics, one picked at random
D $CC09 164, 160 (twice) and 48 (twice) are homers (#R$CC4B); 80 (twice) and 168 have update routines in #R$D1F5 and #R$D251.
B $CC09,8,8

@ $CC11 label=FLYER_TEMPLATE
b $CC11 The record a thing from the sky starts as
D $CC11 #R$CBAB copies it and then sets the graphic, U and V.
B $CC11,8,8 Graphic, U, V, Z 216, half-sizes 8, 8 and 8, flags: to be drawn
B $CC19,24,8 The rest zero, the room (+$08) included

@ $CC31 label=RESET_DROP_TIMER
c $CC31 Reset the drop timer: 80 turns while the first quest item is still to do, 8 after
D $CC31 Meant, by its shape, to count the quest items still to do -- records of #R$D432 whose graphic is 112 to 115; a quest item done becomes 116 to 119 -- and set DROP_TIMER to four times two more than that: 8 to 24 turns. But DE is loaded with the record length and never added to HL, so it tests the first record eighteen times: 80 turns while the first quest item is to do, 8 once it is done, whatever the other three are. Measured in the simulator: 80 with none done, 80 with the other three done, 8 with only the first done.
D $CC31 It runs at the start of every room (#R$AF87) as well as after each drop, so the first drop in a room is always at least that many turns away.
  $CC31,9 Eighteen records of 16 bytes, C starting at 2 -- but HL never moves on
  $CC3A,10 A quest item still to do?
  $CC44,7 Four turns for each

# --------------------------------------------------------------------------
# The homers
# --------------------------------------------------------------------------

@ $CC4B label=HOMER
c $CC4B The update routine for a homer (graphics 48 to 51 and 160 to 167)
D $CC4B Flies at the player. Speeds in U, V and Z are kept in sixteenths in +$14, +$15 and +$16; each turn each gains 3 towards the player -- U and V towards his legs (PLAYER_U, PLAYER_V), Z towards his body's Z -- up to +56 or down to -72, and the step for the next turn is the speed plus 8 divided by 16, rounding down: at most 4 units a turn either way. Gravity takes one off the Z step before the move (#R$B979). A move stopped in U or V turns that speed round, so a homer bounces off walls and objects; one stopped in Z keeps its speed (the routine that would turn it, at #R$CCFB, is never called).
D $CC4B The half-sizes in U and V are set to 10 every turn, over the 8 of #R$CC11. The four frames are the low two bits of the graphic, from a count in +$10. Some fall from the sky (#R$CC09); object template 2 is graphic 48, so a room can start with one too.
D $CC4B The last four instructions are where most moving things' updates finish: bits 4 and 5 of the flags, draw it and copy its rectangle to the screen, and #R$B9A7, which marks whatever it overlaps for redrawing.
R $CC4B IX The homer's record
  $CC4B,3 Drawn 12 left and 6 down
  $CC4E,8 Half-sizes 10 in U and V
  $CC56,3 Z step less 1, cut short where it must be, and moved
  $CC59,7 Stopped on any axis?
  $CC60,5 In U: turn the U speed round
  $CC65,7 In V: turn the V speed round
  $CC6C,14 The U speed: 3 towards the player's U
  $CC7A,17 The V speed: 3 towards his V
  $CC8B,17 The Z speed: 3 towards his body's Z
  $CC9C,33 The steps in U, V and Z: each speed plus 8, divided by 16
  $CCBD,15 The player at a greater U, V or Z (or level): 3 up
  $CCCC,18 The next of four frames
@ $CCDE label=SET_WIPE_AND_DRAW_FLAGS
  $CCDE,11 Draw it and copy its rectangle to the screen, and mark what it overlaps

# --------------------------------------------------------------------------
# Range 5
# --------------------------------------------------------------------------

# Pentagram, stage 2, agent 5: $CCE9 up to $D88F -- the last update
# routines (the homing flyer's helpers, the falling, pushed, lifting, sinking,
# bobbing, pacing, roaming and crumbling things, the conveyors), the quest
# (the well, the bucket, the quest items, the pentagram, the collectables),
# the quest's tables, and the sound: effects, beeps, the tune player, the
# note table and the tunes.
#
# The merge must keep these declared spans from the stage-1 annotations
# (the checker does not accept "; span" lines in a fragment):
#   ; span $D432,304   ; span $D718,183   ; span $D7CF,85   ; span $D824,15
#   ; span $D833,20    ; span $D847,12    ; span $D853,28   ; span $D86F,32
#
# Three blocks sna2ctl left as data are code no path reaches: $CCFB, $D56C
# and $D665. The first two are declared c here so the listing shows the
# instructions; each decodes cleanly to its entry's end. $D665 stays data:
# a byte in its middle is data its second half reads, and declared as code
# it makes skool2asm warn (tried in a scratch build in the scratchpad).

# --------------------------------------------------------------------------
# The homing flyer's helpers (#R$CC4B, graphics 48-51 and 160-167)
# --------------------------------------------------------------------------

@ $CCE9 label=BOUNCE_U
c $CCE9 Bounce off in U: reverse the U velocity
D $CCE9 #R$CC4B calls this when its move has bumped into something in U. The velocity at +14 is in sixteenths of a unit, the step at +9 made from it each turn; negating it sends the flyer back the way it came.
R $CCE9 IX the flyer
  $CCE9,8 +14 = -(+14)

@ $CCF2 label=BOUNCE_V
c $CCF2 Bounce off in V: reverse the V velocity
D $CCF2 As #R$CCE9, for V: #R$CC4B calls this when it has bumped into something in V.
R $CCF2 IX the flyer
  $CCF2,8 +15 = -(+15)

@ $CCFB label=BOUNCE_Z
c $CCFB Unused: bounce off in Z
D $CCFB The third of the set, for the Z velocity at +16, and never called: #R$CC4B tests only the U and V bits of what it bumped into, and no other code or table holds this address. sna2ctl left it as data because no session ran it; its nine bytes are LD A,(IX+$16), NEG, LD (IX+$16),A and RET, the pattern of #R$CCE9 and #R$CCF2 with the next offset.
R $CCFB IX the flyer

@ $CD04 label=ACCEL_PLUS
c $CD04 Speed a homing velocity up the positive way
D $CD04 #R$CC4B pulls each of the flyer's three velocities three sixteenths towards the player every turn. This is the pull for a player further along the axis: add 3, and cap the result at 56. A velocity still negative after the add is left alone, so a flyer going the wrong way turns round gradually rather than at once.
D $CD04 The cap is 56 here and -72 in #R$CD0D, which looks lopsided until #R$CC4B turns a velocity into a step: it adds 8 and shifts right four times, and both caps come out as a step of 4, one way or the other.
R $CD04 A the velocity, in sixteenths of a unit
R $CD04 O:A the new velocity
  $CD04,3 add 3; still going the other way: done
  $CD07,6 no faster than 56

@ $CD0D label=ACCEL_MINUS
c $CD0D Speed a homing velocity up the negative way
D $CD0D The pull for a player further back along the axis: subtract 3, and cap the result at -72 (see #R$CD04 for why the caps differ).
R $CD0D A the velocity, in sixteenths of a unit
R $CD0D O:A the new velocity
  $CD0D,3 subtract 3; still going the other way: done
  $CD10,6 no faster than -72

# --------------------------------------------------------------------------
# The collectables, and the things that are pushed about and fall
# --------------------------------------------------------------------------

@ $CD16 label=COLLECTABLE
c $CD16 The update routine for a collectable
D $CD16 Graphics 144 to 148: the five things that must be brought to the pentagram. Anywhere but room 82, or before the pentagram is showing (PENTAGRAM_ON), a collectable is an ordinary thing that falls and can be pushed (it goes on at FALL, in #R$CD81); the player can pick it up and carry it (#R$BF79).
D $CD16 In room 82 with the pentagram showing, it glides without falling towards its own place on the pentagram, one unit a turn in U and in V: the place comes from #R$D562 by the low three bits of the graphic, and #R$D085 steers. When it is there its graphic goes up by 8, in its object record and in its quest record (#R$CF9E), so it is no longer a collectable (152 to 156 are a still thing's), and PLACED counts it. The fifth ends the game: a jump to #R$C302.
R $CD16 IX the collectable's object record
  $CD16,3 the drawing nudge
  $CD19,15 not in room 82, or no pentagram yet: just fall and stop
  $CD28,22 +15 and +16 = its place on the pentagram, from #R$D562 by graphic AND 7
  $CD3E,6 step towards it, and move without falling
  $CD44,17 not there yet: stop, and redraw
  $CD55,12 there: graphic + 8, here and in its quest record
  $CD61,12 one more placed; the fifth wins the game
  $CD6D,3 stop, and redraw

@ $CD70 label=SPIKES
c $CD70 The update routine for the spikes
D $CD70 Graphic 28, a bed of spikes: deadly both ways (#R$C291), and otherwise a thing that falls and can be pushed, as #R$CD81.
R $CD70 IX the object record
  $CD70,3 deadly

@ $CD75 label=HEAVY_BLOCK
@ $CD7C label=SLIDING_TABLE
c $CD75 The update routine for a block that can only fall; and for the table
D $CD75 Graphic 91, a block. The steps in U and V are cleared before it moves, so whatever pushed it this turn has no effect, and it only falls. It is also, with the player, one of the two things that set bit 7 of +17 on what they land on (#R$B890), so it can crumble a crumbling block or start a lift.
D $CD75 Graphic 73, the table, enters at SLIDING_TABLE: its template makes it pushable, and it keeps the step a push gave it, falls, and stops.
R $CD75 IX the object record
  $CD75,7 no sideways step: pushes are lost
  $CD7C,3 the table's way in: its own drawing nudge
  $CD7F,2 fall, and stop

@ $CD81 label=PUSHABLE
@ $CD84 label=FALL
@ $CD87 label=STOP_MOVING
c $CD81 The update routine for things that fall and can be pushed
D $CD81 Graphics 63 and 79 (blocks), 72 (a tree stump), and the tails of many other routines. A push from something walking into it (the collision code copies the pusher's step into a pushable thing's) moves it that far this turn; it also falls one unit a turn, since the fall at #R$B979 takes one off the Z step and STOP_MOVING clears it again.
D $CD81 STOP_MOVING is the common ending: if it moved at all this turn, clear the three steps and have it redrawn; if not, return without a redraw, so a thing at rest costs nothing to draw.
R $CD81 IX the object record
  $CD81,3 the drawing nudge
  $CD84,3 FALL: fall one unit, and move by whatever steps it has
  $CD87,10 STOP_MOVING: did it move?
  $CD91,15 yes: clear the steps, and redraw it and what it overlaps

@ $CDA0 label=SINKING_BLOCK
c $CDA0 The update routine for a block that sinks under him
D $CDA0 Graphic 78, a block that stays where it is until he stands on it, and then sinks a unit a turn for as long as he does. It never falls by itself: its Z step is only ever set by what lands on it, since the player's flags (bit 2) make the collision code pass his Z step to what he lands on (#R$B7E0). Any Z step at all becomes one unit down.
D $CDA0 Measured in the simulator in room 15: stood on, it went from Z 152 down one a turn, and he with it.
R $CDA0 IX the object record
  $CDA0,3 the drawing nudge
  $CDA3,8 no sideways step
  $CDAB,11 pressed on from above: down one unit
  $CDB6,5 move without falling, then stop

@ $CDBB label=LIFT
c $CDBB The update routine for the lift
D $CDBB Graphic 84, a block that carries him up. It keeps its state in +17: bit 0 while it is moving, bit 1 while it is on the way down, and bit 7, set by the collision code when he (or the heavy block, #R$CD75) lands on it (#R$B890).
D $CDBB At rest, it waits for him: landing on it passes his Z step down to it (#R$B7E0), it moves, bumps the floor, and with bit 7 set it starts to rise. Rising, it asks for two units a turn, gives him a Z step of 3 and tells his code he is standing on something (bit 2 of PLAYER_BUMPED); it rises only while it keeps bumping into something above it -- him -- so the moment he steps off it turns round. At a height of 176 it stops, and he is given a Z step of -2. On the way down it sinks one a turn until it bumps into something below, and then it is at rest again.
D $CDBB Measured in the simulator in room 2: he landed on it at Z 128 and it rose one unit a turn with him on top, 12 above it; at 176 he fell, pushing the lift down with him faster and faster, and at the floor it started up again, and so on for as long as he stood there.
E $CDBB The Z step it gives him is written into his record whether or not he is the one on top.
R $CDBB IX the object record
  $CDBB,8 no sideways step
  $CDC3,3 the drawing nudge
  $CDC6,10 move by its Z step, without falling; no sideways step again
  $CDD0,6 moving?
  $CDD6,6 at rest: did something land on it this turn?
  $CDDC,6 was it him?
  $CDE2,10 yes: start moving, upwards
  $CDEC,17 moving, and nothing above it: go down, one a turn
  $CDFD,6 bumped: on the way down, that is the floor or something below
  $CE03,7 on the way up: below 176?
  $CE0A,12 at the top: stay at 176; he is sent down
  $CE16,20 rise: two units a turn for the lift, three for him, and he stands on it
  $CE2A,7 down again: at rest

@ $CE31 label=BOBBER
c $CE31 The update routine for a thing that bobs up and down
D $CE31 Used by graphic 86 through #R$CE9A, which makes it deadly first; graphic 85 comes here directly, but no room places one. It keeps its state in bit 2 of +D, which the kill bits (5 to 7) leave free: clear while it falls, set while it rises.
D $CE31 Falling, it drops one unit a turn; when it lands on something it starts rising, one unit a turn (the 2 it stores on landing is overwritten with 1 before any move uses it; measured in room 88: one unit a turn from the first), until its height reaches 176, when it falls again. If something above stops it rising, it falls at once. When the player (or the heavy block) is standing on it the rise is three a turn; a jump by him clears that.
D $CE31 Measured in the simulator in room 11 (graphic 86, nothing on it): it rose one unit a turn to 176 and fell back one a turn to where it had landed, over and over.
R $CE31 IX the object record
  $CE31,3 the drawing nudge
  $CE34,13 no sideways step; rising?
  $CE41,6 falling: one unit a turn
  $CE47,14 landed: start rising (the 2 stored here is replaced before it is used)
  $CE55,10 no sideways step; redraw it
  $CE5F,11 rising: if he has jumped, he is no longer on it
  $CE6A,13 he is on it, or it is moving: carry on up; stopped: fall
  $CE77,10 one unit a turn up, or three with him on it (the sign of what was tested last)
  $CE81,16 move; at 176 or above, fall from now on
  $CE91,9 stopped from above: fall

@ $CE9A label=DEADLY_BOBBER
c $CE9A The update routine for the deadly head that bobs up and down
D $CE9A Graphic 86, a head: deadly both ways (#R$C291), then as #R$CE31.
R $CE9A IX the object record
  $CE9A,6 deadly, then bob

@ $CEA0 label=DEADLY_PACER_U
@ $CEA3 label=PACER_U
c $CEA0 The update routine for things that pace to and fro in U
D $CEA0 Graphic 92, a head, is deadly (#R$C291) and enters here; graphic 87, a block, enters at PACER_U. Either moves two units a turn along U, the way bit 0 of +10 says (set: forwards), and turns round when it bumps into anything. It never falls. The player standing on the block is carried along, since the collision code gives him the step of what he stands on when he has none of his own (#R$B7E0).
R $CEA0 IX the object record
  $CEA0,3 deadly
  $CEA3,3 PACER_U: the drawing nudge
  $CEA6,13 no step in V or Z; which way?
  $CEB3,17 forwards: two units, and back the other way after a bump
  $CEC4,3 redraw
  $CEC7,19 backwards: two units, and forwards again after a bump

@ $CEDA label=DEADLY_PACER_V
@ $CEDD label=PACER_V
c $CEDA The update routine for things that pace to and fro in V
D $CEDA As #R$CEA0, along V: graphic 93, a head, deadly, enters here; graphic 88, a block, at PACER_V.
R $CEDA IX the object record
  $CEDA,3 deadly
  $CEDD,3 PACER_V: the drawing nudge
  $CEE0,13 no step in U or Z; which way?
  $CEED,17 forwards: two units, and back the other way after a bump
  $CEFE,3 redraw
  $CF01,19 backwards: two units, and forwards again after a bump

@ $CF14 label=PENTAGRAM_PIECE
c $CF14 The update routine for a piece of the pentagram
D $CF14 Graphics 128 to 135, the eight pieces #R$B097 brings into room 82 once PENTAGRAM_ON is set, and 121 to 127, which no room, template or quest record uses. It moves without falling by whatever steps it has, but only a pushable thing (bit 2 of its flags) goes on to be stopped and redrawn; the pieces are not pushable, nothing gives them a step, and they return here without a redraw and never move.
R $CF14 IX the object record
  $CF14,6 the drawing nudge; move without falling
  $CF1A,8 not pushable: done; pushable: stop, and redraw

@ $CF22 label=SPIDER
c $CF22 The update routine for the spider that scuttles at random
D $CF22 Graphic 89: deadly both ways (#R$C291), falling one unit a turn, and flipped on every other turn, which is its scuttle. It moves diagonally, four units a turn in both U and V; when it bumps into something in U or V, or has no step, it picks a new diagonal at random, U by bit 3 of RANDOM and V by bit 3 of R.
R $CF22 IX the object record
  $CF22,13 the drawing nudge; deadly; fall one unit a turn
  $CF2F,15 mirrored on odd turns
  $CF3E,20 bumped in U or V, or still: a new direction
  $CF52,19 four units either way in U, and in V
  $CF65,3 redraw

# --------------------------------------------------------------------------
# The quest: the quest items, the well, the bucket, the pentagram
# --------------------------------------------------------------------------

@ $CF68 label=QUEST_ITEM
c $CF68 The update routine for a quest item
D $CF68 Graphics 112 to 115, the four rough stones the quest is about, and 116 to 119, the same four once done. Nothing happens until the bucket reaches one: #R$D0AC sets bit 0 of +16. Then the item is done: one more on QUEST_DONE, a life added and the lives redrawn (#R$C29A), and its graphic goes up by 4, in the object record and the quest record (#R$CF9E), which turns the rough stone into a finished pillar and takes it out of the bucket's reach (#R$D0AC looks for 112 to 115 only). #R$D13A shows the pentagram if it was the fourth.
E $CF68 The life is added with INC, not in BCD, but lives start at 5 and only the four quest items add any, so they never pass 9.
R $CF68 IX the object record
  $CF68,6 the drawing nudge; move without falling
  $CF6E,5 has the bucket reached it?
  $CF73,7 one more quest item done
  $CF7A,14 and a life more, shown on the panel
  $CF88,16 done with the bucket; graphic + 4, here and in its quest record
  $CF98,6 all four? Then redraw

@ $CF9E label=CHANGE_GRAPHIC
c $CF9E Give a quest thing a new graphic, in its quest record and its object record
D $CF9E Finds the quest record (#R$D432) that has the old graphic and gives it and the object the new one, so the change lasts when he leaves the room (#R$B115 matches the records by graphic). If no quest record has the old graphic, neither changes.
R $CF9E A the old graphic
R $CF9E C the new graphic
R $CF9E IX the object record
  $CF9E,13 find the quest record with the old graphic; none: done
  $CFAB,7 both get the new one

@ $CFB2 label=BOLT_TOUCHING
c $CFB2 Is one of his bolts touching this object?
D $CFB2 Tests the two bolt records against IX with the intersection test in #R$C206, which counts boxes within two units of each other as touching.
D $CFB2 The two slots are not tested alike: the first goes in past #R$C206's test for a puff (graphics 64 to 71, what a bolt becomes when it hits something), so a puff there still counts; the second goes in before it, and a puff there does not. Watched: as shipped, the bucket came after 7 shots; with both slots treated alike, after 32.
R $CFB2 IX the object record
R $CFB2 O:F Z set if a bolt is touching it (and D is 0)
  $CFB2,17 the first bolt; touching: done
  $CFC3,15 the second

@ $CFD2 label=WELL
c $CFD2 The update routine for the well
D $CFD2 Graphic 120. Shot at enough, it puts out the bucket. It counts in +14 the turns on which one of his bolts touches it (#R$CFB2), and on the 32nd, with no bucket already out (BUCKET_OUT) and none in the room, and a free record for one, it makes the bucket: a copy of its own record with graphic 90, at the well's U, 8 further in V, at a height of 141, rising one unit (so it hangs there for a turn and then falls), pushable, and linked to the quest's bucket record (QUEST_BUCKET, in #R$D432), which gets the graphic and the room.
D $CFD2 The count is kept in the well's own record, which is rebuilt from the room's data every time the room is entered, so the 32 must come in one visit.
R $CFD2 IX the well's object record
  $CFD2,6 the drawing nudge; move without falling
  $CFD8,5 a bucket out already: nothing more
  $CFDD,4 no bolt touching: nothing
  $CFE1,9 the 32nd turn a bolt has touched it?
  $CFEA,17 start the count again; a bucket in the room already: nothing
  $CFFB,14 find a free record; none: nothing
  $D009,11 copy the well's record into it
  $D014,28 graphic 90, height 141, half-sizes 8, 8, 12, flags $14, rising one unit
  $D030,9 linked to the quest's bucket record
  $D039,14 at the well's U, 8 further in V
  $D047,5 the bucket is out
  $D04C,20 the new record: its nudge, its place on screen, a move, and drawn
  $D060,17 the quest's bucket record gets the graphic and the room; redraw the well

@ $D071 label=ROOM_OBJECT_LOOP
c $D071 Set up a walk through the room's 48 object records
D $D071 For a loop of the form test (IY+n), ADD IY,DE, DJNZ.
R $D071 O:IY the first of the room's records, ROOM_OBJECTS
R $D071 O:DE 32, the size of a record
R $D071 O:B 48, the number of them
  $D071,10 DE = 32, IY = ROOM_OBJECTS, B = 48

@ $D07B label=QUEST_RECORD_LOOP
c $D07B Set up a walk through the quest records
D $D07B As #R$D071, for the eighteen quest records at #R$D432.
R $D07B O:IY the first quest record
R $D07B O:DE 16, the size of a record
R $D07B O:B 18, the number of them
  $D07B,10 DE = 16, IY = #R$D432, B = 18

@ $D085 label=HEAD_FOR_TARGET
c $D085 Steer towards the place in +15 and +16
D $D085 Sets the step in U to one unit towards the U in +15, and the step in V to one unit towards the V in +16. An axis already there keeps the step it had, which the callers have cleared the turn before, so the thing goes diagonally until one axis matches and then straight.
R $D085 IX the object record, with the target U and V in +15 and +16
  $D085,16 U: one unit down, or...
  $D095,4 ...one unit up
  $D099,14 V: one unit down, or...
  $D0A7,5 ...one unit up

@ $D0AC label=BUCKET
c $D0AC The update routine for the bucket
D $D0AC Graphic 90. Bit 0 of +14 says whether it has a quest item to go to. Until it has, it falls one unit a turn, and looks for a quest item not yet done (graphics 112 to 115) among the room's records each turn; the well's rooms have none, so it falls to the ground there and waits to be carried (#R$BF79). Put down where a quest item is, it finds it, takes its U and V as the target, and from then on rises one unit a turn to a height of 176 while it steers towards the item (#R$D085), without falling.
D $D0AC When it can move no more -- above the item at the top of its rise, or stopped by something in every direction -- it finds the quest item in the room again and sets bit 0 of its +16, which #R$CF68 acts on. Then the bucket's work is done: BUCKET_OUT is cleared so the well can give another, the quest-item tune plays, the bucket's quest record is emptied, and the bucket turns into a puff (#R$C107).
R $D0AC IX the bucket's object record
  $D0AC,3 the drawing nudge
  $D0AF,6 not yet going to a quest item
  $D0B5,14 going: steer to it, and rise while below 176
  $D0C3,15 move without falling; moved: stop, and redraw
  $D0D2,20 stuck: find the quest item not yet done in this room; none: stop
  $D0E6,4 tell it the bucket has reached it
  $D0EA,10 the well may give another bucket; the quest-item tune
  $D0F4,17 empty the bucket's quest record...
  $D105,7 ...and the bucket becomes a puff
  $D10C,7 not going anywhere: fall one unit
  $D113,20 a quest item not yet done in this room? None: stop
  $D127,19 there is: its U and V are the target, and the bucket is on its way

@ $D13A label=ALL_FOUR_DONE
c $D13A If all four quest items are done, show the pentagram
D $D13A Counts the quest records whose graphic is 116 to 119, the quest items done. With all four, each piece of the pentagram (graphics 128 to 135) gets bit 4 of its flags, and PENTAGRAM_ON is set, which is what lets #R$B097 bring the pieces into room 82 the next time he enters it and makes the collectables there glide to their places (#R$CD16).
E $D13A Two of its writes have no effect found: bit 4 of the pieces' flags, which #R$B097 sets anyway as it brings them in; and bit 0 of +11 of the quest item that called, the high byte of its quest record's address, which makes it point 256 bytes further on. Only a carried thing's link is ever followed (#R$BF79), and a quest item cannot be picked up (#R$C0D4), so nothing reads it.
R $D13A IX the quest item that has just been done
  $D13A,19 count the quest items done
  $D14D,4 not all four: done
  $D151,12 each piece of the pentagram...
  $D15D,4 (a write to the quest item's link that nothing reads)
  $D161,14 ...is to be drawn, and the pentagram is showing

@ $D16F label=NEW_QUEST
c $D16F Set out the quest's things for a new game
D $D16F Copies the eighteen records of #R$D312 to #R$D432, and then puts the five collectables (records 4 to 8) in five consecutive places from #R$D1A5, the first chosen by the random number from the first sixteen: each gets its room, U, V and Z from its place. Called by #R$AF87 once the start tune has played.
  $D16F,11 the quest records as a game starts
  $D17A,12 a random place, 0 to 15, four bytes each
  $D186,9 for the five collectables' records, from record 4
  $D18F,4 the room...
  $D193,11 ...then U, V and Z
  $D19E,7 the next place, the next record

@ $D1A5 label=SPOTS
b $D1A5 Where the collectables can start
D $D1A5 Twenty places, four bytes each: the room, then U, V and Z. #R$D16F takes five in a row, starting at one of the first sixteen chosen at random, so a game's five collectables are always five neighbours in this list and places 16 to 19 are only ever used by the later ones.

# --------------------------------------------------------------------------
# The things that fall from the sky, the crumbling block and the conveyors
# --------------------------------------------------------------------------

@ $D1F5 label=ROAMER
@ $D1FD label=SKY_ROAMER
c $D1F5 The update routine for a spider that runs straight, and a creature from the sky
D $D1F5 Graphics 16 and 17, a spider (both show the same sprite), enter here and flip their picture every turn as they go; graphics 80 and 81, a creature that falls from the sky (#R$CBAB), enter at SKY_ROAMER, which skips the flip. Either is deadly both ways (#R$C291), and falls, faster each turn since its steps are never cleared, but never lower than 129: below that it is put back at 129 with no fall.
D $D1F5 It runs straight at four units a turn until it bumps into something, which the collision code shows by clearing the step. Then it picks a new way, the sign from bit 3 of R: along U if the bump was in V, otherwise along V. The way it faces goes with the way it runs: bit 0 of the graphic and the mirror bit (6) of the flags make four facings from two pictures.
R $D1F5 IX the object record
  $D1F5,8 flip the picture
  $D1FD,3 SKY_ROAMER: the drawing nudge
  $D200,6 deadly; fall
  $D206,15 no lower than 129
  $D215,9 still moving: redraw
  $D21E,6 stopped: four units, either way
  $D224,19 not bumped in V: along V, graphic odd, not mirrored...
  $D237,11 ...bumped in V: along U, graphic even, mirrored
  $D242,15 going backwards: the other graphic of the two; redraw

@ $D251 label=SKY_WALKER
c $D251 The update routine for the walker from the sky
D $D251 Graphics 168 to 171, a creature that falls from the sky (#R$CBAB) and walks. As #R$D1F5, but its picture changes every turn between the two graphics of a pair (bit 0), which is its walk, and bit 1 of the graphic is what goes with the way it runs.
R $D251 IX the object record
  $D251,9 the drawing nudge; deadly; fall
  $D25A,8 the next step of the walk
  $D262,15 no lower than 129
  $D271,9 still moving: redraw
  $D27A,6 stopped: four units, either way
  $D280,19 not bumped in V: along V, the second pair, not mirrored...
  $D293,11 ...bumped in V: along U, the first pair, mirrored
  $D29E,15 going backwards: the other pair; redraw

@ $D2AD label=CRUMBLING_BLOCK
c $D2AD The update routine for the crumbling block
D $D2AD Graphics 136 to 139: a block that crumbles a stage for each turn he stands on it, and vanishes after the fourth. It needs both bit 7 of +17, which the collision code sets when he (or the heavy block, #R$CD75) lands on it (#R$B890), and bit 3 of +D, set for anything landing on it (#R$B7E0); it clears both, then moves up a graphic, or from 139 becomes graphic 1, which #R$B3D3 rubs out and turns into an empty record.
D $D2AD Measured in the simulator in room 4: he landed on it and it went 136, 137, 138, 139, gone, a turn each, and he fell.
R $D2AD IX the object record
  $D2AD,10 the drawing nudge; no fall; move
  $D2B7,18 he has landed on it this turn?
  $D2C9,14 the next stage; redraw
  $D2D7,7 after the last: vanish

@ $D2DE label=CONVEYOR_PLUS_U
c $D2DE The update routine for a conveyor that carries things forwards in U
D $D2DE Graphic 140. What stands on a conveyor is carried by the collision code, not here: when something lands on one of graphics 140 to 143, #R$B866 adds to its step the pair from #R$D30A for that graphic, on every other turn, once a turn -- bit 3 of the conveyor's +D says it has pushed this turn. All this routine does is clear that bit, so it can push again next turn.
D $D2DE Measured in the simulator in room 37: standing on graphic 140 he went up two units in U every other turn, and on graphic 142 the same in V.
R $D2DE IX the object record
  $D2DE,11 the drawing nudge; ready to push again; move without falling

@ $D2E9 label=CONVEYOR_MINUS_U
c $D2E9 The update routine for a conveyor that carries things backwards in U
D $D2E9 Graphic 141; the same code as #R$D2DE, a copy for each graphic. No room has one: this never ran in the build's sessions.
R $D2E9 IX the object record
  $D2E9,11 the drawing nudge; ready to push again; move without falling

@ $D2F4 label=CONVEYOR_PLUS_V
c $D2F4 The update routine for a conveyor that carries things forwards in V
D $D2F4 Graphic 142; the same code as #R$D2DE.
R $D2F4 IX the object record
  $D2F4,11 the drawing nudge; ready to push again; move without falling

@ $D2FF label=CONVEYOR_MINUS_V
c $D2FF The update routine for a conveyor that carries things backwards in V
D $D2FF Graphic 143; the same code as #R$D2DE.
R $D2FF IX the object record
  $D2FF,11 the drawing nudge; ready to push again; move without falling

@ $D30A label=CONVEYOR_STEPS
b $D30A What each conveyor adds to the step of what stands on it
D $D30A Four pairs of U and V, by the conveyor's graphic less 140 (its low two bits): +2 in U, -2 in U, +2 in V, -2 in V. Read by #R$B866 on every other turn.
B $D30A,8,2 Graphics 140 to 143: (2, 0), (-2, 0), (0, 2), (0, -2)

# --------------------------------------------------------------------------
# The quest's records
# --------------------------------------------------------------------------

@ $D312 label=QUEST_START
@ $D422 label=QUEST_START_BUCKET
b $D312 The quest's things, as a game starts
D $D312 Eighteen records of sixteen bytes, the first sixteen bytes of an object record (#R$A76F): 0-3 the quest items, 4-8 the collectables, 9-16 the pieces of the pentagram, 17 the bucket, empty until the well gives one (labelled QUEST_START_BUCKET). #R$D16F copies them to #R$D432 at every new game and gives the collectables their places, so the rooms and positions of records 4 to 8 here are never used.
D $D312 #R$B097 loads QUEST_START_BUCKET's address and adds 16 before it looks at a record, so the address it wants is only "16 bytes before #R$D432"; it reads nothing here.

@ $D432 label=QUEST_RECORDS
@ $D472 label=QUEST_COLLECTABLES
@ $D542 label=QUEST_BUCKET
b $D432 The quest's things, as they are now
D $D432 #R$D312 copied here at every new game (#R$D16F) and kept up to date: #R$B097 puts the records of the room he enters into the object records, linking each to its record through +10 and +11; #R$B115 copies them back as he leaves, finding each by its graphic; a thing picked up has its record's graphic cleared, and given back when it is put down (#R$BF79). A record with graphic 0 is in no room.
D $D432 Eighteen records are used. The block is nineteen long, and the last sixteen bytes nothing reads or writes. Zero on the tape.
B $D432,288,16
B $D552,16,8 Nineteenth record: unused

@ $D562 label=TARGETS
b $D562 Where the collectables settle in room 82
D $D562 Five pairs of U and V, one for each collectable, by its graphic less 144 (its low three bits): where #R$CD16 steers it once the pentagram is showing. There is no height: it glides at the height it has.

# --------------------------------------------------------------------------
# Sound: code no path reaches, and its tables
# --------------------------------------------------------------------------

@ $D56C label=BLIP_BY_TURN
c $D56C Unused: a blip at a pitch chosen by the turn counter
D $D56C No code or table holds this address, and no session ran it. The 27 bytes decode cleanly up to #R$D587: BC = the address of #R$D587; BIT 1,(IX+$07); RES 1,(IX+$07); RET Z; A = TURNS AND 15; B = the byte at BC plus that; C = 12; JP #R$D67B. So: if bit 1 of the object's flags was set, clear it and play twelve waves at one of sixteen pitches, picked by the turn counter.
D $D56C It looks like Knight Lore's blip for the movable block, which plays four waves at one of eight pitches picked by the frame counter every frame; here it is gated on a flag bit and left unused. Bit 1 of the flags is the one the collision code sets on the record it is moving (#R$B6ED) and on a puff (#R$C107).
R $D56C IX an object record

@ $D587 label=BLIP_PITCHES
b $D587 Pitches for the unused blip at #R$D56C
D $D587 Sixteen half-wave counts from here for #R$D682, every one a multiple of 16 (the larger, the lower). After them, up to #R$D5D7, are 64 more bytes of the same kind that no code reads: a run of 32 that climbs from $20 to $90 and back two at a time, and two of 16. sna2ctl took some of the bytes for text, so the tables are cut into the entries that follow at places that mean nothing.
B $D587,3,3

@ $D58A label=BLIP_PITCHES_B
b $D58A More of the unused blip's pitches
B $D58A,1,1

@ $D58B label=BLIP_PITCHES_C
b $D58B More of the unused blip's pitches
B $D58B,4,4

@ $D58F label=BLIP_PITCHES_D
b $D58F More of the unused blip's pitches
B $D58F,1,1

@ $D590 label=BLIP_PITCHES_E
b $D590 More of the unused blip's pitches
B $D590,4,4

@ $D594 label=BLIP_PITCHES_F
b $D594 More of the unused blip's pitches
B $D594,1,1

@ $D595 label=BLIP_PITCHES_G
b $D595 The last of the unused blip's pitches, and the start of an unread run
D $D595 Two bytes finish the sixteen of #R$D587; the four after them start the run of 32 that climbs and falls, which no code reads.
B $D595,6,6

@ $D59B label=SWEEP_PITCHES
b $D59B More of the unread run of pitches
B $D59B,24,8

@ $D5B3 label=SWEEP_PITCHES_B
b $D5B3 The end of the unread run of pitches
B $D5B3,4,4

@ $D5B7 label=MORE_PITCHES
b $D5B7 Two more unread tables of pitches
D $D5B7 Sixteen bytes that fall, zigzagging, from $90 to $20, then the start of sixteen that repeat a pattern of eight; no code reads either.
B $D5B7,16,8 Falling
B $D5C7,3,3 The start of the repeating pattern

@ $D5CA label=MORE_PITCHES_B
b $D5CA More of the repeating pattern
B $D5CA,5,5

@ $D5CF label=MORE_PITCHES_C
b $D5CF More of the repeating pattern
B $D5CF,3,3

@ $D5D2 label=MORE_PITCHES_D
b $D5D2 The end of the repeating pattern
B $D5D2,5,5

# --------------------------------------------------------------------------
# Sound: the effects
# --------------------------------------------------------------------------

@ $D5D7 label=PAUSE_BEEP
c $D5D7 The pause beep
D $D5D7 Twelve waves, played by #R$B4E0 as the game pauses and again as it goes on. The pitch is the effect counter's first byte (SOUND_COUNT) plus 64, after adding one to it -- so each pause also gives the sound effect under way, or the last one, an extra turn or two when play resumes.
  $D5D7,5 one more on the effect's count
  $D5DC,8 twelve waves at 64 plus that

@ $D5E4 label=JUMP_SOUND
c $D5E4 The jump's warble
D $D5E4 Sixteen single waves, the half-wave count scrambled from the step count with an XOR as Knight Lore's werewolf warble does (with $A5 for its $55). #R$C56C plays it as he leaves the ground.
  $D5E4,14 for C = 16 down to 1: one wave at (C XOR $A5) + C

@ $D5F2 label=EFFECT_NOTE
c $D5F2 Play this turn's note of the sound effect under way
D $D5F2 Called by #R$B00C every turn. SOUND_COUNT is two bytes: how many notes are left, and which effect. While the count is not zero, this takes one off and plays twelve waves at the pitch found at the effect's address in #R$D60D plus the count before it was taken: the notes run backwards from the end, and the byte at the effect's address itself is never played.
D $D5F2 Only two effects are started: 0, four notes, when a room has been entered (#R$B00C), and 1, five notes, as he picks something up or puts it down (#R$BF79). Effects 2 and 3 have their notes but nothing starts them.
  $D5F2,6 nothing under way: done
  $D5F8,2 one note fewer; keep the count before
  $D5FA,8 HL = the effect's notes (#R$D60D)
  $D602,11 twelve waves at the note the count points to

@ $D60D label=EFFECTS
@ $D615 label=EFFECT_PITCHES
b $D60D The sound effects
D $D60D The addresses of the four effects' notes, then the notes: half-wave counts for #R$D682. An effect of n notes plays the n bytes after its address, the last first (#R$D5F2). Effect 0, entering a room, four notes: the last two bytes of this block and the first two of #R$D618. Effect 1, picking up or putting down, five notes: the last byte of #R$D618 and the first four of #R$D61B, played falling in pitch. Effects 2 and 3 are never started; their addresses point further into #R$D61B, the byte at effect 2's being effect 1's last note.
W $D60D,8,2 Effects 0 to 3
B $D615,3,3 Effect 0's address byte, never played, then its first two notes

@ $D618 label=EFFECT_PITCHES_B
b $D618 More of the effects' notes
D $D618 sna2ctl took these three bytes for text. The first two are effect 0's last two in memory (the first two it plays); the third is effect 1's first in memory (the last it plays).
B $D618,3,3

@ $D61B label=EFFECT_PITCHES_C
b $D61B The rest of the effects' notes
D $D61B Effect 1's other four notes, then what effects 2 and 3 would play if anything started them.
B $D61B,14,8

@ $D629 label=FIRE_SOUND
c $D629 The sound of a bolt being fired
D $D629 32 single waves; each half-wave count is the step count less the one before. #R$C126 comes here straight from an LDIR that leaves B zero, so the counts alternate between a short one falling from 32 and a long one falling from 255: a high note and a low one, interleaved.
R $D629 B the count to start from
  $D629,12 for C = 32 down to 1: one wave at C less the last count

@ $D635 label=FOOTSTEP
c $D635 A footstep
D $D635 #R$C58D calls this for every step of his walk; STEP_SOUND counts them, and every fourth plays two waves, at a half-wave count of 64 and 96 by turns.
  $D635,9 one more step; which pitch?
  $D63E,8 every fourth: two waves at 64...
  $D646,8 ...or at 96

@ $D64E label=PUFF_SOUND
c $D64E The sound of a puff
D $D64E Four single waves at pitches read from the ROM, as Knight Lore's crashes and sparkles are. The address is the word at RANDOM with its high byte cut to five bits: the random number is one byte, and the byte after it, the high one here, is BUCKET_OUT, which is 0 or 1, so the pitches come from the first 512 bytes of the ROM. Played by #R$C111 as a puff begins.
  $D64E,9 HL = an address in the ROM; four waves
  $D657,14 each at the next ROM byte, less its top bit

@ $D665 label=BEEP_BY_GRAPHIC
b $D665 Unused: two more beeps, left as data
D $D665 Code no path reaches: no code or table holds any address in it, and no session ran it. It stays data because a byte in its middle is data that its second half reads; declared as code, that byte becomes a NOP which an LD reads, and skool2asm warns (tried in a scratch build). In order:
D $D665 Fourteen bytes: LD A,(IX+$00); CPL; RRCA three times; AND $E0; LD B,A; LD C,$06; JR to #R$D67B. Six waves pitched by the object's graphic, the top three bits of its complement rotated right three times.
D $D665 One byte, zero on the tape and written by nothing: the pitch the next part reads.
D $D665 Seven bytes: LD A from that byte; CPL; LD B,A; LD C,$08; and on into #R$D67B, which follows. Eight waves pitched by the complement of the spare byte.
B $D665,22,8

# --------------------------------------------------------------------------
# Sound: waves, tables, tunes
# --------------------------------------------------------------------------

@ $D67B label=BEEP
c $D67B Beep: C waves of half-wave count B
D $D67B The common tail of the effects. #R$D682 leaves B as it found it, so every wave has the same pitch.
R $D67B B the half-wave count (0 is 256)
R $D67B C the number of waves
  $D67B,7 C waves

@ $D682 label=CLICK
c $D682 One wave
D $D682 Speaker bit on for B turns of a 13 T-state loop, then off for as long, with the border black throughout. A wave takes 26 times B plus a caller's overhead: 82 T-states within a BEEP, 101 for the jump, 94 for the bolt firing and 151 for the puff (measured): a count of 128 comes out at about 1kHz. The same routine as Knight Lore's.
R $D682 B the half-wave count, kept
  $D682,8 speaker on; wait
  $D68A,8 speaker off; wait; B back

@ $D692 label=TABLE_WORD
c $D692 Look up a word in a table
R $D692 A the index
R $D692 BC the table
R $D692 O:HL the word at BC + 2A
  $D692,10 HL = (BC + 2 * A)

@ $D69C label=PLAY_TUNE_ONCE
c $D69C Play the menu's tune at DE, once, until a key is pressed
D $D69C The menu (#R$BB74) calls this every time round its loop. TUNE_HEARD remembers that the tune has been played, so it plays only the first time; #R$AF87 clears it with the rest of the game's variables after every game, so it plays again then. Before each note the whole keyboard is read, and any key stops the tune at once.
R $D69C DE the tune
  $D69C,6 played already: done
  $D6A2,2 not again
  $D6A4,7 A = 0 reads every half-row at once: any key stops it
  $D6AB,10 $FF ends the tune; play a note, and look at the keys again

@ $D6B5 label=PLAY_TUNE
c $D6B5 Play the tune at DE
D $D6B5 Plays the whole tune and returns; nothing else happens meanwhile. Used by #R$AF87 as a game starts, #R$C302 and GAME_OVER (in #R$C302) as it ends, and #R$D0AC when the bucket reaches a quest item.
R $D6B5 DE the tune
  $D6B5,10 $FF ends it; play the note, and the next
  $D6BF,1 DE is left pointing at the $FF

@ $D6C0 label=PLAY_NOTE
c $D6C0 Play one note
D $D6C0 A note byte's low six bits index #R$D718, with 0 a rest; its top two bits are its length less one, one to four units. The note's three bytes are two loop counts that time each half of a wave and how many waves make one unit, and the wave count rises with the pitch, which keeps every unit close to 0.155 seconds whatever the note. The speaker is driven directly, off for one half-wave and on for the other, with the border black.
D $D6C0 The routine and #R$D718 are byte for byte Knight Lore's (play_note there), at other addresses.
R $D6C0 A the note byte
R $D6C0 DE the address of the note byte; on exit, the next one
  $D6C0,4 index 0 is a rest
  $D6C4,11 HL = #R$D718 + 3 * index
  $D6CF,7 B and C time the half-wave; HL = the number of waves in one unit
  $D6D6,6 the top two bits: the length, one to four units
  $D6DC,9 HL = the waves in one unit times the length
  $D6E5,1 the tune pointer back in DE
  $D6E6,10 speaker off, border black; wait
  $D6F0,11 speaker on; wait
  $D6FB,5 until all the waves are done
  $D700,2 on to the next note byte
  $D702,8 a rest: one to four units...
  $D70A,14 ...each 17163 turns of a 26 T-state loop, about 0.127 seconds (no tune has a rest)

@ $D718 label=NOTES
b $D718 The notes: 61 of three bytes
D $D718 Indexed by the low six bits of a note byte (#R$D6C0): the first two bytes are the B and C counts that time each half-wave, the third how many waves make one unit of length. Row 0 stands for a rest and is never read.
D $D718 The same 183 bytes as Knight Lore's note table, and so the same scale: a semitone a row for five octaves, G#1 at row 1 and A4 (440Hz) at row 38, with the timing drifting a little sharp at the bottom and flat at the top, and row 18 a copy of row 17's pitch where C#3 should be. The comments are that table's, worked out from the loop timings at 3.5MHz.
B $D718,3 index 0 is a rest, so this row is never read
B $D71B,3 1: about 52.6 Hz, G#1; 8 cycles
B $D71E,3 2: about 55.7 Hz, A1; 9 cycles
B $D721,3 3: about 59.0 Hz, A#1; 9 cycles
B $D724,3 4: about 62.5 Hz, B1; 10 cycles
B $D727,3 5: about 66.2 Hz, C2; 10 cycles
B $D72A,3 6: about 70.1 Hz, C#2; 11 cycles
B $D72D,3 7: about 74.3 Hz, D2; 12 cycles
B $D730,3 8: about 78.7 Hz, D#2; 12 cycles
B $D733,3 9: about 83.4 Hz, E2; 13 cycles
B $D736,3 10: about 88.4 Hz, F2; 14 cycles
B $D739,3 11: about 93.6 Hz, F#2; 15 cycles
B $D73C,3 12: about 99.1 Hz, G2; 15 cycles
B $D73F,3 13: about 105 Hz, G#2; 16 cycles
B $D742,3 14: about 111 Hz, A2; 17 cycles
B $D745,3 15: about 118 Hz, A#2; 18 cycles
B $D748,3 16: about 125 Hz, B2; 19 cycles
B $D74B,3 17: about 132 Hz, C3; 21 cycles
B $D74E,3 18: the same pitch bytes as 17, so C#3 is missing -- probably a slip, since the cycle count carries on as for C#3; 22 cycles
B $D751,3 19: about 148 Hz, D3; 23 cycles
B $D754,3 20: about 157 Hz, D#3; 25 cycles
B $D757,3 21: about 166 Hz, E3; 26 cycles
B $D75A,3 22: about 176 Hz, F3; 28 cycles
B $D75D,3 23: about 187 Hz, F#3; 29 cycles
B $D760,3 24: about 198 Hz, G3; 31 cycles
B $D763,3 25: about 209 Hz, G#3; 33 cycles
B $D766,3 26: about 222 Hz, A3; 35 cycles
B $D769,3 27: about 235 Hz, A#3; 37 cycles
B $D76C,3 28: about 248 Hz, B3; 39 cycles
B $D76F,3 29: about 263 Hz, C4; 41 cycles
B $D772,3 30: about 279 Hz, C#4; 44 cycles
B $D775,3 31: about 296 Hz, D4; 46 cycles
B $D778,3 32: about 313 Hz, D#4; 49 cycles
B $D77B,3 33: about 331 Hz, E4; 52 cycles
B $D77E,3 34: about 350 Hz, F4; 55 cycles
B $D781,3 35: about 371 Hz, F#4; 58 cycles
B $D784,3 36: about 393 Hz, G4; 62 cycles
B $D787,3 37: about 415 Hz, G#4; 65 cycles
B $D78A,3 38: about 440 Hz, A4; 69 cycles
B $D78D,3 39: about 465 Hz, A#4; 73 cycles
B $D790,3 40: about 493 Hz, B4; 78 cycles
B $D793,3 41: about 523 Hz, C5; 82 cycles
B $D796,3 42: about 553 Hz, C#5; 87 cycles
B $D799,3 43: about 584 Hz, D5; 93 cycles
B $D79C,3 44: about 619 Hz, D#5; 98 cycles
B $D79F,3 45: about 656 Hz, E5; 104 cycles
B $D7A2,3 46: about 696 Hz, F5; 110 cycles
B $D7A5,3 47: about 734 Hz, F#5; 117 cycles
B $D7A8,3 48: about 777 Hz, G5; 123 cycles
B $D7AB,3 49: about 824 Hz, G#5; 131 cycles
B $D7AE,3 50: about 872 Hz, A5; 139 cycles
B $D7B1,3 51: about 920 Hz, A#5; 147 cycles
B $D7B4,3 52: about 973 Hz, B5; 156 cycles
B $D7B7,3 53: about 1033 Hz, C6; 165 cycles
B $D7BA,3 54: about 1091 Hz, C#6; 175 cycles
B $D7BD,3 55: about 1147 Hz, D6; 185 cycles
B $D7C0,3 56: about 1220 Hz, D#6; 196 cycles
B $D7C3,3 57: about 1290 Hz, E6; 208 cycles
B $D7C6,3 58: about 1355 Hz, F6; 220 cycles
B $D7C9,3 59: about 1442 Hz, F#6; 233 cycles
B $D7CC,3 60: about 1524 Hz, G6; 247 cycles

@ $D7CF label=TUNE_MENU
b $D7CF The menu's tune
D $D7CF Played under the menu by #R$D69C, the first time the menu is shown after a game, until a key is pressed.
D $D7CF A tune is a string of note bytes ended by $FF: the low six bits of a note index #R$D718 (0 would be a rest, and no tune has one), the top two bits its length less one, so a note lasts one to four units of about 0.155 seconds. The comments name each note by the step of the note table's scale it uses and give lengths over one unit as x2, x3 or x4. The other tunes are in the same format.
B $D7CF,16,8 D#5 x2, C5, C#5, D#5, C5, C#5 x2, C#5 x2, C5, C#5, D#5, C5, A#4 x2, D#5 x2, C5, C#5, D#5
B $D7DF,16,8 C5, C#5 x2, C5, C#5, D#5 x2, D#4 x2, G#4 x2, D#5 x2, C5, C#5, D#5, C5, C#5 x2, C#5 x2, C5, C#5
B $D7EF,16,8 D#5, C5, A#4 x2, D#5 x2, C5, C#5, D#5, C5, C#5 x2, C5, C#5, D#5 x2, D#4 x2, G#4 x3, A#4, C5 x2
B $D7FF,16,8 G#4 x2, C#5 x3, A#4, C5 x2, G#4 x2, A#4 x3, A#4, C5, C#5, D#5, C5, C#5 x2, C5, C#5, D#5 x2, D#4 x2
B $D80F,16,8 G#4 x3, A#4, C5 x2, G#4 x2, C#5 x3, A#4, C5 x2, G#4 x2, A#4 x3, A#4, C5, C#5, D#5, C5, C#5 x2, C5
B $D81F,5,8 C#5, D#5 x2, D#4 x2, G#4 x3, end

@ $D824 label=TUNE_UNUSED
b $D824 A tune no code plays
D $D824 In the tunes' format (#R$D7CF), and nothing refers to it: perhaps one the game once used, or meant to.
B $D824,15,8 A#4, A#4 x2, A#4 x2, F#4, A#4 x2, C#5 x4, C#4 x4, F#4, F#4, C#4 x2, A#3 x2, G#3 x2, F#3 x4, F#4, end

@ $D833 label=TUNE_START
b $D833 The tune a game starts with
D $D833 Played in full by #R$AF87 once 0 has been pressed at the menu, before the quest is set out.
B $D833,16,8 G#4 x2, B4 x2, D#5 x2, G#5 x2, F#5 x2, E5, D#5, F#5, E5, C#5 x2, E5 x2, D#5, C#5, D#5, G#5, D#5 x2
B $D843,4,8 B4 x2, A#4 x2, G#4 x4, end

@ $D847 label=TUNE_QUEST
b $D847 The tune when the bucket reaches a quest item
D $D847 Played in full by #R$D0AC.
B $D847,12,8 D#4, D#4, G#4, A4, D#5, C5 x2, D#4, D#4, F4, G4, G#4 x4, end

@ $D853 label=TUNE_OVER
b $D853 The game-over tune
D $D853 Played in full by GAME_OVER, in #R$C302.
B $D853,16,8 D#4 x2, G#4 x2, C5 x2, D#5 x2, C5 x2, G#4 x2, G#4 x2, A#4 x2, C#5, C5, A#4, G#4, G4 x2, D#4 x2, D#4 x2, G#4 x2
B $D863,12,8 C5, A#4, G#4, G4, F4 x2, C#4 x2, F4 x2, D#4 x2, G#4 x2, G4 x2, G#4 x4, end

@ $D86F label=TUNE_WON
b $D86F The tune when the quest is complete
D $D86F Played in full by #R$C302 when the fifth collectable reaches its place.
B $D86F,16,8 C5, C#5, D#5 x2, C5, C#5, D#5, F5, D#5 x2, C#5 x2, C5 x2, C#5 x2, A#4, C5, C#5, D#5, C#5 x2
B $D87F,16,8 C5 x2, A#4 x2, C5 x2, G#4, A#4, C5, C#5, C5 x2, A#4 x2, G#4 x2, A#4, D#4, D#5 x2, G4 x2, G#4 x4, end

@ $D88F label=BUFFER
b $D88F The screen buffer
D $D88F A room is drawn here, 192 rows of 32 bytes with the bottom row first, and #R$B178 copies it to the screen. #R$CB81 clears it. It starts in the last fifteen bytes of the tape's block, which are zero there; everything above them is whatever the machine held before the game loaded.
B $D88F,6144,16

; span $F08F,113

@ $F08F label=SPARE
b $F08F Between the buffer and the tables
B $F08F,113,16

; span $F100,256

@ $F100 label=REVERSED
b $F100 Every byte with its bits reversed
D $F100 Built by #R$B29A; #R$B2EE mirrors a sprite by looking each byte up here.
B $F100,256,16

; span $F200,512

@ $F200 label=SHIFTED7
b $F200 Masks shifted by seven bits
D $F200 Built by #R$B29A: for every byte, the complement of what it becomes shifted left seven bits as a 16-bit number, the high byte at $F2xx and the low at $F3xx.
B $F200,512,16
; span $F400,512

@ $F400 label=SHIFTED6
b $F400 Masks shifted by six bits
B $F400,512,16
; span $F600,512

@ $F600 label=SHIFTED5
b $F600 Masks shifted by five bits
B $F600,512,16
; span $F800,512

@ $F800 label=SHIFTED4
b $F800 Masks shifted by four bits
B $F800,512,16
; span $FA00,512

@ $FA00 label=SHIFTED3
b $FA00 Masks shifted by three bits
B $FA00,512,16
; span $FC00,512

@ $FC00 label=SHIFTED2
b $FC00 Masks shifted by two bits
B $FC00,512,16
; span $FE00,512

@ $FE00 label=SHIFTED1
b $FE00 Masks shifted by one bit
D $FE00 Until the game builds it, the top of this holds what the machine left there before the tape loaded: the ROM's graphics for the user-defined characters in the last 168 bytes, and below them what the ROM's stack left.
B $FE00,512,16
