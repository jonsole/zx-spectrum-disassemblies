; Fairlight (The Edge, 1985), Release 2: the annotations, layered over the
; control file sna2ctl makes from the code map and over the level data
; scripts/fairlight_data.py generates at each build. Addresses, structure
; and prose only. Every routine and table is described.
;
; The axes. An object's place is +6, +7 and +8: +6 along the floor (x,
; up and to the right on the screen), +7 the height of its top, +8 across
; the floor (up and to the left). The routines from $F2F7 to $F905 call +8
; y and +7 the height; those from $FA83 on, and the variables at $FF80,
; call +7 y and +8 z, as the author's own direction bits do. Where it
; matters the offset is given, which is the same in both.
;
; Some names and facts here were first found by Ville Krumlinde, whose
; disassembly (github.com/VilleKrumlinde/FairlightZ80) is credited where
; used; it has no licence, so only facts and names are taken from it, and
; every word here is this project's own. See notes/fairlight/.

; --------------------------------------------------------------------------
; Graphics below the rooms.
; --------------------------------------------------------------------------

# Tables and buffers that must stay whole: sna2ctl's guesses inside them
# are dropped (see declared_spans in build_fairlight.py).
; span $5D14,288
; span $617C,544
; span $639C,1281
; span $7CCB,53
; span $8736,36
; span $9E68,96
; span $A8FC,40
; span $A924,3420
; span $B680,6
; span $B734,932
; span $BC18,120
; span $BC90,20
; span $BCA4,860
; span $C01A,12
; span $C0B0,972
; span $C4BA,38
; span $D135,443
; span $D694,1068
; span $DAC0,31
; span $DCC9,112
; span $E026,18
; span $E09A,10
; span $E582,21
; span $FF6A,22
; span $FF80,128

# Operands that only look like addresses.
@ $E42B nowarn
@ $E43F nowarn
@ $E452 nowarn
@ $E456 nowarn
@ $EBF5 nowarn
@ $ECAB nowarn
@ $EF00 nowarn
@ $EF10 nowarn
@ $EF13 nowarn
@ $EF17 nowarn
@ $F4E9 nowarn
@ $F89E nowarn
@ $F8BF nowarn
@ $F920 nowarn

# --------------------------------------------------------------------------
# Below the code, the start-up, the title, entering and drawing a room
# --------------------------------------------------------------------------

