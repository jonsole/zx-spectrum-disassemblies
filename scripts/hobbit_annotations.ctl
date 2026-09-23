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

@ $812B label=INC_Y
c $812B Move the point up one, if it can
D $812B y is 0-127, so bit 7 going high means it would leave the canvas: the move is undone and A returned with its low bit clear. Otherwise the low bit is set. The callers test that bit rather than the flags, which is why both exits go through the same tail.

@ $813A label=DEC_Y
c $813A Move the point down one, if it can
D $813A Same test and the same shared tail as INC_Y: DEC E to $FF also shows up in bit 7.

@ $8141 label=INC_X
c $8141 Move the point right one, if it can
D $8141 x is a whole byte, so the only edge is the wrap to zero.

@ $8148 label=DEC_X
c $8148 Move the point left one, if it can

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
# and undoes the move if it would leave $5800-$5AFF, so a path that runs off
# the edge of the screen stops there rather than writing into the picture.

@ $80F5 label=ATTR_UP
c $80F5 Up one attribute row, if it can

@ $8106 label=ATTR_DOWN
c $8106 Down one attribute row, if it can

@ $8117 label=ATTR_LEFT
c $8117 Left one cell, if it can

@ $8121 label=ATTR_RIGHT
c $8121 Right one cell, if it can

# --------------------------------------------------------------------------
# Input
# --------------------------------------------------------------------------

@ $8B93 label=SCAN_KEYBOARD
c $8B93 Scan the whole keyboard, debounced
D $8B93 Reads all eight half-rows with BC = $FEFE and RLC B, building a key map at $8B8B and comparing it against the previous one so that only changes count. It calls DEBOUNCE_DELAY first, which is where nearly all of the game's idle time goes: about 7.4ms per scan.
E $8B93 Worth knowing when driving the game from a script: at uncapped emulation speed a key press and release can straddle a scan and be missed entirely, and the game's own ENTER still gets through, so a command comes out as a bare WAIT. Type at realtime speed.

@ $8B78 label=DEBOUNCE_DELAY
c $8B78 Busy-wait, 1000 times round
D $8B78 About 26000 T-states, or 7.4ms. SCAN_KEYBOARD calls it every time, so while the game sits at its prompt this is 88% of everything it does -- idle, not work, but it is also the reason a scan is too expensive to call from inside the drawing code as it stands.

@ $969A label=WAIT_FOR_ANY_KEY
c $969A Wait until any key is pressed
D $969A Polls the whole keyboard through port $FE and returns once something is held, setting the border white on the way out. The game drops into it once the opening picture is finished, before its first prompt -- and a key pressed there is taken as "carry on" and not as a letter, which is why the first letter of the first command typed after the picture always went missing. (The title screen does not use this: it waits in its own loop around $6C60.)

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
D $6F47 Then the index: the first letter doubled and added to $6000 gives the bucket's offset, and that added to $6000 again gives the first entry. From there it walks entries one at a time and gives up when an entry's initial letter stops matching the one typed, which is the bucket's only end marker.
E $6F47 A linear scan, not a binary search -- which is the other half of why the list only has to be grouped by initial letter and can be loosely ordered within a group, as BLOW before BLOOD and HELP before HEART are.

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

@ $C730 label=ACTION_TABLE
b $C730 What to do for each action code
D $C730 A FIND_RECORD table keyed by the action code in $B6E7, whose values are the routines that carry the action out. Codes 1 to 10 are the ten directions and all go to MOVE, so one routine walks everybody everywhere; the other codes each have a handler of their own, a few of them shared.
D $C730 Every handler address here is real code on the table's own evidence: the playthrough reached 29 of the 31 as routine entry points. The two it did not, for codes 42 and 55, are the reason this table matters for the code map -- a dispatch is exactly what following branches cannot see through, so they are named here and seeded from here.

@ $8D9D label=MOVE
c $8D9D Move a character one step
D $8D9D Called for every character that moves, the player included, with the direction in $B6E7. Watched directly: a single turn in which the player only typed INVENTORY ran this 21 times for nine other characters, each wandering on its own -- which is The Hobbit's independent cast, seen from the inside.
D $8D9D For the player -- told apart by $B6EA being zero -- the codes observed are 1 north, 2 south, 3 east, 9 up and 10 down. West was not observed because it was blocked where the test stood, and the four diagonals will be among 4 to 8, but which is which has not been watched and is not asserted here.

