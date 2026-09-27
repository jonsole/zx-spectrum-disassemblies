# Hand-written annotations for the Atic Atac disassembly.
#
# scripts/build_aticatac.py generates a control file from a code-execution map
# (which addresses are code, which are data) and then layers THIS file on top
# of it. Keeping the two apart is what makes the annotations survive: the
# generated one is thrown away and rebuilt on every run, this one is not.
#
# So: never edit game_disassembly/aticatac/*.asm or *.ctl by hand -- the next
# build overwrites both. Add what you learn here instead.
#
# Everything below was checked against the running game rather than guessed:
# routines were broken on in the emulator and their inputs and outputs read
# back. Anything still uncertain says so.
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
# skool2asm invents NAME_0, NAME_1, NAME_2 and so on for the jump targets
# inside a routine called NAME, and an explicit label of that shape collides
# with one of them and stops the assembly. Use _ALT or a real word instead.

# --------------------------------------------------------------------------
# Entry
# --------------------------------------------------------------------------

# Sprite images are built from the game's own bytes by SkoolKit rather than
# drawn by a simulator and pasted in, so a picture and the DEFBs beside it can
# never disagree. The approach is taken from pobtastic's Atic Atac disassembly
# at skoolkit.arcadegeek.co.uk.
#
# A sprite is one byte of row count, then that many rows of two bytes. So: two
# UDGs across, stepping 2 within a UDG and 1 between them, 16 bytes on to the
# next row of UDGs, and cropped to the real height because it is rarely a
# multiple of 8.

