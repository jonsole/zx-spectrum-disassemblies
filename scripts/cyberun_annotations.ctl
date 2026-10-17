# --------------------------------------------------------------------------
# Agent 1: $5B00-$7101 -- the stack, the loader's entry, the landscape cells'
# records, the scratch variables, and the world: its map, its tiles, the
# things lying in it, the places the pick-ups are dealt to, and the title tune.
# --------------------------------------------------------------------------

@ $5B00 label=stack_space
b $5B00 The stack
D $5B00 The game's stack, in the printer buffer. The start (#R$9A66) sets SP to #R$5B80, so it grows down from there; the game runs with interrupts off, so nothing else ever lands on it. All zero in the snapshot.
B $5B00,122,16

@ $5B7A label=stack_top
b $5B7A The top of the stack
D $5B7A The landscape renderer (#R$D711) does not save and restore SP around its POP blitter: it loads SP with this address after each piece, which must be where the stack stands inside #R$D0BD when that is called from the play loop -- three calls deep, so that these six bytes are three return addresses and the renderer's own RET still finds its caller's (inferred from the reset; the chain of calls was not traced here).
B $5B7A,6,6

@ $5B80 label=loader_entry
c $5B80 Move the game block down and undo its nibble shift
D $5B80 The tape's BASIC calls this once the game block has loaded, 512 bytes above where it runs. It ran during loading, which the build does not see, so it is described from reading alone. #R$FC00, the copy routine the earlier PIC block left at the top of memory, moves the block down 512 bytes to #R$5C80; then an RRD walk down from the block's top moves every byte's nibbles along by one -- the tape holds the game four bits out of step -- and the game starts at #R$5C80.
D $5B80 After the game starts these 25 bytes are dead: the view's page's collision-box list (see #R$5B99) is written over them, and the stack grows down from just below them.
  $5B80,4 Stack under the copy routine's home; interrupts off for good
  $5B84,3 Move the block down 512 bytes to #R$5C80 (#R$FC00)
  $5B87,7 From the top of the block down, 158 times 256 bytes; A starts at 0, so the top byte's high nibble becomes a zero
  $5B8E,2 RRD: (HL)'s low nibble to A, A's old low nibble to (HL)'s high nibble, (HL)'s high nibble to its low nibble
  $5B90,6 Down a byte, for every byte of the block: the whole block and the system variables under it, all but their first byte (hence the nonsense in them)
  $5B96,3 Start the game

@ $5B99 label=ground_cell_top_left_rest
b $5B99 The rest of the view's page's collision-box list
D $5B99 The landscape renderer (#R$D0BD) draws the four map cells (pages) the view straddles in turn -- the view's own page at the map position (#R$5C1D = 0), the one below it (1), the one to its right (2) and the one below and right (3) -- and keeps a list of collision boxes, 37 bytes, for each: #R$5B80 (written over the loader), #R$5BA5, #R$5BCA and #R$5BEF. #R$B946 finds the list for a map column and row by comparing them with the view's own.
D $5B99 The list: +0 the number of pieces the page's tile has (zero for a page with none, and for all four while the map position's row is 0, 1 or 2, when #R$DDF8 clears them and does not call #R$D0BD at all); then, only while #R$5C3D is set, five bytes for each piece as it was drawn, written through the pointer at #R$BA09 by #R$D0BD: +0 its x, +1 its y, +2 and +3 its extent (worked out from the piece's direction and its number of steps), +4 a byte looked up by the direction. These are the ground's collision boxes, read by #R$BC5B and #R$BE8F (through #R$B946 and #R$B980). The meaning of +2 to +4 in detail is for those routines.
B $5B99,12,12 Bytes 25-36 of the list (its first 25 are at #R$5B80)

@ $5BA5 label=ground_cell_bottom_left
b $5BA5 The collision-box list of the page below the view's
D $5BA5 See #R$5B99 for the layout. The page at the map position's column and the row under it (#R$5C1D = 1).
B $5BA5,37,16

@ $5BCA label=ground_cell_top_right
b $5BCA The collision-box list of the page right of the view's
D $5BCA See #R$5B99 for the layout. The page at the next column (wrapping from 95 to 0) and the map position's row (#R$5C1D = 2).
B $5BCA,37,16

@ $5BEF label=ground_cell_bottom_right
b $5BEF The collision-box list of the page below and right of the view's
D $5BEF See #R$5B99 for the layout. The page at the next column and the next row (#R$5C1D = 3). The byte after it is not used (searched).
B $5BEF,37,16
B $5C14,1 Not used (searched)

@ $5C15 label=saved_step_x
g $5C15 A saved step across
D $5C15 In the system variables' area, which the game has no use for, like all the variables from here to #R$5C40. Many of them are scratch: one routine's loop counter is another's flag, and routines in unrelated parts of the game share a byte. Each is named by its main use and its other users are listed. The snapshot's values are the BASIC system variables put through the loader's nibble shift, and mean nothing.
D $5C15 This word is saved by #R$BD44 from a moving thing's record (+7 and +8, put through #R$BDF1) and added back further on in the same routine.
B $5C15,2

@ $5C17 label=saved_step_y
g $5C17 A saved step down
D $5C17 The same as #R$5C15 for the record's +9 and +10: saved and added back by #R$BD44. The byte after it is not used (searched).
B $5C17,2
B $5C19,1 Not used

@ $5C1A label=touch_depth
g $5C1A How far a touch went in
D $5C1A Written by #R$9E35 and #R$9EA5, which test a part of an object against a slope's shape: how far into the shape the part is, made positive. #R$BC5B reads it, negated, as a new step to push the object back out. #R$D711 also uses it as a flag between its own instructions. The byte after it is not used (searched).
B $5C1A,1
B $5C1B,1 Not used

@ $5C1C label=scratch_count
g $5C1C The busiest scratch byte
D $5C1C Used by more than forty routines as a counter or a holding place. Among them: the slope tests (#R$9E35, #R$9EA5) leave 1 in it for a touch, and #R$DF08 keeps in it the object kind it gives the pick-up places it puts into object slots ($0C for the first eleven, $1E for the last eight).
B $5C1C,1

@ $5C1D label=ground_cell
g $5C1D Which map cell is being drawn
D $5C1D Which of the four map cells #R$D0BD is drawing, 0-3 (see #R$5B99): bit 0 set for the lower row, bit 1 for the right-hand column. Elsewhere a scratch byte (#R$8820, #R$89D3, #R$BE43, #R$BE8F, #R$C27F and others).
B $5C1D,1

@ $5C1E label=row_count
g $5C1E A row count
D $5C1E Scratch, mostly a count of rows or lines: the shift-table builders (#R$F895, #R$F8D0, #R$F939) count rows in it, reloading it from #R$5C1F; #R$89D3, #R$9143 and #R$917C keep a line in it; #R$9BDA reads it.
B $5C1E,1

@ $5C1F label=row_count_spare
g $5C1F The row count's spare
D $5C1F The copy #R$5C1E is reloaded from (#R$F895, #R$F8D0, #R$F939); also scratch for #R$89D3 and #R$AA37.
B $5C1F,1

@ $5C20 label=pieces_left
g $5C20 Pieces left in the tile
D $5C20 The number of pieces left to draw in the map cell's tile: #R$D0BD sets it from the tile's record and #R$D711 counts it down. Also scratch for #R$AA37, #R$BA2E, #R$BC13, #R$BCBF and #R$F8E2. The byte after it is not used (searched).
B $5C20,1
B $5C21,1 Not used

@ $5C22 label=piece_steps
g $5C22 Steps in the piece
D $5C22 The number of steps in the piece being drawn: the low nibble of its third byte, 16 when that is 0 (#R$D0BD); read again by #R$D588. The byte after it is not used (searched).
B $5C22,1
B $5C23,1 Not used

@ $5C24 label=piece_step_y
g $5C24 The piece's step down
D $5C24 The piece's step in y, from its direction (#R$CD08, given the sign of the step in x); used by #R$D711 and #R$D9A8. Also written by #R$8347, and by #R$CF38 as a width less one.
B $5C24,1

@ $5C25 label=piece_step_x
g $5C25 The piece's step across
D $5C25 The size of the piece's step in x (#R$CD08), added to its x by #R$CD6B and #R$D0BD. Also a mode byte of the collision routines (#R$BA21, #R$BA4D, #R$BA8F, #R$BC13, #R$BC5B, #R$BCD1, #R$BE8F), written by #R$909A, #R$90A7, #R$B483, #R$C374 and #R$F7EB and read by #R$F939.
B $5C25,1

@ $5C26 label=tile_upside_down
g $5C26 The tile is upside down
D $5C26 $99 while the tile being drawn is turned upside down (its record starts $99), 0 otherwise (#R$D0BD). #R$CD08 then swaps each piece's direction between floor and ceiling through the second half of the table at #R$CE04, and #R$CD6B turns its y over (XOR $0C) and its extra bytes (XOR 1). Floors become ceilings: the caverns.
B $5C26,1

@ $5C27 label=piece_kept
g $5C27 A step kept for the column fill
D $5C27 Cleared for each piece by #R$D0BD; set by #R$D588 when it keeps a step's address and x for the fill behind a piece; read by #R$D8DA, which then uses the kept step.
B $5C27,1

@ $5C28 label=sprite_width
g $5C28 A width in bytes
D $5C28 Scratch, as a byte and as a word with #R$5C29. The sprite routines keep a width less one in bytes here (#R$A303 copies it and #R$5C29 before turning them into pixels); also used by #R$A234, #R$A27A, #R$A2EA, #R$A59F, #R$A629, #R$AAD7, #R$BF85, #R$C1CE, #R$C27F and #R$C3E3.
B $5C28,1

@ $5C29 label=sprite_width_drawn
g $5C29 The width a sprite was drawn with
D $5C29 The width a sprite was drawn with, kept to rub it out (#R$A247, #R$A266, #R$A59F, #R$A678, #R$AE98); the high byte of #R$5C28 as a word. Also read by #R$8E2D, #R$9143, #R$BFB8 and #R$C27F.
B $5C29,1

@ $5C2A label=stick_out_right
g $5C2A How far a box sticks out to the right
D $5C2A Kept by #R$BE8F, the collision box's placement, for the part that sticks out past the right of the page into the next (read by #R$BE26 and #R$BE43).
B $5C2A,1

@ $5C2B label=stick_out_up
g $5C2B How far a box sticks out above
D $5C2B The same for what sticks out above the page's top (#R$BE8F, read by #R$BE10 and #R$BE43).
B $5C2B,1

@ $5C2C label=piece_x
g $5C2C The x of the piece's step
D $5C2C Moved on by the step in x at each step of a piece (#R$D319); also used by #R$A303, #R$A498, #R$A57E, #R$BE10, #R$BE26, #R$BE8F, #R$D4CB, #R$D588 and #R$D937.
B $5C2C,1

@ $5C2D label=piece_y
g $5C2D The y of the piece's step
D $5C2D Moved by the step in y at each step of a piece (#R$D319); also used by #R$A57E, #R$BE10, #R$BE26, #R$BE43, #R$BE8F, #R$D588, #R$D86A and #R$D937.
B $5C2D,1

@ $5C2E label=move_across_kept
g $5C2E A move across
D $5C2E With #R$5C2F, a word: the move across that #R$BE8F keeps (beside #R$BF7F) and #R$BE26 and #R$BE43 read. #R$D4CB writes this byte as one of its own, a count of bytes to skip.
B $5C2E,1

@ $5C2F label=piece_steps_done
g $5C2F Steps of the piece drawn
D $5C2F How many steps of the piece have been drawn: cleared for each piece by #R$D0BD and counted up by #R$D711, which draws nothing more for a piece with none; also read by #R$CEDB, #R$D86A and #R$D937. Its other use is as the high byte of #R$5C2E.
B $5C2F,1

@ $5C30 label=tile_mirrored_left_right
g $5C30 The tile is mirrored left-right
D $5C30 $FF while the tile being drawn is mirrored left-right (its record has an $FF before its piece count), 0 otherwise (#R$D0BD). #R$CD6B then reflects each piece's x, swaps its two extra bytes (XOR 2) and turns its direction round through the first half of the table at #R$CE04. Also the low byte of a move down #R$BE8F keeps for #R$BE10 and #R$BE43.
B $5C30,1

@ $5C31 label=edge_flags
g $5C31 The view's edge flags
D $5C31 Which of the view's edges a step or an object has crossed: cleared at each step by #R$D319, set and tested by the clipping routines #R$CE79, #R$CE97, #R$CEB5 and #R$CEC8; also written by #R$AD48 and read by #R$8C58.
B $5C31,1

@ $5C32 label=piece_clip
g $5C32 The piece reverses
D $5C32 Set by #R$CE79 and #R$CE97 when a piece's steps reverse at an edge, cleared for each piece by #R$D0BD, read by #R$D9A8.
B $5C32,1

@ $5C33 label=piece_extra_a
g $5C33 A flat piece's first extra byte
D $5C33 The first of the two extra bytes a piece of direction 0 or 7 carries (#R$CD6B; with the tile mirrored left-right it is the second, XOR 2; upside down, XOR 1). Read by #R$D588 and #R$D8DA, and by #R$8347 and #R$83A1 as a word with #R$5C34.
B $5C33,1

@ $5C34 label=piece_extra_b
g $5C34 A flat piece's second extra byte
D $5C34 The second; a $16 is left as it is by both reversals. Read by #R$CF38, #R$D588, #R$D86A, #R$D8DA, #R$D9A8 and #R$838B.
B $5C34,1

@ $5C35 label=piece_ceiling
g $5C35 The piece is a ceiling
D $5C35 $80 when the piece's direction is 7 or more, the ceiling shapes (#R$E3D8); cleared for each piece by #R$D0BD; read by #R$D711 and #R$D9A8. The collision routines (#R$BA4D, #R$BA8F, #R$BC13, #R$BE8F) also keep in it what has happened this pass, bit 7 a block hit and bit 4 a slope.
B $5C35,1

@ $5C36 label=steer_push
g $5C36 Which way the ship was pushed
D $5C36 Cleared by #R$B234 every pass and set there from the controls: $80 pushed left, 3 right, 0 not. #R$C3E3 turns the ship's facing towards it; #R$C7FC reads it too.
B $5C36,1

@ $5C37 label=controls_now
g $5C37 This pass's controls
D $5C37 In the Kempston layout (bit 0 right, 1 left, 2 down, 3 up, 4 fire), as #R$B115 leaves them; #R$B234 forces 8 (thrust) while the stage is ending. Read by #R$B731, #R$B833, #R$B889, #R$C3E3, #R$C6D2, and by #R$F23B, which stirs it into the random number.
B $5C37,1

@ $5C38 label=ship_line
g $5C38 The ship's line
D $5C38 The ship's line on the screen, the line its shots fly along: set by #R$AFE9 from the ship's record (+$1E, less the ship's height, plus 9) and by #R$AA37; read by #R$8E2D, #R$9BDA, #R$B483, #R$B731, #R$B90A, #R$C1CE, #R$C27F, #R$C3E3, #R$C6D2 and #R$DCA1.
B $5C38,1

@ $5C39 label=gun_cooling
g $5C39 The gun's cooling count
D $5C39 Set to 6 by #R$B731 when it fires a shot and counted down there every pass; it fires again only once the count is 0. #R$C3E3 clears it.
B $5C39,1

@ $5C3A label=map_row_colour
g $5C3A A colour for the view's page row
D $5C3A Written by #R$DEE1 from one of two bytes kept with the view's four tile numbers (see #R$DF08), chosen by whether the map row is above 12 or not; read by #R$CF38.
B $5C3A,1

@ $5C3B label=map_row_colour_next
g $5C3B A colour for the page row below
D $5C3B The same as #R$5C3A for the row below; read by #R$CF38.
B $5C3B,1

@ $5C3C label=map_rebuild
g $5C3C The view is being built
D $5C3C Nonzero while the view is being built afresh rather than played: $FF from #R$DCA1 at the start of a life, 3 from #R$DD79, 0 when play goes on. While it is set #R$9BDA returns at once and #R$DF08 puts no objects into slots; with bit 7 set, #R$DF08 draws map tile $3E as tile $AA (two of its six pieces). #R$D0BD copies a nonzero value to #R$5C3D.
B $5C3C,1

@ $5C3D label=record_ground
g $5C3D Record the collision boxes
D $5C3D Set from #R$5C3C by #R$D0BD and by #R$DDF8: while it is nonzero, #R$D0BD writes a collision box for each piece it draws into the map cell's list (#R$5B99), so the ground's boxes are made when the view is built rather than at every pass.
B $5C3D,1

@ $5C3E label=top_speed
g $5C3E The ship's top speed across
D $5C3E 2, or 4 when +$0A of the current player's record (#R$F5E7) (an add-on) is set (#R$AFE9); read by #R$C3E3, #R$C7FC and #R$C868, which hold the speed to it.
B $5C3E,1

@ $5C3F label=top_climb
g $5C3F The ship's top climb
D $5C3F 2, or 4 when +$0B of the record (an add-on) is set (#R$AFE9); set to 4 by #R$B234 while the stage is ending, and read there and by #R$B322.
B $5C3F,1

@ $5C40 label=fuel_saver
g $5C40 Halve the fuel burn
D $5C40 Set to $FF by #R$8E2D, and every pass copied away (to #R$8CB1) and cleared by #R$8D42; read by #R$B234 and #R$BCD1. While it is set the fuel burn at the end of #R$B115 is halved (again, after any halving for +$0C of the current player's record).
B $5C40,1

@ $5C41 label=basic_leftovers
b $5C41 Unused: what is left of the system variables
D $5C41 Nothing refers to these bytes (searched). They are the BASIC system variables the loader found here, put through its nibble shift.
B $5C41,63,16

@ $5C80 label=game_entry
c $5C80 Game entry
D $5C80 Where the loader (#R$5B80) jumps once the game is in place: interrupts off -- the game never turns them on -- and on to the start.
  $5C80,1 Interrupts off
  $5C81,3 Start the game (#R$9A66)

@ $5C84 label=double_bits
b $5C84 Bit-doubling table
D $5C84 Sixteen bytes, one for each value of a nibble: each of the nibble's four bits doubled into a pair, so that bit n of the index sets bits 2n and 2n+1. #R$A0DB prints characters twice as wide this way (and twice as tall, by writing each row twice), looking up each half of a font byte: it adds the nibble to $84 with B holding $5C, so the table has to sit within one page.
B $5C84,16,8

@ $5C94 label=map_object_kinds
b $5C94 The things lying in the world: their kinds
D $5C94 The world's 290 objects -- the things lying in the landscape at fixed places, as opposed to the attackers -- are kept in three parallel tables: this one, one byte each; #R$5E17, two bytes each (where); and #R$5DB6, how many there are in each map column. They are in column order, so the objects of column C start at the sum of the counts of the columns before it (#R$E08F).
D $5C94 Each byte here: bits 0-5 the object's kind, 0-16, which #R$E114 copies into the object slot's +$13 and looks up in the table at #R$E0FD (bits 5-7 of that entry go into the slot's +$18, and with bit 4 set the slot's graphic is $1B instead of $0D, an animated object whose frame byte and frame range come from #R$E10E); bit 7 set once player 1 has taken or destroyed the object, bit 6 once player 2 has (#R$A8F4 and #R$ABA8 find the byte again from the slot's +$18 bit 0 and +$19, which hold its number), after which it never comes back for that player: #R$F440 patches the BIT 7 in #R$E114 and the SET 7s in #R$A8F4 and #R$ABA8 to bit 6 while player 2 plays. #R$9A8A ANDs every byte with a mask: $3F at a new game (#R$F3BD), so bits 6 and 7 are cleared and everything comes back; at the end of a planet (#R$83D6) a mask from the player in play (#R$CA1C), $7F for player 1 and $BF for player 2, so that only that player's objects come back.
D $5C94 Read by #R$E08F and #R$E114 each time the screen moves to a new map column. Laid out below a line per map column, the kinds of that column's objects, from the game's bytes when the disassembly is built.

@ $5DB6 label=map_objects_per_column
b $5DB6 The number of objects in each map column
D $5DB6 One byte for each of the 96 map columns: how many of the objects at #R$5C94 and #R$5E17 lie in it. They add up to 290. #R$E08F adds up the counts of the columns before the screen's column to find its first object, and takes the counts of that column and the next.
D $5DB6 A 97th byte follows, a copy of column 0's count: when the screen is at column 95, the next column is column 0 again, and #R$E08F reads its count from here before it starts again at the beginning of the tables.

@ $5E17 label=map_object_places
b $5E17 The things lying in the world: their places
D $5E17 Two bytes for each of the 290 objects, in the same order as #R$5C94. Their column is the one #R$5DB6 puts them in; these give the rest, as #R$E114 unpacks them into an object slot.
D $5E17 First byte: bits 2-7, less 1, the y within the map cell (slot +5); bits 0-1 are bits 3-4 of the x within the cell. Second byte: bits 5-7 are bits 5-7 of the x (slot +2), and bits 0-4 the map row, 1-28 (slot +4). An object is put into a slot only when its row is the screen's map row or the one below.
D $5E17 So objects are placed on an 8-unit grid in x and a 4-unit grid in y within their cell. Laid out below a line per map column, each object's kind (from #R$5C94), row and place decoded, from the game's bytes when the disassembly is built.

@ $605B label=place_pool
b $605B The places the pick-ups can be dealt to
D $605B At every new game #R$6113 deals each player nineteen places for the pick-ups, chosen at random from this pool and copied into the player's record (from +$1D of #R$F5E7 or #R$F650); #R$DF08 later puts the ones in the screen's cells into object slots. Each place is four bytes: the map column, the map row, the x within the cell (to the slot's +2) and the y within the cell (to the slot's +5). While dealing, bit 7 of the first byte marks a place already given out.
D $605B Five groups, one for each value in the dealing list (#R$61A9). No table says where they are: #R$6113 picks a group by its own code, loading its first place and a mask one less than its size. Within each group the places are in column order. Laid out below a line per place, decoded from the game's bytes when the disassembly is built.
@ $605B label=place_pool_kind3
@ $609B label=place_pool_kind1
@ $60DB label=place_pool_kind5
@ $60E3 label=place_pool_kind2
@ $60EB label=place_pool_kind2_third
@ $6103 label=place_pool_kind4

@ $6113 label=deal_places
c $6113 Deal a player the places of the pick-ups
D $6113 Called twice by #R$F3BD at a new game, once for each player's record (#R$F5E7, #R$F650). Goes through the dealing list at #R$61A9 and, for each entry, writes a four-byte place (see #R$605B) to the record and moves on four bytes. An entry of 1 to 5 deals a place at random from that group of the pool, one not dealt already; an entry of 0 deals nothing, leaving the four bytes as they were ($FF, no place) -- unless the next entry is 3, when it copies the place before it, 16 to the right and 35 up, so the two pick-ups lie side by side. The list ends with its entry of 4, which is dealt too.
D $6113 Every place in the pool is free again at the start, so the two players are dealt independently and may be given the same places.
R $6113 DE The player record's first place (+$1D)
  $6113,4 The whole list, nineteen entries
N $6117 With IY at the list's last entry alone (#R$83D6, at the end of a stage), this deals the record's last place again.
  $6117,15 Mark all 46 places in the pool free
  $6126,8 Except the first and third places of kind 2, never dealt
  $612E,6 An entry of 1-5: deal from a group
  $6134,7 An entry of 0: unless the next entry is 3, leave this place alone
  $613B,11 Copy the place before it
  $6146,5 Its y 35 less
  $614B,5 Its x 16 more
  $6150,2 Next entry
  $6152,39 Pick the kind's group and a mask one less than its size: kind 1 the second group of #R$605B, 3 the first, 2 the fourth, 4 the fifth, 5 the third
  $6179,10 A place of the group chosen by the random number (#R$9BCB)
  $6183,10 Already dealt: stir the random number (#R$F23B) and try again
  $618D,5 Copy it to the record
  $6192,6 Mark it dealt
  $6198,3 Next entry
  $619B,4 Leave four bytes
  $619F,6 Stop after the entry of 4
  $61A5,4 Next entry

@ $61A9 label=dealing_list
b $61A9 The dealing list
D $61A9 One byte for each of the nineteen places #R$6113 deals a player, in the order they go into the record: the kind of the pool group (#R$605B) each is dealt from, or 0 for one dealt from nowhere. #R$DF08 gives the first eleven places object kind $0C and the last eight kind $1E, and puts the place's number, counted again from 0 at the twelfth, in the slot's +$13.
D $61A9 Laid out below a line per entry, decoded from the game's bytes when the disassembly is built.
@ $61BB label=dealing_list_last

@ $61BC label=landscape_map
b $61BC The landscape map
D $61BC The world: 96 columns by 28 rows of map cells, a byte each, a row after another (96 bytes a row). Each byte is the number of a tile, 0-$A9, which picks the tile's record through #R$6C3C. A cell is a page the size of the play area; the view scrolls across the pages, so it straddles up to four of them, two across and two down, from the map position (a column and a row kept as a word by #R$DF08) -- #R$DF08 collects their four tile numbers and #R$D0BD draws them. Tiles turned upside down (see #R$6D92) give the caverns their ceilings.
D $61BC #R$E216 finds a cell: row R (1-28) is at this table plus (R-1)*96. Row 0, the sky, is not stored: #R$E235 gives tile 0 for it. Below the last row #R$DF08 uses tile $20: for the lower cells when the map position is on row 28, and for all four when it is on row 29. Columns wrap: column -1 is 95 and column 96 is 0, so the world is a ring.
D $61BC Tiles $00, $20, $2A and $A6 have no pieces, so a cell with one draws nothing: between them they fill most of the map. Laid out below a line per map row, from the game's bytes when the disassembly is built: rows 1-11 are the surface, in the planet's first colour, and rows 12-28 the caverns, in its second (#R$DEE1).

@ $6C3C label=tile_table
b $6C3C The landscape tiles
D $6C3C A word for each of the 171 tiles, $00-$AA: the address of its record in #R$6D92. Tile $AA is never in the map: #R$DF08 draws it instead of tile $3E while #R$5C3C has bit 7 set.
D $6C3C Many tiles are other tiles turned upside down or mirrored left-right, and their records share bytes: the address of such a tile is one, two or three bytes before the plain tile's, where the markers that say so lie (see #R$6D92).
D $6C3C Laid out below a word per tile, each with how the tile reads its record and how often the map uses it, from the game's bytes when the disassembly is built.

@ $6D92 label=tile_records
b $6D92 The landscape tiles' records
D $6D92 Each tile is drawn by #R$D0BD as a list of pieces of ground, each a line of steps of one piece graphic. A record:
D $6D92 Up to three optional markers first. $99: upside down -- floors become ceilings: each piece's direction is swapped through the second half of the table at #R$CE04 (0 and 7, 1 and 8 ... 6 and 13 swap places, 14 and 15 swap), its y is turned over (XOR $0C) and its extra bytes XOR 1. $FF: mirrored left-right -- each piece's x is reflected, its two extra bytes are swapped (XOR 2) and its direction turned round through the table's first half. Then any byte of $95 or more is padding, skipped. Then the number of pieces; a record that is just 0 has none.
D $6D92 Each piece: its x and y in the page; a byte with the direction in bits 4-7 and the number of steps in bits 0-3 (0 means 16); and, only for directions 0 and 7, two extra bytes (#R$5C33, #R$5C34). The direction picks three bytes from #R$E3BD by #R$E3D8: the step in x, the step in y, and a third that is 0 for directions 0 and 7 (the flat pieces) and 8 or 16 for the others. Directions 7 to 13 are the ceiling shapes of 0 to 6 and use the entry seven less, with #R$5C35 set.
D $6D92 The padding rule is what lets four tiles share a record: a plain record of n pieces at A can be preceded by $99 (A-1, upside down), $FF $99 (A-2, mirrored left-right: the $99 is padding) and $99 $FF $99 (A-3, both). So 72 records, one after another with nothing between, serve all 171 tiles: 74 tiles have no marker, 27 are upside down, 51 mirrored left-right and 19 both. Read in Python, every byte from here to the tune is used except one (an unused $99, the third byte of the block).
D $6D92 Laid out below a line per record, from the game's bytes when the disassembly is built: each marker a byte of its own, so that every tile's word in #R$6C3C lands on one, then the count and the pieces; the comment names the tiles that read the record, and how, and decodes each piece as its (x,y) in the page, its direction and its steps, and a flat piece's two end codes.

@ $70D8 label=title_tune
b $70D8 The title tune
D $70D8 The tune the menu (#R$F26C) plays through #R$9A9A, which stops at any key. 250 notes and an end marker, running on past this range. Each note is played by #R$9AB4: bits 0-5 a note number, the note's three bytes in the table at #R$9B0C (0 is a rest); bits 6-7 how many times the note's length to hold it, 1-4. $FF ends the tune.
B $70D8,250,12 The notes
B $71D2,1 End
# --------------------------------------------------------------------------
# Agent 2: $7102-$8D41 -- the sound effects, the sprite graphics, the
# landscape's edge pieces, the planet-secured screen, the menu's loop and its
# pointers, spawning (attackers, clouds, meteor showers, what ground objects
# and attackers fire), the free-record finder, acceleration with a speed
# limit, steering back to the view, and the ship's break-up.
#
# The bytes $7102-$71D2 are the end of the title tune, in agent 1's entry at
# $70D8 (its `; span $70D8,251`); nothing here claims them.
#
# Checked with ctl_tools.py check --new-entries against the merged listing.
#
# Graphics, as read: every picture is drawn bottom-up (#R$A1C3 steps up a
# line), so its lines are stored bottom line first, and its position is its
# bottom line. The usual form is width in bytes, height in lines, then
# width x height bytes, no mask (#R$C96F copies one such picture onto the
# screen as it is; the objects' drawing works from the same header).
# --------------------------------------------------------------------------

@ $71D3 label=beep_pulse
c $71D3 Sound one beeper pulse: B loops on, D loops off
D $71D3 The building block of the crackles (#R$7293, #R$72CF). The game runs with interrupts off and makes every sound by timing loops like these, so a sound costs its length in processor time: about 13 T-states for each loop of B and of D, here and in #R$71E0.
D $71D3 The border stays black: OUT ($FE) writes $10 (speaker on) and 0.
R $71D3 B Loops with the speaker on (0 = 256)
R $71D3 D Loops with it off (0 = 256)
  $71D3,6 Speaker on, wait B loops
  $71D9,7 Speaker off, wait D loops

@ $71E0 label=beep_cycle
c $71E0 Sound one square-wave cycle: B loops on, B loops off
D $71E0 The building block of the tones and sweeps. One cycle takes about 26 x B T-states, so the pitch falls as B grows. B comes back unchanged, so a caller can loop on it.
R $71E0 B Half the period, in loops (0 = 256)
  $71E0,8 Speaker on for B loops, keeping B
  $71E8,8 Speaker off for B loops, B restored

@ $71F0 label=sound_rising_whine
c $71F0 Sound a rising whine
D $71F0 Called by #R$DD79. 32 cycles whose half period falls from $90 to $71 loops, so the note rises. The entry at #R$71F4 is the general sweep: C cycles, each of half period C + D, C counting down. #R$71FE, #R$725C, #R$7275 and #R$7318 are this with other numbers.
  $71F0,4 32 cycles from a half period of $90

@ $71F4 label=rising_sweep
c $71F4 Sound a sweep of C cycles
D $71F4 The general sweep, entered from #R$71F0, #R$71FE, #R$725C, #R$7275 and #R$7318: C cycles, each of half period C + D, C counting down, so the note rises.
R $71F4 C Number of cycles, and the part of the period that shrinks
R $71F4 D The fixed part of the period
  $71F4,3 Half period C + D
  $71F7,7 One cycle (#R$71E0); next C

@ $71FE label=sound_pick_up
c $71FE Sound a short rising chirp
D $71FE Called by #R$AAD7 when the ship picks up a pick-up. 16 cycles from a half period of $50 down to $41 (#R$71F4).
  $71FE,6 C=16, D=$40

@ $7204 label=sound_unused
c $7204 An unused sound: a crackle like #R$7293's
D $7204 Nothing calls these six bytes (sna2ctl took them for data): LD C,$17, LD E,C and a jump into the crackle loop at #R$7297, so 23 clicks with C = E = $17 to start.
  $7204,6 C = E = $17, then the crackle loop

@ $720A label=sound_debris
c $720A Sound the wreck's debris
D $720A Called by #R$96D8, the update routine of type $15 (debris), for each piece each pass while the death byte (#R$8F53) is below 10. The piece's path step (+$15, bits 0-5) halved picks the note, so the sound changes as the pieces fly.
D $720A The entry at #R$7217 is the warble itself, also used by the death sound (#R$72AB): for A of 16 or more, and for 7 and 8, nothing; otherwise four cycles alternating between two half periods, B = 2 x A + $48 and that XOR $2A.
  $720A,6 Not once the death byte is 10 or more
  $7210,7 The piece's path step, halved

@ $7217 label=warble
c $7217 Sound a warble
D $7217 Entered from #R$720A and the death sound (#R$72AB). For A of 16 or more, and for 7 and 8, nothing; otherwise four cycles alternating between two half periods, B = 2 x A + $48 and that XOR $2A.
R $7217 A The note, 0-15
  $7217,10 No sound for 16 and over, nor for 7 and 8
  $7221,6 B = 2 x (A AND 15) + $48
  $7227,13 Four cycles, B toggling by $2A between them

@ $7234 label=sound_flutter
c $7234 Sound a flutter
D $7234 Called by #R$B414 while its record's +$0E is not zero. D = 8 x (1 + the pass counter's low three bits), so 4 to 32 cycles, longer on some passes than others; each cycle's half period is (D XOR 7) + 1 as D counts down by two.
  $7234,10 D = 8 x (pass AND 7, plus 1)
  $723E,14 A cycle of (D XOR 7) + 1; D down by two until it reaches 0

@ $724C label=sound_zap
c $724C Sound a falling zap
D $724C The commonest effect: called by #R$83D6 (the bonus count), #R$8E2D (the shield starting), #R$8F54 (damage), #R$9015 (fuel), #R$9020 (an extra life), #R$917C (a shot hits), #R$94A8 and #R$9572. 16 cycles whose half period is (NOT (4 x C)) AND $7F as C counts down from 16: $3F, $43, ... $7B, so the note falls.
D $724C The entry at #R$724E takes the number of cycles in C (#R$72AB uses 7).
  $724C,2 Sixteen cycles

@ $724E label=zap_sweep
c $724E Sound a falling zap of C cycles
D $724E Entered from #R$724C (16 cycles) and #R$72AB (7). Each cycle has half period (NOT (4 x C)) AND $7F as C counts down, so the note falls.
R $724E C Number of cycles
  $724E,14 Half period (NOT 4C) AND $7F; next C

@ $725C label=sound_ship_colour
c $725C Sound a short whine when the ship changes colour
D $725C Called by #R$F1BD whenever the ship's colour changes: it works out $47 (white), $46 (yellow, when the ore tank is full: the ore count in #R$C905 is 18) or $45 (cyan, with the shield on, flashing in its last $20 passes), and sounds this when that differs from last time (the attribute in the patch at #R$F1FF, its third byte). Ten cycles of half period $8A down to $81 (#R$71F4). It never ran in the build's sessions, none of which had the shield or a full tank; a recording of a staged shield running out, made for the Sounds page, bears the reading out.
  $725C,7 C=10, D=$80

@ $7263 label=sound_buzz
c $7263 Sound a buzz
D $7263 Called by #R$BA8F and #R$BCD1. 15 cycles whose half period is ((C XOR 2) AND 4) x 8: either 32 loops or 0, which DJNZ counts as 256, in runs of four: four of 32, four of 256, four of 32 and the last three of 256 -- a rough two-note buzz.
  $7263,18 15 cycles, half period 32 or 256 loops

@ $7275 label=sound_hum
c $7275 Sound the tough attacker's hum
D $7275 Called by #R$94A8, the update routine of type $19, each pass. Silent on even passes; otherwise four cycles of half period $13 down to $10 (#R$71F4). With bit 6 of the record's +$16 set it would play three cycles of half period $1E to $1C instead, but only on a pass whose count AND 3 is 0 -- and every even pass has returned already, so that branch can never sound. Bit 6 was never set in the build's sessions; eight calls with it set, recorded for the Sounds page, were all silent.
R $7275 IX The attacker's record
  $7275,6 Only on odd passes
  $727B,11 Four short cycles, unless bit 6 of +$16
  $7286,13 Otherwise three lower cycles when the pass count AND 3 is 0, which no odd pass gives: never

@ $7293 label=sound_crackle
c $7293 Sound a crackle
D $7293 Called by #R$BA8F. The crackle loop at #R$7297 makes C clicks: for each, B = 2 x (C XOR E) and D = B AND $1F, one pulse of B loops on and D off (#R$71D3). The XOR scrambles the lengths, so the clicks sound like noise; E picks the scramble. #R$72A5, #R$72AB, #R$72F2, #R$7303 and #R$7311 enter it with other numbers. Here C = $1C, E = $27.
  $7293,4 28 clicks, scramble $27

@ $7297 label=crackle
c $7297 Sound a crackle of C clicks
D $7297 The crackle loop, entered from #R$7204, #R$7293, #R$72A5, #R$72AB, #R$72F2, #R$7303 and #R$7311. For each click B = 2 x (C XOR E) and D = B AND $1F: one pulse of B loops on and D off (#R$71D3). The XOR scrambles the lengths, so the clicks sound like noise; E picks the scramble.
R $7297 C Number of clicks
R $7297 E The scramble
  $7297,14 A click of 2(C XOR E) loops on, the low five bits of that off

@ $72A5 label=sound_tick
c $72A5 Sound a short crackle
D $72A5 Called by #R$90A7 and #R$B6F2. Eight clicks, scramble 3 (#R$7297).
  $72A5,6 C=8, E=3

@ $72AB label=sound_death
c $72AB Sound the ship's death
D $72AB Called by #R$8D42 each pass once the death byte (#R$8F53) has reached 10, until it reaches $2D: from nine passes after the ship is destroyed. Docking with the finished rocket does not play it: #R$9572 sets the death byte to 10 only for the two calls that put the ship away, and back to 0 in the same call, before #R$8D42, its only caller, runs in the pass. It plays the warble (#R$7217) with the death byte - 10, then, on every eighth count, a seven-cycle zap (#R$724E); on the other odd counts, eleven clicks with the death byte halved as the scramble (#R$7297); on even counts nothing more.
  $72AB,6 Nothing from $2D on
  $72B1,5 The warble, note = death byte - 10
  $72B6,8 A multiple of 8: the zap below
  $72BE,3 Even: nothing more
  $72C1,9 Odd: eleven clicks, scramble = death byte / 2
  $72CA,5 Seven cycles of the zap

@ $72CF label=sound_beams
c $72CF Sound the flickering beams
D $72CF Jumped to from the end of #R$9BDA when it has drawn a beam. The record in IX sets the sound: C = ((+0 XOR +1) AND 15) + 8 pulses, E = +2 AND $1F; for each pulse B = ((C + E) AND 15) x 2 loops on and D = 2(E + B) - B off (#R$71D3).
R $72CF IX The beam's record
  $72CF,11 8-23 pulses
  $72DA,6 E from +2
  $72E0,11 The pulse's on and off lengths
  $72EB,7 One pulse; next C

@ $72F2 label=sound_crackle_b
c $72F2 Sound a crackle, chosen by the record
D $72F2 Jumped to by #R$B731. 15 clicks with scramble $17 (#R$7297); or, when bit 7 of the record's +$16 is set, 23 clicks with scramble $20 -- a missile's, which the build's every-add-on session fired.
R $72F2 IX The record
  $72F2,11 15 clicks, scramble $17...
  $72FD,6 ...or 23, scramble $20

@ $7303 label=sound_launch
c $7303 Sound the rocket's launch
D $7303 Called by #R$9572 each pass while the rocket is launching, with the pass counter's low two bits. C = (A + 2) x 4 clicks, 8 to 20, and the scramble (NOT C + 6) AND $1F (#R$7297), so the roar changes from pass to pass.
R $7303 A 0-3
  $7303,5 C = 4(A + 2)
  $7308,9 The scramble from C

@ $7311 label=sound_fire
c $7311 Sound something being fired or thrown
D $7311 Called by #R$882B (which #R$8820 falls into and #R$8813 jumps to) when a ground object or an attacker has fired a bullet or thrown a pick-up. Ten clicks, scramble $22 (#R$7297).
  $7311,7 C=10, E=$22

@ $7318 label=sound_collect
c $7318 Sound an object being collected
D $7318 Called by #R$900B (contact effect bit 3). Ten cycles of half period $22 down to $19 (#R$71F4): a short high rising note.
  $7318,7 C=10, D=$18

@ $731F label=rocket_bars_graphic
b $731F Rocket part: a barred band
D $731F The sprite graphics, from here to the code at #R$8347, mostly in the form width in bytes, height in lines, then the lines bottom line first, with no mask. The ship's add-ons 1-9 (#R$7577 describes them) also have a height byte before and $FF or a mask after; the five pictures from #R$7846 (the jets') and the four frames from #R$803B (the special beam's) have a height byte only. Which object shows which picture is set by the per-type table in #R$AF25: each type's word points at a list of frame addresses, and the record's +$13 (low nibble) picks the frame. Names here describe what each picture looks like; what the scenery pictures are in the game is not yet worked out.
D $731F 3 bytes by 8 lines, no mask, bottom line first. Type $1E's frame 0. The rocket parts are type $1E, and a part's frame is its number.
B $731F,2,2 Width in bytes, height in lines
B $7321,24,3 The lines, bottom first
@ $7339 label=rocket_checks_graphic
b $7339 Rocket part: a chequered band
D $7339 3 bytes by 8 lines, no mask, bottom line first. Type $1E's frame 1.
B $7339,2,2 Width in bytes, height in lines
B $733B,24,3 The lines, bottom first
@ $7353 label=rocket_crate_graphic
b $7353 Rocket part: a lettered crate
D $7353 3 bytes by 17 lines, no mask, bottom line first. Type $1E's frame 2.
B $7353,2,2 Width in bytes, height in lines
B $7355,51,3 The lines, bottom first
@ $7388 label=rocket_crate_b_graphic
b $7388 Rocket part: a second lettered crate
D $7388 3 bytes by 16 lines, no mask, bottom line first. Type $1E's frame 3.
B $7388,2,2 Width in bytes, height in lines
B $738A,48,3 The lines, bottom first
@ $73BA label=rocket_fin_graphic
b $73BA Rocket part: a fin
D $73BA 2 bytes by 16 lines, no mask, bottom line first. Type $1E's frame 4.
B $73BA,2,2 Width in bytes, height in lines
B $73BC,32,2 The lines, bottom first
@ $73DC label=rocket_fin_b_graphic
b $73DC Rocket part: the other fin
D $73DC 2 bytes by 16 lines, no mask, bottom line first. Type $1E's frame 5.
B $73DC,2,2 Width in bytes, height in lines
B $73DE,32,2 The lines, bottom first
@ $73FE label=rocket_nose_graphic
b $73FE Rocket part: a pointed badge
D $73FE 3 bytes by 18 lines, no mask, bottom line first. Type $1E's frame 7.
B $73FE,2,2 Width in bytes, height in lines
B $7400,54,3 The lines, bottom first
@ $7436 label=addon_slab
b $7436 Add-on 10: a large slab (its size)
D $7436 The width and height of add-on 10 (5 bytes by 35 lines), the tenth entry of the add-ons' list (#R$AF95), as type $0C objects (an add-on lying on the planet) read it. #R$C1CE draws it apart from the ship from #R$7438, with sizes of its own. Add-ons 10 and 11 have no height byte before them and no mask after.
B $7436,2,2 Width in bytes, height in lines

@ $7438 label=addon_slab_picture
b $7438 Add-on 10's picture
D $7438 35 lines of 5 bytes, bottom line first: the picture #R$C1CE draws from here, past #R$7436's size bytes.
B $7438,175,5 The lines, bottom first

@ $74E7 label=addon_spire
b $74E7 Add-on 11: a tall spire (its size)
D $74E7 The width and height of add-on 11 (3 bytes by 47 lines), the eleventh entry of #R$AF95. #R$C1CE draws it from #R$74E9 with sizes of its own.
B $74E7,2,2 Width in bytes, height in lines

@ $74E9 label=addon_spire_picture
b $74E9 Add-on 11's picture
D $74E9 47 lines of 3 bytes, bottom line first. The byte after it is add-on 8's height byte.
B $74E9,141,3 The lines, bottom first
B $7576,1,1 Add-on 8's height byte (see #R$7577)

@ $7577 label=addon_bar_graphic
b $7577 Add-on 8: a small bar
D $7577 The add-ons (#R$AF95, drawn into the ship's sprite by #R$B09C) have a byte before them, the height the ship's sprite must have to show the add-on; then width, height and the picture bottom line first; then $FF, or a mask of the same size that #R$B0E4 ANDs on before the picture is ORed. 2 bytes by 4 lines, masked.
B $7577,2,2 Width in bytes, height in lines
B $7579,8,2 The lines, bottom first
B $7581,8,2 The mask
B $7589,1,1 Add-on 6's height byte

@ $758A label=addon_mound_graphic
b $758A Add-on 6: a small mound
D $758A 3 bytes by 6 lines, masked (see #R$7577 for the form).
B $758A,2,2 Width in bytes, height in lines
B $758C,18,3 The lines, bottom first
B $759E,19,3 The mask, then add-on 9's height byte

@ $75B1 label=addon_figure_graphic
b $75B1 Add-on 9: a small figure
D $75B1 2 bytes by 15 lines (see #R$7577 for the form). There is no $FF after the picture, so #R$B09C takes the next 30 bytes as its mask: the six below, then all of add-on 7 (#R$75D8: its height byte, size, picture and mask) and add-on 4's height byte. Whether that was meant is not known.
B $75B1,2,2 Width in bytes, height in lines
B $75B3,30,2 The lines, bottom first
B $75D1,7,2 The first six bytes of what is taken as its mask, then add-on 7's height byte

@ $75D8 label=addon_post_graphic
b $75D8 Add-on 7: a small post
D $75D8 2 bytes by 5 lines, masked (see #R$7577). These bytes also serve as the end of add-on 9's mask (#R$75B1).
B $75D8,2,2 Width in bytes, height in lines
B $75DA,10,2 The lines, bottom first
B $75E4,11,2 The mask, then add-on 4's height byte

@ $75EF label=addon_block_graphic
b $75EF Add-on 4: a small block
D $75EF 2 bytes by 14 lines, masked (see #R$7577).
B $75EF,2,2 Width in bytes, height in lines
B $75F1,28,2 The lines, bottom first
B $760D,29,2 The mask, then add-on 5's height byte

@ $762A label=addon_arches_graphic
b $762A Add-on 5: two arches
D $762A 4 bytes by 11 lines, masked (see #R$7577).
B $762A,2,2 Width in bytes, height in lines
B $762C,44,4 The lines, bottom first
B $7658,45,4 The mask, then add-on 1's height byte

@ $7685 label=addon_hook_graphic
b $7685 Add-on 1: a hook
D $7685 2 bytes by 23 lines, no mask (see #R$7577).
B $7685,2,2 Width in bytes, height in lines
B $7687,46,2 The lines, bottom first
B $76B5,2,2 $FF (no mask), then add-on 2's height byte

@ $76B7 label=addon_hook_b_graphic
b $76B7 Add-on 2: a hook, mirrored
D $76B7 2 bytes by 23 lines, no mask (see #R$7577).
B $76B7,2,2 Width in bytes, height in lines
B $76B9,46,2 The lines, bottom first
B $76E7,2,2 $FF (no mask), then add-on 3's height byte

@ $76E9 label=rocket_tank_graphic
b $76E9 Add-on 3 and rocket part 6: the ore tank
D $76E9 3 bytes by 18 lines. Add-on 3 (#R$AF95) and type $1E's frame 6 (the rocket part, empty). No $FF follows, so as an add-on it is masked with the 54 bytes from #R$7721 on: the ore rows and the first 18 bytes of #R$7745.
B $76E9,2,2 Width in bytes, height in lines
B $76EB,54,3 The lines, bottom first

@ $7721 label=ore_rows_graphic
b $7721 The ore in the tank
D $7721 Up to 18 rows of 2 bytes, bottom first: #R$A8A5 copies one row for each unit of ore collected (the ore count in #R$C891) into bytes 2 and 3 of the rows of the ship's sprite, so the tank fills as ore is picked up. The same bytes begin the mask #R$B09C uses for add-on 3 (#R$76E9).
B $7721,36,2 The rows, bottom first

@ $7745 label=rocket_tank_full_graphic
b $7745 Rocket part: the ore tank, full
D $7745 3 bytes by 18 lines, no mask, bottom line first. Type $1E's frame 8: part 6 once it holds its load of ore. Its first 18 bytes are also the end of add-on 3's mask.
B $7745,2,2 Width in bytes, height in lines
B $7747,54,3 The lines, bottom first
@ $777D label=fuel_flask_graphic
b $777D A flask
D $777D 3 bytes by 35 lines, no mask, bottom line first. Type $0D's frame 0 (the list in #R$AFAB).
B $777D,2,2 Width in bytes, height in lines
B $777F,105,3 The lines, bottom first
@ $77E8 label=pedestal_graphic
b $77E8 A pedestal
D $77E8 4 bytes by 23 lines, no mask, bottom line first. One of type $0D's frames (the list in #R$AFAB).
B $77E8,2,2 Width in bytes, height in lines
B $77EA,92,4 The lines, bottom first
@ $7846 label=puff_graphic
b $7846 The side jet, 16 pixels wide
D $7846 16 lines of 2 bytes, in the height-first form: no width byte. Graphic $0E, the first of the side jet's three flickering frames ($0E-$10, #R$C5FF); its entry in the per-type table (in #R$AF25) points here. #R$C7A3 reads the first byte as the height and the drawer is entered at a fixed width.
B $7846,1,1 Height in lines
B $7847,32,2 The lines
@ $7867 label=puff_b_graphic
b $7867 The side jet, 16 pixels wide, second frame
D $7867 15 lines of 2 bytes, in the height-first form: no width byte. Graphic $0F, the side jet (#R$C5FF); its entry in the per-type table points here.
B $7867,1,1 Height in lines
B $7868,30,2 The lines
@ $7886 label=puff_c_graphic
b $7886 The side jet, 16 pixels wide, third frame
D $7886 14 lines of 2 bytes, in the height-first form: no width byte. Graphic $10, the side jet (#R$C5FF); its entry in the per-type table points here.
B $7886,1,1 Height in lines
B $7887,28,2 The lines
@ $78A3 label=puff_wide_graphic
b $78A3 The lift jet while thrusting, 32 pixels wide
D $78A3 16 lines of 4 bytes, in the height-first form: no width byte. Graphic $11, the lift jet under the ship while it thrusts (#R$C6D2); its entry in the per-type table points here.
B $78A3,1,1 Height in lines
B $78A4,64,4 The lines
@ $78E4 label=puff_wide_b_graphic
b $78E4 The lift jet, 32 pixels wide
D $78E4 8 lines of 4 bytes, in the height-first form: no width byte. Graphic $12, the lift jet when the ship is not thrusting, drawn with its bottom line 8 higher than the thrusting one's, so that both hang from the same place (#R$C6D2); its entry in the per-type table points here.
B $78E4,1,1 Height in lines
B $78E5,32,4 The lines
@ $7905 label=spiky_mound_graphic
b $7905 A spiky mound
D $7905 5 bytes by 13 lines, no mask, bottom line first. One of type $0D's frames (the list in #R$AFAB).
B $7905,2,2 Width in bytes, height in lines
B $7907,65,5 The lines, bottom first
@ $7948 label=cloud_small_graphic
b $7948 The small cloud
D $7948 4 bytes by 12 lines, no mask, bottom line first. Type $13's frame 0.
B $7948,2,2 Width in bytes, height in lines
B $794A,48,4 The lines, bottom first
@ $797A label=cloud_big_graphic
b $797A The big cloud
D $797A 5 bytes by 24 lines, no mask, bottom line first. Type $13's frame 1.
B $797A,2,2 Width in bytes, height in lines
B $797C,120,5 The lines, bottom first
@ $79F4 label=rotor_graphic
b $79F4 A rotor craft
D $79F4 3 bytes by 17 lines, no mask, bottom line first. Type $14's frame 0.
B $79F4,2,2 Width in bytes, height in lines
B $79F6,51,3 The lines, bottom first
@ $7A29 label=rotor_b_graphic
b $7A29 A rotor craft, second frame
D $7A29 3 bytes by 17 lines, no mask, bottom line first. Type $14's frames 1 and 3.
B $7A29,2,2 Width in bytes, height in lines
B $7A2B,51,3 The lines, bottom first
@ $7A5E label=rotor_c_graphic
b $7A5E A rotor craft, third frame
D $7A5E 3 bytes by 17 lines, no mask, bottom line first. Type $14's frame 2.
B $7A5E,2,2 Width in bytes, height in lines
B $7A60,51,3 The lines, bottom first
@ $7A93 label=burst_small_graphic
b $7A93 A small burst
D $7A93 2 bytes by 14 lines, no mask, bottom line first. Type $15's frame 0.
B $7A93,2,2 Width in bytes, height in lines
B $7A95,28,2 The lines, bottom first
@ $7AB1 label=burst_small_b_graphic
b $7AB1 A small burst, second frame
D $7AB1 2 bytes by 14 lines, no mask, bottom line first. Type $15's frame 1.
B $7AB1,2,2 Width in bytes, height in lines
B $7AB3,28,2 The lines, bottom first
@ $7ACF label=burst_big_graphic
b $7ACF A big burst
D $7ACF 3 bytes by 21 lines, no mask, bottom line first. Type $15's frames 2 and 4.
B $7ACF,2,2 Width in bytes, height in lines
B $7AD1,63,3 The lines, bottom first
@ $7B10 label=burst_big_b_graphic
b $7B10 A big burst, second frame
D $7B10 3 bytes by 21 lines, no mask, bottom line first. Type $15's frames 3 and 5.
B $7B10,2,2 Width in bytes, height in lines
B $7B12,63,3 The lines, bottom first
@ $7B51 label=dome_graphic
b $7B51 A dome
D $7B51 3 bytes by 25 lines, no mask, bottom line first. Type $1A's frame 0.
B $7B51,2,2 Width in bytes, height in lines
B $7B53,75,3 The lines, bottom first
@ $7B9E label=dome_b_graphic
b $7B9E A dome, second frame
D $7B9E 3 bytes by 25 lines, no mask, bottom line first. Type $1A's frame 1.
B $7B9E,2,2 Width in bytes, height in lines
B $7BA0,75,3 The lines, bottom first
@ $7BEB label=dome_c_graphic
b $7BEB A dome, third frame
D $7BEB 3 bytes by 25 lines, no mask, bottom line first. Type $1A's frame 2.
B $7BEB,2,2 Width in bytes, height in lines
B $7BED,75,3 The lines, bottom first
@ $7C38 label=bullet_graphic
b $7C38 A bullet
D $7C38 2 bytes by 16 lines, no mask, bottom line first. Type $1C's frame 0; frames 0-2 animate the bullet.
B $7C38,2,2 Width in bytes, height in lines
B $7C3A,32,2 The lines, bottom first
@ $7C5A label=bullet_b_graphic
b $7C5A A bullet, second frame
D $7C5A 2 bytes by 16 lines, no mask, bottom line first. Type $1C's frame 1.
B $7C5A,2,2 Width in bytes, height in lines
B $7C5C,32,2 The lines, bottom first
@ $7C7C label=bullet_c_graphic
b $7C7C A bullet, third frame
D $7C7C 2 bytes by 16 lines, no mask, bottom line first. Type $1C's frame 2.
B $7C7C,2,2 Width in bytes, height in lines
B $7C7E,32,2 The lines, bottom first
@ $7C9E label=pellet_graphic
b $7C9E A pellet
D $7C9E 1 bytes by 8 lines, no mask, bottom line first. Type $1C's frame 4.
B $7C9E,2,2 Width in bytes, height in lines
B $7CA0,8,1 The lines, bottom first
@ $7CA8 label=refuel_pick_up_graphic
b $7CA8 The refuel pick-up
D $7CA8 1 bytes by 8 lines, no mask, bottom line first. Type $1C's frame 3.
B $7CA8,2,2 Width in bytes, height in lines
B $7CAA,8,1 The lines, bottom first
@ $7CB2 label=fuel_thief_graphic
b $7CB2 The fuel thief
D $7CB2 1 bytes by 7 lines, no mask, bottom line first. Type $1C's frame 6.
B $7CB2,2,2 Width in bytes, height in lines
B $7CB4,7,1 The lines, bottom first
@ $7CBB label=pellet_b_graphic
b $7CBB A tiny pellet
D $7CBB 1 bytes by 3 lines, no mask, bottom line first. Type $1C's frames 5 and 7.
B $7CBB,2,2 Width in bytes, height in lines
B $7CBD,3,1 The lines, bottom first
@ $7CC0 label=rock_graphic
b $7CC0 A tumbling rock
D $7CC0 2 bytes by 16 lines, no mask, bottom line first. Type $1D's frame 0; frames 0-5 turn it.
B $7CC0,2,2 Width in bytes, height in lines
B $7CC2,32,2 The lines, bottom first
@ $7CE2 label=rock_b_graphic
b $7CE2 A tumbling rock, frame 1
D $7CE2 2 bytes by 16 lines, no mask, bottom line first. Type $1D's frame 1.
B $7CE2,2,2 Width in bytes, height in lines
B $7CE4,32,2 The lines, bottom first
@ $7D04 label=rock_c_graphic
b $7D04 A tumbling rock, frame 2
D $7D04 2 bytes by 16 lines, no mask, bottom line first. Type $1D's frame 2.
B $7D04,2,2 Width in bytes, height in lines
B $7D06,32,2 The lines, bottom first
@ $7D26 label=rock_d_graphic
b $7D26 A tumbling rock, frame 3
D $7D26 2 bytes by 16 lines, no mask, bottom line first. Type $1D's frame 3.
B $7D26,2,2 Width in bytes, height in lines
B $7D28,32,2 The lines, bottom first
@ $7D48 label=rock_e_graphic
b $7D48 A tumbling rock, frame 4
D $7D48 2 bytes by 16 lines, no mask, bottom line first. Type $1D's frame 4.
B $7D48,2,2 Width in bytes, height in lines
B $7D4A,32,2 The lines, bottom first
@ $7D6A label=rock_f_graphic
b $7D6A A tumbling rock, frame 5
D $7D6A 2 bytes by 16 lines, no mask, bottom line first. Type $1D's frame 5.
B $7D6A,2,2 Width in bytes, height in lines
B $7D6C,32,2 The lines, bottom first
@ $7D8C label=comet_graphic
b $7D8C A comet
D $7D8C 3 bytes by 22 lines, no mask, bottom line first. Type $1D's frame 6.
B $7D8C,2,2 Width in bytes, height in lines
B $7D8E,66,3 The lines, bottom first
@ $7DD0 label=comet_b_graphic
b $7DD0 A comet, second frame
D $7DD0 3 bytes by 23 lines, no mask, bottom line first. Type $1D's frame 7.
B $7DD0,2,2 Width in bytes, height in lines
B $7DD2,69,3 The lines, bottom first
@ $7E17 label=debris_graphic
b $7E17 A heap of debris
D $7E17 3 bytes by 27 lines, no mask, bottom line first. One of type $0D's frames (the list in #R$AFAB).
B $7E17,2,2 Width in bytes, height in lines
B $7E19,81,3 The lines, bottom first
@ $7E6A label=small_craft_graphic
b $7E6A A small craft
D $7E6A 3 bytes by 13 lines, no mask, bottom line first. One of type $0D's frames (the list in #R$AFAB).
B $7E6A,2,2 Width in bytes, height in lines
B $7E6C,39,3 The lines, bottom first
@ $7E93 label=tough_attacker_graphic
b $7E93 The tough attacker
D $7E93 5 bytes by 12 lines, no mask, bottom line first. Type $19's frame 0.
B $7E93,2,2 Width in bytes, height in lines
B $7E95,60,5 The lines, bottom first
@ $7ED1 label=tough_attacker_b_graphic
b $7ED1 The tough attacker, second frame
D $7ED1 5 bytes by 12 lines, no mask, bottom line first. Type $19's frame 1.
B $7ED1,2,2 Width in bytes, height in lines
B $7ED3,60,5 The lines, bottom first
@ $7F0F label=eye_pod_graphic
b $7F0F An eye pod
D $7F0F 2 bytes by 14 lines, no mask, bottom line first. Type $17's frame 0.
B $7F0F,2,2 Width in bytes, height in lines
B $7F11,28,2 The lines, bottom first
@ $7F2D label=eye_pod_b_graphic
b $7F2D An eye pod, second frame
D $7F2D 2 bytes by 13 lines, no mask, bottom line first. Type $17's frame 1.
B $7F2D,2,2 Width in bytes, height in lines
B $7F2F,26,2 The lines, bottom first
@ $7F49 label=saucer_graphic
b $7F49 A saucer
D $7F49 3 bytes by 10 lines, no mask, bottom line first. Type $16's frame 0; frames 0-3 spin it.
B $7F49,2,2 Width in bytes, height in lines
B $7F4B,30,3 The lines, bottom first
@ $7F69 label=saucer_b_graphic
b $7F69 A saucer, frame 1
D $7F69 3 bytes by 10 lines, no mask, bottom line first. Type $16's frame 1.
B $7F69,2,2 Width in bytes, height in lines
B $7F6B,30,3 The lines, bottom first
@ $7F89 label=saucer_c_graphic
b $7F89 A saucer, frame 2
D $7F89 3 bytes by 10 lines, no mask, bottom line first. Type $16's frame 2.
B $7F89,2,2 Width in bytes, height in lines
B $7F8B,30,3 The lines, bottom first
@ $7FA9 label=saucer_d_graphic
b $7FA9 A saucer, frame 3
D $7FA9 3 bytes by 10 lines, no mask, bottom line first. Type $16's frame 3.
B $7FA9,2,2 Width in bytes, height in lines
B $7FAB,30,3 The lines, bottom first
@ $7FC9 label=pillar_graphic
b $7FC9 A pillar
D $7FC9 2 bytes by 18 lines, no mask, bottom line first. Type $18's frame 0.
B $7FC9,2,2 Width in bytes, height in lines
B $7FCB,36,2 The lines, bottom first
@ $7FEF label=pillar_b_graphic
b $7FEF An arch
D $7FEF 2 bytes by 18 lines, no mask, bottom line first. Type $18's frame 2.
B $7FEF,2,2 Width in bytes, height in lines
B $7FF1,36,2 The lines, bottom first
@ $8015 label=pillar_c_graphic
b $8015 A pillar, second frame
D $8015 2 bytes by 18 lines, no mask, bottom line first. Type $18's frames 1 and 3.
B $8015,2,2 Width in bytes, height in lines
B $8017,36,2 The lines, bottom first
@ $803B label=ring_graphic
b $803B The special beam, frame 0
D $803B The special beam's frames (#R$B414) are these four. 5 lines of 2 bytes, in the height-first form: no width byte. Entry 0 of the frame table at #R$B8CF.
B $803B,1,1 Height in lines
B $803C,10,2 The lines
@ $8046 label=ring_b_graphic
b $8046 The special beam, frame 1
D $8046 6 lines of 2 bytes, in the height-first form: no width byte. Entries 1 and 5 of the frame table at #R$B8CF.
B $8046,1,1 Height in lines
B $8047,12,2 The lines
@ $8053 label=ring_c_graphic
b $8053 The special beam, frame 2
D $8053 7 lines of 2 bytes, in the height-first form: no width byte. Entries 2 and 4 of the frame table at #R$B8CF.
B $8053,1,1 Height in lines
B $8054,14,2 The lines
@ $8062 label=ring_d_graphic
b $8062 The special beam, frame 3
D $8062 8 lines of 2 bytes, in the height-first form: no width byte. Entry 3 of the frame table at #R$B8CF.
B $8062,1,1 Height in lines
B $8063,16,2 The lines
@ $8073 label=debris_b_graphic
b $8073 More debris
D $8073 3 bytes by 27 lines, no mask, bottom line first. One of type $0D's frames (the list in #R$AFAB).
B $8073,2,2 Width in bytes, height in lines
B $8075,81,3 The lines, bottom first
@ $80C6 label=debris_c_graphic
b $80C6 More debris
D $80C6 3 bytes by 22 lines, no mask, bottom line first. One of type $0D's frames (the list in #R$AFAB).
B $80C6,2,2 Width in bytes, height in lines
B $80C8,66,3 The lines, bottom first
@ $810A label=small_craft_b_graphic
b $810A A small craft
D $810A 3 bytes by 13 lines, no mask, bottom line first. One of type $0D's frames (the list in #R$AFAB).
B $810A,2,2 Width in bytes, height in lines
B $810C,39,3 The lines, bottom first
@ $8133 label=cloud_craft_graphic
b $8133 A craft in a cloud
D $8133 5 bytes by 20 lines, no mask, bottom line first. One of type $0D's frames (the list in #R$AFAB).
B $8133,2,2 Width in bytes, height in lines
B $8135,100,5 The lines, bottom first
@ $8199 label=dome_robot_graphic
b $8199 A domed robot
D $8199 2 bytes by 15 lines, no mask, bottom line first. Type $1B's frame 2.
B $8199,2,2 Width in bytes, height in lines
B $819B,30,2 The lines, bottom first
@ $81B9 label=dome_robot_b_graphic
b $81B9 A domed robot, second frame
D $81B9 2 bytes by 15 lines, no mask, bottom line first. Type $1B's frame 3.
B $81B9,2,2 Width in bytes, height in lines
B $81BB,30,2 The lines, bottom first
@ $81D9 label=lamp_graphic
b $81D9 A lamp
D $81D9 2 bytes by 16 lines, no mask, bottom line first. Type $1B's frame 0.
B $81D9,2,2 Width in bytes, height in lines
B $81DB,32,2 The lines, bottom first
@ $81FB label=lamp_b_graphic
b $81FB A lamp, second frame
D $81FB 2 bytes by 16 lines, no mask, bottom line first. Type $1B's frame 1.
B $81FB,2,2 Width in bytes, height in lines
B $81FD,32,2 The lines, bottom first
@ $821D label=fuel_station_graphic
b $821D A fuel station
D $821D 3 bytes by 24 lines, no mask, bottom line first. Type $1B's frame 4.
B $821D,2,2 Width in bytes, height in lines
B $821F,72,3 The lines, bottom first
@ $8267 label=fuel_station_b_graphic
b $8267 A fuel station, second frame
D $8267 3 bytes by 24 lines, no mask, bottom line first. Type $1B's frame 5.
B $8267,2,2 Width in bytes, height in lines
B $8269,72,3 The lines, bottom first
@ $82B1 label=pylon_craft_graphic
b $82B1 A craft hanging from a pylon
D $82B1 5 bytes by 16 lines, no mask, bottom line first. One of type $0D's frames (the list in #R$AFAB).
B $82B1,2,2 Width in bytes, height in lines
B $82B3,80,5 The lines, bottom first
@ $8303 label=ringed_planet_graphic
b $8303 A ringed planet
D $8303 3 bytes by 22 lines, no mask, bottom line first. The last of type $0D's frames (the list in #R$AFAB).
B $8303,2,2 Width in bytes, height in lines
B $8305,66,3 The lines, bottom first

@ $8347 label=landscape_end_pieces
c $8347 Adjust a landscape run's start and width for its end pieces
D $8347 Called by #R$D9A8 (when the byte at #R$CE37 is 0) just before it draws a run of the landscape. #R$5C33 and #R$5C34 hold the codes of the run's first and last pieces (#R$CD6B sets them from the map); pieces $90-$93 are ends that need the run moved or widened, depending on the scroll step across (the second byte of #R$CCBA) and on E, which is 0 or $AA (#R$D9A8 sets DE to 0 or $55AA, the dither's phase). B is added to the run's x and C to its width.
D $8347 The width's base is the operand of the LD A,n near the end of this routine, which #R$D9A8 writes as its own width less one. The result goes to #R$5C24 and HL is left at the run's screen position from #R$BA8D with x moved.
D $8347 How the pieces look and why each case needs its adjustment is not yet worked out; a first piece of $93 never came up in the build's sessions.
R $8347 IX The landscape strip's record (nothing is done when +1 is 0)
R $8347 E 0 or $AA
R $8347 O:HL The run's screen position, x moved by B
R $8347 O:A Its width, also in #R$5C24
  $8347,5 Nothing for a strip whose +1 is 0
  $834C,12 The first and last pieces' codes; B and C from them (#R$83A1, #R$838B)
  $8358,14 First piece $91 with the last below $80 and E=0: one wider
  $8366,23 First piece $93: one wider when E=0, if the landscape scrolls this pass or #R$BA8D is not on a byte boundary
  $837D,6 The run's position, x moved by B
  $8383,8 Width = the base #R$D9A8 wrote into the operand + C

@ $838B label=last_piece_width
c $838B Widen a landscape run for its last piece
D $838B Part of #R$8347: one wider when the last piece (#R$5C34) is $93 and E is 0, or $92 and E is not 0.
R $838B E 0 or $AA
R $838B C The width so far
  $838B,12 Only pieces $92 and $93
  $8397,5 $92: one wider unless E=0
  $839C,5 $93: one wider when E=0

@ $83A1 label=first_piece_shift
c $83A1 Move a landscape run's start for its first piece
D $83A1 Part of #R$8347, for the first piece (#R$5C33). $90: B=7 when E=0; otherwise B is minus the scroll step across (the second byte of #R$CCBA) when that is positive, with the run one wider, and 0 when it is not. $91: B=7 unless E=0, when it is minus the scroll step. Other pieces leave B at 0.
D $83A1 L holds #R$5C33 itself here, so the AND 7 near the end always gives 0 for piece $90 and the run is always one wider on that path.
R $83A1 E 0 or $AA
R $83A1 O:B The shift in x
  $83A1,10 Only pieces $90 and $91
  $83AB,7 $91
  $83B2,5 $90 with E=0: 7
  $83B7,10 Otherwise 0 unless the scroll step is positive...
  $83C1,6 ...then one wider
  $83C7,7 And B is minus the scroll step

@ $83CE label=print_strings
c $83CE Print B strings
D $83CE Calls #R$A115 B times. Each string is x, line (its bottom), attribute, length and the characters (0-25 the letters, $1A-$23 the digits, $26 a space), and #R$A115 leaves DE at the next one, so a list of them prints in one call. Used by #R$83D6, #R$CA3F and the menu (#R$F26C).
R $83CE DE The first string
R $83CE B How many
  $83CE,8 Print one and move on

@ $83D6 label=planet_secured
c $83D6 Show the planet-secured screen, award the bonus, and move on to the next planet
D $83D6 Called by #R$F52A once the rocket has launched. Prints the four lines at #R$84A9 and the name of the planet just finished (one of five, #R$8459; +$12 of the current player's record, #R$F5E7, is its number) into #R$8505, then the four lines from #R$8515 with the next planet's name copied into #R$8527 -- after the fifth planet the first comes round again.
D $83D6 It then resets the rocket's base position (#R$96AC), sets the player's +$1A and +$1B to 6, and counts a bonus of ten times 5000 (BCD, the score adder in #R$917C) onto the score with a zap (#R$724C) and a pause after each. Last it deals the player's last pick-up place again (the second entry point of #R$6113, with IY at the dealing list's last entry and DE at the current player's last place, +$65 of #R$F5E7) and clears the player's own gone bits in the 290 world objects' kinds (#R$9A8A) with a mask worked out from the player in play (#R$CA1C): $7F for player 1 (bit 7), $BF for player 2 (bit 6).
  $83D6,8 The first four lines
  $83DE,20 Copy this planet's name (16 bytes) into #R$8505
  $83F2,15 After the last planet the next is the first (number $FF, made 0 below)
  $8401,7 Copy the next planet's name (15 bytes) into #R$8527
  $8408,6 Print this planet's name
  $840E,12 The rocket's base position
  $841A,7 Next planet
  $8421,5 The four lines from #R$8515
  $8426,8 The player's +$1A and +$1B to 6
  $842E,20 Ten times: 5000 points, a zap and a pause
  $8442,10 Deal one pick-up place again
  $844C,13 A mask from the player in play (#R$CA1C) for the world objects' kinds (#R$9A8A): $7F for player 1, $BF for player 2

@ $8459 label=planet_names
b $8459 The five planets' names
D $8459 Five names of 16 characters in the game's character codes (0-25 the letters, $1A-$23 the digits, $26 a space), centred with spaces, in the order the planets are played. #R$83D6 copies the finished planet's into #R$8505 and the next one's into #R$8527.
B $8459,80,16

@ $84A9 label=planet_secured_lines
b $84A9 The planet-secured screen's first four lines
D $84A9 Four strings for #R$83CE: x, line (bottom), attribute, length, then the characters (game codes, see #R$8459). Congratulations, in white, then three lines in yellow.
B $84A9,19,4,15
B $84BC,27,4,12,11
B $84D7,26,4,11,11
B $84F1,16,4,12

@ $8501 label=planet_secured_name
b $8501 The planet-secured screen's planet name
D $8501 The head of one string for #R$A115 (see #R$84A9): x, line, attribute (white) and length, 16. The characters are #R$8505.
B $8501,4,4

@ $8505 label=planet_secured_name_text
b $8505 The name of the planet just finished
D $8505 16 characters, which #R$83D6 copies from #R$8459 before printing #R$8501.
B $8505,16,16

@ $8515 label=next_planet_lines
b $8515 The planet-secured screen's last four lines
D $8515 Four strings for #R$83CE (see #R$84A9): a line saying where to go next, then the next planet's name in green, whose 15 characters are #R$8527, then the two lines at #R$8536.
B $8515,14,4,10 Where to go next
B $8523,4,4 The head of the next planet's name: x, line, attribute (green), length 15

@ $8527 label=next_planet_name_text
b $8527 The name of the next planet
D $8527 15 characters, which #R$83D6 copies from #R$8459 (the next name's first 15) before printing #R$8515.
B $8527,15,15

@ $8536 label=next_planet_lines_end
b $8536 The planet-secured screen's last two lines
D $8536 Two strings for #R$83CE (see #R$84A9), printed after #R$8527's line, finishing the sentence.
B $8536,16,4,12
B $8546,22,4,18

@ $855C label=spawn_point_masks
b $855C Which spawn points each tile allows
D $855C One byte for each tile number: bit n set allows spawn point n (#R$8605) in a map cell holding that tile. #R$89D3 takes the tile of the cell it will put an attacker in from the four tile bytes at #R$DC91 (the four cells the view overlaps, which #R$DF08 keeps from the map), and tries the allowed points starting from a random one. The table covers tiles $00-$A8; the map's one cell of tile $A9 reads its mask from the first byte of #R$8605, and $AA, which #R$DF08 puts in place of $3E during the fly-in (#R$5C3C bit 7), the second.
D $855C This is level data: a build-time generator should lay it out by tile number, with the tiles.
B $855C,169,16

@ $8605 label=spawn_points
b $8605 The eight spawn points
D $8605 Where in a screen #R$89D3 may put a new attacker: eight pairs of x (8-$E7 across the screen) and line ($18-$B7), copied to the record's +2 and +5. Which of them a screen allows is in #R$855C.
B $8605,16,2

@ $8615 label=menu_loop
c $8615 Run the menu until 0 is pressed
D $8615 Called by the menu (#R$F26C) after the title tune. Each pass: a new random number (#R$F23B), the pass counter (in #R$9974) up by one, the two players' control-method pointers moved (#R$8690), the one-or-two-player lines coloured (#R$8666, which flashes the chosen one), a pause of $18 x 255 loops (#R$A802), and then key 0 ends it; otherwise the menu's keys are read (#R$86B9) and round again.
D $8615 Like every keyboard read in the game, the port is selected with OUT ($FD) first.
  $8615,3 A random number
  $8618,7 Count the pass
  $861F,20 Move player 1's pointer, then player 2's
  $8633,12 Colour the two lines
  $863F,5 Pause
  $8644,9 Key 0 (row $EF, bit 0) ends the menu
  $864D,5 Otherwise read the other keys and loop

@ $8652 label=menu_show_players
c $8652 Colour the one-player and two-player lines
D $8652 Called by the menu (#R$F26C) before and after #R$8615. Sets bit 2 of the pass counter, so the chosen line is drawn white, and colours both lines.
  $8652,8 Bit 2 of the pass counter set: the chosen line white
  $865A,12 Both lines

@ $8666 label=colour_player_line
c $8666 Colour a one-or-two-player line
D $8666 Called by #R$8615 and #R$8652. Colours one line nine characters wide from the screen position in HL (line $2F for one player, $3F for two, x $70): bright magenta ($43), or bright white ($47) if it is the one chosen (#R$F2E2: 0 one player, 1 two) and bit 2 of the pass counter (in #R$9974) is set. In the menu loop the counter's bit 2 changes every four passes, so the chosen line flashes.
R $8666 HL Screen position (x, bottom line)
  $8666,9 Magenta unless the flash is on...
  $866F,18 ...and this is the chosen line: (line - $2F) / 16 is its number
  $8681,2 White
  $8683,10 Put the attribute into the patch and colour it (#R$C991)

@ $868D label=player_line_colour
b $868D The colour patch for a one-or-two-player line
D $868D For #R$C991: nine characters wide, one high, and the attribute, which #R$8666 writes before each use.
B $868D,3,3

@ $8690 label=move_method_arrow
c $8690 Move a player's control-method pointer one step and draw it
D $8690 Each player has a pointer on the menu (P1 from the left, P2 from the right) that slides to the line of the control method chosen. The line wanted is the method's entry in #R$8704; the pointer moves down one line a pass towards it and up four a pass, so it creeps down and snaps back up when the method wraps round from Interface II to Keyboard. It is drawn with #R$C96F, which writes the graphic over what is there: the blank lines at the graphic's foot and head rub out the trail.
R $8690 IX The player's pointer record (#R$8708 or #R$870B)
R $8690 DE The pointer's graphic (#R$870E or #R$874F)
  $8690,15 The line wanted against the line it is at
  $869F,9 Below where it is: one line down
  $86A8,8 Above: four lines up
  $86B0,9 Draw it at its x and line

@ $86B9 label=menu_keys
c $86B9 Read the menu's keys
D $86B9 A (row $FD, bit 0) chooses one player, B (row $7F, bit 4) two (#R$F2E2 = 0 or 1). Keys 1 and 2 (row $F7, bits 0 and 1) step player 1's and player 2's control method on through 0-3 (Keyboard, Kempston, Cursor, Interface II), but only once that player's pointer has reached the line of the method it has, so a held key steps once per arrival rather than once a pass.
D $86B9 The entry at #R$86E4 steps one player's method: IX the pointer record, B the key's bit.
  $86B9,13 A: one player
  $86C6,15 B: two players
  $86D5,9 Player 1 and key 1
  $86DE,6 Player 2 and key 2

@ $86E4 label=cycle_method
c $86E4 Step a player's control method
D $86E4 Called and fallen into by #R$86B9: IX the pointer record, B the key's bit in row $F7. Only once the pointer has reached the line of the method it has, and only while the key is pressed, the method goes on by one, 0-3.
R $86E4 IX The player's pointer record
R $86E4 B The key's bit in row $F7
  $86E4,14 Not while the pointer is still moving
  $86F2,8 The key not pressed: nothing
  $86FA,10 Next method, 0-3

@ $8704 label=method_lines
b $8704 The lines of the four control methods on the menu
D $8704 The screen line (bottom) each player's pointer goes to for control method 0 (Keyboard), 1 (Kempston), 2 (Cursor) and 3 (Interface II). Read by #R$8690 and #R$86B9.
B $8704,4,4

@ $8708 label=player1_pointer
b $8708 Player 1's control-method pointer
D $8708 Three bytes: the pointer's x, the line it is at, and player 1's control method (0-3), which #R$F3BD copies into the player record at a new game (+$1C of #R$F5E7 and #R$F650). Moved by #R$8690, stepped by #R$86B9.
B $8708,3,3

@ $870B label=player2_pointer
b $870B Player 2's control-method pointer
D $870B As #R$8708, for player 2, on the right of the screen.
B $870B,3,3

@ $870E label=pointer_p1_graphic
b $870E Player 1's pointer: an arrow to the right marked P1
D $870E 3 bytes by 21 lines, bottom line first (#R$C96F); four blank lines at the foot and one at the head rub out the trail as it moves up four or down one.
B $870E,2,2 Width in bytes, height in lines
B $8710,63,3 The lines, bottom first

@ $874F label=pointer_p2_graphic
b $874F Player 2's pointer: an arrow to the left marked P2
D $874F As #R$870E.
B $874F,2,2 Width in bytes, height in lines
B $8751,63,3 The lines, bottom first

@ $8790 label=spawn_countdown
g $8790 Count down to the next attacker
D $8790 #R$87AF counts it down each pass: at 7 a cloud may start (#R$8792), at 0 an attacker (#R$87E7), and it starts again from 8.
B $8790,1,1

@ $8791 label=attacker_records
g $8791 How many records attackers may use
D $8791 Always 4: #R$87E7 looks for a free record among the first four object records (#R$9974). Nothing writes it.
B $8791,1,1

@ $8792 label=spawn_cloud
c $8792 Start a cloud, when the view is in the sky
D $8792 Called by #R$87AF (when its count reaches 7) and by #R$8D42 (when the load is light). Only while the view's screen row (#R$CE58) is 3-9: looks for a free record among the two clouds' records, 7 and 8 of #R$9974 (#R$87F6), and puts a cloud (attacker kind 1, type $13) in it at a screen edge (#R$8A28, all four screens allowed).
  $8792,9 Only in screen rows 3-9
  $879B,10 A free record among records 7 and 8
  $87A5,10 Kind 1, any of the four screens

@ $87AF label=spawn_tick
c $87AF Count towards the next attacker, and run the meteor-shower timer
D $87AF Called by the play loop (#R$F440) once a pass. Nothing while the load (#R$8E2B) is 8 or more.
D $87AF The meteor-shower timer (#R$87F5): when it is 0, a shower starts on the passes when the random byte #R$9BCB is $6A and the low two bits of its second byte are 0 -- one pass in 1024 -- and lasts 128 passes, during which #R$89D3 puts rocks and comets near the ship instead of attackers.
D $87AF Every eighth pass (#R$8790 at 7) a cloud may start (#R$8792); at 0 the count starts again from 8 and the entry at #R$87E7 looks for a free record among the attackers' four (#R$8791) and fills it (#R$89D3). #R$8D42 also jumps to #R$87E7 when the load is light.
  $87AF,6 Not when the load is 8 or more
  $87B5,6 A shower running: count it down below
  $87BB,21 Start one at random: 128 passes
  $87D0,4 Count the shower down
  $87D4,12 Count the passes; at 7, a cloud
  $87E0,7 At 0, from 8 again, and an attacker

@ $87E7 label=spawn_attacker
c $87E7 Start an attacker if one of their records is free
D $87E7 Fallen into from #R$87AF every eighth pass, and jumped to by #R$8D42 when the load is light. Looks for a free record among the first four (#R$8791) and fills it (#R$89D3).
  $87E7,14 A free record among the first four: fill it

@ $87F5 label=meteor_shower
g $87F5 The meteor-shower timer
D $87F5 0 none; otherwise the passes left (from 128) of a meteor shower (#R$87AF), during which #R$89D3 aims rocks and comets near the ship. Cleared by #R$F311.
B $87F5,1,1

@ $87F6 label=find_free_record
c $87F6 Find a free object record
D $87F6 Looks along B records of 24 bytes from IX for one whose type (+0) is $FF. Gives up at once while the load (#R$8E2B) is 7 or more or the ship is dying (#R$8F53 not 0).
R $87F6 A How many records to look at
R $87F6 IX The first
R $87F6 O:F Z set if one was found
R $87F6 O:IX The free record
R $87F6 O:DE $0018 when one was found (#R$89D3 relies on D being 0)
  $87F6,14 None when the load is 7 or more, or while dying
  $8804,12 Find one with type $FF
  $8810,3 None: NZ

@ $8813 label=attacker_fires
c $8813 Let an attacker fire, now and then
D $8813 Called by the update routines #R$93F2 and #R$94A8 with the kind of shot in #R$5C1C (7 or 8: a horizontal shot right or left, see #R$89A7). Only when the attacker was drawn last pass (#R$A1D7), and then one pass in 32 at random (#R$9BCB AND $2F zero): see #R$882B.
R $8813 IX The attacker's record
  $8813,13 Drawn last pass, and a random chance

@ $8820 label=ground_object_fires
c $8820 Let a ground object fire or throw something
D $8820 Called by #R$AC60 for each ground object whose +$18 bits 1-3 give a kind of shot (1-7, in #R$5C1C). One pass in 16 at random (#R$9BCB AND $5A zero), and only when the object is on the screen (+$10 bit 7).
D $8820 #R$882B, also used by attackers (#R$8813), fires the shot. It needs a free record among the three for shots, 4-6 of #R$9974, and the shooter between x $18 and $BF on the screen; the kind's flags (#R$89A7) may also want it in the top or bottom part of the screen. The new record is a type $1C object at the shooter's place, given the kind's template (#R$89AF), its colour, and then moved once by the template's numbers (#R$BF66), which puts the shot at the gun's mouth. Then its real velocity is set by the frame it has:
D $8820 Frame 0 (kind 1, a bullet thrown up): a random spray upwards (the spray code in #R$882B) that gravity brings down (Y acceleration $0020); one throw in eight is the shield ball (frame 9) instead, and every (lives x 4)th throw is the extra-life ship icon (frame 8, counted by #R$896E) -- so the fewer lives the player has, the more often extra lives come up. Frames 5 and 6 (kinds 4 and 5): a random spray upwards. Frame 7 (kind 6): the same, downwards when the shooter is in the upper part of the screen (#R$8970). Frame 10 (kinds 7 and 8, the attackers' shots): straight across at 6 pixels a pass, right for kind 7 and left for 8. Any other frame (kinds 2 and 3, the refuel pick-up thrown up and a pellet dropped): half the shooter's X velocity and 5 pixels a pass up, or down when the kind's flags have bit 7. A shot is sounded (#R$7311) unless the spray came to nothing.
R $8820 IX The ground object's record (26 bytes, #R$A80B)
  $8820,6 One pass in 16
  $8826,5 Only while on the screen

@ $882B label=fire_from
c $882B Fire a shot from an object
D $882B Fallen into from #R$8820 (ground objects) and jumped to from #R$8813 (attackers), with the kind of shot in #R$5C1C. See #R$8820 for what each kind does.
R $882B IX The shooter's record
  $882B,18 A free record among 4-6, as IY
  $883D,9 The shooter between x $18 and $BF
@ $8849 nowarn
  $8846,13 The kind's flags (#R$89A7) to #R$5C1D
  $8853,10 Bit 7: only from above line $58
  $885D,7 Bit 6: only from line $50 down
  $8864,6 The new record at the shooter's place, cleared
@ $8872 nowarn
  $886A,38 Type $1C; +$10 = $20 (shot, top speed 1); the template's four bytes to +7, +9, +$13, +$14
  $8890,14 Its colour: the flags' low nibble in both halves of +$0D
  $889E,7 +$15 = $38; move it by the template's numbers (#R$BF66), which places it
  $88A5,8 IX the shooter again, IY the shot
  $88AD,28 By the shot's frame
  $88C9,16 Others: X velocity half the shooter's...
  $88D9,15 ...and Y velocity 5 up, or down for flags bit 7
  $88E8,8 Sound it, unless it was freed
  $88F0,29 Frame 10: 6 pixels a pass across, right for kind 7, left otherwise
  $890D,12 Frames 5 and 6, and the others' start: Y velocity 0, -2, -4 or -6 at random...
  $8919,21 ...X velocity -6 to +6 from the random byte's top three bits; 7 there, or no velocity at all, frees it
  $892E,6 Free it
  $8934,9 Frame 0: the spray; none frees it
  $893D,10 One in eight: frame 9, the shield ball
  $8947,11 Top speed 6, still a shot
  $8952,21 Every (lives x 4)th: frame 8, the extra life
  $8967,7 Gravity: Y acceleration $0020

@ $896E label=extra_life_countdown
g $896E Throws left before the next extra life
D $896E Counted down by #R$8820 at each bullet a ground object throws (kind 1); at 0 that throw is the extra-life icon and the count starts again from the current lives x 4.
B $896E,1,1

@ $896F label=shield_timer
g $896F The shield timer
D $896F 0 off; set to $FF when the ship touches the shield ball (#R$8E2D), counted down every other pass by #R$C374. While it is not zero the ship takes no damage (#R$8F54); the ship flashes in its last $20 (#R$F1BD). Cleared at a new game.
B $896F,1,1

@ $8970 label=fire_spray_down
c $8970 Fire a spray of shots downwards from high up
D $8970 Part of #R$882B, for frame 7 (kind 6), jumped to from its test of the frame. sna2ctl took these bytes for data, since no session ran them: they call #R$882B's random spray, then, if the shooter is above line $67 on the screen, its Y velocity turned round so the spray goes down. Then back to the sound near the end of #R$882B.
R $8970 IX The shooter
R $8970 IY The shot
  $8970,3 The random spray
  $8973,8 Shooter at line $67 or below: as it is
  $897B,8 Higher: downwards
  $8983,3 Sound it

@ $8986 label=swap_to_shot
c $8986 Swap IX and IY, and copy the position across
D $8986 Used by #R$8820 to put the new shot at the shooter. #R$898E then copies the screen column and pixel (+1, +2) and the screen row and line (+4, +5) of the record at IY into the record at IX, leaving the fractions; #R$89D3 and #R$8D29 use it to start something at the ship.
R $8986 IX The shooter
R $8986 IY The new record
  $8986,8 Swap them: IX the new record

@ $898E label=copy_position
c $898E Copy a record's place to another
D $898E Fallen into from #R$8986, and called by #R$8A28 and #R$8D29: copies the screen column and pixel (+1, +2) and the screen row and line (+4, +5) of the record at IY into the record at IX, leaving the fractions.
R $898E IX The record to place
R $898E IY The record whose place it takes
  $898E,25 X and Y, without the fractions

@ $89A7 label=shot_kind_flags
b $89A7 Flags for the eight kinds of shot
D $89A7 One byte for each of kinds 1-8 (#R$882B reads the byte before this table plus the kind): bit 7, only from a shooter above line $58 (and, for the frames with no velocity of their own, fire downwards); bit 6, only from line $50 down; low nibble the colour, in both halves of +$0D. Kinds 1 and 2 bright yellow, from low down; 3 bright cyan, from high up; 4 and 5 bright white, from low down; 6 bright cyan; 7 and 8 bright white.
B $89A7,8,1

@ $89AF label=shot_kind_templates
b $89AF Templates for the eight kinds of shot
D $89AF Four bytes for each of kinds 1-8 (#R$882B reads four bytes on per kind from the fifth byte of #R$89A7): the gun's mouth as an X and Y offset (put in +7 and +9 for one move by #R$BF66, then replaced), the frame byte (+$13: low nibble the frame of type $1C, high nibble its timing) and the frame range (+$14).
D $89AF Kind 1 frames 0-2 (the bullet), 2 frame 3 (the refuel pick-up), 3 frame 4, 4 frame 5, 5 frame 6 (the fuel thief), 6 frame 7, 7 and 8 frame 10 (the dash at #R$89CF), kind 7 from 32 pixels to the right of the attacker.
B $89AF,32,4

@ $89CF label=dash_graphic
b $89CF The attackers' shot: a dash
D $89CF Type $1C's frame 10: 1 byte by 1 line, eight pixels across. Fired across the screen by kinds 7 and 8 (#R$8820).
B $89CF,2,2 Width in bytes, height in lines
B $89D1,1,1 The line

@ $89D2 label=attacker_kind
g $89D2 The kind of attacker being started
D $89D2 0-9, an entry of the wave table #R$990A: set by #R$89D3 (from the wave counter there) and #R$8792 (1, a cloud), and 8 or 9 for the meteor shower's rocks and comets.
B $89D2,1,1

@ $89D3 label=start_attacker
@ $8A62 label=start_in_screen
c $89D3 Start an attacker in a free record
D $89D3 Called by #R$87AF with IX a free record among the first four. The kinds of attacker are taken in turn (the wave counter #R$9932 counts round 0-5, or 0-7 once +$0A and +$0B of the player's record, #R$F5E7, are both set); kind 4, the tough attacker, is usually turned into kind 3 (unless the refresh register's bits $32 are all 0), and kinds 1 and 5 (clouds) become kind 0 outside screen rows 3-9. While a meteor shower is on (#R$87F5) and the view is above screen row $0B, a rock or comet starts near the ship instead (at the end of #R$8A28).
D $89D3 #R$8A28 chooses where. The view overlaps four screens: its own (#R$CE57, #R$CE58), the one to its right (#R$DDF7), the one below and the one right and below; bit 1 of #R$5C1C picks right, bit 0 below. B says which bits may be chosen at random, C which are forced: when the ship moves fast across (the high byte of its speed across, +$19 of its record in #R$C891, not 0 or $FF), the screen to the right if the scroll step across (the second byte of #R$CCBA) is negative and the view's own column if not; likewise in Y with its speed down (+$1B) and the first byte of #R$CCBA (the screen below when that is negative). Up to four screens are tried in turn (#R$8C04).
D $89D3 Then one screen is tried: the screen's tile (its byte in #R$DC91) gives a mask of allowed spawn points (#R$855C); a random start point (the instruction shown as RLC B in #R$8A28 is rewritten to BIT n,A) is followed round the mask to the first allowed one (#R$8605), which sets the record's +2 and +5. The record is cleared (#R$AC34), given the kind's four bytes from the wave table #R$990A (type, +$10, +$13, +$14) and a colour ($FF, or $77 now and then; for most types one of the eight colours in #R$9933, the first four only in screen rows 4-11), and put in the chosen screen's column and row. If it would be in view now (#R$ADD8 sets +$10 bit 7) it is freed and the next screen tried; otherwise it is turned towards the view (#R$8C67).
D $89D3 #R$ADD8 is given DE pointing at the screen's kind's byte in the ROM's first bytes ($0000-$0003, D being 0), not at a graphic, so the size it tests with is not the attacker's: a large one. Whether that is meant is not known; it keeps attackers from starting near the view.
D $89D3 A cloud (type $13) takes frame 0 or, one in eight, the big cloud; in screen rows 0-4 it is put at line $1F of row 4 instead, level with the view's x, and not tested. Kinds 8 and 9 (type $1D) move 2 or 4 pixels a pass each way, right in the view's own column and left in the next.
R $89D3 IX The free record
  $89D3,16 Six kinds, or eight
  $89E3,14 The next kind in turn
  $89F1,13 Kind 4 mostly becomes 3
  $89FE,26 Clouds only in screen rows 3-9; elsewhere kind 0
  $8A18,14 A meteor shower above row $0B
  $8A26,2 Any screen

@ $8A28 label=start_at_edge
c $8A28 Start an attacker at a screen near the view
D $8A28 Fallen into from #R$89D3, and jumped to by #R$8792 for a cloud. Chooses one of the four screens the view overlaps, then a spawn point in it, fills the record, and gives up on a screen where it would be seen: see #R$89D3.
  $8A28,26 Moving fast across: the screen ahead in X
  $8A42,22 Moving fast up or down: the screen ahead in Y
  $8A58,10 Four tries; the screen at random within B, forced by C
  $8A62,18 The screen's tile gives the allowed points (#R$855C)
  $8A74,19 A random point to start from; the rewritten BIT below tests it
  $8A87,28 Round the eight points to an allowed one; none: next screen
  $8AA3,26 The point's x and line (#R$8605)
  $8ABD,15 Colour $FF, or $77 one time in four
  $8ACC,45 Clear the record and fill it from the wave table (#R$990A)
  $8AF9,28 In the chosen screen's column and row
  $8B15,25 A cloud: frame 0, or 1 now and then; screen rows 0-4 below
  $8B2E,42 Row 4, line $1F, level with the view
  $8B58,29 Others: a colour from #R$9933
  $8B75,13 In view: free it...
  $8B82,17 ...and try the next screen
  $8B93,3 Turn it towards the view
  $8B96,5 Free it
  $8B9B,39 Meteor shower: at the ship, moved once by an X offset of -$30 to +$48 and a Y offset of $10 less the ship's +$1E (its line on the screen)
  $8BC2,15 A comet (kind 9) in the view's own column, a rock (8) otherwise
  $8BD1,28 Type $1D: 2 or 4 pixels a pass down, 2 or 4 right...
  $8BED,22 ...or left, outside the view's own column

@ $8C03 label=speed_limit
g $8C03 The speed limit while accelerating
D $8C03 Set by #R$8C05 from the record's top speed, read by #R$8C3F.
B $8C03,1,1

@ $8C04 label=speed_limit_down
g $8C04 The negative speed limit; the spawn's tries
D $8C04 Set by #R$8C05 to minus the top speed, minus one, and read by #R$8C3F. #R$89D3 also borrows it to count the screens it tries.
B $8C04,1,1

@ $8C05 label=accelerate
c $8C05 Add an object's acceleration to its velocity, within its top speed
D $8C05 Called by the update routines #R$938D, #R$93F2, #R$9457, #R$94A8 and #R$9507. Velocity (+7 +8 in X, +9 +A in Y) and acceleration (+B +C, +E +F) are signed 8.8 numbers, high byte first. The top speed is (+$10 AND 7) + 1 whole pixels a pass; a velocity that goes past it is set to exactly that (#R$8C3F).
R $8C05 IX The object
  $8C05,13 The limits, n and -(n + 1)
  $8C12,22 X velocity plus X acceleration, limited
  $8C28,23 Y velocity plus Y acceleration, limited

@ $8C3F label=limit_speed
c $8C3F Keep a velocity within the speed limit
D $8C3F A positive velocity of more than n.0 becomes n.0; a negative one below -n becomes -n.0 (n from #R$8C03).
R $8C3F HL The velocity
R $8C3F O:HL The velocity, limited
  $8C3F,15 Positive: no more than n
  $8C4E,10 Negative: no less than -n

@ $8C58 label=steer_to_view
c $8C58 Turn an object that is out of view back towards it
D $8C58 Jumped to by #R$90EC. Not for types $1D and $1E, nor while the object is in view (#R$5C31, its +$10 as last drawn, bit 7). Otherwise it runs on into #R$8C67, which turns it.
R $8C58 IX The object
  $8C58,9 Not types $1D, $1E
  $8C61,6 Not while in view

@ $8C67 label=head_for_view
c $8C67 Turn an object towards the view
D $8C67 Fallen into from #R$8C58, and jumped to by #R$8A28 for a new attacker. Stops the object and sets its acceleration: $20 (an eighth of a pixel a pass, each pass) to the right if it is in the view's own screen column, otherwise to the left; down if it is in the view's screen row above the view's top line; up if it is in another screen row below that line; otherwise none in Y. (The view is one screen in size, so it covers the part of its own screen from that line down and the part of the screen below above it.)
  $8C67,24 Accelerate right in the view's column, left in the next
  $8C7F,13 Stop it
  $8C8C,11 Its screen row against the view's
  $8C97,13 The view's row, above the view: down
  $8CA4,13 The row below, beneath the view: up

@ $8CB1 label=last_pass_contact
g $8CB1 Last pass's cloud-contact flag
D $8CB1 #R$8D42 copies #R$5C40 here each pass before clearing it; #R$5C40 is set when a cloud touches what the ship carries (#R$8E2D). While it is set #R$8F1E does nothing.
B $8CB1,1,1

@ $8CB2 label=wreck_ship
c $8CB2 Break the ship up
D $8CB2 Called by #R$8D42 when the death byte (#R$8F53) reaches 10. Fills all nine object records (#R$9974): the first four as debris (type $15, made by the second entry point of #R$9035) 28 pixels to the right of the ship and above it by half the ship sprite's height (#R$C1A9), +$15 0, $40, $80 and $C0 so that each piece takes a different part of the debris path; the other five as type $1C bullets (frame 0) at the same place (+$14 = 2, frames 0-2, which also marks them as pieces of the wreck), thrown out with the velocities at #R$8D1F and pulled down by gravity (Y acceleration $0020).
  $8CB2,21 Four records from the first; the offset above the ship
  $8CC7,7 At the ship (#R$8D29); debris (type $15)
  $8CCE,19 Colour white, path phase C, next
  $8CE1,7 Five more, at the ship
  $8CE8,24 Type $1C, frame 0, top speed 7, wreck piece, colour yellow
  $8D00,17 Velocity from #R$8D1F
  $8D11,13 Gravity; next
  $8D1E,1 Done

@ $8D1F label=wreck_velocities
b $8D1F Velocities of the five pieces of the ship's wreck
D $8D1F X and Y (high bytes, pixels a pass) for #R$8CB2: two to the left, one straight up, two to the right, all upwards.
B $8D1F,10,2

@ $8D29 label=place_at_ship
c $8D29 Put a record at the ship, offset
D $8D29 Clears the record (#R$AC34), copies the ship's place into it (#R$898E with IY the ship's record), and moves it once by 28 pixels in X and #R$5C1D in Y (#R$BF66), using the velocity as the offset.
R $8D29 IX The record
R $8D29 IY The ship's record (#R$C8E5)
  $8D29,6 Clear it; at the ship
  $8D2F,13 Moved by $1C across, #R$5C1D down

@ $8D3C label=rocket_parts_load
g $8D3C The rocket parts' share of the load
D $8D3C Half the number of rocket parts delivered, rounded up, while #R$9572 is drawing them, else 0. #R$8D42 starts each pass's load (#R$8E2B) from it.
B $8D3C,1,1

@ $8D3D label=skip_free_record
c $8D3D Skip a free record in the object loop
D $8D3D Jumped to by #R$8D42 for a record of type $FF: drop the record pointer it pushed and go on to the next record.
  $8D3D,5 Restore IX and go on
# --------------------------------------------------------------------------
# Agent 3: $8D42-$A0DA -- the object update loop and its contact effects,
# shots against objects, the type handlers and their steering, scoring, the
# rocket parts and the rocket, the debris path and the frame lists, the
# object records, the start, the tune player, the random number, the
# flickering beams, box and slope tests, pause, the screen wipes and the font.
#
# THE OBJECT RECORD (24 bytes; the nine at #R$9974, the rocket's drawing
# record at $9A4C, the ship's own at $C8E5 and the player's homing missiles
# at $B37A share the layout, as far as the code here uses it):
#   +0 type ($FF free; $13-$1E, which also picks the frame list in the table at offset 24 of #R$AF25)
#   +1 +2 +3 X: the page column (0-$5F, wrapping), the pixel in it
#      ($08-$E7: a page, the size of the play area, is 224 pixels wide) and a fraction
#   +4 +5 +6 Y: the page row, the pixel in it ($18-$B7: 160 lines) and a
#      fraction; Y grows downwards
#   +7 +8 X velocity, +9 +A Y velocity: signed 8.8 pixels a pass, high byte
#      first (#R$BF66 adds them)
#   +B +C X acceleration, +E +F Y acceleration, the same form (#R$8C05)
#   +D two colours: low nibble on odd passes, high nibble on even (bits 0-2
#      / 4-6 ink, bit 3 / 7 BRIGHT), so a sprite can flash (#R$AD48)
#   +10 flags: bits 0-2 top speed - 1 (#R$8C05); bit 3 skip one placing
#      (#R$90EC); bit 4 to be freed; bit 5 shot; bit 6 straddles the left
#      edge of the view; bit 7 drawn
#   +11 +12 where it was drawn: screen x and bottom line
#   +13 frame: low nibble the frame in the type's list; bits 4-5 a count
#      down to the next frame, bits 6-7 what it is reloaded with (#R$910A)
#   +14 the frame range: high nibble the first frame, low nibble the last
#   +15 +16 the type's own: a timer, a path step, a hit count...
#   +17 high nibble a count down after touching the ship (#R$8F54); on a
#      homing missile the target's record number, $F = none (#R$9307);
#      bit 3 exploding, bits 0-2 the explosion's frame (#R$AD48)
# --------------------------------------------------------------------------

@ $8D42 label=update_objects
@ $8DFA label=next_object
c $8D42 Update the nine object records, once a pass
D $8D42 Called from the play loop (#R$F440) once a pass, and the most expensive thing in it: for each of the nine records at #R$9974 that is not free it rubs out last pass's picture, runs the type's update routine through #R$A18D (which moves, animates and redraws it), tests it against the ship (#R$8E2D) and against the player's shots (#R$917C). It also keeps the death byte (#R$8F53) counting, and at the end starts a new cloud or attacker when the load (#R$8E2B) is light.
D $8D42 The load is the throttle on spawning: one for every record in use, one more for each that was on the screen last pass, one more for a big cloud, and half the number of rocket parts delivered (#R$8D3C), since #R$9572 draws those in the same pass. Below 4 this routine spawns; #R$87AF stops at 8 and #R$87F6 at 7.
  $8D42,10 Count the death byte up once a pass while it is not zero
  $8D4C,5 At 10 the ship breaks up into nine pieces (#R$8CB2)
  $8D51,8 From 10 on, the death sound (#R$72AB)
  $8D59,13 Keep last pass's contact flag (#R$8CB1) and clear it for this pass
  $8D66,6 The load starts at the rocket parts' share (#R$8D3C)
  $8D6C,6 Nine records
  $8D72,10 A free record (type $FF) is skipped (#R$8D3D)
  $8D7C,19 Count the contact cool-down in the high nibble of +$17 down by one
  $8D8F,14 While the ship is beginning to die (death byte 1-3) every object explodes
  $8D9D,5 The default contact effect: damage and push ($50, see #R$8E2D)
  $8DA2,7 Count the record in the load
  $8DA9,3 No sprite sizes yet this pass (#R$A2EA)
  $8DAC,7 Drawn last pass: count it again and rub it out (#R$8E21)
  $8DB3,4 Clear the straddling flag; placing it sets it again
  $8DB7,1 The update routines run in the other register set
  $8DB8,3 The type's update routine (#R$A18D)
  $8DBB,3 Contact with the ship (#R$8E2D)
  $8DBE,19 Clouds (type $13), type $1D and type $1C...
  $8DD1,7 ...but not a piece of the ship's wreck (+$14 = 2)...
  $8DD8,16 ...are freed once they have left the view: drawn last pass and not this one (the two heights in #R$A1D3)
  $8DE8,12 Shot already, or exploding: no shot test
  $8DF4,6 Its box (#R$9143) against the player's shots (#R$917C)
  $8DFA,10 Next record
  $8E04,6 A load of 4 or more: nothing new this pass
  $8E0A,20 Half the time, while the view is in page rows 3-10, a cloud (#R$8792, which makes one only in rows 3-9)
  $8E1E,3 Otherwise an attacker from the wave table (the entry point in #R$87AF)

@ $8E21 label=count_and_erase
c $8E21 Count a drawn object in the load again and rub it out
D $8E21 Used by #R$8D42 for an object that was drawn last pass (bit 7 of +$10): an object on the screen weighs two in the load (#R$8E2B). Then rubs out its old picture (#R$AD27), which also clears bit 7.
  $8E21,7 One more in the load
  $8E28,3 Rub out last pass's picture

@ $8E2B label=object_load
g $8E2B The load
D $8E2B Worked out afresh each pass by #R$8D42: the rocket parts' share (#R$8D3C), one for each record in use, one more for each drawn last pass (#R$8E21) and one more for a big cloud (#R$93F2). The spawners read it: #R$8D42 spawns below 4, #R$87AF not at 8 or more, #R$87F6 not at 7 or more.

@ $8E2C label=contact_effect
g $8E2C The current object's contact effect
D $8E2C What the current object does to the ship when they touch, one bit per effect: set to $50 for each object by #R$8D42, changed by its update routine, and acted on by #R$8E2D. Bit 7 slows the ship (#R$8F1E), 6 damages it (#R$8F54), 5 refuels (#R$8FC4), 4 pushes (#R$8FCA), 3 collects the object (#R$900B), 2 drains fuel (#R$9015), 1 gives a life (#R$9020), 0 destroys the object (#R$9030); $FF is a shield, and 0 is harmless.

@ $8E2D label=ship_contact
c $8E2D Test the current object against the ship and apply its contact effect
D $8E2D Called by #R$8D42 after each object's update. Nothing happens while the rocket is launching (#R$96AB), while the ship is dying (#R$8F53), when the object is harmless (contact effect 0, #R$8E2B), when it was not drawn this pass, or when it is exploding. Its box -- the screen x and bottom line it was drawn at (+$11, +$12), the width (#R$5C29) and height (in #R$A1D3) it was drawn with -- goes to #R$ABA4, and an object whose x is outside $28-$8D is too far from the ship to touch it. The ship's box is fixed in x: 40 pixels wide from x=100, 16 lines high, its bottom 8 lines below the ship's line (#R$5C38). #R$9DB1 tests the two.
D $8E2D On a touch the effect bits are acted on from bit 7 down (see #R$8E2B), IX the object and IY the ship's record (in #R$C891). $FF is different: it starts the shield (#R$896F = $FF, counted down every other pass by #R$C374, so about 25 seconds), and frees the object with a sound.
D $8E2D Without a touch, a cloud may still touch what the ship is carrying (#R$C1CE keeps a flag in the player record, #R$F5E7, while it carries something): the carried thing's box (from #R$C279) is tested, and on a touch the ship's X velocity becomes minus half the cloud's, and #R$5C40 is set. That branch never ran in the build's sessions; it rests on reading alone.
  $8E2D,20 Nothing during the launch or while dying, for a harmless object, or for one not drawn this pass
  $8E41,9 Nor while it explodes
  $8E4A,20 Its box at #R$ABA4: x and bottom line; too far left or right of the ship to touch
  $8E5E,12 Width (the height went in above)
  $8E6A,15 The ship's box: x=100, 40 wide, 16 high, bottom at the ship's line + 8
  $8E79,15 IY the ship's record; no touch: the cloud test below
  $8E88,5 Touched: the ship is to be redrawn (a flag, #R$D0BC, read by #R$C3E3)
  $8E8D,7 The effect, $FF the shield
  $8E94,11 The shield (#R$896F) counts down from $FF; the object is freed, with a sound
  $8E9F,25 Slow, damage, refuel, push, collect
  $8EB8,12 Drain fuel; an extra life
  $8EC4,6 And destroy the object
  $8ECA,11 No touch: only a cloud, and only while the ship carries something
  $8ED5,9 Only when the ship faces the way the cloud moves (#R$C8FD)
  $8EDE,25 Test the carried thing's box against the cloud
  $8EF7,10 Touched
  $8F01,23 The ship's X velocity becomes minus half the cloud's
  $8F18,6 Note it for the fuel burn (#R$B115) and for the slowing (#R$8F1E)

@ $8F1E label=contact_slow_ship
c $8F1E Contact effect bit 7: halve the ship's velocity
D $8F1E A cloud's effect ($80). Halves each component of the ship's velocity (the words at +$19 and +$1B of its record) that has the same sign as the object's velocity in that axis, so flying through a cloud is slow. Not done in a pass after the carried thing was pushed by a cloud (#R$8CB1).
R $8F1E IX The object
R $8F1E IY The ship's record (#R$C8E5)
  $8F1E,5 Not after a push last pass
  $8F23,24 X: halve it when the signs agree
  $8F3B,23 Y: the same

@ $8F53 label=death_count
g $8F53 The death byte
D $8F53 0 while the ship is alive. A third hit, from an attacker or a beam (#R$8F54), or an empty fuel gauge (#R$CC63) sets it to 1, and #R$8D42 counts it up by one a pass. 1-3: every object explodes (#R$8D42). 10: the ship breaks up into pieces (#R$8CB2). 12 and over: the play loop runs the death sequence (#R$F440), which ends at $50. While it is not zero nothing touches the ship (#R$8E2D) and nothing new is spawned (#R$87F6).
D $8F53 #R$9572 sets it to 10 for the length of two calls when the ship docks with the finished rocket, and puts it back to 0 at once: that is not a death.

@ $8F54 label=contact_damage
@ $8F76 label=damage_ship
c $8F54 Contact effect bit 6: damage the ship
D $8F54 The attackers' effect. An object damages the ship at most once every 16 passes: it sets the cool-down in the high nibble of its +$17 to 15 (#R$8D42 counts it down) and does nothing while it is not zero. With the shield up (#R$896F) an ordinary attacker (effect $50 or $51) is destroyed instead, with a sound.
D $8F54 damage_ship (the entry point at the middle of this routine), reached also from a beam (#R$9D0E) and from #R$A8F4, does nothing with the shield up or while the ship is already dying. Otherwise it counts the hit (the last byte of #R$8FBB) and recolours the ship icon on the panel: yellow ($46) after the first hit, magenta ($43) after the second, and black after the third, which sets the death byte (#R$8F53) to 1. It is also the repair: a refuel pad (#R$A8F4) sets the count to $FF first, so it wraps to 0 and the icon goes back to white ($47). The icon is a 4 by 2 character patch (#R$8FBB) at x=$30 for player 1 and x=$B0 for player 2 (the player number is in #R$CA1C), painted by #R$C991.
R $8F54 IX The object
R $8F54 C The contact effect
  $8F54,6 Still cooling down from the last touch
  $8F5A,8 Cool-down 15
  $8F62,6 No shield: damage
  $8F68,14 Shielded, and an ordinary attacker: it is shot instead
  $8F76,10 No damage with the shield up, or while dying
  $8F80,10 A sound, and one more hit
  $8F8A,14 White after a repair (count 0), yellow after one hit, magenta after two
  $8F98,11 The third: the ship dies, and the icon goes black
  $8FA3,4 The patch's colour
  $8FA7,18 Paint it over this player's ship icon

@ $8FBB label=ship_icon_positions
b $8FBB The two ship icons' positions (unused)
D $8FBB The panel positions of the two players' ship icons as words, x then line ($0F30 and $0FB0); but #R$8F54 loads them as constants, and nothing reads these.
B $8FBB,4,4

@ $8FBF label=icon_patch_record
b $8FBF The ship icon's colour patch
D $8FBF The patch record #R$C991 paints over the current player's ship icon (#R$8F54): width 4 characters, height 2, and the colour, which #R$8F54 writes. The fourth byte is a $C9 that nothing uses.
B $8FBF,4,4 Width, height, colour; and an unused byte

@ $8FC3 label=hit_count
g $8FC3 Hits taken by this ship
D $8FC3 0-3, counted up by each hit (#R$8F54); the third kills the ship. Cleared for a new ship (#R$F311), and set to $FF by a refuel pad's repair (#R$A8F4), so that the damage code wraps it to 0.

@ $8FC4 label=contact_refuel
c $8FC4 Contact effect bit 5: refuel
D $8FC4 The refuel pick-up's effect ($28 with bit 3: refuel and collect). Adds -$1C00 to the fuel word through #R$CC4D, which clamps it at full: the gauge's high byte runs from $42 (full) to $BE (empty), so a pick-up is worth 28 of its 124 steps.

@ $8FCA label=contact_push
c $8FCA Contact effect bit 4: bounce the object off the ship
D $8FCA Part of the default effect. For each axis the object's velocity is halved and negated, so it bounces away at half speed, and the same amount is added to the ship's velocity word in that axis (+$19, +$1B of its record).
R $8FCA IX The object
R $8FCA IY The ship's record (#R$C8E5)
  $8FCA,32 X: the object's velocity becomes minus half of itself; the ship's has that added
  $8FEA,32 Y: the same

@ $900B label=contact_collect
c $900B Contact effect bit 3: collect the object
D $900B Marks the object to be freed (bit 4 of +$10, which #R$90EC acts on next pass) and makes the pick-up sound (#R$7318).

@ $9015 label=contact_drain_fuel
c $9015 Contact effect bit 2: take fuel
D $9015 A sound, then adds $1000 to the fuel word (#R$CC4D): towards empty, 16 of the gauge's 124 steps. The effect of the pick-up with frame 6 ($1C: push, collect, take fuel, #R$944C). Never ran in the build's sessions.

@ $9020 label=contact_extra_life
c $9020 Contact effect bit 1: an extra life
D $9020 The ship-icon pick-up's effect ($1A). One more life (in the player record, #R$F5E7), but never more than 9; a sound, and the panel's count redrawn (#R$CA31). Never ran in the build's sessions.

@ $9030 label=contact_destroy
c $9030 Contact effect bit 0: the object is destroyed
D $9030 Marks the object shot (bit 5 of +$10), as a shot would: its update routine scores it and turns it into debris next pass (#R$9035). The effect of type $1D ($51), which damages the ship and dies doing it.

@ $9035 label=check_shot
@ $903D label=make_debris
c $9035 Score a shot object and turn it into debris
D $9035 Used by the attackers' update routines (#R$9507, #R$9494). If the object has been shot (bit 5 of +$10) it is scored (score_object, in #R$917C) and becomes debris: type $15 (#R$96D8), frame count $50, frames 0-5, and the path step at the start of a random quarter of the path's mirror images (bits 6-7 of +$15). The zero flag tells the caller which.
D $9035 make_debris is also how the ship's wreck starts (#R$8CB2), which sets the four quarters itself.
R $9035 IX The object
R $9035 O:F Z if it had not been shot
  $9035,5 Not shot
  $903A,3 Score it
  $903D,12 Debris: type $15, frame count $50, frames 0 to 5
  $9049,10 A random mirror image of the path
  $9053,3 NZ: it was shot

@ $9056 label=test_landscape_at
@ $9062 label=nudge_object
c $9056 Test an object against the landscape, a little down and to the left
D $9056 Moves the object 4 pixels left and 4 down (by setting its velocity to that, moving it with #R$BF66 and putting the velocity back), tests it against the landscape with #R$BA21, and moves it back. The 4-pixel offset lines the object's box up with its sprite. The mode #R$BA21 tests in (#R$5C25) is the caller's: see #R$909A and #R$90A7; the result is in #R$5C1C.
D $9056 nudge_object moves the object by A pixels down and -A across, keeping its velocity, with the velocity saved in the four bytes at #R$DEDC while it does.
R $9056 BC The box's height and width in pixels, for #R$BA21
R $9062 A The nudge
  $9056,7 Nudge it left and down
  $905D,3 Test the landscape
  $9060,2 And back
  $9062,18 Keep its velocity
  $9074,16 Velocity -A across, A down
  $9084,3 Move it
  $9087,19 Put the velocity back

@ $909A label=move_bouncing
c $909A Move an object that bounces off the landscape
D $909A Used by the attackers, the debris and the homing missiles. Tests the landscape in mode 0 (#R$5C25) and then moves the object by its velocity (#R$BF66). In mode 0 #R$BE8F negates the object's velocity before the test, and this routine negates it again after; how a touch turns into a bounce is #R$BA21's business and not yet worked out here.
R $909A BC The box's height and width in pixels
  $909A,7 Test the landscape in mode 0
  $90A1,6 Negate the velocity again, and move

@ $90A7 label=move_or_explode
c $90A7 Move an object that explodes on the landscape
D $90A7 Used by the small objects (#R$9457) and type $1D (#R$9494). Tests the landscape in mode $80 (#R$5C25); on a touch (#R$5C1C) the object starts exploding (bit 3 of +$17), stops, and makes a sound (#R$72A5). Then it is moved by its velocity (#R$BF66).
R $90A7 BC The box's height and width in pixels
  $90A7,8 Test the landscape in mode $80
  $90AF,7 No touch: just move it
  $90B6,17 Touched: it explodes, and stops
  $90C7,6 A sound, and move it

@ $90CD label=negate_velocity
c $90CD Negate an object's velocity
D $90CD Both components, through #R$BE08.
R $90CD IX The object

@ $90EC label=place_object
c $90EC Place an object on the screen, or free it
D $90EC Remembers the object in #R$AD46. An object marked to be freed (bit 4 of +$10) is freed now. One with bit 3 of +$10 set has it cleared and is not placed this pass. Otherwise #R$AD48 works out where on the screen it is (or frees it when it is far from the view), with its sprite and colour, and #R$8C58 turns an attacker that is off the screen back towards the view.
R $90EC IX The object
  $90EC,4 Remembered for the routines after the update
  $90F0,11 To be freed
  $90FB,9 Skip one placing
  $9104,6 Place it, and steer it back if it is off the screen

@ $910A label=animate_object
c $910A Step an object's animation
D $910A The frame byte +$13: bits 0-3 the frame, bits 4-5 a count, bits 6-7 the count's reload. Each call counts bits 4-5 down; when they read 1 the frame steps on, from the last frame (low nibble of +$14) back to the first (high nibble of +$14), and the count is reloaded from bits 6-7. So a type's animation runs at one frame every one to three passes over any run of its frame list. (A count of 0 sets bits 4-7 all, and the animation goes on at the slowest rate.)
R $910A IX The object
  $910A,11 Count 1: step the frame
  $9115,25 The next frame, or the first after the last
  $912E,13 Reload the count from bits 6-7
  $913B,7 Count down, or the reloaded count, into bits 4-5

@ $9143 label=object_box
c $9143 Make the current object's box for the shot tests
D $9143 The box at #R$ABA4 from where the object was drawn this pass (#R$AD46): x, bottom line, width and height. A sprite straddling the left edge of the view (a flag in #R$A2F8) has its x moved in and its width cut, and one running off the right is cut at the right edge ($EE). #R$5C1E gets its top line. Nothing is done when it was not drawn (height 0 in #R$A1D3); the height left in D tells #R$917C the same.
R $9143 O:D The height drawn (0: not drawn)
  $9143,13 Drawn at x, bottom line; drawn this wide
  $9151,7 This high; not drawn: no box
  $9158,14 Straddling the left edge: x moves in by 8 and the width is cut
  $9166,9 Running off the right: the width ends at x=$EE
  $916F,7 The box
  $9176,6 Its top line

@ $917C label=test_player_shots
@ $918B label=test_shot_list
@ $9234 label=score_object
@ $925E label=add_score
c $917C Test the current object against the player's four shots
D $917C The object's box is at #R$ABA4 (#R$9143). The shots are four records of 24 bytes at #R$B37A (updated by #R$B706). Two kinds: a homing missile (bit 7 of its +$16; #R$9307) is a box 8 wide and 5 high at its drawn position (+$11, +$12), tested only while drawn. The other kind, the laser, is a line: x in its +$0B (0 when there is none), line in +$0C, length in characters in +$0E; when bit 7 of its +$15 is set it is 8 lines high and the line test is skipped. The test is #R$9DB1.
D $917C A hit marks the shot (bit 7 of +$10; a missile is also freed) and the object shot (bit 5 of +$10), which its update routine turns into a score and debris (#R$9035). A missile hitting type $19 counts a hit on it directly (+$16) and scores it. A shot with bit 7 of +$15 set destroys any object outright instead (bit 3 of +$17), scoring it double; type $19 gives its points that way only when it is already worn down (+$D = $FF), and then also credits ore to the part being carried (the second entry point of #R$A8A5). Only the first shot that hits counts.
D $917C score_object adds an object's points to the score: 250 for types $0D and $1B, otherwise from #R$929C, doubled for one destroyed outright. add_score adds BC (BCD, B the high pair) to the current player's score (the first three bytes of the player record, #R$F5E7, BCD, low first), and prints it on the panel with #R$A115: the digits are font codes $1A-$23 (#R$9F76), written into the panel's text (#R$C9F0, the record in front).
R $917C IX The object's record
R $917C D The height it was drawn with (from #R$9143)
R $925E BC The points, BCD
  $917C,3 Not drawn: no test
  $917F,12 Four shots (#R$B37A), the object's box at #R$ABA4
  $918B,7 A missile, or the laser
  $9192,9 The laser: its x, 0 when there is none
  $919B,14 A missile, only while drawn: its x and line
  $91A9,10 The laser's line; a tall one skips the line test
  $91B3,20 The line within the object's height: 5 high
  $91C7,2 Tall: 8
  $91C9,17 Missile: 8 wide; laser: its length in characters times 8
  $91DA,9 The test
  $91E3,12 Next shot
  $91EF,28 A missile hit: it is freed; on type $19 a hit counted, with a sound and the points
  $920B,8 The shot has hit; the object is shot
  $9213,13 A heavy shot destroys it outright
  $9220,7 Type $19 scores...
  $9227,13 ...only when worn down: points, and ore for part 6
  $9234,16 Types $0D and $1B: 250
  $9244,12 The rest from the table, by type
  $9250,14 Doubled when destroyed outright
  $925E,18 Add BC to the score
  $9270,26 Six digits, high first, as font codes
  $928A,18 Print them

@ $929C label=type_points
b $929C Points by type
D $929C For types $13 to $1E, two BCD bytes each, the high pair first (score_object in #R$917C): cloud 0, $14 250, debris 0, $16 200, $17 150, $18 100, $19 75 a hit, $1A 90, $1B 0 (it scores 250 as a special case), $1C 0, $1D 350, $1E 0.
B $929C,24,2

@ $92B4 label=find_missile_target
c $92B4 Pick a target for a homing missile
D $92B4 Called by #R$9307 when the missile has no target. The type is first tested for a free record by INC A, so the SUB $14 after it leaves the type less $13, the same index as #R$929C's. Goes through the first seven records at #R$9974 and picks, of those drawn this pass, the one whose type is worth most in #R$92EE, putting its record number in the high nibble of the missile's +$17 (the low nibble is cleared with it). None found: +$17 stays $F0. The best value so far is kept in #R$5C1C.
R $92B4 IX The missile's record
  $92B4,10 Seven records; best value 0
  $92BE,12 Drawn this pass, and in use
  $92CA,14 Its value, by the type less $13 (the INC A above); not more than the best: skip
  $92D8,4 The best so far
  $92DC,10 Its record number, in the high nibble of +$17
  $92E6,8 Next record

@ $92EE label=missile_target_values
b $92EE The homing missiles' target values
D $92EE By type less $13 (#R$92B4 adds one to the type to test for a free record before it subtracts $14), the indexing of #R$929C, and in the order of the points there: $13 (a cloud) 0, $14 (the rotor craft, 250 points) 8, $15 (debris) 0, $16 (the saucer, 200) 7, $17 (the eye pod, 150) 6, $18 (the pillar, 100) 5, $19 (the tough attacker, 75 a hit) 2, $1A (the dome, 90) 4, $1B 0, $1C (bullets and other thrown things) 0, $1D (rocks, 350) 9, $1E (a falling rocket part) 0. A value of 0 is never picked, so a cloud, which can come into records 0-3 through the wave table, reads the table's first byte and is passed over, as are debris, thrown things and rocket parts.
D $92EE In 240 seconds of simulated flying with missiles, run for the reference pages, all 285 targets chosen were the best on the screen by this ranking, and clouds, debris and bullets were never chosen.
B $92EE,12,12

@ $92FA label=set_facing
c $92FA Face an object the way it moves
D $92FA Frame 1 when its X velocity is negative (moving left), 0 otherwise.
R $92FA IX The object

@ $9307 label=update_missile
c $9307 Update a homing missile
D $9307 Called by #R$B706 for each of the player's shots that is a homing missile (bit 7 of +$16) and is flying (first byte 0; $FF when spent). With no target (the high nibble of +$17 is $F) it looks for one (the code at offset 24 of #R$929C). With one it steers at it (#R$9341), and gives it up when the target's record is freed. Then it moves (#R$938D).
R $9307 IX The missile's record
  $9307,10 No target: look for one
  $9311,10 Still none: just move
  $931B,19 The target's record
  $932E,13 Freed: no target
  $933B,6 Steer at it, and move

@ $9341 label=steer_towards
c $9341 Accelerate an object towards another
D $9341 Sets the acceleration (+$0B, +$0E) to $C0 (three quarters of a pixel a pass, each pass) towards the target in each axis. In X: the same page column decides by the pixel; otherwise the target is taken to be to the left when the object is in the column after the view's (kept in #R$DDF2), and to the right otherwise. In Y, by the whole position.
R $9341 IX The object
R $9341 IY The target
  $9341,26 X: right, unless...
  $935B,10 ...in the other page column
  $9365,8 Left
  $936D,14 Y: compare the positions (page row and pixel)
  $937B,9 Down
  $9384,9 Up

@ $938D label=move_missile
c $938D Move, draw and time out a homing missile
D $938D Rubs out its old picture, accelerates it (#R$8C05), faces it (#R$92FA), counts its life down in +$15 (freed at 0, or when marked by a hit), moves it bouncing off the landscape in a 16 by 11 box (#R$909A), and draws it.
D $938D One odd case: when the landscape piece under the missile is $3E (looked up in the four in #R$DC87 by which quarter of the view it is in) and its line is between $18 and $D7, its line is set to $6A. Not yet worked out.
R $938D IX The missile's record
  $938D,14 Rub out last pass's picture
  $939B,7 Accelerate, and face the way it moves
  $93A2,12 Its life is out: free it
  $93AE,6 Hit something: free it
  $93B4,6 Move it, bouncing
  $93BA,28 The landscape piece in its quarter of the view
  $93D6,19 Piece $3E
  $93E9,3 Place it
  $93EC,6 Draw it

@ $93F2 label=update_cloud
c $93F2 Update routine for type $13, the clouds
D $93F2 A cloud slows the ship (contact effect $80, #R$8F1E), cannot be shot (its +$10 has bit 5 set from the start, #R$87AF), and explodes when it drifts below the bottom of page row 10 or into row 3. Clouds made high up (top speed 4) do not drift in Y. White clouds (+$D = $77) drop things on the ship (#R$8813, kind 3). The big one (frame 1, one in eight) counts twice in the load. It moves bouncing off the landscape in a 48 by 32 box. Identified as clouds by their place in the sky, their colours and their harmlessness, not by name.
R $93F2 IX The cloud's record
  $93F2,5 Its contact effect
  $93F7,20 Below row 10's line $A0: it explodes
  $940B,8 In row 3: it explodes
  $9413,17 White ones drop things
  $9424,17 The high ones keep their height
  $9435,3 Accelerate
  $9438,20 48 by 32; the big one counts twice; move and draw (#R$9507)

@ $944C label=small_object_effects
b $944C Contact effects of type $1C, by frame
D $944C One byte for each of the frames 0-10 of type $1C (#R$9457), the effect #R$8E2D acts on (see #R$8E2B): $50 damage and push for the bullets and the wreck's pieces; frame 3 $28, refuel and collect; frame 6 $1C, push, collect and take fuel; frame 8 (the ship icon) $1A, push, collect and an extra life; frame 9 (the ball) $FF, the shield.
B $944C,6,6 Frames 0-5
B $9452,5,5 Frames 6-10

@ $9457 label=update_small_object
c $9457 Update routine for type $1C, the bullets, pick-ups and wreck pieces
D $9457 The small things: what the attackers drop (#R$8813), the pick-ups, and the five pieces of the ship's wreck (#R$8CB2). The frame picks the contact effect (#R$944C). A wreck piece (+$14 = 2) accelerates (#R$8C05); the others fly straight. The ship icon and the ball (frames 8 and 9) keep their frame; the rest animate. Each lives as many passes as +$15 says, then explodes, and explodes at once on touching the landscape (#R$90A7).
R $9457 IX The record
  $9457,15 Contact effect by frame
  $9466,8 A wreck piece accelerates
  $946E,15 The ship icon and the ball: a 42-wide box, no animation
  $947D,5 The rest animate, 24 wide
  $9482,5 24 high; move, or explode on the landscape
  $9487,13 Count its life down; at 0 it explodes; place and draw it

@ $9494 label=update_rammer
c $9494 Update routine for type $1D
D $9494 Damages the ship and dies doing it (contact effect $51: damage, push, destroyed). Scored and turned to debris when shot (#R$9035), animated, moved in a 32 by 32 box, exploding on the landscape (#R$90A7). Fast (top speed 7, from the wave table #R$990A) and worth 350.
R $9494 IX The record
  $9494,5 Its contact effect
  $9499,3 Shot: score and debris
  $949C,12 Animate, move, place, draw

@ $94A8 label=update_tough_attacker
c $94A8 Update routine for type $19, the tough attacker
D $94A8 Takes many hits: a shot (bit 5 of +$10) counts as one only on every eighth pass, in +$16, and a missile counts one directly (#R$917C); each scores 75. From ten hits it flashes white (+$D = $FF instead of $55), and at fourteen it explodes, scored. It has an engine sound (#R$7275), drops things on the ship (#R$8813, kind 7 or 8 by its facing), changes course now and then (#R$97DF, #R$995B), faces the way it moves, and moves bouncing in a 48 by 24 box.
R $94A8 IX The record
  $94A8,7 Engine sound; its colour
  $94AF,22 Shot, on every eighth pass: one more hit, a sound, 75 points
  $94C5,4 The shot is used up
  $94C9,13 Ten hits: flashing white
  $94D6,11 Fourteen: it explodes, scored
  $94E1,17 Drop something on the ship
  $94F2,6 Change course now and then; accelerate
  $94F8,9 Face the way it moves
  $9501,6 48 by 24; move and draw

@ $9507 label=update_attacker
@ $9512 label=animate_move_draw
@ $9518 label=move_draw
@ $951B label=place_draw
@ $951E label=draw_object
c $9507 Update routine for types $14, $16, $17, $18 and $1A, the attackers
D $9507 A shot attacker is scored and turned to debris (#R$9035). Otherwise it changes course by its type (#R$97DF) and accelerates (#R$8C05). Then, as for most types: animate (#R$910A), move bouncing off the landscape in a 34 by 35 box (#R$909A), place it (#R$90EC), and draw it (#R$AD1B) with its colour (#R$AE98). The other update routines join this tail at its entry points.
R $9507 IX The record
  $9507,5 Shot: score and debris, and no steering
  $950C,6 Change course; accelerate
  $9512,3 Animate
  $9515,3 34 wide, 35 high
  $9518,3 Move, bouncing
  $951B,3 Place it on the screen
  $951E,3 Draw it
  $9521,3 And colour it

@ $9524 label=update_rocket_part
c $9524 Update routine for type $1E, a rocket part falling into place
D $9524 Reached through the type table at #R$AF25 (its last word). A part the ship has let go of (#R$9724) falls under its own acceleration, harmless to touch apart from a push (effect $10), and does not test the landscape. It stops when it reaches its place -- page row +$15 and the line in +$16, set by #R$9724 -- and is freed: as soon as it is in that row with its line at or below the slot's, so a part let go no higher than its slot is freed on its first pass without falling (run in SkoolKit's simulator for the Animations page); the parts delivered (offset $1B of the player record, #R$F5E7) go up by one and the player scores 1500. Then it is drawn (draw_object, the tail of #R$9507).
R $9524 IX The part's record
  $9524,5 Push only
  $9529,6 Accelerate, and move
  $952F,20 At its page row and line: free it
  $9543,3 Place it (freed now if marked)
  $9546,8 Freed?
  $954E,13 One more part delivered, and 1500 points
  $955B,4 Draw it

@ $955F label=put_rocket_record
c $955F Put the rocket's position in its drawing record
D $955F The rocket's base position, X from #R$96AC and Y from the two bytes after it (#R$96AE), goes into the drawing record (#R$9A4C).
R $955F IX The drawing record (#R$9A4C)

@ $9572 label=draw_rocket
c $9572 Draw the rocket parts delivered, and launch the rocket
D $9572 Called by #R$AC60. The rocket is built at a fixed place, page column $52 and row 10, from up to eight parts brought there by the ship (#R$9724, #R$9524). Each pass the view is near it (columns $51-$52, rows 9-10) -- or the rocket is launching -- every part delivered is drawn from the one record #R$9A4C: the base position (#R$96AC, #R$96AE) plus the part's offset from #R$96B0, frame the part's number (part 6 uses frame 8). The part's flags and drawn position are kept in its entry of the table between passes, so its old picture can be rubbed out. Half the parts' number counts in the load (#R$8D3C).
D $9572 When all eight are there and the ship stops in place in the rocket (column $52 pixel $5C, row 10, line $63 or below), the launch starts: #R$96AB is set, the ship is put away (two routines inside #R$C3E3, run with the death byte at 10 for their sake), and from then on the base moves up each pass (at the view's vertical scroll speed (#R$CCBA), or 4 lines a pass in page row 0), with the launch sound (#R$7303). Once part 0 has left the screen #R$96AB is set to $FF, which ends the play loop (#R$F440) in the game's end sequence.
D $9572 It all ran in the build's sessions: the launch, and the deliveries of part 0 and of the ore tank. In the staged launch the rocket kept its place on the screen while the view climbed from page row 10 to row 0, its base moving up by the view's own scroll, and then rose 4 lines a pass off the top; the launch took about 390 passes (run in SkoolKit's simulator for the Animations page).
  $9572,4 No share in the load yet
  $9576,6 Launching: draw
  $957C,19 Otherwise only with the rocket's place in view
  $958F,11 No parts: nothing; half their number counts in the load
  $959A,14 The drawing record; part 0 first
  $95A8,8 Launching: the sound
  $95B0,24 Move the base up with the view, or by 4 at the top
  $95C8,18 Keep the base
  $95DA,3 Each part: the base...
  $95DD,21 ...its flags and drawn position from the table...
  $95F2,20 ...plus its offset
  $9606,11 Part 6 is drawn with frame 8
  $9611,15 Rub out its old picture
  $9620,9 Place, draw and colour it
  $9629,35 Its flags and drawn position back to the table
  $964C,12 Next part
  $9658,6 All eight?
  $965E,6 Launching...
  $9664,14 ...until part 0 is off the screen: then the game's end
  $9672,22 The ship in place in the rocket?
  $9688,8 The launch begins; the death byte 10 for the next two calls
  $9690,6 Put the ship away
  $9696,21 The death byte back to 0; the carried thing's state $80 (#R$C1CE); the ship's X velocity 0; a sound

@ $96AB label=launch_state
g $96AB The launch
D $96AB 0 in play. Set non-zero when the ship docks with the finished rocket (#R$9572): the rocket rises, nothing touches the ship (#R$8E2D, #R$9D0E), the controls are off (#R$C374). $FF when the rocket has left the screen, which ends the play loop (#R$F440). Cleared for a new game (#R$F311).

@ $96AC label=rocket_x
b $96AC The rocket's base position in X
D $96AC A word: the pixel, then the page column ($68 in column $52), where #R$9572 draws the rocket's parts from (#R$955F). It does not change.
W $96AC,2

@ $96AE label=rocket_y
b $96AE The rocket's base position in Y
D $96AE A word: the line, then the page row ($73 in row 10). #R$9572 moves it up each pass of the launch.
W $96AE,2

@ $96B0 label=rocket_part_table
b $96B0 The rocket parts' table
D $96B0 Eight entries of five bytes, one a part, in the order they are delivered: the flags and drawn x and line #R$9572 keeps between passes (copied to and from +$10 to +$12 of #R$9A4C), then the part's offset from the base (#R$96AC, #R$96AE), X and Y, as signed pixels. The parts stack up: offsets in Y 0, -9, -18, -34, -30 (part 4, 14 left), -30 (part 5, 22 right), -47, -63. #R$9724 reads the Y offset to say where a falling part stops. Bit 7 of part 0's flags (drawn) tells #R$9572 when the launched rocket has left the screen.
B $96B0,40,5

@ $96D8 label=update_debris
c $96D8 Update routine for type $15, debris
D $96D8 Debris -- what is left of a shot attacker (#R$9035) and four pieces of the ship's wreck (#R$8CB2) -- is harmless, makes the debris sound (#R$720A), and flies a fixed path: the velocity is taken each pass from #R$9873, the step in +$15 (bits 0-5) going on by two. Bit 7 of +$15 mirrors the path in X and bit 6 in Y, so four pieces of the wreck flying the four mirror images make a burst. At the path's end ($80) it is freed. It animates, and bounces off the landscape (the tail of #R$9507).
R $96D8 IX The record
  $96D8,7 Harmless; the sound
  $96DF,16 The path's next step
  $96EF,7 The end: freed
  $96F6,14 Its velocity, and the next step
  $9704,14 Mirrored in X
  $9712,18 Mirrored in Y; animate, move and draw

@ $9724 label=drop_part
c $9724 Let a carried rocket part go over the rocket's place
D $9724 Called by #R$C3E3. The part the ship carries is kept at offset $1A of the player record (#R$F5E7; $FF none). When the ship is over the rocket's place (page column $52 pixel $5C) in page row 10 or above, the part is let go: a record is found for it (#R$97BD) and filled as type $1E (#R$9524) at column $52 pixel $68 and the ship's height, falling with a Y velocity made from the ship's (its Y velocity word in #R$C891, negated) and a slight downward acceleration ($1B), to stop at row 10 at line $73 plus the part's Y offset (#R$96B0). Part 6 is let go only when full -- when the ore loaded into it (a count in #R$C891, filled by #R$A8A5) is 18 -- and falls with frame 8; its load and a byte of the player record are cleared. Then the ship carries nothing.
D $9724 It all ran in the build's sessions (the deliveries of part 0 and of the ore tank).
  $9724,5 Carrying nothing
  $9729,18 Not over the rocket's place
  $973B,15 Part 6 only when loaded with 18
  $974A,5 +$1F of the ship's record (#R$C904) gets $80 plus the part (or 8)
  $974F,6 A record, emptied
  $9755,15 Its Y velocity, from the ship's
  $9764,12 Type $1E; top speed 4, and it cannot be shot; falling
  $9770,25 Frame the part's number; it stops at line $73 plus the part's offset
  $9789,20 At the ship's height, column $52 pixel $68
  $979D,8 Flashing white; it stops in row 10
  $97A5,18 Part 6: frame 8, emptied
  $97B7,6 Nothing carried

@ $97BD label=find_record_for_part
c $97BD Find a record for a falling rocket part
D $97BD The first free of the nine at #R$9974; if none, the first not drawn this pass; if all are drawn, the ninth.
R $97BD O:IX The record
  $97BD,18 A free one
  $97CF,16 One not on the screen

@ $97DF label=change_course
c $97DF Change an attacker's course now and then
D $97DF Counts +$15 down and, at 0, sets it again to 1-32 passes and jumps to the type's steering routine through the table #R$993B. Once bit 7 of +$16 is set (#R$97FF), there is no wait: the steering runs every pass. The routines: $14 and $16 home in on the ship (#R$97FF), $17 turns at it every 10-25 passes (#R$9837), $18 and $1A drift diagonally at random (#R$984D), and $19 turns at it or stops (#R$995B).
R $97DF IX The attacker
  $97DF,10 Wait
  $97E9,9 The next wait, 1-32 passes
  $97F2,13 The type's steering

@ $97FF label=home_on_ship
c $97FF Steering: home in on the ship
D $97FF Accelerates at a quarter of #R$9341's rate ($30) towards the ship's record (#R$C8E5), and sets bit 7 of +$16 so that #R$97DF runs this every pass from now on: types $14 and $16 home in for good after their first wait.
R $97FF IX The attacker
  $97FF,11 At the ship
  $980A,4 Every pass from now on
  $980E,41 A quarter of the acceleration

@ $9837 label=turn_at_ship
c $9837 Steering: turn at the ship now and then
D $9837 Type $17: full acceleration towards the ship (#R$9341), and the next turn in 10-25 passes.
R $9837 IX The attacker

@ $984D label=drift_at_random
c $984D Steering: drift diagonally at random
D $984D Types $18 and $1A: the acceleration in each axis is $20 or -$20, from bits 0 and 1 of the random number (#R$9BCB).
R $984D IX The attacker

@ $986A label=random_direction
c $986A Return -$20 or +$20
D $986A For #R$984D: DE = -$20 when the flags are zero, +$20 otherwise.
R $986A O:DE The acceleration

@ $9873 label=debris_path
b $9873 The debris path
D $9873 Sixteen steps of the path debris flies (#R$96D8), as X and Y velocities in pixels a pass (signed bytes): out and up, round and down, a loop of about 60 by 40 pixels. $80 ends it.
B $9873,32,2 Sixteen steps: X, Y
B $9893,1 The end

@ $9894 label=attacker_frames
b $9894 The frame lists of types $15 to $1A
D $9894 The frame lists, one a type, which the table at offset 24 of #R$AF25 points into: a word for each frame, the address of its graphic (a byte of width, a byte of height in lines, then the bitmap, bottom row first; no mask). The lists overlap: type $15 starts at the first word (frames 0-5), $16 at the seventh, $17 at the eleventh, $18 at the thirteenth, $19 at the seventeenth, $1A at the nineteenth; the list of type $1A runs on into the clouds' (#R$98BE).
W $9894,42,2

@ $98BE label=cloud_frames
b $98BE The clouds' frame list
D $98BE Type $13's two frames (the table at offset 24 of #R$AF25 points here): the small cloud, 4 bytes by 12 lines, and the big one, 5 by 24.
W $98BE,4,2

@ $98C2 label=small_thing_frames
b $98C2 The frame list of type $1C
D $98C2 Eleven frames (#R$9457): 0-2 the bullet, 3 the refuel pick-up, 4, 5 and 7 small ones, 6 the fuel thief, 8 the ship icon (the graphic the panel shows the lives with, inside #R$C891), 9 the ring (#R$98D8), 10 a graphic inside #R$89A7.
W $98C2,22,2

@ $98D8 label=shield_ring
b $98D8 The ring, the shield pick-up
D $98D8 Frame 9 of type $1C (#R$98C2): a byte of width (2), a byte of height (16 lines), then the bitmap, bottom row first, no mask. Touching it raises the shield (#R$8E2D).
B $98D8,34,2 Width, height; then the bitmap

@ $98FA label=rammer_frames
b $98FA The frame list of type $1D
D $98FA Eight frames of 2 bytes by 16 lines (#R$9494).
W $98FA,16,2

@ $990A label=wave_table
b $990A The wave table
D $990A Ten entries of four bytes, read by #R$89D3 (via #R$87AF): type, flags (+$10), frame byte (+$13) and frame range (+$14) for a new attacker of each kind. 0 type $1A; 1 and 5 clouds ($13, flags $21: top speed 2 and shot already, so they cannot be shot); 2 $17; 3 $18; 4 $19; 6 $14; 7 $16; 8 and 9 type $1D. #R$9932 says which comes next.
B $990A,40,4

@ $9932 label=wave_counter
g $9932 The wave counter
D $9932 The entry of #R$990A that #R$89D3 spawns next: stepped from 0 to 5, or to 7 when two flags in the player record (#R$F5E7) are both set.

@ $9933 label=attacker_colours
b $9933 The attackers' colours
D $9933 Eight colour bytes for +$D (two inks, flashing), one picked at random for each new attacker by #R$89D3; only the first four at middle heights.
B $9933,8,8

@ $993B label=steering_routines
b $993B The steering routines by type
D $993B For #R$97DF, a word each from type $13: #R$93F2 (unused), #R$97FF, #R$96D8 (unused), #R$97FF, #R$9837, #R$984D, #R$995B, #R$984D.
W $993B,16,2

@ $994B label=stop_object
c $994B Stop an object
D $994B Clears its acceleration (#R$B8FC) and its velocity.
R $994B IX The object

@ $995B label=steer_tough_attacker
c $995B Steering for type $19: turn at the ship, or stop
D $995B The next change in 16-79 passes. One time in four it stops dead (#R$994B); otherwise it homes in on the ship at the quarter rate (#R$97FF), but only until the next change (bit 7 of +$16 is cleared again).
R $995B IX The attacker

@ $9974 label=object_records
b $9974 The object records
D $9974 Nine records of 24 bytes, updated by #R$8D42; $FF in the first byte marks a free one. They are shared out: attackers from the wave table go in any (#R$87AF), what the attackers drop in records 4-6 (#R$8820), clouds in records 7 and 8 (#R$8792); the homing missiles look for targets in records 0-6 (#R$92B4); the ship's wreck fills all nine (#R$8CB2), and a falling rocket part takes any (#R$97BD).
D $9974 The record: +0 the type ($FF free; $13-$1E, which picks the update routine in #R$AF25 and the frame list). +1 +2 +3 X: the page column (0-$5F, wrapping), the pixel in it ($08-$E7, a page being 224 wide) and a fraction. +4 +5 +6 Y: the page row, the pixel in it ($18-$B7, 160 lines) and a fraction; Y grows downwards. +7 +8 the X velocity and +9 +A the Y velocity, signed 8.8 pixels a pass, high byte first (#R$BF66 adds them). +B +C the X acceleration and +E +F the Y acceleration, the same form (#R$8C05). +D two colours: the low nibble on odd passes and the high nibble on even ones (bits 0-2 or 4-6 the ink, bit 3 or 7 BRIGHT), so a sprite can flash (#R$AD48).
D $9974 +10 flags: bits 0-2 the top speed less one (#R$8C05), bit 3 skip one placing (#R$90EC), bit 4 to be freed, bit 5 shot, bit 6 straddles the left edge of the view, bit 7 drawn. +11 +12 where it was drawn: screen x and bottom line. +13 the frame: the low nibble the frame in the type's list, bits 4-5 a count down to the next frame and bits 6-7 what it is reloaded with (#R$910A). +14 the frame range: the first frame in the high nibble, the last in the low. +15 +16 the type's own: a timer, a path step, a hit count. +17 the high nibble a count down after touching the ship (#R$8F54), or on a homing missile the target's record number ($F none, #R$9307); bit 3 exploding and bits 0-2 the explosion's frame (#R$AD48).
B $9974,24,8 Record 0
B $998C,24,8 Record 1
B $99A4,24,8 Record 2
B $99BC,24,8 Record 3
@ $99D4 label=drop_records
B $99D4,24,8 Record 4: from here, three for what the attackers drop
B $99EC,24,8 Record 5
B $9A04,24,8 Record 6
@ $9A1C label=cloud_records
B $9A1C,24,8 Record 7: from here, two for clouds
B $9A34,24,8 Record 8

@ $9A4C label=rocket_record
b $9A4C The rocket parts' drawing record
D $9A4C One object record (#R$9974), type $1E, that #R$9572 draws every rocket part with in turn: the base position (#R$96AC, #R$96AE) moved by the part's offset, and the part's flags and drawn position (+$10 to +$12, the third row here) copied in from #R$96B0 and back out after.
B $9A4C,16,8
@ $9A5C label=rocket_record_flags
B $9A5C,8,8 +$10 to +$17

@ $9A64 label=pass_counter
g $9A64 The pass counter
D $9A64 A word, counted up once a pass by #R$C374 (and by the menu's loop). Its low bits time things that happen every other pass, every fourth or every eighth (the shield, the engine sounds, type $19's hits), and bit 0 picks the colour of a flashing sprite (#R$AD48).
W $9A64,2

@ $9A66 label=start
c $9A66 Start the game
D $9A66 Reached from #R$5C80 after the game block is decoded (#R$5C80). The stack goes into the printer buffer (below #R$5B80), the border black; #R$F86B builds the shift tables, and the game's outer loop takes over (#R$F422). Interrupts stay off throughout.
@ $9A66 nowarn
  $9A66,3 The stack goes below #R$5B80, in the printer buffer
  $9A69,3 A black border
  $9A6C,6 Build the shift tables; on to the outer loop

@ $9A72 label=clear_attributes
c $9A72 Set every attribute to white ink on black
D $9A72 All 768 attribute bytes to $47 (bright white on black).

@ $9A7E label=clear_pixels
c $9A7E Clear the screen's pixels
D $9A7E All 6144 bytes of the bitmap to 0.

@ $9A8A label=mask_world_objects
c $9A8A AND every byte of the objects-in-the-world table with E
D $9A8A #R$5C94 holds one byte for each object lying in the world, in map-column order: bits 0-5 its kind, bit 7 set once it is gone for player 1 and bit 6 for player 2 (#R$A8F4, #R$ABA8). A new game passes $3F (#R$F3BD), clearing bits 6 and 7 of each, so everything is back. #R$83D6 passes $7F for player 1 or $BF for player 2 at the end of a planet, bringing back only that player's objects.
R $9A8A E The mask

@ $9A9A label=play_tune_until_key
c $9A9A Play a tune until a key is pressed
D $9A9A The title tune: plays the notes from DE until the $FF at the end, but stops at once, returning NZ, when any key is down (#R$9BC3 with every half-row selected).
R $9A9A DE The tune
R $9A9A O:F NZ if a key stopped it

@ $9AA9 label=play_tune
c $9AA9 Play a tune to the end
D $9AA9 The notes from DE to the $FF at the end (#R$9AB4).
R $9AA9 DE The tune

@ $9AB4 label=play_note
c $9AB4 Play one note on the beeper
D $9AB4 A note is a byte: bits 0-5 the note (0 a rest), bits 6-7 its length less one, in units. A note's entry in #R$9B0C gives the half-period as a delay count and the number of cycles in one unit; the beeper is toggled between $00 and $10 (black border throughout) for length times that many cycles. A rest waits about 0.13 seconds a unit.
R $9AB4 A The note
R $9AB4 DE The tune, at the note
R $9AB4 O:DE The next note
  $9AB4,15 The note's entry
  $9AC3,7 Delay count (B, C) and cycles in a unit
  $9ACA,16 Times the length
  $9ADA,9 Half a cycle low...
  $9AE3,11 ...and half high
  $9AEE,8 Until the cycles are done
  $9AF6,22 A rest: about 0.13 seconds a unit

@ $9B0C label=note_table
b $9B0C The notes
D $9B0C 61 entries of three bytes (#R$9AB4): the half-period's delay count as B then C (the DJNZ count, then the number of passes round it, so about 256*(C-1)+B steps of 13 T-states), then the cycles in one unit of length. Entry 0 is unused (note 0 is a rest). Entries 1-60 rise a semitone each in loop counts -- 256*(C-1)+B is equal-tempered to within 7 cents -- except that entry 18 has entry 17's delay (only its cycle count differs), so note 18 sounds as note 17. Each half-wave also spends a fixed time outside the loops, which bends the scale played from 37 cents sharp at entry 1 to 34 cents flat at entry 60, from about 53 Hz up to 1524 Hz (measured in SkoolKit's simulator for the Sounds page). The cycle counts rise with the pitch so that a unit lasts about the same time.
B $9B0C,183,3

@ $9BC3 label=read_keyboard
c $9BC3 Read the keyboard
D $9BC3 Reads the half-rows A selects; returns the keys down as set bits 0-4. Every keyboard read in the game first writes A to port $FD; on a 48K Spectrum nothing answers that port, and why it is done is not yet worked out. On a 128K the same OUT is a write to the paging port whenever A's bit 7 is clear: the menu's test for B (#R$86B9) writes $7F, which pages RAM bank 7 in at the top of memory and locks the paging, and the game then crashes on the menu's first pass (watched in SkoolKit's 128K memory for the reference pages). It must be run in 48 mode.
R $9BC3 A The half-rows to read (0 bits select)
R $9BC3 O:A The keys down, a bit each
R $9BC3 O:F NZ if any

@ $9BCB label=random_a
g $9BCB A random byte
D $9BCB The first of the two random bytes the game reads (each attacker's choices, the beams, the drops), stepped once a pass by #R$F23B: the byte at #R$9BCD's pointer and the controls (#R$5C37) are added in. The routines that want more randomness also read R.

@ $9BCC label=random_b
g $9BCC A second random byte
D $9BCC Stepped with #R$9BCB by #R$F23B, from the complement of the same byte.

@ $9BCD label=random_pointer
g $9BCD The random number's pointer
D $9BCD A pointer, high byte first, that #R$F23B steps through memory once a pass (its high byte ANDed with $AF), so that the bytes it reads, code and data, stir the random bytes.
B $9BCD,2,2

@ $9BCF label=add_a_to_hl
c $9BCF Add A to HL
D $9BCF Used everywhere to index a table.

@ $9BD6 label=beam_state
g $9BD6 The beams' pattern, colour and timer
D $9BD6 For #R$9BDA: the bit pattern every beam is drawn with this pass (0 while they are off), the colour (bright, ink 1-7), the passes left before the next change, and (the last byte) whether a beam was drawn this pass, for the sound.

@ $9BDA label=draw_beams
c $9BDA Draw the flickering beams, and test them against the ship
D $9BDA Called by #R$DDF8, not while #R$5C3C is set. A beam crosses a screen whose landscape piece is $A6, at a fixed height in it, unless the thing that makes it has been shot: a bit in the player's record, found by #R$AC08 and tested by a BIT instruction this routine writes into itself (the third after the CALL to #R$AC08). Each pass the old beams are rubbed out (#R$9D25) and drawn again in the four screens around the view (the four pieces in #R$DC87, in the order 0, 2, 1, 3; bit 0 the page row below, bit 1 the column to the right). A beam is a one-line row of bytes ORed onto the screen in the current pattern, rotated to follow the fine scroll, its characters coloured (#R$C991) and its extent kept in #R$9D43 for rubbing out (#R$9D30 draws it, #R$9D53 places it).
D $9BDA The pattern changes when its timer runs out: half the time one of the eight at #R$9DA9 in a random bright colour, for 1-32 passes; otherwise none, for 1-16. A beam that touches the ship's box (40 by 16) damages it (#R$9D0E), then not again for 16 passes.
D $9BDA All of it, the pattern changes included, ran in the build's sessions.
  $9BDA,5 Not while #R$5C3C is set
  $9BDF,12 Counting down after a hit: no box
  $9BEB,19 The ship's box at #R$ABA4
  $9BFE,32 No beam piece in view and none drawn: done
  $9C1E,9 The timer
  $9C27,11 Half the time, no beam
  $9C32,15 A random bright colour
  $9C41,20 A random pattern, for up to 32 passes
  $9C55,2 Or none, for up to 16
  $9C57,9 The timer
  $9C60,8 None drawn yet; the four screens
  $9C68,24 Rub out the beam drawn there last pass
  $9C80,4 None now
  $9C84,17 This screen's row and column
  $9C95,13 Its beam-maker shot? (the BIT is written here)
  $9CA2,20 A beam piece, and a pattern
  $9CB6,14 Where it is on the screen; none in view
  $9CC4,3 Draw it
  $9CC7,13 Its width, for the colour and the test
  $9CD4,9 Not counting down: test it against the ship
  $9CDD,17 Colour it; a beam drawn
  $9CEE,24 Next screen
  $9D06,8 The sound when any was drawn (#R$72CF)

@ $9D0E label=beam_hits_ship
c $9D0E Test a beam against the ship
D $9D0E Not during the launch. The beam, D pixels wide and one line high at HL, is tested against the ship's box at #R$ABA4 (#R$AB98); a touch starts 16 passes of grace (#R$9D2F) and damages the ship (#R$8F54).
R $9D0E HL The beam's position
R $9D0E D Its width in pixels

@ $9D25 label=erase_flicker_beam
c $9D25 Rub out a beam
D $9D25 ANDs B bytes along the screen line at HL with the inverse of the pattern C.
R $9D25 HL The screen address
R $9D25 B The length in bytes
R $9D25 C The pattern

@ $9D2F label=beam_grace
g $9D2F The beams' grace count
D $9D2F Counts down the passes after a beam has hurt the ship (#R$9D0E), set to 16; while it is not zero #R$9BDA tests no beam against the ship. Cleared for a new ship (#R$F311).

@ $9D30 label=draw_flicker_beam
c $9D30 Draw a beam
D $9D30 Called by #R$9BDA. Records the beam in the four bytes at IY (#R$9D43) -- HL the screen address, B the length in bytes, C the pattern -- and ORs C into B bytes along the screen line from HL.
  $9D30,19 Record it; OR the pattern along the line

@ $9D43 label=flicker_beam_records
b $9D43 Where the beams were drawn
D $9D43 Four records of four bytes, one for each page around the view, in #R$9BDA's order (the view's page, the one to the right, below, below right): the screen address (low byte first), the length in bytes and the pattern of the beam drawn there (#R$9D30), for rubbing it out next pass (#R$9D25). A zero first byte means none.
B $9D43,16,4

@ $9D53 label=place_flicker_beam
c $9D53 Work out where a beam lies on the screen
D $9D53 Called by #R$9BDA. From the view's pixel position in its page (HL, from #R$CE45), the origins (DE, from #R$CE41) and the page being drawn (#R$9BDA's quarter, in #R$5C1E: bit 0 the page below, bit 1 the page to the right), it works out the beam's x and line, kept in #R$BF7F, and its length in bytes in B (0: not in view). The beam's pattern (from #R$9BD6) is rotated right by the fine scroll (#R$CE41 AND 7) into C, and HL becomes the beam's screen address (#R$A149). A beam lies at page y $21, 9 lines below the top of its tile-$A6 cell.
  $9D53,86 Its line and x; its length; the pattern rotated with the scroll; its screen address

@ $9DA9 label=flicker_beam_patterns
b $9DA9 The beams' patterns
D $9DA9 Eight bit patterns, one picked at random whenever the beams change (#R$9BDA).
B $9DA9,8,8

@ $9DB1 label=boxes_overlap
c $9DB1 Test a box against another
D $9DB1 The box at IX: x, bottom line, width, height. The other: x in L, bottom line in H, width D, height E. They overlap when their x ranges and their line ranges do (#R$9DBB, #R$9DD8). #R$5C1C is 1 if so, 0 if not. Used for the ship's touches (#R$8E2D), the shots (#R$917C) and the landscape.
R $9DB1 IX The box
R $9DB1 L The other's x
R $9DB1 H The other's bottom line
R $9DB1 D The other's width
R $9DB1 E The other's height

@ $9DBB label=x_overlap
@ $9DD2 label=overlap_found
c $9DBB Test two boxes' x ranges
D $9DBB They overlap when the box's x is within D after L, or L is within the box's width after the box's x. #R$5C1C is 1 if so.
  $9DBB,13 The box starts in the other's width
  $9DC8,10 Or the other starts in the box's
  $9DD2,6 Overlap

@ $9DD8 label=y_overlap
c $9DD8 Test two boxes' line ranges
D $9DD8 A box spans its height upwards from its bottom line. They overlap when the other's bottom line is within the box's height above the box's, or the box's within E above the other's. #R$5C1C is 1 if so.

@ $9DEE label=test_slope
c $9DEE Test an object against a sloping landscape edge
D $9DEE Used by the landscape tests (#R$9E35 and those after it). IX is a landscape piece's collision record: +0 and +2 its x range, +1 and +3 its bottom and top lines, +4 flags (bits 0-2 the steepness, bit 7 which way up). The object's box: x in L, bottom line in H, width D, height E (#R$9E35). When the line ranges meet, works out how far the object reaches into the slope at that line: B is the depth of that line under the slope's high edge, scaled by the steepness (2 as it is, 3 halved, others doubled). #R$5C1C is 1 if the object is in the piece's x range.
R $9DEE IX The piece's collision record
R $9DEE O:B The slope's offset at the object's line
  $9DEE,5 Above the piece: nothing
  $9DF3,6 Which way up
  $9DF9,15 The object's lowest line within the piece
  $9E08,14 Upside down: its highest
  $9E16,7 Within the piece's x range?
  $9E1D,5 Yes
  $9E22,19 The depth, scaled by the steepness

@ $9E35 label=test_landscape_piece
c $9E35 Test an object against one landscape piece
D $9E35 Called by #R$BC13 for each of a landscape piece's collision records. The object's box is in #R$CE3A-#R$CE3D, its x, bottom line, height and width (made by #R$BE8F). Bits 6-7 of the record's flags pick one of four slope shapes -- the same slope mirrored left to right and upside down (#R$9EA5, #R$9EC0, #R$9ED9); which way each faces is not yet worked out. A touch leaves #R$5C1C 1 and the depth into the slope in #R$5C1A.
D $9E35 All four shapes ran in the build's sessions; the RET after the four tests cannot be reached.
R $9E35 IX The collision record
  $9E35,11 The object's box
  $9E40,6 The steepness
  $9E46,23 The shape
  $9E5D,3 The first shape
  $9E60,9 In range: no touch yet
  $9E69,9 The object's right edge short of the slope: no touch
  $9E72,8 How far in

@ $9E7A label=test_slope_swapped
c $9E7A Test a slope mirrored left to right
D $9E7A Swaps the record's two x bounds, tests (#R$9DEE), swaps them back, and drops a touch when the object ends before the piece's far x.
R $9E7A IX The collision record

@ $9EA5 label=test_slope_reversed
c $9EA5 Test the second slope shape (flags $40)
D $9EA5 Mirrored left to right (#R$9E7A); the touch measured from the other side. The entry point after it serves #R$9EC0.
R $9EA5 IX The collision record

@ $9EC0 label=test_slope_upside_down
c $9EC0 Test the third slope shape (flags $80)
D $9EC0 Upside down (#R$9DEE, with the depth negated).
R $9EC0 IX The collision record

@ $9ED9 label=test_slope_both_ways
c $9ED9 Test the fourth slope shape (flags $C0)
D $9ED9 Mirrored and upside down, then measured as the first (#R$9E35).
R $9ED9 IX The collision record

@ $9EE3 label=test_pause_keys
c $9EE3 Test SPACE and CAPS SHIFT
D $9EE3 Zero if either is down.
R $9EE3 O:F Z if SPACE or CAPS SHIFT is down

@ $9EF5 label=dissolve_and_clear
c $9EF5 Dissolve the play area to black, then clear it
D $9EF5 The end of the death sequence (#R$F440): #R$9EFE, then #R$9F2C.

@ $9EFE label=dissolve_play_area
c $9EFE Dissolve the play area to black
D $9EFE The play area is 28 bytes by 160 lines from x=8 at its bottom line $B7, walked from the bottom up (#R$A1C3). Sixteen times over, every byte is ANDed with the next of the nine masks at #R$9F44, each clearing one bit (one clears none), the masks running on from byte to byte and line to line, so the picture loses its pixels in a scattered pattern rather than line by line.
R $9EFE HL The bottom left corner, as x and line
  $9EFE,11 Its screen address; sixteen times
  $9F09,9 Each line, 28 bytes
  $9F12,14 AND the bytes with the masks, round and round
  $9F20,7 The line above
  $9F27,5 Again

@ $9F2C label=clear_play_area
c $9F2C Clear the play area
D $9F2C 28 bytes by 160 lines from the bottom left corner (x=8, line $B7), upwards.

@ $9F44 label=dissolve_masks
b $9F44 The dissolve's masks
D $9F44 Nine masks (#R$9EFE), each with one bit clear but for $FF, and a 0 that sends the walk back to the first.
B $9F44,10,10

@ $9F4E label=check_pause
@ $9F5B label=pause
c $9F4E Pause while SPACE or CAPS SHIFT is pressed
D $9F4E Called once a pass from the play loop (#R$F440). Pressing SPACE or CAPS SHIFT pauses the game: it waits for the key to be let go, then for a second press, then for that to be let go too, and play goes on.
  $9F4E,6 Not pressed: go on
  $9F5B,8 Wait for the key to be let go...
  $9F63,8 ...then pressed again...
  $9F6B,6 ...and let go

@ $9F54 label=check_pause_in_play
c $9F54 Pause from the ship's routine
D $9F54 The same pause, called by #R$C3E3; before waiting it calls a routine inside #R$C3E3.

@ $9F71 label=pause_delay
c $9F71 A short delay
D $9F71 #R$A802 with D=$40, between the pause's key tests, so that a bouncing key is read once.

@ $9F76 label=font
b $9F76 The font
D $9F76 45 characters of seven bytes, stored bottom row first and drawn by #R$A0B1 from the bottom up: 0-25 the letters A to Z, 26-35 the digits 0-9 (so a digit's code is $1A plus the digit; add_score in #R$917C), 36 and 38 spaces, 37 the II of INTERFACE II (both letters in one cell), 39 a full stop, 40 a dash, and 41-44 four pieces of a small picture. Each row's bit 0 is clear, the space between characters.
B $9F76,315,7

@ $A0B1 label=print_char
c $A0B1 Print one character
D $A0B1 For #R$A115, which prints strings. The character's seven bytes are at #R$9F76 plus seven times its code. They are copied up the screen from the bottom row (#R$A0CB), or, for a double-size string, drawn twice as wide and tall by #R$A0DB: the JR here is the switch, its offset written by #R$A115 ($00 or $10). In the snapshot the offset is $FE, a jump to itself, but #R$A115 always writes it first.
R $A0B1 DE The character code's address
R $A0B1 HL The screen address of its bottom row
  $A0B1,20 The character's bytes
  $A0C5,4 Seven rows
  $A0C9,2 Normal or double size (written by #R$A115)

@ $A0CB label=print_char_rows
c $A0CB Copy a character's rows up the screen
D $A0CB The normal size: seven rows, the bottom first, each a line above the last (#R$A1C3). Then the colour in the other register set's B goes into the attribute at its HL, which moves on; and HL moves to the next character cell.
R $A0CB DE The character's bytes
R $A0CB HL The screen address of its bottom row
R $A0CB B 7
  $A0CB,8 Seven rows, upwards
  $A0D3,4 Its colour
  $A0D7,4 The next cell; DE back to the code
# Agent 4: $A0DB-$AE97 -- text printing, screen addresses, the sprite
# compositor (its buffer over the start-up code), the ship's direct-to-screen
# drawing, the ground-object records and their update, pick-ups, the ship's
# bounces. Second pass: the variables and patched entry points made entries.

@ $A0DB label=print_char_double
c $A0DB Print one character at double size
D $A0DB The double-size half of the character printer #R$A0B1, reached through its self-modified JR at the end of #R$A0B1 when #R$A115 has patched that JR's displacement to $10 for a string whose attribute byte has bit 7 set. Each of the glyph's seven rows (stored bottom row first) is split into its two nibbles; each nibble is doubled to a whole byte through the table #R$5C84 (bit n of the nibble becomes bits 2n and 2n+1), and the two bytes are written side by side on two pixel lines, so the character comes out 16 pixels wide and 14 lines high, drawn upwards from the line HL starts on.
D $A0DB HL must start on an odd pixel line within its cell (normally the bottom line, 7): the plain DEC H between the two lines of each row never crosses a cell boundary only because each pair starts on an odd line. Then a 2x2 block of attributes is coloured: the cell, the cell above, and the two to their right.
R $A0DB DE The glyph (7 bytes, bottom row first)
R $A0DB HL Screen address of the character's bottom-left byte
R $A0DB B' The attribute
R $A0DB DE' 32, one attribute row
R $A0DB HL' Attribute address of the character's bottom-left cell
  $A0DB,4 Seven rows; B is the page of the nibble-doubling table #R$5C84
  $A0DF,1 Keep the row count in A'
  $A0E0,13 The left half: the glyph byte's high nibble, doubled through the table
  $A0ED,4 Write it on this line and the one above
  $A0F1,8 The right half: the low nibble, doubled
  $A0F9,4 Write it on both lines too, and step back to the left column (now on the upper line)
  $A0FD,4 Next glyph row; move up one more pixel line
  $A101,4 Until all seven rows are drawn
  $A105,11 Colour the 2x2 block of cells: this one, the one above, above-right and right; HL' ends two cells on
  $A110,5 Restore the glyph pointer and step the screen address two columns on, for the next character
@ $A115 label=print_string
c $A115 Print a string
D $A115 Prints one string record and returns DE pointing at the next, so a list of strings can be printed by calling this again. The record is: x in pixels, y in pixels (the pixel line the characters' bottom rows go on), an attribute byte, a character count, and that many character codes. Bit 7 of the attribute byte asks for double size (#R$A0DB); the other seven bits are the colour, so a string can never FLASH. Character n's glyph is the seven bytes at #R$9F76 plus 7n, bottom row first.
R $A115 DE The string record
R $A115 O:DE The byte after it
  $A115,4 Normal size: point the character printer's JR (at the end of #R$A0B1) at the normal-size loop
  $A119,6 The x and y coordinates
  $A11F,5 Keep the pointer and coordinates; HL becomes the screen address
  $A124,6 In the other register set: HL' the attribute address, DE' the pointer to the attribute byte
  $A12A,5 Bit 7 of the attribute byte: double size?
  $A12F,11 Yes: patch the JR to reach #R$A0DB, strip bit 7, and keep DE' at 32 to step an attribute row up
  $A13A,1 The colour in B'
  $A13B,4 Back in the main set: B is the character count
  $A13F,8 Print each character (#R$A0B1 steps HL along)
  $A147,2 Point DE past the string
@ $A149 label=pixel_to_screen
c $A149 Turn pixel coordinates into a screen address
D $A149 The standard Spectrum screen-address calculation from a pixel position: L is x (0-255, its low three bits dropped) and H is y (0-191 from the top). Everything in the game that draws on the screen uses this.
R $A149 L x in pixels
R $A149 H y in pixels
R $A149 O:HL The screen byte containing the pixel
  $A149,10 The column, x divided by 8
  $A153,9 Bits 3-5 of y become bits 5-7 of the low byte
  $A15C,4 Bits 0-2 of y are the pixel line within the cell
  $A160,15 Bits 6-7 of y pick the third of the screen; combine with the pixel line
@ $A170 label=pixel_to_attribute
c $A170 Turn pixel coordinates into an attribute address
D $A170 The attribute that colours the pixel at (x, y): 22528 + 32 * (y / 8) + x / 8.
R $A170 L x in pixels
R $A170 H y in pixels
R $A170 O:HL The attribute address
  $A171,10 The column, x divided by 8
  $A17B,10 Bits 3-5 of y become bits 5-7 of the low byte
  $A185,6 Bits 6-7 of y become bits 0-1 of the high byte, in the attribute file
@ $A18D label=run_sky_object_handler
c $A18D Run a sky object's update routine
D $A18D Jumps to the update routine for the object in record IX, chosen by its graphic number (+0), which for the sky objects runs from $13 to $1E: the first twelve words of #R$A18D's table #R$AF25 are their handlers in that order. Called once for each live record of the nine sky-object records at #R$9974 every pass (#R$8D42), between the setting up of its erase (#R$AD27) and the drawing (#R$AD48 and #R$AD1B, which the handlers end with).
R $A18D IX The object's record
  $A18D,18 Index the handler table by graphic number less $13, and jump
@ $A19F label=graphic_frame_list
c $A19F Point DE at the frame list of a record's graphic
D $A19F Each graphic number has an entry in the graphic table, the words from the 25th byte of #R$AF25 on: the address of a list of words, one per frame or variant, each the address of a graphic. This returns that list for the record's graphic (+0). #R$ADBE goes one step further and picks the frame.
R $A19F IX The record
R $A19F O:DE The graphic's frame list
@ $A1AA label=table_word
c $A1AA Read word C of a table
R $A1AA HL The table
R $A1AA C The index
R $A1AA O:HL The word
@ $A1B3 label=line_up_de
c $A1B3 Move DE up one pixel line
D $A1B3 The same as #R$A1C3, for a screen address in DE.
R $A1B3 DE A screen address
@ $A1C3 label=line_up_hl
c $A1C3 Move HL up one pixel line
D $A1C3 Moves a screen address one pixel line up the screen: the line above within the cell, or the bottom line of the cell above, crossing into the third above when the row was the top of a third. Everything in the game draws bottom-up -- the graphics are stored bottom row first -- so this, and copies of it written inline in the sprite routines, are what step the drawing. About 47 T-states with the CALL, most of the time.
R $A1C3 HL A screen address
R $A1C3 O:HL The address one pixel line above
  $A1C3,6 Up a line; done unless that was the top line of the cell (the line number wrapped to 7)
  $A1C9,5 Back up a character row; done if that borrowed, which means the row is in the same third and H is right as it is
  $A1CE,5 Otherwise put H back into the third the row is in
@ $A1D3 label=old_sprite_x
g $A1D3 The old image's screen x
D $A1D3 The sprite compositor (#R$A303) handles a pair of images at a time: the image an object was drawn as last pass (the old, to be rubbed out) and the image it is to be drawn as now (the new). These six bytes, #R$A1D3 to #R$A1D8, hold them. This one is the old image's x on the screen, set by #R$AD27 from the record's +$11 (and by #R$C032 for a star), and read with the next byte as a word.
@ $A1D4 label=old_sprite_y
g $A1D4 The old image's screen y
D $A1D4 The line of the old image's bottom row, from the record's +$12, clipped to the play area's lines $18-$B7 by #R$A1FB through #R$A1EA.
@ $A1D5 label=new_sprite_x
g $A1D5 The new image's screen x
D $A1D5 Set by #R$ADD8 when it places an object on the screen, and kept in the record's +$11 for the next pass's erase.
@ $A1D6 label=new_sprite_y
g $A1D6 The new image's screen y
D $A1D6 The line of the new image's bottom row: set by #R$ADD8, clipped by #R$A1FB through #R$A1D9. #R$ACDD moves it up afterwards for the colour patch alone.
@ $A1D7 label=old_sprite_rows
g $A1D7 The old image's height
D $A1D7 Rows to rub out, after clipping; 0 when there is no old image (cleared by #R$A2EA, set by #R$A234). Others read it to tell whether an object was on the screen last pass (#R$AAD7, #R$8813, #R$8D42).
@ $A1D8 label=new_sprite_rows
g $A1D8 The new image's height
D $A1D8 Rows to draw, after clipping; 0 when there is no new image (cleared by #R$A2EA, set by #R$A247). #R$ACDD trims it for the colour patch, which #R$AE98 reads.
@ $A1D9 label=new_sprite_header
c $A1D9 Read the new image's graphic header and clip it
D $A1D9 Reads the width and height at the head of the new image's graphic and clips its rows to the play area (#R$A1FB), updating #R$A1D6.
R $A1D9 DE The graphic
R $A1D9 O:DE Its first row of data to draw (clipped)
R $A1D9 O:H Its width in bytes
R $A1D9 O:B Rows to draw
R $A1D9 O:C Which row routine it needs (see #R$A223)
@ $A1EA label=old_sprite_header
c $A1EA Read the old image's graphic header and clip it
D $A1EA As #R$A1D9, for the old image (#R$A1D3, #R$A1D4).
R $A1EA DE The graphic
@ $A1FB label=clip_sprite_rows
c $A1FB Clip a sprite's rows to the play area
D $A1FB Sprites are drawn upwards from their bottom row, inside the lines $18-$B7 (24 to 183): below the panel at the top and above the bottom row of the screen. A sprite reaching above line $18 has its height cut so that its top row is $18; one reaching below line $B7 has its bottom rows skipped (the graphic is stored bottom row first, so DE moves on by width times the rows cut) and its y put at $B7. A sprite wholly outside is not caught here; #R$ADD8 decides what is visible.
R $A1FB A y of the bottom row
R $A1FB B Height in rows
R $A1FB H Width in bytes
R $A1FB DE The graphic's rows
R $A1FB O:L The y to draw from
R $A1FB O:B The rows to draw
  $A1FB,6 Does the top row reach above line $18?
  $A201,5 Yes: draw only the rows from y up to line $18
  $A206,5 Does the bottom row lie below line $B7? Return if not
  $A20B,4 Rows below: take them off the height
  $A20F,10 Skip them in the graphic: width times the rows cut
  $A219,3 And draw from line $B7
@ $A21C label=read_graphic_size
c $A21C Read the width and height bytes at DE
R $A21C DE A graphic
R $A21C O:H Its width in bytes
R $A21C O:B Its height in rows
R $A21C O:DE Its data
@ $A223 label=read_graphic_header
c $A223 Read a graphic's header for the compositor
D $A223 A graphic is a width in bytes and a height in rows, then the rows, bottom row first, each the width in bytes, left to right; there is no mask. This also returns in C the index into the row-routine tables #R$A294 and #R$A2AA: the width less one when the sprite is drawn shifted (x AND 6 not zero), the width plus four when it is byte-aligned -- so 0-4 are the shifted routines for widths 1-5 and 5-10 the aligned ones for widths 1-6.
R $A223 DE The graphic
R $A223 L The x it is to be drawn at
R $A223 O:H Width in bytes
R $A223 O:B Height in rows
R $A223 O:C The row routine's index
R $A223 O:DE The first row
  $A22B,4 Shifted: index width-1
  $A22F,4 Byte-aligned: index width+4
@ $A234 label=set_old_sprite
c $A234 Set up the old image's erase
D $A234 Records the old image's height (#R$A1D7) and width (#R$5C28, which #R$A303 turns to pixels) and chooses the routine that rubs one of its rows out of the buffer (#R$A294) into IY, and its shift table page into B.
R $A234 B Height
R $A234 H Width in bytes
R $A234 C Row routine index (#R$A223)
R $A234 O:IY The erase-row routine
R $A234 O:B The shift tables' page (#R$A25D)
@ $A247 label=set_new_sprite
c $A247 Set up the new image's draw
D $A247 As #R$A234 for the new image: its height (#R$A1D8) and width, its draw-row routine from #R$A2AA into IX, and its shift page into B.
R $A247 B Height
R $A247 H Width in bytes
R $A247 C Row routine index (#R$A223)
R $A247 O:IX The draw-row routine
R $A247 O:B The shift tables' page
@ $A25D label=shift_page
c $A25D The shift tables' page for the old image
D $A25D B becomes $F8 plus x AND 6: $FA, $FC or $FE for an image at 2, 4 or 6 pixels past a byte, the pages of the shift tables #R$FA00 that #R$F86B builds (on the first page of each pair a byte shifted right that many bits, on the page after it the bits that fall into the next byte). $F8 for a byte-aligned image is never used as a table. The second instruction is also an entry, used by #R$A247: the same for the x in A.
R $A25D O:B The page
@ $A266 label=set_direct_new
c $A266 Set up the new image for the direct drawer
D $A266 For #R$A59F, the drawer that works straight on the screen: the new image's bottom line (#R$A28A, from the sprite position word in #R$BF7F), its height (#R$5C1D) and width (#R$5C29), and the screen address of its bottom-left byte.
R $A266 B Height
R $A266 H Width
R $A266 O:HL Screen address
@ $A27A label=set_direct_old
c $A27A Set up the old image for the direct drawer
D $A27A As #R$A266 for the old image (#R$A289), without the screen address.
R $A27A B Height
R $A27A H Width
@ $A289 label=direct_old_line
g $A289 The direct drawer's old image's bottom line
D $A289 Set by #R$A27A or #R$C3E3; #R$A59F compares it with #R$A28A to line the two images up, then reuses it for the old image's rows left over.
@ $A28A label=direct_new_line
g $A28A The direct drawer's new image's bottom line
D $A28A Set by #R$A266 or #R$C3E3; reused by #R$A59F for the new image's rows left over.
@ $A28B label=record_screen_address
c $A28B The screen address of the position at +$0B and +$0C of record IX
D $A28B Used for the player's shots (#R$B414, #R$B483, #R$B5AF, #R$B628), whose x and y are kept there.
R $A28B IX The record
R $A28B O:HL The screen address
@ $A294 label=erase_row_routines
b $A294 The compositor's erase-row routines
D $A294 Eleven words, indexed by #R$A223's routine index (#R$A234 reads them): the entry points into the unrolled loops that rub one row of an old image out of the buffer. Indexes 0-4 are the shifted loop #R$A6E1 for widths 1-5, entered so many byte-steps from its end; 5-10 the byte-aligned loop #R$A6B2 for widths 1-6.
W $A294,22 Shifted widths 1-5, then aligned widths 1-6
@ $A2AA label=draw_row_routines
b $A2AA The compositor's draw-row routines
D $A2AA As #R$A294, for drawing the new image (#R$A247): the shifted loop #R$A75C for widths 1-5, the byte-aligned loop #R$A733 for widths 1-6.
W $A2AA,22 Shifted widths 1-5, then aligned widths 1-6
@ $A2C0 label=add_record_size
c $A2C0 Add or take off a record's size (unused)
D $A2C0 Two small routines that nothing in the program refers to, and that never ran in the build's sessions: this one adds +5 to +2 and +6 to +3 of record IX; the one 21 bytes on takes them off. A leftover.
R $A2C0 IX A record
@ $A2EA label=clear_sprite_pair
c $A2EA Start a new sprite pair: no old image, no new image
D $A2EA Called before each object's erase and draw is set up: both heights (#R$A1D7, #R$A1D8) and both widths 0, and the left-clip flag (#R$A2FA) clear.
@ $A2F8 label=old_sprite_width
g $A2F8 The old image's width in bytes
D $A2F8 Kept by #R$A303 before it turns the working copies of both widths (#R$5C28, #R$5C29) into pixels; read by #R$A43E. Written as a word with #R$A2F9.
@ $A2F9 label=new_sprite_width
g $A2F9 The new image's width in bytes
D $A2F9 Kept by #R$A303; read by #R$A43E and #R$A498.
@ $A2FA label=sprite_left_clip
g $A2FA The compositor's left-clip flag
D $A2FA Not zero while the pair is drawn straddling the left edge of the play area: set by #R$ADD8 for the new image and by #R$AD27 (from +$10 bit 6) for the old, cleared by #R$A2EA. #R$A303 then works with both x positions $60 less, and copies only the part of the box right of the edge. #R$9143 and #R$AE98 read it too.
@ $A2FB label=dissolve_mask_bits
b $A2FB The dissolve masks
D $A2FB Seven masks, one for each step of an object's dissolving (#R$A498, indexed from #R$A2FA so that step 1 is the first): each has one bit fewer set than the last, from seven bits down to one.
B $A2FB,7,1 Steps 1 to 7
@ $A302 label=dissolve_step
g $A302 The new image's dissolve step
D $A302 0, or bit 7 and the step 1-7 while the object dissolves: set by #R$AD48 from the record's +$17, read by #R$A498.
@ $A303 label=draw_sprite_pair
c $A303 Rub out an object's old image and draw its new one, without flicker
D $A303 The sprite compositor, which draws every ground object and sky object, and the stars (#R$C032): about a third of all the game's time goes through here. Both images are worked on in a buffer, never on the screen, and the screen is written once, so nothing flickers. The steps:
D $A303 1. The box: the smallest rectangle, whole bytes wide, covering both images: its left edge (#R$5C2C) and bottom line (#R$5C2D), and its width in bytes (at most 7) and height plus one, kept in #R$CE35 and #R$CE37. If only one image is present, the other's position is taken as its own.
D $A303 2. Copy the box from the screen into the buffer (#R$A3F6), bottom row first, rows packed at the box's width. The buffer is page $F8, in the middle of the start-up code that runs once from #R$F7EB and is no longer wanted; the drawing addresses it by L alone, so the box can be no more than 256 bytes.
D $A303 3. Rub out the old image in the buffer: AND each byte with the complement of the graphic, shifted to the image's x (#R$A43E, #R$A6B2, #R$A6E1). This clears every pixel the graphic sets, whatever was under it; there is no mask, and nothing restores what the old image covered.
D $A303 4. Draw the new image into the buffer: OR (#R$A733, #R$A75C). Then, if the object is dissolving, AND its rows with that step's mask (#R$A498).
D $A303 5. Copy the box back to the screen (the end of #R$A498 onwards), clipped to the play area: column 0 is never written, nor anything right of x=$E8 (the fuel gauge's columns).
D $A303 Graphics are not pre-shifted. An image at x AND 6 = 2, 4 or 6 is shifted as it is drawn, each byte through a pair of 256-byte tables (#R$FA00); x is always even. The loops are unrolled, with patched entry points: the row loops are entered so many steps from their ends (#R$A294, #R$A2AA), and the copies are LDI chains entered by DJNZs whose displacements are patched (see #R$A3F6).
D $A303 A sprite straddling the left edge of the play area (#R$A2FA) is handled by taking $60 off both x positions, which moves positions either side of 0 into one unbroken range; only the part of the box right of the edge, at x=8, is copied in and out (#R$A3CF, #R$A524).
D $A303 The cost, worked out from the instructions: for a 3-byte-wide sprite 16 rows tall, moved and shifted, a 5-byte box of 17 rows, about 2,500 T-states to copy in, 4,500 to rub out, 4,100 to draw, 2,500 to copy out -- some 13,500 in all, a fifth of a frame.
R $A303 DE The new image's first row (#R$A1D9)
R $A303 B The new image's shift page (#R$A247)
R $A303 IY The old image's erase-row routine (#R$A234)
R $A303 IX The new image's draw-row routine (#R$A247)
R $A303 DE' The old image's first row
R $A303 B' The old image's shift page
  $A303,2 Keep the new image's graphic and page (restored at #R$A43E)
  $A305,12 Keep both widths in bytes; turn the working copies into pixels
  $A311,12 No old image: give it the new one's position, so the box is the new image's alone
  $A31D,12 No new image: give it the old one's
  $A329,22 Left-clip mode: take $60 off both x positions
  $A33F,16 The box's bottom line is the lower of the two bottom lines
  $A34F,13 The line above the box's top: the smaller of each image's y less its height
  $A35C,6 The box's rows, plus one
  $A362,18 The box's left edge: the smaller x, rounded down to a byte
  $A374,15 The further right edge of the two, from the box's left edge
  $A383,12 The box's width in bytes, rounding up (x is always even, so 6 is enough)
  $A38F,7 Not straddling the left edge: copy the whole box in (#R$A3F6)
  $A396,11 Straddling: the bytes of the box right of the play area's edge (x=8, now $A8)
  $A3A1,11 Skip the rest in the buffer at the end of each row; start that far into the buffer
  $A3AC,13 Patch the DJNZs of the clipped copies in and out to copy that many bytes
  $A3B9,12 The screen address of the box's bottom row at the play area's left edge
  $A3C5,4 The box's rows plus one
  $A3C9,1 Keep this row's screen address
  $A3CA,2 The DJNZ whose patched displacement enters the chain of LDIs at #R$A3CF, and leaves when the rows are done
  $A3CC,3 Then rub out and draw
@ $A3CF label=copy_in_clipped
c $A3CF Copy a clipped row into the buffer
D $A3CF The row loop of the clipped copy into the buffer, for a box straddling the left edge of the play area: entered from the DJNZ at the end of #R$A303, so many LDIs before the end of this chain as there are bytes on the screen, then the rest of the buffer's row skipped and the screen address moved up a line. The first LDI is reached only with the full six bytes, which never happened in the build's sessions.
  $A3CF,12 Copy the row's bytes from the screen to the buffer (C is $FF, so the LDIs never touch B)
  $A3DB,4 Skip the part of the buffer's row left of the edge (the LD's operand is patched by #R$A303)
  $A3DF,23 Back to the row's start, and up one pixel line; then round again
@ $A3F6 label=copy_box_in
c $A3F6 Copy the box from the screen into the buffer
D $A3F6 The rows are copied bottom-up into the buffer at page $F8. The loop is three pieces: PUSH HL keeps the row's screen address; a DJNZ whose displacement is patched to land in the LDI chain of #R$A419 as many LDIs from its end as the box is bytes wide (7 less the width, times two, plus three to clear the JP); and the chain's end, which pops the address, moves it up a line and jumps back to the PUSH. When B runs out the DJNZ falls through to the JP instead, with one address left on the stack for #R$A43E to drop. C is $FF so that the LDIs' count of BC never reaches B.
R $A3F6 H The box's bottom line
R $A3F6 L The box's left edge
  $A3F6,17 Point DE at the buffer; patch this copy's DJNZ and the copy out's (#R$A54B) for the box's width
  $A407,6 The screen address of the box's bottom-left byte, kept for the copy back
  $A40D,6 C $FF; B the rows plus one
  $A413,6 Keep the address; copy a row (or, when the rows are done, go on to #R$A43E)
@ $A419 label=copy_in_row
c $A419 Copy a row of the box into the buffer
D $A419 The LDI chain and row step of #R$A3F6, entered part way through.
  $A419,14 Up to seven bytes from the screen to the buffer
  $A427,23 Back to the row's start and up one pixel line; then round again
@ $A43E label=erase_old_draw_new
c $A43E Rub out the old image in the buffer, then draw the new one
D $A43E The middle of #R$A303. The register sets are swapped so that the main set holds the old image's graphic and shift page (saved by the EXX after #R$AD27) while the new image's wait in the other set. Each row routine finishes by adding the patched step to L (the box's width less the bytes the routine covered), counting the rows in A', and either jumping back through IY (or IX) for the next row or on to the next stage.
  $A43E,1 Drop the unused screen address left by the copy in
  $A43F,3 Restore the new image's graphic and page, and swap them out of the way
  $A442,7 No old image: straight on to drawing the new one
  $A449,6 Where the old image starts in the buffer
  $A44F,10 The bytes a row covers: the width, less one if byte-aligned (a shifted row spills into one more byte)
  $A459,10 The step from the end of one row to the start of the next, into both erase loops
  $A463,6 Rub out the old image's rows (A' counts them)
  $A469,1 Swap to the new image's graphic and page
  $A46A,7 No new image: copy the box back
  $A471,6 Where the new image starts in the buffer
  $A477,10 The bytes a row covers
  $A481,10 The step to the next row, into both draw loops
  $A48B,4 The dissolve's step (#R$A498) is one less, as it covers one byte more
  $A48F,3 Keep the start for the dissolve, in #R$BA8D
  $A492,6 Draw the new image's rows
@ $A498 label=dissolve_sprite
c $A498 Break up a dissolving object's image
D $A498 An object that has been destroyed dissolves over seven passes (#R$AD48): its new image, just drawn into the buffer, is ANDed with that step's mask from #R$A2FB, rotated a bit to the right at every byte so the gaps do not line up in columns. The masks keep seven bits, then six, down to one, so the object crumbles away.
  $A498,7 Not dissolving: go and copy the box back
  $A49F,9 D is the mask for this step
  $A4A8,3 The new image's start in the buffer
  $A4AB,17 The bytes a row covers (one more if the image is not on a byte boundary), and the rows
  $A4BC,8 AND each byte with the mask, turning the mask a bit each byte
  $A4C4,7 On to the next row (the LD's operand is patched by #R$A43E)
  $A4CB,7 The copy back: the screen address of the box, and the buffer
  $A4D2,13 Straddling the left edge: copy just the part right of it, as #R$A303 worked out
  $A4DF,7 B is the box's width in pixels
  $A4E6,6 Does the box start at column 0?
  $A4EC,7 Does it reach past x=$E8, the right edge of the play area? If not, copy all of it (#R$A54B)
  $A4F5,8 From column 0: leave the frame column out, and copy the rest
  $A4FD,9 Past the right edge: copy only the bytes left of x=$E8
  $A506,18 Patch the step and the DJNZ for that many bytes
  $A518,6 C $FF; B the rows plus one
  $A51E,6 Keep the row's screen address; copy a row (#R$A524) or finish
@ $A524 label=copy_out_part_row
c $A524 Copy part of a row from the buffer to the screen
D $A524 The LDI chain of the clipped copy back (from the DJNZ at the end of #R$A498), for a box cut by an edge of the play area.
  $A524,12 Up to six bytes from the buffer to the screen
  $A530,4 Skip the rest of the buffer's row (the LD's operand is patched)
  $A534,23 Back to the row's start on the screen, up one pixel line, and round again
@ $A54B label=copy_box_out
c $A54B Copy the whole box from the buffer to the screen
R $A54B DE The screen address of the box's bottom-left byte
R $A54B HL The buffer
  $A54B,6 B the rows plus one; C $FF
  $A551,6 Keep the row's screen address; copy a row (the DJNZ's displacement patched by #R$A3F6) or finish
@ $A557 label=copy_out_row
c $A557 Copy a row of the box from the buffer to the screen
D $A557 Reached from #R$A54B by the DJNZ there, whose displacement #R$A3F6 patches so that it
. lands on the LDI that copies just the box's width: one LDI per byte, up to seven. Then the
. row's screen address comes back off the stack, moves up a pixel line (crossing a character
. row or a third of the screen as needed), and the loop goes round again at #R$A54B's DJNZ.
  $A557,14 Up to seven bytes
  $A565,23 Back to the row's start, up one pixel line, and round again
@ $A57C label=copy_out_done
c $A57C Finish the copy back
D $A57C Drops the screen address the last time round the copy loop left on the stack, and returns from #R$A303.
@ $A57E label=buffer_address
c $A57E Turn a sprite position into an address in the buffer
D $A57E The buffer holds the box bottom row first, each row the box's width: a position's byte is (x less the box's left edge) / 8, plus (the box's bottom line less y) rows.
R $A57E L x
R $A57E H y
R $A57E O:HL The byte in the buffer, page $F8
  $A57E,13 The byte within the row
  $A58B,17 Add a row's width for each line above the box's bottom
@ $A59F label=draw_direct_pair
c $A59F Rub out the old image and draw the new one, straight on the screen
D $A59F The other sprite drawer, for the player's ship (#R$C3E3), the carried rocket part (#R$C27F) and the lift jet (#R$C6D2): no buffer, but the rows of the old image's erase and the new image's draw interleaved -- one row rubbed out, one drawn, both moving up the screen -- so no part of the ship is missing for long. The images are byte-aligned (no shift tables); a ship facing left is drawn right to left through the bit-reversing table on page $F9 (#R$A7A4, #R$A7D6). Erase is AND NOT the graphic, draw is OR, as in #R$A303.
D $A59F The old image is in the alternate register set (HL' its screen address, DE' its graphic, IY its row routine, its rows in #R$5C1C), the new in the main set (HL, DE, IX, its rows in #R$5C1D). When their bottom lines (#R$A289, #R$A28A) differ, the rows below the higher one's bottom are done first on their own, so that the two then move up in step.
R $A59F HL The new image's screen address
R $A59F DE The new image's graphic
R $A59F IX The new image's draw-row routine
R $A59F HL' The old image's screen address
R $A59F DE' The old image's graphic
R $A59F IY The old image's erase-row routine
  $A59F,10 Keep each image's column, to come back to at every row
  $A5A9,4 A' counts the new image's rows
  $A5AD,25 Either image absent, or both on the same bottom line: interleave all the rows
  $A5C8,16 The old image is lower: its rows below the new one's bottom are rubbed out alone first
  $A5D8,5 No new rows meanwhile
  $A5DD,14 Then the rest of both, interleaved
  $A5EB,12 The new image is lower: its rows below the old one's bottom are drawn alone first
  $A5F7,13 No old rows meanwhile
  $A604,13 Then the rest of both
@ $A611 label=direct_old_rows_only
c $A611 Rub out another row of the old image, the new one being finished
@ $A61C label=direct_next_pair
c $A61C Rub out a row of the old image, then draw a row of the new
D $A61C The loop of #R$A59F: rub out a row of the old image (through IY, in the alternate set), then draw a row of the new (through IX, in the main set); when the old image's rows run out, draw the new one's alone (#R$A669), and when the new one's do, rub out the old one's alone (#R$A611).
@ $A629 label=direct_erase_row
c $A629 Rub a row of a 6-byte-wide image off the screen
D $A629 One row of the old image in #R$A59F, AND NOT each byte, left to right, in six byte-steps that run on into each other (#R$A629, #R$A62F, #R$A635, #R$A63B, #R$A641, #R$A647); then the screen address goes back to the image's column and up a line. IY enters at the step for the image's width: here for six bytes.
  $A629,6 The first byte, ANDed with its complement
@ $A62F label=direct_erase_five
c $A62F Rub a row of a 5-byte-wide image off the screen
D $A62F The entry into #R$A629's row for an image five bytes wide.
  $A62F,6 Rub out a byte
@ $A635 label=direct_erase_four
c $A635 Rub a row of a 4-byte-wide image off the screen
D $A635 The entry into #R$A629's row for an image four bytes wide.
  $A635,6 Rub out a byte
@ $A63B label=direct_erase_three
c $A63B Rub a row of a 3-byte-wide image off the screen
D $A63B The entry into #R$A629's row for an image three bytes wide.
  $A63B,6 Rub out a byte
@ $A641 label=direct_erase_two
c $A641 Rub a row of a 2-byte-wide image off the screen
D $A641 The entry into #R$A629's row for an image two bytes wide.
  $A641,6 Rub out a byte
@ $A647 label=direct_erase_one
c $A647 Rub a row of a 1-byte-wide image off the screen, and move up a line
D $A647 The last byte-step of #R$A629's row, and the row's end, which the mirrored erase (#R$A7A4) shares.
  $A647,5 Rub out the last byte
  $A64C,29 Back to the image's column, up one pixel line (keeping the new column when a character row is crossed), then a row of the new image
@ $A669 label=direct_new_rows_only
c $A669 Draw another row of the new image, the old one being finished
@ $A66F label=direct_then_new_row
c $A66F Count a row of the new image and draw it
D $A66F After a row of the old image: if the new image has rows left, swap to its registers and draw one; if not, carry on with the old image alone (#R$A611).
@ $A678 label=direct_draw_row
c $A678 Draw a row of a 6-byte-wide image on the screen
D $A678 One row of the new image in #R$A59F, ORed onto the screen left to right in six byte-steps (#R$A678, #R$A67D, #R$A682, #R$A687, #R$A68C, #R$A691); then back to the image's column and up a line. IX enters at the step for the image's width: here for six bytes.
  $A678,5 The first byte ORed on
@ $A67D label=direct_draw_five
c $A67D Draw a row of a 5-byte-wide image on the screen
D $A67D The entry into #R$A678's row for an image five bytes wide.
  $A67D,5 OR on a byte
@ $A682 label=direct_draw_four
c $A682 Draw a row of a 4-byte-wide image on the screen
D $A682 The entry into #R$A678's row for an image four bytes wide.
  $A682,5 OR on a byte
@ $A687 label=direct_draw_three
c $A687 Draw a row of a 3-byte-wide image on the screen
D $A687 The entry into #R$A678's row for an image three bytes wide.
  $A687,5 OR on a byte
@ $A68C label=direct_draw_two
c $A68C Draw a row of a 2-byte-wide image on the screen
D $A68C The entry into #R$A678's row for an image two bytes wide.
  $A68C,5 OR on a byte
@ $A691 label=direct_draw_one
c $A691 Draw a row of a 1-byte-wide image on the screen, and move up a line
D $A691 The last byte-step of #R$A678's row, and the row's end, which the mirrored draw (#R$A7D6) shares.
  $A691,4 OR on the last byte
  $A695,29 Back to the column, up one pixel line, then a row of the old image
@ $A6B2 label=erase_aligned_row
c $A6B2 Rub a byte-aligned row out of the buffer
D $A6B2 One row of the old image in #R$A303: each byte of the graphic, complemented, ANDed into the buffer. Entered so many steps from the end as the graphic is wide (#R$A294). The first step, for a graphic six bytes wide, was never run in the build's sessions.
  $A6B2,35 Up to six bytes
  $A6D5,4 To the next row up (the step is patched by #R$A43E)
  $A6D9,8 Count the row; when they are done, go and draw the new image
@ $A6E1 label=erase_row_shifted
c $A6E1 Rub a shifted row out of the buffer
D $A6E1 One row of a shifted old image: each graphic byte is looked up in the shift tables (B their page, C the byte), the part that stays in this byte at B and the part that falls into the next at B+1, each complemented and ANDed in. So a row of n graphic bytes covers n+1 bytes. About 79 T-states a graphic byte.
  $A6E1,70 Up to five bytes, each split over two
  $A727,4 To the next row up (the step is patched)
  $A72B,8 Count the row; when they are done, draw the new image
@ $A733 label=draw_aligned_row
c $A733 Draw a byte-aligned row into the buffer
D $A733 One row of the new image in #R$A303, ORed in, entered through #R$A2AA. The first step, for a graphic six bytes wide, was never run in the build's sessions.
  $A733,29 Up to six bytes
  $A750,4 To the next row up (the step is patched)
  $A754,8 Count the row; when they are done, go on to the dissolve and the copy back
@ $A75C label=draw_row_shifted
c $A75C Draw a shifted row into the buffer
D $A75C As #R$A6E1, ORing the two parts of each byte in. About 71 T-states a graphic byte.
  $A75C,60 Up to five bytes, each split over two
  $A798,4 To the next row up (the step is patched)
  $A79C,8 Count the row; when they are done, go on
@ $A7A4 label=direct_erase_row_mirrored
c $A7A4 Rub a row of a mirrored 6-byte-wide image off the screen
D $A7A4 As #R$A629, for the ship facing left: each graphic byte is reversed through the table on page $F9 (B is $F9) and the row is worked right to left, in six byte-steps (#R$A7A4, #R$A7AC, #R$A7B4, #R$A7BC, #R$A7C4, #R$A7CC), entered by width (#R$BF85 and other callers).
  $A7A4,8 The first byte, reversed and ANDed out
@ $A7AC label=mirrored_erase_five
c $A7AC Rub a row of a mirrored 5-byte-wide image off the screen
D $A7AC The entry into #R$A7A4's row for an image five bytes wide.
  $A7AC,8 Rub out a byte
@ $A7B4 label=mirrored_erase_four
c $A7B4 Rub a row of a mirrored 4-byte-wide image off the screen
D $A7B4 The entry into #R$A7A4's row for an image four bytes wide.
  $A7B4,8 Rub out a byte
@ $A7BC label=mirrored_erase_three
c $A7BC Rub a row of a mirrored 3-byte-wide image off the screen
D $A7BC The entry into #R$A7A4's row for an image three bytes wide.
  $A7BC,8 Rub out a byte
@ $A7C4 label=mirrored_erase_two
c $A7C4 Rub a row of a mirrored 2-byte-wide image off the screen
D $A7C4 The entry into #R$A7A4's row for an image two bytes wide.
  $A7C4,8 Rub out a byte
@ $A7CC label=mirrored_erase_one
c $A7CC Rub a row of a mirrored 1-byte-wide image off the screen
D $A7CC The last byte-step of #R$A7A4's row; the row ends in #R$A647.
  $A7CC,7 Rub out the last byte
  $A7D3,3 Up a line, then a row of the new image
@ $A7D6 label=direct_draw_row_mirrored
c $A7D6 Draw a row of a mirrored 6-byte-wide image on the screen
D $A7D6 As #R$A678, mirrored as #R$A7A4, in six byte-steps (#R$A7D6, #R$A7DD, #R$A7E4, #R$A7EB, #R$A7F2, #R$A7F9), entered by width (#R$BFB8 and other callers).
  $A7D6,7 The first byte, reversed and ORed on
@ $A7DD label=mirrored_draw_five
c $A7DD Draw a row of a mirrored 5-byte-wide image on the screen
D $A7DD The entry into #R$A7D6's row for an image five bytes wide.
  $A7DD,7 OR on a byte
@ $A7E4 label=mirrored_draw_four
c $A7E4 Draw a row of a mirrored 4-byte-wide image on the screen
D $A7E4 The entry into #R$A7D6's row for an image four bytes wide.
  $A7E4,7 OR on a byte
@ $A7EB label=mirrored_draw_three
c $A7EB Draw a row of a mirrored 3-byte-wide image on the screen
D $A7EB The entry into #R$A7D6's row for an image three bytes wide.
  $A7EB,7 OR on a byte
@ $A7F2 label=mirrored_draw_two
c $A7F2 Draw a row of a mirrored 2-byte-wide image on the screen
D $A7F2 The entry into #R$A7D6's row for an image two bytes wide.
  $A7F2,7 OR on a byte
@ $A7F9 label=mirrored_draw_one
c $A7F9 Draw a row of a mirrored 1-byte-wide image on the screen
D $A7F9 The last byte-step of #R$A7D6's row; the row ends in #R$A691.
  $A7F9,6 OR on the last byte
  $A7FF,3 Up a line, then a row of the old image
@ $A802 label=delay
c $A802 Wait
D $A802 A delay loop: D times 255 turns of DEC E / JR NZ, about 4,100 T-states for each unit of D (D=0 counts 256).
R $A802 D How long
@ $A80B label=ground_objects
b $A80B The ground-object records
D $A80B Six records of 26 bytes for the things lying on the landscape: these four for the objects placed from the map (#R$5C94) -- the installations that can be shot, collided with, landed on, mined -- and two (#R$A873, #R$A88D) for the pick-ups, which have bit 7 of +3 set. #R$AC60 updates and draws them, #R$A8F4 tests the ship against these four, #R$ABA8 the special beam against them. The map code (#R$DF08) fills them as the view reaches them.
D $A80B The fields, as far as this range uses them (the first $18 bytes are the same as the sky objects' records at #R$9974, and the same routines place and draw both):
D $A80B +0 the graphic number ($FF a free record), the index into the graphic table (the words from the 25th byte of #R$AF25). +1 the page column and +2 the x within it (bit 0 ignored); +4 the page row and +5 the y of the bottom row within it -- see #R$ADD8 for the pages. +3 bit 7: a pick-up. +7 to +$0A and +$0B, +$0C, +$0E, +$0F: cleared when the record is freed (#R$AC34; movement, not used here). +$0D the colours, two attributes in its nibbles, shown on alternate passes (#R$AD48). +$10 flags: bit 7 drawn on the screen last pass, bit 6 drawn straddling the left edge, bit 4 to be rubbed out and freed. +$11 and +$12 the screen x and y it was drawn at. +$13 bits 0-3 the frame of the graphic, which for graphic $0D is also the object's kind (from #R$5C94; kind $0B is never collided with); for graphic $1B, the animated objects, the frame byte from #R$E10E -- bits 4-5 a count and 6-7 its reload, with +$14 the frames it runs through (#R$910A) -- and frames 4 and 5 are the fuel station's (map kind $0E), the refuel pad of #R$A8F4. +$15 bit 7: #R$910A animates it. +$17 bit 3 dissolving and bits 0-2 the step. +$18 bits 1-3 not zero: the kind of shot it fires (#R$8820); +$18 bit 0 and +$19 the number of its byte in #R$5C94, where it is marked gone.
B $A80B,104,13 One record every two lines
@ $A873 label=pickup_record
b $A873 The first pick-up record
D $A873 Laid out as #R$A80B, with bit 7 of +3 set: a pick-up -- an add-on for the ship, a rocket part, or the slab and the spire of the load let go (#R$C1CE) -- taken by touching it (#R$AAD7) rather than shot or bumped. Filled by the map code (#R$DF08) and #R$C1AC.
B $A873,26,13 The record
@ $A88D label=second_pickup_record
b $A88D The second pick-up record
D $A88D As #R$A873. Its 26 bytes run two past this block: its +$18 and +$19 are the first two bytes of the routine #R$A8A5. Those two fields are read only for records without bit 7 of +3, so for a pick-up they are never looked at. #R$AAD7 empties it (bit 4 of +$10) when it takes the first piece of a part let go.
B $A88D,24,12 The record, less its last two bytes
@ $A8A5 label=load_ore
c $A8A5 Load ore into the carried ore tank
D $A8A5 Only while the rocket part the ship carries (+$1A of the player's record #R$F5E7) is part 6, the ore tank: adds one or two units (one for an ore kind 8 or 9, two for kind $0A, from bit 1 of A) to the ore aboard (the byte after the ship record in #R$C891), at most 18 -- a full tank, which #R$9724 waits for before letting the part go; clears the new rows on the screen, two bytes at x=$70 above the old level from the ship's bottom line; and redraws the level in the ship's picture (the entry at the eighth instruction from the end of the clearing): the ore's rows, bottom up, from the 2-byte-wide graphic after #R$76E9 into bytes 2 and 3 of each row of #R$F6B9.
D $A8A5 Called with the special beam's record by #R$B5AF, which carries the ore kind in +$13 (#R$ABA8), and with A by #R$917C at the second instruction. Only the redraw ran in the build's sessions (from #R$AFE9 and #R$DCA1).
D $A8A5 A bug, read only: the clearing loop moves DE up a line (#R$A1B3) but writes through HL, so it clears the same two bytes every time.
R $A8A5 IX A record whose +$13 not zero lets it run
  $A8A5,5 Nothing to do if +$13 is zero
  $A8AA,6 One unit for A=0 or 1 (with the kind's bits 0-3: 8 or 9), two for 2 or 3 ($0A)
  $A8B0,6 Only while the ore tank is carried
  $A8B6,14 Load it, to 18 units at most
  $A8C4,10 The screen address of the first new row in the ship, at x=$70
  $A8CE,11 Clear two bytes for each new row (but see above)
  $A8D9,11 The entry from #R$AFE9 and #R$DCA1: draw the ore aboard into the ship's picture
  $A8E4,15 Two bytes a row from the ore graphic into bytes 2 and 3 of each six-byte row of the picture
@ $A8F4 label=ship_hits_ground_objects
c $A8F4 Test the ship against the ground objects
D $A8F4 Once a pass (#R$C374). The ship's box is 40 pixels wide from x=$64 and as high as its picture, at its y, both less this pass's scroll steps (#R$CCBA: across, up and down). Each of the first four ground-object records that is on the screen, between line $28 and the bottom and between x=$30 and $A0, and not of kind $0B, is boxed by its last drawn position and its graphic's size, and tested (#R$9DB1). At the first one that touches:
D $A8F4 A refuel pad -- graphic $1B in frame 4 or 5, the fuel station's two frames (map kind $0E, #R$E10E) -- fills the fuel (#R$CC4B), is used up (freed next pass and marked gone in #R$5C94), and repairs the ship: the hit count (#R$8FC3) is set to $FF before calling the damage handler in #R$8F54, whose count then wraps to 0 and colours the ship white again. This branch never ran in the build's sessions.
D $A8F4 Anything else is solid: the collision flag #R$D0BC is set (so #R$C3E3 redraws the ship's trail), and the ship bounces -- across (#R$AA01) if the object lies beyond either side of the ship, up or down (#R$AA15) if the ship's top is level with or below the object's bottom, and again up or down if, while the vertical scroll step is not positive, the ship's bottom is within nine lines below the object's top.
  $A8F4,5 Not once the rocket is launching (#R$96AB)
  $A8F9,6 The four records
  $A8FF,22 The ship's box: x=$64 and y less the scroll steps
  $A915,10 40 pixels wide, the ship's height tall (kept in #R$BA09)
  $A922,7 A free record
  $A929,10 Kind $0B is never collided with
  $A933,7 Not on the screen
  $A93A,22 Only from line $28 down and between x=$30 and $A0
  $A950,19 Box the object: where it was drawn, its graphic's width in pixels and height
  $A963,18 Test the two boxes
  $A975,6 Touching?
  $A97B,13 Next record
  $A988,24 A refuel pad, graphic $1B in frame 4 or 5 (the fuel station)?
  $A9A0,6 Fill the fuel
  $A9A6,4 Free the pad next pass
  $A9AA,15 And mark it gone in the world's object table
  $A9B9,11 Repair the ship: the hit count wraps to zero in the damage handler, which colours the ship white
  $A9C4,5 Something solid was hit
  $A9C9,19 The object's box (IX is the box now) beyond x=$8B or ending short of x=$65: bounce across
  $A9DC,12 The ship's top level with the object's bottom or lower: bounce up or down
  $A9E8,9 Not while the vertical scroll step is positive
  $A9F1,12 The ship's bottom within nine lines below the object's top: bounce up or down
@ $AA01 label=bounce_across
c $AA01 Bounce the ship across
D $AA01 Reverses and halves the ship's step across (+7 of the ship record, #R$C8EC, #R$AA27) and reverses this pass's scroll step across (#R$CCBB).
@ $AA15 label=bounce_up_down
c $AA15 Bounce the ship up or down
D $AA15 Reverses and halves the ship's step down (+9 of the ship record, #R$C8EE, #R$AA27), and passes the new value to the entry near the end of #R$B234 that moves the ship by it.
@ $AA27 label=reverse_speed
c $AA27 Reverse and halve a step
D $AA27 The ship's step words are kept high byte first, so the bytes are swapped round either side: negate (#R$BE08), halve (#R$BE03), and let #R$BA0B cut a small result to nothing.
R $AA27 HL The step word as stored
R $AA27 O:HL The new step, stored the same way
@ $AA37 label=toggle_carried_part
c $AA37 Hang a rocket part under the ship, or take it off
D $AA37 The ship's picture is built in RAM at #R$F6B9, six bytes a row, bottom row first, and a rocket part the ship carries hangs in its bottom rows. This XORs the part's graphic (from type $1E's frame list #R$AF7B, by the part number in bits 0-3 of the ship record's +$1F) into the picture, shifted four pixels right through the shift tables' fourth and fifth pages (#R$FA00) and one byte in -- so the same call puts it in and takes it out -- and clears the same place on the screen (four bytes from a byte in, the part's height up from the ship's bottom line), presumably because the direct drawer rubs the ship out with its picture as it now is, which would leave the old part's pixels behind. Called from #R$C3E3 when bit 7 of +$1F asks for it.
D $AA37 Then (also the entry at the 24th instruction, used by #R$AFE9 when it rebuilds the picture) the ship's height and the picture's start are set for whether a part hangs there (bit 6 of +$1F): five rows more and the picture from #R$F6B9, or five fewer and from 30 bytes into it; the ship's line for shots (#R$5C38) moves by three, and the ship record's screen y and position are moved to match (#R$BF66, #R$B9EC).
R $AA37 IX The ship's record (#R$C8E5)
  $AA37,13 The part's graphic
  $AA44,14 Its width and height; the picture's first row, a byte in
  $AA52,18 Each byte, shifted four pixels right, XORed into two bytes of the picture
  $AA64,13 Next row, six bytes on
  $AA71,30 Clear the part's rows under the ship on the screen, four bytes a row
  $AA8F,5 Not while the view is being built (#R$5C3C)
  $AA94,19 A part hangs there: the picture from its first byte and five rows more
  $AAA7,15 None: from 30 bytes on and five rows fewer
  $AAB6,7 The ship's picture and height (in #R$C184)
  $AABD,26 Adjust the ship's shot line and record to match, and recompute its position
@ $AAD7 label=collect_pickup
c $AAD7 Pick up a pick-up the ship touches
D $AAD7 For each pick-up record (bit 7 of +3) every pass (#R$AC60). A pick-up is taken when it was on the screen last pass, between line $28 and the bottom and between x=$30 and $90, and its box touches a narrow box under the middle of the ship: 16 pixels from x=$70, the ship's height less ten. Then a sound (#R$71FE), 1000 added to the score (the score adder near the end of #R$917C), the record is emptied (bit 4 of +$10, so its image is rubbed out this pass), and:
D $AAD7 A rocket part (graphic $1E) is taken only when add-on 1 is fitted (+7 of the player's record #R$F5E7) and it is the part due next (its kind against +$1B, the parts delivered); its colours become $FA. It is hung under the ship: the ship record's +$1F gets the part number with bits 6 and 7 set (#R$C3E3 then calls #R$AA37), +$1A of the player's record the part carried, and the part's 4-byte entry from +$49 of the player's record is marked taken.
D $AAD7 Any other pick-up is an add-on: +$1F gets its kind plus one, which #R$C3E3 fits (#R$AFE9), and its entry from +$1D of the player's record is marked. Kinds 9 and $0A are the slab and the spire (add-ons 10 and 11), the load #R$C1CE puts down: kind $0A, the spire, is never taken; kind 9, the slab, only with add-on 9 fitted (+$0F), and taking it clears +$1F and #R$C279, sets +$10 of the player's record (#R$F5F7) to 9 (the whole load is carried again) and empties #R$A88D, which holds the spire. Much of this never ran in the build's sessions: the rocket parts' tests, their hanging and the kind-9 code.
R $AAD7 IX The pick-up's record
  $AAD7,7 A rocket part?
  $AADE,20 Only with add-on 1 fitted and when it is the part due next; recolour it
  $AAF2,17 Kind $0A is never taken; kind 9 only with add-on 9
  $AB03,5 Not if it was not on the screen
  $AB08,17 Its height, and where it was drawn: only from line $28 down and between x=$30 and $90
  $AB19,12 Its box
  $AB25,16 The ship's: 16 pixels from x=$70, its height less ten
  $AB35,5 Not touching
  $AB3A,3 Taken: a sound
  $AB3D,6 1000 to the score
  $AB43,27 A rocket part: hang it with bits 6 and 7 set, and keep the part number
  $AB5E,11 An add-on: fit kind+1
  $AB69,7 Mark it as taken in the player's record
  $AB70,8 Rub it out this pass and free the record
  $AB78,32 Kind 9, the slab: carry the load again, and empty the other pick-up record (the spire)
@ $AB98 label=test_collision_box
c $AB98 Test a box against the collision box
D $AB98 Calls #R$9DB1 with IX at #R$ABA4: the hit flag #R$5C1C is 1 if the box given in HL and DE touches it.
R $AB98 L x
R $AB98 H y of the bottom row
R $AB98 D Width in pixels
R $AB98 E Height in rows
@ $ABA4 label=collision_box
g $ABA4 The collision box's place
D $ABA4 A box for #R$9DB1, with #R$ABA6: x, then the y of its bottom row. Set from a ground object or pick-up (#R$A8F4, #R$AAD7), an object for the shot tests (#R$9143), or the ship (#R$9BDA) before a test.
@ $ABA6 label=collision_box_size
g $ABA6 The collision box's size
D $ABA6 Width in pixels, then height in rows, of the box at #R$ABA4.
@ $ABA8 label=beam_hits_ground_object
c $ABA8 Test the special beam against a ground object
D $ABA8 For each ground object that is not a pick-up, is on the screen, is not already dissolving and is not of kind $0B, while the special beam is out (#R$B832): its box is set from where it was drawn (#R$9143), the beam's record found (#R$B870, which leaves IY at it) and tested against the box (the entry near the start of #R$917C, through #R$AC29). Kind $0B (a ringed planet, by its picture) is the one kind the beam cannot destroy. If that started the object dissolving (bit 3 of +$17), it is marked gone in #R$5C94. Then, for graphic $0D only: an ore deposit (kind 8 to $0A) gives its kind to the beam's +$13, which brings the ore back to the tank (#R$A8A5); kinds 6 and 7 set the bit for their map square in the player's record (#R$AC08).
R $ABA8 IX The object's record
  $ABA8,26 Only for a ground object on the screen, not dissolving and not of kind $0B, while the beam is out
  $ABC2,9 Box it, find the beam, and test
  $ABCB,5 Not hit
  $ABD0,15 Hit: mark it gone
  $ABDF,6 Graphic $0D only
  $ABE5,14 Kinds 8 to $0A, ore: give the kind to the beam
  $ABF3,3 Kinds 6 and 7 only
  $ABF6,17 Set the bit for its map square (the SET's bit number is patched in)
@ $AC08 label=map_square_bit
c $AC08 Find a map square's bit in the player's record
D $AC08 The player's record (#R$F5E7) keeps 24 bits at +3 to +5 (cleared at the end of each level, #R$F52A), one for each of twelve page rows and two halves of the map across (columns below $30 and from $30), marking the squares whose beam generator has been destroyed. This returns the byte and the bit, the bit as eight times its number, ready to add into a BIT, SET or RES opcode. #R$ABA8 sets them and #R$9BDA tests them.
R $AC08 D The page row (1-12)
R $AC08 E The page column
R $AC08 O:HL The byte
R $AC08 O:B Eight times the bit number
  $AC08,16 The byte: page row less one, divided by four
  $AC18,8 The bit: twice the remainder...
  $AC20,8 ...plus one for the right half of the map
@ $AC29 label=test_shot_box
c $AC29 Test a shot against the collision box
D $AC29 Jumps into #R$917C at its sixth instruction with A=1 and IX at #R$ABA4, keeping IX on the stack for the end of that routine.
@ $AC34 label=free_object
c $AC34 Free an object record
D $AC34 Clears the record's movement and state fields and marks it free (+0 = $FF). Its position, colours and +$18/+$19 are left as they were.
R $AC34 IX The record
@ $AC60 label=update_ground_objects
c $AC60 Update and draw the ground objects
D $AC60 Once a pass, from the landscape's drawing (#R$DDF8): before or after the landscape is drawn depending on which way the screen is moving up or down. For each of the six records at #R$A80B in use:
D $AC60 A ground object (not a pick-up) whose +$18 bits 1-3 are set may fire (#R$8820). The pair of images is started (#R$A2EA) and, if it was drawn last pass, its erase set up (#R$AD27). #R$910A animates it if bit 7 of +$15 is set; a pick-up is tested against the ship (#R$AAD7). An object to be removed is freed and only rubbed out; any other is placed for this pass (#R$AD48). The compositor rubs out and draws (#R$AD1B); a ground object's colour patch is trimmed (#R$ACDD); the colours are put on (#R$AE98); and a ground object is tested against the special beam (#R$ABA8).
D $AC60 The ground objects do not move by themselves: their positions in the world are fixed, and they move on the screen as the view scrolls (#R$ADD8).
  $AC60,7 Unless the view is being built (#R$5C3C), the rocket first (#R$9572)
  $AC67,6 The six records
  $AC70,7 Free
  $AC77,19 A ground object: let it fire, if +$18 bits 1-3 give a kind of shot
  $AC8A,10 Start the pair; set up the erase if it was drawn last pass
  $AC94,5 Clear the left-clip mark (#R$AD27 has passed it on); keep the erase in the other registers
  $AC99,7 Animate it if bit 7 of +$15
  $ACA0,7 A pick-up: is it taken?
  $ACA7,16 To be removed: free it, and draw nothing new
  $ACB7,3 Otherwise place it for this pass
  $ACBA,3 Rub out and draw
  $ACBD,11 A ground object: trim its colour patch
  $ACC8,3 Colour it
  $ACCB,7 Test it against the special beam
  $ACD2,10 Next record
@ $ACDD label=trim_colour_patch
c $ACDD Trim a ground object's colour patch
D $ACDD For graphic $1B and the kinds 0, 1, 3, $0A and $0C, after the drawing: when the new image's bottom row is not the bottom line of a character cell, its height (#R$A1D8) is cut by four and its y (#R$A1D6) moved up seven lines, so the colour patch (#R$AE98) stops a character row short and does not colour the cells its bottom shares with the ground; none at all if that would put it above line $18. Only the colouring reads them now. Why four and seven is not yet worked out.
R $ACDD IY The record
  $ACDD,29 Only these graphics and kinds
  $ACFA,8 Not when the bottom row is a cell's bottom line
  $AD02,8 Four rows fewer
  $AD0A,13 Seven lines up; no patch at all if that is above line $18
@ $AD1B label=draw_object_images
c $AD1B Rub out and draw an object's images, if it has any
D $AD1B Passes to the compositor #R$A303 unless both the old and the new image are absent. The profile charges all of #R$A303's time to this routine, since it jumps there.
@ $AD27 label=prepare_erase
c $AD27 Set up the rubbing out of an object's old image
D $AD27 For an object drawn last pass (bit 7 of +$10): the old image is its graphic, as it still is before the update has run, at the screen position it was drawn at (+$11, +$12), clipped (#R$A1EA) and given its row routine (#R$A234). The caller then swaps the registers with EXX so the old image's graphic and shift page wait in the alternate set. Bit 6 of +$10 (drawn straddling the left edge) becomes the compositor's left-clip flag (#R$A2FA).
R $AD27 IX The record
  $AD27,3 The graphic
  $AD2A,9 Where it was drawn
  $AD33,6 Clip it and choose its row routine
  $AD39,4 It is no longer on the screen, until placed again
  $AD3D,9 Whether it straddled the left edge
@ $AD46 label=current_object
g $AD46 The object record being drawn
D $AD46 IX of the object whose images are being worked on (#R$AD48), for the routines after the drawing that need it back (#R$A8F4, #R$9143, #R$AC60).
@ $AD48 label=prepare_draw
c $AD48 Place an object for this pass and set up its new image
D $AD48 Works out where the object is on the screen (#R$ADD8); if it is visible, sets up its new image for the compositor: its graphic clipped (#R$A1D9), its row routine (#R$A247), and its colour for #R$AE98 (the third byte of #R$AF01), one of the two in +$0D on alternate passes (bit 0 of the pass counter in #R$9A64): on odd passes ink bits 0-2 with BRIGHT from bit 3, on even passes ink bits 4-6 with BRIGHT from bit 7, always on black paper, so an object can flicker between two colours.
D $AD48 A dissolving object (bit 3 of +$17) counts its step in bits 0-2 of +$17 and passes it to #R$A498 in #R$A302; at the eighth step it is freed instead.
R $AD48 IX The record
  $AD48,8 Keep the record; not dissolving yet
  $AD50,8 Its graphic; place it on the screen
  $AD58,6 Dissolving?
  $AD5E,11 Count the step
  $AD69,10 The eighth: free the record, and draw nothing
  $AD73,17 Keep the step, and pass it to the dissolve
  $AD84,9 Not visible: nothing to draw
  $AD8D,10 Its colours: which one this pass?
  $AD97,12 Odd passes: BRIGHT from bit 3, ink from bits 0-2
  $ADA3,17 Even passes: BRIGHT from bit 7, ink from bits 4-6
  $ADB4,4 The colour for the patch
  $ADB8,6 Clip the new image and choose its row routine
@ $ADBE label=object_graphic
c $ADBE Find a record's graphic
D $ADBE The graphic number (+0) picks a frame list from the graphic table (the words from the 25th byte of #R$AF25), and bits 0-3 of +$13 the frame in it.
R $ADBE IX The record
R $ADBE O:DE The graphic (width, height, rows)
@ $ADD8 label=place_on_screen
c $ADD8 Work out where an object is on the screen, and whether it can be seen
D $ADD8 The world is a grid of pages the size of the play area, 224 pixels across and 160 lines down; an object's position is its page column (+1) and x within that page (+2), and its page row (+4) and y within it (+5). The view's page column and row are kept in #R$CE57 and #R$CE58, and the x and y in those pages at the play area's left edge and top in #R$CE45 and #R$CE46; the landscape's scroll (#R$DDF8) keeps the screen offsets in #R$CE41 and #R$CE42 at 8 less the view's x and $B7 less its y, so that the screen x is the page x plus the one and the screen y the page y plus the other. The page column to the right of the view's is kept in #R$DDF7.
D $ADD8 Across: an object in the view's page is visible from the view's x on, or straddling it -- and if it starts nine or more pixels left of it, so that it would be off the left of the screen, it is drawn in left-clip mode (+$10 bit 6, #R$A2FA). One in the next page is visible if its x is short of the view's. One in the page to the left is kept only if it was drawn last pass and lies at the right of its page, when it is worked out as straddling the view's left edge (the $30 and $B0 keep the sums in range). Any other is freed (+0 = $FF): objects are dropped once they are out of the two pages the view spans.
D $ADD8 Down: an object in the view's page row is visible if its bottom is below the view's top; one in the row below if its top is above the view's bottom. Any other is freed. An object that is in range but out of sight returns without being marked as on the screen, and so is not drawn this pass. A visible one has its screen x and y put in #R$A1D5 and #R$A1D6 and in +$11 and +$12, and bit 7 of +$10 set.
R $ADD8 DE The graphic
R $ADD8 IX The record
  $ADD8,8 Its width in pixels, and height
  $ADE0,10 The view's x; the object's, made even
  $ADEA,9 In the next page to the right?
  $ADF3,8 In the view's page?
  $ADFB,7 Neither: free it unless it was drawn last pass
  $AE02,15 ...and it reaches the right end of the page to the left
  $AE11,8 Shift both x's to keep the comparison in range
  $AE19,4 From the view's x on: visible
  $AE1D,6 Left of the view's x: wholly left of it is out of sight
  $AE23,15 Straddling, by nine pixels or more: left-clip mode
  $AE32,23 The page to the left: screen x is x less the view's x plus 8
  $AE49,4 The view's page and the next: x plus the screen offset
  $AE4D,9 The screen x
  $AE56,8 The next page: visible only short of the view's x; 224 pixels on
  $AE5E,7 Its y, and the view's
  $AE65,8 In the view's page row?
  $AE6D,7 Yes: visible if its bottom is below the view's top
  $AE74,15 The screen y; it is on the screen
  $AE83,7 In the row below? If not, free it
  $AE8A,9 Visible if its top is above the view's bottom
  $AE93,5 Free the record
# Cyberun, agent 5: $AE98-$BFB7.
#
# THE SHOT RECORD (#R$B37A, four of $18 bytes). Shares the object record's
# first fields, so #R$BF66 moves it through the world like any object:
#   +0 the ship's facing when fired (bit 7 left), $FF free; a missile's type (0)
#   +1 +2 +3 x page, x (8-$E7), fraction   +4 +5 +6 y page, y ($18-$B7), fraction
#   +7 +8 x speed (8.8, pixels a pass)       +9 +A y speed (8.8, down positive)
#   +B the beam's left end on screen, in pixels (0: the record is free)
#   +C its screen line   +D its attribute   +E its length in cells
#   +F the offset into the beam pattern (#R$B3DA and #R$B3E2)
#   +10 bit 7 the head has stopped (hit or edge), bit 6 the tail is catching
#       up, bit 5 the probe has hit; a missile's flags
#   +11 the special beam's age   +12 the special beam's step across (+8 or -8)
#   +15 bit 7 the special beam; bits 0-3 its frame (0-5)
#   +16 bit 7 a missile (an ordinary object, updated by #R$9307)
#   +17 a missile's +17 ($F0)

@ $AE98 label=colour_sprite
c $AE98 Colour the cells under a sprite just drawn
D $AE98 The last step of drawing an object's sprite (#R$938D, #R$9507, #R$9572, #R$AC60 call it after #R$AD1B has drawn it): works out the rectangle of character cells the sprite covers in the play area, and fills it with the attribute in #R$AF01's third byte, set by #R$AD48 from the record's two colours. The rectangle's width goes into #R$AF01, its height into the next byte, and #R$C991 paints it, bottom row first.
D $AE98 The sprite's position is the third and fourth bytes of #R$A1D3 (its x in pixels, its bottom line), its width in pixels is #R$5C29 (the width in bytes, multiplied by 8 in #R$A303) and its height in lines in the last byte of #R$A1D3, as #R$A247 left them after clipping. The play area runs across from x 8 to x $E7 and down from line $18 to line $B7; the cells are clipped to it. A cell holding only the sprite's top line (the top line being the last of its cell) is not counted: (bottom OR 7 less (top - 7)) / 8 rounds that one away.
D $AE98 Two more entries: #R$B5AF comes in at the instruction that takes the width from B, with L, H, D and B already set (the special beam), and #R$AF04 at the height's working, with the width already in #R$AF01.
  $AE98,5 D = the height less one; nothing drawn, nothing to colour
  $AE9D,8 HL = the position (L x, H the bottom line); B = the width in pixels
  $AEA5,14 cut by the play area's left edge (#R$A2FA, the record's +10 bit 6): the visible width is taken as x + width - $A4, from x 8
  $AEB3,12 starting in the left border column: start a cell in, a cell narrower
  $AEBF,11 running past the right edge (x + width over $E8): only up to it
  $AECA,9 not on a cell boundary: it spans one cell more
  $AED3,3 A = B (the special beam joins here with B its width in pixels)
  $AED6,11 the width in cells; none, nothing to do
  $AEE1,11 E = the top line less 7, but not above line $17 (the play area's top)
  $AEEC,15 the height in cells; none, nothing to do
  $AEFB,6 paint it with #R$C991, from the cell under the bottom line upwards

@ $AF01 label=colour_patch
g $AF01 A colour patch: width and height in cells, and the attribute
D $AF01 The record #R$C991 paints from: the width in cells, the height in cells, and the attribute. #R$AE98 works out the first two for a sprite; #R$AD48 sets the attribute for an object (one of its record's two colours, alternating every pass), #R$B5AF to $43 for the special beam, #R$AF04 to $47.
B $AF01,3,3

@ $AF04 label=colour_carried_parts
c $AF04 Colour the two parts drawn by #R$C1CE bright white
D $AF04 The end of #R$C1CE, which draws two big parts of the ship's add-ons (#R$7436 and #R$74E7, the last two in #R$AF95's list, drawn from their third byte) at the positions in #R$C27B and #R$C27D: this colours each, 5 cells wide and $23 lines high for the first, 3 cells wide and $2F lines for the second, clipped at the top of the play area by #R$C331. It joins #R$AE98 for the height and the painting.
D $AF04 Never ran in the build's sessions: what the two parts are is read, not seen.
  $AF04,5 bright white on black
  $AF09,10 the first part: 5 cells wide, $23 lines high
  $AF13,7 the second: 3 cells wide, $2F lines high
  $AF1A,11 the width; the height clipped at the play area's top (#R$C331) into D; colour it

@ $AF25 label=object_handlers
b $AF25 The update routines for object types $13-$1E
D $AF25 Twelve words, the update routines for object types $13 to $1E:
. #R$A18D jumps through them by the record's type less $13. Type $1B's
. entry is #R$AFCB, a list of graphics, not code: a type $1B object updated
. through here would crash, so presumably none is. Type $1E, a rocket part
. falling into place, is #R$9524.
W $AF25,24,2 Update routines for types $13 to $1E

@ $AF3D label=object_graphic_lists
b $AF3D The graphic list of every object type
D $AF3D One word for each object type from 0 to $1E: the address of a list
. of graphics, which #R$ADBE indexes by the low four bits of the record's
. +13 (the frame) and #R$A19F reads the first of. Each graphic is a byte of
. its width in bytes, a byte of its height in lines, then the rows, bottom
. row first.
D $AF3D Type 0, the shots' missile, is #R$B936; type $0C, the add-ons lying
. on the planet, shares the ship's list of add-on graphics (#R$AF95); the
. lists of types $0D, $14, $1B and $1E follow below (#R$AFAB, #R$AF8D,
. #R$AFCB, #R$AF7B).
W $AF3D,28,2 Types 0 to $0D
W $AF59,4,2 Types $0E and $0F
W $AF5D,30,2 Types $10 to $1E

@ $AF7B label=rocket_part_frames
b $AF7B Graphics of the rocket parts
D $AF7B Nine words: type $1E's list of frames (from #R$AF3D), and the list
. #R$AA37 draws into the ship's picture by #R$C904, the part being hung under
. the ship. Type $1E objects are the rocket parts the ship picks up and
. carries to the launch site; #R$AAD7 sets #R$F601 to the frame of the one
. collected. The graphics: #R$731F, #R$7339, #R$7353, #R$7388, #R$73BA,
. #R$73DC, #R$76E9, #R$73FE and #R$7745.
W $AF7B,18,2

@ $AF8D label=type14_graphics
b $AF8D Graphics of the type $14 objects
D $AF8D Type $14's list of frames (from #R$AF3D): four words, #R$79F4,
. #R$7A29, #R$7A5E and #R$7A29 again, so the animation goes back and forth
. over three graphics.
W $AF8D,8,2

@ $AF95 label=addon_graphics
b $AF95 Graphics of the ship's add-ons
D $AF95 Eleven words, the add-ons 1 to 11 in order. #R$B09C draws add-ons 1
. to 9 into the ship's picture from here; type $0C objects, the add-ons
. lying on the planet waiting to be collected, use the same list as their
. frames (#R$AF3D), their +13 being the add-on's number less one. #R$C1CE
. draws 10 and 11 apart from the ship.
D $AF95 Each graphic is preceded by a byte: the height the ship's picture has
. to be to show it, 40 less the buffer row it starts in (see #R$AFE9). Then
. its width in bytes, its height in lines, the picture (width times height
. bytes, bottom row first), and either $FF (no mask) or a mask of the same
. size, ANDed onto the ship's picture before the graphic is ORed on.
W $AF95,22,2 Add-ons 1 to 11

@ $AFAB label=type0d_graphics
b $AFAB Graphics of the type $0D objects
D $AFAB Type $0D's list of frames (from #R$AF3D): sixteen words, the frame
. being the low four bits of the record's +13.
W $AFAB,32,2

@ $AFCB label=type1b_graphics
b $AFCB Graphics of the type $1B objects
D $AFCB Type $1B's list of frames (from #R$AF3D): six words. The table of
. update routines (#R$AF25) also points here for type $1B, by mistake or
. because no type $1B object reaches #R$A18D.
W $AFCB,12,2

@ $AFD7 label=addon_places
b $AFD7 Where the add-ons go on the ship
D $AFD7 Nine words, one for each of add-ons 1 to 9: the address in the
. ship's picture buffer (#R$F6B9, 6 bytes a row, 40 rows) where #R$B09C
. draws its graphic. The first is the start of row 5.
W $AFD7,18,2

@ $AFE9 label=build_ship_sprite
c $AFE9 Build the ship's sprite from its add-ons
D $AFE9 The ship's sprite is put together in a buffer of 50 rows of 6 bytes (300 bytes) at #R$F6B9, drawn from the bottom row up: the bare ship (84 bytes from #R$C891, 14 rows) goes in rows 26-39, the top of the picture without add-on 9, and every add-on fitted -- the nine bytes from #R$F5EE, add-on n's slot holding n or 0 -- is masked and drawn in at its own place (#R$B09C), each hanging below the ship. The sprite's height in rows (#R$C1A9) is the most any add-on needs, at least 14, and drawing starts that many rows below row 40 (#R$C1AA). Add-on 9 sits on top of the ship, rows 36-50, and adds 11 rows to the height after the start is worked out, so the picture then ends at row 50 -- one row past the buffer, in #R$F7E5. Called from #R$C3E3 when an add-on is fitted, and from #R$DCA1.
D $AFE9 The ship's top stays where it was on the screen and its bottom line (#R$C903) moves down by the rows added, and the ship's world position (its record at #R$C8E5) moves with it, so the ship does not jump; #R$5C38, the line its shots come out of, is 8 below its top.
D $AFE9 The add-ons' effects set here: 4 doubles the top speed across (#R$5C3E 4 instead of 2); 5 doubles the top climb (#R$5C3F); 9 adds 11 rows to the height, into which the tail of #R$A8A5 draws the ore collected (#R$C905 rows); a rocket part being carried (#R$F601 not $FF) is hung under the ship again by #R$AA37's second entry. Add-on 2 always comes with add-on 1: its slot is set to twice add-on 1's. All of it ran in the build's every-add-on session; with every add-on fitted the picture is 51 rows, rows 0-50, its top row in #R$F7E5 (simulated for the Graphics page).
  $AFE9,7 add-on 2 comes and goes with add-on 1
  $AFF0,8 the top speeds across and up: 2 a pass
  $AFF8,11 the bare ship into the last 14 rows of the buffer
  $B003,11 the nine add-on slots; 14 rows so far
  $B00E,13 draw in each one fitted (#R$B09C), which may make the sprite taller
  $B01B,21 drawing starts at row 40 less the height: #R$C1AA = #R$F6B9 + 6 * (40 - height)
  $B030,16 the bottom line on screen: $6F plus the rows above 14, to the bottom of its cell
  $B040,17 the change, as the y speed of the ship's record: move it that far
  $B051,3 and clear its speed again (#R$B9EC)
  $B054,13 the line the shots come out of: 9 below the line above the sprite
  $B061,11 add-on 4: top speed across 4
  $B06C,11 add-on 5: top climb 4
  $B077,19 carrying a rocket part: hang it under the ship again
  $B08A,18 add-on 9: 11 more rows, up to row 50 (#R$F7E5); then the rows of the tail of #R$A8A5

@ $B09C label=fit_addon
c $B09C Draw an add-on into the ship's sprite
D $B09C Draws add-on n, from its graphic in #R$AF95 at its place in the buffer from #R$AFD7, and raises the sprite's height (#R$C1A9) to the byte before the graphic if that is more. If the graphic has a mask -- anything but $FF after the picture -- it is ANDed onto the buffer first (#R$B0E4); then the picture is ORed on. Rows in the buffer are 6 bytes apart.
D $B09C The mask test has a catch: a mask whose first byte is $FF is taken as no mask at all.
R $B09C IX the add-on's slot in the player record, holding its number
  $B09C,11 DE = its graphic (#R$AF95)
  $B0A7,15 HL = its place in the buffer (#R$AFD7); keep both
  $B0B6,14 the sprite has to be at least as tall as the byte before the graphic says
  $B0C4,18 the width (in A') and height (#R$5C1D); step over the picture, width times height bytes
  $B0D6,5 $FF after it: no mask
  $B0DB,9 A' = the height, C = the width; into the mask loop (#R$B0E4)

@ $B0E4 label=addon_mask_and_draw
c $B0E4 Mask and draw an add-on into the ship's picture
D $B0E4 #R$B09C runs into it, to its second instruction for the mask or to
. the draw if there is no mask. A row at a time for the height in A': the
. mask, C bytes of it, ANDed onto the buffer at HL, then HL 6 bytes on to
. the next row. Then the stack gives back the buffer address and the
. graphic, the width and height are read again, and the picture is ORed on
. the same way. Returns to #R$AFE9's loop.
R $B0E4 A' the height in lines
R $B0E4 C the width in bytes
R $B0E4 DE the mask
R $B0E4 HL the place in the buffer
  $B0E4,1 keep the row count
  $B0E5,9 AND a row of the mask onto the buffer
  $B0EE,10 the next row, 6 bytes on
  $B0F8,8 the buffer address and the graphic back; its width and height
  $B100,10 OR a row of the picture onto the buffer
  $B10A,10 the next row
  $B114,1 done

@ $B115 label=read_controls
c $B115 Read the controls, and burn fuel for steering and thrust
D $B115 Reads the current player's control method (#R$B16F) into #R$5C37, after three overrides: no thrust at the ceiling -- the view on y page 5 (page 0 with add-on 5) and #R$CE46, the view's line within its page, below $60; only fire and the special key while the special beam is on (#R$B832); and once the ship has docked with the finished rocket (#R$96AB set) nothing is read at all and #R$B234 flies the ship itself.
D $B115 Then the fuel: 8 a pass while steering or thrusting, 16 while doing both at once, halved with add-on 6 and halved again if #R$5C40 is set (by #R$8E2D when something knocks the ship sideways; cleared every pass in #R$8D42). It is added to the fuel word through #R$CC4D, which counts up towards empty.
R $B115 IX the ship's record
  $B115,3 C = the controls: bit 0 right, 1 left, 2 down, 3 up (thrust), 4 fire, 5 the special key
  $B118,27 the ceiling: page 5, or 0 with add-on 5
  $B133,10 the special beam on: only fire and the special key
  $B13D,5 docked with the rocket: nothing
  $B142,4 this pass's controls
  $B146,3 not steering or thrusting: no fuel burned
  $B149,14 8, or 16 for thrust and steering together
  $B157,10 add-on 6: half
  $B161,14 knocked sideways this pass: half again; burn it

@ $B16F label=read_control_method
c $B16F Read the current player's control method
D $B16F By the method in the current player's record (#R$F603): 0 keyboard, 1 Kempston, 2 cursor keys, 3 Interface II. Every method gives C in the Kempston layout -- bit 0 right, 1 left, 2 down, 3 up (thrust), 4 fire -- plus bit 5, the special key, which fires the special beam (#R$B833). On the keyboard the special key is the number row; with a joystick it is any letter key but CAPS SHIFT and SPACE (#R$9BC3 masks the five keys of each half-row).
D $B16F The keyboard: right is X, V, N or SYMBOL SHIFT, left Z, C, B or M -- alternate keys along the bottom row -- thrust any key on the middle letter row, fire any on the top letter row. Down is never set from the keyboard. Every read goes through OUT ($FD),A first (#R$9BC3).
R $B16F O:C the controls
  $B16F,17 by the method
  $B180,8 Kempston: the port is already in this layout
  $B188,30 Interface II, keys 6-0 on half-row $EF: 0 fire, 9 up, 8 down, 7 right, 6 left, rotated into place a bit at a time and inverted
  $B1A6,44 cursor keys: 7 up, 8 right, 6 down and 0 fire from half-row $EF, 5 left from half-row $F7; bits 6 and 7 come out set
  $B1D2,30 keyboard: X or V (half-row $FE), N or SYMBOL SHIFT ($7F): right
  $B1F0,24 Z or C, B or M: left
  $B208,9 any key of A-G or H-ENTER: thrust
  $B211,9 any of Q-T or Y-P: fire
  $B21A,12 any of 1-5 or 6-0: the special key
  $B226,14 joysticks: Z-V or B-SYMBOL SHIFT (not CAPS SHIFT or SPACE), or any of the other letter rows: the special key

@ $B234 label=move_ship
c $B234 Steer the ship: its speed across and up, and this pass's scroll
D $B234 Called first thing in a pass (#R$C374). The ship never moves on the screen across, and up and down only with its height: the landscape moves under it. This works out how far, in pixels, up and across (#R$CCBA and the byte after it), for the landscape (#R$D0BD) and, negated, for the ship's position in the world (#R$B9EC).
D $B234 Across, #R$C7FC does the work: this gives it the push in DE, in 256ths of a pixel a pass a pass: $40 left or -$40 right, plus a drag of 12 against the way the ship was going (the step across last pass) -- but only when pushing against it; pushing the way the ship goes ignores the drag. With nothing pushed the drag alone slows the ship. Nothing is pushed while #R$5C40 is set (knocked sideways). #R$5C36 says which way it was pushed ($80 left, 3 right, 0 not), for #R$C7FC and the ship's drawing.
D $B234 Up: gravity takes $40 a pass from the climb speed (the ship's record +$1B +$1C), or, while thrusting, thrust adds $50 instead -- one or the other is loaded, never both. The speed is clamped (#R$B322): no faster than half the top climb (#R$5C3F, 2 or 4) up, and -3 down. It is added to a fraction kept in #R$B320, and the change in the whole part, doubled, is the step: the screen moves 2 lines a unit. A step one unit too big upwards, or down by 6, is cut to the top climb, or 4. At a step of 4 either way, every other fine-scroll position (#R$CE42 bit 1) moves only 2.
D $B234 While the special beam is on (#R$B832) the ship hangs still. Once it has docked with the finished rocket (#R$96AB set) it thrusts by itself at the fast climb until the view reaches y page 0, then stops.
D $B234 The second entry, at the adding of the speed to the fraction, works the step out from a speed in HL; #R$AA15 and #R$BA8F (a bounce) use it.
R $B234 IX the ship's record
  $B234,3 the controls, and fuel (#R$B115)
  $B237,8 not pushed yet; no drag
  $B23F,26 docked with the rocket: thrust on and the fast climb; at the top page, stop
  $B259,20 the drag: 12 against last pass's way across, if it moved
  $B26D,26 left: $40, with the drag if the ship was going right
  $B287,20 right: -$40, with the drag if the ship was going left
  $B29B,9 knocked sideways this pass: no push
  $B2A4,3 the speed across, the position across and the step across (#R$C7FC)
  $B2A7,15 gravity, or thrust
  $B2B6,6 the climb speed
  $B2BC,15 the special beam on: no climb, no fall
  $B2CB,10 add, clamp (#R$B322) and keep
  $B2D5,8 the second entry: add the speed to the fraction in #R$B320
  $B2DD,4 the whole lines moved, doubled
  $B2E1,18 upwards: one unit too many (the top climb + 2) becomes the top climb
  $B2F3,6 downwards: -6 becomes -4
  $B2F9,3 the step up this pass
  $B2FC,22 4 either way: halved when #R$CE42 bit 1 is set

@ $B312 label=gravity
b $B312 Gravity
D $B312 The ship's accelerations are words in 256ths of a pixel a pass a
. pass, read by #R$B234: this, gravity, -$40; then #R$B314 thrust, #R$B316
. and #R$B318 steering, #R$B31A no push, #R$B31C and #R$B31E the drag across.
W $B312,2,2

@ $B314 label=thrust
b $B314 Thrust
D $B314 +$50, added to the climb speed while thrusting, in place of gravity (#R$B234).
W $B314,2,2

@ $B316 label=push_right
b $B316 Steering right
D $B316 -$40, the push across while steering right (#R$B234).
W $B316,2,2

@ $B318 label=push_left
b $B318 Steering left
D $B318 +$40, the push across while steering left (#R$B234).
W $B318,2,2

@ $B31A label=no_push
b $B31A No push
D $B31A 0: the push across when the ship was not moving across (#R$B234).
W $B31A,2,2

@ $B31C label=drag_going_left
b $B31C The drag while going left
D $B31C -12, against the ship's way across when it was going left
. (#R$B234).
W $B31C,2,2

@ $B31E label=drag_going_right
b $B31E The drag while going right
D $B31E +12, against the ship's way across when it was going right
. (#R$B234).
W $B31E,2,2

@ $B320 label=climb_fraction
g $B320 The ship's vertical position, in 256ths
D $B320 #R$B234 adds the climb speed to it every pass; the change in its
. whole part, doubled, is the step up. Zeroed while the special beam holds
. the ship (#R$B234) and by a bounce off a floor or ceiling (#R$BA8F).
W $B320,2,2

@ $B322 label=clamp_climb
c $B322 Clamp the ship's climb speed
D $B322 Down (negative) no faster than -3 and a fraction; up no faster than half the top climb (#R$5C3F): 1, or 2 with add-on 5.
R $B322 H the whole part of the climb speed
  $B322,11 falling: from -3.99 to -3.0 becomes -3 and the fraction
  $B32D,9 climbing: no more than #R$5C3F / 2

@ $B336 label=draw_beam
c $B336 OR a beam onto the screen
D $B336 Draws a shot's beam: B bytes across, for the lines in the last byte of #R$A1D3, from the screen address in HL upwards (#R$A1C3), the pattern from DE with its rows 8 bytes apart. ORed onto what is there, so the erase (#R$B356) can take it off again exactly.
R $B336 B the width in bytes (0: nothing)
R $B336 DE the pattern
R $B336 HL the screen address of its bottom left
  $B336,7 nothing to draw; C = the width, A = the lines
  $B33D,11 one line: OR the pattern on
  $B348,4 the line above
  $B34C,10 the pattern's next row, 8 bytes on

@ $B356 label=erase_laser
c $B356 Take a beam off the screen
D $B356 The inverse of #R$B336, from the alternate registers, which hold last pass's width, pattern and screen address (the shot routines EXX them away before moving the shot): each pattern byte inverted and ANDed onto the screen, for the lines in the fifth byte of #R$A1D3. Leaves the alternate set as it was.
R $B356 B' the width in bytes (0: nothing)
R $B356 DE' the pattern
R $B356 HL' the screen address of its bottom left
  $B356,9 the alternate set; nothing to rub out if the width is 0
  $B35F,12 one line: clear the pattern's bits
  $B36B,13 the line above; the pattern's next row
  $B378,2 back to the main set

@ $B37A label=shot_records
b $B37A The four shot records
D $B37A Four records of $18 bytes, one for each shot in flight: a laser
. beam, the special beam, or a missile. The fields are listed at the top of
. this part. #R$B731 fills a free one when the ship fires, #R$B706 updates
. them every pass, and #R$917C checks them against the attackers.
B $B37A,24,8 Shot 1
B $B392,24,8 Shot 2
B $B3AA,24,8 Shot 3
B $B3C2,24,8 Shot 4

@ $B3DA label=laser_pattern_right
b $B3DA The pattern of a laser going right
D $B3DA The laser is one line high; this and #R$B3E2 are its pattern, 8
. bytes each. A beam of n cells takes n bytes from offset +F (#R$B3EA), so
. as the beam grows and +F falls the head stays solid and the tail ragged.
. Going right: broken at the left, the tail, solid at the right, the head.
. #R$B483 draws with it.
B $B3DA,8,8

@ $B3E2 label=laser_pattern_left
b $B3E2 The pattern of a laser going left
D $B3E2 As #R$B3DA, solid at the left, the head, and broken at the right.
. #R$B628 draws with it.
B $B3E2,8,8

@ $B3EA label=beam_pattern
c $B3EA Point DE at a shot's beam pattern
R $B3EA DE the pattern's start
R $B3EA IX the shot's record
  $B3EA,8 plus the record's +F

@ $B3F2 label=random_beam_colour
c $B3F2 Give a laser a random colour
D $B3F2 Bright cyan, yellow or white, or bright magenta in place of a fourth, from the random number at #R$9BCB.
  $B3F2,13 $45-$47, or $43
  $B3FF,4 the record's +D

@ $B403 label=random_jitter
c $B403 A random -1, 0 or +1
D $B403 From the second byte of #R$9BCB: 0 half the time, -1 and +1 a quarter each. Used to shake a laser's line by one as it leaves the ship.
R $B403 O:B -1, 0 or +1
  $B403,10 0 or 1: 0
  $B40D,4 3: -1
  $B411,3 2: +1

@ $B414 label=update_special_beam
c $B414 Update the special beam
D $B414 The special beam (record +15 bit 7) is fired by the special key with add-on 7 while the ship is still (#R$B833), and the ship hangs still while it lasts. It is a band 5 to 8 lines high (#R$B8CF's frames, cycling 0, 1, 2, 3, 2, 1 a pass) that grows a cell every other pass up to 8 cells, its probe 8 pixels further each time (+12), stops growing when the probe meets the landscape (#R$B6F0), and after 22 passes ($16 in +11), or when the key is let go (#R$B889), shrinks a cell a pass until gone. Going left, its left end moves out as it grows. A sound every pass (#R$7234).
D $B414 Drawing as for a laser (#R$B5AF), but the pattern for rubbing out is last pass's frame expanded into the sprite buffer at the end of #R$F7EB (#R$B897), and the new one into #R$F880 (#R$B8B5); the beam is coloured bright magenta. When it has gone the ship is free again (#R$B832).
D $B414 It ran in the build's every-add-on session, but only going right and never with the probe in the landscape: the left end's moves going left and the probe's return to the ship are read only. Fired with the ship on the ground, the probe is in the landscape at once: the cell the beam has just grown is taken off again, its length is back to 0, and #R$B5AF frees the record that same pass, so the beam shows only in the air (run in SkoolKit's simulator for the Animations page).
R $B414 IX the shot's record
  $B414,7 a buzz while it is out
  $B41B,3 age it
  $B41E,10 last pass's frame for rubbing out; its screen address and width into the alternate set
  $B428,6 stopped: shrink
  $B42E,6 grow only every other pass
  $B434,9 move the probe a step out
  $B43D,7 at most 8 cells
  $B444,17 a cell longer; going left, the left end a cell further out
  $B455,5 the probe in the landscape (#R$B6F0)?
  $B45A,6 yes: the probe moves with the ship again
  $B460,17 a cell shorter; going left, the left end a cell back
  $B471,3 this pass's frame (#R$B8B5)
  $B474,15 22 passes old: start shrinking; draw it (#R$B5AF)

@ $B483 label=update_shot
c $B483 Update a laser shot
D $B483 Called for each laser (and special beam) in flight (#R$B706). A laser is a line one pixel high, drawn on the screen and coloured a cell high, which grows out of the ship's nose: its head 16 pixels a pass and its tail 8, its length (+E, in cells) one more each pass. A probe moves through the world 16 pixels a pass ahead of the ship (#R$B6EC, the record's +7 being the ship's speed plus 16); when it meets the landscape, or the head reaches the play area's edge (x $B8 for the left end of a beam going right), the head stops (+10 bit 7). The pattern's offset (+F) then counts down to 0, after which the tail catches up (bit 6) a cell a pass until the beam has gone. While stopped the beam is moved by the scroll, so it stays on what it hit. The attackers are checked against it in #R$917C.
D $B483 On its first pass (+E 0) the line is set: the ship's shot line (#R$5C38) less this pass's climb, plus a random -1, 0 or +1, and a random colour (#R$B3F2), and the record's world position is moved by that. Going left is #R$B628; both end in #R$B5AF, which draws the beam and frees the record when it has gone.
D $B483 #R$5C25 is set to $80 for #R$BA21: a shot stops at the first box of landscape it touches.
R $B483 IX the shot's record
  $B483,11 the probe moves with the ship; #R$5C25 = $80, a shot
  $B48E,7 the special beam: #R$B414
  $B495,8 a laser is one line high, drawn and rubbed out
  $B49D,6 not its first pass
  $B4A3,38 its first: no flags, no speed; the line, shaken by one; a colour; move the record to it
  $B4C9,7 going left: #R$B628
  $B4D0,13 last pass's pattern, screen address and width into the alternate set
  $B4DD,6 the head has stopped
  $B4E3,14 first pass: the pattern's offset 8; the left end at x $88
  $B4F1,8 the probe 16 pixels ahead
  $B4F9,5 in the landscape (#R$B6EC)?
  $B4FE,19 yes: the probe back; the head stops, a hit
  $B511,16 the left end 8 on; at $B8 the head is at the edge
  $B521,17 a cell longer, the pattern's offset one less; draw it
  $B532,15 stopped: probe again until it hits
  $B541,15 follow the scroll across; no more probing speed
  $B550,39 the right end past the edge at $E4-$EF: a cell shorter; past $F0 (off the screen): gone
  $B577,15 a cell shorter at the right
  $B586,23 the tail catching up: a cell shorter, the left end 8 on
  $B59D,13 the pattern's offset down to 0: then the tail starts
  $B5AA,5 the right-going pattern; draw it

@ $B5AF label=draw_shot
c $B5AF Draw a beam, colour it, and free the record when it has gone
D $B5AF The end of every beam's update: #R$B628 comes in at the top with the left-going pattern, #R$B483 at its second instruction with the right-going one, #R$B414 at its third with its own in DE. The beam follows the vertical scroll (#R$CCBA) on the screen; last pass's beam is rubbed out (#R$B356) and this pass's drawn (#R$B336), and the record moved by its speed (#R$BF66).
D $B5AF A laser is coloured with its own attribute, a strip of its length one cell high (#R$B625, painted by #R$C991); the special beam bright magenta over its width and height (#R$AE98's second entry). A beam of no length is finished: its record is freed (+B 0) and, for the special beam, the ship let go (#R$B832) -- the jump to #R$A8A5 then returns at once, a shot's +13 being 0.
R $B5AF IX the shot's record
  $B5AF,3 the left-going pattern
  $B5B2,3 plus the record's offset
  $B5B5,9 follow the vertical scroll
  $B5BE,15 this pass's screen address and length (not below 0)
  $B5CD,9 rub out, draw, and move the record through the world
  $B5D6,15 gone: free the record
  $B5E5,7 the special beam gone: the ship is free
  $B5EC,31 the special beam: bright magenta, its height in lines, its width in pixels
  $B60B,26 a laser: a strip of its length, one cell high, in its colour

@ $B625 label=shot_colour_patch
b $B625 The colour patch for a laser
D $B625 For #R$C991: the width in cells (the beam's length), the height (1) and the attribute, filled in by #R$B5AF.
B $B625,3,3

@ $B628 label=update_left_shot
c $B628 Update a laser shot going left
D $B628 #R$B483 for a beam going left, mirrored: the left end moves 16 pixels a pass as the beam grows a cell, the probe 16 pixels a pass the other way (+7 the ship's speed less 16), the pattern taken from the left-going one at offset +F counting up. The head stops at the play area's left edge (x 8) or when the probe meets the landscape; the tail catches up when offset and length together reach 8.
R $B628 IX the shot's record
  $B628,13 last pass's pattern, screen address and width into the alternate set
  $B635,6 the head has stopped
  $B63B,16 the left end 16 out; the probe 16 ahead
  $B64B,10 first pass: the left end at x $58
  $B655,4 the offset 0
  $B659,5 in the landscape (#R$B6EC)?
  $B65E,26 yes: the head stops, a hit; both back 16
  $B678,7 no: a cell longer
  $B67F,15 at the left edge the head stops; draw it
  $B68E,7 stopped: the offset one more
  $B695,15 probe again until it hits
  $B6A4,19 follow the scroll across
  $B6B7,19 past the left edge: a cell shorter, from the left
  $B6CA,16 the tail catching up: a cell shorter
  $B6DA,18 offset and length reach 8: the tail starts

@ $B6EC label=probe_laser
c $B6EC Has a laser's probe met the landscape?
D $B6EC A box 24 pixels wide and 12 high.
  $B6EC,4 12 lines high

@ $B6F0 label=probe_special_beam
c $B6F0 Has the special beam's probe met the landscape?
D $B6F0 A box 24 pixels wide and 16 high. Runs into #R$B6F2.
  $B6F0,2 16 lines high

@ $B6F2 label=probe_shot
c $B6F2 Test a shot's probe against the landscape
D $B6F2 A box C wide and B high at the record's world position, tested with #R$9056 (which moves it 4 pixels left and 4 down for the test, and back). A laser that hits makes a sound (#R$72A5).
R $B6F2 B the height in lines
R $B6F2 IX the shot's record
R $B6F2 O:F NZ if it hit
  $B6F2,5 24 wide: test it
  $B6F7,5 not hit: Z
  $B6FC,10 a laser: a tick; NZ

@ $B706 label=update_shots
c $B706 Update the four shots
D $B706 Called every pass from #R$C374. A missile (+16 bit 7) is updated by #R$9307 while its +0 is 0 (its type); any other record in use (+B not 0) is a beam, updated by #R$B483.
  $B706,6 the four shot records
  $B70C,18 a missile: its own routine
  $B71E,7 a beam in flight: #R$B483
  $B725,11 the next

@ $B730 label=shot_alternator
g $B730 Which shot comes next
D $B730 Bit 0 flips with every shot fired (#R$B731): with add-on 8 every other shot is a missile. #R$B833 sets bit 2 for the one call that launches the special beam.
B $B730,1,1

@ $B731 label=fire
c $B731 Fire, if the fire key is pressed
D $B731 Called every pass from #R$C3E3. First the special beam's key (#R$B833); then, if the fire key is held and the gun has cooled (6 passes, #R$5C39), a shot in the first free record of four. Its record is cleared (#R$AC34), takes the ship's facing and world position, 8 pixels ahead of it (24 facing right), at the ship's shot line (#R$B90A), and is moved there. Then one of three kinds:
D $B731 A laser (#R$B483 takes it on), with a zap (#R$72F2).
D $B731 A missile, every other shot with add-on 8 (#R$B730 bit 0): type 0, the small 8 by 3 sprite of #R$B936, steady bright cyan, flying 8 pixels a pass from 32 ahead of the ship (8 facing left) and 3 lines higher, updated as an ordinary object by #R$9307 (+16 $80).
D $B731 The special beam (#R$B730 bit 2, from #R$B833): +15 $80, bright magenta, at x $90 going right or $60 going left, stepping 8 a pass; it holds the ship still (#R$B832).
D $B731 Both ran in the build's every-add-on session, though a missile was never fired facing left.
  $B731,3 the special beam's key
  $B734,11 the gun cooling
  $B73F,6 fire not pressed
  $B745,13 6 passes to the next; flip the alternator
  $B752,13 (entry from #R$B833) four records; a missile's is free when its +0 is $FF
  $B75F,12 a beam's when +B is 0
  $B76B,16 clear it; the ship's facing; in use; the ship's position (#R$B90A)
  $B77B,12 the special beam, or (every other shot) a missile
  $B787,15 a laser: move it ahead of the ship; a zap
  $B796,10 the next record; none free, no shot
  $B7A0,7 no add-on 8: a laser after all
  $B7A7,34 32 ahead facing right, 3 lines up; put it there
  $B7C9,35 8 a pass, the right way; type 0, bright cyan, a missile
  $B7EC,10 nothing on the screen yet; a zap
  $B7F6,12 the special beam: hold the ship; bright magenta
  $B802,16 the shot line, and 9 down in the world
  $B812,32 facing left: x $60, -8 a pass; facing right: x $90, +8 a pass

@ $B832 label=special_beam_on
g $B832 The special beam is out
D $B832 $80 while the special beam lasts (#R$B731), 0 when it has gone (#R$B5AF). While it is set the ship takes only fire and the special key (#R$B115) and hangs still (#R$B234), and #R$B833 watches for the key being let go.
B $B832,1,1

@ $B833 label=special_beam_key
c $B833 Launch or end the special beam
D $B833 The special key (the number row, or a letter with a joystick: #R$B16F) launches the special beam if add-on 7 is fitted and the ship is still: its speeds last pass (#R$C8FE across and #R$C900 up and down, in the ship's record) both within #R$BA0B's dead band. Letting the key go while the beam is out starts it shrinking (#R$B889).
D $B833 It ran in the build's every-add-on session.
  $B833,6 the beam is out: watch the key
  $B839,11 the key, and add-on 7
  $B844,24 the ship still across and up and down
  $B85C,20 launch it through #R$B731's second entry, with #R$B730 bit 2 set for the one call

@ $B870 label=find_special_beam
c $B870 Find the special beam's record
D $B870 Looks through the first three shot records for one that is not a missile and has +15 bit 7 set. If none of the three is, IY is left at the fourth, unchecked. Also used by #R$ABA8.
R $B870 O:IY the record
  $B870,25 the first three records

@ $B889 label=end_special_beam
c $B889 Start the special beam shrinking when its key is let go
D $B889 It ran in the build's every-add-on session.
  $B889,6 the key still held
  $B88F,8 let go: stop its head (+10 bit 7)

@ $B897 label=old_beam_frame
c $B897 Expand the special beam's last frame, for rubbing out, and step to the next
D $B897 The frame (+15 bits 0-3, from 0 to 5 and round again) is expanded into the sprite buffer at the end of #R$F7EB (#R$B8CF), and its height goes into the fifth byte of #R$A1D3, the lines #R$B356 rubs out.
R $B897 IX the shot's record
R $B897 O:DE the expanded pattern
  $B897,6 the frame's graphic (#R$B8C3)
  $B89D,16 the next frame, 0 to 5, keeping bit 7
  $B8AD,8 the height for rubbing out; expand it (#R$B8DB)

@ $B8B5 label=new_beam_frame
c $B8B5 Expand the special beam's frame for drawing
D $B8B5 As #R$B897 for this pass's frame, into #R$F880; its height goes into the last byte of #R$A1D3, the lines #R$B336 draws.
R $B8B5 IX the shot's record
R $B8B5 O:DE the expanded pattern
  $B8B5,14 the frame's graphic; its height; expand it (#R$B8CF)

@ $B8C3 label=beam_frame
c $B8C3 The special beam's frame graphic
R $B8C3 IX the shot's record
R $B8C3 O:HL the graphic
  $B8C3,12 the frame from #R$B8CF's table (#R$A1AA)

@ $B8CF label=beam_frames
b $B8CF The special beam's frames
D $B8CF Six words, the frames in the order they are shown: 0, 1, 2, 3, 2, 1,
. so the band swells and shrinks. Each frame is a byte of its height (5 to 8
. lines), then two bytes a line, a 16-pixel pattern. #R$B8C3 picks one;
. #R$B8DB expands it.
W $B8CF,8,2 Frames 0, 1, 2, 3
W $B8D7,4,2 Frames 4 and 5

@ $B8DB label=expand_beam_frame
c $B8DB Expand a special beam frame into a pattern buffer
D $B8DB Reached by JP from #R$B897 and #R$B8B5 with DE the frame's graphic
. and HL the buffer (the one at the end of #R$F7EB for last pass's frame, #R$F880 for this
. pass's). Each line's two bytes are repeated four times into an 8-byte row,
. for the frame's height, so #R$B336 and #R$B356 can take up to 8 cells of
. it. Then DE is the buffer, one byte on if the beam goes left and its
. length is odd, which keeps the pattern in step with the screen.
R $B8DB A the frame's height
R $B8DB DE the frame's graphic
R $B8DB HL the buffer
R $B8DB IX the shot's record
R $B8DB O:DE the buffer, adjusted
  $B8DB,10 keep the buffer; A' = the lines; this line's two bytes in C and A; four copies
  $B8E5,6 into the row, two bytes a time
  $B8EB,4 the next line
  $B8EF,1 the buffer
  $B8F0,12 going left with an odd length: a byte on

@ $B8FC label=clear_screen_fields
c $B8FC Clear a record's +B, +C, +E and +F
D $B8FC For a shot these are its screen position, length and pattern offset; #R$AC34 starts the clearing of a whole object record here, and the landscape collisions (#R$BA8F, #R$BC5B) use it on an object that hits something.
R $B8FC IX the record
R $B8FC O:A 0
  $B8FC,14 zero them

@ $B90A label=place_shot
c $B90A Put a shot at the ship
D $B90A The shot's world position is the ship's (#R$C8E6 and #R$C8E9, its record's +1 to +5) and its first move, in +9, is down to the ship's shot line (#R$5C38) from the ship's bottom line (#R$C903). Its speed across is 8 pixels (facing left) or 24 (facing right), for #R$B731 to move it ahead of the ship's nose.
R $B90A IX the shot's record
  $B90A,11 the line, from the ship's bottom line
  $B915,19 the ship's place in the world
  $B928,14 8 ahead, or 24 facing right

@ $B936 label=missile_frames
b $B936 The missile's frames
D $B936 Type 0's list of frames (#R$AF3D): two words, #R$B93A and #R$B93F.
. A missile is drawn with these.
W $B936,4,2 The two frames

@ $B93A label=missile_frame_a
b $B93A The missile, first frame
D $B93A One byte wide and three lines high: a width, a height and three
. bytes, bottom row first.
B $B93A,5,5

@ $B93F label=missile_frame_b
b $B93F The missile, second frame
D $B93F As #R$B93A.
B $B93F,5,5

@ $B944 label=empty_box_list
b $B944 An empty list of landscape boxes
D $B944 A count of 0: #R$B946 points IX here when a record's box is in a
. page that has no list (one off the screen), so #R$BA21 finds no boxes. The
. byte after it is not used as far as read.
B $B944,2,2

@ $B946 label=find_page_boxes
c $B946 Find the list of landscape boxes for a page
D $B946 The landscape's collision boxes are kept page by page: the world is a ring of $60 pages across, each 224 pixels wide (x 8 to $E7), and a stack of pages down, each 160 lines high (y $18 to $B7). The screen shows parts of four at once, and #R$D0BD builds a list of boxes for each of them in the four work areas: #R$5B80 for the view's page (#R$CE57 across, #R$CE58 down), #R$5BA5 for the one below it, #R$5BCA for the one to its right, #R$5BEF for the one below and right. This finds the list for page D across, B down; a page off the screen gets the empty list at #R$B944.
D $B946 Each list is a count, then five bytes a box: +0 its left x, +1 its bottom line, +2 its width, +3 its height (or, for a slope, its other edge's line), +4 its kind (see #R$BA21).
R $B946 B the page down
R $B946 D the page across
R $B946 O:IX the list
R $B946 O:F Z if found
  $B946,1 E = the page down
@ $B947 nowarn
  $B947,12 the view's page
  $B953,9 the one below
  $B95C,16 the one below and right (across wraps at $60)
  $B96C,9 the one to the right
  $B975,5 none: the empty list

@ $B97A label=page_matches
c $B97A Is page (D, E) page (C, B)?
R $B97A O:F Z if so
  $B97A,6 across, then down

@ $B980 label=move_across
c $B980 Move a record across the world by its speed
D $B980 Adds the speed (+7 +8) to the position (+2 +3), and steps the page (+1) when the position leaves 8 to $E7: up a page past $E7, wrapping from $5F to 0, down a page below 8, wrapping from 0 to $5F. Both a run past the end and an 8-bit overflow count, so speeds up to 32 pixels a pass are safe. The record is not changed: #R$BF66 stores the result, and #R$BE8F uses it as the place to test.
R $B980 IX the record
R $B980 O:H the page across
R $B980 O:L the x
R $B980 O:E the fraction
  $B980,21 HL = x and fraction plus the speed; E the fraction, L the x, H the page, C the old x
  $B995,11 moving right: in the page still
  $B9A0,10 into the next page, from $5F round to 0
  $B9AA,7 moving left: in the page still
  $B9B1,10 into the page before, from 0 round to $5F

@ $B9BB label=move_down
c $B9BB Move a record up or down the world by its speed
D $B9BB As #R$B980 for the y (+4 page, +5 line, +6 fraction, +9 +A speed, down positive): a page is 160 lines, $18 to $B7, and the pages do not wrap.
R $B9BB IX the record
R $B9BB O:H the page down
R $B9BB O:L the line
R $B9BB O:E the fraction
  $B9BB,26 HL = line and fraction plus the speed; moving down: in the page still
  $B9DB,5 into the page below
  $B9E0,7 moving up: in the page still
  $B9E7,5 into the page above

@ $B9EC label=ship_speed_from_scroll
c $B9EC Set the ship's speed in the world from this pass's scroll
D $B9EC The ship's record, at #R$C8E5, holds its position in the world (+1 to +6) like any object's; it moves exactly as the landscape scrolls, the other way: across and up by minus the steps in #R$CCBA, whole pixels.
R $B9EC O:IX the ship's record
  $B9EC,29 the speeds, no fractions

@ $BA09 label=collision_object
g $BA09 The record being tested against the landscape
D $BA09 #R$BA21 keeps IX here while IX walks the lists of boxes.
W $BA09,2,2

@ $BA0B label=dead_band
c $BA0B Zero a speed too small to matter
D $BA0B A speed (8.8) from -0.65 to 0.39 (-$A8 to $63 in 256ths) becomes 0. The landscape bounces (#R$BA8F, #R$BC5B) use it so that a bounce dies away; #R$B833 to tell whether the ship is still.
R $BA0B HL the speed
R $BA0B O:HL the speed, or 0
  $BA0B,12 0 to $63: 0
  $BA17,10 -$A8 to -1: 0

@ $BA21 label=collide_with_landscape
c $BA21 Test a record against the landscape
D $BA21 The engine's collision with the ground, for the ship (#R$C374, #R$5C25 $FF), the shots' probes (#R$B6F2, #R$5C25 $80) and the objects (#R$9056, #R$5C25 0). The record's box -- C pixels wide and B lines high, up from its bottom line -- is placed where its speed would take it (#R$BE8F), cut into the parts in each page it overlaps (one, two or four), and each part tested against every box in that page's list (#R$B946). #R$5C1C is non-zero for a hit; for the ship and the objects the speed is also changed, a bounce or a slide.
D $BA21 A box's kind, its +4: if any of bits 2-5 is set it is a solid block (#R$BA8F): bits 4-5 clear make it a floor (bit 2: direction 0 in #R$D0AC) or a ceiling (bit 3: direction 7), a floor tested only while the record moves down onto it and a ceiling only while it moves up into it (either, too, while it does not move up or down); bit 4 or 5 set makes it a wall, tested by the way it is moving across. If bits 2-5 are all clear it is a slope (#R$BC13), its shape tested by #R$9E35: bits 0-2 the slope's kind (2 a 45-degree one), bits 6-7 which way it faces.
D $BA21 #R$5C35 keeps track of what has happened this pass: bit 7 a block hit (no more blocks tested), bit 6 a bounce (no more boxes at all), bit 4 a slope hit (no more slopes).
R $BA21 B the height in lines
R $BA21 C the width in pixels
R $BA21 IX the record
R $BA21 O:IX the record
  $BA21,13 no hit yet; keep IX; set up the first part

@ $BA2E label=next_part_boxes
c $BA2E Test the next part of a record's box against its page's boxes
D $BA2E The loop of #R$BA21: from the top it sets up the next part (#R$BE43); #R$BA21 joins after that for the first. For each box in the page's list, its kind goes into #R$5C20 and it is tested as a solid block (#R$BA8F) or a slope (#R$BC13); both come back to #R$BA4D.
  $BA2E,3 the next part's place and page (#R$BE43)
  $BA31,8 the page's list: empty, the next part
  $BA39,20 for each box: no hit yet; its kind in #R$5C20; a block or a slope

@ $BA4D label=next_box
c $BA4D The next box, the next part, or done
D $BA4D The loop's tail: after a bounce (bit 6 of #R$5C35) the test ends; otherwise the next box, then the next part (#R$BA2E), until #R$5C1D, the parts left, is 0. When the ship has gone through all of them without stopping, #R$BC12 is cleared. The last part is where a test stops early: a shot stops at its first hit; the ship and the objects stop at a bounce, a slope or a block -- except an object once the ship has docked with the rocket or is dying (#R$8F53 10 or more), which goes on to the other boxes.
  $BA4D,7 a bounce: stop
  $BA54,11 the next box
  $BA5F,10 the next part
  $BA69,13 all done; IX back; the ship: not on a slope
  $BA76,16 stop, unless an object after docking or during a death
  $BA86,7 IX back

@ $BA8D label=saved_speed
g $BA8D A word kept for a moment
D $BA8D #R$BC5B keeps an object's speed across here while it pushes the object out of a slope; the sprite code at #R$A43E keeps a screen address here; #R$8347 reads it too.
W $BA8D,2,2

@ $BA8F label=hit_block
c $BA8F Test a part against a solid block, and bounce
D $BA8F The block is tested only if the record is moving into it: a floor (kind bit 2 set) when it moves down or not at all (#R$BE8E, the climb speed it had last pass negated, so positive while it falls), a ceiling (bit 2 clear: bit 3 is set) when it moves up or not at all, a wall by its speed across (#R$BE8D; bit 4 of the kind says which way). Then the boxes are tested for overlap (#R$9DB1). A shot that hits stops there.
D $BA8F Floors and ceilings: the climb speed is reversed and halved (#R$BE08, #R$BE03), clamped (#R$C880) and dropped if small (#R$BA0B). For the ship the new speed sets this pass's step at once (#R$B234's second entry) with a bump (#R$7293). An object hitting it has its screen fields cleared and, on a floor (bit 3 clear), its bottom line put 20 above the box's; one that has stopped under a ceiling is given a speed of 2 downwards (+9 = $FE while the collision code has its speeds turned round), so that it drops away. A ship hitting a ceiling (bit 3) without add-on 9 sets #R$C7C1 to 4 (counted down in #R$C4ED).
D $BA8F Walls: the speed across reversed; for the ship halved, clamped and dropped if small, then this pass's step across worked out again (#R$C7FC's second entry) with a sound (#R$7263), and #R$D0BC set.
D $BA8F Also, before any of this, for the ship: a floor (bit 2) whose bottom line is 0 to 40 below the ship's and which spans part of x+4 to x+40 sets #R$C6D0, which stops #R$C6D2 drawing the lift jet below the ship that add-on 5 brings -- unless add-on 2 is fitted.
D $BA8F Every branch ran in the build's sessions, the bit-3 boxes, the walls and the hop included.
R $BA8F IX the box
  $BA8F,8 a block already hit this pass
  $BA97,10 HL = the part's x and bottom line; a shot: just test
  $BAA1,7 an object
  $BAA8,17 the ship: the span under it, x+4 to x+40
  $BAB9,37 a floor (bit 2) under that span, 0 to 40 lines down, and no add-on 2: #R$C6D0
  $BADE,7 a wall?
  $BAE5,21 a floor or ceiling: tested only if the record moves into it
  $BAFA,19 a wall: likewise, across
  $BB0D,14 do they overlap (#R$9DB1)?
  $BB1B,8 a shot: stop
  $BB23,13 a block hit; the box's bottom line less 20, and its kind
  $BB30,16 IX the record again; a wall?
  $BB40,23 the ship hitting a ceiling (bit 3) without add-on 9: #R$C7C1 = 4
  $BB57,13 an object: clear its screen fields; on a floor, sit it 20 above the box's bottom
  $BB64,28 the climb speed reversed, halved, clamped, dropped if small; keep it
  $BB80,13 still moving: a bounce
  $BB8D,15 stopped: an object under a ceiling drops away at 2
  $BB9C,22 the ship: a bump; this pass's step from the new speed
  $BBB2,27 a box of kind exactly 4 (the flat floor), and the ship's line below the box's bottom less 20: this pass's step up is 2
  $BBCD,20 a wall: the speed across reversed; an object just has its screen fields cleared
  $BBE1,19 the ship: halved, clamped, dropped if small; keep it
  $BBF4,30 the ship: a sound; this pass's step across again; #R$D0BC

@ $BC12 label=ship_on_slope
g $BC12 The ship was on a slope last pass
D $BC12 $80 after the ship touches a slope (#R$BCD1), cleared when it goes through a whole test without stopping (#R$BA4D). A second pass on a slope slides the ship 2 pixels downhill.
B $BC12,1,1

@ $BC13 label=hit_slope
c $BC13 Test a part against a slope, and bounce off it
D $BC13 One slope a pass (#R$5C35 bit 4). #R$9E35 tests the part against the slope's shape and leaves in #R$5C1A how far into it the part is. A shot that hits stops; the ship sets #R$D0BC to $FE. Then the speed is reflected, by the slope's kind and facing: a 45-degree slope swaps the speeds across and up (#R$BD04, #R$BD3B), any other mixes them with factors of 3/8 and 3/4 (#R$BD44, #R$BDBD).
R $BC13 IX the box
  $BC13,8 a slope already hit this pass
  $BC1B,10 the shape test (#R$9E35)
  $BC25,16 a slope hit; a shot: stop
  $BC35,7 the ship: #R$D0BC = $FE
  $BC3C,13 kind 2, facing bit 6 clear: swap and negate
  $BC49,7 kind 2, facing bit 6 set: swap
  $BC50,11 other kinds, by bit 6

@ $BC5B label=leave_slope
c $BC5B Push an object out of a slope, and keep it sliding
D $BC5B Where every slope bounce ends. An object (not the ship) is moved across out of the slope by the depth #R$9E35 found, through #R$B980 with that as its speed for a moment; a push of 16 or more sets its +10 bit 3. Its screen fields are cleared. If its new speeds are both too small to matter, it is set sliding a pixel a pass downhill (#R$BCBF). Then #R$BCD1 for the ship.
R $BC5B O:IX the record
  $BC5B,10 the ship: no pushing
  $BC65,31 the depth as the speed across for a moment; a deep one sets +10 bit 3
  $BC84,22 move across by it; the speed back
  $BC9A,3 clear the screen fields
  $BC9D,34 both speeds too small: slide downhill

@ $BCBF label=downhill
c $BCBF Set a record sliding a pixel a pass downhill
D $BCBF By the slope's facing (#R$5C20 bits 6-7): both clear or both set, right; otherwise left.
R $BCBF IX the record
  $BCBF,18 +1, or -1

@ $BCD1 label=ship_on_slope_response
c $BCD1 The ship on a slope
D $BCD1 An object is done (#R$BA4D's stop). The ship stops scrolling this pass, with a sound unless it is being knocked sideways (#R$5C40) or was on the slope last pass; on its second pass in a row it slides 2 pixels downhill. Marks #R$BC12. All of it ran in the build's sessions.
  $BCD1,7 an object: stop
  $BCD8,7 the ship: no scroll this pass
  $BCDF,13 a sound, if new to the slope and not knocked
  $BCEC,16 on the slope last pass too: 2 pixels downhill
  $BCFC,8 on a slope; stop

@ $BD04 label=bounce_45_negate
c $BD04 Bounce off a 45-degree slope, swapping and negating
D $BD04 The speeds across and up are swapped, each clamped (#R$C880): a
. reflection off a line at 45 degrees. From here both are negated on the
. way; from #R$BD3B they are not. Which is done is decided by two JRs in
. this routine whose displacements are patched: 0 runs the CALL to #R$BD3F
. after each, 3 jumps over it.
R $BD04 IX the box
  $BD04,1 the negations on
  $BD05,6 (#R$BD3B's entry) the two patched JRs' displacements
  $BD0B,10 the record; HL = its speed across
  $BD15,2 patched: run the CALL or jump over it
  $BD17,3 negate the speed across
  $BD1A,16 clamp it; it becomes the speed up and down; HL the old one
  $BD2A,2 patched: run the CALL or jump over it
  $BD2C,3 negate it
  $BD2F,12 clamp it; it becomes the speed across; push the object out (#R$BC5B)

@ $BD3B label=bounce_45_swap_only
c $BD3B Bounce off a 45-degree slope, swapping
D $BD3B #R$BD04 with the negations jumped over.
  $BD3B,4 the JRs jump 3

@ $BD3F label=negate_high_byte
c $BD3F Negate H
D $BD3F Negates the whole part of an 8.8 speed, leaving the fraction: near enough a negation for a bounce.
R $BD3F H the whole part
  $BD3F,5 0 - H

@ $BD44 label=bounce_shallow_negate
c $BD44 Bounce off a slope that is not 45 degrees
D $BD44 The new speeds are a mix of the old: across = 3/8 across + 3/8 up
. and down, up and down = -3/4 up and down + 3/4 across, the terms from the
. other speed negated or not (#R$BDC8) as two JRs in this routine decide:
. their displacements are patched to 0 to run the CALL after each (from
. here) or to 3 to jump over it (from #R$BDBD). For kind 3 slopes the
. speeds are swapped before and after (#R$BDD8), which mirrors the mix
. about the diagonal: the same rule serves the steep slopes and the
. shallow. Each result is clamped (#R$C880). The factors shrink the speed,
. so a bounce loses energy.
R $BD44 IX the box
  $BD44,7 the negations on
  $BD4B,16 (#R$BDBD's entry) the box's kind in C; kind 3: swap the speeds first
  $BD5B,12 3/8 of the speed across, kept for later
  $BD67,12 3/4 of it
  $BD73,2 patched: run the CALL or jump over it
  $BD75,3 negate it
  $BD78,12 keep it; 3/8 of the speed up and down
  $BD84,2 patched: run the CALL or jump over it
  $BD86,3 negate it
  $BD89,14 across: plus the 3/8 across, clamped
  $BD97,29 up and down: 3/4 of it negated, plus the 3/4 across, clamped
  $BDB4,9 kind 3: swap back; push the object out (#R$BC5B)

@ $BDBD label=bounce_shallow
c $BDBD Bounce off a slope that is not 45 degrees, without the negations
D $BDBD #R$BD44 with its two patched JRs jumping over the CALLs.
  $BDBD,11 the JRs jump 3

@ $BDC8 label=slope_negate
c $BDC8 Negate a term of a slope bounce
D $BDC8 For a box with bit 7 of its kind set, or of kind 3, the whole word is negated (#R$BE08); otherwise only its whole part (#R$BD3F).
R $BDC8 C the box's kind
R $BDC8 HL the term
  $BDC8,16 bit 7 or kind 3: all of it; otherwise the whole part

@ $BDD8 label=swap_speeds
c $BDD8 Swap a record's speeds across and up and down
R $BDD8 IX the record
  $BDD8,25 +7 +8 and +9 +A change places

@ $BDF1 label=three_eighths
c $BDF1 Three eighths of HL
R $BDF1 HL the value
R $BDF1 O:HL 3/8 of it
  $BDF1,13 a quarter plus an eighth

@ $BDFE label=double_hl
c $BDFE Double HL
  $BDFE,5 shift left

@ $BE03 label=halve_hl
c $BE03 Halve HL, keeping its sign
  $BE03,5 arithmetic shift right

@ $BE08 label=negate_hl
c $BE08 Negate HL
  $BE08,8 invert and add one

@ $BE10 label=part_above
c $BE10 Set the next part to the page above
D $BE10 For a record whose box reaches above the top of its page: the part in the page above, from its bottom line ($B7) up by what stuck out (#R$5C2B), its full width.
  $BE10,6 the height that stuck out
  $BE16,9 the page above, at its bottom line
  $BE1F,7 the full width

@ $BE26 label=part_right
c $BE26 Set the next part to the page to the right
D $BE26 For a record whose box reaches past the right of its page: the part in the next page across (from $5F round to 0), from its left edge (x 8) across by what stuck out (#R$5C2A), its full height.
  $BE26,6 the width that stuck out
  $BE2C,16 the next page across, at its left edge
  $BE3C,7 the full height

@ $BE43 label=next_part
c $BE43 Set up the next part of a record's box
D $BE43 After the part in the record's own page: the part to the right, then the part above, and when the box reaches past both edges, last, the part above and right (both at once). Each goes on to work out the box in its page (#R$BE8F's second half). #R$E41B is set while the part to the right is still to do.
  $BE43,34 the last of four: above and right
  $BE65,28 the part to the right, at the record's own line
  $BE81,12 the part above, at the record's own x

@ $BE8D label=last_speed_across
g $BE8D The speed across of the record being tested
D $BE8D Set by #R$BE8F: the whole part of the record's speed across (for
. the ship, last pass's). #R$BA8F tests a wall only if the record is moving
. into it, and updates this after a bounce.
B $BE8D,1,1

@ $BE8E label=last_speed_up
g $BE8E The climb speed of the record being tested, negated
D $BE8E Set by #R$BE8F: the whole part of the record's speed up and down
. (+9; for the ship, last pass's climb speed), negated. The collision code
. works with up positive -- the objects' speeds, kept the other way round,
. are turned round for it (#R$90CD) -- so this is positive while the record
. falls. #R$BA8F tests a floor only while it is 0 or more and a ceiling
. only while it is 0 or less, and updates it after a bounce.
B $BE8E,1,1

@ $BE8F label=place_collision_box
c $BE8F Work out where a record's box is, and its part in the first page
D $BE8F The box is the record's position after this pass's move (#R$B980, #R$B9BB; the record is not changed), C wide and B high from its bottom line up. The move is kept in #R$BF7F and #R$5C2E (across), and #R$BF81 and #R$5C30 (down).
D $BE8F Then, from the loading of #R$BF81 (where #R$BE43 comes in for the other parts): the page's list of boxes (#R$B946), and the part of the box inside the page -- its x (#R$CE3A), bottom line (#R$CE3B), height (#R$CE3C) and width (#R$CE3D) -- with what sticks out past the right (#R$5C2A) and above the top (#R$5C2B). On the first part, the number of parts to test, 1, 2 or 4, goes into #R$5C1D.
D $BE8F For the ship, its record's speeds are put back to last pass's for the bounce rules (#R$C8FE, #R$C900); for an object, they are negated (#R$90CD) -- the objects' speeds are kept the other way round.
R $BE8F B the box's height
R $BE8F C the box's width
R $BE8F IX the record
R $BE8F O:IX the page's list of boxes
  $BE8F,20 the size; nothing sticking out yet, no parts, no hits
  $BEA3,18 the record's place after its move
  $BEB5,12 an object: its speeds negated
  $BEC1,12 the ship: last pass's speeds
  $BECD,14 the speeds for the bounce rules
  $BEDB,12 the full size
  $BEE7,11 the page's list (#R$B946)
  $BEF2,15 past the right edge (x + width over $E8)?
  $BF01,20 yes: on the first part, what sticks out; this part is up to $E8
  $BF15,8 the part's width and x
  $BF1D,15 above the top (line - height under $18)?
  $BF2C,17 yes: on the first part, what sticks out; this part is from line $18
  $BF3D,8 the part's height and line
  $BF45,33 on the first part: how many parts, 1, 2 or 4

@ $BF66 label=move_object
c $BF66 Move a record through the world by its speed
D $BF66 Used for every moving thing: the ship, the shots, the objects. The world is a ring $60 pages round, 224 pixels to a page, and a stack of pages 160 lines high (see #R$B980 and #R$B9BB).
R $BF66 IX the record
  $BF66,12 across: page, x and fraction into +1 +2 +3
  $BF72,13 down: page, line and fraction into +4 +5 +6

@ $BF7F label=moved_x
g $BF7F A record's place across after its move
D $BF7F The x and the page across of a record's box after this pass's
. move, or of the part being tested (#R$BE8F, #R$BE26, #R$BE43).
B $BF7F,2,2

@ $BF81 label=moved_y
g $BF81 A record's place down after its move
D $BF81 The line and the page down of a record's box after this pass's
. move, or of the part being tested (#R$BE8F, #R$BE10, #R$BE43).
B $BF81,2,2

@ $BF83 label=sprite_screen_pos
g $BF83 Where the ship's picture is drawn
D $BF83 The screen x and line the ship's picture (or a part drawn with it)
. is drawn at, set by #R$C3E3 and #R$C27F; #R$BF85 moves the x for a
. mirrored one.
B $BF83,2,2

@ $BF85 label=mirror_ship_sprite
c $BF85 Draw the ship's sprite mirrored when it faces left
D $BF85 The ship's sprite is drawn the right way round facing right. Facing left (#R$C8FD bit 7) the drawing starts at its right-hand byte -- x moved by the width less one, in bytes (#R$5C28), times 8 -- and runs right to left through a blitter that turns each byte round with the table at #R$F900 (B = $F9): #R$A7A4 for a width of 6 bytes, or one of its later entries for 5, 4, or 3 or fewer. #R$C27F comes in at the second instruction with the facing of the thing it draws in A.
R $BF85 IY the blitter for drawing the right way round
R $BF85 O:B $F9, the reversal table's page
R $BF85 O:HL the screen position
R $BF85 O:IY the blitter
  $BF85,3 the ship's facing
  $BF88,6 the position; facing right, as it is
  $BF8E,13 the reversal table; start at the right-hand byte
  $BF9B,29 the blitter by the width
# --------------------------------------------------------------------------
# Agent 6: $BFB8-$D291 -- the ship's pass, its add-ons and trail, the
# parallax stars, the restart point, the panel and fuel gauge, and the start
# of the landscape (its piece tables, the attribute colouring of pieces and
# the map walk at #R$D0BD).
# --------------------------------------------------------------------------

@ $BFB8 label=set_mirrored_drawer
c $BFB8 Choose the mirrored drawer for a sprite when the ship faces left
D $BFB8 The drawing half of #R$BF85: when the ship faces left (bit 7 of its facing byte, #R$C8FD) the image is drawn mirrored. The mirrored drawers (#R$A7D6 on, beside the plain ones that #R$A59F jumps into) work from right to left and look each byte up in the bit-reversal table that #R$F856 builds at the start (page $F9), through BC with B the table's page. So this moves L to the last byte of the row and picks the mirrored drawer for the width. Facing right, it returns with IX as the caller left it.
R $BFB8 L The low byte of the screen address of the image's first row (its left end)
R $BFB8 IX The plain drawer the caller chose
R $BFB8 O:IX The drawer to use: the mirrored one for a width of 6, 5, 4, or anything less
R $BFB8 O:B $F9 when mirrored: the bit-reversal table's page
  $BFB8,6 Facing right: keep the plain drawer.
  $BFBE,2 B is the page of the bit-reversal table (#R$F856), for the mirrored drawer's LD A,(BC).
  $BFC0,6 Start at the right-hand byte of the row: L plus the new width (#R$5C29) less one.
@ $BFC9 nowarn
  $BFC6,29 The mirrored drawer for the width: each is entered further in for a narrower image, as the plain ones are.

@ $BFE3 label=draw_stars
c $BFE3 Move and draw the three layers of parallax stars
D $BFE3 Called each pass from #R$DDF8 after the landscape. Only in the top four rows of the map (the view's map row #R$CE58 below 4: open sky) are there stars; lower down this returns at once. It runs in the build's tour at map row 3.
D $BFE3 There are three layers of six stars. Each layer keeps an x and a y offset (in #R$C184) that is moved each pass by the scroll steps (#R$CCBB across, #R$CCBA down) scaled for the layer by #R$C152: a quarter for the far layer, a half for the middle one, the whole step for the near one. A star's place on the screen is its fixed position in #R$C0E6 plus its layer's offset, wrapping at 256 both ways, so the layers slide past one another at three speeds: parallax for six additions a pass. Last pass's offsets are kept so each star can be erased where it was drawn.
  $BFE3,6 No stars below map row 3.
@ $BFEC nowarn
@ $BFEF nowarn
  $BFE9,11 Keep last pass's offsets (six bytes) for the erasing.
@ $BFF6 nowarn
  $BFF4,6 Three layers, B=3 (the far one) first.
  $BFFA,13 Across: the horizontal step (H, from #R$CCBB) scaled for the layer and added to the layer's x offset.
  $C007,17 Down: the vertical step (L, from #R$CCBA) scaled the same way and added to its y offset.
@ $C018 nowarn
@ $C01E nowarn
@ $C022 nowarn
  $C018,18 Point at the first star in #R$C0E6, the first layer's frame slot (#R$C1A3) and its offsets.
  $C02A,8 Draw the three layers.

@ $C032 label=draw_star_layer
c $C032 Erase and redraw the six stars of one layer
D $C032 One layer of #R$BFE3. For each star: if it was drawn last pass (bit 0 of its x in the table is the 'drawn' flag) its old place is its position plus the layer's old offsets, and the erase is set up there. Its new place is tested by #R$C10E and, if it is inside the play area, the drawing is set up too. #R$A303, the sprite compositor, then erases and draws in one go, and the new attribute cell is made white.
D $C032 A star's image is a graphic number kept in the layer's frame slot: the layer's base number (7, 9 or 11, at +1 of the slot) plus bit 0 of the star's x, since x is held in 2-pixel steps and an odd x takes a copy of the image one pixel further right (see #R$C184).
R $C032 IX The layer's frame slot (two bytes: the frame drawn, then the layer's base graphic number)
  $C032,4 Keep the frame slot; six stars.
  $C036,6 Reset the mover (#R$A2EA) and the 'anything to do' flag at #R$CCBC.
  $C03C,10 Not drawn last pass: nothing to erase.
  $C046,25 Its old place: the star's x (flag off) and y plus the layer's old offsets (six bytes on from the new ones), into the mover's old position at #R$A1D3.
  $C05F,10 There is something to do.
  $C069,2 A jump to a jump: the way round for 'not drawn'.
  $C06B,19 The old image: the layer's base number plus bit 0 of x; then x made even for the screen address.
  $C07E,9 Set up the erase: the image's address (#R$A19F), its height clipped to the play area, and the eraser for its width.
  $C087,13 Work out the new place (the code at #R$C10E); out of sight, clear the 'drawn' flag.
  $C094,33 In sight: set the flag, choose the image for the new x, and set up the drawing the same way.
  $C0B5,17 Anything to erase or draw: do it, and make the star's new attribute cell white ($47).
  $C0C6,10 On to the next star's two bytes.
  $C0D0,7 Six stars.
  $C0D7,15 The next layer's frame slot and offsets are two bytes on.

@ $C0E6 label=star_layer_pointer
g $C0E6 The current star layer's offsets
D $C0E6 Used by #R$BFE3 and #R$C032: the address of the current layer's two offsets in #R$C184, moved on by two for each layer.
W $C0E6,2,2

@ $C0E8 label=star_pointer
g $C0E8 The current star
D $C0E8 Used by #R$C032 and #R$C10E: the address of the current star in #R$C0EA, moved on by two for each star.
W $C0E8,2,2

@ $C0EA label=star_positions
b $C0EA The parallax stars' positions
D $C0EA Eighteen stars of two bytes, six a layer, the far layer first (#R$BFE3): x in pixels -- bit 0 is the 'drawn last pass' flag, set and cleared by #R$C032, which is why every star's x is even -- and y. A star's place on the screen is this plus its layer's offsets (#R$C184).
B $C0EA,36,6

@ $C10E label=star_in_sight
c $C10E Decide whether a star is in sight, and where
D $C10E Called by #R$C032 for each star. The first code map typed these bytes as data, because no session then flew high enough for stars; the tour at map row 3 runs them.
D $C10E The new x is the star's x (flag off) plus the layer's x offset, and the star is out of sight unless that is between 8 and $E7 (inside the frame); the new y is the star's y plus the layer's y offset, out of sight unless between $18 and $B8. In map row 3, the lowest with stars, it is also out of sight once it is level with or below the top of the landscape (y against the complement of the view's y less $31), so stars do not show through the hills.
R $C10E O:F NZ in sight, Z out of sight
  $C10E,8 The layer's offsets and the star.
  $C116,16 x: inside 8 to $E7, or out of sight; into the mover's new x (#R$A1D3's second pair).
  $C126,8 y: inside $18 to $B8, or out of sight.
  $C12E,8 Into the mover's new y. In map row 3 ...
  $C136,8 ... the star must be above the top of the landscape.
  $C13E,20 In sight: say there is something to draw (#R$CCBC) and return NZ; out of sight return Z.

@ $C152 label=parallax_step
c $C152 Scale a scroll step for a parallax layer
D $C152 Divides the step in H by 1, 2 or 4 for the layer in B. A plain arithmetic shift would turn a step of -2 into -1 but +2 into 0 for the far layer, so it would only ever drift one way; instead the far layer takes 0 and -1, or 1 and 0, on alternate passes (bit 0 of the pass counter #R$9A64), and moves at a quarter of the speed either way.
R $C152 B The layer: 1 near, 2 middle, 3 far
R $C152 H The scroll step (signed pixels)
R $C152 O:H The layer's step
  $C152,4 Near layer: the whole step.
  $C156,4 Middle layer: just halve it.
  $C15A,15 Far layer, step -2: no movement on odd passes.
  $C169,19 Far layer, step +2: on odd passes make it 4, so that the quarter is 1.
  $C17C,8 Shift right, keeping the sign, B-1 times.

@ $C184 label=star_offsets
b $C184 The star layers' offsets
D $C184 Each layer's x and y offsets (far, middle, near), moved each pass by #R$BFE3 with the scroll scaled for the layer (#R$C152), wrapping at 256.
B $C184,6,2

@ $C18A label=star_offsets_before
b $C18A Last pass's star layer offsets
D $C18A The copies of #R$C184 made at the start of #R$BFE3, for erasing each star where it was drawn.
B $C18A,6,2

@ $C190 label=star_images
b $C190 The star images
D $C190 Graphics 7 to 11 in the sprite graphic table that #R$A19F reads, drawn without a mask (OR on, AND NOT off) by the small-image mover #R$A303. Each is a width in bytes, a height in rows, then the rows bottom first (everything here is drawn upwards). 7 and 8 are one pixel (at bits 7 and 6), 9 and 10 a two-by-two dot at two positions, 11 a three-row cross. Graphic 12, which an odd x in the near layer would ask for, is not a star; the near layer moves by the whole step, which is always even, so it never is.
B $C190,19,5

@ $C1A3 label=star_frames
b $C1A3 The star layers' frame slots
D $C1A3 Two bytes a layer for #R$C032: the frame drawn, and the layer's base graphic number (7, 9, 11 -- see #R$C190).
B $C1A3,6,2

@ $C1A9 label=ship_height
g $C1A9 The ship's height
D $C1A9 In rows: 14 for the bare ship, more with parts fitted. Set by #R$AFE9 when it builds the ship's image, and changed by 5 by #R$AA37 when a rocket part is hung under the ship or let go (bit 6 of #R$C904); read by #R$C421, #R$C374 and the collision code.
B $C1A9,1,1

@ $C1AA label=ship_graphic
g $C1AA The ship's graphic
D $C1AA The address of the ship's image, which #R$AFE9 builds up from the bare ship (#R$C891) and the parts fitted, in a buffer after the player records; #R$AA37 moves it to take in or leave out a hanging rocket part (bit 6 of #R$C904, not the facing). Read by #R$C421.
W $C1AA,2,2

@ $C1AC label=place_dropped_part
c $C1AC Make an object of a dropped ship part
D $C1AC Used by #R$C1CE when the carried part is put down on the surface: initialises the object record at IX (#R$AC34) and fills in its graphic number ($0C), its kind (+$13), $FF at +$0D, and its place in the world from four bytes at HL. Read only: none of it ran in the build's sessions.
R $C1AC IX The object record
R $C1AC HL Four bytes: map column, map row, x and y in the cell
R $C1AC B The kind (9 or 10)
  $C1AC,3 Clear the record.
  $C1AF,11 Graphic $0C, the kind, and $FF at +$0D.
  $C1BA,20 The map column to +1, the row to +4, x to +2, y to +5.

@ $C1CE label=carried_part
c $C1CE Draw the slab-and-spire load on top of the ship, or put it down on the surface
D $C1CE The load the ship picks up as an object of kind 9 (#R$AAD7 sets +$10 of the player's record, #R$F5F7, to 9) is the slab and the spire, add-ons 10 and 11 (#R$7438, #R$74E9), and rides on top of it in two pieces, 5 bytes wide by $23 rows and 3 wide by $2F rows, drawn by #R$C27F at fixed places above the ship: the slab's bottom line $0D above #R$5C38, which is five lines above the top of the ship's picture, and the spire's $23 higher, standing on the slab. When the ship comes down to the surface (the view's map row, +4 of the ship record, is $0B, the lowest row of the surface above the caverns, and its y in the page is $A7 or more) the load is let go: it is erased and becomes two objects, of kinds 9 and 10, the slab and the spire (#R$C1AC), at the ship's place in the world, the second $10 pixels right and $23 rows up.
D $C1CE Called on even passes from #R$C3E3, every pass of the death sequence (#R$F440) and from #R$9572. Nothing here ran in the build's sessions (+$10 of the player's record was always zero), so this is read only.
  $C1CE,5 Nothing carried: return.
  $C1D3,16 Not yet down on the surface: just draw it.
  $C1E3,15 Let go: bit 6 of #R$C279 makes #R$C27F erase it and not draw it again; nothing is carried any more, and the ship record's +$1F is cleared.
  $C1F2,16 The view's map cell (column in E, row in D) for both new objects (at +$41 and +$45 of the player's record, #R$F5E7).
  $C202,27 The first piece's y in the cell from the ship's screen row (#R$5C38) and its screen y (#R$C903); its x the view's x plus 8, rounded down to 8.
  $C21D,11 The second piece $10 to the right and $23 higher.
  $C228,24 Make them objects of kinds 9 and 10, in the two object records loaded into IX.
@ $C240 nowarn
  $C240,22 The 5-wide piece: its graphic, old and new widths 5, no erase unless #R$C27F decides on one, $23 rows; its place kept at #R$C27B.
@ $C256 nowarn
  $C256,22 The 3-wide piece: its graphic, widths 3, $2F rows; its place kept at #R$C27D.
  $C26C,10 Remember the facing it was drawn with; the forced redraw is done.
  $C276,3 The colour patches over the two pieces (#R$AF04).

@ $C279 label=carried_part_facing
g $C279 The facing the carried load was drawn with
D $C279 Used by #R$C1CE and #R$C27F: the ship's facing byte (#R$C8FD) when the carried load was last drawn, 0 if it has not been; bit 6 set when the load is let go. Cleared when the load is picked up (#R$AAD7).
B $C279,1,1

@ $C27A label=carried_part_redraw
g $C27A Force the carried load to be redrawn
D $C27A Non-zero to make the next pass erase and redraw the carried load (#R$C27F): set by #R$C421 when a part is fitted, and by #R$9572 and #R$F311; cleared by #R$C1CE.
B $C27A,1,1

@ $C27B label=carried_big_x
g $C27B The carried load's larger piece: screen x
D $C27B Where #R$C27F last drew the 5-byte-wide piece of the carried load: x here, y in #R$C27C. Read as a word by #R$AF04 for its colour patch.
B $C27B,1,1

@ $C27C label=carried_big_y
g $C27C The carried load's larger piece: screen y
D $C27C See #R$C27B.
B $C27C,1,1

@ $C27D label=carried_small_x
g $C27D The carried load's smaller piece: screen x
D $C27D Where #R$C27F last drew the 3-byte-wide piece: x here, y in #R$C27E.
B $C27D,1,1

@ $C27E label=carried_small_y
g $C27E The carried load's smaller piece: screen y
D $C27E See #R$C27D.
B $C27E,1,1

@ $C27F label=draw_carried_piece
c $C27F Erase and redraw one piece of the carried load
D $C27F The old image is erased only when it has to be: when the load is let go, when a redraw is forced (#R$C27A), or when the ship has turned since it was drawn (its facing byte against the one kept at #R$C279). Otherwise the new image is drawn over the old one, which is at the same place: the ship does not move on the screen. The place is fixed relative to the ship: x $68 for the 5-wide piece, $78 and $23 rows higher for the 3-wide one, $60 when facing left, and y $0D above the ship's line #R$5C38, just above the ship's top, so the load rides on top of the ship. Facing left, the mirrored eraser and drawer are used (#R$BF85, #R$BFB8). Read only: never ran.
R $C27F IX The piece's place (screen x, y)
R $C27F DE The piece's graphic
R $C27F #R$5C28 The piece's width in bytes (old and new)
  $C27F,1 Keep the graphic.
  $C280,7 Let go: erase it.
  $C287,3 Never drawn: nothing to erase.
  $C28A,15 Erase only if forced, or if the ship faced the other way when it was drawn.
  $C299,57 Set up the erase: the old height is the full height, clipped at the top of the play area (#R$C331); its old place; the eraser for width 5 or 3 (entry points in #R$A629), mirrored if it was drawn facing left (#R$BF85); the screen address.
  $C2D2,15 Let go: no new image; run the mover for the erase alone.
  $C2E1,12 The 5-wide piece: x $68, y the ship's screen row less $0D.
  $C2ED,25 The 3-wide piece: x $78, $23 rows higher, and the narrower drawer.
  $C306,11 Facing left: x $60.
  $C311,32 Draw it: its new place, the height clipped at the top, the screen address, the mirrored drawer if facing left, then erase and draw (#R$A59F).

@ $C331 label=clip_height_to_top
c $C331 Clip a sprite's height at the top of the play area
D $C331 Images are drawn upwards from their bottom row, so one whose bottom row is near the top of the play area would run up into the panel. The play area starts at row $17: the height is cut to the rows between there and y.
R $C331 A The height in rows
R $C331 H The y of the image's bottom row
R $C331 O:B The height to draw
  $C331,6 Rows available (y less $17) at least the height: draw it all.
  $C337,5 Otherwise only the rows available.

@ $C33C label=save_restart_point
c $C33C Remember where to start the next ship, if this is a safe place
D $C33C Called every fourth pass by #R$C374. A place is safe if the bottom pixel row of the play area (from screen address $57C1, 28 bytes) is nothing but the flat ground's dither ($55: the ship is over flat ground filling the bottom of the screen), or if all four map cells on the screen (the four tile bytes kept by #R$DF08) are empty sky (0) or cloud ($A6). Then the view's map cell, its x and y in the cell and the fine scroll are saved in the player's record, where #R$DCA1 finds them when the next ship starts. Bit 0 of the saved x says which kind of place it was (0 over the ground, 1 in the sky): over the ground, #R$DCA1 first paints the dither across the bottom of the play area.
  $C33C,13 Is the bottom row of the play area all ground dither?
  $C349,2 Yes: an over-the-ground restart.
  $C34B,22 Save the view's map cell (#R$CE57), its x and y in the cell (#R$CE45, with bit 0 of x the kind of place) and the origins (#R$CE41) at +$13, +$15 and +$17 of the player's record (#R$F5E7).
  $C361,15 Otherwise every cell on the screen must be sky or cloud.
  $C370,4 A sky restart.

@ $C374 label=ship_pass
c $C374 Move the ship and the world for one pass of the game
D $C374 The first call of each pass of the play loop (#R$F440), and of the death sequence. It counts the pass (#R$9A64), counts the shield pick-up's timer #R$896F down on odd passes, and every fourth pass offers the place as a restart point (#R$C33C). Then, unless the ship is dying or the finished rocket is lifting off (#R$96AB), the controls are read and the ship's speeds worked out (#R$B234, which leaves this pass's scroll steps in #R$CCBA and #R$CCBB), the ship record is given the opposite step (#R$B9EC) and tested against the landscape (#R$BA21) and the other objects (#R$A8F4), and the record is moved (#R$BF66).
D $C374 It ends by jumping to #R$DDF8, which scrolls the view, redraws the landscape and the stars, and jumps on to #R$C3E3 to draw the ship: IY, pushed here, is popped there.
  $C374,7 Count the pass.
  $C37B,14 On odd passes, run the shield timer down.
  $C389,6 Every fourth pass, perhaps a restart point.
  $C38F,2 Kept for #R$C3E3.
  $C391,7 No scroll unless the ship moves.
  $C398,7 Dying (death byte $0B or more): no movement.
@ $C39F nowarn
  $C39F,7 Read the controls and work out the ship's speeds and this pass's scroll.
  $C3A6,5 #R$5C25 = $FF: a marker for the landscape test (#R$BA21 clears #R$BC12 if it is still $FF afterwards).
  $C3AB,6 The finished rocket is lifting off (#R$96AB): no tests.
  $C3B1,3 The ship record's step is minus the scroll.
  $C3B4,20 Test it against the landscape: B the ship's height plus 4 (plus nothing with the add-on at +$0F of the player's record).
  $C3C8,3 Test it against the other objects (this is what calls the damage routine).
  $C3CB,12 Keep a copy of the ship record's two step words (at #R$C8FE and #R$C900).
  $C3D7,6 Set the step again and move the record by it.
  $C3DD,6 Then the landscape, and the ship.

@ $C3E3 label=draw_ship
c $C3E3 Draw the ship, its trail and its jets
D $C3E3 Reached by a jump from #R$DDF8 at the end of each pass's landscape drawing; returns to the play loop. IY was pushed by #R$C374.
D $C3E3 The ship stays where it is on the screen and the world moves under it, so its image is drawn over itself and only erased when it changes: when the ship turns (the steering direction #R$5C36 against the facing byte, +$18 of the ship record), when a part is being fitted (+$1F of the record, #R$C904), or while docking with the finished rocket (death byte 10). It is redrawn on every odd pass, and on even passes only when one of those things happens; on even passes the carried part (#R$C1CE) is drawn instead.
D $C3E3 The ship's image is #R$C421; then come the trail (#R$C4ED), the pause key (#R$9F54), the fire button (#R$B731), and one of the two jets: the lift jet (#R$C6D2) on even passes, the side jet (#R$C5FF) on odd ones.
D $C3E3 All of them are drawn by #R$A59F, which interleaves an erase of the old image (main registers: DE the graphic, HL the screen, IY the eraser for its width, #R$5C1C its height, #R$A289 its y) with the drawing of the new (alternate registers, IX the drawer, #R$5C1D the height, the byte after #R$A289 the y), a row of each in turn, so that nothing is ever missing from the screen for long. Images are drawn with OR and erased with AND NOT, without masks.
  $C3E3,2 IY as it was before #R$C374.
  $C3E5,11 Nothing to draw once the rocket is lifting off or the ship is dying.
  $C3F0,3 First #R$9724, which lets a carried rocket part go over its slot.
  $C3F3,7 Odd pass: redraw the ship.
  $C3FA,3 Even pass: the carried part.
  $C3FD,19 Redraw the ship anyway when a part is being fitted, while docking with the finished rocket (death byte 10) or when #R$BC12 is set.
  $C410,17 Otherwise only when it is steered the other way from the way it faces.
@ $C421 label=draw_ship_image
c $C421 Erase and redraw the ship's image
D $C421 Entered from #R$C3E3 on odd passes or when the image must change, and called by #R$9572. The old image is erased only on a turn, while a part is being fitted (#R$C904) or while docking with the finished rocket (death byte 10); the new one is drawn at the same place (#R$C902, #R$C903), mirrored if the ship now faces left. Then on into #R$C4ED.
@ $C433 nowarn
  $C421,22 No erase so far (old height 0), y the ship's (#R$C903), widths 6, IX the ship record.
  $C437,7 Docking with the rocket: erase it.
  $C43E,21 Turning? #R$C7C0 says so (the trail is then redrawn too), and the fire delay is cleared.
@ $C463 nowarn
  $C453,30 Set up the erase: the old graphic (#R$C1AA), height (#R$C1A9) and place (#R$C902), the 6-wide eraser, mirrored if it faced left (#R$BF85).
  $C471,6 A part being fitted?
  $C477,14 One with bit 7 set is drawn by #R$AA37.
@ $C499 nowarn
  $C485,38 Otherwise it goes into the player's list of parts (from +7 of #R$F5E7), the old image is erased now, the ship's graphic rebuilt with it (#R$AFE9), and the erase set up again for nothing (read only).
  $C4AB,6 Not turning: erase only if a part is being fitted.
  $C4B1,9 Being steered: the facing byte follows.
  $C4BA,7 Docking: no new image.
@ $C4DA nowarn
  $C4C1,32 The new image at the same place, with the current graphic and height, mirrored if it now faces left.
  $C4E1,3 Erase and draw.
  $C4E4,3 Colour the ship (#R$F1BD).
  $C4E7,6 Docking or dying: stop here.
@ $C4ED label=draw_trail
c $C4ED Erase and redraw the ship's trail
D $C4ED The trail is a one-byte-wide line behind the ship whose bend follows the speed across (#R$C8FE): the frame is 1 + twice the whole pixels + the half, no more than one past the top speed, mirrored with the direction (record #R$C7BC-#R$C7C1, images #R$C7C8). It is erased only when the frame changes, the ship turns (#R$C7C0) or the collision code asks (#R$D0BC). Also called at the start of each life and of the death sequence (#R$F440; dying, it is only erased) and by #R$9572. Then on to the pause key, the fire button and the jets.
@ $C4F3 nowarn
  $C4ED,25 The trail: its old frame and place (#R$C7BC) for the erase.
  $C506,19 The 1-byte eraser, or the mirrored one (#R$C7B1).
  $C519,4 Keep the old frame in E.
  $C51D,23 A part being fitted: the trail hangs lower (#R$5C38 less 9) and is redrawn.
  $C534,23 The ship's speed across (the step word kept at #R$C8FE, the whole pixels in the high byte): under half a pixel, flagged as moving right (#R$C7BF bit 7).
  $C54B,8 Otherwise its sign; moving the other way, take its size.
  $C553,23 Frame = 1 + twice the whole pixels + the half: the faster, the further bent; no more than one past the top speed (#R$5C3E).
  $C56A,22 A countdown at #R$C7C1 (alive only) holds the frame at 6.
  $C580,28 Same frame, no turn and no collision (#R$D0BC): no erase needed.
  $C59C,30 The new image: x $68, or $78 facing left, at the trail's y.
  $C5BA,21 The 1-byte drawer, or the mirrored one 8 pixels further right.
  $C5CF,3 Erase and draw.
  $C5D2,4 The collision flag is dealt with.
  $C5D6,20 Unless it is frame 6, the attribute cell 7 rows above its bottom made white.
  $C5EA,6 The pause key and the fire button.
  $C5F0,15 Alive, on even passes: the lift jet.
@ $C5FF label=side_jet
c $C5FF Erase and redraw the side jet behind the ship
D $C5FF Reached from #R$C4ED on odd passes, and called by #R$9F54 during the pause. The add-on fitted when +$0A of the player's record (#R$F5E7) is set (which also raises the top speed across, #R$5C3E, to 4: #R$AFE9) flickers behind the ship while it is steered left or right: graphics $0E-$10 through the sequence #R$C7A9, with the record #R$C6C2 and a 2x2 colour patch whose colour cycles through #R$C79B. It ran in the build's every-add-on session, but never mirrored: the erase and the draw for steering left are read only.
D $C5FF The end, from the colour patch on, is also used by #R$C6D2.
  $C5FF,5 Not fitted: return.
@ $C604 nowarn
  $C604,24 Its record (#R$C6C2). Not drawn last pass: nothing to erase, and nothing to do unless steering left or right.
  $C61C,25 Set up the erase from its last frame and place, mirrored if it was.
  $C635,13 Not drawn now; not steering: just erase.
  $C642,7 Dying or docking: just erase.
@ $C652 nowarn
  $C649,21 Next frame of the flicker: a count of 0-7 through #R$C7A9 gives graphic $0E, $0F or $10.
  $C65E,10 Its height; drawn now.
  $C668,35 Behind the ship, 8 rows below its screen row: x $50 steering right; steering left x $98, mirrored (bit 6), with the mirrored drawer.
  $C68B,6 Its screen address, kept for the next erase.
  $C691,3 Erase and draw.
  $C694,20 Drawn: a colour patch over it chosen by the flicker count.
@ $C6AF nowarn
@ $C6BC nowarn
  $C6A8,26 The patch for #R$C991, two cells by two, its colour from #R$C79B (#R$C6D2 comes in here).

@ $C6C2 label=side_jet_record
b $C6C2 The side jet's sprite record
D $C6C2 Used by #R$C5FF. +0 the graphic number ($0E-$10); +1 +2 the screen address it was drawn at; +3 bit 7 drawn, bit 6 mirrored (steering left); +4 +5 its screen x and y; +6 the flicker count (0-7).
B $C6C2,7,7

@ $C6C9 label=side_jet_start
b $C6C9 The side jet's record at the start of a life
D $C6C9 Copied over #R$C6C2 by #R$F311.
B $C6C9,7,7

@ $C6D0 label=lift_jet_skip
g $C6D0 Skip the lift jet for a pass
D $C6D0 Set by #R$BA8F; makes #R$C6D2 erase the lift jet without drawing it again, for one pass. The byte after it is not used.
B $C6D0,2,1

@ $C6D2 label=lift_jet
c $C6D2 Erase and redraw the lift jet under the ship
D $C6D2 The add-on fitted when +$0B of the player's record (#R$F5E7) is set (which also raises the top vertical speed #R$5C3F to 4, #R$AFE9, and lets the ship climb above map row 5, #R$B115) is drawn under the ship on even passes: graphic $12, or $11 while thrusting (control bit 3). It is drawn mirrored and not in turn (bit 6 of +3 flips each time), so it seems to spin. While the finished rocket lifts off it is drawn at the rocket's height. With the ship dying (death byte 10 or more) it is only erased, which is why the death sequence (#R$F440) calls this once at its start. Its 2x2 attribute patch is white. It ran in the build's every-add-on session, all but the lift-off branch: the launch session had no lift jet.
D $C6D2 Stage 0 took this for the death sequence; it is not: the death sequence calls it to take the jet off the screen.
  $C6D2,5 Not fitted: return.
@ $C6D7 nowarn
  $C6D7,13 Its record (#R$C78F); nothing to erase yet.
  $C6E4,31 Drawn last pass: set up the erase, mirrored if it was.
  $C703,5 Not drawn now.
  $C708,6 Skipped this pass (#R$C6D0).
  $C70E,11 Graphic $12; dying or docking, just erase.
  $C719,11 Thrusting: graphic $11.
  $C724,16 Its height; drawn, and mirrored if it was not last time.
  $C734,18 The rocket lifting off: at the rocket's height, graphic $11.
  $C746,17 Otherwise $1D rows below the ship's screen row (#R$5C38), 8 less for graphic $12.
  $C757,20 x $68, or $80 with the mirrored drawer.
  $C76B,9 Its place and screen address, kept for the next erase.
  $C774,7 Erase and draw; the skip flag is used up.
  $C77B,20 Drawn: a white 2x2 patch 7 rows above it at x $70.

@ $C78F label=lift_jet_record
b $C78F The lift jet's sprite record
D $C78F Used by #R$C6D2. +0 the graphic ($12 or $11); +1 +2 the screen address it was drawn at; +3 bit 7 drawn, bit 6 mirrored; +4 +5 its screen x and y.
B $C78F,6,6

@ $C795 label=lift_jet_start
b $C795 The lift jet's record at the start of a life
D $C795 Copied over #R$C78F by #R$F311.
B $C795,6,6

@ $C79B label=jet_colours
b $C79B Side jet colours
D $C79B Eight attributes for the jets' colour patches, chosen by the side jet's flicker count (#R$C3E3): red, yellow, magenta, blue, yellow, magenta, red, white, all bright. The lift jet uses the last.
B $C79B,8,8

@ $C7A3 label=sprite_graphic_width
c $C7A3 Get a jet's graphic and its height
D $C7A3 The graphic's address for the sprite record at IX (#R$A19F), and its first byte. Only the jets use this (#R$C5FF, graphics $0E-$10; #R$C6D2, $11 and $12), whose pictures are in the height-first form (#R$7846), so the byte is the height in lines, not a width.
R $C7A3 IX The sprite record (+0 the graphic number)
R $C7A3 O:A The height
R $C7A3 O:DE The graphic's address plus one
  $C7A3,6 Look it up and read the height.

@ $C7A9 label=side_jet_frames
b $C7A9 The side jet's flicker sequence
D $C7A9 Eight steps of the side jet's animation (#R$C3E3), each added to graphic $0E. Not a plain cycle, so it flickers.
B $C7A9,8,8

@ $C7B1 label=trail_mirror
c $C7B1 Use the mirrored trail image, depending on the speed's sign
D $C7B1 For the trail (#R$C3E3): when bit 7 of #R$C7BF is clear, returns Z with B the bit-reversal page and L one byte further right, for a mirrored eraser or drawer; otherwise returns NZ.
  $C7B1,6 Bit 7 set: the plain image.
  $C7B7,5 Mirrored, one byte to the right.

@ $C7BC label=trail_frame
g $C7BC The trail's frame
D $C7BC The graphic number (1-6, #R$C7C8) of the ship's trail as last drawn by #R$C4ED. With the next five bytes it is the trail's record, reset each life from #R$C7C2.
B $C7BC,1,1

@ $C7BD label=trail_x
g $C7BD The trail's screen x
D $C7BD $68, or $78 facing left (#R$C4ED).
B $C7BD,1,1

@ $C7BE label=trail_y
g $C7BE The trail's screen y
D $C7BE Its bottom row (#R$C4ED); lower while a part is being fitted.
B $C7BE,1,1

@ $C7BF label=trail_direction
g $C7BF The trail's direction
D $C7BF Bit 7 set while the ship's speed across is positive, or under half a pixel; otherwise clear and the trail is drawn mirrored (#R$C4ED, #R$C7B1).
B $C7BF,1,1

@ $C7C0 label=ship_turned
g $C7C0 The ship turned this pass
D $C7C0 Bit 7 set by #R$C421 on a pass the ship turns round; it makes #R$C4ED erase and redraw the trail.
B $C7C0,1,1

@ $C7C1 label=trail_hold
g $C7C1 Hold the trail straight
D $C7C1 A countdown: set to 4 by the collision code when the ship hits a ceiling (#R$BA8F: a box of class bit 3, #R$D0AC) without add-on 9, and counted down by #R$C4ED, which holds the trail at frame 6 while it runs.
B $C7C1,1,1

@ $C7C2 label=trail_start
b $C7C2 The trail's record at the start of a life
D $C7C2 Copied over #R$C7BC-#R$C7C1 by #R$F311.
B $C7C2,6,6

@ $C7C8 label=trail_images
b $C7C8 The trail's six images
D $C7C8 Graphics 1 to 6 (in the sprite graphic table that #R$A19F reads), each one byte wide and 8, 8, 7, 6, 5 and 4 rows high: a width, a height and the rows, bottom first. A line rising from its bottom row and leaning further over at each step, frame 6 a short curve. One byte is 8 pixels: the bend is in the images, not made by shifting. What the trail is in the game has not been seen: drawn behind the ship and bent by its speed across, it looks like a plume.
B $C7C8,10,10 Graphic 1: 8 rows
B $C7D2,10,10 Graphic 2: 8 rows
B $C7DC,9,9 Graphic 3: 7 rows
B $C7E5,8,8 Graphic 4: 6 rows
B $C7ED,7,7 Graphic 5: 5 rows
B $C7F4,6,6 Graphic 6: 4 rows

@ $C7FA label=ship_position_across
g $C7FA The ship's running position across
D $C7FA A word moved by the speed across each pass (#R$C81F): twice the change in its high byte is the pass's horizontal scroll. Zeroed when coasting brings the ship to a stop (#R$C7FC).
W $C7FA,2,2

@ $C7FC label=accelerate_across
c $C7FC Accelerate the ship across, and work out this pass's horizontal scroll
D $C7FC Called by #R$B234 with the thrust (or the drag) for this pass. The ship's speed across is a word at +$19/+$1A of its record, whole pixels in the high byte (stored high byte first). The thrust is added and the speed clamped to the top speed (#R$C868). With the controls off the drag must not turn the ship round, so a speed that changes sign is made zero instead.
D $C7FC Then #R$C81F turns the speed into this pass's horizontal scroll.
R $C7FC IX The ship record
R $C7FC DE The thrust or drag this pass (8.8 fixed point)
  $C7FC,11 Add the thrust and clamp.
  $C807,18 Not steering, and the speed changed sign: stop dead, the position word too.
  $C819,6 The new speed.
@ $C81F label=speed_to_scroll
c $C81F Turn the speed across into this pass's horizontal step
D $C81F The second half of #R$C7FC, also used by #R$BA8F. The speed is added to the running position word #R$C7FA, and twice the change in its high byte is the step in pixels (the landscape moves in 2-pixel steps). A step of the top speed (#R$5C3E) plus 2 is cut to the top speed. The step goes to #R$CCBB. One last rule: a step of 4 taken when the fine scroll (#R$CE41) is at 2 or 6 is halved, so 4-pixel steps start only from 0 or 4.
R $C81F HL The speed across (8.8)
  $C81F,12 The position word moves by the speed; the step is twice the change in its whole part.
  $C82B,17 The limit: the top speed (#R$5C3E) plus 2, with the step's sign.
  $C83C,19 A step at the limit becomes the top speed.
  $C84F,10 This pass's horizontal scroll; anything but a 4-pixel step is done.
  $C859,15 A 4-pixel step from 2 or 6 becomes 2.

@ $C868 label=clamp_speed_across
c $C868 Keep the speed across within the top speed
D $C868 The whole part of the speed may be no more than half the top speed (#R$5C3E) one way, or one more than that the other (the fraction is kept).
R $C868 H The whole part of the speed
  $C868,18 Negative: no less than minus half the top speed, less one.
  $C87A,6 Positive: no more than half the top speed.

@ $C880 label=clamp_object_speed
c $C880 Keep a speed between -3 and 2
D $C880 Used by the object routines (#R$BA8F, #R$BD04 and #R$BD44) on a speed's whole part.
R $C880 H The whole part of the speed
  $C880,11 Negative: -1 and -2 stand, anything less becomes -3.
  $C88B,6 Positive: 0 and 1 stand, anything more becomes 2.

@ $C891 label=bare_ship
b $C891 The bare ship
D $C891 The ship with no parts fitted, 6 bytes by 14 rows, bottom row first and no width or height bytes. #R$AFE9 copies it to the bottom of the buffer where the ship's image is built up with the parts the player has fitted.
B $C891,84,6

@ $C8E5 label=ship_record
b $C8E5 The ship record
D $C8E5 32 bytes, #R$C8E5-#R$C904, laid out like the other objects' records, many of them used by name and given entries of their own: +1 #R$C8E6 the map column and +2 +3 #R$C8E7 the x in the page and its fraction, +4 #R$C8E9 the map row and +5 +6 #R$C8EA the y and fraction (this is the view's place in the world: the screen moves with the ship); +7 +8 #R$C8EC and +9 +A #R$C8EE the speeds (or this pass's step) across and down; +$0B-$17 #R$C8F0; +$18 #R$C8FD the facing; +$19 +$1A #R$C8FE and +$1B +$1C #R$C900 the speeds across and up; +$1D #R$C902 and +$1E #R$C903 the ship's place on the screen; +$1F #R$C904 a part being fitted. Reset each life from #R$C906 (#R$F311).
D $C8E5 +0 here is 0 (an object's graphic number in the other records).
B $C8E5,1,1

@ $C8E6 label=view_page_column
g $C8E6 The ship record: map column
D $C8E6 +1 of #R$C8E5: the column of the page the view is in.
B $C8E6,1,1

@ $C8E7 label=view_page_x
g $C8E7 The ship record: x in the page
D $C8E7 +2 +3 of #R$C8E5: x and its fraction.
B $C8E7,2,2

@ $C8E9 label=view_page_row
g $C8E9 The ship record: map row
D $C8E9 +4 of #R$C8E5: the row of the page the view is in. Map row $0B, the lowest of the surface, is where #R$C1CE puts the carried part down; #R$9572 looks for the rocket's place.
B $C8E9,1,1

@ $C8EA label=view_page_y
g $C8EA The ship record: y in the page
D $C8EA +5 +6 of #R$C8E5: y and its fraction.
B $C8EA,2,2

@ $C8EC label=ship_dx
g $C8EC The ship record: the speed across, or the step
D $C8EC +7 +8 of #R$C8E5, high byte first. #R$B9EC sets it to minus this pass's horizontal scroll so that #R$BF66 moves the record; the collision code (#R$BE8F) copies the speed across (#R$C8FE) into it to test the move, may reverse and halve it (#R$AA27), and #R$C374 copies it back.
W $C8EC,2,2

@ $C8EE label=ship_dy
g $C8EE The ship record: the speed down, or the step
D $C8EE +9 +A of #R$C8E5, as #R$C8EC for the vertical: #R$C900 is its speed.
W $C8EE,2,2

@ $C8F0 label=ship_record_middle
b $C8F0 The ship record: +$0B to +$17
D $C8F0 Nothing in this range uses these bytes by name; +$0D holds $47 at the start, the ship's colour it seems.
B $C8F0,13,8

@ $C8FD label=ship_facing
g $C8FD The ship's facing
D $C8FD +$18 of #R$C8E5: bit 7 set facing left. Set from the steering (#R$C421); read wherever the ship and its add-ons are drawn mirrored (#R$BF85, #R$BFB8, #R$C27F).
B $C8FD,1,1

@ $C8FE label=ship_across_speed
g $C8FE The ship's speed across
D $C8FE +$19 +$1A of #R$C8E5, 8.8 fixed point stored high byte first: accelerated and clamped by #R$C7FC, copied back from #R$C8EC after the collision tests (#R$C374); read by #R$C4ED for the trail's bend.
W $C8FE,2,2

@ $C900 label=ship_down_speed
g $C900 The ship's climb speed
D $C900 +$1B +$1C of #R$C8E5, the same for the vertical, up positive: gravity takes from it and thrust adds to it (#R$B234).
W $C900,2,2

@ $C902 label=ship_screen_x
g $C902 The ship's screen x
D $C902 +$1D of #R$C8E5: $60. The ship does not move on the screen; the world does.
B $C902,1,1

@ $C903 label=ship_screen_y
g $C903 The ship's screen y
D $C903 +$1E of #R$C8E5: $6F at the start, the row the ship is drawn up from; changed by #R$AFE9 when parts make the ship taller.
B $C903,1,1

@ $C904 label=part_being_fitted
g $C904 A part being fitted to the ship
D $C904 +$1F of #R$C8E5. Set when the ship picks up a part (#R$AAD7: the kind plus one, or $C0 plus the rocket part's number for a rocket part); while it is non-zero #R$C421 erases and redraws the ship, fitting the part (#R$AFE9) or hanging a rocket part under it (#R$AA37).
B $C904,1,1

@ $C905 label=ore
g $C905 The ore collected
D $C905 Part 6 of the rocket needs 18. Kept in the player's record between lives (#R$F440, #R$F4C6).
B $C905,1,1

@ $C906 label=ship_record_start
b $C906 The ship record at the start of a life
D $C906 Copied over #R$C8E5 by #R$F311 (32 bytes); the byte after it is not used.
B $C906,33,8

@ $C927 label=score_bitmap
b $C927 The bitmap under the scores
D $C927 4 bytes by 9 rows (a width, a height, the rows bottom first), drawn under each player's score by #R$CA3F.
B $C927,38,8

@ $C94D label=edge_ornament
b $C94D The frame's ornament for the top and bottom edges
D $C94D 1 byte by 6 rows (#R$CACB).
B $C94D,8,8

@ $C955 label=side_ornament
b $C955 The frame's ornament for the sides
D $C955 1 byte by 6 rows (#R$CACB).
B $C955,8,8

@ $C95D label=panel_leftovers
b $C95D Unreferenced bytes
D $C95D Nothing refers to these 18 bytes (searched); they look like the remains of text records.
B $C95D,18,6

@ $C96F label=draw_bitmap
c $C96F Copy a bitmap to the screen
D $C96F Draws a byte-aligned bitmap with no mask, overwriting what is there: a width in bytes, a height in rows, then the rows, bottom row first, drawn upwards from the given pixel position (#R$A1C3 steps up a row). Used for the panel and the play area's frame.
R $C96F H The y of the bottom row
R $C96F L The x (a multiple of 8)
R $C96F DE The bitmap
R $C96F O:DE The byte after it
  $C96F,14 Read the width and height; the screen address (#R$A149).
  $C97D,19 Each row: copy the bytes, then up one pixel row.

@ $C991 label=fill_attributes
c $C991 Apply a colour patch
D $C991 Fills a rectangle of attribute cells with one attribute, from a three-byte record: width in cells, height in cells, attribute. The rectangle is given by its bottom-left pixel and filled upwards. Every sprite's colour comes from such a patch: the patch is all the colour a sprite has, so a sprite takes the colour of the cells it is in (#R$AE98 works the patches out for the objects).
R $C991 H The y of the bottom row
R $C991 L The x
R $C991 DE The record
R $C991 O:DE The byte after it
  $C991,8 Width in B, height in C, and the attribute address (#R$A170).
  $C999,6 The attribute in D.
  $C99F,20 Each row of cells: fill it, then up a row (32 bytes back).

@ $C9B3 label=unused_attribute_bitmap
b $C9B3 An unused bitmap-to-attributes routine
D $C9B3 Code nothing calls (searched): #R$C96F written for the attributes (a width, a height and the attribute bytes, each row filled upwards). A leftover, kept as data.
B $C9B3,39,8

@ $C9DA label=score_labels
b $C9DA The panel's text records: 'SCORE' twice
D $C9DA The first of the panel's eight text records, printed by #R$CA3F through #R$83CE and #R$A115. Each is x, y (pixels), an attribute (bit 7 for double height), a length, and the characters in the game's own font (#R$9F76, 7 rows a character; codes $1A-$23 are the digits). Here: 'SCORE' for each player, white. The others follow: #R$C9EC, #R$C9F6, #R$C9FC, #R$CA06, #R$CA0C, #R$CA12.
B $C9DA,18,9

@ $C9EC label=p1_score_text
b $C9EC The panel's text records: player 1's score
D $C9EC x, y, the attribute (set by #R$CA3F: yellow for the player in play, red for the other) and the length; the six digits follow at #R$C9F0.
B $C9EC,4,4

@ $C9F0 label=p1_score_digits
b $C9F0 Player 1's score
D $C9F0 Six digit codes ($1A-$23) of the text record #R$C9EC: the score as it is kept and printed.
B $C9F0,6,6

@ $C9F6 label=p1_lives_text
b $C9F6 The panel's text records: player 1's lives
D $C9F6 x, y, attribute, length 2, then a '0' and the digit at #R$C9FB. Its x is tested by #R$F3BD to see which player's record is in front.
B $C9F6,5,5

@ $C9FB label=p1_lives_digit
g $C9FB Player 1's lives digit
D $C9FB The lives less one plus $19 (#R$CA31): the ship in play is not counted.
B $C9FB,1,1

@ $C9FC label=p2_score_text
b $C9FC The panel's text records: player 2's score
D $C9FC As #R$C9EC; the digits at #R$CA00.
B $C9FC,4,4

@ $CA00 label=p2_score_digits
b $CA00 Player 2's score
D $CA00 Six digit codes of the text record #R$C9FC.
B $CA00,6,6

@ $CA06 label=p2_lives_text
b $CA06 The panel's text records: player 2's lives
D $CA06 As #R$C9F6; the digit at #R$CA0B.
B $CA06,5,5

@ $CA0B label=p2_lives_digit
g $CA0B Player 2's lives digit
D $CA0B All the waiting player's lives plus $1A (#R$CA3F).
B $CA0B,1,1

@ $CA0C label=hi_label
b $CA0C The panel's text records: 'HI'
D $CA0C The heading over the high score: one of the panel's text records, laid out as #R$C9DA says (x, y, attribute, length, then the characters in the game's font).
B $CA0C,6,6

@ $CA12 label=hiscore_text
b $CA12 The panel's text records: the high score
D $CA12 x, y, attribute, length; the six digits at #R$CA16.
B $CA12,4,4

@ $CA16 label=hiscore_digits
b $CA16 The high score
D $CA16 Six digit codes of the text record #R$CA12.
B $CA16,6,6

@ $CA1C label=player_in_play
g $CA1C The player in play
D $CA1C 0 for player 1 or 1 for player 2 (#R$F3BD, #R$F591, #R$F4EE); also $99 for a moment while #R$F3BD puts the score lines back. Not part of the text.
B $CA1C,1,1

@ $CA1D label=frame_description
b $CA1D The play area's frame
D $CA1D The 17-byte description #R$CACB draws the frame from (see there for the layout): the two sides, the two horizontal edges, the corner list (#R$CBF8), the ornament list (#R$CBE5) and the ornaments' places.
B $CA1D,17,9

@ $CA2E label=panel_patch
b $CA2E The colour patch behind the top of the panel
D $CA2E 20 cells by 2, white (#R$CA3F, through #R$C991).
B $CA2E,3,3

@ $CA31 label=print_lives
c $CA31 Print the lives of the player in play
D $CA31 The number shown is the lives less one: the ship in play is not counted. The digit codes start at $1A, so lives plus $19.
@ $CA39 nowarn
  $CA31,14 Make the digit and print the record at #R$C9F6 (#R$A115).

@ $CA3F label=draw_panel
c $CA3F Draw the panel and the play area's frame
D $CA3F Called by #R$F422 before a game and by #R$F440 at the start of each life. Player 1's score in yellow and player 2's in red, the colour patch behind the panel's top, both players' lives, the eight text records from #R$C9DA, a bitmap under each score, the frame (#R$CACB), the fuel gauge (the entry at the end of #R$CAA7, #R$CBAE) and the word 'FUEL' beside it.
  $CA3F,10 Score colours: player 1 yellow, player 2 red.
@ $CA4C nowarn
  $CA49,9 The white patch behind the top of the panel.
  $CA52,11 Player 1's lives; player 2's digit is all its lives (+6 of #R$F650, plus $1A).
@ $CA5D nowarn
  $CA5D,8 The eight text records.
@ $CA68 nowarn
@ $CA71 nowarn
  $CA65,18 The bitmap under each score.
@ $CA77 nowarn
@ $CA7B nowarn
@ $CA84 nowarn
  $CA77,25 The frame: its corners at #R$CBF8, its ornaments' places at #R$CBE5.
  $CA90,6 The gauge: its colour and its outline.
@ $CA9A nowarn
  $CA96,10 The cyan patch behind the label.
@ $CAA1 nowarn
  $CAA0,7 The label, 2 bytes by 32 rows, at x $F0 (#R$CB66).

@ $CAA7 label=flash_fuel_gauge
c $CAA7 Colour the fuel gauge, flashing red when fuel is low
D $CAA7 On odd passes only. With fuel low (the high byte of #R$CC4B, $98 or more: about seven tenths used) the gauge's colour patch (2 cells by 16, at x $F0) is red on two passes in four and yellow on the others; otherwise yellow. From the entry point near its end (used by #R$CA3F): always yellow.
  $CAA7,7 Even passes: nothing.
  $CAAE,15 Low and bit 1 of the pass counter set: red.
  $CABD,2 Yellow.
@ $CAC2 nowarn
@ $CAC5 nowarn
  $CABF,12 Set the patch's attribute and apply it.

@ $CACB label=draw_frame
c $CACB Draw the play area's frame
D $CACB From a 17-byte description at IX (#R$CA1D for the game; the menu, #R$F26C, has its own). It draws the two sides, the two edges top and bottom, the four corner pieces with their colour patches, and the ornaments along the edges.
D $CACB The description: +0 +1 and +2 +3 the screen addresses of the bottom of the left and right sides; +4 their height in rows (each row a byte of $66); +5 +6 and +7 +8 the screen addresses of the two horizontal edges (each two double lines of $FF bytes, with a two-row gap); +9 +A the corner list (four entries of seven bytes: the bitmap's place, the colour patch's place, the patch's width, height and attribute; the bitmaps follow one another from #R$CC14, #R$CBF8); +B the number of ornaments; +C +D their list (pairs: an x for the top and bottom edges, a y for the sides); +E the y of the bottom edge's ornaments (the top's is $BE); +F the x of the right side's (the left's is 0); +$10 the edges' width in bytes.
R $CACB IX The frame's description
  $CACB,15 The two sides' addresses and height.
  $CADA,13 The sides, upwards, a $66 byte each row.
  $CAE7,28 The two horizontal edges: two rows, a gap of two rows, two rows.
@ $CB03 nowarn
  $CB03,7 The corner bitmaps start at #R$CC14.
  $CB0A,34 Four corners: a bitmap, then its colour patch.
@ $CB3C nowarn
@ $CB44 nowarn
  $CB2C,31 Each ornament: one at its x on the bottom edge and one on the top.
@ $CB51 nowarn
@ $CB5A nowarn
  $CB4B,26 And one at its y on the left side and one on the right.

@ $CB66 label=fuel_label
b $CB66 The fuel gauge's label
D $CB66 The word 'FUEL' set vertically: a bitmap 2 bytes by 32 rows (a width, a height, the rows bottom first), drawn beside the gauge by #R$CA3F.
B $CB66,66,8

@ $CBA8 label=fuel_label_patch
b $CBA8 The fuel label's colour patch
D $CBA8 Cyan, 2 cells by 4 (#R$CA3F).
B $CBA8,3,3

@ $CBAB label=gauge_patch
b $CBAB The fuel gauge's colour patch
D $CBAB 2 cells by 16; its attribute follows at #R$CBAD (#R$CAA7).
B $CBAB,2,2

@ $CBAD label=gauge_colour
g $CBAD The fuel gauge's colour
D $CBAD Yellow, or red when fuel is low (#R$CAA7).
B $CBAD,1,1

@ $CBAE label=draw_fuel_gauge
c $CBAE Draw the fuel gauge's outline
D $CBAE The gauge is a tube at x $F0-$FF: a cap at the foot (line $BF, #R$CBDB) and one at the top (line $43, #R$CBD1), each 2 bytes by 4 rows, and between them 120 rows of two single-pixel walls ($10 in each byte). The fuel inside is drawn by #R$CC77.
@ $CBAE nowarn
@ $CBB1 nowarn
@ $CBBA nowarn
  $CBAE,18 The two caps.
  $CBC0,17 The walls, upwards.

@ $CBD1 label=gauge_bottom_cap
b $CBD1 The fuel gauge's top cap
D $CBD1 2 bytes by 4 rows, closed at the top: drawn at line $43, the top of the tube (#R$CBAE). The label says bottom; the picture and its place say top.
B $CBD1,10,10

@ $CBDB label=gauge_top_cap
b $CBDB The fuel gauge's bottom cap
D $CBDB 2 bytes by 4 rows: drawn at line $BF, the foot of the tube (#R$CBAE). The label says top; its place says bottom.
B $CBDB,10,10

@ $CBE5 label=ornament_places
b $CBE5 The frame's ornament places
D $CBE5 Six pairs for #R$CACB: an x on the top and bottom edges, a y on the sides.
B $CBE5,12,2

@ $CBF1 label=read_word
c $CBF1 Read a word
R $CBF1 DE The word's address
R $CBF1 O:HL The word
R $CBF1 O:DE The address after it
  $CBF1,7 Low byte, then high byte.

@ $CBF8 label=frame_corners
b $CBF8 The frame's corners
D $CBF8 Four entries of seven bytes for #R$CACB: the corner bitmap's place (x, y), then a colour patch's place (x, y), width, height and attribute ($4D: bright cyan on blue). The patches are the frame's colour: the top and bottom edges (30 cells by 1) and the two sides (1 by 20). The bitmaps are at #R$CC14.
B $CBF8,28,7

@ $CC14 label=corner_bitmaps
b $CC14 The frame's corner bitmaps
D $CC14 Four bitmaps, each 1 byte by 7 rows (a width, a height, the rows bottom first), drawn in turn by #R$CACB for both frames, the panel's (#R$CBF8) and the menu's (#R$F202).
B $CC14,36,9

@ $CC38 label=fill_edge_rows
c $CC38 Draw a row of the frame's two horizontal edges
D $CC38 Fills a row of $FF bytes at HL and the same at DE, then moves both up one pixel row (within a character row only: the edges never cross one).
R $CC38 IX The frame's description (+$10 the width in bytes)
R $CC38 HL The bottom edge's row
R $CC38 DE The top edge's row
  $CC38,19 Fill both rows; up one row.

@ $CC4B label=fuel
g $CC4B The fuel
D $CC4B A word, its high byte the gauge's level as a screen row: $42 full, $BE empty, so burning fuel makes it larger. Changed only through #R$CC4D: the burn at #R$B115 adds 8 or 16 a pass, #R$8FC4 takes away $1C00 (a refuel), #R$9015 adds $1000. Filled (high byte $42) at the start of each life by #R$DCA1; set to empty (high byte $BE) as the death sequence starts (#R$F440).
W $CC4B,2,2

@ $CC4D label=add_fuel
c $CC4D Change the fuel, keeping the level between full and empty
R $CC4D DE The amount to add to the fuel word (positive burns, negative fills)
  $CC4D,4 Add it.
  $CC51,7 No emptier than $BE.
  $CC58,6 No fuller than $42.
  $CC5E,4 Store it.

@ $CC62 label=fuel_shown
g $CC62 The fuel level shown
D $CC62 The row the gauge's fuel column reaches on the screen. #R$CC77 moves it one row a pass towards the fuel's level, so the gauge fills up at the start of a life from $BE (set by #R$DCA1) and drains one row at a time.
B $CC62,1,1

@ $CC63 label=check_fuel_empty
c $CC63 Start the death sequence when the gauge shows empty
D $CC63 Reached from #R$CC77 when the gauge is up to date. With the ship alive and the gauge showing empty ($BE), the death byte is set to 1 the next time the low seven bits of the pass counter are zero: up to 128 passes (about six seconds) of grace after the fuel runs out.
R $CC63 B The level shown
  $CC63,5 Already dying: nothing.
  $CC68,4 Not empty: nothing.
  $CC6C,6 Wait for the pass counter.
  $CC72,5 Death byte 1.

@ $CC77 label=update_fuel_gauge
c $CC77 Colour the fuel gauge, and move its fuel column a row towards the fuel level
D $CC77 Called each pass by the play loop (#R$F440) and twice a pass in the death sequence. The fuel inside the gauge is a column three to five pixels wide that runs from the bottom of the gauge up to the level shown. It is never redrawn: each step towards the fuel's level toggles (XOR) two rows: $03,$80 (three pixels in the middle, x $F6-$F8) at one row and $04,$40 (the two pixels either side, $F5 and $F9) at the row below. Two neighbouring steps overlap, so every row inside the column ends up with all five pixels and only the top row has the narrow three: a rounded top, kept up to date by touching two rows a pass.
D $CC77 Going up (filling), the toggled rows are the new level and the one below it; going down (burning), the old level and the one below, which takes the top row's three pixels away and leaves the next row's narrow three as the new top.
  $CC77,3 First the gauge's colour (#R$CAA7).
  $CC7A,10 Level shown against the fuel's level: the same, then see whether it is empty.
  $CC84,9 Filling (level going up the screen): the rows from the new level; burning: from the old level, and the new level is one row lower.
  $CC8D,4 The new level shown.
  $CC91,13 The first row: x $F0, the middle three pixels toggled.
  $CC9E,5 (Second byte of that row.)
  $CCA3,6 Not below the bottom of the tube.
  $CCA9,17 The row below: the two outer pixels toggled.

@ $CCBA label=scroll_down
g $CCBA This pass's vertical scroll
D $CCBA Signed, in pixels: the ship's step up this pass, worked out from its climb speed (#R$B234), positive climbing; 0 while dying. With #R$CCBB it is read as a word by #R$BFE3.
B $CCBA,1,1

@ $CCBB label=scroll_across
g $CCBB This pass's horizontal scroll
D $CCBB Signed, in pixels, a multiple of 2 (#R$C81F).
B $CCBB,1,1

@ $CCBC label=star_drawn
g $CCBC Something to do for this star
D $CCBC Bit 0 set by #R$C032 and #R$C10E when the star has an old image to erase or a new one to draw.
B $CCBC,1,1

@ $CCBD label=shift_table
g $CCBD This pass's shift table
D $CCBD Chosen by #R$D0BD from the fine scroll: one of the four tables from #R$E2BD (shifts 2, 4, 6, then 0) (sixteen entries of four bytes, one per piece direction: a blitter entry point and the address of the piece's graphic at that shift).
W $CCBD,2,2

@ $CCBF label=graphic_offsets
b $CCBF The landscape's graphic-offset table
D $CCBF Six bytes for each piece direction 0 to 8 (directions 7 to 13 use 0 to 6's rows, 14 and 15 rows 7 and 8: the code in #R$D319 that finds the row). The byte at the row plus twice the column's variety (0-2, from #R$CE24), plus one if the fine scroll is not 0 (#R$D0BD then starts the table one byte on), is the offset into the piece's graphic at which its POP blitter starts: so each column of a flat run can show one of three stretches of the ground's graphic.
B $CCBF,54,6

@ $CCF5 label=fold_column_step
c $CCF5 Move the column address on by the piece's column step, and stop the piece stepping
D $CCF5 Used by the clipping code at #R$D4B8 and #R$D4CB: the current column's screen address (its low byte, #R$CE49) takes the piece's column step at once, and the piece's x and column steps (#R$CE35, #R$CE36) become zero.
  $CCF5,19 Add the step; clear both steps.

@ $CD08 label=load_piece_steps
c $CD08 Set up a piece's steps from its direction
D $CD08 Called for each piece by #R$D0BD with the piece's direction in +3 of the piece state at IX (#R$DEDC). A tile turned upside down (#R$D0BD's $99) first remaps the direction through #R$CE14: 0-6 to 7-13 and back, which turns each piece over top to bottom. Then #R$E3D8 loads the direction's three steps from #R$E3BD: the x step in pixels (#R$CE35), the column step in screen bytes (#R$CE36) and the rise in rows (#R$CE37), each per step of the piece, and sets #R$E41B to $FF for a piece that steps right or 1 for one that steps left.
D $CD08 The directions, by their steps (x pixels, bytes, rows): 0 flat (24, 3, 0); 1 a gentle slope (16, 2, 8); 2 a steep one (8, 1, 8); 3 steeper (8, 1, 16); 4-6 the same three going left (-16, -2, 8; -8, -1, 8; -8, -1, 16); 7-13 the same seven upside down (the rise is still taken from 0-6, and #R$5C35 bit 7 marks them); 14 and 15 a wall, going right or left (0, +1 or -1, 16).
D $CD08 From those: #R$CE5A, the rows to work on per step (#R$CE37, or 4 for a flat piece); #R$5C24, the size of the column step; #R$CE59, the x step (0 for a wall); #R$5C25, the size of the x step, or 8 for a wall. A wall in an upside-down tile is also moved 8 pixels.
R $CD08 IX The piece state (#R$DEDC)
@ $CD13 nowarn
  $CD08,19 An upside-down tile: the direction through #R$CE14.
  $CD1B,3 The direction's steps.
  $CD1E,14 Rows per step: the rise, or 4 for a flat piece.
  $CD2C,12 The column step, and the x step kept in #R$CE59.
  $CD38,12 A wall (no x step): 8 pixels, with the sign of its direction.
  $CD44,20 #R$5C25 the size of the x step; going left, #R$5C24 the size of the column step.
  $CD58,19 A wall upside down: 8 pixels over.

@ $CD6B label=piece_ends
c $CD6B Read a flat piece's end pieces, and mirror a piece for a mirrored tile
D $CD6B Called for each piece by #R$D0BD after #R$CD08, with HL at the byte after the piece's direction-and-steps byte and C its number of steps. Only a flat piece (no rise) has two more bytes: the codes of the pieces at its left and right ends, kept in #R$5C33 and #R$5C34 ($16 means none, and codes from $10 have special handling in #R$D588). For a tile mirrored left-right ($FF) they are read the other way round with bit 1 changed (left for right); for one turned upside down ($99) bit 0 is changed as well (top for bottom), and the piece's y is moved (XOR $0C).
D $CD6B The address of the next piece is kept in #R$CE4D. Then, for a mirrored tile, the piece's x is reflected across the page (#R$CE43 becomes the complement of x plus its x step plus $0F), its direction is remapped through #R$CE04 (right for left), #R$E3D8 reloads the steps, and a flat run is moved back along by its length less one step (24 pixels a step), so it starts at its other end. A flat piece whose right end is $16 is not mirrored at all.
R $CD6B HL The next byte of the tile record
R $CD6B C The piece's number of steps
R $CD6B IX The piece state (#R$DEDC)
  $CD6B,6 A piece with a rise has no end bytes.
  $CD71,14 An upside-down tile moves a flat piece's y.
  $CD7F,6 A mirrored tile reads the ends the other way round.
  $CD85,20 Mirrored: the first byte, changed left for right, is the right end; the second (unless $16) the left end.
  $CD99,6 Mirrored, second byte $16: the right end is none.
  $CD9F,10 Not mirrored: left end, then right end.
  $CDA9,26 Upside down: both ends top for bottom, except $16.
  $CDC3,3 Where the next piece starts.
  $CDC6,11 Not mirrored, or mirrored with no right end: done.
  $CDD1,14 Reflect the x across the page.
@ $CDE5 nowarn
  $CDDF,18 Remap the direction through #R$CE04 and reload the steps.
  $CDF1,5 A slope: done.
  $CDF6,14 A flat run: back along by its length less one step.

@ $CE04 label=mirror_table
b $CE04 The left-right mirror table
D $CE04 For a tile mirrored left-right ($FF, #R$CD6B): a piece direction to the direction of the same piece left for right (1 and 4, 2 and 5, 3 and 6 swap, 8-10 and 11-13 swap, the walls 14 and 15 swap; 0 and 7 stay).
B $CE04,16,8

@ $CE14 label=upside_down_table
b $CE14 The upside-down table
D $CE14 For a tile turned upside down ($99, #R$CD08): a direction to the same piece upside down (0-6 and 7-13 swap; the walls swap too), so floors become ceilings.
B $CE14,16,8

@ $CE24 label=column_varieties
b $CE24 The column-variety sequence
D $CE24 Seventeen bytes, each 0, 1 or 2, walked one a column by the piece drawing (#R$D0BD leaves HL here for each piece): which of three stretches of a piece's graphic each column uses (#R$CCBF), so that a long flat run is not one pattern repeated.
B $CE24,17,17

@ $CE35 label=piece_dx
g $CE35 The piece's x step
D $CE35 In pixels per step, signed (#R$E3D8 from #R$E3BD; cleared by #R$CCF5). Also a scratch byte of the sprite code (#R$A303). Like the rest of the landscape's variables here, zero in the snapshot.
B $CE35,1,1

@ $CE36 label=piece_dcolumn
g $CE36 The piece's column step
D $CE36 In screen bytes per step, signed (#R$E3D8; cleared by #R$CCF5 and for walls by #R$CF38).
B $CE36,1,1

@ $CE37 label=piece_rise
g $CE37 The piece's rise
D $CE37 In rows per step, 0 for a flat piece (#R$E3D8). Also written by the sprite code (#R$A303).
B $CE37,1,1

@ $CE38 label=landscape_spare
b $CE38 Not used
D $CE38 Nothing refers to these two bytes (searched).
B $CE38,2,2

@ $CE3A label=box_x
g $CE3A An object's box: x; or a list pointer
D $CE3A The object's collision box made by #R$BE8F is here and in the next three bytes: x, bottom line (#R$CE3B), height (#R$CE3C) and width (#R$CE3D). As a word it is also a list pointer: #R$CACB walks the corner bitmaps with it.
B $CE3A,1,1

@ $CE3B label=box_bottom
g $CE3B An object's box: bottom line
D $CE3B See #R$CE3A.
B $CE3B,1,1

@ $CE3C label=box_height
g $CE3C An object's box: height; the piece's y as read
D $CE3C The box's height (#R$BE8F); and, while the landscape is drawn, the current piece's y as read from its tile record before any change (#R$D0BD), which #R$CF38 compares with $67.
B $CE3C,1,1

@ $CE3D label=box_width
g $CE3D An object's box: width
D $CE3D See #R$CE3A.
B $CE3D,1,1

@ $CE3E label=attribute_rows
g $CE3E Attribute rows to colour per step
D $CE3E Worked out by #R$CF38 for the piece being coloured.
B $CE3E,1,1

@ $CE3F label=vertical_step_size
g $CE3F The size of the vertical scroll
D $CE3F #R$CCBA without its sign (#R$DDF8), used to uncover rows behind pieces (#R$D9A8).
B $CE3F,1,1

@ $CE40 label=half_rows
g $CE40 Half the rows per step
D $CE40 #R$CE5A halved (the code in #R$D319), for the blitter.
B $CE40,1,1

@ $CE41 label=origin_x
g $CE41 The horizontal origin
D $CE41 Added to a page position to give the screen x; AND 7 is the fine scroll. With #R$CE45 it always sums to 8 (#R$DDF8). #R$D0BD moves it on by $E0 for the right-hand pages and puts it back.
B $CE41,1,1

@ $CE42 label=origin_y
g $CE42 The vertical origin
D $CE42 Added to a page position to give the screen y. With #R$CE46 it sums to $B7: the scroll moves one up as the other comes down, and the wraps set both afresh. The exception is a new game's start, whose pair from #R$F3B7 sums to $F7 until the fly-in's first vertical wrap. #R$D0BD moves it on by $A0 for the lower pages and back.
B $CE42,1,1

@ $CE43 label=piece_page_x
g $CE43 The piece's x
D $CE43 The current piece's x in its page (#R$D0BD), moved as it is drawn; also the start of a word used by #R$BE8F.
B $CE43,1,1

@ $CE44 label=piece_page_y
g $CE44 The piece's y
D $CE44 The current piece's y in its page (#R$D0BD), moved as it is drawn.
B $CE44,1,1

@ $CE45 label=view_x
g $CE45 The view's x in its page
D $CE45 Moved by the horizontal scroll and wrapped into the next page by #R$DDF8; saved with the restart point (#R$C33C).
B $CE45,1,1

@ $CE46 label=view_y
g $CE46 The view's y in its page
D $CE46 Moved by the vertical scroll (#R$DDF8).
B $CE46,1,1

@ $CE47 label=piece_graphic
g $CE47 The piece's graphic
D $CE47 Its address at this pass's shift, from #R$CCBD's table (the code in #R$D319).
W $CE47,2,2

@ $CE49 label=column_address
g $CE49 The column being drawn
D $CE49 The screen address of the piece's current column (#R$D319, #R$CCF5).
W $CE49,2,2

@ $CE4B label=offsets_start
g $CE4B Where to start in the graphic-offset table
D $CE4B #R$CCBF, or one byte on when the scroll is shifted (#R$D0BD).
W $CE4B,2,2

@ $CE4D label=next_piece
g $CE4D The next piece
D $CE4D Its address in the tile record (#R$CD6B), picked up by #R$D0BD's loop.
W $CE4D,2,2

@ $CE4F label=first_step_address
g $CE4F The piece's first step
D $CE4F Its screen address, kept by #R$D937.
W $CE4F,2,2

@ $CE51 label=piece_offsets
g $CE51 The piece's row of graphic offsets
D $CE51 In #R$CCBF (the code in #R$D319).
W $CE51,2,2

@ $CE53 label=first_step_y
g $CE53 The piece's first step: y
D $CE53 Kept by #R$D937; read by #R$D711.
B $CE53,1,1

@ $CE54 label=clipped_columns
g $CE54 Columns at the view's edges
D $CE54 Counted for each piece by #R$CE5B and #R$D711; cleared by #R$D0BD.
B $CE54,1,1

@ $CE55 label=first_step_x
g $CE55 The first drawn step's place: x
D $CE55 Kept by #R$D937 with #R$CE56; the two are read as a word by #R$D9A8.
B $CE55,1,1

@ $CE56 label=first_step_y_drawn
g $CE56 The first drawn step's place: y
D $CE56 See #R$CE55.
B $CE56,1,1

@ $CE57 label=view_column
g $CE57 The view's page: column
D $CE57 0-$5F, wrapping (#R$DDF8, #R$DF08); with #R$CE58 it is the word the restart point saves (#R$C33C).
B $CE57,1,1

@ $CE58 label=view_row
g $CE58 The view's page: row
D $CE58 0-$1B: rows 0-3 are open sky (stars, #R$BFE3; no landscape below row 3), $0B is the surface's lowest, $0C on are the caverns.
B $CE58,1,1

@ $CE59 label=piece_dx_copy
g $CE59 The piece's x step again
D $CE59 #R$CE35 kept by #R$CD08: 0 for a wall.
B $CE59,1,1

@ $CE5A label=piece_rows
g $CE5A Rows per step
D $CE5A #R$CE37, or 4 for a flat piece (#R$CD08); reused by #R$CF38 and #R$D711.
B $CE5A,1,1

@ $CE5B label=column_clipped
c $CE5B A column of a piece is cut off at the top or bottom of the view
D $CE5B Jumped to from the column loop (#R$D319) when a column lies across the view's top or bottom edge (#R$5C31, the edge flags, bit 0 or 1, or any of bits 0-3 with others). In the upper tiles, a slope ends after this column (C=1). The column is counted in #R$CE54, and the first one so counted calls the code in #R$D937 that keeps the first step's place; then on to the next column.
  $CE5B,15 Upper tile and a slope: stop after this column.
  $CE6A,12 Count it; the first one keeps the step's place (#R$D937).
  $CE76,3 Next column.

@ $CE79 label=column_at_view_bottom
c $CE79 A lower tile's column reaches the view's bottom edge
D $CE79 From #R$D319 when, in one of the two lower tiles, the column's top is level with the view's edge (#R$CE46). Bit 7 of the edge flags #R$5C31 is set; unless the vertical step #R$CCBA is negative, bit 0 is set instead and copied to #R$5C32. On to the horizontal tests.
  $CE79,16 Flag it; a negative step: no more.
  $CE89,14 Otherwise bit 0, kept in #R$5C32 too.

@ $CE97 label=column_at_view_top
c $CE97 An upper tile's column reaches the view's top edge
D $CE97 From #R$D319 when, in one of the two upper tiles, the column's y is the view's y (#R$CE46). As #R$CE79 but bit 1, when the vertical step #R$CCBA is negative.
  $CE97,16 Flag it; a positive step: no more.
  $CEA7,14 Otherwise bit 1, kept in #R$5C32 too.

@ $CEB5 label=column_at_view_left
c $CEB5 A column reaches the view's left edge
D $CEB5 From the horizontal test in #R$D319 when, in one of the left-hand tiles, the column's x is the view's left edge (#R$CE45). Moving left (#R$CCBB negative): bit 3 of the edge flags; otherwise the column is not drawn.
  $CEB5,8 Not moving left: next column.
  $CEBD,11 Flag it and go on.

@ $CEC8 label=column_at_view_right
c $CEC8 A column reaches the view's right edge
D $CEC8 As #R$CEB5 for the right-hand tiles: moving right (#R$CCBB positive or zero), bit 2 of the edge flags; otherwise the column is not drawn.
  $CEC8,8 Moving left: next column.
  $CED0,11 Flag it and go on.

@ $CEDB label=edge_column
c $CEDB A column on the view's left or right edge
D $CEDB From #R$D319 when the edge flags hold just bit 2 or 3. For a slope going the way that matters for its tile (right in the upper tiles, left in the lower), the piece is cut to at most two more steps (C). The first such column of the piece takes its screen position (#R$D937) and clears +1 of the piece state; every one is counted in #R$5C2F and #R$CE54 by #R$D711 and is not drawn here.
  $CEDB,29 A slope going the right way: no more than two more steps.
  $CF01,7 Not the first: count it.
  $CF08,12 The first: its screen position; then count it.

@ $CF14 label=in_play_area
c $CF14 Is the next attribute cell inside the play area?
D $CF14 Tests the attribute address one on from HL: inside rows 3 to 22 of the screen it returns NZ (A=$FF); in the panel's rows 0-2 or the bottom row 23, Z. HL is left as it was.
R $CF14 HL An attribute address
  $CF14,13 In the top third: rows 3 and below are inside.
  $CF21,4 Inside.
  $CF25,3 Outside.
  $CF28,14 The middle third is inside; in the bottom third, row 23 is outside.

@ $CF36 label=jump_iy
c $CF36 Jump to IY
D $CF36 Lets #R$CF38 CALL the colouring routine whose address it put in IY.
  $CF36,2 Off to it.

@ $CF38 label=colour_piece
c $CF38 Colour the attribute cells under a landscape piece
D $CF38 Called by #R$D711 after a piece is drawn. The landscape takes its colour from its attribute cells, a colour for the upper tiles (#R$5C3A) and another for the lower ones (#R$5C3B), both set from the level's pair of colours (#R$DCA1) by #R$DEE1 (the deeper colour from map row $0C down: the caverns). Where the surface meets the caverns (map row $0B in a lower tile, or $0C in an upper one) the deeper colour is used, or the upper one for a piece starting above y $67.
D $CF38 For each step of the piece it colours a column of cells (the rows per step, #R$CE3E) one, two or three cells wide (the column step plus one: #R$D04F, #R$D063, #R$D082), then moves up by the rise and across by the column step; a flat piece colours three cells wide and as deep as its graphic (about two cells). Only cells inside the play area (#R$CF14) and its columns 1-28 are coloured. A piece ending in the special end piece $13 on the right gets one more column when the scroll is not on a byte boundary.
D $CF38 Nothing is coloured while the landscape is being built after a restart (#R$5C3C), nor for a piece with no columns drawn.
R $CF38 IX The piece state (#R$DEDC): +0 +1 the screen x and y of its first column, +2 the number of steps drawn, +3 the direction
  $CF38,15 Building after a restart, or nothing drawn: no colour.
  $CF47,13 A wall: no column step, and one byte (two cells) wide.
  $CF54,5 The width in cells.
  $CF59,17 A piece going left starts a cell further left.
@ $CF6B nowarn
@ $CF73 nowarn
@ $CF7B nowarn
  $CF6A,21 The colouring routine for the width.
  $CF7F,18 The rise in cells per step; the screen position.
  $CF91,20 Rows to colour: the rise in cells, one more if the first row does not end on a cell boundary.
  $CFA5,10 A flat piece (direction 0 or 7):
@ $CFAF nowarn
  $CFAF,25 three cells wide, no rise, and the cells from its y down to $0B rows below.
  $CFC8,17 The attribute address (an x of $F0 or more, off the right, wraps to the start of the row).
  $CFD9,15 The upper or lower colour.
  $CFE8,42 Where the surface meets the caverns, the deeper colour, or the upper one above y $67.
  $D012,6 Each step of the piece:
  $D018,10 a column of cells,
  $D022,12 up by the rise,
  $D02E,15 and across by the column step (signed).
  $D03D,18 The end piece $13 on the right, scrolled off a byte boundary: one more column.
@ $D04F label=colour_one_cell
c $D04F Colour a column of attribute cells one wide
D $D04F #R$CF38 runs on into it for the extra column after an end piece $13, and enters it through IY for the narrowest pieces. Each row upwards: the cell at HL, if it is inside the play area (#R$CF14) and its columns 1-28.
R $D04F B The number of rows
R $D04F C The attribute
R $D04F DE $0020
R $D04F HL The attribute address of the bottom row
  $D04F,20 One cell a row, upwards.

@ $D063 label=colour_two_cells
c $D063 Colour a column of attribute cells two wide
D $D063 Entered through IY from #R$CF38 for pieces with a column step of one byte (and for walls). Each row upwards: the two cells at HL, wherever they are inside the play area and its columns 1-28.
R $D063 B The number of rows
R $D063 C The attribute
R $D063 DE $0020
R $D063 HL The attribute address of the bottom row
  $D063,14 The first cell.
  $D071,11 The second.
  $D07C,6 Up a row.

@ $D082 label=colour_three_cells
c $D082 Colour a column of attribute cells three wide
D $D082 As #R$D063 for three cells: pieces with a column step of two bytes or more, and flat pieces.
R $D082 B The number of rows
R $D082 C The attribute
R $D082 DE $0020
R $D082 HL The attribute address of the bottom row
  $D082,14 The first cell.
  $D090,10 The second.
  $D09A,12 The third.
  $D0A6,6 Up a row.

@ $D0AC label=piece_classes
b $D0AC Landscape pieces' collision classes
D $D0AC Sixteen bytes, one per piece direction, put in +4 of each piece's collision box (#R$D0BD) for the collision code (#R$BA21): 4 flat; 1, 2, 3 the three slopes rising to the right; $41-$43 the same rising to the left (bit 6); 8 flat upside down; $81-$83 and $C1-$C3 the slopes upside down (bit 7); $10 and $20 the two walls.
B $D0AC,16,8

@ $D0BC label=trail_collision
g $D0BC Redraw the trail
D $D0BC Set by the collision code (#R$8E2D, #R$A8F4, #R$BC13); makes #R$C4ED erase and redraw the ship's trail even if its frame has not changed; cleared there.
B $D0BC,1,1

@ $D0BD label=draw_landscape
c $D0BD Draw the landscape
D $D0BD Called each pass by #R$DDF8, when the view is below the sky (map row 3 or more). The screen shows at most four map tiles, each the size of the play area: the view's page, the one below, the one to the right and the one below that. #R$DF08 has listed their tile records' addresses after #R$DC87, which points into the list, and their collision-box lists (37 bytes each) are at #R$5B80, #R$5BA5, #R$5BCA and #R$5BEF; #R$5C1D says which of the four is being drawn (0 the view's page, 1 below, 2 right, 3 below right). Nothing is scrolled: every piece that can be seen is drawn again, straight onto the screen, from a copy of its graphic pre-shifted for this pass's fine scroll.
D $D0BD First the shift table: the fine scroll (#R$CE41 AND 7) picks one of four tables (at 0, 2, 4 or 6 pixels; #R$CCBD), and the graphic-offset table's start (#R$CCBF, or one byte on when shifted). Then, for each tile: the page-to-screen offsets #R$CE41 and #R$CE42 are moved on to that tile ($E0 to the right, $A0 down, as 8-bit sums) and put back at the end (in #R$D711).
D $D0BD A tile record (the tables from #R$6D92): first byte 0, an empty tile. Otherwise, optionally $99 (the tile is turned upside down: floors become ceilings), optionally $FF (mirrored left-right), optionally a byte of $95 or more (skipped: padding, so a mirrored or upside-down tile can point a few bytes before a plain record and share it), then the number of pieces. Each piece: x and y in the page (pixels; y counts down from the top of the page, and the piece's line rises from there), then a byte whose high nibble is its direction (#R$CD08) and whose low nibble its number of steps (0 meaning 16), and, only for a flat direction (0 or 7), the codes of its two end pieces (#R$CD6B). So a tile's ground is a chain of pieces, each a line of steps of one shape: a flat run of 24-pixel steps, a slope up or down, a wall.
D $D0BD Each collision-box list: +0 the number of pieces, then up to seven 5-byte boxes, one per piece: +0 +1 x and y, +2 +3 for a flat piece its width (24 a step) and $14, for a wall $18 and its height (16 a step), for a slope its far end's x and y; +4 its class (#R$D0AC). These are refilled only while #R$5C3D is set: when the view has moved into a new page this pass (#R$DDF8) or the screen is being built after a restart (#R$5C3C); otherwise only the piece count is rewritten.
D $D0BD Each piece is then tested against the view: a piece wholly outside it across (#R$CE45, #R$D292 for the left-hand tiles, #R$D2C0 for the right) or up and down (#R$CE46, #R$D2DA for the upper tiles, #R$D2E1 for the lower) is not drawn. One that may be seen is drawn by the column loop at #R$D319, its attributes coloured by #R$CF38, and the next piece taken from #R$CE4D. The renderer uses SP for its POP blitter and reloads it from the fixed address #R$5B7A between pieces.
  $D0BD,9 Building after a restart: refill the collision records too.
  $D0C6,8 The vertical offset for the first tile.
@ $D0CE nowarn
  $D0CE,7 Start of the graphic-offset table for an unshifted scroll.
@ $D0E7 nowarn
  $D0D5,38 The fine scroll picks the shift table (and the shifted half of the offsets) for 0, 2, 4 or 6 pixels.
  $D0FB,4 The first tile.
@ $D0FF nowarn
@ $D109 nowarn
@ $D111 nowarn
@ $D119 nowarn
  $D0FF,30 Each tile: its box list.
  $D11D,11 The next tile record's address from the list.
  $D128,10 Not mirrored, not upside down, no pieces yet.
  $D132,5 An empty tile: on to the next.
  $D137,8 $99: upside down.
  $D13F,9 $FF: mirrored left-right.
  $D148,7 A byte from $95 up is skipped.
  $D14F,13 The number of pieces, to #R$5C20 and the box list; its first box kept at #R$BA09.
@ $D15C nowarn
  $D15C,35 Each piece: its state at #R$DEDC, and the per-piece flags cleared.
  $D17F,13 Its x and y in the page (the y kept unchanged in #R$CE3C too).
  $D18C,15 Its direction (high nibble) and its steps (#R$CD08).
  $D19B,11 The number of steps; 0 means 16.
  $D1A6,4 The end pieces, and a mirrored tile's changes (#R$CD6B).
@ $D1AA nowarn
  $D1AA,6 The column-variety sequence in HL; the direction kept in B.
  $D1B0,12 The box, filled only while building (#R$5C3D).
@ $D1C2 nowarn
  $D1BC,32 Its class, steps, x and y.
  $D1DC,6 A flat piece:
  $D1E2,23 width 24 pixels a step, height $14,
  $D1F9,11 and its y $10 lower unless it is upside down.
  $D204,6 A wall:
  $D20A,35 width $18, height 16 a step, and the left-going wall $10 to the left.
  $D22D,16 A slope going left starts one x step further right.
  $D23D,29 Its far end: the x and y after all its steps.
  $D25A,22 Wholly to the left or right of the view?
  $D270,22 Wholly above or below it?
  $D286,6 It can be seen: on to the next collision record, and draw it.
  $D28C,6 It cannot: on to the next collision record and the next piece.

@ $D292 label=piece_off_left_edge
c $D292 Test whether a piece in a left-hand map cell ends before the play area's left edge
D $D292 Used by #R$D0BD for each piece of the two left-hand map cells of the 2x2 window (bit 1 of the cell counter #R$5C1D clear). It finds the piece's rightmost x within the cell from the piece's collision box and compares it with #R$CE45, the in-cell x that sits at the play area's left edge. A piece that ends left of it cannot be seen and is skipped without walking its steps.
D $D292 The box (IX) is five bytes of a map cell's collision-box list (#R$5B80, #R$5BA5, #R$5BCA or #R$5BEF: the view's page, the one below, right, below-right). It holds the piece's start x at +0 and, for a flat piece, its length in pixels at +2; for a sloped piece +2 holds the x of its far end, and +0 its start x (moved on by a step's width for a piece running left, #R$E41B = 1). +4 is a class byte from #R$D0AC for the collision code (#R$BA21).
R $D292 IX Piece's collision box
R $D292 B In-cell x at the play area's left edge (#R$CE45)
R $D292 O:F Z clear (NZ) if the piece is wholly left of the edge
  $D292,14 Flat piece (no rise, #R$CE37 zero): right end = start x + length.
  $D2A0,13 A vertical wall (no run, #R$CE59 zero) is 8 pixels wide.
  $D2AD,15 A sloped piece: its right end is +0 if it runs left (#R$E41B = 1), else +2.
  $D2BC,4 NZ (skip) if the right end is left of the edge; Z otherwise.
@ $D2C0 label=piece_off_right_edge
c $D2C0 Test whether a piece in a right-hand map cell starts beyond the play area's right edge
D $D2C0 The counterpart of #R$D292 for the two right-hand map cells of the window. In the right-hand cell the play area's right edge falls at the same in-cell x as the left edge does in the left-hand one (#R$CE45), so a piece whose leftmost x is beyond it is out of sight.
R $D2C0 IX Piece's collision box
R $D2C0 B In-cell x of the play area's right edge (#R$CE45)
R $D2C0 O:F Z clear (NZ) if the piece is wholly right of the edge
  $D2C0,19 A sloped piece running left: its leftmost x is its far end, +2, less one.
  $D2D3,3 Otherwise the piece's start x.
  $D2D6,4 NZ if beyond the edge. (A piece starting exactly on the edge gives Z and is walked anyway.)
@ $D2DA label=piece_off_top_edge
c $D2DA Test whether a piece in an upper map cell lies wholly above the play area
D $D2DA Pieces are walked upwards from their start, so in the upper map cells of the window a piece whose start (lowest) y is above the in-cell y of the play area's top edge cannot be seen.
R $D2DA B In-cell y of the play area's bottom edge in the lower cell, which is also the top edge's in-cell y in the upper one (#R$CE46)
R $D2DA O:F Z clear (NZ) if the piece is wholly above the play area
@ $D2E1 label=piece_off_bottom_edge
c $D2E1 Test whether a piece in a lower map cell lies wholly below the play area
D $D2E1 The counterpart of #R$D2DA for the lower map cells: the piece's topmost y is compared with #R$CE46, the in-cell y of the play area's bottom row. A flat piece's top is its start y less 4 (a flat step is four rows tall); a vertical wall's is +1 less +3 of its collision box; a slope's is +3.
R $D2E1 IX Piece's collision box
R $D2E1 B In-cell y of the play area's bottom edge (#R$CE46)
R $D2E1 O:F Z clear (NZ) if the piece is wholly below the play area
  $D2E1,13 Flat piece.
  $D2EE,14 Vertical wall.
  $D2FC,3 Slope.
  $D2FF,4 NZ if below the bottom edge.
@ $D303 label=next_piece_box
c $D303 Move to the next piece's collision box and back to the current-piece record
D $D303 Called by #R$D0BD once a piece's visibility has been decided. Moves the pointer #R$BA09 on by the five bytes of a box, points IX back at the current-piece record #R$DEDC, clears its "first step set up" byte (+1) and stores the piece's direction at +3.
R $D303 IX Box just used
R $D303 B' Direction (in the other register set)
  $D303,9 Advance the box pointer.
  $D30C,13 IX = current-piece record; switch register sets; clear +1; keep the direction at +3.
@ $D319 label=landscape_step_loop
c $D319 Move to the next step of a piece, cull it, and set up its graphic and blitter
D $D319 The per-step loop of the landscape renderer. A piece is a straight run of identical steps; each step moves the drawing position on by its direction's advance (#R$CE35 pixels across, #R$CE36 bytes across, #R$CE37 pixels up, from the table at #R$E3BD by #R$E3D8). Directions 0-6 are floors -- flat, three slopes rising to the right, three rising to the left -- and 7-13 the same shapes as ceilings (rock above, sky below; #R$E3D8 sets #R$5C35 to $80 for them); 14 and 15 are vertical walls. For each step this routine:
D $D319 1. Advances the in-cell position (#R$CE43, #R$CE44) and the screen position (#R$5C2C, #R$5C2D). A piece's first step is entered further down, without moving.
. 2. Culls it against the play area. Vertically: in an upper map cell a step whose base is above the top edge is skipped; in a lower one, a step whose top is below the bottom edge; a step exactly on the edge sets a flag in #R$5C31 (#R$CE97, #R$CE79). Horizontally the same against #R$CE45, with flags set by #R$CEB5 and #R$CEC8. Skipped steps go to the step counter in #R$D711 without drawing.
. 3. With an edge flag set, goes to #R$CEDB or #R$CE5B (the edge-exact cases).
. 4. Otherwise reads the step's variant (0-2, from the repeating sequence at #R$CE24) and, for the piece's first drawn step, looks its direction up in the fine-scroll table at #R$CCBD (16 entries of four bytes: a blitter address into IY, a graphic address into #R$CE47), works out the screen address (#R$D937) and finds this direction's row of variant offsets (#R$CE51).
. 5. Chooses how to draw: a flat step goes to #R$D588; a sloped step near the right edge (screen x from $D1) through the patched JR at the end of this routine to #R$D464; others to #R$D4CB, which clips at the left edge or draws whole. All of them end at #R$D672, which draws the step.
D $D319 Interrupts are off for the whole game, which is what makes it safe for the blitters to borrow SP.
R $D319 HL' Address of this step's variant byte (in #R$CE24)
R $D319 C' Steps left in the piece
R $D319 D' Steps drawn so far
  $D319,36 Move to this step: up by the direction's rise, across by its run.
  $D33D,4 A piece's first step enters here (from #R$D0BD): no edge flags yet.
  $D341,24 Upper map cell: skip if the step's base is above the top edge; exactly on it, flag it (#R$CE97).
  $D359,19 Lower map cell: skip if the step's top is below the bottom edge; exactly on it, flag it (#R$CE79).
  $D36C,11 Horizontal cull; the right-hand map cells are tested further on.
  $D377,30 A flat step of a left-hand cell whose screen x falls in $F1-$F6 (hanging off the left edge into the border) is drawn only if it is the piece's last, and then the flag #R$D85D is set to $FF. Exactly $F0 is an edge case (#R$CEB5).
  $D395,17 Skip the step if it ends left of the left edge; exactly on it, #R$CEB5.
  $D3A6,10 Right-hand map cell: skip the step if it starts right of the right edge; exactly on it, #R$CEC8.
  $D3B0,34 An edge flag set: off to the edge-case handlers.
  $D3D2,1 E = this step's variant (0, 1 or 2).
  $D3D3,7 Steps after the piece's first drawn one carry on from where the last blitter left HL.
  $D3DA,28 First drawn step: from the fine-scroll table (#R$CCBD + 4 * direction) the blitter address into IY and the graphic address into #R$CE47.
  $D3F6,8 Row pairs to draw = the step's height (#R$CE5A) / 2.
  $D3FE,13 Screen address of the step (#R$D937), less the byte advance, into #R$CE49.
  $D40B,24 #R$CE51 = this direction's row of variant offsets: #R$CE4B (#R$CCBF on a byte boundary, one byte on off it) + 6 * (direction mod 7).
  $D423,18 D' = 0 steps drawn; the displacement of the JR at the end of #R$D464 = 1 if the step is on a byte boundary, else 0 (#R$D4A7 copies it too).
  $D435,22 A vertical wall: once a step is drawn the rest go straight to the draw; before that #R$CE35 = -8 * direction.
  $D44B,11 Default dispatch (the dispatch JR in #R$D672): the step's own blitter. Flat steps: #R$D588.
  $D456,8 A sloped step: near the right edge (screen x $D1 or more)?
  $D45E,4 B = screen x, A = run in pixels.
  $D462,2 Patched by #R$E3D8: displacement 0 for a piece running left, into #R$D464 to negate the run first; 2 for one running right, past the NEG.
@ $D464 label=slope_step_at_right_edge
c $D464 Decide how a sloped step near the right edge is clipped
D $D464 Entered from the patched JR at the end of #R$D319 with A = the step's run in pixels (negated here for a piece running left) and B its screen x. If the step's far side stays left of $E9 it goes on to #R$D4CB. Otherwise it crosses the play area's right edge and one of the right-clipping blitters is chosen: for a step starting left of $E0 only its rightmost column is lost (#R$D494); for one starting at $E0 or later only its first column or two are drawn, the count patched into the blitter's JR (#R$DB89 by #R$D481, or #R$DC47 by #R$D4A7).
R $D464 A Run of the step in pixels
R $D464 B Screen x of the step
  $D464,8 Far side left of $E9: no right clipping.
  $D46C,5 Starts left of $E0: #R$D494.
  $D471,7 A piece running left uses the mirrored blitter (#R$D4A7).
  $D478,7 Displacement for the JR in #R$DB89: $21 less the byte advance.
  $D47F,2 Patched by #R$D319 (displacement 1 on a byte boundary): into #R$D481 (one less) or past its DEC A.
@ $D481 label=set_right_clip_columns
c $D481 Patch the right-clipping blitter's column count
D $D481 The target of the patched JR at the end of #R$D464, entered at its DEC A when the step is off a byte boundary and just after it when it is on one. Stores A as the displacement of the JR after the first write in #R$DB89, selects that blitter through the dispatch JR in #R$D672, and draws.
R $D481 A Displacement, plus one unless the DEC A is skipped
  $D481,1 Off a byte boundary: one less.
  $D482,3 Patch the JR in #R$DB89.
  $D485,5 Dispatch 2: #R$DB89 (through #R$D703).
  $D48A,7 A vertical wall moves its address once and stops stepping across (#R$CCF5).
  $D491,3 Draw.
@ $D494 label=slope_lose_last_column
c $D494 Clip a sloped step that loses only its rightmost column at the right edge
D $D494 For a step starting left of $E0 that crosses the right edge. A piece running right uses #R$DB89 with its patched JR at displacement 0 (all but the last column); one running left goes to #R$D4B8.
  $D494,7 Running left: the mirrored blitter.
  $D49B,12 Displacement 0 into the JR in #R$DB89; dispatch 2; draw.
@ $D4A7 label=mirrored_slope_far_right
c $D4A7 Work out the column count for a mirrored step far into the right edge
D $D4A7 A step of a piece running left that starts at screen x $E0 or more. The displacement for the patched JR in #R$DC47 is $29 less the byte advance's size, one less again unless the step is on a byte boundary: the JR at the end of this routine (whose displacement is copied here from the byte-boundary flag #R$D319 left in the JR at the end of #R$D464) skips the DEC A at #R$D4B8 or not.
  $D4A7,6 Copy the byte-boundary flag into the JR's displacement.
  $D4AD,9 A = $29 - size of the byte advance (negative for these directions).
  $D4B6,2 Patched: into #R$D4B8 (DEC A) or past it.
@ $D4B8 label=use_mirrored_right_clip
c $D4B8 Select the mirrored right-clipping blitter
D $D4B8 Entered at its DEC A or just after it by the patched JR at the end of #R$D4A7, and from #R$D494 with A = 1 (displacement 0: all but the last column). Stores the displacement of the patched JR in #R$DC47 and selects that blitter with dispatch displacement 5.
R $D4B8 A Column-count displacement, plus one
  $D4B8,4 Patch the JR in #R$DC47.
  $D4BC,5 Dispatch 5: #R$DC47 (through #R$D703).
  $D4C1,10 A vertical wall moves its address once and stops stepping across (#R$CCF5); draw.
@ $D4CB label=slope_step_at_left_edge
c $D4CB Draw a sloped step whole, or decide how it is clipped at the left edge
D $D4CB Steps whose screen x is from -8 to 6 hang over the play area's left edge (column 0 is the border, and x from $F0 is "negative": columns 30 and 31 of the same character row). Anything else is drawn whole (with #R$CCF5 for a vertical wall). A clipped step uses #R$DBB7 (dispatch 8) for a piece running right, or #R$DBFD (dispatch 11) for one running left; the bytes to skip and the columns to draw are patched into those blitters' JRs, and for #R$DBB7 the next step's column into #R$5C2E, according to the column the step starts in.
D $D4CB All the clipped cases ran in the build's sessions.
  $D4CB,22 Not near the left edge: draw whole.
  $D4E1,7 A piece running left: further on.
  $D4E8,13 Running right: by the column in #R$CE49 ($1D, $1E or another).
  $D4F5,31 Another column: skip one graphic byte (first JR in #R$DBB7 at 1), draw the last column of a two-byte step (second JR at $2C), the next step's column from the byte advance (#R$5C2E); dispatch 8.
  $D514,17 $1D: skip two graphic bytes (first JR at 0), draw the last column of a three-byte step (second JR at $30); the next step's column from 1.
  $D525,20 $1E off a byte boundary: skip one byte, draw the last two columns (second JR at 0).
  $D539,14 A piece running left: by the column the step starts in.
  $D547,27 Another column off a byte boundary: skip one byte, two columns (first JR in #R$DBFD at 1, second at 0); dispatch 11.
  $D562,17 Column 2, or on a byte boundary: skip one byte, one column (second JR at $26).
  $D573,21 Column 3: skip two bytes, one column (first JR at 0, second at $2A); with no step drawn yet, #R$CE49 goes a character row back.
@ $D588 label=flat_step_clip
c $D588 Patch the flat-step blitter for the play area's edges and the piece's end caps
D $D588 Flat steps (directions 0 and 7) are three bytes wide and four rows tall, all drawn by #R$E24D, which has three patchable JRs in its loop and two on its cut path (#R$E28E, #R$E2A6). This routine resets the loop's three to draw all three columns, then patches them by the column the step starts in (the low five bits of #R$CE49 are three less than that column):
D $D588 #LIST { $1D (start in column 0, the left border): the first JR to #R$E28E, which skips the first byte and draws columns 1 and 2 (#R$E2AB). } { $1C (start in column 31, one column left of the screen): the same, drawing only the third byte, in column 1 (#R$E2B6). } { $18 (columns 27-29): the third JR to #R$E289, two columns. } { $19 (columns 28-30): the second JR to #R$E283, one column. } LIST#
D $D588 Then the piece's end caps. A flat piece carries two cap bytes (#R$5C33 for its first step, #R$5C34 for its last, read by #R$CD6B); bit 4 marks a cap to act on, and bit 7 is set here when it is acted on (#R$8347 looks for $91 and $93). A cap's low two bits pick one of four extra graphics stored after the three variants (offset $24 + 12 * n), drawn in place of the variant. Cap $16 ($96 once seen) draws just the first column, and skips the step if that column is outside. An odd cap marks a drop at that end of the run: if the step is on a byte boundary and the horizontal scroll is moving towards that end, its address and x are kept (#R$CE4F, #R$5C27, #R$5C1C) for the column fill after the piece (#R$D8DA).
D $D588 The first step of a piece whose start cap is exactly $10 loses its first column (the first JR to #R$E249) when the ground is off a byte boundary.
R $D588 C' Steps left (equal to #R$5C22 on the piece's first step, 1 on its last)
  $D588,10 All three loop JRs to displacement 0: draw every column.
  $D592,21 The step's start column.
  $D5A7,7 A last step hanging into the border (#R$D85D set) is not drawn.
  $D5AE,24 First step, start cap $10, off a byte boundary: lose the first column.
  $D5C6,15 Start column 0: from the second byte on.
  $D5D5,16 Start column 31: only the third byte.
  $D5E5,7 Start column 27: two columns.
  $D5EC,5 Start column 28: one column.
  $D5F1,20 First step with a start cap to act on: mark it.
  $D605,49 An odd cap (a drop) facing the scroll's direction, on a byte boundary: keep the step's address and screen x for #R$D8DA.
  $D636,24 Cap $16: one column only, or nothing if that column is outside.
  $D64E,16 Graphic offset of the cap: $24 + 12 * (cap AND 3), and on to the draw.
  $D65E,20 Last step with an end cap to act on: mark it and treat it the same way.
@ $D672 label=draw_step
c $D672 Draw a landscape step
D $D672 The draw shared by every direction, reached from #R$D319, #R$D481, #R$D494, #R$D4B8, #R$D4CB and #R$D588 (which jumps into it past the first lines with DE already holding a cap's graphic offset). It turns the variant into a graphic address and loads SP with it. If the step hangs below the play area (#R$5C2D from $B8) it pops the rows below the edge away and starts at the bottom row; if it reaches above the top it shortens the row count (and, for a slope, cuts the piece short, since pieces only climb). Then the JR at the end, whose displacement was set to 0, 2, 5, 8 or 11 (0 by #R$D319, the others by the clipping set-ups), lands on one of the five jumps at #R$D703: the step's own blitter (IY) or one of the four edge-clipping blitters.
D $D672 Every blitter is entered with A = row pairs to draw, HL = the screen address less the step's byte advance, SP = the first graphic byte, and ends by jumping to #R$D711 with HL where the next step will start.
R $D672 E Variant (0-2)
R $D672 HL' Screen address of the step, less the byte advance (#R$CE49)
  $D672,12 Normal graphic: the offset from this direction's variant row (#R$CE51 + 2 * variant).
  $D67E,5 SP = the step's graphic. (A cap's offset joins here.)
  $D683,12 E = row pairs. Does the step hang below the play area (#R$5C2D from $B8)?
  $D68F,33 It does: lose half the overhang in row pairs, and pop those rows of the graphic away (D POPs a row pair: the byte advance, plus one for a sloped step off a byte boundary).
  $D6B0,22 Start at the play area's bottom row (pixel row $B7) in the step's column.
  $D6C6,21 For the mirrored left-clipping blitter a column past 28 belongs to the character row above.
  $D6DB,12 Not below: does the step reach above the top row ($18)?
  $D6E7,22 It does: shorten it; a slope's piece is cut to at most one more step (C' = 2 unless already 1).
  $D6FD,3 HL = the screen address kept for this step.
  $D700,1 A = row pairs to draw.
  $D701,2 Patched dispatch: displacement 0, 2, 5, 8 or 11 lands on one of the five jumps that follow.
@ $D703 label=step_dispatch
c $D703 The five jumps of the step dispatch
D $D703 Reached through the patched JR at the end of #R$D672: displacement 0 lands on the first, 2 on the second, and so on.
  $D703,2 0: the step's own blitter, from the fine-scroll table.
  $D705,3 2: #R$DB89, right edge, piece running right.
  $D708,3 5: #R$DC47, right edge, piece running left.
  $D70B,3 8: #R$DBB7, left edge, piece running right.
  $D70E,3 11: #R$DBFD, left edge, piece running left.
@ $D711 label=after_step_drawn
c $D711 Finish a step; at a piece's end repair behind it and colour it; then the next piece and map cell
D $D711 Every step blitter ends with JP #R$D711 (HL = where the next step starts); the flat-step blitter #R$E24D stores #R$CE49 itself and comes back to the second instruction. #R$CEDB and #R$CE5B come in further down, at the step counters, for steps handled at the edges.
D $D711 When a piece's last step is done the stack is put back at #R$5B7A. That address is hard-wired: the landscape is always reached by the play loop's CALL #R$C374 (2 bytes), its PUSH IY (2) and the CALL #R$D0BD in #R$DDF8 (2), below the game's stack top; the fly-in in #R$DCA1 reaches it at the same depth (its CALL, a PUSH BC, the CALL).
D $D711 Then what lies behind the moving landscape is repaired. The screen is never cleared: the sky is black and the inside of the ground is a $55/$AA checker, and both look the same after a move of two pixels either way, which is why the landscape scrolls in steps of two. Only the strips a moving edge uncovers need painting. Across: when the fine horizontal position comes back to a byte boundary each step has just moved into the next byte column, leaving its old one behind; a sloped piece gets that column filled step by step by #R$E41C, with the checker ($55AA) or black (0) chosen by the scroll's direction, the piece's direction and whether it is a ceiling (#R$5C35); a flat piece's drop ends are done by #R$D8DA. Up and down: if the landscape moved vertically (#R$CCBA), #R$D9A8 fills the rows behind every drawn step. Then #R$CF38 colours the piece.
D $D711 Then the next piece of this map cell begins (back in #R$D0BD); when the cell's pieces are done, the next of the four map cells (#R$5C1D 0 to 3: upper-left, lower-left, upper-right, lower-right) follows, with the drawing origin moved down a cell (#R$CE42 + $A0) or back up (#R$CE42 + $60, i.e. - $A0), and right a cell (#R$CE41 - $20, i.e. + $E0) for the right-hand pair. After the fourth, #R$CE41 is put back and the landscape is done. #R$D0BD jumps to both of those places too.
R $D711 HL Screen address where the next step starts
  $D711,3 Keep it.
  $D714,2 Count the step as drawn (D'). The flat-step blitter returns here.
  $D716,14 Count it in #R$5C2F and #R$CE54 too.
  $D724,5 Next step: its variant byte, one fewer to go.
  $D729,3 Steps drawn, into the current-piece record.
  $D72C,3 Take the stack back from the blitters: always #R$5B7A, the depth the landscape is called at.
  $D72F,3 A flat piece's end lip (#R$D86A).
  $D732,15 Column fill only if steps were drawn and the fine horizontal position is on a byte boundary.
  $D741,37 No horizontal scroll: a flat piece needs nothing; a sloped one is filled anyway, with a scroll direction made up from its own direction (#R$E41B, flipped by the ceiling flag #R$5C35 for a slope) and taken away afterwards (#R$5C1A says to).
  $D766,7 Flat piece: #R$D8DA.
  $D76D,27 Start from the piece's first step (#R$CE4F, its y from #R$CE53). A vertical wall is not a ceiling here, and moves a byte against its direction.
  $D788,23 DE = the checker, or black if scroll direction, ceiling flag and piece direction say the uncovered side is sky.
  $D79F,42 The column to fill: just left of the piece, or past its steps, by direction.
  $D7C9,23 A wall is filled as one column, 16 rows a step tall.
  $D7E0,14 C = row pairs a step, B = steps: fill (#R$E41C).
  $D7EE,10 Take away a made-up scroll direction.
  $D7F8,14 Vertical scroll this pass and steps drawn: fill the rows behind (#R$D9A8).
  $D806,4 Colour the piece (#R$CF38).
  $D80A,16 Stack back to #R$5B7A; the next piece, if any are left in this map cell (#R$5C20). #R$D0BD jumps here for a piece it skips.
  $D81A,11 Next map cell of the window. #R$D0BD jumps here for an empty cell.
  $D825,15 Origin down a cell for a lower one, back up for an upper one.
  $D834,20 Origin right a cell for the right-hand pair.
  $D848,9 Done: horizontal origin put back.
@ $D851 label=floor_lip_bytes
b $D851 End-lip graphics for flat floor pieces
D $D851 Used by #R$D86A. Three lips, four rows tall and one byte wide, one for each fine horizontal position 2, 4 and 6 (none is needed on a byte boundary), each listed from the bottom row up. The ceiling pieces' lips follow at #R$D85E.
B $D851,12,4 Fine positions 2, 4, 6
@ $D85D label=last_step_in_border
g $D85D Last flat step hangs into the border
D $D85D $FF when a flat piece's last step hangs off the left edge into the border (set by #R$D319, cleared for each piece by #R$D0BD); 0 otherwise. It makes #R$D588 skip that step, #R$D86A draw the piece's lip a character row up, and #R$D9A8 treat the piece's fill differently.
@ $D85E label=ceiling_lip_bytes
b $D85E End-lip graphics for flat ceiling pieces
D $D85E As #R$D851, for direction 7.
B $D85E,12,4 Fine positions 2, 4, 6
@ $D86A label=draw_flat_end_lip
c $D86A Draw the lip at the end of a flat piece whose end cap is $13
D $D86A A flat run ending in cap $13 ($93 once seen) gets a lip one byte wide and four rows tall in the byte column after its last step, from #R$D851 (floor) or #R$D85E (ceiling) for the current fine horizontal position. Nothing is drawn on a byte boundary or outside the play area's columns, and the lip is cut to two rows at the play area's bottom (#R$5C2D = $B9) or top (#R$5C2D = $19).
  $D86A,18 Only for a flat piece with end cap $13 that drew something.
  $D87C,25 DE = the lip for this direction and fine position.
  $D896,23 The column after the last step; a last step hanging into the border puts it a character row up.
  $D8AD,7 Outside columns 1-28: nothing.
  $D8B4,23 At the bottom edge: two rows only, from the play area's bottom row (the cut never came up in the build's sessions).
  $D8CB,6 At the top edge: two rows only.
  $D8D1,9 Write the lip upwards.
@ $D8DA label=fill_flat_end_column
c $D8DA Blank the byte column a flat piece's drop leaves behind when scrolling across
D $D8DA Called at the end of a flat piece when the fine horizontal position is on a byte boundary and the landscape is scrolling across (#R$CCBB). A byte column four rows tall beside a drop at one end of the run is cleared to black by #R$E41C. Which step gives the place depends on the current-piece record's +1: if zero, the piece's first step (#R$CE4F), provided its cap on the side the scroll moves towards (#R$5C34 when #R$CCBB is negative, else #R$5C33) is odd; otherwise the step kept by #R$D588 (#R$5C27 set), two columns on.
  $D8DA,7 No horizontal scroll: nothing to do.
  $D8E1,31 +1 zero: is that cap odd? Then the column left of the first step.
  $D900,24 Otherwise the step kept by #R$D588, two columns on (a character row up if it hung off the left edge).
  $D918,17 Its y; scrolling the other way, four columns further.
  $D929,14 Black, two row pairs, one step: #R$E41C.
@ $D937 label=step_screen_address
c $D937 Work out a step's screen position and address
D $D937 Screen x = in-cell x (#R$CE43) + horizontal origin (#R$CE41); screen y = in-cell y (#R$CE44) + vertical origin (#R$CE42). Both go into the current-piece record (+0, +1) and #R$5C2C/#R$5C2D, and HL is the screen address (#R$A149). For the piece's first step the address is also kept in #R$CE4F (a character row back when the step hangs off the left edge, x from $F0) and its y in #R$CE53; for the piece's first drawn step the screen position is kept in #R$CE55/#R$CE56 (#R$CE5B calls the routine's last part for that alone).
R $D937 IX Current-piece record (#R$DEDC)
R $D937 O:HL Screen address of the step
  $D937,15 Screen y.
  $D946,15 Screen x.
  $D955,11 D = $20 if the step hangs off the left edge; the address.
  $D960,20 First step of the piece: keep its address and y.
  $D974,5 Not the first drawn step: done.
  $D979,23 Keep the first drawn step's screen position (also entered here).
@ $D990 label=adjust_fill_for_scroll
c $D990 Adjust a vertical fill's start column and width for a horizontal scroll
D $D990 Used by #R$D9A8 for a flat piece with no step set up. With #R$CCBB negative the fill starts a column further left. The rest (a column back right and one narrower) can only run for #R$CCBB = -128, never ran, and looks dead.
R $D990 L Low byte of the fill's screen address
R $D990 C Fill width in bytes
@ $D9A8 label=fill_behind_moving_piece
c $D9A8 Fill the rows a vertically scrolled piece has uncovered
D $D9A8 When the landscape has moved up or down by #R$CE3F pixels (2 or 4) this pass, each drawn step of the piece leaves that many rows of its old place uncovered: below it when the landscape moved up, above when it moved down. Starting from the first drawn step (#R$CE55), this paints them step by step (#R$DB26 with IY = #R$DB41 for 2 rows, #R$DB49 for 4) with the checker ($55AA) for ground or black for sky -- the other way round for a ceiling piece (#R$5C35). The width per step is its byte advance (#R$5C24), adjusted for the shift, a reversing piece and drop caps (#R$8347, #R$D990).
@ $D9A8 nowarn
@ $D9B3 nowarn
  $D9A8,15 Two rows or four.
  $D9B7,18 Black or checker by the direction and the ceiling flag.
  $D9C9,9 Start at the first drawn step.
  $D9D2,47 A vertical wall: filled as one tall step; nothing if it is moving the wrong way.
  $DA01,20 Start above the step (moving down) or below it (moving up).
  $DA15,3 Keep the start for #R$8347.
  $DA18,58 Flat piece: moved by the horizontal scroll, and filled as a single strip as wide as all its steps (1 + 3 a step, in #R$5C24, and less one into the operand of the LD A,n near the end of #R$8347).
  $DA52,78 No step set up and not a wall: moved by the horizontal scroll; a piece that reverses (#R$5C32) turns #R$E41B round; off a byte boundary the strip is a byte wider.
  $DAA0,7 Flat piece: width adjusted for drop caps (#R$8347).
  $DAA7,18 Screen address of the start; x from $F0 is the character row before.
  $DAB9,97 C = width; nudge the start column by the piece's and the scroll's directions.
  $DB1A,12 B = steps: fill behind them, then on to colouring.
@ $DB26 label=fill_next_step
c $DB26 Fill behind one step (loop head)
D $DB26 Switches to the fill's register set and jumps to the routine in IY (#R$DB41 or #R$DB49), which comes back through #R$DB29 for the next step.
R $DB26 B' Steps left
@ $DB29 label=fill_up_past_step
c $DB29 Move a fill up past the rest of a step, and loop
D $DB29 Moves HL up the rest of the step's height (#R$CE5A less the B rows already filled), keeps #R$CE44 in step, and loops to #R$DB26 for the next step.
R $DB29 B Rows already filled
@ $DB41 label=fill_two_rows
c $DB41 Fill two rows behind a step
D $DB41 One row pair (#R$DB5B), then up the step.
@ $DB49 label=fill_four_rows
c $DB49 Fill four rows behind a step
D $DB49 Two row pairs, the second a byte advance back to the left, then up the step.
@ $DB5B label=fill_row_pair
c $DB5B Fill one row pair across a step's width
D $DB5B Writes D on the row at HL and E on the row above, for C bytes rightwards, skipping any byte outside columns 1-28, and only when the row (#R$CE44) is inside the play area. Then moves #R$CE44 and HL two rows up and a byte advance on.
R $DB5B HL Screen address
R $DB5B C Width in bytes
R $DB5B DE Fill pattern: $55AA (checker) or 0
  $DB5B,11 Row outside the play area: nothing.
  $DB66,18 Across the width, inside columns 1-28 only.
  $DB78,17 Two rows up, a byte advance across.
@ $DB89 label=blit_right_clip
c $DB89 Draw a sloped step cut off by the right edge
D $DB89 Reached through #R$D703 (dispatch 2) for a sloped step of a piece running right (directions 1-3 and their ceilings) that crosses the play area's right edge: only its left one or two byte columns are written. Like the full blitters it zig-zags up the screen two rows at a time, popping the graphic from SP. After the first column's byte, the JR whose displacement #R$D481 or #R$D494 set decides the rest:
D $DB89 #LIST { 0: the second column, then the upper row's second and first columns, passing the third column's pair -- a three-byte step cut to two. } { $1E: one column -- a three-byte step cut to one. } { $1F: one column -- a two-byte step cut to one. } { $20: one column -- a one-byte step, uncut. } LIST#
D $DB89 This was code typed as text and data in the first code map.
R $DB89 A Row pairs
R $DB89 HL Screen address, less the byte advance
R $DB89 SP The step's graphic
  $DB89,1 B = row pairs.
  $DB8A,5 To the step's first column.
  $DB8F,2 Lower row, first column.
  $DB91,2 Patched: how much more of the row pair is drawn.
  $DB93,3 Second column; up a row.
  $DB96,2 Pass the third column's pair; take the upper row's.
  $DB98,3 Upper row: second column, first column.
  $DB9B,17 Up a pixel row, crossing a character row if need be.
  $DBAC,2 Next row pair.
  $DBAE,3 Done.
  $DBB1,6 One-column cuts: pass two pairs, one, or none; up a row; the upper row's first column.
@ $DBB7 label=blit_left_clip
c $DBB7 Draw a sloped step cut off by the left edge
D $DBB7 Reached through #R$D703 (dispatch 8) for a sloped step of a piece running right that hangs over the play area's left edge (#R$D4CB). HL moves to column 1 of the same character row; the first patched JR decides whether one or two graphic bytes are skipped (INC SP), so that the first byte popped belongs in column 1; the second decides how much of each row pair is written: displacement 0 the last two columns, $2C the last column of a two-byte step, $30 the last column of a three-byte step. A POP at the end of each row pair keeps the graphic in step. Afterwards the next step's column comes from #R$5C2E.
D $DBB7 This was code typed as text and data in the first code map, before the staged tours ran it.
R $DBB7 A Row pairs
R $DBB7 HL Screen address
R $DBB7 SP The step's graphic
  $DBB7,1 B = row pairs.
  $DBB8,7 Column 1 of this character row.
  $DBBF,1 Skip a graphic byte...
  $DBC0,2 ...patched: and another (displacement 0) or not (1).
  $DBC2,1 The second byte skipped.
  $DBC3,2 Lower row, column 1.
  $DBC5,2 Patched: how much more of the row pair is drawn.
  $DBC7,7 Column 2; up a row; upper row column 2, column 1.
  $DBCE,1 Pass the rest of the row pair.
  $DBCF,17 Up a pixel row, crossing a character row if need be.
  $DBE0,2 Next row pair.
  $DBE2,14 The next step's column, from #R$5C2E and the byte advance.
  $DBF0,3 Done.
  $DBF3,4 Last column of a two-byte step: up a row, the upper row's byte.
  $DBF7,6 Last column of a three-byte step: up a row, the upper row's byte, pass a pair.
@ $DBFD label=blit_mirrored_left_clip
c $DBFD Draw a mirrored sloped step cut off by the left edge
D $DBFD Reached through #R$D703 (dispatch 11) for a sloped step of a piece running left (directions 4-6 and their ceilings) that hangs over the left edge. Those directions are drawn as mirror images: each byte is looked up in the bit-reversing table #R$F900 with B = its page and C = the byte, so the row count lives in B' and the loop switches register sets. HL goes to column 1; INC SP and the first patched JR skip one or two graphic bytes; the second patched JR (displacement 0, $26 or $2A, set by #R$D4CB) picks how many columns of each row pair are written.
D $DBFD This was code partly typed as data in the first code map.
R $DBFD A Row pairs
R $DBFD HL Screen address
R $DBFD SP The step's graphic
  $DBFD,3 Row count into B'.
  $DC00,7 Column 1 of this character row.
  $DC07,2 B = the page of the bit-reversing table.
  $DC09,2 Skip one graphic byte...
  $DC0B,2 ...patched: and another (displacement 0) or not (1).
  $DC0D,1 The second byte skipped.
  $DC0E,5 Lower row, column 1, mirrored.
  $DC13,2 Patched: how much more of the row pair is drawn.
  $DC15,10 Column 2; up a row; upper row column 2.
  $DC1F,3 Upper row, column 1.
  $DC22,1 Pass the rest of the row pair.
  $DC23,17 Up a pixel row, crossing a character row if need be.
  $DC34,7 Next row pair (counted in B'); done.
  $DC3B,4 One column of a two-byte step: up a row, the upper row's byte.
  $DC3F,8 One column of a three-byte step: up a row, the upper row's byte, pass a pair.
@ $DC47 label=blit_mirrored_right_clip
c $DC47 Draw a mirrored sloped step cut off by the right edge
D $DC47 Reached through #R$D703 (dispatch 5) for a sloped step of a piece running left that crosses the right edge. Like #R$DBFD it mirrors each byte through the table #R$F900 and keeps the row count in B'. The patched JR (displacement set by #R$D4B8: 0 for two columns, $26, $27 or $28 for one, by how many pairs must be passed) decides how many of the step's columns are written.
D $DC47 This was code partly typed as data in the first code map.
R $DC47 A Row pairs
R $DC47 HL Screen address less the byte advance
R $DC47 SP The step's graphic
  $DC47,3 Row count into B'.
  $DC4A,5 To the step's first column.
  $DC4F,5 B = the page of the bit-reversing table; into the loop.
  $DC54,1 Loop: the drawing registers.
  $DC55,4 Lower row, first column, mirrored.
  $DC59,2 Patched: how much more of the row pair is drawn.
  $DC5B,11 Second column; up a row; pass the third column's pair; upper row second column.
  $DC66,3 Upper row, first column.
  $DC69,17 Up a pixel row, crossing a character row if need be.
  $DC7A,7 Next row pair (counted in B'); done.
  $DC81,6 One-column cuts: pass two pairs, one, or none; up a row; the upper row's first column.
@ $DC87 label=map_window_pointer
g $DC87 The next tile record to draw
D $DC87 A pointer into #R$DC89: reset to its start by #R$DDF8 and #R$DF08, and moved on a word by #R$D0BD as it takes each map cell's tile record (and by #R$DF08 as it fills the list).
W $DC87,2
@ $DC89 label=map_window_tiles
b $DC89 The tile records of the four map cells on screen
D $DC89 Filled by #R$DF08 whenever the view crosses into a new map cell: the addresses of the tile records (from #R$6C3C) of the view's page, the one below, the one to the right and the one below-right -- the same order as their collision-box lists #R$5B80, #R$5BA5, #R$5BCA and #R$5BEF. Walked through #R$DC87 by #R$D0BD once a pass.
W $DC89,8,2
@ $DC91 label=map_window_tile_bytes
b $DC91 The tile bytes of the four map cells on screen
D $DC91 Written by #R$DF08: the four cells' tile bytes from the map #R$61BC, in the same order as #R$DC89. The collision and object code reads them too.
B $DC91,1 The view's cell
@ $DC92 label=map_window_tile_below
b $DC92 The tile byte of the cell below the view's
D $DC92 The second of #R$DC91's four, read on its own by the collision and object code.
B $DC92,1
@ $DC93 label=map_window_tile_right
b $DC93 The tile byte of the cell right of the view's
D $DC93 The third of #R$DC91's four.
B $DC93,1
@ $DC94 label=map_window_tile_below_right
b $DC94 The tile byte of the cell below and right of the view's
D $DC94 The fourth of #R$DC91's four.
B $DC94,1
@ $DC95 label=ground_attr_above
g $DC95 The landscape's attribute above ground
D $DC95 Copied by #R$DCA1 from the current planet's pair in #R$DC97. #R$DEE1 uses it for map rows above row 12; #R$D0BD's colouring reads it too.
@ $DC96 label=ground_attr_below
g $DC96 The landscape's attribute below ground
D $DC96 Copied by #R$DCA1 from the current planet's pair in #R$DC97. #R$DEE1 uses it for map rows 12 on, the caverns.
@ $DC97 label=planet_ground_colours
b $DC97 Landscape attributes for each planet
D $DC97 Five pairs, one per planet (indexed by the planet number at +$12 of the player record #R$F5E7, in #R$DCA1): the attribute above ground, then below. Planet 0's is bright magenta, then yellow (seen as olive) on black.
B $DC97,10,2
@ $DCA1 label=start_landscape
c $DCA1 Set up the landscape for a life and scroll it into view
D $DCA1 Called by #R$F440 when a player's life starts. Fills the fuel, blacks out the play area's colour, takes the planet's landscape colours from #R$DC97, and restores the view from the player's record #R$F5E7: the map column and row (+$13, and +$14 kept one less), the in-cell x and y at the play area's left and bottom edges (+$15, +$16; bit 0 of the x set means the play area does not need filling with the checker first), and the scroll origins (+$17, +$18).
D $DCA1 Then, with #R$5C3C = $FF (the fly-in), the landscape is scrolled vertically 4 pixels a pass (2 on the first if that brings the origin to a multiple of 4) through #R$DDF8, with #R$DD79 deciding when to stop; with #R$5C3C = 3 one more pass is drawn; and with #R$5C3C = 0 the window is rebuilt with its objects, the ship's record (in #R$C891) gets the map position, and play goes on by way of #R$71F0.
  $DCA1,11 Fuel full.
  $DCAC,7 Play area's attributes black (the colour patch at #R$F10F, 28 by 20 cells).
  $DCB3,19 This planet's two landscape attributes.
  $DCC6,29 Starting below ground (map row 12 or more): the below-ground colour, and items 9 and 10 of the player's item records (bit 7 of +$41 and +$45 of #R$F5E7) and +$10 reset.
  $DCE3,4 The play area's colour, applied later.
  $DCE7,37 Fill the play area (28 columns by 160 rows, from the bottom) with the checker unless bit 0 of the saved x says not to.
  $DD0C,23 Map position, edge positions and scroll origins from the player's record.
  $DD23,10 Vertical scroll step: 2 if bit 1 of the vertical origin is set, else 4.
  $DD2D,11 Fly-in phase; build the map window (#R$DF08).
  $DD38,23 No horizontal scroll; the ship's screen x (#R$C902) = $60; clear 300 bytes from #R$F6B9.
  $DD4F,35 Ship and panel set-up (#R$AFE9, #R$AA37, the end of #R$A8A5); at most 40 passes of fly-in.
  $DD72,7 One pass: fuel gauge, then the scroll and landscape (#R$DDF8). #R$DD79 comes back here for the next.
@ $DD79 label=fly_in_step
c $DD79 Decide whether the landscape's fly-in has finished
D $DD79 #R$DDF8 comes here instead of going on with the play pass while #R$5C3C is not zero. In the fly-in ($FF) the landscape keeps scrolling 4 pixels a pass: 40 passes (160 rows, one map cell) when the play area was left unfilled, or, when it was filled with the checker, until the six bytes in two rows at the ship's screen position (kept in #R$C891) are all clear -- the sky has been swept down to the ship's place. Then the colour goes on, one pass is drawn with #R$5C3C = 3, and finally the window is rebuilt with objects (#R$5C3C = 0), the ship's record (in #R$C891) gets the map column and row (+1, +4) and the in-cell position (+2, +5), and play begins through #R$71F0, which returns to the caller of #R$DCA1.
  $DD79,8 The last pass done: on to play.
  $DD81,5 Scroll 4 pixels a pass.
  $DD86,33 Filled with the checker: go on until the ship's place is clear.
  $DDA7,3 Not filled: 40 passes.
  $DDAA,21 Colour the play area; one more pass with the window rebuilt.
  $DDBF,11 Play: rebuild the window with its objects.
  $DDCA,37 The ship's map position and in-cell position.
  $DDEF,3 Into play.
@ $DDF2 label=start_filled
g $DDF2 Play area filled at the start of the life
D $DDF2 1 if #R$DCA1 filled the play area with the checker at the start of the life, which changes how the fly-in ends (#R$DD79); 0 if it left it.
@ $DDF3 label=unused_landscape_bytes
u $DDF3 Unused
D $DDF3 Two bytes nothing reads or writes.
@ $DDF5 label=left_column_objects
g $DDF5 Objects in the window's left map column
D $DDF5 How many objects the map holds in map column #R$CE57; written and read by #R$E08F.
@ $DDF6 label=right_column_objects
g $DDF6 Objects in the window's right map column
D $DDF6 How many objects the map holds in the column after #R$CE57; written and read by #R$E08F.
@ $DDF7 label=right_map_column
g $DDF7 The window's right-hand map column
D $DDF7 The map column after #R$CE57, wrapped to 0-95, written by #R$E235 as it reads the map. #R$DF08, #R$E062, #R$E08F and the object code read it.
@ $DDF8 label=scroll_landscape
c $DDF8 Scroll the view, step through the map, and draw the landscape
D $DDF8 Jumped to at the end of #R$C374 (once a play pass) and from #R$DCA1 (the fly-in). #R$CCBA and #R$CCBB are this pass's vertical and horizontal scroll in pixels (signed, from the ship's movement). The scroll origins #R$CE42 and #R$CE41 move by them, and the in-cell positions at the play area's bottom and left edges (#R$CE46 = $B7 - #R$CE42, #R$CE45 = 8 - #R$CE41) move the other way. When an edge position leaves its map cell it wraps by a cell -- 160 rows or 224 columns -- and the map row or column (#R$CE58, #R$CE57) moves by one; C counts the wraps into #R$5C3D.
D $DDF8 If any happened (or in the fly-in) the window of four map cells is rebuilt (#R$DF08) and its colours chosen (#R$DEE1). The landscape is drawn (#R$D0BD) unless the view is in the top three map rows, which hold no landscape (the four collision-box lists are just emptied). The sprites are handled by #R$AC60 before or after the landscape by the scroll's direction, #R$9BDA and #R$BFE3 run, four rows of the frame below the play area's bottom-left corner are made solid again, and the pass goes on at #R$C3E3 -- or at #R$DD79 during the fly-in.
  $DDF8,12 #R$CE3F = size of the vertical scroll.
  $DE04,5 No wraps yet; HL = map column and row.
  $DE09,28 Move vertically.
  $DE25,18 The bottom edge has passed the cell's top: wrap to the cell above (row - 1).
  $DE37,15 Past its bottom: wrap to the cell below (row + 1).
  $DE46,28 Move horizontally.
  $DE62,19 The left edge has passed the cell's left: wrap (column - 1).
  $DE75,14 Past its right: wrap (column + 1).
  $DE83,11 Rebuild the window if a cell was crossed; colours.
  $DE8E,7 Walk the window's four cells from the first.
  $DE95,8 #R$CCBA negative (the landscape moving up): sprites first.
  $DE9D,8 Map rows 0-2 hold no landscape:
@ $DEA5 nowarn
  $DEA5,14 empty the four collision-box lists instead.
  $DEB3,3 Draw the landscape.
  $DEB6,8 Otherwise sprites after.
  $DEBE,6 #R$9BDA, #R$BFE3.
  $DEC4,14 Solid frame bytes at column 1, pixel rows 185, 186, 189 and 190.
  $DED2,10 On with the play pass, or the fly-in.
@ $DEDC label=current_piece
s $DEDC Current-piece record
D $DEDC Five bytes, addressed through IX while a piece is drawn: +0, +1 the screen x and y of the latest step set up (+1 is cleared at the start of each piece, so zero means none yet), +2 the number of steps drawn, +3 the direction (0-15). +4 is not used here. #R$9056 and #R$BA8F use the same bytes as scratch.
@ $DEE1 label=set_landscape_colours
c $DEE1 Choose the landscape attributes for the upper and lower map cells
D $DEE1 When the window has moved (#R$5C3D) or during the fly-in: #R$5C3A gets the attribute for the upper map row (#R$CE58) and #R$5C3B the one for the row below -- #R$DC95 for rows below 12 (above ground), #R$DC96 from row 12 (caverns). The routine's tail is called as a subroutine for the first and fallen into for the second.
  $DEE1,9 Nothing changed: done.
  $DEEA,9 The upper row's attribute.
  $DEF3,21 The lower row's.
@ $DF08 label=load_map_window
c $DF08 Build the 2x2 window of map cells, and bring in the objects they hold
D $DF08 HL is the map column (0-95, wrapping at both ends) and row. The four tile bytes -- (column, row), (column, row+1), (column+1, row), (column+1, row+1) -- are read from the map #R$61BC (96 bytes a row, #R$E235) into #R$DC91, and their tile records' addresses from #R$6C3C into #R$DC89. At row 28 the lower two are tile $20, at row 29 all four. In the fly-in, tile $3E is drawn as $AA.
D $DF08 In play (#R$5C3C zero) it then refreshes the objects: the last two slots of #R$A80B, kept for the player's items, are freed if their objects have left the window (#R$E062); each of the current player's 19 item records (from +$1D of #R$F5E7; four bytes: map column, map row, x, y; bit 7 of the first set when gone) that lies in the window is put into a free special slot as kind $0C or $1E, unless it is in one already (#R$E03D); the four ground-object slots at #R$A80B are freed likewise; and #R$E08F brings in the map's objects for the window's two columns.
R $DF08 HL Map column (L) and row (H)
  $DF08,26 Wrap the column; reset the window's pointer.
  $DF22,25 The four tile bytes.
  $DF3B,30 Below the map (rows $1C and $1D): never reached in the build's sessions.
  $DF59,22 Fly-in: tile $3E becomes $AA. (No tile $3E came into a fly-in in the build's sessions.)
  $DF6F,33 The four tile-record addresses.
  $DF90,5 Fly-in: no objects.
  $DF95,14 Free the special slots whose objects have left.
  $DFA3,25 The player's item records: the first 11 are numbered 0-10 with kind $0C, the last 8 numbered 0-7 with kind $1E.
  $DFBC,28 Skip items gone or outside the window.
  $DFD8,18 Skip items already in a special slot.
  $DFEA,51 Into the first free special slot: map column, row, x, y, item number, kind.
  $E01D,11 Next item.
  $E028,21 Tidy the special slots; free the ground-object slots that have left; bring in the map's.
@ $E03D label=same_item_in_slot
c $E03D Compare an item record with a special object slot
R $E03D IX Item record (map column, row, x, y)
R $E03D IY Object slot
R $E03D O:F Z if the slot is in use and holds the same item; NZ if not, or if the slot is free ($FF)
@ $E062 label=drop_far_objects
c $E062 Free the object slots whose objects are outside the window
D $E062 A slot ($1A bytes: +0 state, $FF when free; +1 map column; +4 map row) is freed if its column is neither the window's left (#R$CE57) nor its right (#R$DDF7) column, or its row is neither of the window's two.
R $E062 IX First slot
R $E062 B Number of slots
@ $E08F label=spawn_column_objects
c $E08F Bring in the map's objects for the window's two map columns
D $E08F The things lying in the world are listed column by column: #R$5DB6 holds a count for each map column, #R$5C94 one byte per object (bits 0-5 its kind, bit 7 set once it is gone), and #R$5E17 two position bytes per object. The index of column #R$CE57's first object is the sum of the counts before it; #R$E114 brings in that column's objects, then the next column's (#R$DDF7), restarting at object 0 when the column wraps to 0. Last, slots still free get +$10 cleared.
  $E08F,23 Index of the column's first object, into #R$CE3A.
  $E0A6,11 Object counts of the two columns.
  $E0B1,24 Pointers to its positions and kinds; bring them in.
  $E0C9,27 The next column (from object 0 if it wrapped; that path never ran).
  $E0E4,25 Free slots: +$10 cleared.
@ $E0FD label=object_kind_flags
b $E0FD Object kinds: slot flags
D $E0FD One byte per kind (0-16), read by #R$E114. Bits 7-5 go to bits 3-1 of the slot's +$18; bit 4 set makes the object an animated one, graphic $1B instead of $0D, with its frame byte and frame range from #R$E10E (at the offset in the low four bits) and +$15 set to $80 so that #R$910A animates it: kinds 4, 5, $0C, $0E and $10 (whose byte is $10: bit 4 set and offset 0, frames 0 and 1 like kind 4 -- the lamp).
B $E0FD,17,8 One byte per kind
@ $E10E label=object_part_pairs
b $E10E Object kinds: the animated objects' frames
D $E10E Read by #R$E114 for a kind whose flag byte in #R$E0FD has bit 4 set: the two bytes at the low four bits' offset go to the slot's +$13, the frame byte (the first frame in bits 0-3, a count and its reload above it), and +$14, the frame range (the first frame in the high nibble, the last in the low), which #R$910A steps through. Offsets 0, 2 and 4 are used: kinds 4 and $10 show frames 0 and 1, kinds 5 and $0C frames 2 and 3, and kind $0E, the fuel station, frames 4 and 5 -- the two #R$A8F4 takes for a refuel pad. Read in the build's sessions (#R$E114).
B $E10E,6,2
@ $E114 label=spawn_objects_from_list
c $E114 Bring the objects of one map column into free ground-object slots
D $E114 For each of B objects: skip it if gone (bit 7 of its kind byte, or bit 6 for player 2: #R$F440 patches the BIT), if its map row is not one of the window's two, or if a slot at #R$A80B already holds it; otherwise take the first free of the first three slots (the fourth if none is), set it up (#R$AC34) and fill it in from the object's two position bytes -- bits 7-2 of the first are the y (less one), bits 1-0 of it and bits 7-5 of the second the x, bits 4-0 of the second the map row -- with graphic $0D, kind (+$13), its colours from #R$E205 (+$0D), the flags from #R$E0FD (+$18) and the object's index (+$18 low bits, +$19) so it can be marked gone later.
R $E114 A Number of objects (none if 0)
R $E114 B Same
R $E114 C Map column
R $E114 HL Object's kind byte (in #R$5C94)
R $E114 IX Object's position bytes (in #R$5E17)
  $E114,25 Gone, or in neither row of the window: next.
  $E12D,34 Already in a slot: next.
  $E14F,21 The first free slot.
  $E164,19 Set it up.
  $E177,24 Row, graphic $0D, kind, the colours from #R$E205.
  $E18F,23 Flags from #R$E0FD.
  $E1A6,30 An animated object: graphic $1B, its frame byte and range (#R$E10E).
  $E1C4,15 The object's index.
  $E1D3,30 Column, y, x.
  $E1F1,20 Next object.
@ $E205 label=object_kind_bytes
b $E205 Object kinds: their colours
D $E205 One byte per kind (0-16), copied by the kind into the slot's +$0D by #R$E114: the object's two colours, one in each nibble (BRIGHT in bit 3 and the ink in bits 0-2, and again in bits 7 and 4-6), which #R$AD48 shows on alternate passes, so an object whose nibbles differ flashes between the two.
B $E205,17,8
@ $E216 label=map_cell_address
c $E216 Address of a map cell
D $E216 Map rows are numbered from 1: row H is at #R$61BC + (H - 1) * $60 (rows 0 and 1 give the same address; #R$E235 treats row 0 as empty). The column wraps: $FF becomes 95 and 96 becomes 0. C is left holding the wrapped column.
R $E216 HL Column (L), row (H)
R $E216 DE $60
R $E216 O:HL Address in the map
R $E216 O:C Column, wrapped
  $E216,15 Row.
  $E225,15 Column, wrapped. (Never needed in the sessions.)
@ $E235 label=read_map_cell
c $E235 Read a tile byte from the map
D $E235 Returns the tile byte at (column, row), keeping the wrapped column in #R$DDF7. For the upper row 0 (above the map) it returns 0 (empty) and moves HL a row back so that HL + $60 is still the lower cell's.
R $E235 HL Column (L), row (H)
R $E235 O:A Tile byte
  $E244,5 Row 0.
@ $E249 label=flat_blit_lose_first
c $E249 Flat-step blitter: lose the first column
D $E249 Where the first patched JR in #R$E24D goes when #R$D588 sets its displacement to $EE: the first step of a piece with start cap $10, off a byte boundary, is drawn from its second column (by way of the end of #R$E28E, which skips one graphic byte and repatches the JR for the following row pairs).
@ $E24D label=blit_flat_step
c $E24D Draw a flat landscape step
D $E24D The blitter for directions 0 and 7 (flat floor and flat ceiling) at every fine position: all four entries in the fine-scroll tables point here. The step is three bytes wide and four rows tall (two row pairs); its graphic is twelve bytes in the order the zig-zag writes them -- the bottom row left to right, the row above right to left, and so on up. SP points at the graphic and each POP DE fetches two bytes.
D $E24D #R$CE49 is moved on three bytes for the next step. Then each row pair passes three JRs whose displacements #R$D588 patches: all 0 draws every column; the first (here) can go to #R$E28E (start column 0 or 31: from the second or third byte, at column 1), to #R$E249, or, on later row pairs, straight into #R$E2A6; the second (#R$E25B) to #R$E283 (one column); the third (#R$E25F) to #R$E289 (two columns). The cut paths POP the bytes they do not write, so SP stays in step with the graphic.
D $E24D Each row pair ends with the step up a pixel row, including the crossing of a character row, and DJNZ back to this JR (in #R$E263); at the end it returns to the second instruction of #R$D711 with #R$CE49 already set. An uncut row pair costs about 170 T-states and a whole step about 400 -- less than the deciding done for each step in #R$D319 and #R$D588.
R $E24D A Row pairs to draw
R $E24D HL Screen address, three bytes to the left
R $E24D SP The step's graphic
  $E24D,9 The next step starts three bytes on.
  $E256,3 To the step's first column.
  $E259,2 Patched: 0 to draw; $33, $EE or $4C for the cut paths.
@ $E25B label=flat_blit_first_byte
c $E25B Flat-step blitter: first column of the lower row
D $E25B Part of #R$E24D.
  $E25D,2 Patched: 0, or $24 to #R$E283.
@ $E25F label=flat_blit_second_byte
c $E25F Flat-step blitter: second column of the lower row
D $E25F Part of #R$E24D.
  $E261,2 Patched: 0, or $26 to #R$E289.
@ $E263 label=flat_blit_upper_row
c $E263 Flat-step blitter: third column, the upper row, and the step up
D $E263 Part of #R$E24D: the third column of the lower row, one row up, then the upper row right to left; then up another pixel row with the fix-up for leaving a character row (H back up by 8 within the third, unless the character row was the third's top one), and the loop.
  $E263,3 Third column, lower row.
  $E266,7 Row up; third, second, first columns. #R$E289 joins at the second, #R$E283 at the first.
  $E26D,17 Up a pixel row, crossing a character row if need be. #R$E2AB and #R$E2B6 join here.
  $E27E,2 Next row pair (back to the patched JR in #R$E24D).
  $E280,3 Done: count the step and carry on.
@ $E283 label=flat_blit_one_column
c $E283 Flat-step blitter: one column only
D $E283 Reached by the JR in #R$E25B (displacement $24) after the first byte has been written: row up, two POPs to pass the rest of the row pair's graphic, and the upper row's first-column byte (D of the last pop), written by the last part of #R$E263.
@ $E289 label=flat_blit_left_two
c $E289 Draw only a flat piece's left two bytes
D $E289 One of the clipped ways through the flat-piece blitter #R$E24D, for a piece that runs off the right-hand side of the play area with two of its three bytes still on it. #R$D588 sends the loop here by patching the JR in #R$E25F (offset $26) when the piece's column (the low five bits of #R$CE49) is $18. Each pair of rows is then drawn two bytes wide: the first row's third byte and the second row's right-hand byte are popped and dropped, so SP stays in step with the graphic.
  $E289,1 Up a pixel row: the first row's third byte is not drawn
  $E28A,1 Drop it, and the second row's right-hand byte with it
  $E28B,3 Draw the second row's other two bytes, right to left, and go round the loop

@ $E28E label=flat_blit_left_edge
c $E28E Start a flat piece that crosses the left-hand side of the play area
D $E28E The first pass of the flat-piece blitter #R$E24D comes here when #R$D588 has patched the JR at the top of its loop to offset $33 (the piece's column is $1C or $1D, that is, it begins just left of the play area, whose columns are 1 to 28). It keeps the column saved for the next piece (#R$CE49) in the right character row, moves L to column 1 of the row, and patches the loop's JR again (offset $4C) so that every later pair of rows goes straight to #R$E2A6's second instruction. Then it skips the graphic's first byte, and through the JR #R$D588 also patched (0 or 1) maybe a second one, so that only the bytes that lie on the play area are drawn.
D $E28E Column $1D leaves two bytes of each row to draw (#R$E2AB), column $1C one (#R$E2B6). The POPs that follow are one byte out of step with the graphic's pairs, which is why each row's last write and the drops in those two routines look lopsided.
R $E28E A the column kept for the next piece, low byte (#R$CE49 after the blitter added 3)
R $E28E HL the screen address of the piece's first byte
  $E28E,5 Has the next piece's column come round to the start of a character row?
  $E293,6 If so, take it back into this one
  $E299,5 L to column 1 of this pixel row
  $E29E,5 From now on the loop's JR goes to #R$E2A6 + 1 (offset $4C)
  $E2A3,1 Skip the graphic's first byte
  $E2A4,2 JR patched by #R$D588: 0 skips a second byte at #R$E2A6, 1 does not

@ $E2A6 label=flat_blit_left_rows
c $E2A6 Draw a flat piece's rows that lie right of the play area's left-hand side
D $E2A6 Part of #R$E28E's clipped path. The INC SP here is executed only on the first pass, and only when #R$D588 left the JR before it at 0 (the piece starts two bytes left of the play area); every later pass of the blitter's loop enters at the POP. The JR at the end is patched by #R$D588 too: 0 goes on to draw two bytes (#R$E2AB), $0B one (#R$E2B6).
  $E2A6,1 Skip another byte of the graphic
  $E2A7,2 The first visible byte of the row, at column 1
  $E2A9,2 JR patched by #R$D588: 0 for two bytes, $0B for one

@ $E2AB label=flat_blit_left_two_rows
c $E2AB Draw a pair of rows two bytes wide at the play area's left-hand side
D $E2AB For a flat piece that begins one byte left of the play area: draws the second byte of the first row next to the one #R$E2A6 drew, the second row's two right-hand bytes back the other way, and drops the second row's left-hand byte together with the first byte of the next pair (the POPs run one byte out of step with the graphic since #R$E28E's INC SP).
  $E2AB,2 The first row's other byte, at column 2
  $E2AD,5 Up a row; the second row's two bytes, right to left
  $E2B2,1 Drop the second row's left-hand byte and the next row's first
  $E2B3,3 Up a row, the character-row fix-up and the loop

@ $E2B6 label=flat_blit_left_one_row
c $E2B6 Draw a pair of rows one byte wide at the play area's left-hand side
D $E2B6 For a flat piece that begins two bytes left of the play area: one byte of each row is drawn, at column 1, and the rest popped and dropped.
  $E2B6,2 Up a row: the second row's right-hand byte, at column 1
  $E2B8,2 Drop the second row's other two bytes and the next row's first two
  $E2BA,3 Up a row, the character-row fix-up and the loop

@ $E2BD label=piece_blitters_shift2
b $E2BD Landscape pieces: blitters and graphics at a shift of 2 pixels
D $E2BD The first of four tables of 16 entries, one per piece direction (the high nibble of the piece's direction-and-steps byte in its tile record, kept in (IX+3)), chosen by #R$D0BD from the fine scroll position and kept in #R$CCBD: this one for a shift of 2 pixels, #R$E2FD for 4, #R$E33D for 6 and #R$E37D for 0. Each entry is two words: the blitter that draws a step of the piece, which #R$D319 loads into IY and #R$D703 jumps to, and the step's graphic at that shift, which it keeps in #R$CE47 and starts SP from.
D $E2BD The directions: 0 is flat, three bytes wide; 1, 2 and 3 are slopes that climb to the right (8 rows over 16 pixels, 8 rows over 8, 16 rows over 8), 4, 5 and 6 the same three climbing to the left; 7 to 13 are 0 to 6 upside down (ceilings: rock above, sky below), and 14 and 15 are a 16-row wall facing either way. Each graphic holds three variants of the step one above the other (9 or 17 rows each; 28 rows for a flat step); #R$D319 picks one and the count of row pairs comes in A.
D $E2BD Only nine graphics are stored: a step climbing to the left is its partner's graphic started one row later and drawn by a blitter that mirrors each byte through the bit-reversed table at #R$F900 (#R$E52C, #R$E55B). That works because the graphics zig-zag: each pair of rows is stored left to right and then right to left, so read one row later every row's bytes come in the other order. A mirrored shifted step uses the partner's graphic at the opposite shift: a slope climbing left at a shift of 2 is the right-climbing one at 6, mirrored.
D $E2BD The blitters: #R$E24D for the flat steps at every shift; at shift 0 #R$E4CF (two bytes wide), #R$E48B (one byte), and their mirrored twins #R$E52C (entered one DEC L early, at the end of #R$E4F1) and #R$E55B; at shifts 2 to 6, one byte wider, #R$E4A7 (entered at its second INC L), #R$E4CF (at its second INC L) and the mirrored #R$E4F1 (at its second DEC L) and #R$E52C. The walls (directions 14 and 15) enter one instruction later than the slopes, skipping the INC L or DEC L that places a slope in its column.
W $E2BD,8 Shift 2: directions 0 (flat) and 1 (climbs right, 16 pixels)
W $E2C5,8 Directions 2 and 3 (climb right, 8 pixels: 8 and 16 rows)
W $E2CD,8 Directions 4 and 5 (climb left: mirrors of 1 and 2)
W $E2D5,8 Directions 6 (mirror of 3) and 7 (flat, upside down)
W $E2DD,8 Directions 8 and 9 (1 and 2 upside down)
W $E2E5,8 Directions 10 and 11 (3 and 4 upside down)
W $E2ED,8 Directions 12 and 13 (5 and 6 upside down)
W $E2F5,8 Directions 14 and 15 (wall, and its mirror)

@ $E2FD label=piece_blitters_shift4
b $E2FD Landscape pieces: blitters and graphics at a shift of 4 pixels
D $E2FD Laid out as #R$E2BD: 16 entries, a blitter and a graphic for each piece direction.
W $E2FD,8 Shift 4: directions 0 and 1
W $E305,8 Directions 2 and 3
W $E30D,8 Directions 4 and 5
W $E315,8 Directions 6 and 7
W $E31D,8 Directions 8 and 9
W $E325,8 Directions 10 and 11
W $E32D,8 Directions 12 and 13
W $E335,8 Directions 14 and 15

@ $E33D label=piece_blitters_shift6
b $E33D Landscape pieces: blitters and graphics at a shift of 6 pixels
D $E33D Laid out as #R$E2BD: 16 entries, a blitter and a graphic for each piece direction.
W $E33D,8 Shift 6: directions 0 and 1
W $E345,8 Directions 2 and 3
W $E34D,8 Directions 4 and 5
W $E355,8 Directions 6 and 7
W $E35D,8 Directions 8 and 9
W $E365,8 Directions 10 and 11
W $E36D,8 Directions 12 and 13
W $E375,8 Directions 14 and 15

@ $E37D label=piece_blitters_shift0
b $E37D Landscape pieces: blitters and graphics at a shift of 0 pixels
D $E37D Laid out as #R$E2BD: 16 entries, a blitter and a graphic for each piece direction.
W $E37D,8 Shift 0: directions 0 and 1
W $E385,8 Directions 2 and 3
W $E38D,8 Directions 4 and 5
W $E395,8 Directions 6 and 7
W $E39D,8 Directions 8 and 9
W $E3A5,8 Directions 10 and 11
W $E3AD,8 Directions 12 and 13
W $E3B5,8 Directions 14 and 15

@ $E3BD label=piece_shapes
b $E3BD Terrain piece shapes
D $E3BD Nine records of three bytes, read by #R$E3D8, which copies one to #R$CE35, #R$CE36 and #R$CE37 for the piece being drawn: its run in pixels (negative for a piece that climbs to the left; 0 for a wall), its width in bytes signed the same way (also the step from one column of the ground fill to the next, #R$E41C), and its rise in pixel rows (0 for a flat piece). Directions 0 to 6 (the high nibble of the map byte) use records 0 to 6, directions 7 to 15 records 0 to 8.
B $E3BD,3 0: flat, 24 pixels, 3 bytes
B $E3C0,3 1: climbs right, 16 pixels, 2 bytes, 8 rows
B $E3C3,3 2: climbs right, 8 pixels, 1 byte, 8 rows
B $E3C6,3 3: climbs right, 8 pixels, 1 byte, 16 rows
B $E3C9,3 4: climbs left, mirror of 1
B $E3CC,3 5: climbs left, mirror of 2
B $E3CF,3 6: climbs left, mirror of 3
B $E3D2,3 7 (direction 14): a wall, 16 rows
B $E3D5,3 8 (direction 15): the wall, mirrored

@ $E3D8 label=set_piece_shape
c $E3D8 Look up a terrain piece's shape
D $E3D8 Called by #R$CD08 and #R$CD6B with the piece in hand. Copies its direction's three bytes from #R$E3BD to #R$CE35 (run in pixels), #R$CE36 (width in bytes) and #R$CE37 (rise in rows); directions 7 and up (the ceilings, and the walls) use the records seven lower and set #R$5C35 to $80. Then sets #R$E41B and the displacement of the JR at the end of #R$D319 to match: for a piece that climbs to the right (width positive) #R$E41B is $FF and the JR skips the NEG at #R$D464; for one that climbs to the left it is 1 and the NEG is done.
R $E3D8 IX the collision-box list of the map cell being drawn (see #R$D0BD); (IX+3) the piece's direction
  $E3D8,3 The shape records
  $E3DB,7 Directions 0 to 6 go straight to their record
  $E3E2,10 Directions 7 to 15: say so, and use records 0 to 8
  $E3EC,7 Three bytes a record
  $E3F3,14 Run, width and rise
  $E401,9 Say it climbs to the left: direction 1, the NEG done
  $E40D,3 It does if the width is negative
  $E410,11 Climbs to the right: $FF, and the JR jumps over the NEG

@ $E41B label=direction_flag
g $E41B The current terrain piece's direction, and a flag of the collision-box builder's
D $E41B For the landscape: $FF for a piece that climbs to the right (directions 0 to 3, 7 to 10, 14), 1 for one that climbs to the left. Set by #R$E3D8, turned round by #R$D9A8 when a piece reverses, and read throughout the landscape drawing (#R$D319, #R$D464, #R$D711 and others).
D $E41B #R$BE8F borrows it as well: set to 1 there, it says the part to the right is still to test, and #R$BE43 clears it when it does so. The code map took it for an unused byte.
B $E41B,1

@ $E41C label=fill_under_slope
c $E41C Fill the ground under a terrain piece, column by column
D $E41C Called by #R$D711 once a piece is drawn, to fill what lies beneath it with the ground's checkerboard (DE = $55AA) or to clear it (DE = 0), and by #R$D8DA to clear a column four rows deep. Each column is one byte wide and climbs from HL for C pairs of rows: D is written on one pixel row and E on the row above. After each column L moves on by the piece's width in bytes (#R$CE36), and #R$CE44, the screen row the fill has reached, goes up by the column's height. B, the number of columns, is the number of steps of the piece drawn (#R$5C2F), so this is one column a step, each the step's width in bytes across and as tall as the fill needs, which is how the ground under a slope comes out solid.
D $E41C A column is clipped to the play area: one in screen column 0 or 29 to 31 is not drawn at all (the pointer is only moved on); if the fill starts below row 183 ($B7, the bottom of the play area) the first rows are dropped and it starts at the bottom row of the play area; and near the top it is cut short by what the sum with #R$CE5A (the piece's height) and 24 says. The arithmetic of the top clip is read but not traced through.
R $E41C B the number of columns
R $E41C C' pairs of rows in each column
R $E41C DE' the two pattern bytes ($55AA for the ground's checkerboard, 0 to clear)
R $E41C HL' the screen address of the first column's bottom byte
  $E41C,2 Into the other set: B counts this column's pairs of rows
  $E41E,8 Off the play area (column 0, or 29 and up)? Only move on
  $E426,9 Does the fill start below the play area (row 184 or more)?
  $E42F,8 Then drop the rows that would lie below it
  $E437,11 And start on the play area's bottom row, $57C0 + the column
  $E442,12 Will the column reach above the top of the play area?
  $E44E,7 Then shorten it
  $E455,11 #R$CE44 goes up by the column's height (two rows a pair)
  $E460,8 Fill the column: D, up a row, E, up a row
  $E468,5 On to the next column, by the piece's width in bytes
  $E46D,4 The next column
  $E471,16 A column off the play area: account for its height and step across
  $E481,6 Move HL up by its height without drawing
  $E487,4 The next column

@ $E48B label=blit_one
c $E48B Draw a one-byte-wide terrain step
D $E48B The blitter for the one-byte-wide slopes at shift 0: directions 2, 3, 9 and 10 here, the wall (direction 14) one instruction on, skipping the INC L. Two rows a POP, one byte a row, climbing the screen with DEC H; about 75 T-states a pair of rows. The right-climbing twin of #R$E55B.
R $E48B A the number of pairs of rows
R $E48B HL the screen address of the bottom row, less one
R $E48B SP the graphic (at the variant to draw)
  $E48B,3 Step right into the column; B counts the pairs of rows; pop two bytes
  $E48E,4 One on this row, up a row, the other on the row above, up a row
  $E492,21 Into the next character row up if this one is done; the next pair; leave HL as the column for the next step (#R$D711)

@ $E4A7 label=blit_three
c $E4A7 Draw a three-byte-wide terrain step
D $E4A7 The blitter for the two-byte-wide slopes shifted by 2, 4 or 6 pixels, which are three bytes wide: directions 1 and 8, entered at the second INC L (the first is not used by the tables). Each pair of rows is three POPs: a row left to right, up a row, a row right to left; about 125 T-states a pair.
R $E4A7 A the number of pairs of rows
R $E4A7 HL the screen address of the bottom row's first byte, less two
R $E4A7 SP the graphic
  $E4A7,4 Step right into the column; B counts the pairs of rows
  $E4AB,5 Pop two bytes: the row's first two, left to right
  $E4B0,5 Pop two more: the row's third byte; up a row; the next row's right-hand byte
  $E4B5,5 Pop two more: that row's other two bytes, right to left; up a row
  $E4BA,21 Into the next character row up if this one is done; the next pair; leave HL as the column for the next step

@ $E4CF label=blit_two
c $E4CF Draw a two-byte-wide terrain step
D $E4CF Directions 1 and 8 at shift 0 (here), the one-byte slopes shifted by 2, 4 or 6 (directions 2, 3, 9 and 10, at the second INC L), and the wall shifted (direction 14, at the LD B,A). Two POPs a pair of rows: a row left to right, up, a row right to left, up; about 105 T-states a pair.
R $E4CF A the number of pairs of rows
R $E4CF HL the screen address of the bottom row's first byte, less one or two
R $E4CF SP the graphic
  $E4CF,3 Step right into the column; B counts the pairs of rows
  $E4D2,5 Pop two bytes: a row left to right; up a row
  $E4D7,5 Pop two more: the row above, right to left; up a row
  $E4DC,21 Into the next character row up if this one is done; the next pair; leave HL as the column for the next step

@ $E4F1 label=blit_mirror_three
c $E4F1 Draw a three-byte-wide terrain step, mirrored
D $E4F1 Directions 4 and 11 shifted by 2, 4 or 6 pixels, entered at the second DEC L (the first is not used by the tables). As #R$E4A7, but each byte goes through the bit-reversed table at #R$F900, and the graphic is the partner's at the opposite shift, started one row on. The last DEC L is the entry for directions 4 and 11 at shift 0 into #R$E52C.
R $E4F1 A the number of pairs of rows
R $E4F1 HL the screen address, plus two
R $E4F1 SP the graphic
  $E4F1,3 Step left into the column
  $E4F4,8 B' holds the table's page, B the count; (the loop) pop two bytes and mirror the first
  $E4FC,3 It goes on the left; the second
  $E4FF,6 Mirrored on its right; pop two more and mirror the first
  $E505,3 The row's third byte; up a row; the next
  $E508,6 Mirrored, right to left; pop two more and mirror the first
  $E50E,3 Leftwards; the last of the row
  $E511,27 Mirrored; up a row; into the next character row up if this one is done; the next pair; leave HL as the column for the next step. The last DEC L is the entry for directions 4 and 11 at shift 0 into #R$E52C

@ $E52C label=blit_mirror_two
c $E52C Draw a two-byte-wide terrain piece, mirrored
D $E52C The blitter for the pieces that climb to the left and are two bytes wide: directions 4 and 11 at shift 0 (entered one DEC L earlier, at the end of #R$E4F1), directions 5, 6, 12 and 13 at shifts 2 to 6 (here), and the wall direction 15 at those shifts (at #R$E52C + 1, skipping the DEC L). It draws like the two-byte blitter at #R$E4CF -- POP DE, two bytes left to right, up a row, two bytes right to left, up a row -- but each byte goes through the bit-reversed table at #R$F900 (built by #R$F856), so the graphic comes out mirrored. With the graphic started one row later than its right-climbing partner's (see #R$E2BD), each row's bytes arrive in the mirrored order too.
D $E52C The table lookups make it about 40 T-states a pair of rows slower than the plain blitter: about 150 T-states for two rows of two bytes, against about 105.
R $E52C A the number of pairs of rows
R $E52C HL the screen address of the bottom row's right-hand byte, plus one
R $E52C SP the piece's graphic (at the variant to draw)
  $E52C,1 Step left into the piece's column
  $E52D,4 B' holds the table's page; B the count
  $E531,5 Pop two bytes; the first, mirrored, on the left
  $E536,4 The second, mirrored, on its right
  $E53A,1 Up a row
  $E53B,4 Pop two more: the first on the right
  $E53F,4 The second on the left
  $E543,1 Up a row
  $E544,16 Into the next character row up if this one is done
  $E554,3 The next pair of rows
  $E557,4 Leave HL as the column for the next piece (#R$D711)

@ $E55B label=blit_mirror_one
c $E55B Draw a one-byte-wide terrain piece, mirrored
D $E55B The blitter for the one-byte-wide pieces that climb to the left at shift 0: directions 5, 6, 12 and 13 here, and the wall direction 15 at #R$E55B + 1 (skipping the DEC L). Each popped byte is mirrored through the bit-reversed table at #R$F900 on its way to the screen; one byte a row, two rows a POP. The right-climbing twin is the blitter at #R$E48B, which the code map left as data.
R $E55B A the number of pairs of rows
R $E55B HL the screen address of the bottom row's byte, plus one
R $E55B SP the piece's graphic (at the variant to draw)
  $E55B,1 Step left into the piece's column
  $E55C,4 B' holds the table's page; B the count
  $E560,6 Pop two bytes: the first, mirrored, then up a row
  $E566,4 The second, mirrored, then up a row
  $E56A,16 Into the next character row up if this one is done
  $E57A,3 The next pair of rows
  $E57D,4 Leave HL as the column for the next piece (#R$D711)

@ $E581 label=flat_piece_gfx
b $E581 Landscape graphics: the flat piece (direction 0)
D $E581 The terrain pieces' graphics as they came on the tape: the nine stored shapes unshifted (to the end of #R$E713), each after a header, and the room after them for their copies shifted by 2, 4 and 6 pixels, which #R$F7EB makes at the start (from #R$E74A). The tables at #R$E2BD point into them. All are drawn bottom row first by the POP blitters, and stored as the blitters read them: each pair of rows left to right, then right to left. Every graphic holds three variants of its piece one above the other.
D $E581 This one: a two-byte header for #R$F8E2, then the flat piece, three bytes a row, 28 rows (84 bytes). The ground is the planet's checkerboard ($55 and $AA on alternate rows) with the surface's bumps at the top.
B $E581,2 Header: pairs of rows to make shifted (6), width in bytes less one (2)
B $E583,84,3 The flat piece, 28 rows of 3 bytes

@ $E5D7 label=flat_piece_two_gfx
b $E5D7 Landscape graphics: the flat ceiling (direction 7)
D $E5D7 A two-byte header for #R$F8E2 as at #R$E581, then 28 rows of 3 bytes.
B $E5D7,2 Header: pairs of rows to make shifted (6), width less one (2)
B $E5D9,84,3 The piece, 28 rows of 3 bytes

@ $E62D label=slope_9_gfx
b $E62D Landscape graphics: direction 9, direction 2 upside down, one byte wide
D $E62D A three-byte header for #R$F895 (rows in each variant, halved and rounded up: 5; pairs of rows to make: 17; width in bytes: 1), then three variants of 9 rows, one byte a row (27 bytes). Direction 12 is this graphic one byte (one row) on, mirrored. The shifting at the start reads on past the end into the next graphic, for a fourth, partial variant that is never drawn.
B $E62D,3 Header
B $E630,27,9 Three variants of 9 rows

@ $E64B label=slope_2_gfx
b $E64B Landscape graphics: direction 2, a slope one byte wide, 9 rows
D $E64B Header (5, 17, 1: see #R$E62D), then three variants of 9 rows of one byte. Direction 5 is this graphic one byte on, mirrored.
B $E64B,3 Header
B $E64E,27,9 Three variants of 9 rows

@ $E669 label=slope_8_gfx
b $E669 Landscape graphics: direction 8, direction 1 upside down, two bytes wide
D $E669 Header (5, 17, 2), then three variants of 9 rows of two bytes (54 bytes). Direction 11 is this graphic one row (two bytes) on, mirrored.
B $E669,3 Header
B $E66C,54,6 Three variants of 9 rows (a pair of rows and a half a line)

@ $E6A2 label=slope_1_gfx
b $E6A2 Landscape graphics: direction 1, a slope two bytes wide, 9 rows
D $E6A2 Header (5, 17, 2), then three variants of 9 rows of two bytes, and the extra row the mirrored direction 4 reads (it starts one row on).
B $E6A2,3 Header
B $E6A5,56,6 Three variants of 9 rows, and a row more

@ $E6DD label=slope_10_gfx
b $E6DD Landscape graphics: direction 10, direction 3 upside down
D $E6DD Header (9, 29, 1: variants of 17 rows), then three variants of 17 rows of one byte (51 bytes). Direction 13 is this graphic one byte on, mirrored.
B $E6DD,3 Header
B $E6E0,51,13 Three variants of 17 rows

@ $E713 label=slope_3_gfx
b $E713 Landscape graphics: direction 3, a steep slope, one byte wide, 17 rows
D $E713 Header (9, 29, 1), then three variants of 17 rows of one byte, and one byte more for the mirrored direction 6.
B $E713,3 Header
B $E716,52,13 Three variants of 17 rows and a byte more

@ $E74A label=slope_2_shifted
b $E74A Landscape graphics: direction 2 shifted by 2, 4 and 6 pixels
D $E74A Made at the start by #R$F939 from #R$E64B (zeros on the tape): three copies of 62 bytes, one after another from here, each two bytes wide and 31 rows (three variants of 9 and a partial fourth). The mirrored direction 5 uses them two bytes on, at the opposite shift.

@ $E804 label=slope_1_shifted
b $E804 Landscape graphics: direction 1 shifted by 2, 4 and 6 pixels
D $E804 Made at the start by #R$F939 from #R$E6A2: three copies of 93 bytes (three bytes wide, 31 rows) one after another from here, and three spare bytes the mirrored direction 4 reads.

@ $E91E label=slope_3_shifted
b $E91E Landscape graphics: direction 3 shifted by 2, 4 and 6 pixels
D $E91E Made at the start by #R$F939 from #R$E713: three copies of 110 bytes (two bytes wide, 55 rows: three variants of 17 and a partial fourth) one after another from here.

@ $EA68 label=flat_piece_shifted
b $EA68 Landscape graphics: the flat piece (direction 0) shifted by 2, 4 and 6 pixels
D $EA68 Three copies of 84 bytes (three bytes wide, 28 rows) one after another from here. Only the first 12 rows of each are made at the start (#R$F8E2, by rotating the rows of #R$E581); the other 16 rows of each came on the tape already shifted.

@ $EB64 label=flat_piece_two_shifted
b $EB64 Landscape graphics: the flat ceiling (direction 7) shifted by 2, 4 and 6 pixels
D $EB64 As #R$EA68, from #R$E5D7: three copies one after another, their first 12 rows made at the start.

@ $EC60 label=wall_gfx
b $EC60 Landscape graphics: the wall (direction 14)
D $EC60 Header (9, 29, 1), then three variants of 17 rows of one byte; the mirrored direction 15 reads it one byte on. Its last bytes are overwritten by the first shifted copy (#R$EC96) before the shifting reads them, so the partial fourth variant it makes is garbage -- harmless, as it is never drawn.
B $EC60,3 Header
B $EC63,51,13 Three variants of 17 rows

@ $EC96 label=wall_shifted
b $EC96 Landscape graphics: the wall (direction 14) shifted by 2, 4 and 6 pixels
D $EC96 Made at the start by #R$F939 from #R$EC60: three copies of 110 bytes one after another from here.

@ $EDE0 label=slope_9_shifted
b $EDE0 Landscape graphics: direction 9 shifted by 2, 4 and 6 pixels
D $EDE0 Made at the start by #R$F939 from #R$E62D, with the checkerboard on the left: three copies of 62 bytes one after another from here.

@ $EE9A label=slope_8_shifted
b $EE9A Landscape graphics: direction 8 shifted by 2, 4 and 6 pixels
D $EE9A Made at the start by #R$F939 from #R$E669: three copies of 93 bytes one after another from here.

@ $EFB1 label=slope_10_shifted
b $EFB1 Landscape graphics: direction 10 shifted by 2, 4 and 6 pixels
D $EFB1 Made at the start by #R$F939 from #R$E6DD: three copies of 110 bytes one after another from here. The mirrored direction 13 reads two bytes past the end.

@ $F0FB label=spare_after_pieces
s $F0FB Spare
D $F0FB Twenty zero bytes; the first two are read by the mirrored direction 13 at a shift of 2 (#R$EFB1).

@ $F10F label=play_area_colour
b $F10F The play area's colour patch
D $F10F For #R$C991, painted by #R$F419: 28 cells wide, 20 deep, and the attribute -- the third byte, which #R$DCA1 sets for each level (0 at first, then the level's colour from its table).
B $F10F,3 Width, depth, attribute

@ $F112 label=menu_text
b $F112 The menu's text
D $F112 Twelve messages for #R$A115, printed by #R$F26C through #R$83CE: each a pixel x, a pixel y, an attribute (bit 7 set for the title), a count of characters, and the characters in the game's font codes ($00 to $19 the letters, $1A to $23 the digits, $26 a space, $28 a dash; $25 and $27 two special glyphs, and $2A to $2C the pieces of the rule under the title). In order: the title, the one- and two-player lines, the start line, the four control methods (the two joystick lines in two parts each), the copyright line and the rule. The code map split them into many small entries; their bytes run on to #R$F1BD.

@ $F1BD label=colour_ship
c $F1BD Colour the player's ship
D $F1BD Called once a pass by #R$C3E3. Works out the ship's attribute and paints it over the ship with the colour patch at #R$F1FF (6 cells wide, as many deep as the ship's height in #R$C1A9 needs): white ($47) as a rule, yellow ($46) when the ore count at #R$C905 has reached 18, and while the hit-immunity timer #R$896F runs, cyan ($45) -- flashing between cyan and the usual colour every 8 passes (bit 3 of the pass counter #R$9A64) in its last 32. A change of colour from the last one used (kept in the patch's third byte) makes a short sound through #R$725C.
D $F1BD The ore count #R$C905 goes up (to 18 at most) at #R$A8A5 while the rocket part carried (#R$F601) is part 6, the one that needs 18 ore.
  $F1BD,11 White, or yellow with 18 ore aboard
  $F1C8,1 C keeps it
  $F1C9,6 Is the hit-immunity timer running?
  $F1CF,6 Cyan; steady while the timer is 32 or more
  $F1D5,8 In its last 32, the usual colour every other 8 passes
  $F1DD,9 A sound if the colour has changed
  $F1E6,3 Where the ship is on the screen
  $F1E9,12 Its height in character rows, rounded up
  $F1F5,4 Into the patch: depth and attribute
  $F1F9,6 Paint it

@ $F1FF label=ship_colour_patch
b $F1FF The ship's colour patch
D $F1FF Three bytes for #R$C991: the width in cells (6), the depth in cells and the attribute, the last two written by #R$F1BD every pass.

@ $F202 label=menu_frame_corners
b $F202 The menu frame's corners
D $F202 Four corners of seven bytes, read by #R$CACB through +9 of the frame record (#R$F22A): a pixel position word for the corner's graphic (only its place: #R$CACB always draws the four bitmaps from #R$CC14, the panel frame's own, with #R$C96F), a position word for its colour, and a #R$C991 colour patch (width, depth, attribute).
B $F202,7 Top left
B $F209,7 Top right
B $F210,7 Bottom left
B $F217,7 Bottom right

@ $F21E label=menu_frame_ticks
b $F21E The menu frame's tick marks
D $F21E Six pairs, read by #R$CACB through +12 of the frame record: an x used for a tick on the top and bottom edges, and a y used for one on the left and right edges.
B $F21E,12,2 x, y


@ $F22A label=menu_frame
b $F22A The menu frame record
D $F22A The 17-byte record #R$CACB draws the menu's frame from, given to it in IX by #R$F26C. The play area's frame is drawn from a record of the same shape by #R$CA3F.
B $F22A,4 The screen addresses of the tops of the left and right edges
B $F22E,1 Their height in rows
B $F22F,4 The screen addresses of the top and bottom edges
W $F233,2 The corners (#R$F202, set by #R$F26C)
B $F235,1 The number of tick-mark pairs
W $F236,2 The tick marks (#R$F21E, set by #R$F26C)
B $F238,1 The y of the top tick marks
B $F239,1 The x of the right-hand ones
B $F23A,1 The length of the top and bottom edges, in bytes

@ $F23B label=random
c $F23B Stir the random numbers
D $F23B Called once a pass of the play loop (#R$F440), of the menu's loop (#R$8615) and from #R$6113. The two random bytes of #R$9BCB are stirred with a byte read from a pointer that walks through memory (kept big-endian after them), and with the player's controls as they were last read (#R$5C37). Bits 4 and 6 of the pointer's high byte are cleared and it never reaches the top 20K, so the bytes come from the ROM and the game's own code.
  $F23B,20 Step the pointer on, kept within the ROM and the code
  $F24F,1 The byte there
  $F250,12 First random byte: add the byte, the controls and 5
  $F25C,15 Second: add the byte's complement, the controls and 9

@ $F26C label=menu
c $F26C Show the menu and wait for a game to be started
D $F26C Called by #R$F422 before each game. Clears the screen, draws the frame from #R$F21E, prints the twelve lines of text at #R$F112 with #R$83CE, puts the two small glyphs of the copyright line (#R$F2E2) and colours them, draws a rule under the title, shows the two players' control methods (#R$8690), plays the title tune at #R$70D8 until a key is pressed (#R$9A9A), runs the menu's loop #R$8615 until 0 starts a game, and plays the start tune at #R$F4E4 to the end.
  $F26C,6 Clear the pixels, attributes to white on black
  $F272,25 The frame, with its corners and tick marks
  $F28B,8 The twelve lines of text
  $F293,15 The two glyphs on the copyright line
  $F2A2,8 Their colour
  $F2AA,15 A rule under the title
  $F2B9,20 Show each player's control method
  $F2CD,9 The title tune, until a key is pressed
  $F2D6,3 The menu's keys, until 0
  $F2D9,9 The start tune, played to the end

@ $F2E2 label=player_count
b $F2E2 Number of players
D $F2E2 The first byte is the number of players less one: 0 one, 1 two (set by the menu's keys, #R$86B9). Read by #R$F3BD, #R$F4C6, #R$F4FC and the menu.

@ $F2E3 label=copyright_glyphs
b $F2E3 Two glyphs for the menu's copyright line
D $F2E3 Drawn by #R$F26C with #R$C96F, one after the other: a width in bytes, a height in rows, and the rows. A copyright sign (3 bytes by 8 rows) and two letters (2 bytes by 6 rows).
B $F2E3,2 3 bytes, 8 rows
B $F2E5,24,3
B $F2FD,2 2 bytes, 6 rows
B $F2FF,12,2

@ $F30B label=clear_bytes
c $F30B Clear B bytes from HL
R $F30B HL the first byte
R $F30B B how many
R $F30B O:HL the byte after the last

@ $F311 label=reset_for_life
c $F311 Reset the play for a new life
D $F311 Called by #R$F440 at the start of every life (and of every level). Sets the ship's colour back to white, clears the death byte #R$8F53, the hit-immunity timer #R$896F, the end-of-level byte #R$96AB, the hit count and two more flags, and empties or resets the game's tables: bit 0 of the first byte of 18 two-byte entries of #R$C0E6, 96 bytes at #R$B37A, the first byte of the eight 5-byte entries of #R$96B0, 16 bytes of #R$9D2F's table; then copies four records back from the starting copies that follow them (#R$C7BC, #R$C78F, #R$C6C2, and the 32 bytes of the ship's state in #R$C891), and resets with #R$AC34 the nine 24-byte records at #R$9974 and the six 26-byte records at #R$A80B.
D $F311 Which of these tables is which is for the ranges that hold them; here they are named by address only.
  $F311,5 The ship's colour back to white
  $F316,19 Clear the death byte, the immunity timer, the end of the level, the hits and two more flags
  $F329,5 #R$9D2F to 24
  $F32E,13 Bit 0 of the first byte of 18 entries of #R$C0E6
  $F33B,8 96 bytes at #R$B37A
  $F343,14 The first byte of the eight 5-byte entries of #R$96B0
  $F351,8 16 bytes of #R$9D2F's table
  $F359,41 Four records back to their starting values
  $F382,12 Reset the nine records at #R$9974
  $F38E,8 And the six at #R$A80B
  $F396,8 The loop: B records of DE bytes from IX

@ $F39E label=clear_player_record
c $F39E Clear a player record for a new game
D $F39E Zeroes the first 28 bytes of the record (score, flags, lives, add-ons, level), sets the rocket part carried (+26) to $FF (none), and copies the starting restart position from #R$F3B7 into +19 to +24. The rest of the record (the control method at +28, and the table of the level's objects from +29) is set by #R$F3BD.
R $F39E HL the record (#R$F5CE + 25 for player 1, + 130 for player 2)
  $F39E,6 Zero +0 to +27
  $F3A4,4 +26: no rocket part carried
  $F3A8,15 +19 to +24: the restart position at the start of the game

@ $F3B7 label=start_position
b $F3B7 The restart position at the start of a game
D $F3B7 Three words copied by #R$F39E into a player record's +19 to +24, the place in the landscape a life starts from (see #R$F5CE): the values of #R$CE57, #R$CE45 and #R$CE41 to restore. Taken from those variables by #R$C33C when the restart position moves on, and put back by #R$DCA1.
D $F3B7 The origins here are $78 and $40 against a view x and y of $90 and $B7: the x pair sums to 8 as #R$CE41 says it always does, but the y pair sums to $F7, not $B7 (#R$CE42). A vertical move keeps the sum (#R$DDF8 adds the step to the origin and takes it from the view's y), and only a wrap into the next cell sets the pair afresh, to $B7 and 0 or $17 and $A0; so from a new game's start the sum is $F7 until the fly-in's first vertical wrap. Why, and what the first passes look like, is not known (read only).
W $F3B7,6 #R$CE57, #R$CE45, #R$CE41

@ $F3BD label=new_game
c $F3BD Set up a new game
D $F3BD Called by #R$F422 after the menu. Clears bits 6 and 7 of the 290 bytes from #R$5C94 (#R$9A8A with E = $3F): each player's mark on the level's objects, bit 7 for player 1 and bit 6 for player 2 (see #R$F440). Clears both player records (#R$F39E) and gives each five lives; if the score lines were left the other way round by the last game (the byte at #R$C9F6 is $A0) they are put back with #R$F591, #R$CA1C being set to $99 meanwhile so that it does not also change the current player. Player 1 is current; with one player, player 2 has no lives. Each player's control method is copied from the menu, the two scores on the panel are set to six noughts ($1A is the font's 0), and each player's table of the level's objects is filled in by #R$6113.
  $F3BD,5 Clear both players' marks on the level's objects
  $F3C2,12 Clear both records
  $F3CE,8 Five lives each
  $F3D6,13 Put the score lines back in order if they were swapped
  $F3E3,4 Player 1 is current
  $F3E7,9 One player: player 2 has no lives
  $F3F0,12 Each player's control method, as chosen on the menu
  $F3FC,16 Both scores to 000000
  $F40C,12 Each player's table of the level's objects
  $F418,1 Done

@ $F419 label=colour_play_area
c $F419 Colour the play area
D $F419 Paints the play area's attributes with the colour patch #R$F10F (28 cells by 20, in the attribute #R$DCA1 sets in it for each level). Called by #R$DCA1 and #R$DD79.

@ $F422 label=game
c $F422 The game: menu, a new game, and into play
D $F422 Jumped to by the start (#R$9A66), and by #R$F440 when the current player has no lives left. The menu (#R$F26C), a new game (#R$F3BD), a clear screen (#R$9A72, #R$9A7E), the panel (#R$CA3F), the PLAYER message (#R$F4EE), a pause of six delays (#R$A802), the play area cleared (#R$9F2C), and into the play (#R$F440).
  $F422,6 Menu, and a new game
  $F428,9 Clear the screen and draw the panel
  $F431,3 Say which player is to play
  $F434,7 A pause
  $F43B,5 Clear the play area and play

@ $F440 label=play
c $F440 The play: a life, from its start to its end
D $F440 Entered at the start of every life after the first: from its own death sequence once #R$F4C6 has taken a life, and from #R$F52A at the end of a level. A new game enters further on, past the reset and the panel, from #R$F422. Resets the play (#R$F311), goes back to the menu if the current player has no lives, redraws the panel, and then: puts back the ore (#R$C905) the player had aboard, patches the BIT in #R$E114 and the SETs in #R$A8F4 and #R$ABA8 that test and mark an object gone in #R$5C94 (one byte per object lying in the world) so that they use bit 7 for player 1 and bit 6 for player 2, and starts the level (#R$DCA1).
D $F440 The play loop, once a pass (about 20 a second): #R$C374, the fuel gauge (#R$CC77), #R$87AF, #R$8D42 (counts the death byte up, and much else), the random numbers (#R$F23B). It ends when the death byte #R$8F53 reaches 12, or when #R$96AB is $FF: the rocket, all eight parts built and the ship docked, has risen (#R$F52A).
D $F440 The death sequence: the landscape is stopped (#R$CCBA), the fuel is set to empty (#R$CC4B), part of #R$C3E3 runs once and #R$C6D2 erases the lift jet; then a shorter loop -- #R$C374, the pause key (#R$9F4E), the fuel gauge, #R$8D42, #R$C1CE, the gauge again -- runs until #R$8D42 has counted the death byte up to $50. Then the death tune (#R$F4DD), the play area dissolved (#R$9EF5), and a life is taken (#R$F4C6) before going round again.
  $F440,3 Reset the play
  $F443,6 No lives left: back to the menu
  $F449,3 Redraw the panel
  $F44C,6 Put back the player's ore
  $F452,12 Player 1 tests bit 7 of an object's state (BIT 7,(HL)), player 2 bit 6 (BIT 6,(HL))
  $F45E,11 Patch the test, and (with the bits for SET) the two instructions that set it
  $F469,3 Start the level
  $F46C,15 A pass of the play loop
  $F47B,7 Has the death byte reached 12?
  $F482,6 Go round again unless #R$96AB is $FF
  $F488,3 The level is done
@ $F492 nowarn
  $F48B,13 Death: stop the landscape, the fuel gauge to empty
  $F498,6 Once at the start of the death sequence
  $F49E,18 A pass of the death sequence
  $F4B0,7 Until the death byte is $50
  $F4B7,6 The death tune
  $F4BD,3 Dissolve the play area
  $F4C0,6 Take a life, and start the next

@ $F4C6 label=lose_life
c $F4C6 Take a life from the current player
D $F4C6 Keeps the ore aboard (#R$C905) in the player's record (+25, #R$F600), takes a life (+6), and if that was the last ends the player's game (#R$F4FC). Otherwise, with two players, hands over to the other one (#R$F591).
D $F4C6 The JR Z tests the flags the DEC A leaves; LD does not touch them. With the DEC A taken out (a NOP poked over it, as stage 0's infinite-lives poke did) the JR Z picks up the zero flag left by the last DEC C of #R$9F2C, which the death sequence has just run, and every death goes to #R$F4FC with the lives kept. An OR A in its place keeps the lives and tests them (run for the reference pages).
  $F4C6,6 Keep the ore aboard in the record
  $F4CC,9 A life less; none left: game over
  $F4D5,8 Two players: the other one's turn

@ $F4DD label=death_tune
b $F4DD The tune played when the ship has been destroyed
D $F4DD For #R$9AA9: one byte a note, bits 0 to 5 the note (an index into the table at #R$9B0C; 0 a rest) and bits 6 and 7 its length less one; $FF ends it.

@ $F4E4 label=start_tune
b $F4E4 The tune played when a game is started
D $F4E4 For #R$9AA9, in the format of #R$F4DD; played by #R$F26C as the menu ends. It ends with $FF.

@ $F4EE label=show_player
c $F4EE Say which player is to play
D $F4EE Puts the player's digit ($1B for 1, $1C for 2, from #R$CA1C) into the message at #R$F5CE + 13 and prints it with #R$A115.

@ $F4FC label=game_over
c $F4FC The current player's game is over
D $F4FC Called by #R$F4C6 when the last life has gone. Prints the player's name and GAME OVER (both messages at #R$F5CE), puts the score in the high score if it beats it (#R$F54D), plays the game-over tune (#R$F580), waits twelve delays or until 0 is pressed, clears the play area and, with two players, hands over to the other one (#R$F591 does nothing if that one has no lives either). #R$F440 then finds the current player with no lives and goes back to the menu.
  $F4FC,9 PLAYER n, GAME OVER
  $F505,3 A new high score?
  $F508,6 The game-over tune
  $F50E,17 Wait twelve delays, or until 0 is pressed
  $F51F,3 Clear the play area
  $F522,8 Two players: the other one's turn, if they have lives

@ $F52A label=level_done
c $F52A The end of a level: the rocket has risen
D $F52A Jumped to from the play loop (#R$F440) when #R$96AB is $FF, after the rocket has been built and has risen. Clears the play area, shows the end of the level (#R$83D6, which also counts the level on in the record, +18), plays its tune (#R$F56A), waits fourteen delays, clears the play area again and the player's three flag bytes (+3 to +5, see #R$F5CE), and starts the next life's play at #R$F440.
D $F52A The rocket's part of this is from the agent who read #R$96AB's setting; here, #R$83D6 is read counting the level on.
  $F52A,6 Clear the play area; the end-of-level display
  $F530,6 Its tune
  $F536,7 A pause
  $F53D,3 Clear the play area
  $F540,13 Clear the record's three flag bytes, and play on

@ $F54D label=check_high_score
c $F54D Make the score the high score if it beats it
D $F54D Compares the current player's score as printed on the panel (six characters from #R$C9F0) with the high score (#R$CA16), digit by digit from the left, and copies it over if it is greater.
  $F54D,8 The score's six digits against the high score's
  $F555,3 A digit less: not a high score
  $F558,6 Equal: the next digit
  $F55E,12 Greater: the new high score

@ $F56A label=level_tune
b $F56A The tune played at the end of a level
D $F56A For #R$9AA9, in the format of #R$F4DD; played by #R$F52A. Twenty-one notes and the $FF that ends them.

@ $F580 label=game_over_tune
b $F580 The tune played when a player's game is over
D $F580 For #R$9AA9, in the format of #R$F4DD; played by #R$F4FC. Sixteen notes and the $FF that ends them.

@ $F591 label=swap_players
c $F591 Hand over to the other player
D $F591 Does nothing if the other player has no lives (+6 of the second record). Otherwise swaps the two player records, all 105 bytes, so that the current player is always the one at #R$F5CE + 25 and the rest of the game never needs to know which; swaps the two score lines of the panel (#R$C9EC and #R$C9FC, 16 bytes each); and unless #R$CA1C is $99 (as #R$F3BD sets it while it puts the score lines in order) changes #R$CA1C to the other player, says PLAYER n (#R$F4EE), pauses eight delays and clears the play area.
  $F591,5 The other player has no lives: carry on
  $F596,11 Swap the records
  $F5A1,11 Swap the score lines
  $F5AC,6 Setting up: leave the current player alone
  $F5B2,8 The other player, and say so
  $F5BA,10 A pause, and clear the play area

@ $F5C4 label=swap_bytes
c $F5C4 Swap B bytes between (HL) and (DE)
R $F5C4 HL one block
R $F5C4 DE the other
R $F5C4 B how many

@ $F5CE label=messages_and_players
b $F5CE The GAME OVER message
D $F5CE For #R$A115, printed by #R$F4FC: a pixel x and y, an attribute (bit 7 set here), a count of characters (9) and the characters (font codes: $00 to $19 the letters, $1A to $23 the digits, $26 a space). The PLAYER message follows (#R$F5DB).

@ $F5DB label=player_message
b $F5DB The PLAYER message
D $F5DB For #R$A115, printed by #R$F4EE and #R$F4FC: x, y, attribute, a count of 8 and the characters; the last of them, the player's digit, is #R$F5E6.
B $F5DB,4 x, y, attribute, count
B $F5DF,7 The word and a space

@ $F5E6 label=player_digit
g $F5E6 The PLAYER message's digit
D $F5E6 The last character of #R$F5DB: $1B (the font's 1) or $1C (2), written by #R$F4EE from #R$CA1C, the current player.

@ $F5E7 label=score
g $F5E7 The current player's record: the score
D $F5E7 The current player's record is 105 ($69) bytes from here, to #R$F650; #R$F591 swaps it with the other player's at a change of player, so the game only ever reads and writes this one. #R$F39E clears it for a new game and #R$F3BD fills in the rest. Each field is an entry of its own; +n below is the offset from here.
D $F5E7 +0 to +2: the score, three BCD bytes, least significant first. #R$917C adds BC to it.
B $F5E7,3 Score

@ $F5EA label=player_flag_bits
g $F5EA The current player's destroyed beam generators (+3 to +5)
D $F5EA 24 bits, one for each map square (#R$AC08 picks the byte and the bit): set when the special beam destroys a beam generator there (object kinds 6 and 7, #R$ABA8), and tested by #R$9BDA, which then draws no beam in that square. Cleared at the end of a level (#R$F52A).
B $F5EA,3

@ $F5ED label=lives
g $F5ED The current player's lives (+6)
D $F5ED 5 at a new game (#R$F3BD); one taken by #R$F4C6, one given by #R$9020 (at most 9); none left sends #R$F440 back to the menu. Also read by #R$CA31 for the panel and by #R$8820 for the ground objects' firing rate.
B $F5ED,1

@ $F5EE label=addon_slots
g $F5EE The current player's add-ons (+7 to +15): the first slot
D $F5EE Nine bytes, one per add-on the ship can pick up, each 0 or the add-on's own number (1 to 9), set by #R$C3E3 when one is fitted. #R$AFE9 builds the ship's picture (#R$F6B9) from them. The ones the code reads by name are entries of their own: #R$F5EF, #R$F5F1 to #R$F5F6. This one is read by #R$AAD7, #R$AFE9 and #R$C3E3.
B $F5EE,1

@ $F5EF label=addon_two
g $F5EF Add-on 2 (+8)
D $F5EF Set by #R$AFE9 to twice the first slot as it builds the ship, and read by #R$BA8F. The byte after it, add-on 3, is not read by name.
B $F5EF,2

@ $F5F1 label=addon_four
g $F5F1 Add-on 4 (+10)
D $F5F1 Read by #R$89D3, #R$AFE9 (top speed across) and #R$C3E3 (the side jet is drawn if it is fitted).
B $F5F1,1

@ $F5F2 label=addon_five
g $F5F2 Add-on 5 (+11)
D $F5F2 Read by #R$89D3, #R$AFE9, #R$B115 and #R$C6D2 (the lift jet).
B $F5F2,1

@ $F5F3 label=addon_six
g $F5F3 Add-on 6 (+12)
D $F5F3 When fitted, the fuel burnt by #R$B115 is halved.
B $F5F3,1

@ $F5F4 label=addon_seven
g $F5F4 Add-on 7 (+13)
D $F5F4 Read by #R$B833 when bit 5 of the controls (the number row) is set.
B $F5F4,1

@ $F5F5 label=addon_eight
g $F5F5 Add-on 8 (+14)
D $F5F5 Read by #R$B731 (firing).
B $F5F5,1

@ $F5F6 label=addon_nine
g $F5F6 Add-on 9 (+15)
D $F5F6 Read by #R$AAD7, #R$AFE9, #R$BA8F and #R$C374.
B $F5F6,1

@ $F5F7 label=player_count_nine
g $F5F7 The slab-and-spire load is carried (+16)
D $F5F7 9 while the ship carries the slab and the spire (object kinds 9 and $0A, add-ons 10 and 11): set by #R$AAD7 when the slab is taken, cleared by #R$C1CE when the load is put down and by #R$DCA1; tested by #R$C1CE, which draws the load, and #R$8E2D (a cloud tests itself against the load only while it is carried). The byte after it (+17) is not referred to.
B $F5F7,2

@ $F5F9 label=level
g $F5F9 The current player's level (+18)
D $F5F9 From 0; counted on by #R$83D6 when the planet is secured. #R$DCA1 picks the level's colour and data by it.
B $F5F9,1

@ $F5FA label=restart_scroll
g $F5FA The current player's restart position (+19 to +24): the first word
D $F5FA Three words, saved by #R$C33C as the restart point moves on and put back by #R$DCA1 at the start of a life: this one for #R$CE57, #R$F5FC for #R$CE45, #R$F5FE for #R$CE41. A new game starts from #R$F3B7.
W $F5FA,2

@ $F5FC label=restart_view
g $F5FC The restart position's second word (+21)
D $F5FC For #R$CE45; see #R$F5FA. #R$DCA1 also reads its low byte.
W $F5FC,2

@ $F5FE label=restart_fine
g $F5FE The restart position's third word (+23)
D $F5FE For #R$CE41, the scroll position; see #R$F5FA.
W $F5FE,2

@ $F600 label=ore_kept
g $F600 The ore the current player had aboard (+25)
D $F600 Kept here from #R$C905 by #R$F4C6 when a life is lost and put back by #R$F440; cleared by #R$9724 when part 6 is dropped in place.
B $F600,1

@ $F601 label=rocket_part_carried
g $F601 The rocket part the current player carries (+26)
D $F601 $FF for none (#R$F39E, #R$9724); set by #R$AAD7 when a part is picked up and to 6 by #R$83D6 as a planet is secured. Read by #R$9724, #R$A8A5 (ore is collected only with part 6 aboard), #R$AFE9 and others.
B $F601,1

@ $F602 label=parts_built
g $F602 The rocket parts delivered (+27)
D $F602 How many parts of the rocket have been delivered, which is also the number of the part due next: counted up by #R$9524 as each one falls into place; read by #R$9572, which draws that many and launches at eight, and by #R$AAD7, which lets the ship take only the part due next. Set to 6 by #R$83D6, with #R$F601, at the end of a planet.
B $F602,1

@ $F603 label=control_method
g $F603 The current player's control method (+28)
D $F603 0 keyboard, 1 Kempston, 2 cursor, 3 Interface II; copied from the menu by #R$F3BD and read by #R$B16F.
B $F603,1

@ $F604 label=player_places
g $F604 The current player's places (+29 to +104)
D $F604 19 entries of 4 bytes, filled in by #R$6113 at a new game and walked by #R$DF08; bit 7 of an entry's first byte marks it done (#R$AAD7). The entries the code names directly are entries of their own: #R$F628, #R$F62C, #R$F630, #R$F64C.
B $F604,36,4

@ $F628 label=place_nine
g $F628 Place entry 9 (+65)
D $F628 Given a position by #R$C1CE; bit 7 cleared by #R$DCA1.
B $F628,4

@ $F62C label=place_ten
g $F62C Place entry 10 (+69)
D $F62C Given a position by #R$C1CE; bit 7 set by #R$AAD7 and cleared by #R$DCA1.
B $F62C,4

@ $F630 label=place_eleven
g $F630 Place entry 11 (+73), and the ones after it
D $F630 #R$AAD7 indexes the entries from here by the part's number.
B $F630,28,4

@ $F64C label=place_last
g $F64C The last place entry (+101)
D $F64C Filled in again by #R$83D6 (through #R$6113's second entry point) when a planet is secured.
B $F64C,4

@ $F650 label=other_player_record
g $F650 The other player's record
D $F650 Laid out as #R$F5E7. With one player its lives (+6) are 0, so #R$F591 never swaps it in. #R$F3BD writes its lives, control method (+28) and object table (+29) directly.

@ $F6B9 label=ship_picture
b $F6B9 The ship's picture, built in RAM
D $F6B9 300 bytes ($12C), cleared by #R$DCA1 and built by #R$AFE9 from the add-ons the player has picked up (it starts from 84 bytes copied from #R$C891 to 156 bytes in, and adds each part); six bytes a row, bottom row first like the game's other graphics. #R$C1AA points at #R$F6B9 while a rocket part hangs from the ship (bit 6 of #R$C904), the picture then five rows taller, and otherwise 30 bytes (five rows) on (#R$AA37); and #R$A8A5 adds rows to it from #R$76E9 as the ore aboard (#R$C905) grows.

@ $F7E5 label=spare_after_ship
s $F7E5 Row 50 of the ship's picture
D $F7E5 Six bytes after #R$F6B9's 300, and not spare: add-on 9 (#R$AFE9) grows the picture up to row 50 (51 rows with every add-on fitted, simulated), so its top row and its mask's are drawn here, and the ship is drawn from here up to its top: the figure's top row puts $30 in the third byte, #R$F7E5 + 2, and leaves the rest nought (watched for the reference pages). Zero in the snapshot; nothing clears it, and nothing else uses it.

@ $F7EB label=build_shifted_pieces
c $F7EB Build the landscape pieces' shifted copies
D $F7EB Called once, at the start (#R$F86B), with the shift tables from #R$FA00 in place. Clears the work bytes from #R$5C1C, 38 of them, and makes, for each of the nine stored terrain-piece graphics, its copies shifted right by 2, 4 and 6 pixels, one after another at the address given: with #R$F939 for the slopes and the wall, with #R$F8E2 for the two flat pieces. The three ceiling slopes are made with #R$5C25 set, which pads them with the checkerboard on the left instead of the right.
D $F7EB The tape holds the copies' places as zeros (the generator ORs into them), except that the flat pieces' copies are only partly made here; the rest of them came on the tape (see #R$F8E2). Each graphic starts with a header (#R$F895), which is why the source addresses here are two or three bytes before those in the tables at #R$E2BD.
D $F7EB This routine and the ones after it to #R$F939's end run once. Afterwards their bytes are reused: a sprite-compositing buffer of up to 256 bytes starts 21 bytes into this routine, inside the operand of a CALL, so it cannot have a label of its own (#R$A3F6 copies into it with LDI and #R$A498 reads it back; #R$B897 builds a sprite there and #R$B8B5 another from its 128th byte, #R$F880), over the end of this routine and the ones up to #R$F900; and from #R$F900 the bit-reversed table #R$F856 makes, over the rest.
  $F7EB,8 Clear the work bytes #R$5C1C to #R$5C41
  $F7F3,4 Floors: no padding on the left
  $F7F7,10 Direction 2 (one byte wide, 9 rows), shifted to #R$E74A
  $F801,10 Direction 1 (two bytes wide, 9 rows), to #R$E804
  $F80B,10 Direction 3 (one byte wide, 17 rows), to #R$E91E
  $F815,10 Direction 14 (the wall), to #R$EC96
  $F81F,10 Direction 0 (flat), to #R$EA68
  $F829,10 Direction 7 (the flat ceiling), to #R$EB64
  $F833,5 Ceilings: checkerboard on the left
  $F838,10 Direction 9, to #R$EDE0
  $F842,10 Direction 8, to #R$EE9A
  $F84C,10 Direction 10, to #R$EFB1

@ $F856 label=build_bit_reverse
c $F856 Build the bit-reversed table at #R$F900
D $F856 Jumped to at the end of #R$F86B, after #R$F7EB has run: #R$F900 + n gets n with its bits in the opposite order, for mirroring graphics: the ship when it faces left, the landscape's left-climbing pieces (#R$E52C, #R$E55B), and the sprite routines #R$BF85, #R$C3E3, #R$DBFD and others. It overwrites the start-up routines from #R$F900 to #R$F939's end, which are done with by then; the code map shows them because the snapshot was taken before the game ran.
  $F856,5 From #R$F900, for n = 0 to 255
  $F85B,10 Shift n's bits out of the top of D and into the top of A
  $F865,5 Store, and the next

@ $F86B label=build_shift_tables
c $F86B Build the shift tables
D $F86B Called once by the start (#R$9A66). Makes three pairs of pages: for a shift of 2 pixels, #R$FA00 + n is n shifted right two bits and the next page's byte n the two bits that fall off the right, at the top of a byte; for 4, #R$FC00 and the page after it; for 6, #R$FE00 and the page after it. A byte drawn shifted is then two lookups: the left-hand screen byte gets the high page, the right-hand one the low page. These pages overwrite the end of the loaded block, the loader's copy routine at #R$FC00 and the loader's stack below #R$FE00 among it. Then the landscape pieces are shifted with them (#R$F7EB) and the bit-reversed table made (#R$F856).
D $F86B The tables are used afterwards too: #R$AA37 reads the #R$FC00 page, #R$B322 and #R$C880 the page after it.
  $F86B,5 From #R$FA00; two bits first
  $F870,13 DE = n shifted right B bits, across two bytes
  $F87D,3 The high part in this page, the low part in the next

@ $F880 label=sprite_buffer_two
c $F880 Build the shift tables (continued); later, the second sprite buffer
D $F880 The rest of #R$F86B's loop. After the start-up these bytes are the second half of the sprite-compositing buffer that begins inside #R$F7EB: #R$B8B5 builds a sprite here (and #R$B897 one 128 bytes lower).
  $F880,7 Back to the high page; all 256 values
  $F887,8 The next pair of pages, two bits more, up to six
  $F88F,6 Shift the landscape pieces, and the bit-reversed table

@ $F895 label=read_piece_header
c $F895 Read a slope piece's header
D $F895 For #R$F939: a slope's header is three bytes -- the number of rows in each variant, halved and rounded up (to #R$5C1E, and #R$5C1F to reload it), the number of pairs of rows (row pairs to #R$5C1C and #R$5C1D), and the width in bytes (C). A flat piece's header is the last two of these (entered at its fourth instruction by #R$F8E2). D is set to $FA, the first high page of the shift tables.
R $F895 HL the header
R $F895 O:HL the graphic
R $F895 O:C its width in bytes
R $F895 O:D $FA
  $F895,8 Rows in each variant, halved
  $F89D,8 Pairs of rows
  $F8A5,2 The shift tables' first high page
  $F8A7,3 The width in bytes

@ $F8AA label=shift_byte_forward
c $F8AA Shift a graphic byte into a row being made left to right
D $F8AA ORs the high part of the byte at HL into the byte at HL' and moves on to the next, then ORs the low part into that one: the byte that spills over is left there for the next byte's high part to join.
R $F8AA HL the graphic byte
R $F8AA D the high page of the shift tables
R $F8AA HL' the copy being made
  $F8AA,7 High part, into this byte; on to the next
  $F8B1,8 Low part, into the next byte

@ $F8B9 label=pad_right_checker
c $F8B9 OR the checkerboard's high part into the copy, and move on
D $F8B9 Ends a row made left to right with the checkerboard's ($55) bits shifted in on the right. Entered at its third instruction with A ready, and at its fourth from the alternate set, by #R$F8E2 and #R$F939.
  $F8B9,3 The high part of $55
  $F8BC,6 OR it in, and move on

@ $F8C2 label=unused_inc_hl
b $F8C2 An INC HL never reached
D $F8C2 Nothing jumps here; #R$F8B9 returns just before it.

@ $F8C3 label=shift_byte_low
c $F8C3 Fetch the low part of a graphic byte
D $F8C3 B = C first (the width), when entered here; at its second instruction just A = the low part of the byte at HL, its high part being left for the next call (#R$F8C9) to fetch.
R $F8C3 HL the graphic byte
R $F8C3 D the high page of the shift tables
  $F8C3,1 B is the width
  $F8C4,5 A = the byte's low part

@ $F8C9 label=shift_byte_high
c $F8C9 OR a graphic byte's high part into the copy, and step to the next graphic byte
D $F8C9 For a row being made right to left: the high part of the byte last fetched (E) goes into the copy's current byte, which is not moved on; HL steps to the next graphic byte. Entered at its third instruction with A ready.
  $F8C9,2 Next graphic byte; A = the last one's high part
  $F8CB,5 OR it into the copy

@ $F8D0 label=next_shift
c $F8D0 Start a graphic's next shifted copy
D $F8D0 Reloads the row counts from their spares (#R$5C1F to #R$5C1E when entered here, #R$5C1D to #R$5C1C from its third instruction) and moves D on to the next pair of shift tables, two pages up. Returns with zero set when D has gone past $FF, that is, after the copy shifted by 6.
  $F8D0,6 The rows in each variant
  $F8D6,6 The pairs of rows
  $F8DC,6 The next shift; zero after the last

@ $F8E2 label=shift_flat_piece
c $F8E2 Make a flat piece's shifted copies
D $F8E2 For #R$F7EB, the two flat pieces (directions 0 and 7). A flat piece is three bytes wide and tiles: the ground under it repeats every 24 pixels. So its rows are rotated rather than shifted: the bits that would fall off the right-hand end come back in at the left (the byte that would hold them is cleared and its bits ORed into the row's first byte), and nothing is added to the width. The row pairs alternate as in the blitter #R$E24D: left to right, then right to left. After each copy, HL' skips 48 bytes: only the first 12 rows of each 28-row copy are made here, the other 16 rows of each having come on the tape already shifted (read from the simulator). The 12 made are the three 4-row variants of the step, the ground that repeats and so can be rotated; the 16 on the tape are the four end caps, already shifted (checked in the simulator for the Graphics page) -- presumably because a cap does not tile, so rotating it would wrap its edge round to the wrong side (assumed).
D $F8E2 At the end it patches a byte in the last row of each flat piece's copy shifted by 6 (#R$EA68 and #R$EB64; to $5C and $40), perhaps to mend a pixel the rotation got wrong (not checked).
R $F8E2 HL the piece's header (two bytes: pairs of rows, width)
R $F8E2 HL' where the copy shifted by 2 goes; the copies shifted by 4 and 6 follow, 84 bytes apart
  $F8E2,3 Read the header
  $F8E5,1 Back here for each shift
  $F8E6,8 A row left to right: width + 1 bytes shifted in
  $F8EE,12 Rotate: the spill clears and ORs into the row's first byte
  $F8FA,6 A row right to left: keep the first byte's low part

@ $F900 label=bit_reverse_table
c $F900 Make a flat piece's shifted copies (continued); later, the bit-reversed table
D $F900 The rest of #R$F8E2. Once the start-up is over this is the bit-reversed table #R$F856 builds: #R$F900 + n holds n with its bits reversed, 256 bytes over the end of #R$F8E2 and all of #R$F939, which have done their work by then. The game reads it with LD B,$F9 and the byte in C, to mirror the ship (#R$BF85), the left-climbing landscape steps (#R$E52C, #R$E55B) and other sprites (#R$C3E3, #R$DBFD).
  $F900,1 One byte more than the width
  $F901,11 Shift the bytes in
  $F90C,7 Take out the spill of the next row's byte
  $F913,6 And put the first byte's low part in the last byte, rotating
  $F919,9 The next pair of rows
  $F922,12 The next shift, 48 bytes further on
  $F92E,11 Two bytes of the copies mended

@ $F939 label=shift_slope_piece
c $F939 Make a slope piece's shifted copies
D $F939 For #R$F7EB, the slopes and the wall. A slope is made one byte wider than its graphic, row by row, the rows alternating left to right and right to left like the blitters that draw them; the open side of each row is filled with the checkerboard's bits ($55 on rows made left to right, $AA on the others), on the right normally and on the left for the ceilings (#R$5C25 set). The header's first count (#R$5C1E) cuts the zig-zag after each variant: a variant of 9 rows is 5 rows left to right and 4 back, so every variant begins with a row made left to right, as the blitter starting there expects.
D $F939 The pieces' graphics are packed so tightly that each copy reads a few bytes past its graphic's end (into the next graphic's header, or into the first copy made), giving a fourth, partial variant that the game never draws.
R $F939 HL the piece's header (three bytes; see #R$F895)
R $F939 HL' where the copy shifted by 2 goes; the copies shifted by 4 and 6 follow it directly
  $F939,3 Read the header
  $F93C,1 Back here for each shift
  $F93D,16 A row left to right; ceilings: the checkerboard on the left first
  $F94D,6 The row's bytes shifted in
  $F953,11 Ceilings: the right-hand byte is left with the spill only
  $F95E,3 Floors: the checkerboard's bits on the right
  $F961,9 The variant's last row? Then no row back
  $F96A,12 A row right to left; first style: the checkerboard on the right first
  $F976,12 The row's bytes shifted in, right to left
  $F982,16 Ceilings: the checkerboard on the left
  $F992,4 On past the row's last byte
  $F996,6 Start the next variant
  $F99C,9 The next pair of rows
  $F9A5,7 The next shift

@ $F9AC label=bit_reverse_table_end
b $F9AC The rest of the bit-reversed table
D $F9AC The bit-reversed table #R$F856 makes runs from #R$F900 to the end of this block, over the start-up routines #R$F8E2 and #R$F939, which are finished with by then; the snapshot, taken before the game ran, holds zeros here. The shift tables follow (#R$FA00).

@ $FA00 label=shift_tables
s $FA00 The shift tables
D $FA00 Six pages made by #R$F86B at the start: #R$FA00 + n is n shifted right 2 bits, the next page's byte n the bits that fall off (at the top of the byte); #R$FC00 and the page after it the same for 4 bits, #R$FE00 and the page after it for 6. Before the start they hold what the loader left: undecoded bytes to the end of the game block, then the copy routine #R$FC00, the loader's stack, and a character set.

@ $FC00 label=loader_copy
c $FC00 The loader's copy routine
D $FC00 Put here by the PIC block (its first LDIR copies 16 bytes into place) and called by the loader's entry at #R$5B80 once the game block has loaded, 512 bytes higher than it runs: it moves the block down 512 bytes to #R$5C80. The entry then decodes it with RRD and jumps to #R$5C80. Overwritten at the start by the shift tables (#R$F86B), so it ran only during loading.
@ $FC00 nowarn
  $FC00,3 From where the block loaded
@ $FC03 nowarn
  $FC03,3 To where it runs (#R$5C80)
@ $FC06 nowarn
@ $FC06 keep
  $FC06,5 The whole block, all of it moved
  $FC0B,1 Back to the loader

@ $FC0C label=loader_leftover
b $FC0C The rest of the 16 bytes the PIC block copied
D $FC0C LD SP,#R$FE00 and DI, the same as the start of the loader's entry at #R$5B80; not run here. Then what lies below the loader's stack.

@ $FDFE label=loader_stack
b $FDFE The loader's stack
D $FDFE The return address into #R$5B80 pushed when the entry at #R$5B80 called #R$FC00, left below the loader's stack pointer #R$FE00. The game's own stack is below #R$5B80.
W $FDFE,2 Return address into the loader's entry

@ $FE00 label=loader_leftover_charset
s $FE00 What the loader left above its stack
D $FE00 Zeros, then a character set from the loading; overwritten by the shift tables for 6 bits at the start (#R$F86B).

# The LD operands below are the addresses of the routines or buffers
# they are labelled as (skool2asm cannot tell an address from a number).
@ $B8B5 nowarn
@ $BF9E nowarn
@ $BFA5 nowarn
@ $BFAC nowarn
@ $BFB3 nowarn
@ $BFD0 nowarn
@ $BFD7 nowarn
@ $BFDE nowarn
@ $C2B6 nowarn
@ $C2C1 nowarn
@ $C2ED nowarn
@ $C303 nowarn
@ $C50C nowarn
@ $C515 nowarn
@ $C5BA nowarn
@ $C5C3 nowarn
@ $C625 nowarn
@ $C62F nowarn
@ $C668 nowarn
@ $C684 nowarn
@ $C6F3 nowarn
@ $C6FD nowarn
@ $C75D nowarn
@ $C763 nowarn
@ $F858 nowarn
