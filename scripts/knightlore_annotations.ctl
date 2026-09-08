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

b $6108 The status font
D $6108 Forty characters of 8x8, the only text the game ever draws: the score
. and message line at the top of the screen. Digits, then letters. There is no
. lower case and no punctuation beyond what a word needs.
E $6108 This is the first byte of the disassembly, and the top of the game's
. RAM: everything below it, from $5BA0 up, is variables and object records
. that the game clears at the start of a life. See the object table note on
. #R$AFBD.

b $6248 Room dimensions, three bytes each
D $6248 Three sizes of room -- x, y and z in the game's own units. A room's
. entry in #R$6251 picks one of these by index rather than carrying its own
. measurements, which is why every room in the castle is one of three shapes.

b $6251 The rooms
D $6251 2432 bytes describing every room in the castle: its size, its colour,
. what is built into its walls and floor, and which objects start in it. Each
. record is variable length and ends at $FF, so the table can only be read
. forwards from the start -- there is no index into it.
E $6251 The block types a room can name are listed at #R$6BD1 and the
. backgrounds at #R$6CE2.

b $6BD1 Block types, indexed
D $6BD1 A word per kind of thing that can occupy a cell: plain blocks, fire,
. bouncing balls, rocks, gargoyles, spikes, chests, tables, guards, ghosts and
. the two portcullis halves. A room record names one of these by index and the
. address here says how to build it.

b $6CE2 Backgrounds, indexed
D $6CE2 The same idea as #R$6BD1 for the fixed parts of a room: arches in each
. of the four directions, gates, the tree-room variants, the three wall sizes,
. and the wizard and his cauldron.

b $6FF2 The special objects
D $6FF2 The objects the game shuffles at the start: the items the wizard asks
. for, and where in the castle each one may appear. #R$B2CF picks a set from
. this table, which is why two games ask for different things.

b $7112 Sprite lookup: type and frame to sprite
D $7112 188 words. The game indexes this by object type times eight plus a
. frame or facing number, and gets back the address of one of the 103 sprites
. that follow. Eight entries per type covers four facings for a walking thing,
. or an eight-frame animation for something that does not turn.
E $7112 Entries repeat: a walk cycle is usually four distinct sprites played
. as A B C D C B, so the table names the same address more than once rather
. than storing the frame twice.

b $728A The sprites
D $728A 103 sprites in one format, verified against every one of them: two
. header bytes, a width in bytes and a height in pixel rows, followed by
. width times height pairs. The proof is the block sizes: for all 103, the gap
. between one sprite's label and the next is exactly
. 2 + 2 * (width AND $7F) * height. Each pair is a mask byte and a bitmap
. byte, so a sprite carries the hole it has to punch in whatever is already
. drawn behind it. That is what lets Knight Lore overlap objects in depth
. without the flicker of drawing back to front.
E $728A One oddity: bit 7 of the width byte is set on exactly one sprite,
. spr_014, and clear on the other 102. The drawing code masks the width with
. $7F, so the bit is a flag rather than part of the number. What it selects
. has not been worked out.

# --------------------------------------------------------------------------
# Starting up
# --------------------------------------------------------------------------

c $AF6C Cold start
D $AF6C Wipes the game's whole RAM -- $5BA0 to $6107, 1384 bytes -- and falls
. into #R$AF88. The one thing it keeps is the frame counter, which it reads
. before the wipe and writes back afterwards as the first random seed. A
. machine that has been switched on for a different length of time therefore
. gets a different castle.
  $AF6C,3 $5BA0 to $6107: the variables and all 40 object records
  $AF72,4 FRAMES, the ROM's 50Hz counter, as the seed
  $AF7A,3 put it back where the wipe cannot reach it

c $AF7F Restart after a game
D $AF7F Clears from $5BA8 rather than $5BA0, which leaves the seeds and the
. chosen control method alone. That is deliberate: the next game should carry
. on the random sequence rather than replay the last one, and should not ask
. again which keys you wanted.

c $AF88 Set up and play
D $AF88 Builds the lookup tables, shows the menu, and then does the four
. things that make a game different from the last one: shuffles which objects
. the wizard will ask for, chooses a starting room, sets the sun and moon
. running, and places the special objects.
  $AF88,3 the tables at #R$F100 -- see #R$D69E
  $AFA5,3 the tune that plays as the game starts

c $AFB7 The player has died
c $AFBA One frame
D $AFBA The main loop. #R$AFBD walks the object table; when it reaches the end
. #R$B000 draws the frame and waits.

