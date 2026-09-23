# Hand-written annotations for The Hobbit disassembly.
#
# scripts/build_hobbit.py generates a control file from a code-execution map
# (which addresses are code, which are data) and then layers THIS file on top
# of it. Keeping the two apart is what makes the annotations survive: the
# generated one is thrown away and rebuilt on every run, this one is not.
#
# So: never edit game_disassembly/hobbit/*.asm or *.ctl by hand -- the next
# build overwrites both. Add what you learn here instead.
#
# Everything below was read off the game's own instructions, and the timings
# were measured rather than estimated: a bounded sample of the window between
# the title-screen keypress and the game asking for input. Anything inferred
# rather than proved says so.
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
# routine called NAME, and an explicit label of that shape collides with one
# of them and stops the assembly. Use _ALT or a real word instead.
#
# The dictionary at $6000-$6821 is not here: build_hobbit.py decodes it and
# generates its blocks, so every word is named beside its own bytes without
# any of it being written down by hand. See the module docstring for the
# format and for why the synonym links prove it.

# --------------------------------------------------------------------------
# Pictures: the vector interpreter
# --------------------------------------------------------------------------
#
# A location picture is not a bitmap. It is a stream of opcodes -- move, line,
# flood fill, paint attributes -- a few dozen bytes long, drawn into a 256x128
# canvas occupying the top 128 scanlines of the screen. That is how 40000
# bytes hold both a database of locations and a picture for most of them.
#
# The cost of it is the reason this end of the game was looked at first. One
# room entry spends about 6.9 seconds drawing, and the game does not read the
# keyboard while it does, so anything typed during it is lost. Measured
# breakdown of that window, by sampling the simulator every 1000 T-states:
#
#     PIXEL_ADDRESS   3.59s   52%
#     FLOOD_FILL      0.93s   13%
#     PLOT_PIXEL      0.81s   12%
#     PIXEL_SET       0.54s    8%
#     INC_Y           0.53s    8%
#     the rest        0.40s    6%
#
# PIXEL_ADDRESS dominates because nothing caches it: the line drawer steps its
# coordinates one pixel at a time but still recomputes the screen address from
# (D,E) for every pixel it plots, and the flood fill recomputes it again for
# every neighbour it tests -- up to four times per pixel filled.

@ $7F78 label=DRAW_LOCATION_PICTURE
c $7F78 Draw the current location's picture
D $7F78 Looks the location up in the picture table at $CC00, takes the stream pointer out of the record and runs it. Does nothing at all if the byte at $B707 is zero, which is believed to be the graphics on/off flag -- v1.2 was also sold as a text-only edition, and this is the only test standing between a location change and the whole of the drawing code.
R $7F78 O:A The value stored at $7F77, from the table lookup
  $7F79,3 $B707: nonzero to draw pictures at all (believed the graphics flag)
  $7F8D,4 The picture table, indexed by location
  $7F91,3 Find this location's record; returns NZ if it has a picture
  $7F97,6 HL = the stream pointer, from bytes 1 and 2 of the record
  $7F9D,3 Only run the stream if the lookup found a record

@ $7FA7 label=RUN_PICTURE
c $7FA7 Interpret a picture stream
D $7FA7 IY walks the stream; D and E are the current point, in a 256x128 space with y measured upwards from scanline 127. The opcodes are: $00 end, $08 move, $2x paint attributes, $4x flood fill, and anything with bit 7 set a line. Bits 0-2 of a fill or paint opcode are its colour.
D $7FA7 A line is two bytes, and both are split: the opcode byte carries the direction in bits 0-2 and part of the minor-axis step in bits 2-5, while the second byte carries the length in bits 0-5 and the last two step bits in bits 6-7. That is a Bresenham line of up to 64 pixels in 16 bits.
R $7FA7 I:HL The start of the stream
  $7FAF,3 Clear the canvas and take the border and attribute bytes off the front
  $7FB2,10 The point a stream starts from if it draws before it moves: (127, 63)
  $7FC0,3 $00: end of the picture
  $7FC5,2 $08: move...
  $7FC9,10 ...to the point in the next two bytes
  $7FDA,3 A line: bits 0-2 of the opcode are the direction
  $7FDD,5 Bits 2-5 of it are part of the minor-axis step
  $7FE2,7 The second byte's bits 0-5 are the length, plus one
  $7FE9,12 ...and its bits 6-7 are the rest of the step
  $7FF5,3 Draw it
  $7FFE,2 Bit 6 set: a flood fill; bits 0-2 are its colour
  $8001,10 The fill's seed point, from the next two bytes
  $800B,3 Fill from there
  $800E,1 The fill does not move the current point
  $8017,2 Bit 5 set: paint attribute cells; bits 0-2 are the colour
  $8020,8 HL = the first attribute address, stored high byte first
  $802F,2 $FF ends the path
  $8037,7 Each path item: bits 0-1 the direction, bits 2-7 the count
  $803E,16 Keep the cell's ink out of its paper, so a colour can never hide the lines

@ $820B label=CLEAR_CANVAS
c $820B Take the stream's header off and clear the canvas
D $820B Two header bytes: the border colour, then the attribute the picture area starts as. The clear is exactly the picture's own extent and no more -- $4000-$4FFF is the top 128 scanlines, $5800-$59FF the top 16 character rows -- which leaves the text window below it untouched.
D $820B The carry from the routine at $95ED decides whether the picture is drawn in its own colours or blacked out, and if it comes back clear this drops the interpreter's return address and leaves through its exit, so the stream is never run.
  $820F,3 Border colour, from the stream
  $8220,13 Clear the top 128 scanlines
  $822D,3 ...and the top 16 character rows
  $8236,3 The starting attribute, from the stream, filled over them
  $824A,4 Carry clear: abandon the picture through the interpreter's own exit

# --------------------------------------------------------------------------
# Pictures: plotting
# --------------------------------------------------------------------------

@ $81DE label=PIXEL_ADDRESS
c $81DE Screen address and bit mask for a point
D $81DE Given the point in D and E, returns the screen address in HL and a one-bit mask in A. y is measured upwards, so the first thing it does is turn E into a scanline with $7F - E; the rest is the usual Spectrum interleave, bits 6-7 of the scanline to the address's high byte and bits 3-5 to its low.
D $81DE This is the most expensive routine in the game -- 52% of the time spent drawing a room -- and it is called per pixel, by PLOT_PIXEL for every pixel drawn and by PIXEL_SET for every pixel the flood fill tests. About 269 T-states a call, of which the mask loop below is a third.
R $81DE I:D x, 0-255
R $81DE I:E y, 0-127, measured up from scanline 127
R $81DE O:HL The screen address
R $81DE O:A The bit mask for x within that byte
  $81DE,4 Scanline = $7F - y
  $81E7,7 The scanline's bits 6-7 into the address's high byte
  $81EF,6 Its bits 3-5 into the low byte
  $81F5,8 x >> 3 gives the byte across
  $81FD,3 x & 7 selects the bit...
  $8205,4 ...by rotating a single bit that many places, one place at a time
E $81DE The whole routine is a candidate for two lookup tables and an 8-byte mask table, which would roughly halve it. There is no room above the game for them -- the payload ends at $FC3F and the 960 bytes above that are live workspace -- but the printer buffer at $5B00 is page-aligned and unused, since RAMTOP is at $5FFF and nothing here prints.

@ $81B5 label=PLOT_PIXEL
c $81B5 Plot a pixel and colour its cell
D $81B5 Sets the pixel at (D,E) and fixes the attribute of the cell it lands in, taking the wanted ink from PLOT_INK. The cell's existing ink is compared against the wanted one and flipped if they match, so a line can never be drawn in the colour it is drawn on.
  $81B6,3 Address and mask for the point
  $81BB,9 Screen address to attribute address, the usual way
  $81C4,4 Keep the paper, drop the old ink
  $81C8,3 The ink this picture is being drawn in
  $81CE,3 Same as the paper? Then flip it rather than draw invisibly
  $81DA,2 Finally set the pixel itself

@ $824E label=PLOT_INK
b $824E The ink PLOT_PIXEL and the fill are drawing in
D $824E Set from bits 0-2 of a fill opcode for as long as that fill runs, and put back to zero afterwards.

# --------------------------------------------------------------------------
# Pictures: the flood fill
# --------------------------------------------------------------------------

@ $8071 label=FLOOD_FILL
c $8071 Flood fill from a seed point
D $8071 A boundary fill that uses the machine stack as its queue of pending points: $0080 is pushed first as a sentinel, seed points are PUSHed as they are found, and the loop ends when the POP brings the sentinel back -- an E of $80 cannot otherwise occur, since y only goes up to 127.
D $8071 Every neighbour test goes through PIXEL_SET, which recomputes the screen address from scratch, and a pixel gets tested from each of the four directions it can be reached from. That, rather than the plotting, is what makes a large fill slow.
R $8071 I:A The ink to fill with
R $8071 I:DE The seed point
  $8071,3 Remember the ink for PLOT_PIXEL
  $8076,4 The sentinel that ends the fill
  $80E0,4 Sentinel back off the stack: the fill is done

@ $80EE label=PIXEL_SET
c $80EE Is the pixel at (D,E) set?
D $80EE Returns NZ if it is. Two instructions around PIXEL_ADDRESS, and the fill's inner loop.
  $80EF,4 Address and mask for (D,E), and test that bit on the screen

@ $812B label=INC_Y
c $812B Move the point up one, if it can
D $812B y is 0-127, so bit 7 going high means it would leave the canvas: the move is undone and A returned with its low bit clear. Otherwise the low bit is set. The callers test that bit rather than the flags, which is why both exits go through the same tail.
  $812B,5 Up one; did y pass 127?
  $8130,5 Yes: undo it, and return A with bit 0 clear
  $8135,5 No: return A with bit 0 set (DEC_Y shares this)

@ $813A label=DEC_Y
c $813A Move the point down one, if it can
D $813A Same test and the same shared tail as INC_Y: DEC E to $FF also shows up in bit 7.
  $813A,5 Down one; still 0-127?
  $813F,1 No: undo it

@ $8141 label=INC_X
c $8141 Move the point right one, if it can
D $8141 x is a whole byte, so the only edge is the wrap to zero.
  $8141,2 Right one; fine unless it wrapped to 0
  $8143,4 Wrapped: undo it, bit 0 of A clear

@ $8148 label=DEC_X
c $8148 Move the point left one, if it can
  $8148,7 Left one; fine unless it wrapped to 255
  $814F,1 Wrapped: undo it

# --------------------------------------------------------------------------
# Pictures: lines
# --------------------------------------------------------------------------

@ $8151 label=DRAW_LINE
c $8151 Draw a line
D $8151 A Bresenham stepper in two mirrored halves, picked by bit 0 of C: one walks x as the major axis, the other y. Bit 1 of C is the y direction and bit 2 the x direction. B counts down to the next minor-axis step and is reloaded from the stack each time it runs out; L counts the pixels.
D $8151 It already steps the coordinates one at a time, so it knows exactly where the next pixel is -- and then calls PLOT_PIXEL, which throws that away and recomputes the address from the coordinates. Carrying the address and mask along the line instead is where the large win is.
R $8151 I:DE The point to start from
R $8151 I:C Direction flags: bit 0 major axis, bit 1 y, bit 2 x
R $8151 I:B Minor-axis step counter
R $8151 I:L Length in pixels
  $8151,2 Which axis is the major one
  $8155,2 x-major from here
  $8185,2 y-major from here

# --------------------------------------------------------------------------
# Pictures: stepping the attribute grid
# --------------------------------------------------------------------------
#
# The four routines the attribute painter walks with. Each moves HL one cell
# and undoes the move if it would leave $5800-$59FF -- the picture's sixteen
# rows, not the whole attribute area -- so a path cannot run on into the text
# window below. Left and right only stop at the two ends, and otherwise run on
# from one row into the next.

@ $80F5 label=ATTR_UP
c $80F5 Up one attribute row, if it can
  $80F7,6 Up a row: 32 cells back
  $80FD,6 Above $5800? Then undo it

@ $8106 label=ATTR_DOWN
c $8106 Down one attribute row, if it can
  $8108,4 Down a row: 32 cells on
  $810C,5 Still within the picture's rows? Then jump into the middle of the SBC below...
  $8111,3 ...whose second byte, $52, is LD D,D: a one-byte no-op. Reached from the top it undoes the move; from the JR it is skipped

@ $8117 label=ATTR_LEFT
c $8117 Left one cell, if it can
  $8118,7 Left one cell; undo it above $5800

@ $8121 label=ATTR_RIGHT
c $8121 Right one cell, if it can
  $8122,7 Right one cell; undo it past the picture's rows

# --------------------------------------------------------------------------
# Input
# --------------------------------------------------------------------------

@ $8B93 label=SCAN_KEYBOARD
c $8B93 Scan the whole keyboard, debounced
D $8B93 Reads all eight half-rows with BC = $FEFE and RLC B, building a key map at $8B8B and comparing it against the previous one so that only changes count. It calls DEBOUNCE_DELAY first, which is where nearly all of the game's idle time goes: about 7.4ms per scan.
E $8B93 Worth knowing when driving the game from a script: at uncapped emulation speed a key press and release can straddle a scan and be missed entirely, and the game's own ENTER still gets through, so a command comes out as a bare WAIT. Type at realtime speed.
  $8B97,3 Debounce: about 7.4ms
  $8B9A,14 No new key yet; HL = the keyboard as last seen, IX = the masks, BC = the first half-row
  $8BA8,7 Read a half-row, with the keys that do not count masked out
  $8BAF,6 Any key down now that was up last time?
  $8BB5,7 Yes: remember which half-row and which bits
  $8BBC,9 Remember this half-row for next time, and on to the next
  $8BC5,8 No new key at all: A = 0
  $8BCD,15 Key number = half-row times five plus bit
  $8BDC,25 Look it up in KEY_MAP, or KEY_MAP_SHIFTED if either shift is held

@ $8B78 label=DEBOUNCE_DELAY
c $8B78 Busy-wait, 1000 times round
D $8B78 About 26000 T-states, or 7.4ms. SCAN_KEYBOARD calls it every time, so while the game sits at its prompt this is 88% of everything it does -- idle, not work, but it is also the reason a scan is too expensive to call from inside the drawing code as it stands.
  $8B78,8 1000 times round a four-instruction loop: about 26000 T-states

@ $969A label=WAIT_FOR_ANY_KEY
c $969A Wait until any key is pressed
D $969A Polls the whole keyboard through port $FE and returns once something is held, setting the border white on the way out. The game drops into it once the opening picture is finished, before its first prompt -- and a key pressed there is taken as "carry on" and not as a letter, which is why the first letter of the first command typed after the picture always went missing. (The title screen does not use this: it waits in its own loop around $6C60.)
  $969A,9 Wait until any key is down
  $96A3,4 White border

# --------------------------------------------------------------------------
# The second word list
# --------------------------------------------------------------------------

@ $67AB label=SECOND_LIST
b $67AB The words the game prints, as opposed to the words it reads
D $67AB Packed exactly like the indexed dictionary above -- one 5-bit letter per byte, bit 7 ending a word -- and running up the alphabet again from the start. Nothing in the 26-letter index at $6000 reaches it, and nothing anywhere holds its address: PRINT_WORD is handed a 12-bit offset from $6000 and lands wherever that points, so a word is only ever referred to by its own offset and the start of the list is of no interest to anything.
D $67AB Which is why searching for a pointer to $67AB, as an address or as an offset, finds nothing at all. It was found instead with a read watchpoint over the whole range while the game played: it stays untouched through the opening, LOOK and INVENTORY, and is first read on a command that composes a sentence about an object.
E $67AB So the two lists divide by direction, not by content: the indexed one is what MATCH_WORD searches when you type, and this one is the vocabulary the messages are built from. Both live inside the 12-bit reach of PRINT_WORD, $6000-$6FFF, which is what the whole dictionary region is sized for.

# --------------------------------------------------------------------------
# Words in and words out
# --------------------------------------------------------------------------

@ $6F47 label=MATCH_WORD
c $6F47 Look a typed word up in the dictionary
D $6F47 Copies the word from the input line, turning each letter into its 5-bit code with AND $1F -- which works because 'A' is $41 and the codes were chosen to be the low five bits of the ASCII -- and stops at the first character below $40, so punctuation and spaces end a word without being tested for.
D $6F47 Then the index: the first letter doubled and added to $6000 gives the bucket's offset, and that added to $6000 again gives the first entry. From there each call unpacks one candidate -- the tokeniser comes back in at $6F72 for the next -- and the bucket is over when an entry's initial letter stops matching the one typed, which is its only end marker.
E $6F47 A linear scan, not a binary search -- which is the other half of why the list only has to be grouped by initial letter and can be loosely ordered within a group, as BLOW before BLOOD and HELP before HEART are.
  $6F47,18 Copy the typed word as 5-bit codes to $707A, up to the first character below $40
  $6F59,4 Keep its length
  $6F5D,21 IX = the first word in the dictionary under its initial letter
  $6F72,4 Remember which entry is being tried
  $6F76,11 Has the bucket run out? Its initial letter no longer matches
  $6F82,40 Unpack this entry's letters to $708B, by PRINT_WORD's rule for where a word ends
  $6FAA,5 Keep the entry's length
  $6FAF,11 A synonym: step over its two-byte link to the next entry

@ $74BA label=PRINT_WORD
c $74BA Expand a packed word into letters
D $74BA Takes a 2-byte word reference and writes the letters to a buffer at $74A6 -- which the disassembly shows as a data block and a message, because it holds whatever was last expanded into it rather than anything the game was built with.
D $74BA The reference: the low 12 bits are an offset from $6000 to the entry, and the top 4 bits are flags the tail of the routine acts on. Zero means print nothing. The letters come back out as lowercase ASCII by adding $60 to each 5-bit code.
D $74BA The loop is where the game states the format's awkward rule itself. It stops on a byte with bit 7 set, except that if only two letters have been emitted it carries on regardless -- because the top bits of the first two bytes are the word's part of speech, so bit 7 there is not a terminator. At exactly three letters it goes back and re-tests the second byte's bit 7 before deciding. A decoder that simply stops at the first bit 7 splits ATTACK into AT and TACK.
R $74BA I:HL The word reference to read, or use the entry at $74C2 with it already in DE
E $74BA The flags in the top nibble choose whether the word is inflected, and the whole of it is: $40 always adds the suffix, $50 never does, $10 adds it when $B6E8 is non-zero, and every other value adds it when $B6EA is non-zero. Either way the word itself has the final say -- the suffix is only added if bit 7 of its second byte is set, which is what marks an entry as one that can take it.
E $74BA Measured rather than read off: PRINT_WORD was called directly with each of the sixteen flag values and the buffer read back, then $B6E8 and $B6EA were toggled by hand to test the dispatch. The word at $6AC1 comes out as "shatter" or "shatters" exactly as the rule above predicts in all six cases, the ones at $6AA4 and $67FE inflect the same way, and no word in the indexed list inflects at all -- none of them has that bit set, which fits, since the indexed list is what the parser matches against and nothing is ever printed from it.
E $74BA $B6EA holds who the sentence is about, and zero means the player -- so the test really is subject agreement. Watched across real sentences: while the game narrates you it is zero and no verb inflects, and while it narrates anybody else it holds that character's identifier and the inflectable verbs take their -s. $B6E8 is a second participant, and flag $10 is how a word is made to agree with that one instead.
E $74BA The identifiers are not a flag but a character number: $B6E8 is set to $FF at $79B6, loaded from tables at $7956 and $7942 elsewhere, and compared against list entries with CP (HL) at $7A73. One turn of narration walked $B6EA through a run of consecutive values while repeating the same verb, which is a group of characters being described one after another rather than anything to do with grammar.
  $74BA,7 DE = the reference at HL
  $74C1,5 Zero prints nothing
  $74C9,1 C = the flag nibble, for later
  $74CA,8 HL = the dictionary entry
  $74D2,6 The letters go into the buffer at $74A6
  $74D8,10 Each letter as lower-case ASCII, counted in B
  $74E2,5 Bit 7 clear: more letters to come
  $74E7,5 Bit 7 set after only two letters is part of the class, not the end
  $74EC,13 After three, look again at the second byte's bit 7 before deciding
  $74FA,7 Flag nibble $50: never inflect
  $7501,4 $40: always inflect
  $7505,13 $10 agrees with $B6E8, anything else with $B6EA: zero, no ending
  $7512,5 The word itself has to allow an ending: bit 7 of its second byte
  $7517,14 HL = the ending chosen by bits 5-7 of its third byte, in ENDINGS
  $7525,11 Add up to four characters of it to the buffer
  $7530,8 B = how many characters there are to print
  $7538,16 A space before the word, when one is wanted
  $7548,20 Start a new line first if the word would not fit on this one
  $755D,10 Flag nibble $70 sets $B704 to 1
  $7567,10 Print the buffer

# --------------------------------------------------------------------------
# Actions
# --------------------------------------------------------------------------

@ $9DBD label=FIND_RECORD
c $9DBD Find a record in a keyed table
D $9DBD The game's general-purpose lookup. A table is a run of three-byte records -- a key, then a two-byte value -- ending at a key of $FF, and this walks it in order looking for the key in A. It is not sorted and does not need to be. Eleven routines use it: the picture table at $CC00 is one, the action table at $C730 another.
R $9DBD I:A The key to find
R $9DBD I:IX The table
R $9DBD O:IX The matching record, or the $FF that ended the table
R $9DBD O:F NZ if the key was found, Z if the table ran out
E $9DBD Done in the alternate register set, so the caller's BC, DE and HL survive it.
  $9DBD,1 Work in the other register set, so the caller's BC, DE and HL survive
  $9DBE,3 HL walks the table from IX
  $9DC1,1 B = the key being looked for
  $9DC2,4 DE = 3, the size of a record
  $9DC6,4 Found it? The key is tested before the end marker, so a key of $FF can never be found
  $9DCA,4 Run off the end?
  $9DCE,4 On to the next record
  $9DD2,3 IX = the record, or the $FF that ended the table
  $9DD5,2 NZ if found; A is the key

