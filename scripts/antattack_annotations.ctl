# Hand-written annotations for the Ant Attack disassembly.
#
# scripts/build_antattack.py generates a control file from a code-execution map
# and layers THIS file on top of it. Never edit game_disassembly/antattack/*.ctl
# or *.asm by hand -- the next build overwrites both. Add what you learn here.
#
# How far to trust it. Every instruction in the game but three has been seen
# to run in SkoolKit's simulator, in the build's own playthrough: random play,
# a rescue, running out of time, the ending, and a dozen staged scenes (see
# SESSIONS in the build). The three are in FALL, behind a flag nothing sets.
# Where a comment rests on something measured -- memory read back mid-game, a
# routine run with chosen inputs -- it says so; the rest is read from the code
# and says what the code does rather than guessing at intent.
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
# Never end a label with an underscore and a digit: skool2asm names jump
# targets NAME_0, NAME_1... and an explicit label of that shape collides.
#
# THE OBJECT RECORD. Eight 16-byte records at OBJECTS ($B480) -- the player,
# the person to be rescued, the grenade and five ants -- all moved by the same
# code. BASIC fills them from the DATA in lines 110-180 at the start of every
# level. Fields:
#   +0 x   +1 y   +2 height (0 is the ground; blocks are stacked 0-5)
#   +3 first sprite frame (the boy $DC, the girl $6C, the grenade $68, ants $F8)
#   +4 facing, 0-3 (only the low two bits count)
#   +5 frames spent falling
#   +6 frames left stunned; $FF on an ant is paralysed for good
#   +7 flags: bit 0 may stand on the object IY points at; bit 1 jump; bit 2 move
#      forward; bit 3 never falls; bit 4 steps up a one-block rise by itself
#   +8 animation frame (bit 7 set: a sprite frame number outright)
#   +9 explosion countdown: while non-zero the object is drawn as the blast and
#      does not move, and when it runs out the object goes home
#   +A +B +C home: x, y and height it returns to
#   +D ants: speed; the person to be rescued: 0 waiting, 1 following, 2 out of
#      the city (BASIC's w)
#   +E ants: the speed count; the person to be rescued: last distance to the
#      player, for the scanner
#   +F event for HANDLE_EVENTS: 1 a step, 2 a bad fall, 4 bitten, 8 blown up
#
# COORDINATES. The city is 128 x 128 cells at $80-$FF in both x and y; any
# coordinate below $80 is outside the walls, open ground where nothing is
# solid. READ_MAP_CELL, TEST_MAP_BIT and TOGGLE_MAP_BIT all make that test.
# Directions: 0 is y up, 1 x up, 2 y down, 3 x down (STEP).

# --------------------------------------------------------------------------
# The entry points BASIC calls
# --------------------------------------------------------------------------

@ $8000 ignoreua:t
@ $8000 label=PLAY
c $8000 Play the game (USR 32768)
D $8000 The machine code's main loop, called from BASIC line 700 (to draw the city before "READY WHEN YOU ARE") and line 720 (to play). It runs #R$8E80, #R$8EA0 and #R$8ED0 over and over, returning to BASIC when 1 is pressed (back to the city gate, and "Have another go!") or when #R$B438 counts out.
D $8000 #R$B438 is both the stop signal and a frame budget. BASIC pokes 2 into it before the first call, so that call draws two frames and returns; it is then 0, and the next call decrements that to $FF, which means "run until the game says stop" -- #R$8ED0 and #R$8EA0 stop it by storing a small count again.
  $8001,5 Mark the end of #R$B450, one byte past its eighth entry.
  $8006 Print the grenade count and both energies on the panel.
  $8009,9 Key 1 (bit 0 of the 1-5 half-row, low when pressed)...
  $8012,2 ...goes straight back to BASIC.
  $8014 One frame of the game: move everything, draw the view.
  $8017 Have both left the city?
  $801A Out of time, or out of energy?
  $801D,8 $FF: keep playing.
  $8025,7 Otherwise count a frame off, and stop at zero.
  $802C,6 Leave the random number in SEED, for BASIC's RND.

b $8034 Signature
D $8034 "SandyWhite1983" twice, with a leading fragment and $7F between the copies, padded out to the next routine. Nothing reads it. There is another copy at #R$8448.
; span $8034,44
T $8034,11 The tail of a third copy
B $803F,1
T $8040,14
B $804E,1
T $804F,14
B $805D,3

@ $8060 label=READ_CONTROLS
c $8060 Read the movement keys into the player's record
D $8060 V (move) and C (jump) become bits 2 and 1 of the flags at +7, in one go. SYMBOL SHIFT and M turn the player, but only when not stunned.
R $8060 IX The player's record
  $8060,6 CAPS SHIFT to V, made active high: C is bit 3, V bit 4.
  $8066,4 Down to bits 1 and 2: jump and move.
  $806A,10 Replace the player's jump and move bits with them.
  $8074,5 Stunned: no turning.
  $8079,7 SPACE to B: SYMBOL SHIFT is bit 1, M bit 2.
  $8080,8 SYMBOL SHIFT alone: turn one way...
  $8088,7 ...M alone: the other.

@ $8090 ignoreua:t
@ $8090 label=GET_KEY
c $8090 Return the key being pressed (USR 32912)
D $8090 BASIC's "Girl or Boy (g/b)?" (line 610) reads its answer through this, taking 0 as boy and 6 as girl and asking again for anything else.
R $8090 O:BC The key code the ROM's KEY-SCAN leaves in E
  $8090 KEY-SCAN.
  $8093,3 USR returns BC.

@ $8097 ignoreua:t
@ $8097 label=WAIT_KEY
c $8097 Wait for a key (USR 32919)
D $8097 Loops on the ROM's KEY-SCAN until it reports a key. BASIC calls it for every "press any key" pause.
  $8097 KEY-SCAN.
  $809A,5 E is $FF while no key is down.

# --------------------------------------------------------------------------
# Drawing
# --------------------------------------------------------------------------