c $AFBD Walk the object table
D $AFBD IX steps through 40 object records of 32 bytes each, from $5C08 up to
. #R$6108 -- the byte just below the font. The game deliberately puts its object
. table on top of the ROM's system variables: from $5BA0 upwards nothing the
. ROM keeps there is wanted, and Knight Lore does not call the ROM once it is
. running. LAST-K, at $5C08, is the first byte of object zero.
  $AFBD,6 the frame counter this loop uses
  $AFC3,4 IX = the first object record
E $AFBD The stack is reloaded to $5BA0 on every object, so it grows downwards
. into the 32 bytes below and nothing that happened on the last object can
. leak into this one. #R$AFC7 pushes the loop's own continuation before
. dispatching, so an object handler returns into #R$AFE4 with a plain RET.

c $AFC7 Next object
  $AFC7,3 reset the stack for this object
  $AFCE,4 push the return address the handler will RET to

c $AFD5 Dispatch on object type
D $AFD5 Byte 0 of an object record is its type. This looks the type up in
. #R$B096 and jumps to the handler.

c $AFDB Jump through a table of addresses
R $AFDB HL the index
R $AFDB BC the base of a table of words
D $AFDB Doubles the index, adds the base, loads the word there and jumps to
. it. Used for every dispatch in the game, not just objects.

c $AFE4 One object done
D $AFE4 Stirs the refresh register into the random seed -- so the sequence
. depends on how much work the frame did -- then advances IX by 32 and goes
. round again until it reaches the font.
  $AFE4,3 R changes with every instruction fetched
  $AFEE,3 32 bytes per object record
  $AFF6,3 the end of the object table is the start of the font

c $B000 End of frame
D $B000 Draws everything the object walk decided on, plays whatever sound is
. due, and then burns whatever time is left so the game runs at a constant
. speed rather than at whatever speed the room happens to allow.
  $B01B,6 decide what is visible, then compose the room in the buffer at #R$D8F3
  $B028,7 six frames' worth, less what this frame already used

b $B096 Object handlers, indexed by type
D $B096 188 words, one per object type, in the same order as the sprite table
. at #R$7112. #R$AFD5 jumps through this.

# --------------------------------------------------------------------------
# The menu
# --------------------------------------------------------------------------

c $BD0C The control-method menu
D $BD0C Reads the keyboard directly rather than through the ROM: #R$B5F7 OUTs
. a half-row and INs port $FE. Keys 1 to 4 choose keyboard, Kempston, cursor
. or Interface II, 5 toggles directional control, and 0 starts the game. The
. menu tune plays underneath and the selected line flashes.
E $BD0C Worth knowing if you are driving the game from a script: nothing here
. goes through LAST-K, so poking the ROM's key buffer has no effect at all.
. The keys have to be presented at the port.

c $BD6C Start the game?
  $BD73,5 half-row $EF is 0 9 8 7 6; bit 0 is the 0 key
  $BD78,2 CPL in #R$B5F7 means a set bit is a pressed key

c $B5F7 Read one keyboard half-row
R $B5F7 A the half-row to select, $FE to $7F
R $B5F7 A on exit, the five key bits, 1 for pressed
D $B5F7 OUT ($FD),A puts A on the address bus high byte as well as the low, so
. the following IN reads port A*256+$FE -- the standard way of selecting a
. half-row in one register. The CPL turns the Spectrum's active-low keys the
. right way up, and the AND keeps the five that mean anything.

# --------------------------------------------------------------------------
# Drawing
# --------------------------------------------------------------------------

c $D69E Build the lookup tables
D $D69E Fills #R$F100 upwards at start-up with tables the drawing code needs
. every frame and would otherwise have to compute: pre-shifted bytes, and at
. #R$F100 itself the bit-reversal of every byte value. Reversing bits is how a
. sprite is mirrored horizontally, which is how the game gets a knight facing
. west out of one facing east.
  $D6B8,3 from here up: reverse_bits(n) for n = 0 to 255

c $D3B5 Object index to record address
R $D3B5 A the object index; bit 7 is ignored
R $D3B5 HL the address of its 32-byte record
D $D3B5 Five doublings is a multiply by 32, and $5C08 is the base of the
. object table. The AND $7F is the counterpart of the flag bit that callers
. carry in the top of the index.

b $D8F3 The screen buffer
D $D8F3 6144 bytes -- one screen's worth of bitmap, no attributes. The drawing
. code composes a whole room here and then copies it to the display in one go,
. so a half-drawn room is never visible.

b $F100 Tables built at run time
D $F100 Empty in a freshly loaded game and filled by #R$D69E. The disassembly
. covers the region anyway: it is part of the map, and a snapshot taken during
. play catches it holding real values.
