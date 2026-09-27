    DEVICE ZXSPECTRUM48
  ORG $5B00

; Game variables
;
; Below the game block, where the BASIC loader's CLEAR left the printer buffer,
; the system variables and the loader itself: the bytes the snapshot holds here
; are those, not the game's. The first thing the game does (START) is read the
; ROM's frame counter into SEED and clear everything from here to the end of
; the object records; after every game it clears again from WIPE_COUNT on
; (AFTER_GAME), so the first eight bytes -- the seed, the turn counter, the
; control method and the random number -- carry over from one game to the next.
;
; Up to NO_HEADROOM this is Knight Lore's layout, 160 bytes lower, and where
; Alien 8 does the same job it keeps the same byte. The bytes nothing refers to
; are Knight Lore's variables for things Alien 8 does not have: the three after
; FLOOR the portcullises and the werewolf's change, the one after DRAW_WORK one
; spiked ball falling (Alien 8 keeps its own at DROPPING), the one after
; PLAYER_DZ the bouncing ball's step, the one after LIFT_TOP the rooms visited,
; the two after FONT_BASE the percentage. From CLOCK on the variables are Alien
; 8's own, and the rooms seen and the carried things sit at other places than
; Knight Lore's.
SEED:
  DEFB $00                ; The seed. The ROM's frame counter when the game is
                          ; first run (START), plus the turn counter's low byte
                          ; at every new game (AFTER_GAME), plus one each time
                          ; round the menu (MENU). Bits 0-1 pick the start room
                          ; (NEW_GAME_START); with the refresh register it
                          ; picks the first kind of valve dealt
                          ; (INIT_SPECIAL_OBJECTS)
  DEFB $00                ; Nothing refers to this byte (searched): as in
                          ; Knight Lore, the byte after the seed is spare
TURNS:
  DEFB $00                ; The turn counter, a word, counted up at the end of
                          ; every turn (OBJECT_DONE) and never cleared after
                          ; the first game. Its low bits time things: the
                          ; sparks of the scene after a game (SCENE_SPARKS),
                          ; the clockwork mice's speed (CLOCKWORK_MOUSE), the
                          ; sounds (WARBLE_SOUND, CRASH_SOUND)
TURNS_HIGH:
  DEFB $00                ; Its high byte; the clockwork mice mix it with the
                          ; random number for how far to walk (CLOCKWORK_MOUSE)
CONTROL:
  DEFB $00                ; Control method, set on the menu (MENU): bits 1-2
                          ; are 0 keyboard, 1 Kempston, 2 cursor, 3 Interface
                          ; II; bit 3 directional control, toggled by key 5
RANDOM:
  DEFB $00                ; The random number: R is added in after every
                          ; object's update, and the turn counter and a byte of
                          ; memory it points at at the end of every turn
                          ; (OBJECT_DONE). Read wherever the game wants chance:
                          ; a thing dropping (CEILING_DROP), a leaper starting
                          ; (LEAPER), a mouse's turn (CLOCKWORK_MOUSE), a
                          ; tool's swing (SCENE_TOOL), the dealing of the
                          ; valves (INIT_SPECIAL_OBJECTS)
CONTROL_BEFORE:
  DEFB $00                ; The control method as it was before the menu read
                          ; the keys this time round (MENU)
  DEFB $00                ; Nothing refers to this byte (searched); spare in
                          ; Knight Lore too
WIPE_COUNT:
  DEFB $00                ; How many areas the drawing of a turn
                          ; (RENDER_DYNAMIC_OBJECTS) has wiped and left on the
                          ; stack to be copied to the screen; added to
                          ; DRAW_WORK. The first byte cleared after a game
                          ; (AFTER_GAME)
SAVED_SP:
  DEFB $00,$00            ; The stack pointer, while the sprite drawing borrows
                          ; it (CALC_PIXEL_XY_AND_RENDER, SPRITE_SHIFTED_RUN)
ROOM_HALF_U:
  DEFB $00                ; The room's half-size in U, from ROOM_SIZES
                          ; (BUILD_ROOM)
ROOM_HALF_V:
  DEFB $00                ; The room's half-size in V
ROOM_INK:
  DEFB $00                ; The room's ink, bits 0-2 of its record's third byte
                          ; (BUILD_ROOM); white once its chamber is activated
                          ; (LOOSE_VALVE). COLOUR_PANEL fills the screen's
                          ; attributes with it, and colours the panel's label
                          ; and chamber icon from it
FLOOR:
  DEFB $00                ; The floor's height, from ROOM_SIZES (BUILD_ROOM)
  DEFB $00,$00,$00        ; Nothing refers to these bytes (searched): Knight
                          ; Lore's portcullis and werewolf variables
PLAYED:
  DEFB $00                ; Bit 0 set at the end of every turn (OBJECT_DONE),
                          ; cleared at a new game (AFTER_GAME); while it is
                          ; set, entering a room first writes what lies in the
                          ; one being left back to its places (ENTER_ROOM,
                          ; UPDATE_SPECIAL_OBJS)
TAKE_HELD:
  DEFB $00                ; 1 while the pick-up key is held, so one press does
                          ; one thing (TAKE_OR_LEAVE)
PANEL_DUE:
  DEFB $00                ; Set on every press of the pick-up key that gets
                          ; past TAKE_OR_LEAVE's first checks, whether or not
                          ; anything changes hands; SHOW_CARRIED then redraws
                          ; the carried things on the panel and clears it
INPUT:
  DEFB $00                ; This turn's controls (READ_CONTROLS): bits 0 and 1
                          ; turn, 2 walk, 3 jump, 4 pick up or put down; bit 5
                          ; any letter key, ENTER or SYMBOL SHIFT, which is the
                          ; pick-up when a joystick is used with directional
                          ; control (CHK_PICKUP_DROP). None are read while the
                          ; game is won or over
PRINT_ATTR:
  DEFB $00                ; The colour byte a text list gives each line
                          ; (DISPLAY_MENU), read by the printer
                          ; (PRINT_TEXT_SINGLE_COLOUR)
NEW_ROOM:
  DEFB $00                ; Set when a room has been built (ENTER_ROOM) and
                          ; when the scene after a game is set up (GAME_ENDED).
                          ; The turn's drawing (RENDER_DYNAMIC_OBJECTS) then
                          ; wipes nothing, and the main loop (OBJECT_DONE)
                          ; draws the panel, colours the screen, copies the
                          ; whole buffer out and clears it
TEXT_SHOWN:
  DEFB $00                ; 0 until a text list has been printed and the screen
                          ; copied once (DISPLAY_MENU); the menu and the
                          ; arrival screen clear it
PLACE_NUDGE:
  DEFB $00                ; Added to the objects' positions by the builder
                          ; (BUILD_ROOM); set by a template-0 header in a
                          ; room's record
LIVES:
  DEFB $00                ; Lives, counted in binary but printed on the panel
                          ; as though BCD (PRINT_LIVES): five at a new game
                          ; (AFTER_GAME), one taken at the start of every life
                          ; (NEW_LIFE), so the one in play and four more; the
                          ; game is over when there is none to take. An extra
                          ; life adds one (EXTRA_LIFE)
SAVED_UVZ:
  DEFB $00,$00,$00        ; An object's U, V and Z before its move, saved by
                          ; SAVE_UVZ and compared after it by SAME_UVZ, so
                          ; PUSHABLE can tell whether it was moved
DRAW_WORK:
  DEFB $00                ; The turn's drawing work: SORT_AND_DRAW zeroes it
                          ; and counts every object it draws,
                          ; RENDER_DYNAMIC_OBJECTS adds the areas it wiped, and
                          ; the main loop (OBJECT_DONE) waits six units less
                          ; this
  DEFB $00                ; Nothing refers to this byte (searched): Knight
                          ; Lore's "a spiked ball is falling"
TEMPLATES_AT:
  DEFB $00                ; The object template table the builder reads, a word
                          ; with the next byte (OBJECT_TABLE, BUILD_ROOM): a
                          ; template-31 header moves it on to the second page
PLAYER_DZ:
  DEFB $00                ; The player's step in Z this turn (MOVE_PLAYER) --
                          ; and the high byte of TEMPLATES_AT while a room is
                          ; being built
  DEFB $00                ; Nothing refers to this byte (searched): Knight
                          ; Lore's bouncing ball's step
WON:
  DEFB $00                ; Set when the twenty-fourth chamber is activated
                          ; (LOOSE_VALVE). The game then ends with the arrival
                          ; screen (GAME_ENDED, ARRIVAL_SCREEN) and the robot's
                          ; oiling (OILED_ROBOT) instead of the re-programming;
                          ; while it is set the panel's carried things are not
                          ; redrawn (SHOW_CARRIED)
GAME_OVER:
  DEFB $00                ; 1 while the scene after a game runs in the main
                          ; loop (GAME_ENDED): objects are then placed in
                          ; pixels rather than projected (CALC_PIXEL_XY), the
                          ; main loop neither waits nor runs the clock
                          ; (OBJECT_DONE), and no controls are read
                          ; (READ_CONTROLS). Cleared with the rest when the
                          ; scene ends (AFTER_GAME)
LIFT_TOP:
  DEFB $00                ; The height the room's lifts rise to, one for them
                          ; all: zero when a room is built (BUILD_ROOM), then
                          ; set by the first lift or bobbing block to run
                          ; (LIFT) -- a lift (graphic 47) its own Z plus 48, a
                          ; bobbing block (graphic 31) its own Z. Measured: 112
                          ; in room $23, 100 in room $1D. Knight Lore keeps its
                          ; bouncing balls' turning height the same way
  DEFB $00                ; Nothing refers to this byte (searched): Knight
                          ; Lore's count of rooms visited
FONT_BASE:
  DEFB $00,$00            ; The base the printer adds eight times a character's
                          ; code to (PRINT_LIVES, PRINT_TEXT_SINGLE_COLOUR):
                          ; FONT less 384 for text, FONT itself for numbers
                          ; (RUN_CLOCK)
  DEFB $00,$00            ; Nothing refers to these bytes (searched): Knight
                          ; Lore's percentage
SEQUENCE_AT:
  DEFB $00,$00            ; Where the turn's drawing (RENDER_DYNAMIC_OBJECTS)
                          ; is in the list of records to draw at DRAW_LIST,
                          ; which LIST_DRAWN makes and ends with $FF
SORT_FIRST:
  DEFB $00,$00            ; A place in the depth sort's list (SORT_AND_DRAW)
SORT_SECOND:
  DEFB $00,$00            ; Another (SORT_AND_DRAW)
TUNE_HEARD:
  DEFB $00                ; Bit 0 set once the menu's tune has played
                          ; (PLAY_TUNE_ONCE), so it plays once each time the
                          ; menu is shown, not at every pass of the menu's
                          ; loop; the clear after a game (AFTER_GAME) lets it
                          ; play again
KEY5_HELD:
  DEFB $00                ; 1 while key 5 is held on the menu, so one press
                          ; toggles directional control once (MENU)
NO_HEADROOM:
  DEFB $00                ; 1 when there is no room above him to stand on what
                          ; he puts down (TAKE_OR_LEAVE)
ROOM_COLOUR_AT:
  DEFB $00,$00            ; The address of the room record's third byte, its
                          ; size and colours (BUILD_ROOM); an activated
                          ; chamber's white ink is written there (LOOSE_VALVE),
                          ; so the room stays white until the next game
CLOCK:
  DEFB $00,$00            ; The light years left, four bytes, the highest digit
                          ; first: each a digit in bits 4-7 and, in bits 0-2,
                          ; how far it still has to roll into place. 6000 at a
                          ; new game (AFTER_GAME); counted down by RUN_CLOCK
                          ; every turn, a light year every seven turns; the
                          ; game is over when all four are zero
CLOCK_LOW:
  DEFB $00                ; The third digit
CLOCK_LAST:
  DEFB $00                ; The last digit: CLOCK_BORROW takes a light year off
                          ; when it has finished rolling
DROPPING:
  DEFB $00                ; 1 while one of the things that drop from the
                          ; ceiling is falling, so only one falls at a time
                          ; (CEILING_DROP); cleared on entering a room
                          ; (ENTER_ROOM)
DROP_LATCH:
  DEFB $00                ; While it is set nothing drops from the ceiling
                          ; (CEILING_DROP): set on entering an even-numbered
                          ; room (ENTER_ROOM), cleared by a pick-up
                          ; (TAKE_OR_LEAVE) or an extra life (EXTRA_LIFE). As
                          ; Knight Lore's spiked balls
SUMMARY_LOST:
  DEFB $00                ; The summary after a game (SUMMARISE_CHAMBERS),
                          ; worked out from the room directory and the places.
                          ; The cryonauts lost -- the frozen crew, object
                          ; templates 21 and 22 (graphic 74), in the chambers
                          ; not activated -- a BCD word, high byte first; 132
                          ; when none is activated. PRINT_SUMMARY_COUNTS prints
                          ; three digits
SUMMARY_LOST_LOW:
  DEFB $00                ; Its low byte
SUMMARY_ACTIVE:
  DEFB $00                ; Chambers activated, BCD: the crew rooms where a
                          ; seated valve (graphics 100-103) lies
                          ; (SUMMARISE_CHAMBERS)
SUMMARY_IDLE:
  DEFB $00                ; Chambers not activated, BCD (SUMMARISE_CHAMBERS)
CHAMBERS:
  DEFB $00                ; Chambers activated in this game, BCD (LOOSE_VALVE),
                          ; printed on the panel (PRINT_CHAMBERS); the
                          ; twenty-fourth wins
SCENE_STATE:
  DEFB $00                ; The re-programming after a lost game. 0 while the
                          ; sparks over the robot flash; 1 when they stop
                          ; (SCENE_SPARKS); then bit 7 is set while one of the
                          ; three tools swings (SCENE_TOOL) and bits 0-6 count
                          ; the swings, the scene ending at 16
REMOTE_ORDERS:
  DEFB $00                ; The remote-controlled robots' orders. Bit 7: one
                          ; robot has taken control (REMOTE_ROBOT). Bits 0-6:
                          ; what he stands on this turn -- 1 the pad
                          ; (REMOTE_PAD), 2-5 a button (REMOTE_BUTTON), each a
                          ; step in U or V (REMOTE_STEPS) -- taken by the robot
                          ; in control as it moves; cleared on entering a room
                          ; (ENTER_ROOM)
LEAPING:
  DEFB $00                ; 1 while one of the room's leapers (graphic 130) is
                          ; in the air, so they leap one at a time (LEAPER):
                          ; set when one starts, cleared when it lands and on
                          ; entering a room (ENTER_ROOM)
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; Nothing refers to these bytes
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; (searched)
  DEFB $00,$00,$00,$00                 ;
ROOMS_SEEN:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; A bit per room number, set on entering
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; the room (MARK_ROOM_SEEN): 256 bits,
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; byte room/8, bit room AND 7. Counted
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; for the rating after a game
                                       ; (COUNT_ROOMS_SEEN)
CARRIED_NEW:
  DEFB $00,$00,$00,$00    ; What he carries -- only valves can be picked up --
                          ; in entries of four bytes: the graphic, the flags
                          ; and the address of its place. This one is where a
                          ; thing being picked up is put (TAKE_OR_LEAVE) before
                          ; the list moves on one; empty between presses
CARRIED:
  DEFB $00,$00,$00,$00    ; The things he carries, newest first (drawn on the
  DEFB $00,$00,$00,$00    ; panel by SHOW_CARRIED)
CARRIED_LAST:
  DEFB $00,$00,$00,$00    ; The oldest, which the next press puts down
                          ; (TAKE_OR_LEAVE)

; The object records
;
; Everything in the room: 56 records of 32 bytes. The first four have fixed
; jobs -- the robot's legs and top, and two for what lies in the room from the
; table of places (PLACES) -- and the other 52 are the room's, filled by the
; builder (BUILD_ROOM). The main loop (AFTER_GAME) runs every record's update
; routine once a turn, in order, empty ones included. In the scene after a game
; the same records hold the scene's pieces (SET_UP_SCENE).
;
; A record is Knight Lore's 32 bytes. +0 the graphic, which picks the update
; routine (UPDATES) and the sprite (GRAPHICS): 0 an empty record, 1 one to be
; rubbed out and emptied when next drawn. +1 +2 +3 U, V and Z. +4 +5 +6 the
; half-sizes in U and V and the height. +7 flags: bit 0 in a doorway, bit 1 out
; of the collision tests, bit 2 can be pushed and rides what it stands on, bit
; 3 may use doorways (the legs), bit 4 to be drawn this turn, bit 5 moved: wipe
; it and copy it to the screen (SET_WIPE_AND_DRAW_FLAGS sets both), bit 6
; mirrored, bit 7 upside down. +8 the room. +9 +A +B the step in U, V and Z
; this turn.
;
; +C: bits 0-2 the move was stopped in U, V, Z -- bit 2 either way, standing on
; something or bumping something above -- bit 3 jumping, bits 4-7 turns of
; walking in after a doorway. +D: bit 7 kills what it moves into and bit 5
; kills what touches it (SPIKES sets both), bit 6 killed, bit 3 landed on, by
; the robot or a mover of graphics 16-47, bit 0 just put down (a valve reads
; it, LOOSE_VALVE); bit 2 is a kind's own (a dropping thing falling, a lift's
; direction), and on the legs bits 1-2 keep his turning. +E +F the player's
; nudge from a doorway; +F is also a dropping thing's "was standing"
; (THUD_ON_LANDING) and a scene tool's steps (SCENE_TOOL). +10 +11: for what
; lies in the room from the places, the address of its place
; (FIND_SPECIAL_OBJS_HERE); for other kinds their own counters and states,
; described with each update routine (in the robot's records and the start
; records, START_LEGS, the real graphic kept while he is appearing; a pacer's
; saved step, a leaper's height, a mouse's turns, a scene piece's colour ...).
; +12 +13 the drawing nudge in pixels (DRAW_AT_L16_D9 and the entries beside
; it). +14 to +17: no instruction was found using them. +18 +19 the sprite's
; width in bytes and height in rows as drawn; +1A +1B its pixel x and y,
; counted up from the bottom -- in the scene after a game set directly, as the
; scene is not projected (SET_UP_SCENE); +1C to +1F the same four as they were
; before this turn's update (the main loop, AFTER_GAME).
;
; Below the game block, like the variables: the bytes the snapshot holds here
; are the ROM's system variables and the BASIC loader, which the game clears
; before it uses them (START).
OBJECTS:
  DEFB $00                ; Record 0, the robot's legs, the whole of his
                          ; collision box: graphic (16-23 walking, 48 on the
                          ; dying sparkle, 56-62 materialising)
PLAYER_U:
  DEFB $00                ; U, read by the things that home in on him
                          ; (MOVE_TOWARDS_PLAYER)
  DEFB $00,$00,$00,$00,$00 ; V, Z, the half-sizes and the height
PLAYER_FLAGS:
  DEFB $00                ; Flags; the first of the 56 bytes whose bit 5
                          ; CLEAR_WIPE_FLAGS clears
PLAYER_ROOM:
  DEFB $00                ; The room he is in: what the builder builds
                          ; (BUILD_ROOM), what FIND_SPECIAL_OBJS_HERE matches
                          ; the places against, and the bit set in ROOMS_SEEN
                          ; (MARK_ROOM_SEEN)
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; The rest of the legs' record
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00     ;
PLAYER_TOP:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; Record 1, the robot's top, which
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; copies the legs every turn and sits 12
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; above them; the main loop starts a new
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; life when both it and the legs are
                                       ; empty (OBJECT_DONE)
VALVES:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; Record 2: the first thing from the
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; table of places in this room -- a
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; valve, loose or seated, or an extra
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; life -- built by
                                       ; FIND_SPECIAL_OBJS_HERE and written
                                       ; back by UPDATE_SPECIAL_OBJS; a thing
                                       ; put down goes into whichever of the
                                       ; two is empty (TAKE_OR_LEAVE)
VALVE_SECOND:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; Record 3: the second
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $FF,$00,$00,$00,$FF,$00,$23,$0D ;
ROOM_OBJECTS:
  DEFB $0D,$23,$05,$00,$00,$00,$16,$14 ; Records 4 to 55, the room's:
  DEFB $01,$00,$06,$00,$0B,$00,$01,$00 ; backgrounds and objects, filled by the
  DEFB $01,$00,$06,$00,$10,$00,$00,$00 ; builder from here up (BUILD_ROOM)
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$3C ;
  DEFB $40,$00,$FF,$CD,$00,$F9,$62,$00 ;
  DEFB $00,$00,$01,$00,$FF,$1E,$00,$01 ;
  DEFB $07,$00,$00,$1D,$5D,$00,$00,$B6 ;
  DEFB $5C,$BB,$5C,$CB,$5C,$1D,$5D,$CA ;
  DEFB $5C,$1E,$5D,$21,$5D,$1C,$5D,$8D ;
  DEFB $5D,$23,$5D,$23,$5D,$23,$5D,$2D ;
  DEFB $92,$5C,$00,$02,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$B6,$1A,$00,$00 ;
FRAMES:
  DEFB $06,$00,$00        ; In the snapshot, the ROM's frame counter: the game
                          ; reads its low byte for the seed (START) before it
                          ; clears this area
  DEFB $58,$FF,$00,$00,$21,$00,$5B,$21 ; The rest of the room's records
  DEFB $17,$C0,$50,$E0,$50,$21,$02,$21 ;
  DEFB $17,$03,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$FC ;
  DEFB $62,$FF,$FF,$F4,$09,$A8,$10,$4B ;
  DEFB $F4,$09,$C4,$15,$53,$81,$0F,$C4 ;
  DEFB $15,$52,$F4,$09,$C4,$15,$50,$80 ;
  DEFB $00,$01,$3C,$00,$E7,$C3,$A7,$3A ;
  DEFB $DA,$C3,$A7,$3A,$D9,$C3,$A7,$3A ;
  DEFB $FD,$B0,$22,$32,$35,$33,$34,$30 ;
  DEFB $22,$3A,$EF,$22,$41,$6C,$69,$65 ;
  DEFB $6E,$38,$2E,$32,$22,$AA,$3A,$F5 ;
  DEFB $AC,$B0,$22,$32,$30,$22,$2C,$C3 ;
  DEFB $A7,$3B,$3A,$EF,$22,$41,$6C,$69 ;
  DEFB $65,$6E,$38,$2E,$33,$22,$AF,$0D ;
  DEFB $00,$1E,$0E,$00,$F9,$C0,$32,$35 ;
  DEFB $33,$34,$34,$0E,$00,$00,$00,$63 ;
  DEFB $00,$0D,$80,$EF,$22,$22,$0D,$80 ;
  DEFB $00,$00,$00,$63,$00,$6E,$38,$2E ;
  DEFB $33,$20,$20,$00,$00,$00,$00,$00 ;
  DEFB $00,$03,$41,$6C,$69,$65,$6E,$38 ;
  DEFB $2E,$33,$20,$20,$03,$9D,$FD,$62 ;
  DEFB $39,$80,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00             ;

; Unused
;
; Between the object records and the game block. Nothing in the game refers to
; these bytes (searched), and none was touched in the simulator from the entry
; into play; what the snapshot holds is what the BASIC loader left on its stack
; under RAMTOP.
BELOW_BLOCK:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$B1
  DEFB $33,$30,$5D,$05,$00,$B1,$33,$30
  DEFB $5D,$00,$00,$2B,$5D,$27,$5D,$2B
  DEFB $5D,$B1,$33,$26,$5D,$B1,$33,$31
  DEFB $5D,$05,$00,$F3,$0D,$B7,$2D,$23
  DEFB $5D,$1E,$5D,$00,$63,$2B,$2D,$65
  DEFB $33,$00,$00,$ED,$10,$0D,$00,$09
  DEFB $00,$85,$1C,$10,$1C,$52,$1B,$76
  DEFB $1B,$03,$13,$00,$3E

; The block's first three bytes
;
; The block loads from one past the loader's CLEAR, but the loader enters it
; three bytes in, at ENTRY. Nothing refers to these bytes.
BLOCK_START:
  DEFB $00,$00,$00

; Where the BASIC loader enters the game
;
; The loader's last line is a RANDOMIZE USR to this address. The stack goes to
; MIRROR_TABLE, the top of the space above the screen buffer, and the game
; starts at START.
ENTRY:
  DI
  LD SP,MIRROR_TABLE
  NOP
  JP START

; The font
;
; 43 characters of 8 bytes, the codes $30 to $5A. The printer adds eight times
; a code to FONT_BASE: for text, 384 bytes below this one, so that code $30
; lands here; for the light years (RUN_CLOCK), this address itself, so that the
; digits are codes 0-9.
FONT:
  DEFB $7E                ; Character 0
  DEFB $42                ;
  DEFB $42                ;
  DEFB $46                ;
  DEFB $46                ;
  DEFB $46                ;
  DEFB $7E                ;
  DEFB $00                ;
  DEFB $08                ; Character 1
  DEFB $08                ;
  DEFB $08                ;
  DEFB $18                ;
  DEFB $18                ;
  DEFB $18                ;
  DEFB $18                ;
  DEFB $00                ;
  DEFB $7E                ; Character 2
  DEFB $02                ;
  DEFB $02                ;
  DEFB $7E                ;
  DEFB $60                ;
  DEFB $60                ;
  DEFB $7E                ;
  DEFB $00                ;
  DEFB $7C                ; Character 3
  DEFB $44                ;
  DEFB $04                ;
  DEFB $1E                ;
  DEFB $06                ;
  DEFB $46                ;
  DEFB $7E                ;
  DEFB $00                ;
  DEFB $78                ; Character 4
  DEFB $48                ;
  DEFB $48                ;
  DEFB $48                ;
  DEFB $7E                ;
  DEFB $18                ;
  DEFB $18                ;
  DEFB $00                ;
  DEFB $7E                ; Character 5
  DEFB $40                ;
  DEFB $40                ;
  DEFB $7E                ;
  DEFB $06                ;
  DEFB $46                ;
  DEFB $7E                ;
  DEFB $00                ;
  DEFB $7E                ; Character 6
  DEFB $42                ;
  DEFB $40                ;
  DEFB $7E                ;
  DEFB $62                ;
  DEFB $62                ;
  DEFB $7E                ;
  DEFB $00                ;
  DEFB $7E                ; Character 7
  DEFB $02                ;
  DEFB $02                ;
  DEFB $06                ;
  DEFB $06                ;
  DEFB $06                ;
  DEFB $06                ;
  DEFB $00                ;
  DEFB $3C                ; Character 8
  DEFB $24                ;
  DEFB $24                ;
  DEFB $7E                ;
  DEFB $46                ;
  DEFB $46                ;
  DEFB $7E                ;
  DEFB $00                ;
  DEFB $7E                ; Character 9
  DEFB $42                ;
  DEFB $42                ;
  DEFB $7E                ;
  DEFB $06                ;
  DEFB $06                ;
  DEFB $06                ;
  DEFB $00                ;
  DEFB $7E                ; Character $3A
  DEFB $42                ;
  DEFB $42                ;
  DEFB $46                ;
  DEFB $46                ;
  DEFB $46                ;
  DEFB $7E                ;
  DEFB $00                ;
  DEFB $00                ; Character $3B
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $18                ;
  DEFB $18                ;
  DEFB $00                ;
  DEFB $00                ; Character $3C
  DEFB $00                ;
  DEFB $7E                ;
  DEFB $7E                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ; Character $3D
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $3C                ; Character $3E
  DEFB $42                ;
  DEFB $99                ;
  DEFB $A1                ;
  DEFB $A1                ;
  DEFB $99                ;
  DEFB $42                ;
  DEFB $3C                ;
  DEFB $00                ; Character $3F
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ; Character $40
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $3C                ; Character A
  DEFB $24                ;
  DEFB $24                ;
  DEFB $7E                ;
  DEFB $62                ;
  DEFB $62                ;
  DEFB $62                ;
  DEFB $00                ;
  DEFB $7C                ; Character B
  DEFB $44                ;
  DEFB $44                ;
  DEFB $7E                ;
  DEFB $62                ;
  DEFB $62                ;
  DEFB $7E                ;
  DEFB $00                ;
  DEFB $7E                ; Character C
  DEFB $42                ;
  DEFB $40                ;
  DEFB $60                ;
  DEFB $60                ;
  DEFB $62                ;
  DEFB $7E                ;
  DEFB $00                ;
  DEFB $7E                ; Character D
  DEFB $42                ;
  DEFB $42                ;
  DEFB $62                ;
  DEFB $62                ;
  DEFB $62                ;
  DEFB $7E                ;
  DEFB $00                ;
  DEFB $7E                ; Character E
  DEFB $40                ;
  DEFB $40                ;
  DEFB $7E                ;
  DEFB $60                ;
  DEFB $60                ;
  DEFB $7E                ;
  DEFB $00                ;
  DEFB $7E                ; Character F
  DEFB $40                ;
  DEFB $40                ;
  DEFB $7E                ;
  DEFB $60                ;
  DEFB $60                ;
  DEFB $60                ;
  DEFB $00                ;
  DEFB $7E                ; Character G
  DEFB $42                ;
  DEFB $40                ;
  DEFB $66                ;
  DEFB $62                ;
  DEFB $62                ;
  DEFB $7E                ;
  DEFB $00                ;
  DEFB $42                ; Character H
  DEFB $42                ;
  DEFB $42                ;
  DEFB $7E                ;
  DEFB $62                ;
  DEFB $62                ;
  DEFB $62                ;
  DEFB $00                ;
  DEFB $10                ; Character I
  DEFB $10                ;
  DEFB $10                ;
  DEFB $18                ;
  DEFB $18                ;
  DEFB $18                ;
  DEFB $18                ;
  DEFB $00                ;
  DEFB $04                ; Character J
  DEFB $04                ;
  DEFB $04                ;
  DEFB $06                ;
  DEFB $46                ;
  DEFB $46                ;
  DEFB $7E                ;
  DEFB $00                ;
  DEFB $44                ; Character K
  DEFB $44                ;
  DEFB $44                ;
  DEFB $7E                ;
  DEFB $62                ;
  DEFB $62                ;
  DEFB $62                ;
  DEFB $00                ;
  DEFB $40                ; Character L
  DEFB $40                ;
  DEFB $40                ;
  DEFB $60                ;
  DEFB $60                ;
  DEFB $60                ;
  DEFB $7E                ;
  DEFB $00                ;
  DEFB $7E                ; Character M
  DEFB $4A                ;
  DEFB $4A                ;
  DEFB $6A                ;
  DEFB $6A                ;
  DEFB $6A                ;
  DEFB $6A                ;
  DEFB $00                ;
  DEFB $7E                ; Character N
  DEFB $42                ;
  DEFB $42                ;
  DEFB $62                ;
  DEFB $62                ;
  DEFB $62                ;
  DEFB $62                ;
  DEFB $00                ;
  DEFB $7E                ; Character O
  DEFB $46                ;
  DEFB $42                ;
  DEFB $42                ;
  DEFB $42                ;
  DEFB $42                ;
  DEFB $7E                ;
  DEFB $00                ;
  DEFB $7E                ; Character P
  DEFB $42                ;
  DEFB $42                ;
  DEFB $7E                ;
  DEFB $60                ;
  DEFB $60                ;
  DEFB $60                ;
  DEFB $00                ;
  DEFB $7E                ; Character Q
  DEFB $42                ;
  DEFB $42                ;
  DEFB $42                ;
  DEFB $42                ;
  DEFB $4E                ;
  DEFB $7E                ;
  DEFB $00                ;
  DEFB $7C                ; Character R
  DEFB $44                ;
  DEFB $44                ;
  DEFB $7E                ;
  DEFB $62                ;
  DEFB $62                ;
  DEFB $62                ;
  DEFB $00                ;
  DEFB $7E                ; Character S
  DEFB $40                ;
  DEFB $40                ;
  DEFB $7E                ;
  DEFB $06                ;
  DEFB $06                ;
  DEFB $7E                ;
  DEFB $00                ;
  DEFB $7E                ; Character T
  DEFB $10                ;
  DEFB $10                ;
  DEFB $18                ;
  DEFB $18                ;
  DEFB $18                ;
  DEFB $18                ;
  DEFB $00                ;
  DEFB $42                ; Character U
  DEFB $42                ;
  DEFB $42                ;
  DEFB $62                ;
  DEFB $62                ;
  DEFB $62                ;
  DEFB $7E                ;
  DEFB $00                ;
  DEFB $62                ; Character V
  DEFB $62                ;
  DEFB $62                ;
  DEFB $62                ;
  DEFB $24                ;
  DEFB $24                ;
  DEFB $3C                ;
  DEFB $00                ;
  DEFB $4A                ; Character W
  DEFB $4A                ;
  DEFB $4A                ;
  DEFB $6A                ;
  DEFB $6A                ;
  DEFB $6A                ;
  DEFB $7E                ;
  DEFB $00                ;
  DEFB $42                ; Character X
  DEFB $42                ;
  DEFB $42                ;
  DEFB $3C                ;
  DEFB $62                ;
  DEFB $62                ;
  DEFB $62                ;
  DEFB $00                ;
  DEFB $42                ; Character Y
  DEFB $42                ;
  DEFB $42                ;
  DEFB $7E                ;
  DEFB $18                ;
  DEFB $18                ;
  DEFB $18                ;
  DEFB $00                ;
  DEFB $7E                ; Character Z
  DEFB $42                ;
  DEFB $02                ;
  DEFB $7E                ;
  DEFB $60                ;
  DEFB $62                ;
  DEFB $7F                ;
  DEFB $00                ;

; Room sizes
;
; Three entries: the half-size in U, the half-size in V (about the room's
; centre at 128), and the floor's height. Bits 6-7 of a room record's third
; byte pick one, and the builder (BUILD_ROOM) copies it to ROOM_HALF_U.
ROOM_SIZES:
  DEFB $40,$40,$40        ; Size 0: half-sizes 64 in U and 64 in V; floor at 64
  DEFB $20,$40,$40        ; Size 1: half-sizes 32 in U and 64 in V; floor at 64
  DEFB $40,$20,$40        ; Size 2: half-sizes 64 in U and 32 in V; floor at 64

; Room $02 (row 0, column 2): 128 by 128, yellow
;
; 5 backgrounds and 18 objects in 4 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
;
; The room directory: 128 records, one per room, end to end up to OBJECT_TABLE.
; BUILD_ROOM finds a room by stepping from one record to the next until the
; number matches; the rooms are numbered on a 16 by 16 grid, as in Knight Lore.
;
; A record is +0 the room number, +1 the count of bytes from +1 to the end of
; the record, +2 the room's size (bits 6-7, an index into ROOM_SIZES) and its
; colour: bits 3-5 on the tape, copied into bits 0-2 at the start of every game
; (RESET_ROOM_COLOURS) because bits 0-2 are the ink in use, which an activated
; chamber turns white (LOOSE_VALVE). Then the backgrounds, a byte each (an
; index into BACKGROUND_TABLE), up to an $FF; then the objects in groups, a
; header byte (bits 0-2: how many, less one; bits 3-7: the object template,
; OBJECT_TABLE) and a position byte for each: U in bits 0-2, V in bits 3-5, the
; level in bits 6-7. A header with template 0 sets the placement nudge
; (PLACE_NUDGE) from the byte after it, and one with template 31 moves on to
; the second page of templates. Nothing ends a record but the count at +1
; running out, and a group can be cut short by it.
;
; Each room is an entry of its own, laid out from the game's data when the
; disassembly is built.
ROOM02:
  DEFB $02,$20,$30        ; Room $02; 32 bytes from the next; size 0, colour 6
  DEFB $00                ; Background 0
  DEFB $0A                ; Background 10
  DEFB $0C                ; Background 12
  DEFB $04                ; Background 4
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $0F,$40,$88,$78,$B0,$E7,$DF,$E8 ; Object template 1 x8 at (0,0,1),
  DEFB $D0                             ; (0,1,2), (0,7,1), (0,6,2), (7,4,3),
                                       ; (7,3,3), (0,5,3), (0,2,3)
  DEFB $09,$00,$38        ; Object template 1 x2 at (0,0,0), (0,7,0)
  DEFB $00,$30            ; Placement nudge $30 for the objects that follow
  DEFB $0B,$20,$18,$19,$21 ; Object template 1 x4 at (0,4,0), (0,3,0), (1,3,0),
                           ; (1,4,0)
  DEFB $33,$22,$23,$1A,$1B ; Object template 6 x4 at (2,4,0), (3,4,0), (2,3,0),
                           ; (3,3,0)

; Room $03 (row 0, column 3): 128 by 128, green
;
; 6 backgrounds and 12 objects in 2 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM03:
  DEFB $03,$17,$20        ; Room $03; 23 bytes from the next; size 0, colour 4
  DEFB $00                ; Background 0
  DEFB $03                ; Background 3
  DEFB $0A                ; Background 10
  DEFB $0C                ; Background 12
  DEFB $06                ; Background 6
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $5F,$24,$1C,$65,$5D,$A6,$9E,$E7 ; Object template 11 x8 at (4,4,0),
  DEFB $DF                             ; (4,3,0), (5,4,1), (5,3,1), (6,4,2),
                                       ; (6,3,2), (7,4,3), (7,3,3)
  DEFB $3B,$22,$23,$1A,$1B ; Object template 7 x4 at (2,4,0), (3,4,0), (2,3,0),
                           ; (3,3,0)

; Room $04 (row 0, column 4): 128 by 128, cyan
;
; 5 backgrounds and 13 objects in 4 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM04:
  DEFB $04,$19,$28        ; Room $04; 25 bytes from the next; size 0, colour 5
  DEFB $00                ; Background 0
  DEFB $01                ; Background 1
  DEFB $03                ; Background 3
  DEFB $06                ; Background 6
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $0B,$1C,$23,$1A,$13 ; Object template 1 x4 at (4,3,0), (3,4,0), (2,3,0),
                           ; (3,2,0)
  DEFB $38,$1B            ; Object template 7 at (3,3,0)
  DEFB $7B,$63,$5A,$5C,$53 ; Object template 15 x4 at (3,4,1), (2,3,1),
                           ; (4,3,1), (3,2,1)
  DEFB $BB,$12,$14,$22,$24 ; Object template 23 x4 at (2,2,0), (4,2,0),
                           ; (2,4,0), (4,4,0)

; Room $05 (row 0, column 5): 128 by 128, magenta
;
; 4 backgrounds and 14 objects in 3 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM05:
  DEFB $05,$1A,$18        ; Room $05; 26 bytes from the next; size 0, colour 3
  DEFB $00                ; Background 0
  DEFB $03                ; Background 3
  DEFB $06                ; Background 6
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $0F,$22,$24,$12,$14,$63,$5C,$53 ; Object template 1 x8 at (2,4,0),
  DEFB $5A                             ; (4,4,0), (2,2,0), (4,2,0), (3,4,1),
                                       ; (4,3,1), (3,2,1), (2,3,1)
  DEFB $09,$9B,$DB        ; Object template 1 x2 at (3,3,2), (3,3,3)
  DEFB $00,$30            ; Placement nudge $30 for the objects that follow
  DEFB $0B,$1B,$5B,$9B,$1C ; Object template 1 x4 at (3,3,0), (3,3,1), (3,3,2),
                           ; (4,3,0)

; Room $0A (row 0, column 10): 128 by 128, magenta
;
; 4 backgrounds and 18 objects in 6 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM0A:
  DEFB $0A,$21,$18        ; Room $0A; 33 bytes from the next; size 0, colour 3
  DEFB $00                ; Background 0
  DEFB $01                ; Background 1
  DEFB $04                ; Background 4
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $B5,$38,$39,$3A,$3D,$3E,$3F ; Object template 22 x6 at (0,7,0), (1,7,0),
                                   ; (2,7,0), (5,7,0), (6,7,0), (7,7,0)
  DEFB $0F,$23,$24,$1B,$1C,$00,$40,$80 ; Object template 1 x8 at (3,4,0),
  DEFB $C0                             ; (4,4,0), (3,3,0), (4,3,0), (0,0,0),
                                       ; (0,0,1), (0,0,2), (0,0,3)
  DEFB $10,$63            ; Object template 2 at (3,4,1)
  DEFB $18,$A3            ; Object template 3 at (3,4,2)
  DEFB $00,$30            ; Placement nudge $30 for the objects that follow
  DEFB $08,$00            ; Object template 1 at (0,0,0)
  DEFB $D8,$40            ; Object template 27 at (0,0,1)

; Room $0B (row 0, column 11): 128 by 128, cyan
;
; 5 backgrounds and 17 objects in 8 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM0B:
  DEFB $0B,$23,$28        ; Room $0B; 35 bytes from the next; size 0, colour 5
  DEFB $00                ; Background 0
  DEFB $01                ; Background 1
  DEFB $03                ; Background 3
  DEFB $06                ; Background 6
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $BF,$3D,$3E,$3F,$35,$36,$37,$2D ; Object template 23 x8 at (5,7,0),
  DEFB $2E                             ; (6,7,0), (7,7,0), (5,6,0), (6,6,0),
                                       ; (7,6,0), (5,5,0), (6,5,0)
  DEFB $B9,$2F,$BF        ; Object template 23 x2 at (7,5,0), (7,7,2)
  DEFB $F1,$76,$31        ; Object template 30 x2 at (6,6,1), (1,6,0)
  DEFB $F8,$00            ; Switch to the second page of object templates
  DEFB $28,$09            ; Object template 5 at (1,1,0)
  DEFB $08,$08            ; Object template 1 at (0,1,0)
  DEFB $10,$11            ; Object template 2 at (1,2,0)
  DEFB $18,$0A            ; Object template 3 at (2,1,0)
  DEFB $20,$01            ; Object template 4 at (1,0,0)

; Room $0C (row 0, column 12): 128 by 128, green
;
; 5 backgrounds and 23 objects in 6 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM0C:
  DEFB $0C,$27,$20        ; Room $0C; 39 bytes from the next; size 0, colour 4
  DEFB $00                ; Background 0
  DEFB $01                ; Background 1
  DEFB $03                ; Background 3
  DEFB $06                ; Background 6
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $AA,$00,$08,$10    ; Object template 21 x3 at (0,0,0), (0,1,0), (0,2,0)
  DEFB $B2,$3D,$3E,$3F    ; Object template 22 x3 at (5,7,0), (6,7,0), (7,7,0)
  DEFB $BB,$63,$65,$53,$55 ; Object template 23 x4 at (3,4,1), (5,4,1),
                           ; (3,2,1), (5,2,1)
  DEFB $0F,$1D,$1B,$24,$14,$5B,$64,$5D ; Object template 1 x8 at (5,3,0),
  DEFB $54                             ; (3,3,0), (4,4,0), (4,2,0), (3,3,1),
                                       ; (4,4,1), (5,3,1), (4,2,1)
  DEFB $C0,$1C            ; Object template 24 at (4,3,0)
  DEFB $00,$30            ; Placement nudge $30 for the objects that follow
  DEFB $A3,$A4,$94,$9B,$9D ; Object template 20 x4 at (4,4,2), (4,2,2),
                           ; (3,3,2), (5,3,2)

; Room $0D (row 0, column 13): 128 by 128, yellow
;
; 4 backgrounds and 17 objects in 7 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM0D:
  DEFB $0D,$21,$30        ; Room $0D; 33 bytes from the next; size 0, colour 6
  DEFB $00                ; Background 0
  DEFB $03                ; Background 3
  DEFB $06                ; Background 6
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $0A,$5B,$9C,$E4    ; Object template 1 x3 at (3,3,1), (4,3,2), (4,4,3)
  DEFB $4A,$12,$13,$14    ; Object template 9 x3 at (2,2,0), (3,2,0), (4,2,0)
  DEFB $42,$15,$1D,$25    ; Object template 8 x3 at (5,2,0), (5,3,0), (5,4,0)
  DEFB $5A,$2D,$2C,$2B    ; Object template 11 x3 at (5,5,0), (4,5,0), (3,5,0)
  DEFB $52,$2A,$22,$1A    ; Object template 10 x3 at (2,5,0), (2,4,0), (2,3,0)
  DEFB $38,$23            ; Object template 7 at (3,4,0)
  DEFB $00,$30            ; Placement nudge $30 for the objects that follow
  DEFB $08,$23            ; Object template 1 at (3,4,0)

; Room $12 (row 1, column 2): 128 by 128, cyan
;
; 5 backgrounds and 13 objects in 5 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM12:
  DEFB $12,$1C,$28        ; Room $12; 28 bytes from the next; size 0, colour 5
  DEFB $01                ; Background 1
  DEFB $0B                ; Background 11
  DEFB $0D                ; Background 13
  DEFB $04                ; Background 4
  DEFB $05                ; Background 5
  DEFB $FF                ; End of the backgrounds
  DEFB $09,$C3,$C4        ; Object template 1 x2 at (3,0,3), (4,0,3)
  DEFB $38,$00            ; Object template 7 at (0,0,0)
  DEFB $2A,$3A,$79,$B8    ; Object template 5 x3 at (2,7,0), (1,7,1), (0,7,2)
  DEFB $54,$F0,$E8,$E0,$D8,$D0 ; Object template 10 x5 at (0,6,3), (0,5,3),
                               ; (0,4,3), (0,3,3), (0,2,3)
  DEFB $00,$30            ; Placement nudge $30 for the objects that follow
  DEFB $31,$00,$40        ; Object template 6 x2 at (0,0,0), (0,0,1)

; Room $13 (row 1, column 3): 128 by 128, magenta
;
; 6 backgrounds and 20 objects in 3 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM13:
  DEFB $13,$20,$18        ; Room $13; 32 bytes from the next; size 0, colour 3
  DEFB $00                ; Background 0
  DEFB $01                ; Background 1
  DEFB $02                ; Background 2
  DEFB $03                ; Background 3
  DEFB $06                ; Background 6
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $BF,$3A,$32,$2A,$29,$28,$10,$11 ; Object template 23 x8 at (2,7,0),
  DEFB $12                             ; (2,6,0), (2,5,0), (1,5,0), (0,5,0),
                                       ; (0,2,0), (1,2,0), (2,2,0)
  DEFB $BF,$0A,$02,$3D,$35,$2D,$2E,$2F ; Object template 23 x8 at (2,1,0),
  DEFB $17                             ; (2,0,0), (5,7,0), (5,6,0), (5,5,0),
                                       ; (6,5,0), (7,5,0), (7,2,0)
  DEFB $BB,$16,$15,$0D,$05 ; Object template 23 x4 at (6,2,0), (5,2,0),
                           ; (5,1,0), (5,0,0)

; Room $14 (row 1, column 4): 128 by 128, yellow
;
; 6 backgrounds and 24 objects in 4 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM14:
  DEFB $14,$25,$30        ; Room $14; 37 bytes from the next; size 0, colour 6
  DEFB $00                ; Background 0
  DEFB $01                ; Background 1
  DEFB $02                ; Background 2
  DEFB $03                ; Background 3
  DEFB $06                ; Background 6
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $0F,$2F,$2E,$26,$1E,$16,$17,$28 ; Object template 1 x8 at (7,5,0),
  DEFB $29                             ; (6,5,0), (6,4,0), (6,3,0), (6,2,0),
                                       ; (7,2,0), (0,5,0), (1,5,0)
  DEFB $0B,$21,$19,$11,$10 ; Object template 1 x4 at (1,4,0), (1,3,0), (1,2,0),
                           ; (0,2,0)
  DEFB $7F,$68,$69,$61,$59,$51,$50,$57 ; Object template 15 x8 at (0,5,1),
  DEFB $56                             ; (1,5,1), (1,4,1), (1,3,1), (1,2,1),
                                       ; (0,2,1), (7,2,1), (6,2,1)
  DEFB $7B,$5E,$66,$6E,$6F ; Object template 15 x4 at (6,3,1), (6,4,1),
                           ; (6,5,1), (7,5,1)

; Room $15 (row 1, column 5): 128 by 128, cyan
;
; 4 backgrounds and 18 objects in 3 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM15:
  DEFB $15,$1C,$28        ; Room $15; 28 bytes from the next; size 0, colour 5
  DEFB $02                ; Background 2
  DEFB $03                ; Background 3
  DEFB $05                ; Background 5
  DEFB $06                ; Background 6
  DEFB $FF                ; End of the backgrounds
  DEFB $37,$3C,$74,$27,$66,$0C,$54,$21 ; Object template 6 x8 at (4,7,0),
  DEFB $62                             ; (4,6,1), (7,4,0), (6,4,1), (4,1,0),
                                       ; (4,2,1), (1,4,0), (2,4,1)
  DEFB $34,$AC,$A5,$A3,$9C,$E4 ; Object template 6 x5 at (4,5,2), (5,4,2),
                               ; (3,4,2), (4,3,2), (4,4,3)
  DEFB $3C,$23,$2C,$25,$1C,$24 ; Object template 7 x5 at (3,4,0), (4,5,0),
                               ; (5,4,0), (4,3,0), (4,4,0)

; Room $1A (row 1, column 10): 128 by 128, cyan
;
; 6 backgrounds and 16 objects in 3 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM1A:
  DEFB $1A,$1C,$28        ; Room $1A; 28 bytes from the next; size 0, colour 5
  DEFB $0A                ; Background 10
  DEFB $0B                ; Background 11
  DEFB $0C                ; Background 12
  DEFB $0D                ; Background 13
  DEFB $04                ; Background 4
  DEFB $05                ; Background 5
  DEFB $FF                ; End of the backgrounds
  DEFB $3B,$23,$24,$1C,$1B ; Object template 7 x4 at (3,4,0), (4,4,0), (4,3,0),
                           ; (3,3,0)
  DEFB $45,$C3,$C4,$8B,$8C,$53,$54 ; Object template 8 x6 at (3,0,3), (4,0,3),
                                   ; (3,1,2), (4,1,2), (3,2,1), (4,2,1)
  DEFB $5D,$DF,$E7,$9E,$A6,$5D,$65 ; Object template 11 x6 at (7,3,3), (7,4,3),
                                   ; (6,3,2), (6,4,2), (5,3,1), (5,4,1)

; Room $1B (row 1, column 11): 128 by 128, yellow
;
; 6 backgrounds and 12 objects in 3 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM1B:
  DEFB $1B,$1A,$30        ; Room $1B; 26 bytes from the next; size 0, colour 6
  DEFB $00                ; Background 0
  DEFB $01                ; Background 1
  DEFB $02                ; Background 2
  DEFB $03                ; Background 3
  DEFB $06                ; Background 6
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $34,$55,$95,$94,$D4,$DC ; Object template 6 x5 at (5,2,1), (5,2,2),
                               ; (4,2,2), (4,2,3), (4,3,3)
  DEFB $BB,$1C,$1D,$14,$15 ; Object template 23 x4 at (4,3,0), (5,3,0),
                           ; (4,2,0), (5,2,0)
  DEFB $00,$30            ; Placement nudge $30 for the objects that follow
  DEFB $32,$1C,$1D,$5D    ; Object template 6 x3 at (4,3,0), (5,3,0), (5,3,1)

; Room $1C (row 1, column 12): 128 by 128, magenta
;
; 6 backgrounds and 19 objects in 5 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM1C:
  DEFB $1C,$21,$18        ; Room $1C; 33 bytes from the next; size 0, colour 3
  DEFB $00                ; Background 0
  DEFB $01                ; Background 1
  DEFB $02                ; Background 2
  DEFB $03                ; Background 3
  DEFB $06                ; Background 6
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $0F,$23,$63,$25,$65,$13,$53,$15 ; Object template 1 x8 at (3,4,0),
  DEFB $55                             ; (3,4,1), (5,4,0), (5,4,1), (3,2,0),
                                       ; (3,2,1), (5,2,0), (5,2,1)
  DEFB $0F,$A4,$E4,$9D,$DD,$94,$D4,$9B ; Object template 1 x8 at (4,4,2),
  DEFB $DB                             ; (4,4,3), (5,3,2), (5,3,3), (4,2,2),
                                       ; (4,2,3), (3,3,2), (3,3,3)
  DEFB $10,$1C            ; Object template 2 at (4,3,0)
  DEFB $18,$5C            ; Object template 3 at (4,3,1)
  DEFB $A0,$DC            ; Object template 20 at (4,3,3)

; Room $1D (row 1, column 13): 128 by 128, cyan
;
; 4 backgrounds and 27 objects in 7 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM1D:
  DEFB $1D,$2B,$28        ; Room $1D; 43 bytes from the next; size 0, colour 5
  DEFB $02                ; Background 2
  DEFB $03                ; Background 3
  DEFB $05                ; Background 5
  DEFB $06                ; Background 6
  DEFB $FF                ; End of the backgrounds
  DEFB $AA,$00,$08,$10    ; Object template 21 x3 at (0,0,0), (0,1,0), (0,2,0)
  DEFB $0B,$FF,$06,$0E,$0F ; Object template 1 x4 at (7,7,3), (6,0,0), (6,1,0),
                           ; (7,1,0)
  DEFB $20,$F8            ; Object template 4 at (0,7,3)
  DEFB $3F,$30,$31,$39,$FE,$F7,$46,$4F ; Object template 7 x8 at (0,6,0),
  DEFB $4E                             ; (1,6,0), (1,7,0), (6,7,3), (7,6,3),
                                       ; (6,0,1), (7,1,1), (6,1,1)
  DEFB $57,$F9,$FA,$FB,$FC,$FD,$EF,$E7 ; Object template 10 x8 at (1,7,3),
  DEFB $DF                             ; (2,7,3), (3,7,3), (4,7,3), (5,7,3),
                                       ; (7,5,3), (7,4,3), (7,3,3)
  DEFB $51,$D7,$CF        ; Object template 10 x2 at (7,2,3), (7,1,3)
  DEFB $00,$30            ; Placement nudge $30 for the objects that follow
  DEFB $D0,$3F            ; Object template 26 at (7,7,0)

; Room $20 (row 2, column 0): 128 by 128, cyan
;
; 3 backgrounds and 15 objects in 5 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM20:
  DEFB $20,$1A,$28        ; Room $20; 26 bytes from the next; size 0, colour 5
  DEFB $00                ; Background 0
  DEFB $04                ; Background 4
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $0F,$1A,$5A,$9A,$DA,$1D,$5D,$9D ; Object template 1 x8 at (2,3,0),
  DEFB $DD                             ; (2,3,1), (2,3,2), (2,3,3), (5,3,0),
                                       ; (5,3,1), (5,3,2), (5,3,3)
  DEFB $09,$00,$07        ; Object template 1 x2 at (0,0,0), (7,0,0)
  DEFB $39,$1B,$1C        ; Object template 7 x2 at (3,3,0), (4,3,0)
  DEFB $31,$DB,$DC        ; Object template 6 x2 at (3,3,3), (4,3,3)
  DEFB $80,$40            ; Object template 16 at (0,0,1)

; Room $23 (row 2, column 3): 64 by 128, yellow
;
; 3 backgrounds and 24 objects in 5 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM23:
  DEFB $23,$23,$70        ; Room $23; 35 bytes from the next; size 1, colour 6
  DEFB $00                ; Background 0
  DEFB $02                ; Background 2
  DEFB $08                ; Background 8
  DEFB $FF                ; End of the backgrounds
  DEFB $0F,$22,$23,$24,$25,$1A,$1B,$1C ; Object template 1 x8 at (2,4,0),
  DEFB $1D                             ; (3,4,0), (4,4,0), (5,4,0), (2,3,0),
                                       ; (3,3,0), (4,3,0), (5,3,0)
  DEFB $52,$2B,$2C,$2D    ; Object template 10 x3 at (3,5,0), (4,5,0), (5,5,0)
  DEFB $42,$13,$14,$15    ; Object template 8 x3 at (3,2,0), (4,2,0), (5,2,0)
  DEFB $61,$2A,$12        ; Object template 12 x2 at (2,5,0), (2,2,0)
  DEFB $7F,$62,$63,$64,$65,$5A,$5B,$5C ; Object template 15 x8 at (2,4,1),
  DEFB $5D                             ; (3,4,1), (4,4,1), (5,4,1), (2,3,1),
                                       ; (3,3,1), (4,3,1), (5,3,1)

; Room $24 (row 2, column 4): 64 by 128, green
;
; 3 backgrounds and 8 objects in 1 group. Positions are cells (U, V, level): U
; and V 0-7, sixteen units a cell from 72; each level twelve units up from the
; floor.
ROOM24:
  DEFB $24,$0F,$60        ; Room $24; 15 bytes from the next; size 1, colour 4
  DEFB $00                ; Background 0
  DEFB $02                ; Background 2
  DEFB $08                ; Background 8
  DEFB $FF                ; End of the backgrounds
  DEFB $7F,$35,$2C,$2B,$22,$0A,$13,$14 ; Object template 15 x8 at (5,6,0),
  DEFB $1D                             ; (4,5,0), (3,5,0), (2,4,0), (2,1,0),
                                       ; (3,2,0), (4,2,0), (5,3,0)

; Room $27 (row 2, column 7): 128 by 128, yellow
;
; 4 backgrounds and 20 objects in 5 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM27:
  DEFB $27,$22,$30        ; Room $27; 34 bytes from the next; size 0, colour 6
  DEFB $00                ; Background 0
  DEFB $01                ; Background 1
  DEFB $04                ; Background 4
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $0F,$00,$08,$48,$10,$50,$90,$18 ; Object template 1 x8 at (0,0,0),
  DEFB $58                             ; (0,1,0), (0,1,1), (0,2,0), (0,2,1),
                                       ; (0,2,2), (0,3,0), (0,3,1)
  DEFB $09,$21,$61        ; Object template 1 x2 at (1,4,0), (1,4,1)
  DEFB $35,$D8,$A0,$28,$68,$A8,$E8 ; Object template 6 x6 at (0,3,3), (0,4,2),
                                   ; (0,5,0), (0,5,1), (0,5,2), (0,5,3)
  DEFB $39,$98,$A1        ; Object template 7 x2 at (0,3,2), (1,4,2)
  DEFB $00,$30            ; Placement nudge $30 for the objects that follow
  DEFB $31,$28,$68        ; Object template 6 x2 at (0,5,0), (0,5,1)

; Room $28 (row 2, column 8): 128 by 128, yellow
;
; 4 backgrounds and 29 objects in 7 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM28:
  DEFB $28,$2D,$30        ; Room $28; 45 bytes from the next; size 0, colour 6
  DEFB $00                ; Background 0
  DEFB $03                ; Background 3
  DEFB $06                ; Background 6
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $A9,$00,$08        ; Object template 21 x2 at (0,0,0), (0,1,0)
  DEFB $0F,$46,$47,$06,$07,$86,$87,$C6 ; Object template 1 x8 at (6,0,1),
  DEFB $C7                             ; (7,0,1), (6,0,0), (7,0,0), (6,0,2),
                                       ; (7,0,2), (6,0,3), (7,0,3)
  DEFB $0F,$1E,$1F,$5E,$5F,$9E,$9F,$DE ; Object template 1 x8 at (6,3,0),
  DEFB $DF                             ; (7,3,0), (6,3,1), (7,3,1), (6,3,2),
                                       ; (7,3,2), (6,3,3), (7,3,3)
  DEFB $0C,$1D,$5D,$9D,$DD,$D5 ; Object template 1 x5 at (5,3,0), (5,3,1),
                               ; (5,3,2), (5,3,3), (5,2,3)
  DEFB $C0,$17            ; Object template 24 at (7,2,0)
  DEFB $10,$31            ; Object template 2 at (1,6,0)
  DEFB $00,$30            ; Placement nudge $30 for the objects that follow
  DEFB $0B,$16,$17,$0E,$0F ; Object template 1 x4 at (6,2,0), (7,2,0), (6,1,0),
                           ; (7,1,0)

; Room $2B (row 2, column 11): 64 by 128, green
;
; 3 backgrounds and 0 objects in 0 groups. Positions are cells (U, V, level): U
; and V 0-7, sixteen units a cell from 72; each level twelve units up from the
; floor.
ROOM2B:
  DEFB $2B,$05,$60        ; Room $2B; 5 bytes from the next; size 1, colour 4
  DEFB $00                ; Background 0
  DEFB $02                ; Background 2
  DEFB $08                ; Background 8

; Room $2C (row 2, column 12): 64 by 128, yellow
;
; 3 backgrounds and 0 objects in 0 groups. Positions are cells (U, V, level): U
; and V 0-7, sixteen units a cell from 72; each level twelve units up from the
; floor.
ROOM2C:
  DEFB $2C,$05,$70        ; Room $2C; 5 bytes from the next; size 1, colour 6
  DEFB $00                ; Background 0
  DEFB $02                ; Background 2
  DEFB $08                ; Background 8

; Room $2F (row 2, column 15): 128 by 128, cyan
;
; 3 backgrounds and 23 objects in 5 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM2F:
  DEFB $2F,$22,$28        ; Room $2F; 34 bytes from the next; size 0, colour 5
  DEFB $00                ; Background 0
  DEFB $04                ; Background 4
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $0B,$1A,$5A,$9A,$9D ; Object template 1 x4 at (2,3,0), (2,3,1), (2,3,2),
                           ; (5,3,2)
  DEFB $0F,$5D,$1D,$1B,$1C,$28,$08,$0F ; Object template 1 x8 at (5,3,1),
  DEFB $2F                             ; (5,3,0), (3,3,0), (4,3,0), (0,5,0),
                                       ; (0,1,0), (7,1,0), (7,5,0)
  DEFB $33,$9E,$9F,$98,$99 ; Object template 6 x4 at (6,3,2), (7,3,2), (0,3,2),
                           ; (1,3,2)
  DEFB $7D,$68,$48,$4F,$6F,$5B,$5C ; Object template 15 x6 at (0,5,1), (0,1,1),
                                   ; (7,1,1), (7,5,1), (3,3,1), (4,3,1)
  DEFB $88,$50            ; Object template 17 at (0,2,1)

; Room $30 (row 3, column 0): 128 by 128, magenta
;
; 5 backgrounds and 11 objects in 3 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM30:
  DEFB $30,$16,$18        ; Room $30; 22 bytes from the next; size 0, colour 3
  DEFB $00                ; Background 0
  DEFB $01                ; Background 1
  DEFB $02                ; Background 2
  DEFB $04                ; Background 4
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $0E,$00,$40,$F8,$20,$18,$60,$58 ; Object template 1 x7 at (0,0,0),
                                       ; (0,0,1), (0,7,3), (0,4,0), (0,3,0),
                                       ; (0,4,1), (0,3,1)
  DEFB $71,$E8,$C8        ; Object template 14 x2 at (0,5,3), (0,1,3)
  DEFB $79,$A0,$98        ; Object template 15 x2 at (0,4,2), (0,3,2)

; Room $31 (row 3, column 1): 128 by 128, green
;
; 4 backgrounds and 22 objects in 5 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM31:
  DEFB $31,$22,$20        ; Room $31; 34 bytes from the next; size 0, colour 4
  DEFB $00                ; Background 0
  DEFB $03                ; Background 3
  DEFB $06                ; Background 6
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $B5,$38,$39,$3A,$3D,$3E,$3F ; Object template 22 x6 at (0,7,0), (1,7,0),
                                   ; (2,7,0), (5,7,0), (6,7,0), (7,7,0)
  DEFB $0A,$1C,$5C,$9C    ; Object template 1 x3 at (4,3,0), (4,3,1), (4,3,2)
  DEFB $33,$64,$5D,$54,$5B ; Object template 6 x4 at (4,4,1), (5,3,1), (4,2,1),
                           ; (3,3,1)
  DEFB $BF,$23,$24,$25,$1B,$1D,$13,$14 ; Object template 23 x8 at (3,4,0),
  DEFB $15                             ; (4,4,0), (5,4,0), (3,3,0), (5,3,0),
                                       ; (3,2,0), (4,2,0), (5,2,0)
  DEFB $D0,$DC            ; Object template 26 at (4,3,3)

; Room $33 (row 3, column 3): 64 by 128, cyan
;
; 3 backgrounds and 12 objects in 2 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM33:
  DEFB $33,$14,$68        ; Room $33; 20 bytes from the next; size 1, colour 5
  DEFB $00                ; Background 0
  DEFB $02                ; Background 2
  DEFB $08                ; Background 8
  DEFB $FF                ; End of the backgrounds
  DEFB $0F,$1A,$1B,$1C,$1D,$5A,$5D,$9A ; Object template 1 x8 at (2,3,0),
  DEFB $9D                             ; (3,3,0), (4,3,0), (5,3,0), (2,3,1),
                                       ; (5,3,1), (2,3,2), (5,3,2)
  DEFB $7B,$DA,$DD,$5B,$5C ; Object template 15 x4 at (2,3,3), (5,3,3),
                           ; (3,3,1), (4,3,1)

; Room $34 (row 3, column 4): 64 by 128, magenta
;
; 3 backgrounds and 24 objects in 5 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM34:
  DEFB $34,$25,$58        ; Room $34; 37 bytes from the next; size 1, colour 3
  DEFB $00                ; Background 0
  DEFB $02                ; Background 2
  DEFB $08                ; Background 8
  DEFB $FF                ; End of the backgrounds
  DEFB $0F,$3A,$7A,$22,$1A,$5A,$12,$52 ; Object template 1 x8 at (2,7,0),
  DEFB $92                             ; (2,7,1), (2,4,0), (2,3,0), (2,3,1),
                                       ; (2,2,0), (2,2,1), (2,2,2)
  DEFB $0C,$0A,$33,$4A,$BA,$2B ; Object template 1 x5 at (2,1,0), (3,6,0),
                               ; (2,1,1), (2,7,2), (3,5,0)
  DEFB $63,$2A,$62,$9A,$D2 ; Object template 12 x4 at (2,5,0), (2,4,1),
                           ; (2,3,2), (2,2,3)
  DEFB $7A,$FA,$73,$6B    ; Object template 15 x3 at (2,7,3), (3,6,1), (3,5,1)
  DEFB $00,$30            ; Placement nudge $30 for the objects that follow
  DEFB $7B,$32,$6A,$A2,$DA ; Object template 15 x4 at (2,6,0), (2,5,1),
                           ; (2,4,2), (2,3,3)

; Room $36 (row 3, column 6): 128 by 128, green
;
; 4 backgrounds and 22 objects in 5 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM36:
  DEFB $36,$22,$20        ; Room $36; 34 bytes from the next; size 0, colour 4
  DEFB $00                ; Background 0
  DEFB $01                ; Background 1
  DEFB $04                ; Background 4
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $0F,$3D,$35,$2D,$25,$1D,$5D,$1A ; Object template 1 x8 at (5,7,0),
  DEFB $5A                             ; (5,6,0), (5,5,0), (5,4,0), (5,3,0),
                                       ; (5,3,1), (2,3,0), (2,3,1)
  DEFB $09,$18,$19        ; Object template 1 x2 at (0,3,0), (1,3,0)
  DEFB $21,$DC,$5B        ; Object template 4 x2 at (4,3,3), (3,3,1)
  DEFB $B9,$1B,$1C        ; Object template 23 x2 at (3,3,0), (4,3,0)
  DEFB $7F,$7D,$75,$6D,$65,$9D,$9A,$58 ; Object template 15 x8 at (5,7,1),
  DEFB $59                             ; (5,6,1), (5,5,1), (5,4,1), (5,3,2),
                                       ; (2,3,2), (0,3,1), (1,3,1)

; Room $37 (row 3, column 7): 128 by 128, cyan
;
; 5 backgrounds and 15 objects in 4 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM37:
  DEFB $37,$1D,$28        ; Room $37; 29 bytes from the next; size 0, colour 5
  DEFB $00                ; Background 0
  DEFB $02                ; Background 2
  DEFB $03                ; Background 3
  DEFB $06                ; Background 6
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $0F,$0F,$06,$46,$0E,$2F,$67,$9F ; Object template 1 x8 at (7,1,0),
  DEFB $D7                             ; (6,0,0), (6,0,1), (6,1,0), (7,5,0),
                                       ; (7,4,1), (7,3,2), (7,2,3)
  DEFB $BC,$17,$07,$16,$4E,$86 ; Object template 23 x5 at (7,2,0), (7,0,0),
                               ; (6,2,0), (6,1,1), (6,0,2)
  DEFB $00,$30            ; Placement nudge $30 for the objects that follow
  DEFB $08,$0F            ; Object template 1 at (7,1,0)
  DEFB $18,$4F            ; Object template 3 at (7,1,1)

; Room $38 (row 3, column 8): 128 by 128, cyan
;
; 5 backgrounds and 24 objects in 4 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM38:
  DEFB $38,$24,$28        ; Room $38; 36 bytes from the next; size 0, colour 5
  DEFB $00                ; Background 0
  DEFB $01                ; Background 1
  DEFB $02                ; Background 2
  DEFB $04                ; Background 4
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $0F,$05,$0D,$15,$1C,$23,$2A,$32 ; Object template 1 x8 at (5,0,0),
  DEFB $38                             ; (5,1,0), (5,2,0), (4,3,0), (3,4,0),
                                       ; (2,5,0), (2,6,0), (0,7,0)
  DEFB $0B,$02,$0B,$12,$19 ; Object template 1 x4 at (2,0,0), (3,1,0), (2,2,0),
                           ; (1,3,0)
  DEFB $7F,$45,$4D,$55,$5C,$63,$6A,$72 ; Object template 15 x8 at (5,0,1),
  DEFB $78                             ; (5,1,1), (5,2,1), (4,3,1), (3,4,1),
                                       ; (2,5,1), (2,6,1), (0,7,1)
  DEFB $7B,$42,$4B,$52,$59 ; Object template 15 x4 at (2,0,1), (3,1,1),
                           ; (2,2,1), (1,3,1)

; Room $39 (row 3, column 9): 128 by 128, green
;
; 4 backgrounds and 9 objects in 3 groups. Positions are cells (U, V, level): U
; and V 0-7, sixteen units a cell from 72; each level twelve units up from the
; floor.
ROOM39:
  DEFB $39,$15,$20        ; Room $39; 21 bytes from the next; size 0, colour 4
  DEFB $00                ; Background 0
  DEFB $03                ; Background 3
  DEFB $06                ; Background 6
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $0E,$07,$1F,$57,$8F,$04,$45,$86 ; Object template 1 x7 at (7,0,0),
                                       ; (7,3,0), (7,2,1), (7,1,2), (4,0,0),
                                       ; (5,0,1), (6,0,2)
  DEFB $38,$47            ; Object template 7 at (7,0,1)
  DEFB $00,$30            ; Placement nudge $30 for the objects that follow
  DEFB $20,$C7            ; Object template 4 at (7,0,3)

; Room $3B (row 3, column 11): 64 by 128, magenta
;
; 4 backgrounds and 26 objects in 6 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM3B:
  DEFB $3B,$27,$58        ; Room $3B; 39 bytes from the next; size 1, colour 3
  DEFB $00                ; Background 0
  DEFB $0B                ; Background 11
  DEFB $0D                ; Background 13
  DEFB $08                ; Background 8
  DEFB $FF                ; End of the backgrounds
  DEFB $0F,$23,$24,$63,$64,$A3,$A4,$E3 ; Object template 1 x8 at (3,4,0),
  DEFB $E4                             ; (4,4,0), (3,4,1), (4,4,1), (3,4,2),
                                       ; (4,4,2), (3,4,3), (4,4,3)
  DEFB $09,$2B,$2C        ; Object template 1 x2 at (3,5,0), (4,5,0)
  DEFB $4A,$C4,$CC,$D4    ; Object template 9 x3 at (4,0,3), (4,1,3), (4,2,3)
  DEFB $5A,$C3,$CB,$D3    ; Object template 11 x3 at (3,0,3), (3,1,3), (3,2,3)
  DEFB $31,$DB,$DC        ; Object template 6 x2 at (3,3,3), (4,3,3)
  DEFB $7F,$02,$0A,$12,$1A,$05,$0D,$15 ; Object template 15 x8 at (2,0,0),
  DEFB $1D                             ; (2,1,0), (2,2,0), (2,3,0), (5,0,0),
                                       ; (5,1,0), (5,2,0), (5,3,0)

; Room $3C (row 3, column 12): 64 by 128, cyan
;
; 3 backgrounds and 3 objects in 2 groups. Positions are cells (U, V, level): U
; and V 0-7, sixteen units a cell from 72; each level twelve units up from the
; floor.
ROOM3C:
  DEFB $3C,$0B,$68        ; Room $3C; 11 bytes from the next; size 1, colour 5
  DEFB $00                ; Background 0
  DEFB $02                ; Background 2
  DEFB $08                ; Background 8
  DEFB $FF                ; End of the backgrounds
  DEFB $69,$2B,$13        ; Object template 13 x2 at (3,5,0), (3,2,0)
  DEFB $80,$23            ; Object template 16 at (3,4,0)

; Room $3E (row 3, column 14): 128 by 128, green
;
; 4 backgrounds and 29 objects in 4 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM3E:
  DEFB $3E,$2A,$20        ; Room $3E; 42 bytes from the next; size 0, colour 4
  DEFB $00                ; Background 0
  DEFB $01                ; Background 1
  DEFB $04                ; Background 4
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $37,$54,$55,$95,$5D,$9D,$DD,$65 ; Object template 6 x8 at (4,2,1),
  DEFB $A5                             ; (5,2,1), (5,2,2), (5,3,1), (5,3,2),
                                       ; (5,3,3), (5,4,1), (5,4,2)
  DEFB $36,$E5,$64,$A4,$E4,$63,$A3,$E3 ; Object template 6 x7 at (5,4,3),
                                       ; (4,4,1), (4,4,2), (4,4,3), (3,4,1),
                                       ; (3,4,2), (3,4,3)
  DEFB $3F,$23,$24,$25,$1B,$1D,$13,$14 ; Object template 7 x8 at (3,4,0),
  DEFB $15                             ; (4,4,0), (5,4,0), (3,3,0), (5,3,0),
                                       ; (3,2,0), (4,2,0), (5,2,0)
  DEFB $00,$30            ; Placement nudge $30 for the objects that follow
  DEFB $35,$25,$24,$64,$23,$63,$A3 ; Object template 6 x6 at (5,4,0), (4,4,0),
                                   ; (4,4,1), (3,4,0), (3,4,1), (3,4,2)

; Room $3F (row 3, column 15): 128 by 128, magenta
;
; 6 backgrounds and 19 objects in 4 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM3F:
  DEFB $3F,$22,$18        ; Room $3F; 34 bytes from the next; size 0, colour 3
  DEFB $00                ; Background 0
  DEFB $0B                ; Background 11
  DEFB $0D                ; Background 13
  DEFB $03                ; Background 3
  DEFB $06                ; Background 6
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $0F,$E3,$E4,$DB,$DC,$DD,$95,$4D ; Object template 1 x8 at (3,4,3),
  DEFB $05                             ; (4,4,3), (3,3,3), (4,3,3), (5,3,3),
                                       ; (5,2,2), (5,1,1), (5,0,0)
  DEFB $09,$C3,$C4        ; Object template 1 x2 at (3,0,3), (4,0,3)
  DEFB $00,$30            ; Placement nudge $30 for the objects that follow
  DEFB $37,$13,$14,$1A,$22,$1D,$25,$2B ; Object template 6 x8 at (3,2,0),
  DEFB $2C                             ; (4,2,0), (2,3,0), (2,4,0), (5,3,0),
                                       ; (5,4,0), (3,5,0), (4,5,0)
  DEFB $E0,$63            ; Object template 28 at (3,4,1)

; Room $40 (row 4, column 0): 128 by 128, yellow
;
; 5 backgrounds and 15 objects in 4 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM40:
  DEFB $40,$1B,$30        ; Room $40; 27 bytes from the next; size 0, colour 6
  DEFB $0A                ; Background 10
  DEFB $02                ; Background 2
  DEFB $0C                ; Background 12
  DEFB $04                ; Background 4
  DEFB $05                ; Background 5
  DEFB $FF                ; End of the backgrounds
  DEFB $0D,$20,$68,$B0,$FF,$E7,$DF ; Object template 1 x6 at (0,4,0), (0,5,1),
                                   ; (0,6,2), (7,7,3), (7,4,3), (7,3,3)
  DEFB $4A,$F8,$F9,$FA    ; Object template 9 x3 at (0,7,3), (1,7,3), (2,7,3)
  DEFB $31,$FB,$FC        ; Object template 6 x2 at (3,7,3), (4,7,3)
  DEFB $3B,$3F,$3E,$3D,$3B ; Object template 7 x4 at (7,7,0), (6,7,0), (5,7,0),
                           ; (3,7,0)

; Room $41 (row 4, column 1): 128 by 128, cyan
;
; 6 backgrounds and 21 objects in 8 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM41:
  DEFB $41,$28,$28        ; Room $41; 40 bytes from the next; size 0, colour 5
  DEFB $00                ; Background 0
  DEFB $01                ; Background 1
  DEFB $02                ; Background 2
  DEFB $03                ; Background 3
  DEFB $06                ; Background 6
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $AA,$00,$08,$10    ; Object template 21 x3 at (0,0,0), (0,1,0), (0,2,0)
  DEFB $B2,$3D,$3E,$3F    ; Object template 22 x3 at (5,7,0), (6,7,0), (7,7,0)
  DEFB $0B,$23,$63,$A3,$E3 ; Object template 1 x4 at (3,4,0), (3,4,1), (3,4,2),
                           ; (3,4,3)
  DEFB $12,$12,$2D,$92    ; Object template 2 x3 at (2,2,0), (5,5,0), (2,2,2)
  DEFB $1A,$52,$6D,$D2    ; Object template 3 x3 at (2,2,1), (5,5,1), (2,2,3)
  DEFB $BA,$06,$07,$0F    ; Object template 23 x3 at (6,0,0), (7,0,0), (7,1,0)
  DEFB $00,$30            ; Placement nudge $30 for the objects that follow
  DEFB $08,$23            ; Object template 1 at (3,4,0)
  DEFB $C8,$63            ; Object template 25 at (3,4,1)

; Room $42 (row 4, column 2): 128 by 64, magenta
;
; 3 backgrounds and 13 objects in 3 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM42:
  DEFB $42,$16,$98        ; Room $42; 22 bytes from the next; size 2, colour 3
  DEFB $01                ; Background 1
  DEFB $03                ; Background 3
  DEFB $09                ; Background 9
  DEFB $FF                ; End of the backgrounds
  DEFB $0B,$2A,$2D,$12,$15 ; Object template 1 x4 at (2,5,0), (5,5,0), (2,2,0),
                           ; (5,2,0)
  DEFB $BF,$6D,$65,$5D,$55,$6A,$62,$5A ; Object template 23 x8 at (5,5,1),
  DEFB $52                             ; (5,4,1), (5,3,1), (5,2,1), (2,5,1),
                                       ; (2,4,1), (2,3,1), (2,2,1)
  DEFB $E0,$23            ; Object template 28 at (3,4,0)

; Room $43 (row 4, column 3): 128 by 128, green
;
; 5 backgrounds and 26 objects in 7 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM43:
  DEFB $43,$29,$20        ; Room $43; 41 bytes from the next; size 0, colour 4
  DEFB $0B                ; Background 11
  DEFB $0D                ; Background 13
  DEFB $03                ; Background 3
  DEFB $05                ; Background 5
  DEFB $06                ; Background 6
  DEFB $FF                ; End of the backgrounds
  DEFB $0F,$C3,$C4,$23,$24,$63,$64,$A3 ; Object template 1 x8 at (3,0,3),
  DEFB $A4                             ; (4,0,3), (3,4,0), (4,4,0), (3,4,1),
                                       ; (4,4,1), (3,4,2), (4,4,2)
  DEFB $09,$25,$22        ; Object template 1 x2 at (5,4,0), (2,4,0)
  DEFB $61,$2B,$2C        ; Object template 12 x2 at (3,5,0), (4,5,0)
  DEFB $7F,$62,$65,$1B,$1C,$13,$14,$0B ; Object template 15 x8 at (2,4,1),
  DEFB $0C                             ; (5,4,1), (3,3,0), (4,3,0), (3,2,0),
                                       ; (4,2,0), (3,1,0), (4,1,0)
  DEFB $49,$DC,$D4        ; Object template 9 x2 at (4,3,3), (4,2,3)
  DEFB $59,$DB,$D3        ; Object template 11 x2 at (3,3,3), (3,2,3)
  DEFB $31,$CB,$CC        ; Object template 6 x2 at (3,1,3), (4,1,3)

; Room $44 (row 4, column 4): 128 by 128, yellow
;
; 5 backgrounds and 28 objects in 11 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM44:
  DEFB $44,$35,$30        ; Room $44; 53 bytes from the next; size 0, colour 6
  DEFB $00                ; Background 0
  DEFB $01                ; Background 1
  DEFB $02                ; Background 2
  DEFB $04                ; Background 4
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $37,$62,$A2,$E2,$5B,$9B,$DB,$52 ; Object template 6 x8 at (2,4,1),
  DEFB $92                             ; (2,4,2), (2,4,3), (3,3,1), (3,3,2),
                                       ; (3,3,3), (2,2,1), (2,2,2)
  DEFB $35,$D2,$59,$99,$D9,$5A,$9A ; Object template 6 x6 at (2,2,3), (1,3,1),
                                   ; (1,3,2), (1,3,3), (2,3,1), (2,3,2)
  DEFB $10,$0E            ; Object template 2 at (6,1,0)
  DEFB $00,$30            ; Placement nudge $30 for the objects that follow
  DEFB $08,$1A            ; Object template 1 at (2,3,0)
  DEFB $00,$00            ; Placement nudge $00 for the objects that follow
  DEFB $F0,$DA            ; Object template 30 at (2,3,3)
  DEFB $F8,$00            ; Switch to the second page of object templates
  DEFB $28,$1A            ; Object template 5 at (2,3,0)
  DEFB $08,$19            ; Object template 1 at (1,3,0)
  DEFB $10,$22            ; Object template 2 at (2,4,0)
  DEFB $18,$1B            ; Object template 3 at (3,3,0)
  DEFB $20,$12            ; Object template 4 at (2,2,0)
  DEFB $35,$2E,$2F,$25,$1D,$16,$17 ; Object template 6 x6 at (6,5,0), (7,5,0),
                                   ; (5,4,0), (5,3,0), (6,2,0), (7,2,0)

; Room $45 (row 4, column 5): 128 by 64, cyan
;
; 3 backgrounds and 15 objects in 4 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM45:
  DEFB $45,$19,$A8        ; Room $45; 25 bytes from the next; size 2, colour 5
  DEFB $01                ; Background 1
  DEFB $03                ; Background 3
  DEFB $09                ; Background 9
  DEFB $FF                ; End of the backgrounds
  DEFB $0B,$15,$2D,$2A,$12 ; Object template 1 x4 at (5,2,0), (5,5,0), (2,5,0),
                           ; (2,2,0)
  DEFB $31,$AB,$AC        ; Object template 6 x2 at (3,5,2), (4,5,2)
  DEFB $7F,$55,$1D,$25,$6D,$6A,$22,$1A ; Object template 15 x8 at (5,2,1),
  DEFB $52                             ; (5,3,0), (5,4,0), (5,5,1), (2,5,1),
                                       ; (2,4,0), (2,3,0), (2,2,1)
  DEFB $E0,$23            ; Object template 28 at (3,4,0)

; Room $46 (row 4, column 6): 128 by 128, magenta
;
; 5 backgrounds and 22 objects in 4 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM46:
  DEFB $46,$22,$18        ; Room $46; 34 bytes from the next; size 0, colour 3
  DEFB $00                ; Background 0
  DEFB $02                ; Background 2
  DEFB $03                ; Background 3
  DEFB $06                ; Background 6
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $0F,$27,$67,$A7,$E7,$1F,$5F,$9F ; Object template 1 x8 at (7,4,0),
  DEFB $DF                             ; (7,4,1), (7,4,2), (7,4,3), (7,3,0),
                                       ; (7,3,1), (7,3,2), (7,3,3)
  DEFB $0D,$2E,$2F,$25,$1D,$16,$17 ; Object template 1 x6 at (6,5,0), (7,5,0),
                                   ; (5,4,0), (5,3,0), (6,2,0), (7,2,0)
  DEFB $7D,$6E,$6F,$65,$5D,$56,$57 ; Object template 15 x6 at (6,5,1), (7,5,1),
                                   ; (5,4,1), (5,3,1), (6,2,1), (7,2,1)
  DEFB $31,$26,$1E        ; Object template 6 x2 at (6,4,0), (6,3,0)

; Room $47 (row 4, column 7): 64 by 128, green
;
; 3 backgrounds and 0 objects in 0 groups. Positions are cells (U, V, level): U
; and V 0-7, sixteen units a cell from 72; each level twelve units up from the
; floor.
ROOM47:
  DEFB $47,$05,$60        ; Room $47; 5 bytes from the next; size 1, colour 4
  DEFB $00                ; Background 0
  DEFB $02                ; Background 2
  DEFB $08                ; Background 8

; Room $48 (row 4, column 8): 64 by 128, green
;
; 3 backgrounds and 26 objects in 5 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM48:
  DEFB $48,$25,$60        ; Room $48; 37 bytes from the next; size 1, colour 4
  DEFB $00                ; Background 0
  DEFB $02                ; Background 2
  DEFB $08                ; Background 8
  DEFB $FF                ; End of the backgrounds
  DEFB $0D,$3A,$32,$72,$02,$0A,$4A ; Object template 1 x6 at (2,7,0), (2,6,0),
                                   ; (2,6,1), (2,0,0), (2,1,0), (2,1,1)
  DEFB $31,$A2,$9A        ; Object template 6 x2 at (2,4,2), (2,3,2)
  DEFB $49,$AA,$92        ; Object template 9 x2 at (2,5,2), (2,2,2)
  DEFB $7F,$2A,$2B,$2C,$2D,$22,$23,$24 ; Object template 15 x8 at (2,5,0),
  DEFB $25                             ; (3,5,0), (4,5,0), (5,5,0), (2,4,0),
                                       ; (3,4,0), (4,4,0), (5,4,0)
  DEFB $7F,$1A,$1B,$1C,$1D,$12,$13,$14 ; Object template 15 x8 at (2,3,0),
  DEFB $15                             ; (3,3,0), (4,3,0), (5,3,0), (2,2,0),
                                       ; (3,2,0), (4,2,0), (5,2,0)

; Room $49 (row 4, column 9): 128 by 128, magenta
;
; 6 backgrounds and 4 objects in 2 groups. Positions are cells (U, V, level): U
; and V 0-7, sixteen units a cell from 72; each level twelve units up from the
; floor.
ROOM49:
  DEFB $49,$0F,$18        ; Room $49; 15 bytes from the next; size 0, colour 3
  DEFB $00                ; Background 0
  DEFB $02                ; Background 2
  DEFB $0A                ; Background 10
  DEFB $0C                ; Background 12
  DEFB $04                ; Background 4
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $11,$25,$65        ; Object template 2 x2 at (5,4,0), (5,4,1)
  DEFB $09,$DF,$E7        ; Object template 1 x2 at (7,3,3), (7,4,3)

; Room $4A (row 4, column 10): 128 by 64, cyan
;
; 4 backgrounds and 16 objects in 4 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM4A:
  DEFB $4A,$1B,$A8        ; Room $4A; 27 bytes from the next; size 2, colour 5
  DEFB $0A                ; Background 10
  DEFB $03                ; Background 3
  DEFB $0C                ; Background 12
  DEFB $09                ; Background 9
  DEFB $FF                ; End of the backgrounds
  DEFB $09,$E7,$DF        ; Object template 1 x2 at (7,4,3), (7,3,3)
  DEFB $4F,$19,$21,$22,$1A,$24,$1C,$25 ; Object template 9 x8 at (1,3,0),
  DEFB $1D                             ; (1,4,0), (2,4,0), (2,3,0), (4,4,0),
                                       ; (4,3,0), (5,4,0), (5,3,0)
  DEFB $3B,$1B,$23,$26,$1E ; Object template 7 x4 at (3,3,0), (3,4,0), (6,4,0),
                           ; (6,3,0)
  DEFB $21,$E6,$5E        ; Object template 4 x2 at (6,4,3), (6,3,1)

; Room $4B (row 4, column 11): 128 by 128, yellow
;
; 5 backgrounds and 30 objects in 8 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM4B:
  DEFB $4B,$30,$30        ; Room $4B; 48 bytes from the next; size 0, colour 6
  DEFB $00                ; Background 0
  DEFB $02                ; Background 2
  DEFB $03                ; Background 3
  DEFB $06                ; Background 6
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $AD,$00,$08,$10,$28,$30,$38 ; Object template 21 x6 at (0,0,0), (0,1,0),
                                   ; (0,2,0), (0,5,0), (0,6,0), (0,7,0)
  DEFB $0F,$FF,$BF,$7F,$3F,$37,$77,$B7 ; Object template 1 x8 at (7,7,3),
  DEFB $2F                             ; (7,7,2), (7,7,1), (7,7,0), (7,6,0),
                                       ; (7,6,1), (7,6,2), (7,5,0)
  DEFB $0C,$6F,$AF,$27,$67,$1F ; Object template 1 x5 at (7,5,1), (7,5,2),
                               ; (7,4,0), (7,4,1), (7,3,0)
  DEFB $11,$0F,$8F        ; Object template 2 x2 at (7,1,0), (7,1,2)
  DEFB $19,$4F,$CF        ; Object template 3 x2 at (7,1,1), (7,1,3)
  DEFB $BC,$EF,$A7,$5F,$17,$F7 ; Object template 23 x5 at (7,5,3), (7,4,2),
                               ; (7,3,1), (7,2,0), (7,6,3)
  DEFB $00,$30            ; Placement nudge $30 for the objects that follow
  DEFB $D0,$3F            ; Object template 26 at (7,7,0)
  DEFB $10,$0F            ; Object template 2 at (7,1,0)

; Room $4C (row 4, column 12): 128 by 128, green
;
; 6 backgrounds and 26 objects in 6 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM4C:
  DEFB $4C,$2B,$20        ; Room $4C; 43 bytes from the next; size 0, colour 4
  DEFB $0A                ; Background 10
  DEFB $0B                ; Background 11
  DEFB $0C                ; Background 12
  DEFB $0D                ; Background 13
  DEFB $04                ; Background 4
  DEFB $05                ; Background 5
  DEFB $FF                ; End of the backgrounds
  DEFB $0D,$C3,$C4,$E7,$DF,$C0,$F8 ; Object template 1 x6 at (3,0,3), (4,0,3),
                                   ; (7,4,3), (7,3,3), (0,0,3), (0,7,3)
  DEFB $37,$D8,$E0,$E8,$FA,$FD,$EF,$7B ; Object template 6 x8 at (0,3,3),
  DEFB $7C                             ; (0,4,3), (0,5,3), (2,7,3), (5,7,3),
                                       ; (7,5,3), (3,7,1), (4,7,1)
  DEFB $31,$F0,$F9        ; Object template 6 x2 at (0,6,3), (1,7,3)
  DEFB $3E,$33,$34,$18,$20,$28,$3A,$3D ; Object template 7 x7 at (3,6,0),
                                       ; (4,6,0), (0,3,0), (0,4,0), (0,5,0),
                                       ; (2,7,0), (5,7,0)
  DEFB $00,$30            ; Placement nudge $30 for the objects that follow
  DEFB $08,$7F            ; Object template 1 at (7,7,1)
  DEFB $31,$3E,$37        ; Object template 6 x2 at (6,7,0), (7,6,0)

; Room $4D (row 4, column 13): 128 by 64, magenta
;
; 3 backgrounds and 2 objects in 1 group. Positions are cells (U, V, level): U
; and V 0-7, sixteen units a cell from 72; each level twelve units up from the
; floor.
ROOM4D:
  DEFB $4D,$09,$98        ; Room $4D; 9 bytes from the next; size 2, colour 3
  DEFB $01                ; Background 1
  DEFB $03                ; Background 3
  DEFB $09                ; Background 9
  DEFB $FF                ; End of the backgrounds
  DEFB $E1,$23,$1C        ; Object template 28 x2 at (3,4,0), (4,3,0)

; Room $4E (row 4, column 14): 128 by 128, cyan
;
; 6 backgrounds and 20 objects in 3 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM4E:
  DEFB $4E,$20,$28        ; Room $4E; 32 bytes from the next; size 0, colour 5
  DEFB $00                ; Background 0
  DEFB $01                ; Background 1
  DEFB $02                ; Background 2
  DEFB $03                ; Background 3
  DEFB $06                ; Background 6
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $0F,$3A,$32,$2A,$29,$28,$3D,$35 ; Object template 1 x8 at (2,7,0),
  DEFB $2D                             ; (2,6,0), (2,5,0), (1,5,0), (0,5,0),
                                       ; (5,7,0), (5,6,0), (5,5,0)
  DEFB $0F,$2E,$2F,$17,$16,$15,$0D,$05 ; Object template 1 x8 at (6,5,0),
  DEFB $02                             ; (7,5,0), (7,2,0), (6,2,0), (5,2,0),
                                       ; (5,1,0), (5,0,0), (2,0,0)
  DEFB $0B,$0A,$10,$11,$12 ; Object template 1 x4 at (2,1,0), (0,2,0), (1,2,0),
                           ; (2,2,0)

; Room $4F (row 4, column 15): 128 by 128, yellow
;
; 4 backgrounds and 21 objects in 6 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM4F:
  DEFB $4F,$24,$30        ; Room $4F; 36 bytes from the next; size 0, colour 6
  DEFB $02                ; Background 2
  DEFB $03                ; Background 3
  DEFB $05                ; Background 5
  DEFB $06                ; Background 6
  DEFB $FF                ; End of the backgrounds
  DEFB $AD,$00,$08,$10,$38,$30,$28 ; Object template 21 x6 at (0,0,0), (0,1,0),
                                   ; (0,2,0), (0,7,0), (0,6,0), (0,5,0)
  DEFB $0F,$05,$45,$06,$46,$86,$07,$47 ; Object template 1 x8 at (5,0,0),
  DEFB $87                             ; (5,0,1), (6,0,0), (6,0,1), (6,0,2),
                                       ; (7,0,0), (7,0,1), (7,0,2)
  DEFB $09,$C7,$FF        ; Object template 1 x2 at (7,0,3), (7,7,3)
  DEFB $39,$37,$2F        ; Object template 7 x2 at (7,6,0), (7,5,0)
  DEFB $71,$EF,$CF        ; Object template 14 x2 at (7,5,3), (7,1,3)
  DEFB $00,$30            ; Placement nudge $30 for the objects that follow
  DEFB $D8,$3F            ; Object template 27 at (7,7,0)

; Room $51 (row 5, column 1): 64 by 128, green
;
; 3 backgrounds and 0 objects in 0 groups. Positions are cells (U, V, level): U
; and V 0-7, sixteen units a cell from 72; each level twelve units up from the
; floor.
ROOM51:
  DEFB $51,$05,$60        ; Room $51; 5 bytes from the next; size 1, colour 4
  DEFB $00                ; Background 0
  DEFB $02                ; Background 2
  DEFB $08                ; Background 8

; Room $54 (row 5, column 4): 64 by 128, cyan
;
; 3 backgrounds and 20 objects in 6 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM54:
  DEFB $54,$20,$68        ; Room $54; 32 bytes from the next; size 1, colour 5
  DEFB $00                ; Background 0
  DEFB $02                ; Background 2
  DEFB $08                ; Background 8
  DEFB $FF                ; End of the backgrounds
  DEFB $0D,$3A,$3D,$33,$02,$05,$0B ; Object template 1 x6 at (2,7,0), (5,7,0),
                                   ; (3,6,0), (2,0,0), (5,0,0), (3,1,0)
  DEFB $50,$34            ; Object template 10 at (4,6,0)
  DEFB $40,$0C            ; Object template 8 at (4,1,0)
  DEFB $7D,$42,$45,$4B,$73,$7A,$7D ; Object template 15 x6 at (2,0,1), (5,0,1),
                                   ; (3,1,1), (3,6,1), (2,7,1), (5,7,1)
  DEFB $3B,$2C,$24,$1C,$14 ; Object template 7 x4 at (4,5,0), (4,4,0), (4,3,0),
                           ; (4,2,0)
  DEFB $21,$E4,$5C        ; Object template 4 x2 at (4,4,3), (4,3,1)

; Room $56 (row 5, column 6): 128 by 128, yellow
;
; 3 backgrounds and 28 objects in 11 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM56:
  DEFB $56,$2F,$30        ; Room $56; 47 bytes from the next; size 0, colour 6
  DEFB $02                ; Background 2
  DEFB $04                ; Background 4
  DEFB $05                ; Background 5
  DEFB $FF                ; End of the backgrounds
  DEFB $09,$7A,$7D        ; Object template 1 x2 at (2,7,1), (5,7,1)
  DEFB $79,$BA,$BD        ; Object template 15 x2 at (2,7,2), (5,7,2)
  DEFB $F0,$09            ; Object template 30 at (1,1,0)
  DEFB $F8,$00            ; Switch to the second page of object templates
  DEFB $28,$0E            ; Object template 5 at (6,1,0)
  DEFB $10,$16            ; Object template 2 at (6,2,0)
  DEFB $18,$0F            ; Object template 3 at (7,1,0)
  DEFB $20,$06            ; Object template 4 at (6,0,0)
  DEFB $08,$0D            ; Object template 1 at (5,1,0)
  DEFB $35,$38,$39,$3A,$3D,$3E,$3F ; Object template 6 x6 at (0,7,0), (1,7,0),
                                   ; (2,7,0), (5,7,0), (6,7,0), (7,7,0)
  DEFB $37,$31,$32,$33,$34,$35,$36,$2A ; Object template 6 x8 at (1,6,0),
  DEFB $2B                             ; (2,6,0), (3,6,0), (4,6,0), (5,6,0),
                                       ; (6,6,0), (2,5,0), (3,5,0)
  DEFB $33,$2C,$2D,$23,$24 ; Object template 6 x4 at (4,5,0), (5,5,0), (3,4,0),
                           ; (4,4,0)

; Room $57 (row 5, column 7): 64 by 128, magenta
;
; 3 backgrounds and 9 objects in 3 groups. Positions are cells (U, V, level): U
; and V 0-7, sixteen units a cell from 72; each level twelve units up from the
; floor.
ROOM57:
  DEFB $57,$12,$58        ; Room $57; 18 bytes from the next; size 1, colour 3
  DEFB $00                ; Background 0
  DEFB $02                ; Background 2
  DEFB $08                ; Background 8
  DEFB $FF                ; End of the backgrounds
  DEFB $0B,$0B,$0C,$33,$34 ; Object template 1 x4 at (3,1,0), (4,1,0), (3,6,0),
                           ; (4,6,0)
  DEFB $3B,$0A,$0D,$32,$35 ; Object template 7 x4 at (2,1,0), (5,1,0), (2,6,0),
                           ; (5,6,0)
  DEFB $80,$1C            ; Object template 16 at (4,3,0)

; Room $58 (row 5, column 8): 64 by 128, magenta
;
; 3 backgrounds and 32 objects in 4 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM58:
  DEFB $58,$2C,$58        ; Room $58; 44 bytes from the next; size 1, colour 3
  DEFB $00                ; Background 0
  DEFB $02                ; Background 2
  DEFB $08                ; Background 8
  DEFB $FF                ; End of the backgrounds
  DEFB $0F,$12,$13,$14,$15,$1A,$1B,$1C ; Object template 1 x8 at (2,2,0),
  DEFB $1D                             ; (3,2,0), (4,2,0), (5,2,0), (2,3,0),
                                       ; (3,3,0), (4,3,0), (5,3,0)
  DEFB $0F,$22,$23,$24,$25,$2A,$2B,$2C ; Object template 1 x8 at (2,4,0),
  DEFB $2D                             ; (3,4,0), (4,4,0), (5,4,0), (2,5,0),
                                       ; (3,5,0), (4,5,0), (5,5,0)
  DEFB $00,$30            ; Placement nudge $30 for the objects that follow
  DEFB $A7,$12,$13,$14,$15,$1A,$1B,$1C ; Object template 20 x8 at (2,2,0),
  DEFB $1D                             ; (3,2,0), (4,2,0), (5,2,0), (2,3,0),
                                       ; (3,3,0), (4,3,0), (5,3,0)
  DEFB $A7,$22,$23,$24,$25,$2A,$2B,$2C ; Object template 20 x8 at (2,4,0),
  DEFB $2D                             ; (3,4,0), (4,4,0), (5,4,0), (2,5,0),
                                       ; (3,5,0), (4,5,0), (5,5,0)

; Room $59 (row 5, column 9): 128 by 128, yellow
;
; 4 backgrounds and 14 objects in 5 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM59:
  DEFB $59,$1C,$30        ; Room $59; 28 bytes from the next; size 0, colour 6
  DEFB $0B                ; Background 11
  DEFB $0D                ; Background 13
  DEFB $04                ; Background 4
  DEFB $05                ; Background 5
  DEFB $FF                ; End of the backgrounds
  DEFB $0B,$C3,$C4,$07,$46 ; Object template 1 x4 at (3,0,3), (4,0,3), (7,0,0),
                           ; (6,0,1)
  DEFB $08,$85            ; Object template 1 at (5,0,2)
  DEFB $3C,$1C,$1B,$1D,$24,$14 ; Object template 7 x5 at (4,3,0), (3,3,0),
                               ; (5,3,0), (4,4,0), (4,2,0)
  DEFB $32,$5C,$9C,$DC    ; Object template 6 x3 at (4,3,1), (4,3,2), (4,3,3)
  DEFB $00,$30            ; Placement nudge $30 for the objects that follow
  DEFB $30,$1C            ; Object template 6 at (4,3,0)

; Room $5B (row 5, column 11): 64 by 128, cyan
;
; 3 backgrounds and 16 objects in 3 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM5B:
  DEFB $5B,$19,$68        ; Room $5B; 25 bytes from the next; size 1, colour 5
  DEFB $00                ; Background 0
  DEFB $02                ; Background 2
  DEFB $08                ; Background 8
  DEFB $FF                ; End of the backgrounds
  DEFB $43,$12,$13,$14,$15 ; Object template 8 x4 at (2,2,0), (3,2,0), (4,2,0),
                           ; (5,2,0)
  DEFB $53,$2A,$2B,$2C,$2D ; Object template 10 x4 at (2,5,0), (3,5,0),
                           ; (4,5,0), (5,5,0)
  DEFB $3F,$1A,$1B,$1C,$1D,$22,$23,$24 ; Object template 7 x8 at (2,3,0),
  DEFB $25                             ; (3,3,0), (4,3,0), (5,3,0), (2,4,0),
                                       ; (3,4,0), (4,4,0), (5,4,0)

; Room $5E (row 5, column 14): 64 by 128, green
;
; 3 backgrounds and 1 object in 1 group. Positions are cells (U, V, level): U
; and V 0-7, sixteen units a cell from 72; each level twelve units up from the
; floor.
ROOM5E:
  DEFB $5E,$08,$60        ; Room $5E; 8 bytes from the next; size 1, colour 4
  DEFB $00                ; Background 0
  DEFB $02                ; Background 2
  DEFB $08                ; Background 8
  DEFB $FF                ; End of the backgrounds
  DEFB $E8,$24            ; Object template 29 at (4,4,0)

; Room $61 (row 6, column 1): 128 by 128, yellow
;
; 5 backgrounds and 22 objects in 9 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM61:
  DEFB $61,$29,$30        ; Room $61; 41 bytes from the next; size 0, colour 6
  DEFB $01                ; Background 1
  DEFB $0B                ; Background 11
  DEFB $0D                ; Background 13
  DEFB $04                ; Background 4
  DEFB $05                ; Background 5
  DEFB $FF                ; End of the backgrounds
  DEFB $0F,$C3,$C4,$1A,$5A,$9A,$DA,$16 ; Object template 1 x8 at (3,0,3),
  DEFB $56                             ; (4,0,3), (2,3,0), (2,3,1), (2,3,2),
                                       ; (2,3,3), (6,2,0), (6,2,1)
  DEFB $09,$96,$D6        ; Object template 1 x2 at (6,2,2), (6,2,3)
  DEFB $11,$36,$B6        ; Object template 2 x2 at (6,6,0), (6,6,2)
  DEFB $19,$76,$F6        ; Object template 3 x2 at (6,6,1), (6,6,3)
  DEFB $BA,$06,$07,$0F    ; Object template 23 x3 at (6,0,0), (7,0,0), (7,1,0)
  DEFB $00,$30            ; Placement nudge $30 for the objects that follow
  DEFB $08,$36            ; Object template 1 at (6,6,0)
  DEFB $68,$1A            ; Object template 13 at (2,3,0)
  DEFB $70,$16            ; Object template 14 at (6,2,0)
  DEFB $79,$56,$5A        ; Object template 15 x2 at (6,2,1), (2,3,1)

; Room $62 (row 6, column 2): 128 by 128, magenta
;
; 4 backgrounds and 25 objects in 7 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM62:
  DEFB $62,$29,$18        ; Room $62; 41 bytes from the next; size 0, colour 3
  DEFB $00                ; Background 0
  DEFB $03                ; Background 3
  DEFB $06                ; Background 6
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $B2,$3D,$3E,$3F    ; Object template 22 x3 at (5,7,0), (6,7,0), (7,7,0)
  DEFB $0F,$23,$24,$25,$1B,$1D,$13,$14 ; Object template 1 x8 at (3,4,0),
  DEFB $15                             ; (4,4,0), (5,4,0), (3,3,0), (5,3,0),
                                       ; (3,2,0), (4,2,0), (5,2,0)
  DEFB $0A,$9C,$DC,$09    ; Object template 1 x3 at (4,3,2), (4,3,3), (1,1,0)
  DEFB $BF,$63,$64,$65,$5B,$5D,$53,$54 ; Object template 23 x8 at (3,4,1),
  DEFB $55                             ; (4,4,1), (5,4,1), (3,3,1), (5,3,1),
                                       ; (3,2,1), (4,2,1), (5,2,1)
  DEFB $10,$49            ; Object template 2 at (1,1,1)
  DEFB $18,$89            ; Object template 3 at (1,1,2)
  DEFB $00,$30            ; Placement nudge $30 for the objects that follow
  DEFB $C8,$1C            ; Object template 25 at (4,3,0)

; Room $64 (row 6, column 4): 128 by 128, green
;
; 5 backgrounds and 27 objects in 6 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM64:
  DEFB $64,$2B,$20        ; Room $64; 43 bytes from the next; size 0, colour 4
  DEFB $00                ; Background 0
  DEFB $01                ; Background 1
  DEFB $02                ; Background 2
  DEFB $04                ; Background 4
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $0F,$30,$28,$68,$A8,$20,$60,$A0 ; Object template 1 x8 at (0,6,0),
  DEFB $E0                             ; (0,5,0), (0,5,1), (0,5,2), (0,4,0),
                                       ; (0,4,1), (0,4,2), (0,4,3)
  DEFB $0C,$90,$D1,$D9,$C9,$98 ; Object template 1 x5 at (0,2,2), (1,2,3),
                               ; (1,3,3), (1,1,3), (0,3,2)
  DEFB $32,$80,$C0,$88    ; Object template 6 x3 at (0,0,2), (0,0,3), (0,1,2)
  DEFB $39,$18,$08        ; Object template 7 x2 at (0,3,0), (0,1,0)
  DEFB $00,$30            ; Placement nudge $30 for the objects that follow
  DEFB $0D,$20,$58,$48,$19,$11,$09 ; Object template 1 x6 at (0,4,0), (0,3,1),
                                   ; (0,1,1), (1,3,0), (1,2,0), (1,1,0)
  DEFB $32,$00,$40,$50    ; Object template 6 x3 at (0,0,0), (0,0,1), (0,2,1)

; Room $65 (row 6, column 5): 128 by 128, cyan
;
; 4 backgrounds and 25 objects in 6 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM65:
  DEFB $65,$26,$28        ; Room $65; 38 bytes from the next; size 0, colour 5
  DEFB $00                ; Background 0
  DEFB $03                ; Background 3
  DEFB $06                ; Background 6
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $A9,$7A,$72        ; Object template 21 x2 at (2,7,1), (2,6,1)
  DEFB $B1,$68,$69        ; Object template 22 x2 at (0,5,1), (1,5,1)
  DEFB $0F,$02,$41,$80,$C8,$2F,$77,$BF ; Object template 1 x8 at (2,0,0),
  DEFB $FE                             ; (1,0,1), (0,0,2), (0,1,3), (7,5,0),
                                       ; (7,6,1), (7,7,2), (6,7,3)
  DEFB $0F,$28,$29,$2A,$32,$3A,$70,$71 ; Object template 1 x8 at (0,5,0),
  DEFB $78                             ; (1,5,0), (2,5,0), (2,6,0), (2,7,0),
                                       ; (0,6,1), (1,6,1), (0,7,1)
  DEFB $0B,$79,$B0,$B1,$B9 ; Object template 1 x4 at (1,7,1), (0,6,2), (1,6,2),
                           ; (1,7,2)
  DEFB $D8,$B8            ; Object template 27 at (0,7,2)

; Room $67 (row 6, column 7): 64 by 128, yellow
;
; 3 backgrounds and 9 objects in 3 groups. Positions are cells (U, V, level): U
; and V 0-7, sixteen units a cell from 72; each level twelve units up from the
; floor.
ROOM67:
  DEFB $67,$12,$70        ; Room $67; 18 bytes from the next; size 1, colour 6
  DEFB $00                ; Background 0
  DEFB $02                ; Background 2
  DEFB $08                ; Background 8
  DEFB $FF                ; End of the backgrounds
  DEFB $0B,$2A,$2D,$12,$15 ; Object template 1 x4 at (2,5,0), (5,5,0), (2,2,0),
                           ; (5,2,0)
  DEFB $BB,$6A,$6D,$52,$55 ; Object template 23 x4 at (2,5,1), (5,5,1),
                           ; (2,2,1), (5,2,1)
  DEFB $88,$62            ; Object template 17 at (2,4,1)

; Room $68 (row 6, column 8): 64 by 128, yellow
;
; 3 backgrounds and 0 objects in 0 groups. Positions are cells (U, V, level): U
; and V 0-7, sixteen units a cell from 72; each level twelve units up from the
; floor.
ROOM68:
  DEFB $68,$05,$70        ; Room $68; 5 bytes from the next; size 1, colour 6
  DEFB $00                ; Background 0
  DEFB $02                ; Background 2
  DEFB $08                ; Background 8

; Room $6A (row 6, column 10): 128 by 128, cyan
;
; 4 backgrounds and 30 objects in 10 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM6A:
  DEFB $6A,$31,$28        ; Room $6A; 49 bytes from the next; size 0, colour 5
  DEFB $00                ; Background 0
  DEFB $01                ; Background 1
  DEFB $04                ; Background 4
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $0F,$19,$59,$12,$52,$09,$49,$10 ; Object template 1 x8 at (1,3,0),
  DEFB $50                             ; (1,3,1), (2,2,0), (2,2,1), (1,1,0),
                                       ; (1,1,1), (0,2,0), (0,2,1)
  DEFB $09,$11,$51        ; Object template 1 x2 at (1,2,0), (1,2,1)
  DEFB $F0,$0E            ; Object template 30 at (6,1,0)
  DEFB $F8,$00            ; Switch to the second page of object templates
  DEFB $37,$3A,$32,$39,$31,$2B,$2C,$23 ; Object template 6 x8 at (2,7,0),
  DEFB $24                             ; (2,6,0), (1,7,0), (1,6,0), (3,5,0),
                                       ; (4,5,0), (3,4,0), (4,4,0)
  DEFB $35,$3D,$35,$3E,$36,$2D,$2A ; Object template 6 x6 at (5,7,0), (5,6,0),
                                   ; (6,7,0), (6,6,0), (5,5,0), (2,5,0)
  DEFB $28,$91            ; Object template 5 at (1,2,2)
  DEFB $08,$90            ; Object template 1 at (0,2,2)
  DEFB $10,$99            ; Object template 2 at (1,3,2)
  DEFB $18,$92            ; Object template 3 at (2,2,2)
  DEFB $20,$89            ; Object template 4 at (1,1,2)

; Room $6B (row 6, column 11): 128 by 128, green
;
; 5 backgrounds and 23 objects in 10 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM6B:
  DEFB $6B,$2B,$20        ; Room $6B; 43 bytes from the next; size 0, colour 4
  DEFB $00                ; Background 0
  DEFB $02                ; Background 2
  DEFB $03                ; Background 3
  DEFB $06                ; Background 6
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $0F,$3F,$7F,$BF,$FF,$3A,$32,$33 ; Object template 1 x8 at (7,7,0),
  DEFB $34                             ; (7,7,1), (7,7,2), (7,7,3), (2,7,0),
                                       ; (2,6,0), (3,6,0), (4,6,0)
  DEFB $09,$35,$3D        ; Object template 1 x2 at (5,6,0), (5,7,0)
  DEFB $7D,$7A,$72,$73,$74,$75,$7D ; Object template 15 x6 at (2,7,1), (2,6,1),
                                   ; (3,6,1), (4,6,1), (5,6,1), (5,7,1)
  DEFB $F0,$07            ; Object template 30 at (7,0,0)
  DEFB $10,$47            ; Object template 2 at (7,0,1)
  DEFB $F8,$00            ; Switch to the second page of object templates
  DEFB $28,$09            ; Object template 5 at (1,1,0)
  DEFB $08,$08            ; Object template 1 at (0,1,0)
  DEFB $10,$11            ; Object template 2 at (1,2,0)
  DEFB $18,$0A            ; Object template 3 at (2,1,0)
  DEFB $20,$01            ; Object template 4 at (1,0,0)

; Room $6D (row 6, column 13): 128 by 128, magenta
;
; 4 backgrounds and 0 objects in 0 groups. Positions are cells (U, V, level): U
; and V 0-7, sixteen units a cell from 72; each level twelve units up from the
; floor.
ROOM6D:
  DEFB $6D,$06,$18        ; Room $6D; 6 bytes from the next; size 0, colour 3
  DEFB $00                ; Background 0
  DEFB $01                ; Background 1
  DEFB $04                ; Background 4
  DEFB $07                ; Background 7

; Room $6E (row 6, column 14): 128 by 128, yellow
;
; 4 backgrounds and 30 objects in 7 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM6E:
  DEFB $6E,$2E,$30        ; Room $6E; 46 bytes from the next; size 0, colour 6
  DEFB $02                ; Background 2
  DEFB $03                ; Background 3
  DEFB $05                ; Background 5
  DEFB $06                ; Background 6
  DEFB $FF                ; End of the backgrounds
  DEFB $AB,$00,$10,$28,$38 ; Object template 21 x4 at (0,0,0), (0,2,0),
                           ; (0,5,0), (0,7,0)
  DEFB $0D,$15,$55,$14,$54,$94,$D4 ; Object template 1 x6 at (5,2,0), (5,2,1),
                                   ; (4,2,0), (4,2,1), (4,2,2), (4,2,3)
  DEFB $08,$FC            ; Object template 1 at (4,7,3)
  DEFB $33,$B4,$AC,$A4,$9C ; Object template 6 x4 at (4,6,2), (4,5,2), (4,4,2),
                           ; (4,3,2)
  DEFB $BD,$3D,$3E,$3B,$3A,$39,$3F ; Object template 23 x6 at (5,7,0), (6,7,0),
                                   ; (3,7,0), (2,7,0), (1,7,0), (7,7,0)
  DEFB $BF,$35,$2D,$25,$1D,$33,$2B,$23 ; Object template 23 x8 at (5,6,0),
  DEFB $1B                             ; (5,5,0), (5,4,0), (5,3,0), (3,6,0),
                                       ; (3,5,0), (3,4,0), (3,3,0)
  DEFB $00,$30            ; Placement nudge $30 for the objects that follow
  DEFB $C8,$3C            ; Object template 25 at (4,7,0)

; Room $72 (row 7, column 2): 128 by 128, cyan
;
; 4 backgrounds and 30 objects in 5 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM72:
  DEFB $72,$2C,$28        ; Room $72; 44 bytes from the next; size 0, colour 5
  DEFB $00                ; Background 0
  DEFB $02                ; Background 2
  DEFB $04                ; Background 4
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $E1,$27,$18        ; Object template 28 x2 at (7,4,0), (0,3,0)
  DEFB $F8,$00            ; Switch to the second page of object templates
  DEFB $37,$08,$09,$0A,$10,$11,$12,$1B ; Object template 6 x8 at (0,1,0),
  DEFB $1C                             ; (1,1,0), (2,1,0), (0,2,0), (1,2,0),
                                       ; (2,2,0), (3,3,0), (4,3,0)
  DEFB $37,$0D,$0E,$0F,$15,$16,$17,$23 ; Object template 6 x8 at (5,1,0),
  DEFB $24                             ; (6,1,0), (7,1,0), (5,2,0), (6,2,0),
                                       ; (7,2,0), (3,4,0), (4,4,0)
  DEFB $37,$28,$29,$2A,$30,$31,$32,$2D ; Object template 6 x8 at (0,5,0),
  DEFB $2E                             ; (1,5,0), (2,5,0), (0,6,0), (1,6,0),
                                       ; (2,6,0), (5,5,0), (6,5,0)
  DEFB $33,$2F,$35,$36,$37 ; Object template 6 x4 at (7,5,0), (5,6,0), (6,6,0),
                           ; (7,6,0)

; Room $74 (row 7, column 4): 128 by 128, magenta
;
; 4 backgrounds and 33 objects in 10 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM74:
  DEFB $74,$34,$18        ; Room $74; 52 bytes from the next; size 0, colour 3
  DEFB $01                ; Background 1
  DEFB $02                ; Background 2
  DEFB $04                ; Background 4
  DEFB $05                ; Background 5
  DEFB $FF                ; End of the backgrounds
  DEFB $0F,$38,$30,$28,$29,$2A,$32,$33 ; Object template 1 x8 at (0,7,0),
  DEFB $34                             ; (0,6,0), (0,5,0), (1,5,0), (2,5,0),
                                       ; (2,6,0), (3,6,0), (4,6,0)
  DEFB $0F,$2C,$24,$1C,$25,$1D,$26,$1E ; Object template 1 x8 at (4,5,0),
  DEFB $2E                             ; (4,4,0), (4,3,0), (5,4,0), (5,3,0),
                                       ; (6,4,0), (6,3,0), (6,5,0)
  DEFB $0A,$16,$2F,$17    ; Object template 1 x3 at (6,2,0), (7,5,0), (7,2,0)
  DEFB $F0,$78            ; Object template 30 at (0,7,1)
  DEFB $F8,$00            ; Switch to the second page of object templates
  DEFB $37,$6F,$57,$6E,$56,$66,$5E,$65 ; Object template 6 x8 at (7,5,1),
  DEFB $5D                             ; (7,2,1), (6,5,1), (6,2,1), (6,4,1),
                                       ; (6,3,1), (5,4,1), (5,3,1)
  DEFB $28,$09            ; Object template 5 at (1,1,0)
  DEFB $08,$08            ; Object template 1 at (0,1,0)
  DEFB $10,$11            ; Object template 2 at (1,2,0)
  DEFB $18,$0A            ; Object template 3 at (2,1,0)
  DEFB $20,$01            ; Object template 4 at (1,0,0)

; Room $75 (row 7, column 5): 128 by 128, yellow
;
; 5 backgrounds and 24 objects in 6 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM75:
  DEFB $75,$28,$30        ; Room $75; 40 bytes from the next; size 0, colour 6
  DEFB $01                ; Background 1
  DEFB $02                ; Background 2
  DEFB $03                ; Background 3
  DEFB $05                ; Background 5
  DEFB $06                ; Background 6
  DEFB $FF                ; End of the backgrounds
  DEFB $0F,$2B,$6B,$AB,$EB,$2C,$6C,$AC ; Object template 1 x8 at (3,5,0),
  DEFB $EC                             ; (3,5,1), (3,5,2), (3,5,3), (4,5,0),
                                       ; (4,5,1), (4,5,2), (4,5,3)
  DEFB $0F,$22,$62,$A2,$25,$65,$A5,$1B ; Object template 1 x8 at (2,4,0),
  DEFB $5B                             ; (2,4,1), (2,4,2), (5,4,0), (5,4,1),
                                       ; (5,4,2), (3,3,0), (3,3,1)
  DEFB $09,$1C,$5C        ; Object template 1 x2 at (4,3,0), (4,3,1)
  DEFB $31,$A3,$A4        ; Object template 6 x2 at (3,4,2), (4,4,2)
  DEFB $39,$23,$24        ; Object template 7 x2 at (3,4,0), (4,4,0)
  DEFB $00,$30            ; Placement nudge $30 for the objects that follow
  DEFB $09,$2B,$2C        ; Object template 1 x2 at (3,5,0), (4,5,0)

; Room $76 (row 7, column 6): 128 by 64, green
;
; 3 backgrounds and 24 objects in 4 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM76:
  DEFB $76,$22,$A0        ; Room $76; 34 bytes from the next; size 2, colour 4
  DEFB $01                ; Background 1
  DEFB $03                ; Background 3
  DEFB $09                ; Background 9
  DEFB $FF                ; End of the backgrounds
  DEFB $53,$6A,$6B,$6C,$6D ; Object template 10 x4 at (2,5,1), (3,5,1),
                           ; (4,5,1), (5,5,1)
  DEFB $43,$52,$53,$54,$55 ; Object template 8 x4 at (2,2,1), (3,2,1), (4,2,1),
                           ; (5,2,1)
  DEFB $3F,$2A,$2B,$2C,$2D,$22,$23,$24 ; Object template 7 x8 at (2,5,0),
  DEFB $25                             ; (3,5,0), (4,5,0), (5,5,0), (2,4,0),
                                       ; (3,4,0), (4,4,0), (5,4,0)
  DEFB $3F,$1A,$1B,$1C,$1D,$12,$13,$14 ; Object template 7 x8 at (2,3,0),
  DEFB $15                             ; (3,3,0), (4,3,0), (5,3,0), (2,2,0),
                                       ; (3,2,0), (4,2,0), (5,2,0)

; Room $77 (row 7, column 7): 128 by 128, cyan
;
; 6 backgrounds and 32 objects in 5 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM77:
  DEFB $77,$2E,$28        ; Room $77; 46 bytes from the next; size 0, colour 5
  DEFB $00                ; Background 0
  DEFB $01                ; Background 1
  DEFB $02                ; Background 2
  DEFB $03                ; Background 3
  DEFB $06                ; Background 6
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $0F,$16,$0D,$0A,$11,$29,$32,$35 ; Object template 1 x8 at (6,2,0),
  DEFB $2E                             ; (5,1,0), (2,1,0), (1,2,0), (1,5,0),
                                       ; (2,6,0), (5,6,0), (6,5,0)
  DEFB $0F,$3F,$38,$00,$07,$23,$24,$1B ; Object template 1 x8 at (7,7,0),
  DEFB $1C                             ; (0,7,0), (0,0,0), (7,0,0), (3,4,0),
                                       ; (4,4,0), (3,3,0), (4,3,0)
  DEFB $3B,$7F,$78,$47,$40 ; Object template 7 x4 at (7,7,1), (0,7,1), (7,0,1),
                           ; (0,0,1)
  DEFB $7F,$72,$69,$51,$4A,$4D,$56,$6E ; Object template 15 x8 at (2,6,1),
  DEFB $75                             ; (1,5,1), (1,2,1), (2,1,1), (5,1,1),
                                       ; (6,2,1), (6,5,1), (5,6,1)
  DEFB $7B,$63,$64,$5B,$5C ; Object template 15 x4 at (3,4,1), (4,4,1),
                           ; (3,3,1), (4,3,1)

; Room $78 (row 7, column 8): 128 by 128, cyan
;
; 6 backgrounds and 15 objects in 4 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM78:
  DEFB $78,$1C,$28        ; Room $78; 28 bytes from the next; size 0, colour 5
  DEFB $00                ; Background 0
  DEFB $01                ; Background 1
  DEFB $02                ; Background 2
  DEFB $03                ; Background 3
  DEFB $06                ; Background 6
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $0F,$00,$40,$38,$78,$3F,$7F,$07 ; Object template 1 x8 at (0,0,0),
  DEFB $47                             ; (0,0,1), (0,7,0), (0,7,1), (7,7,0),
                                       ; (7,7,1), (7,0,0), (7,0,1)
  DEFB $0B,$23,$24,$1B,$1C ; Object template 1 x4 at (3,4,0), (4,4,0), (3,3,0),
                           ; (4,3,0)
  DEFB $79,$80,$BF        ; Object template 15 x2 at (0,0,2), (7,7,2)
  DEFB $80,$5C            ; Object template 16 at (4,3,1)

; Room $79 (row 7, column 9): 128 by 64, green
;
; 3 backgrounds and 0 objects in 0 groups. Positions are cells (U, V, level): U
; and V 0-7, sixteen units a cell from 72; each level twelve units up from the
; floor.
ROOM79:
  DEFB $79,$05,$A0        ; Room $79; 5 bytes from the next; size 2, colour 4
  DEFB $01                ; Background 1
  DEFB $03                ; Background 3
  DEFB $09                ; Background 9

; Room $7A (row 7, column 10): 128 by 128, yellow
;
; 5 backgrounds and 17 objects in 6 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM7A:
  DEFB $7A,$21,$30        ; Room $7A; 33 bytes from the next; size 0, colour 6
  DEFB $01                ; Background 1
  DEFB $02                ; Background 2
  DEFB $03                ; Background 3
  DEFB $05                ; Background 5
  DEFB $06                ; Background 6
  DEFB $FF                ; End of the backgrounds
  DEFB $AA,$00,$08,$10    ; Object template 21 x3 at (0,0,0), (0,1,0), (0,2,0)
  DEFB $B4,$3B,$3C,$3D,$3E,$3F ; Object template 22 x5 at (3,7,0), (4,7,0),
                               ; (5,7,0), (6,7,0), (7,7,0)
  DEFB $0D,$24,$14,$1B,$1C,$1D,$DC ; Object template 1 x6 at (4,4,0), (4,2,0),
                                   ; (3,3,0), (4,3,0), (5,3,0), (4,3,3)
  DEFB $10,$5C            ; Object template 2 at (4,3,1)
  DEFB $18,$9C            ; Object template 3 at (4,3,2)
  DEFB $00,$30            ; Placement nudge $30 for the objects that follow
  DEFB $C0,$1C            ; Object template 24 at (4,3,0)

; Room $7B (row 7, column 11): 128 by 128, magenta
;
; 4 backgrounds and 16 objects in 5 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM7B:
  DEFB $7B,$1C,$18        ; Room $7B; 28 bytes from the next; size 0, colour 3
  DEFB $02                ; Background 2
  DEFB $03                ; Background 3
  DEFB $05                ; Background 5
  DEFB $06                ; Background 6
  DEFB $FF                ; End of the backgrounds
  DEFB $0E,$0F,$4F,$27,$67,$A7,$16,$1E ; Object template 1 x7 at (7,1,0),
                                       ; (7,1,1), (7,4,0), (7,4,1), (7,4,2),
                                       ; (6,2,0), (6,3,0)
  DEFB $0B,$5E,$56,$9E,$96 ; Object template 1 x4 at (6,3,1), (6,2,1), (6,3,2),
                           ; (6,2,2)
  DEFB $32,$5F,$57,$8F    ; Object template 6 x3 at (7,3,1), (7,2,1), (7,1,2)
  DEFB $98,$DF            ; Object template 19 at (7,3,3)
  DEFB $B8,$0E            ; Object template 23 at (6,1,0)

; Room $7D (row 7, column 13): 128 by 128, cyan
;
; 4 backgrounds and 20 objects in 3 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM7D:
  DEFB $7D,$1E,$28        ; Room $7D; 30 bytes from the next; size 0, colour 5
  DEFB $00                ; Background 0
  DEFB $02                ; Background 2
  DEFB $04                ; Background 4
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $7F,$00,$11,$19,$21,$02,$1A,$32 ; Object template 15 x8 at (0,0,0),
  DEFB $3A                             ; (1,2,0), (1,3,0), (1,4,0), (2,0,0),
                                       ; (2,3,0), (2,6,0), (2,7,0)
  DEFB $7F,$2B,$1B,$14,$2C,$3D,$25,$15 ; Object template 15 x8 at (3,5,0),
  DEFB $0D                             ; (3,3,0), (4,2,0), (4,5,0), (5,7,0),
                                       ; (5,4,0), (5,2,0), (5,1,0)
  DEFB $7B,$05,$36,$26,$17 ; Object template 15 x4 at (5,0,0), (6,6,0),
                           ; (6,4,0), (7,2,0)

; Room $82 (row 8, column 2): 128 by 128, green
;
; 6 backgrounds and 16 objects in 7 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM82:
  DEFB $82,$22,$20        ; Room $82; 34 bytes from the next; size 0, colour 4
  DEFB $0A                ; Background 10
  DEFB $0B                ; Background 11
  DEFB $0C                ; Background 12
  DEFB $0D                ; Background 13
  DEFB $04                ; Background 4
  DEFB $05                ; Background 5
  DEFB $FF                ; End of the backgrounds
  DEFB $0F,$C3,$C4,$EF,$E7,$DF,$FE,$FB ; Object template 1 x8 at (3,0,3),
  DEFB $F8                             ; (4,0,3), (7,5,3), (7,4,3), (7,3,3),
                                       ; (6,7,3), (3,7,3), (0,7,3)
  DEFB $09,$31,$D0        ; Object template 1 x2 at (1,6,0), (0,2,3)
  DEFB $29,$FC,$C0        ; Object template 5 x2 at (4,7,3), (0,0,3)
  DEFB $30,$D8            ; Object template 6 at (0,3,3)
  DEFB $98,$40            ; Object template 19 at (0,0,1)
  DEFB $18,$80            ; Object template 3 at (0,0,2)
  DEFB $00,$30            ; Placement nudge $30 for the objects that follow
  DEFB $08,$3B            ; Object template 1 at (3,7,0)

; Room $83 (row 8, column 3): 128 by 128, yellow
;
; 5 backgrounds and 0 objects in 0 groups. Positions are cells (U, V, level): U
; and V 0-7, sixteen units a cell from 72; each level twelve units up from the
; floor.
ROOM83:
  DEFB $83,$07,$30        ; Room $83; 7 bytes from the next; size 0, colour 6
  DEFB $00                ; Background 0
  DEFB $01                ; Background 1
  DEFB $03                ; Background 3
  DEFB $06                ; Background 6
  DEFB $07                ; Background 7

; Room $84 (row 8, column 4): 128 by 128, cyan
;
; 5 backgrounds and 15 objects in 4 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM84:
  DEFB $84,$1D,$28        ; Room $84; 29 bytes from the next; size 0, colour 5
  DEFB $00                ; Background 0
  DEFB $01                ; Background 1
  DEFB $03                ; Background 3
  DEFB $06                ; Background 6
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $AA,$00,$08,$10    ; Object template 21 x3 at (0,0,0), (0,1,0), (0,2,0)
  DEFB $0E,$1C,$5C,$9C,$24,$14,$1B,$1D ; Object template 1 x7 at (4,3,0),
                                       ; (4,3,1), (4,3,2), (4,4,0), (4,2,0),
                                       ; (3,3,0), (5,3,0)
  DEFB $D0,$DC            ; Object template 26 at (4,3,3)
  DEFB $00,$30            ; Placement nudge $30 for the objects that follow
  DEFB $A3,$E4,$DB,$DD,$D4 ; Object template 20 x4 at (4,4,3), (3,3,3),
                           ; (5,3,3), (4,2,3)

; Room $85 (row 8, column 5): 128 by 64, magenta
;
; 3 backgrounds and 0 objects in 0 groups. Positions are cells (U, V, level): U
; and V 0-7, sixteen units a cell from 72; each level twelve units up from the
; floor.
ROOM85:
  DEFB $85,$05,$98        ; Room $85; 5 bytes from the next; size 2, colour 3
  DEFB $01                ; Background 1
  DEFB $03                ; Background 3
  DEFB $09                ; Background 9

; Room $86 (row 8, column 6): 128 by 64, yellow
;
; 3 backgrounds and 20 objects in 5 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM86:
  DEFB $86,$1F,$B0        ; Room $86; 31 bytes from the next; size 2, colour 6
  DEFB $01                ; Background 1
  DEFB $03                ; Background 3
  DEFB $09                ; Background 9
  DEFB $FF                ; End of the backgrounds
  DEFB $0D,$2C,$6C,$AC,$14,$54,$94 ; Object template 1 x6 at (4,5,0), (4,5,1),
                                   ; (4,5,2), (4,2,0), (4,2,1), (4,2,2)
  DEFB $7F,$2D,$25,$1D,$15,$2B,$23,$1B ; Object template 15 x8 at (5,5,0),
  DEFB $13                             ; (5,4,0), (5,3,0), (5,2,0), (3,5,0),
                                       ; (3,4,0), (3,3,0), (3,2,0)
  DEFB $79,$EC,$D4        ; Object template 15 x2 at (4,5,3), (4,2,3)
  DEFB $39,$24,$1C        ; Object template 7 x2 at (4,4,0), (4,3,0)
  DEFB $21,$DC,$E4        ; Object template 4 x2 at (4,3,3), (4,4,3)

; Room $87 (row 8, column 7): 128 by 128, green
;
; 6 backgrounds and 31 objects in 5 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM87:
  DEFB $87,$2D,$20        ; Room $87; 45 bytes from the next; size 0, colour 4
  DEFB $00                ; Background 0
  DEFB $01                ; Background 1
  DEFB $02                ; Background 2
  DEFB $03                ; Background 3
  DEFB $06                ; Background 6
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $0F,$33,$34,$26,$1E,$0B,$0C,$21 ; Object template 1 x8 at (3,6,0),
  DEFB $19                             ; (4,6,0), (6,4,0), (6,3,0), (3,1,0),
                                       ; (4,1,0), (1,4,0), (1,3,0)
  DEFB $37,$2B,$6B,$2C,$6C,$25,$65,$1D ; Object template 6 x8 at (3,5,0),
  DEFB $5D                             ; (3,5,1), (4,5,0), (4,5,1), (5,4,0),
                                       ; (5,4,1), (5,3,0), (5,3,1)
  DEFB $37,$13,$53,$14,$54,$22,$62,$1A ; Object template 6 x8 at (3,2,0),
  DEFB $5A                             ; (3,2,1), (4,2,0), (4,2,1), (2,4,0),
                                       ; (2,4,1), (2,3,0), (2,3,1)
  DEFB $33,$A3,$A4,$9B,$9C ; Object template 6 x4 at (3,4,2), (4,4,2), (3,3,2),
                           ; (4,3,2)
  DEFB $3A,$1B,$1C,$24    ; Object template 7 x3 at (3,3,0), (4,3,0), (4,4,0)

; Room $88 (row 8, column 8): 128 by 128, green
;
; 6 backgrounds and 20 objects in 3 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM88:
  DEFB $88,$20,$20        ; Room $88; 32 bytes from the next; size 0, colour 4
  DEFB $00                ; Background 0
  DEFB $01                ; Background 1
  DEFB $02                ; Background 2
  DEFB $03                ; Background 3
  DEFB $06                ; Background 6
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $3F,$3A,$32,$2A,$29,$28,$10,$11 ; Object template 7 x8 at (2,7,0),
  DEFB $12                             ; (2,6,0), (2,5,0), (1,5,0), (0,5,0),
                                       ; (0,2,0), (1,2,0), (2,2,0)
  DEFB $3F,$0A,$02,$05,$0D,$15,$16,$17 ; Object template 7 x8 at (2,1,0),
  DEFB $2F                             ; (2,0,0), (5,0,0), (5,1,0), (5,2,0),
                                       ; (6,2,0), (7,2,0), (7,5,0)
  DEFB $3B,$2E,$2D,$35,$3D ; Object template 7 x4 at (6,5,0), (5,5,0), (5,6,0),
                           ; (5,7,0)

; Room $89 (row 8, column 9): 128 by 64, yellow
;
; 3 backgrounds and 1 object in 1 group. Positions are cells (U, V, level): U
; and V 0-7, sixteen units a cell from 72; each level twelve units up from the
; floor.
ROOM89:
  DEFB $89,$08,$B0        ; Room $89; 8 bytes from the next; size 2, colour 6
  DEFB $01                ; Background 1
  DEFB $03                ; Background 3
  DEFB $09                ; Background 9
  DEFB $FF                ; End of the backgrounds
  DEFB $88,$5A            ; Object template 17 at (2,3,1)

; Room $8A (row 8, column 10): 128 by 64, magenta
;
; 3 backgrounds and 9 objects in 2 groups. Positions are cells (U, V, level): U
; and V 0-7, sixteen units a cell from 72; each level twelve units up from the
; floor.
ROOM8A:
  DEFB $8A,$11,$98        ; Room $8A; 17 bytes from the next; size 2, colour 3
  DEFB $01                ; Background 1
  DEFB $03                ; Background 3
  DEFB $09                ; Background 9
  DEFB $FF                ; End of the backgrounds
  DEFB $3F,$2A,$22,$1A,$12,$2D,$25,$1D ; Object template 7 x8 at (2,5,0),
  DEFB $15                             ; (2,4,0), (2,3,0), (2,2,0), (5,5,0),
                                       ; (5,4,0), (5,3,0), (5,2,0)
  DEFB $88,$6B            ; Object template 17 at (3,5,1)

; Room $8B (row 8, column 11): 128 by 128, cyan
;
; 5 backgrounds and 18 objects in 8 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM8B:
  DEFB $8B,$24,$28        ; Room $8B; 36 bytes from the next; size 0, colour 5
  DEFB $00                ; Background 0
  DEFB $01                ; Background 1
  DEFB $03                ; Background 3
  DEFB $06                ; Background 6
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $F0,$0E            ; Object template 30 at (6,1,0)
  DEFB $F8,$00            ; Switch to the second page of object templates
  DEFB $28,$09            ; Object template 5 at (1,1,0)
  DEFB $08,$08            ; Object template 1 at (0,1,0)
  DEFB $10,$11            ; Object template 2 at (1,2,0)
  DEFB $18,$0A            ; Object template 3 at (2,1,0)
  DEFB $20,$01            ; Object template 4 at (1,0,0)
  DEFB $37,$3A,$7A,$32,$72,$2B,$6B,$2C ; Object template 6 x8 at (2,7,0),
  DEFB $6C                             ; (2,7,1), (2,6,0), (2,6,1), (3,5,0),
                                       ; (3,5,1), (4,5,0), (4,5,1)
  DEFB $33,$35,$75,$3D,$7D ; Object template 6 x4 at (5,6,0), (5,6,1), (5,7,0),
                           ; (5,7,1)

; Room $8C (row 8, column 12): 128 by 128, yellow
;
; 5 backgrounds and 16 objects in 7 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM8C:
  DEFB $8C,$21,$30        ; Room $8C; 33 bytes from the next; size 0, colour 6
  DEFB $00                ; Background 0
  DEFB $01                ; Background 1
  DEFB $03                ; Background 3
  DEFB $06                ; Background 6
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $AA,$00,$08,$10    ; Object template 21 x3 at (0,0,0), (0,1,0), (0,2,0)
  DEFB $B2,$3D,$3E,$3F    ; Object template 22 x3 at (5,7,0), (6,7,0), (7,7,0)
  DEFB $0B,$0E,$4E,$8E,$CE ; Object template 1 x4 at (6,1,0), (6,1,1), (6,1,2),
                           ; (6,1,3)
  DEFB $10,$0A            ; Object template 2 at (2,1,0)
  DEFB $18,$4A            ; Object template 3 at (2,1,1)
  DEFB $00,$30            ; Placement nudge $30 for the objects that follow
  DEFB $0A,$0E,$0F,$06    ; Object template 1 x3 at (6,1,0), (7,1,0), (6,0,0)
  DEFB $D8,$4E            ; Object template 27 at (6,1,1)

; Room $8D (row 8, column 13): 128 by 128, green
;
; 4 backgrounds and 29 objects in 6 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM8D:
  DEFB $8D,$2A,$20        ; Room $8D; 42 bytes from the next; size 0, colour 4
  DEFB $02                ; Background 2
  DEFB $03                ; Background 3
  DEFB $05                ; Background 5
  DEFB $06                ; Background 6
  DEFB $FF                ; End of the backgrounds
  DEFB $AA,$10,$08,$00    ; Object template 21 x3 at (0,2,0), (0,1,0), (0,0,0)
  DEFB $0F,$38,$39,$79,$3A,$7A,$BA,$7F ; Object template 1 x8 at (0,7,0),
  DEFB $17                             ; (1,7,0), (1,7,1), (2,7,0), (2,7,1),
                                       ; (2,7,2), (7,7,1), (7,2,0)
  DEFB $0C,$57,$97,$0F,$4F,$07 ; Object template 1 x5 at (7,2,1), (7,2,2),
                               ; (7,1,0), (7,1,1), (7,0,0)
  DEFB $BF,$3B,$3C,$3D,$35,$2D,$36,$3E ; Object template 23 x8 at (3,7,0),
  DEFB $2E                             ; (4,7,0), (5,7,0), (5,6,0), (5,5,0),
                                       ; (6,6,0), (6,7,0), (6,5,0)
  DEFB $BB,$37,$2F,$27,$1F ; Object template 23 x4 at (7,6,0), (7,5,0),
                           ; (7,4,0), (7,3,0)
  DEFB $D0,$BF            ; Object template 26 at (7,7,2)

; Room $93 (row 9, column 3): 128 by 128, magenta
;
; 6 backgrounds and 27 objects in 5 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM93:
  DEFB $93,$29,$18        ; Room $93; 41 bytes from the next; size 0, colour 3
  DEFB $0A                ; Background 10
  DEFB $0B                ; Background 11
  DEFB $0C                ; Background 12
  DEFB $0D                ; Background 13
  DEFB $04                ; Background 4
  DEFB $05                ; Background 5
  DEFB $FF                ; End of the backgrounds
  DEFB $0F,$03,$43,$83,$C3,$04,$44,$84 ; Object template 1 x8 at (3,0,0),
  DEFB $C4                             ; (3,0,1), (3,0,2), (3,0,3), (4,0,0),
                                       ; (4,0,1), (4,0,2), (4,0,3)
  DEFB $0F,$1F,$5F,$9F,$DF,$27,$67,$A7 ; Object template 1 x8 at (7,3,0),
  DEFB $E7                             ; (7,3,1), (7,3,2), (7,3,3), (7,4,0),
                                       ; (7,4,1), (7,4,2), (7,4,3)
  DEFB $60,$23            ; Object template 12 at (3,4,0)
  DEFB $09,$CB,$E6        ; Object template 1 x2 at (3,1,3), (6,4,3)
  DEFB $3F,$2A,$2B,$2C,$1A,$1B,$1C,$22 ; Object template 7 x8 at (2,5,0),
  DEFB $24                             ; (3,5,0), (4,5,0), (2,3,0), (3,3,0),
                                       ; (4,3,0), (2,4,0), (4,4,0)

; Room $94 (row 9, column 4): 128 by 128, green
;
; 5 backgrounds and 20 objects in 5 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM94:
  DEFB $94,$21,$20        ; Room $94; 33 bytes from the next; size 0, colour 4
  DEFB $00                ; Background 0
  DEFB $02                ; Background 2
  DEFB $03                ; Background 3
  DEFB $06                ; Background 6
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $AD,$00,$08,$10,$28,$30,$38 ; Object template 21 x6 at (0,0,0), (0,1,0),
                                   ; (0,2,0), (0,5,0), (0,6,0), (0,7,0)
  DEFB $0C,$8E,$16,$0D,$0F,$06 ; Object template 1 x5 at (6,1,2), (6,2,0),
                               ; (5,1,0), (7,1,0), (6,0,0)
  DEFB $33,$56,$4F,$46,$4D ; Object template 6 x4 at (6,2,1), (7,1,1), (6,0,1),
                           ; (5,1,1)
  DEFB $BB,$15,$17,$05,$07 ; Object template 23 x4 at (5,2,0), (7,2,0),
                           ; (5,0,0), (7,0,0)
  DEFB $D0,$CE            ; Object template 26 at (6,1,3)

; Room $95 (row 9, column 5): 128 by 128, yellow
;
; 4 backgrounds and 10 objects in 4 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM95:
  DEFB $95,$15,$30        ; Room $95; 21 bytes from the next; size 0, colour 6
  DEFB $00                ; Background 0
  DEFB $01                ; Background 1
  DEFB $04                ; Background 4
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $09,$1A,$5A        ; Object template 1 x2 at (2,3,0), (2,3,1)
  DEFB $28,$99            ; Object template 5 at (1,3,2)
  DEFB $32,$92,$9B,$A2    ; Object template 6 x3 at (2,2,2), (3,3,2), (2,4,2)
  DEFB $3B,$19,$1B,$22,$12 ; Object template 7 x4 at (1,3,0), (3,3,0), (2,4,0),
                           ; (2,2,0)

; Room $96 (row 9, column 6): 128 by 128, magenta
;
; 4 backgrounds and 30 objects in 8 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM96:
  DEFB $96,$2F,$18        ; Room $96; 47 bytes from the next; size 0, colour 3
  DEFB $00                ; Background 0
  DEFB $03                ; Background 3
  DEFB $06                ; Background 6
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $AA,$28,$30,$38    ; Object template 21 x3 at (0,5,0), (0,6,0), (0,7,0)
  DEFB $B2,$3D,$3E,$3F    ; Object template 22 x3 at (5,7,0), (6,7,0), (7,7,0)
  DEFB $0F,$88,$40,$00,$05,$45,$CD,$D6 ; Object template 1 x8 at (0,1,2),
  DEFB $CE                             ; (0,0,1), (0,0,0), (5,0,0), (5,0,1),
                                       ; (5,1,3), (6,2,3), (6,1,3)
  DEFB $0B,$0E,$4E,$17,$57 ; Object template 1 x4 at (6,1,0), (6,1,1), (7,2,0),
                           ; (7,2,1)
  DEFB $4B,$C9,$CA,$CB,$CC ; Object template 9 x4 at (1,1,3), (2,1,3), (3,1,3),
                           ; (4,1,3)
  DEFB $BC,$85,$8E,$97,$86,$8F ; Object template 23 x5 at (5,0,2), (6,1,2),
                               ; (7,2,2), (6,0,2), (7,1,2)
  DEFB $C8,$07            ; Object template 25 at (7,0,0)
  DEFB $00,$30            ; Placement nudge $30 for the objects that follow
  DEFB $11,$0D,$16        ; Object template 2 x2 at (5,1,0), (6,2,0)

; Room $97 (row 9, column 7): 64 by 128, magenta
;
; 3 backgrounds and 8 objects in 1 group. Positions are cells (U, V, level): U
; and V 0-7, sixteen units a cell from 72; each level twelve units up from the
; floor.
ROOM97:
  DEFB $97,$11,$58        ; Room $97; 17 bytes from the next; size 1, colour 3
  DEFB $00                ; Background 0
  DEFB $02                ; Background 2
  DEFB $08                ; Background 8
  DEFB $FF                ; End of the backgrounds
  DEFB $F8,$00            ; Switch to the second page of object templates
  DEFB $3F,$12,$13,$14,$15,$2A,$2B,$2C ; Object template 7 x8 at (2,2,0),
  DEFB $2D                             ; (3,2,0), (4,2,0), (5,2,0), (2,5,0),
                                       ; (3,5,0), (4,5,0), (5,5,0)

; Room $98 (row 9, column 8): 64 by 128, magenta
;
; 3 backgrounds and 16 objects in 2 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM98:
  DEFB $98,$18,$58        ; Room $98; 24 bytes from the next; size 1, colour 3
  DEFB $00                ; Background 0
  DEFB $02                ; Background 2
  DEFB $08                ; Background 8
  DEFB $FF                ; End of the backgrounds
  DEFB $0F,$1D,$13,$14,$15,$22,$2A,$2B ; Object template 1 x8 at (5,3,0),
  DEFB $2C                             ; (3,2,0), (4,2,0), (5,2,0), (2,4,0),
                                       ; (2,5,0), (3,5,0), (4,5,0)
  DEFB $7F,$5D,$55,$54,$53,$62,$6A,$6B ; Object template 15 x8 at (5,3,1),
  DEFB $6C                             ; (5,2,1), (4,2,1), (3,2,1), (2,4,1),
                                       ; (2,5,1), (3,5,1), (4,5,1)

; Room $99 (row 9, column 9): 128 by 128, magenta
;
; 4 backgrounds and 21 objects in 9 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM99:
  DEFB $99,$27,$18        ; Room $99; 39 bytes from the next; size 0, colour 3
  DEFB $00                ; Background 0
  DEFB $01                ; Background 1
  DEFB $04                ; Background 4
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $AF,$00,$08,$10,$18,$20,$28,$30 ; Object template 21 x8 at (0,0,0),
  DEFB $38                             ; (0,1,0), (0,2,0), (0,3,0), (0,4,0),
                                       ; (0,5,0), (0,6,0), (0,7,0)
  DEFB $09,$17,$57        ; Object template 1 x2 at (7,2,0), (7,2,1)
  DEFB $B8,$97            ; Object template 23 at (7,2,2)
  DEFB $11,$15,$95        ; Object template 2 x2 at (5,2,0), (5,2,2)
  DEFB $19,$55,$D5        ; Object template 3 x2 at (5,2,1), (5,2,3)
  DEFB $00,$30            ; Placement nudge $30 for the objects that follow
  DEFB $10,$15            ; Object template 2 at (5,2,0)
  DEFB $18,$55            ; Object template 3 at (5,2,1)
  DEFB $0A,$95,$96,$97    ; Object template 1 x3 at (5,2,2), (6,2,2), (7,2,2)
  DEFB $C0,$D7            ; Object template 24 at (7,2,3)

; Room $9A (row 9, column 10): 128 by 128, yellow
;
; 4 backgrounds and 16 objects in 4 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM9A:
  DEFB $9A,$1B,$30        ; Room $9A; 27 bytes from the next; size 0, colour 6
  DEFB $00                ; Background 0
  DEFB $03                ; Background 3
  DEFB $06                ; Background 6
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $0F,$3F,$7F,$BF,$FF,$2D,$6D,$AD ; Object template 1 x8 at (7,7,0),
  DEFB $24                             ; (7,7,1), (7,7,2), (7,7,3), (5,5,0),
                                       ; (5,5,1), (5,5,2), (4,4,0)
  DEFB $09,$64,$1B        ; Object template 1 x2 at (4,4,1), (3,3,0)
  DEFB $32,$F6,$F7,$FE    ; Object template 6 x3 at (6,6,3), (7,6,3), (6,7,3)
  DEFB $BA,$3E,$36,$37    ; Object template 23 x3 at (6,7,0), (6,6,0), (7,6,0)

; Room $9B (row 9, column 11): 128 by 128, green
;
; 5 backgrounds and 0 objects in 0 groups. Positions are cells (U, V, level): U
; and V 0-7, sixteen units a cell from 72; each level twelve units up from the
; floor.
ROOM9B:
  DEFB $9B,$07,$20        ; Room $9B; 7 bytes from the next; size 0, colour 4
  DEFB $00                ; Background 0
  DEFB $01                ; Background 1
  DEFB $02                ; Background 2
  DEFB $04                ; Background 4
  DEFB $07                ; Background 7

; Room $9C (row 9, column 12): 128 by 128, magenta
;
; 4 backgrounds and 16 objects in 6 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOM9C:
  DEFB $9C,$1D,$18        ; Room $9C; 29 bytes from the next; size 0, colour 3
  DEFB $02                ; Background 2
  DEFB $03                ; Background 3
  DEFB $05                ; Background 5
  DEFB $06                ; Background 6
  DEFB $FF                ; End of the backgrounds
  DEFB $0D,$3E,$3F,$FE,$37,$77,$B7 ; Object template 1 x6 at (6,7,0), (7,7,0),
                                   ; (6,7,3), (7,6,0), (7,6,1), (7,6,2)
  DEFB $3A,$3C,$35,$36    ; Object template 7 x3 at (4,7,0), (5,6,0), (6,6,0)
  DEFB $13,$23,$24,$1B,$1C ; Object template 2 x4 at (3,4,0), (4,4,0), (3,3,0),
                           ; (4,3,0)
  DEFB $28,$FD            ; Object template 5 at (5,7,3)
  DEFB $30,$FF            ; Object template 6 at (7,7,3)
  DEFB $80,$7E            ; Object template 16 at (6,7,1)

; Room $A4 (row 10, column 4): 128 by 128, yellow
;
; 5 backgrounds and 30 objects in 6 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOMA4:
  DEFB $A4,$2C,$30        ; Room $A4; 44 bytes from the next; size 0, colour 6
  DEFB $01                ; Background 1
  DEFB $0B                ; Background 11
  DEFB $0D                ; Background 13
  DEFB $04                ; Background 4
  DEFB $05                ; Background 5
  DEFB $FF                ; End of the backgrounds
  DEFB $29,$6B,$6C        ; Object template 5 x2 at (3,5,1), (4,5,1)
  DEFB $0F,$13,$14,$0B,$0C,$53,$54,$4B ; Object template 1 x8 at (3,2,0),
  DEFB $4C                             ; (4,2,0), (3,1,0), (4,1,0), (3,2,1),
                                       ; (4,2,1), (3,1,1), (4,1,1)
  DEFB $0B,$8B,$8C,$C3,$C4 ; Object template 1 x4 at (3,1,2), (4,1,2), (3,0,3),
                           ; (4,0,3)
  DEFB $37,$23,$63,$24,$64,$1B,$5B,$1C ; Object template 6 x8 at (3,4,0),
  DEFB $5C                             ; (3,4,1), (4,4,0), (4,4,1), (3,3,0),
                                       ; (3,3,1), (4,3,0), (4,3,1)
  DEFB $33,$9B,$DB,$9C,$DC ; Object template 6 x4 at (3,3,2), (3,3,3), (4,3,2),
                           ; (4,3,3)
  DEFB $7B,$93,$94,$CB,$CC ; Object template 15 x4 at (3,2,2), (4,2,2),
                           ; (3,1,3), (4,1,3)

; Room $A5 (row 10, column 5): 128 by 128, magenta
;
; 6 backgrounds and 27 objects in 7 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOMA5:
  DEFB $A5,$2D,$18        ; Room $A5; 45 bytes from the next; size 0, colour 3
  DEFB $00                ; Background 0
  DEFB $01                ; Background 1
  DEFB $02                ; Background 2
  DEFB $03                ; Background 3
  DEFB $06                ; Background 6
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $A9,$00,$08        ; Object template 21 x2 at (0,0,0), (0,1,0)
  DEFB $B1,$3E,$3F        ; Object template 22 x2 at (6,7,0), (7,7,0)
  DEFB $0F,$12,$52,$92,$D2,$15,$55,$2D ; Object template 1 x8 at (2,2,0),
  DEFB $6D                             ; (2,2,1), (2,2,2), (2,2,3), (5,2,0),
                                       ; (5,2,1), (5,5,0), (5,5,1)
  DEFB $0C,$AD,$2A,$6A,$AA,$EA ; Object template 1 x5 at (5,5,2), (2,5,0),
                               ; (2,5,1), (2,5,2), (2,5,3)
  DEFB $BF,$22,$1A,$2B,$2C,$25,$1D,$13 ; Object template 23 x8 at (2,4,0),
  DEFB $14                             ; (2,3,0), (3,5,0), (4,5,0), (5,4,0),
                                       ; (5,3,0), (3,2,0), (4,2,0)
  DEFB $00,$30            ; Placement nudge $30 for the objects that follow
  DEFB $08,$12            ; Object template 1 at (2,2,0)
  DEFB $C0,$52            ; Object template 24 at (2,2,1)

; Room $A6 (row 10, column 6): 128 by 128, cyan
;
; 5 backgrounds and 6 objects in 3 groups. Positions are cells (U, V, level): U
; and V 0-7, sixteen units a cell from 72; each level twelve units up from the
; floor.
ROOMA6:
  DEFB $A6,$11,$28        ; Room $A6; 17 bytes from the next; size 0, colour 5
  DEFB $0B                ; Background 11
  DEFB $0D                ; Background 13
  DEFB $03                ; Background 3
  DEFB $05                ; Background 5
  DEFB $06                ; Background 6
  DEFB $FF                ; End of the backgrounds
  DEFB $09,$C4,$C3        ; Object template 1 x2 at (4,0,3), (3,0,3)
  DEFB $62,$07,$06,$85    ; Object template 12 x3 at (7,0,0), (6,0,0), (5,0,2)
  DEFB $90,$87            ; Object template 18 at (7,0,2)

; Room $A7 (row 10, column 7): 64 by 128, yellow
;
; 3 backgrounds and 17 objects in 4 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOMA7:
  DEFB $A7,$1B,$70        ; Room $A7; 27 bytes from the next; size 1, colour 6
  DEFB $00                ; Background 0
  DEFB $02                ; Background 2
  DEFB $08                ; Background 8
  DEFB $FF                ; End of the backgrounds
  DEFB $0D,$0A,$0B,$0C,$0D,$3A,$3D ; Object template 1 x6 at (2,1,0), (3,1,0),
                                   ; (4,1,0), (5,1,0), (2,7,0), (5,7,0)
  DEFB $3F,$1A,$1B,$1C,$1D,$5B,$5C,$23 ; Object template 7 x8 at (2,3,0),
  DEFB $24                             ; (3,3,0), (4,3,0), (5,3,0), (3,3,1),
                                       ; (4,3,1), (3,4,0), (4,4,0)
  DEFB $31,$5A,$5D        ; Object template 6 x2 at (2,3,1), (5,3,1)
  DEFB $80,$25            ; Object template 16 at (5,4,0)

; Room $A8 (row 10, column 8): 64 by 128, yellow
;
; 3 backgrounds and 0 objects in 0 groups. Positions are cells (U, V, level): U
; and V 0-7, sixteen units a cell from 72; each level twelve units up from the
; floor.
ROOMA8:
  DEFB $A8,$05,$70        ; Room $A8; 5 bytes from the next; size 1, colour 6
  DEFB $00                ; Background 0
  DEFB $02                ; Background 2
  DEFB $08                ; Background 8

; Room $A9 (row 10, column 9): 128 by 128, cyan
;
; 4 backgrounds and 13 objects in 3 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOMA9:
  DEFB $A9,$19,$28        ; Room $A9; 25 bytes from the next; size 0, colour 5
  DEFB $01                ; Background 1
  DEFB $02                ; Background 2
  DEFB $04                ; Background 4
  DEFB $05                ; Background 5
  DEFB $FF                ; End of the backgrounds
  DEFB $E0,$2A            ; Object template 28 at (2,5,0)
  DEFB $F8,$00            ; Switch to the second page of object templates
  DEFB $3F,$32,$33,$34,$2D,$25,$1D,$14 ; Object template 7 x8 at (2,6,0),
  DEFB $13                             ; (3,6,0), (4,6,0), (5,5,0), (5,4,0),
                                       ; (5,3,0), (4,2,0), (3,2,0)
  DEFB $3B,$12,$19,$21,$29 ; Object template 7 x4 at (2,2,0), (1,3,0), (1,4,0),
                           ; (1,5,0)

; Room $AA (row 10, column 10): 128 by 128, magenta
;
; 6 backgrounds and 21 objects in 6 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOMAA:
  DEFB $AA,$24,$18        ; Room $AA; 36 bytes from the next; size 0, colour 3
  DEFB $00                ; Background 0
  DEFB $01                ; Background 1
  DEFB $02                ; Background 2
  DEFB $03                ; Background 3
  DEFB $06                ; Background 6
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $B5,$3F,$3E,$3D,$3A,$39,$38 ; Object template 22 x6 at (7,7,0), (6,7,0),
                                   ; (5,7,0), (2,7,0), (1,7,0), (0,7,0)
  DEFB $0F,$1B,$5B,$1D,$5D,$24,$64,$14 ; Object template 1 x8 at (3,3,0),
  DEFB $54                             ; (3,3,1), (5,3,0), (5,3,1), (4,4,0),
                                       ; (4,4,1), (4,2,0), (4,2,1)
  DEFB $08,$1C            ; Object template 1 at (4,3,0)
  DEFB $33,$A4,$9B,$9D,$94 ; Object template 6 x4 at (4,4,2), (3,3,2), (5,3,2),
                           ; (4,2,2)
  DEFB $10,$DC            ; Object template 2 at (4,3,3)
  DEFB $C8,$5C            ; Object template 25 at (4,3,1)

; Room $AB (row 10, column 11): 128 by 128, yellow
;
; 4 backgrounds and 19 objects in 5 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOMAB:
  DEFB $AB,$21,$30        ; Room $AB; 33 bytes from the next; size 0, colour 6
  DEFB $02                ; Background 2
  DEFB $03                ; Background 3
  DEFB $05                ; Background 5
  DEFB $06                ; Background 6
  DEFB $FF                ; End of the backgrounds
  DEFB $0F,$BE,$B7,$AF,$A7,$F6,$EE,$E6 ; Object template 1 x8 at (6,7,2),
  DEFB $1E                             ; (7,6,2), (7,5,2), (7,4,2), (6,6,3),
                                       ; (6,5,3), (6,4,3), (6,3,0)
  DEFB $0C,$16,$0E,$0F,$27,$67 ; Object template 1 x5 at (6,2,0), (6,1,0),
                               ; (7,1,0), (7,4,0), (7,4,1)
  DEFB $7B,$5E,$56,$4E,$4F ; Object template 15 x4 at (6,3,1), (6,2,1),
                           ; (6,1,1), (7,1,1)
  DEFB $28,$FF            ; Object template 5 at (7,7,3)
  DEFB $00,$30            ; Placement nudge $30 for the objects that follow
  DEFB $88,$37            ; Object template 17 at (7,6,0)

; Room $B5 (row 11, column 5): 128 by 128, cyan
;
; 5 backgrounds and 29 objects in 6 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOMB5:
  DEFB $B5,$2D,$28        ; Room $B5; 45 bytes from the next; size 0, colour 5
  DEFB $0A                ; Background 10
  DEFB $02                ; Background 2
  DEFB $0C                ; Background 12
  DEFB $04                ; Background 4
  DEFB $05                ; Background 5
  DEFB $FF                ; End of the backgrounds
  DEFB $0F,$F8,$E8,$FA,$FF,$E7,$DF,$EF ; Object template 1 x8 at (0,7,3),
  DEFB $FD                             ; (0,5,3), (2,7,3), (7,7,3), (7,4,3),
                                       ; (7,3,3), (7,5,3), (5,7,3)
  DEFB $09,$FA,$FC        ; Object template 1 x2 at (2,7,3), (4,7,3)
  DEFB $2C,$00,$48,$90,$D8,$FB ; Object template 5 x5 at (0,0,0), (0,1,1),
                               ; (0,2,2), (0,3,3), (3,7,3)
  DEFB $34,$E0,$F0,$F9,$FE,$F7 ; Object template 6 x5 at (0,4,3), (0,6,3),
                               ; (1,7,3), (6,7,3), (7,6,3)
  DEFB $BC,$38,$30,$39,$3F,$37 ; Object template 23 x5 at (0,7,0), (0,6,0),
                               ; (1,7,0), (7,7,0), (7,6,0)
  DEFB $00,$30            ; Placement nudge $30 for the objects that follow
  DEFB $BB,$28,$3A,$3D,$2F ; Object template 23 x4 at (0,5,0), (2,7,0),
                           ; (5,7,0), (7,5,0)

; Room $B6 (row 11, column 6): 128 by 128, green
;
; 4 backgrounds and 15 objects in 6 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOMB6:
  DEFB $B6,$1C,$20        ; Room $B6; 28 bytes from the next; size 0, colour 4
  DEFB $00                ; Background 0
  DEFB $03                ; Background 3
  DEFB $06                ; Background 6
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $AA,$10,$08,$00    ; Object template 21 x3 at (0,2,0), (0,1,0), (0,0,0)
  DEFB $B2,$3D,$3E,$3F    ; Object template 22 x3 at (5,7,0), (6,7,0), (7,7,0)
  DEFB $3D,$0F,$4F,$8F,$06,$46,$86 ; Object template 7 x6 at (7,1,0), (7,1,1),
                                   ; (7,1,2), (6,0,0), (6,0,1), (6,0,2)
  DEFB $C0,$07            ; Object template 24 at (7,0,0)
  DEFB $10,$31            ; Object template 2 at (1,6,0)
  DEFB $30,$C7            ; Object template 6 at (7,0,3)

; Room $B7 (row 11, column 7): 64 by 128, cyan
;
; 3 backgrounds and 8 objects in 2 groups. Positions are cells (U, V, level): U
; and V 0-7, sixteen units a cell from 72; each level twelve units up from the
; floor.
ROOMB7:
  DEFB $B7,$12,$68        ; Room $B7; 18 bytes from the next; size 1, colour 5
  DEFB $00                ; Background 0
  DEFB $02                ; Background 2
  DEFB $08                ; Background 8
  DEFB $FF                ; End of the backgrounds
  DEFB $09,$1B,$1C        ; Object template 1 x2 at (3,3,0), (4,3,0)
  DEFB $F8,$00            ; Switch to the second page of object templates
  DEFB $3D,$13,$14,$1A,$1D,$23,$24 ; Object template 7 x6 at (3,2,0), (4,2,0),
                                   ; (2,3,0), (5,3,0), (3,4,0), (4,4,0)

; Room $B8 (row 11, column 8): 64 by 128, cyan
;
; 3 backgrounds and 24 objects in 3 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOMB8:
  DEFB $B8,$21,$68        ; Room $B8; 33 bytes from the next; size 1, colour 5
  DEFB $00                ; Background 0
  DEFB $02                ; Background 2
  DEFB $08                ; Background 8
  DEFB $FF                ; End of the backgrounds
  DEFB $37,$05,$4C,$93,$DA,$E2,$AB,$74 ; Object template 6 x8 at (5,0,0),
  DEFB $3D                             ; (4,1,1), (3,2,2), (2,3,3), (2,4,3),
                                       ; (3,5,2), (4,6,1), (5,7,0)
  DEFB $7F,$2A,$2C,$23,$25,$1A,$1C,$13 ; Object template 15 x8 at (2,5,0),
  DEFB $15                             ; (4,5,0), (3,4,0), (5,4,0), (2,3,0),
                                       ; (4,3,0), (3,2,0), (5,2,0)
  DEFB $7F,$2B,$2D,$22,$24,$1B,$1D,$12 ; Object template 15 x8 at (3,5,0),
  DEFB $14                             ; (5,5,0), (2,4,0), (4,4,0), (3,3,0),
                                       ; (5,3,0), (2,2,0), (4,2,0)

; Room $B9 (row 11, column 9): 128 by 128, green
;
; 5 backgrounds and 11 objects in 6 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOMB9:
  DEFB $B9,$1B,$20        ; Room $B9; 27 bytes from the next; size 0, colour 4
  DEFB $00                ; Background 0
  DEFB $0A                ; Background 10
  DEFB $0C                ; Background 12
  DEFB $04                ; Background 4
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $0B,$E7,$DF,$F8,$FA ; Object template 1 x4 at (7,4,3), (7,3,3), (0,7,3),
                           ; (2,7,3)
  DEFB $29,$90,$FF        ; Object template 5 x2 at (0,2,2), (7,7,3)
  DEFB $20,$F0            ; Object template 4 at (0,6,3)
  DEFB $39,$08,$30        ; Object template 7 x2 at (0,1,0), (0,6,0)
  DEFB $00,$30            ; Placement nudge $30 for the objects that follow
  DEFB $08,$3D            ; Object template 1 at (5,7,0)
  DEFB $28,$20            ; Object template 5 at (0,4,0)

; Room $BA (row 11, column 10): 128 by 128, cyan
;
; 4 backgrounds and 23 objects in 7 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOMBA:
  DEFB $BA,$27,$28        ; Room $BA; 39 bytes from the next; size 0, colour 5
  DEFB $02                ; Background 2
  DEFB $03                ; Background 3
  DEFB $05                ; Background 5
  DEFB $06                ; Background 6
  DEFB $FF                ; End of the backgrounds
  DEFB $AD,$00,$08,$10,$28,$30,$38 ; Object template 21 x6 at (0,0,0), (0,1,0),
                                   ; (0,2,0), (0,5,0), (0,6,0), (0,7,0)
  DEFB $0F,$BF,$BE,$7D,$3C,$C7,$47,$87 ; Object template 1 x8 at (7,7,2),
  DEFB $07                             ; (6,7,2), (5,7,1), (4,7,0), (7,0,3),
                                       ; (7,0,1), (7,0,2), (7,0,0)
  DEFB $BB,$B7,$AF,$A7,$9F ; Object template 23 x4 at (7,6,2), (7,5,2),
                           ; (7,4,2), (7,3,2)
  DEFB $10,$F7            ; Object template 2 at (7,6,3)
  DEFB $00,$30            ; Placement nudge $30 for the objects that follow
  DEFB $10,$77            ; Object template 2 at (7,6,1)
  DEFB $19,$37,$B7        ; Object template 3 x2 at (7,6,0), (7,6,2)
  DEFB $D8,$07            ; Object template 27 at (7,0,0)

; Room $C6 (row 12, column 6): 128 by 128, magenta
;
; 4 backgrounds and 30 objects in 5 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOMC6:
  DEFB $C6,$2A,$18        ; Room $C6; 42 bytes from the next; size 0, colour 3
  DEFB $00                ; Background 0
  DEFB $02                ; Background 2
  DEFB $04                ; Background 4
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $0F,$18,$58,$98,$19,$59,$1A,$5A ; Object template 1 x8 at (0,3,0),
  DEFB $9A                             ; (0,3,1), (0,3,2), (1,3,0), (1,3,1),
                                       ; (2,3,0), (2,3,1), (2,3,2)
  DEFB $0F,$1D,$5D,$9D,$1E,$5E,$1F,$5F ; Object template 1 x8 at (5,3,0),
  DEFB $9F                             ; (5,3,1), (5,3,2), (6,3,0), (6,3,1),
                                       ; (7,3,0), (7,3,1), (7,3,2)
  DEFB $0B,$32,$35,$0A,$0D ; Object template 1 x4 at (2,6,0), (5,6,0), (2,1,0),
                           ; (5,1,0)
  DEFB $21,$DB,$5C        ; Object template 4 x2 at (3,3,3), (4,3,1)
  DEFB $BF,$D8,$99,$DA,$1B,$1C,$DD,$9E ; Object template 23 x8 at (0,3,3),
  DEFB $DF                             ; (1,3,2), (2,3,3), (3,3,0), (4,3,0),
                                       ; (5,3,3), (6,3,2), (7,3,3)

; Room $C7 (row 12, column 7): 128 by 128, yellow
;
; 5 backgrounds and 16 objects in 3 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOMC7:
  DEFB $C7,$1B,$30        ; Room $C7; 27 bytes from the next; size 0, colour 6
  DEFB $00                ; Background 0
  DEFB $0B                ; Background 11
  DEFB $0D                ; Background 13
  DEFB $04                ; Background 4
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $0B,$C3,$C4,$D0,$E8 ; Object template 1 x4 at (3,0,3), (4,0,3), (0,2,3),
                           ; (0,5,3)
  DEFB $3E,$00,$28,$68,$A8,$29,$69,$2A ; Object template 7 x7 at (0,0,0),
                                       ; (0,5,0), (0,5,1), (0,5,2), (1,5,0),
                                       ; (1,5,1), (2,5,0)
  DEFB $34,$A9,$6A,$2B,$C0,$80 ; Object template 6 x5 at (1,5,2), (2,5,1),
                               ; (3,5,0), (0,0,3), (0,0,2)

; Room $C8 (row 12, column 8): 128 by 128, yellow
;
; 4 backgrounds and 16 objects in 5 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOMC8:
  DEFB $C8,$1C,$30        ; Room $C8; 28 bytes from the next; size 0, colour 6
  DEFB $00                ; Background 0
  DEFB $02                ; Background 2
  DEFB $04                ; Background 4
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $0D,$3F,$3D,$35,$2D,$2E,$2F ; Object template 1 x6 at (7,7,0), (5,7,0),
                                   ; (5,6,0), (5,5,0), (6,5,0), (7,5,0)
  DEFB $10,$31            ; Object template 2 at (1,6,0)
  DEFB $18,$71            ; Object template 3 at (1,6,1)
  DEFB $3A,$3E,$36,$37    ; Object template 7 x3 at (6,7,0), (6,6,0), (7,6,0)
  DEFB $BC,$7D,$75,$6D,$6E,$6F ; Object template 23 x5 at (5,7,1), (5,6,1),
                               ; (5,5,1), (6,5,1), (7,5,1)

; Room $C9 (row 12, column 9): 128 by 128, magenta
;
; 5 backgrounds and 26 objects in 4 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOMC9:
  DEFB $C9,$26,$18        ; Room $C9; 38 bytes from the next; size 0, colour 3
  DEFB $00                ; Background 0
  DEFB $0B                ; Background 11
  DEFB $0D                ; Background 13
  DEFB $04                ; Background 4
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $09,$C3,$C4        ; Object template 1 x2 at (3,0,3), (4,0,3)
  DEFB $47,$E3,$E4,$9B,$9C,$A3,$A4,$DB ; Object template 8 x8 at (3,4,3),
  DEFB $DC                             ; (4,4,3), (3,3,2), (4,3,2), (3,4,2),
                                       ; (4,4,2), (3,3,3), (4,3,3)
  DEFB $47,$2B,$6B,$2C,$6C,$25,$65,$1D ; Object template 8 x8 at (3,5,0),
  DEFB $5D                             ; (3,5,1), (4,5,0), (4,5,1), (5,4,0),
                                       ; (5,4,1), (5,3,0), (5,3,1)
  DEFB $47,$13,$53,$14,$54,$22,$62,$1A ; Object template 8 x8 at (3,2,0),
  DEFB $5A                             ; (3,2,1), (4,2,0), (4,2,1), (2,4,0),
                                       ; (2,4,1), (2,3,0), (2,3,1)

; Room $D6 (row 13, column 6): 128 by 128, green
;
; 4 backgrounds and 18 objects in 6 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOMD6:
  DEFB $D6,$21,$20        ; Room $D6; 33 bytes from the next; size 0, colour 4
  DEFB $01                ; Background 1
  DEFB $02                ; Background 2
  DEFB $04                ; Background 4
  DEFB $05                ; Background 5
  DEFB $FF                ; End of the backgrounds
  DEFB $AD,$28,$20,$18,$10,$08,$00 ; Object template 21 x6 at (0,5,0), (0,4,0),
                                   ; (0,3,0), (0,2,0), (0,1,0), (0,0,0)
  DEFB $B5,$3A,$3B,$3C,$3D,$3E,$3F ; Object template 22 x6 at (2,7,0), (3,7,0),
                                   ; (4,7,0), (5,7,0), (6,7,0), (7,7,0)
  DEFB $0A,$39,$31,$30    ; Object template 1 x3 at (1,7,0), (1,6,0), (0,6,0)
  DEFB $60,$F8            ; Object template 12 at (0,7,3)
  DEFB $C8,$38            ; Object template 25 at (0,7,0)
  DEFB $00,$30            ; Placement nudge $30 for the objects that follow
  DEFB $78,$38            ; Object template 15 at (0,7,0)

; Room $D7 (row 13, column 7): 128 by 128, cyan
;
; 5 backgrounds and 18 objects in 3 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOMD7:
  DEFB $D7,$1D,$28        ; Room $D7; 29 bytes from the next; size 0, colour 5
  DEFB $00                ; Background 0
  DEFB $02                ; Background 2
  DEFB $03                ; Background 3
  DEFB $06                ; Background 6
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $7F,$3D,$35,$2D,$25,$1D,$15,$0D ; Object template 15 x8 at (5,7,0),
  DEFB $05                             ; (5,6,0), (5,5,0), (5,4,0), (5,3,0),
                                       ; (5,2,0), (5,1,0), (5,0,0)
  DEFB $7F,$3A,$32,$2A,$29,$28,$10,$11 ; Object template 15 x8 at (2,7,0),
  DEFB $12                             ; (2,6,0), (2,5,0), (1,5,0), (0,5,0),
                                       ; (0,2,0), (1,2,0), (2,2,0)
  DEFB $79,$0A,$02        ; Object template 15 x2 at (2,1,0), (2,0,0)

; Room $D8 (row 13, column 8): 128 by 128, cyan
;
; 5 backgrounds and 6 objects in 3 groups. Positions are cells (U, V, level): U
; and V 0-7, sixteen units a cell from 72; each level twelve units up from the
; floor.
ROOMD8:
  DEFB $D8,$11,$28        ; Room $D8; 17 bytes from the next; size 0, colour 5
  DEFB $00                ; Background 0
  DEFB $01                ; Background 1
  DEFB $02                ; Background 2
  DEFB $04                ; Background 4
  DEFB $07                ; Background 7
  DEFB $FF                ; End of the backgrounds
  DEFB $0B,$23,$24,$1B,$1C ; Object template 1 x4 at (3,4,0), (4,4,0), (3,3,0),
                           ; (4,3,0)
  DEFB $E8,$63            ; Object template 29 at (3,4,1)
  DEFB $E0,$15            ; Object template 28 at (5,2,0)

; Room $D9 (row 13, column 9): 128 by 128, green
;
; 4 backgrounds and 22 objects in 8 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOMD9:
  DEFB $D9,$27,$20        ; Room $D9; 39 bytes from the next; size 0, colour 4
  DEFB $02                ; Background 2
  DEFB $03                ; Background 3
  DEFB $05                ; Background 5
  DEFB $06                ; Background 6
  DEFB $FF                ; End of the backgrounds
  DEFB $F0,$1B            ; Object template 30 at (3,3,0)
  DEFB $F8,$00            ; Switch to the second page of object templates
  DEFB $28,$09            ; Object template 5 at (1,1,0)
  DEFB $08,$08            ; Object template 1 at (0,1,0)
  DEFB $10,$11            ; Object template 2 at (1,2,0)
  DEFB $18,$0A            ; Object template 3 at (2,1,0)
  DEFB $20,$01            ; Object template 4 at (1,0,0)
  DEFB $37,$3B,$3C,$3D,$3E,$34,$35,$36 ; Object template 6 x8 at (3,7,0),
  DEFB $37                             ; (4,7,0), (5,7,0), (6,7,0), (4,6,0),
                                       ; (5,6,0), (6,6,0), (7,6,0)
  DEFB $37,$2C,$2D,$2E,$2F,$25,$26,$27 ; Object template 6 x8 at (4,5,0),
  DEFB $1F                             ; (5,5,0), (6,5,0), (7,5,0), (5,4,0),
                                       ; (6,4,0), (7,4,0), (7,3,0)

; Room $E7 (row 14, column 7): 64 by 128, yellow
;
; 3 backgrounds and 18 objects in 5 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOME7:
  DEFB $E7,$1F,$70        ; Room $E7; 31 bytes from the next; size 1, colour 6
  DEFB $00                ; Background 0
  DEFB $02                ; Background 2
  DEFB $08                ; Background 8
  DEFB $FF                ; End of the backgrounds
  DEFB $0F,$1A,$1B,$1C,$1D,$5A,$5B,$5C ; Object template 1 x8 at (2,3,0),
  DEFB $5D                             ; (3,3,0), (4,3,0), (5,3,0), (2,3,1),
                                       ; (3,3,1), (4,3,1), (5,3,1)
  DEFB $09,$2B,$2C        ; Object template 1 x2 at (3,5,0), (4,5,0)
  DEFB $7B,$9A,$9B,$9C,$9D ; Object template 15 x4 at (2,3,2), (3,3,2),
                           ; (4,3,2), (5,3,2)
  DEFB $21,$CC,$0B        ; Object template 4 x2 at (4,1,3), (3,1,0)
  DEFB $00,$30            ; Placement nudge $30 for the objects that follow
  DEFB $39,$6B,$6C        ; Object template 7 x2 at (3,5,1), (4,5,1)

; Room $E8 (row 14, column 8): 64 by 128, yellow
;
; 3 backgrounds and 0 objects in 0 groups. Positions are cells (U, V, level): U
; and V 0-7, sixteen units a cell from 72; each level twelve units up from the
; floor.
ROOME8:
  DEFB $E8,$05,$70        ; Room $E8; 5 bytes from the next; size 1, colour 6
  DEFB $00                ; Background 0
  DEFB $02                ; Background 2
  DEFB $08                ; Background 8

; Room $F7 (row 15, column 7): 128 by 128, magenta
;
; 6 backgrounds and 14 objects in 6 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOMF7:
  DEFB $F7,$1F,$18        ; Room $F7; 31 bytes from the next; size 0, colour 3
  DEFB $0A                ; Background 10
  DEFB $0B                ; Background 11
  DEFB $0C                ; Background 12
  DEFB $0D                ; Background 13
  DEFB $04                ; Background 4
  DEFB $05                ; Background 5
  DEFB $FF                ; End of the backgrounds
  DEFB $0F,$C3,$C4,$85,$46,$07,$DF,$E7 ; Object template 1 x8 at (3,0,3),
  DEFB $F8                             ; (4,0,3), (5,0,2), (6,0,1), (7,0,0),
                                       ; (7,3,3), (7,4,3), (0,7,3)
  DEFB $41,$EF,$EE        ; Object template 8 x2 at (7,5,3), (6,5,3)
  DEFB $70,$F3            ; Object template 14 at (3,6,3)
  DEFB $00,$30            ; Placement nudge $30 for the objects that follow
  DEFB $30,$28            ; Object template 6 at (0,5,0)
  DEFB $28,$18            ; Object template 5 at (0,3,0)
  DEFB $48,$40            ; Object template 9 at (0,0,1)

; Room $F8 (row 15, column 8): 128 by 128, magenta
;
; 4 backgrounds and 18 objects in 6 groups. Positions are cells (U, V, level):
; U and V 0-7, sixteen units a cell from 72; each level twelve units up from
; the floor.
ROOMF8:
  DEFB $F8,$1F,$18        ; Room $F8; 31 bytes from the next; size 0, colour 3
  DEFB $02                ; Background 2
  DEFB $03                ; Background 3
  DEFB $05                ; Background 5
  DEFB $06                ; Background 6
  DEFB $FF                ; End of the backgrounds
  DEFB $AD,$38,$30,$28,$10,$08,$00 ; Object template 21 x6 at (0,7,0), (0,6,0),
                                   ; (0,5,0), (0,2,0), (0,1,0), (0,0,0)
  DEFB $09,$36,$76        ; Object template 1 x2 at (6,6,0), (6,6,1)
  DEFB $31,$3D,$2F        ; Object template 6 x2 at (5,7,0), (7,5,0)
  DEFB $D8,$B6            ; Object template 27 at (6,6,2)
  DEFB $BD,$3C,$27,$2C,$25,$26,$35 ; Object template 23 x6 at (4,7,0), (7,4,0),
                                   ; (4,5,0), (5,4,0), (6,4,0), (5,6,0)
  DEFB $88,$6D            ; Object template 17 at (5,5,1)

; Object template table
;
; A word per object template, the group header's bits 3-7 doubled as the index
; (BUILD_ROOM), in two pages: the builder keeps the page it is reading in
; TEMPLATES_AT, and template 31 moves it on by 64 bytes, to the second, which
; has seven. Templates 0 and 31 of each page are not templates, so their words
; are zero.
;
; A template is a list of five-byte pieces -- graphic, the half-sizes in U and
; V, the height, flags -- each copied to +0 and +4 to +7 of an object record at
; the group's position, for as long as the byte after a piece is not zero.
OBJECT_TABLE:
  DEFW $0000              ; Template 0: none (a header with template 0 sets the
                          ; placement nudge)
  DEFW OBJECT1            ; Template 1
  DEFW OBJECT2            ; Template 2
  DEFW OBJECT3            ; Template 3
  DEFW OBJECT4            ; Template 4
  DEFW OBJECT5            ; Template 5
  DEFW OBJECT6            ; Template 6
  DEFW OBJECT7            ; Template 7
  DEFW OBJECT8            ; Template 8
  DEFW OBJECT9            ; Template 9
  DEFW OBJECT10           ; Template 10
  DEFW OBJECT11           ; Template 11
  DEFW OBJECT12           ; Template 12
  DEFW OBJECT13           ; Template 13
  DEFW OBJECT14           ; Template 14
  DEFW OBJECT15           ; Template 15
  DEFW OBJECT16           ; Template 16
  DEFW OBJECT17           ; Template 17
  DEFW OBJECT18           ; Template 18
  DEFW OBJECT19           ; Template 19
  DEFW OBJECT20           ; Template 20
  DEFW OBJECT21           ; Template 21
  DEFW OBJECT22           ; Template 22
  DEFW OBJECT23           ; Template 23
  DEFW OBJECT24           ; Template 24
  DEFW OBJECT25           ; Template 25
  DEFW OBJECT26           ; Template 26
  DEFW OBJECT27           ; Template 27
  DEFW OBJECT28           ; Template 28
  DEFW OBJECT29           ; Template 29
  DEFW OBJECT30           ; Template 30
  DEFW $0000              ; Template 31: none (a header with template 31 moves
                          ; on to the second page)
  DEFW $0000              ; Template 2:0: none (the second page's template 0 is
                          ; the nudge)
  DEFW OBJECT33           ; Template 2:1
  DEFW OBJECT34           ; Template 2:2
  DEFW OBJECT35           ; Template 2:3
  DEFW OBJECT36           ; Template 2:4
  DEFW OBJECT37           ; Template 2:5
  DEFW OBJECT38           ; Template 2:6
  DEFW OBJECT39           ; Template 2:7

; Object template 1: graphic 30
OBJECT1:
  DEFB $1E,$08,$08,$0C,$10 ; Graphic 30; half-sizes 8, 8, height 12; flags $10
  DEFB $00                ; End of the template

; Object template 2: graphic 28
OBJECT2:
  DEFB $1C,$07,$07,$0C,$14 ; Graphic 28; half-sizes 7, 7, height 12; flags $14
  DEFB $00                ; End of the template

; Object template 3: graphic 29
OBJECT3:
  DEFB $1D,$07,$07,$0C,$14 ; Graphic 29; half-sizes 7, 7, height 12; flags $14
  DEFB $00                ; End of the template

; Object template 4: graphic 31
OBJECT4:
  DEFB $1F,$08,$08,$0C,$14 ; Graphic 31; half-sizes 8, 8, height 12; flags $14
  DEFB $00                ; End of the template

; Object template 5: graphic 44
OBJECT5:
  DEFB $2C,$08,$08,$0C,$10 ; Graphic 44; half-sizes 8, 8, height 12; flags $10
  DEFB $00                ; End of the template

; Object template 6: graphic 45
OBJECT6:
  DEFB $2D,$08,$08,$0C,$10 ; Graphic 45; half-sizes 8, 8, height 12; flags $10
  DEFB $00                ; End of the template

; Object template 7: graphic 46
OBJECT7:
  DEFB $2E,$08,$08,$0C,$10 ; Graphic 46; half-sizes 8, 8, height 12; flags $10
  DEFB $00                ; End of the template

; Object template 8: graphic 68
OBJECT8:
  DEFB $44,$08,$08,$0C,$10 ; Graphic 68; half-sizes 8, 8, height 12; flags $10
  DEFB $00                ; End of the template

; Object template 9: graphic 69
OBJECT9:
  DEFB $45,$08,$08,$0C,$10 ; Graphic 69; half-sizes 8, 8, height 12; flags $10
  DEFB $00                ; End of the template

; Object template 10: graphic 70
OBJECT10:
  DEFB $46,$08,$08,$0C,$10 ; Graphic 70; half-sizes 8, 8, height 12; flags $10
  DEFB $00                ; End of the template

; Object template 11: graphic 71
OBJECT11:
  DEFB $47,$08,$08,$0C,$10 ; Graphic 71; half-sizes 8, 8, height 12; flags $10
  DEFB $00                ; End of the template

; Object template 12: graphic 47
OBJECT12:
  DEFB $2F,$08,$08,$0C,$14 ; Graphic 47; half-sizes 8, 8, height 12; flags $14
  DEFB $00                ; End of the template

; Object template 13: graphic 66
OBJECT13:
  DEFB $42,$08,$08,$0C,$10 ; Graphic 66; half-sizes 8, 8, height 12; flags $10
  DEFB $00                ; End of the template

; Object template 14: graphic 67
OBJECT14:
  DEFB $43,$08,$08,$0C,$10 ; Graphic 67; half-sizes 8, 8, height 12; flags $10
  DEFB $00                ; End of the template

; Object template 15: graphic 72
OBJECT15:
  DEFB $48,$08,$08,$0C,$10 ; Graphic 72; half-sizes 8, 8, height 12; flags $10
  DEFB $00                ; End of the template

; Object template 16: graphic 76
OBJECT16:
  DEFB $4C,$08,$08,$0C,$10 ; Graphic 76; half-sizes 8, 8, height 12; flags $10
  DEFB $00                ; End of the template

; Object template 18: graphics 86, 11
OBJECT18:
  DEFB $56,$07,$07,$0C,$10 ; Graphic 86; half-sizes 7, 7, height 12; flags $10
  DEFB $0B,$07,$07,$0C,$10 ; Graphic 11; half-sizes 7, 7, height 12; flags $10
  DEFB $00                ; End of the template

; Object template 19: graphics 87, 11
OBJECT19:
  DEFB $57,$07,$07,$0C,$50 ; Graphic 87; half-sizes 7, 7, height 12; flags $50
  DEFB $0B,$07,$07,$0C,$50 ; Graphic 11; half-sizes 7, 7, height 12; flags $50
  DEFB $00                ; End of the template

; Object template 17: graphics 94, 11
OBJECT17:
  DEFB $5E,$07,$07,$0C,$10 ; Graphic 94; half-sizes 7, 7, height 12; flags $10
  DEFB $0B,$07,$07,$0C,$10 ; Graphic 11; half-sizes 7, 7, height 12; flags $10
  DEFB $00                ; End of the template

; Object template 20: graphic 73
OBJECT20:
  DEFB $49,$08,$08,$0C,$14 ; Graphic 73; half-sizes 8, 8, height 12; flags $14
  DEFB $00                ; End of the template

; Object template 21: graphic 74
OBJECT21:
  DEFB $4A,$08,$08,$18,$10 ; Graphic 74; half-sizes 8, 8, height 24; flags $10
  DEFB $00                ; End of the template

; Object template 22: graphic 74
OBJECT22:
  DEFB $4A,$08,$08,$18,$50 ; Graphic 74; half-sizes 8, 8, height 24; flags $50
  DEFB $00                ; End of the template

; Object template 23: graphic 75
OBJECT23:
  DEFB $4B,$08,$08,$0C,$14 ; Graphic 75; half-sizes 8, 8, height 12; flags $14
  DEFB $00                ; End of the template

; Object template 24: graphics 112, 108
OBJECT24:
  DEFB $70,$08,$08,$0C,$10 ; Graphic 112; half-sizes 8, 8, height 12; flags $10
  DEFB $6C,$08,$08,$0C,$12 ; Graphic 108; half-sizes 8, 8, height 12; flags $12
  DEFB $00                ; End of the template

; Object template 25: graphics 113, 109
OBJECT25:
  DEFB $71,$08,$08,$0C,$10 ; Graphic 113; half-sizes 8, 8, height 12; flags $10
  DEFB $6D,$08,$08,$0C,$12 ; Graphic 109; half-sizes 8, 8, height 12; flags $12
  DEFB $00                ; End of the template

; Object template 26: graphics 114, 110
OBJECT26:
  DEFB $72,$08,$08,$0C,$10 ; Graphic 114; half-sizes 8, 8, height 12; flags $10
  DEFB $6E,$08,$08,$0C,$12 ; Graphic 110; half-sizes 8, 8, height 12; flags $12
  DEFB $00                ; End of the template

; Object template 27: graphics 115, 111
OBJECT27:
  DEFB $73,$08,$08,$0C,$10 ; Graphic 115; half-sizes 8, 8, height 12; flags $10
  DEFB $6F,$08,$08,$0C,$12 ; Graphic 111; half-sizes 8, 8, height 12; flags $12
  DEFB $00                ; End of the template

; Object template 28: graphic 116
OBJECT28:
  DEFB $74,$07,$07,$0C,$10 ; Graphic 116; half-sizes 7, 7, height 12; flags $10
  DEFB $00                ; End of the template

; Object template 29: graphic 120
OBJECT29:
  DEFB $78,$06,$06,$0C,$10 ; Graphic 120; half-sizes 6, 6, height 12; flags $10
  DEFB $00                ; End of the template

; Object template 30: graphic 124
OBJECT30:
  DEFB $7C,$07,$07,$0C,$10 ; Graphic 124; half-sizes 7, 7, height 12; flags $10
  DEFB $00                ; End of the template

; Object template 2:1: graphic 122
OBJECT33:
  DEFB $7A,$08,$08,$0C,$10 ; Graphic 122; half-sizes 8, 8, height 12; flags $10
  DEFB $00                ; End of the template

; Object template 2:2: graphic 122
OBJECT34:
  DEFB $7A,$08,$08,$0C,$50 ; Graphic 122; half-sizes 8, 8, height 12; flags $50
  DEFB $00                ; End of the template

; Object template 2:3: graphic 123
OBJECT35:
  DEFB $7B,$08,$08,$0C,$10 ; Graphic 123; half-sizes 8, 8, height 12; flags $10
  DEFB $00                ; End of the template

; Object template 2:4: graphic 123
OBJECT36:
  DEFB $7B,$08,$08,$0C,$50 ; Graphic 123; half-sizes 8, 8, height 12; flags $50
  DEFB $00                ; End of the template

; Object template 2:5: graphic 128
OBJECT37:
  DEFB $80,$08,$08,$0C,$10 ; Graphic 128; half-sizes 8, 8, height 12; flags $10
  DEFB $00                ; End of the template

; Object template 2:6: graphic 129
OBJECT38:
  DEFB $81,$07,$07,$0C,$14 ; Graphic 129; half-sizes 7, 7, height 12; flags $14
  DEFB $00                ; End of the template

; Object template 2:7: graphic 130
OBJECT39:
  DEFB $82,$08,$08,$0C,$10 ; Graphic 130; half-sizes 8, 8, height 12; flags $10
  DEFB $00                ; End of the template

; Background table
;
; A word per background, a room's background byte doubled as the index
; (BUILD_ROOM). A background is a list of eight-byte pieces -- graphic, U, V,
; Z, the half-sizes, the height, flags -- each copied to +0 to +7 of an object
; record, ended by a zero.
BACKGROUND_TABLE:
  DEFW BACKGROUND0        ; Background 0
  DEFW BACKGROUND1        ; Background 1
  DEFW BACKGROUND2        ; Background 2
  DEFW BACKGROUND3        ; Background 3
  DEFW BACKGROUND4        ; Background 4
  DEFW BACKGROUND5        ; Background 5
  DEFW BACKGROUND6        ; Background 6
  DEFW BACKGROUND7        ; Background 7
  DEFW BACKGROUND8        ; Background 8
  DEFW BACKGROUND9        ; Background 9
  DEFW BACKGROUND10       ; Background 10
  DEFW BACKGROUND11       ; Background 11
  DEFW BACKGROUND12       ; Background 12
  DEFW BACKGROUND13       ; Background 13

; Background 0
;
; 2 pieces.
BACKGROUND0:
  DEFB $02,$8D,$C5,$40,$03,$06,$30,$50 ; Graphic 2 at U 141, V 197, Z 64;
                                       ; half-sizes 3, 6, height 48; flags $50
  DEFB $03,$73,$C5,$40,$03,$06,$30,$50 ; Graphic 3 at U 115, V 197, Z 64;
                                       ; half-sizes 3, 6, height 48; flags $50
  DEFB $00                ; End of the background

; Background 1
;
; 2 pieces.
BACKGROUND1:
  DEFB $02,$C5,$73,$40,$06,$03,$30,$10 ; Graphic 2 at U 197, V 115, Z 64;
                                       ; half-sizes 6, 3, height 48; flags $10
  DEFB $03,$C5,$8D,$40,$06,$03,$30,$10 ; Graphic 3 at U 197, V 141, Z 64;
                                       ; half-sizes 6, 3, height 48; flags $10
  DEFB $00                ; End of the background

; Background 10
;
; 2 pieces.
BACKGROUND10:
  DEFB $02,$C5,$73,$70,$06,$03,$30,$10 ; Graphic 2 at U 197, V 115, Z 112;
                                       ; half-sizes 6, 3, height 48; flags $10
  DEFB $03,$C5,$8D,$70,$06,$03,$30,$10 ; Graphic 3 at U 197, V 141, Z 112;
                                       ; half-sizes 6, 3, height 48; flags $10
  DEFB $00                ; End of the background

; Background 12
;
; 2 pieces.
BACKGROUND12:
  DEFB $1E,$C8,$78,$64,$08,$08,$0C,$10 ; Graphic 30 at U 200, V 120, Z 100;
                                       ; half-sizes 8, 8, height 12; flags $10
  DEFB $1E,$C8,$88,$64,$08,$08,$0C,$10 ; Graphic 30 at U 200, V 136, Z 100;
                                       ; half-sizes 8, 8, height 12; flags $10
  DEFB $00                ; End of the background

; Background 2
;
; 2 pieces.
BACKGROUND2:
  DEFB $02,$8D,$3B,$40,$03,$06,$30,$50 ; Graphic 2 at U 141, V 59, Z 64;
                                       ; half-sizes 3, 6, height 48; flags $50
  DEFB $03,$73,$3B,$40,$03,$06,$30,$50 ; Graphic 3 at U 115, V 59, Z 64;
                                       ; half-sizes 3, 6, height 48; flags $50
  DEFB $00                ; End of the background

; Background 11
;
; 2 pieces.
BACKGROUND11:
  DEFB $02,$8D,$3B,$70,$03,$06,$30,$50 ; Graphic 2 at U 141, V 59, Z 112;
                                       ; half-sizes 3, 6, height 48; flags $50
  DEFB $03,$73,$3B,$70,$03,$06,$30,$50 ; Graphic 3 at U 115, V 59, Z 112;
                                       ; half-sizes 3, 6, height 48; flags $50
  DEFB $00                ; End of the background

; Background 13
;
; 2 pieces.
BACKGROUND13:
  DEFB $1E,$78,$38,$64,$08,$08,$0C,$10 ; Graphic 30 at U 120, V 56, Z 100;
                                       ; half-sizes 8, 8, height 12; flags $10
  DEFB $1E,$88,$38,$64,$08,$08,$0C,$10 ; Graphic 30 at U 136, V 56, Z 100;
                                       ; half-sizes 8, 8, height 12; flags $10
  DEFB $00                ; End of the background

; Background 3
;
; 2 pieces.
BACKGROUND3:
  DEFB $02,$3B,$73,$40,$06,$03,$30,$10 ; Graphic 2 at U 59, V 115, Z 64;
                                       ; half-sizes 6, 3, height 48; flags $10
  DEFB $03,$3B,$8D,$40,$06,$03,$30,$10 ; Graphic 3 at U 59, V 141, Z 64;
                                       ; half-sizes 6, 3, height 48; flags $10
  DEFB $00                ; End of the background

; Background 4
;
; 6 pieces.
BACKGROUND4:
  DEFB $0E,$40,$44,$40,$00,$04,$30,$50 ; Graphic 14 at U 64, V 68, Z 64;
                                       ; half-sizes 0, 4, height 48; flags $50
  DEFB $0D,$40,$54,$40,$00,$0C,$30,$50 ; Graphic 13 at U 64, V 84, Z 64;
                                       ; half-sizes 0, 12, height 48; flags $50
  DEFB $0D,$40,$6C,$40,$00,$0C,$30,$50 ; Graphic 13 at U 64, V 108, Z 64;
                                       ; half-sizes 0, 12, height 48; flags $50
  DEFB $0D,$40,$84,$40,$00,$0C,$30,$50 ; Graphic 13 at U 64, V 132, Z 64;
                                       ; half-sizes 0, 12, height 48; flags $50
  DEFB $0D,$40,$9C,$40,$00,$0C,$30,$50 ; Graphic 13 at U 64, V 156, Z 64;
                                       ; half-sizes 0, 12, height 48; flags $50
  DEFB $0D,$40,$B4,$40,$00,$0C,$30,$50 ; Graphic 13 at U 64, V 180, Z 64;
                                       ; half-sizes 0, 12, height 48; flags $50
  DEFB $00                ; End of the background

; Background 5
;
; 6 pieces.
BACKGROUND5:
  DEFB $0D,$4C,$C0,$40,$0C,$00,$30,$10 ; Graphic 13 at U 76, V 192, Z 64;
                                       ; half-sizes 12, 0, height 48; flags $10
  DEFB $0D,$64,$C0,$40,$0C,$00,$30,$10 ; Graphic 13 at U 100, V 192, Z 64;
                                       ; half-sizes 12, 0, height 48; flags $10
  DEFB $0D,$7C,$C0,$40,$0C,$00,$30,$10 ; Graphic 13 at U 124, V 192, Z 64;
                                       ; half-sizes 12, 0, height 48; flags $10
  DEFB $0D,$94,$C0,$40,$0C,$00,$30,$10 ; Graphic 13 at U 148, V 192, Z 64;
                                       ; half-sizes 12, 0, height 48; flags $10
  DEFB $0D,$AC,$C0,$40,$0C,$00,$30,$10 ; Graphic 13 at U 172, V 192, Z 64;
                                       ; half-sizes 12, 0, height 48; flags $10
  DEFB $0E,$BC,$C0,$40,$04,$00,$30,$10 ; Graphic 14 at U 188, V 192, Z 64;
                                       ; half-sizes 4, 0, height 48; flags $10
  DEFB $00                ; End of the background

; Background 6
;
; 4 pieces.
BACKGROUND6:
  DEFB $0D,$40,$4C,$40,$00,$0C,$30,$50 ; Graphic 13 at U 64, V 76, Z 64;
                                       ; half-sizes 0, 12, height 48; flags $50
  DEFB $0D,$40,$64,$40,$00,$0C,$30,$50 ; Graphic 13 at U 64, V 100, Z 64;
                                       ; half-sizes 0, 12, height 48; flags $50
  DEFB $0D,$40,$9C,$40,$00,$0C,$30,$50 ; Graphic 13 at U 64, V 156, Z 64;
                                       ; half-sizes 0, 12, height 48; flags $50
  DEFB $0D,$40,$B4,$40,$00,$0C,$30,$50 ; Graphic 13 at U 64, V 180, Z 64;
                                       ; half-sizes 0, 12, height 48; flags $50
  DEFB $00                ; End of the background

; Background 7
;
; 4 pieces.
BACKGROUND7:
  DEFB $0D,$4C,$C0,$40,$0C,$00,$30,$10 ; Graphic 13 at U 76, V 192, Z 64;
                                       ; half-sizes 12, 0, height 48; flags $10
  DEFB $0D,$64,$C0,$40,$0C,$00,$30,$10 ; Graphic 13 at U 100, V 192, Z 64;
                                       ; half-sizes 12, 0, height 48; flags $10
  DEFB $0D,$9C,$C0,$40,$0C,$00,$30,$10 ; Graphic 13 at U 156, V 192, Z 64;
                                       ; half-sizes 12, 0, height 48; flags $10
  DEFB $0D,$B4,$C0,$40,$0C,$00,$30,$10 ; Graphic 13 at U 180, V 192, Z 64;
                                       ; half-sizes 12, 0, height 48; flags $10
  DEFB $00                ; End of the background

; Background 8
;
; 8 pieces.
BACKGROUND8:
  DEFB $0E,$60,$44,$40,$00,$04,$30,$50 ; Graphic 14 at U 96, V 68, Z 64;
                                       ; half-sizes 0, 4, height 48; flags $50
  DEFB $0D,$60,$54,$40,$00,$0C,$30,$50 ; Graphic 13 at U 96, V 84, Z 64;
                                       ; half-sizes 0, 12, height 48; flags $50
  DEFB $0D,$60,$6C,$40,$00,$0C,$30,$50 ; Graphic 13 at U 96, V 108, Z 64;
                                       ; half-sizes 0, 12, height 48; flags $50
  DEFB $0D,$60,$84,$40,$00,$0C,$30,$50 ; Graphic 13 at U 96, V 132, Z 64;
                                       ; half-sizes 0, 12, height 48; flags $50
  DEFB $0D,$60,$9C,$40,$00,$0C,$30,$50 ; Graphic 13 at U 96, V 156, Z 64;
                                       ; half-sizes 0, 12, height 48; flags $50
  DEFB $0D,$60,$B4,$40,$00,$0C,$30,$50 ; Graphic 13 at U 96, V 180, Z 64;
                                       ; half-sizes 0, 12, height 48; flags $50
  DEFB $0F,$68,$C0,$40,$04,$00,$30,$10 ; Graphic 15 at U 104, V 192, Z 64;
                                       ; half-sizes 4, 0, height 48; flags $10
  DEFB $0F,$98,$C0,$40,$04,$00,$30,$10 ; Graphic 15 at U 152, V 192, Z 64;
                                       ; half-sizes 4, 0, height 48; flags $10
  DEFB $00                ; End of the background

; Background 9
;
; 8 pieces.
BACKGROUND9:
  DEFB $0D,$4C,$A0,$40,$0C,$00,$30,$10 ; Graphic 13 at U 76, V 160, Z 64;
                                       ; half-sizes 12, 0, height 48; flags $10
  DEFB $0D,$64,$A0,$40,$0C,$00,$30,$10 ; Graphic 13 at U 100, V 160, Z 64;
                                       ; half-sizes 12, 0, height 48; flags $10
  DEFB $0D,$7C,$A0,$40,$0C,$00,$30,$10 ; Graphic 13 at U 124, V 160, Z 64;
                                       ; half-sizes 12, 0, height 48; flags $10
  DEFB $0D,$94,$A0,$40,$0C,$00,$30,$10 ; Graphic 13 at U 148, V 160, Z 64;
                                       ; half-sizes 12, 0, height 48; flags $10
  DEFB $0D,$AC,$A0,$40,$0C,$00,$30,$10 ; Graphic 13 at U 172, V 160, Z 64;
                                       ; half-sizes 12, 0, height 48; flags $10
  DEFB $0E,$BC,$A0,$40,$04,$00,$30,$10 ; Graphic 14 at U 188, V 160, Z 64;
                                       ; half-sizes 4, 0, height 48; flags $10
  DEFB $0F,$40,$68,$40,$00,$04,$30,$50 ; Graphic 15 at U 64, V 104, Z 64;
                                       ; half-sizes 0, 4, height 48; flags $50
  DEFB $0F,$40,$98,$40,$00,$04,$30,$50 ; Graphic 15 at U 64, V 152, Z 64;
                                       ; half-sizes 0, 4, height 48; flags $50
  DEFB $00                ; End of the background

; Where the valves can lie
;
; Thirty-six records of nine bytes: the places a valve can lie. At a new game
; INIT_SPECIAL_OBJECTS gives each a graphic -- a valve of one of the four kinds
; (96-99, chosen from the random number), or, now and then, an extra life
; (graphic 12) -- and copies the place in +1 to +4 (U, V, Z and room, from the
; tape) to +5 to +8, where it is kept from then on: FIND_SPECIAL_OBJS_HERE puts
; what lies in a room into the two records at VALVES as the room is built, and
; UPDATE_SPECIAL_OBJS writes them back when it is left. On the tape the
; graphics and the second halves are zero.
PLACES:
  DEFB $00                ; Place 0: room $04, U 120, V 120, Z 76
  DEFB $78,$78,$4C,$04    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00                ; Place 1: room $05, U 120, V 120, Z 148
  DEFB $78,$78,$94,$05    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00                ; Place 2: room $0B, U 184, V 184, Z 100
  DEFB $B8,$B8,$64,$0B    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00                ; Place 3: room $0D, U 120, V 136, Z 124
  DEFB $78,$88,$7C,$0D    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00                ; Place 4: room $15, U 136, V 136, Z 112
  DEFB $88,$88,$70,$15    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00                ; Place 5: room $1B, U 152, V 120, Z 136
  DEFB $98,$78,$88,$1B    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00                ; Place 6: room $1C, U 136, V 120, Z 88
  DEFB $88,$78,$58,$1C    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00                ; Place 7: room $20, U 128, V 120, Z 112
  DEFB $80,$78,$70,$20    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00                ; Place 8: room $27, U 72, V 136, Z 64
  DEFB $48,$88,$40,$27    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00                ; Place 9: room $2F, U 184, V 120, Z 100
  DEFB $B8,$78,$64,$2F    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00                ; Place 10: room $30, U 72, V 184, Z 112
  DEFB $48,$B8,$70,$30    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00                ; Place 11: room $34, U 104, V 168, Z 64
  DEFB $68,$A8,$40,$34    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00                ; Place 12: room $37, U 184, V 88, Z 76
  DEFB $B8,$58,$4C,$37    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00                ; Place 13: room $39, U 184, V 72, Z 88
  DEFB $B8,$48,$58,$39    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00                ; Place 14: room $3E, U 120, V 136, Z 148
  DEFB $78,$88,$94,$3E    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00                ; Place 15: room $45, U 128, V 152, Z 100
  DEFB $80,$98,$64,$45    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00                ; Place 16: room $46, U 184, V 128, Z 112
  DEFB $B8,$80,$70,$46    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00                ; Place 17: room $56, U 128, V 184, Z 64
  DEFB $80,$B8,$40,$56    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00                ; Place 18: room $58, U 128, V 128, Z 76
  DEFB $80,$80,$4C,$58    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00                ; Place 19: room $59, U 136, V 120, Z 124
  DEFB $88,$78,$7C,$59    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00                ; Place 20: room $61, U 168, V 168, Z 124
  DEFB $A8,$A8,$7C,$61    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00                ; Place 21: room $64, U 72, V 120, Z 100
  DEFB $48,$78,$64,$64    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00                ; Place 22: room $6A, U 72, V 72, Z 64
  DEFB $48,$48,$40,$6A    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00                ; Place 23: room $6B, U 184, V 184, Z 112
  DEFB $B8,$B8,$70,$6B    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00                ; Place 24: room $75, U 128, V 152, Z 124
  DEFB $80,$98,$7C,$75    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00                ; Place 25: room $7B, U 184, V 104, Z 64
  DEFB $B8,$68,$40,$7B    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00                ; Place 26: room $87, U 120, V 136, Z 64
  DEFB $78,$88,$40,$87    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00                ; Place 27: room $8A, U 128, V 128, Z 64
  DEFB $80,$80,$40,$8A    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00                ; Place 28: room $95, U 104, V 120, Z 88
  DEFB $68,$78,$58,$95    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00                ; Place 29: room $9A, U 184, V 184, Z 112
  DEFB $B8,$B8,$70,$9A    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00                ; Place 30: room $9C, U 184, V 184, Z 76
  DEFB $B8,$B8,$4C,$9C    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00                ; Place 31: room $A9, U 120, V 136, Z 64
  DEFB $78,$88,$40,$A9    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00                ; Place 32: room $AB, U 184, V 120, Z 64
  DEFB $B8,$78,$40,$AB    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00                ; Place 33: room $B7, U 128, V 120, Z 76
  DEFB $80,$78,$4C,$B7    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00                ; Place 34: room $C8, U 184, V 184, Z 76
  DEFB $B8,$B8,$4C,$C8    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00                ; Place 35: room $D9, U 184, V 184, Z 64
  DEFB $B8,$B8,$40,$D9    ;
  DEFB $00,$00,$00,$00    ;

; Graphic table
;
; A word per graphic number, the address of its sprite. Numbers 0 and 1 share a
; sprite whose width and height are both zero, which draws nothing.
GRAPHICS:
  DEFW SPRITE0            ; Graphic 0
  DEFW SPRITE0            ; Graphic 1
  DEFW SPRITE2            ; Graphic 2
  DEFW SPRITE3            ; Graphic 3
  DEFW SPRITE4            ; Graphic 4
  DEFW SPRITE5            ; Graphic 5
  DEFW SPRITE6            ; Graphic 6
  DEFW SPRITE7            ; Graphic 7
  DEFW SPRITE8            ; Graphic 8
  DEFW SPRITE9            ; Graphic 9
  DEFW SPRITE10           ; Graphic 10
  DEFW SPRITE11           ; Graphic 11
  DEFW SPRITE12           ; Graphic 12
  DEFW SPRITE13           ; Graphic 13
  DEFW SPRITE14           ; Graphic 14
  DEFW SPRITE15           ; Graphic 15
  DEFW SPRITE16           ; Graphic 16
  DEFW SPRITE17           ; Graphic 17
  DEFW SPRITE18           ; Graphic 18
  DEFW SPRITE17           ; Graphic 19
  DEFW SPRITE20           ; Graphic 20
  DEFW SPRITE21           ; Graphic 21
  DEFW SPRITE22           ; Graphic 22
  DEFW SPRITE21           ; Graphic 23
  DEFW SPRITE24           ; Graphic 24
  DEFW SPRITE25           ; Graphic 25
  DEFW SPRITE26           ; Graphic 26
  DEFW SPRITE26           ; Graphic 27
  DEFW SPRITE28           ; Graphic 28
  DEFW SPRITE29           ; Graphic 29
  DEFW SPRITE30           ; Graphic 30
  DEFW SPRITE30           ; Graphic 31
  DEFW SPRITE32           ; Graphic 32
  DEFW SPRITE33           ; Graphic 33
  DEFW SPRITE34           ; Graphic 34
  DEFW SPRITE33           ; Graphic 35
  DEFW SPRITE36           ; Graphic 36
  DEFW SPRITE37           ; Graphic 37
  DEFW SPRITE38           ; Graphic 38
  DEFW SPRITE37           ; Graphic 39
  DEFW SPRITE40           ; Graphic 40
  DEFW SPRITE41           ; Graphic 41
  DEFW SPRITE42           ; Graphic 42
  DEFW SPRITE42           ; Graphic 43
  DEFW SPRITE30           ; Graphic 44
  DEFW SPRITE30           ; Graphic 45
  DEFW SPRITE46           ; Graphic 46
  DEFW SPRITE30           ; Graphic 47
  DEFW SPRITE48           ; Graphic 48
  DEFW SPRITE49           ; Graphic 49
  DEFW SPRITE48           ; Graphic 50
  DEFW SPRITE49           ; Graphic 51
  DEFW SPRITE52           ; Graphic 52
  DEFW SPRITE53           ; Graphic 53
  DEFW SPRITE54           ; Graphic 54
  DEFW SPRITE55           ; Graphic 55
  DEFW SPRITE55           ; Graphic 56
  DEFW SPRITE54           ; Graphic 57
  DEFW SPRITE53           ; Graphic 58
  DEFW SPRITE52           ; Graphic 59
  DEFW SPRITE49           ; Graphic 60
  DEFW SPRITE48           ; Graphic 61
  DEFW SPRITE49           ; Graphic 62
  DEFW SPRITE48           ; Graphic 63
  DEFW SPRITE48           ; Graphic 64
  DEFW SPRITE49           ; Graphic 65
  DEFW SPRITE30           ; Graphic 66
  DEFW SPRITE30           ; Graphic 67
  DEFW SPRITE30           ; Graphic 68
  DEFW SPRITE30           ; Graphic 69
  DEFW SPRITE30           ; Graphic 70
  DEFW SPRITE30           ; Graphic 71
  DEFW SPRITE72           ; Graphic 72
  DEFW SPRITE73           ; Graphic 73
  DEFW SPRITE74           ; Graphic 74
  DEFW SPRITE75           ; Graphic 75
  DEFW SPRITE48           ; Graphic 76
  DEFW SPRITE49           ; Graphic 77
  DEFW SPRITE52           ; Graphic 78
  DEFW SPRITE49           ; Graphic 79
  DEFW SPRITE80           ; Graphic 80
  DEFW SPRITE81           ; Graphic 81
  DEFW SPRITE82           ; Graphic 82
  DEFW SPRITE83           ; Graphic 83
  DEFW SPRITE84           ; Graphic 84
  DEFW SPRITE85           ; Graphic 85
  DEFW SPRITE86           ; Graphic 86
  DEFW SPRITE87           ; Graphic 87
  DEFW SPRITE88           ; Graphic 88
  DEFW SPRITE89           ; Graphic 89
  DEFW SPRITE25           ; Graphic 90
  DEFW SPRITE41           ; Graphic 91
  DEFW SPRITE25           ; Graphic 92
  DEFW SPRITE41           ; Graphic 93
  DEFW SPRITE86           ; Graphic 94
  DEFW SPRITE87           ; Graphic 95
  DEFW SPRITE96           ; Graphic 96
  DEFW SPRITE97           ; Graphic 97
  DEFW SPRITE98           ; Graphic 98
  DEFW SPRITE99           ; Graphic 99
  DEFW SPRITE96           ; Graphic 100
  DEFW SPRITE97           ; Graphic 101
  DEFW SPRITE98           ; Graphic 102
  DEFW SPRITE99           ; Graphic 103
  DEFW SPRITE96           ; Graphic 104
  DEFW SPRITE97           ; Graphic 105
  DEFW SPRITE98           ; Graphic 106
  DEFW SPRITE99           ; Graphic 107
  DEFW SPRITE52           ; Graphic 108
  DEFW SPRITE49           ; Graphic 109
  DEFW SPRITE48           ; Graphic 110
  DEFW SPRITE49           ; Graphic 111
  DEFW SPRITE112          ; Graphic 112
  DEFW SPRITE112          ; Graphic 113
  DEFW SPRITE112          ; Graphic 114
  DEFW SPRITE112          ; Graphic 115
  DEFW SPRITE116          ; Graphic 116
  DEFW SPRITE117          ; Graphic 117
  DEFW SPRITE118          ; Graphic 118
  DEFW SPRITE119          ; Graphic 119
  DEFW SPRITE120          ; Graphic 120
  DEFW SPRITE121          ; Graphic 121
  DEFW SPRITE122          ; Graphic 122
  DEFW SPRITE123          ; Graphic 123
  DEFW SPRITE124          ; Graphic 124
  DEFW SPRITE125          ; Graphic 125
  DEFW SPRITE126          ; Graphic 126
  DEFW SPRITE127          ; Graphic 127
  DEFW SPRITE30           ; Graphic 128
  DEFW SPRITE129          ; Graphic 129
  DEFW SPRITE130          ; Graphic 130
  DEFW SPRITE131          ; Graphic 131

; Sprite for graphics 0-1
;
; Width and height both zero: the drawing code sees the zero and draws nothing.
;
; The sprites, end to end from here to the code at START. Each is a width byte
; (bits 0-3 the width in bytes; bits 6 and 7 the mirrored and upside-down
; flags, toggled in place as objects face about), a height byte, then a mask
; byte and an image byte for each cell, the bottom row first. On the tape every
; sprite is the right way round.
SPRITE0:
  DEFB $00,$00            ; Width and height

; Sprite for graphic 131
;
; 24 by 20 pixels.
SPRITE131:
  DEFB $03,$14            ; Width in bytes, and height in rows
  DEFB $03,$00,$FF,$7E,$C0,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $0F,$03,$FF,$81,$F0,$C0 ; bottom row first
  DEFB $1F,$0C,$FF,$7E,$F8,$30 ;
  DEFB $3F,$13,$FF,$FF,$FC,$C8 ;
  DEFB $7F,$23,$FF,$FF,$FE,$F4 ;
  DEFB $7F,$11,$FF,$FF,$FE,$F8 ;
  DEFB $7F,$39,$FF,$FF,$FE,$FC ;
  DEFB $3F,$1C,$FF,$C3,$FC,$F8 ;
  DEFB $3F,$0F,$FF,$3C,$F8,$F0 ;
  DEFB $0F,$04,$FF,$FF,$F0,$60 ;
  DEFB $07,$02,$FF,$FF,$E0,$80 ;
  DEFB $07,$02,$FF,$FF,$E0,$C0 ;
  DEFB $07,$02,$FF,$C3,$E0,$C0 ;
  DEFB $07,$02,$FF,$3C,$E0,$C0 ;
  DEFB $07,$02,$FF,$FF,$E0,$40 ;
  DEFB $07,$01,$FF,$BD,$E0,$80 ;
  DEFB $07,$03,$FF,$3C,$E0,$C0 ;
  DEFB $03,$01,$FF,$E7,$C0,$80 ;
  DEFB $01,$00,$FF,$E7,$80,$00 ;
  DEFB $00,$00,$FF,$3C,$00,$00 ;

; Sprite for graphic 85
;
; 40 by 35 pixels.
SPRITE85:
  DEFB $05,$23            ; Width in bytes, and height in rows
  DEFB $00,$00,$78,$00,$00,$00,$1E,$00,$00,$00 ; Mask and image bytes, a pair
  DEFB $00,$00,$FC,$78,$00,$00,$3F,$1E,$00,$00 ; per cell, the bottom row first
  DEFB $00,$00,$FC,$78,$00,$00,$3F,$1E,$00,$00 ;
  DEFB $00,$00,$7E,$3C,$00,$00,$7E,$3C,$00,$00 ;
  DEFB $00,$00,$3F,$1E,$FF,$00,$FC,$78,$00,$00 ;
  DEFB $00,$00,$3F,$11,$FF,$DF,$FF,$88,$00,$00 ;
  DEFB $00,$00,$3F,$0F,$FF,$3F,$FC,$F0,$00,$00 ;
  DEFB $00,$00,$FF,$3E,$FF,$7F,$FF,$FC,$00,$00 ;
  DEFB $01,$00,$FF,$FC,$FF,$FF,$FF,$FF,$80,$00 ;
  DEFB $03,$01,$FF,$F9,$FF,$FF,$FF,$FF,$C0,$80 ;
  DEFB $07,$03,$FF,$F3,$FF,$FF,$FF,$FF,$E0,$C0 ;
  DEFB $0F,$07,$FF,$E7,$FF,$FF,$FF,$FF,$F0,$E0 ;
  DEFB $0F,$07,$FF,$C7,$FF,$FF,$FF,$FF,$F0,$E0 ;
  DEFB $1F,$0F,$FF,$87,$FF,$FF,$FF,$FF,$F8,$F0 ;
  DEFB $1F,$0F,$FF,$8F,$FF,$FF,$FF,$FF,$F8,$F0 ;
  DEFB $1F,$0F,$FF,$8F,$FF,$FF,$FF,$FF,$F8,$F0 ;
  DEFB $3F,$1F,$FF,$0F,$FF,$FF,$FF,$FF,$FC,$F8 ;
  DEFB $3F,$1F,$FF,$0F,$FF,$FF,$FF,$FF,$FC,$F8 ;
  DEFB $3F,$1F,$FF,$0F,$FF,$FF,$FF,$FF,$FC,$F8 ;
  DEFB $3F,$1F,$FF,$0C,$FF,$61,$FF,$0F,$FC,$F8 ;
  DEFB $3F,$1F,$FF,$0B,$FF,$33,$FF,$3F,$FC,$F8 ;
  DEFB $3F,$1F,$FF,$0B,$FF,$33,$FF,$3F,$FC,$F8 ;
  DEFB $3F,$1F,$FF,$0B,$FF,$33,$FF,$3F,$FC,$F8 ;
  DEFB $3F,$1F,$FF,$0B,$FF,$33,$FF,$3F,$FC,$F8 ;
  DEFB $3F,$1F,$FF,$0C,$FF,$61,$FF,$3F,$FC,$F8 ;
  DEFB $3F,$1F,$FF,$0F,$FF,$FF,$FF,$FF,$FC,$F8 ;
  DEFB $3F,$1F,$FF,$0F,$FF,$FF,$FF,$FF,$FC,$F8 ;
  DEFB $3F,$1F,$FF,$0F,$FF,$FF,$FF,$FF,$FC,$F8 ;
  DEFB $3F,$1F,$FF,$0F,$FF,$FF,$FF,$FF,$FC,$F8 ;
  DEFB $3F,$1F,$FF,$0F,$FF,$FF,$FF,$FF,$FC,$F8 ;
  DEFB $3F,$1E,$FF,$0F,$FF,$FF,$FF,$FF,$FC,$F8 ;
  DEFB $7F,$3E,$FF,$0F,$FF,$FF,$FF,$FF,$FE,$FC ;
  DEFB $7F,$3C,$FF,$1F,$FF,$FF,$FF,$FF,$FE,$FC ;
  DEFB $FF,$7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE ;
  DEFB $7F,$00,$FF,$00,$FF,$00,$FF,$00,$FE,$00 ;

; Sprite for graphic 130
;
; 32 by 23 pixels.
SPRITE130:
  DEFB $04,$17            ; Width in bytes, and height in rows
  DEFB $00,$00,$01,$00,$80,$00,$00,$00 ; Mask and image bytes, a pair per cell,
  DEFB $00,$00,$03,$01,$C0,$80,$00,$00 ; the bottom row first
  DEFB $01,$00,$03,$01,$C0,$80,$80,$00 ;
  DEFB $03,$01,$83,$01,$C1,$80,$C0,$80 ;
  DEFB $03,$01,$CF,$81,$F3,$81,$C0,$80 ;
  DEFB $03,$01,$FF,$CD,$FF,$B3,$C0,$80 ;
  DEFB $03,$01,$FF,$ED,$FF,$B7,$C0,$80 ;
  DEFB $3F,$01,$FF,$ED,$FF,$B7,$FC,$80 ;
  DEFB $7F,$3E,$FF,$ED,$FF,$B7,$FE,$7C ;
  DEFB $7F,$3F,$FF,$6D,$FF,$B6,$FE,$FC ;
  DEFB $7F,$3F,$FF,$28,$FF,$04,$FE,$FC ;
  DEFB $7F,$3F,$FF,$47,$FF,$E2,$FE,$FC ;
  DEFB $7F,$3F,$FF,$3F,$FF,$FC,$FE,$FC ;
  DEFB $7F,$3F,$FF,$7F,$FF,$FE,$FE,$FC ;
  DEFB $3F,$00,$FF,$7F,$FF,$FE,$FC,$00 ;
  DEFB $03,$01,$FF,$BF,$FF,$FD,$C0,$80 ;
  DEFB $03,$01,$FF,$E7,$FF,$E7,$C0,$80 ;
  DEFB $03,$01,$E7,$C0,$F7,$03,$C0,$80 ;
  DEFB $03,$01,$C3,$81,$C3,$81,$C0,$80 ;
  DEFB $03,$01,$83,$01,$C1,$80,$C0,$80 ;
  DEFB $01,$00,$03,$01,$C0,$80,$80,$00 ;
  DEFB $00,$00,$03,$01,$C0,$80,$00,$00 ;
  DEFB $00,$00,$01,$00,$80,$00,$00,$00 ;

; Sprite for graphic 129
;
; 24 by 25 pixels.
SPRITE129:
  DEFB $03,$19            ; Width in bytes, and height in rows
  DEFB $00,$00,$7E,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $03,$00,$FF,$7E,$C0,$00 ; bottom row first
  DEFB $0F,$03,$FF,$FF,$F0,$C0 ;
  DEFB $1F,$03,$FF,$FF,$F8,$F0 ;
  DEFB $3F,$03,$FF,$FF,$FC,$F8 ;
  DEFB $7F,$23,$FF,$FF,$FE,$FC ;
  DEFB $FF,$63,$FF,$FF,$FF,$FE ;
  DEFB $FF,$71,$FF,$FF,$FF,$FE ;
  DEFB $7F,$31,$FF,$FF,$FE,$FC ;
  DEFB $7F,$38,$FF,$FF,$FE,$FC ;
  DEFB $3F,$1C,$FF,$E7,$FC,$F8 ;
  DEFB $1F,$0E,$FF,$5B,$F8,$F0 ;
  DEFB $0F,$07,$FF,$AD,$F0,$E0 ;
  DEFB $1F,$09,$FF,$AD,$F8,$90 ;
  DEFB $1F,$0A,$FF,$24,$F8,$70 ;
  DEFB $3F,$17,$FF,$18,$FC,$B8 ;
  DEFB $7F,$2E,$7E,$3C,$FE,$5C ;
  DEFB $FE,$5C,$7E,$18,$7F,$2A ;
  DEFB $FC,$68,$7E,$24,$3F,$16 ;
  DEFB $78,$30,$7E,$2C,$1E,$0C ;
  DEFB $30,$00,$7E,$2C,$0C,$00 ;
  DEFB $00,$00,$7E,$08,$00,$00 ;
  DEFB $00,$00,$7E,$24,$00,$00 ;
  DEFB $00,$00,$3C,$18,$00,$00 ;
  DEFB $00,$00,$18,$00,$00,$00 ;

; Sprite for graphic 124
;
; 24 by 24 pixels.
SPRITE124:
  DEFB $03,$18            ; Width in bytes, and height in rows
  DEFB $00,$00,$FF,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $07,$00,$FF,$FF,$E0,$00 ; bottom row first
  DEFB $1F,$07,$FF,$F8,$F8,$E0 ;
  DEFB $3F,$19,$FF,$F8,$FC,$78 ;
  DEFB $7F,$31,$FF,$F8,$FE,$7C ;
  DEFB $FF,$71,$FF,$FF,$FF,$7A ;
  DEFB $FF,$77,$FF,$00,$FF,$FA ;
  DEFB $FF,$7B,$FF,$FF,$FF,$1A ;
  DEFB $FF,$61,$FF,$FF,$FF,$E6 ;
  DEFB $FF,$51,$FF,$00,$FF,$FA ;
  DEFB $7F,$38,$FF,$FF,$FE,$3C ;
  DEFB $7F,$38,$FF,$FF,$FE,$DC ;
  DEFB $3F,$14,$FF,$FF,$FC,$E8 ;
  DEFB $1F,$0C,$FF,$7F,$F8,$F0 ;
  DEFB $1F,$0E,$FF,$7F,$F8,$F0 ;
  DEFB $0F,$06,$FF,$3F,$F0,$E0 ;
  DEFB $0F,$07,$FF,$1F,$F0,$E0 ;
  DEFB $07,$02,$FF,$FF,$E0,$C0 ;
  DEFB $07,$03,$FF,$E7,$E0,$C0 ;
  DEFB $1F,$04,$FF,$7E,$F8,$20 ;
  DEFB $3C,$18,$7E,$00,$3C,$18 ;
  DEFB $3C,$18,$00,$00,$3C,$18 ;
  DEFB $18,$00,$00,$00,$18,$00 ;
  DEFB $00,$00,$00,$00,$00,$00 ;

; Sprite for graphic 125
;
; 24 by 24 pixels.
SPRITE125:
  DEFB $03,$18            ; Width in bytes, and height in rows
  DEFB $00,$00,$FF,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $07,$00,$FF,$FF,$E0,$00 ; bottom row first
  DEFB $1F,$07,$FF,$7E,$F8,$E0 ;
  DEFB $3F,$18,$FF,$7E,$FC,$18 ;
  DEFB $7F,$38,$FF,$7E,$FE,$1C ;
  DEFB $FF,$78,$FF,$FF,$FF,$1E ;
  DEFB $FF,$7F,$FF,$00,$FF,$FE ;
  DEFB $FF,$78,$FF,$FF,$FF,$1E ;
  DEFB $FF,$61,$FF,$FF,$FF,$E6 ;
  DEFB $FF,$51,$FF,$00,$FF,$FA ;
  DEFB $7F,$38,$FF,$FF,$FE,$3C ;
  DEFB $7F,$38,$FF,$FF,$FE,$DC ;
  DEFB $3F,$14,$FF,$FF,$FC,$E8 ;
  DEFB $1F,$0C,$FF,$7F,$F8,$F0 ;
  DEFB $1F,$0E,$FF,$7F,$F8,$F0 ;
  DEFB $0F,$06,$FF,$3F,$F0,$E0 ;
  DEFB $0F,$07,$FF,$1F,$F0,$E0 ;
  DEFB $07,$02,$FF,$FF,$E0,$C0 ;
  DEFB $1F,$03,$FF,$E7,$F8,$C0 ;
  DEFB $3F,$1C,$FF,$7E,$FC,$38 ;
  DEFB $7E,$3C,$7E,$00,$7E,$3C ;
  DEFB $7E,$3C,$00,$00,$7E,$3C ;
  DEFB $3C,$1C,$00,$00,$3C,$18 ;
  DEFB $18,$00,$00,$00,$18,$00 ;

; Sprite for graphic 126
;
; 24 by 24 pixels.
SPRITE126:
  DEFB $03,$18            ; Width in bytes, and height in rows
  DEFB $00,$00,$FF,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $07,$00,$FF,$FF,$E0,$00 ; bottom row first
  DEFB $1F,$07,$FF,$1F,$F8,$E0 ;
  DEFB $3F,$1E,$FF,$1F,$FC,$98 ;
  DEFB $7F,$3E,$FF,$1F,$FE,$8C ;
  DEFB $FF,$5E,$FF,$FF,$FF,$8E ;
  DEFB $FF,$5F,$FF,$00,$FF,$EE ;
  DEFB $FF,$58,$FF,$FF,$FF,$1E ;
  DEFB $FF,$61,$FF,$FF,$FF,$E6 ;
  DEFB $FF,$51,$FF,$00,$FF,$FA ;
  DEFB $7F,$38,$FF,$FF,$FE,$3C ;
  DEFB $7F,$38,$FF,$FF,$FE,$DC ;
  DEFB $3F,$14,$FF,$FF,$FC,$E8 ;
  DEFB $1F,$0C,$FF,$7F,$F8,$F0 ;
  DEFB $1F,$0E,$FF,$7F,$F8,$F0 ;
  DEFB $0F,$06,$FF,$3F,$F0,$E0 ;
  DEFB $0F,$07,$FF,$1F,$F0,$E0 ;
  DEFB $07,$02,$FF,$FF,$E0,$C0 ;
  DEFB $1F,$03,$FF,$E7,$F8,$C0 ;
  DEFB $3F,$1C,$FF,$7E,$FC,$38 ;
  DEFB $7E,$3C,$7E,$00,$7E,$3C ;
  DEFB $7E,$3C,$00,$00,$7E,$3C ;
  DEFB $3C,$1C,$00,$00,$3C,$38 ;
  DEFB $18,$00,$00,$00,$18,$00 ;

; Sprite for graphic 127
;
; 24 by 24 pixels.
SPRITE127:
  DEFB $03,$18            ; Width in bytes, and height in rows
  DEFB $00,$00,$FF,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $07,$00,$FF,$FF,$E0,$00 ; bottom row first
  DEFB $1F,$07,$FF,$C7,$F8,$E0 ;
  DEFB $3F,$1F,$FF,$C7,$FC,$F8 ;
  DEFB $7F,$2F,$FF,$C7,$FE,$EC ;
  DEFB $FF,$67,$FF,$FF,$FF,$E6 ;
  DEFB $FF,$67,$FF,$00,$FF,$E6 ;
  DEFB $FF,$78,$FF,$FF,$FF,$1E ;
  DEFB $FF,$61,$FF,$FF,$FF,$E6 ;
  DEFB $FF,$51,$FF,$00,$FF,$FA ;
  DEFB $7F,$38,$FF,$FF,$FE,$3C ;
  DEFB $7F,$38,$FF,$FF,$FE,$DC ;
  DEFB $3F,$14,$FF,$FF,$FC,$E8 ;
  DEFB $1F,$0C,$FF,$7F,$F8,$F0 ;
  DEFB $1F,$0E,$FF,$7F,$F8,$F0 ;
  DEFB $0F,$06,$FF,$3F,$F0,$E0 ;
  DEFB $0F,$07,$FF,$1F,$F0,$E0 ;
  DEFB $07,$02,$FF,$FF,$E0,$C0 ;
  DEFB $07,$03,$FF,$E7,$E0,$C0 ;
  DEFB $1F,$04,$FF,$7E,$F8,$20 ;
  DEFB $3C,$18,$7E,$00,$3C,$18 ;
  DEFB $3C,$18,$00,$00,$3C,$18 ;
  DEFB $18,$00,$00,$00,$18,$00 ;
  DEFB $00,$00,$00,$00,$00,$00 ;

; Sprite for graphic 122
;
; 32 by 29 pixels.
SPRITE122:
  DEFB $04,$1D            ; Width in bytes, and height in rows
  DEFB $00,$00,$01,$00,$80,$00,$00,$00 ; Mask and image bytes, a pair per cell,
  DEFB $00,$00,$07,$01,$E0,$80,$00,$00 ; the bottom row first
  DEFB $00,$00,$1F,$02,$F8,$60,$00,$00 ;
  DEFB $00,$00,$7F,$15,$FE,$78,$00,$00 ;
  DEFB $01,$00,$FF,$2A,$FF,$7E,$80,$00 ;
  DEFB $07,$01,$FF,$55,$FF,$7F,$E0,$80 ;
  DEFB $1F,$02,$FF,$AA,$FF,$7F,$F8,$E0 ;
  DEFB $7F,$15,$FF,$55,$FF,$7F,$FE,$F8 ;
  DEFB $FF,$2A,$FF,$AA,$FF,$7F,$FF,$FE ;
  DEFB $FF,$55,$FF,$55,$FF,$7F,$FF,$FE ;
  DEFB $FF,$2A,$FF,$AA,$FF,$7F,$FF,$FE ;
  DEFB $FF,$55,$FF,$55,$FF,$FF,$FF,$FE ;
  DEFB $FF,$2A,$FF,$AA,$FF,$7F,$FF,$FE ;
  DEFB $FF,$55,$FF,$51,$FF,$9F,$FF,$FE ;
  DEFB $FF,$2A,$FF,$A7,$FF,$E7,$FF,$FE ;
  DEFB $FF,$55,$FF,$1F,$FF,$F9,$FF,$FE ;
  DEFB $FF,$2E,$FF,$7F,$FF,$FE,$FF,$7E ;
  DEFB $FF,$51,$FF,$E7,$FF,$9F,$FF,$9E ;
  DEFB $FF,$27,$FF,$E1,$FF,$07,$FF,$E6 ;
  DEFB $FF,$5F,$FF,$E0,$FF,$03,$0F,$FA ;
  DEFB $FF,$7F,$FF,$E0,$FF,$0F,$FF,$FE ;
  DEFB $7F,$1F,$FF,$E0,$FF,$1F,$FE,$F8 ;
  DEFB $1F,$07,$FF,$E0,$FF,$07,$F8,$E0 ;
  DEFB $07,$01,$FF,$E0,$FF,$03,$E0,$80 ;
  DEFB $01,$00,$FF,$7F,$FF,$FE,$80,$00 ;
  DEFB $00,$00,$7F,$1F,$FE,$F8,$00,$00 ;
  DEFB $00,$00,$1F,$07,$F8,$E0,$00,$00 ;
  DEFB $00,$00,$07,$01,$E0,$80,$00,$00 ;
  DEFB $00,$00,$01,$00,$80,$00,$00,$00 ;

; Sprite for graphic 123
;
; 32 by 29 pixels.
SPRITE123:
  DEFB $04,$1D            ; Width in bytes, and height in rows
  DEFB $00,$00,$01,$00,$80,$00,$00,$00 ; Mask and image bytes, a pair per cell,
  DEFB $00,$00,$07,$01,$E0,$80,$00,$00 ; the bottom row first
  DEFB $00,$00,$1F,$06,$F8,$40,$00,$00 ;
  DEFB $00,$00,$7F,$1E,$FE,$A8,$00,$00 ;
  DEFB $01,$00,$FF,$7E,$FF,$54,$80,$00 ;
  DEFB $07,$01,$FF,$FE,$FF,$AA,$E0,$80 ;
  DEFB $1F,$07,$FF,$FE,$FF,$55,$F8,$40 ;
  DEFB $7F,$1F,$FF,$FE,$FF,$AA,$FE,$A8 ;
  DEFB $FF,$7F,$FF,$FE,$FF,$55,$FF,$54 ;
  DEFB $FF,$7F,$FF,$FE,$FF,$AA,$FF,$AA ;
  DEFB $FF,$7F,$FF,$FE,$FF,$55,$FF,$54 ;
  DEFB $FF,$7F,$FF,$FF,$FF,$AA,$FF,$AA ;
  DEFB $FF,$7F,$FF,$FE,$FF,$55,$FF,$54 ;
  DEFB $FF,$7F,$FF,$F9,$FF,$8A,$FF,$AA ;
  DEFB $FF,$7F,$FF,$E7,$FF,$E5,$FF,$54 ;
  DEFB $FF,$7F,$FF,$9F,$FF,$F8,$FF,$AA ;
  DEFB $FF,$7E,$FF,$7F,$FF,$FE,$FF,$54 ;
  DEFB $FF,$79,$FF,$C0,$FF,$07,$FF,$8A ;
  DEFB $FF,$67,$FF,$E0,$FF,$07,$FF,$E4 ;
  DEFB $FF,$5F,$FF,$F8,$FF,$07,$FF,$F8 ;
  DEFB $FF,$7F,$FF,$F0,$FF,$07,$FF,$FE ;
  DEFB $7F,$1F,$FF,$C0,$FF,$07,$FE,$F8 ;
  DEFB $1F,$07,$FF,$E0,$FF,$87,$F8,$E0 ;
  DEFB $07,$01,$FF,$F9,$FF,$E7,$E0,$80 ;
  DEFB $01,$00,$FF,$7F,$FF,$FE,$80,$00 ;
  DEFB $00,$00,$7F,$1F,$FE,$F8,$00,$00 ;
  DEFB $00,$00,$1F,$07,$F8,$E0,$00,$00 ;
  DEFB $00,$00,$07,$01,$E0,$80,$00,$00 ;
  DEFB $00,$00,$01,$00,$80,$00,$00,$00 ;

; Sprite for graphic 118
;
; 24 by 26 pixels.
SPRITE118:
  DEFB $03,$1A            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$48,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$F8,$00,$FE,$48 ; bottom row first
  DEFB $03,$00,$FF,$F8,$FF,$AA ;
  DEFB $0F,$03,$FF,$07,$FE,$20 ;
  DEFB $1F,$0C,$FF,$F8,$FF,$D6 ;
  DEFB $3F,$13,$FF,$FF,$FF,$FE ;
  DEFB $7F,$2F,$FF,$FF,$FE,$DC ;
  DEFB $FF,$57,$FF,$FF,$FC,$C8 ;
  DEFB $7F,$27,$FF,$FD,$FC,$F8 ;
  DEFB $7F,$27,$FF,$FD,$F8,$F0 ;
  DEFB $FF,$67,$FF,$FD,$FC,$B8 ;
  DEFB $FF,$73,$FF,$FD,$FC,$58 ;
  DEFB $FF,$73,$FF,$FE,$FC,$C8 ;
  DEFB $7F,$39,$FF,$FF,$C8,$80 ;
  DEFB $7F,$3E,$FF,$9F,$C0,$80 ;
  DEFB $3F,$1F,$FF,$6F,$80,$00 ;
  DEFB $7F,$28,$FF,$6E,$00,$00 ;
  DEFB $FF,$47,$FE,$68,$00,$00 ;
  DEFB $5F,$0F,$F8,$E0,$00,$00 ;
  DEFB $1F,$0C,$FE,$F8,$00,$00 ;
  DEFB $1F,$0C,$FF,$FE,$00,$00 ;
  DEFB $0F,$07,$FF,$E6,$00,$00 ;
  DEFB $07,$03,$FF,$E6,$00,$00 ;
  DEFB $03,$00,$FF,$3E,$00,$00 ;
  DEFB $00,$00,$3E,$1C,$00,$00 ;
  DEFB $00,$00,$1C,$00,$00,$00 ;

; Sprite for graphic 116
;
; 24 by 26 pixels.
SPRITE116:
  DEFB $03,$1A            ; Width in bytes, and height in rows
  DEFB $00,$00,$0F,$00,$C0,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$3F,$0F,$F0,$C0 ; bottom row first
  DEFB $00,$00,$FF,$30,$F8,$30 ;
  DEFB $01,$00,$FF,$CF,$FC,$C8 ;
  DEFB $03,$01,$FF,$3F,$FE,$F0 ;
  DEFB $07,$02,$FF,$DF,$FF,$F2 ;
  DEFB $0F,$05,$FF,$9F,$FE,$E4 ;
  DEFB $0F,$05,$FF,$9F,$FE,$D4 ;
  DEFB $1F,$0B,$FF,$9F,$FF,$DA ;
  DEFB $3F,$17,$FF,$CF,$FF,$E6 ;
  DEFB $7F,$2F,$FF,$CF,$FF,$FE ;
  DEFB $FF,$5F,$FF,$E7,$FF,$FE ;
  DEFB $FF,$37,$FF,$F7,$FE,$FC ;
  DEFB $FF,$65,$FF,$FB,$FE,$FC ;
  DEFB $FF,$7B,$FF,$BC,$FC,$F8 ;
  DEFB $7F,$03,$FF,$BB,$F8,$60 ;
  DEFB $07,$03,$FF,$83,$E0,$00 ;
  DEFB $03,$01,$FF,$3B,$80,$00 ;
  DEFB $01,$00,$FF,$7F,$C0,$00 ;
  DEFB $00,$00,$FF,$67,$F0,$C0 ;
  DEFB $00,$00,$FF,$67,$F8,$F0 ;
  DEFB $00,$00,$7F,$3F,$F8,$30 ;
  DEFB $00,$00,$3F,$1F,$F8,$30 ;
  DEFB $00,$00,$1F,$01,$F8,$F0 ;
  DEFB $00,$00,$01,$00,$F0,$E0 ;
  DEFB $00,$00,$00,$00,$E0,$00 ;

; Sprite for graphic 117
;
; 24 by 26 pixels.
SPRITE117:
  DEFB $03,$1A            ; Width in bytes, and height in rows
  DEFB $00,$00,$0F,$00,$C0,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$3F,$0F,$F0,$C0 ; bottom row first
  DEFB $00,$00,$FF,$30,$F8,$30 ;
  DEFB $01,$00,$FF,$CF,$FE,$C8 ;
  DEFB $03,$01,$FF,$3F,$FF,$F2 ;
  DEFB $07,$02,$FF,$DF,$FF,$F2 ;
  DEFB $0F,$05,$FF,$9F,$FE,$E4 ;
  DEFB $0F,$05,$FF,$9F,$FE,$D4 ;
  DEFB $1F,$0B,$FF,$9F,$FF,$DA ;
  DEFB $3F,$17,$FF,$CF,$FF,$E6 ;
  DEFB $7F,$2F,$FF,$CF,$FF,$FE ;
  DEFB $FF,$5F,$FF,$EF,$FF,$FE ;
  DEFB $FF,$37,$FF,$F7,$FE,$FC ;
  DEFB $FF,$65,$FF,$FB,$FE,$FC ;
  DEFB $FF,$7B,$FF,$BC,$FC,$F8 ;
  DEFB $7F,$03,$FF,$BB,$F8,$60 ;
  DEFB $07,$03,$FF,$83,$F0,$00 ;
  DEFB $03,$01,$FF,$63,$F8,$70 ;
  DEFB $01,$00,$FF,$23,$FC,$F8 ;
  DEFB $00,$00,$3F,$0F,$FC,$98 ;
  DEFB $00,$00,$7F,$3F,$FC,$98 ;
  DEFB $00,$00,$7F,$33,$F8,$F0 ;
  DEFB $00,$00,$7F,$33,$F0,$E0 ;
  DEFB $00,$00,$7F,$3E,$E0,$00 ;
  DEFB $00,$00,$3E,$1C,$00,$00 ;
  DEFB $00,$00,$1C,$00,$00,$00 ;

; Sprite for graphic 119
;
; 24 by 26 pixels.
SPRITE119:
  DEFB $03,$1A            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$48,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$F8,$00,$FE,$48 ; bottom row first
  DEFB $03,$00,$FF,$F8,$FF,$AA ;
  DEFB $0F,$03,$FF,$07,$FE,$20 ;
  DEFB $1F,$0C,$FF,$F8,$FF,$D6 ;
  DEFB $3F,$13,$FF,$FF,$FF,$FE ;
  DEFB $7F,$1F,$FF,$FF,$FE,$DC ;
  DEFB $FF,$57,$FF,$FF,$FC,$C8 ;
  DEFB $7F,$27,$FF,$FD,$FC,$F8 ;
  DEFB $7F,$27,$FF,$FD,$F8,$F0 ;
  DEFB $FF,$67,$FF,$FD,$FC,$B8 ;
  DEFB $FF,$73,$FF,$FD,$FC,$58 ;
  DEFB $FF,$73,$FF,$FE,$FC,$C8 ;
  DEFB $7F,$39,$FF,$FF,$C8,$80 ;
  DEFB $7F,$3E,$FF,$9F,$C0,$80 ;
  DEFB $3F,$1F,$FF,$6F,$80,$00 ;
  DEFB $7F,$2F,$FF,$60,$00,$00 ;
  DEFB $7F,$27,$FF,$6E,$00,$00 ;
  DEFB $3F,$10,$FF,$7F,$80,$00 ;
  DEFB $1F,$01,$FF,$F3,$80,$00 ;
  DEFB $0F,$07,$FF,$F3,$80,$00 ;
  DEFB $0F,$06,$FF,$7E,$00,$00 ;
  DEFB $0F,$06,$FE,$7E,$00,$00 ;
  DEFB $0F,$07,$FC,$C0,$00,$00 ;
  DEFB $07,$03,$C0,$80,$00,$00 ;
  DEFB $03,$00,$80,$00,$00,$00 ;

; Sprite for graphic 120
;
; 24 by 30 pixels.
SPRITE120:
  DEFB $03,$1E            ; Width in bytes, and height in rows
  DEFB $00,$00,$7E,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $01,$00,$FF,$7E,$80,$00 ; bottom row first
  DEFB $03,$00,$FF,$FF,$C0,$80 ;
  DEFB $07,$00,$FF,$81,$E0,$C0 ;
  DEFB $0F,$04,$FF,$7E,$F0,$40 ;
  DEFB $0F,$03,$FF,$FF,$F0,$C0 ;
  DEFB $1F,$0F,$FF,$81,$F8,$F0 ;
  DEFB $3F,$1E,$FF,$7E,$FC,$78 ;
  DEFB $7F,$3C,$FF,$FF,$FE,$BC ;
  DEFB $FF,$78,$FF,$FF,$FF,$DE ;
  DEFB $FF,$74,$FF,$FF,$FF,$EE ;
  DEFB $FF,$74,$FF,$FF,$FF,$EE ;
  DEFB $FF,$74,$FF,$FF,$FF,$EE ;
  DEFB $7F,$34,$FF,$81,$FE,$EC ;
  DEFB $3F,$14,$FF,$7E,$FC,$28 ;
  DEFB $1F,$03,$FF,$FF,$F8,$C0 ;
  DEFB $1F,$0F,$FF,$81,$F8,$F0 ;
  DEFB $3F,$1E,$FF,$7F,$FC,$78 ;
  DEFB $7F,$3C,$FF,$FF,$FE,$BC ;
  DEFB $FF,$78,$FF,$7F,$FF,$DE ;
  DEFB $FF,$74,$FF,$7F,$FF,$EE ;
  DEFB $FF,$74,$FF,$7F,$FF,$EE ;
  DEFB $FF,$76,$FF,$7F,$FF,$EE ;
  DEFB $7F,$36,$FF,$3F,$FE,$EC ;
  DEFB $3F,$1B,$FF,$3F,$FC,$D8 ;
  DEFB $1F,$0B,$FF,$9F,$F8,$D0 ;
  DEFB $0B,$01,$FF,$CF,$D0,$80 ;
  DEFB $01,$00,$FF,$FF,$80,$00 ;
  DEFB $00,$00,$FF,$3C,$00,$00 ;
  DEFB $00,$00,$3C,$00,$00,$00 ;

; Sprite for graphic 121
;
; 24 by 30 pixels.
SPRITE121:
  DEFB $03,$1E            ; Width in bytes, and height in rows
  DEFB $00,$00,$7E,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $01,$00,$FF,$3E,$80,$00 ; bottom row first
  DEFB $03,$00,$FF,$FF,$C0,$80 ;
  DEFB $07,$00,$FF,$FF,$E0,$C0 ;
  DEFB $0F,$04,$FF,$FF,$F0,$E0 ;
  DEFB $0F,$04,$FF,$81,$F0,$E0 ;
  DEFB $0F,$04,$FF,$7E,$F0,$20 ;
  DEFB $0F,$03,$FF,$FF,$F0,$C0 ;
  DEFB $1F,$0F,$FF,$81,$F8,$F0 ;
  DEFB $3F,$1E,$FF,$7E,$FC,$78 ;
  DEFB $7F,$3C,$FF,$FF,$FE,$BC ;
  DEFB $FF,$78,$FF,$81,$FF,$DE ;
  DEFB $FF,$74,$FF,$7E,$FF,$2E ;
  DEFB $FF,$73,$FF,$FF,$FF,$CE ;
  DEFB $FF,$6F,$FF,$81,$FF,$F8 ;
  DEFB $7F,$1E,$FF,$7E,$FE,$78 ;
  DEFB $7F,$3C,$FF,$FF,$FE,$BC ;
  DEFB $FF,$78,$FF,$FF,$FF,$DE ;
  DEFB $FF,$74,$FF,$FF,$FF,$EE ;
  DEFB $FF,$74,$FF,$FF,$FF,$EE ;
  DEFB $FF,$74,$FF,$7F,$FF,$EE ;
  DEFB $7F,$34,$FF,$7F,$FE,$EC ;
  DEFB $3F,$16,$FF,$7F,$FC,$E8 ;
  DEFB $1F,$06,$FF,$3F,$F8,$E0 ;
  DEFB $07,$03,$FF,$3F,$E0,$C0 ;
  DEFB $07,$03,$FF,$9F,$E0,$C0 ;
  DEFB $03,$01,$FF,$CF,$C0,$80 ;
  DEFB $01,$00,$FF,$FF,$80,$00 ;
  DEFB $00,$00,$FF,$3C,$00,$00 ;
  DEFB $00,$00,$3C,$00,$00,$00 ;

; Sprite for graphic 82
;
; 32 by 16 pixels.
SPRITE82:
  DEFB $04,$10            ; Width in bytes, and height in rows
  DEFB $1F,$00,$C0,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell,
  DEFB $3F,$1B,$E0,$C0,$00,$00,$00,$00 ; the bottom row first
  DEFB $7F,$37,$F0,$E0,$00,$00,$00,$00 ;
  DEFB $7F,$00,$F0,$00,$00,$00,$00,$00 ;
  DEFB $FF,$77,$F8,$F0,$00,$00,$00,$00 ;
  DEFB $FF,$77,$FF,$F0,$FF,$00,$FC,$00 ;
  DEFB $FF,$6F,$FF,$FF,$FF,$FF,$FE,$FC ;
  DEFB $FF,$6F,$FF,$F0,$FF,$00,$FF,$02 ;
  DEFB $FF,$6F,$FF,$FF,$FF,$FF,$FF,$FE ;
  DEFB $FF,$6F,$FF,$FF,$FF,$FF,$FE,$FC ;
  DEFB $FF,$77,$FF,$F0,$FF,$00,$FC,$00 ;
  DEFB $FF,$77,$F8,$F0,$00,$00,$00,$00 ;
  DEFB $7F,$00,$F0,$00,$00,$00,$00,$00 ;
  DEFB $7F,$37,$F0,$E0,$00,$00,$00,$00 ;
  DEFB $3F,$1B,$E0,$C0,$00,$00,$00,$00 ;
  DEFB $1F,$00,$C0,$00,$00,$00,$00,$00 ;

; Sprite for graphic 81
;
; 32 by 18 pixels.
SPRITE81:
  DEFB $04,$12            ; Width in bytes, and height in rows
  DEFB $00,$00,$7E,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell,
  DEFB $01,$00,$FF,$5E,$C0,$00,$00,$00 ; the bottom row first
  DEFB $03,$01,$FF,$BF,$F1,$C0,$E0,$00 ;
  DEFB $07,$03,$FF,$BF,$FF,$F1,$F0,$E0 ;
  DEFB $0F,$07,$FF,$DF,$FF,$FF,$F8,$F0 ;
  DEFB $0F,$07,$FF,$EF,$FF,$FF,$F8,$F0 ;
  DEFB $1F,$0F,$FF,$F4,$FF,$FB,$F8,$50 ;
  DEFB $1F,$0F,$FF,$F3,$FF,$7F,$F8,$F0 ;
  DEFB $1F,$0F,$FF,$F3,$FF,$B8,$F8,$00 ;
  DEFB $1F,$0F,$FF,$F7,$FF,$CF,$F8,$F0 ;
  DEFB $1F,$0F,$FF,$F7,$FF,$F5,$F8,$50 ;
  DEFB $1F,$0F,$FF,$E7,$FF,$FF,$F8,$F0 ;
  DEFB $0F,$07,$FF,$D7,$FF,$FF,$F0,$E0 ;
  DEFB $0F,$07,$FF,$BB,$FF,$FF,$E0,$80 ;
  DEFB $07,$03,$FF,$BC,$FF,$FC,$80,$00 ;
  DEFB $03,$01,$FF,$DF,$FC,$30,$00,$00 ;
  DEFB $01,$00,$FF,$6F,$F0,$80,$00,$00 ;
  DEFB $00,$00,$7F,$00,$80,$00,$00,$00 ;

; Sprite for graphic 80
;
; 24 by 11 pixels.
SPRITE80:
  DEFB $03,$0B            ; Width in bytes, and height in rows
  DEFB $10,$00,$00,$00,$08,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $78,$10,$00,$00,$1E,$08 ; bottom row first
  DEFB $F0,$60,$00,$00,$0F,$06 ;
  DEFB $E0,$80,$00,$00,$07,$01 ;
  DEFB $84,$00,$00,$00,$41,$00 ;
  DEFB $0E,$04,$44,$00,$E0,$40 ;
  DEFB $1C,$08,$EE,$44,$70,$20 ;
  DEFB $39,$10,$CE,$84,$C8,$10 ;
  DEFB $11,$00,$CE,$84,$10,$00 ;
  DEFB $01,$00,$CE,$84,$00,$00 ;
  DEFB $00,$00,$84,$00,$00,$00 ;

; Sprite for graphic 83
;
; 40 by 17 pixels.
SPRITE83:
  DEFB $05,$11            ; Width in bytes, and height in rows
  DEFB $03,$00,$80,$00,$00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair
  DEFB $0F,$03,$C0,$80,$00,$00,$00,$00,$00,$00 ; per cell, the bottom row first
  DEFB $1F,$0F,$E0,$C0,$00,$00,$00,$00,$00,$00 ;
  DEFB $3F,$1F,$E0,$C0,$00,$00,$00,$00,$00,$00 ;
  DEFB $7F,$3F,$C0,$80,$00,$00,$00,$00,$00,$00 ;
  DEFB $7F,$3E,$80,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $FE,$7C,$00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $FC,$58,$00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $FC,$58,$00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $FE,$5C,$00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $FF,$5E,$80,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $7F,$2F,$FF,$80,$FF,$00,$FF,$00,$FC,$00 ;
  DEFB $7F,$37,$FF,$FF,$FF,$FF,$FF,$FF,$FE,$FC ;
  DEFB $3F,$18,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE ;
  DEFB $1F,$07,$FF,$00,$FF,$00,$FF,$00,$FF,$02 ;
  DEFB $07,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FE,$FC ;
  DEFB $00,$00,$FF,$00,$FF,$00,$FF,$00,$FC,$00 ;

; Sprite for graphic 88
;
; 24 by 8 pixels.
SPRITE88:
  DEFB $03,$08            ; Width in bytes, and height in rows
  DEFB $FC,$FC,$6F,$6F,$FF,$FF ; Mask and image bytes, a pair per cell, the
  DEFB $7C,$7C,$2F,$2F,$FF,$FF ; bottom row first
  DEFB $3E,$3E,$37,$37,$FF,$FF ;
  DEFB $1F,$1F,$17,$17,$FF,$FF ;
  DEFB $07,$07,$8B,$8B,$FF,$FF ;
  DEFB $01,$01,$80,$80,$00,$00 ;
  DEFB $00,$00,$65,$65,$FF,$FF ;
  DEFB $00,$00,$65,$65,$FF,$FF ;

; Sprite for graphic 89
;
; 24 by 8 pixels.
SPRITE89:
  DEFB $03,$08            ; Width in bytes, and height in rows
  DEFB $FF,$FF,$FF,$FF,$FF,$FF ; Mask and image bytes, a pair per cell, the
  DEFB $FF,$FF,$FF,$FF,$FE,$FE ; bottom row first
  DEFB $FF,$FF,$FF,$FF,$FC,$FC ;
  DEFB $FF,$FF,$FF,$FF,$F0,$F0 ;
  DEFB $FF,$FF,$FF,$FF,$C0,$C0 ;
  DEFB $00,$00,$03,$03,$00,$00 ;
  DEFB $FF,$FF,$FC,$FC,$00,$00 ;
  DEFB $FF,$FF,$FC,$FC,$00,$00 ;

; Sprite for graphic 84
;
; 24 by 22 pixels.
SPRITE84:
  DEFB $03,$16            ; Width in bytes, and height in rows
  DEFB $FF,$FF,$FF,$FF,$C0,$C0 ; Mask and image bytes, a pair per cell, the
  DEFB $FF,$FF,$FF,$FF,$E0,$E0 ; bottom row first
  DEFB $FF,$FF,$FF,$FF,$F0,$F0 ;
  DEFB $00,$00,$00,$00,$78,$78 ;
  DEFB $FF,$FF,$FF,$FF,$3C,$3C ;
  DEFB $FF,$FF,$FF,$FF,$9E,$9E ;
  DEFB $00,$00,$00,$00,$CE,$CE ;
  DEFB $00,$00,$00,$00,$6E,$6E ;
  DEFB $00,$00,$00,$00,$6E,$6E ;
  DEFB $00,$00,$00,$00,$6E,$6E ;
  DEFB $00,$00,$00,$00,$6E,$6E ;
  DEFB $00,$00,$00,$00,$6E,$6E ;
  DEFB $00,$00,$00,$00,$6E,$6E ;
  DEFB $00,$00,$00,$00,$6E,$6E ;
  DEFB $00,$00,$00,$00,$6E,$6E ;
  DEFB $00,$00,$00,$00,$CE,$CE ;
  DEFB $FF,$FF,$FF,$FF,$9E,$9E ;
  DEFB $FF,$FF,$FF,$FF,$3C,$3C ;
  DEFB $00,$00,$00,$00,$78,$78 ;
  DEFB $FF,$FF,$FF,$FF,$F0,$F0 ;
  DEFB $FF,$FF,$FF,$FF,$E0,$E0 ;
  DEFB $FF,$FF,$FF,$FF,$C0,$C0 ;

; Sprite for graphic 11
;
; 24 by 16 pixels.
SPRITE11:
  DEFB $03,$10            ; Width in bytes, and height in rows
  DEFB $00,$00,$7E,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $03,$00,$FF,$7E,$C0,$00 ; bottom row first
  DEFB $0F,$03,$FF,$BD,$F0,$C0 ;
  DEFB $1F,$0E,$FF,$3C,$F8,$70 ;
  DEFB $3F,$16,$FF,$18,$FC,$68 ;
  DEFB $7F,$23,$FF,$18,$FE,$C4 ;
  DEFB $7F,$33,$FF,$FF,$FE,$CC ;
  DEFB $3F,$13,$FF,$99,$FC,$C8 ;
  DEFB $3F,$1F,$FF,$18,$FC,$F8 ;
  DEFB $3F,$19,$FF,$18,$FC,$98 ;
  DEFB $1F,$09,$FF,$99,$F8,$90 ;
  DEFB $1F,$08,$FF,$FF,$F8,$10 ;
  DEFB $1F,$0D,$FF,$81,$F8,$B0 ;
  DEFB $0F,$06,$81,$00,$F0,$60 ;
  DEFB $0E,$04,$00,$00,$70,$20 ;
  DEFB $04,$00,$00,$00,$20,$00 ;

; Sprite for graphic 73
;
; 24 by 19 pixels.
SPRITE73:
  DEFB $03,$13            ; Width in bytes, and height in rows
  DEFB $00,$00,$08,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $02,$00,$1C,$08,$00,$00 ; bottom row first
  DEFB $07,$02,$1E,$0C,$40,$00 ;
  DEFB $07,$03,$BF,$1E,$E0,$40 ;
  DEFB $27,$03,$FF,$3E,$E4,$40 ;
  DEFB $7F,$27,$FF,$BE,$EE,$C4 ;
  DEFB $7F,$37,$FF,$FF,$FE,$CC ;
  DEFB $7F,$37,$FF,$FF,$FE,$DC ;
  DEFB $7F,$3E,$FF,$FF,$FE,$FC ;
  DEFB $7F,$38,$FF,$FF,$FE,$FC ;
  DEFB $3F,$18,$FF,$FF,$FC,$F8 ;
  DEFB $3F,$1C,$FF,$7F,$FC,$F8 ;
  DEFB $1F,$0C,$FF,$7F,$F8,$F0 ;
  DEFB $1F,$0E,$FF,$3F,$F8,$F0 ;
  DEFB $0F,$07,$FF,$3F,$F0,$E0 ;
  DEFB $07,$03,$FF,$9F,$E0,$C0 ;
  DEFB $03,$01,$FF,$CF,$C0,$80 ;
  DEFB $01,$00,$FF,$7E,$80,$00 ;
  DEFB $00,$00,$7E,$00,$00,$00 ;

; Sprite for graphic 46
;
; 24 by 24 pixels.
SPRITE46:
  DEFB $03,$18            ; Width in bytes, and height in rows
  DEFB $00,$00,$FF,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $07,$00,$FF,$FF,$E0,$00 ; bottom row first
  DEFB $1F,$07,$FF,$FF,$F8,$E0 ;
  DEFB $3F,$17,$FF,$FF,$FC,$F8 ;
  DEFB $7F,$33,$FF,$00,$FE,$FC ;
  DEFB $7F,$38,$FF,$FF,$FE,$3C ;
  DEFB $3F,$1B,$FF,$FF,$FC,$D8 ;
  DEFB $3F,$17,$FF,$FF,$FC,$E8 ;
  DEFB $1F,$0F,$FF,$FF,$F8,$F0 ;
  DEFB $3F,$1F,$FF,$F7,$FC,$F8 ;
  DEFB $7F,$3F,$FF,$F7,$FE,$FC ;
  DEFB $7F,$3E,$FF,$F7,$FE,$BC ;
  DEFB $FF,$7E,$FF,$73,$FF,$3E ;
  DEFB $FF,$75,$FF,$6A,$FF,$DE ;
  DEFB $FF,$75,$FF,$AD,$FF,$DE ;
  DEFB $FF,$6B,$FF,$DF,$FF,$EA ;
  DEFB $FF,$6F,$FF,$FF,$FF,$F2 ;
  DEFB $FF,$5D,$FF,$FF,$FF,$FA ;
  DEFB $7F,$39,$FF,$EF,$FE,$F8 ;
  DEFB $3B,$11,$FF,$EF,$F8,$70 ;
  DEFB $11,$00,$EF,$C7,$F0,$20 ;
  DEFB $01,$00,$C7,$83,$A0,$00 ;
  DEFB $00,$00,$83,$01,$80,$00 ;
  DEFB $00,$00,$01,$00,$00,$00 ;

; Sprite no graphic number reaches
;
; 32 by 25 pixels.
SPARE_SPRITEA:
  DEFB $04,$19            ; Width in bytes, and height in rows
  DEFB $00,$00,$01,$00,$20,$00,$00,$00 ; Mask and image bytes, a pair per cell,
  DEFB $00,$00,$13,$01,$F0,$20,$00,$00 ; the bottom row first
  DEFB $00,$00,$3F,$11,$F2,$80,$00,$00 ;
  DEFB $01,$00,$3F,$07,$FF,$62,$00,$00 ;
  DEFB $03,$01,$FF,$1F,$FF,$B8,$20,$00 ;
  DEFB $13,$00,$FF,$7F,$FF,$DE,$F4,$20 ;
  DEFB $3F,$11,$FF,$FF,$FF,$EF,$FE,$84 ;
  DEFB $3F,$07,$FF,$FF,$FF,$F7,$FE,$E4 ;
  DEFB $7F,$1F,$FF,$FF,$FF,$FB,$FE,$F8 ;
  DEFB $7F,$3F,$FF,$FF,$FF,$FD,$FF,$FE ;
  DEFB $3F,$1F,$FF,$FF,$FF,$FE,$FF,$FE ;
  DEFB $1F,$0F,$FF,$FF,$FF,$FF,$FF,$7E ;
  DEFB $0F,$07,$FF,$FF,$FF,$FF,$FF,$BE ;
  DEFB $07,$03,$FF,$FF,$FF,$FF,$FF,$DE ;
  DEFB $03,$01,$FF,$FF,$FF,$FF,$FF,$EE ;
  DEFB $01,$00,$FF,$FF,$FF,$FF,$FF,$F6 ;
  DEFB $00,$00,$FF,$7F,$FF,$FF,$FF,$FA ;
  DEFB $00,$00,$7F,$3F,$FF,$FF,$FF,$FC ;
  DEFB $00,$00,$3F,$1F,$FF,$FF,$FE,$F8 ;
  DEFB $00,$00,$1F,$0F,$FF,$FF,$F8,$E0 ;
  DEFB $00,$00,$0F,$07,$FE,$FF,$E0,$80 ;
  DEFB $00,$00,$07,$03,$F8,$FE,$80,$00 ;
  DEFB $00,$00,$03,$01,$E0,$F8,$00,$00 ;
  DEFB $00,$00,$01,$00,$80,$E0,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;

; Sprite for graphic 74
;
; 24 by 32 pixels.
SPRITE74:
  DEFB $03,$20            ; Width in bytes, and height in rows
  DEFB $00,$00,$3E,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$FF,$3E,$00,$00 ; bottom row first
  DEFB $01,$00,$FF,$FF,$E0,$00 ;
  DEFB $03,$01,$FF,$FF,$F0,$60 ;
  DEFB $03,$01,$FF,$FE,$F8,$F0 ;
  DEFB $03,$01,$FF,$FD,$F8,$F0 ;
  DEFB $03,$01,$FF,$1B,$F0,$E0 ;
  DEFB $03,$00,$FF,$E3,$E0,$C0 ;
  DEFB $03,$01,$FF,$F8,$C0,$80 ;
  DEFB $07,$00,$FF,$FB,$C0,$00 ;
  DEFB $0F,$07,$FF,$7F,$C0,$80 ;
  DEFB $1F,$0A,$FF,$BF,$C0,$80 ;
  DEFB $3F,$1F,$FF,$BF,$E0,$80 ;
  DEFB $3F,$1F,$FF,$67,$F0,$60 ;
  DEFB $3F,$1F,$FF,$61,$F8,$70 ;
  DEFB $7F,$2F,$FF,$61,$F8,$B0 ;
  DEFB $7F,$2F,$FF,$61,$F8,$B0 ;
  DEFB $7F,$2F,$FF,$F9,$F8,$B0 ;
  DEFB $7F,$2F,$FF,$FF,$F8,$B0 ;
  DEFB $7F,$2F,$FF,$83,$F8,$70 ;
  DEFB $7F,$32,$FF,$7C,$F0,$E0 ;
  DEFB $7F,$3D,$FF,$FF,$E0,$40 ;
  DEFB $3F,$1B,$FF,$83,$C0,$80 ;
  DEFB $1F,$07,$FF,$80,$E0,$C0 ;
  DEFB $0F,$05,$FF,$84,$E0,$40 ;
  DEFB $0F,$05,$FF,$88,$E0,$40 ;
  DEFB $0F,$05,$FF,$E0,$C0,$80 ;
  DEFB $07,$02,$FF,$FD,$C0,$80 ;
  DEFB $07,$02,$FF,$FF,$80,$00 ;
  DEFB $03,$01,$FF,$3E,$00,$00 ;
  DEFB $01,$00,$FE,$DC,$00,$00 ;
  DEFB $00,$00,$FC,$00,$00,$00 ;

; Sprite for graphics 86, 94
;
; 24 by 25 pixels.
SPRITE86:
  DEFB $03,$19            ; Width in bytes, and height in rows
  DEFB $00,$00,$3F,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$FF,$3F,$C0,$00 ; bottom row first
  DEFB $01,$00,$FF,$FF,$E0,$C0 ;
  DEFB $03,$01,$FF,$FF,$F0,$E0 ;
  DEFB $07,$03,$FF,$FF,$F8,$F0 ;
  DEFB $0F,$04,$FF,$7F,$F8,$F0 ;
  DEFB $1F,$00,$FF,$3F,$FC,$F8 ;
  DEFB $3F,$14,$FF,$3F,$FC,$B8 ;
  DEFB $3F,$1F,$FF,$BF,$FC,$D8 ;
  DEFB $3F,$19,$FF,$FF,$FC,$E8 ;
  DEFB $1F,$01,$FF,$FF,$F8,$F0 ;
  DEFB $1F,$05,$FF,$FF,$F8,$F0 ;
  DEFB $3F,$1D,$FF,$FF,$F8,$F0 ;
  DEFB $3F,$1D,$FF,$FF,$F8,$F0 ;
  DEFB $1F,$0F,$FF,$FF,$F8,$F0 ;
  DEFB $0F,$00,$FF,$FF,$F0,$E0 ;
  DEFB $0F,$01,$FF,$FF,$F0,$E0 ;
  DEFB $1F,$0E,$FF,$BF,$E0,$C0 ;
  DEFB $3F,$1F,$BF,$1F,$C0,$80 ;
  DEFB $3F,$17,$9F,$0F,$E0,$00 ;
  DEFB $3F,$13,$8F,$00,$F0,$E0 ;
  DEFB $1F,$0E,$03,$01,$F8,$70 ;
  DEFB $0E,$00,$03,$01,$F8,$30 ;
  DEFB $00,$00,$01,$00,$F0,$E0 ;
  DEFB $00,$00,$00,$00,$E0,$00 ;

; Sprite for graphic 28
;
; 32 by 29 pixels.
SPRITE28:
  DEFB $04,$1D            ; Width in bytes, and height in rows
  DEFB $00,$00,$01,$00,$80,$00,$00,$00 ; Mask and image bytes, a pair per cell,
  DEFB $00,$00,$07,$00,$E0,$00,$00,$00 ; the bottom row first
  DEFB $00,$00,$1F,$06,$F8,$20,$00,$00 ;
  DEFB $00,$00,$7F,$1E,$FE,$58,$00,$00 ;
  DEFB $01,$00,$FF,$7D,$FF,$AA,$80,$00 ;
  DEFB $07,$01,$FF,$FD,$FF,$95,$E0,$00 ;
  DEFB $1F,$07,$FF,$FD,$FF,$AA,$F8,$A0 ;
  DEFB $7F,$1F,$FF,$FD,$FF,$95,$FE,$50 ;
  DEFB $FF,$7F,$FF,$FB,$FF,$CA,$FF,$AA ;
  DEFB $7F,$3F,$FF,$FB,$FF,$D5,$FE,$54 ;
  DEFB $7F,$3F,$FF,$FB,$FF,$CA,$FE,$A8 ;
  DEFB $7F,$1F,$FF,$FB,$FF,$D5,$FE,$50 ;
  DEFB $7F,$2F,$FF,$F7,$FF,$EA,$FE,$A4 ;
  DEFB $3F,$0F,$FF,$F7,$FF,$E5,$FC,$50 ;
  DEFB $3F,$17,$FF,$F7,$FF,$EA,$FC,$A8 ;
  DEFB $3F,$1B,$FF,$C0,$FF,$01,$FC,$58 ;
  DEFB $1F,$0B,$FF,$3F,$FF,$FC,$F8,$90 ;
  DEFB $1F,$0C,$FF,$FF,$FF,$FF,$F8,$30 ;
  DEFB $0F,$05,$FF,$FF,$FF,$FF,$F0,$A0 ;
  DEFB $0F,$05,$FF,$FF,$FF,$FF,$F0,$A0 ;
  DEFB $0F,$05,$FF,$FF,$FF,$FF,$F0,$A0 ;
  DEFB $07,$01,$FF,$FF,$FF,$FF,$E0,$80 ;
  DEFB $03,$01,$FF,$FF,$FF,$FF,$C0,$80 ;
  DEFB $01,$00,$FF,$FF,$FF,$FF,$C0,$00 ;
  DEFB $00,$00,$FF,$3F,$FF,$FC,$00,$00 ;
  DEFB $00,$00,$3F,$00,$FC,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;

; Sprite for graphic 29
;
; 32 by 27 pixels.
SPRITE29:
  DEFB $04,$1B            ; Width in bytes, and height in rows
  DEFB $00,$00,$3F,$00,$FC,$00,$00,$00 ; Mask and image bytes, a pair per cell,
  DEFB $00,$00,$FF,$2F,$FF,$F4,$00,$00 ; the bottom row first
  DEFB $01,$00,$FF,$EF,$FF,$F5,$80,$00 ;
  DEFB $03,$01,$FF,$E7,$FF,$F2,$C0,$80 ;
  DEFB $03,$01,$FF,$F7,$FF,$E5,$C0,$00 ;
  DEFB $07,$03,$FF,$FB,$FF,$CA,$E0,$80 ;
  DEFB $07,$03,$FF,$FB,$FF,$D5,$E0,$40 ;
  DEFB $0F,$07,$FF,$FD,$FF,$AA,$F0,$A0 ;
  DEFB $0F,$07,$FF,$FD,$FF,$95,$F0,$40 ;
  DEFB $1F,$0F,$FF,$FE,$FF,$2A,$F8,$B0 ;
  DEFB $1F,$0F,$FF,$FE,$FF,$55,$F8,$50 ;
  DEFB $3F,$1F,$FF,$F9,$FF,$8A,$FC,$A8 ;
  DEFB $3F,$1F,$FF,$E7,$FF,$E5,$FC,$50 ;
  DEFB $7F,$3F,$FF,$9F,$FF,$F8,$FE,$A8 ;
  DEFB $7F,$3E,$FF,$7F,$FF,$FE,$FE,$54 ;
  DEFB $FF,$79,$FF,$FF,$FF,$FF,$FF,$9A ;
  DEFB $FF,$67,$FF,$FF,$FF,$FF,$FF,$E4 ;
  DEFB $FF,$1F,$FF,$FF,$FF,$FF,$FF,$F8 ;
  DEFB $FF,$7F,$FF,$FF,$FF,$FF,$FF,$FE ;
  DEFB $7F,$1F,$FF,$FF,$FF,$FF,$FE,$F8 ;
  DEFB $1F,$07,$FF,$FF,$FF,$FF,$F8,$E0 ;
  DEFB $07,$01,$FF,$FF,$FF,$FF,$E0,$80 ;
  DEFB $01,$00,$FF,$7F,$FF,$FE,$80,$00 ;
  DEFB $00,$00,$7F,$1F,$FE,$F8,$00,$00 ;
  DEFB $00,$00,$1F,$07,$F8,$E0,$00,$00 ;
  DEFB $00,$00,$07,$01,$E0,$80,$00,$00 ;
  DEFB $00,$00,$01,$00,$80,$00,$00,$00 ;

; Sprite for graphics 30-31, 44-45, 47, 66-71, 128
;
; 32 by 29 pixels.
SPRITE30:
  DEFB $04,$1D            ; Width in bytes, and height in rows
  DEFB $00,$00,$01,$00,$80,$00,$00,$00 ; Mask and image bytes, a pair per cell,
  DEFB $00,$00,$07,$01,$E0,$80,$00,$00 ; the bottom row first
  DEFB $00,$00,$1F,$05,$F8,$20,$00,$00 ;
  DEFB $00,$00,$7F,$1D,$FE,$50,$00,$00 ;
  DEFB $01,$00,$FF,$7B,$FF,$AA,$80,$00 ;
  DEFB $07,$01,$FF,$FB,$FF,$95,$E0,$00 ;
  DEFB $1F,$07,$FF,$F7,$FF,$CA,$F8,$A0 ;
  DEFB $7F,$1F,$FF,$F0,$FF,$15,$FE,$50 ;
  DEFB $FF,$7F,$FF,$F7,$FF,$CA,$FF,$AA ;
  DEFB $7F,$3F,$FF,$FB,$FF,$95,$FE,$54 ;
  DEFB $7F,$3F,$FF,$FB,$FF,$AA,$FE,$A8 ;
  DEFB $3F,$1F,$FF,$FD,$FF,$55,$FC,$50 ;
  DEFB $3F,$1F,$FF,$FC,$FF,$AA,$FC,$A8 ;
  DEFB $1F,$0F,$FF,$F9,$FF,$95,$F8,$50 ;
  DEFB $3F,$1F,$FF,$E7,$FF,$E2,$FC,$A0 ;
  DEFB $3F,$1F,$FF,$9F,$FF,$F9,$FC,$50 ;
  DEFB $7F,$3E,$FF,$7F,$FF,$FE,$FE,$28 ;
  DEFB $7F,$39,$FF,$FF,$FF,$FF,$FE,$94 ;
  DEFB $FF,$67,$FF,$FF,$FF,$FF,$FF,$E2 ;
  DEFB $FF,$1F,$FF,$FF,$FF,$FF,$FF,$F8 ;
  DEFB $FF,$7F,$FF,$FF,$FF,$FF,$FF,$FE ;
  DEFB $7F,$1F,$FF,$FF,$FF,$FF,$FE,$F8 ;
  DEFB $1F,$07,$FF,$FF,$FF,$FF,$F8,$E0 ;
  DEFB $07,$01,$FF,$FF,$FF,$FF,$E0,$80 ;
  DEFB $01,$00,$FF,$7F,$FF,$FE,$80,$00 ;
  DEFB $00,$00,$7F,$1F,$FE,$F8,$00,$00 ;
  DEFB $00,$00,$1F,$07,$F8,$E0,$00,$00 ;
  DEFB $00,$00,$07,$01,$E0,$80,$00,$00 ;
  DEFB $00,$00,$01,$00,$80,$00,$00,$00 ;

; Sprite for graphics 87, 95
;
; 24 by 25 pixels.
SPRITE87:
  DEFB $03,$19            ; Width in bytes, and height in rows
  DEFB $00,$00,$7E,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $01,$00,$FF,$7E,$80,$00 ; bottom row first
  DEFB $03,$01,$FF,$F7,$E0,$80 ;
  DEFB $07,$03,$FF,$FB,$F4,$E0 ;
  DEFB $0F,$07,$FF,$83,$FE,$F4 ;
  DEFB $0F,$07,$FF,$07,$FF,$F2 ;
  DEFB $0F,$06,$FF,$3F,$FF,$F6 ;
  DEFB $07,$02,$FF,$47,$FE,$F4 ;
  DEFB $07,$03,$FF,$BF,$FC,$A0 ;
  DEFB $03,$01,$FF,$7E,$FC,$58 ;
  DEFB $01,$00,$FF,$FD,$FE,$BC ;
  DEFB $03,$01,$FF,$FF,$FE,$BC ;
  DEFB $03,$01,$FF,$FF,$FC,$D8 ;
  DEFB $03,$01,$FF,$B7,$F8,$E0 ;
  DEFB $03,$01,$FF,$72,$E0,$C0 ;
  DEFB $07,$00,$FF,$FE,$E0,$40 ;
  DEFB $0F,$07,$FF,$5F,$C0,$80 ;
  DEFB $1F,$0F,$FF,$BF,$80,$00 ;
  DEFB $1F,$0B,$FF,$9C,$C0,$80 ;
  DEFB $1F,$09,$FF,$81,$E0,$00 ;
  DEFB $0F,$07,$83,$00,$F0,$E0 ;
  DEFB $07,$00,$03,$01,$F8,$70 ;
  DEFB $00,$00,$03,$01,$F8,$30 ;
  DEFB $00,$00,$01,$00,$F0,$E0 ;
  DEFB $00,$00,$00,$00,$E0,$00 ;

; Sprite for graphic 75
;
; 32 by 25 pixels.
SPRITE75:
  DEFB $04,$19            ; Width in bytes, and height in rows
  DEFB $00,$00,$01,$00,$80,$00,$00,$00 ; Mask and image bytes, a pair per cell,
  DEFB $00,$00,$07,$01,$E0,$80,$00,$00 ; the bottom row first
  DEFB $00,$00,$1F,$07,$F8,$E0,$00,$00 ;
  DEFB $00,$00,$7F,$1E,$FE,$78,$00,$00 ;
  DEFB $01,$00,$FF,$79,$FF,$9E,$80,$00 ;
  DEFB $07,$01,$FF,$E7,$FF,$E7,$E0,$80 ;
  DEFB $1F,$07,$FF,$9C,$FF,$39,$F8,$E0 ;
  DEFB $7F,$1E,$FF,$78,$FF,$CE,$FE,$78 ;
  DEFB $FF,$79,$FF,$F4,$FF,$EF,$FF,$9E ;
  DEFB $FF,$66,$FF,$14,$FF,$28,$FF,$66 ;
  DEFB $FF,$1C,$FF,$63,$FF,$C1,$FF,$B8 ;
  DEFB $FF,$7A,$FF,$77,$FF,$E9,$FF,$DE ;
  DEFB $7F,$1A,$FF,$77,$FF,$E9,$FE,$D8 ;
  DEFB $1F,$02,$FF,$73,$FF,$C9,$F8,$C0 ;
  DEFB $07,$02,$FF,$70,$FF,$09,$E0,$C0 ;
  DEFB $07,$02,$FF,$71,$FF,$C9,$E0,$C0 ;
  DEFB $07,$02,$FF,$11,$FF,$C9,$E0,$C0 ;
  DEFB $07,$01,$FF,$E1,$FF,$C9,$E0,$C0 ;
  DEFB $07,$03,$FF,$F1,$FF,$C9,$E0,$C0 ;
  DEFB $07,$03,$FF,$F0,$FF,$48,$E0,$40 ;
  DEFB $03,$01,$FF,$E7,$FF,$87,$E0,$80 ;
  DEFB $01,$00,$FF,$0F,$FF,$CF,$E0,$C0 ;
  DEFB $00,$00,$1F,$0F,$FF,$CF,$E0,$C0 ;
  DEFB $00,$00,$0F,$07,$CF,$87,$C0,$80 ;
  DEFB $00,$00,$07,$00,$87,$00,$80,$00 ;

; Sprite for graphic 2
;
; 16 by 62 pixels.
SPRITE2:
  DEFB $02,$3E            ; Width in bytes, and height in rows
  DEFB $0F,$00,$80,$00    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $1F,$0B,$E0,$00    ; row first
  DEFB $3F,$1B,$F8,$60    ;
  DEFB $3F,$1B,$FE,$78    ;
  DEFB $3F,$1B,$FF,$7E    ;
  DEFB $3F,$1B,$FF,$7E    ;
  DEFB $3F,$1B,$FF,$7E    ;
  DEFB $3F,$1B,$FF,$7E    ;
  DEFB $3F,$1B,$FF,$7E    ;
  DEFB $3F,$1B,$FF,$7E    ;
  DEFB $3F,$1B,$FF,$7E    ;
  DEFB $3F,$1B,$FF,$7E    ;
  DEFB $3F,$1B,$FF,$7E    ;
  DEFB $3F,$1B,$FF,$7E    ;
  DEFB $3F,$1B,$FF,$7E    ;
  DEFB $3F,$1B,$FF,$7E    ;
  DEFB $3F,$1B,$FF,$7E    ;
  DEFB $3F,$1B,$FF,$7E    ;
  DEFB $3F,$1B,$FF,$7E    ;
  DEFB $3F,$1B,$FF,$7E    ;
  DEFB $3F,$1B,$FF,$7E    ;
  DEFB $3F,$1B,$FF,$7E    ;
  DEFB $3F,$1B,$FF,$7E    ;
  DEFB $3F,$1B,$FF,$7E    ;
  DEFB $3F,$1B,$FF,$7E    ;
  DEFB $3F,$1B,$FF,$7E    ;
  DEFB $3F,$1B,$FF,$7E    ;
  DEFB $3F,$1B,$FF,$7E    ;
  DEFB $3F,$1B,$FF,$7E    ;
  DEFB $3F,$1B,$FF,$7E    ;
  DEFB $3F,$1B,$FF,$7E    ;
  DEFB $3F,$1B,$FF,$7E    ;
  DEFB $3F,$1B,$FF,$7E    ;
  DEFB $3F,$1B,$FF,$7E    ;
  DEFB $3F,$1B,$FF,$7E    ;
  DEFB $3F,$1B,$FF,$7E    ;
  DEFB $3F,$1B,$FF,$7E    ;
  DEFB $3F,$1B,$FF,$7E    ;
  DEFB $3F,$1B,$FF,$7F    ;
  DEFB $3F,$1B,$FF,$7F    ;
  DEFB $3F,$1B,$FF,$7F    ;
  DEFB $3F,$1A,$FF,$7F    ;
  DEFB $3F,$19,$FF,$BF    ;
  DEFB $3F,$03,$FF,$BF    ;
  DEFB $1F,$0D,$FF,$DF    ;
  DEFB $1F,$0D,$FF,$EF    ;
  DEFB $0F,$06,$FF,$EF    ;
  DEFB $07,$03,$FF,$77    ;
  DEFB $07,$03,$FF,$7B    ;
  DEFB $03,$01,$FF,$B9    ;
  DEFB $01,$00,$FF,$D6    ;
  DEFB $01,$00,$FF,$CF    ;
  DEFB $00,$00,$FF,$33    ;
  DEFB $00,$00,$7F,$1C    ;
  DEFB $00,$00,$1F,$07    ;
  DEFB $00,$00,$07,$01    ;
  DEFB $00,$00,$01,$00    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00,$00,$00,$00    ;

; Sprite for graphic 3
;
; 24 by 48 pixels.
SPRITE3:
  DEFB $03,$30            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$1C,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$00,$00,$7E,$14 ; bottom row first
  DEFB $00,$00,$01,$00,$FF,$56 ;
  DEFB $00,$00,$07,$01,$FF,$D6 ;
  DEFB $00,$00,$1F,$07,$FF,$D6 ;
  DEFB $00,$00,$3F,$1F,$FF,$D6 ;
  DEFB $00,$00,$3F,$1F,$FF,$D6 ;
  DEFB $00,$00,$3F,$1F,$FF,$D6 ;
  DEFB $00,$00,$3F,$1F,$FF,$D6 ;
  DEFB $00,$00,$3F,$1F,$FF,$D6 ;
  DEFB $00,$00,$3F,$1F,$FF,$D6 ;
  DEFB $00,$00,$3F,$1F,$FF,$D6 ;
  DEFB $00,$00,$3F,$1F,$FF,$D6 ;
  DEFB $00,$00,$3F,$1F,$FF,$D6 ;
  DEFB $00,$00,$3F,$1F,$FF,$D6 ;
  DEFB $00,$00,$3F,$1F,$FF,$D6 ;
  DEFB $00,$00,$3F,$1F,$FF,$D6 ;
  DEFB $00,$00,$3F,$1F,$FF,$D6 ;
  DEFB $00,$00,$3F,$1F,$FF,$D6 ;
  DEFB $00,$00,$3F,$1F,$FF,$D6 ;
  DEFB $00,$00,$3F,$1E,$FF,$D6 ;
  DEFB $00,$00,$3F,$18,$FF,$D6 ;
  DEFB $00,$00,$3F,$12,$FF,$D6 ;
  DEFB $80,$00,$3F,$14,$FF,$D6 ;
  DEFB $C0,$80,$3F,$12,$FF,$D6 ;
  DEFB $C0,$80,$3F,$14,$FF,$D6 ;
  DEFB $E0,$C0,$3F,$11,$FF,$D6 ;
  DEFB $E0,$C0,$3F,$17,$FF,$D6 ;
  DEFB $F8,$E0,$3F,$1F,$FF,$D6 ;
  DEFB $FE,$F8,$3F,$1F,$FF,$D6 ;
  DEFB $FF,$FE,$BF,$1F,$FF,$D6 ;
  DEFB $FF,$FF,$FF,$9F,$FF,$AE ;
  DEFB $FF,$FF,$FF,$E7,$FF,$5E ;
  DEFB $FF,$FF,$FF,$F8,$FF,$BE ;
  DEFB $FF,$FF,$FF,$FE,$FF,$7E ;
  DEFB $FF,$7F,$FF,$FF,$FF,$FE ;
  DEFB $FF,$9F,$FF,$FF,$FF,$FE ;
  DEFB $FF,$E7,$FF,$FF,$FF,$FC ;
  DEFB $FF,$F9,$FF,$FF,$FF,$FA ;
  DEFB $FF,$3E,$FF,$7F,$FE,$F4 ;
  DEFB $FF,$CF,$FF,$9F,$FE,$EC ;
  DEFB $FF,$73,$FF,$E7,$FC,$D8 ;
  DEFB $7F,$1C,$FF,$F9,$F8,$B0 ;
  DEFB $1F,$07,$FF,$3E,$F0,$60 ;
  DEFB $07,$01,$FF,$CF,$E0,$40 ;
  DEFB $01,$00,$FF,$72,$C0,$00 ;
  DEFB $00,$00,$7E,$1C,$00,$00 ;
  DEFB $00,$00,$1C,$00,$00,$00 ;

; Sprite for graphic 13
;
; 24 by 56 pixels.
SPRITE13:
  DEFB $03,$38            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$03,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$00,$00,$0F,$03 ; bottom row first
  DEFB $00,$00,$00,$00,$3F,$0F ;
  DEFB $00,$00,$00,$00,$FF,$3F ;
  DEFB $00,$00,$03,$00,$FF,$FF ;
  DEFB $00,$00,$0F,$03,$FF,$FF ;
  DEFB $00,$00,$3F,$07,$FF,$FF ;
  DEFB $00,$00,$FF,$3B,$FF,$FC ;
  DEFB $03,$00,$FF,$FD,$FF,$F3 ;
  DEFB $0F,$03,$FF,$FE,$FF,$CF ;
  DEFB $3F,$07,$FF,$FF,$FF,$3F ;
  DEFB $FF,$2F,$FF,$FF,$FF,$7F ;
  DEFB $FF,$EF,$FF,$FE,$FF,$FF ;
  DEFB $FF,$DF,$FF,$FE,$FF,$FF ;
  DEFB $FF,$DF,$FF,$FD,$FF,$FF ;
  DEFB $FF,$BF,$FF,$FD,$FF,$FF ;
  DEFB $FF,$BF,$FF,$FB,$FF,$FF ;
  DEFB $FF,$7F,$FF,$FB,$FF,$FF ;
  DEFB $FF,$7F,$FF,$F7,$FF,$FF ;
  DEFB $FF,$7F,$FF,$F7,$FF,$FF ;
  DEFB $FF,$BF,$FF,$CB,$FF,$FC ;
  DEFB $FF,$DF,$FF,$3D,$FF,$F3 ;
  DEFB $FF,$EC,$FF,$FE,$FF,$CF ;
  DEFB $FF,$F3,$FF,$FF,$FF,$3F ;
  DEFB $FF,$EF,$FF,$FF,$FF,$7F ;
  DEFB $FF,$EF,$FF,$FE,$FF,$FF ;
  DEFB $FF,$DF,$FF,$FE,$FF,$FF ;
  DEFB $FF,$DF,$FF,$FD,$FF,$FF ;
  DEFB $FF,$BF,$FF,$FD,$FF,$FF ;
  DEFB $FF,$BF,$FF,$FB,$FF,$FF ;
  DEFB $FF,$7F,$FF,$FB,$FF,$FF ;
  DEFB $FF,$7F,$FF,$F7,$FF,$FF ;
  DEFB $FF,$7F,$FF,$F7,$FF,$FF ;
  DEFB $FF,$BF,$FF,$CB,$FF,$FC ;
  DEFB $FF,$DF,$FF,$3D,$FF,$F3 ;
  DEFB $FF,$EC,$FF,$FE,$FF,$CC ;
  DEFB $FF,$E3,$FF,$FF,$FC,$30 ;
  DEFB $FF,$EF,$FF,$FF,$F0,$40 ;
  DEFB $FF,$EF,$FF,$FE,$C0,$80 ;
  DEFB $FF,$DF,$FF,$FE,$C0,$80 ;
  DEFB $FF,$DF,$FF,$FD,$80,$00 ;
  DEFB $FF,$BF,$FF,$FD,$80,$00 ;
  DEFB $FF,$BF,$FF,$FA,$00,$00 ;
  DEFB $FF,$7F,$FF,$FA,$00,$00 ;
  DEFB $FF,$7F,$FE,$F4,$00,$00 ;
  DEFB $FF,$7F,$FE,$F4,$00,$00 ;
  DEFB $FF,$BF,$FE,$C4,$00,$00 ;
  DEFB $FF,$5F,$FF,$3A,$00,$00 ;
  DEFB $7F,$2C,$FF,$C5,$80,$00 ;
  DEFB $3F,$13,$C5,$00,$00,$00 ;
  DEFB $7F,$2C,$00,$00,$00,$00 ;
  DEFB $7C,$28,$00,$00,$00,$00 ;
  DEFB $F8,$50,$00,$00,$00,$00 ;
  DEFB $F8,$50,$00,$00,$00,$00 ;
  DEFB $F0,$A0,$00,$00,$00,$00 ;
  DEFB $E0,$00,$00,$00,$00,$00 ;

; Sprite for graphic 15
;
; 16 by 52 pixels.
SPRITE15:
  DEFB $02,$34            ; Width in bytes, and height in rows
  DEFB $00,$00,$03,$00    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $00,$00,$0F,$03    ; row first
  DEFB $00,$00,$3F,$07    ;
  DEFB $00,$00,$FF,$3B    ;
  DEFB $03,$00,$FF,$FD    ;
  DEFB $0F,$03,$FF,$FE    ;
  DEFB $3F,$07,$FF,$FF    ;
  DEFB $FF,$2F,$FF,$FF    ;
  DEFB $FF,$EF,$FF,$FE    ;
  DEFB $FF,$DF,$FF,$FE    ;
  DEFB $FF,$DF,$FF,$FD    ;
  DEFB $FF,$BF,$FF,$FD    ;
  DEFB $FF,$BF,$FF,$FB    ;
  DEFB $FF,$7F,$FF,$FB    ;
  DEFB $FF,$7F,$FF,$F7    ;
  DEFB $FF,$7F,$FF,$F7    ;
  DEFB $FF,$BF,$FF,$CB    ;
  DEFB $FF,$DF,$FF,$3D    ;
  DEFB $FF,$EC,$FF,$FE    ;
  DEFB $FF,$F3,$FF,$FF    ;
  DEFB $FF,$EF,$FF,$FF    ;
  DEFB $FF,$EF,$FF,$FE    ;
  DEFB $FF,$DF,$FF,$FE    ;
  DEFB $FF,$DF,$FF,$FD    ;
  DEFB $FF,$BF,$FF,$FD    ;
  DEFB $FF,$BF,$FF,$FB    ;
  DEFB $FF,$7F,$FF,$FB    ;
  DEFB $FF,$7F,$FF,$F7    ;
  DEFB $FF,$7F,$FF,$F7    ;
  DEFB $FF,$BF,$FF,$CB    ;
  DEFB $FF,$DF,$FF,$3D    ;
  DEFB $FF,$EC,$FF,$FE    ;
  DEFB $FF,$E3,$FF,$FF    ;
  DEFB $FF,$EF,$FF,$FF    ;
  DEFB $FF,$EF,$FF,$FE    ;
  DEFB $FF,$DF,$FF,$FE    ;
  DEFB $FF,$DF,$FF,$FD    ;
  DEFB $FF,$BF,$FF,$FD    ;
  DEFB $FF,$BF,$FF,$FA    ;
  DEFB $FF,$7F,$FF,$FA    ;
  DEFB $FF,$7F,$FE,$F4    ;
  DEFB $FF,$7F,$FE,$F4    ;
  DEFB $FF,$BF,$FE,$C4    ;
  DEFB $FF,$5F,$FF,$3A    ;
  DEFB $7F,$2C,$FF,$C5    ;
  DEFB $3F,$13,$C5,$00    ;
  DEFB $7F,$2C,$00,$00    ;
  DEFB $7C,$28,$00,$00    ;
  DEFB $F8,$50,$00,$00    ;
  DEFB $F8,$50,$00,$00    ;
  DEFB $F0,$A0,$00,$00    ;
  DEFB $E0,$00,$00,$00    ;

; Sprite for graphic 4
;
; 32 by 32 pixels.
SPRITE4:
  DEFB $04,$20            ; Width in bytes, and height in rows
  DEFB $EF,$EF,$FF,$FF,$70,$70,$00,$00 ; Mask and image bytes, a pair per cell,
  DEFB $EF,$EF,$FF,$FF,$70,$70,$00,$00 ; the bottom row first
  DEFB $FF,$FF,$FF,$FF,$F0,$F0,$00,$00 ;
  DEFB $80,$80,$00,$00,$20,$20,$00,$00 ;
  DEFB $7F,$7F,$FC,$FC,$10,$10,$00,$00 ;
  DEFB $3F,$3F,$83,$83,$E0,$E0,$00,$00 ;
  DEFB $10,$10,$7F,$7F,$F0,$F0,$00,$00 ;
  DEFB $3F,$3F,$FF,$FF,$20,$20,$00,$00 ;
  DEFB $7F,$7F,$F9,$F9,$98,$98,$00,$00 ;
  DEFB $FF,$FF,$C6,$C6,$3C,$3C,$00,$00 ;
  DEFB $7E,$7E,$39,$39,$DE,$DE,$00,$00 ;
  DEFB $38,$38,$E7,$E7,$EF,$EF,$00,$00 ;
  DEFB $17,$17,$9F,$9F,$F7,$F7,$57,$57 ;
  DEFB $3E,$3E,$7F,$7F,$FA,$FA,$EF,$EF ;
  DEFB $79,$79,$FF,$FF,$FC,$FC,$67,$67 ;
  DEFB $E7,$E7,$FF,$FF,$FD,$FD,$64,$64 ;
  DEFB $0F,$0F,$FF,$FF,$FD,$FD,$E7,$E7 ;
  DEFB $F7,$F7,$FF,$FF,$FA,$FA,$E7,$E7 ;
  DEFB $7B,$7B,$FF,$FF,$FA,$FA,$D7,$D7 ;
  DEFB $3D,$3D,$FF,$FF,$F5,$F5,$D7,$D7 ;
  DEFB $1E,$1E,$FF,$FF,$F5,$F5,$D7,$D7 ;
  DEFB $0F,$0F,$7F,$7F,$ED,$ED,$D7,$D7 ;
  DEFB $07,$07,$BF,$BF,$EB,$EB,$D7,$D7 ;
  DEFB $03,$03,$DF,$DF,$DB,$DB,$B7,$B7 ;
  DEFB $01,$01,$EF,$EF,$D3,$D3,$B7,$B7 ;
  DEFB $00,$00,$F7,$F7,$B7,$B7,$B7,$B7 ;
  DEFB $00,$00,$7B,$7B,$B7,$B7,$B7,$B7 ;
  DEFB $00,$00,$3D,$3D,$6F,$6F,$B7,$B7 ;
  DEFB $00,$00,$1E,$1E,$7F,$7F,$F4,$F4 ;
  DEFB $00,$00,$0E,$0E,$EF,$EF,$B7,$B7 ;
  DEFB $00,$00,$06,$06,$C7,$C7,$17,$17 ;
  DEFB $00,$00,$02,$02,$82,$82,$0F,$0F ;

; Sprite for graphic 6
;
; 8 by 24 pixels.
SPRITE6:
  DEFB $01,$18            ; Width in bytes, and height in rows
  DEFB $00,$00            ; Mask and image bytes, a pair per cell, the bottom
  DEFB $00,$00            ; row first
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $FF,$FF            ;
  DEFB $FF,$FF            ;
  DEFB $FF,$FF            ;
  DEFB $00,$00            ;
  DEFB $FF,$FF            ;
  DEFB $FF,$FF            ;
  DEFB $FF,$FF            ;
  DEFB $FF,$FF            ;
  DEFB $FF,$FF            ;
  DEFB $FF,$FF            ;
  DEFB $FF,$FF            ;
  DEFB $FF,$FF            ;
  DEFB $FF,$FF            ;
  DEFB $FF,$FF            ;
  DEFB $FF,$FF            ;
  DEFB $FF,$FF            ;
  DEFB $00,$00            ;
  DEFB $FF,$FF            ;
  DEFB $FF,$FF            ;
  DEFB $FF,$FF            ;

; Sprite for graphic 5
;
; 24 by 1 pixels.
SPRITE5:
  DEFB $03,$01            ; Width in bytes, and height in rows
  DEFB $EF,$EF,$FF,$FF,$70,$70 ; Mask and image bytes, a pair per cell, the
                               ; bottom row first

; Sprite for graphic 10
;
; 8 by 8 pixels.
SPRITE10:
  DEFB $01,$08            ; Width in bytes, and height in rows
  DEFB $FF,$FF            ; Mask and image bytes, a pair per cell, the bottom
  DEFB $FF,$FF            ; row first
  DEFB $C3,$C3            ;
  DEFB $C3,$C3            ;
  DEFB $C3,$C3            ;
  DEFB $C3,$C3            ;
  DEFB $FF,$FF            ;
  DEFB $FF,$FF            ;

; Sprite for graphic 7
;
; 16 by 12 pixels.
SPRITE7:
  DEFB $02,$0C            ; Width in bytes, and height in rows
  DEFB $FB,$FB,$00,$00    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $F1,$F1,$C0,$C0    ; row first
  DEFB $E0,$E0,$E0,$E0    ;
  DEFB $70,$70,$70,$70    ;
  DEFB $38,$38,$F8,$F8    ;
  DEFB $1D,$1D,$FC,$FC    ;
  DEFB $0F,$0F,$FE,$FE    ;
  DEFB $07,$07,$FF,$FF    ;
  DEFB $03,$03,$FF,$FF    ;
  DEFB $01,$01,$FC,$FC    ;
  DEFB $00,$00,$F0,$F0    ;
  DEFB $00,$00,$40,$40    ;

; Sprite for graphic 8
;
; 16 by 16 pixels.
SPRITE8:
  DEFB $02,$10            ; Width in bytes, and height in rows
  DEFB $FF,$FF,$F0,$F0    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $1F,$1F,$F0,$F0    ; row first
  DEFB $1F,$1F,$38,$38    ;
  DEFB $0E,$0E,$38,$38    ;
  DEFB $0E,$0E,$1C,$1C    ;
  DEFB $07,$07,$1C,$1C    ;
  DEFB $07,$07,$0E,$0E    ;
  DEFB $03,$03,$9E,$9E    ;
  DEFB $03,$03,$FF,$FF    ;
  DEFB $01,$01,$FC,$FC    ;
  DEFB $01,$01,$F0,$F0    ;
  DEFB $00,$00,$C0,$C0    ;
  DEFB $03,$03,$00,$00    ;
  DEFB $0C,$0C,$00,$00    ;
  DEFB $30,$30,$00,$00    ;
  DEFB $C0,$C0,$00,$00    ;

; Sprite for graphic 9
;
; 16 by 8 pixels.
SPRITE9:
  DEFB $02,$08            ; Width in bytes, and height in rows
  DEFB $00,$00,$03,$03    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $00,$00,$0C,$0C    ; row first
  DEFB $00,$00,$30,$30    ;
  DEFB $00,$00,$C0,$C0    ;
  DEFB $03,$03,$00,$00    ;
  DEFB $0C,$0C,$00,$00    ;
  DEFB $30,$30,$00,$00    ;
  DEFB $C0,$C0,$00,$00    ;

; Sprite for graphic 72
;
; 32 by 24 pixels.
SPRITE72:
  DEFB $04,$18            ; Width in bytes, and height in rows
  DEFB $00,$00,$01,$00,$80,$00,$00,$00 ; Mask and image bytes, a pair per cell,
  DEFB $00,$00,$07,$01,$E0,$80,$00,$00 ; the bottom row first
  DEFB $00,$00,$1F,$06,$F8,$E0,$00,$00 ;
  DEFB $00,$00,$7F,$1E,$FE,$F8,$00,$00 ;
  DEFB $01,$00,$FF,$7E,$FF,$FE,$80,$00 ;
  DEFB $07,$01,$FF,$FA,$FF,$FF,$E0,$80 ;
  DEFB $1F,$07,$FF,$E2,$FF,$FF,$F8,$E0 ;
  DEFB $7F,$1F,$FF,$9A,$FF,$FF,$FE,$F8 ;
  DEFB $FF,$7E,$FF,$7A,$FF,$FF,$FF,$FE ;
  DEFB $7F,$38,$FF,$FA,$FF,$FF,$FE,$FC ;
  DEFB $3F,$1D,$FF,$7A,$FF,$FF,$FC,$F8 ;
  DEFB $1F,$0E,$FF,$9A,$FF,$FF,$F8,$F0 ;
  DEFB $0F,$07,$FF,$6A,$FF,$FF,$F0,$E0 ;
  DEFB $07,$03,$FF,$BA,$FF,$FF,$E0,$C0 ;
  DEFB $03,$01,$FF,$DA,$FF,$FF,$C0,$80 ;
  DEFB $01,$00,$FF,$EA,$FF,$FF,$80,$00 ;
  DEFB $00,$00,$FF,$72,$FF,$FE,$00,$00 ;
  DEFB $00,$00,$7F,$3A,$FE,$FC,$00,$00 ;
  DEFB $00,$00,$3F,$1E,$FC,$F8,$00,$00 ;
  DEFB $00,$00,$1F,$0E,$F8,$F0,$00,$00 ;
  DEFB $00,$00,$0F,$06,$F0,$E0,$00,$00 ;
  DEFB $00,$00,$07,$02,$E0,$C0,$00,$00 ;
  DEFB $00,$00,$03,$01,$C0,$80,$00,$00 ;
  DEFB $00,$00,$01,$00,$80,$00,$00,$00 ;

; Sprite for graphic 12
;
; 16 by 17 pixels.
SPRITE12:
  DEFB $02,$11            ; Width in bytes, and height in rows
  DEFB $0E,$00,$38,$00    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $1F,$0E,$7C,$38    ; row first
  DEFB $1F,$0B,$FC,$78    ;
  DEFB $0F,$05,$F8,$70    ;
  DEFB $07,$03,$F0,$60    ;
  DEFB $0F,$03,$F8,$E0    ;
  DEFB $1F,$0D,$FC,$F8    ;
  DEFB $1F,$0D,$FC,$F8    ;
  DEFB $1F,$0D,$FC,$F8    ;
  DEFB $1F,$0D,$FC,$F8    ;
  DEFB $1F,$0E,$FC,$38    ;
  DEFB $0F,$01,$F8,$C0    ;
  DEFB $0F,$07,$F8,$F0    ;
  DEFB $0F,$07,$F8,$F0    ;
  DEFB $07,$02,$F0,$A0    ;
  DEFB $07,$03,$F0,$E0    ;
  DEFB $03,$00,$E0,$00    ;

; Sprite for graphics 25, 90, 92
;
; 32 by 17 pixels.
SPRITE25:
  DEFB $04,$11            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell,
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; the bottom row first
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $03,$00,$FC,$00,$3F,$00,$C0,$00 ;
  DEFB $07,$03,$FE,$FC,$7F,$3F,$E0,$C0 ;
  DEFB $03,$01,$FC,$F8,$3F,$1F,$C0,$80 ;
  DEFB $01,$00,$F8,$F0,$1F,$0F,$80,$00 ;
  DEFB $03,$00,$FF,$00,$FF,$00,$C0,$00 ;
  DEFB $07,$03,$FF,$FF,$FF,$FF,$E0,$C0 ;
  DEFB $0F,$03,$FF,$FF,$FF,$FF,$F0,$C0 ;
  DEFB $1F,$0B,$FF,$F0,$FF,$0F,$F8,$D0 ;
  DEFB $1F,$0B,$FF,$F7,$FF,$EF,$F8,$D0 ;
  DEFB $1F,$0B,$FF,$F7,$FF,$EF,$F8,$D0 ;
  DEFB $1F,$09,$FF,$F0,$FF,$0F,$F8,$B0 ;
  DEFB $1F,$0D,$FF,$F8,$FF,$1F,$F8,$B0 ;
  DEFB $1F,$0D,$FF,$FB,$FF,$DF,$F8,$B0 ;

; Sprite for graphics 41, 91, 93
;
; 32 by 16 pixels.
SPRITE41:
  DEFB $04,$10            ; Width in bytes, and height in rows
  DEFB $1F,$0D,$FF,$F8,$FF,$1F,$F8,$B0 ; Mask and image bytes, a pair per cell,
  DEFB $1F,$0D,$FF,$FF,$FF,$FF,$F8,$B0 ; the bottom row first
  DEFB $0F,$05,$FF,$00,$FF,$00,$F0,$A0 ;
  DEFB $05,$00,$FF,$FF,$FF,$FF,$A0,$00 ;
  DEFB $00,$00,$FF,$00,$FF,$00,$80,$00 ;
  DEFB $01,$00,$FF,$FF,$FF,$FF,$80,$00 ;
  DEFB $01,$00,$FF,$F9,$FF,$9F,$80,$00 ;
  DEFB $00,$00,$FF,$74,$FF,$2E,$00,$00 ;
  DEFB $00,$00,$FF,$76,$FF,$6E,$00,$00 ;
  DEFB $00,$00,$7F,$39,$FE,$9C,$00,$00 ;
  DEFB $00,$00,$7F,$3F,$FE,$FC,$00,$00 ;
  DEFB $00,$00,$7F,$20,$FE,$04,$00,$00 ;
  DEFB $00,$00,$3F,$1F,$FC,$F8,$00,$00 ;
  DEFB $00,$00,$3F,$1F,$FC,$F8,$00,$00 ;
  DEFB $00,$00,$1F,$00,$F8,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;

; Sprite for graphic 24
;
; 32 by 17 pixels.
SPRITE24:
  DEFB $04,$11            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell,
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; the bottom row first
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $03,$00,$FC,$00,$3F,$00,$C0,$00 ;
  DEFB $07,$03,$FE,$FC,$7F,$3F,$E0,$C0 ;
  DEFB $03,$01,$FC,$F8,$3F,$1F,$C0,$80 ;
  DEFB $01,$00,$F8,$F0,$1F,$0F,$80,$00 ;
  DEFB $03,$00,$FF,$00,$FF,$00,$C0,$00 ;
  DEFB $07,$03,$FF,$FF,$FF,$FF,$E0,$C0 ;
  DEFB $0F,$03,$FF,$FF,$FF,$FF,$F0,$C0 ;
  DEFB $1F,$0B,$FF,$FF,$FF,$FF,$F8,$D0 ;
  DEFB $1F,$0B,$FF,$FF,$FF,$FF,$F8,$D0 ;
  DEFB $1F,$0B,$FF,$FF,$FF,$FF,$F8,$D0 ;
  DEFB $1F,$09,$FF,$FF,$FF,$FF,$F8,$B0 ;
  DEFB $1F,$0D,$FF,$FF,$FF,$FF,$F8,$B0 ;
  DEFB $1F,$0D,$FF,$FF,$FF,$FF,$F8,$B0 ;

; Sprite for graphic 40
;
; 32 by 16 pixels.
SPRITE40:
  DEFB $04,$10            ; Width in bytes, and height in rows
  DEFB $1F,$0D,$FF,$FF,$FF,$FF,$F8,$B0 ; Mask and image bytes, a pair per cell,
  DEFB $1F,$0D,$FF,$FF,$FF,$FF,$F8,$B0 ; the bottom row first
  DEFB $0F,$05,$FF,$00,$FF,$00,$F0,$A0 ;
  DEFB $05,$00,$FF,$FF,$FF,$FF,$A0,$00 ;
  DEFB $00,$00,$FF,$00,$FF,$00,$00,$00 ;
  DEFB $01,$00,$FF,$FF,$FF,$FF,$80,$00 ;
  DEFB $01,$00,$FF,$FF,$FF,$FF,$80,$00 ;
  DEFB $00,$00,$FF,$7F,$FF,$FE,$00,$00 ;
  DEFB $00,$00,$FF,$7F,$FF,$FE,$00,$00 ;
  DEFB $00,$00,$7F,$3F,$FE,$FC,$00,$00 ;
  DEFB $00,$00,$7F,$3F,$FE,$FC,$00,$00 ;
  DEFB $00,$00,$7F,$20,$FE,$04,$00,$00 ;
  DEFB $00,$00,$3F,$1F,$FC,$F8,$00,$00 ;
  DEFB $00,$00,$3F,$1F,$FC,$F8,$00,$00 ;
  DEFB $00,$00,$1F,$00,$F8,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;

; Sprite for graphics 26-27
;
; 32 by 17 pixels.
SPRITE26:
  DEFB $04,$11            ; Width in bytes, and height in rows
  DEFB $00,$00,$7F,$00,$FE,$00,$00,$00 ; Mask and image bytes, a pair per cell,
  DEFB $00,$00,$FF,$7F,$FF,$FE,$00,$00 ; the bottom row first
  DEFB $00,$00,$FF,$3F,$FF,$FA,$00,$00 ;
  DEFB $00,$00,$FF,$5F,$FE,$E4,$00,$00 ;
  DEFB $00,$00,$7F,$2F,$FC,$B8,$00,$00 ;
  DEFB $00,$00,$FF,$00,$FF,$00,$00,$00 ;
  DEFB $01,$00,$FF,$FF,$FF,$FF,$80,$00 ;
  DEFB $01,$00,$FF,$FF,$FF,$FF,$80,$00 ;
  DEFB $01,$00,$FF,$FC,$FF,$3F,$80,$00 ;
  DEFB $01,$00,$FF,$FC,$FF,$1F,$80,$00 ;
  DEFB $01,$00,$FF,$FE,$FF,$5F,$80,$00 ;
  DEFB $01,$00,$FF,$FE,$FF,$5E,$00,$00 ;
  DEFB $00,$00,$FF,$7C,$FF,$5E,$00,$00 ;
  DEFB $00,$00,$FF,$7C,$FF,$BE,$00,$00 ;
  DEFB $01,$00,$FF,$FC,$FF,$BF,$80,$00 ;
  DEFB $01,$00,$FF,$FC,$FF,$BF,$80,$00 ;
  DEFB $01,$00,$FF,$FD,$FF,$BF,$80,$00 ;

; Sprite for graphics 42-43
;
; 32 by 17 pixels.
SPRITE42:
  DEFB $04,$11            ; Width in bytes, and height in rows
  DEFB $01,$00,$FF,$BC,$FF,$7D,$80,$00 ; Mask and image bytes, a pair per cell,
  DEFB $01,$00,$FF,$BF,$FF,$FD,$80,$00 ; the bottom row first
  DEFB $00,$00,$FF,$7F,$FF,$FE,$00,$00 ;
  DEFB $00,$00,$FF,$40,$FF,$02,$00,$00 ;
  DEFB $00,$00,$FF,$5F,$FF,$FA,$00,$00 ;
  DEFB $00,$00,$FF,$40,$FF,$02,$00,$00 ;
  DEFB $00,$00,$7F,$3F,$FE,$FC,$00,$00 ;
  DEFB $00,$00,$7F,$3F,$FE,$FC,$00,$00 ;
  DEFB $00,$00,$7F,$3F,$FE,$FC,$00,$00 ;
  DEFB $00,$00,$7F,$2F,$FE,$F4,$00,$00 ;
  DEFB $00,$00,$7F,$37,$FE,$EC,$00,$00 ;
  DEFB $00,$00,$7F,$37,$FE,$EC,$00,$00 ;
  DEFB $00,$00,$3F,$18,$FC,$18,$00,$00 ;
  DEFB $00,$00,$3F,$1B,$FC,$D8,$00,$00 ;
  DEFB $00,$00,$1F,$0B,$F8,$D0,$00,$00 ;
  DEFB $00,$00,$1F,$0F,$F8,$F0,$00,$00 ;
  DEFB $00,$00,$0F,$00,$F0,$00,$00,$00 ;

; Sprite for graphic 20
;
; 32 by 17 pixels.
SPRITE20:
  DEFB $04,$11            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell,
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; the bottom row first
  DEFB $00,$00,$1E,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$7F,$1A,$80,$00,$00,$00 ;
  DEFB $01,$00,$FF,$77,$E3,$80,$80,$00 ;
  DEFB $07,$01,$FF,$E3,$FF,$E3,$F0,$80 ;
  DEFB $0F,$07,$FF,$CC,$FF,$CF,$FC,$70 ;
  DEFB $07,$03,$FF,$3B,$FF,$1C,$FE,$FC ;
  DEFB $03,$00,$FF,$FB,$FF,$CB,$FC,$F8 ;
  DEFB $07,$03,$FF,$FB,$FF,$F3,$F8,$F0 ;
  DEFB $0F,$07,$FF,$C3,$FF,$1C,$F0,$E0 ;
  DEFB $1F,$0F,$FF,$C3,$FF,$27,$E0,$00 ;
  DEFB $1F,$0F,$FF,$93,$FF,$33,$E0,$C0 ;
  DEFB $1F,$0F,$FF,$13,$FF,$19,$F0,$E0 ;
  DEFB $1F,$0E,$FF,$2B,$FF,$09,$F0,$E0 ;
  DEFB $1F,$0E,$FF,$2B,$FF,$A1,$E0,$C0 ;
  DEFB $1F,$0E,$FF,$DB,$FF,$B9,$E0,$C0 ;

; Sprite for graphic 36
;
; 32 by 17 pixels.
SPRITE36:
  DEFB $04,$11            ; Width in bytes, and height in rows
  DEFB $1F,$0E,$FF,$31,$FF,$CB,$E0,$C0 ; Mask and image bytes, a pair per cell,
  DEFB $0F,$07,$FF,$CE,$FF,$73,$C0,$80 ; the bottom row first
  DEFB $0F,$07,$FF,$3F,$FF,$9F,$C0,$80 ;
  DEFB $0F,$04,$FF,$F1,$FF,$E7,$C0,$80 ;
  DEFB $07,$03,$FF,$CE,$FF,$79,$C0,$80 ;
  DEFB $0F,$07,$FF,$3B,$FF,$9E,$80,$00 ;
  DEFB $07,$00,$FF,$FB,$FF,$E7,$80,$00 ;
  DEFB $07,$03,$FF,$FB,$FF,$38,$00,$00 ;
  DEFB $0F,$07,$FF,$F6,$FF,$9E,$80,$00 ;
  DEFB $07,$03,$FF,$F6,$FF,$E7,$C0,$80 ;
  DEFB $03,$01,$FF,$EB,$FF,$37,$80,$00 ;
  DEFB $01,$00,$FF,$9C,$FF,$C6,$00,$00 ;
  DEFB $00,$00,$FF,$7F,$FE,$3C,$00,$00 ;
  DEFB $00,$00,$7F,$1F,$FC,$C8,$00,$00 ;
  DEFB $00,$00,$1F,$07,$F8,$E0,$00,$00 ;
  DEFB $00,$00,$07,$01,$E0,$80,$00,$00 ;
  DEFB $00,$00,$01,$00,$80,$00,$00,$00 ;

; Sprite for graphics 21, 23
;
; 32 by 17 pixels.
SPRITE21:
  DEFB $04,$11            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell,
  DEFB $00,$00,$0F,$00,$00,$00,$00,$00 ; the bottom row first
  DEFB $00,$00,$3F,$0D,$C0,$00,$00,$00 ;
  DEFB $00,$00,$FF,$3B,$F0,$C0,$00,$00 ;
  DEFB $03,$00,$FF,$F7,$F8,$F0,$00,$00 ;
  DEFB $07,$03,$FF,$F3,$FF,$E0,$00,$00 ;
  DEFB $03,$01,$FF,$CC,$FF,$C7,$E0,$00 ;
  DEFB $01,$00,$FF,$3B,$FF,$1E,$F8,$E0 ;
  DEFB $03,$00,$FF,$FB,$FF,$C9,$FC,$F8 ;
  DEFB $07,$03,$FF,$9B,$FF,$F3,$F8,$F0 ;
  DEFB $0F,$06,$FF,$5B,$FF,$1C,$F0,$E0 ;
  DEFB $1F,$0E,$FF,$5B,$FF,$27,$E0,$00 ;
  DEFB $1F,$0E,$FF,$3B,$FF,$33,$E0,$C0 ;
  DEFB $1F,$0F,$FF,$3B,$FF,$19,$F0,$E0 ;
  DEFB $1F,$0E,$FF,$5B,$FF,$09,$F0,$E0 ;
  DEFB $1F,$0E,$FF,$5B,$FF,$A1,$E0,$C0 ;
  DEFB $1F,$0E,$FF,$BB,$FF,$B9,$E0,$C0 ;

; Sprite for graphics 37, 39
;
; 32 by 17 pixels.
SPRITE37:
  DEFB $04,$11            ; Width in bytes, and height in rows
  DEFB $1F,$0E,$FF,$71,$FF,$CB,$E0,$C0 ; Mask and image bytes, a pair per cell,
  DEFB $0F,$07,$FF,$CE,$FF,$73,$C0,$80 ; the bottom row first
  DEFB $0F,$07,$FF,$3F,$FF,$9F,$C0,$80 ;
  DEFB $0F,$04,$FF,$F1,$FF,$E7,$C0,$80 ;
  DEFB $07,$03,$FF,$CE,$FF,$79,$C0,$80 ;
  DEFB $0F,$07,$FF,$3B,$FF,$9E,$80,$00 ;
  DEFB $07,$00,$FF,$FB,$FF,$E7,$80,$00 ;
  DEFB $07,$03,$FF,$FB,$FF,$38,$00,$00 ;
  DEFB $0F,$07,$FF,$F6,$FF,$9E,$80,$00 ;
  DEFB $07,$03,$FF,$F6,$FF,$E7,$C0,$80 ;
  DEFB $03,$01,$FF,$EB,$FF,$37,$80,$00 ;
  DEFB $01,$00,$FF,$9C,$FF,$C6,$00,$00 ;
  DEFB $00,$00,$FF,$7F,$FE,$3C,$00,$00 ;
  DEFB $00,$00,$7F,$1F,$FC,$C8,$00,$00 ;
  DEFB $00,$00,$1F,$07,$F8,$E0,$00,$00 ;
  DEFB $00,$00,$07,$01,$E0,$80,$00,$00 ;
  DEFB $00,$00,$01,$00,$80,$00,$00,$00 ;

; Sprite for graphic 22
;
; 32 by 17 pixels.
SPRITE22:
  DEFB $04,$11            ; Width in bytes, and height in rows
  DEFB $00,$00,$07,$00,$80,$00,$00,$00 ; Mask and image bytes, a pair per cell,
  DEFB $00,$00,$1F,$06,$E0,$80,$00,$00 ; the bottom row first
  DEFB $00,$00,$7F,$1D,$F8,$E0,$00,$00 ;
  DEFB $01,$00,$FF,$7B,$FC,$F8,$00,$00 ;
  DEFB $03,$01,$FF,$F7,$F8,$F0,$00,$00 ;
  DEFB $01,$00,$FF,$F3,$F0,$E0,$00,$00 ;
  DEFB $00,$00,$FF,$4C,$FE,$C0,$00,$00 ;
  DEFB $00,$00,$FF,$3B,$FF,$0E,$C0,$00 ;
  DEFB $03,$00,$FF,$FB,$FF,$DD,$F0,$C0 ;
  DEFB $07,$03,$FF,$FB,$FF,$F3,$F8,$F0 ;
  DEFB $0F,$07,$FF,$FB,$FF,$1C,$F0,$E0 ;
  DEFB $1F,$0F,$FF,$FB,$FF,$27,$E0,$00 ;
  DEFB $1F,$08,$FF,$FB,$FF,$3B,$E0,$C0 ;
  DEFB $1F,$00,$FF,$3B,$FF,$19,$F0,$E0 ;
  DEFB $1F,$00,$FF,$5B,$FF,$09,$F0,$E0 ;
  DEFB $1F,$0C,$FF,$5B,$FF,$A1,$F8,$D0 ;
  DEFB $1F,$0E,$FF,$BB,$FF,$B9,$F8,$D0 ;

; Sprite for graphic 38
;
; 32 by 17 pixels.
SPRITE38:
  DEFB $04,$11            ; Width in bytes, and height in rows
  DEFB $1F,$0F,$FF,$71,$FF,$CB,$F8,$D0 ; Mask and image bytes, a pair per cell,
  DEFB $0F,$07,$FF,$CE,$FF,$73,$F8,$B0 ; the bottom row first
  DEFB $0F,$07,$FF,$3F,$FF,$9F,$F0,$A0 ;
  DEFB $0F,$04,$FF,$F1,$FF,$E7,$E0,$80 ;
  DEFB $07,$03,$FF,$CE,$FF,$79,$C0,$80 ;
  DEFB $0F,$07,$FF,$3B,$FF,$9E,$80,$00 ;
  DEFB $07,$00,$FF,$FB,$FF,$E7,$80,$00 ;
  DEFB $07,$03,$FF,$FB,$FF,$38,$00,$00 ;
  DEFB $0F,$07,$FF,$F6,$FF,$9E,$80,$00 ;
  DEFB $07,$03,$FF,$F6,$FF,$E7,$C0,$80 ;
  DEFB $03,$01,$FF,$CB,$FF,$37,$80,$00 ;
  DEFB $01,$00,$FF,$9C,$FF,$C6,$00,$00 ;
  DEFB $00,$00,$FF,$7F,$FE,$3C,$00,$00 ;
  DEFB $00,$00,$7F,$1F,$FC,$C8,$00,$00 ;
  DEFB $00,$00,$1F,$07,$F8,$E0,$00,$00 ;
  DEFB $00,$00,$07,$01,$E0,$80,$00,$00 ;
  DEFB $00,$00,$01,$00,$80,$00,$00,$00 ;

; Sprite for graphic 16
;
; 32 by 17 pixels.
SPRITE16:
  DEFB $04,$11            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell,
  DEFB $00,$00,$0D,$00,$00,$00,$00,$00 ; the bottom row first
  DEFB $00,$00,$3F,$0D,$C0,$00,$00,$00 ;
  DEFB $00,$00,$FF,$3D,$F0,$C0,$00,$00 ;
  DEFB $03,$00,$FF,$FD,$F8,$F0,$00,$00 ;
  DEFB $07,$03,$FF,$F3,$F8,$F0,$00,$00 ;
  DEFB $03,$00,$FF,$CC,$F0,$E0,$00,$00 ;
  DEFB $00,$00,$FF,$3B,$FC,$00,$00,$00 ;
  DEFB $03,$00,$FF,$FB,$FF,$D4,$00,$00 ;
  DEFB $07,$03,$FF,$FB,$FF,$F3,$C0,$00 ;
  DEFB $0F,$07,$FF,$C3,$FF,$FC,$E0,$C0 ;
  DEFB $1F,$0F,$FF,$D3,$FF,$FF,$C0,$00 ;
  DEFB $1F,$0F,$FF,$D3,$FF,$FF,$E0,$C0 ;
  DEFB $1F,$0F,$FF,$13,$FF,$FF,$F0,$E0 ;
  DEFB $1F,$0E,$FF,$2B,$FF,$FF,$F0,$E0 ;
  DEFB $1F,$0E,$FF,$2B,$FF,$FF,$E0,$C0 ;
  DEFB $1F,$0E,$FF,$DB,$FF,$FF,$E0,$C0 ;

; Sprite for graphic 32
;
; 32 by 17 pixels.
SPRITE32:
  DEFB $04,$11            ; Width in bytes, and height in rows
  DEFB $1F,$0E,$FF,$31,$FF,$FF,$E0,$C0 ; Mask and image bytes, a pair per cell,
  DEFB $0F,$07,$FF,$CE,$FF,$7F,$C0,$80 ; the bottom row first
  DEFB $0F,$07,$FF,$3F,$FF,$9F,$C0,$80 ;
  DEFB $0F,$04,$FF,$F1,$FF,$E7,$C0,$80 ;
  DEFB $07,$03,$FF,$CE,$FF,$79,$C0,$80 ;
  DEFB $0F,$07,$FF,$3B,$FF,$9E,$80,$00 ;
  DEFB $07,$00,$FF,$FB,$FF,$E7,$80,$00 ;
  DEFB $07,$03,$FF,$FB,$FF,$F8,$00,$00 ;
  DEFB $0F,$07,$FF,$F7,$FF,$FE,$80,$00 ;
  DEFB $07,$03,$FF,$F7,$FF,$FF,$C0,$80 ;
  DEFB $03,$01,$FF,$EB,$FF,$FF,$80,$00 ;
  DEFB $01,$00,$FF,$9C,$FF,$FE,$00,$00 ;
  DEFB $00,$00,$FF,$7F,$FE,$3C,$00,$00 ;
  DEFB $00,$00,$7F,$1F,$FC,$C8,$00,$00 ;
  DEFB $00,$00,$1F,$07,$F8,$E0,$00,$00 ;
  DEFB $00,$00,$07,$01,$E0,$80,$00,$00 ;
  DEFB $00,$00,$01,$00,$80,$00,$00,$00 ;

; Sprite for graphics 17, 19
;
; 32 by 17 pixels.
SPRITE17:
  DEFB $04,$11            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell,
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; the bottom row first
  DEFB $00,$00,$1A,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$7F,$1A,$80,$00,$00,$00 ;
  DEFB $01,$00,$FF,$7B,$E0,$80,$00,$00 ;
  DEFB $07,$01,$FF,$F3,$F0,$E0,$00,$00 ;
  DEFB $0F,$07,$FF,$CC,$FA,$E0,$00,$00 ;
  DEFB $07,$01,$FF,$3B,$FF,$0A,$80,$00 ;
  DEFB $03,$00,$FF,$FB,$FF,$CB,$E0,$80 ;
  DEFB $07,$03,$FF,$9B,$FF,$F3,$F0,$E0 ;
  DEFB $0F,$06,$FF,$1B,$FF,$FC,$F0,$E0 ;
  DEFB $1F,$0E,$FF,$5B,$FF,$FF,$E0,$00 ;
  DEFB $1F,$0F,$FF,$3B,$FF,$FF,$E0,$C0 ;
  DEFB $1F,$0F,$FF,$5B,$FF,$FF,$F0,$E0 ;
  DEFB $1F,$0E,$FF,$5B,$FF,$FF,$F0,$E0 ;
  DEFB $1F,$0E,$FF,$5B,$FF,$FF,$E0,$C0 ;
  DEFB $1F,$0E,$FF,$BB,$FF,$FF,$E0,$C0 ;

; Sprite for graphics 33, 35
;
; 32 by 17 pixels.
SPRITE33:
  DEFB $04,$11            ; Width in bytes, and height in rows
  DEFB $1F,$0E,$FF,$71,$FF,$FF,$E0,$C0 ; Mask and image bytes, a pair per cell,
  DEFB $0F,$07,$FF,$CE,$FF,$7F,$C0,$80 ; the bottom row first
  DEFB $0F,$07,$FF,$3F,$FF,$9F,$C0,$80 ;
  DEFB $0F,$04,$FF,$F1,$FF,$E7,$C0,$80 ;
  DEFB $07,$03,$FF,$CE,$FF,$79,$C0,$80 ;
  DEFB $0F,$07,$FF,$3B,$FF,$9E,$80,$00 ;
  DEFB $07,$00,$FF,$FB,$FF,$E7,$80,$00 ;
  DEFB $0F,$03,$FF,$FB,$FF,$F8,$00,$00 ;
  DEFB $0F,$07,$FF,$F7,$FF,$FE,$80,$00 ;
  DEFB $07,$03,$FF,$F7,$FF,$FF,$C0,$80 ;
  DEFB $03,$01,$FF,$EB,$FF,$FF,$80,$00 ;
  DEFB $01,$00,$FF,$9C,$FF,$FE,$00,$00 ;
  DEFB $00,$00,$FF,$7F,$FE,$3C,$00,$00 ;
  DEFB $00,$00,$7F,$1F,$FC,$C8,$00,$00 ;
  DEFB $00,$00,$1F,$07,$F8,$E0,$00,$00 ;
  DEFB $00,$00,$07,$01,$E0,$80,$00,$00 ;
  DEFB $00,$00,$01,$00,$80,$00,$00,$00 ;

; Sprite for graphic 18
;
; 32 by 17 pixels.
SPRITE18:
  DEFB $04,$11            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell,
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; the bottom row first
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$34,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$FF,$34,$00,$00,$00,$00 ;
  DEFB $03,$00,$FF,$F3,$C5,$00,$00,$00 ;
  DEFB $0F,$03,$FF,$CC,$FF,$C5,$C0,$00 ;
  DEFB $1F,$0F,$FF,$3B,$FF,$1D,$F0,$C0 ;
  DEFB $0F,$00,$FF,$FB,$FF,$CD,$F8,$F0 ;
  DEFB $07,$03,$FF,$FB,$FF,$F0,$F8,$70 ;
  DEFB $0F,$07,$FF,$FB,$FF,$FC,$F0,$20 ;
  DEFB $1F,$0F,$FF,$FB,$FF,$FF,$E0,$00 ;
  DEFB $1F,$08,$FF,$FB,$FF,$FF,$E0,$C0 ;
  DEFB $0F,$00,$FF,$3B,$FF,$FF,$F0,$E0 ;
  DEFB $0F,$00,$FF,$5B,$FF,$FF,$F0,$E0 ;
  DEFB $1F,$0C,$FF,$5B,$FF,$FF,$F8,$D0 ;
  DEFB $1F,$0E,$FF,$BB,$FF,$FF,$FC,$D8 ;

; Sprite for graphic 34
;
; 32 by 17 pixels.
SPRITE34:
  DEFB $04,$11            ; Width in bytes, and height in rows
  DEFB $1F,$0F,$FF,$71,$FF,$FF,$FC,$D8 ; Mask and image bytes, a pair per cell,
  DEFB $0F,$07,$FF,$CE,$FF,$7F,$F8,$B0 ; the bottom row first
  DEFB $0F,$07,$FF,$3F,$FF,$9F,$F0,$A0 ;
  DEFB $0F,$04,$FF,$F1,$FF,$E7,$E0,$80 ;
  DEFB $07,$03,$FF,$CE,$FF,$79,$C0,$80 ;
  DEFB $0F,$07,$FF,$3B,$FF,$9E,$80,$00 ;
  DEFB $07,$00,$FF,$FB,$FF,$E7,$80,$00 ;
  DEFB $07,$03,$FF,$FB,$FF,$F8,$00,$00 ;
  DEFB $0F,$07,$FF,$F7,$FF,$FE,$80,$00 ;
  DEFB $07,$03,$FF,$F7,$FF,$FF,$C0,$80 ;
  DEFB $03,$01,$FF,$EB,$FF,$FF,$80,$00 ;
  DEFB $01,$00,$FF,$9C,$FF,$FE,$00,$00 ;
  DEFB $00,$00,$FF,$7F,$FE,$3C,$00,$00 ;
  DEFB $00,$00,$7F,$1F,$FC,$C8,$00,$00 ;
  DEFB $00,$00,$1F,$07,$F8,$E0,$00,$00 ;
  DEFB $00,$00,$07,$01,$E0,$80,$00,$00 ;
  DEFB $00,$00,$01,$00,$80,$00,$00,$00 ;

; Sprite for graphic 14
;
; 8 by 48 pixels.
SPRITE14:
  DEFB $01,$30            ; Width in bytes, and height in rows
  DEFB $03,$00            ; Mask and image bytes, a pair per cell, the bottom
  DEFB $0F,$03            ; row first
  DEFB $3F,$07            ;
  DEFB $FF,$2F            ;
  DEFB $FF,$EF            ;
  DEFB $FF,$DF            ;
  DEFB $FF,$DF            ;
  DEFB $FF,$BF            ;
  DEFB $FF,$BF            ;
  DEFB $FF,$7F            ;
  DEFB $FF,$7F            ;
  DEFB $FF,$7F            ;
  DEFB $FF,$BF            ;
  DEFB $FF,$DF            ;
  DEFB $FF,$EC            ;
  DEFB $FF,$F3            ;
  DEFB $FF,$EF            ;
  DEFB $FF,$EF            ;
  DEFB $FF,$DF            ;
  DEFB $FF,$DF            ;
  DEFB $FF,$BF            ;
  DEFB $FF,$BF            ;
  DEFB $FF,$7F            ;
  DEFB $FF,$7F            ;
  DEFB $FF,$7F            ;
  DEFB $FF,$BF            ;
  DEFB $FF,$DF            ;
  DEFB $FF,$EC            ;
  DEFB $FF,$E3            ;
  DEFB $FF,$EF            ;
  DEFB $FF,$EF            ;
  DEFB $FF,$DF            ;
  DEFB $FF,$DF            ;
  DEFB $FF,$BF            ;
  DEFB $FF,$BF            ;
  DEFB $FF,$7F            ;
  DEFB $FF,$7F            ;
  DEFB $FF,$7F            ;
  DEFB $FF,$BF            ;
  DEFB $FF,$5F            ;
  DEFB $7F,$2C            ;
  DEFB $3F,$13            ;
  DEFB $7F,$2C            ;
  DEFB $7C,$28            ;
  DEFB $F8,$50            ;
  DEFB $F8,$50            ;
  DEFB $F0,$A0            ;
  DEFB $E0,$00            ;

; Sprite for graphics 55-56
;
; 24 by 20 pixels.
SPRITE55:
  DEFB $03,$14            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$00,$00,$00,$00 ; bottom row first
  DEFB $08,$00,$00,$00,$00,$00 ;
  DEFB $1C,$08,$00,$00,$00,$00 ;
  DEFB $08,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$20,$00 ;
  DEFB $00,$00,$00,$00,$70,$20 ;
  DEFB $00,$00,$00,$00,$20,$00 ;
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $10,$00,$00,$00,$00,$00 ;
  DEFB $38,$10,$00,$00,$80,$00 ;
  DEFB $10,$00,$11,$00,$C0,$80 ;
  DEFB $00,$00,$38,$10,$80,$00 ;
  DEFB $00,$00,$7C,$38,$00,$00 ;
  DEFB $00,$00,$38,$10,$00,$00 ;
  DEFB $00,$00,$10,$00,$00,$00 ;
  DEFB $01,$00,$00,$00,$00,$00 ;
  DEFB $03,$01,$80,$00,$00,$00 ;
  DEFB $01,$00,$00,$00,$00,$00 ;

; Sprite for graphics 54, 57
;
; 24 by 21 pixels.
SPRITE54:
  DEFB $03,$15            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $08,$00,$00,$00,$00,$00 ; bottom row first
  DEFB $1C,$08,$00,$00,$00,$00 ;
  DEFB $3E,$1C,$00,$00,$00,$00 ;
  DEFB $1C,$08,$00,$00,$00,$00 ;
  DEFB $08,$00,$1C,$08,$70,$20 ;
  DEFB $00,$00,$3E,$1C,$F8,$70 ;
  DEFB $01,$00,$1C,$08,$70,$20 ;
  DEFB $03,$01,$88,$00,$20,$00 ;
  DEFB $11,$00,$00,$00,$00,$00 ;
  DEFB $38,$10,$00,$00,$80,$00 ;
  DEFB $7C,$38,$11,$00,$C0,$80 ;
  DEFB $38,$10,$3B,$11,$E0,$C0 ;
  DEFB $10,$00,$7D,$38,$C0,$80 ;
  DEFB $00,$00,$FE,$7C,$80,$00 ;
  DEFB $00,$00,$7C,$38,$00,$00 ;
  DEFB $01,$00,$38,$10,$00,$00 ;
  DEFB $03,$01,$90,$00,$00,$00 ;
  DEFB $07,$03,$C0,$80,$00,$00 ;
  DEFB $03,$01,$80,$00,$00,$00 ;
  DEFB $01,$00,$00,$00,$00,$00 ;

; Sprite for graphics 53, 58
;
; 24 by 23 pixels.
SPRITE53:
  DEFB $03,$17            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$00,$00,$00,$00 ; bottom row first
  DEFB $08,$00,$00,$00,$00,$00 ;
  DEFB $1C,$08,$08,$00,$00,$00 ;
  DEFB $08,$00,$1C,$08,$00,$00 ;
  DEFB $00,$00,$3E,$1C,$20,$00 ;
  DEFB $01,$00,$7F,$3E,$70,$20 ;
  DEFB $03,$01,$BE,$1C,$20,$00 ;
  DEFB $17,$03,$DC,$88,$00,$00 ;
  DEFB $3B,$11,$88,$00,$80,$00 ;
  DEFB $7D,$38,$11,$00,$C0,$80 ;
  DEFB $FE,$7C,$3B,$11,$E0,$C0 ;
  DEFB $7C,$38,$7F,$3B,$F0,$E0 ;
  DEFB $38,$10,$FF,$7D,$E0,$C0 ;
  DEFB $11,$00,$FF,$FE,$C0,$80 ;
  DEFB $00,$00,$FE,$7C,$80,$00 ;
  DEFB $00,$00,$7C,$38,$00,$00 ;
  DEFB $01,$00,$38,$10,$00,$00 ;
  DEFB $03,$01,$90,$00,$00,$00 ;
  DEFB $01,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$80,$00 ;
  DEFB $00,$00,$01,$00,$C0,$80 ;
  DEFB $00,$00,$00,$00,$80,$00 ;

; Sprite for graphics 52, 59, 78, 108
;
; 24 by 24 pixels.
SPRITE52:
  DEFB $03,$18            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $08,$00,$00,$00,$00,$00 ; bottom row first
  DEFB $1C,$08,$08,$00,$00,$00 ;
  DEFB $3E,$1C,$1C,$01,$00,$00 ;
  DEFB $1C,$08,$3E,$1C,$20,$00 ;
  DEFB $09,$00,$7F,$3E,$70,$20 ;
  DEFB $03,$01,$FF,$7F,$F8,$70 ;
  DEFB $17,$03,$FF,$BE,$70,$20 ;
  DEFB $3F,$17,$FE,$DC,$20,$00 ;
  DEFB $7F,$3B,$DC,$88,$00,$00 ;
  DEFB $FF,$7D,$88,$00,$80,$00 ;
  DEFB $FF,$FE,$01,$00,$C0,$80 ;
  DEFB $FE,$7C,$13,$01,$E0,$C0 ;
  DEFB $7C,$38,$39,$10,$C8,$80 ;
  DEFB $38,$10,$7C,$38,$9C,$08 ;
  DEFB $10,$00,$38,$10,$08,$00 ;
  DEFB $01,$00,$10,$00,$00,$00 ;
  DEFB $03,$10,$80,$00,$00,$00 ;
  DEFB $07,$03,$C0,$80,$00,$00 ;
  DEFB $03,$10,$80,$00,$80,$00 ;
  DEFB $01,$00,$09,$00,$C0,$80 ;
  DEFB $00,$00,$1F,$09,$E0,$C0 ;
  DEFB $00,$00,$09,$00,$C0,$80 ;
  DEFB $00,$00,$00,$00,$80,$00 ;

; Sprite for graphics 49, 51, 60, 62, 65, 77, 79, 109, 111
;
; 24 by 24 pixels.
SPRITE49:
  DEFB $03,$18            ; Width in bytes, and height in rows
  DEFB $08,$00,$70,$20,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $1C,$08,$F8,$70,$08,$00 ; bottom row first
  DEFB $3F,$1C,$FC,$F8,$3C,$08 ;
  DEFB $7F,$36,$F8,$70,$78,$20 ;
  DEFB $3E,$1C,$78,$20,$F8,$70 ;
  DEFB $1C,$08,$3D,$08,$FC,$F8 ;
  DEFB $08,$00,$3F,$1D,$FE,$FC ;
  DEFB $01,$00,$1D,$08,$FC,$F8 ;
  DEFB $13,$01,$C8,$00,$F8,$70 ;
  DEFB $39,$10,$E0,$40,$70,$40 ;
  DEFB $7C,$38,$50,$00,$20,$00 ;
  DEFB $FE,$7C,$38,$10,$80,$00 ;
  DEFB $7F,$3A,$7D,$38,$C8,$80 ;
  DEFB $3A,$10,$FE,$7C,$9C,$08 ;
  DEFB $11,$00,$FF,$FE,$3E,$1C ;
  DEFB $01,$00,$FF,$7C,$1C,$08 ;
  DEFB $03,$01,$FF,$39,$88,$00 ;
  DEFB $07,$03,$F9,$90,$00,$00 ;
  DEFB $0F,$07,$F0,$C0,$80,$00 ;
  DEFB $07,$03,$C1,$80,$C0,$80 ;
  DEFB $03,$01,$8B,$01,$E0,$C0 ;
  DEFB $01,$00,$1F,$0B,$F0,$E0 ;
  DEFB $00,$00,$0B,$01,$E0,$C0 ;
  DEFB $00,$00,$01,$00,$C0,$80 ;

; Sprite for graphics 48, 50, 61, 63-64, 76, 110
;
; 24 by 24 pixels.
SPRITE48:
  DEFB $03,$18            ; Width in bytes, and height in rows
  DEFB $1C,$08,$00,$00,$08,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $3E,$1C,$20,$00,$1C,$08 ; bottom row first
  DEFB $7F,$3E,$78,$20,$3E,$1C ;
  DEFB $FF,$7F,$BC,$08,$1C,$08 ;
  DEFB $7F,$3E,$3E,$1C,$28,$00 ;
  DEFB $3F,$1C,$7F,$3E,$70,$20 ;
  DEFB $1F,$09,$FF,$7F,$F8,$70 ;
  DEFB $0F,$03,$FF,$BE,$70,$20 ;
  DEFB $0F,$07,$FE,$DC,$A0,$00 ;
  DEFB $07,$03,$DD,$88,$C0,$80 ;
  DEFB $13,$01,$8B,$01,$E0,$C0 ;
  DEFB $3B,$10,$07,$03,$F8,$E0 ;
  DEFB $17,$02,$13,$01,$FC,$C8 ;
  DEFB $0F,$07,$B9,$10,$FE,$9C ;
  DEFB $07,$02,$7D,$38,$FF,$3E ;
  DEFB $03,$01,$BB,$11,$BE,$1C ;
  DEFB $07,$03,$D7,$83,$DC,$11 ;
  DEFB $0F,$07,$E3,$C1,$88,$00 ;
  DEFB $1F,$0F,$F9,$E0,$00,$00 ;
  DEFB $0F,$07,$FC,$C8,$80,$00 ;
  DEFB $07,$03,$FF,$9C,$C0,$80 ;
  DEFB $03,$01,$FF,$3F,$E0,$C0 ;
  DEFB $01,$00,$BF,$1C,$C0,$80 ;
  DEFB $00,$00,$1C,$08,$80,$00 ;

; Sprite for graphics 112-115
;
; 32 by 25 pixels.
SPRITE112:
  DEFB $04,$19            ; Width in bytes, and height in rows
  DEFB $00,$00,$1F,$00,$F8,$00,$00,$00 ; Mask and image bytes, a pair per cell,
  DEFB $00,$00,$FF,$1F,$FF,$F8,$00,$00 ; the bottom row first
  DEFB $03,$00,$FF,$FF,$FF,$FF,$C0,$00 ;
  DEFB $07,$03,$FF,$E0,$FF,$07,$E0,$C0 ;
  DEFB $0F,$07,$FF,$1F,$FF,$F8,$F0,$E0 ;
  DEFB $1F,$0C,$FF,$FF,$FF,$FF,$F8,$30 ;
  DEFB $3F,$18,$FF,$7F,$FF,$FF,$FC,$D8 ;
  DEFB $3F,$10,$FF,$7F,$FF,$FF,$FC,$E8 ;
  DEFB $3F,$08,$FF,$7F,$FF,$FF,$FC,$F0 ;
  DEFB $3F,$1C,$FF,$3F,$FF,$FF,$FC,$F8 ;
  DEFB $3F,$1E,$FF,$3C,$FF,$3F,$FC,$F8 ;
  DEFB $3F,$1E,$FF,$23,$FF,$C7,$FC,$F8 ;
  DEFB $1F,$0F,$FF,$5F,$FF,$F9,$F8,$F0 ;
  DEFB $0F,$07,$FF,$9F,$FF,$FE,$F0,$E0 ;
  DEFB $07,$02,$FF,$9C,$FF,$3F,$E0,$40 ;
  DEFB $03,$00,$FF,$83,$FF,$C7,$C0,$00 ;
  DEFB $03,$01,$FF,$9E,$FF,$79,$C0,$80 ;
  DEFB $03,$01,$FF,$7C,$FF,$3E,$C0,$80 ;
  DEFB $03,$01,$FF,$7F,$FF,$FE,$C0,$80 ;
  DEFB $03,$00,$FF,$E7,$FF,$E7,$C0,$00 ;
  DEFB $01,$00,$FF,$E3,$FF,$C7,$80,$00 ;
  DEFB $00,$00,$FF,$73,$FF,$CE,$00,$00 ;
  DEFB $00,$00,$7F,$1F,$FE,$F8,$00,$00 ;
  DEFB $00,$00,$1F,$03,$F8,$C0,$00,$00 ;
  DEFB $00,$00,$03,$00,$C0,$00,$00,$00 ;

; Sprite for graphics 96, 100, 104
;
; 24 by 24 pixels.
SPRITE96:
  DEFB $03,$18            ; Width in bytes, and height in rows
  DEFB $00,$00,$3C,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $03,$00,$7E,$3C,$C0,$00 ; bottom row first
  DEFB $07,$03,$FF,$7E,$E0,$C0 ;
  DEFB $0F,$07,$FF,$42,$F0,$E0 ;
  DEFB $0F,$06,$FF,$3C,$F0,$60 ;
  DEFB $0F,$01,$FF,$FF,$F0,$80 ;
  DEFB $0F,$03,$FF,$7F,$F0,$E0 ;
  DEFB $1F,$0C,$FF,$7F,$F8,$F0 ;
  DEFB $3F,$1C,$FF,$7F,$FC,$F8 ;
  DEFB $3F,$1C,$FF,$7F,$FC,$F8 ;
  DEFB $3F,$1C,$FF,$7F,$FC,$F8 ;
  DEFB $3F,$1C,$FF,$43,$FC,$F8 ;
  DEFB $3F,$1D,$FF,$BC,$FC,$78 ;
  DEFB $3F,$1A,$FF,$7F,$FC,$98 ;
  DEFB $3F,$14,$FF,$3F,$FC,$E8 ;
  DEFB $3F,$0F,$FF,$1F,$FC,$F0 ;
  DEFB $3F,$1F,$FF,$8F,$FC,$F8 ;
  DEFB $3F,$1F,$FF,$EF,$FC,$F8 ;
  DEFB $3F,$1F,$FF,$FF,$FC,$F8 ;
  DEFB $1F,$0F,$FF,$FF,$F8,$F0 ;
  DEFB $0F,$07,$FF,$FF,$F0,$E0 ;
  DEFB $07,$01,$FF,$FF,$E0,$80 ;
  DEFB $01,$00,$FF,$3C,$80,$00 ;
  DEFB $00,$00,$3C,$00,$00,$00 ;

; Sprite for graphics 97, 101, 105
;
; 24 by 23 pixels.
SPRITE97:
  DEFB $03,$17            ; Width in bytes, and height in rows
  DEFB $00,$00,$18,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$3C,$18,$00,$00 ; bottom row first
  DEFB $01,$00,$FF,$3C,$80,$00 ;
  DEFB $03,$01,$FF,$BD,$C0,$80 ;
  DEFB $07,$03,$FF,$A5,$E0,$C0 ;
  DEFB $07,$03,$FF,$99,$E0,$C0 ;
  DEFB $07,$02,$FF,$6E,$E0,$40 ;
  DEFB $07,$01,$FF,$EF,$E0,$80 ;
  DEFB $1F,$07,$FF,$EF,$F8,$E0 ;
  DEFB $3F,$1F,$FF,$EF,$FC,$F8 ;
  DEFB $3F,$1F,$FF,$EF,$FC,$F8 ;
  DEFB $3F,$1F,$FF,$EF,$FC,$F8 ;
  DEFB $3F,$1F,$FF,$EF,$FC,$F8 ;
  DEFB $3F,$1F,$FF,$99,$FC,$F8 ;
  DEFB $3F,$1E,$FF,$7E,$FC,$78 ;
  DEFB $3F,$19,$FF,$FF,$FC,$98 ;
  DEFB $3F,$17,$FF,$FF,$FC,$E8 ;
  DEFB $3F,$1F,$FF,$FF,$FC,$F8 ;
  DEFB $1F,$07,$FF,$FF,$F8,$E0 ;
  DEFB $07,$01,$FF,$FF,$E0,$80 ;
  DEFB $01,$00,$FF,$7E,$80,$00 ;
  DEFB $00,$00,$7E,$18,$00,$00 ;
  DEFB $00,$00,$18,$00,$00,$00 ;

; Sprite for graphics 98, 102, 106
;
; 24 by 19 pixels.
SPRITE98:
  DEFB $03,$13            ; Width in bytes, and height in rows
  DEFB $00,$00,$18,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$3C,$18,$00,$00 ; bottom row first
  DEFB $01,$00,$FF,$3C,$80,$00 ;
  DEFB $03,$01,$FF,$BD,$C0,$80 ;
  DEFB $07,$03,$FF,$A5,$E0,$C0 ;
  DEFB $07,$03,$FF,$99,$E0,$C0 ;
  DEFB $07,$02,$FF,$6E,$E0,$40 ;
  DEFB $0F,$01,$FF,$EF,$F0,$80 ;
  DEFB $3F,$07,$FF,$EF,$FC,$E0 ;
  DEFB $3F,$1F,$FF,$EF,$FC,$F8 ;
  DEFB $1F,$0F,$FF,$EF,$F8,$F0 ;
  DEFB $0F,$07,$FF,$EF,$F0,$E0 ;
  DEFB $07,$03,$FF,$EF,$E0,$C0 ;
  DEFB $03,$01,$FF,$EF,$C0,$80 ;
  DEFB $01,$00,$FF,$EF,$80,$00 ;
  DEFB $00,$00,$FF,$6E,$00,$00 ;
  DEFB $00,$00,$7E,$2C,$00,$00 ;
  DEFB $00,$00,$3C,$18,$00,$00 ;
  DEFB $00,$00,$18,$00,$00,$00 ;

; Sprite for graphics 99, 103, 107
;
; 24 by 21 pixels.
SPRITE99:
  DEFB $03,$15            ; Width in bytes, and height in rows
  DEFB $00,$00,$3C,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $03,$00,$7E,$3C,$C0,$00 ; bottom row first
  DEFB $07,$03,$FF,$7E,$E0,$C0 ;
  DEFB $0F,$07,$FF,$42,$F0,$E0 ;
  DEFB $0F,$06,$FF,$3C,$F0,$60 ;
  DEFB $0F,$01,$FF,$FF,$F0,$80 ;
  DEFB $0F,$07,$FF,$FF,$F0,$E0 ;
  DEFB $1F,$0F,$FF,$FF,$F8,$F0 ;
  DEFB $3F,$1F,$FF,$FF,$FC,$F8 ;
  DEFB $3F,$1F,$FF,$3F,$FC,$F8 ;
  DEFB $3F,$1E,$FF,$3F,$FC,$F8 ;
  DEFB $3F,$1C,$FF,$3F,$FC,$F8 ;
  DEFB $1F,$0C,$FF,$3F,$F8,$F0 ;
  DEFB $1F,$0E,$FF,$1F,$F8,$F0 ;
  DEFB $0F,$06,$FF,$1F,$F0,$E0 ;
  DEFB $0F,$07,$FF,$0F,$F0,$E0 ;
  DEFB $07,$03,$FF,$8F,$E0,$C0 ;
  DEFB $03,$01,$FF,$CF,$C0,$80 ;
  DEFB $01,$00,$FF,$7E,$80,$00 ;
  DEFB $00,$00,$7E,$18,$00,$00 ;
  DEFB $00,$00,$18,$00,$00,$00 ;

; Start the game
;
; Used by the routine at ENTRY.
;
; Entered from ENTRY when the game is first run. Clears the variables and all
; 56 object records, from SEED up to BELOW_BLOCK, keeping only the ROM's frame
; counter, which becomes the seed (SEED): a machine switched on for a different
; time gets a different game. The frame counter has to be read first because it
; lies inside the object records (FRAMES, in record 7), which the clear wipes.
;
; As Knight Lore's cold start, but for the call to R_CHECK_LEFTOVER, which does
; nothing that lasts.
START:
  LD HL,SEED              ; from SEED up to BELOW_BLOCK: the variables and the
  LD BC,$0788             ; 56 object records
  LD A,(FRAMES)           ; FRAMES, the ROM's frame counter, kept on the stack
  PUSH AF                 ;
  CALL CLR_MEM            ; clear them, and the counter becomes the seed
  POP AF                  ;
  LD (SEED),A             ;
  CALL R_CHECK_LEFTOVER   ; a leftover that returns at once
  JR MAIN_NEW_GAME        ; and set up a game

; Back to the menu after a game, set up a game, and run it
;
; Used by the routines at OILED_ROBOT and SCENE_TOOL.
;
; Reached when the scene after a game ends (SCENE_TOOL, OILED_ROBOT). Clears
; from WIPE_COUNT to the end of the object records, so the seed, the turn
; counter, the control method and the random number carry over, and falls into
; the setting up of a game at MAIN_NEW_GAME, where START joins.
;
; A new game builds the drawing tables, has five lives, 6000 light years, and
; no room played yet; stirs the last game's turn count into the seed; clears
; the screen and shows the menu (MENU); plays the start tune; puts the robot in
; one of four start rooms (NEW_GAME_START); deals the valves and extra lives to
; their places (INIT_SPECIAL_OBJECTS); and gives every room back its colour
; (RESET_ROOM_COLOURS), undoing the white of the chambers activated last game.
;
; Then three loops, one inside the other, each with its own entry:
; MAIN_NEW_LIFE starts a life (NEW_LIFE) and falls into MAIN_NEW_ROOM, which
; builds the room he is in (ENTER_ROOM) -- leaving a room comes back here from
; EXIT_LOW_U -- and falls into MAIN_NEXT_TURN, the start of a turn.
; MAIN_NEXT_OBJECT runs one record's update routine: the stack is reset to
; MIRROR_TABLE for every object, the address of OBJECT_DONE is pushed for the
; routine's RET to go to, and the record's last drawn size and place are kept
; (+18 to +1B into +1C to +1F) so that its old picture can be wiped.
; MAIN_DISPATCH jumps through UPDATES by the graphic; JUMP_THROUGH_TABLE jumps
; through any table of words by the index in L and the table in BC, and
; CALC_PLYR_DUV and SORT_AND_DRAW use it too.
;
; Knight Lore's main and its object walk, with the clock where the sun and moon
; were and nothing for the cauldron; the stack is Alien 8's own, above the
; screen buffer, where Knight Lore's is below its variables.
AFTER_GAME:
  LD HL,WIPE_COUNT        ; from WIPE_COUNT up to BELOW_BLOCK
  LD BC,$0780             ;
  CALL CLR_MEM            ;
; This entry point is used by the routine at START.
MAIN_NEW_GAME:
  CALL BUILD_LOOKUP_TBLS  ; the tables at MIRROR_TABLE
  XOR A                   ; no room played yet, so the first room built has
  LD (PLAYED),A           ; nothing to write back
  LD ($CA29),A            ; clear the start legs' +C: not jumping, not standing
  LD A,$05                ; five lives: the first life takes one
  LD (LIVES),A            ;
  LD HL,$0060             ; 6000 light years: the first digit 6, the rest 0,
  LD (CLOCK),HL           ; none rolling
  LD HL,$0000             ;
  LD (CLOCK_LOW),HL       ;
  LD HL,SEED              ; stir the turn counter into the seed; it is zero on
  LD A,(TURNS)            ; the first game after loading
  ADD A,(HL)              ;
  LD (HL),A               ;
  CALL CLEAR_SCRN         ; clear the screen, border black
  CALL MENU               ; the menu, until 0 is pressed
  LD DE,TUNE_START        ; the tune that plays as a game starts
  CALL PLAY_TUNE          ;
  CALL NEW_GAME_START     ; the start records and the start room
  CALL INIT_SPECIAL_OBJECTS ; deal the valves and the extra lives
  CALL RESET_ROOM_COLOURS ; every room's colour from its record
; This entry point is used by the routine at OBJECT_DONE.
MAIN_NEW_LIFE:
  CALL NEW_LIFE           ; a life: the robot from the start records, a life
                          ; fewer
; This entry point is used by the routine at EXIT_LOW_U.
MAIN_NEW_ROOM:
  CALL ENTER_ROOM         ; build the room he is in
; This entry point is used by the routines at OBJECT_DONE and GAME_ENDED.
MAIN_NEXT_TURN:
  LD IX,OBJECTS           ; the first record
; This entry point is used by the routine at OBJECT_DONE.
MAIN_NEXT_OBJECT:
  LD SP,MIRROR_TABLE      ; a fresh stack for every object
  LD HL,OBJECT_DONE       ; its update routine returns to OBJECT_DONE
  PUSH HL                 ;
  LD A,(IX+$18)           ; keep last turn's size and place on the screen, to
  LD (IX+$1C),A           ; wipe
  LD A,(IX+$19)           ;
  LD (IX+$1D),A           ;
  LD A,(IX+$1A)           ;
  LD (IX+$1E),A           ;
  LD A,(IX+$1B)           ;
  LD (IX+$1F),A           ;
; This entry point is used by the routine at PLAYER_APPEARED.
MAIN_DISPATCH:
  LD L,(IX+$00)           ; the graphic indexes UPDATES
  LD BC,UPDATES           ;
; This entry point is used by the routines at CALC_PLYR_DUV and SORT_AND_DRAW.
JUMP_THROUGH_TABLE:
  LD H,$00                ; HL = BC + 2 * L; jump to the word there
  ADD HL,HL               ;
  ADD HL,BC               ;
  LD A,(HL)               ;
  INC HL                  ;
  LD H,(HL)               ;
  LD L,A                  ;
  JP (HL)                 ;

; After each object's update routine; the end of a turn
;
; Every update routine returns here: the main loop pushes this address before
; it jumps to one. The refresh register is stirred into the random number, so
; the sequence depends on how much work the turn did, and the loop goes on to
; the next record -- or, after the last, ends the turn.
;
; The end of a turn, MAIN_END_OF_TURN: count the turn, stir the random number
; again, note that a turn has been played, list and draw what changed, and then
; pad the turn out: the drawing counts its work in DRAW_WORK, and the loop
; waits six units less that, a unit being 768 turns of a 26 T-state loop, about
; 20,000 T-states. A room where little moves runs at the speed of one where six
; things are drawn; a busier room runs slower. Then the clock, which can end
; the game (RUN_CLOCK).
;
; On the first turn in a room the panel is drawn and coloured (DISPLAY_PANEL,
; COLOUR_PANEL) and the whole buffer copied to the screen. Then the pause key
; (HANDLE_PAUSE), and a new life if both of the robot's records have emptied --
; they do when his dying sparkle ends -- or the next turn.
;
; While the scene after a game runs (GAME_OVER) there is no waiting and no
; clock.
OBJECT_DONE:
  LD A,R                  ; R changes with every instruction fetched
  LD C,A                  ;
  LD A,(RANDOM)           ;
  ADD A,C                 ;
  LD (RANDOM),A           ;
  LD BC,$0020             ; the next record, until BELOW_BLOCK, the end of the
  ADD IX,BC               ; records
  PUSH IX                 ;
  POP HL                  ;
  LD BC,BELOW_BLOCK       ;
  AND A                   ;
  SBC HL,BC               ;
  JR NC,MAIN_END_OF_TURN  ; not there yet: the next object
  JR MAIN_NEXT_OBJECT     ;
MAIN_END_OF_TURN:
  LD HL,(TURNS)           ; count the turn
  INC HL                  ;
  LD (TURNS),HL           ;
  LD A,(RANDOM)           ; stir in the turn counter and whatever byte it
  ADD A,(HL)              ; addresses
  ADD A,L                 ;
  ADD A,H                 ;
  LD (RANDOM),A           ;
  LD HL,PLAYED            ; a turn has been played: the next room built writes
  SET 0,(HL)              ; back the valves
  CALL LIST_DRAWN         ; list the records flagged to be drawn
  CALL RENDER_DYNAMIC_OBJECTS ; wipe, draw in depth order and copy the changes
                              ; to the screen
  LD A,(GAME_OVER)        ; the scene after a game: no delay, no clock
  AND A                   ;
  JP NZ,OBJECT_DONE_5     ;
  LD A,(DRAW_WORK)        ; six units, less the turn's drawing; none if that is
  NEG                     ; six or more
  ADD A,$06               ;
  LD B,A                  ;
  JP M,OBJECT_DONE_2      ;
  JR Z,OBJECT_DONE_2      ;
OBJECT_DONE_0:
  LD HL,$0300             ; about 20,000 T-states a unit
OBJECT_DONE_1:
  DEC HL                  ; 26 T-states a turn
  LD A,L                  ;
  OR H                    ;
  JR NZ,OBJECT_DONE_1     ;
  DJNZ OBJECT_DONE_0      ;
OBJECT_DONE_2:
  CALL RUN_CLOCK          ; the light years: may end the game
  LD A,(NEW_ROOM)         ; not the first turn in a room
  AND A                   ;
  JR Z,OBJECT_DONE_4      ;
  CALL DISPLAY_PANEL      ; draw the panel, and colour the screen and the panel
  CALL COLOUR_PANEL       ;
OBJECT_DONE_3:
  XOR A                   ; once only; the whole buffer to the screen
  LD (NEW_ROOM),A         ;
  CALL SHOW_BUFFER        ;
  CALL CLEAR_WIPE_FLAGS   ; nothing drawn so far needs wiping
OBJECT_DONE_4:
  CALL HANDLE_PAUSE       ; pause, if SPACE or CAPS SHIFT alone is pressed
  LD IX,OBJECTS           ; his legs and top both empty: start a life
  LD A,(IX+$00)           ;
  OR (IX+$20)             ;
  JP Z,MAIN_NEW_LIFE      ;
  JP MAIN_NEXT_TURN       ; the next turn
OBJECT_DONE_5:
  LD A,(NEW_ROOM)         ; in the scene: only the whole-screen copy of its
  AND A                   ; first turn
  JR Z,OBJECT_DONE_4      ;
  JR OBJECT_DONE_3        ;

; Colour the screen and the panel for the room
;
; Used by the routines at OBJECT_DONE and LOOSE_VALVE.
;
; On the first turn in a room (OBJECT_DONE) and when a chamber is activated
; (LOOSE_VALVE). The whole attribute file gets the room's ink, bright on black,
; and then the panel its colours: the lives bright white, the light-years box
; red round white digits (COLOUR_CLOCK_BOX), the carried things (SHOW_CARRIED,
; part way in), the LIGHT YEARS label and the chamber icon in a colour chosen
; from the room's ink, and the count of chambers and of lives.
;
; The label's colour is 2 plus 7 less the room's ink, bright on black: never
; the room's own colour for the inks the rooms use (3 to 6 on the tape, and 7
; once a chamber is activated), and red in an activated chamber. It is written
; into the first byte of the label's text (LIGHT_YEARS_TEXT), where the printer
; takes a line's colour from, and read back from there for the icon.
COLOUR_PANEL:
  LD A,(ROOM_INK)         ; the whole screen in the room's ink, bright on black
  OR $40                  ;
  CALL FILL_ATTR          ;
  LD A,$47                ; the lives, bright white
  LD DE,$5ACE             ;
  LD B,$02                ;
  CALL FILL_DE            ;
  LD DE,$5AEE             ;
  LD B,$04                ;
  CALL FILL_DE            ;
  CALL COLOUR_CLOCK_BOX   ; the light-years box
  CALL SHOW_CARRIED_NOW   ; the carried things
  LD A,(ROOM_INK)         ; 2 + (7 - ink), bright: the label's colour, into its
  CPL                     ; text
  AND $07                 ;
  ADD A,$42               ;
  LD (LIGHT_YEARS_TEXT),A ;
  LD DE,LIGHT_YEARS_TEXT  ; print LIGHT YEARS at the foot of the screen, right
  LD HL,$07A0             ; of centre
  CALL PRINT_TEXT         ;
  CALL PRINT_CHAMBERS     ; the count of chambers
  LD HL,$5A84             ; its two digits bright white
  LD (HL),$47             ;
  INC HL                  ;
  LD (HL),$47             ;
  LD HL,$5A41             ; the chamber icon, three by three cells at the left,
  LD BC,$0303             ; in the label's colour
  LD A,(LIGHT_YEARS_TEXT) ;
  CALL FILL_BOX           ;
  JP PRINT_LIVES          ; and the lives

; The panel's label
;
; The words LIGHT YEARS for the panel, in the printer's form (PRINT_TEXT): a
; colour byte, then the text, the last character with bit 7 set
; (LIGHT_YEARS_TEXT_END). The colour byte is written by COLOUR_PANEL before
; every printing; on the tape it is 'E'.
LIGHT_YEARS_TEXT:
  DEFM $45,"LIGHT YEAR"   ; The colour, then LIGHT YEAR

; The end of the panel's label
;
; The last letter of LIGHT_YEARS_TEXT, S with bit 7 set to end the string.
LIGHT_YEARS_TEXT_END:
  DEFB $D3                ; S, the last

; Print the count of chambers activated
;
; Used by the routines at COLOUR_PANEL and LOOSE_VALVE.
;
; The two BCD digits of CHAMBERS into the buffer at the panel's left, beside
; the chamber icon, with the digits of the font (PRINT_LIVES sets the base so
; that digit n is character n).
PRINT_CHAMBERS:
  LD DE,CHAMBERS          ; one byte, two digits
  LD HL,$D5E4             ;
  LD B,$01                ;
  JP PRINT_BCD_NUMBER     ;

; Colour the light-years box
;
; Used by the routine at COLOUR_PANEL.
;
; Three rows of six attribute cells at the right of the panel, from
; CLOCK_BOX_COLOURS: a bright red frame round the four digits in bright white.
COLOUR_CLOCK_BOX:
  LD HL,$5A99             ; row 20, column 25; three rows of six
  LD DE,CLOCK_BOX_COLOURS ;
  LD BC,$0603             ;
COLOUR_CLOCK_BOX_0:
  PUSH BC                 ; a row
  PUSH HL                 ;
COLOUR_CLOCK_BOX_1:
  LD A,(DE)               ;
  INC DE                  ;
  LD (HL),A               ;
  INC HL                  ;
  DJNZ COLOUR_CLOCK_BOX_1 ;
  POP HL                  ; the next row down
  LD A,$20                ;
  CALL ADD_HL_A           ;
  POP BC                   ; three rows
  DEC C                    ;
  JR NZ,COLOUR_CLOCK_BOX_0 ;
  RET                      ;

; The light-years box's colours
;
; Read by COLOUR_CLOCK_BOX. They happen to be the codes of the letters B and G:
; $42 bright red, $47 bright white.
CLOCK_BOX_COLOURS:
  DEFB $42,$42,$42,$42,$42,$42 ; Three rows of six: red round the edge, white
  DEFB $42,$47,$47,$47,$47,$42 ; behind the digits
  DEFB $42,$42,$42,$42,$42,$42 ;

; Clear every object's wipe flag
;
; Used by the routine at OBJECT_DONE.
;
; Bit 5 of +7 marks an object whose old picture must be wiped. After the whole
; screen has just been copied out (OBJECT_DONE) there is nothing to wipe.
CLEAR_WIPE_FLAGS:
  LD B,$38                ; all 56 records, from the legs' flags
  LD DE,$0020             ;
  LD HL,PLAYER_FLAGS      ;
CLEAR_WIPE_FLAGS_0:
  RES 5,(HL)              ;
  ADD HL,DE               ;
  DJNZ CLEAR_WIPE_FLAGS_0 ;
  RET                     ;

; Update routines, by graphic
;
; A word per graphic number, 0 to 130: the routine the main loop
; (MAIN_DISPATCH, in AFTER_GAME) jumps to for a record holding that graphic.
; Graphic 131 has a sprite (GRAPHICS) but no entry here.
;
; This table is the only way in to the update routines, so they have no "Used
; by" line; each one's title names the graphics that reach it. A routine
; changes what an object does, as well as how it looks, by changing its
; graphic: a valve seated on its socket goes from 96-99 to 100-103, and a dying
; thing runs through the sparkle's graphics.
UPDATES:
  DEFW NO_UPDATE          ; Graphic 0
  DEFW NO_UPDATE          ; Graphic 1
  DEFW FIRST_PILLAR       ; Graphic 2
  DEFW SECOND_PILLAR      ; Graphic 3
  DEFW NO_UPDATE          ; Graphic 4
  DEFW NO_UPDATE          ; Graphic 5
  DEFW NO_UPDATE          ; Graphic 6
  DEFW NO_UPDATE          ; Graphic 7
  DEFW NO_UPDATE          ; Graphic 8
  DEFW NO_UPDATE          ; Graphic 9
  DEFW NO_UPDATE          ; Graphic 10
  DEFW LOWER_HALF         ; Graphic 11
  DEFW EXTRA_LIFE         ; Graphic 12
  DEFW DRAW_AT_L12_D7     ; Graphic 13
  DEFW DRAW_AT_L4_D3      ; Graphic 14
  DEFW DRAW_AT_L8_D5      ; Graphic 15
  DEFW PLAYER_LEGS        ; Graphic 16
  DEFW PLAYER_LEGS        ; Graphic 17
  DEFW PLAYER_LEGS        ; Graphic 18
  DEFW PLAYER_LEGS        ; Graphic 19
  DEFW PLAYER_LEGS        ; Graphic 20
  DEFW PLAYER_LEGS        ; Graphic 21
  DEFW PLAYER_LEGS        ; Graphic 22
  DEFW PLAYER_LEGS        ; Graphic 23
  DEFW TURNING_LEGS       ; Graphic 24
  DEFW TURNING_LEGS       ; Graphic 25
  DEFW TURNING_LEGS       ; Graphic 26
  DEFW TURNING_LEGS       ; Graphic 27
  DEFW PUSHABLE           ; Graphic 28
  DEFW PUSHABLE_INVERTED  ; Graphic 29
  DEFW DRAW_AT_L16_D9     ; Graphic 30
  DEFW BOBBER             ; Graphic 31
  DEFW TOP_FOLLOWS_LEGS   ; Graphic 32
  DEFW TOP_FOLLOWS_LEGS   ; Graphic 33
  DEFW TOP_FOLLOWS_LEGS   ; Graphic 34
  DEFW TOP_FOLLOWS_LEGS   ; Graphic 35
  DEFW TOP_FOLLOWS_LEGS   ; Graphic 36
  DEFW TOP_FOLLOWS_LEGS   ; Graphic 37
  DEFW TOP_FOLLOWS_LEGS   ; Graphic 38
  DEFW TOP_FOLLOWS_LEGS   ; Graphic 39
  DEFW TOP_FOLLOWS_LEGS   ; Graphic 40
  DEFW TOP_FOLLOWS_LEGS   ; Graphic 41
  DEFW TOP_FOLLOWS_LEGS   ; Graphic 42
  DEFW TOP_FOLLOWS_LEGS   ; Graphic 43
  DEFW DROPPING_BLOCK     ; Graphic 44
  DEFW COLLAPSING_BLOCK   ; Graphic 45
  DEFW SPIKES             ; Graphic 46
  DEFW LIFT               ; Graphic 47
  DEFW SPARKLE_STEP       ; Graphic 48
  DEFW SPARKLE_STEP       ; Graphic 49
  DEFW SPARKLE_STEP       ; Graphic 50
  DEFW SPARKLE_STEP       ; Graphic 51
  DEFW SPARKLE_STEP       ; Graphic 52
  DEFW SPARKLE_STEP       ; Graphic 53
  DEFW SPARKLE_STEP       ; Graphic 54
  DEFW SPARKLE_END        ; Graphic 55
  DEFW PLAYER_APPEARING   ; Graphic 56
  DEFW PLAYER_APPEARING   ; Graphic 57
  DEFW PLAYER_APPEARING   ; Graphic 58
  DEFW PLAYER_APPEARING   ; Graphic 59
  DEFW PLAYER_APPEARING   ; Graphic 60
  DEFW PLAYER_APPEARING   ; Graphic 61
  DEFW PLAYER_APPEARING   ; Graphic 62
  DEFW PLAYER_APPEARED    ; Graphic 63
  DEFW SPARKLE_STEP       ; Graphic 64
  DEFW SPARKLE_END_PLACE  ; Graphic 65
  DEFW SHUTTLE_U          ; Graphic 66
  DEFW SHUTTLE_V          ; Graphic 67
  DEFW CONVEYOR_PLUS_V    ; Graphic 68
  DEFW CONVEYOR_PLUS_U    ; Graphic 69
  DEFW CONVEYOR_MINUS_V   ; Graphic 70
  DEFW CONVEYOR_MINUS_U   ; Graphic 71
  DEFW STILL_DEADLY       ; Graphic 72
  DEFW CEILING_DROP       ; Graphic 73
  DEFW CRYONAUT           ; Graphic 74
  DEFW STILL_DEADLY       ; Graphic 75
  DEFW SPARK_CHASER       ; Graphic 76
  DEFW SPARK_CHASER       ; Graphic 77
  DEFW SPARK_CHASER       ; Graphic 78
  DEFW SPARK_CHASER       ; Graphic 79
  DEFW SCENE_SPARKS       ; Graphic 80
  DEFW SCENE_TOOL         ; Graphic 81
  DEFW SCENE_TOOL         ; Graphic 82
  DEFW SCENE_TOOL         ; Graphic 83
  DEFW NO_UPDATE          ; Graphic 84
  DEFW COLOUR_SCENE_OBJECT ; Graphic 85
  DEFW PACER              ; Graphic 86
  DEFW PACER              ; Graphic 87
  DEFW COLOUR_SCENE_OBJECT ; Graphic 88
  DEFW COLOUR_SCENE_OBJECT ; Graphic 89
  DEFW COLOUR_SCENE_OBJECT ; Graphic 90
  DEFW COLOUR_SCENE_OBJECT ; Graphic 91
  DEFW OILED_ROBOT        ; Graphic 92
  DEFW SCENE_ROBOT_TOP    ; Graphic 93
  DEFW WANDERER           ; Graphic 94
  DEFW WANDERER           ; Graphic 95
  DEFW LOOSE_VALVE        ; Graphic 96
  DEFW LOOSE_VALVE        ; Graphic 97
  DEFW LOOSE_VALVE        ; Graphic 98
  DEFW LOOSE_VALVE        ; Graphic 99
  DEFW SEATED_VALVE       ; Graphic 100
  DEFW SEATED_VALVE       ; Graphic 101
  DEFW SEATED_VALVE       ; Graphic 102
  DEFW SEATED_VALVE       ; Graphic 103
  DEFW WANTED_VALVE       ; Graphic 104
  DEFW WANTED_VALVE       ; Graphic 105
  DEFW WANTED_VALVE       ; Graphic 106
  DEFW WANTED_VALVE       ; Graphic 107
  DEFW SOCKET_SPARKLE     ; Graphic 108
  DEFW SOCKET_SPARKLE     ; Graphic 109
  DEFW SOCKET_SPARKLE     ; Graphic 110
  DEFW SOCKET_SPARKLE     ; Graphic 111
  DEFW SOCKET             ; Graphic 112
  DEFW SOCKET             ; Graphic 113
  DEFW SOCKET             ; Graphic 114
  DEFW SOCKET             ; Graphic 115
  DEFW CLOCKWORK_MOUSE    ; Graphic 116
  DEFW CLOCKWORK_MOUSE    ; Graphic 117
  DEFW CLOCKWORK_MOUSE    ; Graphic 118
  DEFW CLOCKWORK_MOUSE    ; Graphic 119
  DEFW SLOW_CHASER        ; Graphic 120
  DEFW SLOW_CHASER        ; Graphic 121
  DEFW REMOTE_BUTTON      ; Graphic 122
  DEFW REMOTE_BUTTON      ; Graphic 123
  DEFW REMOTE_ROBOT       ; Graphic 124
  DEFW REMOTE_ROBOT       ; Graphic 125
  DEFW REMOTE_ROBOT       ; Graphic 126
  DEFW REMOTE_ROBOT       ; Graphic 127
  DEFW REMOTE_PAD         ; Graphic 128
  DEFW FRAGILE            ; Graphic 129
  DEFW LEAPER             ; Graphic 130

; An update routine that does nothing
;
; Reached through UPDATES for graphics 0 and 1 (an empty record), 4 to 10, and
; 84.
NO_UPDATE:
  RET

; A leftover that returns at once
;
; Used by the routine at START.
;
; Called once, by START. It loads HL with 0 and rotates R's top bit into the
; carry, and nothing uses either. With the byte after it, JP_HL_LEFTOVER, a JP
; (HL), it reads like the remains of a check that jumped to address 0 -- a
; reset -- when bit 7 of R was set, which only an LD R,A can do; with a plain
; RET where a conditional return would be, it never jumps.
R_CHECK_LEFTOVER:
  LD HL,$0000
  LD A,R
  RLA
  RET

; An unused JP (HL)
;
; The opcode of JP (HL), after the RET of R_CHECK_LEFTOVER and never reached:
; see there.
JP_HL_LEFTOVER:
  DEFB $E9                ; JP (HL)

; A leaper (graphic 130)
;
; Reached through UPDATES. A deadly thing that now and then leaps 48 units
; straight up and falls back. Only one in a room is in the air at a time
; (LEAPING); when none is, each on its turn has a chance of one in four of
; going. It rises two units a turn until it is 48 above where it started or
; meets something above it, then falls under gravity, with a sound pitched by
; its height all the while, and lands.
;
; +10: bit 0 in the air, bit 1 falling. +11: the height to leap to. Rooms $97,
; $A9 and $B7 have them (object template 39).
LEAPER:
  CALL DRAW_AT_L16_D9     ; draw 16 left and 9 down
  CALL MAKE_DEADLY        ; deadly both ways
  BIT 0,(IX+$10)          ; in the air
  JR NZ,LEAPER_0          ;
  LD A,(LEAPING)          ; another is in the air
  AND A                   ;
  RET NZ                  ;
  LD A,(RANDOM)           ; one turn in four
  INC A                   ;
  AND $03                 ;
  RET NZ                  ;
  LD A,$01                ; leap: the flag, and the height to reach, 48 up
  LD (LEAPING),A          ;
  LD (IX+$10),A           ;
  LD A,(IX+$03)           ;
  ADD A,$30               ;
  LD (IX+$11),A           ;
LEAPER_0:
  BIT 1,(IX+$10)          ; not falling yet
  JR Z,LEAPER_2           ;
  CALL DEC_DZ_AND_UPDATE_UVZ ; fall
  BIT 2,(IX+$0C)          ; landed: on the floor again, and another may leap
  JR Z,LEAPER_1           ;
  XOR A                   ;
  LD (IX+$10),A           ;
  LD (LEAPING),A          ;
LEAPER_1:
  CALL BEEP_BY_Z             ; a sound pitched by its height; redraw
  JP SET_WIPE_AND_DRAW_FLAGS ;
LEAPER_2:
  LD (IX+$0B),$03            ; rising: two units a turn (3, less one for
  CALL DEC_DZ_AND_UPDATE_UVZ ; gravity)
  LD A,(IX+$03)           ; not yet at the top, and nothing above
  CP (IX+$11)             ;
  JR NC,LEAPER_3          ;
  BIT 2,(IX+$0C)          ;
  JR NZ,LEAPER_3          ;
  JR LEAPER_1             ;
LEAPER_3:
  SET 1,(IX+$10)          ; now fall
  JR LEAPER_1             ;

; The robot's top in the ending (graphic 93)
;
; Reached through UPDATES. In the scene after the twenty-fourth chamber
; (GAME_ENDED) the robot is two records, legs (graphic 92, OILED_ROBOT) and
; top; the top keeps 16 pixels above the legs, in their colour and with their
; flags, so it is wiped and redrawn with them, and colours its cells
; (COLOUR_SCENE_OBJECT, in SCENE_SPARKS).
SCENE_ROBOT_TOP:
  LD A,(IX-$05)           ; 16 pixels above the legs (the record before: -5 is
  ADD A,$10               ; its +1B)
  LD (IX+$1B),A           ;
  LD A,(IX-$10)           ; its colour
  LD (IX+$10),A           ;
  LD A,(IX-$19)           ; its flags
  LD (IX+$07),A           ;
  JP COLOUR_SCENE_OBJECT  ; colour the cells it covers

; The robot being oiled, in the ending (graphic 92)
;
; Reached through UPDATES: the scene after the twenty-fourth chamber, set up by
; GAME_ENDED in pixels (the scene is not projected). The robot waits 64 turns,
; is lowered three pixels a turn into the can of oil (graphic 85) until it is
; below 40, stays there while its count runs on to 128, then rises three pixels
; a turn, now bright white, to 128, with a sound pitched by its height as it
; moves. Then a tune, and back to the menu (AFTER_GAME).
;
; +11 counts: 0 to 63 waiting; 64 going down and then counting at the bottom;
; 128 and over going up. +10 is its colour (COLOUR_SCENE_OBJECT, in
; SCENE_SPARKS).
OILED_ROBOT:
  LD A,(IX+$11)           ; the first 64 turns: wait
  CP $40                  ;
  JR C,OILED_ROBOT_2      ;
  CP $80                  ; 128 on: going up
  JR NC,OILED_ROBOT_3     ;
  LD A,(IX+$1B)           ; at the bottom: count
  CP $28                  ;
  JR C,OILED_ROBOT_2      ;
  SUB $03                 ; three pixels down
  LD (IX+$1B),A           ;
OILED_ROBOT_0:
  CALL BEEP_BY_A               ; a sound pitched by its height; redraw
  CALL SET_WIPE_AND_DRAW_FLAGS ;
OILED_ROBOT_1:
  JP COLOUR_SCENE_OBJECT  ; colour its cells
OILED_ROBOT_2:
  INC (IX+$11)            ; count on
  JR OILED_ROBOT_1        ;
OILED_ROBOT_3:
  LD A,(IX+$1B)           ; at the top: done
  CP $80                  ;
  JR NC,OILED_ROBOT_4     ;
  ADD A,$03               ; three pixels up, now bright white
  LD (IX+$1B),A           ;
  LD (IX+$10),$47         ;
  JR OILED_ROBOT_0
OILED_ROBOT_4:
  LD DE,TUNE_WON          ; a tune, and back to the menu
  CALL PLAY_TUNE          ;
  JP AFTER_GAME           ;

; A thing that breaks when moved (graphic 129)
;
; Reached through UPDATES. Deadly both ways, and pushable (its template, 38,
; gives it flags $14), but it never moves itself: as long as nothing has given
; it a step it stays. Once something moves it, it turns into graphic 54, the
; last frame of the sparkle a thing dies in (SPARKLE_STEP), and so vanishes.
; The player cannot push one and live; the remote-controlled robots
; (REMOTE_ROBOT), harmless, can, and six of the seven rooms that have these
; have a robot to clear them. The seventh, room $72, has some two dozen and two
; clockwork mice (CLOCKWORK_MOUSE), which run into them and break them: 28 in
; the room's record and on its first turn -- the mice break some while the
; robot is still appearing, so 24 were counted once he was playing -- and 10
; left after 30 seconds of play in the simulator (measured).
FRAGILE:
  CALL DRAW_AT_L12_D4     ; draw 12 left and 4 down
  LD A,(IX+$09)           ; not moved: deadly, and that is all
  OR (IX+$0A)             ;
  OR (IX+$0B)             ;
  JP Z,MAKE_DEADLY        ;
  LD (IX+$00),$36         ; moved: the end of the sparkle
  JP DEADLY_AND_DRAW      ;

; A remote-controlled robot (graphics 124 to 127)
;
; Reached through UPDATES. One in each of eight rooms, two in room $0B, each
; room with four buttons (REMOTE_BUTTON) and a pad (REMOTE_PAD) that the player
; stands on to drive it. One robot at a time is in control: bit 7 of
; REMOTE_ORDERS says one has it, and bit 7 of its own +10 which. The first
; robot to run while no one has control takes it. While the player stands on a
; button the robot in control steps two units a turn in the button's direction
; (REMOTE_STEPS), animating through its four graphics, with a sound; on the pad
; it animates on the spot. When he steps off, it gives control up and the next
; robot to run takes it -- so the two in room $0B take turns, one for each time
; he steps off a button or the pad (measured there).
;
; Otherwise a robot falls under gravity, with a sound pitched by its height
; while it moves. They are harmless, and there to push things: the rooms that
; have them are the rooms of the things that break when moved (FRAGILE), all
; but room $0B.
;
; +10: bit 7 in control, waiting; bit 6 in control, moving.
REMOTE_ROBOT:
  CALL DRAW_AT_L16_D9     ; draw 16 left and 9 down
  LD HL,REMOTE_ORDERS     ; no robot in control: take it
  LD A,(HL)               ;
  AND $80                 ;
  JR Z,REMOTE_ROBOT_1     ;
  LD A,(IX+$10)           ; not this one: just fall
  AND $C0                 ;
  JR Z,REMOTE_ROBOT_0     ;
  BIT 7,(IX+$10)          ; waiting for an order
  JR NZ,REMOTE_ROBOT_2    ;
  LD A,(HL)               ; moving, and another order
  AND $3F                 ;
  JR NZ,REMOTE_ROBOT_3    ;
  RES 7,(HL)              ; no order: give control up, and stop
  RES 6,(IX+$10)          ;
  XOR A                   ;
  LD (IX+$09),A           ;
  LD (IX+$0A),A           ;
REMOTE_ROBOT_0:
  CALL DEC_DZ_AND_UPDATE_UVZ ; fall, and move by the step
  CALL IS_OBJ_MOVING      ; not moving: done
  RET Z                   ;
  CALL BEEP_BY_Z             ; a sound pitched by its height; redraw
  JP SET_WIPE_AND_DRAW_FLAGS ;
REMOTE_ROBOT_1:
  SET 7,(HL)              ; take control
  SET 7,(IX+$10)          ;
  JR REMOTE_ROBOT_0       ;
REMOTE_ROBOT_2:
  LD A,(HL)               ; waiting, and still no order
  AND $7F                 ;
  JR Z,REMOTE_ROBOT_0     ;
  LD A,(IX+$10)           ; an order: from waiting to moving
  AND $3F                 ;
  OR $40                  ;
  LD (IX+$10),A           ;
REMOTE_ROBOT_3:
  LD A,(HL)               ; take the order; control stays taken
  LD (HL),$80             ;
  DEC A                   ; the order's pair of steps
  RLCA                    ;
  AND $7E                 ;
  LD HL,REMOTE_STEPS      ;
  CALL ADD_HL_A           ;
  LD A,(HL)               ; the step in U and in V
  INC HL                  ;
  LD (IX+$09),A           ;
  LD A,(HL)               ;
  DEC HL                  ;
  LD (IX+$0A),A           ;
  CALL NEXT_FRAME_MOD4    ; the next of its four graphics
  LD A,(IX+$09)              ; a step to take: take it
  OR (IX+$0A)                ;
  JR Z,REMOTE_ROBOT_4        ;
  CALL DEC_DZ_AND_UPDATE_UVZ ;
REMOTE_ROBOT_4:
  LD HL,WARBLE_COUNTS        ; its sound; redraw
  CALL WARBLE_SOUND          ;
  JP SET_WIPE_AND_DRAW_FLAGS ;

; The remote-controlled robots' steps
;
; A pair of steps in U and V for each order in REMOTE_ORDERS, 1 to 5
; (REMOTE_ROBOT): the pad stands still; the buttons, graphic 122 and 123 each
; plain and mirrored (REMOTE_BUTTON), step two units along one axis.
REMOTE_STEPS:
  DEFB $00,$00            ; Order 1 (the pad) none; 2 -2 in U; 3 +2 in V; 4 +2
  DEFB $FE,$00            ; in U; 5 -2 in V
  DEFB $00,$02            ;
  DEFB $02,$00            ;
  DEFB $00,$FE            ;

; The remote-control pad (graphic 128)
;
; Reached through UPDATES. When something lands on it -- the collision code
; gives what it lands on its step in Z, so a non-zero step means something is
; standing on it this turn -- it takes the step back and orders the robot in
; control to stand still (order 1). Stepping off it passes control to the other
; robot, as stepping off a button does (REMOTE_ROBOT).
REMOTE_PAD:
  CALL DRAW_AT_L16_D9     ; draw 16 left and 9 down
  LD A,(IX+$0B)           ; nothing on it
  AND A                   ;
  RET Z                   ;
  XOR A                   ; it does not move
  LD (IX+$0B),A           ;
  LD HL,REMOTE_ORDERS     ; order 1, keeping bit 7
  LD A,(HL)               ;
  AND $80                 ;
  OR $01                  ;
  LD (HL),A               ;
  RET                     ;

; A remote-control button (graphics 122 and 123)
;
; Reached through UPDATES. As the pad (REMOTE_PAD), but the order is 2 to 5,
; from which of the two graphics it is and whether it is mirrored: four
; buttons, a direction each (REMOTE_STEPS).
REMOTE_BUTTON:
  CALL DRAW_AT_L16_D9     ; draw 16 left and 9 down
  LD A,(IX+$0B)           ; nothing on it
  AND A                   ;
  RET Z                   ;
  XOR A                   ; it does not move
  LD (IX+$0B),A           ;
  LD A,(IX+$07)           ; bit 6 of its flags, mirrored, to bit 7
  RLCA                    ;
  AND $80                 ;
  LD C,A                  ;
  LD A,(IX+$00)           ; order = 2 + 2 * (graphic AND 1) + mirrored
  AND $01                 ;
  OR C                    ;
  RLCA                    ;
  ADD A,$02               ;
  LD C,A                  ;
  LD HL,REMOTE_ORDERS     ; into the orders, keeping bit 7
  LD A,(HL)               ;
  AND $80                 ;
  OR C                    ;
  LD (HL),A               ;
  RET                     ;

; A thing that homes in on the player (graphics 120 and 121)
;
; Reached through UPDATES. Deadly both ways; every turn it steps one unit
; towards the player in U and in V (MOVE_TOWARDS_PLAYER), falls under gravity,
; flips between its two graphics, and makes its sound. Rooms $5E and $D8 have
; them (object template 29).
SLOW_CHASER:
  CALL DRAW_AT_L12_D4     ; draw 12 left and 4 down
  LD BC,$0101              ; one unit towards him in U and V
  CALL MOVE_TOWARDS_PLAYER ;
  CALL DEC_DZ_AND_UPDATE_UVZ ; fall, and move
  CALL TOGGLE_FRAME       ; the other graphic
  LD HL,$B6AD             ; its sound
  CALL WARBLE_SOUND       ;
  JP DEADLY_AND_DRAW      ; deadly both ways; redraw

; A clockwork mouse (graphics 116 to 119)
;
; Reached through UPDATES. Deadly both ways. It runs straight along U or V at
; two to five units a turn, flipping between two graphics as it goes, for a
; random number of turns up to 15 (none left counts as 256); when it is
; stopped, is blocked, or has run its turns it beeps and turns a quarter, left
; or right at random, with a new speed and a new count.
;
; The way it faces is its mirror flag (bit 6 of +7: clear along U, set along V)
; and bit 1 of its graphic (which way along it); a turn always flips the mirror
; flag, so always changes the axis, and flips bit 1 or not by the random
; number. The speed is the turn counter's low two bits plus two. +10 counts the
; turns left. Rooms $3F, $42, $45, $4D, $72, $A9 and $D8 have them (object
; template 28).
CLOCKWORK_MOUSE:
  CALL DRAW_AT_L12_D6     ; draw 12 left and 6 down
  CALL DEC_DZ_AND_UPDATE_UVZ ; fall, and move
  LD A,(IX+$09)           ; not moving: turn
  OR (IX+$0A)             ;
  JR Z,CLOCKWORK_MOUSE_1  ;
  LD A,(IX+$0C)           ; blocked in U or V: turn
  AND $03                 ;
  JR NZ,CLOCKWORK_MOUSE_1 ;
  DEC (IX+$10)            ; its turns run out: turn
  JR Z,CLOCKWORK_MOUSE_1  ;
CLOCKWORK_MOUSE_0:
  CALL TOGGLE_FRAME       ; the other of its two graphics
  JP DEADLY_AND_DRAW      ; deadly both ways; redraw
CLOCKWORK_MOUSE_1:
  CALL HIGH_BEEP          ; a beep
  LD A,(TURNS_HIGH)       ; a new count of turns, 0 to 15
  LD C,A                  ;
  LD A,(RANDOM)           ;
  XOR C                   ;
  AND $0F                 ;
  LD (IX+$10),A           ;
  LD A,(IX+$07)           ; always the other axis
  XOR $40                 ;
  LD (IX+$07),A           ;
  LD A,(RANDOM)           ; by the random number, flip its way along the axis
  AND $01                 ; or not
  JR Z,CLOCKWORK_MOUSE_5  ;
  BIT 6,(IX+$07)          ;
  JR Z,CLOCKWORK_MOUSE_3  ;
CLOCKWORK_MOUSE_2:
  LD A,(IX+$00)           ; flip bit 1: the other way
  XOR $02                 ;
  LD (IX+$00),A           ;
CLOCKWORK_MOUSE_3:
  LD A,(TURNS)            ; two to five units, the way bit 1 says
  AND $03                 ;
  ADD A,$02               ;
  BIT 1,(IX+$00)          ;
  JR NZ,CLOCKWORK_MOUSE_4 ;
  NEG                     ;
CLOCKWORK_MOUSE_4:
  BIT 6,(IX+$07)          ; along U
  JR NZ,CLOCKWORK_MOUSE_6 ;
  LD (IX+$09),A           ;
  LD (IX+$0A),$00         ;
  JR CLOCKWORK_MOUSE_0    ;
CLOCKWORK_MOUSE_5:
  BIT 6,(IX+$07)          ; the other half of the random choice
  JR Z,CLOCKWORK_MOUSE_2  ;
  JR CLOCKWORK_MOUSE_3    ;
CLOCKWORK_MOUSE_6:
  NEG                     ; along V
  LD (IX+$0A),A           ;
  LD (IX+$09),$00         ;
  JR CLOCKWORK_MOUSE_0    ;

; Unused: face by the signs of the steps
;
; Nothing calls or jumps here (searched), and the build's sessions never ran
; it; stage 1 took it for data. It is code, and ends where SCENE_TOOL begins:
; it sets bit 1 of the graphic and the mirror flag, the two bits a clockwork
; mouse (CLOCKWORK_MOUSE) faces by, from the signs of the steps in U (+9) and V
; (+A). The signs agree with the mice's way of facing, but the axis does not:
; as written it faces along V when the step in U is the larger, and along U
; otherwise -- across the larger step rather than along it -- so it was either
; for sprites that face another way or left unfinished.
FACE_BY_STEP_UNUSED:
  LD A,(IX+$09)
  AND A
  JP P,FACE_BY_STEP_UNUSED_0
  NEG
FACE_BY_STEP_UNUSED_0:
  LD C,A
  LD A,(IX+$0A)
  AND A
  JP P,FACE_BY_STEP_UNUSED_1
  NEG
FACE_BY_STEP_UNUSED_1:
  CP C
  JR C,FACE_BY_STEP_UNUSED_4
  LD A,(IX+$09)
  AND A
  JP P,FACE_BY_STEP_UNUSED_3
  RES 1,(IX+$00)
FACE_BY_STEP_UNUSED_2:
  RES 6,(IX+$07)
  RET
FACE_BY_STEP_UNUSED_3:
  SET 1,(IX+$00)
  JR FACE_BY_STEP_UNUSED_2
FACE_BY_STEP_UNUSED_4:
  LD A,(IX+$0A)
  AND A
  JP P,FACE_BY_STEP_UNUSED_6
  SET 1,(IX+$00)
FACE_BY_STEP_UNUSED_5:
  SET 6,(IX+$07)
  RET
FACE_BY_STEP_UNUSED_6:
  RES 1,(IX+$00)
  JR FACE_BY_STEP_UNUSED_5

; A tool in the re-programming (graphics 81 to 83)
;
; Reached through UPDATES: the scene after a lost game (GAME_ENDED), with the
; robot (graphics 88 to 91) on its stand in the middle, sparks over its head
; (SCENE_SPARKS), and three tools round it -- a glove at the right (81), a
; hammer above (82) and a hook at the left (83). Once the sparks have stopped
; (SCENE_STATE not zero) the tools take turns: when none is swinging, each on
; its turn has a chance of one in four to start, with a thud. A swing is six
; steps towards the robot -- eight pixels across for the glove and the hook,
; four down for the hammer -- a crash, and six steps back. Fifteen swings end
; the scene and go back to the menu (AFTER_GAME); so does any of the keys 1 to
; 0.
;
; +11: bit 0 swinging, bit 7 on the way back. +F the steps left. +10 the
; colour, which every turn paints the cells it covers (COLOUR_SCENE_OBJECT, in
; SCENE_SPARKS).
SCENE_TOOL:
  LD HL,SCENE_STATE       ; the sparks still flashing: only colour its cells
  LD A,(HL)               ;
  AND A                   ;
  JR Z,SCENE_TOOL_5       ;
  LD A,$E7                ; keys 1 to 0: back to the menu
  CALL READ_KEYS          ;
  JP NZ,AFTER_GAME        ;
  BIT 0,(IX+$11)          ; swinging
  JR NZ,SCENE_TOOL_0      ;
  BIT 7,(HL)              ; another is swinging
  JR NZ,SCENE_TOOL_5      ;
  LD A,(RANDOM)           ; one turn in four
  CPL                     ;
  AND $03                 ;
  JR NZ,SCENE_TOOL_5      ;
  PUSH HL                 ; a thud
  CALL THUD_SOUND         ;
  POP HL                  ;
  SET 0,(IX+$11)          ; swing: this one, one at a time, six steps
  SET 7,(HL)              ;
  LD (IX+$0F),$06         ;
SCENE_TOOL_0:
  LD A,(IX+$00)           ; the hammer (even) swings down; the glove and hook
  AND $01                 ; across
  JR Z,SCENE_TOOL_6       ;
  LD A,(IX+$1A)           ; eight pixels towards the middle of the screen, or
  XOR (IX+$11)            ; back
  AND $80                 ;
  LD A,$08                ;
  JR Z,SCENE_TOOL_1       ;
  NEG                     ;
SCENE_TOOL_1:
  ADD A,(IX+$1A)          ;
  LD (IX+$1A),A           ;
SCENE_TOOL_2:
  DEC (IX+$0F)            ; steps left
  JR NZ,SCENE_TOOL_4      ;
  LD (IX+$0F),$06         ; six more, the other way
  LD A,(IX+$11)           ;
  XOR $80                 ;
  LD (IX+$11),A           ;
  AND $80                 ;
  JR Z,SCENE_TOOL_3       ;
  CALL CRASH_SOUND        ; at the robot: a crash
  JR SCENE_TOOL_4         ;
SCENE_TOOL_3:
  RES 0,(IX+$11)          ; back where it started: the swing is over
  RES 7,(HL)              ;
  INC (HL)                ; count it: fifteen swings
  LD A,(HL)               ;
  AND $7F                 ;
  CP $10                  ;
  JR NZ,SCENE_TOOL_4      ;
  JP AFTER_GAME           ; and back to the menu
SCENE_TOOL_4:
  CALL SET_WIPE_AND_DRAW_FLAGS ; redraw
SCENE_TOOL_5:
  JP COLOUR_SCENE_OBJECT  ; colour its cells
SCENE_TOOL_6:
  LD A,(IX+$1B)           ; the hammer: four pixels towards the middle, or back
  ADD A,$20               ;
  XOR (IX+$11)            ;
  AND $80                 ;
  LD A,$04                ;
  JR Z,SCENE_TOOL_7       ;
  NEG                     ;
SCENE_TOOL_7:
  ADD A,(IX+$1B)          ;
  LD (IX+$1B),A           ;
  JR SCENE_TOOL_2         ;

; The sparks over the robot (graphic 80)
;
; Reached through UPDATES: the first part of the re-programming (SCENE_TOOL).
; Every eighth turn the sparks change colour, bright yellow or black by bit 3
; of the turn counter, with a beep; after sixteen changes they go (graphic 1:
; rubbed out and emptied) and set SCENE_STATE to 1, which lets the tools swing.
;
; COLOUR_SCENE_OBJECT is the update routine of the scene's pieces that do not
; move (graphics 85, 88 to 91: the can of oil, the robot's stand, its legs and
; top) and the last step of the others'. The scene's screen is bright red on
; black (GAME_ENDED), the colour of its frame, and each piece has its own
; colour: this paints the attribute cells a piece's picture covers (its width
; and height as last drawn, at its pixel place) with its colour at +10, bottom
; row first -- except any cell already bright green ($44), the hammer's colour,
; so the hammer stays green where it is over the robot. Nothing puts those
; cells back, so the robot's head is left green after the hammer's blows (seen
; in the simulator). It does nothing for a piece not drawn yet.
SCENE_SPARKS:
  LD A,(TURNS)              ; not an eighth turn: only colour
  LD C,A                    ;
  AND $07                   ;
  JR NZ,COLOUR_SCENE_OBJECT ;
  BIT 3,C                 ; bright yellow, or black
  JR Z,SCENE_SPARKS_0     ;
  ADD A,$46               ;
SCENE_SPARKS_0:
  LD (IX+$10),A           ;
  CALL PLAIN_BEEP         ; a beep
  INC (IX+$11)              ; sixteen changes
  LD A,(IX+$11)             ;
  CP $10                    ;
  JR NZ,COLOUR_SCENE_OBJECT ;
  LD A,$01                ; the tools may start; the sparks go
  LD (SCENE_STATE),A      ;
  LD (IX+$00),A           ;
  CALL COLOUR_SCENE_OBJECT   ; colour its cells; redraw
  JP SET_WIPE_AND_DRAW_FLAGS ;
; This entry point is used by the routines at SCENE_ROBOT_TOP, OILED_ROBOT and
; SCENE_TOOL.
COLOUR_SCENE_OBJECT:
  LD A,(IX+$18)           ; not drawn yet
  OR (IX+$19)             ;
  RET Z                   ;
  LD L,(IX+$1A)           ; the cells across: its width, one more if it starts
  LD B,(IX+$18)           ; inside a cell
  LD A,L                  ;
  AND $07                 ;
  JR Z,SCENE_SPARKS_1     ;
  INC B                   ;
SCENE_SPARKS_1:
  LD H,(IX+$1B)           ; the rows of cells from its bottom to its top
  LD A,H                  ;
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  AND $1F                 ;
  LD C,A                  ;
  LD A,(IX+$19)           ;
  DEC A                   ;
  ADD A,H                 ;
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  AND $1F                 ;
  SUB C                   ;
  INC A                   ;
  LD C,A                  ;
  CALL CALC_ATTRIB_ADDR   ; the bottom-left cell's attribute; the colour
  EX DE,HL                ;
  LD A,(IX+$10)           ;
  LD DE,$0020             ;
SCENE_SPARKS_2:
  PUSH BC                 ; a row
  PUSH HL                 ;
  LD C,A                  ;
SCENE_SPARKS_3:
  LD A,(HL)               ; each cell but a bright green one
  CP $44                  ;
  JR Z,SCENE_SPARKS_4     ;
  LD (HL),C               ;
SCENE_SPARKS_4:
  INC L                   ;
  DJNZ SCENE_SPARKS_3     ;
  LD A,C                  ; up a row, for each row
  POP HL                  ;
  POP BC                  ;
  AND A                   ;
  SBC HL,DE               ;
  DEC C                   ;
  JR NZ,SCENE_SPARKS_2    ;
  RET                     ;

; Count the chambers and the cryonauts for the summary
;
; Used by the routine at GAME_ENDED.
;
; Called by GAME_ENDED at the end of a game, after the valves in the room have
; been written back to their places (UPDATE_SPECIAL_OBJS). Walks the room
; directory (ROOM02). A room is a chamber if the first object groups after its
; backgrounds are the frozen crew, object templates 21 and 22 (graphic 74) --
; exactly the 24 rooms with a socket. A chamber with a seated valve lying in it
; (graphics 100-103, looked for in the places, PLACES) counts in
; SUMMARY_ACTIVE; any other in SUMMARY_IDLE, and its crew -- a group's count,
; for each group of templates 21 and 22 in a row -- in SUMMARY_LOST. All three
; are BCD. The game's summary calls them the activated and unactivated
; cryogenic chambers and the cryonauts lost: with none activated, 24 and 132
; (measured: the summary screen in the simulator, and the room data counted the
; same way).
;
; A record is read as the builder reads it: the byte count at +1 bounds the
; walk, the backgrounds end with $FF, and a group is a header and a position
; for each copy.
SUMMARISE_CHAMBERS:
  LD DE,SUMMARY_LOST      ; the three counts to zero
  LD B,$04                ;
  CALL ZERO_DE            ;
  LD HL,ROOM02            ; the first room
SUMMARISE_CHAMBERS_0:
  LD C,(HL)               ; C = the room, B = the count of its bytes
  INC HL                  ;
  LD B,(HL)               ;
SUMMARISE_CHAMBERS_1:
  LD A,(HL)                 ; look for the $FF after the backgrounds; the count
  INC HL                    ; running out first means no objects
  INC A                     ;
  JR Z,SUMMARISE_CHAMBERS_3 ;
  DJNZ SUMMARISE_CHAMBERS_1 ;
SUMMARISE_CHAMBERS_2:
  LD BC,OBJECT_TABLE      ; the next room, until the end of the directory at
  AND A                   ; OBJECT_TABLE
  SBC HL,BC               ;
  RET NC                  ;
  ADD HL,BC
  JR SUMMARISE_CHAMBERS_0
SUMMARISE_CHAMBERS_3:
  DEC B                   ; the bytes left after the $FF
  LD A,(HL)                 ; the first group crew (template 21 or 22)?
  AND $F8                   ;
  CP $A8                    ;
  JR Z,SUMMARISE_CHAMBERS_5 ;
  CP $B0                    ;
  JR Z,SUMMARISE_CHAMBERS_5 ;
SUMMARISE_CHAMBERS_4:
  LD A,B                  ; no: skip the rest of the record
  CALL ADD_HL_A           ;
  JR SUMMARISE_CHAMBERS_2 ;
SUMMARISE_CHAMBERS_5:
  LD IY,PLACES            ; a chamber: look for a place in this room
SUMMARISE_CHAMBERS_6:
  LD A,(IY+$08)             ; in this room?
  CP C                      ;
  JR Z,SUMMARISE_CHAMBERS_8 ;
SUMMARISE_CHAMBERS_7:
  LD DE,$0009                ; nine bytes on, to the end of the places at
  ADD IY,DE                  ; GRAPHICS
  PUSH HL                    ;
  PUSH IY                    ;
  POP HL                     ;
  LD DE,GRAPHICS             ;
  AND A                      ;
  SBC HL,DE                  ;
  PUSH HL                    ;
  POP IY                     ;
  POP HL                     ;
  JR NC,SUMMARISE_CHAMBERS_9 ;
  LD DE,GRAPHICS             ;
  ADD IY,DE                  ;
  JR SUMMARISE_CHAMBERS_6    ;
SUMMARISE_CHAMBERS_8:
  LD A,(IY+$00)              ; a seated valve? If not, look on
  SUB $64                    ;
  CP $04                     ;
  JR NC,SUMMARISE_CHAMBERS_7 ;
  LD A,(SUMMARY_ACTIVE)   ; activated: count it, and on to the next room
  ADD A,$01               ;
  DAA                     ;
  LD (SUMMARY_ACTIVE),A   ;
  JR SUMMARISE_CHAMBERS_4 ;
SUMMARISE_CHAMBERS_9:
  LD DE,SUMMARY_LOST_LOW  ; not activated: add the group's crew to those lost
  EX DE,HL                ;
  LD A,(DE)               ;
  AND $07                 ;
  INC A                   ;
  ADD A,(HL)              ;
  DAA                     ;
  LD (HL),A               ;
  DEC HL                  ;
  LD A,(HL)               ;
  ADC A,$00               ;
  DAA                     ;
  LD (HL),A               ;
  EX DE,HL                ; past the group: its header and a position a copy
  LD A,(HL)               ;
  AND $07                 ;
  ADD A,$02               ;
  LD E,A                  ;
  CALL ADD_HL_A           ;
  LD A,E                     ; the record's bytes used up
  NEG                        ;
  ADD A,B                    ;
  LD B,A                     ;
  JR Z,SUMMARISE_CHAMBERS_10 ;
  LD A,(HL)                 ; another group of crew: count it too
  AND $F8                   ;
  CP $A8                    ;
  JR Z,SUMMARISE_CHAMBERS_9 ;
  CP $B0                    ;
  JR Z,SUMMARISE_CHAMBERS_9 ;
  LD A,B                  ; skip the rest of the record
  CALL ADD_HL_A           ;
SUMMARISE_CHAMBERS_10:
  LD A,(SUMMARY_IDLE)     ; count the chamber not activated
  ADD A,$01               ;
  DAA                     ;
  LD (SUMMARY_IDLE),A     ;
  JP SUMMARISE_CHAMBERS_2 ;

; A thing that drops from the ceiling (graphic 73)
;
; Reached through UPDATES. Knight Lore's spiked ball: deadly both ways, it
; hangs until a turn when the random number is under 16 (one in sixteen), no
; other is falling (DROPPING), and the drop latch (DROP_LATCH) is clear --
; which in an even-numbered room it is not until something has been picked up.
; Then it falls, with a sound pitched by its height, lands with a thud
; (THUD_ON_LANDING), and lets the next one go.
;
; Bit 2 of +D: falling. Once on the floor it can be let go again, but it has
; nowhere to fall and makes no second thud. Rooms $0C, $1C, $58 and $84 have
; them (object template 20).
CEILING_DROP:
  CALL MAKE_DEADLY        ; deadly both ways
  CALL DRAW_AT_L12_D8     ; draw 12 left and 8 down
  LD A,(DROP_LATCH)       ; latched: nothing drops
  AND A                   ;
  RET NZ                  ;
  BIT 2,(IX+$0D)          ; falling
  JR NZ,CEILING_DROP_0    ;
  LD HL,DROPPING          ; another is falling
  LD A,(HL)               ;
  AND A                   ;
  RET NZ                  ;
  LD A,(RANDOM)           ; one turn in sixteen
  CP $10                  ;
  RET NC                  ;
  SET 2,(IX+$0D)          ; let go
  LD (HL),$01             ;
  RET                     ;
CEILING_DROP_0:
  CALL DEC_DZ_AND_UPDATE_UVZ ; fall
  CALL THUD_ON_LANDING    ; a thud if it has just landed
  BIT 2,(IX+$0C)          ; landed
  JR NZ,CEILING_DROP_2    ;
  CALL BEEP_BY_Z          ; a sound pitched by its height
CEILING_DROP_1:
  JP SET_WIPE_AND_DRAW_FLAGS ; redraw
CEILING_DROP_2:
  RES 2,(IX+$0D)          ; landed: another may fall
  LD HL,DROPPING          ;
  LD (HL),$00             ;
  JR CEILING_DROP_1

; A thud, once, when it lands
;
; Used by the routine at CEILING_DROP.
;
; Used by CEILING_DROP. +F remembers whether it was standing last time; the
; crash sound (CRASH_SOUND) plays when it changes to standing.
THUD_ON_LANDING:
  LD A,(IX+$0C)           ; not standing on anything
  AND $04                 ;
  LD C,A                  ;
  RET Z                   ;
  LD A,(IX+$0F)           ; standing now and not before: the sound
  CP C                    ;
  LD (IX+$0F),C           ;
  CALL NZ,CRASH_SOUND     ;
  RET

; Count down the light years, and show them
;
; Used by the routine at OBJECT_DONE.
;
; Once a turn from the main loop (OBJECT_DONE). CLOCK is four digits, a byte
; each, the highest first; each byte is the digit in bits 4-7 and, in bits 0-2,
; how far it still has to roll. A digit that changes is drawn rows out of line:
; the eight rows from its count down its character, so that it shows mostly the
; next digit up with a count of 7 and rolls down into place as the count runs
; out, like a mechanical counter's wheel (PRINT_ROLLING_DIGIT). Every turn the
; rolling digits roll one row (ROLL_CLOCK); when the last has finished, a light
; year is taken off (CLOCK_BORROW) and the digits it changes start rolling. So
; a light year takes seven turns.
;
; The four digits are printed into the buffer at the right of the panel, the
; last one inverted, and copied to the screen; when all four bytes are zero the
; game is over (GAME_ENDED).
;
; The font's character after 9 (code $3A, 11th of FONT) is a second nought, so
; a 9 that follows a 0 rolls in from a nought.
RUN_CLOCK:
  CALL CLOCK_BORROW       ; a light year off, if the last digit has rolled into
                          ; place
  CALL ROLL_CLOCK         ; roll the rolling digits a row
  LD HL,$D4FA             ; the four digits, at the right of the panel, with
  LD DE,CLOCK             ; the font's digits as characters 0 to 9
  LD B,$04                ;
  PUSH HL                 ;
  LD HL,FONT              ;
  LD (FONT_BASE),HL       ;
  POP HL                  ;
RUN_CLOCK_0:
  LD A,(DE)                ; each digit, rolled
  INC DE                   ;
  CALL PRINT_ROLLING_DIGIT ;
  DJNZ RUN_CLOCK_0         ;
  LD HL,$D41D             ; invert the last digit
  LD B,$08                ;
  LD DE,$0020             ;
RUN_CLOCK_1:
  LD A,(HL)               ;
  CPL                     ;
  LD (HL),A               ;
  ADD HL,DE               ;
  DJNZ RUN_CLOCK_1        ;
  LD BC,$10D0             ; copy the four digits' 32 by 8 pixels to the screen
  CALL CALC_VRAM_ADDR     ;
  CALL CALC_VIDBUF_ADDR   ;
  LD L,C                  ;
  LD H,B                  ;
  LD BC,$0804             ;
  CALL BLIT_TO_SCREEN     ;
  LD HL,CLOCK             ; all four bytes
  LD B,$04                ;
  XOR A                   ;
RUN_CLOCK_2:
  OR (HL)                 ;
  INC HL                  ;
  DJNZ RUN_CLOCK_2        ;
  JP Z,GAME_ENDED         ; zero: the game is over
  RET

; Print a digit rolled
;
; Used by the routine at RUN_CLOCK.
;
; Used by RUN_CLOCK. Prints the eight bytes from the digit's character plus its
; count, so a digit with count c shows its own last 8-c rows at the top and the
; next character's first c rows below them. The printer's PRINT_CHAR does the
; printing, entered part way, from the base in FONT_BASE.
;
;   A the digit (bits 4-7) and its count (bits 0-3)
;   HL where in the buffer
; O:HL the next place along
PRINT_ROLLING_DIGIT:
  PUSH BC                 ; as PRINT_CHAR keeps them
  PUSH DE                 ;
  PUSH HL                 ;
  LD L,A                  ; the digit's character, eight bytes a character
  SRL L                   ;
  SRL L                   ;
  SRL L                   ;
  SRL L                   ;
  LD H,$00                ;
  ADD HL,HL               ;
  ADD HL,HL               ;
  ADD HL,HL               ;
  AND $0F                 ; plus the count: rolled that many rows
  CALL ADD_HL_A           ;
  JP PRINT_GLYPH          ; print it

; Take a light year off
;
; Used by the routine at RUN_CLOCK.
;
; Used by RUN_CLOCK, but only when the last digit has finished rolling (its
; count is 0). Takes one off the last digit, borrowing from the digits above it
; as a 0 becomes a 9; each digit that changes is given a count of 7, to roll
; into place.
CLOCK_BORROW:
  LD HL,CLOCK_LAST        ; the last digit still rolling: nothing
  LD B,$04                ;
  LD A,(HL)               ;
  AND $07                 ;
  RET NZ                  ;
CLOCK_BORROW_0:
  LD A,(HL)               ; not 0: one less, and roll
  LD C,A                  ;
  AND $F0                 ;
  JR Z,CLOCK_BORROW_1     ;
  SUB $10                 ;
  OR $07                  ;
  LD (HL),A               ;
  RET                     ;
CLOCK_BORROW_1:
  LD A,$97                ; 0: 9, rolling, and borrow from the next digit up
  LD (HL),A               ;
  DEC HL                  ;
  DJNZ CLOCK_BORROW_0     ;
  RET

; Roll the clock's digits a row
;
; Used by the routine at RUN_CLOCK.
;
; Used by RUN_CLOCK. From the last digit up, takes one off each count until it
; meets a digit that is not rolling: the digits changed by one borrow always
; roll together.
ROLL_CLOCK:
  LD HL,CLOCK_LAST        ; the last digit first
  LD B,$04                ;
ROLL_CLOCK_0:
  LD A,(HL)               ;
  AND $07                 ;
  RET Z                   ;
  DEC (HL)                ;
  DEC HL                  ;
  DJNZ ROLL_CLOCK_0       ;
  RET                     ;

; Mark the object at IY to be wiped and redrawn
;
; Used by the routine at TAKE_OR_LEAVE.
;
; SET_WIPE_AND_DRAW_FLAGS for the record at IY rather than IX. Used by
; TAKE_OR_LEAVE. Knight Lore's routine of the same name.
;
; IY the record
SET_WIPE_AND_DRAW_IY:
  PUSH IY                      ; IX = IY, and mark it
  PUSH IX                      ;
  PUSH IY                      ;
  POP IX                       ;
  CALL SET_WIPE_AND_DRAW_FLAGS ;
  POP IX                  ; IX and IY back
  POP IY                  ;
  RET                     ;

; Find the room's first object with a graphic in a range
;
; Used by the routine at LOOSE_VALVE.
;
; Looks through the room's 52 records, OBJECTS's records 4 to 55, for a graphic
; from L to L+H-1. Used by LOOSE_VALVE to find the room's socket.
;
;   L the first graphic
;   H how many
; O:IY the record found
; O:F carry set if one was found
FIND_GRAPHIC_HERE:
  LD IY,ROOM_OBJECTS      ; records 4 to 55
  LD DE,$0020             ;
  LD B,$34                ;
FIND_GRAPHIC_HERE_0:
  LD A,(IY+$00)           ; graphic - L < H: found
  SUB L                   ;
  CP H                    ;
  RET C                   ;
  ADD IY,DE                ; the next; none found, no carry
  DJNZ FIND_GRAPHIC_HERE_0 ;
  RET                      ;

; The picture of the valve a socket wants (graphics 104 to 107)
;
; Reached through UPDATES. A chamber's socket (SOCKET) is built with a record
; after it for its sparkle (SOCKET_SPARKLE), which from time to time becomes,
; for two turns, a picture of the valve the socket takes (graphics 104-107
; share the valves' sprites, 96-99), hovering 13 above the socket. Whenever
; anything lies in the room from the places -- a valve, even a seated one, or
; an extra life -- it goes, rubbed out and emptied, so a chamber once activated
; has none.
;
; +10 counts the two turns; then it is the sparkle again (graphic 4 more).
WANTED_VALVE:
  CALL DRAW_AT_L12_D5     ; draw 12 left and 5 down
  CALL ANY_SPECIAL_HERE   ; anything from the places in the room: go
  JP NZ,VANISH            ;
  LD A,(IX-$1D)           ; 13 above the socket, the record before
  ADD A,$0D               ;
  LD (IX+$03),A           ;
  DEC (IX+$10)            ; two turns
  RET NZ                  ;
  SET 2,(IX+$00)             ; then the sparkle, redrawn
  JP SET_WIPE_AND_DRAW_FLAGS ;

; A socket's sparkle (graphics 108 to 111)
;
; Reached through UPDATES. The sparkle over a chamber's socket, built with it
; (object templates 24 to 27, flags $12: out of the collision tests). It hovers
; 13 above the socket and steps through four frames (graphics 108-111 share the
; sprites of the sparkle a thing dies in), and when the frame comes round to
; the socket's kind it shows the valve wanted (WANTED_VALVE) for two turns:
; about two turns in six. Like the picture, it goes when anything lies in the
; room from the places.
SOCKET_SPARKLE:
  CALL DRAW_AT_L12_D5     ; draw 12 left and 5 down
  CALL ANY_SPECIAL_HERE   ; anything from the places in the room: go
  JP NZ,VANISH            ;
  LD A,(IX-$1D)           ; 13 above the socket, the record before
  ADD A,$0D               ;
  LD (IX+$03),A           ;
  CALL NEXT_FRAME_MOD4    ; the next frame
  AND $03                 ;
  LD C,A                  ;
  LD A,(IX-$20)           ; the socket's kind?
  AND $03                 ;
  CP C                    ;
  JR NZ,SOCKET_SPARKLE_0  ;
  RES 2,(IX+$00)          ; yes: the valve wanted, for two turns
  LD (IX+$10),$02         ;
SOCKET_SPARKLE_0:
  JP SET_WIPE_AND_DRAW_FLAGS ; redraw

; A valve seated in its socket (graphics 100 to 103)
;
; Reached through UPDATES. What a valve becomes when it activates its chamber
; (LOOSE_VALVE): it stays where it is, never falling, and cannot be picked up
; (TAKE_OR_LEAVE takes only graphics 96-99). The summary after a game counts a
; chamber activated by finding one of these in its room (SUMMARISE_CHAMBERS).
SEATED_VALVE:
  CALL DRAW_AT_L12_D5     ; draw 12 left and 5 down
  XOR A                   ; no step in U or V
  LD (IX+$09),A           ;
  LD (IX+$0A),A           ;
  RET                     ;

; A chamber's socket (graphics 112 to 115)
;
; Reached through UPDATES. The socket a valve of its kind (its graphic less 16,
; 96-99) is put on to activate the chamber; the valve does the work
; (LOOSE_VALVE). This only brings the sparkle back: when nothing lies in the
; room from the places and the record after the socket is empty -- as when the
; sparkle went because a valve lay here, and the valve has been picked up -- it
; puts the sparkle there again (graphic 108 plus the socket's kind).
;
; The record keeps the sparkle's old position, which is what makes it appear in
; the right place: the projection it then asks for (CALC_PIXEL_XY_IY) is of the
; record at IY, which here is whatever an earlier routine left there -- the
; legs' record, in the simulator -- rather than the new sparkle's. The build's
; sessions never ran this; a scene staged in room $0C, with a valve in the room
; and then taken away, did (measured): the sparkle came back over the socket.
SOCKET:
  CALL DRAW_AT_L16_D7     ; draw 16 left and 7 down
  CALL ANY_SPECIAL_HERE   ; anything from the places in the room: nothing to do
  RET NZ                  ;
  LD A,(IX+$20)           ; the sparkle is there
  AND A                   ;
  RET NZ                  ;
  LD A,(IX+$00)           ; put it back, of the socket's kind
  AND $03                 ;
  OR $6C                  ;
  LD (IX+$20),A           ;
  JP CALC_PIXEL_XY_IY     ; project the record at IY

; Is anything lying in the room from the places?
;
; Used by the routines at WANTED_VALVE, SOCKET_SPARKLE and SOCKET.
;
; The graphics of the two records the places fill (OBJECTS's records 2 and 3)
; ORed: zero when both are empty. Used by the socket and its sparkle
; (WANTED_VALVE, SOCKET_SPARKLE, SOCKET).
;
; O:F zero flag set if nothing is there
ANY_SPECIAL_HERE:
  LD A,(VALVES)           ; VALVES or VALVE_SECOND
  LD C,A                  ;
  LD A,(VALVE_SECOND)     ;
  OR C                    ;
  RET                     ;

; Project the object at IY onto the screen
;
; Used by the routines at SOCKET and TAKE_OR_LEAVE.
;
; CALC_PIXEL_XY for the record at IY rather than IX. Used by TAKE_OR_LEAVE for
; a thing put down, and by SOCKET.
;
; IY the record
CALC_PIXEL_XY_IY:
  PUSH IX                 ; IX = IY for the projection
  PUSH IY                 ;
  POP IX                  ;
  CALL CALC_PIXEL_XY      ;
  POP IX                  ;
  RET                     ;

; A frozen cryonaut (graphic 74)
;
; Reached through UPDATES. The frozen crew in the cryogenic chambers only
; stand: this sets the drawing nudge and nothing more. They are what the
; summary after a game counts (SUMMARISE_CHAMBERS).
CRYONAUT:
  JP DRAW_AT_L12_D4       ; draw 12 left and 4 down

; Bring in what lies in the room from the places
;
; Used by the routine at ENTER_ROOM.
;
; Called while a room is built (ENTER_ROOM), after the builder. Looks through
; the 36 places at PLACES for any in use (a graphic) whose current room (+8) is
; the one he is in, and builds an object record for each in records 2 and 3
; (VALVES and VALVE_SECOND) -- the two kept for them: the graphic; U, V and Z
; from where it is now; the half-sizes 5 by 5 and the height 12; flags $14
; (drawn, can be pushed); the room; nothing moving; and at +10 the address of
; the place, so that the record can be written back (UPDATE_SPECIAL_OBJS).
; Whatever is left of the two records is cleared.
;
; Knight Lore's find_special_objs_here, instruction for instruction; only the
; addresses differ. As there, nothing here stops at two: a third place in one
; room would be built over record 4, the room's first, and the clearing after
; the loop would then never meet record 4 again and would run on through
; memory. The 36 places start in 36 different rooms, and a thing is put down
; only into an empty one of the two records (TAKE_OR_LEAVE), so it does not
; happen (read; inferred for every way a valve can travel).
;
; IX the legs' record, whose +8 is the room being entered
FIND_SPECIAL_OBJS_HERE:
  LD DE,VALVES            ; DE', the record being built, in the alternate set
  EXX                     ;
  LD IY,PLACES            ; the first place; the room
  LD B,(IX+$08)           ;
FIND_SPECIAL_OBJS_HERE_0:
  LD A,(IY+$00)                 ; not in use: skip
  AND A                         ;
  JR Z,FIND_SPECIAL_OBJS_HERE_1 ;
  LD A,(IY+$08)                  ; in another room: skip
  CP B                           ;
  JR NZ,FIND_SPECIAL_OBJS_HERE_1 ;
  PUSH IY                 ; HL = the place; its address is kept on the stack
  EXX                     ;
  POP HL                  ;
  PUSH HL                 ;
  LD A,(HL)               ; the graphic
  INC HL                  ;
  LD (DE),A               ;
  INC DE                  ;
  INC HL                  ; U, V and Z from +5 to +7, where it is now
  INC HL                  ;
  INC HL                  ;
  INC HL                  ;
  LD BC,$0003             ;
  LDIR                    ;
  EX DE,HL                ; 5 by 5 by 12, flags $14
  LD (HL),$05             ;
  INC HL                  ;
  LD (HL),$05             ;
  INC HL                  ;
  LD (HL),$0C             ;
  INC HL                  ;
  LD (HL),$14             ;
  INC HL                  ;
  EX DE,HL                ;
  LD A,(HL)               ; the room
  INC HL                  ;
  LD (DE),A               ;
  INC DE                  ;
  LD B,$07                ; +9 to +F: no step, nothing met
  CALL ZERO_DE            ;
  POP BC                  ; +10 and +11: the place
  LD A,C                  ;
  LD (DE),A               ;
  INC DE                  ;
  LD A,B                  ;
  LD (DE),A               ;
  INC DE                  ;
  LD B,$0E                ; +12 to +1F cleared
  CALL ZERO_DE            ;
  EXX                     ; back to the scan's registers
FIND_SPECIAL_OBJS_HERE_1:
  LD DE,$0009                   ; nine bytes on, until the graphic table at
  ADD IY,DE                     ; GRAPHICS that follows the last place
  PUSH IY                       ;
  POP HL                        ;
  LD DE,GRAPHICS                ;
  AND A                         ;
  SBC HL,DE                     ;
  JR C,FIND_SPECIAL_OBJS_HERE_0 ;
  EXX                     ; DE = the next record to build
FIND_SPECIAL_OBJS_HERE_2:
  LD HL,ROOM_OBJECTS      ; up to record 4, ROOM_OBJECTS
  AND A                   ;
  SBC HL,DE               ;
  RET Z                   ;
  LD B,$20                    ; clear the rest of the two
  CALL ZERO_DE                ;
  JR FIND_SPECIAL_OBJS_HERE_2 ;

; Write the valves in the room back to their places
;
; Used by the routines at GAME_ENDED and ENTER_ROOM.
;
; Called before a new room is built, once a turn has been played (PLAYED:
; ENTER_ROOM), and at the end of a game (GAME_ENDED), so that the summary sees
; where the valves are. For each of records 2 and 3 holding a valve, loose or
; seated (graphics 96 to 103), writes its graphic, its U, V and Z and its room
; back to its place through the address at +10: that is how a valve moved,
; carried in or seated stays where it was left.
;
; Knight Lore's update_special_objs writes back whatever the records hold; this
; writes back only the valves. An extra life (graphic 12) never moves, and
; taking one empties its place (EXTRA_LIFE).
UPDATE_SPECIAL_OBJS:
  LD IY,VALVES            ; record 2
UPDATE_SPECIAL_OBJS_0:
  LD A,(IY+$00)               ; not a valve: skip
  SUB $60                     ;
  CP $08                      ;
  JR NC,UPDATE_SPECIAL_OBJS_1 ;
  LD E,(IY+$10)           ; the place
  LD D,(IY+$11)           ;
  LD A,(IY+$00)           ; the graphic
  LD (DE),A               ;
  INC DE                  ; on to +5
  INC DE                  ;
  INC DE                  ;
  INC DE                  ;
  INC DE                  ;
  PUSH IY                 ; U, V and Z
  POP HL                  ;
  INC HL                  ;
  LD BC,$0003             ;
  LDIR                    ;
  LD A,(IY+$08)           ; the room
  LD (DE),A               ;
UPDATE_SPECIAL_OBJS_1:
  LD BC,$0020                ; record 3, then stop at record 4, ROOM_OBJECTS
  ADD IY,BC                  ;
  PUSH IY                    ;
  POP HL                     ;
  LD BC,ROOM_OBJECTS         ;
  AND A                      ;
  SBC HL,BC                  ;
  JR C,UPDATE_SPECIAL_OBJS_0 ;
  RET

; Deal the valves and the extra lives to their places
;
; Used by the routine at AFTER_GAME.
;
; At every new game (AFTER_GAME). Gives each of the 36 places at PLACES a
; graphic and puts it where it starts, copying +1 to +4 (U, V, Z, room) to +5
; to +8. The kinds of valve go round in order, 96, 97, 98, 99 and again, from a
; random starting kind -- the seed plus the refresh register -- so there are
; nine of each or near it -- but see the extra lives below: they fall 16 places
; apart and the kinds repeat every 4, so every extra life replaces a valve of
; the same kind, and a deal gives 9, 9, 9 and 7 of the four kinds, or 9, 9, 9
; and 6 in a game with three extra lives (one in four). Then one kind has
; exactly the six its sockets need, and losing one valve (BOXES_INTERSECT)
; leaves the game unwinnable (the counts measured; the consequence inferred).
; Every sixteenth place by a second count, started from the random number, gets
; an extra life (graphic 12) instead, and the kind that would have gone there
; is skipped: two or three extra lives a game.
;
; Knight Lore's init_special_objects, which deals eight kinds in turn, the
; eighth its extra life; here four kinds, and the extra lives by a count of
; their own. The chambers want six valves of each kind (SOCKET: six sockets of
; each).
INIT_SPECIAL_OBJECTS:
  LD HL,PLACES            ; the first place
  LD A,(SEED)             ; E: the kind to deal next, from the seed and R
  LD E,A                  ;
  LD A,R                  ;
  ADD A,E                 ;
  LD E,A                  ;
  LD A,(RANDOM)           ; D: the count for the extra lives, from the random
  LD D,A                  ; number
INIT_SPECIAL_OBJECTS_0:
  DEC D                       ; every sixteenth: an extra life
  LD A,D                      ;
  AND $0F                     ;
  JR Z,INIT_SPECIAL_OBJECTS_2 ;
  LD A,E                  ; a valve of the next kind, 96-99
  AND $03                 ;
  OR $60                  ;
INIT_SPECIAL_OBJECTS_1:
  LD (HL),A               ; its graphic; the next kind
  INC HL                  ;
  INC E                   ;
  PUSH DE                 ; +1 to +4, where it starts, to +5 to +8, where it is
  EX DE,HL                ;
  LD HL,$0004             ;
  ADD HL,DE               ;
  EX DE,HL                ;
  LD BC,$0004             ;
  LDIR                    ;
  EX DE,HL                    ; until the graphic table at GRAPHICS, after the
  PUSH HL                     ; last place
  LD BC,GRAPHICS              ;
  AND A                       ;
  SBC HL,BC                   ;
  POP HL                      ;
  POP DE                      ;
  JR C,INIT_SPECIAL_OBJECTS_0 ;
  RET
INIT_SPECIAL_OBJECTS_2:
  LD A,$0C                  ; an extra life
  JR INIT_SPECIAL_OBJECTS_1 ;

; A valve (graphics 96 to 99), and activating a chamber
;
; Reached through UPDATES. A valve falls under gravity, can be pushed, and is
; the one thing that can be picked up and carried (TAKE_OR_LEAVE), and makes a
; sound pitched by its position each turn it moves. In a chamber whose socket
; is of its kind (the socket's graphic less 16) it also steers itself, a unit a
; turn in U and V, towards the socket; when it sits exactly on it -- the same U
; and V, and 12 above the socket's base -- it activates the chamber.
;
; Activating: the valve becomes a seated one (graphic 4 more, SEATED_VALVE);
; the screen's inks run through all eight colours twice, with a sparkle's
; sound; the room's ink becomes white for the rest of the game (through
; ROOM_COLOUR_AT) and the screen and panel are recoloured (COLOUR_PANEL);
; CHAMBERS goes up by one, and the twenty-fourth sets WON and ends the game
; (GAME_ENDED). Otherwise the new count is printed and copied to the screen.
;
; The second test of the kinds, after the valve is found sitting on the socket,
; can never fail: the valve would have steered only to a socket of its kind.
; Had it failed, the valve would have become graphic 64, the dying sparkle, and
; been lost (SPARKLE_STEP). Nothing reaches it (read; never run).
LOOSE_VALVE:
  CALL DRAW_AT_L12_D5     ; draw 12 left and 5 down
  LD HL,$0470             ; find the room's socket, graphics 112 to 115
  CALL FIND_GRAPHIC_HERE  ;
  JR NC,LOOSE_VALVE_2     ;
  LD A,(IY+$00)           ; not of this valve's kind: only a valve
  AND $03                 ;
  LD C,A                  ;
  LD A,(IX+$00)           ;
  AND $03                 ;
  CP C                    ;
  JR NZ,LOOSE_VALVE_2     ;
  LD A,(IX+$01)           ; a step of one in U towards the socket
  SUB (IY+$01)            ;
  JR Z,LOOSE_VALVE_0      ;
  LD A,$01                ;
  JP M,LOOSE_VALVE_0      ;
  NEG                     ;
LOOSE_VALVE_0:
  LD (IX+$09),A           ;
  LD A,(IX+$02)           ; and in V
  SUB (IY+$02)            ;
  JR Z,LOOSE_VALVE_1      ;
  LD A,$01                ;
  JP M,LOOSE_VALVE_1      ;
  NEG                     ;
LOOSE_VALVE_1:
  LD (IX+$0A),A           ;
  LD A,(IX+$01)           ; not over it yet
  CP (IY+$01)             ;
  JR NZ,LOOSE_VALVE_2     ;
  LD A,(IX+$02)           ;
  CP (IY+$02)             ;
  JR NZ,LOOSE_VALVE_2     ;
  LD A,(IY+$03)           ; sitting on it: activate
  ADD A,$0C               ;
  CP (IX+$03)             ;
  JR Z,LOOSE_VALVE_4      ;
LOOSE_VALVE_2:
  CALL DEC_DZ_AND_UPDATE_UVZ ; fall, and move
  BIT 0,(IX+$0D)          ; just put down: its sound
  JR NZ,LOOSE_VALVE_3     ;
  CALL IS_OBJ_MOVING      ; not moving: done
  RET Z                   ;
LOOSE_VALVE_3:
  RES 0,(IX+$0D)          ; no step left in U or V; a sound pitched by where it
  CALL CLEAR_DUV          ; is; redraw
  JP SOUND_AND_DRAW       ;
LOOSE_VALVE_4:
  LD A,(IX+$00)           ; the kinds again
  XOR (IY+$00)            ;
  AND $03                 ;
  JR Z,LOOSE_VALVE_5      ;
  LD (IX+$00),$40            ; never: the sparkle, and the valve lost
  JP SET_WIPE_AND_DRAW_FLAGS ;
LOOSE_VALVE_5:
  LD A,(IX+$00)           ; seated: graphic 100-103
  OR $04                  ;
  LD (IX+$00),A           ;
  CALL SOUND_AND_DRAW     ; a sound; redraw
  LD D,$10                ; sixteen times
LOOSE_VALVE_6:
  LD HL,$5800             ; every attribute's ink one on
  LD BC,$0300             ;
LOOSE_VALVE_7:
  LD A,(HL)               ;
  AND $F8                 ;
  LD E,A                  ;
  LD A,(HL)               ;
  INC A                   ;
  AND $07                 ;
  OR E                    ;
  LD (HL),A               ;
  INC HL                  ;
  DEC BC                  ;
  LD A,B                  ;
  OR C                    ;
  JR NZ,LOOSE_VALVE_7     ;
  CALL SPARKLE_SOUND      ; a sparkle's sound
  LD BC,$0200             ; and a pause
LOOSE_VALVE_8:
  DEC BC                  ;
  LD A,B                  ;
  OR C                    ;
  JR NZ,LOOSE_VALVE_8     ;
  DEC D                   ; sixteen times: the inks back where they were
  JR NZ,LOOSE_VALVE_6     ;
  LD HL,(ROOM_COLOUR_AT)  ; the room's ink white, in its record and for now
  LD A,(HL)               ;
  OR $07                  ;
  LD (HL),A               ;
  AND $07                 ;
  LD (ROOM_INK),A         ;
  CALL COLOUR_PANEL       ; recolour the screen and the panel
  LD HL,CHAMBERS          ; one more chamber
  LD A,(HL)               ;
  ADD A,$01               ;
  DAA                     ;
  LD (HL),A               ;
  CP $24                  ; not the twenty-fourth
  JR NZ,LOOSE_VALVE_9     ;
  LD A,$01                ; won: the end
  LD (WON),A              ;
  JP GAME_ENDED           ;
LOOSE_VALVE_9:
  CALL PRINT_CHAMBERS     ; print the count
  LD BC,$1820             ; and copy its 16 by 8 pixels to the screen
  JP BLIT_2X8             ;

; The update routine for the lower half of a two-part creature (graphic 11)
;
; Object templates 17, 18 and 19 are two pieces at one place: a creature
; (graphic 94, 86 or 87) and under it graphic 11, its lower half, in the next
; record. The lower half does nothing of its own: it is put straight under the
; record before it -- the same U and V, 12 lower -- after that record's update
; has moved it, and is redrawn whenever the upper half has any step.
;
; The footstep it asks for never sounds: LOWER_HALF_STEP plays only on an even
; graphic, and 11 is odd. The simulator sessions never ran that part of
; LOWER_HALF_STEP (see the coverage report).
;
; IX the lower half's record; the upper half's is 32 bytes below it
LOWER_HALF:
  CALL DRAW_AT_L12_D6     ; the drawing nudge
  CALL PUT_UNDER_UPPER    ; under the upper half
  LD A,(IX-$17)           ; the upper half has no step in U, V or Z this turn:
  OR (IX-$16)             ; nothing to draw
  OR (IX-$15)             ;
  RET Z                   ;
  CALL LOWER_HALF_STEP       ; a footstep (never, see above), and redraw it
  JP SET_WIPE_AND_DRAW_FLAGS ;

; The update routine for a creature that wanders at random (graphics 94 and 95)
;
; The upper half of object template 17 (the lower half is LOWER_HALF's). It
; walks two units a turn in one of four directions, and when it is stopped, or
; has no step yet, it turns a quarter to the left or to the right, chosen by
; bit 0 of the random number, and sets off the new way on the next turn. It is
; deadly both ways (SPIKES).
;
; The direction is kept in bit 0 of the graphic and bit 6 of the flags, the
; mirror bit (STEP_FROM_FACING has the four combinations), so turning also
; turns the picture. For the move the two halves are made one box
; (JOIN_HALVES); afterwards they are parted again (PART_HALVES).
;
; Measured in the simulator in room $2F: two units a turn in V, then, stopped,
; a quarter turn and two units a turn in U, the lower half following it each
; turn.
;
; IX the upper half's record
WANDERER:
  CALL DRAW_AT_L12_D6     ; the drawing nudge
  CALL JOIN_HALVES        ; the two halves as one box
  LD A,(IX+$09)           ; no step yet: choose a direction
  OR (IX+$0A)             ;
  JR Z,WANDERER_0         ;
  CALL DEC_DZ_AND_UPDATE_UVZ ; move
  LD A,(IX+$0B)           ; a thud whenever it has a step in Z (falling, or
  AND A                   ; just landed)
  CALL NZ,BEEP_BY_Z       ;
  LD A,(IX+$0C)           ; not stopped in U or V: done
  AND $03                 ;
  JR Z,WANDERER_2         ;
WANDERER_0:
  CALL THUD_SOUND         ; a thud as it turns
  LD A,(RANDOM)           ; bit 0 of the random number: which way to turn
  AND $01                 ;
  JR Z,WANDERER_3         ;
  CALL TURN_QUARTER_BACK  ; 1: a quarter turn the other way (TURN_QUARTER_BACK)
WANDERER_1:
  CALL STEP_FROM_FACING   ; set off in the direction it now faces, two units a
  SLA (IX+$09)            ; turn
  SLA (IX+$0A)            ;
WANDERER_2:
  CALL PART_HALVES        ; part the halves; deadly both ways, and redraw it
  JP DEADLY_AND_DRAW      ;
WANDERER_3:
  CALL TURN_QUARTER       ; 0: a quarter turn one way (TURN_QUARTER)
  JR WANDERER_1           ;

; Turn a creature a quarter
;
; Used by the routines at WANDERER and TURN_QUARTER_BACK.
;
; The four directions are the four combinations of bit 0 of the graphic and bit
; 6 of the flags (the mirror bit): taking them as a pair, this steps (0,0) to
; (1,1) to (1,0) to (0,1) and back to (0,0), which by STEP_FROM_FACING's table
; is minus U, minus V, plus U, plus V -- always the same way round.
; TURN_QUARTER_BACK toggles bit 0 first, which makes the same step the other
; way round.
;
; IX the creature
TURN_QUARTER:
  BIT 0,(IX+$00)          ; which of the four is it?
  JR NZ,TURN_QUARTER_1    ;
  BIT 6,(IX+$07)          ;
  JR NZ,TURN_QUARTER_2    ;
  SET 0,(IX+$00)          ; (0,0): to (1,1)
TURN_QUARTER_0:
  SET 6,(IX+$07)          ;
  RET                     ;
TURN_QUARTER_1:
  BIT 6,(IX+$07)          ; (1,0): to (0,1)
  JR NZ,TURN_QUARTER_4    ;
  RES 0,(IX+$00)          ;
  JR TURN_QUARTER_0       ;
TURN_QUARTER_2:
  RES 0,(IX+$00)          ; (0,1): to (0,0)
TURN_QUARTER_3:
  RES 6,(IX+$07)          ;
  RET                     ;
TURN_QUARTER_4:
  SET 0,(IX+$00)          ; (1,1): to (1,0)
  JR TURN_QUARTER_3       ;

; Turn a creature a quarter the other way
;
; Used by the routine at WANDERER.
;
; Toggling bit 0 of the graphic before TURN_QUARTER's step makes the step go
; the other way round: (0,0) to (0,1), (0,1) to (1,0), (1,0) to (1,1), (1,1) to
; (0,0).
;
; IX the creature
TURN_QUARTER_BACK:
  LD A,(IX+$00)           ; graphic XOR 1, then on into the quarter turn
  XOR $01                 ;
  LD (IX+$00),A           ;
  JR TURN_QUARTER         ;

; Set a creature's step from the way it faces
;
; Used by the routines at WANDERER and PACER.
;
; Makes an index of bit 6 of the flags (the mirror bit) and bit 0 of the
; graphic, and copies the step in U and V from FACING_STEPS: one unit in the
; direction it faces. The callers double it.
;
; IX the creature
STEP_FROM_FACING:
  LD A,(IX+$07)           ; bit 6 of the flags, turned into bit 1
  RLCA                    ;
  RLCA                    ;
  RLCA                    ;
  AND $02                 ;
  LD B,A                  ;
  LD A,(IX+$00)           ; with bit 0 of the graphic: 0 to 3, doubled
  AND $01                 ;
  OR B                    ;
  SLA A                   ;
  LD HL,FACING_STEPS      ; its pair in the table
  CALL ADD_HL_A           ;
  LD A,(HL)               ; its steps in U and V
  INC HL                  ;
  LD (IX+$09),A           ;
  LD A,(HL)               ;
  LD (IX+$0A),A           ;
  RET                     ;

; The step in U and V for each way a creature can face
;
; Four pairs of a step in U and a step in V, indexed by bit 6 of the flags (the
; mirror bit) times two plus bit 0 of the graphic (STEP_FROM_FACING).
FACING_STEPS:
  DEFB $FF,$00            ; Unmirrored, graphic even: minus U; odd: plus U.
  DEFB $01,$00            ; Mirrored, even: plus V; odd: minus V
  DEFB $00,$01            ;
  DEFB $00,$FF            ;

; The update routine for a creature that paces to and fro (graphics 86 and 87)
;
; The upper half of object templates 18 and 19 (the lower half is
; LOWER_HALF's). It walks two units a turn along one axis, and when it is
; stopped it turns round, with a thud, and walks back the other way. It keeps
; its step in U or V in +10 while it moves, since a blocked move leaves the
; step zero. With no step at all, as when the room has just been built, it
; takes the way it faces (STEP_FROM_FACING). It is deadly both ways.
;
; Measured in the simulator in room $A6: from U 180 down two units a turn to
; 168, then back up to 184 and down again, the picture turning with it, and the
; lower half following.
;
; IX the upper half's record
PACER:
  CALL DRAW_AT_L12_D6     ; the drawing nudge
  CALL JOIN_HALVES        ; the two halves as one box
PACER_0:
  LD A,(IX+$09)           ; a step in U?
  AND A                   ;
  JR Z,PACER_3            ;
  LD (IX+$10),A              ; yes: keep it, and move
  CALL DEC_DZ_AND_UPDATE_UVZ ;
  BIT 0,(IX+$0C)          ; not stopped in U: done
  JR Z,PACER_2            ;
  LD A,(IX+$10)           ; stopped: walk back the other way
  NEG                     ;
  LD (IX+$09),A           ;
PACER_1:
  CALL THUD_SOUND         ; a thud, and face the new way
  CALL FACE_ALONG_STEP    ;
PACER_2:
  CALL PART_HALVES        ; part the halves; deadly both ways, and redraw it
  JP DEADLY_AND_DRAW      ;
PACER_3:
  LD A,(IX+$0A)           ; a step in V?
  AND A                   ;
  JR Z,PACER_4            ;
  LD (IX+$10),A              ; yes: keep it, and move
  CALL DEC_DZ_AND_UPDATE_UVZ ;
  BIT 1,(IX+$0C)          ; not stopped in V: done
  JR Z,PACER_2            ;
  LD A,(IX+$10)           ; stopped: walk back the other way
  NEG                     ;
  LD (IX+$0A),A           ;
  JR PACER_1              ;
PACER_4:
  CALL STEP_FROM_FACING   ; no step: take the way it faces, two units a turn,
  SLA (IX+$09)            ; and go again
  SLA (IX+$0A)            ;
  JR PACER_0              ;

; Point an object at the player
;
; Used by the routines at SLOW_CHASER and SPARK_CHASER.
;
; Sets the step in U and V to plus or minus the given speeds, each pointing
; from the object towards the robot's legs (PLAYER_U and the V after it) along
; its axis. The sign comes from the difference, so it is right while the two
; are less than 128 apart; level with him, the object steps the negative way.
; Knight Lore's move_towards_plyr, byte for byte in its logic.
;
; IX the object
; C the speed in U
; B the speed in V
MOVE_TOWARDS_PLAYER:
  LD HL,PLAYER_U          ; own U less his U
  LD A,(IX+$01)           ;
  SUB (HL)                ;
  INC HL
  LD A,C                     ; +C if he is further along U, else -C
  JP M,MOVE_TOWARDS_PLAYER_0 ;
  NEG                        ;
MOVE_TOWARDS_PLAYER_0:
  LD (IX+$09),A              ;
  LD A,(IX+$02)           ; own V less his V
  SUB (HL)                ;
  INC HL                  ;
  LD A,B                     ; +B if he is further along V, else -B
  JP M,MOVE_TOWARDS_PLAYER_1 ;
  NEG                        ;
MOVE_TOWARDS_PLAYER_1:
  LD (IX+$0A),A              ;
  RET

; Flip between an object's two frames
;
; Used by the routines at SLOW_CHASER and CLOCKWORK_MOUSE.
;
; Toggles bit 0 of the graphic, for things whose two frames are a pair of
; graphics differing only in bit 0. Knight Lore's toggle_next_prev_sprite.
;
; IX the object
TOGGLE_FRAME:
  LD A,(IX+$00)           ; graphic XOR 1, stored by NEXT_FRAME_MOD4's last
  XOR $01                 ; instruction
  JR NEXT_FRAME_MOD4_0    ;

; Step an object through four frames
;
; Used by the routines at REMOTE_ROBOT, SOCKET_SPARKLE and SPARK_CHASER.
;
; Adds one to the low two bits of the graphic and leaves the rest alone, so 76
; goes to 77, 78, 79 and back to 76. Knight Lore's next_graphic_no_mod_4.
;
; IX the object
NEXT_FRAME_MOD4:
  LD A,(IX+$00)           ; the graphic with its low two bits plus 1, modulo 4
  LD C,A                  ;
  AND $FC                 ;
  LD B,A                  ;
  LD A,C                  ;
  INC A                   ;
  AND $03                 ;
  OR B                    ;
; This entry point is used by the routine at TOGGLE_FRAME.
NEXT_FRAME_MOD4_0:
  LD (IX+$00),A           ; store it (TOGGLE_FRAME comes here too)
  RET

; The update routine for the thing that chases the player (graphics 76 to 79)
;
; Object template 16: a crackle of sparks that heads for the robot at four
; units a turn in U and in V, falls, and runs through its four frames every
; turn, with a note pitched by its position. Nothing here makes it deadly; it
; pushes what it runs into like anything else that moves.
;
; Measured in the simulator in room $9C: it came at him four units a turn along
; U, pushed him before it until both were stopped, and went on cycling its
; frames there.
;
; IX the object
SPARK_CHASER:
  CALL DRAW_AT_L12_D4     ; the drawing nudge
  LD BC,$0404              ; four units a turn at the player, in U and in V
  CALL MOVE_TOWARDS_PLAYER ;
  CALL DEC_DZ_AND_UPDATE_UVZ ; fall, and move
  CALL NEXT_FRAME_MOD4    ; the next of its four frames
  JP SOUND_AND_DRAW       ; a note pitched by U, V and Z, and redraw it

; Turn a creature to face the way it is stepping
;
; Used by the routine at PACER.
;
; Sets bit 0 of the graphic and bit 6 of the flags (the mirror bit) to the pair
; STEP_FROM_FACING would turn back into this step. The comparison of the two
; steps is unsigned, which works because one of them is always zero. With no
; step it leaves them alone. Knight Lore's set_guard_wizard_sprite does the
; same for its guards.
;
; IX the creature
FACE_ALONG_STEP:
  LD A,(IX+$09)           ; not stepping: leave it
  OR (IX+$0A)             ;
  RET Z                   ;
  LD A,(IX+$09)           ; stepping in V (the U step is the smaller)?
  CP (IX+$0A)             ;
  JR C,FACE_ALONG_STEP_2  ;
  BIT 7,A                 ; in U, and plus: (1,0)
  JR NZ,FACE_ALONG_STEP_1 ;
  SET 0,(IX+$00)          ;
FACE_ALONG_STEP_0:
  RES 6,(IX+$07)          ;
  RET                     ;
FACE_ALONG_STEP_1:
  RES 0,(IX+$00)          ; minus: (0,0)
  JR FACE_ALONG_STEP_0    ;
FACE_ALONG_STEP_2:
  BIT 7,(IX+$0A)          ; in V, and minus: (1,1)
  JR Z,FACE_ALONG_STEP_4  ;
  SET 0,(IX+$00)          ;
FACE_ALONG_STEP_3:
  SET 6,(IX+$07)          ;
  RET                     ;
FACE_ALONG_STEP_4:
  RES 0,(IX+$00)          ; plus: (0,1)
  JR FACE_ALONG_STEP_3    ;

; Put a lower half under its upper half
;
; Used by the routine at LOWER_HALF.
;
; Copies U and V from the record before, and puts Z 12 below it: the height of
; one piece.
;
; IX the lower half; the upper half's record is 32 bytes below it
PUT_UNDER_UPPER:
  LD A,(IX-$1F)           ; U and V as the upper half's
  LD (IX+$01),A           ;
  LD A,(IX-$1E)           ;
  LD (IX+$02),A           ;
  LD A,(IX-$1D)           ; Z 12 lower
  SUB $0C                 ;
  LD (IX+$03),A           ;
  RET                     ;

; Make a two-part creature one box for its move
;
; Used by the routines at WANDERER and PACER.
;
; Lowers the upper half's Z by 12 to where its lower half stands and doubles
; its height, so that the move and the collision code treat the two as one
; object; the lower half, in the next record, is taken out of the collision
; tests (bit 1 of its flags) meanwhile. PART_HALVES undoes it.
;
; IX the upper half
JOIN_HALVES:
  LD A,(IX+$03)           ; down to the lower half's Z
  SUB $0C                 ;
  LD (IX+$03),A           ;
  SLA (IX+$06)            ; twice the height
  SET 1,(IX+$27)          ; the lower half out of collisions
  RET

; Part a two-part creature again after its move
;
; Used by the routines at WANDERER and PACER.
;
; Undoes JOIN_HALVES: the upper half back up 12 at its own height, and the
; lower half back in the collision tests.
;
; IX the upper half
PART_HALVES:
  LD A,(IX+$03)           ; up 12
  ADD A,$0C               ;
  LD (IX+$03),A           ;
  SRL (IX+$06)            ; its own height
  RES 1,(IX+$27)          ; the lower half back in collisions
  RET

; The update routine for a block that shuttles to and fro in V (graphic 67)
;
; Object template 14. A note pitched by V every turn, then SHUTTLE_U's common
; part, set up for V: it reads +2 and sets +A. Knight Lore's upd_55.
;
; IX the block
SHUTTLE_V:
  CALL BEEP_BY_V          ; a note pitched by V
  LD HL,$020A             ; H = 2 (V), L = 10 (its step)
  JR SHUTTLE_BLOCK        ;

; The update routine for a block that shuttles to and fro in U (graphic 66)
;
; Object template 13. The block follows the turn counter: folding its low five
; bits at bit 4 gives a triangle wave, 0 up to 15 and back over 32 turns, and
; the block steps one unit a turn towards that place in a span of 16. The
; blocks in odd-numbered records add 16 first, so they run half a cycle out of
; step with those in even-numbered ones. Knight Lore's shuttle_block, with the
; same trick of one routine for both axes: the two IX displacements of the read
; of the position and the write of the step are patched before they run.
;
; The position used is 8 more than the block's own, because a block stands on
; the centre line of a cell, 8 past a multiple of 16. Its Z step is set to 1 so
; that the move's fall (DEC_DZ_AND_UPDATE_UVZ) leaves it at 0: a shuttling
; block never falls.
;
; IX the block
SHUTTLE_U:
  CALL BEEP_BY_U          ; a note pitched by U
  LD HL,$0109             ; H = 1 (U), L = 9 (its step)
; This entry point is used by the routine at SHUTTLE_V.
SHUTTLE_BLOCK:
  LD A,H                  ; patch the displacements of the read below and of
  LD ($B24B),A            ; the write of the step
  LD A,L                  ;
  LD ($B25C),A            ;
  CALL DRAW_AT_L16_D9     ; the drawing nudge
  PUSH IX                 ; C = 16 in an odd-numbered record, 0 in an even one
  POP BC                  ; (bit 5 of the record's address)
  LD A,C                  ;
  RRCA                    ;
  AND $10                 ;
  LD C,A                  ;
  LD A,(TURNS)            ; the turn counter plus C, folded at bit 4: the place
  ADD A,C                 ; to be, 0 to 15
  BIT 4,A                 ;
  JR Z,SHUTTLE_U_0        ;
  CPL                     ;
SHUTTLE_U_0:
  AND $0F                 ;
  LD C,A                  ;
  LD A,(IX+$01)           ; where it is now in its span: U or V (the
  ADD A,$08               ; displacement patched) plus 8, modulo 16
  AND $0F                 ;
  CP C                         ; there: stand still, but redraw it
  JP Z,SET_WIPE_AND_DRAW_FLAGS ;
  LD A,$01                ; one unit towards it: plus if short of it, minus if
  JR C,SHUTTLE_U_1        ; past it, as its U or V step (patched)
  NEG                     ;
SHUTTLE_U_1:
  LD (IX+$09),A           ;
  LD (IX+$0B),$01         ; a Z step of 1, which the fall makes 0
  CALL DEC_DZ_AND_UPDATE_UVZ ; move, and redraw it
  JP SET_WIPE_AND_DRAW_FLAGS ;

; The update routine for a conveyor that carries things forwards in V (graphic
; 68)
;
; Object template 8, and CONVEYOR_PLUS_U, CONVEYOR_MINUS_V and CONVEYOR_MINUS_U
; for the other three directions (graphics 69, 70 and 71, templates 9 to 11). A
; conveyor never moves itself: it only sets its own step, two units a turn,
; every turn (the room builder copies no steps from the templates). What stands
; on it is carried by the collision code: when something lands on anything, and
; has no step of its own in U or V, it takes the step of the thing it has
; landed on (ADJ_DZ_FOR_OBJ_INTERSECT).
;
; The same code copies the lander's Z step into the conveyor's, which is how a
; conveyor knows something has landed on it: this routine then beeps
; (HIGH_BEEP) and clears it.
;
; Measured in the simulator in room $0D, a ring of the four: standing on
; graphic 68, he went up two units in V every turn.
;
; IX the conveyor
CONVEYOR_PLUS_V:
  LD (IX+$0A),$02         ; its step: two units in V
; This entry point is used by the routines at CONVEYOR_PLUS_U, CONVEYOR_MINUS_V
; and CONVEYOR_MINUS_U.
CONVEYOR:
  CALL DRAW_AT_L16_D9     ; the drawing nudge
  LD A,(IX+$0B)           ; something has landed on it: a beep
  AND A                   ;
  CALL NZ,HIGH_BEEP       ;
  XOR A                   ; and its Z step cleared; no redraw, as nothing about
  LD (IX+$0B),A           ; it changes
  RET                     ;

; The update routine for a conveyor that carries things forwards in U (graphic
; 69)
;
; Object template 9; the rest as CONVEYOR_PLUS_V.
;
; IX the conveyor
CONVEYOR_PLUS_U:
  LD (IX+$09),$02         ; two units in U
  JR CONVEYOR             ;

; The update routine for a conveyor that carries things back in V (graphic 70)
;
; Object template 10; the rest as CONVEYOR_PLUS_V.
;
; IX the conveyor
CONVEYOR_MINUS_V:
  LD (IX+$0A),$FE         ; minus two units in V
  JR CONVEYOR             ;

; The update routine for a conveyor that carries things back in U (graphic 71)
;
; Object template 11; the rest as CONVEYOR_PLUS_V.
;
; IX the conveyor
CONVEYOR_MINUS_U:
  LD (IX+$09),$FE         ; minus two units in U
  JR CONVEYOR             ;

; The update routine for a block that collapses when landed on (graphic 45)
;
; Object template 6. It sits still until the robot, or something else of
; graphics 16 to 47 that moves, lands on it -- bit 3 of +D, which the collision
; code sets on what such a thing lands on (ADJ_DZ_FOR_OBJ_INTERSECT) -- and
; then it vanishes in the sparkle (SPARKLE_STEP, SPARKLE_END_PLACE): graphic 64
; is set and stepped to 65 in the same turn, so what is seen is 45, 65, gone
; (measured). Rebuilding the room brings it back. As Knight Lore's collapsing
; block (upd_143).
;
; Graphic 65's routine empties the place the record's +10 and +11 point to,
; which for a block is address 0 in the ROM: the write does nothing.
;
; Measured in the simulator in room $12: dropped on it, he stood on it for a
; turn; it became 65, then 1, then an empty record, and he fell.
;
; IX the block
COLLAPSING_BLOCK:
  CALL DRAW_AT_L16_D9     ; the drawing nudge
  BIT 3,(IX+$0D)          ; landed on? (and ready for the next time)
  RES 3,(IX+$0D)          ;
  RET Z                   ;
  LD (IX+$00),$40         ; yes: graphic 64, and on into the sparkle's next
  JP SPARKLE_STEP         ; frame

; The update routine for things that kill but never move (graphics 72 and 75)
;
; Object templates 15 and 23: sets the drawing nudge and makes the thing deadly
; both ways (SPIKES). It is not marked for redrawing, as nothing about it
; changes. As Pentagram's routine of the same name.
;
; IX the object
STILL_DEADLY:
  CALL DRAW_AT_L16_D9     ; the drawing nudge; deadly both ways, and return
  JR MAKE_DEADLY          ; from there

; The update routine for the spikes (graphic 46)
;
; Object template 7. As STILL_DEADLY with another drawing nudge. The entry at
; MAKE_DEADLY is the common part, used by many update routines: bits 7 and 5 of
; +D, so that the thing kills what it moves into and what touches it, whichever
; of them moved -- Knight Lore's set_both_deadly_flags.
;
; IX the object
SPIKES:
  CALL DRAW_AT_L12_D4     ; the drawing nudge
; This entry point is used by the routines at LEAPER, FRAGILE, CEILING_DROP,
; STILL_DEADLY and DEADLY_AND_DRAW.
MAKE_DEADLY:
  LD A,(IX+$0D)           ; +D OR $A0: deadly both ways
  OR $A0                  ;
  LD (IX+$0D),A           ;
  RET                     ;

; Make an object deadly both ways, and redraw it
;
; Used by the routines at FRAGILE, SLOW_CHASER, CLOCKWORK_MOUSE, WANDERER and
; PACER.
;
; IX the object
DEADLY_AND_DRAW:
  CALL MAKE_DEADLY           ; deadly (SPIKES), and mark it to be redrawn
  JP SET_WIPE_AND_DRAW_FLAGS ;

; The update routine for a block that sinks while something stands on it
; (graphic 44)
;
; Object template 5. Each turn something is on it -- bit 3 of +D, set by the
; collision code on what the robot or another mover of graphics 16 to 47 lands
; on (ADJ_DZ_FOR_OBJ_INTERSECT), and cleared here -- it sinks one unit, with a
; grinding note, until it lands on what is under it. As Knight Lore's dropping
; block (upd_91).
;
; Measured in the simulator in room $82: with him on it, it went down one unit
; a turn from Z 100. On the floor, as in room $12, it cannot sink and stays
; put. The sessions of the build had never stood on one (the coverage report).
;
; IX the block
DROPPING_BLOCK:
  CALL DRAW_AT_L16_D9     ; the drawing nudge
  BIT 3,(IX+$0D)          ; nothing on it: nothing to do, not even a redraw
  RES 3,(IX+$0D)          ;
  RET Z                   ;
  LD (IX+$0B),$00            ; a Z step of 0, which the fall makes -1: down one
  CALL DEC_DZ_AND_UPDATE_UVZ ;
  LD (IX+$0B),$00         ; no Z step kept
  BIT 2,(IX+$0C)          ; still moving down: a grinding note pitched by Z
  JR NZ,DROPPING_BLOCK_0  ;
  CALL BEEP_BY_Z          ;
DROPPING_BLOCK_0:
  JP SET_WIPE_AND_DRAW_FLAGS ; redraw it

; Keep an object's position
;
; Used by the routine at PUSHABLE.
;
; Copies U, V and Z to SAVED_UVZ, for SAME_UVZ to compare after a move.
;
; IX the object
SAVE_UVZ:
  LD HL,SAVED_UVZ         ; U, V and Z to SAVED_UVZ
  LD A,(IX+$01)           ;
  LD (HL),A               ;
  INC HL                  ;
  LD A,(IX+$02)           ;
  LD (HL),A               ;
  INC HL                  ;
  LD A,(IX+$03)           ;
  LD (HL),A               ;
  RET                     ;

; Is an object where it was?
;
; Used by the routine at PUSHABLE.
;
; Compares U, V and Z with SAVED_UVZ (SAVE_UVZ).
;
;   IX the object
; O:F Z set if it has not moved
SAME_UVZ:
  LD HL,SAVED_UVZ         ; U, V and Z each as they were
  LD A,(IX+$01)           ;
  CP (HL)                 ;
  RET NZ                  ;
  INC HL                  ;
  LD A,(IX+$02)           ;
  CP (HL)                 ;
  RET NZ                  ;
  INC HL                  ;
  LD A,(IX+$03)           ;
  CP (HL)                 ;
  RET                     ;

; The update routine for a block that can be pushed (graphic 28)
;
; Object template 2. Its flags have bit 2 set, and the collision code gives a
; thing with that bit the step of whatever pushes into it
; (ADJ_DU_FOR_OBJ_INTERSECT, ADJ_DV_FOR_OBJ_INTERSECT). Each turn it falls and
; moves by its steps; if it moved, its steps in U and V are cleared, so that a
; push moves it once and not on and on (the end of MOVE_PLAYER does the
; clearing), and it sounds a note pitched by its position and is redrawn. As
; Knight Lore's chest (upd_85) and table.
;
; The position is kept before the move and compared after it, for the case
; where it has no step left but has moved. By the reading that cannot happen --
; with every step zero the move adds nothing -- and the sessions never ran it.
;
; IX the block
PUSHABLE:
  CALL DRAW_AT_L16_D9     ; the drawing nudge
; This entry point is used by the routine at PUSHABLE_INVERTED.
PUSHABLE_MOVE:
  CALL SAVE_UVZ           ; keep its place
  CALL DEC_DZ_AND_UPDATE_UVZ ; fall, and move
  CALL IS_OBJ_MOVING      ; any step left in U, V or Z?
  JR NZ,PUSHABLE_0        ;
  CALL SAME_UVZ              ; none: redraw it only if it has moved (never, see
  RET Z                      ; above)
  JP SET_WIPE_AND_DRAW_FLAGS ;
PUSHABLE_0:
  CALL CLEAR_DUV          ; moving: one step per push; a note pitched by U, V
  JP SOUND_AND_DRAW       ; and Z, and redraw it

; The update routine for the other block that can be pushed (graphic 29)
;
; Object template 3: PUSHABLE with another drawing nudge. Its sprite is graphic
; 28's shape upside down.
;
; IX the block
PUSHABLE_INVERTED:
  CALL DRAW_AT_L16_D6     ; the drawing nudge, and on as graphic 28
  JR PUSHABLE_MOVE        ;

; The update routines for the lift (graphic 47) and the bobbing block (graphic
; 31)
;
; The lift is object template 12 and the bobbing block template 4. Both keep
; their state in bit 2 of +D, which the kill bits leave free: clear while it
; goes down, one unit a turn, and set while it goes up, two a turn. Going down,
; it turns round when it is stopped (bit 2 of +C, set by the collision code
; whenever a move in Z is stopped, down or up); going up, it turns round when
; its Z passes the top, LIFT_TOP, the variable stage 1 called UNKNOWN_5B25,
; which the first of them updated after the room is built sets and every lift
; and block in the room then shares.
;
; The lift (entry here) waits on the floor: LIFT_TOP is its first Z plus 48,
; and it moves only in a turn the robot or another mover of graphics 16 to 47
; lands on it (bit 3 of +D, set by ADJ_DZ_FOR_OBJ_INTERSECT and cleared here),
; or while its last move was stopped in Z -- as it is each turn it pushes a
; rider up. Left alone in mid-air it would stay where it is (by the reading;
; not tried). The bobbing block (entry at BOBBER) moves every turn, and
; LIFT_TOP is its first Z: it starts at the top.
;
; Going up, a stopped move is tried again at a step of 4: the collision code
; passes the lift's Z step to what it pushes into (ADJ_DZ_FOR_OBJ_INTERSECT),
; so the rider is lifted.
;
; Measured in the simulator. Room $23: two lifts at Z 64 stayed put; dropped on
; one, he rode it up one unit a turn to Z 113 (LIFT_TOP 112), and it came down
; with him one unit a turn to the floor, and up again. Room $36: two bobbing
; blocks, LIFT_TOP 100, each falling one unit a turn to what is under it at Z
; 76 and rising two a turn to 102, half a cycle apart.
;
; IX the lift or the block
LIFT:
  CALL DRAW_AT_L16_D9     ; the drawing nudge
  LD A,(LIFT_TOP)         ; the first lift in the room sets the top: its Z plus
  AND A                   ; 48
  JR NZ,LIFT_0            ;
  LD A,(IX+$03)           ;
  ADD A,$30               ;
  LD (LIFT_TOP),A         ;
LIFT_0:
  BIT 3,(IX+$0D)          ; landed on this turn? (cleared for the next)
  RES 3,(IX+$0D)          ;
  JR NZ,LIFT_MOVE         ;
  BIT 2,(IX+$0C)          ; no: only move if the last move was stopped in Z
  RET Z                   ;
BOBBER:
  CALL DRAW_AT_L16_D9     ; the drawing nudge (the bobbing block's entry)
  LD A,(LIFT_TOP)         ; the first bobbing block in the room sets the top:
  AND A                   ; its Z
  JR NZ,LIFT_MOVE         ;
  LD A,(IX+$03)           ;
  LD (LIFT_TOP),A         ;
LIFT_MOVE:
  CALL BEEP_BY_Z          ; a note pitched by Z
  XOR A                   ; no step in U or V
  LD (IX+$09),A           ;
  LD (IX+$0A),A           ;
  BIT 2,(IX+$0D)          ; going up?
  JR NZ,LIFT_2            ;
  LD (IX+$0B),A              ; down: a Z step of 0, which the fall makes -1
  CALL DEC_DZ_AND_UPDATE_UVZ ;
  BIT 2,(IX+$0C)          ; stopped: go up from the next turn
  JR Z,LIFT_1             ;
  SET 2,(IX+$0D)          ;
LIFT_1:
  JP SET_WIPE_AND_DRAW_FLAGS ; redraw it
LIFT_2:
  LD (IX+$0B),$03            ; up: a Z step of 3, which the fall makes 2
  CALL DEC_DZ_AND_UPDATE_UVZ ;
  BIT 2,(IX+$0C)          ; not stopped: see if it is past the top
  JR Z,LIFT_3             ;
  LD (IX+$0B),$04            ; stopped by what is on it: try again at 4, which
  XOR A                      ; lifts the rider
  LD (IX+$09),A              ;
  LD (IX+$0A),A              ;
  CALL DEC_DZ_AND_UPDATE_UVZ ;
LIFT_3:
  LD A,(LIFT_TOP)         ; not past the top: redraw it
  CP (IX+$03)             ;
  JR NC,LIFT_1            ;
  RES 2,(IX+$0D)          ; past it: go down from the next turn
  JR LIFT_1               ;

; Start the sparkle an object vanishes in
;
; Used by the routines at PLAYER_LEGS and TOP_FOLLOWS_LEGS.
;
; Turns the object into graphic 48, the first frame of the sparkle, and takes
; it out of the collision tests (bit 1 of its flags); SPARKLE_STEP runs it on
; through 49 to 54 a frame a turn, and SPARKLE_END_PLACE's graphic 55 ends it.
; Used by the robot's update routines (PLAYER_LEGS, TOP_FOLLOWS_LEGS) when he
; dies. Knight Lore's init_death_sparkles; Pentagram's START_PUFF.
;
; IX the object
START_SPARKLE:
  LD (IX+$00),$30           ; graphic 48, out of collisions
  SET 1,(IX+$07)            ;
  JR SPARKLE_SOUND_AND_DRAW ;

; The update routine for a frame of the sparkle (graphics 48 to 54, and 64)
;
; Used by the routine at COLLAPSING_BLOCK.
;
; Moves the sparkle on a frame each turn: 48 to 54 run to 55, and 64 (a
; collapsing block, COLLAPSING_BLOCK, or a touched extra life, EXTRA_LIFE) goes
; to 65. The sound (SPARKLE_SOUND) is shorter at each frame.
;
; IX the object
SPARKLE_STEP:
  CALL DRAW_AT_L12_D4     ; the drawing nudge
  INC (IX+$00)            ; the next frame
; This entry point is used by the routine at START_SPARKLE.
SPARKLE_SOUND_AND_DRAW:
  CALL SPARKLE_SOUND         ; the sparkle's sound, and redraw it
  JP SET_WIPE_AND_DRAW_FLAGS ;

; The update routines for the last frame of a sparkle (graphics 65 and 55)
;
; Graphic 65 is the end of the sparkle an extra life vanishes in (EXTRA_LIFE):
; it first clears the graphic of its place in PLACES, whose address is in +10
; and +11, so the extra life is gone for good. A collapsing block
; (COLLAPSING_BLOCK) comes here too, with 0 in +10 and +11, and writes its zero
; into the ROM. Graphic 55, the end of a death's sparkle, comes in at
; SPARKLE_END. Either way the record becomes graphic 1, which the drawing
; empties when it next draws it, with a note pitched by the position. Knight
; Lore's upd_185_187.
;
; Two more entries serve other routines: VANISH, which turns any object into
; graphic 1 (WANTED_VALVE, SOCKET_SPARKLE), and SOUND_AND_DRAW, a note pitched
; by U, V and Z and a redraw, the common end of many update routines.
;
; IX the object
SPARKLE_END_PLACE:
  LD L,(IX+$10)           ; empty its place
  LD H,(IX+$11)           ;
  LD (HL),$00             ;
SPARKLE_END:
  CALL DRAW_AT_L12_D4     ; the drawing nudge (graphic 55's entry)
; This entry point is used by the routines at WANTED_VALVE and SOCKET_SPARKLE.
VANISH:
  LD (IX+$00),$01         ; graphic 1: gone when next drawn
; This entry point is used by the routines at LOOSE_VALVE, SPARK_CHASER,
; PUSHABLE and EXTRA_LIFE.
SOUND_AND_DRAW:
  CALL BEEP_BY_UVZ           ; a note pitched by U, V and Z, and redraw it
  JP SET_WIPE_AND_DRAW_FLAGS ;

; The tune as a game starts
;
; Played to its end by AFTER_GAME between the menu and the first room.
; Seventeen notes, 18 units of about 0.155 seconds; the notes are 37 to 45 of
; NOTES.
;
; A tune is a string of note bytes ended by $FF: the low six bits of a note
; index the notes (NOTES, 0 would be a rest, and no tune has one), and the top
; two bits are its length less one, so a note lasts one to four units. The
; other tunes are in the same format. The winning tune (TUNE_WON) begins with
; these seventeen notes.
TUNE_START:
  DEFB $25,$28,$2C,$25,$2A,$2D,$2C,$2A ; Note bytes
  DEFB $28,$2C,$2A,$28,$27,$2A,$28,$27 ;
  DEFB $65                             ;

; The end of the start tune
TUNE_START_END:
  DEFB $FF                ; $FF ends the tune

; The tune at the end of the winning scene
;
; Played to its end by OILED_ROBOT (graphic 92) as the scene after a won game
; finishes, before the menu. Thirty-one notes, 32 units: the start tune
; (TUNE_START) and fourteen more.
TUNE_WON:
  DEFB $25,$28,$2C,$25,$2A,$2D,$2C,$2A ; Note bytes
  DEFB $28,$2C,$2A,$28,$27,$2A,$28,$27 ;
  DEFB $25,$28,$2C,$25,$2A,$2D,$2C,$2A ;
  DEFB $28,$25,$27,$2C,$28,$25,$65     ;

; The end of the winning tune
TUNE_WON_END:
  DEFB $FF                ; $FF ends the tune

; The game-over tune
;
; Played by GAME_ENDED under the summary after every game, won or lost, until a
; key is pressed (PLAY_TUNE_ONCE's second entry). Sixty-three notes, 64 units,
; about ten seconds; notes 30 to 44. It runs on through the next eight entries
; to the $FF at TUNE_GAME_OVER_END: sna2ctl took some of its bytes for text.
TUNE_GAME_OVER:
  DEFB $25,$29,$2C,$29,$24,$29,$2C,$29 ; Note bytes
  DEFB $22,$27,$2A,$27,$21,$27,$2A,$27 ;
  DEFB $20,$25,$29,$25                 ;

; The game-over tune, continued
TUNE_GAME_OVER_B:
  DEFB $1F                ; A note

; The game-over tune, continued
TUNE_GAME_OVER_C:
  DEFB $25,$29,$25        ; Note bytes

; The game-over tune, continued
TUNE_GAME_OVER_D:
  DEFB $1E                ; A note

; The game-over tune, continued
TUNE_GAME_OVER_E:
  DEFB $24,$27,$24,$20,$24,$27,$24,$25 ; Note bytes
  DEFB $29,$2C,$29,$24,$29,$2C,$29,$22 ;
  DEFB $27,$2A,$27,$21,$27,$2A,$27,$20 ;
  DEFB $25,$29,$25                     ;

; The game-over tune, continued
TUNE_GAME_OVER_F:
  DEFB $1F                ; A note

; The game-over tune, continued
TUNE_GAME_OVER_G:
  DEFB $25,$29,$25        ; Note bytes

; The game-over tune, continued
TUNE_GAME_OVER_H:
  DEFB $1E                ; A note

; The game-over tune, continued
TUNE_GAME_OVER_I:
  DEFB $24,$27,$24,$25,$29,$65 ; Note bytes

; The end of the game-over tune; the arrival tune; the menu tune
;
; Three things in one entry. The first byte is the $FF that ends the game-over
; tune (TUNE_GAME_OVER). The arrival tune that follows is Knight Lore's
; game-completed tune, byte for byte (compared against its snapshot).
;
; TUNE_ARRIVAL, the next 26 bytes: the tune ARRIVAL_SCREEN plays to its end
; when the game is won, as the arrival text is shown. Twenty-five notes and its
; $FF, 27 units; notes 26 to 34.
;
; TUNE_MENU, the last 80 bytes: the menu's tune (MENU, through PLAY_TUNE_ONCE),
; played the first time the menu is shown after a game, until a key is pressed.
; Seventy-nine notes and its $FF, 79 units, about twelve seconds; notes 23 to
; 47.
TUNE_GAME_OVER_END:
  DEFB $FF                             ; The game-over tune's $FF; the arrival
TUNE_ARRIVAL:
  DEFB $1B,$1D,$1E,$1B,$1D,$1E,$20,$1D ; tune and its $FF; the menu tune and
  DEFB $1E,$20,$22,$1E,$1D,$1E,$20,$1D ; its $FF
  DEFB $1B,$1D,$1E,$1B,$1A,$1B,$1D,$1A ;
  DEFB $9B,$FF                         ;
TUNE_MENU:
  DEFB $19,$25,$19,$25,$19,$19,$25,$19 ;
  DEFB $25,$19,$19,$25,$19,$25,$19,$1B ;
  DEFB $1C,$28,$1C,$28,$1C,$28,$1C,$28 ;
  DEFB $1B,$27,$1B,$27,$17,$23,$17,$23 ;
  DEFB $19,$25,$19,$25,$19,$19,$25,$19 ;
  DEFB $25,$19,$19,$25,$19,$25,$19,$1B ;
  DEFB $1C,$2F,$1C,$2F,$1C,$2F,$1C,$2F ;
  DEFB $1B,$2A,$1B,$2A,$17,$2A,$17,$2A ;
  DEFB $19,$2C,$19,$2C,$19,$19,$2C,$19 ;
  DEFB $2C,$19,$19,$2C,$19,$2C,$19,$FF ;

; Play the menu's tune, once, until a key is pressed
;
; Used by the routine at MENU.
;
; The menu (MENU) calls this every time round its loop with the tune at DE.
; TUNE_HEARD remembers that it has been played, so it plays only the first
; time; AFTER_GAME clears the variable with the rest after every game, so it
; plays again then. Before each note the whole keyboard is read, and any key
; stops the tune at once.
;
; GAME_ENDED comes in at PLAY_TUNE_TILL_KEY for the game-over tune, which plays
; after every game, until a key. The same routine as Pentagram's
; PLAY_TUNE_ONCE.
;
; DE the tune
PLAY_TUNE_ONCE:
  LD HL,TUNE_HEARD        ; played already: done
  LD A,(HL)               ;
  AND A                   ;
  RET NZ                  ;
  SET 0,(HL)              ; not again
; This entry point is used by the routine at GAME_ENDED.
PLAY_TUNE_TILL_KEY:
  XOR A                   ; A = 0 reads every half-row at once: any key stops
  CALL READ_KEYS          ; it
  JR Z,PLAY_TUNE_ONCE_0   ;
  RET                     ;
PLAY_TUNE_ONCE_0:
  LD A,(DE)               ; $FF ends the tune; play a note, and look at the
  CP $FF                  ; keys again
  JR Z,PLAY_TUNE_0        ;
  CALL PLAY_NOTE          ;
  JR PLAY_TUNE_TILL_KEY   ;

; Play the tune at DE
;
; Used by the routines at AFTER_GAME, OILED_ROBOT and ARRIVAL_SCREEN.
;
; Plays the whole tune and returns; nothing else happens meanwhile, since the
; sound is made by timing loops. Used for the start tune (AFTER_GAME), the
; winning tune (OILED_ROBOT) and the arrival tune (ARRIVAL_SCREEN). Knight
; Lore's play_audio; Pentagram's PLAY_TUNE.
;
; DE the tune
PLAY_TUNE:
  LD A,(DE)               ; $FF ends it; play the note, and the next
  CP $FF                  ;
  JR Z,PLAY_TUNE_0        ;
  CALL PLAY_NOTE          ;
  JR PLAY_TUNE            ;
; This entry point is used by the routine at PLAY_TUNE_ONCE.
PLAY_TUNE_0:
  RET                     ; DE is left pointing at the $FF

; Play one note
;
; Used by the routines at PLAY_TUNE_ONCE and PLAY_TUNE.
;
; A note byte's low six bits index NOTES, with 0 a rest; its top two bits are
; its length less one, one to four units. A note's three bytes are two loop
; counts that time each half of a wave and how many waves make one unit, and
; the wave count rises with the pitch, which keeps every unit close to 0.155
; seconds whatever the note. The speaker is driven directly, off for one
; half-wave and on for the other, with the border black.
;
; The routine and NOTES are byte for byte Knight Lore's play_note and its
; table, and Pentagram's PLAY_NOTE.
;
; A the note byte
; DE the address of the note byte; on exit, the next one
PLAY_NOTE:
  AND $3F                 ; index 0 is a rest
  JR Z,PLAY_NOTE_5        ;
  LD L,A                  ; HL = NOTES + 3 * index
  LD H,$00                ;
  ADD HL,HL               ;
  CALL ADD_HL_A           ;
  LD BC,NOTES             ;
  ADD HL,BC               ;
  LD B,(HL)               ; B and C time the half-wave; HL = the number of
  INC HL                  ; waves in one unit
  LD C,(HL)               ;
  INC HL                  ;
  LD L,(HL)               ;
  LD H,$00                ;
  LD A,(DE)               ; the top two bits: the length, one to four units
  RLCA                    ;
  RLCA                    ;
  AND $03                 ;
  INC A                   ;
  PUSH DE                 ; HL = the waves in one unit times the length
  LD E,L                  ;
  LD D,H                  ;
PLAY_NOTE_0:
  DEC A                   ;
  JR Z,PLAY_NOTE_1        ;
  ADD HL,DE               ;
  JR PLAY_NOTE_0          ;
PLAY_NOTE_1:
  POP DE                  ;
PLAY_NOTE_2:
  PUSH BC                 ; speaker off, border black; wait
  XOR A                   ;
  OUT ($FE),A             ;
PLAY_NOTE_3:
  DJNZ PLAY_NOTE_3        ;
  DEC C                   ;
  JR NZ,PLAY_NOTE_3       ;
  POP BC                  ;
  PUSH BC                 ; speaker on; wait
  LD A,$10                ;
  OUT ($FE),A             ;
PLAY_NOTE_4:
  DJNZ PLAY_NOTE_4        ;
  DEC C                   ;
  JR NZ,PLAY_NOTE_4       ;
  POP BC                  ;
  DEC HL                  ; until all the waves are done
  LD A,H                  ;
  OR L                    ;
  JR NZ,PLAY_NOTE_2       ;
  INC DE                  ; on to the next note byte
  RET                     ;
PLAY_NOTE_5:
  LD A,(DE)               ; a rest: one to four units...
  INC DE                  ;
  RLCA                    ;
  RLCA                    ;
  AND $03                 ;
  INC A                   ;
  LD L,A                  ; ...each 17163 turns of a 26 T-state loop, about
  LD BC,$430B             ; 0.127 seconds (no tune has a rest, and the sessions
PLAY_NOTE_6:
  PUSH BC                 ; never played one)
PLAY_NOTE_7:
  DEC BC                  ;
  LD A,B                  ;
  OR C                    ;
  JR NZ,PLAY_NOTE_7       ;
  POP BC                  ;
  DEC L                   ;
  JR NZ,PLAY_NOTE_6       ;
  RET                     ;

; The notes: 61 of three bytes
;
; Indexed by the low six bits of a note byte (PLAY_NOTE): the first two bytes
; are the B and C counts that time each half-wave, the third how many waves
; make one unit of length. Row 0 stands for a rest and is never read.
;
; The same 183 bytes as Knight Lore's and Pentagram's note tables (compared
; byte for byte), and so the same scale: a semitone a row for five octaves,
; about G#1 at row 1 and A4 (440Hz) at row 38 by Pentagram's working, with row
; 18 a copy of row 17's pitch where C#3 should be. The tunes here use rows 23
; to 47 only.
NOTES:
  DEFB $00,$00,$00        ; Rows 0 to 60
  DEFB $F4,$0A,$08        ;
  DEFB $65,$0A,$09        ;
  DEFB $DE,$09,$09        ;
  DEFB $5E,$09,$0A        ;
  DEFB $E7,$08,$0A        ;
  DEFB $75,$08,$0B        ;
  DEFB $0A,$08,$0C        ;
  DEFB $A5,$07,$0C        ;
  DEFB $45,$07,$0D        ;
  DEFB $EB,$06,$0E        ;
  DEFB $96,$06,$0F        ;
  DEFB $46,$06,$0F        ;
  DEFB $FA,$05,$10        ;
  DEFB $B3,$05,$11        ;
  DEFB $6F,$05,$12        ;
  DEFB $2F,$05,$13        ;
  DEFB $F3,$04,$15        ;
  DEFB $F3,$04,$16        ;
  DEFB $85,$04,$17        ;
  DEFB $52,$04,$19        ;
  DEFB $23,$04,$1A        ;
  DEFB $F6,$03,$1C        ;
  DEFB $CB,$03,$1D        ;
  DEFB $A3,$03,$1F        ;
  DEFB $7D,$03,$21        ;
  DEFB $59,$03,$23        ;
  DEFB $38,$03,$25        ;
  DEFB $18,$03,$27        ;
  DEFB $FA,$02,$29        ;
  DEFB $DD,$02,$2C        ;
  DEFB $C2,$02,$2E        ;
  DEFB $A9,$02,$31        ;
  DEFB $91,$02,$34        ;
  DEFB $7B,$02,$37        ;
  DEFB $66,$02,$3A        ;
  DEFB $51,$02,$3E        ;
  DEFB $3F,$02,$41        ;
  DEFB $2D,$02,$45        ;
  DEFB $1C,$02,$49        ;
  DEFB $0C,$02,$4E        ;
  DEFB $FD,$01,$52        ;
  DEFB $EF,$01,$57        ;
  DEFB $E2,$01,$5D        ;
  DEFB $D5,$01,$62        ;
  DEFB $C9,$01,$68        ;
  DEFB $BD,$01,$6E        ;
  DEFB $B3,$01,$75        ;
  DEFB $A9,$01,$7B        ;
  DEFB $9F,$01,$83        ;
  DEFB $96,$01,$8B        ;
  DEFB $8E,$01,$93        ;
  DEFB $86,$01,$9C        ;
  DEFB $7E,$01,$A5        ;
  DEFB $77,$01,$AF        ;
  DEFB $71,$01,$B9        ;
  DEFB $6A,$01,$C4        ;
  DEFB $64,$01,$D0        ;
  DEFB $5F,$01,$DC        ;
  DEFB $59,$01,$E9        ;
  DEFB $54,$01,$F7        ;
  DEFB $3A,$02,$5B,$E6,$07,$6F,$26,$00
  DEFB $01,$E6,$B5,$09,$46,$0E,$04,$C3
  DEFB $FB,$B6,$A0,$B0,$C0,$90,$A0,$E0
  DEFB $80,$60
; The last 26 bytes are not notes. The first 18 are code that nothing reaches
; -- no instruction or table holds an address in it, and no session ran it: LD
; A,(TURNS); AND 7; LD L,A; LD H,0; LD BC, the address of the eight bytes after
; it; ADD HL,BC; LD B,(HL); LD C,4; JP to BEEP (in FOOTSTEP) -- four waves at a
; pitch from those eight bytes, chosen by the low three bits of the turn
; counter. The last eight are that table of half-wave counts. It is Knight
; Lore's blip for its moveable block, byte for byte apart from its three
; addresses (the turn counter, the table and BEEP), with the same eight pitches
; -- compared against Knight Lore's loaded snapshot; stage 2 had searched and
; missed it because the addresses differ.

; The sparkle's sound
;
; Used by the routines at LOOSE_VALVE and SPARKLE_STEP.
;
; Short blips at pitches read from the ROM, from $1234 on: two waves each, and
; as many blips as the complement of the graphic's low five bits, so a
; sparkle's sound shortens as its frames go by -- 15 at graphic 48, 9 at 54, 31
; at 64. Used by START_SPARKLE and SPARKLE_STEP, and by LOOSE_VALVE as a
; chamber is activated. As Knight Lore's sound_sparkle.
;
; IX the object
SPARKLE_SOUND:
  LD A,(IX+$00)           ; E = the complement of the graphic's low five bits
  CPL                     ;
  AND $1F                 ;
  LD E,A                  ;
  LD HL,$1234             ; the pitches: ROM bytes from $1234
SPARKLE_SOUND_0:
  LD A,(HL)               ; two waves at each, E times
  INC HL                  ;
  LD B,A                  ;
  LD C,$02                ;
  CALL BEEP               ;
  DEC E                   ;
  JR NZ,SPARKLE_SOUND_0   ;
  RET                     ;

; The sound of the robot materialising
;
; Used by the routine at PLAYER_APPEARING.
;
; A rising sweep, one wave a step, for graphics 56 to 62 (PLAYER_APPEARING),
; the sparkle run backwards as a life starts. It starts from four times the
; graphic's low three bits, plus 3 -- 3 at graphic 56, 27 at 62 -- and steps
; down to 1, the half-wave count four times the step: higher as it goes. As
; Knight Lore's sound_materialise.
;
; IX the object
MATERIALISE_SOUND:
  LD A,(IX+$00)           ; C = 4 * (graphic AND 7) + 3 (the rotation brings
  RLCA                    ; bits 6-7 in as bits 0-1, but they are 0 here)
  RLCA                    ;
  AND $1F                 ;
  OR $03                  ;
  LD C,A                  ;
MATERIALISE_SOUND_0:
  LD A,C                  ; one wave at a half-wave count of 4 * C
  RLCA                    ;
  RLCA                    ;
  LD B,A                  ;
  CALL CLICK              ;
  DEC C                     ; until C runs out
  JR NZ,MATERIALISE_SOUND_0 ;
  RET                       ;

; The sound of a thud
;
; Used by the routines at SCENE_TOOL, WANDERER and PACER.
;
; Four blips of three waves at pitches read from the start of the ROM, made low
; by setting their top two bits. Used as the creatures turn (WANDERER, PACER)
; and by SCENE_TOOL. As Knight Lore's sound_thud.
THUD_SOUND:
  LD HL,$0000             ; four, from the ROM's first bytes
  LD E,$04                ;
THUD_SOUND_0:
  LD C,$03                ; three waves at the next ROM byte OR $C0
  LD A,(HL)               ;
  INC HL                  ;
  OR $C0                  ;
  LD B,A                  ;
  CALL BEEP
  DEC E                   ; until E runs out
  JR NZ,THUD_SOUND_0      ;
  RET                     ;

; The sound of a jump
;
; Used by the routine at HANDLE_JUMP.
;
; A rising sweep of 32 single waves: five right rotations are three left ones,
; so the half-wave count is 8 times the step, which falls from 32 to 1 (the
; first, 256, wraps round to 1). Used by HANDLE_JUMP. As Knight Lore's
; sound_jump.
JUMP_SOUND:
  LD C,$20                ; half-wave count 8 * C
JUMP_SOUND_0:
  LD A,C                  ;
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  LD B,A                  ;
  CALL CLICK              ; one wave
  DEC C                   ; until C runs out
  JR NZ,JUMP_SOUND_0      ;
  RET                     ;

; A note pitched by an object's Z
;
; Used by the routines at LEAPER, REMOTE_ROBOT, CEILING_DROP, WANDERER,
; DROPPING_BLOCK, LIFT and MOVE_PLAYER.
;
; Six waves at a half-wave count of the complement of 64 more than Z, rotated
; left twice (so the top two bits wrap round): the higher the object, the
; higher the note. The entry at BEEP_BY_A takes the value in A; BEEP_BY_U,
; BEEP_BY_V and BEEP_BY_UVZ use it for U, V and all three. Knight Lore's
; sound_pitch_from_z and sound_pitch_from_a.
;
; IX the object
BEEP_BY_Z:
  LD A,(IX+$03)           ; Z
; This entry point is used by the routines at OILED_ROBOT, BEEP_BY_U, BEEP_BY_V
; and BEEP_BY_UVZ.
BEEP_BY_A:
  ADD A,$40               ; B = the half-wave count
  CPL                     ;
  RLCA                    ;
  RLCA                    ;
  LD B,A                  ;
  LD C,$06                ; six waves
  JP BEEP                 ;

; A note pitched by an object's U
;
; Used by the routine at SHUTTLE_U.
;
; IX the object
BEEP_BY_U:
  LD A,(IX+$01)           ; U, then as BEEP_BY_Z
  JR BEEP_BY_A            ;

; A note pitched by an object's V
;
; Used by the routine at SHUTTLE_V.
;
; IX the object
BEEP_BY_V:
  LD A,(IX+$02)           ; V, then as BEEP_BY_Z
  JR BEEP_BY_A            ;

; A note pitched by an object's position
;
; Used by the routine at SPARKLE_END_PLACE.
;
; The pitch follows the sum of U, V and Z, so it changes whichever way the
; object moves. Knight Lore's sound_pitch_from_xyz.
;
; IX the object
BEEP_BY_UVZ:
  LD A,(IX+$01)           ; U + V + Z, then as BEEP_BY_Z
  ADD A,(IX+$02)          ;
  ADD A,(IX+$03)          ;
  JR BEEP_BY_A            ;

; Unused: Knight Lore's werewolf sound
;
; Code nothing reaches: no instruction or table holds its address, and no
; session ran it. sna2ctl left it as data; it decodes cleanly to its RET. It is
; Knight Lore's sound_transform byte for byte (found by searching Knight Lore's
; snapshot for these bytes): a warble of 16 to 40 single waves, the number set
; by the low two bits of the graphic -- the four frames of Sabreman changing
; into the werewolf and back -- each at a half-wave count of the step XOR $55,
; plus the step. Alien 8 kept the routine and dropped its only caller.
;
; IX the object
TRANSFORM_SOUND:
  LD A,(IX+$00)           ; C = 16, 24, 32 or 40 by the graphic's bits 0-1; one
  RLCA                    ; wave at (C XOR $55) + C for each C down to 1
  RLCA                    ;
  RLCA                    ;
  AND $18                 ;
  ADD A,$10               ;
  LD C,A                  ;
TRANSFORM_SOUND_0:
  LD A,C                  ;
  XOR $55                 ;
  ADD A,C                 ;
  LD B,A                  ;
  CALL CLICK              ;
  DEC C                   ;
  JR NZ,TRANSFORM_SOUND_0 ;
  RET                     ;

; The sound of a crash
;
; Used by the routines at SCENE_TOOL and THUD_ON_LANDING.
;
; Sixteen blips of two waves at pitches read from the first 8K of the ROM, less
; their top bits: the address is the random number in the low byte and the turn
; counter's low five bits in the high one, so it differs every time. Used by
; SCENE_TOOL and THUD_ON_LANDING. As Knight Lore's crash sound.
CRASH_SOUND:
  LD A,(RANDOM)           ; HL = an address in the ROM; sixteen
  LD L,A                  ;
  LD A,(TURNS)            ;
  AND $1F                 ;
  LD H,A                  ;
  LD E,$10                ;
CRASH_SOUND_0:
  LD A,(HL)               ; two waves at each ROM byte, less its top bit
  INC HL                  ;
  AND $7F                 ;
  LD B,A                  ;
  LD C,$02                ;
  CALL BEEP               ;
  DEC E                   ;
  JR NZ,CRASH_SOUND_0     ;
  RET                     ;

; A warble for the remote-controlled robots
;
; Used by the routines at REMOTE_ROBOT and SLOW_CHASER.
;
; A few single waves, their pitch scrambled from the turn counter and the step
; count with an XOR. How many is read from a table at HL, indexed by the turn
; counter's low two bits: REMOTE_ROBOT passes WARBLE_COUNTS, SLOW_CHASER the
; fifth byte of it, so the two run through different parts of the same rise and
; fall.
;
; HL the table of wave counts (WARBLE_COUNTS, or four bytes into it)
WARBLE_SOUND:
  LD A,(TURNS)            ; C = the table's entry for the turn counter's low
  AND $03                 ; two bits
  CALL ADD_HL_A           ;
  LD C,(HL)               ;
WARBLE_SOUND_0:
  LD A,(TURNS)            ; one wave at half-wave count 64 + ((turns XOR C) AND
  XOR C                   ; 31)
  AND $1F                 ;
  OR $40                  ;
  LD B,A                  ;
  CALL CLICK              ;
  DEC C                   ; until C runs out
  JR NZ,WARBLE_SOUND_0    ;
  RET                     ;

; How many waves each warble has
;
; Read four at a time by WARBLE_SOUND, from the start or from the fifth byte.
WARBLE_COUNTS:
  DEFB $08,$0C,$10,$14,$18,$14,$10,$0C ; Wave counts, rising and falling

; A plain beep: 16 waves at half-wave count 128
;
; Used by the routines at SCENE_SPARKS, MENU, TAKE_OR_LEAVE and EXTRA_LIFE.
;
; Used as the control method changes on the menu (MENU), as a thing is picked
; up or put down (TAKE_OR_LEAVE), for an extra life (EXTRA_LIFE) and by
; SCENE_SPARKS.
PLAIN_BEEP:
  LD BC,$8010             ; 16 waves at 128
  JR BEEP                 ;

; A beep: 24 waves at half-wave count 80
;
; Used by the routine at HANDLE_PAUSE.
;
; The pause's beep (HANDLE_PAUSE). Knight Lore's pause beep is the same.
PAUSE_BEEP:
  LD BC,$5018             ; 24 waves at 80
  JR BEEP                 ;

; A beep: 32 waves at half-wave count 48
;
; Used by the routines at CLOCKWORK_MOUSE and CONVEYOR_PLUS_V.
;
; As something lands on a conveyor (CONVEYOR_PLUS_V), and for CLOCKWORK_MOUSE.
HIGH_BEEP:
  LD BC,$3020             ; 32 waves at 48
  JR BEEP                 ;

; A footstep for a creature's lower half
;
; Used by the routine at LOWER_HALF.
;
; Called by LOWER_HALF with its own record, whose graphic is always 11: odd, so
; the RET at the top is always taken and the footstep never sounds (the
; sessions never ran the rest). What it would play is FOOTSTEP's footstep at a
; fixed pitch of 128 on alternate pairs of turns, the complement of the turn
; counter where the robot's uses the counter itself. Knight Lore's
; audio_guard_wizard, where the walkers' graphics change.
;
; IX the object
LOWER_HALF_STEP:
  LD A,(IX+$00)           ; only on an even graphic: never
  AND $01                 ;
  RET NZ                  ;
  LD B,$80                ; a pitch of 128, and the turn counter inverted
  LD A,(TURNS)            ;
  CPL                     ;
  JR FOOTSTEP_PITCH       ;

; The robot's footstep
;
; Used by the routine at HANDLE_FORWARD.
;
; For the legs (HANDLE_FORWARD), on every other frame of the walk: those with
; bit 0 of the graphic clear. FOOTSTEP_NOW skips that test (TURNING_LEGS). The
; pitch alternates by bit 1 of the turn counter between a fixed half-wave count
; of 96 and one from the height, the tick-tock of two feet; the number of waves
; is (U/2 + (256-V)/2)/16, which comes out longer towards plus U and shorter
; towards plus V. Knight Lore's sound_footstep.
;
; BEEP, its end, is the common tail of the sound effects: C waves at a
; half-wave count of B. A C of 0 would mean 256 waves.
;
; IX the legs
FOOTSTEP:
  LD A,(IX+$00)           ; only on even walking frames
  AND $01                 ;
  RET NZ                  ;
; This entry point is used by the routine at TURNING_LEGS.
FOOTSTEP_NOW:
  LD B,$60                ; a pitch of 96, and the turn counter
  LD A,(TURNS)            ;
; This entry point is used by the routine at LOWER_HALF_STEP.
FOOTSTEP_PITCH:
  BIT 1,A                 ; on alternate pairs of turns, a pitch from the
  JR Z,FOOTSTEP_0         ; height instead
  LD A,(IX+$03)           ;
  ADD A,$40               ;
  CPL                     ;
  SRL A                   ;
  LD B,A                  ;
FOOTSTEP_0:
  LD A,(IX+$01)           ; C = the number of waves, from U and V
  SRL A                   ;
  LD C,A                  ;
  LD A,(IX+$02)           ;
  NEG                     ;
  SRL A                   ;
  ADD A,C                 ;
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  AND $0F                 ;
  LD C,A                  ;
; This entry point is used by the routines at SPARKLE_SOUND, THUD_SOUND,
; BEEP_BY_Z, CRASH_SOUND, PLAIN_BEEP, PAUSE_BEEP and HIGH_BEEP.
BEEP:
  CALL CLICK              ; C waves of half-wave count B
  DEC C                   ;
  JR NZ,BEEP              ;
  RET                     ;

; One wave
;
; Used by the routines at MATERIALISE_SOUND, JUMP_SOUND, TRANSFORM_SOUND,
; WARBLE_SOUND and FOOTSTEP.
;
; Speaker bit on for B turns of a 13 T-state loop, then off for as long, with
; the border black throughout; B is kept. Knight Lore's routine, and
; Pentagram's CLICK.
;
; B the half-wave count, kept
CLICK:
  LD A,$10                ; speaker on; wait
  OUT ($FE),A             ;
  LD A,B                  ;
CLICK_0:
  DJNZ CLICK_0            ;
  LD B,A                  ;
  XOR A                   ; speaker off; wait; B back
  OUT ($FE),A             ;
  LD A,B                  ;
CLICK_1:
  DJNZ CLICK_1            ;
  LD B,A                  ;
  RET                     ;

; Does this object overlap any other?
;
; Used by the routine at TAKE_OR_LEAVE.
;
; Tests IX against all 56 records with the tests on each axis at
; DO_OBJS_INTERSECT_ON_U, DO_OBJS_INTERSECT_ON_V and DO_OBJS_INTERSECT_ON_Z,
; with no offset on any axis. Empty records are skipped, and so is any with bit
; 1 of its flags set (IS_OBJECT_NOT_IGNORED) -- which is how IX avoids finding
; itself: it sets its own bit 1 for the duration. Used by TAKE_OR_LEAVE, to see
; whether what he puts down has room. Knight Lore's do_any_objs_intersect and
; Pentagram's DO_ANY_OBJS_INTERSECT.
;
;   IX the object
; O:F carry set if another object's box overlaps IX's where it stands
; O:IY the one it overlaps, when carry is set
DO_ANY_OBJS_INTERSECT:
  PUSH BC                 ; save the registers; IY walks all 56 records
  PUSH DE                 ;
  PUSH HL                 ;
  PUSH IY                 ;
  LD IY,OBJECTS           ;
  LD B,$38                ;
  LD C,$00                ; no offset on U, V or Z; and IX out of its own way
  LD L,C                  ;
  LD H,C                  ;
  SET 1,(IX+$07)          ;
DO_ANY_OBJS_INTERSECT_0:
  CALL IS_OBJECT_NOT_IGNORED   ; empty, or out of collisions: next
  JR Z,DO_ANY_OBJS_INTERSECT_2 ;
  CALL DO_OBJS_INTERSECT_ON_U   ; overlapping in U, V and Z: found, with carry
  JR NC,DO_ANY_OBJS_INTERSECT_2 ; set
  CALL DO_OBJS_INTERSECT_ON_V   ;
  JR NC,DO_ANY_OBJS_INTERSECT_2 ;
  CALL DO_OBJS_INTERSECT_ON_Z   ;
  JR NC,DO_ANY_OBJS_INTERSECT_2 ;
DO_ANY_OBJS_INTERSECT_1:
  POP IY                  ; put the registers back and IX's bit 1 clear; the
  POP HL                  ; carry is kept
  POP DE                  ;
  POP BC                  ;
  RES 1,(IX+$07)          ;
  RET                     ;
DO_ANY_OBJS_INTERSECT_2:
  LD DE,$0020                  ; next record; none: clear carry
  ADD IY,DE                    ;
  DJNZ DO_ANY_OBJS_INTERSECT_0 ;
  AND A                        ;
  JR DO_ANY_OBJS_INTERSECT_1   ;
; The exit clears IX's bit 1 whatever it was before.

; Does this object take part in collisions?
;
; Used by the routines at DO_ANY_OBJS_INTERSECT, ADJ_DU_FOR_OBJ_INTERSECT,
; ADJ_DV_FOR_OBJ_INTERSECT and ADJ_DZ_FOR_OBJ_INTERSECT.
;
; Z set for an empty record, or one with bit 1 of its flags set: the object
; moving now (ADJ_FOR_OUT_OF_BOUNDS sets it on itself), a lower half while its
; upper half moves (JOIN_HALVES), or one marked to be passed over, like a
; sparkle. Knight Lore's is_object_not_ignored.
;
;   IY the object
; O:F Z set if it is to be skipped
IS_OBJECT_NOT_IGNORED:
  LD A,(IY+$00)           ; an empty record
  AND A                   ;
  RET Z                   ;
  LD A,(IY+$07)           ; bit 1 of the flags
  CPL                     ;
  AND $02                 ;
  RET                     ;

; Read a half-row of the keyboard
;
; Used by the routines at SCENE_TOOL, PLAY_TUNE_ONCE, GAME_ENDED,
; WAIT_KEY_OR_TIME, MENU, READ_CONTROLS and HANDLE_PAUSE.
;
; Knight Lore's routine, byte for byte. The IN does the selecting on its own:
; IN A,($FE) puts A on the top half of the address bus, so each 0 bit in A
; selects a half-row, and A = 0 reads all eight at once. The CPL turns the
; keys' active-low bits the right way up.
;
; The OUT before it is not needed for the read. It writes A to port A*256+$FD,
; which nothing on a 48K Spectrum answers; a 128K machine's paging port would
; decode it whenever A has bit 7 clear (see Pentagram's READ_KEYS, where that
; was tried). Not tried with Alien 8.
;
;   A the half-rows to read, as the port's high byte
; O:A the keys pressed, bits 0-4, a set bit for a key down
; O:F Z set if none is
READ_KEYS:
  OUT ($FD),A             ; not what selects the row: see above
  IN A,($FE)              ; reads port A*256+$FE
  CPL                     ; set bits now mean pressed keys; keep the five
  AND $1F                 ;
  RET                     ;

; The game is over
;
; Used by the routines at RUN_CLOCK, LOOSE_VALVE and NEW_LIFE.
;
; Jumped to when the last life is lost (NEW_LIFE), when the clock runs out
; (RUN_CLOCK), and when the twenty-fourth chamber is activated (LOOSE_VALVE).
; The valves in the room are put back in their places first
; (UPDATE_SPECIAL_OBJS). A won game shows the arrival screen (ARRIVAL_SCREEN)
; first, which comes back to SUMMARY_SCREEN.
;
; The summary: the buffer cleared, the screen blanked with bright red
; attributes, and seven lines from the text list at SUMMARY_COLOURS -- the
; heading, the activated and unactivated chambers, the crew lost, and the
; overall rating -- then the rating, one of eight from the table after it,
; printed at x 88, line 39 of the buffer; then the counts are worked out
; (SUMMARISE_CHAMBERS) and printed (PRINT_SUMMARY_COUNTS), the border drawn and
; the whole shown. The game-over tune plays until a key is pressed (after any
; key held is let go), and then the summary stays up for about fourteen seconds
; more or until another key.
;
; The rating: bit 0 of WON picks the better four of the eight, and bits 5 and 6
; of the number of rooms seen less one (COUNT_ROOMS_SEEN) one of those four --
; so it goes up a step for every 32 rooms seen, and a player who wins is rated
; above any who does not. As Knight Lore's game_over_summary.
;
; Then the scene: GAME_OVER is set, the buffer and the object records are
; cleared, the attributes made bright red, and the scene's objects put in the
; records (SET_UP_SCENE) -- the re-programming of the robot (SCENE_LOST) after
; a lost game, with the flashing text RE-PROGRAMMING (REPROGRAMMING) at x 72,
; line 159; the robot and an oil can (the list at SCENE_WON in SCENE_LOST_END)
; after a won one. NEW_ROOM is set and the main loop takes over: the scene's
; update routines run it, and one of them returns to the menu (AFTER_GAME).
;
; O:SP the main loop resets it
GAME_ENDED:
  CALL UPDATE_SPECIAL_OBJS ; the valves in the room back in their places
  LD A,(WON)              ; won: the arrival screen first
  AND A                   ;
  JP NZ,ARRIVAL_SCREEN    ;
; This entry point is used by the routine at ARRIVAL_SCREEN.
SUMMARY_SCREEN:
  CALL CLEAR_SCRN_BUFFER  ; clear the buffer; the border black, the attributes
  CALL CLEAR_SCRN         ; bright red, the screen blank
  LD DE,SUMMARY_COLOURS   ; colours from SUMMARY_COLOURS, then positions and
  EXX                     ; strings from the two tables after it: seven lines.
  LD HL,SUMMARY_XY        ; The screen was shown once this game already, so the
  LD DE,SUMMARY_TEXT      ; list only draws into the buffer
  LD B,$07                ;
  CALL DISPLAY_TEXT_LIST  ;
  CALL COUNT_ROOMS_SEEN   ; the rooms seen less one: bits 5 and 6, as bits 6
  RLCA                    ; and 7
  AND $C0                 ;
  LD C,A                  ;
  LD A,(WON)              ; with WON as bit 0
  AND $01                 ;
  OR C                    ;
  RLCA                    ; rotated into a word offset: WON * 8 + the rooms'
  RLCA                    ; bits * 2
  RLCA                    ;
  AND $0E                 ;
  LD L,A                  ;
  LD H,$00                ;
  LD BC,RATINGS           ; DE = the rating's text, from the table of ratings
  ADD HL,BC               ; in SUMMARY_RATING_LAST
  LD E,(HL)               ;
  INC HL                  ;
  LD D,(HL)               ;
  LD HL,$2758             ; print it at x 88, line 39; its first byte is its
  CALL PRINT_TEXT         ; colour
  CALL SUMMARISE_CHAMBERS   ; work out the summary's counts, and print them
  CALL PRINT_SUMMARY_COUNTS ; into the buffer
  CALL PRINT_BORDER       ; the border; show it all
  CALL SHOW_BUFFER        ;
GAME_ENDED_0:
  XOR A                   ; wait until no key is held
  CALL READ_KEYS          ;
  JR NZ,GAME_ENDED_0      ;
  LD DE,TUNE_GAME_OVER    ; the game-over tune, until a key
  CALL PLAY_TUNE_TILL_KEY ;
  LD B,$08                ; then about 14 seconds more, or until a key
  CALL WAIT_KEY_OR_TIME   ;
  LD A,$01                ; the scene after a game is on
  LD (GAME_OVER),A        ;
  CALL CLEAR_SCRN_BUFFER  ; clear the buffer; the border; show it
  CALL PRINT_BORDER       ;
  CALL SHOW_BUFFER        ;
  CALL CLEAR_OBJECTS      ; clear the object records
  CALL CLR_ATTRIBUTE_MEMORY ; the attributes bright red
  LD A,(WON)              ; won?
  AND A                   ;
  JR NZ,GAME_ENDED_2      ;
  LD HL,$9F48             ; lost: RE-PROGRAMMING at x 72, line 159
  LD DE,REPROGRAMMING     ;
  CALL PRINT_TEXT         ;
  LD DE,SCENE_LOST        ; the lost game's scene
GAME_ENDED_1:
  CALL SET_UP_SCENE       ; its objects into the records
  LD A,$01                ; a new room: the main loop redraws it all, and runs
  LD (NEW_ROOM),A         ; the scene
  JP MAIN_NEXT_TURN       ;
GAME_ENDED_2:
  LD DE,SCENE_WON         ; won: the won game's scene
  JR GAME_ENDED_1         ;

; The text shown over the scene after a lost game
;
; A string in the printer's form (PRINT_TEXT): a colour byte, then the
; characters, the last with bit 7 set. The colour is flashing bright yellow on
; black. The less-than sign is the font's dash, so the text reads
; RE-PROGRAMMING.
REPROGRAMMING:
  DEFB $C6                ; Flashing, bright, yellow ink

; The re-programming text
REPROGRAMMING_TEXT:
  DEFM "RE<PROGRAMMIN"

; The re-programming text's last character
REPROGRAMMING_END:
  DEFB $C7                ; G, with bit 7 set

; Put the scene's objects in the object records
;
; Used by the routine at GAME_ENDED.
;
; From the first record on, one record for each five-byte entry of the list at
; DE until a zero: the graphic to +0, the flags to +7, the colour to +10, and
; the place on the screen to +1A and +1B, x and line of the buffer. The scene's
; update routines draw from there and colour what they draw with +10 (the
; second entry of SCENE_SPARKS). The records were cleared before
; (CLEAR_OBJECTS).
;
; DE the list: SCENE_LOST after a lost game, or the one at SCENE_WON after a
;    won one (SCENE_LOST_END)
SET_UP_SCENE:
  LD IY,OBJECTS           ; IY at the first record
  LD BC,$0020             ;
SET_UP_SCENE_0:
  LD A,(DE)               ; zero ends the list
  INC DE                  ;
  AND A                   ;
  RET Z                   ;
  LD (IY+$00),A           ; graphic, flags, colour, x, line
  LD A,(DE)               ;
  INC DE                  ;
  LD (IY+$07),A           ;
  LD A,(DE)               ;
  INC DE                  ;
  LD (IY+$10),A           ;
  LD A,(DE)               ;
  INC DE                  ;
  LD (IY+$1A),A           ;
  LD A,(DE)               ;
  INC DE                  ;
  LD (IY+$1B),A           ;
  ADD IY,BC               ; the next record
  JR SET_UP_SCENE_0       ;

; The objects of the scene after a lost game
;
; Eight entries of five bytes -- graphic, flags, colour, x, line -- ended by a
; zero, read by SET_UP_SCENE. The list runs through the next eight entries to
; the zero at the start of SCENE_LOST_END (sna2ctl took some of its bytes for
; text). In order: graphic 81 in bright red at x 184, line 80; 83, bright
; white, 32, 80; 82, bright green, 120, 124; 88, bright cyan, 104, 64; 89,
; bright cyan, 128, 64; 90 and 91, drawn with the robot's own sprites (those of
; graphics 25 and 41), bright cyan, at 112, lines 69 and 85; and 80, bright
; yellow, 116, 104. Their update routines are SCENE_TOOL (81 to 83),
; SCENE_SPARKS (80), and the second entry of SCENE_SPARKS (88 to 91); every
; flags byte is $10.
SCENE_LOST:
  DEFB $51,$10,$42,$B8,$50 ; Graphic 81; and the start of graphic 83's entry
  DEFB $53,$10             ;

; The scene after a lost game, continued
SCENE_LOST_B:
  DEFB $47,$20,$50        ; The rest of graphic 83's entry; graphic 82's first
  DEFB $52                ; byte

; The scene after a lost game, continued
SCENE_LOST_C:
  DEFB $10,$44,$78,$7C     ; Graphic 82's entry, 88's, 89's, and the start of
  DEFB $58,$10,$45,$68,$40 ; 90's
  DEFB $59,$10,$45,$80,$40 ;
  DEFB $5A,$10             ;

; The scene after a lost game, continued
SCENE_LOST_D:
  DEFB $45,$70,$45        ; The rest of graphic 90's entry; graphic 91's first
  DEFB $5B                ; byte

; The scene after a lost game, continued
SCENE_LOST_E:
  DEFB $10                ; Graphic 91's flags

; The scene after a lost game, continued
SCENE_LOST_F:
  DEFB $45,$70,$55        ; The rest of graphic 91's entry; graphic 80's first
  DEFB $50                ; byte

; The scene after a lost game, continued
SCENE_LOST_G:
  DEFB $10                ; Graphic 80's flags

; The scene after a lost game, continued
SCENE_LOST_H:
  DEFB $46,$74,$68        ; Graphic 80's colour, x and line

; The end of the lost game's scene; the scene after a won game
;
; The zero that ends SCENE_LOST, and then SCENE_WON, the list SET_UP_SCENE
; reads after a won game: graphics 92 and 93, drawn with the same two sprites
; as 90 and 91, in white at x 112, lines 128 and 144, and graphic 85, the oil
; can, in bright green at x 108, line 32 -- run by OILED_ROBOT, SCENE_ROBOT_TOP
; and the second entry of SCENE_SPARKS. It is ended by the zero at
; SCENE_WON_END.
SCENE_LOST_END:
  DEFB $00                 ; The end of the lost scene; graphic 92; 93; the
SCENE_WON:
  DEFB $5C,$10,$07,$70,$80 ; start of 85's entry
  DEFB $5D,$10,$07,$70,$90 ;
  DEFB $55,$10             ;

; The scene after a won game, continued
SCENE_WON_B:
  DEFB $44,$6C,$20        ; Graphic 85's colour, x and line

; The end of the won game's scene
;
; The zero that ends the list at SCENE_WON (SCENE_LOST_END). The stage-1
; annotations had this byte as unused; it is read by SET_UP_SCENE at the end of
; every won game.
SCENE_WON_END:
  DEFB $00                ; End of the list

; Mark the robot's room as seen
;
; Used by the routine at ENTER_ROOM.
;
; ROOMS_SEEN is a 256-bit map, a bit per room number: the byte is the room
; number divided by 8, the bit its low three bits. SET takes its bit number in
; the opcode, so the second byte of the SET instruction at the end is rewritten
; before it runs. Called as a room is entered (ENTER_ROOM); COUNT_ROOMS_SEEN
; counts the bits for the rating. Knight Lore's flag_room_visited, byte for
; byte in its logic.
MARK_ROOM_SEEN:
  LD A,(PLAYER_ROOM)      ; HL = the room / 8
  LD C,A                  ;
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  AND $1F                 ;
  LD L,A                  ;
  LD H,$00                ;
  LD A,C                  ; the opcode byte for SET (room AND 7),(HL)
  RLCA                    ;
  RLCA                    ;
  RLCA                    ;
  AND $38                 ;
  OR $C6                  ;
  LD ($B87F),A            ;
  LD BC,ROOMS_SEEN        ; set the bit in the map
  ADD HL,BC               ;
  SET 0,(HL)              ;
  RET                     ;

; Count the rooms seen
;
; Used by the routine at GAME_ENDED.
;
; Counts the set bits in the 32 bytes of ROOMS_SEEN, less one. Used for the
; rating after a game (GAME_ENDED).
;
; O:A the number of rooms seen, less one
COUNT_ROOMS_SEEN:
  LD E,$00                ; E counts; 8 bits in each of 32 bytes
  LD BC,$0820             ;
  LD HL,ROOMS_SEEN        ;
COUNT_ROOMS_SEEN_0:
  PUSH BC                  ; count this byte's bits
  LD A,(HL)                ;
  INC HL                   ;
COUNT_ROOMS_SEEN_1:
  RRCA                     ;
  JR NC,COUNT_ROOMS_SEEN_2 ;
  INC E                    ;
COUNT_ROOMS_SEEN_2:
  DJNZ COUNT_ROOMS_SEEN_1  ;
  POP BC                   ; the next byte
  DEC C                    ;
  JR NZ,COUNT_ROOMS_SEEN_0 ;
  LD A,E                  ; less one
  DEC A                   ;
  RET                     ;

; Wait for a key, or for a while
;
; Used by the routines at GAME_ENDED and ARRIVAL_SCREEN.
;
; Reads the whole keyboard B times 65536 times, and returns as soon as a key is
; down. At 95 T-states a read (counted from the instructions), B = 8 is about
; 14 seconds. Knight Lore's wait_key_poll.
;
;   B how long to wait, in units of 65536 reads
; O:F NZ if a key was pressed
WAIT_KEY_OR_TIME:
  LD HL,$0000             ; the inner count
WAIT_KEY_OR_TIME_0:
  XOR A                   ; any key: done
  CALL READ_KEYS          ;
  RET NZ                  ;
  DEC HL                   ; the inner count
  LD A,H                   ;
  OR L                     ;
  JR NZ,WAIT_KEY_OR_TIME_0 ;
  DJNZ WAIT_KEY_OR_TIME_0 ; the outer count
  RET                     ;

; The game is won: the arrival screen
;
; Used by the routine at GAME_ENDED.
;
; Jumped to from GAME_ENDED when WON is set. Clears the buffer, blanks the
; screen with bright red attributes, prints the seven lines of the arrival text
; -- the station arrived and slowed, the activation circuits held, all crew
; systems go -- clearing TEXT_SHOWN first so that the list also draws the
; border and shows the screen, then plays the arrival tune to its end, waits
; about fourteen seconds or for a key, and goes on to the summary as for a lost
; game. As Knight Lore's game_complete_msg.
ARRIVAL_SCREEN:
  CALL CLEAR_SCRN_BUFFER  ; clear the buffer; the border black, the attributes
  CALL CLEAR_SCRN         ; bright red, the screen blank
  LD DE,ARRIVAL_COLOURS   ; colours from ARRIVAL_COLOURS, positions from
  EXX                     ; ARRIVAL_XY, strings from ARRIVAL_TEXT: seven lines
  LD HL,ARRIVAL_XY        ;
  LD DE,ARRIVAL_TEXT      ;
  LD B,$07                ;
  XOR A                   ; the first list since the flag was cleared: border
  LD (TEXT_SHOWN),A       ; and screen too
  CALL DISPLAY_TEXT_LIST  ;
  LD DE,TUNE_ARRIVAL      ; the arrival tune, in full
  CALL PLAY_TUNE          ;
  LD B,$08                ; about 14 seconds, or until a key
  CALL WAIT_KEY_OR_TIME   ;
  JP SUMMARY_SCREEN       ; then the summary

; The arrival screen's text: colours
;
; A text list for DISPLAY_MENU's printing loop (entered at DISPLAY_MENU's
; second entry by ARRIVAL_SCREEN) is three tables: a colour byte for each line;
; two bytes for each line's place, x and then the line of the buffer counted up
; from the bottom; and the strings, each ended by bit 7 set on its last
; character. Here seven lines: colours, from this entry; places from
; ARRIVAL_XY; strings from ARRIVAL_TEXT (in ARRIVAL_XY_E). The whole list runs
; to ARRIVAL_TEXT_N; sna2ctl split it into pieces, some taken for text.
;
; The colours are bright cyan for the first two lines, then bright green,
; bright magenta, bright magenta, bright red and bright red. The places are x
; 32, line 143; 88, 127; 40, 111; 72, 95; 72, 79; 72, 63; and 88, 47.
ARRIVAL_COLOURS:
  DEFB $45,$45,$44,$43,$43,$42,$42 ; The seven lines' colours; then the first
ARRIVAL_XY:
  DEFB $20                         ; line's x

; The arrival screen's text: places, continued
ARRIVAL_XY_B:
  DEFB $8F                ; The first line's line; the second's x and line
  DEFB $58,$7F            ;

; The arrival screen's text: places, continued
ARRIVAL_XY_C:
  DEFB $28,$6F            ; The third line's place; the fourth's x
  DEFB $48                ;

; The arrival screen's text: places, continued
ARRIVAL_XY_D:
  DEFB $5F                ; The fourth line's line

; The arrival screen's text: the last places and the first string
;
; The places of lines five to seven, then ARRIVAL_TEXT, the strings, which
; ARRIVAL_SCREEN points at. The last character of each string, with bit 7 set,
; is an entry of its own.
ARRIVAL_XY_E:
  DEFB $48,$4F            ; Lines five, six and seven: x and line
  DEFB $48,$3F            ;
  DEFB $58,$2F            ;
ARRIVAL_TEXT:
  DEFM "THE STATION HAS ARRIVE"

; The arrival text, continued
ARRIVAL_TEXT_B:
  DEFB $C4                ; D, with bit 7 set

; The arrival text, continued
ARRIVAL_TEXT_C:
  DEFM "FROM SPAC"

; The arrival text, continued
ARRIVAL_TEXT_D:
  DEFB $C5                ; E, with bit 7 set

; The arrival text, continued
ARRIVAL_TEXT_E:
  DEFM "THRUSTERS GENTLY SLO"

; The arrival text, continued
ARRIVAL_TEXT_F:
  DEFB $D7                ; W, with bit 7 set

; The arrival text, continued
ARRIVAL_TEXT_G:
  DEFM "THE ACTIVATIO"

; The arrival text, continued
ARRIVAL_TEXT_H:
  DEFB $CE                ; N, with bit 7 set

; The arrival text, continued
ARRIVAL_TEXT_I:
  DEFM "CIRCUITS  HEL"

; The arrival text, continued
ARRIVAL_TEXT_J:
  DEFB $C4                ; D, with bit 7 set

; The arrival text, continued
ARRIVAL_TEXT_K:
  DEFM "ALL CRYONAUGH"

; The arrival text, continued
ARRIVAL_TEXT_L:
  DEFB $D4                ; T, with bit 7 set

; The arrival text, continued
ARRIVAL_TEXT_M:
  DEFM "SYSTEMS G"

; The arrival text's last character
ARRIVAL_TEXT_N:
  DEFB $CF                ; O, with bit 7 set

; The summary screen: the colour of each line
;
; The summary shown after every game (GAME_ENDED), won or lost, is a text list
; printed by DISPLAY_TEXT_LIST (DISPLAY_MENU) from three tables that run on
; from here: seven colours, one per line (this entry's first seven bytes);
; seven (x, y) pixel positions from the eighth byte (SUMMARY_XY), y counting up
; from the bottom of the screen; and the seven strings from SUMMARY_TEXT, in
; SUMMARY_XY_LOST, to SUMMARY_RATING_LAST, ASCII with bit 7 set on the last
; character of each. sna2ctl split them into many entries, because the
; positions and colours are the codes of letters.
;
; The colours are bright white for the title, bright yellow for the two lines
; about the activated chambers, bright cyan for the two about the unactivated
; ones, bright magenta for the crew lost and bright green for the rating's
; heading. The three counts (PRINT_SUMMARY_COUNTS) and the rating itself (in
; the routine at GAME_ENDED, from SUMMARY_RATING_LAST) are printed over the
; list afterwards.
SUMMARY_COLOURS:
  DEFB $47,$46,$46,$45,$45,$43,$44 ; The seven lines' colours; then the title's
SUMMARY_XY:
  DEFB $58                         ; x, 88 (character column 11), the first
                                   ; byte of the positions

; The summary screen: where the lines go (the title's y; lines 2 and 3)
;
; The positions go on from SUMMARY_XY, SUMMARY_COLOURS's last byte, an (x, y)
; pair per line; each line's characters cover the eight pixel rows from y down.
SUMMARY_Y_TITLE:
  DEFB $9F                ; The title's y, 159 (character row 4); "ACTIVATED
  DEFB $30,$8F            ; CRYOGENIC" at (48, 143); the first "CHAMBERS" line
  DEFB $30,$7F            ; at (48, 127)

; The summary screen: where the lines go (line 4; line 5's x)
SUMMARY_XY_UNACTIVATED:
  DEFB $28,$6F            ; "UNACTIVATED CRYOGENIC" at (40, 111); x of the
  DEFB $30                ; second "CHAMBERS" line, 48

; The summary screen: where the lines go (line 5's y)
SUMMARY_Y_CHAMBERS:
  DEFB $5F                ; y of the second "CHAMBERS" line: 95

; The summary screen: where the last two lines go, and the title
;
; The last two positions, then the list's strings begin, at SUMMARY_TEXT, the
; fifth byte of this entry.
SUMMARY_XY_LOST:
  DEFB $28,$4F            ; "CRYONAUGHTS LOST" at (40, 79); "OVERALL RATING" at
  DEFB $48,$37            ; (72, 55)
SUMMARY_TEXT:
  DEFM "GAME OVE"

; The summary screen: the title's last letter
SUMMARY_TITLE_LAST:
  DEFB $D2                ; R, with bit 7 set to end the string

; The summary screen: "ACTIVATED CRYOGENIC"
SUMMARY_ACTIVATED:
  DEFM "ACTIVATED CRYOGENI"

; The summary screen: "ACTIVATED CRYOGENIC", its last letter
SUMMARY_ACTIVATED_LAST:
  DEFB $C3                ; C, with bit 7 set

; The summary screen: the first "CHAMBERS" line
;
; "CHAMBERS" and a row of dots, which the font draws for the semicolon, then
; two spaces for the count (SUMMARY_ACTIVE) that PRINT_SUMMARY_COUNTS prints
; over them.
SUMMARY_CHAMBERS_ACTIVE:
  DEFM "CHAMBERS;;;;;;;;; "

; The summary screen: the first "CHAMBERS" line, its last character
SUMMARY_CHAMBERS_ACTIVE_LAST:
  DEFB $A0                ; A space, with bit 7 set

; The summary screen: "UNACTIVATED CRYOGENIC"
SUMMARY_UNACTIVATED:
  DEFM "UNACTIVATED CRYOGENI"

; The summary screen: "UNACTIVATED CRYOGENIC", its last letter
SUMMARY_UNACTIVATED_LAST:
  DEFB $C3                ; C, with bit 7 set

; The summary screen: the second "CHAMBERS" line
;
; As SUMMARY_CHAMBERS_ACTIVE; the count printed over the spaces is
; SUMMARY_IDLE.
SUMMARY_CHAMBERS_IDLE:
  DEFM "CHAMBERS;;;;;;;;; "

; The summary screen: the second "CHAMBERS" line, its last character
SUMMARY_CHAMBERS_IDLE_LAST:
  DEFB $A0                ; A space, with bit 7 set

; The summary screen: "CRYONAUGHTS LOST."
;
; Three spaces after the full stop (a semicolon in the code), where
; PRINT_SUMMARY_COUNTS prints the last three digits of SUMMARY_LOST.
SUMMARY_CRYONAUGHTS:
  DEFM "CRYONAUGHTS LOST;  "

; The summary screen: "CRYONAUGHTS LOST.", its last character
SUMMARY_CRYONAUGHTS_LAST:
  DEFB $A0                ; A space, with bit 7 set

; The summary screen: "OVERALL RATING"
SUMMARY_RATING:
  DEFM "OVERALL RATIN"

; The summary screen: "OVERALL RATING", its last letter; and the eight ratings
;
; The heading's last letter, then, from RATINGS, the second byte of this entry,
; eight words: the addresses of the ratings, RATING_POOR to RATING_ADVENTURER.
; The summary (GAME_ENDED) picks one by the rooms seen and by whether the game
; was won: the rooms seen (ROOMS_SEEN, counted by COUNT_ROOMS_SEEN) less one,
; divided by 32, is 0 to 3, and a won game adds 4. So a lost game rates POOR up
; to 32 rooms seen, AVERAGE up to 64, FAIR up to 96 and GOOD above; a won one
; EXCELLENT, MARVELLOUS, HERO and ADVENTURER the same way. AVERAGE ranks below
; FAIR. The eight words, their order and the way one is picked are Knight
; Lore's (its ratings table); only the colour differs.
;
; The ratings are printed at (88, 39) by PRINT_TEXT, which takes a string's
; colour from its first byte: every rating starts with G, bright white.
SUMMARY_RATING_LAST:
  DEFB $C7                ; G, with bit 7 set
RATINGS:
  DEFW RATING_POOR        ; 0: lost, up to 32 rooms seen: RATING_POOR
  DEFW RATING_AVERAGE     ; 1: lost, up to 64: RATING_AVERAGE
  DEFW RATING_FAIR        ; 2: lost, up to 96: RATING_FAIR
  DEFW RATING_GOOD        ; 3: lost, more: RATING_GOOD
  DEFW RATING_EXCELLENT   ; 4: won, up to 32 rooms seen: RATING_EXCELLENT
  DEFW RATING_MARVELLOUS  ; 5: won, up to 64: RATING_MARVELLOUS
  DEFW RATING_HERO        ; 6: won, up to 96: RATING_HERO
  DEFW RATING_ADVENTURER  ; 7: won, more: RATING_ADVENTURER

; Rating 0: "POOR"
;
; The first byte is the colour, bright white; some words are padded on the left
; with spaces. The same form for all eight.
RATING_POOR:
  DEFB $47                ; The colour
  DEFM "   POO"

; Rating 0, its last letter
RATING_POOR_LAST:
  DEFB $D2                ; R, with bit 7 set

; Rating 1: "AVERAGE"
RATING_AVERAGE:
  DEFB $47                ; The colour
  DEFM " AVERAG"

; Rating 1, its last letter
RATING_AVERAGE_LAST:
  DEFB $C5                ; E, with bit 7 set

; Rating 2: "FAIR"
RATING_FAIR:
  DEFB $47                ; The colour
  DEFM "   FAI"

; Rating 2, its last letter
RATING_FAIR_LAST:
  DEFB $D2                ; R, with bit 7 set

; Rating 3: "GOOD"
RATING_GOOD:
  DEFB $47                ; The colour
  DEFM "   GOO"

; Rating 3, its last letter
RATING_GOOD_LAST:
  DEFB $C4                ; D, with bit 7 set

; Rating 4, the first for a won game: "EXCELLENT"
RATING_EXCELLENT:
  DEFB $47                ; The colour
  DEFM "EXCELLEN"

; Rating 4, its last letter
RATING_EXCELLENT_LAST:
  DEFB $D4                ; T, with bit 7 set

; Rating 5: "MARVELLOUS"
RATING_MARVELLOUS:
  DEFB $47                ; The colour
  DEFM "MARVELLOU"

; Rating 5, its last letter
RATING_MARVELLOUS_LAST:
  DEFB $D3                ; S, with bit 7 set

; Rating 6: "HERO"
RATING_HERO:
  DEFB $47                ; The colour
  DEFM "   HER"

; Rating 6, its last letter
RATING_HERO_LAST:
  DEFB $CF                ; O, with bit 7 set

; Rating 7, a won game with more than 96 rooms seen: "ADVENTURER"
RATING_ADVENTURER:
  DEFB $47                ; The colour
  DEFM "ADVENTURE"

; Rating 7, its last letter
RATING_ADVENTURER_LAST:
  DEFB $D2                ; R, with bit 7 set

; Print the summary's three counts
;
; Used by the routine at GAME_ENDED.
;
; Prints the counts SUMMARISE_CHAMBERS has worked out over the spaces the
; summary's text list (SUMMARY_COLOURS) leaves for them, into the buffer, in
; the digits' font: the activated chambers (SUMMARY_ACTIVE) at pixel x 184, y
; 127; the unactivated ones (SUMMARY_IDLE) at x 184, y 95; the crew lost
; (SUMMARY_LOST, four BCD digits of which the last three are printed) at x 176,
; y 79. Called by the summary (GAME_ENDED), before it draws the border and
; shows the buffer.
PRINT_SUMMARY_COUNTS:
  LD HL,FONT              ; the font itself as the base, so that a BCD digit is
  LD (FONT_BASE),HL       ; its own character code
  LD DE,SUMMARY_LOST      ; SUMMARY_LOST: its low digit, then both digits of
  LD HL,$DBF6             ; the byte after
  LD B,$02                ;
  CALL PRINT_BCD_LSD      ;
  LD HL,$E1F7             ; SUMMARY_ACTIVE, the next byte: both digits
  LD B,$01                ;
  CALL PRINT_BCD_BYTE     ;
  LD HL,$DDF7             ; SUMMARY_IDLE, the byte after that
  LD B,$01                ;
  JP PRINT_BCD_BYTE       ;

; Print the number of lives
;
; Used by the routines at COLOUR_PANEL and EXTRA_LIFE.
;
; LIVES as two BCD digits into the buffer at pixel x 128, y 7, on the panel.
; Called when the panel is drawn (COLOUR_PANEL) and when an extra life is taken
; (EXTRA_LIFE), which then copies the two characters to the screen (BLIT_2X8).
;
; LIVES counts in binary (START sets 5, NEW_LIFE takes one, EXTRA_LIFE adds
; one), so the display is right only while he has fewer than ten -- as in
; Knight Lore.
PRINT_LIVES:
  LD DE,LIVES             ; one byte, LIVES, into the buffer at pixel row 7,
  LD B,$01                ; byte column 16
  LD HL,$D2F0             ;
  JP PRINT_BCD_NUMBER     ;
; This entry point is used by the routine at PRINT_CHAMBERS.
;
; Print B bytes of BCD from DE into the buffer at HL, two digits each, the high
; digit first. Also used by PRINT_CHAMBERS for the chambers activated.
PRINT_BCD_NUMBER:
  PUSH HL                 ; the font itself as FONT_BASE: digits are codes 0 to
  LD HL,FONT              ; 9
  LD (FONT_BASE),HL       ;
  POP HL                  ;
; This entry point is used by the routine at PRINT_SUMMARY_COUNTS.
PRINT_BCD_BYTE:
  LD A,(DE)               ; the high digit
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  AND $0F                 ;
  CALL PRINT_CHAR         ;
; This entry point is used by the routine at PRINT_SUMMARY_COUNTS.
PRINT_BCD_LSD:
  LD A,(DE)               ; the low digit; coming in here prints only the low
  AND $0F                 ; digit of the first byte (PRINT_SUMMARY_COUNTS)
  CALL PRINT_CHAR         ;
  INC DE                  ; the next byte
  DJNZ PRINT_BCD_BYTE     ;
  RET                     ;

; The menu
;
; Used by the routine at AFTER_GAME.
;
; Called by AFTER_GAME before every game. It clears TEXT_SHOWN, so that the
; first list printed draws the border and shows the buffer, stops every line's
; flash, clears the buffer, draws the menu (DISPLAY_MENU) and flashes the lines
; chosen (FLASH_MENU). Then round a loop: print the text again (only its
; attributes, with the flashing, reach the screen), play the tune if it has not
; been heard (PLAY_TUNE_ONCE, which a key cuts short), and read the keys.
;
; Keys 1 to 4 set bits 1 and 2 of CONTROL to 0 keyboard, 1 Kempston, 2 cursor,
; 3 Interface II; if several are held the highest wins, since each is applied
; in turn. Key 5 toggles bit 3, directional control, once a press (KEY5_HELD).
; A change to CONTROL beeps (PLAIN_BEEP). Key 0 starts the game. Every pass
; counts SEED up by one, so the time spent on the menu goes into the choice of
; start room (NEW_GAME_START).
;
; As Knight Lore's menu, key 5 and all; Pentagram's is this code without key 5
; and without the beep.
MENU:
  XOR A                   ; no list shown yet
  LD (TEXT_SHOWN),A       ;
  LD HL,MENU_COLOURS      ; no line flashing: all eight colours in MENU_COLOURS
  LD B,$08                ;
MENU_0:
  RES 7,(HL)              ;
  INC HL                  ;
  DJNZ MENU_0             ;
  CALL CLEAR_SCRN_BUFFER  ; a clear buffer; the text, the border and the whole
  CALL DISPLAY_MENU       ; screen; the lines chosen
  CALL FLASH_MENU         ;
MENU_LOOP:
  CALL DISPLAY_MENU       ; the text again; the tune, once
  LD DE,TUNE_MENU         ;
  CALL PLAY_TUNE_ONCE     ;
  LD A,$F7                ; E = keys 1-5, key 1 in bit 0
  CALL READ_KEYS          ;
  LD E,A                  ;
  LD A,(CONTROL)          ; A = CONTROL, and as it was into CONTROL_BEFORE
  LD (CONTROL_BEFORE),A   ;
  BIT 0,E                 ; 1: keyboard
  JR Z,MENU_1             ;
  AND $F9                 ;
MENU_1:
  BIT 1,E                 ; 2: Kempston
  JR Z,MENU_2             ;
  AND $F9                 ;
  OR $02                  ;
MENU_2:
  BIT 2,E                 ; 3: cursor keys
  JR Z,MENU_3             ;
  AND $F9                 ;
  OR $04                  ;
MENU_3:
  BIT 3,E                 ; 4: Interface II
  JR Z,MENU_4             ;
  OR $06                  ;
MENU_4:
  LD (CONTROL),A          ; the new method
  LD HL,KEY5_HELD         ; key 5 not held: clear its latch (at the end)
  BIT 4,E                 ;
  JR Z,MENU_KEY5_RELEASED ;
  BIT 0,(HL)                 ; still held since the last pass: nothing
  JR NZ,MENU_BEEP_IF_CHANGED ;
  SET 0,(HL)              ; a new press: latch it, and toggle directional
  LD A,(CONTROL)          ; control
  XOR $08                 ;
  LD (CONTROL),A          ;
MENU_BEEP_IF_CHANGED:
  LD HL,CONTROL_BEFORE    ; A is the new CONTROL whichever way this is reached:
  CP (HL)                 ; beep if it has changed
  CALL NZ,PLAIN_BEEP      ;
  LD A,$EF                ; key 0 (bit 0 of the 6-0 half-row): start the game
  CALL READ_KEYS          ;
  BIT 0,A                 ;
  RET NZ                  ;
  LD HL,SEED              ; one more to the seed each pass
  INC (HL)                ;
  CALL FLASH_MENU         ; flash the choice; round again
  JP MENU_LOOP            ;
MENU_KEY5_RELEASED:
  RES 0,(HL)              ; key 5 is up: clear the latch
  JR MENU_BEEP_IF_CHANGED ;

; Flash the chosen lines on the menu
;
; Used by the routine at MENU.
;
; Sets the FLASH bit on the colour of the line for the method in bits 1-2 of
; CONTROL and clears it on the other three (TOGGLE_SELECTED), then sets or
; clears it on the next colour -- the "5 DIRECTIONAL CONTROL" line's -- to
; match bit 3 of CONTROL. The colours are MENU_COLOURS's; the title's, the
; first, is left alone. As Knight Lore's flash_menu, instruction for
; instruction.
FLASH_MENU:
  LD HL,$BB15             ; the four method lines, from the second colour:
  LD A,(CONTROL)          ; flash the one for bits 1-2
  RRCA                    ;
  AND $03                 ;
  LD B,$04                ;
  CALL TOGGLE_SELECTED    ;
  RES 7,(HL)              ; HL is now on the directional-control line's colour:
  LD A,(CONTROL)          ; flash it if bit 3 is set
  AND $08                 ;
  RET Z                   ;
  SET 7,(HL)              ;
  RET                     ;

; The menu: the colour of each line
;
; The menu's three tables run on from here as one block, as the summary's do
; (SUMMARY_COLOURS): eight colours, one per line; eight (x, y) pixel positions
; from the ninth byte (MENU_XY), y counting up from the bottom of the screen;
; and the eight strings from MENU_TEXT, in MENU_XY_KEY5, to
; MENU_COPYRIGHT_LAST, ASCII with bit 7 set on the last character of each.
; DISPLAY_MENU hands the three addresses to DISPLAY_TEXT_LIST.
;
; The colours are bright magenta for the title, bright green for the four
; control methods, bright cyan for directional control and bright white for the
; start and copyright lines. FLASH_MENU sets bit 7 (FLASH) of the chosen
; method's and of directional control's; MENU clears bit 7 of all eight before
; the menu is drawn.
MENU_COLOURS:
  DEFB $43,$44,$44,$44,$44,$45,$47,$47 ; The eight lines' colours; then the
MENU_XY:
  DEFB $68                             ; title's x, 104 (character column 13),
                                       ; the first byte of the positions

; The menu: where the lines go (the title's y; keys 1 and 2)
;
; The positions go on from MENU_XY, MENU_COLOURS's last byte, an (x, y) pair
; per line. The option lines start at x 48, character column 6, and step down
; 16 pixels, two character rows, from y 143.
MENU_Y_TITLE:
  DEFB $9F                ; The title's y, 159 (character row 4); "1 KEYBOARD"
  DEFB $30,$8F            ; at (48, 143); "2 KEMPSTON JOYSTICK" at (48, 127)
  DEFB $30,$7F            ;

; The menu: where the lines go (key 3; key 4's x)
MENU_XY_KEY3:
  DEFB $30,$6F            ; "3 CURSOR JOYSTICK" at (48, 111); x of "4 INTERFACE
  DEFB $30                ; II", 48

; The menu: where the lines go (key 4's y)
MENU_Y_KEY4:
  DEFB $5F                ; y of "4 INTERFACE II": 95

; The menu: where the last three lines go, and the title
;
; The last three positions, then the menu's strings begin, at MENU_TEXT, the
; seventh byte of this entry, with the title.
MENU_XY_KEY5:
  DEFB $30,$4F            ; "5 DIRECTIONAL CONTROL" at (48, 79); "0 START GAME"
  DEFB $30,$3F            ; at (48, 63); the copyright line at (80, 39)
  DEFB $50,$27            ;
MENU_TEXT:
  DEFM "ALIEN "

; The menu: the title's last character
MENU_TITLE_LAST:
  DEFB $B8                ; 8, with bit 7 set to end the string

; The menu: "1 KEYBOARD"
MENU_KEYBOARD:
  DEFM "1 KEYBOAR"

; The menu: "1 KEYBOARD", its last letter
MENU_KEYBOARD_LAST:
  DEFB $C4                ; D, with bit 7 set

; The menu: "2 KEMPSTON JOYSTICK"
MENU_KEMPSTON:
  DEFM "2 KEMPSTON JOYSTIC"

; The menu: "2 KEMPSTON JOYSTICK", its last letter
MENU_KEMPSTON_LAST:
  DEFB $CB                ; K, with bit 7 set

; The menu: "3 CURSOR JOYSTICK"
MENU_CURSOR:
  DEFM "3 CURSOR JOYSTIC"

; The menu: "3 CURSOR JOYSTICK", its last letter
MENU_CURSOR_LAST:
  DEFB $CB                ; K, with bit 7 set

; The menu: "4 INTERFACE II"
MENU_INTERFACE:
  DEFM "4 INTERFACE I"

; The menu: "4 INTERFACE II", its last letter
MENU_INTERFACE_LAST:
  DEFB $C9                ; I, with bit 7 set

; The menu: "5 DIRECTIONAL CONTROL"
MENU_DIRECTIONAL:
  DEFM "5 DIRECTIONAL CONTRO"

; The menu: "5 DIRECTIONAL CONTROL", its last letter
MENU_DIRECTIONAL_LAST:
  DEFB $CC                ; L, with bit 7 set

; The menu: "0 START GAME"
MENU_START:
  DEFM "0 START GAM"

; The menu: "0 START GAME", its last letter
MENU_START_LAST:
  DEFB $C5                ; E, with bit 7 set

; The menu: the copyright line
;
; Reads on the screen as a copyright sign, then "1985 A.C.G.": the font (FONT)
; draws the copyright sign for the code of the greater-than sign, and a full
; stop for the semicolon (drawn from the font's bytes).
MENU_COPYRIGHT:
  DEFM "> 1985 A;C;G"

; The menu: the copyright line's last character
MENU_COPYRIGHT_LAST:
  DEFB $BB                ; The last full stop (a semicolon in the code), with
                          ; bit 7 set

; Print a string in one colour
;
; Used by the routine at DISPLAY_MENU.
;
; Prints into the screen buffer (CALC_VIDBUF_ADDR) in the text font, colouring
; each character's cell straight into the attribute file with PRINT_ATTR. Each
; character covers the pixel rows from y down to y-7. As Knight Lore's
; print_text_single_colour, instruction for instruction; the rest is in
; PRINT_TEXT.
;
;   HL the position: L = x, H = y, in pixels, y counting up from the bottom of
;      the screen
;   DE the string, ASCII with bit 7 set on the last character
; O:DE the byte after the string
PRINT_TEXT_SINGLE_COLOUR:
  PUSH HL                 ; the text font: FONT_BASE 384 bytes below the font
  LD HL,$6188             ; at FONT, so that a letter's code lands on its glyph
  LD (FONT_BASE),HL       ;
  POP BC                  ; BC = the position again, left on the stack for
  PUSH BC                 ; TEXT_ATTR_ADDR; HL = its address in the buffer
  CALL CALC_VIDBUF_ADDR   ;
  LD L,C                  ;
  LD H,B                  ;
  LD A,(PRINT_ATTR)       ; the colour into A'
  EX AF,AF'               ;
  JR TEXT_ATTR_ADDR       ;

; Print a string whose first byte is its colour
;
; Used by the routines at COLOUR_PANEL and GAME_ENDED.
;
; As PRINT_TEXT_SINGLE_COLOUR, but the colour is the string's own first byte.
; The panel's "LIGHT YEARS" (COLOUR_PANEL, which writes that byte first) and
; the summary's rating (GAME_ENDED, RATING_POOR) are printed with it. Knight
; Lore's print_text; Pentagram has these bytes too, but nothing reaches them
; there.
;
; TEXT_ATTR_ADDR, the entry after the colour is in A', takes the position off
; the stack: in the alternate registers HL' becomes the attribute address of
; the first cell, while DE' is kept, since the list printer (DISPLAY_MENU)
; walks its colours with it. Then each character is drawn into the buffer by
; PRINT_CHAR, which leaves HL one cell to the right, and its cell in the
; attribute file is given the colour.
;
;   HL the position: L = x, H = y, in pixels, y counting up from the bottom
;   DE the colour byte, then the string, bit 7 set on its last character
; O:DE the byte after the string
PRINT_TEXT:
  PUSH HL                 ; the text font
  LD HL,$6188             ;
  LD (FONT_BASE),HL       ;
  POP BC                  ; BC = the position, left on the stack; HL = its
  PUSH BC                 ; address in the buffer
  CALL CALC_VIDBUF_ADDR   ;
  LD L,C                  ;
  LD H,B                  ;
  LD A,(DE)               ; the colour, from the string's first byte, into A'
  EX AF,AF'               ;
  INC DE                  ;
; This entry point is used by the routine at PRINT_TEXT_SINGLE_COLOUR.
TEXT_ATTR_ADDR:
  EXX                     ; take the position off the stack into HL'
  POP HL                  ;
  PUSH DE                 ; HL' = the attribute address of the position
  CALL CALC_ATTRIB_ADDR   ; (CALC_ATTRIB_ADDR); DE' kept
  LD L,E                  ;
  LD H,D                  ;
  POP DE                  ;
PRINT_TEXT_CHAR:
  EXX                     ; bit 7 marks the last character
  LD A,(DE)               ;
  BIT 7,A                 ;
  JR NZ,PRINT_TEXT_LAST   ;
  PUSH DE                 ; draw it, and move on in the string
  CALL PRINT_CHAR         ;
  POP DE                  ;
  INC DE                  ;
  EXX                     ; colour its cell, one cell right, and loop
  EX AF,AF'               ;
  LD (HL),A               ;
  INC L                   ;
  EX AF,AF'               ;
  JR PRINT_TEXT_CHAR      ;
PRINT_TEXT_LAST:
  AND $7F                 ; the last character, without its end marker; DE ends
  PUSH DE                 ; past the string
  CALL PRINT_CHAR         ;
  POP DE                  ;
  INC DE                  ;
  EXX                     ; colour its cell
  EX AF,AF'               ;
  LD (HL),A               ;
  EXX                     ;
  RET                     ;
; The PUSH DE and POP DE round each call of PRINT_CHAR are not needed: it keeps
; DE itself.

; Print a character into the screen buffer
;
; Used by the routines at PRINT_LIVES and PRINT_TEXT.
;
; A character is eight bytes from FONT_BASE plus eight times its code, the top
; row first; they overwrite eight rows of the buffer going down from HL (32
; bytes a row, down being towards the start of the buffer). HL comes back one
; byte to the right, on the same top row, ready for the next character. A space
; is printed as code $3D, whose glyph is blank.
;
; For text FONT_BASE is 384 bytes below the font (PRINT_TEXT_SINGLE_COLOUR), so
; the codes $30 to $5A land in it; for numbers it is the font itself
; (PRINT_BCD_NUMBER, in PRINT_LIVES), so that digits are codes 0 to 9. The
; light years (PRINT_ROLLING_DIGIT) come in at PRINT_GLYPH with HL already
; eight times the code.
;
;   A the code
;   HL the buffer address of the character's top row
; O:HL one byte to the right
PRINT_CHAR:
  CP $20                  ; a space is code $3D
  JR NZ,PRINT_CHAR_0      ;
  LD A,$3D                ;
PRINT_CHAR_0:
  PUSH BC                 ; HL = 8 * the code
  PUSH DE                 ;
  PUSH HL                 ;
  LD L,A                  ;
  LD H,$00                ;
  ADD HL,HL               ;
  ADD HL,HL               ;
  ADD HL,HL               ;
; This entry point is used by the routine at PRINT_ROLLING_DIGIT.
PRINT_GLYPH:
  LD DE,(FONT_BASE)       ; DE = FONT_BASE + HL, the glyph
  ADD HL,DE               ;
  EX DE,HL                ;
  POP HL                  ; eight rows, each written 32 bytes below the one
  LD B,$08                ; before
PRINT_CHAR_1:
  LD A,(DE)               ;
  LD (HL),A               ;
  INC DE                  ;
  PUSH BC                 ;
  LD BC,$FFE0             ;
  ADD HL,BC               ;
  POP BC                  ;
  DJNZ PRINT_CHAR_1       ;
  POP DE                  ; back up the eight rows and one byte right
  LD BC,$0101             ;
  ADD HL,BC               ;
  POP BC                  ;
  RET                     ;

; Flash one of B attributes, and steady the rest
;
; Used by the routine at FLASH_MENU.
;
; Sets bit 7, FLASH, on the A'th of B attribute bytes from HL, counting from 0,
; and clears it on the others. FLASH_MENU marks the chosen control method on
; the menu with it. This entry deals with the first byte; the loop is
; FLASH_NEXT_ONE. HL comes back just past the last byte. As Knight Lore's
; toggle_selected.
;
; HL the first attribute
; B how many
; A which one flashes
TOGGLE_SELECTED:
  AND A                   ; not the first
  JR NZ,UNFLASH_THIS_ONE  ;
; This entry point is used by the routine at FLASH_NEXT_ONE.
FLASH_THIS_ONE:
  SET 7,(HL)              ; flash this one
  JR FLASH_LIST_STEP      ;

; The rest of TOGGLE_SELECTED
;
; Counts A down a byte at a time, flashing the byte where it reaches zero.
FLASH_NEXT_ONE:
  DEC A                   ; this is the one
  JR Z,FLASH_THIS_ONE     ;
; This entry point is used by the routine at TOGGLE_SELECTED.
UNFLASH_THIS_ONE:
  RES 7,(HL)              ; steady
; This entry point is used by the routine at TOGGLE_SELECTED.
FLASH_LIST_STEP:
  INC HL                  ; the next byte, until B runs out
  DJNZ FLASH_NEXT_ONE     ;
  RET                     ;

; Draw the menu
;
; Used by the routine at MENU.
;
; Hands DISPLAY_TEXT_LIST, the rest of this routine, the menu's eight colours
; (MENU_COLOURS), positions and strings. Called at the start of the menu and on
; every pass of its loop (MENU).
DISPLAY_MENU:
  LD DE,MENU_COLOURS      ; DE' = the colours
  EXX                     ;
  LD HL,MENU_XY           ; HL = the positions, MENU_XY
  LD DE,MENU_TEXT         ; DE = the strings, MENU_TEXT
  LD B,$08                ; eight lines
; This entry point is used by the routines at GAME_ENDED and ARRIVAL_SCREEN.
;
; Print a list of strings. B how many; DE' their colours, a byte each; HL their
; positions, an (x, y) pair each; DE the strings, end to end. Also used by the
; summary (GAME_ENDED) and the arrival screen (ARRIVAL_SCREEN).
DISPLAY_TEXT_LIST:
  EXX                     ; this string's colour into PRINT_ATTR, for
  LD A,(DE)               ; PRINT_TEXT_SINGLE_COLOUR
  LD (PRINT_ATTR),A       ;
  INC DE                  ;
  EXX                     ;
  PUSH BC                 ; L = x, H = y; HL moved on to the next pair and kept
  LD A,(HL)               ;
  INC HL                  ;
  INC HL                  ;
  PUSH HL                 ;
  DEC HL                  ;
  LD H,(HL)               ;
  LD L,A                  ;
  CALL PRINT_TEXT_SINGLE_COLOUR ; print it, and loop
  POP HL                        ;
  POP BC                        ;
  DJNZ DISPLAY_TEXT_LIST        ;
  LD A,(TEXT_SHOWN)       ; the first list since TEXT_SHOWN was cleared...
  AND A                   ;
  RET NZ                  ;
  INC A                   ; ...sets it...
  LD (TEXT_SHOWN),A       ;
  CALL PRINT_BORDER       ; ...draws the border (PRINT_BORDER) and shows the
  JP SHOW_BUFFER          ; whole buffer (SHOW_BUFFER); later lists only redraw
                          ; into the buffer and write the attributes, which is
                          ; how the menu's flashing lines change without the
                          ; screen being redrawn

; Draw a sprite several times in a line
;
; Used by the routines at DISPLAY_PANEL and PRINT_BORDER.
;
; Used to build the border (PRINT_BORDER) and the panel's frame (DISPLAY_PANEL)
; out of repeated pieces, drawn through the spare record at PANEL_RECORD. As
; Knight Lore's multiple_print_sprite.
;
; IX the record: the graphic at +0, the flags at +7, the pixel position at +$1A
;    and +$1B
; B how many times
; E the step in x between copies
; D the step in y between copies
MULTIPLE_PRINT_SPRITE:
  PUSH BC                 ; draw it (the entry into CALC_PIXEL_XY_AND_RENDER
  PUSH DE                 ; past the projection), keeping the registers
  PUSH HL                 ;
  CALL PRINT_SPRITE       ;
  POP HL                  ;
  POP DE                  ;
  POP BC                  ;
  LD A,(IX+$1A)           ; move the record's x by E and y by D
  ADD A,E                 ;
  LD (IX+$1A),A           ;
  LD A,(IX+$1B)           ;
  ADD A,D                 ;
  LD (IX+$1B),A           ;
  DJNZ MULTIPLE_PRINT_SPRITE ; and again
  RET                        ;

; The update routine for the robot appearing (graphics 56 to 62)
;
; Reached through UPDATES. As a life starts or he comes through a doorway both
; of the robot's records begin as graphic 56 with their real graphic kept at
; +$10 (EXIT_LOW_U, NEW_GAME_START; the start records at START_LEGS). This
; steps the graphic on by one every other turn, on the turns TURNS is odd, with
; a sound worked out from the frame (MATERIALISE_SOUND), until PLAYER_APPEARED
; finishes. Seven frames of two turns each. As Knight Lore's upd_120_to_126.
;
; IX the record
PLAYER_APPEARING:
  CALL DRAW_AT_L12_D8     ; the drawing nudge: X -12, Y -8
  LD A,(TURNS)            ; only when bit 0 of TURNS is set
  CPL                     ;
  AND $01                 ;
  RET NZ                  ;
  INC (IX+$00)               ; the next frame, its sound, and mark it to be
  CALL MATERIALISE_SOUND     ; drawn
  JP SET_WIPE_AND_DRAW_FLAGS ;

; The update routine for the robot's last frame of appearing (graphic 63)
;
; Reached through UPDATES. Turns the record back into what it was -- the
; graphic kept at +$10 -- with no step in U, V or Z and bit 6 of +$0D, the
; killed flag, clear, and runs that graphic's update routine at once, through
; the main loop's dispatch (AFTER_GAME). As Knight Lore's upd_127. Why the
; killed flag is cleared here is not certain: perhaps so that something deadly
; he touched while appearing does not count.
;
; IX the record
PLAYER_APPEARED:
  CALL DRAW_AT_L12_D8     ; the drawing nudge: X -12, Y -8
  XOR A                   ; no step in U, V or Z
  LD (IX+$09),A           ;
  LD (IX+$0A),A           ;
  LD (IX+$0B),A           ;
  RES 6,(IX+$0D)          ; not killed
  LD A,(IX+$10)           ; the real graphic back, and its update routine now
  LD (IX+$00),A           ;
  JP MAIN_DISPATCH        ;

; Show the carried things on the panel, if they have changed
;
; Used by the routine at RENDER_DYNAMIC_OBJECTS.
;
; Called every turn by RENDER_DYNAMIC_OBJECTS; it acts only when PANEL_DUE is
; set, as TAKE_OR_LEAVE sets it when what he carries changes, and not once the
; game is won. The panel's drawing (COLOUR_PANEL) comes in at SHOW_CARRIED_NOW
; to draw them regardless.
;
; The panel shows the three slots CARRIED, the one after it, and CARRIED_LAST
; (four bytes each: the graphic first), in three boxes 24 pixels square at the
; bottom left of the screen, at pixel x 8, 32 and 56, y 0. For each, the box is
; cleared in the buffer (FILL_BOX), the thing's sprite drawn there through the
; spare record at PANEL_RECORD (by the entry into CALC_PIXEL_XY_AND_RENDER past
; the projection, with the mirror bit clear), and the box copied to the screen
; (BLIT_TO_SCREEN); then its three by three attribute cells are coloured by the
; graphic's low four bits, from CARRIED_COLOURS, which gives each of the four
; kinds of valve its own colour. An empty slot is cleared, and coloured as if
; graphic 0. As Pentagram's SHOW_CARRIED; Knight Lore's does the same with more
; routines.
SHOW_CARRIED:
  LD A,(WON)              ; not once the game is won
  AND A                   ;
  RET NZ                  ;
  LD A,(PANEL_DUE)        ; nothing has changed; or clear the flag
  AND A                   ;
  RET Z                   ;
  XOR A                   ;
  LD (PANEL_DUE),A        ;
; This entry point is used by the routine at COLOUR_PANEL.
SHOW_CARRIED_NOW:
  PUSH IX                 ; IX = the spare record; three boxes; HL = the first
  LD IX,PANEL_RECORD      ; slot shown
  LD B,$03                ;
  LD HL,CARRIED           ;
SHOW_CARRIED_BOX:
  PUSH BC                 ; the box's pixel x: 8 + 24 times its number; pixel y
  PUSH HL                 ; 0, the bottom of the screen
  LD A,B                  ;
  NEG                     ;
  ADD A,$03               ;
  SLA A                   ;
  SLA A                   ;
  SLA A                   ;
  LD C,A                  ;
  SLA A                   ;
  ADD A,C                 ;
  ADD A,$08               ;
  LD (IX+$1A),A           ;
  LD (IX+$1B),$00         ;
  LD C,(IX+$1A)           ; clear three bytes by 24 rows of the buffer
  LD B,(IX+$1B)           ;
  PUSH HL                 ;
  CALL CALC_VIDBUF_ADDR   ;
  LD L,C                  ;
  LD H,B                  ;
  LD BC,$0318             ;
  XOR A                   ;
  CALL FILL_BOX           ;
  POP HL                  ; something there: its sprite into the buffer, not
  LD A,(HL)               ; mirrored
  AND A                   ;
  JR Z,SHOW_CARRIED_0     ;
  RES 6,(IX+$07)          ;
  LD (IX+$00),A           ;
  CALL PRINT_SPRITE       ;
SHOW_CARRIED_0:
  LD C,(IX+$1A)           ; copy the box from the buffer to the screen
  LD B,(IX+$1B)           ;
  CALL CALC_VRAM_ADDR     ;
  CALL CALC_VIDBUF_ADDR   ;
  LD L,C                  ;
  LD H,B                  ;
  LD BC,$1803             ;
  CALL BLIT_TO_SCREEN     ;
  POP HL                  ; C = the colour for the slot's graphic
  POP BC                  ;
  PUSH BC                 ;
  PUSH HL                 ;
  LD A,(HL)               ;
  AND $0F                 ;
  LD E,A                  ;
  LD D,$00                ;
  LD HL,CARRIED_COLOURS   ;
  ADD HL,DE               ;
  LD C,(HL)               ;
  LD L,(IX+$1A)           ; DE = the attribute address of the box's top row, 23
  LD A,(IX+$1B)           ; pixels up
  ADD A,$17               ;
  LD H,A                  ;
  CALL CALC_ATTRIB_ADDR   ;
  EX DE,HL                ;
  LD A,C                  ; colour three cells by three
  LD BC,$0303             ;
  CALL FILL_BOX           ;
  POP HL                  ; the next slot, four bytes on
  POP BC                  ;
  INC HL                  ;
  INC HL                  ;
  INC HL                  ;
  INC HL                  ;
  DJNZ SHOW_CARRIED_BOX   ;
  POP IX                  ; IX back
  RET                     ;

; The colours of the carried things
;
; Four attributes, indexed by the low four bits of a carried thing's graphic
; (SHOW_CARRIED): bright red, magenta, cyan and white ink on black, for the
; valves of graphics 96 to 99. Only valves can be carried (CAN_PICK_UP).
; sna2ctl took them for text, since they are the codes of four capital letters.
CARRIED_COLOURS:
  DEFB $42,$43,$45,$47    ; Graphics 96, 97, 98 and 99

; A spare object record, for drawing on the panel and the border
;
; Never one of the room's objects: SHOW_CARRIED draws the carried things
; through it, and DISPLAY_PANEL and PRINT_BORDER the panel's frame and the
; border. They set its graphic (+0), its flags (+7) and its pixel position
; (+$1A, +$1B), and the sprite drawing (the entry into CALC_PIXEL_XY_AND_RENDER
; past the projection) writes +$18 and +$19. Zero on the tape.
PANEL_RECORD:
  DEFS $20

; Is the pick-up control pressed?
;
; Used by the routine at TAKE_OR_LEAVE.
;
; The pick-up bit is bit 4 of INPUT, except with a joystick and bit 3 of
; CONTROL (directional control) set, when it is taken from bit 5: then a
; joystick's down is a direction, and READ_CONTROLS sets bit 5 from any key but
; the number keys, CAPS SHIFT and SPACE instead. As Knight Lore's
; chk_pickup_drop.
;
; O:F Z clear if it is
; O:A bit 4 set if it is
CHK_PICKUP_DROP:
  LD HL,CONTROL           ; the method, bits 1-2 of CONTROL
  LD A,(HL)               ;
  AND $06                 ;
  LD A,(INPUT)            ; this turn's controls; the keyboard: bit 4 as it is
  JR Z,CHK_PICKUP_DROP_0  ;
  BIT 3,(HL)              ; a joystick without directional control: bit 4 as it
  JR Z,CHK_PICKUP_DROP_0  ; is
  RRCA                    ; a joystick with it: bit 5 moves into bit 4
CHK_PICKUP_DROP_0:
  AND $10                 ; the pick-up bit
  RET                     ;

; Pick up, or put down
;
; Used by the routine at PLAYER_LEGS.
;
; Called from the legs' update routine (PLAYER_LEGS) every turn. One press does
; one thing: pick up a valve he is on or beside; failing that, put down the
; last of the things he carries (CARRIED_LAST), under himself, so that he
; stands on it; and if there is nothing in that slot, move what he carries one
; slot along towards it. TAKE_HELD latches the press, so holding the key does
; nothing more, and every press that gets past the tests below beeps
; (PLAIN_BEEP). Knight Lore's handle_pickup_drop and the routines after it,
; joined into one, as in Pentagram.
;
; Nothing happens unless he is inside the room's walls (CHK_PLYR_OOB, not in a
; doorway), not jumping (bit 3 of +$0C) and standing on something (bit 2).
; Before anything else it looks for an object in the space he would fill if he
; were lifted 12 units (DO_ANY_OBJS_INTERSECT): if there is one, NO_HEADROOM is
; set and nothing is put down, because putting something down lifts him 12
; units onto it.
;
; Only the two records at VALVES are looked at, for a thing to pick up and for
; a record to put one down in: the records that hold what lies in the room from
; the table of places (PLACES). So only a valve that lies in its place can be
; picked up, and a thing can be put down only while one of the two is empty: a
; room holds at most two valves.
;
; He carries up to three things, in the four-byte slots CARRIED (the newest),
; the one after, and CARRIED_LAST (the oldest, put down next): the graphic, the
; flags from +7, and the address of the thing's place (PLACES). CARRIED_NEW is
; a fourth slot in front of them, where a thing just picked up waits for the
; slots to be moved along. They behave as a queue, and a press that puts
; nothing down moves them along: one thing carried takes three presses to reach
; CARRIED_LAST and a fourth to be put down (measured by the build's sessions:
; see the notes' driving recipe).
;
; IX the robot's legs (OBJECTS)
TAKE_OR_LEAVE:
  LD A,(TAKE_HELD)        ; the key is still held from the last press: wait for
  AND A                   ; it to go up
  JP NZ,WAIT_TAKE_RELEASE ;
  CALL CHK_PICKUP_DROP    ; not pressed: nothing to do
  RET Z                   ;
  CALL CHK_PLYR_OOB       ; only inside the room's walls
  RET NC                  ;
  BIT 3,(IX+$0C)          ; not while jumping (bit 3 of +$0C); only when
  RET NZ                  ; standing on something (bit 2)
  BIT 2,(IX+$0C)          ;
  RET Z                   ;
  XOR A                      ; anything in the space he would fill lifted by
  LD (NO_HEADROOM),A         ; 12? His Z is raised to look, with the legs as
  LD A,(IX+$03)              ; high as the whole robot (PLAYER_LEGS), then put
  LD B,A                     ; back
  ADD A,$0C                  ;
  LD (IX+$03),A              ;
  CALL DO_ANY_OBJS_INTERSECT ;
  LD (IX+$03),B              ;
  JR NC,TAKE_OR_LEAVE_0      ;
  LD A,$01                ; yes: there is no room for him to stand on what he
  LD (NO_HEADROOM),A      ; puts down
TAKE_OR_LEAVE_0:
  CALL PLAIN_BEEP         ; beep; latch the key, and have the panel's carried
  LD A,$01                ; things redrawn (SHOW_CARRIED)
  LD (TAKE_HELD),A        ;
  LD (PANEL_DUE),A        ;
  LD B,$02                ; each half-size 4 more, so that a thing just out of
  LD L,(IX+$04)           ; reach counts; the old ones go on the stack
  LD A,L                  ;
  ADD A,$04               ;
  LD (IX+$04),A           ;
  LD H,(IX+$05)           ;
  LD A,H                  ;
  ADD A,$04               ;
  LD (IX+$05),A           ;
  PUSH HL                 ;
  LD L,(IX+$06)           ;
  LD A,L                  ;
  ADD A,$04               ;
  LD (IX+$06),A           ;
  PUSH HL                 ;
  LD IY,VALVES            ; the two records of what lies in the room: the first
TAKE_OR_LEAVE_1:
  CALL CAN_PICK_UP        ; that can be picked up (CAN_PICK_UP) is taken
  JP C,PICK_UP_VALVE      ;
  LD DE,$0020             ;
  ADD IY,DE               ;
  DJNZ TAKE_OR_LEAVE_1    ;
  CALL CHK_PICKUP_DROP    ; nothing to pick up. This test cannot fail: INPUT
  JR Z,TAKE_DONE          ; has not changed since the same test at the start
  LD B,$02                ; the first empty record of the two, to put a thing
  LD IY,VALVES            ; down in; none: nothing is put down
  LD DE,$0020             ;
TAKE_OR_LEAVE_2:
  LD A,(IY+$00)           ;
  AND A                   ;
  JR Z,PUT_DOWN_LAST      ;
  ADD IY,DE               ;
  DJNZ TAKE_OR_LEAVE_2    ;
TAKE_DONE:
  POP HL                  ; his half-sizes back
  LD (IX+$06),L           ;
  POP HL                  ;
  LD (IX+$04),L           ;
  LD (IX+$05),H           ;
  RET                     ;
WAIT_TAKE_RELEASE:
  CALL CHK_PICKUP_DROP    ; clear the latch once the key is up
  RET NZ                  ;
  XOR A                   ;
  LD (TAKE_HELD),A        ;
  RET                     ;
; Put down the last thing he carries, into the empty record at IY.
PUT_DOWN_LAST:
  LD HL,CARRIED_LAST      ; nothing in the last slot: just move the slots along
  LD A,(HL)               ;
  INC HL                  ;
  AND A                   ;
  JR Z,SHIFT_CARRIED      ;
  LD A,(NO_HEADROOM)      ; no headroom: put nothing down
  AND A                   ;
  JR NZ,TAKE_DONE         ;
  DEC HL                  ; the thing's graphic into the empty record; HL on to
  LD A,(HL)               ; the slot's flags
  INC HL                  ;
  LD (IY+$00),A           ;
  PUSH HL                 ; U, V and Z from the robot's legs, so that it goes
  LD BC,$0003             ; down where he stands
  PUSH IX                 ;
  POP HL                  ;
  PUSH IY                 ;
  POP DE                  ;
  INC DE                  ;
  INC HL                  ;
  LDIR                    ;
  LD A,(IX+$03)           ; lift both of his records by 12, the thing's height,
  ADD A,$0C               ; so that he stands on it
  LD (IX+$03),A           ;
  LD A,(IX+$23)           ;
  ADD A,$0C               ;
  LD (IX+$23),A           ;
  CALL CALC_PIXEL_XY_IY   ; its place on the screen (CALC_PIXEL_XY_IY)
; Fill in the record of a thing put down: IY the record, its graphic and
; position already set; the slot's flags byte on the stack.
FILL_PUT_DOWN:
  LD (IY+$04),$05         ; half-sizes 5, 5 and 12
  LD (IY+$05),$05         ;
  LD (IY+$06),$0C         ;
  POP HL                  ; +7 the flags from the slot; +8 the room, the
  LD A,(HL)               ; robot's
  INC HL                  ;
  LD (IY+$07),A           ;
  LD A,(IX+$08)           ;
  LD (IY+$08),A           ;
  LD A,(HL)               ; +$10 and +$11: the address of its place, from the
  INC HL                  ; slot. The place itself is not written: when he
  LD (IY+$10),A           ; leaves the room UPDATE_SPECIAL_OBJS copies where
  LD A,(HL)               ; the valve now lies into it
  LD (IY+$11),A           ;
  SET 0,(IY+$0D)          ; bit 0 of +$0D: just put down, which the valve's
                          ; update routine (LOOSE_VALVE) reads once
; Move the carried things one slot along.
SHIFT_CARRIED:
  LD HL,$5B83             ; twelve bytes up by four, copied from the top down
  LD DE,$5B87             ; so that they do not overwrite themselves:
  LD BC,$000C             ; CARRIED_NEW moves into CARRIED, and so on to
  LDDR                    ; CARRIED_LAST
  LD DE,CARRIED_NEW       ; CARRIED_NEW is empty
  LD B,$04                ;
  CALL ZERO_DE            ;
  JP TAKE_DONE            ;
; Pick up the valve at IY.
PICK_UP_VALVE:
  LD HL,CARRIED_NEW       ; picking something up lets the things on the ceiling
  XOR A                   ; drop (DROP_LATCH)
  LD (DROP_LATCH),A       ;
  LD A,(IY+$00)           ; graphic, flags and place's address into
  LD (HL),A               ; CARRIED_NEW; the place's graphic zeroed, so that
  INC HL                  ; the valve is not put back in its room when he
  LD A,(IY+$07)           ; leaves or comes back
  LD (HL),A               ;
  INC HL                  ;
  LD E,(IY+$10)           ;
  LD D,(IY+$11)           ;
  XOR A                   ;
  LD (DE),A               ;
  LD (HL),E               ;
  INC HL                  ;
  LD (HL),D               ;
  CALL SET_WIPE_AND_DRAW_IY ; mark it to be rubbed out (SET_WIPE_AND_DRAW_IY),
  LD (IY+$00),$01           ; and make it graphic 1, which the drawing code
                            ; rubs out and then empties
  LD HL,CARRIED_LAST      ; carrying nothing in the last slot: move the slots
  LD A,(HL)               ; along
  INC HL                  ;
  AND A                   ;
  JR Z,SHIFT_CARRIED      ;
  LD (IY+$00),A           ; three: the oldest goes down where this one was, in
  PUSH HL                 ; the same record -- picking up swaps (this never ran
  JR FILL_PUT_DOWN        ; in the build's sessions)

; Can this thing be picked up?
;
; Used by the routine at TAKE_OR_LEAVE.
;
; Only a valve (graphics 96 to 99), and only when he is on or beside it:
; IS_ON_OR_NEAR_OBJ, their boxes overlapping in U and V, and in Z with him
; lowered by 4, so that a thing he stands on counts as touching. The caller
; (TAKE_OR_LEAVE) has made his box 4 bigger each way. Knight Lore's
; can_pickup_spec_obj and is_on_or_near_obj together; EXTRA_LIFE uses the
; second alone.
;
;   IX the robot's legs
;   IY the thing
; O:F carry set if it can
CAN_PICK_UP:
  LD A,(IY+$00)           ; a valve, graphic 96 to 99; otherwise no carry
  SUB $60                 ;
  CP $04                  ;
  RET NC                  ;
; This entry point is used by the routine at EXTRA_LIFE.
IS_ON_OR_NEAR_OBJ:
  PUSH BC                     ; overlapping in U and V (DO_OBJS_INTERSECT_ON_U,
  LD BC,$0000                 ; DO_OBJS_INTERSECT_ON_V), with no offset
  LD L,C                      ;
  LD H,C                      ;
  CALL DO_OBJS_INTERSECT_ON_U ;
  JR NC,CAN_PICK_UP_0         ;
  CALL DO_OBJS_INTERSECT_ON_V ;
  JR NC,CAN_PICK_UP_0         ;
  LD A,(IX+$03)               ; in Z (DO_OBJS_INTERSECT_ON_Z), with him 4
  SUB $04                     ; lower, then put back
  LD (IX+$03),A               ;
  CALL DO_OBJS_INTERSECT_ON_Z ;
  PUSH AF                     ;
  LD A,(IX+$03)               ;
  ADD A,$04                   ;
  LD (IX+$03),A               ;
  POP AF                      ;
CAN_PICK_UP_0:
  POP BC                  ; BC kept
  RET                     ;

; Is the object moving?
;
; Used by the routines at REMOTE_ROBOT, LOOSE_VALVE, PUSHABLE and EXTRA_LIFE.
;
; As Knight Lore's is_obj_moving.
;
;   IX the object
; O:F Z set if its steps in U, V and Z (+$09 to +$0B) are all zero
IS_OBJ_MOVING:
  LD A,(IX+$09)
  OR (IX+$0A)
  OR (IX+$0B)
  RET

; The update routine for an extra life (graphic 12)
;
; Reached through UPDATES. A place given graphic 12 at a new game
; (INIT_SPECIAL_OBJECTS) is an extra life, put in one of the two place records
; as its room is built (FIND_SPECIAL_OBJS_HERE). If the robot's legs touch it
; -- their box widened by 1 in U and V -- it becomes graphic 64, the first of a
; two-frame vanish (SPARKLE_STEP, SPARKLE_END_PLACE), its place is emptied so
; it never comes back, the drop latch is cleared, and LIVES goes up by one, is
; reprinted on the panel and copied to the screen. Either way it then falls and
; settles like other things. As Knight Lore's upd_103, the extra life, but
; through the table of places rather than Knight Lore's special-object table.
;
; IX the extra life's record
EXTRA_LIFE:
  CALL DRAW_AT_L8_D2      ; the drawing nudge: X -8, Y -2
  PUSH IX                 ; IY = the extra life; IX = the robot's legs
  POP IY                  ;
  LD IX,OBJECTS           ;
  INC (IX+$04)            ; touching, with the legs 1 wider in U and V? The
  INC (IX+$05)            ; legs back as they were, and IX back
  CALL IS_ON_OR_NEAR_OBJ  ;
  DEC (IX+$04)            ;
  DEC (IX+$05)            ;
  PUSH IY                 ;
  POP IX                  ;
  JR NC,EXTRA_LIFE_FALL   ;
  LD (IX+$00),$40         ; graphic 64, the vanish, with its drawing nudge
  CALL DRAW_AT_L12_D4     ;
  LD L,(IX+$10)           ; its place emptied for good
  LD H,(IX+$11)           ;
  XOR A                   ;
  LD (HL),A               ;
  LD (DROP_LATCH),A       ; the things on the ceiling may drop again
  LD HL,LIVES             ; one more life
  INC (HL)                ;
  CALL PLAIN_BEEP         ; beep, print the lives into the buffer and copy them
  CALL PRINT_LIVES        ; to the screen, at pixel x 128, y 0 (BLIT_2X8)
  LD BC,$0080             ;
  CALL BLIT_2X8           ;
EXTRA_LIFE_FALL:
  CALL DEC_DZ_AND_UPDATE_UVZ ; fall and move; not moving: done
  CALL IS_OBJ_MOVING         ;
  RET Z                      ;
  CALL CLEAR_DUV          ; moving: no step in U or V next turn; a sound and a
  JP SOUND_AND_DRAW       ; redraw (SPARKLE_END_PLACE)

; Copy a 16 by 8 pixel patch from the buffer to the screen
;
; Used by the routines at LOOSE_VALVE and EXTRA_LIFE.
;
; Works out the screen address (CALC_VRAM_ADDR) and the buffer address
; (CALC_VIDBUF_ADDR) of the position, then copies 8 rows of 2 bytes
; (BLIT_TO_SCREEN). Used for the lives (EXTRA_LIFE) and the chambers activated
; (LOOSE_VALVE), which change without the whole screen being redrawn. As Knight
; Lore's blit_2x8.
;
; B the pixel row of its bottom, counted from the bottom of the screen
; C the pixel column
BLIT_2X8:
  CALL CALC_VRAM_ADDR
  CALL CALC_VIDBUF_ADDR
  LD L,C
  LD H,B
  LD BC,$0802
  JP BLIT_TO_SCREEN

; Drawing nudge X -16, Y -9 (graphic 30)
;
; Used by the routines at LEAPER, REMOTE_ROBOT, REMOTE_PAD, REMOTE_BUTTON,
; SHUTTLE_U, CONVEYOR_PLUS_V, COLLAPSING_BLOCK, STILL_DEADLY, DROPPING_BLOCK,
; PUSHABLE and LIFT.
;
; A note for all the nudge routines from here to DRAW_AT_L8_D2: +$12 and +$13
; of an object record are added to the pixel position the projection
; (CALC_PIXEL_XY) works out from the object's U, V and Z, to line the sprite up
; with the object's position. X is pixels right and Y pixels up, so the usual
; negative values move the sprite left and down. For a still object that is all
; its update routine does; others call one to set the nudge before they move.
; They all end at SET_PIXEL_ADJ, in DRAW_AT_L4_D3. Knight Lore calls these
; drawing offsets.
;
; This one is the whole update routine for graphic 30 (UPDATES), the only piece
; of object template 1 and of backgrounds 12 and 13, and is called by the
; update routines of graphics 28, 44, 45, 47, 66, 68, 72, 75, 122 to 128 and
; 130.
DRAW_AT_L16_D9:
  LD HL,$F7F0             ; Left 16, down 9
  JR SET_PIXEL_ADJ

; Unreached code: drawing nudge X -12, Y -9
;
; A LD HL and a JR to SET_PIXEL_ADJ (DRAW_AT_L4_D3) like the routines round it,
; which nothing calls, jumps to or lists in the update table (UPDATES); the
; code map leaves it as data.
UNUSED_NUDGE_L12_D9:
  DEFB $21,$F4,$F7        ; LD HL: left 12, down 9; JR to SET_PIXEL_ADJ
  DEFB $18,$30            ;

; Drawing nudge X -12, Y -8
;
; Used by the routines at CEILING_DROP, PLAYER_APPEARING and PLAYER_APPEARED.
;
; The robot appearing (PLAYER_APPEARING, PLAYER_APPEARED), and the things that
; drop from the ceiling (CEILING_DROP).
DRAW_AT_L12_D8:
  LD HL,$F8F4             ; Left 12, down 8
  JR SET_PIXEL_ADJ

; Drawing nudge X -16, Y -7
;
; Used by the routines at SOCKET, PLAYER_LEGS and TURNING_LEGS.
;
; The robot's legs (PLAYER_LEGS, TURNING_LEGS), and the sockets (SOCKET).
DRAW_AT_L16_D7:
  LD HL,$F9F0             ; Left 16, down 7
  JR SET_PIXEL_ADJ

; Drawing nudge X -12, Y -7 (graphic 13)
;
; The whole update routine for graphic 13 (UPDATES), the longest of the thin
; pieces -- a half-size of 12 along, none across, 48 high -- that backgrounds 4
; to 9 are built of.
DRAW_AT_L12_D7:
  LD HL,$F9F4             ; Left 12, down 7
  JR SET_PIXEL_ADJ

; Drawing nudge X -16, Y -6
;
; Used by the routine at PUSHABLE_INVERTED.
;
; Graphic 29 (PUSHABLE_INVERTED).
DRAW_AT_L16_D6:
  LD HL,$FAF0             ; Left 16, down 6
  JR SET_PIXEL_ADJ

; Drawing nudge X -12, Y -6
;
; Used by the routines at CLOCKWORK_MOUSE, LOWER_HALF, WANDERER and PACER.
;
; The update routines of graphics 11, 86, 87, 94, 95 and 116 to 119
; (LOWER_HALF, PACER, WANDERER, CLOCKWORK_MOUSE).
DRAW_AT_L12_D6:
  LD HL,$FAF4             ; Left 12, down 6
  JR SET_PIXEL_ADJ

; Drawing nudge X -12, Y -5
;
; Used by the routines at WANTED_VALVE, SOCKET_SPARKLE, SEATED_VALVE and
; LOOSE_VALVE.
;
; The valves (LOOSE_VALVE) and graphics 100 to 111 (SEATED_VALVE, WANTED_VALVE,
; SOCKET_SPARKLE).
DRAW_AT_L12_D5:
  LD HL,$FBF4             ; Left 12, down 5
  JR SET_PIXEL_ADJ

; Drawing nudge X -8, Y -5 (graphic 15)
;
; The whole update routine for graphic 15 (UPDATES), a short thin piece of
; backgrounds 8 and 9.
DRAW_AT_L8_D5:
  LD HL,$FBF8             ; Left 8, down 5
  JR SET_PIXEL_ADJ

; Drawing nudge X -12, Y -4
;
; Used by the routines at FRAGILE, SLOW_CHASER, CRYONAUT, SPARK_CHASER, SPIKES,
; SPARKLE_STEP, SPARKLE_END_PLACE and EXTRA_LIFE.
;
; The sparkle (SPARKLE_STEP, SPARKLE_END_PLACE), the vanishing extra life
; (EXTRA_LIFE), and the update routines of graphics 46, 74, 76 to 79, 120, 121
; and 129.
DRAW_AT_L12_D4:
  LD HL,$FCF4             ; Left 12, down 4
  JR SET_PIXEL_ADJ

; Drawing nudge X -16, Y -3
;
; Used by the routine at TOP_FOLLOWS_LEGS.
;
; The robot's top (TOP_FOLLOWS_LEGS).
DRAW_AT_L16_D3:
  LD HL,$FDF0             ; Left 16, down 3
  JR SET_PIXEL_ADJ

; Drawing nudge X -4, Y -3 (graphic 14)
;
; The whole update routine for graphic 14 (UPDATES), the short thin piece at
; the end of a row of DRAW_AT_L12_D7's in backgrounds 4, 5, 8 and 9.
DRAW_AT_L4_D3:
  LD HL,$FDFC             ; Left 4, down 3
; This entry point is used by the routines at DRAW_AT_L16_D9, DRAW_AT_L12_D8,
; DRAW_AT_L16_D7, DRAW_AT_L12_D7, DRAW_AT_L16_D6, DRAW_AT_L12_D6,
; DRAW_AT_L12_D5, DRAW_AT_L8_D5, DRAW_AT_L12_D4, DRAW_AT_L16_D3, DRAW_AT_L8_D2,
; SECOND_PILLAR and FIRST_PILLAR.
SET_PIXEL_ADJ:
  LD (IX+$12),L           ; The shared end of all the nudge routines: L to
  LD (IX+$13),H           ; +$12, H to +$13
  RET                     ;

; Drawing nudge X -8, Y -2
;
; Used by the routine at EXTRA_LIFE.
;
; The extra life (EXTRA_LIFE).
DRAW_AT_L8_D2:
  LD HL,$FEF8             ; Left 8, down 2
  JR SET_PIXEL_ADJ

; Fill a box of bytes, B wide and C rows high, with A
;
; Used by the routines at COLOUR_PANEL, SHOW_CARRIED, BORDER_DATA and
; RENDER_DYNAMIC_OBJECTS.
;
; Fills B bytes along from HL, then moves 32 bytes on to the next row, C times:
; in the buffer that is up the screen, in the attribute file down. The row is
; eight unrolled stores (FILL_BOX_STORES), and the routine rewrites the
; displacement of the JR at FILL_BOX_ROW so that it lands on the last B of them
; -- on the tape the JR jumps to itself, and it is always rewritten before it
; runs. Used to clear the carried things' boxes and colour them (SHOW_CARRIED),
; for the panel (COLOUR_PANEL) and by RENDER_DYNAMIC_OBJECTS.
;
; HL the first byte: the box's bottom-left in the buffer, or its top-left in
;    the attribute file
; A the byte to fill with
; B the width in bytes, 1 to 8
; C how many rows
FILL_BOX:
  PUSH AF                 ; the displacement: twice (8 - B) modulo 8, into the
  LD A,B                  ; JR's second byte
  NEG                     ;
  AND $07                 ;
  ADD A,A                 ;
  LD ($BF96),A            ;
  LD A,$20                ; DE = 32 - B, from the end of one row to the start
  SUB B                   ; of the next
  LD E,A                  ;
  LD D,$00                ;
  LD B,C                  ; B = the rows
  POP AF                  ;
; This entry point is used by the routine at FILL_BOX_STORES.
FILL_BOX_ROW:
  JR FILL_BOX_ROW         ; into the stores, B from the end (rewritten above)

; The eight stores of FILL_BOX
;
; Entered only by the JR at the end of FILL_BOX, part way down, so that the
; last B stores run. The DJNZ goes back to that JR for the next row.
FILL_BOX_STORES:
  LD (HL),A               ; eight stores, each one byte on
  INC HL                  ;
  LD (HL),A               ;
  INC HL                  ;
  LD (HL),A               ;
  INC HL                  ;
  LD (HL),A               ;
  INC HL                  ;
  LD (HL),A               ;
  INC HL                  ;
  LD (HL),A               ;
  INC HL                  ;
  LD (HL),A               ;
  INC HL                  ;
  LD (HL),A               ;
  INC HL                  ;
  ADD HL,DE               ; on to the next row; C rows in all
  DJNZ FILL_BOX_ROW       ;
  RET                     ;

; Mark an object to be rubbed out and redrawn
;
; Used by the routines at LEAPER, OILED_ROBOT, REMOTE_ROBOT, SCENE_TOOL,
; SCENE_SPARKS, CEILING_DROP, SET_WIPE_AND_DRAW_IY, WANTED_VALVE,
; SOCKET_SPARKLE, LOOSE_VALVE, LOWER_HALF, SHUTTLE_U, DEADLY_AND_DRAW,
; DROPPING_BLOCK, PUSHABLE, LIFT, SPARKLE_STEP, SPARKLE_END_PLACE,
; PLAYER_APPEARING and PLAYER_LEGS.
;
; Sets bits 4 and 5 of +7 -- draw it, and rub out where it was -- and marks
; every object its old or new rectangle touches (SET_DRAW_OBJS_OVERLAPPED). The
; end of most update routines that move or change their object. As Knight
; Lore's set_wipe_and_draw_flags; SET_WIPE_AND_DRAW_IY does the same for the
; record at IY.
;
; IX the object
SET_WIPE_AND_DRAW_FLAGS:
  LD A,(IX+$07)
  OR $30
  LD (IX+$07),A
  JP SET_DRAW_OBJS_OVERLAPPED

; Fall, and move
;
; Used by the routines at LEAPER, REMOTE_ROBOT, SLOW_CHASER, CLOCKWORK_MOUSE,
; CEILING_DROP, LOOSE_VALVE, WANDERER, PACER, SPARK_CHASER, SHUTTLE_U,
; DROPPING_BLOCK, PUSHABLE, LIFT and EXTRA_LIFE.
;
; Takes one off the step in Z -- the pull of gravity -- then lets
; ADJ_FOR_OUT_OF_BOUNDS cut the steps down to what fits, and adds what is left
; to the position. The player's move (MOVE_PLAYER) comes in at ADD_DUVZ, having
; cut the move itself. As Pentagram's DEC_DZ_AND_UPDATE_UVZ; Knight Lore's
; add_dXYZ.
;
; IX the object
DEC_DZ_AND_UPDATE_UVZ:
  DEC (IX+$0B)            ; gravity
  CALL ADJ_FOR_OUT_OF_BOUNDS ; cut the move short where it has to be
; This entry point is used by the routine at MOVE_PLAYER.
ADD_DUVZ:
  LD A,(IX+$01)           ; U, V and Z (+$01 to +$03) plus the step in each
  ADD A,(IX+$09)          ; (+$09 to +$0B)
  LD (IX+$01),A           ;
  LD A,(IX+$02)           ;
  ADD A,(IX+$0A)          ;
  LD (IX+$02),A           ;
  LD A,(IX+$03)           ;
  ADD A,(IX+$0B)          ;
  LD (IX+$03),A           ;
  RET                     ;

; The update routine for the second pillar of a doorway (graphic 3)
;
; Reached through UPDATES. A doorway is two pillars, graphics 2 and 3, from one
; background (BACKGROUND_TABLE: backgrounds 0 to 3, 10 and 11), and this one
; only sets its drawing nudge: the first pillar (FIRST_PILLAR) does the work. A
; doorway in a wall of constant V is mirrored (bit 6 of its flags); one in a
; wall of constant U is not. As Knight Lore's upd_3_5 and Pentagram's
; SECOND_PILLAR.
;
; IX the pillar's record
SECOND_PILLAR:
  BIT 6,(IX+$07)               ; Mirrored?
  JR NZ,SECOND_PILLAR_MIRRORED ;
  LD HL,$FBF0             ; Not mirrored: X -16, Y -5
  JP SET_PIXEL_ADJ        ;
SECOND_PILLAR_MIRRORED:
  LD HL,$FCF8             ; Mirrored: X -8, Y -4
  JP SET_PIXEL_ADJ        ;

; The update routine for the first pillar of a doorway (graphic 2)
;
; Reached through UPDATES. This pillar is the doorway. It works out the point
; in the middle of the doorway, 13 from itself along the wall, and keeps it in
; its own +$09 to +$0B -- the step fields, which a pillar never needs, borrowed
; because IS_NEAR_TO compares +$09 to +$0B of one record with +$01 to +$03 of
; another. Then CHK_PLYR_NEAR_ARCH marks the robot's legs as in the doorway if
; they are near enough, which lets them past the line of the wall
; (HANDLE_EXIT_SCREEN), and ARCH_NUDGE_TO_CENTRE nudges him onto the doorway's
; middle line if he is near it and facing through.
;
; A doorway in a wall of constant U (not mirrored) has its other pillar 13
; further along V, and reaches 15 either way in U and 6 in V; one in a wall of
; constant V (mirrored) has its other pillar 13 back along U, and reaches 6 in
; U and 15 in V. The backgrounds put the middle of every doorway at 128 along
; its wall.
;
; As Knight Lore's adj_2_4_hflip and the routines after it, and Pentagram's
; FIRST_PILLAR. The nudge differs from both: see NUDGE_ALONG_V.
;
; IX the pillar's record
FIRST_PILLAR:
  BIT 6,(IX+$07)          ; Mirrored: a doorway in a wall of constant V
  JR NZ,ARCH_ALONG_V      ;
  LD HL,$F9FA             ; Not mirrored: X -6, Y -7
  CALL SET_PIXEL_ADJ      ;
  LD A,(IX+$02)           ; V of the middle: this pillar's plus 13
  ADD A,$0D               ;
  LD (IX+$0A),A           ;
  LD A,(IX+$01)           ; U of the middle: this pillar's
  LD (IX+$09),A           ;
  LD HL,$060F             ; In the doorway: U within 15, V within 6
ARCH_CHECK_DOORWAY:
  LD A,(IX+$03)           ; Z of the middle: the pillar's base
  LD (IX+$0B),A           ;
  CALL CHK_PLYR_NEAR_ARCH ; In the doorway: the legs may cross the line of the
                          ; wall
  JP ARCH_NUDGE_TO_CENTRE ; Near it: nudge towards the middle
ARCH_ALONG_V:
  LD HL,$FAF6             ; Mirrored: X -10, Y -6
  CALL SET_PIXEL_ADJ      ;
  LD A,(IX+$01)           ; U of the middle: this pillar's less 13
  SUB $0D                 ;
  LD (IX+$09),A           ;
  LD A,(IX+$02)           ; V of the middle: this pillar's
  LD (IX+$0A),A           ;
  LD HL,$0F06             ; In the doorway: U within 6, V within 15
  JR ARCH_CHECK_DOORWAY   ;
; Nudge the robot towards the middle line of the doorway: if his legs, record
; 0, are in use, use doorways (bit 3 of +7), and are within 15 of the middle in
; U and V and 4 in Z, one of the routines in NUDGE_ROUTINES is run, picked by
; the pillar's own facing (GET_SPRITE_DIR). Knight Lore does this for each of
; records 0 to 3; here only the legs are nudged, as in Pentagram.
ARCH_NUDGE_TO_CENTRE:
  LD HL,$0F0F             ; 15 either way in U and V
  LD IY,OBJECTS           ; the robot's legs, if there are any
  LD A,(IY+$00)           ;
  AND A                   ;
  RET Z                   ;
  BIT 3,(IY+$07)          ; not one that uses doorways
  RET Z                   ;
  CALL IS_NEAR_TO         ; not near
  RET NC                  ;
  PUSH BC                 ; the nudge routine for the pillar's facing; the BC
  LD BC,NUDGE_ROUTINES    ; pushed here is taken off again at NUDGE_DONE
  JP DISPATCH_ON_FACING   ;

; The doorway's nudge routines, by the pillar's facing
;
; Four words indexed by the first pillar's facing (GET_SPRITE_DIR, used by
; FIRST_PILLAR): 0 and 1 not mirrored, 2 and 3 mirrored. A pillar is graphic 2,
; whose bit 2 is clear, so only entries 0 and 2 are ever used; 1 and 3 repeat
; them.
NUDGE_ROUTINES:
  DEFW NUDGE_ALONG_V      ; Facings 0 and 1, not mirrored: NUDGE_ALONG_V, along
  DEFW NUDGE_ALONG_V      ; V; 2 and 3, mirrored: NUDGE_ALONG_U, along U
  DEFW NUDGE_ALONG_U      ;
  DEFW NUDGE_ALONG_U      ;

; Nudge along V
;
; For a doorway in a wall of constant U: nothing if the robot faces along V
; (his legs mirrored) or is on the middle line already, otherwise +1 or -1 into
; +$0F of his legs, towards it, which the walk (CALC_PLYR_DUV) adds to his step
; in V when he next walks. This is why he slides into line with a doorway as he
; walks through.
;
; Only while he faces through the doorway: Knight Lore (adj_ew) and Pentagram
; (NUDGE_ALONG_V) nudge whichever way he faces.
;
; IX the pillar, holding the middle at +$09 to +$0B
; IY the robot's legs
NUDGE_ALONG_V:
  BIT 6,(IY+$07)          ; facing along V: no nudge
  JR NZ,NUDGE_DONE        ;
  LD A,(IX+$0A)           ; on the middle line already
  CP (IY+$02)             ;
  JR Z,NUDGE_DONE         ;
  LD A,$01                ; +1 if the middle is at a greater V, else -1
  JR NC,NUDGE_ALONG_V_0   ;
  NEG                     ;
NUDGE_ALONG_V_0:
  LD (IY+$0F),A           ; the V nudge
  JR NUDGE_DONE           ;

; Nudge along U
;
; For a doorway in a wall of constant V: +1 or -1 into +$0E of his legs,
; towards the middle line, while he faces along V (his legs mirrored) and is
; not on it.
;
; IX the pillar, holding the middle at +$09 to +$0B
; IY the robot's legs
NUDGE_ALONG_U:
  BIT 6,(IY+$07)          ; facing along U: no nudge
  JR Z,NUDGE_DONE         ;
  LD A,(IX+$09)           ; on the middle line already
  CP (IY+$01)             ;
  JR Z,NUDGE_DONE         ;
  LD A,$01                ; +1 if the middle is at a greater U, else -1
  JR NC,NUDGE_ALONG_U_0   ;
  NEG                     ;
NUDGE_ALONG_U_0:
  LD (IY+$0E),A           ; the U nudge
; This entry point is used by the routine at NUDGE_ALONG_V.
NUDGE_DONE:
  POP BC                  ; drop the BC FIRST_PILLAR pushed, and back to the
  RET                     ; main loop

; Is the robot in the doorway?
;
; Used by the routine at FIRST_PILLAR.
;
; If the robot's legs, record 0, are in use, use doorways (bit 3 of +7) and are
; within the doorway's limits (IS_NEAR_TO), sets bit 0 of their flags: while it
; is set the collision code lets him past the line of the wall, and his move
; (HANDLE_EXIT_SCREEN) sees whether he has walked out of the room, and clears
; it. Knight Lore's chk_plyr_spec_near_arch, which looks at records 0 to 3.
;
; IX the first pillar, holding the middle at +$09 to +$0B
; L how near in U
; H how near in V
CHK_PLYR_NEAR_ARCH:
  LD IY,OBJECTS           ; the robot's legs, if there are any
  LD A,(IY+$00)           ;
  AND A                   ;
  RET Z                   ;
  BIT 3,(IY+$07)          ; not one that uses doorways
  RET Z                   ;
  CALL IS_NEAR_TO         ; not in the doorway
  RET NC                  ;
  SET 0,(IY+$07)          ; in it: he may cross the line of the wall
  RET                     ;

; Is an object near a point?
;
; Used by the routines at FIRST_PILLAR and CHK_PLYR_NEAR_ARCH.
;
; Carry set if the object's U, V and Z are all within the limits of the point:
; strictly less than L in U, H in V and 4 in Z. As Knight Lore's is_near_to.
;
;   IX a record whose +$09 to +$0B hold the point's U, V and Z
;   IY the object
;   L the limit in U
;   H the limit in V
; O:F carry set if near
IS_NEAR_TO:
  LD A,(IX+$09)           ; U
  SUB (IY+$01)            ;
  JR NC,IS_NEAR_TO_0      ;
  NEG                     ;
IS_NEAR_TO_0:
  CP L                    ;
  RET NC                  ;
  LD A,(IX+$0A)           ; V
  SUB (IY+$02)            ;
  JR NC,IS_NEAR_TO_1      ;
  NEG                     ;
IS_NEAR_TO_1:
  CP H                    ;
  RET NC                  ;
  LD A,(IX+$0B)           ; Z: within 4 sets the carry
  SUB (IY+$03)            ;
  JR NC,IS_NEAR_TO_2      ;
  NEG                     ;
IS_NEAR_TO_2:
  CP $04                  ;
  RET                     ;

; The update routine for the robot's legs (graphics 16 to 23)
;
; Reached through UPDATES. The robot's turn, in order: read the controls
; (READ_CONTROLS), pick up or put down (TAKE_OR_LEAVE), turn
; (HANDLE_LEFT_RIGHT), start a jump (HANDLE_JUMP), step the legs' frame
; (HANDLE_FORWARD). Then, if he stands in a doorway -- past the line of the
; room's walls (CHK_PLYR_OOB) -- he may not rise, only fall. The move is
; resolved and made (MOVE_PLAYER) with the top out of the collision tests; the
; count of turns he walks on by himself after coming through a doorway goes
; down, and he is marked to be redrawn.
;
; While this runs the legs' height is 23, the whole robot's, and the top's is
; 0, so that the legs stand for the robot in the headroom test and in the move;
; at the end they are put back to 12 and 11, the top standing on the legs. The
; top's height of 0 is what keeps the headroom test from finding the top
; itself: DO_ANY_OBJS_INTERSECT takes only the legs out of its own way, and its
; test in Z (DO_OBJS_INTERSECT_ON_Z) never finds an overlap with a thing of no
; height whose base is at or below the legs'. For the move the top is taken out
; of the collision tests as well (bit 1 of its +7).
;
; If he has been killed (bit 6 of +$0D), the top is killed too and the legs
; become the sparkle (START_SPARKLE). Graphics 24 to 27, the legs part way
; through a turn, have their own update routine (TURNING_LEGS), which comes
; back in at PLAYER_LEGS_DONE.
;
; As Pentagram's PLAYER_LEGS and Knight Lore's player_controls, in a different
; order: pick-up comes before the turn here.
;
; IX the legs' record, OBJECTS
PLAYER_LEGS:
  CALL DRAW_AT_L16_D7     ; the legs' drawing nudge: X -16, Y -7
  BIT 6,(IX+$0D)          ; killed: the top too (+$0D of the next record), and
  JR Z,PLAYER_LEGS_0      ; the sparkle
  SET 6,(IX+$2D)          ;
  JP START_SPARKLE        ;
PLAYER_LEGS_0:
  LD (IX+$06),$17         ; the legs as high as the whole robot, the top of no
  LD (IX+$26),$00         ; height
  CALL READ_CONTROLS      ; the controls into C; pick up or put down, turn,
  CALL TAKE_OR_LEAVE      ; jump, step
  CALL HANDLE_LEFT_RIGHT  ;
  CALL HANDLE_JUMP        ;
  CALL HANDLE_FORWARD     ;
  CALL CHK_PLYR_OOB            ; in a doorway, beyond the walls?
  JR NC,PLAYER_LEGS_IN_DOORWAY ;
PLAYER_LEGS_MOVE:
  SET 1,(IX+$27)          ; the top (+7 of the next record) out of the
  CALL MOVE_PLAYER        ; collision tests while the legs move
  RES 1,(IX+$27)          ;
  LD A,(IX+$0C)           ; count down the top four bits of +$0C: the turns he
  SUB $10                 ; walks on by himself after coming through a doorway
  JR C,PLAYER_LEGS_DONE   ;
  LD (IX+$0C),A           ;
; This entry point is used by the routine at TURNING_LEGS.
PLAYER_LEGS_DONE:
  LD (IX+$06),$0C         ; the heights back: legs 12, top 11
  LD (IX+$26),$0B         ;
  JP SET_WIPE_AND_DRAW_FLAGS ; mark him to be redrawn
PLAYER_LEGS_IN_DOORWAY:
  LD A,(IX+$0B)           ; in a doorway: falling is allowed...
  AND A                   ;
  JP M,PLAYER_LEGS_MOVE   ;
  XOR A                   ; ...rising is not
  LD (IX+$0B),A           ;
  JR PLAYER_LEGS_MOVE     ;

; Is he inside the room's walls?
;
; Used by the routines at TAKE_OR_LEAVE and PLAYER_LEGS.
;
; Compares the object's distance from the room's centre, 128 on U and V, with
; the room's half-size in each (ROOM_HALF_U, ROOM_HALF_V) less its own
; half-size. Carry means the whole of its footprint is inside on both; no
; carry, that it touches or crosses the line of a wall, which only a doorway
; allows. As Knight Lore's chk_plyr_OOB.
;
;   IX the object, the robot's legs
; O:F carry set if it is
CHK_PLYR_OOB:
  LD HL,(ROOM_HALF_U)     ; L = the room's half-size in U less his; H = the
  LD A,L                  ; same for V
  SUB (IX+$04)            ;
  LD L,A                  ;
  LD A,H                  ;
  SUB (IX+$05)            ;
  LD H,A                  ;
  LD A,(IX+$01)           ; |U - 128|: no carry, outside
  SUB $80                 ;
  JP P,CHK_PLYR_OOB_0     ;
  NEG                     ;
CHK_PLYR_OOB_0:
  CP L                    ;
  RET NC                  ;
  LD A,(IX+$02)           ; |V - 128|
  SUB $80                 ;
  JP P,CHK_PLYR_OOB_1     ;
  NEG                     ;
CHK_PLYR_OOB_1:
  CP H                    ;
  RET                     ;

; Turn the robot
;
; Used by the routine at PLAYER_LEGS.
;
; Two ways of steering. Rotational control -- the keyboard's always, and a
; joystick's unless directional control is chosen -- turns a quarter at a time
; on the two turn controls: bit 0 of C left, bit 1 right. Directional control,
; a joystick with bit 3 of CONTROL set (key 5 on the menu), treats the controls
; as four points of the compass instead: pushing one turns the robot towards it
; and, once he faces it, walks him that way.
;
; Facings, as GET_SPRITE_DIR gives them: bit 2 of the graphic and bit 6 of the
; flags, the mirror bit, make a number 0 to 3 (the mirror bit the high bit); a
; left turn goes 0, 3, 1, 2 and round, a right turn the other way. Directional
; control reads up (bit 2) -- which faces 2 -- unless left is also held, then
; right (1), down (bit 4; 3) and left (0), and goes the short way round, or two
; turns for an about-face.
;
; A turn is not made at once, as in Knight Lore and Pentagram. The legs become
; one of four part-way graphics, 24 to 27, from TURN_RIGHT_VIEWS for a right
; turn or TURN_LEFT_VIEWS for a left one, by the facing; bit 0 of +$0D records
; which way, and bits 1-2 a count of one. Their update routine (TURNING_LEGS)
; holds that frame for two turns and then puts in the new facing's standing
; graphic (17 or 21, with its mirror bit), so a quarter turn takes three turns
; (measured: holding a turn key, the legs' graphic at the end of each turn went
; 26, 26, then 17 mirrored, and so on round). The top follows the legs'
; graphic, 16 higher (TOP_FOLLOWS_LEGS). No turn is started during the walk
; into a room, or in a jump; directional control also waits until he stands on
; something.
;
;   IX the robot's legs
;   C the controls (INPUT): bits 0 and 1 turn, 2 walk, 3 jump, 4 pick up
; O:C bit 2 set if he is to walk
HANDLE_LEFT_RIGHT:
  LD HL,CONTROL           ; bits 1-2 of CONTROL: 0, the keyboard, always turns
  LD A,(HL)               ; rotationally
  AND $06                 ;
  JR Z,ROTATIONAL_TURN    ;
  BIT 3,(HL)              ; directional control not chosen
  JR Z,ROTATIONAL_TURN    ;
  LD A,(IX+$0C)           ; directional: nothing during the walk into a room
  AND $F0                 ; (the count in bits 4-7 of +$0C)...
  RET NZ                  ;
  BIT 2,(IX+$0C)          ; ...nor in the air: bit 2 of +$0C, standing on
  RET Z                   ; something
  BIT 0,C                  ; left held: skip up; up held: face 2
  JR NZ,DIRECTIONAL_NOT_UP ;
  BIT 2,C                  ;
  JR NZ,DIRECTIONAL_UP     ;
DIRECTIONAL_NOT_UP:
  BIT 1,C                 ; right: face 1; down: face 3; left: face 0
  JR NZ,DIRECTIONAL_RIGHT ;
  BIT 4,C                 ;
  JR NZ,DIRECTIONAL_DOWN  ;
  BIT 0,C                 ;
  JR NZ,DIRECTIONAL_LEFT  ;
  RES 2,C                 ; nothing pushed: no walking
  RET                     ;
DIRECTIONAL_UP:
  CALL GET_SPRITE_DIR     ; up: facing 2 already?
  CP $02                  ;
HANDLE_LEFT_RIGHT_0:
  JR Z,FACING_THAT_WAY    ; yes: walk; otherwise invert the facing, so that its
  CPL                     ; bit 0 set means a right turn is the short way
TURN_BY_PARITY:
  AND $01                 ; the facing's bit 0 picks the turn
  JR HANDLE_LEFT_RIGHT_2  ;
DIRECTIONAL_RIGHT:
  CALL GET_SPRITE_DIR     ; right: facing 1 already? The same test as up
  CP $01                  ;
  JR HANDLE_LEFT_RIGHT_0  ;
DIRECTIONAL_DOWN:
  CALL GET_SPRITE_DIR     ; down: facing 3 already? Walk if so; otherwise the
  CP $03                  ; facing's own bit 0 picks the turn
HANDLE_LEFT_RIGHT_1:
  JR Z,FACING_THAT_WAY    ;
  JR TURN_BY_PARITY       ;
DIRECTIONAL_LEFT:
  CALL GET_SPRITE_DIR     ; left: facing 0 already? The same test as down
  AND A                   ;
  JR HANDLE_LEFT_RIGHT_1  ;
FACING_THAT_WAY:
  SET 2,C                 ; facing the way pushed: walk
  RET                     ;
ROTATIONAL_TURN:
  LD A,C                  ; rotational: neither turn control held
  AND $03                 ;
  RET Z                   ;
  LD A,(IX+$0C)           ; not during the walk into a room
  AND $F0                 ;
  RET NZ                  ;
  BIT 3,(IX+$0C)          ; not in the middle of a jump
  RET NZ                  ;
  BIT 1,C                 ; bit 1: right
HANDLE_LEFT_RIGHT_2:
  JR NZ,START_TURN_RIGHT  ; NZ for a right turn, Z for a left
START_TURN_LEFT:
  RES 0,(IX+$0D)          ; left: bit 0 of +$0D clear, and the left turn's
  LD HL,TURN_LEFT_VIEWS   ; part-way graphics
  JR START_TURN           ;
START_TURN_RIGHT:
  SET 0,(IX+$0D)          ; right: bit 0 of +$0D set, and the right turn's
  LD HL,TURN_RIGHT_VIEWS  ;
START_TURN:
  LD A,(IX+$0D)           ; a count of one in bits 1-2 of +$0D, for
  OR $02                  ; TURNING_LEGS
  LD (IX+$0D),A           ;
  CALL GET_SPRITE_DIR     ; A = the facing
; This entry point is used by the routine at TURNING_LEGS.
;
; Set the graphic and the mirror bit from the pair A selects in the table at
; HL, A taken modulo 4. Also used by TURNING_LEGS, with the part-way graphic as
; A.
SET_TURN_GRAPHIC:
  RLCA                    ; HL = the pair: A times 2
  AND $06                 ;
  CALL ADD_HL_A           ;
  LD A,(HL)               ; the graphic
  INC HL                  ;
  LD (IX+$00),A           ;
  LD A,(IX+$07)           ; the mirror bit (bit 6 of +7) from the pair's second
  AND $BF                 ; byte
  OR (HL)                 ;
  LD (IX+$07),A           ;
  RET                     ;

; The in-between views of a right turn
;
; Read by HANDLE_LEFT_RIGHT as a quarter turn to the right starts: indexed by
; the facing, two bytes each, the graphic the legs take for the turn and the
; mirror bit (bit 6 of the flags). Graphics 24-27 are the views between the
; diagonal ones the robot walks in: the facing either side of each says which
; -- 24 from behind, 25 from the front, 26 side-on facing right, and 27, 26's
; drawing, used mirrored for facing left. The left turn's four follow at
; TURN_LEFT_VIEWS; TURNING_LEGS ends the turn from TURN_RIGHT_ENDS.
TURN_RIGHT_VIEWS:
  DEFB $18,$00            ; Facing 0 (lower U) to 2: graphic 24, from behind
  DEFB $19,$00            ; Facing 1 (higher U) to 3: graphic 25, from the
                          ; front
  DEFB $1A,$00            ; Facing 2 (higher V) to 1: graphic 26, side-on
  DEFB $1B,$40            ; Facing 3 (lower V) to 0: graphic 27, mirrored

; The in-between views of a left turn
;
; As TURN_RIGHT_VIEWS, for a quarter turn to the left (HANDLE_LEFT_RIGHT);
; TURNING_LEGS ends it from TURN_LEFT_ENDS.
TURN_LEFT_VIEWS:
  DEFB $1B,$40            ; Facing 0 (lower U) to 3: graphic 27, mirrored
  DEFB $1A,$00            ; Facing 1 (higher U) to 2: graphic 26
  DEFB $18,$00            ; Facing 2 (higher V) to 0: graphic 24, from behind
  DEFB $19,$00            ; Facing 3 (lower V) to 1: graphic 25, from the front

; The robot's legs while he turns (graphics 24 to 27)
;
; The update routine (UPDATES) of the in-between views a quarter turn passes
; through. HANDLE_LEFT_RIGHT starts a turn by giving the legs one of them
; (TURN_RIGHT_VIEWS, TURN_LEFT_VIEWS) and a count of one in bits 1-2 of +$0D,
; with bit 0 set for a right turn. While the count runs this routine only lets
; the robot fall; once it has run out it gives the legs the standing graphic of
; the new facing (TURN_RIGHT_ENDS, TURN_LEFT_ENDS), with a sound. So the
; in-between view is on the screen for two turns, and a walking robot stands
; still for three: the turn a turn starts (MOVE_PLAYER takes no step with an
; in-between graphic), and these two (measured in the simulator: a left turn
; from facing 1 showed graphic 26 for two turns and then 17 mirrored, facing 2;
; with walk held through a right turn U did not change until the turn after the
; new facing).
;
; Like the legs' own routine (PLAYER_LEGS) it reads the controls, gives the
; legs the whole robot's height, 23, and the top none while he moves, keeps the
; top out of the collision scans meanwhile, and ends in that routine's tail:
; heights 12 and 11, and a redraw. Unlike it, it does not look at the killed
; bit of +$0D, nor count down the walk into a room.
;
; The finishing branch means to take a step if walk is held: it comes into
; MOVE_PLAYER at MOVE_IF_WALKING, which tests bit 2 of C. But the sound it
; makes first (FOOTSTEP, at the entry that skips the frame test) counts C down
; to zero, so the step is never taken and gravity takes its full two units
; whatever is held. HANDLE_FORWARD keeps BC around the same sound.
;
; IX the legs' record
TURNING_LEGS:
  CALL DRAW_AT_L16_D7     ; Drawn 16 left and 7 down
  LD (IX+$06),$17         ; While he moves, the legs' box is the whole robot's,
  LD (IX+$26),$00         ; 23 high, and the top has no height
  CALL READ_CONTROLS      ; C = the controls
  LD A,(IX+$0D)           ; The turn's count, bits 1-2 of +$0D, still running?
  AND $06                 ;
  JR Z,TURNING_LEGS_0     ;
  LD A,(IX+$0D)           ; Count it down
  SUB $02                 ;
  LD (IX+$0D),A           ;
  SET 1,(IX+$27)          ; The top out of the scans; fall, without a step
  CALL APPLY_GRAVITY      ;
  JR TURNING_LEGS_2       ;
TURNING_LEGS_0:
  BIT 0,(IX+$0D)          ; Bit 0: a right turn ends from TURN_RIGHT_ENDS...
  JR Z,TURNING_LEGS_3     ;
  LD HL,TURN_RIGHT_ENDS   ;
TURNING_LEGS_1:
  LD A,(IX+$00)           ; ...the standing graphic and mirror bit of the new
  CALL SET_TURN_GRAPHIC   ; facing, by the in-between graphic's low two bits
  CALL FOOTSTEP_NOW       ; The turn's sound; it leaves C at zero
  SET 1,(IX+$27)          ; The top out of the scans; a step if walk is held
  CALL MOVE_IF_WALKING    ; (never, C being zero), then fall
TURNING_LEGS_2:
  RES 1,(IX+$27)          ; The top back in the scans; heights 12 and 11 and
  JP PLAYER_LEGS_DONE     ; the redraw, in the tail of PLAYER_LEGS
TURNING_LEGS_3:
  LD HL,TURN_LEFT_ENDS    ; A left turn ends from TURN_LEFT_ENDS
  JR TURNING_LEGS_1       ;

; The facings a right turn ends in
;
; Read by TURNING_LEGS when the in-between view of a right turn has been shown:
; indexed by the in-between graphic's low two bits, the graphic and mirror bit
; of the new facing. Graphics 17 and 21 are the legs standing (frame 1) in the
; two views bit 2 of the graphic chooses; the mirror bit makes the other two
; facings. The left turn's four follow at TURN_LEFT_ENDS.
TURN_RIGHT_ENDS:
  DEFB $11,$40            ; After graphic 24: 17 mirrored, facing 2 (higher V)
  DEFB $15,$40            ; After 25: 21 mirrored, facing 3 (lower V)
  DEFB $15,$00            ; After 26: 21, facing 1 (higher U)
  DEFB $11,$00            ; After 27: 17, facing 0 (lower U)

; The facings a left turn ends in
;
; As TURN_RIGHT_ENDS, for a left turn (TURNING_LEGS).
TURN_LEFT_ENDS:
  DEFB $11,$00            ; After graphic 24: 17, facing 0 (lower U)
  DEFB $15,$00            ; After 25: 21, facing 1 (higher U)
  DEFB $11,$40            ; After 26: 17 mirrored, facing 2 (higher V)
  DEFB $15,$40            ; After 27: 21 mirrored, facing 3 (lower V)

; Start a jump
;
; Used by the routine at PLAYER_LEGS.
;
; Called by the legs (PLAYER_LEGS) every turn. A jump needs the jump control
; held, the walk into a room over (the count in bits 4-7 of +$0C), no jump
; already under way (bit 3 of +$0C, cleared on landing by MOVE_PLAYER), and the
; robot not falling: a Z step of -2 or less says he is. That is Knight Lore's
; test, on the speed; Pentagram tests bit 2 of +$0C, standing, instead. The
; jump starts at 8 units up a turn, with a rising sound (JUMP_SOUND); gravity
; in MOVE_PLAYER takes it away again.
;
; IX the legs' record
; C the controls
HANDLE_JUMP:
  BIT 3,C                 ; Jump not held
  RET Z                   ;
  LD A,(IX+$0C)           ; Not during the walk into a room
  AND $F0                 ;
  RET NZ                  ;
  BIT 3,(IX+$0C)          ; Already jumping
  RET NZ                  ;
  LD A,(IX+$0B)           ; A Z step of -2 or less: falling
  INC A                   ;
  RET M                   ;
  SET 3,(IX+$0C)          ; Jumping, 8 up
  LD (IX+$0B),$08         ;
  PUSH BC                 ; The jump's sound, the controls kept
  CALL JUMP_SOUND         ;
  POP BC                  ;
  RET                     ;

; Step the legs
;
; Used by the routine at PLAYER_LEGS.
;
; The legs' graphics 16-23 are two views (bit 2) of four frames (bits 0-1): a
; stride, legs together, the other stride, together again -- frames 1 and 3
; share a drawing (GRAPHICS). While the robot walks, jumps or walks into a room
; the legs step on through the four, with a sound (FOOTSTEP) on leaving a
; stride, frames 0 and 2. Otherwise they carry on, silently, to frame 1 and
; stop there. Nothing happens on the turn a turn starts: HANDLE_LEFT_RIGHT,
; called just before, has given the legs an in-between view, 24-27.
;
; Pentagram's is the same with frame 2 the standing pose and a footstep every
; fourth frame; Knight Lore's walk has six frames.
;
; IX the legs' record
; C the controls
HANDLE_FORWARD:
  LD A,(IX+$00)           ; Graphics 24-27: a turn has just started
  SUB $18                 ;
  CP $04                  ;
  RET C                   ;
  LD A,(IX+$0C)           ; Walking into a room: step
  AND $F0                 ;
  JR NZ,HANDLE_FORWARD_0  ;
  BIT 3,(IX+$0C)          ; Jumping: step
  JR NZ,HANDLE_FORWARD_0  ;
  BIT 2,C                 ; Walk not held: on to the standing frame
  JR Z,HANDLE_FORWARD_2   ;
HANDLE_FORWARD_0:
  PUSH BC                 ; The step's sound, on frames 0 and 2 only; the
  CALL FOOTSTEP           ; controls kept
  POP BC                  ;
HANDLE_FORWARD_1:
  LD A,(IX+$00)           ; The next frame of four, in the graphic's low two
  LD E,A                  ; bits
  INC A                   ;
  AND $03                 ;
  LD D,A                  ;
  LD A,E                  ;
  AND $FC                 ;
  OR D                    ;
  LD (IX+$00),A           ;
  RET                     ;
HANDLE_FORWARD_2:
  LD A,(IX+$00)           ; Frame 1, legs together: stand
  AND $03                 ;
  CP $01                  ;
  RET Z                   ;
  JR HANDLE_FORWARD_1     ; Otherwise step on towards it, silently

; Move the robot
;
; Used by the routine at PLAYER_LEGS.
;
; Called by the legs (PLAYER_LEGS) every turn, with the top kept out of the
; collision scans. He steps forward -- 3 units the way he faces, plus any nudge
; a doorway has left (CALC_PLYR_DUV) -- while jumping, during the walk into a
; room, or when walk is held; but not on the turn a turn starts, when the legs
; have an in-between graphic (bit 3 set: 24-27). Then gravity: 2 off the Z step
; every turn, or 1 while he is still rising (or level) with jump held, so that
; holding jump jumps higher. The Z step is copied to PLAYER_DZ, a fall faster
; than 2 a turn makes a sound pitched by the height (BEEP_BY_Z), and
; ADJ_FOR_OUT_OF_BOUNDS cuts the move short against the floor, the walls and
; the other objects. HANDLE_EXIT_SCREEN takes him out of the room if the move
; carries him through a doorway, and does not come back; otherwise the move is
; made (the second half of DEC_DZ_AND_UPDATE_UVZ). A move down that was stopped
; (bit 2 of +$0C) is a landing, and ends the jump. The U and V steps are then
; cleared; the Z step carries over as his speed.
;
; While the scene after a game runs (GAME_OVER) the Z step is set to 2 every
; turn, which gravity brings back to 0: the robot hangs where he is. Knight
; Lore does the same while something floats into its cauldron.
;
; This is Knight Lore's routine, the falling sound and the exit check included;
; Pentagram keeps neither. The turning legs (TURNING_LEGS) come in at
; MOVE_IF_WALKING and APPLY_GRAVITY, and LOOSE_VALVE, PUSHABLE and EXTRA_LIFE
; end their own updates at CLEAR_DUV.
;
; IX the legs' record
; C the controls
MOVE_PLAYER:
  LD A,(GAME_OVER)        ; The scene after a game: a Z step of 2, to hang
  AND A                   ; still
  JR Z,MOVE_PLAYER_0      ;
  LD (IX+$0B),$02         ;
MOVE_PLAYER_0:
  BIT 3,(IX+$0C)          ; Jumping: forward
  JR NZ,MOVE_PLAYER_1     ;
  LD A,(IX+$0C)           ; Walking into a room: forward
  AND $F0                 ;
  JR NZ,MOVE_PLAYER_1     ;
  BIT 3,(IX+$00)          ; An in-between graphic: a turn has just started, so
  JR NZ,APPLY_GRAVITY     ; no step
; This entry point is used by the routine at TURNING_LEGS.
MOVE_IF_WALKING:
  BIT 2,C                 ; Walk not held: no step
  JR Z,APPLY_GRAVITY      ;
MOVE_PLAYER_1:
  PUSH BC                 ; A step forward, the controls kept
  CALL CALC_PLYR_DUV      ;
  POP BC                  ;
; This entry point is used by the routine at TURNING_LEGS.
APPLY_GRAVITY:
  LD A,(IX+$0B)           ; The Z step negative: falling, two off
  AND A                   ;
  JP M,MOVE_PLAYER_2      ;
  BIT 3,C                 ; Rising or level with jump held: one off
  JR NZ,MOVE_PLAYER_3     ;
MOVE_PLAYER_2:
  DEC A                   ; Gravity: two off, or one
MOVE_PLAYER_3:
  DEC A                   ;
  LD (IX+$0B),A           ; The new Z step, and a copy that says afterwards
  LD (PLAYER_DZ),A        ; which way he was going
  ADD A,$02               ; Falling faster than 2: the falling sound, pitched
  CALL M,BEEP_BY_Z        ; by Z
  CALL ADJ_FOR_OUT_OF_BOUNDS ; Cut the move short where it must be
  CALL HANDLE_EXIT_SCREEN ; Through a doorway: into the next room, and no
                          ; return
  CALL ADD_DUVZ           ; U, V and Z plus the steps
  BIT 2,(IX+$0C)          ; Stopped while moving down?
  JR Z,CLEAR_DUV          ;
  LD A,(PLAYER_DZ)        ;
  AND A                   ;
  JP P,CLEAR_DUV          ;
  RES 3,(IX+$0C)          ; Then landed: the jump is over
; This entry point is used by the routines at LOOSE_VALVE, PUSHABLE and
; EXTRA_LIFE.
CLEAR_DUV:
  XOR A                   ; The U and V steps are one turn's; the Z step
  LD (IX+$09),A           ; carries over as the speed
  LD (IX+$0A),A           ;
  RET                     ;

; Add a step in the direction he faces
;
; Used by the routine at MOVE_PLAYER.
;
; First adds the nudge in +$0E and +$0F, which a doorway leaves to steer the
; robot onto its middle line (NUDGE_ALONG_V, NUDGE_ALONG_U), to the U and V
; steps, and clears it; then adds 3 in the direction he faces, through
; WALK_STEP_TBL. So the nudge acts only while he walks.
;
; DISPATCH_ON_FACING, the last three instructions, jumps through a table of
; four addresses at BC by the facing of the object at IX (GET_SPRITE_DIR),
; using the main loop's jump through the update table (in AFTER_GAME). The exit
; check (HANDLE_EXIT_SCREEN) and a doorway's first pillar (FIRST_PILLAR) use it
; too.
;
; IX the legs' record
CALC_PLYR_DUV:
  LD A,(IX+$09)           ; The U and V steps plus the nudge
  ADD A,(IX+$0E)          ;
  LD (IX+$09),A           ;
  LD A,(IX+$0A)           ;
  ADD A,(IX+$0F)          ;
  LD (IX+$0A),A           ;
  XOR A                   ; The nudge is used up
  LD (IX+$0E),A           ;
  LD (IX+$0F),A           ;
  LD BC,WALK_STEP_TBL     ; The table of steps
; This entry point is used by the routines at FIRST_PILLAR and
; HANDLE_EXIT_SCREEN.
DISPATCH_ON_FACING:
  CALL GET_SPRITE_DIR     ; Jump to the table's entry for the facing
  LD L,A                  ;
  JP JUMP_THROUGH_TABLE   ;

; Which way an object faces
;
; Used by the routines at HANDLE_LEFT_RIGHT and CALC_PLYR_DUV.
;
; The facing, 0 to 3, from the two bits that store it: bit 6 of the flags (the
; sprite mirrored) gives 2, and bit 2 of the graphic adds 1. By the steps each
; facing is given (WALK_STEP_TBL), 0 faces lower U, 1 higher U, 2 higher V and
; 3 lower V. Knight Lore's is the same with bit 3 of the graphic; Pentagram's
; counts 2 for a sprite not mirrored.
;
;   IX the object
; O:A the facing
GET_SPRITE_DIR:
  PUSH HL                 ; L = 8 if the sprite is mirrored
  LD A,(IX+$07)           ;
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  AND $08                 ;
  LD L,A                  ;
  LD A,(IX+$00)           ; With the graphic's bit 2
  AND $04                 ;
  OR L                    ;
  RRCA                    ; Down to bits 1 and 0; HL kept
  RRCA                    ;
  AND $03                 ;
  POP HL                  ;
  RET                     ;

; A step in each direction
;
; Four routine addresses, one per facing, used through DISPATCH_ON_FACING by
; CALC_PLYR_DUV. Each adds 3 to, or takes 3 from, the U or V step.
WALK_STEP_TBL:
  DEFW STEP_U_DOWN        ; Facing 0: U - 3 (STEP_U_DOWN); 1: U + 3
  DEFW STEP_U_UP          ; (STEP_U_UP); 2: V + 3 (STEP_V_UP); 3: V - 3
  DEFW STEP_V_UP          ; (STEP_V_DOWN)
  DEFW STEP_V_DOWN        ;

; Step towards lower U
;
; The U step less 3, for facing 0.
;
; IX the legs' record
STEP_U_DOWN:
  LD A,(IX+$09)           ; -3
  ADD A,$FD               ;
; This entry point is used by the routine at STEP_U_UP.
STORE_PLYR_DU:
  LD (IX+$09),A           ; Store the U step (STEP_U_UP ends here too)
  RET                     ;

; Step towards higher U
;
; The U step plus 3, for facing 1.
;
; IX the legs' record
STEP_U_UP:
  LD A,(IX+$09)           ; +3, and store it
  ADD A,$03               ;
  JR STORE_PLYR_DU        ;

; Step towards higher V
;
; The V step plus 3, for facing 2.
;
; IX the legs' record
STEP_V_UP:
  LD A,(IX+$0A)           ; +3
  ADD A,$03               ;
; This entry point is used by the routine at STEP_V_DOWN.
STORE_PLYR_DV:
  LD (IX+$0A),A           ; Store the V step (STEP_V_DOWN ends here too)
  RET                     ;

; Step towards lower V
;
; The V step less 3, for facing 3.
;
; IX the legs' record
STEP_V_DOWN:
  LD A,(IX+$0A)           ; -3, and store it
  ADD A,$FD               ;
  JR STORE_PLYR_DV        ;

; Shorten dZ at the floor
;
; Used by the routine at ADJ_FOR_OUT_OF_BOUNDS.
;
; The floor is the only limit on Z: there is no ceiling. FLOOR is 64 in all
; three room sizes (ROOM_SIZES). A move that would take the object's base below
; it is shortened a unit at a time until it would not, and bit 2 of +$0C
; records that the move was stopped. Called by ADJ_FOR_OUT_OF_BOUNDS before the
; other objects are tried.
;
;   IX the object
;   H dZ
; O:H dZ, shortened
ADJ_DZ_FOR_OUT_OF_BOUNDS:
  LD A,(FLOOR)            ; D = the floor
  LD D,A                  ;
CLIP_DZ_TO_FLOOR:
  LD A,(IX+$03)           ; Z + dZ at or above the floor: done
  ADD A,H                 ;
  CP D                    ;
  RET NC                  ;
  SET 2,(IX+$0C)          ; Stopped in Z
  LD A,H                  ; A unit shorter, and again unless nothing is left
  CALL SHORTEN_DELTA      ;
  LD H,A                  ;
  JR NZ,CLIP_DZ_TO_FLOOR  ;
  RET                     ;

; Has the robot walked out of the room?
;
; Used by the routine at MOVE_PLAYER.
;
; Called by MOVE_PLAYER once the move has been cut short and before it is made.
; A room is left only through a doorway, and only walking the way the robot
; faces: a doorway's first pillar sets bit 0 of the legs' flags while he is in
; it (CHK_PLYR_NEAR_ARCH), which also lets him past the line of the wall
; (ADJ_DU_FOR_OUT_OF_BOUNDS, ADJ_DV_FOR_OUT_OF_BOUNDS). This clears the bit --
; it is used once, and the pillar sets it again on its next update if he is
; still there -- and jumps through SCREEN_MOVE_TBL by the facing; each of the
; four decides whether this turn's move takes him wholly past the wall he
; faces.
;
; Knight Lore's, instruction for instruction. The room's half-sizes are pushed
; for the four, because the dispatch uses HL.
;
; IX the legs' record
HANDLE_EXIT_SCREEN:
  LD A,(IX+$0C)           ; Not during the walk into a room
  AND $F0                 ;
  RET NZ                  ;
  BIT 0,(IX+$07)          ; Not in a doorway
  RET Z                   ;
  RES 0,(IX+$07)          ; The flag is used once
  LD BC,SCREEN_MOVE_TBL   ; The four exits, the room's half-sizes pushed for
  LD HL,(ROOM_HALF_U)     ; them, and the jump by facing
  PUSH HL                 ;
  JP DISPATCH_ON_FACING   ;

; Shorten a move by one unit
;
; Used by the routines at ADJ_DZ_FOR_OUT_OF_BOUNDS, ADJ_DU_FOR_OBJ_INTERSECT,
; ADJ_DV_FOR_OBJ_INTERSECT, ADJ_DZ_FOR_OBJ_INTERSECT, ADJ_DU_FOR_OUT_OF_BOUNDS
; and ADJ_DV_FOR_OUT_OF_BOUNDS.
;
; Moves A one step towards zero -- down if positive, up if negative -- and
; leaves Z set if nothing is left. Every loop in the collision code uses it to
; cut a move short a unit at a time and try again.
;
;   A a dU, dV or dZ
; O:A one unit closer to zero; Z set if zero
SHORTEN_DELTA:
  AND A                   ; Already zero
  RET Z                   ;
  JP P,SHORTEN_DELTA_DEC  ; Negative: +2 here and -1 below
  INC A                   ;
  INC A                   ;
SHORTEN_DELTA_DEC:
  DEC A                   ; The step down that sets Z
  RET                     ;

; Leaving a room, by facing
;
; Four routine addresses in facing order, used through DISPATCH_ON_FACING by
; HANDLE_EXIT_SCREEN.
SCREEN_MOVE_TBL:
  DEFW EXIT_LOW_U         ; Facing 0: out at low U? (EXIT_LOW_U); 1: at high U?
  DEFW EXIT_HIGH_U        ; (EXIT_HIGH_U); 2: at high V? (EXIT_HIGH_V); 3: at
  DEFW EXIT_HIGH_V        ; low V? (EXIT_LOW_V)
  DEFW EXIT_LOW_V         ;

; Out through the wall at low U?
;
; Out if the robot's far edge after this turn's move -- U plus the step plus
; his half-size -- is below the wall at 128 less the room's U half-size. U is
; then set to 0: not a position but a marker, which
; ADJUST_PLYR_UVZ_FOR_ROOM_SIZE sees when the next room is built and puts him
; in the doorway of its wall at high U. The other exits use $FF and 0 the same
; way. The new room is the one before in the same row: room numbers are a row
; in the high four bits and a column in the low four, and the column is changed
; on its own so that it wraps within the row.
;
; EXIT_SCREEN is the way on for all four. It gives the legs the new room and
; starts the walk into it: 4 in bits 4-7 of +$0C, four turns of walking
; straight on with the controls and the walls ignored (Knight Lore's is three).
; For anything but the robot -- graphics 16 to 79 -- it returns, but only he
; gets here. For him the rest of the turn is abandoned: the returns into
; MOVE_PLAYER and to the legs' update are dropped, and both his records are
; copied to the start records (START_LEGS), so that a life lost in the new room
; starts again at this doorway. In the copies the graphic is moved to +$10 and
; replaced by 56, the first of the appearing robot's (PLAYER_APPEARING). Then
; the new room is built and the main loop starts over (AFTER_GAME).
;
; IX the legs' record
; HL the room's half-sizes (pushed by HANDLE_EXIT_SCREEN)
EXIT_LOW_U:
  POP HL                  ; L = the wall
  LD A,$80                ;
  SUB L                   ;
  LD L,A                  ;
  LD A,(IX+$01)           ; U + dU + half-size still at or beyond it: stay
  ADD A,(IX+$09)          ;
  ADD A,(IX+$04)          ;
  CP L                    ;
  RET NC                  ;
  LD (IX+$01),$00         ; Arrive at the wall at high U
  LD A,(IX+$08)           ; Room - 1...
  LD L,A                  ;
  DEC A                   ;
; This entry point is used by the routine at EXIT_HIGH_U.
EXIT_WITHIN_ROW:
  AND $0F                 ; ...the new column with the old row
  LD H,A                  ;
  LD A,L                  ;
  AND $F0                 ;
  OR H                    ;
; This entry point is used by the routines at EXIT_HIGH_V and EXIT_LOW_V.
EXIT_SCREEN:
  LD (IX+$08),A           ; The new room
  LD A,(IX+$0C)           ; The walk into the room: four turns
  OR $40                  ;
  LD (IX+$0C),A           ;
  LD A,(IX+$00)           ; Anything but the robot: carry on
  SUB $10                 ;
  CP $40                  ;
  RET NC                  ;
  INC SP                  ; Drop the returns into MOVE_PLAYER and to the legs'
  INC SP                  ; update
  INC SP                  ;
  INC SP                  ;
  PUSH IX                 ; Both his records to the start records
  POP HL                  ;
  LD DE,START_LEGS        ;
  LD BC,$0040             ;
  LDIR                    ;
  LD A,(START_LEGS)       ; Each copy's graphic kept in its +$10...
  LD (START_LEGS_NEXT),A  ;
  LD A,(START_TOP)        ;
  LD (START_TOP_NEXT),A   ;
  LD A,$38                ; ...and replaced by the appearing robot's first
  LD (START_LEGS),A       ;
  LD (START_TOP),A        ;
  JP MAIN_NEW_ROOM        ; Build the new room and start its turns

; Out through the wall at high U?
;
; As EXIT_LOW_U the other way: out if the near edge after the move -- U plus
; the step less the half-size -- is at or past the wall at 128 plus the room's
; U half-size. U becomes the marker $FF, to arrive at the wall at low U, and
; the room is the next in the row.
;
; IX the legs' record
; HL the room's half-sizes (pushed by HANDLE_EXIT_SCREEN)
EXIT_HIGH_U:
  POP HL                  ; L = the wall
  LD A,L                  ;
  ADD A,$80               ;
  LD L,A                  ;
  LD A,(IX+$01)           ; U + dU - half-size short of it: stay
  ADD A,(IX+$09)          ;
  SUB (IX+$04)            ;
  CP L                    ;
  RET C                   ;
  LD (IX+$01),$FF         ; Arrive at the wall at low U
  LD A,(IX+$08)           ; Room + 1, within the row
  LD L,A                  ;
  INC A                   ;
  JR EXIT_WITHIN_ROW      ;

; Out through the wall at high V?
;
; Out if the near edge in V after the move is at or past the wall at 128 plus
; the room's V half-size. V becomes the marker $FF, to arrive at the wall at
; low V, and the room is the one 16 on: the next row, wrapping from the last
; row to the first.
;
; IX the legs' record
; HL the room's half-sizes (pushed by HANDLE_EXIT_SCREEN)
EXIT_HIGH_V:
  POP HL                  ; H = the wall
  LD A,H                  ;
  ADD A,$80               ;
  LD H,A                  ;
  LD A,(IX+$02)           ; V + dV - half-size short of it: stay
  ADD A,(IX+$0A)          ;
  SUB (IX+$05)            ;
  CP H                    ;
  RET C                   ;
  LD (IX+$02),$FF         ; Arrive at the wall at low V
  LD A,(IX+$08)           ; Room + 16
  ADD A,$10               ;
  JR EXIT_SCREEN          ;

; Out through the wall at low V?
;
; Out if the far edge in V after the move is below the wall at 128 less the
; room's V half-size. V becomes the marker 0, to arrive at the wall at high V,
; and the room is the one 16 back: the row before.
;
; IX the legs' record
; HL the room's half-sizes (pushed by HANDLE_EXIT_SCREEN)
EXIT_LOW_V:
  POP HL                  ; H = the wall
  LD A,$80                ;
  SUB H                   ;
  LD H,A                  ;
  LD A,(IX+$02)           ; V + dV + half-size still at or beyond it: stay
  ADD A,(IX+$0A)          ;
  ADD A,(IX+$05)          ;
  CP H                    ;
  RET NC                  ;
  LD (IX+$02),$00         ; Arrive at the wall at high V
  LD A,(IX+$08)           ; Room - 16
  SUB $10                 ;
  JP EXIT_SCREEN          ;

; Cut a move short against the room and the other objects
;
; Used by the routines at DEC_DZ_AND_UPDATE_UVZ and MOVE_PLAYER.
;
; Every moving object's move comes through here: the robot's from MOVE_PLAYER,
; everything else's from DEC_DZ_AND_UPDATE_UVZ. It takes the steps in U, V and
; Z (+$09 to +$0B) and shortens each where the object would otherwise end up
; below the floor, through a wall, or inside another object, then writes them
; back. The code is Knight Lore's and Pentagram's.
;
; The axes are done one at a time, Z first, then U, then V, and each test
; counts the moves already accepted on the earlier axes and the later ones as
; zero. That is what lets a blocked move slide: walking diagonally into a wall
; keeps the part of the move that runs along it.
;
; While it works, bit 1 of +$07 is set, which makes the object scans
; (IS_OBJECT_NOT_IGNORED) pass over the object itself; found already set, it
; returns at once. Bits 0-2 of +$0C are cleared at the start and set for each
; axis whose move was cut.
;
; IX the object
ADJ_FOR_OUT_OF_BOUNDS:
  BIT 1,(IX+$07)          ; Not while already set; and ignore ourself while we
  RET NZ                  ; work
  SET 1,(IX+$07)          ;
  LD A,(IX+$0C)           ; Clear the three "stopped" bits
  AND $F8                 ;
  LD (IX+$0C),A           ;
  LD L,$00                ; dV and dU count as zero while Z is tested
  LD C,L                  ;
  LD A,(IX+$0B)                ; H = dZ; nothing to do if zero
  AND A                        ;
  LD H,A                       ;
  JR Z,ADJ_FOR_OUT_OF_BOUNDS_0 ;
  CALL ADJ_DZ_FOR_OUT_OF_BOUNDS ; The floor first; nothing left means no
  LD A,H                        ; objects to test
  AND A                         ;
  JR Z,ADJ_FOR_OUT_OF_BOUNDS_0  ;
  CALL ADJ_DZ_FOR_OBJ_INTERSECT ; Then the other objects
ADJ_FOR_OUT_OF_BOUNDS_0:
  LD A,(IX+$09)                ; C = dU; nothing to do if zero
  AND A                        ;
  LD C,A                       ;
  JR Z,ADJ_FOR_OUT_OF_BOUNDS_1 ;
  CALL ADJ_DU_FOR_OUT_OF_BOUNDS ; The walls first; nothing left means no
  LD A,C                        ; objects to test
  AND A                         ;
  JR Z,ADJ_FOR_OUT_OF_BOUNDS_1  ;
  CALL ADJ_DU_FOR_OBJ_INTERSECT ; Then the other objects
ADJ_FOR_OUT_OF_BOUNDS_1:
  LD A,(IX+$0A)                ; L = dV; nothing to do if zero
  AND A                        ;
  LD L,A                       ;
  JR Z,ADJ_FOR_OUT_OF_BOUNDS_2 ;
  CALL ADJ_DV_FOR_OUT_OF_BOUNDS ; The walls first; nothing left means no
  LD A,L                        ; objects to test
  AND A                         ;
  JR Z,ADJ_FOR_OUT_OF_BOUNDS_2  ;
  CALL ADJ_DV_FOR_OBJ_INTERSECT ; Then the other objects
ADJ_FOR_OUT_OF_BOUNDS_2:
  LD (IX+$09),C           ; The three moves as cut
  LD (IX+$0A),L           ;
  LD (IX+$0B),H           ;
  RES 1,(IX+$07)          ; Other objects' scans may find us again
  RET                     ;

; Shorten dU against the other objects
;
; Used by the routine at ADJ_FOR_OUT_OF_BOUNDS.
;
; Tries the object's box against all 56 records. For each one it already
; overlaps in V and Z, with the moves accepted so far, an overlap in U after
; the move means dU has to be shortened, a unit at a time, until the boxes no
; longer meet; if dU reaches zero the scan stops.
;
; Every such meeting sets bit 0 of +$0C and passes harm between the two: bit 6
; of +$0D means killed, and the obstacle gets it if the mover has bit 7 (kills
; what it moves into), the mover if the obstacle has bit 5 (kills what touches
; it). An obstacle with bit 2 of its flags set, a thing that can be pushed, is
; given the mover's whole intended dU, which its own update then moves it by.
;
;   IX the moving object
;   C dU
;   L dV so far (zero)
;   H dZ as accepted
; O:C dU, shortened
ADJ_DU_FOR_OBJ_INTERSECT:
  LD IY,OBJECTS           ; IY = the first record; 56 of them
  LD B,$38                ;
ADJ_DU_FOR_OBJ_INTERSECT_0:
  CALL IS_OBJECT_NOT_IGNORED ; Empty, or out of the collision tests
  JR Z,DU_OBJ_NEXT           ;
  CALL DO_OBJS_INTERSECT_ON_V ; Not overlapping in V, or not in Z
  JR NC,DU_OBJ_NEXT           ;
  CALL DO_OBJS_INTERSECT_ON_Z ;
  JR NC,DU_OBJ_NEXT           ;
DU_OBJ_HIT_TEST:
  CALL DO_OBJS_INTERSECT_ON_U ; No overlap in U after the move: the next object
  JR NC,DU_OBJ_NEXT           ;
  SET 0,(IX+$0C)          ; Stopped in U
  LD A,(IX+$0D)           ; The mover's bit 7 becomes the obstacle's bit 6
  RRCA                    ;
  AND $40                 ;
  OR (IY+$0D)             ;
  LD (IY+$0D),A           ;
  RLCA                    ; The obstacle's bit 5 becomes the mover's bit 6
  AND $40                 ;
  OR (IX+$0D)             ;
  LD (IX+$0D),A           ;
  BIT 2,(IY+$07)                  ; A pushable obstacle takes on our dU
  JR Z,ADJ_DU_FOR_OBJ_INTERSECT_1 ;
  LD A,(IX+$09)                   ;
  LD (IY+$09),A                   ;
ADJ_DU_FOR_OBJ_INTERSECT_1:
  LD A,C                  ; A unit shorter; none left, done; else the same
  CALL SHORTEN_DELTA      ; object again
  LD C,A                  ;
  RET Z                   ;
  JR DU_OBJ_HIT_TEST      ;
DU_OBJ_NEXT:
  LD DE,$0020                     ; The next of 56
  ADD IY,DE                       ;
  DJNZ ADJ_DU_FOR_OBJ_INTERSECT_0 ;
  RET                             ;

; Shorten dV against the other objects
;
; Used by the routine at ADJ_FOR_OUT_OF_BOUNDS.
;
; ADJ_DU_FOR_OBJ_INTERSECT for V: an object has to overlap in U, after the
; accepted dU, and in Z to be in the way. Stopping sets bit 1 of +$0C; harm
; passes the same way, and a pushable obstacle takes on the mover's dV.
;
;   IX the moving object
;   L dV
;   C dU as accepted
;   H dZ as accepted
; O:L dV, shortened
ADJ_DV_FOR_OBJ_INTERSECT:
  LD IY,OBJECTS           ; IY = the first record; 56 of them
  LD B,$38                ;
ADJ_DV_FOR_OBJ_INTERSECT_0:
  CALL IS_OBJECT_NOT_IGNORED ; Empty, or out of the collision tests
  JR Z,DV_OBJ_NEXT           ;
  CALL DO_OBJS_INTERSECT_ON_U ; Not overlapping in U, or not in Z
  JR NC,DV_OBJ_NEXT           ;
  CALL DO_OBJS_INTERSECT_ON_Z ;
  JR NC,DV_OBJ_NEXT           ;
DV_OBJ_HIT_TEST:
  CALL DO_OBJS_INTERSECT_ON_V ; No overlap in V after the move: the next object
  JR NC,DV_OBJ_NEXT           ;
  SET 1,(IX+$0C)          ; Stopped in V
  LD A,(IX+$0D)           ; Harm passes both ways, as in U
  RRCA                    ;
  AND $40                 ;
  OR (IY+$0D)             ;
  LD (IY+$0D),A           ;
  RLCA                    ;
  AND $40                 ;
  OR (IX+$0D)             ;
  LD (IX+$0D),A           ;
  BIT 2,(IY+$07)                  ; A pushable obstacle takes on our dV
  JR Z,ADJ_DV_FOR_OBJ_INTERSECT_1 ;
  LD A,(IX+$0A)                   ;
  LD (IY+$0A),A                   ;
ADJ_DV_FOR_OBJ_INTERSECT_1:
  LD A,L                  ; A unit shorter; none left, done; else the same
  CALL SHORTEN_DELTA      ; object again
  LD L,A                  ;
  RET Z                   ;
  JR DV_OBJ_HIT_TEST      ;
DV_OBJ_NEXT:
  LD DE,$0020                     ; The next of 56
  ADD IY,DE                       ;
  DJNZ ADJ_DV_FOR_OBJ_INTERSECT_0 ;
  RET                             ;

; Shorten dZ against the other objects
;
; Used by the routine at ADJ_FOR_OUT_OF_BOUNDS.
;
; ADJ_DU_FOR_OBJ_INTERSECT for Z, done before U and V so it tests the object
; where it stands: an object has to overlap in U and in V to be above or below
; it. Stopping sets bit 2 of +$0C, whether the move was up or down, and harm
; passes as in U.
;
; A mover with bit 2 of its flags -- the robot's legs have it -- is carried: it
; gives its intended dZ to the obstacle and, wherever its own dU or dV is zero,
; takes on the obstacle's, so standing on something that moves carries it
; along. When that mover is one of graphics 16 to 47, which takes in the
; robot's legs, the obstacle also gets bit 3 of its +$0D: the robot has stood
; on it, or come up against it from below. The update routines of graphics 44,
; 45 and 47 (DROPPING_BLOCK, COLLAPSING_BLOCK, LIFT) read and clear that bit.
;
; Knight Lore sets the obstacle's bit 3 for any mover and passes no dZ;
; Pentagram passes the dZ and sets bit 3 for any mover too, with more of its
; own (the conveyors, the marks its lift reads). Here the bit is kept for the
; robot.
;
;   IX the moving object
;   H dZ
;   C dU, zero here
;   L dV, zero here
; O:H dZ, shortened
ADJ_DZ_FOR_OBJ_INTERSECT:
  LD IY,OBJECTS           ; IY = the first record; 56 of them
  LD B,$38                ;
ADJ_DZ_FOR_OBJ_INTERSECT_0:
  CALL IS_OBJECT_NOT_IGNORED ; Empty, or out of the collision tests
  JR Z,DZ_OBJ_NEXT           ;
  CALL DO_OBJS_INTERSECT_ON_U ; Not overlapping in U, or not in V
  JR NC,DZ_OBJ_NEXT           ;
  CALL DO_OBJS_INTERSECT_ON_V ;
  JR NC,DZ_OBJ_NEXT           ;
DZ_OBJ_HIT_TEST:
  CALL DO_OBJS_INTERSECT_ON_Z ; No overlap in Z after the move: the next object
  JR NC,DZ_OBJ_NEXT           ;
  SET 2,(IX+$0C)          ; Stopped in Z
  LD A,(IX+$0D)           ; Harm passes both ways, as in U
  RRCA                    ;
  AND $40                 ;
  OR (IY+$0D)             ;
  LD (IY+$0D),A           ;
  RLCA                    ;
  AND $40                 ;
  OR (IX+$0D)             ;
  LD (IX+$0D),A           ;
  BIT 2,(IX+$07)                  ; Not a mover that is carried
  JR Z,ADJ_DZ_FOR_OBJ_INTERSECT_3 ;
  LD A,(IX+$00)                    ; Not graphics 16-47
  SUB $10                          ;
  CP $20                           ;
  JR NC,ADJ_DZ_FOR_OBJ_INTERSECT_1 ;
  SET 3,(IY+$0D)          ; The mover (flags bit 2 and graphics 16-47: the
                          ; robot, the pushable blocks, the bobbing block and
                          ; the lift) has met the obstacle in Z
ADJ_DZ_FOR_OBJ_INTERSECT_1:
  LD A,(IX+$0B)           ; The obstacle takes our dZ
  LD (IY+$0B),A           ;
  LD A,(IX+$09)                    ; No dU of our own: ride with the obstacle's
  AND A                            ;
  JR NZ,ADJ_DZ_FOR_OBJ_INTERSECT_2 ;
  LD A,(IY+$09)                    ;
  LD (IX+$09),A                    ;
ADJ_DZ_FOR_OBJ_INTERSECT_2:
  LD A,(IX+$0A)                    ; No dV of our own: ride with the obstacle's
  AND A                            ;
  JR NZ,ADJ_DZ_FOR_OBJ_INTERSECT_3 ;
  LD A,(IY+$0A)                    ;
  LD (IX+$0A),A                    ;
ADJ_DZ_FOR_OBJ_INTERSECT_3:
  LD A,H                  ; A unit shorter; none left, done; else the same
  CALL SHORTEN_DELTA      ; object again
  LD H,A                  ;
  RET Z                   ;
  JR DZ_OBJ_HIT_TEST      ;
DZ_OBJ_NEXT:
  LD DE,$0020                     ; The next of 56
  ADD IY,DE                       ;
  DJNZ ADJ_DZ_FOR_OBJ_INTERSECT_0 ;
  RET                             ;

; Do two objects overlap in U?
;
; Used by the routines at DO_ANY_OBJS_INTERSECT, CAN_PICK_UP,
; ADJ_DU_FOR_OBJ_INTERSECT, ADJ_DV_FOR_OBJ_INTERSECT and
; ADJ_DZ_FOR_OBJ_INTERSECT.
;
; Boxes are centred in U and V, with +$04 and +$05 the half-sizes. They overlap
; in U if the distance between the centres, after the mover's dU, is less than
; the two half-sizes added: exactly touching is not overlapping. The distance
; is taken as a signed byte, so centres 128 or more apart would be misjudged;
; no room is that big. Also used by DO_ANY_OBJS_INTERSECT and CAN_PICK_UP.
;
;   IX the moving object
;   IY the other object
;   C the mover's dU
; O:F carry set if they overlap
DO_OBJS_INTERSECT_ON_U:
  LD A,(IX+$04)           ; D = the two half-sizes
  ADD A,(IY+$04)          ;
  LD D,A                  ;
  LD A,(IX+$01)                 ; A = |U + dU - the other's U|
  ADD A,C                       ;
  SUB (IY+$01)                  ;
  JP P,DO_OBJS_INTERSECT_ON_U_0 ;
  NEG                           ;
DO_OBJS_INTERSECT_ON_U_0:
  SUB D                   ; Carry if less than D
  RET                     ;

; Do two objects overlap in V?
;
; Used by the routines at DO_ANY_OBJS_INTERSECT, CAN_PICK_UP,
; ADJ_DU_FOR_OBJ_INTERSECT, ADJ_DV_FOR_OBJ_INTERSECT and
; ADJ_DZ_FOR_OBJ_INTERSECT.
;
; DO_OBJS_INTERSECT_ON_U for V, with the mover's dV in L and the half-sizes at
; +$05. Also used by DO_ANY_OBJS_INTERSECT and CAN_PICK_UP.
;
;   IX the moving object
;   IY the other object
;   L the mover's dV
; O:F carry set if they overlap
DO_OBJS_INTERSECT_ON_V:
  LD A,(IX+$05)           ; D = the two half-sizes
  ADD A,(IY+$05)          ;
  LD D,A                  ;
  LD A,(IX+$02)                 ; A = |V + dV - the other's V|
  ADD A,L                       ;
  SUB (IY+$02)                  ;
  JP P,DO_OBJS_INTERSECT_ON_V_0 ;
  NEG                           ;
DO_OBJS_INTERSECT_ON_V_0:
  SUB D                   ; Carry if less than D
  RET                     ;

; Do two objects overlap in Z?
;
; Used by the routines at DO_ANY_OBJS_INTERSECT, CAN_PICK_UP,
; ADJ_DU_FOR_OBJ_INTERSECT, ADJ_DV_FOR_OBJ_INTERSECT and
; ADJ_DZ_FOR_OBJ_INTERSECT.
;
; Not centred like U and V: Z is an object's base and +$06 its whole height. So
; the test takes the gap between the two bases, after the mover's dZ, and
; compares it with the height of whichever object is lower. The robot's top has
; no height while the legs move (PLAYER_LEGS), and is kept out of the scans
; then; the legs, 23 high meanwhile, stand for the whole robot. Also used by
; DO_ANY_OBJS_INTERSECT and CAN_PICK_UP.
;
;   IX the moving object
;   IY the other object
;   H the mover's dZ
; O:F carry set if they overlap
DO_OBJS_INTERSECT_ON_Z:
  LD A,(IX+$03)                 ; A = Z + dZ - the other's Z; the mover higher,
  ADD A,H                       ; use the other's height
  SUB (IY+$03)                  ;
  JP P,DO_OBJS_INTERSECT_ON_Z_1 ;
  NEG                     ; The mover lower: the distance, and its own height
  LD D,(IX+$06)           ;
DO_OBJS_INTERSECT_ON_Z_0:
  SUB D                   ; Carry if the gap is less than the lower one's
  RET                     ; height
DO_OBJS_INTERSECT_ON_Z_1:
  LD D,(IY+$06)               ; The other's height
  JR DO_OBJS_INTERSECT_ON_Z_0 ;

; Shorten dU at the walls
;
; Used by the routine at ADJ_FOR_OUT_OF_BOUNDS.
;
; Keeps the object's whole footprint within the room: its U after the move no
; further from 128 than the room's U half-size (ROOM_HALF_U, 64 or 32) less its
; own half-size. dU is shortened a unit at a time, and bit 0 of +$0C set if it
; had to be.
;
; Two things switch the walls off, as in Knight Lore: the count in bits 4-7 of
; +$0C, the walk into a room, which the legs' update runs down a turn at a time
; (PLAYER_LEGS); and bit 0 of the flags, which a doorway sets on the robot
; while he is in it (CHK_PLYR_NEAR_ARCH). That is how he walks through one at
; all.
;
;   IX the object
;   C dU
; O:C dU, shortened
ADJ_DU_FOR_OUT_OF_BOUNDS:
  LD A,(IX+$0C)           ; Not while the count in +$0C runs
  AND $F0                 ;
  RET NZ                  ;
  BIT 0,(IX+$07)          ; Not in a doorway
  RET NZ                  ;
  LD A,(ROOM_HALF_U)      ; B = the room's U half-size
  LD B,A                  ;
CLIP_DU_TO_WALLS:
  LD A,(IX+$01)                    ; A = |U + dU - 128|
  ADD A,C                          ;
  SUB $80                          ;
  JR NC,ADJ_DU_FOR_OUT_OF_BOUNDS_0 ;
  NEG                              ;
ADJ_DU_FOR_OUT_OF_BOUNDS_0:
  ADD A,(IX+$04)          ; Inside if that plus the half-size is less than the
  CP B                    ; room's: done
  RET C                   ;
  SET 0,(IX+$0C)          ; Stopped in U
  LD A,C                  ; A unit shorter, and again unless nothing is left
  CALL SHORTEN_DELTA      ;
  LD C,A                  ;
  JR NZ,CLIP_DU_TO_WALLS  ;
  RET                     ;

; Shorten dV at the walls
;
; Used by the routine at ADJ_FOR_OUT_OF_BOUNDS.
;
; ADJ_DU_FOR_OUT_OF_BOUNDS for V: the room's V half-size (ROOM_HALF_V), the
; object's at +$05, and bit 1 of +$0C.
;
;   IX the object
;   L dV
; O:L dV, shortened
ADJ_DV_FOR_OUT_OF_BOUNDS:
  LD A,(IX+$0C)           ; Not while the count in +$0C runs
  AND $F0                 ;
  RET NZ                  ;
  BIT 0,(IX+$07)          ; Not in a doorway
  RET NZ                  ;
  LD A,(ROOM_HALF_V)      ; B = the room's V half-size
  LD B,A                  ;
CLIP_DV_TO_WALLS:
  LD A,(IX+$02)                    ; A = |V + dV - 128|
  ADD A,L                          ;
  SUB $80                          ;
  JR NC,ADJ_DV_FOR_OUT_OF_BOUNDS_0 ;
  NEG                              ;
ADJ_DV_FOR_OUT_OF_BOUNDS_0:
  ADD A,(IX+$05)          ; Inside if that plus the half-size is less than the
  CP B                    ; room's: done
  RET C                   ;
  SET 1,(IX+$0C)          ; Stopped in V
  LD A,L                  ; A unit shorter, and again unless nothing is left
  CALL SHORTEN_DELTA      ;
  LD L,A                  ;
  JR NZ,CLIP_DV_TO_WALLS  ;
  RET                     ;

; Work out an object's screen rectangle
;
; Used by the routine at SET_DRAW_OBJS_OVERLAPPED.
;
; Fills in where an object's sprite lands in the screen buffer: the pixel
; position at +$1A and +$1B (CALC_PIXEL_XY), and the size -- +$18 the width in
; bytes, one more when the pixel x is not a multiple of 8, and +$19 the height
; in rows. FLIP_SPRITE also turns the sprite the way the object faces.
;
; Two cases leave things as they were. While the scene after a game runs
; (GAME_OVER), CALC_PIXEL_XY does not move the position. And when the object's
; sprite is the empty one (graphics 0 and 1 use it), FLIP_SPRITE returns
; straight to this routine's caller, so +$18 and +$19 keep what they held: the
; area the object last covered is still the area to clear.
;
; IX the object
CALC_2D_INFO:
  CALL CALC_PIXEL_XY      ; The pixel position
  CALL FLIP_SPRITE        ; DE = the sprite, turned the way the object faces
  LD A,(IX+$1A)           ; The width, bits 0-3 of the sprite's first byte, and
  AND $07                 ; one more for a shifted sprite
  LD A,(DE)               ;
  INC DE                  ;
  JR Z,CALC_2D_INFO_0     ;
  INC A                   ;
CALC_2D_INFO_0:
  AND $0F                 ;
  LD (IX+$18),A           ; +$18: the width in bytes
  LD A,(DE)               ; +$19: the height
  LD (IX+$19),A           ;
  RET                     ;

; Mark every object the moving object's old or new rectangle touches
;
; Used by the routines at SET_WIPE_AND_DRAW_FLAGS and TOP_FOLLOWS_LEGS.
;
; Called once an object has moved or changed its drawing: by the robot's top
; (TOP_FOLLOWS_LEGS), and through SET_WIPE_AND_DRAW_FLAGS -- which sets bits 4
; and 5 of the object's flags first -- by the legs and most other update
; routines. It works out the object's new screen rectangle (CALC_2D_INFO),
; forms the smallest rectangle covering that and the one it had at the start of
; the turn (+$1C to +$1F, copied there by the main loop, AFTER_GAME), and walks
; all 56 records setting the draw flag, bit 4 of +$07, on every live object
; whose rectangle meets it -- the moving object itself included.
;
; Across, the rectangles are measured in byte columns (pixel x over 8); up, in
; pixel rows from the bottom of the screen. E is the union's first column and D
; its width in columns; L its lowest row and H its height. Only the moving
; object's rectangle is used: an object redrawn because it meets it does not in
; turn mark the objects that meet it. Pentagram's routine, instruction for
; instruction.
;
; IX the object that has moved
SET_DRAW_OBJS_OVERLAPPED:
  LD IY,OBJECTS           ; IY = the first record; the new rectangle into +$18
  CALL CALC_2D_INFO       ; to +$1B
  LD B,$38                ; 56 records
  LD A,(IX+$1A)           ; L = the new first column
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  AND $1F                 ;
  LD L,A                  ;
  LD A,(IX+$1E)           ; H = the old first column
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  AND $1F                 ;
  LD H,A                  ;
  CP L                            ; E = whichever is further left
  JR C,SET_DRAW_OBJS_OVERLAPPED_0 ;
  LD A,L                          ;
SET_DRAW_OBJS_OVERLAPPED_0:
  LD E,A                          ;
  LD A,L                           ; D = the further right-hand edge, less E:
  ADD A,(IX+$18)                   ; the width in columns
  LD L,A                           ;
  LD A,H                           ;
  ADD A,(IX+$1C)                   ;
  CP L                             ;
  JR NC,SET_DRAW_OBJS_OVERLAPPED_1 ;
  LD A,L                           ;
SET_DRAW_OBJS_OVERLAPPED_1:
  SUB E                            ;
  LD D,A                           ;
  LD A,(IX+$1B)                   ; L = the lower of the two bottom rows
  CP (IX+$1F)                     ;
  JR C,SET_DRAW_OBJS_OVERLAPPED_2 ;
  LD A,(IX+$1F)                   ;
SET_DRAW_OBJS_OVERLAPPED_2:
  LD L,A                          ;
  LD A,(IX+$1B)                    ; H = the higher of the two tops, less L:
  ADD A,(IX+$19)                   ; the height
  LD H,A                           ;
  LD A,(IX+$1F)                    ;
  ADD A,(IX+$1D)                   ;
  CP H                             ;
  JR NC,SET_DRAW_OBJS_OVERLAPPED_3 ;
  LD A,H                           ;
SET_DRAW_OBJS_OVERLAPPED_3:
  SUB L                            ;
  LD H,A                           ;
OVERLAP_TEST_OBJ:
  LD A,(IY+$00)                   ; An empty record: next
  AND A                           ;
  JR Z,SET_DRAW_OBJS_OVERLAPPED_6 ;
  BIT 4,(IY+$07)                   ; Already to be drawn: next
  JR NZ,SET_DRAW_OBJS_OVERLAPPED_6 ;
  LD A,(IY+$1A)                   ; Its first column, less E; left of the
  RRCA                            ; union, see below
  RRCA                            ;
  RRCA                            ;
  AND $1F                         ;
  SUB E                           ;
  JR C,SET_DRAW_OBJS_OVERLAPPED_7 ;
  CP D                             ; Not left of the union: it meets it across
SET_DRAW_OBJS_OVERLAPPED_4:
  JR NC,SET_DRAW_OBJS_OVERLAPPED_6 ; if it starts inside
  LD A,(IY+$1B)                   ; Its bottom row, less L; below the union,
  SUB L                           ; see below
  JR C,SET_DRAW_OBJS_OVERLAPPED_8 ;
  CP H                             ; Not below: it meets it up and down if it
SET_DRAW_OBJS_OVERLAPPED_5:
  JR NC,SET_DRAW_OBJS_OVERLAPPED_6 ; starts inside
  SET 4,(IY+$07)          ; Draw it this turn
SET_DRAW_OBJS_OVERLAPPED_6:
  EXX                     ; The next record, D and E kept across the step
  LD DE,$0020             ;
  ADD IY,DE               ;
  EXX                     ;
  DJNZ OVERLAP_TEST_OBJ   ;
  RET                     ;
SET_DRAW_OBJS_OVERLAPPED_7:
  NEG                           ; To the left: it meets the union if the union
  CP (IY+$18)                   ; starts inside its width
  JR SET_DRAW_OBJS_OVERLAPPED_4 ;
SET_DRAW_OBJS_OVERLAPPED_8:
  NEG                           ; Below: it meets the union if the union starts
  CP (IY+$19)                   ; inside its height
  JR SET_DRAW_OBJS_OVERLAPPED_5 ;

; The robot's top (graphics 32 to 43)
;
; The top has no movement of its own. Each turn it copies the legs' U, V, Z,
; half-sizes, height and flags, takes a height one less, sits 12 above the
; legs, and takes the legs' graphic plus 16 -- so it turns and steps with them:
; legs 16-23 and 24-27, top 32-39 and 40-43. Then it and whatever its old or
; new rectangle meets are marked to be drawn (SET_DRAW_OBJS_OVERLAPPED). The
; flags it copies carry the legs' mirror bit, and their draw bits, which the
; legs' update has just set (SET_WIPE_AND_DRAW_FLAGS).
;
; The legs' height is 12 by now (the tail of PLAYER_LEGS), so the top's is 11,
; from 12 up to 23: the robot's box is 23 high in all, the height the legs take
; on their own while he moves. Unlike Pentagram's body, the top is kept out of
; the collision tests only while the legs move (PLAYER_LEGS sets bit 1 of its
; flags around the move), so other things can land on it and meet it.
;
; A top marked killed (bit 6 of +$0D) marks the legs killed too and turns into
; the sparkle he dies in (START_SPARKLE); the legs' update does the same the
; other way.
;
; IX the top's record
TOP_FOLLOWS_LEGS:
  CALL DRAW_AT_L16_D3     ; Drawn 16 left and 3 down
  BIT 6,(IX+$0D)          ; Killed?
  JR Z,TOP_FOLLOWS_LEGS_0 ;
  SET 6,(IX-$13)          ; Then the legs are too; become the sparkle
  JP START_SPARKLE        ;
TOP_FOLLOWS_LEGS_0:
  PUSH IX                 ; IY = HL = the legs, the record below (-32)
  POP DE                  ;
  LD HL,$FFE0             ;
  ADD HL,DE               ;
  PUSH HL                 ;
  POP IY                  ;
  INC DE                  ; U, V, Z, the half-sizes, the height and the flags
  INC HL                  ; from the legs
  LD BC,$0007             ;
  LDIR                    ;
  DEC (IX+$06)            ; One less high
  LD A,(IY+$00)           ; The legs' graphic plus 16
  ADD A,$10               ;
  LD (IX+$00),A           ;
  LD A,(IY+$03)           ; 12 above the legs
  ADD A,$0C               ;
  LD (IX+$03),A           ;
  CALL SET_DRAW_OBJS_OVERLAPPED ; Have it and whatever it overlaps redrawn
  RET                           ;

; List the objects to be drawn
;
; Used by the routine at OBJECT_DONE.
;
; Called by the main loop (OBJECT_DONE) at the end of every turn, once every
; record has been updated. Writes into DRAW_LIST the number (0-55) of every
; record in use whose draw flag, bit 4 of +$07, is set, in record order, and an
; $FF after the last. RENDER_DYNAMIC_OBJECTS wipes the objects' old places from
; this list and SORT_AND_DRAW draws from it.
LIST_DRAWN:
  PUSH IX                 ; 56 records from the first; HL = the list; C = the
  LD B,$38                ; number; IX kept
  LD DE,$0020             ;
  LD IX,OBJECTS           ;
  LD HL,DRAW_LIST         ;
  LD C,$00                ;
LIST_DRAWN_0:
  LD A,(IX+$00)           ; An empty record: not listed
  AND A                   ;
  JR Z,LIST_DRAWN_1       ;
  BIT 4,(IX+$07)          ; Not to be drawn this turn
  JR Z,LIST_DRAWN_1       ;
  LD (HL),C               ; List its number
  INC HL                  ;
LIST_DRAWN_1:
  INC C                   ; The next record
  ADD IX,DE               ;
  DJNZ LIST_DRAWN_0       ;
  LD A,$FF                ; End the list
  LD (HL),A               ;
  POP IX                  ;
  RET                     ;

; The objects to draw this turn
;
; Filled by LIST_DRAWN every turn: record numbers, then $FF. While
; SORT_AND_DRAW works through the list it sets bit 7 of each entry as that
; object is drawn, so the list also says what is still to do;
; RENDER_DYNAMIC_OBJECTS reads it first to wipe what moved. All zero on the
; tape.
;
; 64 bytes: room for all 56 records and the $FF, with seven to spare.
; Pentagram's list, 48 bytes for 54 records, can overflow into the code after
; it; this one cannot. Measured in the simulator over the build's room tour
; (every room in turn, a few seconds of walking in each): the longest list was
; 51, first reached around room $74.
DRAW_LIST:
  DEFS $40

; Draw the listed objects, back to front
;
; Used by the routine at RENDER_DYNAMIC_OBJECTS.
;
; Called by RENDER_DYNAMIC_OBJECTS every turn. This is where the game decides
; what is in front of what; the code is Knight Lore's and Pentagram's. Every
; listed object is a box in the room: centre U and V with half-sizes at +$04
; and +$05, a base Z with its whole height at +$06. The far side of anything is
; towards smaller U, larger V and lower Z (measured in Pentagram, whose code
; this is).
;
; It takes the first object in DRAW_LIST not yet drawn as the candidate (IX)
; and compares it with every other undrawn one (IY). If some IY has to be drawn
; before the candidate, IY becomes the candidate and the comparison starts
; again from the top of the list; a candidate that survives a whole pass is
; drawn, marked done, and the whole thing starts over. So each object drawn has
; nothing undrawn behind it.
;
; The comparison classifies the two boxes on each axis -- IX clear on one side,
; overlapping, IY clear on one side -- and adds the three into an index 0-26
; into DEPTH_ORDER. The order found need not be consistent (three boxes can
; each be behind the next), so the chain of candidates is kept in
; CANDIDATE_CHAIN, and meeting an object already in it breaks the circle by
; drawing that object at once.
;
; DRAW_WORK counts the objects drawn; RENDER_DYNAMIC_OBJECTS adds the
; rectangles it wiped, and the main loop waits less the more work a turn has
; done. SORT_FIRST and SORT_SECOND point just past the candidate's entry and
; the compared object's.
;
; O:IX kept
; O:IY kept
SORT_AND_DRAW:
  XOR A                   ; No objects drawn yet; keep IX and IY
  LD (DRAW_WORK),A        ;
  PUSH IX                 ;
  PUSH IY                 ;
; This entry point is used by the routines at IY_GOES_FIRST and DRAW_CANDIDATE.
SORT_PASS:
  LD DE,DRAW_LIST         ; A pass: from the top of the list
SORT_AND_DRAW_0:
  LD A,(DE)               ; The end of the list: everything is drawn
  INC DE                  ;
  CP $FF                  ;
  JP Z,ALL_DRAWN          ;
  BIT 7,A                 ; Bit 7: already drawn
  JR NZ,SORT_AND_DRAW_0   ;
  CALL GET_PTR_OBJECT     ; IX = the candidate; SORT_FIRST just past its entry
  LD (SORT_FIRST),DE      ;
  PUSH HL                 ;
  POP IX                  ;
; This entry point is used by the routines at ORDER_UNCONSTRAINED,
; CANDIDATE_ALREADY_FIRST, IY_GOES_FIRST and BOXES_INTERSECT.
COMPARE_NEXT_OBJ:
  LD A,(DE)               ; The end of the list: nothing is behind the
  INC DE                  ; candidate, so draw it
  CP $FF                  ;
  JP Z,DRAW_CANDIDATE     ;
  BIT 7,A                 ; Already drawn: skip
  JR NZ,COMPARE_NEXT_OBJ  ;
  CALL GET_PTR_OBJECT     ; IY = this object; SORT_SECOND just past its entry
  LD (SORT_SECOND),DE     ;
  PUSH HL                 ;
  POP IY                  ;
  PUSH IX                 ; The candidate itself: skip
  POP BC                  ;
  AND A                   ;
  SBC HL,BC               ;
  JR Z,COMPARE_NEXT_OBJ   ;
  LD C,$00                ; Z: code 0 if the candidate's base is at or above
  LD A,(IY+$03)           ; IY's top
  ADD A,(IY+$06)          ;
  LD L,A                  ;
  LD A,(IX+$03)           ;
  SUB L                   ;
  JR NC,COMPARE_ALONG_V   ;
  LD A,(IX+$03)           ; Code 2 if IY's base is at or above the candidate's
  ADD A,(IX+$06)          ; top, 1 if they overlap
  LD L,A                  ;
  LD A,(IY+$03)           ;
  SUB L                   ;
  JR C,SORT_AND_DRAW_1    ;
  INC C                   ;
SORT_AND_DRAW_1:
  INC C                   ;
COMPARE_ALONG_V:
  LD A,(IY+$02)           ; V: add 0 if the candidate's low-V edge is at or
  ADD A,(IY+$05)          ; beyond IY's high-V edge, the candidate lying wholly
  LD L,A                  ; further back
  LD A,(IX+$02)           ;
  SUB (IX+$05)            ;
  SUB L                   ;
  JR NC,COMPARE_ALONG_U   ;
  LD A,(IX+$02)           ; Add 6 if IY lies wholly further back, 3 if they
  ADD A,(IX+$05)          ; overlap
  LD L,A                  ;
  LD A,(IY+$02)           ;
  SUB (IY+$05)            ;
  SUB L                   ;
  LD A,C                  ;
  JR C,SORT_AND_DRAW_2    ;
  ADD A,$03               ;
SORT_AND_DRAW_2:
  ADD A,$03               ;
  LD C,A                  ;
COMPARE_ALONG_U:
  LD A,(IY+$01)           ; U: add 0 if the candidate's low-U edge is at or
  ADD A,(IY+$04)          ; beyond IY's high-U edge, IY lying wholly further
  LD L,A                  ; back
  LD A,(IX+$01)           ;
  SUB (IX+$04)            ;
  SUB L                   ;
  JR NC,ACT_ON_COMPARISON ;
  LD A,(IX+$01)           ; Add 18 if the candidate lies wholly further back, 9
  ADD A,(IX+$04)          ; if they overlap
  LD L,A                  ;
  LD A,(IY+$01)           ;
  SUB (IY+$04)            ;
  SUB L                   ;
  LD A,C                  ;
  JR C,SORT_AND_DRAW_3    ;
  ADD A,$09               ;
SORT_AND_DRAW_3:
  ADD A,$09               ;
  LD C,A                  ;
ACT_ON_COMPARISON:
  LD L,C                  ; Jump through DEPTH_ORDER, as the main loop jumps
  LD BC,DEPTH_ORDER       ; through the update table
  JP JUMP_THROUGH_TABLE   ;

; What to do about a pair of boxes
;
; 27 routine addresses, indexed by the Z code (0 the candidate above, 1
; overlapping, 2 IY above) + the V code (0 the candidate further back, 3
; overlapping, 6 IY further back) + the U code (0 IY further back, 9
; overlapping, 18 the candidate further back), as SORT_AND_DRAW works them out.
; "Further back" is smaller U, larger V, lower Z. The table is Knight Lore's
; and Pentagram's, entry for entry.
;
; Four outcomes. IY_GOES_FIRST when IY is behind or level with the candidate on
; all three axes and strictly behind on at least one: IY must be drawn first.
; CANDIDATE_ALREADY_FIRST for the mirror image, where the candidate is behind
; IY and is being drawn first anyway. ORDER_UNCONSTRAINED where each is in
; front of the other on some axis, which says nothing about their order.
; BOXES_INTERSECT, index 13, for boxes that overlap on every axis.
DEPTH_ORDER:
  DEFW ORDER_UNCONSTRAINED ; 0 (Z0 V0 U0): no constraint; 1 (Z1 V0 U0): no
  DEFW ORDER_UNCONSTRAINED ; constraint; 2 (Z2 V0 U0): no constraint; 3 (Z0 V3
  DEFW ORDER_UNCONSTRAINED ; U0): IY first
  DEFW IY_GOES_FIRST       ;
  DEFW IY_GOES_FIRST       ; 4 (Z1 V3 U0): IY first; 5 (Z2 V3 U0): no
  DEFW ORDER_UNCONSTRAINED ; constraint; 6 (Z0 V6 U0): IY first; 7 (Z1 V6 U0):
  DEFW IY_GOES_FIRST       ; IY first
  DEFW IY_GOES_FIRST       ;
  DEFW ORDER_UNCONSTRAINED     ; 8 (Z2 V6 U0): no constraint; 9 (Z0 V0 U9): no
  DEFW ORDER_UNCONSTRAINED     ; constraint; 10 (Z1 V0 U9): candidate first; 11
  DEFW CANDIDATE_ALREADY_FIRST ; (Z2 V0 U9): candidate first
  DEFW CANDIDATE_ALREADY_FIRST ;
  DEFW IY_GOES_FIRST           ; 12 (Z0 V3 U9): IY first; 13 (Z1 V3 U9): the
  DEFW BOXES_INTERSECT         ; boxes intersect; 14 (Z2 V3 U9): candidate
  DEFW CANDIDATE_ALREADY_FIRST ; first; 15 (Z0 V6 U9): IY first
  DEFW IY_GOES_FIRST           ;
  DEFW IY_GOES_FIRST           ; 16 (Z1 V6 U9): IY first; 17 (Z2 V6 U9): no
  DEFW ORDER_UNCONSTRAINED     ; constraint; 18 (Z0 V0 U18): no constraint; 19
  DEFW ORDER_UNCONSTRAINED     ; (Z1 V0 U18): candidate first
  DEFW CANDIDATE_ALREADY_FIRST ;
  DEFW CANDIDATE_ALREADY_FIRST ; 20 (Z2 V0 U18): candidate first; 21 (Z0 V3
  DEFW ORDER_UNCONSTRAINED     ; U18): no constraint; 22 (Z1 V3 U18): candidate
  DEFW CANDIDATE_ALREADY_FIRST ; first; 23 (Z2 V3 U18): candidate first
  DEFW CANDIDATE_ALREADY_FIRST ;
  DEFW ORDER_UNCONSTRAINED ; 24 (Z0 V6 U18): no constraint; 25 (Z1 V6 U18): no
  DEFW ORDER_UNCONSTRAINED ; constraint; 26 (Z2 V6 U18): no constraint
  DEFW ORDER_UNCONSTRAINED ;

; A pair with no order between them
;
; Reached through DEPTH_ORDER. Each box is in front of the other along some
; axis, so neither has to be drawn first: on to the next object.
ORDER_UNCONSTRAINED:
  JP COMPARE_NEXT_OBJ     ; Next comparison

; The candidate is behind the other object
;
; Reached through DEPTH_ORDER. The candidate is to be drawn before IY, which is
; what will happen anyway. The same instruction as ORDER_UNCONSTRAINED.
CANDIDATE_ALREADY_FIRST:
  JP COMPARE_NEXT_OBJ     ; Next comparison

; The other object must be drawn first
;
; Reached through DEPTH_ORDER. IY is behind the candidate, so it becomes the
; candidate instead -- unless it is already in the chain of objects that have
; been candidates since the last draw (CANDIDATE_CHAIN), in which case the
; order has gone round in a circle and IY is drawn straight away.
IY_GOES_FIRST:
  LD HL,(SORT_SECOND)     ; C = IY's number, from its entry in the list
  DEC HL                  ;
  LD C,(HL)               ;
  LD DE,CANDIDATE_CHAIN     ; Search the chain for it
IY_GOES_FIRST_0:
  LD A,(DE)                 ;
  CP $FF                    ;
  JR Z,IY_BECOMES_CANDIDATE ;
  CP C                      ;
  JR Z,BREAK_ORDER_CYCLE    ;
  INC DE                    ;
  JR IY_GOES_FIRST_0        ;
IY_BECOMES_CANDIDATE:
  LD A,C                  ; Not there: add it, with a new $FF after it
  LD (DE),A               ;
  INC DE                  ;
  LD A,$FF                ;
  LD (DE),A               ;
  PUSH IY                 ; IX = IY, and SORT_FIRST = SORT_SECOND
  POP IX                  ;
  LD HL,(SORT_SECOND)     ;
  LD (SORT_FIRST),HL      ;
  LD DE,DRAW_LIST         ; Compare it with the whole list from the top, since
  JP COMPARE_NEXT_OBJ     ; it need not be the first undrawn entry
BREAK_ORDER_CYCLE:
  LD HL,DRAW_LIST         ; A circle: find IY's entry in the list (its number
IY_GOES_FIRST_1:
  LD A,(HL)               ; is certain to be there, so the exit to a new pass
  INC HL                  ; is never taken)
  CP $FF                  ;
  JP Z,SORT_PASS          ;
  CP C                    ;
  JR NZ,IY_GOES_FIRST_1   ;
  PUSH IY                 ; IX = IY; draw it, HL just past its entry
  POP IX                  ;
  JR DRAW_AND_NEXT_PASS   ;

; Two boxes occupy the same space
;
; Index 13 of DEPTH_ORDER: the boxes overlap on all three axes, and order does
; not come into it. As in Knight Lore, this is where a valve that shares its
; space with something else is destroyed. Unless either is out of the collision
; tests (bit 1 of the flags), a loose valve -- graphics 96 to 99 -- is turned
; into graphic 64, whose update (SPARKLE_STEP) steps it to 65, whose update
; (SPARKLE_END_PLACE) empties its place in PLACES and then the record: the
; valve is gone for the rest of the game. The candidate is checked first; only
; one of the pair is changed. Knight Lore does this to its collectables (types
; 96-102); Pentagram does nothing here.
;
; Measured in the simulator: a valve put in the start room where the robot
; appears, inside his box, was gone -- record and place emptied -- once he had
; appeared, with this routine's IY branch run; the same valve put above him
; came to rest on his top.
BOXES_INTERSECT:
  LD A,(IX+$07)           ; Either out of the collision tests: nothing to do
  OR (IY+$07)             ;
  AND $02                 ;
  JP NZ,COMPARE_NEXT_OBJ  ;
  LD A,(IX+$00)           ; The candidate a loose valve?
  SUB $60                 ;
  CP $04                  ;
  JR NC,BOXES_INTERSECT_0 ;
  LD (IX+$00),$40         ; Yes: destroy it
  JR BOXES_INTERSECT_1    ;
BOXES_INTERSECT_0:
  LD A,(IY+$00)           ; The other a loose valve?
  SUB $60                 ;
  CP $04                  ;
  JR NC,BOXES_INTERSECT_1 ;
  LD (IY+$00),$40         ; Yes: destroy it
BOXES_INTERSECT_1:
  JP COMPARE_NEXT_OBJ     ; Next comparison

; Draw the candidate and start the next pass
;
; Used by the routine at SORT_AND_DRAW.
;
; The end of the list was reached with nothing found that has to be drawn
; before the candidate. Its entry is marked drawn (bit 7), the candidate chain
; emptied, the object counted in DRAW_WORK and drawn
; (CALC_PIXEL_XY_AND_RENDER); then back to the top of the list for the next.
; IY_GOES_FIRST comes in at DRAW_AND_NEXT_PASS to draw an object that closes a
; circle.
;
; IX the object
DRAW_CANDIDATE:
  LD HL,(SORT_FIRST)      ; HL = just past the candidate's entry
; This entry point is used by the routine at IY_GOES_FIRST.
DRAW_AND_NEXT_PASS:
  DEC HL                  ; Its entry: drawn
  SET 7,(HL)              ;
  LD A,$FF                ; The chain is empty again
  LD (CANDIDATE_CHAIN),A  ;
  LD HL,DRAW_WORK         ; One more object drawn this turn
  INC (HL)                ;
  CALL CALC_PIXEL_XY_AND_RENDER ; Draw it; then the next pass
  JP SORT_PASS                  ;

; All the listed objects are drawn
;
; Used by the routine at SORT_AND_DRAW.
;
; The end of SORT_AND_DRAW: its caller's IX and IY back.
ALL_DRAWN:
  POP IY
  POP IX
  RET

; The chain of candidates since the last draw
;
; Record numbers, ended by $FF, of every object IY_GOES_FIRST has made the
; candidate since DRAW_CANDIDATE last drew something; DRAW_CANDIDATE empties it
; by putting an $FF in the first byte. All $FF on the tape.
;
; Nothing checks the chain's length: sixteen bytes hold fifteen numbers and the
; $FF, twice Knight Lore's eight, and a sixteenth link would put its $FF on the
; first byte of READ_CONTROLS. Measured in the simulator over the build's room
; tour: the longest chain was 8, first reached around room $12 -- one more than
; Knight Lore's eight bytes could have held.
CANDIDATE_CHAIN:
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF

; Read the controls
;
; Used by the routines at PLAYER_LEGS and TURNING_LEGS.
;
; Reads the keyboard or a joystick, by the method in bits 1-2 of CONTROL, into
; one byte for this turn: the legs' update routines (PLAYER_LEGS, TURNING_LEGS)
; use it in C, and it is kept in INPUT for the pick-up (CHK_PICKUP_DROP).
;
; The keyboard: Z, C, M and B turn left and X, V, SYMBOL SHIFT and N right; the
; whole of the A-G and H-ENTER rows walk; the whole of the Q-T and Y-P rows
; jump; any number key picks up or puts down. CAPS SHIFT and SPACE do nothing
; here (SPACE pauses, HANDLE_PAUSE). The joysticks: left and right turn, up
; walks, fire jumps and down picks up or puts down. The Kempston is read from
; port 31; the cursor keys are 5 left, 8 right, 7 up, 6 down and 0 fire;
; Interface II is the keys 6-0 for one stick and 1-5 for the other, read
; together.
;
; Bit 5 is set, whatever the method, by any letter key, ENTER or SYMBOL SHIFT
; -- everything but CAPS SHIFT, SPACE and the number keys. With directional
; control on a joystick, where down is a direction, it is the pick-up in place
; of bit 4 (CHK_PICKUP_DROP), as in Knight Lore. While the game is won or the
; scene after a game runs (WON, GAME_OVER) only bit 5 is read: the robot takes
; no orders.
;
; Pentagram's is the same but for its fire button, and it has no bit 5.
;
; O:A the controls: bit 0 turn left, 1 turn right, 2 walk, 3 jump, 4 pick up or
;     put down, 5 any letter key
; O:C the same
READ_CONTROLS:
  LD A,(WON)              ; Won, or the scene after a game: nothing but bit 5
  LD C,A                  ;
  LD A,(GAME_OVER)        ;
  OR C                    ;
  LD C,$00                ;
  JP NZ,READ_LETTER_KEYS  ;
  LD A,(CONTROL)          ; Bits 1-2 of CONTROL: 0 keyboard, 1 Kempston, 2
  RRCA                    ; cursor keys...
  AND $03                 ;
  JP Z,READ_KEYBOARD      ;
  DEC A                   ;
  JR Z,READ_KEMPSTON      ;
  DEC A                   ;
  JR Z,READ_CURSOR        ;
  LD A,$F7                ; ...3 Interface II: keys 1-5, their order reversed
  CALL READ_KEYS          ; into C, so that 5 is bit 0 and 1 is bit 4, as 0 and
  PUSH BC                 ; 6 are on the other half-row
  LD B,$05                ;
READ_CONTROLS_0:
  RRA                     ;
  RL C                    ;
  DJNZ READ_CONTROLS_0    ;
  LD A,C                  ;
  POP BC                  ;
  LD C,A                  ;
  LD A,$EF                ; OR in keys 6-0: bit 0 fire (0 or 5), 1 up (9 or 4),
  CALL READ_KEYS          ; 2 down (8 or 3), 3 right (7 or 2), 4 left (6 or 1)
  OR C                    ;
  LD C,$00                ; Fire: jump
  BIT 0,A                 ;
  JR Z,READ_CONTROLS_1    ;
  SET 3,C                 ;
READ_CONTROLS_1:
  BIT 1,A                 ; Up: walk
  JR Z,READ_CONTROLS_2    ;
  SET 2,C                 ;
READ_CONTROLS_2:
  BIT 2,A                 ; Down: pick up or put down
  JR Z,READ_CONTROLS_3    ;
  SET 4,C                 ;
READ_CONTROLS_3:
  BIT 3,A                 ; Right: turn right
  JR Z,READ_CONTROLS_4    ;
  SET 1,C                 ;
READ_CONTROLS_4:
  BIT 4,A                 ; Left: turn left; then bit 5
  JR Z,READ_CONTROLS_5    ;
  SET 0,C                 ;
READ_CONTROLS_5:
  JP READ_LETTER_KEYS     ;
READ_KEMPSTON:
  IN A,($1F)              ; The Kempston joystick: bit 0, right, turns right
  LD C,$00                ;
  BIT 0,A                 ;
  JR Z,READ_CONTROLS_6    ;
  SET 1,C                 ;
READ_CONTROLS_6:
  BIT 1,A                 ; Bit 1, left: turn left
  JR Z,READ_CONTROLS_7    ;
  SET 0,C                 ;
READ_CONTROLS_7:
  BIT 2,A                 ; Bit 2, down: pick up or put down
  JR Z,READ_CONTROLS_8    ;
  SET 4,C                 ;
READ_CONTROLS_8:
  BIT 3,A                 ; Bit 3, up: walk
  JR Z,READ_CONTROLS_9    ;
  SET 2,C                 ;
READ_CONTROLS_9:
  BIT 4,A                 ; Bit 4, fire: jump; then bit 5
  JR Z,READ_CONTROLS_10   ;
  SET 3,C                 ;
READ_CONTROLS_10:
  JP READ_LETTER_KEYS     ;
READ_CURSOR:
  LD C,$00                ; The cursor keys: 5 turns left
  LD A,$F7                ;
  CALL READ_KEYS          ;
  BIT 4,A                 ;
  JR Z,READ_CONTROLS_11   ;
  SET 0,C                 ;
READ_CONTROLS_11:
  LD A,$EF                ; 0: jump
  CALL READ_KEYS          ;
  BIT 0,A                 ;
  JR Z,READ_CONTROLS_12   ;
  SET 3,C                 ;
READ_CONTROLS_12:
  BIT 3,A                 ; 7: walk
  JR Z,READ_CONTROLS_13   ;
  SET 2,C                 ;
READ_CONTROLS_13:
  BIT 2,A                 ; 8: turn right
  JR Z,READ_CONTROLS_14   ;
  SET 1,C                 ;
READ_CONTROLS_14:
  BIT 4,A                 ; 6: pick up or put down; then bit 5
  JR Z,READ_LETTER_KEYS   ;
  SET 4,C                 ;
  JR READ_LETTER_KEYS     ;
READ_KEYBOARD:
  LD A,$FE                ; The keyboard. CAPS SHIFT to V: Z and C brought down
  CALL READ_KEYS          ; to bit 0, turn left, and X and V to bit 1, turn
  RRCA                    ; right; CAPS SHIFT dropped
  LD C,A                  ;
  AND $03                 ;
  SRL C                   ;
  SRL C                   ;
  OR C                    ;
  AND $03                 ;
  LD C,A                  ;
  LD A,$7F                ; SYMBOL SHIFT turns right...
  CALL READ_KEYS          ;
  BIT 1,A                 ;
  JR Z,READ_CONTROLS_15   ;
  SET 1,C                 ;
READ_CONTROLS_15:
  BIT 2,A                 ; ...M left...
  JR Z,READ_CONTROLS_16   ;
  SET 0,C                 ;
READ_CONTROLS_16:
  BIT 3,A                 ; ...N right...
  JR Z,READ_CONTROLS_17   ;
  SET 1,C                 ;
READ_CONTROLS_17:
  BIT 4,A                 ; ...B left
  JR Z,READ_CONTROLS_18   ;
  SET 0,C                 ;
READ_CONTROLS_18:
  LD A,$BD                ; Any key on the A-G or H-ENTER rows (both half-rows
  CALL READ_KEYS          ; at once): walk
  JR Z,READ_CONTROLS_19   ;
  SET 2,C                 ;
READ_CONTROLS_19:
  LD A,$DB                ; Any on the Q-T or Y-P rows: jump
  CALL READ_KEYS          ;
  JR Z,READ_CONTROLS_20   ;
  SET 3,C                 ;
READ_CONTROLS_20:
  LD A,$E7                ; Any number key: pick up or put down
  CALL READ_KEYS          ;
  JR Z,READ_LETTER_KEYS   ;
  SET 4,C                 ;
READ_LETTER_KEYS:
  LD A,$7E                ; Any of Z, X, C, V, SYMBOL SHIFT, M, N and B, or of
  CALL READ_KEYS          ; the four other letter half-rows: bit 5
  AND $1E                 ;
  PUSH BC                 ;
  LD B,A                  ;
  LD A,$99                ;
  CALL READ_KEYS          ;
  OR B                    ;
  POP BC                  ;
  JR Z,READ_CONTROLS_21   ;
  SET 5,C                 ;
READ_CONTROLS_21:
  LD A,C                  ; This turn's controls into INPUT, and in A and C
  LD (INPUT),A            ;
  RET                     ;

; Start a life
;
; Used by the routine at AFTER_GAME.
;
; Called by the main loop at the start of every game and after every death
; (AFTER_GAME, OBJECT_DONE). Copies the two start records (START_LEGS) over the
; robot's -- as a game starts (NEW_GAME_START), or as he last came through a
; doorway (EXIT_LOW_U) -- and takes a life. The copies' graphic is 56, so he
; appears through graphics 56-63 (PLAYER_APPEARING) and then takes the graphic
; kept at +$10 (PLAYER_APPEARED).
;
; The first call of a game takes the five lives to four; below zero, after the
; fifth death, the game is over (GAME_ENDED).
;
; O:IX the legs' record
NEW_LIFE:
  LD HL,START_LEGS        ; Both records, legs and top; IX on the legs
  LD DE,OBJECTS           ;
  PUSH DE                 ;
  POP IX                  ;
  LD BC,$0040             ;
  LDIR                    ;
  LD HL,LIVES             ; A life fewer; below zero, the game is over
  DEC (HL)                ;
  JP M,GAME_ENDED         ;
  RET                     ;

; The start records
;
; Two object records of 32 bytes, the robot's legs and top as a life starts:
; NEW_LIFE copies them over OBJECTS. All zero on the tape. At a new game
; NEW_GAME_START fills the first eight bytes of each, the room and the graphic
; kept at +$10, and AFTER_GAME clears the legs' +$0C; as the robot comes
; through a doorway EXIT_LOW_U copies his whole records here, walk into the
; room and all, so a life starts where he last came in. Whatever else a record
; holds is what the last doorway left.
START_LEGS:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; The legs: graphic, U, V, Z,
                                       ; half-sizes, height, flags
START_LEGS_ROOM:
  DEFB $00                ; The room
  DEFB $00,$00,$00,$00,$00,$00,$00 ; The step in U, V and Z; +C, the walk into
                                   ; a room (bits 4-7) and the jump (bit 3),
                                   ; which a doorway leaves set and AFTER_GAME
                                   ; clears at every new game; +D, +E, +F
START_LEGS_NEXT:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; +10: the legs' own graphic, which the
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; appearing robot takes at the end
                                       ; (PLAYER_APPEARED); then the rest of
                                       ; the record
START_TOP:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; The top: graphic, U, V, Z, half-sizes,
                                       ; height, flags
START_TOP_ROOM:
  DEFB $00                ; The room
  DEFB $00,$00,$00,$00,$00,$00,$00 ; The step in U, V and Z, +C, +D, +E, +F
START_TOP_NEXT:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; +10: the top's own graphic, as for the
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; legs; then the rest of the record

; The start of the robot's records at a new game
;
; Eight bytes for each of the two records, copied into the first eight bytes of
; the two start records (START_LEGS) by NEW_GAME_START: graphic 56, the first
; of the appearing robot's; U and V 128, the middle of the room; Z 64, the
; floor, and 76 for the top, 12 above; half-sizes 7 and 7; heights 12 and 11;
; and flags with bits 2, 3 and 4 set -- carried by what he stands on
; (ADJ_DZ_FOR_OBJ_INTERSECT), able to use a doorway (CHK_PLYR_NEAR_ARCH), and
; drawn.
START_TEMPLATE:
  DEFB $38,$80,$80,$40,$07,$07,$0C,$1C ; The legs
  DEFB $38,$80,$80,$4C,$07,$07,$0B,$1C ; The top

; Set the start records for a new game
;
; Used by the routine at AFTER_GAME.
;
; Called at every new game (AFTER_GAME), before the first NEW_LIFE. Copies
; START_TEMPLATE into the first eight bytes of each start record, gives each
; the graphic it takes once it has appeared -- 22 for the legs, facing higher
; U, and 38 for the top -- and picks the start room from START_ROOMS by bits
; 0-1 of SEED.
NEW_GAME_START:
  LD HL,START_TEMPLATE    ; Graphic, position, sizes and flags of each
  LD DE,START_LEGS        ;
  LD BC,$0008             ;
  LDIR                    ;
  LD DE,START_TOP         ;
  LD BC,$0008             ;
  LDIR                    ;
  LD A,$16                ; The graphics they take once they have appeared
  LD (START_LEGS_NEXT),A  ;
  LD A,$26                ;
  LD (START_TOP_NEXT),A   ;
  LD A,(SEED)             ; One of four rooms, by bits 0-1 of SEED
  AND $03                 ;
  LD L,A                  ;
  LD H,$00                ;
  LD BC,START_ROOMS       ;
  ADD HL,BC               ;
  LD A,(HL)               ; Into both records
  LD (START_LEGS_ROOM),A  ;
  LD (START_TOP_ROOM),A   ;
  RET                     ;

; The four start rooms
;
; Indexed by bits 0-1 of SEED (NEW_GAME_START). In the simulator the seed is
; always the same, and a game starts in room $4E.
START_ROOMS:
  DEFB $13                ; Room $13: row 1, column 3
  DEFB $4E                ; Room $4E: row 4, column 14
  DEFB $88                ; Room $88: row 8, column 8
  DEFB $D7                ; Room $D7: row 13, column 7

; Build the room he is in
;
; Used by the routine at AFTER_GAME.
;
; Called from the main loop (AFTER_GAME) at the start of every life and after
; every walk through a doorway (EXIT_LOW_U), with IX on the legs. Puts the
; valves of the room being left back into their places (UPDATE_SPECIAL_OBJS) --
; unless no turn has been played since the game began (PLAYED) -- builds the
; room's records (BUILD_ROOM), clears the screen buffer (CLEAR_SCRN_BUFFER),
; fills the two valve records from the places (FIND_SPECIAL_OBJS_HERE), and
; puts the robot in the doorway he came in by if he came through one
; (ADJUST_PLYR_UVZ_FOR_ROOM_SIZE).
;
; Then the room's state: nothing dropping from the ceiling (DROPPING), no
; orders for the remote-controlled robots (REMOTE_ORDERS), LEAPING cleared, and
; DROP_LATCH set in an even-numbered room, so that nothing drops there until
; something is picked up. NEW_ROOM tells the main loop to redraw the whole
; screen, and the room is marked seen (MARK_ROOM_SEEN).
;
; IX the legs' record
ENTER_ROOM:
  LD A,(PLAYED)            ; A turn has been played: the valves in the room
  AND A                    ; being left back into their places
  JR Z,ENTER_ROOM_0        ;
  CALL UPDATE_SPECIAL_OBJS ;
ENTER_ROOM_0:
  CALL BUILD_ROOM         ; Build the room
  CALL CLEAR_SCRN_BUFFER  ; Clear the screen buffer
  CALL FIND_SPECIAL_OBJS_HERE ; The valves in this room into their records
  CALL ADJUST_PLYR_UVZ_FOR_ROOM_SIZE ; In by a doorway: stand him in it
  XOR A                   ; Nothing dropping, no orders for the
  LD (DROPPING),A         ; remote-controlled robots, LEAPING cleared
  LD (REMOTE_ORDERS),A    ;
  LD (LEAPING),A          ;
  LD A,(PLAYER_ROOM)      ; DROP_LATCH: 1 in an even-numbered room
  CPL                     ;
  AND $01                 ;
  LD (DROP_LATCH),A       ;
  LD A,$01                ; NEW_ROOM
  LD (NEW_ROOM),A         ;
  JP MARK_ROOM_SEEN       ; Mark the room seen

; Give every room back its own colour
;
; Used by the routine at AFTER_GAME.
;
; Called at every new game (AFTER_GAME). A room's third byte holds its colour
; twice: bits 3-5 as the tape has it, and bits 0-2, the ink in use, which an
; activated chamber turns white (LOOSE_VALVE). This copies bits 3-5 into bits
; 0-2 in every record of the room directory (ROOM02), stepping from one to the
; next by the count at +1, so a new game starts with no chamber activated.
RESET_ROOM_COLOURS:
  LD HL,ROOM02            ; The room directory and its end; HL on the first
  LD BC,OBJECT_TABLE      ; record's count
  INC HL                  ;
RESET_ROOM_COLOURS_0:
  LD E,(HL)               ; E = the count; HL on the third byte
  INC HL                  ;
  LD A,(HL)               ; Bits 3-5 into bits 0-2
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  AND $07                 ;
  LD D,A                  ;
  LD A,(HL)               ;
  AND $F8                 ;
  OR D                    ;
  LD (HL),A               ;
  LD D,$00                ; On to the next record's count
  ADD HL,DE               ;
  AND A                   ; Until the end of the directory
  SBC HL,BC               ;
  RET NC                  ;
  ADD HL,BC               ;
  JR RESET_ROOM_COLOURS_0 ;

; Copy a sprite's four bytes into the drawing record
;
; Used by the routines at TRANSFER_SPRITE_AND_PRINT, DISPLAY_PANEL and
; PRINT_BORDER.
;
; Graphic, flags, x and y into +0, +7, +$1A and +$1B, where the sprite drawing
; (CALC_PIXEL_XY_AND_RENDER) finds them. Used by TRANSFER_SPRITE_AND_PRINT,
; DISPLAY_PANEL and PRINT_BORDER to draw the panel and the border piece by
; piece. As Knight Lore's transfer_sprite and Pentagram's TRANSFER_SPRITE.
;
;   HL the four-byte entry
;   IX the record to draw with
; O:HL the next entry
TRANSFER_SPRITE:
  LD A,(HL)               ; The graphic; the flags (bit 6 mirrored)
  INC HL                  ;
  LD (IX+$00),A           ;
  LD A,(HL)               ;
  INC HL                  ;
  LD (IX+$07),A           ;
  LD A,(HL)               ; X and y, in pixels
  INC HL                  ;
  LD (IX+$1A),A           ;
  LD A,(HL)               ;
  INC HL                  ;
  LD (IX+$1B),A           ;
  RET                     ;

; Copy a sprite's four bytes and draw it
;
; Used by the routines at DISPLAY_PANEL and PRINT_BORDER.
;
; TRANSFER_SPRITE puts the graphic, the flags, x and y of a four-byte entry
; into +0, +7, +$1A and +$1B of the record at IX, and PRINT_SPRITE (in
; CALC_PIXEL_XY_AND_RENDER) draws it at that pixel position, with no
; projection. HL is kept on the next entry. As Knight Lore's
; transfer_sprite_and_print.
;
;   HL the four-byte entry
;   IX the record to draw with, the spare one at PANEL_RECORD
; O:HL the next entry
TRANSFER_SPRITE_AND_PRINT:
  CALL TRANSFER_SPRITE    ; Graphic, flags, x and y into the record
  PUSH HL                 ; Draw it, keeping HL
  CALL PRINT_SPRITE       ;
  POP HL                  ;
  RET

; Draw the panel's scroll-work and icons at the foot of the screen
;
; Used by the routine at OBJECT_DONE.
;
; Draws the twelve pieces of PANEL_DATA into the buffer through the spare
; record at PANEL_RECORD: on each side a slanting run of five of graphic 9,
; stepping 16 pixels in and 8 down, a column of six of graphic 10 up the edge,
; and graphics 7 and 8 at the ends, the right side the left mirrored; then
; three icons -- the robot (graphic 12) beside the lives, the frame round the
; light years (graphic 84, in two mirrored halves), and graphic 131 beside the
; count of chambers activated, which PRINT_CHAMBERS prints at (32, 31). That is
; the only place graphic 131 is drawn, which is why it has a sprite but no
; update routine. Where each entry lands was measured: the routine run in the
; simulator, and run again with each entry's graphic made 0, the difference
; being that entry's pixels.
;
; Called from the main loop (OBJECT_DONE) on the first turn in a new room,
; before COLOUR_PANEL colours the panel and prints its numbers and SHOW_BUFFER
; shows the whole buffer. Knight Lore's display_panel draws the same kind of
; scroll-work from six entries; the icons are Alien 8's.
DISPLAY_PANEL:
  LD IX,PANEL_RECORD      ; IX = the spare record; the first entry
  LD HL,PANEL_DATA        ;
  CALL TRANSFER_SPRITE    ;
  LD DE,$F810                ; The left run: five, each 16 pixels right and 8
  LD B,$05                   ; down
  CALL MULTIPLE_PRINT_SPRITE ;
  CALL TRANSFER_SPRITE       ; Six up the left edge, 8 pixels apart
  LD DE,$0800                ;
  LD B,$06                   ;
  CALL MULTIPLE_PRINT_SPRITE ;
  CALL TRANSFER_SPRITE_AND_PRINT ; Graphic 7 above the edge, and graphic 8 at
  CALL TRANSFER_SPRITE_AND_PRINT ; the foot of the run
  CALL TRANSFER_SPRITE       ; The right run: five, each 16 pixels left and 8
  LD DE,$F8F0                ; down
  LD B,$05                   ;
  CALL MULTIPLE_PRINT_SPRITE ;
  CALL TRANSFER_SPRITE       ; Six up the right edge
  LD DE,$0800                ;
  LD B,$06                   ;
  CALL MULTIPLE_PRINT_SPRITE ;
  CALL TRANSFER_SPRITE_AND_PRINT ; Graphics 7 and 8 on the right, mirrored
  CALL TRANSFER_SPRITE_AND_PRINT ;
  CALL TRANSFER_SPRITE_AND_PRINT ; The robot beside the lives
  CALL TRANSFER_SPRITE_AND_PRINT ; The two halves of the frame round the light
  CALL TRANSFER_SPRITE_AND_PRINT ; years
  JP TRANSFER_SPRITE_AND_PRINT ; The icon beside the chambers count

; The pieces of the panel
;
; Twelve entries of four bytes, as TRANSFER_SPRITE reads them: the graphic, the
; flags (bit 6 mirrored, bit 7 upside down), then x and y in pixels, y counting
; up from the bottom of the screen. DISPLAY_PANEL draws some once and repeats
; others along a line. Two entries a line.
PANEL_DATA:
  DEFB $09,$00,$10,$30    ; Graphic 9 at (16, 48), the left run's first, five
  DEFB $0A,$00,$00,$00    ; of them; graphic 10 at (0, 0), six up the left edge
  DEFB $07,$00,$00,$30    ; Graphic 7 at (0, 48), once; graphic 8 at (96, 0),
  DEFB $08,$00,$60,$00    ; once
  DEFB $09,$40,$E0,$30    ; Graphic 9 mirrored at (224, 48), the right run's
  DEFB $0A,$40,$F8,$00    ; first; graphic 10 mirrored at (248, 0), six up the
                          ; right edge
  DEFB $07,$40,$F0,$30    ; Graphic 7 mirrored at (240, 48); graphic 8 mirrored
  DEFB $08,$40,$90,$00    ; at (144, 0)
  DEFB $0C,$00,$70,$00    ; Graphic 12, the robot, at (112, 0); graphic 84, the
  DEFB $54,$00,$E0,$09    ; right half of the light years' frame, at (224, 9)
  DEFB $54,$40,$C8,$09    ; Graphic 84 mirrored, the left half, at (200, 9);
  DEFB $83,$00,$08,$18    ; graphic 131, the chambers icon, at (8, 24)

; Draw the border round the screen
;
; Used by the routines at GAME_ENDED and DISPLAY_MENU.
;
; From BORDER_DATA, into the buffer through the spare record at PANEL_RECORD:
; the corner sprite (graphic 4) drawn four times, turned each way; the top and
; bottom edges as 24 pieces of graphic 6, 8 pixels apart; and the sides as 128
; of graphic 5 -- a sprite one pixel high -- a pixel apart. It frames the menu
; (DISPLAY_MENU, the first text list printed) and the screens after a game
; (GAME_ENDED); a room has none. Knight Lore's print_border, with the same
; counts and steps.
PRINT_BORDER:
  LD IX,PANEL_RECORD      ; IX = the spare record; the first entry
  LD HL,BORDER_DATA       ;
  CALL TRANSFER_SPRITE_AND_PRINT ; The four corners
  CALL TRANSFER_SPRITE_AND_PRINT ;
  CALL TRANSFER_SPRITE_AND_PRINT ;
  CALL TRANSFER_SPRITE_AND_PRINT ;
  CALL TRANSFER_SPRITE       ; The top edge: 24 pieces, 8 pixels apart
  LD DE,$0008                ;
  LD B,$18                   ;
  CALL MULTIPLE_PRINT_SPRITE ;
  CALL TRANSFER_SPRITE       ; The bottom edge, the same upside down
  LD B,$18                   ;
  CALL MULTIPLE_PRINT_SPRITE ;
  CALL TRANSFER_SPRITE       ; The left edge: 128 pieces, a pixel apart going
  LD DE,$0100                ; up
  LD B,$80                   ;
  CALL MULTIPLE_PRINT_SPRITE ;
  CALL TRANSFER_SPRITE     ; The right edge, mirrored
  LD B,$80                 ;
  JP MULTIPLE_PRINT_SPRITE ;

; The pieces of the border, and unreached code from Knight Lore
;
; Eight entries of four bytes for PRINT_BORDER, as in PANEL_DATA: graphic,
; flags (bit 6 mirrored, bit 7 upside down), x, y. The screen is 256 by 192;
; the corner is 32 pixels square.
;
; Then, from the 33rd byte, code that nothing calls or jumps to (the loaded
; block searched for its address): Knight Lore's colour_panel, which coloured
; the frame of that game's sun and moon window, byte for byte the same but for
; the address of the fill routine, here FILL_BOX. It blacks out columns 22 and
; 29 of rows 21 to 23 and makes columns 23 to 28 of rows 20 to 23 bright red.
; Alien 8 has no such window; its panel is coloured by COLOUR_PANEL. The code
; runs on across COLOUR_PANEL_RED and COLOUR_PANEL_TAIL, entries of their own
; only because the disassembler took those bytes for text and data.
BORDER_DATA:
  DEFB $04,$00,$00,$A0    ; Graphic 4, the corner, at (0, 160); mirrored at
  DEFB $04,$40,$E0,$A0    ; (224, 160)
  DEFB $04,$C0,$E0,$00    ; Graphic 4 mirrored and upside down at (224, 0);
  DEFB $04,$80,$00,$00    ; upside down at (0, 0)
  DEFB $06,$00,$20,$A8    ; Graphic 6 at (32, 168), the top edge's first;
  DEFB $06,$80,$20,$00    ; upside down at (32, 0), the bottom's
  DEFB $05,$00,$00,$20    ; Graphic 5 at (0, 32), the left edge's first;
  DEFB $05,$40,$E8,$20    ; mirrored at (232, 32), the right's
  XOR A                   ; Unreached: black, one byte wide and three rows
  LD HL,$5AB6             ; deep, at column 22 of row 21 and at column 29
  LD BC,$0103             ; (FILL_BOX fills B bytes by C rows with A)
  CALL FILL_BOX           ;
  LD HL,$5ABD             ;
  LD BC,$0103             ;
  CALL FILL_BOX           ;

; Unreached code, continued
;
; The part of the unreached code at BORDER_DATA that colours the frame bright
; red: LD A,$42, then the first byte of LD HL,$5A97 (row 20, column 23), whose
; other two bytes are the first of COLOUR_PANEL_TAIL.
COLOUR_PANEL_RED:
  DEFB $3E,$42,$21

; The rest of the unreached code
;
; The last two bytes of LD HL,$5A97; LD BC,$0604 (six bytes wide, four rows
; deep); JP to the fill routine at FILL_BOX. See BORDER_DATA.
COLOUR_PANEL_TAIL:
  DEFB $97,$5A,$01,$04,$06,$C3,$83,$BF

; Put the robot in the doorway he came in by
;
; Used by the routine at ENTER_ROOM.
;
; Called when a room has been built (ENTER_ROOM). The exit code leaves a U or V
; of 0 or $FF as a marker of the wall he walked out through: 0 in U means he
; left by a wall at low U and comes in by this room's wall at high U, $FF the
; other way, and the same for V. He is put with his inner edge 2 inside the
; wall's line, the rest of him in the doorway, and ADJUST_PLYR_Z_FOR_ARCH finds
; the arch in that wall and stands him on its floor. Without a marker -- a new
; game, or a life started where he last came in -- he stays where his record
; says.
;
; Both his records are flagged to be drawn, and the top is put at the legs' U
; and V. The walls are where the room's size puts them, so the doorway's place
; is worked out from ROOM_HALF_U and ROOM_HALF_V. As Knight Lore's
; adjust_plyr_xyz_for_room_size, with the same four U+V values for the arches.
;
; IX the robot's legs
ADJUST_PLYR_UVZ_FOR_ROOM_SIZE:
  LD A,(ROOM_HALF_U)      ; L, H = the room's half-sizes in U and V, less 2
  SUB $02                 ;
  LD L,A                  ;
  LD A,(ROOM_HALF_V)      ;
  SUB $02                 ;
  LD H,A                  ;
  LD A,(IX+$01)                        ; U 0: in at high U
  AND A                                ;
  JR Z,ADJUST_PLYR_UVZ_FOR_ROOM_SIZE_6 ;
  INC A                                ; U $FF: in at low U
  JR Z,ADJUST_PLYR_UVZ_FOR_ROOM_SIZE_4 ;
  LD A,(IX+$02)                        ; V 0: in at high V
  AND A                                ;
  JR Z,ADJUST_PLYR_UVZ_FOR_ROOM_SIZE_3 ;
  INC A                                ; V $FF: in at low V; no marker, nothing
  JR Z,ADJUST_PLYR_UVZ_FOR_ROOM_SIZE_0 ; to do
  RET                                  ;
ADJUST_PLYR_UVZ_FOR_ROOM_SIZE_0:
  LD C,$C8                    ; At low V: Z from the arch whose U+V is $C8, and
  CALL ADJUST_PLYR_Z_FOR_ARCH ; V puts his inner edge 2 inside the wall
  LD A,$80                    ;
  SUB H                       ;
  SUB (IX+$05)                ;
ADJUST_PLYR_UVZ_FOR_ROOM_SIZE_1:
  LD (IX+$02),A           ; Store V
ADJUST_PLYR_UVZ_FOR_ROOM_SIZE_2:
  SET 4,(IX+$07)          ; Both his records to be drawn (bit 4 of the flags)
  SET 4,(IX+$27)          ;
  LD A,(IX+$01)           ; The top at the legs' U and V
  LD (IX+$21),A           ;
  LD A,(IX+$02)           ;
  LD (IX+$22),A           ;
  RET                     ;
ADJUST_PLYR_UVZ_FOR_ROOM_SIZE_3:
  LD C,$52                           ; At high V: the arch whose U+V is $52
  CALL ADJUST_PLYR_Z_FOR_ARCH        ;
  LD A,H                             ;
  ADD A,$80                          ;
  ADD A,(IX+$05)                     ;
  JR ADJUST_PLYR_UVZ_FOR_ROOM_SIZE_1 ;
ADJUST_PLYR_UVZ_FOR_ROOM_SIZE_4:
  LD C,$AE                    ; At low U: the arch whose U+V is $AE
  CALL ADJUST_PLYR_Z_FOR_ARCH ;
  LD A,$80                    ;
  SUB L                       ;
  SUB (IX+$04)                ;
ADJUST_PLYR_UVZ_FOR_ROOM_SIZE_5:
  LD (IX+$01),A                      ; Store U
  JR ADJUST_PLYR_UVZ_FOR_ROOM_SIZE_2 ;
ADJUST_PLYR_UVZ_FOR_ROOM_SIZE_6:
  LD C,$38                           ; At high U: the arch whose U+V is $38
  CALL ADJUST_PLYR_Z_FOR_ARCH        ;
  LD A,L                             ;
  ADD A,$80                          ;
  ADD A,(IX+$04)                     ;
  JR ADJUST_PLYR_UVZ_FOR_ROOM_SIZE_5 ;

; Stand the robot on the floor of the arch he comes in by
;
; Used by the routine at ADJUST_PLYR_UVZ_FOR_ROOM_SIZE.
;
; The code takes a room's doorways to be its first backgrounds, two pieces
; each, a pillar of graphic 2 and one of graphic 3 (BACKGROUND0 and the three
; after it). The first pillars are then records 4, 6, 8 and 10, and the wall an
; arch is in is told by its first pillar's U + V (mod 256): $52 at high V, $38
; at high U, $C8 at low V, $AE at low U. The one wanted gives the legs its Z,
; and the top goes 12 above; that is what puts him at the right height in a
; raised doorway.
;
; The search stops at the first record that is not an arch pillar (graphic 4 or
; more) or after four; with no match Z is left alone. The RET after the fourth
; was never reached in the build's sessions. As Knight Lore's
; adjust_plyr_Z_for_arch, whose pillars are graphics 2 to 5.
;
; C the U + V of the arch wanted
; IX the robot's legs
ADJUST_PLYR_Z_FOR_ARCH:
  LD IY,ROOM_OBJECTS      ; Record 4, and every other record from there: four
  LD DE,$0040             ; doorways at most
  LD B,$04                ;
ADJUST_PLYR_Z_FOR_ARCH_0:
  LD A,(IY+$00)           ; Not an arch pillar: no more doorways
  CP $04                  ;
  RET NC                  ;
  LD A,(IY+$01)                 ; This arch?
  ADD A,(IY+$02)                ;
  CP C                          ;
  JR Z,ADJUST_PLYR_Z_FOR_ARCH_1 ;
  ADD IY,DE                     ; The next; none matched
  DJNZ ADJUST_PLYR_Z_FOR_ARCH_0 ;
  RET                           ;
ADJUST_PLYR_Z_FOR_ARCH_1:
  LD A,(IY+$03)           ; The legs' Z = the pillar's; the top 12 above
  LD (IX+$03),A           ;
  ADD A,$0C               ;
  LD (IX+$23),A           ;
  RET                     ;

; The address of the object record numbered A
;
; Used by the routines at SORT_AND_DRAW and RENDER_DYNAMIC_OBJECTS.
;
; Bit 7 of A is ignored: the draw list (DRAW_LIST) sets it on entries already
; drawn. BC is kept. As Knight Lore's get_ptr_object, from OBJECTS here.
;
;   A the record's number, 0-55
; O:HL the record
GET_PTR_OBJECT:
  PUSH BC
  AND $7F                 ; Drop bit 7
  LD L,A                  ; Times 32, plus the first record
  LD H,$00                ;
  ADD HL,HL               ;
  ADD HL,HL               ;
  ADD HL,HL               ;
  ADD HL,HL               ;
  ADD HL,HL               ;
  LD BC,OBJECTS           ;
  ADD HL,BC               ;
  POP BC
  RET

; Build a room's object records from the room directory
;
; Used by the routine at ENTER_ROOM.
;
; Finds the robot's room in ROOM02, stepping from record to record by the count
; at +1, and takes its ink (ROOM_INK), the address of its colour byte
; (ROOM_COLOUR_AT), and its half-sizes and floor from ROOM_SIZES. Then it fills
; the records from record 4 (ROOM_OBJECTS) up, backgrounds first, then objects,
; and clears every record after the last it filled. A room that is not in the
; directory gets no records at all. Called by ENTER_ROOM on entering a room;
; the first four records -- the robot's two and the two for the places -- are
; not touched.
;
; Backgrounds: a byte each, up to an $FF. A background (BACKGROUND_TABLE) is a
; list of eight-byte pieces -- graphic, U, V, Z, the half-sizes, the height,
; flags -- ended by a zero, each piece its own record, with this room as its
; +8.
;
; Objects: groups, each a header byte (bits 0-2 how many less one, bits 3-7 the
; template) and a position byte for each. A template (OBJECT_TABLE) is a list
; of five-byte pieces -- graphic, the half-sizes, the height, flags -- ended by
; a zero, each piece its own record at the same place: U = 72 + 16 times bits
; 0-2 of the position, V = 72 + 16 times bits 3-5, and Z = the floor + 12 times
; bits 6-7.
;
; Two templates are not templates. Template 31 moves TEMPLATES_AT on 64 bytes,
; to the second page, and the byte after it is skipped (twelve times in the
; rooms). Template 0 makes the byte after it the placement nudge (PLACE_NUDGE)
; for the groups that follow: its bit 0 adds 8 to U, bit 1 adds 8 to V, and the
; rest is added to Z. The rooms use it 42 times, 41 of them with $30, which
; raises the objects that follow by 48 -- four levels -- and once with 0.
; Pentagram's builder has the same code for the nudge but no jump reaches it;
; in Alien 8 it is live.
;
; The count at +1 of the room's record, of the bytes from there to the end, is
; what stops the build, not the data: the backgrounds can use it up, or a group
; be cut short. Nothing checks that the 52 records are enough; if a room
; overran them the clearing loop, which stops only when it reaches the end of
; the records exactly, would not stop. None does: every room was built in the
; build's sessions.
;
; IX the robot's legs, whose +8 is the room
BUILD_ROOM:
  LD HL,OBJECT_TABLE      ; The first page of object templates, no nudge;
  LD (TEMPLATES_AT),HL    ; LIFT_TOP cleared
  XOR A                   ;
  LD (PLACE_NUDGE),A      ;
  LD (LIFT_TOP),A         ;
  LD DE,ROOM_OBJECTS      ; DE = the first record to fill; BC = the end of the
  LD BC,OBJECT_TABLE      ; directory; HL = its first room
  LD HL,ROOM02            ;
BUILD_ROOM_0:
  LD A,(HL)               ; This room?
  INC HL                  ;
  CP (IX+$08)             ;
  JR Z,BUILD_ROOM_1       ;
  LD A,(HL)               ; No: on by the count, until the end of the directory
  CALL ADD_HL_A           ;
  AND A                   ;
  SBC HL,BC               ;
  JR NC,BUILD_CLEAR_REST  ;
  ADD HL,BC               ;
  JR BUILD_ROOM_0         ;
BUILD_CLEAR_REST:
  LD HL,BELOW_BLOCK       ; Clear the records from DE to the last; every way
  AND A                   ; out of the builder ends here
  SBC HL,DE               ;
  RET Z                   ;
  LD B,$20                ;
  CALL ZERO_DE            ;
  JR BUILD_CLEAR_REST     ;
BUILD_ROOM_1:
  LD B,(HL)               ; B = the count
  INC HL                  ;
  LD A,(HL)               ; The room's ink, and where its colour byte is
  AND $07                 ;
  LD (ROOM_INK),A         ;
  LD (ROOM_COLOUR_AT),HL  ;
  PUSH DE                 ; Bits 6-7 of the colour byte: which of the three
  EX DE,HL                ; sizes, times three
  LD A,(DE)               ;
  INC DE                  ;
  RLCA                    ;
  RLCA                    ;
  AND $03                 ;
  LD C,A                  ;
  ADD A,A                 ;
  ADD A,C                 ;
  LD HL,ROOM_SIZES        ; The half-sizes in U and V, and the floor
  CALL ADD_HL_A           ;
  LD A,(HL)               ;
  INC HL                  ;
  LD (ROOM_HALF_U),A      ;
  LD A,(HL)               ;
  INC HL                  ;
  LD (ROOM_HALF_V),A      ;
  LD A,(HL)               ;
  LD (FLOOR),A            ;
  DEC B                   ; Two of the count used; HL on the backgrounds, DE
  DEC B                   ; the record
  EX DE,HL                ;
  POP DE                  ;
BUILD_NEXT_BACKGROUND:
  LD A,(HL)               ; The backgrounds end at an $FF
  INC HL                  ;
  CP $FF                  ;
  JR Z,BUILD_OBJECTS      ;
  PUSH BC                 ; HL = the background, the place in the room's record
  PUSH HL                 ; kept
  LD L,A                  ;
  LD H,$00                ;
  ADD HL,HL               ;
  LD BC,BACKGROUND_TABLE  ;
  ADD HL,BC               ;
  LD A,(HL)               ;
  INC HL                  ;
  LD H,(HL)               ;
  LD L,A                  ;
BUILD_BACKGROUND_PIECE:
  LD BC,$0008             ; A piece: graphic, U, V, Z, half-sizes, height,
  LDIR                    ; flags into +0 to +7
  LD A,(IX+$08)           ; +8: this room
  LD (DE),A               ;
  INC DE                  ;
  LD B,$17                ; +9 to +31 cleared; DE on the next record
  CALL ZERO_DE            ;
  LD A,(HL)                    ; Another piece?
  AND A                        ;
  JR NZ,BUILD_BACKGROUND_PIECE ;
  POP HL                     ; The next background, while the count lasts
  POP BC                     ;
  DJNZ BUILD_NEXT_BACKGROUND ;
  JP BUILD_CLEAR_REST     ; The count ran out
BUILD_OBJECTS:
  DEC B                   ; The $FF counted
  PUSH IY                 ; IY = the next record; the caller's IY kept
  PUSH DE                 ;
  POP IY                  ;
BUILD_NEXT_GROUP:
  LD A,(HL)               ; C = how many in this group
  AND $07                 ;
  INC A                   ;
  LD C,A                  ;
  LD A,(HL)               ; The header counted; D = the first position; the
  INC HL                  ; place kept
  DEC B                   ;
  LD D,(HL)               ;
  INC HL                  ;
  PUSH HL                 ;
  RRCA                    ; The template number doubled; template 0 sets the
  RRCA                    ; nudge
  AND $3E                 ;
  JP Z,BUILD_SET_NUDGE    ;
  CP $3E                   ; Template 31 moves to the second page
  JP Z,BUILD_TEMPLATE_PAGE ;
  LD HL,(TEMPLATES_AT)    ; HL = the template, from the page in TEMPLATES_AT
  CALL ADD_HL_A           ;
  LD A,(HL)               ;
  INC HL                  ;
  LD H,(HL)               ;
  LD L,A                  ;
BUILD_NEXT_OBJECT:
  PUSH HL                 ; Kept for the next object of the group
BUILD_OBJECT_PIECE:
  LD A,(HL)               ; A piece: graphic into +0, half-sizes and height
  INC HL                  ; into +4 to +6, flags into +7
  LD (IY+$00),A           ;
  LD A,(HL)               ;
  INC HL                  ;
  LD (IY+$04),A           ;
  LD A,(HL)               ;
  INC HL                  ;
  LD (IY+$05),A           ;
  LD A,(HL)               ;
  INC HL                  ;
  LD (IY+$06),A           ;
  LD A,(HL)               ;
  INC HL                  ;
  LD (IY+$07),A           ;
  LD A,(IX+$08)           ; +8: this room
  LD (IY+$08),A           ;
  LD A,(PLACE_NUDGE)      ; U from bits 0-2 of the position, and 8 more for bit
  RLCA                    ; 0 of the nudge
  RLCA                    ;
  RLCA                    ;
  AND $08                 ;
  LD E,A                  ;
  LD A,D                  ;
  RLCA                    ;
  RLCA                    ;
  RLCA                    ;
  RLCA                    ;
  AND $70                 ;
  ADD A,E                 ;
  ADD A,$48               ;
  LD (IY+$01),A           ;
  LD A,(PLACE_NUDGE)      ; V from bits 3-5, and 8 more for bit 1 of the nudge
  RLCA                    ;
  RLCA                    ;
  AND $08                 ;
  LD E,A                  ;
  LD A,D                  ;
  RLCA                    ;
  AND $70                 ;
  ADD A,E                 ;
  ADD A,$48               ;
  LD (IY+$02),A           ;
  LD A,D                  ; Z from bits 6-7, 12 a level, plus the nudge less
  RLCA                    ; its bits 0-1, on the floor
  RLCA                    ;
  AND $03                 ;
  ADD A,A                 ;
  ADD A,A                 ;
  LD E,A                  ;
  ADD A,A                 ;
  ADD A,E                 ;
  LD E,A                  ;
  LD A,(PLACE_NUDGE)      ;
  ADD A,E                 ;
  AND $FC                 ;
  LD E,A                  ;
  LD A,(FLOOR)            ;
  ADD A,E                 ;
  LD (IY+$03),A           ;
  PUSH BC                 ; +9 to +31 cleared; IY on the next record
  LD BC,$0009             ;
  ADD IY,BC               ;
  LD B,$17                ;
BUILD_ROOM_2:
  LD (IY+$00),$00         ;
  INC IY                  ;
  DJNZ BUILD_ROOM_2       ;
  POP BC                  ;
  LD A,(HL)                ; Another piece?
  AND A                    ;
  JR NZ,BUILD_OBJECT_PIECE ;
  POP DE                  ; DE = the template, HL = the place in the room's
  POP HL                  ; record
  DEC B                   ; The position counted; the end of the count ends the
  JR Z,BUILD_OBJECTS_DONE ; room
  DEC C                   ; The end of the group: the next header
  JP Z,BUILD_NEXT_GROUP   ;
  LD A,(HL)               ; The next position, the same template
  INC HL                  ;
  PUSH HL                 ;
  EX DE,HL                ;
  LD D,A                  ;
  JP BUILD_NEXT_OBJECT    ;
BUILD_OBJECTS_DONE:
  PUSH IY                 ; DE = the next free record; the caller's IY back;
  POP DE                  ; clear the rest
  POP IY                  ;
  JP BUILD_CLEAR_REST     ;
BUILD_TEMPLATE_PAGE:
  LD HL,(TEMPLATES_AT)    ; Template 31: the next page of templates
  LD A,$40                ;
  CALL ADD_HL_A           ;
  LD (TEMPLATES_AT),HL    ;
BUILD_ROOM_3:
  DEC B                   ; The byte after the header counted and skipped; the
  POP HL                  ; next group
  JP BUILD_NEXT_GROUP     ;
BUILD_SET_NUDGE:
  LD A,D                  ; Template 0: the byte after it is the nudge
  LD (PLACE_NUDGE),A      ;
  JR BUILD_ROOM_3         ;

; HL = HL + A
;
; Used by the routines at COLOUR_CLOCK_BOX, REMOTE_ROBOT, SUMMARISE_CHAMBERS,
; PRINT_ROLLING_DIGIT, STEP_FROM_FACING, PLAY_NOTE, WARBLE_SOUND,
; HANDLE_LEFT_RIGHT, BUILD_ROOM and VFLIP_SPRITE_DATA.
;
; A is treated as unsigned, and comes back holding H. As Knight Lore's
; add_HL_A.
;
; HL a number
; A what to add
ADD_HL_A:
  ADD A,L
  LD L,A
  LD A,H
  ADC A,$00
  LD H,A
  RET

; HL = DE * A
;
; Used by the routine at VFLIP_SPRITE_DATA.
;
; Shift and add, taking the bits of A from the top; eight RLCAs bring A back to
; what it was, and BC is kept. Used only to find the length of a sprite's data
; (VFLIP_SPRITE_DATA). As Knight Lore's HL_equals_DE_x_A.
;
;   DE the multiplicand
;   A the multiplier
; O:HL the product
HL_EQUALS_DE_X_A:
  PUSH BC
  LD HL,$0000             ; HL = 0; eight bits
  LD B,$08                ;
HL_EQUALS_DE_X_A_0:
  ADD HL,HL                ; Double the total, and add DE if the next bit of A
  RLCA                     ; is set
  JR NC,HL_EQUALS_DE_X_A_1 ;
  ADD HL,DE                ;
HL_EQUALS_DE_X_A_1:
  DJNZ HL_EQUALS_DE_X_A_0  ;
  POP BC
  RET

; Clear B bytes from DE
;
; Used by the routines at SUMMARISE_CHAMBERS, FIND_SPECIAL_OBJS_HERE,
; TAKE_OR_LEAVE and BUILD_ROOM.
;
; DE is left just past the last byte, which is how the room builder
; (BUILD_ROOM) moves on to the next record. The entry point FILL_DE fills with
; A instead: COLOUR_PANEL colours parts of the panel with it. As Knight Lore's
; zero_DE and fill_DE.
;
;   DE the first byte
;   B how many
; O:DE just past the last
ZERO_DE:
  XOR A                   ; Zero
; This entry point is used by the routine at COLOUR_PANEL.
FILL_DE:
  LD (DE),A               ; Fill B bytes with A
  INC DE                  ;
  DJNZ FILL_DE            ;
  RET

; Pause, when SPACE is pressed on its own
;
; Used by the routine at OBJECT_DONE.
;
; Called once a turn by the main loop (OBJECT_DONE). READ_KEYS is given $7E,
; which selects two half-rows at once -- SPACE to B, and CAPS SHIFT to V --
; read with a key pressed as a set bit; SPACE and CAPS SHIFT share bit 0, so
; either on its own pauses. A beep (PAUSE_BEEP), a wait for the key to be let
; go, then for a press and a release, and a beep again.
;
; The pause is a busy wait with interrupts off: the game has no EI anywhere, so
; nothing runs while it waits. Pentagram's pause turns interrupts on while it
; waits; Knight Lore's and this one do not.
HANDLE_PAUSE:
  LD A,$7E                ; SPACE not pressed: no pause
  CALL READ_KEYS          ;
  BIT 0,A                 ;
  RET Z                   ;
  AND $1E                 ; Another key of the half-row with it: no pause
  RET NZ                  ;
HANDLE_PAUSE_0:
  LD A,$7E                ; Wait for it to be let go
  CALL READ_KEYS          ;
  BIT 0,A                 ;
  JR NZ,HANDLE_PAUSE_0    ;
  CALL PAUSE_BEEP         ; A beep
HANDLE_PAUSE_1:
  LD A,$7E                ; Wait for a press
  CALL READ_KEYS          ;
  BIT 0,A                 ;
  JR Z,HANDLE_PAUSE_1     ;
HANDLE_PAUSE_2:
  LD A,$7E                ; And for it to be let go
  CALL READ_KEYS          ;
  BIT 0,A                 ;
  JR NZ,HANDLE_PAUSE_2    ;
  JP PAUSE_BEEP           ; A beep, and back to the game

; Clear all 56 object records
;
; Used by the routine at GAME_ENDED.
;
; 1792 bytes from OBJECTS, the robot's records included: used when a game has
; ended (GAME_ENDED). The entry point CLR_MEM clears BC bytes from HL, and
; CLR_BYTE fills them with E; the start of a game clears the variables and
; records with CLR_MEM (START, AFTER_GAME). As Knight Lore's clr_mem and
; clr_byte.
;
; HL (CLR_MEM, CLR_BYTE) the first byte
; BC (CLR_MEM, CLR_BYTE) how many
; E (CLR_BYTE) the value
CLEAR_OBJECTS:
  LD HL,OBJECTS           ; All the records
  LD BC,$0700             ;
  JR CLR_MEM              ;
; This entry point is used by the routines at START, AFTER_GAME and
; CLR_BITMAP_MEMORY.
CLR_MEM:
  LD E,$00                ; Zero
; This entry point is used by the routines at CLR_ATTRIBUTE_MEMORY and
; CLEAR_SCRN_BUFFER.
CLR_BYTE:
  LD (HL),E               ; One at a time: BC is a 16-bit count
  INC HL                  ;
  DEC BC                  ;
  LD A,B                  ;
  OR C                    ;
  JR NZ,CLR_BYTE          ;
  RET                     ;

; Clear the display bitmap
;
; Used by the routine at CLEAR_SCRN.
;
; 6144 bytes from 16384, through CLR_MEM (CLEAR_OBJECTS). As Knight Lore's
; clr_bitmap_memory.
CLR_BITMAP_MEMORY:
  LD HL,$4000
  LD BC,$1800
  JR CLR_MEM

; Set every attribute to bright red on black
;
; Used by the routines at GAME_ENDED and CLEAR_SCRN.
;
; $42 is BRIGHT, black paper, red ink. The entry point FILL_ATTR sets every
; attribute to A: COLOUR_PANEL fills the screen with the room's ink, BRIGHT, on
; black, as a room is first shown. Knight Lore's clr_attribute_memory sets
; bright yellow; its fill_attr is the same.
;
; A (FILL_ATTR) the attribute
CLR_ATTRIBUTE_MEMORY:
  LD A,$42
; This entry point is used by the routine at COLOUR_PANEL.
FILL_ATTR:
  LD E,A
  LD HL,$5800
  LD BC,$0300
  JR CLR_BYTE

; Clear the screen and make the border black
;
; Used by the routines at AFTER_GAME, GAME_ENDED and ARRIVAL_SCREEN.
;
; A black border, the attributes bright red on black (CLR_ATTRIBUTE_MEMORY),
; and the bitmap cleared (CLR_BITMAP_MEMORY). Used at the start of every game
; (AFTER_GAME) and by the screens after a game (GAME_ENDED, ARRIVAL_SCREEN). As
; Knight Lore's clear_scrn.
CLEAR_SCRN:
  XOR A
  OUT ($FE),A
  CALL CLR_ATTRIBUTE_MEMORY
  JR CLR_BITMAP_MEMORY

; Clear the screen buffer
;
; Used by the routines at GAME_ENDED, ARRIVAL_SCREEN, MENU and ENTER_ROOM.
;
; 6144 bytes of BUFFER, through CLR_BYTE (CLEAR_OBJECTS): on entering a room
; (ENTER_ROOM), on the menu (MENU) and on the screens after a game. As Knight
; Lore's clear_scrn_buffer.
CLEAR_SCRN_BUFFER:
  LD BC,$1800
  LD HL,BUFFER
  LD E,$00
  JR CLR_BYTE

; Copy the screen buffer to the screen
;
; Used by the routines at OBJECT_DONE, GAME_ENDED and DISPLAY_MENU.
;
; All 192 rows of 32 bytes from BUFFER. The buffer runs the other way up from
; the display -- its first row is the bottom line of the screen -- because the
; game's pixel y counts up from the bottom; so the copy starts at the display's
; bottom-left byte and works up a line at a time. Used on the first turn in a
; room (OBJECT_DONE) and for the text screens (DISPLAY_MENU, GAME_ENDED).
; Knight Lore's update_screen clears the buffer as it copies; this one, like
; Pentagram's, leaves it as it is.
SHOW_BUFFER:
  LD HL,BUFFER            ; From the buffer's first row to the display's bottom
  LD DE,$57E0             ; line; 192 rows
  LD BC,$C020             ;
SHOW_BUFFER_0:
  PUSH BC                 ; A row of 32 bytes; HL runs on to the next row by
  PUSH DE                 ; itself
  LD B,$00                ;
  LDIR                    ;
  POP DE                  ;
  DEC D                   ; Up a display line, unless that crossed a character
  LD A,D                  ; row
  CPL                     ;
  AND $07                 ;
  JR NZ,SHOW_BUFFER_1     ;
  LD A,E                  ; Crossing a character row: back 32 in E, and back
  SUB $20                 ; into this third unless that borrowed
  LD E,A                  ;
  JR C,SHOW_BUFFER_1      ;
  LD A,D                  ;
  ADD A,$08               ;
  LD D,A                  ;
SHOW_BUFFER_1:
  POP BC                  ; The next row
  DEC B                   ;
  JR NZ,SHOW_BUFFER_0     ;
  RET

; Redraw what changed and copy it to the screen
;
; Used by the routine at OBJECT_DONE.
;
; Called at the end of every turn (OBJECT_DONE). The draw list (DRAW_LIST)
; holds the number of every record to be drawn this turn, up to an $FF, and
; SEQUENCE_AT steps through it. First, for each one that moved -- bit 5 of its
; flags, cleared here -- the area covering both where it was drawn last turn
; (+1C to +1F) and where it is now (+18 to +1B) is cleared in the buffer and
; remembered on the stack, WIPE_COUNT counting them. Then every listed object
; is drawn into the buffer in depth order (SORT_AND_DRAW), and the carried
; things on the panel if they changed (SHOW_CARRIED); and last the remembered
; areas -- and only those -- are copied to the screen.
;
; Nothing is ever rubbed out on the screen itself, so nothing flickers: the
; scenery is made of objects too, so what stood behind a moving thing is simply
; drawn again. On the first turn in a room (NEW_ROOM set) nothing is wiped: the
; buffer is freshly built and the main loop shows all of it. The areas count
; towards the turn's drawing work (DRAW_WORK), which sets how long the main
; loop waits. Pentagram's routine, instruction for instruction; Knight Lore's
; does the same in more pieces.
RENDER_DYNAMIC_OBJECTS:
  XOR A                   ; No areas yet
  LD (WIPE_COUNT),A       ;
  PUSH IX                 ; Kept for the caller
  LD A,(NEW_ROOM)                ; The first turn in a room: nothing to wipe
  AND A                          ;
  JP NZ,RENDER_DYNAMIC_OBJECTS_8 ;
  LD HL,DRAW_LIST         ; From the start of the draw list
  LD (SEQUENCE_AT),HL     ;
RENDER_DYNAMIC_OBJECTS_0:
  LD HL,(SEQUENCE_AT)           ; The next record's number; $FF ends the list
  LD A,(HL)                     ;
  INC HL                        ;
  LD (SEQUENCE_AT),HL           ;
  CP $FF                        ;
  JP Z,RENDER_DYNAMIC_OBJECTS_8 ;
  CALL GET_PTR_OBJECT     ; IX = the record
  PUSH HL                 ;
  POP IX                  ;
  BIT 5,(IX+$07)                ; Bit 5 of the flags: it moved; the others in
  JR Z,RENDER_DYNAMIC_OBJECTS_0 ; the list are only being drawn again
  RES 5,(IX+$07)          ; Only once
  LD A,(IX+$1A)                 ; C = the further left of the new pixel x (+1A)
  SUB (IX+$1E)                  ; and the old (+1E)
  JP C,RENDER_DYNAMIC_OBJECTS_6 ;
  LD C,(IX+$1E)                 ;
RENDER_DYNAMIC_OBJECTS_1:
  LD A,(IX+$1E)           ; The old right edge in bytes: old x / 8 + old width
  RRCA                    ; (+1C)
  RRCA                    ;
  RRCA                    ;
  AND $1F                 ;
  ADD A,(IX+$1C)          ;
  LD E,A                  ;
  LD A,(IX+$1A)                 ; The new one: new x / 8 + new width (+18); E =
  RRCA                          ; the further right
  RRCA                          ;
  RRCA                          ;
  AND $1F                       ;
  ADD A,(IX+$18)                ;
  CP E                          ;
  JR C,RENDER_DYNAMIC_OBJECTS_2 ;
  LD E,A                        ;
RENDER_DYNAMIC_OBJECTS_2:
  LD A,C                  ; H = the width in bytes, from the left edge's byte
  RRCA                    ; to the right edge
  RRCA                    ;
  RRCA                    ;
  AND $1F                 ;
  LD B,A                  ;
  LD A,E                  ;
  SUB B                   ;
  LD H,A                  ;
  LD A,(IX+$1B)                 ; B = the lower of the new pixel y (+1B) and
  SUB (IX+$1F)                  ; the old (+1F)
  JR C,RENDER_DYNAMIC_OBJECTS_7 ;
  LD B,(IX+$1F)                 ;
RENDER_DYNAMIC_OBJECTS_3:
  LD A,(IX+$1F)           ; The old top: old y + old height (+1D)
  ADD A,(IX+$1D)          ;
  LD E,A                  ;
  LD A,(IX+$1B)                  ; The new top: new y + new height (+19); A =
  ADD A,(IX+$19)                 ; the higher
  CP E                           ;
  JR NC,RENDER_DYNAMIC_OBJECTS_4 ;
  LD A,E                         ;
RENDER_DYNAMIC_OBJECTS_4:
  SUB B                   ; L = the height in rows
  LD L,A                  ;
  LD A,B                         ; An area that starts above the top of the
  CP $C0                         ; screen has nothing to wipe
  JR NC,RENDER_DYNAMIC_OBJECTS_0 ;
  ADD A,L                       ; If it runs past line 192, keep only the part
  SUB $C0                       ; below
  JR C,RENDER_DYNAMIC_OBJECTS_5 ;
  NEG                           ;
  ADD A,L                       ;
  LD L,A                        ;
RENDER_DYNAMIC_OBJECTS_5:
  CALL CALC_VRAM_ADDR     ; DE = its display address, BC = its buffer address
  CALL CALC_VIDBUF_ADDR   ;
  LD A,L                  ; Rearranged: HL = the buffer address, B = the width,
  LD L,C                  ; C = the height
  LD C,A                  ;
  LD A,H                  ;
  LD H,B                  ;
  LD B,A                  ;
  LD A,(WIPE_COUNT)       ; One more area
  INC A                   ;
  LD (WIPE_COUNT),A       ;
  PUSH BC                 ; On the stack until the objects have been drawn
  PUSH DE                 ;
  PUSH HL                 ;
  XOR A                   ; Cleared in the buffer: FILL_BOX fills B bytes by C
  CALL FILL_BOX           ; rows with A
  JP RENDER_DYNAMIC_OBJECTS_0 ; The next record
RENDER_DYNAMIC_OBJECTS_6:
  LD C,(IX+$1A)               ; The new x is the further left
  JR RENDER_DYNAMIC_OBJECTS_1 ;
RENDER_DYNAMIC_OBJECTS_7:
  LD B,(IX+$1B)               ; The new y is the lower
  JR RENDER_DYNAMIC_OBJECTS_3 ;
RENDER_DYNAMIC_OBJECTS_8:
  CALL SORT_AND_DRAW      ; Every listed object into the buffer, in depth order
  CALL SHOW_CARRIED       ; The carried things on the panel, if they changed
  LD HL,WIPE_COUNT        ; The areas count towards the turn's drawing work
  LD A,(DRAW_WORK)        ;
  ADD A,(HL)              ;
  LD (DRAW_WORK),A        ;
RENDER_DYNAMIC_OBJECTS_9:
  LD HL,WIPE_COUNT               ; None left to copy
  LD A,(HL)                      ;
  AND A                          ;
  JR Z,RENDER_DYNAMIC_OBJECTS_10 ;
  DEC (HL)                ; Take one off the stack, with the width and height
  POP HL                  ; swapped into the order BLIT_TO_SCREEN takes them
  POP DE                  ;
  POP BC                  ;
  LD A,B                  ;
  LD B,C                  ;
  LD C,A                  ;
  CALL BLIT_TO_SCREEN         ; Copy it to the screen; the next
  JR RENDER_DYNAMIC_OBJECTS_9 ;
RENDER_DYNAMIC_OBJECTS_10:
  POP IX                  ; Done
  RET                     ;

; Copy a rectangle of the buffer to the screen
;
; Used by the routines at RUN_CLOCK, SHOW_CARRIED, BLIT_2X8 and
; RENDER_DYNAMIC_OBJECTS.
;
; Works up the screen a row at a time, as SHOW_BUFFER does: for the areas
; RENDER_DYNAMIC_OBJECTS wiped, the carried things on the panel (SHOW_CARRIED),
; and pieces of the panel redrawn in place (RUN_CLOCK, BLIT_2X8). As Knight
; Lore's blit_to_screen.
;
; HL the buffer address of its bottom-left byte
; DE the display address of the same byte
; B the height in rows
; C the width in bytes
BLIT_TO_SCREEN:
  PUSH BC                 ; One row: B is cleared so that LDIR copies C bytes
  PUSH DE                 ;
  PUSH HL                 ;
  LD B,$00                ;
  LDIR                    ;
  POP HL                  ; The buffer row above is 32 bytes on
  LD DE,$0020             ;
  ADD HL,DE               ;
  POP DE                  ; Up a display line, unless that crossed a character
  DEC D                   ; row
  LD A,D                  ;
  CPL                     ;
  AND $07                 ;
  JR NZ,BLIT_TO_SCREEN_0  ;
  LD A,E                  ; Crossing a character row: back 32 in E, and back
  SUB $20                 ; into this third unless that borrowed
  LD E,A                  ;
  JR C,BLIT_TO_SCREEN_0   ;
  LD A,D                  ;
  ADD A,$08               ;
  LD D,A                  ;
BLIT_TO_SCREEN_0:
  POP BC                  ; The next row
  DJNZ BLIT_TO_SCREEN     ;
  RET

; Build the drawing tables
;
; Used by the routine at AFTER_GAME.
;
; Fills the fifteen pages from MIRROR_TABLE up with tables the sprite drawing
; needs every turn, run at the start of every game before the menu
; (AFTER_GAME).
;
; The fourteen above MIRROR_TABLE are the shifted bytes, in pairs: for each
; shift s from 1 to 7, page $F0 + 2s holds every byte value shifted right s
; places, and the page above it the bits that fall out into the next byte. Both
; are stored complemented, so that one value both clears the buffer under a
; sprite's mask and lets its image in (SPRITE_SHIFTED_RUN). The loop builds
; them the other way about: it shifts each value left across two bytes, one
; place at a time, and stores the pair after each shift from the top page down,
; so shift s is the value shifted left 8 - s.
;
; MIRROR_TABLE itself is every byte value with its bits in the opposite order,
; which is how a sprite is mirrored (VFLIP_SPRITE_DATA). The layout is Knight
; Lore's build_lookup_tbls.
BUILD_LOOKUP_TBLS:
  LD L,$00                ; Every byte value, L from 0
SHIFT_TBL_VALUE:
  LD D,$00                ; DE = the value; H on the top page; seven shifts
  LD E,L                  ;
  LD H,$FF                ;
  LD B,$07                ;
SHIFT_TBL_ENTRY:
  SLA E                   ; One more place left across D and E
  RL D                    ;
  LD A,E                  ; E complemented, on this page
  CPL                     ;
  LD (HL),A               ;
  DEC H                   ;
  LD A,D                  ; D complemented, on the page below
  CPL                     ;
  LD (HL),A               ;
  DEC H                   ;
  DJNZ SHIFT_TBL_ENTRY    ; The next shift
  INC L                   ; The next value, until L wraps to 0
  JR NZ,SHIFT_TBL_VALUE   ;
  LD HL,MIRROR_TABLE      ; Then the bit reversal
REVERSE_TBL_VALUE:
  LD D,L                  ; Eight bits out of the bottom of D into the bottom
  LD B,$08                ; of E: E is the value reversed
REVERSE_TBL_BIT:
  SRL D                   ;
  RL E                    ;
  DJNZ REVERSE_TBL_BIT    ;
  LD (HL),E               ; Store it; the next value, until L wraps to 0
  INC L                   ;
  JR NZ,REVERSE_TBL_VALUE ;
  RET

; Project an object's position onto the screen
;
; Used by the routines at CALC_PIXEL_XY_IY, CALC_2D_INFO and
; CALC_PIXEL_XY_AND_RENDER.
;
; The isometric projection. U, V and Z (+1 to +3) become a pixel x in +1A and a
; pixel y in +1B, counted up from the bottom of the screen: pixel x = U + V -
; 128, and pixel y = (V - U + 128) / 2 + Z - 40, each with the drawing nudge
; (+12, +13) added. Knight Lore takes 104 where this takes 40, since its floors
; are lower; and Pentagram's version stops a pixel x below 0 at 0, which this
; does not.
;
; While GAME_OVER is set nothing is projected, and carry comes back set: the
; scene after a game (SCENE_TOOL) places its sprites by pixel, writing +1A and
; +1B itself.
;
;   IX the object
; O:F carry set if the pixel y is below 192, that is on the screen
CALC_PIXEL_XY:
  LD A,(GAME_OVER)        ; After a game: no projection, and drawn wherever +1A
  AND A                   ; and +1B say
  SCF                     ;
  RET NZ                  ;
  LD A,(IX+$01)           ; Pixel x: U + V - 128, plus the nudge
  ADD A,(IX+$02)          ;
  SUB $80                 ;
  ADD A,(IX+$12)          ;
  LD (IX+$1A),A           ;
  LD A,(IX+$02)           ; Pixel y: (V - U + 128) / 2 + Z - 40, plus the nudge
  SUB (IX+$01)            ;
  ADD A,$80               ;
  SRL A                   ;
  ADD A,(IX+$03)          ;
  SUB $28                 ;
  ADD A,(IX+$13)          ;
  LD (IX+$1B),A           ;
  CP $C0                  ; Carry set if it is on the screen
  RET                     ;

; Find an object's sprite and make it face the right way
;
; Used by the routines at CALC_2D_INFO and CALC_PIXEL_XY_AND_RENDER.
;
; The graphic (+0) indexes GRAPHICS for the sprite. A sprite whose first byte
; is 0 draws nothing: the routine then drops its own return address, so its RET
; leaves its caller too. Otherwise it jumps to VFLIP_SPRITE_DATA, which turns
; the sprite's data to match the object's flags and returns to the caller with
; DE on the width byte. As Knight Lore's flip_sprite.
;
;   IX the object
; O:DE the sprite's width byte
FLIP_SPRITE:
  LD L,(IX+$00)           ; DE = the sprite, from the graphic table
  LD H,$00                ;
  ADD HL,HL               ;
  LD BC,GRAPHICS          ;
  ADD HL,BC               ;
  LD E,(HL)               ;
  INC HL                  ;
  LD D,(HL)               ;
  LD A,(DE)               ; A real sprite: turn it, and return from there
  AND A                   ;
  JP NZ,VFLIP_SPRITE_DATA ;
  INC SP                  ; None: return from the caller as well
  INC SP                  ;
  RET                     ;

; Draw one object from the draw list
;
; Used by the routine at DRAW_CANDIDATE.
;
; Called by the depth sort (DRAW_CANDIDATE) for each listed object in turn,
; back to front. Graphic 1 marks an object on its way out of the room's records
; -- a thing picked up (TAKE_OR_LEAVE), or at the end of SPARKLE_END_PLACE --
; and is not drawn: its record is emptied instead, which frees it. Anything
; else loses its draw flag (bit 4 of +7), is projected onto the screen by
; CALC_PIXEL_XY, and is drawn by the entry point PRINT_SPRITE unless its pixel
; y is 192 or more, wholly above the screen.
;
; PRINT_SPRITE draws whatever sprite IX's graphic names at the pixel position
; already in +1A and +1B, with no projection: the panel and the border
; (TRANSFER_SPRITE_AND_PRINT, MULTIPLE_PRINT_SPRITE) and the carried things
; (SHOW_CARRIED) are drawn with it, through the spare record at PANEL_RECORD.
;
; A sprite is a width byte (bits 0-3 the width in bytes, bits 6 and 7 how it is
; stored now, turned or not), a height byte, and then a mask byte and an image
; byte for each byte of each row, the bottom row first. Each buffer byte is
; cleared where the mask is set and has the image put in, so an object punches
; its own shape out of whatever was drawn behind it.
;
; The row loop is unrolled for the widest sprite, five bytes, twice: a plain
; run for a sprite whose pixel x is a multiple of 8 (SPRITE_ALIGNED_RUN), and a
; shifted run that reads its bytes through the tables above MIRROR_TABLE and so
; touches one byte more per row (SPRITE_SHIFTED_RUN). This routine patches the
; offset of the JR in SPRITE_ROW to enter the right run as many units from its
; end as the sprite is wide, and the operand of the ADD at the foot of
; SPRITE_SHIFTED_RUN with the step from the end of one row to the start of the
; next. The stack pointer reads the sprite: SP is pointed at the data and each
; POP DE fetches a mask into E and its image into D, the real SP kept in
; SAVED_SP meanwhile. The game never enables interrupts, so nothing pushes onto
; the sprite.
;
; On the way out +18 holds the width in bytes that was drawn (one more than the
; sprite's own when shifted) and +19 the height, cut to the rows below the top
; of the screen; the main loop copies them and the pixel position to +1C to +1F
; before the next turn's update, so RENDER_DYNAMIC_OBJECTS knows what to rub
; out. Nothing is clipped at the sides or the bottom. As Knight Lore's
; calc_pixel_XY_and_render and print_sprite.
;
; IX the object
CALC_PIXEL_XY_AND_RENDER:
  LD A,(IX+$00)           ; Graphic 1: empty the record instead
  CP $01                  ;
  JR NZ,PROJECT_AND_DRAW  ;
  LD (IX+$00),$00         ;
  RET                     ;
PROJECT_AND_DRAW:
  RES 4,(IX+$07)          ; Drawn now: off the draw list's flag
  CALL CALC_PIXEL_XY      ; Pixel position into +1A and +1B; above the screen,
  RET NC                  ; nothing to draw
; This entry point is used by the routines at MULTIPLE_PRINT_SPRITE,
; SHOW_CARRIED and TRANSFER_SPRITE_AND_PRINT.
PRINT_SPRITE:
  CALL FLIP_SPRITE        ; DE = the sprite's width byte, the sprite turned the
                          ; way the object faces; an empty sprite returns from
                          ; here at once
  LD A,(IX+$1A)           ; The pixel x within its byte; 0 goes to the aligned
  AND $07                 ; case, SPRITE_ALIGNED
  JR Z,SPRITE_ALIGNED     ;
  RLCA                    ; H = $F0 + 2 * the shift: the page pair of
  AND $0E                 ; BUILD_LOOKUP_TBLS's tables for that shift
  OR $F0                  ;
  LD H,A                  ;
  LD A,(DE)               ; The width from the width byte (bits 0-2 here), plus
  INC DE                  ; one: the bytes a shifted row touches, into +18
  AND $07                 ;
  INC A                   ;
  LD B,A                  ;
  LD (IX+$18),A           ;
  DEC A                   ; The JR's offset: 16 bytes of code per byte of
  AND $07                 ; width, back from the end of the shifted run at
  ADD A,A                 ; SPRITE_SHIFTED_RUN
  ADD A,A                 ;
  ADD A,A                 ;
  ADD A,A                 ;
  NEG                     ;
  ADD A,$50               ;
PATCH_SPRITE_ROWS:
  LD ($D0BC),A            ; The offset, into the JR in SPRITE_ROW
  LD A,B                  ; The step to the next row, into the ADD at the foot
  CPL                     ; of SPRITE_SHIFTED_RUN: 33 less the bytes touched,
  ADD A,$22               ; since a row moves BC on one fewer than that
  LD ($D110),A            ;
  LD A,(DE)               ; The height, into +19
  INC DE                  ;
  LD (IX+$19),A           ;
  ADD A,(IX+$1B)          ; If the sprite would run past the top of the screen,
  SUB $C0                 ; only the rows below it: 192 less the pixel y
  JR C,DRAW_SPRITE_ROWS   ;
  NEG                     ;
  ADD A,(IX+$19)          ;
  LD (IX+$19),A           ;
DRAW_SPRITE_ROWS:
  LD C,(IX+$1A)           ; BC = the buffer address of the sprite's bottom-left
  LD B,(IX+$1B)           ; byte (CALC_VIDBUF_ADDR)
  CALL CALC_VIDBUF_ADDR   ;
  LD (SAVED_SP),SP        ; SP onto the mask and image bytes, the real one kept
  EX DE,HL                ; in SAVED_SP
  LD SP,HL                ;
  EX DE,HL                ;
  LD A,(IX+$19)           ; A = the rows to draw; into the loop
  JR SPRITE_ROW           ;
SPRITE_ALIGNED:
  LD A,(DE)               ; The aligned case: the width (bits 0-3), into +18; B
  INC DE                  ; = the bytes a row touches
  AND $0F                 ;
  LD (IX+$18),A           ;
  LD B,A                  ;
  ADD A,A                 ; The JR's offset: 8 bytes of code per byte of width,
  ADD A,A                 ; back from the end of the aligned run at
  ADD A,A                 ; SPRITE_ALIGNED_RUN
  NEG                     ;
  SUB $06                 ;
  JR PATCH_SPRITE_ROWS    ;

; The unrolled row of a byte-aligned sprite
;
; Entered by the JR in SPRITE_ROW, as many 8-byte units from the end as the
; sprite is wide. Each unit takes the next mask and image pair off the stack
; and does one buffer byte: cleared under the mask (CPL, OR E, CPL), the image
; ORed in, stored. The last unit has no INC BC, so a row leaves BC on its last
; byte, which is what the step patched into SPRITE_SHIFTED_RUN allows for.
; Knight Lore's sprite_aligned and sprite_aligned_tail.
;
; BC the buffer byte to start at
; SP the sprite's next mask and image bytes
; A' the rows left
SPRITE_ALIGNED_RUN:
  POP DE                  ; The first of five units
  LD A,(BC)               ;
  CPL                     ;
  OR E                    ;
  CPL                     ;
  OR D                    ;
  LD (BC),A               ;
  INC BC                  ;
  POP DE                  ; Three more the same
  LD A,(BC)               ;
  CPL                     ;
  OR E                    ;
  CPL                     ;
  OR D                    ;
  LD (BC),A               ;
  INC BC                  ;
  POP DE                  ;
  LD A,(BC)               ;
  CPL                     ;
  OR E                    ;
  CPL                     ;
  OR D                    ;
  LD (BC),A               ;
  INC BC                  ;
  POP DE                  ;
  LD A,(BC)               ;
  CPL                     ;
  OR E                    ;
  CPL                     ;
  OR D                    ;
  LD (BC),A               ;
  INC BC                  ;
  POP DE                  ; The fifth, without the INC BC
  LD A,(BC)               ;
  CPL                     ;
  OR E                    ;
  CPL                     ;
  OR D                    ;
  LD (BC),A               ;
  JP SPRITE_NEXT_ROW      ; On to the next row

; Start a row of a sprite
;
; Used by the routines at CALC_PIXEL_XY_AND_RENDER and SPRITE_SHIFTED_RUN.
;
; The row count goes to A', and A takes the first buffer byte: the shifted
; units of SPRITE_SHIFTED_RUN expect the byte they are finishing to be in A
; already. The JR's offset is patched by CALC_PIXEL_XY_AND_RENDER for every
; sprite, into the aligned run at SPRITE_ALIGNED_RUN or the shifted one at
; SPRITE_SHIFTED_RUN; as it stands in the listing, an offset of $FE, it is a JR
; to itself. Knight Lore's sprite_row and sprite_row_jump.
;
; A the rows left
; BC the buffer byte the row starts at
SPRITE_ROW:
  EX AF,AF'               ; The count to A'; the first buffer byte
  LD A,(BC)               ;
SPRITE_ROW_JUMP:
  JR SPRITE_ROW_JUMP      ; Offset patched: into one of the unrolled runs

; The unrolled row of a shifted sprite
;
; Entered by the JR in SPRITE_ROW, as many 16-byte units from the end as the
; sprite is wide. H is the first of the two pages BUILD_LOOKUP_TBLS built for
; this shift. The tables hold complements, so each byte is ANDed with the
; complement of the mask shifted, and XORed with the complement of the image
; shifted and complemented again -- which comes to the buffer byte cleared
; under the shifted mask with the shifted image put in. Page H gives the part
; of a mask or image byte that stays in the current buffer byte, which is
; finished and stored; page H + 1 the part that falls into the next, which is
; begun and left in A for the next unit. The byte the last unit begins is
; stored after the fifth.
;
; Then, for both runs, BC steps up to the next row by the amount patched into
; the ADD below, and the loop goes round until A' runs out. The real stack
; pointer comes back from SAVED_SP, and the RET is the return from
; CALC_PIXEL_XY_AND_RENDER.
;
; A the buffer byte the row starts with
; BC its address
; H the shift's first table page
; SP the sprite's next mask and image bytes
SPRITE_SHIFTED_RUN:
  POP DE                  ; The first unit: the buffer byte cleared under the
  LD L,E                  ; mask and with the image put in, shifted right, and
  AND (HL)                ; stored
  LD L,D                  ;
  XOR (HL)                ;
  CPL                     ;
  LD (BC),A               ;
  INC BC                  ;
  INC H                   ; The bits that fall out, into the next buffer byte,
  LD L,E                  ; left in A
  LD A,(BC)               ;
  AND (HL)                ;
  LD L,D                  ;
  XOR (HL)                ;
  CPL                     ;
  DEC H                   ;
  POP DE                  ; Four more units the same
  LD L,E                  ;
  AND (HL)                ;
  LD L,D                  ;
  XOR (HL)                ;
  CPL                     ;
  LD (BC),A               ;
  INC BC                  ;
  INC H                   ;
  LD L,E                  ;
  LD A,(BC)               ;
  AND (HL)                ;
  LD L,D                  ;
  XOR (HL)                ;
  CPL                     ;
  DEC H                   ;
  POP DE                  ;
  LD L,E                  ;
  AND (HL)                ;
  LD L,D                  ;
  XOR (HL)                ;
  CPL                     ;
  LD (BC),A               ;
  INC BC                  ;
  INC H                   ;
  LD L,E                  ;
  LD A,(BC)               ;
  AND (HL)                ;
  LD L,D                  ;
  XOR (HL)                ;
  CPL                     ;
  DEC H                   ;
  POP DE                  ;
  LD L,E                  ;
  AND (HL)                ;
  LD L,D                  ;
  XOR (HL)                ;
  CPL                     ;
  LD (BC),A               ;
  INC BC                  ;
  INC H                   ;
  LD L,E                  ;
  LD A,(BC)               ;
  AND (HL)                ;
  LD L,D                  ;
  XOR (HL)                ;
  CPL                     ;
  DEC H                   ;
  POP DE                  ;
  LD L,E                  ;
  AND (HL)                ;
  LD L,D                  ;
  XOR (HL)                ;
  CPL                     ;
  LD (BC),A               ;
  INC BC                  ;
  INC H                   ;
  LD L,E                  ;
  LD A,(BC)               ;
  AND (HL)                ;
  LD L,D                  ;
  XOR (HL)                ;
  CPL                     ;
  DEC H                   ;
  LD (BC),A               ; Store the last spilled byte
; This entry point is used by the routine at SPRITE_ALIGNED_RUN.
SPRITE_NEXT_ROW:
  LD A,C                  ; BC up a row: the ADD's operand patched by
  ADD A,$00               ; CALC_PIXEL_XY_AND_RENDER to 33 less the bytes a row
  LD C,A                  ; touches
  LD A,B                  ;
  ADC A,$00               ;
  LD B,A                  ;
  EX AF,AF'               ; The next row, until the height runs out
  DEC A                   ;
  JP NZ,SPRITE_ROW        ;
  LD SP,(SAVED_SP)        ; The real stack pointer back; return from
  RET                     ; CALC_PIXEL_XY_AND_RENDER

; Buffer address of a pixel position
;
; Used by the routines at RUN_CLOCK, PRINT_TEXT_SINGLE_COLOUR, PRINT_TEXT,
; SHOW_CARRIED, BLIT_2X8, RENDER_DYNAMIC_OBJECTS and CALC_PIXEL_XY_AND_RENDER.
;
; The buffer is plain rows of 32 bytes, the bottom line first, so the address
; is y * 32 + x / 8 from its start: BC shifted right three times. HL is kept.
; As Knight Lore's calc_vidbuf_addr.
;
;   C the pixel x
;   B the pixel y, counted up from the bottom of the screen
; O:BC the address in BUFFER
CALC_VIDBUF_ADDR:
  PUSH HL
  SRL B                   ; BC / 8 = y * 32 + x / 8
  RR C                    ;
  SRL B                   ;
  RR C                    ;
  SRL B                   ;
  RR C                    ;
  LD HL,BUFFER            ; Plus the start of the buffer
  ADD HL,BC               ;
  LD C,L                  ;
  LD B,H                  ;
  POP HL
  RET

; Display address of a pixel position
;
; Used by the routines at RUN_CLOCK, SHOW_CARRIED, BLIT_2X8 and
; RENDER_DYNAMIC_OBJECTS.
;
; Turns the game's upward y into the display's line counted from the top by
; complementing it: 255 - y is that line plus 64, one third of the screen too
; many in the top bits, which is taken back by adding 56 rather than 64 to the
; high byte. A' is changed. As Knight Lore's calc_vram_addr.
;
;   C the pixel x
;   B the pixel y, counted up from the bottom of the screen
; O:DE the display address of that byte
CALC_VRAM_ADDR:
  LD A,C                  ; E = x / 8, the column
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  AND $1F                 ;
  LD E,A                  ;
  LD A,B                  ; The line within the character row, from bits 0-2 of
  CPL                     ; 255 - y, kept in A'
  AND $07                 ;
  EX AF,AF'               ;
  LD A,B                  ; Bits 3-5, the character row within the third, into
  CPL                     ; the top of E
  RLCA                    ;
  RLCA                    ;
  AND $E0                 ;
  OR E                    ;
  LD E,A                  ;
  LD A,B                  ; Bits 6-7, the third, with the line within the row,
  CPL                     ; and 56 for the extra third
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  AND $18                 ;
  LD D,A                  ;
  EX AF,AF'               ;
  OR D                    ;
  ADD A,$38               ;
  LD D,A                  ;
  RET

; Attribute address of a pixel position
;
; Used by the routines at SCENE_SPARKS, PRINT_TEXT and SHOW_CARRIED.
;
; HL is kept. As Knight Lore's calc_attrib_addr.
;
;   H the pixel y, counted up from the bottom of the screen
;   L the pixel x
; O:DE the attribute address
CALC_ATTRIB_ADDR:
  PUSH HL                 ; Kept
  LD A,H                  ; H = (255 - y) / 8: the character row counted from
  CPL                     ; the top, plus 8
  LD H,A                  ;
  SRL H                   ;
  SRL H                   ;
  SRL H                   ;
  SRL H                   ; Three more shifts across H and L: row * 32 + x / 8
  RR L                    ;
  SRL H                   ;
  RR L                    ;
  SRL H                   ;
  RR L                    ;
  LD DE,$5700             ; The attribute file less those 8 rows
  ADD HL,DE               ;
  EX DE,HL                ;
  POP HL
  RET

; Turn a sprite's stored data the way its object faces
;
; Used by the routine at FLIP_SPRITE.
;
; Reached by a jump from FLIP_SPRITE, so its RET goes back to FLIP_SPRITE's
; caller. Sprites are turned in place, and the width byte remembers which way
; round the data now is: bit 7 set while it is stored upside down, bit 6 while
; mirrored. Bits 7 and 6 of the object's flags (+7) say how it wants to be
; drawn. Where they disagree the data is turned and the sprite's bit toggled,
; so an object that keeps facing one way costs nothing after the first time,
; while two objects sharing a sprite and facing opposite ways turn it back and
; forth every time each is drawn.
;
; Upside down is done by swapping whole rows end for end; mirroring
; (HFLIP_SPRITE_DATA) by reversing the order of each row's cells and the bits
; of every byte, through MIRROR_TABLE. The row swap halves the height: a sprite
; one row high would make that 0 and the loop run 256 times. The only such
; sprite is graphic 5, the border's sides, which is mirrored but never turned
; upside down (BORDER_DATA). As Knight Lore's vflip_sprite_data and
; hflip_sprite_data.
;
;   DE the sprite's width byte
;   IX the object
; O:DE the sprite's width byte
VFLIP_SPRITE_DATA:
  PUSH DE                 ; Kept
  LD A,(DE)               ; The sprite's bit 7 against the object's: the same
  XOR (IX+$07)            ; means no turning over
  AND $80                 ;
  JR Z,HFLIP_SPRITE_DATA  ;
  LD A,(DE)               ; Toggle the sprite's bit
  XOR $80                 ;
  LD (DE),A               ;
  RLCA                    ; B = bytes a row: the width times two, for the mask
  AND $7E                 ; and image bytes
  LD B,A                  ;
  INC DE                  ; C = the height in rows; DE on the data
  LD A,(DE)               ;
  LD C,A                  ;
  INC DE                  ;
  PUSH DE                 ; HL = B * C, the data's length, plus the start: one
  LD E,B                  ; past the end
  LD D,$00                ;
  CALL HL_EQUALS_DE_X_A   ;
  POP DE                  ;
  ADD HL,DE               ;
  EX DE,HL                ;
  LD A,B                  ; DE one past the end; HL one past the first row
  CALL ADD_HL_A           ;
  DEC DE                  ; DE on the last byte of the last row, HL on the last
  DEC HL                  ; byte of the first
  SRL C                   ; Swap rows in pairs: half the height
VFLIP_ROW_PAIR:
  PUSH BC                 ; Kept
VFLIP_SPRITE_LINE_PAIR:
  LD A,(DE)                   ; Swap the two rows byte by byte, working
  LD C,(HL)                   ; backwards
  LD (HL),A                   ;
  LD A,C                      ;
  LD (DE),A                   ;
  DEC HL                      ;
  DEC DE                      ;
  DJNZ VFLIP_SPRITE_LINE_PAIR ;
  POP BC                  ; HL on to the end of the next row down; DE is
  LD A,B                  ; already at the end of the row before its last
  SLA A                   ;
  CALL ADD_HL_A           ;
  DEC C                   ; The next pair
  JR NZ,VFLIP_ROW_PAIR    ;
HFLIP_SPRITE_DATA:
  POP DE                  ; The sprite's bit 6 against the object's
  PUSH DE                 ;
  LD A,(DE)               ;
  XOR (IX+$07)            ;
  AND $40                 ;
  JR Z,FLIP_DONE          ;
  LD A,(DE)               ; Toggle the sprite's bit; B and C = the width in
  XOR $40                 ; cells
  LD (DE),A               ;
  AND $0F                 ;
  LD B,A                  ;
  LD C,A                  ;
  INC DE                  ; The height into A'
  LD A,(DE)               ;
  EX AF,AF'               ;
  INC DE                  ; HL' reads and HL writes, both from the first row;
  EX DE,HL                ; B' = the page of the bit reversal table
  PUSH HL                 ;
  EXX                     ;
  POP HL                  ;
  LD B,$F1                ;
  EXX                     ;
HFLIP_READ_ROW:
  EXX                     ; Push a row's pairs, each byte reversed: E' the
  LD C,(HL)               ; mask, D' the image
  LD A,(BC)               ;
  LD E,A                  ;
  INC HL                  ;
  LD C,(HL)               ;
  LD A,(BC)               ;
  LD D,A                  ;
  INC HL                  ;
  PUSH DE                 ;
  EXX                     ;
  DJNZ HFLIP_READ_ROW     ;
  LD B,C                  ; The width again, for the writing
HFLIP_WRITE_ROW:
  POP DE                  ; Pop them back over the row: last first, so the
  LD (HL),E               ; cells come back in the reverse order
  INC HL                  ;
  LD (HL),D               ;
  INC HL                  ;
  DJNZ HFLIP_WRITE_ROW    ;
  EX AF,AF'               ; The next row, until the height runs out
  DEC A                   ;
  JR Z,FLIP_DONE          ;
  EX AF,AF'               ;
  LD B,C                  ;
  JR HFLIP_READ_ROW       ;
FLIP_DONE:
  POP DE                  ; DE = the sprite
  RET                     ;

; Unused: Knight Lore's copyright line
;
; "COPYRIGHT 1984 A.C.G." -- the same 21 characters Knight Lore has in the same
; place, just after its last routine (flip_done) and before its screen buffer,
; carried over with the engine: Alien 8 is from 1985, and its menu prints its
; own notice from its text list. Nothing refers to it (the loaded block
; searched for its address), and the game never reads or writes it (measured,
; as for BUFFER).
OLD_COPYRIGHT:
  DEFM "COPYRIGHT 1984 A.C.G."

; The screen buffer
;
; 6144 bytes, a byte for each eight pixels of the play area, 32 to a line, the
; bottom line first: the room is drawn here (CALC_PIXEL_XY_AND_RENDER) and
; copied to the screen, all of it on the first turn in a room (SHOW_BUFFER) and
; only what changed after that (RENDER_DYNAMIC_OBJECTS). CALC_VIDBUF_ADDR finds
; a place in it. The buffer is cleared (CLEAR_SCRN_BUFFER) before anything is
; drawn in it.
;
; What the tape loads here is not the game's: the block runs on to the top of
; memory, and the machine it was saved from had these bytes in it. Every one is
; overwritten before it is read (measured: the loaded game run in the simulator
; from ENTRY into its first room, noting the first access to each address).
; They are, in order: zeros; stack debris -- words that look like addresses in
; the ROM and the display; the Spectrum ROM's capital letters A to U; the first
; 1464 bytes of the Interface 1's ROM; and zeros.
;
; The Interface 1 code starts 328 bytes in. Disassembled as if at address 0 it
; is that ROM's restart table: RST 0 at offset 0 (POP HL, then LD (IY+124),0 --
; the Interface 1's FLAGS3 -- and JP $0700), RST 8 at 8, RST 16 at 16 (which
; stores HL into its SBRT routine among the system variables), EI and RET at
; $38, RETN at $66; and read from address 0 its absolute jumps and calls into
; itself land on the starts of its instructions, which they do not when it is
; read from 1 or 2. The system variables it uses beyond the Spectrum's own
; exist only with an Interface 1 attached, and the error reports at offset
; $02B8 are the Interface 1's own, each between two numbers counting from 0 to
; 24. The ROM itself was not compared byte for byte.
BUFFER:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; Zeros
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $F3,$0D,$CE,$0B,$E2,$50,$CE,$0B ; Stack debris: words that look like ROM
  DEFB $E3,$50,$1E,$17,$DC,$0A,$CE,$0B ; and display addresses
  DEFB $E4,$50,$1D,$17,$12,$16,$FF,$FF ;
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$DB,$02 ;
  DEFB $4D,$00,$1A,$55,$E6,$00,$DB,$02 ;
  DEFB $4D,$00,$F4,$00,$21,$18,$C0,$57 ;
  DEFB $71,$0E,$F3,$0D,$21,$17,$C6,$1E ;
  DEFB $A7,$61,$76,$1B,$03,$13,$00,$3E ;
  DEFB $00,$3C,$42,$42,$7E,$42,$42,$00 ; The Spectrum ROM's letters A to U,
  DEFB $00,$7C,$42,$7C,$42,$42,$7C,$00 ; eight bytes each
  DEFB $00,$3C,$42,$40,$40,$42,$3C,$00 ;
  DEFB $00,$78,$44,$42,$42,$44,$78,$00 ;
  DEFB $00,$7E,$40,$7C,$40,$40,$7E,$00 ;
  DEFB $00,$7E,$40,$7C,$40,$40,$40,$00 ;
  DEFB $00,$3C,$42,$40,$4E,$42,$3C,$00 ;
  DEFB $00,$42,$42,$7E,$42,$42,$42,$00 ;
  DEFB $00,$3E,$08,$08,$08,$08,$3E,$00 ;
  DEFB $00,$02,$02,$02,$42,$42,$3C,$00 ;
  DEFB $00,$44,$48,$70,$48,$44,$42,$00 ;
  DEFB $00,$40,$40,$40,$40,$40,$7E,$00 ;
  DEFB $00,$42,$66,$5A,$42,$42,$42,$00 ;
  DEFB $00,$42,$62,$52,$4A,$46,$42,$00 ;
  DEFB $00,$3C,$42,$42,$42,$42,$3C,$00 ;
  DEFB $00,$7C,$42,$42,$7C,$40,$40,$00 ;
  DEFB $00,$3C,$42,$42,$52,$4A,$3C,$00 ;
  DEFB $00,$7C,$42,$42,$7C,$44,$42,$00 ;
  DEFB $00,$3C,$40,$3C,$02,$42,$3C,$00 ;
  DEFB $00,$FE,$10,$10,$10,$10,$10,$00 ;
  DEFB $00,$42,$42,$42,$42,$42,$3C,$00 ;
  DEFB $E1,$FD,$36,$7C,$00,$C3,$00,$07 ; The Interface 1's ROM from its first
  DEFB $2A,$5D,$5C,$E1,$E5,$C3,$9A,$00 ; byte: the restart table and the code
  DEFB $22,$BA,$5C,$E1,$D5,$18,$6A,$FF ; after it; the last byte is the number
  DEFB $FD,$CB,$01,$7E,$C9,$FF,$FF,$FF ; 0 that comes before the first report
  DEFB $DF,$28,$45,$18,$15,$FF,$FF,$FF ;
  DEFB $FD,$CB,$02,$9E,$18,$12,$FF,$FF ;
  DEFB $C3,$F7,$01,$FF,$FF,$FF,$FF,$FF ;
  DEFB $FB,$C9,$CD,$77,$00,$C3,$58,$02 ;
  DEFB $DF,$28,$25,$CD,$77,$00,$CD,$B9 ;
  DEFB $17,$FD,$CB,$7C,$4E,$28,$19,$FD ;
  DEFB $CB,$7C,$66,$28,$13,$FD,$7E,$00 ;
  DEFB $FE,$14,$20,$0C,$21,$00,$00,$E5 ;
  DEFB $C7,$FF,$FF,$FF,$FF,$FF,$ED,$45 ;
  DEFB $2A,$5D,$5C,$22,$5F,$5C,$ED,$7B ;
  DEFB $3D,$5C,$21,$C5,$16,$E5,$C7,$FD ;
  DEFB $CB,$7C,$56,$C8,$ED,$7B,$3D,$5C ;
  DEFB $C7,$5E,$23,$56,$ED,$53,$BD,$5C ;
  DEFB $23,$E3,$EB,$21,$00,$00,$E5,$21 ;
  DEFB $08,$00,$E5,$21,$B9,$5C,$E5,$C3 ;
  DEFB $00,$07,$F5,$7C,$B5,$20,$06,$F1 ;
  DEFB $E1,$2A,$BA,$5C,$C9,$D5,$11,$FE ;
  DEFB $15,$ED,$52,$D1,$20,$0E,$F1,$21 ;
  DEFB $00,$07,$E5,$21,$04,$00,$19,$5E ;
  DEFB $23,$56,$EB,$E9,$F7,$3E,$01,$D3 ;
  DEFB $F7,$3E,$EE,$D3,$EF,$F1,$E1,$F5 ;
  DEFB $D7,$7B,$00,$32,$3A,$5C,$FE,$FF ;
  DEFB $20,$17,$FD,$CB,$7C,$4E,$28,$0F ;
  DEFB $FD,$CB,$0C,$7E,$28,$09,$2A,$59 ;
  DEFB $5C,$7E,$FE,$F7,$CA,$95,$0A,$E7 ;
  DEFB $FF,$D6,$1B,$D2,$81,$19,$FE,$F0 ;
  DEFB $28,$09,$FE,$F3,$28,$05,$FE,$FC ;
  DEFB $C2,$28,$00,$2A,$5D,$5C,$22,$CB ;
  DEFB $5C,$F1,$FD,$CB,$37,$6E,$C2,$28 ;
  DEFB $00,$FD,$CB,$7C,$46,$C2,$28,$00 ;
  DEFB $FD,$CB,$7C,$C6,$DF,$20,$04,$FD ;
  DEFB $36,$0C,$FF,$FD,$46,$0D,$0E,$00 ;
  DEFB $FD,$CB,$0C,$7E,$28,$0A,$C5,$D7 ;
  DEFB $FB,$19,$C1,$D7,$18,$00,$18,$3F ;
  DEFB $2A,$53,$5C,$3A,$46,$5C,$BE,$30 ;
  DEFB $02,$E7,$00,$23,$20,$06,$3A,$45 ;
  DEFB $5C,$BE,$38,$F5,$23,$5E,$23,$56 ;
  DEFB $23,$28,$24,$19,$18,$E5,$11,$06 ;
  DEFB $00,$19,$7E,$FE,$0E,$28,$F7,$23 ;
  DEFB $FE,$22,$20,$01,$0D,$FE,$3A,$28 ;
  DEFB $04,$FE,$CB,$20,$04,$CB,$41,$28 ;
  DEFB $06,$FE,$0D,$20,$E5,$18,$CA,$10 ;
  DEFB $E1,$2B,$22,$5D,$5C,$DF,$20,$32 ;
  DEFB $FD,$CB,$0C,$7E,$CA,$F0,$01,$2B ;
  DEFB $0E,$00,$23,$7E,$FE,$0E,$20,$1D ;
  DEFB $C5,$01,$06,$00,$D7,$E8,$19,$E5 ;
  DEFB $ED,$5B,$CB,$5C,$A7,$ED,$52,$30 ;
  DEFB $0A,$EB,$01,$06,$00,$A7,$ED,$42 ;
  DEFB $22,$CB,$5C,$E1,$C1,$7E,$FE,$0D ;
  DEFB $20,$D8,$D7,$BF,$16,$CD,$4D,$02 ;
  DEFB $D7,$20,$00,$D6,$CE,$FE,$01,$CA ;
  DEFB $86,$04,$FE,$02,$CA,$B4,$04,$FE ;
  DEFB $03,$CA,$3D,$05,$FE,$04,$CA,$31 ;
  DEFB $05,$FE,$05,$CA,$ED,$04,$FE,$2A ;
  DEFB $CA,$2F,$08,$FE,$21,$CA,$94,$08 ;
  DEFB $FE,$08,$CA,$9E,$08,$FE,$07,$CA ;
  DEFB $A8,$08,$FE,$2D,$CA,$59,$05,$FE ;
  DEFB $2F,$CA,$7F,$05,$2A,$B7,$5C,$E9 ;
  DEFB $2A,$CB,$5C,$22,$5D,$5C,$EF,$2A ;
  DEFB $4F,$5C,$11,$49,$A3,$19,$38,$35 ;
  DEFB $21,$24,$02,$E5,$2A,$63,$5C,$22 ;
  DEFB $65,$5C,$21,$92,$5C,$22,$68,$5C ;
  DEFB $21,$B5,$5C,$01,$3A,$00,$11,$00 ;
  DEFB $00,$D5,$1E,$08,$D5,$11,$55,$16 ;
  DEFB $D5,$C3,$00,$07,$21,$3A,$02,$01 ;
  DEFB $13,$00,$11,$B6,$5C,$ED,$B0,$3E ;
  DEFB $01,$32,$EF,$5C,$C9,$FD,$CB,$7C ;
  DEFB $8E,$C9,$02,$F0,$01,$21,$00,$00 ;
  DEFB $CD,$00,$00,$22,$BA,$5C,$C9,$0C ;
  DEFB $00,$01,$00,$00,$00,$21,$CD,$5C ;
  DEFB $06,$22,$36,$FF,$23,$10,$FB,$C9 ;
  DEFB $FD,$36,$7C,$00,$FB,$76,$CD,$B9 ;
  DEFB $17,$FD,$CB,$01,$AE,$FD,$CB,$30 ;
  DEFB $4E,$28,$03,$D7,$CD,$0E,$E1,$7E ;
  DEFB $FD,$77,$00,$3C,$F5,$21,$00,$00 ;
  DEFB $FD,$74,$37,$FD,$74,$26,$22,$0B ;
  DEFB $5C,$2C,$22,$16,$5C,$D7,$B0,$16 ;
  DEFB $FD,$CB,$37,$AE,$D7,$6E,$0D,$FD ;
  DEFB $CB,$02,$EE,$FD,$CB,$02,$9E,$F1 ;
  DEFB $21,$B7,$02,$06,$04,$ED,$B1,$7E ;
  DEFB $FE,$20,$38,$08,$E5,$D7,$10,$00 ;
  DEFB $E1,$23,$18,$F3,$ED,$7B,$3D,$5C ;
  DEFB $33,$33,$21,$49,$13,$E5,$C7,$00 ;
  DEFM "Program finished",$01,"Nonsens"       ; The Interface 1's error
  DEFM "e in BASIC",$02,"Invalid strea"       ; reports, each followed by its
  DEFM "m number",$03,"Invalid device "       ; number
  DEFM "expression",$04,"Invalid name",$05    ;
  DEFM "Invalid drive number",$06,"Inv"       ;
  DEFM "alid station number",$07,"Miss"       ;
  DEFM "ing name",$08,"Missing station"       ;
  DEFM " number",$09,"Missing drive nu"       ;
  DEFM "mber",$0A,"Missing baud rate",$0B,"H" ;
  DEFM "eader mismatch error",$0C,"Str"       ;
  DEFM "eam already open",$0D,"Writing"       ;
  DEFM " to a 'read' file",$0E,"Readin"       ;
  DEFM "g a 'write' file",$0F,"Drive '"       ;
  DEFM "write' protected",$10,"Microdr"       ;
  DEFM "ive full",$11,"Microdrive not "       ;
  DEFM "present",$12,"File not found",$13,"H" ;
  DEFM "ook code error",$14,"CODE erro"       ;
  DEFM "r",$15,"MERGE error",$16,"Verificati" ;
  DEFM "on has failed",$17,"Wrong file"       ;
  DEFM " type"                                ;
  DEFB $18,$21,$D8,$5C,$36,$02,$D7,$20 ; The ROM continued, from the number
  DEFB $00,$FE,$0D,$28,$02,$FE,$3A,$CA ; after the last report to offset $05B7
  DEFB $83,$06,$FE,$23,$20,$0B,$CD,$4E ;
  DEFB $06,$CD,$B1,$05,$20,$0F,$D7,$20 ;
  DEFB $00,$CD,$1E,$06,$CD,$B7,$05,$CD ;
  DEFB $6D,$06,$C3,$70,$1E,$E7,$00,$CD ;
  DEFB $F2,$05,$CD,$B1,$05,$20,$03,$CD ;
  DEFB $2F,$06,$CD,$B7,$05,$3A,$D9,$5C ;
  DEFB $FE,$54,$28,$04,$FE,$42,$20,$06 ;
  DEFB $CD,$B0,$06,$C3,$C9,$0A,$FE,$4E ;
  DEFB $20,$10,$CD,$8F,$06,$3A,$D6,$5C ;
  DEFB $A7,$CA,$9F,$06,$32,$C5,$5C,$C3 ;
  DEFB $C1,$05,$CD,$85,$06,$C3,$75,$1E ;
  DEFB $CD,$4E,$06,$CD,$B1,$05,$20,$BD ;
  DEFB $CD,$F2,$05,$CD,$B1,$05,$20,$03 ;
  DEFB $CD,$2F,$06,$CD,$B7,$05,$3A,$D8 ;
  DEFB $5C,$D7,$27,$17,$21,$11,$00,$A7 ;
  DEFB $ED,$42,$38,$1E,$3A,$D9,$5C,$FE ;
  DEFB $54,$28,$04,$FE,$42,$20,$03,$C3 ;
  DEFB $47,$0B,$FE,$4E,$20,$06,$CD,$8F ;
  DEFB $06,$C3,$A3,$0E,$CD,$85,$06,$C3 ;
  DEFB $7A,$1E,$E7,$0B,$CD,$A3,$06,$CD ;
  DEFB $B7,$05,$CD,$85,$06,$C3,$66,$1E ;
  DEFB $CD,$B9,$06,$CD,$9F,$05,$D7,$18 ;
  DEFB $00,$FE,$CC,$20,$3A,$CD,$B9,$06 ;
  DEFB $CD,$9F,$05,$D7,$18,$00,$CD,$B7 ;
  DEFB $05,$C3,$6B,$1E,$D7,$20,$00,$FE ;
  DEFB $23,$20,$24,$D7,$20,$00,$CD,$B7 ;
  DEFB $05,$21,$38,$00,$22,$8D,$5C,$22 ;
  DEFB $8F,$5C,$FD,$75,$0E,$FD,$74,$57 ;
  DEFB $3E,$07,$D3,$FE,$D7,$6B,$0D,$C3 ;
  DEFB $C1,$05,$D7,$20,$00,$FE,$23,$C2 ;
  DEFB $B2,$04,$D7,$20,$00,$CD,$B7,$05 ;
  DEFB $AF,$F5,$FD,$CB,$7C,$CE,$CD,$18 ;
  DEFB $17,$F1,$3C,$FE,$10,$38,$F2,$C3 ;
  DEFB $C1,$05,$21,$D6,$5C,$11,$DE,$5C ;
  DEFB $06,$08,$1A,$4E,$77,$79,$12,$23 ;
  DEFB $13,$10,$F7,$C9,$FE,$2C,$C8,$FE ;
  DEFB $3B,$C9,$FE                     ;
  DEFB $0D,$00,$00,$00,$00,$00,$00,$00 ; A byte of $0D, then zeros
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;

; The stack
;
; From here up to MIRROR_TABLE, where ENTRY puts the stack pointer; the main
; loop puts it back there before every object's update routine (AFTER_GAME), so
; nothing is left on the stack from one object to the next. The deepest use is
; RENDER_DYNAMIC_OBJECTS, which keeps three words for every area it wipes until
; they are copied to the screen. Zeros on the tape.
STACK_SPACE:
  DEFS $0700

; Lookup tables
;
; Built by BUILD_LOOKUP_TBLS at the start of every game, before the menu: here
; every byte value with its bits reversed, for mirroring sprites
; (VFLIP_SPRITE_DATA); and on the fourteen pages above it, in pairs, every byte
; value shifted right one to seven places and the bits that fall out of it,
; complemented, for drawing a sprite at any pixel (SPRITE_SHIFTED_RUN).
;
; What the tape loads here is zeros, stack debris like the buffer's, and a font
; of capital letters A to U of some other program -- none of it the game's, all
; overwritten before it is read (measured, as for BUFFER).
MIRROR_TABLE:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; Zeros on the tape
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $F3,$0D,$CE,$0B,$E3,$50,$CE,$0B ; Stack debris
  DEFB $E4,$50,$1D,$17,$DC,$0A,$CE,$0B ;
  DEFB $E7,$50,$1A,$17,$DC,$0A,$D7,$18 ;
  DEFB $38,$00,$38,$00,$0D,$19,$DB,$02 ;
  DEFB $DB,$02,$4D,$00,$EF,$56,$11,$00 ;
  DEFB $EE,$56,$0C,$02,$5C,$0E,$C0,$57 ;
  DEFB $71,$0E,$F3,$0D,$21,$17,$C6,$1E ;
  DEFB $FC,$62,$76,$1B,$03,$13,$00,$3E ;
  DEFB $18,$3C,$66,$66,$7E,$66,$66,$00 ; A font's letters A to U
  DEFB $FC,$66,$66,$7C,$66,$66,$FC,$00 ;
  DEFB $3C,$66,$C0,$C0,$C0,$66,$3C,$00 ;
  DEFB $F8,$6C,$66,$66,$66,$6C,$F8,$00 ;
  DEFB $FE,$62,$68,$78,$68,$62,$FE,$00 ;
  DEFB $FE,$62,$68,$78,$68,$60,$F0,$00 ;
  DEFB $3C,$66,$C0,$C0,$CE,$66,$3E,$00 ;
  DEFB $66,$66,$66,$7E,$66,$66,$66,$00 ;
  DEFB $7E,$18,$18,$18,$18,$18,$7E,$00 ;
  DEFB $1E,$0C,$0C,$0C,$CC,$CC,$78,$00 ;
  DEFB $E6,$66,$6C,$78,$6C,$66,$E6,$00 ;
  DEFB $F0,$60,$60,$60,$62,$66,$FE,$00 ;
  DEFB $C6,$EE,$FE,$FE,$D6,$C6,$C6,$00 ;
  DEFB $C6,$E6,$F6,$DE,$CE,$C6,$C6,$00 ;
  DEFB $38,$6C,$C6,$C6,$C6,$6C,$38,$00 ;
  DEFB $FC,$66,$66,$7C,$60,$60,$F0,$00 ;
  DEFB $38,$6C,$C6,$C6,$DA,$CC,$76,$00 ;
  DEFB $FC,$66,$66,$7C,$6C,$66,$E6,$00 ;
  DEFB $3C,$66,$60,$3C,$06,$66,$3C,$00 ;
  DEFB $7E,$5A,$18,$18,$18,$18,$3C,$00 ;
  DEFB $66,$66,$66,$66,$66,$66,$3C,$00 ;