@ $80A0 label=DRAW_SPRITE
c $80A0 Draw one sprite into the render buffer
D $80A0 A sprite frame is 64 bytes: 16 rows of mask, graphic, mask, graphic. Frame f lives 64f bytes above #R$8000, so the frame number is the address, less #R$8000, divided by 64 -- the sprites are at #R$9A00 (frames $68-$7F) and #R$B700 (frames $DC-$FF).
R $80A0 IX The frame byte of the sprite's entry in #R$B450; moved on one
R $80A0 HL The sprite's place in #R$B500
R $80A0 DE The render buffer's row length less one ($1F)
  $80A0,3 BC = the row step.
  $80A3,5 The frame number.
  $80A8,13 DE = 64 x the frame number: the frame's first byte.
  $80B5 HL = where the sprite goes in the render buffer.
  $80B8 Sixteen rows.
  $80BB,7 The left byte: mask out, then OR in the graphic...
  $80C2,7 ...and the right byte.
  $80C9,2 Down a row.
  $80CF,3 Give DE back.

@ $80D3 label=MOVE_ANTS
c $80D3 Move the five ants
D $80D3 Each ant takes its turn (#R$8A5D) chasing the player, whom IY points at.

b $80FF Unused
D $80FF $FF filler, like almost every gap between the routines, which start on 16-byte boundaries where they can.

@ $8100 label=COPY_TO_SCREEN
c $8100 Copy the render buffer to the screen
D $8100 Rows 12-127 of the render buffer go to screen lines 12-127, bytes 1-30 of each: the rows above and below and the columns either side are margins for blocks and sprites to overhang into. Checked by filling the buffer's rows with their own numbers and running this.
; span $8100,47
  $8100,10 From row 12 of the buffer to line 12 of the screen, column 1, in two passes (the top two thirds of the screen).
  $810A,3 Save the pass count; start the first row.
  $810D,5 The next screen line: 256 bytes on from the start of the last, less the 30 just copied.
  $8112,5 Skip the buffer's margin column, copy 30 bytes...
  $8117 ...and skip the other margin column.
  $8118,5 Until the buffer crosses into its next 256 bytes: eight rows, the first time four.
  $811D,13 The next character row of the screen; every 64 rows of the buffer, the end of a pass.
  $812A,4 Next pass.

b $812F Unused

@ $8130 label=PLANE_TO_BUFFER
c $8130 Convert a place in PLANES to an address in the render buffer
D $8130 The 512 places in #R$B500 are 32 to a row, and each row is two half-rows of 16. The first half-row's places are every other byte across one row of the buffer; the second's are one byte across and four rows down. Each row of places is eight rows of the buffer. So the places tile the view like bricks, 16 pixels wide. Measured by running this for a range of places.
R $8130 HL On entry, an address in #R$B500; on exit, the render buffer address of the top left of what is drawn there

b $814A Unused

@ $8160 label=CLEAR_PLANES
c $8160 Fill PLANES with $FF (nothing)
  $8160,6 64 times 8 bytes of $FF.

b $8179 Unused

@ $8180 label=MARK_PLANE
c $8180 Mark one height's blocks in PLANES
D $8180 For each of the 512 places in #R$B500, write the height's bit there if the gathered cell at the same offset from DE has a block at that height. Called for the heights in order, lowest first, so a higher block overwrites a lower one.
R $8180 C The height's bit ($01 for the ground layer up to $20)
R $8180 DE Where in #R$B180 that height's cells start
  $8180,5 128 times four places.
  $8185,5 A block at this height in the cell: mark the place.

b $81A4 Unused

@ $81B0 label=BUILD_PLANES
c $81B0 Sort the gathered cells into PLANES, height by height
D $81B0 Each height reads #R$B180 one row of 32 cells further on: a block one higher is drawn one row further up the screen, so it covers the place a row back. That is the whole of the 3D -- after this, #R$B500 says, for each place in the view, which height of block (if any) is the one to be seen there.
  $81B0 Start from nothing.
  $81B3,8 The ground layer...
  $81DB,8 ...up to height 5, 32 cells further on each time.

@ $81E4 label=PRINT_COUNTERS
c $81E4 Print the grenade count and both energies
D $81E4 Scripts 4, 8 and 11 print AMMO, the player's energy and the other's.

b $81F4 Unused
D $81F4 $FF filler, and in its last three bytes LD DE,31: the first instruction of #R$8203, which is entered three bytes in because #R$8500 has already set DE.

@ $8203 label=DRAW_BLOCK
c $8203 Draw a block (views 0 and 2)
D $8203 One block's picture, drawn straight into the render buffer as immediate data, 16 pixels wide. Each of the eight steps paints one row of the block's outline -- the two bytes' edge pixels merged with what is behind them -- and the row eight below it outright, in the dithered shades of the faces. There is one of these for each pair of views, since turning the view round a quarter mirrors the shading: #R$8703 is the other. #R$8570 points IY at the right one and #R$8500 jumps to it.
D $8203 Ends by jumping back into #R$8500 rather than returning.
R $8203 HL The block's place in #R$B500
R $8203 DE The row length less one ($1F)
  $8203 HL = the top left of the block in the render buffer.
  $8206,16 The first step: the outline row, and the solid row eight below...
  $8216,20 ...and so on down.
  $829D Back to #R$8500.

@ $82A0 label=COPY_POSITION
c $82A0 Put IX where IY is, facing the same way
D $82A0 #R$8D00 uses this to start the grenade at the player.

b $82B9 Unused

@ $82C0 label=MOVE_PLAYER
c $82C0 Move the player
D $82C0 IY is the person to be rescued, whom the player may stand on (bit 0 of the flags).
  $82C8 Keys into the flags.
  $82CB Move.
  $82CE Pick the animation frame.

b $82D2 Unused

@ $82E0 label=BLAST_FRAME
c $82E0 Show the explosion while the explosion countdown runs
D $82E0 Frames $F4-$F7, chosen by the low two bits of the count.

b $82ED Unused

@ $8300 label=CLEAR_BUFFER_ROWS
c $8300 Clear every fourth row of the render buffer
D $8300 Unrolled: 29 rows of 32 bytes, four rows apart, from row 12 of the render buffer. #R$B44F moves the starting row on each call, so #R$84A0's four calls clear rows 12-127 -- the rows #R$8100 copies to the screen.
  $8300,8 The step to four rows on, the render buffer, 29 rows of zeros.
  $8308,13 Next quarter: rows 12, 13, 14 or 15 to start from.
  $8315,63 32 bytes.
  $8354,3 Four rows on.

b $8358 Unused

@ $8360 label=RANDOM
c $8360 Step the random number generator
D $8360 A 32-bit shift register at #R$B428, big-endian, fed back from two bits of its first byte. The carry out is the random bit: #R$8A00 uses it to pick which way an ant turns and #R$8B4A to make a hiss.
R $8360 O:F Carry the random bit
  $8360,10 The feedback bit into the carry.
  $836A,14 Shift all 32 bits left, feeding it in at the bottom.

b $8379 Unused

@ $8380 label=READ_MAP_CELL
c $8380 Read one cell of the city map
D $8380 The map is 128 x 128 bytes at #R$C000, a bit for each of six heights. Coordinates run $80-$FF; below that is outside the walls and reads as empty. Cell (x, y) is at #R$C000 + 128(y - $80) + (x - $80).
R $8380 E x
R $8380 D y
R $8380 IX Where to write the byte; moved on one
  $8380,9 Outside the walls if either coordinate is below $80.
  $8389,4 HL = #R$C000 + 128 x (y AND $7F) + (x AND $7F).
  $838D,7 Store the cell.
  $8394,7 Outside: store 0.

b $839B Unused

@ $83B0 label=GATHER_VIEW
c $83B0 Gather the cells in view into VIEW_CELLS
D $83B0 Jumps to one of four routines, 32 bytes apart from #R$8681, which read the map along diagonals in the order that view needs: 21 rows of two 16-cell half-rows, from #R$B420.
  $83B0,13 HL = #R$8681 + 32 x the view.
  $83C5 21 rows.

b $83C8 Unused

@ $83E0 label=MOVE_GRENADE
c $83E0 Throw and move the grenade, and see whether it hit anything
  $83E8 Throw, or fly.
  $83EB Move.
  $83EE The blast's frames.
  $83F1 Anything in the blast?

b $83F5 Unused

@ $8400 label=READ_VIEW_KEYS
c $8400 Turn the view with 0, P, ENTER or SPACE
D $8400 Each key picks one of the four views and re-centres #R$B420 on the player for it, the view origin being the player's position less an offset that depends on the view. No key: nothing changes.
  $8400,5 L = $FF: no key yet.
  $8405,10 0: view 3.
  $840F,12 P: view 2.
  $841B,12 ENTER: view 1.
  $8427,12 SPACE: view 0.
  $8433,5 None of them.
  $8438 Set the view...
  $843B,12 ...and its origin, the player less the offset.

b $8448 Unused
D $8448 $FF filler, with another "SandyWhite1983" in the middle of it.
; span $8448,24
B $8448,9
T $8451,14
B $845F,1

@ $8460 label=SCROLL_VIEW
c $8460 Scroll the view when the player nears its edge
D $8460 Reads where the player was placed this frame (the last entry of #R$B450) and, if that is outside a central window of the view, steps #R$B420 a cell in the direction the player is facing -- unless the player is jumping or falling. It takes effect next frame, since the view has already been gathered.
  $8460,7 Off the view altogether: leave it.
  $8467 Undo the +1 #R$8600 adds.
  $8468,9 Across: inside if the column is 4-11 of 16...
  $8471,14 ...and down: inside if the row is 8-23 of 32.
  $847F Outside: move the view.
  $8482,11 Not while jumping or falling.
  $848D,9 A cell the way the player faces.

b $8497 Unused

@ $84A0 label=DRAW_VIEW
c $84A0 Draw the view
D $84A0 A painter's algorithm in eleven steps: gather the map, sort it into #R$B500 by height, clear the render buffer, work out where each object falls in #R$B500, scroll if the player is near the edge, sort the objects by that, turn their places into distances, pick the block picture for this view, paint the lot back to front, and copy it to the screen.
  $84A0 The map, into #R$B180.
  $84A3 Into #R$B500, by height.
  $84A6,12 Clear the visible rows of the render buffer, a quarter at a time.
  $84B2 Where each object falls.
  $84B5 Scroll next frame, if need be.
  $84B8 Sort the objects...
  $84BB ...and space them out.
  $84BE The block picture for this view.
  $84C1 Paint.
  $84C4 Show.

b $84C8 Unused

@ $84D0 label=SHARE_CELL
c $84D0 The rescued person and the player in one cell: nobody falls
D $84D0 When the two are in the same cell and at most one block apart in height -- one on the other's head -- the rescued person's stun and the player's stun and fall count are cleared. So dropping onto each other is never a landing: seen in play, when a scene dropped the player three blocks onto the rescued person's head and it made no bad fall and no search for an ant beneath.
R $84D0 IX The person being rescued
R $84D0 IY The player
  $84D0,14 More than a block apart in height: nothing.
  $84DE,14 Not the same cell: nothing.
  $84EC,10 Clear both stuns and the player's fall.
  $84F6,3 Three NOPs, left where something was taken out.

b $84FA Unused

@ $8500 label=DRAW_SCENE
c $8500 Paint PLANES and the sprites into the render buffer, back to front
D $8500 #R$B500 holds, per place, one of $01, $02 ... $20 (a block at that height) or $FF (nothing). This paints every $01 place, then every $02, and so on up to $40 -- a pass with no blocks in it, for anything standing on top of a six-high block -- using CPIR to find each next one. The sprites are threaded in by distance: BC counts down the places to the next sprite across all the passes, so when CPIR runs BC out before finding a block, it is time to draw a sprite (#R$852F).
; span $8500,43
  $8500,7 BC = the count to the first sprite.
  $8507,8 Row step for the drawers; start with height bit $01.
  $8511,5 The next height's bit; past $40, done.
  $8516 HL was one past the end; back to the last place.
  $8517 A sentinel, so the CPIR stops at the end.
  $8518 From the first place.
  $851B,5 Find the next place at this height -- or run out of count first.
  $8520,6 Found the sentinel: the next height.
  $8526,4 Draw the block through the pointer #R$8570 set.

@ $852B label=BLOCK_DRAWN
c $852B Where DRAW_BLOCK and DRAW_BLOCK_TURNED come back to
  $852B,4 Carry on scanning.

@ $852F label=DRAW_HERE
c $852F Draw the sprite that is due, then carry on the scan
  $852F,6 The place is the one before where CPIR stopped.
  $8536 The next sprite's count.
  $8539,5 The scan ran to the end: next height.

b $8541 Unused

@ $8550 label=NEXT_SPRITE
c $8550 Load the count to the next sprite in SPRITE_LIST
D $8550 Skips entries whose count is zero.
R $8550 IX An entry in #R$B450; on exit, its frame byte
R $8550 O:BC The count
  $855D Skip the frame byte of an empty entry.

b $8561 Unused

@ $8570 label=SELECT_BLOCK_DRAWER
c $8570 Point IY at the block picture for this view
  $8570,6 Views 1 and 3...
  $8576 ...or 0 and 2.

@ $8580 label=SORT_SPRITES
c $8580 Sort SPRITE_LIST by place in PLANES
D $8580 A bubble sort into ascending order, repeated until a pass swaps nothing.
  $8580 C = 0: nothing swapped.
  $8582,6 Seven comparisons a pass.
  $8588,18 This entry's place against the next's.
  $859C,26 Out of order: swap places and frames, and note it.
  $85BE,3 Swapped something: another pass.

b $85C2 Unused

@ $85D0 label=SPRITE_DISTANCES
c $85D0 Turn the sorted places into distances from one to the next
D $85D0 So #R$8500 can use each as a CPIR count. The first entry keeps its place.
; span $85D0,39
  $85D0,12 From the last entry back.
  $85E5,15 This place less the one before.

b $85F7 Unused

@ $85FA label=OFF_VIEW
c $85FA An object out of view: a place past the end, so it is never drawn

b $85FE Unused

@ $8600 label=PROJECT_SPRITES
c $8600 Work out where each object falls in PLANES
D $8600 For each object, last to first, its position relative to #R$B420 is turned for the view and projected: the half-row is v - u - 2h and the column (u + v) / 2, where u and v are the turned coordinates and h the height. The place is height x 512 + half-row x 16 + column -- the height counting a whole pass of #R$8500 -- and it goes into #R$B450 with the sprite frame: the object's first frame, plus four times its animation frame, plus its facing relative to the view.
  $8600,13 From the fifth ant back to the player; eight objects.
  $860F Its height.
  $8612,10 Its position relative to the view's origin.
  $861C,26 Turn it for the view: swap x and y for views 1 and 3, and negate as the view needs.
  $8636,6 Raise it by its height.
  $863C,8 The half-row, 0-31, or out of view.
  $8644,8 Times 16, with the height above it.
  $864C,9 The column, 0-31 before halving, or out of view.
  $8655,5 Into the place, plus one.
  $865A,5 Store the place.
  $865F,9 The facing relative to the view.
  $8668,7 Bit 7 set: the frame outright...
  $866F,6 ...otherwise the first frame, plus four times the animation frame, plus the facing.
  $8677,5 The object before.

@ $8681 label=GATHER_VIEW0
c $8681 Gather the cells in view, view 0
D $8681 Each row is 16 cells along a diagonal from the start, then 16 more from the cell beside it; the next row starts a cell further back. The other three views' routines are the same with the signs turned.
  $8681,4 First half-row...
  $868C,5 ...then the second, from the next cell over.
  $8698,2 The next row starts a cell back.

b $869F Unused

@ $86A1 label=GATHER_VIEW1
c $86A1 Gather the cells in view, view 1

b $86BF Unused

@ $86C1 label=GATHER_VIEW2
c $86C1 Gather the cells in view, view 2

b $86DF Unused

@ $86E1 label=GATHER_VIEW3
c $86E1 Gather the cells in view, view 3

b $86FF Unused
D $86FF $FF, then LD DE,31: the unused first instruction of #R$8703, as before #R$8203.

@ $8703 label=DRAW_BLOCK_TURNED
c $8703 Draw a block (views 1 and 3)
D $8703 #R$8203's picture shaded for the other two views.
  $879D Back to #R$8500.

# --------------------------------------------------------------------------
# Moving things
# --------------------------------------------------------------------------

@ $87A0 label=BLAST_ANT
c $87A0 See whether an exploding grenade got an ant
D $87A0 Only ants at the grenade's height and not already exploding. Within four cells (counted along the grid, not diagonally) the ant is blown up -- "GOOD SHOT!" -- and within seven it is stunned for 24 frames. Both seen in play, in staged scenes.
R $87A0 HL The grenade's x and y
R $87A0 C Its height
R $87A0 IY The ant
  $87A0,10 Another height, or already exploding: no.
  $87B3,3 Eight or more away: missed.
  $87B6,9 Five to seven: stunned.
  $87BF,8 Four or less: blown up...
  $87C7,8 ...and "GOOD SHOT!".

@ $87D0 label=SCANNER
c $87D0 Colour the scanner
D $87D0 Green if carry is set -- closer than last frame -- and red otherwise.

b $87F5 Unused

@ $8800 label=MOVE_OBJECT
c $8800 Move an object one frame: fall, climb, jump, walk
D $8800 The physics for everything. Nothing is solid but the map, and ants put themselves in the map (#R$8940), so walking into an ant is walking into a wall -- and an ant arriving in someone's cell is a bite.
R $8800 IX The object
  $8800,9 Where it is.
  $8809,10 Anything to stand on? If not, fall.
  $8813,9 Something in this very cell: bitten, and pushed up.
  $881C,7 Stunned: count it down.
  $8823,8 Just landed from a fall.
  $882B,4 Standing.
  $882F,7 Jump.
  $8836,7 Walk forward, if moving...
  $883D,12 ...a cell the way it faces...
  $8849 ...unless the way is blocked.
  $884C,10 A step.

b $8857 Unused

@ $8860 label=LANDED
c $8860 Land from a fall
D $8860 A fall of five frames or more stuns for eight frames each, and is a bad fall; shorter ones stun for as many frames as they lasted and are a step. Landing at height 1 means landing on something on the ground, which may be an ant (#R$8BD1). Seen in play: a drop of five blocks stunned the player for 48 frames with a bad fall.
R $8860 A Frames spent falling, at least 2
  $8860,6 A step...
  $8866,9 ...or, from five frames up, a bad fall, stunned for eight times as long.
  $886F,6 The stun and the event.
  $8875,9 On something at ground level: an ant?

b $887F Unused

@ $8880 label=FALL
c $8880 Fall, after a frame's grace
D $8880 On the first frame with nothing underneath, an object can still walk -- off a ledge, say -- and only after that does it drop a block a frame.
D $8880 Nothing sets bit 3 of the flags -- not the BASIC's DATA, not the code -- so the three instructions of its "never falls" branch never run. These are the only instructions in the game not seen to run.
  $8880,13 Bit 3: never falls.
  $888D,11 Count the frame; the first one, walk.
  $8898,4 Then drop a block.

b $889D Unused

@ $88A0 label=BITTEN
c $88A0 Something is in this cell: a bite
D $88A0 And the object is pushed up a block, out of the way.

b $88A7 Unused

@ $88B0 label=STUNNED
c $88B0 Count down being stunned
D $88B0 Also clears the fall count, so a fall that ends while an object is still stunned is never landed: no stun, no bad fall. The rescued person starts each level stunned for four frames (line 120's DATA), which is enough to swallow a short drop.

b $88B9 Unused

@ $88C0 label=ON_TOP
c $88C0 The rescued person shares the player's cell
D $88C0 Only #R$8AB6 comes here, when the distance between the two is 0: one is standing on the other. If the rescued person is the higher of the two they take the player's facing and walk on; if lower, they stop. Both seen in play, in staged scenes.
R $88C0 IX The rescued person
R $88C0 IY The player
R $88C0 O:C The player's facing
  $88C6 A NOP, left where something was taken out.

@ $88D0 label=RISE
c $88D0 Go up a block, if there is room
  $88D0,10 Blocked above: walk instead.

b $88DF Unused

@ $88E0 label=STEP_UP
c $88E0 Blocked: step up onto it, for things that can
D $88E0 Only with bit 4 of the flags -- the rescued person and the grenade -- and only if the cell above the object is free. It rises there, and next frame walks on at the new height.

b $88F5 Unused

@ $8900 label=STEP
c $8900 Move a position one cell in a direction
R $8900 A The direction (only bits 0-1 count)
R $8900 HL The position: L is x, H is y
  $8912 0: y up.
  $8910 1: x up.
  $890E 2: y down.
  $890C 3: x down.

b $8914 Unused

@ $8920 label=TEST_MAP_BIT
c $8920 Is there a block at a height in a cell?
D $8920 Height 6 is the open sky, always empty; above it, always solid, and so is height -1 ($FF), which is how the ground holds things up. Anywhere outside the walls is empty.
R $8920 A The height
R $8920 DE The cell: E is x, D is y
R $8920 O:F Carry set if there is a block
  $8926,7 Outside the walls: empty.
  $892D,5 The cell's address.
  $8932,3 Rotate the height's bit into the carry.
  $8938,2 Heights 6 and up.

b $893B Unused

@ $8940 label=TOGGLE_MAP_BIT
c $8940 Flip a height's bit in a map cell
D $8940 How the ants become solid: #R$8A00 takes an ant out of the map before moving it and puts it back after, so everything else collides with it. This is why the city map changes during play. Nothing outside the walls is written.
D $8940 It is an XOR, so the map and the ant's record have to agree: an ant moved without its bit leaves a phantom block behind and puts one in its own cell, where it is promptly "bitten" and pushed up a block. Seen in a scene that did exactly that.
R $8940 A The height
R $8940 DE The cell: E is x, D is y

b $8959 Unused

@ $895D label=TEST_BELOW
c $895D Is there anything to stand on?
D $895D As #R$8920, but an object with bit 0 of its flags set can also stand on the object IY points at: the player on the rescued person, and the other way about.
R $895D A The height to test
R $895D DE The cell
R $895D O:F Carry set if something is there

b $897C Unused

@ $8980 label=CHOOSE_FRAME
c $8980 Choose the animation frame
D $8980 The explosion while it lasts; then, stunned for five frames or more, frame 3 (or 2 while still falling); stunned for less, 2; falling, 4; walking, 0 and 1 in turn; standing, 0.

b $89C9 Unused

@ $89D0 label=MOVE_OR_RESPAWN
c $89D0 Move an object, or count down its explosion and send it home
D $89D0 While the explosion countdown runs the object does not move, and when it runs out the object goes back to its home position. The player starts every level this way: BASIC sets its countdown to 1, so the first frame puts it at the city gate.
  $89DF,18 Home.
  $89F1,10 Not falling, not stunned, standing.

b $89FC Unused

@ $8A00 label=MOVE_ANT
c $8A00 Move an ant towards the player
D $8A00 The ant is taken out of the map, moved, and put back. If the move brought it closer to the player it walks on (and, within four cells, turns to face the player); otherwise it stops and turns a random way.
  $8A00,13 Out of the map...
  $8A0D Move it.
  $8A10,14 ...and back in where it is now.
  $8A1E,15 Its distance from the player, now and before.
  $8A31,9 Closer: walk.
  $8A3A,16 Within four: face the player.
  $8A4B,17 No closer: stop, and turn left or right at random.

b $8A5C Unused

@ $8A5D label=ANT_TURN
c $8A5D An ant's turn
D $8A5D A paralysed ant does nothing. Otherwise an ant moves every frame except one in every +D: 2 is half speed, 20 very nearly full. The first ant is the fast one (line 140's DATA); BASIC sets the others' speed from sp, which goes up as the levels do.
  $8A5D,6 Paralysed.
  $8A66,8 Not the frame to skip: move.
  $8A6F,6 Skip it, and start counting again.

b $8A76 Unused

@ $8A80 label=DISTANCE
c $8A80 Distance between two cells, along the grid
R $8A80 HL One cell
R $8A80 DE The other
R $8A80 O:A |x difference| + |y difference|

@ $8A91 label=DIRECTION_TO
c $8A91 The direction from one cell towards another
D $8A91 Straight along the axis if they share a row or column; otherwise one of the two directions that close the gap, chosen by the signs.
R $8A91 HL From
R $8A91 DE Towards
R $8A91 O:A A direction for #R$8900 (only the low two bits count)

@ $8AB6 label=FOLLOW_PLAYER
c $8AB6 Walk the rescued person after the player
D $8AB6 Walks towards the player while two to five cells away, and stops beside them or more than five away. The facing is kept if one more step along it would still end beside the player; otherwise they turn towards the player.
  $8AB6,5 Not while stunned.
  $8ACD Walking, unless...
  $8AD1,8 ...six or more away, or beside the player.
  $8AD9,6 In the player's own cell.
  $8ADF,10 Would a step this way end beside the player?
  $8AE9,10 No: face the player.

b $8AFC Unused

@ $8B00 label=FILL_PLAY_ATTRIBUTES
c $8B00 Fill the play area's attributes
D $8B00 The flash behind "CONGRATULATIONS !", "BITTEN!" and the rest: rows 1-15, columns 1-30.
R $8B00 A The attribute

b $8B46 Unused

@ $8B4A label=NOISE
c $8B4A A burst of noise on the speaker
R $8B4A B Length
  $8B4A,8 The border colour, with the MIC and speaker bits set.
  $8B52,8 A random speaker bit, each time round.

b $8B60 An unused script
D $8B60 In the #R$8E0D format -- AT 15,12, then letters between notes -- and spelling "OWCH!". It is not among the ones #R$9000 counts from, so nothing ever runs it: a leftover.
; span $8B60,32

@ $8B80 label=TONE
c $8B80 A note on the speaker
R $8B80 A The note, an index into #R$8BB1
  $8B80,8 HL = the note's entry.
  $8B88,8 The border colour, with the MIC and speaker bits set.
  $8B90,3 E = the pitch, B = the half-cycles.
  $8B93,15 The pitch delay...
  $8BA2,6 ...then flip the speaker.
  $8BAC,4 Speaker off.

@ $8BB1 label=TONES
b $8BB1 Note table
D $8BB1 A delay (the pitch) and a count of half-cycles per note: 16 notes rising in pitch, the count rising with them so that each lasts about as long. Note $0F is taken as noise by #R$8E0D, so the last entry is never played.
; span $8BB1,32
B $8BB1,32,2

@ $8BD1 label=PARALYSE_ANT
c $8BD1 Paralyse the ant the player has landed on
D $8BD1 An ant that is not exploding and not already paralysed is paralysed for good, with "PARALYSED AN ANT !". Seen in play, by dropping the player on a stunned ant; and landing on a plain one-block wall finds no ant here and returns.
R $8BD1 HL The cell
  $8BD1,9 Five ants.
  $8BDA,12 Is this one in the cell?
  $8BEB,11 Not while exploding, and not twice.
  $8BF6,8 Paralysed, for good.

b $8BFF Unused
D $8BFF A repeating 5-byte pattern -- 0E 00 3A 25 B4, which reads as LD C,0 and a LD A,(nn) -- filling the page. Nothing reads it.
; span $8BFF,257

@ $8D00 label=THROW_GRENADE
c $8D00 Throw a grenade, or keep one flying
D $8D00 S, D, F and G throw, further along the keyboard throwing further: each key's bit is its flight time (2, 4, 8 or 16 frames). The grenade starts at the player and moves like anything else, a cell a frame; when the time runs out it explodes where it is.
D $8D00 Every frame of the flight, not only the last, the grenade is checked against the player's cell and the rescued person's: if it is in either, they are blown up.
R $8D00 IX The grenade
R $8D00 IY The player
  $8D00,6 In flight.
  $8D06,5 Still exploding.
  $8D0B,9 A to G: S, D, F or G.
  $8D14 C = the flight time.
  $8D15,9 None left, or one fewer.
  $8D1E,4 Launch.
  $8D22 The player's throwing pose.
  $8D26 The grenade moves...
  $8D2A ...from where the player is...
  $8D2D,5 ...and the count is reprinted.
  $8D32 In flight it is drawn as frame $F4.
  $8D37,6 One frame less in the air...
  $8D3D,13 ...and at the end, bang: explode and stop.
  $8D4B,24 In the player's cell...
  $8D63,13 ...blows the player up.
  $8D71,21 In the rescued person's cell...
  $8D86,13 ...blows them up.

b $8D94 Unused

@ $8D9A label=GRENADE_BLAST
c $8D9A Check each ant against an exploding grenade

b $8DCC Unused

@ $8DD0 label=COUNT_DOWN_TIME
c $8DD0 Count the time down and print it
D $8DD0 One tick every three frames. The time is big-endian, as the ROM's OUT-NUM-2 prints it.
  $8DD0,8 Every third frame.
  $8DDB,4 Already zero.
  $8DDF A redundant decrement of the low byte: the next three instructions overwrite it.
  $8DE0,4 One less.
  $8DE4,18 PRINT AT 19,20;
  $8DF6,6 The time.

b $8DFD Unused

@ $8E00 label=PLAY_SCRIPT_ONE
c $8E00 Run script 1, "NASTY FALL !"

@ $8E02 label=PLAY_SCRIPT
c $8E02 Run a script, keeping IX
R $8E02 A The script's number

b $8E0B Unused

@ $8E0D label=RUN_SCRIPT
c $8E0D Run a script: text, sound and colour
D $8E0D Every message the machine code shows and every sound it makes is a script in #R$9000: the Dth record there, counting the $FF that ends each. The first byte is a stream to print to (2, the upper screen); then, until $FF:
D $8E0D $80-$FF: a sound -- bits 0-3 a note from #R$8BB1, $0F meaning noise, and bits 4-6 one less than how many times. $7D: the next byte is an attribute to fill the play area with. $7E: the next byte is the low byte of the address of a two-byte number, in the variables, to print. Anything else is printed, control codes and all.
R $8E0D D The script's number
  $8E0D,12 Find the Dth $FF from #R$9000...
  $8E19,6 ...or give up after 2K.
  $8E1F,3 IX = the script.
  $8E22,13 Stream 1 or 2, or nothing.
  $8E2F,8 The next byte; $FF ends.
  $8E37,4 A sound?
  $8E3B,9 D = how many times.
  $8E44,7 E = the note; $0F is noise.
  $8E4B,10 Play the note D times.
  $8E55,10 Or the noise.
  $8E5F,4 $7E: a number.
  $8E63,4 $7D: a colour.
  $8E67 Print anything else.
  $8E6A,8 Fill the play area with the colour.
  $8E74,10 Print the number whose address has the next byte as its low byte and $B4 as its high.

@ $8E80 label=GAME_FRAME
c $8E80 One frame of play
  $8E80 The player.
  $8E83 The person to be rescued.
  $8E86 The grenade.
  $8E89 The ants.
  $8E8C The view keys.
  $8E8F Draw.
  $8E92 Messages for what happened to the two people...
  $8E95 ...and to the grenade.
  $8E98 The clock.

b $8E9C Unused

@ $8EA0 label=CHECK_RESCUED
c $8EA0 Have the player and the rescued person both left the city?
D $8EA0 Seen in play. Once both are outside the walls, the rescued person's +D is set to 2 -- BASIC's w, which line 70 reads as success -- "CONGRATULATIONS !" is shown, and the game stops next frame.
  $8EA0,7 The player is inside if both x and y have bit 7 set...
  $8EA7,6 ...and the same for the rescued person.
  $8EAD,6 Already done.
  $8EB3,10 Rescued.
  $8EBD,8 Stop after this frame.

b $8EC6 Unused

@ $8ED0 label=CHECK_GAME_OVER
c $8ED0 Stop the game when time or either energy runs out
D $8ED0 Five frames later, so the last message is seen. Seen in play for the time.
  $8ED0,13 Either energy at zero...
  $8EDD,6 ...or the time.
  $8EE3,6 Only once.
  $8EE9,8 Five more frames.

@ $8EF2 ignoreua:t
@ $8EF2 label=FINAL_SCRIPT
c $8EF2 The ending (USR 36594)
D $8EF2 Script 17, "YOU ARE A REAL HERO", called from BASIC line 3600 after the tenth rescue. Seen in play, with BASIC's fin set to 1.

b $8EFA Unused

@ $8F00 label=HANDLE_EVENTS
c $8F00 React to what happened to the player and the rescued person
D $8F00 Reads and clears the two event bytes (+F). A step is a click; a bad fall, "NASTY FALL !" or "HELP! I FELL!"; blown up, energy to 0 with "SILLY! YOU BLEW YOURSELF UP !" or "HOW COULD YOU ?"; bitten, an energy point off with "BITTEN!" or "THEY GOT ME", or when it reaches 0, "EATEN ALIVE" or "IVE BEEN EATEN ALIVE". All seen in play.
  $8F00,10 E = the player's event, D = the other's, both cleared.
  $8F0A,3 Nothing happened.
  $8F0D,8 Only a step: a click.
  $8F16,10 The player's bad fall...
  $8F20,6 ...or theirs.
  $8F27,18 The player blown up: energy 0.
  $8F39,18 Bitten: a point off, and which message.
  $8F4B,5 Reprint the player's energy.
  $8F50,41 The same for the rescued person.

b $8F7A Unused

@ $8F80 label=MOVE_RESCUEE
c $8F80 The person to be rescued: wait, or follow
D $8F80 Waiting, they drive the scanner, and are found when the player comes within three cells at the same height: "MY HERO!". After that they follow the player.
  $8F88,6 Found yet?
  $8F8E,13 Following: stand clear, follow, move, animate.
  $8F9B,16 Waiting: how far is the player?
  $8FAB,9 Green if closer than last frame.
  $8FB4,11 Within three cells at the same height...
  $8FBF,12 ...found: "MY HERO!". The scanner goes red, the flags left from the height comparison.

b $8FCC Unused

@ $8FD0 label=GRENADE_SOUNDS
c $8FD0 Show and sound what the grenade did
D $8FD0 #R$B42D: bit 0 thrown (reprint the count), bit 1 exploded (a bang), bit 2 hit an ant ("GOOD SHOT!").

b $8FF4 Unused

@ $8100 isub=LD HL,RENDER_BUFFER+$0180
@ $81BD isub=LD DE,VIEW_CELLS+$20
@ $81C5 isub=LD DE,VIEW_CELLS+$40
@ $81CD isub=LD DE,VIEW_CELLS+$60
@ $81D5 isub=LD DE,VIEW_CELLS+$80
@ $81DD isub=LD DE,VIEW_CELLS+$A0
@ $850C isub=LD HL,PLANES+$01FF
@ $8576 isub=LD IY,DRAW_BLOCK
@ $857B isub=LD IY,DRAW_BLOCK_TURNED

# --------------------------------------------------------------------------
# Data
# --------------------------------------------------------------------------

@ $9000 label=SCRIPTS
b $9000 Scripts
D $9000 The $FF that ends a script zero. #R$8E0D finds script n by counting $FF bytes from here, so the seventeen that follow are numbered from 1; see #R$8E0D for their format, and the scripts page for what each says and when. The build generates their blocks, since their titles are their words.
; span $9000,954

b $93BA Unused
D $93BA Filled with $02.

@ $9700 label=LOADED
c $9700 Where the load finishes
D $9700 The loader in the BASIC line leaves LD-BYTES's return address pointing here. A failed load (carry clear) or a short one (DE not zero) resets the machine.
; span $9700,18
  $9700 Carry clear: a tape error.
  $9703,5 Bytes left over: a short load.
  $9708,6 The interrupt vectors at #R$9800: every one points to #R$9797.
  $970E,4 Run the BASIC.

b $9712 Unused
D $9712 Zeros, $02 filler, and just before #R$9797 a stray copy of the interrupt set-up.

@ $9797 label=INTERRUPT
c $9797 The interrupt routine: no BREAK
D $9797 Passes the interrupt to the ROM unless an error is pending -- BREAK, most likely -- and if one is, restarts the BASIC program instead of letting it stop.
  $9799,7 No error: the ROM's interrupt routine.

@ $97A0 label=RESTART_BASIC
c $97A0 Type RUN and run it
D $97A0 Clears the error, resets the stack from ERR_SP, puts RUN and ENTER in the edit line and jumps into the ROM's line executor. This is also how the game starts after loading, since the tape's program header has no auto-run line.
  $97A0,5 No error.
  $97A5 The stack BASIC keeps.
  $97A9,10 RUN, ENTER into the edit line.
  $97B4 The ROM's statement loop, as if ENTER had been pressed.
  $97B7,4 The ROM's own interrupt routine.

b $97BB Unused

@ $9800 label=INTERRUPT_VECTORS
b $9800 Interrupt vector table
D $9800 257 bytes of $97 (and one more), so wherever the data bus leaves the vector, the interrupt goes to #R$9797.

b $9902 Unused
D $9902 Filled with $02.

@ $9A00 label=SPRITES
b $9A00 Sprites: the grenade and the girl
D $9A00 Frames $68-$6B are the grenade's by its record, but in flight it is drawn as $F4 and at home it is out of view, so these are not seen in play; $6C-$7F are the girl. 64 bytes a frame, mask and graphic interleaved (see #R$80A0).

@ $A000 label=RENDER_BUFFER
b $A000 Render buffer
D $A000 140 rows of 32 bytes. The view is painted here and rows 12-127 copied to the screen (#R$8100); the rest is margin. What the tape holds here is whatever was in it when the game was saved.

@ $B180 label=VIEW_CELLS
b $B180 The cells in view
D $B180 #R$83B0's output: 21 rows of 32 map cells.

@ $B420 label=VIEW_ORIGIN
b $B420 Game variables
D $B420 BASIC sets most of these at the start of each level (lines 200-220, and 750 for the time). The two-byte counts are big-endian, for the ROM's OUT-NUM-2, and the code only ever touches their low bytes.
B $B420,2 The x and y the view is drawn from
@ $B422 label=VIEW
B $B422,1 Which of the four views, 0-3
B $B423,5 Set to 1 by BASIC; not used by the machine code
@ $B428 label=RANDOM_BITS
B $B428,3 The random number generator, 32 bits big-endian: the first byte is left in SEED for BASIC...
@ $B42B label=RANDOM_LOW
B $B42B,1 ...and this is where #R$8360 shifts in the new bit
@ $B42C label=BORDER
B $B42C,1 The border colour, for the sound routines
@ $B42D label=GRENADE_EVENTS
B $B42D,1 What the grenade did, for #R$8FD0
@ $B42E label=THROW_TIME
B $B42E,1 Frames of flight left
@ $B42F label=AMMO
B $B42F,1 Grenades left: the high byte, always 0...
@ $B430 label=AMMO_LOW
B $B430,1 ...and the low
@ $B431 label=PLAYER_ENERGY
B $B431,1 The player's energy: the high byte, always 0...
@ $B432 label=PLAYER_ENERGY_LOW
B $B432,1 ...and the low
@ $B433 label=RESCUEE_ENERGY
B $B433,1 The rescued person's energy: the high byte, always 0...
@ $B434 label=RESCUEE_ENERGY_LOW
B $B434,1 ...and the low
@ $B435 label=TIME_TICKS
B $B435,1 Frames to the next tick of the clock
@ $B436 label=TIME
B $B436,2 The time
@ $B438 label=FRAMES_LEFT
B $B438,1 Frames to run; $FF, until the game says stop (see #R$8000)
B $B439,22 Unused
@ $B44F label=CLEAR_PHASE
B $B44F,1 Which rows #R$8300 clears next

@ $B450 label=SPRITE_LIST
b $B450 Sprite list
D $B450 Three bytes an object, in the order #R$8600 meets them, the last object first: the place in #R$B500 -- turned into a distance once sorted -- and the frame.
B $B450,15,3 The ants, the fifth first
B $B45F,3 The grenade
@ $B462 label=RESCUEE_SPRITE
B $B462,3 The rescued person
@ $B465 label=PLAYER_SPRITE
B $B465,3 The player
B $B468,1 End marker: a count to a ninth sprite too big ever to be reached...
@ $B469 label=SPRITE_LIST_END
B $B469,1 ...its high byte set by #R$8000
B $B46A,22 Unused

@ $B480 label=PLAYER
b $B480 Objects
D $B480 The player, the person to be rescued, the grenade and five ants, 16 bytes each; the fields are described at the top of the annotations. The fields the code names directly have labels of their own.
B $B480,4 The player: x, y, height, first frame
@ $B484 label=PLAYER_FACING
B $B484,1
@ $B485 label=PLAYER_FALL
B $B485,1
B $B486,1
@ $B487 label=PLAYER_FLAGS
B $B487,1
B $B488,7
@ $B48F label=PLAYER_EVENT
B $B48F,1
@ $B490 label=RESCUEE
B $B490,13 The person to be rescued
@ $B49D label=RESCUEE_STATE
B $B49D,1 0 waiting, 1 following, 2 out of the city: BASIC's w
B $B49E,1
@ $B49F label=RESCUEE_EVENT
B $B49F,1
@ $B4A0 label=GRENADE
B $B4A0,16 The grenade
@ $B4B0 label=ANT1
B $B4B0,16 The first ant, the fast one
@ $B4C0 label=ANT2
B $B4C0,16
@ $B4D0 label=ANT3
B $B4D0,16
@ $B4E0 label=ANT4
B $B4E0,16
@ $B4F0 label=ANT5
B $B4F0,16

@ $B500 label=PLANES
b $B500 Planes
D $B500 #R$81B0's output, 512 places: each holds the bit of the height of block seen there, or $FF. The last place is where #R$8500 plants its sentinel.

@ $B700 label=MORE_SPRITES
b $B700 Sprites: the boy, the grenade in flight, and the ants
D $B700 Frames $DC-$EF the boy, $F4-$F7 the grenade in flight and exploding, $F8-$FF the ants. What $F0-$F3 are has not been checked.

@ $C000 label=CITY_MAP
b $C000 The city of Antescher
D $C000 128 x 128 cells, a byte each, one bit per height: bit 0 a block on the ground, up to bit 5. See #R$8380.