@ $C063 label=OBJECT_INDEX
b $C063 Every object and every character, by number
D $C063 A FIND_RECORD table of 61 objects, whose values are the objects' own records. The keys come in two runs: $00 to $2B without a gap, then $3C to $4C. The second run is the characters -- every one of the nine seen wandering in a single turn had its number here, and $B6EA, which says who a sentence is about, holds numbers from that same run. So a character is an object with a number in the upper block, not a separate kind of thing.
D $C063 Object 0 is the player: $B6EA, which is zero when a sentence is about you, holds object numbers, and object 0's location is where the player is.
D $C063 A record is a 16-byte head, then the locations the object is in -- byte 0 of the head says how many -- then its own action handlers (see FIND_OBJECT_HANDLER). Watched rather than inferred: over several turns the one byte that changes in any character's record is the first of those locations, as it wanders; and when the player walked east out of Bag End and back, object 0's location went 1, 4, 1, matching at every step the location whose picture DRAW_LOCATION_PICTURE looked up. Most things are in one place; the ones in several are fixtures between rooms. Object 5 is in locations 1 and 4 -- exactly the two rooms that walk went between, so it is the round green door.
D $C063 What the rest of the head means is open. The door's record does not change at all when it is opened and closed, so being open is not stored here -- most likely on the room's exit, which is in the room records, not yet decoded. $95DF tests bit 6 and bit 3 of (IX+$07), consistent with a flags byte at offset 7, but not traced from here and not asserted.

@ $9BCA label=GET_OBJECT
c $9BCA Find an object's record
D $9BCA The object number in A goes to FIND_RECORD against OBJECT_INDEX, and the record's address comes back in IX. Twenty-one routines use it.
R $9BCA I:A The object number
R $9BCA O:IX The object's record

@ $9B81 label=FIND_OBJECT_HANDLER
c $9B81 Find an object's own handler for an action
D $9B81 Skips the record's 16-byte head and the list whose length is byte 0 of it, and searches what follows with FIND_RECORD. That is the object record's grammar stated by the game itself: parsed this way, all 61 records end exactly where the next begins, and the last exactly where ACTION_TABLE starts.
D $9B81 So an object can carry handlers of its own for particular actions, and this is how the game asks whether it does before falling back on the ordinary ones. A handler of $0000 in a record is not an address.
R $9B81 I:A The action code
R $9B81 I:IX The object's record
R $9B81 O:IX The matching handler record, or the $FF that ended the list
R $9B81 O:F NZ if the object has its own handler for this action

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

# --------------------------------------------------------------------------
# Rooms and exits
# --------------------------------------------------------------------------

@ $9BB1 label=GET_ROOM
c $9BB1 Find a location's record
D $9BB1 Anything from $50 up is not a location and gets zero back; otherwise the record's address is read straight out of ROOM_POINTERS, two bytes per location. Unlike objects there is no search: locations are numbered densely, so a table indexed by number is cheaper than FIND_RECORD.
R $9BB1 I:A The location
R $9BB1 O:IX Its record

@ $9D37 label=ACTOR_ROOM
c $9D37 The record of the room the current actor is in
D $9D37 $B70C points at the object record of whoever is acting this turn -- the player or any other character -- and its location is at +$10, so the same code moves everybody.
R $9D37 O:IX The room record

@ $9E95 label=FIRST_EXIT
c $9E95 Point IX just before the actor's room's first exit
D $9E95 The room's record, plus 7: three short of the exits, because NEXT_EXIT steps three before it looks.

@ $9B93 label=NEXT_EXIT
c $9B93 Step to the next three-byte entry
D $9B93 Adds 3 to IX and returns Z at the $FF that ends a list. Shared with other lists of three-byte entries, which is why it also loads IY from bytes 1 and 2 -- for an exit those are the object it goes through and the destination, not an address.

@ $9F08 label=FIND_EXIT
c $9F08 Find the actor's room's exit in a direction
D $9F08 Walks the exits for one whose direction matches and whose destination is not zero, and returns with IX on it. Watched as well as read: rewinding from the moment the player's location changed on EAST out of Bag End to where this returned found IX at $BAA1, the direction 3, and the record 03 05 04 -- east, through the round green door, to location 4.
R $9F08 I:A The direction, 1-10
R $9F08 O:IX The exit
R $9F08 O:F NZ if there is one

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