@ $5D14 label=TYPE48_FRAMES
b $5D14 Frames 1 and 2 of object type 48, striking
D $5D14 Two more 24 by 24 sprites, image then mask like every sprite, in the style of #R$5C84 (type 48's own sprite), which they follow directly: the same winged creature in two other poses.
D $5D14 They are its strike. When the knight comes within reach in front of one of these creatures, the object dispatcher (#R$F1E0, at the author's I4) takes 3 from LIFE and steps the creature's frames from #R$5C84 on, 144 bytes each (the animation step, the author's ANIM, inside #R$F595). Bits 3-5 of a type 48 object's +$11 give its last frame, and every one has $10 there (measured on those in room 45): frames 0 to 2, #R$5C84 and these two. The strike never happened in the build's sessions (that code never ran), nor in half a minute of play in room 45 tried for this description, so no object showed these frames and no generated entry lays them out. #R$F1E0 describes the strike.
B $5D14,72,3 Frame 1: the image, 24 rows of three bytes
B $5D5C,72,3 Frame 1: the mask
B $5DA4,72,3 Frame 2: the image
B $5DEC,72,3 Frame 2: the mask

@ $617C label=SOURCE_AND_STACK
t $617C Leftover source text, and the game's stack
D $617C Part of the game's own source code, as text, left in memory when the tape was made: numbered lines (a two-byte line number, the text with tabs between the fields, a carriage return), here lines 6240-6670. They are the source of the end of the pick-up code in #R$F52A (the author's WEI3, and calls of routines he called ROMM, DOE, SRP and INFOR: #R$F4E6, the instruction three bytes before it, #R$ECBD and #R$EC4C) and the start of the joystick and keyboard reading (#R$F595, his I88 onwards); the text goes on at #R$639C. The game never reads it.
D $617C The top of it is the game's stack: #R$C47C sets SP two bytes below the block's end, and in the build's sessions the stack reached down 150 bytes below that.
T $617C,542,16
@ $639A label=STACK_TOP
B $639A,2,2 SP starts here, so the first word pushed goes just below

t $639C The master copy of the object table, the variables and the knight's record
D $639C At start-up (#R$C47C) the first 1200 bytes of the object table are copied here from #R$A924, the variables from #R$FF80 (61 bytes) and the knight's record from #R$BC90 (20 bytes); a new game (#R$F065) copies them back. The 1200 bytes hold the first 183 records and a piece of the 184th, which takes in all 163 six-byte records at the start of the table: the things whose room the game changes (#R$F4E6 finds a thing's record by its number, six bytes a number, which only works among those). The later records are not restored; whether the game ever changes one of them is not settled.
D $639C On the tape these bytes are other things. The first 293 are more of the source text of #R$617C (lines 6680-6890, more of the keyboard reading in #R$F595, to the author's INP5 and a little after). After them come bytes that are not text: machine code, by the look of it, whose calls and jumps go to addresses in this same block and which reads one of the ROM's system variables, so it ran at this address on the development machine; perhaps part of the development tools. Not identified.
@ $639C label=MASTER_OBJECTS
T $639C,1200,16
@ $684C label=MASTER_VARIABLES
T $684C,61,16
@ $6889 label=MASTER_KNIGHT
T $6889,20,16

@ $689D label=ZEROS_BEFORE_ROOMS
u $689D Unused
D $689D Nineteen zeros between the master copy and the rooms (#R$68B0). Nothing reads or writes them.

@ $7CCB label=BYTES_AFTER_PARTS
b $7CCB Bytes after the parts
D $7CCB 53 bytes between the last part (#R$7CBC) and the sprites, not identified. No room or part reaches them, and no address of any of them appears anywhere in the game.
D $7CCB The first nine parse as drawing commands (two points, a mode bit, the second point, a point and a line), but what follows does not end with $E5. The last eighteen are six groups of a byte and a word, and every word is an address inside this block (four of them different, 4 to 20 bytes apart), so the block was made for this address; it may be a table left from an earlier version.
B $7CCB,53,8,1,8,8,8,2,3,3,3,3,3,3 Nine bytes that parse as drawing commands; 26 more; six groups of a byte and an address in this block

@ $8736 label=BYTES_AFTER_TYPE49
b $8736 Bytes between two sprites
D $8736 36 bytes between the sprites at #R$86A6 and #R$875A that no object showed in the sessions and no template or table points at. They are not a sprite at any width that divides them (8, 16, 24 or 48 pixels): at every width the image's bits fall where the mask says the background shows. Drawn 16 pixels wide they are diagonal stripes. Not identified.
B $8736,36,8

@ $9E68 label=DIAGONAL_SPRITE
b $9E68 A sprite no object uses
D $9E68 A 24 by 16 sprite, image then mask, between the sprites at #R$9D78 and #R$9EC8: a thick diagonal shaft, like a staff or a lance, lying from top left to bottom right. Image and mask agree, so it is a sprite, but no template, object or table points at it, and it is not a frame of its neighbours (they are other sizes). Perhaps the picture of a thing that was left out of the game.
B $9E68,48,3 The image, 16 rows of three bytes
B $9E98,48,3 The mask

@ $A8FC label=SOURCE_BEFORE_OBJECTS
t $A8FC Leftover source text
D $A8FC Assembler source text, the same kind as at #R$617C: the end of line 3130, one of the DEFB lines of the object table's source; the text runs on at #R$A924. Three of the code's addresses fall in it, six, five and three bytes below #R$A924: bases to which a multiple of six is added, to reach a field of a record of the object table (#R$F4E6, #R$F7C4, #R$F906).
T $A8FC,40,16

@ $A924 label=OBJECTS
t $A924 Where the object table is kept while the game runs
D $A924 The start-up (#R$C47C) copies 3420 bytes here from #R$C4E0: the object table (381 records, 3157 bytes with the $FF that ends it) and 263 bytes of the leftover text that follows it on the tape. IY+$3A points here. On the tape these bytes are leftover source text: lines 3140-3920, the DEFB lines of the object table and comments between them, which the table copied over them repeats byte for byte; the game never reads the text.
D $A924 The source text is one run of lines through this part of memory, interrupted wherever the game's own bytes lie: #R$A8FC (line 3130), here, #R$B680, then (after the title page's routine) #R$B734 (lines 3970-4180), then (after the font and the first seven records) #R$BCA4 (lines 4300-4510), and the end of #R$C0B0 (lines 4920-4940, the table's last line).
T $A924,3420,16

@ $B680 label=SOURCE_BEFORE_TITLE
t $B680 Leftover source text
D $B680 Six bytes of a DEFB line of the object table's source, between #R$A924's text and the title page's routine.
T $B680,6,6

@ $B686 label=TITLE_PAGE_TEXT
c $B686 Print the title page's words
D $B686 Called by #R$F065 once the title picture (room 79) is drawn and coloured: the game's name and subtitle, its author and publisher, and the keys and what each does, each at its own place. It is all one string for the printer (#R$EBFE), after the CALL, laid out below by the printer's commands: $C8 and a position, the characters, and $A4 to end.
  $B686,3 The string follows the CALL.
  $B733,1 The printer returns here, after the string.

@ $B734 label=TEMPLATES
t $B734 Where the object templates are kept while the game runs
D $B734 The start-up (#R$C47C) copies 932 bytes here from #R$D2F0: the templates for object types 0-$38, 11 bytes each; from offset 630 (LARGE_TEMPLATES), those for types $46-$54, 9 bytes each; and from offset 784 the patches for the codes $E6 up in a room's object list, six bytes each. The patches' base (PATCHES, offset 778) is where code $E5 would find its entry: PATCH_RECORDS in #R$E5E8 counts from there. On the tape these bytes are leftover source text (lines 3970-4180, more of the object table's DEFB lines); the game never reads it.
T $B734,630,16
@ $B9AA label=LARGE_TEMPLATES
T $B9AA,148,16
@ $BA3E label=PATCHES
T $BA3E,154,16

@ $BC18 label=FIXED_RECORDS
b $BC18 The room's floor, ceiling and walls: six object records
D $BC18 Records 1 to 6 of the object records (the knight's is the seventh, #R$BC90), twenty bytes each, laid out like his. They have no sprite (+4 and +5 are zero, so nothing draws them) and huge sizes, and they box the room in for the collision code, which tests every record in use from the first (#R$FCA5): record 1 is the floor, ten high with its top at +7; record 2 the ceiling; records 3 and 4 the walls across +6, one at each end; records 5 and 6 the walls across +8. Each reaches right across the room the other two ways ($FF). An object occupies +6 to +6 plus +9, +7 less +10 to +7, and +8 to +8 plus +11 (#R$F036).
D $BC18 A room sets them with the patch code in its object list (or a part's), $E6 up: PATCH_RECORDS in #R$E5E8 writes the patch's six bytes into the floor's and the ceiling's +7, records 3 and 4's +6 and records 5 and 6's +8. In most rooms the floor's top is 50, the height the knight's feet are at when he stands on it. Every room the knight plays in has a patch in its list or in one of its parts; only rooms 1, 79 and 81 (GAME OVER, the title and the end of the quest) have none (read from the rooms' commands, parts followed). On the tape they hold the values below; entering rooms 3, 45, 80 and 5 in the simulator showed the walls moving to that room's patch (measured).
B $BC18,20,6,3,3,8 Record 1, the floor: no sprite; at 50, 50, 50; 255 by 10 by 255
B $BC2C,20,6,3,3,8 Record 2, the ceiling: at 50, 120, 50 on the tape; 255 by 10 by 255
B $BC40,20,6,3,3,8 Record 3, a wall across +6: at 178, 255, 50; 10 by 255 by 255
B $BC54,20,6,3,3,8 Record 4, the other wall across +6: at 40, 255, 50; 10 by 255 by 255
B $BC68,20,6,3,3,8 Record 5, a wall across +8: at 50, 255, 175 on the tape; 255 by 255 by 10
B $BC7C,20,6,3,3,8 Record 6, the other wall across +8: the same on the tape

b $BC90 The knight's object record
D $BC90 Record 7; the room's objects follow from #R$BCA4. Twenty bytes, the layout of every object record. The fields this part of the code reads: +0 and +1, where the sprite is on the screen (x, and y of its top row, counted up from the bottom of the screen); +2 and +3, its width in pixels and height in rows; +4 and +5, the sprite (image, then mask); +6 to +8, where the object is in the room, +6 and +8 along the floor and +7 the height of its top (#R$E4F7 turns a change in them into a change of +0 and +1); +9 to +11, its size along each; +12, its kind in the low nibble and flags above it; +19, its number in the object table (0 for the knight, who is not in it).
D $BC90 The listing names the fields wherever IX holds a record's address: OBJ_SCREEN_X (+0), OBJ_SCREEN_Y (+1), OBJ_WIDTH (+2), OBJ_ROWS (+3), OBJ_SPRITE (+4, a word), OBJ_X (+6), OBJ_TOP (+7), OBJ_Z (+8), OBJ_LEN_X (+9), OBJ_HEIGHT (+10), OBJ_LEN_Z (+11), OBJ_KIND (+12), OBJ_DIRECTION (+13), OBJ_STATE (+14), OBJ_COUNT (+15), OBJ_WEIGHT (+16), OBJ_FRAME (+17), OBJ_COURSE (+18) and OBJ_NUMBER (+19); OBJ_SIZE is the record's twenty bytes. They are EQUs at the top of the source file. A door's record uses the same bytes for its own things -- +13 the room behind it, +14 the key, +15, +16 and +18 where the knight arrives, +17 the way through -- and the routines that read a door say so.
D $BC90 On the tape this is his record at the start of a game. #R$C47C copies it to the master copy (#R$639C), and #R$F065 copies it back at every new game and whenever he is carried off to another room, all but +14: bit 5 of +14 says which way his sprite images face, and #R$F117 turns the images themselves round in memory when he turns, so the record must go on saying which way they face now.
@ $BC90 label=KNIGHT
B $BC90,4,2 Where his sprite is (x 60, y 62), and its size (24 pixels by 31 rows)
@ $BC94 label=KNIGHT_SPRITE
W $BC94,2 His sprite: the first of his frames
B $BC96,8,3,3,1,1 +6 to +8, where he is in the room (54, 78, 110); +9 to +11, his size (8, 28, 8); +12, his kind (0) and flags; +13
@ $BC9E label=KNIGHT_FLAGS
B $BC9E,6,1,5 +14, which a reset of the record keeps (bit 5: which way his sprite images face); +15 to +19 (+19, his number: 0)

@ $BCA4 label=RECORDS
t $BCA4 The object records for the room's things
D $BCA4 Records 8 up: filled when a room is entered, twenty bytes a record. #R$FD20 copies in the records of the things carried and #R$EACC makes the rest from the room's entries in the object table, placed by the room's object list (#R$E5E8); IY+$38 holds the address of the next free record and IY+$00 counts the records in use, the fixed seven included. On the tape: leftover source text, lines 4300-4510 (DEFB lines of the object table, and a comment line that heads the table's second part); the game never reads it.
T $BCA4,860,16

@ $C000 label=LOADING_TUNE
@ $C07F isub=LD IXH,D
@ $C08B isub=LD E,IXH
c $C000 Play the loading tune until a key is pressed
D $C000 Called once, from #R$C47C, while the loading screen is still up: two voices on the beeper, a note at a time (#R$C049), with the ROM's KEY-SCAN between notes. The voices' pointers are set from #R$C0B0 first, so the tune starts from its beginning. The tune lasts 52.6 seconds (418 note bytes a voice, of which the last three rest in both and are passed over, so 415 notes heard, each 0.127 s; measured for the sounds page); after it both voices rest, and the routine goes on scanning the keyboard in silence.
D $C000 Interrupts are off while it plays (KEY-SCAN does not need them); it turns them on as it returns, and #R$C47C turns them off again three instructions later, for good.
D $C000 From the first room on, these bytes are part of the clean copy of the screen (#R$F10B copies the screen here), so the tune cannot be played again.
  $C000,11 Both voices to the start of the tune: the four pointers from #R$C0B0.
  $C00B,1 Interrupts off while it plays.
  $C00C,3 Play a note (once both voices are resting, nothing).
  $C00F,9 KEY-SCAN leaves E at $FF while no key is pressed.
  $C018,2 A key.

b $C01A The loading tune's variables
D $C01A Set by #R$C000 and the player. On the tape, the pointers hold where the tune had got to when the tape was made; #R$C000 sets them from #R$C0B0 before it plays.
@ $C01A label=VOICE_ONE_NOTE
B $C01A,1,1 Voice one's note, from #R$C026
@ $C01B label=VOICE_TWO_NOTE
B $C01B,1,1 Voice two's
@ $C01C label=TUNE_PORT
B $C01C,1,1 What both voices send to port $FE before they toggle the speaker bit: 0, the border black
@ $C01D label=VOICE_ONE_AT
W $C01D,4,4 Voice one: the byte before its next note, and where it goes back to at its end
@ $C021 label=VOICE_TWO_AT
W $C021,4,4 Voice two: the same
@ $C025 label=NOTE_LENGTH
B $C025,1,1 A note lasts 256 less this ($EE: 18) passes of 256 turns of the player's loop

@ $C026 label=TUNE_NEXT_NOTE
c $C026 Take a voice's next note
D $C026 A voice's first word is the address of the note last played, and the byte after it is the next. $40 marks a voice's end; the voice then carries on from the address in its second word (#R$C041), which for both voices is their last note, a rest, so the tune plays once and then rests for ever.
R $C026 HL A voice's two words (at offset 3 or 7 of #R$C01A)
R $C026 O:A The note
  $C026,4 DE: the address after the note last played.
  $C02A,5 The voice's end?
  $C02F,4 No: DE is the voice's place now.

@ $C033 label=TUNE_PITCH
c $C033 Look up a note's pitch
D $C033 A note is a number of semitones, -12 to 40, or 41 for a rest. Twelve is added to it to index the table of pitches at offset 8 of #R$C0B0 (TUNE_NOTES), which gives the number of turns of the player's loop between two toggles of the speaker bit. The rest's entry is 1: a toggle every turn, about 18 kHz, too high to be heard as a note; when both voices rest, #R$C049 plays nothing at all.
R $C033 HL A voice's note (#R$C01A or the byte after it)
R $C033 O:H Its pitch: the turns of the loop between two toggles
R $C033 O:L 1, the countdown to the first toggle
  $C033,10 The table, indexed by the note plus 12.
  $C03D,4 H: the pitch; L: 1, so that the voice toggles on the first turn.

@ $C041 label=TUNE_RESTART_VOICE
c $C041 Send a voice back to where it repeats from
D $C041 Reached from #R$C026 at a voice's $40. It never ran in the build's sessions, which press a key long before the end of the tune; the sounds page's recording runs it.
R $C041 HL The high byte of the voice's first word
  $C041,6 DE: the address in the voice's second word; HL back.
  $C047,2 Take the note there, the voice's last.

@ $C049 label=TUNE_PLAY_NOTE
c $C049 Play one note of the loading tune
D $C049 Both voices' next notes are taken and their pitches looked up. Unless both are resting, the note is played for 18 passes of 256 turns of a loop that sends a byte to the speaker's port twice a turn, one for each voice. Each voice keeps its own copy of the port byte (voice one's in A', voice two's in A) and its own countdown (E, and L), and toggles the speaker bit in its copy when the countdown runs out; so each is a square wave at its own pitch, and the two sound together. The two ways round the loop take the same time, 96 T-states (the JR Z that never jumps and the NOPs pad the shorter), so neither voice's pitch depends on the other's.
D $C049 Once both voices rest, it returns at once. That never ran in the sessions (the sounds page's runs reach it), and nor did the end of a note by way of the first DJNZ: which of the two ends a note depends only on voice two's countdown in the note's last turn.
  $C049,9 Voice one's next note.
  $C052,9 Voice two's.
  $C05B,7 Voice one's pitch, on the stack.
  $C062,7 Voice two's: H its pitch, L its countdown; D and E voice one's.
  $C069,9 Both resting: nothing to play.
  $C072,6 BC counts the note's turns: B 256 at a time, C up from $EE to 0.
  $C078,7 Both voices start from the same port byte: voice one's copy in A', voice two's in A.
  $C07F,2 Voice one's pitch in IXh, to reload its countdown from.
  $C081,2 D: the speaker bit (bit 4 of port $FE).
  $C083,2 Padding.
  $C085,6 Voice one: its port byte out, and its countdown down; not run out, the other way round.
  $C08B,3 Run out: reload it, and toggle voice one's speaker bit.
  $C08E,5 Voice two: its countdown down; not run out, out with its port byte as it is.
  $C093,4 Run out: out with voice two's port byte; reload its countdown and toggle its speaker bit.
  $C097,7 Next turn; next 256; the note is over.
  $C09E,2 As long as the reload above, and never jumps: Z is clear here.
  $C0A0,5 Voice two: its countdown down; run out, go and toggle it.
  $C0A5,4 Out with voice two's port byte, and padding.
  $C0A9,7 Next turn; next 256; the note is over.

@ $C0B0 label=TUNE_VOICES
b $C0B0 The loading tune: where the voices start, the pitches, and the two voices
D $C0B0 Four words first, copied to #R$C01A by #R$C000: for each voice, the byte before its first note (never played) and the address it goes back to after its end marker, which is its own last note, a rest.
D $C0B0 From offset 8 (TUNE_NOTES), the table of pitches: 54 bytes, one for each note from -12 to 40 and the rest's 1. Each is the number of turns of the player's loop between two toggles of the speaker, $FF down to $0C, each about 0.944 of the one before: a semitone.
D $C0B0 From offset 63, voice one's 418 notes, and $40 to end them at offset 481; from offset 483, voice two's 418 and its $40 at offset 901. A note is a signed number of semitones ($FB is -5); 41 ($29) is a rest.
D $C0B0 From offset 902 to the end: leftover source text, the last lines of the object table's source (lines 4920-4940, with the DEFB 255 that ends the table), continuing the text at #R$BCA4, and ten bytes that are not text.
W $C0B0,8,4 Voice one: its first note's address less one, and where it goes back to; then voice two's
@ $C0B8 label=TUNE_NOTES
B $C0B8,48,8 Pitches for the notes -12 to 35
B $C0E8,8,8 Pitches for 36 to 40; 1, for the rest (41); the byte before voice one's first note; its first note
B $C0F0,416,8 Voice one
B $C290,8,8 Voice one's last note (a rest, which it repeats after its end); its end marker; the byte before voice two's first note; its first five
B $C298,408,8 Voice two
B $C430,8,8 Voice two's last notes and its end marker; the start of the leftover text
T $C438,68,16

@ $C47C label=START
c $C47C The game's first instruction
D $C47C The loader returns here once it has checked its checksum and cleared itself. The stack goes near the top of #R$617C; the loading tune plays until a key is pressed; IY is set to the variables, and interrupts turned off for the rest of the game; the object table and the templates are copied from where the tape has them to where the game reads them; a master copy of the object table, the variables and the knight's record is made at #R$639C, for each new game to start from; and the title page begins.
D $C47C The game runs with interrupts off from here on (measured: the interrupt flip-flop stays clear in the simulator, and the ROM's frame counter in its system variables never moves). It has to: the sprites from #R$5B00 up lie over the ROM's system variables, which the ROM's interrupt routine writes to fifty times a second.
  $C47C,4 The stack: two bytes below the end of #R$617C, over leftover source text.
  $C480,3 The loading tune, until a key is pressed.
  $C483,4 IY at the variables, from here on.
  $C487,1 Interrupts off for good (the tune turned them on as it returned).
  $C488,11 The object table, and 263 bytes of text after it: 3420 bytes from #R$C4E0 to #R$A924.
  $C493,11 The templates and the patches: 932 bytes from #R$D2F0 to #R$B734.
  $C49E,11 The master copy: the object table's first 1200 bytes...
  $C4A9,7 ...the 61 bytes of variables a new game starts with (IY+$00 to IY+$3C; B is 0 after the LDIR)...
  $C4B0,7 ...and the knight's record.
  $C4B7,3 The title page.

@ $C4BA label=SOURCE_AFTER_START
t $C4BA Leftover source text
D $C4BA Three lines of source text (12860-12870 and part of the line before), from code that stores into IY+$71 after an AND 5, with labels the author called BT32 and BT33: much like the code at #R$FA83 by the AND 5 there, though not line for line the same. The text runs on, with gaps where the game's bytes lie, at #R$D135 and #R$D694.
T $C4BA,38,16

@ $D135 label=SOURCE_AFTER_OBJECTS
t $D135 Leftover source text
D $D135 More of the source text, lines 15380-15690, just after the object table on the tape; the start-up's copy to #R$A924 takes the first 263 bytes of it along. It is the source of the end of #R$FD20: the DEFB of the glyphs of one of the quest's closing messages, the call of MESS2 (#R$DFF2) and the jump to WAIT (#R$F0D2), and the start of the room's set-up, from the label ROS (the LD (IY),7 there) to the loop that copies the records of the things carried, OBJD and OB2, with DATLEN for the record's length and the variable bases V (IY, #R$FF80) and T (IY+$64).
T $D135,443,16

@ $D694 label=SOURCE_AFTER_TEMPLATES
t $D694 Leftover source text
D $D694 More of the source text, lines 16370-17190: the source of the part of #R$FE47 that uses the thing in hand and chooses one of the five places to carry things, with its labels STAR2, ST3 to ST9, ST20 to ST22, STE3 and USE4 to USE6, and calls of routines the author called INPUT, EEN, TELE, INFO0, INFOR and PRINT (#R$F0DF, #R$F906, the entry into a room in #R$F065, #R$EC75, #R$EC4C and #R$EBFE).
D $D694 Once the game runs, its buffers lie over these bytes: the clean copy of the screen runs to offset 363, and the four pages #R$E3E4 composites from start at offsets 364 (page $D8, BUFFER_D800), 620 (page $D9, BUFFER_D900) and 876 (page $DA, BUFFER_DA00); page $DB lies over the loader's leftovers.
T $D694,364,16
@ $D800 label=BUFFER_D800
B $D800,1,1
T $D801,255,16
@ $D900 label=BUFFER_D900
B $D900,1,1
T $D901,255,16
@ $DA00 label=BUFFER_DA00
B $DA00,1,1
T $DA01,191,16

@ $DAC0 label=LOADER_TABLE
b $DAC0 What the loader left: its table of pieces, its stack and its checksum
D $DAC0 The tape's long block does not load these bytes: the loader's second stage put them here, and they are as its turbo stage left them. At the start of that stage (a snapshot taken there) the block begins with a jump to #R$DADF, and from offset 3 the table the loader pops, with SP, as it goes: a zero (no more screen lines), then a length and an address for each piece of the game, the first of which (14 bytes at offset 9) writes the rest of the table ahead of where it is being read, and a zero length to end. As the stack pointer worked up through the table, the loader's calls pushed their return addresses into the words it had read, which is why most of it now holds two return addresses over and over.
D $DAC0 After the table: at offset 23, the address the loader returned to when the table ran out, the checksum test at the end of #R$DADF; at offset 25, the last piece loaded, three bytes: the address the loader's final RET goes to, #R$C47C, and a byte of the checksum; at offset 28, the byte the checksum test wants (it adds H to the byte at offset 27 and compares); at offset 29, the header the long block starts with, which the loader checks ($03F6).
B $DAC0,31,3,2,8,8,2,2,2,1,1,2 Once a jump to the turbo stage; the table's first zero; return addresses over the table; its zero length; the return to the checksum test; the return to #R$C47C and the checksum's byte; what the test wants; the header

@ $DADF label=LOADER_CLEARED
s $DADF The loader, cleared
D $DADF The loader's turbo stage, which clears itself as its last act: an LD (HL),0 and an LDIR run zeros from here to the end of the block. The LDIR's own first byte is the last it clears; the processor then fetches the instruction again (an LDIR repeats by going back to itself), finds a NOP, and goes on through the LDIR's second byte (OR B) to the RET after it, which takes the last piece's return address off the stack: #R$C47C. So 488 bytes are cleared, and the last two are not zeros. (Read from the loader's code in a snapshot taken where the turbo stage starts.)
D $DADF The code names offset 289 (BUFFER_DC00) only as the end of the 512 bytes below it that #R$EDC6 clears: pages $DA and $DB.
S $DADF,289,289
@ $DC00 label=BUFFER_DC00
B $DC00,201,8 Zeros, but for the last two bytes: the LDIR's second byte, and the RET

@ $DCC9 label=LOADER_FAILURE
b $DCC9 The loader's failure routine
D $DCC9 Where the loader goes if its checksum test fails. It never runs on a good load and is kept as data here; what it does, read from the bytes: it clears memory from its own first bytes down to #R$5B00 (an LDDR), prints a line in the ROM's characters on the bottom row of the screen, bright yellow and flashing on black, asking for the tape to be rewound and loaded again, makes the border black, warbles on the beeper with two calls of the ROM's BEEPER 233 times over, and resets the machine (RST 0).
D $DCC9 After its message, the byte the loader keeps its decryption key in (it XORs each byte loaded with it, and adds to it), as the load left it; and three counters of the countdown the loader draws over the loading screen.
B $DCC9,80,8 The routine
B $DD19,32,4,8,8,8,1,3 The routine's last four bytes (the end of the BEEPER loop, and the RST 0); the message, 24 characters of ASCII; the key; the countdown's counters

@ $DFF2 label=MESS2
c $DFF2 Print the closing lines of the quest
D $DFF2 The author's MESS2: the source text at #R$D135 calls MESS2 and jumps to WAIT at the end of #R$FD20, just as the code there calls this and jumps to #R$F0D2. Two lines under either ending's message in room 81, whether the quest succeeded or not: that the quest continues, and where -- the title of the sequel.
  $DFF2,3 The two lines follow the CALL.
  $E025,1 The printer returns here, after the string.

@ $E026 label=SYMBOLS_AFTER_MESS2
b $E026 More of the symbol table
D $E026 Eighteen bytes of the assembler's symbol table left between #R$DFF2 and #R$E038, the format of #R$DD39: the last byte of a value, a whole symbol, and the start of another. The whole one is named I62, but its value is 43 more than the value the table at #R$DD39 gives I62 (both are instructions in #R$F309); two symbols of one name cannot be in one tree, so these scraps are from another state of the table than the one at #R$DD39: an earlier assembly, or an earlier pass.
B $E026,18,1,4,1,3,2,4,1,2 The end of a value; links, 1, the name I62 and its value; the links and the 1 of a symbol whose name the routine at #R$E038 cuts off

@ $E038 label=SHOW_MESSAGE
c $E038 Show a message under the room, and take it away again
D $E038 Called once a pass by the main loop (#R$FE47). A message is asked for by putting its number in IY+$07: 1 when the knight's way is blocked (#R$F309, #R$F7C4), 2 when a door is locked (#R$F7C4), 3 when what he would pick up is too heavy (#R$F52A). Message 1 prints a B and then shares message 2's word.
D $E038 The message is printed at x 28, y 12, over LIFE's digits, and stays for ten passes, counted in IY+$08, while bit 6 of IY+$17 is set; then nine spaces clear it, and bit 0 of IY+$17 asks the main loop to print LIFE again.
  $E038,6 Everything here prints at x 28, y 12.
  $E03E,6 A new message?
  $E044,9 No: if one is showing, count down its passes.
  $E04D,11 Its time is up: clear it, and have LIFE printed again.
  $E062,1 The printer returns here, after the string.
  $E063,12 A new message: ten passes, and it has been taken.
  $E06F,7 Message 1: B...
  $E078,2 ...and on to the word of message 2.
  $E07A,7 Message 2.
  $E088,1 The printer returns here.
  $E089,6 Message 3.
  $E099,1 The printer returns here.

@ $E09A label=SYMBOLS_BEFORE_TEXTURES
b $E09A More of the symbol table
D $E09A Ten bytes of the symbol table left between #R$E038 and the textures, as at #R$E026. They do not parse as cleanly: read as the end of a link, a flag byte of 0 (every whole symbol at #R$DD39 has 1 there), a one-letter name (J), its value (a jump target in this release, inside #R$F309), and the links and flag of the next symbol, cut off by the textures. Not settled.
B $E09A,10,2,1,1,2,4 The end of a link; 0; J; its value; the next symbol's links and its 1

@ $E3E4 label=COMPOSITE_TO_SCREEN
c $E3E4 Redraw a rectangle of the screen from an image, its mask and the clean copy
D $E3E4 Krumlinde's RTN_Composite_To_Screen. The pixels the game draws on the screen once a room is drawn go through here (the colours are #R$F0FB's): a moving object's new picture (from #R$ECBD), the box on the panel for the thing in use (#R$EC75, #R$EC4C), and every character printed (#R$EBFE, by way of the second entry, three instructions in).
D $E3E4 The rectangle's top left corner is x, y at IY+$64 and IY+$65 (y counted up from the bottom of the screen, as everywhere in the game), its width in bytes at IY+$73 and its height in rows at IY+$67. A row is written as its width plus one screen bytes, since the image is shifted to x's pixel within its byte, and each byte is made from four buffer pages ($D8 to $DB: the 1 KB after the clean copy, from offset 364 of #R$D694), indexed by one count that goes on through the rows: where page $D8 has a bit set, the screen keeps what it has; elsewhere, where page $D9 has it clear, the pixel comes from the image (IX); where $D9 has it set, it comes from page $DB if page $DA has it set too (when bit 1 of IY+$71 says pages $DA and $DB are in use), and otherwise from the clean copy of the room, the byte 32 KB above the screen byte (the copy #R$F10B and room code $E2 make).
D $E3E4 The callers fill the pages. For a moving object, #R$ECBD and the routines it calls (#R$ED47, #R$EDC6, #R$EE8D) fill them from the objects that overlap the rectangle: the object's own mask, what stands in front of it, and what moves behind it (see there). The printer clears pages $D8 and $D9, so a character is drawn as it is; #R$EC75 sets every bit of page $D9, which puts the clean copy back over the box. The pixels to the left of x in each row's first byte are marked in page $D8 by this routine itself, so that they stay as they are.
D $E3E4 The shift is made by jumping into a run of seven RRCAs: the start rewrites the operand of the JR before them. It also rewrites the JRs round the steps for pages $DA and $DB (to skip them unless they are in use) and the one before a row's last byte (to skip it when x is on a byte boundary, as nothing spills into it). Rows above the top of the screen (y above 191) are skipped, and it stops at the bottom of the screen.
D $E3E4 At this entry the image's address is the word at IY+$68, and the routine starts three rows before it, as #R$ECBD's rectangle does; at the second, COMPOSITE_FROM_IX, three instructions in, HL is the address to start from.
@ $E3F3 label=COMPOSITE_FROM_IX
  $E3E4,15 HL: the image less three rows (IY+$73 bytes each): #R$ECBD's rectangle starts three rows above the object's sprite.
  $E3F3,3 IX: where the image's bytes are read from.
  $E3F6,4 C': the index into the pages, from 0.
  $E3FA,9 B, C: the top left corner. Is the top on the screen (y 191 or less)? A: 191 less y, its row from the top.
  $E403,13 No: take the rows above the screen off the height; if none are left, there is nothing to draw.
  $E410,17 And skip them: IX on by the width for each, the page index by the width plus one.
  $E421,2 Start at the top row.
  $E423,3 HL: the screen address of the rectangle's first byte (the ROM's PIXEL-ADD, from its LD B,A on); A: x's pixel within its byte.
  $E426,8 Rewrite the JR into the RRCAs, to rotate the image right by x's pixel.
  $E42E,9 D: the bits of a rotated byte that stay in their own screen byte; E: those that spill into the next.
  $E437,11 Rewrite the JR before a row's last byte: skip it when x is on a byte boundary.
  $E442,23 Rewrite the two JRs round the steps for pages $DA and $DB: skip them unless bit 1 of IY+$71 is set.
  $E459,3 HL': the screen address; B': page $D8.
  $E45C,6 A row. The pixels left of x in its first byte are marked in page $D8, to be left as they are.
  $E462,6 B: the image's bytes in a row; L: the bits spilt from the byte before, none yet.
  $E468,12 Rotate the next image byte right by x's pixel (the JR lands on the right RRCA).
  $E474,3 A: this byte's image bits, and those spilt from the byte before.
  $E477,17 Page $D9: the image where it is clear, the clean copy (the screen address with bit 7 set) where it is set.
  $E488,13 Where pages $D9 and $DA both have a bit set, page $DB's bit (skipped unless bit 1 of IY+$71 is set).
  $E495,12 Page $D8: the screen's own bit where it is set, the new one elsewhere.
  $E4A1,2 Next screen byte, next page index.
  $E4A3,8 Keep the bits that spill into the next byte; next image byte.
  $E4AB,3 The row's last screen byte, which only the spilt bits reach (skipped when x is on a byte boundary).
  $E4AE,16 Page $D9, as above.
  $E4BE,13 Pages $DA and $DB, as above.
  $E4CB,15 Page $D8, and the bits right of the image's end (D) left as they are too.
  $E4DA,7 Next row: the page index past the row's last byte; one row fewer to do.
  $E4E1,22 The screen address of the row below; stop at the bottom of the screen.

@ $E4F7 label=ISO_MOVE
c $E4F7 Move an object to a new position, and its sprite on the screen with it
D $E4F7 Krumlinde's RTN_Iso_Project. The new position is compared with the record's (+6 to +8), field by field, and the sprite's place on the screen (+0, +1) moved by the difference, projected: a step along +6 moves it one pixel right and half a row up, a step along +8 one pixel left and half a row up, and a step up in +7 (the height) one row up. So, give or take a constant, x is +6 less +8 and y is (+6 plus +8) / 2 plus +7, and the far corner of a room is at the top of the screen.
D $E4F7 Half rows are rounded towards zero, and C remembers whether +6's half was rounded: when both +6 and +8 move an odd amount the same way, the two halves make a whole row between them. An odd move along one axis alone would lose its half row, but the knight moves two at a step (measured, walking each way in the simulator: x by 2 and y by 1 a step).
D $E4F7 Called when an object is made for a room (#R$EB4C, after setting its record to 50, its height plus 50, 50, the position its template's screen place is drawn for) and when things move (#R$F309, #R$F65C, #R$F7C4).
R $E4F7 IX The object's record
R $E4F7 B The new +6
R $E4F7 D The new +7 (the height of its top)
R $E4F7 H The new +8
  $E4F7,9 Keep H, the new +8; HL: the sprite's place on the screen, x and y.
  $E500,6 How far +6 moves (not at all: on to the height).
  $E506,11 Further: half of it, rounded down; bit 0 of C set if it was odd.
  $E511,10 Back: half of it, rounded towards zero; bit 1 of C set if it was odd.
  $E51B,8 y up by the half, x right by the whole; the new +6.
  $E523,9 y up by the change in the height; the new +7.
  $E52C,6 How far +8 moves.
  $E532,13 Further: half of it, and a row more if +6 moved an odd amount the same way.
  $E53F,13 Back: the same, the other way.
  $E54C,5 y up by the half, x left by the whole.
  $E551,10 The new +8, and the sprite's new place.

@ $E55B label=DRAW_CURRENT_ROOM
c $E55B Draw the room the knight is in
D $E55B Called by #R$FD20 for every room entered, and by #R$F065 for the title (room 79, put in IY+$34 for the purpose), for GAME OVER (room 1) and at the end of the quest (room 81). The flag that says the room's objects have been placed (bit 0 of IY+$3C) is cleared, so that its $E4 $04 or $E4 $05 places them once however many parts it draws; the room is found by walking the table at #R$68B0 from room 1, each record's first word its length; the drawing variables are set from #R$E582; and the room is drawn from its colour byte on (#R$E597).
D $E55B Stage 1 called it DRAW_ROOM_NUMBER, which reads as if it drew a number.
  $E55B,4 Let the room place its objects again (#R$E89B, room code $E4 $04 or $05).
  $E55F,17 Find the room's record: room n is the nth, each skipped by its length.
  $E570,5 IX: the room's colour byte, after the length.
  $E575,11 The drawing variables' starting values, into IY+$5F to IY+$72.
  $E580,2 Draw it.

@ $E582 label=ROOM_DEFAULTS
b $E582 What the drawing variables start as in each room
D $E582 Twenty bytes, copied to IY+$5F to IY+$72 by #R$E55B before a room is drawn. The byte after them is not copied, and nothing reads it.
B $E582,10,5 Into IY+$5F to IY+$68: the origin for the objects placed (0, 0, 0); a word other code uses (0); the point and the second point (50, 50 and 50, 50); $38 for the attributes, which #R$E597 replaces with 0 before anything reads it
B $E58C,10,5 Into IY+$69 to IY+$72: 0; lines to the screen, not the fill's map (IY+$6A: 0); the mode, the repeat count and the repeat's address (0); two bytes the object code uses (0); and $80 in IY+$72, which the code that moves things reads
B $E596,1,1 Not copied

@ $E597 label=DRAW_ROOM_RECORD
c $E597 Draw a room from its record
D $E597 The screen is cleared (#R$E5BA) with black ink on black paper, so the drawing cannot be seen until #R$F0FB colours it; the record's first byte is kept as the room's colour (IY+$0E); and its commands are carried out one at a time by #R$E5E8, until the $E5 that ends them. The format is laid out command by command in each room's entry (room 1's is #R$68B0).
D $E597 The loop (RUN_ROOM_COMMANDS, after the colour byte) is also how a part is drawn: room codes $E0 and $E1 (#R$E89B) find the part in the table at #R$758C and run its commands through it, recursively. A part has no colour byte.
R $E597 IX The room's record, at its colour byte
  $E597,7 The attributes' byte 0, and the screen cleared.
  $E59E,8 The room's colour.
@ $E5A6 label=RUN_ROOM_COMMANDS
  $E5A6,6 The next command; $E5 ends the room, or the part.
  $E5AC,6 Carry it out, with D the mode byte (IY+$6B).
  $E5B2,4 IY back at the variables after every command, though none of them moves it.
  $E5B6,4 On past the command's last byte.

@ $E5BA label=CLEAR_ROOM_SCREEN
@ $E5BA isub=LD HL,$5B00
c $E5BA Clear the screen
D $E5BA Krumlinde's RTN_Clear_Room_Screen. The attributes are filled with the byte at IY+$68 (always 0: #R$E597 sets it just before) and the pixels with zeros, by pushing: SP is pointed at the end of each area in turn, the value pushed eight bytes at a time, and SP put back. The second area is filled by falling into the loop the first was filled by with a CALL.
  $E5BA,14 The attributes: 96 turns, down from their end.
  $E5C8,6 Then the pixels, below them: 768 turns of zeros.
  $E5CE,5 Keep SP; SP at the top of the area.
  $E5D3,9 Eight bytes a turn.
  $E5DC,12 HL: where the fill stopped, the top of the next area; SP back.

@ $E5E8 label=DO_ROOM_COMMAND
@ $E605 label=PATCH_RECORDS
c $E5E8 Carry out one room command
D $E5E8 One command of a room's (or a part's) drawing, at IX; on return IX is at its last byte, and the loop (#R$E597) steps past it. The commands are laid out in the rooms' entries; this is what they do. The point is x, y at IY+$64, IY+$65 and the second point at IY+$66, IY+$67; y counts up from the bottom of the screen, and rows go modulo 192.
D $E5E8 Points, $00-$BF: the byte is a row, the next a column, and the point moves there. With mode bit 4 the two are added to the point instead; bit 6 mirrors the column (255 less it, or negated when it is added); bit 3 moves the second point by as much as the point; bit 5 draws a line from the second point to the new point (#R$E89B); and bit 2 then makes the new point the second point too, so that the next line starts where this one ended.
D $E5E8 $C0, a row and a column: the second point, set, or with bit 4 moved, as a point is. $CF: the second point to the point. $D0: the two swapped. $D6: the end of a repeat started by $D5 (#R$E89B): IY+$6C counted down, and back to just after the $D5 while it has not run out. $E6-$FF: a flood fill with a texture from the point (#R$E734; the textures are 32 bytes each from #R$E0A4 -- not all of them patterns). Everything else goes on to #R$E89B: lines, the mode bits, the repeat's start, parts, the clean copy, and $E4 and its sub-commands.
D $E5E8 In object mode (mode bit 7, which $E4 $04 sets for the rest of the room), a code below $E4 is an object: its type and four bytes, made into an object record at the next free one (IY+$38) by #R$EB1A; $E4 does nothing; and $E6 up are patches (PATCH_RECORDS), which set the room's floor, ceiling and walls (#R$BC18) from the table of patches (at offset 778 of #R$B734).
R $E5E8 A The command
R $E5E8 D The mode byte (IY+$6B)
R $E5E8 IX The command's address
  $E5E8,4 Object mode?
  $E5EC,5 Yes: $E4 does nothing; $E6 up are patches.
  $E5F1,12 An object: HL at its type, IX at the next free record, and the record made.
  $E5FD,8 IX at the object's last byte.
  $E605,18 PATCH_RECORDS: IX at record 1 (the floor); HL at patch n (the code less $E5), six bytes each from the table's base.
  $E617,29 Its six bytes into the floor's and the ceiling's +7, the walls' +6 (records 3 and 4) and the other walls' +8 (records 5 and 6).
  $E637,4 A point ($00-$BF)?
  $E63B,10 BC: the point as it was; H: the row; A: the column.
  $E645,13 Mode bit 6 mirrors the column: 255 less it, or negated when it is added (bit 4).
  $E652,5 Added to the point (mode bit 4)?
  $E657,15 Yes: the column to x, and the row to y, modulo 192 (a sum that carries, or reaches 192, has 64 added).
  $E666,2 No: the point is the row and column.
  $E668,30 Mode bit 3: the second point moves as far as the point does (its row modulo 192).
  $E686,12 The new point (its row modulo 192 again, which cannot matter: never ran).
  $E692,5 Mode bit 5: a line from the second point to it.
  $E697,12 Mode bit 2: the second point follows.
  $E6A3,11 $CF: the second point to the point.
  $E6AE,10 $C0: a second point, a row and a column.
  $E6B8,20 Set: the row, then the column, mirrored with mode bit 6 (never in any room: the CPL never ran).
  $E6CC,33 Or added to it (mode bit 4): the row modulo 192, the column negated with bit 6.
  $E6ED,13 $D6: the end of a repeat. Count down; not run out, back to the $D5's count byte.
  $E6FA,19 $D0: the points swapped.
  $E70D,5 The rest below $E6 go on to #R$E89B.
  $E712,20 A fill: the texture's address, 32 bytes each from #R$E0A4, kept at IY+$78.
  $E726,9 Nothing to fill if the point is set in the fill's map already.
  $E72F,5 Push the end marker (its high byte $FE), and fill from the point.

@ $E734 label=FILL_NEXT_SEED
c $E734 Fill the next run of a flood fill
D $E734 The textured flood fill of room codes $E6-$FF (#R$E5E8), with the machine stack as its list of places still to fill. A place is x, y in C, B (y up from the bottom), and the list ends at a word whose high byte is $FE, pushed before the first. The fill's map is the 6 KB 32 KB above the screen, laid out like it: the pixels set there bound the fill (room code $E4 $00 clears it and sends the lines there, and $E2 copies the screen there), and the fill sets there every pixel it fills. For each place taken off the list: if it is off the top or the bottom of the screen, or already set in the map, it is dropped; otherwise the fill goes right to the last clear pixel of its run, and from there fills leftwards a pixel at a time (#R$E7B2), writing the texture's pixels to the screen, setting them in the map, and pushing a place in the row above or below each time a clear run begins there.
D $E734 This part sets up a run: the map addresses of its pixel and of the pixels above and below it (IY+$7B, IY+$7D, IY+$76), and the texture's two bytes for the row (B' the one for this byte, C' the other). A texture is 16 pixels by 16 rows, in four 8 by 8 cells: bytes 0-7 and 8-15 the left and right cells for the character rows in which y has bit 3 set, bytes 16-23 and 24-31 for the others; each cell's bytes run from the top of its character row. So the pattern lines up with the screen's character cells, and with the colours, whatever the area's shape.
  $E734,9 The next place; the end marker ends the fill; a place off the screen (y 192 or more, or below 0) is dropped.
@ $E73D label=FILL_SEED
  $E73D,6 FILL_SEED, where #R$E5E8 starts: dropped if its pixel is set in the map (HL the byte, D the bit).
  $E743,14 Go right to a set pixel, or to the screen's right edge (x back round to 0).
  $E751,8 Back one pixel, the run's last clear one; E: no run open above or below yet.
  $E759,7 Keep its map address; HL: its screen address.
  $E760,18 The map address of the pixel above (y plus 1): the screen address a line up, worked out afresh across the top of a character row.
  $E772,18 And of the pixel below.
  $E784,3 x, y into BC'.
  $E787,18 HL': the texture's byte for this row of the left cell: the second half unless bit 3 of y is set, and the row within the character row, from the top.
  $E799,14 C' the left cell's byte, B' the right's; swapped when bit 3 of x is clear, so that B' is this byte's.
  $E7A7,11 E': this byte's; HL': the screen address; and on to fill leftwards.

# --------------------------------------------------------------------------
# Fills, lines, parts, placing objects, the printer
# --------------------------------------------------------------------------

@ $E7B2 label=FILL_NEXT_PIXEL
c $E7B2 Paint one row of the textured fill, a pixel at a time, leftwards
D $E7B2 The inner loop of the flood fill that the room codes $E6-$FF start
. (#R$E5E8) and #R$E734 feeds with runs to fill. It walks leftwards along one
. row from the right-hand end of an unfilled run until it meets a pixel that
. is already set in the clean copy of the screen (#R$C000, the fill's map of
. what bounds it and what it has done) or the left edge of the screen. Each
. pixel is set in the clean copy, so that the fill never comes back to it, and
. set or cleared on the screen from the texture: the texture replaces whatever
. was drawn there.
D $E7B2 As it goes it watches the rows above and below. Where a clear pixel
. follows a set one there, a run opens, and its row and column are pushed on
. the machine stack for #R$E734 to fill later; bits 0 (above) and 1 (below) of
. E remember that a run is open, so that a long run is pushed once rather than
. at every pixel. A run in a row off the screen (above the top or below the
. bottom, where the pointers land in other memory) may be pushed too, and
. #R$E734 throws it away. When the mask in D moves into the next byte to the
. left, #R$E834 moves every pointer a byte left and #R$E806 may paint the
. whole byte at once.
D $E7B2 Krumlinde's name (Fill_NextPixel). The entry at FILL_THIS_PIXEL is
. where #R$E734 starts a run.
R $E7B2 B Row of the pixel just painted, counted from the bottom (0-191)
R $E7B2 C Its column
R $E7B2 D Its mask (bit 7 the left-hand pixel of the byte)
R $E7B2 E Bit 0: a run is open in the row above; bit 1: in the row below
R $E7B2 HL' The screen byte
R $E7B2 E' The texture's byte for this screen byte; B' and C' the texture's two bytes for the row
  $E7B2,5 the left edge of the screen ends the run: on to the next (#R$E734)
  $E7B7,6 one pixel left; into the next byte when the mask wraps round
@ $E7BD label=FILL_THIS_PIXEL
  $E7BD,8 already set in the clean copy: the run ends here
  $E7C5,3 set it there, so that the fill never comes back
  $E7C8,13 the screen's pixel: set where the texture has a 1, cleared where it has a 0
  $E7D5,9 the row above: is a run open there?
  $E7DE,10 no: a clear pixel above opens one; push its row and column
  $E7E8,5 yes: a set pixel above closes it
  $E7ED,8 the row below, the same way
  $E7F5,10 none open: a clear pixel below opens one
  $E7FF,7 one open: a set pixel closes it

@ $E806 label=FILL_WHOLE_BYTE
c $E806 Fill a whole byte at once when nothing in it needs looking at pixel by pixel
D $E806 Jumped to from #R$E834 when the fill has just moved into a new byte.
. The whole byte is painted in one go only when nothing in it could change the
. fill's course: all eight pixels are clear in the clean copy, and each
. neighbouring row is the same all along the byte -- all clear if a run is
. open there (the run just goes on), all set if none is (none can open). Then
. all eight are marked in the clean copy, the texture's byte is written to the
. screen whole, and the loop goes on from the byte's left-hand pixel; the
. return address into #R$E7B2 is dropped so as to go straight to its top,
. ready for the next byte. Otherwise it returns and the byte is done pixel by
. pixel. On a room's big plain areas this paints eight pixels for about the
. work of one.
R $E806 HL The byte below, in the clean copy
  $E806,9 the row below, with no run open: go on only if all eight are set
  $E80F,2 with a run open: only if all eight are clear
  $E811,14 the row above, the same way
  $E81F,6 this row: all eight must be clear
  $E825,2 mark all eight done
  $E827,3 the texture's byte onto the screen whole
  $E82A,6 the byte's left-hand pixel is the last one painted
  $E830,4 drop the return into #R$E7B2 and go on from its top

@ $E834 label=FILL_BYTE_TO_LEFT
c $E834 Move the fill's pointers a byte to the left
D $E834 Called from #R$E7B2 when the pixel mask wraps round into the byte to
. the left. The clean copy's pointers for this row and the row above (the low
. bytes at IY+$7B and IY+$7D) and for the row below, and the screen pointer,
. all go back a byte; and the texture's two bytes change places, since a
. texture is 16 pixels wide. Then #R$E806 sees whether the new byte can be
. filled whole. A row's bytes never cross into another row here, because
. #R$E7B2 stops at column 0.
  $E834,6 this row and the row above, in the clean copy
  $E83A,6 the screen; the texture's other byte for the new screen byte
  $E840,9 the row below; then try the byte whole

@ $E849 label=PIXEL_ADDRESS
c $E849 Find the screen byte of a pixel
D $E849 The screen address of the pixel at column C, row B, with the rows
. counted up from the bottom: row 191 is the top line of the screen. It is the
. arithmetic of the ROM's PIXEL-ADD, over 192 lines rather than BASIC's 176
. and without the ROM's check.
R $E849 B Row (0 the bottom line, 191 the top)
R $E849 C Column (0-255)
R $E849 O:HL The screen byte
  $E849,4 the line, counted down from the top of the screen
  $E84D,11 H: the third of the screen and the line within the character row
  $E858,12 L: the character row within the third, and the column over 8

@ $E864 label=BUFFER_PIXEL
c $E864 Find a pixel in the clean copy of the screen
D $E864 As #R$E86E, then moved to the same place in the clean copy of the
. screen (#R$C000), 32K above the screen. The fill uses the clean copy as its
. map.
R $E864 B Row, from the bottom
R $E864 C Column
R $E864 O:HL The byte in the clean copy
R $E864 O:A The pixel's mask, and D the same
  $E864,3 the screen byte and the mask
  $E867,7 the same byte in the clean copy

@ $E86E label=SCREEN_PIXEL
c $E86E Find a pixel's screen byte and its mask
R $E86E B Row, from the bottom
R $E86E C Column
R $E86E O:HL The screen byte
R $E86E O:A The pixel's mask (bit 7 the left-hand pixel); D is left 0
  $E86E,3 the screen byte
  $E871,12 $80, moved right by the column's low three bits

@ $E87D label=PLOT_LINE_START
c $E87D Plot the first pixel of a line
D $E87D Plots the pixel at column C, row B with the room drawing's pen, and
. leaves HL and D at it for #R$E89B to carry on the line from there. The pen
. draws on the screen, or in the clean copy (#R$C000) while a room has sent
. its lines there (code $E4 $00 puts $80 in IY+$6A, which is added to the
. screen address; $E4 $01 puts 0 back). By the mode bits (MODE) it sets the
. pixel (the usual), clears it (bit 0, codes $CB and $CC) or flips it (bit 1,
. codes $CD and $CE). A row above the top of the screen is not plotted -- a
. guard nothing reaches, since the points always wrap round into the screen
. (#R$E5E8).
R $E87D B Row, from the bottom
R $E87D C Column
R $E87D O:HL The byte plotted, on the screen or in the clean copy
R $E87D O:D The pixel's mask
  $E87D,4 above the top of the screen: nothing
  $E881,9 the screen byte and mask; IY+$6A moves it to the clean copy
  $E88A,14 flip it (bit 1); or set it, and clear it again if bit 0 is on
  $E898,3 write it back

@ $E89B label=MORE_ROOM_COMMANDS
c $E89B The room commands $C1-$E4: lines, mode bits, repeats, parts, the clean copy and $E4
D $E89B Where the command interpreter (#R$E5E8) sends every code below $E6
. that it has not dealt with itself -- it takes the points ($00-$BF), $C0,
. $CF, $D0 and $D6, and in object mode the objects. A cascade of comparisons;
. a code that none of them matches ($D1, $D3, $D4, $D7-$DF and $E3) does
. nothing and has no operand. The lengths of every code are laid out command
. by command in the rooms (#R$68B0) and parts (#R$758C).
D $E89B $D2 draws a line from the second point to the first, both ends
. included (DRAW_LINE; #R$E5E8 also calls it after each point while mode bit 5
. is on). It is Bresenham's: a step along the longer distance every pixel, and
. one along the shorter whenever the running error passes the longer. The
. first pixel goes through #R$E87D; the rest are plotted here with the same
. pen, stepping the screen address a line or a pixel at a time rather than
. working it out afresh.
D $E89B $C1-$CE set and clear the mode bits (MODE), which the interpreter
. reads before every command. Bit 0 ($CB on, $CC off): lines clear pixels. Bit
. 1 ($CD on, $CE off): lines flip pixels. Bit 2 ($C3, $C4): after each point
. the second point is moved to it, so that with bit 5 the points make a joined
. line. Bit 3 ($C5, $C6): the second point moves along with the first. Bit 4
. ($C1, $C2): points are relative -- their bytes are added to the point
. before, and those of $C0 and $E4 $05 to the second point and the origin. Bit
. 5 ($C7, $C8): a line from the second point to each new point. Bit 6 ($C9,
. $CA): the column bytes are negated or complemented, which mirrors the
. drawing left to right. Bit 7 is object mode, which $E4 $04 turns on. How the
. points use bits 2 to 6 is #R$E5E8's.
D $E89B $D5 n repeats what follows, up to the $D6 that #R$E5E8 handles, n
. times: the count goes in REPEATS and the place to go back to in REPEAT_FROM,
. so there is one repeat at a time. $E0 n and $E1 n draw part n (#R$758C) in
. the middle of the room's commands and come back to them; $E1 keeps the
. drawing's state as it was -- both points, the origin, the mode and the
. repeat, which it saves and restores -- and $E0 lets the part change it.
. Either way object mode ends with the part. $E2 copies the screen into the
. clean copy: from then on, what has been drawn so far bounds the fills.
D $E89B $E4 has a second byte. $E4 $00 clears the clean copy and sends the
. lines into it, where they bound a fill without being seen; $E4 $01 sends
. them back to the screen. Room 2 uses the pair to lay a second texture over
. part of a wall that is already textured, inside an outline drawn only in the
. clean copy (measured: without them the fill finds its first point already
. set and does nothing); part 16 does the same. $E4 $04 turns object mode on,
. and $E4 $05 x y z sets the origin (ORIGIN, ORIGIN_Y, ORIGIN_Z) that is added
. to the place of each object a room's commands put down -- rooms 13 and 17
. draw one part's objects several times over, moving the origin each time.
. Both first place the object table's things in the room (#R$EACC), once in
. each drawing of a room, whichever comes first -- so the table's things are
. always placed with the origin at 0, and their places are the room's own. Any
. other second byte does nothing.
D $E89B Of these codes only $CE occurs in no room or part. Room 26 is the only
. one to turn flipping on, for its last line, which crosses a wall that is
. already textured; its drawing ends soon after, so nothing needs to turn it
. off (measured: with the line drawn in set pixels instead, 36 pixels of the
. room come out different).
  $E89B,5 not $D2: the other codes
@ $E8A0 label=DRAW_LINE
  $E8A0,7 the line starts at the second point
  $E8A7,15 rows: how far to the first point, and which way (D +1 down the screen, -1 up)
  $E8B6,1 B = the rows
  $E8B7,14 columns: E +1 to go left, -1 right
  $E8C5,1 C = the columns
  $E8C6,9 more rows than columns: every step moves a row, some a column too (the plain step has no column)
  $E8CF,7 more columns: every step moves a column (the plain step has no row); nothing more to do if the points are the same
  $E8D6,3 H = steps, the longer distance; the error starts at half of it
  $E8D9,6 add the shorter distance: past the longer?
  $E8DF,7 yes: take the longer off, and step both ways (the step pushed first)
  $E8E6,4 no: the plain step
  $E8EA,4 a row to move?
  $E8EE,22 down a line: into the next character row, and into the next third only if L carried
  $E904,18 up a line: the same, the other way
  $E916,4 a column to move?
  $E91A,11 left: the mask moves left, into the byte before when it wraps
  $E925,6 right
  $E92B,16 plot it with the pen, as #R$E87D does
  $E93B,4 the error back in A; the next step
  $E93F,2 drop the step saved at the start
@ $E941 label=ROOM_MODE_CODES
  $E941,8 $CB: bit 0 on
  $E949,8 $CD: bit 1 on
  $E951,6 $C3: bit 2 on
  $E957,8 set the bit in MODE
  $E95F,8 $C7: bit 5 on
  $E967,8 $C5: bit 3 on
  $E96F,8 $C1: bit 4 on
  $E977,8 $C9: bit 6 on
  $E97F,8 $CA: bit 6 off
  $E987,8 $C2: bit 4 off
  $E98F,8 $CE: bit 1 off (no room or part has it)
  $E997,8 $CC: bit 0 off
  $E99F,8 $C8: bit 5 off
  $E9A7,8 $C6: bit 3 off
  $E9AF,6 $C4: bit 2 off
  $E9B5,6 clear the bit (D is MODE, as the interpreter read it)
  $E9BB,4 $D5 n
  $E9BF,13 the count, and where to go back to: the count's own place, which the interpreter steps past
  $E9CC,4 $E1 n
  $E9D0,32 keep the points, the mode, the repeat, the origin and the bytes between
  $E9F0,3 draw the part
  $E9F3,38 and put them all back
  $EA19,4 $E0 n
@ $EA1D label=DRAW_PART
  $EA1D,11 the part's number; the parts from #R$758C, the first numbered 1
  $EA28,4 this one?
  $EA2C,17 yes: run its commands to its $E5, after its length; object mode ends with it
  $EA3D,9 no: past it by its length
  $EA46,4 $E2
  $EA4A,5 the screen...
  $EA4F,11 ...into the clean copy, its 6144 bytes of pixels
  $EA5A,3 $E4, or nothing
  $EA5D,9 the second byte
  $EA66,13 0: clear the clean copy (a zero at the end of the records area, #R$BCA4, copied along it) and send lines into it
  $EA73,9 1: lines onto the screen again
  $EA7C,8 4: object mode on
@ $EA84 label=PLACE_OBJECTS_ONCE
  $EA84,17 place the object table's things in the room, if this drawing has not yet
  $EA95,6 5: place them too
  $EA9B,48 then the origin's three bytes, each added to the origin as it is while mode bit 4 is on
  $EACB,1 done

@ $EACC label=PLACE_ROOM_OBJECTS
c $EACC Put the object table's things for this room into its records
D $EACC Walks the whole object table (#R$A924) and makes a record (#R$EB1A)
. for every entry whose room is ROOM, in the table's order, from FREE_RECORD
. on. First every record from there to the end of the area (#R$BCA4; the clean
. copy begins where it ends) is cleared.
D $EACC An entry is a room, a type and four more bytes for a type below $46 --
. the things, which can be moved and carried from room to room -- or nine for
. the rest (doors, walls and the like); $FF ends the table. A thing's record
. also gets its number in the table, counting from 1, at +19: the code that
. moves a thing to another room or into the knight's hands writes its new room
. into its entry by that number (#R$F4E6). The number is a byte, which is
. enough because the 163 things come first.
D $EACC Called once in each drawing of a room, by #R$E89B's $E4 $04 or $E4
. $05. The most records a room's drawing makes is 30 (room 71), besides the
. knight's and the five carried; the area has room for 43 (measured, in rooms
. 1-80).
@ $EADB isub=LD HL,$C000
  $EACC,26 clear the records from the next free one to the end of the area
  $EAE6,7 from the start of the table, numbering the entries
  $EAED,5 the entry's room; $FF ends the table
  $EAF2,8 count it; this room?
  $EAFA,14 no: past it, six bytes or eleven by its type
  $EB08,3 yes: make its record
  $EB0B,15 a thing: its number in the table at +19

@ $EB1A label=PLACE_OBJECT
c $EB1A Make an object record from a type, a place and its template
D $EB1A Makes the record at IX for an object whose type is at HL, from the
. type's template and the bytes that follow the type, and counts it in
. OBJECT_COUNT. It serves both the object table (#R$EACC) and the objects a
. room's own commands put down in object mode (#R$E5E8), which are written the
. same way as the table's things without the room.
D $EB1A A type below $46 has an 11-byte template (#R$B734) and four bytes
. after it: +12 (the thing's kind, and whether it can be picked up), then its
. place, +6 to +8 (along the floor, the height of its top, across the floor).
. The template gives +0 to +5 (where its sprite goes on the screen, the
. sprite's size and the sprite), +9 to +11 (its length along, its height and
. its length across, each from the corner at +6 to +8) and two more bytes: +14, whose low nibble is the kind of
. movement the object dispatcher (#R$F1E0) acts on, and +16 (bits 0-4: 0 for
. an object that stays put, which the object dispatcher passes over, else 16
. plus its weight, #R$F52A; bit 5 set while it is carried or gone).
D $EB1A A type from $46 has a 9-byte template (LARGE_TEMPLATES, less $46) and
. nine bytes after it: the place, then six bytes for +13 to +18, which the
. door code reads (#R$F7C4). Its +12 is 1, the kind that the object dispatcher
. passes over. A room's commands only ever put down types below $46 -- they
. take five bytes each (#R$E5E8), which would not do for these.
D $EB1A The template's screen position is right for an object standing at 50,
. 50 with its floor at 50, so the record is first given that place (the top is
. 50 plus the height) and #R$E4F7 moves it from there to the place asked for
. plus the origin, moving the screen position with it. Then a thing's movement
. gets its starting state by kind: +15 is 1, and +13 and +17 are set for kinds
. 3 and 4-10 (and for kind 2, which no template has, so that code never runs).
R $EB1A HL The type, followed by its bytes
R $EB1A IX The record to fill (FREE_RECORD)
R $EB1A O:HL The byte after them
R $EB1A O:IX The next record, which FREE_RECORD is left at
  $EB1A,4 the type, kept for #R$EACC
  $EB1E,16 a type from $46: +12 is 1, and bit 6 of IY+$7D says so below
  $EB2E,4 past the type; one more record in use
  $EB32,10 the templates for types below $46, 11 bytes each...
  $EB3C,16 ...or from $46, 9 bytes each

@ $EB4C label=PLACE_FROM_TEMPLATE
c $EB4C Fill an object record from its template (#R$EB1A continued)
D $EB4C The rest of #R$EB1A, from the loop that finds the template on: the
. template's pointer is in the other register set (HL') and the bytes after
. the type in this one, and the record is filled from each in turn.
  $EB4C,4 the template for the type
  $EB50,5 template: +0 to +5, where the sprite goes, its size and the sprite
  $EB55,12 a small type: its first byte to +12
  $EB61,5 its place, +6 to +8
  $EB66,6 template: +9 to +11, the lengths along, up and across from the corner
  $EB6C,17 a large type: six more bytes, to +13 to +18
  $EB7D,9 a small type: the template's last two bytes to +14 and +16
  $EB86,23 the place asked for, plus the origin
  $EB9D,19 from the place the template's screen position is for, move it there (#R$E4F7)
  $EBB0,7 a large type: done
  $EBB7,4 +15: a countdown the object code uses
  $EBBB,9 the kind of movement: 2 (no template has it)
  $EBC4,4 its +13
  $EBC8,8 kind 3: +13
  $EBD0,16 kinds 4-10: +13 and +17
  $EBE0,10 the next free record

@ $EBEA label=COPY_TO_RECORD
c $EBEA Copy bytes into an object record
R $EBEA B How many
R $EBEA HL From
R $EBEA IX To
R $EBEA O:HL,IX Past them
  $EBEA,9 a byte at a time

@ $EBF4 label=BYTE_BEFORE_PRINT_CHAR
s $EBF4 A spare byte
D $EBF4 Zero; nothing reads it.

@ $EBF5 label=PRINT_CHAR
c $EBF5 Print one character
D $EBF5 Prints the character in A at the printing position (PRINT_X, PRINT_Y),
. by putting it into the one-character string after its own call to the
. printer (#R$EBFE). LIFE's digits are printed this way (#R$FE47).
R $EBF5 A The character (0 a space, 1-26 the letters, 27-36 the digits)
  $EBF5,3 into the string
  $EBF8,3 print it
  $EBFD,1 past the string, done

@ $EBFE label=PRINT
c $EBFE Print the string after the call
D $EBFE The game's text printer, the author's PRINT (the name the leftover
. source text calls it by). The string is the bytes after the CALL: characters
. of the font (#R$BAD8), $C8 and two bytes to move the printing position
. (PRINT_X, in pixels from the left, and PRINT_Y, in rows counted up from the
. bottom), and $A4 to end it; the printer returns to the byte after the $A4. A
. string can be only a $C8 and its position, to set it for #R$EBF5.
D $EBFE Each character is an 8 by 8 picture put on the screen by the
. compositor (#R$E3E4, at its second entry point, 15 bytes in), 8 pixels to
. the right of the one before. With its first two planes (BUFFER_D800 and
. BUFFER_D900) cleared and nothing else to merge, the compositor puts the
. character over the 8 by 8 pixels under it and leaves its neighbours alone,
. so text need not sit on the character grid. The printer uses the room
. drawing's point variables for the place and size, which the drawing is
. finished with.
  $EBFE,12 one byte wide; the first two planes cleared
  $EC0A,4 nothing else to merge
@ $EC0E label=PRINT_NEXT_CHAR
  $EC0E,7 the next byte of the string; $A4 ends it, returning past it
  $EC15,17 $C8: a new printing position
  $EC26,15 an 8 by 8 picture at the printing position
  $EC35,6 the character's 8 bytes in the font

@ $EC3B label=PRINT_FIND_GLYPH
c $EC3B Find a character in the font and print it (#R$EBFE continued)
D $EC3B The rest of the printer, from the loop that finds the character on.
  $EC3B,4 8 bytes a character
  $EC3F,3 draw it
  $EC42,10 8 pixels on; the next character

@ $EC4C label=SHOW_THING_IN_USE
c $EC4C Show a carried thing in the panel's box
D $EC4C The author's INFOR (named by its calls in the leftover source text).
. Clears the panel's box and prints the number of the carried place in use
. (#R$EC75), then draws the sprite of the object whose record is at HL in the
. box, at x 20, row 40: only the sprite's image, with the compositor's first
. two planes cleared, over what the box holds. Called when a thing is picked
. up (#R$F52A) and when a carried place that holds one is chosen (#R$FE47).
R $EC4C HL The thing's record
  $EC4C,4 clear the box and number it
  $EC50,8 the first two planes cleared
  $EC58,11 its sprite's width, height and address, +2 to +5
  $EC63,12 the width in bytes
  $EC6F,6 draw it in the box (placed by #R$EC75)

@ $EC75 label=CLEAR_THING_BOX
c $EC75 Clear the panel's box for the thing in use, and number it
D $EC75 The author's INFO0 (named by its calls in the leftover source text).
. The panel shows the thing in use in a box 24 pixels wide and 32 high at x
. 20, row 40 down, and the number of its carried place (1-5) above it at x 10,
. y 50. The box is put back as the clean copy of the screen (#R$C000) has it:
. the compositor (#R$E3E4) is given its second plane all set, which takes
. every pixel from the clean copy, so whatever sprite it finds does not
. matter. Then the digit is printed, from SELECTED. Called on its own when a
. thing is dropped (#R$F309) or an empty place is chosen (#R$FE47), and by
. #R$EC4C.
  $EC75,11 the second plane all set: every pixel from the clean copy
  $EC80,8 the first plane clear
  $EC88,12 the box: x 20, row 40, 24 by 32
  $EC94,3 not used: #R$E3E4 loads HL itself
  $EC97,9 nothing else to merge; 4 bytes wide
  $ECA0,3 put the box back
  $ECA3,11 the place in use ($9F-$A7 in twos) as a digit 1-5, into the string
  $ECAE print it (the string follows the CALL, laid out by the data generator)
  $ECB6,7 the box's corner again, for #R$EC4C

@ $ECBD label=REDRAW_OBJECT
c $ECBD Redraw an object, and every other object that overlaps it
D $ECBD The author's SRP (named by its call in the leftover source text's
. pick-up code). Draws the object whose record is at HL where it now stands --
. or rubs it out, if it has been carried off or is gone (bit 5 of +16) --
. together with every other object whose sprite overlaps it on the screen,
. each in front of or behind it as their places say, and puts the result on
. the screen. The record's first twelve bytes are copied to the variables from
. IY+$64 on (the room drawing's points, which it is finished with), and the
. box to redraw is the sprite's, with three rows more at the top and three at
. the bottom.
D $ECBD The work is done in the compositor's planes. The first (BUFFER_D800)
. is cleared; then either the object's sprite is drawn into them (#R$EE8D,
. with $80) or the second (BUFFER_D900) is filled, which lets the clean copy
. of the room show through where it was. Then every record from the knight's
. (the seventh) to the last in use, but this one, goes to #R$ED47, which lists
. at BUFFER_DA00 those that overlap the box (IY+$7F counts them, less one) and
. compares each one's depth with the corner of this object's box (#R$F036). If
. any of them needs drawing, #R$EDC6 sorts them and draws them into the
. planes, and at the end #R$E3E4 puts the box onto the screen.
D $ECBD Used when a thing is picked up (#R$F52A, to rub it out), as objects
. move (#R$F65C, #R$F959), and when a room is entered (#R$FE15 draws each
. object that stays put into the picture before it becomes the clean copy; bit
. 4 of IY+$17 is set then, and nothing is rubbed out).
R $ECBD HL The object's record
  $ECBD,11 the record's first twelve bytes to IY+$64 on; IX the record
  $ECC8,7 no sprite: nothing to draw
  $ECCF,6 the first plane cleared
  $ECD5,8 none listed yet
  $ECDD,12 the width in bytes
  $ECE9,12 carried or gone, and the room not being entered?
  $ECF5,13 then the clean copy shows through: the second plane all set
  $ED02,5 else its sprite into the planes
  $ED07,3 the corner of its box that depths are compared with
  $ED0A,16 three rows more above and below
  $ED1A,10 from the knight's record, the seventh; nothing to merge yet
  $ED24,10 each record but this one: does it overlap?
  $ED2E,7 the next record, keeping DE
  $ED35,8 up to the last in use
  $ED3D,7 sort and draw those that must be
  $ED44,3 onto the screen

# Constants that equal a variable's address: -1, not RIDE_DIRECTION (range 5).
@ $EC7A keep
@ $ECF8 keep

# --------------------------------------------------------------------------
# Culling, sorting and drawing sprites, input, the dispatcher
# --------------------------------------------------------------------------

@ $ED47 label=CULL_OBJECT
c $ED47 Sort one object into the redraw of a region: in front, behind, or out of it
D $ED47 Called by #R$ECBD for each object record but the one being redrawn
. (THIS_RECORD), with IX at the record and D, E, C the redrawn object's far
. corner and floor (#R$F036). The region is the rectangle of screen being
. rebuilt, the redrawn object's own box with three rows more above and below it:
. its x at IY+$64, its top row at IY+$65 (y counts up the screen), its width in
. pixels at IY+$66 and its height at IY+$67. An object that does not overlap the
. region, or has no sprite, is left out. One that overlaps it and stands in
. front of the redrawn object (#R$EE73) has its cover drawn at once into page
. $D8 (#R$EE8D, mode 0), which tells the compositor (#R$E3E4) to leave the
. screen as it is there. One behind goes onto the list at page $DA for #R$EDC6
. to sort and draw. Krumlinde's name for it is Cull_TestObject.
D $ED47 What counts depends on the pass. Normally (bit 4 of IY+$17 clear)
. scenery -- an object whose +$10 has bits 0-4 clear, drawn once as the room was
. entered and so already in the clean copy of the screen (#R$C000) -- goes on
. the list but does not by itself ask for the list to be drawn: only a live
. object behind sets bit 1 of IY+$71. In the scenery pass as a room is entered
. (bit 4 set, #R$FD20) live objects are left out altogether, since they are
. drawn later, and anything behind asks for the list. A door (type 1 in +$0C)
. skips both tests; anything taken out of the room (bit 5 of +$10: carried, or
. destroyed) is never drawn.
R $ED47 IX An object record
R $ED47 D The redrawn object's far edge along +6
R $ED47 E Its floor
R $ED47 C Its far edge along +8
  $ED47,9 A door skips the flag tests
  $ED50,12 In the scenery pass, leave out live objects
  $ED5C,5 Leave out anything taken out of the room
  $ED61,19 Across: out if the object lies wholly right or wholly left of the region
  $ED74,19 Down: y is the top row and the sprite hangs +3 rows below it; out if wholly below or above
  $ED87,7 No sprite, nothing to draw
  $ED8E,11 In front of the redrawn object: its cover into page $D8, and done
  $ED99,14 Behind it: its number onto the list at page $DA; IY+$7F, which #R$ECBD sets to $FF, holds the last entry's index
  $EDA7,12 Scenery behind does not need the list drawn, except in the scenery pass
  $EDB3,5 The list has something to draw

@ $EDB8 label=RECORD_FROM_NUMBER
c $EDB8 Point IX at an object record by its number
D $EDB8 Records are numbered from 1, the first of the six fixed ones (#R$BC18);
. the knight's is 7 (#R$BC90). Twenty bytes each. Used by the sorting in #R$EDC6
. (Krumlinde's RTN_ObjectPtr_From_Index).
R $EDB8 B The record's number
R $EDB8 O:IX The record
  $EDB8,9 From the first record, twenty bytes a step; the jump into the loop makes one step fewer than B

@ $EDC1 label=RECORD_FROM_NUMBER_STEP
c $EDC1 The stepping loop of #R$EDB8
D $EDC1 A routine of its own only because #R$EDB8 jumps into the middle of it:
. IX moves on a record for each number past the first.

@ $EDC6 label=SORT_AND_DRAW_BEHIND
c $EDC6 Put the objects behind in drawing order, and draw them into pages $DA and $DB
D $EDC6 Called by #R$ECBD when the list that #R$ED47 built at page $DA has
. something to draw (bit 1 of IY+$71). The list holds record numbers; IY+$7F the
. index of the last. Krumlinde's name for it is RTN_Sort_And_Draw_Sprites.
D $EDC6 First the list is sorted. For each place in turn, the entries after it
. are tested against the one there with #R$EE73; if one of them stands in front
. of it, the entry is taken out, the rest close up, it goes on the end, and
. whatever now fills its place is tested in turn. The list is drawn from the end
. back, so each object is drawn before anything in front of it. An isometric
. scene has no single depth to sort by, and three objects can each stand in
. front of the next; the fifty moves allowed at each place (IY+$7E) are what
. stop such a ring from sorting forever.
D $EDC6 Then the list is copied up to IY+$46, since the pages it lies in are
. about to be cleared -- thirty bytes whatever its length, over the printer's
. position and the room origin, which are wanted only while printing or drawing
. a room -- and drawn: each object's cover is ORed into page $DA and cleared out
. of page $DB (mode 4), and its image ORed into page $DB (mode 8). So page $DA
. ends up with where the objects behind cover the region, and page $DB with what
. they show, nearer over farther. In an ordinary pass the entries at the back of
. the list that are scenery or doors are skipped, because the clean copy the
. compositor starts from already shows them; from the first live object on
. everything is drawn, scenery included, since it has to cover that object. In
. the scenery pass everything is drawn.
  $EDC6,12 One entry: nothing to sort. IY+$74 counts the places still to settle
  $EDD2,4 At most fifty moves at this place
  $EDD6,7 The record at this place, and its far corner
  $EDDD,25 Test each entry after it; none in front: the place is settled
  $EDF6,11 One is in front: take this entry out and close up the list...
  $EE01,6 ...and put it on the end
  $EE07,8 Test what now fills the place, unless the moves are used up
  $EE0F,7 The next place
  $EE16,11 Keep the list up at IY+$46, out of the pages about to be cleared
  $EE21,12 Clear pages $DA and $DB (512 bytes), and start at the last entry (IY+$7E)
  $EE2D,10 An ordinary pass: nothing is drawn until the first live object
  $EE37,12 The record at this index
  $EE43,26 Until then, skip scenery and doors; draw from the first live object on
  $EE5D,10 Its cover into page $DA, its image into page $DB
  $EE67,12 On to the first entry

@ $EE73 label=IS_IN_FRONT
c $EE73 Is this object in front of the other?
D $EE73 Sets bit 0 of IY+$71 if the object at IX stands in front of the other
. object whose far corner and floor are in D, E and C (#R$F036): if it does not
. lie wholly beyond the other on any axis. That is: its +6 is less than the
. other's far edge along +6, its top (+7) is above the other's floor, and its +8
. is less than the other's far edge along +8. Greater +6 and +8 are farther from
. the viewer, and something wholly below another's floor is under it, so drawn
. behind it. Asked only of objects that overlap on the screen, one answer is
. enough to order them. Krumlinde's name for it is RTN_ComparePosition.
R $EE73 IX The object
R $EE73 D The other's far edge along +6
R $EE73 E The other's floor
R $EE73 C The other's far edge along +8
R $EE73 O:F Carry and zero are left from the last comparison made
  $EE73,10 Not in front if its +6 is at or beyond the other's far edge
  $EE7D,5 Or its top is at or below the other's floor
  $EE82,6 Or its +8 is at or beyond the other's far edge
  $EE88,5 In front

@ $EE8D label=DRAW_SPRITE
c $EE8D Draw an object's sprite into one of the region's buffers
D $EE8D The one routine that draws objects, and it never touches the screen: it
. draws the object at IX into a buffer the shape of the region being rebuilt --
. a row one byte wider than the region's width in bytes (IY+$73), as many rows
. as the region is high, wrapping within its 256-byte page -- clipped to the
. region and shifted to the pixel. The compositor (#R$E3E4) then makes the
. screen's bytes from the buffers. Krumlinde's name for it is RTN_Draw_Sprite.
D $EE8D The mode in A says what is drawn where. Mode $80, for the object being
. redrawn (#R$ECBD): its mask, into page $D9, with three rows of $FF (nothing
. covered) above and below it. Mode 0, for an object in front of it (#R$ED47):
. its cover -- the mask inverted, a bit set where the object shows -- ORed into
. page $D8. Modes 4 and 8, for the objects behind (#R$EDC6): the cover ORed into
. page $DA and cleared out of page $DB, and then the image ORed into page $DB. A
. sprite is its image and then its mask, each width/8 bytes by height rows (+2
. and +3), so every mode but 8 starts one plane in.
D $EE8D The setting up works out, in turn: which rows to draw -- skipping the
. sprite's rows above the region, or the buffer's rows above the sprite -- into
. IY+$75; the shift, x mod 8, written into the JR in #R$EF6C that jumps into its
. run of RRCAs, and the masks for the two parts of a shifted byte written into
. the three ANDs there; and which columns: a sprite starting left of the region
. is handled by #R$EF53, one starting inside it by moving the buffer pointer
. along (#R$EF4E). Then #R$EF6C draws.
D $EE8D The bits of C, besides the mode's: bit 4, the sprite starts left of the
. region; bit 5, the first column only primes the spill and is not written; bit
. 6, no spill column after the last, because the sprite is on a byte boundary or
. is cut by the region's right edge.
R $EE8D A The mode: $80, 0, 4 or 8
R $EE8D IX The object's record
  $EE8D,16 The sprite's width in bytes, kept at IY+$78
  $EE9D,6 One plane's size: width times height
  $EEA3,14 The sprite; every mode but 8 draws the second plane, the mask
  $EEB1,1 DE: where to read from
  $EEB2,8 Does the sprite start above the region's top row?
  $EEBA,11 No: skip the buffer's rows above it (a count of 0 goes round 256 times and comes back to no rows)
  $EEC5,21 And draw down to the region's bottom, or the sprite's height if that is less
  $EEDA,15 Yes: skip the sprite's rows above the region
  $EEE9,14 And draw from the buffer's top down to the sprite's bottom
  $EEF7,3 The rows to draw
  $EEFA,9 7 minus (x mod 8) into the JR's displacement: that many of the seven RRCAs are jumped over
  $EF03,6 On a byte boundary: nothing spills into a next column
  $EF09,7 A mask of the low 8 minus (x mod 8) bits: the part of a shifted byte that stays in its column
  $EF10,10 Into the two ANDs that keep it, and its complement into the one that keeps the spill
  $EF1A,18 Columns from the region's left byte to the sprite's; bit 4 if the sprite starts left of it
  $EF2C,11 In bytes; starting left: #R$EF53
  $EF37,16 Starting inside: draw what fits before the region's right edge and its spare column, the spill cut off...
  $EF47,7 ...or the whole width and the spill column after it

@ $EF4E label=DRAW_SPRITE_SKIP_COLUMNS
c $EF4E Part of #R$EE8D: move the buffer pointer to the sprite's first column
D $EF4E A routine of its own only because #R$EE8D jumps into the middle of it. B
. is one more than the columns to pass over.

@ $EF53 label=DRAW_SPRITE_CLIP_LEFT
c $EF53 Part of #R$EE8D: a sprite that starts left of the region
D $EF53 A holds how many of the sprite's bytes lie left of the region's first.
. The columns drawn are the rest of the sprite, or, if it also runs past the
. region's right edge, the region's width and its spare column (bit 6 then: no
. spill beyond). The last byte left of the region is still read, and one more
. column drawn for it, because its shifted spill is the first visible column's
. left part; bit 5, set as the drawing starts, keeps it from being written
. itself.
R $EF53 A The bytes cut off at the left
  $EF53,18 The sprite runs past the right edge too: the region's width and its spare column
  $EF65,4 Or the rest of the sprite
  $EF69,3 On to skip the bytes cut off

@ $EF6C label=DRAW_SPRITE_ROWS
c $EF6C Part of #R$EE8D: skip the bytes cut off at the left, then draw the rows
D $EF6C The drawing. The sprite pointer stays in HL, and the buffer pointer and
. the mode move to the alternate set, so the loop holds both without touching
. memory. Each sprite byte is inverted if the mode is $80 (the mask, inverted,
. is cover, so the zero bits the shift brings in mean nothing covered; it is
. inverted back as it is stored), rotated right by x mod 8 through the patched
. JR, and split: the part that stays in this column, with the last column's
. spill ORed in, is written; the part that spills is kept in E for the next.
. Mode $80 stores the byte as it is; modes 0 and 8 OR it in; mode 4 ORs it into
. page $DA and first clears the same bits from page $DB.
D $EF6C The three ANDs and the JR's displacement here are rewritten by #R$EE8D
. before every sprite; the operands the listing shows are the tape's.
  $EF6C,4 Skip the bytes cut off (one fewer: the last of them primes the spill), and count that column
  $EF70,3 The columns to draw
  $EF73,11 The buffer pointer and the mode to the alternate set; the rows; page $D9 to start with
  $EF7E,4 Mode $80?
  $EF82,18 Yes: three rows of $FF, nothing covered, at the top of page $D9...
  $EF94,20 ...and three below the sprite's rows...
  $EFA8,6 ...and the sprite from the fourth row
  $EFAE,13 The other modes: page $D8, page $DA for mode 4, page $DB for mode 8
  $EFBB,14 Each row: E carries the spill from column to column; the first column only primes it if the sprite starts left of the region
  $EFC9,7 Each column: a sprite byte; mode $80 inverts the mask into cover
  $EFD0,2 Patched: jumps over 7 minus (x mod 8) of the RRCAs
  $EFD2,7 Rotate right by x mod 8
  $EFD9,4 Mode 8, the image
  $EFDD,4 Mode $80?
  $EFE1,8 Yes: this column's part (the AND is patched) with the last one's spill, back into a mask
  $EFE9,1 Modes 0 and 4: the mask becomes cover
  $EFEA,9 The whole byte kept for the spill; only that, the first time round when the first column is not written
  $EFF3,4 This column's part (the AND is patched), with the last one's spill
  $EFF7,11 Mode 4: clear this cover out of the image in page $DB
  $F002,4 OR it into the buffer (or, for mode $80, store it); the next column
  $F006,6 The spill for the next column (the AND is patched)
  $F00C,7 The sprite's next row
  $F014,4 A spill column after the last?
  $F018,18 Write the spill into it the same way
  $F02A,9 The buffer's next row: one byte wider than the region
  $F033,3 Done

@ $F036 label=FAR_CORNER
c $F036 Find an object's far corner and floor
D $F036 D is +6 plus +9 and C is +8 plus +11, the far edges along the two floor
. axes; E is +7, the top, less +10, the height: the floor it stands on. #R$EE73
. tests other objects against them. Krumlinde's name for it is
. RTN_ComputeSortKey.
R $F036 IX The object's record
R $F036 O:D The far edge along +6
R $F036 O:E The floor
R $F036 O:C The far edge along +8

@ $F04C label=CLEAR_256_BELOW
c $F04C Clear the 256 bytes below HL
D $F04C Used with HL at the top of page $D8 to clear it (#R$ECBD).
R $F04C HL The byte after the last to clear

@ $F050 label=CLEAR_512_BELOW
@ $F052 label=CLEAR_BELOW
@ $F055 label=FILL_BELOW
c $F050 Clear the 512 bytes below HL
D $F050 And the two entries every fill of the buffers uses: CLEAR_BELOW, at
. offset 2, clears B times 8 bytes below HL, and FILL_BELOW, at offset 5, fills
. them with DE. The stack pointer is put at HL and DE pushed four times a turn,
. the fastest way a Z80 has to fill memory; SP is kept at IY+$76 while it is
. borrowed. No interrupt can push into the area meanwhile: the game runs with
. interrupts off (the DI at offset 11 of #R$C47C). Krumlinde's names for these
. are RTN_ClearBuffer_512, FastFill_Zero and RTN_FastFill.
R $F050 HL The byte after the last to fill
R $F050 B The number of 8-byte units, at CLEAR_BELOW and FILL_BELOW
R $F050 DE The word to fill with, at FILL_BELOW
  $F050,2 64 units: 512 bytes
  $F052,3 CLEAR_BELOW: fill with zero
  $F055,5 FILL_BELOW: the stack pointer borrowed
  $F05A,6 Eight bytes a turn, going down
  $F060,5 And given back

@ $F065 label=TITLE_SCREEN
@ $F089 label=NEW_GAME
@ $F09B label=TELE
c $F065 The title, a game, GAME OVER, and round again
D $F065 Reached from the start-up (#R$C47C) and never left. The title is room 79
. drawn (#R$E55B), coloured (#R$F0FB), with the title page printed over it
. (#R$B686) and, in Release 2, 9-JOY beside the controls; then it waits for a
. key. ROOM is kept round the drawing, though the copy from the master a moment
. later sets it anyway.
D $F065 A key starts a game (NEW_GAME, at offset 36). The master copies made at
. start-up (#R$639C) go back: the object table's first 1200 bytes, and the 61
. bytes of variables from IY on. TELE, the author's name for offset 54, puts the
. knight's record back as a game starts it and enters the room ROOM names
. (#R$FD20). That call returns only when the game is over: LIFE gone, the
. quest's last room reached, or 0 pressed with SYMBOL SHIFT (#R$FE47). Then
. #R$F906 puts the room's things back into the object table, and room 1 is drawn
. as the backdrop for GAME OVER, which waits for the keys to be let go and one
. pressed (#R$F0D2) before the title comes round again.
D $F065 TELE is also where the thing that carries the knight off (type 9,
. #R$FE47) goes, with ROOM set to 30, so he arrives as a new game starts him.
. The knight's +$0E is kept through the copy: its bits 5 and 6 say which way his
. sprites face, and they are turned round in place (#R$F117), so the record must
. go on agreeing with them.
D $F065 In Release 1 the routine begins by setting IY, turning interrupts off
. and making the start-up's copies, which Release 2 moved into #R$C47C, and
. there is no 9-JOY. The name the author gave this routine is lost but for its
. last letter, G (#R$DD39). Krumlinde's name for it is RTN_Title_Screen_Loop.
  $F065,15 The title: room 79, with ROOM kept round it
  $F074,3 Coloured
  $F077,3 The title page's text
  $F07A,3 And Release 2's note that 9 turns the joystick on
  $F086,3 Wait for a key (PAUS)
  $F089,11 NEW_GAME: the object table's master copy back
  $F094,7 And the variables' (HL runs on from the one to the other)
  $F09B,17 TELE: the knight's record from the master, but for his +$0E
  $F0AC,3 Play: back here when the game is over
  $F0AF,3 The room's things back into the object table, and the creatures' sprites turned back
  $F0B2,7 Room 1 as GAME OVER's backdrop
  $F0B9,3 GAME OVER
  $F0C9,3 Coloured
  $F0CC,6 Wait for the keys to be let go and one pressed; the title again

@ $F0D2 label=WAIT
@ $F0D8 label=PAUS
c $F0D2 Wait for no key, then for a key
D $F0D2 The author's WAIT; PAUS, at offset 6, is the second half alone, a wait
. for a key. Both read all eight half-rows at once (A=0 selects them all), so
. any key will do. WAIT is used after GAME OVER (#R$F065), at the end of the
. quest (#R$FD20) and for the pause, SPACE with SYMBOL SHIFT (#R$FE47); PAUS
. under the title.
  $F0D2,6 Until no key is held
  $F0D8,7 PAUS: until one is

@ $F0DF label=INPUT
c $F0DF Read a row of keys
D $F0DF The author's INPUT. A selects the half-rows the way the high byte of IN
. A,($FE)'s address does, a 0 bit for each one read; what comes back has a bit
. set for each key held.
R $F0DF A The half-rows to read
R $F0DF O:A Bits 0-4, one for each key held
R $F0DF O:F Z if none is
  $F0DF,7 Keys pull their bits low: turn them round

@ $F0E6 label=IN31
c $F0E6 Read the Kempston joystick, if it is in use
D $F0E6 The author's IN31: 31 ($1F) is the Kempston interface's port. Nothing is
. read unless bit 3 of OPTIONS is set, which 9 turns on and off (#R$FE47): on a
. Spectrum without the interface the port gives whatever the bus holds, which
. would read as the stick being moved. The port is read three times and the
. reads ORed together; why three is not known. Each XOR A puts 0 in the high
. half of the port's address.
D $F0E6 Release 1's routine is XOR A and RET before the same reads: its joystick
. is switched off, and Release 2's switch and the 9-JOY on the title are the
. change (see the notes' versions.md).
R $F0E6 O:A Bits 0-4: right, left, down, up, fire (0 if not in use)
R $F0E6 O:F Z if nothing
  $F0E6,6 Not in use: nothing
  $F0EC,12 Three reads, ORed
  $F0F8,3 The five bits

@ $F0FB label=ATTRI
c $F0FB Colour the whole screen in the room's colour
D $F0FB The author's ATTRI: all 768 attribute bytes set to ROOM_COLOUR. A room
. is drawn unseen, its attributes cleared (#R$E55B), and coloured only when it
. is complete: under the title and GAME OVER (#R$F065), at the end of the quest
. (#R$FD20), and after the first pass of a new room, when every object has been
. drawn (#R$FE47).

@ $F10B label=RESTOR
@ $F10E isub=LD DE,$C000
c $F10B Copy the screen to the clean copy at #R$C000
D $F10B The author's RESTOR. The 6144 bytes of the screen's bitmap go to
. #R$C000, where the loading tune was. Entering a room (#R$FD20) does it twice:
. once when the room is drawn, as the background the scenery is drawn over, and
. once when the scenery is done. The compositor (#R$E3E4) takes the background
. from this copy wherever it rebuilds the screen round a moving object, which is
. what the name is about: it is what restores the picture an object uncovers.

@ $F117 label=MIMAN
c $F117 Turn the knight's sprites to face his way
D $F117 The author's MIMAN, mirror man: MIRROR (#R$F127) for the knight, whose
. sprites begin at #R$9110: 28 planes, the image and mask of all fourteen of his
. frames. Called from his walking (#R$F595).
R $F117 C His direction bits
R $F117 E His +$0E
R $F117 IX His record
  $F117,8 The first sprite; 28 planes, counted in the alternate C

@ $F11F label=MIWRAI
c $F11F Turn the sprites of the state-11 creature to face its way
D $F11F The author's MIWRAI, which reads as "mirror wraith": MIRROR (#R$F127)
. for the two frames at #R$5E88, 4 planes, the sprites of objects in state 11
. (#R$F309), and in #R$F906 to turn them back as a room is left.
R $F11F C Its direction bits
R $F11F E Its +$0E
R $F11F IX Its record
  $F11F,8 The first sprite; 4 planes

@ $F127 label=MITRO
@ $F12D label=MIRROR
@ $F13A label=MW1
@ $F143 label=MW2
c $F127 Turn the sprites of the state-7 creature to face its way
D $F127 The author's MITRO, which reads as "mirror troll": the six frames at
. #R$8BB8, 12 planes, the sprites of objects in state 7 (#R$F309), and turned
. back as a room is left (#R$F906).
D $F127 Then MIRROR, at offset 6, the part the three share. The direction bits
. in C become two facing bits in E: bit 6 says which of the two views the
. sprites show, bit 5 whether the view is mirrored. $08 (Y to P, or the stick
. right) is view 0 as drawn; $40 (Q to T, up) view 0 mirrored; $80 (A to G,
. down) view 1 as drawn; $04 (H to ENTER, left) view 1 mirrored. E goes to
. IY+$72, the copy of +$0E that #R$F1E0 writes back, and if bit 5 of the
. record's +$0E says the sprites face the other way they are mirrored in place
. (#R$F157). With no direction bit ($CC) nothing changes.
D $F127 The sprites are shared by every creature of a kind, so a record's bit 5
. is only true if one creature of the kind is about: no room has two in state 7
. or two in state 11 (measured over every room). Leaving a room turns them back
. (#R$F906), so the next room's creature, whose record comes fresh from its
. template with bit 5 clear, agrees with them; the knight's +$0E is kept through
. a new game for the same reason (TELE, #R$F065). Krumlinde's names are
. Sub_F117, Sub_F11F and Sub_F127.
R $F127 C The direction bits
R $F127 E The record's +$0E
R $F127 IX The record
R $F127 O:E The new facing in bits 5 and 6, also at IY+$72
  $F127,6 The first sprite; 12 planes
  $F12D,5 MIRROR: no direction, nothing to do
  $F132,8 Bit 5, mirrored: set for $40 and $04
  $F13A,9 MW1: bit 6, view 1: set for $80 and $04
  $F143,3 MW2: the new facing for the record
  $F146,10 The width in bytes (the carry is clear from the AND)
  $F150,3 Mirror them if they face the other way

@ $F157 label=MW
@ $F160 label=MW0
@ $F164 label=MIR0
@ $F167 label=MIR1
@ $F169 label=MIR2
@ $F18D label=MIR3
c $F157 Mirror a run of sprite planes in place, if they face the other way
D $F157 The author's MW. Nothing is done if bit 5 of the record's +$0E, the way
. the sprites face now, already matches bit 5 of E. Otherwise every row of every
. plane is turned end for end: each byte's bits reversed into E and pushed, and
. then popped back over the row, which reverses the bytes' order too.
R $F157 E The new facing
R $F157 C The width in bytes
R $F157 HL The first plane
R $F157 IX The record
R $F157 C' The number of planes
  $F157,12 Already that way round: nothing to do
  $F163,4 MIR0: each plane, its height in rows (in the alternate B)
  $F167,2 MIR1: each row, its width in bytes
  $F169,29 MIR2: each byte's bits reversed, and pushed
  $F186,7 Back to the row's start
  $F18D,5 MIR3: the bytes written back, last first
  $F192,7 The next row; the next plane

@ $F199 label=FACING
@ $F1AC label=FA0
c $F199 Turn facing bits back into a direction, and find the view's sprite
D $F199 The author's FACING, the other way from MIRROR (#R$F127): bits 6 and 5
. of E give C one of $08 or $40 (view 0) or $04 or $80 (view 1), and for view 0
. HL moves on by the word at IY+$62, from the first view's sprite to the
. other's. Picking up (#R$F4F4) and fighting (#R$F595) use it to take the pose
. for the way the knight faces.
R $F199 E The facing, in bits 5 and 6
R $F199 HL The pose's sprite in view 1
R $F199 O:C The direction bit
R $F199 O:HL The pose's sprite in the view he faces
  $F199,4 View 1?
  $F19D,7 View 0: its sprite is further on
  $F1A4,8 $08, or $40 when mirrored
  $F1AC,8 FA0: $80, or $04 when mirrored

@ $F1B4 label=DECLI1
@ $F1B6 label=DECLIF
c $F1B4 Take ten from LIFE
D $F1B4 The author's DECLI1; DECLIF, at offset 2, takes what A holds. LIFE is
. two decimal digits (LIFE_TENS and LIFE_UNITS), and it stops at 00, which ends
. the game (#R$FE47). Bit 0 of IY+$17 asks for it to be printed again. Ten or
. one goes when something is met (#R$F959), three when the creature in state 4
. strikes (#R$F1E0), and, when the knight lands from a long fall, what it lasted
. beyond 20 steps (#R$F309). The alternate registers do the work, so the
. caller's are kept.
R $F1B4 A How much LIFE to take, at DECLIF
  $F1B4,2 Ten
  $F1B6,18 DECLIF: LIFE to be printed again; take A from its digits

@ $F1C8 label=DE1
@ $F1D7 label=DE2
c $F1C8 Take a number from LIFE's two digits
D $F1C8 The author's DE1. A is split into tens (counted in B) and units; the
. units are taken from H, borrowing from the tens, and the tens from L. If that
. goes below nothing LIFE is 00.
R $F1C8 A The number, below 100
R $F1C8 B $FF
R $F1C8 L The tens
R $F1C8 H The units
R $F1C8 O:HL The new tens and units
  $F1C8,8 Tens into B, units into C
  $F1D0,7 The units, borrowing a ten if need be
  $F1D7,5 DE2: the tens
  $F1DC,4 Below nothing: 00

@ $F1E0 label=CHE3D
@ $F21D label=I0
@ $F22C label=I00
@ $F245 label=I01
@ $F24D label=I02
@ $F258 label=I3
@ $F267 label=I30
@ $F272 label=I31
@ $F275 label=I4
@ $F29F label=I5
@ $F2B5 label=I50
@ $F2BE label=I9
@ $F2EB label=I95
@ $F2EE label=I92
@ $F2F2 label=I91
c $F1E0 Update one object: the start of the dispatch on its state
D $F1E0 The author's CHE3D (Krumlinde's Sub_F1E0). The main loop (#R$FE47) calls
. it once a pass for every record from the knight's on, and the movement code
. comes back to it at once for an object whose carried-along movement has just
. stopped (#R$F65C). Nothing is done for an object without a sprite, a door
. (type 1 in +$0C, dealt with where it is met, #R$F7C4), anything taken out of
. the room (bit 5 of +$10) or scenery (bits 0-4 of +$10 clear). The labels
. inside are the author's own.
D $F1E0 Otherwise the record's first 19 bytes are copied to IY+$64 on and its
. address kept at IY+$7D; its state byte, +$0E, is also kept at IY+$67, for the
. movement code to see bit 7 of it as it was when the pass began. In the first
. pass after a room is entered (bit 2 of IY+$17) the object is only drawn where
. it stands (NOG, #R$F65C). An object carried along by a movement already under
. way (bit 7 of +$0E) carries on in the direction kept in +$12 (NOPROP).
. Otherwise the low four bits of +$0E, its state, say what it does. The states
. dealt with here:
D $F1E0 State 0, at rest: it falls if it can -- the movement code adds the fall
. -- except that with bit 4 of +$0E, which is cleared as it is read, it makes
. its last movement (+$0D) once more instead: a thing just dropped (#R$F309) or
. knocked (#R$F959). The pass also notes two kinds of thing as it meets them:
. the first thing of type 8 (+$0C) is kept at IY+$0F with bit 0 of IY+$11 set,
. and the creatures in state 9 go for it rather than for the knight (ZOOMIN,
. #R$FC48), and destroy it when they reach it (#R$FA83); a thing of kind 11 sets
. bit 1 of IY+$11, which wakes the creature in state 15 (#R$F309). Both are
. forgotten when a room is entered, a thing is picked up, or the kind-8 thing is
. destroyed.
D $F1E0 State 3 bounces about: it keeps moving along its last movement, $45 (a
. diagonal) when it has none, and the movement code turns it round when it is
. blocked. State 4 strikes at the knight when he is in its reach -- its own box
. moved 12 towards lower +6, towards the viewer -- taking three from LIFE each
. pass and showing its striking frames (#R$5D14); otherwise it is left alone.
. State 5 is the knight in a jump (#R$F595 starts one): eight passes going up in
. the direction he was walking, without the fall, then back to state 8 to come
. down. State 9 is a creature that rises out of the floor: after a wait it grows
. through four frames (#R$A4B8 to #R$A2E4) as +$11 counts up, and then walks
. after the knight like state 6. Every other state, the knight's 8 among them,
. goes on to #R$F309.
D $F1E0 Bit 7 of IY+$17 is set when the thing of type 5 is used (#R$FE47), and
. lasts until a room is entered. While it is set every state but the knight's 8
. and his jump's 5 is dealt with as state 0: the creatures stand where they are
. and only fall. Release 1 excepts only state 8 -- at offset 131 it has JR I00
. where Release 2 has CP 5 and JR NZ -- and there a knight who jumps while the
. freeze lasts stays in state 5 for good, since nothing counts his jump down: he
. never walks again. Played in the simulator in both releases (the type-5 thing
. in room 24 picked up and used, then SPACE, then Q): Release 1's knight stayed
. in state 5 and did not move; Release 2's landed after eight passes and walked.
E $F1E0 Continued at #R$F309.
R $F1E0 HL The object's record
  $F1E0,10 No sprite: nothing to do
  $F1EA,8 A door: dealt with where it is met
  $F1F2,9 Taken out of the room, or scenery
  $F1FB,11 The record's first 19 bytes to IY+$64 on, its address to IY+$7D
  $F206,6 The state byte as the pass found it, over the height's copy
  $F20C,7 The first pass in a new room: only draw it
  $F213,10 Carried along: on in the direction in +$12
  $F21D,15 I0: C its last movement (+$0D), HL its sprite; bit 4 cleared in the copy of +$0E; state 0?
  $F22C,25 I00: the first kind-8 thing, kept while none is
  $F245,8 I01: a kind-11 thing. Once a kind-8 thing is known this compares the state instead of the kind, so a kind-11 thing met later goes unnoticed, and a frozen creature in state 11 counts as one
  $F24D,11 I02: with bit 4, its last movement once more; otherwise only bit 0 of it, and the movement code adds the fall
  $F258,15 I3: the freeze: the knight to his controls, his jump on, everything else as state 0
  $F267,11 I30: state 3: its last movement, or $45 if it has no direction
  $F272,3 I31: move (KON6)
  $F275,22 I4: state 4: is the knight in its box moved 12 along +6?
  $F28B,20 Never run in the build's sessions: three from LIFE, and its striking frames, 144 bytes each, without moving (ANIM)
  $F29F,22 I5: state 5, the jump: when +$0F has counted down, back to state 8, and only the fall
  $F2B5,9 I50: up (bit 4) without the fall (bit 1) along +$12, in the knight's poses (INP5, #R$F595)
  $F2BE,4 I9: other states go on
  $F2C2,7 State 9: risen already (bit 6 of +$11)?
  $F2C9,10 Rising: +$11 counts up; it stands still
  $F2D3,24 Its frame by the count: below $37, $3A, $3D and $40
  $F2EB,3 I95: into +4 and +5 (INPE)
  $F2EE,4 I92: risen: +$11 to $51
  $F2F2,5 I91: turn after the knight now and then (ZZ1), and walk with state 6's sprites (I600)

# --------------------------------------------------------------------------
# Object states, the knight's controls, carrying, doors
# --------------------------------------------------------------------------

# Fairlight: stage 2, range 4 ($F2F7-$F905) -- the objects' states and their
# updates, the knight's controls, picking up and dropping, weight, and doors.
# Author's names (notes/fairlight/symbols.md) are kept or expanded where they
# name a place; Krumlinde's (credited) where he had one.

@ $F2F7 label=STEER
c $F2F7 Keep a creature's course, or aim it at the knight when its count runs out
D $F2F7 The author's ZZ1. The creatures that chase -- the guards (#R$F309, and state 9 in #R$F1E0), the wraith and the troll -- each keep a countdown at +15 of their record and their course at +18. Every pass takes one off the count; when it reaches nought #R$FC48 aims the creature at the knight (or, for a state-9 guard, at a lure lying in the room), sets the count again (10 passes, or 3 when he is within 14 along y) and says how far away he is. So a creature changes its mind only every few passes.
R $F2F7 IX The creature's record (the pass's working copy of it is at IY+$64)
R $F2F7 E Its state (+14)
R $F2F7 O:C The direction to go in, with the low two bits cleared (the direction bits are described at #R$F595)
R $F2F7 O:D How far the knight is, along the floor axis on which he is further, if the course was set again this pass; nought if it was not
  $F2F7,3 The course it is on (+18, from the working copy)
  $F2FA,8 Count this pass off the record's +15; at nought, take a new course (and distance) from #R$FC48
  $F302,7 Only the way to go, not the low bits: in C, and kept at +18

@ $F309 label=CREATURE_UPDATE
c $F309 Update an object by its state: guards, the troll, the wraith, the floating things and the knight
D $F309 The author's I6: the rest of the dispatch that #R$F1E0 (CHE3D) begins, which tests the low nibble of the object's state (+14) in turn and comes here for state 6 and up. Each case chooses a direction in C and a sprite in HL, and leaves by one of three doors into the movement code: ANIM (in #R$F595), which picks a frame from a run of them, SET_SPRITE_AND_MOVE (#R$F65C), which shows HL as it is, or MOVE_IN_DIRECTION (#R$F65C), which leaves the sprite alone. From there the object is moved in direction C, collides, lands, and is redrawn.
D $F309 The states handled here, with the object types whose templates (#R$B734) start them in each:
. 6 and 10 (types 26 and 33): a guard. Within 30 of the knight along the floor it chases him (#R$F2F7); further off, a state-6 guard walks to and fro along x and a state-10 one along y, turning back at whatever stops it. Its frames depend on the way it walks: #R$9F3C, #R$A110, #R$A554 or #R$A728, three each. The guards of state 9 (type 27), which materialise first (#R$F1E0), use the same frames and always chase.
. 7 (type 13): the troll, which chases, turning its frames (#R$8BB8 facing the viewer, #R$8E64 facing away).
. 11 (type 45): a wraith, which chases and has one frame each way, #R$5E88 and #R$5F08.
. 12 (type 51): hangs in the air where it is and flickers through three small frames from #R$5B00.
. 13 (type 52): wanders, diagonally if it has no way of its own yet, and turns back off whatever it meets; frames from #R$5B30.
. 14 (type 40): hangs where it is and flickers through three frames from #R$6104.
. 15 (type 56, one in room 61): stands still until the thing of kind 11 lies in the room, when it takes the wraith's frames and state and chases the knight from then on (measured: it becomes state 11 for good). The door out of room 61 waits for the same thing (#R$F7C4).
. 8: the knight -- KNIGHT_UPDATE, below.
. Any other (1 or 2, which no object that is updated has): moves the way +13 says, with no sprite change.
D $F309 The knight (the author's I8, KNIGHT_UPDATE) comes here on every pass on which he is not in the air: in the air, #R$F1E0 carries him on in the direction +18 holds. First, if he has just landed from a long fall, it costs him LIFE: IY+$14 counts the passes he fell for, and each pass over 20 -- each two units over 40 -- takes a point (measured: a fall of 50 cost 5, of 60 cost 10, of 40 nothing). Then the keys. Any key but the number keys goes to the action keys: X to V pick up (#R$F4F4), CAPS SHIFT and Z drop, and the rest walk, jump and fight (#R$F595). With no key, the Kempston joystick (when 9 has turned it on) goes to #R$F595 too. With neither, he stands: facing the viewer or away, with now and then a fidget of 14 passes (bit 3 of IY+$17) after a random wait of 128 to 255.
D $F309 The drop (Krumlinde's MainLoop_DropItemCheck, at the CAPS SHIFT row test) takes the thing in the place in use and puts it down just beside him on the side he faces: past his own width or depth when he faces the way the axis grows, past the thing's own when he faces back. Its top is set level with his, so it starts in the air. If the thing's box there meets anything (#R$FCA5), BLOCKED (message 1, IY+$07) and nothing changes. Otherwise the place is emptied, the thing moved there, its weight -- its +16 less 16, and never below nought -- taken off CARRIED_WEIGHT (IY+$12), its carried flag cleared, and it is given one pass going up (state bit 4 with +13 = $12) after which it falls to the floor like anything else. The object table is told it is in this room now (#R$F4E6) and the panel's box for the place is emptied (#R$EC75). With 46 or more object records in use the drop key is ignored (not worked out why).
R $F309 A The state's low nibble
R $F309 E The whole state, +14
R $F309 C Its direction, +13 (#R$F595 has the bits)
R $F309 HL Its sprite, +4 and +5
R $F309 IX Its record; the working copy of its +0 to +18 is at IY+$64 to IY+$76
  $F309,8 States 6 and 10: a guard
@ $F311 label=GUARD_MOVES
  $F311,3 The author's I601. Keep course, or aim at the knight (D is how far he is, when it aimed)
  $F314,8 Not aimed this pass, or the knight within 30: go the way #R$F2F7 said
  $F31C,4 Far off: look again next pass
  $F320,10 A state-6 guard walks along x
  $F32A,11 State 10: keep its y direction (and the low bits); with none, go up y ($40) and turn back when stopped (bit 0)
  $F335,7 State 6 (the author's I602): keep its x direction; with none, go down x ($04) and turn back when stopped
@ $F33C label=GUARD_FRAMES
  $F33C,3 The author's I600, which the materialised guards of state 9 use too (#R$F1E0). Frames by the way it goes: down y, or standing, #R$9F3C
  $F33F,7 Up x: #R$A110 (the author's I60 is the next test)
  $F346,7 Down x: #R$A554 (I61 is the next)
  $F34D,7 Up y: #R$A728 (a later test wins over an earlier one)
  $F354,6 The author's I62: frames of 24 by 26, 156 bytes apart; step through them
  $F35A,4 The author's I11. State 11: a wraith
@ $F35E label=WRAITH_MOVES
  $F35E,3 The author's I1110 (state 15 comes here too). Keep course, or aim at the knight
  $F361,3 Turn its two frames (#R$5E88) to face the way it goes; HL is the first
  $F364,8 Facing away (bit 6 of the state clear): the second frame, 128 bytes on (#R$5F08)
  $F36C,3 Show that frame (no animation) and move
  $F36F,4 The author's I12. State 12: the small floating thing
  $F373,6 Frames of 8 by 8, 16 bytes apart, from #R$5B00
  $F379,2 No way to go, and bit 1: it does not fall
  $F37B,4 Make sure the run is at least three frames (the last frame, bits 3-5 of +17, at least 2)
  $F37F,3 Step through the frames
  $F382,4 State 13
  $F386,7 With no x or y direction of its own, go down x and up y ($45), turning back when stopped
  $F38D,8 Frames of 16 by 23 from #R$5B30
  $F395,4 State 14
  $F399,8 Frames of 16 by 10 from #R$6104, hanging still
  $F3A1,4 State 15
  $F3A5,8 Unless the thing of kind 11 lies in the room (bit 1 of IY+$11, set by #R$F1E0): stand quite still, not even falling. (This skips the clearing of C: C still holds +13, which is nought for this figure)
  $F3AD,4 Then be a wraith. The wraith's case writes the state it is given, so it stays one (measured, by putting the thing of kind 11 in room 61: the figure took the wraith's frame and state 11 and came for the knight)
  $F3B1,4 State 7: the troll
  $F3B5,4 Clear bit 4 of its +12, which makes a touch cost the knight 10 LIFE (#R$F959): the troll's object-table records have it set, so it lasts only until the troll's first pass (the working copy keeps it for that pass)
  $F3B9,3 Keep course, or aim at the knight
  $F3BC,3 Turn its frames (#R$8BB8) to face the way it goes
  $F3BF,8 Facing away: the frames that start 684 bytes on (#R$8E64)
  $F3C7,6 Frames of 24 by 38, 228 bytes apart
@ $F3CD label=KNIGHT_UPDATE
  $F3CD,5 The author's I8. Any state not handled above just moves the way +13 says
  $F3D2,8 State 8, the knight, on the ground. A fall of more than 20 passes (IY+$14, counted by #R$F65C) costs a LIFE point a pass over
  $F3DA,4 Start the count again
  $F3DE,2 Standing: no way to go (bit 0 alone)
  $F3E0,7 Any key but 1-5 and 6-0: the action and movement keys
  $F3E7,6 No key: the Kempston joystick, if it is on (#R$F0E6)
  $F3ED,3 Nothing pressed. C = the way he was going, which matters only if he stands on something that moves
  $F3F0,8 Back to the first frame of a run (+17's bits 0-2)
  $F3F8,5 Count down to a change of stance (+18)
  $F3FD,8 Start or end a fidget (bit 3 of IY+$17)
  $F405,8 A fidget lasts 14 passes...
  $F40D,7 ...and the stillness between them 128 to 255, at random
  $F414,4 His sword is not out
  $F418,4 Riding on something that moves (state bit 4): keep his sprite and go with it
  $F41C,19 Facing the viewer: #R$91CA, or #R$99C8 in a fidget
  $F42F,13 Facing away: #R$93F8, or #R$9A82 in a fidget
  $F43C,2 Stand still
  $F43E,3 Show the frame, and move (or not)
@ $F441 label=PICK_OR_DROP
  $F441,6 Krumlinde's MainLoop_DropItemCheck. A key is down, so no fidget
  $F447,6 Nothing on the CAPS SHIFT to V row: walk, jump or fight (#R$F595)
  $F44D,5 X, C or V: pick up (#R$F4F4)
@ $F452 label=DROP_THING
  $F452,8 CAPS SHIFT or Z: drop. Not with 46 records or more in use: then read the walking keys instead
  $F45A,13 The place in use (SELECTED, IY+$1E) is empty: nothing to drop; just redraw him
  $F467,8 Keep the place's address; IX = the thing; B, D, H = where he is
  $F46F,11 Which way he faces: bits 5 and 6 of his state
  $F47A,7 Up x (neither bit): put it past his width
  $F481,7 Down y (bit 6): its own depth short of him
  $F488,11 Down x (both bits): its own width short of him
  $F493,5 Up y (bit 5): past his depth
@ $F498 label=DROP_TEST
  $F498,14 Krumlinde's DropItem_TestPlacement. Would the thing's own box there meet anything? (It is still marked as carried, so it does not meet itself)
  $F4A6,5 Keep the place's address in the other register set
  $F4AB,8 Something is there: BLOCKED
@ $F4B3 label=DROP_COMMIT
  $F4B3,6 Krumlinde's DropItem_Commit. Empty the place
  $F4B9,3 Move the thing to the spot (its top level with his, so it starts in the air)
  $F4BC,11 Its weight: +16 less 16, and nought if that is below it
  $F4C7,7 Off what he carries (CARRIED_WEIGHT, IY+$12)
  $F4CE,4 No longer carried
  $F4D2,8 For one pass it goes where +13 says: up, and not falling (bits 4 and 1); then it falls
  $F4DA,6 The object table: it is in this room now
  $F4E0,3 Empty the panel's box for the place
@ $F4E3 label=KNIGHT_DONE
  $F4E3,3 The author's DOE: the way out of the knight's actions. Redraw him, and the pass is over for him

@ $F4E6 label=SET_THING_ROOM
c $F4E6 Write a thing's room into the object table
D $F4E6 The author's ROMM. A thing's number (+19 of its record, counted from 1, #R$EACC) is its place in the object table (#R$A924), and the first 163 records of that table are all six bytes long, so the number times six, from six bytes before the table, reaches the room byte of the thing's own record. Dropping writes the room it is dropped in; picking up and the things that vanish (#R$F959) write $FE, which no room is, so the thing is placed nowhere until it is dropped again. (A thing's place in the room is saved separately, by #R$F906, when the knight leaves.)
D $F4E6 Only the first 163 records of the table can be reached this way, and they are the things that can move between rooms. A record with no number (+19 nought) runs the loop 256 times and reaches 1536 bytes past the start, among the eleven-byte records -- and that happens: room 19's drawing places two things of its own (not from the object table, so with no number) that can be picked up, and picking one up writes $FE into the x of the object table's record 214, the door from room 25 to room 21. Measured: after that the door is at x 254 and room 25 cannot be left that way. (Dropping the thing would write 19 there instead.)
R $F4E6 IX The thing's record
R $F4E6 C The room, or $FE for none
  $F4E6,12 HL = six bytes before the object table, plus six for each step of the thing's number
  $F4F2,2 The room

@ $F4F4 label=PICK_UP
c $F4F4 Pick up whatever the knight is standing at
D $F4F4 X, C or V (#R$F309). Only into an empty place: if the place in use (1 to 5, SELECTED) holds something, nothing happens. Otherwise he stoops (#R$956C facing the viewer, #R$9626 facing away) and the game looks for things in a box the size of his own, four units on the way he faces (measured facing up x, with a thing 8 wide: it was found with its corner anywhere from 2 behind his to 10 ahead). #R$FCA5 finds the first record whose box meets it; #R$F52A goes on through the rest until one can be carried.
  $F4F4,10 The place in use already holds something: do nothing but redraw him
  $F4FE,9 The stooping frames: #R$956C, and 186 bytes on (#R$9626) facing away
  $F507,9 Choose by which way he faces; C = that way; it becomes his sprite
  $F510,3 B, D, H = where he is
  $F513,9 Move along x (bit 0), or along y (bit 2) if he faces along y
  $F51C,6 Two steps of two: four units on
  $F522,8 His sizes; what does a box there meet?

@ $F52A label=PICK_UP_LOOK_ON
c $F52A Look on for a thing that can be carried, and take it
D $F52A The pick-up's search, from where #R$FCA5 (or this, going round) left it. Each record whose box meets the search box is tested: it must be a thing that can be picked up (bit 5 of +12). A door ends the search (though no door has bit 5 set: a door's +12 is exactly 1). Then the weight: the thing's +16 less 16 (never below nought) is added to what he carries (CARRIED_WEIGHT, IY+$12), and if that comes to 8 or more it is TOO HEAVY (message 3) and nothing changes. So the load is at most 7; the heaviest things weigh 6.
D $F52A Taking it: the place in use gets the record's address, the record is marked as carried (bit 5 of +16) and not in the air, and the object table says it is in no room ($FE, #R$F4E6). The knight is redrawn stooping; then the thing's picture is wiped from the room, by redrawing its area (#R$ECBD) with THIS_RECORD pointing at it so that it is left out, and drawn in the panel's box for the place (#R$EC4C). Krumlinde names the part from the weight on RTN_Store_Carried_Weight.
D $F52A The flags in IY+$11 are cleared: they say whether the lure and the thing of kind 11 lie in the room, and whichever still does sets its flag again on the next pass (#R$F1E0).
  $F52A,3 Look on from the last record met
  $F52D,2 Nothing more: the pick-up ends with a redraw
  $F52F,6 Not a thing that can be carried: look on
  $F535,9 A door: stop
  $F53E,10 Its weight: +16 less 16, nought if below
  $F548,13 Added to his load, 8 or more is TOO HEAVY
@ $F555 label=TAKE_THING
  $F555,3 The author's WEI3. The new load
  $F558,11 The place in use holds the thing now
  $F563,8 Carried, and not in the air
  $F56B,4 The thing of kind 11 may not lie in the room any more
  $F56F,5 In no room
  $F574,5 Redraw the knight, stooping
  $F579,11 THIS_RECORD = IY+$78, meant as the thing's number among the records so that its own redraw leaves it out; but the knight's redraw has already used that byte for a sprite's width (3 when measured, the thing being 9), so a fixed record is left out instead
  $F584,4 Redraw where it was: without it
  $F588,4 Draw it in the panel's box
  $F58C,4 THIS_RECORD back to the knight's
  $F590,4 Both room flags cleared (see above)
  $F594,1 The knight's pass is over

@ $F595 label=KNIGHT_CONTROLS
c $F595 The knight's controls: walk, jump or fight, and the frames they show
D $F595 Reached from KNIGHT_UPDATE (#R$F309) when a key other than the action keys is down, or the joystick has moved. The way to go comes from the joystick if it is on and moved, otherwise from the keyboard. A later test wins, so there is no diagonal walking: on the keyboard Q-T beats A-G beats H-ENTER beats Y-P, and on the joystick up beats down beats left beats right.
D $F595 A direction is a byte with one bit for each way, the same for every object (+13, +18, IY+$71, IY+$7C):
. bit 0 -- turn back when stopped (#R$FA83 reverses the way rather than ending it);
. bit 1 -- rising: do not fall this pass;
. bit 2 -- down x; bit 3 -- up x (Y-P, joystick right);
. bit 4 -- up; bit 5 -- down (gravity);
. bit 6 -- up y (Q-T, joystick up); bit 7 -- down y.
. On the screen, going up x moves up and to the right, and going up y moves up and to the left. A step is two units along one axis, or one along each of x and y for a diagonal; up or down is always two.
D $F595 The author's I88, with the author's own labels from the source text left at #R$617C for most of its tests. INP5 then turns the knight to face the way he goes (#R$F117 mirrors all his frames, and sets bits 5 and 6 of his state: #R$F199 has which is which). Mid-jump (state 5, from #R$F1E0) he just walks on. Otherwise SPACE or SYMBOL SHIFT jumps: up for 8 passes of two units, going the way he walked, then down (measured: from 78 to 94 and back). His state becomes 5 for the rise, keeping the facing bits; #R$F1E0 counts the rise off and makes him 8 again, and he falls as anything does. B, N or M, or the joystick's fire, fights: the sword is out (bit 1 of IY+$17, which is what hurts a creature he meets, #R$F959) for three passes, standing, and then away for three while he steps forward, the two frames facing the viewer or away (#R$96E0 and #R$979A, #R$9854 and #R$990E). Otherwise he walks, through three frames of his walk (#R$9110 facing the viewer, #R$933E away).
D $F595 The author's ANIM, at the end, picks a frame from a run of them. +17 holds the frame (bits 0-2), the last frame of the run (bits 3-5) and bit 7 while going back. HL is the first frame and DE the size of one; the frame shown is HL + DE times the frame. The run goes forward to the last and then back, but it goes back by jumping to frame 1: measured, a run of three goes 0, 1, 2, 1, 0, 1, 2 ..., but one of four goes 0, 1, 2, 3, 1, 0 and one of two 0, 1, 1, 0. Every run the game uses is three frames. The rest of it is at #R$F65C.
R $F595 E The knight's state, +14
R $F595 C The way to go by default (1: standing)
R $F595 IX His record
  $F595,5 The author's I88. The joystick, if it is on; otherwise the keyboard
@ $F59A label=STICK_DIRECTION
  $F59A,5 The author's I89 (the source's I82 to I85 are the next four tests). Right: up x
  $F59F,5 Left: down x
  $F5A4,5 Down: down y
  $F5A9,5 Up: up y
  $F5AE,3 Fire: fight, at once
  $F5B1,2 Walk
@ $F5B3 label=WALK_KEYS
  $F5B3,9 The author's I80 (INP2 to INP4 are the next three tests). Y-P: up x
  $F5BC,9 H-ENTER: down x
  $F5C5,9 A-G: down y
  $F5CE,9 Q-T: up y
@ $F5D7 label=KNIGHT_TURN
  $F5D7,3 The author's INP5 (#R$F1E0 comes here mid-jump). Turn his frames to face the way he goes; HL = his walking frames facing the viewer (#R$9110)
  $F5DA,8 Facing away: the walk at #R$933E
  $F5E2,6 Mid-jump (state 5): just walk on through the air
  $F5E8,7 None of SPACE, SYMBOL SHIFT, M, N and B: walk
  $F5EF,4 SPACE or SYMBOL SHIFT: jump
@ $F5F3 label=KNIGHT_FIGHT
  $F5F3,12 The author's INP59. B, N or M, or fire: fight. The frames #R$96E0 facing the viewer, and 372 bytes on (#R$9854) facing away; C = the way he faces
  $F5FF,6 Is his sword out?
  $F605,5 Not yet: the step forward, until +15 runs out
  $F60A,10 Out with the sword, for three passes (this pass still steps)
  $F614,2 Sword out: stand
  $F616,5 For three passes
  $F61B,8 Then away with it, three passes more
  $F623,6 The stepping frame, one on from the other
@ $F629 label=KNIGHT_JUMP
  $F629,4 Jump: up, and not falling, as well as the way he walks
  $F62D,7 For 8 passes (+15), going this way (+18)
  $F634,10 State 5, rising, with his facing kept; show the first frame of the walk
  $F63E,7 Walk: frames 186 bytes apart; the sword is not out
@ $F645 label=ANIM
  $F645,1 The author's ANIM. Keep the way to go
  $F646,8 C = +17; B = the frame, plus one
  $F64E,4 Going forward: the next frame is this one plus one
  $F652,4 Going back: this one less one...
  $F656,6 ...and at nought, the frame before is 1, going forward again

@ $F65C label=ANIMATE_AND_MOVE
c $F65C Show the frame, then move the object and redraw it
D $F65C The rest of the author's ANIM (#R$F595), and then the common end of every object's update: INPE sets the sprite, KON6 takes the direction, NOPROP adds gravity, NOG makes the direction into the three axes of the step, and the step is tried against every other record (#R$FCA5). If something is in the way, #R$F7C4 deals with it: a door may take the knight to another room, anything else is met (#R$F959) and the step tried again axis by axis (#R$FA83), which comes back to TRY_STEP here. When the step is clear the record gets the new state and place (#R$E4F7), and the object is redrawn (#R$ECBD).
D $F65C Gravity: unless the direction has bit 1 (rising), the up bit is cleared (by the constant $EF in IY+$0B) and down added (from the constant in IY+$05), so everything falls two units a pass until it is stopped. A fall sets bit 7 of the state, in the air, and while that is set #R$F1E0 does not run the object's own case but keeps it going the way +18 says. A fall keeps only the down bit (and the low two), so everything falls straight down, the knight at the end of a jump too (measured). The air ends when the fall is stopped, or when the count in +15 runs out (it is 1 while falling, 3 for a bounce), and if it was in the air at the start of the pass and did not move at all, the object is updated again at once (#R$F1E0) as a thing on the ground. Bit 6 of IY+$7B, which #R$FA83 sets when the step was stopped by an object of kind 2 or 3, makes it bounce: three passes going up.
D $F65C The knight's screen position is worked out afresh on each pass: his record is first put back to one fixed point on the floor (50, 78, 50) and its place on the screen, and #R$E4F7 moves him from there. Everything else is moved from where it was.
D $F65C On the first pass in a room (bit 2 of IY+$17, which the room's entry sets and #R$FE47 clears) nothing moves: the direction is cleared, but all three axis bits are set, so the test runs on a box one unit up x, two down and one down y from where the object is, and whatever that meets is dealt with as usual (#R$F7C4); then the record is only drawn. What the offset box is for is not worked out.
R $F65C HL The first frame of the run
R $F65C DE The size of one frame
R $F65C B The frame, plus one
R $F65C A The next frame
R $F65C C The object's +17
  $F65C,3 HL = the frame to show
  $F65F,7 The last frame of the run
  $F666,10 Past it: go back, and next time show frame 1
  $F670,6 Otherwise the next frame
  $F676,1 The way to go
@ $F677 label=SET_SPRITE_AND_MOVE
  $F677,6 The author's INPE: the sprite is HL
@ $F67D label=MOVE_IN_DIRECTION
  $F67D,1 The author's KON6: the way to go is C
@ $F67E label=ADD_GRAVITY
  $F67E,4 The author's NOPROP. Rising (bit 1): no gravity this pass
  $F682,10 Otherwise no up (IY+$0B holds $EF), and down (IY+$05 holds $23; its low two bits are not used)
@ $F68C label=SKIP_GRAVITY
  $F68C,8 The author's NOG. C will be the axes of the step
  $F694,3 The first pass in a room: no way to go, but a test on all three axes
  $F697,6 The way to go this pass: IY+$71 (which #R$FA83 may change) and IY+$7C (which it does not)
  $F69D,7 Down or up x: an x step (bit 0 of IY+$7B)
  $F6A4,7 Up or down: a step in height (bit 1)
  $F6AB,7 Up or down y: a y step (bit 2)
  $F6B2,3 IY+$7B = the axes of the step
@ $F6B5 label=TRY_STEP
  $F6B5,4 #R$FA83 comes back here: no door met yet (bit 7 of IY+$7B)
  $F6B9,9 B, D, H = where it would be after the step
  $F6C2,7 Not moving: nothing to test
  $F6C9,9 With its sizes, does it meet anything? If so, see what (IX is what it met)
@ $F6D2 label=COMMIT_STEP
  $F6D2,10 The step is clear. The record gets the state from the working copy
  $F6DC,7 The first pass in a room: just draw it
  $F6E3,6 The knight?
  $F6E9,20 Put his record back to the fixed point, so that his screen place comes out afresh
  $F6FD,3 Move it: the new place, and the screen position from it
  $F700,6 E = the state; D = the way it went (after any change by #R$FA83)
  $F706,7 On the ground, that becomes its way (+13)
  $F70D,17 Riding on something that moves (state bit 4): take its way (IY+$7F), keeping the low bits
  $F71E,10 Moved in height, going down: falling
  $F728,9 In the air; keep going down (with the low bits)
  $F731,14 The knight counts the passes he falls for (IY+$14)
  $F73F,6 Stopped by an object of kind 2 or 3 (bit 6 of IY+$7B, from #R$FA83)
  $F745,10 Bounce: in the air, going up for three passes
  $F74F,4 On the ground: done
  $F753,5 In the air: count down, and at nought it is out of the air
  $F758,1 Keep going the way it went
  $F759,11 Mid-jump (state 5): the way asked for, before #R$FA83 changed it
  $F764,10 The knight in the air with no step in height has landed
  $F76E,9 Out of the air; carry on the way +13 says
  $F777,3 Its way while in the air
  $F77A,7 It moved: keep the new state
  $F781,6 It did not move, and was not in the air at the start of the pass: keep the state
  $F787,15 It was in the air and could not move at all: out of the air, and update it again at once
  $F796,4 The new state
  $F79A,4 Anything but a thing lying (state 0) is redrawn
  $F79E,6 A thing that is carried too
  $F7A4,6 A thing lying still needs no redraw
@ $F7AA label=REDRAW_THIS_OBJECT
  $F7AA,6 Redraw the object, in its new place

@ $F7B0 label=WORKING_POSITION
c $F7B0 Where the object being updated is
D $F7B0 The author's BUT. Reads the working copy that #R$F1E0 makes of the record (+6 to +8, at IY+$6A to IY+$6C).
R $F7B0 O:B Its place along x (+6)
R $F7B0 O:D Its top (+7), counting upwards
R $F7B0 O:H Its place along y (+8)

@ $F7BA label=WORKING_SIZES
c $F7BA How big the object being updated is
D $F7BA The author's BUT2. Its box runs from +6 to +6 plus the width along x, from +8 to +8 plus the depth along y, and from +7 less the height up to +7 -- a corner and three sizes, not a centre and half-sizes (the box test in #R$FCDC).
R $F7BA O:C Its width, along x (+9)
R $F7BA O:E Its height (+10)
R $F7BA O:L Its depth, along y (+11)

@ $F7C4 label=BUMPED
c $F7C4 Something is in the way: a door takes the knight through, anything else is met
D $F7C4 Reached when a step would make the object's box meet another record's (#R$FCA5), IX being the one it meets. Anything but a door (kind 1 in the low nibble of +12, the eleven-byte records of the object table) goes to #R$F959. A door stops anyone but the knight, like a wall. For him:
. The key. If the door's +14 holds a thing's number, the thing in the place in use must be that one, or it is LOCKED (message 2). With the place empty, IX becomes nought and the test reads byte 19 of the ROM, $FF, which is no thing's number, so it is LOCKED. Eight things open doors (numbers 1 to 8; 21 doors need one).
. The way. The door's +17 has the direction bits (#R$F595) of the way through it, and he must be going that way this pass: x or y for a doorway, up or down for a hole (twelve doors). Walking into a door any other way is stopped as by a wall. Going down happens by gravity alone, as he stands over the hole; going up needs a jump.
. Room 61. The only way out of room 61 also needs the thing of kind 11 to be lying in the room (bit 1 of IY+$11) -- measured: without it he stands on the hole; with it he drops to room 60.
. Where he arrives. For a doorway along y he must be wholly within the door's width; he arrives as far along x from the door's +15 as he was from the door's corner, at y = +18 (less his depth if he walked down y). For one along x, within its depth; as far along y from +18, at x = +15 (less his width if he walked down x). For a hole his x and y are carried across relative to the door (+15 and +18) and his top is set to +16 (plus his height going up; that case never ran in the build's sessions). Through a doorway his height must lie wholly within the door's, and carries across relative to +16.
. The room behind. Every thing among the first 163 records of the object table whose record puts it in the room he is going to is tested against where he would arrive, its box made from the table's position and its template's sizes; if one is there, it is BLOCKED (message 1) and he stays. A thing with bit 4 of its +12 -- in the table, only the trolls -- does not count (measured, by moving thing 1 into room 30 where the door from room 29 lands him: BLOCKED; with bit 4 set he went through).
D $F7C4 Then the room changes (Krumlinde's RTN_Trigger_Room_Change): the room number is the door's +13, the knight's record is moved to where he arrives, the things' places are saved (#R$F906), and the new room is entered (#R$FD20), which goes back to the main loop.
R $F7C4 IX The record in the way
R $F7C4 B The object's x after the step (D its top, H its y; C, E, L its sizes)
  $F7C4,10 Not a door: meet it
  $F7CE,4 A door was met this pass
  $F7D2,8 Only the knight goes through; for anything else it is a wall (#R$FA83)
  $F7DA,6 No key needed
  $F7E0,15 The thing in the place in use (nought, the ROM, if none)
  $F7EF,9 Is it the key?
  $F7F8,7 No: LOCKED, and it is a wall
@ $F7FF label=DOOR_WAY
  $F7FF,4 Krumlinde's RTN_Check_Door_Keys, though the key is already settled here. C = the way through the door
  $F803,6 Is he going that way? This is AND (IY+$7C): Krumlinde has a DB and a label at its second byte, and reads the rest as AND (HL) and LD A,H
  $F809,7 In room 61...
  $F810,7 ...only if the thing of kind 11 lies there
@ $F817 label=DOOR_ARRIVAL
  $F817,3 B, D, H = where he is (before the step)
  $F81A,6 L = the x he arrives at, E = the y (the door's +15 and +18)
  $F820,5 Is the way along y (neither x nor height)?
  $F825,17 Along y: he must be wholly within the door's width
  $F836,3 x: as far along from +15 as he was from the door's corner
  $F839,5 y: +18 when going up y...
  $F83E,7 ...or his depth less, going down y
  $F845,5 A hole (up or down)?
  $F84A,6 x: carried across relative to the door
  $F850,6 And y
  $F856,3 His top: the door's +16...
  $F859,4 ...when going down
  $F85D,5 Going up, plus his height (never ran in the build's sessions)
  $F862,17 Along x: he must be wholly within the door's depth
  $F873,1 (A wasted load: A is loaded again at once)
  $F874,3 y: as far along from +18 as he was from the door's corner
  $F877,2 x: +15 when going up x...
  $F879,8 ...or his width less, going down x
  $F881,7 Through a doorway: his top must be below the door's top...
  $F888,10 ...and his feet not below the door's foot
  $F892,4 His top: as far below +16 as it was below the door's top
  $F896,1 D = his top on arrival
  $F897,4 C, E, L = his sizes; keep all six in the other set
  $F89B,3 C = the room behind the door (+13)
@ $F89E label=ARRIVAL_CHECK
  $F89E,5 HL five bytes before the object table, so that each step of five and the byte read after it moves on one six-byte record; keep the door's record
  $F8A3,7 Next record: E = its room, A = its type
  $F8AA,4 The first eleven-byte record ends the things: none is in the way
  $F8AE,4 A thing in another room: next
  $F8B2,12 Make a record of it at IY+$4B: its +12 byte and its place (x, top, y) go to +5 to +8 (+5 and +6 are PRINT_X and PRINT_Y; whatever prints next sets them again)
  $F8BE,12 Its template (#R$B734): the sizes, at byte 6
  $F8CA,6 To +9 to +11
  $F8D0,9 Would he arrive in its box? (the box test in #R$FCDC, with his arrival in the other set)
  $F8D9,4 No: next thing
  $F8DD,6 A thing with bit 4 of +12 does not count
  $F8E3,9 Anything else: BLOCKED, and it is a wall
@ $F8EC label=GO_THROUGH_DOOR
  $F8EC,3 Krumlinde's RTN_Trigger_Room_Change. The room is the one behind the door
  $F8EF,4 Drop the scan's IX, and the two words the main loop left (#R$FE47): #R$FD20 goes back into the loop itself
  $F8F3,7 Move the knight to where he arrives
  $F8FA,6 With the state he had
  $F900,3 Save where the things of the room are (#R$F906)
  $F903,3 And enter the new one

# The scratch record's +5, not PRINT_X (range 5).
@ $F8B6 keep

# --------------------------------------------------------------------------
# Meeting objects, collision, movement, the main loop, the variables
# --------------------------------------------------------------------------

@ $F906 label=SAVE_OBJECT_POSITIONS
c $F906 Write the room's things' positions back into the object table (the author's EEN)
D $F906 Run whenever the knight leaves a room: through a door (#R$F7C4), carried off by the thing of kind 9 (#R$FE47), and at the end of a game, before GAME OVER (#R$F065). The records after the knight's (from #R$BCA4) are the things he carries and then the object table's things for this room, in the table's order. For each, the three bytes of where it is -- +6 x, +7 y (its top: y is the height) and +8 z -- are copied into bytes 3 to 5 of its entry in the object table (#R$A924), found from the number at +$13. That is how a thing left somewhere, or pushed, is still there when the knight comes back.
D $F906 The walk stops at the first door. The table lists a room's things that can move before its doors, and nothing after them is kept: not the doors, not the table's last six-byte entries (the author's source text heads them STATIC OBJ), and not what the room's drawing placed. The walk would also stop after the last record in use, but that never happened in the build's sessions: every room has a door.
D $F906 Two creatures are drawn facing the other way by turning their shared frames round in place: the wraith (#R$5E88, behaviour 11) and the troll (#R$8BB8, behaviour 7) -- the author's MIWRAI and MITRO name the routines. One whose frames are turned (bit 5 of +14) has them turned back here, by asking for the direction +x (C=8), so that the next room's wraiths and trolls, which start with bit 5 clear, find them the way round they expect. The record keeps its bit 5, but it is about to be overwritten.
E $F906 Measured in the simulator: a thing's +6 and +8 changed in room 20, then LIFE set to 0; after this routine the thing's entry held the new values.
  $F906,6 Nothing to do if the knight's is the last record in use (the seventh)
  $F90C,5 IX = the first record after his; B = how many there are
  $F911,8 Stop at the first door (kind 1 in +12)
  $F919,14 HL = the thing's entry plus 3: six bytes a number, counted on from just below the table; kept on the stack
  $F927,8 B = its behaviour byte (+14); C = 8, facing +x, for the mirror routines
  $F92F,11 Behaviour 11, the wraith: frames turned round (bit 5)? Turn them back (MIWRAI)
  $F93A,9 Behaviour 7, the troll: the same (MITRO)
  $F943,13 Copy x, y and z (+6 to +8) into the entry
  $F950,8 On to the next record
  $F958,1 After the last record (never reached in the build's sessions)

@ $F959 label=OBJECTS_MEET
@ $F9E6 label=OTHER_VANISHES
c $F959 Settle what happens when a moving object runs into one that is not a door
D $F959 Jumped to from #R$F7C4 when the move tried for the object being updated -- the mover: its record at WORK_RECORD, its number in THIS_RECORD and a working copy of it from IY+$64 -- would overlap a record that is not a door: the other, at IX, its number in FOUND_RECORD. The kind bytes (+12) of the two decide, in this order.
D $F959 A mover with bit 4 of its kind byte hurts what it touches: the troll and the bouncing balls (#R$7E88). If the other is the knight he loses 10 LIFE, except on a room's first pass (bit 2 of GAME_FLAGS). If the other is not a still thing (+16), it is knocked -- bit 4 of its +14 and the direction $12 make its next update a hop upward -- and the mover vanishes where it is (bit 5 of its +16). Against a still thing the tests go on.
D $F959 When the knight walks into something whose kind byte has bit 4, he loses 10 LIFE, the other vanishes, and his move carries on as if it had not been there.
D $F959 Bit 7 of the kind byte marks a fighter: the knight and nearly every creature. A fighter other than the knight that walks into him takes 1 LIFE; the knight walking into a fighter loses 1 LIFE himself, unless his sword is out (bit 1 of GAME_FLAGS, the striking half of the fight animation, #R$F595). Then a fighter that can be killed (bit 6: the guards, the ghosts and the troll) has one of its strikes taken: the counter #R$FCA5 gave it, one of the six STRIKES_LEFT, each 4 when the room was entered. At none left, a guard (behaviour 6, 9 or 10) is left lying as its helmet (#R$A4B8), a thing that can be picked up; anything else vanishes. That never happened in the build's sessions. Staged in the simulator -- the counters set to 1, the guard of room 29 put in front of the knight, and B and Y held -- the guard became the helmet.
D $F959 After the fighters: a creature of behaviour 13 (the ghost, #R$5B30) takes any thing that can be picked up that it runs into: the thing vanishes, and its entry in the object table is moved to room $FE, out of the game (#R$F4E6). A wraith (behaviour 11) that a thing of kind 6 or 10 runs into vanishes with it, both taken out of the game; that too never ran in the sessions, and was staged in room 28 by dropping the kind-6 thing onto the wraith. Anything that runs into a kind-7 object -- the floor of the pits in rooms 9 and 12 -- vanishes, and if it is the knight, LIFE goes to 0. Everything else goes on to #R$FA83.
E $F959 When something has vanished, or a guard become a helmet, the mover's move is finished at #R$FA83's BLOCKED_MOVE and the other is redrawn -- erased, in fact, as it is now hidden -- with THIS_RECORD set to the other's number for #R$ECBD. The number is read from FOUND_RECORD after the mover's own redraw has used that byte for its sprite's width in bytes (#R$EE8D), so it is wrong: 3, not 19, when the knight met the troll in room 2 in the simulator. It only changes which record #R$ECBD leaves out of the redraw. A vanished thing is hidden anyway; a helmet is not, and is drawn once as if in front of itself -- measured with a guard killed by fighting in room 77: one pixel differs from a corrected run, for one pass.
  $F959,6 Does the mover hurt what it touches (bit 4 of its kind)?
  $F95F,6 Not on the room's first pass
  $F965,10 The knight touched: 10 LIFE (the author's DECLI1)
  $F96F,7 A still thing: on to the next test
  $F976,8 Knock it: next time it moves by the direction $12, up
  $F97E,8 The mover vanishes
  $F986,6 where it was, and is erased (#R$F65C)
  $F98C,13 Does the other hurt, and is the mover the knight?
  $F999,5 10 LIFE, and the other vanishes
  $F99E,6 Is the mover a fighter (bit 7)?
  $F9A4,7 The knight: below
  $F9AB,7 Another fighter: has it walked into the knight?
  $F9B2,7 Take 1 LIFE (at DECLIF, #R$F1B4)
  $F9B9,6 The knight: is his sword out?
  $F9BF,8 No: a fighter touched costs him 1 LIFE
  $F9C7,6 Yes: can the other be killed (bit 6)?
  $F9CD,8 Take a strike off its counter (the address's low byte in IY+2)
  $F9D5,17 None left: is it a guard (behaviour 6, 9 or 10)?
  $F9E6,6 OTHER_VANISHES: bit 5 of its +16
  $F9EC,20 The guard's helmet: its sprite, behaviour 0 with a hop, a fighter that can be picked up, direction $12
  $FA00,9 Finish the mover's move (BLOCKED_MOVE, #R$FA83)
  $FA09,13 Redraw the other as the record being drawn (the number is stale: see below)
  $FA16,5 THIS_RECORD back; the mover's update is done
  $FA1B,15 A behaviour-13 creature, the ghost, and a thing that can be picked up?
  $FA2A,22 A wraith (behaviour 11) met by a thing of kind 6 or 10?
  $FA40,17 The thing leaves the game (room $FE) and vanishes...
  $FA51,7 ...and so does the other
  $FA58,9 Kind 7, the pit floor?
  $FA61,4 IX = the mover
  $FA65,13 The knight: LIFE 0
  $FA72,2 Over the five bytes at #R$FA74

@ $FA74 label=SKIPPED_REMOVAL
b $FA74 Five bytes of code no jump reaches
D $FA74 LD C,$FE and CALL #R$F4E6, the pair #R$F959 uses to take a thing out of the game by moving its object-table entry to room $FE. They lie after the JR that ends the kind-7 case, which always skips them (Krumlinde noted them too). So a thing that falls to a pit's floor keeps its entry and, as #R$F906 saves where it vanished, is placed again the next time the room is entered, and falls in again (measured: its table room stays 9; not checked by leaving through room 9's doors). Had they run for the knight they would have done harm: the number at +$13 of his record is 0, and #R$F4E6 would count 256 entries on and overwrite a byte of the table far beyond.
B $FA74,5,5

@ $FA79 label=MOVER_VANISHES
c $FA79 Make the mover vanish where it stands
D $FA79 The end of #R$F959's kind-7 case, and of a hurting mover's touch: bit 5 of the mover's +16 hides it -- it is no longer updated, drawn or run into -- and the move is finished where the mover already was, which erases it (#R$F65C).
R $FA79 IX The mover's record
  $FA79,4 Hidden
  $FA7D,6 Finish the move at the old position

@ $FA83 label=MEET_DECOY
@ $FA9C label=BLOCKED_MOVE
c $FA83 Let a guard take a decoy, or else stop the part of a move that is blocked
D $FA83 The last case of #R$F959: a behaviour-9 guard that runs into a decoy (kind 8) takes it. The decoy vanishes, its entry goes to room $FE, and THINGS_NOTED is cleared, so that #R$F1E0 finds any other decoy afresh and until then the guard chases the knight (#R$FC48). Anything else, and a move into a door (#R$F7C4), comes to BLOCKED_MOVE.
D $FA83 BLOCKED_MOVE works out how much of the move the other object stops, trying the move against that one object only (#R$FC9C) from where the mover was. Each axis that is moving is tried alone: x (+6), y (+7, the height) and z (+8). One that collides is taken out of the move, and the mover's direction on it is turned round if the mover bounces (bit 0 of its direction, +13) or cleared if it does not. Two collisions do something else. Running along x into a kind-3 object, or along z into a kind-2 one, marks a climb (bit 6 of STEP_AXES): those are the invisible steps of a staircase, and #R$F65C lifts the mover for three passes. Coming down onto the other marks a landing (bit 5); and if what the mover lands on is moving -- by its own behaviour, or coasting (bit 7 of +14) -- the mover rides it: bit 4 of the mover's +14 is set and the other's direction (+13, or +18 if coasting) goes to RIDE_DIRECTION, which #R$F65C gives the mover. Nothing rides a door.
D $FA83 Then the pairs, from where the mover was: x with y colliding takes y out; x with z takes both out; y with z takes y out. If all three axes are still in the move after that, only the whole move collides, and none of it is made.
D $FA83 Last, a push. Unless the mover landed on the other or it is a door, and unless the other is still (nothing in the low five bits of +16, which for a thing that moves are 16 more than its weight), the other is pushed if it is no more than 5 heavier than the mover: it coasts (bit 7 of +14) for the mover's +16 less its own, plus 6, passes (+15), heading (+18) the way the mover asked to go (ASKED_DIRECTION), keeping its own bounce and rise bits. The knight's +16 is 18, so he pushes anything of 23 or less. What is left of the move is then tried again (#R$F65C), and may run into something else.
R $FA83 A The other's kind (+12, low nibble)
R $FA83 IX The other's record
  $FA83,13 A decoy, and the mover a behaviour-9 guard?
  $FA90,9 The decoy leaves the game (room $FE); look for decoys again
  $FA99,3 It vanishes (#R$F959)
  $FA9C,6 BLOCKED_MOVE: B, D, H = the mover's x, y and z before the move; C, E, L its lengths
  $FAA2,3 C = the axes moving (STEP_AXES)
  $FAA5,8 x alone
  $FAAD,2 Blocked: x out of the move
  $FAAF,13 Along x into a kind-3 step: a climb
  $FABC,16 Otherwise turn round on x if the mover bounces, or stop on x
  $FACC,11 y alone, x back where it was
  $FAD7,2 Blocked: y out
  $FAD9,4 Nothing rides a door
  $FADD,9 Coming down onto it (bit 5 of the direction)?
  $FAE6,2 A landing
  $FAE8,8 What it lands on has a behaviour: ride with its direction (+13)
  $FAF0,7 Or is coasting: ride with its heading (+18)
  $FAF7,7 Riding: bit 4 of the mover's +14, and the way to go
  $FAFE,16 Turn round on y if the mover bounces, or stop on y
  $FB0E,11 z alone, y back where it was
  $FB19,2 Blocked: z out
  $FB1B,13 Along z into a kind-2 step: a climb
  $FB28,16 Otherwise turn round on z, or stop on z
  $FB38,6 Back to where the mover was
  $FB3E,18 x and y together
  $FB50,18 Blocked: y out, turned round or stopped
  $FB62,3 Back again
  $FB65,18 x and z together
  $FB77,20 Blocked: both out, both turned round or stopped
  $FB8B,3 Back again
  $FB8E,18 y and z together
  $FBA0,18 Blocked: y out
  $FBB2,3 Back again
  $FBB5,7 All three still moving? Then only the whole move collides...
  $FBBC,20 ...so none of it is made
  $FBD0,6 What is left of the move, the landing and door bits dropped
  $FBD6,5 No push after a landing or into a door
  $FBDB,7 Nor of a still thing
  $FBE2,11 Pushed if no more than 5 heavier than the mover
  $FBED,8 Coasting for the difference plus 6 passes
  $FBF5,15 heading the way the mover asked to go, with its own bounce and rise bits
  $FC04,3 Try what is left of the move again

@ $FC07 label=STEP_ALONG_X
c $FC07 Step a position along x, if x is moving
D $FC07 Two units, or one when z is moving too. The way is bit 2 of the direction in WORK_DIRECTION: set for -x, clear for +x (bit 3).
R $FC07 C The axes moving: bit 0 x, bit 1 y, bit 2 z
R $FC07 B x
R $FC07 O:B x after the step
  $FC07,3 x not moving
  $FC0A,6 Which way?
  $FC10,6 -x: one, or two if z is not moving
  $FC16,6 +x the same

@ $FC1C label=STEP_ALONG_Y
c $FC1C Step a position along y, the height, if y is moving
D $FC1C Always two units: up if bit 4 of the direction in WORK_DIRECTION is set, down (bit 5) if not.
R $FC1C C The axes moving: bit 1 y
R $FC1C D y
R $FC1C O:D y after the step
  $FC1C,3 y not moving
  $FC1F,9 Up two
  $FC28,3 Down two

@ $FC2B label=STEP_ALONG_Z
c $FC2B Step a position along z, if z is moving
D $FC2B Two units, or one when x is moving too: +z if bit 6 of the direction in WORK_DIRECTION is set, -z (bit 7) if not.
R $FC2B C The axes moving: bit 2 z
R $FC2B H z
R $FC2B O:H z after the step
  $FC2B,3 z not moving
  $FC2E,6 Which way?
  $FC34,6 +z: one, or two if x is not moving
  $FC3A,6 -z the same

@ $FC40 label=STEP_ALL_AXES
c $FC40 Step a position along every axis that is moving
D $FC40 The whole of a move: #R$FC07, #R$FC1C and #R$FC2B in turn. A move along both x and z is one unit each way.
R $FC40 C The axes moving: bit 0 x, bit 1 y, bit 2 z
R $FC40 B, D, H x, y and z
R $FC40 O:B, D, H The position after the move

@ $FC48 label=ZOOMIN
c $FC48 Aim a chasing creature at the knight, or at a decoy (the author's ZOOMIN)
D $FC48 Called by #R$F2F7 when a chaser's timer (+15) runs out: the guards (behaviours 6, 9 and 10), the troll (7) and the wraith (11, and 15 once woken). The target is the knight's record (#R$BC90), except for a behaviour-9 guard while a decoy is in the room (bit 0 of THINGS_NOTED): then it is the decoy's record, which #R$F1E0 keeps in DECOY. IY is pointed at the target for #R$FC66, so (IY+6) and (IY+8) there are the target's x and z rather than variables -- which is why THINGS_NOTED is read by its address here -- and then set back to #R$FF80.
R $FC48 E The chaser's behaviour byte (+14)
R $FC48 IX The chaser's record
R $FC48 O:A The new heading
R $FC48 O:D How far off the target is along that axis
  $FC48,11 The target is the knight...
  $FC53,7 ...unless this is a behaviour-9 guard and a decoy has been seen
  $FC5A,4 The decoy's record
  $FC5E,3 Work out the heading
  $FC61,5 IY back on the variables

@ $FC66 label=AIM_AT
c $FC66 Work out which way a chaser should go to reach its target
D $FC66 The heading is along one floor axis only, whichever the target is further off along: x (+6) or z (+8), measured to a point two units past the target's corner, and z when they are equal. The chaser's timer (+15) is set to 10 passes before it looks again, or to 3 when the z distance is under 14 -- the z distance whichever axis won, as the code has it.
R $FC66 IX The chaser's record
R $FC66 IY The target's record
R $FC66 O:A The heading: 8 for +x, 4 for -x, $40 for +z, $80 for -z
R $FC66 O:D How far off the target is along that axis
  $FC66,9 Look again in 10 passes
  $FC6F,1 Keep HL
  $FC70,12 Along x: H = +x (8) or -x (4), D = how far
  $FC7C,16 Along z: L = +z ($40) or -z ($80)
  $FC8C,5 As far or further along z: head that way
  $FC91,8 Near along z: look again in 3 passes
  $FC99,3 A = the heading

@ $FC9C label=TEST_OTHER
c $FC9C Test the mover's box, moved, against the record at IX only
D $FC9C #R$FA83 tries each axis of a blocked move against the one object the move ran into. C is holding the axes, so the mover's x length is taken from its working copy (IY+$6D) for the test and C given back after.
R $FC9C IX The record
R $FC9C B, D, H The mover's x, y and z, moved
R $FC9C E, L Its height and z length
R $FC9C O:F Carry set if the boxes overlap

@ $FCA5 label=FIND_OBSTACLE
@ $FCB4 keep
@ $FCD1 label=NEXT_OBSTACLE
c $FCA5 Find a record whose box overlaps a given box
D $FCA5 Walks the records in use from the last down to the first -- the six fixed ones at #R$BC18, the room's floor, ceiling and four walls, included -- and stops at the first that overlaps the box, the mover's own record and hidden things aside (#R$FCDC). Used for a move (#R$F65C), for the place a thing would be dropped (#R$F309), and by the pick-up (#R$F4F4), which carries on down the list from NEXT_OBSTACLE (#R$F52A) until it finds a thing it can take.
D $FCA5 On the way it deals out the strike counters. IY+2 starts at $9E and goes down by one at each fighter (bit 7 of +12), but no lower than $98: the first six fighters from the top of the list have the counters at $9D down to $98 in STRIKES_LEFT, and any more share the last. The count depends only on the order of the records, so a fighter has the same counter for as long as the room lasts, and when a fighter is found IY+2 holds the low byte of its counter, for #R$F959.
R $FCA5 B, D, H x, y and z of the box (y its top)
R $FCA5 C, E, L its x length, height and z length
R $FCA5 O:F Carry set if a record was found
R $FCA5 O:IX The record found; FOUND_RECORD its number
  $FCA5,4 IX = the next free record
  $FCA9,6 FOUND_RECORD counts down from the number of records in use
  $FCAF,4 The strike counters from the top
  $FCB3,6 DE' = minus 20; IX = the last record in use
  $FCB9,7 A fighter?
  $FCC0,13 The next counter down, the sixth at most
  $FCCD,4 Overlapping: found
  $FCD1,8 NEXT_OBSTACLE: on down the list
  $FCD9,3 None: carry clear

@ $FCDC label=TEST_ONE_RECORD
@ $FCF2 label=BOX_OVERLAP
c $FCDC Test a box against one record, unless it is the mover's own or hidden
D $FCDC A record counts unless it is the one being updated (FOUND_RECORD equal to THIS_RECORD), or has bit 5 of +16 set -- carried, or vanished -- when it is not a door. Doors always count.
D $FCDC BOX_OVERLAP, the author's BB2, is the box test itself, used on its own by #R$F1E0 and #R$F7C4. A box runs from a corner: from +6 for the length +9 along x, from +8 for +11 along z, and down from the top, +7, for the height +10. Two boxes overlap when they overlap along all three axes, each test strict, so boxes that only touch do not; each axis that does not overlap returns at once with the carry clear.
R $FCDC IX The record
R $FCDC B, D, H x, y and z of the box
R $FCDC C, E, L its x length, height and z length
R $FCDC O:F Carry set if they overlap
  $FCDC,7 The mover's own record: no
  $FCE3,9 A door: always
  $FCEC,6 Anything else, unless hidden
  $FCF2,16 BOX_OVERLAP: z -- the record's corner less the box's must lie between minus the record's length and the box's
  $FD02,16 x the same way
  $FD12,14 y, from the tops down: the carry from the last subtraction is the answer

@ $FD20 label=ROOMST
@ $FD9C label=LOAD_ROOM
c $FD20 Enter the room in ROOM, or end the quest (the author's ROOMST)
D $FD20 Called by a new game (#R$F065, at TELE) and jumped to from the door code (#R$F7C4) once the knight's record has its new place. It does not return until the game is over: the main loop (#R$FE47) runs inside it and returns from it when LIFE is gone, or on SYMBOL SHIFT and 0, back to #R$F065 for GAME OVER. A door, and the thing that carries the knight off, come back in here with the stack as it was.
D $FD20 Room 81 is the end of the quest. Its picture is drawn and the verdict printed: success if any of the five things carried is number 5 in the object table (+$13; the thing that lies in room 33), failure if not. An empty place reads as a record at address 0, whose +$13 is a ROM byte ($FF) and never matches. Then the two lines of #R$DFF2, a key (#R$F0D2), and back to GAME OVER.
D $FD20 Any other room is entered at LOAD_ROOM (the author's ROS). First the carried things: their records, wherever the last room left them, are copied to the first places after the knight's, in the order of the five places, and each place is pointed at its record's new home. They go by way of BUFFER_D900, as one record may be moved onto another that has still to be copied. IY steps two bytes a place through the loop (the author's OBJD to OB2) so that IY+$1F and IY+$20 are each place in turn. OBJECT_COUNT becomes 7 and one for each thing carried; FREE_RECORD the next place. Then the room is drawn (#R$E55B), which also makes the records of its objects, the six strike counters are set to 4, LIFE's label is printed, and the bare room is copied to the clean copy of the screen (#R$F10B) before #R$FE15 draws the still things and starts the main loop.
E $FD20 Room 0 returns at once, which ends the game: a new game's room comes from the master copy (#R$639C), where it is 29, but door record 185, a hole in room 10's floor, leads to room 0, so falling through it ends the game with LIFE still full (measured for the Facts page).
  $FD20,3 DE = the first record after the knight's: where the carried things go
  $FD23,5 Room 0 (room 10's hole): the game ends
  $FD28,4 Any room but 81: LOAD_ROOM
  $FD2C,6 Draw room 81's picture and colour the screen; then print the start of the verdict
  $FD42,5 The five places a thing is carried in
  $FD47,7 IX = the record in this place
  $FD4E,7 Number 5 in the object table: print success
  $FD55,2 Try the next place; after the last, print failure
  $FD61,2 On to the rest of the verdict
  $FD96,3 The two lines about the quest going on (#R$DFF2)
  $FD99,3 Wait for a key, and return to the new game's code: GAME OVER
  $FD9C,4 LOAD_ROOM: seven records, the six fixed ones and the knight's
  $FDA0,8 Five places; the records gather in BUFFER_D900 first, the pointer in POINT (the author's T)
  $FDA8,14 HL = the record in the next place, IY moved on two
  $FDB6,6 Point the place at DE, the record's new home
  $FDBC,7 DE on to the next home
  $FDC3,12 Copy the record's 20 bytes to the buffer
  $FDD0,7 One more record in use
  $FDD7,2 Next place (the author's OB2)
  $FDD9,4 The room's own records start after the carried things
  $FDDD,11 Copy the carried things into place (five records' worth, whatever was carried)
  $FDE8,4 IY back on the variables
  $FDEC,3 Draw the room and make its objects' records
  $FDEF,11 Four strikes in each of the six counters; then print LIFE's label
  $FE05,3 Copy the bare room to the clean copy
  $FE08,11 From the first record after the knight's, with bit 4 of GAME_FLAGS set: still things are drawn into the room
  $FE13,2 Draw them (#R$FE15)

@ $FE15 label=DRAW_STILL_THINGS
c $FE15 Draw a room's doors and still things into its picture, and start the main loop
D $FE15 Entered at its end from #R$FD20, with HL at the first record after the knight's and THIS_RECORD at 7. Each record is drawn now, once, if it is a door or still: nothing in the low five bits of +16, a thing that never moves and that #R$F1E0 never updates. With bit 4 of GAME_FLAGS set, #R$ECBD draws it among the other still things only. When all are done the screen is copied to the clean copy again (#R$F10B), so from now on they are part of the room's picture, drawn again only where something passes in front of them.
D $FE15 Then THINGS_NOTED is cleared and GAME_FLAGS set to 5 -- LIFE to be printed (bit 0) and the room's first pass (bit 2), everything else off, a freeze included -- and the main loop starts with its keys (#R$FE47).
R $FE15 HL The record
  $FE15,6 IX = the record; THIS_RECORD = its number
  $FE1B,9 A door: draw it
  $FE24,5 Anything else only if still
  $FE29,5 Draw it (#R$ECBD)
  $FE2E,4 Next record
  $FE32,8 Until the last in use
  $FE3A,3 Copy the screen, still things and all, to the clean copy
  $FE3D,10 A new room's flags, and into the main loop

@ $FE47 label=MAIN_LOOP
@ $FE71 label=PASS_KEYS
@ $FF0E label=SHOW_IN_USE
@ $FF21 label=START_PASS
c $FE47 The main loop: the keys between passes, LIFE, the message line and every object
D $FE47 One pass is: the keys that are not the knight's own (walking, jumping, fighting, picking up and dropping are read in his update, #R$F309); LIFE printed if it has changed; the message line (#R$E038); and each record from the knight's, the seventh, to the last in use updated by the author's CHE3D (#R$F1E0). Nothing waits for the frame, so a pass takes as long as it takes. The author's source text, left on the tape, names the places from the use of a thing on: STAR2, USE6 to USE4, ST20 to ST22, STE3, ST3 to ST6 and ST9.
D $FE47 The keys, in order. 9 turns the Kempston joystick on or off (bit 3 of OPTIONS), and waits until no key is held. After a room's first pass its colours are put on (#R$F0FB) -- it was drawn black on black -- so it appears all at once, and the thing in use is shown again. Then, unless the joystick is being pushed: SPACE and SYMBOL SHIFT together pause the game until a key is pressed; SYMBOL SHIFT and 0 together return from #R$FD20, which ends the game; 6 or 7 use the thing in the chosen place; 1 to 5 choose a place and show what is in it.
D $FE47 What using a thing does depends on its kind (+12). Kind 9 carries the knight off to room 30, to where a new game starts him (TELE, #R$F065), after #R$F906 has saved the room. Kind 6 makes LIFE 99. Kind 5 freezes the room's creatures until he leaves it (bit 7 of GAME_FLAGS: #R$F1E0 then lets everything but the knight only fall). Kind 4 adds 10 to LIFE, to no more than 99. Each of these is used up: its place is emptied, though its record stays among the room's, hidden, and its entry in the object table says room $FE; LIFE is printed again. A thing of any other kind does nothing.
D $FE47 A pass ends with a RET when LIFE is 0: that returns from #R$FD20 to #R$F065, which says GAME OVER.
  $FE47,9 Row 6 to 0: 9 held?
  $FE50,8 Turn the joystick on or off
  $FE58,6 Wait until no key is held
  $FE5E,6 After the room's first pass (bit 2 of GAME_FLAGS)...
  $FE64,3 ...put the room's colours on, so it appears at once...
  $FE67,10 ...and show the thing in use again
  $FE71,6 PASS_KEYS: the joystick pushed? Then no more keys this pass
  $FE77,8 B = SPACE (bit 0) and SYMBOL SHIFT (bit 1)
  $FE7F,5 Both: pause until a key (#R$F0D2)
  $FE84,8 Row 6 to 0 again, 0 into the carry
  $FE8C,3 0 with SYMBOL SHIFT: return, ending the game
  $FE8F,4 STAR2: 6 or 7 (now bits 3 and 2)? Use the thing in the chosen place
  $FE93,11 IX = its record (0 for an empty place: its +12 is a ROM byte of kind 15, and nothing happens)
  $FE9E,9 Kind 9?
  $FEA7,4 To room 30
  $FEAB,5 Empty the place
  $FEB0,3 Save the room's things (#R$F906)
  $FEB3,4 Drop the return to the new game's code, and go in as a new game does (TELE)
  $FEB7,13 USE6: kind 6, LIFE 99
  $FEC4,10 USE5: kind 5, freeze the creatures
  $FECE,17 USE4: kind 4, LIFE's tens up one...
  $FEDF,4 ...or at 9 tens already, 99 (ST21)
  $FEE3,14 ST22: used up -- LIFE to be printed, the place emptied, and shown empty
  $FEF1,7 ST20: row 1 to 5; nothing held, on to the pass
  $FEF8,11 C = 1, 3, 5, 7 or 9 for keys 1 to 5
  $FF03,8 The place ($9F to $A7); the one in use already: nothing to do
  $FF0B,3 Choose it
  $FF0E,11 SHOW_IN_USE (STE3): HL = the record in the place
  $FF19,5 Empty: clear the box and show the place's number (#R$EC75)
  $FF1E,3 Show the thing (#R$EC4C)
  $FF21,10 START_PASS (ST3): LIFE changed (bit 0 of GAME_FLAGS)? Then move the printer to x 55, y 12
  $FF32,16 Print the tens, then the units (glyph 27 is 0)
  $FF42,3 The message line (#R$E038, at ST9)
  $FF45,7 From the knight's record, the seventh
  $FF4C,7 LIFE 0: return from #R$FD20, the game over
  $FF53,5 Update this object (CHE3D)
  $FF58,12 The last in use done: next pass
  $FF64,6 Next record

@ $FF6A label=UDG_LEFTOVERS
b $FF6A Leftover characters
D $FF6A Bits of the ROM's user-defined graphics as the tape's maker left them: the ends of the letters C, D and E, which the ROM puts at the top of memory when it starts. The game never reads them. More of the same lie among the variables above, where the game does not use the bytes.
B $FF6A,22,8

g $FF80 The game's variables
D $FF80 IY holds #R$FF80 throughout the game, so most of these are reached as IY+n: the author's source text calls this base V, as in (V+3). Only two places move IY: ZOOMIN (#R$FC48) points it at a chaser's target for a moment, and #R$FD20 steps it through the carried things. On the tape the first 61 bytes, up to OBJECTS_PLACED, hold the values a game starts with; the start-up copies them to the master copy (#R$639C) and a new game copies them back. The rest are set before they are read; on the tape many hold the ends of the ROM's user-defined graphics, like #R$FF6A.
D $FF80 From POINT up the bytes have several lives, one at a time. While a room is drawn they are the drawing's state, twenty of them (from ORIGIN) reset from #R$E582 for each room. While an object is updated (#R$F1E0), POINT to WORK_HEADING are a copy of its record's first 19 bytes -- the author's T, as in (T+13) -- so that IY+$64 is the record's +0, IY+$6A its x (+6), IY+$6B its y (+7), IY+$6C its z (+8), IY+$70 its kind (+12) and so on; FOUND_RECORD (T+20), STEP_AXES, ASKED_DIRECTION, WORK_RECORD and RIDE_DIRECTION go with them. While a sprite is drawn (#R$ECBD) the same bytes hold the rectangle being redrawn, from a copy of +0 to +11, and the drawing's counters; and DRAW_LIST, lower down, takes a list of 30 bytes that runs over the printer's and the room drawing's bytes. Each use sets what it reads first.
D $FF80 The labels are for the use the object code makes of a byte where it reads it by address, and for the drawing's otherwise.
@ $FF80 label=OBJECT_COUNT
B $FF80,1,1 Records in use, counted from #R$BC18: the six fixed ones, the knight's (7), then the carried things' and the room's
B $FF81,1,1 Not used
@ $FF82 label=STRIKES_AT
B $FF82,1,1 The low byte of the strike counter of the fighter #R$FCA5 last passed ($98 to $9D)
@ $FF83 label=THIS_RECORD
B $FF83,1,1 The number of the record being updated or drawn, counted from #R$BC18 (the knight is 7)
B $FF84,1,1 Not used
@ $FF85 label=GRAVITY
B $FF85,1,1 $23, never written: its top six bits are ORed into the direction of a thing not rising -- bit 5, down (#R$F65C)
@ $FF86 label=OPTIONS
B $FF86,1,1 Bit 3: the Kempston joystick is in use (9 turns it on and off)
@ $FF87 label=MESSAGE
B $FF87,1,1 The message #R$E038 is to show: 1 BLOCKED, 2 LOCKED, 3 TOO HEAVY; 0 none
@ $FF88 label=MESSAGE_TIMER
@ $FF8B label=NO_RISE_MASK
B $FF88,6,1 MESSAGE_TIMER: passes the message stays up (10). Then two bytes not used; NO_RISE_MASK (IY+$0B), $EF and never written: ANDed with the direction of a thing not rising, it takes out bit 4, up (#R$F65C); and two more not used
@ $FF8E label=ROOM_COLOUR
B $FF8E,1,1 The room's colour, from its first byte
@ $FF8F label=DECOY
B $FF8F,2,2 The record of a decoy (kind 8) in the room, noted by #R$F1E0 for the guards of behaviour 9
@ $FF91 label=THINGS_NOTED
B $FF91,1,1 Bit 0: a decoy is in the room (DECOY); bit 1: a thing of kind 11 is, which wakes the creature of behaviour 15 and lets the doors of room 61 be used (#R$F1E0, #R$F7C4)
@ $FF92 label=CARRIED_WEIGHT
B $FF92,1,1 The weight of what is carried; 8 or more is too heavy
@ $FF94 label=FALL_COUNT
B $FF93,2,1 Not used; then FALL_COUNT (IY+$14), the passes the knight has been falling: each over 20 costs 1 LIFE when he lands (#R$F309; measured in the simulator)
@ $FF95 label=LIFE_TENS
B $FF95,1,1 LIFE: the tens
@ $FF96 label=LIFE_UNITS
B $FF96,1,1 LIFE: the units
@ $FF97 label=GAME_FLAGS
B $FF97,1,1 Bit 0: LIFE to be printed; 1: the knight's sword out; 2: the room's first pass; 3: the knight's idle pose; 4: still things being drawn into the room; 6: a message showing; 7: the creatures frozen
@ $FF98 label=STRIKES_LEFT
B $FF98,6,6 Six fighters' strikes left, 4 each when a room is entered (#R$FCA5 deals them out)
@ $FF9E label=SELECTED
B $FF9E,1,1 The low byte of the word in CARRIED for the thing in use ($9F to $A7)
@ $FF9F label=CARRIED
B $FF9F,10,2 The records of the five things carried
B $FFA9,8,8 Not used
B $FFB1,3,3 Not used
@ $FFB4 label=ROOM
B $FFB4,1,1 The room the knight is in
@ $FFB5 label=PARTS_TABLE
B $FFB5,2,2 Where the parts are (#R$758C)
B $FFB7,1,1 Not used
@ $FFB8 label=FREE_RECORD
B $FFB8,2,2 The next free object record
@ $FFBA label=OBJECT_TABLE_AT
B $FFBA,2,2 Where the object table is (#R$A924)
@ $FFBC label=OBJECTS_PLACED
B $FFBC,8,1 Bit 0: the object table's things have been placed in this room (room code $E4, #R$E89B); the rest not used
B $FFC4,2,2 Not used
@ $FFC6 label=DRAW_LIST
B $FFC6,1,1 30 bytes to the end of AWAY_FRAMES: the numbers of the records to draw, in order, copied from BUFFER_DA00 by #R$EDC6
B $FFC7,4,4 More of DRAW_LIST
@ $FFCB label=ARRIVAL_BOX
B $FFCB,5,5 The door code (#R$F7C4) points IX here, so that a record's +5 to +11 are PRINT_X and the six bytes after it: the box of a door's far side
@ $FFD0 label=PRINT_X
B $FFD0,1,1 Where the next character is printed: x
@ $FFD1 label=PRINT_Y
B $FFD1,1,1 And y
B $FFD2,8,8 The rest of ARRIVAL_BOX, and more of DRAW_LIST
@ $FFDA label=PLACED_TYPE
B $FFDA,1,1 The type of the object being placed (#R$EB1A)
@ $FFDB label=PLACED_NUMBER
B $FFDB,1,1 Counts the object table's entries as #R$EACC walks it: the number it gives a record at +$13 (it wraps round after 255)
B $FFDC,3,3 More of DRAW_LIST
@ $FFDF label=ORIGIN
B $FFDF,1,1 Added to x (+6) of each object the room places (IY+$5F-$61; room code $E4 $05)
@ $FFE0 label=ORIGIN_Y
B $FFE0,1,1 Added to its y, the height (+7)
@ $FFE1 label=ORIGIN_Z
B $FFE1,1,1 Added to its z (+8)
@ $FFE2 label=AWAY_FRAMES
B $FFE2,2,2 How far the knight's frames for walking away (+x or +z) lie beyond those for walking towards the viewer, set just before #R$F199 adds it
@ $FFE4 label=POINT
B $FFE4,1,1 The room drawing's first point: column. While an object is updated, its +0; in #R$FD20, where the next carried record goes
@ $FFE5 label=POINT_ROW
B $FFE5,1,1 And row. While an object is updated, its +1
@ $FFE6 label=SECOND_POINT
B $FFE6,1,1 The second point: column. While an object is updated, its +2
@ $FFE7 label=SECOND_POINT_ROW
B $FFE7,1,1 And row. While an object is updated, its +14 as it was when the update began (#R$F1E0)
@ $FFE8 label=WORK_SPRITE
B $FFE8,1,1 While an object is updated or drawn, its sprite (+4, +5, a word); zero, and the byte the screen is cleared with, when a room is drawn (#R$E5BA)
@ $FFEA label=LINE_PAGE
B $FFE9,2,1 The sprite's high byte; then LINE_PAGE (IY+$6A): 0 to draw a room's lines on the screen, $80 in the clean copy (room code $E4), and while an object is updated, its x (+6)
@ $FFEB label=MODE
B $FFEB,1,1 The room drawing's mode bits (room codes $C1-$CE, $E4 $04); while an object is updated, its y (+7)
@ $FFEC label=REPEATS
B $FFEC,1,1 How many times the room drawing repeats (room code $D5); while an object is updated, its z (+8)
B $FFED,1,1 Kept with REPEATS by room code $E1; while an object is updated, its x length (+9)
@ $FFEE label=REPEAT_FROM
B $FFEE,2,2 Where the repeat goes back to; while an object is updated, its height and z length (+10, +11)
@ $FFF0 label=WORK_KIND
B $FFF0,1,1 While an object is updated, its kind byte (+12)
@ $FFF1 label=WORK_DIRECTION
B $FFF1,1,1 Its direction (+13): 0 bounces, 1 rises, 2 -x, 3 +x, 4 up, 5 down, 6 +z, 7 -z; the sprite drawing's flags
@ $FFF2 label=WORK_BEHAVIOUR
B $FFF2,1,1 Its behaviour byte (+14)
@ $FFF3 label=DRAW_WIDTH
B $FFF3,1,1 A sprite's width in bytes, while it is drawn; while an object is updated, its timer (+15)
@ $FFF4 label=WORK_WEIGHT
B $FFF4,1,1 Its +16: 16 more than its weight, 0 if still; the length of the draw list while sprites are drawn
@ $FFF5 label=WORK_ANIMATION
B $FFF5,1,1 Its animation byte (+17); rows, while a sprite is drawn
@ $FFF6 label=WORK_HEADING
B $FFF6,2,2 Its heading (+18); SP while #R$F050 borrows it; the fill's pointer to the row below
@ $FFF8 label=FOUND_RECORD
B $FFF8,1,1 The number of the record #R$FCA5 found (the author's T+20); SP while #R$E5BA borrows it; the fill's texture; a sprite row's bytes (#R$EE8D)
@ $FFF9 label=DRAW_INDEX
B $FFF9,1,1 The record #R$ECBD is looking at
@ $FFFA label=CLEAR_END
B $FFFA,1,1 Where #R$E5BA's clearing stopped
@ $FFFB label=STEP_AXES
B $FFFB,1,1 A move's axes: bit 0 x, 1 y, 2 z; 5 landed, 6 a climb, 7 into a door; the fill's pointer to this row
@ $FFFC label=ASKED_DIRECTION
B $FFFC,1,1 The direction a move asked for, before collisions changed it
@ $FFFD label=WORK_RECORD
B $FFFD,1,1 The record being updated; the fill's pointer to the row above
@ $FFFE label=DRAW_COUNT
B $FFFE,1,1 Counts down the draw list; the high byte of WORK_RECORD
@ $FFFF label=RIDE_DIRECTION
B $FFFF,1,1 The direction of what the mover has landed on; the last entry in the draw list at BUFFER_DA00 ($FF: none)