@ $C730 label=ACTION_TABLE
b $C730 What to do for each action code
D $C730 A FIND_RECORD table keyed by the action code in $B6E7, whose values are the routines that carry the action out. Codes 1 to 10 are the ten directions and all go to MOVE, so one routine walks everybody everywhere; the other codes each have a handler of their own, a few of them shared.
D $C730 Every handler address here is real code on the table's own evidence: the playthrough reached 29 of the 31 as routine entry points. The two it did not, for codes 42 and 55, are the reason this table matters for the code map -- a dispatch is exactly what following branches cannot see through, so they are named here and seeded from here.

@ $8D9D label=MOVE
c $8D9D Move a character one step
D $8D9D Called for every character that moves, the player included, with the direction in $B6E7. Watched directly: a single turn in which the player only typed INVENTORY ran this 21 times for nine other characters, each wandering on its own -- which is The Hobbit's independent cast, seen from the inside.
D $8D9D For the player -- told apart by $B6EA being zero -- the codes observed are 1 north, 2 south, 3 east, 9 up and 10 down. West was not observed because it was blocked where the test stood, and the four diagonals will be among 4 to 8, but which is which has not been watched and is not asserted here.
  $8D9D,14 In the dark, the direction asked for is thrown away for a random one from 1 to 10
  $8DAB,11 Is the actor held by anything?
  $8DB6,9 Held by a thing, not a character: cannot move
  $8DBF,4 Held by a character: let go
  $8DC3,12 The actor's size with everything it carries, for fitting through the way out
  $8DCF,10 Is there an exit in that direction?
  $8DD9,6 No way through. In the light, the ordinary refusal
  $8DDF,15 In the dark the player falls: halve byte 5 of the player's record...
  $8DEE,3 ...and while anything is left, "but fall and hit your HEAD." -- six falls are survived
  $8DF1,9 The seventh empties it: "but fall and smash your skull.", and PLAYER_DIES
  $8DFA,6 The exit leads to location 0: nowhere yet
  $8E00,6 Keep the destination; A = the object the way goes through
  $8E06,12 Can it be used (CAN_PASS)? 1 no, 2 too small, 3 no room there
  $8E12,6 Move: the actor's location becomes the destination
  $8E18,6 And everything it holds goes too
  $8E1E,6 The rest is for the player only
  $8E24,21 Run the place's arrival hook, if it has one (ARRIVAL_HOOKS)
  $8E39,4 In the dark, that is all
  $8E3D,9 A = the destination
  $8E46,11 Been here before? On at $96A8. If not, mark the room visited (bit 6)
  $8E51,24 And score it (VISIT_SCORES)
  $8E69,4 Then $9630

@ $C063 label=OBJECT_INDEX
b $C063 Every object and every character, by number
D $C063 A FIND_RECORD table of 61 objects, whose values are the objects' own records. The keys come in two runs: $00 to $2B without a gap, then $3C to $4C. The second run is the characters -- every one of the nine seen wandering in a single turn had its number here, and $B6EA, which says who a sentence is about, holds numbers from that same run. So a character is an object with a number in the upper block, not a separate kind of thing.
D $C063 Object 0 is the player: $B6EA, which is zero when a sentence is about you, holds object numbers, and object 0's location is where the player is.
D $C063 A record is a 16-byte head, then the locations the object is in -- byte 0 of the head says how many -- then its own action handlers (see FIND_OBJECT_HANDLER). Watched rather than inferred: over several turns the one byte that changes in any character's record is the first of those locations, as it wanders; and when the player walked east out of Bag End and back, object 0's location went 1, 4, 1, matching at every step the location whose picture DRAW_LOCATION_PICTURE looked up. Most things are in one place; the ones in several are fixtures between rooms. Object 5 is in locations 1 and 4 -- exactly the two rooms that walk went between, so it is the round green door.
D $C063 The head, as far as it is known. Byte 1 is what holds the object or has it inside, $FF for nothing: see SHUT_IN. Byte 2 is its size and byte 3 its weight, and for a character byte 3 is the most it can carry: the routine at $8CF1 compares a thing's weight and load with the actor's byte 3 and fails with "is too heavy to lift", the one at $93AB with "you are carrying too much", and the one at $A596 compares the actor's size with the room in the thing at byte 2 and fails with "you are too big". Doors, walls and fixtures are $FF in both. Bytes 14 and 15, where not zero, are the object's own description: the map's says there seem to be symbols on it that you cannot read, printed through RUN_MESSAGE. Byte 4's low four bits say how things are placed with this object, as PLACED_WORD prints it: 0 in, 1 on, 2 behind (the curtain, which the wall is behind), 3 under (the trap door), 4 tied to (the rope). Its bits 4 to 6 are sides (see SAME_SIDE): 1 for the player, Gandalf, Thorin and Bard; 2 for Gollum and the goblins; 4 for the wood elf and the butler; 5 for Elrond, on two; bit 7 is on the window alone. Byte 5 is strength and byte 6 defence, what DO_ATTACK weighs, and both wear down with wounds -- and a fall in the dark halves the player's strength.
D $C063 Byte 7, the flags. Bit 7: there, to be seen and reached -- IN_REACH wants it, and the only two objects without it are the mountains' side door, which is secret, and the butler. Bit 6: a character -- set on all twelve and on nothing else, and what FIND_NAMED_OBJECT's mode picks on. Bit 5: can be seen into, which SHUT_IN climbs through; the characters have it, and the goblins' cache and the wooden boat. Bit 1: a liquid -- exactly the wine and the four waters, and the rivers. Bit 2, on a container, is full: DRINK and EMPTY clear it, and FILL will not fill what has it. Bit 3 is dead, or broken: KILL sets it on a character, and a struck spider web has it until it is mended. Bits 2, 3 and 4 are what TOO_DARK reads on the sword; the torch has the same flags. Bit 5 is also a door's being open: OPEN sets it and CLOSE clears it, and CAN_PASS will not let anyone through a way whose object has neither it nor bit 3. Bit 0 is locked: LOCK sets it and UNLOCK clears it, and it is on four doors to start with.

@ $9BCA label=GET_OBJECT
c $9BCA Find an object's record
D $9BCA The object number in A goes to FIND_RECORD against OBJECT_INDEX, and the record's address comes back in IX. Twenty-one routines use it.
R $9BCA I:A The object number
R $9BCA O:IX The object's record
  $9BCA,7 Find the object's entry in OBJECT_INDEX
  $9BD1,11 Swap the entry's pointer into IX, keeping HL

@ $9B81 label=FIND_OBJECT_HANDLER
c $9B81 Find an object's own handler for an action
D $9B81 Skips the record's 16-byte head and the list whose length is byte 0 of it, and searches what follows with FIND_RECORD. That is the object record's grammar stated by the game itself: parsed this way, all 61 records end exactly where the next begins, and the last exactly where ACTION_TABLE starts.
D $9B81 So an object can carry handlers of its own for particular actions, and this is how the game asks whether it does before falling back on the ordinary ones. A handler of $0000 in a record is not an address.
R $9B81 I:A The action code
R $9B81 I:IX The object's record
R $9B81 O:IX The matching handler record, or the $FF that ended the list
R $9B81 O:F NZ if the object has its own handler for this action
  $9B82,1 Keep the action code
  $9B83,6 Skip the 16-byte head and the list of locations, whose length is byte 0
  $9B89,5 IX = the start of the object's own handlers
  $9B8E,3 Look for this action among them

# --------------------------------------------------------------------------
# Reading a command
# --------------------------------------------------------------------------

@ $6FF9 label=INPUT_LINE
b $6FF9 The command line being read
D $6FF9 What READ_LINE fills from the keyboard and the tokeniser reads, ended by a carriage return. The game also fills it itself: on the very first turn the main loop copies LOOK and a return in from $6FF4 and skips READ_LINE, which is how the opening description appears without anybody typing it. scripts/hobbit_drive.py uses the same way in.

@ $6DD6 label=READ_LINE
c $6DD6 Read a command from the keyboard
D $6DD6 Prints the prompt, then takes keys into INPUT_LINE until a carriage return: letters, space, quote, comma and full stop are kept and echoed, backspace steps back, and anything else is ignored. The cursor lives only in registers -- HL walks the line and B counts the room left in it, 128 to start -- so there is no variable in memory that says how much has been typed.
D $6DD6 That is what makes putting a whole command in from outside possible but not quite trivial: stop at $6DF3, just after HL and B are set, write the text into the line, move HL and B past it, and press ENTER. The reader then files the return after the text exactly as if the rest had been typed.
R $6DD6 O:F NZ when a line has been read
  $6DD6,6 Patience: GET_KEY waits this long before typing WAIT itself
  $6DDC,8 Flags read by the printing code while a line is being typed
  $6DE4,10 The prompt: "> "
  $6DEE,5 HL = the start of INPUT_LINE, B = room for 128 characters
  $6DF3,2 Nothing typed yet on this line
  $6DF5,3 Wait for a key
  $6DF8,9 @ on an empty line: do the last command again
  $6E01,7 The first key of a line calls $6E4F first
  $6E08,9 $18 clears the line and starts again
  $6E11,17 Backspace, unless the line is empty: step back one
  $6E22,24 Letters, quote, space, return, full stop and comma are kept; anything else is ignored
  $6E3A,3 Remember the last key
  $6E3D,10 If there is room, echo it and put it in the line
  $6E47,8 Until return: then NZ, a line has been read

# --------------------------------------------------------------------------
# Rooms and exits
# --------------------------------------------------------------------------

@ $9BB1 label=GET_ROOM
c $9BB1 Find a location's record
D $9BB1 Anything from $50 up is not a location and gets zero back; otherwise the record's address is read straight out of ROOM_POINTERS, two bytes per location. Unlike objects there is no search: locations are numbered densely, so a table indexed by number is cheaper than FIND_RECORD.
R $9BB1 I:A The location
R $9BB1 O:IX Its record
  $9BB1,6 $50 and above is not a location: return zero
  $9BB7,5 DE = ROOM_POINTERS, keeping HL
  $9BBC,5 HL = ROOM_POINTERS + 2 x location
  $9BC1,3 DE = the pointer there
  $9BC4,3 IX = the room's record

@ $9D37 label=ACTOR_ROOM
c $9D37 The record of the room the current actor is in
D $9D37 $B70C points at the object record of whoever is acting this turn -- the player or any other character -- and its location is at +$10, so the same code moves everybody.
R $9D37 O:IX The room record
  $9D38,4 IX = the acting character's object record
  $9D3C,3 A = where that character is
  $9D3F,3 IX = that room's record

@ $9E95 label=FIRST_EXIT
c $9E95 Point IX just before the actor's room's first exit
D $9E95 The room's record, plus 7: three short of the exits, because NEXT_EXIT steps three before it looks.
  $9E96,3 IX = the actor's room
  $9E99,5 Plus 7: three short of the exits at +10, since NEXT_EXIT adds 3 before it looks

@ $9B93 label=NEXT_EXIT
c $9B93 Step to the next three-byte entry
D $9B93 Adds 3 to IX and returns Z at the $FF that ends a list. Shared with other lists of three-byte entries, which is why it also loads IY from bytes 1 and 2 -- for an exit those are the object it goes through and the destination, not an address.
  $9B93,1 Keep the caller's BC, DE and HL
  $9B94,5 On three bytes to the next entry
  $9B99,9 IY = bytes 1 and 2 of it, which for an object index entry is the record's address
  $9BA2,5 Z if this is the $FF that ends the list

@ $9F08 label=FIND_EXIT
c $9F08 Find the actor's room's exit in a direction
D $9F08 Walks the exits for one whose direction matches and whose destination is not zero, and returns with IX on it. Watched as well as read: rewinding from the moment the player's location changed on EAST out of Bag End to where this returned found IX at $BAA1, the direction 3, and the record 03 05 04 -- east, through the round green door, to location 4.
R $9F08 I:A The direction, 1-10
R $9F08 O:IX The exit
R $9F08 O:F NZ if there is one
  $9F0B,1 B = the direction wanted
  $9F0C,3 IX just before the actor's room's first exit
  $9F0F,5 Next exit, or give up at the end of the list
  $9F14,6 An exit leading to location 0 goes nowhere yet: pass over it
  $9F1A,7 Not the direction wanted: keep looking

@ $B70C label=ACTOR
b $B70C Whose turn it is
D $B70C The address of the acting character's object record. MOVE, ACTOR_ROOM and the rest read the actor through here rather than assuming the player, which is why one MOVE serves the whole cast.

# --------------------------------------------------------------------------
# Darkness
# --------------------------------------------------------------------------
#
# The v1.0 disassembly credited in build_hobbit.py pointed at what this is --
# the sword is the only lamp, as Sting glows in the book -- and everything
# below was then checked against v1.2's own instructions and data.

@ $95ED label=TOO_DARK
c $95ED Is it too dark for the player to see?
D $95ED Characters are never in the dark: anyone but the player gets "no" at once. The player can see if inside something, or if the room is lit -- bit 7 of the first byte of its record. Otherwise only the short strong sword helps: it has to be with the player, and its flag byte at $C30C must have bit 2 set, bit 3 clear and bit 4 set, which is what XOR $F7 then AND $1C tests for in one go. It starts as $94, so it glows from the beginning, and carrying it lights every dark place.
D $95ED Twenty-six of the seventy-nine rooms are dark, and they are the ones the story says are: the trolls' cave, the goblins' dungeon, cavern and fourteen identical stuffy dark passages, Gollum's lake, the Elvenking's halls, cellar and dungeon, and the passage into the mountain.
D $95ED What depends on it: MOVE, which in the dark throws the direction away and picks one from 1 to 10 at random; and CLEAR_CANVAS, which blacks the picture out instead of drawing it.
R $95ED O:F Carry set if the player cannot see
  $95ED,5 Characters can always see: only the player is ever in the dark
  $95F5,10 The player shut inside something can see
  $95FF,9 So can a player in a lit room (bit 7 of its first byte)
  $9608,15 Otherwise only by the sword, object $0E, if it is within reach...
  $9617,9 ...and glowing: flags bit 2 set, bit 3 clear, bit 4 set, all in one test
  $9620,4 Too dark: carry set, and HL = "it is dark."
  $9628,3 Can see: carry clear

# --------------------------------------------------------------------------
# Messages
# --------------------------------------------------------------------------

@ $72D3 label=RUN_MESSAGE
c $72D3 Print a message
D $72D3 Nearly everything the game says goes through here, as a compact bytecode rather than text. A byte with bit 7 set starts a two-byte word reference, high byte first: twelve bits of offset into the dictionary and a flag nibble, of which 2, 3 and 6 end the message. A byte from $60 to $7F is one of the COMMON_WORDS; from $20 to $5F, a literal character; below $20, a control code, dispatched through CONTROL_CODES -- below $14 as a subroutine that returns to the message, from $14 up as the end of it.
D $72D3 Checked against the screen, not only read: location 4's description decodes to exactly the words the game printed on arriving there, and so does Bag End's. The v1.0 disassembly credited in build_hobbit.py describes the same bytecode, and pointed at where to look.
D $72D3 The messages are stored end to end from $AD7D, straight after COMMON_WORDS, and a few are entered part-way through another: four at an element boundary, sharing its tail -- the last is the two banks of the black river, one description entered at two places -- and one on the second byte of the word that ends the message before, which it reads as a control code.
R $72D3 I:HL The message
  $72D3,10 Inside a quotation, clear $B6FA first
  $72DD,11 Keep DE, IX and A to put back at the end
  $72E8,9 Clear $B6FB unless $B6FA is set
  $72F1,3 IX walks the message
  $72F4,7 Bit 7 set: a word reference
  $72FB,8 DE = the reference: flags and offset from the first byte, low byte from the second
  $7303,14 Ending flags 3, 2 or 6: print it and end the message
  $7311,7 Print it, and on to the next byte
  $7318,9 $60 and up: one of the COMMON_WORDS
  $7321,5 $20-$5F: print it as it is
  $7326,14 Below $20: HL = its handler from CONTROL_CODES
  $7334,4 $14 and up ends the message: jump to it
  $7338,7 Below $14: call it; Z to carry on, NZ to print the word it left in DE

@ $7295 label=CONTROL_CODES
w $7295 A handler for each message control code, $00 to $16
D $7295 Twenty-three handlers. Code $0D, a new line, is printed by the same routine as a literal character, and four codes share the one at $738B -- which is the XOR A; RET that ends code $02's own handler. Codes $02 and $0B are the only ones that take a byte after them. The codes that print a name, IS or ARE, and HIS or YOUR are what let one message serve the whole cast: the same bytes print YOU ARE NOT CARRYING IT for the player and GANDALF IS NOT CARRYING IT for Gandalf.

# The control-code handlers. What each one does was first learned from the v1.0
# disassembly credited in build_hobbit.py, whose table lists the same codes;
# the handlers here are v1.2's, read from its own CONTROL_CODES, and the ones
# marked confirmed were run through RUN_MESSAGE with the output captured at
# PRINT_CHAR. Codes that take a pushed parameter print whatever is on the stack
# when called without one, which is itself consistent with that reading.

@ $7367 label=MC_PUSHED_OBJECT
c $7367 Message control code $00: print the object whose record the caller pushed
  $7367,4 No article
  $736B,4 Dig the caller's pushed record out from under the return addresses
  $736F,5 Print it, unless it is zero

@ $7376 label=MC_PUSHED_WORD
c $7376 Message control code $01: print the word the caller pushed
  $7376,5 Dig the caller's pushed word out into DE
  $737B,3 NZ: print it

@ $737E label=MC_JUMP
c $737E Message control code $02: jump within the message by the signed byte that follows
D $737E Checked, not only read: confirmed by running location 66's description, which prints the west bank and skips the east.
  $737E,11 DE = the signed byte after the code
  $7389,2 Jump by it -- and fall into MC_NOTHING, whose XOR A; RET is this handler's own end

@ $738D label=MC_INSTRUMENT_NOUN
c $738D Message control code $03: the noun of the instrument in the current command
  $738D,7 DE = the instrument's noun, from $B6FC; NZ to print it

@ $7394 label=MC_PUSHED_WITH_ARTICLE
c $7394 Message control code $04: the pushed word with a or the in front
  $7394,5 Dig the caller's pushed word out into DE
  $7399,5 With an article
  $739E,3 Print it

@ $738B label=MC_NOTHING
c $738B Message control code $05, $0A, $0F and $12: do nothing
  $738B,2 Z: carry on with the message

@ $73A3 label=MC_ACTOR
c $73A3 Message control code $06: the actor's name, or YOU
D $73A3 Checked, not only read: confirmed by running a message with it as the player and as Gandalf.
  $73A3,4 No article
  $73A7,6 Print whoever the sentence is about: a name, or YOU

@ $73AF label=MC_TARGET
c $73AF Message control code $07: the target, with its article
  $73AF,5 With an article
  $73B4,9 The target, found one of two ways by $B6FE; printed as MC_INSTRUMENT does

@ $73BD label=MC_BACKSPACE
c $73BD Message control code $08: a backspace, joining the next word to the last
  $73BD,3 A still holds the code, 8, which is the backspace character: print it

@ $73C2 label=MC_INSTRUMENT
c $73C2 Message control code $09: the instrument, with its article
  $73C2,5 With an article
  $73C7,7 The instrument, found one of two ways by $B6FF...
  $73CE,12 ...one routine or the other giving its record...
  $73DA,3 ...which is printed

@ $73E0 label=MC_SUBMESSAGE
c $73E0 Message control code $0B: run the sub-message the signed byte that follows points at
  $73E0,2 Step past the offset byte
  $73E2,16 HL = here plus the signed offset
  $73F2,3 Run that sub-message, then carry on with this one

@ $73F9 label=MC_ACTOR_HIS
c $73F9 Message control code $0C: HIS, or YOUR for the player
D $73F9 Checked, not only read: confirmed the same way: YOUR for the player, HIS for anyone else.
  $73F9,3 The actor
  $73FC,5 Anyone but the player: HIS
  $7401,6 The player: YOUR

@ $7407 label=MC_TARGET_HIS
c $7407 Message control code $0E: HIS or YOUR for the target
  $7407,5 The target instead of the actor

@ $740C label=MC_ACTOR_IS
c $740C Message control code $10: the actor's name and IS, or YOU ARE
D $740C Checked, not only read: confirmed the same way: YOU ARE, GANDALF IS, THORIN IS, from one message.
  $740C,9 The actor, with no article
  $7415,5 Print the name
  $741A,5 Anyone but the player: IS
  $741F,6 The player: ARE

@ $7425 label=MC_TARGET_IS
c $7425 Message control code $11: the same for the target
  $7425,8 The target, with an article

@ $742D label=MC_PUSHED_IS
c $742D Message control code $13: the same for a pushed object
  $742D,7 An object the caller pushed

@ $7340 label=MC_END_LINE
c $7340 Message control code $14: end the message with a new line
  $7340,4 End as flag nibble 6 would: a new line

@ $7344 label=MC_END_STOP
c $7344 Message control code $15: end the message with a full stop and a new line
  $7344,4 End as flag nibble 3 would: a full stop and a new line

@ $735B label=MC_END
c $735B Message control code $16: end the message
  $735B,12 End here: put back the DE, IX and A that RUN_MESSAGE kept