@ $6000 label=ENTRY
c $6000 Entry point, and the second half of the tape protection
D $6000 The 18-byte decryptor at $5B80 (in the printer buffer, entered by the loader's PRINT USR 23424) RRDs a nibble through the whole game block and then jumps here.
D $6000 This is where the tape's third trick pays off. One of the tiny CODE blocks pokes $255E into FRAMES at $5C78 for no reason a normal loader would have; the check below is the reason. A cracked loader that drops the little blocks, or anything that lets an interrupt tick FRAMES on before arriving here, fails the compare and falls straight back to BASIC with no error -- the game simply does not start.
R $6000 A FRAMES+1, which must still hold $25
  $6001,3 Well below the game block at $5FFF, so the stack cannot walk into the code.
  $6004,3 FRAMES+1. Interrupts are off from the DI above, so this still holds what the tape poked.
  $6009,1 Not a failure path with a message -- just RET, straight back to the BASIC that called USR.
  $600A,3 The real entry point.

# --------------------------------------------------------------------------
# Title screen
# --------------------------------------------------------------------------

@ $7C19 label=TITLE_SCREEN
c $7C19 Title screen: draw the menu and poll for a selection
D $7C19 Runs the "ATICATAC GAME SELECTION" menu -- control method (1-3), character (4-6) and 0 to start. Both answers are packed into the one byte at $5E00: bits 1 and 2 are the control method, which READ_CONTROLS picks out with AND $06, and bits 3 and 4 the character, which DRAW_LIVES turns back into a sprite number. Reading it after choosing each character in turn gives $00, $08 and $10.
  $7C19,3 $5E00 is the base of the game-state block; the first 16 bytes are zeroed here.
  $7C23,9 Point the tile source at the text font, so the menu can be drawn with PRINT_STRING.
  $7C32,6 Select the half-row holding keys 1-5. The OUT to $FD is inert on a 48K; what matters is that A is left as the high address byte for the IN that follows.
  $7C38,1 Keyboard bits are active-low, so CPL makes a set bit mean "pressed".

# --------------------------------------------------------------------------
# Screen address arithmetic
# --------------------------------------------------------------------------

@ $9BA2 label=PIXEL_TO_SCREEN
c $9BA2 Convert pixel coordinates to a display file address
D $9BA2 The standard 48K display address computation, done in place on HL. Builds $4000 + ((y AND $C0) << 5) + ((y AND $07) << 8) + ((y AND $38) << 2) + (x >> 3).
R $9BA2 HL On entry H = y (0-191), L = x. On exit, the display file address of that pixel's character cell.
  $9BA2,7 x >> 3 gives the character column; (y AND $38) << 2 the row within the third.
  $9BB4,1 Stash the low three bits of y -- the scan line within the cell.
  $9BBC,2 Bits 6-7 of y select which third of the screen; OR $40 puts it in the display file.

@ $9BD2 label=PIXEL_TO_ATTR
c $9BD2 Convert pixel coordinates to an attribute file address
D $9BD2 The same conversion as PIXEL_TO_SCREEN, but landing in the attribute file: $5800 + (y >> 3) * 32 + (x >> 3). Preserves BC.
R $9BD2 HL On entry H = y (0-191), L = x. On exit, the attribute address of that character cell.
  $9BE2,3 OR $58 rather than $40 -- the only real difference from PIXEL_TO_SCREEN.

# --------------------------------------------------------------------------
# Drawing
# --------------------------------------------------------------------------

@ $A1D3 label=PLOT_TILE
c $A1D3 Plot one 8x8 tile and step right
D $A1D3 Copies eight bytes from the current tile source to a character cell. The source base is the pointer at $5E01, so the meaning of the tile code depends on what that currently points at -- see PLOT_TILE's note below.
R $A1D3 A Tile code; the source is ($5E01) + A * 8
R $A1D3 HL Display file address of the cell to draw into. On exit, advanced to the next cell to the right.
  $A1D6,6 A * 8 -- eight bytes per tile.
  $A1DC,4 The current tile source. Not a fixed font: callers repoint it.
  $A1E3,8 INC H walks down the eight scan lines of a character cell, which works because the cell never crosses a third boundary.
  $A1ED,4 Undo the eight INC Hs, then INC L to land on the next cell to the right.
E $A1D3 The tile source at $5E01 is deliberately biased by its callers. Initialised to TEXT_FONT less $100, where a tile code is simply an ASCII character, it is repointed during play -- while the score is on screen it holds #R$BFCC, which is TEXT_FONT + $80, so that a raw digit 0-9 indexes the characters '0' to '9' directly with no adjustment at the call site.

@ $A1F3 label=PRINT_STRING
c $A1F3 Print a string of tiles in a single colour
D $A1F3 Draws consecutive tiles left to right, writing one attribute byte per cell as it goes. It keeps the display address and the attribute address live at the same time in the two register banks, swapping with EXX between the pixel write and the colour write rather than recomputing either.
R $A1F3 HL H = y (0-191), L = x -- where to start
R $A1F3 DE The string: one attribute byte, then the tile codes. Bit 7 set on a code marks it as the last one.
  $A1F4,3 Display address into the main bank...
  $A1FC,4 ...and the attribute address into the alternate one.
  $A1F7,3 The first byte is the colour, not a character; it is kept in A' for the whole run.
  $A201,2 Bit 7 is the end marker, not part of the code.
  $A20B,2 Colour the cell PLOT_TILE just drew into.
  $A210,2 Strip the end marker before drawing the final character.

# --------------------------------------------------------------------------
# Actors
# --------------------------------------------------------------------------

@ $9FFB label=ACTOR_TO_WORKSPACE
c $9FFB Copy an actor's position and sprite into the drawing workspace
D $9FFB Lifts three fields out of the record IX points at into fixed locations at $5E15-$5E17, so the drawing code can reach them without IX.
D $9FFB Called for the player and for every monster alike, which is how the two were shown to share one record layout: breaking here and collecting IX gives $EA90 -- the player -- alongside the eight monster records at $EE60, $EE70, $EE80, $EE90, $EEA0, $EEB0, $EEC0 and $EED0.
R $9FFB IX The record to read
  $9FFB,12 +$03 and +$04 are the position.
  $A007,6 +$00 is the sprite.
E $9FFB The record is 16 bytes. The lower half describes the thing itself -- +$00 sprite, +$01 room, +$03 x, +$04 y -- and in the player's copy the upper half describes the weapon it has in flight: +$08 type ($00 when nothing is in the air), +$09 room, +$0B x, +$0C y, +$0E signed velocity. Watched live: firing fills +$08 onwards, +$0B walks across the room while +$0C holds steady, and +$0E flips between $04 and $FC as the shot turns round off a wall.

@ $85F0 label=ACTOR_TICK_TIMER
c $85F0 Count down the actor's timer, and act when it expires
D $85F0 Field +$0F of the actor record is a countdown. Almost every call is a no-op that just decrements it; only on the tick where it reaches zero does control go to #R$81F0.
R $85F0 IX The actor record

# --------------------------------------------------------------------------
# Screen clearing
# --------------------------------------------------------------------------

@ $8093 label=CLEAR_PLAY_AREA
c $8093 Clear the play area, leaving the status panel alone
D $8093 Blanks the 24 character columns the castle is drawn in and stops there, so the parchment scroll down the right-hand side -- score, time, lives and the inventory -- survives untouched and does not have to be redrawn on every room change.
D $8093 Verified by running it against a live room and reading the display file back: columns 0-23 came back all zero, columns 24-31 unchanged.
  $8093,6 24 bytes across, 192 display-file rows -- the whole height of the screen, but only three quarters of its width.
  $8099,1 The fill byte. Blank here, but the shared entry below takes whatever is in A.

@ $809A label=FILL_BLOCK
c $809A Fill a rectangular block of the display file
D $809A The general form of CLEAR_PLAY_AREA above, which falls into it. Because it steps by a fixed 32 bytes per row rather than doing any display-file address arithmetic, "rows" here means consecutive 32-byte rows of the display file, not screen lines -- walking $4000 upwards covers the interleaved thirds in the order they are stored.
R $809A HL Top-left corner, as a display file address
R $809A B Width in bytes (character columns)
R $809A C Number of rows
R $809A A The byte to fill with
  $809A,2 Both are needed again on the next row, so they are saved rather than recomputed.
  $809C,3 One display-file row is 32 bytes.
  $809F,4 Fill B bytes across.
  $80A4,1 Step down to the next row.

# --------------------------------------------------------------------------
# Collision
# --------------------------------------------------------------------------

@ $85B2 label=CHECK_HIT
c $85B2 Has this monster caught the player?
D $85B2 Compares the monster IX points at against the player's record at $EA90: same room, and within 12 pixels on both axes. Confirmed by breaking here and collecting IX -- it is only ever one of the eight monster records at $EE60-$EED0, tested against the fixed player address.
R $85B2 IX The monster to test
R $85B2 E 1 if it has the player, 0 if not
  $85B2,8 Cheapest rejection first: a monster in another room cannot touch anything.
  $85BB,8 $31 is not an arbitrary threshold: sprite codes $01-$30 are the three playable characters, sixteen codes each (see ACTOR_HANDLERS), so "non-zero and below $31" means "$EA90 currently holds a player". It reads $66 while the game is still bringing the player into the room, which is what stops them being killed before they exist.
  $85C3,11 |dx|, via negate-if-negative rather than a signed compare.
  $85CE,3 Within 12 pixels horizontally, or no hit.
  $85D1,13 The same for |dy|.
  $85DF,5 Record the hit where the caller can find it...
  $85E4,3 ...and make a noise about it.

# --------------------------------------------------------------------------
# Sound
# --------------------------------------------------------------------------

@ $A3A8 label=BEEP
c $A3A8 Square wave on the beeper
D $A3A8 Toggles bit 4 of port $FE with a busy-wait either side, which is the only way a 48K makes a sound. Every sound effect in the game is a call here, or a short sequence of them with different pitches.
R $A3A8 B Half-period: the delay between edges, so smaller is higher pitched
R $A3A8 C Number of complete cycles, i.e. how long the note lasts
  $A3A8,2 The plain entry point plays exactly one cycle; callers wanting a longer note enter below with C already set.
  $A3AA,4 Speaker bit high.
  $A3AF,2 The pitch: burn B iterations doing nothing.
  $A3B3,3 Speaker bit low again. This also writes 0 to the border bits, which is why the border stays black through every effect.
  $A3B9,3 Repeat for C cycles.

@ $A3E5 label=PLAY_SOUND_CAUGHT
c $A3E5 Start sound $64, the one for being caught
D $A3E5 A sound is not played here and it is not played by a scheduler either: it is spawned as an actor. This writes a sprite and a count into the record at $EAA0, and from the next frame on the dispatcher finds it there like any other creature and calls its handler, which beeps once, counts down, and frees the slot when it reaches zero.
D $A3E5 So the second byte is a duration in frames rather than the room number the same field holds in every other record, and the sprite is one of the codes that draws nothing -- $64, $65 and $A0 are sounds wearing an actor's clothes.
D $A3E5 Three routines share the tail with different values: sound $64 for 16 frames here, $65 for 10 from #R$A403 (a room entered) and $A0 for 16 from #R$A485 (food eaten). This one is started by CHECK_HIT when a creature touches the player, and by MUSHROOM_DRAIN on every pass the player stands on a mushroom. There is one slot, so a new sound replaces one still playing. Watched live, writing $64 and $10 into the two bytes by hand makes the count fall 0C, 07, 03 over the following frames and then the slot empties itself.
R $A3E5 BC B = which sound, C = how many frames it lasts
  $A3E5,3 This entry's sound and length.
  $A3E8,6 Sprite first, then the count -- the field an ordinary record uses for its room.

@ $A3EF label=SOUND_CAUGHT
c $A3EF Sound $64 (being caught), one frame of it
D $A3EF Called once a frame while the sound lasts. The pitch is taken from however much of the countdown is left, so the note slides as it plays rather than holding steady, and the same handler gives a different sweep for a different starting count.
R $A3EF IX The sound's record
  $A3EF,5 One frame less to go; at zero the sound is over.
  $A3F4,4 What is left of the count is how many cycles to sound.
  $A3F8,3 And, folded about $43, the pitch -- so it glides.
  $A3FB,3 Into BEEP, entered below its own first instruction so the cycle count survives.

@ $A408 label=SOUND_NEW_ROOM
c $A408 Sound $65 (entering a room), one frame of it
D $A408 The same shape as SOUND_CAUGHT with the pitch derived differently -- three rotations, complemented, folded about $40 -- which is what makes it a different effect rather than the same one at another speed. ARRIVE_IN_ROOM starts it through PLAY_SOUND_NEW_ROOM whenever a room is entered.
  $A408,5 Counting down.
  $A40D,4 Cycles from the count.
  $A411,7 Pitch from the count as well, but along a different curve.

@ $A3FE label=END_SOUND
c $A3FE Free the slot when a sound finishes
D $A3FE Zeroing the sprite is all it takes: the dispatcher skips a record with sprite $00, so the sound simply stops being found. Shared by all three sound handlers.

# --------------------------------------------------------------------------
# Collision: monster vs player, and player vs monster
# --------------------------------------------------------------------------

@ $8566 label=CHECK_SHOT_HIT
c $8566 Has the player's shot hit this monster?
D $8566 The mirror image of CHECK_HIT. Same test, same 12-pixel box, but reading $EA98 onwards -- the upper half of the player's record, where a weapon in flight lives -- so this asks whether the player has hit the monster rather than the other way round. The two are called back to back from the same place.
D $8566 This pair was previously written up as two entries of an 8-byte "object table". That was wrong. $EA90 is one 16-byte record laid out exactly like a monster's, and $EA98 is its second half, not a neighbouring record; the giveaway is that ACTOR_TO_WORKSPACE is called with $EA90 and with the monster records but never with $EA98.
R $8566 IX The monster to test
R $8566 E 1 if the shot has hit it, 0 if not
  $8566,8 +$09 is the weapon's room, +$08 its type, +$0B and +$0C its position.

# --------------------------------------------------------------------------
# Actor movement
# --------------------------------------------------------------------------

@ $845F label=MOVE_ACTOR
c $845F Drive the pumpkin and the spider: move, bounce off the walls, animate
D $845F The per-actor update. Actors drift in a direction until they hit the edge of the room, then reverse; the direction is re-rolled at intervals from the refresh register, which is the game's random number source.
D $845F Velocity lives in +$08 (x) and +$09 (y) and is nudged one step per call toward +2 or -2 rather than being set outright, so things accelerate and turn smoothly instead of snapping.
R $845F IX The actor to move
  $845F,9 An actor in another room is not drawn or moved...
  $8468,3 ...it only gets its timer ticked.
  $846B,4 Count of actors present in this room.
  $846F,3 Two proximity tests: has the player shot this monster, and has this monster caught the player.
  $847D,4 The room's half-width and half-height -- how far from the centre an actor may stray.
  $8490,4 The refresh register as a source of randomness: whatever R happens to hold, masked to two direction bits.
  $84C2,8 Flip the bottom bit of the sprite index every other tick, which is the walk animation.
  $84CD,6 Provisional new x = x + x-velocity.
  $84D4,5 Distance from the room's centre column ($58)...
  $84DB,8 ...and if that is outside the half-width, stay put and reverse.
  $84F8,6 The same again for y, about centre row $68.
  $8523,6 Commit the new position.
  $8530,7 Two kinds are exempt from the test below: the humpback, whose codes are $9C-$9F, and the four big monsters at $70-$7F -- the mummy, Frankenstein's monster, the devil and Dracula, which come through STEP_ACTOR too. Masking with $FC and $F0 tests a whole run of codes in one compare, without caring which frame is showing.
  $853F,8 Everything else is destroyed, with the 155 points of KILL_MONSTER, whenever the player is not in play -- sinking or rising. So dying clears the room of small creatures (measured in the simulator, 2026-09-27).
E $845F Nothing in the disassembly jumps here, which is not because the routine is dead: it is entry $5C/$5D of the table at ACTOR_HANDLERS, and DISPATCH_ACTOR reaches it through a JP (HL). Breaking here does catch it, 16 times in 20, always with IX = $EE80 -- the monster whose sprite byte is currently $5C. Two earlier rounds of sampling reported zero hits and concluded it was unused; both were taken before the player had finished spawning, when no monster was in the room yet.
E $845F #R$84CD is also entered directly by eight other routines, which is why the position update is written as a separate stretch: they supply their own velocity in +$08/+$09 and reuse the bounce logic. Verified against the running game -- ($5E1D) reads 56 by 56, and sampled actor positions stay inside $58 +/- 56 by $68 +/- 56.

# --------------------------------------------------------------------------
# Animation
# --------------------------------------------------------------------------

@ $8E26 label=UPDATE_KNIGHT
c $8E26 Per-frame update for the knight
D $8E26 One of three near-identical routines, one per playable character: this is the knight, UPDATE_WIZARD and UPDATE_SERF are the other two. Which one runs is decided by the sprite byte alone -- see ACTOR_HANDLERS.
D $8E26 Treats +$06 and +$07 as a signed dx/dy, compares their magnitudes to decide whether the movement is mostly horizontal or mostly vertical, and picks a sprite accordingly -- base + 4 or base + 8, with the low two bits cycling to give the walk cycle.
D $8E26 This looked at first like it contradicted MOVE_ACTOR, which treats +$06 as a pair of direction bits rather than a signed value. It does not: the two routines work on different records. Breaking on each and reading IX shows UPDATE_KNIGHT is only ever called with IX = $EA90, the player, while MOVE_ACTOR is called with the 16-byte monster records at $EE90. Both readings stand; the field simply means different things in the two layouts.
R $8E26 IX The actor to animate
  $8E32,6 dx and dy. If both are zero the thing is standing still and keeps its sprite.
  $8E3C,5 FRAMES, so the walk cycle advances every fourth frame rather than every call. Interrupts are enabled during play (checked live: IFF1 set, IM 1), so the ROM's interrupt handler is what keeps this ticking.
  $8E43,6 Cycle the low two bits: the four frames of the walk.
  $8E5E,10 Mostly-vertical movement takes one sprite group, mostly-horizontal another.
  $8E6D,3 A footstep.
  $8E7B,7 Only while TICKS -- main-loop passes, not frames -- is a multiple of sixteen; the gate stays open for every frame of that pass, so it takes one or two units per sixteen passes.
  $8E82,6 The life force runs down on its own, a unit at a time. Reaching zero is death -- there is no way to stand still and survive.
  $8E88,6 Store it and redraw the roast, which only actually redraws once an eighth has gone.

# --------------------------------------------------------------------------
# Input
# --------------------------------------------------------------------------

@ $93BE label=READ_CONTROLS
c $93BE Read the player's controls, whichever kind they chose
D $93BE Returns one byte for all three control methods, in Kempston's bit order: bit 0 right, bit 1 left, bit 2 down, bit 3 up, bit 4 fire. A bit is 0 when that direction is being asked for.
D $93BE Kempston reads the other way round, so its byte is inverted; the keyboard needs no inversion but does need its bits shuffled, because Q and W sit in the opposite order to left and right. That swap is the whole reason this routine looks fiddly -- it is what lets the movement code downstream be written once instead of three times.
D $93BE This is what pins down the key map: the half-row selected is $FBFE, which is Q W E R T, and after the swap Q lands on the "left" bit and W on the "right" bit. So the keyboard controls are Q left, W right, E down, R up, T fire. Confirmed live -- holding W drives the player's x up to the room's right-hand limit and E drives y down to the bottom one.
R $93BE A The direction/fire mask, 0 bits meaning pressed
  $93BE,5 The control method chosen on the title screen, kept in $5E00.
  $93C3,6 0 is keyboard, 4 is the cursor keys, anything else Kempston.
  $93C9,3 Kempston is active high, so invert it to match the other two.
  $93CD,4 Select the half-row holding Q, W, E, R and T.
  $93D1,3 Bits 0-4 are Q, W, E, R, T in that order.
  $93D4,9 Exchange bits 0 and 1, so that W becomes "right" and Q "left".
  $93DE,4 E, R and T are already in the right places for down, up and fire.

# --------------------------------------------------------------------------
# Actor dispatch
# --------------------------------------------------------------------------

@ $7E7E label=DISPATCH_ACTOR
c $7E7E Jump to the handler for whatever this actor is
D $7E7E Looks the actor's +$00 byte up in ACTOR_HANDLERS and jumps to the address it finds. This is why so many of the per-creature routines have nothing referencing them anywhere in the disassembly -- they are only ever reached from that table, which to a disassembler is just data.
D $7E7E The jump itself is worth a look. Rather than an equivalent sequence ending in JP (HL), the routine jumps to $5CB0 -- an address in the system variables, well outside the game. What lives there is a single $E9 byte, which is the opcode for JP (HL), and it got there because one of the five blocks on the tape is one byte long and loads to exactly that address. So the dispatch runs through an instruction the loader poked into spare ROM-variable space, and a loader that skips that block leaves the game jumping into whatever happened to be at $5CB0.
R $7E7E IX The actor
  $7E7E,1 The caller left the address to come back to in HL, and this puts it on the stack -- so the handler's own RET returns into MAIN_LOOP, and the dispatch itself costs a jump rather than a call.
  $7E7F,3 The table.
  $7E82,3 The actor's sprite byte doubles as its type.
  $7E85,6 Two bytes per entry, so double the index -- through B as well, since types run past $7F.
  $7E8C,4 Fetch the handler address into HL.
  $7E90,3 The poked JP (HL).

@ $7EE6 label=ACTOR_HANDLERS
w $7EE6 Handler address for each actor type
D $7EE6 202 addresses, indexed by an actor's +$00 byte, used by DISPATCH_ACTOR. Entries come in runs of two or four because the low bits of +$00 are the animation frame rather than part of the identity -- $5C and $5D are the two frames of one creature and share a handler, as do $58 to $5B.
D $7EE6 The first three runs are the playable characters -- $01-$10 knight, $11-$20 wizard, $21-$30 serf -- sixteen sprite codes each, which is what makes "below $31" mean "is a player" in CHECK_HIT. Confirmed by starting a game as each of the three in turn and reading the player's sprite byte back: $08, $18 and $28, the same offset into each band.
D $7EE6 Checked against the running game: the monster at $EE80 had sprite byte $5C, the table entry two bytes into #R$7EE6 + $5C * 2 reads #R$845F, and a breakpoint at #R$845F does fire with IX pointing at that monster.

@ $80D2 label=UPDATE_WIZARD
c $80D2 Per-frame update for the wizard
D $80D2 The wizard's equivalent of UPDATE_KNIGHT, reached from ACTOR_HANDLERS for sprite codes $11-$20.

@ $8DC4 label=UPDATE_SERF
c $8DC4 Per-frame update for the serf
D $8DC4 The serf's equivalent of UPDATE_KNIGHT, reached from ACTOR_HANDLERS for sprite codes $21-$30.


# --------------------------------------------------------------------------
# Rooms visited
# --------------------------------------------------------------------------

@ $96AF label=MARK_ROOM_VISITED
c $96AF Mark a room as seen, by writing the instruction that does it
D $96AF Sets one bit in the 19-byte map at $5E40, one bit per room, 152 rooms in all. The bit number is not known until run time, and rather than shift a mask into place the routine assembles the instruction it needs and stores it over the one below.
D $96AF SET b,(HL) is $CB followed by $C6 + b * 8, so ORing the room's low three bits (already shifted up by the three RLCAs) with $C6 gives exactly the operand byte required, and it is written into SET_BIT_OP+1 -- the second byte of the SET at #R$96C6.
D $96AF Checked by calling it directly with a series of room numbers and reading both the map and the patched bytes back: $2A set bit 42 and left SET 2,(HL) in place, $07 set bit 7 as SET 7, $08 set bit 8 as SET 0, $4B set bit 75 as SET 3, and $97 set bit 151 as SET 7 -- the last bit the map has room for.
R $96AF A The room number
  $96AF,7 Room / 8 -- which byte of the map.
  $96B8,4 The map itself. It sits below #R$6000, so it is not part of this disassembly.
  $96BC,7 Room AND 7, shifted into the bit-number field of a SET opcode.
  $96C3,3 Overwrite the operand of the instruction on the next line.
  $96C6,2 Reads as SET 0 here, but by the time it runs it is SET (room AND 7).

@ $96C9 label=COUNT_ROOMS_EXPLORED
c $96C9 Work out how much of the castle has been seen
D $96C9 Counts the bits set in the room map and turns the total into a two-digit BCD figure at $5E54. It is not shown while playing -- DRAW_SUMMARY prints it on the GAME OVER screen, as the last of the three figures under the heading. Every third room seen is worth 2, and 1 is added at the end, so the value is (rooms / 3) * 2 + 1.
D $96C9 Measured by setting the map by hand and running it: 6, 7 and 8 rooms all give $05, 11 gives $07, 144 gives $97, and none at all gives $01.
D $96C9 The map holds 152 bits but the castle does not have 152 rooms. ROOM_TABLE has 151 entries, and of those the last two are black -- colour $00, so nothing they draw can be seen. That leaves 149 real rooms, 0 to 148, and (149 / 3) * 2 + 1 is exactly 99. The figure is scaled so that seeing everything reads 99 and it never has to carry into a third digit, which a single byte of BCD could not hold: setting all 152 bits by hand does overflow it, and $5E54 comes back $01, but no game can get there.
D $96C9 It is a percentage: DRAW_SUMMARY prints it after the font's percent sign (the "$" of PERCENT_LABEL is drawn as %), so every room seen reads 99%.
  $96C9,6 19 bytes, 8 bits each.
  $96D5,4 Walk the bits of one byte.
  $96D9,7 Two per three rooms, in BCD -- hence the DAA.
  $96E0,1 Keeps the running total in BCD so it can be printed a digit at a time.
  $96E7,4 The finished figure, read back by the status panel.

# --------------------------------------------------------------------------
# Score
# --------------------------------------------------------------------------

@ $A19C label=ADD_SCORE
c $A19C Add to the score and redraw it
D $A19C The score is three bytes of BCD at $5E2A-$5E2C, printed as six digits. The three DAAs carry across the whole of it, so a caller only has to hand over the amount in BC.
D $A19C Confirmed against a running game: with the panel reading SCORE 000310 the three bytes held $00 $03 $10.
R $A19C BC The amount to add, in BCD
  $A19C,3 The least significant byte, working backwards from there.
  $A19F,4 DAA after each addition is what keeps it decimal.
  $A1A3,9 Carry up through the middle and top bytes.
  $A1AE,6 Point the tile source at the digits before drawing -- this is the biased pointer PLOT_TILE's note describes, TEXT_FONT + $80, so a digit value indexes its own character.
  $A1BA,5 Three bytes, two digits in each.
  $A1BF,7 High nibble first, then the low one.
E $A19C #R$A1AE and #R$A1B7 are entered on their own to redraw the score without changing it, and #R$A1BF is the general digit printer: B bytes of BCD from DE, drawn at the screen address in HL. The status panel uses that last entry to print the rooms-explored figure from COUNT_ROOMS_EXPLORED as well.

# --------------------------------------------------------------------------
# Rooms: drawing and geometry
# --------------------------------------------------------------------------

@ $9BEA label=DRAW_ROOM
c $9BEA Draw the room the player is in
D $9BEA Looks the room up twice. Its own entry in ROOM_TABLE gives a colour and a shape number; the shape number then selects an entry in ROOM_SHAPES, which carries how far the player may walk and where the outline's geometry lives. Rooms therefore share outlines freely -- only the colour and the shape number are per-room.
D $9BEA Verified against a running game: in room $00 the table gives colour $42 and shape $00, shape $00 gives 56 by 56 and the two pointers #R$A9DF and #R$A9EF, and the machine's own $5E1A, $5E1D and $5E1E read back $42, 56 and 56 with the attribute file filled with $42.
  $9BEE,3 The room the player is in.
  $9BF1,3 Two bytes per room...
  $9BF4,5 ...so double the room number to index it.
  $9BF9,5 First byte: the colour the whole room is drawn in.
  $9BFF,9 24 by 24 character cells -- the play area, the same extent CLEAR_PLAY_AREA blanks.
  $9C08,3 Flood the attribute file with the room's colour in one go.
  $9C0C,11 Second byte is the shape number; six bytes per shape, so multiply by 6 the cheap way, as x2 + x4.
  $9C18,5 How far from the centre the player may walk -- MOVE_ACTOR reads these back out of $5E1D.
  $9C1D,5 The vertical limit.
  $9C22,4 Where the shape's vertices are.
  $9C26,4 Where its edge list is.
  $9C2A,3 The vertices are indexed through IX.

@ $9C2F label=DRAW_OUTLINE
c $9C2F Walk the edge list and draw the room's outline
D $9C2F The edge list is a run of vertex numbers. The first begins a group, each one after it draws a line from that vertex to this one, and $FF ends the group; a second $FF ends the list. Writing it as groups rather than as pairs means a corner shared by three lines is only named once.
D $9C2F The vertex number cannot be known in advance, so as with MARK_ROOM_VISITED the routine writes the instruction that will use it: the displacement in each LD r,(IX+$00) below is overwritten just before it runs.
D $9C2F For room shape $00 the vertices are two nested squares -- (4,187) (4,4) (187,4) (187,187) and (31,160) (31,31) (160,31) (160,160) -- and the groups are 0 to 1,3,4; 2 to 1,3,6; 5 to 1,4,6; 7 to 3,4,6. That is the four outer walls, the four inner ones and the four corner diagonals, each drawn exactly once, which is the "looking into a box" outline every room is built from.
  $9C2F,4 $FF ends the whole list.
  $9C34,9 Double the vertex number and patch it into both halves of the 16-bit fetch below.
  $9C3D,6 Reads as (IX+$00) but the displacements were just rewritten.
  $9C5A,3 Draw one line, corner to corner.

@ $9C79 label=DRAW_LINE
c $9C79 Draw a line between two points
D $9C79 Takes the difference along each axis, remembers which way each one runs in a pair of bits, and picks whichever axis is longer to step along -- the ordinary way of drawing a line one pixel at a time on a machine with no multiply. $5E23 and $5E24 hold the working values.
R $9C79 BC One end
R $9C79 DE The other
  $9C79,2 Keep one end in HL to walk along.
  $9C7D,8 |dx|, with bit 0 of C remembering the direction.
  $9C86,8 |dy|, in bit 1.
  $9C8E,1 Whichever is longer becomes the axis stepped along...
  $9C95,3 ...and the steep case is handled separately.

@ $A854 label=ROOM_TABLE
; span $A854,302
b $A854 Colour and shape of each room
D $A854 Two bytes per room, indexed by room number: the first is the attribute the whole play area is filled with, the second is an index into ROOM_SHAPES. The table has 151 entries: the 149 rooms, then entry $95, black, and entry $96, the shape TRAPDOOR_FALL draws. With 149 rooms sharing thirteen outlines, this is most of what makes the castle fit in memory.

@ $A982 label=ROOM_SHAPES
; span $A982,78
b $A982 Geometry of each room shape
D $A982 Six bytes per shape: how far the player may walk from the centre horizontally and vertically, then a pointer to the shape's vertex table, then a pointer to its edge list. Shape $00 reads 56, 56, #R$A9DF, #R$A9EF.
D $A982 A vertex table is two bytes per point, x then y; an edge list is the $FF-separated groups DRAW_OUTLINE walks.

# --------------------------------------------------------------------------
# The status panel
# --------------------------------------------------------------------------

@ $A240 label=PAINT_PANEL
c $A240 Colour the status panel to go with the room
D $A240 The third and last step of a room change, after CLEAR_PLAY_AREA and DRAW_ROOM. It writes attributes only -- the scroll, the timer and the score are drawn elsewhere and simply take whatever colour is underneath them, which is why walking into a differently-coloured room recolours the whole panel without anything being redrawn.
D $A240 The colour is the room's own ink complemented: CPL then AND $07 keeps just the three ink bits and inverts them, so a red room gives a cyan panel, green gives magenta and so on. Complementing also throws away the bright and paper bits, which is why the panel comes out one shade darker than the room outline.
D $A240 Inks 0 and 1 -- black and blue -- would be unreadable against black paper, so anything below 2 is replaced outright by $44, bright green. Measured by writing each room colour into $5E1A in turn and re-running: $42 gives $05, $43 gives $04, $44 gives $03, $45 gives $02, and $46 and $47 both give $44.
  $A240,6 x = 192, the first character column past the play area.
  $A246,3 8 columns wide, 24 rows deep -- the rest of the screen.
  $A249,6 The room's colour, inverted.
  $A24F,4 Too dark to read against black...
  $A253,2 ...so use bright green instead.
  $A259,4 Fill one row of the panel.
  $A25E,4 32 bytes to the row below.
  $A266,6 The little blocks below the scroll are coloured separately...
  $A26C,9 ...in the room's own colour rather than the complement.
  $A27E,3 One cell on its own.
  $A28C,5 Bright white, for the part that never changes.

# --------------------------------------------------------------------------
# Doors and room changes
# --------------------------------------------------------------------------

@ $90CC label=PLAYER_AT_DOOR
c $90CC Is the player standing in this doorway?
D $90CC Unlike CHECK_HIT the box is not centred on the door. Both comparisons are unsigned against a subtraction that is not made absolute, so the box starts at the door's own corner (+$03, +$04) and runs right and up from it -- the door's own cells. It also needs the player in play and the low nibble of the player's +$02 clear.
D $90CC Bit 6 of +$05 says which way the doorway faces, and it halves the tolerance across the door rather than along it: a door in a side wall is generous vertically and tight horizontally, and the other way round for one in the top or bottom wall. The caller passes $1111 as the starting tolerance in BC.
R $90CC IX The door
R $90CC BC Tolerance across and along the doorway
R $90CC F Carry set if the player is in it
  $90CC,6 Suppressed while the low nibble of $EA92 is set -- the flag ENTER_ROOM leaves behind, so one doorway cannot fire twice.
  $90D2,7 And only while the player is actually in play, the same $01-$30 test CHECK_HIT makes.
  $90D9,8 Halve the tolerance across the door, unless it faces the other way.
  $90E1,8 One-sided: unsigned, so a negative difference fails the compare outright.
  $90F1,9 The same again for the other axis, negated because this one is measured the opposite way.

@ $90FB label=NEAR_PLAYER
c $90FB Is the player within 12 pixels of this thing?
D $90FB The symmetric version of the test PLAYER_AT_DOOR makes -- absolute difference on both axes against the same 12-pixel box CHECK_HIT uses, with no room check and no one-sidedness.
R $90FB IX The thing to measure from
  $90FB,9 |dx|, by negating if it came out negative.

@ $9117 label=ENTER_ROOM
c $9117 Move the player through a door and redraw everything
D $9117 Takes the door record in IX, copies its destination into the player's room and position, and then rebuilds the screen: mark the room seen, blank the play area, draw the new room, recolour the panel.
D $9117 The arrival position is not stored outright. +$02 packs both offsets into one byte, unpacked by rotating it in opposite directions and masking to $1E -- an even number 0 to 30 each way, the vertical one negated. Every door checked holds $34, which comes out as 8 to the right and 6 up, so the player lands just inside the room rather than on top of the doorway they arrived through.
D $9117 Confirmed by setting IX to four different door records and running from ENTER_ROOM+3, past its first call: doors to rooms $07, $19, $01 and $00 produced exactly the destination and the offset position predicted from their bytes.
R $9117 IX The door being entered
  $9117,3 Swap to the door's other side. The record the player touched describes this room; the one eight bytes away describes where they come out. That reassignment of IX is also why anything testing this routine has to enter below it.
  $911A,6 +$01 is the destination room.
  $9120,12 Rotate left and mask: the horizontal offset, added to the door's own x.
  $912C,16 Rotate right three times for the vertical one, which is subtracted rather than added.
  $913C,3 Head the player into the room, away from the wall this door is in; with the nibble set below, STEER keeps them walking that way for fifteen frames.
  $913F,8 Set the flag that stops PLAYER_AT_DOOR firing again on the way out.
  $9147,6 Record the new room as seen.
  $914D,9 Blank the play area, draw the new room, colour the panel to match.
E $9117 Each door is one sixteen-byte record whose two eight-byte halves are in the two rooms it joins (+$00 type, +$01 the room this half is in, +$02 the packed arrival offset, +$03 and +$04 the doorway's corner, +$05 orientation and flags, +$06 and +$07 its walk box). The doors tested are the ones in the player's room's list, dispatched by DISPATCH_FROM_LIST.

# --------------------------------------------------------------------------
# Sprites
# --------------------------------------------------------------------------

@ $9962 label=DRAW_SPRITE_PIXELS
c $9962 Draw a sprite, choosing the routine from the drawing mode
D $9962 Neither this nor DRAW_SPRITE_COLOURS does any drawing. Each loads the address of its own table of eight routines and falls into the tail of DISPATCH_ACTOR, which indexes the table and jumps through the JP (HL) the tape left at $5CB0 -- the same machinery that picks an actor's handler, reused for picking how a sprite gets put on the screen.
D $9962 The mode is the top three bits of the actor's +$05, so the low five bits are free for other flags -- PLAYER_AT_DOOR reads bit 6 of the same byte as a door's facing.
R $9962 C Sprite number
R $9962 B Drawing mode in its top three bits
R $9962 DE Where to draw, as pixel coordinates
  $9962,3 One table of eight...
  $9966,7 ...indexed by the top three bits of B.
  $996D,3 Into the dispatcher's tail, which does the lookup and the jump.

@ $9970 label=PIXEL_DRAWERS
w $9970 Eight ways of putting a sprite's pixels on the screen
D $9970 Chosen by DRAW_SPRITE_PIXELS from the top three bits of the drawing mode. Used only for doors and furniture; creatures are drawn by DRAW_THING. The eight are the eight ways to lay a rectangle down: 0 as stored, 1 mirrored, 2 turned a quarter clockwise, 3 transposed (mirrored across the diagonal), 4 upside down, 5 a half turn, 6 transposed the other way, 7 turned a quarter anticlockwise. A door's mode is its wall, which is how one picture serves all four.

@ $9980 label=DRAW_SPRITE_COLOURS
c $9980 Draw a sprite from the other set of eight routines
D $9980 As DRAW_SPRITE_PIXELS, but pointing at COLOUR_DRAWERS. Actor handlers call this one to put a sprite down and the masked one to take it away again, a row above -- which is why #R$91F2 does the two with the same coordinates but a DEC D between them.
  $9980,3 The other table.

@ $9985 label=COLOUR_DRAWERS
w $9985 Eight ways of putting a sprite's colours on the screen
D $9985 Chosen by DRAW_SPRITE_COLOURS from the drawing mode: the same eight orientations as PIXEL_DRAWERS, applied to a graphic's colour table. A colour of $00 leaves the cell alone and $FF writes the room's colour.

@ $9995 label=FETCH_SPRITE
c $9995 Look up a sprite's bitmap and work out where it goes
D $9995 Sprite numbers are 1-based, so the number is decremented before being doubled into the table of addresses at #R$A600. The first two bytes of the data are its size, and the pointer is left just past them.
R $9995 C Sprite number
R $9995 DE On exit, the first row of bitmap data
R $9995 B On exit, width in bytes
R $9995 C On exit, height in rows
R $9995 HL On exit, where the top-left corner lands in the display file
  $9995,3 The table of sprite addresses.
  $9998,7 Numbered from 1, two bytes each.
  $99A0,5 The address of the bitmap itself.
  $99A5,3 Turn the pixel coordinates into a display file address.
  $99A8,6 Width then height, and step past them to the first row.
E $9995 Watched live, the sizes coming back are 4 by 24 for the characters and 6 by 5 or 6 by 6 for smaller pieces -- so width really is in bytes, eight pixels at a time.
E $9995 #R$A600 is not a table of its own. It is the 161st entry of SPRITE_TABLE, and this routine does the same arithmetic SPRITE_ADDRESS does, so asking it for sprite 1 fetches entry 161. The base is what says which family of sprites is wanted. An earlier reading of this routine took the 39 entries between #R$A600 and #R$A64E for the whole table and concluded it held the knight, the wizard and seven frames of the serf; that was an accident of where the next base happens to fall.

@ $99AF label=FETCH_SPRITE_ATTRS
c $99AF Look up a sprite's colours
D $99AF The same routine as FETCH_SPRITE but based at #R$A64E -- the 200th entry of SPRITE_TABLE rather than the 161st -- and ending in PIXEL_TO_ATTR rather than PIXEL_TO_SCREEN, so what it fetches is a sprite's colours rather than its shape.
R $99AF C Sprite number
  $99AF,3 The colour tables, one per sprite.
  $99BF,3 The attribute address rather than the display one.

@ $99C9 label=BLIT_SPRITE
c $99C9 Copy a sprite to the screen, combining it however the caller asked
D $99C9 The inner loop of everything that moves. A sprite is width bytes by height rows, and the row-to-row step is left to SCREEN_ROW_UP rather than being computed here, because the display file's thirds make it anything but a simple addition.
D $99C9 It works upwards. The first row of a sprite's data is its bottom row, so an actor's +$03 and +$04 are the point its feet stand on rather than a top-left corner. Rendering the data top-down produces nothing recognisable; reversed, it comes out as a picture.
D $99C9 How each byte meets what is already on the screen is not decided by a branch. #R$9D19 hands back an opcode and it is written over the NOP in the middle of the loop, so the same six instructions become a plain copy, an OR, an XOR or an AND with nothing tested per byte. Read live during play the byte is $00 -- a NOP, so a plain copy.
  $99CA,6 Fetch the combining opcode and write it into the loop below.
  $99D0,3 Bitmap, size and destination.
  $99D5,2 One byte of the sprite.
  $99D7,1 Assembled at run time: NOP, OR (HL), XOR (HL) or AND (HL).
  $99D8,4 Store it and move one cell right, width times.
  $99DD,3 Up one pixel row -- see SCREEN_ROW_UP. Sprites are stored and drawn from the bottom.
  $99E0,4 Repeat for every row.

@ $9D19 label=SPRITE_COMBINE_OPCODE
c $9D19 Choose the instruction that puts a sprite byte on the screen
D $9D19 Returns an opcode rather than a flag, for BLIT_SPRITE to write into the middle of its own loop. The drawing mode is packed into B: the low two bits pick the combining operation here, the top three pick which of the eight drawing routines runs.
R $9D19 B Drawing mode
R $9D19 A $00 for NOP, $B6 for OR (HL), $AE for XOR (HL)
  $9D19,4 Mode 0 leaves A zero -- a NOP, so the sprite byte is stored as it is.
  $9D1D,4 $AE is XOR (HL), which is how a sprite is drawn and then rubbed out again by drawing it a second time.
  $9D21,1 Modes 2 and 3 both take it.
  $9D22,2 $AE + 8 is $B6, OR (HL) -- the sprite laid over what is already there.

@ $9F03 label=SCREEN_ROW_UP
c $9F03 Move a display file address up one pixel row
D $9F03 The counterpart to PIXEL_TO_SCREEN's arithmetic, done as cheaply as possible because BLIT_SPRITE calls it once per row of every sprite on the screen. Within a character cell the row is the low three bits of H, so most calls are a DEC H and a test; only one in eight has to step back a whole character row, and only one in sixty-four crosses between the display's thirds.
R $9F03 HL A display file address; on exit, the same column one pixel higher
  $9F03,1 The common case, and usually the only instruction that runs.
  $9F04,5 Did that take us out of the top of the character cell? If not, done.
  $9F09,5 It did: back one character row. A borrow here means we also crossed into the third above, where H is already right.
  $9F0E,4 No borrow, so undo the DEC H's effect on the cell row.

# --------------------------------------------------------------------------
# The clock
# --------------------------------------------------------------------------

@ $95DA label=TICK_CLOCK
c $95DA Advance the elapsed-time clock
D $95DA The clock counts up rather than down -- Atic Atac's TIME is how long you have been in the castle, not how long is left. Three bytes of BCD at $5E3D, $5E3E and $5E3F hold it, and the panel prints them as one digit, then two, a colon, then two: 000:09.
D $95DA Its time base is the ROM's own FRAMES counter, which ticks 50 times a second on the interrupt the game leaves enabled. Rather than remember when the last second was, it subtracts 50 from FRAMES whenever there are at least 50 there, so the remainder carries the fraction of a second forward and nothing drifts.
D $95DA Confirmed against a running game: with the three bytes reading $00 $00 $09 the panel showed TIME 000:09.
  $95DA,6 Fewer than fifty frames since the last tick, so there is nothing to do yet.
  $95E0,5 Take a whole second out and leave the remainder for next time.
  $95E5,3 The seconds, the last of the three bytes.
  $95E8,4 INC then DAA -- adding 1 in BCD, so the digits stay printable.
  $95EC,4 Sixty, in BCD, is $60.
  $95F0,3 Round the seconds and carry into the minutes.
  $95FD,4 And the minutes into the hours.
  $9601,2 Hours are kept to a single digit, which is what makes the display 000:09 rather than 00:00:09.

# --------------------------------------------------------------------------
# Game over
# --------------------------------------------------------------------------

@ $8C35 label=GAME_OVER
c $8C35 Clear the castle away and show how it went
D $8C35 Reached from LOSE_LIFE when a life is lost with none to spare, whatever took it. It blanks the play area, prints GAME OVER across it, and hands over to DRAW_SUMMARY for the three figures underneath, then sits in a counting loop long enough to read them.
D $8C35 Note the second and third instructions: the tile source has to be pointed back at the text font first. During play it holds #R$BFCC, the copy biased so that digits index themselves, and anything printed through PLOT_TILE while it is still there comes out as the wrong glyphs entirely.
  $8C35,3 The castle goes; the status panel down the side stays.
  $8C38,6 Back to the text font, or the words below would be gibberish.
  $8C3E,6 "GAME OVER", centred above the figures.
  $8C47,3 TIME, SCORE and the proportion of the castle seen.
  $8C4A,5 A delay, and a long one: twenty times round a full 16-bit count.
  $8C4F,7 Twenty times 65536 turns of 26 T-states: about ten seconds (9.8 s from here to the title, measured in the simulator), with interrupts off because the death happened inside FRAME_TICK.

@ $9641 label=DRAW_SUMMARY
c $9641 Print the three end-of-game figures
D $9641 Three labels and three numbers, stacked at the left of the cleared play area. The labels carry their own colour in their first byte and their own punctuation: the one for the clock ends with the font's colon glyph, so TIME's digits print either side of a colon that was drawn with the word.
D $9641 It assumes the text font is already selected, which is why GAME_OVER repoints $5E01 before calling. Halfway through it switches to the digit-biased copy for the numbers.
D $9641 The third line is a percent sign -- "$" in this font -- and the rooms-explored figure: the share of the castle seen.
  $9641,3 Work out the proportion of the castle seen before printing it.
  $9644,9 "TIME", with the colon.
  $965F,6 From here on the numbers, so bias the tile source to the digits.
  $9665,6 The clock, then the score.
  $9671,3 And the rooms-explored figure.
  $9674,8 One byte, two digits.

# --------------------------------------------------------------------------
# The scroll, and the title screen's pictures
# --------------------------------------------------------------------------

@ $A17D label=UI_RECORD
s $A17D A spare record for drawing things that are not actors
D $A17D Eight bytes of scratch. The sprite routines only know how to draw from a record, so anything that has to appear without being a creature -- the lives on the scroll, the pictures on the title screen -- is written in here first and drawn from here.
D $A17D That it is eight bytes and not sixteen is the useful part. A monster's record is sixteen, but only its first eight describe the thing itself: sprite, room, a flag, x, y, drawing mode. Each half of a door or furniture record is eight bytes too. So the short form is the common one, and an actor is that plus another eight for how it moves and what it has in the air.

@ $A2CE label=DRAW_LIVES
c $A2CE Draw the remaining lives on the scroll
D $A2CE Draws up to three small figures at the foot of the panel, sixteen pixels apart, in whichever character the player chose. The count comes from $5E21, and the loop always runs three times: the slots past the count are drawn over rather than skipped, so a life that has just been lost is erased.
D $A2CE The sprite is worked out from the menu selection rather than stored. $5E00 holds the character in bits 3 and 4, so shifting it up one and masking to $30 gives $00, $10 or $20, and setting bit 0 makes it $01, $11 or $21 -- the first sprite of the knight, the wizard and the serf. Checked by starting a game as each: $5E00 reads $00, $08 and $10 and the player's own sprite byte comes out $08, $18 and $28, seven along from those bases.
  $A2D0,4 Not an actor, so borrow UI_RECORD to draw from.
  $A2D4,8 Turn the menu selection into the chosen character's first sprite.
  $A2DC,3 Bright white.
  $A2E3,3 The foot of the scroll: x = 200, y = 141.
  $A2E6,6 The record wants x then y, and HL holds them the other way round.
  $A2EC,6 Lives remaining, but three slots regardless.
  $A2FD,8 Sixteen pixels along for the next one.
  $A306,4 Once the count runs out it stays at zero, and the rest are blanks.

@ $A311 label=DRAW_TITLE_ICONS
c $A311 Draw the nine pictures on the title screen
D $A311 Works through TITLE_ICONS, copying each eight-byte record into UI_RECORD and drawing it. Nine records, but only six pictures: the three control methods are each too wide for one sprite and are drawn as two halves side by side, while the three characters below are one sprite each.
  $A311,4 Everything is drawn from the same scratch record...
  $A315,5 ...one copy of it at a time.
  $A31B,8 Eight bytes: the whole record.
  $A325,6 Put it on the screen, then its colours.

; span $A331,72
@ $A331 label=TITLE_ICONS
b $A331 The nine pictures on the title screen
D $A331 Nine records of eight bytes, in the ordinary short form -- sprite, room, flag, x, y, drawing mode. Read out of the game: sprites $48 and $49 make the keyboard at the top, $4A and $4B the joystick, $32 and $33 the cursor keys, and then $01, $11 and $21 draw the knight, the wizard and the serf down the left, at the very sprite numbers DRAW_LIVES computes from the menu selection.

# --------------------------------------------------------------------------
# Life force
# --------------------------------------------------------------------------

@ $8C2D label=FOOD_RECORD
s $8C2D A second scratch record, for redrawing the food
D $8C2D The disassembler calls this unused because nothing reaches it as code and nothing loads it as data through an obvious address. It is neither: DRAW_FOOD puts it in IX and draws from it, and writes a screen address into its +$03 and +$04.

@ $8A15 label=LOSE_FOOD_SIXTEEN
c $8A15 Take sixteen off the life force
D $8A15 The heavier of the two penalties. If it would go below zero the stack is dropped and control goes straight to the death routine, so the caller never returns.
D $8A15 Only the humpback calls it, on every pass it touches the player. Landing on exactly zero is not caught here -- only a borrow is -- and the next drain in PLAYER_TICK then turns the zero into 255 (measured in the simulator, 2026-09-27).
  $8A15,5 Sixteen, against the eight LOSE_FOOD_EIGHT takes.

@ $8A1E label=LOSE_FOOD_EIGHT
c $8A1E Take eight off the life force
D $8A1E What touching one of the four big hunters costs -- the mummy, Dracula, Frankenstein's monster and the devil call it on every pass they touch the player. Both penalties share the tail: store the new level, redraw the indicator, and on underflow die instead. As with LOSE_FOOD_SIXTEEN, a result of exactly zero is stored and the player lives, until the next drain wraps it to 255.
R $8A1E A The new level
  $8A1E,5 Eight.
  $8A25,6 Store it, then redraw the roast on the scroll.

@ $8B8A label=DRAW_FOOD
c $8B8A Redraw the roast on the scroll
D $8B8A The life force in $5E28 is drawn as the roast down the right-hand side, eaten away as it falls. $5E29 remembers the level the picture was last drawn at, and both are shifted right three times before being compared, so nothing happens until a whole eighth of the roast has gone -- most calls return at the third instruction.
D $8B8A It does not have its own copy of the picture. It reaches into the sprite tables, moves the roast's entry at #R$A626 forward by however many rows have been eaten and shortens the height bytes of GFX_B5 and GFX_B4, the second byte of each, to match, draws, and then puts all three back from the stack. The tables are only wrong for the few hundred T-states it takes to draw.
D $8B8A Watched live: at rest #R$A626 holds #R$C48C and GFX_B5's height byte holds $1E, and breaking just before the restore catches #R$A626 reading $C522 and then $C51C as the roast goes down -- the same entry, advanced past the rows that have been eaten.
R $8B8A None; it reads the level out of $5E28
  $8B8A,9 The level, in eighths.
  $8B94,10 What was drawn last time, also in eighths.
  $8B9E,2 The same, so the picture is still right.
  $8BA0,8 Keep the roast's real height to put back afterwards.
  $8BAA,4 Not an actor, so borrow FOOD_RECORD.
  $8BBD,6 The roast's entry in the sprite pointer table.
  $8BC3,3 Moved past the eaten rows, and put back before returning.

# --------------------------------------------------------------------------
# Objects lying in rooms
# --------------------------------------------------------------------------

@ $8C63 label=EAT_FOOD
c $8C63 The handler for a piece of food
D $8C63 Sprites $50 to $57 are food, and ACTOR_HANDLERS sends all eight of them here. Every frame it asks whether the player is standing on it; if not, it just draws itself and that is the whole of its behaviour.
D $8C63 Eating is worth $40 -- a quarter of the bar -- and the total is held at $F0 rather than being allowed to wrap, so arriving at a roast with almost full health wastes most of it. The two branches before the cap catch the carry as well as the compare, because $5E28 plus $40 can pass $FF.
R $8C63 IX The food
  $8C63,6 Is the player on it?
  $8C69,5 No -- draw it and do nothing else.
  $8C6E,7 Rub it out and free its slot. REGROW_FOOD fills the slot again, much later, while the player is elsewhere.
  $8C75,3 A noise.
  $8C78,6 Sixty-four units of life force.
  $8C7E,6 Cap it, catching both the carry and the limit...
  $8C84,2 ...at $F0, just short of a full bar.
  $8C86,3 Store it and redraw the roast on the scroll.

@ $95A9 label=DROP_GRAVESTONE
c $95A9 Leave an object where the player is standing
D $95A9 Four slots of eight bytes at $EAE8. The first with a zero sprite is taken, given sprite $8F, and the seven bytes after it are copied straight out of the player's own record -- room, flag, position and all -- so the thing appears exactly where the player is. With all four in use the routine simply returns and nothing is dropped.
D $95A9 The copy is what makes it cheap: because an object and an actor share the same eight-byte header, placing one is one LDIR rather than half a dozen assignments.
  $95A9,8 Four slots, eight bytes apart.
  $95B1,4 A zero sprite means the slot is free.
  $95B5,4 All four taken, so give up.
  $95BF,2 The sprite the dropped thing is drawn as.
  $95C3,8 Room, flag and position, straight from the player's record.

@ $8C8C label=FLASH_SCORE
c $8C8C Flash the score line while a countdown runs
D $8C8C Counts $5E3C down and, while it lasts, sets bit 7 of the six attribute cells the score sits in -- the flash bit, so the ULA does the work and nothing has to be redrawn. A beep every sixteenth step goes with it. It runs at the start of every life: PLACE_PLAYER sets the count to 104 and MATERIALISING calls this instead of rising until it runs out.
  $8C8C,4 The countdown.
  $8C92,5 A beep once every sixteen.
  $8C97,6 The attributes under the score, not the pixels.
  $8C9F,4 Bit 7 is FLASH; the hardware alternates ink and paper from there on.

# --------------------------------------------------------------------------
# Dying and coming back
# --------------------------------------------------------------------------

@ $8EA0 label=LOSE_LIFE
c $8EA0 Take a life and start the player sinking
D $8EA0 The single way out of the game. Both food penalties and the steady drain arrive here when the life force reaches zero, and with no lives left it goes straight to GAME_OVER.
D $8EA0 Otherwise the player is not moved or hidden -- their sprite is changed to $67, which ACTOR_HANDLERS sends to DYING, and the character they were is put in +$07 for MATERIALISING to restore. Nothing else has to know a death has happened; the sprite byte carries the whole state.
D $8EA0 Watched live by starving the player: lives went 3 to 2, the sprite went $08 to $67 to $66, the life force came back as $F0, and a gravestone appeared in the first of the four drop slots at the exact spot the player fell.
  $8EA0,4 No lives left...
  $8EA4,3 ...so that is the end of the game.
  $8EA7,4 Otherwise pay one.
  $8EAB,8 Was the thing that died a player at all? Sprites $01 to $30 are.
  $8EB6,3 Remember what to come back as.
  $8EC0,5 $67 -- the sinking animation, which the dispatcher will find on the next pass.
  $8EC6,12 The player's own handler found the zero: put the player back where this frame began, from the workspace. When something else took the last unit, the player stays where he is.

@ $8ED7 label=LOSE_FOOD_THIRTY_TWO
c $8ED7 Take thirty-two off the life force
D $8ED7 The heaviest of the three penalties, and the one MOVE_ACTOR's hit path uses. Unlike the other two this one clamps to zero rather than underflowing, then dies anyway -- the roast is redrawn empty before the life is taken, so the bar is seen to run out.
  $8ED7,5 Thirty-two, against sixteen and eight elsewhere.
  $8EDC,5 Exactly zero, or past it: either way the player is dead.
  $8EE1,6 Show the empty bar first, then lose the life.

@ $8D45 label=DYING
c $8D45 Sink the player into the floor
D $8D45 The handler for sprite $67. On three frames in four it counts +$06 down and redraws the sprite that many rows shorter, so the character sinks; on the fourth it only changes colour. (Measured: 19 steps in 25 frames for the knight.) When the count passes zero it leaves a gravestone where the body was and hands over to #R$9443.
  $8D45,5 One frame in four: colour only.
  $8D4C,6 Down a little further, until it goes negative.
  $8D5B,6 Leave something behind, then carry on.

@ $8CB7 label=MATERIALISING
c $8CB7 Raise the player back out of the floor
D $8CB7 The handler for sprite $66, and the mirror of DYING: +$06 counts up instead of down and the sprite rises. It is what runs at the start of a game as well as after a death, which is why the player's sprite byte reads $66 for several seconds before a new game is really under way -- and why CHECK_HIT, which only counts sprites below $31 as a player, cannot register a hit during it.
  $8CB7,4 For the first 104 frames of a life the score flashes instead (FLASH_COUNT, set by PLACE_PLAYER).
  $8CBD,5 One step in four frames.
  $8CC5,3 Up a little further.
  $8CCF,5 At the top, so become a player again.

@ $8D32 label=FINISH_MATERIALISING
c $8D32 Turn back into the character and clear the animation
D $8D32 +$07 has been carrying the character's sprite since LOSE_LIFE put it there. Restoring it is all it takes to be alive again: the dispatcher will send the next frame to UPDATE_KNIGHT, and CHECK_HIT will start counting the player as hittable.
  $8D32,6 Back to the knight, the wizard or the serf.
  $8D38,12 Clear the counter, the saved sprite and the offset.

# --------------------------------------------------------------------------
# What the sprites depict
#
# These `; sprite` lines are read by scripts/build_aticatac.py to title the
# sections of the generated sprite catalogue. They are kept separate from the
# routine labels because the two do not line up: one handler often drives
# several creatures (MOVE_ACTOR is both the pumpkin and the spider), and one
# run of codes can hold more than one picture (the keyboard and the joystick
# share a handler and sit next to each other).
# --------------------------------------------------------------------------

; sprite $01-$10 The knight
; sprite $11-$20 The wizard
; sprite $21-$30 The serf
; sprite $32-$33 Cursor keys icon, in two halves

# Runs that are one picture cut into pieces rather than frames of an
# animation. A sprite is only ever sixteen pixels wide, so anything wider
# is drawn as two side by side; showing them as an animation flicks
# between the halves of one icon.
; joined $32-$33
; joined $48-$49
; joined $4A-$4B

; sprite $6C-$6F Burst, expanding
; sprite $34-$37 Spell, thrown by the wizard
; sprite $38-$3F Sword, spinning, thrown by the serf
; sprite $40-$47 Axe, spinning, thrown by the knight
; sprite $48-$49 Keyboard icon, in two halves
; sprite $4A-$4B Joystick icon, in two halves
; sprite $4C-$4D Pumpkin
; sprite $4E-$4F Bat
; sprite $50-$57 Food
; sprite $58-$5B Monster, spawning
; sprite $5C-$5D Spider
; sprite $5E-$5F Spiky creature, hops
; sprite $60-$61 Small face with two eyes
; sprite $62-$63 Ghost
; sprite $68-$69 Ghost, a second kind
; sprite $6A-$6B Bat, a second kind
; sprite $70-$73 Mummy
; sprite $74-$77 Frankenstein's monster
; sprite $78-$7B Devil
; sprite $7C-$7F Dracula
; sprite $80-$8E Collectables: keys, and the objects that kill the mummy, Dracula, the devil and Frankenstein's monster
; sprite $8F Gravestone, left where the player died
; sprite $90-$93 Witch
; sprite $98-$9B Bat, a third kind
; sprite $9C-$9F Humpback
# $AE-$B1, $B2, $B9 and $BC were named here as doors. They are not: drawn at
# their real size they are a cave door, a grandfather clock, a framed picture,
# a trapdoor and a rug. The mistake came of reading them in the sprite format,
# nine bytes instead of a hundred and thirty, and naming the fragment. The
# names further down are pobtastic's and are what the pictures actually show.
; sprite $A1 Mushroom, which drains the player's life force

@ $807A label=INERT_SPRITE
c $807A A sprite that does nothing at all
D $807A The handler for everything that is drawn but never acts -- the three control-method pictures on the title screen among them. It checks whether IX is one of the first three monster records and, if it is, burns a couple of hundred cycles doing nothing; otherwise it returns at once.
D $807A The delay looks pointless but is not: those three slots are drawn every frame whatever occupies them, and an inert occupant that returned instantly would make the frame shorter than one holding a creature. Spending the time keeps the pace even.
  $807A,6 IX, as a number, against the base of the monster table.
  $8080,6 Not in the table at all -- nothing to do.
  $8086,4 Only the first three slots get the delay.
  $808A,3 192, counted down and thrown away.
  $808D,5 The delay itself.

@ $82F1 label=AIM_SWORD
c $82F1 Aim the serf's sword the way it flies
D $82F1 Sprites $38 to $3F are one sword drawn at eight angles, a compass point apart. This does not cycle them: SIGN_TO_DIRECTION picks the one that matches the signs of the weapon's velocity, so the sword points where it is going and turns only when it bounces. (The axe, SPIN_AXE, is the one that spins.)
D $82F1 This is the serf's weapon. Each character throws its own: firing as each in turn and reading the type out of the player record's upper half gives $3E for the serf, $41 to $47 for the knight's axe and $36 for the wizard's spell.

@ $81DB label=SPIN_AXE
c $81DB Drive the spinning axe
D $81DB The axe's equivalent of AIM_SWORD, over sprites $40 to $47 -- again eight frames, one per compass point. It is the knight's weapon.

@ $862E label=MOVE_BAT
c $862E Drive a bat
D $862E Sprites $4E and $4F. A second kind of bat, sprites $6A and $6B, is driven by MOVE_ARCS instead; the two look alike but are not the same creature and do not share a routine.

@ $8301 label=MOVE_ARCS
c $8301 Drive the second bat, which flies in arcs
D $8301 Sprites $6A and $6B, the second kind of bat. Every sixteen passes it picks a random direction from R into +$08, and in between takes its steps from STEP_VECTORS in order through ARC_STEP -- sixteen steps that swing from horizontal to vertical, the axes swapped by bit 2 of +$08 -- so it flies in arcs, bouncing off the walls.

@ $87A6 label=MOVE_GHOST
c $87A6 Drive a ghost
D $87A6 Sprites $62 and $63. As with the bats there is a second ghost, sprites $68 and $69, with its own routine in MOVE_HOPPER.

@ $8672 label=MOVE_HOPPER
c $8672 Drive the hoppers: the spiky creature and the second ghost
D $8672 Drives two runs of codes, $5E-$5F (a spiky creature) and $68-$69 (the second ghost). A counter in +$0A climbs from -7 to 7 and, halved, is the vertical velocity; each time it tops out it is reset and RANDOM_VELOCITY picks a new direction, so these creatures hop.

@ $8862 label=MOVE_MUMMY
c $8862 Drive the mummy
D $8862 Sprites $70 to $73 -- four frames rather than the two most creatures get. PLACE_KEYS puts the mummy in the red key's room. If object $80 (MUMMY_LURE) is in its room it walks to it and, on reaching it, sends it to room $6B. Otherwise, while the red key is in its room, it walks back and forth between two points; once the key has gone it sets bit 7 of +$06 and hunts the player for the rest of the game. Touching costs eight a pass.

@ $8988 label=MOVE_FRANKENSTEIN
c $8988 Drive Frankenstein's monster
D $8988 Sprites $74 to $77, four frames. Hunts the player. Touched while the player carries the cyan spanner ($8B), it is killed: 1000 points, then KILL_MONSTER's 155, and its slot is never refilled (measured in the simulator: +1155). Otherwise its touch costs eight units of life force a pass, through LOSE_FOOD_EIGHT.

@ $89ED label=MOVE_DEVIL
c $89ED Drive the devil
D $89ED Sprites $78 to $7B. Hunts the player; its touch costs eight units a pass through LOSE_FOOD_EIGHT, and nothing in the code stops it.

@ $8906 label=MOVE_DRACULA
c $8906 Drive Dracula
D $8906 Sprites $7C to $7F, four frames. Touch: eight a pass. While the player carries the yellow crucifix ($8A) he runs from the player. In the player's room he hunts. Elsewhere, on a pass that falls in the frame when FRAMES is 0, he picks a random room 0-127 and moves there if its shape is $00-$02 and it is not the player's: he wanders the castle unseen. (His off-screen HOME_IN is given the crucifix test's DE rather than the centre he has just stored in +$0B and +$0C; harmless, since he is not drawn.)

@ $8A2F label=MOVE_WITCH
c $8A2F Drive the witch
D $8A2F Sprites $90 to $93. The countdown at +$0D and the arithmetic shift of +$09 give her flight its rise and fall: SRA halves the vertical speed while keeping its sign, so she coasts upward, slows and drops rather than moving at a constant rate.

@ $95D7 label=GRAVESTONE
c $95D7 The gravestone left where the player died
D $95D7 Sprite $8F, and nothing more than a jump into the routine that draws a thing and leaves it alone. DROP_GRAVESTONE is what puts one down: on dying, seven bytes of the player's record are copied into a free slot and given this sprite, so the stone stands exactly where the body fell.
D $95D7 Confirmed live by starving the player -- the first of the four slots came back holding sprite $8F at the player's own position.

@ $8AFF label=MOVE_HUMPBACK
c $8AFF Drive the humpback
D $8AFF Sprites $9C to $9F. If one of the eight collectables at $EB18 is in its room (SCAN_COLLECTABLES) it walks to it and takes it -- the record is emptied, so the object is gone for the game; otherwise it stands still. Its touch costs sixteen a pass (LOSE_FOOD_SIXTEEN). While the player is not in play it walks to the top of the room. MOVE_ACTOR's exemption mask singles it out: masking with $FC and comparing against $9C matches all four of its frames.

@ $8A80 label=MOVE_FACING_FLYER
c $8A80 Drive the cloaked figure and the third bat, facing the way they fly
D $8A80 Covers sprites $94 to $9B, two creatures of four codes each: $94-$97 a cloaked figure, $98-$9B the third kind of bat. Every 32 passes a random velocity, x from bit 2 of FRAMES and y halved; the picture faces left or right by the sign of +$08 and flaps between two frames. MOVE_WITCH is the same with a period of 16.

@ $85F7 label=SPAWN_MONSTER
c $85F7 The sprite a monster arrives as
D $85F7 Sprites $58 to $5B, four frames of a monster appearing. Nothing wanders in from another room: a creature is spawned into the one the player is in, and this is what is drawn while it does.

@ $871A label=MOVE_FACE
c $871A Drive the small face at $60-$61
D $871A Two frames of a small face with two eyes, nine pixels tall, whose sides pull in and stretch out again -- eleven pixels wide in the first frame and fifteen in the second. A new random velocity every 17 passes, bouncing off the walls.

@ $81F0 label=SPIN_SPELL
c $81F0 Drive the wizard's spell
D $81F0 Sprites $34 to $37, and the odd one of the three weapons: where the sword and the axe are solid shapes redrawn at eight angles, this is a scatter of loose pixels that changes shape rather than turning, which is what makes it read as magic rather than as a thrown object. Two of its four frames are identical.
D $81F0 Confirmed by firing as each character and reading the weapon type out of the player record: the wizard's shots come back as $36, inside this range, while the knight's are $41-$47 and the serf's $3E.

# --------------------------------------------------------------------------
# Where a sprite's graphics live
# --------------------------------------------------------------------------

@ $9E89 label=SPRITE_ADDRESS
c $9E89 Find a sprite's graphics
D $9E89 Sprite numbers are 1-based, so one is taken off before doubling into SPRITE_TABLE. This is the lookup the general drawing path uses, and it is the one that covers every sprite in the game -- the catalogue of pictures is built by driving this path, which is why it can draw codes right across the range.
R $9E89 A The sprite number
R $9E89 DE On exit, that sprite's graphics
  $9E89,5 Numbered from 1, two bytes an entry.
  $9E8E,4 The table.
  $9E92,3 The address it holds.

; span $A4BE,478
@ $A4BE label=SPRITE_TABLE
b $A4BE The address of every sprite's graphics
D $A4BE 239 addresses, two bytes each, indexed by sprite number less one, running from #R$A4BE up to the graphics. The graphics themselves start immediately after it.
D $A4BE It is three tables end to end, which is why the count is 239. The first 161 entries, up to FURNITURE_SPRITES, are the creatures and objects -- two bytes wide, one byte of row count. The next 39, from #R$A600, are the pieces the rooms are furnished with, which carry a width as well. The last 39, from #R$A64E, are not pictures at all: they are those same pieces' attribute tables, one colour per character cell in the same width-and-height format.
D $A4BE Entry N of the third table belongs to entry N of the second, which is how one picture serves four doors: $A9 to $AC all point at the graphic at #R$A69C and differ only in their colours -- $43 $42 for red, $44 green, $45 cyan, $46 yellow. The three bases the code uses, #R$A4BE, #R$A600 and #R$A64E, are not a bias trick after all; they are simply where each table starts.
D $A4BE The count is measured rather than assumed: every code was drawn on a machine of its own with its reads logged, and 239 is the highest whose entry points at something the drawing code can read. Entries beyond that hold values like $1804 and $33F8, which are not addresses in this game at all.
D $A4BE FETCH_SPRITE and FETCH_SPRITE_ATTRS were read here as biased views of a single table, on the grounds that #R$A600 is its 161st entry and #R$A64E its 200th. That is arithmetically true and the wrong way round: they are separate tables, and the arithmetic works because they follow each other.

# --------------------------------------------------------------------------
# Drawing a sprite at any x
# --------------------------------------------------------------------------

@ $9F9F label=SETUP_SPRITE_DRAW
c $9F9F Work out where a sprite goes, and how far to shift it
D $9F9F Sprites in this family are two bytes wide in the data and land on the screen straddling two or three, because x is a pixel position and not a character column. Rather than keep eight pre-shifted copies of every sprite, the game shifts at draw time -- and rather than loop, it computes where to jump into an unrolled chain of shifts and writes that into the jump itself.
D $9F9F The displacement is 2 * ((x - 1) AND 7), which SHIFT_AND_PLOT's JR turns into "skip this many bytes of the chain". More shifts for a small offset, fewer for a large one. The one case that would need none is redirected to a plot routine that does not shift at all.
R $9F9F IX The thing being drawn
  $9F9F,3 Its graphics, through SPRITE_TABLE.
  $9FA2,6 Its position.
  $9FA8,5 The low three bits of x, doubled: how far into the shift chain to start.
  $9FAD,4 A shift of none is a special case...
  $9FB1,2 ...redirected right out of the chain to a plot with no shifting at all.
  $9FB3,3 Write it into the JR at #R$9F29.
  $9FB6,5 Two bytes of sprite cover three columns unless it lands square.
  $9FBB,3 How wide to erase and redraw.
  $9FC1,7 The first byte of a sprite's data is its height in rows.

@ $9F21 label=SHIFT_AND_PLOT
c $9F21 Shift one row of a sprite into place and draw it
D $9F21 Reads two bytes of the row into HL and then jumps into the chain below at whatever depth SETUP_SPRITE_DRAW patched in. Each step there is ADD HL,HL with ADC A,A behind it, so the pair behaves as a 17-bit shift left: the bit falling off HL is caught in A, which becomes the third byte on screen.
  $9F21,2 The row.
  $9F23,4 Two bytes of it, and step past them.
  $9F27,2 A starts empty and collects the bits pushed out of HL.
  $9F29,2 Reads as a jump to itself; by the time it runs the displacement has been overwritten, and it lands part-way down the chain.

@ $9F2B label=SHIFT_CHAIN
c $9F2B Seven shifts, entered part-way down
D $9F2B Not a loop: seven copies of the same two instructions, one after another, so that jumping in n pairs from the top performs 7 - n shifts with no counter and no branch. The whole cost of positioning a sprite to the pixel is one patched jump.
  $9F2B,14 Seven ADD HL,HL / ADC A,A pairs. Entering at the top shifts seven times, two bytes in six, and so on.
  $9F39,5 Whatever the shift, the row ends up here to be XORed onto the screen.

# --------------------------------------------------------------------------
# Sound effects played directly
# --------------------------------------------------------------------------

@ $A3C7 label=SOUND_FOOTSTEP
c $A3C7 The footstep, two tones alternating
D $A3C7 Called every frame by all three characters' handlers -- UPDATE_KNIGHT, UPDATE_WIZARD and UPDATE_SERF -- so walking sounds the same whoever is doing it. A counter at $5E2F advances on every call and its bottom two bits do all the work: bit 0 decides whether to make a sound at all, so only every other call does, and bit 1 chooses which of two notes.
D $A3C7 The two are four cycles each, of half-period $60 and $40 -- which measure at about 1360 Hz and 2005 Hz. They alternate, so a walking character produces low, high, low, high rather than one repeated click. That is the whole footstep: two tones and a counter.
R $A3C7 None; it reads and advances $5E2F itself
  $A3C7,5 The step counter, advanced on every call.
  $A3CC,4 Bit 1 picks the note.
  $A3D0,3 Bit 0 silences every other call, which is what sets the pace.
  $A3D3,5 The higher of the two, about 2005 Hz.
  $A3D8,3 The same gate on the other branch.
  $A3DB,5 The lower, about 1360 Hz.

@ $A3E0 label=SOUND_LIFE_PIP
c $A3E0 The pip that goes with the flashing score at the start of a life
D $A3E0 One call from FLASH_SCORE, once every sixteen steps of its 104-frame countdown. B is half-period $80 and C is 96 cycles of it, which measures as 96 milliseconds at about 1030 Hz: a clear steady pip rather than a sweep.

@ $A427 label=SOUND_SWEEP_UP
c $A427 A rising sweep
D $A427 Sixteen calls to BEEP with the pitch walked from one end to the other, so the note climbs. Measured at roughly 16 milliseconds, sweeping from about 500 Hz upwards. Reached from the serf's handler by way of #R$8283.
  $A427,2 Sixteen steps.
  $A429,7 The pitch for this step, derived from the step number.
  $A431,3 One short note.

@ $A438 label=SOUND_SWEEP_DOWN
c $A438 A short falling sweep
D $A438 Eight steps rather than sixteen, and the pitch complemented so it falls where SOUND_SWEEP_UP rises. About 14 milliseconds, and barely moving -- 520 to 556 Hz -- so it lands as a blip rather than a slide.
  $A438,2 Eight steps.
  $A43A,3 Complemented, so the pitch falls.
  $A43E,3 One short note.

@ $A445 label=SOUND_WEAPON_GONE
c $A445 The sound of a weapon's flight ending, or a burst ending
D $A445 Called from WEAPON_GONE in SPIN_WEAPON, which all three weapons share, and so also at the end of every burst (COUNTDOWN_ACTOR jumps there). It takes its starting pitch from $5E25, the count of creatures in the room, so it does not sound quite the same twice. Measured at about 6 milliseconds across 1900 to 3700 Hz.

@ $A46E label=SOUND_NOISE_BURST
c $A46E A short burst of noise
D $A46E Run from a cold machine it lasts about 8 milliseconds and puts out 119 speaker edges with the gaps between them swinging wildly -- 843 Hz at the widest and far above hearing at the narrowest. That is not a note; it is a rasp.
D $A46E Reached by JP from TOGGLE_TIMED_DOOR (a timed door slamming or opening) and from the tail of TRAPDOOR_CLOSED (a trapdoor opening or closing), so it returns to whoever called those. Its noise is the ROM: eight bits of each of 48 bytes from address 0 go to the speaker. An earlier note put the caller at #R$917D, which was wrong -- that is the timed door's handler, two calls away.
D $A46E An earlier note here claimed this was a full second of sound sweeping the audible range, which was wrong. The measurement behind it came from running several sound routines in turn on one machine, so this one inherited the state the others left and took a longer path than it ever does in the game.

# --------------------------------------------------------------------------
# Collectables
# --------------------------------------------------------------------------

c $92F5 The handler for a collectable
D $92F5 The playthroughs that build the code map never reach this, so the automatic pass leaves it as data. It is not: the bytes decode cleanly as code from the first byte, and forcing it here costs nothing -- the round-trip check still reassembles the whole game byte for byte, which it could not do if the split were wrong.

@ $92F5 label=PICK_UP
c $92F5 Pick a collectable up
D $92F5 The handler for sprites $80 to $8E -- the keys and the objects that kill the four big monsters. Like the food it does nothing but wait: every frame it asks whether the player is standing on it, and only then acts.
D $92F5 Picking something up is not free. The player can hold three things, and taking a fourth pushes the oldest out, so the three calls at the end run in the order they have to: DROP_CARRIED first, while the item about to be lost can still be read, then SHIFT_CARRIED to make room, then REMEMBER_CARRIED to put the new one at the front.
R $92F5 IX The collectable
  $92F5,3 Position and sprite into the workspace.
  $92F8,13 Two gates before anything else is considered.
  $9305,6 And the player has to actually be in play, the same $01-$30 test CHECK_HIT makes.
  $930D,5 Standing on it?
  $9312,8 Mark this press of the pick-up key as used (bit 1), and a pick-up as done this pass (bit 0), so PUT_DOWN does not act on the same press.
  $931A,3 Put the oldest of the three back into the world...
  $931D,3 ...shift the other two along...
  $9320,3 ...and record the new one at the front.

@ $9326 label=REMEMBER_CARRIED
c $9326 Record what has just been picked up
D $9326 Writes four bytes into the first slot at $5E30: the address of the object's own record, then its sprite and its drawing mode. Keeping the address rather than a copy is what lets DROP_CARRIED put the thing back exactly as it was.

@ $934C label=SHIFT_CARRIED
c $934C Move the carried items along one slot
D $934C Three slots of four bytes at $5E30, $5E34 and $5E38. LDDR copies the eight bytes at $5E30 up to $5E34, so the newest slot is freed and whatever was in the third is overwritten -- which is why DROP_CARRIED has to run first.

@ $9358 label=DROP_CARRIED
c $9358 Put the oldest carried thing back in the room
D $9358 Reads the third slot at $5E38 and returns at once if it is empty, so nothing happens until the player is already carrying three. Otherwise it builds a record where the player is standing -- the sprite it had, the player's room from $EA91, then $80, then the player's x and y from $EA93 and $EA94 -- so a dropped object lands at your feet and can be picked straight back up.
  $9358,7 The slot about to be lost.
  $9361,2 Nothing there: the player is not carrying three yet.

# --------------------------------------------------------------------------
# Routines the code map never reached
#
# Each of these is the target of an entry in ACTOR_HANDLERS or one of the two
# sprite-drawer tables, so it is certainly code; the playthroughs that build
# the map simply never took the path that runs it. Left alone, the automatic
# pass renders them as DEFBs. Forcing them costs nothing and is checked: if
# any one of them were not code, the round-trip would stop reassembling the
# game byte for byte.
# --------------------------------------------------------------------------

c $91BC
c $9252
c $9421
c $988B
c $99E5
c $9AEF
c $9D47
c $9DF8

@ $988B label=MUSHROOM
c $988B The mushroom that drains you
D $988B Sprite $A1. Standing on it is not fatal at once -- it takes a unit of life force per pass and loops, so the drain continues for as long as the player stays on it and stops the moment they step off. Reaching zero there kills as surely as anything else.
D $988B When nobody is on it, it cycles its colour rather than its shape: the low two bits of a counter index four attribute bytes at #R$98C4, and only the drawing mode in +$05 changes. The sprite itself never moves.
R $988B IX The mushroom
  $988B,6 Is the player standing on it?
  $9891,2 Yes -- start draining.
  $9893,11 Otherwise advance the colour, every fourth frame.
  $989E,11 Four colours, cycled by the low two bits.
  $98AB,6 Only the drawing mode changes; the shape is the same every time.

; span $98B1,19
c $98B1 Drain a unit of life force and go round again
  $98B1,7 A unit of life force, every pass round the loop.
  $98B8,3 It has run out: die.
  $98BB,6 Otherwise redraw the roast and make a noise about it...
  $98C1,3 ...and go round again while the player is still on it.

; span $98C4,4
b $98C4 The mushroom's four colours
D $98C4 Indexed by the low two bits of its counter, and written straight into +$05 as the drawing mode.

c $98C8

# --------------------------------------------------------------------------
# Doors only one character can use
# --------------------------------------------------------------------------

@ $9421 label=DOOR_SERF
c $9421 A door the serf can use
D $9421 Three doors, three entry points, one test. Each subtracts a character's first sprite from the player's current one and asks whether what is left is under $10 -- which is exactly "is the player this character", since each character owns sixteen consecutive sprite codes. #R$9421 takes $21 for the serf, #R$9428 takes $11 for the wizard and #R$942F takes 1 for the knight. The records that reach them are types $1A (a barrel), $17 (a bookcase) and $10 (a grandfather clock), drawn as graphics $BB, $B8 and $B1 -- handler-table entries $BC, $B9 and $B2.
D $9421 Pass the test and the thing behaves as an ordinary door, through the same #R$91F2 that every other door goes through. Fail it and control goes to #R$91FE instead, which draws it and nothing more: the door is there, visible, and will not open.
R $9421 IX The door
  $9421,5 The serf's sprites start at $21.
  $9428,5 The wizard's at $11.
  $942F,4 The knight's at 1.
  $9433,4 Sixteen codes per character, so anything under $10 is a match.
  $9437,6 The right character: let them through.
  $943D,6 The wrong one: draw it and leave it shut.

# --------------------------------------------------------------------------
# Why there are eight ways to draw a sprite
# --------------------------------------------------------------------------

@ $9A92 label=REVERSE_BITS
c $9A92 Turn a byte back to front
D $9A92 Eight rotations: each one shifts a bit off the top of A into the carry and back into the bottom of C, so C ends up holding A's bits in the opposite order. That is a sprite byte mirrored, and mirroring every byte of a row while reading the row's bytes backwards mirrors the whole sprite.
D $9A92 It is what saves the game from storing anything twice. A creature facing left and the same creature facing right are one set of bytes and a different drawing routine.
R $9A92 A The byte
R $9A92 A On exit, the same bits in reverse
  $9A92,3 Eight bits to move.
  $9A95,5 Off the top of A, into the bottom of C.
  $9A9A,3 C now holds it reversed.

@ $9A9D label=NEXT_SPRITE_ROW
c $9A9D Step the sprite pointer on by one row
D $9A9D DE += B, where B is the width in bytes. The counterpart at #R$9AA5 subtracts instead, for the routines that read a sprite from the bottom up.

@ $99E5 label=BLIT_SPRITE_MIRRORED
c $99E5 Copy a sprite to the screen, back to front
D $99E5 BLIT_SPRITE with two changes: the row is walked with DEC DE rather than INC DE, and every byte goes through REVERSE_BITS on the way out. Between them those mirror the sprite horizontally without a second copy of the data.
D $99E5 It patches its own combining instruction the same way BLIT_SPRITE does -- #R$9D19 hands back an opcode and it is written over the NOP in the loop.
  $99E5,7 The combining opcode, into the loop below.
  $99EF,5 Start of a row.
  $99F4,5 Backwards through the row, reversing each byte.
  $99F9,1 Assembled at run time: NOP, OR, XOR or AND.

@ $9AEF label=BLIT_SPRITE_FLIPPED
c $9AEF Drawing mode 5: furniture turned a half turn (mirrored and upside down)
D $9AEF Mirrored like BLIT_SPRITE_MIRRORED, and turned over as well: the call to #R$9ABA moves the data pointer to the last row before anything is drawn, so the rows come out in the opposite order.
D $9AEF This is why there are eight drawing routines in each family rather than one. They are the eight symmetries of a rectangle -- the four ways to flip it (as stored, mirrored, upside down, both, which is a half turn) and the same four turned through a right angle -- and the top three bits of a door's or piece of furniture's +$05 pick between them.
  $9AEF,7 The combining opcode.
  $9AF9,3 Move to the last row: this one draws bottom to top.

# --------------------------------------------------------------------------
# Locked doors and the keys that open them
# --------------------------------------------------------------------------

@ $9273 label=FIND_CARRIED
c $9273 Is the player carrying this?
D $9273 Walks the three slots of the inventory looking for one that matches on both bytes: the sprite in E and the drawing mode -- which for a key is its colour -- in D. It starts at $5E32 rather than $5E30 because the first two bytes of a slot are the object's address; the sprite and the mode are the third and fourth, which is exactly what REMEMBER_CARRIED put there.
R $9273 E The sprite to look for
R $9273 D The colour it has to be
R $9273 F Zero flag set if it is being carried
  $9273,5 Three slots, four bytes each, starting at the sprite byte of the first.
  $9278,5 Wrong sprite: on to the next slot.
  $927D,3 Right sprite, right colour: found.
  $9280,5 Step over the rest of the slot.

@ $9222 label=DOOR_NEEDS_KEY
c $9222 Will this locked door open?
D $9222 The coloured doors. Each carries its colour in the low two bits of its own sprite, which index four attribute bytes at DOOR_COLOURS, and the door opens only if the player is carrying a key -- sprite $81 -- of that same colour.
D $9222 So the lock is not a flag anywhere. The door's colour is part of its sprite number, the key's colour is the drawing mode stored with it when it was picked up, and opening the door is a comparison of the two.
R $9222 IX The door
R $9222 F Carry set if it opens
  $9222,5 The low two bits of the sprite are the colour.
  $9227,6 Look it up.
  $922D,3 $81 is a key; D is the colour it has to be.
  $9230,6 Not carrying it: the door stays shut.
  $9236,6 Carrying it: behave as an ordinary doorway from here on.
  $923F,5 Draw it shut and report no.

; span $925C,4
@ $925C label=DOOR_COLOURS
b $925C The four door colours
D $925C Indexed by the low two bits of a door's sprite. The same four values are what a key carries as its drawing mode, so the comparison in FIND_CARRIED is between a door's colour and a key's colour with no translation in between.

@ $91BC label=TRAPDOOR_CLOSED
c $91BC A trapdoor, closed (type $18): it opens every 256 passes
D $91BC On a pass when TICKS' low byte is zero it swaps the picture: XOR the current one off (mode bits forced to XOR), flip bit 0 of the type -- $18 closed to $19 open -- XOR the new one on, restore the mode, draw the colours, and rasp. The open trapdoor's handler, TRAPDOOR, enters the same tail at #R$91CC to close again, when the byte RUNNING_SUM happens to be zero. An earlier reading, "what a thing being destroyed looks and sounds like", was wrong.
  $91BC,7 Only when TICKS' low byte is zero: every 256 passes.
  $91CC,9 XOR the current picture off.
  $91D8,11 The other state's picture -- the type's bit 0 flipped -- XORed on.
  $91E3,7 Put the mode back and draw the colours.
  $91EA,3 And the rasp.

# --------------------------------------------------------------------------
# The main loop
# --------------------------------------------------------------------------

@ $7DC3 label=MAIN_LOOP
c $7DC3 The loop the whole game runs in
D $7DC3 Everything the game does happens here. It walks two tables of records and the player's room's list, and hands each record to DISPATCH_ACTOR, which finds its handler from its sprite byte; there is no other structure above this. Monsters, doors, objects, the player and even the sound effects are all just records this loop reaches.
D $7DC3 The three are treated differently. From $EAA8 to $EE60 are eight-byte records -- objects, collectables, the drop controller -- and those are only dispatched if their room matches the player's. From $EE60 to $EEE0 are the sixteen-byte monster records, dispatched every pass whatever room they are in, which is how creatures keep moving around a castle you cannot see. The doors and furniture, sixteen-byte records from $EEE0 with a half in each of two rooms, are not walked at all: ROOM_LIST_PASS dispatches the ones the player's room's list names. On the first pass in a room the first two walks are skipped. Measured in the simulator, a pass in room $00 takes about 1.7 frames: a fifth of it this loop's own walk over the objects, with a FRAMES check between each, and a seventh INERT_SPRITE's delay in the three empty monster slots.
D $7DC3 Two details in the first three instructions are worth more than they look. The stack pointer is reset at the top of every pass, so no handler has to leave the stack as it found it -- which is what lets LOSE_FOOD_SIXTEEN abandon its caller and jump straight to the death routine. And the EI here is where the DI at the entry point is finally lifted: everything before this runs with interrupts off.
  $7DC3,3 Reset the stack every pass; handlers need not balance it.
  $7DC6,1 Interrupts on. This is where the DI at ENTRY is undone.
  $7DC7,4 Count of actors in the player's room, recounted each pass.
  $7DCB,4 The first table: objects and sounds, eight bytes each.
  $7DD6,4 Never used: on the first pass in a room the loop goes straight to the room list, which reloads IX.
  $7DE7,6 Only things in the player's room are dispatched from this one.
  $7DED,6 The return address goes in HL, and the dispatch is a jump rather than a call.
  $7DF3,5 Eight bytes to the next record.
  $7DF8,9 Until the monster table is reached.

@ $7E13 label=MAIN_LOOP_MONSTERS
c $7E13 The second pass: the monsters
D $7E13 Sixteen bytes a record rather than eight, and no room test -- every monster is dispatched every pass wherever it is. That is what keeps the castle alive behind the player rather than freezing rooms they have left.
  $7E13,5 Sixteen bytes to the next monster.
  $7E18,9 Until the door table is reached.

@ $7EB2 label=FRAME_TICK
c $7EB2 The work that happens once per frame
D $7EB2 MAIN_LOOP runs as fast as it can and calls this only when the ROM's frame counter has moved on, so what happens here is tied to the 50Hz interrupt rather than to how much there is to do.
D $7EB2 It dispatches three records the main loop deliberately skips -- $EA90, $EA98 and $EAA0, the player, the weapon it has in flight, and the sound effect slot -- and then ticks the clock. That is why the player moves at a steady speed however crowded a room is, while the monsters are dispatched on every pass of the outer loop.
D $7EB2 It runs with interrupts off, so a frame's work is never interrupted half way.
  $7EB2,1 Nothing may interrupt a frame's work.
  $7EB5,5 A flag saying a frame is in progress.
  $7EBA,4 The player, first of the three.
  $7EBE,4 Push the return address, then enter DISPATCH_ACTOR below its own PUSH HL -- it has already been done here.
  $7EC2,3 Dispatch.

@ $7EC5 label=FRAME_TICK_NEXT
c $7EC5 On to the next of the three, then the clock
D $7EC5 Eight bytes at a time from the player up to $EAA8, which is where MAIN_LOOP's own first table begins -- so between them the two loops cover every record exactly once, at two different rates.
  $7EC5,5 Eight bytes on.
  $7ECA,9 Until the main loop's first table is reached.
  $7ED5,3 Then advance the clock.

# --------------------------------------------------------------------------
# A door has two sides
# --------------------------------------------------------------------------

@ $9286 label=DOOR_OTHER_SIDE
c $9286 Swap IX to the far side of a door
D $9286 A door is two records, one for each room it joins, and they are deliberately put eight bytes apart so that the other side is found by flipping one bit of the address. No pointer, no table, no search: XOR the low byte with $08 and IX is looking at the other half.
D $9286 That pairing is why the door records read out of a running game sit at $EEE0 and $EEE8, $EEF0 and $EEF8. Each side carries the destination and arrival position for going that way, so walking through is a matter of reading the record you did not touch.
R $9286 IX A door; on exit, its other side
  $9286,3 IX into HL, where its low byte can be got at.
  $9289,4 One bit is the whole of it.
  $928D,3 And back into IX.

c $954D Open a door, both halves at once
D $954D Clear bit 3 of the drawing mode -- the bit that says a door is shut, which TEST_ROOM_BOXES reads to decide whether the doorway lets the player through -- and clear it on the far side too, so the two halves never disagree about whether the door is open. DOOR_NEEDS_KEY calls it when the player is carrying the right key, the character doors when the right character walks up, TIMED_DOOR_SHUT's toggle, and ACG_DOOR.
  $954D,8 Bit 3 off: open.
  $9555,5 Now the other side.
  $955A,8 The same there.

c $9565 Shut a door, both halves at once
D $9565 The opposite of the routine above: set bit 3 on both halves, so the door is drawn shut and stays that way. This is what runs when the key is missing or the wrong character is standing there -- the door is still drawn, it simply does not open.
  $9565,8 Bit 3 on: shut.
  $956D,5 And the far side.
  $9572,8 The same there.

# --------------------------------------------------------------------------
# What is in each room
# --------------------------------------------------------------------------

@ $902B label=TEST_ROOM_BOXES
c $902B Test one axis of the player's step against the room's doorways and tables
D $902B Called twice a frame from MOVE_PLAYER, through TEST_STEP_BOXES, with the proposed position in E and D and the bit for one axis in A' ($10 for x, $20 for y -- the bits of the player's +$02 that stop APPLY_HEADING moving that way). It walks the player's room's list of door and furniture halves, the same list MAIN_LOOP dispatches, and tests the point against each one's box.
D $902B The box is in +$06 (x) and +$07 (y) of the half: the high nibble, signed, times 4 is an offset from the record's own x or y, the low nibble times 4 a size; it runs right from x plus the offset and up from y plus the offset. Inside a box with +$05 bit 3 set -- a shut door -- nothing happens. Inside one with bit 2 set -- a table, the only solid furniture -- the bit is set: the step is refused. Inside any other -- a doorway -- the bit is cleared: the step is allowed although it leaves the room's walk rectangle. So an open door is a channel through the wall, a shut one is wall, and a table is an obstacle.
D $902B The lists hold template addresses (#R$600D onwards) plus #R$757D; taking #R$757D off gives the runtime address, as DISPATCH_FROM_LIST does. An earlier title, "Set up the records that belong to a room", described the walk but not the purpose: nothing is set up.
D $902B The check part-way down is the door pairing: if the half named in the list belongs to the other room, eight is added to reach the half in this one.
R $902B IX The player
R $902B DE The proposed position: E x, D y
R $902B A' The axis bit: $10 or $20
  $902B,5 The player's room.
  $9030,8 Two bytes per room, into the table.
  $9038,3 The start of this room's list.
  $903B,8 The next entry, and $0000 ends the list.
  $9044,7 Take the bias off to get the record's real address.
  $904B,4 Is this the half that belongs to the player's room?
  $904F,5 No -- the other half is eight bytes along.

; span $757D,300
@ $757D label=ROOM_CONTENTS
b $757D What is in each room
D $757D One pointer per room, 150 of them, each to a $0000-terminated list of the records that belong to that room. Read out of the game, room $00's list names $EEE0, $EEF0 and $EF00 -- which are exactly the door records found in the running game when the player starts there.
D $757D The lists themselves follow immediately, from #R$76A9 on. Their entries are addresses into the initial-state template at #R$600D rather than into the runtime tables, and subtracting #R$757D is exactly the relocation from one to the other. See TEST_ROOM_BOXES.

# --------------------------------------------------------------------------
# Firing, spawning, and steering
# --------------------------------------------------------------------------

@ $817C label=FIRE_WEAPON
c $817C Launch the player's weapon
D $817C Sets the weapon's velocity from the direction the player is facing: +4, -4 or nothing on each axis, taken from the sign of +$06 and +$07. A shot therefore travels four pixels a frame along whichever axes the player was moving on, and a diagonal shot moves on both.
D $817C Confirmed live -- firing and reading the weapon's velocity field back gives exactly $04 and $FC, and the shot's x walks across the room four pixels at a time.
R $817C IX The player
  $817C,3 The weapon's velocity field, +$0E of the player's record.
  $817F,5 A lifetime of 48 frames, in +$0F of the weapon's record (WEAPON_LIFE, which lies in the sound slot's unused tail).
  $8184,5 And clear its contact flag.
  $8189,8 Standing still: nothing to fire along.
  $8191,6 Which way on this axis?
  $819A,4 Right or down.
  $819E,2 Left or up: $FC is minus four.
  $81A0,2 Store it and do the other axis the same way.

@ $83EA label=SPAWN_MONSTER_INTO_ROOM
c $83EA Put a new monster into the room
D $83EA Monsters are not placed once and left. Called once a frame from PLAYER_TICK: entering a room names it in $5E26 and starts a 32-frame countdown at $5E27; when that expires a creature is dropped into the room, and after that one more on any frame the refresh register's low nibble is zero -- which is why standing still in one place does not make you safe.
D $83EA It looks for a free slot among only the first three of the eight monster records, and gives up if all three are taken. Those three are also the ones INERT_SPRITE bothers to burn time for, so the spawning slots and the timed slots are the same three.
D $83EA A new monster is a straight sixteen-byte copy of a template at #R$8B6A -- one LDIR, and the record is complete.
  $83EA,8 Only in the room the spawner is watching.
  $83F2,2 Wrong room: nothing to do.
  $83F4,5 The countdown to the next one.
  $83FB,2 Not yet.
  $83FD,8 Three slots, sixteen bytes apart.
  $8405,4 A zero sprite means the slot is free.
  $840E,6 The template.
  $8415,2 Sixteen bytes, and the monster exists.

@ $8EEF label=STEER
c $8EEF Move a heading towards a target, within limits
D $8EEF Adds E and D to the pair at +$06 and +$07 and clamps the result to L and H, handling the negative side by negating, comparing and negating back. The two fields are a signed heading, so this is how a creature turns towards something gradually rather than snapping round to face it.
  $8EEF,5 Not every call: the low nibble of +$02 gates it.
  $8EF6,4 Add the change to the horizontal part...
  $8EFA,3 ...taking the negative side separately.
  $8EFD,4 Clamp to the limit in L.
  $8F01,3 Store it.
  $8F04,4 And the vertical part the same way.
  $8F12,6 Both parts through the same conversion on the way out.

; span $8B6A,16
; span $8B7A,11
@ $8B6A label=MONSTER_TEMPLATE
b $8B6A A new monster, ready to copy
D $8B6A The sixteen bytes SPAWN_MONSTER_INTO_ROOM copies into a free slot, every one of them meaning something documented elsewhere.
D $8B6A The sprite is $58 -- not a creature but the arrival animation, so a new monster appears by materialising rather than blinking into existence. +$03 and +$04 are the centre of the room, overwritten by RANDOM_POSITION. +$08 and +$09 are its starting velocities. And +$02 is the creature to become when the animation ends -- the same trick the player uses when dying -- though the template's own value there, the spider, is never used: the spawner always writes a code from SPAWN_TYPES over it.

# ------------------------------------------------------------------
# The sixteen drawing routines
# ------------------------------------------------------------------

@ $9A0A label=DRAW_TURNED_RIGHT
c $9A0A Drawing mode 2: furniture's pixels turned a quarter clockwise
D $9A0A Entry 2 of PIXEL_DRAWERS. Each screen byte is gathered a bit at a time from one bit column of eight successive rows, starting from the right-hand column, so the source's bottom edge ends up on the left: the picture turned a quarter clockwise. The combining instruction is patched in by SPRITE_COMBINE_OPCODE, as in every routine of the two tables.

@ $9A50 label=DRAW_TRANSPOSED
c $9A50 Drawing mode 3: furniture's pixels transposed
D $9A50 Entry 3 of PIXEL_DRAWERS. Gathers bits as DRAW_TURNED_RIGHT does, but from the left-hand column rightwards: the picture mirrored across its diagonal.

@ $9ACB label=DRAW_UPSIDE_DOWN
c $9ACB Drawing mode 4: furniture's pixels upside down
D $9ACB Entry 4 of PIXEL_DRAWERS. It fetches through FETCH_SPRITE, then copies row by row with the combining instruction patched in by SPRITE_COMBINE_OPCODE, the same as every other routine in the two tables.

; span $9B14,73
@ $9B14 label=DRAW_ANTI_TRANSPOSED
c $9B14 Drawing mode 6: furniture's pixels transposed the other way
D $9B14 Entry 6 of PIXEL_DRAWERS. DRAW_TURNED_RIGHT's bit gathering, reading the rows from the top down: the picture mirrored across its other diagonal.

@ $9B5D label=DRAW_TURNED_LEFT
c $9B5D Drawing mode 7: furniture's pixels turned a quarter anticlockwise
D $9B5D Entry 7 of PIXEL_DRAWERS. DRAW_TRANSPOSED's bit gathering, reading the rows from the top down: the picture turned a quarter anticlockwise.

@ $9D25 label=COLOURS_AS_STORED
c $9D25 Drawing mode 0: furniture's colours as stored
D $9D25 Entry 0 of COLOUR_DRAWERS. It fetches through FETCH_SPRITE_ATTRS, then copies row by row with the combining instruction patched in by SPRITE_COMBINE_OPCODE, the same as every other routine in the two tables.

@ $9D47 label=COLOURS_MIRRORED
c $9D47 Drawing mode 1: furniture's colours mirrored
D $9D47 Entry 1 of COLOUR_DRAWERS. It fetches through FETCH_SPRITE_ATTRS, then copies row by row with the combining instruction patched in by SPRITE_COMBINE_OPCODE, the same as every other routine in the two tables.

@ $9D6F label=COLOURS_TURNED_RIGHT
c $9D6F Drawing mode 2: furniture's colours turned a quarter clockwise
D $9D6F Entry 2 of COLOUR_DRAWERS. It fetches through FETCH_SPRITE_ATTRS, then copies row by row with the combining instruction patched in by SPRITE_COMBINE_OPCODE, the same as every other routine in the two tables.

@ $9DA0 label=COLOURS_TRANSPOSED
c $9DA0 Drawing mode 3: furniture's colours transposed
D $9DA0 Entry 3 of COLOUR_DRAWERS. It fetches through FETCH_SPRITE_ATTRS, then copies row by row with the combining instruction patched in by SPRITE_COMBINE_OPCODE, the same as every other routine in the two tables.

@ $9DCE label=COLOURS_UPSIDE_DOWN
c $9DCE Drawing mode 4: furniture's colours upside down
D $9DCE Entry 4 of COLOUR_DRAWERS. It fetches through FETCH_SPRITE_ATTRS, then copies row by row with the combining instruction patched in by SPRITE_COMBINE_OPCODE, the same as every other routine in the two tables.

@ $9DF8 label=COLOURS_HALF_TURN
c $9DF8 Drawing mode 5: furniture's colours turned a half turn
D $9DF8 Entry 5 of COLOUR_DRAWERS. It fetches through FETCH_SPRITE_ATTRS, then copies row by row with the combining instruction patched in by SPRITE_COMBINE_OPCODE, the same as every other routine in the two tables.

@ $9E21 label=COLOURS_ANTI_TRANSPOSED
c $9E21 Drawing mode 6: furniture's colours transposed the other way
D $9E21 Entry 6 of COLOUR_DRAWERS. It fetches through FETCH_SPRITE_ATTRS, then copies row by row with the combining instruction patched in by SPRITE_COMBINE_OPCODE, the same as every other routine in the two tables.

@ $9E55 label=COLOURS_TURNED_LEFT
c $9E55 Drawing mode 7: furniture's colours turned a quarter anticlockwise
D $9E55 Entry 7 of COLOUR_DRAWERS. It fetches through FETCH_SPRITE_ATTRS, then copies row by row with the combining instruction patched in by SPRITE_COMBINE_OPCODE, the same as every other routine in the two tables.

# --------------------------------------------------------------------------
# How the drawing mode is laid out
# --------------------------------------------------------------------------

@ $9ABA label=START_AT_LAST_ROW
c $9ABA Point at the bottom row of a sprite
D $9ABA Multiplies the width by the height less one and adds it to the data pointer, so drawing can start from the far end. Called by every drawing routine whose mode number has bit 2 set -- which is how the eight modes divide: the low two bits choose the horizontal treatment and bit 2 turns the sprite over.
D $9ABA Checking all sixteen routines in the two tables bears that out exactly. Modes 0 to 3 leave the pointer where it is; modes 4 to 7 all begin by calling this.

# --------------------------------------------------------------------------
# Moving the player, and redrawing what is on screen
# --------------------------------------------------------------------------

@ $8D77 label=MOVE_PLAYER
c $8D77 Turn the controls into movement
D $8D77 The other end of READ_CONTROLS. It takes the byte that routine returns and turns it into a signed step on each axis: bit 0 right, bit 1 left, bit 2 down, bit 3 up, each tested for being clear because a zero bit is a pressed one. B holds the distance, so left is B negated and right is B as it stands.
D $8D77 The character handler passes a step in B ($20), a decay in DE and a value in HL that is popped and never used. DECAY_HEADING takes the decay off the heading, STEER adds the step and clamps it to 32, and SCALE_SIGNED makes two pixels of 32. So all three characters reach full speed at once and differ in how they stop: the knight's decay of 3 slides him five pixels, the serf's 1 sixteen, the wizard's 32 not at all (measured in the simulator).
R $8D77 IX The player
  $8D77,6 Keep the drop controller at $EE58 in the player's room, so MAIN_LOOP runs PUT_DOWN every pass.
  $8D83,8 Mark the record as being worked on.
  $8D8B,6 Position into the workspace, then read the controls.
  $8D96,8 Left: the step, negated.
  $8D9E,5 Right: the step as it is.
  $8DA3,5 Down.
  $8DA8,8 Up: negated again.
  $8DB1,3 Apply it...
  $8DB5,6 ...through STEER, so the change is gradual.

@ $A00E label=WORKSPACE_AND_DRAW
c $A00E Note where a thing is, then draw it
D $A00E Copies the position out of the record into $5E16 and $5E17 before falling into the drawing proper. Those two are what the erase pass reads to find where something was last frame, so recording them here is what lets the next pass rub it out cleanly.
R $A00E IX The thing to draw
  $A00E,6 Where it is now...
  $A014,6 ...kept for the pass that will erase it.

@ $9291 label=DRAW_ROOM_CONTENTS
c $9291 Draw everything in the player's room
D $9291 Walks the eight-byte records from the player up to the monster table, drawing each one whose room matches the player's and skipping any whose sprite is zero. It is the sweep that puts the room's objects, doors and the player back on the screen after the play area has been cleared.
  $9291,4 From the player upwards.
  $9295,6 A zero sprite is an empty slot.
  $929B,8 And only things in this room.
  $92A3,3 Draw it.
  $92A6,5 Eight bytes to the next.

@ $94F5 label=CHOOSE_TIMED_DOORS
c $94F5 Turn about half the plain doors into timed doors
D $94F5 Called once, by START_GAME, on the runtime copy. H' and L' make a pointer into the ROM from TICKS and FRAMES, stepped a byte per record, and the byte there is the random number: for each sixteen-byte record from $EEE0 whose halves are both type 1 (cave door) or both type 2 (door), a byte below $70 turns both halves into $22 or $20 -- a timed cave door or door -- and marks them shut. In the first game after loading that converted 47 of the 82 doors and 21 of the 43 cave doors (measured in the simulator). The walk stops when the address carries past the top of memory.
  $94F5,4 The frame counter drives it.
  $94F9,7 Low bits of the frame, with bit 4 forced on.
  $9502,9 The two halves of the first door, sixteen bytes to the next pair.

# --------------------------------------------------------------------------
# Firing, placing the player, and the menu
# --------------------------------------------------------------------------

@ $8283 label=SERF_FIRE
c $8283 The serf fires his sword
D $8283 The serf's fire routine, called from UPDATE_SERF. Refuses outright if the weapon slot at $EA98 is occupied, so only one shot exists at a time -- that single test is the whole of the game's rate of fire -- or if IN_DOORWAY says the player is outside the room's walk area. With the way clear it makes the rising sweep and calls FIRE_WEAPON, then picks the sword's first angle from the velocity.

@ $9443 label=PLACE_PLAYER
c $9443 Build the player's record from scratch
D $9443 Copies the eight-byte template at PLAYER_TEMPLATE over $EA90, having patched two things into it first: the room, from $EA91, and -- into the template's last byte, not its first -- the character's sprite, worked out from the menu selection the way DRAW_LIVES does it: shift $5E00 up, mask to $30, add 8.
D $9443 The first byte of the template is $66, and that is the point. A game does not begin with the player standing there; it begins with them rising out of the floor, because $66 is what MATERIALISING answers to. The character's own sprite goes into +$07, which is where FINISH_MATERIALISING looks when the animation ends.
D $9443 This is the answer to something that looked like a bug early on: reading the player's sprite byte a second after starting a game gives $66, not $08, and nothing responds to the controls. Nothing is wrong -- the player has not finished arriving.

@ $93E3 label=PUT_DOWN
c $93E3 Put a carried object down
D $93E3 Run every pass by the drop controller, the sprite-$31 record at $EE58 whose room MOVE_PLAYER keeps equal to the player's. With the player in play, the pick-up key held and the press not yet used (PICKUP_USED clear), it marks the press used, lets the third slot's object fall at the player's feet (DROP_CARRIED), shifts the queue along, clears the first slot and redraws the inventory. When the key is up it clears the used bit, so each press does one thing. So a press with nothing underfoot moves the queue on one place; an object falls out only when pushed past the third slot (measured in the simulator).

@ $7CAF label=DRAW_MENU
c $7CAF Draw the title screen's list of options
D $7CAF Points the tile source at the text font and then walks seven entries, each with its own string and position, writing the current one into $5E22 as it goes. Those seven are the six choices -- three control methods and three characters -- and the line that starts the game.

@ $917D label=TIMED_DOOR_SHUT
c $917D A timed door, shut (types $20 and $22)
D $917D Made by CHOOSE_TIMED_DOORS; reached through ACTOR_HANDLERS entries $C2 and $C4 for types $20 and $22. On passes where TICKS is even it counts the shared DOOR_WAIT ($5E2E) down; the door that finds it at zero runs TOGGLE_TIMED_DOOR, which opens it. Otherwise it only draws itself.

@ $9924 label=REGROW_FOOD
c $9924 Grow the food back, one slot every 512 passes
D $9924 On a pass when TICKS' low byte is zero and bit 0 of its high byte clear -- once in 512 -- REGROW_CURSOR ($5E55) steps to the next of the eighty food records, wrapping from the mushrooms back to the first. If that slot is empty and not in the player's room, it is refilled with a random kind of food, $50 + FRAMES AND 7, in its old place (measured in the simulator). A whole round of the eighty takes 512 times 80 passes, about half an hour.

; span $9481,8
@ $9481 label=PLAYER_TEMPLATE
b $9481 A player, ready to copy
D $9481 Sprite $66 is the materialising animation, $60 and $68 the position, and the last byte is patched by PLACE_PLAYER with the sprite to turn into once the player has finished rising.

# --------------------------------------------------------------------------
# The long tail
# --------------------------------------------------------------------------

@ $814B label=WIZARD_FIRE
c $814B The wizard fires his spell
D $814B The wizard's fire routine, called from UPDATE_WIZARD. The same tests as SERF_FIRE -- refuse if a shot is already in the air or IN_DOORWAY is set, make a noise, launch -- with SOUND_SWEEP_DOWN for its noise and sprite $34 for the spell.

@ $882D label=HOME_IN
c $882D Set a heading towards the player
D $882D Compares the target's position with its own on each axis and sets the velocity fields to $FF or $01 accordingly -- the crudest possible pursuit, one pixel a frame towards wherever the player is, with no smoothing and no memory. It is what makes some creatures follow you rather than drift.

@ $8F96 label=DECAY_HEADING
c $8F96 Let a heading fall back towards nothing
D $8F96 The counterpart to STEER. Where that adds to the pair at +$06 and +$07, this subtracts from them towards zero, so a creature that stops being pushed coasts to a halt instead of stopping dead. Gated on the low nibble of +$02, so it only bites every so often.

@ $9E9B label=ERASE_DRAW_ROWS
c $9E9B Erase the old rows and draw the new, interleaved
D $9E9B The loop behind REDRAW_MOVED, DRAW_THING and ERASE_THING. One register bank holds the erase of a thing at its old place (through ERASE_SHIFT_CHAIN), the other the draw at its new place (through SHIFT_CHAIN), each with a row count in C; the loop takes a row from each in turn, bottom up, both XORed onto the screen. ERASE_ROWS and DRAW_ROWS ($5E18, $5E19) hold the rows still to do once ALIGN_ROWS has done the rows the two do not share. Nothing is clipped against the play area.

@ $98D2 label=PLACE_KEYS
c $98D2 Put three of the keys, and the mummy, in rooms chosen for this game
D $98D2 Writes into INITIAL_STATE before START_GAME copies it: the rooms of GREEN_KEY, RED_KEY and CYAN_KEY, each one of eight from RANDOM_ROOMS_ONE, RANDOM_ROOMS_TWO and RANDOM_ROOMS_THREE, chosen from the frame counter. The running values at $5E12 and $5E13 are added in too, but they have just been cleared, so green and red use the same index. The mummy goes into the same room as the red key. The yellow key's room is not touched.

@ $A14D label=DRAW_LIST
c $A14D Draw a list of things through the scratch record
D $A14D Walks a list whose entries are drawn one at a time by loading each into UI_RECORD and using the ordinary sprite path, stopping at a zero pair. The same idea as DRAW_TITLE_ICONS, generalised: anything that has to be drawn without being an actor goes through here.

@ $9FCA label=REDRAW_MOVED
c $9FCA Redraw a thing that may have moved
D $9FCA The end of most handlers (through REDRAW_ACTOR). Sets up the draw at the record's position through SETUP_SPRITE_DRAW, and in the other register bank the erase at the position saved in the workspace through SETUP_ERASE; then ALIGN_ROWS compares the two y positions, erases (or draws) the rows the old and new pictures do not share, and hands the rest to ERASE_DRAW_ROWS, so each screen row is rubbed out and redrawn close together.

# --------------------------------------------------------------------------
# Clearing, starting, and the menu highlight
# --------------------------------------------------------------------------

@ $80B4 label=CLEAR_DISPLAY
c $80B4 Blank the display file
D $80B4 Writes $00 over $4000 for $58 pages -- the whole bitmap, all three thirds. The two routines below it share the same inner loop with a different address and length, which is why they are three entry points rather than three routines.

@ $80C2 label=CLEAR_ATTRIBUTES
c $80C2 Blank the attribute file
D $80C2 $5800 for $5B pages, through the same loop as CLEAR_DISPLAY.

@ $80CB label=CLEAR_VARIABLES
c $80CB Blank the game's variables
D $80CB $5E10 for $60 bytes -- the block holding the score, the clock, the inventory and everything else the game keeps about a session. Called when a new game starts.

@ $80AA label=CLEAR_SCREEN
c $80AA Blank everything and black the border
D $80AA Bitmap, attributes, and then an OUT to port $FE with zero, which sets the border black. The whole screen gone in three calls.

@ $7D9A label=START_GAME
c $7D9A Set a new game up
D $7D9A Clears the variables, sets the lives to three, points the cursor at $EB58, blanks the screen and goes on to build the castle. Everything a game needs to be true at its first frame is made true here.

@ $7CA4 label=UNHIGHLIGHT
c $7CA4 Take the highlight off a menu cell
D $7CA4 Clears bit 7 of an attribute -- the FLASH bit -- and steps on. The title screen shows the current choice by flashing it, so selecting is a matter of turning this bit off one line and on another.

@ $7CAB label=HIGHLIGHT
c $7CAB Put the highlight on a menu cell
D $7CAB Sets the bit UNHIGHLIGHT clears.

@ $7C90 label=HIGHLIGHT_LINE
c $7C90 Flash or unflash a whole menu line
D $7C90 Walks a line of attributes calling one or other of the two routines above, so a whole option lights up rather than a single character.

@ $7D8A label=PRINT_MENU_LINE
c $7D8A Print one line of the menu
D $7D8A Works out the display address and the attribute address for the same point -- one in each register bank, the trick PRINT_STRING uses -- and draws the line with the colour held at $5E22.

@ $8134 label=KNIGHT_FIRE
c $8134 The knight fires his axe
D $8134 The knight's fire routine, called from UPDATE_KNIGHT. The same three tests and FIRE_WEAPON as the other two, with SOUND_SWEEP_A41B for its noise and sprite $40 for the axe.

@ $7E93 label=DISPATCH_FROM_LIST
c $7E93 Dispatch a record named in a room's list
D $7E93 Takes an entry as ROOM_CONTENTS stores it, subtracts the #R$757D bias to get the real address, puts it in IX and dispatches it -- pushing a return address first, the same convention MAIN_LOOP uses.

@ $83BA label=ARC_STEP
c $83BA Look up the second bat's next step
D $83BA For MOVE_ARCS, +$09 is a step counter from 0 to 15, not a speed: doubled, it indexes STEP_VECTORS, and bit 2 of +$08 (tested on the way out) says whether to swap the two components.

# --------------------------------------------------------------------------
# Setting the castle up, and the small helpers
# --------------------------------------------------------------------------

@ $8D61 label=LOAD_INITIAL_STATE
c $8D61 Put the castle back the way it started
D $8D61 One LDIR of $1570 bytes from #R$600D to $EA90. Everything the game keeps at run time -- the player's record, the objects, the monsters, the doors, all of it -- exists as a template inside the loaded block and is copied wholesale into the working area.
D $8D61 So the runtime tables that do not appear in this disassembly, because they live above $D600, do appear in it after all: as five and a half kilobytes of data starting at #R$600D, waiting to be copied. Starting a new game is a single block move.

@ $86F2 label=RANDOM_VELOCITY
c $86F2 Give a creature a random velocity
D $86F2 Reads the refresh register twice: for each axis one bit picks a speed of 1 or 2 and another its sign, and the results go into +$09 and +$08.

@ $8598 label=RANDOM_POSITION
c $8598 A random coordinate near the middle of the room
D $8598 Returns $60 plus or minus (R modulo the limit in B less 8), the sign from another bit of R. SPAWN_MONSTER_INTO_ROOM calls it once for x and once for y with the room's half-extents, so a new creature appears somewhere inside the walk area. It also steps HL on, to the next field.

@ $897D label=ROOM_SHAPE_OF
c $897D Find a room's shape number
D $897D Doubles the room number into ROOM_TABLE and steps one byte on, which lands on the shape rather than the colour.

@ $8F80 label=SCALE_SIGNED
c $8F80 Divide a signed value by sixteen
D $8F80 Negates a negative, rotates four times and keeps four bits, and puts the sign back. It is how a heading in +$06 and +$07 (up to 32) becomes a movement of two pixels or one.

@ $8D6D label=TICK_LOW_NIBBLE
c $8D6D Count down the low nibble of +$02
D $8D6D Does nothing once it reaches zero, so a creature that uses it gets a delay that expires and then stays expired until something sets it again.

@ $8F66 label=APPLY_HEADING
c $8F66 Move a creature, on the axes it is allowed to move on
D $8F66 Bits 4 and 5 of +$02 say whether the horizontal and vertical parts of a heading are to be applied. A creature pinned to one axis is not a special case in the movement code: it is the ordinary code with one of those bits clear.

@ $8FCA label=TEST_STEP_IN_ROOM
c $8FCA Test the player's step against the room's walk rectangle, axis by axis
D $8FCA Called once a frame from MOVE_PLAYER. For the proposed x with the old y, then the old x with the proposed y, ALLOW_IF_IN_ROOM clears bit 4 or bit 5 of +$02 (the "do not move this way" bits MOVE_PLAYER has just set) if the point is inside the walk rectangle. B holds the bit, not a count.

@ $8787 label=COUNTDOWN_ACTOR
c $8787 The burst a destroyed creature becomes
D $8787 Sprites $6C to $6F, the expanding burst KILL_MONSTER turns a creature into. Skips everything if it is in another room, then counts +$0E down from 16, one frame a pass, and at zero goes to WEAPON_GONE: erased, SOUND_WEAPON_GONE, slot freed.

@ $85EA label=MONSTER_CAUGHT_PLAYER
c $85EA A creature caught the player: thirty-two off, and the creature dies
D $85EA The two-instruction path taken when a small creature's proximity test succeeds: LOSE_FOOD_THIRTY_TWO, then KILL_MONSTER. Being caught is expensive but destroys the creature and scores 155, just as shooting it does (measured in the simulator: five contacts, 160 units lost, 775 points).

@ $82C3 label=SIGN_TO_DIRECTION
c $82C3 Turn a signed value into a direction code
D $82C3 Zero, positive or negative becomes 0 or 4 in C, which is then used to pick a sprite or a table entry. The game's usual way of turning "which way is it going" into "which picture".

@ $8ADB label=SCAN_COLLECTABLES
c $8ADB Walk the eight records at $EB18
D $8ADB Eight records, eight bytes apart, skipping any whose first byte is zero -- the same shape as every other table walk in the game.

# --------------------------------------------------------------------------
# Doors, cursor keys, and more helpers
# --------------------------------------------------------------------------

@ $91F2 label=DOOR
c $91F2 An ordinary door
D $91F2 The plain doorway, and the routine every other kind falls back on once it has decided to let the player through. It offers $1111 as the tolerance, asks PLAYER_AT_DOOR whether anyone is standing in it, and calls ENTER_ROOM if so -- then draws itself either way.

@ $9244 label=DOOR_LOCKED_A
c $9244 A locked door of the first sort
D $9244 Types $08-$0B, the red, green, cyan and yellow doors. Asks DOOR_NEEDS_KEY whether the player has the matching key. With one, once the player is in the doorway, it sets both halves' type to $02 -- a plain door -- through SET_BOTH_HALVES and goes through ENTER_ROOM: the door stays an ordinary door for the rest of the game, and the key is kept. Without one it just draws itself shut.

@ $9252 label=DOOR_LOCKED_B
c $9252 A locked door of the second sort
D $9252 Types $0C-$0F, the locked cave doors. The same as DOOR_LOCKED_A but setting type $01, a plain cave door. They share everything from the third instruction on.

@ $9260 label=SET_BOTH_HALVES
c $9260 Give both halves of a door the same sprite
D $9260 Writes the sprite into the record IX points at, then flips bit 3 of the address -- the DOOR_OTHER_SIDE trick -- and writes it into the far half too. An open door has to look open from both rooms.

@ $926C label=ADD_A_TO_HL
c $926C Add an unsigned byte to HL
D $926C Four instructions to do what the Z80 has no single instruction for. Used wherever a table is indexed by a byte, which is most places.

@ $9398 label=READ_CURSOR_KEYS
c $9398 Read the cursor keys
D $9398 The branch READ_CONTROLS takes when the cursor option was chosen. The cursor keys are not adjacent in the matrix the way Q, W, E, R and T are, so this reads a different half-row and assembles the same five bits by hand rather than swapping two of them.

@ $938B label=READ_PICKUP_KEY
c $938B Read the pick-up key, SYMBOL SHIFT
D $938B Selects the half-row holding B, N, M, SYMBOL SHIFT and SPACE, keeps bit 1 -- SYMBOL SHIFT -- and leaves it at $5E20 for PICK_UP and PUT_DOWN. It is read whatever the control method; fire is bit 4 of READ_CONTROLS.

@ $9489 label=PAUSE
c $9489 Pause while SPACE is pressed on its own
D $9489 Once a pass, with interrupts off: if SPACE is down and none of B, N, M or SYMBOL SHIFT is, wait for SPACE to be released, then pressed again, then released. FRAMES does not move meanwhile, so the clock stops too (measured in the simulator). Interrupts come back on at the top of the next pass.

@ $8FE9 label=ALLOW_IF_IN_ROOM
c $8FE9 Allow a step that stays inside the walk rectangle
D $8FE9 If |x - $58| is below the half-width at $5E1D and |y - $68| below the half-height, clears the bit in B from the record's +$02. MOVE_ACTOR's own test is the same comparison inline, for creatures, without the flag.

@ $900A label=TEST_STEP_BOXES
c $900A Test the player's step against the doorways and tables, axis by axis
D $900A As TEST_STEP_IN_ROOM, but calling TEST_ROOM_BOXES with the bit in A'. Runs after it, so a doorway can allow a step the rectangle refused and a table refuse one it allowed.

@ $915F label=TIMED_DOOR_OPEN
c $915F A timed door, open (types $21 and $23)
D $915F As TIMED_DOOR_SHUT, but acting as an ordinary DOOR while it waits, and not toggling while IN_DOORWAY says the player is standing in a doorway.

@ $92E0 label=DRAW_AT_POSITION
c $92E0 Draw a thing where its record says it is
D $92E0 Sets the width, works out where the sprite lands from +$03, and draws. The plain "put it on the screen" ending that most creature handlers jump to when they have nothing else to do.

# --------------------------------------------------------------------------
# Arithmetic the Z80 does not have, and a few more
# --------------------------------------------------------------------------

@ $9AAD label=MULTIPLY
c $9AAD Multiply DE by A
D $9AAD Shift and add, eight times. START_AT_LAST_ROW uses it to find the bottom of a sprite, and DRAW_FOOD to move the roast's pointer past the eaten rows.

@ $9C61 label=PLOT_PIXEL
c $9C61 Plot one pixel
D $9C61 Takes the low three bits of x, rotates a single set bit into that position, and ORs it into the screen at the pixel's address -- DRAW_LINE's plot.

@ $9AA5 label=PREVIOUS_SPRITE_ROW
c $9AA5 Step the sprite pointer back one row
D $9AA5 DE -= B. The mirror of NEXT_SPRITE_ROW, for the drawing modes that read a sprite from the bottom up.

@ $9904 label=TABLE_LOOKUP_3BIT
c $9904 Pick one of eight from a table
D $9904 Masks to three bits, adds to HL, reads the byte. Small enough to inline, kept as a routine because several callers want exactly this.

@ $9E96 label=SPRITE_OF_ACTOR
c $9E96 Find this actor's graphics
D $9E96 Takes the sprite number out of the record and falls into SPRITE_ADDRESS. The two-instruction convenience that most of the drawing path actually calls.

@ $9E86 label=SPRITE_OF_WORKSPACE
c $9E86 Find the graphics for what is in the workspace
D $9E86 The same as SPRITE_OF_ACTOR but reading the sprite from $5E15 rather than from a record -- for the paths that have already lifted it out.

@ $986A label=SET_ARRIVAL_HEADING
c $986A Head the player into the room, away from the arrival door
D $986A Called by ENTER_ROOM with IX on the arrival half. Bits 7 and 6 of its +$05 say which wall the door is in; doubled, they index ARRIVAL_HEADINGS, and the pair found is written into the player's heading at +$06 and +$07: down from the north wall, up from the south, right from the west, left from the east. With the low nibble of +$02 set to 15, STEER keeps the player walking that way for fifteen frames.

@ $98C8 label=MUSHROOM_KILLED_PLAYER
c $98C8 Rub the mushroom out and take the life
D $98C8 Erases it, frees its slot, and jumps into LOSE_LIFE. The mushroom is consumed by killing you.

@ $961B label=ACG_DOOR
c $961B The A.C.G. door: it opens only for the whole of the A.C.G. key
D $961B The handler for the A.C.G. door. It walks the three inventory slots four bytes at a time and wants $8C, $8D and $8E in them, in that order -- the three pieces of the A.C.G. key, ACG_KEY_PARTS -- and only then opens the door (OPEN_DOOR) and behaves as one, with a wider doorway than most. Anything less and it is drawn shut (SHUT_DOOR). Through it is room $8E, and reaching that ends the game.
D $961B New pickups go into the first slot, so this order means collecting $8E first and $8C last. Measured in the simulator: $8C, $8D, $8E opened it and walking in reached SHOW_END_SCREEN; the opposite order left it shut. The door is in room $00, the starting room, on its east wall.

@ $96EC label=SHOW_END_SCREEN
c $96EC Draw the screen shown when a game ends
D $96EC Draws the player, points the tile source back at the text font and prints a line at $2040 from a string at #R$9710 -- the same shape as GAME_OVER, for a different ending.

@ $94B6 label=PLACE_ACG_KEY
c $94B6 Hide the three pieces of the A.C.G. key
D $94B6 Called once, by START_GAME, before the template is copied: (FRAMES + TICKS) AND 7 picks one of the eight sets in KEY_ROOM_SETS, and its three rooms are written into the room bytes of the three pieces' records. TICKS has just been cleared and interrupts have been off since the title screen, so the first game after loading always gets the same set (rooms $17, $10 and $2B from the build's snapshot, measured in the simulator).

@ $957D label=CHECK_IN_DOORWAY
c $957D Note whether the player is standing in a doorway
D $957D Compares the player's position with the room's half-extents at $5E1D, one more than the limit on each axis, and stores the number of axes on which it is outside in IN_DOORWAY ($5E2D). Non-zero means the player is outside the walk rectangle, in a doorway: the three fire routines refuse to fire, and an open timed door will not shut.

# --------------------------------------------------------------------------
# The colour-writing family, and the last of the sounds
# --------------------------------------------------------------------------

@ $A07A label=COLOUR_STILL
c $A07A Colour a thing that has not moved
D $A07A The first of nine attribute fillers DRAW_FROM_RECORD picks by comparing a thing's old and new position: each paints the thing's block of cells in D, its own colour, and the column or row it has just moved out of in E, the room's colour -- so a creature carries its colour with it and hands the room's back. This one, for a thing that has not moved, only paints the block.

@ $A08D label=COLOUR_MOVED_RIGHT
c $A08D Colour a thing that moved right
D $A08D The room's colour into the column to the left of the block, which the thing has just left, then the block.

@ $A0A3 label=COLOUR_MOVED_LEFT
c $A0A3 Colour a thing that moved left
D $A0A3 The block, then the room's colour into the column to its right.

@ $A0B7 label=COLOUR_MOVED_DOWN
c $A0B7 Colour a thing that moved down
D $A0B7 The block, then (COLOUR_TRAIL_ABOVE) the room's colour into the row above it, unless that is above the attribute file.

@ $A0D2 label=COLOUR_MOVED_DOWN_RIGHT
c $A0D2 Colour a thing that moved down and right
D $A0D2 The room's colour to the left of each row and in the row above, the block in D. E is the room's colour, not a second colour of the thing's.

@ $A0EC label=COLOUR_MOVED_UP
c $A0EC Colour a thing that moved up
D $A0EC The room's colour into the row below the block, then the block.

@ $A0FE label=COLOUR_MOVED_UP_LEFT
c $A0FE Colour a thing that moved up and left
D $A0FE The room's colour into the row below, one cell wider, then the block with the column to its right.

@ $A110 label=COLOUR_MOVED_DOWN_LEFT
c $A110 Colour a thing that moved down and left
D $A110 The block with the room's colour to the right of each row, then the row above.

@ $A127 label=COLOUR_MOVED_UP_RIGHT
c $A127 Colour a thing that moved up and right
D $A127 The room's colour into the row below and the column to the left, then the block.

@ $A13B label=DRAW_INVENTORY
c $A13B Draw the three carried objects on the scroll
D $A13B Walks the three inventory slots at $5E30 and draws each through DRAW_LIST, starting at $2CC8 -- so what the player is carrying is shown by drawing the objects themselves rather than by any separate icon. An empty slot draws nothing.

@ $A185 label=ERASE_STRIP
c $A185 Blank twenty bytes where something was
D $A185 Works out the display address from a record's position and writes zero across twenty bytes -- the fastest way to rub out something that is about to be redrawn somewhere else.

@ $A219 label=DRAW_SCROLL
c $A219 Draw the scroll down the side of the screen
D $A219 Points the tile source at #R$B03A -- a set of tiles of its own, not the text font -- and lays out an eight by twenty-four block of them from #R$B32A at x $C0. The parchment border, drawn once when a game starts and left alone after that.

@ $9546 label=DOOR_OPEN_OR_SHUT
c $9546 Open or shut a door, according to its type
D $9546 Bit 0 of the type says which: $21 and $23 (timed doors, open) are odd, $20 and $22 (shut) even. OPEN_DOOR and SHUT_DOOR below do the work on both halves.

@ $9F4A label=DRAW_THING
c $9F4A Draw a record's sprite
D $9F4A Sets the drawing up through SETUP_SPRITE_DRAW, clears the working count at $5E18, and draws. The entry most handlers use when they simply want something on the screen.

@ $9F56 label=ERASE_THING
c $9F56 Rub a record's sprite out
D $9F56 The counterpart to DRAW_THING, working from the position saved in the workspace rather than the record's current one -- which is how something is erased from where it was rather than where it has just moved to.

@ $9F80 label=SETUP_ERASE
c $9F80 Work out where a thing used to be
D $9F80 Looks the sprite up from the workspace and computes the display address of the position saved in $5E16, so ERASE_THING can blank exactly the cells the last frame filled.

@ $9EE6 label=ERASE_SHIFT_CHAIN
c $9EE6 The erase path's unrolled shift chain
D $9EE6 Seven more ADD HL,HL and ADC A,A pairs, entered part-way down by the jump at ERASE_JR, which SETUP_ERASE patches exactly as SETUP_SPRITE_DRAW patches the one before SHIFT_CHAIN. There are two because the erase and the draw run interleaved, each in its own register bank, with its own shift.

@ $9ECE label=ERASE_UNSHIFTED
c $9ECE XOR two unshifted bytes: the erase path's plot for a thing on a cell boundary
D $9ECE Where ERASE_JR lands when the thing's x needs no shift: XOR the two bytes onto the screen, which rubs the thing out.

@ $9F13 label=DRAW_UNSHIFTED
c $9F13 XOR two unshifted bytes: the draw path's plot for a thing on a cell boundary
D $9F13 Where DRAW_JR lands when no shift is needed; the same as ERASE_UNSHIFTED.

@ $9EDC label=FETCH_ROW
c $9EDC Read two bytes of a sprite row
D $9EDC Loads a row into DE ready for shifting, and steps the pointer on.

@ $A379 label=DIVIDE_SLOPE
c $A379 Divide, for a line's slope
D $A379 Eight rounds of shift, trial subtract and set a quotient bit: the shorter side of a line over the longer, as an 8-bit fraction. Its only callers are the two halves of DRAW_LINE.

@ $A39E label=NEGATE_HL
c $A39E Negate HL
D $A39E Subtracts HL from zero, which is the shortest way the Z80 has of negating a sixteen-bit value.

@ $A403 label=PLAY_SOUND_NEW_ROOM
c $A403 Start sound $65
D $A403 Hands sound $65 and a length of ten frames to PLAY_SOUND_CAUGHT's tail. ARRIVE_IN_ROOM calls it for every room entered.

@ $A485 label=PLAY_SOUND_EATING
c $A485 Start sound $A0
D $A485 Hands sound $A0 and a length of sixteen frames to the same tail. EAT_FOOD calls it.

@ $A48B label=SOUND_EATING
c $A48B Sound $A0, one frame of it
D $A48B The third of the sound handlers, alongside SOUND_CAUGHT and SOUND_NEW_ROOM. It takes its pitch from a table at #R$A4A0 rather than computing it, so its sweep is a shape someone chose rather than an arithmetic accident.

@ $A41B label=SOUND_SWEEP_A41B
c $A41B A short sweep
D $A41B Twelve steps of BEEP with the pitch walked down, about nine milliseconds. Reached from KNIGHT_FIRE, so it is one of the three firing noises.

@ $A45F label=SOUND_RISE_SINK
c $A45F The note of the player sinking or rising
D $A45F Takes +$06, complements and masks it, and uses the result as the half-period. Its only caller is the colour step shared by DYING and MATERIALISING, where +$06 is the number of rows of the figure showing -- so the note moves as the player sinks or rises.

@ $A4B0 label=SOUND_BOUNCE
c $A4B0 The sound of a weapon bouncing off a wall
D $A4B0 Called twice in SPIN_WEAPON, when any of the three weapons reverses at the edge of the walk area.

# --------------------------------------------------------------------------
# The castle, as it starts
# --------------------------------------------------------------------------

@ $600D label=INITIAL_STATE
b $600D Every record in the game, before anything has happened
D $600D The 5488 bytes LOAD_INITIAL_STATE copies to $EA90 -- which is to say the whole of the runtime area, $EA90 to the top of memory, written out in full and moved into place with one LDIR. Nothing is built at run time; the castle is simply copied.
D $600D It is laid out exactly as the running game reads it, in the four regions MAIN_LOOP and FRAME_TICK walk. The bytes below are grouped one record to a line.
D $600D What is in it, read out of the data: three empty records for the player, the weapon and the sound slot, which are filled in when a game starts rather than here; 115 objects of the 119 slots, among them sixteen mushrooms, ten each of the eight kinds of food, and, last of them, the drop controller (sprite $31) that runs PUT_DOWN; five monsters, one each of the mummy, Dracula, the devil, Frankenstein's monster and the humpback; and 274 sixteen-byte records for the doors and the furniture.
D $600D The doors are the surprise. Every one is sixteen bytes, not eight -- one record holding both of its sides -- which is why DOOR_OTHER_SIDE flips bit 3 of an address: it is moving between the two halves of a single record. The last region is 274 of these sixteen-byte records: 205 doors, and 69 pairs of pieces of furniture, one in each of two rooms, stored the same way though nothing ever crosses between them -- 36 of the pairs are not even the same piece. A record's type byte says which (see DOOR_KINDS in build_aticatac.py): its handler, found by DISPATCH_FROM_LIST, is a door routine for a door and DRAW_DOOR, the draw-only tail of DOOR, for furniture. Each room's list names the records that are in it; the objects and monsters it names nowhere, finding them by their own room byte.

# --------------------------------------------------------------------------
# The two character sets
# --------------------------------------------------------------------------

; span $B03A,752
@ $B03A label=PANEL_TILES
b $B03A The character set the status panel is drawn from
D $B03A 94 characters, eight bytes each, top row first. DRAW_PANEL points the tile source at this and then draws 8 columns by 24 rows from PANEL_LAYOUT, so the parchment scroll down the right of the screen is not a bitmap at all -- it is a little character set, and a 192-byte map naming which piece goes in each cell.
D $B03A Running DRAW_PANEL and photographing the screen settles what it draws: the scroll, with the words TIME and SCORE on it and the compass at its foot. An earlier note here called it the title picture, which it is not.
D $B03A That the count is exactly 94 is confirmed by the map: the highest value in it is $5D, which is 93, the last character here.
B $B03A,752,8

; span $B32A,192
@ $B32A label=PANEL_LAYOUT
b $B32A The status panel, as tile numbers
D $B32A 24 rows of 8, each byte an index into PANEL_TILES. The loop at #R$A228 walks it a row at a time, calling PLOT_TILE for each cell and colouring it as it goes. The eight columns start at x=192, which is the first character column past the play area -- the same place PAINT_PANEL colours.
B $B32A,192,8

; span $BF4C,472
@ $BF4C label=TEXT_FONT
b $BF4C The text font
D $BF4C 59 characters, eight bytes each, for the codes $20 (space) to $5A ("Z") -- so the game can print spaces, digits, punctuation and capitals, and nothing else.
D $BF4C The code never names this address. It loads TEXT_FONT less $100 into the tile source instead, which is this block less $20 characters, so that a character's own ASCII code indexes it. DRAW_SUMMARY+30 and #R$A1AE load #R$BFCC for the same reason one bias further on: that is where "0" lives, so a digit's value indexes its own glyph with no adjustment at all. Drawing the two glyphs out confirms it -- #R$BFCC is a nought, TEXT_FONT less $100 plus $41 characters is an A, and plus $5A is a Z.
B $BF4C,472,8

# --------------------------------------------------------------------------
# The screens either side of the game
# --------------------------------------------------------------------------

; span $7CEA,160
@ $7CEA label=MENU_DATA
b $7CEA The title screen's menu
D $7CEA Three tables and then the words. The seven lines are drawn by DRAW_MENU, which walks the colours and the row positions in step and takes each string in turn; a character with bit 7 set ends a string, which is why there are no lengths anywhere.
D $7CEA The last two strings are not part of the seven and carry their own colour byte in front, so they can be printed on their own.
B $7CEA,7,7 The colour of each line -- six in $45 and the last in $47, which is what makes START GAME brighter than the choices above it.
B $7CF1,7,7 The row each is drawn at, 24 pixels apart.
T $7CF8,89,11,20,20,9,9,7,13
T $7D51,33 The copyright line. "%" is the copyright sign in this font, not a per cent.
T $7D72,24

; span $967F,48
@ $967F label=END_LABELS
b $967F The three words on the end-of-game screen
D $967F Sixteen bytes each: a colour, then the word padded out with spaces to the width of the field, with bit 7 set on the last one. DRAW_SUMMARY draws the numbers into the gap the padding leaves. The third is not a word: "$" is this font's percent sign, for the share of the castle seen.
T $967F,48,16

; span $9710,33
@ $9710 label=END_MESSAGES
b $9710 What it says when you escape
D $9710 Two strings, each a colour byte then the text, with bit 7 on the last character. The first is misspelt: the bytes read CONGRATULATION and then $D4, which is "T" with the end marker set, so the screen says CONGRATULATIONT. Drawing the screen confirms it -- this is what the game shipped with, not a mistake in reading it.
T $9710,33,16,17

; span $9731,120
@ $9731 label=TRAPDOOR_FALL
c $9731 Fall through a trapdoor
D $9731 Reached only from the trapdoor's handler, #R$91C5, and only while the player is standing on it -- PLAYER_AT_DOOR with a tolerance of $1818. It draws room $96, which is not a room but the trapdoor fall's twelve nested rectangles (see the room types), then runs 128 times: each pass beeps a note whose pitch comes from the frame counter at $5C78 and walks down as the loop counts up, picks black or white from bit 3 of it, writes that into two cells of the attribute file and floods the rest outwards with SPIRAL_FILL. It ends in ENTER_ROOM, which takes the player to the trapdoor's other half -- the landing in the room below.
D $9731 Never reached in any of the recorded playthroughs, which is why the code map left it as data until it was disassembled by hand.
  $9748,3 The frame counter, so the pitch follows real time rather than a count of its own.
  $9750,3 One cycle of BEEP with B complemented, which is what walks the pitch down as the loop counts up.
  $975A,8 Low three bits of the counter all clear -- one frame in eight -- gives $47, white; otherwise $00, black.
  $976B,3 Flood the change outwards from the middle.
  $9771,3 Straight back into the main loop; there is no return.

@ $9774 label=SPIRAL_FILL
D $9774 Fills the attribute file from the centre outwards in a rectangular spiral: right along a row, down the far column, back along the bottom and up the near column, then in by one and round again. It reads the colour to write from the cell one row above the start, so it spreads whatever TRAPDOOR_FALL just put there.
  $9777,6 $5AE0 is the last row of the attribute file; the spiral is walked backwards from there.
  $97A3,3 Two rows and one column shorter each time round.

# --------------------------------------------------------------------------
# Bytes nothing reads
# --------------------------------------------------------------------------

; span $D505,251
@ $D505 label=TAIL_PADDING
b $D505 The tail of the game image
D $D505 251 bytes, of which three are not zero: a $01 seven bytes in, and $3A $85 at the very end. Nothing points here and nothing reads it -- it is the space between the last of the graphics and the end of what the tape loads.
B $D505,251,16








# --------------------------------------------------------------------------
# Two routines nothing calls
# --------------------------------------------------------------------------

; span $9BC1,17
@ $9BC1 label=NEXT_PIXEL_ROW
c $9BC1 Step a screen address down one pixel row
D $9BC1 The standard Spectrum move: bump the row within the character cell, and only when that carries out of three bits step L on by 32 and take 8 off H to get back into the right third of the screen.
D $9BC1 Nothing calls it. There is no CALL or JP to #R$9BC1 anywhere in the game, and it is not in any of the jump tables; the drawing routines all compute a fresh address through PIXEL_TO_SCREEN instead. It disassembles cleanly and ends in a RET, so it is a routine, just not one that runs.
  $9BC2,3 Still inside the cell -- nothing else to do.
  $9BC6,4 Down to the next character row...
  $9BCA,2 ...and if that did not wrap, the third is unchanged.

; span $9F74,12
@ $9F74 label=SETUP_BOTH_BANKS
c $9F74 Set up the drawing address in both register banks
D $9F74 Runs the same setup twice, once per bank, keeping DE across the first call so the second gets the same argument, and then joins the erase path at #R$9FD1.
D $9F74 Like NEXT_PIXEL_ROW, nothing reaches it: no call, no jump, no table entry. SETUP_ERASE immediately after it is the version the game actually uses.
  $9F74,4 DE is wanted twice, so it is kept over the first call.
  $9F78,5 The second bank gets the same argument.

# --------------------------------------------------------------------------
# The small tables
# --------------------------------------------------------------------------

; span $83CA,32
@ $83CA label=STEP_VECTORS
b $83CA How far to move, for each of sixteen headings
D $83CA Sixteen pairs, x then y, indexed by an actor's +$09 doubled. They run (3,0), (3,0), (3,1), (3,1), (3,1), then six of (2,2), then (1,3) three times and (0,3) twice -- a quarter turn walked round in sixteen steps, with the total distance kept roughly the same so a diagonal is not faster than a straight line.
B $83CA,32,2

; span $8C59,10
@ $8C59 label=GAME_OVER_TEXT
b $8C59 "GAME OVER"
D $8C59 A colour byte and nine characters, the last with bit 7 set. GAME_OVER+12 hands it to PRINT_STRING, then the three figures are printed under it, then a two-level counted delay runs and the game jumps back to the title screen.
T $8C59,10

; span $94DD,24
@ $94DD label=KEY_ROOM_SETS
b $94DD Eight sets of three rooms, for hiding the key
D $94DD The routine above picks a set with (A + C) AND $07, multiplies by three, and copies the three bytes into the room bytes of ACG_KEY_PARTS, stepping by eight -- which is +$01 of three consecutive object records in INITIAL_STATE, the field that says which room the object is in. So this chooses where the three pieces are hidden, and it does it by editing the template before LOAD_INITIAL_STATE copies it.
D $94DD Every one of the 24 values is a valid room number, 149 or less, which is what a table of rooms should look like and what a table of anything else almost certainly would not.
B $94DD,24,3

; span $990C,8
@ $990C label=RANDOM_ROOMS_ONE
b $990C Eight rooms to choose between
D $990C Read by the helper at #R$9904, which takes A AND $07 as the index. The result is written to GREEN_KEY's room byte -- inside INITIAL_STATE again, so this is another thing placed differently each game.
B $990C,8,8

; span $9914,8
@ $9914 label=RANDOM_ROOMS_TWO
b $9914 Eight more
D $9914 Chosen with the frame counter added to $5E12, and written to two places at once, RED_KEY's room byte and MUMMY's.
B $9914,8,8

; span $991C,8
@ $991C label=RANDOM_ROOMS_THREE
b $991C Eight more again
D $991C Chosen with the other half of the frame counter added to $5E13, and written to CYAN_KEY's room byte.
B $991C,8,8

; span $A064,22
@ $A064 label=COLOUR_FILLERS
b $A064 Which attribute filler to use, by the way a thing moved
D $A064 Eleven addresses, indexed by 0, 1 or 2 for x unchanged, increased or decreased, plus 4 if y increased (moved down) or 8 if it decreased: nine fillers. The two unused slots are #R$807A rather than a routine in this group, the same trick the actor table uses: an entry that does nothing useful points at something harmless instead of being left out.
W $A064,22,2

; span $A4A0,16
@ $A4A0 label=SWEEP_PITCHES
b $A4A0 The pitches the sweep steps through
D $A4A0 $80 and $90 alternating four times, then $80 walked down to $10 in steps of $10. SOUND_EATING reads it from the last entry down, so in time the note falls from high to low and ends wavering between two pitches.
B $A4A0,16,16

# --------------------------------------------------------------------------
# The last of it
# --------------------------------------------------------------------------

; span $A3BD,10
@ $A3BD label=BEEP_ENTRIES
c $A3BD Two more ways into BEEP
D $A3BD Each loads a pitch and a length and drops into BEEP a few bytes above, the same shape as the two footstep branches. $4040 is one long note; $2080 is a shorter, higher one. Reached from the JP at REMEMBER_CARRIED+35.
  $A3BD,5 One long note.
  $A3C2,5 Shorter and higher.

; span $9F40,10
@ $9F40 label=SETUP_ALT_ENTRIES
c $9F40 Two short entries into the drawing setup
D $9F40 Each calls one half of the setup and jumps into the middle of the routine below, so a caller that already has half of what it needs can skip the rest.

; span $92D8,8
@ $92D8 label=CLEAR_DRAW_FLAG
c $92D8 Clear bit 1 of the drawing flags
D $92D8 Reads $5E1F, ANDs out bit 1 and writes it back. Three instructions on their own, with no return -- it is fallen into rather than called.

; span $7CA1,3
@ $7CA1 label=SET_HIGHLIGHT
c $7CA1 Mark the menu line under the cursor
D $7CA1 SET 7,(HL) then INC HL. Setting bit 7 of a character is the end marker everywhere else, but here it is being used on the menu's attribute bytes to pick a line out.

; span $7CA8,3
@ $7CA8 label=CLEAR_HIGHLIGHT
c $7CA8 Unmark it again
D $7CA8 The other half of SET_HIGHLIGHT: RES 7,(HL) then INC HL.

; span $9883,8
@ $9883 label=ARRIVAL_HEADINGS
b $9883 The heading to arrive with, for each wall
D $9883 Four pairs, x then y, read by the LD HL at SET_ARRIVAL_HEADING+11: nothing and +32 (down, for a north door), -32 and nothing (left, east), nothing and -32 (up, south), +32 and nothing (right, west). 32 is a full-speed heading. An earlier note took these for the mushroom's wander; only ENTER_ROOM reads them.
B $9883,8,8

; span $8B85,5
@ $8B85 label=SPAWNABLE_SPRITES
b $8B85 Five creatures
D $8B85 $62, $4C, $4E, $68, $6A -- a ghost, the pumpkin, a bat, another ghost and another bat. Five sprite codes in a row immediately before the routine at #R$8B8A -- and, as it turns out, the last five entries of SPAWN_TYPES.
B $8B85,5,5





# --------------------------------------------------------------------------
# What the rooms are furnished with
#
# Names for the wide graphics, codes $A2 upwards. These are from pobtastic's
# Atic Atac disassembly at skoolkit.arcadegeek.co.uk, whose graphics pages
# name all of them. Its own index counts from a base of $A600, which is entry
# 162 of SPRITE_TABLE, so its id $0F is this disassembly's code $B1; the two
# tables agree address for address.
#
# Reading these as sprites rather than furniture is what made their tails look
# like unreferenced artwork -- see the note beside GFX_FIRST.
# --------------------------------------------------------------------------

; sprite $A2 Cave door frame
; sprite $A3 Door frame
; sprite $A4 Big door frame
; sprite $A9 Door, locked, red
; sprite $AA Door, locked, green
; sprite $AB Door, locked, cyan
; sprite $AC Door, locked, yellow
; sprite $AD Cave door, locked, red
; sprite $AE Cave door, locked, green
; sprite $AF Cave door, locked, cyan
; sprite $B0 Cave door, locked, yellow
; sprite $B1 Clock
; sprite $B2 Ghost picture
; sprite $B3 Table
; sprite $B4 Roast chicken, whole -- the health indicator
; sprite $B5 Roast chicken, picked to the bones
; sprite $B6 Wall antlers
; sprite $B7 Wall trophy
; sprite $B8 Bookcase
; sprite $B9 Trapdoor, closed
; sprite $BA Trapdoor, open
; sprite $BB Barrel
; sprite $BC Rug
; sprite $BD A.C.G. shield
; sprite $BE Wall shield
; sprite $BF Suit of armour
; sprite $C1 Door, shut
; sprite $C3 Cave door, shut
; sprite $C5 A.C.G. door
; sprite $C6 Pumpkin picture
; sprite $C7 Skeleton
; sprite $C8 Barrel stack

@ $8B7A label=SPAWN_TYPES
b $8B7A What a new monster turns into
D $8B7A Sixteen sprite codes, picked by the frame counter's low four bits: SPAWN_MONSTER_INTO_ROOM puts the one it picks into the new record's +$02, where MONSTER_TEMPLATE's arrival animation finds it when it finishes. The table runs on into the five bytes of SPAWNABLE_SPRITES below, which are its last five entries as well as a list of their own.
B $8B7A,11,8,3

W $A4BE,322,8
@ $A600 label=FURNITURE_SPRITES
W $A600,38,8
@ $A626 label=ROAST_SPRITE
W $A626,2,2 The roast chicken's entry, which DRAW_FOOD moves on past the rows eaten
W $A628,38,8
@ $A64E label=FURNITURE_COLOURS
W $A64E,78,8
@ $BFCC label=FONT_DIGITS

@ $7CF1 label=MENU_ROWS
@ $7CF8 label=MENU_TEXT
@ $7D51 label=COPYRIGHT_LINE
@ $7D72 label=MENU_TITLE
@ $968F label=SCORE_LABEL
@ $969F label=PERCENT_LABEL
@ $9720 label=ESCAPED_TEXT

# ---- Places in the code others name: return points, handlers, doors.
@ $7DF3 label=NEXT_OBJECT
@ $7E35 label=NEXT_IN_LIST
@ $91C5 label=TRAPDOOR
@ $91ED label=BIG_DOOR
@ $9428 label=DOOR_WIZARD
@ $942F label=DOOR_KNIGHT
@ $954D label=OPEN_DOOR
@ $9565 label=SHUT_DOOR

# ---- Self-modifying code: the instructions written into, and the writes as label plus offset.
@ $99D7 label=BLIT_SPRITE_OP
@ $99F9 label=BLIT_MIRRORED_OP
@ $9A36 label=DRAW_TURNED_RIGHT_OP
@ $9A78 label=DRAW_TRANSPOSED_OP
@ $9ADD label=DRAW_UPSIDE_DOWN_OP
@ $9B06 label=BLIT_FLIPPED_OP
@ $9B43 label=DRAW_ANTI_TRANSPOSED_OP
@ $9B88 label=DRAW_TURNED_LEFT_OP
@ $96C6 label=SET_BIT_OP
@ $9C3D label=FROM_VERTEX_X
@ $9C40 label=FROM_VERTEX_Y
@ $9C53 label=TO_VERTEX_X
@ $9C56 label=TO_VERTEX_Y
@ $9EE4 label=ERASE_JR
@ $9F29 label=DRAW_JR

# --------------------------------------------------------------------------
# The runtime records, above the loaded block: named, not labelled
# --------------------------------------------------------------------------

@ $6000 equ=PLAYER=$EA90
@ $6000 equ=PLAYER_ROOM=$EA91
@ $6000 equ=PLAYER_FLAG=$EA92
@ $6000 equ=PLAYER_X=$EA93
@ $6000 equ=PLAYER_Y=$EA94
@ $6000 equ=PLAYER_MODE=$EA95
@ $6000 equ=PLAYER_DX=$EA96
@ $6000 equ=PLAYER_DY=$EA97
@ $6000 equ=WEAPON=$EA98
@ $6000 equ=WEAPON_ROOM=$EA99
@ $6000 equ=WEAPON_HIT=$EA9A
@ $6000 equ=WEAPON_X=$EA9B
@ $6000 equ=WEAPON_Y=$EA9C
@ $6000 equ=WEAPON_DX=$EA9E
@ $6000 equ=WEAPON_DY=$EA9F
@ $6000 equ=WEAPON_LIFE=$EAA7
@ $6000 equ=SOUND_SLOT=$EAA0
@ $6000 equ=LIVE_OBJECTS=$EAA8
@ $6000 equ=LIVE_RED_KEY=$EAC8
@ $6000 equ=LIVE_MUMMY_LURE=$EAE0
@ $6000 equ=LIVE_DROP_SLOTS=$EAE8
@ $6000 equ=LIVE_COLLECTABLES=$EB18
@ $6000 equ=LIVE_FOOD=$EB58
@ $6000 equ=LIVE_MUSHROOMS=$EDD8
@ $6000 equ=DROP_CONTROL_ROOM=$EE59
@ $6000 equ=LIVE_MONSTERS=$EE60
@ $6000 equ=LIVE_DOORS=$EEE0

# Writes into data and code, as a label plus the offset of the byte written.
@ $7C23 isub=LD HL,TEXT_FONT-$0100
@ $7CAF isub=LD HL,TEXT_FONT-$0100
@ $7EAD isub=LD HL,ACTOR_HANDLERS+$0144
@ $8181 isub=LD (WEAPON_LIFE),A
@ $88F4 isub=LD (LIVE_MUMMY_LURE+1),A
@ $8BA0 isub=LD A,(GFX_B4+1)
@ $8BA4 isub=LD A,(GFX_B5+1)
@ $8BC9 isub=LD A,(GFX_B5+1)
@ $8BE2 isub=LD (FOOD_RECORD+3),HL
@ $8BE8 isub=LD HL,(FOOD_RECORD+3)
@ $8C02 isub=LD (GFX_B4+1),A
@ $8C06 isub=LD (GFX_B5+1),A
@ $8C13 isub=LD (GFX_B4+1),A
@ $8C1E isub=LD (FOOD_RECORD+3),HL
@ $8C38 isub=LD HL,TEXT_FONT-$0100
@ $944B isub=LD (PLAYER_TEMPLATE+7),A
@ $9451 isub=LD (PLAYER_TEMPLATE+1),A
@ $94CB isub=LD HL,ACG_KEY_PARTS+1
@ $9505 isub=LD DE,LIVE_DOORS+8
@ $96C3 isub=LD (SET_BIT_OP+1),A
@ $96F2 isub=LD HL,TEXT_FONT-$0100
@ $98DB isub=LD (GREEN_KEY+1),A
@ $98EC isub=LD (RED_KEY+1),A
@ $98EF isub=LD (MUMMY+1),A
@ $9900 isub=LD (CYAN_KEY+1),A
@ $9C36 isub=LD (FROM_VERTEX_X+2),A
@ $9C3A isub=LD (FROM_VERTEX_Y+2),A
@ $9C4C isub=LD (TO_VERTEX_X+2),A
@ $9C50 isub=LD (TO_VERTEX_Y+2),A
@ $9F91 isub=LD (ERASE_JR+1),A
@ $9FB3 isub=LD (DRAW_JR+1),A

# Pairs of numbers loaded together -- pitches, sounds and lengths, pixel# coordinates -- not addresses.
@ $7CD8 keep
@ $8BDC keep
@ $8C1B keep
@ $9656 keep
@ $9671 keep
@ $A266 keep
@ $A27E keep
@ $A286 keep
@ $A2E3 keep
@ $A3DB keep
@ $A3E0 keep
@ $A3E5 keep
@ $A403 keep
@ $A485 keep

# Addresses loaded as return points: the label is right.
@ $7E0E nowarn
@ $7EBE nowarn

# Seventeen codes in SPRITE_TABLE point here: the last row of the graphic
# before, whose first byte, read as a row count, is zero -- a sprite of no rows.
@ $AEEA label=NO_GRAPHIC

# Writes into the drawing loops, and return points: the labels are right.
@ $7DED nowarn
@ $7E93 nowarn
@ $99CD nowarn
@ $99E9 nowarn
@ $9A0E nowarn
@ $9A54 nowarn
@ $9ACF nowarn
@ $9AF3 nowarn
@ $9B18 nowarn
@ $9B61 nowarn

# Entry points other routines use, named for what happens there.
@ $7C29 label=TITLE_AGAIN
@ $7E03 label=NEXT_MONSTER
@ $7E23 label=ROOM_LIST_PASS
@ $7E7F label=DISPATCH_PUSHED
@ $7E82 label=DISPATCH_IN_TABLE
@ $7E85 label=DISPATCH_TYPE_C
@ $7EBE label=TICK_DISPATCH
@ $80B9 label=CLEAR_FROM_HL
@ $80BB label=FILL_FROM_HL
@ $8160 label=LAUNCH_SHOT
@ $8209 label=SPIN_WEAPON
@ $826F label=WEAPON_GONE
@ $827E label=CLEAR_ACTOR
@ $84CD label=STEP_ACTOR
@ $875F label=KILL_MONSTER
@ $89BB label=BIG_MONSTER_STEP
@ $8A25 label=SET_FOOD_LEVEL
@ $8A2B label=FOOD_GONE
@ $8C4A label=END_DELAY
@ $8CD4 label=ANIMATE_SHAPE
@ $8D12 label=ANIMATE_COLOUR
@ $8E78 label=PLAYER_TICK
@ $8E8E label=REDRAW_ACTOR
@ $9147 label=ARRIVE_IN_ROOM
@ $9193 label=TOGGLE_TIMED_DOOR
@ $91F5 label=DOORWAY
@ $91FE label=DRAW_DOOR
@ $9213 label=DRAW_RECORD
@ $924C label=OPEN_AND_ENTER
@ $92E2 label=DRAW_AT_A
@ $95CC label=PLACE_RECORD
@ $9607 label=PRINT_CLOCK
@ $9893 label=MUSHROOM_COLOUR_STEP
@ $98B1 label=MUSHROOM_DRAIN
@ $98C4 label=MUSHROOM_COLOURS
@ $9965 label=DRAW_WITH_MODE
@ $9BF1 label=DRAW_ROOM_A
@ $9C2E label=OUTLINE_DONE
@ $9EB4 label=ROWS_TOGETHER_SWAP
@ $9EB5 label=ROWS_TOGETHER
@ $9EC8 label=ROWS_DRAW_ONLY
@ $9EF9 label=XOR_BYTE
@ $9F4D label=DRAW_THING_ALT
@ $9F59 label=ERASE_THING_ALT
@ $9F83 label=SETUP_ERASE_ALT
@ $9F9B label=SETUP_DONE
@ $9FA2 label=SETUP_AT_POSITION
@ $9FD1 label=ALIGN_ROWS
@ $A01A label=DRAW_FROM_RECORD
@ $A07B label=COLOUR_STILL_BODY
@ $A08E label=COLOUR_RIGHT_BODY
@ $A0A4 label=COLOUR_LEFT_BODY
@ $A0C9 label=COLOUR_TRAIL_ABOVE
@ $A1AE label=DRAW_SCORE
@ $A1B7 label=DRAW_SCORE_AT
@ $A1BF label=DRAW_DIGITS
@ $A1C9 label=DRAW_LOW_DIGIT
@ $A1FF label=PRINT_STRING_REST
@ $A3AA label=BEEP_BC
@ $A3C2 label=SHORT_HIGH_BEEP
@ $A3E8 label=PLAY_SOUND_BC

# The game's variables below the loaded block, from $5E00, and the ROM's
# FRAMES -- named where the notes above describe them, as equates since none
# of them is in the disassembly.
@ $6000 equ=FRAMES=$5C78
@ $6000 equ=FRAMES_HIGH=$5C79
@ $6000 equ=JP_HL_POKE=$5CB0
@ $6000 equ=SELECTION=$5E00
@ $6000 equ=TILE_SOURCE=$5E01
@ $6000 equ=LAST_FRAME=$5E03
@ $6000 equ=IN_FRAME=$5E04
@ $6000 equ=RUNNING_SUM=$5E05
@ $6000 equ=DRAW_WIDTH=$5E10
@ $6000 equ=DRAW_SHIFT=$5E11
@ $6000 equ=TICKS=$5E12
@ $6000 equ=TICKS_HIGH=$5E13
@ $6000 equ=ROOM_DRAWN=$5E14
@ $6000 equ=WORK_SPRITE=$5E15
@ $6000 equ=WORK_X=$5E16
@ $6000 equ=WORK_Y=$5E17
@ $6000 equ=ERASE_ROWS=$5E18
@ $6000 equ=DRAW_ROWS=$5E19
@ $6000 equ=ROOM_COLOUR=$5E1A
@ $6000 equ=LIST_POINTER=$5E1B
@ $6000 equ=ROOM_HALF_WIDTH=$5E1D
@ $6000 equ=ROOM_HALF_HEIGHT=$5E1E
@ $6000 equ=PICKUP_USED=$5E1F
@ $6000 equ=PICKUP_KEY=$5E20
@ $6000 equ=LIVES=$5E21
@ $6000 equ=MENU_COLOUR=$5E22
@ $6000 equ=LINE_WORK=$5E23
@ $6000 equ=LINE_WORK_NEXT=$5E24
@ $6000 equ=ACTORS_HERE=$5E25
@ $6000 equ=SPAWN_ROOM=$5E26
@ $6000 equ=SPAWN_COUNTDOWN=$5E27
@ $6000 equ=FOOD_LEVEL=$5E28
@ $6000 equ=FOOD_DRAWN=$5E29
@ $6000 equ=SCORE=$5E2A
@ $6000 equ=SCORE_LOW=$5E2C
@ $6000 equ=IN_DOORWAY=$5E2D
@ $6000 equ=DOOR_WAIT=$5E2E
@ $6000 equ=STEP_COUNTER=$5E2F
@ $6000 equ=CARRIED=$5E30
@ $6000 equ=CARRIED_SPRITE=$5E32
@ $6000 equ=THIRD_SLOT=$5E38
@ $6000 equ=FLASH_COUNT=$5E3C
@ $6000 equ=CLOCK=$5E3D
@ $6000 equ=CLOCK_SECONDS=$5E3F
@ $6000 equ=ROOMS_SEEN=$5E40
@ $6000 equ=ROOMS_EXPLORED=$5E54
@ $6000 equ=REGROW_CURSOR=$5E55
@ $934C isub=LD HL,CARRIED+7
@ $934F isub=LD DE,CARRIED+11
# The stack's top, not the variable that happens to share the address.
@ $6001 keep
@ $7DC3 keep

# Line comments for the operands written as label plus offset: the HTML shows
# their addresses, so the comment says which field it is.
  $7CAF,3 The text font, less $100: TEXT_FONT-$100
  $7EAD,3 ACTOR_HANDLERS + 2 * $A2, where the room records' handlers start
  $88F4,3 LIVE_MUMMY_LURE+1: its room
  $8BC9,3 GFX_B5+1: the bones' height byte
  $8BE2,3 FOOD_RECORD+3: where the roast is drawn
  $8BE8,3 FOOD_RECORD+3: where the roast is drawn
  $8C02,3 GFX_B4+1: the whole roast's height byte
  $8C06,3 GFX_B5+1: the bones' height byte
  $8C13,3 GFX_B4+1: the whole roast's height byte
  $8C1E,3 FOOD_RECORD+3: where the roast is drawn
  $934C,3 CARRIED+7: the last byte of the second slot...
  $934F,3 CARRIED+11: ...and of the third
  $944B,3 PLAYER_TEMPLATE+7: the character's sprite
  $9451,3 PLAYER_TEMPLATE+1: the room
  $94CB,3 ACG_KEY_PARTS+1: the first piece's room
  $96F2,3 The text font, less $100: TEXT_FONT-$100
  $98DB,3 GREEN_KEY+1: the green key's room
  $98EC,3 RED_KEY+1: the red key's room...
  $98EF,3 ...and MUMMY+1, the mummy's
  $9900,3 CYAN_KEY+1: the cyan key's room
  $9C4C,3 TO_VERTEX_X+2: the displacement in the fetch below
  $9C50,3 TO_VERTEX_Y+2: likewise
  $9F91,3 ERASE_JR+1: the jump's displacement

  $875F,3 KILL_MONSTER: erase the creature, turn it into the burst $6C for sixteen passes (COUNTDOWN_ACTOR), and add 155 to the score. Reached when a small creature is shot, when it touches the player, and when the player is not in play.
  $9193,5 TOGGLE_TIMED_DOOR: reload the shared countdown, then swap this door between shut and open on both halves and rasp.