@ $72C3 label=PRINT_LITERAL
c $72C3 Print a literal character from a message
D $72C3 Also control code $0D, a new line, which is why that code has no handler of its own.
  $72C3,3 Print it
  $72C6,7 A new line clears $B704

@ $858B label=PRINT_CHAR
c $858B Print one character
D $858B Everything printed passes through here with the character in A -- which is what makes it a good place to stop to capture exactly what a message says.
  $858B,4 $8576 can refuse to print anything at all
  $8590,6 While a line is being typed, the echo goes another way
  $8596,4 Print it
  $859B,8 Drunk?
  $85A3,8 Only after an S...
  $85AB,7 ...print an H

# --------------------------------------------------------------------------
# Reading a command into tokens
# --------------------------------------------------------------------------

@ $7249 label=GET_KEY
c $7249 Wait for a key, or type WAIT when none comes
D $7249 Counts down from $B714 while it scans the keyboard, and returns the first new key. If the count runs out first it does something rather nice: it clears the line, copies the four letters at $7291 -- WAIT -- into it, prints them, and returns a carriage return as though the player had pressed ENTER. So "time passes" is the game typing a command on your behalf, and the WAIT lines on screen that nobody typed are exactly that.
D $7249 The keyboard scan reports only changes. A driver that stops the game with ENTER held and presses it again at the next prompt is not heard, because the release was never seen; hobbit_drive.py lets it scan with nothing held first.
R $7249 O:A The key
  $724A,14 Scan until a new key, or until the patience in $B714 runs out
  $7258,5 Out of patience: clear the line...
  $725D,14 ...type WAIT into it, printing each letter as a player would...
  $726B,8 ...and return as if ENTER had been pressed after it
  $7273,21 The next wait is what was left of this one plus 500, at most 3000; after a timeout it is 3000 again

@ $7291 label=WAIT_TEXT
t $7291 What GET_KEY types when the player does not
D $7291 Four letters, WAIT, and no terminator: GET_KEY copies exactly four.

@ $6E97 label=TOKENISE
c $6E97 Turn the next word of INPUT_LINE into a token
D $6E97 A token is two bytes: the word's class in the top nibble -- bits 5-6 of its first two dictionary bytes, read together -- and its twelve-bit dictionary offset below that. A synonym comes out as the word it stands for, so GET SWORD is TAKE SWORD by the time anything reads it. $C0 ends the line; $D0 is a word not in the dictionary, and the main loop prints the complaint and never calls the parser.
D $6E97 A typed word may be shortened or, within limits, lengthened. A candidate is taken if the two agree over the shorter length and the typed word is the shorter -- an abbreviation; if the typed word is the longer, only when the entry has at least four letters and no later candidate fits too. Tried: EXAM gives EXAMINE, INV gives INVENTORY, SWORDS gives SWORD, INT gives INTO because IN is too short to stretch, and EXAMINING is not a word at all, since its seventh letter disagrees.
D $6E97 Watched on real sentences: VICIOUSLY ATTACK THE TROLL WITH THE SWORD comes out as adverb, verb, article, noun, preposition, article, noun, end; TAKE THE MAP AND THE KEY puts AND in class $A; and a closing quote gets a full stop token inserted before it by the main loop, so what is said to a character ends as a sentence.
R $6E97 O:BC The token
  $6E98,7 Skip spaces
  $6E9F,3 Remember where the word starts, for the echo of an unknown one
  $6EA2,4 The end of the line: $C0
  $6EA6,5 A full stop, comma or quote is a token by itself
  $6EAB,5 Start on the dictionary bucket for its first letter; none, and it is unknown
  $6EB0,6 Does this candidate agree with what was typed?
  $6EB6,6 No: try the next in the bucket, until it runs out
  $6EBC,4 Not in the dictionary: $D0
  $6EC0,10 The typed word no longer than the entry: an abbreviation, take it
  $6ECA,4 Longer, and the entry under four letters: not this one
  $6ECE,16 Longer, and the entry four or more: take it unless the next candidate agrees too
  $6EDE,5 No word: end of line, or unknown, or punctuation
  $6EE3,6 B = class and top of the offset, C the low byte; A = the class
  $6EEB,16 Walk to the end of the chosen entry...
  $6EFB,14 ...by PRINT_WORD's rule for where a word ends
  $6F09,17 A synonym: its link, turned into an address, replaces it
  $6F1A,12 The class: bits 5-6 of the first byte above bits 5-6 of the second
  $6F26,10 And the entry's offset from $6000

@ $709C label=TOKENS
b $709C The tokens of the line being obeyed
D $709C Two bytes each, up to the end-of-line token $C0. Cleared before each line.

@ $7585 label=PARSE_COMMAND
c $7585 Parse one command from the tokens
D $7585 Called by the main loop with $B6DC pointing into TOKENS; returns NZ to go back for another line. A line of several commands -- joined by THEN, or by a full stop -- is taken one command at a time, the main loop coming back here while $B705 says there is more.
  $7585,8 Start at the first frame, outside any quotation
  $758D,6 Not yet worked out
  $7593,11 Was the last command left unfinished -- after 'which key?', say? Then fit these words into it
  $759E,2 A fresh command
  $75A0,8 E says what may come next: bit 1 a verb, bit 2 an adverb, bit 4 an article, and more
  $75A8,9 In one case a verb may not start here
  $75B1,3 Clear this frame
  $75B4,10 Start a new noun phrase, and allow an article
  $75BE,3 Next token: its class in D
  $75C1,17 Go to the handler for its class, from PARSER_CLASSES

@ $7960 label=OBEY
c $7960 Carry out the parsed command, and let the world take its turn
  $7960,8 From the first frame
  $7968,8 A reply was just fitted into an unfinished command: clear that, and go on from the next frame
  $7970,5 Work out this frame's command; nothing left, and the line is done
  $7975,5 No more commands on this line
  $797A,6 Check it; $7DF5 when it will not do
  $7980,5 Really do it
  $7985,3 Not yet worked out
  $7988,3 Carry it out -- the player's MOVE was reached from here
  $798B,3 Not yet worked out
  $798E,6 Asked to go round the same frame again?
  $7994,8 Count the frame off; none left, done
  $799C,13 On to the next frame down, passing over ALL EXCEPT's exception frames

# --------------------------------------------------------------------------
# Parsing
# --------------------------------------------------------------------------
#
# The shape of the parser -- a state machine dispatching on each token's class,
# filling 24-byte command frames -- was learned from the v1.0 disassembly
# credited in build_hobbit.py. The addresses below are v1.2's own, and the
# frame layout was confirmed by stopping at OBEY after real sentences.

; span $75D2,26
@ $75D2 label=PARSER_CLASSES
w $75D2 Where the parser goes for each class of word
D $75D2 One handler per token class, indexed by the class nibble shifted right three places at $75C2 and reached through JP (HL) -- so following branches never finds them, and they are code seeds. Twelve of the thirteen were reached in play. There is no entry for class $D: an unknown word never gets this far.
W $75D2,26,2
  $75D2,2 Class $0: an adverb
  $75D4,2 Class $1: IN or INTO
  $75D6,2 Class $2: a direction
  $75D8,2 Class $3: a verb
  $75DA,2 Class $4: GO or RUN
  $75DC,2 Class $5: a noun
  $75DE,2 Class $6: an adjective
  $75E0,2 Class $7: a preposition
  $75E2,2 Class $8: an article
  $75E4,2 Class $9: a quantifier, pronoun or game command
  $75E6,2 Class $A: AND
  $75E8,2 Class $B: THEN or a full stop
  $75EA,2 Class $C: the end of the line

@ $76F2 label=PARSE_ADVERB
c $76F2 Parse an adverb
  $76F2,5 Not where an adverb can go: NOT_ALLOWED_HERE
  $76F7,10 Not yet worked out
  $7701,2 Only one
  $7703,5 Store it at offset 2 of the frame
  $7708,3 And on to the next word

@ $7795 label=PARSE_IN
c $7795 Parse IN or INTO
  $7795,11 At the start of a command, straight after AND, IN is a verb
  $77A0,2 Otherwise it is a preposition

@ $76EC label=PARSE_DIRECTION
c $76EC Parse a direction
  $76EC,4 Where a verb could start, a direction is the verb: NORTHEAST on its own
  $76F0,2 Anywhere else it goes where an adverb would, as after GO

@ $7733 label=PARSE_VERB
c $7733 Parse a verb
  $7733,9 Not straight after AND -- E bit 3 is set for an ordinary command -- or inside a quotation: handle it as the verb
  $773C,25 Straight after AND: the AND joined two commands. Go back to the checkpoint PARSE_AND saved at $7574 and end this command there, as THEN would -- so TAKE THE MAP AND DROP IT is two commands
  $7755,8 A second verb without AND: NOT_ALLOWED_HERE, "what ?"
  $775D,4 Already looked ahead for a direction?
  $7761,6 Store it, and on to the next word
  $7767,6 Look ahead, keeping the place...
  $776D,9 ...past any adverbs...
  $7776,12 ...for a direction. None: go back, and store just the verb
  $7782,14 A direction: store the verb, and the direction at offset 2 -- RUN QUICKLY WEST

@ $772F label=PARSE_GO
c $772F Parse GO or RUN
  $772F,2 GO or RUN...

@ $77D1 label=PARSE_NOUN
c $77D1 Parse a noun
  $77D1,6 The noun into PHRASE
  $77D9,7 In mode 2, after ALL EXCEPT...
  $77E0,7 ...with no preposition...
  $77E7,14 ...the noun goes into the frame below, cleared first if need be...
  $77F5,10 ...as its first phrase, and that frame is marked with $40 in its verb's second byte
  $77FF,3 Not yet worked out
  $7802,7 File the phrase; on to the next word unless that failed

@ $77C9 label=PARSE_ADJECTIVE
c $77C9 Parse an adjective
  $77C9,3 Put it in the phrase
  $77CC,5 And go on to see what follows it

@ $77A2 label=PARSE_PREPOSITION
c $77A2 Parse a preposition
  $77A2,3 Into PHRASE
  $77A5,7 Another preposition follows? Add that too
  $77AC,13 An article: allowed once, then dropped
  $77B9,8 An adjective or a noun: carry on building the phrase
  $77C1,8 Anything else: put it back, and file the phrase without a noun

@ $7790 label=PARSE_ARTICLE
c $7790 Parse an article
  $7790,5 An article: noted, not stored -- no second one allowed -- and on to the next word

@ $8251 label=PARSE_SPECIAL
c $8251 Parse a quantifier, pronoun or game command
  $8251,6 Search SPECIAL_WORDS, 13 of them
  $8257,13 Match the low byte, then the high
  $8264,3 Not there: start the command again
  $8267,10 Found: jump to its handler, 26 bytes on

@ $770B label=PARSE_AND
c $770B Parse AND
  $770B,2 Just had AND: a verb now would start another command
  $770E,7 Pass over any more ANDs
  $7715,8 Back to the word after them, and save that place...
  $771D,15 ...with E, the frame and the frame count: the checkpoint PARSE_VERB goes back to
  $772C,3 Then end this part as THEN would

@ $75FA label=PARSE_THEN
c $75FA Parse THEN or a full stop
  $75FA,10 No verb yet, and no earlier frame to borrow one from...
  $7604,10 ...an empty line: nothing to do
  $760E,6 ...no verb outside a quotation: "what ?"
  $7614,10 $B719 = 1 means ALL: set bit 7 of the verb's second byte
  $761E,12 Count the frame, except for the AND in ALL EXCEPT
  $762A,8 On to the next frame; if an AND ended this one, keep going: TAKE THE MAP AND THE KEY
  $7632,6 Finishing a command that was left unfinished?
  $7638,39 Compare the new frame's noun with the old command's...
  $765F,11 ...or its second noun...
  $766A,23 ...and copy the new words into whichever of the old noun and adjectives are empty
  $7682,34 Every frame with no verb takes the verb of the frame before
  $76A4,58 And a frame with the same verb but no second phrase borrows the one before's: PUT THE MAP AND THE KEY IN THE CHEST
  $76DE,7 Nothing more on the line: done
  $76E5,7 More: outside a quotation, go back to the main loop for it; inside one, carry straight on

@ $75F6 label=PARSE_END
c $75F6 Parse the end of the line
  $75F6,4 The end of the line: no more commands in it. On as for THEN

@ $B9C8 label=COMMAND_FRAME
b $B9C8 The command being obeyed
D $B9C8 Twenty-four bytes, and further commands in the same line are built in the frames below it, $B9B0 and down. Offset 0 is the verb, and bit 7 of its second byte marks a command with ALL; offset 2 an adverb or direction; offsets 4 and 14 two noun phrases of ten bytes each -- two prepositions, the noun, and two adjectives. Every word is stored as a two-byte reference, low byte first, articles are dropped altogether.
D $B9C8 Watched rather than taken on trust. PUT THE SMALL CURIOUS KEY IN THE WOODEN CHEST leaves PUT, then KEY with SMALL and CURIOUS, then IN with CHEST and WOODEN. VICIOUSLY ATTACK THE TROLL WITH THE SWORD leaves ATTACK and VICIOUSLY, TROLL, and WITH and SWORD. And the first noun phrase of the first is byte for byte bytes 8 to 13 of the key's own object record: a noun phrase is written in exactly the form objects are named in, so finding what the player means is a straight comparison.
B $B9C8,24,2

# --------------------------------------------------------------------------
# Deciding which object the player means
# --------------------------------------------------------------------------
#
# Found by a read watchpoint on COMMAND_FRAME's first noun, which stopped in
# COPY_PHRASE, and then read forward from there. NAME_MATCHES was then called
# directly on the small curious key with different typed names.

@ $793D label=PHRASES
b $793D The target and instrument being looked for
D $793D Zeros on the tape, so the generated listing called it unused; it is the parser's working space for the command in hand.
B $793D,1,1
  $793D,1 Target flags: bit 0, a target was named; bit 1, one has been found
B $793E,1,1
  $793E,1 The same for the instrument
B $793F,3,3
  $793F,3 Not yet worked out
@ $7942 label=TARGET_NAME
B $7942,6,2
  $7942,6 The target as typed: noun, then two adjectives, in the form objects are named in
@ $7948 label=INSTRUMENT_NAME
B $7948,6,2
  $7948,6 The instrument, the same way
B $794E,2,2
  $794E,2 A pointer the search starts from
B $7950,10,10
  $7950,10 Not yet worked out
B $795A,4,2
  $795A,4 Prepositions the command expects, which decide which noun phrase is which
B $795E,2,2
  $795E,2 Not yet worked out

@ $7C91 label=COPY_PHRASE
c $7C91 Copy a noun and its adjectives out of the command frame
D $7C91 Six bytes from the frame offset in C -- 8 for the first noun phrase's noun, 18 for the second's -- into a slot, and sets bit 0 of the flag byte in HL if anything was there. The code before it chooses which phrase goes to TARGET_NAME and which to INSTRUMENT_NAME, by whether the second phrase's prepositions are the ones the command expects: ATTACK THE TROLL WITH THE SWORD makes the troll the target and the sword the instrument.
  $7C92,8 HL = the phrase in the frame, at offset A
  $7C9A,5 Copy its noun and two adjectives to DE
  $7C9F,7 Walk back over the six bytes just copied: were any of them set?
  $7CA8,1 No: nothing was named here
  $7CA9,2 Yes: set bit 0 of the flag byte

@ $7CC9 label=CALL_IY
c $7CC9 Call the routine IY points at
D $7CC9 JP (IY), so a caller can choose the search: TRY_TARGETS uses FIND_NAMED_OBJECT.
  $7CC9,2 Whatever routine IY points at

@ $7CFC label=TRY_TARGETS
c $7CFC Try each object that fits the target's name
D $7CFC Finds the next object matching TARGET_NAME, makes it the target in $B6E8, and tries the command on it; if that did not take, it goes round again for the next. So PICK UP THE KEY where there are several keys tries them in turn.
  $7CFC,9 Next object fitting the target's name; none left, and the command fails
  $7D05,3 It is the target
  $7D08,5 Note that a target was found
  $7D0D,3 Try the command on it
  $7D10,6 It did not take: try the next object that fits

@ $9DD9 label=FIND_NAMED_OBJECT
c $9DD9 Find the next object that fits a name
D $9DD9 Walks OBJECT_INDEX from IX, three bytes at a time with the iterator the exits use, which leaves each object's record in IY. An object is passed over if its name does not match (NAME_MATCHES against the record's bytes 8-13), if a mode in $B710 asks only for objects whose byte 7 has, or lacks, bit 6 set with bit 3 clear, or -- unless $B70F says otherwise -- if $9E34 finds it is not within the actor's reach.
R $9DD9 I:HL The name to look for
R $9DD9 I:IX Where in the index to carry on from
R $9DD9 O:A The object number, or $FF when there are no more
  $9DDD,7 IY = the actor; D = where the actor is
  $9DE4,4 E = the mode: 0 only things, 1 only characters, 2 either
  $9DE8,5 Next object in the index -- IY is its record -- or stop at the end
  $9DED,5 Mode 2: take anything
  $9DF2,12 A = 1 for a character (flags bit 6 set, bit 3 clear), else 0...
  $9DFE,3 ...and pass it over if that is not the kind wanted
  $9E01,14 Compare the typed name with the object's, at bytes 8-13 of its record
  $9E0F,6 Asked not to check reach?
  $9E15,8 Pass over anything out of the actor's reach
  $9E1D,3 A = this object's number, or $FF from the end of the index

@ $71F3 label=NAME_MATCHES
c $71F3 Does a typed name fit an object's name?
D $71F3 The noun has to match; the adjectives need not be typed at all, and are accepted in either order -- it tries them as given, then swapped -- but one that does not belong rules the object out. Called directly on the small curious key: KEY, CURIOUS KEY, SMALL CURIOUS KEY and CURIOUS SMALL KEY all match; LARGE KEY, SMALL LARGE KEY and MAP do not.
R $71F3 I:HL The typed name
R $71F3 I:IY The object's name
R $71F3 O:F Z if it fits
  $71F7,5 The nouns must match, or it is not this object
  $71FC,5 Note that the noun matched
  $7201,12 Adjectives in the order typed? Then it fits, A = 0
  $720D,6 Otherwise start again from the beginning of both names...
  $7213,12 ...compare the first typed adjective with the object's second...
  $721F,10 ...and the second typed adjective with the object's first: A = 1 if that fits

@ $722E label=WORD_MATCHES
c $722E Does a typed word fit a word of a name?
D $722E A word that was not typed -- zero -- fits anything. Otherwise only the twelve-bit dictionary offset is compared, not the flag nibble above it. Both pointers move on two bytes either way.
  $722F,5 Not typed at all? Then it fits anything
  $7234,8 Same top half of the twelve-bit offset, ignoring the flag nibble...
  $723C,5 ...and the same low byte
  $7241,8 On to the next word of both names either way

# --------------------------------------------------------------------------
# What can be reached
# --------------------------------------------------------------------------

@ $9E34 label=IN_REACH
c $9E34 Is an object within the acting character's reach?
D $9E34 The actor from ACTOR, then IN_REACH_OF. Called directly with the player at Bag End, it says yes to the wooden chest, the map the player holds, Gandalf, Thorin, and the round green door -- which is in Bag End and the Lonelands at once -- and no to the large key the troll is holding in the clearing, the heavy rock door, and the short strong sword, which is lying in the trolls' cave, where Bilbo finds Sting in the book.
R $9E34 I:A The object's number
R $9E34 I:IY Its record
R $9E34 O:F NZ if it is within reach
  $9E36,4 The acting character

@ $9E40 label=IN_REACH_OF
c $9E40 Is an object within reach of the character in IX?
D $9E40 Nothing is within reach that has bit 7 of its flags clear. Otherwise it is if the character is inside it; or if the two are shut in the same container; or if neither is shut in anything and the object is in the character's location -- any of its locations, which is how a door is within reach from either side.
R $9E40 I:IX The character's record
R $9E40 I:IY The object's record
  $9E40,5 Not there to be seen: never in reach
  $9E4A,4 B = the object; C = where the character is
  $9E4E,9 Is the character shut inside the object itself? Then it is in reach
  $9E59,6 Shut inside something the object is not? Out of reach
  $9E5F,3 Both shut in the same thing: in reach
  $9E62,13 Both free: in reach if the character's location is any of the object's
  $9E6F,3 Z: out of reach
  $9E72,2 NZ: in reach

@ $9E7A label=SHUT_IN
c $9E7A What is this object shut inside?
D $9E7A Follows byte 1 of the object's record -- what holds it -- up through holders whose flags have $28 set, which can be seen into, and returns the first that cannot, or $FF if it runs out. The player's own record has $28 set, so a thing the player carries is not shut in anything by being carried.
D $9E7A Byte 1 is watched as well as read: the map is held by Gandalf ($3E) on the tape and by the player (0) at the first prompt, the turn the game says Gandalf gives it to you; and the large key is held by the hideous troll, as the trolls' clearing says it is.
R $9E7A I:IX The object's record
R $9E7A O:A What it is shut in, or $FF
  $9E7C,7 Held by nothing? Then it is not shut in anything: A = $FF
  $9E83,7 Go up to the holder, keeping its number
  $9E8A,7 Can the holder be seen into (flags $28)? Then keep climbing
  $9E91,1 A = the first holder that cannot be seen into

@ $90D2 label=PLAYER_DIES
c $90D2 The player is dead: say so and start again
D $90D2 Prints "you are dead." as a sentence about the player, calls $83F5, waits for any key and goes back into the start-up at $6C27. Reached, for one, from MOVE when the player falls in the dark once too often.
  $90D2,4 The sentence is about the player
  $90D6,6 "you are dead."
  $90DC,3 Not yet worked out
  $90DF,9 Wait for any key
  $90E8,3 And start again

@ $8B81 label=KEY_STATE
b $8B81 The keyboard scan's working bytes
D $8B81 Eight masks, one per half-row, of keys that never count as pressed on their own -- CAPS SHIFT and SYMBOL SHIFT among them; then the half-row and bits of the last new key found; then the eight half-rows as last seen, which is how SCAN_KEYBOARD knows a key is new.
B $8B81,8,8
  $8B81,8 Keys that do not count as a keypress, per half-row
B $8B89,2,2
  $8B89,2 The last new key: half-row and bits
B $8B8B,8,8
  $8B8B,8 The keyboard as last scanned

@ $8BFB label=KEY_MAP
b $8BFB What each key gives
D $8BFB Forty characters, one per key, indexed by half-row times five plus the key's bit: capital letters, SPACE, ENTER and a backspace on 0; the rest of the number row gives nothing.
B $8BFB,40,10

@ $8C23 label=KEY_MAP_SHIFTED
b $8C23 What each key gives with a shift held
D $8C23 The same, plus the quote on P, full stop and comma on M and N, the @ that repeats the last command, and the $18 that clears the line.
B $8C23,40,10

@ $B71F label=ENDINGS
b $B71F The endings a word can be given
D $B71F Eight slots of four characters, chosen by bits 5-7 of a word's third dictionary byte when PRINT_WORD inflects it: "s" for fifty verbs, "es" for six (GO, CROSS, PUSH, SLASH, SMASH, TORCH), "ies", "d", "ing", and one worth a second look -- a backspace then "ies", which is how CARRY prints as CARRIES: the backspace takes the Y back off. The last two slots are empty. EMPTY is given plain "ies", which would print EMPTYIES if it were ever inflected; that has not been checked.
B $B71F,32,4

@ $B700 label=DRUNK
b $B700 Whether the player has drunk the wine
D $B700 Cleared at the start of a game and set by WINE_DRUNK. While it is set, PRINT_CHAR follows every S with an H: after the wine, the Lonelands' description comes out as "a gloomy empty land with dreary hillsH ahead". Tried, not only read -- the wine was moved into Bag End, DRINK THE WINE answered "you drink some wine." and set this byte, and a message printed before and after shows the difference.
B $B700,1,1

@ $AAF9 label=WINE_DRUNK
c $AAF9 The wine's own handler: the player drinks it
D $AAF9 The wine carries this for action 0 in its record, so nothing branches to it and it showed as data; drinking the wine is what runs it. Only the player is affected. It also starts timer 7 in TIMERS, copying its length of five turns into its count, and when that runs out WINE_WEARS_OFF sobers the player up again.
  $AAF9,6 Only the player
  $AAFF,5 Drunk: from now on every S is followed by an H
  $AB04,7 Start timer 7: sober again in five turns

@ $757A label=PHRASE
b $757A The noun phrase being built
D $757A A count of prepositions, then ten bytes laid out as a noun phrase in the command frame is -- two prepositions, the noun, two adjectives, each a word reference low byte first -- which the class handlers fill as the words arrive.
B $757A,1,1
  $757A,1 How many prepositions it has so far: ADD_PREPOSITION refuses a third
B $757B,4,2
  $757B,4 Two prepositions
B $757F,2,2
  $757F,2 The noun
B $7581,4,2
  $7581,4 Two adjectives: ADD_ADJECTIVE takes the first free one and refuses a third

@ $7873 label=NEXT_TOKEN
c $7873 Take the next token
D $7873 From the pointer in $B6DC, which it moves on. The previous position is kept in $B6DA, which is what the main loop echoes back when a word is not known, and the previous class in $B6DE, which PARSE_IN looks at.
R $7873 O:D The class, in the top nibble
R $7873 O:BC The word: B the top of its offset, C the low byte
  $7873,6 Keep where this token is, for the echo of an unknown word
  $7879,4 Keep the class of the last token
  $787D,8 B = the top of the word's offset, D = the class
  $7885,6 C = the low byte; move the pointer on

@ $7864 label=CLEAR_FRAME
c $7864 Clear the frame at IY
D $7864 All 24 bytes, and the verb of the frame below it, so that one reads as empty.
  $7864,8 Clear the 24 bytes
  $786C,6 And the verb of the frame below

@ $70E2 label=CLEAR_BYTES
c $70E2 Zero B bytes from HL
  $70E2,5 Zero, B times over

@ $7918 label=STORE_WORD
c $7918 Store the word in BC in the frame at offset L
D $7918 Low byte first -- which is why the frames and object names hold their words little-endian while tokens hold them the other way round.
  $7918,7 HL = the frame plus L
  $791F,3 The word, low byte first

@ $7929 label=NOT_ALLOWED_HERE
c $7929 A word that is not allowed where it came
D $7929 Inside a quotation it is simply passed over, so orders given to other characters are more forgiving. Otherwise the game says "what ?" and the command is abandoned.
  $7929,6 Inside a quotation: ignore the word and carry on
  $792F,11 Otherwise "what ?"
  $793A,3 NZ: the command is abandoned

@ $7809 label=ADD_ADJECTIVE
c $7809 Add the adjective in BC to PHRASE
  $7809,8 Is the first adjective slot free?
  $7811,7 Is the second? Neither: too many adjectives
  $7818,3 Store it, low byte first

@ $7914 label=STORE_VERB
c $7914 Store the verb in BC at the head of the frame
D $7914 No second verb is allowed after it, and it goes in at offset 0 through STORE_WORD, which it runs straight into.
  $7914,4 No second verb; offset 0

@ $781C label=ADD_PREPOSITION
c $781C Add the preposition in BC to PHRASE
  $781C,10 Count it; a third preposition is an error
  $7826,5 Into the first free preposition slot, as ADD_ADJECTIVE does adjectives

@ $782B label=FILE_PHRASE
c $782B Put PHRASE into the frame's first free noun phrase
D $782B E's bit 6 says the first, at offset 4, is still empty, and bit 7 the second, at offset 14. A third phrase is an error.
  $782B,4 The first phrase still empty? It goes there
  $782F,9 Nor the second: one phrase too many
  $7838,6 The second, at offset 14
  $783E,14 Copy the ten bytes of PHRASE into the frame at that offset

@ $7850 label=FILE_FIRST_PHRASE
c $7850 Put PHRASE into the frame's first noun phrase
  $7850,8 The first, at offset 4

@ $8271 label=SPECIAL_WORDS
b $8271 The special words, and what PARSE_SPECIAL does with each
D $8271 Thirteen word references, then a handler for each, reached through JP (HL) -- so the handlers are code seeds. Among them are the game's own commands: SAVE and LOAD, which the playthrough never types, QUIT, PAUSE, HELP, SCORE, and PRINT and NOPRINT. Slot 0 holds no word, so its handler is never reached through here; ONE's handler just goes on to the next word.
W $8271,26,2
  $8271,2 NO WORD
  $8273,2 ALL
  $8275,2 EXCEPT
  $8277,2 IT
  $8279,2 ONE
  $827B,2 PRINT
  $827D,2 NOPRINT
  $827F,2 LOAD
  $8281,2 SAVE
  $8283,2 QUIT
  $8285,2 HELP
  $8287,2 SCORE
  $8289,2 PAUSE
W $828B,26,2
  $828B,2 Handler for SLOT 0
  $828D,2 Handler for ALL
  $828F,2 Handler for EXCEPT
  $8291,2 Handler for IT
  $8293,2 Handler for ONE
  $8295,2 Handler for PRINT
  $8297,2 Handler for NOPRINT
  $8299,2 Handler for LOAD
  $829B,2 Handler for SAVE
  $829D,2 Handler for QUIT
  $829F,2 Handler for HELP
  $82A1,2 Handler for SCORE
  $82A3,2 Handler for PAUSE

@ $78B7 label=COPY_VERB_ON
c $78B7 Give the frame at IY the verb of the frame at IX
D $78B7 Keeping its own ALL bit. In some cases it also moves the frame's own phrase to second place and borrows the first phrase and the adverb from the frame before; exactly when is not yet worked out.
  $78B8,17 The verb, keeping this frame's own ALL bit
  $78CA,10 Not yet worked out

@ $789F label=FRAME_BELOW
c $789F Step IY down one frame
  $78A0,5 24 bytes down

@ $6F30 label=PUNCTUATION_TOKEN
c $6F30 A full stop, comma or quote is a token by itself
D $6F30 And each takes the class of a word: a full stop $B0, the same as THEN, and a comma $A0, the same as AND -- so TAKE THE MAP. GO EAST and TAKE THE MAP, THE KEY parse exactly as their spelled-out forms. A quote is $90. Returns Z if it was one of the three.
  $6F30,6 Full stop: $B0, as THEN
  $6F36,6 Comma: $A0, as AND
  $6F3C,5 Quote: $90; anything else is not punctuation
  $6F41,6 Step past it; A = the class, and no word

@ $6FBA label=LETTERS_AGREE
c $6FBA Does the typed word agree with the candidate?
D $6FBA Letter for letter, over the shorter of the two -- which is what lets TOKENISE take a typed word as an abbreviation.
R $6FBA O:F Z if they agree
  $6FBA,11 B = the shorter of the two lengths
  $6FC5,13 Compare that many letters

# --------------------------------------------------------------------------
# The end of a turn: timers
# --------------------------------------------------------------------------

@ $96B3 label=END_OF_TURN
c $96B3 Let the other characters act, then count the timers down
D $96B3 Calls $A9D6 and $980E -- the rest of the world's turn, not yet worked out -- and then walks TIMERS. A timer whose count is zero is not running. One that is running counts down by one a turn; on reaching zero it runs its routine, and in the turns before that, while the count is no more than its warning span, it runs its warning routine instead.
D $96B3 Only one timer fires in a turn. A second one to reach zero in the same turn is held at a count of 1 and fires in the next, so two events never land on the player at once.
  $96BA,6 The characters' turn, not yet worked out
  $96C0,11 Nothing has fired yet this turn; printing on
  $96CB,4 IY = the first timer
  $96CF,7 $FF ends the table
  $96D6,7 A count of zero: not running
  $96DD,8 Count down, and go on to the warning test unless it reached zero
  $96E5,10 Already had one fire this turn? Hold this one at 1 until the next
  $96EF,4 Count one fired
  $96F3,11 Run its routine through $9B6C
  $96FE,7 No warning span: nothing to do
  $9705,5 Is the count within the warning span?
  $970A,9 Then run the warning routine
  $9713,8 On to the next 7-byte timer
  $971B,5 Printing on

@ $9B6C label=RUN_ROUTINE
c $9B6C Call the routine at HL, if there is one
D $9B6C Keeps every register pair the caller has, IX and IY included, and does nothing for an address of zero.
R $9B6C I:HL The routine, or 0
  $9B73,5 HL not zero? Call it through $9B80

@ $9B80 label=JUMP_HL
c $9B80 Jump to HL
D $9B80 The one-byte target that RUN_ROUTINE calls, so that a routine held in HL can be called and return.

@ $CA84 label=TIMERS
b $CA84 The timers END_OF_TURN counts down
D $CA84 Ten 7-byte entries, ending at $FF: byte 0 is the timer's length in turns, and starting it is copying that into byte 1, the count -- WINE_DRUNK does exactly that for timer 7, and timer 9 restarts itself the same way. Bytes 2 and 3 are the routine to run when the count reaches zero. Byte 4 is how many turns before then to warn, and bytes 5 and 6 the routine to warn with. All of them are reached through $9B80's JP (HL).
D $CA84 This table and what follows it, $BF bytes in all, are copied aside by START and copied back on every new game; SAVE and LOAD take the same $BF bytes.
B $CA84,7,7 Timer 0, 2 turns: the barrel reaches the long lake (#R$A5FB); started by BARREL_THROWN
B $CA8B,7,7 Timer 1, 2 turns: the broken web is mended (#R$AA5C); started by WEB_BROKEN
B $CA92,7,7 Timer 2, 5 turns: the web smothers anyone still in it (#R$AB10)
B $CA99,7,7 Timer 3, 2 turns: the goblins' door shuts (#R$A4D9); started by GOBLINS_DOOR_OPENED
B $CAA0,7,7 Timer 4, 2 turns: the deep bog, warning every turn (#R$A7AA)
B $CAA7,7,7 Timer 5, 4 turns: the magic door opens a turn before it closes (#R$AAB3, #R$AAD5); started by MAGIC_DOOR_EXAMINED
B $CAAE,7,7 Timer 6: the ring slips off (#R$AAE0); started by WEAR_RING at 2 to 10 turns, and run early by timer 5's warning
B $CAB5,7,7 Timer 7, 5 turns: the wine wears off (#R$AB0B)
B $CABC,7,7 Timer 8, 4 turns: the eyes in the forest (#R$AB1F, #R$AB3A)
B $CAC3,7,7 Timer 9, 5 turns: the hole in the mountain's side (#R$AA91, #R$AA74)
B $CACA,1,1 End of the timers

@ $AB0B label=WINE_WEARS_OFF
c $AB0B Timer 7: the wine wears off
D $AB0B Clears DRUNK, five turns after WINE_DRUNK set it and started this timer.
  $AB0B,4 No longer drunk

@ $A5FB label=BARREL_REACHES_LAKE
c $A5FB Timer 0: the barrel is thrown up on the long lake
D $A5FB Two turns after it is started, the barrel goes to location 34, the long lake, and anything in it goes with it -- the player too, who is told so and arrives there. Then it is emptied, with printing off, so that what spills is not reported; and the wine is put back into a barrel in location 32, the elvenking's cellar.
  $A5FB,4 Only one timer fires in a turn
  $A5FF,11 In the barrel ($13)? "you are thrown onto the bank of the long lake."
  $A60A,5 The barrel is at location 34 now
  $A60F,6 ... and so is everything in it
  $A615,16 The barrel: at the lake; flag bit 5 (seen into) off, bit 2 on
  $A625,14 Empty it with printing off
  $A633,13 The wine: back in location 32, held by the barrel

@ $AA5C label=WEB_CHANGES
c $AA5C Timer 1: the broken web is mended
D $AA5C Two turns after WEB_BROKEN: clears the web's flag bits 3 (broken) and 5 (can be seen through), doubles its byte 5, and gives it back SPIDER as the adjective in its name. Not yet seen in play.
  $AA5C,16 Flags and byte 5
  $AA6C,7 Its name

@ $AB10 label=WEB_SMOTHERS
c $AB10 Timer 2: the spider web smothers the player
D $AB10 Only if the player is still at location 26, the spider threads place: "the spider web is slowly smothering you", and PLAYER_DIES.
  $AB10,6 Not at location 26? Nothing happens
  $AB16,9 Say so and die

@ $A4D9 label=GOBLINS_DOOR_SHUTS
c $A4D9 Timer 3: the goblins' door shuts
D $A4D9 Clears bit 5 of the goblins' door's flags -- the bit that lets it be seen through, which a door has while it is open.

@ $A7AA label=SINKING_IN_BOG
c $A7AA Timer 4: sinking into the deep bog
D $A7AA Timer 4's routine for both its warning and its end. Standing in location 29, the deep bog, stops the timer; either way "you are slowly sinking into the bog", and if the timer has stopped, whether by running out or by the player being in the bog, PLAYER_DIES.
  $A7AA,11 In the bog? Stop the timer
  $A7B5,6 "you are slowly sinking into the bog."
  $A7BB,9 Stopped: dead

@ $AAB3 label=MAGIC_DOOR_OPENS
c $AAB3 Timer 5's warning: the magic door opens and an elf sweeps past
D $AAB3 Sets bit 5 of the magic door's flags, reports it to a player in either of its rooms, and goes on to timer 6's routine.
  $AAB3,5 Open
  $AAB8,6 "the magic door opens."
  $AABE,6 "an elf sweeps past."

@ $AAC7 label=AT_MAGIC_DOOR
c $AAC7 Print the message at HL if the player is by the magic door
D $AAC7 That is, at location 30 or location 28, the two rooms the door is in.
R $AAC7 I:HL A message

@ $AAD5 label=MAGIC_DOOR_CLOSES
c $AAD5 Timer 5: the magic door closes
  $AAD5,5 Shut
  $AADA,6 "the magic door closes."

@ $AAE0 label=RING_CHECK
c $AAE0 Timer 6: the ring slips off
D $AAE0 WEAR_RING starts this timer at a random 2 to 10 turns, so the ring's invisibility never lasts. When it runs out -- or when the magic door opens and the elf sweeps past, whose warning comes here too -- whoever has the ring and is invisible takes it off, through TAKE_OFF_RING.
  $AAE0,10 Nobody has the ring: nothing to do
  $AAEA,7 The holder is the actor
  $AAF1,7 Invisible? Then it comes off

@ $AB1F label=EYES_WARNING
c $AB1F Timer 8's warning: pale eyes in the forest
D $AB1F "you see some pale bulbous eyes staring at you." Then, unless the player is where $B6F3 says or at the other of the forest road and the forest (locations 2 and 3), something drops and stings, fatally, as in EYES_STING. What sets $B6F3 is not yet traced.
  $AB1F,6 "you see some pale bulbous eyes staring at you."
  $AB25,9 At $B6F3's location: safe
  $AB2E,10 A = 2, or 3 if $B6F3 is 2: safe there too
  $AB38,2 Anywhere else: stung

@ $AB3A label=EYES_STING
c $AB3A Timer 8: stung in the forest
D $AB3A A player still at location 2 or 3, the forest road or the forest, sees the eyes, is stung by something dropping from above, and dies.
  $AB3A,10 Not at location 2 or 3? Nothing happens
  $AB44,6 "you see some pale bulbous eyes staring at you."
  $AB4A,9 "some thing drops from above and stings.", and dead

@ $AA91 label=SIDE_DOOR_APPEARS
c $AA91 Timer 9's warning: a hole appears in the mountain's side
D $AA91 Makes the side door visible -- it is one of the two objects in the game that start without flag bit 7 -- and tells a player at location 42, the side door.
  $AA91,5 The side door can be seen now
  $AA96,9 At location 42? "there is a loud crack and a hole appears..."

@ $AA74 label=SIDE_DOOR_VANISHES
c $AA74 Timer 9: the hole vanishes again
D $AA74 Unless the door has been opened (flag bit 5), the timer is started again and the door hidden, so the hole comes and goes every five turns until somebody opens it.
  $AA74,6 Opened? Then it stays
  $AA7A,6 Start the timer again
  $AA80,5 Hidden
  $AA85,12 At location 42? "the hole vanishes."

@ $9BDD label=MOVE_CONTENTS
c $9BDD Move everything inside an object to a location
D $9BDD Everything held by the object in A, at any depth, goes to location B through MOVE_HELD. If the player was among it, the move is played out for them: MOVE's own step at $8E12 puts them there, with the sentence made about the player for the length of it, and $9B02 follows.
R $9BDD I:A The object
R $9BDD I:B The location
  $9BDD,8 Say the player is not among it, and move it all
  $9BE5,3 Not among it: done
  $9BE9,6 Nowhere? Nothing more to do
  $9BEF,18 The sentence is about the player for now
  $9C01,10 Move the player there
  $9C0B,8 Put the sentence back

@ $9C17 label=MOVE_HELD
c $9C17 Put everything held by object A in location B
D $9C17 Recursively, so what is inside those goes too; if one of them is the player, $9BDC is cleared to say so.
  $9C1F,10 Next object held by A
  $9C29,3 Its location becomes B
  $9C2C,10 The player? Note it
  $9C36,3 And the same for what it holds

@ $9D53 label=EMPTY_OUT
c $9D53 Empty an object into whatever holds it
D $9D53 Everything held by the object in A passes to the object's own holder, except liquids (flag bit 1): those are poured away -- nowhere, held by nothing, not visible -- with a message.
R $9D53 I:A The object
  $9D58,6 B = its holder
  $9D62,10 Next object held by A
  $9D6C,6 A liquid?
  $9D72,25 Poured away
  $9D8B,6 Anything else goes to the holder

@ $6C00 label=START
c $6C00 The game's entry point
D $6C00 Reached by PRINT USR 27648. It first copies the whole of the game's changeable state aside -- the objects to $F400, the rooms straight after them, the variables at $B6EB and the TIMERS block to $5F00 -- and every new game at $6C27 copies it back, which is how dying and starting again restores the world as it was loaded.
  $6C01,19 The objects and the rooms, to $F400 onwards
  $6C14,19 The variables and the timers, to $5F00 onwards
  $6C27,4 A new game starts here
  $6C2B,20 Not yet worked out: zeroes two bytes found through picture 5's entry
  $6C3F,38 Copy the saved state back

# --------------------------------------------------------------------------
# The other characters: scripts
# --------------------------------------------------------------------------

@ $A9D6 label=CHECK_WON
c $A9D6 Has the player won?
D $A9D6 The first thing END_OF_TURN does. The game is won when the valuable treasure, object $23, is held by the wooden chest, object $25 -- byte 1 of the treasure's record. Then a cheering crowd of dwarves, hobbits and elves carries the player off into the sunset, and the game waits for a key and starts again, through the tail of PLAYER_DIES.
  $A9D6,6 The treasure not in the chest? Play on
  $A9DC,9 "a cheering crowd of dwarves, hobbits and elves appears..."; wait and start again

@ $980E label=CHARACTERS_ACT
c $980E Every other character takes its turn
D $980E Walks CHARACTERS and runs each character's script until it has done something. Each instruction is an action the character tries, as if it had typed a sentence: the action code and its objects go into $B6E7-$B6E9 exactly as the parser puts them for the player, and $99C6 carries it out through the same ACTION_TABLE. So Thorin opens a door by the same code the player does.
D $980E A step that is refused moves on to the next, or to a fallback of its own, and the script goes on; a step that succeeds ends the character's turn. Six refusals in a row end it too. What a character does is printed only when the player can see it.
D $980E An order comes first. Whatever the player has told a character to do (see ORDERS) replaces its script's step for the turn, unless the step has bit 6 set, which makes it one that cannot be interrupted.
  $980E,3 Not yet worked out
  $9811,4 IY = the first character
  $9815,4 No steps refused yet
  $9819,8 $FF ends the table
  $9821,5 An empty slot
  $9826,13 The sentence is about this character: its number, its record, and its location in $B6F6
  $9833,4 Printing off
  $9837,16 Can the player see it (IN_REACH_OF, the other way round)?
  $9847,33 Then print what it does -- unless the player is in the dark ($980C, set by NOTE_LIGHT): then the first one is only heard, "you hear a noise.", and nothing is printed
  $9868,8 Held by something? Try to get out (CAPTIVE)
  $9870,15 $B6F4 = 1 if it has an order waiting
  $987F,6 HL = where its script has got to
  $9885,7 Six steps refused: its turn is over
  $988C,7 IX = the instruction
  $9893,6 Opcodes 5 and up
  $9899,38 An order, and this step may be interrupted (bit 6 clear)? Take the order and carry it out, and that is its turn
  $98BF,12 Opcode 4: an action with no objects, or a jump; 0 to 3: an action with objects, or a routine
  $98CB,18 $0E: go to the address that follows, and carry on
  $98DD,15 $0C: switch to the script its table keys under the byte that follows
  $98EC,9 $0F: switch to one of its scripts at random
  $98F5,7 Never taken: A is at least 5 here
  $98FC,5 Anything else: back to its first script, and its turn is over
  $9901,8 On to the next 7-byte slot
  $9909,15 Done: the sentence is about the player again, and printing on

@ $9918 label=STEP_PAST
c $9918 Move a character's script past this instruction
D $9918 By DE bytes, and two more if the instruction has a fallback (bit 4).
R $9918 I:HL The instruction
R $9918 I:DE Its length without a fallback
R $9918 I:IY The character's slot
  $9918,1 Past the instruction
  $9919,8 And its fallback, if it has one
  $9921,7 Save the new place in the slot

@ $9928 label=SCRIPT_DO
c $9928 A script step: an action with objects, or a routine
D $9928 Four bytes, then a 2-byte fallback if bit 4 is set. With bit 0 clear they are the action code and its two objects, tried as the character's own sentence. With bit 0 set, bytes 1 and 2 are the address of a routine instead: it is run once with printing off as a test, and only if it reports success by setting $B6FB is it run again for real.
D $9928 A step that succeeds with bit 5 set takes the character out of the story: its slot is emptied and it never acts again.
  $9928,3 Step past it
  $992B,6 A routine?
  $9931,18 The action and its two objects
  $9943,7 Try it: done, or refused
  $994A,29 The routine: run it quietly, and if it succeeded, again for real
  $9967,13 Done. Bit 5: the character's part is over

@ $9974 label=SCRIPT_BARE
c $9974 A script step: an action with no objects, or a jump
D $9974 Two bytes, then a 2-byte fallback if bit 4 is set. Byte 1 is an action code, tried with neither object -- RUN, say, which carries the character off in some direction. An action code of $FF does nothing and ends the character's turn: a pause, with the script going on at the next step next turn -- or, with a fallback, at the fallback, which makes it a jump. The warg's one script ends that way, a pause before going round again.
D $9974 A refused step, of either kind, comes here at $99AA: count it, and go on at the fallback if there is one, or the next step if not.
  $9974,6 Step past it
  $997A,5 $FF: a pause or a jump
  $9981,19 The action alone: done, or refused
  $9994,22 Jump to the fallback, if there is one; either way that is the turn
  $99AA,4 Refused: count it
  $99AE,7 No fallback? On to the next step
  $99B5,17 Otherwise on at the fallback

@ $99C6 label=ACTOR_TRIES
c $99C6 A character tries the action in $B6E7-$B6E9
D $99C6 Checked by $7AF5 first, as the player's sentences are; then carried out by $950F, and the player is told of anyone who has just come into view -- "... enters." for the actor, "... appears." for the second object, through $9ACD. $99CE is the way in for an order the character was given, skipping the check.
R $99C6 O:F NZ if it was done, Z if it was refused
  $99C6,8 Refused by the check: Z
  $99CE,7 $B6FE set? Straight to doing it
  $99D5,16 Going through something, away from the player: straight to doing it
  $99E5,77 Not yet worked out: two ways into $712B
  $9A32,3 Do it
  $9A35,12 The actor has come into the player's view? "... enters."
  $9A41,19 The second object too? "... appears."
  $9A54,2 Done: NZ

@ $9ACD label=ANNOUNCE_ARRIVAL
c $9ACD Tell the player an object has just come into view
D $9ACD Prints the message at DE with the object's name if the object is now where the player is and was not before -- HL points at where it was.
R $9ACD I:A The object
R $9ACD I:HL Where it was
R $9ACD I:DE The message

@ $9A59 label=SCRIPT_RANDOM
c $9A59 Opcode $0F: switch to one of a character's scripts at random
D $9A59 A random number, limited by the lesser of the operand and slot byte 1 picks from the start of the character's script table; this is how Gandalf and the others wander without a fixed route. $9A68 picks entry E instead, and opcodes with no meaning of their own come in there with E = 0.
  $9A59,11 The lesser of the operand and the character's own limit
  $9A64,4 A random number within it
  $9A68,7 No further than the character's own limit
  $9A6F,21 The script its table has at that place

@ $9A85 label=FIND_CHARACTER
c $9A85 Find a character's slot
R $9A85 I:A The character
R $9A85 O:IY Its slot in CHARACTERS, or the $FF that ended it

@ $9AA0 label=REACT
c $9AA0 Switch a character to the script it keeps for an action
D $9AA0 Looks the action up in the character's own script table with FIND_RECORD, and if it has a script for it, sends the character there. The script opcode $0C uses it, and so does $95DF: whenever an action is done to a character, it reacts. That is what the entries after the first few in each table are for -- Gandalf's and Thorin's have scripts for being given something ($1D), captured ($30) and attacked ($0F).
R $9AA0 I:A The character
R $9AA0 I:B The action
  $9AA4,7 Not in CHARACTERS: nothing to do
  $9AAB,17 Its script for this action, if it has one
  $9ABC,12 Go there

@ $95DF label=REACT_TO_ACTION
c $95DF An action has been done to this object: if it is a character, it reacts
D $95DF Only a character (flag bit 6), and only one without flag bit 3, which is not yet worked out.

@ $9B16 label=CAPTIVE
c $9B16 A character held by something tries to get out
D $9B16 A character held by another character, or by something with flag bit 3, goes on with its script as usual. Held by something closed -- flag bit 5 clear, not to be seen into -- it can do nothing. Otherwise it tries action $37, CLIMB OUT OF, on what holds it.
  $9B16,11 The holder is the object
  $9B21,17 Held by a character, or by something with flag bit 3: carry on with the script
  $9B32,7 Shut in: nothing this turn
  $9B39,11 Try to climb out

@ $7EFF label=FIND_ORDER
c $7EFF Find an order waiting for the character in $B6EA
R $7EFF O:HL Its slot in ORDERS
R $7EFF O:F Z if there is one

@ $7F10 label=HAS_ORDER
c $7F10 Is there an order waiting for the character in $B6EA?
R $7F10 O:F Z if there is one

@ $7F1A label=TAKE_ORDER
c $7F1A Take the order waiting for a character, and parse it
D $7F1A Frees the slot, then parses the command kept in it the way the player's own commands are parsed, leaving the action and its objects in $B6E7-$B6E9 for ACTOR_TRIES.
  $7F22,5 Free the slot

@ $B738 label=ORDERS
b $B738 What the player has told the other characters to do
D $B738 Eight 25-byte slots, each the number of the character it is for followed by the command it was given, kept until the character's next turn. CHARACTERS_ACT carries out an order before the character's own script. START clears all 200 bytes.
B $B738,200,25

@ $9CA8 label=RANDOM
c $9CA8 A random number from -A to A
D $9CA8 Mixes the last result, kept at $B70E and seeded from R by START, with the byte the pointer at $B712 has got to -- it steps on by one every call -- and one DE bytes past it, and draws again if that repeats the last result. The byte is then halved until it is no more than twice A, and A taken off.
D $9CA8 Measured over 3000 calls each, through RANDOM_POSITIVE: every value from 0 to A comes up, but not evenly -- for A = 4 the ends come up half as often as the middle, and for A = 9 the top three do.
R $9CA8 I:A The limit, 0 to 127
R $9CA8 O:A The result, -A to A
  $9CAB,8 B = twice the limit, or $FF if that overflows
  $9CB3,12 Step the pointer on
  $9CBF,20 Mix two bytes from there into the last result
  $9CD3,6 The same as last time? Draw again; otherwise keep it
  $9CD9,10 Halve it until it is no more than B
  $9CE3,1 Take the limit off
@ $9C9F label=RANDOM_POSITIVE
c $9C9F A random number from 0 to A
D $9C9F RANDOM, with the sign dropped.

@ $9F82 label=LOCATION_OF
c $9F82 Where an object is, if it is in only one place
R $9F82 I:A The object, or $FF
R $9F82 O:A Its location; $FF if it is in several, or for $FF

@ $CACB label=CHARACTERS
b $CACB The characters' scripts: where each has got to
D $CACB Seventeen 7-byte slots, ending at $FF. Byte 0 is the character, or 0 for a slot not in use -- three are empty at the start, and a character whose part is over (see SCRIPT_DO) empties its own. Byte 1 is how many of its scripts SCRIPT_RANDOM may choose among. Bytes 2 and 3 are the instruction its script has got to; bytes 4 and 5 are its script table, a FIND_RECORD table whose entries keyed 0 are its ordinary scripts and whose others are its reactions (see REACT). Byte 6 is how many of the player's orders it will take at once (see DO_TALK): Thorin 6, Gandalf and Elrond 5, Gollum 3, the wood elf and the trolls 1, and the warg and the goblins 0, never.
D $CACB The scripts themselves are in $C82D-$CA7F. An instruction's low four bits are its opcode: 0 to 3 as SCRIPT_DO, 4 as SCRIPT_BARE, $0C, $0E and $0F as CHARACTERS_ACT says, and anything else sends the character back to its first script. Bit 4 means a 2-byte fallback follows, bit 5 that the character leaves the story when the step succeeds, and bit 6 that an order cannot interrupt it.
B $CACB,7,7 Gandalf
B $CAD2,7,7 Thorin
B $CAD9,7,7 The wood elf
B $CAE0,7,7 The vicious warg
B $CAE7,7,7 Empty at the start
B $CAEE,7,7 Elrond
B $CAF5,7,7 Gollum
B $CAFC,7,7 Empty at the start
B $CB03,7,7 Empty at the start
B $CB0A,7,7 The hideous troll
B $CB11,7,7 The vicious troll
B $CB18,7,7 The nasty goblin
B $CB1F,7,7 The hideous goblin
B $CB26,7,7 The vicious goblin
B $CB2D,7,7 The horrible goblin
B $CB34,7,7 The mean goblin
B $CB3B,7,7 The disgusting goblin
B $CB42,1,1 End of the characters

@ $AB53 label=ACTION_PATTERNS
b $AB53 The sentence each action code stands for
D $AB53 Fifty-nine 8-byte patterns, ending at a zero word. The action code is the pattern's place in the list, counting from 1: $79B6 finds the one that matches the parsed sentence and works the code out from its address. Each is a verb, a particle and a preposition as word references, then two more bytes; for the ten directions the first word is the direction and the last is GO, so that NORTH and GO NORTH are the same action. The top bits of the references and the last two bytes of the others are flags, not yet worked out.
D $AB53 So this is also the key to ACTION_TABLE and to every action code in the characters' scripts: $10 is OPEN, $13 TAKE, $1D GIVE TO, $24 RUN, $30 CAPTURE, $37 CLIMB OUT OF.
B $AB53,472,8
  $AB53,8 1 ($01): GO NORTH
  $AB5B,8 2 ($02): GO SOUTH
  $AB63,8 3 ($03): GO EAST
  $AB6B,8 4 ($04): GO WEST
  $AB73,8 5 ($05): GO NORTHEAST
  $AB7B,8 6 ($06): GO NORTHWEST
  $AB83,8 7 ($07): GO SOUTHEAST
  $AB8B,8 8 ($08): GO SOUTHWEST
  $AB93,8 9 ($09): GO UP
  $AB9B,8 10 ($0A): GO DOWN
  $ABA3,8 11 ($0B): STRIKE WITH
  $ABAB,8 12 ($0C): CLOSE
  $ABB3,8 13 ($0D): DROP
  $ABBB,8 14 ($0E): DROP IN
  $ABC3,8 15 ($0F): ATTACK WITH
  $ABCB,8 16 ($10): OPEN
  $ABD3,8 17 ($11): PUT IN
  $ABDB,8 18 ($12): PUT ON
  $ABE3,8 19 ($13): TAKE
  $ABEB,8 20 ($14): TAKE OUT OF
  $ABF3,8 21 ($15): TAKE FROM
  $ABFB,8 22 ($16): TAKE OFF
  $AC03,8 23 ($17): LOOK
  $AC0B,8 24 ($18): LOOK THROUGH
  $AC13,8 25 ($19): LOOK ACROSS
  $AC1B,8 26 ($1A): INVENTORY
  $AC23,8 27 ($1B): EAT
  $AC2B,8 28 ($1C): EXAMINE
  $AC33,8 29 ($1D): GIVE TO
  $AC3B,8 30 ($1E): GO THROUGH
  $AC43,8 31 ($1F): ENTER
  $AC4B,8 32 ($20): GO INTO
  $AC53,8 33 ($21): DRINK
  $AC5B,8 34 ($22): EMPTY
  $AC63,8 35 ($23): FILL WITH
  $AC6B,8 36 ($24): RUN
  $AC73,8 37 ($25): LOCK WITH
  $AC7B,8 38 ($26): UNLOCK WITH
  $AC83,8 39 ($27): FOLLOW
  $AC8B,8 40 ($28): WEAR
  $AC93,8 41 ($29): THROW
  $AC9B,8 42 ($2A): THROW AT
  $ACA3,8 43 ($2B): THROW ACROSS
  $ACAB,8 44 ($2C): THROW THROUGH
  $ACB3,8 45 ($2D): BURN
  $ACBB,8 46 ($2E): TIE TO
  $ACC3,8 47 ($2F): CUT
  $ACCB,8 48 ($30): CAPTURE
  $ACD3,8 49 ($31): PULL
  $ACDB,8 50 ($32): SWIM
  $ACE3,8 51 ($33): UNTIE
  $ACEB,8 52 ($34): CLIMB
  $ACF3,8 53 ($35): TALK TO
  $ACFB,8 54 ($36): CLIMB INTO
  $AD03,8 55 ($37): CLIMB OUT OF
  $AD0B,8 56 ($38): JUMP ONTO
  $AD13,8 57 ($39): DIG
  $AD1B,8 58 ($3A): SHOOT
  $AD23,8 59 ($3B): CARRY
B $AD2B,2,2
  $AD2B,2 End of the patterns

# --------------------------------------------------------------------------
# Carrying an action out
# --------------------------------------------------------------------------

@ $950F label=DO_ACTION
c $950F Carry out the action in $B6E7-$B6E9, for whoever is acting
D $950F The one place every action is done, the player's and every other character's alike. The action is refused outright if it makes no sense (SENSIBLE), and in the dark it can only be done to what the actor is carrying. Then the objects get the first say: an object can carry a handler of its own for an action (see FIND_OBJECT_HANDLER), and only if neither has one does ACTION_TABLE's ordinary handler run. For most actions the first object is asked; for the five in SECOND_FIRST -- DROP IN, PUT IN, PUT ON, TAKE OUT OF and THROW THROUGH -- the second object is asked first, since it is the container or the gap that decides.
D $950F A handler is followed by any records after it keyed 0, which run too: the wine's record has the ordinary handler for DRINK followed by WINE_DRUNK under key 0, so drinking it does both. Last, each object that is a character reacts to what was done to it (REACT_TO_ACTION).
  $9513,6 Makes no sense? "i cannot do that."
  $9519,5 Can the actor see?
  $951E,19 In the dark, only what the actor carries -- and nothing at all while $B711 is set
  $9531,8 "i see nothing here."
  $9539,16 $B6FE set, or no object: the ordinary handler
  $9549,15 The first object, in $B708: not being carried by somebody else
  $9558,7 No second object: ask the first
  $955F,7 $B6FF set: the ordinary handler
  $9566,15 The second object, in $B70A: not being carried by somebody else
  $9575,5 One of SECOND_FIRST? Ask the second object
  $957A,4 Otherwise the first
  $957E,8 Does it have a handler of its own for this? If not, the ordinary one
  $9586,21 Run the handler, and every record after it keyed 0
  $959B,7 Done quietly, as a test? Then that is all
  $95A2,13 Not yet worked out: for the player in the dark, a message at HL
  $95AF,24 Each object that is a character reacts
  $95CC,14 The ordinary handler, from ACTION_TABLE
  $95DA,5 "i cannot do that."

@ $A1D0 label=IS_SECOND_FIRST
c $A1D0 Is the action one where the second object is asked first?
R $A1D0 O:F Z if the action in $B6E7 is in SECOND_FIRST
@ $A20B label=SECOND_FIRST
b $A20B The actions whose second object is asked first
D $A20B DROP IN, PUT IN, PUT ON, TAKE OUT OF and THROW THROUGH (see ACTION_PATTERNS): in each the second object is what the first goes into, onto, out of or through.
B $A20B,5,5

@ $9B44 label=SENSIBLE
c $9B44 Does the action make sense?
D $9B44 No if the actor would be doing it to itself, as either object, or doing it to one object with itself; $B6FE and $B6FF waive the checks, and what sets them is not yet traced. An action with no object always makes sense.
R $9B44 O:F Z if it makes no sense
  $9B44,8 No object: fine
  $9B4C,19 Unless $B6FE is set: not to itself, and not an object with itself
  $9B5F,13 Unless $B6FF is set: the second object not itself either

@ $9728 label=CARRIED_BY_ANOTHER
c $9728 Is somebody else carrying this object?
D $9728 Only asked for the player. If a character holds the object, the player is told so -- "the ... is carrying ...", with the two names -- and it cannot be acted on. Something the player has, however deep, and something held by a non-character, are fine.
R $9728 I:A The object, or $FF
R $9728 O:F NZ if another character has it
  $9731,10 Only for the player
  $973B,11 Held by nothing: fine
  $9746,10 Held, at any depth, by the player: fine
  $9750,16 Its holder a character, and $C122 bit 7 set?
  $9760,22 Then "the ... is carrying ..."

@ $9C78 label=ACTOR_HAS_FIRST
c $9C78 Is the first object the actor's, or no object at all?
D $9C78 $9C7B asks the same of the object in A, and $9C8A does the climbing: up through the holders until one is the actor or there are none.
R $9C78 O:F C if so

@ $72CE label=CANNOT_DO
c $72CE "i cannot do that."

# --------------------------------------------------------------------------
# Arriving somewhere
# --------------------------------------------------------------------------

@ $C78E label=ARRIVAL_HOOKS
b $C78E What happens when the player arrives in certain places
D $C78E A FIND_RECORD table keyed by location, of routines MOVE runs when the player gets there. Most start one of TIMERS, which is how a place can be deadly only after a few turns in it.
B $C78E,3,3 Location 22, Beorn's house: #R$C7A4
B $C791,3,3 Location 26, the spider threads place: #R$C7B2
B $C794,3,3 Location 29, the deep bog: #R$C7B9
B $C797,3,3 Location 33, the forest river: #R$C7EA
B $C79A,3,3 Location 2, the forest road: #R$C7DD
B $C79D,3,3 Location 3, the forest: #R$C7DD
B $C7A0,3,3 Location 32, the elvenking's cellar: #R$C7C0
B $C7A3,1,1 End of the table

@ $C7A4 label=AT_BEORNS_HOUSE
c $C7A4 Arriving at Beorn's house: the butler joins in
D $C7A4 Unless the butler has flag bit 3 -- the bit that also keeps a character from reacting, and looks like being dead -- it is given the empty CHARACTERS slot at $CAE7 and made visible.

@ $C7B2 label=AT_SPIDER_THREADS
c $C7B2 Arriving at the spider threads place: start timer 2
D $C7B2 Five turns later WEB_SMOTHERS kills a player still there.

@ $C7B9 label=AT_DEEP_BOG
c $C7B9 Arriving in the deep bog: start timer 4
D $C7B9 SINKING_IN_BOG does the rest.

@ $C7C0 label=AT_ELVENKINGS_CELLAR
c $C7C0 Arriving in the elvenking's cellar
D $C7C0 Starts timer 9, the hole in the mountain's side, at three turns rather than its usual five; and brings the dragon and Bard into the story, each unless it has flag bit 3, by giving them the empty CHARACTERS slots at $CB03 and $CAFC.

@ $C7DD label=IN_THE_FOREST
c $C7DD Arriving on the forest road or in the forest: the eyes
D $C7DD Keeps the place the player came into the forest by in $B6F3 -- the one EYES_WARNING counts as safe -- and starts timer 8.

@ $C7EA label=AT_FOREST_RIVER
c $C7EA Arriving at the forest river
D $C7EA Out of the barrel, the player is swept against the portcullis and dies: "you are swept forcefully against the portcullis." In it, nothing happens here.

@ $8D6E label=VISIT_SCORES
b $8D6E The score for reaching each place
D $8D6E A FIND_RECORD table keyed by location, of the points MOVE adds to the score at $B6F7 the first time the player gets there -- the first time being told by bit 6 of byte 0 of the room's record, which MOVE sets. Fourteen places, 750 points between them, 200 of those for the lower halls.
B $8D6E,42,3
B $8D98,1,1 End of the table

# --------------------------------------------------------------------------
# What changes from game to game: a closed road and Gollum's riddle
# --------------------------------------------------------------------------

@ $97AD label=NEW_GAME_CHOICES
c $97AD Make the choices that differ from one game to the next
D $97AD Called by START for every new game. One of HIDDEN_ROADS is picked at random and its exit wiped from the room, so a different way is shut each time until Elrond reads the curious map (ELROND_READS_MAP); and one of RIDDLES is picked for Gollum.
  $97AD,10 The player acts; the map not yet read ($B6F1); no riddle asked yet ($B6F9)
  $97B7,6 The player's record
  $97BD,18 IY = one of HIDDEN_ROADS at random
  $97CF,4 Kept in the operand of ELROND_READS_MAP's LD IY
  $97D3,13 Wipe that exit: all three bytes zero, so no direction matches it
  $97E0,19 And one of RIDDLES at random, in $B6EE

@ $C7FC label=RIDDLES
b $C7FC Gollum's riddles
D $C7FC Four entries, each the answer as a word reference and then the riddle as a message. There are only two riddles, each in the table twice; NEW_GAME_CHOICES picks among all four with RANDOM_POSITIVE given 3, which comes up with the four about equally, so the two riddles are even.
B $C7FC,4,4 NIGHT: "it cannot be seen, cannot be felt, cannot be heard, cannot be smelt..."
B $C800,4,4 MAN: "which is the animal that has four feet in the morning, two at midday and three in the evening ?"
B $C804,4,4 NIGHT again
B $C808,4,4 MAN again
B $C80C,2,2 Not yet worked out

@ $C80E label=HIDDEN_ROADS
b $C80E The ways one of which is shut at the start of each game
D $C80E Six bytes each: the location, the address of one of its exits in the room records, and that exit's three bytes -- direction, the object it goes through, and destination -- kept here so that ELROND_READS_MAP can put them back. NEW_GAME_CHOICES picks one with RANDOM_POSITIVE given 4, so any of the five can be shut, the first and last half as often as the other three.
B $C80E,6,6 Beorn's house, north to the great river
B $C814,6,6 The forest gate, east to the bewitched gloomy place
B $C81A,6,6 The treeless opening, west to outside the goblins' gate
B $C820,6,6 The long lake, east to lake town
B $C826,6,6 The misty mountain, east to the narrow place
B $C82C,1,1 End of the table

@ $A7C4 label=ELROND_READS_MAP
c $A7C4 The curious map's own EXAMINE: Elrond reads it
D $A7C4 Anyone but Elrond examining the map gets the ordinary EXAMINE. Elrond puts back the road NEW_GAME_CHOICES shut -- unless $B6F1 says it has been done -- and tells the way along it: "go ... from the ... to get to the ...", with the direction and the two places' names. The entry is found through the operand of the LD IY at $A7CF, which NEW_GAME_CHOICES writes.
  $A7C4,8 Not Elrond: the ordinary EXAMINE
  $A7CC,3 Not yet worked out
  $A7CF,10 IY = the road that was shut; HL = its exit in the room record
  $A7D9,7 Already put back? Just say the way
  $A7E0,11 Put the exit back
  $A7EB,4 IY = the road again
  $A7EF,12 The destination's name, from its room record, on the stack
  $A7FB,12 And the location's
  $A807,6 And the direction's word
  $A80D,7 "go ... from the ... to get to the ..."

@ $A8D2 label=GOLLUM_ASKS
c $A8D2 Gollum asks the player his riddle
D $A8D2 One of Gollum's script routines. Only where the player is, and only if the player can be seen: the riddle NEW_GAME_CHOICES chose is said, and $B6F9 set so that the answer is expected.
  $A8D2,8 Gollum not where the player is? Nothing
  $A8DA,6 The player not to be seen? Nothing
  $A8E0,16 Ask the riddle
  $A8F0,5 An answer is expected

@ $A8F6 label=GOLLUM_HEARS_ANSWER
c $A8F6 Gollum hears the answer to his riddle
D $A8F6 The answer has to be given to Gollum as an order -- said to him, in the ORDERS slot he takes his turn from. It is right if the answer's word reference appears anywhere in it; with no answer, or a wrong one, "someone strangles you from behind." and PLAYER_DIES.
  $A8F6,7 No longer expecting an answer
  $A8FD,5 Nothing said to him: strangled
  $A902,19 Look through what was said for the answer word
  $A915,17 "someone strangles you from behind.", and dead

# --------------------------------------------------------------------------
# What starts the timers
# --------------------------------------------------------------------------

@ $A377 label=WEB_BROKEN
c $A377 After the spider web is struck: the spiders start mending it
D $A377 The web's record has this under key 0 straight after its handler for action 11, STRIKE WITH, so it runs whenever that does (see DO_ACTION). If the blow left the web broken -- flag bit 3 -- it can now be seen through (bit 5), "some spiders start mending the broken web.", and timer 1 is started: two turns later the web is whole again.
  $A377,9 Not broken: nothing
  $A380,4 It can be seen through now
  $A384,6 Start timer 1
  $A38A,6 "some spiders start mending the broken web."

@ $A4C0 label=GOBLINS_DOOR_OPENED
c $A4C0 The goblins' door's own OPEN
D $A4C0 Only from location 16, the big goblins' cavern, where it is opened as any door is (through $910E); then timer 3 shuts it again two turns later. From its other side, the goblins' dungeon, it will not open.
  $A4C0,12 Not in the cavern: refused
  $A4CC,6 Open it
  $A4D2,6 Start timer 3

@ $A5E2 label=BARREL_THROWN
c $A5E2 After something is thrown through the trap door
D $A5E2 The large trap door's record has this under key 0 after its handler for action 44, THROW THROUGH. If what went through was the barrel, and it has landed in location 33, the forest river, timer 0 is set going: two turns later BARREL_REACHES_LAKE takes it, and anyone inside, on to the long lake.
  $A5E2,6 Not the barrel: nothing
  $A5E8,3 Not yet worked out
  $A5EB,10 Not in the forest river: nothing
  $A5F5,5 Start timer 0 at two turns

@ $A71E label=MAGIC_DOOR_EXAMINED
c $A71E The magic door's own EXAMINE
D $A71E Anyone who can be seen -- flag bit 7 -- sees "nothing special here." Anyone who cannot, sets timer 5 going: "the magic door warns of elves approaching.", and three turns later it opens for an elf to sweep past (MAGIC_DOOR_OPENS).
  $A721,14 Visible? "you see nothing special here."
  $A72F,6 Start timer 5
  $A735,6 "the magic door warns of elves approaching."

# --------------------------------------------------------------------------
# Describing where the player is
# --------------------------------------------------------------------------

@ $9630 label=DESCRIBE_ROOM
c $9630 Describe a location in full: "you are in ...", the picture, and what is there
D $9630 What MOVE does on the first visit to a place. The opening phrase is a message with a word left to fill in: bits 1-3 of byte 0 of the room's record pick it from ROOM_PREPOSITIONS, and it is written into the message at $AFFC before DESCRIBE_LOCATION prints it -- "you are in", "you are on", "you are outside" and so on.
R $9630 I:A The location
  $9631,3 Its record
  $9634,15 The word for how the player is placed there
  $9643,6 Into the message, high byte first, the way messages keep a word
  $9649,4 HL = "you are ..."
  $964D,13 Describe it, keeping IX, IY and BC

@ $BA80 label=ROOM_PREPOSITIONS
w $BA80 How the player is placed in each kind of room
D $BA80 Word references, picked by bits 1 to 3 of byte 0 of a room's record. Only five are needed: most rooms use IN, twenty ON and nine AT, and INSIDE and OUTSIDE are the two sides of the goblins' gate, locations 19 and 20. The room records follow straight on.
  $BA80,2 OUTSIDE
  $BA82,2 INSIDE
  $BA84,2 IN
  $BA86,2 ON
  $BA88,2 AT

@ $965B label=DESCRIBE_LOCATION
c $965B Print the opening message at HL and describe the location in A
D $965B Its long description if it has one, or else its name; its picture, with a wait for a key once it is drawn; then the ways out through things (EXITS_THROUGH), the open ways out (VISIBLE_EXITS), and what is there to see (YOU_SEE).
R $965B I:A The location
R $965B I:HL The opening message
  $965B,1 B = the location
  $965C,6 Its record; the opening message
  $9662,11 Its description, or its name
  $966D,4 Its picture
  $9671,7 If a picture was drawn, wait for a key
  $9678,3 New line
  $967B,4 "to the east there is ..." for each way through something
  $967F,7 "visible exits are:", and "you see :"

@ $9686 label=DESCRIPTION_OR_NAME
c $9686 Print the message at HL if there is one, or else the room's name
D $9686 $9689 prints the name alone, from the record's bytes 2 to 7, the same way an object's name is printed.
R $9686 I:HL The description, or 0
R $9686 I:F NZ if HL is not 0
R $9686 I:IX The room's record
  $9689,16 The name, which starts two bytes into the record

@ $96A8 label=DESCRIBE_BRIEFLY
c $96A8 Describe a location already visited
D $96A8 What MOVE does on coming back to a place: just its name, then the open ways out and what is there -- no opening, no description, no picture, and no doors.
R $96A8 I:A The location
  $96A8,6 Its name
  $96AE,5 New line, and the end of DESCRIBE_LOCATION

@ $9B02 label=NOTE_LIGHT
c $9B02 Note where the player is, and whether it is too dark to see
D $9B02 CHARACTERS_ACT starts with this. $B6F5 is the player's location and $980C is 1 in the dark, 0 in the light: in the dark the other characters are heard, not seen.
  $9B02,8 $B6F5 = where the player is
  $9B0A,11 $980C = 1 if too dark to see

@ $A0AE label=EXITS_OF
c $A0AE Point at a location's exits
D $A0AE IX is left three bytes short of the first exit and BC = 3, so that ADD IX,BC steps to each in turn.
R $A0AE I:A The location
R $A0AE O:IX Its record + 7
R $A0AE O:BC 3

@ $A0BA label=DIRECTION_WORD
c $A0BA The word for a direction
R $A0BA I:A The direction, 1 to 10 (bit 7 ignored)
R $A0BA O:DE Its word reference, from DIRECTION_WORDS
@ $A210 label=DIRECTION_WORDS
w $A210 The ten directions, as words
D $A210 In the order of the direction codes, 1 to 10. DIRECTION_WORD indexes from $A20E, two bytes earlier, because there is no direction 0.
  $A210,2 NORTH
  $A212,2 SOUTH
  $A214,2 EAST
  $A216,2 WEST
  $A218,2 NORTHEAST
  $A21A,2 NORTHWEST
  $A21C,2 SOUTHEAST
  $A21E,2 SOUTHWEST
  $A220,2 UP
  $A222,2 DOWN

@ $A0C8 label=EXITS_THROUGH
c $A0C8 Say where each way out through something lies
D $A0C8 For every exit of the location that goes through an object which can be seen: "to the east there is ...", or "above there is ..." and "below there is ..." for up and down, with the object's name. This is how doors appear in a description.
R $A0C8 I:A The location
  $A0CE,9 IY = the first exit
  $A0D7,6 Not through anything: skip it
  $A0DD,12 Through something that cannot be seen: skip it
  $A0E9,7 Its name, for the message
  $A0F0,6 The direction's word
  $A0F6,14 Up is "above", down "below"
  $A104,6 The rest are "to the ..."
  $A10A,9 The word, then "there is ..."
  $A113,10 Until the $FF after the last exit

@ $A124 label=NEXT_OPEN_EXIT
c $A124 Step to the next open way out
D $A124 One that goes through nothing, and has not been wiped -- NEW_GAME_CHOICES leaves a shut road with a direction of 0.
R $A124 I:IX The last exit, or EXITS_OF's pointer
R $A124 O:IX The next open exit
R $A124 O:F Z at the end

@ $A138 label=VISIBLE_EXITS
c $A138 "visible exits are:" and the open ways out
D $A138 Nothing at all is printed when there are none.
R $A138 I:A The location
  $A13E,6 Is there an open way out at all?
  $A146,6 "visible exits are:"
  $A14C,14 Each one's direction
  $A15A,3 New line

@ $9F94 label=YOU_SEE
c $9F94 "you see :" and what is there
  $9F98,6 "you see :"
  $9FA0,10 What lies loose where the actor is

@ $9FAF label=LIST_HERE
c $9FAF List what is in a place, or say "nothing"
R $9FAF I:A The holder, or $FF for what lies loose
R $9FAF I:B The location
  $9FB3,7 List it, from an indent of 4
  $9FBA,8 Nothing listed: "nothing"

@ $9FC7 label=LIST_HELD
c $9FC7 List what object A holds, or with A = $FF what lies loose in location B
D $9FC7 Each thing is named and followed by a full stop, and then -- unless $A050 says otherwise -- whatever it holds is listed after it, two places further in: the indent is kept at $869F, and this calls itself. Left out: the actor itself, anything out of the actor's reach, and loose things that are in more than one place at once, which are the doors and other fixtures -- EXITS_THROUGH has already told of those.
R $9FC7 I:A The holder, or $FF
R $9FC7 I:B The location
R $9FC7 I:D The indent
R $9FC7 O:C How many were listed, added on
  $9FC7,12 Indent by D, keeping the old indent
  $9FD3,6 Walk every object
  $9FD9,10 Next object held by A
  $9FE3,27 Loose and in several places? Leave it out. Otherwise, is it in location B, first or second of its places?
  $9FFE,13 Not the actor, at the top level
  $A00B,8 Out of reach? Leave it out
  $A013,11 Count it, and name it
  $A01E,8 The actor itself: $A041
  $A026,5 A full stop
  $A02B,18 And what it holds, two further in
  $A03D,4 On to the next

# --------------------------------------------------------------------------
# Telling the player what someone did
# --------------------------------------------------------------------------

@ $70E8 label=PATTERN_OF
c $70E8 Find an action's entry in ACTION_PATTERNS
R $70E8 I:A The action code
R $70E8 O:HL Its 8-byte pattern

@ $70F3 label=PATTERN_FLAGS
c $70F3 Gather an action pattern's flags
D $70F3 The top four bits of each of the pattern's four word references are flags, not part of the word. They are gathered in pairs: $B71D from the first two references, $B71E from the last two. What is known of them is in NARRATE_ACTION and WOULD_WORK.
R $70F3 I:IX The pattern
  $70F3,19 $B71E = the fourth reference's flags, with the third's below them
  $7106,19 $B71D = the second reference's flags, with the first's below them

@ $712B label=NARRATE_ACTION
c $712B Tell the player what was done, as a sentence
D $712B Built from the action's pattern: who did it, "cannot" if it was refused, the verb -- or GO and the direction, for a move, or GO SOMEWHERE in the dark, when the player cannot see which way -- then the first object after its particle, and the second after its preposition, and a full stop. So what the other characters are seen to do is told by the same code, from the same patterns, as the player's own actions.
D $712B A pattern with bit 4 of $B71D set is not narrated at all: that is LOOK and INVENTORY, the only two, which change nothing anyone could see.
  $712B,5 Narrating
  $7130,4 Not yet worked out
  $7137,13 $B701 = 1 if the action was refused
  $7148,9 IX = the action's pattern
  $7151,11 Done, and by the player: a new line first
  $715C,9 A pattern that is not narrated: nothing
  $7165,3 Who did it
  $7168,8 Refused: "cannot"
  $7170,8 The pattern's last word -- GO, for a move
  $7178,23 In the dark, a move goes "somewhere"
  $718F,3 Otherwise the verb, or the direction
  $7192,20 The first object, after its particle, if the pattern has one (bit 3)
  $71A6,27 The second object, after its preposition, if it has one (bit 2)
  $71C1,8 A full stop, and a new line
  $71C9,4 No longer narrating

@ $7AF5 label=WOULD_WORK
c $7AF5 Would the action in $B6E7-$B6E9 work? Try it as a test
D $7AF5 The action is run through DO_ACTION with $B6FA clear. That flag is not only whether anything is printed: it is whether the action is done for real, and with it clear a handler only says, by setting $B6FB, whether it would work -- the same test-then-do that SCRIPT_DO uses for a script's own routines. ACTOR_TRIES calls this first, and does the action for real only if it answers yes.
D $7AF5 Patterns with bits 2 or 3 of $B71D, which have objects to be matched, go through $7A14 instead, not yet worked out.
R $7AF5 O:F NZ if it would work
  $7AFC,4 Keep $794E
  $7B00,9 IX = the action's pattern
  $7B09,9 Not yet worked out
  $7B12,26 The two objects' names, into TARGET_NAME and INSTRUMENT_NAME
  $7B2C,3 Not yet worked out
  $7B2F,4 Only a test
  $7B33,7 Objects to match? $7A14
  $7B3A,9 Otherwise try it: $B6FB says whether it worked
  $7B43,13 $7A14 answers instead
  $7B50,2 It would work
  $7B52,5 For real again

# --------------------------------------------------------------------------
# The ordinary action handlers
# --------------------------------------------------------------------------
#
# Every handler is run twice for anyone but the player: once with $B6FA clear
# to ask whether it would work (see WOULD_WORK), and once for real. FOR_REAL
# is the dividing line in each: the checks come before it, and it answers the
# test by returning straight out of the handler with $B6FB set.

@ $9D44 label=FOR_REAL
c $9D44 Only a test? Then say it would work, and leave the handler
D $9D44 With $B6FA set this returns and the handler goes on to do the action. With it clear it sets $B6FB -- yes, it would work -- and drops its own return address, so the RET leaves the handler that called it.
@ $8C9B label=MUST_CARRY
  $9D44,6 For real: carry on
  $9D4A,4 A test: yes, it would work
  $9D4E,2 ...and out of the handler
c $8C9B Refuse unless the actor has the first object
D $8C9B "you are not carrying it.", and out of the handler that called it.
@ $8CF1 label=CAN_LIFT
  $8C9B,4 The actor has it: fine
  $8C9F,7 Otherwise "you are not carrying it.", from the caller
c $8CF1 Can the actor pick the first object up?
D $8CF1 Its weight and all it holds must fit what the actor can carry -- byte 3 of the actor's record less its own weight and load -- or "the ... is too heavy to lift." and "you are carrying too much."; and a liquid cannot be picked up at all. A refusal leaves the handler that called it.
@ $9D97 label=COUNT_HELD
  $8CF1,18 Its weight with all it holds, at most 255
  $8D03,13 More than the actor can carry at all? "too heavy to lift"
  $8D10,16 More than it can carry besides its load? "you are carrying too much"
  $8D20,5 Refused, from the caller
  $8D25,10 Fine, unless $9246 objects or it is a liquid
  $8D2F,4 Refused
c $9D97 How many visible things does object A hold?
R $9D97 I:A The holder
R $9D97 O:A The count
@ $A09D label=PLACED_WORD
  $9D9C,6 Count from 0, through every object
  $9DA2,20 Held by A and visible: count it
c $A09D Print how things are placed with this object: "in the", "on the"...
D $A09D Picked by the low four bits of byte 4 of its record, from the phrases at $AFCA, four bytes apart: in, on, behind, under, tied to.
R $A09D I:IX The object's record
@ $8C4B label=DO_LOOK
  $A09D,17 The phrase for its byte 4
c $8C4B LOOK
D $8C4B Inside something -- the barrel, say -- the actor is told what it is in and what else is in there with it: "you are in the barrel." and "you see :". Otherwise the whole location is described again, as on a first visit.
@ $8CA6 label=DO_DROP
  $8C4B,3 The test ends here
  $8C4E,11 Held by nothing: describe the place
  $8C59,12 "you are"...
  $8C65,23 ...in the ..., and its name
  $8C7C,8 A full stop and a new line
  $8C84,17 "you see :" and what else it holds
  $8C95,6 Describe the location
c $8CA6 DROP
D $8CA6 The object goes to whatever holds the actor, or to the ground if nothing does. Something tied to the rope goes with the rope: it is the rope that is dropped. A liquid is not dropped but lost: it goes nowhere, and "... evaporates.".
@ $8D33 label=DO_TAKE
  $8CA6,6 Must be carrying it; the test ends here
  $8CAC,15 Tied to the rope? Then it is the rope that is dropped
  $8CBB,14 It is held by what holds the actor
  $8CC9,5 Not a liquid: done
  $8CCE,17 A liquid goes nowhere: "... evaporates."
c $8D33 TAKE and CARRY
D $8D33 Refused if the actor has it already ("you are already carrying the ..."), if it will not lift (CAN_LIFT), or if the actor is inside it. Something tied to the rope is taken by taking the rope.
@ $90EB label=DO_INVENTORY
  $8D33,9 Has it already? "you are already carrying the ..."
  $8D3C,3 Can it be lifted?
  $8D3F,22 Is the actor inside it, at any depth? Refused
  $8D55,7 The test ends here
  $8D5C,14 The actor holds it now...
  $8D6A,4 ...or, if it is tied to the rope, the rope
c $90EB INVENTORY
D $90EB "you are carrying." and a list of what the actor holds, or "nothing".
  $90EB,3 The test ends here
  $90EE,6 "you are carrying."
  $90F4,13 Nothing? "nothing"
  $9101,13 Otherwise the list

@ $8FAD label=DO_RUN
c $8FAD RUN: off in any direction that has a way out
D $8FAD A random direction from 1 to 10, then the first from there on, going round, that the location has an exit in; then MOVE.
@ $9F25 label=EXIT_VIA
  $8FAD,9 A random direction, 1 to 10
  $8FB6,17 Is there a way out that way? If not, the next, round from 10 to 1
  $8FC7,6 Go
c $9F25 Find the exit that goes through the first object
D $9F25 FIND_EXIT's search with the field it matches patched: byte 1 of an exit, the object it goes through, here; byte 2, the destination, from EXIT_TO.
R $9F25 O:IX The exit
R $9F25 O:F Z if there is none
@ $9F2D label=EXIT_TO
c $9F2D Find the exit that leads to location A
R $9F2D I:A The location
R $9F2D O:IX The exit
R $9F2D O:F Z if there is none
@ $8F3B label=GO_THROUGH
c $8F3B GO THROUGH, carried by doors and the like as their own handler
D $8F3B The exit that goes through the object; refused if there is none, if it leads nowhere yet, or if the object will not let anyone through ($8E85). Otherwise it is a move in that exit's direction, into MOVE past its darkness and captivity checks. $8F3E is the way in for callers that have found the exit already.
@ $8FCD label=DO_ENTER
  $8F3B,3 The exit through it
  $8F3E,13 None, or to nowhere yet: refused
  $8F4B,13 Will it let the actor through?
  $8F58,3 The test ends here
  $8F5B,14 A move that way, with no object
c $8FCD ENTER and GO INTO
D $8FCD Looks for an exit whose destination is the number in $B6E8 and goes through it as GO_THROUGH does. How an object number comes to stand for a place here is not yet understood.
@ $8FD6 label=DO_FOLLOW
c $8FD6 FOLLOW
D $8FD6 Only one step: the exit that leads to where the one followed is, if there is one, and through it. Already in the same place, or not next to it: "i cannot follow the ... from here."
@ $8FF5 label=DO_THROW_AT
  $8FD6,17 Already where the one followed is?
  $8FE7,8 An exit that leads there: through it
  $8FEF,6 "i cannot follow the ... from here."
c $8FF5 THROW AT
D $8FF5 Throwing something at a character is attacking the character with it, and at anything else striking it with it: the two objects are swapped and ATTACK WITH or STRIKE WITH is run (SWAPPED_OBJECTS). Done for real, the thrown thing lands, held by nothing, and the target reacts as to an attack.
@ $9F4A label=SWAPPED_OBJECTS
  $8FF5,3 Can it be lifted to throw?
  $8FF8,20 At a character: ATTACK WITH; at a thing: STRIKE WITH
  $900C,6 Run it, the objects swapped
  $9012,11 Only a test: done
  $901D,8 It lands, held by nothing
  $9025,11 And the target reacts as to an attack
c $9F4A Run the routine at HL with the first and second objects swapped
D $9F4A Both the numbers in $B6E8-$B6E9 and the records in $B708-$B70A, all put back afterwards.
R $9F4A I:HL The routine
@ $9034 label=DO_TALK
c $9034 TALK TO, and SAY TO
D $9034 Decides how many of the sentences just said the character will take on as orders (ASSIGN_ORDERS): none if it is not a character; exactly one if it is Gollum waiting for his riddle's answer ($B6F9); otherwise a random number up to byte 6 of its CHARACTERS slot -- and if that comes out 0, "... says " no "". A character whose byte 6 is 0 never takes an order and does not say so.
@ $7EBA label=ASSIGN_ORDERS
  $9034,3 The test ends here
  $9037,12 Not a character: no orders
  $9043,7 Gollum waiting for an answer: one
  $904A,7 Never takes orders: none
  $9051,7 Otherwise a random number up to its limit
  $9058,4 Give it that many
  $905C,9 None: "... says " no "", and none
c $7EBA Give A of the sentences just said to the character in $B6E8
D $7EBA The sentences waiting in ORDERS -- $B737 of them, marked $FF -- are given to the character in turn, as many as A says, and the rest are thrown away.
R $7EBA I:A How many to give
  $7EBE,12 No more than there are; C = how many are left over
  $7ECA,28 The next A waiting are the character's
  $7EE6,20 The rest are thrown away

# --------------------------------------------------------------------------
# The special words: printer, ALL and EXCEPT, IT, and the game's own commands
# --------------------------------------------------------------------------

@ $82A5 label=PRINTER_ON
c $82A5 PRINT: copy the game's text to a ZX Printer, if there is one
D $82A5 Bit 6 of port $FB is low when a ZX Printer is attached; only then is $B6F2 set. NOPRINT, at $82AF, clears it. Both go back to the parser for the next word at $82B3.
  $82A5,6 No printer: nothing changes
  $82AB,4 Copy to the printer from now on
  $82AF,1 NOPRINT: stop
  $82B3,7 On to the next word of the sentence
@ $82BA label=WORD_EXCEPT
c $82BA EXCEPT: only after ALL
D $82BA ALL ... EXCEPT ... is kept as $B719 = 2, and the ALL bit set on the verb; EXCEPT on its own is an error, through $7929.
@ $82D2 label=WORD_ALL
c $82D2 ALL
D $82D2 $B719 = 1, unless an EXCEPT has already made it 2.
@ $82E2 label=WORD_IT
c $82E2 IT: the last noun phrase again
D $82E2 The noun phrase kept at $B6E0 from the last sentence is copied into PHRASE, as if it had been typed, and handed to the first or the second phrase's handler.
@ $8391 label=DO_QUIT
c $8391 QUIT: the score, then a new game on the next key
@ $83A0 label=DO_HELP
c $83A0 HELP: a hint for where the player is
D $83A0 Eleven places have a hint of their own, in HELP_HINTS; anywhere else it is "YOU'RE DOING FINE.". Only the player gets help: a character told HELP just goes on to the next word.
  $83A0,7 Not the player: ignore it
  $83AA,21 The hint for this place, or the general one
  $83BF,11 Print it
@ $83CD label=HELP_HINTS
b $83CD The places HELP has a hint for
D $83CD A FIND_RECORD table of [location, message], eleven of them.
B $83CD,33,3
B $83EE,1,1 End of the table
@ $83EF label=DO_SCORE
c $83EF SCORE
@ $83F5 label=SHOW_SCORE
c $83F5 "you have mastered ... % of this adventure."
D $83F5 The score at $B6F7 is kept in tenths of a per cent, so a full game is 1000, and it is printed with one decimal place: hundreds only if not zero, then tens, a point, and units. Reaching the lonelands scores 25 (VISIT_SCORES), which is the 2.5% a first death there reports.
  $83F7,10 "you have mastered"
  $8401,12 Hundreds, if any
  $840D,9 Tens
  $8416,5 A decimal point
  $841B,6 Units
  $8421,10 "% of this adventure."
@ $842E label=DIGIT
c $842E One decimal digit of HL
D $842E The number of times DE goes into HL, as a character; HL is left with the remainder.
R $842E I:HL The number
R $842E I:DE The place value
R $842E O:A The digit, '0' to '9'
R $842E O:F Z if it is '0'
@ $843A label=DO_PAUSE
c $843A PAUSE: a green border until a key is pressed
@ $84B9 label=NEW_KEYPRESS
c $84B9 Wait for all keys up, then for one down
@ $84B3 label=COPY_3
c $84B3 Copy three bytes from HL to DE
@ $84CC label=DO_SAVE
c $84CC SAVE: four blocks to tape, then verified
D $84CC Four headerless blocks through the ROM's SA-BYTES: the variables at $B6EB, the objects at $C11B, the timers and the characters at $CA84, and the rooms at $BA8A -- the same four START keeps a copy of. Then the tape is rewound and each block checked with the ROM's LD-BYTES in verify mode; an error says so and goes back to the game.
D $84CC Three bytes of a character script at $C9E2, which the game rewrites as it runs ($A8CC), are carried in the first three of the variables block; DO_LOAD puts them back.
  $84CF,9 The script bytes into the variables block
  $84D8,11 "start TAPE then PRESS ANY key."
  $84E3,3 Wait for the key
  $84E6,48 Save the four blocks
  $8516,9 "REWIND and PREPARE TAPE for VERIFICATION -- then hit ANY key."
  $851F,52 Verify them
@ $855A label=VERIFY_BLOCK
c $855A Verify one block, or say the tape is bad
D $855A "TAPE ERROR - hit ANY key to CONTINUE.", and the save gives up.
@ $8451 label=DO_LOAD
c $8451 LOAD: the four blocks SAVE wrote
D $8451 A block that fails to load leaves the game half-loaded, so LOAD_BLOCK does not return to it: "TAPE ERROR - hit ANY key to RESTART PROGRAM.".
  $8454,52 Load the four blocks
  $8488,10 The script bytes back where they belong
@ $8498 label=LOAD_BLOCK
c $8498 Load one block, or start the game again

# --------------------------------------------------------------------------
# Printing: two windows, two fonts
# --------------------------------------------------------------------------
#
# The screen has two text windows. The story -- everything the game narrates
# -- is written in lower case with a capital to start each sentence, in the
# game's own font six pixels wide, 42 columns to a line, and scrolls up over
# the top 17 character rows, which is why a picture scrolls away as the story
# goes on beneath it. The five rows at the bottom are the input window, in
# the ROM's own font, 32 columns and all capitals: the command line, and the
# game's messages about the tape and HELP. $B701 picks between them.

@ $85B7 label=INPUT_CHAR
c $85B7 Print a character in the input window
D $85B7 The bottom five rows, 19 to 23, in capitals with the ROM's font. A carriage return blanks the rest of the line and scrolls the window up; a backspace ($08) steps back, and up to the line before if it has to. The cursor is kept at $85B4 and the columns left on the line at $85B3.
  $85BA,14 A carriage return: to the next line
  $85C8,4 Backspace
  $85CC,10 Lower case to capitals
  $85D6,3 Print it
  $85D9,6 End of the line?
  $85DF,7 Then scroll the window, and start again at the left
  $85E6,15 The cursor after it
  $85F5,24 Backspace: blank the cursor, step back, and up a line if it has to
@ $860D label=SCROLL_INPUT
c $860D Scroll the input window up a line
D $860D Character rows 20-23 move up to 19-22, and row 23 is blanked.
@ $864A label=SCROLL_INPUT_BACK
c $864A Scroll the input window down a line
D $864A For a backspace past the start of a line: rows 19-22 back down to 20-23.
@ $867A label=ROM_FONT_CHAR
c $867A Print a character at HL in the ROM's font
D $867A The eight rows of the ROM's own character set at $3D00; L is moved on one column.
R $867A I:A The character, $20 to $7F
R $867A I:HL The screen address
@ $86A1 label=STORY_CHAR
c $86A1 Print a character of the story
D $86A1 Where most of the game's text goes, in the six-pixel font at $8822 (NARROW_CHAR), 42 to a line: HL is the byte and C the pixel within it where the next character starts, kept at $869C and $869E between calls, and $869B counts the columns left.
D $86A1 A new line starts with the indent at $869F -- how LIST_HELD indents what is inside something. Capitals are the game's own: every letter is made lower case, and the first letter after a carriage return or a full stop made upper case again, by the flag at $B704.
D $86A1 At the end of a line the finished line is copied to the ZX Printer if PRINT is on, then the game waits about a third of a second, or less if a key is pressed, before scrolling. $B716, when not zero, takes away that wait for as many lines as it counts; what sets it is not yet traced.
  $86A4,34 Starting a line: the indent
  $86C6,6 A carriage return?
  $86CC,5 The next letter is a capital
  $86D1,7 A new line: to the printer, if PRINT is on
  $86D8,32 A short wait, or until a key
  $86F8,9 Until the keys are let go
  $8701,12 Scroll the story up a line, 42 columns ahead
  $870D,21 Backspace: back a column, blank it, back again
  $8722,10 Capitals to lower case...
  $872C,25 ...and a capital where a sentence starts
  $8746,6 Print it
  $874C,7 The line full? A new one
  $8753,14 Keep the place
@ $8761 label=BACK_ONE
c $8761 Step back one six-pixel column
R $8761 I:HL The screen byte
R $8761 I:C The pixel within it
@ $876B label=SCROLL_STORY
c $876B Scroll the story up a line
D $876B Character rows 1 to 17 move up to 0 to 16, attributes with them, and row 17 is cleared to 42 spaces. The picture is in rows 0 to 15, so it goes up and off the top as the story goes on.
@ $87C9 label=NARROW_CHAR
c $87C9 Print a character in the six-pixel font
D $87C9 A character six pixels wide seldom sits in one byte: each row is shifted to the pixel in C and, when it runs over, the rest put into the next byte along. The font is at $8822, from the space: $8722 + 8 times the character.
R $87C9 I:A The character
R $87C9 I:HL The screen byte
R $87C9 I:C The pixel within it where the character starts
R $87C9 O:HL The byte the next character starts in
R $87C9 O:C The pixel within it
@ $8B22 label=LINE_TO_PRINTER
c $8B22 Copy the newest line of the story to the ZX Printer
D $8B22 Only while PRINT is on. The eight pixel rows of character row 17 go out through port $FB a pixel at a time, as the ROM's COPY does; a printer that stops, or is not there, ends it.

# --------------------------------------------------------------------------
# Fighting
# --------------------------------------------------------------------------

@ $9171 label=DO_ATTACK
c $9171 ATTACK WITH, and STRIKE WITH through THROW AT
D $9171 The attacker's strength, byte 5 of its record, plus the weapon's if there is one -- bare hands are a FIST -- against the target's defence, byte 6, each with a random -10 to +10 (JOSTLE). A blow no stronger than the defence is wasted: "but the effort is wasted. his defense is too strong.". One more than 16 stronger kills: "with one well placed blow you cleave his skull." and KILL. Anything between picks a message from WOUNDS by how much stronger it was, and wears the target's strength and defence down by it.
D $9171 Only something in one place can be a weapon: "you cannot kill with the ...". And no one attacks their own side (SAME_SIDE).
  $9171,3 Not against its own side
  $9174,23 The weapon's name, or FIST, for the messages
  $918B,7 B = the attacker's strength
  $9192,6 No weapon: that is all
  $9198,14 A weapon in more than one place: "you cannot kill with the ..."
  $91A6,9 Otherwise its strength is added, at most 255
  $91AF,5 A random share of it
  $91B4,3 The test ends here
  $91B7,10 A random share of the target's defence
  $91C1,7 No stronger: "but the effort is wasted..."
  $91C8,10 More than 16 stronger?
  $91D2,18 Otherwise a wound: the message for how much stronger...
  $91E4,23 ...and the target's strength and defence worn down by it
  $91FB,3 Print the wound
  $91FE,21 A kill: "...you cleave his skull.", dead, and it is said
@ $914A label=SAME_SIDE
c $914A Are attacker and target on the same side?
D $914A Bits 4 to 6 of byte 4 of each record are the sides; sharing one ends the handler that called this with $B6FB clear -- it would not work. The player alone can turn on a friend: attacked by the player, a character on the player's side (bit 4) is taken off it first, so the attack goes ahead and it is an enemy from then on.
  $914A,20 The player attacking a friend: no longer a friend
  $915E,19 Sharing a side? Then no: out of the caller, would not work
@ $9213 label=JOSTLE
c $9213 A plus a random -10 to +10, kept to 0-255
@ $9226 label=WOUNDS
w $9226 What a wound is said to be, by how much stronger the blow was
D $9226 The messages the fight picks between, from a stagger to a stunning hit; the stronger the blow, the further down the table.
@ $977F label=KILL
c $977F Kill the character in A
D $977F The player's death is PLAYER_DIES. Anyone else is marked dead (flag bit 3), drops everything it holds (EMPTY_OUT), and gives up its slot in CHARACTERS, so its script never runs again.
  $977F,4 The player: PLAYER_DIES
  $9789,7 Dead
  $9790,3 Everything it held drops
  $9793,13 Its script is over
  $97A0,7 Not yet worked out

@ $9076 label=DO_SHOOT
c $9076 SHOOT
D $9076 Only with the bow in hand ("you are not carrying the bow."), and not at one's own side. Bard never misses. Anyone else shooting at the dragon always misses -- only Bard can kill it -- and at anything else misses about a third of the time: "the arrow misses the ... by a wide margin.". A hit, "the arrow hits the ...", kills a living character (KILL) and strikes anything else as STRIKE WITH would; the arrow is spent, held by nothing, unless it was what was shot at.
  $9076,11 Not carrying the bow: refused
  $9081,6 Not its own side; the test ends here
  $9087,5 It is an attack
  $908C,7 Bard: a hit
  $9093,11 At the dragon: a miss
  $909E,10 Otherwise a miss one time in three
  $90A8,15 The arrow is spent
  $90B7,6 "the arrow hits the ..."
  $90BD,10 Not a living character: struck, as STRIKE WITH
  $90C7,11 Killed
@ $A1C8 label=IS_ALIVE
c $A1C8 Is this a character, and alive?
D $A1C8 Flag bit 6 set, a character, and bit 3 clear, not dead.
R $A1C8 I:IX The record
R $A1C8 O:F Z if so
@ $939E label=DO_GIVE
c $939E GIVE TO
D $939E The giver must be carrying it, and the one given it must be able to carry it too ("you are carrying too much."). Then it is theirs, and in their place, with everything inside it.
  $939E,13 Not carrying it: refused
  $93AB,25 More than the other can carry: refused
  $93C4,3 The test ends here
  $93C7,12 Theirs now, and where they are
  $93D3,7 With all it holds
@ $93DA label=DO_EXAMINE
c $93DA EXAMINE
D $93DA An object's own description, bytes 14 and 15 of its record, if it has one; otherwise "you see" and its name. Some objects carry their own EXAMINE instead -- the curious map's is ELROND_READS_MAP, the magic door's MAGIC_DOOR_EXAMINED.
  $93DA,3 The test ends here
  $93DD,17 Its own description, if it has one
  $93EE,22 Otherwise "you see" and its name

@ $A16C label=SAY_STATE
c $A16C "the ... is ...": an object and its state
D $A16C The state word is picked by A from STATE_WORDS: bits 0-6 the pair, bit 7 which of the two. A kill says "the ... is dead.", CLIMB OUT OF something shut "the ... is closed.". $A172 is the way in with the name already in HL.
R $A16C I:A The state
R $A16C I:IX The object's record
@ $A224 label=STATE_WORDS
w $A224 The states of things, as words, in pairs
D $A224 Eight words for bit 7 of the state clear, then the eight they pair with for it set: unlocked and locked, empty and full, broken, off and on, closed and open, dead and alive. The gaps are zero.
  $A224,16 UNLOCKED, -, EMPTY, -, OFF, CLOSED, DEAD, -
  $A234,16 LOCKED, -, FULL, BROKEN, ON, OPEN, ALIVE, -
@ $A248 label=DO_TIE
c $A248 TIE TO
D $A248 Only with the rope. TIE ROPE TO X is made TIE X TO ROPE by swapping the objects (SWAPPED_OBJECTS). Not a liquid, not anything with something visible in it ("the ... is already tied."), and not a living character -- a dead one can be. The thing is then held by the rope; and the rope goes to the one who tied it if they have the thing, or could take it, and is left lying otherwise.
  $A248,7 TIE ROPE TO X: swap them round
  $A24F,8 Only to the rope
  $A257,11 Not a liquid
  $A262,11 Nothing in it already
  $A26D,13 Not a living character
  $A27A,3 The test ends here
  $A27D,13 Tied: held by the rope
  $A28A,24 Could the actor take it? A test of TAKE
  $A2A2,7 Then the rope is the actor's...
  $A2A9,5 ...otherwise it is left
  $A2AE,6 The objects swapped round, and again
@ $A2B4 label=DO_UNTIE
c $A2B4 UNTIE
D $A2B4 Only something tied to the rope ("the ... is not tied."); it goes to whoever has the rope.
@ $A302 label=DO_BURN
c $A302 BURN: only the dragon can, and it kills
@ $977C label=KILL_TARGET
c $977C Kill the first object
@ $A3E6 label=DO_CAPTURE
c $A3E6 CAPTURE
D $A3E6 Only a character can be captured, and not by its own side. The wood elf and the butler take the captive to the elvenking's dark dungeon, location 31; anyone else -- the goblins -- to the goblins' dungeon, location 13. Already there, it is refused. The captive goes with everything it carries; a captured player is shown the new place, if it can be seen. ACTION_TABLE's key-0 record after this runs NOTE_LIGHT.
  $A3E6,23 Not its own side
  $A3FD,7 Only a character
  $A404,15 The elves' dungeon, or the goblins'
  $A413,7 Already there: refused
  $A41A,3 The test ends here
  $A41D,17 There now, held by nothing, with all it carries
  $A42E,6 Not the player: done
  $A434,9 The player is the subject again
  $A43D,11 Show the player the dungeon, if it can be seen
@ $A541 label=DO_CLIMB_OUT
c $A541 CLIMB OUT OF
D $A541 Only out of what holds the actor, and not if it is shut ("the ... is closed.").
  $A541,13 Not in it: refused
  $A54E,9 Shut: "the ... is closed."
  $A557,3 The test ends here
  $A55A,4 Out
@ $A5CA label=IS_SHUT
c $A5CA Is this thing shut?
D $A5CA Flag bit 5 is being open to be seen into, and so to be got out of; Z if it is clear. A = 5, CLOSED, for SAY_STATE.
R $A5CA I:IX The record
R $A5CA O:F Z if shut

# --------------------------------------------------------------------------
# Doors, locks and ways through
# --------------------------------------------------------------------------

@ $8E85 label=CAN_PASS
c $8E85 Can the actor go this way?
D $8E85 A way through an object is shut unless the object is open (flag bit 5) or broken (bit 3), and the window, with bit 7 of its byte 4, will never let the player through at all. The actor, with all it carries ($8D9C), must fit the opening -- byte 2 of the object's record -- and then the room it goes into must have space for it: byte 1 of a room's record is how much it holds, and $FF, for nearly every room, is no limit.
R $8E85 I:A The object the way goes through, or 0
R $8E85 O:A 0 it can; 1 it is shut; 2 "the ... is too small for you to enter."; 3 "... is too full for you to enter."
  $8E85,3 No object in the way: only the room to check
  $8E88,10 Shut
  $8E92,12 The window: never for the player
  $8E9E,9 Too big for the opening
  $8EA7,23 The room's capacity, less what is in it...
  $8EBE,6 ...against the actor's size
  $8EC4,2 It can
  $8EC6,4 3: the room is full
  $8ECA,4 2: too small
  $8ECE,4 1: shut
@ $9C41 label=ROOM_LEFT
c $9C41 How much room is left in a location
D $9C41 Byte 1 of its record, less the size of everything that is only there; 0 if it is over-full.
R $9C41 I:A The location
R $9C41 O:A The room left
@ $A1F9 label=LOCK_STATE
c $A1F9 Is the first object locked, or open?
D $A1F9 NZ with A a SAY_STATE state for "locked" or "open"; $A204 asks only whether it is open.
R $A1F9 O:F NZ if it is locked or open
R $A1F9 O:A LOCKED or OPEN, for SAY_STATE
@ $910E label=DO_OPEN
c $910E OPEN, carried by doors and containers as their own handler
D $910E Not if it is locked or open already ("the ... is locked.", "the ... is open."). Opening sets flag bit 5, and a container in one place with something visible inside shows what: "you see". $9117 is the way in for callers that only want it opened.
  $910E,6 Locked, or open already: say which
  $9114,3 The test ends here
  $9117,4 Open
  $911B,5 Not a container in one place: done
  $9120,8 Nothing in it: done
  $9128,7 Not yet worked out
  $912F,9 "you see" and what is in it
@ $9138 label=DO_CLOSE
c $9138 CLOSE
D $9138 Not if it is shut already ("the ... is closed."); otherwise flag bit 5 is cleared.
@ $946D label=DO_LOCK
c $946D LOCK WITH, once the right key is known
D $946D Not if it is locked or open, and not with a broken key ("the ... is broken."). The same code unlocks, from $948D, by writing the one byte of its SET 0 or RES 0 at $948B.
  $946D,6 Locked or open already: say which
  $9473,5 SET 0: lock it
  $9478,13 A broken key will not turn
  $9485,3 The test ends here
  $9488,4 Bit 0: locked, or not
@ $948D label=DO_UNLOCK
c $948D UNLOCK WITH, once the right key is known
  $948D,13 Not locked: "the ... is unlocked."
  $949A,6 Open: "the ... is open."
  $94A0,4 RES 0: unlock it
@ $A330 label=SIDE_DOOR_KEY
c $A330 The mountains' side door takes the small curious key
D $A330 Each lockable door carries its own LOCK WITH and UNLOCK WITH, naming the key that fits in B: the side door the small curious key (2), the red door the red key (15), the heavy rock door the large key (4). Another of those keys "does not fit this lock."; anything else cannot be done at all. The round green door and the trap door go straight to NO_KEY_FITS: nothing opens them with a key.
@ $A334 label=RED_DOOR_KEY
c $A334 The red door takes the red key
@ $A338 label=ROCK_DOOR_KEY
c $A338 The heavy rock door takes the large key
  $A33A,17 The key that fits: LOCK or UNLOCK
  $A34B,13 Another key: it does not fit. Anything else: cannot be done
@ $A358 label=NO_KEY_FITS
c $A358 "the ... does not fit this lock."
@ $A35E label=SIDE_DOOR_UNLOCKED
c $A35E After the side door is unlocked, it opens

# --------------------------------------------------------------------------
# Containers, food and water
# --------------------------------------------------------------------------

@ $8CE0 label=DO_TAKE_OUT
c $8CE0 TAKE OUT OF, carried by the containers
D $8CE0 The thing must be in the container, at any depth ("the ... is not in the ..."); then it is taken as TAKE takes anything, from the lifting check on.
@ $924F label=DO_PUT_IN
c $924F PUT IN and DROP IN, carried by the containers
D $924F What goes in must be something in one place, and not a liquid -- the last part of CAN_LIFT -- and not the container itself. The container must be open -- except to PUT something ON it -- and have room: its size, byte 2, less what is in it, more than the thing's size ("the ... is too full."). Then it is in the container, and where the container is.
  $924F,3 Something that can be put anywhere
  $9252,9 Not into itself
  $925B,17 Shut, unless it is PUT ON: "the ... is closed."
  $926C,27 Room for it? "the ... is too full."
  $9287,3 The test ends here
  $928A,13 In it, and where it is
  $9297,5 "the ... is closed."
@ $9428 label=INTO_THE_RIVER
c $9428 PUT IN or DROP IN a river: swept away
D $9428 A river is in two places, and whatever goes in comes out at the other, downstream: "and it gets swept away.". If that was the player, carried off in something, and the river leads nowhere, it is death.
@ $8F69 label=DO_FILL
c $8F69 FILL WITH, carried by the barrel
D $8F69 Filling from a river's water fetches a fresh water of the same kind (objects $15 and $16, kept nowhere for this), which is what goes in; then it is PUT IN with the objects swapped. A container already full says so. As read, the liquid would then be refused by the last part of CAN_LIFT, which DO_PUT_IN begins with, so that FILL can never succeed; that has not been tried in play.
  $8F69,15 From a river's water? A fresh one
  $8F78,11 Only with a liquid
  $8F83,9 Full already: "the ... is full."
  $8F8C,6 Put it in, the objects swapped
  $8F92,27 The fresh water, held by nothing
@ $929C label=DO_DRINK
c $929C DRINK
D $929C A drink from a container leaves it no longer full and gives one point of strength; anything else is eaten, as EAT.
@ $92B5 label=DO_EAT
c $92B5 EAT
D $92B5 Ten points of strength, and the thing is gone from everywhere. Strength reaching 128 kills the eater: "his foul gluttony has killed the ...". That is the end the trolls come to when they eat the player, whose own record has PLAYER_DIES after EAT.
  $92BA,14 Stronger, unless it is too much
  $92C8,20 The thing is nowhere
  $92DC,12 Too much: dead of gluttony
@ $9404 label=DO_EMPTY
c $9404 EMPTY, carried by the barrel
D $9404 Not if it is shut ("the ... is closed.") or has nothing in it ("the ... is empty."); otherwise EMPTY_OUT, and it is no longer full.
@ $A244 label=DRINK_WATER
c $A244 The water's own DRINK: nothing happens, and it works
@ $A328 label=DRINK_BLACK_WATER
c $A328 The black water's own DRINK: asleep, and dead
D $A328 "... fall asleep." and the drinker is killed through the end of SWIM_BLACK_RIVER.
@ $A310 label=SWIM_BLACK_RIVER
c $A310 SWIM, in the fast black river: asleep, and dead
D $A310 "as soon as you touch the river you fall asleep and gently float away.", "time passes..." for the player, and KILL. The drinking of its water ends the same way, from $A316.
@ $A2CD label=SWIM_RIVER
c $A2CD SWIM, in the fast river
D $A2CD Across, if the river's exit leads anywhere: the river is opened for the moment it takes MOVE to go that way through it, and shut again. Leading nowhere, it works and nothing happens.
@ $A55F label=DO_CLIMB_INTO
c $A55F CLIMB INTO, carried by the barrel, the boat and the chest
D $A55F Not what the actor is in already, and only what it can reach. If the actor is carrying it, it is put down first. It must be open, and big enough for the actor and all it carries, unless its size is $FF ("the ... is too big.").
  $A55F,13 Already in it: refused
  $A56C,10 Out of reach: refused
  $A576,32 Carrying it? Put it down first
  $A596,18 The actor's size, with its load
  $A5A8,10 Shut: "the ... is closed."
  $A5B2,14 Too small: "the ... is too big."
  $A5C0,3 The test ends here
  $A5C3,6 In

# --------------------------------------------------------------------------
# Breaking things, looking through, and the ring
# --------------------------------------------------------------------------

@ $92ED label=DO_STRIKE
c $92ED STRIKE WITH, carried by whatever can be broken
D $92ED Not a liquid, not what is broken already ("the ... is broken."), and not what has no defence at all. The blow is the weapon's strength, the striker's and a random 0 to 21 together, against the thing's defence, byte 6: at least equal, and the thing breaks -- flag bit 3, "broken" in its name (BROKEN_OR_DEAD), its strength halved, and a thing that holds others in or on it spills them. Then the weapon itself is tried the same way against the thing's defence, and a weapon weaker than what it hit breaks too: striking the trap door with the sword can cost the sword.
  $92ED,18 Not a liquid; broken already: say so
  $92FF,7 Nothing with no defence
  $9306,1 B = the weapon's strength, 0 with none
  $9307,37 A weapon: one with strength, and one that can itself be struck
  $932C,3 The test ends here
  $932F,22 The blow, against its defence
  $9345,27 Broken: named so, weaker, and spilling what it held
  $9360,31 The weapon against the same defence...
  $937F,26 ...and broken too if it was weaker
  $9399,5 "the ... is broken."
@ $A18C label=BROKEN_OR_DEAD
c $A18C Rename an object BROKEN, or a character DEAD
D $A18C The first adjective of its name becomes BROKEN, or DEAD for a character, and the second is dropped.
R $A18C I:A The object
@ $8EEC label=LOOK_THROUGH
c $8EEC LOOK THROUGH, carried by doors and the like
D $8EEC Not through something shut ("the ... is closed."). The place beyond is shown as if the actor were there for a moment -- "you see" and its description -- if it is lit, and "it is dark." if not. $8EF8, the rivers' LOOK ACROSS, is the same without the shut test. Nothing at all happens for an actor shut inside something (SHUT_IN_ACTOR).
  $8EEC,12 Shut: "the ... is closed."
  $8EF8,7 The actor shut in something: nothing
  $8EFF,16 The way through it, and where it leads
  $8F0F,3 The test ends here
  $8F12,13 Dark there: "it is dark."
  $8F1F,22 Show it, from there
  $8F35,6 "it is dark."
@ $8ED2 label=SHUT_IN_ACTOR
c $8ED2 Is the character in A shut inside something?
R $8ED2 I:A The character
R $8ED2 O:F NZ if something shut holds it, at any depth
@ $962B label=DESCRIBE_SEEN
c $962B Describe a location, opening "you see"
@ $94A4 label=THROW_THROUGH
c $94A4 THROW THROUGH, carried by doors and the like
D $94A4 The thrower must have it, the way through the object must exist and be open ("the ... is closed."); it lands in the place beyond, with all it holds. The trap door's record runs BARREL_THROWN after this.
@ $9065 label=DO_DIG
c $9065 DIG, carried by the sand
D $9065 Digging the sand opens it, and shows what it hides -- the trap door; digging it again closes it.
@ $A368 label=OPEN_CRACK
c $A368 The crack's own OPEN: only from the dark stuffy passage, location 15
@ $A390 label=WEAR_RING
c $A390 WEAR, carried by the ring
D $A390 The wearer is invisible -- flag bit 7 clear -- and a quarter as strong, the ring is out of sight too, and timer 6 is set to take it off again in 2 to 10 turns (see TIMERS).
  $A393,20 Invisible, and weaker
  $A3A7,10 The ring, out of sight on the wearer
  $A3B1,11 Off again in 2 to 10 turns
@ $A3BC label=TAKE_OFF_RING
c $A3BC TAKE OFF, carried by the ring
D $A3BC Not if it is not being worn ("you are not wearing the ..."). Visible again, four times as strong, and the timer stopped.
  $A3C4,10 Not worn: refused
  $A3CE,3 The test ends here
  $A3D1,21 Seen again, and as strong as before; the timer stopped

# --------------------------------------------------------------------------
# The last of the objects' own handlers
# --------------------------------------------------------------------------

@ $97FF label=ONLY_IF_DONE
c $97FF Go on only if the action was done for real, and worked
D $97FF Otherwise it leaves the handler that called it. This is what the records keyed 0 after a handler use: they run whether or not the handler succeeded, and this is how they find out.
@ $A448 label=GOBLIN_RETURNS
  $97FF,9 Done for real, and it worked: carry on
  $9808,3 Otherwise out of the caller
c $A448 After a goblin is attacked: a dead goblin comes back
D $A448 Killing a goblin does not get rid of it. "the ... falls down a hole and vanishes.", it is alive again, back in its slot in CHARACTERS and in its own place, named as it was, from GOBLIN_HOMES; and if that is where the player is, "another goblin enters.".
@ $A49C label=GOBLIN_HOMES
  $A448,9 Not dead: nothing
  $A451,4 Alive again
  $A455,19 Its entry in GOBLIN_HOMES
  $A468,8 Back in its slot
  $A470,15 Back in its place, and its name as it was
  $A47F,6 "the ... falls down a hole and vanishes."
  $A485,23 Where the player is: "another goblin enters."
b $A49C Where each goblin comes back to
D $A49C Six bytes for each of the six: the goblin, its slot in CHARACTERS, the location it comes back in, and the adjective its name had.
B $A49C,36,6
@ $A73B label=THORIN_KILLED
c $A73B After Thorin is attacked: if he is dead, the curious key shatters
D $A73B The small curious key opens the mountain's side door, and it is Thorin's. Killing him breaks it -- "the small curious key shatters." where the player can see -- which leaves the side door locked for good.
@ $A761 label=WINDOW_OPEN_CLOSE
  $A73B,6 Thorin not dead: nothing
  $A741,3 Only if it really happened
  $A744,13 The key is broken
  $A751,16 "the small curious key shatters.", where the player sees it
c $A761 The window's own OPEN and CLOSE: out of the player's reach unless carried
D $A761 The player can only reach the window while held by something -- carried, as the guides have it, by Thorin -- and otherwise "you cannot reach the ...". Characters can open and close it as any door.
@ $A784 label=WINDOW_OTHERS
  $A761,21 The player, held by nothing: "you cannot reach the ..."
  $A776,14 Otherwise the ordinary CLOSE or OPEN
c $A784 The window's GO THROUGH, STRIKE WITH and LOOK THROUGH, with the same reach
@ $A67E label=TRAP_DOOR_OPEN_CLOSE
  $A784,19 The player, held by nothing: out of reach
  $A797,19 Otherwise GO THROUGH, STRIKE WITH or LOOK THROUGH as usual
c $A67E The trap door's own OPEN and CLOSE: only from the elvenking's cellar
D $A67E Anywhere else, "you cannot reach the ...".
@ $A814 label=THROW_ROPE_ACROSS
  $A67E,15 Not in the cellar: out of reach
  $A68D,11 Otherwise the ordinary CLOSE or OPEN
c $A814 THROW ACROSS, carried by the rope
D $A814 Across a river: "it sails across and" -- and if the boat is on the far bank, half the time it "lands in the boat.", tying the boat to it, and otherwise falls short or slides out again. With no boat there it lands on the other side, half the time, or falls short.
@ $A86E label=HALF_THE_TIME
  $A814,11 Across what? A river's way over
  $A81F,3 The test ends here
  $A822,6 "it sails across and"
  $A828,8 Is the boat on the far bank?
  $A830,18 Then half the time into it; if not, short or out again
  $A842,10 In the boat: the boat is tied to the rope
  $A84C,8 No boat: half the time short
  $A854,23 ...otherwise over, onto the far bank
  $A86B,3 Say which
c $A86E Carry set half the time
@ $A876 label=PULL_ROPE
c $A876 PULL, carried by the rope
D $A876 With the boat tied to it: "the boat glides across the river and lands on this side.", from one bank to the other, and it is let go. $A882 is the crossing itself, which BOAT_BOARDED uses too.
@ $A89E label=BOAT_BOARDED
  $A876,9 Only with the boat tied to it
  $A87F,3 "the boat glides across the river and lands on this side."
  $A882,3 The crossing: the message...
  $A885,25 ...and the boat, with whoever is in it, to the other bank, let go
c $A89E After climbing into the boat: across
D $A89E "with a lurch the boat glides across the river and lands on the other side.", and whoever is in it goes too.
@ $AA27 label=JUMP_ONTO_BARREL
  $A89E,8 Only if it really happened, and for the player
  $A8A6,5 "with a lurch..." and across
c $AA27 JUMP ONTO, carried by the barrel
D $AA27 Only down onto it, from a place with a way down to where it is: then the jumper is in the barrel, with it, and a player is shown the place. From anywhere else it is "you cannot jump onto the ... from here." -- or would be: where the way to it is not down, the code has JP NZ,$B301, which jumps into that message's bytes rather than printing them, apparently for LD HL,$B301 and JP $72DD. In a quick test, from the great halls beside the cellar, that path was not reached; whether anything can reach it is not worked out.
@ $AAA2 label=SIDE_DOOR_CLOSED
  $AA27,19 A way from here to where the barrel is? If not, say so
  $AA3A,8 Not down: into the message bytes -- see above
  $AA42,3 The test ends here
  $AA45,13 In the barrel, and there
  $AA52,10 For the player, describe it
c $AAA2 After the side door is closed: locked, hidden, and the hole's timer started again
  $AAA2,3 Only if it really happened
  $AAA5,5 The hole comes again in six turns
  $AAAA,9 Locked and hidden, and "the hole vanishes." where seen

# --------------------------------------------------------------------------
# The characters' own routines, called from their scripts
# --------------------------------------------------------------------------

@ $A1E3 label=SAYS
c $A1E3 The actor says the message at HL: ... says " ... "
D $A1E3 The words in quotes, capitalised, after the actor's name and "says".
R $A1E3 I:HL The message
@ $97F4 label=NARRATE_LINE
c $97F4 The message at HL as a sentence of the story, with a full stop and a new line
R $97F4 I:HL The message
@ $A4DF label=GIVEN_SOMETHING
c $A4DF Given something: "thank you", mostly
D $A4DF Gandalf, Thorin, Elrond, the wood elf and the butler all keep this for GIVE TO: mostly "thank you", sometimes "what do you expect me to do with this ?".
@ $A4F5 label=GANDALF_WHATS_THIS
c $A4F5 Gandalf: "what's this ?"
@ $A4FE label=GANDALF_CHATTER
c $A4FE Gandalf: "you are doing a great job", "hurry up" or "hello", at random
@ $A51C label=THORIN_THRAINS_KEY
c $A51C Thorin: "this was thrains key"
@ $A525 label=ELROND_HELLO
c $A525 Elrond, where the player is: "hello"
@ $A5D1 label=WARG_HOWLS
c $A5D1 The warg, where the player is: "the vicious warg runs around you and howls"
@ $A640 label=THORIN_WHERES_THIEF
c $A640 Thorin, where the player is but cannot be seen: "where's the thief ?"
D $A640 That is, while the player wears the ring.
@ $A657 label=THORIN_CHATTER
c $A657 Thorin, at random: waits, sings about gold, or says "hurry up" or "get us out of this one, thief !"
D $A657 Quite often -- four of the nine values RANDOM_POSITIVE gives here -- nothing at all.
@ $A698 label=DRAGON_FOLLOWS
c $A698 The dragon follows the player through its mountain
D $A698 In the front gate, the lower halls or on the lonely mountain (locations 39, 41 and 44), the dragon goes to wherever the player is, and "... enters.".
@ $A6C2 label=DRAGON_THREATENS
c $A6C2 The dragon, where the player is: "prepare to die"
D $A6C2 "well thief your cunning has failed you this time. prepare to die " -- or, to a player it cannot see, "i may not be able to see you thief but i can still burn you...".
@ $A6DC label=DRAGON_HUNTS
c $A6DC Once the treasure is gone from its hall, the dragon hunts the player
D $A6DC While the treasure is still in the lower halls, nothing. Once it is not, wherever the player is in the open -- a lit place -- four times in five "in the distance you see the shape of a monstrous dragon flying after you.", and otherwise "the dragon descends and in a terrific spout of flames burns you to a crisp." and PLAYER_DIES.
@ $A8AB label=BARD_TAKES_ORDER
c $A8AB Bard: an order given to him becomes a step of his own script
D $A8AB The order is taken and parsed, and its action and objects are written into the script step at $C9E2 -- with opcode $42, an action that an order cannot interrupt -- so that Bard goes on trying it, turn after turn, until it works. Those are the three script bytes that DO_SAVE carries in the variables block.
@ $A926 label=GOLLUM_POCKETS
c $A926 Gollum, where the player is: "what has it got in its pockets ?"
D $A926 Or, depending on who has the ring, "my birthday present -- how did we lose it. my precious"; the exact choice is not yet worked out.
@ $A9E5 label=ELROND_GIVES_LUNCH
c $A9E5 Elrond, where the player is: he gives the player lunch
D $A9E5 The lunch, if it is nowhere or Elrond has it, is made his and then given to the player, through DO_GIVE -- so it can be refused if the player is carrying too much.
@ $A9BD label=TROLLS_TALK
c $A9BD The trolls, once the player comes to their clearing: their lines
D $A9BD Fails, and so is tried again every turn, until the player is in location 5; then the hideous troll and the vicious troll each say their line and the script moves on.
@ $A94E label=TROLLS_EAT
c $A94E The trolls, the four turns after: eat the player, if still there
D $A94E The troll eats the player (EAT, $1B) where they are both, and PLAYER_DIES. Anywhere else it fails, and the script pauses a turn.
@ $A971 label=TROLLS_TURN_TO_STONE
c $A971 Dawn: the trolls turn to stone
D $A971 Both trolls are killed and hidden, drop what they held -- the large key among it -- the clearing gets its daytime description and is marked unvisited, and its picture is patched to show them as stone.
