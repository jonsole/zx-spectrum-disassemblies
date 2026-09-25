    DEVICE ZXSPECTRUM48
LOC_LONELANDS EQU $04
LOC_TROLLS_CAVE EQU $07
LOC_NARROW_PLACE EQU $0B
LOC_BEORNS_HOUSE EQU $16
LOC_GOBLINS_DUNGEON EQU $0D
LOC_DARK_STUFFY_PASSAGE_65 EQU $41
LOC_SMOTHERING_FOREST EQU $1B
LOC_LEVELLED_ELVISH_CLEARING EQU $1C
LOC_DARK_DUNGEON EQU $1F
LOC_LONG_LAKE EQU $22
LOC_DALE_VALLEY EQU $26
LOC_SIDEDOOR EQU $2A
LOC_SMOOTH_STRAIGHT_PASSAGE EQU $2B
LOC_LOWER_HALLS EQU $29
  ORG $6000

; Dictionary: index by initial letter
;
; One 2-byte offset per letter, relative to the start of this table, to the
; first word beginning with it. Entry 0 is unused; entries 27-31 are padding.
WORD_INDEX:
  DEFB $00,$00            ; Entry 0: unused
  DEFB $40,$00            ; A: +64, first word A
  DEFB $7C,$00            ; B: +124, first word BACK
  DEFB $E2,$00            ; C: +226, first word CACHE
  DEFB $7C,$01            ; D: +380, first word D
  DEFB $F6,$01            ; E: +502, first word E
  DEFB $4F,$02            ; F: +591, first word FALL
  DEFB $BD,$02            ; G: +701, first word GANDALF
  DEFB $09,$03            ; H: +777, first word HALL
  DEFB $73,$03            ; I: +883, first word I
  DEFB $A1,$03            ; J: +929, first word JUMP
  DEFB $A5,$03            ; K: +933, first word KEY
  DEFB $B2,$03            ; L: +946, first word L
  DEFB $24,$04            ; M: +1060, first word MAGIC
  DEFB $5F,$04            ; N: +1119, first word N
  DEFB $9C,$04            ; O: +1180, first word OF
  DEFB $CD,$04            ; P: +1229, first word PASSAGE
  DEFB $0C,$05            ; Q: +1292, first word QUICKLY
  DEFB $21,$05            ; R: +1313, first word RAVENHILL
  DEFB $77,$05            ; S: +1399, first word S
  DEFB $8C,$06            ; T: +1676, first word TAKE
  DEFB $0D,$07            ; U: +1805, first word U
  DEFB $28,$07            ; V: +1832, first word VALIANT
  DEFB $51,$07            ; W: +1873, first word W
  DEFB $00,$00            ; X: no words
  DEFB $A8,$07            ; Y: +1960, first word YOU
  DEFB $00,$00            ; Z: no words
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; Entries 27-31: padding, all zero
  DEFB $00,$00                         ;

; Dictionary: the words
;
; One 5-bit letter code per byte (A=1..Z=26, 0 for none). Bits 5-6 of the first
; two bytes together are the word's class, the top nibble of its token, and bit
; 7 of the second byte marks a word that can take an -s, so bit 7 is not a
; terminator there; from the third byte on, bit 7 marks the last letter. A
; terminator with bit 6 set is followed by a 2-byte offset, from the start of
; the index table, to the entry this word is a synonym of.
WORD_LIST:
  DEFB $41,$00,$80        ; A (article or the like)
  DEFB $21,$63,$12,$0F,$13,$93 ; ACROSS (preposition)
  DEFB $21,$66,$14,$05,$92 ; AFTER (preposition)
  DEFB $41,$2C,$8C        ; ALL (quantifier, pronoun or game command)
  DEFB $41,$0C,$12,$05,$01,$04,$99 ; ALREADY (article or the like)
  DEFB $41,$0E,$80        ; AN (article or the like)
  DEFB $41,$4E,$84        ; AND (and)
  DEFB $41,$0E,$0F,$14,$08,$05,$92 ; ANOTHER (article or the like)
  DEFB $41,$12,$85        ; ARE (article or the like)
  DEFB $21,$32,$8D        ; ARM (noun)
  DEFB $21,$32,$12,$0F,$97 ; ARROW (noun)
  DEFB $21,$74,$80        ; AT (preposition)
  DEFB $01,$F4,$14,$01,$03,$8B ; ATTACK (verb)
  DEFB $21,$38,$85        ; AXE (noun)
  DEFB $22,$41,$03,$8B    ; BACK (adjective)
  DEFB $22,$21,$12,$84    ; BARD (noun)
  DEFB $22,$21,$12,$12,$05,$8C ; BARREL (noun)
  DEFB $22,$41,$12,$12,$05,$8E ; BARREN (adjective)
  DEFB $22,$21,$99        ; BAY (noun)
  DEFB $22,$45,$0F,$12,$0E,$93 ; BEORNS (adjective)
  DEFB $22,$45,$17,$09,$14,$03,$08,$05 ; BEWITCHED (adjective)
  DEFB $84                             ;
  DEFB $22,$49,$87        ; BIG (adjective)
  DEFB $22,$4C,$01,$03,$8B ; BLACK (adjective)
  DEFB $22,$4C,$05,$01,$8B ; BLEAK (adjective)
  DEFB $22,$2C,$0F,$97    ; BLOW (noun)
  DEFB $22,$2C,$0F,$0F,$84 ; BLOOD (noun)
  DEFB $22,$2F,$01,$94    ; BOAT (noun)
  DEFB $22,$2F,$87        ; BOG (noun)
  DEFB $22,$2F,$04,$99    ; BODY (noun)
  DEFB $22,$2F,$97        ; BOW (noun)
  DEFB $02,$F2,$05,$01,$CB,$58,$06 ; BREAK (verb, synonym of STRIKE)
  DEFB $22,$52,$0F,$0B,$05,$8E ; BROKEN (adjective)
  DEFB $02,$F5,$12,$8E    ; BURN (verb)
  DEFB $42,$35,$D4,$45,$02 ; BUT (quantifier, pronoun or game command, synonym
                           ; of EXCEPT)
  DEFB $22,$35,$14,$0C,$05,$92 ; BUTLER (noun)
  DEFB $23,$21,$03,$08,$85 ; CACHE (noun)
  DEFB $23,$21,$0D,$90    ; CAMP (noun)
  DEFB $43,$01,$8E        ; CAN (article or the like)
  DEFB $43,$01,$0E,$0E,$0F,$94 ; CANNOT (article or the like)
  DEFB $03,$E1,$10,$14,$15,$12,$C5,$73 ; CAPTURE (verb, synonym of ATTACK)
  DEFB $00                             ;
  DEFB $03,$01,$12,$05,$06,$15,$0C,$0C ; CAREFULLY (adverb)
  DEFB $99                             ;
  DEFB $23,$21,$12,$12,$0F,$03,$8B ; CARROCK (noun)
  DEFB $03,$E1,$72,$12,$99 ; CARRY (verb)
  DEFB $23,$21,$16,$85    ; CAVE (noun)
  DEFB $23,$21,$16,$05,$12,$8E ; CAVERN (noun)
  DEFB $23,$25,$0C,$0C,$01,$92 ; CELLAR (noun)
  DEFB $23,$28,$05,$13,$94 ; CHEST (noun)
  DEFB $23,$2C,$05,$01,$12,$09,$0E,$87 ; CLEARING (noun)
  DEFB $03,$EC,$09,$0D,$82 ; CLIMB (verb)
  DEFB $03,$EC,$0F,$13,$85 ; CLOSE (verb)
  DEFB $23,$4C,$0F,$13,$05,$84 ; CLOSED (adjective)
  DEFB $23,$4F,$0D,$06,$0F,$12,$14,$01 ; COMFORTABLE (adjective)
  DEFB $02,$0C,$85                     ;
  DEFB $23,$2F,$15,$0E,$14,$12,$99 ; COUNTRY (noun)
  DEFB $23,$32,$01,$03,$8B ; CRACK (noun)
  DEFB $03,$F2,$2F,$13,$93 ; CROSS (verb)
  DEFB $23,$35,$10,$02,$0F,$01,$12,$84 ; CUPBOARD (noun)
  DEFB $23,$55,$12,$09,$0F,$15,$93 ; CURIOUS (adjective)
  DEFB $23,$35,$12,$14,$01,$09,$8E ; CURTAIN (noun)
  DEFB $23,$55,$0E,$0E,$09,$0E,$87 ; CUNNING (adjective)
  DEFB $03,$F5,$14,$80    ; CUT (verb)
  DEFB $04,$40,$C0,$C4,$01 ; D (direction, synonym of DOWN)
  DEFB $24,$21,$0C,$85    ; DALE (noun)
  DEFB $24,$41,$0E,$07,$05,$12,$0F,$15 ; DANGEROUS (adjective)
  DEFB $93                             ;
  DEFB $24,$41,$12,$8B    ; DARK (adjective)
  DEFB $24,$45,$01,$84    ; DEAD (adjective)
  DEFB $24,$45,$05,$90    ; DEEP (adjective)
  DEFB $24,$45,$0E,$13,$85 ; DENSE (adjective)
  DEFB $24,$25,$13,$0F,$0C,$01,$14,$09 ; DESOLATION (noun)
  DEFB $0F,$8E                         ;
  DEFB $04,$E9,$07,$80    ; DIG (verb)
  DEFB $44,$09,$12,$05,$03,$14,$09,$0F ; DIRECTION (article or the like)
  DEFB $8E                             ;
  DEFB $24,$49,$13,$07,$15,$13,$14,$09 ; DISGUSTING (adjective)
  DEFB $0E,$87                         ;
  DEFB $24,$2F,$0F,$92    ; DOOR (noun)
  DEFB $04,$4F,$17,$8E    ; DOWN (direction)
  DEFB $24,$32,$01,$07,$0F,$8E ; DRAGON (noun)
  DEFB $24,$52,$01,$07,$0F,$0E,$93 ; DRAGONS (adjective)
  DEFB $24,$52,$05,$01,$04,$06,$15,$8C ; DREADFUL (adjective)
  DEFB $24,$52,$05,$01,$12,$99 ; DREARY (adjective)
  DEFB $04,$F2,$09,$0E,$8B ; DRINK (verb)
  DEFB $04,$F2,$0F,$90    ; DROP (verb)
  DEFB $24,$52,$99        ; DRY (adjective)
  DEFB $24,$35,$0E,$07,$05,$0F,$8E ; DUNGEON (noun)
  DEFB $05,$40,$C0,$FE,$01 ; E (direction, synonym of EAST)
  DEFB $25,$21,$92        ; EAR (noun)
  DEFB $05,$41,$13,$94    ; EAST (direction)
  DEFB $05,$E1,$14,$80    ; EAT (verb)
  DEFB $25,$44,$07,$85    ; EDGE (adjective)
  DEFB $25,$2C,$86        ; ELF (noun)
  DEFB $25,$2C,$12,$0F,$0E,$84 ; ELROND (noun)
  DEFB $25,$4C,$16,$05,$0E,$0B,$09,$0E ; ELVENKINGS (adjective)
  DEFB $07,$93                         ;
  DEFB $25,$2C,$16,$05,$93 ; ELVES (noun)
  DEFB $25,$4C,$16,$09,$13,$88 ; ELVISH (adjective)
  DEFB $05,$ED,$50,$14,$99 ; EMPTY (verb)
  DEFB $05,$EE,$14,$05,$92 ; ENTER (verb)
  DEFB $45,$36,$05,$12,$19,$14,$08,$09 ; EVERYTHING (quantifier, pronoun or
  DEFB $0E,$C7,$4E,$00                 ; game command, synonym of ALL)
  DEFB $05,$F8,$01,$0D,$09,$0E,$85 ; EXAMINE (verb)
  DEFB $45,$38,$03,$05,$10,$94 ; EXCEPT (quantifier, pronoun or game command)
  DEFB $25,$39,$05,$93    ; EYES (noun)
  DEFB $06,$E1,$0C,$8C    ; FALL (verb)
  DEFB $26,$41,$13,$94    ; FAST (adjective)
  DEFB $06,$05,$05,$02,$0C,$99 ; FEEBLY (adverb)
  DEFB $26,$25,$05,$94    ; FEET (noun)
  DEFB $06,$E9,$0C,$8C    ; FILL (verb)
  DEFB $26,$29,$0E,$07,$05,$92 ; FINGER (noun)
  DEFB $26,$29,$13,$94    ; FIST (noun)
  DEFB $26,$2C,$01,$0D,$05,$93 ; FLAMES (noun)
  DEFB $26,$4C,$01,$94    ; FLAT (adjective)
  DEFB $26,$2C,$0F,$0F,$92 ; FLOOR (noun)
  DEFB $26,$4C,$0F,$17,$09,$0E,$87 ; FLOWING (adjective)
  DEFB $06,$EF,$0C,$0C,$0F,$97 ; FOLLOW (verb)
  DEFB $26,$2F,$0F,$84    ; FOOD (noun)
  DEFB $26,$6F,$92        ; FOR (preposition)
  DEFB $06,$0F,$12,$03,$05,$06,$15,$0C ; FORCEFULLY (adverb)
  DEFB $0C,$99                         ;
  DEFB $26,$2F,$12,$84    ; FORD (noun)
  DEFB $26,$2F,$12,$05,$13,$94 ; FOREST (noun)
  DEFB $26,$2F,$12,$05,$13,$14,$12,$09 ; FORESTRIVER (noun)
  DEFB $16,$05,$92                     ;
  DEFB $26,$4F,$15,$8C    ; FOUL (adjective)
  DEFB $26,$72,$0F,$8D    ; FROM (preposition)
  DEFB $26,$55,$0C,$8C    ; FULL (adjective)
  DEFB $27,$21,$0E,$04,$01,$0C,$86 ; GANDALF (noun)
  DEFB $27,$21,$14,$85    ; GATE (noun)
  DEFB $27,$45,$0E,$14,$0C,$99 ; GENTLY (adjective)
  DEFB $07,$E5,$14,$C0,$8C,$06 ; GET (verb, synonym of TAKE)
  DEFB $07,$E9,$16,$85    ; GIVE (verb)
  DEFB $27,$4C,$0F,$0F,$0D,$99 ; GLOOMY (adjective)
  DEFB $27,$8F,$20,$80    ; GO (verb of motion)
  DEFB $27,$2F,$02,$0C,$09,$8E ; GOBLIN (noun)
  DEFB $27,$4F,$02,$0C,$09,$0E,$93 ; GOBLINS (adjective)
  DEFB $27,$2F,$0C,$84    ; GOLD (noun)
  DEFB $27,$4F,$0C,$04,$05,$8E ; GOLDEN (adjective)
  DEFB $27,$2F,$0C,$0C,$15,$8D ; GOLLUM (noun)
  DEFB $27,$52,$05,$01,$94 ; GREAT (adjective)
  DEFB $27,$52,$05,$05,$8E ; GREEN (adjective)
  DEFB $28,$21,$0C,$8C    ; HALL (noun)
  DEFB $28,$21,$0C,$0C,$93 ; HALLS (noun)
  DEFB $28,$21,$0E,$84    ; HAND (noun)
  DEFB $28,$41,$12,$84    ; HARD (adjective)
  DEFB $28,$25,$01,$84    ; HEAD (noun)
  DEFB $48,$25,$0C,$90    ; HELP (quantifier, pronoun or game command)
  DEFB $28,$25,$01,$12,$94 ; HEART (noun)
  DEFB $28,$45,$01,$16,$99 ; HEAVY (adjective)
  DEFB $08,$65,$0C,$0C,$8F ; HELLO (verb)
  DEFB $28,$49,$04,$04,$05,$8E ; HIDDEN (adjective)
  DEFB $28,$49,$04,$05,$0F,$15,$93 ; HIDEOUS (adjective)
  DEFB $28,$29,$0C,$8C    ; HILL (noun)
  DEFB $28,$29,$0C,$0C,$93 ; HILLS (noun)
  DEFB $08,$E9,$14,$C0,$73,$00 ; HIT (verb, synonym of ATTACK)
  DEFB $28,$4F,$02,$02,$09,$94 ; HOBBIT (adjective)
  DEFB $28,$2F,$02,$02,$09,$14,$0C,$01 ; HOBBITLAND (noun)
  DEFB $0E,$84                         ;
  DEFB $28,$2F,$0C,$85    ; HOLE (noun)
  DEFB $28,$4F,$12,$12,$09,$02,$0C,$85 ; HORRIBLE (adjective)
  DEFB $28,$4F,$15,$13,$85 ; HOUSE (adjective)
  DEFB $08,$75,$12,$12,$99 ; HURRY (verb)
  DEFB $09,$00,$C0,$92,$03 ; I (adverb, synonym of INVENTORY)
  DEFB $09,$2E,$80        ; IN (in or into)
  DEFB $29,$6E,$13,$09,$04,$85 ; INSIDE (preposition)
  DEFB $29,$4E,$13,$09,$07,$0E,$09,$06 ; INSIGNIFICANT (adjective)
  DEFB $09,$03,$01,$0E,$94             ;
  DEFB $09,$2E,$14,$8F    ; INTO (in or into)
  DEFB $09,$6E,$16,$05,$0E,$14,$0F,$12 ; INVENTORY (verb)
  DEFB $99                             ;
  DEFB $49,$13,$80        ; IS (article or the like)
  DEFB $49,$34,$80        ; IT (quantifier, pronoun or game command)
  DEFB $0A,$F5,$0D,$90    ; JUMP (verb)
  DEFB $2B,$25,$99        ; KEY (noun)
  DEFB $0B,$E9,$0C,$CC,$73,$00 ; KILL (verb, synonym of ATTACK)
  DEFB $2B,$29,$0E,$87    ; KING (noun)
  DEFB $0C,$00,$C0,$13,$04 ; L (adverb, synonym of LOOK)
  DEFB $2C,$21,$0B,$85    ; LAKE (noun)
  DEFB $2C,$21,$0E,$84    ; LAND (noun)
  DEFB $2C,$41,$12,$07,$85 ; LARGE (adjective)
  DEFB $0C,$E5,$01,$16,$85 ; LEAVE (verb)
  DEFB $2C,$25,$87        ; LEG (noun)
  DEFB $2C,$45,$16,$05,$0C,$0C,$05,$84 ; LEVELLED (adjective)
  DEFB $0C,$E9,$06,$D4,$8C,$06 ; LIFT (verb, synonym of TAKE)
  DEFB $2C,$49,$0B,$85    ; LIKE (adjective)
  DEFB $0C,$E9,$07,$08,$94 ; LIGHT (verb)
  DEFB $2C,$49,$14,$14,$0C,$85 ; LITTLE (adjective)
  DEFB $0C,$0F,$C0,$13,$04 ; LO (adverb, synonym of LOOK)
  DEFB $4C,$2F,$01,$84    ; LOAD (quantifier, pronoun or game command)
  DEFB $0C,$EF,$03,$8B    ; LOCK (verb)
  DEFB $2C,$4F,$03,$0B,$05,$84 ; LOCKED (adjective)
  DEFB $2C,$2F,$07,$93    ; LOGS (noun)
  DEFB $2C,$2F,$0E,$05,$0C,$01,$0E,$04 ; LONELANDS (noun)
  DEFB $93                             ;
  DEFB $2C,$4F,$0E,$05,$0C,$99 ; LONELY (adjective)
  DEFB $2C,$4F,$0E,$87    ; LONG (adjective)
  DEFB $0C,$EF,$0F,$8B    ; LOOK (verb)
  DEFB $2C,$4F,$97        ; LOW (adjective)
  DEFB $2C,$4F,$17,$05,$92 ; LOWER (adjective)
  DEFB $2C,$35,$0E,$03,$88 ; LUNCH (noun)
  DEFB $2D,$41,$07,$09,$83 ; MAGIC (adjective)
  DEFB $2D,$21,$8E        ; MAN (noun)
  DEFB $2D,$21,$90        ; MAP (noun)
  DEFB $2D,$25,$C0,$A8,$07 ; ME (noun, synonym of YOU)
  DEFB $2D,$45,$01,$8E    ; MEAN (adjective)
  DEFB $2D,$29,$12,$0B,$17,$0F,$0F,$84 ; MIRKWOOD (noun)
  DEFB $2D,$49,$13,$14,$99 ; MISTY (adjective)
  DEFB $2D,$4F,$0E,$13,$14,$12,$0F,$15 ; MONSTROUS (adjective)
  DEFB $93                             ;
  DEFB $2D,$2F,$15,$0E,$14,$01,$09,$8E ; MOUNTAIN (noun)
  DEFB $2D,$2F,$15,$0E,$14,$01,$09,$0E ; MOUNTAINS (noun)
  DEFB $93                             ;
  DEFB $0E,$40,$C0,$80,$04 ; N (direction, synonym of NORTH)
  DEFB $2E,$41,$12,$12,$0F,$97 ; NARROW (adjective)
  DEFB $2E,$41,$13,$14,$99 ; NASTY (adjective)
  DEFB $0E,$45,$C0,$85,$04 ; NE (direction, synonym of NORTHEAST)
  DEFB $2E,$29,$07,$08,$94 ; NIGHT (noun)
  DEFB $4E,$2F,$10,$12,$09,$0E,$94 ; NOPRINT (quantifier, pronoun or game
                                   ; command)
  DEFB $0E,$4F,$12,$14,$88 ; NORTH (direction)
  DEFB $0E,$4F,$12,$14,$08,$05,$01,$13 ; NORTHEAST (direction)
  DEFB $94                             ;
  DEFB $0E,$4F,$12,$14,$08,$17,$05,$13 ; NORTHWEST (direction)
  DEFB $94                             ;
  DEFB $0E,$57,$C0,$8E,$04 ; NW (direction, synonym of NORTHWEST)
  DEFB $2F,$66,$80        ; OF (preposition)
  DEFB $2F,$66,$86        ; OFF (preposition)
  DEFB $0F,$E6,$06,$05,$92 ; OFFER (verb)
  DEFB $2F,$4C,$84        ; OLD (adjective)
  DEFB $2F,$6E,$80        ; ON (preposition)
  DEFB $4F,$2E,$85        ; ONE (quantifier, pronoun or game command)
  DEFB $2F,$6E,$14,$8F    ; ONTO (preposition)
  DEFB $0F,$F0,$05,$8E    ; OPEN (verb)
  DEFB $2F,$30,$05,$0E,$09,$0E,$87 ; OPENING (noun)
  DEFB $2F,$75,$94        ; OUT (preposition)
  DEFB $2F,$55,$14,$13,$09,$04,$85 ; OUTSIDE (adjective)
  DEFB $2F,$76,$05,$92    ; OVER (preposition)
  DEFB $30,$21,$13,$13,$01,$07,$85 ; PASSAGE (noun)
  DEFB $30,$21,$14,$88    ; PATH (noun)
  DEFB $50,$21,$15,$13,$85 ; PAUSE (quantifier, pronoun or game command)
  DEFB $10,$E9,$03,$CB,$0D,$01 ; PICK (verb, synonym of CARRY)
  DEFB $30,$29,$94        ; PIT (noun)
  DEFB $30,$2C,$01,$03,$85 ; PLACE (noun)
  DEFB $10,$0C,$05,$01,$13,$85 ; PLEASE (adverb)
  DEFB $30,$2F,$12,$14,$03,$15,$0C,$0C ; PORTCULLIS (noun)
  DEFB $09,$93                         ;
  DEFB $50,$32,$09,$0E,$94 ; PRINT (quantifier, pronoun or game command)
  DEFB $10,$F5,$0C,$8C    ; PULL (verb)
  DEFB $10,$F5,$33,$88    ; PUSH (verb)
  DEFB $10,$F5,$14,$80    ; PUT (verb)
  DEFB $11,$15,$09,$03,$0B,$0C,$99 ; QUICKLY (adverb)
  DEFB $11,$15,$09,$05,$94 ; QUIET (adverb)
  DEFB $51,$35,$09,$94    ; QUIT (quantifier, pronoun or game command)
  DEFB $31,$55,$09,$14,$85 ; QUITE (adjective)
  DEFB $32,$21,$16,$05,$0E,$08,$09,$0C ; RAVENHILL (noun)
  DEFB $8C                             ;
  DEFB $32,$21,$16,$09,$0E,$85 ; RAVINE (noun)
  DEFB $12,$65,$01,$C4,$3E,$02 ; READ (verb, synonym of EXAMINE)
  DEFB $32,$45,$84        ; RED (adjective)
  DEFB $32,$29,$02,$93    ; RIBS (noun)
  DEFB $32,$29,$0E,$87    ; RING (noun)
  DEFB $32,$29,$16,$05,$0E,$04,$05,$0C ; RIVENDELL (noun)
  DEFB $8C                             ;
  DEFB $32,$29,$16,$05,$92 ; RIVER (noun)
  DEFB $32,$2F,$01,$84    ; ROAD (noun)
  DEFB $32,$4F,$03,$8B    ; ROCK (adjective)
  DEFB $32,$2F,$0F,$8D    ; ROOM (noun)
  DEFB $32,$2F,$10,$85    ; ROPE (noun)
  DEFB $32,$4F,$15,$0E,$84 ; ROUND (adjective)
  DEFB $32,$35,$87        ; RUG (noun)
  DEFB $32,$35,$09,$0E,$93 ; RUINS (noun)
  DEFB $32,$95,$0E,$80    ; RUN (verb of motion)
  DEFB $32,$35,$0E,$0E,$09,$0E,$87 ; RUNNING (noun)
  DEFB $13,$40,$C0,$07,$06 ; S (direction, synonym of SOUTH)
  DEFB $33,$21,$0E,$84    ; SAND (noun)
  DEFB $53,$21,$16,$85    ; SAVE (quantifier, pronoun or game command)
  DEFB $13,$E1,$19,$C0,$90,$06 ; SAY (verb, synonym of TALK)
  DEFB $53,$23,$0F,$12,$85 ; SCORE (quantifier, pronoun or game command)
  DEFB $13,$45,$C0,$0C,$06 ; SE (direction, synonym of SOUTHEAST)
  DEFB $13,$E8,$0F,$0F,$94 ; SHOOT (verb)
  DEFB $33,$48,$0F,$12,$94 ; SHORT (adjective)
  DEFB $33,$28,$0F,$15,$0C,$04,$05,$92 ; SHOULDER (noun)
  DEFB $33,$49,$04,$85    ; SIDE (adjective)
  DEFB $33,$29,$04,$05,$04,$0F,$0F,$92 ; SIDEDOOR (noun)
  DEFB $33,$29,$07,$8E    ; SIGN (noun)
  DEFB $13,$69,$0E,$87    ; SING (verb)
  DEFB $13,$E9,$14,$80    ; SIT (verb)
  DEFB $33,$2B,$15,$0C,$8C ; SKULL (noun)
  DEFB $13,$EC,$21,$13,$C8,$73,$00 ; SLASH (verb, synonym of ATTACK)
  DEFB $13,$EC,$05,$05,$90 ; SLEEP (verb)
  DEFB $13,$EC,$09,$03,$C5,$73,$00 ; SLICE (verb, synonym of ATTACK)
  DEFB $33,$4C,$09,$0D,$99 ; SLIMY (adjective)
  DEFB $13,$0C,$0F,$17,$0C,$99 ; SLOWLY (adverb)
  DEFB $33,$4D,$01,$0C,$8C ; SMALL (adjective)
  DEFB $13,$ED,$21,$13,$C8,$58,$06 ; SMASH (verb, synonym of STRIKE)
  DEFB $33,$4D,$0F,$0F,$14,$88 ; SMOOTH (adjective)
  DEFB $33,$4D,$0F,$14,$08,$05,$12,$09 ; SMOTHERING (adjective)
  DEFB $0E,$87                         ;
  DEFB $13,$0F,$06,$14,$0C,$99 ; SOFTLY (adverb)
  DEFB $33,$4F,$0D,$85    ; SOME (adjective)
  DEFB $13,$4F,$15,$14,$88 ; SOUTH (direction)
  DEFB $13,$4F,$15,$14,$08,$05,$01,$13 ; SOUTHEAST (direction)
  DEFB $94                             ;
  DEFB $13,$4F,$15,$14,$08,$17,$05,$13 ; SOUTHWEST (direction)
  DEFB $94                             ;
  DEFB $33,$30,$01,$03,$85 ; SPACE (noun)
  DEFB $33,$50,$09,$04,$05,$92 ; SPIDER (adjective)
  DEFB $33,$34,$01,$09,$12,$93 ; STAIRS (noun)
  DEFB $33,$34,$01,$14,$15,$85 ; STATUE (noun)
  DEFB $13,$F4,$05,$01,$CC,$8C,$06 ; STEAL (verb, synonym of TAKE)
  DEFB $33,$54,$05,$05,$90 ; STEEP (adjective)
  DEFB $33,$34,$0F,$0E,$85 ; STONE (noun)
  DEFB $33,$54,$12,$01,$09,$07,$08,$94 ; STRAIGHT (adjective)
  DEFB $33,$54,$12,$05,$14,$03,$08,$09 ; STRETCHING (adjective)
  DEFB $0E,$87                         ;
  DEFB $13,$F4,$12,$09,$0B,$85 ; STRIKE (verb)
  DEFB $33,$34,$12,$0F,$0B,$85 ; STROKE (noun)
  DEFB $33,$34,$12,$0F,$0E,$87 ; STRONG (noun)
  DEFB $33,$54,$15,$06,$06,$99 ; STUFFY (adjective)
  DEFB $33,$54,$15,$0E,$0E,$05,$84 ; STUNNED (adjective)
  DEFB $13,$57,$C0,$15,$06 ; SW (direction, synonym of SOUTHWEST)
  DEFB $13,$F7,$09,$8D    ; SWIM (verb)
  DEFB $33,$37,$0F,$12,$84 ; SWORD (noun)
  DEFB $33,$39,$0D,$02,$0F,$0C,$93 ; SYMBOLS (noun)
  DEFB $14,$E1,$0B,$85    ; TAKE (verb)
  DEFB $14,$61,$0C,$8B    ; TALK (verb)
  DEFB $34,$41,$0E,$07,$0C,$05,$84 ; TANGLED (adjective)
  DEFB $54,$08,$01,$94    ; THAT (article or the like)
  DEFB $54,$08,$85        ; THE (article or the like)
  DEFB $54,$68,$05,$8E    ; THEN (then)
  DEFB $34,$48,$09,$03,$8B ; THICK (adjective)
  DEFB $34,$28,$09,$05,$86 ; THIEF (noun)
  DEFB $34,$48,$09,$8E    ; THIN (adjective)
  DEFB $34,$28,$0F,$12,$09,$8E ; THORIN (noun)
  DEFB $34,$48,$12,$05,$01,$04,$93 ; THREADS (adjective)
  DEFB $34,$68,$12,$0F,$15,$07,$88 ; THROUGH (preposition)
  DEFB $14,$E8,$12,$0F,$97 ; THROW (verb)
  DEFB $14,$E9,$05,$80    ; TIE (verb)
  DEFB $34,$6F,$80        ; TO (preposition)
  DEFB $34,$6F,$8F        ; TOO (preposition)
  DEFB $34,$AF,$32,$03,$88 ; TORCH (noun)
  DEFB $34,$2F,$17,$8E    ; TOWN (noun)
  DEFB $34,$52,$01,$90    ; TRAP (adjective)
  DEFB $34,$32,$05,$01,$13,$15,$12,$85 ; TREASURE (noun)
  DEFB $34,$B2,$05,$85    ; TREE (noun)
  DEFB $34,$52,$05,$05,$0C,$05,$13,$93 ; TREELESS (adjective)
  DEFB $34,$32,$0F,$0C,$8C ; TROLL (noun)
  DEFB $34,$52,$0F,$0C,$0C,$93 ; TROLLS (adjective)
  DEFB $34,$55,$0E,$0E,$05,$8C ; TUNNEL (adjective)
  DEFB $14,$F5,$12,$8E    ; TURN (verb)
  DEFB $15,$00,$C0,$25,$07 ; U (adverb, synonym of UP)
  DEFB $15,$EE,$0C,$0F,$03,$8B ; UNLOCK (verb)
  DEFB $35,$4E,$0C,$0F,$03,$0B,$05,$84 ; UNLOCKED (adjective)
  DEFB $15,$EE,$14,$09,$85 ; UNTIE (verb)
  DEFB $15,$50,$80        ; UP (direction)
  DEFB $36,$41,$0C,$09,$01,$0E,$94 ; VALIANT (adjective)
  DEFB $36,$21,$0C,$0C,$05,$99 ; VALLEY (noun)
  DEFB $36,$41,$0C,$15,$01,$02,$0C,$85 ; VALUABLE (adjective)
  DEFB $36,$45,$12,$99    ; VERY (adjective)
  DEFB $36,$49,$03,$09,$0F,$15,$93 ; VICIOUS (adjective)
  DEFB $16,$09,$03,$09,$0F,$15,$13,$0C ; VICIOUSLY (adverb)
  DEFB $99                             ;
  DEFB $17,$40,$C0,$79,$07 ; W (direction, synonym of WEST)
  DEFB $17,$E1,$09,$94    ; WAIT (verb)
  DEFB $37,$A1,$0C,$8C    ; WALL (noun)
  DEFB $37,$21,$14,$05,$92 ; WATER (noun)
  DEFB $37,$21,$14,$05,$12,$06,$01,$0C ; WATERFALL (noun)
  DEFB $8C                             ;
  DEFB $37,$25,$01,$10,$0F,$8E ; WEAPON (noun)
  DEFB $17,$E5,$01,$92    ; WEAR (verb)
  DEFB $37,$25,$82        ; WEB (noun)
  DEFB $17,$45,$13,$94    ; WEST (direction)
  DEFB $37,$49,$04,$85    ; WIDE (adjective)
  DEFB $37,$49,$0C,$84    ; WILD (adjective)
  DEFB $37,$49,$0E,$04,$09,$0E,$87 ; WINDING (adjective)
  DEFB $37,$29,$0E,$04,$0F,$97 ; WINDOW (noun)
  DEFB $37,$29,$0E,$85    ; WINE (noun)
  DEFB $37,$69,$14,$88    ; WITH (preposition)
  DEFB $37,$21,$12,$87    ; WARG (noun)
  DEFB $37,$4F,$0F,$84    ; WOOD (adjective)
  DEFB $37,$4F,$0F,$04,$05,$8E ; WOODEN (adjective)
  DEFB $39,$2F,$95        ; YOU (noun)

; The words the game prints, as opposed to the words it reads
;
; Packed exactly like the indexed dictionary above -- one 5-bit letter per
; byte, bit 7 ending a word -- and running up the alphabet again from the
; start. Nothing in the 26-letter index at WORD_INDEX reaches it, and nothing
; anywhere holds its address: PRINT_WORD is handed a 12-bit offset from
; WORD_INDEX and lands wherever that points, so a word is only ever referred to
; by its own offset and the start of the list is of no interest to anything.
;
; Which is why searching for a pointer to SECOND_LIST, as an address or as an
; offset, finds nothing at all. It was found instead with a read watchpoint
; over the whole range while the game played: it stays untouched through the
; opening, LOOK and INVENTORY, and is first read on a command that composes a
; sentence about an object.
SECOND_LIST:
  DEFB $00,$01,$02,$0C,$85 ; ABLE
  DEFB $01,$02,$0F,$15,$94 ; ABOUT
  DEFB $01,$02,$0F,$16,$85 ; ABOVE
  DEFB $01,$04,$16,$05,$0E,$14,$15,$12 ; ADVENTURE
  DEFB $85                             ;
  DEFB $01,$07,$01,$09,$8E ; AGAIN
  DEFB $01,$07,$01,$09,$0E,$13,$94 ; AGAINST
  DEFB $01,$08,$05,$01,$84 ; AHEAD
  DEFB $01,$0C,$09,$16,$85 ; ALIVE
  DEFB $01,$0C,$0D,$0F,$13,$94 ; ALMOST
  DEFB $01,$0C,$0F,$0E,$87 ; ALONG
  DEFB $01,$0E,$09,$0D,$01,$8C ; ANIMAL
  DEFB $01,$90,$10,$05,$01,$92 ; APPEAR
  DEFB $01,$90,$B0,$12,$0F,$01,$03,$88 ; APPROACH
  DEFB $01,$12,$0F,$15,$0E,$84 ; AROUND
WORD_ARRIVES:
  DEFB $01,$12,$12,$09,$16,$05,$93 ; ARRIVES
  DEFB $01,$13,$80        ; AS
  DEFB $01,$13,$09,$04,$85 ; ASIDE
  DEFB $01,$13,$0C,$05,$05,$90 ; ASLEEP
  DEFB $01,$94,$14,$05,$0D,$10,$94 ; ATTEMPT
  DEFB $01,$17,$01,$99    ; AWAY
  DEFB $02,$01,$0E,$8B    ; BANK
  DEFB $02,$05,$80        ; BE
  DEFB $02,$05,$08,$09,$0E,$84 ; BEHIND
  DEFB $02,$05,$0C,$0F,$97 ; BELOW
  DEFB $02,$09,$12,$14,$08,$04,$01,$99 ; BIRTHDAY
  DEFB $02,$0C,$09,$0D,$05,$99 ; BLIMEY
  DEFB $02,$92,$21,$0E,$04,$09,$13,$88 ; BRANDISH
  DEFB $02,$12,$09,$0E,$8B ; BRINK
  DEFB $02,$12,$0F,$01,$04,$13,$09,$04 ; BROADSIDE
  DEFB $85                             ;
  DEFB $02,$15,$0C,$02,$0F,$15,$93 ; BULBOUS
  DEFB $02,$19,$80        ; BY
  DEFB $03,$01,$12,$12,$19,$09,$0E,$87 ; CARRYING
  DEFB $03,$8C,$05,$01,$16,$85 ; CLEAVE
  DEFB $03,$0C,$09,$06,$86 ; CLIFF
  DEFB $03,$8F,$0D,$85    ; COME
  DEFB $03,$8F,$8D,$10,$0C,$05,$14,$85 ; COMPLETE
  DEFB $03,$8F,$0E,$07,$12,$01,$14,$15 ; CONGRATULATION
  DEFB $0C,$01,$14,$09,$0F,$8E         ;
  DEFB $03,$0F,$0F,$8B    ; COOK
  DEFB $03,$15,$12,$12,$05,$0E,$94 ; CURRENT
  DEFB $03,$12,$09,$13,$90 ; CRISP
  DEFB $04,$81,$17,$8E    ; DAWN
  DEFB $04,$01,$99        ; DAY
  DEFB $04,$05,$06,$05,$0E,$13,$85 ; DEFENSE
  DEFB $04,$05,$13,$03,$05,$0E,$04,$93 ; DESCENDS
  DEFB $04,$09,$85        ; DIE
  DEFB $04,$09,$84        ; DID
  DEFB $04,$09,$8D        ; DIM
  DEFB $04,$09,$13,$14,$01,$0E,$03,$85 ; DISTANCE
  DEFB $04,$8F,$20,$80    ; DO
  DEFB $04,$8F,$A0,$80    ; DO
  DEFB $04,$12,$09,$10,$93 ; DRIPS
  DEFB $05,$06,$06,$0F,$12,$94 ; EFFORT
  DEFB $05,$8E,$04,$80    ; END
  DEFB $05,$0E,$14,$12,$01,$0E,$03,$85 ; ENTRANCE
  DEFB $05,$96,$01,$10,$0F,$12,$01,$14 ; EVAPORATE
  DEFB $85                             ;
  DEFB $05,$16,$05,$0E,$09,$0E,$87 ; EVENING
  DEFB $05,$18,$09,$14,$93 ; EXITS
  DEFB $05,$18,$10,$05,$03,$94 ; EXPECT
  DEFB $06,$01,$09,$0C,$05,$84 ; FAILED
  DEFB $06,$01,$09,$0C,$09,$0E,$87 ; FAILING
  DEFB $06,$01,$92        ; FAR
  DEFB $06,$01,$14,$01,$8C ; FATAL
  DEFB $06,$05,$05,$84    ; FEED
  DEFB $06,$05,$0C,$94    ; FELT
  DEFB $06,$09,$94        ; FIT
  DEFB $06,$09,$12,$13,$94 ; FIRST
  DEFB $06,$8C,$01,$0D,$85 ; FLAME
  DEFB $06,$8C,$0F,$01,$94 ; FLOAT
  DEFB $06,$0C,$19,$09,$0E,$87 ; FLYING
  DEFB $06,$0F,$0F,$94    ; FOOT
  DEFB $06,$0F,$0F,$14,$09,$0E,$87 ; FOOTING
  DEFB $06,$0F,$15,$92    ; FOUR
  DEFB $06,$12,$0F,$0E,$94 ; FRONT
  DEFB $07,$05,$14,$14,$09,$0E,$87 ; GETTING
  DEFB $07,$0C,$01,$0E,$03,$09,$0E,$87 ; GLANCING
  DEFB $07,$0C,$09,$04,$05,$93 ; GLIDES
  DEFB $07,$0C,$15,$14,$14,$0F,$0E,$99 ; GLUTTONY
  DEFB $07,$0F,$94        ; GOT
  DEFB $07,$12,$0F,$15,$0E,$84 ; GROUND
  DEFB $07,$12,$0F,$97    ; GROW
  DEFB $07,$15,$01,$12,$84 ; GUARD
  DEFB $08,$01,$0E,$07,$09,$0E,$87 ; HANGING
  DEFB $08,$01,$93        ; HAS
  DEFB $08,$01,$16,$85    ; HAVE
  DEFB $08,$05,$80        ; HE
  DEFB $08,$85,$81,$92    ; HEAR
  DEFB $08,$05,$12,$85    ; HERE
  DEFB $08,$09,$8D        ; HIM
  DEFB $08,$09,$93        ; HIS
  DEFB $08,$0F,$97        ; HOW
  DEFB $08,$0F,$17,$0C,$93 ; HOWLS
  DEFB $08,$15,$12,$12,$99 ; HURRY
  DEFB $09,$0E,$05,$06,$06,$05,$03,$14 ; INEFFECTIVE
  DEFB $09,$16,$85                     ;
  DEFB $09,$14,$93        ; ITS
  DEFB $0A,$0F,$82        ; JOB
  DEFB $0A,$15,$13,$94    ; JUST
  DEFB $0C,$15,$12,$03,$88 ; LURCH
  DEFB $0B,$05,$05,$10,$93 ; KEEPS
  DEFB $0B,$0E,$0F,$03,$0B,$93 ; KNOCKS
  DEFB $0B,$0E,$0F,$97    ; KNOW
  DEFB $0C,$01,$13,$94    ; LAST
  DEFB $0C,$01,$15,$07,$08,$93 ; LAUGHS
  DEFB $0C,$01,$15,$07,$08,$14,$05,$92 ; LAUGHTER
  DEFB $0C,$89,$05,$80    ; LIE
  DEFB $0C,$09,$06,$85    ; LIFE
  DEFB $0C,$09,$16,$05,$93 ; LIVES
  DEFB $0C,$8F,$13,$85    ; LOSE
  DEFB $0C,$0F,$15,$84    ; LOUD
  DEFB $0C,$15,$03,$0B,$99 ; LUCKY
  DEFB $0D,$01,$04,$85    ; MADE
  DEFB $0D,$01,$0B,$85    ; MAKE
  DEFB $0D,$01,$12,$07,$09,$8E ; MARGIN
  DEFB $0D,$01,$12,$16,$05,$0C,$0C,$0F ; MARVELLOUS
  DEFB $15,$93                         ;
  DEFB $0D,$01,$99        ; MAY
  DEFB $0D,$01,$19,$02,$85 ; MAYBE
  DEFB $0D,$85,$AE,$84    ; MEND
  DEFB $0D,$09,$04,$04,$0C,$85 ; MIDDLE
  DEFB $0D,$09,$04,$04,$01,$99 ; MIDDAY
  DEFB $0D,$89,$33,$93    ; MISS
  DEFB $0D,$0F,$0D,$05,$0E,$94 ; MOMENT
  DEFB $0D,$0F,$0D,$05,$0E,$14,$01,$12 ; MOMENTARILY
  DEFB $09,$0C,$99                     ;
  DEFB $0D,$8F,$B2,$8E    ; MORN
  DEFB $0D,$0F,$15,$14,$08,$06,$15,$0C ; MOUTHFULL
  DEFB $8C                             ;
  DEFB $0D,$0F,$16,$85    ; MOVE
  DEFB $0D,$15,$03,$88    ; MUCH
  DEFB $0D,$19,$80        ; MY
  DEFB $0E,$0F,$80        ; NO
  DEFB $0E,$0F,$09,$13,$85 ; NOISE
  DEFB $0E,$0F,$94        ; NOT
  DEFB $0E,$0F,$14,$08,$09,$0E,$87 ; NOTHING
  DEFB $0E,$0F,$97        ; NOW
  DEFB $0F,$0E,$03,$85    ; ONCE
  DEFB $0F,$14,$08,$05,$92 ; OTHER
  DEFB $10,$01,$0C,$85    ; PALE
  DEFB $10,$01,$13,$13,$05,$93 ; PASSES
  DEFB $10,$01,$13,$94    ; PAST
  DEFB $10,$8C,$81,$03,$85 ; PLACE
  DEFB $10,$8F,$03,$0B,$05,$94 ; POCKET
  DEFB $10,$92,$05,$03,$09,$0F,$15,$93 ; PRECIOUS
  DEFB $10,$12,$05,$10,$01,$12,$85 ; PREPARE
  DEFB $10,$12,$05,$13,$05,$0E,$94 ; PRESENT
  DEFB $12,$05,$01,$03,$88 ; REACH
WORD_RECOVER:
  DEFB $12,$85,$03,$0F,$16,$05,$92 ; RECOVER
  DEFB $13,$81,$09,$8C    ; SAIL
  DEFB $13,$05,$85        ; SEE
  DEFB $13,$85,$05,$8D    ; SEEM
  DEFB $13,$08,$01,$04,$0F,$97 ; SHADOW
  DEFB $13,$08,$01,$10,$85 ; SHAPE
WORD_SHATTER:
  DEFB $13,$88,$01,$14,$14,$05,$92 ; SHATTER
  DEFB $13,$89,$AE,$87    ; SING
  DEFB $13,$89,$AE,$8B    ; SINK
  DEFB $13,$89,$14,$80    ; SIT
  DEFB $13,$8C,$09,$04,$85 ; SLIDE
  DEFB $13,$0D,$05,$0C,$8C ; SMELL
  DEFB $13,$0D,$05,$0C,$94 ; SMELT
  DEFB $13,$0F,$0D,$05,$0F,$0E,$85 ; SOMEONE
  DEFB $13,$0F,$0D,$05,$17,$08,$05,$12 ; SOMEWHERE
  DEFB $85                             ;
  DEFB $13,$0F,$0F,$8E    ; SOON
  DEFB $13,$10,$05,$03,$09,$01,$8C ; SPECIAL
  DEFB $13,$90,$0F,$15,$94 ; SPOUT
  DEFB $13,$94,$01,$07,$07,$05,$92 ; STAGGER
  DEFB $13,$94,$A1,$0E,$84 ; STAND
  DEFB $13,$94,$01,$92    ; STAR
  DEFB $13,$94,$A1,$92    ; STAR
  DEFB $13,$94,$01,$12,$94 ; START
  DEFB $13,$14,$09,$0C,$8C ; STILL
  DEFB $13,$94,$09,$0E,$87 ; STING
  DEFB $13,$94,$12,$01,$0E,$07,$0C,$85 ; STRANGLE
  DEFB $13,$14,$12,$05,$0E,$07,$14,$88 ; STRENGTH
  DEFB $13,$15,$12,$12,$0F,$15,$0E,$04 ; SURROUNDED
  DEFB $05,$84                         ;
  DEFB $13,$17,$05,$05,$10,$93 ; SWEEPS
  DEFB $13,$17,$05,$10,$94 ; SWEPT
  DEFB $13,$97,$09,$0E,$87 ; SWING
  DEFB $14,$05,$12,$12,$09,$06,$09,$83 ; TERRIFIC
  DEFB $14,$08,$01,$0E,$8B ; THANK
  DEFB $14,$08,$05,$8D    ; THEM
  DEFB $14,$08,$05,$12,$85 ; THERE
  DEFB $14,$08,$09,$0E,$87 ; THING
  DEFB $14,$08,$09,$93    ; THIS
  DEFB $14,$08,$12,$01,$09,$0E,$93 ; THRAINS
  DEFB $14,$08,$12,$05,$85 ; THREE
  DEFB $14,$08,$12,$0F,$17,$8E ; THROWN
  DEFB $14,$88,$12,$15,$13,$94 ; THRUST
  DEFB $14,$09,$0D,$85    ; TIME
  DEFB $14,$09,$12,$05,$84 ; TIRED
  DEFB $14,$12,$99        ; TRY
  DEFB $14,$0F,$15,$03,$88 ; TOUCH
  DEFB $14,$17,$8F        ; TWO
  DEFB $15,$0E,$04,$05,$92 ; UNDER
  DEFB $15,$13,$80        ; US
  DEFB $16,$81,$2E,$09,$13,$88 ; VANISH
  DEFB $16,$05,$12,$82    ; VERB
  DEFB $16,$09,$13,$09,$02,$0C,$85 ; VISIBLE
  DEFB $17,$81,$12,$8E    ; WARN
  DEFB $17,$01,$93        ; WAS
  DEFB $17,$01,$13,$14,$05,$84 ; WASTED
  DEFB $17,$05,$80        ; WE
  DEFB $17,$05,$0C,$8C    ; WELL
  DEFB $17,$08,$01,$94    ; WHAT
  DEFB $17,$08,$05,$12,$85 ; WHERE
  DEFB $17,$08,$09,$03,$88 ; WHICH
  DEFB $17,$09,$0C,$8C    ; WILL
  DEFB $17,$09,$0E,$84    ; WIND
  DEFB $17,$0F,$12,$84    ; WORD
  DEFB $17,$0F,$15,$0C,$84 ; WOULD
  DEFB $19,$05,$92        ; YER
  DEFB $19,$0F,$15,$92    ; YOUR
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; Zeros, to the start of the code
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00                         ;
; So the two lists divide by direction, not by content: the indexed one is what
; MATCH_WORD searches when you type, and this one is the vocabulary the
; messages are built from. Both live within the 4096 bytes from WORD_INDEX that
; PRINT_WORD's 12-bit offsets can reach, which is what the whole dictionary
; region is sized for.

; The game's entry point
;
; Reached by PRINT USR 27648, and never left: it runs on into MAIN_LOOP at
; MAIN_LOOP, which is the game. It first copies the whole of the game's
; changeable state aside -- the objects to WORLD_COPY, the rooms straight after
; them, the variables at SAVED_STATE and the TIMERS block to $5F00 -- and every
; new game at NEW_GAME copies it back, which is how dying and starting again
; restores the world as it was loaded.
START:
  DI
  LD DE,WORLD_COPY        ; The objects and the rooms, to WORLD_COPY onwards
  LD HL,PLAYER            ;
  LD BC,$0615             ;
  LDIR                    ;
  LD HL,ROOM0             ;
  LD BC,$05D9             ;
  LDIR                    ;
  LD DE,$5F00             ; The variables and the timers, to $5F00 onwards
  LD HL,SAVED_STATE       ;
  LD BC,$001D             ;
  LDIR                    ;
  LD HL,TIMERS            ;
  LD BC,$00BF             ;
  LDIR                    ;
; This entry point is used by the routines at DO_QUIT, LOAD_BLOCK and
; PLAYER_DIES.
NEW_GAME:
  DI                      ; A new game starts here
  LD SP,$5EFF             ;
  LD IX,PICTURE_TABLE     ; Not yet worked out: zeroes two bytes found through
  LD A,$05                ; picture 5's entry
  CALL FIND_RECORD        ;
  LD L,(IX+$01)           ;
  LD H,(IX+$02)           ;
  LD (HL),$00             ;
  INC HL                  ;
  LD (HL),$00             ;
  LD HL,WORLD_COPY        ; Copy the saved state back
  LD DE,PLAYER            ;
  LD BC,$0615             ;
  LDIR                    ;
  LD DE,ROOM0             ;
  LD BC,$05D9             ;
  LDIR                    ;
  LD HL,$5F00             ;
  LD DE,SAVED_STATE       ;
  LD BC,$001D             ;
  LDIR                    ;
  LD DE,TIMERS            ;
  LD BC,$00BF             ;
  LDIR                    ;
  XOR A                   ; Black border; the ROM told the border is black too
  OUT ($FE),A             ;
  LD A,$38                ;
  LD ($5C48),A            ;
TITLE_WAIT:
  XOR A                   ; The title screen: wait for a key
  IN A,($FE)              ;
  AND $1F                 ;
  CP $1F                  ;
  JR Z,TITLE_WAIT         ;
  LD A,$7F                ; N held down: no pictures (PICTURES_ON)
  IN A,($FE)              ;
  AND $08                 ;
  LD (PICTURES_ON),A      ;
  LD HL,$50E0             ; Both windows' cursors to the start
  LD (INPUT_CURSOR),HL    ;
  LD A,$2B                ;
  LD (CURSOR_CHAR),A      ;
  LD HL,$5020             ;
  LD (STORY_CURSOR),HL    ;
  LD A,$01                ;
  LD (STORY_PIXEL),A      ;
  LD A,$20                ;
  LD (INPUT_COLUMNS),A    ;
  LD A,$2A                ;
  LD (STORY_COLUMNS),A    ;
  LD B,$C8                ; No orders waiting
  LD HL,ORDERS            ;
  CALL CLEAR_BYTES        ;
  LD A,R                  ; Seed RANDOM from R
  LD (RANDOM_LAST),A      ;
  XOR A                   ; The rest of the variables: sober, no printer,
  LD (INDENT),A           ; printing on, a capital first, no score
  LD (MID_LINE),A         ;
  LD (QUESTION_WAITING),A ;
  LD (DRUNK),A            ;
  LD (TO_PRINTER),A       ;
  LD A,$01                ;
  LD (PRINTING_ON),A      ;
  LD (DOING_IT),A         ;
  LD (CAPITAL_NEXT),A     ;
  LD HL,$0000             ;
  LD (SCORE),HL           ;
  CALL CLEAR_SCREEN       ; Clear the screen and draw the divider
  LD HL,$5140             ;
  LD DE,DIVIDER           ;
  LD C,$05                ;
START_0:
  LD B,$10                ;
  PUSH HL                 ;
START_1:
  LD A,(DE)               ;
  LD (HL),A               ;
  INC HL                  ;
  INC DE                  ;
  LD A,(DE)               ;
  LD (HL),A               ;
  INC HL                  ;
  DEC DE                  ;
  DJNZ START_1            ;
  INC DE                  ;
  INC DE                  ;
  POP HL                  ;
  INC H                   ;
  DEC C                   ;
  JR NZ,START_0           ;
  LD A,$11                ; The first 17 lines of story without a pause
  LD (NO_PAUSE_LINES),A   ;
  LD A,(COMMAND_FRAMES)   ; Come back here with a command to repeat? Straight
  INC A                   ; to it
  JR NZ,MAIN_LOOP         ;
  CALL NEW_GAME_CHOICES   ; Shut a road and choose a riddle
  LD HL,FIRST_COMMAND     ; The first turn: "> LOOK" printed and put in the
START_2:
  LD A,(HL)               ; line
  CALL INPUT_CHAR_A       ;
  INC HL                  ;
  CP $0D                  ;
  JR NZ,START_2           ;
  LD HL,LOOK_COMMAND      ;
  LD DE,INPUT_LINE        ;
  LD BC,$0005             ;
  LDIR                    ;
  JR START_3              ;
MAIN_LOOP:
  LD A,$01                ; The main loop: a new line; nine lines of story
  LD (MORE_COMMANDS),A    ; before a pause
  LD A,$09                ;
  LD (NO_PAUSE_LINES),A   ;
  CALL READ_LINE          ; Read it; @ reruns the last
  JR Z,START_7            ;
START_3:
  LD HL,TOKENS            ; Tokenise it into TOKENS
  LD B,$40                ;
  CALL CLEAR_BYTES        ;
  LD HL,INPUT_LINE        ;
  LD IY,TOKENS            ;
START_4:
  CALL TOKENISE           ; The next word; unknown: say so
  CP $D0                  ;
  JR Z,UNKNOWN_WORD       ;
  CP $90                  ; An opening quote: an order to someone
  JR NZ,START_6           ;
  LD A,B                  ;
  AND $0F                 ;
  OR C                    ;
  JR NZ,START_6           ;
  LD A,(IS_ORDER)         ;
  AND A                   ;
  JR NZ,START_5           ;
  INC A                   ;
  LD (IS_ORDER),A         ;
  JR START_6              ;
START_5:
  DEC A                   ; A closing quote: end the order, as if with THEN
  LD (IS_ORDER),A         ;
  LD A,(IY-$02)           ;
  AND $F0                 ;
  CP $B0                  ;
  JR Z,START_6            ;
  CP $A0                  ;
  JR Z,START_6            ;
  LD A,$B0                ;
  LD (IY+$00),A           ;
  XOR A                   ;
  LD (IY+$01),A           ;
  INC IY                  ;
  INC IY                  ;
START_6:
  LD (IY+$00),B           ; Keep the token, to the end of the line
  LD (IY+$01),C           ;
  INC IY                  ;
  INC IY                  ;
  LD A,D                  ;
  CP $C0                  ;
  JR NZ,START_4           ;
  LD A,(IS_ORDER)         ; A quote left open: "what ?"
  AND A                   ;
  JR Z,START_7            ;
  XOR A                   ;
  LD (IS_ORDER),A         ;
  CALL QUOTE_LEFT_OPEN    ;
  JR MAIN_LOOP            ;
START_7:
  LD HL,TOKENS            ; Parse from the start of TOKENS
  LD (TOKEN_POINTER),HL   ;
START_8:
  CALL PARSE_COMMAND      ; The next command in it
  JP NZ,MAIN_LOOP         ;
  CALL OBEY               ; Obey it, and on while there are more
  LD A,(MORE_COMMANDS)    ;
  AND A                   ;
  JR NZ,START_8           ;
  JP MAIN_LOOP            ;
UNKNOWN_WORD:
  LD HL,MSG_I_DO_NOT_KNOW ; "i do not know the word "...
  LD A,$01                ;
  LD (INPUT_STYLE),A      ;
  CALL RUN_MESSAGE_HL     ;
  LD HL,(VARIABLES)       ; ...and the word itself, in quotes
START_9:
  LD A,(HL)               ;
  CP $0D                  ;
  JR Z,START_10           ;
  CP $22                  ;
  JR Z,START_10           ;
  CALL PRINT_CHAR         ;
  INC HL                  ;
  CP $20                  ;
  JR NZ,START_9           ;
START_10:
  LD A,$22                ;
  CALL PRINT_CHAR         ;
  CALL NEW_LINE           ;
  JP MAIN_LOOP

; The wavy line between the story and the input window
;
; Five pairs of bytes, each pair repeated across a pixel row at $5140 by START.
DIVIDER:
  DEFB $C3,$C3,$2C,$34,$10,$08,$2C,$34
  DEFB $C3,$C3

; Read a command from the keyboard
;
; Used by the routine at START.
;
; Prints the prompt, then takes keys into INPUT_LINE until a carriage return:
; letters, space, quote, comma and full stop are kept and echoed, backspace
; steps back, and anything else is ignored. The cursor lives only in registers
; -- HL walks the line and B counts the room left in it, 128 to start -- so
; there is no variable in memory that says how much has been typed.
;
; That is what makes putting a whole command in from outside possible but not
; quite trivial: stop at READ_LINE_0, just after HL and B are set, write the
; text into the line, move HL and B past it, and press ENTER. The reader then
; files the return after the text exactly as if the rest had been typed.
;
; O:F NZ when a line has been read
READ_LINE:
  LD HL,$0BB8             ; Patience: GET_KEY waits this long before typing
  LD (PATIENCE),HL        ; WAIT itself
  LD A,$01                ; Flags read by the printing code while a line is
  LD (INPUT_STYLE),A      ; being typed
  LD (DOING_IT),A         ;
  LD A,$3E                ; The prompt: "> "
  CALL PRINT_CHAR         ;
  LD A,$20                ;
  CALL PRINT_CHAR         ;
  LD HL,INPUT_LINE        ; HL = the start of INPUT_LINE, B = room for 128
  LD B,$80                ; characters
READ_LINE_0:
  LD C,$00                ; Nothing typed yet on this line
; This entry point is used by the routine at REPEAT_LAST.
READ_LINE_KEY:
  CALL GET_KEY            ; Wait for a key
  BIT 7,B                 ; @ on an empty line: do the last command again
  JR Z,READ_LINE_1        ;
  CP $40                  ;
  JP Z,REPEAT_LAST        ;
READ_LINE_1:
  BIT 0,C                 ; The first key of a line may be a one-key move
  CALL Z,ONE_KEY_MOVES    ; (ONE_KEY_MOVES)
  LD C,$01                ;
  CP $18                  ; $18 clears the line and starts again
  JR NZ,READ_LINE_2       ;
  CALL RUB_OUT_LINE       ;
  JR READ_LINE_0          ;
READ_LINE_2:
  CP $08                  ; Backspace, unless the line is empty: step back one
  JR NZ,READ_LINE_3       ;
  BIT 7,B                 ;
  JR NZ,READ_LINE_KEY     ;
  LD A,$08                ;
  CALL PRINT_CHAR         ;
  INC B                   ;
  DEC HL                  ;
  JR READ_LINE_KEY        ;
READ_LINE_3:
  CP $40                  ; Letters, quote, space, return, full stop and comma
  JR NC,READ_LINE_4       ; are kept; anything else is ignored
  CP $22                  ;
  JR Z,READ_LINE_4        ;
  CP $20                  ;
  JR Z,READ_LINE_4        ;
  CP $0D                  ;
  JR Z,READ_LINE_4        ;
  CP $2E                  ;
  JR Z,READ_LINE_4        ;
  CP $2C                  ;
  JR NZ,READ_LINE_KEY     ;
READ_LINE_4:
  LD (CAPITAL_NEXT),A     ; Remember the last key
  DEC B                   ; If there is room, echo it and put it in the line
  INC B                   ;
  JR Z,READ_LINE_5        ;
  CALL PRINT_CHAR         ;
  LD (HL),A               ;
  INC HL                  ;
  DEC B                   ;
READ_LINE_5:
  CP $0D                  ; Until return: then NZ, a line has been read
  JP NZ,READ_LINE_KEY     ;
  OR $01                  ;
  RET                     ;

; The cursor keys, pressed first on a line, are whole moves
;
; Used by the routine at READ_LINE.
;
; On an empty line, 7 is N, 6 is S, 8 is E and 5 -- or 0 -- is W: the letter
; and a carriage return go straight into the line, so a single key moves the
; player. Later in the line the same code from 0 or 5 is a backspace.
;
; I:A The key
; O:F NZ if it was one, with the line finished
ONE_KEY_MOVES:
  CP $09                  ; Which way? Anything else is an ordinary key
  JR Z,ONE_KEY_MOVES_2    ;
  CP $08                  ;
  JR Z,ONE_KEY_MOVES_3    ;
  CP $0A                  ;
  JR Z,ONE_KEY_MOVES_1    ;
  CP $5B                  ;
  RET NZ                  ;
  LD A,$4E                ; N: the letter and a carriage return, echoed
ONE_KEY_MOVES_0:
  LD (HL),A               ;
  INC HL                  ;
  CALL PRINT_CHAR         ;
  DEC B                   ;
  LD A,$0D                ;
  LD (HL),A               ;
  INC HL                  ;
  DEC B                   ;
  OR $01                  ;
  RET                     ;
ONE_KEY_MOVES_1:
  LD A,$53                ; S, E and W
  JR ONE_KEY_MOVES_0      ;
ONE_KEY_MOVES_2:
  LD A,$45                ;
  JR ONE_KEY_MOVES_0      ;
ONE_KEY_MOVES_3:
  LD A,$57                ;
  JR ONE_KEY_MOVES_0      ;

; @ on an empty line: the last command again
;
; Used by the routine at READ_LINE.
;
; Returns Z, no new line, so the old line in INPUT_LINE is run again; unless
; QUESTION_WAITING says otherwise, when the key is ignored.
REPEAT_LAST:
  LD A,(QUESTION_WAITING)
  AND A
  JP NZ,READ_LINE_KEY
  LD A,$08
  CALL PRINT_CHAR
  CALL PRINT_CHAR
  XOR A
  RET

; Backspace to the start of the line
;
; Used by the routines at READ_LINE and GET_KEY.
;
; What the key that gives $18 does.
RUB_OUT_LINE:
  BIT 7,B
  RET NZ
  LD A,$08
  CALL PRINT_CHAR
  INC B
  DEC HL
  JR RUB_OUT_LINE

; Turn the next word of INPUT_LINE into a token
;
; Used by the routine at START.
;
; A token is two bytes: the word's class in the top nibble -- bits 5-6 of its
; first two dictionary bytes, read together -- and its twelve-bit dictionary
; offset below that. A synonym comes out as the word it stands for, so GET
; SWORD is TAKE SWORD by the time anything reads it. $C0 ends the line; $D0 is
; a word not in the dictionary, and the main loop prints the complaint and
; never calls the parser.
;
; A typed word may be shortened or, within limits, lengthened. A candidate is
; taken if the two agree over the shorter length and the typed word is the
; shorter -- an abbreviation; if the typed word is the longer, only when the
; entry has at least four letters and no later candidate fits too. Tried: EXAM
; gives EXAMINE, INV gives INVENTORY, SWORDS gives SWORD, INT gives INTO
; because IN is too short to stretch, and EXAMINING is not a word at all, since
; its seventh letter disagrees.
;
; Watched on real sentences: VICIOUSLY ATTACK THE TROLL WITH THE SWORD comes
; out as adverb, verb, article, noun, preposition, article, noun, end; TAKE THE
; MAP AND THE KEY puts AND in class $A; and a closing quote gets a full stop
; token inserted before it by the main loop, so what is said to a character
; ends as a sentence.
;
; O:BC The token
TOKENISE:
  PUSH DE
TOKENISE_0:
  LD A,(HL)               ; Skip spaces
  INC HL                  ;
  CP $20                  ;
  JR Z,TOKENISE_0         ;
  DEC HL                  ;
  LD (VARIABLES),HL       ; Remember where the word starts, for the echo of an
                          ; unknown one
  CP $0D                  ; The end of the line: $C0
  JR Z,TOKENISE_5         ;
  CALL PUNCTUATION_TOKEN  ; A full stop, comma or quote is a token by itself
  JR Z,TOKENISE_7         ;
  CALL MATCH_WORD         ; Start on the dictionary bucket for its first
  JR NZ,TOKENISE_3        ; letter; none, and it is unknown
  PUSH HL                 ; Does this candidate agree with what was typed?
TOKENISE_1:
  CALL LETTERS_AGREE      ;
  JR Z,TOKENISE_4         ;
TOKENISE_2:
  CALL TRY_ENTRY          ; No: try the next in the bucket, until it runs out
  JR Z,TOKENISE_1         ;
  POP HL                  ;
TOKENISE_3:
  LD A,$D0                ; Not in the dictionary: $D0
  JR TOKENISE_6           ;
TOKENISE_4:
  LD A,(TYPED_LENGTH)     ; The typed word no longer than the entry: an
  LD B,A                  ; abbreviation, take it
  LD A,(ENTRY_LENGTH)     ;
  CP B                    ;
  JR NC,TOKENISE_9        ;
  CP $04                  ; Longer, and the entry under four letters: not this
  JR C,TOKENISE_2         ; one
  PUSH IX                 ; Longer, and the entry four or more: take it unless
  CALL TRY_SAME_ENTRY     ; the next candidate agrees too
  JR NZ,TOKENISE_8        ;
  CALL LETTERS_AGREE      ;
  JR NZ,TOKENISE_8        ;
  POP IX                  ;
  JR TOKENISE_2           ;
TOKENISE_5:
  LD A,$C0                ; No word: end of line, or unknown, or punctuation
TOKENISE_6:
  LD BC,$0000             ;
TOKENISE_7:
  POP DE                  ; B = class and top of the offset, C the low byte; A
  LD D,A                  ; = the class
  ADD A,B                 ;
  LD B,A                  ;
  LD A,D                  ;
  RET                     ;
TOKENISE_8:
  POP IX
TOKENISE_9:
  LD IX,(DICTIONARY_ENTRY) ; Walk to the end of the chosen entry...
  PUSH IX                  ;
  XOR A                    ;
TOKENISE_10:
  INC IX                   ;
  INC A                    ;
  BIT 7,(IX-$01)           ;
  JR Z,TOKENISE_10         ;
  CP $02                  ; ...by PRINT_WORD's rule for where a word ends
  JR Z,TOKENISE_10        ;
  CP $03                  ;
  JR NZ,TOKENISE_11       ;
  BIT 7,(IX-$02)          ;
  JR NZ,TOKENISE_10       ;
TOKENISE_11:
  BIT 6,(IX-$01)          ; A synonym: its link, turned into an address,
  JR Z,TOKENISE_12        ; replaces it
  LD L,(IX+$00)           ;
  LD H,(IX+$01)           ;
  LD DE,WORD_INDEX        ;
  ADD HL,DE               ;
  EX (SP),HL              ;
TOKENISE_12:
  POP HL                  ; The class: bits 5-6 of the first byte above bits
  LD A,(HL)               ; 5-6 of the second
  RLCA                    ;
  AND $C0                 ;
  LD B,A                  ;
  INC HL                  ;
  LD A,(HL)               ;
  RRCA                    ;
  AND $30                 ;
  ADD A,B                 ;
  DEC HL                  ; And the entry's offset from WORD_INDEX
  LD DE,$A000             ;
  ADD HL,DE               ;
  PUSH HL                 ;
  POP BC                  ;
  POP HL                  ;
  JR TOKENISE_7           ;

; A full stop, comma or quote is a token by itself
;
; Used by the routine at TOKENISE.
;
; And each takes the class of a word: a full stop $B0, the same as THEN, and a
; comma $A0, the same as AND -- so TAKE THE MAP. GO EAST and TAKE THE MAP, THE
; KEY parse exactly as their spelled-out forms. A quote is $90. Returns Z if it
; was one of the three.
PUNCTUATION_TOKEN:
  LD B,$B0                 ; Full stop: $B0, as THEN
  CP $2E                   ;
  JR Z,PUNCTUATION_TOKEN_0 ;
  LD B,$A0                 ; Comma: $A0, as AND
  CP $2C                   ;
  JR Z,PUNCTUATION_TOKEN_0 ;
  CP $22                  ; Quote: $90; anything else is not punctuation
  RET NZ                  ;
  LD B,$90                ;
PUNCTUATION_TOKEN_0:
  INC HL                  ; Step past it; A = the class, and no word
  LD A,B                  ;
  LD BC,$0000             ;
  RET                     ;

; Look a typed word up in the dictionary
;
; Used by the routine at TOKENISE.
;
; Copies the word from the input line, turning each letter into its 5-bit code
; with AND $1F -- which works because 'A' is $41 and the codes were chosen to
; be the low five bits of the ASCII -- and stops at the first character below
; $40, so punctuation and spaces end a word without being tested for.
;
; Then the index: the first letter doubled and added to WORD_INDEX gives the
; bucket's offset, and that added to WORD_INDEX again gives the first entry.
; From there each call unpacks one candidate -- the tokeniser comes back in at
; TRY_ENTRY for the next -- and the bucket is over when an entry's initial
; letter stops matching the one typed, which is its only end marker.
MATCH_WORD:
  LD DE,TYPED_LETTERS     ; Copy the typed word as 5-bit codes to
  LD B,$00                ; TYPED_LETTERS, up to the first character below $40
MATCH_WORD_0:
  LD A,(HL)               ;
  CP $40                  ;
  JR C,MATCH_WORD_1       ;
  AND $1F                 ;
  LD (DE),A               ;
  INC DE                  ;
  INC HL                  ;
  INC B                   ;
  JR MATCH_WORD_0         ;
MATCH_WORD_1:
  LD A,B                  ; Keep its length
  LD (TYPED_LENGTH),A     ;
  PUSH HL                 ; IX = the first word in the dictionary under its
  LD HL,(TYPED_LETTERS)   ; initial letter
  LD H,$00                ;
  LD DE,WORD_INDEX        ;
  ADD HL,HL               ;
  ADD HL,DE               ;
  LD E,(HL)               ;
  INC HL                  ;
  LD D,(HL)               ;
  LD IX,WORD_INDEX        ;
  ADD IX,DE               ;
  POP HL                  ;
; This entry point is used by the routine at TOKENISE.
TRY_ENTRY:
  LD (DICTIONARY_ENTRY),IX ; Remember which entry is being tried
; This entry point is used by the routine at TOKENISE.
TRY_SAME_ENTRY:
  LD A,(IX+$00)           ; Has the bucket run out? Its initial letter no
  AND $1F                 ; longer matches
  LD B,A                  ;
  LD A,(TYPED_LETTERS)    ;
  CP B                    ;
  RET NZ                  ;
  PUSH HL
  LD HL,ENTRY_LETTERS     ; Unpack this entry's letters to ENTRY_LETTERS, by
  LD BC,$0000             ; PRINT_WORD's rule for where a word ends
MATCH_WORD_2:
  LD A,(IX+$00)           ;
  AND $1F                 ;
  JR Z,MATCH_WORD_3       ;
  LD (HL),A               ;
  INC HL                  ;
  INC B                   ;
MATCH_WORD_3:
  INC IX                  ;
  INC C                   ;
  BIT 7,(IX-$01)          ;
  JR Z,MATCH_WORD_2       ;
  LD A,C                  ;
  CP $02                  ;
  JR Z,MATCH_WORD_2       ;
  CP $03                  ;
  JR NZ,MATCH_WORD_4      ;
  BIT 7,(IX-$02)          ;
  JR NZ,MATCH_WORD_2      ;
MATCH_WORD_4:
  POP HL                  ; Keep the entry's length
  LD A,B                  ;
  LD (ENTRY_LENGTH),A     ;
  BIT 6,(IX-$01)          ; A synonym: step over its two-byte link to the next
  RET Z                   ; entry
  INC IX                  ;
  INC IX                  ;
  XOR A                   ;
  RET                     ;
; A linear scan, not a binary search -- which is the other half of why the list
; only has to be grouped by initial letter and can be loosely ordered within a
; group, as BLOW before BLOOD and HELP before HEART are.

; Does the typed word agree with the candidate?
;
; Used by the routine at TOKENISE.
;
; Letter for letter, over the shorter of the two -- which is what lets TOKENISE
; take a typed word as an abbreviation.
;
; O:F Z if they agree
LETTERS_AGREE:
  LD A,(TYPED_LENGTH)     ; B = the shorter of the two lengths
  LD B,A                  ;
  LD A,(ENTRY_LENGTH)     ;
  CP B                    ;
  JR NC,LETTERS_AGREE_0   ;
  LD B,A                  ;
LETTERS_AGREE_0:
  LD HL,TYPED_LETTERS     ; Compare that many letters
  LD DE,ENTRY_LETTERS     ;
LETTERS_AGREE_1:
  LD A,(DE)               ;
  CP (HL)                 ;
  RET NZ                  ;
  INC DE                  ;
  INC HL                  ;
  DJNZ LETTERS_AGREE_1    ;
  RET

; Clear the screen: white border, black on white
;
; Used by the routine at START.
CLEAR_SCREEN:
  PUSH HL
  PUSH DE
  PUSH BC
  LD A,$07
  OUT ($FE),A
  LD HL,$4000
  LD DE,$4001
  LD BC,$1800
  LD (HL),$00
  LDIR
  LD BC,$0300
  LD (HL),$38
  LDIR
  POP BC
  POP DE
  POP HL
  RET

; The first turn's command
;
; "> LOOK" and a carriage return: START prints it as if it had been typed, and
; copies LOOK into INPUT_LINE, so the game opens with a description nobody
; asked for.
FIRST_COMMAND:
  DEFB $3E,$20            ; The prompt, "> "
LOOK_COMMAND:
  DEFB $4C,$4F,$4F,$4B,$0D ; LOOK, and a carriage return

; The command line being read
;
; What READ_LINE fills from the keyboard and the tokeniser reads, ended by a
; carriage return. The game also fills it itself: on the very first turn the
; main loop copies LOOK and a return in from LOOK_COMMAND and skips READ_LINE,
; which is how the opening description appears without anybody typing it.
; scripts/hobbit_drive.py uses the same way in.
INPUT_LINE:
  DEFB $20,$20,$20,$20,$20,$20,$20,$20
  DEFB $20,$20,$20,$20,$20,$20,$20,$20
  DEFB $20,$20,$20,$20,$20,$20,$20,$20
  DEFB $20,$20,$20,$20,$20,$20,$20,$20
  DEFB $20,$20,$20,$20,$20,$20,$20,$20
  DEFB $20,$20,$20,$20,$20,$20,$20,$20
  DEFB $20,$20,$20,$20,$20,$20,$20,$20
  DEFB $20,$20,$20,$20,$20,$20,$20,$20
  DEFB $20,$20,$20,$20,$20,$20,$20,$20
  DEFB $20,$20,$20,$20,$20,$20,$20,$20
  DEFB $20,$20,$20,$20,$20,$20,$20,$20
  DEFB $20,$20,$20,$20,$20,$20,$20,$20
  DEFB $20,$20,$20,$20,$20,$20,$20,$20
  DEFB $20,$20,$20,$20,$20,$20,$20,$20
  DEFB $20,$20,$20,$20,$20,$20,$20,$20
  DEFB $20,$20,$20,$20,$20,$20,$20,$20

; TOKENISE's working copy of the word being looked up
;
; MATCH_WORD copies the typed word here as 5-bit letter codes, and unpacks each
; dictionary entry it tries beside it, so that LETTERS_AGREE can compare the
; two a letter at a time.
TYPED_WORD:
  DEFB $0D                ; Not used
TYPED_LETTERS:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; The typed word, a letter to a byte
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
TYPED_LENGTH:
  DEFB $00                ; How many letters it has
ENTRY_LETTERS:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; The dictionary entry being tried,
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; unpacked the same way
ENTRY_LENGTH:
  DEFB $01                ; How many letters that has

; The tokens of the line being obeyed
;
; Two bytes each, up to the end-of-line token $C0. Cleared before each line.
TOKENS:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; What RUN_MESSAGE keeps while a message runs, and the narrating flag
;
; RUN_MESSAGE keeps A, DE and IX here and MC_END puts them back, so a message
; can be run from anywhere without upsetting its caller.
MESSAGE_A:
  DEFB $00                ; A
MESSAGE_DE:
  DEFB $00,$00            ; DE
NARRATING:
  DEFB $00                ; Set while NARRATE_ACTION tells the player what was
                          ; done, so that ARTICLE says THE throughout
MESSAGE_IX:
  DEFB $00,$00            ; IX

; Zero B bytes from HL
;
; Used by the routines at START, PARSE_COMMAND, CLEAR_FRAME, CLEAR_PHRASES and
; MATCH_PATTERN.
CLEAR_BYTES:
  XOR A                   ; Zero, B times over
CLEAR_BYTES_0:
  LD (HL),A               ;
  INC HL                  ;
  DJNZ CLEAR_BYTES_0      ;
  RET

; Find an action's entry in ACTION_PATTERNS
;
; Used by the routines at NARRATE_ACTION and WOULD_WORK.
;
; I:A The action code
; O:HL Its 8-byte pattern
PATTERN_OF:
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,ACTION_PATTERNS-$0008
  ADD HL,DE
  RET

; Gather an action pattern's flags
;
; Used by the routines at NARRATE_ACTION, WOULD_WORK and ASSIGN_PHRASES.
;
; The top four bits of each of the pattern's four word references are flags,
; not part of the word. They are gathered in pairs: FLAGS_FIRST_WORDS from the
; first two references, FLAGS_LAST_WORDS from the last two. What is known of
; them is in PATTERN_OPTIONS, NARRATE_ACTION and WOULD_WORK: bits 2 and 3 of
; FLAGS_FIRST_WORDS are the second and first objects, bit 4 not narrated, bit 7
; an object that is a place, bit 0 PATTERN_OPTION; bit 6 of FLAGS_LAST_WORDS
; needs light.
;
; I:IX The pattern
PATTERN_FLAGS:
  LD A,(IX+$05)           ; FLAGS_LAST_WORDS = the fourth reference's flags,
  RRCA                    ; with the third's below them
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  AND $0F                 ;
  LD C,A                  ;
  LD A,(IX+$07)           ;
  AND $F0                 ;
  ADD A,C                 ;
  LD (FLAGS_LAST_WORDS),A ;
  LD A,(IX+$01)            ; FLAGS_FIRST_WORDS = the second reference's flags,
  RRCA                     ; with the first's below them
  RRCA                     ;
  RRCA                     ;
  RRCA                     ;
  AND $0F                  ;
  LD C,A                   ;
  LD A,(IX+$03)            ;
  AND $F0                  ;
  ADD A,C                  ;
  LD (FLAGS_FIRST_WORDS),A ;
  RET

; Narrate the action as refused, unless IS_ORDER says not to
;
; Used by the routine at TARGET_TROUBLE.
NARRATE_REFUSAL:
  XOR A
  LD (SUCCEEDED),A
  INC A
  LD (DOING_IT),A
  LD A,(IS_ORDER)
  AND A
  CALL Z,NARRATE_ACTION
  XOR A
  RET

; Tell the player what was done, as a sentence
;
; Used by the routines at NARRATE_REFUSAL, OBEY, ACTOR_TRIES and REFUSE.
;
; Built from the action's pattern: who did it, "cannot" if it was refused, the
; verb -- or GO and the direction, for a move, or GO SOMEWHERE in the dark,
; when the player cannot see which way -- then the first object after its
; particle, and the second after its preposition, and a full stop. So what the
; other characters are seen to do is told by the same code, from the same
; patterns, as the player's own actions.
;
; A pattern with bit 4 of FLAGS_FIRST_WORDS set is not narrated at all: that is
; LOOK and INVENTORY, the only two, which change nothing anyone could see.
NARRATE_ACTION:
  LD A,$01                ; Narrating
  LD (NARRATING),A        ;
  XOR A                   ; Not yet worked out
  LD (NOUN_ONLY),A        ;
  PUSH IY
  PUSH BC
  LD A,(SUCCEEDED)        ; INPUT_STYLE = 1 if the action was refused
  LD B,A                  ;
  AND A                   ;
  LD A,$01                ;
  JR Z,NARRATE_ACTION_0   ;
  XOR A                   ;
NARRATE_ACTION_0:
  LD (INPUT_STYLE),A      ;
  PUSH IX
  PUSH HL
  PUSH DE
  LD A,(ACTION)           ; IX = the action's pattern
  CALL PATTERN_OF         ;
  PUSH HL                 ;
  POP IX                  ;
  XOR A                   ; Done, and by the player: a new line first
  CP B                    ;
  JR Z,NARRATE_ACTION_1   ;
  LD A,(ACTING)           ;
  AND A                   ;
  CALL Z,NEW_LINE         ;
NARRATE_ACTION_1:
  CALL PATTERN_FLAGS      ; A pattern that is not narrated: nothing
  BIT 4,A                 ;
  LD C,A                  ;
  JP NZ,NARRATE_ACTION_6  ;
  CALL PRINT_ACTOR        ; Who did it
  LD DE,$00EE             ; Refused: "cannot"
  XOR A                   ;
  CP B                    ;
  CALL Z,PRINT_WORD_DE    ;
  PUSH HL                 ; The pattern's last word -- GO, for a move
  LD DE,$0006             ;
  ADD HL,DE               ;
  CALL PRINT_WORD         ;
  CALL TOO_DARK           ; In the dark, a move goes "somewhere"
  POP HL                  ;
  JR NC,NARRATE_ACTION_2  ;
  LD A,(ACTION)           ;
  CP $0B                  ;
  JR NC,NARRATE_ACTION_2  ;
  LD DE,$0AEA             ;
  INC HL                  ;
  INC HL                  ;
  CALL PRINT_WORD_DE      ;
  JR NARRATE_ACTION_3     ;
NARRATE_ACTION_2:
  CALL PRINT_WORD         ; Otherwise the verb, or the direction
NARRATE_ACTION_3:
  BIT 3,C                 ; The first object, after its particle, if the
  JR Z,NARRATE_ACTION_4   ; pattern has one (bit 3)
  BIT 5,C                 ;
  CALL NZ,PRINT_WORD      ;
  LD A,(FLAGS_LAST_WORDS) ;
  BIT 7,A                 ;
  CALL NZ,PRINT_WORD      ;
  CALL PRINT_TARGET       ;
NARRATE_ACTION_4:
  LD A,(INSTRUMENT)       ; The second object, after its preposition, if it has
  CP $FF                  ; one (bit 2)
  JR Z,NARRATE_ACTION_5   ;
  BIT 2,C                 ;
  JR Z,NARRATE_ACTION_5   ;
  BIT 5,C                 ;
  CALL Z,PRINT_WORD       ;
  LD A,(FLAGS_LAST_WORDS) ;
  BIT 7,A                 ;
  CALL Z,PRINT_WORD       ;
  CALL PRINT_INSTRUMENT   ;
NARRATE_ACTION_5:
  LD A,$2E                ; A full stop, and a new line
  CALL PRINT_CHAR         ;
  CALL NEW_LINE           ;
NARRATE_ACTION_6:
  XOR A                   ; No longer narrating
  LD (NARRATING),A        ;
  POP DE
  POP HL
  POP IX
  POP BC
  POP IY
  RET

; HL = where location A's name is, in its record
;
; Used by the routines at MC_INSTRUMENT and NAME_OF_NUMBER.
ROOM_NAME_AT:
  PUSH IX
  CALL GET_ROOM
  PUSH IX
  POP HL
  INC HL
  INC HL
  POP IX
  RET

; HL = where object A's name is, in its record
;
; Used by the routines at MC_INSTRUMENT, NAME_OF_NUMBER and NO_INSTRUMENT.
OBJECT_NAME_AT:
  PUSH DE
  PUSH IX
  CALL GET_OBJECT
  PUSH IX
  POP HL
  LD DE,$0008
  ADD HL,DE
  POP IX
  POP DE
  RET

; Does a typed name fit an object's name?
;
; Used by the routines at MATCH_PATTERN, FIND_NAMED_OBJECT and ROOM_BY_NAME.
;
; The noun has to match; the adjectives need not be typed at all, and are
; accepted in either order -- it tries them as given, then swapped -- but one
; that does not belong rules the object out. Called directly on the small
; curious key: KEY, CURIOUS KEY, SMALL CURIOUS KEY and CURIOUS SMALL KEY all
; match; LARGE KEY, SMALL LARGE KEY and MAP do not.
;
; I:HL The typed name
; I:IY The object's name
; O:F Z if it fits
NAME_MATCHES:
  PUSH DE
  PUSH HL
  PUSH IY
  CALL WORD_MATCHES       ; The nouns must match, or it is not this object
  JR NZ,NAME_MATCHES_1    ;
  LD A,$01                ; Note that the noun matched
  LD (NAME_FAILED),A      ;
  CALL WORD_MATCHES       ; Adjectives in the order typed? Then it fits, A = 0
  JR NZ,NAME_MATCHES_0    ;
  CALL WORD_MATCHES       ;
  LD A,$00                ;
  JR Z,NAME_MATCHES_1     ;
NAME_MATCHES_0:
  POP IY                  ; Otherwise start again from the beginning of both
  POP HL                  ; names...
  PUSH HL                 ;
  PUSH IY                 ;
  LD DE,$0004             ; ...compare the first typed adjective with the
  ADD IY,DE               ; object's second...
  INC HL                  ;
  INC HL                  ;
  CALL WORD_MATCHES       ;
  JR NZ,NAME_MATCHES_1    ;
  LD DE,$FFFC             ; ...and the second typed adjective with the object's
  ADD IY,DE               ; first: A = 1 if that fits
  CALL WORD_MATCHES       ;
  LD A,$01                ;
NAME_MATCHES_1:
  POP IY
  POP HL
  POP DE
  RET

; Does a typed word fit a word of a name?
;
; Used by the routine at NAME_MATCHES.
;
; A word that was not typed -- zero -- fits anything. Otherwise only the
; twelve-bit dictionary offset is compared, not the flag nibble above it. Both
; pointers move on two bytes either way.
WORD_MATCHES:
  PUSH HL
  LD A,(HL)               ; Not typed at all? Then it fits anything
  INC HL                  ;
  OR (HL)                 ;
  JR Z,WORD_MATCHES_0     ;
  LD A,(IY+$01)           ; Same top half of the twelve-bit offset, ignoring
  XOR (HL)                ; the flag nibble...
  AND $0F                 ;
  JR NZ,WORD_MATCHES_0    ;
  DEC HL                  ; ...and the same low byte
  LD A,(HL)               ;
  CP (IY+$00)             ;
WORD_MATCHES_0:
  POP HL                  ; On to the next word of both names either way
  INC HL                  ;
  INC HL                  ;
  INC IY                  ;
  INC IY                  ;
  RET                     ;

; Wait for a key, or type WAIT when none comes
;
; Used by the routine at READ_LINE.
;
; Counts down from PATIENCE while it scans the keyboard, and returns the first
; new key. If the count runs out first it does something rather nice: it clears
; the line, copies the four letters at WAIT_TEXT -- WAIT -- into it, prints
; them, and returns a carriage return as though the player had pressed ENTER.
; So "time passes" is the game typing a command on your behalf, and the WAIT
; lines on screen that nobody typed are exactly that.
;
; The keyboard scan reports only changes. A driver that stops the game with
; ENTER held and presses it again at the next prompt is not heard, because the
; release was never seen; hobbit_drive.py lets it scan with nothing held first.
;
; O:A The key
GET_KEY:
  PUSH HL
  LD HL,(PATIENCE)        ; Scan until a new key, or until the patience in
GET_KEY_0:
  CALL SCAN_KEYBOARD      ; PATIENCE runs out
  AND A                   ;
  JR NZ,GET_KEY_2         ;
  DEC HL                  ;
  LD A,H                  ;
  OR L                    ;
  JR NZ,GET_KEY_0         ;
  POP HL                  ; Out of patience: clear the line...
  PUSH HL                 ;
  CALL RUB_OUT_LINE       ;
  LD DE,WAIT_TEXT         ; ...type WAIT into it, printing each letter as a
  LD B,$04                ; player would...
GET_KEY_1:
  LD A,(DE)               ;
  LD (HL),A               ;
  INC HL                  ;
  INC DE                  ;
  CALL PRINT_CHAR         ;
  DJNZ GET_KEY_1          ;
  EX (SP),HL              ; ...and return as if ENTER had been pressed after it
  LD B,$7C                ;
  LD A,$0D                ;
  LD HL,$FE0C             ;
GET_KEY_2:
  PUSH AF                 ; The next wait is what was left of this one plus
  XOR A                   ; 500, at most 3000; after a timeout it is 3000 again
  LD DE,$01F4             ;
  ADC HL,DE               ;
  LD DE,$0BB8             ;
  JR C,GET_KEY_3          ;
  CALL COMPARE_HL_DE      ;
  JR C,GET_KEY_4          ;
GET_KEY_3:
  EX DE,HL                ;
GET_KEY_4:
  LD (PATIENCE),HL        ;
  POP AF
  POP HL
  RET

; Compare HL with DE: Z if equal
;
; Used by the routine at GET_KEY.
COMPARE_HL_DE:
  LD A,H
  SUB D
  RET NZ
  LD A,L
  SUB E
  RET

; What GET_KEY types when the player does not
;
; Four letters, WAIT, and no terminator: GET_KEY copies exactly four.
WAIT_TEXT:
  DEFM "WAIT"

; A handler for each message control code, $00 to $16
;
; Twenty-three handlers. Code $0D, a new line, is printed by the same routine
; as a literal character, and four codes share the one at MC_NOTHING -- which
; is the XOR A; RET that ends code $02's own handler. Codes $02 and $0B are the
; only ones that take a byte after them. The codes that print a name, IS or
; ARE, and HIS or YOUR are what let one message serve the whole cast: the same
; bytes print YOU ARE NOT CARRYING IT for the player and GANDALF IS NOT
; CARRYING IT for Gandalf.
CONTROL_CODES:
  DEFW MC_PUSHED_OBJECT
  DEFW MC_PUSHED_WORD
  DEFW MC_JUMP
  DEFW MC_INSTRUMENT_NOUN
  DEFW MC_PUSHED_WITH_ARTICLE
  DEFW MC_NOTHING
  DEFW MC_ACTOR
  DEFW MC_TARGET
  DEFW MC_BACKSPACE
  DEFW MC_INSTRUMENT
  DEFW MC_NOTHING
  DEFW MC_SUBMESSAGE
  DEFW MC_ACTOR_HIS
  DEFW PRINT_LITERAL
  DEFW MC_TARGET_HIS
  DEFW MC_NOTHING
  DEFW MC_ACTOR_IS
  DEFW MC_TARGET_IS
  DEFW MC_NOTHING
  DEFW MC_PUSHED_IS
  DEFW MC_END_LINE
  DEFW MC_END_STOP
  DEFW MC_END

; Print a literal character from a message
;
; Used by the routine at RUN_MESSAGE.
;
; Also control code $0D, a new line, which is why that code has no handler of
; its own.
PRINT_LITERAL:
  CALL PRINT_CHAR         ; Print it
  CP $0D                  ; A new line clears CAPITAL_NEXT
  RET NZ                  ;
  XOR A                   ;
  LD (CAPITAL_NEXT),A     ;
  RET

; "i cannot do that."
;
; Used by the routines at DO_PUT_IN, INTO_THE_RIVER, DO_ACTION and
; ROCK_DOOR_KEY.
CANNOT_DO:
  LD HL,MSG_I_CANNOT_DO_THAT
  JR RUN_MESSAGE_HL

; Print a message
;
; Used by the routines at MATCH_PATTERN, ASK_WHICH and TARGET_TROUBLE.
;
; Nearly everything the game says goes through here, as a compact bytecode
; rather than text. A byte with bit 7 set starts a two-byte word reference,
; high byte first: twelve bits of offset into the dictionary and a flag nibble,
; of which 2, 3 and 6 end the message. A byte from $60 to $7F is one of the
; COMMON_WORDS; from $20 to $5F, a literal character; below $20, a control
; code, dispatched through CONTROL_CODES -- below $14 as a subroutine that
; returns to the message, from $14 up as the end of it.
;
; Checked against the screen, not only read: location 4's description decodes
; to exactly the words the game printed on arriving there, and so does Bag
; End's. The v1.0 disassembly credited in build_hobbit.py describes the same
; bytecode, and pointed at where to look.
;
; The messages are stored end to end from MSG_BUT_FALL_AND_HIT, straight after
; COMMON_WORDS, and a few are entered part-way through another: four at an
; element boundary, sharing its tail -- the last is the two banks of the black
; river, one description entered at two places -- and one on the second byte of
; the word that ends the message before, which it reads as a control code.
;
; I:HL The message
RUN_MESSAGE:
  LD A,(IS_ORDER)         ; Inside a quotation, clear DOING_IT first
  AND A                   ;
  JR Z,RUN_MESSAGE_HL     ;
  XOR A                   ;
  LD (DOING_IT),A         ;
; This entry point is used by the routines at START, CANNOT_DO,
; QUOTE_LEFT_OPEN, DO_HELP, SHOW_SCORE, LOAD_BLOCK, DO_SAVE, VERIFY_BLOCK,
; DO_LOOK, MUST_CARRY, DO_DROP, DO_TAKE_OUT, CAN_LIFT, DO_TAKE, MOVE,
; LOOK_THROUGH, DO_FOLLOW, DO_TALK, DO_SHOOT, PLAYER_DIES, DO_INVENTORY,
; DO_ATTACK, DO_PUT_IN, DO_EAT, DO_GIVE, DO_EXAMINE, INTO_THE_RIVER, DO_ACTION,
; DESCRIBE_LOCATION, DESCRIPTION_OR_NAME, CARRIED_BY_ANOTHER, NARRATE_LINE,
; CHARACTERS_ACT, ANNOUNCE_ARRIVAL, EMPTY_OUT, YOU_SEE, LIST_HERE,
; CONTENTS_INTRO, PLACED_WORD, EXITS_THROUGH, VISIBLE_EXITS, SAY_STATE, SAYS,
; DO_TIE, DO_UNTIE, SWIM_BLACK_RIVER, NO_KEY_FITS, WEB_BROKEN, TAKE_OFF_RING,
; GOBLIN_RETURNS, DO_CLIMB_INTO, BARREL_REACHES_LAKE, TRAP_DOOR_OPEN_CLOSE,
; DRAGON_FOLLOWS, DRAGON_HUNTS, MAGIC_DOOR_EXAMINED, THORIN_KILLED,
; WINDOW_OPEN_CLOSE, WINDOW_OTHERS, SINKING_IN_BOG, THROW_ROPE_ACROSS,
; PULL_ROPE, GOLLUM_HEARS_ANSWER, TROLLS_TURN_TO_STONE, CHECK_WON,
; JUMP_ONTO_BARREL, SIDE_DOOR_VANISHES, SIDE_DOOR_APPEARS, AT_MAGIC_DOOR,
; WEB_SMOTHERS, EYES_WARNING, EYES_STING and AT_FOREST_RIVER.
RUN_MESSAGE_HL:
  LD (MESSAGE_DE),DE      ; Keep DE, IX and A to put back at the end
  LD (MESSAGE_IX),IX      ;
  LD (MESSAGE_A),A        ;
  LD A,(DOING_IT)         ; Clear SUCCEEDED unless DOING_IT is set
  AND A                   ;
  JR NZ,RUN_SUBMESSAGE    ;
  LD (SUCCEEDED),A        ;
; This entry point is used by the routine at MC_SUBMESSAGE.
RUN_SUBMESSAGE:
  PUSH HL                 ; IX walks the message
  POP IX                  ;
RUN_MESSAGE_0:
  LD A,(IX+$00)           ; Bit 7 set: a word reference
  BIT 7,A                 ;
  JR Z,RUN_MESSAGE_2      ;
  AND $7F                 ; DE = the reference: flags and offset from the first
  LD D,A                  ; byte, low byte from the second
  LD E,(IX+$01)           ;
  INC IX                  ;
  AND $F0                 ; Ending flags 3, 2 or 6: print it and end the
  CP $30                  ; message
  JR Z,WORD_AND_END       ;
  CP $20                  ;
  JR Z,WORD_AND_END       ;
  CP $60                  ;
  JR Z,WORD_AND_END       ;
; This entry point is used by the routine at COMMON_WORD.
MESSAGE_WORD:
  CALL PRINT_WORD_DE      ; Print it, and on to the next byte
RUN_MESSAGE_1:
  INC IX                  ;
  JR RUN_MESSAGE_0        ;
RUN_MESSAGE_2:
  CP $20                  ; $60 and up: one of the COMMON_WORDS
  JR C,RUN_MESSAGE_3      ;
  CP $60                  ;
  JP NC,COMMON_WORD       ;
  CALL PRINT_LITERAL      ; $20-$5F: print it as it is
  JR RUN_MESSAGE_1        ;
RUN_MESSAGE_3:
  PUSH DE                 ; Below $20: HL = its handler from CONTROL_CODES
  LD E,A                  ;
  LD D,$00                ;
  LD HL,CONTROL_CODES     ;
  ADD HL,DE               ;
  ADD HL,DE               ;
  LD E,(HL)               ;
  INC HL                  ;
  LD D,(HL)               ;
  EX DE,HL                ;
  POP DE                  ;
  CP $14                  ; $14 and up ends the message: jump to it
  JR NC,RUN_MESSAGE_4     ;
  CALL RUN_MESSAGE_4      ; Below $14: call it; Z to carry on, NZ to print the
  JR Z,RUN_MESSAGE_1      ; word it left in DE
  JR MESSAGE_WORD         ;
RUN_MESSAGE_4:
  JP (HL)

; Message control code $14: end the message with a new line
MC_END_LINE:
  LD D,$60                ; End as flag nibble 6 would: a new line
  JR END_AS_FLAGGED       ;

; Message control code $15: end the message with a full stop and a new line
MC_END_STOP:
  LD D,$30                ; End as flag nibble 3 would: a full stop and a new
  JR END_AS_FLAGGED       ; line

; Print a word, then end the sentence or the line as its flags say
;
; Used by the routine at RUN_MESSAGE.
;
; One of RUN_MESSAGE's ways of ending: bit 6 of the reference's flags a new
; line only, bit 4 a full stop and a new line.
WORD_AND_END:
  CALL PRINT_WORD_DE
; This entry point is used by the routines at MC_END_LINE and MC_END_STOP.
END_AS_FLAGGED:
  LD A,$2E
  BIT 6,D
  JR NZ,WORD_AND_END_0
  BIT 4,D
  CALL NZ,PRINT_CHAR
  BIT 4,D
WORD_AND_END_0:
  CALL NZ,NEW_LINE

; Message control code $16: end the message
MC_END:
  LD DE,(MESSAGE_DE)      ; End here: put back the DE, IX and A that
  LD IX,(MESSAGE_IX)      ; RUN_MESSAGE kept
  LD A,(MESSAGE_A)        ;
  RET                     ;

; Message control code $00: print the object whose record the caller pushed
MC_PUSHED_OBJECT:
  XOR A                   ; No article
  LD (NOUN_ONLY),A        ;
  POP DE                  ; Dig the caller's pushed record out from under the
  POP HL                  ; return addresses
  EX (SP),HL              ;
  PUSH DE                 ;
  LD A,H                  ; Print it, unless it is zero
  OR L                    ;
  CALL NZ,PRINT_NAME_AT   ;
  XOR A
  RET

; Message control code $01: print the word the caller pushed
MC_PUSHED_WORD:
  POP DE                  ; Dig the caller's pushed word out into DE
  POP HL                  ;
  EX (SP),HL              ;
  PUSH DE                 ;
  EX DE,HL                ;
  OR $01                  ; NZ: print it
  RET                     ;

; Message control code $02: jump within the message by the signed byte that
; follows
;
; Checked, not only read: confirmed by running location 66's description, which
; prints the west bank and skips the east.
MC_JUMP:
  LD E,(IX+$01)           ; DE = the signed byte after the code
  LD D,$00                ;
  BIT 7,E                 ;
  JR Z,MC_JUMP_0          ;
  LD D,$FF                ;
MC_JUMP_0:
  ADD IX,DE               ; Jump by it -- and fall into MC_NOTHING, whose XOR
                          ; A; RET is this handler's own end

; Message control code $05, $0A, $0F and $12: do nothing
MC_NOTHING:
  XOR A                   ; Z: carry on with the message
  RET                     ;

; Message control code $03: the noun of the instrument in the current command
MC_INSTRUMENT_NOUN:
  LD DE,(WEAPON_NAME)     ; DE = the instrument's noun, from WEAPON_NAME; NZ to
  OR $01                  ; print it
  RET                     ;

; Message control code $04: the pushed word with a or the in front
MC_PUSHED_WITH_ARTICLE:
  POP DE                  ; Dig the caller's pushed word out into DE
  POP HL                  ;
  EX (SP),HL              ;
  PUSH DE                 ;
  EX DE,HL                ;
  LD A,$01                ; With an article
  LD (NOUN_ONLY),A        ;
  CALL PRINT_NOUN         ; Print it
  XOR A
  RET

; Message control code $06: the actor's name, or YOU
;
; Checked, not only read: confirmed by running a message with it as the player
; and as Gandalf.
MC_ACTOR:
  XOR A                   ; No article
  LD (NOUN_ONLY),A        ;
; This entry point is used by the routine at NARRATE_ACTION.
PRINT_ACTOR:
  LD A,(ACTING)           ; Print whoever the sentence is about: a name, or YOU
  CALL PRINT_SUBJECT      ;
  XOR A
  RET

; Message control code $07: the target, with its article
MC_TARGET:
  LD A,$01                ; With an article
  LD (NOUN_ONLY),A        ;
; This entry point is used by the routine at NARRATE_ACTION.
PRINT_TARGET:
  LD A,(TARGET_IS_PLACE)  ; The target, found one of two ways by
  AND A                   ; TARGET_IS_PLACE; printed as MC_INSTRUMENT does
  LD A,(TARGET)           ;
  JR PRINT_THING_OR_PLACE ;

; Message control code $08: a backspace, joining the next word to the last
MC_BACKSPACE:
  CALL PRINT_CHAR         ; A still holds the code, 8, which is the backspace
                          ; character: print it
  XOR A
  RET

; Message control code $09: the instrument, with its article
MC_INSTRUMENT:
  LD A,$01                ; With an article
  LD (NOUN_ONLY),A        ;
; This entry point is used by the routine at NARRATE_ACTION.
PRINT_INSTRUMENT:
  LD A,(INSTRUMENT_IS_PLACE) ; The instrument, found one of two ways by
  AND A                      ; INSTRUMENT_IS_PLACE...
  LD A,(INSTRUMENT)          ;
; This entry point is used by the routine at MC_TARGET.
PRINT_THING_OR_PLACE:
  JR Z,PRINT_THING        ; ...one routine or the other giving its record...
  PUSH HL                 ;
  CALL ROOM_NAME_AT       ;
  JR MC_INSTRUMENT_0      ;
; This entry point is used by the routine at PRINT_SUBJECT.
PRINT_THING:
  PUSH HL
  CALL OBJECT_NAME_AT     ; }
MC_INSTRUMENT_0:
  CALL PRINT_NAME_AT      ; ...which is printed
  POP HL
  XOR A
  RET

; Message control code $0B: run the sub-message the signed byte that follows
; points at
MC_SUBMESSAGE:
  INC IX                  ; Step past the offset byte
  PUSH IX                 ; HL = here plus the signed offset
  POP HL                  ;
  PUSH HL                 ;
  LD E,(IX+$00)           ;
  LD D,$00                ;
  BIT 7,E                 ;
  JR Z,MC_SUBMESSAGE_0    ;
  LD D,$FF                ;
MC_SUBMESSAGE_0:
  ADD HL,DE               ;
  CALL RUN_SUBMESSAGE     ; Run that sub-message, then carry on with this one
  POP IX
  XOR A
  RET

; Message control code $0C: HIS, or YOUR for the player
;
; Checked, not only read: confirmed the same way: YOUR for the player, HIS for
; anyone else.
MC_ACTOR_HIS:
  LD A,(ACTING)           ; The actor
; This entry point is used by the routine at MC_TARGET_HIS.
HIS_OR_YOUR:
  LD DE,$0990             ; Anyone but the player: HIS
  AND A                   ;
  RET NZ                  ;
  LD DE,$0BEA             ; The player: YOUR
  OR $01                  ;
  RET                     ;

; Message control code $0E: HIS or YOUR for the target
MC_TARGET_HIS:
  LD A,(TARGET)           ; The target instead of the actor
  JR HIS_OR_YOUR          ;

; Message control code $10: the actor's name and IS, or YOU ARE
;
; Checked, not only read: confirmed the same way: YOU ARE, GANDALF IS, THORIN
; IS, from one message.
MC_ACTOR_IS:
  LD A,(ACTING)           ; The actor, with no article
  EX AF,AF'               ;
  XOR A                   ;
; This entry point is used by the routine at MC_TARGET_IS.
NAME_AND_IS:
  LD (NOUN_ONLY),A
  EX AF,AF'               ; }
  PUSH AF                 ; Print the name
  CALL PRINT_SUBJECT      ;
  POP AF                  ;
  AND A                   ; Anyone but the player: IS
  LD DE,$039B             ;
  RET NZ                  ;
  LD DE,$0065             ; The player: ARE
  OR $01                  ;
  RET                     ;

; Message control code $11: the same for the target
MC_TARGET_IS:
  LD A,(TARGET)           ; The target, with an article
; This entry point is used by the routine at MC_PUSHED_IS.
NAME_WITH_ARTICLE_IS:
  EX AF,AF'
  LD A,$01
  JR NAME_AND_IS          ; }

; Message control code $13: the same for a pushed object
MC_PUSHED_IS:
  POP DE                  ; An object the caller pushed
  POP HL                  ;
  POP AF                  ;
  PUSH HL                 ;
  PUSH DE                 ;
  JR NAME_WITH_ARTICLE_IS ;

; Print the object name whose six bytes are at HL
;
; Used by the routines at MC_PUSHED_OBJECT and MC_INSTRUMENT.
PRINT_NAME_AT:
  PUSH IY
  PUSH HL
  POP IY
  CALL PRINT_NAME
  POP IY
  RET

; Print the article a noun takes
;
; Used by the routines at PRINT_NOUN and PRINT_NAME.
;
; The top bits of the noun's word reference choose it. Bit 7 marks a proper
; name, which takes none and is capitalised instead -- except YOU, the word at
; $07A8, which is left in lower case. Otherwise bits 4 to 6 pick from ARTICLES:
; THE, A, AN or SOME -- or, in the input window or while an action is being
; narrated, THE for everything but SOME.
;
; I:DE The noun's word reference
ARTICLE:
  BIT 7,D                 ; A proper name?
  JR Z,ARTICLE_1          ;
  LD A,E                  ; YOU: no capital
  LD HL,$07A8             ;
  CP L                    ;
  JR NZ,ARTICLE_0         ;
  LD A,D                  ;
  AND $0F                 ;
  CP H                    ;
  RET Z                   ;
ARTICLE_0:
  LD A,$01                ; Otherwise the next letter is a capital
  LD (CAPITAL_NEXT),A     ;
  RET                     ;
ARTICLE_1:
  LD HL,ARTICLES           ; THE, A, AN or SOME -- or THE throughout when
  LD A,(INPUT_STYLE)       ; narrating
  LD E,A                   ;
  LD A,(NARRATING)         ;
  OR E                     ;
  JR Z,ARTICLE_2           ;
  LD HL,ARTICLES_NARRATING ;
ARTICLE_2:
  LD A,D                  ; Print the one its bits choose
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  AND $1E                 ;
  PUSH DE                 ;
  LD E,A                  ;
  LD D,$00                ;
  ADD HL,DE               ;
  LD E,(HL)               ;
  INC HL                  ;
  LD D,(HL)               ;
  CALL PRINT_WORD_DE      ;
  POP DE                  ;
  RET                     ;

; Print a noun, with its article in the one case PRINT_NAME leaves it out
;
; Used by the routines at MC_PUSHED_WITH_ARTICLE and PRINT_NAME.
;
; PRINT_NAME prints the article itself, except when NOUN_ONLY asks for the noun
; alone; then it is done here. The flag bits are taken off the reference first.
;
; I:DE The noun's word reference
PRINT_NOUN:
  PUSH DE
  LD A,(NOUN_ONLY)
  AND A
  CALL NZ,ARTICLE
  POP DE
  LD A,D
  AND $0F
  LD D,A
  JP PRINT_WORD_DE

; Print who a sentence is about: object A, or "someone" for $FF
;
; Used by the routines at MC_ACTOR and MC_ACTOR_IS.
;
; $FF is what the subject is when the player cannot see who did it.
PRINT_SUBJECT:
  CP $FF
  JP NZ,PRINT_THING
  LD DE,$0AE3
  JP PRINT_WORD_DE

; A message's byte $60-$7F: one of the 32 COMMON_WORDS
;
; Used by the routine at RUN_MESSAGE.
COMMON_WORD:
  SUB $60
  LD E,A
  LD D,$00
  LD HL,COMMON_WORDS
  ADD HL,DE
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD A,(HL)
  ADD A,$50
  LD D,A
  JP MESSAGE_WORD

; Where PRINT_WORD assembles a word's letters before printing
;
; Twenty bytes. What is in them in the loaded game is only what was left there,
; which is why it reads like code.
WORD_BUFFER:
  DEFB $F1,$78,$36,$04,$CD,$30,$79,$36
  DEFB $36,$23,$73,$23,$70,$18,$1C,$FE
  DEFB $0B,$20,$1B,$CB

; Expand a packed word into letters
;
; Used by the routine at NARRATE_ACTION.
;
; Takes a 2-byte word reference and writes the letters to a buffer at
; WORD_BUFFER -- which the disassembly shows as a data block and a message,
; because it holds whatever was last expanded into it rather than anything the
; game was built with.
;
; The reference: the low 12 bits are an offset from WORD_INDEX to the entry,
; and the top 4 bits are flags the tail of the routine acts on. Zero means
; print nothing. The letters come back out as lowercase ASCII by adding $60 to
; each 5-bit code.
;
; The loop is where the game states the format's awkward rule itself. It stops
; on a byte with bit 7 set, except that if only two letters have been emitted
; it carries on regardless -- because the top bits of the first two bytes are
; the word's part of speech, so bit 7 there is not a terminator. At exactly
; three letters it goes back and re-tests the second byte's bit 7 before
; deciding. A decoder that simply stops at the first bit 7 splits ATTACK into
; AT and TACK.
;
; I:HL The word reference to read, or use the entry at PRINT_WORD_DE with it
;      already in DE
PRINT_WORD:
  LD E,(HL)               ; DE = the reference at HL
  INC HL                  ;
  LD A,(HL)               ;
  INC HL                  ;
  AND $0F                 ;
  LD D,A                  ;
; This entry point is used by the routines at NARRATE_ACTION, RUN_MESSAGE,
; WORD_AND_END, ARTICLE, PRINT_NOUN, PRINT_SUBJECT, DO_LOOK, PRINT_NAME,
; EXITS_THROUGH, VISIBLE_EXITS and GOBLIN_RETURNS.
PRINT_WORD_DE:
  LD A,D                  ; Zero prints nothing
  AND $0F                 ;
  OR E                    ;
  RET Z                   ;
  PUSH HL
  PUSH BC
  PUSH DE
  LD C,D                  ; C = the flag nibble, for later
  LD A,D                  ; HL = the dictionary entry
  AND $0F                 ;
  LD D,A                  ;
  LD HL,WORD_INDEX        ;
  ADD HL,DE               ;
  LD DE,WORD_BUFFER       ; The letters go into the buffer at WORD_BUFFER
  PUSH HL                 ;
  LD B,$00                ;
PRINT_WORD_0:
  LD A,(HL)               ; Each letter as lower-case ASCII, counted in B
  AND $1F                 ;
  JR Z,PRINT_WORD_1       ;
  INC B                   ;
  ADD A,$60               ;
  LD (DE),A               ;
  INC DE                  ;
  BIT 7,(HL)              ; Bit 7 clear: more letters to come
  INC HL                  ;
  JR Z,PRINT_WORD_0       ;
  LD A,B                  ; Bit 7 set after only two letters is part of the
  CP $02                  ; class, not the end
  JR Z,PRINT_WORD_0       ;
  CP $03                  ; After three, look again at the second byte's bit 7
  JR NZ,PRINT_WORD_1      ; before deciding
  DEC HL                  ;
  DEC HL                  ;
  LD A,(HL)               ;
  INC HL                  ;
  INC HL                  ;
  BIT 7,A                 ;
  JR NZ,PRINT_WORD_0      ;
PRINT_WORD_1:
  POP HL
  LD A,C                  ; Flag nibble $50: never inflect
  AND $F0                 ;
  CP $50                  ;
  JR Z,PRINT_WORD_5       ;
  CP $40                  ; $40: always inflect
  JR Z,PRINT_WORD_3       ;
  CP $10                  ; $10 agrees with TARGET, anything else with ACTING:
  LD A,(TARGET)           ; zero, no ending
  JR Z,PRINT_WORD_2       ;
  LD A,(ACTING)           ;
PRINT_WORD_2:
  AND A                   ;
  JR Z,PRINT_WORD_5       ;
PRINT_WORD_3:
  INC HL                  ; The word itself has to allow an ending: bit 7 of
  BIT 7,(HL)              ; its second byte
  JR Z,PRINT_WORD_5       ;
  INC HL                  ; HL = the ending chosen by bits 5-7 of its third
  LD A,(HL)               ; byte, in ENDINGS
  AND $E0                 ;
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  LD L,A                  ;
  LD H,$00                ;
  LD BC,ENDINGS           ;
  ADD HL,BC               ;
  LD B,$04                ; Add up to four characters of it to the buffer
PRINT_WORD_4:
  LD A,(HL)               ;
  AND A                   ;
  JR Z,PRINT_WORD_5       ;
  INC HL                  ;
  LD (DE),A               ;
  INC DE                  ;
  DJNZ PRINT_WORD_4       ;
PRINT_WORD_5:
  LD HL,WORD_BUFFER       ; B = how many characters there are to print
  EX DE,HL                ;
  AND A                   ;
  SBC HL,DE               ;
  LD B,L                  ;
  LD A,(INPUT_STYLE)      ; A space before the word, when one is wanted
  AND A                   ;
  PUSH AF                 ;
  JR NZ,PRINT_WORD_6      ;
  LD A,(MID_LINE)         ;
  AND A                   ;
PRINT_WORD_6:
  LD A,$20                ;
  CALL NZ,PRINT_CHAR      ;
  POP AF                  ; Start a new line first if the word would not fit on
  LD A,(INPUT_COLUMNS)    ; this one
  JR NZ,PRINT_WORD_7      ;
  LD A,(STORY_COLUMNS)    ;
PRINT_WORD_7:
  LD HL,CAPITAL_NEXT      ;
  CP B                    ;
  JR NC,PRINT_WORD_8      ;
  LD A,(HL)               ;
  CALL NEW_LINE           ;
  LD (HL),A               ;
PRINT_WORD_8:
  POP DE
  LD A,D                  ; Flag nibble $70 sets CAPITAL_NEXT to 1
  AND $F0                 ;
  CP $70                  ;
  LD A,$01                ;
  JR NZ,PRINT_WORD_9      ;
  LD (HL),A               ;
PRINT_WORD_9:
  LD HL,WORD_BUFFER       ; Print the buffer
PRINT_WORD_10:
  LD A,(HL)               ;
  CALL PRINT_CHAR         ;
  INC HL                  ;
  DJNZ PRINT_WORD_10      ;
  POP BC
  POP HL
  RET
; The flags in the top nibble choose whether the word is inflected, and the
; whole of it is: $40 always adds the suffix, $50 never does, $10 adds it when
; TARGET is non-zero, and every other value adds it when ACTING is non-zero.
; Either way the word itself has the final say -- the suffix is only added if
; bit 7 of its second byte is set, which is what marks an entry as one that can
; take it.
;
; Measured rather than read off: PRINT_WORD was called directly with each of
; the sixteen flag values and the buffer read back, then TARGET and ACTING were
; toggled by hand to test the dispatch. The word at WORD_SHATTER comes out as
; "shatter" or "shatters" exactly as the rule above predicts in all six cases,
; the ones at WORD_RECOVER and WORD_ARRIVES inflect the same way, and no word
; in the indexed list inflects at all -- none of them has that bit set, which
; fits, since the indexed list is what the parser matches against and nothing
; is ever printed from it.
;
; ACTING holds who the sentence is about, and zero means the player -- so the
; test really is subject agreement. Watched across real sentences: while the
; game narrates you it is zero and no verb inflects, and while it narrates
; anybody else it holds that character's identifier and the inflectable verbs
; take their -s. TARGET is a second participant, and flag $10 is how a word is
; made to agree with that one instead.
;
; The identifiers are not a flag but a character number: TARGET is set to $FF
; at PARSE_ACTION, loaded from tables at FIRST_TARGET_FAILED and TARGET_NAME
; elsewhere, and compared against list entries with CP (HL) at EXCEPTED. One
; turn of narration walked ACTING through a run of consecutive values while
; repeating the same verb, which is a group of characters being described one
; after another rather than anything to do with grammar.

; PARSE_AND's checkpoint
;
; Where the parser was when it met AND, so that PARSE_VERB can go back there if
; a verb follows: TAKE THE MAP AND DROP IT is then two commands.
AND_TOKENS:
  DEFB $00,$00            ; The place in TOKENS after the ANDs
AND_STATE:
  DEFB $00                ; The parser's state in E
AND_FRAME:
  DEFB $00,$00            ; The frame being built (IY)
AND_FRAMES:
  DEFB $00                ; COMMAND_FRAMES as it was

; The noun phrase being built
;
; A count of prepositions, then ten bytes laid out as a noun phrase in the
; command frame is -- two prepositions, the noun, two adjectives, each a word
; reference low byte first -- which the class handlers fill as the words
; arrive.
PHRASE:
  DEFB $00                ; How many prepositions it has so far:
                          ; ADD_PREPOSITION refuses a third
PHRASE_PREPOSITIONS:
  DEFB $00,$00,$00,$00    ; Two prepositions
PHRASE_NOUN:
  DEFB $00,$00            ; The noun
PHRASE_ADJECTIVES:
  DEFB $00,$00,$00,$00    ; Two adjectives: ADD_ADJECTIVE takes the first free
                          ; one and refuses a third

; Parse one command from the tokens
;
; Used by the routine at START.
;
; Called by the main loop with TOKEN_POINTER pointing into TOKENS; returns NZ
; to go back for another line. A line of several commands -- joined by THEN, or
; by a full stop -- is taken one command at a time, the main loop coming back
; here while MORE_COMMANDS says there is more.
PARSE_COMMAND:
  LD IY,COMMAND_FRAME     ; Start at the first frame, outside any quotation
  XOR A                   ;
; This entry point is used by the routine at ORDER_BEGINS.
PARSE_ORDER:
  LD (IS_ORDER),A         ; }
  CALL CLEAR_ALL_EXCEPT   ; Not yet worked out
  LD (COMMAND_FRAMES),A   ;
  LD E,$FF                ; Was the last command left unfinished -- after
  LD A,(QUESTION_WAITING) ; 'which key?', say? Then fit these words into it
  AND A                   ;
  LD D,$A0                ;
  JP NZ,END_COMMAND       ;
  LD D,$C0                ; A fresh command
; This entry point is used by the routines at PARSE_THEN and PARSE_SPECIAL.
PARSE_NEXT_COMMAND:
  XOR A                   ; E says what may come next: bit 1 a verb, bit 2 an
  LD (PHRASE),A           ; adverb, bit 4 an article, and more
  LD A,E                  ;
  OR $C7                  ;
  LD E,A                  ;
  LD A,(ALL_EXCEPT)       ; In one case a verb may not start here
  CP $02                  ;
  JR NZ,PARSE_COMMAND_0   ;
  RES 1,E                 ;
PARSE_COMMAND_0:
  CALL CLEAR_FRAME        ; Clear this frame
; This entry point is used by the routines at PARSE_ADVERB, PARSE_VERB,
; PARSE_NOUN, NOT_ALLOWED_HERE, WORD_NOPRINT, WORD_EXCEPT, WORD_ALL, WORD_IT,
; SPECIAL_QUOTE and DO_HELP.
NEW_NOUN_PHRASE:
  LD HL,PHRASE_PREPOSITIONS ; Start a new noun phrase, and allow an article
  LD B,$0A                  ;
  CALL CLEAR_BYTES          ;
  SET 4,E                   ;
; This entry point is used by the routine at PARSE_ARTICLE.
PARSE_NEXT_WORD:
  CALL NEXT_TOKEN         ; Next token: its class in D
CLASS_DISPATCH:
  PUSH DE                 ; Go to the handler for its class, from
  RRCA                    ; PARSER_CLASSES
  RRCA                    ;
  RRCA                    ;
  LD E,A                  ;
  LD D,$00                ;
  LD HL,PARSER_CLASSES    ;
  ADD HL,DE               ;
  LD E,(HL)               ;
  INC HL                  ;
  LD D,(HL)               ;
  EX DE,HL                ;
  POP DE                  ;
  JP (HL)                 ;

; Where the parser goes for each class of word
;
; One handler per token class, indexed by the class nibble shifted right three
; places at CLASS_DISPATCH and reached through JP (HL) -- so following branches
; never finds them, and they are code seeds. Twelve of the thirteen were
; reached in play. There is no entry for class $D: an unknown word never gets
; this far.
PARSER_CLASSES:
  DEFW PARSE_ADVERB       ; Class $0: an adverb
  DEFW PARSE_IN           ; Class $1: IN or INTO
  DEFW PARSE_DIRECTION    ; Class $2: a direction
  DEFW PARSE_VERB         ; Class $3: a verb
  DEFW PARSE_GO           ; Class $4: GO or RUN
  DEFW PARSE_NOUN         ; Class $5: a noun
  DEFW PARSE_ADJECTIVE    ; Class $6: an adjective
  DEFW PARSE_PREPOSITION  ; Class $7: a preposition
  DEFW PARSE_ARTICLE      ; Class $8: an article
  DEFW PARSE_SPECIAL      ; Class $9: a quantifier, pronoun or game command
  DEFW PARSE_AND          ; Class $A: AND
  DEFW PARSE_THEN         ; Class $B: THEN or a full stop
  DEFW PARSE_END          ; Class $C: the end of the line

; Z if the sentence being parsed is an order said to someone (IS_ORDER = 1)
;
; Used by the routine at PARSE_THEN.
IN_ORDER_ONLY:
  LD A,(IS_ORDER)
  DEC A
  RET

; NZ if the sentence being parsed is an order said to someone
;
; Used by the routines at PARSE_THEN, PARSE_VERB, ORDERS_ONLY and
; NOT_ALLOWED_HERE.
PARSING_ORDER:
  LD A,(IS_ORDER)
  AND A
  RET

; Parse the end of the line
PARSE_END:
  XOR A                   ; The end of the line: no more commands in it. On as
  LD (MORE_COMMANDS),A    ; for THEN

; Parse THEN or a full stop
;
; Used by the routines at PARSE_AND and PARSE_VERB.
PARSE_THEN:
  BIT 1,E                 ; No verb yet, and no earlier frame to borrow one
  JR Z,END_COMMAND        ; from...
  LD A,(COMMAND_FRAMES)   ;
  AND A                   ;
  JR NZ,END_COMMAND       ;
  LD A,(LAST_CLASS)       ; ...an empty line: nothing to do
  CP $C0                  ;
  JR NZ,PARSE_THEN_0      ;
  CP D                    ;
  JR Z,IN_ORDER_ONLY      ;
PARSE_THEN_0:
  CALL PARSING_ORDER      ; ...no verb outside a quotation: "what ?"
  JP Z,QUOTE_LEFT_OPEN    ;
; This entry point is used by the routine at PARSE_COMMAND.
END_COMMAND:
  LD A,(ALL_EXCEPT)       ; ALL_EXCEPT = 1 means ALL: set bit 7 of the verb's
  DEC A                   ; second byte
  JR NZ,PARSE_THEN_1      ;
  SET 7,(IY+$01)          ;
PARSE_THEN_1:
  LD HL,COMMAND_FRAMES    ; Count the frame, except for the AND in ALL EXCEPT
  DEC A                   ;
  LD A,D                  ;
  JR NZ,PARSE_THEN_2      ;
  CP $A0                  ;
  JR Z,PARSE_THEN_3       ;
PARSE_THEN_2:
  INC (HL)                ;
PARSE_THEN_3:
  CALL FRAME_BELOW_THEN_SWAP ; On to the next frame; if an AND ended this one,
  CP $A0                     ; keep going: TAKE THE MAP AND THE KEY
  JP Z,PARSE_NEXT_COMMAND    ;
  LD A,(QUESTION_WAITING) ; Finishing a command that was left unfinished?
  AND A                   ;
  JR Z,PARSE_THEN_10      ;
  PUSH DE                 ; Compare the new frame's noun with the old
  LD E,A                  ; command's...
  LD D,$00                ;
  LD HL,COMMAND_FRAME     ;
  ADD HL,DE               ;
  PUSH IY                 ;
  LD IY,NEXT_FRAME        ;
  LD A,(IY+$08)           ;
  OR (IY+$09)             ;
  LD DE,NEXT_FRAME+$0008  ;
  JR Z,PARSE_THEN_5       ;
  LD A,(IY+$08)           ;
  CP (HL)                 ;
  JR NZ,PARSE_THEN_4      ;
  LD A,(IY+$09)           ;
  INC HL                  ;
  CP (HL)                 ;
  DEC HL                  ;
  JR Z,PARSE_THEN_5       ;
PARSE_THEN_4:
  LD A,(IY+$12)           ; ...or its second noun...
  OR (IY+$13)             ;
  LD DE,NEXT_FRAME+$0012  ;
PARSE_THEN_5:
  POP IY                  ;
  JR NZ,PARSE_THEN_9      ; ...and copy the new words into whichever of the old
  EX DE,HL                ; noun and adjectives are empty
  LD B,$03                ;
PARSE_THEN_6:
  LD A,(HL)               ;
  INC HL                  ;
  OR (HL)                 ;
  DEC HL                  ;
  JR NZ,PARSE_THEN_7      ;
  LD A,(DE)               ;
  LD (HL),A               ;
PARSE_THEN_7:
  INC HL                  ;
  INC DE                  ;
  JR NZ,PARSE_THEN_8      ;
  LD A,(DE)               ;
  LD (HL),A               ;
PARSE_THEN_8:
  INC HL                  ;
  INC DE                  ;
  DJNZ PARSE_THEN_6       ;
PARSE_THEN_9:
  POP DE
PARSE_THEN_10:
  PUSH IY                 ; Every frame with no verb takes the verb of the
  LD IY,ROOM_POINTERS     ; frame before
  LD A,(COMMAND_FRAMES)   ;
  LD B,A                  ;
  PUSH BC                 ;
  CALL FRAME_BELOW_SWAP   ;
PARSE_THEN_11:
  LD A,B                  ;
  AND A                   ;
  JR Z,PARSE_THEN_12      ;
  CALL FRAME_BELOW_SWAP   ;
  LD A,(IY+$01)           ;
  AND $7F                 ;
  OR (IY+$00)             ;
  CALL Z,COPY_VERB_ON     ;
  JR PARSE_THEN_11        ;
PARSE_THEN_12:
  POP BC                  ; And a frame with the same verb but no second phrase
  POP IY                  ; borrows the one before's: PUT THE MAP AND THE KEY
  PUSH IY                 ; IN THE CHEST
  CALL FRAME_SWAP_DOWN    ;
PARSE_THEN_13:
  LD A,B                  ;
  AND A                   ;
  JP Z,PARSE_THEN_14      ;
  CALL FRAME_SWAP_DOWN    ;
  LD A,(IY+$12)           ;
  OR (IY+$13)             ;
  JR NZ,PARSE_THEN_13     ;
  LD A,(IY+$00)           ;
  CP (IX+$00)             ;
  JR NZ,PARSE_THEN_13     ;
  LD A,(IY+$01)           ;
  CP (IX+$01)             ;
  JR NZ,PARSE_THEN_13     ;
  LD A,(IX+$0E)           ;
  OR (IX+$0F)             ;
  JR Z,PARSE_THEN_13      ;
  EXX                     ;
  LD DE,$000E             ;
  CALL COPY_VERB_PHRASE   ;
  JP PARSE_THEN_13        ;
PARSE_THEN_14:
  POP IY                  ; Nothing more on the line: done
  LD A,(MORE_COMMANDS)    ;
  AND A                   ;
  RET Z                   ;
  CALL PARSING_ORDER      ; More: outside a quotation, go back to the main loop
  RET Z                   ; for it; inside one, carry straight on
  JP PARSE_NEXT_COMMAND   ;

; Parse a direction
PARSE_DIRECTION:
  BIT 1,E                 ; Where a verb could start, a direction is the verb:
  JR NZ,AS_VERB           ; NORTHEAST on its own
  LD D,$00                ; Anywhere else it goes where an adverb would, as
                          ; after GO

; Parse an adverb
PARSE_ADVERB:
  BIT 2,E                 ; Not where an adverb can go: NOT_ALLOWED_HERE
  JP Z,NOT_ALLOWED_HERE   ;
  LD A,(ALL_EXCEPT)       ; Not yet worked out
  CP $02                  ;
  JR NZ,PARSE_ADVERB_0    ;
  CALL NEW_SENTENCE_FRAME ;
PARSE_ADVERB_0:
  RES 2,E                 ; Only one
  LD L,$02                ; Store it at offset 2 of the frame
  CALL STORE_WORD         ;
  JP NEW_NOUN_PHRASE      ; And on to the next word

; Parse AND
PARSE_AND:
  RES 3,E                 ; Just had AND: a verb now would start another
                          ; command
  PUSH DE
PARSE_AND_0:
  CALL NEXT_TOKEN         ; Pass over any more ANDs
  CP $A0                  ;
  JR Z,PARSE_AND_0        ;
  DEC HL                  ; Back to the word after them, and save that place...
  DEC HL                  ;
  LD (AND_TOKENS),HL      ;
  LD (TOKEN_POINTER),HL   ;
  POP DE                  ; ...with E, the frame and the frame count: the
  LD A,E                  ; checkpoint PARSE_VERB goes back to
  LD (AND_STATE),A        ;
  LD (AND_FRAME),IY       ;
  LD A,(COMMAND_FRAMES)   ;
  LD (AND_FRAMES),A       ;
  JP PARSE_THEN           ; Then end this part as THEN would

; Parse GO or RUN
PARSE_GO:
  RES 0,E                 ; GO or RUN...
; This entry point is used by the routines at PARSE_DIRECTION and PARSE_IN.
AS_VERB:
  LD D,$30

; Parse a verb
PARSE_VERB:
  BIT 3,E                 ; Not straight after AND -- E bit 3 is set for an
  JR NZ,PARSE_VERB_0      ; ordinary command -- or inside a quotation: handle
  CALL PARSING_ORDER      ; it as the verb
  JR NZ,PARSE_VERB_0      ;
  LD HL,(AND_TOKENS)      ; Straight after AND: the AND joined two commands. Go
  LD (TOKEN_POINTER),HL   ; back to the checkpoint PARSE_AND saved at
  LD D,$B0                ; AND_TOKENS and end this command there, as THEN
  LD A,(AND_STATE)        ; would -- so TAKE THE MAP AND DROP IT is two
  LD E,A                  ; commands
  LD A,(AND_FRAMES)       ;
  LD (COMMAND_FRAMES),A   ;
  LD IY,(AND_FRAME)       ;
  JP PARSE_THEN           ;
PARSE_VERB_0:
  CALL CLEAR_ALL_EXCEPT   ; A second verb without AND: NOT_ALLOWED_HERE, "what
  BIT 1,E                 ; ?"
  JP Z,NOT_ALLOWED_HERE   ;
  BIT 0,E                 ; Already looked ahead for a direction?
  JR Z,PARSE_VERB_2       ;
PARSE_VERB_1:
  CALL STORE_VERB         ; Store it, and on to the next word
  JP NEW_NOUN_PHRASE      ;
PARSE_VERB_2:
  PUSH DE                 ; Look ahead, keeping the place...
  PUSH BC                 ;
  LD HL,(TOKEN_POINTER)   ;
  PUSH HL                 ;
PARSE_VERB_3:
  CALL NEXT_TOKEN         ; ...past any adverbs...
  CP $00                  ;
  JR Z,PARSE_VERB_3       ;
  SET 0,E                 ;
  CP $20                  ; ...for a direction. None: go back, and store just
  JR Z,PARSE_VERB_4       ; the verb
  POP HL                  ;
  LD (TOKEN_POINTER),HL   ;
  POP BC                  ;
  POP DE                  ;
  JR PARSE_VERB_1         ;
PARSE_VERB_4:
  CALL STORE_VERB         ; A direction: store the verb, and the direction at
  POP HL                  ; offset 2 -- RUN QUICKLY WEST
  POP BC                  ;
  POP HL                  ;
  LD L,$02                ;
  CALL STORE_WORD         ;
  JP NEW_NOUN_PHRASE      ;

; Parse an article
PARSE_ARTICLE:
  RES 4,E                 ; An article: noted, not stored -- no second one
  JP PARSE_NEXT_WORD      ; allowed -- and on to the next word

; Parse IN or INTO
PARSE_IN:
  BIT 1,E                 ; At the start of a command, straight after AND, IN
  JR Z,PARSE_IN_0         ; is a verb
  LD A,(LAST_CLASS)       ;
  CP $A0                  ;
  JR Z,AS_VERB            ;
PARSE_IN_0:
  LD D,$70                ; Otherwise it is a preposition

; Parse a preposition
PARSE_PREPOSITION:
  CALL ADD_PREPOSITION    ; Into PHRASE
PARSE_PREPOSITION_0:
  CALL NEXT_TOKEN         ; Another preposition follows? Add that too
  CP $70                  ;
  JR Z,PARSE_PREPOSITION  ;
  CP $80                  ; An article: allowed once, then dropped
  JR NZ,PHRASE_GOES_ON    ;
  BIT 4,E                 ;
  CALL Z,ORDERS_ONLY      ;
  RES 4,E                 ;
  JR PARSE_PREPOSITION_0  ;
; This entry point is used by the routine at PARSE_ADJECTIVE.
PHRASE_GOES_ON:
  CP $60                  ; An adjective or a noun: carry on building the
  JR Z,PARSE_ADJECTIVE    ; phrase
  CP $50                  ;
  JR Z,PARSE_NOUN         ;
  LD HL,(VARIABLES)       ; Anything else: put it back, and file the phrase
  LD (TOKEN_POINTER),HL   ; without a noun
  JR AS_NOUN              ;

; Parse an adjective
;
; Used by the routine at PARSE_PREPOSITION.
PARSE_ADJECTIVE:
  CALL ADD_ADJECTIVE      ; Put it in the phrase
  CALL NEXT_TOKEN         ; And go on to see what follows it
  JR PHRASE_GOES_ON       ;

; Parse a noun
;
; Used by the routine at PARSE_PREPOSITION.
PARSE_NOUN:
  LD HL,PHRASE_NOUN       ; The noun into PHRASE
  LD (HL),C               ;
  INC HL                  ;
  LD (HL),B               ;
; This entry point is used by the routine at PARSE_PREPOSITION.
AS_NOUN:
  LD D,$50
  LD A,(ALL_EXCEPT)       ; In mode 2, after ALL EXCEPT...
  CP $02                  ;
  JR NZ,PARSE_NOUN_2      ;
  LD HL,(PHRASE_PREPOSITIONS) ; ...with no preposition...
  LD A,H                      ;
  OR L                        ;
  JR NZ,PARSE_NOUN_1          ;
  BIT 6,(IY+$19)          ; ...the noun goes into the frame below, cleared
  JR NZ,PARSE_NOUN_0      ; first if need be...
  LD BC,$FFE8             ;
  ADD IY,BC               ;
  CALL CLEAR_FRAME        ;
PARSE_NOUN_0:
  CALL FILE_FIRST_PHRASE  ; ...as its first phrase, and that frame is marked
  LD (IY+$01),$40         ; with $40 in its verb's second byte
  JP NEW_NOUN_PHRASE      ;
PARSE_NOUN_1:
  CALL NEW_SENTENCE_FRAME ; Not yet worked out
PARSE_NOUN_2:
  CALL FILE_PHRASE        ; File the phrase; on to the next word unless that
  JP Z,NEW_NOUN_PHRASE    ; failed
  RET                     ;

; Add the adjective in BC to PHRASE
;
; Used by the routine at PARSE_ADJECTIVE.
ADD_ADJECTIVE:
  LD HL,PHRASE_ADJECTIVES ; Is the first adjective slot free?
; This entry point is used by the routine at ADD_PREPOSITION.
ADD_TO_PAIR:
  LD A,(HL)
  INC HL
  OR (HL)
  JR Z,ADD_ADJECTIVE_0    ; }
  INC HL                  ; Is the second? Neither: too many adjectives
  LD A,(HL)               ;
  INC HL                  ;
  OR (HL)                 ;
  JP NZ,ORDERS_ONLY       ;
ADD_ADJECTIVE_0:
  LD (HL),B               ; Store it, low byte first
  DEC HL                  ;
  LD (HL),C               ;
  RET

; Add the preposition in BC to PHRASE
;
; Used by the routine at PARSE_PREPOSITION.
ADD_PREPOSITION:
  LD HL,PHRASE            ; Count it; a third preposition is an error
  INC (HL)                ;
  LD A,(HL)               ;
  CP $03                  ;
  JP NC,ORDERS_ONLY       ;
  LD HL,PHRASE_PREPOSITIONS ; Into the first free preposition slot, as
  JR ADD_TO_PAIR            ; ADD_ADJECTIVE does adjectives

; Put PHRASE into the frame's first free noun phrase
;
; Used by the routine at PARSE_NOUN.
;
; E's bit 6 says the first, at offset 4, is still empty, and bit 7 the second,
; at offset 14. A third phrase is an error.
FILE_PHRASE:
  BIT 6,E                 ; The first phrase still empty? It goes there
  JR NZ,FILE_FIRST_PHRASE ;
  BIT 7,E                  ; Nor the second: one phrase too many
  JR NZ,FILE_SECOND_PHRASE ;
  CALL ORDERS_ONLY         ;
  XOR A                    ;
  RET                      ;
; This entry point is used by the routine at IT_PHRASE.
FILE_SECOND_PHRASE:
  RES 7,E                 ; The second, at offset 14
  PUSH DE                 ;
  LD DE,$000E             ;
; This entry point is used by the routine at FILE_FIRST_PHRASE.
FILE_PHRASE_AT:
  PUSH BC                   ; Copy the ten bytes of PHRASE into the frame at
  PUSH IY                   ; that offset
  POP HL                    ;
  ADD HL,DE                 ;
  EX DE,HL                  ;
  LD HL,PHRASE_PREPOSITIONS ;
  LD BC,$000A               ;
  LDIR                      ;
  POP BC
  POP DE
  XOR A
  RET

; Put PHRASE into the frame's first noun phrase
;
; Used by the routines at PARSE_NOUN, FILE_PHRASE and IT_PHRASE.
FILE_FIRST_PHRASE:
  RES 6,E                 ; The first, at offset 4
  PUSH DE                 ;
  LD DE,$0004             ;
  JR FILE_PHRASE_AT       ;

; Move on to a new frame, and forget ALL and EXCEPT
;
; Used by the routines at PARSE_ADVERB and PARSE_NOUN.
NEW_SENTENCE_FRAME:
  CALL FRAME_ABOVE_EMPTY
  PUSH IX
  POP IY
; This entry point is used by the routines at PARSE_COMMAND and PARSE_VERB.
CLEAR_ALL_EXCEPT:
  XOR A
  LD (ALL_EXCEPT),A
  RET

; Clear the frame at IY
;
; Used by the routines at PARSE_COMMAND and PARSE_NOUN.
;
; All 24 bytes, and the verb of the frame below it, so that one reads as empty.
CLEAR_FRAME:
  PUSH IY                 ; Clear the 24 bytes
  POP HL                  ;
  LD B,$18                ;
  CALL CLEAR_BYTES        ;
  LD (IY-$18),B           ; And the verb of the frame below
  LD (IY-$17),B           ;
  RET

; Take the next token
;
; Used by the routines at PARSE_COMMAND, PARSE_AND, PARSE_VERB,
; PARSE_PREPOSITION and PARSE_ADJECTIVE.
;
; From the pointer in TOKEN_POINTER, which it moves on. The previous position
; is kept in VARIABLES, which is what the main loop echoes back when a word is
; not known, and the previous class in LAST_CLASS, which PARSE_IN looks at.
;
; O:D The class, in the top nibble
; O:BC The word: B the top of its offset, C the low byte
NEXT_TOKEN:
  LD HL,(TOKEN_POINTER)   ; Keep where this token is, for the echo of an
  LD (VARIABLES),HL       ; unknown word
  LD A,D                  ; Keep the class of the last token
  LD (LAST_CLASS),A       ;
  LD A,(HL)               ; B = the top of the word's offset, D = the class
  AND $0F                 ;
  LD B,A                  ;
  LD A,(HL)               ;
  AND $F0                 ;
  LD D,A                  ;
  INC HL                  ; C = the low byte; move the pointer on
  LD C,(HL)               ;
  INC HL                  ;
  LD (TOKEN_POINTER),HL   ;
  RET

; FRAME_ABOVE_EMPTY with the frames in IX and IY swapped round
;
; Used by the routine at PARSE_THEN.
FRAME_SWAP_DOWN:
  DEC B
  CALL FRAME_ABOVE_EMPTY
  JR SWAP_FRAMES

; FRAME_BELOW with the frames in IX and IY swapped round
;
; Used by the routine at PARSE_THEN.
FRAME_BELOW_SWAP:
  DEC B
; This entry point is used by the routine at PARSE_THEN.
FRAME_BELOW_THEN_SWAP:
  CALL FRAME_BELOW
; This entry point is used by the routine at FRAME_SWAP_DOWN.
SWAP_FRAMES:
  PUSH IX
  PUSH IY
  POP IX
  POP IY
  RET

; Step IY down one frame
;
; Used by the routine at FRAME_BELOW_SWAP.
FRAME_BELOW:
  PUSH DE
  LD DE,$FFE8             ; 24 bytes down
  JR FRAME_ABOVE_EMPTY_BY ;

; IX = the first frame down from IY with its first phrase in use
;
; Used by the routines at NEW_SENTENCE_FRAME and FRAME_SWAP_DOWN.
;
; Frames are 24 bytes apart below COMMAND_FRAME; bit 6 of a frame's second byte
; marks its first phrase empty.
FRAME_ABOVE_EMPTY:
  PUSH DE
  LD DE,$0018
; This entry point is used by the routine at FRAME_BELOW.
FRAME_ABOVE_EMPTY_BY:
  PUSH IY
  POP IX
FRAME_ABOVE_EMPTY_0:
  ADD IX,DE
  BIT 6,(IX+$01)
  JR NZ,FRAME_ABOVE_EMPTY_0
  POP DE
  RET

; Give the frame at IY the verb of the frame at IX
;
; Used by the routine at PARSE_THEN.
;
; Keeping its own ALL bit. In some cases it also moves the frame's own phrase
; to second place and borrows the first phrase and the adverb from the frame
; before; exactly when is not yet worked out.
COPY_VERB_ON:
  EXX
  LD A,(IX+$01)           ; The verb, keeping this frame's own ALL bit
  AND $7F                 ;
  OR (IY+$01)             ;
  LD (IY+$01),A           ;
  LD A,(IX+$00)           ;
  LD (IY+$00),A           ;
  EXX
  LD A,(IY+$1C)           ; Not yet worked out
  OR (IY+$1D)             ;
  RET Z                   ;
  BIT 7,E                 ;
  RET Z                   ;
  EXX
  PUSH IY
  POP HL
  LD DE,$0012
  ADD HL,DE
  PUSH HL
  LD DE,$FFF6
  ADD HL,DE
  POP DE
  LD BC,$0006
  LDIR
  LD DE,$0004
; This entry point is used by the routine at PARSE_THEN.
COPY_VERB_PHRASE:
  CALL COPY_FRAME_PHRASE
  LD A,(IY+$02)
  OR (IY+$03)
  LD DE,$0002
  CALL Z,COPY_FRAME_WORD
  EXX
  RET

; Unreached: LD C,6 and JR COPY_FRAME_BYTES
;
; A third way into COPY_FRAME_PHRASE, for six bytes, that nothing uses.
UNREACHED_COPY_SIX:
  DEFB $0E,$06,$18,$06

; Copy a ten-byte noun phrase from frame IX to frame IY, at offset DE
;
; Used by the routine at COPY_VERB_ON.
;
; COPY_FRAME_WORD, the way in with C = 2, copies a single word instead.
COPY_FRAME_PHRASE:
  LD C,$0A
  JR COPY_FRAME_BYTES

; Copy a single word from frame IX to frame IY, at offset DE (COPY_FRAME_PHRASE
; with C = 2)
;
; Used by the routine at COPY_VERB_ON.
COPY_FRAME_WORD:
  LD C,$02
; This entry point is used by the routine at COPY_FRAME_PHRASE.
COPY_FRAME_BYTES:
  PUSH IY
  POP HL
  ADD HL,DE
  PUSH HL
  PUSH IX
  POP HL
  ADD HL,DE
  POP DE
  LD B,$00
  LDIR
  RET

; Store the verb in BC at the head of the frame
;
; Used by the routine at PARSE_VERB.
;
; No second verb is allowed after it, and it goes in at offset 0 through
; STORE_WORD, which it runs straight into.
STORE_VERB:
  RES 1,E                 ; No second verb; offset 0
  LD L,$00                ;

; Store the word in BC in the frame at offset L
;
; Used by the routines at PARSE_ADVERB and PARSE_VERB.
;
; Low byte first -- which is why the frames and object names hold their words
; little-endian while tokens hold them the other way round.
STORE_WORD:
  PUSH DE                 ; HL = the frame plus L
  PUSH IY                 ;
  POP DE                  ;
  LD H,$00                ;
  ADD HL,DE               ;
  LD (HL),C               ; The word, low byte first
  INC HL                  ;
  LD (HL),B               ;
  POP DE
  RET

; Allowed only in an order; otherwise NOT_ALLOWED_HERE
;
; Used by the routines at PARSE_PREPOSITION, ADD_ADJECTIVE, ADD_PREPOSITION and
; FILE_PHRASE.
ORDERS_ONLY:
  CALL PARSING_ORDER
  RET NZ
  POP HL

; A word that is not allowed where it came
;
; Used by the routines at PARSE_ADVERB, PARSE_VERB and WORD_EXCEPT.
;
; Inside a quotation it is simply passed over, so orders given to other
; characters are more forgiving. Otherwise the game says "what ?" and the
; command is abandoned.
NOT_ALLOWED_HERE:
  CALL PARSING_ORDER      ; Inside a quotation: ignore the word and carry on
  JP NZ,NEW_NOUN_PHRASE   ;

; "what ?": the line ended inside a quotation
;
; Used by the routines at START and PARSE_THEN.
QUOTE_LEFT_OPEN:
  LD HL,MSG_WHAT          ; Otherwise "what ?"
  LD A,$01                ;
  LD (INPUT_STYLE),A      ;
  CALL RUN_MESSAGE_HL     ;
  OR $01                  ; NZ: the command is abandoned
  RET                     ;

; The target and instrument being looked for
;
; Zeros on the tape, so the generated listing called it unused; it is the
; parser's working space for the command in hand.
PHRASES:
  DEFB $00                ; Target flags: bit 0, a target was named; bit 1, one
                          ; has been found
INSTRUMENT_STATE:
  DEFB $00                ; The same for the instrument
TARGETS_FOUND:
  DEFB $00                ; How many objects have fitted the target's name
TARGETS_FAILED:
  DEFB $00                ; How many of them were tried and did not work: if
                          ; only one, the refusal is about that one
INSTRUMENTS_FAILED:
  DEFB $00                ; The same for the instrument
TARGET_NAME:
  DEFB $00,$00,$00,$00,$00,$00 ; The target as typed: noun, then two
                               ; adjectives, in the form objects are named in
INSTRUMENT_NAME:
  DEFB $00,$00,$00,$00,$00,$00 ; The instrument, the same way
TARGET_SEARCH:
  DEFB $00,$00            ; Where the search for the target has got to: an
                          ; object, or an exit when it is a place
INSTRUMENT_SEARCH:
  DEFB $00,$00            ; The same for the instrument
ALL_BIT:
  DEFB $00                ; The verb's ALL bit, bit 7, which MATCH_PATTERN sets
                          ; aside
WITH_ALL:
  DEFB $00                ; 1 with ALL: MATCH_AND_TRY gives up on an object
                          ; after one try rather than trying the next
TARGET_PHRASE_AT:
  DEFB $00                ; Where the target's noun is in the frame: 8 for the
                          ; first phrase, 18 for the second
INSTRUMENT_PHRASE_AT:
  DEFB $00                ; And the instrument's
FIRST_TARGET_FAILED:
  DEFB $00                ; The first target that was tried and did not work
FIRST_INSTRUMENT_FAILED:
  DEFB $00                ; The same for the instrument
PROBE_VERB:
  DEFB $00,$00            ; The probe MATCH_PATTERN looks for among
                          ; ACTION_PATTERNS: the verb, without its ALL bit...
PROBE_WORD1:
  DEFB $00,$00            ; ...then a particle and a preposition, picked from
                          ; the frame's noun phrases by PICK_WORD...
PROBE_WORD2:
  DEFB $00,$00            ; ...one to a word; ASSIGN_PHRASES swaps the two when
                          ; the pattern wants them the other way round
PATTERN:
  DEFB $00,$00            ; The pattern found, in ACTION_PATTERNS

; Carry out the parsed command, and let the world take its turn
;
; Used by the routine at START.
OBEY:
  XOR A                   ; From the first frame
  LD (ALL_ACTION),A       ;
  LD IY,COMMAND_FRAME     ;
  LD HL,QUESTION_WAITING  ; A reply was just fitted into an unfinished command:
  CP (HL)                 ; clear that, and go on from the next frame
  LD (HL),A               ;
  JP NZ,FRAME_DONE        ;
OBEY_0:
  CALL PARSE_ACTION       ; Work out this frame's command; nothing left, and
  JR NZ,OBEY_1            ; the line is done
  XOR A                   ; No more commands on this line
  LD (MORE_COMMANDS),A    ;
  RET                     ;
OBEY_1:
  CALL TRY_IT             ; Check it; SAY_WHY_NOT when it will not do
  JP Z,SAY_WHY_NOT        ;
  LD A,$01                ; Really do it
  LD (DOING_IT),A         ;
  CALL NARRATE_ACTION     ; Not yet worked out
  CALL DO_ACTION          ; Carry it out -- the player's MOVE was reached from
                          ; here
; This entry point is used by the routine at MATCH_PATTERN.
TURN_OVER:
  CALL END_OF_TURN        ; Not yet worked out
; This entry point is used by the routine at TARGET_TROUBLE.
OBEY_NEXT:
  LD A,(ALL_ACTION)       ; Asked to go round the same frame again?
  AND A                   ;
  JR NZ,OBEY_0            ;
; This entry point is used by the routine at TARGET_TROUBLE.
FRAME_DONE:
  LD A,(COMMAND_FRAMES)   ; Count the frame off; none left, done
  DEC A                   ;
  LD (COMMAND_FRAMES),A   ;
  RET Z                   ;
  LD BC,$FFE8             ; On to the next frame down, passing over ALL
OBEY_2:
  ADD IY,BC               ; EXCEPT's exception frames
  BIT 6,(IY+$01)          ;
  JR NZ,OBEY_2            ;
  JR OBEY_0               ;

; Clear PHRASES for a new sentence
;
; Used by the routines at PARSE_ACTION and WOULD_WORK.
CLEAR_PHRASES:
  XOR A
  LD (INPUT_STYLE),A
  LD HL,PHRASES
  LD B,$11
  CALL CLEAR_BYTES
  RET

; Turn a parsed sentence into an action and do it
;
; Used by the routines at OBEY and TAKE_ORDER.
;
; MATCH_PATTERN finds the sentence's pattern; the action code is its place in
; ACTION_PATTERNS, counted from 1, into ACTION and PARSED_ACTION. The pattern's
; options are set (PATTERN_OPTIONS) and the search for the target begun. A
; pattern with objects goes to MATCH_AND_TRY, and anything it leaves to be said
; to TARGET_TROUBLE. With ALL, it goes round again for each object, passing
; over one an EXCEPT names -- which is what EXCEPTED is believed to check.
PARSE_ACTION:
  LD A,$FF                ; No objects yet; clear the phrases; match the
  LD (INSTRUMENT),A       ; pattern
  LD (TARGET),A           ;
  CALL CLEAR_PHRASES      ;
  CALL MATCH_PATTERN      ;
  RET Z                   ;
  LD A,$01                ; The action code is the pattern's place in the table
  PUSH IX                 ;
  POP HL                  ;
  LD DE,ACTION_PATTERNS   ;
  SBC HL,DE               ;
  JR Z,PARSE_ACTION_1     ;
  LD DE,$0008             ;
PARSE_ACTION_0:
  INC A                   ;
  SBC HL,DE               ;
  JR NZ,PARSE_ACTION_0    ;
PARSE_ACTION_1:
  LD (ACTION),A           ; Keep it, and the pattern; set its options, start
  LD (PARSED_ACTION),A    ; the search
  LD (PATTERN),IX         ;
  CALL PATTERN_OPTIONS    ;
  CALL START_TARGETS      ;
  XOR A                   ; Only tests from here
  LD (DOING_IT),A         ;
  LD A,(FLAGS_FIRST_WORDS) ; No objects in the pattern: done
  AND $0C                  ;
  JR Z,PARSE_ACTION_3      ;
  LD A,(ALL_BIT)          ; ALL?
  LD (ALL_ACTION),A       ;
  RLCA                    ;
  AND $01                 ;
  LD (WITH_ALL),A         ;
PARSE_ACTION_2:
  CALL MATCH_AND_TRY      ; Match and try; trouble: TARGET_TROUBLE
  JP NZ,TARGET_TROUBLE    ;
  LD A,(ALL_ACTION)       ; With ALL, on to the next object that is not
  AND A                   ; excepted
  JR Z,PARSE_ACTION_3     ;
  CALL EXCEPTED           ;
  JR NZ,PARSE_ACTION_2    ;
PARSE_ACTION_3:
  OR $01
  RET

; Try the objects that fit the sentence's names until the action works
;
; Used by the routines at PARSE_ACTION and WOULD_WORK.
;
; For a pattern with objects, the target and the instrument are each only names
; until something fits them. This goes through the objects that fit the
; target's name (NEXT_TARGET) and, for each, those that fit the instrument's
; (NEXT_INSTRUMENT), trying the action on each pair, and stops at the first
; that works. How many fitted is counted at TARGETS_FOUND to
; INSTRUMENTS_FAILED, and the first of each is kept at FIRST_TARGET_FAILED to
; FIRST_INSTRUMENT_FAILED, so that when only one thing fitted it is that one
; the refusal is about. The exact order of the fall-backs is not worked out in
; full.
MATCH_AND_TRY:
  CALL NEXT_TARGET        ; The next target that fits
  JR NZ,MATCH_AND_TRY_0   ;
  LD A,(TARGETS_FAILED)      ; None left: if only one ever fitted, it is the
  CP $01                     ; one; try it with the instruments
  RET NZ                     ;
  LD A,(FIRST_TARGET_FAILED) ;
  LD (TARGET),A              ;
  CALL START_INSTRUMENTS     ;
  CALL WANTS_TARGET          ;
  JR NZ,MATCH_AND_TRY_3      ;
  RET                        ;
MATCH_AND_TRY_0:
  LD HL,TARGETS_FOUND     ; Count it
  INC (HL)                ;
  CALL WANTS_TARGET       ; Wants an instrument? Try each with it
  JR Z,MATCH_AND_TRY_2    ;
  CALL START_INSTRUMENTS  ;
  CALL NEXT_INSTRUMENT    ;
MATCH_AND_TRY_1:
  JR Z,MATCH_AND_TRY         ; Did not work: keep the first, count, and go on
  LD A,(WITH_ALL)            ;
  DEC A                      ;
  RET Z                      ;
  LD A,(TARGET)              ;
  LD (FIRST_TARGET_FAILED),A ;
  LD HL,TARGETS_FAILED       ;
  INC (HL)                   ;
  JR MATCH_AND_TRY           ;
MATCH_AND_TRY_2:
  CALL TRY_IT             ; No instrument wanted: just try it
  JR MATCH_AND_TRY_1      ;
MATCH_AND_TRY_3:
  CALL NEXT_INSTRUMENT           ; The instruments in turn, keeping the first
  JR NZ,MATCH_AND_TRY_4          ;
  LD A,(INSTRUMENTS_FAILED)      ;
  CP $01                         ;
  RET NZ                         ;
  LD A,(FIRST_INSTRUMENT_FAILED) ;
  LD (INSTRUMENT),A              ;
  RET                            ;
MATCH_AND_TRY_4:
  LD A,(INSTRUMENT)              ;
  LD (FIRST_INSTRUMENT_FAILED),A ;
  LD HL,INSTRUMENTS_FAILED       ;
  INC (HL)                       ;
  JR MATCH_AND_TRY_3             ;

; Is the target one an EXCEPT phrase names?
;
; Used by the routine at PARSE_ACTION.
;
; Believed to be: it walks the frames above, and for each whose phrase is in
; use looks for its name among the objects (FIND_NAMED_OBJECT), comparing with
; the target in TARGET. NZ if one matches. Not traced in play.
EXCEPTED:
  PUSH IY
  PUSH DE
  PUSH HL
EXCEPTED_0:
  LD DE,$FFE8
  ADD IY,DE
  BIT 6,(IY+$01)
  JR Z,EXCEPTED_2
  LD IX,OBJECT_INDEX-$0003
EXCEPTED_1:
  PUSH IY
  POP HL
  LD DE,$0008
  ADD HL,DE
  CALL FIND_NAMED_OBJECT
  CP $FF
  JR Z,EXCEPTED_0
  LD HL,TARGET
  CP (HL)
  JR NZ,EXCEPTED_1
  OR $01
EXCEPTED_2:
  POP HL
  POP DE
  POP IY
  RET

; Start the search for the target from the beginning
;
; Used by the routine at PARSE_ACTION.
;
; From the first object, or, when the target is a place (TARGET_IS_PLACE), from
; the first exit (FIRST_EXIT); kept at TARGET_SEARCH. RESTART_TARGETS is the
; way in that does it whatever ALL_ACTION says.
START_TARGETS:
  LD A,(ALL_ACTION)
  AND A
  RET NZ
; This entry point is used by the routine at WOULD_WORK.
RESTART_TARGETS:
  LD A,(FLAGS_LAST_WORDS)
  RRCA
  RRCA
  CALL SEARCH_START
  LD A,(TARGET_IS_PLACE)
  AND A
  CALL NZ,FIRST_EXIT
  LD (TARGET_SEARCH),IX
  RET

; Start the search for the instrument from the beginning
;
; Used by the routine at MATCH_AND_TRY.
;
; The same for the second object, kept at INSTRUMENT_SEARCH.
START_INSTRUMENTS:
  LD A,(FLAGS_LAST_WORDS)
  CALL SEARCH_START
  LD A,(INSTRUMENT_IS_PLACE)
  AND A
  CALL NZ,FIRST_EXIT
  LD (INSTRUMENT_SEARCH),IX
  RET

; IX = where a search of the objects starts, for the mode in A's low bits
;
; Used by the routines at START_TARGETS and START_INSTRUMENTS.
;
; Mode 0 starts at the object index itself, anything else three bytes before
; it; not worked out further.
SEARCH_START:
  LD IX,OBJECT_INDEX
  AND $03
  RET Z
  LD IX,OBJECT_INDEX-$0003
  RET

; Does the sentence still want a target found?
;
; Used by the routines at MATCH_AND_TRY and TARGET_TROUBLE.
;
; Only for a pattern with a first object (bit 2 of FLAGS_FIRST_WORDS). Not yet
; worked out in full.
WANTS_TARGET:
  LD A,(FLAGS_FIRST_WORDS)
  BIT 2,A
  RET Z
  LD HL,INSTRUMENT_STATE
  BIT 0,(HL)
  RET NZ
  BIT 1,A
  JR NZ,WANTS_TARGET_0
  OR $01
  RET
WANTS_TARGET_0:
  XOR A
  RET

; Do the action; Z if it did not work
;
; Used by the routines at OBEY, MATCH_AND_TRY, TRY_INSTRUMENTS and TAKE_ORDER.
TRY_IT:
  CALL DO_ACTION
  LD A,(SUCCEEDED)
  AND A
  RET

; Would the action in ACTION to INSTRUMENT work? Try it as a test
;
; Used by the routine at ACTOR_TRIES.
;
; The action is run through DO_ACTION with DOING_IT clear. That flag is not
; only whether anything is printed: it is whether the action is done for real,
; and with it clear a handler only says, by setting SUCCEEDED, whether it would
; work -- the same test-then-do that SCRIPT_DO uses for a script's own
; routines. ACTOR_TRIES calls this first, and does the action for real only if
; it answers yes.
;
; Patterns with bits 2 or 3 of FLAGS_FIRST_WORDS, which have objects to be
; matched, go through MATCH_AND_TRY instead, not yet worked out.
;
; O:F NZ if it would work
WOULD_WORK:
  PUSH HL
  PUSH IY
  PUSH IX
  PUSH DE
  PUSH BC
  LD HL,(TARGET_SEARCH)   ; Keep TARGET_SEARCH
  PUSH HL                 ;
  LD A,(ACTION)           ; IX = the action's pattern
  CALL PATTERN_OF         ;
  PUSH HL                 ;
  POP IX                  ;
  CALL CLEAR_PHRASES      ; Not yet worked out
  CALL PATTERN_FLAGS      ;
  CALL PATTERN_OPTIONS    ;
  LD A,(TARGET)              ; The two objects' names, into TARGET_NAME and
  LD B,A                     ; INSTRUMENT_NAME
  LD A,(TARGET_IS_PLACE)     ;
  LD DE,TARGET_NAME          ;
  CALL NAME_OF_NUMBER        ;
  LD A,(INSTRUMENT)          ;
  LD B,A                     ;
  LD A,(INSTRUMENT_IS_PLACE) ;
  LD DE,INSTRUMENT_NAME      ;
  CALL NAME_OF_NUMBER        ;
  CALL RESTART_TARGETS    ; Not yet worked out
  XOR A                   ; Only a test
  LD (DOING_IT),A         ;
  LD A,(FLAGS_FIRST_WORDS) ; Objects to match? MATCH_AND_TRY
  AND $0C                  ;
  JR NZ,WOULD_WORK_0       ;
  CALL DO_ACTION          ; Otherwise try it: SUCCEEDED says whether it worked
  LD A,(SUCCEEDED)        ;
  AND A                   ;
  JR WOULD_WORK_2         ;
WOULD_WORK_0:
  LD A,$01                ; MATCH_AND_TRY answers instead
  LD (WITH_ALL),A         ;
  CALL MATCH_AND_TRY      ;
  JR Z,WOULD_WORK_1       ;
  XOR A                   ;
  JR WOULD_WORK_2         ;
WOULD_WORK_1:
  OR $01                  ; It would work
WOULD_WORK_2:
  LD A,$01                ; For real again
  LD (DOING_IT),A         ;
  POP HL
  LD (TARGET_SEARCH),HL
  POP BC
  POP DE
  POP IX
  POP IY
  POP HL
  RET

; Copy the name of object (or, with A set, location) B to DE
;
; Used by the routine at WOULD_WORK.
;
; How a character's action, which comes as object numbers, gets names in
; TARGET_NAME and INSTRUMENT_NAME like a typed sentence's. $FF copies nothing.
NAME_OF_NUMBER:
  INC B
  RET Z
  DEC B
  AND A
  LD A,B
  JR Z,NAME_OF_NUMBER_0
  CALL ROOM_NAME_AT
  JR NAME_OF_NUMBER_1
NAME_OF_NUMBER_0:
  CALL OBJECT_NAME_AT
NAME_OF_NUMBER_1:
  LD BC,$0006
  LDIR
  RET

; Set the action's options from its pattern's flags
;
; Used by the routines at PARSE_ACTION and WOULD_WORK.
;
; Four flags, from PATTERN_FLAGS. NEEDS_LIGHT: the action needs light at all --
; set for every hands-on action, TAKE, OPEN, EXAMINE, LOOK and INVENTORY among
; them, which DO_ACTION refuses in the dark ("i see nothing here."), where the
; rest can still be done to what the actor carries. TARGET_IS_PLACE: the first
; object is a place, not a thing -- ENTER and GO INTO. INSTRUMENT_IS_PLACE: the
; same for the second object, set by no action in the game. PATTERN_OPTION:
; TAKE OFF, FOLLOW and JUMP ONTO, used by the object matching at
; NEXT_INSTRUMENT and not yet worked out.
PATTERN_OPTIONS:
  LD A,(FLAGS_LAST_WORDS) ; NEEDS_LIGHT: needs light
  AND $40                 ;
  LD (NEEDS_LIGHT),A      ;
  LD A,(FLAGS_FIRST_WORDS) ; PATTERN_OPTION
  LD B,A                   ;
  AND $01                  ;
  LD (PATTERN_OPTION),A    ;
  LD A,B                  ; TARGET_IS_PLACE: the first object is a place
  AND $80                 ;
  JR Z,PATTERN_OPTIONS_0  ;
  LD A,$01                ;
PATTERN_OPTIONS_0:
  LD (TARGET_IS_PLACE),A  ;
  LD A,B                     ; INSTRUMENT_IS_PLACE: the second is
  AND $40                    ;
  JR Z,PATTERN_OPTIONS_1     ;
  LD A,$01                   ;
PATTERN_OPTIONS_1:
  LD (INSTRUMENT_IS_PLACE),A ;
  RET

; Find the action pattern a sentence fits
;
; Used by the routine at PARSE_ACTION.
;
; Four words are gathered from the frame at IY into a probe at PROBE_VERB --
; the verb with its ALL bit set aside at ALL_BIT, then a particle and a
; preposition from the two noun phrases (PICK_WORD) -- and ACTION_PATTERNS is
; searched with NAME_MATCHES for one that fits, so word order within the probe
; does not matter. A match goes on to ASSIGN_PHRASES. With none the verb does
; nothing: "you ... . time passes..." -- except in an order, which goes back to
; the parser at TURN_OVER instead.
;
; I:IY The sentence's frame
; O:IX The pattern
; O:F NZ if one was found
MATCH_PATTERN:
  PUSH IY
  LD L,(IY+$00)
  LD H,(IY+$01)
  LD A,H
  AND $80
  LD (ALL_BIT),A
  RES 7,H
  LD (PROBE_VERB),HL
  LD HL,PROBE_WORD1
  PUSH HL
  LD B,$04
  CALL CLEAR_BYTES
  POP HL
  LD B,$02
  LD E,$04
  CALL PICK_WORD
  LD E,$0E
  CALL PICK_WORD
  LD E,$06
  CALL PICK_WORD
  LD E,$10
  CALL PICK_WORD
  XOR A
  LD (NAME_FAILED),A
  LD HL,PROBE_VERB
  LD DE,$0008
  LD IX,ACTION_PATTERNS
MATCH_PATTERN_0:
  PUSH IX
  POP IY
  CALL NAME_MATCHES
  JR Z,MATCH_PATTERN_1
  ADD IX,DE
  LD A,(IX+$01)
  OR (IX+$00)
  JR NZ,MATCH_PATTERN_0
  POP IY
  LD A,(NAME_FAILED)
  AND A
  JP NZ,UNKNOWN_VERB
  LD HL,(PROBE_VERB)
  PUSH HL
  LD HL,MSG_YOU_TIME_PASSES
  XOR A
  LD (INPUT_STYLE),A
  LD (ALL_ACTION),A
  LD A,$01
  LD (DOING_IT),A
  CALL RUN_MESSAGE
  LD A,(IS_ORDER)
  DEC A
  RET Z
  POP HL
  POP HL
  JP TURN_OVER
MATCH_PATTERN_1:
  POP IY
  CALL ASSIGN_PHRASES
  OR $01
  RET

; Decide which noun phrase is the target and which the instrument
;
; Used by the routine at MATCH_PATTERN.
;
; The pattern's preposition is compared with the frame's two phrases'
; prepositions, and with bit 5 of the pattern's flags decides which of the two
; phrases -- at +4 or +14 in the frame -- is the target: it goes by where the
; preposition the pattern wants is found, not simply by which phrase came
; first. The phrases go to TARGET_NAME and INSTRUMENT_NAME, and the target's
; name is also kept at IT_NAME for IT.
ASSIGN_PHRASES:
  AND A
  JR Z,ASSIGN_PHRASES_0
  LD HL,(PROBE_WORD1)
  LD DE,(PROBE_WORD2)
  LD (PROBE_WORD1),DE
  LD (PROBE_WORD2),HL
ASSIGN_PHRASES_0:
  CALL PATTERN_FLAGS
  LD HL,PROBE_WORD1
  LD A,(HL)
  INC HL
  OR (HL)
  JR NZ,ASSIGN_PHRASES_1
  LD A,(FLAGS_LAST_WORDS)
  JR ASSIGN_PHRASES_4
ASSIGN_PHRASES_1:
  DEC HL
  LD A,(HL)
  CP (IY+$0E)
  JR NZ,ASSIGN_PHRASES_2
  INC HL
  LD A,(HL)
  CP (IY+$0F)
  JR Z,ASSIGN_PHRASES_3
  DEC HL
ASSIGN_PHRASES_2:
  LD A,(HL)
  CP (IY+$10)
  JR NZ,ASSIGN_PHRASES_3
  INC HL
  LD A,(HL)
  CP (IY+$11)
ASSIGN_PHRASES_3:
  LD A,(FLAGS_FIRST_WORDS)
  JR NZ,ASSIGN_PHRASES_5
ASSIGN_PHRASES_4:
  XOR $20
ASSIGN_PHRASES_5:
  BIT 5,A
  LD BC,$1208
  JR Z,ASSIGN_PHRASES_6
  LD BC,$0812
ASSIGN_PHRASES_6:
  LD HL,TARGET_PHRASE_AT
  LD (HL),B
  INC HL
  LD (HL),C
  LD A,B
  LD DE,TARGET_NAME
  LD HL,PHRASES
  CALL COPY_PHRASE
  LD A,C
  LD HL,TARGET_NAME
  LD DE,IT_NAME
  LD BC,$0006
  LDIR
  LD DE,INSTRUMENT_NAME
  LD HL,INSTRUMENT_STATE

; Copy a noun and its adjectives out of the command frame
;
; Used by the routine at ASSIGN_PHRASES.
;
; Six bytes from the frame offset in C -- 8 for the first noun phrase's noun,
; 18 for the second's -- into a slot, and sets bit 0 of the flag byte in HL if
; anything was there. The code before it chooses which phrase goes to
; TARGET_NAME and which to INSTRUMENT_NAME, by whether the second phrase's
; prepositions are the ones the command expects: ATTACK THE TROLL WITH THE
; SWORD makes the troll the target and the sword the instrument.
COPY_PHRASE:
  PUSH BC
  LD C,A                  ; HL = the phrase in the frame, at offset A
  LD B,$00                ;
  PUSH HL                 ;
  PUSH IY                 ;
  POP HL                  ;
  ADD HL,BC               ;
  LD BC,$0006             ; Copy its noun and two adjectives to DE
  LDIR                    ;
  XOR A                   ; Walk back over the six bytes just copied: were any
  LD B,$06                ; of them set?
COPY_PHRASE_0:
  DEC HL                  ;
  OR (HL)                 ;
  DJNZ COPY_PHRASE_0      ;
  POP HL
  POP BC
  RET Z                   ; No: nothing was named here
  SET 0,(HL)              ; Yes: set bit 0 of the flag byte
  RET

; Take the next word of a noun phrase that is not empty
;
; Used by the routine at MATCH_PATTERN.
;
; I:IY The frame
; I:E The offset of the word in it
; I:HL Where to put it
; I:B How many words may still be taken
PICK_WORD:
  XOR A
  CP B
  RET Z
  LD D,$00
  PUSH IY
  ADD IY,DE
  LD A,(IY+$00)
  LD (HL),A
  INC HL
  LD A,(IY+$01)
  LD (HL),A
  DEC HL
  OR (IY+$00)
  POP IY
  RET Z
  DEC B
  INC HL
  INC HL
  RET

; Call the routine IY points at
;
; Used by the routines at TRY_TARGETS and TRY_INSTRUMENTS.
;
; JP (IY), so a caller can choose the search: TRY_TARGETS uses
; FIND_NAMED_OBJECT.
CALL_IY:
  JP (IY)                 ; Whatever routine IY points at

; Try the next object that fits the target's name
;
; Used by the routine at MATCH_AND_TRY.
;
; TRY_TARGETS with FIND_NAMED_OBJECT as its finder, in the mode bits 2-3 of
; FLAGS_LAST_WORDS give (FIND_MODE) -- which kinds of object will do -- or with
; ROOM_BY_NAME when the target is a place.
;
; O:F NZ if one was found and tried
NEXT_TARGET:
  PUSH IY
  LD IX,(TARGET_SEARCH)   ; Where the search had got to; a place?
  LD A,(TARGET_IS_PLACE)  ;
  DEC A                   ;
  JR Z,NEXT_TARGET_1      ;
  LD IY,FIND_NAMED_OBJECT ; An object: FIND_NAMED_OBJECT, in the pattern's mode
  LD A,(FLAGS_LAST_WORDS) ;
  RRCA                    ;
  RRCA                    ;
  AND $03                 ;
  LD (FIND_MODE),A        ;
  CALL TRY_TARGETS        ;
  CP $FF                  ;
NEXT_TARGET_0:
  LD (TARGET_SEARCH),IX   ; Keep the place
  POP IY                  ;
  RET                     ;
NEXT_TARGET_1:
  LD IY,ROOM_BY_NAME      ; A place: ROOM_BY_NAME
  CALL TRY_TARGETS        ;
  CP $FF                  ;
  JR NEXT_TARGET_0        ;

; Try each object that fits the target's name
;
; Used by the routine at NEXT_TARGET.
;
; Finds the next object matching TARGET_NAME, makes it the target in TARGET,
; and tries the command on it; if that did not take, it goes round again for
; the next. So PICK UP THE KEY where there are several keys tries them in turn.
TRY_TARGETS:
  LD HL,TARGET_NAME       ; Next object fitting the target's name; none left,
  CALL CALL_IY            ; and the command fails
  CP $FF                  ;
  RET Z                   ;
  LD (TARGET),A           ; It is the target
  LD HL,PHRASES           ; Note that a target was found
  SET 1,(HL)              ;
  CALL HANDLED            ; Try the command on it
  LD A,(SUCCEEDED)        ; It did not take: try the next object that fits
  AND A                   ;
  JR Z,TRY_TARGETS        ;
  RET

; Try the next object that fits the instrument's name
;
; Used by the routine at MATCH_AND_TRY.
;
; The same for the second object, the mode from bits 0-1 of FLAGS_LAST_WORDS;
; PATTERN_OPTION is set from the pattern on the way out.
NEXT_INSTRUMENT:
  XOR A                      ; Where the search had got to; a place?
  LD (PATTERN_OPTION),A      ;
  PUSH IY                    ;
  LD IX,(INSTRUMENT_SEARCH)  ;
  LD A,(INSTRUMENT_IS_PLACE) ;
  DEC A                      ;
  JR Z,NEXT_INSTRUMENT_1     ;
  LD IY,FIND_NAMED_OBJECT ; An object, in the pattern's mode
  LD A,(FLAGS_LAST_WORDS) ;
  AND $03                 ;
  LD (FIND_MODE),A        ;
  CALL TRY_INSTRUMENTS    ;
  CP $FF                  ;
NEXT_INSTRUMENT_0:
  LD (INSTRUMENT_SEARCH),IX ; Keep the place; PATTERN_OPTION from the pattern
  POP IY                    ;
  PUSH AF                   ;
  LD A,(FLAGS_FIRST_WORDS)  ;
  AND $01                   ;
  LD (PATTERN_OPTION),A     ;
  POP AF                    ;
  RET                       ;
NEXT_INSTRUMENT_1:
  LD IY,ROOM_BY_NAME      ; A place
  CALL TRY_INSTRUMENTS    ;
  CP $FF                  ;
  JR NEXT_INSTRUMENT_0    ;

; TRY_TARGETS for the instrument: each object that fits INSTRUMENT_NAME in turn
;
; Used by the routine at NEXT_INSTRUMENT.
TRY_INSTRUMENTS:
  LD HL,INSTRUMENT_NAME
  CALL CALL_IY
  CP $FF
  RET Z
  LD (INSTRUMENT),A
  LD HL,INSTRUMENT_STATE
  SET 1,(HL)
  CALL TRY_IT
  JR Z,TRY_INSTRUMENTS
  RET

; For real, and in the input window: for the parser's own replies
;
; Used by the routines at ASK_WHICH and TARGET_TROUBLE.
PRINT_NOW:
  LD A,$01
  LD (DOING_IT),A
  LD (INPUT_STYLE),A
  RET

; Keep this sentence's frame, so that the next line can answer a question about
; it
;
; Used by the routines at ASK_WHICH, TARGET_TROUBLE and NO_INSTRUMENT.
;
; It is copied up to COMMAND_FRAME, and QUESTION_WAITING says a question is
; waiting.
KEEP_QUESTION:
  LD (QUESTION_WAITING),A
  PUSH IY
  POP HL
  LD DE,COMMAND_FRAME
  LD BC,$0018
  LDIR
  RET

; "which ... ?": more than one thing fits the name
;
; Used by the routine at TARGET_TROUBLE.
;
; The sentence is kept (KEEP_QUESTION) for the answer. ASK_WHICH_NAME is the
; way in with the name already chosen, and SAY_NOW the way in for any of the
; parser's replies.
ASK_WHICH:
  LD A,(TARGET_PHRASE_AT)
  LD HL,(TARGET_NAME)
; This entry point is used by the routine at INSTRUMENT_TROUBLE.
ASK_WHICH_NAME:
  PUSH HL
  CALL KEEP_QUESTION
  LD HL,MSG_WHICH
; This entry point is used by the routines at TARGET_TROUBLE, NO_INSTRUMENT and
; UNKNOWN_VERB.
SAY_NOW:
  CALL PRINT_NOW
  CALL RUN_MESSAGE
  XOR A
  RET

; The same for the instrument
;
; Used by the routine at TARGET_TROUBLE.
INSTRUMENT_TROUBLE:
  LD HL,INSTRUMENT_STATE
  BIT 0,(HL)
  JP Z,NO_INSTRUMENT
  BIT 1,(HL)
  LD HL,INSTRUMENT_NAME
  LD DE,INSTRUMENT
  LD BC,INSTRUMENT_IS_PLACE
  JR Z,TROUBLE_AS_PLACE
  LD A,(INSTRUMENTS_FAILED)
  AND A
  JP Z,SAY_WHY_NOT
  LD A,(INSTRUMENT_PHRASE_AT)
  LD A,(INSTRUMENT_NAME)
  JR ASK_WHICH_NAME

; The target's name did not lead to an action that worked: say why
;
; Used by the routine at PARSE_ACTION.
;
; Nothing in an order, which is left to the character. One thing fitted: that
; is the one, and the action is done for real so that its refusal is told.
; Several: ASK_WHICH. None: the name is looked for among the rooms the exits
; lead to and all the objects, and if it is there it is the refusal that is
; told; otherwise "i do not see the ... here". No name given at all: "i see
; nothing to ..." or "... what ?".
TARGET_TROUBLE:
  LD A,(IS_ORDER)
  DEC A
  RET Z
  LD A,(ALL_ACTION)
  AND A
  JR Z,TARGET_TROUBLE_0
  POP HL
  JP FRAME_DONE
TARGET_TROUBLE_0:
  LD A,(TARGETS_FAILED)
  CP $01
  JR Z,INSTRUMENT_TROUBLE
  LD HL,PHRASES
  BIT 0,(HL)
  JP Z,TARGET_TROUBLE_3
  BIT 1,(HL)
  LD HL,TARGET_NAME
  LD DE,TARGET
  LD BC,TARGET_IS_PLACE
  JR Z,TROUBLE_AS_PLACE
  LD A,(TARGETS_FOUND)
  AND A
  JR Z,SAY_WHY_NOT
  DEC A
  JR NZ,ASK_WHICH
  CALL WANTS_TARGET
  JR NZ,INSTRUMENT_TROUBLE
; This entry point is used by the routines at OBEY and INSTRUMENT_TROUBLE.
SAY_WHY_NOT:
  CALL PRINT_NOW
  CALL DO_ACTION
  JP OBEY_NEXT
; This entry point is used by the routine at INSTRUMENT_TROUBLE.
TROUBLE_AS_PLACE:
  PUSH HL
  CALL FIRST_EXIT
  LD A,$01
  LD (BC),A
  CALL ROOM_BY_NAME
  CP $FF
  JR NZ,TARGET_TROUBLE_1
  POP HL
  LD A,$02
  LD (FIND_MODE),A
  LD IX,OBJECT_INDEX-$0003
  XOR A
  LD (BC),A
  PUSH HL
  CALL FIND_NAMED_OBJECT
  CP $FF
  JR Z,TARGET_TROUBLE_2
TARGET_TROUBLE_1:
  POP HL
  LD (DE),A
  JP NARRATE_REFUSAL
TARGET_TROUBLE_2:
  CALL PRINT_NOW
  LD HL,MSG_I_DO_NOT_SEE
  CALL RUN_MESSAGE
  XOR A
  RET
TARGET_TROUBLE_3:
  CALL PUSH_PATTERN_WORDS_NZ
  LD HL,(PROBE_VERB)
  PUSH HL
  LD HL,MSG_CODES_ONLY_B
  LD A,(TARGETS_FAILED)
  AND A
  JP Z,SAY_NOW
  LD A,(TARGET_PHRASE_AT)
  CALL KEEP_QUESTION
  LD HL,MSG_WHAT_C
  JP SAY_NOW

; No instrument named: "i see nothing to ... with" or "... with what ?"
;
; Used by the routine at INSTRUMENT_TROUBLE.
NO_INSTRUMENT:
  CALL PUSH_PATTERN_WORDS
  LD HL,$0000
  PUSH HL
  LD A,(TARGET)
  CALL OBJECT_NAME_AT
  PUSH HL
  CALL PUSH_PATTERN_WORDS_NZ
  LD HL,(PROBE_VERB)
  PUSH HL
  LD HL,MSG_CODES_ONLY_C
  LD A,(INSTRUMENTS_FAILED)
  AND A
  JP Z,SAY_NOW
  LD A,(INSTRUMENT_PHRASE_AT)
  CALL KEEP_QUESTION
  LD HL,MSG_WHAT_B
  JP SAY_NOW

; Push the pattern's particle and preposition, for a reply
;
; Used by the routine at NO_INSTRUMENT.
;
; Each only if the pattern's flags say it is there; the tests are JR Z or JR
; NZ, as PUSH_PATTERN_WORDS and PUSH_PATTERN_WORDS_NZ write them into the code
; at THIRD_WORD_TEST and SECOND_WORD_TEST.
PUSH_PATTERN_WORDS:
  LD A,$28
  JR SET_WORD_TESTS

; PUSH_PATTERN_WORDS, with its tests the other way round (JR NZ)
;
; Used by the routines at TARGET_TROUBLE and NO_INSTRUMENT.
PUSH_PATTERN_WORDS_NZ:
  LD A,$20
; This entry point is used by the routine at PUSH_PATTERN_WORDS.
SET_WORD_TESTS:
  LD (THIRD_WORD_TEST),A
  LD (SECOND_WORD_TEST),A
  LD IX,(PATTERN)
  LD L,(IX+$04)
  LD H,(IX+$05)
  BIT 7,(IX+$07)
THIRD_WORD_TEST:
  JR NZ,PUSH_PATTERN_WORDS_NZ_0
  LD HL,$0000
PUSH_PATTERN_WORDS_NZ_0:
  EX (SP),HL
  PUSH HL
  LD L,(IX+$02)
  LD H,(IX+$03)
  BIT 5,H
SECOND_WORD_TEST:
  JR NZ,PUSH_PATTERN_WORDS_NZ_1
  LD HL,$0000
PUSH_PATTERN_WORDS_NZ_1:
  EX (SP),HL
  JP (HL)

; "i do not know the verb "...""
;
; Used by the routine at MATCH_PATTERN.
UNKNOWN_VERB:
  LD HL,(PROBE_WORD2)
  PUSH HL
  LD HL,(PROBE_WORD1)
  PUSH HL
  LD HL,(PROBE_VERB)
  PUSH HL
  LD HL,MSG_I_DO_NOT_KNOW_B
  JP SAY_NOW

; Give A of the sentences just said to the character in TARGET
;
; Used by the routine at DO_TALK.
;
; The sentences waiting in ORDERS -- ORDER_COUNT of them, marked $FF -- are
; given to the character in turn, as many as A says, and the rest are thrown
; away.
;
; I:A How many to give
ASSIGN_ORDERS:
  PUSH BC
  PUSH IX
  PUSH DE
  LD B,A                  ; No more than there are; C = how many are left over
  LD A,(ORDER_COUNT)      ;
  LD C,A                  ;
  CP B                    ;
  JR NC,ASSIGN_ORDERS_0   ;
  LD B,A                  ;
ASSIGN_ORDERS_0:
  LD A,C                  ;
  SUB B                   ;
  LD C,A                  ;
  LD IX,ORDERS-$0019      ; The next A waiting are the character's
  LD DE,$0019             ;
  XOR A                   ;
  CP B                    ;
  JR Z,ASSIGN_ORDERS_2    ;
ASSIGN_ORDERS_1:
  ADD IX,DE               ;
  LD A,(IX+$00)           ;
  CP $FF                  ;
  JR NZ,ASSIGN_ORDERS_1   ;
  LD A,(TARGET)           ;
  LD (IX+$00),A           ;
  DJNZ ASSIGN_ORDERS_1    ;
ASSIGN_ORDERS_2:
  LD B,C                  ; The rest are thrown away
  XOR A                   ;
  CP B                    ;
  JR Z,ASSIGN_ORDERS_4    ;
ASSIGN_ORDERS_3:
  ADD IX,DE               ;
  LD A,(IX+$00)           ;
  CP $FF                  ;
  JR NZ,ASSIGN_ORDERS_3   ;
  LD (IX+$00),$00         ;
  DJNZ ASSIGN_ORDERS_3    ;
ASSIGN_ORDERS_4:
  POP DE
  POP IX
  POP BC
  RET

; Find an order waiting for the character in ACTING
;
; Used by the routines at HAS_ORDER and TAKE_ORDER.
;
; O:HL Its slot in ORDERS
; O:F Z if there is one
FIND_ORDER:
  LD HL,ORDERS
  LD DE,$0019
  LD A,(ACTING)
  LD B,$08
FIND_ORDER_0:
  CP (HL)
  RET Z
  ADD HL,DE
  DJNZ FIND_ORDER_0
  RET

; Is there an order waiting for the character in ACTING?
;
; Used by the routine at CHARACTERS_ACT.
;
; O:F Z if there is one
HAS_ORDER:
  PUSH HL
  PUSH DE
  PUSH BC
  CALL FIND_ORDER
  POP BC
  POP DE
  POP HL
  RET

; Take the order waiting for a character, and parse it
;
; Used by the routines at CHARACTERS_ACT, BARD_TAKES_ORDER and
; GOLLUM_HEARS_ANSWER.
;
; Frees the slot, then parses the command kept in it the way the player's own
; commands are parsed, leaving the action and its objects in ACTION to
; INSTRUMENT for ACTOR_TRIES.
TAKE_ORDER:
  PUSH IX
  PUSH IY
  PUSH BC
  PUSH DE
  PUSH HL
  LD C,A
  CALL FIND_ORDER         ; Free the slot
  LD (HL),$00             ;
  INC HL
  XOR A
  CP C
  JR NZ,TAKE_ORDER_1
  OR $01
  EX (SP),HL
TAKE_ORDER_0:
  POP HL
  POP DE
  POP BC
  POP IY
  POP IX
  RET
TAKE_ORDER_1:
  PUSH HL
  POP IY
  LD A,$01
  LD (IS_ORDER),A
  LD A,(ALL_ACTION)
  PUSH AF
  CALL PARSE_ACTION
  EX AF,AF'
  XOR A
  LD (IS_ORDER),A
  POP AF
  LD (ALL_ACTION),A
  EX AF,AF'
  JR Z,TAKE_ORDER_2
  CALL TRY_IT
  JR NZ,TAKE_ORDER_0
TAKE_ORDER_2:
  LD A,(ACTING)
  CALL CANCEL_ORDERS
  XOR A
  JR TAKE_ORDER_0

; Throw away any orders waiting for character A
;
; Used by the routines at TAKE_ORDER and KILL.
;
; KILL does this, so that the dead do not act on what they were told.
CANCEL_ORDERS:
  PUSH HL
  PUSH DE
  PUSH BC
  LD HL,ORDERS
  LD DE,$0019
  LD B,$08
CANCEL_ORDERS_0:
  CP (HL)
  JR NZ,CANCEL_ORDERS_1
  LD (HL),$00
CANCEL_ORDERS_1:
  ADD HL,DE
  DJNZ CANCEL_ORDERS_0
  POP BC
  POP DE
  POP HL
  RET

; Whether DRAW_LOCATION_PICTURE drew anything
;
; $FF with pictures off; otherwise what FIND_RECORD left in A, nonzero if the
; location has a picture. DESCRIBE_LOCATION waits for a key after the picture
; unless this is $FF.
PICTURE_SHOWN:
  DEFB $00

; Draw the current location's picture
;
; Used by the routine at DESCRIBE_LOCATION.
;
; Looks the location up in the picture table at PICTURE_TABLE, takes the stream
; pointer out of the record and runs it. Does nothing at all if the byte at
; PICTURES_ON is zero, which is believed to be the graphics on/off flag -- v1.2
; was also sold as a text-only edition, and this is the only test standing
; between a location change and the whole of the drawing code.
;
; O:A The value stored at PICTURE_SHOWN, from the table lookup
DRAW_LOCATION_PICTURE:
  PUSH AF
  LD A,(PICTURES_ON)      ; PICTURES_ON: nonzero to draw pictures at all
                          ; (believed the graphics flag)
  AND A
  JR NZ,DRAW_LOCATION_PICTURE_0
  LD A,$FF
  LD (PICTURE_SHOWN),A
  POP AF
  RET
DRAW_LOCATION_PICTURE_0:
  POP AF
  PUSH AF
  PUSH HL
  PUSH BC
  PUSH DE
  PUSH IX
  LD IX,PICTURE_TABLE     ; The picture table, indexed by location
  CALL FIND_RECORD        ; Find this location's record; returns NZ if it has a
                          ; picture
  LD (PICTURE_SHOWN),A
  LD L,(IX+$01)           ; HL = the stream pointer, from bytes 1 and 2 of the
  LD H,(IX+$02)           ; record
  CALL NZ,RUN_PICTURE     ; Only run the stream if the lookup found a record
  POP IX
  POP DE
  POP BC
  POP HL
  POP AF
  RET

; Interpret a picture stream
;
; Used by the routine at DRAW_LOCATION_PICTURE.
;
; IY walks the stream; D and E are the current point, in a 256x128 space with y
; measured upwards from scanline 127. The opcodes are: $00 end, $08 move, $2x
; paint attributes, $4x flood fill, and anything with bit 7 set a line. Bits
; 0-2 of a fill or paint opcode are its colour.
;
; A line is two bytes, and both are split: the opcode byte carries the
; direction in bits 0-2 and part of the minor-axis step in bits 2-5, while the
; second byte carries the length in bits 0-5 and the last two step bits in bits
; 6-7. That is a Bresenham line of up to 64 pixels in 16 bits.
;
; I:HL The start of the stream
RUN_PICTURE:
  PUSH IY
  PUSH HL
  PUSH HL
  POP IY
  PUSH DE
  PUSH BC
  CALL CLEAR_CANVAS       ; Clear the canvas and take the border and attribute
                          ; bytes off the front
  LD D,$7F                ; The point a stream starts from if it draws before
  LD E,$3F                ; it moves: (127, 63)
  LD B,$01                ;
  LD C,$01                ;
  LD L,$01                ;
RUN_PICTURE_0:
  LD A,(IY+$00)
  AND A
  JP Z,PICTURE_DONE       ; $00: end of the picture
  INC IY
  CP $08                  ; $08: move...
  JR NZ,RUN_PICTURE_1
  LD D,(IY+$00)           ; ...to the point in the next two bytes
  INC IY                  ;
  LD E,(IY+$00)           ;
  INC IY                  ;
  JR RUN_PICTURE_0
RUN_PICTURE_1:
  BIT 7,A
  JR Z,RUN_PICTURE_2
  LD B,A
  AND $07                 ; A line: bits 0-2 of the opcode are the direction
  LD C,A                  ;
  LD A,B                  ; Bits 2-5 of it are part of the minor-axis step
  RRCA                    ;
  AND $3C                 ;
  LD B,A                  ;
  LD A,(IY+$00)           ; The second byte's bits 0-5 are the length, plus one
  AND $3F                 ;
  LD L,A                  ;
  INC L                   ;
  LD A,(IY+$00)           ; ...and its bits 6-7 are the rest of the step
  INC IY                  ;
  RLCA                    ;
  RLCA                    ;
  AND $03                 ;
  OR B                    ;
  LD B,A                  ;
  INC B                   ;
  CALL DRAW_LINE          ; Draw it
  JR RUN_PICTURE_0
RUN_PICTURE_2:
  BIT 6,A
  JR Z,RUN_PICTURE_3
  AND $07                 ; Bit 6 set: a flood fill; bits 0-2 are its colour
  PUSH DE
  LD D,(IY+$00)           ; The fill's seed point, from the next two bytes
  INC IY                  ;
  LD E,(IY+$00)           ;
  INC IY                  ;
  CALL FLOOD_FILL         ; Fill from there
  POP DE                  ; The fill does not move the current point
  JP RUN_PICTURE_0
RUN_PICTURE_3:
  BIT 5,A
  JP Z,RUN_PICTURE_0
  AND $07                 ; Bit 5 set: paint attribute cells; bits 0-2 are the
                          ; colour
  RLCA
  RLCA
  RLCA
  PUSH HL
  PUSH DE
  PUSH BC
  LD C,A
  LD H,(IY+$00)           ; HL = the first attribute address, stored high byte
  INC IY                  ; first
  LD L,(IY+$00)           ;
  INC IY
RUN_PICTURE_4:
  LD A,(IY+$00)
  INC IY
  CP $FF                  ; $FF ends the path
  JR Z,RUN_PICTURE_7
  LD B,A
  AND $03
  LD E,A
  LD A,B                  ; Each path item: bits 0-1 the direction, bits 2-7
  RRCA                    ; the count
  RRCA                    ;
  AND $3F                 ;
  INC A                   ;
  LD B,A                  ;
RUN_PICTURE_5:
  LD A,(HL)               ; Keep the cell's ink out of its paper, so a colour
  AND $07                 ; can never hide the lines
  RLCA                    ;
  RLCA                    ;
  RLCA                    ;
  CP C                    ;
  JR NZ,RUN_PICTURE_6     ;
  XOR $38                 ;
RUN_PICTURE_6:
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  OR C                    ;
  LD (HL),A               ;
  LD A,E
  AND A
  CALL Z,ATTR_UP
  DEC A
  CALL Z,ATTR_RIGHT
  DEC A
  CALL Z,ATTR_DOWN
  DEC A
  CALL Z,ATTR_LEFT
  DJNZ RUN_PICTURE_5
  JR RUN_PICTURE_4
RUN_PICTURE_7:
  POP BC
  POP DE
  POP HL
  JP RUN_PICTURE_0
; This entry point is used by the routine at CLEAR_CANVAS.
PICTURE_DONE:
  POP BC
  POP DE
  POP HL
  POP IY
  RET

; FLOOD_FILL's two flags for the run it is filling
;
; Set once a seed point has been pushed for the row above, and for the row
; below, so that a stretch of empty pixels there is queued once rather than at
; every pixel; cleared again where the run meets ink.
SEEDED_ABOVE:
  DEFB $00                ; The row above
SEEDED_BELOW:
  DEFB $00                ; The row below

; Flood fill from a seed point
;
; Used by the routine at RUN_PICTURE.
;
; A boundary fill that uses the machine stack as its queue of pending points:
; $0080 is pushed first as a sentinel, seed points are PUSHed as they are
; found, and the loop ends when the POP brings the sentinel back -- an E of $80
; cannot otherwise occur, since y only goes up to 127.
;
; Every neighbour test goes through PIXEL_SET, which recomputes the screen
; address from scratch, and a pixel gets tested from each of the four
; directions it can be reached from. That, rather than the plotting, is what
; makes a large fill slow.
;
; I:A The ink to fill with
; I:DE The seed point
FLOOD_FILL:
  LD (PLOT_INK),A         ; Remember the ink for PLOT_PIXEL
  PUSH DE
  PUSH HL
  LD HL,$0080             ; The sentinel that ends the fill
  PUSH HL                 ;
FLOOD_FILL_0:
  CALL PIXEL_SET
  JR NZ,FLOOD_FILL_1
  CALL DEC_X
  JR NZ,FLOOD_FILL_0
  JR FLOOD_FILL_2
FLOOD_FILL_1:
  CALL PLOT_PIXEL
  CALL INC_X
FLOOD_FILL_2:
  LD HL,$0000
  LD (SEEDED_ABOVE),HL
FLOOD_FILL_3:
  CALL INC_Y
  LD A,$00
  JR Z,FLOOD_FILL_5
  CALL PIXEL_SET
  LD A,$00
  JR NZ,FLOOD_FILL_4
  LD A,(SEEDED_ABOVE)
  AND A
  JR NZ,FLOOD_FILL_4
  PUSH DE
  LD A,$01
FLOOD_FILL_4:
  PUSH AF
  CALL DEC_Y
  POP AF
FLOOD_FILL_5:
  LD (SEEDED_ABOVE),A
  CALL DEC_Y
  LD A,$00
  JR Z,FLOOD_FILL_7
  CALL PIXEL_SET
  LD A,$00
  JR NZ,FLOOD_FILL_6
  LD A,(SEEDED_BELOW)
  AND A
  JR NZ,FLOOD_FILL_6
  PUSH DE
  LD A,$01
FLOOD_FILL_6:
  PUSH AF
  CALL INC_Y
  POP AF
FLOOD_FILL_7:
  LD (SEEDED_BELOW),A
  CALL PLOT_PIXEL
  CALL INC_X
  JR Z,FLOOD_FILL_8
  CALL PIXEL_SET
  JR Z,FLOOD_FILL_3
  CALL PLOT_PIXEL
FLOOD_FILL_8:
  POP DE                  ; Sentinel back off the stack: the fill is done
  LD A,E                  ;
  CP $80                  ;
  JR NZ,FLOOD_FILL_0
  LD A,$00
  LD (PLOT_INK),A
  POP HL
  POP DE
  RET

; Is the pixel at (D,E) set?
;
; Used by the routine at FLOOD_FILL.
;
; Returns NZ if it is. Two instructions around PIXEL_ADDRESS, and the fill's
; inner loop.
PIXEL_SET:
  PUSH HL
  CALL PIXEL_ADDRESS      ; Address and mask for (D,E), and test that bit on
  AND (HL)                ; the screen
  POP HL
  RET

; Up one attribute row, if it can
;
; Used by the routine at RUN_PICTURE.
ATTR_UP:
  PUSH AF
  PUSH DE
  LD DE,$0020             ; Up a row: 32 cells back
  AND A                   ;
  SBC HL,DE               ;
  LD A,H                  ; Above $5800? Then undo it
  CP $57                  ;
  JR NZ,ATTR_UP_0         ;
  ADD HL,DE               ;
ATTR_UP_0:
  POP DE
  POP AF
  RET

; Down one attribute row, if it can
;
; Used by the routine at RUN_PICTURE.
ATTR_DOWN:
  PUSH AF
  PUSH DE
  LD DE,$0020             ; Down a row: 32 cells on
  ADD HL,DE               ;
  LD A,H                  ; Still within the picture's rows? Then jump into the
  CP $5A                  ; middle of the SBC below...
  JR NZ,ROW_UNDO+$0001    ;
  AND A                   ; ...whose second byte, $52, is LD D,D: a one-byte
ROW_UNDO:
  SBC HL,DE               ; no-op. Reached from the top it undoes the move;
                          ; from the JR it is skipped
  POP DE
  POP AF
  RET

; Left one cell, if it can
;
; Used by the routine at RUN_PICTURE.
ATTR_LEFT:
  PUSH AF
  DEC HL                  ; Left one cell; undo it above $5800
  LD A,H                  ;
  CP $57                  ;
  JR NZ,ATTR_LEFT_0       ;
  INC HL                  ;
ATTR_LEFT_0:
  POP AF
  RET

; Right one cell, if it can
;
; Used by the routine at RUN_PICTURE.
ATTR_RIGHT:
  PUSH AF
  INC HL                  ; Right one cell; undo it past the picture's rows
  LD A,H                  ;
  CP $5A                  ;
  JR NZ,ATTR_RIGHT_0      ;
  DEC HL                  ;
ATTR_RIGHT_0:
  POP AF
  RET

; Move the point up one, if it can
;
; Used by the routines at FLOOD_FILL and DRAW_LINE.
;
; y is 0-127, so bit 7 going high means it would leave the canvas: the move is
; undone and A returned with its low bit clear. Otherwise the low bit is set.
; The callers test that bit rather than the flags, which is why both exits go
; through the same tail.
INC_Y:
  INC E                   ; Up one; did y pass 127?
  BIT 7,E                 ;
  JR Z,Y_MOVED            ;
  DEC E                   ; Yes: undo it, and return A with bit 0 clear
  LD H,A                  ;
  XOR A                   ;
  LD A,H                  ;
  RET                     ;
; This entry point is used by the routine at DEC_Y.
Y_MOVED:
  LD H,A                  ; No: return A with bit 0 set (DEC_Y shares this)
  OR $01                  ;
  LD A,H                  ;
  RET                     ;

; Move the point down one, if it can
;
; Used by the routines at FLOOD_FILL and DRAW_LINE.
;
; Same test and the same shared tail as INC_Y: DEC E to $FF also shows up in
; bit 7.
DEC_Y:
  DEC E                   ; Down one; still 0-127?
  BIT 7,E                 ;
  JR Z,Y_MOVED            ;
  INC E                   ; No: undo it
  RET

; Move the point right one, if it can
;
; Used by the routines at FLOOD_FILL and DRAW_LINE.
;
; x is a whole byte, so the only edge is the wrap to zero.
INC_X:
  INC D                   ; Right one; fine unless it wrapped to 0
  RET NZ                  ;
  DEC D                   ; Wrapped: undo it, bit 0 of A clear
  LD H,A                  ;
  XOR A                   ;
  LD A,H                  ;
  RET

; Move the point left one, if it can
;
; Used by the routines at FLOOD_FILL and DRAW_LINE.
DEC_X:
  DEC D                   ; Left one; fine unless it wrapped to 255
  LD H,A                  ;
  LD A,D                  ;
  CP $FF                  ;
  LD A,H                  ;
  RET NZ                  ;
  INC D                   ; Wrapped: undo it
  RET

; Draw a line
;
; Used by the routine at RUN_PICTURE.
;
; A Bresenham stepper in two mirrored halves, picked by bit 0 of C: one walks x
; as the major axis, the other y. Bit 1 of C is the y direction and bit 2 the x
; direction. B counts down to the next minor-axis step and is reloaded from the
; stack each time it runs out; L counts the pixels.
;
; It already steps the coordinates one at a time, so it knows exactly where the
; next pixel is -- and then calls PLOT_PIXEL, which throws that away and
; recomputes the address from the coordinates. Carrying the address and mask
; along the line instead is where the large win is.
;
; I:DE The point to start from
; I:C Direction flags: bit 0 major axis, bit 1 y, bit 2 x
; I:B Minor-axis step counter
; I:L Length in pixels
DRAW_LINE:
  BIT 0,C                 ; Which axis is the major one
  JR NZ,DRAW_LINE_7
  PUSH HL                 ; x-major from here
  PUSH BC                 ;
DRAW_LINE_0:
  CALL PLOT_PIXEL
  BIT 2,C
  JR Z,DRAW_LINE_1
  CALL DEC_X
  JR Z,DRAW_LINE_6
  JR DRAW_LINE_2
DRAW_LINE_1:
  CALL INC_X
  JR Z,DRAW_LINE_6
DRAW_LINE_2:
  DEC B
  JR NZ,DRAW_LINE_5
  BIT 1,C
  JR Z,DRAW_LINE_3
  CALL DEC_Y
  JR Z,DRAW_LINE_6
  JR DRAW_LINE_4
DRAW_LINE_3:
  CALL INC_Y
  JR Z,DRAW_LINE_6
DRAW_LINE_4:
  POP BC
  PUSH BC
DRAW_LINE_5:
  DEC L
  JR NZ,DRAW_LINE_0
DRAW_LINE_6:
  POP BC
  POP HL
  RET
DRAW_LINE_7:
  PUSH HL                 ; y-major from here
  PUSH BC                 ;
DRAW_LINE_8:
  CALL PLOT_PIXEL
  BIT 1,C
  JR Z,DRAW_LINE_9
  CALL DEC_Y
  JR Z,DRAW_LINE_14
  JR DRAW_LINE_10
DRAW_LINE_9:
  CALL INC_Y
  JR Z,DRAW_LINE_14
DRAW_LINE_10:
  DEC B
  JR NZ,DRAW_LINE_13
  BIT 2,C
  JR Z,DRAW_LINE_11
  CALL DEC_X
  JR Z,DRAW_LINE_14
  JR DRAW_LINE_12
DRAW_LINE_11:
  CALL INC_X
  JR Z,DRAW_LINE_14
DRAW_LINE_12:
  POP BC
  PUSH BC
DRAW_LINE_13:
  DEC L
  JR NZ,DRAW_LINE_8
DRAW_LINE_14:
  POP BC
  POP HL
  RET

; Plot a pixel and colour its cell
;
; Used by the routines at FLOOD_FILL and DRAW_LINE.
;
; Sets the pixel at (D,E) and fixes the attribute of the cell it lands in,
; taking the wanted ink from PLOT_INK. The cell's existing ink is compared
; against the wanted one and flipped if they match, so a line can never be
; drawn in the colour it is drawn on.
PLOT_PIXEL:
  PUSH HL
  CALL PIXEL_ADDRESS      ; Address and mask for the point
  PUSH AF
  PUSH HL
  LD A,H                  ; Screen address to attribute address, the usual way
  AND $18                 ;
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  ADD A,$58               ;
  LD H,A                  ;
  LD A,(HL)               ; Keep the paper, drop the old ink
  AND $38                 ;
  LD (HL),A               ;
  LD A,(PLOT_INK)         ; The ink this picture is being drawn in
  RLCA
  RLCA
  RLCA
  CP (HL)                 ; Same as the paper? Then flip it rather than draw
  JR NZ,PLOT_PIXEL_0      ; invisibly
  XOR $38
PLOT_PIXEL_0:
  RRCA
  RRCA
  RRCA
  OR (HL)
  LD (HL),A
  POP HL
  POP AF
  OR (HL)                 ; Finally set the pixel itself
  LD (HL),A               ;
  POP HL
  RET

; Screen address and bit mask for a point
;
; Used by the routines at PIXEL_SET and PLOT_PIXEL.
;
; Given the point in D and E, returns the screen address in HL and a one-bit
; mask in A. y is measured upwards, so the first thing it does is turn E into a
; scanline with $7F - E; the rest is the usual Spectrum interleave, bits 6-7 of
; the scanline to the address's high byte and bits 3-5 to its low.
;
; This is the most expensive routine in the game -- 52% of the time spent
; drawing a room -- and it is called per pixel, by PLOT_PIXEL for every pixel
; drawn and by PIXEL_SET for every pixel the flood fill tests. About 269
; T-states a call, of which the mask loop below is a third.
;
; I:D x, 0-255
; I:E y, 0-127, measured up from scanline 127
; O:HL The screen address
; O:A The bit mask for x within that byte
PIXEL_ADDRESS:
  LD A,$7F                ; Scanline = $7F - y
  SUB E                   ;
  LD L,A                  ;
  AND $07
  OR $40
  LD H,A
  LD A,L                  ; The scanline's bits 6-7 into the address's high
  AND $C0                 ; byte
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  OR H                    ;
  LD H,A
  LD A,L                  ; Its bits 3-5 into the low byte
  AND $38                 ;
  RLCA                    ;
  RLCA                    ;
  LD L,A                  ;
  LD A,D                  ; x >> 3 gives the byte across
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  AND $1F                 ;
  OR L                    ;
  LD L,A                  ;
  LD A,D                  ; x & 7 selects the bit...
  AND $07                 ;
  PUSH BC
  LD B,A
  INC B
  LD A,$01
PIXEL_ADDRESS_0:
  RRC A                   ; ...by rotating a single bit that many places, one
  DJNZ PIXEL_ADDRESS_0    ; place at a time
  POP BC
  RET
; The whole routine is a candidate for two lookup tables and an 8-byte mask
; table, which would roughly halve it. There is no room above the game for them
; -- the payload ends at $FC3F and the 960 bytes above that are live workspace
; -- but the printer buffer at $5B00 is page-aligned and unused, since RAMTOP
; is at $5FFF and nothing here prints.

; Take the stream's header off and clear the canvas
;
; Used by the routine at RUN_PICTURE.
;
; Two header bytes: the border colour, then the attribute the picture area
; starts as. The clear is exactly the picture's own extent and no more --
; $4000-$4FFF is the top 128 scanlines, $5800-$59FF the top 16 character rows
; -- which leaves the text window below it untouched.
;
; The carry from the routine at TOO_DARK decides whether the picture is drawn
; in its own colours or blacked out, and if it comes back clear this drops the
; interpreter's return address and leaves through its exit, so the stream is
; never run.
CLEAR_CANVAS:
  CALL TOO_DARK
  EX AF,AF'
  LD A,(IY+$00)           ; Border colour, from the stream
  INC IY
  EX AF,AF'
  JR NC,CLEAR_CANVAS_0
  EX AF,AF'
  XOR A
  EX AF,AF'
CLEAR_CANVAS_0:
  EX AF,AF'
  OUT ($FE),A
  PUSH HL
  PUSH DE
  PUSH BC
  LD HL,$4000             ; Clear the top 128 scanlines
  LD DE,$4001             ;
  LD BC,$0FFF             ;
  LD (HL),$00             ;
  LDIR                    ;
  LD HL,$5800             ; ...and the top 16 character rows
  LD DE,$5801
  LD BC,$01FF
  LD A,(IY+$00)           ; The starting attribute, from the stream, filled
                          ; over them
  INC IY
  EX AF,AF'
  JR NC,CLEAR_CANVAS_1
  EX AF,AF'
  XOR A
  EX AF,AF'
CLEAR_CANVAS_1:
  EX AF,AF'
  LD (HL),A
  LDIR
  POP BC
  POP DE
  POP HL
  EX AF,AF'
  RET NC
  POP HL                  ; Carry clear: abandon the picture through the
  JP PICTURE_DONE         ; interpreter's own exit

; The ink PLOT_PIXEL and the fill are drawing in
;
; Set from bits 0-2 of a fill opcode for as long as that fill runs, and put
; back to zero afterwards. The two bytes after it are the quote mark's: see
; SPECIAL_QUOTE.
PLOT_INK:
  DEFB $38                ; The ink
ORDER_SAVED_D:
  DEFB $00                ; D, kept by ORDER_BEGINS while an order is parsed
ORDER_FIRST_FRAME:
  DEFB $00                ; COMMAND_FRAMES when the order began: its commands
                          ; are the frames after

; Parse a quantifier, pronoun or game command
PARSE_SPECIAL:
  LD HL,SPECIAL_WORDS     ; Search SPECIAL_WORDS, 13 of them
  PUSH DE                 ;
  LD D,$0D                ;
PARSE_SPECIAL_0:
  LD A,(HL)               ; Match the low byte, then the high
  INC HL                  ;
  CP C                    ;
  JR NZ,PARSE_SPECIAL_1   ;
  LD A,(HL)               ;
  CP B                    ;
  JR Z,PARSE_SPECIAL_2    ;
PARSE_SPECIAL_1:
  INC HL                  ;
  DEC D                   ;
  JR NZ,PARSE_SPECIAL_0   ;
  JP PARSE_NEXT_COMMAND   ; Not there: start the command again
PARSE_SPECIAL_2:
  LD DE,$0019             ; Found: jump to its handler, 26 bytes on
  ADD HL,DE               ;
  LD E,(HL)               ;
  INC HL                  ;
  LD D,(HL)               ;
  EX DE,HL                ;
  POP DE                  ;
  JP (HL)                 ;

; The special words, and what PARSE_SPECIAL does with each
;
; Thirteen word references, then a handler for each, reached through JP (HL) --
; so the handlers are code seeds. Among them are the game's own commands: SAVE
; and LOAD, which the playthrough never types, QUIT, PAUSE, HELP, SCORE, and
; PRINT and NOPRINT. Slot 0 holds no word -- the reference zero -- and that is
; what a quote mark comes through the tokeniser as: its handler is
; SPECIAL_QUOTE's. ONE's handler just goes on to the next word.
SPECIAL_WORDS:
  DEFW $0000              ; NO WORD
  DEFW $004E              ; ALL
  DEFW $0245              ; EXCEPT
  DEFW $039E              ; IT
  DEFW $04AD              ; ONE
  DEFW $04FB              ; PRINT
  DEFW $0479              ; NOPRINT
  DEFW $03EE              ; LOAD
  DEFW $0580              ; SAVE
  DEFW $0518              ; QUIT
  DEFW $031E              ; HELP
  DEFW $058A              ; SCORE
  DEFW $04D8              ; PAUSE
  DEFW SPECIAL_QUOTE      ; Handler for SLOT 0
  DEFW WORD_ALL           ; Handler for ALL
  DEFW WORD_EXCEPT        ; Handler for EXCEPT
  DEFW WORD_IT            ; Handler for IT
  DEFW NEW_NOUN_PHRASE    ; Handler for ONE
  DEFW PRINTER_ON         ; Handler for PRINT
  DEFW WORD_NOPRINT       ; Handler for NOPRINT
  DEFW DO_LOAD            ; Handler for LOAD
  DEFW DO_SAVE            ; Handler for SAVE
  DEFW DO_QUIT            ; Handler for QUIT
  DEFW DO_HELP            ; Handler for HELP
  DEFW DO_SCORE           ; Handler for SCORE
  DEFW DO_PAUSE           ; Handler for PAUSE

; PRINT: copy the game's text to a ZX Printer, if there is one
;
; Bit 6 of port $FB is low when a ZX Printer is attached; only then is
; TO_PRINTER set. NOPRINT, at WORD_NOPRINT, clears it. Both go back to the
; parser for the next word at SPECIAL_WORD_DONE.
PRINTER_ON:
  IN A,($FB)              ; No printer: nothing changes
  BIT 6,A                 ;
  JR NZ,SPECIAL_WORD_DONE ;
  LD A,$01                ; Copy to the printer from now on
  JR SET_TO_PRINTER       ;

; NOPRINT: stop copying the text to the printer
WORD_NOPRINT:
  XOR A                   ; NOPRINT: stop
; This entry point is used by the routine at PRINTER_ON.
SET_TO_PRINTER:
  LD (TO_PRINTER),A
; This entry point is used by the routines at PRINTER_ON, DO_HELP, DO_SCORE,
; DO_PAUSE, DO_LOAD and DO_SAVE.
SPECIAL_WORD_DONE:
  LD A,(LAST_CLASS)       ; On to the next word of the sentence
  LD D,A                  ;
  JP NEW_NOUN_PHRASE      ;

; EXCEPT: only after ALL
;
; ALL ... EXCEPT ... is kept as ALL_EXCEPT = 2, and the ALL bit set on the
; verb; EXCEPT on its own is an error, through NOT_ALLOWED_HERE.
WORD_EXCEPT:
  LD A,(ALL_EXCEPT)
  CP $01
  JP NZ,NOT_ALLOWED_HERE
  LD A,$02
  LD (ALL_EXCEPT),A
  LD A,(IY+$01)
  OR $80
  LD (IY+$01),A
  JP NEW_NOUN_PHRASE

; ALL
;
; ALL_EXCEPT = 1, unless an EXCEPT has already made it 2.
WORD_ALL:
  LD A,(ALL_EXCEPT)
  CP $02
  JP Z,NEW_NOUN_PHRASE
  LD A,$01
  LD (ALL_EXCEPT),A
  JP NEW_NOUN_PHRASE

; IT: the last noun phrase again
;
; The noun phrase kept at IT_NAME from the last sentence is copied into PHRASE,
; as if it had been typed, and handed to the first or the second phrase's
; handler.
WORD_IT:
  PUSH DE
  LD HL,IT_NAME
  LD DE,PHRASE_NOUN
  LD BC,$0006
  LDIR
  POP DE
  BIT 7,E
  CALL IT_PHRASE
  JP NEW_NOUN_PHRASE

; Hand IT's phrase to the first phrase's handler or the second's, as E says
;
; Used by the routine at WORD_IT.
IT_PHRASE:
  JP Z,FILE_SECOND_PHRASE
  JP FILE_FIRST_PHRASE

; Begin an order: the opening quote
;
; Used by the routine at SPECIAL_QUOTE.
;
; Reached from SPECIAL_QUOTE at the opening quote of something said to a
; character -- SAY TO THORIN "CARRY ME". What follows, up to the closing quote,
; is parsed as commands of its own, in fresh command frames: this keeps D and
; COMMAND_FRAMES aside in the two bytes after PLOT_INK, and IY on the stack,
; steps IY on a frame, and goes back into PARSE_COMMAND at PARSE_ORDER with A =
; 1, which marks the commands as an order (IS_ORDER).
ORDER_BEGINS:
  LD A,D
  LD (ORDER_SAVED_D),A
  PUSH DE
  PUSH BC
  PUSH IY
  LD A,(COMMAND_FRAMES)
  LD (ORDER_FIRST_FRAME),A
  LD DE,$FFE8
  ADD IY,DE
  LD A,$01
  JP PARSE_ORDER

; Special word slot 0: a quote mark
;
; Slot 0 of SPECIAL_WORDS holds the word reference zero, and a quote mark comes
; through the tokeniser as a zero word, so this is where everything said in
; quotes comes. At the opening quote, with IS_ORDER clear, it begins an order
; (ORDER_BEGINS). At the closing one it clears IS_ORDER and files each command
; parsed since -- the frames after ORDER_FIRST_FRAME -- into a free slot of
; ORDERS, eight of 25 bytes, marking the slot taken with $FF and counting them
; into ORDER_COUNT; then it puts back what ORDER_BEGINS kept and goes on with
; the sentence at NEW_NOUN_PHRASE. What the character then does with them is
; its own business: see CHARACTERS.
;
; Nothing in the playthrough that finds the code said anything in quotes, so
; for a while this disassembly had these 148 bytes as code nothing reaches --
; and the fast-draw patch put its own code over them, so that the patched game
; crashed at the first thing said in quotes. It has moved; see the Patches
; page.
SPECIAL_QUOTE:
  LD A,(IS_ORDER)
  AND A
  JR Z,ORDER_BEGINS
  DEC A
  LD (IS_ORDER),A
  LD A,(ORDER_FIRST_FRAME)
  LD B,A
  LD A,(COMMAND_FRAMES)
  SUB B
  AND A
  LD C,$00
  JR Z,SPECIAL_QUOTE_6
  POP IY
  PUSH IY
  LD DE,$FFE8
  ADD IY,DE
  LD B,A
SPECIAL_QUOTE_0:
  LD IX,ORDERS
  PUSH DE
  PUSH BC
  LD DE,$0019
  LD B,$08
SPECIAL_QUOTE_1:
  LD A,(IX+$00)
  AND A
  JR Z,SPECIAL_QUOTE_2
  ADD IX,DE
  DJNZ SPECIAL_QUOTE_1
SPECIAL_QUOTE_2:
  LD (IX+$00),$FF
  INC IX
  POP BC
  POP DE
  JR NZ,SPECIAL_QUOTE_6
  BIT 6,(IY+$01)
  JR Z,SPECIAL_QUOTE_3
  LD (IX-$01),$00
  JR SPECIAL_QUOTE_5
SPECIAL_QUOTE_3:
  PUSH BC
  LD B,$18
SPECIAL_QUOTE_4:
  LD A,(IY+$00)
  LD (IX+$00),A
  INC IY
  INC IX
  DJNZ SPECIAL_QUOTE_4
  POP BC
  ADD IY,DE
SPECIAL_QUOTE_5:
  ADD IY,DE
  INC C
  DJNZ SPECIAL_QUOTE_0
SPECIAL_QUOTE_6:
  XOR A
  LD (ALL_EXCEPT),A
  LD A,C
  LD (ORDER_COUNT),A
  POP IY
  LD A,(ORDER_FIRST_FRAME)
  LD (COMMAND_FRAMES),A
  POP BC
  POP DE
  LD A,(ORDER_SAVED_D)
  LD D,A
  JP NEW_NOUN_PHRASE

; QUIT: the score, then a new game on the next key
DO_QUIT:
  CALL SHOW_SCORE
DO_QUIT_0:
  XOR A
  IN A,($FE)
  AND $1F
  CP $1F
  JR Z,DO_QUIT_0
  JP NEW_GAME

; HELP: a hint for where the player is
;
; Eleven places have a hint of their own, in HELP_HINTS; anywhere else it is
; "YOU'RE DOING FINE.". Only the player gets help: a character told HELP just
; goes on to the next word.
DO_HELP:
  LD A,(ACTING)           ; Not the player: ignore it
  AND A                   ;
  JP NZ,NEW_NOUN_PHRASE   ;
  PUSH HL
  PUSH IX
  LD HL,MSG_Y_O_U_R       ; The hint for this place, or the general one
  LD A,(PLAYER_WHERE)     ;
  LD IX,HELP_HINTS        ;
  CALL FIND_RECORD        ;
  JR Z,DO_HELP_0          ;
  LD L,(IX+$01)           ;
  LD H,(IX+$02)           ;
DO_HELP_0:
  LD A,$01                ; Print it
  LD (INPUT_STYLE),A      ;
  CALL RUN_MESSAGE_HL     ;
  POP IX                  ;
  POP HL                  ;
  JP SPECIAL_WORD_DONE

; The places HELP has a hint for
;
; A FIND_RECORD table of [location, message], eleven of them.
HELP_HINTS:
  DEFB $06,$7A,$B4
  DEFB $09,$8A,$B4
  DEFB $0D,$9A,$B4
  DEFB $42,$BE,$B4
  DEFB $1F,$CA,$B4
  DEFB $20,$DA,$B4
  DEFB $2A,$FA,$B4
  DEFB $2E,$04,$B5
  DEFB $29,$18,$B5
  DEFB $1A,$2F,$B5
  DEFB $05,$3E,$B5
  DEFB $FF                ; End of the table

; SCORE
DO_SCORE:
  CALL SHOW_SCORE
  JP SPECIAL_WORD_DONE

; "you have mastered ... % of this adventure."
;
; Used by the routines at DO_QUIT, DO_SCORE and PLAYER_DIES.
;
; The score at SCORE is kept in tenths of a per cent, so a full game is 1000,
; and it is printed with one decimal place: hundreds only if not zero, then
; tens, a point, and units. Reaching the lonelands scores 25 (VISIT_SCORES),
; which is the 2.5% a first death there reports.
SHOW_SCORE:
  PUSH HL
  PUSH DE
  XOR A                   ; "you have mastered"
  LD (INPUT_STYLE),A      ;
  LD HL,MSG_YOU_HAVE_M_A  ;
  CALL RUN_MESSAGE_HL     ;
  LD HL,(SCORE)           ; Hundreds, if any
  LD DE,$0064             ;
  CALL DIGIT              ;
  CALL NZ,PRINT_CHAR      ;
  LD DE,$000A             ; Tens
  CALL DIGIT              ;
  CALL PRINT_CHAR         ;
  LD A,$2E                ; A decimal point
  CALL PRINT_CHAR         ;
  LD A,L                  ; Units
  ADD A,$30               ;
  CALL PRINT_CHAR         ;
  XOR A                       ; "% of this adventure."
  LD (CAPITAL_NEXT),A         ;
  LD HL,MSG_OF_THIS_ADVENTURE ;
  CALL RUN_MESSAGE_HL         ;
  POP DE
  POP HL
  RET

; One decimal digit of HL
;
; Used by the routine at SHOW_SCORE.
;
; The number of times DE goes into HL, as a character; HL is left with the
; remainder.
;
; I:HL The number
; I:DE The place value
; O:A The digit, '0' to '9'
; O:F Z if it is '0'
DIGIT:
  LD A,$2F
DIGIT_0:
  INC A
  AND A
  SBC HL,DE
  JR NC,DIGIT_0
  ADD HL,DE
  CP $30
  RET

; PAUSE: a green border until a key is pressed
DO_PAUSE:
  LD A,$04
  OUT ($FE),A
  CALL NEW_KEYPRESS
DO_PAUSE_0:
  XOR A
  IN A,($FE)
  AND $1F
  CP $1F
  JR NZ,DO_PAUSE_0
  LD A,$07
  OUT ($FE),A
  JP SPECIAL_WORD_DONE

; LOAD: the four blocks SAVE wrote
;
; A block that fails to load leaves the game half-loaded, so LOAD_BLOCK does
; not return to it: "TAPE ERROR - hit ANY key to RESTART PROGRAM.".
DO_LOAD:
  PUSH IX
  PUSH DE
  LD A,$FF                ; Load the four blocks
  SCF                     ;
  LD IX,SAVED_STATE       ;
  LD DE,$001D             ;
  CALL LOAD_BLOCK         ;
  LD A,$FF                ;
  SCF                     ;
  LD IX,PLAYER            ;
  LD DE,$0615             ;
  CALL LOAD_BLOCK         ;
  LD A,$FF                ;
  SCF                     ;
  LD IX,TIMERS            ;
  LD DE,$00BF             ;
  CALL LOAD_BLOCK         ;
  LD A,$FF                ;
  SCF                     ;
  LD IX,ROOM0             ;
  LD DE,$05D9             ;
  CALL LOAD_BLOCK         ;
  DI                      ; The script bytes back where they belong
  LD HL,SAVED_STATE       ;
  LD DE,BARD_ORDER_STEP   ;
  CALL COPY_THREE         ;
  POP DE
  POP IX
  JP SPECIAL_WORD_DONE

; Load one block, or start the game again
;
; Used by the routine at DO_LOAD.
LOAD_BLOCK:
  CALL $0556
  RET C
  LD A,$01
  LD (INPUT_STYLE),A
  LD HL,MSG_T_A_P_E
  CALL RUN_MESSAGE_HL
LOAD_BLOCK_0:
  XOR A
  IN A,($FE)
  AND $1F
  CP $1F
  JR Z,LOAD_BLOCK_0
  JP NEW_GAME

; Copy three bytes from HL to DE
;
; Used by the routines at DO_LOAD and DO_SAVE.
COPY_THREE:
  LD BC,$0003
  LDIR
  RET

; Wait for all keys up, then for one down
;
; Used by the routines at DO_PAUSE and DO_SAVE.
NEW_KEYPRESS:
  XOR A
  IN A,($FE)
  AND $1F
  CP $1F
  JR NZ,NEW_KEYPRESS
NEW_KEYPRESS_0:
  XOR A
  IN A,($FE)
  AND $1F
  CP $1F
  JR Z,NEW_KEYPRESS_0
  RET

; SAVE: four blocks to tape, then verified
;
; Four headerless blocks through the ROM's SA-BYTES: the variables at
; SAVED_STATE, the objects at PLAYER, the timers and the characters at TIMERS,
; and the rooms at ROOM0 -- the same four START keeps a copy of. Then the tape
; is rewound and each block checked with the ROM's LD-BYTES in verify mode; an
; error says so and goes back to the game.
;
; Three bytes of a character script at BARD_ORDER_STEP, which the game rewrites
; as it runs (BARD_SETS_STEP), are carried in the first three of the variables
; block; DO_LOAD puts them back.
DO_SAVE:
  PUSH IX
  PUSH DE
  LD DE,SAVED_STATE       ; The script bytes into the variables block
  LD HL,BARD_ORDER_STEP   ;
  CALL COPY_THREE         ;
  LD A,$01                ; "start TAPE then PRESS ANY key."
  LD (INPUT_STYLE),A      ;
  LD HL,MSG_START_T_A_P   ;
  CALL RUN_MESSAGE_HL     ;
  CALL NEW_KEYPRESS       ; Wait for the key
  LD A,$FF                ; Save the four blocks
  LD IX,SAVED_STATE       ;
  LD DE,$001D             ;
  CALL $04C2              ;
  LD A,$FF                ;
  LD IX,PLAYER            ;
  LD DE,$0615             ;
  CALL $04C2              ;
  LD A,$FF                ;
  LD IX,TIMERS            ;
  LD DE,$00BF             ;
  CALL $04C2              ;
  LD A,$FF                ;
  LD IX,ROOM0             ;
  LD DE,$05D9             ;
  CALL $04C2              ;
  LD HL,MSG_R_E_W_I       ; "REWIND and PREPARE TAPE for VERIFICATION -- then
  CALL RUN_MESSAGE_HL     ; hit ANY key."
  CALL NEW_KEYPRESS       ;
  LD A,$FF                ; Verify them
  AND A                   ;
  LD IX,SAVED_STATE       ;
  LD DE,$001D             ;
  CALL VERIFY_BLOCK       ;
  LD A,$FF                ;
  AND A                   ;
  LD IX,PLAYER            ;
  LD DE,$0615             ;
  CALL VERIFY_BLOCK       ;
  LD A,$FF                ;
  AND A                   ;
  LD IX,TIMERS            ;
  LD DE,$00BF             ;
  CALL VERIFY_BLOCK       ;
  LD A,$FF                ;
  AND A                   ;
  LD IX,ROOM0             ;
  LD DE,$05D9             ;
  CALL VERIFY_BLOCK       ;
; This entry point is used by the routine at VERIFY_BLOCK.
TAPE_DONE:
  DI
  POP DE
  POP IX
  JP SPECIAL_WORD_DONE

; Verify one block, or say the tape is bad
;
; Used by the routine at DO_SAVE.
;
; "TAPE ERROR - hit ANY key to CONTINUE.", and the save gives up.
VERIFY_BLOCK:
  CALL $0556
  RET C
  LD A,$01
  LD (INPUT_STYLE),A
  LD HL,MSG_T_A_P_E_B
  CALL RUN_MESSAGE_HL
VERIFY_BLOCK_0:
  XOR A
  IN A,($FE)
  AND $1F
  CP $1F
  JR Z,VERIFY_BLOCK_0
  POP DE
  JP TAPE_DONE

; May anything be printed? Z if not
;
; Used by the routine at PRINT_CHAR.
;
; Printing happens only while both DOING_IT (for real, not a test) and
; PRINTING_ON (printing on) are set.
PRINT_GATE:
  PUSH HL
  LD L,A
  LD A,(DOING_IT)
  LD H,A
  LD A,(PRINTING_ON)
  AND H
  LD A,L
  POP HL
  RET

; A carriage return, through PRINT_CHAR
;
; Used by the routines at START, NARRATE_ACTION, WORD_AND_END, PRINT_WORD,
; DO_LOOK, DO_EXAMINE, DESCRIBE_LOCATION, DESCRIBE_BRIEFLY, NARRATE_LINE,
; LIST_HELD, CONTENTS_INTRO and VISIBLE_EXITS.
NEW_LINE:
  PUSH AF
  LD A,$0D
  CALL PRINT_CHAR
  POP AF
  RET

; Print one character
;
; Used by the routines at START, READ_LINE, ONE_KEY_MOVES, REPEAT_LAST,
; RUB_OUT_LINE, NARRATE_ACTION, GET_KEY, PRINT_LITERAL, WORD_AND_END,
; MC_BACKSPACE, PRINT_WORD, SHOW_SCORE, NEW_LINE, DO_LOOK, DO_EXAMINE,
; NARRATE_LINE and LIST_HELD.
;
; Everything printed passes through here with the character in A -- which is
; what makes it a good place to stop to capture exactly what a message says.
PRINT_CHAR:
  CALL PRINT_GATE         ; PRINT_GATE can refuse to print anything at all
  RET Z                   ;
  PUSH AF
  LD A,(INPUT_STYLE)      ; While a line is being typed, the echo goes another
  AND A                   ; way
  JR NZ,INPUT_CHAR        ;
  POP AF                  ; Print it
  CALL STORY_CHAR         ;
  PUSH AF
  LD A,(DRUNK)            ; Drunk?
  AND A                   ;
  JR NZ,PRINT_CHAR_0      ;
  POP AF                  ;
  RET                     ;
PRINT_CHAR_0:
  POP AF                  ; Only after an S...
  CP $53                  ;
  JR Z,PRINT_CHAR_1       ;
  CP $73                  ;
  RET NZ                  ;
PRINT_CHAR_1:
  PUSH AF                 ; ...print an H
  LD A,$48                ;
  CALL STORY_CHAR         ;
  POP AF                  ;
  RET

; The input window's cursor
;
; Set up by START and kept by INPUT_CHAR.
INPUT_COLUMNS:
  DEFB $00                ; Columns left on the line
INPUT_CURSOR:
  DEFB $00,$00            ; The screen address the next character goes to
CURSOR_CHAR:
  DEFB $00                ; The cursor, printed after each character: a +

; Print a character in the input window
;
; Used by the routine at PRINT_CHAR.
;
; The bottom five rows, 19 to 23, in capitals with the ROM's font. A carriage
; return blanks the rest of the line and scrolls the window up; a backspace
; ($08) steps back, and up to the line before if it has to. The cursor is kept
; at INPUT_CURSOR and the columns left on the line at INPUT_COLUMNS.
INPUT_CHAR:
  POP AF
; This entry point is used by the routine at START.
INPUT_CHAR_A:
  PUSH HL
  PUSH AF
  LD HL,(INPUT_CURSOR)    ; A carriage return: to the next line
  CP $0D                  ;
  JR NZ,INPUT_CHAR_0      ;
  LD A,$20                ;
  CALL ROM_FONT_CHAR      ;
  JR INPUT_CHAR_2         ;
INPUT_CHAR_0:
  CP $08                  ; Backspace
  JR Z,INPUT_CHAR_4       ;
  CP $61                  ; Lower case to capitals
  JR C,INPUT_CHAR_1       ;
  CP $7B                  ;
  JR NC,INPUT_CHAR_1      ;
  AND $5F                 ;
INPUT_CHAR_1:
  CALL ROM_FONT_CHAR      ; Print it
  LD A,(INPUT_COLUMNS)    ; End of the line?
  DEC A                   ;
  JR NZ,INPUT_CHAR_3      ;
INPUT_CHAR_2:
  LD L,$E0                ; Then scroll the window, and start again at the left
  CALL SCROLL_INPUT       ;
  LD A,$20                ;
INPUT_CHAR_3:
  LD (INPUT_COLUMNS),A    ; The cursor after it
  LD A,(CURSOR_CHAR)      ;
  LD (INPUT_CURSOR),HL    ;
  CALL ROM_FONT_CHAR      ;
  POP AF                  ;
  POP HL                  ;
  RET                     ;
INPUT_CHAR_4:
  LD A,$20                ; Backspace: blank the cursor, step back, and up a
  CALL ROM_FONT_CHAR      ; line if it has to
  DEC L                   ;
  DEC L                   ;
  LD A,(INPUT_COLUMNS)    ;
  INC A                   ;
  CP $21                  ;
  JR NZ,INPUT_CHAR_3      ;
  LD L,$FF                ;
  CALL SCROLL_INPUT_BACK  ;
  LD A,$01                ;
  JR INPUT_CHAR_3         ;

; Scroll the input window up a line
;
; Used by the routine at INPUT_CHAR.
;
; Character rows 20-23 move up to 19-22, and row 23 is blanked.
SCROLL_INPUT:
  PUSH HL
  PUSH DE
  PUSH BC
  PUSH AF
  LD HL,$5080
  LD DE,$5060
  LD A,$04
  LD B,$00
SCROLL_INPUT_0:
  PUSH HL
  PUSH DE
  LD C,$08
SCROLL_INPUT_1:
  PUSH HL
  PUSH DE
  PUSH BC
  LD C,$20
  LDIR
  POP BC
  POP DE
  POP HL
  INC H
  INC D
  DEC C
  JR NZ,SCROLL_INPUT_1
  POP DE
  POP HL
  LD C,$20
  ADD HL,BC
  EX DE,HL
  ADD HL,BC
  EX DE,HL
  DEC A
  JR NZ,SCROLL_INPUT_0
  LD B,$20
  LD HL,$50E0
  LD A,$20
SCROLL_INPUT_2:
  CALL ROM_FONT_CHAR
  DJNZ SCROLL_INPUT_2
  POP AF
  POP BC
  POP DE
  POP HL
  RET

; Scroll the input window down a line
;
; Used by the routine at INPUT_CHAR.
;
; For a backspace past the start of a line: rows 19-22 back down to 20-23.
SCROLL_INPUT_BACK:
  PUSH HL
  PUSH DE
  PUSH BC
  PUSH AF
  LD HL,$50C0
  LD DE,$50E0
  LD A,$05
SCROLL_INPUT_BACK_0:
  PUSH HL
  PUSH DE
  LD B,$08
SCROLL_INPUT_BACK_1:
  PUSH HL
  PUSH DE
  PUSH BC
  LD BC,$0020
  LDIR
  POP BC
  POP DE
  POP HL
  INC H
  INC D
  DJNZ SCROLL_INPUT_BACK_1
  POP DE
  POP HL
  LD BC,$FFE0
  ADD HL,BC
  EX DE,HL
  ADD HL,BC
  EX DE,HL
  DEC A
  JR NZ,SCROLL_INPUT_BACK_0
  POP AF
  POP BC
  POP DE
  POP HL
  RET

; Print a character at HL in the ROM's font
;
; Used by the routines at INPUT_CHAR and SCROLL_INPUT.
;
; The eight rows of the ROM's own character set at $3D00; L is moved on one
; column.
;
; I:A The character, $20 to $7F
; I:HL The screen address
ROM_FONT_CHAR:
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  SUB $20
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,$3D00
  ADD HL,DE
  EX DE,HL
  POP HL
  PUSH HL
  LD B,$08
ROM_FONT_CHAR_0:
  LD A,(DE)
  LD (HL),A
  INC DE
  INC H
  DJNZ ROM_FONT_CHAR_0
  POP HL
  POP DE
  POP BC
  POP AF
  INC L
  RET

; The story window's place, and the indent
;
; Set up by START and kept by STORY_CHAR.
STORY_COLUMNS:
  DEFB $00                ; Columns left on the line, of 42
STORY_CURSOR:
  DEFB $00,$00            ; The screen byte the next character starts in...
STORY_PIXEL:
  DEFB $00                ; ...and the pixel within it
INDENT:
  DEFB $00                ; How far a new line is indented: LIST_HELD indents
                          ; what things hold
MID_LINE:
  DEFB $00                ; Nonzero once a character has been printed on the
                          ; line, so the indent is not given twice

; Print a character of the story
;
; Used by the routine at PRINT_CHAR.
;
; Where most of the game's text goes, in the six-pixel font at FONT
; (NARROW_CHAR), 42 to a line: HL is the byte and C the pixel within it where
; the next character starts, kept at STORY_CURSOR and STORY_PIXEL between
; calls, and STORY_COLUMNS counts the columns left.
;
; A new line starts with the indent at INDENT -- how LIST_HELD indents what is
; inside something. Capitals are the game's own: every letter is made lower
; case, and the first letter after a carriage return or a full stop made upper
; case again, by the flag at CAPITAL_NEXT.
;
; At the end of a line the finished line is copied to the ZX Printer if PRINT
; is on, then the game waits about a third of a second, or less if a key is
; pressed, before scrolling. NO_PAUSE_LINES, when not zero, takes away that
; wait for as many lines as it counts; what sets it is not yet traced.
STORY_CHAR:
  PUSH HL
  PUSH BC
  PUSH AF
  LD HL,(STORY_CURSOR)    ; Starting a line: the indent
  LD A,(STORY_PIXEL)      ;
  LD C,A                  ;
  LD A,(MID_LINE)         ;
  AND A                   ;
  JR NZ,STORY_CHAR_1      ;
  LD A,(INDENT)           ;
  AND A                   ;
  JR Z,STORY_CHAR_1       ;
  LD B,A                  ;
STORY_CHAR_0:
  LD A,$20                ;
  CALL NARROW_CHAR        ;
  LD A,(STORY_COLUMNS)    ;
  DEC A                   ;
  LD (STORY_COLUMNS),A    ;
  DJNZ STORY_CHAR_0       ;
STORY_CHAR_1:
  POP AF                  ; A carriage return?
  PUSH AF                 ;
  CP $0D                  ;
  JR NZ,STORY_CHAR_8      ;
  LD A,$01                ; The next letter is a capital
  LD (CAPITAL_NEXT),A     ;
STORY_CHAR_2:
  XOR A                   ; A new line: to the printer, if PRINT is on
  LD (MID_LINE),A         ;
  CALL LINE_TO_PRINTER    ;
  PUSH BC                 ; A short wait, or until a key
  LD A,(NO_PAUSE_LINES)   ;
  AND A                   ;
  JR NZ,STORY_CHAR_4      ;
  LD BC,$8000             ;
STORY_CHAR_3:
  XOR A                   ;
  IN A,($FE)              ;
  AND $1F                 ;
  CP $1F                  ;
  JR NZ,STORY_CHAR_5      ;
  DEC BC                  ;
  LD A,B                  ;
  OR C                    ;
  JR NZ,STORY_CHAR_3      ;
  POP BC                  ;
  JR STORY_CHAR_7         ;
STORY_CHAR_4:
  DEC A                   ;
  LD (NO_PAUSE_LINES),A   ;
STORY_CHAR_5:
  POP BC                  ;
STORY_CHAR_6:
  XOR A                   ; Until the keys are let go
  IN A,($FE)              ;
  AND $1F                 ;
  CP $1F                  ;
  JR NZ,STORY_CHAR_6      ;
STORY_CHAR_7:
  LD HL,$5020             ; Scroll the story up a line, 42 columns ahead
  LD C,$01                ;
  CALL SCROLL_STORY       ;
  LD A,$2A                ;
  JR STORY_CHAR_13        ;
STORY_CHAR_8:
  CP $08                  ; Backspace: back a column, blank it, back again
  JR NZ,STORY_CHAR_9      ;
  CALL BACK_ONE           ;
  LD A,$20                ;
  CALL NARROW_CHAR        ;
  CALL BACK_ONE           ;
  LD A,(STORY_COLUMNS)    ;
  INC A                   ;
  JR STORY_CHAR_13        ;
STORY_CHAR_9:
  CP $41                  ; Capitals to lower case...
  JR C,STORY_CHAR_10      ;
  CP $5B                  ;
  JR NC,STORY_CHAR_10     ;
  OR $20                  ;
STORY_CHAR_10:
  PUSH HL                 ; ...and a capital where a sentence starts
  LD HL,CAPITAL_NEXT      ;
  INC (HL)                ;
  DEC (HL)                ;
  JR Z,STORY_CHAR_11      ;
  CP $61                  ;
  JR C,STORY_CHAR_11      ;
  CP $7B                  ;
  JR NC,STORY_CHAR_11     ;
  RES 5,A                 ;
  LD (HL),$00             ;
STORY_CHAR_11:
  CP $2E                  ;
  JR NZ,STORY_CHAR_12     ;
  INC (HL)                ;
STORY_CHAR_12:
  POP HL
  CALL NARROW_CHAR        ; Print it
  LD (MID_LINE),A         ;
  LD A,(STORY_COLUMNS)    ; The line full? A new one
  DEC A                   ;
  JP Z,STORY_CHAR_2       ;
STORY_CHAR_13:
  LD (STORY_COLUMNS),A    ; Keep the place
  LD (STORY_CURSOR),HL    ;
  LD A,C                  ;
  LD (STORY_PIXEL),A      ;
  POP AF                  ;
  POP BC                  ;
  POP HL                  ;
  RET                     ;

; Step back one six-pixel column
;
; Used by the routine at STORY_CHAR.
;
; I:HL The screen byte
; I:C The pixel within it
BACK_ONE:
  LD A,C
  SUB $06
  LD C,A
  RET NC
  ADD A,$08
  LD C,A
  DEC L
  RET

; Scroll the story up a line
;
; Used by the routine at STORY_CHAR.
;
; Character rows 1 to 17 move up to 0 to 16, attributes with them, and row 17
; is cleared to 42 spaces. The picture is in rows 0 to 15, so it goes up and
; off the top as the story goes on.
SCROLL_STORY:
  PUSH AF
  PUSH BC
  PUSH HL
  PUSH DE
  LD HL,$4020
  LD DE,$4000
  LD A,$11
  LD B,$00
SCROLL_STORY_0:
  PUSH HL
  PUSH DE
  LD C,$08
SCROLL_STORY_1:
  PUSH HL
  PUSH DE
  PUSH BC
  LD C,$20
  LDIR
  POP BC
  POP DE
  POP HL
  INC H
  INC D
  DEC C
  JR NZ,SCROLL_STORY_1
  POP DE
  POP HL
  LD C,$20
  ADD HL,BC
  EX DE,HL
  ADD HL,BC
  EX DE,HL
  PUSH AF
  LD A,D
  AND $07
  JR Z,SCROLL_STORY_2
  LD A,D
  ADD A,$07
  LD D,A
SCROLL_STORY_2:
  LD A,H
  AND $07
  JR Z,SCROLL_STORY_3
  LD A,H
  ADD A,$07
  LD H,A
SCROLL_STORY_3:
  POP AF
  DEC A
  JR NZ,SCROLL_STORY_0
  LD HL,$5820
  LD DE,$5800
  LD BC,$0220
  LDIR
  LD B,$2A
  LD HL,$5020
  LD C,$01
  LD A,$20
SCROLL_STORY_4:
  CALL NARROW_CHAR
  DJNZ SCROLL_STORY_4
  POP DE
  POP HL
  POP BC
  POP AF
  RET

; Print a character in the six-pixel font
;
; Used by the routines at STORY_CHAR and SCROLL_STORY.
;
; A character six pixels wide seldom sits in one byte: each row is shifted to
; the pixel in C and, when it runs over, the rest put into the next byte along.
; The font is at FONT, from the space: STORY_CHAR_9 + 8 times the character.
;
; I:A The character
; I:HL The screen byte
; I:C The pixel within it where the character starts
; O:HL The byte the next character starts in
; O:C The pixel within it
NARROW_CHAR:
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,STORY_CHAR_9
  ADD HL,DE
  EX DE,HL
  POP HL
  PUSH HL
  LD B,$08
NARROW_CHAR_0:
  LD A,(DE)
  PUSH BC
  DEC C
  INC C
  LD B,$FF
  JR Z,NARROW_CHAR_2
NARROW_CHAR_1:
  SRL A
  SRL B
  DEC C
  JR NZ,NARROW_CHAR_1
NARROW_CHAR_2:
  LD C,A
  LD A,B
  CPL
  AND (HL)
  OR C
  LD (HL),A
  POP BC
  DEC C
  INC C
  JR Z,NARROW_CHAR_4
  PUSH BC
  LD A,$08
  SUB C
  LD C,A
  LD A,(DE)
  LD B,$FF
NARROW_CHAR_3:
  SLA A
  SLA B
  DEC C
  JR NZ,NARROW_CHAR_3
  LD C,A
  LD A,B
  CPL
  INC HL
  AND (HL)
  OR C
  LD (HL),A
  DEC HL
  POP BC
NARROW_CHAR_4:
  INC DE
  INC H
  DJNZ NARROW_CHAR_0
  POP HL
  POP DE
  POP BC
  LD A,C
  ADD A,$06
  CP $08
  JR C,NARROW_CHAR_5
  SUB $08
  INC L
NARROW_CHAR_5:
  LD C,A
  POP AF
  RET

; The story's font: six pixels wide, from the space to $7F
;
; Ninety-six characters of eight bytes each, drawn by NARROW_CHAR.
FONT:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$10,$10,$10,$10,$00,$10,$00
  DEFB $00,$28,$28,$00,$00,$00,$00,$00
  DEFB $00,$28,$7C,$28,$7C,$28,$00,$00
  DEFB $00,$10,$7C,$50,$7C,$14,$7C,$10
  DEFB $00,$64,$48,$10,$24,$4C,$00,$00
  DEFB $20,$50,$20,$54,$48,$74,$00,$00
  DEFB $00,$08,$10,$00,$00,$00,$00,$00
  DEFB $00,$08,$10,$10,$10,$10,$08,$00
  DEFB $00,$10,$08,$08,$08,$08,$10,$00
  DEFB $00,$28,$10,$7C,$10,$28,$00,$00
  DEFB $00,$10,$10,$7C,$10,$10,$00,$00
  DEFB $00,$00,$00,$00,$00,$10,$10,$20
  DEFB $00,$00,$00,$7C,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$30,$30,$00
  DEFB $00,$04,$08,$10,$20,$40,$00,$00
  DEFB $00,$38,$4C,$54,$54,$64,$38,$00
  DEFB $00,$30,$50,$10,$10,$10,$7C,$00
  DEFB $00,$38,$44,$04,$38,$40,$7C,$00
  DEFB $00,$38,$44,$18,$04,$44,$38,$00
  DEFB $00,$18,$28,$48,$7C,$08,$08,$00
  DEFB $00,$7C,$40,$78,$04,$44,$38,$00
  DEFB $00,$38,$40,$78,$44,$44,$38,$00
  DEFB $00,$7C,$04,$08,$10,$20,$20,$00
  DEFB $00,$38,$44,$38,$44,$44,$38,$00
  DEFB $00,$38,$44,$44,$3C,$04,$38,$00
  DEFB $00,$00,$10,$00,$00,$10,$00,$00
  DEFB $00,$00,$10,$00,$00,$10,$10,$20
  DEFB $00,$00,$08,$10,$20,$10,$08,$00
  DEFB $00,$00,$00,$3C,$00,$3C,$00,$00
  DEFB $00,$00,$20,$10,$08,$10,$20,$00
  DEFB $00,$38,$44,$08,$10,$00,$10,$00
  DEFB $00,$38,$54,$54,$58,$40,$38,$00
  DEFB $00,$38,$44,$44,$7C,$44,$44,$00
  DEFB $00,$78,$44,$78,$44,$44,$78,$00
  DEFB $00,$38,$44,$40,$40,$44,$38,$00
  DEFB $00,$70,$48,$44,$44,$48,$70,$00
  DEFB $00,$7C,$40,$78,$40,$40,$7C,$00
  DEFB $00,$7C,$40,$78,$40,$40,$40,$00
  DEFB $00,$38,$44,$40,$5C,$44,$38,$00
  DEFB $00,$44,$44,$7C,$44,$44,$44,$00
  DEFB $00,$7C,$10,$10,$10,$10,$7C,$00
  DEFB $00,$04,$04,$04,$44,$44,$38,$00
  DEFB $00,$48,$50,$60,$50,$48,$44,$00
  DEFB $00,$40,$40,$40,$40,$40,$7C,$00
  DEFB $00,$44,$6C,$54,$44,$44,$44,$00
  DEFB $00,$44,$64,$54,$54,$4C,$44,$00
  DEFB $00,$38,$44,$44,$44,$44,$38,$00
  DEFB $00,$78,$44,$44,$78,$40,$40,$00
  DEFB $00,$38,$44,$44,$54,$48,$34,$00
  DEFB $00,$78,$44,$44,$78,$48,$44,$00
  DEFB $00,$38,$40,$38,$04,$44,$38,$00
  DEFB $00,$7C,$10,$10,$10,$10,$10,$00
  DEFB $00,$44,$44,$44,$44,$44,$38,$00
  DEFB $00,$44,$44,$44,$44,$28,$10,$00
  DEFB $00,$44,$44,$44,$54,$6C,$44,$00
  DEFB $00,$44,$28,$10,$10,$28,$44,$00
  DEFB $00,$44,$44,$28,$10,$10,$10,$00
  DEFB $00,$7C,$04,$18,$20,$40,$7C,$00
  DEFB $00,$38,$20,$20,$20,$20,$38,$00
  DEFB $00,$40,$20,$10,$08,$04,$00,$00
  DEFB $00,$38,$08,$08,$08,$08,$38,$00
  DEFB $00,$10,$38,$54,$10,$10,$10,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$7C
  DEFB $00,$18,$24,$70,$20,$20,$7C,$00
  DEFB $00,$00,$38,$04,$3C,$44,$3C,$00
  DEFB $00,$40,$40,$78,$44,$44,$78,$00
  DEFB $00,$00,$38,$40,$40,$40,$38,$00
  DEFB $00,$04,$04,$3C,$44,$44,$3C,$00
  DEFB $00,$00,$38,$44,$78,$40,$3C,$00
  DEFB $00,$18,$20,$30,$20,$20,$20,$00
  DEFB $00,$00,$3C,$44,$44,$3C,$04,$38
  DEFB $00,$40,$40,$78,$44,$44,$44,$00
  DEFB $00,$10,$00,$30,$10,$10,$38,$00
  DEFB $00,$08,$00,$08,$08,$08,$48,$30
  DEFB $00,$20,$28,$30,$30,$28,$24,$00
  DEFB $00,$20,$20,$20,$20,$20,$18,$00
  DEFB $00,$00,$68,$54,$54,$54,$54,$00
  DEFB $00,$00,$78,$44,$44,$44,$44,$00
  DEFB $00,$00,$38,$44,$44,$44,$38,$00
  DEFB $00,$00,$78,$44,$44,$78,$40,$40
  DEFB $00,$00,$38,$48,$48,$38,$08,$0C
  DEFB $00,$00,$38,$20,$20,$20,$20,$00
  DEFB $00,$00,$38,$40,$38,$04,$78,$00
  DEFB $00,$20,$70,$20,$20,$20,$18,$00
  DEFB $00,$00,$44,$44,$44,$44,$38,$00
  DEFB $00,$00,$44,$44,$28,$28,$10,$00
  DEFB $00,$00,$44,$54,$54,$54,$28,$00
  DEFB $00,$00,$44,$28,$10,$28,$44,$00
  DEFB $00,$00,$44,$44,$44,$3C,$04,$38
  DEFB $00,$00,$7C,$08,$10,$20,$7C,$00
  DEFB $00,$1C,$10,$60,$10,$10,$1C,$00
  DEFB $00,$10,$10,$10,$10,$10,$10,$00
  DEFB $00,$70,$10,$0C,$10,$10,$70,$00
  DEFB $00,$28,$50,$00,$00,$00,$00,$00
  DEFB $00,$10,$08,$7C,$00,$7C,$08,$10

; Copy the newest line of the story to the ZX Printer
;
; Used by the routine at STORY_CHAR.
;
; Only while PRINT is on. The eight pixel rows of character row 17 go out
; through port $FB a pixel at a time, as the ROM's COPY does; a printer that
; stops, or is not there, ends it.
LINE_TO_PRINTER:
  LD A,(TO_PRINTER)
  AND A
  RET Z
  PUSH HL
  PUSH DE
  PUSH BC
  LD D,$01
  LD HL,$5020
  XOR A
  LD E,A
LINE_TO_PRINTER_0:
  OUT ($FB),A
LINE_TO_PRINTER_1:
  IN A,($FB)
  ADD A,A
  JP M,LINE_TO_PRINTER_6
  JR NC,LINE_TO_PRINTER_1
  PUSH HL
  PUSH DE
  LD A,D
  CP $02
  SBC A,A
  AND E
  RLCA
  AND E
  LD D,A
LINE_TO_PRINTER_2:
  LD C,(HL)
  PUSH HL
  LD B,$08
LINE_TO_PRINTER_3:
  LD A,D
  RLC C
  RRA
  LD H,A
LINE_TO_PRINTER_4:
  IN A,($FB)
  RRA
  JR NC,LINE_TO_PRINTER_4
  LD A,H
  OUT ($FB),A
  DJNZ LINE_TO_PRINTER_3
  POP HL
  INC HL
  LD A,L
  AND $1F
  JR NZ,LINE_TO_PRINTER_2
LINE_TO_PRINTER_5:
  IN A,($FB)
  RRA
  JR NC,LINE_TO_PRINTER_5
  LD A,D
  RRCA
  OUT ($FB),A
  POP DE
  POP HL
  INC H
  INC E
  BIT 3,E
  JR Z,LINE_TO_PRINTER_0
  LD A,$04
  OUT ($FB),A
LINE_TO_PRINTER_6:
  POP BC
  POP DE
  POP HL
  RET

; Busy-wait, 1000 times round
;
; Used by the routine at SCAN_KEYBOARD.
;
; About 26000 T-states, or 7.4ms. SCAN_KEYBOARD calls it every time, so while
; the game sits at its prompt this is 88% of everything it does -- idle, not
; work, but it is also the reason a scan is too expensive to call from inside
; the drawing code as it stands.
DEBOUNCE_DELAY:
  LD BC,$03E8             ; 1000 times round a four-instruction loop: about
DEBOUNCE_DELAY_0:
  DEC BC                  ; 26000 T-states
  LD A,B                  ;
  OR C                    ;
  JR NZ,DEBOUNCE_DELAY_0  ;
  RET

; The keyboard scan's working bytes
;
; Eight masks, one per half-row, of keys that never count as pressed on their
; own -- CAPS SHIFT and SYMBOL SHIFT among them; then the half-row and bits of
; the last new key found; then the eight half-rows as last seen, which is how
; SCAN_KEYBOARD knows a key is new.
KEY_STATE:
  DEFB $01,$00,$00,$0D,$02,$00,$00,$02 ; Keys that do not count as a keypress,
                                       ; per half-row
NEW_KEY:
  DEFB $00,$00            ; The last new key: half-row and bits
KEYS_LAST_SEEN:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; The keyboard as last scanned

; Scan the whole keyboard, debounced
;
; Used by the routine at GET_KEY.
;
; Reads all eight half-rows with BC = $FEFE and RLC B, building a key map at
; KEYS_LAST_SEEN and comparing it against the previous one so that only changes
; count. It calls DEBOUNCE_DELAY first, which is where nearly all of the game's
; idle time goes: about 7.4ms per scan.
SCAN_KEYBOARD:
  PUSH HL
  PUSH IX
  PUSH BC
  CALL DEBOUNCE_DELAY     ; Debounce: about 7.4ms
  LD (NEW_KEY),BC         ; No new key yet; HL = the keyboard as last seen, IX
  LD HL,KEYS_LAST_SEEN    ; = the masks, BC = the first half-row
  LD IX,KEY_STATE         ;
  LD BC,$FEFE             ;
SCAN_KEYBOARD_0:
  IN A,(C)                ; Read a half-row, with the keys that do not count
  AND $1F                 ; masked out
  OR (IX+$00)             ;
  PUSH AF                 ; Any key down now that was up last time?
  CPL                     ;
  AND (HL)                ;
  CPL                     ;
  JR Z,SCAN_KEYBOARD_1    ;
  LD (NEW_KEY),BC         ; Yes: remember which half-row and which bits
  LD (NEW_KEY),A          ;
SCAN_KEYBOARD_1:
  POP AF                  ; Remember this half-row for next time, and on to the
  LD (HL),A               ; next
  INC HL                  ;
  INC IX                  ;
  RLC B                   ;
  JR C,SCAN_KEYBOARD_0    ;
  LD BC,(NEW_KEY)         ; No new key at all: A = 0
  LD A,B                  ;
  OR C                    ;
  JR Z,SCAN_KEYBOARD_6    ;
  LD A,$FB                ; Key number = half-row times five plus bit
SCAN_KEYBOARD_2:
  ADD A,$05               ;
  RRC B                   ;
  JR C,SCAN_KEYBOARD_2    ;
  DEC A                   ;
SCAN_KEYBOARD_3:
  INC A                   ;
  RRC C                   ;
  JR C,SCAN_KEYBOARD_3    ;
  LD C,A                  ;
  LD B,$00                ; Look it up in KEY_MAP, or KEY_MAP_SHIFTED if either
  LD HL,KEY_MAP           ; shift is held
  LD A,$FE                ;
  IN A,($FE)              ;
  AND $01                 ;
  JR Z,SCAN_KEYBOARD_4    ;
  LD A,$7F                ;
  IN A,($FE)              ;
  AND $02                 ;
  JR NZ,SCAN_KEYBOARD_5   ;
SCAN_KEYBOARD_4:
  LD HL,KEY_MAP_SHIFTED   ;
SCAN_KEYBOARD_5:
  ADD HL,BC               ;
  LD A,(HL)
SCAN_KEYBOARD_6:
  POP BC
  POP IX
  POP HL
  RET
; Worth knowing when driving the game from a script: at uncapped emulation
; speed a key press and release can straddle a scan and be missed entirely, and
; the game's own ENTER still gets through, so a command comes out as a bare
; WAIT. Type at realtime speed.

; What each key gives
;
; Forty characters, one per key, indexed by half-row times five plus the key's
; bit: capital letters, SPACE, ENTER and a backspace on 0; and on 5, 6, 7 and
; 8, the cursor keys, the codes ONE_KEY_MOVES turns into moves. The rest of the
; number row gives nothing.
KEY_MAP:
  DEFB $00,$5A,$58,$43,$56,$41,$53,$44,$46,$47
  DEFB $51,$57,$45,$52,$54,$00,$00,$00,$00,$08
  DEFB $08,$00,$09,$5B,$0A,$50,$4F,$49,$55,$59
  DEFB $0D,$4C,$4B,$4A,$48,$20,$00,$4D,$4E,$42

; What each key gives with a shift held
;
; The same, plus the quote on P, full stop and comma on M and N, the @ that
; repeats the last command, and the $18 that clears the line.
KEY_MAP_SHIFTED:
  DEFB $00,$5A,$58,$43,$56,$41,$53,$44,$46,$47
  DEFB $51,$57,$45,$52,$54,$00,$40,$00,$00,$08
  DEFB $18,$00,$09,$5B,$0A,$22,$4F,$49,$55,$59
  DEFB $0D,$4C,$4B,$4A,$48,$02,$00,$2E,$2C,$42

; LOOK
;
; Inside something -- the barrel, say -- the actor is told what it is in and
; what else is in there with it: "you are in the barrel." and "you see :".
; Otherwise the whole location is described again, as on a first visit.
DO_LOOK:
  CALL FOR_REAL           ; The test ends here
  LD IX,(ACTOR)           ; Held by nothing: describe the place
  LD A,(IX+$01)           ;
  CP $FF                  ;
  JR Z,DO_LOOK_0          ;
  LD HL,$0080             ; "you are"...
  LD (MSG_IN_SLOT),HL     ;
  LD HL,MSG_IN            ;
  CALL RUN_MESSAGE_HL     ;
  PUSH IX                 ; ...in the ..., and its name
  LD A,(IX+$01)           ;
  CALL GET_OBJECT         ;
  CALL PLACED_WORD        ;
  LD E,(IX+$08)           ;
  LD A,(IX+$09)           ;
  AND $0F                 ;
  LD D,A                  ;
  CALL PRINT_WORD_DE      ;
  LD A,$2E                ; A full stop and a new line
  CALL PRINT_CHAR         ;
  CALL NEW_LINE           ;
  LD HL,MSG_SEE_B         ; "you see :" and what else it holds
  CALL RUN_MESSAGE_HL     ;
  POP IX                  ;
  LD A,(IX+$01)           ;
  LD B,(IX+$10)           ;
  JP LIST_HERE            ;
DO_LOOK_0:
  LD A,(IX+$10)           ; Describe the location
  JP DESCRIBE_ROOM        ;

; Refuse unless the actor has the first object
;
; Used by the routines at DO_DROP and THROW_THROUGH.
;
; "you are not carrying it.", and out of the handler that called it.
MUST_CARRY:
  CALL ACTOR_HAS_FIRST    ; The actor has it: fine
  RET C                   ;
  POP HL                    ; Otherwise "you are not carrying it.", from the
  LD HL,MSG_NOT_CARRYING_IT ; caller
  JP RUN_MESSAGE_HL         ;

; DROP
;
; The object goes to whatever holds the actor, or to the ground if nothing
; does. Something tied to the rope goes with the rope: it is the rope that is
; dropped. A liquid is not dropped but lost: it goes nowhere, and "...
; evaporates.".
DO_DROP:
  CALL MUST_CARRY         ; Must be carrying it; the test ends here
  CALL FOR_REAL           ;
  LD IX,(TARGET_RECORD)   ; Tied to the rope? Then it is the rope that is
  LD A,(IX+$01)           ; dropped
  CP $12                  ;
  JR NZ,DO_DROP_0         ;
  LD IX,ROPE              ;
DO_DROP_0:
  PUSH IX                 ; It is held by what holds the actor
  LD IX,(ACTOR)           ;
  LD A,(IX+$01)           ;
  POP IX                  ;
  LD (IX+$01),A           ;
  BIT 1,(IX+$07)          ; Not a liquid: done
  RET Z                   ;
  LD (IX+$10),$00         ; A liquid goes nowhere: "... evaporates."
  LD HL,MSG_EVAPORATE     ;
  LD DE,$0008             ;
  ADD IX,DE               ;
  PUSH IX                 ;
  CALL RUN_MESSAGE_HL     ;
  RET

; TAKE OUT OF, carried by the containers
;
; The thing must be in the container, at any depth ("the ... is not in the
; ..."); then it is taken as TAKE takes anything, from the lifting check on.
DO_TAKE_OUT:
  LD A,(TARGET)
  LD HL,INSTRUMENT
  CALL HELD_BY_HL
  LD HL,MSG_IS_NOT_IN
  JP NZ,RUN_MESSAGE_HL
  JR TAKE_IT

; Can the actor pick the first object up?
;
; Used by the routines at DO_TAKE and DO_THROW_AT.
;
; Its weight and all it holds must fit what the actor can carry -- byte 3 of
; the actor's record less its own weight and load -- or "the ... is too heavy
; to lift." and "you are carrying too much."; and a liquid cannot be picked up
; at all. A refusal leaves the handler that called it.
CAN_LIFT:
  LD IX,(TARGET_RECORD)   ; Its weight with all it holds, at most 255
  LD A,(TARGET)           ;
  CALL WEIGHT_HELD        ;
  ADD A,(IX+$03)          ;
  JR NC,CAN_LIFT_0        ;
  LD A,$FF                ;
CAN_LIFT_0:
  LD B,A                  ;
  LD IY,(ACTOR)             ; More than the actor can carry at all? "too heavy
  LD A,(IY+$03)             ; to lift"
  SUB B                     ;
  LD HL,MSG_IS_TOO_HEAVY_TO ;
  JR C,CAN_LIFT_1           ;
  PUSH AF                     ; More than it can carry besides its load? "you
  LD A,(ACTING)               ; are carrying too much"
  CALL WEIGHT_HELD            ;
  LD B,A                      ;
  POP AF                      ;
  SUB B                       ;
  JP P,CAN_LIFT_HERE          ;
  LD HL,MSG_CARRYING_TOO_MUCH ;
CAN_LIFT_1:
  EX (SP),HL              ; Refused, from the caller
  POP HL                  ;
  JP RUN_MESSAGE_HL       ;
; This entry point is used by the routines at DO_PUT_IN and INTO_THE_RIVER.
CAN_LIFT_HERE:
  CALL ONE_PLACE          ; Fine, unless ONE_PLACE objects or it is a liquid
  JR NZ,CAN_LIFT_2        ;
  BIT 1,(IX+$07)          ;
  RET Z                   ;
CAN_LIFT_2:
  POP HL                  ; Refused
  JP REFUSE               ;

; TAKE and CARRY
;
; Used by the routine at DO_TIE.
;
; Refused if the actor has it already ("you are already carrying the ..."), if
; it will not lift (CAN_LIFT), or if the actor is inside it. Something tied to
; the rope is taken by taking the rope.
DO_TAKE:
  CALL ACTOR_HAS_FIRST       ; Has it already? "you are already carrying the
  LD HL,MSG_ALREADY_CARRYING ; ..."
  JP C,RUN_MESSAGE_HL        ;
; This entry point is used by the routine at DO_TAKE_OUT.
TAKE_IT:
  CALL CAN_LIFT           ; Can it be lifted?
  LD A,(ACTING)           ; Is the actor inside it, at any depth? Refused
DO_TAKE_0:
  CALL GET_OBJECT         ;
  LD A,(TARGET)           ;
  CP (IX+$01)             ;
  JP Z,REFUSE             ;
  LD A,(IX+$01)           ;
  CP $FF                  ;
  JR NZ,DO_TAKE_0         ;
  LD IX,(TARGET_RECORD)   ; The test ends here
  CALL FOR_REAL           ;
  LD A,(IX+$01)           ; The actor holds it now...
  CP $12                  ;
  LD A,(ACTING)           ;
  JR Z,DO_TAKE_1          ;
  LD (IX+$01),A           ;
  RET                     ;
DO_TAKE_1:
  LD (ROPE_HOLDER),A      ; ...or, if it is tied to the rope, the rope
  RET                     ;

; The score for reaching each place
;
; A FIND_RECORD table keyed by location, of the points MOVE adds to the score
; at SCORE the first time the player gets there -- the first time being told by
; bit 6 of byte 0 of the room's record, which MOVE sets. Fourteen places, 750
; points between them, 200 of those for the lower halls.
VISIT_SCORES:
  DEFB LOC_LONELANDS      ; Location 4, lonelands
  DEFW $0019              ; 25 points: 2.5% of the game
  DEFB LOC_TROLLS_CAVE    ; Location 7, trolls cave
  DEFW $0032              ; 50 points: 5.0% of the game
  DEFB LOC_NARROW_PLACE   ; Location 11, narrow place
  DEFW $0019              ; 25 points: 2.5% of the game
  DEFB LOC_BEORNS_HOUSE   ; Location 22, beorns house
  DEFW $0019              ; 25 points: 2.5% of the game
  DEFB LOC_GOBLINS_DUNGEON ; Location 13, goblins dungeon
  DEFW $004B              ; 75 points: 7.5% of the game
  DEFB LOC_DARK_STUFFY_PASSAGE_65 ; Location 65, dark stuffy passage
  DEFW $0032              ; 50 points: 5.0% of the game
  DEFB LOC_SMOTHERING_FOREST ; Location 27, smothering forest
  DEFW $0019              ; 25 points: 2.5% of the game
  DEFB LOC_LEVELLED_ELVISH_CLEARING ; Location 28, levelled elvish clearing
  DEFW $0019              ; 25 points: 2.5% of the game
  DEFB LOC_DARK_DUNGEON   ; Location 31, dark dungeon
  DEFW $0032              ; 50 points: 5.0% of the game
  DEFB LOC_LONG_LAKE      ; Location 34, long lake
  DEFW $0064              ; 100 points: 10.0% of the game
  DEFB LOC_DALE_VALLEY    ; Location 38, dale valley
  DEFW $0019              ; 25 points: 2.5% of the game
  DEFB LOC_SIDEDOOR       ; Location 42, sidedoor
  DEFW $0019              ; 25 points: 2.5% of the game
  DEFB LOC_SMOOTH_STRAIGHT_PASSAGE ; Location 43, smooth straight passage
  DEFW $0032              ; 50 points: 5.0% of the game
  DEFB LOC_LOWER_HALLS    ; Location 41, lower halls
  DEFW $00C8              ; 200 points: 20.0% of the game
  DEFB $FF                ; End of the table

; MOVE's working bytes
DESTINATION_ROOM:
  DEFB $00,$00            ; The destination's room record
DESTINATION:
  DEFB $00                ; The destination
ACTOR_SIZE:
  DEFB $00                ; The actor's size with all it carries, which has to
                          ; fit through the way out

; Move a character one step
;
; Used by the routine at DO_RUN.
;
; Called for every character that moves, the player included, with the
; direction in ACTION. Watched directly: a single turn in which the player only
; typed INVENTORY ran this 21 times for nine other characters, each wandering
; on its own -- which is The Hobbit's independent cast, seen from the inside.
;
; For the player -- told apart by ACTING being zero -- the codes observed are 1
; north, 2 south, 3 east, 9 up and 10 down. West was not observed because it
; was blocked where the test stood, and the four diagonals will be among 4 to
; 8, but which is which has not been watched and is not asserted here.
MOVE:
  CALL TOO_DARK           ; In the dark, the direction asked for is thrown away
  JR NC,MOVE_ACTOR        ; for a random one from 1 to 10
  LD A,$09                ;
  CALL RANDOM_POSITIVE    ;
  INC A                   ;
  LD (ACTION),A           ;
; This entry point is used by the routines at GO_THROUGH and SWIM_RIVER.
MOVE_ACTOR:
  LD IY,(ACTOR)           ; Is the actor held by anything?
  LD A,(IY+$01)           ;
  CP $FF                  ;
  JR Z,MOVE_0             ;
  CALL GET_OBJECT         ; Held by a thing, not a character: cannot move
  BIT 6,(IX+$07)          ;
  JR Z,MOVE_1             ;
  LD (IY+$01),$FF         ; Held by a character: let go
MOVE_0:
  LD A,(ACTING)           ; The actor's size with everything it carries, for
  CALL SIZE_HELD          ; fitting through the way out
  ADD A,(IY+$02)          ;
  LD (ACTOR_SIZE),A       ;
  LD A,(ACTION)           ; Is there an exit in that direction?
  CALL FIND_EXIT          ;
  CP $FF                  ;
  JR NZ,MOVE_2            ;
MOVE_1:
  CALL TOO_DARK           ; No way through. In the light, the ordinary refusal
  JP NC,REFUSE            ;
  CALL FOR_REAL              ; In the dark the player falls: halve byte 5 of
  LD IX,PLAYER               ; the player's record...
  AND A                      ;
  LD HL,MSG_BUT_FALL_AND_HIT ;
  RR (IX+$05)                ;
  JP NZ,RUN_MESSAGE_HL    ; ...and while anything is left, "but fall and hit
                          ; your HEAD." -- six falls are survived
  LD HL,MSG_BUT_FALL_AND_SMASH ; The seventh empties it: "but fall and smash
  CALL RUN_MESSAGE_HL          ; your skull.", and PLAYER_DIES
  JP PLAYER_DIES               ;
MOVE_2:
  LD A,(IX+$02)           ; The exit leads to location 0: nowhere yet
  AND A                   ;
  JR Z,MOVE_1             ;
  LD (DESTINATION),A      ; Keep the destination; A = the object the way goes
  LD A,(IX+$01)           ; through
  CALL CAN_PASS           ; Can it be used (CAN_PASS)? 1 no, 2 too small, 3 no
  DEC A                   ; room there
  JR Z,MOVE_1             ;
  DEC A                   ;
  JR Z,MOVE_5             ;
  DEC A                   ;
  JR Z,MOVE_6             ;
; This entry point is used by the routine at MOVE_CONTENTS.
MOVE_THERE:
  CALL FOR_REAL           ; Move: the actor's location becomes the destination
  LD (IY+$10),B           ;
  LD A,(ACTING)           ; And everything it holds goes too
  CALL MOVE_CONTENTS      ;
  LD A,(ACTING)           ; The rest is for the player only
  CP $00                  ;
  RET NZ                  ;
  LD IX,ARRIVAL_HOOKS     ; Run the place's arrival hook, if it has one
  LD A,(DESTINATION)      ; (ARRIVAL_HOOKS)
  CALL FIND_RECORD        ;
  JR Z,ARRIVE             ;
  LD L,(IX+$01)           ;
  LD H,(IX+$02)           ;
  CALL RUN_ROUTINE        ;
; This entry point is used by the routine at AT_FOREST_RIVER.
ARRIVE:
  CALL TOO_DARK           ; In the dark, that is all
  RET C                   ;
  LD A,(ACTING)           ; A = the destination
  AND A                   ;
  LD A,(DESTINATION)      ;
  JR NZ,MOVE_4            ;
  LD HL,(DESTINATION_ROOM) ; Been here before? On at DESCRIBE_BRIEFLY. If not,
  BIT 6,(HL)               ; mark the room visited (bit 6)
  JP NZ,DESCRIBE_BRIEFLY   ;
  SET 6,(HL)               ;
  PUSH AF                  ;
  LD IX,VISIT_SCORES      ; And score it (VISIT_SCORES)
  CALL FIND_RECORD        ;
  JR Z,MOVE_3             ;
  PUSH DE                 ;
  LD E,(IX+$01)           ;
  LD D,(IX+$02)           ;
  LD HL,(SCORE)           ;
  ADD HL,DE               ;
  LD (SCORE),HL           ;
  POP DE                  ;
MOVE_3:
  POP AF                  ; Then DESCRIBE_ROOM
MOVE_4:
  JP DESCRIBE_ROOM        ;
MOVE_5:
  LD HL,MSG_IS_TOO_SMALL_FOR
  JR MOVE_7
MOVE_6:
  LD IX,(DESTINATION_ROOM)
  LD HL,MSG_IS_TOO_FULL_FOR
MOVE_7:
  PUSH HL
  LD L,(IX+$02)
  LD H,(IX+$03)
  EX (SP),HL
  CALL RUN_MESSAGE_HL
  RET

; Can the actor go this way?
;
; Used by the routines at MOVE and GO_THROUGH.
;
; A way through an object is shut unless the object is open (flag bit 5) or
; broken (bit 3), and the window, with bit 7 of its byte 4, will never let the
; player through at all. The actor, with all it carries (ACTOR_SIZE), must fit
; the opening -- byte 2 of the object's record -- and then the room it goes
; into must have space for it: byte 1 of a room's record is how much it holds,
; and $FF, for nearly every room, is no limit.
;
; I:A The object the way goes through, or 0
; O:A 0 it can; 1 it is shut; 2 "the ... is too small for you to enter."; 3
;     "... is too full for you to enter."
CAN_PASS:
  AND A                   ; No object in the way: only the room to check
  JR Z,CAN_PASS_1         ;
  CALL GET_OBJECT         ; Shut
  LD A,(IX+$07)           ;
  AND $28                 ;
  JR Z,CAN_PASS_5         ;
  LD A,(ACTING)           ; The window: never for the player
  AND A                   ;
  JR NZ,CAN_PASS_0        ;
  BIT 7,(IX+$04)          ;
  JR NZ,CAN_PASS_5        ;
CAN_PASS_0:
  LD A,(ACTOR_SIZE)       ; Too big for the opening
  LD B,(IX+$02)           ;
  SUB B                   ;
  JR NC,CAN_PASS_4        ;
CAN_PASS_1:
  LD A,(DESTINATION)       ; The room's capacity, less what is in it...
  LD B,A                   ;
  CALL GET_ROOM            ;
  LD (DESTINATION_ROOM),IX ;
  LD A,$FF                 ;
  CP (IX+$01)              ;
  JR Z,CAN_PASS_2          ;
  LD A,B                   ;
  CALL ROOM_LEFT           ;
  LD C,A                   ;
  LD A,(ACTOR_SIZE)       ; ...against the actor's size
  SUB C                   ;
  JR NC,CAN_PASS_3        ;
CAN_PASS_2:
  XOR A                   ; It can
  RET                     ;
CAN_PASS_3:
  LD A,$03                ; 3: the room is full
  AND A                   ;
  RET                     ;
CAN_PASS_4:
  LD A,$02                ; 2: too small
  AND A                   ;
  RET                     ;
CAN_PASS_5:
  LD A,$01                ; 1: shut
  AND A                   ;
  RET                     ;

; Is the character in A shut inside something?
;
; Used by the routine at LOOK_THROUGH.
;
; I:A The character
; O:F NZ if something shut holds it, at any depth
SHUT_IN_ACTOR:
  PUSH IX
  CALL GET_OBJECT
SHUT_IN_ACTOR_0:
  LD A,(IX+$01)
  CP $FF
  JR Z,SHUT_IN_ACTOR_1
  CALL GET_OBJECT
  BIT 5,(IX+$07)
  JR NZ,SHUT_IN_ACTOR_0
  OR $01
SHUT_IN_ACTOR_1:
  POP IX
  RET

; LOOK THROUGH, carried by doors and the like
;
; Used by the routine at WINDOW_OTHERS.
;
; Not through something shut ("the ... is closed."). The place beyond is shown
; as if the actor were there for a moment -- "you see" and its description --
; if it is lit, and "it is dark." if not. LOOK_ACROSS, the rivers' LOOK ACROSS,
; is the same without the shut test. Nothing at all happens for an actor shut
; inside something (SHUT_IN_ACTOR).
LOOK_THROUGH:
  LD A,(TARGET)           ; Shut: "the ... is closed."
  CALL GET_OBJECT         ;
  CALL IS_SHUT            ;
  JP Z,SAY_STATE          ;
LOOK_ACROSS:
  LD A,(ACTING)           ; The actor shut in something: nothing
  CALL SHUT_IN_ACTOR      ;
  RET NZ                  ;
  CALL EXIT_VIA           ; The way through it, and where it leads
  CP $FF                  ;
  JP Z,REFUSE             ;
  LD A,(IX+$02)           ;
  CP $00                  ;
  JP Z,REFUSE             ;
  CALL FOR_REAL           ; The test ends here
  PUSH IX                 ; Dark there: "it is dark."
  CALL GET_ROOM           ;
  BIT 7,(IX+$00)          ;
  POP IX                  ;
  JR Z,LOOK_THROUGH_0     ;
  LD IY,(ACTOR)           ; Show it, from there
  LD A,(IY+$10)           ;
  PUSH AF                 ;
  LD A,(IX+$02)           ;
  LD (IY+$10),A           ;
  CALL DESCRIBE_SEEN      ;
  POP AF                  ;
  LD (IY+$10),A           ;
  RET                     ;
LOOK_THROUGH_0:
  LD HL,MSG_IT_IS_DARK    ; "it is dark."
  JP RUN_MESSAGE_HL       ;

; GO THROUGH, carried by doors and the like as their own handler
;
; Used by the routine at WINDOW_OTHERS.
;
; The exit that goes through the object; refused if there is none, if it leads
; nowhere yet, or if the object will not let anyone through (CAN_PASS).
; Otherwise it is a move in that exit's direction, into MOVE past its darkness
; and captivity checks. GO_BY_EXIT is the way in for callers that have found
; the exit already.
GO_THROUGH:
  CALL EXIT_VIA           ; The exit through it
; This entry point is used by the routines at DO_ENTER and DO_FOLLOW.
GO_BY_EXIT:
  CP $FF                  ; None, or to nowhere yet: refused
  JP Z,REFUSE             ;
  LD A,(IX+$02)           ;
  CP $00                  ;
  JP Z,REFUSE             ;
  LD A,(IX+$01)           ; Will it let the actor through?
  PUSH IX                 ;
  CALL CAN_PASS           ;
  POP IX                  ;
  JP NZ,REFUSE            ;
  CALL FOR_REAL           ; The test ends here
  LD A,(IX+$00)           ; A move that way, with no object
  LD (ACTION),A           ;
  LD A,$FF                ;
  LD (TARGET),A           ;
  JP MOVE_ACTOR           ;

; FILL WITH, carried by the barrel
;
; Filling from a river's water fetches a fresh water of the same kind (objects
; $15 and $16, kept nowhere for this), which is what goes in; then it is PUT IN
; with the objects swapped. A container already full says so. As read, the
; liquid would then be refused by the last part of CAN_LIFT, which DO_PUT_IN
; begins with, so that FILL can never succeed; that has not been tried in play.
DO_FILL:
  LD IX,(TARGET_RECORD)   ; From a river's water? A fresh one
  LD A,(INSTRUMENT)       ;
  CP $17                  ;
  JR Z,DO_FILL_1          ;
  CP $18                  ;
  JR Z,DO_FILL_2          ;
DO_FILL_0:
  LD IY,(INSTRUMENT_RECORD) ; Only with a liquid
  BIT 1,(IY+$07)            ;
  JP Z,REFUSE               ;
  BIT 2,(IX+$07)          ; Full already: "the ... is full."
  LD A,$82                ;
  JP NZ,SAY_STATE         ;
  LD HL,DO_PUT_IN         ; Put it in, the objects swapped
  JP SWAPPED_OBJECTS      ;
DO_FILL_1:
  LD A,$15                  ; The fresh water, held by nothing
  LD IY,WATER               ;
  JR DO_FILL_3              ;
DO_FILL_2:
  LD A,$16                  ;
  LD IY,BLACK_WATER         ;
DO_FILL_3:
  LD (INSTRUMENT),A         ;
  LD (INSTRUMENT_RECORD),IY ;
  LD (IY+$01),$FF           ;
  JR DO_FILL_0              ;

; RUN: off in any direction that has a way out
;
; A random direction from 1 to 10, then the first from there on, going round,
; that the location has an exit in; then MOVE.
DO_RUN:
  LD A,$0A                ; A random direction, 1 to 10
  CALL RANDOM_POSITIVE    ;
  CP $00                  ;
  JR Z,DO_RUN             ;
DO_RUN_0:
  LD B,A                  ; Is there a way out that way? If not, the next,
  CALL FIND_EXIT          ; round from 10 to 1
  CP B                    ;
  JR Z,DO_RUN_1           ;
  LD A,B                  ;
  INC A                   ;
  CP $0A                  ;
  JR C,DO_RUN_0           ;
  LD A,$01                ;
  JR DO_RUN_0             ;
DO_RUN_1:
  LD (ACTION),A           ; Go
  JP MOVE                 ;

; ENTER and GO INTO
;
; Looks for an exit whose destination is the number in TARGET and goes through
; it as GO_THROUGH does. For these two actions that number is a place, not an
; object: the parser, at TROUBLE_AS_PLACE, tries a noun against the names of
; the rooms this one's exits lead to (ROOM_BY_NAME) before it tries the
; objects, so ENTER THE CAVE names the cave.
DO_ENTER:
  LD A,(TARGET)
  CALL EXIT_TO
  JP GO_BY_EXIT

; FOLLOW
;
; Only one step: the exit that leads to where the one followed is, if there is
; one, and through it. Already in the same place, or not next to it: "i cannot
; follow the ... from here."
DO_FOLLOW:
  LD IX,(ACTOR)           ; Already where the one followed is?
  LD B,(IX+$10)           ;
  LD IX,(TARGET_RECORD)   ;
  LD A,(IX+$10)           ;
  CP B                    ;
  JR Z,DO_FOLLOW_0        ;
  CALL EXIT_TO            ; An exit that leads there: through it
  CP $FF                  ;
  JP NZ,GO_BY_EXIT        ;
DO_FOLLOW_0:
  LD HL,MSG_I_CANNOT_FOLLOW_FROM ; "i cannot follow the ... from here."
  JP RUN_MESSAGE_HL              ;

; THROW AT
;
; Throwing something at a character is attacking the character with it, and at
; anything else striking it with it: the two objects are swapped and ATTACK
; WITH or STRIKE WITH is run (SWAPPED_OBJECTS). Done for real, the thrown thing
; lands, held by nothing, and the target reacts as to an attack.
DO_THROW_AT:
  CALL CAN_LIFT           ; Can it be lifted to throw?
  LD HL,DO_ATTACK           ; At a character: ATTACK WITH; at a thing: STRIKE
  LD A,$0F                  ; WITH
  LD IX,(INSTRUMENT_RECORD) ;
  BIT 6,(IX+$07)            ;
  JR NZ,DO_THROW_AT_0       ;
  LD HL,DO_STRIKE           ;
  LD A,$0B                  ;
DO_THROW_AT_0:
  LD (ACTION),A           ; Run it, the objects swapped
  CALL SWAPPED_OBJECTS    ;
  LD A,$2A                ; Only a test: done
  LD (ACTION),A           ;
  LD A,(DOING_IT)         ;
  CP $01                  ;
  RET NZ                  ;
  LD IX,(TARGET_RECORD)   ; It lands, held by nothing
  LD (IX+$01),$FF         ;
  LD A,$0F                ; And the target reacts as to an attack
  LD (ACTION),A           ;
  LD A,(TARGET)           ;
  JP REACT_TO_ACTION      ;

; Unreached: LD (IX+1),$FF -- let something go
UNREACHED_LET_GO:
  DEFB $DD,$36,$01,$FF

; TALK TO, and SAY TO
;
; Decides how many of the sentences just said the character will take on as
; orders (ASSIGN_ORDERS): none if it is not a character; exactly one if it is
; Gollum waiting for his riddle's answer (RIDDLE_ASKED); otherwise a random
; number up to byte 6 of its CHARACTERS slot -- and if that comes out 0, "...
; says " no "". A character whose byte 6 is 0 never takes an order and does not
; say so.
DO_TALK:
  CALL FOR_REAL           ; The test ends here
  LD A,(TARGET)           ; Not a character: no orders
  CALL FIND_CHARACTER     ;
  CP $FF                  ;
  LD A,$00                ;
  JR Z,DO_TALK_0          ;
  LD A,(RIDDLE_ASKED)     ; Gollum waiting for an answer: one
  CP $00                  ;
  JR NZ,DO_TALK_0         ;
  LD A,(IY+$06)           ; Never takes orders: none
  CP $00                  ;
  JR Z,DO_TALK_0          ;
  CALL RANDOM_POSITIVE    ; Otherwise a random number up to its limit
  CP $00                  ;
  JR Z,DO_TALK_1          ;
DO_TALK_0:
  CALL ASSIGN_ORDERS      ; Give it that many
  RET                     ;
DO_TALK_1:
  LD HL,MSG_SAY_S_NO      ; None: "... says " no "", and none
  CALL RUN_MESSAGE_HL     ;
  SUB A                   ;
  JR DO_TALK_0            ;

; DIG, carried by the sand
;
; Digging the sand opens it, and shows what it hides -- the trap door; digging
; it again closes it.
DO_DIG:
  CALL FOR_REAL
  LD IX,(TARGET_RECORD)
  BIT 5,(IX+$07)
  JP Z,OPEN_IT
  JP CLOSE_IT

; SHOOT
;
; Only with the bow in hand ("you are not carrying the bow."), and not at one's
; own side. Bard never misses. Anyone else shooting at the dragon always misses
; -- only Bard can kill it -- and at anything else misses about a third of the
; time: "the arrow misses the ... by a wide margin.". A hit, "the arrow hits
; the ...", kills a living character (KILL) and strikes anything else as STRIKE
; WITH would; the arrow is spent, held by nothing, unless it was what was shot
; at.
DO_SHOOT:
  LD A,$19                       ; Not carrying the bow: refused
  CALL ACTOR_HAS_A               ;
  LD HL,MSG_NOT_CARRYING_THE_BOW ;
  JP NC,RUN_MESSAGE_HL           ;
  CALL SAME_SIDE          ; Not its own side; the test ends here
  CALL FOR_REAL           ;
  LD A,$0F                ; It is an attack
  LD (ACTION),A           ;
  LD A,(ACTING)           ; Bard: a hit
  CP $46                  ;
  JR Z,DO_SHOOT_0         ;
  LD A,(TARGET)              ; At the dragon: a miss
  CP $3C                     ;
  LD HL,MSG_THE_ARROW_MISS_E ;
  JP Z,RUN_MESSAGE_HL        ;
  LD A,$08                ; Otherwise a miss one time in three
  CALL RANDOM_POSITIVE    ;
  CP $03                  ;
  JP C,RUN_MESSAGE_HL     ;
DO_SHOOT_0:
  LD IX,STRONG_ARROW      ; The arrow is spent
  LD A,(TARGET)           ;
  CP $1A                  ;
  JR Z,DO_SHOOT_1         ;
  LD (IX+$01),$FF         ;
DO_SHOOT_1:
  LD HL,MSG_THE_ARROW_HIT_S ; "the arrow hits the ..."
  CALL RUN_MESSAGE_HL       ;
  LD IX,(TARGET_RECORD)   ; Not a living character: struck, as STRIKE WITH
  CALL IS_ALIVE           ;
  JP NZ,DO_STRIKE         ;
  LD A,(TARGET)           ; Killed
  CALL KILL               ;
  LD A,$06                ;
  JP SAY_STATE            ;

; The player is dead: say so and start again
;
; Used by the routines at MOVE, INTO_THE_RIVER, KILL, DRAGON_HUNTS,
; SINKING_IN_BOG, GOLLUM_HEARS_ANSWER, TROLLS_EAT, WEB_SMOTHERS, EYES_STING and
; AT_FOREST_RIVER.
;
; Prints "you are dead." as a sentence about the player, calls SHOW_SCORE,
; waits for any key and goes back into the start-up at NEW_GAME. Reached, for
; one, from MOVE when the player falls in the dark once too often.
PLAYER_DIES:
  SUB A                   ; The sentence is about the player
  LD (ACTING),A           ;
  LD HL,MSG_DEAD          ; "you are dead."
  CALL RUN_MESSAGE_HL     ;
  CALL SHOW_SCORE         ; Not yet worked out
; This entry point is used by the routine at CHECK_WON.
WAIT_AND_RESTART:
  XOR A                   ; Wait for any key
  IN A,($FE)              ;
  AND $1F                 ;
  CP $1F                  ;
  JR Z,WAIT_AND_RESTART   ;
  JP NEW_GAME             ; And start again

; INVENTORY
;
; "you are carrying." and a list of what the actor holds, or "nothing".
DO_INVENTORY:
  CALL FOR_REAL           ; The test ends here
  LD HL,MSG_CARRYING      ; "you are carrying."
  CALL RUN_MESSAGE_HL     ;
  LD A,(ACTING)           ; Nothing? "nothing"
  CALL COUNT_HELD         ;
  AND A                   ;
  LD HL,MSG_NOTHING       ;
  JP Z,RUN_MESSAGE_HL     ;
  LD A,(ACTING)           ; Otherwise the list
  LD IX,(ACTOR)           ;
  LD B,(IX+$10)           ;
  JP LIST_HERE            ;

; OPEN, carried by doors and containers as their own handler
;
; Used by the routines at OPEN_CRACK, GOBLINS_DOOR_OPENED, TRAP_DOOR_OPEN_CLOSE
; and WINDOW_OPEN_CLOSE.
;
; Not if it is locked or open already ("the ... is locked.", "the ... is
; open."). Opening sets flag bit 5, and a container in one place with something
; visible inside shows what: "you see". OPEN_IT is the way in for callers that
; only want it opened.
DO_OPEN:
  CALL LOCK_STATE         ; Locked, or open already: say which
  JP NZ,SAY_STATE         ;
  CALL FOR_REAL           ; The test ends here
; This entry point is used by the routines at DO_DIG and SIDE_DOOR_UNLOCKED.
OPEN_IT:
  SET 5,(IX+$07)          ; Open
  LD A,(IX+$00)           ; Not a container in one place: done
  DEC A                   ;
  RET NZ                  ;
  LD A,(TARGET)           ; Nothing in it: done
  CALL COUNT_HELD         ;
  AND A                   ;
  RET Z                   ;
  LD A,(TARGET)           ; Not yet worked out
  CALL CONTENTS_INTRO     ;
  RET C                   ;
  LD B,(IX+$10)           ; "you see" and what is in it
  LD A,(TARGET)           ;
  JP LIST_HERE            ;

; CLOSE
;
; Used by the routines at TRAP_DOOR_OPEN_CLOSE and WINDOW_OPEN_CLOSE.
;
; Not if it is shut already ("the ... is closed."); otherwise flag bit 5 is
; cleared.
DO_CLOSE:
  LD IX,(TARGET_RECORD)
  CALL IS_SHUT
  JP Z,SAY_STATE
  CALL FOR_REAL
; This entry point is used by the routine at DO_DIG.
CLOSE_IT:
  RES 5,(IX+$07)
  RET

; Are attacker and target on the same side?
;
; Used by the routines at DO_SHOOT and DO_ATTACK.
;
; Bits 4 to 6 of byte 4 of each record are the sides; sharing one ends the
; handler that called this with SUCCEEDED clear -- it would not work. The
; player alone can turn on a friend: attacked by the player, a character on the
; player's side (bit 4) is taken off it first, so the attack goes ahead and it
; is an enemy from then on.
SAME_SIDE:
  LD IX,(TARGET_RECORD)   ; The player attacking a friend: no longer a friend
  LD A,(ACTING)           ;
  AND A                   ;
  JR NZ,SAME_SIDE_0       ;
  BIT 4,(IX+$04)          ;
  JR Z,SAME_SIDE_0        ;
  RES 4,(IX+$04)          ;
SAME_SIDE_0:
  LD A,(IX+$04)           ; Sharing a side? Then no: out of the caller, would
  AND $70                 ; not work
  LD IX,(ACTOR)           ;
  AND (IX+$04)            ;
  RET Z                   ;
  POP HL                  ;
  XOR A                   ;
  LD (SUCCEEDED),A        ;
  RET                     ;

; ATTACK WITH, and STRIKE WITH through THROW AT
;
; The attacker's strength, byte 5 of its record, plus the weapon's if there is
; one -- bare hands are a FIST -- against the target's defence, byte 6, each
; with a random -10 to +10 (JOSTLE). A blow no stronger than the defence is
; wasted: "but the effort is wasted. his defense is too strong.". One more than
; 16 stronger kills: "with one well placed blow you cleave his skull." and
; KILL. Anything between picks a message from WOUNDS by how much stronger it
; was, and wears the target's strength and defence down by it.
;
; Only something in one place can be a weapon: "you cannot kill with the ...".
; And no one attacks their own side (SAME_SIDE).
DO_ATTACK:
  CALL SAME_SIDE          ; Not against its own side
  LD A,(INSTRUMENT)         ; The weapon's name, or FIST, for the messages
  LD HL,$026B               ;
  CP $FF                    ;
  JR Z,DO_ATTACK_0          ;
  LD IX,(INSTRUMENT_RECORD) ;
  LD L,(IX+$08)             ;
  LD H,(IX+$09)             ;
DO_ATTACK_0:
  LD (WEAPON_NAME),HL       ;
  LD IX,(ACTOR)           ; B = the attacker's strength
  LD B,(IX+$05)           ;
  LD A,(INSTRUMENT)       ; No weapon: that is all
  INC A                   ;
  JR Z,DO_ATTACK_2        ;
  LD IY,(INSTRUMENT_RECORD)      ; A weapon in more than one place: "you cannot
  LD A,(IY+$00)                  ; kill with the ..."
  DEC A                          ;
  LD HL,MSG_YOU_CANNOT_KILL_WITH ;
  JP NZ,RUN_MESSAGE_HL           ;
  LD A,(IY+$05)           ; Otherwise its strength is added, at most 255
  ADD A,B                 ;
  JR NC,DO_ATTACK_1       ;
  LD A,$FF                ;
DO_ATTACK_1:
  LD B,A                  ;
DO_ATTACK_2:
  LD A,B                  ; A random share of it
  CALL JOSTLE             ;
  LD B,A                  ;
  CALL FOR_REAL           ; The test ends here
  LD IX,(TARGET_RECORD)   ; A random share of the target's defence
  LD A,(IX+$06)           ;
  CALL JOSTLE             ;
  CP B                        ; No stronger: "but the effort is wasted..."
  LD HL,MSG_BUT_THE_EFFORT_IS ;
  JP NC,RUN_MESSAGE_HL        ;
  LD C,A                  ; More than 16 stronger?
  ADD A,$10               ;
  JR NC,DO_ATTACK_3       ;
  LD A,$FF                ;
DO_ATTACK_3:
  CP B                    ;
  JR C,DO_ATTACK_6        ;
  LD A,B                  ; Otherwise a wound: the message for how much
  SUB C                   ; stronger...
  RLCA                    ;
  LD E,A                  ;
  LD D,$00                ;
  LD IY,WOUNDS            ;
  ADD IY,DE               ;
  LD L,(IY+$00)           ;
  LD H,(IY+$01)           ;
  RRCA                    ; ...and the target's strength and defence worn down
  RRCA                    ; by it
  LD B,A                  ;
  CPL                     ;
  ADD A,(IX+$05)          ;
  JR NC,DO_ATTACK_4       ;
  LD (IX+$05),A           ;
DO_ATTACK_4:
  LD A,B                  ;
  RRCA                    ;
  CPL                     ;
  ADD A,(IX+$06)          ;
  JR NC,DO_ATTACK_5       ;
  LD (IX+$06),A           ;
DO_ATTACK_5:
  JP RUN_MESSAGE_HL       ; Print the wound
DO_ATTACK_6:
  LD HL,MSG_WITH_ONE_WELL_PLACE ; A kill: "...you cleave his skull.", dead, and
  CALL RUN_MESSAGE_HL           ; it is said
  SET 3,(IX+$07)                ;
  LD A,(TARGET)                 ;
  CALL KILL                     ;
  LD A,$06                      ;
  JP SAY_STATE                  ;

; A plus a random -10 to +10, kept to 0-255
;
; Used by the routine at DO_ATTACK.
JOSTLE:
  PUSH BC
  LD B,A
  LD A,$0A
  CALL RANDOM
  LD C,A
  ADD A,B
  JR NC,JOSTLE_0
  XOR A
  BIT 7,C
  JR NZ,JOSTLE_0
  DEC A
JOSTLE_0:
  POP BC
  RET

; What a wound is said to be, by how much stronger the blow was
;
; The messages the fight picks between, from a stagger to a stunning hit; the
; stronger the blow, the further down the table.
WOUNDS:
  DEFW MSG_SEEM_TIRED_STAGGER_BUT
  DEFW MSG_SWING_FEEBLY_AT_BUT
  DEFW MSG_BRANDISH_BUT_ON_GUARD
  DEFW MSG_SLASH_AT_BUT_THE
  DEFW MSG_SWEEPS_PAST_CLOSE_TO
  DEFW MSG_SWING_BROADSIDE_AT_BODY
  DEFW MSG_THRUST_BACK_LOSE_FOOTING
  DEFW MSG_HIT_WITH_A_GLANCING
  DEFW MSG_A_FAST_STROKE_SWEEPS
  DEFW MSG_A_FAST_BLOW_KNOCKS
  DEFW MSG_HIT_HARD_ON_THE
  DEFW MSG_GIVE_A_NASTY_SLASH
  DEFW MSG_SLICE_HAND_BLOOD_DRIPS
  DEFW MSG_A_NASTY_SLICE_MISS
  DEFW MSG_GIVE_A_VICIOUS_CUT
  DEFW MSG_V_I_O_L

; Is the first object in only one place? Z if so
;
; Used by the routine at CAN_LIFT.
ONE_PLACE:
  LD IX,(TARGET_RECORD)
  LD A,(IX+$00)
  DEC A
  RET

; PUT IN and DROP IN, carried by the containers
;
; What goes in must be something in one place, and not a liquid -- the last
; part of CAN_LIFT -- and not the container itself. The container must be open
; -- except to PUT something ON it -- and have room: its size, byte 2, less
; what is in it, more than the thing's size ("the ... is too full."). Then it
; is in the container, and where the container is.
DO_PUT_IN:
  CALL CAN_LIFT_HERE      ; Something that can be put anywhere
  LD A,(INSTRUMENT)       ; Not into itself
  CP (IX+$01)             ;
  JP Z,CANNOT_DO          ;
  LD IY,(INSTRUMENT_RECORD) ; Shut, unless it is PUT ON: "the ... is closed."
  LD A,(ACTION)             ;
  CP $12                    ;
  JR Z,DO_PUT_IN_0          ;
  BIT 5,(IY+$07)            ;
  JR Z,DO_PUT_IN_2          ;
DO_PUT_IN_0:
  LD A,(IY+$02)           ; Room for it? "the ... is too full."
  SUB (IX+$02)            ;
  JR C,DO_PUT_IN_1        ;
  PUSH AF                 ;
  LD A,(INSTRUMENT)       ;
  CALL SIZE_HELD          ;
  LD B,A                  ;
  POP AF                  ;
  SUB B                   ;
DO_PUT_IN_1:
  LD HL,MSG_IS_TOO_FULL   ;
  JP C,RUN_MESSAGE_HL     ;
  JP Z,RUN_MESSAGE_HL     ;
  CALL FOR_REAL           ; The test ends here
  LD A,(IY+$10)           ; In it, and where it is
  LD (IX+$10),A           ;
  LD A,(INSTRUMENT)       ;
  LD (IX+$01),A           ;
  RET                     ;
DO_PUT_IN_2:
  LD A,$05                ; "the ... is closed."
  JP SAY_STATE_OF         ;

; DRINK
;
; A drink from a container leaves it no longer full and gives one point of
; strength; anything else is eaten, as EAT.
DO_DRINK:
  CALL FOR_REAL
  LD IX,(TARGET_RECORD)
  LD A,(IX+$01)
  CP $FF
  JR Z,DO_EAT
  CALL GET_OBJECT
  RES 2,(IX+$07)
  LD A,$01
  JR GAIN_STRENGTH

; EAT
;
; Used by the routines at DO_DRINK and TROLLS_EAT.
;
; Ten points of strength, and the thing is gone from everywhere. Strength
; reaching 128 kills the eater: "his foul gluttony has killed the ...". That is
; the end the trolls come to when they eat the player, whose own record has
; PLAYER_DIES after EAT.
DO_EAT:
  CALL FOR_REAL
  LD A,$0A
; This entry point is used by the routine at DO_DRINK.
GAIN_STRENGTH:
  LD IX,(ACTOR)           ; Stronger, unless it is too much
  ADD A,(IX+$05)          ;
  CP $80                  ;
  JR NC,DO_EAT_1          ;
  LD (IX+$05),A           ;
  LD IX,(TARGET_RECORD)   ; The thing is nowhere
  LD (IX+$01),$FF         ;
  LD B,(IX+$00)           ;
DO_EAT_0:
  LD (IX+$10),$00         ;
  INC IX                  ;
  DJNZ DO_EAT_0           ;
  RET                     ;
DO_EAT_1:
  LD HL,MSG_FOUL_GLUTTONY_HAS_KILL ; Too much: dead of gluttony
  CALL RUN_MESSAGE_HL              ;
  LD A,(ACTING)                    ;
  JP KILL                          ;

; Unreached: LD A,$83 and JP SAY_STATE_OF -- "the ... is broken."
UNREACHED_SAY_BROKEN:
  DEFB $3E,$83,$C3,$64,$A1

; STRIKE WITH, carried by whatever can be broken
;
; Used by the routines at DO_SHOOT and WINDOW_OTHERS.
;
; Not a liquid, not what is broken already ("the ... is broken."), and not what
; has no defence at all. The blow is the weapon's strength, the striker's and a
; random 0 to 21 together, against the thing's defence, byte 6: at least equal,
; and the thing breaks -- flag bit 3, "broken" in its name (BROKEN_OR_DEAD),
; its strength halved, and a thing that holds others in or on it spills them.
; Then the weapon itself is tried the same way against the thing's defence, and
; a weapon weaker than what it hit breaks too: striking the trap door with the
; sword can cost the sword.
DO_STRIKE:
  LD IX,(TARGET_RECORD)   ; Not a liquid; broken already: say so
  BIT 1,(IX+$07)          ;
  JP NZ,REFUSE            ;
  BIT 3,(IX+$07)          ;
  JP NZ,DO_STRIKE_4       ;
  SUB A                   ; Nothing with no defence
  CP (IX+$06)             ;
  JP Z,REFUSE             ;
  LD B,A                  ; B = the weapon's strength, 0 with none
  LD A,(INSTRUMENT)         ; A weapon: one with strength, and one that can
  INC A                     ; itself be struck
  JR Z,DO_STRIKE_0          ;
  LD IY,(INSTRUMENT_RECORD) ;
  LD A,(IY+$05)             ;
  AND A                     ;
  JP Z,REFUSE               ;
  PUSH IX                   ;
  LD IX,(INSTRUMENT_RECORD) ;
  LD A,$0B                  ;
  CALL FIND_OBJECT_HANDLER  ;
  POP IX                    ;
  INC A                     ;
  JP Z,REFUSE               ;
  LD B,(IY+$05)             ;
DO_STRIKE_0:
  CALL FOR_REAL           ; The test ends here
  LD A,$15                ; The blow, against its defence
  CALL RANDOM             ;
  ADD A,B                 ;
  LD IY,(ACTOR)           ;
  ADD A,(IY+$05)          ;
  JR NC,DO_STRIKE_1       ;
  LD A,$FF                ;
DO_STRIKE_1:
  SUB (IX+$06)            ;
  JR C,DO_STRIKE_2        ;
  SET 3,(IX+$07)          ; Broken: named so, weaker, and spilling what it held
  LD A,(TARGET)           ;
  CALL BROKEN_OR_DEAD     ;
  SRA (IX+$05)            ;
  LD A,(IX+$04)           ;
  CP $02                  ;
  CALL C,EMPTY_FIRST      ;
  LD A,$83                ;
  CALL SAY_STATE          ;
DO_STRIKE_2:
  LD A,(INSTRUMENT)         ; The weapon against the same defence...
  CP $FF                    ;
  RET Z                     ;
  LD IY,(INSTRUMENT_RECORD) ;
  BIT 3,(IY+$07)            ;
  RET NZ                    ;
  LD B,(IY+$06)             ;
  LD A,$15                  ;
  CALL RANDOM               ;
  ADD A,B                   ;
  JR NC,DO_STRIKE_3         ;
  LD A,$FF                  ;
DO_STRIKE_3:
  SUB (IX+$06)              ;
  RET C                   ; ...and broken too if it was weaker
  SET 3,(IY+$07)          ;
  LD A,(INSTRUMENT)       ;
  CALL BROKEN_OR_DEAD     ;
  LD A,(IY+$05)           ;
  SRA A                   ;
  LD (IY+$05),A           ;
  CALL EMPTY_FIRST        ;
  PUSH IY                 ;
  POP IX                  ;
DO_STRIKE_4:
  LD A,$83                ; "the ... is broken."
  JP SAY_STATE            ;

; GIVE TO
;
; Used by the routine at ELROND_GIVES_LUNCH.
;
; The giver must be carrying it, and the one given it must be able to carry it
; too ("you are carrying too much."). Then it is theirs, and in their place,
; with everything inside it.
DO_GIVE:
  LD IY,(INSTRUMENT_RECORD) ; Not carrying it: refused
  CALL ACTOR_HAS_FIRST      ;
  LD HL,MSG_NOT_CARRYING_IT ;
  JP NC,RUN_MESSAGE_HL      ;
GIVE_TOO_MUCH:
  LD A,(INSTRUMENT)           ; More than the other can carry: refused
  CALL WEIGHT_HELD            ;
  LD IX,(TARGET_RECORD)       ;
  ADD A,(IX+$03)              ;
  PUSH AF                     ;
  POP BC                      ;
  LD A,(IY+$03)               ;
  SUB B                       ;
  LD HL,MSG_CARRYING_TOO_MUCH ;
  JP C,RUN_MESSAGE_HL         ;
  CALL FOR_REAL           ; The test ends here
  LD A,(INSTRUMENT)       ; Theirs now, and where they are
  LD (IX+$01),A           ;
  LD A,(IY+$10)           ;
  LD (IX+$10),A           ;
  LD B,A                  ; With all it holds
  LD A,(TARGET)           ;
  JP MOVE_CONTENTS        ;

; EXAMINE
;
; Used by the routine at ELROND_READS_MAP.
;
; An object's own description, bytes 14 and 15 of its record, if it has one;
; otherwise "you see" and its name. Some objects carry their own EXAMINE
; instead -- the curious map's is ELROND_READS_MAP, the magic door's
; MAGIC_DOOR_EXAMINED.
DO_EXAMINE:
  CALL FOR_REAL           ; The test ends here
  LD A,(TARGET)           ; Its own description, if it has one
  CALL GET_OBJECT         ;
  LD L,(IX+$0E)           ;
  LD H,(IX+$0F)           ;
  LD A,H                  ;
  OR L                    ;
  JP NZ,RUN_MESSAGE_HL    ;
  LD HL,MSG_SEE           ; Otherwise "you see" and its name
  CALL RUN_MESSAGE_HL     ;
  PUSH IX                 ;
  POP IY                  ;
  CALL PRINT_RECORD_NAME  ;
  LD A,$2E                ;
  CALL PRINT_CHAR         ;
  CALL NEW_LINE           ;
  RET                     ;

; EMPTY, carried by the barrel
;
; Not if it is shut ("the ... is closed.") or has nothing in it ("the ... is
; empty."); otherwise EMPTY_OUT, and it is no longer full.
DO_EMPTY:
  LD IX,(TARGET_RECORD)
  CALL IS_SHUT
  JP Z,SAY_STATE
  LD A,(TARGET)
  CALL COUNT_HELD
  CP $00
  JR Z,DO_EMPTY_0
  CALL FOR_REAL
  CALL EMPTY_FIRST
  RES 2,(IX+$07)
  RET
DO_EMPTY_0:
  LD A,$02
  JP SAY_STATE

; PUT IN or DROP IN a river: swept away
;
; A river is in two places, and whatever goes in comes out at the other,
; downstream: "and it gets swept away.". If that was the player, carried off in
; something, and the river leads nowhere, it is death.
INTO_THE_RIVER:
  CALL CAN_LIFT_HERE
  CALL FOR_REAL
  LD A,(ACTOR_AT)
  LD IX,(INSTRUMENT_RECORD)
  LD B,(IX+$00)
INTO_THE_RIVER_0:
  CP (IX+$10)
  JR Z,INTO_THE_RIVER_1
  INC IX
  DJNZ INTO_THE_RIVER_0
  JP CANNOT_DO
INTO_THE_RIVER_1:
  LD A,(IX+$11)
  DEC B
  JR NZ,INTO_THE_RIVER_2
  XOR A
INTO_THE_RIVER_2:
  PUSH AF
  LD HL,MSG_AND_IT_GET_SWEPT
  CALL RUN_MESSAGE_HL
  POP AF
  LD IX,(TARGET_RECORD)
  LD (IX+$10),A
  LD (IX+$01),$FF
  LD B,A
  LD A,(TARGET)
  CALL MOVE_CONTENTS
  LD A,(PLAYER_WHERE)
  AND A
  JP Z,PLAYER_DIES
  RET

; LOCK WITH, once the right key is known
;
; Used by the routine at ROCK_DOOR_KEY.
;
; Not if it is locked or open, and not with a broken key ("the ... is
; broken."). The same code unlocks, from DO_UNLOCK, by writing the last byte of
; the SET 0 or RES 0 at LOCK_BIT_OP.
DO_LOCK:
  CALL LOCK_STATE         ; Locked or open already: say which
  JP NZ,SAY_STATE         ;
  LD A,$C6                ; SET 0: lock it
; This entry point is used by the routine at DO_UNLOCK.
TURN_KEY:
  LD (LOCK_BIT_OP+$0003),A ; }
  LD IY,(INSTRUMENT_RECORD) ; A broken key will not turn
  BIT 3,(IY+$07)            ;
  LD A,$83                  ;
  JP NZ,SAY_STATE_OF        ;
  CALL FOR_REAL           ; The test ends here
LOCK_BIT_OP:
  SET 0,(IX+$07)          ; Bit 0: locked, or not
  RET

; UNLOCK WITH, once the right key is known
;
; Used by the routine at ROCK_DOOR_KEY.
DO_UNLOCK:
  LD IX,(TARGET_RECORD)   ; Not locked: "the ... is unlocked."
  BIT 0,(IX+$07)          ;
  LD A,$00                ;
  JP Z,SAY_STATE          ;
  CALL OPEN_STATE         ; Open: "the ... is open."
  JP NZ,SAY_STATE         ;
  LD A,$86                ; RES 0: unlock it
  JR TURN_KEY             ;

; THROW THROUGH, carried by doors and the like
;
; The thrower must have it, the way through the object must exist and be open
; ("the ... is closed."); it lands in the place beyond, with all it holds. The
; trap door's record runs BARREL_THROWN after this.
THROW_THROUGH:
  CALL MUST_CARRY
  LD A,(INSTRUMENT)
  CALL EXIT_VIA_A
  CP $FF
  JP Z,REFUSE
  LD IY,(INSTRUMENT_RECORD)
  BIT 5,(IY+$07)
  LD A,$05
  JP Z,SAY_STATE_OF
  CALL FOR_REAL
  LD B,(IX+$02)
  LD IX,(TARGET_RECORD)
  LD (IX+$01),$FF
  LD (IX+$10),B
  LD A,(TARGET)
  JP MOVE_CONTENTS

; Is there anything that handles this action?
;
; Used by the routine at TRY_TARGETS.
;
; SUCCEEDED = 1 if so: an ordinary handler in ACTION_TABLE, one of the
; SECOND_FIRST actions, or a handler of the first object's own; 0 if not, or if
; the action makes no sense (SENSIBLE).
HANDLED:
  PUSH IX
  PUSH HL
  CALL SENSIBLE
  LD A,$00
  JR Z,HANDLED_0
  LD A,(ACTION)
  LD IX,ACTION_TABLE
  CALL FIND_RECORD
  CP $FF
  LD A,$01
  JR NZ,HANDLED_0
  CALL IS_SECOND_FIRST
  LD A,$01
  JR Z,HANDLED_0
  LD A,(TARGET)
  CALL GET_OBJECT
  LD A,(ACTION)
  CALL FIND_OBJECT_HANDLER
  LD A,$01
  JR C,HANDLED_0
  SUB A
HANDLED_0:
  LD (SUCCEEDED),A
  POP HL
  POP IX
  RET

; Carry out the action in ACTION to INSTRUMENT, for whoever is acting
;
; Used by the routines at OBEY, TRY_IT, WOULD_WORK, TARGET_TROUBLE and
; ACTOR_TRIES.
;
; The one place every action is done, the player's and every other character's
; alike. The action is refused outright if it makes no sense (SENSIBLE), and in
; the dark it can only be done to what the actor is carrying. Then the objects
; get the first say: an object can carry a handler of its own for an action
; (see FIND_OBJECT_HANDLER), and only if neither has one does ACTION_TABLE's
; ordinary handler run. For most actions the first object is asked; for the
; five in SECOND_FIRST -- DROP IN, PUT IN, PUT ON, TAKE OUT OF and THROW
; THROUGH -- the second object is asked first, since it is the container or the
; gap that decides.
;
; A handler is followed by any records after it keyed 0, which run too: the
; wine's record has the ordinary handler for DRINK followed by WINE_DRUNK under
; key 0, so drinking it does both. Last, each object that is a character reacts
; to what was done to it (REACT_TO_ACTION).
DO_ACTION:
  PUSH HL
  PUSH IX
  PUSH BC
  CALL SENSIBLE           ; Makes no sense? "i cannot do that."
  JP Z,DO_ACTION_9        ;
  CALL TOO_DARK           ; Can the actor see?
  JR NC,DO_ACTION_1       ;
  LD A,(NEEDS_LIGHT)      ; In the dark, only what the actor carries -- and
  AND A                   ; nothing at all while NEEDS_LIGHT is set
  JR NZ,DO_ACTION_0       ;
  CALL ACTOR_HAS_FIRST    ;
  JR NC,DO_ACTION_0       ;
  LD A,(INSTRUMENT)       ;
  CALL ACTOR_HAS_A        ;
  JR C,DO_ACTION_1        ;
DO_ACTION_0:
  LD HL,MSG_I_SEE_NOTHING_HERE ; "i see nothing here."
  CALL RUN_MESSAGE_HL          ;
  JR DO_ACTION_5               ;
DO_ACTION_1:
  LD A,(TARGET_IS_PLACE)  ; TARGET_IS_PLACE set, or no object: the ordinary
  CP $01                  ; handler
  JP Z,DO_ACTION_8        ;
  LD A,(TARGET)           ;
  CP $FF                  ;
  JP Z,DO_ACTION_8        ;
  CALL GET_OBJECT         ; The first object, in TARGET_RECORD: not being
  LD (TARGET_RECORD),IX   ; carried by somebody else
  LD A,(TARGET)           ;
  CALL CARRIED_BY_ANOTHER ;
  JR NZ,DO_ACTION_5       ;
  LD A,(INSTRUMENT)       ; No second object: ask the first
  CP $FF                  ;
  JR Z,DO_ACTION_2        ;
  LD A,(INSTRUMENT_IS_PLACE) ; INSTRUMENT_IS_PLACE set: the ordinary handler
  CP $01                     ;
  JR Z,DO_ACTION_8           ;
  LD A,(INSTRUMENT)         ; The second object, in INSTRUMENT_RECORD: not
  CALL GET_OBJECT           ; being carried by somebody else
  LD (INSTRUMENT_RECORD),IX ;
  CALL CARRIED_BY_ANOTHER   ;
  JR NZ,DO_ACTION_5         ;
  CALL IS_SECOND_FIRST    ; One of SECOND_FIRST? Ask the second object
  JR Z,DO_ACTION_3        ;
DO_ACTION_2:
  LD IX,(TARGET_RECORD)   ; Otherwise the first
DO_ACTION_3:
  LD A,(ACTION)            ; Does it have a handler of its own for this? If
  CALL FIND_OBJECT_HANDLER ; not, the ordinary one
  JR NC,DO_ACTION_8        ;
DO_ACTION_4:
  LD L,(IX+$01)           ; Run the handler, and every record after it keyed 0
  LD H,(IX+$02)           ;
  CALL RUN_ROUTINE        ;
  INC IX                  ;
  INC IX                  ;
  INC IX                  ;
  SUB A                   ;
  CP (IX+$00)             ;
  JR Z,DO_ACTION_4        ;
DO_ACTION_5:
  LD A,(DOING_IT)         ; Done quietly, as a test? Then that is all
  CP $01                  ;
  JR NZ,DO_ACTION_7       ;
  LD A,(ACTING)           ; Not yet worked out: for the player in the dark, a
  CP $00                  ; message at HL
  JR NZ,DO_ACTION_6       ;
  CALL TOO_DARK           ;
  CALL C,RUN_MESSAGE_HL   ;
DO_ACTION_6:
  LD A,(ACTION)             ; Each object that is a character reacts
  LD B,A                    ;
  LD A,(TARGET)             ;
  LD IX,(TARGET_RECORD)     ;
  CALL REACT_TO_ACTION      ;
  LD A,(INSTRUMENT)         ;
  LD IX,(INSTRUMENT_RECORD) ;
  CALL REACT_TO_ACTION      ;
DO_ACTION_7:
  POP BC
  POP IX
  POP HL
  RET
DO_ACTION_8:
  LD A,(ACTION)           ; The ordinary handler, from ACTION_TABLE
  LD IX,ACTION_TABLE      ;
  CALL FIND_RECORD        ;
  CP $FF                  ;
  JR NZ,DO_ACTION_4       ;
DO_ACTION_9:
  CALL CANNOT_DO          ; "i cannot do that."
  JR DO_ACTION_7          ;

; An action has been done to this object: if it is a character, it reacts
;
; Used by the routines at DO_THROW_AT and DO_ACTION.
;
; Only a character (flag bit 6), and only one without flag bit 3, which is not
; yet worked out.
REACT_TO_ACTION:
  BIT 6,(IX+$07)
  RET Z
  BIT 3,(IX+$07)
  RET NZ
  CALL REACT
  RET

; Is it too dark for the player to see?
;
; Used by the routines at NARRATE_ACTION, CLEAR_CANVAS, MOVE, DO_ACTION,
; NOTE_LIGHT and DO_CAPTURE.
;
; Characters are never in the dark: anyone but the player gets "no" at once.
; The player can see if inside something, or if the room is lit -- bit 7 of the
; first byte of its record. Otherwise only the short strong sword helps: it has
; to be with the player, and its flag byte at SHORT_STRONG_SWORD_FLAGS must
; have bit 2 set, bit 3 clear and bit 4 set, which is what XOR $F7 then AND $1C
; tests for in one go. It starts as $94, so it glows from the beginning, and
; carrying it lights every dark place.
;
; Twenty-six of the seventy-nine rooms are dark, and they are the ones the
; story says are: the trolls' cave, the goblins' dungeon, cavern and fourteen
; identical stuffy dark passages, Gollum's lake, the Elvenking's halls, cellar
; and dungeon, and the passage into the mountain.
;
; What depends on it: MOVE, which in the dark throws the direction away and
; picks one from 1 to 10 at random; and CLEAR_CANVAS, which blacks the picture
; out instead of drawing it.
;
; O:F Carry set if the player cannot see
TOO_DARK:
  LD A,(ACTING)           ; Characters can always see: only the player is ever
  AND A                   ; in the dark
  RET NZ                  ;
  PUSH IX
  PUSH BC
  LD IX,PLAYER            ; The player shut inside something can see
  CALL SHUT_IN            ;
  INC A                   ;
  JR NZ,TOO_DARK_0        ;
  CALL ACTOR_ROOM         ; So can a player in a lit room (bit 7 of its first
  BIT 7,(IX+$00)          ; byte)
  JR NZ,TOO_DARK_2        ;
TOO_DARK_0:
  PUSH IY                  ; Otherwise only by the sword, object $0E, if it is
  LD A,$0E                 ; within reach...
  LD IY,SHORT_STRONG_SWORD ;
  CALL IN_REACH            ;
  POP IY                   ;
  JR Z,TOO_DARK_1          ;
  LD A,(SHORT_STRONG_SWORD_FLAGS) ; ...and glowing: flags bit 2 set, bit 3
  XOR $F7                         ; clear, bit 4 set, all in one test
  AND $1C                         ;
  JR Z,TOO_DARK_3                 ;
TOO_DARK_1:
  LD HL,MSG_IT_IS_DARK    ; Too dark: carry set, and HL = "it is dark."
  SCF                     ;
TOO_DARK_2:
  POP BC
  POP IX
  RET
TOO_DARK_3:
  AND A                   ; Can see: carry clear
  JR TOO_DARK_2           ;

; Describe a location, opening "you see"
;
; Used by the routine at LOOK_THROUGH.
DESCRIBE_SEEN:
  LD HL,MSG_SEE
  JR DESCRIBE_WITH_OPENING

; Describe a location in full: "you are in ...", the picture, and what is there
;
; Used by the routines at DO_LOOK, MOVE and JUMP_ONTO_BARREL.
;
; What MOVE does on the first visit to a place. The opening phrase is a message
; with a word left to fill in: bits 1-3 of byte 0 of the room's record pick it
; from ROOM_PREPOSITIONS, and it is written into the message at MSG_IN before
; DESCRIBE_LOCATION prints it -- "you are in", "you are on", "you are outside"
; and so on.
;
; I:A The location
DESCRIBE_ROOM:
  PUSH AF
  CALL GET_ROOM           ; Its record
  LD A,(IX+$00)           ; The word for how the player is placed there
  AND $0E                 ;
  LD E,A                  ;
  LD D,$00                ;
  LD HL,ROOM_PREPOSITIONS ;
  ADD HL,DE               ;
  LD E,(HL)               ;
  INC HL                  ;
  LD D,(HL)               ;
  LD HL,MSG_IN_SLOT       ; Into the message, high byte first, the way messages
  LD (HL),D               ; keep a word
  INC HL                  ;
  LD (HL),E               ;
  POP AF                  ; HL = "you are ..."
  LD HL,MSG_IN            ;
; This entry point is used by the routines at DESCRIBE_SEEN and DO_CAPTURE.
DESCRIBE_WITH_OPENING:
  PUSH IX                 ; Describe it, keeping IX, IY and BC
  PUSH IY                 ;
  PUSH BC                 ;
  CALL DESCRIBE_LOCATION  ;
  POP BC                  ;
  POP IY                  ;
  POP IX                  ;
  RET

; Print the opening message at HL and describe the location in A
;
; Used by the routine at DESCRIBE_ROOM.
;
; Its long description if it has one, or else its name; its picture, with a
; wait for a key once it is drawn; then the ways out through things
; (EXITS_THROUGH), the open ways out (VISIBLE_EXITS), and what is there to see
; (YOU_SEE).
;
; I:A The location
; I:HL The opening message
DESCRIBE_LOCATION:
  LD B,A                  ; B = the location
  CALL GET_ROOM           ; Its record; the opening message
  CALL RUN_MESSAGE_HL     ;
  LD L,(IX+$08)            ; Its description, or its name
  LD H,(IX+$09)            ;
  LD A,H                   ;
  OR L                     ;
  CALL DESCRIPTION_OR_NAME ;
  LD A,B                     ; Its picture
  CALL DRAW_LOCATION_PICTURE ;
  LD A,(PICTURE_SHOWN)     ; If a picture was drawn, wait for a key
  INC A                    ;
  CALL NZ,WAIT_FOR_ANY_KEY ;
  CALL NEW_LINE           ; New line
  LD A,B                  ; "to the east there is ..." for each way through
  CALL EXITS_THROUGH      ; something
; This entry point is used by the routine at DESCRIBE_BRIEFLY.
EXITS_AND_WHAT_IS_HERE:
  LD A,B                  ; "visible exits are:", and "you see :"
  CALL VISIBLE_EXITS      ;
  JP YOU_SEE              ;

; Print the message at HL if there is one, or else the room's name
;
; Used by the routine at DESCRIBE_LOCATION.
;
; PRINT_ROOM_NAME prints the name alone, from the record's bytes 2 to 7, the
; same way an object's name is printed.
;
; I:HL The description, or 0
; I:F NZ if HL is not 0
; I:IX The room's record
DESCRIPTION_OR_NAME:
  JP NZ,RUN_MESSAGE_HL
; This entry point is used by the routine at DESCRIBE_BRIEFLY.
PRINT_ROOM_NAME:
  LD DE,$0002             ; The name, which starts two bytes into the record
  PUSH IY                 ;
  PUSH IX                 ;
  POP IY                  ;
  ADD IY,DE               ;
  CALL PRINT_NAME         ;
  POP IY                  ;
  RET

; Wait until any key is pressed
;
; Used by the routine at DESCRIBE_LOCATION.
;
; Polls the whole keyboard through port $FE and returns once something is held,
; setting the border white on the way out. The game drops into it whenever a
; picture is finished -- the opening one, and each new location's after that --
; before the next prompt, and a key pressed there is taken as "carry on" and
; not as a letter, which is why the first letter of a command typed while a
; picture was drawing went missing. (The title screen does not use this: it
; waits in its own loop at TITLE_WAIT.)
WAIT_FOR_ANY_KEY:
  XOR A                   ; Wait until any key is down
  IN A,($FE)              ;
  AND $1F                 ;
  CP $1F                  ;
  JR Z,WAIT_FOR_ANY_KEY   ;
  LD A,$07                ; White border
  OUT ($FE),A             ;
  RET

; Describe a location already visited
;
; Used by the routine at MOVE.
;
; What MOVE does on coming back to a place: just its name, then the open ways
; out and what is there -- no opening, no description, no picture, and no
; doors.
;
; I:A The location
DESCRIBE_BRIEFLY:
  CALL GET_ROOM           ; Its name
  CALL PRINT_ROOM_NAME    ;
  CALL NEW_LINE             ; New line, and the end of DESCRIBE_LOCATION
  JR EXITS_AND_WHAT_IS_HERE ;

; Let the other characters act, then count the timers down
;
; Used by the routine at OBEY.
;
; Calls CHECK_WON and CHARACTERS_ACT -- the rest of the world's turn, not yet
; worked out -- and then walks TIMERS. A timer whose count is zero is not
; running. One that is running counts down by one a turn; on reaching zero it
; runs its routine, and in the turns before that, while the count is no more
; than its warning span, it runs its warning routine instead.
;
; Only one timer fires in a turn. A second one to reach zero in the same turn
; is held at a count of 1 and fires in the next, so two events never land on
; the player at once.
END_OF_TURN:
  PUSH HL
  PUSH IX
  PUSH IY
  PUSH BC
  PUSH DE
  CALL CHECK_WON          ; The characters' turn, not yet worked out
  CALL CHARACTERS_ACT     ;
  SUB A                   ; Nothing has fired yet this turn; printing on
  LD (TIMER_FIRED),A      ;
  INC A                   ;
  LD (SUCCEEDED),A        ;
  LD (DOING_IT),A         ;
  LD IY,TIMERS            ; IY = the first timer
END_OF_TURN_0:
  LD A,(IY+$00)           ; $FF ends the table
  CP $FF                  ;
  JR Z,END_OF_TURN_3      ;
  LD A,(IY+$01)           ; A count of zero: not running
  CP $00                  ;
  JR Z,END_OF_TURN_2      ;
  DEC A                   ; Count down, and go on to the warning test unless it
  LD (IY+$01),A           ; reached zero
  CP $00                  ;
  JR NZ,END_OF_TURN_1     ;
  LD A,(TIMER_FIRED)      ; Already had one fire this turn? Hold this one at 1
  CP $01                  ; until the next
  LD (IY+$01),A           ;
  JR Z,END_OF_TURN_1      ;
  INC A                   ; Count one fired
  LD (TIMER_FIRED),A      ;
  LD L,(IY+$02)           ; Run its routine through RUN_ROUTINE
  LD H,(IY+$03)           ;
  CALL RUN_ROUTINE        ;
  JR END_OF_TURN_2        ;
END_OF_TURN_1:
  LD A,(IY+$04)           ; No warning span: nothing to do
  CP $00                  ;
  JR Z,END_OF_TURN_2      ;
  CP (IY+$01)             ; Is the count within the warning span?
  JR C,END_OF_TURN_2      ;
  LD L,(IY+$05)           ; Then run the warning routine
  LD H,(IY+$06)           ;
  CALL RUN_ROUTINE        ;
END_OF_TURN_2:
  LD DE,$0007             ; On to the next 7-byte timer
  ADD IY,DE               ;
  JP END_OF_TURN_0        ;
END_OF_TURN_3:
  LD A,$01                ; Printing on
  LD (PRINTING_ON),A      ;
  POP DE
  POP BC
  POP IY
  POP IX
  POP HL
  RET

; Is somebody else carrying this object?
;
; Used by the routine at DO_ACTION.
;
; Only asked for the player. If a character holds the object, the player is
; told so -- "the ... is carrying ...", with the two names -- and it cannot be
; acted on. Something the player has, however deep, and something held by a
; non-character, are fine.
;
; I:A The object, or $FF
; O:F NZ if another character has it
CARRIED_BY_ANOTHER:
  CP $FF
  RET Z
  PUSH IX
  PUSH IY
  PUSH BC
  LD B,A
  LD A,(ACTING)             ; Only for the player
  CP $00                    ;
  JR Z,CARRIED_BY_ANOTHER_0 ;
  XOR A                     ;
  JR CARRIED_BY_ANOTHER_1   ;
CARRIED_BY_ANOTHER_0:
  LD A,B                    ; Held by nothing: fine
  CALL GET_OBJECT           ;
  LD A,(IX+$01)             ;
  CP $FF                    ;
  JR Z,CARRIED_BY_ANOTHER_1 ;
  LD A,B                    ; Held, at any depth, by the player: fine
  PUSH IX                   ;
  POP IY                    ;
  CALL ACTOR_HAS_A          ;
  JR C,CARRIED_BY_ANOTHER_1 ;
  CALL GET_OBJECT           ; Its holder a character, and PLAYER_FLAGS bit 7
  BIT 6,(IX+$07)            ; set?
  JR Z,CARRIED_BY_ANOTHER_1 ;
  LD A,(PLAYER_FLAGS)       ;
  BIT 7,A                   ;
  JR Z,CARRIED_BY_ANOTHER_1 ;
  LD L,(IY+$08)           ; Then "the ... is carrying ..."
  LD H,(IY+$09)           ;
  PUSH HL                 ;
  LD L,(IX+$08)           ;
  LD H,(IX+$09)           ;
  PUSH HL                 ;
  LD HL,MSG_IS_CARRYING   ;
  CALL RUN_MESSAGE_HL     ;
  OR $01                  ;
CARRIED_BY_ANOTHER_1:
  POP BC
  POP IY
  POP IX
  RET

; Kill the first object
;
; Used by the routine at DO_BURN.
KILL_TARGET:
  LD A,(TARGET)

; Kill the character in A
;
; Used by the routines at DO_SHOOT, DO_ATTACK, DO_EAT, SWIM_BLACK_RIVER and
; TROLLS_TURN_TO_STONE.
;
; The player's death is PLAYER_DIES. Anyone else is marked dead (flag bit 3),
; drops everything it holds (EMPTY_OUT), and gives up its slot in CHARACTERS,
; so its script never runs again.
KILL:
  AND A                   ; The player: PLAYER_DIES
  JP Z,PLAYER_DIES        ;
  PUSH BC
  PUSH IY
  PUSH IX
  LD C,A
  CALL GET_OBJECT         ; Dead
  SET 3,(IX+$07)          ;
  CALL EMPTY_OUT          ; Everything it held drops
  LD A,C                  ; Its script is over
  CALL FIND_CHARACTER     ;
  CP $FF                  ;
  LD A,C                  ;
  JR Z,KILL_0             ;
  LD (IY+$00),$00         ;
KILL_0:
  CALL BROKEN_OR_DEAD     ; Not yet worked out
  LD A,C                  ;
  CALL CANCEL_ORDERS      ;
  POP IX
  POP IY
  POP BC
  RET

; Make the choices that differ from one game to the next
;
; Used by the routine at START.
;
; Called by START for every new game. One of HIDDEN_ROADS is picked at random
; and its exit wiped from the room, so a different way is shut each time until
; Elrond reads the curious map (ELROND_READS_MAP); and one of RIDDLES is picked
; for Gollum.
NEW_GAME_CHOICES:
  SUB A                   ; The player acts; ROAD_OPEN cleared, which nothing
  LD (ACTING),A           ; ever sets again; no riddle asked yet (RIDDLE_ASKED)
  LD (ROAD_OPEN),A        ;
  LD (RIDDLE_ASKED),A     ;
  LD HL,PLAYER            ; The player's record
  LD (ACTOR),HL           ;
  LD A,$04                 ; IY = one of HIDDEN_ROADS at random
  CALL RANDOM_POSITIVE     ;
  INC A                    ;
  LD B,A                   ;
  LD IY,HIDDEN_ROADS-$0006 ;
  LD DE,$0006              ;
NEW_GAME_CHOICES_0:
  ADD IY,DE                ;
  DJNZ NEW_GAME_CHOICES_0  ;
  LD (SHUT_ROAD+$0002),IY ; Kept in the operand of ELROND_READS_MAP's LD IY
  LD L,(IY+$01)           ; Wipe that exit: all three bytes zero, so no
  LD H,(IY+$02)           ; direction matches it
  LD B,$03                ;
NEW_GAME_CHOICES_1:
  LD (HL),$00             ;
  INC HL                  ;
  DJNZ NEW_GAME_CHOICES_1 ;
  LD A,$03                ; And one of RIDDLES at random, in RIDDLE
  CALL RANDOM_POSITIVE    ;
  LD E,A                  ;
  LD D,$00                ;
  SLA E                   ;
  SLA E                   ;
  LD HL,RIDDLES           ;
  ADD HL,DE               ;
  LD (RIDDLE),HL          ;
  RET

; The message at HL as a sentence of the story, with a full stop and a new line
;
; Used by the routines at WARG_HOWLS and THORIN_CHATTER.
;
; I:HL The message
NARRATE_LINE:
  CALL RUN_MESSAGE_HL
  LD A,$2E
  CALL PRINT_CHAR
  JP NEW_LINE

; Go on only if the action was done for real, and worked
;
; Used by the routines at SIDE_DOOR_UNLOCKED, GOBLINS_DOOR_OPENED,
; BARREL_THROWN, THORIN_KILLED, BOAT_BOARDED and SIDE_DOOR_CLOSED.
;
; Otherwise it leaves the handler that called it. This is what the records
; keyed 0 after a handler use: they run whether or not the handler succeeded,
; and this is how they find out.
ONLY_IF_DONE:
  PUSH BC                 ; Done for real, and it worked: carry on
  LD BC,(DOING_IT)        ;
  LD A,C                  ;
  AND B                   ;
  JR NZ,ONLY_IF_DONE_0    ;
  POP BC                  ; Otherwise out of the caller
ONLY_IF_DONE_0:
  POP BC                  ;
  RET                     ;

; CHARACTERS_ACT's working bytes
STEPS_REFUSED:
  DEFB $00                ; How many of this character's steps have been
                          ; refused this turn: at six its turn is over
PLAYER_IN_DARK:
  DEFB $00                ; 0 if the player can see, 1 in the dark
                          ; (NOTE_LIGHT), 2 once "you hear a noise." has been
                          ; said this turn
TARGET_AT:
  DEFB $00                ; Where the action's target is, for ANNOUNCE_ARRIVAL

; Every other character takes its turn
;
; Used by the routine at END_OF_TURN.
;
; Walks CHARACTERS and runs each character's script until it has done
; something. Each instruction is an action the character tries, as if it had
; typed a sentence: the action code and its objects go into ACTION to
; INSTRUMENT exactly as the parser puts them for the player, and ACTOR_TRIES
; carries it out through the same ACTION_TABLE. So Thorin opens a door by the
; same code the player does.
;
; A step that is refused moves on to the next, or to a fallback of its own, and
; the script goes on; a step that succeeds ends the character's turn. Six
; refusals in a row end it too. What a character does is printed only when the
; player can see it.
;
; An order comes first. Whatever the player has told a character to do (see
; ORDERS) replaces its script's step for the turn, unless the step has bit 6
; set, which makes it one that cannot be interrupted.
CHARACTERS_ACT:
  CALL NOTE_LIGHT         ; Not yet worked out
  LD IY,CHARACTERS        ; IY = the first character
CHARACTERS_ACT_0:
  XOR A                   ; No steps refused yet
  LD (STEPS_REFUSED),A    ;
  LD A,(IY+$00)           ; $FF ends the table
  CP $FF                  ;
  JP Z,CHARACTERS_ACT_9   ;
  CP $00                  ; An empty slot
  JP Z,NEXT_CHARACTER     ;
  LD (ACTING),A           ; The sentence is about this character: its number,
  CALL LOCATION_OF        ; its record, and its location in ACTOR_AT
  LD (ACTOR),IX           ;
  LD (ACTOR_AT),A         ;
  SUB A                   ; Printing off
  LD (PRINTING_ON),A      ;
  LD A,(IY+$00)           ; Can the player see it (IN_REACH_OF, the other way
  PUSH IY                 ; round)?
  LD IY,PLAYER            ;
  CALL ACTOR_IN_REACH     ;
  POP IY                  ;
  JR Z,CHARACTERS_ACT_1   ;
  LD A,(PLAYER_IN_DARK)      ; Then print what it does -- unless the player is
  CP $02                     ; in the dark (PLAYER_IN_DARK, set by NOTE_LIGHT):
  JR Z,CHARACTERS_ACT_1      ; then the first one is only heard, "you hear a
  LD A,$01                   ; noise.", and nothing is printed
  LD (PRINTING_ON),A         ;
  LD A,(PLAYER_IN_DARK)      ;
  CP $01                     ;
  JR NZ,CHARACTERS_ACT_1     ;
  INC A                      ;
  LD (PLAYER_IN_DARK),A      ;
  LD HL,MSG_YOU_HEAR_A_NOISE ;
  CALL RUN_MESSAGE_HL        ;
  SUB A                      ;
  LD (PRINTING_ON),A         ;
CHARACTERS_ACT_1:
  LD A,$FF                ; Held by something? Try to get out (CAPTIVE)
  CP (IX+$01)             ;
  JP NZ,CAPTIVE           ;
; This entry point is used by the routine at CAPTIVE.
CHARACTER_FREE:
  LD IX,(ACTOR)           ; ORDER_WAITING = 1 if it has an order waiting
  CALL HAS_ORDER          ;
  LD A,$00                ;
  JR NZ,CHARACTERS_ACT_2  ;
  INC A                   ;
CHARACTERS_ACT_2:
  LD (ORDER_WAITING),A    ;
; This entry point is used by the routine at SCRIPT_BARE.
RUN_SCRIPT:
  LD L,(IY+$02)           ; HL = where its script has got to
  LD H,(IY+$03)           ;
; This entry point is used by the routine at SCRIPT_BARE.
SCRIPT_STEP:
  LD A,(STEPS_REFUSED)    ; Six steps refused: its turn is over
  CP $06                  ;
  JR Z,NEXT_CHARACTER     ;
  LD A,(HL)               ; IX = the instruction
  LD DE,$0004             ;
  PUSH HL                 ;
  POP IX                  ;
  AND $0F                 ; Opcodes 5 and up
  CP $05                  ;
  JR NC,CHARACTERS_ACT_4  ;
  LD A,(ORDER_WAITING)    ; An order, and this step may be interrupted (bit 6
  CP $01                  ; clear)? Take the order and carry it out, and that
  JR NZ,CHARACTERS_ACT_3  ; is its turn
  BIT 6,(HL)              ;
  JR NZ,CHARACTERS_ACT_3  ;
  SUB A                   ;
  LD (ORDER_WAITING),A    ;
  INC A                   ;
  CALL TAKE_ORDER         ;
  JR Z,CHARACTERS_ACT_3   ;
  LD A,$01                ;
  LD (DOING_IT),A         ;
  LD (SUCCEEDED),A        ;
  LD HL,NEXT_CHARACTER    ;
  PUSH HL                 ;
  PUSH IX                 ;
  JP ACTOR_DOES           ;
CHARACTERS_ACT_3:
  LD A,(HL)               ; Opcode 4: an action with no objects, or a jump; 0
  AND $0F                 ; to 3: an action with objects, or a routine
  CP $04                  ;
  JP Z,SCRIPT_BARE        ;
  JR C,SCRIPT_DO          ;
  JR NEXT_CHARACTER       ;
CHARACTERS_ACT_4:
  CP $0E                  ; $0E: go to the address that follows, and carry on
  JR NZ,CHARACTERS_ACT_5  ;
  LD E,(IX+$01)           ;
  LD (IY+$02),E           ;
  LD E,(IX+$02)           ;
  LD (IY+$03),E           ;
  JR RUN_SCRIPT           ;
CHARACTERS_ACT_5:
  CP $0C                  ; $0C: switch to the script its table keys under the
  JR NZ,CHARACTERS_ACT_6  ; byte that follows
  LD B,(IX+$01)           ;
  LD A,(IY+$00)           ;
  CALL REACT              ;
  JR RUN_SCRIPT           ;
CHARACTERS_ACT_6:
  CP $0F                  ; $0F: switch to one of its scripts at random
  JR NZ,CHARACTERS_ACT_7  ;
  CALL SCRIPT_RANDOM      ;
  JR RUN_SCRIPT           ;
CHARACTERS_ACT_7:
  CP $00                  ; Never taken: A is at least 5 here
  JR NZ,CHARACTERS_ACT_8  ;
  ADD HL,DE               ;
  JR SCRIPT_STEP          ;
CHARACTERS_ACT_8:
  SUB A                   ; Anything else: back to its first script, and its
  LD E,A                  ; turn is over
  CALL SCRIPT_PICK        ;
; This entry point is used by the routines at SCRIPT_DO, SCRIPT_BARE and
; CAPTIVE.
NEXT_CHARACTER:
  LD DE,$0007             ; On to the next 7-byte slot
  ADD IY,DE               ;
  JP CHARACTERS_ACT_0     ;
CHARACTERS_ACT_9:
  SUB A                   ; Done: the sentence is about the player again, and
  LD (ACTING),A           ; printing on
  INC A                   ;
  LD (PRINTING_ON),A      ;
  LD HL,PLAYER            ;
  LD (ACTOR),HL           ;
  RET                     ;

; Move a character's script past this instruction
;
; Used by the routines at SCRIPT_DO and SCRIPT_BARE.
;
; By DE bytes, and two more if the instruction has a fallback (bit 4).
;
; I:HL The instruction
; I:DE Its length without a fallback
; I:IY The character's slot
STEP_PAST:
  ADD HL,DE               ; Past the instruction
  BIT 4,(IX+$00)          ; And its fallback, if it has one
  JR Z,STEP_PAST_0        ;
  INC HL                  ;
  INC HL                  ;
STEP_PAST_0:
  LD (IY+$02),L           ; Save the new place in the slot
  LD (IY+$03),H           ;
  RET                     ;

; A script step: an action with objects, or a routine
;
; Used by the routine at CHARACTERS_ACT.
;
; Four bytes, then a 2-byte fallback if bit 4 is set. With bit 0 clear they are
; the action code and its two objects, tried as the character's own sentence.
; With bit 0 set, bytes 1 and 2 are the address of a routine instead: it is run
; once with printing off as a test, and only if it reports success by setting
; SUCCEEDED is it run again for real.
;
; A step that succeeds with bit 5 set takes the character out of the story: its
; slot is emptied and it never acts again.
SCRIPT_DO:
  CALL STEP_PAST          ; Step past it
  BIT 0,(IX+$00)          ; A routine?
  JR NZ,SCRIPT_DO_0       ;
  LD A,(IX+$01)           ; The action and its two objects
  LD (ACTION),A           ;
  LD A,(IX+$02)           ;
  LD (TARGET),A           ;
  LD A,(IX+$03)           ;
  LD (INSTRUMENT),A       ;
  CALL ACTOR_TRIES        ; Try it: done, or refused
  JR Z,STEP_REFUSED       ;
  JR SCRIPT_DO_1          ;
SCRIPT_DO_0:
  LD L,(IX+$01)           ; The routine: run it quietly, and if it succeeded,
  LD H,(IX+$02)           ; again for real
  SUB A                   ;
  LD (DOING_IT),A         ;
  LD (SUCCEEDED),A        ;
  CALL RUN_ROUTINE        ;
  LD A,(SUCCEEDED)        ;
  CP $01                  ;
  JR NZ,STEP_REFUSED      ;
  LD (DOING_IT),A         ;
  CALL RUN_ROUTINE        ;
SCRIPT_DO_1:
  BIT 5,(IX+$00)          ; Done. Bit 5: the character's part is over
  JP Z,NEXT_CHARACTER     ;
  LD (IX+$00),$00         ;
  JR NEXT_CHARACTER       ;

; A script step: an action with no objects, or a jump
;
; Used by the routine at CHARACTERS_ACT.
;
; Two bytes, then a 2-byte fallback if bit 4 is set. Byte 1 is an action code,
; tried with neither object -- RUN, say, which carries the character off in
; some direction. An action code of $FF does nothing and ends the character's
; turn: a pause, with the script going on at the next step next turn -- or,
; with a fallback, at the fallback, which makes it a jump. The warg's one
; script ends that way, a pause before going round again.
;
; A refused step, of either kind, comes here at STEP_REFUSED: count it, and go
; on at the fallback if there is one, or the next step if not.
SCRIPT_BARE:
  LD DE,$0002             ; Step past it
  CALL STEP_PAST          ;
  LD A,(IX+$01)           ; $FF: a pause or a jump
  CP $FF                  ;
  JR Z,SCRIPT_BARE_0
  LD (ACTION),A           ; The action alone: done, or refused
  LD A,$FF                ;
  LD (TARGET),A           ;
  LD (INSTRUMENT),A       ;
  CALL ACTOR_TRIES        ;
  JR Z,STEP_REFUSED       ;
  JP NEXT_CHARACTER       ;
SCRIPT_BARE_0:
  BIT 4,(IX+$00)          ; Jump to the fallback, if there is one; either way
  JP Z,NEXT_CHARACTER     ; that is the turn
  LD L,(IX+$02)           ;
  LD H,(IX+$03)           ;
  LD (IY+$02),L           ;
  LD (IY+$03),H           ;
  JP NEXT_CHARACTER       ;
; This entry point is used by the routine at SCRIPT_DO.
STEP_REFUSED:
  LD HL,STEPS_REFUSED     ; Refused: count it
  INC (HL)                ;
  BIT 4,(IX+$00)          ; No fallback? On to the next step
  JP Z,RUN_SCRIPT         ;
  ADD IX,DE               ; Otherwise on at the fallback
  LD H,(IX+$01)           ;
  LD L,(IX+$00)           ;
  LD (IY+$02),L           ;
  LD (IY+$03),H           ;
  JP SCRIPT_STEP          ;

; A character tries the action in ACTION to INSTRUMENT
;
; Used by the routines at SCRIPT_DO, SCRIPT_BARE and CAPTIVE.
;
; Checked by WOULD_WORK first, as the player's sentences are; then carried out
; by DO_ACTION, and the player is told of anyone who has just come into view --
; "... enters." for the actor, "... appears." for the second object, through
; ANNOUNCE_ARRIVAL. ACTOR_DOES is the way in for an order the character was
; given, skipping the check.
;
; O:F NZ if it was done, Z if it was refused
ACTOR_TRIES:
  PUSH IX                 ; Refused by the check: Z
  CALL WOULD_WORK         ;
  JP Z,ACTOR_TRIES_6      ;
; This entry point is used by the routine at CHARACTERS_ACT.
ACTOR_DOES:
  LD A,(TARGET_IS_PLACE)  ; TARGET_IS_PLACE set? Straight to doing it
  CP $01                  ;
  JR Z,ACTOR_TRIES_4      ;
  LD A,(ACTION)           ; Going through something, away from the player:
  CP $1E                  ; straight to doing it
  JR NZ,ACTOR_TRIES_0     ;
  LD A,(ACTOR_AT)         ;
  LD HL,PLAYER_WHERE      ;
  CP (HL)                 ;
  JR NZ,ACTOR_TRIES_4     ;
ACTOR_TRIES_0:
  LD A,(TARGET)           ; Not yet worked out: two ways into NARRATE_ACTION
  CP $FF                  ;
  JR Z,ACTOR_TRIES_3      ;
  CALL LOCATION_OF        ;
  LD (TARGET_AT),A        ;
  CP $FF                  ;
  JR NZ,ACTOR_TRIES_3     ;
  LD BC,(PLAYER_AT)       ;
  LD A,C                  ;
  CP B                    ;
  JR Z,ACTOR_TRIES_3      ;
  LD B,(IX+$00)           ;
ACTOR_TRIES_1:
  CP (IX+$10)             ;
  JR Z,ACTOR_TRIES_2      ;
  INC IX                  ;
  DJNZ ACTOR_TRIES_1      ;
  JR ACTOR_TRIES_3        ;
ACTOR_TRIES_2:
  LD A,(ACTING)           ;
  LD B,A                  ;
  LD A,$FF                ;
  LD (ACTING),A           ;
  LD A,$01                ;
  LD (PRINTING_ON),A      ;
  PUSH IY                 ;
  CALL NARRATE_ACTION     ;
  POP IY                  ;
  SUB A                   ;
  LD (PRINTING_ON),A      ;
  LD A,B                  ;
  LD (ACTING),A           ;
  JR ACTOR_TRIES_4        ;
ACTOR_TRIES_3:
  PUSH IY                 ;
  CALL NARRATE_ACTION     ;
  POP IY                  ;
ACTOR_TRIES_4:
  CALL DO_ACTION          ; Do it
  LD A,(ACTING)           ; The actor has come into the player's view? "...
  LD HL,ACTOR_AT          ; enters."
  LD DE,MSG_ENTER         ;
  CALL ANNOUNCE_ARRIVAL   ;
  LD A,(TARGET_IS_PLACE)  ; The second object too? "... appears."
  CP $01                  ;
  JR Z,ACTOR_TRIES_5      ;
  LD A,(TARGET)           ;
  LD HL,TARGET_AT         ;
  LD DE,MSG_APPEAR        ;
  CALL ANNOUNCE_ARRIVAL   ;
ACTOR_TRIES_5:
  OR $01                  ; Done: NZ
ACTOR_TRIES_6:
  POP IX
  RET

; Opcode $0F: switch to one of a character's scripts at random
;
; Used by the routine at CHARACTERS_ACT.
;
; A random number, limited by the lesser of the operand and slot byte 1 picks
; from the start of the character's script table; this is how Gandalf and the
; others wander without a fixed route. SCRIPT_PICK picks entry E instead, and
; opcodes with no meaning of their own come in there with E = 0.
SCRIPT_RANDOM:
  LD A,(IX+$01)           ; The lesser of the operand and the character's own
  CP (IY+$01)             ; limit
  JR C,SCRIPT_RANDOM_0    ;
  LD A,(IY+$01)           ;
SCRIPT_RANDOM_0:
  CALL RANDOM_POSITIVE    ; A random number within it
  LD E,A                  ;
; This entry point is used by the routine at CHARACTERS_ACT.
SCRIPT_PICK:
  LD A,(IY+$01)           ; No further than the character's own limit
  CP E                    ;
  JR NC,SCRIPT_RANDOM_1   ;
  LD E,A                  ;
SCRIPT_RANDOM_1:
  LD L,(IY+$04)           ; The script its table has at that place
  LD H,(IY+$05)           ;
  LD D,$00                ;
  ADD HL,DE               ;
  ADD HL,DE               ;
  ADD HL,DE               ;
  INC HL                  ;
  LD E,(HL)               ;
  INC HL                  ;
  LD D,(HL)               ;
  LD (IY+$02),E           ;
  LD (IY+$03),D           ;
  RET

; Find a character's slot
;
; Used by the routines at DO_TALK, KILL and REACT.
;
; I:A The character
; O:IY Its slot in CHARACTERS, or the $FF that ended it
FIND_CHARACTER:
  PUSH DE
  PUSH BC
  LD B,A
  LD HL,CHARACTERS
  LD DE,$0007
FIND_CHARACTER_0:
  LD A,(HL)
  CP B
  JR Z,FIND_CHARACTER_1
  CP $FF
  JR Z,FIND_CHARACTER_1
  ADD HL,DE
  JP FIND_CHARACTER_0
FIND_CHARACTER_1:
  POP BC
  POP DE
  PUSH HL
  POP IY
  RET

; Switch a character to the script it keeps for an action
;
; Used by the routines at REACT_TO_ACTION and CHARACTERS_ACT.
;
; Looks the action up in the character's own script table with FIND_RECORD, and
; if it has a script for it, sends the character there. The script opcode $0C
; uses it, and so does REACT_TO_ACTION: whenever an action is done to a
; character, it reacts. That is what the entries after the first few in each
; table are for -- Gandalf's and Thorin's have scripts for being given
; something ($1D), captured ($30) and attacked ($0F).
;
; I:A The character
; I:B The action
REACT:
  PUSH IY
  PUSH IX
  CALL FIND_CHARACTER     ; Not in CHARACTERS: nothing to do
  CP $FF                  ;
  JR Z,REACT_0            ;
  LD L,(IY+$04)           ; Its script for this action, if it has one
  LD H,(IY+$05)           ;
  PUSH HL                 ;
  POP IX                  ;
  LD A,B                  ;
  CALL FIND_RECORD        ;
  CP $FF                  ;
  JR Z,REACT_0            ;
  LD L,(IX+$01)           ; Go there
  LD H,(IX+$02)           ;
  LD (IY+$02),L           ;
  LD (IY+$03),H           ;
REACT_0:
  POP IX
  POP IY
  RET

; Tell the player an object has just come into view
;
; Used by the routine at ACTOR_TRIES.
;
; Prints the message at DE with the object's name if the object is now where
; the player is and was not before -- HL points at where it was.
;
; I:A The object
; I:HL Where it was
; I:DE The message
ANNOUNCE_ARRIVAL:
  CP $FF
  RET Z
  AND A
  RET Z
  LD B,A
  LD A,(PLAYER_IN_DARK)
  CP $02
  RET Z
  LD A,B
  CALL LOCATION_OF
  LD C,A
  CP (HL)
  RET Z
  LD A,(PLAYER_AT)
  CP C
  RET NZ
  LD A,(PLAYER_MOVED)
  AND A
  RET Z
  LD A,$01
  LD (PRINTING_ON),A
  PUSH DE
  POP HL
  LD A,B
  CALL GET_OBJECT
  PUSH DE
  LD DE,$0008
  ADD IX,DE
  POP DE
  PUSH IX
  CALL RUN_MESSAGE_HL
  RET

; Note where the player is, and whether it is too dark to see
;
; Used by the routines at CHARACTERS_ACT and MOVE_CONTENTS.
;
; CHARACTERS_ACT starts with this. PLAYER_AT is the player's location and
; PLAYER_IN_DARK is 1 in the dark, 0 in the light: in the dark the other
; characters are heard, not seen.
NOTE_LIGHT:
  LD A,$00                ; PLAYER_AT = where the player is
  CALL LOCATION_OF        ;
  LD (PLAYER_AT),A        ;
  CALL TOO_DARK           ; PLAYER_IN_DARK = 1 if too dark to see
  LD A,$00                ;
  JR NC,NOTE_LIGHT_0      ;
  INC A                   ;
NOTE_LIGHT_0:
  LD (PLAYER_IN_DARK),A   ;
  RET

; A character held by something tries to get out
;
; Used by the routine at CHARACTERS_ACT.
;
; A character held by another character, or by something with flag bit 3, goes
; on with its script as usual. Held by something closed -- flag bit 5 clear,
; not to be seen into -- it can do nothing. Otherwise it tries action $37,
; CLIMB OUT OF, on what holds it.
CAPTIVE:
  LD A,$FF                ; The holder is the object
  LD (INSTRUMENT),A       ;
  LD A,(IX+$01)           ;
  LD (TARGET),A           ;
  CALL GET_OBJECT         ; Held by a character, or by something with flag bit
  BIT 3,(IX+$07)          ; 3: carry on with the script
  JP NZ,CHARACTER_FREE    ;
  BIT 6,(IX+$07)          ;
  JP NZ,CHARACTER_FREE    ;
  BIT 5,(IX+$07)          ; Shut in: nothing this turn
  JP Z,NEXT_CHARACTER     ;
  LD A,$37                ; Try to climb out
  LD (ACTION),A           ;
  CALL ACTOR_TRIES        ;
  JP NEXT_CHARACTER       ;

; Does the action make sense?
;
; Used by the routines at HANDLED and DO_ACTION.
;
; No if the actor would be doing it to itself, as either object, or doing it to
; one object with itself; TARGET_IS_PLACE and INSTRUMENT_IS_PLACE waive the
; checks; they are options of the action's pattern (PATTERN_OPTIONS),
; TARGET_IS_PLACE set for ENTER and GO INTO, whose object is a place, and
; INSTRUMENT_IS_PLACE for nothing at all. An action with no object always makes
; sense.
;
; O:F Z if it makes no sense
SENSIBLE:
  LD A,(TARGET)           ; No object: fine
  INC A                   ;
  JR NZ,SENSIBLE_0        ;
  INC A                   ;
  RET                     ;
SENSIBLE_0:
  LD A,(TARGET_IS_PLACE)  ; Unless TARGET_IS_PLACE is set: not to itself, and
  AND A                   ; not an object with itself
  JR NZ,SENSIBLE_1        ;
  LD HL,TARGET            ;
  LD A,(ACTING)           ;
  CP (HL)                 ;
  RET Z                   ;
  LD A,(INSTRUMENT)       ;
  CP (HL)                 ;
  RET Z                   ;
SENSIBLE_1:
  LD A,(INSTRUMENT_IS_PLACE) ; Unless INSTRUMENT_IS_PLACE is set: the second
  AND A                      ; object not itself either
  RET NZ                     ;
  LD A,(INSTRUMENT)          ;
  LD HL,ACTING               ;
  CP (HL)                    ;
  RET                        ;

; Call the routine at HL, if there is one
;
; Used by the routines at MOVE, DO_ACTION, END_OF_TURN, SCRIPT_DO and
; SWAPPED_OBJECTS.
;
; Keeps every register pair the caller has, IX and IY included, and does
; nothing for an address of zero.
;
; I:HL The routine, or 0
RUN_ROUTINE:
  PUSH IX
  PUSH IY
  PUSH DE
  PUSH BC
  PUSH HL
  LD A,L                  ; HL not zero? Call it through JUMP_HL
  OR H                    ;
  CALL NZ,JUMP_HL         ;
  POP HL
  POP BC
  POP DE
  POP IY
  POP IX
  RET

; Jump to HL
;
; Used by the routine at RUN_ROUTINE.
;
; The one-byte target that RUN_ROUTINE calls, so that a routine held in HL can
; be called and return.
JUMP_HL:
  JP (HL)

; Find an object's own handler for an action
;
; Used by the routines at DO_STRIKE, HANDLED and DO_ACTION.
;
; Skips the record's 16-byte head and the list whose length is byte 0 of it,
; and searches what follows with FIND_RECORD. That is the object record's
; grammar stated by the game itself: parsed this way, all 61 records end
; exactly where the next begins, and the last exactly where ACTION_TABLE
; starts.
;
; So an object can carry handlers of its own for particular actions, and this
; is how the game asks whether it does before falling back on the ordinary
; ones. A handler of $0000 in a record is not an address.
;
; I:A The action code
; I:IX The object's record
; O:IX The matching handler record, or the $FF that ended the list
; O:F NZ if the object has its own handler for this action
FIND_OBJECT_HANDLER:
  PUSH DE
  LD D,A                  ; Keep the action code
  LD A,(IX+$00)           ; Skip the 16-byte head and the list of locations,
  ADD A,$10               ; whose length is byte 0
  LD E,A                  ;
  LD A,D                  ; IX = the start of the object's own handlers
  LD D,$00                ;
  ADD IX,DE               ;
  CALL FIND_RECORD        ; Look for this action among them
  POP DE
  RET

; Step to the next three-byte entry
;
; Used by the routines at NEXT_OBJECT_KEEP_A, ROOM_LEFT, FIND_NAMED_OBJECT,
; ROOM_BY_NAME, FIND_EXIT and EXIT_TO.
;
; Adds 3 to IX and returns Z at the $FF that ends a list. Shared with other
; lists of three-byte entries, which is why it also loads IY from bytes 1 and 2
; -- for an exit those are the object it goes through and the destination, not
; an address.
NEXT_EXIT:
  EXX                     ; Keep the caller's BC, DE and HL
  LD DE,$0003             ; On three bytes to the next entry
  ADD IX,DE               ;
  LD D,(IX+$02)           ; IY = bytes 1 and 2 of it, which for an object index
  LD E,(IX+$01)           ; entry is the record's address
  PUSH DE                 ;
  POP IY                  ;
  LD A,(IX+$00)           ; Z if this is the $FF that ends the list
  CP $FF                  ;
  EXX
  RET

; The next object in the index, keeping A
;
; Used by the routines at MOVE_HELD, ADD_UP_HELD, EMPTY_OUT, COUNT_HELD and
; LIST_HELD.
;
; NEXT_OBJECT (NEXT_EXIT) with A saved: the loops that walk every object
; looking for those held by A all use it.
NEXT_OBJECT_KEEP_A:
  PUSH BC
  LD B,A
  CALL NEXT_EXIT
  LD A,B
  POP BC
  RET

; Find a location's record
;
; Used by the routines at ROOM_NAME_AT, CAN_PASS, LOOK_THROUGH, DESCRIBE_ROOM,
; DESCRIBE_LOCATION, DESCRIBE_BRIEFLY, ROOM_LEFT, ACTOR_ROOM, ROOM_BY_NAME,
; EXITS_OF, DRAGON_HUNTS and ELROND_READS_MAP.
;
; Anything from $50 up is not a location and gets zero back; otherwise the
; record's address is read straight out of ROOM_POINTERS, two bytes per
; location. Unlike objects there is no search: locations are numbered densely,
; so a table indexed by number is cheaper than FIND_RECORD.
;
; I:A The location
; O:IX Its record
GET_ROOM:
  CP $50                  ; $50 and above is not a location: return zero
  JR C,GET_ROOM_0         ;
  XOR A                   ;
  RET                     ;
GET_ROOM_0:
  PUSH DE                 ; DE = ROOM_POINTERS, keeping HL
  LD DE,ROOM_POINTERS     ;
  PUSH HL                 ;
  LD L,A                  ; HL = ROOM_POINTERS + 2 x location
  LD H,$00                ;
  ADD HL,HL               ;
  ADD HL,DE               ;
  LD E,(HL)               ; DE = the pointer there
  INC HL                  ;
  LD D,(HL)               ;
  PUSH DE                 ; IX = the room's record
  POP IX                  ;
  POP HL
  POP DE
  RET

; Find an object's record
;
; Used by the routines at OBJECT_NAME_AT, DO_LOOK, DO_TAKE, MOVE, CAN_PASS,
; SHUT_IN_ACTOR, LOOK_THROUGH, DO_DRINK, DO_EXAMINE, HANDLED, DO_ACTION,
; CARRIED_BY_ANOTHER, KILL, ANNOUNCE_ARRIVAL, CAPTIVE, HELD_BY_ACTOR,
; EMPTY_OUT, SHUT_IN, LOCATION_OF, CONTENTS_INTRO, EXITS_THROUGH,
; BROKEN_OR_DEAD, DO_CLIMB_OUT, DO_CLIMB_INTO and RING_CHECK.
;
; The object number in A goes to FIND_RECORD against OBJECT_INDEX, and the
; record's address comes back in IX. Twenty-one routines use it.
;
; I:A The object number
; O:IX The object's record
GET_OBJECT:
  LD IX,OBJECT_INDEX      ; Find the object's entry in OBJECT_INDEX
  CALL FIND_RECORD        ;
  PUSH HL                 ; Swap the entry's pointer into IX, keeping HL
  LD L,(IX+$01)           ;
  LD H,(IX+$02)           ;
  EX (SP),HL              ;
  POP IX                  ;
  RET                     ;

; Cleared by MOVE_HELD when the player is among what it moves
PLAYER_MOVED:
  DEFB $FF

; Move everything inside an object to a location
;
; Used by the routines at MOVE, DO_GIVE, INTO_THE_RIVER, THROW_THROUGH,
; DO_CAPTURE, BARREL_REACHES_LAKE, THROW_ROPE_ACROSS, PULL_ROPE and
; JUMP_ONTO_BARREL.
;
; Everything held by the object in A, at any depth, goes to location B through
; MOVE_HELD. If the player was among it, the move is played out for them:
; MOVE's own step at MOVE_THERE puts them there, with the sentence made about
; the player for the length of it, and NOTE_LIGHT follows.
;
; I:A The object
; I:B The location
MOVE_CONTENTS:
  LD HL,PLAYER_MOVED      ; Say the player is not among it, and move it all
  LD (HL),$01             ;
  CALL MOVE_HELD          ;
  LD A,(HL)               ; Not among it: done
  AND A                   ;
  RET NZ                  ;
  PUSH HL
  LD A,(PLAYER_WHERE)     ; Nowhere? Nothing more to do
  AND A                   ;
  JR Z,MOVE_CONTENTS_0    ;
  LD A,(ACTING)           ; The sentence is about the player for now
  PUSH AF                 ;
  LD HL,(ACTOR)           ;
  PUSH HL                 ;
  LD HL,PLAYER            ;
  LD (ACTOR),HL           ;
  XOR A                   ;
  LD (ACTING),A           ;
  LD A,B                  ; Move the player there
  LD (DESTINATION),A      ;
  CALL MOVE_THERE         ;
  CALL NOTE_LIGHT         ;
  POP HL                  ; Put the sentence back
  LD (ACTOR),HL           ;
  POP AF                  ;
  LD (ACTING),A           ;
MOVE_CONTENTS_0:
  POP HL
  XOR A
  LD (HL),A
  RET

; Put everything held by object A in location B
;
; Used by the routine at MOVE_CONTENTS.
;
; Recursively, so what is inside those goes too; if one of them is the player,
; PLAYER_MOVED is cleared to say so.
MOVE_HELD:
  PUSH IY
  PUSH IX
  LD IX,OBJECT_INDEX-$0003
MOVE_HELD_0:
  CALL NEXT_OBJECT_KEEP_A ; Next object held by A
  JR Z,MOVE_HELD_2        ;
  CP (IY+$01)             ;
  JR NZ,MOVE_HELD_0       ;
  LD (IY+$10),B           ; Its location becomes B
  PUSH AF                 ; The player? Note it
  LD A,(IX+$00)           ;
  AND A                   ;
  JR NZ,MOVE_HELD_1       ;
  LD (PLAYER_MOVED),A     ;
MOVE_HELD_1:
  CALL MOVE_HELD          ; And the same for what it holds
  POP AF
  JR MOVE_HELD_0
MOVE_HELD_2:
  POP IX
  POP IY
  RET

; How much room is left in a location
;
; Used by the routine at CAN_PASS.
;
; Byte 1 of its record, less the size of everything that is only there; 0 if it
; is over-full.
;
; I:A The location
; O:A The room left
ROOM_LEFT:
  PUSH IX
  PUSH IY
  PUSH BC
  LD B,A
  CALL GET_ROOM
  LD A,(IX+$01)
  LD C,A
  LD IX,OBJECT_INDEX-$0003
ROOM_LEFT_0:
  CALL NEXT_EXIT
  JR Z,ROOM_LEFT_1
  LD A,(IY+$00)
  CP $01
  JR NZ,ROOM_LEFT_0
  LD A,B
  CP (IY+$10)
  JR NZ,ROOM_LEFT_0
  LD A,C
  SUB (IY+$02)
  JR C,ROOM_LEFT_2
  LD C,A
  JR ROOM_LEFT_0
ROOM_LEFT_1:
  LD A,C
  POP BC
  POP IY
  POP IX
  RET
ROOM_LEFT_2:
  LD C,$00
  JR ROOM_LEFT_1

; Is the first object the actor's, or no object at all?
;
; Used by the routines at MUST_CARRY, DO_TAKE, DO_GIVE, DO_ACTION and DO_TIE.
;
; ACTOR_HAS_A asks the same of the object in A, and HELD_BY_ACTOR does the
; climbing: up through the holders until one is the actor or there are none.
;
; O:F C if so
ACTOR_HAS_FIRST:
  LD A,(TARGET)
; This entry point is used by the routines at DO_SHOOT, DO_ACTION and
; CARRIED_BY_ANOTHER.
ACTOR_HAS_A:
  LD HL,ACTING
; This entry point is used by the routine at DO_TAKE_OUT.
HELD_BY_HL:
  CP $FF
  SCF
  RET Z
  PUSH IX
  CALL HELD_BY_ACTOR
  POP IX
  RET

; Climb from object A through its holders: carry if one is the one at (HL)
;
; Used by the routine at ACTOR_HAS_FIRST.
;
; The climb ACTOR_HAS_FIRST does.
HELD_BY_ACTOR:
  CALL GET_OBJECT
  PUSH AF
  LD A,(IX+$01)
  CP $FF
  JR Z,HELD_BY_ACTOR_0
  POP IX
  CP (HL)
  JR NZ,HELD_BY_ACTOR
  SCF
  RET
HELD_BY_ACTOR_0:
  POP AF
  AND A
  RET

; A random number from 0 to A
;
; Used by the routines at MOVE, DO_RUN, DO_TALK, DO_SHOOT, NEW_GAME_CHOICES,
; SCRIPT_RANDOM, WEAR_RING, GIVEN_SOMETHING, GANDALF_CHATTER, THORIN_CHATTER,
; DRAGON_HUNTS, HALF_THE_TIME and GOLLUM_POCKETS.
;
; RANDOM, with the sign dropped.
RANDOM_POSITIVE:
  CALL RANDOM
  BIT 7,A
  RET Z
  NEG
  RET

; A random number from -A to A
;
; Used by the routines at JOSTLE, DO_STRIKE and RANDOM_POSITIVE.
;
; Mixes the last result, kept at RANDOM_LAST and seeded from R by START, with
; the byte the pointer at RANDOM_POINTER has got to -- it steps on by one every
; call -- and one DE bytes past it, and draws again if that repeats the last
; result. The byte is then halved until it is no more than twice A, and A taken
; off.
;
; Measured over 3000 calls each, through RANDOM_POSITIVE: every value from 0 to
; A comes up, but not evenly -- for A = 4 the ends come up half as often as the
; middle, and for A = 9 the top three do.
;
; I:A The limit, 0 to 127
; O:A The result, -A to A
RANDOM:
  PUSH IX
  PUSH BC
  LD C,A                  ; B = twice the limit, or $FF if that overflows
  SLA A                   ;
  JR NC,RANDOM_0          ;
  LD A,$FF                ;
RANDOM_0:
  LD B,A                  ;
RANDOM_1:
  LD IX,RANDOM_POINTER    ; Step the pointer on
  INC (IX+$01)            ;
  JR NZ,RANDOM_2          ;
  INC (IX+$00)            ;
RANDOM_2:
  LD IX,(RANDOM_POINTER)  ; Mix two bytes from there into the last result
  LD A,(RANDOM_LAST)      ;
  ADC A,(IX+$00)          ;
  ADD IX,DE               ;
  XOR (IX+$01)            ;
  PUSH HL                 ;
  LD HL,RANDOM_LAST       ;
  CP (HL)                 ;
  POP HL                  ; The same as last time? Draw again; otherwise keep
  JR Z,RANDOM_1           ; it
  LD (RANDOM_LAST),A      ;
RANDOM_3:
  CP B                    ; Halve it until it is no more than B
  JR C,RANDOM_4           ;
  JR Z,RANDOM_4           ;
  SRL A                   ;
  JP RANDOM_3             ;
RANDOM_4:
  SUB C                   ; Take the limit off
  POP BC
  POP IX
  RET

; The sizes of what object A holds directly, added up (ADD_UP_HELD)
;
; Used by the routines at MOVE, DO_PUT_IN and DO_CLIMB_INTO.
SIZE_HELD:
  PUSH BC
  LD B,$01
  JR SUM_HELD

; The weights of everything in object A, at any depth, added up (ADD_UP_HELD)
;
; Used by the routines at CAN_LIFT and DO_GIVE.
WEIGHT_HELD:
  PUSH BC
  LD B,$00
; This entry point is used by the routine at SIZE_HELD.
SUM_HELD:
  PUSH IX
  PUSH IY
  LD C,$00
  CALL ADD_UP_HELD
  LD A,C
  POP IY
  POP IX
  POP BC
  RET

; Add up the sizes or the weights of what object A holds
;
; Used by the routine at WEIGHT_HELD.
;
; With B set, the sizes of what it holds directly (SIZE_HELD, SIZE_HELD); with
; B clear, the weights of everything in it at any depth (WEIGHT_HELD,
; WEIGHT_HELD). The sum is kept in C, and goes to $FF on overflow.
;
; I:A The holder
; I:B 1 for sizes, 0 for weights
; O:C The sum
ADD_UP_HELD:
  PUSH IX
  LD IX,OBJECT_INDEX
ADD_UP_HELD_0:
  CALL NEXT_OBJECT_KEEP_A
  JR Z,ADD_UP_HELD_3
  CP (IY+$01)
  JR NZ,ADD_UP_HELD_0
  PUSH AF
  SUB A
  CP B
  LD A,C
  JR Z,ADD_UP_HELD_1
  ADD A,(IY+$02)
  JP PE,ADD_UP_HELD_4
  LD C,A
  JR ADD_UP_HELD_2
ADD_UP_HELD_1:
  ADD A,(IY+$03)
  JP PE,ADD_UP_HELD_4
  LD C,A
  LD A,(IX+$00)
  CALL ADD_UP_HELD
ADD_UP_HELD_2:
  POP AF
  JR ADD_UP_HELD_0
ADD_UP_HELD_3:
  POP IX
  RET
ADD_UP_HELD_4:
  POP AF
  LD C,$FF
  JR ADD_UP_HELD_3

; The record of the room the current actor is in
;
; Used by the routines at TOO_DARK and FIRST_EXIT.
;
; ACTOR points at the object record of whoever is acting this turn -- the
; player or any other character -- and its location is at +$10, so the same
; code moves everybody.
;
; O:IX The room record
ACTOR_ROOM:
  PUSH AF
  LD IX,(ACTOR)           ; IX = the acting character's object record
  LD A,(IX+$10)           ; A = where that character is
  CALL GET_ROOM           ; IX = that room's record
  POP AF
  RET

; Only a test? Then say it would work, and leave the handler
;
; Used by the routines at DO_LOOK, DO_DROP, DO_TAKE, MOVE, LOOK_THROUGH,
; GO_THROUGH, DO_TALK, DO_DIG, DO_SHOOT, DO_INVENTORY, DO_OPEN, DO_CLOSE,
; DO_ATTACK, DO_PUT_IN, DO_DRINK, DO_EAT, DO_STRIKE, DO_GIVE, DO_EXAMINE,
; DO_EMPTY, INTO_THE_RIVER, DO_LOCK, THROW_THROUGH, DRINK_WATER, DO_TIE,
; DO_UNTIE, SWIM_RIVER, DO_BURN, SWIM_BLACK_RIVER, DRINK_BLACK_WATER,
; WEAR_RING, TAKE_OFF_RING, DO_CAPTURE, GIVEN_SOMETHING, GANDALF_WHATS_THIS,
; GANDALF_CHATTER, THORIN_THRAINS_KEY, ELROND_HELLO, DO_CLIMB_OUT,
; DO_CLIMB_INTO, WARG_HOWLS, THORIN_WHERES_THIEF, THORIN_CHATTER,
; DRAGON_FOLLOWS, DRAGON_THREATENS, DRAGON_HUNTS, MAGIC_DOOR_EXAMINED,
; ELROND_READS_MAP, THROW_ROPE_ACROSS, PULL_ROPE, GOLLUM_ASKS,
; GOLLUM_HEARS_ANSWER, GOLLUM_POCKETS, TROLLS_EAT, TROLLS_TURN_TO_STONE,
; TROLLS_TALK, ELROND_GIVES_LUNCH and JUMP_ONTO_BARREL.
;
; With DOING_IT set this returns and the handler goes on to do the action. With
; it clear it sets SUCCEEDED -- yes, it would work -- and drops its own return
; address, so the RET leaves the handler that called it.
FOR_REAL:
  LD A,(DOING_IT)         ; For real: carry on
  CP $01                  ;
  RET Z                   ;
  INC A                   ; A test: yes, it would work
  LD (SUCCEEDED),A        ;
  POP BC                  ; ...and out of the handler
  RET                     ;

; EMPTY_OUT the first object
;
; Used by the routines at DO_STRIKE and DO_EMPTY.
EMPTY_FIRST:
  LD A,(TARGET)

; Empty an object into whatever holds it
;
; Used by the routines at KILL, BARREL_REACHES_LAKE and TROLLS_TURN_TO_STONE.
;
; Everything held by the object in A passes to the object's own holder, except
; liquids (flag bit 1): those are poured away -- nowhere, held by nothing, not
; visible -- with a message.
;
; I:A The object
EMPTY_OUT:
  PUSH IY
  PUSH IX
  PUSH HL
  CALL GET_OBJECT         ; B = its holder
  LD B,(IX+$01)           ;
  LD IX,OBJECT_INDEX-$0003
EMPTY_OUT_0:
  CALL NEXT_OBJECT_KEEP_A ; Next object held by A
  JR Z,EMPTY_OUT_2        ;
  CP (IY+$01)             ;
  JR NZ,EMPTY_OUT_0       ;
  BIT 1,(IY+$07)          ; A liquid?
  JR Z,EMPTY_OUT_1        ;
  PUSH AF                 ; Poured away
  LD (IY+$10),$00         ;
  LD (IY+$01),$FF         ;
  RES 7,(IY+$07)          ;
  CALL PRINT_RECORD_NAME  ;
  LD HL,MSG_EVAPORATE_B   ;
  CALL RUN_MESSAGE_HL     ;
  POP AF                  ;
  JR EMPTY_OUT_0          ;
EMPTY_OUT_1:
  LD (IY+$01),B           ; Anything else goes to the holder
  JP EMPTY_OUT_0          ;
EMPTY_OUT_2:
  POP HL
  POP IX
  POP IY
  RET

; How many visible things does object A hold?
;
; Used by the routines at DO_INVENTORY, DO_OPEN, DO_EMPTY, CONTENTS_INTRO and
; DO_TIE.
;
; I:A The holder
; O:A The count
COUNT_HELD:
  PUSH IX
  PUSH IY
  PUSH BC
  LD B,$00                 ; Count from 0, through every object
  LD IX,OBJECT_INDEX-$0003 ;
COUNT_HELD_0:
  CALL NEXT_OBJECT_KEEP_A ; Held by A and visible: count it
  JR Z,COUNT_HELD_1       ;
  CP (IY+$01)             ;
  JR NZ,COUNT_HELD_0      ;
  BIT 7,(IY+$07)          ;
  JR Z,COUNT_HELD_0       ;
  INC B                   ;
  JP COUNT_HELD_0         ;
COUNT_HELD_1:
  LD A,B
  POP BC
  POP IY
  POP IX
  RET

; Find a record in a keyed table
;
; Used by the routines at START, DRAW_LOCATION_PICTURE, DO_HELP, MOVE, HANDLED,
; DO_ACTION, REACT, FIND_OBJECT_HANDLER, GET_OBJECT and TROLLS_TURN_TO_STONE.
;
; The game's general-purpose lookup. A table is a run of three-byte records --
; a key, then a two-byte value -- ending at a key of $FF, and this walks it in
; order looking for the key in A. It is not sorted and does not need to be.
; Eleven routines use it: the picture table at PICTURE_TABLE is one, the action
; table at ACTION_TABLE another.
;
; I:A The key to find
; I:IX The table
; O:IX The matching record, or the $FF that ended the table
; O:F NZ if the key was found, Z if the table ran out
FIND_RECORD:
  EXX                     ; Work in the other register set, so the caller's BC,
                          ; DE and HL survive
  PUSH IX                 ; HL walks the table from IX
  POP HL                  ;
  LD B,A                  ; B = the key being looked for
  LD E,$03                ; DE = 3, the size of a record
  LD D,$00                ;
FIND_RECORD_0:
  LD A,(HL)               ; Found it? The key is tested before the end marker,
  CP B                    ; so a key of $FF can never be found
  JR Z,FIND_RECORD_1      ;
  CP $FF                  ; Run off the end?
  JR Z,FIND_RECORD_1      ;
  ADD HL,DE               ; On to the next record
  JP FIND_RECORD_0        ;
FIND_RECORD_1:
  PUSH HL                 ; IX = the record, or the $FF that ended the table
  POP IX                  ;
  CP $FF                  ; NZ if found; A is the key
  EXX
  RET
; Done in the alternate register set, so the caller's BC, DE and HL survive it.

; Find the next object that fits a name
;
; Used by the routines at EXCEPTED and TARGET_TROUBLE.
;
; Walks OBJECT_INDEX from IX, three bytes at a time with the iterator the exits
; use, which leaves each object's record in IY. An object is passed over if its
; name does not match (NAME_MATCHES against the record's bytes 8-13), if a mode
; in FIND_MODE asks only for objects whose byte 7 has, or lacks, bit 6 set with
; bit 3 clear, or -- unless PATTERN_OPTION says otherwise -- if IN_REACH finds
; it is not within the actor's reach.
;
; I:HL The name to look for
; I:IX Where in the index to carry on from
; O:A The object number, or $FF when there are no more
FIND_NAMED_OBJECT:
  PUSH BC
  PUSH DE
  PUSH IY
  LD IY,(ACTOR)           ; IY = the actor; D = where the actor is
  LD D,(IY+$10)           ;
  LD A,(FIND_MODE)        ; E = the mode: 0 only things, 1 only characters, 2
  LD E,A                  ; either
FIND_NAMED_OBJECT_0:
  CALL NEXT_EXIT           ; Next object in the index -- IY is its record -- or
  JR Z,FIND_NAMED_OBJECT_3 ; stop at the end
  LD A,$02                 ; Mode 2: take anything
  CP E                     ;
  JR Z,FIND_NAMED_OBJECT_2 ;
  LD A,(IY+$07)             ; A = 1 for a character (flags bit 6 set, bit 3
  AND $48                   ; clear), else 0...
  CP $40                    ;
  LD A,$00                  ;
  JR NZ,FIND_NAMED_OBJECT_1 ;
  INC A                     ;
FIND_NAMED_OBJECT_1:
  CP E                      ; ...and pass it over if that is not the kind
  JR NZ,FIND_NAMED_OBJECT_0 ; wanted
FIND_NAMED_OBJECT_2:
  LD BC,$0008               ; Compare the typed name with the object's, at
  PUSH IY                   ; bytes 8-13 of its record
  ADD IY,BC                 ;
  CALL NAME_MATCHES         ;
  POP IY                    ;
  JR NZ,FIND_NAMED_OBJECT_0 ;
  LD A,(PATTERN_OPTION)     ; Asked not to check reach?
  AND A                     ;
  JR NZ,FIND_NAMED_OBJECT_3 ;
  LD A,(IX+$00)            ; Pass over anything out of the actor's reach
  CALL IN_REACH            ;
  JR Z,FIND_NAMED_OBJECT_0 ;
FIND_NAMED_OBJECT_3:
  LD A,(IX+$00)           ; A = this object's number, or $FF from the end of
                          ; the index
  POP IY
  POP DE
  POP BC
  RET

; IN_REACH_OF, the other way round
;
; Used by the routines at CHARACTERS_ACT and THORIN_KILLED.
;
; IX and IY are swapped for the call and back again: CHARACTERS_ACT asks
; whether the player, at IY, can see the character at IX.
ACTOR_IN_REACH:
  CALL ACTOR_IN_REACH_0
  CALL IN_REACH_OF
ACTOR_IN_REACH_0:
  PUSH IX
  PUSH IY
  POP IX
  POP IY
  RET

; Is an object within the acting character's reach?
;
; Used by the routines at TOO_DARK, FIND_NAMED_OBJECT, LIST_HELD and
; DO_CLIMB_INTO.
;
; The actor from ACTOR, then IN_REACH_OF. Called directly with the player at
; Bag End, it says yes to the wooden chest, the map the player holds, Gandalf,
; Thorin, and the round green door -- which is in Bag End and the Lonelands at
; once -- and no to the large key the troll is holding in the clearing, the
; heavy rock door, and the short strong sword, which is lying in the trolls'
; cave, where Bilbo finds Sting in the book.
;
; I:A The object's number
; I:IY Its record
; O:F NZ if it is within reach
IN_REACH:
  PUSH IX
  LD IX,(ACTOR)           ; The acting character
  CALL IN_REACH_OF
  POP IX
  RET

; Is an object within reach of the character in IX?
;
; Used by the routines at ACTOR_IN_REACH and IN_REACH.
;
; Nothing is within reach that has bit 7 of its flags clear. Otherwise it is if
; the character is inside it; or if the two are shut in the same container; or
; if neither is shut in anything and the object is in the character's location
; -- any of its locations, which is how a door is within reach from either
; side.
;
; I:IX The character's record
; I:IY The object's record
IN_REACH_OF:
  BIT 7,(IY+$07)          ; Not there to be seen: never in reach
  RET Z                   ;
  PUSH IY
  PUSH IX
  PUSH BC
  LD B,A                  ; B = the object; C = where the character is
  LD C,(IX+$10)           ;
  PUSH IY                 ; Is the character shut inside the object itself?
  CALL SHUT_IN            ; Then it is in reach
  CP B                    ;
  LD B,A                  ;
  POP IX                  ;
  JR Z,IN_REACH_OF_2
  CALL SHUT_IN            ; Shut inside something the object is not? Out of
  CP B                    ; reach
  JR NZ,IN_REACH_OF_1     ;
  INC A                   ; Both shut in the same thing: in reach
  JR NZ,IN_REACH_OF_2     ;
  LD B,(IY+$00)           ; Both free: in reach if the character's location is
  LD A,C                  ; any of the object's
IN_REACH_OF_0:
  CP (IY+$10)             ;
  JR Z,IN_REACH_OF_2      ;
  INC IY                  ;
  DJNZ IN_REACH_OF_0      ;
IN_REACH_OF_1:
  XOR A                   ; Z: out of reach
  JR IN_REACH_OF_3        ;
IN_REACH_OF_2:
  OR $01                  ; NZ: in reach
IN_REACH_OF_3:
  POP BC
  POP IX
  POP IY
  RET

; What is this object shut inside?
;
; Used by the routines at TOO_DARK and IN_REACH_OF.
;
; Follows byte 1 of the object's record -- what holds it -- up through holders
; whose flags have $28 set, which can be seen into, and returns the first that
; cannot, or $FF if it runs out. The player's own record has $28 set, so a
; thing the player carries is not shut in anything by being carried.
;
; Byte 1 is watched as well as read: the map is held by Gandalf ($3E) on the
; tape and by the player (0) at the first prompt, the turn the game says
; Gandalf gives it to you; and the large key is held by the hideous troll, as
; the trolls' clearing says it is.
;
; I:IX The object's record
; O:A What it is shut in, or $FF
SHUT_IN:
  PUSH IX
SHUT_IN_0:
  LD A,(IX+$01)           ; Held by nothing? Then it is not shut in anything: A
  CP $FF                  ; = $FF
  JR Z,SHUT_IN_1          ;
  EX AF,AF'               ; Go up to the holder, keeping its number
  LD A,(IX+$01)           ;
  CALL GET_OBJECT         ;
  LD A,(IX+$07)           ; Can the holder be seen into (flags $28)? Then keep
  AND $28                 ; climbing
  JR NZ,SHUT_IN_0         ;
  EX AF,AF'               ; A = the first holder that cannot be seen into
SHUT_IN_1:
  POP IX
  RET

; Point IX just before the actor's room's first exit
;
; Used by the routines at START_TARGETS, START_INSTRUMENTS, TARGET_TROUBLE,
; FIND_EXIT and EXIT_TO.
;
; The room's record, plus 7: three short of the exits, because NEXT_EXIT steps
; three before it looks.
FIRST_EXIT:
  PUSH DE
  CALL ACTOR_ROOM         ; IX = the actor's room
  LD DE,$0007             ; Plus 7: three short of the exits at +10, since
  ADD IX,DE               ; NEXT_EXIT adds 3 before it looks
  POP DE
  RET

; Which of the places the exits lead to has this name?
;
; Used by the routine at TARGET_TROUBLE.
;
; How ENTER and GO INTO name a place: each exit's destination is looked up and
; its name matched against the phrase with NAME_MATCHES.
;
; I:IX The exits, as FIRST_EXIT leaves them
; O:A The location, or $FF
ROOM_BY_NAME:
  PUSH IY
  PUSH DE
  LD DE,$0002
ROOM_BY_NAME_0:
  CALL NEXT_EXIT
  JR Z,ROOM_BY_NAME_1
  LD A,(IX+$02)
  PUSH IX
  CALL GET_ROOM
  PUSH IX
  POP IY
  POP IX
  ADD IY,DE
  CALL NAME_MATCHES
  JR NZ,ROOM_BY_NAME_0
  LD A,(IX+$02)
ROOM_BY_NAME_1:
  POP DE
  POP IY
  RET

; Print the name of the object whose record is at IY
;
; Used by the routines at DO_EXAMINE, EMPTY_OUT and LIST_HELD.
PRINT_RECORD_NAME:
  PUSH IY
  PUSH DE
  LD DE,$0008
  ADD IY,DE
  CALL PRINT_NAME
  POP DE
  POP IY
  RET

; Print an object's name, with its article
;
; Used by the routines at PRINT_NAME_AT, DESCRIPTION_OR_NAME and
; PRINT_RECORD_NAME.
;
; The article (ARTICLE), then the adjectives in the order stored, then the
; noun. With NOUN_ONLY set, the noun alone.
;
; I:IY The name's six bytes: noun, then two adjectives
PRINT_NAME:
  PUSH AF
  PUSH DE
  LD A,(NOUN_ONLY)        ; The noun only?
  CP $00                  ;
  JR NZ,PRINT_NAME_0      ;
  LD D,(IY+$01)           ; The article, for the noun
  LD E,(IY+$00)           ;
  CALL ARTICLE            ;
  LD E,(IY+$02)           ; The adjectives
  LD D,(IY+$03)           ;
  CALL PRINT_WORD_DE      ;
  LD E,(IY+$04)           ;
  LD D,(IY+$05)           ;
  CALL PRINT_WORD_DE      ;
PRINT_NAME_0:
  LD E,(IY+$00)           ; The noun, if there is one
  LD D,(IY+$01)           ;
  LD A,D                  ;
  OR E                    ;
  CALL NZ,PRINT_NOUN      ;
  POP DE
  POP AF
  RET

; Find the actor's room's exit in a direction
;
; Used by the routines at MOVE and DO_RUN.
;
; Walks the exits for one whose direction matches and whose destination is not
; zero, and returns with IX on it. Watched as well as read: rewinding from the
; moment the player's location changed on EAST out of Bag End to where this
; returned found IX at ROOM1_EAST, the direction 3, and the record 03 05 04 --
; east, through the round green door, to location 4.
;
; I:A The direction, 1-10
; O:IX The exit
; O:F NZ if there is one
FIND_EXIT:
  PUSH BC
  PUSH IY
  LD B,A                  ; B = the direction wanted
  CALL FIRST_EXIT         ; IX just before the actor's room's first exit
FIND_EXIT_0:
  CALL NEXT_EXIT          ; Next exit, or give up at the end of the list
  JR Z,FIND_EXIT_1        ;
  LD A,(IX+$02)           ; An exit leading to location 0 goes nowhere yet:
  AND A                   ; pass over it
  JR Z,FIND_EXIT_0        ;
  LD A,(IX+$00)           ; Not the direction wanted: keep looking
  CP B                    ;
  JP NZ,FIND_EXIT_0       ;
FIND_EXIT_1:
  POP IY
  POP BC
  RET

; Find the exit that goes through the first object
;
; Used by the routines at LOOK_THROUGH, GO_THROUGH and SWIM_RIVER.
;
; FIND_EXIT's search with the field it matches patched: byte 1 of an exit, the
; object it goes through, here; byte 2, the destination, from EXIT_TO.
;
; O:IX The exit
; O:F Z if there is none
EXIT_VIA:
  LD A,(TARGET)
; This entry point is used by the routines at THROW_THROUGH and
; THROW_ROPE_ACROSS.
EXIT_VIA_A:
  PUSH AF
  LD A,$01
  JR FIND_EXIT_FIELD

; Find the exit that leads to location A
;
; Used by the routines at DO_ENTER, DO_FOLLOW and JUMP_ONTO_BARREL.
;
; I:A The location
; O:IX The exit
; O:F Z if there is none
EXIT_TO:
  PUSH AF
  LD A,$02
; This entry point is used by the routine at EXIT_VIA.
FIND_EXIT_FIELD:
  LD (EXIT_FIELD_TEST+$0002),A
  POP AF
  PUSH BC
  PUSH IY
  LD B,A
  CALL FIRST_EXIT
EXIT_TO_0:
  CALL NEXT_EXIT
  JR Z,EXIT_TO_1
EXIT_FIELD_TEST:
  LD A,(IX+$02)
  CP B
  JR NZ,EXIT_TO_0
EXIT_TO_1:
  POP IY
  POP BC
  RET

; Run the routine at HL with the first and second objects swapped
;
; Used by the routines at DO_FILL, DO_THROW_AT and DO_TIE.
;
; Both the numbers in TARGET to INSTRUMENT and the records in TARGET_RECORD to
; INSTRUMENT_RECORD, all put back afterwards.
;
; I:HL The routine
SWAPPED_OBJECTS:
  LD DE,(TARGET_RECORD)
  LD IY,(INSTRUMENT_RECORD)
  LD (TARGET_RECORD),IY
  LD (INSTRUMENT_RECORD),DE
  LD BC,(TARGET)
  LD A,B
  LD (TARGET),A
  LD A,C
  LD (INSTRUMENT),A
  CALL RUN_ROUTINE
  LD (TARGET),BC
  LD (TARGET_RECORD),DE
  LD (INSTRUMENT_RECORD),IY
  RET

; The action cannot be done
;
; Used by the routines at CAN_LIFT, DO_TAKE, MOVE, LOOK_THROUGH, GO_THROUGH,
; DO_FILL, DO_STRIKE, THROW_THROUGH, DO_TIE, DO_BURN, OPEN_CRACK, DO_CAPTURE,
; GOBLINS_DOOR_OPENED, DO_CLIMB_OUT, DO_CLIMB_INTO, WINDOW_OPEN_CLOSE,
; THROW_ROPE_ACROSS, TROLLS_EAT and ELROND_GIVES_LUNCH.
;
; For real, the refusal is narrated ("... cannot ...", through NARRATE_ACTION);
; as a test, SUCCEEDED is cleared: no, it would not work.
REFUSE:
  LD A,(DOING_IT)
  DEC A
  JP Z,NARRATE_ACTION
  SUB A
  LD (SUCCEEDED),A
  RET

; Where an object is, if it is in only one place
;
; Used by the routines at CHARACTERS_ACT, ACTOR_TRIES, ANNOUNCE_ARRIVAL and
; NOTE_LIGHT.
;
; I:A The object, or $FF
; O:A Its location; $FF if it is in several, or for $FF
LOCATION_OF:
  CP $FF
  RET Z
  CALL GET_OBJECT
  LD A,$01
  CP (IX+$00)
  LD A,$FF
  RET NZ
  LD A,(IX+$10)
  RET

; "you see :" and what is there
;
; Used by the routine at DESCRIBE_LOCATION.
YOU_SEE:
  PUSH IY
  PUSH AF
  PUSH BC
  LD HL,MSG_SEE_B         ; "you see :"
  CALL RUN_MESSAGE_HL     ;
  LD A,$FF
  LD IY,(ACTOR)           ; What lies loose where the actor is
  LD B,(IY+$10)           ;
  CALL LIST_HERE          ;
  POP BC
  POP AF
  POP IY
  RET

; List what is in a place, or say "nothing"
;
; Used by the routines at DO_LOOK, DO_INVENTORY, DO_OPEN and YOU_SEE.
;
; I:A The holder, or $FF for what lies loose
; I:B The location
LIST_HERE:
  PUSH IY
  PUSH DE
  PUSH BC
  LD C,$00                ; List it, from an indent of 4
  LD D,$04                ;
  CALL LIST_HELD          ;
  SUB A                   ; Nothing listed: "nothing"
  CP C                    ;
  LD HL,MSG_NOTHING       ;
  CALL Z,RUN_MESSAGE_HL   ;
  POP BC
  POP DE
  POP IY
  RET

; List what object A holds, or with A = $FF what lies loose in location B
;
; Used by the routine at LIST_HERE.
;
; Each thing is named and followed by a full stop, and then -- unless
; CONTENTS_INTRO says otherwise -- whatever it holds is listed after it, two
; places further in: the indent is kept at INDENT, and this calls itself. Left
; out: the actor itself, anything out of the actor's reach, and loose things
; that are in more than one place at once, which are the doors and other
; fixtures -- EXITS_THROUGH has already told of those.
;
; I:A The holder, or $FF
; I:B The location
; I:D The indent
; O:C How many were listed, added on
LIST_HELD:
  PUSH HL                 ; Indent by D, keeping the old indent
  LD L,A                  ;
  LD A,(INDENT)           ;
  LD H,A                  ;
  LD A,D                  ;
  LD (INDENT),A           ;
  LD A,L                  ;
  EX (SP),HL              ;
  PUSH IX                  ; Walk every object
  LD IX,OBJECT_INDEX-$0003 ;
LIST_HELD_0:
  CALL NEXT_OBJECT_KEEP_A ; Next object held by A
  JR Z,LIST_HELD_6        ;
  CP (IY+$01)             ;
  JR NZ,LIST_HELD_0       ;
  PUSH AF                 ; Loose and in several places? Leave it out.
  INC A                   ; Otherwise, is it in location B, first or second of
  LD E,(IY+$00)           ; its places?
  JR NZ,LIST_HELD_1       ;
  LD A,$01                ;
  CP E                    ;
  JR NZ,LIST_HELD_4       ;
LIST_HELD_1:
  LD A,(IY+$10)           ;
  CP B                    ;
  JR Z,LIST_HELD_2        ;
  DEC E                   ;
  JR Z,LIST_HELD_4        ;
  LD A,(IY+$11)           ;
  CP B                    ;
  JR NZ,LIST_HELD_4       ;
LIST_HELD_2:
  LD A,(ACTING)           ; Not the actor, at the top level
  CP (IX+$00)             ;
  JR NZ,LIST_HELD_3       ;
  LD A,$04                ;
  CP D                    ;
  JR Z,LIST_HELD_4        ;
LIST_HELD_3:
  LD A,(IX+$00)           ; Out of reach? Leave it out
  CALL IN_REACH           ;
  JR Z,LIST_HELD_4        ;
  INC C                   ; Count it, and name it
  SUB A                   ;
  LD (CAPITAL_NEXT),A     ;
  LD (NOUN_ONLY),A        ;
  CALL PRINT_RECORD_NAME  ;
  LD A,(ACTING)           ; The actor itself: LIST_HELD_5
  CP (IX+$00)             ;
  JR Z,LIST_HELD_5        ;
  LD A,$2E                ; A full stop
  CALL PRINT_CHAR         ;
  LD A,(IX+$00)           ; And what it holds, two further in
  CALL CONTENTS_INTRO     ;
  JR C,LIST_HELD_4        ;
  LD A,(IX+$00)           ;
  PUSH DE                 ;
  INC D                   ;
  INC D                   ;
  CALL LIST_HELD          ;
  POP DE                  ;
LIST_HELD_4:
  POP AF                  ; On to the next
  JP LIST_HELD_0          ;
LIST_HELD_5:
  CALL NEW_LINE
  JR LIST_HELD_4
LIST_HELD_6:
  POP IX
  EX (SP),HL
  LD A,H
  LD (INDENT),A
  LD A,L
  POP HL
  RET

; Introduce what an object holds, for LIST_HELD
;
; Used by the routines at DO_OPEN and LIST_HELD.
;
; Only for something that can be seen into and holds anything visible: a
; character's is "... is carrying", a thing's the phrase for how things sit
; with it (PLACED_WORD), its name, and "is" or "are" there. Otherwise a new
; line, and carry set, so LIST_HELD goes no deeper.
;
; I:A The object
; O:F Carry set if there is nothing to list
CONTENTS_INTRO:
  PUSH IX
  PUSH BC
  PUSH DE
  LD C,A
  CALL GET_OBJECT
  LD A,(IX+$07)
  AND $28
  JR Z,CONTENTS_INTRO_4
  LD A,C
  CALL COUNT_HELD
  CP $00
  JR Z,CONTENTS_INTRO_4
  BIT 6,(IX+$07)
  JR Z,CONTENTS_INTRO_0
  LD A,C
  PUSH AF
  LD HL,MSG_CARRYING_B
  JR CONTENTS_INTRO_2
CONTENTS_INTRO_0:
  LD HL,$039B
  DEC A
  JR Z,CONTENTS_INTRO_1
  LD HL,$0065
CONTENTS_INTRO_1:
  PUSH HL
  LD L,(IX+$08)
  LD A,(IX+$09)
  AND $0F
  LD H,A
  PUSH HL
  CALL PLACED_WORD
  LD HL,MSG_THERE
CONTENTS_INTRO_2:
  CALL RUN_MESSAGE_HL
  AND A
CONTENTS_INTRO_3:
  POP DE
  POP BC
  POP IX
  RET
CONTENTS_INTRO_4:
  CALL NEW_LINE
  SCF
  JR CONTENTS_INTRO_3

; Print how things are placed with this object: "in the", "on the"...
;
; Used by the routines at DO_LOOK and CONTENTS_INTRO.
;
; Picked by the low four bits of byte 4 of its record, from the phrases at
; MSG_IN_ON_BEHIND_UNDER, four bytes apart: in, on, behind, under, tied to.
;
; I:IX The object's record
PLACED_WORD:
  LD HL,MSG_IN_ON_BEHIND_UNDER ; The phrase for its byte 4
  LD A,(IX+$04)                ;
  RLCA                         ;
  RLCA                         ;
  AND $3C                      ;
  LD E,A                       ;
  LD D,$00                     ;
  ADD HL,DE                    ;
  JP RUN_MESSAGE_HL            ;

; Point at a location's exits
;
; Used by the routines at EXITS_THROUGH and VISIBLE_EXITS.
;
; IX is left three bytes short of the first exit and BC = 3, so that ADD IX,BC
; steps to each in turn.
;
; I:A The location
; O:IX Its record + 7
; O:BC 3
EXITS_OF:
  CALL GET_ROOM
  LD BC,$0007
  ADD IX,BC
  LD BC,$0003
  RET

; The word for a direction
;
; Used by the routines at EXITS_THROUGH, VISIBLE_EXITS and ELROND_READS_MAP.
;
; I:A The direction, 1 to 10 (bit 7 ignored)
; O:DE Its word reference, from DIRECTION_WORDS
DIRECTION_WORD:
  LD HL,DIRECTION_WORDS-$0002
; This entry point is used by the routine at SAY_STATE.
WORD_FROM_TABLE:
  LD E,A
  RES 7,E
  LD D,$00
  ADD HL,DE
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  RET

; Say where each way out through something lies
;
; Used by the routine at DESCRIBE_LOCATION.
;
; For every exit of the location that goes through an object which can be seen:
; "to the east there is ...", or "above there is ..." and "below there is ..."
; for up and down, with the object's name. This is how doors appear in a
; description.
;
; I:A The location
EXITS_THROUGH:
  PUSH BC
  PUSH DE
  PUSH IY
  PUSH IX
  CALL EXITS_OF           ; IY = the first exit
  ADD IX,BC               ;
  PUSH IX                 ;
  POP IY                  ;
EXITS_THROUGH_0:
  SUB A                   ; Not through anything: skip it
  CP (IY+$01)             ;
  JR Z,EXITS_THROUGH_3    ;
  LD A,(IY+$01)           ; Through something that cannot be seen: skip it
  CALL GET_OBJECT         ;
  BIT 7,(IX+$07)          ;
  JR Z,EXITS_THROUGH_3    ;
  LD DE,$0008             ; Its name, for the message
  ADD IX,DE               ;
  PUSH IX                 ;
  LD A,(IY+$00)           ; The direction's word
  CALL DIRECTION_WORD     ;
  CP $09                  ; Up is "above", down "below"
  JR C,EXITS_THROUGH_1    ;
  LD DE,$07B5             ;
  JR Z,EXITS_THROUGH_2    ;
  LD DE,$082B             ;
  JR EXITS_THROUGH_2      ;
EXITS_THROUGH_1:
  LD HL,MSG_TO_THE        ; The rest are "to the ..."
  CALL RUN_MESSAGE_HL     ;
EXITS_THROUGH_2:
  CALL PRINT_WORD_DE      ; The word, then "there is ..."
  LD HL,MSG_THERE_IS      ;
  CALL RUN_MESSAGE_HL     ;
EXITS_THROUGH_3:
  ADD IY,BC               ; Until the $FF after the last exit
  LD A,$FF                ;
  CP (IY+$00)             ;
  JP NZ,EXITS_THROUGH_0   ;
  POP IX
  POP IY
  POP DE
  POP BC
  RET

; Step to the next open way out
;
; Used by the routine at VISIBLE_EXITS.
;
; One that goes through nothing, and has not been wiped -- NEW_GAME_CHOICES
; leaves a shut road with a direction of 0.
;
; I:IX The last exit, or EXITS_OF's pointer
; O:IX The next open exit
; O:F Z at the end
NEXT_OPEN_EXIT:
  ADD IX,BC
  LD A,$FF
  CP (IX+$00)
  RET Z
  XOR A
  CP (IX+$01)
  JR NZ,NEXT_OPEN_EXIT
  CP (IX+$00)
  JR Z,NEXT_OPEN_EXIT
  RET

; "visible exits are:" and the open ways out
;
; Used by the routine at DESCRIBE_LOCATION.
;
; Nothing at all is printed when there are none.
;
; I:A The location
VISIBLE_EXITS:
  PUSH IX
  PUSH IY
  PUSH DE
  PUSH BC
  CALL EXITS_OF           ; Is there an open way out at all?
  CALL NEXT_OPEN_EXIT     ;
  JR Z,VISIBLE_EXITS_1
  LD HL,MSG_VISIBLE_EXITS_ARE ; "visible exits are:"
  CALL RUN_MESSAGE_HL         ;
VISIBLE_EXITS_0:
  LD A,(IX+$00)           ; Each one's direction
  CALL DIRECTION_WORD     ;
  CALL PRINT_WORD_DE      ;
  CALL NEXT_OPEN_EXIT     ;
  JR NZ,VISIBLE_EXITS_0   ;
  CALL NEW_LINE           ; New line
VISIBLE_EXITS_1:
  POP BC
  POP DE
  POP IY
  POP IX
  RET

; SAY_STATE for the object whose record is at IY
;
; Used by the routines at DO_PUT_IN, DO_LOCK and THROW_THROUGH.
SAY_STATE_OF:
  LD L,(IY+$08)
  LD H,(IY+$09)
  JR SAY_STATE_NAMED

; "the ... is ...": an object and its state
;
; Used by the routines at LOOK_THROUGH, DO_FILL, DO_SHOOT, DO_OPEN, DO_CLOSE,
; DO_ATTACK, DO_STRIKE, DO_EMPTY, DO_LOCK, DO_UNLOCK, DO_CLIMB_OUT and
; DO_CLIMB_INTO.
;
; The state word is picked by A from STATE_WORDS: bits 0-6 the pair, bit 7
; which of the two. A kill says "the ... is dead.", CLIMB OUT OF something shut
; "the ... is closed.". SAY_STATE_NAMED is the way in with the name already in
; HL.
;
; I:A The state
; I:IX The object's record
SAY_STATE:
  LD L,(IX+$08)
  LD H,(IX+$09)
; This entry point is used by the routine at SAY_STATE_OF.
SAY_STATE_NAMED:
  PUSH DE
  PUSH HL
  LD HL,STATE_WORDS
  BIT 7,A
  JR Z,SAY_STATE_0
  LD HL,STATE_WORDS_SET
SAY_STATE_0:
  CALL WORD_FROM_TABLE
  POP HL
  PUSH DE
  PUSH HL
  LD HL,MSG_IS
  CALL RUN_MESSAGE_HL
  POP DE
  RET

; Rename an object BROKEN, or a character DEAD
;
; Used by the routines at DO_STRIKE, KILL and THORIN_KILLED.
;
; The first adjective of its name becomes BROKEN, or DEAD for a character, and
; the second is dropped.
;
; I:A The object
BROKEN_OR_DEAD:
  PUSH IX
  CALL GET_OBJECT
  LD (IX+$0C),$00
  LD (IX+$0D),$00
  LD DE,$00CD
  BIT 6,(IX+$07)
  JR Z,BROKEN_OR_DEAD_0
  LD DE,$0192
BROKEN_OR_DEAD_0:
  LD (IX+$0A),E
  LD (IX+$0B),D
  POP IX
  RET

; Unreached: a routine that walks the objects held by one
;
; It reads as a search of the object index for what is held by the object in A,
; returning the first. Nothing calls it.
UNREACHED_WALK_HELD:
  DEFB $FD,$E5,$DD,$E5,$DD,$21,$60,$C0
  DEFB $CD,$A9,$9B,$28,$05,$FD,$BE,$01
  DEFB $20,$F6,$DD,$7E,$00,$DD,$E1,$FD
  DEFB $E1,$C9

; Is this a character, and alive?
;
; Used by the routine at DO_SHOOT.
;
; Flag bit 6 set, a character, and bit 3 clear, not dead.
;
; I:IX The record
; O:F Z if so
IS_ALIVE:
  LD A,(IX+$07)
  AND $48
  CP $40
  RET

; Is the action one where the second object is asked first?
;
; Used by the routines at HANDLED and DO_ACTION.
;
; O:F Z if the action in ACTION is in SECOND_FIRST
IS_SECOND_FIRST:
  PUSH HL
  PUSH BC
  LD B,$05
  LD HL,SECOND_FIRST
  LD A,(ACTION)
IS_SECOND_FIRST_0:
  CP (HL)
  JR Z,IS_SECOND_FIRST_1
  INC HL
  DJNZ IS_SECOND_FIRST_0
IS_SECOND_FIRST_1:
  POP BC
  POP HL
  RET

; The actor says the message at HL: ... says " ... "
;
; Used by the routines at GIVEN_SOMETHING, GANDALF_WHATS_THIS, GANDALF_CHATTER,
; THORIN_THRAINS_KEY, ELROND_HELLO, THORIN_WHERES_THIEF, THORIN_CHATTER,
; ELROND_READS_MAP, GOLLUM_ASKS, GOLLUM_POCKETS and TROLLS_TALK.
;
; The words in quotes, capitalised, after the actor's name and "says".
;
; I:HL The message
SAYS:
  PUSH HL
  LD HL,MSG_SAY
  CALL RUN_MESSAGE_HL
  POP HL
  LD A,$01
  LD (CAPITAL_NEXT),A
  CALL RUN_MESSAGE_HL
  LD HL,MSG_CODES_ONLY_D
  JP RUN_MESSAGE_HL

; Is the first object locked, or open?
;
; Used by the routines at DO_OPEN and DO_LOCK.
;
; NZ with A a SAY_STATE state for "locked" or "open"; OPEN_STATE asks only
; whether it is open.
;
; O:F NZ if it is locked or open
; O:A LOCKED or OPEN, for SAY_STATE
LOCK_STATE:
  LD IX,(TARGET_RECORD)
  BIT 0,(IX+$07)
  LD A,$80
  RET NZ
; This entry point is used by the routine at DO_UNLOCK.
OPEN_STATE:
  BIT 5,(IX+$07)
  LD A,$85
  RET

; The actions whose second object is asked first
;
; DROP IN, PUT IN, PUT ON, TAKE OUT OF and THROW THROUGH (see ACTION_PATTERNS):
; in each the second object is what the first goes into, onto, out of or
; through.
SECOND_FIRST:
  DEFB $0E,$11,$12,$14,$2C

; The ten directions, as words
;
; In the order of the direction codes, 1 to 10. DIRECTION_WORD indexes from
; DIRECTION_WORDS-2, two bytes earlier, because there is no direction 0.
DIRECTION_WORDS:
  DEFW $0480              ; NORTH
  DEFW $0607              ; SOUTH
  DEFW $01FE              ; EAST
  DEFW $0779              ; WEST
  DEFW $0485              ; NORTHEAST
  DEFW $048E              ; NORTHWEST
  DEFW $060C              ; SOUTHEAST
  DEFW $0615              ; SOUTHWEST
  DEFW $0725              ; UP
  DEFW $01C4              ; DOWN

; The states of things, as words, in pairs
;
; Eight words for bit 7 of the state clear, then the eight they pair with for
; it set: unlocked and locked, empty and full, broken, off and on, closed and
; open, dead and alive. The gaps are zero.
STATE_WORDS:
  DEFW $0718              ; UNLOCKED, -, EMPTY, -, OFF, CLOSED, DEAD, -
  DEFW $0000              ;
  DEFW $0228              ;
  DEFW $0000              ;
  DEFW $049F              ;
  DEFW $0139              ;
  DEFW $0192              ;
  DEFW $0000              ;
STATE_WORDS_SET:
  DEFW $03F6              ; LOCKED, -, FULL, BROKEN, ON, OPEN, ALIVE, -
  DEFW $0000              ;
  DEFW $02B9              ;
  DEFW $00CD              ;
  DEFW $04AA              ;
  DEFW $04B4              ;
  DEFW $07D4              ;
  DEFW $0000              ;

; The water's own DRINK: nothing happens, and it works
DRINK_WATER:
  CALL FOR_REAL
  RET

; TIE TO
;
; Only with the rope. TIE ROPE TO X is made TIE X TO ROPE by swapping the
; objects (SWAPPED_OBJECTS). Not a liquid, not anything with something visible
; in it ("the ... is already tied."), and not a living character -- a dead one
; can be. The thing is then held by the rope; and the rope goes to the one who
; tied it if they have the thing, or could take it, and is left lying
; otherwise.
DO_TIE:
  LD A,(TARGET)           ; TIE ROPE TO X: swap them round
  CP $12                  ;
  JR Z,DO_TIE_3           ;
  LD A,(INSTRUMENT)       ; Only to the rope
  CP $12                  ;
  JP NZ,REFUSE            ;
  LD IX,(TARGET_RECORD)   ; Not a liquid
  BIT 1,(IX+$07)          ;
  JP NZ,REFUSE            ;
  CALL COUNT_HELD            ; Nothing in it already
  CP $00                     ;
  LD HL,MSG_IS_ALREADY_TIE_D ;
  JP NZ,RUN_MESSAGE_HL       ;
  BIT 3,(IX+$07)          ; Not a living character
  JR NZ,DO_TIE_0          ;
  BIT 6,(IX+$07)          ;
  JP NZ,REFUSE            ;
DO_TIE_0:
  CALL FOR_REAL           ; The test ends here
  LD IY,(INSTRUMENT_RECORD) ; Tied: held by the rope
  CALL ACTOR_HAS_FIRST      ;
  LD A,(INSTRUMENT)         ;
  LD (IX+$01),A             ;
  JR C,DO_TIE_1           ; Could the actor take it? A test of TAKE
  SUB A                   ;
  LD (DOING_IT),A         ;
  CALL DO_TAKE            ;
  LD A,(SUCCEEDED)        ;
  CP $00                  ;
  LD A,$01                ;
  LD (DOING_IT),A         ;
  LD (SUCCEEDED),A        ;
  JR Z,DO_TIE_2           ;
DO_TIE_1:
  LD A,(ACTING)           ; Then the rope is the actor's...
  LD (IY+$01),A           ;
  RET                     ;
DO_TIE_2:
  LD (IY+$01),$FF         ; ...otherwise it is left
  RET                     ;
DO_TIE_3:
  LD HL,DO_TIE            ; The objects swapped round, and again
  JP SWAPPED_OBJECTS      ;

; UNTIE
;
; Only something tied to the rope ("the ... is not tied."); it goes to whoever
; has the rope.
DO_UNTIE:
  LD IX,(TARGET_RECORD)
  LD A,(IX+$01)
  CP $12
  LD HL,MSG_IS_NOT_TIE_D
  JP NZ,RUN_MESSAGE_HL
  CALL FOR_REAL
  LD A,(ROPE_HOLDER)
  LD (IX+$01),A
  RET

; SWIM, in the fast river
;
; Across, if the river's exit leads anywhere: the river is opened for the
; moment it takes MOVE to go that way through it, and shut again. Leading
; nowhere, it works and nothing happens.
SWIM_RIVER:
  CALL EXIT_VIA
  LD A,(IX+$02)
  CP $00
  JR NZ,SWIM_RIVER_0
  CALL FOR_REAL
  RET
SWIM_RIVER_0:
  LD A,(IX+$00)
  LD HL,(ACTION)
  PUSH HL
  LD (ACTION),A
  LD IX,(TARGET_RECORD)
  SET 5,(IX+$07)
  PUSH IX
  LD A,$FF
  LD (TARGET),A
  CALL MOVE_ACTOR
  POP IX
  RES 5,(IX+$07)
  POP HL
  LD (ACTION),HL
  RET

; BURN: only the dragon can, and it kills
DO_BURN:
  LD A,(ACTING)
  CP $3C
  JP NZ,REFUSE
  CALL FOR_REAL
  JP KILL_TARGET

; SWIM, in the fast black river: asleep, and dead
;
; "as soon as you touch the river you fall asleep and gently float away.",
; "time passes..." for the player, and KILL. The drinking of its water ends the
; same way, from ASLEEP_AND_DEAD.
SWIM_BLACK_RIVER:
  CALL FOR_REAL
  LD HL,MSG_AS_SOON_AS_TOUCH
; This entry point is used by the routine at DRINK_BLACK_WATER.
ASLEEP_AND_DEAD:
  CALL RUN_MESSAGE_HL
  LD A,(ACTING)
  PUSH AF
  AND A
  LD HL,MSG_TIME_PASSES
  CALL Z,RUN_MESSAGE_HL
  POP AF
  JP KILL

; The black water's own DRINK: asleep, and dead
;
; "... fall asleep." and the drinker is killed through the end of
; SWIM_BLACK_RIVER.
DRINK_BLACK_WATER:
  CALL FOR_REAL
  LD HL,MSG_FALL_ASLEEP
  JR ASLEEP_AND_DEAD

; The mountains' side door takes the small curious key
;
; Each lockable door carries its own LOCK WITH and UNLOCK WITH, naming the key
; that fits in B: the side door the small curious key (2), the red door the red
; key (15), the heavy rock door the large key (4). Another of those keys "does
; not fit this lock."; anything else cannot be done at all. The round green
; door and the trap door go straight to NO_KEY_FITS: nothing opens them with a
; key.
SIDE_DOOR_KEY:
  LD B,$02
  JR KEY_FITS

; The red door takes the red key
RED_DOOR_KEY:
  LD B,$0F
  JR KEY_FITS

; The heavy rock door takes the large key
ROCK_DOOR_KEY:
  LD B,$04
; This entry point is used by the routines at SIDE_DOOR_KEY and RED_DOOR_KEY.
KEY_FITS:
  LD A,(INSTRUMENT)       ; The key that fits: LOCK or UNLOCK
  CP B                    ;
  JR NZ,ROCK_DOOR_KEY_0   ;
  LD A,(ACTION)           ;
  CP $25                  ;
  JP Z,DO_LOCK            ;
  JP DO_UNLOCK            ;
ROCK_DOOR_KEY_0:
  CP $02                  ; Another key: it does not fit. Anything else: cannot
  JR Z,NO_KEY_FITS        ; be done
  CP $04                  ;
  JR Z,NO_KEY_FITS        ;
  CP $0F                  ;
  JP NZ,CANNOT_DO         ;

; "the ... does not fit this lock."
;
; Used by the routine at ROCK_DOOR_KEY.
NO_KEY_FITS:
  LD HL,MSG_DO_E_S_NOT
  JP RUN_MESSAGE_HL

; After the side door is unlocked, it opens
SIDE_DOOR_UNLOCKED:
  CALL ONLY_IF_DONE
  LD IX,(TARGET_RECORD)
  JP OPEN_IT

; The crack's own OPEN: only from the dark stuffy passage, location 15
OPEN_CRACK:
  LD IX,(ACTOR)
  LD A,(IX+$10)
  CP $0F
  JP NZ,REFUSE
  JP DO_OPEN

; After the spider web is struck: the spiders start mending it
;
; The web's record has this under key 0 straight after its handler for action
; 11, STRIKE WITH, so it runs whenever that does (see DO_ACTION). If the blow
; left the web broken -- flag bit 3 -- it can now be seen through (bit 5),
; "some spiders start mending the broken web.", and timer 1 is started: two
; turns later the web is whole again.
WEB_BROKEN:
  LD IX,(TARGET_RECORD)   ; Not broken: nothing
  BIT 3,(IX+$07)          ;
  RET Z                   ;
  SET 5,(IX+$07)          ; It can be seen through now
  LD A,(TIMER1)           ; Start timer 1
  LD (TIMER1_COUNT),A     ;
  LD HL,MSG_SOME_SPIDER_S_START ; "some spiders start mending the broken web."
  JP RUN_MESSAGE_HL             ;

; WEAR, carried by the ring
;
; The wearer is invisible -- flag bit 7 clear -- and a quarter as strong, the
; ring is out of sight too, and timer 6 is set to take it off again in 2 to 10
; turns (see TIMERS).
WEAR_RING:
  CALL FOR_REAL
  LD IY,(ACTOR)              ; Invisible, and weaker
  LD IX,VALUABLE_GOLDEN_RING ;
  RES 7,(IY+$07)             ;
  SRL (IY+$05)               ;
  SRL (IY+$05)               ;
  RES 7,(IX+$07)          ; The ring, out of sight on the wearer
  LD A,(ACTING)           ;
  LD (IX+$01),A           ;
  LD A,$08                ; Off again in 2 to 10 turns
  CALL RANDOM_POSITIVE    ;
  ADD A,$02               ;
  LD (TIMER6_COUNT),A     ;
  RET                     ;

; TAKE OFF, carried by the ring
;
; Used by the routine at RING_CHECK.
;
; Not if it is not being worn ("you are not wearing the ..."). Visible again,
; four times as strong, and the timer stopped.
TAKE_OFF_RING:
  LD IX,(ACTOR)
  LD IY,VALUABLE_GOLDEN_RING
  BIT 7,(IY+$07)          ; Not worn: refused
  LD HL,MSG_NOT_WEAR_I_N  ;
  JP NZ,RUN_MESSAGE_HL    ;
  CALL FOR_REAL           ; The test ends here
  SET 7,(IY+$07)          ; Seen again, and as strong as before; the timer
  SET 7,(IX+$07)          ; stopped
  SLA (IX+$05)            ;
  SLA (IX+$05)            ;
  SUB A                   ;
  LD (TIMER6_COUNT),A     ;
  RET                     ;

; CAPTURE
;
; Only a character can be captured, and not by its own side. The wood elf and
; the butler take the captive to the elvenking's dark dungeon, location 31;
; anyone else -- the goblins -- to the goblins' dungeon, location 13. Already
; there, it is refused. The captive goes with everything it carries; a captured
; player is shown the new place, if it can be seen. ACTION_TABLE's key-0 record
; after this runs NOTE_LIGHT.
DO_CAPTURE:
  LD IX,(TARGET_RECORD)   ; Not its own side
  LD A,(IX+$04)           ;
  AND $70                 ;
  PUSH IX                 ;
  LD IX,(ACTOR)           ;
  AND (IX+$04)            ;
  POP IX                  ;
  JP NZ,REFUSE            ;
  BIT 6,(IX+$07)          ; Only a character
  JP Z,REFUSE             ;
  LD A,(ACTING)           ; The elves' dungeon, or the goblins'
  LD B,$1F                ;
  CP $40                  ;
  JR Z,DO_CAPTURE_0       ;
  CP $42                  ;
  JR Z,DO_CAPTURE_0       ;
  LD B,$0D                ;
DO_CAPTURE_0:
  LD A,(ACTOR_AT)         ; Already there: refused
  CP B                    ;
  JP Z,REFUSE             ;
  CALL FOR_REAL           ; The test ends here
  LD IX,(TARGET_RECORD)   ; There now, held by nothing, with all it carries
  LD (IX+$10),B           ;
  LD (IX+$01),$FF         ;
  LD A,(TARGET)           ;
  CALL MOVE_CONTENTS      ;
  LD A,(TARGET)           ; Not the player: done
  CP $00                  ;
  RET NZ                  ;
  LD (ACTING),A           ; The player is the subject again
  LD HL,PLAYER            ;
  LD (ACTOR),HL           ;
  CALL TOO_DARK            ; Show the player the dungeon, if it can be seen
  RET C                    ;
  LD A,B                   ;
  LD HL,MSG_IN             ;
  JP DESCRIBE_WITH_OPENING ;

; After a goblin is attacked: a dead goblin comes back
;
; Killing a goblin does not get rid of it. "the ... falls down a hole and
; vanishes.", it is alive again, back in its slot in CHARACTERS and in its own
; place, named as it was, from GOBLIN_HOMES; and if that is where the player
; is, "another goblin enters.".
GOBLIN_RETURNS:
  LD IX,(TARGET_RECORD)   ; Not dead: nothing
  BIT 3,(IX+$07)          ;
  RET Z                   ;
  RES 3,(IX+$07)          ; Alive again
  LD DE,$0006             ; Its entry in GOBLIN_HOMES
  LD IY,GOBLIN_HOMES      ;
  LD A,(TARGET)           ;
GOBLIN_RETURNS_0:
  CP (IY+$00)             ;
  JR Z,GOBLIN_RETURNS_1   ;
  ADD IY,DE               ;
  JR GOBLIN_RETURNS_0     ;
GOBLIN_RETURNS_1:
  PUSH IY                 ; Back in its slot
  POP HL                  ;
  INC HL                  ;
  LD E,(HL)               ;
  INC HL                  ;
  LD D,(HL)               ;
  LD (DE),A               ;
  INC HL                  ; Back in its place, and its name as it was
  LD A,(HL)               ;
  LD (IX+$10),A           ;
  INC HL                  ;
  LD A,(HL)               ;
  LD (IX+$0A),A           ;
  INC HL                  ;
  LD A,(HL)               ;
  LD (IX+$0B),A           ;
  LD HL,MSG_FALL_DOWN_A_HOLE ; "the ... falls down a hole and vanishes."
  CALL RUN_MESSAGE_HL        ;
  LD A,(PLAYER_WHERE)     ; Where the player is: "another goblin enters."
  CP B                    ;
  RET NZ                  ;
  LD DE,$005E             ;
  CALL PRINT_WORD_DE      ;
  LD DE,$02E2             ;
  CALL PRINT_WORD_DE      ;
  LD HL,MSG_ENTER_B       ;
  JP RUN_MESSAGE_HL       ;

; Where each goblin comes back to
;
; Six bytes for each of the six: the goblin, its slot in CHARACTERS, the
; location it comes back in, and the adjective its name had.
GOBLIN_HOMES:
  DEFB $3D,$18,$CB,$0F,$6A,$04
  DEFB $45,$1F,$CB,$3A,$37,$03
  DEFB $49,$2D,$CB,$12,$61,$03
  DEFB $4A,$34,$CB,$38,$34,$04
  DEFB $4B,$26,$CB,$40,$41,$07
  DEFB $4C,$3B,$CB,$10,$B6,$01

; The goblins' door's own OPEN
;
; Only from location 16, the big goblins' cavern, where it is opened as any
; door is (through DO_OPEN); then timer 3 shuts it again two turns later. From
; its other side, the goblins' dungeon, it will not open.
GOBLINS_DOOR_OPENED:
  LD IX,(ACTOR)           ; Not in the cavern: refused
  LD A,(IX+$10)           ;
  CP $10                  ;
  JP NZ,REFUSE            ;
  CALL DO_OPEN            ; Open it
  CALL ONLY_IF_DONE       ;
  LD A,(TIMER3)           ; Start timer 3
  LD (TIMER3_COUNT),A     ;
  RET

; Timer 3: the goblins' door shuts
;
; Clears bit 5 of the goblins' door's flags -- the bit that lets it be seen
; through, which a door has while it is open.
GOBLINS_DOOR_SHUTS:
  LD HL,GOBLINS_DOOR_FLAGS
  RES 5,(HL)
  RET

; Given something: "thank you", mostly
;
; Gandalf, Thorin, Elrond, the wood elf and the butler all keep this for GIVE
; TO: mostly "thank you", sometimes "what do you expect me to do with this ?".
GIVEN_SOMETHING:
  CALL FOR_REAL
  LD A,$0A
  CALL RANDOM_POSITIVE
  LD HL,MSG_WHAT_DO_YOU_EXPECT
  CP $08
  JP NC,SAYS
  LD HL,MSG_THANK_YOU
  JP SAYS

; Gandalf: "what's this ?"
GANDALF_WHATS_THIS:
  CALL FOR_REAL
  LD HL,MSG_WHAT_S_THIS
  JP SAYS

; Gandalf: "you are doing a great job", "hurry up" or "hello", at random
GANDALF_CHATTER:
  CALL FOR_REAL
  LD A,$02
  CALL RANDOM_POSITIVE
  LD HL,MSG_YOU_ARE_DO_A
  CP $00
  JP Z,SAYS
  LD HL,MSG_HURRY_UP
  CP $01
  JP Z,SAYS
  LD HL,MSG_HELLO
  JP SAYS

; Thorin: "this was thrains key"
THORIN_THRAINS_KEY:
  CALL FOR_REAL
  LD HL,MSG_THIS_WAS_THRAINS_KEY
  JP SAYS

; Elrond, where the player is: "hello"
ELROND_HELLO:
  LD A,(ACTOR_AT)
  LD HL,PLAYER_AT
  CP (HL)
  RET NZ
  CALL FOR_REAL
  LD HL,MSG_HELLO
  JP SAYS

; Unreached: an OPEN for the wood elf alone
;
; Reads as: unless the actor is the wood elf ($40), refuse; otherwise DO_OPEN.
; No object's record carries it.
UNREACHED_ELF_OPEN:
  DEFB $3A,$EA,$B6,$FE,$40,$C2,$76,$9F
  DEFB $C3,$0E,$91

; CLIMB OUT OF
;
; Only out of what holds the actor, and not if it is shut ("the ... is
; closed.").
DO_CLIMB_OUT:
  LD IY,(ACTOR)           ; Not in it: refused
  LD A,(TARGET)           ;
  CP (IY+$01)             ;
  JP NZ,REFUSE            ;
  CALL GET_OBJECT         ; Shut: "the ... is closed."
  CALL IS_SHUT            ;
  JP Z,SAY_STATE          ;
  CALL FOR_REAL           ; The test ends here
  LD (IY+$01),$FF         ; Out
  RET

; CLIMB INTO, carried by the barrel, the boat and the chest
;
; Not what the actor is in already, and only what it can reach. If the actor is
; carrying it, it is put down first. It must be open, and big enough for the
; actor and all it carries, unless its size is $FF ("the ... is too big.").
DO_CLIMB_INTO:
  LD IY,(ACTOR)           ; Already in it: refused
  LD A,(TARGET)           ;
  CP (IY+$01)             ;
  JP Z,REFUSE             ;
  LD IY,(TARGET_RECORD)   ; Out of reach: refused
  CALL IN_REACH           ;
  JP Z,REFUSE             ;
  LD A,(TARGET)           ; Carrying it? Put it down first
DO_CLIMB_INTO_0:
  CALL GET_OBJECT         ;
  LD A,(IX+$01)           ;
  CP $FF                  ;
  JR Z,DO_CLIMB_INTO_1    ;
  LD A,(ACTING)           ;
  CP (IX+$01)             ;
  LD A,(IX+$01)           ;
  JR NZ,DO_CLIMB_INTO_0   ;
  LD IX,(TARGET_RECORD)   ;
  LD (IX+$01),$FF         ;
DO_CLIMB_INTO_1:
  LD IY,(ACTOR)           ; The actor's size, with its load
  LD A,(ACTING)           ;
  CALL SIZE_HELD          ;
  ADD A,(IY+$02)          ;
  JR C,DO_CLIMB_INTO_2    ;
  LD A,$FF                ;
DO_CLIMB_INTO_2:
  LD B,A                  ;
  LD IX,(TARGET_RECORD)   ; Shut: "the ... is closed."
  CALL IS_SHUT            ;
  JP Z,SAY_STATE          ;
  LD A,(IX+$02)           ; Too small: "the ... is too big."
  CP $FF                  ;
  JR Z,DO_CLIMB_INTO_3    ;
  SUB B                   ;
  LD HL,MSG_TOO_BIG       ;
  JP NC,RUN_MESSAGE_HL    ;
DO_CLIMB_INTO_3:
  CALL FOR_REAL           ; The test ends here
  LD A,(TARGET)           ; In
  LD (IY+$01),A           ;
  RET

; Is this thing shut?
;
; Used by the routines at LOOK_THROUGH, DO_CLOSE, DO_EMPTY, DO_CLIMB_OUT and
; DO_CLIMB_INTO.
;
; Flag bit 5 is being open to be seen into, and so to be got out of; Z if it is
; clear. A = 5, CLOSED, for SAY_STATE.
;
; I:IX The record
; O:F Z if shut
IS_SHUT:
  BIT 5,(IX+$07)
  LD A,$05
  RET

; The warg, where the player is: "the vicious warg runs around you and howls"
WARG_HOWLS:
  CALL FOR_REAL
  LD HL,VICIOUS_WARG_WHERE
  LD A,(PLAYER_WHERE)
  CP (HL)
  RET NZ
  LD HL,MSG_THE_VICIOUS_WARG_RUN
  JP NARRATE_LINE

; After something is thrown through the trap door
;
; The large trap door's record has this under key 0 after its handler for
; action 44, THROW THROUGH. If what went through was the barrel, and it has
; landed in location 33, the forest river, timer 0 is set going: two turns
; later BARREL_REACHES_LAKE takes it, and anyone inside, on to the long lake.
BARREL_THROWN:
  LD A,(TARGET)           ; Not the barrel: nothing
  CP $13                  ;
  RET NZ                  ;
  CALL ONLY_IF_DONE       ; Not yet worked out
  LD IX,BARREL            ; Not in the forest river: nothing
  LD A,(IX+$10)           ;
  CP $21                  ;
  RET NZ                  ;
  LD A,$02                ; Start timer 0 at two turns
  LD (TIMER0_COUNT),A     ;
  RET

; Timer 0: the barrel is thrown up on the long lake
;
; Two turns after it is started, the barrel goes to location 34, the long lake,
; and anything in it goes with it -- the player too, who is told so and arrives
; there. Then it is emptied, with printing off, so that what spills is not
; reported; and the wine is put back into a barrel in location 32, the
; elvenking's cellar.
BARREL_REACHES_LAKE:
  SUB A                   ; Only one timer fires in a turn
  LD (TIMER_FIRED),A      ;
  LD A,(PLAYER_HOLDER)          ; In the barrel ($13)? "you are thrown onto the
  CP $13                        ; bank of the long lake."
  LD HL,MSG_YOU_ARE_THROWN_ONTO ;
  CALL Z,RUN_MESSAGE_HL         ;
  LD A,$22                ; The barrel is at location 34 now
  LD (BARREL_WHERE),A     ;
  LD B,A                  ; ... and so is everything in it
  LD A,$13                ;
  CALL MOVE_CONTENTS      ;
  LD IX,BARREL            ; The barrel: at the lake; flag bit 5 (seen into)
  LD (IX+$10),$20         ; off, bit 2 on
  RES 5,(IX+$07)          ;
  SET 2,(IX+$07)          ;
  SUB A                   ; Empty it with printing off
  LD (PRINTING_ON),A      ;
  LD A,$13                ;
  CALL EMPTY_OUT          ;
  LD A,$01                ;
  LD (PRINTING_ON),A      ;
  LD IY,WINE              ; The wine: back in location 32, held by the barrel
  LD (IY+$10),$20         ;
  LD (IY+$01),$13         ;
  RET                     ;

; Thorin, where the player is but cannot be seen: "where's the thief ?"
;
; That is, while the player wears the ring.
THORIN_WHERES_THIEF:
  LD A,(ACTOR_AT)
  LD HL,PLAYER_AT
  CP (HL)
  RET NZ
  LD A,(PLAYER_FLAGS)
  BIT 7,A
  RET NZ
  CALL FOR_REAL
  LD HL,MSG_WHERE_S_THE_THIEF
  JP SAYS

; Thorin, at random: waits, sings about gold, or says "hurry up" or "get us out
; of this one, thief !"
;
; Quite often -- four of the nine values RANDOM_POSITIVE gives here -- nothing
; at all.
THORIN_CHATTER:
  CALL FOR_REAL
  LD A,$08
  CALL RANDOM_POSITIVE
  CP $05
  RET NC
  CP $03
  LD HL,MSG_THORIN_WAIT
  JP NC,NARRATE_LINE
  LD HL,MSG_GET_US_OUT_OF
  JP Z,SAYS
  LD HL,MSG_THORIN_SIT_DOWN_AND
  CP $00
  JP Z,NARRATE_LINE
  LD HL,MSG_HURRY_UP
  JP SAYS

; The trap door's own OPEN and CLOSE: only from the elvenking's cellar
;
; Anywhere else, "you cannot reach the ...".
TRAP_DOOR_OPEN_CLOSE:
  LD IX,(ACTOR)              ; Not in the cellar: out of reach
  LD A,(IX+$10)              ;
  CP $20                     ;
  LD HL,MSG_YOU_CANNOT_REACH ;
  JP NZ,RUN_MESSAGE_HL       ;
  LD A,(ACTION)           ; Otherwise the ordinary CLOSE or OPEN
  CP $0C                  ;
  JP Z,DO_CLOSE           ;
  JP DO_OPEN              ;

; The dragon follows the player through its mountain
;
; In the front gate, the lower halls or on the lonely mountain (locations 39,
; 41 and 44), the dragon goes to wherever the player is, and "... enters.".
DRAGON_FOLLOWS:
  LD A,(PLAYER_WHERE)
  CP $27
  JR Z,DRAGON_FOLLOWS_0
  CP $2C
  JR Z,DRAGON_FOLLOWS_0
  CP $29
  RET NZ
DRAGON_FOLLOWS_0:
  CALL FOR_REAL
  LD A,(PLAYER_WHERE)
  LD HL,RED_GOLDEN_DRAGON_WHERE
  CP (HL)
  RET Z
  LD (HL),A
  LD A,$01
  LD (PRINTING_ON),A
  LD HL,RED_GOLDEN_DRAGON_NAME
  PUSH HL
  LD HL,MSG_ENTER
; This entry point is used by the routines at DRAGON_THREATENS and
; DRAGON_HUNTS.
DRAGON_SAYS:
  CALL RUN_MESSAGE_HL
  RET

; The dragon, where the player is: "prepare to die"
;
; "well thief your cunning has failed you this time. prepare to die " -- or, to
; a player it cannot see, "i may not be able to see you thief but i can still
; burn you...".
DRAGON_THREATENS:
  LD A,(PLAYER_WHERE)
  LD HL,ACTOR_AT
  CP (HL)
  RET NZ
  CALL FOR_REAL
  LD A,(PLAYER_FLAGS)
  AND $80
  LD HL,MSG_THE_DRAGON_SAY_I
  JR Z,DRAGON_THREATENS_0
  LD HL,MSG_THE_DRAGON_SAY_WELL
DRAGON_THREATENS_0:
  JR DRAGON_SAYS

; Once the treasure is gone from its hall, the dragon hunts the player
;
; While the treasure is still in the lower halls, nothing. Once it is not,
; wherever the player is in the open -- a lit place -- four times in five "in
; the distance you see the shape of a monstrous dragon flying after you.", and
; otherwise "the dragon descends and in a terrific spout of flames burns you to
; a crisp." and PLAYER_DIES.
DRAGON_HUNTS:
  LD A,(VALUABLE_TREASURE_WHERE)
  CP $29
  RET Z
  LD A,(PLAYER_WHERE)
  CALL GET_ROOM
  BIT 7,(IX+$00)
  RET Z
  CALL FOR_REAL
  LD A,$01
  LD (PRINTING_ON),A
  LD HL,MSG_IN_THE_DISTANCE_YOU
  LD A,$64
  CALL RANDOM_POSITIVE
  CP $50
  JR C,DRAGON_SAYS
  LD HL,MSG_THE_DRAGON_DESCENDS_AND
  CALL RUN_MESSAGE_HL
  JP PLAYER_DIES

; Unreached: wipe the exit through the first object
;
; Reads as: find the exit through the first object (EXIT_VIA) and, if there is
; one, set its three bytes to zero -- the way the hidden roads are shut.
; Nothing calls it.
UNREACHED_WIPE_EXIT:
  DEFB $CD,$25,$9F,$FE,$FF,$C8,$97,$DD
  DEFB $36,$00,$00,$DD,$36,$01,$00,$DD
  DEFB $36,$02,$00,$C9

; The magic door's own EXAMINE
;
; Anyone who can be seen -- flag bit 7 -- sees "nothing special here." Anyone
; who cannot, sets timer 5 going: "the magic door warns of elves approaching.",
; and three turns later it opens for an elf to sweep past (MAGIC_DOOR_OPENS).
MAGIC_DOOR_EXAMINED:
  CALL FOR_REAL
  LD IX,(ACTOR)                      ; Visible? "you see nothing special here."
  BIT 7,(IX+$07)                     ;
  LD HL,MSG_SEE_NOTHING_SPECIAL_HERE ;
  JP NZ,RUN_MESSAGE_HL               ;
  LD A,(TIMER5)           ; Start timer 5
  LD (TIMER5_COUNT),A     ;
  LD HL,MSG_THE_MAGIC_DOOR_WARN ; "the magic door warns of elves approaching."
  JP RUN_MESSAGE_HL             ;

; After Thorin is attacked: if he is dead, the curious key shatters
;
; The small curious key opens the mountain's side door, and it is Thorin's.
; Killing him breaks it -- "the small curious key shatters." where the player
; can see -- which leaves the side door locked for good.
THORIN_KILLED:
  LD HL,THORIN_FLAGS      ; Thorin not dead: nothing
  BIT 3,(HL)              ;
  RET Z                   ;
  CALL ONLY_IF_DONE       ; Only if it really happened
  LD IX,SMALL_CURIOUS_KEY ; The key is broken
  SET 3,(IX+$07)          ;
  LD A,$02                ;
  CALL BROKEN_OR_DEAD     ;
  LD A,$02                        ; "the small curious key shatters.", where
  LD IY,PLAYER                    ; the player sees it
  CALL ACTOR_IN_REACH             ;
  RET Z                           ;
  LD HL,MSG_THE_SMALL_CURIOUS_KEY ;
  JP RUN_MESSAGE_HL               ;

; The window's own OPEN and CLOSE: out of the player's reach unless carried
;
; The player can only reach the window while held by something -- carried, as
; the guides have it, by Thorin -- and otherwise "you cannot reach the ...".
; Characters can open and close it as any door.
WINDOW_OPEN_CLOSE:
  LD A,(ACTING)              ; The player, held by nothing: "you cannot reach
  CP $00                     ; the ..."
  JR NZ,WINDOW_OPEN_CLOSE_0  ;
  LD A,(PLAYER_HOLDER)       ;
  LD HL,MSG_YOU_CANNOT_REACH ;
  CP $FF                     ;
  JP Z,RUN_MESSAGE_HL        ;
  JP REFUSE                  ;
WINDOW_OPEN_CLOSE_0:
  LD A,(ACTION)           ; Otherwise the ordinary CLOSE or OPEN
  CP $0C                  ;
  JP Z,DO_CLOSE           ;
  CP $10                  ;
  JP Z,DO_OPEN            ;
  RET                     ;

; The window's GO THROUGH, STRIKE WITH and LOOK THROUGH, with the same reach
WINDOW_OTHERS:
  LD A,(ACTING)              ; The player, held by nothing: out of reach
  CP $00                     ;
  JP NZ,WINDOW_OTHERS_0      ;
  LD A,(PLAYER_HOLDER)       ;
  CP $FF                     ;
  LD HL,MSG_YOU_CANNOT_REACH ;
  JP Z,RUN_MESSAGE_HL        ;
WINDOW_OTHERS_0:
  LD A,(ACTION)           ; Otherwise GO THROUGH, STRIKE WITH or LOOK THROUGH
  CP $1E                  ; as usual
  JP Z,GO_THROUGH         ;
  CP $0B                  ;
  JP Z,DO_STRIKE          ;
  CP $18                  ;
  JP Z,LOOK_THROUGH       ;
  RET                     ;

; Timer 4: sinking into the deep bog
;
; Timer 4's routine for both its warning and its end. Standing in location 29,
; the deep bog, stops the timer; either way "you are slowly sinking into the
; bog", and if the timer has stopped, whether by running out or by the player
; being in the bog, PLAYER_DIES.
SINKING_IN_BOG:
  LD A,(PLAYER_WHERE)     ; In the bog? Stop the timer
  CP $1D                  ;
  JR NZ,SINKING_IN_BOG_0  ;
  SUB A                   ;
  LD (TIMER4_COUNT),A     ;
SINKING_IN_BOG_0:
  LD HL,MSG_SLOWLY_SINK_INTO_THE ; "you are slowly sinking into the bog."
  CALL RUN_MESSAGE_HL            ;
  LD A,(TIMER4_COUNT)     ; Stopped: dead
  CP $00                  ;
  RET NZ                  ;
  JP PLAYER_DIES          ;

; The curious map's own EXAMINE: Elrond reads it
;
; Anyone but Elrond examining the map gets the ordinary EXAMINE. Elrond puts
; back the road NEW_GAME_CHOICES shut and tells the way along it: "go ... from
; the ... to get to the ...", with the direction and the two places' names. The
; entry is found through the operand of the LD IY at SHUT_ROAD, which
; NEW_GAME_CHOICES writes.
;
; The put-back is skipped if ROAD_OPEN is not zero, but nothing ever makes it
; so: NEW_GAME_CHOICES clears it and no instruction writes it otherwise (the
; only other F1 B6 in memory is in the picture code, where it is POP AF and
; then OR (HL)). So the road is put back again, to the same three bytes, every
; time Elrond reads the map. Watched: the treeless opening's west exit, wiped
; to zeros by NEW_GAME_CHOICES, came back as $04 $00 $14, written by the LD
; (HL),A in the loop above, when Elrond examined the map, and ROAD_OPEN was
; still 0 afterwards.
ELROND_READS_MAP:
  LD A,(ACTING)           ; Not Elrond: the ordinary EXAMINE
  CP $41                  ;
  JP NZ,DO_EXAMINE        ;
  CALL FOR_REAL           ; Not yet worked out
SHUT_ROAD:
  LD IY,$0000             ; IY = the road that was shut; HL = its exit in the
  LD L,(IY+$01)           ; room record
  LD H,(IY+$02)           ;
  LD A,(ROAD_OPEN)         ; Already put back? Just say the way -- never taken:
  CP $00                   ; nothing sets ROAD_OPEN
  JR NZ,ELROND_READS_MAP_1 ;
  LD B,$03                ; Put the exit back
ELROND_READS_MAP_0:
  LD A,(IY+$03)           ;
  LD (HL),A               ;
  INC HL                  ;
  INC IY                  ;
  DJNZ ELROND_READS_MAP_0 ;
  LD IY,(SHUT_ROAD+$0002) ; IY = the road again
ELROND_READS_MAP_1:
  LD A,(IY+$05)           ; The destination's name, from its room record, on
  CALL GET_ROOM           ; the stack
  INC IX                  ;
  INC IX                  ;
  PUSH IX                 ;
  LD A,(IY+$00)           ; And the location's
  CALL GET_ROOM           ;
  INC IX                  ;
  INC IX                  ;
  PUSH IX                 ;
  LD A,(IY+$03)           ; And the direction's word
  CALL DIRECTION_WORD     ;
  PUSH DE                  ; "go ... from the ... to get to the ..."
  LD HL,MSG_GO_FROM_TO_GET ;
  JP SAYS                  ;

; THROW ACROSS, carried by the rope
;
; Across a river: "it sails across and" -- and if the boat is on the far bank,
; half the time it "lands in the boat.", tying the boat to it, and otherwise
; falls short or slides out again. With no boat there it lands on the other
; side, half the time, or falls short.
THROW_ROPE_ACROSS:
  LD A,(INSTRUMENT)       ; Across what? A river's way over
  CALL EXIT_VIA_A         ;
  CP $FF                  ;
  JP Z,REFUSE             ;
  CALL FOR_REAL           ; The test ends here
  LD HL,MSG_IT_SAIL_ACROSS_AND ; "it sails across and"
  CALL RUN_MESSAGE_HL          ;
  LD A,(WOODEN_BOAT_WHERE)  ; Is the boat on the far bank?
  CP (IX+$02)               ;
  JR NZ,THROW_ROPE_ACROSS_1 ;
  CALL HALF_THE_TIME            ; Then half the time into it; if not, short or
  JR C,THROW_ROPE_ACROSS_0      ; out again
  LD HL,MSG_FALL_JUST_SHORT_OF  ;
  CALL HALF_THE_TIME            ;
  JR C,THROW_ROPE_ACROSS_2      ;
  LD HL,MSG_BUT_SLIDE_OUT_AGAIN ;
  JR THROW_ROPE_ACROSS_2        ;
THROW_ROPE_ACROSS_0:
  LD A,$12                  ; In the boat: the boat is tied to the rope
  LD (WOODEN_BOAT_HOLDER),A ;
  LD HL,MSG_LAND_S_IN_THE   ;
  JR THROW_ROPE_ACROSS_2    ;
THROW_ROPE_ACROSS_1:
  LD HL,MSG_FALL_JUST_SHORT_OF ; No boat: half the time short
  CALL HALF_THE_TIME           ;
  JR C,THROW_ROPE_ACROSS_2     ;
  LD A,(IX+$02)           ; ...otherwise over, onto the far bank
  LD IX,(TARGET_RECORD)   ;
  LD (IX+$10),A           ;
  LD (IX+$01),$FF         ;
  LD A,(TARGET)           ;
  CALL MOVE_CONTENTS      ;
  LD HL,MSG_LAND_S_ON_THE ;
THROW_ROPE_ACROSS_2:
  JP RUN_MESSAGE_HL       ; Say which

; Carry set half the time
;
; Used by the routine at THROW_ROPE_ACROSS.
HALF_THE_TIME:
  LD A,$64
  CALL RANDOM_POSITIVE
  CP $32
  RET

; PULL, carried by the rope
;
; With the boat tied to it: "the boat glides across the river and lands on this
; side.", from one bank to the other, and it is let go. BOAT_CROSSES is the
; crossing itself, which BOAT_BOARDED uses too.
PULL_ROPE:
  CALL FOR_REAL             ; Only with the boat tied to it
  LD A,(WOODEN_BOAT_HOLDER) ;
  CP $12                    ;
  RET NZ                    ;
  LD HL,MSG_THE_BOAT_GLIDES_ACROSS ; "the boat glides across the river and
                                   ; lands on this side."
; This entry point is used by the routine at BOAT_BOARDED.
BOAT_CROSSES:
  CALL RUN_MESSAGE_HL     ; The crossing: the message...
  LD A,(WOODEN_BOAT_WHERE)  ; ...and the boat, with whoever is in it, to the
  CP $42                    ; other bank, let go
  LD A,$42                  ;
  JR NZ,PULL_ROPE_0         ;
  LD A,$43                  ;
PULL_ROPE_0:
  LD (WOODEN_BOAT_WHERE),A  ;
  LD B,A                    ;
  LD A,$FF                  ;
  LD (WOODEN_BOAT_HOLDER),A ;
  LD A,$29                  ;
  JP MOVE_CONTENTS          ;

; After climbing into the boat: across
;
; "with a lurch the boat glides across the river and lands on the other side.",
; and whoever is in it goes too.
BOAT_BOARDED:
  CALL ONLY_IF_DONE       ; Only if it really happened, and for the player
  LD A,(ACTING)           ;
  AND A                   ;
  RET NZ                  ;
  LD HL,MSG_WITH_A_LURCH_THE ; "with a lurch..." and across
  JR BOAT_CROSSES            ;

; Bard: an order given to him becomes a step of his own script
;
; The order is taken and parsed, and its action and objects are written into
; the script step at BARD_ORDER_STEP -- with opcode $42, an action that an
; order cannot interrupt -- so that Bard goes on trying it, turn after turn,
; until it works. Those are the three script bytes that DO_SAVE carries in the
; variables block.
BARD_TAKES_ORDER:
  LD A,(ORDER_WAITING)
  CP $01
  RET NZ
  SUB A
  LD (ORDER_WAITING),A
  INC A
  CALL TAKE_ORDER
  RET Z
  SUB A
  LD (SUCCEEDED),A
  LD A,(PARSED_ACTION)
  LD (BARD_ORDER_ACTION),A
  LD BC,(TARGET)
  LD (BARD_ORDER_OBJECTS),BC
BARD_SETS_STEP:
  LD A,$42
  LD (BARD_ORDER_STEP),A
  RET

; Gollum asks the player his riddle
;
; One of Gollum's script routines. Only where the player is, and only if the
; player can be seen: the riddle NEW_GAME_CHOICES chose is said, and
; RIDDLE_ASKED set so that the answer is expected.
GOLLUM_ASKS:
  LD A,(GOLLUM_WHERE)     ; Gollum not where the player is? Nothing
  LD HL,PLAYER_AT         ;
  CP (HL)                 ;
  RET NZ                  ;
  LD HL,PLAYER_FLAGS      ; The player not to be seen? Nothing
  BIT 7,(HL)              ;
  RET Z                   ;
  CALL FOR_REAL           ; Ask the riddle
  LD HL,(RIDDLE)          ;
  INC HL                  ;
  INC HL                  ;
  LD E,(HL)               ;
  INC HL                  ;
  LD D,(HL)               ;
  PUSH DE                 ;
  POP HL                  ;
  CALL SAYS               ;
  LD A,$01                ; An answer is expected
  LD (RIDDLE_ASKED),A     ;
  RET

; Gollum hears the answer to his riddle
;
; The answer has to be given to Gollum as an order -- said to him, in the
; ORDERS slot he takes his turn from. It is right if the answer's word
; reference appears anywhere in it; with no answer, or a wrong one, "someone
; strangles you from behind." and PLAYER_DIES.
GOLLUM_HEARS_ANSWER:
  CALL FOR_REAL           ; No longer expecting an answer
  SUB A                   ;
  LD (RIDDLE_ASKED),A     ;
  CALL TAKE_ORDER            ; Nothing said to him: strangled
  JR Z,GOLLUM_HEARS_ANSWER_1 ;
  LD BC,$0018                 ; Look through what was said for the answer word
  LD DE,(RIDDLE)              ;
  LD A,(DE)                   ;
GOLLUM_HEARS_ANSWER_0:
  CPIR                        ;
  JR NZ,GOLLUM_HEARS_ANSWER_1 ;
  INC DE                      ;
  LD A,(DE)                   ;
  DEC DE                      ;
  CP (HL)                     ;
  JR NZ,GOLLUM_HEARS_ANSWER_0 ;
  RET                         ;
GOLLUM_HEARS_ANSWER_1:
  CALL FOR_REAL                  ; "someone strangles you from behind.", and
  LD A,$01                       ; dead
  LD (PRINTING_ON),A             ;
  LD HL,MSG_SOMEONE_STRANGLE_YOU ;
  CALL RUN_MESSAGE_HL            ;
  JP PLAYER_DIES                 ;

; Gollum, where the player is: "what has it got in its pockets ?"
;
; Or, depending on who has the ring, "my birthday present -- how did we lose
; it. my precious"; the exact choice is not yet worked out.
GOLLUM_POCKETS:
  LD A,(GOLLUM_WHERE)
  LD HL,PLAYER_AT
  CP (HL)
  RET NZ
  CALL FOR_REAL
  LD HL,MSG_WHAT_HAS_IT_GOT
  LD A,$08
  CALL RANDOM_POSITIVE
  JP NC,SAYS
  LD IX,VALUABLE_GOLDEN_RING
  LD A,$44
  CP (IX+$01)
  JP Z,SAYS
  LD HL,MSG_MY_BIRTHDAY_PRESENT_HOW
  JP SAYS

; The trolls, the four turns after: eat the player, if still there
;
; The troll eats the player (EAT, $1B) where they are both, and PLAYER_DIES.
; Anywhere else it fails, and the script pauses a turn.
TROLLS_EAT:
  LD A,(ACTOR_AT)
  LD HL,PLAYER_AT
  CP (HL)
  RET NZ
  CALL FOR_REAL
  LD A,$1B
  LD (ACTION),A
  LD A,$00
  LD (TARGET),A
  LD A,$FF
  LD (INSTRUMENT),A
  CALL REFUSE
  CALL DO_EAT
  JP PLAYER_DIES

; Dawn: the trolls turn to stone
;
; Both trolls are killed and hidden, drop what they held -- the large key among
; it -- the clearing gets its daytime description and is marked unvisited, and
; its picture is patched to show them as stone.
TROLLS_TURN_TO_STONE:
  CALL FOR_REAL
  LD A,$47
  CALL KILL
  LD A,$48
  CALL KILL
  LD HL,HIDEOUS_TROLL_FLAGS
  RES 7,(HL)
  LD HL,VICIOUS_TROLL_FLAGS
  RES 7,(HL)
  LD HL,MSG_IN_A_CLEARING_WITH
  LD (ROOM5_DESCRIPTION),HL
  LD HL,ROOM5
  RES 6,(HL)
  LD A,$47
  CALL EMPTY_OUT
  LD A,$48
  CALL EMPTY_OUT
  LD HL,MSG_DAY_DAWN
  LD A,$01
  LD (PRINTING_ON),A
  CALL RUN_MESSAGE_HL
  LD IX,PICTURE_TABLE
  LD A,$05
  CALL FIND_RECORD
  LD L,(IX+$01)
  LD H,(IX+$02)
  LD (HL),$05
  INC HL
  LD (HL),$28
  RET

; The trolls, once the player comes to their clearing: their lines
;
; Fails, and so is tried again every turn, until the player is in location 5;
; then the hideous troll and the vicious troll each say their line and the
; script moves on.
TROLLS_TALK:
  LD A,(PLAYER_AT)
  CP $05
  RET NZ
  CALL FOR_REAL
  LD A,(ACTING)
  LD HL,MSG_BLIMEY_LOOK_AT_THIS
  CP $47
  JR Z,TROLLS_TALK_0
  LD HL,MSG_YER_CAN_TRY_BUT
TROLLS_TALK_0:
  JP SAYS

; Has the player won?
;
; Used by the routine at END_OF_TURN.
;
; The first thing END_OF_TURN does. The game is won when the valuable treasure,
; object $23, is held by the wooden chest, object $25 -- byte 1 of the
; treasure's record. Then a cheering crowd of dwarves, hobbits and elves
; carries the player off into the sunset, and the game waits for a key and
; starts again, through the tail of PLAYER_DIES.
CHECK_WON:
  LD A,(VALUABLE_TREASURE_HOLDER) ; The treasure not in the chest? Play on
  CP $25                          ;
  RET NZ                          ;
  LD HL,MSG_A_C_H_E       ; "a cheering crowd of dwarves, hobbits and elves
  CALL RUN_MESSAGE_HL     ; appears..."; wait and start again
  JP WAIT_AND_RESTART     ;

; Elrond, where the player is: he gives the player lunch
;
; The lunch, if it is nowhere or Elrond has it, is made his and then given to
; the player, through DO_GIVE -- so it can be refused if the player is carrying
; too much.
ELROND_GIVES_LUNCH:
  LD A,(ACTOR_AT)
  LD HL,PLAYER_AT
  CP (HL)
  RET NZ
  LD IX,LUNCH
  LD A,(IX+$10)
  CP $00
  JR Z,ELROND_GIVES_LUNCH_0
  LD A,$41
  CP (IX+$01)
  RET NZ
ELROND_GIVES_LUNCH_0:
  CALL FOR_REAL
  LD A,(ACTOR_AT)
  LD (IX+$10),A
  LD (IX+$01),$41
  LD BC,$0026
  LD (TARGET),BC
  LD A,$1D
  LD (ACTION),A
  LD (TARGET_RECORD),IX
  LD HL,PLAYER
  LD (INSTRUMENT_RECORD),HL
  CALL REFUSE
  JP DO_GIVE

; JUMP ONTO, carried by the barrel
;
; Only down onto it, from a place with a way down to where it is: then the
; jumper is in the barrel, with it, and a player is shown the place. From
; anywhere else it is "you cannot jump onto the ... from here." -- or would be:
; where the way to it is not down, the code has JP
; NZ,MSG_CANNOT_JUMP_ONTO_FROM, which jumps into that message's bytes rather
; than printing them, apparently for LD HL,MSG_CANNOT_JUMP_ONTO_FROM and JP
; RUN_MESSAGE_HL. In a quick test, from the great halls beside the cellar, that
; path was not reached; whether anything can reach it is not worked out.
JUMP_ONTO_BARREL:
  LD IY,(TARGET_RECORD)           ; A way from here to where the barrel is? If
  LD A,(IY+$10)                   ; not, say so
  LD B,A                          ;
  CALL EXIT_TO                    ;
  CP $FF                          ;
  LD HL,MSG_CANNOT_JUMP_ONTO_FROM ;
  JP Z,RUN_MESSAGE_HL             ;
  LD A,(IX+$00)                   ; Not down: into the message bytes -- see
  CP $0A                          ; above
  JP NZ,MSG_CANNOT_JUMP_ONTO_FROM ;
  CALL FOR_REAL           ; The test ends here
  LD A,(TARGET)           ; In the barrel, and there
  LD IX,(ACTOR)           ;
  LD (IX+$01),A           ;
  CALL MOVE_CONTENTS      ;
  LD A,(ACTING)           ; For the player, describe it
  CP $00                  ;
  RET NZ                  ;
  LD A,B                  ;
  JP DESCRIBE_ROOM        ;

; Timer 1: the broken web is mended
;
; Two turns after WEB_BROKEN: clears the web's flag bits 3 (broken) and 5 (can
; be seen through), doubles its byte 5, and gives it back SPIDER as the
; adjective in its name. Not yet seen in play.
WEB_CHANGES:
  LD IX,SPIDER_WEB        ; Flags and byte 5
  RES 3,(IX+$07)          ;
  RES 5,(IX+$07)          ;
  SLA (IX+$05)            ;
  LD DE,$0623                  ; Its name
  LD (SPIDER_WEB_ADJECTIVE),DE ;
  RET

; Timer 9: the hole vanishes again
;
; Unless the door has been opened (flag bit 5), the timer is started again and
; the door hidden, so the hole comes and goes every five turns until somebody
; opens it.
SIDE_DOOR_VANISHES:
  LD HL,MOUNTAINS_SIDE_DOOR_FLAGS ; Opened? Then it stays
  BIT 5,(HL)                      ;
  RET NZ                          ;
  LD A,(TIMER9)           ; Start the timer again
  LD (TIMER9_COUNT),A     ;
  LD HL,MOUNTAINS_SIDE_DOOR_FLAGS ; Hidden
  RES 7,(HL)                      ;
  LD A,(PLAYER_WHERE)     ; At location 42? "the hole vanishes."
  CP $2A                  ;
  RET NZ                  ;
; This entry point is used by the routine at SIDE_DOOR_CLOSED.
SAY_HOLE_VANISHES:
  LD HL,MSG_THE_HOLE_VANISH
  JP RUN_MESSAGE_HL       ; }

; Timer 9's warning: a hole appears in the mountain's side
;
; Makes the side door visible -- it is one of the two objects in the game that
; start without flag bit 7 -- and tells a player at location 42, the side door.
SIDE_DOOR_APPEARS:
  LD HL,MOUNTAINS_SIDE_DOOR_FLAGS ; The side door can be seen now
  SET 7,(HL)                      ;
  LD A,(PLAYER_WHERE)       ; At location 42? "there is a loud crack and a hole
  CP $2A                    ; appears..."
  RET NZ                    ;
  LD HL,MSG_THERE_IS_A_LOUD ;
  JP RUN_MESSAGE_HL

; After the side door is closed: locked, hidden, and the hole's timer started
; again
SIDE_DOOR_CLOSED:
  CALL ONLY_IF_DONE       ; Only if it really happened
  LD A,$06                ; The hole comes again in six turns
  LD (TIMER9_COUNT),A     ;
  LD HL,MOUNTAINS_SIDE_DOOR_FLAGS ; Locked and hidden, and "the hole vanishes."
  SET 0,(HL)                      ; where seen
  RES 7,(HL)                      ;
  JR SAY_HOLE_VANISHES            ;

; Timer 5's warning: the magic door opens and an elf sweeps past
;
; Sets bit 5 of the magic door's flags, reports it to a player in either of its
; rooms, and goes on to timer 6's routine.
MAGIC_DOOR_OPENS:
  LD HL,MAGIC_DOOR_FLAGS  ; Open
  SET 5,(HL)              ;
  LD HL,MSG_THE_MAGIC_DOOR_OPEN ; "the magic door opens."
  CALL AT_MAGIC_DOOR            ;
  LD HL,MSG_AN_ELF_SWEEPS_PAST ; "an elf sweeps past."
  CALL AT_MAGIC_DOOR           ;
  JP RING_CHECK

; Print the message at HL if the player is by the magic door
;
; Used by the routines at MAGIC_DOOR_OPENS and MAGIC_DOOR_CLOSES.
;
; That is, at location 30 or location 28, the two rooms the door is in.
;
; I:HL A message
AT_MAGIC_DOOR:
  LD A,(PLAYER_WHERE)
  CP $1E
  JP Z,RUN_MESSAGE_HL
  CP $1C
  JP Z,RUN_MESSAGE_HL
  RET

; Timer 5: the magic door closes
MAGIC_DOOR_CLOSES:
  LD HL,MAGIC_DOOR_FLAGS  ; Shut
  RES 5,(HL)              ;
  LD HL,MSG_THE_MAGIC_DOOR_CLOSE ; "the magic door closes."
  JP AT_MAGIC_DOOR               ;

; Timer 6: the ring slips off
;
; Used by the routine at MAGIC_DOOR_OPENS.
;
; WEAR_RING starts this timer at a random 2 to 10 turns, so the ring's
; invisibility never lasts. When it runs out -- or when the magic door opens
; and the elf sweeps past, whose warning comes here too -- whoever has the ring
; and is invisible takes it off, through TAKE_OFF_RING.
RING_CHECK:
  LD IX,VALUABLE_GOLDEN_RING ; Nobody has the ring: nothing to do
  LD A,(IX+$01)              ;
  CP $FF                     ;
  RET Z                      ;
  CALL GET_OBJECT         ; The holder is the actor
  LD (ACTOR),IX           ;
  BIT 7,(IX+$07)          ; Invisible? Then it comes off
  JP Z,TAKE_OFF_RING      ;
  RET

; The wine's own handler: the player drinks it
;
; The wine carries this for action 0 in its record, so nothing branches to it
; and it showed as data; drinking the wine is what runs it. Only the player is
; affected. It also starts timer 7 in TIMERS, copying its length of five turns
; into its count, and when that runs out WINE_WEARS_OFF sobers the player up
; again.
WINE_DRUNK:
  LD A,(ACTING)           ; Only the player
  CP $00                  ;
  RET NZ                  ;
  LD A,$01                ; Drunk: from now on every S is followed by an H
  LD (DRUNK),A            ;
  LD A,(TIMER7)           ; Start timer 7: sober again in five turns
  LD (TIMER7_COUNT),A     ;
  RET                     ;

; Timer 7: the wine wears off
;
; Clears DRUNK, five turns after WINE_DRUNK set it and started this timer.
WINE_WEARS_OFF:
  SUB A                   ; No longer drunk
  LD (DRUNK),A            ;
  RET

; Timer 2: the spider web smothers the player
;
; Only if the player is still at location 26, the spider threads place: "the
; spider web is slowly smothering you", and PLAYER_DIES.
WEB_SMOTHERS:
  LD A,(PLAYER_WHERE)     ; Not at location 26? Nothing happens
  CP $1A                  ;
  RET NZ                  ;
  LD HL,MSG_THE_SPIDER_WEB_IS ; Say so and die
  CALL RUN_MESSAGE_HL         ;
  JP PLAYER_DIES              ;

; Timer 8's warning: pale eyes in the forest
;
; "you see some pale bulbous eyes staring at you." Then, unless the player is
; where FOREST_ENTRY says or at the other of the forest road and the forest
; (locations 2 and 3), something drops and stings, fatally, as in EYES_STING.
; What sets FOREST_ENTRY is not yet traced.
EYES_WARNING:
  LD HL,MSG_SEE_SOME_PALE_BULBOUS ; "you see some pale bulbous eyes staring at
  CALL RUN_MESSAGE_HL             ; you."
  LD A,(PLAYER_WHERE)     ; At FOREST_ENTRY's location: safe
  LD C,A                  ;
  LD HL,FOREST_ENTRY      ;
  CP (HL)                 ;
  RET Z                   ;
  LD B,(HL)               ; A = 2, or 3 if FOREST_ENTRY is 2: safe there too
  LD A,$02                ;
  CP B                    ;
  JR NZ,EYES_WARNING_0    ;
  LD A,$03                ;
EYES_WARNING_0:
  CP C                    ;
  RET Z                   ;
  JR STUNG_DEAD           ; Anywhere else: stung

; Timer 8: stung in the forest
;
; A player still at location 2 or 3, the forest road or the forest, sees the
; eyes, is stung by something dropping from above, and dies.
EYES_STING:
  LD A,(PLAYER_WHERE)     ; Not at location 2 or 3? Nothing happens
  CP $02                  ;
  JR Z,EYES_STING_0       ;
  CP $03                  ;
  RET NZ                  ;
EYES_STING_0:
  LD HL,MSG_SEE_SOME_PALE_BULBOUS ; "you see some pale bulbous eyes staring at
  CALL RUN_MESSAGE_HL             ; you."
; This entry point is used by the routine at EYES_WARNING.
STUNG_DEAD:
  LD HL,MSG_SOME_THIN_G_DROP ; "some thing drops from above and stings.", and
  CALL RUN_MESSAGE_HL        ; dead
  JP PLAYER_DIES             ;

; The sentence each action code stands for
;
; Fifty-nine 8-byte patterns, ending at a zero word. The action code is the
; pattern's place in the list, counting from 1: PARSE_ACTION finds the one that
; matches the parsed sentence and works the code out from its address. Each is
; a verb, a particle and a preposition as word references, then two more bytes;
; for the ten directions the first word is the direction and the last is GO, so
; that NORTH and GO NORTH are the same action. The top bits of the references
; and the last two bytes of the others are flags, not yet worked out.
;
; So this is also the key to ACTION_TABLE and to every action code in the
; characters' scripts: $10 is OPEN, $13 TAKE, $1D GIVE TO, $24 RUN, $30
; CAPTURE, $37 CLIMB OUT OF.
ACTION_PATTERNS:
  DEFB $80,$04,$00,$00,$00,$00,$DE,$02 ; 1 ($01): GO NORTH
  DEFB $07,$06,$00,$00,$00,$00,$DE,$02 ; 2 ($02): GO SOUTH
  DEFB $FE,$01,$00,$00,$00,$00,$DE,$02 ; 3 ($03): GO EAST
  DEFB $79,$07,$00,$00,$00,$00,$DE,$02 ; 4 ($04): GO WEST
  DEFB $85,$04,$00,$00,$00,$00,$DE,$02 ; 5 ($05): GO NORTHEAST
  DEFB $8E,$04,$00,$00,$00,$00,$DE,$02 ; 6 ($06): GO NORTHWEST
  DEFB $0C,$06,$00,$00,$00,$00,$DE,$02 ; 7 ($07): GO SOUTHEAST
  DEFB $15,$06,$00,$00,$00,$00,$DE,$02 ; 8 ($08): GO SOUTHWEST
  DEFB $25,$07,$00,$00,$00,$00,$DE,$02 ; 9 ($09): GO UP
  DEFB $C4,$01,$00,$00,$00,$00,$DE,$02 ; 10 ($0A): GO DOWN
  DEFB $58,$E6,$00,$00,$96,$07,$00,$40 ; 11 ($0B): STRIKE WITH
  DEFB $34,$81,$00,$00,$00,$00,$00,$40 ; 12 ($0C): CLOSE
  DEFB $E8,$81,$00,$00,$00,$80,$00,$00 ; 13 ($0D): DROP
  DEFB $E8,$C1,$00,$00,$78,$03,$00,$40 ; 14 ($0E): DROP IN
  DEFB $73,$E0,$00,$00,$96,$47,$00,$40 ; 15 ($0F): ATTACK WITH
  DEFB $B4,$84,$00,$00,$00,$00,$00,$40 ; 16 ($10): OPEN
  DEFB $08,$C5,$00,$00,$78,$03,$00,$40 ; 17 ($11): PUT IN
  DEFB $08,$C5,$00,$00,$AA,$04,$00,$40 ; 18 ($12): PUT ON
  DEFB $8C,$86,$00,$00,$00,$00,$00,$40 ; 19 ($13): TAKE
  DEFB $8C,$C6,$BF,$04,$9C,$04,$00,$40 ; 20 ($14): TAKE OUT OF
  DEFB $8C,$C6,$B5,$02,$00,$00,$00,$40 ; 21 ($15): TAKE FROM
  DEFB $8C,$96,$9F,$24,$00,$00,$00,$40 ; 22 ($16): TAKE OFF
  DEFB $13,$04,$00,$10,$00,$00,$00,$40 ; 23 ($17): LOOK
  DEFB $13,$84,$C1,$26,$00,$00,$00,$00 ; 24 ($18): LOOK THROUGH
  DEFB $13,$84,$43,$20,$00,$00,$00,$00 ; 25 ($19): LOOK ACROSS
  DEFB $92,$03,$00,$10,$00,$00,$00,$40 ; 26 ($1A): INVENTORY
  DEFB $02,$82,$00,$00,$00,$00,$00,$00 ; 27 ($1B): EAT
  DEFB $3E,$82,$00,$00,$00,$00,$00,$40 ; 28 ($1C): EXAMINE
  DEFB $D4,$C2,$D1,$06,$00,$10,$00,$60 ; 29 ($1D): GIVE TO
  DEFB $DE,$82,$C1,$26,$00,$00,$00,$00 ; 30 ($1E): GO THROUGH
  DEFB $2D,$82,$00,$80,$00,$00,$00,$00 ; 31 ($1F): ENTER
  DEFB $DE,$82,$8E,$A3,$00,$00,$00,$00 ; 32 ($20): GO INTO
  DEFB $E3,$81,$00,$00,$00,$00,$00,$00 ; 33 ($21): DRINK
  DEFB $28,$82,$00,$00,$00,$00,$00,$00 ; 34 ($22): EMPTY
  DEFB $61,$C2,$00,$00,$96,$07,$00,$40 ; 35 ($23): FILL WITH
  DEFB $6C,$05,$00,$00,$00,$00,$00,$00 ; 36 ($24): RUN
  DEFB $F2,$C3,$00,$00,$96,$07,$00,$40 ; 37 ($25): LOCK WITH
  DEFB $12,$C7,$00,$00,$96,$07,$00,$40 ; 38 ($26): UNLOCK WITH
  DEFB $85,$92,$00,$00,$00,$40,$00,$00 ; 39 ($27): FOLLOW
  DEFB $72,$87,$00,$00,$00,$00,$00,$00 ; 40 ($28): WEAR
  DEFB $C8,$86,$00,$00,$00,$00,$00,$00 ; 41 ($29): THROW
  DEFB $C8,$C6,$00,$00,$70,$20,$00,$00 ; 42 ($2A): THROW AT
  DEFB $C8,$C6,$00,$00,$43,$00,$00,$40 ; 43 ($2B): THROW ACROSS
  DEFB $C8,$C6,$00,$00,$C1,$06,$00,$40 ; 44 ($2C): THROW THROUGH
  DEFB $D3,$80,$00,$00,$00,$40,$00,$00 ; 45 ($2D): BURN
  DEFB $CD,$C6,$00,$00,$D1,$06,$00,$40 ; 46 ($2E): TIE TO
  DEFB $78,$81,$00,$00,$00,$00,$00,$00 ; 47 ($2F): CUT
  DEFB $F4,$80,$00,$00,$00,$40,$00,$00 ; 48 ($30): CAPTURE
  DEFB $00,$85,$00,$00,$00,$00,$00,$00 ; 49 ($31): PULL
  DEFB $7C,$86,$00,$00,$00,$00,$00,$40 ; 50 ($32): SWIM
  DEFB $20,$87,$00,$00,$00,$80,$00,$40 ; 51 ($33): UNTIE
  DEFB $2F,$81,$00,$00,$00,$00,$00,$40 ; 52 ($34): CLIMB
  DEFB $90,$86,$D1,$26,$00,$40,$00,$40 ; 53 ($35): TALK TO
  DEFB $2F,$81,$8E,$23,$00,$00,$00,$40 ; 54 ($36): CLIMB INTO
  DEFB $2F,$81,$BF,$24,$9C,$04,$00,$80 ; 55 ($37): CLIMB OUT OF
  DEFB $A1,$93,$B0,$24,$00,$00,$00,$00 ; 56 ($38): JUMP ONTO
  DEFB $A9,$81,$00,$00,$00,$00,$00,$40 ; 57 ($39): DIG
  DEFB $94,$85,$00,$00,$00,$40,$00,$40 ; 58 ($3A): SHOOT
  DEFB $0D,$81,$00,$00,$00,$80,$00,$40 ; 59 ($3B): CARRY
  DEFB $00,$00            ; End of the patterns

; The articles, as word references
;
; Two sets of four, picked by the top bits of a noun's word reference
; (ARTICLE): the first for ordinary text, the second for the input window and
; for narration, which says THE where the first would say A or AN.
ARTICLES:
  DEFW $069F              ; THE, A, AN, SOME
  DEFW $0040              ;
  DEFW $0058              ;
  DEFW $0603              ;
ARTICLES_NARRATING:
  DEFW $069F              ; THE, THE, THE, SOME
  DEFW $069F              ;
  DEFW $069F              ;
  DEFW $0603              ;

; The 32 commonest words in messages
;
; A message byte from $60 to $7F stands for one of these, which is how the
; small glue words cost a byte each.
COMMON_WORDS:
  DEFB $40,$00            ; $60: a
  DEFB $5B,$00            ; $61: and
  DEFB $65,$00            ; $62: are
  DEFB $70,$00            ; $63: at
  DEFB $22,$08            ; $64: be
  DEFB $AF,$00            ; $65: blow
  DEFB $D7,$00            ; $66: but
  DEFB $EE,$00            ; $67: cannot
  DEFB $5E,$08            ; $68: carrying
  DEFB $C2,$08            ; $69: do
  DEFB $C0,$01            ; $6A: door
  DEFB $C8,$01            ; $6B: dragon
  DEFB $4F,$02            ; $6C: fall
  DEFB $B5,$02            ; $6D: from
  DEFB $89,$09            ; $6E: here
  DEFB $73,$03            ; $6F: i
  DEFB $78,$03            ; $70: in
  DEFB $9B,$03            ; $71: is
  DEFB $9E,$03            ; $72: it
  DEFB $5A,$0A            ; $73: not
  DEFB $9C,$04            ; $74: of
  DEFB $AA,$04            ; $75: on
  DEFB $AF,$0A            ; $76: see
  DEFB $03,$06            ; $77: some
  DEFB $9F,$06            ; $78: the
  DEFB $61,$0B            ; $79: there
  DEFB $6B,$0B            ; $7A: this
  DEFB $D1,$06            ; $7B: to
  DEFB $D4,$06            ; $7C: too
  DEFB $C8,$0B            ; $7D: what
  DEFB $96,$07            ; $7E: with
  DEFB $A8,$07            ; $7F: you

; Message: but fall and hit your   H E A D
;
; but fall and hit your   H E A D
MSG_BUT_FALL_AND_HIT:
  DEFB $66,$6C,$61,$83,$47,$8B,$EA,$20
  DEFB $48,$45,$41,$44,$15

; Message: but fall and smash your skull.
;
; but fall and smash your skull.
MSG_BUT_FALL_AND_SMASH:
  DEFB $66,$6C,$61,$85,$E6,$8B,$EA,$B5
  DEFB $BE

; Message: i do not know the word   "
;
; i do not know the word   "
MSG_I_DO_NOT_KNOW:
  DEFB $6F,$69,$73,$89,$C5,$78,$8B,$DE
  DEFB $20,$22,$20,$16

; Message: what   ?
;
; what   ?
MSG_WHAT:
  DEFB $7D,$20,$3F,$14

; Message: {13} you {1} . {13} time passes . .
;
; {13} you {1} . {13} time passes . .
;
; Also entered at MSG_TIME_PASSES (a tail): time passes . .
MSG_YOU_TIME_PASSES:
  DEFB $0D,$F7,$A8,$01,$2E,$0D
MSG_TIME_PASSES:
  DEFB $FB,$87,$8A,$74,$2E,$2E,$15

; Message: i do not know the verb   " {1} {1} {1}   "
;
; i do not know the verb   " {1} {1} {1}   "
MSG_I_DO_NOT_KNOW_B:
  DEFB $6F,$69,$73,$89,$C5,$78,$8B,$A9
  DEFB $20,$22,$01,$01,$01,$20,$22,$14

; Message: {1} {1} {1} {0} {1} {1} {1} what   ?
;
; {1} {1} {1} {0} {1} {1} {1} what   ?
;
; Also entered at MSG_WHAT_C (a tail): {1} {1} {1} what   ?
MSG_WHAT_B:
  DEFB $01,$01,$01,$00
MSG_WHAT_C:
  DEFB $01,$01,$01,$7D,$20,$3F,$20,$16

; Message: which {1}   ?
;
; which {1}   ?
MSG_WHICH:
  DEFB $8B,$D1,$01,$20,$3F,$20,$16

; Message: i do not see {0} here
;
; i do not see {0} here
MSG_I_DO_NOT_SEE:
  DEFB $6F,$69,$73,$76,$00,$6E,$14

; Message:
MSG_CODES_ONLY:
  DEFB $14

; Message: i see nothing to
;
; i see nothing to
MSG_I_SEE_NOTHING_TO:
  DEFB $6F,$76,$8A,$5D,$A6,$D1

; Message: {sub-message -7} {1} {1} {1}
;
; {sub-message -7} {1} {1} {1}
MSG_CODES_ONLY_B:
  DEFB $0B,$F9,$01,$01,$01,$14

; Message: {sub-message -13} {1} {1} {1} {0} {1} {1} {1}
;
; {sub-message -13} {1} {1} {1} {0} {1} {1} {1}
MSG_CODES_ONLY_C:
  DEFB $0B,$F3,$01,$01,$01,$00,$01,$01
  DEFB $01,$14

; Message: {16} not carrying it
;
; {16} not carrying it
MSG_NOT_CARRYING_IT:
  DEFB $10,$73,$68,$72,$15

; Message: {16} carrying
;
; {16} carrying
MSG_CARRYING:
  DEFB $10,$68,$15

; Message: {19} carrying
;
; {19} carrying
MSG_CARRYING_B:
  DEFB $13,$68,$14

; Message: and it get swept away.
;
; and it get swept away.
MSG_AND_IT_GET_SWEPT:
  DEFB $61,$72,$C2,$CE,$8B,$46,$B8,$1A

; Message: {7} is too heavy to lift.
;
; {7} is too heavy to lift.
MSG_IS_TOO_HEAVY_TO:
  DEFB $07,$71,$7C,$83,$27,$7B,$B3,$D4

; Message: {16} carrying too much.
;
; {16} carrying too much.
MSG_CARRYING_TOO_MUCH:
  DEFB $10,$68,$7C,$BA,$4B

; Message: {16} already carrying {7}
;
; {16} already carrying {7}
MSG_ALREADY_CARRYING:
  DEFB $10,$80,$51,$68,$07,$15

; Message: to the
;
; to the
MSG_TO_THE:
  DEFB $7B,$78,$16

; Message: {9} is too full.
;
; {9} is too full.
MSG_IS_TOO_FULL:
  DEFB $09,$71,$7C,$B2,$B9

; Message: it is dark.
;
; it is dark.
MSG_IT_IS_DARK:
  DEFB $72,$71,$B1,$8E

; Message: {4} is too small for {6} to enter.
;
; {4} is too small for {6} to enter.
MSG_IS_TOO_SMALL_FOR:
  DEFB $04,$71,$7C,$85,$E1,$82,$8F,$06
  DEFB $7B,$B2,$2D

; Message: {4} is too full for {6} to enter
;
; {4} is too full for {6} to enter
MSG_IS_TOO_FULL_FOR:
  DEFB $04,$71,$7C,$82,$B9,$82,$8F,$06
  DEFB $7B,$D2,$2D,$15

; Message: with one well place blow {6} cleave {14} skull.
;
; with one well place blow {6} cleave {14} skull.
MSG_WITH_ONE_WELL_PLACE:
  DEFB $7E,$84,$AD,$8B,$C4,$CA,$7E,$80
  DEFB $AF,$06,$88,$66,$0E,$B5,$BE

; Message: {12}   V I O L E N T attack almost kill {6}
;
; {12}   V I O L E N T attack almost kill {6}
MSG_V_I_O_L:
  DEFB $0C,$20,$56,$49,$4F,$4C,$45,$4E
  DEFB $54,$80,$73,$87,$D9,$C3,$A8,$06
  DEFB $15

; Message: {6} give {7} a vicious cut in the ribs - {14} strength is fa
;
; {6} give {7} a vicious cut in the ribs - {14} strength is failing fast.
MSG_GIVE_A_VICIOUS_CUT:
  DEFB $06,$82,$D4,$07,$60,$87,$41,$D1
  DEFB $78,$70,$78,$85,$39,$2D,$0E,$8B
  DEFB $2E,$71,$89,$02,$B2,$53

; Message: a nasty slice miss {14} heart.
;
; a nasty slice miss {14} heart.
MSG_A_NASTY_SLICE_MISS:
  DEFB $60,$84,$6A,$85,$CF,$CA,$25,$0E
  DEFB $B3,$22

; Message: {6} slice {14} - hand blood drips slowly to the ground.
;
; {6} slice {14} - hand blood drips slowly to the ground.
MSG_SLICE_HAND_BLOOD_DRIPS:
  DEFB $06,$85,$CF,$0E,$2D,$83,$12,$80
  DEFB $B3,$88,$CA,$85,$DB,$7B,$78,$B9
  DEFB $65

; Message: {6} give {7} a nasty slash in the leg.
;
; {6} give {7} a nasty slash in the leg.
MSG_GIVE_A_NASTY_SLASH:
  DEFB $06,$82,$D4,$07,$60,$84,$6A,$D5
  DEFB $C3,$70,$78,$B3,$C9

; Message: {6} hit {7} hard on the shoulder - {7} stagger and almost fa
;
; {6} hit {7} hard on the shoulder - {7} stagger and almost fall
MSG_HIT_HARD_ON_THE:
  DEFB $06,$83,$47,$07,$83,$16,$75,$78
  DEFB $85,$9E,$2D,$07,$9B,$03,$61,$87
  DEFB $D9,$92,$4F,$15

; Message: a fast blow knocks the wind out of {7}
;
; a fast blow knocks the wind out of {7}
MSG_A_FAST_BLOW_KNOCKS:
  DEFB $60,$82,$53,$65,$89,$BF,$78,$8B
  DEFB $DA,$84,$BF,$74,$07,$15

; Message: a fast stroke sweeps {7} off {14} feet , but {17} on guard i
;
; a fast stroke sweeps {7} off {14} feet , but {17} on guard in a moment.
MSG_A_FAST_STROKE_SWEEPS:
  DEFB $60,$82,$53,$86,$5E,$8B,$40,$07
  DEFB $84,$9F,$0E,$82,$5D,$2C,$66,$11
  DEFB $75,$89,$6F,$70,$60,$BA,$29

; Message: {6} hit {7} with a glancing blow and leave {7} momentarily s
;
; {6} hit {7} with a glancing blow and leave {7} momentarily stunned.
MSG_HIT_WITH_A_GLANCING:
  DEFB $06,$83,$47,$07,$7E,$60,$89,$4C
  DEFB $65,$61,$83,$C4,$07,$8A,$2F,$B6
  DEFB $70

; Message: {6} thrust {7} back - {7} lose {14} footing but recover quic
;
; {6} thrust {7} back - {7} lose {14} footing but recover quickly.
MSG_THRUST_BACK_LOSE_FOOTING:
  DEFB $06,$8B,$81,$07,$80,$7C,$2D,$07
  DEFB $99,$E8,$0E,$89,$35,$66,$9A,$A4
  DEFB $B5,$0C

; Message: {6} swing broadside at {14} body but at the last moment {7}
;
; {6} swing broadside at {14} body but at the last moment {7} jump aside.
MSG_SWING_BROADSIDE_AT_BODY:
  DEFB $06,$8B,$4B,$88,$4B,$63,$0E,$80
  DEFB $BF,$66,$63,$78,$89,$C9,$8A,$29
  DEFB $07,$93,$A1,$B8,$08

; Message: {12} {3} sweeps past close to {14} ear.
;
; {12} {3} sweeps past close to {14} ear.
MSG_SWEEPS_PAST_CLOSE_TO:
  DEFB $0C,$03,$8B,$40,$8A,$7A,$81,$34
  DEFB $7B,$0E,$B1,$FB

; Message: {6} slash at {7} but the blow is ineffective.
;
; {6} slash at {7} but the blow is ineffective.
MSG_SLASH_AT_BUT_THE:
  DEFB $06,$85,$C3,$63,$07,$66,$78,$65
  DEFB $71,$B9,$A0

; Message: {6} brandish {12} {3} , but {17} on guard.
;
; {6} brandish {12} {3} , but {17} on guard.
MSG_BRANDISH_BUT_ON_GUARD:
  DEFB $06,$88,$3E,$0C,$03,$2C,$66,$11
  DEFB $75,$B9,$6F

; Message: {6} swing feebly at {7} but miss by a wide margin.
;
; {6} swing feebly at {7} but miss by a wide margin.
MSG_SWING_FEEBLY_AT_BUT:
  DEFB $06,$8B,$4B,$82,$57,$63,$07,$66
  DEFB $8A,$25,$88,$5B,$60,$87,$7D,$B9
  DEFB $FD

; Message: {6} seem tired - {6} stagger but valiant L Y attempt another
;
; {6} seem tired - {6} stagger but valiant L Y attempt another blow.
MSG_SEEM_TIRED_STAGGER_BUT:
  DEFB $06,$8A,$B2,$8B,$8B,$2D,$06,$8B
  DEFB $03,$66,$87,$28,$4C,$59,$88,$13
  DEFB $80,$5E,$B0,$AF

; Message: but the effort is wasted . {14} defense is too strong.
;
; but the effort is wasted . {14} defense is too strong.
MSG_BUT_THE_EFFORT_IS:
  DEFB $66,$78,$88,$CF,$71,$8B,$BB,$2E
  DEFB $0E,$88,$A2,$71,$7C,$B6,$64

; Message: you cannot kill with {9}
;
; you cannot kill with {9}
MSG_YOU_CANNOT_KILL_WITH:
  DEFB $7F,$67,$83,$A8,$7E,$09,$15

; Message: it sail across and
;
; it sail across and
MSG_IT_SAIL_ACROSS_AND:
  DEFB $72,$CA,$AB,$80,$43,$A0,$5B

; Message: land S on the other side.
;
; land S on the other side.
MSG_LAND_S_ON_THE:
  DEFB $83,$BB,$53,$75,$78,$8A,$6B,$B5
  DEFB $A6

; Message: fall just short of the other side.
;
; fall just short of the other side.
MSG_FALL_JUST_SHORT_OF:
  DEFB $C2,$4F,$89,$B1,$85,$99,$74,$78
  DEFB $8A,$6B,$B5,$A6

; Message: {sub-message +8} but slide out again.
;
; {sub-message +8} but slide out again.
MSG_BUT_SLIDE_OUT_AGAIN:
  DEFB $0B,$08,$66,$CA,$D4,$84,$BF,$B7
  DEFB $C3

; Message: land S in the boat.
;
; land S in the boat.
MSG_LAND_S_IN_THE:
  DEFB $83,$BB,$53,$70,$78,$B0,$B8

; Message: the boat glides across the river and land S on this side.
;
; the boat glides across the river and land S on this side.
MSG_THE_BOAT_GLIDES_ACROSS:
  DEFB $78,$80,$B8,$89,$54,$80,$43,$78
  DEFB $85,$4A,$61,$83,$BB,$53,$75,$7A
  DEFB $B5,$A6

; Message: with a lurch the boat glides across the river and {jump -71}
;
; with a lurch the boat glides across the river and {jump -71} {7} is not in
; {9}
;
; Also entered at MSG_IS_NOT_IN (an overlap): {7} is not in {9}
MSG_WITH_A_LURCH_THE:
  DEFB $7E,$60,$89,$B5,$78,$80,$B8,$89
  DEFB $54,$80,$43,$78,$85,$4A,$61,$02
  DEFB $B9
MSG_IS_NOT_IN:
  DEFB $07,$71,$73,$70,$09,$15

; Message: {4} is {1}
;
; {4} is {1}
MSG_IS:
  DEFB $04,$71,$01,$15

; Message: i cannot do that.
;
; i cannot do that.
MSG_I_CANNOT_DO_THAT:
  DEFB $6F,$67,$69,$B6,$9B

; Message: i see nothing here.
;
; i see nothing here.
MSG_I_SEE_NOTHING_HERE:
  DEFB $6F,$76,$8A,$5D,$B9,$89

; Message: in {jump +17} on {jump +13} behind {jump +9} under {jump +5}
;
; in {jump +17} on {jump +13} behind {jump +9} under {jump +5} tie D to the
MSG_IN_ON_BEHIND_UNDER:
  DEFB $83,$78,$02,$11,$84,$AA,$02,$0D
  DEFB $88,$25,$02,$09,$8B,$9B,$02,$05
  DEFB $86,$CD,$44,$7B,$78,$16

; Message: {1} there {1}
;
; {1} there {1}
MSG_THERE:
  DEFB $01,$79,$01,$14

; Message: {4} is carrying {4}
;
; {4} is carrying {4}
MSG_IS_CARRYING:
  DEFB $04,$71,$68,$04,$15

; Message: i cannot follow {7} from here
;
; i cannot follow {7} from here
MSG_I_CANNOT_FOLLOW_FROM:
  DEFB $6F,$67,$82,$85,$07,$6D,$6E,$15

; Message: {16} dead.
;
; {16} dead.
MSG_DEAD:
  DEFB $10,$B1,$92

; Message: {6} see nothing special here.
;
; {6} see nothing special here.
MSG_SEE_NOTHING_SPECIAL_HERE:
  DEFB $06,$76,$8A,$5D,$8A,$F7,$B9,$89

; Message: {16} in
;
; {16} in
MSG_IN:
  DEFB $10
MSG_IN_SLOT:
  DEFB $83,$78
  DEFB $16

; Message: {6} see
;
; {6} see
MSG_SEE:
  DEFB $06,$76,$16

; Message: {6} see   :
;
; {6} see   :
MSG_SEE_B:
  DEFB $06,$8A,$AF,$20,$3A,$14

; Message: {6} say   "
;
; {6} say   "
MSG_SAY:
  DEFB $06,$85,$84,$20,$22,$16

; Message:   " .
;
; " .
MSG_CODES_ONLY_D:
  DEFB $20,$22,$2E,$14

; Message: there is {0}
;
; there is {0}
MSG_THERE_IS:
  DEFB $79,$71,$00,$14

; Message: {0} enter .
;
; {0} enter .
;
; Also entered at MSG_ENTER_B (a tail): enter .
MSG_ENTER:
  DEFB $00
MSG_ENTER_B:
  DEFB $C2,$2D,$2E,$14

; Message: {0} appear
;
; {0} appear
MSG_APPEAR:
  DEFB $00,$C7,$EA,$15

; Message: visible exits are :
;
; visible exits are :
MSG_VISIBLE_EXITS_ARE:
  DEFB $8B,$AD,$88,$F1,$62,$3A,$16

; Message: you hear a noise.
;
; you hear a noise.
MSG_YOU_HEAR_A_NOISE:
  DEFB $7F,$D9,$85,$60,$BA,$55

; Message: {9} do E S not fit this lock.
;
; {9} do E S not fit this lock.
MSG_DO_E_S_NOT:
  DEFB $09,$69,$45,$53,$73,$89,$19,$7A
  DEFB $B3,$F2

; Message: the magic door open .
;
; the magic door open .
MSG_THE_MAGIC_DOOR_OPEN:
  DEFB $78,$84,$24,$6A,$C4,$B4,$2E,$14

; Message: the magic door close .
;
; the magic door close .
MSG_THE_MAGIC_DOOR_CLOSE:
  DEFB $78,$84,$24,$6A,$C1,$34,$2E,$14

; Message: thank you
;
; thank you
MSG_THANK_YOU:
  DEFB $8B,$58,$A7,$A8

; Message: what ' S this   ?
;
; what ' S this   ?
MSG_WHAT_S_THIS:
  DEFB $7D,$27,$53,$7A,$20,$3F,$16

; Message: you are do a great job
;
; you are do a great job
MSG_YOU_ARE_DO_A:
  DEFB $7F,$62,$C8,$C6,$60,$82,$FF,$A9
  DEFB $AE

; Message: hurry up
;
; hurry up
MSG_HURRY_UP:
  DEFB $89,$9B,$A7,$25

; Message: hello
;
; hello
MSG_HELLO:
  DEFB $A3,$2C

; Message: this was thrains key
;
; this was thrains key
MSG_THIS_WAS_THRAINS_KEY:
  DEFB $7A,$8B,$B8,$FB,$6F,$A3,$A5

; Message: {7} fall down a hole and vanish
;
; {7} fall down a hole and vanish
MSG_FALL_DOWN_A_HOLE:
  DEFB $07,$C2,$4F,$81,$C4,$60,$83,$5D
  DEFB $61,$CB,$A3,$15

; Message: {16} not wear I N G {7}
;
; {16} not wear I N G {7}
MSG_NOT_WEAR_I_N:
  DEFB $10,$73,$87,$72,$49,$4E,$47,$07
  DEFB $15

; Message: {9} is already tie D
;
; {9} is already tie D
MSG_IS_ALREADY_TIE_D:
  DEFB $09,$71,$80,$51,$86,$CD,$44,$15

; Message: the vicious warg run around you and howls
;
; the vicious warg run around you and howls
MSG_THE_VICIOUS_WARG_RUN:
  DEFB $78,$87,$41,$87,$9A,$85,$6C,$87
  DEFB $F8,$7F,$61,$A9,$96

; Message: {7} is not tie D
;
; {7} is not tie D
MSG_IS_NOT_TIE_D:
  DEFB $07,$71,$73,$86,$CD,$44,$15

; Message: some spider S start mend the broken web.
;
; some spider S start mend the broken web.
MSG_SOME_SPIDER_S_START:
  DEFB $77,$86,$23,$53,$8B,$17,$CA,$15
  DEFB $78,$80,$CD,$B7,$76

; Message: what do you expect me to do with this   ?
;
; what do you expect me to do with this   ?
MSG_WHAT_DO_YOU_EXPECT:
  DEFB $7D,$69,$7F,$88,$F6,$84,$2F,$7B
  DEFB $69,$7E,$7A,$20,$3F,$16

; Message: as soon as {6} touch the river {6} fall asleep and gently fl
;
; as soon as {6} touch the river {6} fall asleep and gently float away.
MSG_AS_SOON_AS_TOUCH:
  DEFB $88,$05,$8A,$F3,$88,$05,$06,$8B
  DEFB $93,$78,$85,$4A,$06,$6C,$88,$0D
  DEFB $61,$82,$C8,$89,$26,$B8,$1A

; Message: where ' S the thief   ?
;
; where ' S the thief   ?
MSG_WHERE_S_THE_THIEF:
  DEFB $8B,$CC,$27,$53,$78,$86,$AB,$20
  DEFB $3F,$16

; Message: get us out of this one , thief   !
;
; get us out of this one , thief   !
MSG_GET_US_OUT_OF:
  DEFB $82,$CE,$8B,$A0,$84,$BF,$74,$7A
  DEFB $84,$AD,$2C,$86,$AB,$20,$21,$16

; Message: thorin sit down and start sing about gold
;
; thorin sit down and start sing about gold
MSG_THORIN_SIT_DOWN_AND:
  DEFB $86,$B4,$CA,$D0,$81,$C4,$61,$CB
  DEFB $17,$CA,$C8,$87,$B0,$A2,$EF

; Message: thorin wait
;
; thorin wait
MSG_THORIN_WAIT:
  DEFB $86,$B4,$A7,$56

; Message: {6} fall asleep
;
; {6} fall asleep
MSG_FALL_ASLEEP:
  DEFB $06,$6C,$88,$0D,$15

; Message: the spider web is slowly smothering you
;
; the spider web is slowly smothering you
MSG_THE_SPIDER_WEB_IS:
  DEFB $78,$86,$23,$87,$76,$71,$85,$DB
  DEFB $85,$F3,$A7,$A8

; Message: the small curious key shatter
;
; the small curious key shatter
MSG_THE_SMALL_CURIOUS_KEY:
  DEFB $78,$85,$E1,$81,$63,$83,$A5,$CA
  DEFB $C1,$15

; Message: an elf sweeps past.
;
; an elf sweeps past.
MSG_AN_ELF_SWEEPS_PAST:
  DEFB $80,$58,$82,$0A,$8B,$40,$BA,$7A

; Message: you cannot reach {7}
;
; you cannot reach {7}
MSG_YOU_CANNOT_REACH:
  DEFB $7F,$67,$8A,$9F,$07,$15

; Message: {16} not carrying the bow.
;
; {16} not carrying the bow.
MSG_NOT_CARRYING_THE_BOW:
  DEFB $10,$73,$68,$78,$B0,$C3

; Message: the arrow miss E S {9} by a wide margin.
;
; the arrow miss E S {9} by a wide margin.
MSG_THE_ARROW_MISS_E:
  DEFB $78,$80,$6B,$8A,$25,$45,$53,$09
  DEFB $88,$5B,$60,$87,$7D,$B9,$FD

; Message: the arrow hit S {7}
;
; the arrow hit S {7}
MSG_THE_ARROW_HIT_S:
  DEFB $78,$80,$6B,$D3,$47,$53,$07,$15

; Message: {16} too big.
;
; {16} too big.
MSG_TOO_BIG:
  DEFB $10,$7C,$B0,$A2

; Message: {0} evaporate
;
; {0} evaporate
;
; Also entered at MSG_EVAPORATE_B (a tail): evaporate
MSG_EVAPORATE:
  DEFB $00
MSG_EVAPORATE_B:
  DEFB $C8,$E1,$15

; Message: {12} foul gluttony has kill E D {6}
;
; {12} foul gluttony has kill E D {6}
MSG_FOUL_GLUTTONY_HAS_KILL:
  DEFB $0C,$82,$B1,$89,$5A,$89,$7B,$D3
  DEFB $A8,$45,$44,$06,$15

; Message: {16} slowly sink into the bog.
;
; {16} slowly sink into the bog.
MSG_SLOWLY_SINK_INTO_THE:
  DEFB $10,$85,$DB,$CA,$CC,$83,$8E,$78
  DEFB $B0,$BC

; Message: the dragon say   " well thief your cunning has failed you th
;
; the dragon say   " well thief your cunning has failed you this time . prepare
; to die   "   .
MSG_THE_DRAGON_SAY_WELL:
  DEFB $78,$6B,$C5,$84,$20,$22,$FB,$C4
  DEFB $86,$AB,$8B,$EA,$81,$71,$89,$7B
  DEFB $88,$FC,$7F,$7A,$8B,$87,$2E,$8A
  DEFB $91,$7B,$88,$B1,$20,$22,$20,$2E
  DEFB $14

; Message: the dragon say   " i may not be able to see you thief but i
;
; the dragon say   " i may not be able to see you thief but i can still burn
; you . prepare to die   "   .
MSG_THE_DRAGON_SAY_I:
  DEFB $78,$6B,$C5,$84,$20,$22,$F3,$73
  DEFB $8A,$0D,$73,$64,$87,$AC,$7B,$76
  DEFB $7F,$86,$AB,$66,$F3,$73,$80,$EB
  DEFB $8B,$1C,$80,$D3,$7F,$2E,$8A,$91
  DEFB $7B,$88,$B1,$20,$22,$20,$2E,$14

; Message: in the distance you see the shape of a monstrous dragon flyi
;
; in the distance you see the shape of a monstrous dragon flying after you.
MSG_IN_THE_DISTANCE_YOU:
  DEFB $70,$78,$88,$BA,$7F,$76,$78,$8A
  DEFB $BC,$74,$60,$84,$45,$6B,$89,$2B
  DEFB $80,$49,$B7,$A8

; Message: the dragon descends and in a terrific spout of flames burn y
;
; the dragon descends and in a terrific spout of flames burn you to a crisp
MSG_THE_DRAGON_DESCENDS_AND:
  DEFB $78,$6B,$88,$A9,$61,$70,$60,$8B
  DEFB $50,$DA,$FE,$74,$82,$6F,$C0,$D3
  DEFB $7F,$7B,$60,$88,$96,$15

; Message: go {1} from {0} to get to {0}
;
; go {1} from {0} to get to {0}
MSG_GO_FROM_TO_GET:
  DEFB $D2,$DE,$01,$6D,$00,$7B,$D2,$CE
  DEFB $7B,$00,$16

; Message: someone strangle you from behind.
;
; someone strangle you from behind.
MSG_SOMEONE_STRANGLE_YOU:
  DEFB $8A,$E3,$CB,$26,$7F,$6D,$B8,$25

; Message: {7} say S   " no   "
;
; {7} say S   " no   "
MSG_SAY_S_NO:
  DEFB $07,$85,$84,$53,$20,$22,$FA,$52
  DEFB $20,$22,$14

; Message: it cannot be see N , cannot be felt {13} cannot be hear , ca
;
; it cannot be see N , cannot be felt {13} cannot be hear , cannot be smelt .
; {13} it lie behind star and under hills , {13} and empty hole S it fill .
; {13} it come first and follow after , {13} end life , kill laughter .
MSG_IT_CANNOT_BE_SEE:
  DEFB $72,$67,$64,$76,$4E,$2C,$67,$64
  DEFB $89,$15,$0D,$F0,$EE,$64,$C9,$85
  DEFB $2C,$67,$64,$8A,$DE,$2E,$0D,$F3
  DEFB $9E,$C9,$DB,$88,$25,$CB,$0F,$61
  DEFB $8B,$9B,$83,$42,$2C,$0D,$F0,$5B
  DEFB $D2,$28,$83,$5D,$53,$72,$C2,$61
  DEFB $2E,$0D,$F3,$9E,$C8,$71,$89,$1C
  DEFB $61,$C2,$85,$80,$49,$2C,$0D,$C8
  DEFB $D5,$89,$DF,$2C,$C3,$A8,$89,$D3
  DEFB $2E,$16

; Message: blimey , look at this ! ! can yer cook ' E M ?
;
; blimey , look at this ! ! can yer cook ' E M ?
MSG_BLIMEY_LOOK_AT_THIS:
  DEFB $88,$38,$2C,$84,$13,$63,$7A,$21
  DEFB $21,$F0,$EB,$8B,$E7,$88,$8B,$27
  DEFB $45,$4D,$3F,$16

; Message: yer can try , but he would N ' T make above a mouthfull
;
; yer can try , but he would N ' T make above a mouthfull
MSG_YER_CAN_TRY_BUT:
  DEFB $8B,$E7,$80,$EB,$8B,$90,$2C,$66
  DEFB $89,$82,$8B,$E2,$4E,$27,$54,$89
  DEFB $F9,$87,$B5,$60,$AA,$3E

; Message: in a clearing with two stone trolls
;
; in a clearing with two stone trolls
MSG_IN_A_CLEARING_WITH:
  DEFB $70,$60,$81,$27,$7E,$8B,$98,$86
  DEFB $41,$A6,$FD

; Message: {16} swept forcefully against the portcullis.
;
; {16} swept forcefully against the portcullis.
MSG_SWEPT_FORCEFULLY_AGAINST:
  DEFB $10,$8B,$46,$82,$92,$87,$C8,$78
  DEFB $B4,$F1

; Message: there is a loud crack and a hole appear about three feet fro
;
; there is a loud crack and a hole appear about three feet from the ground .
; {13} you are stand in front of the side door to the lonely mountain
MSG_THERE_IS_A_LOUD:
  DEFB $79,$71,$60,$89,$EC,$81,$51,$61
  DEFB $60,$83,$5D,$C7,$EA,$87,$B0,$8B
  DEFB $76,$82,$5D,$6D,$78,$89,$65,$2E
  DEFB $0D,$F7,$A8,$62,$CB,$0A,$70,$89
  DEFB $40,$74,$78,$85,$A6,$6A,$7B,$78
  DEFB $F4,$09,$F4,$4E,$15

; Message: the hole vanish
;
; the hole vanish
MSG_THE_HOLE_VANISH:
  DEFB $78,$83,$5D,$CB,$A3,$15

; Message: the magic door warn of elves approach
;
; the magic door warn of elves approach
MSG_THE_MAGIC_DOOR_WARN:
  DEFB $F6,$9F,$84,$24,$6A,$CB,$B4,$74
  DEFB $82,$1D,$C7,$F0,$15

; Message: which is the animal that has four feet in the morn , two at
;
; which is the animal that has four feet in the morn , two at midday and three
; in the evening   ?
MSG_WHICH_IS_THE_ANIMAL:
  DEFB $8B,$D1,$71,$78,$87,$E4,$86,$9B
  DEFB $89,$7B,$89,$3C,$82,$5D,$70,$78
  DEFB $CA,$3A,$2C,$8B,$98,$63,$8A,$1F
  DEFB $61,$8B,$76,$70,$78,$88,$EA,$20
  DEFB $3F,$16

; Message: what has it got in its pocket   ?
;
; what has it got in its pocket   ?
MSG_WHAT_HAS_IT_GOT:
  DEFB $7D,$89,$7B,$72,$89,$62,$70,$89
  DEFB $AB,$CA,$83,$20,$3F,$16

; Message: my birthday present   " how did we lose it . {13} my preciou
;
; my birthday present   " how did we lose it . {13} my precious   "
MSG_MY_BIRTHDAY_PRESENT_HOW:
  DEFB $8A,$4F,$88,$30,$8A,$98,$20,$22
  DEFB $89,$93,$88,$B4,$8B,$C1,$89,$E8
  DEFB $72,$2E,$0D,$8A,$4F,$8A,$89,$20
  DEFB $22,$16

; Message: {6} cannot jump onto {7} from here
;
; Used by the routine at JUMP_ONTO_BARREL.
;
; {6} cannot jump onto {7} from here
MSG_CANNOT_JUMP_ONTO_FROM:
  DEFB $06,$67,$83,$A1,$84,$B0,$07,$6D
  DEFB $6E,$15

; Message: day dawn ?.
;
; day dawn ?.
MSG_DAY_DAWN:
  DEFB $88,$9F,$C8,$9B,$B0,$00

; Message: {6} see some pale bulbous eyes star at {6}
;
; {6} see some pale bulbous eyes star at {6}
MSG_SEE_SOME_PALE_BULBOUS:
  DEFB $06,$76,$77,$8A,$70,$88,$54,$82
  DEFB $4B,$CB,$13,$63,$06,$15

; Message: some thin G drop from above and sting
;
; some thin G drop from above and sting
MSG_SOME_THIN_G_DROP:
  DEFB $77,$86,$B0,$47,$C1,$E8,$6D,$87
  DEFB $B5,$61,$CB,$21,$15

; Message: you are thrown onto the bank of the long lake.
;
; you are thrown onto the bank of the long lake.
MSG_YOU_ARE_THROWN_ONTO:
  DEFB $7F,$62,$8B,$7B,$84,$B0,$78,$88
  DEFB $1E,$74,$78,$84,$0F,$B3,$B7

; Message:           nothing
;
; nothing
MSG_NOTHING:
  DEFB $20,$20,$20,$20,$20,$EA,$5D

; Message: start   T A P E then   P R E S S   A N Y key.
;
; start   T A P E then   P R E S S   A N Y key.
MSG_START_T_A_P:
  DEFB $8B,$17,$20,$54,$41,$50,$45,$86
  DEFB $A2,$20,$50,$52,$45,$53,$53,$20
  DEFB $41,$4E,$59,$B3,$A5

; Message: T A P E   E R R O R   -         hit   A N Y key to   R E S T
;
; T A P E   E R R O R   -         hit   A N Y key to   R E S T A R T   P R O G
; R A M
MSG_T_A_P_E:
  DEFB $54,$41,$50,$45,$20,$45,$52,$52
  DEFB $4F,$52,$20,$2D,$20,$20,$20,$20
  DEFB $83,$47,$20,$41,$4E,$59,$83,$A5
  DEFB $7B,$20,$52,$45,$53,$54,$41,$52
  DEFB $54,$20,$50,$52,$4F,$47,$52,$41
  DEFB $4D,$15

; Message: T A P E   E R R O R   -         hit   A N Y key to   C O N T
;
; T A P E   E R R O R   -         hit   A N Y key to   C O N T I N U E
MSG_T_A_P_E_B:
  DEFB $54,$41,$50,$45,$20,$45,$52,$52
  DEFB $4F,$52,$20,$2D,$20,$20,$20,$20
  DEFB $83,$47,$20,$41,$4E,$59,$83,$A5
  DEFB $7B,$20,$43,$4F,$4E,$54,$49,$4E
  DEFB $55,$45,$15

; Message: R E W I N D and   P R E P A R E   T A P E for           V E
;
; R E W I N D and   P R E P A R E   T A P E for           V E R I F I C A T I O
; N     - - then hit   A N Y key.
MSG_R_E_W_I:
  DEFB $52,$45,$57,$49,$4E,$44,$61,$20
  DEFB $50,$52,$45,$50,$41,$52,$45,$20
  DEFB $54,$41,$50,$45,$82,$8F,$20,$20
  DEFB $20,$20,$20,$56,$45,$52,$49,$46
  DEFB $49,$43,$41,$54,$49,$4F,$4E,$20
  DEFB $20,$2D,$2D,$86,$A2,$83,$47,$20
  DEFB $41,$4E,$59,$B3,$A5

; Message: {13} {13} {13} a   C H E E R I N G   C R O W D of   D W A R
;
; {13} {13} {13} a   C H E E R I N G   C R O W D of   D W A R V E S ,   H O B B
; I T S and elves appear .   L E D by gandalf   T H E Y carry you off into the
; S U N S E T ,   P R O C L A I M I N G you     H E R O of   H E R O E S and M
; A S T E R   A D V E N T U R E R   ! ! !
MSG_A_C_H_E:
  DEFB $0D,$0D,$0D,$60,$20,$43,$48,$45
  DEFB $45,$52,$49,$4E,$47,$20,$43,$52
  DEFB $4F,$57,$44,$74,$20,$44,$57,$41
  DEFB $52,$56,$45,$53,$2C,$20,$48,$4F
  DEFB $42,$42,$49,$54,$53,$61,$82,$1D
  DEFB $C7,$EA,$2E,$20,$4C,$45,$44,$88
  DEFB $5B,$82,$BD,$20,$54,$48,$45,$59
  DEFB $81,$0D,$7F,$84,$9F,$83,$8E,$78
  DEFB $20,$53,$55,$4E,$53,$45,$54,$2C
  DEFB $20,$50,$52,$4F,$43,$4C,$41,$49
  DEFB $4D,$49,$4E,$47,$7F,$20,$20,$48
  DEFB $45,$52,$4F,$74,$20,$48,$45,$52
  DEFB $4F,$45,$53,$61,$20,$4D,$41,$53
  DEFB $54,$45,$52,$20,$41,$44,$56,$45
  DEFB $4E,$54,$55,$52,$45,$52,$20,$21
  DEFB $21,$21,$15

; Message: you have   M A S T E R E D
;
; you have   M A S T E R E D
MSG_YOU_HAVE_M_A:
  DEFB $7F,$89,$7E,$20,$4D,$41,$53,$54
  DEFB $45,$52,$45,$44,$20,$16

; Message: % of this adventure.
;
; % of this adventure.
MSG_OF_THIS_ADVENTURE:
  DEFB $25,$74,$7A,$B7,$BA

; Message:   Y O U ' R E   D O I N G   F I N E
;
; Y O U ' R E   D O I N G   F I N E
MSG_Y_O_U_R:
  DEFB $20,$59,$4F,$55,$27,$52,$45,$20
  DEFB $44,$4F,$49,$4E,$47,$20,$46,$49
  DEFB $4E,$45,$15

; Message: a trolls door   N E E D S a trolls key.
;
; a trolls door   N E E D S a trolls key.
MSG_A_TROLLS_DOOR_N:
  DEFB $60,$86,$FD,$81,$C0,$20,$4E,$45
  DEFB $45,$44,$53,$60,$86,$FD,$B3,$A5

; Message: elves are   G O O D at read I N G symbols.
;
; elves are   G O O D at read I N G symbols.
MSG_ELVES_ARE_G_O:
  DEFB $82,$1D,$62,$20,$47,$4F,$4F,$44
  DEFB $63,$85,$30,$49,$4E,$47,$B6,$85

; Message: a window   S H O U L D be no   O B S T A C L E to a thief wi
;
; a window   S H O U L D be no   O B S T A C L E to a thief with   F R I E N D
; S
MSG_A_WINDOW_S_H:
  DEFB $60,$87,$8C,$20,$53,$48,$4F,$55
  DEFB $4C,$44,$64,$8A,$52,$20,$4F,$42
  DEFB $53,$54,$41,$43,$4C,$45,$7B,$60
  DEFB $86,$AB,$7E,$20,$46,$52,$49,$45
  DEFB $4E,$44,$53,$15

; Message: boat S can help . look carefully.
;
; boat S can help . look carefully.
MSG_BOAT_S_CAN_HELP:
  DEFB $80,$B8,$53,$80,$EB,$83,$1E,$2E
  DEFB $F4,$13,$B0,$FD

; Message: wait around and time your   E X I T carefully.
;
; wait around and time your   E X I T carefully.
MSG_WAIT_AROUND_AND_TIME:
  DEFB $87,$56,$87,$F8,$61,$8B,$87,$8B
  DEFB $EA,$20,$45,$58,$49,$54,$B0,$FD

; Message:   T I M I N G is   C R I T I C A L ,   R E M E M B E R barre
;
; T I M I N G is   C R I T I C A L ,   R E M E M B E R barrel S float.
MSG_T_I_M_I:
  DEFB $20,$54,$49,$4D,$49,$4E,$47,$71
  DEFB $20,$43,$52,$49,$54,$49,$43,$41
  DEFB $4C,$2C,$20,$52,$45,$4D,$45,$4D
  DEFB $42,$45,$52,$80,$84,$53,$B9,$26

; Message: wait a   W H I L E
;
; wait a   W H I L E
MSG_WAIT_A_W_H:
  DEFB $87,$56,$60,$20,$57,$48,$49,$4C
  DEFB $45,$15

; Message: take   C A R E to leave at the   R I G H T time.
;
; take   C A R E to leave at the   R I G H T time.
MSG_TAKE_C_A_R:
  DEFB $86,$8C,$20,$43,$41,$52,$45,$7B
  DEFB $83,$C4,$63,$78,$20,$52,$49,$47
  DEFB $48,$54,$BB,$87

; Message: a   L I V I N G dragon is   D E A D L Y , look to bard.
;
; a   L I V I N G dragon is   D E A D L Y , look to bard.
MSG_A_L_I_V:
  DEFB $60,$20,$4C,$49,$56,$49,$4E,$47
  DEFB $6B,$71,$20,$44,$45,$41,$44,$4C
  DEFB $59,$2C,$84,$13,$7B,$B0,$80

; Message:   D O N ' T   S T A Y here too long.
;
; D O N ' T   S T A Y here too long.
MSG_D_O_N_T:
  DEFB $20,$44,$4F,$4E,$27,$54,$20,$53
  DEFB $54,$41,$59,$6E,$7C,$B4,$0F

; Message: wait for the   N E W day   D A W N I N G
;
; wait for the   N E W day   D A W N I N G
MSG_WAIT_FOR_THE_N:
  DEFB $87,$56,$82,$8F,$78,$20,$4E,$45
  DEFB $57,$88,$9F,$20,$44,$41,$57,$4E
  DEFB $49,$4E,$47,$15

; Message: there seem to be some symbols on it but {6} cannot read them
;
; there seem to be some symbols on it but {6} cannot read them.
MSG_THERE_SEEM_TO_BE:
  DEFB $79,$DA,$B2,$7B,$64,$77,$86,$85
  DEFB $75,$72,$66,$06,$67,$85,$30,$BB
  DEFB $5D

; Message: you see a fast flowing black river not very wide across.
;
; you see a fast flowing black river not very wide across.
MSG_YOU_SEE_A_FAST:
  DEFB $7F,$76,$60,$82,$53,$82,$7E,$80
  DEFB $A5,$85,$4A,$73,$87,$3D,$87,$7D
  DEFB $B0,$43

; Message: a comfortable tunnel like hall
;
; a comfortable tunnel like hall
MSG_A_COMFORTABLE_TUNNEL:
  DEFB $60,$81,$3F,$87,$03,$83,$DA,$A3
  DEFB $09

; Message: a gloomy empty land with dreary hills ahead
;
; a gloomy empty land with dreary hills ahead
MSG_A_GLOOMY_EMPTY_LAND:
  DEFB $60,$82,$D8,$82,$28,$83,$BB,$7E
  DEFB $81,$DD,$83,$42,$A7,$CF

; Message: a hidden path with trolls foot print S
;
; a hidden path with trolls foot print S
MSG_A_HIDDEN_PATH_WITH:
  DEFB $60,$83,$31,$84,$D4,$7E,$86,$FD
  DEFB $89,$31,$84,$FB,$53,$16

; Message: the trolls cave
;
; the trolls cave
MSG_THE_TROLLS_CAVE:
  DEFB $78,$86,$FD,$A1,$12

; Message: a hard dangerous path in the misty mountains
;
; a hard dangerous path in the misty mountains
MSG_A_HARD_DANGEROUS_PATH:
  DEFB $60,$83,$16,$81,$85,$84,$D4,$70
  DEFB $78,$84,$40,$A4,$56

; Message: a narrow place with a dreadful drop into a dim valley
;
; a narrow place with a dreadful drop into a dim valley
MSG_A_NARROW_PLACE_WITH:
  DEFB $60,$84,$64,$D4,$E6,$7E,$60,$81
  DEFB $D5,$81,$E8,$83,$8E,$60,$88,$B7
  DEFB $A7,$2F

; Message: a narrow dangerous path
;
; a narrow dangerous path
MSG_A_NARROW_DANGEROUS_PATH:
  DEFB $60,$84,$64,$81,$85,$A4,$D4

; Message: a large dry cave which is quite comfortable
;
; a large dry cave which is quite comfortable
MSG_A_LARGE_DRY_CAVE:
  DEFB $60,$83,$BF,$81,$EC,$81,$12,$8B
  DEFB $D1,$71,$85,$1C,$A1,$3F

; Message: a big cavern with torch E S along the wall S
;
; a big cavern with torch E S along the wall S
MSG_A_BIG_CAVERN_WITH:
  DEFB $60,$80,$A2,$81,$16,$7E,$86,$D7
  DEFB $45,$53,$87,$DF,$78,$87,$5A,$53
  DEFB $16

; Message: the brink of a deep dark under ground lake
;
; the brink of a deep dark under ground lake
MSG_THE_BRINK_OF_A:
  DEFB $78,$88,$46,$74,$60,$81,$96,$81
  DEFB $8E,$8B,$9B,$89,$65,$A3,$B7

; Message: the goblins gate
;
; the goblins gate
MSG_THE_GOBLINS_GATE:
  DEFB $78,$82,$E8,$A2,$C4

; Message: the gate to mirkwood
;
; the gate to mirkwood
MSG_THE_GATE_TO_MIRKWOOD:
  DEFB $78,$82,$C4,$7B,$A4,$38

; Message: a bewitched gloomy place surrounded by thick tree ?
;
; a bewitched gloomy place surrounded by thick tree ?
MSG_A_BEWITCHED_GLOOMY_PLACE:
  DEFB $60,$80,$99,$82,$D8,$84,$E6,$8B
  DEFB $36,$88,$5B,$86,$A6,$C6,$EC,$A0
  DEFB $00

; Message: a place of black spider S
;
; a place of black spider S
MSG_A_PLACE_OF_BLACK:
  DEFB $60,$84,$E6,$74,$80,$A5,$86,$23
  DEFB $53,$16

; Message: a forest of tangled smothering tree
;
; a forest of tangled smothering tree
MSG_A_FOREST_OF_TANGLED:
  DEFB $60,$82,$A0,$74,$86,$94,$85,$F3
  DEFB $C6,$EC,$16

; Message: a N elvish clearing with levelled ground and logs
;
; a N elvish clearing with levelled ground and logs
MSG_A_N_ELVISH_CLEARING:
  DEFB $60,$4E,$82,$22,$81,$27,$7E,$83
  DEFB $CC,$89,$65,$61,$A3,$FC

; Message: a dark dungeon in the elvenkings halls
;
; a dark dungeon in the elvenkings halls
MSG_A_DARK_DUNGEON_IN:
  DEFB $60,$81,$8E,$81,$EF,$70,$78,$82
  DEFB $13,$A3,$0D

; Message: the cellar where the king keeps his barrel S of wine
;
; the cellar where the king keeps his barrel S of wine
MSG_THE_CELLAR_WHERE_THE:
  DEFB $78,$81,$1C,$8B,$CC,$78,$83,$AE
  DEFB $89,$BA,$89,$90,$80,$84,$53,$74
  DEFB $A7,$92

; Message: a wooden town in the middle of long lake
;
; a wooden town in the middle of long lake
MSG_A_WOODEN_TOWN_IN:
  DEFB $60,$87,$A2,$86,$DC,$70,$78,$8A
  DEFB $19,$74,$84,$0F,$A3,$B7

; Message: a strong river : the current is now too strong to move again
;
; a strong river : the current is now too strong to move against
MSG_A_STRONG_RIVER_THE:
  DEFB $60,$86,$64,$85,$4A,$3A,$78,$88
  DEFB $8F,$71,$8A,$64,$7C,$86,$64,$7B
  DEFB $8A,$47,$A7,$C8

; Message: a bleak barren land that was once green
;
; a bleak barren land that was once green
MSG_A_BLEAK_BARREN_LAND:
  DEFB $60,$80,$AA,$80,$8A,$83,$BB,$86
  DEFB $9B,$8B,$B8,$8A,$67,$A3,$04

; Message: the ruins of the town of dale
;
; the ruins of the town of dale
MSG_THE_RUINS_OF_THE:
  DEFB $78,$85,$67,$74,$78,$86,$DC,$74
  DEFB $A1,$81

; Message: the front gate of the lonely mountain
;
; the front gate of the lonely mountain
MSG_THE_FRONT_GATE_OF:
  DEFB $78,$89,$40,$82,$C4,$74,$78,$84
  DEFB $09,$A4,$4E

; Message: the west side of ravenhill
;
; the west side of ravenhill
MSG_THE_WEST_SIDE_OF:
  DEFB $78,$87,$79,$85,$A6,$74,$A5,$21

; Message: the halls where the dragon sleep
;
; the halls where the dragon sleep
MSG_THE_HALLS_WHERE_THE:
  DEFB $78,$83,$0D,$8B,$CC,$78,$6B,$C5
  DEFB $CA,$16

; Message: a little steep bay , still and quiet , with an over hanging
;
; a little steep bay , still and quiet , with an over hanging cliff
MSG_A_LITTLE_STEEP_BAY:
  DEFB $60,$83,$E3,$86,$3C,$80,$90,$2C
  DEFB $8B,$1C,$61,$85,$13,$2C,$7E,$80
  DEFB $58,$84,$C9,$89,$74,$A8,$6C

; Message: a smooth straight passage
;
; a smooth straight passage
MSG_A_SMOOTH_STRAIGHT:
  DEFB $60,$85,$ED,$86,$46,$A4,$CD

; Message: the lonely mountain
;
; the lonely mountain
MSG_THE_LONELY_MOUNTAIN:
  DEFB $78,$84,$09,$A4,$4E

; Message: the west {jump +4} the east bank of a black river
;
; the west {jump +4} the east bank of a black river
;
; Also entered at MSG_THE_EAST_BANK_OF (a tail): the east bank of a black river
MSG_THE_WEST_THE_EAST:
  DEFB $78,$87,$79,$02,$04
MSG_THE_EAST_BANK_OF:
  DEFB $78,$81,$FE,$88,$1E,$74,$60,$80
  DEFB $A5,$A5,$4A

; The game's variables
;
; The working state, from here to ENDINGS. The part from SAVED_STATE to
; PICTURES_ON is the game's own -- where things stand, the score, the riddle,
; the map -- and is what START keeps a copy of for a new game and SAVE writes
; to tape; the rest is scratch for the parser, the printer and the action in
; hand. DRUNK, at DRUNK, and ACTOR, at ACTOR, have blocks of their own.
VARIABLES:
  DEFB $00,$00            ; Where the last word began in the input, echoed back
                          ; when a word is not known
TOKEN_POINTER:
  DEFB $00,$00            ; The parser's place in TOKENS
LAST_CLASS:
  DEFB $00                ; The class of the last word, which the parser and
                          ; the special words go back to
NAME_FAILED:
  DEFB $00                ; Set by NAME_MATCHES; MATCH_PATTERN ends in
                          ; UNKNOWN_VERB when it is
IT_NAME:
  DEFB $00,$00,$00,$00,$00,$00 ; The last target's name, for IT
PARSED_ACTION:
  DEFB $00                ; The action code, a copy kept by PARSE_ACTION
ACTION:
  DEFB $00                ; The action code being carried out
TARGET:
  DEFB $00                ; Its first object, the target, or $FF
INSTRUMENT:
  DEFB $00                ; Its second object, the instrument, or $FF
ACTING:
  DEFB $00                ; Who is acting, and who the sentence is about: 0 for
                          ; the player
SAVED_STATE:
  DEFB $00,$00,$00        ; Scratch: DO_SAVE carries Bard's three script bytes
                          ; here. From here to PICTURES_ON is what START keeps
                          ; a copy of and SAVE writes
RIDDLE:
  DEFB $00,$00            ; This game's riddle, an entry in RIDDLES
TIMER_FIRED:
  DEFB $00                ; A timer has fired this turn
ROAD_OPEN:
  DEFB $00                ; Meant to say Elrond has put the shut road back, so
                          ; it is not done twice; cleared for each new game and
                          ; never set
TO_PRINTER:
  DEFB $00                ; PRINT is on: the story goes to the ZX Printer too
FOREST_ENTRY:
  DEFB $00                ; Where the player came into the forest, for the eyes
ORDER_WAITING:
  DEFB $00                ; The character acting has an order waiting
PLAYER_AT:
  DEFB $00                ; Where the player is
ACTOR_AT:
  DEFB $00                ; Where the character acting is
SCORE:
  DEFB $00,$00            ; The score, in tenths of a per cent
RIDDLE_ASKED:
  DEFB $00                ; Gollum is waiting for the answer to his riddle
DOING_IT:
  DEFB $00                ; For real: clear while an action is only being
                          ; tested, and nothing is printed
SUCCEEDED:
  DEFB $00                ; It worked: what a test, or a handler, answers
WEAPON_NAME:
  DEFB $00,$00            ; The weapon's name, or FIST, for the fight's
                          ; messages
TARGET_IS_PLACE:
  DEFB $00                ; The action's first object is a place
                          ; (PATTERN_OPTIONS)
INSTRUMENT_IS_PLACE:
  DEFB $00                ; The second object is a place: set by no action

; Whether the player has drunk the wine
;
; Cleared at the start of a game and set by WINE_DRUNK. While it is set,
; PRINT_CHAR follows every S with an H: after the wine, the Lonelands'
; description comes out as "a gloomy empty land with dreary hillsH ahead".
; Tried, not only read -- the wine was moved into Bag End, DRINK THE WINE
; answered "you drink some wine." and set this byte, and a message printed
; before and after shows the difference.
DRUNK:
  DEFB $00
INPUT_STYLE:
  DEFB $00                ; Print in the input window, in capitals; also set
                          ; while an action is refused
PRINTING_ON:
  DEFB $00                ; Printing on
NOUN_ONLY:
  DEFB $00                ; Names are printed as the noun alone
CAPITAL_NEXT:
  DEFB $00                ; The next letter printed is a capital
MORE_COMMANDS:
  DEFB $00                ; More commands are waiting in the line, after THEN
                          ; or a full stop
COMMAND_FRAMES:
  DEFB $FF                ; How many frames the command has taken
PICTURES_ON:
  DEFB $00                ; Pictures on: the N key held at the title screen
                          ; turns them off
TARGET_RECORD:
  DEFB $00,$00            ; The first object's record
INSTRUMENT_RECORD:
  DEFB $00,$00            ; The second object's record

; Whose turn it is, and the rest of the variables
;
; The address of the acting character's object record. MOVE, ACTOR_ROOM and the
; rest read the actor through here rather than assuming the player, which is
; why one MOVE serves the whole cast.
ACTOR:
  DEFB $1B,$C1            ; The acting character's record (ACTOR)
RANDOM_LAST:
  DEFB $00                ; RANDOM's last result
PATTERN_OPTION:
  DEFB $00                ; An option of the action's pattern, read by the
                          ; object matching
FIND_MODE:
  DEFB $00                ; FIND_NAMED_OBJECT's mode: which kinds of object
                          ; will do
NEEDS_LIGHT:
  DEFB $00                ; The action needs light at all (PATTERN_OPTIONS)
RANDOM_POINTER:
  DEFB $00,$00            ; RANDOM's pointer, stepping on through memory
PATIENCE:
  DEFB $00,$00            ; GET_KEY's patience before it types WAIT itself,
                          ; which adapts to the player
NO_PAUSE_LINES:
  DEFB $00                ; Lines of story to print without the end-of-line
                          ; pause
DICTIONARY_ENTRY:
  DEFB $00,$00            ; The dictionary entry TOKENISE is trying
ALL_EXCEPT:
  DEFB $00                ; ALL (1) or ALL ... EXCEPT (2) in the sentence being
                          ; parsed
QUESTION_WAITING:
  DEFB $00                ; A question is waiting for the next line to answer
IS_ORDER:
  DEFB $00                ; The sentence being parsed is an order said to
                          ; someone
ALL_ACTION:
  DEFB $00                ; ALL, for the action being carried out
FLAGS_FIRST_WORDS:
  DEFB $00                ; The action pattern's flags, from its first two
                          ; words (PATTERN_FLAGS)
FLAGS_LAST_WORDS:
  DEFB $00                ; The action pattern's flags, from its last two words

; The endings a word can be given
;
; Eight slots of four characters, chosen by bits 5-7 of a word's third
; dictionary byte when PRINT_WORD inflects it: "s" for fifty verbs, "es" for
; six (GO, CROSS, PUSH, SLASH, SMASH, TORCH), "ies", "d", "ing", and one worth
; a second look -- a backspace then "ies", which is how CARRY prints as
; CARRIES: the backspace takes the Y back off. Slots 6 and 7 would be read from
; ORDER_COUNT and ORDERS, which follow; no word in the dictionary asks for
; them, nor for 4 or 5. EMPTY is given plain "ies", which would print EMPTYIES
; if it were ever inflected; that has not been checked.
ENDINGS:
  DEFB $73,$00,$00,$00
  DEFB $65,$73,$00,$00
  DEFB $69,$65,$73,$00
  DEFB $08,$69,$65,$73
  DEFB $64,$00,$00,$00
  DEFB $69,$6E,$67,$00
ORDER_COUNT:
  DEFB $00                ; How many orders are waiting in ORDERS (see
                          ; ASSIGN_ORDERS)

; What the player has told the other characters to do
;
; Eight 25-byte slots, each the number of the character it is for followed by
; the command it was given, kept until the character's next turn.
; CHARACTERS_ACT carries out an order before the character's own script. START
; clears all 200 bytes.
ORDERS:
  DEFB $00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00

; The frames below COMMAND_FRAME
;
; Nineteen more 24-byte frames, laid out as COMMAND_FRAME is, for the further
; commands of a line: the parser builds each one a frame lower than the last
; (see COMMAND_FRAMES).
FRAMES:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
NEXT_FRAME:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; The frame straight below
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; COMMAND_FRAME, for a line's second
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; command

; The command being obeyed
;
; Twenty-four bytes, and further commands in the same line are built in the
; frames below it, NEXT_FRAME and down. Offset 0 is the verb, and bit 7 of its
; second byte marks a command with ALL; offset 2 an adverb or direction;
; offsets 4 and 14 two noun phrases of ten bytes each -- two prepositions, the
; noun, and two adjectives. Every word is stored as a two-byte reference, low
; byte first, articles are dropped altogether.
;
; Watched rather than taken on trust. PUT THE SMALL CURIOUS KEY IN THE WOODEN
; CHEST leaves PUT, then KEY with SMALL and CURIOUS, then IN with CHEST and
; WOODEN. VICIOUSLY ATTACK THE TROLL WITH THE SWORD leaves ATTACK and
; VICIOUSLY, TROLL, and WITH and SWORD. And the first noun phrase of the first
; is byte for byte bytes 8 to 13 of the key's own object record: a noun phrase
; is written in exactly the form objects are named in, so finding what the
; player means is a straight comparison.
COMMAND_FRAME:
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00

; Where each location's record is
;
; One 2-byte pointer per location, 0 to 79, indexed directly by GET_ROOM.
ROOM_POINTERS:
  DEFB $8A,$BA
  DEFB $97,$BA
  DEFB $D3,$BE
  DEFB $E4,$BE
  DEFB $A5,$BA
  DEFB $BC,$BA
  DEFB $D0,$BA
  DEFB $E1,$BA
  DEFB $F5,$BE
  DEFB $EF,$BA
  DEFB $00,$BB
  DEFB $17,$BB
  DEFB $2B,$BB
  DEFB $DA,$BC
  DEFB $3C,$BB
  DEFB $4D,$BB
  DEFB $6A,$BC
  DEFB $7E,$BC
  DEFB $8C,$BC
  DEFB $A0,$BC
  DEFB $C9,$BC
  DEFB $EB,$BC
  DEFB $FC,$BC
  DEFB $06,$BF
  DEFB $16,$BD
  DEFB $2A,$BD
  DEFB $3E,$BD
  DEFB $55,$BD
  DEFB $66,$BD
  DEFB $7A,$BD
  DEFB $88,$BD
  DEFB $9C,$BD
  DEFB $AD,$BD
  DEFB $C1,$BD
  DEFB $D5,$BD
  DEFB $EC,$BD
  DEFB $03,$BE
  DEFB $14,$BE
  DEFB $25,$BE
  DEFB $39,$BE
  DEFB $4D,$BE
  DEFB $61,$BE
  DEFB $75,$BE
  DEFB $89,$BE
  DEFB $9A,$BE
  DEFB $C2,$BE
  DEFB $B1,$BE
  DEFB $42,$BF
  DEFB $17,$BF
  DEFB $2B,$BF
  DEFB $4D,$BF
  DEFB $5E,$BF
  DEFB $61,$BB
  DEFB $75,$BB
  DEFB $83,$BB
  DEFB $9A,$BB
  DEFB $B1,$BB
  DEFB $BF,$BB
  DEFB $D3,$BB
  DEFB $EA,$BB
  DEFB $FB,$BB
  DEFB $0F,$BC
  DEFB $20,$BC
  DEFB $2E,$BC
  DEFB $42,$BC
  DEFB $56,$BC
  DEFB $72,$BF
  DEFB $83,$BF
  DEFB $94,$BF
  DEFB $A8,$BF
  DEFB $BC,$BF
  DEFB $CD,$BF
  DEFB $E1,$BF
  DEFB $F5,$BF
  DEFB $06,$C0
  DEFB $17,$C0
  DEFB $25,$C0
  DEFB $33,$C0
  DEFB $41,$C0
  DEFB $52,$C0

; How the player is placed in each kind of room
;
; Word references, picked by bits 1 to 3 of byte 0 of a room's record. Only
; five are needed: most rooms use IN, twenty ON and nine AT, and INSIDE and
; OUTSIDE are the two sides of the goblins' gate, locations 19 and 20. The room
; records follow straight on.
ROOM_PREPOSITIONS:
  DEFW $84C2              ; OUTSIDE
  DEFW $837B              ; INSIDE
  DEFW $8378              ; IN
  DEFW $84AA              ; ON
  DEFW $8070              ; AT

; Location 0: not a room
;
; An empty head and no real exits. Nothing walks it.
ROOM0:
  DEFB $FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF

; Location 1: tunnel like hall
;
; A 10-byte head -- lit, named tunnel like hall -- then its exits: east.
ROOM1:
  DEFB $84                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $A0                ; Capacity: holds 160
  DEFB $09,$13            ; Its name: HALL
  DEFB $03,$07            ; An adjective: TUNNEL
  DEFB $DA,$03            ; Another: LIKE
  DEFW MSG_A_COMFORTABLE_TUNNEL ; A longer description
ROOM1_EAST:
  DEFB $03,$05,$04        ; East through object 5 to location 4
  DEFB $FF                ; End of the exits

; Location 4: lonelands
;
; A 10-byte head -- lit, named lonelands -- then its exits: west, east, north,
; northeast.
ROOM4:
  DEFB $84                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $00,$04            ; Its name: LONELANDS
  DEFB $00,$00            ; No adjective
  DEFB $00,$00            ; No second adjective
  DEFW MSG_A_GLOOMY_EMPTY_LAND ; A longer description
  DEFB $04,$05,$01        ; West through object 5 to location 1
  DEFB $03,$00,$05        ; East to location 5
  DEFB $01,$00,$05        ; North to location 5
  DEFB $05,$00,$06        ; Northeast to location 6
  DEFB $FF                ; End of the exits

; Location 5: trolls clearing
;
; A 10-byte head -- lit, named trolls clearing -- then its exits: southwest,
; southeast, north.
ROOM5:
  DEFB $84                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $27,$01            ; Its name: CLEARING
  DEFB $FD,$06            ; An adjective: TROLLS
  DEFB $00,$00            ; No second adjective
ROOM5_DESCRIPTION:
  DEFW $0000              ; No longer description
  DEFB $08,$00,$04        ; Southwest to location 4
  DEFB $07,$00,$09        ; Southeast to location 9
  DEFB $01,$00,$06        ; North to location 6
  DEFB $FF                ; End of the exits

; Location 6: trolls path
;
; A 10-byte head -- lit, named trolls path -- then its exits: south, north.
ROOM6:
  DEFB $84                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $D4,$04            ; Its name: PATH
  DEFB $FD,$06            ; An adjective: TROLLS
  DEFB $00,$00            ; No second adjective
  DEFW MSG_A_HIDDEN_PATH_WITH ; A longer description
  DEFB $02,$00,$05        ; South to location 5
  DEFB $01,$01,$07        ; North through object 1 to location 7
  DEFB $FF                ; End of the exits

; Location 7: trolls cave
;
; A 10-byte head -- dark, named trolls cave -- then its exits: south.
ROOM7:
  DEFB $04                ; Flags: dark (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $12,$01            ; Its name: CAVE
  DEFB $FD,$06            ; An adjective: TROLLS
  DEFB $00,$00            ; No second adjective
  DEFW MSG_THE_TROLLS_CAVE ; A longer description
  DEFB $02,$01,$06        ; South through object 1 to location 6
  DEFB $FF                ; End of the exits

; Location 9: rivendell
;
; A 10-byte head -- lit, named rivendell -- then its exits: east, west.
ROOM9:
  DEFB $84                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $41,$85            ; Its name: RIVENDELL
  DEFB $00,$00            ; No adjective
  DEFB $00,$00            ; No second adjective
  DEFW $0000              ; No longer description
  DEFB $03,$00,$0A        ; East to location 10
  DEFB $04,$00,$05        ; West to location 5
  DEFB $FF                ; End of the exits

; Location 10: misty mountain
;
; A 10-byte head -- lit, named misty mountain -- then its exits: east, north,
; west, south.
ROOM10:
  DEFB $86                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $4E,$04            ; Its name: MOUNTAIN
  DEFB $40,$04            ; An adjective: MISTY
  DEFB $00,$00            ; No second adjective
  DEFW MSG_A_HARD_DANGEROUS_PATH ; A longer description
  DEFB $03,$00,$0B        ; East to location 11
  DEFB $01,$00,$44        ; North to location 68
  DEFB $04,$00,$09        ; West to location 9
  DEFB $02,$00,$49        ; South to location 73
  DEFB $FF                ; End of the exits

; Location 11: narrow place
;
; A 10-byte head -- lit, named narrow place -- then its exits: east, west,
; north.
ROOM11:
  DEFB $84                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $E6,$14            ; Its name: PLACE
  DEFB $64,$04            ; An adjective: NARROW
  DEFB $00,$00            ; No second adjective
  DEFW MSG_A_NARROW_PLACE_WITH ; A longer description
  DEFB $03,$00,$0C        ; East to location 12
  DEFB $04,$00,$0A        ; West to location 10
  DEFB $01,$00,$0E        ; North to location 14
  DEFB $FF                ; End of the exits

; Location 12: dangerous narrow path
;
; A 10-byte head -- lit, named dangerous narrow path -- then its exits: east,
; west.
ROOM12:
  DEFB $86                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $D4,$14            ; Its name: PATH
  DEFB $85,$01            ; An adjective: DANGEROUS
  DEFB $64,$04            ; Another: NARROW
  DEFW MSG_A_NARROW_DANGEROUS_PATH ; A longer description
  DEFB $03,$00,$16        ; East to location 22
  DEFB $04,$00,$0B        ; West to location 11
  DEFB $FF                ; End of the exits

; Location 14: large dry cave
;
; A 10-byte head -- dark, named large dry cave -- then its exits: down, south.
ROOM14:
  DEFB $04                ; Flags: dark (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $12,$11            ; Its name: CAVE
  DEFB $BF,$03            ; An adjective: LARGE
  DEFB $EC,$01            ; Another: DRY
  DEFW MSG_A_LARGE_DRY_CAVE ; A longer description
  DEFB $0A,$06,$0F        ; Down through object 6 to location 15
  DEFB $02,$00,$0B        ; South to location 11
  DEFB $FF                ; End of the exits

; Location 15: dark stuffy passage
;
; A 10-byte head -- dark, named dark stuffy passage -- then its exits: up,
; south, northeast.
ROOM15:
  DEFB $04                ; Flags: dark (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $CD,$04            ; Its name: PASSAGE
  DEFB $8E,$01            ; An adjective: DARK
  DEFB $6A,$06            ; Another: STUFFY
  DEFW $0000              ; No longer description
  DEFB $09,$06,$0E        ; Up through object 6 to location 14
  DEFB $02,$00,$34        ; South to location 52
  DEFB $05,$00,$3A        ; Northeast to location 58
  DEFB $FF                ; End of the exits

; Location 52: dark stuffy passage
;
; A 10-byte head -- dark, named dark stuffy passage -- then its exits: north,
; down, up.
ROOM52:
  DEFB $04                ; Flags: dark (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $CD,$04            ; Its name: PASSAGE
  DEFB $8E,$01            ; An adjective: DARK
  DEFB $6A,$06            ; Another: STUFFY
  DEFW $0000              ; No longer description
  DEFB $01,$00,$0F        ; North to location 15
  DEFB $0A,$00,$35        ; Down to location 53
  DEFB $09,$00,$36        ; Up to location 54
  DEFB $FF                ; End of the exits

; Location 53: dark stuffy passage
;
; A 10-byte head -- dark, named dark stuffy passage -- then its exits: up.
ROOM53:
  DEFB $04                ; Flags: dark (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $CD,$04            ; Its name: PASSAGE
  DEFB $8E,$01            ; An adjective: DARK
  DEFB $6A,$06            ; Another: STUFFY
  DEFW $0000              ; No longer description
  DEFB $09,$00,$34        ; Up to location 52
  DEFB $FF                ; End of the exits

; Location 54: dark stuffy passage
;
; A 10-byte head -- dark, named dark stuffy passage -- then its exits: down,
; southeast, south, southwest.
ROOM54:
  DEFB $04                ; Flags: dark (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $CD,$04            ; Its name: PASSAGE
  DEFB $8E,$01            ; An adjective: DARK
  DEFB $6A,$06            ; Another: STUFFY
  DEFW $0000              ; No longer description
  DEFB $0A,$00,$34        ; Down to location 52
  DEFB $07,$00,$37        ; Southeast to location 55
  DEFB $02,$00,$40        ; South to location 64
  DEFB $08,$00,$11        ; Southwest to location 17
  DEFB $FF                ; End of the exits

; Location 55: dark stuffy passage
;
; A 10-byte head -- dark, named dark stuffy passage -- then its exits: south,
; northeast, southwest, west.
ROOM55:
  DEFB $04                ; Flags: dark (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $CD,$04            ; Its name: PASSAGE
  DEFB $8E,$01            ; An adjective: DARK
  DEFB $6A,$06            ; Another: STUFFY
  DEFW $0000              ; No longer description
  DEFB $02,$00,$11        ; South to location 17
  DEFB $05,$00,$36        ; Northeast to location 54
  DEFB $08,$00,$3D        ; Southwest to location 61
  DEFB $04,$00,$3C        ; West to location 60
  DEFB $FF                ; End of the exits

; Location 56: dark stuffy passage
;
; A 10-byte head -- dark, named dark stuffy passage -- then its exits:
; southwest.
ROOM56:
  DEFB $04                ; Flags: dark (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $CD,$04            ; Its name: PASSAGE
  DEFB $8E,$01            ; An adjective: DARK
  DEFB $6A,$06            ; Another: STUFFY
  DEFW $0000              ; No longer description
  DEFB $08,$00,$3C        ; Southwest to location 60
  DEFB $FF                ; End of the exits

; Location 57: dark stuffy passage
;
; A 10-byte head -- dark, named dark stuffy passage -- then its exits: up,
; west, north.
ROOM57:
  DEFB $04                ; Flags: dark (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $CD,$04            ; Its name: PASSAGE
  DEFB $8E,$01            ; An adjective: DARK
  DEFB $6A,$06            ; Another: STUFFY
  DEFW $0000              ; No longer description
  DEFB $09,$00,$10        ; Up to location 16
  DEFB $04,$00,$41        ; West to location 65
  DEFB $01,$00,$3A        ; North to location 58
  DEFB $FF                ; End of the exits

; Location 58: dark stuffy passage
;
; A 10-byte head -- dark, named dark stuffy passage -- then its exits:
; southeast, east, south, up.
ROOM58:
  DEFB $04                ; Flags: dark (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $CD,$04            ; Its name: PASSAGE
  DEFB $8E,$01            ; An adjective: DARK
  DEFB $6A,$06            ; Another: STUFFY
  DEFW $0000              ; No longer description
  DEFB $07,$00,$3E        ; Southeast to location 62
  DEFB $03,$00,$0F        ; East to location 15
  DEFB $02,$00,$39        ; South to location 57
  DEFB $09,$00,$3B        ; Up to location 59
  DEFB $FF                ; End of the exits

; Location 59: dark stuffy passage
;
; A 10-byte head -- dark, named dark stuffy passage -- then its exits: down,
; south.
ROOM59:
  DEFB $04                ; Flags: dark (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $CD,$04            ; Its name: PASSAGE
  DEFB $8E,$01            ; An adjective: DARK
  DEFB $6A,$06            ; Another: STUFFY
  DEFW $0000              ; No longer description
  DEFB $0A,$00,$3A        ; Down to location 58
  DEFB $02,$00,$3C        ; South to location 60
  DEFB $FF                ; End of the exits

; Location 60: dark stuffy passage
;
; A 10-byte head -- dark, named dark stuffy passage -- then its exits:
; southeast, north, northwest.
ROOM60:
  DEFB $04                ; Flags: dark (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $CD,$04            ; Its name: PASSAGE
  DEFB $8E,$01            ; An adjective: DARK
  DEFB $6A,$06            ; Another: STUFFY
  DEFW $0000              ; No longer description
  DEFB $07,$00,$3D        ; Southeast to location 61
  DEFB $01,$00,$3B        ; North to location 59
  DEFB $06,$00,$38        ; Northwest to location 56
  DEFB $FF                ; End of the exits

; Location 61: dark stuffy passage
;
; A 10-byte head -- dark, named dark stuffy passage -- then its exits: north,
; northwest.
ROOM61:
  DEFB $04                ; Flags: dark (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $CD,$04            ; Its name: PASSAGE
  DEFB $8E,$01            ; An adjective: DARK
  DEFB $6A,$06            ; Another: STUFFY
  DEFW $0000              ; No longer description
  DEFB $01,$00,$36        ; North to location 54
  DEFB $06,$00,$3C        ; Northwest to location 60
  DEFB $FF                ; End of the exits

; Location 62: dark stuffy passage
;
; A 10-byte head -- dark, named dark stuffy passage -- then its exits: east.
ROOM62:
  DEFB $04                ; Flags: dark (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $CD,$04            ; Its name: PASSAGE
  DEFB $8E,$01            ; An adjective: DARK
  DEFB $6A,$06            ; Another: STUFFY
  DEFW $0000              ; No longer description
  DEFB $03,$00,$3D        ; East to location 61
  DEFB $FF                ; End of the exits

; Location 63: dark stuffy passage
;
; A 10-byte head -- dark, named dark stuffy passage -- then its exits: up,
; north, east.
ROOM63:
  DEFB $04                ; Flags: dark (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $CD,$04            ; Its name: PASSAGE
  DEFB $8E,$01            ; An adjective: DARK
  DEFB $6A,$06            ; Another: STUFFY
  DEFW $0000              ; No longer description
  DEFB $09,$00,$40        ; Up to location 64
  DEFB $01,$00,$12        ; North to location 18
  DEFB $03,$00,$3A        ; East to location 58
  DEFB $FF                ; End of the exits

; Location 64: dark stuffy passage
;
; A 10-byte head -- dark, named dark stuffy passage -- then its exits:
; northwest, west, southwest.
ROOM64:
  DEFB $04                ; Flags: dark (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $CD,$04            ; Its name: PASSAGE
  DEFB $8E,$01            ; An adjective: DARK
  DEFB $6A,$06            ; Another: STUFFY
  DEFW $0000              ; No longer description
  DEFB $06,$00,$41        ; Northwest to location 65
  DEFB $04,$00,$36        ; West to location 54
  DEFB $08,$00,$3F        ; Southwest to location 63
  DEFB $FF                ; End of the exits

; Location 65: dark stuffy passage
;
; A 10-byte head -- dark, named dark stuffy passage -- then its exits: north,
; southeast, east.
ROOM65:
  DEFB $04                ; Flags: dark (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $CD,$04            ; Its name: PASSAGE
  DEFB $8E,$01            ; An adjective: DARK
  DEFB $6A,$06            ; Another: STUFFY
  DEFW $0000              ; No longer description
  DEFB $01,$00,$40        ; North to location 64
  DEFB $07,$00,$39        ; Southeast to location 57
  DEFB $03,$00,$13        ; East to location 19
  DEFB $FF                ; End of the exits

; Location 16: big goblins cavern
;
; A 10-byte head -- dark, named big goblins cavern -- then its exits: down,
; northeast, southeast.
ROOM16:
  DEFB $04                ; Flags: dark (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $16,$01            ; Its name: CAVERN
  DEFB $A2,$00            ; An adjective: BIG
  DEFB $E8,$02            ; Another: GOBLINS
  DEFW MSG_A_BIG_CAVERN_WITH ; A longer description
  DEFB $0A,$00,$39        ; Down to location 57
  DEFB $05,$00,$12        ; Northeast to location 18
  DEFB $07,$11,$0D        ; Southeast through object 17 to location 13
  DEFB $FF                ; End of the exits

; Location 17: deep dark lake
;
; A 10-byte head -- dark, named deep dark lake -- then its exits: north.
ROOM17:
  DEFB $08                ; Flags: dark (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $B7,$03            ; Its name: LAKE
  DEFB $96,$01            ; An adjective: DEEP
  DEFB $8E,$01            ; Another: DARK
  DEFW MSG_THE_BRINK_OF_A ; A longer description
  DEFB $01,$00,$37        ; North to location 55
  DEFB $FF                ; End of the exits

; Location 18: dark winding passage
;
; A 10-byte head -- dark, named dark winding passage -- then its exits:
; southwest, southeast, north.
ROOM18:
  DEFB $04                ; Flags: dark (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $CD,$04            ; Its name: PASSAGE
  DEFB $8E,$01            ; An adjective: DARK
  DEFB $85,$07            ; Another: WINDING
  DEFW $0000              ; No longer description
  DEFB $08,$00,$10        ; Southwest to location 16
  DEFB $07,$00,$3F        ; Southeast to location 63
  DEFB $01,$1B,$0D        ; North through object 27 to location 13
  DEFB $FF                ; End of the exits

; Location 19: inside goblins gate
;
; A 10-byte head -- dark, named inside goblins gate -- then its exits: west,
; north, south, up, east, southeast, southwest, down, northeast, northwest.
ROOM19:
  DEFB $02                ; Flags: dark (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $C4,$82            ; Its name: GATE
  DEFB $7B,$03            ; An adjective: INSIDE
  DEFB $E8,$02            ; Another: GOBLINS
  DEFW MSG_THE_GOBLINS_GATE ; A longer description
  DEFB $04,$00,$10        ; West to location 16
  DEFB $01,$00,$10        ; North to location 16
  DEFB $02,$00,$10        ; South to location 16
  DEFB $09,$0A,$14        ; Up through object 10 to location 20
  DEFB $03,$00,$10        ; East to location 16
  DEFB $07,$00,$10        ; Southeast to location 16
  DEFB $08,$00,$10        ; Southwest to location 16
  DEFB $0A,$00,$10        ; Down to location 16
  DEFB $05,$00,$41        ; Northeast to location 65
  DEFB $06,$00,$10        ; Northwest to location 16
  DEFB $FF                ; End of the exits

; Location 20: outside goblins gate
;
; A 10-byte head -- lit, named outside goblins gate -- then its exits: down,
; east.
ROOM20:
  DEFB $80                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $C4,$82            ; Its name: GATE
  DEFB $C2,$04            ; An adjective: OUTSIDE
  DEFB $E8,$02            ; Another: GOBLINS
  DEFW MSG_THE_GOBLINS_GATE ; A longer description
  DEFB $0A,$0A,$13        ; Down through object 10 to location 19
  DEFB $03,$00,$15        ; East to location 21
  DEFB $FF                ; End of the exits

; Location 13: goblins dungeon
;
; A 10-byte head -- dark, named goblins dungeon -- then its exits: north, west.
ROOM13:
  DEFB $04                ; Flags: dark (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $EF,$01            ; Its name: DUNGEON
  DEFB $E8,$02            ; An adjective: GOBLINS
  DEFB $00,$00            ; No second adjective
  DEFW $0000              ; No longer description
  DEFB $01,$11,$10        ; North through object 17 to location 16
  DEFB $04,$1B,$12        ; West through object 27 to location 18
  DEFB $FF                ; End of the exits

; Location 21: treeless opening
;
; A 10-byte head -- lit, named treeless opening -- then its exits: east, west.
ROOM21:
  DEFB $84                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $B8,$04            ; Its name: OPENING
  DEFB $F0,$06            ; An adjective: TREELESS
  DEFB $00,$00            ; No second adjective
  DEFW $0000              ; No longer description
  DEFB $03,$00,$16        ; East to location 22
  DEFB $04,$00,$14        ; West to location 20
  DEFB $FF                ; End of the exits

; Location 22: beorns house
;
; A 10-byte head -- lit, named beorns house -- then its exits: northeast,
; northwest, south, southwest, north.
ROOM22:
  DEFB $84                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $69,$83            ; Its name: HOUSE
  DEFB $93,$00            ; An adjective: BEORNS
  DEFB $00,$00            ; No second adjective
  DEFW $0000              ; No longer description
  DEFB $05,$00,$18        ; Northeast to location 24
  DEFB $06,$00,$14        ; Northwest to location 20
  DEFB $02,$00,$2E        ; South to location 46
  DEFB $08,$00,$0C        ; Southwest to location 12
  DEFB $01,$00,$31        ; North to location 49
  DEFB $FF                ; End of the exits

; Location 24: forest gate
;
; A 10-byte head -- lit, named forest gate -- then its exits: west, south,
; east.
ROOM24:
  DEFB $88                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $C4,$02            ; Its name: GATE
  DEFB $A0,$02            ; An adjective: FOREST
  DEFB $00,$00            ; No second adjective
  DEFW MSG_THE_GATE_TO_MIRKWOOD ; A longer description
  DEFB $04,$00,$16        ; West to location 22
  DEFB $02,$00,$2E        ; South to location 46
  DEFB $03,$00,$19        ; East to location 25
  DEFB $FF                ; End of the exits

; Location 25: bewitched gloomy place
;
; A 10-byte head -- lit, named bewitched gloomy place -- then its exits: west,
; east, south.
ROOM25:
  DEFB $84                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $E6,$04            ; Its name: PLACE
  DEFB $99,$00            ; An adjective: BEWITCHED
  DEFB $D8,$02            ; Another: GLOOMY
  DEFW $0000              ; No longer description
  DEFB $04,$00,$18        ; West to location 24
  DEFB $03,$00,$42        ; East to location 66
  DEFB $02,$09,$00        ; South through object 9 to nowhere yet: FIND_EXIT
                          ; passes over it until a location is written in
  DEFB $FF                ; End of the exits

; Location 26: spider threads place
;
; A 10-byte head -- lit, named spider threads place -- then its exits: east,
; west, north, south.
ROOM26:
  DEFB $84                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $E6,$04            ; Its name: PLACE
  DEFB $23,$06            ; An adjective: SPIDER
  DEFB $BA,$06            ; Another: THREADS
  DEFW MSG_A_PLACE_OF_BLACK ; A longer description
  DEFB $03,$07,$1D        ; East through object 7 to location 29
  DEFB $04,$07,$32        ; West through object 7 to location 50
  DEFB $01,$07,$1C        ; North through object 7 to location 28
  DEFB $02,$07,$1B        ; South through object 7 to location 27
  DEFB $FF                ; End of the exits

; Location 27: smothering forest
;
; A 10-byte head -- lit, named smothering forest -- then its exits: north,
; west.
ROOM27:
  DEFB $84                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $A0,$02            ; Its name: FOREST
  DEFB $F3,$05            ; An adjective: SMOTHERING
  DEFB $00,$00            ; No second adjective
  DEFW MSG_A_FOREST_OF_TANGLED ; A longer description
  DEFB $01,$07,$1A        ; North through object 7 to location 26
  DEFB $04,$07,$32        ; West through object 7 to location 50
  DEFB $FF                ; End of the exits

; Location 28: levelled elvish clearing
;
; A 10-byte head -- lit, named levelled elvish clearing -- then its exits:
; west, east, northeast.
ROOM28:
  DEFB $84                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $27,$11            ; Its name: CLEARING
  DEFB $CC,$03            ; An adjective: LEVELLED
  DEFB $22,$02            ; Another: ELVISH
  DEFW MSG_A_N_ELVISH_CLEARING ; A longer description
  DEFB $04,$00,$19        ; West to location 25
  DEFB $03,$07,$1A        ; East through object 7 to location 26
  DEFB $05,$0D,$1E        ; Northeast through object 13 to location 30
  DEFB $FF                ; End of the exits

; Location 29: deep bog
;
; A 10-byte head -- lit, named deep bog -- then its exits: west.
ROOM29:
  DEFB $84                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $BC,$00            ; Its name: BOG
  DEFB $96,$01            ; An adjective: DEEP
  DEFB $00,$00            ; No second adjective
  DEFW $0000              ; No longer description
  DEFB $04,$07,$1A        ; West through object 7 to location 26
  DEFB $FF                ; End of the exits

; Location 30: elvenkings great halls
;
; A 10-byte head -- dark, named elvenkings great halls -- then its exits: east,
; south, west.
ROOM30:
  DEFB $04                ; Flags: dark (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $0D,$03            ; Its name: HALLS
  DEFB $13,$02            ; An adjective: ELVENKINGS
  DEFB $FF,$02            ; Another: GREAT
  DEFW $0000              ; No longer description
  DEFB $03,$08,$1F        ; East through object 8 to location 31
  DEFB $02,$00,$20        ; South to location 32
  DEFB $04,$0D,$1C        ; West through object 13 to location 28
  DEFB $FF                ; End of the exits

; Location 31: dark dungeon
;
; A 10-byte head -- dark, named dark dungeon -- then its exits: southwest,
; west.
ROOM31:
  DEFB $04                ; Flags: dark (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $EF,$11            ; Its name: DUNGEON
  DEFB $8E,$01            ; An adjective: DARK
  DEFB $00,$00            ; No second adjective
  DEFW MSG_A_DARK_DUNGEON_IN ; A longer description
  DEFB $08,$08,$20        ; Southwest through object 8 to location 32
  DEFB $04,$08,$1E        ; West through object 8 to location 30
  DEFB $FF                ; End of the exits

; Location 32: elvenkings cellar
;
; A 10-byte head -- dark, named elvenkings cellar -- then its exits: northeast,
; north, down.
ROOM32:
  DEFB $04                ; Flags: dark (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $1C,$01            ; Its name: CELLAR
  DEFB $13,$02            ; An adjective: ELVENKINGS
  DEFB $00,$00            ; No second adjective
  DEFW MSG_THE_CELLAR_WHERE_THE ; A longer description
  DEFB $05,$08,$1F        ; Northeast through object 8 to location 31
  DEFB $01,$00,$1E        ; North to location 30
  DEFB $0A,$0C,$21        ; Down through object 12 to location 33
  DEFB $FF                ; End of the exits

; Location 33: forestriver
;
; A 10-byte head -- lit, named forestriver -- then its exits: east, up, south.
ROOM33:
  DEFB $88                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $A6,$82            ; Its name: FORESTRIVER
  DEFB $00,$00            ; No adjective
  DEFB $00,$00            ; No second adjective
  DEFW $0000              ; No longer description
  DEFB $03,$27,$22        ; East through object 39 to location 34
  DEFB $09,$0C,$00        ; Up through object 12 to nowhere yet: FIND_EXIT
                          ; passes over it until a location is written in
  DEFB $02,$2A,$00        ; South through object 42 to nowhere yet: FIND_EXIT
                          ; passes over it until a location is written in
  DEFB $FF                ; End of the exits

; Location 34: long lake
;
; A 10-byte head -- lit, named long lake -- then its exits: north, east,
; northwest, south.
ROOM34:
  DEFB $88                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $B7,$83            ; Its name: LAKE
  DEFB $0F,$04            ; An adjective: LONG
  DEFB $00,$00            ; No second adjective
  DEFW $0000              ; No longer description
  DEFB $01,$00,$24        ; North to location 36
  DEFB $03,$00,$23        ; East to location 35
  DEFB $06,$27,$21        ; Northwest through object 39 to location 33
  DEFB $02,$00,$2D        ; South to location 45
  DEFB $FF                ; End of the exits

; Location 35: lake town
;
; A 10-byte head -- lit, named lake town -- then its exits: north, south, east,
; west.
ROOM35:
  DEFB $84                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $DC,$86            ; Its name: TOWN
  DEFB $B7,$03            ; An adjective: LAKE
  DEFB $00,$00            ; No second adjective
  DEFW MSG_A_WOODEN_TOWN_IN ; A longer description
  DEFB $01,$00,$22        ; North to location 34
  DEFB $02,$00,$22        ; South to location 34
  DEFB $03,$00,$22        ; East to location 34
  DEFB $04,$00,$22        ; West to location 34
  DEFB $FF                ; End of the exits

; Location 36: running river
;
; A 10-byte head -- lit, named running river -- then its exits: up, south.
ROOM36:
  DEFB $86                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $4A,$85            ; Its name: RIVER
  DEFB $70,$05            ; An adjective: RUNNING
  DEFB $00,$00            ; No second adjective
  DEFW MSG_A_STRONG_RIVER_THE ; A longer description
  DEFB $09,$00,$25        ; Up to location 37
  DEFB $02,$00,$22        ; South to location 34
  DEFB $FF                ; End of the exits

; Location 37: dragons desolation
;
; A 10-byte head -- lit, named dragons desolation -- then its exits: north,
; down.
ROOM37:
  DEFB $84                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $9F,$01            ; Its name: DESOLATION
  DEFB $CE,$01            ; An adjective: DRAGONS
  DEFB $00,$00            ; No second adjective
  DEFW MSG_A_BLEAK_BARREN_LAND ; A longer description
  DEFB $01,$00,$26        ; North to location 38
  DEFB $0A,$00,$24        ; Down to location 36
  DEFB $FF                ; End of the exits

; Location 38: dale valley
;
; A 10-byte head -- lit, named dale valley -- then its exits: north, south,
; northwest.
ROOM38:
  DEFB $84                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $2F,$87            ; Its name: VALLEY
  DEFB $81,$01            ; An adjective: DALE
  DEFB $00,$00            ; No second adjective
  DEFW MSG_THE_RUINS_OF_THE ; A longer description
  DEFB $01,$00,$27        ; North to location 39
  DEFB $02,$00,$25        ; South to location 37
  DEFB $06,$00,$28        ; Northwest to location 40
  DEFB $FF                ; End of the exits

; Location 39: front gate
;
; A 10-byte head -- lit, named front gate -- then its exits: north, south,
; west.
ROOM39:
  DEFB $88                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $C4,$02            ; Its name: GATE
  DEFB $40,$09            ; An adjective: FRONT
  DEFB $00,$00            ; No second adjective
  DEFW MSG_THE_FRONT_GATE_OF ; A longer description
  DEFB $01,$00,$29        ; North to location 41
  DEFB $02,$00,$26        ; South to location 38
  DEFB $04,$00,$28        ; West to location 40
  DEFB $FF                ; End of the exits

; Location 40: ravenhill
;
; A 10-byte head -- lit, named ravenhill -- then its exits: north, southeast,
; east.
ROOM40:
  DEFB $86                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $21,$85            ; Its name: RAVENHILL
  DEFB $00,$00            ; No adjective
  DEFB $00,$00            ; No second adjective
  DEFW MSG_THE_WEST_SIDE_OF ; A longer description
  DEFB $01,$00,$2A        ; North to location 42
  DEFB $07,$00,$25        ; Southeast to location 37
  DEFB $03,$00,$27        ; East to location 39
  DEFB $FF                ; End of the exits

; Location 41: lower halls
;
; A 10-byte head -- lit, named lower halls -- then its exits: south, east, up.
ROOM41:
  DEFB $84                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $0D,$83            ; Its name: HALLS
  DEFB $1A,$04            ; An adjective: LOWER
  DEFB $00,$00            ; No second adjective
  DEFW MSG_THE_HALLS_WHERE_THE ; A longer description
  DEFB $02,$00,$27        ; South to location 39
  DEFB $03,$00,$2B        ; East to location 43
  DEFB $09,$00,$2C        ; Up to location 44
  DEFB $FF                ; End of the exits

; Location 42: sidedoor
;
; A 10-byte head -- lit, named sidedoor -- then its exits: south, east, north.
ROOM42:
  DEFB $84                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $AA,$05            ; Its name: SIDEDOOR
  DEFB $00,$00            ; No adjective
  DEFB $00,$00            ; No second adjective
  DEFW MSG_A_LITTLE_STEEP_BAY ; A longer description
  DEFB $02,$00,$28        ; South to location 40
  DEFB $03,$0B,$2B        ; East through object 11 to location 43
  DEFB $01,$00,$33        ; North to location 51
  DEFB $FF                ; End of the exits

; Location 43: smooth straight passage
;
; A 10-byte head -- dark, named smooth straight passage -- then its exits:
; west, east.
ROOM43:
  DEFB $04                ; Flags: dark (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $B0                ; Capacity: holds 176
  DEFB $CD,$14            ; Its name: PASSAGE
  DEFB $ED,$05            ; An adjective: SMOOTH
  DEFB $46,$06            ; Another: STRAIGHT
  DEFW MSG_A_SMOOTH_STRAIGHT ; A longer description
  DEFB $04,$0B,$2A        ; West through object 11 to location 42
  DEFB $03,$00,$29        ; East to location 41
  DEFB $FF                ; End of the exits

; Location 44: lonely mountain
;
; A 10-byte head -- lit, named lonely mountain -- then its exits: down, west,
; south, southwest.
ROOM44:
  DEFB $86                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $4E,$84            ; Its name: MOUNTAIN
  DEFB $09,$04            ; An adjective: LONELY
  DEFB $00,$00            ; No second adjective
  DEFW MSG_THE_LONELY_MOUNTAIN ; A longer description
  DEFB $0A,$00,$29        ; Down to location 41
  DEFB $04,$00,$2A        ; West to location 42
  DEFB $02,$00,$27        ; South to location 39
  DEFB $08,$00,$28        ; Southwest to location 40
  DEFB $FF                ; End of the exits

; Location 46: forest road
;
; A 10-byte head -- lit, named forest road -- then its exits: east, north.
ROOM46:
  DEFB $86                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $4F,$05            ; Its name: ROAD
  DEFB $A0,$02            ; An adjective: FOREST
  DEFB $00,$00            ; No second adjective
  DEFW $0000              ; No longer description
  DEFB $03,$00,$02        ; East to location 2
  DEFB $01,$00,$18        ; North to location 24
  DEFB $FF                ; End of the exits

; Location 45: waterfall
;
; A 10-byte head -- lit, named waterfall -- then its exits: south, west.
ROOM45:
  DEFB $88                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $63,$07            ; Its name: WATERFALL
  DEFB $00,$00            ; No adjective
  DEFB $00,$00            ; No second adjective
  DEFW $0000              ; No longer description
  DEFB $02,$00,$08        ; South to location 8
  DEFB $04,$00,$03        ; West to location 3
  DEFB $FF                ; End of the exits

; Location 2: forest road
;
; A 10-byte head -- lit, named forest road -- then its exits: east, west.
ROOM2:
  DEFB $86                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $4F,$05            ; Its name: ROAD
  DEFB $A0,$02            ; An adjective: FOREST
  DEFB $00,$00            ; No second adjective
  DEFW $0000              ; No longer description
  DEFB $03,$00,$03        ; East to location 3
  DEFB $04,$00,$2E        ; West to location 46
  DEFB $FF                ; End of the exits

; Location 3: forest
;
; A 10-byte head -- lit, named forest -- then its exits: west, east.
ROOM3:
  DEFB $84                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $A0,$02            ; Its name: FOREST
  DEFB $00,$00            ; No adjective
  DEFB $00,$00            ; No second adjective
  DEFW $0000              ; No longer description
  DEFB $04,$00,$02        ; West to location 2
  DEFB $03,$00,$2D        ; East to location 45
  DEFB $FF                ; End of the exits

; Location 8: running river
;
; A 10-byte head -- lit, named running river -- then its exits: north, west.
ROOM8:
  DEFB $88                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $4A,$05            ; Its name: RIVER
  DEFB $70,$05            ; An adjective: RUNNING
  DEFB $00,$00            ; No second adjective
  DEFW $0000              ; No longer description
  DEFB $01,$00,$2D        ; North to location 45
  DEFB $04,$00,$03        ; West to location 3
  DEFB $FF                ; End of the exits

; Location 23: forestriver
;
; A 10-byte head -- lit, named forestriver -- then its exits: southeast, north.
ROOM23:
  DEFB $88                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $A6,$82            ; Its name: FORESTRIVER
  DEFB $00,$00            ; No adjective
  DEFB $00,$00            ; No second adjective
  DEFW $0000              ; No longer description
  DEFB $07,$2A,$21        ; Southeast through object 42 to location 33
  DEFB $01,$00,$30        ; North to location 48
  DEFB $FF                ; End of the exits

; Location 48: mountains
;
; A 10-byte head -- lit, named mountains -- then its exits: southwest, east,
; southeast.
ROOM48:
  DEFB $86                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $56,$04            ; Its name: MOUNTAINS
  DEFB $00,$00            ; No adjective
  DEFB $00,$00            ; No second adjective
  DEFW $0000              ; No longer description
  DEFB $08,$00,$31        ; Southwest to location 49
  DEFB $03,$00,$2F        ; East to location 47
  DEFB $07,$00,$17        ; Southeast to location 23
  DEFB $FF                ; End of the exits

; Location 49: great river
;
; A 10-byte head -- lit, named great river -- then its exits: northeast, south,
; east, southwest.
ROOM49:
  DEFB $88                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $4A,$05            ; Its name: RIVER
  DEFB $FF,$02            ; An adjective: GREAT
  DEFB $00,$00            ; No second adjective
  DEFW $0000              ; No longer description
  DEFB $05,$00,$30        ; Northeast to location 48
  DEFB $02,$00,$16        ; South to location 22
  DEFB $03,$00,$18        ; East to location 24
  DEFB $08,$00,$0A        ; Southwest to location 10
  DEFB $FF                ; End of the exits

; Location 47: empty place
;
; A 10-byte head -- lit, named empty place -- then its exits: none.
ROOM47:
  DEFB $84                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FE                ; Capacity: holds 254
  DEFB $E6,$04            ; Its name: PLACE
  DEFB $28,$02            ; An adjective: EMPTY
  DEFB $00,$00            ; No second adjective
  DEFW $0000              ; No longer description
  DEFB $FF                ; End of the exits

; Location 50: green forest
;
; A 10-byte head -- lit, named green forest -- then its exits: northeast, west.
ROOM50:
  DEFB $84                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $A0,$02            ; Its name: FOREST
  DEFB $04,$03            ; An adjective: GREEN
  DEFB $00,$00            ; No second adjective
  DEFW $0000              ; No longer description
  DEFB $05,$07,$1A        ; Northeast through object 7 to location 26
  DEFB $04,$00,$43        ; West to location 67
  DEFB $FF                ; End of the exits

; Location 51: empty place
;
; A 10-byte head -- lit, named empty place -- then its exits: north, south, up.
ROOM51:
  DEFB $84                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $E6,$04            ; Its name: PLACE
  DEFB $28,$02            ; An adjective: EMPTY
  DEFB $00,$00            ; No second adjective
  DEFW $0000              ; No longer description
  DEFB $01,$00,$2F        ; North to location 47
  DEFB $02,$00,$2A        ; South to location 42
  DEFB $09,$00,$2C        ; Up to location 44
  DEFB $FF                ; End of the exits

; Location 66: west bank
;
; A 10-byte head -- lit, named west bank -- then its exits: west, east.
ROOM66:
  DEFB $86                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $1E,$08            ; Its name: BANK
  DEFB $79,$07            ; An adjective: WEST
  DEFB $00,$00            ; No second adjective
  DEFW MSG_THE_WEST_THE_EAST ; A longer description
  DEFB $04,$00,$19        ; West to location 25
  DEFB $03,$09,$43        ; East through object 9 to location 67
  DEFB $FF                ; End of the exits

; Location 67: east bank
;
; A 10-byte head -- lit, named east bank -- then its exits: east, west.
ROOM67:
  DEFB $86                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $1E,$08            ; Its name: BANK
  DEFB $FE,$01            ; An adjective: EAST
  DEFB $00,$00            ; No second adjective
  DEFW MSG_THE_EAST_BANK_OF ; A longer description
  DEFB $03,$00,$32        ; East to location 50
  DEFB $04,$09,$42        ; West through object 9 to location 66
  DEFB $FF                ; End of the exits

; Location 68: narrow path
;
; A 10-byte head -- lit, named narrow path -- then its exits: east, northeast,
; south.
ROOM68:
  DEFB $86                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $D4,$14            ; Its name: PATH
  DEFB $64,$04            ; An adjective: NARROW
  DEFB $00,$00            ; No second adjective
  DEFW $0000              ; No longer description
  DEFB $03,$00,$47        ; East to location 71
  DEFB $05,$00,$45        ; Northeast to location 69
  DEFB $02,$00,$0A        ; South to location 10
  DEFB $FF                ; End of the exits

; Location 69: narrow path
;
; A 10-byte head -- lit, named narrow path -- then its exits: north, southwest,
; south.
ROOM69:
  DEFB $86                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $D4,$14            ; Its name: PATH
  DEFB $64,$04            ; An adjective: NARROW
  DEFB $00,$00            ; No second adjective
  DEFW $0000              ; No longer description
  DEFB $01,$00,$46        ; North to location 70
  DEFB $08,$00,$44        ; Southwest to location 68
  DEFB $02,$00,$0A        ; South to location 10
  DEFB $FF                ; End of the exits

; Location 70: narrow path
;
; A 10-byte head -- lit, named narrow path -- then its exits: southeast, south.
ROOM70:
  DEFB $86                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $D4,$14            ; Its name: PATH
  DEFB $64,$04            ; An adjective: NARROW
  DEFB $00,$00            ; No second adjective
  DEFW $0000              ; No longer description
  DEFB $07,$00,$48        ; Southeast to location 72
  DEFB $02,$00,$45        ; South to location 69
  DEFB $FF                ; End of the exits

; Location 71: narrow path
;
; A 10-byte head -- lit, named narrow path -- then its exits: northwest, south,
; west.
ROOM71:
  DEFB $86                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $D4,$14            ; Its name: PATH
  DEFB $64,$04            ; An adjective: NARROW
  DEFB $00,$00            ; No second adjective
  DEFW $0000              ; No longer description
  DEFB $06,$00,$45        ; Northwest to location 69
  DEFB $02,$00,$4A        ; South to location 74
  DEFB $04,$00,$44        ; West to location 68
  DEFB $FF                ; End of the exits

; Location 72: narrow path
;
; A 10-byte head -- lit, named narrow path -- then its exits: northwest,
; southwest, down.
ROOM72:
  DEFB $86                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $D4,$14            ; Its name: PATH
  DEFB $64,$04            ; An adjective: NARROW
  DEFB $00,$00            ; No second adjective
  DEFW $0000              ; No longer description
  DEFB $06,$00,$46        ; Northwest to location 70
  DEFB $08,$00,$47        ; Southwest to location 71
  DEFB $0A,$00,$4B        ; Down to location 75
  DEFB $FF                ; End of the exits

; Location 73: narrow path
;
; A 10-byte head -- lit, named narrow path -- then its exits: east, north.
ROOM73:
  DEFB $86                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $D4,$14            ; Its name: PATH
  DEFB $64,$04            ; An adjective: NARROW
  DEFB $00,$00            ; No second adjective
  DEFW $0000              ; No longer description
  DEFB $03,$00,$4A        ; East to location 74
  DEFB $01,$00,$0A        ; North to location 10
  DEFB $FF                ; End of the exits

; Location 74: narrow path
;
; A 10-byte head -- lit, named narrow path -- then its exits: north, west.
ROOM74:
  DEFB $86                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $D4,$14            ; Its name: PATH
  DEFB $64,$04            ; An adjective: NARROW
  DEFB $00,$00            ; No second adjective
  DEFW $0000              ; No longer description
  DEFB $01,$00,$47        ; North to location 71
  DEFB $04,$00,$49        ; West to location 73
  DEFB $FF                ; End of the exits

; Location 75: steep path
;
; A 10-byte head -- lit, named steep path -- then its exits: down.
ROOM75:
  DEFB $86                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $D4,$14            ; Its name: PATH
  DEFB $3C,$06            ; An adjective: STEEP
  DEFB $00,$00            ; No second adjective
  DEFW $0000              ; No longer description
  DEFB $0A,$00,$4C        ; Down to location 76
  DEFB $FF                ; End of the exits

; Location 76: steep path
;
; A 10-byte head -- lit, named steep path -- then its exits: down.
ROOM76:
  DEFB $86                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $D4,$14            ; Its name: PATH
  DEFB $3C,$06            ; An adjective: STEEP
  DEFB $00,$00            ; No second adjective
  DEFW $0000              ; No longer description
  DEFB $0A,$00,$4D        ; Down to location 77
  DEFB $FF                ; End of the exits

; Location 77: steep path
;
; A 10-byte head -- lit, named steep path -- then its exits: down.
ROOM77:
  DEFB $86                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $D4,$14            ; Its name: PATH
  DEFB $3C,$06            ; An adjective: STEEP
  DEFB $00,$00            ; No second adjective
  DEFW $0000              ; No longer description
  DEFB $0A,$00,$4E        ; Down to location 78
  DEFB $FF                ; End of the exits

; Location 78: deep misty valley
;
; A 10-byte head -- lit, named deep misty valley -- then its exits: east, up.
ROOM78:
  DEFB $84                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $2F,$17            ; Its name: VALLEY
  DEFB $96,$01            ; An adjective: DEEP
  DEFB $40,$04            ; Another: MISTY
  DEFW $0000              ; No longer description
  DEFB $03,$00,$4F        ; East to location 79
  DEFB $09,$00,$4D        ; Up to location 77
  DEFB $FF                ; End of the exits

; Location 79: deep misty valley
;
; A 10-byte head -- lit, named deep misty valley -- then its exits: west, up.
ROOM79:
  DEFB $84                ; Flags: lit (bit 7), visited (bit 6), and how the
                          ; player is placed there (bits 1-3)
  DEFB $FF                ; Capacity: holds any amount
  DEFB $2F,$17            ; Its name: VALLEY
  DEFB $96,$01            ; An adjective: DEEP
  DEFB $40,$04            ; Another: MISTY
  DEFW $0000              ; No longer description
  DEFB $04,$00,$4E        ; West to location 78
  DEFB $09,$00,$4A        ; Up to location 74
  DEFB $FF                ; End of the exits

; Every object and every character, by number
;
; A FIND_RECORD table of 61 objects, whose values are the objects' own records.
; The keys come in two runs: $00 to $2B without a gap, then $3C to $4C. The
; second run is the characters -- every one of the nine seen wandering in a
; single turn had its number here, and ACTING, which says who a sentence is
; about, holds numbers from that same run. So a character is an object with a
; number in the upper block, not a separate kind of thing.
;
; Object 0 is the player: ACTING, which is zero when a sentence is about you,
; holds object numbers, and object 0's location is where the player is.
;
; A record is a 16-byte head, then the locations the object is in -- byte 0 of
; the head says how many -- then its own action handlers (see
; FIND_OBJECT_HANDLER). Watched rather than inferred: over several turns the
; one byte that changes in any character's record is the first of those
; locations, as it wanders; and when the player walked east out of Bag End and
; back, object 0's location went 1, 4, 1, matching at every step the location
; whose picture DRAW_LOCATION_PICTURE looked up. Most things are in one place;
; the ones in several are fixtures between rooms. Object 5 is in locations 1
; and 4 -- exactly the two rooms that walk went between, so it is the round
; green door.
;
; The head, as far as it is known. Byte 1 is what holds the object or has it
; inside, $FF for nothing: see SHUT_IN. Byte 2 is its size and byte 3 its
; weight, and for a character byte 3 is the most it can carry: the routine at
; CAN_LIFT compares a thing's weight and load with the actor's byte 3 and fails
; with "is too heavy to lift", the one at GIVE_TOO_MUCH with "you are carrying
; too much", and the one at DO_CLIMB_INTO_1 compares the actor's size with the
; room in the thing at byte 2 and fails with "you are too big". Doors, walls
; and fixtures are $FF in both. Bytes 14 and 15, where not zero, are the
; object's own description: the map's says there seem to be symbols on it that
; you cannot read, printed through RUN_MESSAGE. Byte 4's low four bits say how
; things are placed with this object, as PLACED_WORD prints it: 0 in, 1 on, 2
; behind (the curtain, which the wall is behind), 3 under (the trap door), 4
; tied to (the rope). Its bits 4 to 6 are sides (see SAME_SIDE): 1 for the
; player, Gandalf, Thorin and Bard; 2 for Gollum and the goblins; 4 for the
; wood elf and the butler; 5 for Elrond, on two; bit 7 is on the window alone.
; Byte 5 is strength and byte 6 defence, what DO_ATTACK weighs, and both wear
; down with wounds -- and a fall in the dark halves the player's strength.
;
; Byte 7, the flags. Bit 7: there, to be seen and reached -- IN_REACH wants it,
; and the only two objects without it are the mountains' side door, which is
; secret, and the butler. Bit 6: a character -- set on the player and the
; seventeen others, objects $3C to $4C, and on nothing else, and what
; FIND_NAMED_OBJECT's mode picks on. Bit 5: can be seen into, which SHUT_IN
; climbs through; the characters have it, and the goblins' cache and the wooden
; boat. Bit 1: a liquid -- exactly the wine and the four waters, and the
; rivers. Bit 2, on a container, is full: DRINK and EMPTY clear it, and FILL
; will not fill what has it. Bit 3 is dead, or broken: KILL sets it on a
; character, and a struck spider web has it until it is mended. Bit 4 gives
; light: it is on exactly the sword and the torch, and nothing else, as
; Wilderland also has it. Bits 2, 3 and 4 together are what TOO_DARK reads on
; the sword; the torch has the same flags. Bit 5 is also a door's being open:
; OPEN sets it and CLOSE clears it, and CAN_PASS will not let anyone through a
; way whose object has neither it nor bit 3. Bit 0 is locked: LOCK sets it and
; UNLOCK clears it, and it is on four doors to start with.
OBJECT_INDEX:
  DEFB $00                ; $00: you
  DEFW PLAYER
  DEFB $01                ; $01: heavy rock door
  DEFW HEAVY_ROCK_DOOR
  DEFB $02                ; $02: small curious key
  DEFW SMALL_CURIOUS_KEY
  DEFB $03                ; $03: curious map
  DEFW CURIOUS_MAP
  DEFB $04                ; $04: large key
  DEFW LARGE_KEY
  DEFB $05                ; $05: round green door
  DEFW ROUND_GREEN_DOOR
  DEFB $06                ; $06: small insignificant crack
  DEFW SMALL_INSIGNIFICANT_CRACK
  DEFB $07                ; $07: spider web
  DEFW SPIDER_WEB
  DEFB $08                ; $08: red door
  DEFW RED_DOOR
  DEFB $09                ; $09: fast black river
  DEFW FAST_BLACK_RIVER
  DEFB $0A                ; $0A: goblins back door
  DEFW GOBLINS_BACK_DOOR
  DEFB $0B                ; $0B: mountains side door
  DEFW MOUNTAINS_SIDE_DOOR
  DEFB $0C                ; $0C: large trap door
  DEFW LARGE_TRAP_DOOR
  DEFB $0D                ; $0D: magic door
  DEFW MAGIC_DOOR
  DEFB $0E                ; $0E: short strong sword
  DEFW SHORT_STRONG_SWORD
  DEFB $0F                ; $0F: red key
  DEFW RED_KEY
  DEFB $10                ; $10: valuable golden ring
  DEFW VALUABLE_GOLDEN_RING
  DEFB $11                ; $11: goblins door
  DEFW GOBLINS_DOOR
  DEFB $12                ; $12: rope
  DEFW ROPE
  DEFB $13                ; $13: barrel
  DEFW BARREL
  DEFB $14                ; $14: wine
  DEFW WINE
  DEFB $15                ; $15: water
  DEFW WATER
  DEFB $16                ; $16: black water
  DEFW BLACK_WATER
  DEFB $17                ; $17: water
  DEFW WATER_OBJ17
  DEFB $18                ; $18: black water
  DEFW BLACK_WATER_OBJ18
  DEFB $19                ; $19: bow
  DEFW BOW
  DEFB $1A                ; $1A: strong arrow
  DEFW STRONG_ARROW
  DEFB $1B                ; $1B: window
  DEFW WINDOW
  DEFB $1C                ; $1C: torch
  DEFW TORCH
  DEFB $1D                ; $1D: sand
  DEFW SAND
  DEFB $1E                ; $1E: trap door
  DEFW TRAP_DOOR
  DEFB $1F                ; $1F: goblins cache
  DEFW GOBLINS_CACHE
  DEFB $20                ; $20: heavy curtain
  DEFW HEAVY_CURTAIN
  DEFB $21                ; $21: large cupboard
  DEFW LARGE_CUPBOARD
  DEFB $22                ; $22: food
  DEFW FOOD
  DEFB $23                ; $23: valuable treasure
  DEFW VALUABLE_TREASURE
  DEFB $24                ; $24: wall
  DEFW WALL
  DEFB $25                ; $25: wooden chest
  DEFW WOODEN_CHEST
  DEFB $26                ; $26: lunch
  DEFW LUNCH
  DEFB $27                ; $27: strong portcullis
  DEFW STRONG_PORTCULLIS
  DEFB $28                ; $28: stone
  DEFW STONE
  DEFB $29                ; $29: wooden boat
  DEFW WOODEN_BOAT
  DEFB $2A                ; $2A: fast river
  DEFW FAST_RIVER
  DEFB $2B                ; $2B: golden key
  DEFW GOLDEN_KEY
  DEFB $3C                ; $3C: red golden dragon
  DEFW RED_GOLDEN_DRAGON
  DEFB $3D                ; $3D: nasty goblin
  DEFW NASTY_GOBLIN
  DEFB $3E                ; $3E: gandalf
  DEFW GANDALF
  DEFB $3F                ; $3F: thorin
  DEFW THORIN
  DEFB $40                ; $40: wood elf
  DEFW WOOD_ELF
  DEFB $41                ; $41: elrond
  DEFW ELROND
  DEFB $42                ; $42: butler
  DEFW BUTLER
  DEFB $43                ; $43: vicious warg
  DEFW VICIOUS_WARG
  DEFB $44                ; $44: gollum
  DEFW GOLLUM
  DEFB $45                ; $45: hideous goblin
  DEFW HIDEOUS_GOBLIN
  DEFB $46                ; $46: bard
  DEFW BARD
  DEFB $47                ; $47: hideous troll
  DEFW HIDEOUS_TROLL
  DEFB $48                ; $48: vicious troll
  DEFW VICIOUS_TROLL
  DEFB $49                ; $49: horrible goblin
  DEFW HORRIBLE_GOBLIN
  DEFB $4A                ; $4A: mean goblin
  DEFW MEAN_GOBLIN
  DEFB $4B                ; $4B: vicious goblin
  DEFW VICIOUS_GOBLIN
  DEFB $4C                ; $4C: disgusting goblin
  DEFW DISGUSTING_GOBLIN
  DEFB $FF                ; End of the index

; You (the player)
;
; You: the player. It starts in tunnel like hall. It is present, a character,
; open, or can be seen into. It has its own handling for EAT.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
PLAYER:
  DEFB $01                ; In 1 place
PLAYER_HOLDER:
  DEFB $FF                ; Held by nothing
  DEFB $10                ; Size 16
  DEFB $40                ; Carries up to 64
  DEFB $10                ; Things are in it; on the player's side
  DEFB $40                ; Strength 64
  DEFB $40                ; Defence 64
PLAYER_FLAGS:
  DEFB $E0                ; Flags: present, a character, open, or can be seen
                          ; into
  DEFB $A8,$87            ; Its name: YOU
  DEFB $00,$00            ; No adjective
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
PLAYER_WHERE:
  DEFB $01                ; In location 1, tunnel like hall
  DEFB $1B                ; On EAT (action $1B)
  DEFW DO_EAT
  DEFB $00                ; Key 0: after EAT, as well
  DEFW PLAYER_DIES
  DEFB $FF                ; End of its handlers

; Red golden dragon (character $3C)
;
; Red golden dragon: character $3C. It starts in lower halls. It is present, a
; character, open, or can be seen into. It has no handlers of its own: every
; action on it is the ordinary one.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
RED_GOLDEN_DRAGON:
  DEFB $01                ; In 1 place
  DEFB $FF                ; Held by nothing
  DEFB $C0                ; Size 192
  DEFB $60                ; Carries up to 96
  DEFB $00                ; Things are in it
  DEFB $C0                ; Strength 192
  DEFB $C0                ; Defence 192
RED_GOLDEN_DRAGON_FLAGS:
  DEFB $E0                ; Flags: present, a character, open, or can be seen
                          ; into
RED_GOLDEN_DRAGON_NAME:
  DEFB $C8,$01            ; Its name: DRAGON
  DEFB $36,$05            ; An adjective: RED
  DEFB $F3,$02            ; Another: GOLDEN
  DEFB $00,$00            ; No description of its own
RED_GOLDEN_DRAGON_WHERE:
  DEFB $29                ; In location 41, lower halls
  DEFB $FF                ; End of its handlers

; Round green door (object $05)
;
; Round green door: object $05. It starts in tunnel like hall and lonelands. It
; is present. It has its own handling for CLOSE, GO THROUGH, LOCK WITH, LOOK
; THROUGH, OPEN, STRIKE WITH, THROW THROUGH, UNLOCK WITH.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
ROUND_GREEN_DOOR:
  DEFB $02                ; In 2 places
  DEFB $FF                ; Held by nothing
  DEFB $FF                ; Size 255: nothing can hold it
  DEFB $FF                ; Weight 255: too heavy for anyone to lift
  DEFB $00                ; Things are in it
  DEFB $00                ; Strength 0
  DEFB $10                ; Defence 16
  DEFB $80                ; Flags: present
  DEFB $C0,$01            ; Its name: DOOR
  DEFB $5F,$05            ; An adjective: ROUND
  DEFB $04,$03            ; Another: GREEN
  DEFB $00,$00            ; No description of its own
  DEFB $01,$04            ; In locations 1, tunnel like hall; 4, lonelands
  DEFB $0B                ; On STRIKE WITH (action $0B)
  DEFW DO_STRIKE
  DEFB $0C                ; On CLOSE (action $0C)
  DEFW DO_CLOSE
  DEFB $10                ; On OPEN (action $10)
  DEFW DO_OPEN
  DEFB $18                ; On LOOK THROUGH (action $18)
  DEFW LOOK_THROUGH
  DEFB $1E                ; On GO THROUGH (action $1E)
  DEFW GO_THROUGH
  DEFB $25                ; On LOCK WITH (action $25)
  DEFW NO_KEY_FITS
  DEFB $26                ; On UNLOCK WITH (action $26)
  DEFW NO_KEY_FITS
  DEFB $2C                ; On THROW THROUGH (action $2C)
  DEFW THROW_THROUGH
  DEFB $FF                ; End of its handlers

; Heavy rock door (object $01)
;
; Heavy rock door: object $01. It starts in trolls cave and trolls path. It is
; present, locked. It has its own handling for CLOSE, GO THROUGH, LOCK WITH,
; LOOK THROUGH, OPEN, STRIKE WITH, THROW THROUGH, UNLOCK WITH.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
HEAVY_ROCK_DOOR:
  DEFB $02                ; In 2 places
  DEFB $FF                ; Held by nothing
  DEFB $FF                ; Size 255: nothing can hold it
  DEFB $FF                ; Weight 255: too heavy for anyone to lift
  DEFB $00                ; Things are in it
  DEFB $00                ; Strength 0
  DEFB $90                ; Defence 144
  DEFB $81                ; Flags: present, locked
  DEFB $C0,$01            ; Its name: DOOR
  DEFB $27,$03            ; An adjective: HEAVY
  DEFB $53,$05            ; Another: ROCK
  DEFB $00,$00            ; No description of its own
  DEFB $07,$06            ; In locations 7, trolls cave; 6, trolls path
  DEFB $0B                ; On STRIKE WITH (action $0B)
  DEFW DO_STRIKE
  DEFB $0C                ; On CLOSE (action $0C)
  DEFW DO_CLOSE
  DEFB $10                ; On OPEN (action $10)
  DEFW DO_OPEN
  DEFB $18                ; On LOOK THROUGH (action $18)
  DEFW LOOK_THROUGH
  DEFB $1E                ; On GO THROUGH (action $1E)
  DEFW GO_THROUGH
  DEFB $25                ; On LOCK WITH (action $25)
  DEFW ROCK_DOOR_KEY
  DEFB $26                ; On UNLOCK WITH (action $26)
  DEFW ROCK_DOOR_KEY
  DEFB $2C                ; On THROW THROUGH (action $2C)
  DEFW THROW_THROUGH
  DEFB $FF                ; End of its handlers

; Golden key (object $2B)
;
; Golden key: object $2B. It starts in deep misty valley. It is present. It has
; no handlers of its own: every action on it is the ordinary one.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
GOLDEN_KEY:
  DEFB $01                ; In 1 place
  DEFB $FF                ; Held by nothing
  DEFB $00                ; Size 0
  DEFB $00                ; Weight 0
  DEFB $00                ; Things are in it
  DEFB $00                ; Strength 0
  DEFB $00                ; Defence 0
  DEFB $80                ; Flags: present
  DEFB $A5,$03            ; Its name: KEY
  DEFB $F3,$02            ; An adjective: GOLDEN
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
  DEFB $4F                ; In location 79, deep misty valley
  DEFB $FF                ; End of its handlers

; Small curious key (object $02)
;
; Small curious key: object $02. It starts in goblins dungeon, held by goblins
; cache. It is present. It has no handlers of its own: every action on it is
; the ordinary one.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
SMALL_CURIOUS_KEY:
  DEFB $01                ; In 1 place
  DEFB $1F                ; Held by goblins cache (GOBLINS_CACHE)
  DEFB $00                ; Size 0
  DEFB $00                ; Weight 0
  DEFB $00                ; Things are in it
  DEFB $00                ; Strength 0
  DEFB $00                ; Defence 0
  DEFB $80                ; Flags: present
  DEFB $A5,$03            ; Its name: KEY
  DEFB $E1,$05            ; An adjective: SMALL
  DEFB $63,$01            ; Another: CURIOUS
  DEFB $00,$00            ; No description of its own
  DEFB $0D                ; In location 13, goblins dungeon
  DEFB $FF                ; End of its handlers

; Large key (object $04)
;
; Large key: object $04. It starts in trolls clearing, held by hideous troll.
; It is present. It has no handlers of its own: every action on it is the
; ordinary one.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
LARGE_KEY:
  DEFB $01                ; In 1 place
  DEFB $47                ; Held by hideous troll (HIDEOUS_TROLL)
  DEFB $01                ; Size 1
  DEFB $01                ; Weight 1
  DEFB $00                ; Things are in it
  DEFB $00                ; Strength 0
  DEFB $00                ; Defence 0
  DEFB $80                ; Flags: present
  DEFB $A5,$03            ; Its name: KEY
  DEFB $BF,$03            ; An adjective: LARGE
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
  DEFB $05                ; In location 5, trolls clearing
  DEFB $FF                ; End of its handlers

; Curious map (object $03)
;
; Curious map: object $03. It starts in tunnel like hall, held by gandalf. It
; is present. It has its own handling for EXAMINE.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
CURIOUS_MAP:
  DEFB $01                ; In 1 place
  DEFB $3E                ; Held by gandalf (GANDALF)
  DEFB $02                ; Size 2
  DEFB $00                ; Weight 0
  DEFB $00                ; Things are in it
  DEFB $00                ; Strength 0
  DEFB $02                ; Defence 2
  DEFB $80                ; Flags: present
  DEFB $2C,$14            ; Its name: MAP
  DEFB $63,$01            ; An adjective: CURIOUS
  DEFB $00,$00            ; No second adjective
  DEFW MSG_THERE_SEEM_TO_BE ; Its own description
  DEFB $01                ; In location 1, tunnel like hall
  DEFB $1C                ; On EXAMINE (action $1C)
  DEFW ELROND_READS_MAP
  DEFB $FF                ; End of its handlers

; Small insignificant crack (object $06)
;
; Small insignificant crack: object $06. It starts in large dry cave and dark
; stuffy passage. It is present. It has its own handling for CLOSE, GO THROUGH,
; LOOK THROUGH, OPEN.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
SMALL_INSIGNIFICANT_CRACK:
  DEFB $02                ; In 2 places
  DEFB $FF                ; Held by nothing
  DEFB $FF                ; Size 255: nothing can hold it
  DEFB $FF                ; Weight 255: too heavy for anyone to lift
  DEFB $00                ; Things are in it
  DEFB $FF                ; Strength 255
  DEFB $00                ; Defence 0
  DEFB $80                ; Flags: present
  DEFB $51,$01            ; Its name: CRACK
  DEFB $E1,$05            ; An adjective: SMALL
  DEFB $81,$03            ; Another: INSIGNIFICANT
  DEFB $00,$00            ; No description of its own
  DEFB $0E,$0F            ; In locations 14, large dry cave; 15, dark stuffy
                          ; passage
  DEFB $10                ; On OPEN (action $10)
  DEFW OPEN_CRACK
  DEFB $0C                ; On CLOSE (action $0C)
  DEFW DO_CLOSE
  DEFB $1E                ; On GO THROUGH (action $1E)
  DEFW GO_THROUGH
  DEFB $18                ; On LOOK THROUGH (action $18)
  DEFW LOOK_THROUGH
  DEFB $FF                ; End of its handlers

; Spider web (object $07)
;
; Spider web: object $07. It starts in spider threads place and levelled elvish
; clearing and smothering forest and deep bog and green forest. It is present.
; It has its own handling for GO THROUGH, STRIKE WITH.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
SPIDER_WEB:
  DEFB $05                ; In 5 places
  DEFB $FF                ; Held by nothing
  DEFB $A0                ; Size 160
  DEFB $50                ; Weight 80
  DEFB $00                ; Things are in it
  DEFB $40                ; Strength 64
  DEFB $40                ; Defence 64
  DEFB $80                ; Flags: present
  DEFB $76,$07            ; Its name: WEB
SPIDER_WEB_ADJECTIVE:
  DEFB $23,$06            ; An adjective: SPIDER
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
  DEFB $1A,$1C,$1B,$1D,$32 ; In locations 26, spider threads place; 28,
                           ; levelled elvish clearing; 27, smothering forest;
                           ; 29, deep bog; 50, green forest
  DEFB $0B                ; On STRIKE WITH (action $0B)
  DEFW DO_STRIKE
  DEFB $00                ; Key 0: after STRIKE WITH, as well
  DEFW WEB_BROKEN
  DEFB $1E                ; On GO THROUGH (action $1E)
  DEFW GO_THROUGH
  DEFB $FF                ; End of its handlers

; Red door (object $08)
;
; Red door: object $08. It starts in dark dungeon and elvenkings great halls
; and elvenkings cellar. It is present, locked. It has its own handling for
; CLOSE, GO THROUGH, LOCK WITH, LOOK THROUGH, OPEN, THROW THROUGH, UNLOCK WITH.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
RED_DOOR:
  DEFB $03                ; In 3 places
  DEFB $FF                ; Held by nothing
  DEFB $FF                ; Size 255: nothing can hold it
  DEFB $FF                ; Weight 255: too heavy for anyone to lift
  DEFB $00                ; Things are in it
  DEFB $00                ; Strength 0
  DEFB $00                ; Defence 0
  DEFB $81                ; Flags: present, locked
  DEFB $C0,$01            ; Its name: DOOR
  DEFB $36,$05            ; An adjective: RED
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
  DEFB $1F,$1E,$20        ; In locations 31, dark dungeon; 30, elvenkings great
                          ; halls; 32, elvenkings cellar
  DEFB $10                ; On OPEN (action $10)
  DEFW DO_OPEN
  DEFB $0C                ; On CLOSE (action $0C)
  DEFW DO_CLOSE
  DEFB $18                ; On LOOK THROUGH (action $18)
  DEFW LOOK_THROUGH
  DEFB $1E                ; On GO THROUGH (action $1E)
  DEFW GO_THROUGH
  DEFB $25                ; On LOCK WITH (action $25)
  DEFW RED_DOOR_KEY
  DEFB $26                ; On UNLOCK WITH (action $26)
  DEFW RED_DOOR_KEY
  DEFB $2C                ; On THROW THROUGH (action $2C)
  DEFW THROW_THROUGH
  DEFB $FF                ; End of its handlers

; Fast black river (object $09)
;
; Fast black river: object $09. It starts in west bank and east bank and
; bewitched gloomy place. It is present, full, a liquid. It has its own
; handling for DROP IN, LOOK ACROSS, PUT IN, SWIM.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
FAST_BLACK_RIVER:
  DEFB $03                ; In 3 places
  DEFB $FF                ; Held by nothing
  DEFB $FF                ; Size 255: nothing can hold it
  DEFB $FF                ; Weight 255: too heavy for anyone to lift
  DEFB $00                ; Things are in it
  DEFB $00                ; Strength 0
  DEFB $00                ; Defence 0
  DEFB $86                ; Flags: present, full, a liquid
  DEFB $4A,$05            ; Its name: RIVER
  DEFB $53,$02            ; An adjective: FAST
  DEFB $A5,$00            ; Another: BLACK
  DEFW MSG_YOU_SEE_A_FAST ; Its own description
  DEFB $42,$43,$19        ; In locations 66, west bank; 67, east bank; 25,
                          ; bewitched gloomy place
  DEFB $11                ; On PUT IN (action $11)
  DEFW INTO_THE_RIVER
  DEFB $0E                ; On DROP IN (action $0E)
  DEFW INTO_THE_RIVER
  DEFB $19                ; On LOOK ACROSS (action $19)
  DEFW LOOK_ACROSS
  DEFB $32                ; On SWIM (action $32)
  DEFW SWIM_BLACK_RIVER
  DEFB $FF                ; End of its handlers

; Fast river (object $2A)
;
; Fast river: object $2A. It starts in forestriver and forestriver and long
; lake. It is present, full, a liquid. It has its own handling for DROP IN,
; LOOK ACROSS, PUT IN, SWIM.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
FAST_RIVER:
  DEFB $03                ; In 3 places
  DEFB $FF                ; Held by nothing
  DEFB $FF                ; Size 255: nothing can hold it
  DEFB $FF                ; Weight 255: too heavy for anyone to lift
  DEFB $00                ; Things are in it
  DEFB $00                ; Strength 0
  DEFB $00                ; Defence 0
  DEFB $86                ; Flags: present, full, a liquid
  DEFB $4A,$05            ; Its name: RIVER
  DEFB $53,$02            ; An adjective: FAST
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
  DEFB $17,$21,$22        ; In locations 23, forestriver; 33, forestriver; 34,
                          ; long lake
  DEFB $11                ; On PUT IN (action $11)
  DEFW INTO_THE_RIVER
  DEFB $0E                ; On DROP IN (action $0E)
  DEFW INTO_THE_RIVER
  DEFB $19                ; On LOOK ACROSS (action $19)
  DEFW LOOK_ACROSS
  DEFB $32                ; On SWIM (action $32)
  DEFW SWIM_RIVER
  DEFB $FF                ; End of its handlers

; Goblins back door (object $0A)
;
; Goblins back door: object $0A. It starts in inside goblins gate and outside
; goblins gate. It is present. It has its own handling for CLOSE, GO THROUGH,
; LOOK THROUGH, OPEN, STRIKE WITH, THROW THROUGH.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
GOBLINS_BACK_DOOR:
  DEFB $02                ; In 2 places
  DEFB $FF                ; Held by nothing
  DEFB $40                ; Size 64
  DEFB $FF                ; Weight 255: too heavy for anyone to lift
  DEFB $00                ; Things are in it
  DEFB $50                ; Strength 80
  DEFB $50                ; Defence 80
  DEFB $80                ; Flags: present
  DEFB $C0,$01            ; Its name: DOOR
  DEFB $E8,$02            ; An adjective: GOBLINS
  DEFB $7C,$00            ; Another: BACK
  DEFB $00,$00            ; No description of its own
  DEFB $13,$14            ; In locations 19, inside goblins gate; 20, outside
                          ; goblins gate
  DEFB $10                ; On OPEN (action $10)
  DEFW DO_OPEN
  DEFB $0C                ; On CLOSE (action $0C)
  DEFW DO_CLOSE
  DEFB $0B                ; On STRIKE WITH (action $0B)
  DEFW DO_STRIKE
  DEFB $18                ; On LOOK THROUGH (action $18)
  DEFW LOOK_THROUGH
  DEFB $1E                ; On GO THROUGH (action $1E)
  DEFW GO_THROUGH
  DEFB $2C                ; On THROW THROUGH (action $2C)
  DEFW THROW_THROUGH
  DEFB $0B                ; On STRIKE WITH (action $0B)
  DEFW DO_STRIKE
  DEFB $FF                ; End of its handlers

; Mountains side door (object $0B)
;
; Mountains side door: object $0B. It starts in sidedoor and smooth straight
; passage. It is locked. It has its own handling for CLOSE, GO THROUGH, LOOK
; THROUGH, THROW THROUGH, UNLOCK WITH.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
MOUNTAINS_SIDE_DOOR:
  DEFB $02                ; In 2 places
  DEFB $FF                ; Held by nothing
  DEFB $FF                ; Size 255: nothing can hold it
  DEFB $FF                ; Weight 255: too heavy for anyone to lift
  DEFB $00                ; Things are in it
  DEFB $00                ; Strength 0
  DEFB $00                ; Defence 0
MOUNTAINS_SIDE_DOOR_FLAGS:
  DEFB $01                ; Flags: locked
  DEFB $C0,$01            ; Its name: DOOR
  DEFB $56,$04            ; An adjective: MOUNTAINS
  DEFB $A6,$05            ; Another: SIDE
  DEFB $00,$00            ; No description of its own
  DEFB $2A,$2B            ; In locations 42, sidedoor; 43, smooth straight
                          ; passage
  DEFB $0C                ; On CLOSE (action $0C)
  DEFW DO_CLOSE
  DEFB $00                ; Key 0: after CLOSE, as well
  DEFW SIDE_DOOR_CLOSED
  DEFB $26                ; On UNLOCK WITH (action $26)
  DEFW SIDE_DOOR_KEY
  DEFB $00                ; Key 0: after UNLOCK WITH, as well
  DEFW SIDE_DOOR_UNLOCKED
  DEFB $1E                ; On GO THROUGH (action $1E)
  DEFW GO_THROUGH
  DEFB $18                ; On LOOK THROUGH (action $18)
  DEFW LOOK_THROUGH
  DEFB $2C                ; On THROW THROUGH (action $2C)
  DEFW THROW_THROUGH
  DEFB $FF                ; End of its handlers

; Large trap door (object $0C)
;
; Large trap door: object $0C. It starts in elvenkings cellar and forestriver.
; It is present. It has its own handling for CLOSE, GO THROUGH, LOOK THROUGH,
; OPEN, STRIKE WITH, THROW THROUGH.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
LARGE_TRAP_DOOR:
  DEFB $02                ; In 2 places
  DEFB $FF                ; Held by nothing
  DEFB $FF                ; Size 255: nothing can hold it
  DEFB $FF                ; Weight 255: too heavy for anyone to lift
  DEFB $00                ; Things are in it
  DEFB $00                ; Strength 0
  DEFB $30                ; Defence 48
  DEFB $80                ; Flags: present
  DEFB $C0,$01            ; Its name: DOOR
  DEFB $BF,$03            ; An adjective: LARGE
  DEFB $E0,$06            ; Another: TRAP
  DEFB $00,$00            ; No description of its own
  DEFB $20,$21            ; In locations 32, elvenkings cellar; 33, forestriver
  DEFB $10                ; On OPEN (action $10)
  DEFW TRAP_DOOR_OPEN_CLOSE
  DEFB $0C                ; On CLOSE (action $0C)
  DEFW TRAP_DOOR_OPEN_CLOSE
  DEFB $0B                ; On STRIKE WITH (action $0B)
  DEFW DO_STRIKE
  DEFB $18                ; On LOOK THROUGH (action $18)
  DEFW LOOK_THROUGH
  DEFB $1E                ; On GO THROUGH (action $1E)
  DEFW GO_THROUGH
  DEFB $2C                ; On THROW THROUGH (action $2C)
  DEFW THROW_THROUGH
  DEFB $00                ; Key 0: after THROW THROUGH, as well
  DEFW BARREL_THROWN
  DEFB $FF                ; End of its handlers

; Short strong sword (object $0E)
;
; Short strong sword: object $0E. It starts in trolls cave. It is present, a
; light (bit 4, with bit 2). It has its own handling for STRIKE WITH.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
SHORT_STRONG_SWORD:
  DEFB $01                ; In 1 place
  DEFB $FF                ; Held by nothing
  DEFB $03                ; Size 3
  DEFB $04                ; Weight 4
  DEFB $00                ; Things are in it
  DEFB $40                ; Strength 64
  DEFB $80                ; Defence 128
SHORT_STRONG_SWORD_FLAGS:
  DEFB $94                ; Flags: present, a light (bit 4, with bit 2)
  DEFB $80,$06            ; Its name: SWORD
  DEFB $99,$05            ; An adjective: SHORT
  DEFB $64,$06            ; Another: STRONG
  DEFB $00,$00            ; No description of its own
  DEFB $07                ; In location 7, trolls cave
  DEFB $0B                ; On STRIKE WITH (action $0B)
  DEFW DO_STRIKE
  DEFB $FF                ; End of its handlers

; Valuable golden ring (object $10)
;
; Valuable golden ring: object $10. It starts in dark stuffy passage. It is
; present. It has its own handling for TAKE OFF, WEAR.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
VALUABLE_GOLDEN_RING:
  DEFB $01                ; In 1 place
  DEFB $FF                ; Held by nothing
  DEFB $00                ; Size 0
  DEFB $00                ; Weight 0
  DEFB $00                ; Things are in it
  DEFB $FF                ; Strength 255
  DEFB $00                ; Defence 0
  DEFB $80                ; Flags: present
  DEFB $3D,$05            ; Its name: RING
  DEFB $35,$07            ; An adjective: VALUABLE
  DEFB $F3,$02            ; Another: GOLDEN
  DEFB $00,$00            ; No description of its own
  DEFB $3D                ; In location 61, dark stuffy passage
  DEFB $28                ; On WEAR (action $28)
  DEFW WEAR_RING
  DEFB $16                ; On TAKE OFF (action $16)
  DEFW TAKE_OFF_RING
  DEFB $FF                ; End of its handlers

; Red key (object $0F)
;
; Red key: object $0F. It starts in elvenkings cellar, held by butler. It is
; present. It has no handlers of its own: every action on it is the ordinary
; one.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
RED_KEY:
  DEFB $01                ; In 1 place
  DEFB $42                ; Held by butler (BUTLER)
  DEFB $02                ; Size 2
  DEFB $02                ; Weight 2
  DEFB $00                ; Things are in it
  DEFB $02                ; Strength 2
  DEFB $02                ; Defence 2
  DEFB $80                ; Flags: present
  DEFB $A5,$03            ; Its name: KEY
  DEFB $36,$05            ; An adjective: RED
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
  DEFB $20                ; In location 32, elvenkings cellar
  DEFB $FF                ; End of its handlers

; Goblins door (object $11)
;
; Goblins door: object $11. It starts in big goblins cavern and goblins
; dungeon. It is present. It has its own handling for CLOSE, GO THROUGH, LOOK
; THROUGH, OPEN, THROW THROUGH.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
GOBLINS_DOOR:
  DEFB $02                ; In 2 places
  DEFB $FF                ; Held by nothing
  DEFB $FF                ; Size 255: nothing can hold it
  DEFB $FF                ; Weight 255: too heavy for anyone to lift
  DEFB $00                ; Things are in it
  DEFB $FF                ; Strength 255
  DEFB $FF                ; Defence 255
GOBLINS_DOOR_FLAGS:
  DEFB $80                ; Flags: present
  DEFB $C0,$01            ; Its name: DOOR
  DEFB $E8,$02            ; An adjective: GOBLINS
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
  DEFB $10,$0D            ; In locations 16, big goblins cavern; 13, goblins
                          ; dungeon
  DEFB $10                ; On OPEN (action $10)
  DEFW GOBLINS_DOOR_OPENED
  DEFB $0C                ; On CLOSE (action $0C)
  DEFW DO_CLOSE
  DEFB $1E                ; On GO THROUGH (action $1E)
  DEFW GO_THROUGH
  DEFB $18                ; On LOOK THROUGH (action $18)
  DEFW LOOK_THROUGH
  DEFB $2C                ; On THROW THROUGH (action $2C)
  DEFW THROW_THROUGH
  DEFB $FF                ; End of its handlers

; Rope (object $12)
;
; Rope: object $12. It starts in trolls cave. It is present, open, or can be
; seen into. It has its own handling for PULL, THROW ACROSS, TIE TO.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
ROPE:
  DEFB $01                ; In 1 place
ROPE_HOLDER:
  DEFB $FF                ; Held by nothing
  DEFB $02                ; Size 2
  DEFB $02                ; Weight 2
  DEFB $04                ; Things are tied to it
  DEFB $20                ; Strength 32
  DEFB $05                ; Defence 5
  DEFB $A0                ; Flags: present, open, or can be seen into
  DEFB $5B,$05            ; Its name: ROPE
  DEFB $00,$00            ; No adjective
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
  DEFB $07                ; In location 7, trolls cave
  DEFB $2B                ; On THROW ACROSS (action $2B)
  DEFW THROW_ROPE_ACROSS
  DEFB $2E                ; On TIE TO (action $2E)
  DEFW DO_TIE
  DEFB $31                ; On PULL (action $31)
  DEFW PULL_ROPE
  DEFB $FF                ; End of its handlers

; Magic door (object $0D)
;
; Magic door: object $0D. It starts in elvenkings great halls and levelled
; elvish clearing. It is present. It has its own handling for EXAMINE, GO
; THROUGH, LOOK THROUGH, THROW THROUGH.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
MAGIC_DOOR:
  DEFB $02                ; In 2 places
  DEFB $FF                ; Held by nothing
  DEFB $FF                ; Size 255: nothing can hold it
  DEFB $FF                ; Weight 255: too heavy for anyone to lift
  DEFB $00                ; Things are in it
  DEFB $FF                ; Strength 255
  DEFB $FF                ; Defence 255
MAGIC_DOOR_FLAGS:
  DEFB $80                ; Flags: present
  DEFB $C0,$01            ; Its name: DOOR
  DEFB $24,$04            ; An adjective: MAGIC
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
  DEFB $1E,$1C            ; In locations 30, elvenkings great halls; 28,
                          ; levelled elvish clearing
  DEFB $1E                ; On GO THROUGH (action $1E)
  DEFW GO_THROUGH
  DEFB $18                ; On LOOK THROUGH (action $18)
  DEFW LOOK_THROUGH
  DEFB $2C                ; On THROW THROUGH (action $2C)
  DEFW THROW_THROUGH
  DEFB $1C                ; On EXAMINE (action $1C)
  DEFW MAGIC_DOOR_EXAMINED
  DEFB $FF                ; End of its handlers

; Gandalf (character $3E)
;
; Gandalf: character $3E. It starts in tunnel like hall. It is present, a
; character, open, or can be seen into. It has no handlers of its own: every
; action on it is the ordinary one.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
GANDALF:
  DEFB $01                ; In 1 place
  DEFB $FF                ; Held by nothing
  DEFB $15                ; Size 21
  DEFB $60                ; Carries up to 96
  DEFB $10                ; Things are in it; on the player's side
  DEFB $70                ; Strength 112
  DEFB $88                ; Defence 136
  DEFB $E0                ; Flags: present, a character, open, or can be seen
                          ; into
  DEFB $BD,$82            ; Its name: GANDALF
  DEFB $00,$00            ; No adjective
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
  DEFB $01                ; In location 1, tunnel like hall
  DEFB $FF                ; End of its handlers

; Thorin (character $3F)
;
; Thorin: character $3F. It starts in tunnel like hall. It is present, a
; character, open, or can be seen into. It has its own handling for ATTACK
; WITH.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
THORIN:
  DEFB $01                ; In 1 place
  DEFB $FF                ; Held by nothing
  DEFB $1D                ; Size 29
  DEFB $50                ; Carries up to 80
  DEFB $10                ; Things are in it; on the player's side
  DEFB $68                ; Strength 104
  DEFB $78                ; Defence 120
THORIN_FLAGS:
  DEFB $E0                ; Flags: present, a character, open, or can be seen
                          ; into
  DEFB $B4,$86            ; Its name: THORIN
  DEFB $00,$00            ; No adjective
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
  DEFB $01                ; In location 1, tunnel like hall
  DEFB $0F                ; On ATTACK WITH (action $0F)
  DEFW DO_ATTACK
  DEFB $00                ; Key 0: after ATTACK WITH, as well
  DEFW THORIN_KILLED
  DEFB $FF                ; End of its handlers

; Wood elf (character $40)
;
; Wood elf: character $40. It starts in levelled elvish clearing. It is
; present, a character, open, or can be seen into. It has no handlers of its
; own: every action on it is the ordinary one.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
WOOD_ELF:
  DEFB $01                ; In 1 place
  DEFB $FF                ; Held by nothing
  DEFB $70                ; Size 112
  DEFB $FF                ; Carries up to 255
  DEFB $40                ; Things are in it; on the elves' side
  DEFB $40                ; Strength 64
  DEFB $30                ; Defence 48
  DEFB $E0                ; Flags: present, a character, open, or can be seen
                          ; into
  DEFB $0A,$02            ; Its name: ELF
  DEFB $9E,$07            ; An adjective: WOOD
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
  DEFB $1C                ; In location 28, levelled elvish clearing
  DEFB $FF                ; End of its handlers

; Elrond (character $41)
;
; Elrond: character $41. It starts in rivendell. It is present, a character,
; open, or can be seen into. It has no handlers of its own: every action on it
; is the ordinary one.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
ELROND:
  DEFB $01                ; In 1 place
  DEFB $FF                ; Held by nothing
  DEFB $20                ; Size 32
  DEFB $30                ; Carries up to 48
  DEFB $50                ; Things are in it; on the player's, the elves' side
  DEFB $40                ; Strength 64
  DEFB $40                ; Defence 64
  DEFB $E0                ; Flags: present, a character, open, or can be seen
                          ; into
  DEFB $0D,$82            ; Its name: ELROND
  DEFB $00,$00            ; No adjective
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
  DEFB $09                ; In location 9, rivendell
  DEFB $FF                ; End of its handlers

; Barrel (object $13)
;
; Barrel: object $13. It starts in elvenkings cellar. It is present, full. It
; has its own handling for CLIMB INTO, CLOSE, EMPTY, FILL WITH, JUMP ONTO,
; OPEN, PUT IN, STRIKE WITH.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
BARREL:
  DEFB $01                ; In 1 place
  DEFB $FF                ; Held by nothing
  DEFB $20                ; Size 32
  DEFB $03                ; Weight 3
  DEFB $00                ; Things are in it
  DEFB $20                ; Strength 32
  DEFB $20                ; Defence 32
  DEFB $84                ; Flags: present, full
  DEFB $84,$10            ; Its name: BARREL
  DEFB $00,$00            ; No adjective
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
BARREL_WHERE:
  DEFB $20                ; In location 32, elvenkings cellar
  DEFB $10                ; On OPEN (action $10)
  DEFW DO_OPEN
  DEFB $0C                ; On CLOSE (action $0C)
  DEFW DO_CLOSE
  DEFB $11                ; On PUT IN (action $11)
  DEFW DO_PUT_IN
  DEFB $23                ; On FILL WITH (action $23)
  DEFW DO_FILL
  DEFB $22                ; On EMPTY (action $22)
  DEFW DO_EMPTY
  DEFB $38                ; On JUMP ONTO (action $38)
  DEFW JUMP_ONTO_BARREL
  DEFB $36                ; On CLIMB INTO (action $36)
  DEFW DO_CLIMB_INTO
  DEFB $0B                ; On STRIKE WITH (action $0B)
  DEFW DO_STRIKE
  DEFB $FF                ; End of its handlers

; Wine (object $14)
;
; Wine: object $14. It starts in elvenkings cellar, held by barrel. It is
; present, a liquid. It has its own handling for DRINK.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
WINE:
  DEFB $01                ; In 1 place
  DEFB $13                ; Held by barrel (BARREL)
  DEFB $1F                ; Size 31
  DEFB $05                ; Weight 5
  DEFB $00                ; Things are in it
  DEFB $00                ; Strength 0
  DEFB $00                ; Defence 0
  DEFB $82                ; Flags: present, a liquid
  DEFB $92,$37            ; Its name: WINE
  DEFB $00,$00            ; No adjective
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
  DEFB $20                ; In location 32, elvenkings cellar
  DEFB $21                ; On DRINK (action $21)
  DEFW DO_DRINK
  DEFB $00                ; Key 0: after DRINK, as well
  DEFW WINE_DRUNK
  DEFB $FF                ; End of its handlers

; Butler (character $42)
;
; Butler: character $42. It starts in elvenkings cellar. It is a character,
; open, or can be seen into. It has no handlers of its own: every action on it
; is the ordinary one.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
BUTLER:
  DEFB $01                ; In 1 place
  DEFB $FF                ; Held by nothing
  DEFB $30                ; Size 48
  DEFB $30                ; Carries up to 48
  DEFB $40                ; Things are in it; on the elves' side
  DEFB $20                ; Strength 32
  DEFB $70                ; Defence 112
BUTLER_FLAGS:
  DEFB $60                ; Flags: a character, open, or can be seen into
  DEFB $DC,$00            ; Its name: BUTLER
  DEFB $00,$00            ; No adjective
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
  DEFB $20                ; In location 32, elvenkings cellar
  DEFB $FF                ; End of its handlers

; Vicious warg (character $43)
;
; Vicious warg: character $43. It starts in treeless opening. It is present, a
; character, open, or can be seen into. It has no handlers of its own: every
; action on it is the ordinary one.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
VICIOUS_WARG:
  DEFB $01                ; In 1 place
  DEFB $FF                ; Held by nothing
  DEFB $30                ; Size 48
  DEFB $30                ; Carries up to 48
  DEFB $00                ; Things are in it
  DEFB $37                ; Strength 55
  DEFB $37                ; Defence 55
  DEFB $E0                ; Flags: present, a character, open, or can be seen
                          ; into
  DEFB $9A,$07            ; Its name: WARG
  DEFB $41,$07            ; An adjective: VICIOUS
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
VICIOUS_WARG_WHERE:
  DEFB $15                ; In location 21, treeless opening
  DEFB $FF                ; End of its handlers

; Water (object $15)
;
; Water: object $15. It starts in nowhere, until something puts it somewhere.
; It is present, a liquid. It has its own handling for DRINK.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
WATER:
  DEFB $01                ; In 1 place
  DEFB $FF                ; Held by nothing
  DEFB $1F                ; Size 31
  DEFB $05                ; Weight 5
  DEFB $00                ; Things are in it
  DEFB $00                ; Strength 0
  DEFB $00                ; Defence 0
  DEFB $82                ; Flags: present, a liquid
  DEFB $5E,$37            ; Its name: WATER
  DEFB $00,$00            ; No adjective
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
  DEFB $00                ; In location 0, nowhere
  DEFB $21                ; On DRINK (action $21)
  DEFW DO_DRINK
  DEFB $FF                ; End of its handlers

; Black water (object $16)
;
; Black water: object $16. It starts in nowhere, until something puts it
; somewhere. It is present, a liquid. It has its own handling for DRINK.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
BLACK_WATER:
  DEFB $01                ; In 1 place
  DEFB $FF                ; Held by nothing
  DEFB $1F                ; Size 31
  DEFB $05                ; Weight 5
  DEFB $00                ; Things are in it
  DEFB $00                ; Strength 0
  DEFB $00                ; Defence 0
  DEFB $82                ; Flags: present, a liquid
  DEFB $5E,$07            ; Its name: WATER
  DEFB $A5,$00            ; An adjective: BLACK
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
  DEFB $00                ; In location 0, nowhere
  DEFB $21                ; On DRINK (action $21)
  DEFW DRINK_BLACK_WATER
  DEFB $FF                ; End of its handlers

; Water (object $17)
;
; Water: object $17. It starts in running river and forestriver and long lake
; and running river and great river and waterfall and deep dark lake and
; forestriver. It is present, a liquid. It has its own handling for DRINK.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
WATER_OBJ17:
  DEFB $08                ; In 8 places
  DEFB $FF                ; Held by nothing
  DEFB $00                ; Size 0
  DEFB $05                ; Weight 5
  DEFB $00                ; Things are in it
  DEFB $00                ; Strength 0
  DEFB $00                ; Defence 0
  DEFB $82                ; Flags: present, a liquid
  DEFB $5E,$07            ; Its name: WATER
  DEFB $00,$00            ; No adjective
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
  DEFB $08,$21,$22,$24,$31,$2D,$11,$17 ; In locations 8, running river; 33,
                                       ; forestriver; 34, long lake; 36,
                                       ; running river; 49, great river; 45,
                                       ; waterfall; 17, deep dark lake; 23,
                                       ; forestriver
  DEFB $21                ; On DRINK (action $21)
  DEFW DRINK_WATER
  DEFB $FF                ; End of its handlers

; Black water (object $18)
;
; Black water: object $18. It starts in bewitched gloomy place and west bank
; and east bank. It is present, a liquid. It has its own handling for DRINK.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
BLACK_WATER_OBJ18:
  DEFB $03                ; In 3 places
  DEFB $FF                ; Held by nothing
  DEFB $1F                ; Size 31
  DEFB $05                ; Weight 5
  DEFB $00                ; Things are in it
  DEFB $00                ; Strength 0
  DEFB $00                ; Defence 0
  DEFB $82                ; Flags: present, a liquid
  DEFB $5E,$07            ; Its name: WATER
  DEFB $A5,$00            ; An adjective: BLACK
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
  DEFB $19,$42,$43        ; In locations 25, bewitched gloomy place; 66, west
                          ; bank; 67, east bank
  DEFB $21                ; On DRINK (action $21)
  DEFW DRINK_BLACK_WATER
  DEFB $FF                ; End of its handlers

; Gollum (character $44)
;
; Gollum: character $44. It starts in deep dark lake. It is present, a
; character, open, or can be seen into. It has no handlers of its own: every
; action on it is the ordinary one.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
GOLLUM:
  DEFB $01                ; In 1 place
  DEFB $FF                ; Held by nothing
  DEFB $05                ; Size 5
  DEFB $05                ; Carries up to 5
  DEFB $20                ; Things are in it; on the goblins' side
  DEFB $20                ; Strength 32
  DEFB $40                ; Defence 64
  DEFB $E0                ; Flags: present, a character, open, or can be seen
                          ; into
  DEFB $F9,$82            ; Its name: GOLLUM
  DEFB $00,$00            ; No adjective
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
GOLLUM_WHERE:
  DEFB $11                ; In location 17, deep dark lake
  DEFB $FF                ; End of its handlers

; Bard (character $46)
;
; Bard: character $46. It starts in lake town. It is present, a character,
; open, or can be seen into. It has no handlers of its own: every action on it
; is the ordinary one.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
BARD:
  DEFB $01                ; In 1 place
  DEFB $FF                ; Held by nothing
  DEFB $30                ; Size 48
  DEFB $10                ; Carries up to 16
  DEFB $10                ; Things are in it; on the player's side
  DEFB $60                ; Strength 96
  DEFB $60                ; Defence 96
BARD_FLAGS:
  DEFB $E0                ; Flags: present, a character, open, or can be seen
                          ; into
  DEFB $80,$80            ; Its name: BARD
  DEFB $00,$00            ; No adjective
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
  DEFB $23                ; In location 35, lake town
  DEFB $FF                ; End of its handlers

; Bow (object $19)
;
; Bow: object $19. It starts in lake town, held by bard. It is present. It has
; its own handling for STRIKE WITH.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
BOW:
  DEFB $01                ; In 1 place
  DEFB $46                ; Held by bard (BARD)
  DEFB $05                ; Size 5
  DEFB $03                ; Weight 3
  DEFB $00                ; Things are in it
  DEFB $10                ; Strength 16
  DEFB $10                ; Defence 16
  DEFB $80                ; Flags: present
  DEFB $C3,$10            ; Its name: BOW
  DEFB $00,$00            ; No adjective
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
  DEFB $23                ; In location 35, lake town
  DEFB $0B                ; On STRIKE WITH (action $0B)
  DEFW DO_STRIKE
  DEFB $FF                ; End of its handlers

; Strong arrow (object $1A)
;
; Strong arrow: object $1A. It starts in lake town, held by bard. It is
; present. It has its own handling for STRIKE WITH.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
STRONG_ARROW:
  DEFB $01                ; In 1 place
  DEFB $46                ; Held by bard (BARD)
  DEFB $02                ; Size 2
  DEFB $01                ; Weight 1
  DEFB $00                ; Things are in it
  DEFB $10                ; Strength 16
  DEFB $10                ; Defence 16
  DEFB $80                ; Flags: present
  DEFB $6B,$10            ; Its name: ARROW
  DEFB $64,$06            ; An adjective: STRONG
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
  DEFB $23                ; In location 35, lake town
  DEFB $0B                ; On STRIKE WITH (action $0B)
  DEFW DO_STRIKE
  DEFB $FF                ; End of its handlers

; Window (object $1B)
;
; Window: object $1B. It starts in goblins dungeon and dark winding passage. It
; is present. It has its own handling for CLOSE, GO THROUGH, LOOK THROUGH,
; OPEN, STRIKE WITH.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
WINDOW:
  DEFB $02                ; In 2 places
  DEFB $FF                ; Held by nothing
  DEFB $60                ; Size 96
  DEFB $FF                ; Weight 255: too heavy for anyone to lift
  DEFB $80                ; Things are in it; the window's bit 7
  DEFB $70                ; Strength 112
  DEFB $70                ; Defence 112
  DEFB $80                ; Flags: present
  DEFB $8C,$07            ; Its name: WINDOW
  DEFB $00,$00            ; No adjective
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
  DEFB $0D,$12            ; In locations 13, goblins dungeon; 18, dark winding
                          ; passage
  DEFB $1E                ; On GO THROUGH (action $1E)
  DEFW WINDOW_OTHERS
  DEFB $0B                ; On STRIKE WITH (action $0B)
  DEFW WINDOW_OTHERS
  DEFB $10                ; On OPEN (action $10)
  DEFW WINDOW_OPEN_CLOSE
  DEFB $0C                ; On CLOSE (action $0C)
  DEFW WINDOW_OPEN_CLOSE
  DEFB $18                ; On LOOK THROUGH (action $18)
  DEFW WINDOW_OTHERS
  DEFB $FF                ; End of its handlers

; Torch (object $1C)
;
; Torch: object $1C. It starts in big goblins cavern and elvenkings great
; halls. It is present, a light (bit 4, with bit 2). It has no handlers of its
; own: every action on it is the ordinary one.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
TORCH:
  DEFB $02                ; In 2 places
  DEFB $FF                ; Held by nothing
  DEFB $05                ; Size 5
  DEFB $05                ; Weight 5
  DEFB $00                ; Things are in it
  DEFB $80                ; Strength 128
  DEFB $80                ; Defence 128
  DEFB $94                ; Flags: present, a light (bit 4, with bit 2)
  DEFB $D7,$16            ; Its name: TORCH
  DEFB $00,$00            ; No adjective
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
  DEFB $10,$1E            ; In locations 16, big goblins cavern; 30, elvenkings
                          ; great halls
  DEFB $FF                ; End of its handlers

; Sand (object $1D)
;
; Sand: object $1D. It starts in goblins dungeon. It is present. It has its own
; handling for DIG, PUT IN.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
SAND:
  DEFB $01                ; In 1 place
  DEFB $FF                ; Held by nothing
  DEFB $65                ; Size 101
  DEFB $65                ; Weight 101
  DEFB $00                ; Things are in it
  DEFB $00                ; Strength 0
  DEFB $00                ; Defence 0
  DEFB $80                ; Flags: present
  DEFB $7C,$35            ; Its name: SAND
  DEFB $00,$00            ; No adjective
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
  DEFB $0D                ; In location 13, goblins dungeon
  DEFB $39                ; On DIG (action $39)
  DEFW DO_DIG
  DEFB $11                ; On PUT IN (action $11)
  DEFW DO_PUT_IN
  DEFB $FF                ; End of its handlers

; Trap door (object $1E)
;
; Trap door: object $1E. It starts in goblins dungeon, held by sand. It is
; present, locked. It has its own handling for OPEN, STRIKE WITH, UNLOCK WITH.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
TRAP_DOOR:
  DEFB $01                ; In 1 place
  DEFB $1D                ; Held by sand (SAND)
  DEFB $FF                ; Size 255: nothing can hold it
  DEFB $FF                ; Weight 255: too heavy for anyone to lift
  DEFB $03                ; Things are under it
  DEFB $80                ; Strength 128
  DEFB $80                ; Defence 128
  DEFB $81                ; Flags: present, locked
  DEFB $C0,$01            ; Its name: DOOR
  DEFB $E0,$06            ; An adjective: TRAP
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
  DEFB $0D                ; In location 13, goblins dungeon
  DEFB $0B                ; On STRIKE WITH (action $0B)
  DEFW DO_STRIKE
  DEFB $26                ; On UNLOCK WITH (action $26)
  DEFW NO_KEY_FITS
  DEFB $10                ; On OPEN (action $10)
  DEFW DO_OPEN
  DEFB $FF                ; End of its handlers

; Goblins cache (object $1F)
;
; Goblins cache: object $1F. It starts in goblins dungeon, held by trap door.
; It is present, open, or can be seen into. It has its own handling for PUT IN,
; TAKE OUT OF.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
GOBLINS_CACHE:
  DEFB $01                ; In 1 place
  DEFB $1E                ; Held by trap door (TRAP_DOOR)
  DEFB $FF                ; Size 255: nothing can hold it
  DEFB $FF                ; Weight 255: too heavy for anyone to lift
  DEFB $00                ; Things are in it
  DEFB $00                ; Strength 0
  DEFB $00                ; Defence 0
  DEFB $A0                ; Flags: present, open, or can be seen into
  DEFB $E2,$00            ; Its name: CACHE
  DEFB $E8,$02            ; An adjective: GOBLINS
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
  DEFB $0D                ; In location 13, goblins dungeon
  DEFB $11                ; On PUT IN (action $11)
  DEFW DO_PUT_IN
  DEFB $14                ; On TAKE OUT OF (action $14)
  DEFW DO_TAKE_OUT
  DEFB $FF                ; End of its handlers

; Heavy curtain (object $20)
;
; Heavy curtain: object $20. It starts in beorns house. It is present. It has
; its own handling for CLOSE, OPEN.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
HEAVY_CURTAIN:
  DEFB $01                ; In 1 place
  DEFB $FF                ; Held by nothing
  DEFB $FF                ; Size 255: nothing can hold it
  DEFB $FF                ; Weight 255: too heavy for anyone to lift
  DEFB $02                ; Things are behind it
  DEFB $00                ; Strength 0
  DEFB $00                ; Defence 0
  DEFB $80                ; Flags: present
  DEFB $6A,$11            ; Its name: CURTAIN
  DEFB $27,$03            ; An adjective: HEAVY
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
  DEFB $16                ; In location 22, beorns house
  DEFB $10                ; On OPEN (action $10)
  DEFW DO_OPEN
  DEFB $0C                ; On CLOSE (action $0C)
  DEFW DO_CLOSE
  DEFB $FF                ; End of its handlers

; Large cupboard (object $21)
;
; Large cupboard: object $21. It starts in beorns house, held by wall. It is
; present. It has its own handling for CLOSE, OPEN, PUT IN, STRIKE WITH, TAKE
; OUT OF.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
LARGE_CUPBOARD:
  DEFB $01                ; In 1 place
  DEFB $24                ; Held by wall (WALL)
  DEFB $FF                ; Size 255: nothing can hold it
  DEFB $FF                ; Weight 255: too heavy for anyone to lift
  DEFB $00                ; Things are in it
  DEFB $00                ; Strength 0
  DEFB $00                ; Defence 0
  DEFB $80                ; Flags: present
  DEFB $5B,$11            ; Its name: CUPBOARD
  DEFB $BF,$03            ; An adjective: LARGE
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
  DEFB $16                ; In location 22, beorns house
  DEFB $10                ; On OPEN (action $10)
  DEFW DO_OPEN
  DEFB $0C                ; On CLOSE (action $0C)
  DEFW DO_CLOSE
  DEFB $11                ; On PUT IN (action $11)
  DEFW DO_PUT_IN
  DEFB $14                ; On TAKE OUT OF (action $14)
  DEFW DO_TAKE_OUT
  DEFB $0B                ; On STRIKE WITH (action $0B)
  DEFW DO_STRIKE
  DEFB $FF                ; End of its handlers

; Food (object $22)
;
; Food: object $22. It starts in beorns house, held by large cupboard. It is
; present. It has its own handling for EAT.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
FOOD:
  DEFB $01                ; In 1 place
  DEFB $21                ; Held by large cupboard (LARGE_CUPBOARD)
  DEFB $05                ; Size 5
  DEFB $05                ; Weight 5
  DEFB $00                ; Things are in it
  DEFB $01                ; Strength 1
  DEFB $00                ; Defence 0
  DEFB $80                ; Flags: present
  DEFB $8B,$32            ; Its name: FOOD
  DEFB $00,$00            ; No adjective
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
  DEFB $16                ; In location 22, beorns house
  DEFB $1B                ; On EAT (action $1B)
  DEFW DO_EAT
  DEFB $FF                ; End of its handlers

; Valuable treasure (object $23)
;
; Valuable treasure: object $23. It starts in lower halls. It is present. It
; has no handlers of its own: every action on it is the ordinary one.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
VALUABLE_TREASURE:
  DEFB $01                ; In 1 place
VALUABLE_TREASURE_HOLDER:
  DEFB $FF                ; Held by nothing
  DEFB $20                ; Size 32
  DEFB $20                ; Weight 32
  DEFB $00                ; Things are in it
  DEFB $05                ; Strength 5
  DEFB $05                ; Defence 5
  DEFB $80                ; Flags: present
  DEFB $E4,$06            ; Its name: TREASURE
  DEFB $35,$07            ; An adjective: VALUABLE
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
VALUABLE_TREASURE_WHERE:
  DEFB $29                ; In location 41, lower halls
  DEFB $FF                ; End of its handlers

; Wall (object $24)
;
; Wall: object $24. It starts in beorns house, held by heavy curtain. It is
; present, open, or can be seen into. It has no handlers of its own: every
; action on it is the ordinary one.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
WALL:
  DEFB $01                ; In 1 place
  DEFB $20                ; Held by heavy curtain (HEAVY_CURTAIN)
  DEFB $FF                ; Size 255: nothing can hold it
  DEFB $FF                ; Weight 255: too heavy for anyone to lift
  DEFB $00                ; Things are in it
  DEFB $00                ; Strength 0
  DEFB $00                ; Defence 0
  DEFB $A0                ; Flags: present, open, or can be seen into
  DEFB $5A,$17            ; Its name: WALL
  DEFB $00,$00            ; No adjective
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
  DEFB $16                ; In location 22, beorns house
  DEFB $11                ; On PUT IN (action $11): nothing
  DEFW $0000
  DEFB $FF                ; End of its handlers

; Wooden chest (object $25)
;
; Wooden chest: object $25. It starts in tunnel like hall. It is present. It
; has its own handling for CLIMB INTO, CLOSE, DROP IN, OPEN, PUT IN, STRIKE
; WITH, TAKE OUT OF.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
WOODEN_CHEST:
  DEFB $01                ; In 1 place
  DEFB $FF                ; Held by nothing
  DEFB $40                ; Size 64
  DEFB $FF                ; Weight 255: too heavy for anyone to lift
  DEFB $00                ; Things are in it
  DEFB $00                ; Strength 0
  DEFB $00                ; Defence 0
  DEFB $80                ; Flags: present
  DEFB $22,$01            ; Its name: CHEST
  DEFB $A2,$07            ; An adjective: WOODEN
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
  DEFB $01                ; In location 1, tunnel like hall
  DEFB $10                ; On OPEN (action $10)
  DEFW DO_OPEN
  DEFB $0C                ; On CLOSE (action $0C)
  DEFW DO_CLOSE
  DEFB $11                ; On PUT IN (action $11)
  DEFW DO_PUT_IN
  DEFB $0E                ; On DROP IN (action $0E)
  DEFW DO_PUT_IN
  DEFB $14                ; On TAKE OUT OF (action $14)
  DEFW DO_TAKE_OUT
  DEFB $0B                ; On STRIKE WITH (action $0B)
  DEFW DO_STRIKE
  DEFB $36                ; On CLIMB INTO (action $36)
  DEFW DO_CLIMB_INTO
  DEFB $FF                ; End of its handlers

; Wooden boat (object $29)
;
; Wooden boat: object $29. It starts in east bank. It is present, open, or can
; be seen into. It has its own handling for CLIMB INTO, DROP IN, PUT IN, STRIKE
; WITH, TAKE OUT OF.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
WOODEN_BOAT:
  DEFB $01                ; In 1 place
WOODEN_BOAT_HOLDER:
  DEFB $FF                ; Held by nothing
  DEFB $40                ; Size 64
  DEFB $FF                ; Weight 255: too heavy for anyone to lift
  DEFB $00                ; Things are in it
  DEFB $00                ; Strength 0
  DEFB $00                ; Defence 0
  DEFB $A0                ; Flags: present, open, or can be seen into
  DEFB $B8,$00            ; Its name: BOAT
  DEFB $A2,$07            ; An adjective: WOODEN
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
WOODEN_BOAT_WHERE:
  DEFB $43                ; In location 67, east bank
  DEFB $11                ; On PUT IN (action $11)
  DEFW DO_PUT_IN
  DEFB $0E                ; On DROP IN (action $0E)
  DEFW DO_PUT_IN
  DEFB $14                ; On TAKE OUT OF (action $14)
  DEFW DO_TAKE_OUT
  DEFB $0B                ; On STRIKE WITH (action $0B)
  DEFW DO_STRIKE
  DEFB $36                ; On CLIMB INTO (action $36)
  DEFW DO_CLIMB_INTO
  DEFB $00                ; Key 0: after CLIMB INTO, as well
  DEFW BOAT_BOARDED
  DEFB $FF                ; End of its handlers

; Hideous troll (character $47)
;
; Hideous troll: character $47. It starts in trolls clearing. It is present, a
; character, open, or can be seen into. It has no handlers of its own: every
; action on it is the ordinary one.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
HIDEOUS_TROLL:
  DEFB $01                ; In 1 place
  DEFB $FF                ; Held by nothing
  DEFB $90                ; Size 144
  DEFB $90                ; Carries up to 144
  DEFB $00                ; Things are in it
  DEFB $A0                ; Strength 160
  DEFB $A0                ; Defence 160
HIDEOUS_TROLL_FLAGS:
  DEFB $E0                ; Flags: present, a character, open, or can be seen
                          ; into
  DEFB $F8,$06            ; Its name: TROLL
  DEFB $37,$03            ; An adjective: HIDEOUS
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
  DEFB $05                ; In location 5, trolls clearing
  DEFB $FF                ; End of its handlers

; Vicious troll (character $48)
;
; Vicious troll: character $48. It starts in trolls clearing. It is present, a
; character, open, or can be seen into. It has no handlers of its own: every
; action on it is the ordinary one.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
VICIOUS_TROLL:
  DEFB $01                ; In 1 place
  DEFB $FF                ; Held by nothing
  DEFB $90                ; Size 144
  DEFB $90                ; Carries up to 144
  DEFB $00                ; Things are in it
  DEFB $A0                ; Strength 160
  DEFB $A0                ; Defence 160
VICIOUS_TROLL_FLAGS:
  DEFB $E0                ; Flags: present, a character, open, or can be seen
                          ; into
  DEFB $F8,$06            ; Its name: TROLL
  DEFB $41,$07            ; An adjective: VICIOUS
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
  DEFB $05                ; In location 5, trolls clearing
  DEFB $FF                ; End of its handlers

; Lunch (object $26)
;
; Lunch: object $26. It starts in nowhere, until something puts it somewhere.
; It is present. It has its own handling for EAT.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
LUNCH:
  DEFB $01                ; In 1 place
  DEFB $FF                ; Held by nothing
  DEFB $05                ; Size 5
  DEFB $05                ; Weight 5
  DEFB $00                ; Things are in it
  DEFB $01                ; Strength 1
  DEFB $00                ; Defence 0
  DEFB $80                ; Flags: present
  DEFB $1F,$34            ; Its name: LUNCH
  DEFB $00,$00            ; No adjective
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
  DEFB $00                ; In location 0, nowhere
  DEFB $1B                ; On EAT (action $1B)
  DEFW DO_EAT
  DEFB $FF                ; End of its handlers

; Strong portcullis (object $27)
;
; Strong portcullis: object $27. It starts in forestriver and long lake. It is
; present. It has its own handling for GO THROUGH.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
STRONG_PORTCULLIS:
  DEFB $02                ; In 2 places
  DEFB $FF                ; Held by nothing
  DEFB $90                ; Size 144
  DEFB $FF                ; Weight 255: too heavy for anyone to lift
  DEFB $00                ; Things are in it
  DEFB $00                ; Strength 0
  DEFB $00                ; Defence 0
  DEFB $80                ; Flags: present
  DEFB $F1,$04            ; Its name: PORTCULLIS
  DEFB $64,$06            ; An adjective: STRONG
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
  DEFB $21,$22            ; In locations 33, forestriver; 34, long lake
  DEFB $1E                ; On GO THROUGH (action $1E)
  DEFW GO_THROUGH
  DEFB $FF                ; End of its handlers

; Stone (object $28)
;
; Stone: object $28. It starts in empty place. It is present. It has no
; handlers of its own: every action on it is the ordinary one.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
STONE:
  DEFB $01                ; In 1 place
  DEFB $FF                ; Held by nothing
  DEFB $FE                ; Size 254
  DEFB $FE                ; Weight 254
  DEFB $00                ; Things are in it
  DEFB $FF                ; Strength 255
  DEFB $FF                ; Defence 255
  DEFB $80                ; Flags: present
  DEFB $41,$36            ; Its name: STONE
  DEFB $00,$00            ; No adjective
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
  DEFB $2F                ; In location 47, empty place
  DEFB $FF                ; End of its handlers

; Nasty goblin (character $3D)
;
; Nasty goblin: character $3D. It starts in dark stuffy passage. It is present,
; a character, open, or can be seen into. It has its own handling for ATTACK
; WITH.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
NASTY_GOBLIN:
  DEFB $01                ; In 1 place
  DEFB $FF                ; Held by nothing
  DEFB $40                ; Size 64
  DEFB $30                ; Carries up to 48
  DEFB $20                ; Things are in it; on the goblins' side
  DEFB $48                ; Strength 72
  DEFB $60                ; Defence 96
  DEFB $E0                ; Flags: present, a character, open, or can be seen
                          ; into
  DEFB $E2,$02            ; Its name: GOBLIN
  DEFB $6A,$04            ; An adjective: NASTY
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
  DEFB $0F                ; In location 15, dark stuffy passage
  DEFB $0F                ; On ATTACK WITH (action $0F)
  DEFW DO_ATTACK
  DEFB $00                ; Key 0: after ATTACK WITH, as well
  DEFW GOBLIN_RETURNS
  DEFB $FF                ; End of its handlers

; Hideous goblin (character $45)
;
; Hideous goblin: character $45. It starts in dark stuffy passage. It is
; present, a character, open, or can be seen into. It has its own handling for
; ATTACK WITH.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
HIDEOUS_GOBLIN:
  DEFB $01                ; In 1 place
  DEFB $FF                ; Held by nothing
  DEFB $40                ; Size 64
  DEFB $30                ; Carries up to 48
  DEFB $20                ; Things are in it; on the goblins' side
  DEFB $48                ; Strength 72
  DEFB $60                ; Defence 96
  DEFB $E0                ; Flags: present, a character, open, or can be seen
                          ; into
  DEFB $E2,$02            ; Its name: GOBLIN
  DEFB $37,$03            ; An adjective: HIDEOUS
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
  DEFB $3A                ; In location 58, dark stuffy passage
  DEFB $0F                ; On ATTACK WITH (action $0F)
  DEFW DO_ATTACK
  DEFB $00                ; Key 0: after ATTACK WITH, as well
  DEFW GOBLIN_RETURNS
  DEFB $FF                ; End of its handlers

; Horrible goblin (character $49)
;
; Horrible goblin: character $49. It starts in dark winding passage. It is
; present, a character, open, or can be seen into. It has its own handling for
; ATTACK WITH.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
HORRIBLE_GOBLIN:
  DEFB $01                ; In 1 place
  DEFB $FF                ; Held by nothing
  DEFB $40                ; Size 64
  DEFB $30                ; Carries up to 48
  DEFB $20                ; Things are in it; on the goblins' side
  DEFB $48                ; Strength 72
  DEFB $60                ; Defence 96
  DEFB $E0                ; Flags: present, a character, open, or can be seen
                          ; into
  DEFB $E2,$02            ; Its name: GOBLIN
  DEFB $61,$03            ; An adjective: HORRIBLE
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
  DEFB $12                ; In location 18, dark winding passage
  DEFB $0F                ; On ATTACK WITH (action $0F)
  DEFW DO_ATTACK
  DEFB $00                ; Key 0: after ATTACK WITH, as well
  DEFW GOBLIN_RETURNS
  DEFB $FF                ; End of its handlers

; Mean goblin (character $4A)
;
; Mean goblin: character $4A. It starts in dark stuffy passage. It is present,
; a character, open, or can be seen into. It has its own handling for ATTACK
; WITH.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
MEAN_GOBLIN:
  DEFB $01                ; In 1 place
  DEFB $FF                ; Held by nothing
  DEFB $40                ; Size 64
  DEFB $30                ; Carries up to 48
  DEFB $20                ; Things are in it; on the goblins' side
  DEFB $48                ; Strength 72
  DEFB $60                ; Defence 96
  DEFB $E0                ; Flags: present, a character, open, or can be seen
                          ; into
  DEFB $E2,$02            ; Its name: GOBLIN
  DEFB $34,$04            ; An adjective: MEAN
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
  DEFB $38                ; In location 56, dark stuffy passage
  DEFB $0F                ; On ATTACK WITH (action $0F)
  DEFW DO_ATTACK
  DEFB $00                ; Key 0: after ATTACK WITH, as well
  DEFW GOBLIN_RETURNS
  DEFB $FF                ; End of its handlers

; Vicious goblin (character $4B)
;
; Vicious goblin: character $4B. It starts in dark stuffy passage. It is
; present, a character, open, or can be seen into. It has its own handling for
; ATTACK WITH.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
VICIOUS_GOBLIN:
  DEFB $01                ; In 1 place
  DEFB $FF                ; Held by nothing
  DEFB $40                ; Size 64
  DEFB $30                ; Carries up to 48
  DEFB $20                ; Things are in it; on the goblins' side
  DEFB $48                ; Strength 72
  DEFB $60                ; Defence 96
  DEFB $E0                ; Flags: present, a character, open, or can be seen
                          ; into
  DEFB $E2,$02            ; Its name: GOBLIN
  DEFB $41,$07            ; An adjective: VICIOUS
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
  DEFB $40                ; In location 64, dark stuffy passage
  DEFB $0F                ; On ATTACK WITH (action $0F)
  DEFW DO_ATTACK
  DEFB $00                ; Key 0: after ATTACK WITH, as well
  DEFW GOBLIN_RETURNS
  DEFB $FF                ; End of its handlers

; Disgusting goblin (character $4C)
;
; Disgusting goblin: character $4C. It starts in big goblins cavern. It is
; present, a character, open, or can be seen into. It has its own handling for
; ATTACK WITH.
;
; A record is a 16-byte head -- where it is, what holds it, its size, weight,
; strength and defence, its flags, its name and its description -- then the
; places it is in, then its own handlers, ending at $FF. OBJECT_INDEX describes
; each field.
DISGUSTING_GOBLIN:
  DEFB $01                ; In 1 place
  DEFB $FF                ; Held by nothing
  DEFB $40                ; Size 64
  DEFB $30                ; Carries up to 48
  DEFB $20                ; Things are in it; on the goblins' side
  DEFB $48                ; Strength 72
  DEFB $60                ; Defence 96
  DEFB $E0                ; Flags: present, a character, open, or can be seen
                          ; into
  DEFB $E2,$02            ; Its name: GOBLIN
  DEFB $B6,$01            ; An adjective: DISGUSTING
  DEFB $00,$00            ; No second adjective
  DEFB $00,$00            ; No description of its own
  DEFB $10                ; In location 16, big goblins cavern
  DEFB $0F                ; On ATTACK WITH (action $0F)
  DEFW DO_ATTACK
  DEFB $00                ; Key 0: after ATTACK WITH, as well
  DEFW GOBLIN_RETURNS
  DEFB $FF                ; End of its handlers

; What to do for each action code
;
; A FIND_RECORD table keyed by the action code in ACTION, whose values are the
; routines that carry the action out. Codes 1 to 10 are the ten directions and
; all go to MOVE, so one routine walks everybody everywhere; the other codes
; each have a handler of their own, a few of them shared.
;
; Every handler address here is real code on the table's own evidence: the
; playthrough reached 29 of the 31 as routine entry points. The two it did not,
; for codes 42 and 55, are the reason this table matters for the code map -- a
; dispatch is exactly what following branches cannot see through, so they are
; named here and seeded from here.
ACTION_TABLE:
  DEFB $01                ; GO NORTH (action $01)
  DEFW MOVE
  DEFB $02                ; GO SOUTH (action $02)
  DEFW MOVE
  DEFB $03                ; GO EAST (action $03)
  DEFW MOVE
  DEFB $04                ; GO WEST (action $04)
  DEFW MOVE
  DEFB $05                ; GO NORTHEAST (action $05)
  DEFW MOVE
  DEFB $06                ; GO NORTHWEST (action $06)
  DEFW MOVE
  DEFB $07                ; GO SOUTHEAST (action $07)
  DEFW MOVE
  DEFB $08                ; GO SOUTHWEST (action $08)
  DEFW MOVE
  DEFB $09                ; GO UP (action $09)
  DEFW MOVE
  DEFB $0A                ; GO DOWN (action $0A)
  DEFW MOVE
  DEFB $13                ; TAKE (action $13)
  DEFW DO_TAKE
  DEFB $0D                ; DROP (action $0D)
  DEFW DO_DROP
  DEFB $0F                ; ATTACK WITH (action $0F)
  DEFW DO_ATTACK
  DEFB $17                ; LOOK (action $17)
  DEFW DO_LOOK
  DEFB $1A                ; INVENTORY (action $1A)
  DEFW DO_INVENTORY
  DEFB $1C                ; EXAMINE (action $1C)
  DEFW DO_EXAMINE
  DEFB $1D                ; GIVE TO (action $1D)
  DEFW DO_GIVE
  DEFB $1F                ; ENTER (action $1F)
  DEFW DO_ENTER
  DEFB $20                ; GO INTO (action $20)
  DEFW DO_ENTER
  DEFB $24                ; RUN (action $24)
  DEFW DO_RUN
  DEFB $27                ; FOLLOW (action $27)
  DEFW DO_FOLLOW
  DEFB $2A                ; THROW AT (action $2A)
  DEFW DO_THROW_AT
  DEFB $30                ; CAPTURE (action $30)
  DEFW DO_CAPTURE
  DEFB $00                ; Key 0: after the one before (action $00)
  DEFW NOTE_LIGHT
  DEFB $33                ; UNTIE (action $33)
  DEFW DO_UNTIE
  DEFB $2E                ; TIE TO (action $2E)
  DEFW DO_TIE
  DEFB $2D                ; BURN (action $2D)
  DEFW DO_BURN
  DEFB $35                ; TALK TO (action $35)
  DEFW DO_TALK
  DEFB $3A                ; SHOOT (action $3A)
  DEFW DO_SHOOT
  DEFB $3B                ; CARRY (action $3B)
  DEFW DO_TAKE
  DEFB $37                ; CLIMB OUT OF (action $37)
  DEFW DO_CLIMB_OUT
  DEFB $FF

; What happens when the player arrives in certain places
;
; A FIND_RECORD table keyed by location, of routines MOVE runs when the player
; gets there. Most start one of TIMERS, which is how a place can be deadly only
; after a few turns in it.
ARRIVAL_HOOKS:
  DEFB $16,$A4,$C7        ; Location 22, Beorn's house: AT_BEORNS_HOUSE
  DEFB $1A,$B2,$C7        ; Location 26, the spider threads place:
                          ; AT_SPIDER_THREADS
  DEFB $1D,$B9,$C7        ; Location 29, the deep bog: AT_DEEP_BOG
  DEFB $21,$EA,$C7        ; Location 33, the forest river: AT_FOREST_RIVER
  DEFB $02,$DD,$C7        ; Location 2, the forest road: IN_THE_FOREST
  DEFB $03,$DD,$C7        ; Location 3, the forest: IN_THE_FOREST
  DEFB $20,$C0,$C7        ; Location 32, the elvenking's cellar:
                          ; AT_ELVENKINGS_CELLAR
  DEFB $FF                ; End of the table

; Arriving at Beorn's house: the butler joins in
;
; Unless the butler has flag bit 3 -- the bit that also keeps a character from
; reacting, and looks like being dead -- it is given the empty CHARACTERS slot
; at BUTLER_SLOT and made visible.
AT_BEORNS_HOUSE:
  LD HL,BUTLER_FLAGS
  BIT 3,(HL)
  RET NZ
  LD A,$42
  LD (BUTLER_SLOT),A
  SET 7,(HL)
  RET

; Arriving at the spider threads place: start timer 2
;
; Five turns later WEB_SMOTHERS kills a player still there.
AT_SPIDER_THREADS:
  LD A,(TIMER2)
  LD (TIMER2_COUNT),A
  RET

; Arriving in the deep bog: start timer 4
;
; SINKING_IN_BOG does the rest.
AT_DEEP_BOG:
  LD A,(TIMER4)
  LD (TIMER4_COUNT),A
  RET

; Arriving in the elvenking's cellar
;
; Starts timer 9, the hole in the mountain's side, at three turns rather than
; its usual five; and brings the dragon and Bard into the story, each unless it
; has flag bit 3, by giving them the empty CHARACTERS slots at
; RED_GOLDEN_DRAGON_SLOT and BARD_SLOT.
AT_ELVENKINGS_CELLAR:
  LD A,$03
  LD (TIMER9_COUNT),A
  LD HL,RED_GOLDEN_DRAGON_FLAGS
  BIT 3,(HL)
  JR NZ,AT_ELVENKINGS_CELLAR_0
  LD A,$3C
  LD (RED_GOLDEN_DRAGON_SLOT),A
AT_ELVENKINGS_CELLAR_0:
  LD HL,BARD_FLAGS
  BIT 3,(HL)
  RET NZ
  LD A,$46
  LD (BARD_SLOT),A
  RET

; Arriving on the forest road or in the forest: the eyes
;
; Keeps the place the player came into the forest by in FOREST_ENTRY -- the one
; EYES_WARNING counts as safe -- and starts timer 8.
IN_THE_FOREST:
  LD A,(DESTINATION)
  LD (FOREST_ENTRY),A
  LD A,(TIMER8)
  LD (TIMER8_COUNT),A
  RET

; Arriving at the forest river
;
; Out of the barrel, the player is swept against the portcullis and dies: "you
; are swept forcefully against the portcullis." In it, nothing happens here.
AT_FOREST_RIVER:
  LD A,(PLAYER_HOLDER)
  CP $13
  RET Z
  CALL ARRIVE
  LD HL,MSG_SWEPT_FORCEFULLY_AGAINST
  CALL RUN_MESSAGE_HL
  JP PLAYER_DIES

; Gollum's riddles
;
; Four entries, each the answer as a word reference and then the riddle as a
; message. There are only two riddles, each in the table twice;
; NEW_GAME_CHOICES picks among all four with RANDOM_POSITIVE given 3, which
; comes up with the four about equally, so the two riddles are even.
RIDDLES:
  DEFB $74,$04,$EE,$B1    ; NIGHT: "it cannot be seen, cannot be felt, cannot
                          ; be heard, cannot be smelt..."
  DEFB $29,$04,$B7,$B2    ; MAN: "which is the animal that has four feet in the
                          ; morning, two at midday and three in the evening ?"
  DEFB $74,$04,$EE,$B1    ; NIGHT again
  DEFB $29,$04,$B7,$B2    ; MAN again
  DEFB $FF,$FF            ; Not yet worked out

; The ways one of which is shut at the start of each game
;
; Six bytes each: the location, the address of one of its exits in the room
; records, and that exit's three bytes -- direction, the object it goes
; through, and destination -- kept here so that ELROND_READS_MAP can put them
; back. NEW_GAME_CHOICES picks one with RANDOM_POSITIVE given 4, so any of the
; five can be shut, the first and last half as often as the other three.
HIDDEN_ROADS:
  DEFB $16,$12,$BD,$01,$00,$31 ; Beorn's house, north to the great river
  DEFB $18,$26,$BD,$03,$00,$19 ; The forest gate, east to the bewitched gloomy
                               ; place
  DEFB $15,$F8,$BC,$04,$00,$14 ; The treeless opening, west to outside the
                               ; goblins' gate
  DEFB $22,$E2,$BD,$03,$00,$23 ; The long lake, east to lake town
  DEFB $0A,$0A,$BB,$03,$00,$0B ; The misty mountain, east to the narrow place
  DEFB $FF                ; End of the table

; Scripts: nasty goblin, hideous goblin
;
; What nasty goblin, hideous goblin does, turn by turn. CHARACTERS_ACT runs one
; step of a character's script each turn it can, and a step is an action the
; character tries as if it had typed it: RUN, TAKE, GIVE TO. A step that names
; nothing acts on whatever fits.
;
; First comes the script table: one entry per script, a key and the script's
; address. Key 0 is an ordinary script -- the ones a character wanders between,
; picked at random by a 'switch at random' step. Any other key is an action
; code, and that script is the character's reaction when that is done to it:
; attacked, given something, captured.
;
; Then the scripts, one step to a line. A step's first byte says what it is:
; its low four bits $00-$03 an action with objects (or, $01 and $03, a routine
; to call), $04 an action with none, $0E go to, $0F switch at random, $0C
; switch to a reaction. $10 added means an address follows, where the script
; goes on if the step is refused; $20 that the character's part is over once it
; works; $40 that an order from the player cannot interrupt it. So $14 is an
; action with no objects, with somewhere to go if it is refused. The Characters
; page has every script written out.
NASTY_GOBLIN_SCRIPTS:
  DEFB $00                ; Key 0, an ordinary script: NASTY_GOBLIN_A
  DEFW NASTY_GOBLIN_A
  DEFB $0F                ; Key $0F, ATTACK WITH: its reaction,
                          ; GOBLINS_ON_ATTACK_WITH
  DEFW GOBLINS_ON_ATTACK_WITH
  DEFB $FF                ; End of the table

; Scripts: vicious goblin
;
; What vicious goblin does, turn by turn. CHARACTERS_ACT runs one step of a
; character's script each turn it can, and a step is an action the character
; tries as if it had typed it: RUN, TAKE, GIVE TO. A step that names nothing
; acts on whatever fits.
;
; First comes the script table: one entry per script, a key and the script's
; address. Key 0 is an ordinary script -- the ones a character wanders between,
; picked at random by a 'switch at random' step. Any other key is an action
; code, and that script is the character's reaction when that is done to it:
; attacked, given something, captured.
;
; Then the scripts, one step to a line. A step's first byte says what it is:
; its low four bits $00-$03 an action with objects (or, $01 and $03, a routine
; to call), $04 an action with none, $0E go to, $0F switch at random, $0C
; switch to a reaction. $10 added means an address follows, where the script
; goes on if the step is refused; $20 that the character's part is over once it
; works; $40 that an order from the player cannot interrupt it. So $14 is an
; action with no objects, with somewhere to go if it is refused. The Characters
; page has every script written out.
VICIOUS_GOBLIN_SCRIPTS:
  DEFB $00                ; Key 0, an ordinary script: VICIOUS_GOBLIN_A
  DEFW VICIOUS_GOBLIN_A
  DEFB $0F                ; Key $0F, ATTACK WITH: its reaction,
                          ; GOBLINS_ON_ATTACK_WITH
  DEFW GOBLINS_ON_ATTACK_WITH
  DEFB $FF                ; End of the table

; Scripts: horrible goblin, mean goblin, disgusting goblin
;
; What horrible goblin, mean goblin, disgusting goblin does, turn by turn.
; CHARACTERS_ACT runs one step of a character's script each turn it can, and a
; step is an action the character tries as if it had typed it: RUN, TAKE, GIVE
; TO. A step that names nothing acts on whatever fits.
;
; First comes the script table: one entry per script, a key and the script's
; address. Key 0 is an ordinary script -- the ones a character wanders between,
; picked at random by a 'switch at random' step. Any other key is an action
; code, and that script is the character's reaction when that is done to it:
; attacked, given something, captured.
;
; Then the scripts, one step to a line. A step's first byte says what it is:
; its low four bits $00-$03 an action with objects (or, $01 and $03, a routine
; to call), $04 an action with none, $0E go to, $0F switch at random, $0C
; switch to a reaction. $10 added means an address follows, where the script
; goes on if the step is refused; $20 that the character's part is over once it
; works; $40 that an order from the player cannot interrupt it. So $14 is an
; action with no objects, with somewhere to go if it is refused. The Characters
; page has every script written out.
HORRIBLE_GOBLIN_SCRIPTS:
  DEFB $00                ; Key 0, an ordinary script: HORRIBLE_GOBLIN_A
  DEFW HORRIBLE_GOBLIN_A
  DEFB $0F                ; Key $0F, ATTACK WITH: its reaction,
                          ; GOBLINS_ON_ATTACK_WITH
  DEFW GOBLINS_ON_ATTACK_WITH
  DEFB $FF                ; End of the table
; NASTY_GOBLIN_A -- An ordinary script: OPEN: small insignificant crack, then
; on as GOBLINS_A.
NASTY_GOBLIN_A:
  DEFB $02,$10,$06,$FF    ; OPEN: small insignificant crack
; GOBLINS_A -- Where a jump or a refusal goes on: CAPTURE, Go to GOBLINS_A.
GOBLINS_A:
  DEFB $14,$30            ; CAPTURE
  DEFW GOBLINS_B          ; If it is refused: GOBLINS_B
  DEFB $0E                ; Go to GOBLINS_A
  DEFW GOBLINS_A
; GOBLINS_B -- Where a jump or a refusal goes on: GO UP, then on as GOBLINS_C.
GOBLINS_B:
  DEFB $04,$09            ; GO UP
; GOBLINS_C -- Where a jump or a refusal goes on: CAPTURE, Go to GOBLINS_C.
GOBLINS_C:
  DEFB $14,$30            ; CAPTURE
  DEFW GOBLINS_D          ; If it is refused: GOBLINS_D
  DEFB $0E                ; Go to GOBLINS_C
  DEFW GOBLINS_C
; GOBLINS_D -- Where a jump or a refusal goes on: GO DOWN, then on as
; GOBLINS_E.
GOBLINS_D:
  DEFB $04,$0A            ; GO DOWN
; GOBLINS_E -- Where a jump or a refusal goes on: CAPTURE, Go to GOBLINS_E.
GOBLINS_E:
  DEFB $14,$30            ; CAPTURE
  DEFW GOBLINS_F          ; If it is refused: GOBLINS_F
  DEFB $0E                ; Go to GOBLINS_E
  DEFW GOBLINS_E
; GOBLINS_F -- Where a jump or a refusal goes on: CLOSE: small insignificant
; crack, GO SOUTH, then on as GOBLINS_G.
GOBLINS_F:
  DEFB $02,$0C,$06,$FF    ; CLOSE: small insignificant crack
  DEFB $04,$02            ; GO SOUTH
; GOBLINS_G -- Where a jump or a refusal goes on: CAPTURE, Go to GOBLINS_G.
GOBLINS_G:
  DEFB $14,$30            ; CAPTURE
  DEFW GOBLINS_H          ; If it is refused: GOBLINS_H
  DEFB $0E                ; Go to GOBLINS_G
  DEFW GOBLINS_G
; GOBLINS_H -- Where a jump or a refusal goes on: GO NORTH, Go to
; NASTY_GOBLIN_A.
GOBLINS_H:
  DEFB $04,$01            ; GO NORTH
  DEFB $0E                ; Go to NASTY_GOBLIN_A
  DEFW NASTY_GOBLIN_A
; VICIOUS_GOBLIN_A -- An ordinary script: GO NORTHWEST, then on as GOBLINS_I.
VICIOUS_GOBLIN_A:
  DEFB $04,$06            ; GO NORTHWEST
; GOBLINS_I -- Where a jump or a refusal goes on: CAPTURE, Go to GOBLINS_I.
GOBLINS_I:
  DEFB $14,$30            ; CAPTURE
  DEFW GOBLINS_J          ; If it is refused: GOBLINS_J
  DEFB $0E                ; Go to GOBLINS_I
  DEFW GOBLINS_I
; GOBLINS_J -- Where a jump or a refusal goes on: GO NORTH, then on as
; GOBLINS_K.
GOBLINS_J:
  DEFB $04,$01            ; GO NORTH
; GOBLINS_K -- Where a jump or a refusal goes on: CAPTURE, Go to GOBLINS_K.
GOBLINS_K:
  DEFB $14,$30            ; CAPTURE
  DEFW GOBLINS_L          ; If it is refused: GOBLINS_L
  DEFB $0E                ; Go to GOBLINS_K
  DEFW GOBLINS_K
; GOBLINS_L -- Where a jump or a refusal goes on: GO SOUTHWEST, then on as
; GOBLINS_M.
GOBLINS_L:
  DEFB $04,$08            ; GO SOUTHWEST
; GOBLINS_M -- Where a jump or a refusal goes on: CAPTURE, Go to GOBLINS_M.
GOBLINS_M:
  DEFB $14,$30            ; CAPTURE
  DEFW GOBLINS_N          ; If it is refused: GOBLINS_N
  DEFB $0E                ; Go to GOBLINS_M
  DEFW GOBLINS_M
; GOBLINS_N -- Where a jump or a refusal goes on: GO UP, then on as GOBLINS_O.
GOBLINS_N:
  DEFB $04,$09            ; GO UP
; GOBLINS_O -- Where a jump or a refusal goes on: CAPTURE, Go to GOBLINS_O.
GOBLINS_O:
  DEFB $14,$30            ; CAPTURE
  DEFW VICIOUS_GOBLIN_A   ; If it is refused: VICIOUS_GOBLIN_A
  DEFB $0E                ; Go to GOBLINS_O
  DEFW GOBLINS_O
; HORRIBLE_GOBLIN_A -- An ordinary script: RUN, ATTACK WITH, CAPTURE, Go to
; HORRIBLE_GOBLIN_A.
HORRIBLE_GOBLIN_A:
  DEFB $04,$24            ; RUN
  DEFB $04,$0F            ; ATTACK WITH
  DEFB $04,$30            ; CAPTURE
  DEFB $0E                ; Go to HORRIBLE_GOBLIN_A
  DEFW HORRIBLE_GOBLIN_A
; GOBLINS_ON_ATTACK_WITH -- The reaction to ATTACK WITH: CAPTURE, Back to its
; first script.
GOBLINS_ON_ATTACK_WITH:
  DEFB $04,$30            ; CAPTURE
  DEFB $07                ; Back to its first script

; Scripts: gandalf
;
; What gandalf does, turn by turn. CHARACTERS_ACT runs one step of a
; character's script each turn it can, and a step is an action the character
; tries as if it had typed it: RUN, TAKE, GIVE TO. A step that names nothing
; acts on whatever fits.
;
; First comes the script table: one entry per script, a key and the script's
; address. Key 0 is an ordinary script -- the ones a character wanders between,
; picked at random by a 'switch at random' step. Any other key is an action
; code, and that script is the character's reaction when that is done to it:
; attacked, given something, captured.
;
; Then the scripts, one step to a line. A step's first byte says what it is:
; its low four bits $00-$03 an action with objects (or, $01 and $03, a routine
; to call), $04 an action with none, $0E go to, $0F switch at random, $0C
; switch to a reaction. $10 added means an address follows, where the script
; goes on if the step is refused; $20 that the character's part is over once it
; works; $40 that an order from the player cannot interrupt it. So $14 is an
; action with no objects, with somewhere to go if it is refused. The Characters
; page has every script written out.
GANDALF_SCRIPTS:
  DEFB $00                ; Key 0, an ordinary script: GANDALF_A
  DEFW GANDALF_A
  DEFB $00                ; Key 0, an ordinary script: GANDALF_B
  DEFW GANDALF_B
  DEFB $00                ; Key 0, an ordinary script: GANDALF_C
  DEFW GANDALF_C
  DEFB $00                ; Key 0, an ordinary script: GANDALF_D
  DEFW GANDALF_D
  DEFB $00                ; Key 0, an ordinary script: GANDALF_E
  DEFW GANDALF_E
  DEFB $1D                ; Key $1D, GIVE TO: its reaction, ON_GIVE_TO
  DEFW ON_GIVE_TO
  DEFB $30                ; Key $30, CAPTURE: its reaction, GANDALF_ON_CAPTURE
  DEFW GANDALF_ON_CAPTURE
  DEFB $0F                ; Key $0F, ATTACK WITH: its reaction, ON_ATTACK_WITH
  DEFW ON_ATTACK_WITH
  DEFB $FF                ; End of the table
; GANDALF_F -- Where the script starts: GIVE TO: curious map, the player, OPEN:
; round green door, then on as GANDALF_A.
GANDALF_F:
  DEFB $02,$1D,$03,$00    ; GIVE TO: curious map, the player
  DEFB $02,$10,$05,$FF    ; OPEN: round green door
; GANDALF_A -- An ordinary script: RUN, TAKE, GANDALF_WHATS_THIS, CLOSE, GIVE
; TO, then on as GANDALF_B.
GANDALF_A:
  DEFB $04,$24            ; RUN
  DEFB $14,$13            ; TAKE
  DEFW GANDALF_B          ; If it is refused: GANDALF_B
  DEFB $03                ; Call GANDALF_WHATS_THIS
  DEFW GANDALF_WHATS_THIS
  DEFB $00                ; Not used
  DEFB $04,$0C            ; CLOSE
  DEFB $04,$1D            ; GIVE TO
; GANDALF_B -- An ordinary script: RUN, DROP, then on as GANDALF_C.
GANDALF_B:
  DEFB $04,$24            ; RUN
  DEFB $04,$0D            ; DROP
; GANDALF_C -- An ordinary script: RUN, GANDALF_CHATTER, then on as GANDALF_D.
GANDALF_C:
  DEFB $04,$24            ; RUN
  DEFB $03                ; Call GANDALF_CHATTER
  DEFW GANDALF_CHATTER
  DEFB $00                ; Not used
; GANDALF_D -- An ordinary script: RUN, GIVE TO, then on as GANDALF_E.
GANDALF_D:
  DEFB $04,$24            ; RUN
  DEFB $04,$1D            ; GIVE TO
; GANDALF_E -- An ordinary script: OPEN, switch at random among its first 4.
GANDALF_E:
  DEFB $04,$10            ; OPEN
  DEFB $0F,$04            ; Switch to one of its first 4 scripts at random

; Scripts: thorin
;
; What thorin does, turn by turn. CHARACTERS_ACT runs one step of a character's
; script each turn it can, and a step is an action the character tries as if it
; had typed it: RUN, TAKE, GIVE TO. A step that names nothing acts on whatever
; fits.
;
; First comes the script table: one entry per script, a key and the script's
; address. Key 0 is an ordinary script -- the ones a character wanders between,
; picked at random by a 'switch at random' step. Any other key is an action
; code, and that script is the character's reaction when that is done to it:
; attacked, given something, captured.
;
; Then the scripts, one step to a line. A step's first byte says what it is:
; its low four bits $00-$03 an action with objects (or, $01 and $03, a routine
; to call), $04 an action with none, $0E go to, $0F switch at random, $0C
; switch to a reaction. $10 added means an address follows, where the script
; goes on if the step is refused; $20 that the character's part is over once it
; works; $40 that an order from the player cannot interrupt it. So $14 is an
; action with no objects, with somewhere to go if it is refused. The Characters
; page has every script written out.
THORIN_SCRIPTS:
  DEFB $00                ; Key 0, an ordinary script: THORIN_A
  DEFW THORIN_A
  DEFB $1D                ; Key $1D, GIVE TO: its reaction, ON_GIVE_TO
  DEFW ON_GIVE_TO
  DEFB $0F                ; Key $0F, ATTACK WITH: its reaction, ON_ATTACK_WITH
  DEFW ON_ATTACK_WITH
  DEFB $FF                ; End of the table
; THORIN_A -- An ordinary script: FOLLOW: the player, Go to THORIN_A.
THORIN_A:
  DEFB $12,$27,$00,$FF    ; FOLLOW: the player
  DEFW THORIN_B           ; If it is refused: THORIN_B
  DEFB $0E                ; Go to THORIN_A
  DEFW THORIN_A
; THORIN_B -- Where a jump or a refusal goes on: TAKE: small curious key,
; THORIN_THRAINS_KEY, then on as THORIN_C.
THORIN_B:
  DEFB $12,$13,$02,$FF    ; TAKE: small curious key
  DEFW THORIN_C           ; If it is refused: THORIN_C
  DEFB $23                ; Call THORIN_THRAINS_KEY (then its part in the story
                          ; is over)
  DEFW THORIN_THRAINS_KEY
  DEFB $00                ; Not used
; THORIN_C -- Where a jump or a refusal goes on: THORIN_WHERES_THIEF, Pause:
; nothing this turn, RUN, Go to THORIN_A.
THORIN_C:
  DEFB $13                ; Call THORIN_WHERES_THIEF
  DEFW THORIN_WHERES_THIEF
  DEFB $00                ; Not used
  DEFW THORIN_D           ; If it is refused: THORIN_D
  DEFB $04,$FF            ; Pause: nothing this turn
  DEFB $04,$24            ; RUN
  DEFB $0E                ; Go to THORIN_A
  DEFW THORIN_A
; THORIN_D -- Where a jump or a refusal goes on: THORIN_CHATTER, Go to
; THORIN_A.
THORIN_D:
  DEFB $03                ; Call THORIN_CHATTER
  DEFW THORIN_CHATTER
  DEFB $00                ; Not used
  DEFB $0E                ; Go to THORIN_A
  DEFW THORIN_A

; Scripts: wood elf
;
; What wood elf does, turn by turn. CHARACTERS_ACT runs one step of a
; character's script each turn it can, and a step is an action the character
; tries as if it had typed it: RUN, TAKE, GIVE TO. A step that names nothing
; acts on whatever fits.
;
; First comes the script table: one entry per script, a key and the script's
; address. Key 0 is an ordinary script -- the ones a character wanders between,
; picked at random by a 'switch at random' step. Any other key is an action
; code, and that script is the character's reaction when that is done to it:
; attacked, given something, captured.
;
; Then the scripts, one step to a line. A step's first byte says what it is:
; its low four bits $00-$03 an action with objects (or, $01 and $03, a routine
; to call), $04 an action with none, $0E go to, $0F switch at random, $0C
; switch to a reaction. $10 added means an address follows, where the script
; goes on if the step is refused; $20 that the character's part is over once it
; works; $40 that an order from the player cannot interrupt it. So $14 is an
; action with no objects, with somewhere to go if it is refused. The Characters
; page has every script written out.
WOOD_ELF_SCRIPTS:
  DEFB $00                ; Key 0, an ordinary script: WOOD_ELF_A
  DEFW WOOD_ELF_A
  DEFB $0F                ; Key $0F, ATTACK WITH: its reaction, WOOD_ELF_A
  DEFW WOOD_ELF_A
  DEFB $1D                ; Key $1D, GIVE TO: its reaction, ON_GIVE_TO
  DEFW ON_GIVE_TO
  DEFB $FF                ; End of the table
; WOOD_ELF_A -- An ordinary script: CAPTURE, RUN, Go to WOOD_ELF_A.
WOOD_ELF_A:
  DEFB $04,$30            ; CAPTURE
  DEFB $04,$24            ; RUN
  DEFB $0E                ; Go to WOOD_ELF_A
  DEFW WOOD_ELF_A

; Scripts: vicious warg
;
; What vicious warg does, turn by turn. CHARACTERS_ACT runs one step of a
; character's script each turn it can, and a step is an action the character
; tries as if it had typed it: RUN, TAKE, GIVE TO. A step that names nothing
; acts on whatever fits.
;
; First comes the script table: one entry per script, a key and the script's
; address. Key 0 is an ordinary script -- the ones a character wanders between,
; picked at random by a 'switch at random' step. Any other key is an action
; code, and that script is the character's reaction when that is done to it:
; attacked, given something, captured.
;
; Then the scripts, one step to a line. A step's first byte says what it is:
; its low four bits $00-$03 an action with objects (or, $01 and $03, a routine
; to call), $04 an action with none, $0E go to, $0F switch at random, $0C
; switch to a reaction. $10 added means an address follows, where the script
; goes on if the step is refused; $20 that the character's part is over once it
; works; $40 that an order from the player cannot interrupt it. So $14 is an
; action with no objects, with somewhere to go if it is refused. The Characters
; page has every script written out.
VICIOUS_WARG_SCRIPTS:
  DEFB $00                ; Key 0, an ordinary script: VICIOUS_WARG_A
  DEFW VICIOUS_WARG_A
  DEFB $FF                ; End of the table
; VICIOUS_WARG_A -- An ordinary script: ATTACK WITH, Go to VICIOUS_WARG_A.
VICIOUS_WARG_A:
  DEFB $14,$0F            ; ATTACK WITH
  DEFW VICIOUS_WARG_B     ; If it is refused: VICIOUS_WARG_B
  DEFB $0E                ; Go to VICIOUS_WARG_A
  DEFW VICIOUS_WARG_A
; VICIOUS_WARG_B -- Where a jump or a refusal goes on: FOLLOW, WARG_HOWLS, Go
; to VICIOUS_WARG_A.
VICIOUS_WARG_B:
  DEFB $14,$27            ; FOLLOW
  DEFW VICIOUS_WARG_C     ; If it is refused: VICIOUS_WARG_C
  DEFB $03                ; Call WARG_HOWLS
  DEFW WARG_HOWLS
  DEFB $00                ; Not used
  DEFB $0E                ; Go to VICIOUS_WARG_A
  DEFW VICIOUS_WARG_A
; VICIOUS_WARG_C -- Where a jump or a refusal goes on: RUN, Go to
; VICIOUS_WARG_A.
VICIOUS_WARG_C:
  DEFB $14,$24            ; RUN
  DEFW VICIOUS_WARG_D     ; If it is refused: VICIOUS_WARG_D
  DEFB $0E                ; Go to VICIOUS_WARG_A
  DEFW VICIOUS_WARG_A
; VICIOUS_WARG_D -- Where a jump or a refusal goes on: Pause: nothing this
; turn, Go to VICIOUS_WARG_A.
VICIOUS_WARG_D:
  DEFB $04,$FF            ; Pause: nothing this turn
  DEFB $0E                ; Go to VICIOUS_WARG_A
  DEFW VICIOUS_WARG_A

; Scripts: butler
;
; What butler does, turn by turn. CHARACTERS_ACT runs one step of a character's
; script each turn it can, and a step is an action the character tries as if it
; had typed it: RUN, TAKE, GIVE TO. A step that names nothing acts on whatever
; fits.
;
; First comes the script table: one entry per script, a key and the script's
; address. Key 0 is an ordinary script -- the ones a character wanders between,
; picked at random by a 'switch at random' step. Any other key is an action
; code, and that script is the character's reaction when that is done to it:
; attacked, given something, captured.
;
; Then the scripts, one step to a line. A step's first byte says what it is:
; its low four bits $00-$03 an action with objects (or, $01 and $03, a routine
; to call), $04 an action with none, $0E go to, $0F switch at random, $0C
; switch to a reaction. $10 added means an address follows, where the script
; goes on if the step is refused; $20 that the character's part is over once it
; works; $40 that an order from the player cannot interrupt it. So $14 is an
; action with no objects, with somewhere to go if it is refused. The Characters
; page has every script written out.
BUTLER_SCRIPTS:
  DEFB $00                ; Key 0, an ordinary script: BUTLER_A
  DEFW BUTLER_A
  DEFB $0F                ; Key $0F, ATTACK WITH: its reaction,
                          ; BUTLER_ON_ATTACK_WITH
  DEFW BUTLER_ON_ATTACK_WITH
  DEFB $1D                ; Key $1D, GIVE TO: its reaction, ON_GIVE_TO
  DEFW ON_GIVE_TO
  DEFB $FF                ; End of the table
; BUTLER_A -- An ordinary script: UNLOCK WITH: red door, red key, OPEN: red
; door, CLOSE: red door, LOCK WITH: red door, red key, then on as
; BUTLER_ON_ATTACK_WITH.
BUTLER_A:
  DEFB $02,$26,$08,$0F    ; UNLOCK WITH: red door, red key
  DEFB $02,$10,$08,$FF    ; OPEN: red door
  DEFB $02,$0C,$08,$FF    ; CLOSE: red door
  DEFB $02,$25,$08,$0F    ; LOCK WITH: red door, red key
; BUTLER_ON_ATTACK_WITH -- The reaction to ATTACK WITH: CAPTURE, Go to
; BUTLER_ON_ATTACK_WITH.
BUTLER_ON_ATTACK_WITH:
  DEFB $14,$30            ; CAPTURE
  DEFW BUTLER_B           ; If it is refused: BUTLER_B
  DEFB $0E                ; Go to BUTLER_ON_ATTACK_WITH
  DEFW BUTLER_ON_ATTACK_WITH
; BUTLER_B -- Where a jump or a refusal goes on: OPEN: barrel, DRINK: wine,
; CAPTURE, CLOSE: barrel, OPEN: large trap door, CAPTURE, TAKE: barrel, THROW
; THROUGH: barrel, large trap door, CAPTURE, CLOSE: large trap door, CAPTURE,
; Go to BUTLER_A.
BUTLER_B:
  DEFB $02,$10,$13,$FF    ; OPEN: barrel
  DEFB $02,$21,$14,$FF    ; DRINK: wine
  DEFB $04,$30            ; CAPTURE
  DEFB $02,$0C,$13,$FF    ; CLOSE: barrel
  DEFB $02,$10,$0C,$FF    ; OPEN: large trap door
  DEFB $04,$30            ; CAPTURE
  DEFB $02,$13,$13,$FF    ; TAKE: barrel
  DEFB $02,$2C,$13,$0C    ; THROW THROUGH: barrel, large trap door
  DEFB $04,$30            ; CAPTURE
  DEFB $02,$0C,$0C,$FF    ; CLOSE: large trap door
  DEFB $14,$30            ; CAPTURE
  DEFW BUTLER_A           ; If it is refused: BUTLER_A
  DEFB $0E                ; Go to BUTLER_A
  DEFW BUTLER_A

; Scripts: elrond
;
; What elrond does, turn by turn. CHARACTERS_ACT runs one step of a character's
; script each turn it can, and a step is an action the character tries as if it
; had typed it: RUN, TAKE, GIVE TO. A step that names nothing acts on whatever
; fits.
;
; First comes the script table: one entry per script, a key and the script's
; address. Key 0 is an ordinary script -- the ones a character wanders between,
; picked at random by a 'switch at random' step. Any other key is an action
; code, and that script is the character's reaction when that is done to it:
; attacked, given something, captured.
;
; Then the scripts, one step to a line. A step's first byte says what it is:
; its low four bits $00-$03 an action with objects (or, $01 and $03, a routine
; to call), $04 an action with none, $0E go to, $0F switch at random, $0C
; switch to a reaction. $10 added means an address follows, where the script
; goes on if the step is refused; $20 that the character's part is over once it
; works; $40 that an order from the player cannot interrupt it. So $14 is an
; action with no objects, with somewhere to go if it is refused. The Characters
; page has every script written out.
ELROND_SCRIPTS:
  DEFB $00                ; Key 0, an ordinary script: ELROND_A
  DEFW ELROND_A
  DEFB $0F                ; Key $0F, ATTACK WITH: its reaction,
                          ; ELROND_ON_ATTACK_WITH
  DEFW ELROND_ON_ATTACK_WITH
  DEFB $1D                ; Key $1D, GIVE TO: its reaction, ON_GIVE_TO
  DEFW ON_GIVE_TO
  DEFB $FF                ; End of the table
; ELROND_B -- Where the script starts: ELROND_HELLO, then on as ELROND_A.
ELROND_B:
  DEFB $13                ; Call ELROND_HELLO
  DEFW ELROND_HELLO
  DEFB $00                ; Not used
  DEFW ELROND_C           ; If it is refused: ELROND_C
; ELROND_A -- An ordinary script: ELROND_GIVES_LUNCH, then on as ELROND_C.
ELROND_A:
  DEFB $03                ; Call ELROND_GIVES_LUNCH
  DEFW ELROND_GIVES_LUNCH
  DEFB $00                ; Not used
; ELROND_C -- Where a jump or a refusal goes on: Pause: nothing this turn,
; Pause: nothing this turn, then on as ELROND_ON_ATTACK_WITH.
ELROND_C:
  DEFB $04,$FF            ; Pause: nothing this turn
  DEFB $14,$FF            ; Pause: nothing this turn
  DEFW ELROND_B           ; If it is refused: ELROND_B
; ELROND_ON_ATTACK_WITH -- The reaction to ATTACK WITH: ATTACK WITH, Go to
; ELROND_ON_ATTACK_WITH.
ELROND_ON_ATTACK_WITH:
  DEFB $14,$0F            ; ATTACK WITH
  DEFW ELROND_B           ; If it is refused: ELROND_B
  DEFB $0E                ; Go to ELROND_ON_ATTACK_WITH
  DEFW ELROND_ON_ATTACK_WITH

; Scripts: red golden dragon
;
; What red golden dragon does, turn by turn. CHARACTERS_ACT runs one step of a
; character's script each turn it can, and a step is an action the character
; tries as if it had typed it: RUN, TAKE, GIVE TO. A step that names nothing
; acts on whatever fits.
;
; First comes the script table: one entry per script, a key and the script's
; address. Key 0 is an ordinary script -- the ones a character wanders between,
; picked at random by a 'switch at random' step. Any other key is an action
; code, and that script is the character's reaction when that is done to it:
; attacked, given something, captured.
;
; Then the scripts, one step to a line. A step's first byte says what it is:
; its low four bits $00-$03 an action with objects (or, $01 and $03, a routine
; to call), $04 an action with none, $0E go to, $0F switch at random, $0C
; switch to a reaction. $10 added means an address follows, where the script
; goes on if the step is refused; $20 that the character's part is over once it
; works; $40 that an order from the player cannot interrupt it. So $14 is an
; action with no objects, with somewhere to go if it is refused. The Characters
; page has every script written out.
RED_GOLDEN_DRAGON_SCRIPTS:
  DEFB $00                ; Key 0, an ordinary script: RED_GOLDEN_DRAGON_A
  DEFW RED_GOLDEN_DRAGON_A
  DEFB $0F                ; Key $0F, ATTACK WITH: its reaction,
                          ; RED_GOLDEN_DRAGON_ON_ATTACK_WITH
  DEFW RED_GOLDEN_DRAGON_ON_ATTACK_WITH
  DEFB $FF                ; End of the table
; RED_GOLDEN_DRAGON_A -- An ordinary script: DRAGON_HUNTS, Go to
; RED_GOLDEN_DRAGON_A.
RED_GOLDEN_DRAGON_A:
  DEFB $13                ; Call DRAGON_HUNTS
  DEFW DRAGON_HUNTS
  DEFB $00                ; Not used
  DEFW RED_GOLDEN_DRAGON_B ; If it is refused: RED_GOLDEN_DRAGON_B
  DEFB $0E                ; Go to RED_GOLDEN_DRAGON_A
  DEFW RED_GOLDEN_DRAGON_A
; RED_GOLDEN_DRAGON_B -- Where a jump or a refusal goes on: DRAGON_FOLLOWS,
; DRAGON_THREATENS, then on as RED_GOLDEN_DRAGON_ON_ATTACK_WITH.
RED_GOLDEN_DRAGON_B:
  DEFB $13                ; Call DRAGON_FOLLOWS
  DEFW DRAGON_FOLLOWS
  DEFB $00                ; Not used
  DEFW RED_GOLDEN_DRAGON_C ; If it is refused: RED_GOLDEN_DRAGON_C
  DEFB $13                ; Call DRAGON_THREATENS
  DEFW DRAGON_THREATENS
  DEFB $00                ; Not used
  DEFW RED_GOLDEN_DRAGON_C ; If it is refused: RED_GOLDEN_DRAGON_C
; RED_GOLDEN_DRAGON_ON_ATTACK_WITH -- The reaction to ATTACK WITH: BURN, Go to
; RED_GOLDEN_DRAGON_A.
RED_GOLDEN_DRAGON_ON_ATTACK_WITH:
  DEFB $04,$2D            ; BURN
  DEFB $0E                ; Go to RED_GOLDEN_DRAGON_A
  DEFW RED_GOLDEN_DRAGON_A
; RED_GOLDEN_DRAGON_C -- Where a jump or a refusal goes on: RUN, Go to
; RED_GOLDEN_DRAGON_A.
RED_GOLDEN_DRAGON_C:
  DEFB $04,$24            ; RUN
  DEFB $0E                ; Go to RED_GOLDEN_DRAGON_A
  DEFW RED_GOLDEN_DRAGON_A

; Scripts: bard
;
; What bard does, turn by turn. CHARACTERS_ACT runs one step of a character's
; script each turn it can, and a step is an action the character tries as if it
; had typed it: RUN, TAKE, GIVE TO. A step that names nothing acts on whatever
; fits.
;
; First comes the script table: one entry per script, a key and the script's
; address. Key 0 is an ordinary script -- the ones a character wanders between,
; picked at random by a 'switch at random' step. Any other key is an action
; code, and that script is the character's reaction when that is done to it:
; attacked, given something, captured.
;
; Then the scripts, one step to a line. A step's first byte says what it is:
; its low four bits $00-$03 an action with objects (or, $01 and $03, a routine
; to call), $04 an action with none, $0E go to, $0F switch at random, $0C
; switch to a reaction. $10 added means an address follows, where the script
; goes on if the step is refused; $20 that the character's part is over once it
; works; $40 that an order from the player cannot interrupt it. So $14 is an
; action with no objects, with somewhere to go if it is refused. The Characters
; page has every script written out.
BARD_SCRIPTS:
  DEFB $00                ; Key 0, an ordinary script: BARD_A
  DEFW BARD_A
  DEFB $0F                ; Key $0F, ATTACK WITH: its reaction,
                          ; BARD_ON_ATTACK_WITH
  DEFW BARD_ON_ATTACK_WITH
  DEFB $FF                ; End of the table
; BARD_A -- An ordinary script: BARD_TAKES_ORDER, TAKE: wooden chest, Go to
; BARD_A.
BARD_A:
  DEFB $43                ; Call BARD_TAKES_ORDER (an order cannot interrupt
                          ; it)
  DEFW BARD_TAKES_ORDER
  DEFB $00                ; Not used
BARD_ORDER_STEP:
  DEFB $42                ; TAKE: wooden chest (an order cannot interrupt it)
                          ; -- rewritten by BARD_TAKES_ORDER with each order
                          ; Bard is given
BARD_ORDER_ACTION:
  DEFB $13                ; The action
BARD_ORDER_OBJECTS:
  DEFB $25,$FF            ; Its objects
  DEFB $0E                ; Go to BARD_A
  DEFW BARD_A
; BARD_ON_ATTACK_WITH -- The reaction to ATTACK WITH: SHOOT, Go to
; BARD_ON_ATTACK_WITH.
BARD_ON_ATTACK_WITH:
  DEFB $54,$3A            ; SHOOT (an order cannot interrupt it)
  DEFW ON_ATTACK_WITH     ; If it is refused: ON_ATTACK_WITH
  DEFB $0E                ; Go to BARD_ON_ATTACK_WITH
  DEFW BARD_ON_ATTACK_WITH

; Scripts: gollum
;
; What gollum does, turn by turn. CHARACTERS_ACT runs one step of a character's
; script each turn it can, and a step is an action the character tries as if it
; had typed it: RUN, TAKE, GIVE TO. A step that names nothing acts on whatever
; fits.
;
; First comes the script table: one entry per script, a key and the script's
; address. Key 0 is an ordinary script -- the ones a character wanders between,
; picked at random by a 'switch at random' step. Any other key is an action
; code, and that script is the character's reaction when that is done to it:
; attacked, given something, captured.
;
; Then the scripts, one step to a line. A step's first byte says what it is:
; its low four bits $00-$03 an action with objects (or, $01 and $03, a routine
; to call), $04 an action with none, $0E go to, $0F switch at random, $0C
; switch to a reaction. $10 added means an address follows, where the script
; goes on if the step is refused; $20 that the character's part is over once it
; works; $40 that an order from the player cannot interrupt it. So $14 is an
; action with no objects, with somewhere to go if it is refused. The Characters
; page has every script written out.
GOLLUM_SCRIPTS:
  DEFB $00                ; Key 0, an ordinary script: GOLLUM_A
  DEFW GOLLUM_A
  DEFB $0F                ; Key $0F, ATTACK WITH: its reaction,
                          ; GOLLUM_ON_ATTACK_WITH
  DEFW GOLLUM_ON_ATTACK_WITH
  DEFB $FF                ; End of the table
; GOLLUM_A -- An ordinary script: GOLLUM_ASKS, GOLLUM_HEARS_ANSWER, DROP:
; valuable golden ring, GO NORTH, then on as GOLLUM_B.
GOLLUM_A:
  DEFB $13                ; Call GOLLUM_ASKS
  DEFW GOLLUM_ASKS
  DEFB $00                ; Not used
  DEFW GOLLUM_C           ; If it is refused: GOLLUM_C
  DEFB $43                ; Call GOLLUM_HEARS_ANSWER (an order cannot interrupt
                          ; it)
  DEFW GOLLUM_HEARS_ANSWER
  DEFB $00                ; Not used
  DEFB $02,$0D,$10,$FF    ; DROP: valuable golden ring
  DEFB $14,$01            ; GO NORTH
  DEFW GOLLUM_E           ; If it is refused: GOLLUM_E
; GOLLUM_B -- Where a jump or a refusal goes on: TAKE: valuable golden ring, Go
; to GOLLUM_A.
GOLLUM_B:
  DEFB $02,$13,$10,$FF    ; TAKE: valuable golden ring
  DEFB $0E                ; Go to GOLLUM_A
  DEFW GOLLUM_A
; GOLLUM_C -- Where a jump or a refusal goes on: GO NORTH, then on as GOLLUM_D.
GOLLUM_C:
  DEFB $14,$01            ; GO NORTH
  DEFW GOLLUM_F           ; If it is refused: GOLLUM_F
; GOLLUM_D -- Where a jump or a refusal goes on: GOLLUM_POCKETS, TAKE: valuable
; golden ring, Go to GOLLUM_A.
GOLLUM_D:
  DEFB $13                ; Call GOLLUM_POCKETS
  DEFW GOLLUM_POCKETS
  DEFB $00                ; Not used
  DEFW GOLLUM_A           ; If it is refused: GOLLUM_A
  DEFB $02,$13,$10,$FF    ; TAKE: valuable golden ring
  DEFB $0E                ; Go to GOLLUM_A
  DEFW GOLLUM_A
; GOLLUM_E -- Where a jump or a refusal goes on: GO SOUTHWEST, Go to GOLLUM_B.
GOLLUM_E:
  DEFB $04,$08            ; GO SOUTHWEST
  DEFB $0E                ; Go to GOLLUM_B
  DEFW GOLLUM_B
; GOLLUM_F -- Where a jump or a refusal goes on: GO SOUTHWEST, Go to GOLLUM_D.
GOLLUM_F:
  DEFB $04,$08            ; GO SOUTHWEST
  DEFB $0E                ; Go to GOLLUM_D
  DEFW GOLLUM_D
; GOLLUM_ON_ATTACK_WITH -- The reaction to ATTACK WITH: WEAR: valuable golden
; ring, RUN, Go to GOLLUM_A.
GOLLUM_ON_ATTACK_WITH:
  DEFB $02,$28,$10,$FF    ; WEAR: valuable golden ring
  DEFB $04,$24            ; RUN
  DEFB $0E                ; Go to GOLLUM_A
  DEFW GOLLUM_A

; Scripts: hideous troll, vicious troll
;
; What hideous troll, vicious troll does, turn by turn. CHARACTERS_ACT runs one
; step of a character's script each turn it can, and a step is an action the
; character tries as if it had typed it: RUN, TAKE, GIVE TO. A step that names
; nothing acts on whatever fits.
;
; First comes the script table: one entry per script, a key and the script's
; address. Key 0 is an ordinary script -- the ones a character wanders between,
; picked at random by a 'switch at random' step. Any other key is an action
; code, and that script is the character's reaction when that is done to it:
; attacked, given something, captured.
;
; Then the scripts, one step to a line. A step's first byte says what it is:
; its low four bits $00-$03 an action with objects (or, $01 and $03, a routine
; to call), $04 an action with none, $0E go to, $0F switch at random, $0C
; switch to a reaction. $10 added means an address follows, where the script
; goes on if the step is refused; $20 that the character's part is over once it
; works; $40 that an order from the player cannot interrupt it. So $14 is an
; action with no objects, with somewhere to go if it is refused. The Characters
; page has every script written out.
HIDEOUS_TROLL_SCRIPTS:
  DEFB $00                ; Key 0, an ordinary script: HIDEOUS_TROLL_A
  DEFW HIDEOUS_TROLL_A
  DEFB $0F                ; Key $0F, ATTACK WITH: its reaction, ON_ATTACK_WITH
  DEFW ON_ATTACK_WITH
  DEFB $FF                ; End of the table
; HIDEOUS_TROLL_B -- Where the script starts: TROLLS_TALK, then on as
; HIDEOUS_TROLL_A.
HIDEOUS_TROLL_B:
  DEFB $13                ; Call TROLLS_TALK
  DEFW TROLLS_TALK
  DEFB $00                ; Not used
  DEFW HIDEOUS_TROLL_B    ; If it is refused: HIDEOUS_TROLL_B
; HIDEOUS_TROLL_A -- An ordinary script: TROLLS_EAT, Pause: nothing this turn,
; TROLLS_EAT, Pause: nothing this turn, TROLLS_EAT, Pause: nothing this turn,
; TROLLS_EAT, TROLLS_TURN_TO_STONE, Go to HIDEOUS_TROLL_A.
HIDEOUS_TROLL_A:
  DEFB $03                ; Call TROLLS_EAT
  DEFW TROLLS_EAT
  DEFB $00                ; Not used
  DEFB $04,$FF            ; Pause: nothing this turn
  DEFB $03                ; Call TROLLS_EAT
  DEFW TROLLS_EAT
  DEFB $00                ; Not used
  DEFB $04,$FF            ; Pause: nothing this turn
  DEFB $03                ; Call TROLLS_EAT
  DEFW TROLLS_EAT
  DEFB $00                ; Not used
  DEFB $04,$FF            ; Pause: nothing this turn
  DEFB $03                ; Call TROLLS_EAT
  DEFW TROLLS_EAT
  DEFB $00                ; Not used
  DEFB $03                ; Call TROLLS_TURN_TO_STONE
  DEFW TROLLS_TURN_TO_STONE
  DEFB $00                ; Not used
  DEFB $0E                ; Go to HIDEOUS_TROLL_A
  DEFW HIDEOUS_TROLL_A

; Scripts several characters share
;
; What they do when attacked, captured or given something.
;
; ON_ATTACK_WITH -- The reaction to ATTACK WITH: ATTACK WITH, ATTACK WITH, RUN,
; Go to ON_ATTACK_WITH.
ON_ATTACK_WITH:
  DEFB $54,$0F            ; ATTACK WITH (an order cannot interrupt it)
  DEFW HIDEOUS_TROLL_C    ; If it is refused: HIDEOUS_TROLL_C
  DEFB $54,$0F            ; ATTACK WITH (an order cannot interrupt it)
  DEFW HIDEOUS_TROLL_D    ; If it is refused: HIDEOUS_TROLL_D
  DEFB $44,$24            ; RUN (an order cannot interrupt it)
  DEFB $0E                ; Go to ON_ATTACK_WITH
  DEFW ON_ATTACK_WITH
; HIDEOUS_TROLL_C -- Where a jump or a refusal goes on: FOLLOW, Go to
; ON_ATTACK_WITH.
HIDEOUS_TROLL_C:
  DEFB $54,$27            ; FOLLOW (an order cannot interrupt it)
  DEFW HIDEOUS_TROLL_D    ; If it is refused: HIDEOUS_TROLL_D
  DEFB $0E                ; Go to ON_ATTACK_WITH
  DEFW ON_ATTACK_WITH
; HIDEOUS_TROLL_D -- Where a jump or a refusal goes on: Back to its first
; script.
HIDEOUS_TROLL_D:
  DEFB $07                ; Back to its first script
; GANDALF_ON_CAPTURE -- The reaction to CAPTURE: GO THROUGH, RUN, Back to its
; first script.
GANDALF_ON_CAPTURE:
  DEFB $14,$1E            ; GO THROUGH
  DEFW HIDEOUS_TROLL_E    ; If it is refused: HIDEOUS_TROLL_E
  DEFB $04,$24            ; RUN
  DEFB $07                ; Back to its first script
; HIDEOUS_TROLL_E -- Where a jump or a refusal goes on: Pause: nothing this
; turn, Go to GANDALF_ON_CAPTURE.
HIDEOUS_TROLL_E:
  DEFB $04,$FF            ; Pause: nothing this turn
  DEFB $0E                ; Go to GANDALF_ON_CAPTURE
  DEFW GANDALF_ON_CAPTURE
; ON_GIVE_TO -- The reaction to GIVE TO: GIVEN_SOMETHING, Back to its first
; script.
ON_GIVE_TO:
  DEFB $03                ; Call GIVEN_SOMETHING
  DEFW GIVEN_SOMETHING
  DEFB $00                ; Not used
  DEFB $07                ; Back to its first script

; The timers END_OF_TURN counts down
;
; Ten 7-byte entries, ending at $FF: byte 0 is the timer's length in turns, and
; starting it is copying that into byte 1, the count -- WINE_DRUNK does exactly
; that for timer 7, and timer 9 restarts itself the same way. Bytes 2 and 3 are
; the routine to run when the count reaches zero. Byte 4 is how many turns
; before then to warn, and bytes 5 and 6 the routine to warn with. All of them
; are reached through JUMP_HL's JP (HL).
;
; This table and what follows it, $BF bytes in all, are copied aside by START
; and copied back on every new game; SAVE and LOAD take the same $BF bytes.
;
; Timer 0, 2 turns: the barrel reaches the long lake (BARREL_REACHES_LAKE);
; started by BARREL_THROWN
TIMERS:
  DEFB $02                ; Its length in turns
TIMER0_COUNT:
  DEFB $00                ; Its count: 0 when it is not running
  DEFW BARREL_REACHES_LAKE ; The routine when the count reaches zero
  DEFB $00                ; How many turns before then to warn
  DEFW $0000              ; The routine to warn with
; Timer 1, 2 turns: the broken web is mended (WEB_CHANGES); started by
; WEB_BROKEN
TIMER1:
  DEFB $02                ; Its length in turns
TIMER1_COUNT:
  DEFB $00                ; Its count: 0 when it is not running
  DEFW WEB_CHANGES        ; The routine when the count reaches zero
  DEFB $00                ; How many turns before then to warn
  DEFW $0000              ; The routine to warn with
; Timer 2, 5 turns: the web smothers anyone still in it (WEB_SMOTHERS)
TIMER2:
  DEFB $05                ; Its length in turns
TIMER2_COUNT:
  DEFB $00                ; Its count: 0 when it is not running
  DEFW WEB_SMOTHERS       ; The routine when the count reaches zero
  DEFB $00                ; How many turns before then to warn
  DEFW $0000              ; The routine to warn with
; Timer 3, 2 turns: the goblins' door shuts (GOBLINS_DOOR_SHUTS); started by
; GOBLINS_DOOR_OPENED
TIMER3:
  DEFB $02                ; Its length in turns
TIMER3_COUNT:
  DEFB $00                ; Its count: 0 when it is not running
  DEFW GOBLINS_DOOR_SHUTS ; The routine when the count reaches zero
  DEFB $00                ; How many turns before then to warn
  DEFW $0000              ; The routine to warn with
; Timer 4, 2 turns: the deep bog, warning every turn (SINKING_IN_BOG)
TIMER4:
  DEFB $02                ; Its length in turns
TIMER4_COUNT:
  DEFB $00                ; Its count: 0 when it is not running
  DEFW SINKING_IN_BOG     ; The routine when the count reaches zero
  DEFB $02                ; How many turns before then to warn
  DEFW SINKING_IN_BOG     ; The routine to warn with
; Timer 5, 4 turns: the magic door opens a turn before it closes
; (MAGIC_DOOR_OPENS, MAGIC_DOOR_CLOSES); started by MAGIC_DOOR_EXAMINED
TIMER5:
  DEFB $04                ; Its length in turns
TIMER5_COUNT:
  DEFB $00                ; Its count: 0 when it is not running
  DEFW MAGIC_DOOR_CLOSES  ; The routine when the count reaches zero
  DEFB $01                ; How many turns before then to warn
  DEFW MAGIC_DOOR_OPENS   ; The routine to warn with
; Timer 6: the ring slips off (RING_CHECK); started by WEAR_RING at 2 to 10
; turns, and run early by timer 5's warning
TIMER6:
  DEFB $00                ; Its length in turns
TIMER6_COUNT:
  DEFB $00                ; Its count: 0 when it is not running
  DEFW RING_CHECK         ; The routine when the count reaches zero
  DEFB $00                ; How many turns before then to warn
  DEFW $0000              ; The routine to warn with
; Timer 7, 5 turns: the wine wears off (WINE_WEARS_OFF)
TIMER7:
  DEFB $05                ; Its length in turns
TIMER7_COUNT:
  DEFB $00                ; Its count: 0 when it is not running
  DEFW WINE_WEARS_OFF     ; The routine when the count reaches zero
  DEFB $00                ; How many turns before then to warn
  DEFW $0000              ; The routine to warn with
; Timer 8, 4 turns: the eyes in the forest (EYES_WARNING, EYES_STING)
TIMER8:
  DEFB $04                ; Its length in turns
TIMER8_COUNT:
  DEFB $00                ; Its count: 0 when it is not running
  DEFW EYES_STING         ; The routine when the count reaches zero
  DEFB $03                ; How many turns before then to warn
  DEFW EYES_WARNING       ; The routine to warn with
; Timer 9, 5 turns: the hole in the mountain's side (SIDE_DOOR_APPEARS,
; SIDE_DOOR_VANISHES)
TIMER9:
  DEFB $05                ; Its length in turns
TIMER9_COUNT:
  DEFB $00                ; Its count: 0 when it is not running
  DEFW SIDE_DOOR_VANISHES ; The routine when the count reaches zero
  DEFB $01                ; How many turns before then to warn
  DEFW SIDE_DOOR_APPEARS  ; The routine to warn with
  DEFB $FF                ; End of the timers

; The characters' scripts: where each has got to
;
; Seventeen 7-byte slots, ending at $FF. Byte 0 is the character, or 0 for a
; slot not in use -- three are empty at the start, and a character whose part
; is over (see SCRIPT_DO) empties its own. Byte 1 is how many of its scripts
; SCRIPT_RANDOM may choose among. Bytes 2 and 3 are the instruction its script
; has got to; bytes 4 and 5 are its script table, a FIND_RECORD table whose
; entries keyed 0 are its ordinary scripts and whose others are its reactions
; (see REACT). Byte 6 is how many of the player's orders it will take at once
; (see DO_TALK): Thorin 6, Gandalf and Elrond 5, Gollum 3, the wood elf and the
; trolls 1, and the warg and the goblins 0, never.
;
; The scripts themselves are from NASTY_GOBLIN_SCRIPTS up to TIMERS, each table
; followed by its scripts, every step decoded and every address in them a label
; (generated by build_hobbit.py's script_blocks). An instruction's low four
; bits are its opcode: 0 to 3 as SCRIPT_DO, 4 as SCRIPT_BARE, $0C, $0E and $0F
; as CHARACTERS_ACT says, and anything else sends the character back to its
; first script. Bit 4 means a 2-byte fallback follows, bit 5 that the character
; leaves the story when the step succeeds, and bit 6 that an order cannot
; interrupt it.
CHARACTERS:
  DEFB $3E                ; Gandalf
  DEFB $07                ; How many of its scripts it chooses among at random
  DEFW GANDALF_F          ; Where its script has got to
  DEFW GANDALF_SCRIPTS    ; Its script table
  DEFB $05                ; How many orders it takes at once
THORIN_SLOT:
  DEFB $3F                ; Thorin
  DEFB $02                ; How many of its scripts it chooses among at random
  DEFW THORIN_A           ; Where its script has got to
  DEFW THORIN_SCRIPTS     ; Its script table
  DEFB $06                ; How many orders it takes at once
WOOD_ELF_SLOT:
  DEFB $40                ; Wood elf
  DEFB $02                ; How many of its scripts it chooses among at random
  DEFW WOOD_ELF_A         ; Where its script has got to
  DEFW WOOD_ELF_SCRIPTS   ; Its script table
  DEFB $01                ; How many orders it takes at once
VICIOUS_WARG_SLOT:
  DEFB $43                ; Vicious warg
  DEFB $00                ; How many of its scripts it chooses among at random
  DEFW VICIOUS_WARG_A     ; Where its script has got to
  DEFW VICIOUS_WARG_SCRIPTS ; Its script table
  DEFB $00                ; How many orders it takes at once
BUTLER_SLOT:
  DEFB $00                ; Empty at the start: butler's, once an arrival hook
                          ; writes it in
  DEFB $02                ; How many of its scripts it chooses among at random
  DEFW BUTLER_A           ; Where its script has got to
  DEFW BUTLER_SCRIPTS     ; Its script table
  DEFB $01                ; How many orders it takes at once
ELROND_SLOT:
  DEFB $41                ; Elrond
  DEFB $02                ; How many of its scripts it chooses among at random
  DEFW ELROND_B           ; Where its script has got to
  DEFW ELROND_SCRIPTS     ; Its script table
  DEFB $05                ; How many orders it takes at once
GOLLUM_SLOT:
  DEFB $44                ; Gollum
  DEFB $01                ; How many of its scripts it chooses among at random
  DEFW GOLLUM_A           ; Where its script has got to
  DEFW GOLLUM_SCRIPTS     ; Its script table
  DEFB $03                ; How many orders it takes at once
BARD_SLOT:
  DEFB $00                ; Empty at the start: bard's, once an arrival hook
                          ; writes it in
  DEFB $01                ; How many of its scripts it chooses among at random
  DEFW BARD_A             ; Where its script has got to
  DEFW BARD_SCRIPTS       ; Its script table
  DEFB $03                ; How many orders it takes at once
RED_GOLDEN_DRAGON_SLOT:
  DEFB $00                ; Empty at the start: red golden dragon's, once an
                          ; arrival hook writes it in
  DEFB $01                ; How many of its scripts it chooses among at random
  DEFW RED_GOLDEN_DRAGON_A ; Where its script has got to
  DEFW RED_GOLDEN_DRAGON_SCRIPTS ; Its script table
  DEFB $00                ; How many orders it takes at once
HIDEOUS_TROLL_SLOT:
  DEFB $47                ; Hideous troll
  DEFB $01                ; How many of its scripts it chooses among at random
  DEFW HIDEOUS_TROLL_B    ; Where its script has got to
  DEFW HIDEOUS_TROLL_SCRIPTS ; Its script table
  DEFB $01                ; How many orders it takes at once
VICIOUS_TROLL_SLOT:
  DEFB $48                ; Vicious troll
  DEFB $01                ; How many of its scripts it chooses among at random
  DEFW HIDEOUS_TROLL_B    ; Where its script has got to
  DEFW HIDEOUS_TROLL_SCRIPTS ; Its script table
  DEFB $01                ; How many orders it takes at once
NASTY_GOBLIN_SLOT:
  DEFB $3D                ; Nasty goblin
  DEFB $01                ; How many of its scripts it chooses among at random
  DEFW NASTY_GOBLIN_A     ; Where its script has got to
  DEFW NASTY_GOBLIN_SCRIPTS ; Its script table
  DEFB $00                ; How many orders it takes at once
HIDEOUS_GOBLIN_SLOT:
  DEFB $45                ; Hideous goblin
  DEFB $01                ; How many of its scripts it chooses among at random
  DEFW NASTY_GOBLIN_A     ; Where its script has got to
  DEFW NASTY_GOBLIN_SCRIPTS ; Its script table
  DEFB $00                ; How many orders it takes at once
VICIOUS_GOBLIN_SLOT:
  DEFB $4B                ; Vicious goblin
  DEFB $01                ; How many of its scripts it chooses among at random
  DEFW VICIOUS_GOBLIN_A   ; Where its script has got to
  DEFW VICIOUS_GOBLIN_SCRIPTS ; Its script table
  DEFB $00                ; How many orders it takes at once
HORRIBLE_GOBLIN_SLOT:
  DEFB $49                ; Horrible goblin
  DEFB $01                ; How many of its scripts it chooses among at random
  DEFW HORRIBLE_GOBLIN_A  ; Where its script has got to
  DEFW HORRIBLE_GOBLIN_SCRIPTS ; Its script table
  DEFB $00                ; How many orders it takes at once
MEAN_GOBLIN_SLOT:
  DEFB $4A                ; Mean goblin
  DEFB $01                ; How many of its scripts it chooses among at random
  DEFW HORRIBLE_GOBLIN_A  ; Where its script has got to
  DEFW HORRIBLE_GOBLIN_SCRIPTS ; Its script table
  DEFB $00                ; How many orders it takes at once
DISGUSTING_GOBLIN_SLOT:
  DEFB $4C                ; Disgusting goblin
  DEFB $01                ; How many of its scripts it chooses among at random
  DEFW HORRIBLE_GOBLIN_A  ; Where its script has got to
  DEFW HORRIBLE_GOBLIN_SCRIPTS ; Its script table
  DEFB $00                ; How many orders it takes at once
  DEFB $FF                ; End of the characters
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00

; Pictures: which locations have one, and where
;
; 22 records of a location number and the address of its picture stream, ending
; at a location of $FF. Searched by L9DBD, which walks it in order, so it does
; not need to be sorted and is not.
PICTURE_TABLE:
  DEFB $01                ; Location 1, tunnel like hall
  DEFW LOC1_TUNNEL_LIKE_HALL_PIC
  DEFB $31                ; Location 49, great river
  DEFW LOC49_GREAT_RIVER_PIC
  DEFB $06                ; Location 6, trolls path
  DEFW LOC6_TROLLS_PATH_PIC
  DEFB $0B                ; Location 11, narrow place
  DEFW LOC11_NARROW_PLACE_PIC
  DEFB $25                ; Location 37, dragons desolation
  DEFW LOC37_DRAGONS_DESOLATION_PIC
  DEFB $2B                ; Location 43, smooth straight passage
  DEFW LOC43_SMOOTH_STRAIGHT_PASSAGE_PIC
  DEFB $26                ; Location 38, dale valley
  DEFW LOC38_DALE_VALLEY_PIC
  DEFB $07                ; Location 7, trolls cave
  DEFW LOC7_TROLLS_CAVE_PIC
  DEFB $18                ; Location 24, forest gate
  DEFW LOC24_FOREST_GATE_PIC
  DEFB $23                ; Location 35, lake town
  DEFW LOC35_LAKE_TOWN_PIC
  DEFB $0D                ; Location 13, goblins dungeon
  DEFW LOC13_GOBLINS_DUNGEON_PIC
  DEFB $1F                ; Location 31, dark dungeon
  DEFW LOC31_DARK_DUNGEON_PIC
  DEFB $05                ; Location 5, trolls clearing
  DEFW LOC5_TROLLS_CLEARING_PIC
  DEFB $1C                ; Location 28, levelled elvish clearing
  DEFW LOC28_LEVELLED_ELVISH_CLEARING_PIC
  DEFB $04                ; Location 4, lonelands
  DEFW LOC4_LONELANDS_PIC
  DEFB $20                ; Location 32, elvenkings cellar
  DEFW LOC32_ELVENKINGS_CELLAR_PIC
  DEFB $10                ; Location 16, big goblins cavern
  DEFW LOC16_BIG_GOBLINS_CAVERN_PIC
  DEFB $19                ; Location 25, bewitched gloomy place
  DEFW LOC25_BEWITCHED_GLOOMY_PLACE_PIC
  DEFB $08                ; Location 8, running river
  DEFW LOC8_RUNNING_RIVER_PIC
  DEFB $29                ; Location 41, lower halls
  DEFW LOC41_LOWER_HALLS_PIC
  DEFB $1A                ; Location 26, spider threads place
  DEFW LOC26_SPIDER_THREADS_PLACE_PIC
  DEFB $27                ; Location 39, front gate
  DEFW LOC39_FRONT_GATE_PIC
  DEFB $FF                ; End of the table

; Picture for location 1: tunnel like hall
;
; A border colour and a starting attribute, then 68 moves, 162 lines, 6 fills,
; 1 paint, ending at $00.
LOC1_TUNNEL_LIKE_HALL_PIC:
  DEFB $07                ; Border: white
  DEFB $38                ; The canvas starts white paper, black ink
  DEFB $08,$9E,$46        ; MOVE to 158, 70
  DEFB $89,$44            ; LINE of 5 pixels up, stepping right every 6
  DEFB $81,$C4            ; LINE of 5 pixels up, stepping right every 4
  DEFB $81,$44            ; LINE of 5 pixels up, stepping right every 2
  DEFB $81,$04            ; LINE of 5 pixels diagonally up and right
  DEFB $80,$44            ; LINE of 5 pixels right, stepping up every 2
  DEFB $80,$C4            ; LINE of 5 pixels right, stepping up every 4
  DEFB $88,$44            ; LINE of 5 pixels right, stepping up every 6
  DEFB $08,$C6,$46        ; MOVE to 198, 70
  DEFB $89,$44            ; LINE of 5 pixels up, stepping right every 6
  DEFB $85,$C4            ; LINE of 5 pixels up, stepping left every 4
  DEFB $85,$44            ; LINE of 5 pixels up, stepping left every 2
  DEFB $84,$04            ; LINE of 5 pixels diagonally left and up
  DEFB $84,$44            ; LINE of 5 pixels left, stepping up every 2
  DEFB $8C,$04            ; LINE of 5 pixels left, stepping up every 5
  DEFB $08,$9F,$45        ; MOVE to 159, 69
  DEFB $83,$C4            ; LINE of 5 pixels down, stepping right every 4
  DEFB $83,$44            ; LINE of 5 pixels down, stepping right every 2
  DEFB $83,$04            ; LINE of 5 pixels diagonally down and right
  DEFB $82,$44            ; LINE of 5 pixels right, stepping down every 2
  DEFB $82,$82            ; LINE of 3 pixels right, stepping down every 3
  DEFB $8A,$04            ; LINE of 5 pixels right, stepping down every 5
  DEFB $08,$C5,$45        ; MOVE to 197, 69
  DEFB $87,$C4            ; LINE of 5 pixels down, stepping left every 4
  DEFB $87,$44            ; LINE of 5 pixels down, stepping left every 2
  DEFB $87,$04            ; LINE of 5 pixels diagonally down and left
  DEFB $86,$44            ; LINE of 5 pixels left, stepping down every 2
  DEFB $86,$C4            ; LINE of 5 pixels left, stepping down every 4
  DEFB $08,$91,$4E        ; MOVE to 145, 78
  DEFB $D6,$27            ; LINE of 40 pixels left, stepping down every 41
  DEFB $8C,$E7            ; LINE of 40 pixels left, stepping up every 8
  DEFB $8C,$E7            ; LINE of 40 pixels left, stepping up every 8
  DEFB $8C,$E7            ; LINE of 40 pixels left, stepping up every 8
  DEFB $08,$91,$37        ; MOVE to 145, 55
  DEFB $D4,$27            ; LINE of 40 pixels left, stepping up every 41
  DEFB $8E,$E7            ; LINE of 40 pixels left, stepping down every 8
  DEFB $8E,$E7            ; LINE of 40 pixels left, stepping down every 8
  DEFB $8E,$E7            ; LINE of 40 pixels left, stepping down every 8
  DEFB $08,$91,$59        ; MOVE to 145, 89
  DEFB $DC,$AE            ; LINE of 47 pixels left, stepping up every 47
  DEFB $8C,$27            ; LINE of 40 pixels left, stepping up every 5
  DEFB $8C,$27            ; LINE of 40 pixels left, stepping up every 5
  DEFB $8C,$27            ; LINE of 40 pixels left, stepping up every 5
  DEFB $08,$6A,$18        ; MOVE to 106, 24
  DEFB $9E,$CE            ; LINE of 15 pixels left, stepping down every 16
  DEFB $85,$4D            ; LINE of 14 pixels up, stepping left every 2
  DEFB $98,$8D            ; LINE of 14 pixels right, stepping up every 15
  DEFB $98,$CE            ; LINE of 15 pixels right, stepping up every 16
  DEFB $87,$4E            ; LINE of 15 pixels down, stepping left every 2
  DEFB $08,$55,$26        ; MOVE to 85, 38
  DEFB $81,$42            ; LINE of 3 pixels up, stepping right every 2
  DEFB $81,$02            ; LINE of 3 pixels diagonally up and right
  DEFB $80,$42            ; LINE of 3 pixels right, stepping up every 2
  DEFB $80,$42            ; LINE of 3 pixels right, stepping up every 2
  DEFB $80,$82            ; LINE of 3 pixels right, stepping up every 3
  DEFB $82,$82            ; LINE of 3 pixels right, stepping down every 3
  DEFB $82,$82            ; LINE of 3 pixels right, stepping down every 3
  DEFB $82,$82            ; LINE of 3 pixels right, stepping down every 3
  DEFB $82,$42            ; LINE of 3 pixels right, stepping down every 2
  DEFB $82,$42            ; LINE of 3 pixels right, stepping down every 2
  DEFB $83,$42            ; LINE of 3 pixels down, stepping right every 2
  DEFB $80,$42            ; LINE of 3 pixels right, stepping up every 2
  DEFB $81,$04            ; LINE of 5 pixels diagonally up and right
  DEFB $08,$6C,$18        ; MOVE to 108, 24
  DEFB $80,$09            ; LINE of 10 pixels diagonally right and up
  DEFB $81,$8A            ; LINE of 11 pixels up, stepping right every 3
  DEFB $85,$02            ; LINE of 3 pixels diagonally up and left
  DEFB $84,$42            ; LINE of 3 pixels left, stepping up every 2
  DEFB $84,$42            ; LINE of 3 pixels left, stepping up every 2
  DEFB $84,$82            ; LINE of 3 pixels left, stepping up every 3
  DEFB $86,$82            ; LINE of 3 pixels left, stepping down every 3
  DEFB $86,$82            ; LINE of 3 pixels left, stepping down every 3
  DEFB $86,$82            ; LINE of 3 pixels left, stepping down every 3
  DEFB $86,$82            ; LINE of 3 pixels left, stepping down every 3
  DEFB $86,$82            ; LINE of 3 pixels left, stepping down every 3
  DEFB $08,$5C,$18        ; MOVE to 92, 24
  DEFB $A9,$55            ; LINE of 22 pixels up, stepping right every 22
  DEFB $08,$63,$18        ; MOVE to 99, 24
  DEFB $A9,$D7            ; LINE of 24 pixels up, stepping right every 24
  DEFB $08,$6B,$19        ; MOVE to 107, 25
  DEFB $A9,$14            ; LINE of 21 pixels up, stepping right every 21
  DEFB $08,$55,$25        ; MOVE to 85, 37
  DEFB $BA,$1C            ; LINE of 29 pixels right, stepping down every 29
  DEFB $08,$6C,$2C        ; MOVE to 108, 44
  DEFB $80,$49            ; LINE of 10 pixels right, stepping up every 2
  DEFB $08,$66,$2F        ; MOVE to 102, 47
  DEFB $80,$48            ; LINE of 9 pixels right, stepping up every 2
  DEFB $08,$93,$2C        ; MOVE to 147, 44
  DEFB $B6,$99            ; LINE of 26 pixels left, stepping down every 27
  DEFB $08,$55,$28        ; MOVE to 85, 40
  DEFB $8E,$19            ; LINE of 26 pixels left, stepping down every 5
  DEFB $8E,$19            ; LINE of 26 pixels left, stepping down every 5
  DEFB $8E,$19            ; LINE of 26 pixels left, stepping down every 5
  DEFB $8E,$19            ; LINE of 26 pixels left, stepping down every 5
  DEFB $08,$93,$37        ; MOVE to 147, 55
  DEFB $C1,$A2            ; LINE of 35 pixels up, stepping right every 35
  DEFB $81,$45            ; LINE of 6 pixels up, stepping right every 2
  DEFB $80,$05            ; LINE of 6 pixels diagonally right and up
  DEFB $80,$45            ; LINE of 6 pixels right, stepping up every 2
  DEFB $80,$85            ; LINE of 6 pixels right, stepping up every 3
  DEFB $80,$C5            ; LINE of 6 pixels right, stepping up every 4
  DEFB $88,$85            ; LINE of 6 pixels right, stepping up every 7
  DEFB $08,$D0,$59        ; MOVE to 208, 89
  DEFB $85,$45            ; LINE of 6 pixels up, stepping left every 2
  DEFB $85,$05            ; LINE of 6 pixels diagonally up and left
  DEFB $84,$45            ; LINE of 6 pixels left, stepping up every 2
  DEFB $84,$85            ; LINE of 6 pixels left, stepping up every 3
  DEFB $84,$86            ; LINE of 7 pixels left, stepping up every 3
  DEFB $08,$D0,$58        ; MOVE to 208, 88
  DEFB $C3,$A1            ; LINE of 34 pixels down, stepping right every 35
  DEFB $86,$06            ; LINE of 7 pixels diagonally left and down
  DEFB $D4,$AA            ; LINE of 43 pixels left, stepping up every 43
  DEFB $85,$4C            ; LINE of 13 pixels up, stepping left every 2
  DEFB $B9,$A5            ; LINE of 38 pixels up, stepping right every 31
  DEFB $08,$98,$3A        ; MOVE to 152, 58
  DEFB $86,$45            ; LINE of 6 pixels left, stepping down every 2
  DEFB $08,$9D,$31        ; MOVE to 157, 49
  DEFB $86,$4A            ; LINE of 11 pixels left, stepping down every 2
  DEFB $08,$60,$36        ; MOVE to 96, 54
  DEFB $83,$02            ; LINE of 3 pixels diagonally down and right
  DEFB $08,$63,$34        ; MOVE to 99, 52
  DEFB $E2,$30            ; LINE of 49 pixels right, stepping down every 49
  DEFB $08,$94,$34        ; MOVE to 148, 52
  DEFB $85,$43            ; LINE of 4 pixels up, stepping left every 2
  DEFB $08,$94,$35        ; MOVE to 148, 53
  DEFB $80,$46            ; LINE of 7 pixels right, stepping up every 2
  DEFB $08,$94,$2D        ; MOVE to 148, 45
  DEFB $89,$C7            ; LINE of 8 pixels up, stepping right every 8
  DEFB $08,$CD,$33        ; MOVE to 205, 51
  DEFB $C1,$60            ; LINE of 33 pixels up, stepping right every 34
  DEFB $8D,$4D            ; LINE of 14 pixels up, stepping left every 6
  DEFB $08,$9B,$2F        ; MOVE to 155, 47
  DEFB $90,$07            ; LINE of 8 pixels right, stepping up every 9
  DEFB $08,$9D,$30        ; MOVE to 157, 48
  DEFB $81,$00            ; LINE of 1 pixel diagonally up and right
  DEFB $08,$9C,$30        ; MOVE to 156, 48
  DEFB $81,$00            ; LINE of 1 pixel diagonally up and right
  DEFB $08,$62,$34        ; MOVE to 98, 52
  DEFB $8E,$7E            ; LINE of 63 pixels left, stepping down every 6
  DEFB $8E,$7E            ; LINE of 63 pixels left, stepping down every 6
  DEFB $08,$93,$4E        ; MOVE to 147, 78
  DEFB $80,$C5            ; LINE of 6 pixels right, stepping up every 4
  DEFB $08,$93,$59        ; MOVE to 147, 89
  DEFB $82,$C4            ; LINE of 5 pixels right, stepping down every 4
  DEFB $08,$A7,$37        ; MOVE to 167, 55
  DEFB $C1,$E3            ; LINE of 36 pixels up, stepping right every 36
  DEFB $08,$B0,$34        ; MOVE to 176, 52
  DEFB $D5,$28            ; LINE of 41 pixels up, stepping left every 41
  DEFB $08,$BA,$35        ; MOVE to 186, 53
  DEFB $CD,$E7            ; LINE of 40 pixels up, stepping left every 40
  DEFB $08,$C3,$3D        ; MOVE to 195, 61
  DEFB $AD,$D7            ; LINE of 24 pixels up, stepping left every 24
  DEFB $08,$C2,$53        ; MOVE to 194, 83
  DEFB $86,$87            ; LINE of 8 pixels left, stepping down every 3
  DEFB $08,$BA,$4F        ; MOVE to 186, 79
  DEFB $82,$CC            ; LINE of 13 pixels right, stepping down every 4
  DEFB $08,$C3,$3F        ; MOVE to 195, 63
  DEFB $84,$89            ; LINE of 10 pixels left, stepping up every 3
  DEFB $08,$BA,$44        ; MOVE to 186, 68
  DEFB $80,$CC            ; LINE of 13 pixels right, stepping up every 4
  DEFB $08,$A2,$49        ; MOVE to 162, 73
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$A3,$46        ; MOVE to 163, 70
  DEFB $89,$03            ; LINE of 4 pixels up, stepping right every 5
  DEFB $08,$A1,$47        ; MOVE to 161, 71
  DEFB $81,$81            ; LINE of 2 pixels up, stepping right every 3
  DEFB $08,$CB,$2D        ; MOVE to 203, 45
  DEFB $92,$89            ; LINE of 10 pixels right, stepping down every 11
  DEFB $82,$6A            ; LINE of 43 pixels right, stepping down every 2
  DEFB $08,$D7,$34        ; MOVE to 215, 52
  DEFB $82,$AA            ; LINE of 43 pixels right, stepping down every 3
  DEFB $08,$DB,$37        ; MOVE to 219, 55
  DEFB $8A,$2A            ; LINE of 43 pixels right, stepping down every 5
  DEFB $08,$D9,$37        ; MOVE to 217, 55
  DEFB $86,$02            ; LINE of 3 pixels diagonally left and down
  DEFB $08,$D7,$34        ; MOVE to 215, 52
  DEFB $8B,$C7            ; LINE of 8 pixels down, stepping right every 8
  DEFB $08,$D8,$37        ; MOVE to 216, 55
  DEFB $96,$07            ; LINE of 8 pixels left, stepping down every 9
  DEFB $08,$D6,$34        ; MOVE to 214, 52
  DEFB $96,$09            ; LINE of 10 pixels left, stepping down every 9
  DEFB $08,$CE,$33        ; MOVE to 206, 51
  DEFB $8F,$C6            ; LINE of 7 pixels down, stepping left every 8
  DEFB $08,$CA,$30        ; MOVE to 202, 48
  DEFB $83,$03            ; LINE of 4 pixels diagonally down and right
  DEFB $08,$62,$4D        ; MOVE to 98, 77
  DEFB $AB,$D7            ; LINE of 24 pixels down, stepping right every 24
  DEFB $08,$62,$4D        ; MOVE to 98, 77
  DEFB $89,$0C            ; LINE of 13 pixels up, stepping right every 5
  DEFB $08,$D2,$4D        ; MOVE to 210, 77
  DEFB $88,$86            ; LINE of 7 pixels right, stepping up every 7
  DEFB $88,$2C            ; LINE of 45 pixels right, stepping up every 5
  DEFB $08,$D1,$59        ; MOVE to 209, 89
  DEFB $8A,$45            ; LINE of 6 pixels right, stepping down every 6
  DEFB $08,$D7,$5A        ; MOVE to 215, 90
  DEFB $80,$A9            ; LINE of 42 pixels right, stepping up every 3
  DEFB $08,$D8,$4E        ; MOVE to 216, 78
  DEFB $AB,$D7            ; LINE of 24 pixels down, stepping right every 24
  DEFB $08,$D8,$4E        ; MOVE to 216, 78
  DEFB $8D,$0C            ; LINE of 13 pixels up, stepping left every 5
  DEFB $08,$D6,$59        ; MOVE to 214, 89
  DEFB $85,$C6            ; LINE of 7 pixels up, stepping left every 4
  DEFB $85,$46            ; LINE of 7 pixels up, stepping left every 2
  DEFB $85,$06            ; LINE of 7 pixels diagonally up and left
  DEFB $84,$46            ; LINE of 7 pixels left, stepping up every 2
  DEFB $84,$86            ; LINE of 7 pixels left, stepping up every 3
  DEFB $84,$C6            ; LINE of 7 pixels left, stepping up every 4
  DEFB $8C,$46            ; LINE of 7 pixels left, stepping up every 6
  DEFB $8C,$86            ; LINE of 7 pixels left, stepping up every 7
  DEFB $8C,$C6            ; LINE of 7 pixels left, stepping up every 8
  DEFB $8C,$C6            ; LINE of 7 pixels left, stepping up every 8
  DEFB $8C,$C6            ; LINE of 7 pixels left, stepping up every 8
  DEFB $84,$C2            ; LINE of 3 pixels left, stepping up every 4
  DEFB $8C,$44            ; LINE of 5 pixels left, stepping up every 6
  DEFB $08,$63,$59        ; MOVE to 99, 89
  DEFB $81,$86            ; LINE of 7 pixels up, stepping right every 3
  DEFB $81,$46            ; LINE of 7 pixels up, stepping right every 2
  DEFB $81,$06            ; LINE of 7 pixels diagonally up and right
  DEFB $80,$46            ; LINE of 7 pixels right, stepping up every 2
  DEFB $80,$86            ; LINE of 7 pixels right, stepping up every 3
  DEFB $80,$C6            ; LINE of 7 pixels right, stepping up every 4
  DEFB $80,$C7            ; LINE of 8 pixels right, stepping up every 4
  DEFB $08,$CF,$37        ; MOVE to 207, 55
  DEFB $84,$02            ; LINE of 3 pixels diagonally left and up
  DEFB $08,$D1,$4D        ; MOVE to 209, 77
  DEFB $84,$43            ; LINE of 4 pixels left, stepping up every 2
  DEFB $08,$D0,$59        ; MOVE to 208, 89
  DEFB $86,$82            ; LINE of 3 pixels left, stepping down every 3
  DEFB $08,$60,$34        ; MOVE to 96, 52
  DEFB $8F,$04            ; LINE of 5 pixels down, stepping left every 5
  DEFB $40,$BF,$51        ; FILL with black from 191, 81
  DEFB $40,$BF,$43        ; FILL with black from 191, 67
  DEFB $40,$C4,$50        ; FILL with black from 196, 80
  DEFB $40,$C4,$44        ; FILL with black from 196, 68
  DEFB $40,$9C,$44        ; FILL with black from 156, 68
  DEFB $24,$58,$F3,$08,$11,$12,$0F,$0C ; PAINT green ink from row 7, column 19,
  DEFB $09,$0A,$07,$04,$01,$06,$FF     ; along a path of 11 steps
  DEFB $43,$7F,$18        ; FILL with magenta from 127, 24
  DEFB $00                ; End of the picture

; Picture for location 49: great river
;
; A border colour and a starting attribute, then 25 moves, 104 lines, 6 fills,
; 1 paint, ending at $00.
LOC49_GREAT_RIVER_PIC:
  DEFB $04                ; Border: green
  DEFB $20                ; The canvas starts green paper, black ink
  DEFB $08,$A4,$00        ; MOVE to 164, 0
  DEFB $85,$86            ; LINE of 7 pixels up, stepping left every 3
  DEFB $8D,$C6            ; LINE of 7 pixels up, stepping left every 8
  DEFB $81,$89            ; LINE of 10 pixels up, stepping right every 3
  DEFB $89,$04            ; LINE of 5 pixels up, stepping right every 5
  DEFB $85,$47            ; LINE of 8 pixels up, stepping left every 2
  DEFB $84,$8F            ; LINE of 16 pixels left, stepping up every 3
  DEFB $94,$48            ; LINE of 9 pixels left, stepping up every 10
  DEFB $8E,$3E            ; LINE of 63 pixels left, stepping down every 5
  DEFB $96,$CB            ; LINE of 12 pixels left, stepping down every 12
  DEFB $8C,$FE            ; LINE of 63 pixels left, stepping up every 8
  DEFB $08,$00,$4F        ; MOVE to 0, 79
  DEFB $80,$CD            ; LINE of 14 pixels right, stepping up every 4
  DEFB $90,$23            ; LINE of 36 pixels right, stepping up every 9
  DEFB $92,$8F            ; LINE of 16 pixels right, stepping down every 11
  DEFB $80,$89            ; LINE of 10 pixels right, stepping up every 3
  DEFB $81,$C4            ; LINE of 5 pixels up, stepping right every 4
  DEFB $84,$8B            ; LINE of 12 pixels left, stepping up every 3
  DEFB $8C,$4B            ; LINE of 12 pixels left, stepping up every 6
  DEFB $8C,$57            ; LINE of 24 pixels left, stepping up every 6
  DEFB $80,$02            ; LINE of 3 pixels diagonally right and up
  DEFB $88,$66            ; LINE of 39 pixels right, stepping up every 6
  DEFB $92,$E6            ; LINE of 39 pixels right, stepping down every 12
  DEFB $8A,$66            ; LINE of 39 pixels right, stepping down every 6
  DEFB $8A,$5F            ; LINE of 32 pixels right, stepping down every 6
  DEFB $88,$97            ; LINE of 24 pixels right, stepping up every 7
  DEFB $81,$C3            ; LINE of 4 pixels up, stepping right every 4
  DEFB $8C,$69            ; LINE of 42 pixels left, stepping up every 6
  DEFB $94,$E9            ; LINE of 42 pixels left, stepping up every 12
  DEFB $81,$42            ; LINE of 3 pixels up, stepping right every 2
  DEFB $88,$2D            ; LINE of 46 pixels right, stepping up every 5
  DEFB $08,$E9,$00        ; MOVE to 233, 0
  DEFB $84,$53            ; LINE of 20 pixels left, stepping up every 2
  DEFB $85,$88            ; LINE of 9 pixels up, stepping left every 3
  DEFB $BD,$5E            ; LINE of 31 pixels up, stepping left every 30
  DEFB $84,$54            ; LINE of 21 pixels left, stepping up every 2
  DEFB $9E,$14            ; LINE of 21 pixels left, stepping down every 13
  DEFB $8E,$29            ; LINE of 42 pixels left, stepping down every 5
  DEFB $8E,$56            ; LINE of 23 pixels left, stepping down every 6
  DEFB $8C,$D6            ; LINE of 23 pixels left, stepping up every 8
  DEFB $8C,$0D            ; LINE of 14 pixels left, stepping up every 5
  DEFB $8E,$4D            ; LINE of 14 pixels left, stepping down every 6
  DEFB $84,$8D            ; LINE of 14 pixels left, stepping up every 3
  DEFB $81,$45            ; LINE of 6 pixels up, stepping right every 2
  DEFB $88,$15            ; LINE of 22 pixels right, stepping up every 5
  DEFB $88,$E6            ; LINE of 39 pixels right, stepping up every 8
  DEFB $88,$26            ; LINE of 39 pixels right, stepping up every 5
  DEFB $81,$46            ; LINE of 7 pixels up, stepping right every 2
  DEFB $85,$86            ; LINE of 7 pixels up, stepping left every 3
  DEFB $8C,$78            ; LINE of 57 pixels left, stepping up every 6
  DEFB $80,$48            ; LINE of 9 pixels right, stepping up every 2
  DEFB $88,$48            ; LINE of 9 pixels right, stepping up every 6
  DEFB $8A,$88            ; LINE of 9 pixels right, stepping down every 7
  DEFB $8A,$A5            ; LINE of 38 pixels right, stepping down every 7
  DEFB $8A,$25            ; LINE of 38 pixels right, stepping down every 5
  DEFB $90,$25            ; LINE of 38 pixels right, stepping up every 9
  DEFB $81,$8F            ; LINE of 16 pixels up, stepping right every 3
  DEFB $8C,$51            ; LINE of 18 pixels left, stepping up every 6
  DEFB $94,$A7            ; LINE of 40 pixels left, stepping up every 11
  DEFB $84,$46            ; LINE of 7 pixels left, stepping up every 2
  DEFB $89,$46            ; LINE of 7 pixels up, stepping right every 6
  DEFB $08,$DF,$5D        ; MOVE to 223, 93
  DEFB $80,$4D            ; LINE of 14 pixels right, stepping up every 2
  DEFB $88,$12            ; LINE of 19 pixels right, stepping up every 5
  DEFB $08,$8C,$4A        ; MOVE to 140, 74
  DEFB $88,$D2            ; LINE of 19 pixels right, stepping up every 8
  DEFB $80,$51            ; LINE of 18 pixels right, stepping up every 2
  DEFB $80,$D1            ; LINE of 18 pixels right, stepping up every 4
  DEFB $08,$B1,$55        ; MOVE to 177, 85
  DEFB $83,$44            ; LINE of 5 pixels down, stepping right every 2
  DEFB $82,$56            ; LINE of 23 pixels right, stepping down every 2
  DEFB $8A,$96            ; LINE of 23 pixels right, stepping down every 7
  DEFB $9A,$5E            ; LINE of 31 pixels right, stepping down every 14
  DEFB $08,$54,$7F        ; MOVE to 84, 127
  DEFB $82,$A5            ; LINE of 38 pixels right, stepping down every 3
  DEFB $08,$17,$2E        ; MOVE to 23, 46
  DEFB $8C,$50            ; LINE of 17 pixels left, stepping up every 6
  DEFB $85,$86            ; LINE of 7 pixels up, stepping left every 3
  DEFB $82,$D4            ; LINE of 21 pixels right, stepping down every 4
  DEFB $87,$C4            ; LINE of 5 pixels down, stepping left every 4
  DEFB $08,$0E,$36        ; MOVE to 14, 54
  DEFB $95,$8A            ; LINE of 11 pixels up, stepping left every 11
  DEFB $08,$0F,$35        ; MOVE to 15, 53
  DEFB $95,$8A            ; LINE of 11 pixels up, stepping left every 11
  DEFB $08,$13,$34        ; MOVE to 19, 52
  DEFB $95,$08            ; LINE of 9 pixels up, stepping left every 9
  DEFB $08,$14,$33        ; MOVE to 20, 51
  DEFB $95,$09            ; LINE of 10 pixels up, stepping left every 9
  DEFB $40,$14,$31        ; FILL with black from 20, 49
  DEFB $25,$59,$40,$08,$01,$0A,$01,$08 ; PAINT cyan ink from row 10, column 0,
  DEFB $01,$0E,$FF                     ; along a path of 7 steps
  DEFB $08,$00,$48        ; MOVE to 0, 72
  DEFB $C2,$1F            ; LINE of 32 pixels right, stepping down every 33
  DEFB $C7,$20            ; LINE of 33 pixels down, stepping left every 33
  DEFB $C6,$21            ; LINE of 34 pixels left, stepping down every 33
  DEFB $45,$48,$28        ; FILL with cyan from 72, 40
  DEFB $08,$41,$71        ; MOVE to 65, 113
  DEFB $84,$D3            ; LINE of 20 pixels left, stepping up every 4
  DEFB $94,$53            ; LINE of 20 pixels left, stepping up every 10
  DEFB $86,$D3            ; LINE of 20 pixels left, stepping down every 4
  DEFB $86,$93            ; LINE of 20 pixels left, stepping down every 3
  DEFB $08,$E2,$1C        ; MOVE to 226, 28
  DEFB $91,$CB            ; LINE of 12 pixels up, stepping right every 12
  DEFB $81,$44            ; LINE of 5 pixels up, stepping right every 2
  DEFB $83,$48            ; LINE of 9 pixels down, stepping right every 2
  DEFB $97,$8A            ; LINE of 11 pixels down, stepping left every 11
  DEFB $08,$E9,$1A        ; MOVE to 233, 26
  DEFB $84,$87            ; LINE of 8 pixels left, stepping up every 3
  DEFB $08,$EA,$24        ; MOVE to 234, 36
  DEFB $80,$CC            ; LINE of 13 pixels right, stepping up every 4
  DEFB $85,$48            ; LINE of 9 pixels up, stepping left every 2
  DEFB $86,$CD            ; LINE of 14 pixels left, stepping down every 4
  DEFB $08,$E9,$1A        ; MOVE to 233, 26
  DEFB $80,$CD            ; LINE of 14 pixels right, stepping up every 4
  DEFB $91,$49            ; LINE of 10 pixels up, stepping right every 10
  DEFB $42,$EF,$28        ; FILL with red from 239, 40
  DEFB $08,$F0,$30        ; MOVE to 240, 48
  DEFB $89,$0D            ; LINE of 14 pixels up, stepping right every 5
  DEFB $08,$F3,$3E        ; MOVE to 243, 62
  DEFB $8B,$17            ; LINE of 24 pixels down, stepping right every 5
  DEFB $42,$F2,$34        ; FILL with red from 242, 52
  DEFB $42,$F2,$20        ; FILL with red from 242, 32
  DEFB $08,$ED,$10        ; MOVE to 237, 16
  DEFB $8F,$C7            ; LINE of 8 pixels down, stepping left every 8
  DEFB $08,$EE,$08        ; MOVE to 238, 8
  DEFB $82,$8A            ; LINE of 11 pixels right, stepping down every 3
  DEFB $89,$C7            ; LINE of 8 pixels up, stepping right every 8
  DEFB $08,$F9,$0D        ; MOVE to 249, 13
  DEFB $84,$8B            ; LINE of 12 pixels left, stepping up every 3
  DEFB $80,$03            ; LINE of 4 pixels diagonally right and up
  DEFB $82,$8A            ; LINE of 11 pixels right, stepping down every 3
  DEFB $87,$44            ; LINE of 5 pixels down, stepping left every 2
  DEFB $08,$FD,$11        ; MOVE to 253, 17
  DEFB $82,$04            ; LINE of 5 pixels diagonally right and down
  DEFB $08,$FA,$05        ; MOVE to 250, 5
  DEFB $80,$46            ; LINE of 7 pixels right, stepping up every 2
  DEFB $42,$F6,$11        ; FILL with red from 246, 17
  DEFB $00                ; End of the picture

; Picture for location 6: trolls path
;
; A border colour and a starting attribute, then 46 moves, 244 lines, 13 fills,
; ending at $00.
LOC6_TROLLS_PATH_PIC:
  DEFB $00                ; Border: black
  DEFB $20                ; The canvas starts green paper, black ink
  DEFB $08,$2F,$19        ; MOVE to 47, 25
  DEFB $81,$64            ; LINE of 37 pixels up, stepping right every 2
  DEFB $88,$86            ; LINE of 7 pixels right, stepping up every 7
  DEFB $83,$C6            ; LINE of 7 pixels down, stepping right every 4
  DEFB $82,$D3            ; LINE of 20 pixels right, stepping down every 4
  DEFB $83,$07            ; LINE of 8 pixels diagonally down and right
  DEFB $81,$C4            ; LINE of 5 pixels up, stepping right every 4
  DEFB $85,$48            ; LINE of 9 pixels up, stepping left every 2
  DEFB $08,$62,$38        ; MOVE to 98, 56
  DEFB $84,$08            ; LINE of 9 pixels diagonally left and up
  DEFB $84,$88            ; LINE of 9 pixels left, stepping up every 3
  DEFB $90,$CB            ; LINE of 12 pixels right, stepping up every 12
  DEFB $85,$07            ; LINE of 8 pixels diagonally up and left
  DEFB $86,$47            ; LINE of 8 pixels left, stepping down every 2
  DEFB $84,$C5            ; LINE of 6 pixels left, stepping up every 4
  DEFB $81,$5E            ; LINE of 31 pixels up, stepping right every 2
  DEFB $98,$54            ; LINE of 21 pixels right, stepping up every 14
  DEFB $80,$91            ; LINE of 18 pixels right, stepping up every 3
  DEFB $83,$46            ; LINE of 7 pixels down, stepping right every 2
  DEFB $81,$CA            ; LINE of 11 pixels up, stepping right every 4
  DEFB $80,$D6            ; LINE of 23 pixels right, stepping up every 4
  DEFB $82,$06            ; LINE of 7 pixels diagonally right and down
  DEFB $8C,$45            ; LINE of 6 pixels left, stepping up every 6
  DEFB $86,$4A            ; LINE of 11 pixels left, stepping down every 2
  DEFB $87,$8A            ; LINE of 11 pixels down, stepping left every 3
  DEFB $80,$49            ; LINE of 10 pixels right, stepping up every 2
  DEFB $87,$4C            ; LINE of 13 pixels down, stepping left every 2
  DEFB $80,$D4            ; LINE of 21 pixels right, stepping up every 4
  DEFB $80,$82            ; LINE of 3 pixels right, stepping up every 3
  DEFB $87,$86            ; LINE of 7 pixels down, stepping left every 3
  DEFB $82,$02            ; LINE of 3 pixels diagonally right and down
  DEFB $81,$45            ; LINE of 6 pixels up, stepping right every 2
  DEFB $93,$CA            ; LINE of 11 pixels down, stepping right every 12
  DEFB $86,$4A            ; LINE of 11 pixels left, stepping down every 2
  DEFB $8A,$8A            ; LINE of 11 pixels right, stepping down every 7
  DEFB $93,$CA            ; LINE of 11 pixels down, stepping right every 12
  DEFB $86,$8A            ; LINE of 11 pixels left, stepping down every 3
  DEFB $83,$C4            ; LINE of 5 pixels down, stepping right every 4
  DEFB $88,$09            ; LINE of 10 pixels right, stepping up every 5
  DEFB $9F,$70            ; LINE of 49 pixels down, stepping left every 14
  DEFB $85,$4D            ; LINE of 14 pixels up, stepping left every 2
  DEFB $87,$48            ; LINE of 9 pixels down, stepping left every 2
  DEFB $8F,$0B            ; LINE of 12 pixels down, stepping left every 5
  DEFB $94,$A1            ; LINE of 34 pixels left, stepping up every 11
  DEFB $81,$C6            ; LINE of 7 pixels up, stepping right every 4
  DEFB $89,$45            ; LINE of 6 pixels up, stepping right every 6
  DEFB $81,$85            ; LINE of 6 pixels up, stepping right every 3
  DEFB $86,$09            ; LINE of 10 pixels diagonally left and down
  DEFB $9D,$0C            ; LINE of 13 pixels up, stepping left every 13
  DEFB $87,$4C            ; LINE of 13 pixels down, stepping left every 2
  DEFB $8B,$08            ; LINE of 9 pixels down, stepping right every 5
  DEFB $84,$D3            ; LINE of 20 pixels left, stepping up every 4
  DEFB $85,$07            ; LINE of 8 pixels diagonally up and left
  DEFB $86,$47            ; LINE of 8 pixels left, stepping down every 2
  DEFB $81,$47            ; LINE of 8 pixels up, stepping right every 2
  DEFB $81,$07            ; LINE of 8 pixels diagonally up and right
  DEFB $85,$84            ; LINE of 5 pixels up, stepping left every 3
  DEFB $86,$CA            ; LINE of 11 pixels left, stepping down every 4
  DEFB $87,$4F            ; LINE of 16 pixels down, stepping left every 2
  DEFB $94,$52            ; LINE of 19 pixels left, stepping up every 10
  DEFB $81,$89            ; LINE of 10 pixels up, stepping right every 3
  DEFB $08,$37,$72        ; MOVE to 55, 114
  DEFB $84,$CB            ; LINE of 12 pixels left, stepping up every 4
  DEFB $89,$05            ; LINE of 6 pixels up, stepping right every 5
  DEFB $80,$CA            ; LINE of 11 pixels right, stepping up every 4
  DEFB $8B,$4A            ; LINE of 11 pixels down, stepping right every 6
  DEFB $08,$3E,$72        ; MOVE to 62, 114
  DEFB $83,$4B            ; LINE of 12 pixels down, stepping right every 2
  DEFB $89,$0D            ; LINE of 14 pixels up, stepping right every 5
  DEFB $83,$49            ; LINE of 10 pixels down, stepping right every 2
  DEFB $87,$C5            ; LINE of 6 pixels down, stepping left every 4
  DEFB $82,$82            ; LINE of 3 pixels right, stepping down every 3
  DEFB $81,$50            ; LINE of 17 pixels up, stepping right every 2
  DEFB $85,$D0            ; LINE of 17 pixels up, stepping left every 4
  DEFB $08,$3E,$73        ; MOVE to 62, 115
  DEFB $9D,$90            ; LINE of 17 pixels up, stepping left every 15
  DEFB $08,$46,$7F        ; MOVE to 70, 127
  DEFB $83,$47            ; LINE of 8 pixels down, stepping right every 2
  DEFB $81,$88            ; LINE of 9 pixels up, stepping right every 3
  DEFB $08,$B9,$04        ; MOVE to 185, 4
  DEFB $81,$B7            ; LINE of 56 pixels up, stepping right every 3
  DEFB $83,$4A            ; LINE of 11 pixels down, stepping right every 2
  DEFB $8B,$45            ; LINE of 6 pixels down, stepping right every 6
  DEFB $81,$45            ; LINE of 6 pixels up, stepping right every 2
  DEFB $81,$CF            ; LINE of 16 pixels up, stepping right every 4
  DEFB $85,$C8            ; LINE of 9 pixels up, stepping left every 4
  DEFB $8A,$08            ; LINE of 9 pixels right, stepping down every 5
  DEFB $85,$C4            ; LINE of 5 pixels up, stepping left every 4
  DEFB $82,$C4            ; LINE of 5 pixels right, stepping down every 4
  DEFB $83,$C8            ; LINE of 9 pixels down, stepping right every 4
  DEFB $8B,$45            ; LINE of 6 pixels down, stepping right every 6
  DEFB $81,$46            ; LINE of 7 pixels up, stepping right every 2
  DEFB $93,$49            ; LINE of 10 pixels down, stepping right every 10
  DEFB $80,$4D            ; LINE of 14 pixels right, stepping up every 2
  DEFB $8F,$0A            ; LINE of 11 pixels down, stepping left every 5
  DEFB $8E,$11            ; LINE of 18 pixels left, stepping down every 5
  DEFB $86,$45            ; LINE of 6 pixels left, stepping down every 2
  DEFB $87,$48            ; LINE of 9 pixels down, stepping left every 2
  DEFB $82,$43            ; LINE of 4 pixels right, stepping down every 2
  DEFB $88,$0E            ; LINE of 15 pixels right, stepping up every 5
  DEFB $87,$C6            ; LINE of 7 pixels down, stepping left every 4
  DEFB $83,$89            ; LINE of 10 pixels down, stepping right every 3
  DEFB $83,$C5            ; LINE of 6 pixels down, stepping right every 4
  DEFB $81,$4F            ; LINE of 16 pixels up, stepping right every 2
  DEFB $83,$96            ; LINE of 23 pixels down, stepping right every 3
  DEFB $08,$B2,$25        ; MOVE to 178, 37
  DEFB $A1,$1E            ; LINE of 31 pixels up, stepping right every 17
  DEFB $88,$4A            ; LINE of 11 pixels right, stepping up every 6
  DEFB $08,$BD,$45        ; MOVE to 189, 69
  DEFB $87,$A1            ; LINE of 34 pixels down, stepping left every 3
  DEFB $08,$B9,$04        ; MOVE to 185, 4
  DEFB $90,$A1            ; LINE of 34 pixels right, stepping up every 11
  DEFB $82,$A1            ; LINE of 34 pixels right, stepping down every 3
  DEFB $08,$B2,$61        ; MOVE to 178, 97
  DEFB $80,$49            ; LINE of 10 pixels right, stepping up every 2
  DEFB $8B,$CD            ; LINE of 14 pixels down, stepping right every 8
  DEFB $86,$89            ; LINE of 10 pixels left, stepping down every 3
  DEFB $8D,$4B            ; LINE of 12 pixels up, stepping left every 6
  DEFB $08,$82,$7B        ; MOVE to 130, 123
  DEFB $87,$C3            ; LINE of 4 pixels down, stepping left every 4
  DEFB $80,$85            ; LINE of 6 pixels right, stepping up every 3
  DEFB $84,$45            ; LINE of 6 pixels left, stepping up every 2
  DEFB $08,$78,$76        ; MOVE to 120, 118
  DEFB $85,$05            ; LINE of 6 pixels diagonally up and left
  DEFB $84,$85            ; LINE of 6 pixels left, stepping up every 3
  DEFB $8C,$45            ; LINE of 6 pixels left, stepping up every 6
  DEFB $86,$05            ; LINE of 6 pixels diagonally left and down
  DEFB $87,$05            ; LINE of 6 pixels diagonally down and left
  DEFB $87,$45            ; LINE of 6 pixels down, stepping left every 2
  DEFB $88,$45            ; LINE of 6 pixels right, stepping up every 6
  DEFB $88,$05            ; LINE of 6 pixels right, stepping up every 5
  DEFB $88,$45            ; LINE of 6 pixels right, stepping up every 6
  DEFB $88,$05            ; LINE of 6 pixels right, stepping up every 5
  DEFB $80,$49            ; LINE of 10 pixels right, stepping up every 2
  DEFB $08,$6B,$06        ; MOVE to 107, 6
  DEFB $85,$54            ; LINE of 21 pixels up, stepping left every 2
  DEFB $85,$89            ; LINE of 10 pixels up, stepping left every 3
  DEFB $81,$89            ; LINE of 10 pixels up, stepping right every 3
  DEFB $08,$65,$35        ; MOVE to 101, 53
  DEFB $80,$49            ; LINE of 10 pixels right, stepping up every 2
  DEFB $80,$09            ; LINE of 10 pixels diagonally right and up
  DEFB $81,$89            ; LINE of 10 pixels up, stepping right every 3
  DEFB $8D,$09            ; LINE of 10 pixels up, stepping left every 5
  DEFB $85,$09            ; LINE of 10 pixels diagonally up and left
  DEFB $8C,$09            ; LINE of 10 pixels left, stepping up every 5
  DEFB $8C,$89            ; LINE of 10 pixels left, stepping up every 7
  DEFB $8C,$89            ; LINE of 10 pixels left, stepping up every 7
  DEFB $08,$4E,$67        ; MOVE to 78, 103
  DEFB $84,$C3            ; LINE of 4 pixels left, stepping up every 4
  DEFB $08,$D1,$07        ; MOVE to 209, 7
  DEFB $84,$D5            ; LINE of 22 pixels left, stepping up every 4
  DEFB $08,$A9,$15        ; MOVE to 169, 21
  DEFB $84,$55            ; LINE of 22 pixels left, stepping up every 2
  DEFB $85,$4E            ; LINE of 15 pixels up, stepping left every 2
  DEFB $95,$09            ; LINE of 10 pixels up, stepping left every 9
  DEFB $81,$C9            ; LINE of 10 pixels up, stepping right every 4
  DEFB $81,$89            ; LINE of 10 pixels up, stepping right every 3
  DEFB $95,$09            ; LINE of 10 pixels up, stepping left every 9
  DEFB $85,$C9            ; LINE of 10 pixels up, stepping left every 4
  DEFB $84,$49            ; LINE of 10 pixels left, stepping up every 2
  DEFB $84,$49            ; LINE of 10 pixels left, stepping up every 2
  DEFB $8C,$C9            ; LINE of 10 pixels left, stepping up every 8
  DEFB $08,$51,$6C        ; MOVE to 81, 108
  DEFB $8C,$C7            ; LINE of 8 pixels left, stepping up every 8
  DEFB $08,$44,$6D        ; MOVE to 68, 109
  DEFB $84,$C3            ; LINE of 4 pixels left, stepping up every 4
  DEFB $40,$00,$00        ; FILL with black from 0, 0
  DEFB $40,$48,$7F        ; FILL with black from 72, 127
  DEFB $08,$7A,$65        ; MOVE to 122, 101
  DEFB $82,$41            ; LINE of 2 pixels right, stepping down every 2
  DEFB $83,$41            ; LINE of 2 pixels down, stepping right every 2
  DEFB $84,$83            ; LINE of 4 pixels left, stepping up every 3
  DEFB $08,$7F,$5B        ; MOVE to 127, 91
  DEFB $84,$83            ; LINE of 4 pixels left, stepping up every 3
  DEFB $80,$43            ; LINE of 4 pixels right, stepping up every 2
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$86,$5E        ; MOVE to 134, 94
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $81,$83            ; LINE of 4 pixels up, stepping right every 3
  DEFB $84,$C3            ; LINE of 4 pixels left, stepping up every 4
  DEFB $08,$82,$55        ; MOVE to 130, 85
  DEFB $86,$03            ; LINE of 4 pixels diagonally left and down
  DEFB $88,$03            ; LINE of 4 pixels right, stepping up every 5
  DEFB $81,$43            ; LINE of 4 pixels up, stepping right every 2
  DEFB $08,$88,$4F        ; MOVE to 136, 79
  DEFB $81,$43            ; LINE of 4 pixels up, stepping right every 2
  DEFB $82,$03            ; LINE of 4 pixels diagonally right and down
  DEFB $86,$83            ; LINE of 4 pixels left, stepping down every 3
  DEFB $84,$43            ; LINE of 4 pixels left, stepping up every 2
  DEFB $08,$7D,$45        ; MOVE to 125, 69
  DEFB $81,$83            ; LINE of 4 pixels up, stepping right every 3
  DEFB $83,$03            ; LINE of 4 pixels diagonally down and right
  DEFB $8E,$05            ; LINE of 6 pixels left, stepping down every 5
  DEFB $08,$79,$3A        ; MOVE to 121, 58
  DEFB $8E,$03            ; LINE of 4 pixels left, stepping down every 5
  DEFB $81,$43            ; LINE of 4 pixels up, stepping right every 2
  DEFB $80,$83            ; LINE of 4 pixels right, stepping up every 3
  DEFB $87,$C4            ; LINE of 5 pixels down, stepping left every 4
  DEFB $08,$6B,$2C        ; MOVE to 107, 44
  DEFB $81,$44            ; LINE of 5 pixels up, stepping right every 2
  DEFB $80,$42            ; LINE of 3 pixels right, stepping up every 2
  DEFB $83,$42            ; LINE of 3 pixels down, stepping right every 2
  DEFB $82,$C2            ; LINE of 3 pixels right, stepping down every 4
  DEFB $87,$42            ; LINE of 3 pixels down, stepping left every 2
  DEFB $86,$42            ; LINE of 3 pixels left, stepping down every 2
  DEFB $86,$82            ; LINE of 3 pixels left, stepping down every 3
  DEFB $84,$43            ; LINE of 4 pixels left, stepping up every 2
  DEFB $08,$75,$1A        ; MOVE to 117, 26
  DEFB $85,$02            ; LINE of 3 pixels diagonally up and left
  DEFB $85,$42            ; LINE of 3 pixels up, stepping left every 2
  DEFB $85,$C2            ; LINE of 3 pixels up, stepping left every 4
  DEFB $80,$82            ; LINE of 3 pixels right, stepping up every 3
  DEFB $82,$42            ; LINE of 3 pixels right, stepping down every 2
  DEFB $81,$42            ; LINE of 3 pixels up, stepping right every 2
  DEFB $83,$02            ; LINE of 3 pixels diagonally down and right
  DEFB $87,$42            ; LINE of 3 pixels down, stepping left every 2
  DEFB $87,$82            ; LINE of 3 pixels down, stepping left every 3
  DEFB $87,$42            ; LINE of 3 pixels down, stepping left every 2
  DEFB $86,$C2            ; LINE of 3 pixels left, stepping down every 4
  DEFB $08,$89,$09        ; MOVE to 137, 9
  DEFB $86,$C2            ; LINE of 3 pixels left, stepping down every 4
  DEFB $84,$42            ; LINE of 3 pixels left, stepping up every 2
  DEFB $85,$42            ; LINE of 3 pixels up, stepping left every 2
  DEFB $81,$82            ; LINE of 3 pixels up, stepping right every 3
  DEFB $81,$82            ; LINE of 3 pixels up, stepping right every 3
  DEFB $80,$82            ; LINE of 3 pixels right, stepping up every 3
  DEFB $83,$42            ; LINE of 3 pixels down, stepping right every 2
  DEFB $81,$42            ; LINE of 3 pixels up, stepping right every 2
  DEFB $81,$42            ; LINE of 3 pixels up, stepping right every 2
  DEFB $83,$42            ; LINE of 3 pixels down, stepping right every 2
  DEFB $83,$82            ; LINE of 3 pixels down, stepping right every 3
  DEFB $83,$C2            ; LINE of 3 pixels down, stepping right every 4
  DEFB $87,$42            ; LINE of 3 pixels down, stepping left every 2
  DEFB $87,$02            ; LINE of 3 pixels diagonally down and left
  DEFB $42,$85,$0D        ; FILL with red from 133, 13
  DEFB $42,$75,$1F        ; FILL with red from 117, 31
  DEFB $42,$70,$2E        ; FILL with red from 112, 46
  DEFB $42,$77,$3C        ; FILL with red from 119, 60
  DEFB $42,$7E,$46        ; FILL with red from 126, 70
  DEFB $42,$81,$52        ; FILL with red from 129, 82
  DEFB $42,$8B,$51        ; FILL with red from 139, 81
  DEFB $08,$87,$43        ; MOVE to 135, 67
  DEFB $87,$02            ; LINE of 3 pixels diagonally down and left
  DEFB $82,$42            ; LINE of 3 pixels right, stepping down every 2
  DEFB $80,$42            ; LINE of 3 pixels right, stepping up every 2
  DEFB $85,$02            ; LINE of 3 pixels diagonally up and left
  DEFB $08,$7E,$31        ; MOVE to 126, 49
  DEFB $85,$82            ; LINE of 3 pixels up, stepping left every 3
  DEFB $81,$42            ; LINE of 3 pixels up, stepping right every 2
  DEFB $80,$82            ; LINE of 3 pixels right, stepping up every 3
  DEFB $82,$42            ; LINE of 3 pixels right, stepping down every 2
  DEFB $83,$C2            ; LINE of 3 pixels down, stepping right every 4
  DEFB $87,$02            ; LINE of 3 pixels diagonally down and left
  DEFB $86,$82            ; LINE of 3 pixels left, stepping down every 3
  DEFB $08,$84,$23        ; MOVE to 132, 35
  DEFB $86,$82            ; LINE of 3 pixels left, stepping down every 3
  DEFB $85,$42            ; LINE of 3 pixels up, stepping left every 2
  DEFB $85,$82            ; LINE of 3 pixels up, stepping left every 3
  DEFB $81,$42            ; LINE of 3 pixels up, stepping right every 2
  DEFB $82,$42            ; LINE of 3 pixels right, stepping down every 2
  DEFB $80,$02            ; LINE of 3 pixels diagonally right and up
  DEFB $83,$C2            ; LINE of 3 pixels down, stepping right every 4
  DEFB $83,$C2            ; LINE of 3 pixels down, stepping right every 4
  DEFB $87,$82            ; LINE of 3 pixels down, stepping left every 3
  DEFB $87,$82            ; LINE of 3 pixels down, stepping left every 3
  DEFB $08,$93,$15        ; MOVE to 147, 21
  DEFB $87,$82            ; LINE of 3 pixels down, stepping left every 3
  DEFB $83,$02            ; LINE of 3 pixels diagonally down and right
  DEFB $82,$C2            ; LINE of 3 pixels right, stepping down every 4
  DEFB $81,$02            ; LINE of 3 pixels diagonally up and right
  DEFB $81,$82            ; LINE of 3 pixels up, stepping right every 3
  DEFB $85,$02            ; LINE of 3 pixels diagonally up and left
  DEFB $84,$42            ; LINE of 3 pixels left, stepping up every 2
  DEFB $86,$82            ; LINE of 3 pixels left, stepping down every 3
  DEFB $83,$42            ; LINE of 3 pixels down, stepping right every 2
  DEFB $42,$97,$15        ; FILL with red from 151, 21
  DEFB $42,$83,$27        ; FILL with red from 131, 39
  DEFB $42,$82,$34        ; FILL with red from 130, 52
  DEFB $42,$87,$41        ; FILL with red from 135, 65
  DEFB $08,$75,$67        ; MOVE to 117, 103
  DEFB $80,$01            ; LINE of 2 pixels diagonally right and up
  DEFB $08,$76,$67        ; MOVE to 118, 103
  DEFB $80,$01            ; LINE of 2 pixels diagonally right and up
  DEFB $08,$74,$67        ; MOVE to 116, 103
  DEFB $80,$01            ; LINE of 2 pixels diagonally right and up
  DEFB $08,$6F,$67        ; MOVE to 111, 103
  DEFB $80,$01            ; LINE of 2 pixels diagonally right and up
  DEFB $08,$6E,$67        ; MOVE to 110, 103
  DEFB $80,$01            ; LINE of 2 pixels diagonally right and up
  DEFB $08,$70,$64        ; MOVE to 112, 100
  DEFB $81,$41            ; LINE of 2 pixels up, stepping right every 2
  DEFB $08,$71,$64        ; MOVE to 113, 100
  DEFB $81,$41            ; LINE of 2 pixels up, stepping right every 2
  DEFB $08,$76,$62        ; MOVE to 118, 98
  DEFB $81,$41            ; LINE of 2 pixels up, stepping right every 2
  DEFB $08,$77,$62        ; MOVE to 119, 98
  DEFB $81,$41            ; LINE of 2 pixels up, stepping right every 2
  DEFB $08,$78,$61        ; MOVE to 120, 97
  DEFB $81,$41            ; LINE of 2 pixels up, stepping right every 2
  DEFB $08,$6A,$67        ; MOVE to 106, 103
  DEFB $81,$41            ; LINE of 2 pixels up, stepping right every 2
  DEFB $08,$66,$67        ; MOVE to 102, 103
  DEFB $81,$41            ; LINE of 2 pixels up, stepping right every 2
  DEFB $00                ; End of the picture

; Picture for location 11: narrow place
;
; A border colour and a starting attribute, then 27 moves, 85 lines, 5 fills, 1
; paint, ending at $00.
LOC11_NARROW_PLACE_PIC:
  DEFB $07                ; Border: white
  DEFB $38                ; The canvas starts white paper, black ink
  DEFB $08,$A1,$00        ; MOVE to 161, 0
  DEFB $80,$0B            ; LINE of 12 pixels diagonally right and up
  DEFB $81,$4B            ; LINE of 12 pixels up, stepping right every 2
  DEFB $81,$8B            ; LINE of 12 pixels up, stepping right every 3
  DEFB $85,$50            ; LINE of 17 pixels up, stepping left every 2
  DEFB $84,$D0            ; LINE of 17 pixels left, stepping up every 4
  DEFB $8C,$50            ; LINE of 17 pixels left, stepping up every 6
  DEFB $84,$90            ; LINE of 17 pixels left, stepping up every 3
  DEFB $8C,$50            ; LINE of 17 pixels left, stepping up every 6
  DEFB $84,$50            ; LINE of 17 pixels left, stepping up every 2
  DEFB $8D,$0D            ; LINE of 14 pixels up, stepping left every 5
  DEFB $95,$8D            ; LINE of 14 pixels up, stepping left every 11
  DEFB $81,$46            ; LINE of 7 pixels up, stepping right every 2
  DEFB $80,$85            ; LINE of 6 pixels right, stepping up every 3
  DEFB $08,$60,$6E        ; MOVE to 96, 110
  DEFB $87,$45            ; LINE of 6 pixels down, stepping left every 2
  DEFB $8B,$D2            ; LINE of 19 pixels down, stepping right every 8
  DEFB $83,$87            ; LINE of 8 pixels down, stepping right every 3
  DEFB $82,$4A            ; LINE of 11 pixels right, stepping down every 2
  DEFB $8A,$4F            ; LINE of 16 pixels right, stepping down every 6
  DEFB $82,$8F            ; LINE of 16 pixels right, stepping down every 3
  DEFB $8A,$23            ; LINE of 36 pixels right, stepping down every 5
  DEFB $82,$63            ; LINE of 36 pixels right, stepping down every 2
  DEFB $8A,$23            ; LINE of 36 pixels right, stepping down every 5
  DEFB $8A,$23            ; LINE of 36 pixels right, stepping down every 5
  DEFB $08,$61,$6F        ; MOVE to 97, 111
  DEFB $81,$51            ; LINE of 18 pixels up, stepping right every 2
  DEFB $08,$3E,$7F        ; MOVE to 62, 127
  DEFB $87,$87            ; LINE of 8 pixels down, stepping left every 3
  DEFB $8E,$04            ; LINE of 5 pixels left, stepping down every 5
  DEFB $97,$BE            ; LINE of 63 pixels down, stepping left every 11
  DEFB $97,$BE            ; LINE of 63 pixels down, stepping left every 11
  DEFB $08,$38,$76        ; MOVE to 56, 118
  DEFB $92,$29            ; LINE of 42 pixels right, stepping down every 9
  DEFB $08,$38,$75        ; MOVE to 56, 117
  DEFB $92,$29            ; LINE of 42 pixels right, stepping down every 9
  DEFB $08,$56,$65        ; MOVE to 86, 101
  DEFB $8F,$BE            ; LINE of 63 pixels down, stepping left every 7
  DEFB $8F,$97            ; LINE of 24 pixels down, stepping left every 7
  DEFB $08,$5A,$4B        ; MOVE to 90, 75
  DEFB $97,$BD            ; LINE of 62 pixels down, stepping left every 11
  DEFB $08,$6A,$42        ; MOVE to 106, 66
  DEFB $A7,$39            ; LINE of 58 pixels down, stepping left every 17
  DEFB $08,$89,$3B        ; MOVE to 137, 59
  DEFB $8F,$B4            ; LINE of 53 pixels down, stepping left every 7
  DEFB $08,$9B,$38        ; MOVE to 155, 56
  DEFB $87,$F3            ; LINE of 52 pixels down, stepping left every 4
  DEFB $08,$AD,$34        ; MOVE to 173, 52
  DEFB $87,$72            ; LINE of 51 pixels down, stepping left every 2
  DEFB $08,$B5,$1F        ; MOVE to 181, 31
  DEFB $87,$3E            ; LINE of 63 pixels diagonally down and left
  DEFB $08,$44,$73        ; MOVE to 68, 115
  DEFB $8F,$BE            ; LINE of 63 pixels down, stepping left every 7
  DEFB $97,$17            ; LINE of 24 pixels down, stepping left every 9
  DEFB $08,$57,$65        ; MOVE to 87, 101
  DEFB $8F,$BE            ; LINE of 63 pixels down, stepping left every 7
  DEFB $8F,$97            ; LINE of 24 pixels down, stepping left every 7
  DEFB $08,$33,$4E        ; MOVE to 51, 78
  DEFB $84,$8D            ; LINE of 14 pixels left, stepping up every 3
  DEFB $84,$0D            ; LINE of 14 pixels diagonally left and up
  DEFB $85,$4D            ; LINE of 14 pixels up, stepping left every 2
  DEFB $85,$12            ; LINE of 19 pixels diagonally up and left
  DEFB $08,$1B,$75        ; MOVE to 27, 117
  DEFB $81,$02            ; LINE of 3 pixels diagonally up and right
  DEFB $80,$42            ; LINE of 3 pixels right, stepping up every 2
  DEFB $82,$82            ; LINE of 3 pixels right, stepping down every 3
  DEFB $82,$42            ; LINE of 3 pixels right, stepping down every 2
  DEFB $83,$42            ; LINE of 3 pixels down, stepping right every 2
  DEFB $86,$82            ; LINE of 3 pixels left, stepping down every 3
  DEFB $86,$42            ; LINE of 3 pixels left, stepping down every 2
  DEFB $87,$42            ; LINE of 3 pixels down, stepping left every 2
  DEFB $87,$42            ; LINE of 3 pixels down, stepping left every 2
  DEFB $83,$82            ; LINE of 3 pixels down, stepping right every 3
  DEFB $83,$42            ; LINE of 3 pixels down, stepping right every 2
  DEFB $83,$02            ; LINE of 3 pixels diagonally down and right
  DEFB $86,$C2            ; LINE of 3 pixels left, stepping down every 4
  DEFB $84,$82            ; LINE of 3 pixels left, stepping up every 3
  DEFB $84,$42            ; LINE of 3 pixels left, stepping up every 2
  DEFB $85,$02            ; LINE of 3 pixels diagonally up and left
  DEFB $85,$42            ; LINE of 3 pixels up, stepping left every 2
  DEFB $85,$82            ; LINE of 3 pixels up, stepping left every 3
  DEFB $81,$82            ; LINE of 3 pixels up, stepping right every 3
  DEFB $81,$42            ; LINE of 3 pixels up, stepping right every 2
  DEFB $80,$02            ; LINE of 3 pixels diagonally right and up
  DEFB $41,$18,$78        ; FILL with blue from 24, 120
  DEFB $20,$58,$00,$16,$11,$00,$0F,$0C ; PAINT black ink from row 0, column 0,
  DEFB $01,$0A,$05,$FF                 ; along a path of 8 steps
  DEFB $08,$00,$47        ; MOVE to 0, 71
  DEFB $E2,$F3            ; LINE of 52 pixels right, stepping down every 52
  DEFB $40,$0B,$45        ; FILL with black from 11, 69
  DEFB $08,$30,$48        ; MOVE to 48, 72
  DEFB $8D,$07            ; LINE of 8 pixels up, stepping left every 5
  DEFB $40,$32,$49        ; FILL with black from 50, 73
  DEFB $08,$60,$58        ; MOVE to 96, 88
  DEFB $81,$78            ; LINE of 57 pixels up, stepping right every 2
  DEFB $08,$7F,$46        ; MOVE to 127, 70
  DEFB $81,$F8            ; LINE of 57 pixels up, stepping right every 4
  DEFB $08,$A1,$3E        ; MOVE to 161, 62
  DEFB $89,$38            ; LINE of 57 pixels up, stepping right every 5
  DEFB $89,$38            ; LINE of 57 pixels up, stepping right every 5
  DEFB $08,$CA,$2F        ; MOVE to 202, 47
  DEFB $81,$B8            ; LINE of 57 pixels up, stepping right every 3
  DEFB $81,$78            ; LINE of 57 pixels up, stepping right every 2
  DEFB $08,$46,$76        ; MOVE to 70, 118
  DEFB $81,$CA            ; LINE of 11 pixels up, stepping right every 4
  DEFB $08,$53,$75        ; MOVE to 83, 117
  DEFB $89,$0A            ; LINE of 11 pixels up, stepping right every 5
  DEFB $08,$31,$20        ; MOVE to 49, 32
  DEFB $82,$46            ; LINE of 7 pixels right, stepping down every 2
  DEFB $82,$D3            ; LINE of 20 pixels right, stepping down every 4
  DEFB $08,$4C,$10        ; MOVE to 76, 16
  DEFB $82,$C8            ; LINE of 9 pixels right, stepping down every 4
  DEFB $82,$D0            ; LINE of 17 pixels right, stepping down every 4
  DEFB $8A,$5B            ; LINE of 28 pixels right, stepping down every 6
  DEFB $88,$8C            ; LINE of 13 pixels right, stepping up every 7
  DEFB $82,$46            ; LINE of 7 pixels right, stepping down every 2
  DEFB $83,$47            ; LINE of 8 pixels down, stepping right every 2
  DEFB $40,$33,$0D        ; FILL with black from 51, 13
  DEFB $42,$B5,$00        ; FILL with red from 181, 0
  DEFB $00                ; End of the picture

; Picture for location 37: dragons desolation
;
; A border colour and a starting attribute, then 56 moves, 187 lines, 15 fills,
; ending at $00.
LOC37_DRAGONS_DESOLATION_PIC:
  DEFB $07                ; Border: white
  DEFB $38                ; The canvas starts white paper, black ink
  DEFB $08,$5B,$2B        ; MOVE to 91, 43
  DEFB $8D,$14            ; LINE of 21 pixels up, stepping left every 5
  DEFB $85,$8B            ; LINE of 12 pixels up, stepping left every 3
  DEFB $A1,$51            ; LINE of 18 pixels up, stepping right every 18
  DEFB $81,$06            ; LINE of 7 pixels diagonally up and right
  DEFB $91,$07            ; LINE of 8 pixels up, stepping right every 9
  DEFB $88,$03            ; LINE of 4 pixels right, stepping up every 5
  DEFB $97,$8B            ; LINE of 12 pixels down, stepping left every 11
  DEFB $86,$05            ; LINE of 6 pixels diagonally left and down
  DEFB $9B,$8E            ; LINE of 15 pixels down, stepping right every 15
  DEFB $83,$A1            ; LINE of 34 pixels down, stepping right every 3
  DEFB $96,$49            ; LINE of 10 pixels left, stepping down every 10
  DEFB $40,$5F,$2E        ; FILL with black from 95, 46
  DEFB $08,$52,$56        ; MOVE to 82, 86
  DEFB $84,$89            ; LINE of 10 pixels left, stepping up every 3
  DEFB $85,$4C            ; LINE of 13 pixels up, stepping left every 2
  DEFB $87,$43            ; LINE of 4 pixels down, stepping left every 2
  DEFB $83,$4F            ; LINE of 16 pixels down, stepping right every 2
  DEFB $82,$CA            ; LINE of 11 pixels right, stepping down every 4
  DEFB $40,$50,$52        ; FILL with black from 80, 82
  DEFB $08,$60,$39        ; MOVE to 96, 57
  DEFB $80,$09            ; LINE of 10 pixels diagonally right and up
  DEFB $85,$86            ; LINE of 7 pixels up, stepping left every 3
  DEFB $82,$82            ; LINE of 3 pixels right, stepping down every 3
  DEFB $83,$86            ; LINE of 7 pixels down, stepping right every 3
  DEFB $87,$0C            ; LINE of 13 pixels diagonally down and left
  DEFB $40,$61,$38        ; FILL with black from 97, 56
  DEFB $08,$C3,$4B        ; MOVE to 195, 75
  DEFB $91,$CB            ; LINE of 12 pixels up, stepping right every 12
  DEFB $80,$46            ; LINE of 7 pixels right, stepping up every 2
  DEFB $8D,$4E            ; LINE of 15 pixels up, stepping left every 6
  DEFB $84,$46            ; LINE of 7 pixels left, stepping up every 2
  DEFB $80,$01            ; LINE of 2 pixels diagonally right and up
  DEFB $82,$47            ; LINE of 8 pixels right, stepping down every 2
  DEFB $8B,$D2            ; LINE of 19 pixels down, stepping right every 8
  DEFB $86,$47            ; LINE of 8 pixels left, stepping down every 2
  DEFB $97,$8A            ; LINE of 11 pixels down, stepping left every 11
  DEFB $84,$02            ; LINE of 3 pixels diagonally left and up
  DEFB $08,$C2,$55        ; MOVE to 194, 85
  DEFB $84,$4E            ; LINE of 15 pixels left, stepping up every 2
  DEFB $08,$B3,$5D        ; MOVE to 179, 93
  DEFB $82,$91            ; LINE of 18 pixels right, stepping down every 3
  DEFB $08,$BC,$57        ; MOVE to 188, 87
  DEFB $86,$C9            ; LINE of 10 pixels left, stepping down every 4
  DEFB $08,$BC,$56        ; MOVE to 188, 86
  DEFB $86,$C9            ; LINE of 10 pixels left, stepping down every 4
  DEFB $08,$C9,$62        ; MOVE to 201, 98
  DEFB $84,$49            ; LINE of 10 pixels left, stepping up every 2
  DEFB $08,$C9,$61        ; MOVE to 201, 97
  DEFB $84,$49            ; LINE of 10 pixels left, stepping up every 2
  DEFB $40,$C9,$57        ; FILL with black from 201, 87
  DEFB $40,$C1,$57        ; FILL with black from 193, 87
  DEFB $40,$B7,$5B        ; FILL with black from 183, 91
  DEFB $08,$B5,$5C        ; MOVE to 181, 92
  DEFB $84,$00            ; LINE of 1 pixel diagonally left and up
  DEFB $08,$CD,$65        ; MOVE to 205, 101
  DEFB $80,$05            ; LINE of 6 pixels diagonally right and up
  DEFB $08,$C9,$6C        ; MOVE to 201, 108
  DEFB $81,$43            ; LINE of 4 pixels up, stepping right every 2
  DEFB $08,$BD,$5A        ; MOVE to 189, 90
  DEFB $81,$C4            ; LINE of 5 pixels up, stepping right every 4
  DEFB $85,$46            ; LINE of 7 pixels up, stepping left every 2
  DEFB $08,$7E,$30        ; MOVE to 126, 48
  DEFB $8C,$0A            ; LINE of 11 pixels left, stepping up every 5
  DEFB $81,$02            ; LINE of 3 pixels diagonally up and right
  DEFB $82,$89            ; LINE of 10 pixels right, stepping down every 3
  DEFB $87,$42            ; LINE of 3 pixels down, stepping left every 2
  DEFB $40,$77,$33        ; FILL with black from 119, 51
  DEFB $08,$76,$1A        ; MOVE to 118, 26
  DEFB $8C,$C6            ; LINE of 7 pixels left, stepping up every 8
  DEFB $84,$44            ; LINE of 5 pixels left, stepping up every 2
  DEFB $84,$02            ; LINE of 3 pixels diagonally left and up
  DEFB $83,$86            ; LINE of 7 pixels down, stepping right every 3
  DEFB $82,$C6            ; LINE of 7 pixels right, stepping down every 4
  DEFB $8A,$86            ; LINE of 7 pixels right, stepping down every 7
  DEFB $82,$02            ; LINE of 3 pixels diagonally right and down
  DEFB $80,$84            ; LINE of 5 pixels right, stepping up every 3
  DEFB $82,$47            ; LINE of 8 pixels right, stepping down every 2
  DEFB $81,$03            ; LINE of 4 pixels diagonally up and right
  DEFB $85,$04            ; LINE of 5 pixels diagonally up and left
  DEFB $85,$C3            ; LINE of 4 pixels up, stepping left every 4
  DEFB $84,$03            ; LINE of 4 pixels diagonally left and up
  DEFB $8C,$03            ; LINE of 4 pixels left, stepping up every 5
  DEFB $87,$03            ; LINE of 4 pixels diagonally down and left
  DEFB $87,$03            ; LINE of 4 pixels diagonally down and left
  DEFB $08,$7E,$22        ; MOVE to 126, 34
  DEFB $85,$C3            ; LINE of 4 pixels up, stepping left every 4
  DEFB $85,$83            ; LINE of 4 pixels up, stepping left every 3
  DEFB $85,$03            ; LINE of 4 pixels diagonally up and left
  DEFB $82,$82            ; LINE of 3 pixels right, stepping down every 3
  DEFB $82,$43            ; LINE of 4 pixels right, stepping down every 2
  DEFB $83,$43            ; LINE of 4 pixels down, stepping right every 2
  DEFB $8F,$03            ; LINE of 4 pixels down, stepping left every 5
  DEFB $83,$82            ; LINE of 3 pixels down, stepping right every 3
  DEFB $08,$74,$16        ; MOVE to 116, 22
  DEFB $87,$82            ; LINE of 3 pixels down, stepping left every 3
  DEFB $83,$03            ; LINE of 4 pixels diagonally down and right
  DEFB $82,$C3            ; LINE of 4 pixels right, stepping down every 4
  DEFB $8A,$03            ; LINE of 4 pixels right, stepping down every 5
  DEFB $80,$C3            ; LINE of 4 pixels right, stepping up every 4
  DEFB $80,$C3            ; LINE of 4 pixels right, stepping up every 4
  DEFB $80,$82            ; LINE of 3 pixels right, stepping up every 3
  DEFB $84,$41            ; LINE of 2 pixels left, stepping up every 2
  DEFB $40,$80,$11        ; FILL with black from 128, 17
  DEFB $08,$73,$12        ; MOVE to 115, 18
  DEFB $94,$4C            ; LINE of 13 pixels left, stepping up every 10
  DEFB $08,$73,$13        ; MOVE to 115, 19
  DEFB $94,$4C            ; LINE of 13 pixels left, stepping up every 10
  DEFB $08,$82,$1C        ; MOVE to 130, 28
  DEFB $84,$83            ; LINE of 4 pixels left, stepping up every 3
  DEFB $08,$81,$1B        ; MOVE to 129, 27
  DEFB $84,$43            ; LINE of 4 pixels left, stepping up every 2
  DEFB $08,$81,$1A        ; MOVE to 129, 26
  DEFB $84,$43            ; LINE of 4 pixels left, stepping up every 2
  DEFB $08,$7B,$16        ; MOVE to 123, 22
  DEFB $84,$42            ; LINE of 3 pixels left, stepping up every 2
  DEFB $08,$7C,$17        ; MOVE to 124, 23
  DEFB $84,$42            ; LINE of 3 pixels left, stepping up every 2
  DEFB $08,$7A,$17        ; MOVE to 122, 23
  DEFB $84,$00            ; LINE of 1 pixel diagonally left and up
  DEFB $08,$76,$1A        ; MOVE to 118, 26
  DEFB $87,$C3            ; LINE of 4 pixels down, stepping left every 4
  DEFB $08,$00,$6C        ; MOVE to 0, 108
  DEFB $8A,$8B            ; LINE of 12 pixels right, stepping down every 7
  DEFB $82,$4B            ; LINE of 12 pixels right, stepping down every 2
  DEFB $8A,$5B            ; LINE of 28 pixels right, stepping down every 6
  DEFB $9A,$1B            ; LINE of 28 pixels right, stepping down every 13
  DEFB $82,$5B            ; LINE of 28 pixels right, stepping down every 2
  DEFB $82,$4B            ; LINE of 12 pixels right, stepping down every 2
  DEFB $08,$6C,$51        ; MOVE to 108, 81
  DEFB $88,$17            ; LINE of 24 pixels right, stepping up every 5
  DEFB $81,$88            ; LINE of 9 pixels up, stepping right every 3
  DEFB $88,$17            ; LINE of 24 pixels right, stepping up every 5
  DEFB $80,$4C            ; LINE of 13 pixels right, stepping up every 2
  DEFB $88,$4C            ; LINE of 13 pixels right, stepping up every 6
  DEFB $8A,$33            ; LINE of 52 pixels right, stepping down every 5
  DEFB $82,$B3            ; LINE of 52 pixels right, stepping down every 3
  DEFB $08,$00,$43        ; MOVE to 0, 67
  DEFB $A2,$B3            ; LINE of 52 pixels right, stepping down every 19
  DEFB $90,$73            ; LINE of 52 pixels right, stepping up every 10
  DEFB $98,$33            ; LINE of 52 pixels right, stepping up every 13
  DEFB $A8,$73            ; LINE of 52 pixels right, stepping up every 22
  DEFB $92,$73            ; LINE of 52 pixels right, stepping down every 10
  DEFB $08,$82,$00        ; MOVE to 130, 0
  DEFB $88,$EF            ; LINE of 48 pixels right, stepping up every 8
  DEFB $C8,$64            ; LINE of 37 pixels right, stepping up every 38
  DEFB $80,$D3            ; LINE of 20 pixels right, stepping up every 4
  DEFB $90,$95            ; LINE of 22 pixels right, stepping up every 11
  DEFB $08,$41,$00        ; MOVE to 65, 0
  DEFB $88,$BE            ; LINE of 63 pixels right, stepping up every 7
  DEFB $88,$7E            ; LINE of 63 pixels right, stepping up every 6
  DEFB $90,$7E            ; LINE of 63 pixels right, stepping up every 10
  DEFB $90,$7E            ; LINE of 63 pixels right, stepping up every 10
  DEFB $08,$68,$00        ; MOVE to 104, 0
  DEFB $88,$FE            ; LINE of 63 pixels right, stepping up every 8
  DEFB $90,$3E            ; LINE of 63 pixels right, stepping up every 9
  DEFB $90,$3E            ; LINE of 63 pixels right, stepping up every 9
  DEFB $40,$DB,$09        ; FILL with black from 219, 9
  DEFB $08,$EE,$0F        ; MOVE to 238, 15
  DEFB $85,$87            ; LINE of 8 pixels up, stepping left every 3
  DEFB $84,$49            ; LINE of 10 pixels left, stepping up every 2
  DEFB $81,$45            ; LINE of 6 pixels up, stepping right every 2
  DEFB $84,$9D            ; LINE of 30 pixels left, stepping up every 3
  DEFB $8C,$5D            ; LINE of 30 pixels left, stepping up every 6
  DEFB $80,$83            ; LINE of 4 pixels right, stepping up every 3
  DEFB $92,$18            ; LINE of 25 pixels right, stepping down every 9
  DEFB $82,$E6            ; LINE of 39 pixels right, stepping down every 4
  DEFB $87,$87            ; LINE of 8 pixels down, stepping left every 3
  DEFB $82,$4D            ; LINE of 14 pixels right, stepping down every 2
  DEFB $83,$87            ; LINE of 8 pixels down, stepping right every 3
  DEFB $08,$AA,$31        ; MOVE to 170, 49
  DEFB $8C,$56            ; LINE of 23 pixels left, stepping up every 6
  DEFB $92,$18            ; LINE of 25 pixels right, stepping down every 9
  DEFB $08,$BB,$0A        ; MOVE to 187, 10
  DEFB $85,$88            ; LINE of 9 pixels up, stepping left every 3
  DEFB $84,$D8            ; LINE of 25 pixels left, stepping up every 4
  DEFB $8D,$08            ; LINE of 9 pixels up, stepping left every 5
  DEFB $80,$8D            ; LINE of 14 pixels right, stepping up every 3
  DEFB $91,$09            ; LINE of 10 pixels up, stepping right every 9
  DEFB $93,$49            ; LINE of 10 pixels down, stepping right every 10
  DEFB $86,$4B            ; LINE of 12 pixels left, stepping down every 2
  DEFB $83,$84            ; LINE of 5 pixels down, stepping right every 3
  DEFB $8A,$24            ; LINE of 37 pixels right, stepping down every 5
  DEFB $83,$C9            ; LINE of 10 pixels down, stepping right every 4
  DEFB $08,$AA,$25        ; MOVE to 170, 37
  DEFB $83,$00            ; LINE of 1 pixel diagonally down and right
  DEFB $08,$A2,$23        ; MOVE to 162, 35
  DEFB $84,$4A            ; LINE of 11 pixels left, stepping up every 2
  DEFB $08,$9B,$08        ; MOVE to 155, 8
  DEFB $85,$84            ; LINE of 5 pixels up, stepping left every 3
  DEFB $08,$7D,$02        ; MOVE to 125, 2
  DEFB $85,$85            ; LINE of 6 pixels up, stepping left every 3
  DEFB $08,$9A,$0C        ; MOVE to 154, 12
  DEFB $84,$49            ; LINE of 10 pixels left, stepping up every 2
  DEFB $8D,$09            ; LINE of 10 pixels up, stepping left every 5
  DEFB $85,$89            ; LINE of 10 pixels up, stepping left every 3
  DEFB $84,$89            ; LINE of 10 pixels left, stepping up every 3
  DEFB $08,$8B,$25        ; MOVE to 139, 37
  DEFB $8D,$C9            ; LINE of 10 pixels up, stepping left every 8
  DEFB $08,$91,$18        ; MOVE to 145, 24
  DEFB $81,$09            ; LINE of 10 pixels diagonally up and right
  DEFB $08,$7D,$08        ; MOVE to 125, 8
  DEFB $80,$49            ; LINE of 10 pixels right, stepping up every 2
  DEFB $80,$09            ; LINE of 10 pixels diagonally right and up
  DEFB $08,$7F,$09        ; MOVE to 127, 9
  DEFB $89,$89            ; LINE of 10 pixels up, stepping right every 7
  DEFB $08,$69,$06        ; MOVE to 105, 6
  DEFB $84,$49            ; LINE of 10 pixels left, stepping up every 2
  DEFB $85,$09            ; LINE of 10 pixels diagonally up and left
  DEFB $8D,$89            ; LINE of 10 pixels up, stepping left every 7
  DEFB $84,$C9            ; LINE of 10 pixels left, stepping up every 4
  DEFB $08,$54,$16        ; MOVE to 84, 22
  DEFB $94,$89            ; LINE of 10 pixels left, stepping up every 11
  DEFB $08,$5F,$16        ; MOVE to 95, 22
  DEFB $81,$89            ; LINE of 10 pixels up, stepping right every 3
  DEFB $80,$89            ; LINE of 10 pixels right, stepping up every 3
  DEFB $81,$89            ; LINE of 10 pixels up, stepping right every 3
  DEFB $80,$C9            ; LINE of 10 pixels right, stepping up every 4
  DEFB $08,$6D,$24        ; MOVE to 109, 36
  DEFB $8A,$09            ; LINE of 10 pixels right, stepping down every 5
  DEFB $08,$5C,$0C        ; MOVE to 92, 12
  DEFB $86,$49            ; LINE of 10 pixels left, stepping down every 2
  DEFB $85,$09            ; LINE of 10 pixels diagonally up and left
  DEFB $8C,$09            ; LINE of 10 pixels left, stepping up every 5
  DEFB $08,$71,$71        ; MOVE to 113, 113
  DEFB $89,$04            ; LINE of 5 pixels up, stepping right every 5
  DEFB $81,$42            ; LINE of 3 pixels up, stepping right every 2
  DEFB $80,$02            ; LINE of 3 pixels diagonally right and up
  DEFB $80,$42            ; LINE of 3 pixels right, stepping up every 2
  DEFB $80,$42            ; LINE of 3 pixels right, stepping up every 2
  DEFB $08,$72,$70        ; MOVE to 114, 112
  DEFB $83,$82            ; LINE of 3 pixels down, stepping right every 3
  DEFB $83,$42            ; LINE of 3 pixels down, stepping right every 2
  DEFB $82,$42            ; LINE of 3 pixels right, stepping down every 2
  DEFB $82,$82            ; LINE of 3 pixels right, stepping down every 3
  DEFB $82,$82            ; LINE of 3 pixels right, stepping down every 3
  DEFB $08,$7C,$7E        ; MOVE to 124, 126
  DEFB $82,$82            ; LINE of 3 pixels right, stepping down every 3
  DEFB $08,$88,$72        ; MOVE to 136, 114
  DEFB $85,$C3            ; LINE of 4 pixels up, stepping left every 4
  DEFB $85,$82            ; LINE of 3 pixels up, stepping left every 3
  DEFB $85,$02            ; LINE of 3 pixels diagonally up and left
  DEFB $84,$42            ; LINE of 3 pixels left, stepping up every 2
  DEFB $84,$42            ; LINE of 3 pixels left, stepping up every 2
  DEFB $08,$88,$71        ; MOVE to 136, 113
  DEFB $87,$42            ; LINE of 3 pixels down, stepping left every 2
  DEFB $87,$42            ; LINE of 3 pixels down, stepping left every 2
  DEFB $86,$42            ; LINE of 3 pixels left, stepping down every 2
  DEFB $86,$82            ; LINE of 3 pixels left, stepping down every 3
  DEFB $86,$83            ; LINE of 4 pixels left, stepping down every 3
  DEFB $46,$7B,$6E        ; FILL with yellow from 123, 110
  DEFB $42,$D9,$29        ; FILL with red from 217, 41
  DEFB $42,$F2,$12        ; FILL with red from 242, 18
  DEFB $40,$A8,$24        ; FILL with black from 168, 36
  DEFB $08,$A8,$24        ; MOVE to 168, 36
  DEFB $86,$42            ; LINE of 3 pixels left, stepping down every 2
  DEFB $40,$A8,$19        ; FILL with black from 168, 25
  DEFB $40,$C0,$0D        ; FILL with black from 192, 13
  DEFB $00                ; End of the picture

; Picture for location 43: smooth straight passage
;
; A border colour and a starting attribute, then 20 moves, 142 lines, 1 fill,
; ending at $00.
LOC43_SMOOTH_STRAIGHT_PASSAGE_PIC:
  DEFB $01                ; Border: blue
  DEFB $20                ; The canvas starts green paper, black ink
  DEFB $08,$70,$37        ; MOVE to 112, 55
  DEFB $81,$82            ; LINE of 3 pixels up, stepping right every 3
  DEFB $81,$42            ; LINE of 3 pixels up, stepping right every 2
  DEFB $81,$02            ; LINE of 3 pixels diagonally up and right
  DEFB $80,$42            ; LINE of 3 pixels right, stepping up every 2
  DEFB $80,$82            ; LINE of 3 pixels right, stepping up every 3
  DEFB $80,$C2            ; LINE of 3 pixels right, stepping up every 4
  DEFB $08,$8B,$37        ; MOVE to 139, 55
  DEFB $85,$82            ; LINE of 3 pixels up, stepping left every 3
  DEFB $85,$42            ; LINE of 3 pixels up, stepping left every 2
  DEFB $85,$02            ; LINE of 3 pixels diagonally up and left
  DEFB $84,$42            ; LINE of 3 pixels left, stepping up every 2
  DEFB $84,$82            ; LINE of 3 pixels left, stepping up every 3
  DEFB $84,$C2            ; LINE of 3 pixels left, stepping up every 4
  DEFB $08,$70,$36        ; MOVE to 112, 54
  DEFB $83,$82            ; LINE of 3 pixels down, stepping right every 3
  DEFB $83,$42            ; LINE of 3 pixels down, stepping right every 2
  DEFB $83,$02            ; LINE of 3 pixels diagonally down and right
  DEFB $82,$42            ; LINE of 3 pixels right, stepping down every 2
  DEFB $82,$82            ; LINE of 3 pixels right, stepping down every 3
  DEFB $82,$C2            ; LINE of 3 pixels right, stepping down every 4
  DEFB $08,$8B,$36        ; MOVE to 139, 54
  DEFB $87,$82            ; LINE of 3 pixels down, stepping left every 3
  DEFB $87,$42            ; LINE of 3 pixels down, stepping left every 2
  DEFB $87,$02            ; LINE of 3 pixels diagonally down and left
  DEFB $86,$42            ; LINE of 3 pixels left, stepping down every 2
  DEFB $86,$82            ; LINE of 3 pixels left, stepping down every 3
  DEFB $86,$C2            ; LINE of 3 pixels left, stepping down every 4
  DEFB $08,$65,$41        ; MOVE to 101, 65
  DEFB $89,$C7            ; LINE of 8 pixels up, stepping right every 8
  DEFB $81,$87            ; LINE of 8 pixels up, stepping right every 3
  DEFB $81,$04            ; LINE of 5 pixels diagonally up and right
  DEFB $80,$44            ; LINE of 5 pixels right, stepping up every 2
  DEFB $80,$84            ; LINE of 5 pixels right, stepping up every 3
  DEFB $80,$84            ; LINE of 5 pixels right, stepping up every 3
  DEFB $80,$C4            ; LINE of 5 pixels right, stepping up every 4
  DEFB $88,$04            ; LINE of 5 pixels right, stepping up every 5
  DEFB $08,$A0,$41        ; MOVE to 160, 65
  DEFB $8D,$C7            ; LINE of 8 pixels up, stepping left every 8
  DEFB $85,$87            ; LINE of 8 pixels up, stepping left every 3
  DEFB $85,$04            ; LINE of 5 pixels diagonally up and left
  DEFB $84,$44            ; LINE of 5 pixels left, stepping up every 2
  DEFB $84,$84            ; LINE of 5 pixels left, stepping up every 3
  DEFB $84,$84            ; LINE of 5 pixels left, stepping up every 3
  DEFB $84,$84            ; LINE of 5 pixels left, stepping up every 3
  DEFB $08,$65,$40        ; MOVE to 101, 64
  DEFB $93,$08            ; LINE of 9 pixels down, stepping right every 9
  DEFB $83,$88            ; LINE of 9 pixels down, stepping right every 3
  DEFB $82,$05            ; LINE of 6 pixels diagonally right and down
  DEFB $82,$43            ; LINE of 4 pixels right, stepping down every 2
  DEFB $08,$A0,$40        ; MOVE to 160, 64
  DEFB $97,$49            ; LINE of 10 pixels down, stepping left every 10
  DEFB $87,$88            ; LINE of 9 pixels down, stepping left every 3
  DEFB $87,$05            ; LINE of 6 pixels diagonally down and left
  DEFB $86,$46            ; LINE of 7 pixels left, stepping down every 2
  DEFB $8E,$4A            ; LINE of 11 pixels left, stepping down every 6
  DEFB $08,$42,$40        ; MOVE to 66, 64
  DEFB $91,$CB            ; LINE of 12 pixels up, stepping right every 12
  DEFB $81,$C9            ; LINE of 10 pixels up, stepping right every 4
  DEFB $81,$49            ; LINE of 10 pixels up, stepping right every 2
  DEFB $80,$09            ; LINE of 10 pixels diagonally right and up
  DEFB $80,$49            ; LINE of 10 pixels right, stepping up every 2
  DEFB $80,$89            ; LINE of 10 pixels right, stepping up every 3
  DEFB $80,$C9            ; LINE of 10 pixels right, stepping up every 4
  DEFB $88,$09            ; LINE of 10 pixels right, stepping up every 5
  DEFB $90,$89            ; LINE of 10 pixels right, stepping up every 11
  DEFB $08,$C3,$3F        ; MOVE to 195, 63
  DEFB $9D,$0C            ; LINE of 13 pixels up, stepping left every 13
  DEFB $85,$CB            ; LINE of 12 pixels up, stepping left every 4
  DEFB $85,$49            ; LINE of 10 pixels up, stepping left every 2
  DEFB $85,$08            ; LINE of 9 pixels diagonally up and left
  DEFB $84,$48            ; LINE of 9 pixels left, stepping up every 2
  DEFB $84,$88            ; LINE of 9 pixels left, stepping up every 3
  DEFB $84,$C8            ; LINE of 9 pixels left, stepping up every 4
  DEFB $8C,$08            ; LINE of 9 pixels left, stepping up every 5
  DEFB $8C,$08            ; LINE of 9 pixels left, stepping up every 5
  DEFB $08,$42,$3F        ; MOVE to 66, 63
  DEFB $93,$08            ; LINE of 9 pixels down, stepping right every 9
  DEFB $83,$C8            ; LINE of 9 pixels down, stepping right every 4
  DEFB $83,$48            ; LINE of 9 pixels down, stepping right every 2
  DEFB $83,$08            ; LINE of 9 pixels diagonally down and right
  DEFB $82,$43            ; LINE of 4 pixels right, stepping down every 2
  DEFB $08,$C3,$3E        ; MOVE to 195, 62
  DEFB $97,$08            ; LINE of 9 pixels down, stepping left every 9
  DEFB $87,$88            ; LINE of 9 pixels down, stepping left every 3
  DEFB $87,$48            ; LINE of 9 pixels down, stepping left every 2
  DEFB $87,$08            ; LINE of 9 pixels diagonally down and left
  DEFB $86,$48            ; LINE of 9 pixels left, stepping down every 2
  DEFB $86,$88            ; LINE of 9 pixels left, stepping down every 3
  DEFB $86,$C5            ; LINE of 6 pixels left, stepping down every 4
  DEFB $08,$13,$41        ; MOVE to 19, 65
  DEFB $95,$48            ; LINE of 9 pixels up, stepping left every 10
  DEFB $81,$C8            ; LINE of 9 pixels up, stepping right every 4
  DEFB $81,$48            ; LINE of 9 pixels up, stepping right every 2
  DEFB $81,$48            ; LINE of 9 pixels up, stepping right every 2
  DEFB $81,$08            ; LINE of 9 pixels diagonally up and right
  DEFB $80,$48            ; LINE of 9 pixels right, stepping up every 2
  DEFB $80,$48            ; LINE of 9 pixels right, stepping up every 2
  DEFB $80,$88            ; LINE of 9 pixels right, stepping up every 3
  DEFB $80,$C8            ; LINE of 9 pixels right, stepping up every 4
  DEFB $80,$C8            ; LINE of 9 pixels right, stepping up every 4
  DEFB $88,$08            ; LINE of 9 pixels right, stepping up every 5
  DEFB $88,$08            ; LINE of 9 pixels right, stepping up every 5
  DEFB $08,$F0,$41        ; MOVE to 240, 65
  DEFB $95,$48            ; LINE of 9 pixels up, stepping left every 10
  DEFB $85,$C8            ; LINE of 9 pixels up, stepping left every 4
  DEFB $85,$48            ; LINE of 9 pixels up, stepping left every 2
  DEFB $85,$48            ; LINE of 9 pixels up, stepping left every 2
  DEFB $85,$08            ; LINE of 9 pixels diagonally up and left
  DEFB $84,$48            ; LINE of 9 pixels left, stepping up every 2
  DEFB $84,$48            ; LINE of 9 pixels left, stepping up every 2
  DEFB $84,$88            ; LINE of 9 pixels left, stepping up every 3
  DEFB $84,$C8            ; LINE of 9 pixels left, stepping up every 4
  DEFB $8C,$08            ; LINE of 9 pixels left, stepping up every 5
  DEFB $8C,$48            ; LINE of 9 pixels left, stepping up every 6
  DEFB $8C,$48            ; LINE of 9 pixels left, stepping up every 6
  DEFB $8C,$48            ; LINE of 9 pixels left, stepping up every 6
  DEFB $08,$13,$40        ; MOVE to 19, 64
  DEFB $8B,$C8            ; LINE of 9 pixels down, stepping right every 8
  DEFB $8B,$08            ; LINE of 9 pixels down, stepping right every 5
  DEFB $83,$88            ; LINE of 9 pixels down, stepping right every 3
  DEFB $83,$48            ; LINE of 9 pixels down, stepping right every 2
  DEFB $83,$10            ; LINE of 17 pixels diagonally down and right
  DEFB $08,$F0,$40        ; MOVE to 240, 64
  DEFB $8F,$48            ; LINE of 9 pixels down, stepping left every 6
  DEFB $8F,$08            ; LINE of 9 pixels down, stepping left every 5
  DEFB $87,$88            ; LINE of 9 pixels down, stepping left every 3
  DEFB $87,$48            ; LINE of 9 pixels down, stepping left every 2
  DEFB $87,$08            ; LINE of 9 pixels diagonally down and left
  DEFB $86,$48            ; LINE of 9 pixels left, stepping down every 2
  DEFB $86,$48            ; LINE of 9 pixels left, stepping down every 2
  DEFB $86,$88            ; LINE of 9 pixels left, stepping down every 3
  DEFB $86,$88            ; LINE of 9 pixels left, stepping down every 3
  DEFB $8E,$04            ; LINE of 5 pixels left, stepping down every 5
  DEFB $08,$71,$37        ; MOVE to 113, 55
  DEFB $81,$02            ; LINE of 3 pixels diagonally up and right
  DEFB $80,$42            ; LINE of 3 pixels right, stepping up every 2
  DEFB $80,$82            ; LINE of 3 pixels right, stepping up every 3
  DEFB $82,$42            ; LINE of 3 pixels right, stepping down every 2
  DEFB $82,$02            ; LINE of 3 pixels diagonally right and down
  DEFB $83,$42            ; LINE of 3 pixels down, stepping right every 2
  DEFB $83,$82            ; LINE of 3 pixels down, stepping right every 3
  DEFB $87,$42            ; LINE of 3 pixels down, stepping left every 2
  DEFB $87,$02            ; LINE of 3 pixels diagonally down and left
  DEFB $08,$07,$00        ; MOVE to 7, 0
  DEFB $80,$BE            ; LINE of 63 pixels right, stepping up every 3
  DEFB $80,$90            ; LINE of 17 pixels right, stepping up every 3
  DEFB $80,$5B            ; LINE of 28 pixels right, stepping up every 2
  DEFB $81,$03            ; LINE of 4 pixels diagonally up and right
  DEFB $08,$C1,$00        ; MOVE to 193, 0
  DEFB $84,$64            ; LINE of 37 pixels left, stepping up every 2
  DEFB $84,$4D            ; LINE of 14 pixels left, stepping up every 2
  DEFB $84,$09            ; LINE of 10 pixels diagonally left and up
  DEFB $85,$07            ; LINE of 8 pixels diagonally up and left
  DEFB $08,$72,$31        ; MOVE to 114, 49
  DEFB $81,$43            ; LINE of 4 pixels up, stepping right every 2
  DEFB $80,$41            ; LINE of 2 pixels right, stepping up every 2
  DEFB $82,$41            ; LINE of 2 pixels right, stepping down every 2
  DEFB $83,$01            ; LINE of 2 pixels diagonally down and right
  DEFB $87,$81            ; LINE of 2 pixels down, stepping left every 3
  DEFB $83,$81            ; LINE of 2 pixels down, stepping right every 3
  DEFB $87,$02            ; LINE of 3 pixels diagonally down and left
  DEFB $40,$74,$33        ; FILL with black from 116, 51
  DEFB $00                ; End of the picture

; Picture for location 38: dale valley
;
; A border colour and a starting attribute, then 63 moves, 150 lines, 6 fills,
; 2 paints, ending at $00.
LOC38_DALE_VALLEY_PIC:
  DEFB $05                ; Border: cyan
  DEFB $28                ; The canvas starts cyan paper, black ink
  DEFB $08,$FF,$0E        ; MOVE to 255, 14
  DEFB $84,$D2            ; LINE of 19 pixels left, stepping up every 4
  DEFB $8C,$0E            ; LINE of 15 pixels left, stepping up every 5
  DEFB $8C,$0E            ; LINE of 15 pixels left, stepping up every 5
  DEFB $8C,$4E            ; LINE of 15 pixels left, stepping up every 6
  DEFB $8C,$4C            ; LINE of 13 pixels left, stepping up every 6
  DEFB $8D,$60            ; LINE of 33 pixels up, stepping left every 6
  DEFB $8C,$46            ; LINE of 7 pixels left, stepping up every 6
  DEFB $87,$C7            ; LINE of 8 pixels down, stepping left every 4
  DEFB $85,$02            ; LINE of 3 pixels diagonally up and left
  DEFB $8E,$09            ; LINE of 10 pixels left, stepping down every 5
  DEFB $86,$88            ; LINE of 9 pixels left, stepping down every 3
  DEFB $8F,$90            ; LINE of 17 pixels down, stepping left every 7
  DEFB $84,$CA            ; LINE of 11 pixels left, stepping up every 4
  DEFB $95,$5D            ; LINE of 30 pixels up, stepping left every 10
  DEFB $86,$83            ; LINE of 4 pixels left, stepping down every 3
  DEFB $87,$D2            ; LINE of 19 pixels down, stepping left every 4
  DEFB $94,$98            ; LINE of 25 pixels left, stepping up every 11
  DEFB $87,$C3            ; LINE of 4 pixels down, stepping left every 4
  DEFB $84,$8A            ; LINE of 11 pixels left, stepping up every 3
  DEFB $91,$89            ; LINE of 10 pixels up, stepping right every 11
  DEFB $8C,$85            ; LINE of 6 pixels left, stepping up every 7
  DEFB $9B,$0C            ; LINE of 13 pixels down, stepping right every 13
  DEFB $8B,$C7            ; LINE of 8 pixels down, stepping right every 8
  DEFB $08,$4C,$26        ; MOVE to 76, 38
  DEFB $BC,$9E            ; LINE of 31 pixels left, stepping up every 31
  DEFB $9D,$19            ; LINE of 26 pixels up, stepping left every 13
  DEFB $84,$83            ; LINE of 4 pixels left, stepping up every 3
  DEFB $A1,$92            ; LINE of 19 pixels up, stepping right every 19
  DEFB $08,$27,$55        ; MOVE to 39, 85
  DEFB $86,$45            ; LINE of 6 pixels left, stepping down every 2
  DEFB $97,$5A            ; LINE of 27 pixels down, stepping left every 10
  DEFB $8E,$1A            ; LINE of 27 pixels left, stepping down every 5
  DEFB $87,$5A            ; LINE of 27 pixels down, stepping left every 2
  DEFB $08,$00,$13        ; MOVE to 0, 19
  DEFB $88,$1A            ; LINE of 27 pixels right, stepping up every 5
  DEFB $88,$4C            ; LINE of 13 pixels right, stepping up every 6
  DEFB $86,$4C            ; LINE of 13 pixels left, stepping down every 2
  DEFB $86,$8C            ; LINE of 13 pixels left, stepping down every 3
  DEFB $86,$8C            ; LINE of 13 pixels left, stepping down every 3
  DEFB $08,$01,$0B        ; MOVE to 1, 11
  DEFB $80,$8C            ; LINE of 13 pixels right, stepping up every 3
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $80,$EF            ; LINE of 48 pixels right, stepping up every 4
  DEFB $82,$89            ; LINE of 10 pixels right, stepping down every 3
  DEFB $90,$15            ; LINE of 22 pixels right, stepping up every 9
  DEFB $88,$C7            ; LINE of 8 pixels right, stepping up every 8
  DEFB $81,$87            ; LINE of 8 pixels up, stepping right every 3
  DEFB $8B,$93            ; LINE of 20 pixels down, stepping right every 7
  DEFB $8B,$93            ; LINE of 20 pixels down, stepping right every 7
  DEFB $08,$71,$09        ; MOVE to 113, 9
  DEFB $8A,$13            ; LINE of 20 pixels right, stepping down every 5
  DEFB $92,$53            ; LINE of 20 pixels right, stepping down every 10
  DEFB $98,$13            ; LINE of 20 pixels right, stepping up every 13
  DEFB $88,$13            ; LINE of 20 pixels right, stepping up every 5
  DEFB $82,$93            ; LINE of 20 pixels right, stepping down every 3
  DEFB $92,$53            ; LINE of 20 pixels right, stepping down every 10
  DEFB $92,$53            ; LINE of 20 pixels right, stepping down every 10
  DEFB $08,$72,$09        ; MOVE to 114, 9
  DEFB $80,$D3            ; LINE of 20 pixels right, stepping up every 4
  DEFB $80,$D3            ; LINE of 20 pixels right, stepping up every 4
  DEFB $88,$53            ; LINE of 20 pixels right, stepping up every 6
  DEFB $A2,$53            ; LINE of 20 pixels right, stepping down every 18
  DEFB $8A,$93            ; LINE of 20 pixels right, stepping down every 7
  DEFB $8A,$13            ; LINE of 20 pixels right, stepping down every 5
  DEFB $8A,$13            ; LINE of 20 pixels right, stepping down every 5
  DEFB $8A,$13            ; LINE of 20 pixels right, stepping down every 5
  DEFB $40,$A0,$21        ; FILL with black from 160, 33
  DEFB $21,$59,$D7,$02,$23,$00,$41,$02 ; PAINT blue ink from row 14, column 23,
  DEFB $1B,$04,$1B,$2D,$FF             ; along a path of 9 steps
  DEFB $08,$67,$15        ; MOVE to 103, 21
  DEFB $8F,$CE            ; LINE of 15 pixels down, stepping left every 8
  DEFB $8A,$4E            ; LINE of 15 pixels right, stepping down every 6
  DEFB $08,$5A,$14        ; MOVE to 90, 20
  DEFB $86,$56            ; LINE of 23 pixels left, stepping down every 2
  DEFB $95,$8D            ; LINE of 14 pixels up, stepping left every 11
  DEFB $9F,$4D            ; LINE of 14 pixels down, stepping left every 14
  DEFB $08,$41,$11        ; MOVE to 65, 17
  DEFB $8E,$0D            ; LINE of 14 pixels left, stepping down every 5
  DEFB $86,$CD            ; LINE of 14 pixels left, stepping down every 4
  DEFB $86,$8D            ; LINE of 14 pixels left, stepping down every 3
  DEFB $86,$8D            ; LINE of 14 pixels left, stepping down every 3
  DEFB $86,$8D            ; LINE of 14 pixels left, stepping down every 3
  DEFB $08,$29,$04        ; MOVE to 41, 4
  DEFB $86,$8D            ; LINE of 14 pixels left, stepping down every 3
  DEFB $08,$3A,$00        ; MOVE to 58, 0
  DEFB $84,$D1            ; LINE of 18 pixels left, stepping up every 4
  DEFB $40,$3C,$04        ; FILL with black from 60, 4
  DEFB $21,$59,$A0,$31,$00,$27,$06,$0F ; PAINT blue ink from row 13, column 0,
  DEFB $35,$02,$37,$FF                 ; along a path of 8 steps
  DEFB $08,$DF,$5D        ; MOVE to 223, 93
  DEFB $84,$03            ; LINE of 4 pixels diagonally left and up
  DEFB $86,$44            ; LINE of 5 pixels left, stepping down every 2
  DEFB $88,$05            ; LINE of 6 pixels right, stepping up every 5
  DEFB $08,$DB,$60        ; MOVE to 219, 96
  DEFB $82,$03            ; LINE of 4 pixels diagonally right and down
  DEFB $80,$45            ; LINE of 6 pixels right, stepping up every 2
  DEFB $83,$03            ; LINE of 4 pixels diagonally down and right
  DEFB $08,$E8,$5B        ; MOVE to 232, 91
  DEFB $84,$03            ; LINE of 4 pixels diagonally left and up
  DEFB $08,$C1,$66        ; MOVE to 193, 102
  DEFB $84,$03            ; LINE of 4 pixels diagonally left and up
  DEFB $80,$83            ; LINE of 4 pixels right, stepping up every 3
  DEFB $80,$C3            ; LINE of 4 pixels right, stepping up every 4
  DEFB $08,$C4,$6B        ; MOVE to 196, 107
  DEFB $82,$47            ; LINE of 8 pixels right, stepping down every 2
  DEFB $83,$05            ; LINE of 6 pixels diagonally down and right
  DEFB $83,$85            ; LINE of 6 pixels down, stepping right every 3
  DEFB $8B,$85            ; LINE of 6 pixels down, stepping right every 7
  DEFB $87,$C5            ; LINE of 6 pixels down, stepping left every 4
  DEFB $87,$05            ; LINE of 6 pixels diagonally down and left
  DEFB $86,$45            ; LINE of 6 pixels left, stepping down every 2
  DEFB $86,$85            ; LINE of 6 pixels left, stepping down every 3
  DEFB $08,$C1,$45        ; MOVE to 193, 69
  DEFB $81,$05            ; LINE of 6 pixels diagonally up and right
  DEFB $81,$45            ; LINE of 6 pixels up, stepping right every 2
  DEFB $89,$45            ; LINE of 6 pixels up, stepping right every 6
  DEFB $08,$CA,$57        ; MOVE to 202, 87
  DEFB $85,$85            ; LINE of 6 pixels up, stepping left every 3
  DEFB $85,$45            ; LINE of 6 pixels up, stepping left every 2
  DEFB $85,$03            ; LINE of 4 pixels diagonally up and left
  DEFB $46,$C5,$67        ; FILL with yellow from 197, 103
  DEFB $08,$C0,$1B        ; MOVE to 192, 27
  DEFB $85,$0F            ; LINE of 16 pixels diagonally up and left
  DEFB $08,$C1,$1B        ; MOVE to 193, 27
  DEFB $85,$10            ; LINE of 17 pixels diagonally up and left
  DEFB $08,$C3,$1A        ; MOVE to 195, 26
  DEFB $85,$13            ; LINE of 20 pixels diagonally up and left
  DEFB $08,$94,$37        ; MOVE to 148, 55
  DEFB $AD,$13            ; LINE of 20 pixels up, stepping left every 21
  DEFB $08,$8B,$23        ; MOVE to 139, 35
  DEFB $84,$09            ; LINE of 10 pixels diagonally left and up
  DEFB $08,$8B,$24        ; MOVE to 139, 36
  DEFB $84,$09            ; LINE of 10 pixels diagonally left and up
  DEFB $08,$8F,$0E        ; MOVE to 143, 14
  DEFB $90,$BE            ; LINE of 63 pixels right, stepping up every 11
  DEFB $08,$46,$26        ; MOVE to 70, 38
  DEFB $B5,$18            ; LINE of 25 pixels up, stepping left every 25
  DEFB $84,$83            ; LINE of 4 pixels left, stepping up every 3
  DEFB $8F,$D1            ; LINE of 18 pixels down, stepping left every 8
  DEFB $85,$4C            ; LINE of 13 pixels up, stepping left every 2
  DEFB $08,$39,$3A        ; MOVE to 57, 58
  DEFB $86,$02            ; LINE of 3 pixels diagonally left and down
  DEFB $83,$90            ; LINE of 17 pixels down, stepping right every 3
  DEFB $40,$3F,$2A        ; FILL with black from 63, 42
  DEFB $08,$2D,$31        ; MOVE to 45, 49
  DEFB $9A,$DF            ; LINE of 32 pixels right, stepping down every 16
  DEFB $08,$31,$27        ; MOVE to 49, 39
  DEFB $89,$C7            ; LINE of 8 pixels up, stepping right every 8
  DEFB $08,$31,$2F        ; MOVE to 49, 47
  DEFB $80,$C3            ; LINE of 4 pixels right, stepping up every 4
  DEFB $08,$35,$2F        ; MOVE to 53, 47
  DEFB $83,$C8            ; LINE of 9 pixels down, stepping right every 4
  DEFB $40,$33,$2C        ; FILL with black from 51, 44
  DEFB $08,$34,$2F        ; MOVE to 52, 47
  DEFB $A1,$55            ; LINE of 22 pixels up, stepping right every 18
  DEFB $82,$55            ; LINE of 22 pixels right, stepping down every 2
  DEFB $08,$35,$44        ; MOVE to 53, 68
  DEFB $82,$55            ; LINE of 22 pixels right, stepping down every 2
  DEFB $08,$35,$44        ; MOVE to 53, 68
  DEFB $AB,$15            ; LINE of 22 pixels down, stepping right every 21
  DEFB $08,$53,$3A        ; MOVE to 83, 58
  DEFB $83,$0A            ; LINE of 11 pixels diagonally down and right
  DEFB $08,$53,$3B        ; MOVE to 83, 59
  DEFB $83,$0A            ; LINE of 11 pixels diagonally down and right
  DEFB $08,$53,$3B        ; MOVE to 83, 59
  DEFB $80,$13            ; LINE of 20 pixels diagonally right and up
  DEFB $08,$54,$3B        ; MOVE to 84, 59
  DEFB $80,$13            ; LINE of 20 pixels diagonally right and up
  DEFB $08,$67,$4E        ; MOVE to 103, 78
  DEFB $82,$55            ; LINE of 22 pixels right, stepping down every 2
  DEFB $08,$67,$4D        ; MOVE to 103, 77
  DEFB $82,$55            ; LINE of 22 pixels right, stepping down every 2
  DEFB $08,$67,$4D        ; MOVE to 103, 77
  DEFB $8B,$95            ; LINE of 22 pixels down, stepping right every 7
  DEFB $08,$68,$42        ; MOVE to 104, 66
  DEFB $82,$50            ; LINE of 17 pixels right, stepping down every 2
  DEFB $08,$68,$41        ; MOVE to 104, 65
  DEFB $82,$50            ; LINE of 17 pixels right, stepping down every 2
  DEFB $08,$6A,$39        ; MOVE to 106, 57
  DEFB $82,$4D            ; LINE of 14 pixels right, stepping down every 2
  DEFB $08,$6A,$38        ; MOVE to 106, 56
  DEFB $82,$4D            ; LINE of 14 pixels right, stepping down every 2
  DEFB $08,$69,$39        ; MOVE to 105, 57
  DEFB $86,$4D            ; LINE of 14 pixels left, stepping down every 2
  DEFB $08,$69,$38        ; MOVE to 105, 56
  DEFB $86,$4D            ; LINE of 14 pixels left, stepping down every 2
  DEFB $08,$68,$41        ; MOVE to 104, 65
  DEFB $86,$52            ; LINE of 19 pixels left, stepping down every 2
  DEFB $08,$68,$40        ; MOVE to 104, 64
  DEFB $86,$52            ; LINE of 19 pixels left, stepping down every 2
  DEFB $08,$57,$3A        ; MOVE to 87, 58
  DEFB $8F,$CB            ; LINE of 12 pixels down, stepping left every 8
  DEFB $08,$58,$3A        ; MOVE to 88, 58
  DEFB $8F,$CB            ; LINE of 12 pixels down, stepping left every 8
  DEFB $08,$52,$3A        ; MOVE to 82, 58
  DEFB $8F,$CB            ; LINE of 12 pixels down, stepping left every 8
  DEFB $08,$1F,$4F        ; MOVE to 31, 79
  DEFB $81,$59            ; LINE of 26 pixels up, stepping right every 2
  DEFB $08,$1E,$4F        ; MOVE to 30, 79
  DEFB $81,$59            ; LINE of 26 pixels up, stepping right every 2
  DEFB $08,$1E,$4F        ; MOVE to 30, 79
  DEFB $81,$59            ; LINE of 26 pixels up, stepping right every 2
  DEFB $83,$57            ; LINE of 24 pixels down, stepping right every 2
  DEFB $84,$C8            ; LINE of 9 pixels left, stepping up every 4
  DEFB $8E,$08            ; LINE of 9 pixels left, stepping down every 5
  DEFB $08,$2D,$53        ; MOVE to 45, 83
  DEFB $8D,$D3            ; LINE of 20 pixels up, stepping left every 8
  DEFB $08,$2C,$53        ; MOVE to 44, 83
  DEFB $8D,$D3            ; LINE of 20 pixels up, stepping left every 8
  DEFB $08,$2F,$26        ; MOVE to 47, 38
  DEFB $99,$2C            ; LINE of 45 pixels up, stepping right every 13
  DEFB $08,$30,$26        ; MOVE to 48, 38
  DEFB $99,$2C            ; LINE of 45 pixels up, stepping right every 13
  DEFB $08,$27,$45        ; MOVE to 39, 69
  DEFB $81,$4E            ; LINE of 15 pixels up, stepping right every 2
  DEFB $08,$28,$45        ; MOVE to 40, 69
  DEFB $81,$4E            ; LINE of 15 pixels up, stepping right every 2
  DEFB $08,$D4,$15        ; MOVE to 212, 21
  DEFB $80,$4E            ; LINE of 15 pixels right, stepping up every 2
  DEFB $80,$0E            ; LINE of 15 pixels diagonally right and up
  DEFB $82,$4E            ; LINE of 15 pixels right, stepping down every 2
  DEFB $40,$FF,$1D        ; FILL with black from 255, 29
  DEFB $00                ; End of the picture

; Picture for location 7: trolls cave
;
; A border colour and a starting attribute, then 50 moves, 192 lines, 26 fills,
; 3 paints, ending at $00.
LOC7_TROLLS_CAVE_PIC:
  DEFB $07                ; Border: white
  DEFB $38                ; The canvas starts white paper, black ink
  DEFB $08,$34,$00        ; MOVE to 52, 0
  DEFB $8D,$7E            ; LINE of 63 pixels up, stepping left every 6
  DEFB $B0,$DB            ; LINE of 28 pixels right, stepping up every 28
  DEFB $8C,$9D            ; LINE of 30 pixels left, stepping up every 7
  DEFB $85,$D5            ; LINE of 22 pixels up, stepping left every 4
  DEFB $08,$22,$5A        ; MOVE to 34, 90
  DEFB $AB,$D6            ; LINE of 23 pixels down, stepping right every 24
  DEFB $8C,$0E            ; LINE of 15 pixels left, stepping up every 5
  DEFB $8C,$C6            ; LINE of 7 pixels left, stepping up every 8
  DEFB $8E,$46            ; LINE of 7 pixels left, stepping down every 6
  DEFB $8B,$06            ; LINE of 7 pixels down, stepping right every 5
  DEFB $83,$46            ; LINE of 7 pixels down, stepping right every 2
  DEFB $83,$06            ; LINE of 7 pixels diagonally down and right
  DEFB $80,$46            ; LINE of 7 pixels right, stepping up every 2
  DEFB $80,$46            ; LINE of 7 pixels right, stepping up every 2
  DEFB $89,$04            ; LINE of 5 pixels up, stepping right every 5
  DEFB $80,$C5            ; LINE of 6 pixels right, stepping up every 4
  DEFB $8B,$7E            ; LINE of 63 pixels down, stepping right every 6
  DEFB $08,$0C,$45        ; MOVE to 12, 69
  DEFB $83,$48            ; LINE of 9 pixels down, stepping right every 2
  DEFB $82,$45            ; LINE of 6 pixels right, stepping down every 2
  DEFB $82,$05            ; LINE of 6 pixels diagonally right and down
  DEFB $08,$18,$34        ; MOVE to 24, 52
  DEFB $8C,$0D            ; LINE of 14 pixels left, stepping up every 5
  DEFB $42,$0C,$3A        ; FILL with red from 12, 58
  DEFB $08,$27,$33        ; MOVE to 39, 51
  DEFB $88,$04            ; LINE of 5 pixels right, stepping up every 5
  DEFB $40,$2A,$2E        ; FILL with black from 42, 46
  DEFB $08,$D1,$07        ; MOVE to 209, 7
  DEFB $8C,$9F            ; LINE of 32 pixels left, stepping up every 7
  DEFB $87,$83            ; LINE of 4 pixels down, stepping left every 3
  DEFB $84,$03            ; LINE of 4 pixels diagonally left and up
  DEFB $81,$02            ; LINE of 3 pixels diagonally up and right
  DEFB $85,$02            ; LINE of 3 pixels diagonally up and left
  DEFB $80,$42            ; LINE of 3 pixels right, stepping up every 2
  DEFB $82,$44            ; LINE of 5 pixels right, stepping down every 2
  DEFB $8A,$57            ; LINE of 24 pixels right, stepping down every 6
  DEFB $83,$02            ; LINE of 3 pixels diagonally down and right
  DEFB $80,$42            ; LINE of 3 pixels right, stepping up every 2
  DEFB $81,$42            ; LINE of 3 pixels up, stepping right every 2
  DEFB $80,$42            ; LINE of 3 pixels right, stepping up every 2
  DEFB $80,$C2            ; LINE of 3 pixels right, stepping up every 4
  DEFB $83,$42            ; LINE of 3 pixels down, stepping right every 2
  DEFB $83,$82            ; LINE of 3 pixels down, stepping right every 3
  DEFB $87,$42            ; LINE of 3 pixels down, stepping left every 2
  DEFB $86,$42            ; LINE of 3 pixels left, stepping down every 2
  DEFB $86,$82            ; LINE of 3 pixels left, stepping down every 3
  DEFB $85,$03            ; LINE of 4 pixels diagonally up and left
  DEFB $08,$CA,$0D        ; MOVE to 202, 13
  DEFB $84,$47            ; LINE of 8 pixels left, stepping up every 2
  DEFB $8C,$45            ; LINE of 6 pixels left, stepping up every 6
  DEFB $85,$86            ; LINE of 7 pixels up, stepping left every 3
  DEFB $82,$83            ; LINE of 4 pixels right, stepping down every 3
  DEFB $08,$BD,$19        ; MOVE to 189, 25
  DEFB $81,$45            ; LINE of 6 pixels up, stepping right every 2
  DEFB $80,$45            ; LINE of 6 pixels right, stepping up every 2
  DEFB $82,$C5            ; LINE of 6 pixels right, stepping down every 4
  DEFB $82,$03            ; LINE of 4 pixels diagonally right and down
  DEFB $87,$43            ; LINE of 4 pixels down, stepping left every 2
  DEFB $83,$83            ; LINE of 4 pixels down, stepping right every 3
  DEFB $83,$03            ; LINE of 4 pixels diagonally down and right
  DEFB $83,$83            ; LINE of 4 pixels down, stepping right every 3
  DEFB $08,$CD,$18        ; MOVE to 205, 24
  DEFB $84,$02            ; LINE of 3 pixels diagonally left and up
  DEFB $08,$CA,$1A        ; MOVE to 202, 26
  DEFB $87,$82            ; LINE of 3 pixels down, stepping left every 3
  DEFB $08,$CA,$17        ; MOVE to 202, 23
  DEFB $82,$82            ; LINE of 3 pixels right, stepping down every 3
  DEFB $40,$CB,$18        ; FILL with black from 203, 24
  DEFB $08,$C3,$15        ; MOVE to 195, 21
  DEFB $83,$82            ; LINE of 3 pixels down, stepping right every 3
  DEFB $80,$42            ; LINE of 3 pixels right, stepping up every 2
  DEFB $85,$42            ; LINE of 3 pixels up, stepping left every 2
  DEFB $86,$82            ; LINE of 3 pixels left, stepping down every 3
  DEFB $40,$C5,$14        ; FILL with black from 197, 20
  DEFB $08,$BB,$14        ; MOVE to 187, 20
  DEFB $84,$92            ; LINE of 19 pixels left, stepping up every 3
  DEFB $86,$82            ; LINE of 3 pixels left, stepping down every 3
  DEFB $85,$42            ; LINE of 3 pixels up, stepping left every 2
  DEFB $85,$C2            ; LINE of 3 pixels up, stepping left every 4
  DEFB $81,$02            ; LINE of 3 pixels diagonally up and right
  DEFB $85,$42            ; LINE of 3 pixels up, stepping left every 2
  DEFB $80,$82            ; LINE of 3 pixels right, stepping up every 3
  DEFB $82,$02            ; LINE of 3 pixels diagonally right and down
  DEFB $83,$82            ; LINE of 3 pixels down, stepping right every 3
  DEFB $83,$C2            ; LINE of 3 pixels down, stepping right every 4
  DEFB $82,$8C            ; LINE of 13 pixels right, stepping down every 3
  DEFB $08,$FF,$2C        ; MOVE to 255, 44
  DEFB $8C,$0A            ; LINE of 11 pixels left, stepping up every 5
  DEFB $84,$0A            ; LINE of 11 pixels diagonally left and up
  DEFB $8C,$8A            ; LINE of 11 pixels left, stepping up every 7
  DEFB $94,$0A            ; LINE of 11 pixels left, stepping up every 9
  DEFB $96,$8A            ; LINE of 11 pixels left, stepping down every 11
  DEFB $84,$4A            ; LINE of 11 pixels left, stepping up every 2
  DEFB $85,$8A            ; LINE of 11 pixels up, stepping left every 3
  DEFB $8C,$4A            ; LINE of 11 pixels left, stepping up every 6
  DEFB $84,$8D            ; LINE of 14 pixels left, stepping up every 3
  DEFB $84,$CA            ; LINE of 11 pixels left, stepping up every 4
  DEFB $94,$0A            ; LINE of 11 pixels left, stepping up every 9
  DEFB $96,$8A            ; LINE of 11 pixels left, stepping down every 11
  DEFB $84,$CA            ; LINE of 11 pixels left, stepping up every 4
  DEFB $96,$8A            ; LINE of 11 pixels left, stepping down every 11
  DEFB $84,$47            ; LINE of 8 pixels left, stepping up every 2
  DEFB $8C,$CA            ; LINE of 11 pixels left, stepping up every 8
  DEFB $87,$04            ; LINE of 5 pixels diagonally down and left
  DEFB $8E,$4A            ; LINE of 11 pixels left, stepping down every 6
  DEFB $8E,$CA            ; LINE of 11 pixels left, stepping down every 8
  DEFB $8E,$CA            ; LINE of 11 pixels left, stepping down every 8
  DEFB $8C,$8B            ; LINE of 12 pixels left, stepping up every 7
  DEFB $08,$21,$52        ; MOVE to 33, 82
  DEFB $8C,$0F            ; LINE of 16 pixels left, stepping up every 5
  DEFB $86,$52            ; LINE of 19 pixels left, stepping down every 2
  DEFB $08,$5D,$21        ; MOVE to 93, 33
  DEFB $84,$44            ; LINE of 5 pixels left, stepping up every 2
  DEFB $84,$04            ; LINE of 5 pixels diagonally left and up
  DEFB $85,$44            ; LINE of 5 pixels up, stepping left every 2
  DEFB $8D,$44            ; LINE of 5 pixels up, stepping left every 6
  DEFB $81,$44            ; LINE of 5 pixels up, stepping right every 2
  DEFB $81,$04            ; LINE of 5 pixels diagonally up and right
  DEFB $82,$44            ; LINE of 5 pixels right, stepping down every 2
  DEFB $82,$84            ; LINE of 5 pixels right, stepping down every 3
  DEFB $8A,$04            ; LINE of 5 pixels right, stepping down every 5
  DEFB $88,$04            ; LINE of 5 pixels right, stepping up every 5
  DEFB $08,$67,$38        ; MOVE to 103, 56
  DEFB $80,$C4            ; LINE of 5 pixels right, stepping up every 4
  DEFB $80,$C4            ; LINE of 5 pixels right, stepping up every 4
  DEFB $80,$C4            ; LINE of 5 pixels right, stepping up every 4
  DEFB $80,$44            ; LINE of 5 pixels right, stepping up every 2
  DEFB $82,$44            ; LINE of 5 pixels right, stepping down every 2
  DEFB $83,$44            ; LINE of 5 pixels down, stepping right every 2
  DEFB $8F,$04            ; LINE of 5 pixels down, stepping left every 5
  DEFB $87,$C4            ; LINE of 5 pixels down, stepping left every 4
  DEFB $87,$84            ; LINE of 5 pixels down, stepping left every 3
  DEFB $87,$04            ; LINE of 5 pixels diagonally down and left
  DEFB $86,$84            ; LINE of 5 pixels left, stepping down every 3
  DEFB $8E,$04            ; LINE of 5 pixels left, stepping down every 5
  DEFB $8E,$04            ; LINE of 5 pixels left, stepping down every 5
  DEFB $8E,$44            ; LINE of 5 pixels left, stepping down every 6
  DEFB $8C,$04            ; LINE of 5 pixels left, stepping up every 5
  DEFB $84,$C4            ; LINE of 5 pixels left, stepping up every 4
  DEFB $08,$59,$3D        ; MOVE to 89, 61
  DEFB $80,$44            ; LINE of 5 pixels right, stepping up every 2
  DEFB $88,$04            ; LINE of 5 pixels right, stepping up every 5
  DEFB $88,$04            ; LINE of 5 pixels right, stepping up every 5
  DEFB $88,$44            ; LINE of 5 pixels right, stepping up every 6
  DEFB $82,$C4            ; LINE of 5 pixels right, stepping down every 4
  DEFB $82,$C4            ; LINE of 5 pixels right, stepping down every 4
  DEFB $82,$84            ; LINE of 5 pixels right, stepping down every 3
  DEFB $08,$53,$28        ; MOVE to 83, 40
  DEFB $84,$84            ; LINE of 5 pixels left, stepping up every 3
  DEFB $84,$44            ; LINE of 5 pixels left, stepping up every 2
  DEFB $87,$03            ; LINE of 4 pixels diagonally down and left
  DEFB $8A,$50            ; LINE of 17 pixels right, stepping down every 6
  DEFB $86,$4A            ; LINE of 11 pixels left, stepping down every 2
  DEFB $8B,$04            ; LINE of 5 pixels down, stepping right every 5
  DEFB $80,$42            ; LINE of 3 pixels right, stepping up every 2
  DEFB $85,$82            ; LINE of 3 pixels up, stepping left every 3
  DEFB $84,$C2            ; LINE of 3 pixels left, stepping up every 4
  DEFB $08,$4F,$1D        ; MOVE to 79, 29
  DEFB $80,$4A            ; LINE of 11 pixels right, stepping up every 2
  DEFB $08,$5C,$20        ; MOVE to 92, 32
  DEFB $8F,$8A            ; LINE of 11 pixels down, stepping left every 7
  DEFB $82,$03            ; LINE of 4 pixels diagonally right and down
  DEFB $80,$02            ; LINE of 3 pixels diagonally right and up
  DEFB $85,$02            ; LINE of 3 pixels diagonally up and left
  DEFB $86,$43            ; LINE of 4 pixels left, stepping down every 2
  DEFB $08,$62,$15        ; MOVE to 98, 21
  DEFB $89,$49            ; LINE of 10 pixels up, stepping right every 6
  DEFB $08,$6A,$1F        ; MOVE to 106, 31
  DEFB $83,$49            ; LINE of 10 pixels down, stepping right every 2
  DEFB $82,$83            ; LINE of 4 pixels right, stepping down every 3
  DEFB $81,$83            ; LINE of 4 pixels up, stepping right every 3
  DEFB $84,$83            ; LINE of 4 pixels left, stepping up every 3
  DEFB $87,$83            ; LINE of 4 pixels down, stepping left every 3
  DEFB $08,$74,$18        ; MOVE to 116, 24
  DEFB $85,$48            ; LINE of 9 pixels up, stepping left every 2
  DEFB $08,$7B,$22        ; MOVE to 123, 34
  DEFB $82,$88            ; LINE of 9 pixels right, stepping down every 3
  DEFB $82,$88            ; LINE of 9 pixels right, stepping down every 3
  DEFB $87,$83            ; LINE of 4 pixels down, stepping left every 3
  DEFB $8E,$03            ; LINE of 4 pixels left, stepping down every 5
  DEFB $85,$C3            ; LINE of 4 pixels up, stepping left every 4
  DEFB $80,$83            ; LINE of 4 pixels right, stepping up every 3
  DEFB $08,$88,$18        ; MOVE to 136, 24
  DEFB $84,$51            ; LINE of 18 pixels left, stepping up every 2
  DEFB $08,$7E,$25        ; MOVE to 126, 37
  DEFB $80,$8E            ; LINE of 15 pixels right, stepping up every 3
  DEFB $8C,$06            ; LINE of 7 pixels left, stepping up every 5
  DEFB $86,$C6            ; LINE of 7 pixels left, stepping down every 4
  DEFB $08,$5B,$3A        ; MOVE to 91, 58
  DEFB $83,$44            ; LINE of 5 pixels down, stepping right every 2
  DEFB $80,$04            ; LINE of 5 pixels diagonally right and up
  DEFB $08,$6E,$38        ; MOVE to 110, 56
  DEFB $82,$C4            ; LINE of 5 pixels right, stepping down every 4
  DEFB $80,$04            ; LINE of 5 pixels diagonally right and up
  DEFB $42,$6B,$3D        ; FILL with red from 107, 61
  DEFB $42,$5E,$38        ; FILL with red from 94, 56
  DEFB $42,$73,$39        ; FILL with red from 115, 57
  DEFB $08,$73,$53        ; MOVE to 115, 83
  DEFB $85,$90            ; LINE of 17 pixels up, stepping left every 3
  DEFB $85,$D0            ; LINE of 17 pixels up, stepping left every 4
  DEFB $85,$D0            ; LINE of 17 pixels up, stepping left every 4
  DEFB $08,$32,$50        ; MOVE to 50, 80
  DEFB $81,$DA            ; LINE of 27 pixels up, stepping right every 4
  DEFB $81,$5A            ; LINE of 27 pixels up, stepping right every 2
  DEFB $08,$10,$56        ; MOVE to 16, 86
  DEFB $89,$DA            ; LINE of 27 pixels up, stepping right every 8
  DEFB $8D,$9A            ; LINE of 27 pixels up, stepping left every 7
  DEFB $08,$9B,$51        ; MOVE to 155, 81
  DEFB $95,$5A            ; LINE of 27 pixels up, stepping left every 10
  DEFB $81,$D9            ; LINE of 26 pixels up, stepping right every 4
  DEFB $08,$57,$58        ; MOVE to 87, 88
  DEFB $81,$D3            ; LINE of 20 pixels up, stepping right every 4
  DEFB $83,$96            ; LINE of 23 pixels down, stepping right every 3
  DEFB $40,$5F,$5B        ; FILL with black from 95, 91
  DEFB $08,$BA,$4B        ; MOVE to 186, 75
  DEFB $89,$E0            ; LINE of 33 pixels up, stepping right every 8
  DEFB $89,$2B            ; LINE of 44 pixels up, stepping right every 5
  DEFB $08,$E9,$3A        ; MOVE to 233, 58
  DEFB $91,$7E            ; LINE of 63 pixels up, stepping right every 10
  DEFB $91,$7E            ; LINE of 63 pixels up, stepping right every 10
  DEFB $08,$A5,$1F        ; MOVE to 165, 31
  DEFB $88,$48            ; LINE of 9 pixels right, stepping up every 6
  DEFB $21,$58,$00,$F9,$F9,$89,$FF ; PAINT blue ink from row 0, column 0, along
                                   ; a path of 3 steps
  DEFB $21,$58,$A5,$09,$FF ; PAINT blue ink from row 5, column 5, along a path
                           ; of 1 step
  DEFB $21,$58,$B2,$31,$02,$1B,$02,$19 ; PAINT blue ink from row 5, column 18,
  DEFB $02,$0B,$FF                     ; along a path of 7 steps
  DEFB $08,$00,$4F        ; MOVE to 0, 79
  DEFB $8A,$C6            ; LINE of 7 pixels right, stepping down every 8
  DEFB $41,$00,$4E        ; FILL with blue from 0, 78
  DEFB $08,$08,$51        ; MOVE to 8, 81
  DEFB $89,$86            ; LINE of 7 pixels up, stepping right every 7
  DEFB $08,$09,$57        ; MOVE to 9, 87
  DEFB $B2,$58            ; LINE of 25 pixels right, stepping down every 26
  DEFB $41,$0B,$55        ; FILL with blue from 11, 85
  DEFB $41,$1A,$55        ; FILL with blue from 26, 85
  DEFB $08,$25,$57        ; MOVE to 37, 87
  DEFB $82,$82            ; LINE of 3 pixels right, stepping down every 3
  DEFB $08,$27,$57        ; MOVE to 39, 87
  DEFB $8B,$C7            ; LINE of 8 pixels down, stepping right every 8
  DEFB $41,$25,$54        ; FILL with blue from 37, 84
  DEFB $08,$40,$51        ; MOVE to 64, 81
  DEFB $89,$C6            ; LINE of 7 pixels up, stepping right every 8
  DEFB $08,$40,$57        ; MOVE to 64, 87
  DEFB $AA,$D7            ; LINE of 24 pixels right, stepping down every 24
  DEFB $41,$45,$55        ; FILL with blue from 69, 85
  DEFB $08,$64,$57        ; MOVE to 100, 87
  DEFB $D2,$EB            ; LINE of 44 pixels right, stepping down every 44
  DEFB $08,$8F,$57        ; MOVE to 143, 87
  DEFB $8B,$C7            ; LINE of 8 pixels down, stepping right every 8
  DEFB $41,$86,$54        ; FILL with blue from 134, 84
  DEFB $41,$6C,$54        ; FILL with blue from 108, 84
  DEFB $08,$A4,$4F        ; MOVE to 164, 79
  DEFB $B2,$DC            ; LINE of 29 pixels right, stepping down every 28
  DEFB $08,$BF,$4E        ; MOVE to 191, 78
  DEFB $9B,$8E            ; LINE of 15 pixels down, stepping right every 15
  DEFB $08,$BF,$3F        ; MOVE to 191, 63
  DEFB $D2,$28            ; LINE of 41 pixels right, stepping down every 41
  DEFB $08,$E7,$3E        ; MOVE to 231, 62
  DEFB $8B,$86            ; LINE of 7 pixels down, stepping right every 7
  DEFB $AA,$D8            ; LINE of 25 pixels right, stepping down every 24
  DEFB $41,$F4,$32        ; FILL with blue from 244, 50
  DEFB $41,$DD,$3C        ; FILL with blue from 221, 60
  DEFB $41,$BD,$47        ; FILL with blue from 189, 71
  DEFB $41,$AB,$4D        ; FILL with blue from 171, 77
  DEFB $42,$A9,$22        ; FILL with red from 169, 34
  DEFB $40,$83,$28        ; FILL with black from 131, 40
  DEFB $40,$83,$1D        ; FILL with black from 131, 29
  DEFB $40,$6F,$1D        ; FILL with black from 111, 29
  DEFB $40,$60,$1D        ; FILL with black from 96, 29
  DEFB $40,$53,$20        ; FILL with black from 83, 32
  DEFB $40,$4E,$27        ; FILL with black from 78, 39
  DEFB $00                ; End of the picture

; Picture for location 24: forest gate
;
; A border colour and a starting attribute, then 52 moves, 141 lines, 8 fills,
; ending at $00.
LOC24_FOREST_GATE_PIC:
  DEFB $07                ; Border: white
  DEFB $38                ; The canvas starts white paper, black ink
  DEFB $08,$00,$77        ; MOVE to 0, 119
  DEFB $82,$45            ; LINE of 6 pixels right, stepping down every 2
  DEFB $80,$45            ; LINE of 6 pixels right, stepping up every 2
  DEFB $80,$85            ; LINE of 6 pixels right, stepping up every 3
  DEFB $82,$45            ; LINE of 6 pixels right, stepping down every 2
  DEFB $8B,$85            ; LINE of 6 pixels down, stepping right every 7
  DEFB $87,$45            ; LINE of 6 pixels down, stepping left every 2
  DEFB $8F,$85            ; LINE of 6 pixels down, stepping left every 7
  DEFB $82,$05            ; LINE of 6 pixels diagonally right and down
  DEFB $82,$85            ; LINE of 6 pixels right, stepping down every 3
  DEFB $82,$45            ; LINE of 6 pixels right, stepping down every 2
  DEFB $85,$45            ; LINE of 6 pixels up, stepping left every 2
  DEFB $85,$45            ; LINE of 6 pixels up, stepping left every 2
  DEFB $81,$45            ; LINE of 6 pixels up, stepping right every 2
  DEFB $80,$45            ; LINE of 6 pixels right, stepping up every 2
  DEFB $80,$05            ; LINE of 6 pixels diagonally right and up
  DEFB $80,$45            ; LINE of 6 pixels right, stepping up every 2
  DEFB $81,$C5            ; LINE of 6 pixels up, stepping right every 4
  DEFB $80,$45            ; LINE of 6 pixels right, stepping up every 2
  DEFB $45,$2E,$79        ; FILL with cyan from 46, 121
  DEFB $08,$B8,$7F        ; MOVE to 184, 127
  DEFB $83,$05            ; LINE of 6 pixels diagonally down and right
  DEFB $83,$45            ; LINE of 6 pixels down, stepping right every 2
  DEFB $8A,$45            ; LINE of 6 pixels right, stepping down every 6
  DEFB $82,$05            ; LINE of 6 pixels diagonally right and down
  DEFB $82,$C5            ; LINE of 6 pixels right, stepping down every 4
  DEFB $82,$85            ; LINE of 6 pixels right, stepping down every 3
  DEFB $88,$45            ; LINE of 6 pixels right, stepping up every 6
  DEFB $80,$C5            ; LINE of 6 pixels right, stepping up every 4
  DEFB $80,$85            ; LINE of 6 pixels right, stepping up every 3
  DEFB $80,$C5            ; LINE of 6 pixels right, stepping up every 4
  DEFB $80,$85            ; LINE of 6 pixels right, stepping up every 3
  DEFB $80,$85            ; LINE of 6 pixels right, stepping up every 3
  DEFB $80,$85            ; LINE of 6 pixels right, stepping up every 3
  DEFB $45,$F0,$71        ; FILL with cyan from 240, 113
  DEFB $08,$19,$30        ; MOVE to 25, 48
  DEFB $98,$7E            ; LINE of 63 pixels right, stepping up every 14
  DEFB $90,$08            ; LINE of 9 pixels right, stepping up every 9
  DEFB $F3,$BD            ; LINE of 62 pixels down, stepping right every 59
  DEFB $08,$23,$2A        ; MOVE to 35, 42
  DEFB $A0,$3D            ; LINE of 62 pixels right, stepping up every 17
  DEFB $08,$1E,$20        ; MOVE to 30, 32
  DEFB $A0,$3D            ; LINE of 62 pixels right, stepping up every 17
  DEFB $80,$C3            ; LINE of 4 pixels right, stepping up every 4
  DEFB $08,$18,$2F        ; MOVE to 24, 47
  DEFB $82,$4A            ; LINE of 11 pixels right, stepping down every 2
  DEFB $8F,$46            ; LINE of 7 pixels down, stepping left every 6
  DEFB $86,$44            ; LINE of 5 pixels left, stepping down every 2
  DEFB $08,$61,$35        ; MOVE to 97, 53
  DEFB $85,$04            ; LINE of 5 pixels diagonally up and left
  DEFB $89,$44            ; LINE of 5 pixels up, stepping right every 6
  DEFB $86,$04            ; LINE of 5 pixels diagonally left and down
  DEFB $84,$84            ; LINE of 5 pixels left, stepping up every 3
  DEFB $85,$C4            ; LINE of 5 pixels up, stepping left every 4
  DEFB $80,$2D            ; LINE of 46 pixels diagonally right and up
  DEFB $82,$28            ; LINE of 41 pixels diagonally right and down
  DEFB $83,$C8            ; LINE of 9 pixels down, stepping right every 4
  DEFB $84,$83            ; LINE of 4 pixels left, stepping up every 3
  DEFB $85,$43            ; LINE of 4 pixels up, stepping left every 2
  DEFB $81,$43            ; LINE of 4 pixels up, stepping right every 2
  DEFB $80,$82            ; LINE of 3 pixels right, stepping up every 3
  DEFB $08,$A7,$3C        ; MOVE to 167, 60
  DEFB $85,$26            ; LINE of 39 pixels diagonally up and left
  DEFB $87,$24            ; LINE of 37 pixels diagonally down and left
  DEFB $08,$80,$63        ; MOVE to 128, 99
  DEFB $85,$85            ; LINE of 6 pixels up, stepping left every 3
  DEFB $81,$84            ; LINE of 5 pixels up, stepping right every 3
  DEFB $08,$60,$42        ; MOVE to 96, 66
  DEFB $98,$FE            ; LINE of 63 pixels right, stepping up every 16
  DEFB $08,$9D,$3D        ; MOVE to 157, 61
  DEFB $9E,$FE            ; LINE of 63 pixels left, stepping down every 16
  DEFB $86,$00            ; LINE of 1 pixel diagonally left and down
  DEFB $08,$9E,$3D        ; MOVE to 158, 61
  DEFB $8D,$86            ; LINE of 7 pixels up, stepping left every 7
  DEFB $08,$9E,$3C        ; MOVE to 158, 60
  DEFB $83,$03            ; LINE of 4 pixels diagonally down and right
  DEFB $A6,$3E            ; LINE of 63 pixels left, stepping down every 17
  DEFB $86,$C3            ; LINE of 4 pixels left, stepping down every 4
  DEFB $08,$A3,$38        ; MOVE to 163, 56
  DEFB $89,$86            ; LINE of 7 pixels up, stepping right every 7
  DEFB $08,$A3,$37        ; MOVE to 163, 55
  DEFB $FB,$3E            ; LINE of 63 pixels down, stepping right every 61
  DEFB $08,$68,$34        ; MOVE to 104, 52
  DEFB $FB,$3E            ; LINE of 63 pixels down, stepping right every 61
  DEFB $08,$6B,$34        ; MOVE to 107, 52
  DEFB $FB,$3E            ; LINE of 63 pixels down, stepping right every 61
  DEFB $08,$99,$37        ; MOVE to 153, 55
  DEFB $FB,$3E            ; LINE of 63 pixels down, stepping right every 61
  DEFB $08,$A0,$37        ; MOVE to 160, 55
  DEFB $FB,$3E            ; LINE of 63 pixels down, stepping right every 61
  DEFB $08,$21,$1F        ; MOVE to 33, 31
  DEFB $A3,$10            ; LINE of 17 pixels down, stepping right every 17
  DEFB $08,$29,$1F        ; MOVE to 41, 31
  DEFB $B7,$59            ; LINE of 26 pixels down, stepping left every 26
  DEFB $08,$32,$20        ; MOVE to 50, 32
  DEFB $B7,$59            ; LINE of 26 pixels down, stepping left every 26
  DEFB $08,$3B,$20        ; MOVE to 59, 32
  DEFB $A7,$D3            ; LINE of 20 pixels down, stepping left every 20
  DEFB $08,$44,$21        ; MOVE to 68, 33
  DEFB $C7,$E2            ; LINE of 35 pixels down, stepping left every 36
  DEFB $08,$4D,$21        ; MOVE to 77, 33
  DEFB $C7,$E2            ; LINE of 35 pixels down, stepping left every 36
  DEFB $08,$57,$22        ; MOVE to 87, 34
  DEFB $C7,$A3            ; LINE of 36 pixels down, stepping left every 35
  DEFB $08,$A4,$37        ; MOVE to 164, 55
  DEFB $A0,$3E            ; LINE of 63 pixels right, stepping up every 17
  DEFB $A0,$3E            ; LINE of 63 pixels right, stepping up every 17
  DEFB $08,$A4,$30        ; MOVE to 164, 48
  DEFB $A0,$3E            ; LINE of 63 pixels right, stepping up every 17
  DEFB $A0,$3E            ; LINE of 63 pixels right, stepping up every 17
  DEFB $08,$A4,$25        ; MOVE to 164, 37
  DEFB $A0,$3E            ; LINE of 63 pixels right, stepping up every 17
  DEFB $A0,$3E            ; LINE of 63 pixels right, stepping up every 17
  DEFB $08,$AD,$24        ; MOVE to 173, 36
  DEFB $CB,$AD            ; LINE of 46 pixels down, stepping right every 39
  DEFB $08,$B7,$25        ; MOVE to 183, 37
  DEFB $CB,$AD            ; LINE of 46 pixels down, stepping right every 39
  DEFB $08,$C1,$25        ; MOVE to 193, 37
  DEFB $CB,$AD            ; LINE of 46 pixels down, stepping right every 39
  DEFB $08,$CC,$26        ; MOVE to 204, 38
  DEFB $C3,$A2            ; LINE of 35 pixels down, stepping right every 35
  DEFB $08,$D5,$26        ; MOVE to 213, 38
  DEFB $CB,$24            ; LINE of 37 pixels down, stepping right every 37
  DEFB $08,$DE,$27        ; MOVE to 222, 39
  DEFB $D7,$69            ; LINE of 42 pixels down, stepping left every 42
  DEFB $08,$E8,$27        ; MOVE to 232, 39
  DEFB $D7,$69            ; LINE of 42 pixels down, stepping left every 42
  DEFB $08,$F1,$27        ; MOVE to 241, 39
  DEFB $D7,$69            ; LINE of 42 pixels down, stepping left every 42
  DEFB $08,$FA,$28        ; MOVE to 250, 40
  DEFB $D7,$69            ; LINE of 42 pixels down, stepping left every 42
  DEFB $08,$81,$5C        ; MOVE to 129, 92
  DEFB $86,$19            ; LINE of 26 pixels diagonally left and down
  DEFB $08,$81,$5C        ; MOVE to 129, 92
  DEFB $83,$16            ; LINE of 23 pixels diagonally down and right
  DEFB $40,$81,$5E        ; FILL with black from 129, 94
  DEFB $40,$69,$2D        ; FILL with black from 105, 45
  DEFB $40,$A2,$2D        ; FILL with black from 162, 45
  DEFB $40,$A2,$3C        ; FILL with black from 162, 60
  DEFB $40,$A7,$40        ; FILL with black from 167, 64
  DEFB $08,$21,$0E        ; MOVE to 33, 14
  DEFB $83,$08            ; LINE of 9 pixels diagonally down and right
  DEFB $88,$48            ; LINE of 9 pixels right, stepping up every 6
  DEFB $88,$48            ; LINE of 9 pixels right, stepping up every 6
  DEFB $85,$85            ; LINE of 6 pixels up, stepping left every 3
  DEFB $08,$3C,$07        ; MOVE to 60, 7
  DEFB $83,$08            ; LINE of 9 pixels diagonally down and right
  DEFB $42,$7D,$4A        ; FILL with red from 125, 74
  DEFB $08,$21,$0E        ; MOVE to 33, 14
  DEFB $84,$CB            ; LINE of 12 pixels left, stepping up every 4
  DEFB $8C,$8B            ; LINE of 12 pixels left, stepping up every 7
  DEFB $85,$0B            ; LINE of 12 pixels diagonally up and left
  DEFB $08,$C2,$00        ; MOVE to 194, 0
  DEFB $80,$49            ; LINE of 10 pixels right, stepping up every 2
  DEFB $82,$49            ; LINE of 10 pixels right, stepping down every 2
  DEFB $8A,$C9            ; LINE of 10 pixels right, stepping down every 8
  DEFB $08,$1D,$20        ; MOVE to 29, 32
  DEFB $87,$88            ; LINE of 9 pixels down, stepping left every 3
  DEFB $87,$88            ; LINE of 9 pixels down, stepping left every 3
  DEFB $08,$17,$30        ; MOVE to 23, 48
  DEFB $85,$C8            ; LINE of 9 pixels up, stepping left every 4
  DEFB $85,$08            ; LINE of 9 pixels diagonally up and left
  DEFB $85,$48            ; LINE of 9 pixels up, stepping left every 2
  DEFB $85,$08            ; LINE of 9 pixels diagonally up and left
  DEFB $08,$29,$57        ; MOVE to 41, 87
  DEFB $82,$48            ; LINE of 9 pixels right, stepping down every 2
  DEFB $83,$C8            ; LINE of 9 pixels down, stepping right every 4
  DEFB $83,$48            ; LINE of 9 pixels down, stepping right every 2
  DEFB $83,$08            ; LINE of 9 pixels diagonally down and right
  DEFB $82,$48            ; LINE of 9 pixels right, stepping down every 2
  DEFB $08,$A8,$47        ; MOVE to 168, 71
  DEFB $81,$C8            ; LINE of 9 pixels up, stepping right every 4
  DEFB $81,$08            ; LINE of 9 pixels diagonally up and right
  DEFB $81,$48            ; LINE of 9 pixels up, stepping right every 2
  DEFB $80,$C8            ; LINE of 9 pixels right, stepping up every 4
  DEFB $80,$88            ; LINE of 9 pixels right, stepping up every 3
  DEFB $90,$48            ; LINE of 9 pixels right, stepping up every 10
  DEFB $90,$48            ; LINE of 9 pixels right, stepping up every 10
  DEFB $08,$C5,$49        ; MOVE to 197, 73
  DEFB $81,$08            ; LINE of 9 pixels diagonally up and right
  DEFB $80,$88            ; LINE of 9 pixels right, stepping up every 3
  DEFB $80,$48            ; LINE of 9 pixels right, stepping up every 2
  DEFB $88,$48            ; LINE of 9 pixels right, stepping up every 6
  DEFB $80,$08            ; LINE of 9 pixels diagonally right and up
  DEFB $80,$C8            ; LINE of 9 pixels right, stepping up every 4
  DEFB $80,$C8            ; LINE of 9 pixels right, stepping up every 4
  DEFB $08,$46,$7E        ; MOVE to 70, 126
  DEFB $8A,$88            ; LINE of 9 pixels right, stepping down every 7
  DEFB $82,$48            ; LINE of 9 pixels right, stepping down every 2
  DEFB $83,$C8            ; LINE of 9 pixels down, stepping right every 4
  DEFB $83,$88            ; LINE of 9 pixels down, stepping right every 3
  DEFB $08,$5A,$70        ; MOVE to 90, 112
  DEFB $8F,$C8            ; LINE of 9 pixels down, stepping left every 8
  DEFB $8F,$88            ; LINE of 9 pixels down, stepping left every 7
  DEFB $8B,$C8            ; LINE of 9 pixels down, stepping right every 8
  DEFB $83,$48            ; LINE of 9 pixels down, stepping right every 2
  DEFB $08,$88,$66        ; MOVE to 136, 102
  DEFB $81,$88            ; LINE of 9 pixels up, stepping right every 3
  DEFB $81,$08            ; LINE of 9 pixels diagonally up and right
  DEFB $80,$48            ; LINE of 9 pixels right, stepping up every 2
  DEFB $80,$48            ; LINE of 9 pixels right, stepping up every 2
  DEFB $00                ; End of the picture

; Picture for location 35: lake town
;
; A border colour and a starting attribute, then 100 moves, 185 lines, 6 fills,
; ending at $00.
LOC35_LAKE_TOWN_PIC:
  DEFB $07                ; Border: white
  DEFB $38                ; The canvas starts white paper, black ink
  DEFB $08,$23,$34        ; MOVE to 35, 52
  DEFB $95,$CA            ; LINE of 11 pixels up, stepping left every 12
  DEFB $81,$04            ; LINE of 5 pixels diagonally up and right
  DEFB $8A,$C6            ; LINE of 7 pixels right, stepping down every 8
  DEFB $08,$2E,$41        ; MOVE to 46, 65
  DEFB $81,$4C            ; LINE of 13 pixels up, stepping right every 2
  DEFB $A0,$51            ; LINE of 18 pixels right, stepping up every 18
  DEFB $08,$2E,$40        ; MOVE to 46, 64
  DEFB $A8,$D7            ; LINE of 24 pixels right, stepping up every 24
  DEFB $A9,$D7            ; LINE of 24 pixels up, stepping right every 24
  DEFB $08,$44,$57        ; MOVE to 68, 87
  DEFB $81,$52            ; LINE of 19 pixels up, stepping right every 2
  DEFB $93,$92            ; LINE of 19 pixels down, stepping right every 11
  DEFB $08,$4D,$6A        ; MOVE to 77, 106
  DEFB $83,$91            ; LINE of 18 pixels down, stepping right every 3
  DEFB $08,$4D,$6A        ; MOVE to 77, 106
  DEFB $8D,$04            ; LINE of 5 pixels up, stepping left every 5
  DEFB $08,$47,$59        ; MOVE to 71, 89
  DEFB $88,$86            ; LINE of 7 pixels right, stepping up every 7
  DEFB $08,$4E,$59        ; MOVE to 78, 89
  DEFB $80,$84            ; LINE of 5 pixels right, stepping up every 3
  DEFB $08,$4E,$58        ; MOVE to 78, 88
  DEFB $A3,$D2            ; LINE of 19 pixels down, stepping right every 20
  DEFB $08,$52,$59        ; MOVE to 82, 89
  DEFB $A3,$92            ; LINE of 19 pixels down, stepping right every 19
  DEFB $08,$46,$40        ; MOVE to 70, 64
  DEFB $8B,$45            ; LINE of 6 pixels down, stepping right every 6
  DEFB $08,$46,$3D        ; MOVE to 70, 61
  DEFB $81,$0A            ; LINE of 11 pixels diagonally up and right
  DEFB $08,$51,$47        ; MOVE to 81, 71
  DEFB $B0,$18            ; LINE of 25 pixels right, stepping up every 25
  DEFB $08,$6A,$47        ; MOVE to 106, 71
  DEFB $82,$08            ; LINE of 9 pixels diagonally right and down
  DEFB $8E,$08            ; LINE of 9 pixels left, stepping down every 5
  DEFB $95,$49            ; LINE of 10 pixels up, stepping left every 10
  DEFB $08,$6A,$3D        ; MOVE to 106, 61
  DEFB $C4,$E3            ; LINE of 36 pixels left, stepping up every 36
  DEFB $08,$6A,$3D        ; MOVE to 106, 61
  DEFB $97,$CB            ; LINE of 12 pixels down, stepping left every 12
  DEFB $08,$72,$3E        ; MOVE to 114, 62
  DEFB $97,$CB            ; LINE of 12 pixels down, stepping left every 12
  DEFB $08,$79,$36        ; MOVE to 121, 54
  DEFB $89,$86            ; LINE of 7 pixels up, stepping right every 7
  DEFB $80,$04            ; LINE of 5 pixels diagonally right and up
  DEFB $95,$08            ; LINE of 9 pixels up, stepping left every 9
  DEFB $80,$08            ; LINE of 9 pixels diagonally right and up
  DEFB $A0,$10            ; LINE of 17 pixels right, stepping up every 17
  DEFB $83,$08            ; LINE of 9 pixels diagonally down and right
  DEFB $8E,$CA            ; LINE of 11 pixels left, stepping down every 8
  DEFB $81,$CA            ; LINE of 11 pixels up, stepping right every 4
  DEFB $08,$95,$4B        ; MOVE to 149, 75
  DEFB $AC,$96            ; LINE of 23 pixels left, stepping up every 23
  DEFB $08,$95,$4B        ; MOVE to 149, 75
  DEFB $AF,$D7            ; LINE of 24 pixels down, stepping left every 24
  DEFB $08,$A0,$4B        ; MOVE to 160, 75
  DEFB $AF,$D7            ; LINE of 24 pixels down, stepping left every 24
  DEFB $08,$80,$42        ; MOVE to 128, 66
  DEFB $90,$08            ; LINE of 9 pixels right, stepping up every 9
  DEFB $08,$8A,$42        ; MOVE to 138, 66
  DEFB $9B,$CF            ; LINE of 16 pixels down, stepping right every 16
  DEFB $08,$8A,$42        ; MOVE to 138, 66
  DEFB $86,$06            ; LINE of 7 pixels diagonally left and down
  DEFB $97,$49            ; LINE of 10 pixels down, stepping left every 10
  DEFB $08,$83,$3B        ; MOVE to 131, 59
  DEFB $96,$89            ; LINE of 10 pixels left, stepping down every 11
  DEFB $08,$82,$35        ; MOVE to 130, 53
  DEFB $9E,$0C            ; LINE of 13 pixels left, stepping down every 13
  DEFB $86,$45            ; LINE of 6 pixels left, stepping down every 2
  DEFB $8F,$85            ; LINE of 6 pixels down, stepping left every 7
  DEFB $08,$1D,$32        ; MOVE to 29, 50
  DEFB $80,$C4            ; LINE of 5 pixels right, stepping up every 4
  DEFB $88,$04            ; LINE of 5 pixels right, stepping up every 5
  DEFB $80,$84            ; LINE of 5 pixels right, stepping up every 3
  DEFB $88,$44            ; LINE of 5 pixels right, stepping up every 6
  DEFB $83,$44            ; LINE of 5 pixels down, stepping right every 2
  DEFB $8A,$04            ; LINE of 5 pixels right, stepping down every 5
  DEFB $08,$33,$30        ; MOVE to 51, 48
  DEFB $8A,$04            ; LINE of 5 pixels right, stepping down every 5
  DEFB $8A,$44            ; LINE of 5 pixels right, stepping down every 6
  DEFB $88,$04            ; LINE of 5 pixels right, stepping up every 5
  DEFB $88,$44            ; LINE of 5 pixels right, stepping up every 6
  DEFB $82,$C4            ; LINE of 5 pixels right, stepping down every 4
  DEFB $82,$84            ; LINE of 5 pixels right, stepping down every 3
  DEFB $08,$4C,$2F        ; MOVE to 76, 47
  DEFB $82,$84            ; LINE of 5 pixels right, stepping down every 3
  DEFB $82,$C4            ; LINE of 5 pixels right, stepping down every 4
  DEFB $8A,$04            ; LINE of 5 pixels right, stepping down every 5
  DEFB $80,$84            ; LINE of 5 pixels right, stepping up every 3
  DEFB $80,$04            ; LINE of 5 pixels diagonally right and up
  DEFB $88,$04            ; LINE of 5 pixels right, stepping up every 5
  DEFB $83,$84            ; LINE of 5 pixels down, stepping right every 3
  DEFB $82,$44            ; LINE of 5 pixels right, stepping down every 2
  DEFB $82,$C4            ; LINE of 5 pixels right, stepping down every 4
  DEFB $80,$84            ; LINE of 5 pixels right, stepping up every 3
  DEFB $80,$04            ; LINE of 5 pixels diagonally right and up
  DEFB $80,$84            ; LINE of 5 pixels right, stepping up every 3
  DEFB $80,$C4            ; LINE of 5 pixels right, stepping up every 4
  DEFB $88,$04            ; LINE of 5 pixels right, stepping up every 5
  DEFB $88,$44            ; LINE of 5 pixels right, stepping up every 6
  DEFB $8A,$04            ; LINE of 5 pixels right, stepping down every 5
  DEFB $82,$C4            ; LINE of 5 pixels right, stepping down every 4
  DEFB $80,$84            ; LINE of 5 pixels right, stepping up every 3
  DEFB $88,$04            ; LINE of 5 pixels right, stepping up every 5
  DEFB $08,$05,$31        ; MOVE to 5, 49
  DEFB $82,$91            ; LINE of 18 pixels right, stepping down every 3
  DEFB $82,$D1            ; LINE of 18 pixels right, stepping down every 4
  DEFB $8A,$D1            ; LINE of 18 pixels right, stepping down every 8
  DEFB $8A,$91            ; LINE of 18 pixels right, stepping down every 7
  DEFB $8A,$51            ; LINE of 18 pixels right, stepping down every 6
  DEFB $88,$11            ; LINE of 18 pixels right, stepping up every 5
  DEFB $88,$D1            ; LINE of 18 pixels right, stepping up every 8
  DEFB $90,$51            ; LINE of 18 pixels right, stepping up every 10
  DEFB $90,$51            ; LINE of 18 pixels right, stepping up every 10
  DEFB $80,$51            ; LINE of 18 pixels right, stepping up every 2
  DEFB $80,$91            ; LINE of 18 pixels right, stepping up every 3
  DEFB $8C,$51            ; LINE of 18 pixels left, stepping up every 6
  DEFB $08,$CB,$36        ; MOVE to 203, 54
  DEFB $8C,$91            ; LINE of 18 pixels left, stepping up every 7
  DEFB $8C,$91            ; LINE of 18 pixels left, stepping up every 7
  DEFB $84,$46            ; LINE of 7 pixels left, stepping up every 2
  DEFB $08,$31,$49        ; MOVE to 49, 73
  DEFB $8C,$4E            ; LINE of 15 pixels left, stepping up every 6
  DEFB $8E,$8E            ; LINE of 15 pixels left, stepping down every 7
  DEFB $8E,$8E            ; LINE of 15 pixels left, stepping down every 7
  DEFB $8E,$8E            ; LINE of 15 pixels left, stepping down every 7
  DEFB $08,$05,$31        ; MOVE to 5, 49
  DEFB $8E,$8E            ; LINE of 15 pixels left, stepping down every 7
  DEFB $08,$5D,$47        ; MOVE to 93, 71
  DEFB $A9,$96            ; LINE of 23 pixels up, stepping right every 23
  DEFB $80,$49            ; LINE of 10 pixels right, stepping up every 2
  DEFB $B8,$9D            ; LINE of 30 pixels right, stepping up every 31
  DEFB $9B,$CF            ; LINE of 16 pixels down, stepping right every 16
  DEFB $08,$86,$63        ; MOVE to 134, 99
  DEFB $86,$4C            ; LINE of 13 pixels left, stepping down every 2
  DEFB $B4,$9A            ; LINE of 27 pixels left, stepping up every 27
  DEFB $08,$79,$5D        ; MOVE to 121, 93
  DEFB $C3,$A1            ; LINE of 34 pixels down, stepping right every 35
  DEFB $08,$46,$47        ; MOVE to 70, 71
  DEFB $B3,$17            ; LINE of 24 pixels down, stepping right every 25
  DEFB $08,$2E,$40        ; MOVE to 46, 64
  DEFB $9B,$0B            ; LINE of 12 pixels down, stepping right every 13
  DEFB $08,$53,$4C        ; MOVE to 83, 76
  DEFB $80,$49            ; LINE of 10 pixels right, stepping up every 2
  DEFB $08,$A6,$33        ; MOVE to 166, 51
  DEFB $82,$C9            ; LINE of 10 pixels right, stepping down every 4
  DEFB $82,$C9            ; LINE of 10 pixels right, stepping down every 4
  DEFB $08,$A1,$35        ; MOVE to 161, 53
  DEFB $92,$49            ; LINE of 10 pixels right, stepping down every 10
  DEFB $8A,$49            ; LINE of 10 pixels right, stepping down every 6
  DEFB $8A,$09            ; LINE of 10 pixels right, stepping down every 5
  DEFB $08,$FF,$39        ; MOVE to 255, 57
  DEFB $8C,$23            ; LINE of 36 pixels left, stepping up every 5
  DEFB $84,$E3            ; LINE of 36 pixels left, stepping up every 4
  DEFB $84,$D8            ; LINE of 25 pixels left, stepping up every 4
  DEFB $08,$5C,$5A        ; MOVE to 92, 90
  DEFB $8C,$49            ; LINE of 10 pixels left, stepping up every 6
  DEFB $08,$47,$61        ; MOVE to 71, 97
  DEFB $94,$F9            ; LINE of 58 pixels left, stepping up every 12
  DEFB $9C,$39            ; LINE of 58 pixels left, stepping up every 13
  DEFB $08,$FF,$7A        ; MOVE to 255, 122
  DEFB $8E,$2F            ; LINE of 48 pixels left, stepping down every 5
  DEFB $8E,$E3            ; LINE of 36 pixels left, stepping down every 8
  DEFB $8E,$D3            ; LINE of 20 pixels left, stepping down every 8
  DEFB $84,$93            ; LINE of 20 pixels left, stepping up every 3
  DEFB $86,$4C            ; LINE of 13 pixels left, stepping down every 2
  DEFB $8E,$4C            ; LINE of 13 pixels left, stepping down every 6
  DEFB $86,$CC            ; LINE of 13 pixels left, stepping down every 4
  DEFB $86,$CC            ; LINE of 13 pixels left, stepping down every 4
  DEFB $08,$AA,$6E        ; MOVE to 170, 110
  DEFB $84,$4C            ; LINE of 13 pixels left, stepping up every 2
  DEFB $8C,$0C            ; LINE of 13 pixels left, stepping up every 5
  DEFB $8C,$4C            ; LINE of 13 pixels left, stepping up every 6
  DEFB $84,$4E            ; LINE of 15 pixels left, stepping up every 2
  DEFB $08,$A1,$73        ; MOVE to 161, 115
  DEFB $80,$8C            ; LINE of 13 pixels right, stepping up every 3
  DEFB $80,$44            ; LINE of 5 pixels right, stepping up every 2
  DEFB $83,$04            ; LINE of 5 pixels diagonally down and right
  DEFB $80,$84            ; LINE of 5 pixels right, stepping up every 3
  DEFB $82,$8B            ; LINE of 12 pixels right, stepping down every 3
  DEFB $08,$48,$55        ; MOVE to 72, 85
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$49,$55        ; MOVE to 73, 85
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$4B,$55        ; MOVE to 75, 85
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$4C,$55        ; MOVE to 76, 85
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$48,$4E        ; MOVE to 72, 78
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$49,$4E        ; MOVE to 73, 78
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$4B,$4E        ; MOVE to 75, 78
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$4C,$4E        ; MOVE to 76, 78
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$4C,$47        ; MOVE to 76, 71
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$4B,$47        ; MOVE to 75, 71
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$49,$47        ; MOVE to 73, 71
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$48,$47        ; MOVE to 72, 71
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$32,$3C        ; MOVE to 50, 60
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$33,$3C        ; MOVE to 51, 60
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$34,$3C        ; MOVE to 52, 60
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$39,$3C        ; MOVE to 57, 60
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$3A,$3C        ; MOVE to 58, 60
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$3B,$3C        ; MOVE to 59, 60
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$40,$3C        ; MOVE to 64, 60
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$41,$3C        ; MOVE to 65, 60
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$42,$3C        ; MOVE to 66, 60
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$4A,$38        ; MOVE to 74, 56
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$4B,$39        ; MOVE to 75, 57
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$4C,$38        ; MOVE to 76, 56
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$51,$38        ; MOVE to 81, 56
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$52,$39        ; MOVE to 82, 57
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$53,$38        ; MOVE to 83, 56
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$58,$38        ; MOVE to 88, 56
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$59,$39        ; MOVE to 89, 57
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$5A,$38        ; MOVE to 90, 56
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$60,$38        ; MOVE to 96, 56
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$61,$39        ; MOVE to 97, 57
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$62,$38        ; MOVE to 98, 56
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$8E,$46        ; MOVE to 142, 70
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$8F,$46        ; MOVE to 143, 70
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$90,$46        ; MOVE to 144, 70
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$90,$3E        ; MOVE to 144, 62
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$8F,$3E        ; MOVE to 143, 62
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$8E,$3E        ; MOVE to 142, 62
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$99,$3E        ; MOVE to 153, 62
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$9A,$3E        ; MOVE to 154, 62
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$9B,$3F        ; MOVE to 155, 63
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$9C,$3F        ; MOVE to 156, 63
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$99,$45        ; MOVE to 153, 69
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$9A,$45        ; MOVE to 154, 69
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$9A,$45        ; MOVE to 154, 69
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$9B,$46        ; MOVE to 155, 70
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$9C,$46        ; MOVE to 156, 70
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$84,$48        ; MOVE to 132, 72
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$85,$48        ; MOVE to 133, 72
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$86,$48        ; MOVE to 134, 72
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$50,$56        ; MOVE to 80, 86
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $08,$50,$4F        ; MOVE to 80, 79
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $42,$86,$4D        ; FILL with red from 134, 77
  DEFB $42,$82,$3F        ; FILL with red from 130, 63
  DEFB $42,$49,$5B        ; FILL with red from 73, 91
  DEFB $42,$50,$5B        ; FILL with red from 80, 91
  DEFB $45,$8C,$7F        ; FILL with cyan from 140, 127
  DEFB $41,$59,$15        ; FILL with blue from 89, 21
  DEFB $00                ; End of the picture

; Picture for location 13: goblins dungeon
;
; A border colour and a starting attribute, then 43 moves, 70 lines, 2 fills,
; counting the part it shares with location 31, dark dungeon, and ending at the
; $00 the two have in common.
;
; Runs on into location 31's -- dark dungeon's -- picture rather than ending:
; the last opcode here takes that picture's border and attribute bytes as its
; operands, and from its first opcode on the two are one stream.
LOC13_GOBLINS_DUNGEON_PIC:
  DEFB $00                ; Border: black
  DEFB $30                ; The canvas starts yellow paper, black ink
  DEFB $08,$84,$55        ; MOVE to 132, 85
  DEFB $85,$CF            ; LINE of 16 pixels up, stepping left every 4
  DEFB $85,$05            ; LINE of 6 pixels diagonally up and left
  DEFB $81,$C3            ; LINE of 4 pixels up, stepping right every 4
  DEFB $80,$43            ; LINE of 4 pixels right, stepping up every 2
  DEFB $82,$83            ; LINE of 4 pixels right, stepping down every 3
  DEFB $82,$43            ; LINE of 4 pixels right, stepping down every 2
  DEFB $82,$03            ; LINE of 4 pixels diagonally right and down
  DEFB $82,$01            ; LINE of 2 pixels diagonally right and down
  DEFB $83,$8F            ; LINE of 16 pixels down, stepping right every 3
  DEFB $86,$CE            ; LINE of 15 pixels left, stepping down every 4
  DEFB $40,$84,$6B        ; FILL with black from 132, 107
  DEFB $08                ; MOVE to 0, 16 -- its last bytes are the next
                          ; picture's start

; Picture for location 31: dark dungeon
;
; A border colour and a starting attribute, then 41 moves, 60 lines, 1 fill,
; ending at $00.
LOC31_DARK_DUNGEON_PIC:
  DEFB $00                ; Border: black
  DEFB $10                ; The canvas starts red paper, black ink
  DEFB $08,$41,$1D        ; MOVE to 65, 29
  DEFB $C9,$65            ; LINE of 38 pixels up, stepping right every 38
  DEFB $89,$09            ; LINE of 10 pixels up, stepping right every 5
  DEFB $81,$CA            ; LINE of 11 pixels up, stepping right every 4
  DEFB $81,$49            ; LINE of 10 pixels up, stepping right every 2
  DEFB $81,$0A            ; LINE of 11 pixels diagonally up and right
  DEFB $80,$CB            ; LINE of 12 pixels right, stepping up every 4
  DEFB $08,$6A,$1D        ; MOVE to 106, 29
  DEFB $91,$CA            ; LINE of 11 pixels up, stepping right every 12
  DEFB $81,$83            ; LINE of 4 pixels up, stepping right every 3
  DEFB $81,$42            ; LINE of 3 pixels up, stepping right every 2
  DEFB $81,$03            ; LINE of 4 pixels diagonally up and right
  DEFB $88,$04            ; LINE of 5 pixels right, stepping up every 5
  DEFB $08,$7B,$1D        ; MOVE to 123, 29
  DEFB $9D,$0C            ; LINE of 13 pixels up, stepping left every 13
  DEFB $85,$84            ; LINE of 5 pixels up, stepping left every 3
  DEFB $85,$04            ; LINE of 5 pixels diagonally up and left
  DEFB $08,$40,$1D        ; MOVE to 64, 29
  DEFB $8E,$7E            ; LINE of 63 pixels left, stepping down every 6
  DEFB $08,$40,$35        ; MOVE to 64, 53
  DEFB $8C,$7E            ; LINE of 63 pixels left, stepping up every 6
  DEFB $08,$42,$4C        ; MOVE to 66, 76
  DEFB $84,$BE            ; LINE of 63 pixels left, stepping up every 3
  DEFB $08,$4A,$62        ; MOVE to 74, 98
  DEFB $84,$7E            ; LINE of 63 pixels left, stepping up every 2
  DEFB $08,$55,$6E        ; MOVE to 85, 110
  DEFB $84,$3E            ; LINE of 63 pixels diagonally left and up
  DEFB $08,$61,$6F        ; MOVE to 97, 111
  DEFB $89,$BE            ; LINE of 63 pixels up, stepping right every 7
  DEFB $08,$6D,$6D        ; MOVE to 109, 109
  DEFB $80,$7E            ; LINE of 63 pixels right, stepping up every 2
  DEFB $08,$79,$62        ; MOVE to 121, 98
  DEFB $80,$BE            ; LINE of 63 pixels right, stepping up every 3
  DEFB $80,$BE            ; LINE of 63 pixels right, stepping up every 3
  DEFB $08,$80,$4C        ; MOVE to 128, 76
  DEFB $88,$BE            ; LINE of 63 pixels right, stepping up every 7
  DEFB $88,$BE            ; LINE of 63 pixels right, stepping up every 7
  DEFB $08,$82,$34        ; MOVE to 130, 52
  DEFB $A0,$BE            ; LINE of 63 pixels right, stepping up every 19
  DEFB $A0,$BC            ; LINE of 61 pixels right, stepping up every 19
  DEFB $08,$82,$1D        ; MOVE to 130, 29
  DEFB $8A,$BE            ; LINE of 63 pixels right, stepping down every 7
  DEFB $8A,$BC            ; LINE of 61 pixels right, stepping down every 7
  DEFB $08,$33,$38        ; MOVE to 51, 56
  DEFB $89,$97            ; LINE of 24 pixels up, stepping right every 7
  DEFB $08,$41,$67        ; MOVE to 65, 103
  DEFB $80,$0D            ; LINE of 14 pixels diagonally right and up
  DEFB $08,$62,$75        ; MOVE to 98, 117
  DEFB $8A,$14            ; LINE of 21 pixels right, stepping down every 5
  DEFB $08,$85,$64        ; MOVE to 133, 100
  DEFB $83,$96            ; LINE of 23 pixels down, stepping right every 3
  DEFB $08,$8E,$33        ; MOVE to 142, 51
  DEFB $AB,$96            ; LINE of 23 pixels down, stepping right every 23
  DEFB $08,$B2,$35        ; MOVE to 178, 53
  DEFB $BB,$DE            ; LINE of 31 pixels down, stepping right every 32
  DEFB $08,$DD,$37        ; MOVE to 221, 55
  DEFB $CF,$65            ; LINE of 38 pixels down, stepping left every 38
  DEFB $08,$F0,$3A        ; MOVE to 240, 58
  DEFB $8D,$A0            ; LINE of 33 pixels up, stepping left every 7
  DEFB $08,$C8,$38        ; MOVE to 200, 56
  DEFB $8D,$5D            ; LINE of 30 pixels up, stepping left every 6
  DEFB $08,$9F,$36        ; MOVE to 159, 54
  DEFB $8D,$9A            ; LINE of 27 pixels up, stepping left every 7
  DEFB $08,$B1,$53        ; MOVE to 177, 83
  DEFB $85,$9D            ; LINE of 30 pixels up, stepping left every 3
  DEFB $08,$D7,$59        ; MOVE to 215, 89
  DEFB $85,$A3            ; LINE of 36 pixels up, stepping left every 3
  DEFB $08,$94,$6C        ; MOVE to 148, 108
  DEFB $84,$0D            ; LINE of 14 pixels diagonally left and up
  DEFB $08,$B8,$78        ; MOVE to 184, 120
  DEFB $84,$0D            ; LINE of 14 pixels diagonally left and up
  DEFB $08,$22,$19        ; MOVE to 34, 25
  DEFB $C1,$20            ; LINE of 33 pixels up, stepping right every 33
  DEFB $08,$12,$3D        ; MOVE to 18, 61
  DEFB $89,$5D            ; LINE of 30 pixels up, stepping right every 6
  DEFB $08,$26,$56        ; MOVE to 38, 86
  DEFB $81,$57            ; LINE of 24 pixels up, stepping right every 2
  DEFB $08,$04,$61        ; MOVE to 4, 97
  DEFB $81,$5C            ; LINE of 29 pixels up, stepping right every 2
  DEFB $08,$22,$76        ; MOVE to 34, 118
  DEFB $80,$1C            ; LINE of 29 pixels diagonally right and up
  DEFB $08,$47,$7D        ; MOVE to 71, 125
  DEFB $88,$1C            ; LINE of 29 pixels right, stepping up every 5
  DEFB $08,$81,$1D        ; MOVE to 129, 29
  DEFB $CD,$65            ; LINE of 38 pixels up, stepping left every 38
  DEFB $8D,$13            ; LINE of 20 pixels up, stepping left every 5
  DEFB $85,$8A            ; LINE of 11 pixels up, stepping left every 3
  DEFB $84,$0B            ; LINE of 12 pixels diagonally left and up
  DEFB $8C,$4B            ; LINE of 12 pixels left, stepping up every 6
  DEFB $08,$42,$1D        ; MOVE to 66, 29
  DEFB $F8,$BE            ; LINE of 63 pixels right, stepping up every 63
  DEFB $08,$FC,$5E        ; MOVE to 252, 94
  DEFB $85,$FE            ; LINE of 63 pixels up, stepping left every 4
  DEFB $40,$FC,$7F        ; FILL with black from 252, 127
  DEFB $08,$72,$2F        ; MOVE to 114, 47
  DEFB $8B,$45            ; LINE of 6 pixels down, stepping right every 6
  DEFB $08,$75,$2F        ; MOVE to 117, 47
  DEFB $8B,$45            ; LINE of 6 pixels down, stepping right every 6
  DEFB $08,$71,$2E        ; MOVE to 113, 46
  DEFB $8A,$45            ; LINE of 6 pixels right, stepping down every 6
  DEFB $08,$71,$2B        ; MOVE to 113, 43
  DEFB $8A,$45            ; LINE of 6 pixels right, stepping down every 6
  DEFB $00                ; End of the picture

; Picture for location 5: trolls clearing
;
; A border colour and a starting attribute, then 57 moves, 248 lines, 7 fills,
; 1 paint, counting the part it shares with location 28, levelled elvish
; clearing, and ending at the $00 the two have in common.
;
; Runs on into location 28's -- levelled elvish clearing's -- picture rather
; than ending: the last opcode here takes that picture's border and attribute
; bytes as its operands, and from its first opcode on the two are one stream.
LOC5_TROLLS_CLEARING_PIC:
  DEFB $00                ; Border: black
  DEFB $00                ; The canvas starts black paper, black ink
  DEFB $08,$5E,$36        ; MOVE to 94, 54
  DEFB $B2,$59            ; LINE of 26 pixels right, stepping down every 26
  DEFB $87,$02            ; LINE of 3 pixels diagonally down and left
  DEFB $82,$02            ; LINE of 3 pixels diagonally right and down
  DEFB $83,$42            ; LINE of 3 pixels down, stepping right every 2
  DEFB $83,$82            ; LINE of 3 pixels down, stepping right every 3
  DEFB $83,$C2            ; LINE of 3 pixels down, stepping right every 4
  DEFB $87,$82            ; LINE of 3 pixels down, stepping left every 3
  DEFB $87,$42            ; LINE of 3 pixels down, stepping left every 2
  DEFB $87,$02            ; LINE of 3 pixels diagonally down and left
  DEFB $86,$42            ; LINE of 3 pixels left, stepping down every 2
  DEFB $86,$82            ; LINE of 3 pixels left, stepping down every 3
  DEFB $86,$C2            ; LINE of 3 pixels left, stepping down every 4
  DEFB $86,$C2            ; LINE of 3 pixels left, stepping down every 4
  DEFB $08,$5D,$35        ; MOVE to 93, 53
  DEFB $82,$03            ; LINE of 4 pixels diagonally right and down
  DEFB $86,$02            ; LINE of 3 pixels diagonally left and down
  DEFB $87,$42            ; LINE of 3 pixels down, stepping left every 2
  DEFB $87,$82            ; LINE of 3 pixels down, stepping left every 3
  DEFB $83,$82            ; LINE of 3 pixels down, stepping right every 3
  DEFB $83,$82            ; LINE of 3 pixels down, stepping right every 3
  DEFB $83,$42            ; LINE of 3 pixels down, stepping right every 2
  DEFB $83,$02            ; LINE of 3 pixels diagonally down and right
  DEFB $82,$82            ; LINE of 3 pixels right, stepping down every 3
  DEFB $82,$82            ; LINE of 3 pixels right, stepping down every 3
  DEFB $82,$82            ; LINE of 3 pixels right, stepping down every 3
  DEFB $40,$6B,$21        ; FILL with black from 107, 33
  DEFB $40,$6B,$29        ; FILL with black from 107, 41
  DEFB $40,$65,$2F        ; FILL with black from 101, 47
  DEFB $08,$61,$1C        ; MOVE to 97, 28
  DEFB $86,$04            ; LINE of 5 pixels diagonally left and down
  DEFB $80,$C4            ; LINE of 5 pixels right, stepping up every 4
  DEFB $80,$04            ; LINE of 5 pixels diagonally right and up
  DEFB $08,$75,$1C        ; MOVE to 117, 28
  DEFB $82,$04            ; LINE of 5 pixels diagonally right and down
  DEFB $08,$79,$17        ; MOVE to 121, 23
  DEFB $84,$84            ; LINE of 5 pixels left, stepping up every 3
  DEFB $84,$04            ; LINE of 5 pixels diagonally left and up
  DEFB $40,$74,$19        ; FILL with black from 116, 25
  DEFB $40,$60,$19        ; FILL with black from 96, 25
  DEFB $08                ; MOVE to 4, 32 -- its last bytes are the next
                          ; picture's start

; Picture for location 28: levelled elvish clearing
;
; A border colour and a starting attribute, then 51 moves, 218 lines, 2 fills,
; 1 paint, ending at $00.
LOC28_LEVELLED_ELVISH_CLEARING_PIC:
  DEFB $04                ; Border: green
  DEFB $20                ; The canvas starts green paper, black ink
  DEFB $08,$0C,$25        ; MOVE to 12, 37
  DEFB $81,$43            ; LINE of 4 pixels up, stepping right every 2
  DEFB $81,$03            ; LINE of 4 pixels diagonally up and right
  DEFB $88,$03            ; LINE of 4 pixels right, stepping up every 5
  DEFB $82,$03            ; LINE of 4 pixels diagonally right and down
  DEFB $8F,$03            ; LINE of 4 pixels down, stepping left every 5
  DEFB $87,$C3            ; LINE of 4 pixels down, stepping left every 4
  DEFB $86,$43            ; LINE of 4 pixels left, stepping down every 2
  DEFB $86,$C3            ; LINE of 4 pixels left, stepping down every 4
  DEFB $84,$43            ; LINE of 4 pixels left, stepping up every 2
  DEFB $8D,$03            ; LINE of 4 pixels up, stepping left every 5
  DEFB $8D,$44            ; LINE of 5 pixels up, stepping left every 6
  DEFB $08,$15,$2D        ; MOVE to 21, 45
  DEFB $92,$38            ; LINE of 57 pixels right, stepping down every 9
  DEFB $83,$43            ; LINE of 4 pixels down, stepping right every 2
  DEFB $87,$82            ; LINE of 3 pixels down, stepping left every 3
  DEFB $87,$42            ; LINE of 3 pixels down, stepping left every 2
  DEFB $BC,$BC            ; LINE of 61 pixels left, stepping up every 31
  DEFB $08,$B6,$25        ; MOVE to 182, 37
  DEFB $9C,$2B            ; LINE of 44 pixels left, stepping up every 13
  DEFB $86,$42            ; LINE of 3 pixels left, stepping down every 2
  DEFB $87,$42            ; LINE of 3 pixels down, stepping left every 2
  DEFB $83,$42            ; LINE of 3 pixels down, stepping right every 2
  DEFB $82,$42            ; LINE of 3 pixels right, stepping down every 2
  DEFB $8A,$ED            ; LINE of 46 pixels right, stepping down every 8
  DEFB $80,$C4            ; LINE of 5 pixels right, stepping up every 4
  DEFB $81,$44            ; LINE of 5 pixels up, stepping right every 2
  DEFB $85,$02            ; LINE of 3 pixels diagonally up and left
  DEFB $84,$42            ; LINE of 3 pixels left, stepping up every 2
  DEFB $86,$83            ; LINE of 4 pixels left, stepping down every 3
  DEFB $87,$83            ; LINE of 4 pixels down, stepping left every 3
  DEFB $83,$82            ; LINE of 3 pixels down, stepping right every 3
  DEFB $82,$43            ; LINE of 4 pixels right, stepping down every 2
  DEFB $08,$4A,$00        ; MOVE to 74, 0
  DEFB $85,$83            ; LINE of 4 pixels up, stepping left every 3
  DEFB $81,$83            ; LINE of 4 pixels up, stepping right every 3
  DEFB $81,$43            ; LINE of 4 pixels up, stepping right every 2
  DEFB $80,$C3            ; LINE of 4 pixels right, stepping up every 4
  DEFB $83,$03            ; LINE of 4 pixels diagonally down and right
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $8B,$03            ; LINE of 4 pixels down, stepping right every 5
  DEFB $87,$C3            ; LINE of 4 pixels down, stepping left every 4
  DEFB $08,$52,$0C        ; MOVE to 82, 12
  DEFB $F8,$BE            ; LINE of 63 pixels right, stepping up every 63
  DEFB $F8,$BE            ; LINE of 63 pixels right, stepping up every 63
  DEFB $82,$03            ; LINE of 4 pixels diagonally right and down
  DEFB $83,$83            ; LINE of 4 pixels down, stepping right every 3
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $8B,$03            ; LINE of 4 pixels down, stepping right every 5
  DEFB $08,$E2,$09        ; MOVE to 226, 9
  DEFB $83,$03            ; LINE of 4 pixels diagonally down and right
  DEFB $82,$83            ; LINE of 4 pixels right, stepping down every 3
  DEFB $80,$83            ; LINE of 4 pixels right, stepping up every 3
  DEFB $80,$03            ; LINE of 4 pixels diagonally right and up
  DEFB $81,$83            ; LINE of 4 pixels up, stepping right every 3
  DEFB $08,$F2,$09        ; MOVE to 242, 9
  DEFB $81,$83            ; LINE of 4 pixels up, stepping right every 3
  DEFB $81,$83            ; LINE of 4 pixels up, stepping right every 3
  DEFB $81,$C3            ; LINE of 4 pixels up, stepping right every 4
  DEFB $85,$43            ; LINE of 4 pixels up, stepping left every 2
  DEFB $85,$03            ; LINE of 4 pixels diagonally up and left
  DEFB $84,$C3            ; LINE of 4 pixels left, stepping up every 4
  DEFB $86,$C3            ; LINE of 4 pixels left, stepping down every 4
  DEFB $86,$83            ; LINE of 4 pixels left, stepping down every 3
  DEFB $87,$03            ; LINE of 4 pixels diagonally down and left
  DEFB $87,$43            ; LINE of 4 pixels down, stepping left every 2
  DEFB $8F,$03            ; LINE of 4 pixels down, stepping left every 5
  DEFB $83,$83            ; LINE of 4 pixels down, stepping right every 3
  DEFB $82,$03            ; LINE of 4 pixels diagonally right and down
  DEFB $08,$E3,$07        ; MOVE to 227, 7
  DEFB $84,$D0            ; LINE of 17 pixels left, stepping up every 4
  DEFB $08,$CB,$0E        ; MOVE to 203, 14
  DEFB $84,$87            ; LINE of 8 pixels left, stepping up every 3
  DEFB $81,$C3            ; LINE of 4 pixels up, stepping right every 4
  DEFB $81,$C3            ; LINE of 4 pixels up, stepping right every 4
  DEFB $81,$43            ; LINE of 4 pixels up, stepping right every 2
  DEFB $81,$43            ; LINE of 4 pixels up, stepping right every 2
  DEFB $80,$43            ; LINE of 4 pixels right, stepping up every 2
  DEFB $88,$03            ; LINE of 4 pixels right, stepping up every 5
  DEFB $8A,$59            ; LINE of 26 pixels right, stepping down every 6
  DEFB $08,$11,$2E        ; MOVE to 17, 46
  DEFB $8D,$48            ; LINE of 9 pixels up, stepping left every 6
  DEFB $89,$88            ; LINE of 9 pixels up, stepping right every 7
  DEFB $81,$48            ; LINE of 9 pixels up, stepping right every 2
  DEFB $91,$08            ; LINE of 9 pixels up, stepping right every 9
  DEFB $8D,$08            ; LINE of 9 pixels up, stepping left every 5
  DEFB $85,$C8            ; LINE of 9 pixels up, stepping left every 4
  DEFB $8D,$08            ; LINE of 9 pixels up, stepping left every 5
  DEFB $84,$88            ; LINE of 9 pixels left, stepping up every 3
  DEFB $84,$88            ; LINE of 9 pixels left, stepping up every 3
  DEFB $08,$00,$79        ; MOVE to 0, 121
  DEFB $82,$88            ; LINE of 9 pixels right, stepping down every 3
  DEFB $82,$88            ; LINE of 9 pixels right, stepping down every 3
  DEFB $91,$48            ; LINE of 9 pixels up, stepping right every 10
  DEFB $91,$48            ; LINE of 9 pixels up, stepping right every 10
  DEFB $08,$0C,$23        ; MOVE to 12, 35
  DEFB $86,$D0            ; LINE of 17 pixels left, stepping down every 4
  DEFB $08,$24,$2D        ; MOVE to 36, 45
  DEFB $8D,$08            ; LINE of 9 pixels up, stepping left every 5
  DEFB $91,$08            ; LINE of 9 pixels up, stepping right every 9
  DEFB $80,$48            ; LINE of 9 pixels right, stepping up every 2
  DEFB $80,$08            ; LINE of 9 pixels diagonally right and up
  DEFB $81,$48            ; LINE of 9 pixels up, stepping right every 2
  DEFB $83,$48            ; LINE of 9 pixels down, stepping right every 2
  DEFB $83,$88            ; LINE of 9 pixels down, stepping right every 3
  DEFB $8B,$48            ; LINE of 9 pixels down, stepping right every 6
  DEFB $93,$48            ; LINE of 9 pixels down, stepping right every 10
  DEFB $93,$48            ; LINE of 9 pixels down, stepping right every 10
  DEFB $08,$25,$47        ; MOVE to 37, 71
  DEFB $81,$88            ; LINE of 9 pixels up, stepping right every 3
  DEFB $8D,$48            ; LINE of 9 pixels up, stepping left every 6
  DEFB $85,$48            ; LINE of 9 pixels up, stepping left every 2
  DEFB $8D,$08            ; LINE of 9 pixels up, stepping left every 5
  DEFB $85,$C8            ; LINE of 9 pixels up, stepping left every 4
  DEFB $8D,$4F            ; LINE of 16 pixels up, stepping left every 6
  DEFB $8D,$48            ; LINE of 9 pixels up, stepping left every 6
  DEFB $08,$26,$48        ; MOVE to 38, 72
  DEFB $80,$45            ; LINE of 6 pixels right, stepping up every 2
  DEFB $80,$06            ; LINE of 7 pixels diagonally right and up
  DEFB $81,$86            ; LINE of 7 pixels up, stepping right every 3
  DEFB $08,$3A,$56        ; MOVE to 58, 86
  DEFB $84,$46            ; LINE of 7 pixels left, stepping up every 2
  DEFB $85,$C6            ; LINE of 7 pixels up, stepping left every 4
  DEFB $85,$86            ; LINE of 7 pixels up, stepping left every 3
  DEFB $85,$46            ; LINE of 7 pixels up, stepping left every 2
  DEFB $84,$C6            ; LINE of 7 pixels left, stepping up every 4
  DEFB $84,$06            ; LINE of 7 pixels diagonally left and up
  DEFB $08,$4F,$26        ; MOVE to 79, 38
  DEFB $8D,$C6            ; LINE of 7 pixels up, stepping left every 8
  DEFB $8D,$C6            ; LINE of 7 pixels up, stepping left every 8
  DEFB $8D,$C7            ; LINE of 8 pixels up, stepping left every 8
  DEFB $8D,$C8            ; LINE of 9 pixels up, stepping left every 8
  DEFB $9D,$0C            ; LINE of 13 pixels up, stepping left every 13
  DEFB $81,$4C            ; LINE of 13 pixels up, stepping right every 2
  DEFB $81,$4C            ; LINE of 13 pixels up, stepping right every 2
  DEFB $81,$8C            ; LINE of 13 pixels up, stepping right every 3
  DEFB $81,$8C            ; LINE of 13 pixels up, stepping right every 3
  DEFB $08,$57,$7F        ; MOVE to 87, 127
  DEFB $87,$CC            ; LINE of 13 pixels down, stepping left every 4
  DEFB $86,$0C            ; LINE of 13 pixels diagonally left and down
  DEFB $87,$85            ; LINE of 6 pixels down, stepping left every 3
  DEFB $84,$45            ; LINE of 6 pixels left, stepping up every 2
  DEFB $85,$85            ; LINE of 6 pixels up, stepping left every 3
  DEFB $85,$45            ; LINE of 6 pixels up, stepping left every 2
  DEFB $85,$05            ; LINE of 6 pixels diagonally up and left
  DEFB $84,$85            ; LINE of 6 pixels left, stepping up every 3
  DEFB $84,$45            ; LINE of 6 pixels left, stepping up every 2
  DEFB $84,$07            ; LINE of 8 pixels diagonally left and up
  DEFB $08,$50,$27        ; MOVE to 80, 39
  DEFB $C0,$61            ; LINE of 34 pixels right, stepping up every 34
  DEFB $92,$56            ; LINE of 23 pixels right, stepping down every 10
  DEFB $08,$C0,$1F        ; MOVE to 192, 31
  DEFB $82,$46            ; LINE of 7 pixels right, stepping down every 2
  DEFB $08,$F5,$12        ; MOVE to 245, 18
  DEFB $8A,$CD            ; LINE of 14 pixels right, stepping down every 8
  DEFB $08,$89,$29        ; MOVE to 137, 41
  DEFB $95,$8D            ; LINE of 14 pixels up, stepping left every 11
  DEFB $8D,$CD            ; LINE of 14 pixels up, stepping left every 8
  DEFB $85,$CD            ; LINE of 14 pixels up, stepping left every 4
  DEFB $85,$8D            ; LINE of 14 pixels up, stepping left every 3
  DEFB $85,$CD            ; LINE of 14 pixels up, stepping left every 4
  DEFB $8D,$0D            ; LINE of 14 pixels up, stepping left every 5
  DEFB $8D,$0D            ; LINE of 14 pixels up, stepping left every 5
  DEFB $08,$7E,$7F        ; MOVE to 126, 127
  DEFB $8B,$0D            ; LINE of 14 pixels down, stepping right every 5
  DEFB $83,$8D            ; LINE of 14 pixels down, stepping right every 3
  DEFB $89,$0D            ; LINE of 14 pixels up, stepping right every 5
  DEFB $89,$0D            ; LINE of 14 pixels up, stepping right every 5
  DEFB $08,$96,$7F        ; MOVE to 150, 127
  DEFB $8F,$0D            ; LINE of 14 pixels down, stepping left every 5
  DEFB $8F,$CD            ; LINE of 14 pixels down, stepping left every 8
  DEFB $80,$85            ; LINE of 6 pixels right, stepping up every 3
  DEFB $81,$4E            ; LINE of 15 pixels up, stepping right every 2
  DEFB $08,$A2,$73        ; MOVE to 162, 115
  DEFB $87,$8E            ; LINE of 15 pixels down, stepping left every 3
  DEFB $87,$C7            ; LINE of 8 pixels down, stepping left every 4
  DEFB $80,$47            ; LINE of 8 pixels right, stepping up every 2
  DEFB $81,$87            ; LINE of 8 pixels up, stepping right every 3
  DEFB $81,$90            ; LINE of 17 pixels up, stepping right every 3
  DEFB $81,$90            ; LINE of 17 pixels up, stepping right every 3
  DEFB $08,$9D,$27        ; MOVE to 157, 39
  DEFB $89,$D0            ; LINE of 17 pixels up, stepping right every 8
  DEFB $99,$10            ; LINE of 17 pixels up, stepping right every 13
  DEFB $8D,$8B            ; LINE of 12 pixels up, stepping left every 7
  DEFB $81,$06            ; LINE of 7 pixels diagonally up and right
  DEFB $81,$C6            ; LINE of 7 pixels up, stepping right every 4
  DEFB $81,$86            ; LINE of 7 pixels up, stepping right every 3
  DEFB $81,$C6            ; LINE of 7 pixels up, stepping right every 4
  DEFB $81,$86            ; LINE of 7 pixels up, stepping right every 3
  DEFB $81,$86            ; LINE of 7 pixels up, stepping right every 3
  DEFB $08,$EC,$1F        ; MOVE to 236, 31
  DEFB $85,$D6            ; LINE of 23 pixels up, stepping left every 4
  DEFB $85,$96            ; LINE of 23 pixels up, stepping left every 3
  DEFB $8D,$4F            ; LINE of 16 pixels up, stepping left every 6
  DEFB $8D,$0F            ; LINE of 16 pixels up, stepping left every 5
  DEFB $85,$CF            ; LINE of 16 pixels up, stepping left every 4
  DEFB $85,$CF            ; LINE of 16 pixels up, stepping left every 4
  DEFB $08,$E4,$7F        ; MOVE to 228, 127
  DEFB $83,$CF            ; LINE of 16 pixels down, stepping right every 4
  DEFB $83,$8F            ; LINE of 16 pixels down, stepping right every 3
  DEFB $83,$8F            ; LINE of 16 pixels down, stepping right every 3
  DEFB $81,$0F            ; LINE of 16 pixels diagonally up and right
  DEFB $08,$FF,$50        ; MOVE to 255, 80
  DEFB $87,$4B            ; LINE of 12 pixels down, stepping left every 2
  DEFB $83,$CB            ; LINE of 12 pixels down, stepping right every 4
  DEFB $83,$4B            ; LINE of 12 pixels down, stepping right every 2
  DEFB $08,$5F,$2D        ; MOVE to 95, 45
  DEFB $85,$D3            ; LINE of 20 pixels up, stepping left every 4
  DEFB $8D,$13            ; LINE of 20 pixels up, stepping left every 5
  DEFB $A1,$D3            ; LINE of 20 pixels up, stepping right every 20
  DEFB $08,$53,$71        ; MOVE to 83, 113
  DEFB $85,$53            ; LINE of 20 pixels up, stepping left every 2
  DEFB $08,$6A,$2C        ; MOVE to 106, 44
  DEFB $8D,$D3            ; LINE of 20 pixels up, stepping left every 8
  DEFB $9D,$53            ; LINE of 20 pixels up, stepping left every 14
  DEFB $89,$D3            ; LINE of 20 pixels up, stepping right every 8
  DEFB $81,$11            ; LINE of 18 pixels diagonally up and right
  DEFB $08,$65,$70        ; MOVE to 101, 112
  DEFB $80,$11            ; LINE of 18 pixels diagonally right and up
  DEFB $08,$64,$70        ; MOVE to 100, 112
  DEFB $84,$07            ; LINE of 8 pixels diagonally left and up
  DEFB $08,$56,$7C        ; MOVE to 86, 124
  DEFB $84,$07            ; LINE of 8 pixels diagonally left and up
  DEFB $08,$64,$70        ; MOVE to 100, 112
  DEFB $87,$86            ; LINE of 7 pixels down, stepping left every 3
  DEFB $08,$45,$5F        ; MOVE to 69, 95
  DEFB $87,$86            ; LINE of 7 pixels down, stepping left every 3
  DEFB $08,$25,$46        ; MOVE to 37, 70
  DEFB $87,$87            ; LINE of 8 pixels down, stepping left every 3
  DEFB $08,$13,$73        ; MOVE to 19, 115
  DEFB $82,$42            ; LINE of 3 pixels right, stepping down every 2
  DEFB $87,$42            ; LINE of 3 pixels down, stepping left every 2
  DEFB $87,$02            ; LINE of 3 pixels diagonally down and left
  DEFB $08,$84,$65        ; MOVE to 132, 101
  DEFB $83,$89            ; LINE of 10 pixels down, stepping right every 3
  DEFB $08,$93,$62        ; MOVE to 147, 98
  DEFB $83,$86            ; LINE of 7 pixels down, stepping right every 3
  DEFB $88,$06            ; LINE of 7 pixels right, stepping up every 5
  DEFB $08,$F3,$4D        ; MOVE to 243, 77
  DEFB $83,$86            ; LINE of 7 pixels down, stepping right every 3
  DEFB $08,$5F,$2C        ; MOVE to 95, 44
  DEFB $8A,$06            ; LINE of 7 pixels right, stepping down every 5
  DEFB $8A,$04            ; LINE of 5 pixels right, stepping down every 5
  DEFB $08,$B9,$2A        ; MOVE to 185, 42
  DEFB $82,$C4            ; LINE of 5 pixels right, stepping down every 4
  DEFB $82,$84            ; LINE of 5 pixels right, stepping down every 3
  DEFB $82,$C4            ; LINE of 5 pixels right, stepping down every 4
  DEFB $8A,$04            ; LINE of 5 pixels right, stepping down every 5
  DEFB $91,$A2            ; LINE of 35 pixels up, stepping right every 11
  DEFB $8D,$E2            ; LINE of 35 pixels up, stepping left every 8
  DEFB $85,$A2            ; LINE of 35 pixels up, stepping left every 3
  DEFB $08,$B9,$2B        ; MOVE to 185, 43
  DEFB $99,$65            ; LINE of 38 pixels up, stepping right every 14
  DEFB $85,$12            ; LINE of 19 pixels diagonally up and left
  DEFB $08,$A4,$68        ; MOVE to 164, 104
  DEFB $8D,$12            ; LINE of 19 pixels up, stepping left every 5
  DEFB $8D,$12            ; LINE of 19 pixels up, stepping left every 5
  DEFB $08,$C1,$56        ; MOVE to 193, 86
  DEFB $85,$17            ; LINE of 24 pixels diagonally up and left
  DEFB $08,$A7,$70        ; MOVE to 167, 112
  DEFB $95,$71            ; LINE of 50 pixels up, stepping left every 10
  DEFB $08,$BD,$5B        ; MOVE to 189, 91
  DEFB $8D,$9C            ; LINE of 29 pixels up, stepping left every 7
  DEFB $85,$5C            ; LINE of 29 pixels up, stepping left every 2
  DEFB $42,$DB,$06        ; FILL with red from 219, 6
  DEFB $08,$4F,$0F        ; MOVE to 79, 15
  DEFB $B1,$18            ; LINE of 25 pixels up, stepping right every 25
  DEFB $08,$4F,$0F        ; MOVE to 79, 15
  DEFB $F0,$38            ; LINE of 57 pixels right, stepping up every 57
  DEFB $A1,$10            ; LINE of 17 pixels up, stepping right every 17
  DEFB $22,$59,$6A,$15,$06,$17,$00,$15 ; PAINT red ink from row 11, column 10,
  DEFB $FF                             ; along a path of 5 steps
  DEFB $42,$90,$10        ; FILL with red from 144, 16
  DEFB $00                ; End of the picture

; Picture for location 4: lonelands
;
; A border colour and a starting attribute, then 15 moves, 35 lines, 2 fills,
; ending at $00.
LOC4_LONELANDS_PIC:
  DEFB $07                ; Border: white
  DEFB $30                ; The canvas starts yellow paper, black ink
  DEFB $08,$00,$26        ; MOVE to 0, 38
  DEFB $98,$FE            ; LINE of 63 pixels right, stepping up every 16
  DEFB $98,$F2            ; LINE of 51 pixels right, stepping up every 16
  DEFB $84,$07            ; LINE of 8 pixels diagonally left and up
  DEFB $C8,$79            ; LINE of 58 pixels right, stepping up every 38
  DEFB $92,$39            ; LINE of 58 pixels right, stepping down every 9
  DEFB $A0,$78            ; LINE of 57 pixels right, stepping up every 18
  DEFB $08,$65,$2C        ; MOVE to 101, 44
  DEFB $81,$48            ; LINE of 9 pixels up, stepping right every 2
  DEFB $08,$65,$2B        ; MOVE to 101, 43
  DEFB $81,$48            ; LINE of 9 pixels up, stepping right every 2
  DEFB $08,$00,$3F        ; MOVE to 0, 63
  DEFB $88,$FE            ; LINE of 63 pixels right, stepping up every 8
  DEFB $A8,$7E            ; LINE of 63 pixels right, stepping up every 22
  DEFB $A8,$7E            ; LINE of 63 pixels right, stepping up every 22
  DEFB $9A,$FE            ; LINE of 63 pixels right, stepping down every 16
  DEFB $9A,$FE            ; LINE of 63 pixels right, stepping down every 16
  DEFB $08,$FF,$51        ; MOVE to 255, 81
  DEFB $84,$9A            ; LINE of 27 pixels left, stepping up every 3
  DEFB $8C,$DA            ; LINE of 27 pixels left, stepping up every 8
  DEFB $86,$DA            ; LINE of 27 pixels left, stepping down every 4
  DEFB $86,$DA            ; LINE of 27 pixels left, stepping down every 4
  DEFB $08,$A8,$57        ; MOVE to 168, 87
  DEFB $94,$DA            ; LINE of 27 pixels left, stepping up every 12
  DEFB $84,$9A            ; LINE of 27 pixels left, stepping up every 3
  DEFB $8C,$DA            ; LINE of 27 pixels left, stepping up every 8
  DEFB $8E,$5A            ; LINE of 27 pixels left, stepping down every 6
  DEFB $8E,$5A            ; LINE of 27 pixels left, stepping down every 6
  DEFB $96,$5A            ; LINE of 27 pixels left, stepping down every 10
  DEFB $96,$5A            ; LINE of 27 pixels left, stepping down every 10
  DEFB $08,$16,$5D        ; MOVE to 22, 93
  DEFB $84,$9A            ; LINE of 27 pixels left, stepping up every 3
  DEFB $08,$B8,$5A        ; MOVE to 184, 90
  DEFB $84,$9A            ; LINE of 27 pixels left, stepping up every 3
  DEFB $94,$5A            ; LINE of 27 pixels left, stepping up every 10
  DEFB $8E,$9A            ; LINE of 27 pixels left, stepping down every 7
  DEFB $08,$E6,$5A        ; MOVE to 230, 90
  DEFB $88,$DA            ; LINE of 27 pixels right, stepping up every 8
  DEFB $08,$C5,$39        ; MOVE to 197, 57
  DEFB $89,$9A            ; LINE of 27 pixels up, stepping right every 7
  DEFB $08,$C5,$44        ; MOVE to 197, 68
  DEFB $85,$CE            ; LINE of 15 pixels up, stepping left every 4
  DEFB $08,$C8,$4A        ; MOVE to 200, 74
  DEFB $81,$4A            ; LINE of 11 pixels up, stepping right every 2
  DEFB $08,$CB,$4E        ; MOVE to 203, 78
  DEFB $80,$83            ; LINE of 4 pixels right, stepping up every 3
  DEFB $08,$C4,$4E        ; MOVE to 196, 78
  DEFB $81,$83            ; LINE of 4 pixels up, stepping right every 3
  DEFB $08,$C3,$48        ; MOVE to 195, 72
  DEFB $84,$43            ; LINE of 4 pixels left, stepping up every 2
  DEFB $41,$B7,$62        ; FILL with blue from 183, 98
  DEFB $44,$95,$21        ; FILL with green from 149, 33
  DEFB $00                ; End of the picture

; Picture for location 32: elvenkings cellar
;
; A border colour and a starting attribute, then 52 moves, 216 lines, 9 fills,
; ending at $00.
LOC32_ELVENKINGS_CELLAR_PIC:
  DEFB $01                ; Border: blue
  DEFB $08                ; The canvas starts blue paper, black ink
  DEFB $08,$26,$00        ; MOVE to 38, 0
  DEFB $80,$04            ; LINE of 5 pixels diagonally right and up
  DEFB $80,$44            ; LINE of 5 pixels right, stepping up every 2
  DEFB $80,$84            ; LINE of 5 pixels right, stepping up every 3
  DEFB $80,$84            ; LINE of 5 pixels right, stepping up every 3
  DEFB $80,$C4            ; LINE of 5 pixels right, stepping up every 4
  DEFB $80,$C4            ; LINE of 5 pixels right, stepping up every 4
  DEFB $88,$04            ; LINE of 5 pixels right, stepping up every 5
  DEFB $88,$04            ; LINE of 5 pixels right, stepping up every 5
  DEFB $88,$44            ; LINE of 5 pixels right, stepping up every 6
  DEFB $88,$44            ; LINE of 5 pixels right, stepping up every 6
  DEFB $8A,$04            ; LINE of 5 pixels right, stepping down every 5
  DEFB $8A,$04            ; LINE of 5 pixels right, stepping down every 5
  DEFB $82,$C4            ; LINE of 5 pixels right, stepping down every 4
  DEFB $82,$C4            ; LINE of 5 pixels right, stepping down every 4
  DEFB $82,$84            ; LINE of 5 pixels right, stepping down every 3
  DEFB $82,$85            ; LINE of 6 pixels right, stepping down every 3
  DEFB $82,$45            ; LINE of 6 pixels right, stepping down every 2
  DEFB $83,$04            ; LINE of 5 pixels diagonally down and right
  DEFB $08,$73,$09        ; MOVE to 115, 9
  DEFB $89,$14            ; LINE of 21 pixels up, stepping right every 5
  DEFB $81,$03            ; LINE of 4 pixels diagonally up and right
  DEFB $80,$85            ; LINE of 6 pixels right, stepping up every 3
  DEFB $88,$04            ; LINE of 5 pixels right, stepping up every 5
  DEFB $88,$04            ; LINE of 5 pixels right, stepping up every 5
  DEFB $88,$44            ; LINE of 5 pixels right, stepping up every 6
  DEFB $88,$44            ; LINE of 5 pixels right, stepping up every 6
  DEFB $82,$C3            ; LINE of 4 pixels right, stepping down every 4
  DEFB $88,$03            ; LINE of 4 pixels right, stepping up every 5
  DEFB $82,$C3            ; LINE of 4 pixels right, stepping down every 4
  DEFB $8A,$04            ; LINE of 5 pixels right, stepping down every 5
  DEFB $8A,$04            ; LINE of 5 pixels right, stepping down every 5
  DEFB $8A,$04            ; LINE of 5 pixels right, stepping down every 5
  DEFB $82,$84            ; LINE of 5 pixels right, stepping down every 3
  DEFB $83,$43            ; LINE of 4 pixels down, stepping right every 2
  DEFB $87,$43            ; LINE of 4 pixels down, stepping left every 2
  DEFB $86,$84            ; LINE of 5 pixels left, stepping down every 3
  DEFB $86,$C4            ; LINE of 5 pixels left, stepping down every 4
  DEFB $8E,$04            ; LINE of 5 pixels left, stepping down every 5
  DEFB $8E,$04            ; LINE of 5 pixels left, stepping down every 5
  DEFB $8E,$44            ; LINE of 5 pixels left, stepping down every 6
  DEFB $8E,$44            ; LINE of 5 pixels left, stepping down every 6
  DEFB $84,$C4            ; LINE of 5 pixels left, stepping up every 4
  DEFB $84,$C4            ; LINE of 5 pixels left, stepping up every 4
  DEFB $84,$C4            ; LINE of 5 pixels left, stepping up every 4
  DEFB $84,$C4            ; LINE of 5 pixels left, stepping up every 4
  DEFB $84,$C4            ; LINE of 5 pixels left, stepping up every 4
  DEFB $84,$44            ; LINE of 5 pixels left, stepping up every 2
  DEFB $84,$02            ; LINE of 3 pixels diagonally left and up
  DEFB $08,$B7,$1B        ; MOVE to 183, 27
  DEFB $93,$1D            ; LINE of 30 pixels down, stepping right every 9
  DEFB $08,$CD,$28        ; MOVE to 205, 40
  DEFB $82,$C8            ; LINE of 9 pixels right, stepping down every 4
  DEFB $8A,$08            ; LINE of 9 pixels right, stepping down every 5
  DEFB $8A,$89            ; LINE of 10 pixels right, stepping down every 7
  DEFB $90,$49            ; LINE of 10 pixels right, stepping up every 10
  DEFB $88,$CC            ; LINE of 13 pixels right, stepping up every 8
  DEFB $08,$CD,$28        ; MOVE to 205, 40
  DEFB $85,$48            ; LINE of 9 pixels up, stepping left every 2
  DEFB $85,$C8            ; LINE of 9 pixels up, stepping left every 4
  DEFB $8D,$08            ; LINE of 9 pixels up, stepping left every 5
  DEFB $95,$48            ; LINE of 9 pixels up, stepping left every 10
  DEFB $89,$08            ; LINE of 9 pixels up, stepping right every 5
  DEFB $81,$C8            ; LINE of 9 pixels up, stepping right every 4
  DEFB $81,$88            ; LINE of 9 pixels up, stepping right every 3
  DEFB $88,$C7            ; LINE of 8 pixels right, stepping up every 8
  DEFB $90,$08            ; LINE of 9 pixels right, stepping up every 9
  DEFB $90,$48            ; LINE of 9 pixels right, stepping up every 10
  DEFB $92,$08            ; LINE of 9 pixels right, stepping down every 9
  DEFB $92,$08            ; LINE of 9 pixels right, stepping down every 9
  DEFB $92,$08            ; LINE of 9 pixels right, stepping down every 9
  DEFB $08,$CC,$66        ; MOVE to 204, 102
  DEFB $8A,$C8            ; LINE of 9 pixels right, stepping down every 8
  DEFB $92,$08            ; LINE of 9 pixels right, stepping down every 9
  DEFB $92,$48            ; LINE of 9 pixels right, stepping down every 10
  DEFB $92,$48            ; LINE of 9 pixels right, stepping down every 10
  DEFB $90,$08            ; LINE of 9 pixels right, stepping up every 9
  DEFB $90,$08            ; LINE of 9 pixels right, stepping up every 9
  DEFB $08,$C8,$34        ; MOVE to 200, 52
  DEFB $8E,$48            ; LINE of 9 pixels left, stepping down every 6
  DEFB $96,$48            ; LINE of 9 pixels left, stepping down every 10
  DEFB $84,$C8            ; LINE of 9 pixels left, stepping up every 4
  DEFB $85,$48            ; LINE of 9 pixels up, stepping left every 2
  DEFB $8D,$09            ; LINE of 10 pixels up, stepping left every 5
  DEFB $95,$48            ; LINE of 9 pixels up, stepping left every 10
  DEFB $89,$08            ; LINE of 9 pixels up, stepping right every 5
  DEFB $81,$C8            ; LINE of 9 pixels up, stepping right every 4
  DEFB $81,$87            ; LINE of 8 pixels up, stepping right every 3
  DEFB $80,$C8            ; LINE of 9 pixels right, stepping up every 4
  DEFB $88,$45            ; LINE of 6 pixels right, stepping up every 6
  DEFB $8A,$86            ; LINE of 7 pixels right, stepping down every 7
  DEFB $8A,$48            ; LINE of 9 pixels right, stepping down every 6
  DEFB $82,$44            ; LINE of 5 pixels right, stepping down every 2
  DEFB $83,$42            ; LINE of 3 pixels down, stepping right every 2
  DEFB $08,$AD,$6B        ; MOVE to 173, 107
  DEFB $82,$C4            ; LINE of 5 pixels right, stepping down every 4
  DEFB $8A,$04            ; LINE of 5 pixels right, stepping down every 5
  DEFB $8A,$44            ; LINE of 5 pixels right, stepping down every 6
  DEFB $88,$04            ; LINE of 5 pixels right, stepping up every 5
  DEFB $88,$44            ; LINE of 5 pixels right, stepping up every 6
  DEFB $88,$44            ; LINE of 5 pixels right, stepping up every 6
  DEFB $88,$44            ; LINE of 5 pixels right, stepping up every 6
  DEFB $08,$2E,$00        ; MOVE to 46, 0
  DEFB $80,$02            ; LINE of 3 pixels diagonally right and up
  DEFB $80,$C4            ; LINE of 5 pixels right, stepping up every 4
  DEFB $88,$04            ; LINE of 5 pixels right, stepping up every 5
  DEFB $88,$04            ; LINE of 5 pixels right, stepping up every 5
  DEFB $88,$04            ; LINE of 5 pixels right, stepping up every 5
  DEFB $88,$04            ; LINE of 5 pixels right, stepping up every 5
  DEFB $88,$44            ; LINE of 5 pixels right, stepping up every 6
  DEFB $88,$44            ; LINE of 5 pixels right, stepping up every 6
  DEFB $8A,$04            ; LINE of 5 pixels right, stepping down every 5
  DEFB $82,$C4            ; LINE of 5 pixels right, stepping down every 4
  DEFB $82,$C4            ; LINE of 5 pixels right, stepping down every 4
  DEFB $8A,$04            ; LINE of 5 pixels right, stepping down every 5
  DEFB $82,$C4            ; LINE of 5 pixels right, stepping down every 4
  DEFB $82,$84            ; LINE of 5 pixels right, stepping down every 3
  DEFB $82,$44            ; LINE of 5 pixels right, stepping down every 2
  DEFB $40,$7A,$00        ; FILL with black from 122, 0
  DEFB $08,$3A,$00        ; MOVE to 58, 0
  DEFB $81,$04            ; LINE of 5 pixels diagonally up and right
  DEFB $08,$44,$00        ; MOVE to 68, 0
  DEFB $81,$07            ; LINE of 8 pixels diagonally up and right
  DEFB $08,$4F,$00        ; MOVE to 79, 0
  DEFB $81,$07            ; LINE of 8 pixels diagonally up and right
  DEFB $08,$5A,$00        ; MOVE to 90, 0
  DEFB $81,$07            ; LINE of 8 pixels diagonally up and right
  DEFB $08,$66,$00        ; MOVE to 102, 0
  DEFB $81,$07            ; LINE of 8 pixels diagonally up and right
  DEFB $08,$7D,$1A        ; MOVE to 125, 26
  DEFB $81,$83            ; LINE of 4 pixels up, stepping right every 3
  DEFB $80,$43            ; LINE of 4 pixels right, stepping up every 2
  DEFB $80,$83            ; LINE of 4 pixels right, stepping up every 3
  DEFB $80,$C3            ; LINE of 4 pixels right, stepping up every 4
  DEFB $88,$03            ; LINE of 4 pixels right, stepping up every 5
  DEFB $88,$03            ; LINE of 4 pixels right, stepping up every 5
  DEFB $88,$03            ; LINE of 4 pixels right, stepping up every 5
  DEFB $82,$C3            ; LINE of 4 pixels right, stepping down every 4
  DEFB $82,$C3            ; LINE of 4 pixels right, stepping down every 4
  DEFB $8A,$03            ; LINE of 4 pixels right, stepping down every 5
  DEFB $82,$C3            ; LINE of 4 pixels right, stepping down every 4
  DEFB $82,$C3            ; LINE of 4 pixels right, stepping down every 4
  DEFB $82,$C3            ; LINE of 4 pixels right, stepping down every 4
  DEFB $82,$43            ; LINE of 4 pixels right, stepping down every 2
  DEFB $87,$83            ; LINE of 4 pixels down, stepping left every 3
  DEFB $40,$B4,$1B        ; FILL with black from 180, 27
  DEFB $08,$87,$18        ; MOVE to 135, 24
  DEFB $85,$07            ; LINE of 8 pixels diagonally up and left
  DEFB $08,$92,$16        ; MOVE to 146, 22
  DEFB $85,$0A            ; LINE of 11 pixels diagonally up and left
  DEFB $08,$9C,$15        ; MOVE to 156, 21
  DEFB $85,$0D            ; LINE of 14 pixels diagonally up and left
  DEFB $08,$A6,$17        ; MOVE to 166, 23
  DEFB $85,$0D            ; LINE of 14 pixels diagonally up and left
  DEFB $08,$AF,$17        ; MOVE to 175, 23
  DEFB $85,$0D            ; LINE of 14 pixels diagonally up and left
  DEFB $40,$B6,$6B        ; FILL with black from 182, 107
  DEFB $40,$EA,$68        ; FILL with black from 234, 104
  DEFB $08,$7C,$05        ; MOVE to 124, 5
  DEFB $89,$94            ; LINE of 21 pixels up, stepping right every 7
  DEFB $08,$86,$00        ; MOVE to 134, 0
  DEFB $89,$D6            ; LINE of 23 pixels up, stepping right every 8
  DEFB $08,$94,$00        ; MOVE to 148, 0
  DEFB $99,$D4            ; LINE of 21 pixels up, stepping right every 16
  DEFB $08,$A3,$00        ; MOVE to 163, 0
  DEFB $9D,$D4            ; LINE of 21 pixels up, stepping left every 16
  DEFB $08,$AF,$00        ; MOVE to 175, 0
  DEFB $95,$15            ; LINE of 22 pixels up, stepping left every 9
  DEFB $08,$B1,$35        ; MOVE to 177, 53
  DEFB $85,$88            ; LINE of 9 pixels up, stepping left every 3
  DEFB $8D,$08            ; LINE of 9 pixels up, stepping left every 5
  DEFB $95,$08            ; LINE of 9 pixels up, stepping left every 9
  DEFB $89,$48            ; LINE of 9 pixels up, stepping right every 6
  DEFB $81,$C8            ; LINE of 9 pixels up, stepping right every 4
  DEFB $81,$C8            ; LINE of 9 pixels up, stepping right every 4
  DEFB $08,$B8,$34        ; MOVE to 184, 52
  DEFB $8D,$08            ; LINE of 9 pixels up, stepping left every 5
  DEFB $8D,$48            ; LINE of 9 pixels up, stepping left every 6
  DEFB $95,$08            ; LINE of 9 pixels up, stepping left every 9
  DEFB $95,$48            ; LINE of 9 pixels up, stepping left every 10
  DEFB $89,$48            ; LINE of 9 pixels up, stepping right every 6
  DEFB $81,$C7            ; LINE of 8 pixels up, stepping right every 4
  DEFB $08,$C0,$34        ; MOVE to 192, 52
  DEFB $B5,$18            ; LINE of 25 pixels up, stepping left every 25
  DEFB $B5,$DB            ; LINE of 28 pixels up, stepping left every 28
  DEFB $08,$C8,$60        ; MOVE to 200, 96
  DEFB $8D,$C9            ; LINE of 10 pixels up, stepping left every 8
  DEFB $08,$CD,$68        ; MOVE to 205, 104
  DEFB $85,$02            ; LINE of 3 pixels diagonally up and left
  DEFB $08,$D3,$28        ; MOVE to 211, 40
  DEFB $85,$46            ; LINE of 7 pixels up, stepping left every 2
  DEFB $85,$86            ; LINE of 7 pixels up, stepping left every 3
  DEFB $85,$C6            ; LINE of 7 pixels up, stepping left every 4
  DEFB $8D,$06            ; LINE of 7 pixels up, stepping left every 5
  DEFB $8D,$86            ; LINE of 7 pixels up, stepping left every 7
  DEFB $89,$46            ; LINE of 7 pixels up, stepping right every 6
  DEFB $89,$06            ; LINE of 7 pixels up, stepping right every 5
  DEFB $81,$86            ; LINE of 7 pixels up, stepping right every 3
  DEFB $81,$86            ; LINE of 7 pixels up, stepping right every 3
  DEFB $08,$DC,$26        ; MOVE to 220, 38
  DEFB $85,$86            ; LINE of 7 pixels up, stepping left every 3
  DEFB $85,$C6            ; LINE of 7 pixels up, stepping left every 4
  DEFB $85,$C6            ; LINE of 7 pixels up, stepping left every 4
  DEFB $8D,$46            ; LINE of 7 pixels up, stepping left every 6
  DEFB $8D,$C6            ; LINE of 7 pixels up, stepping left every 8
  DEFB $89,$86            ; LINE of 7 pixels up, stepping right every 7
  DEFB $89,$86            ; LINE of 7 pixels up, stepping right every 7
  DEFB $89,$46            ; LINE of 7 pixels up, stepping right every 6
  DEFB $81,$C6            ; LINE of 7 pixels up, stepping right every 4
  DEFB $08,$EC,$25        ; MOVE to 236, 37
  DEFB $BD,$FE            ; LINE of 63 pixels up, stepping left every 32
  DEFB $08,$FC,$27        ; MOVE to 252, 39
  DEFB $91,$0F            ; LINE of 16 pixels up, stepping right every 9
  DEFB $A1,$0F            ; LINE of 16 pixels up, stepping right every 17
  DEFB $95,$0F            ; LINE of 16 pixels up, stepping left every 9
  DEFB $8D,$4E            ; LINE of 15 pixels up, stepping left every 6
  DEFB $08,$00,$23        ; MOVE to 0, 35
  DEFB $8A,$BE            ; LINE of 63 pixels right, stepping down every 7
  DEFB $80,$B5            ; LINE of 54 pixels right, stepping up every 3
  DEFB $08,$00,$24        ; MOVE to 0, 36
  DEFB $80,$B4            ; LINE of 53 pixels right, stepping up every 3
  DEFB $8A,$7E            ; LINE of 63 pixels right, stepping down every 6
  DEFB $08,$37,$35        ; MOVE to 55, 53
  DEFB $93,$CB            ; LINE of 12 pixels down, stepping right every 12
  DEFB $86,$9D            ; LINE of 30 pixels left, stepping down every 3
  DEFB $08,$37,$29        ; MOVE to 55, 41
  DEFB $8A,$62            ; LINE of 35 pixels right, stepping down every 6
  DEFB $08,$00,$25        ; MOVE to 0, 37
  DEFB $80,$B5            ; LINE of 54 pixels right, stepping up every 3
  DEFB $81,$9F            ; LINE of 32 pixels up, stepping right every 3
  DEFB $86,$F3            ; LINE of 52 pixels left, stepping down every 4
  DEFB $87,$A4            ; LINE of 37 pixels down, stepping left every 3
  DEFB $08,$0D,$4A        ; MOVE to 13, 74
  DEFB $85,$06            ; LINE of 7 pixels diagonally up and left
  DEFB $87,$9B            ; LINE of 28 pixels down, stepping left every 3
  DEFB $08,$07,$52        ; MOVE to 7, 82
  DEFB $80,$F2            ; LINE of 51 pixels right, stepping up every 4
  DEFB $83,$07            ; LINE of 8 pixels diagonally down and right
  DEFB $08,$1E,$30        ; MOVE to 30, 48
  DEFB $81,$A0            ; LINE of 33 pixels up, stepping right every 3
  DEFB $08,$29,$52        ; MOVE to 41, 82
  DEFB $84,$06            ; LINE of 7 pixels diagonally left and up
  DEFB $08,$0F,$2B        ; MOVE to 15, 43
  DEFB $81,$A3            ; LINE of 36 pixels up, stepping right every 3
  DEFB $84,$05            ; LINE of 6 pixels diagonally left and up
  DEFB $08,$2B,$34        ; MOVE to 43, 52
  DEFB $81,$A0            ; LINE of 33 pixels up, stepping right every 3
  DEFB $85,$07            ; LINE of 8 pixels diagonally up and left
  DEFB $08,$2A,$5B        ; MOVE to 42, 91
  DEFB $8D,$0C            ; LINE of 13 pixels up, stepping left every 5
  DEFB $08,$3A,$40        ; MOVE to 58, 64
  DEFB $80,$F6            ; LINE of 55 pixels right, stepping up every 4
  DEFB $E1,$B6            ; LINE of 55 pixels up, stepping right every 51
  DEFB $08,$71,$4D        ; MOVE to 113, 77
  DEFB $92,$76            ; LINE of 55 pixels right, stepping down every 10
  DEFB $08,$27,$68        ; MOVE to 39, 104
  DEFB $8E,$36            ; LINE of 55 pixels left, stepping down every 5
  DEFB $40,$22,$5D        ; FILL with black from 34, 93
  DEFB $45,$42,$23        ; FILL with cyan from 66, 35
  DEFB $08,$CE,$28        ; MOVE to 206, 40
  DEFB $8C,$12            ; LINE of 19 pixels left, stepping up every 5
  DEFB $84,$CC            ; LINE of 13 pixels left, stepping up every 4
  DEFB $84,$4C            ; LINE of 13 pixels left, stepping up every 2
  DEFB $84,$48            ; LINE of 9 pixels left, stepping up every 2
  DEFB $80,$88            ; LINE of 9 pixels right, stepping up every 3
  DEFB $80,$C8            ; LINE of 9 pixels right, stepping up every 4
  DEFB $40,$C5,$2F        ; FILL with black from 197, 47
  DEFB $08,$A5,$3D        ; MOVE to 165, 61
  DEFB $84,$48            ; LINE of 9 pixels left, stepping up every 2
  DEFB $84,$48            ; LINE of 9 pixels left, stepping up every 2
  DEFB $80,$89            ; LINE of 10 pixels right, stepping up every 3
  DEFB $40,$A5,$45        ; FILL with black from 165, 69
  DEFB $08,$74,$17        ; MOVE to 116, 23
  DEFB $86,$88            ; LINE of 9 pixels left, stepping down every 3
  DEFB $86,$48            ; LINE of 9 pixels left, stepping down every 2
  DEFB $86,$48            ; LINE of 9 pixels left, stepping down every 2
  DEFB $40,$6C,$0C        ; FILL with black from 108, 12
  DEFB $00                ; End of the picture

; Picture for location 16: big goblins cavern
;
; A border colour and a starting attribute, then 52 moves, 284 lines, 17 fills,
; ending at $00.
LOC16_BIG_GOBLINS_CAVERN_PIC:
  DEFB $06                ; Border: yellow
  DEFB $30                ; The canvas starts yellow paper, black ink
  DEFB $08,$70,$37        ; MOVE to 112, 55
  DEFB $81,$82            ; LINE of 3 pixels up, stepping right every 3
  DEFB $81,$42            ; LINE of 3 pixels up, stepping right every 2
  DEFB $81,$02            ; LINE of 3 pixels diagonally up and right
  DEFB $80,$42            ; LINE of 3 pixels right, stepping up every 2
  DEFB $80,$82            ; LINE of 3 pixels right, stepping up every 3
  DEFB $80,$C2            ; LINE of 3 pixels right, stepping up every 4
  DEFB $08,$8B,$37        ; MOVE to 139, 55
  DEFB $85,$82            ; LINE of 3 pixels up, stepping left every 3
  DEFB $85,$42            ; LINE of 3 pixels up, stepping left every 2
  DEFB $85,$02            ; LINE of 3 pixels diagonally up and left
  DEFB $84,$42            ; LINE of 3 pixels left, stepping up every 2
  DEFB $84,$82            ; LINE of 3 pixels left, stepping up every 3
  DEFB $84,$C2            ; LINE of 3 pixels left, stepping up every 4
  DEFB $08,$70,$36        ; MOVE to 112, 54
  DEFB $83,$82            ; LINE of 3 pixels down, stepping right every 3
  DEFB $83,$42            ; LINE of 3 pixels down, stepping right every 2
  DEFB $83,$02            ; LINE of 3 pixels diagonally down and right
  DEFB $82,$42            ; LINE of 3 pixels right, stepping down every 2
  DEFB $82,$82            ; LINE of 3 pixels right, stepping down every 3
  DEFB $82,$C2            ; LINE of 3 pixels right, stepping down every 4
  DEFB $08,$8B,$36        ; MOVE to 139, 54
  DEFB $87,$82            ; LINE of 3 pixels down, stepping left every 3
  DEFB $87,$42            ; LINE of 3 pixels down, stepping left every 2
  DEFB $87,$02            ; LINE of 3 pixels diagonally down and left
  DEFB $86,$42            ; LINE of 3 pixels left, stepping down every 2
  DEFB $86,$82            ; LINE of 3 pixels left, stepping down every 3
  DEFB $86,$C2            ; LINE of 3 pixels left, stepping down every 4
  DEFB $08,$65,$41        ; MOVE to 101, 65
  DEFB $89,$C7            ; LINE of 8 pixels up, stepping right every 8
  DEFB $81,$87            ; LINE of 8 pixels up, stepping right every 3
  DEFB $81,$04            ; LINE of 5 pixels diagonally up and right
  DEFB $80,$44            ; LINE of 5 pixels right, stepping up every 2
  DEFB $80,$84            ; LINE of 5 pixels right, stepping up every 3
  DEFB $80,$84            ; LINE of 5 pixels right, stepping up every 3
  DEFB $80,$C4            ; LINE of 5 pixels right, stepping up every 4
  DEFB $88,$04            ; LINE of 5 pixels right, stepping up every 5
  DEFB $08,$A0,$41        ; MOVE to 160, 65
  DEFB $8D,$C7            ; LINE of 8 pixels up, stepping left every 8
  DEFB $85,$87            ; LINE of 8 pixels up, stepping left every 3
  DEFB $85,$04            ; LINE of 5 pixels diagonally up and left
  DEFB $84,$44            ; LINE of 5 pixels left, stepping up every 2
  DEFB $84,$84            ; LINE of 5 pixels left, stepping up every 3
  DEFB $84,$84            ; LINE of 5 pixels left, stepping up every 3
  DEFB $84,$84            ; LINE of 5 pixels left, stepping up every 3
  DEFB $08,$65,$40        ; MOVE to 101, 64
  DEFB $93,$08            ; LINE of 9 pixels down, stepping right every 9
  DEFB $83,$88            ; LINE of 9 pixels down, stepping right every 3
  DEFB $82,$05            ; LINE of 6 pixels diagonally right and down
  DEFB $82,$43            ; LINE of 4 pixels right, stepping down every 2
  DEFB $08,$A0,$40        ; MOVE to 160, 64
  DEFB $97,$49            ; LINE of 10 pixels down, stepping left every 10
  DEFB $87,$88            ; LINE of 9 pixels down, stepping left every 3
  DEFB $87,$05            ; LINE of 6 pixels diagonally down and left
  DEFB $86,$46            ; LINE of 7 pixels left, stepping down every 2
  DEFB $8E,$4A            ; LINE of 11 pixels left, stepping down every 6
  DEFB $08,$42,$40        ; MOVE to 66, 64
  DEFB $91,$CB            ; LINE of 12 pixels up, stepping right every 12
  DEFB $81,$C9            ; LINE of 10 pixels up, stepping right every 4
  DEFB $81,$49            ; LINE of 10 pixels up, stepping right every 2
  DEFB $80,$09            ; LINE of 10 pixels diagonally right and up
  DEFB $80,$49            ; LINE of 10 pixels right, stepping up every 2
  DEFB $80,$89            ; LINE of 10 pixels right, stepping up every 3
  DEFB $80,$C9            ; LINE of 10 pixels right, stepping up every 4
  DEFB $88,$09            ; LINE of 10 pixels right, stepping up every 5
  DEFB $90,$89            ; LINE of 10 pixels right, stepping up every 11
  DEFB $08,$C3,$3F        ; MOVE to 195, 63
  DEFB $9D,$0C            ; LINE of 13 pixels up, stepping left every 13
  DEFB $85,$CB            ; LINE of 12 pixels up, stepping left every 4
  DEFB $85,$49            ; LINE of 10 pixels up, stepping left every 2
  DEFB $85,$08            ; LINE of 9 pixels diagonally up and left
  DEFB $84,$48            ; LINE of 9 pixels left, stepping up every 2
  DEFB $84,$88            ; LINE of 9 pixels left, stepping up every 3
  DEFB $84,$C8            ; LINE of 9 pixels left, stepping up every 4
  DEFB $8C,$08            ; LINE of 9 pixels left, stepping up every 5
  DEFB $8C,$08            ; LINE of 9 pixels left, stepping up every 5
  DEFB $08,$42,$3F        ; MOVE to 66, 63
  DEFB $93,$08            ; LINE of 9 pixels down, stepping right every 9
  DEFB $83,$C8            ; LINE of 9 pixels down, stepping right every 4
  DEFB $83,$48            ; LINE of 9 pixels down, stepping right every 2
  DEFB $83,$08            ; LINE of 9 pixels diagonally down and right
  DEFB $82,$43            ; LINE of 4 pixels right, stepping down every 2
  DEFB $08,$C3,$3E        ; MOVE to 195, 62
  DEFB $97,$08            ; LINE of 9 pixels down, stepping left every 9
  DEFB $87,$88            ; LINE of 9 pixels down, stepping left every 3
  DEFB $87,$48            ; LINE of 9 pixels down, stepping left every 2
  DEFB $87,$08            ; LINE of 9 pixels diagonally down and left
  DEFB $86,$48            ; LINE of 9 pixels left, stepping down every 2
  DEFB $86,$88            ; LINE of 9 pixels left, stepping down every 3
  DEFB $86,$C5            ; LINE of 6 pixels left, stepping down every 4
  DEFB $08,$13,$41        ; MOVE to 19, 65
  DEFB $95,$48            ; LINE of 9 pixels up, stepping left every 10
  DEFB $81,$C8            ; LINE of 9 pixels up, stepping right every 4
  DEFB $81,$48            ; LINE of 9 pixels up, stepping right every 2
  DEFB $81,$48            ; LINE of 9 pixels up, stepping right every 2
  DEFB $81,$08            ; LINE of 9 pixels diagonally up and right
  DEFB $80,$48            ; LINE of 9 pixels right, stepping up every 2
  DEFB $80,$48            ; LINE of 9 pixels right, stepping up every 2
  DEFB $80,$88            ; LINE of 9 pixels right, stepping up every 3
  DEFB $80,$C8            ; LINE of 9 pixels right, stepping up every 4
  DEFB $80,$C8            ; LINE of 9 pixels right, stepping up every 4
  DEFB $88,$08            ; LINE of 9 pixels right, stepping up every 5
  DEFB $88,$08            ; LINE of 9 pixels right, stepping up every 5
  DEFB $08,$F0,$41        ; MOVE to 240, 65
  DEFB $95,$48            ; LINE of 9 pixels up, stepping left every 10
  DEFB $85,$C8            ; LINE of 9 pixels up, stepping left every 4
  DEFB $85,$48            ; LINE of 9 pixels up, stepping left every 2
  DEFB $85,$48            ; LINE of 9 pixels up, stepping left every 2
  DEFB $85,$08            ; LINE of 9 pixels diagonally up and left
  DEFB $84,$48            ; LINE of 9 pixels left, stepping up every 2
  DEFB $84,$48            ; LINE of 9 pixels left, stepping up every 2
  DEFB $84,$88            ; LINE of 9 pixels left, stepping up every 3
  DEFB $84,$C8            ; LINE of 9 pixels left, stepping up every 4
  DEFB $8C,$08            ; LINE of 9 pixels left, stepping up every 5
  DEFB $8C,$48            ; LINE of 9 pixels left, stepping up every 6
  DEFB $8C,$48            ; LINE of 9 pixels left, stepping up every 6
  DEFB $8C,$48            ; LINE of 9 pixels left, stepping up every 6
  DEFB $08,$13,$40        ; MOVE to 19, 64
  DEFB $8B,$C8            ; LINE of 9 pixels down, stepping right every 8
  DEFB $8B,$08            ; LINE of 9 pixels down, stepping right every 5
  DEFB $83,$88            ; LINE of 9 pixels down, stepping right every 3
  DEFB $83,$48            ; LINE of 9 pixels down, stepping right every 2
  DEFB $83,$10            ; LINE of 17 pixels diagonally down and right
  DEFB $08,$F0,$40        ; MOVE to 240, 64
  DEFB $8F,$48            ; LINE of 9 pixels down, stepping left every 6
  DEFB $8F,$08            ; LINE of 9 pixels down, stepping left every 5
  DEFB $87,$88            ; LINE of 9 pixels down, stepping left every 3
  DEFB $87,$48            ; LINE of 9 pixels down, stepping left every 2
  DEFB $87,$08            ; LINE of 9 pixels diagonally down and left
  DEFB $86,$48            ; LINE of 9 pixels left, stepping down every 2
  DEFB $86,$48            ; LINE of 9 pixels left, stepping down every 2
  DEFB $86,$88            ; LINE of 9 pixels left, stepping down every 3
  DEFB $86,$88            ; LINE of 9 pixels left, stepping down every 3
  DEFB $8E,$04            ; LINE of 5 pixels left, stepping down every 5
  DEFB $08,$71,$37        ; MOVE to 113, 55
  DEFB $81,$02            ; LINE of 3 pixels diagonally up and right
  DEFB $80,$42            ; LINE of 3 pixels right, stepping up every 2
  DEFB $80,$82            ; LINE of 3 pixels right, stepping up every 3
  DEFB $82,$42            ; LINE of 3 pixels right, stepping down every 2
  DEFB $82,$02            ; LINE of 3 pixels diagonally right and down
  DEFB $83,$42            ; LINE of 3 pixels down, stepping right every 2
  DEFB $83,$82            ; LINE of 3 pixels down, stepping right every 3
  DEFB $87,$42            ; LINE of 3 pixels down, stepping left every 2
  DEFB $87,$02            ; LINE of 3 pixels diagonally down and left
  DEFB $08,$07,$00        ; MOVE to 7, 0
  DEFB $80,$BE            ; LINE of 63 pixels right, stepping up every 3
  DEFB $80,$90            ; LINE of 17 pixels right, stepping up every 3
  DEFB $80,$5B            ; LINE of 28 pixels right, stepping up every 2
  DEFB $81,$03            ; LINE of 4 pixels diagonally up and right
  DEFB $08,$C1,$00        ; MOVE to 193, 0
  DEFB $84,$64            ; LINE of 37 pixels left, stepping up every 2
  DEFB $84,$4D            ; LINE of 14 pixels left, stepping up every 2
  DEFB $84,$09            ; LINE of 10 pixels diagonally left and up
  DEFB $85,$07            ; LINE of 8 pixels diagonally up and left
  DEFB $08,$72,$31        ; MOVE to 114, 49
  DEFB $81,$43            ; LINE of 4 pixels up, stepping right every 2
  DEFB $80,$41            ; LINE of 2 pixels right, stepping up every 2
  DEFB $82,$41            ; LINE of 2 pixels right, stepping down every 2
  DEFB $83,$01            ; LINE of 2 pixels diagonally down and right
  DEFB $87,$81            ; LINE of 2 pixels down, stepping left every 3
  DEFB $83,$81            ; LINE of 2 pixels down, stepping right every 3
  DEFB $87,$02            ; LINE of 3 pixels diagonally down and left
  DEFB $40,$74,$33        ; FILL with black from 116, 51
  DEFB $08,$0C,$52        ; MOVE to 12, 82
  DEFB $81,$D5            ; LINE of 22 pixels up, stepping right every 4
  DEFB $82,$C8            ; LINE of 9 pixels right, stepping down every 4
  DEFB $87,$57            ; LINE of 24 pixels down, stepping left every 2
  DEFB $85,$44            ; LINE of 5 pixels up, stepping left every 2
  DEFB $40,$0F,$53        ; FILL with black from 15, 83
  DEFB $08,$12,$69        ; MOVE to 18, 105
  DEFB $85,$43            ; LINE of 4 pixels up, stepping left every 2
  DEFB $81,$C3            ; LINE of 4 pixels up, stepping right every 4
  DEFB $81,$43            ; LINE of 4 pixels up, stepping right every 2
  DEFB $81,$03            ; LINE of 4 pixels diagonally up and right
  DEFB $81,$43            ; LINE of 4 pixels up, stepping right every 2
  DEFB $83,$83            ; LINE of 4 pixels down, stepping right every 3
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $8B,$03            ; LINE of 4 pixels down, stepping right every 5
  DEFB $83,$83            ; LINE of 4 pixels down, stepping right every 3
  DEFB $83,$83            ; LINE of 4 pixels down, stepping right every 3
  DEFB $87,$03            ; LINE of 4 pixels diagonally down and left
  DEFB $08,$11,$6A        ; MOVE to 17, 106
  DEFB $85,$03            ; LINE of 4 pixels diagonally up and left
  DEFB $8D,$03            ; LINE of 4 pixels up, stepping left every 5
  DEFB $8D,$03            ; LINE of 4 pixels up, stepping left every 5
  DEFB $81,$83            ; LINE of 4 pixels up, stepping right every 3
  DEFB $81,$03            ; LINE of 4 pixels diagonally up and right
  DEFB $81,$03            ; LINE of 4 pixels diagonally up and right
  DEFB $08,$1B,$66        ; MOVE to 27, 102
  DEFB $81,$03            ; LINE of 4 pixels diagonally up and right
  DEFB $81,$43            ; LINE of 4 pixels up, stepping right every 2
  DEFB $81,$43            ; LINE of 4 pixels up, stepping right every 2
  DEFB $81,$83            ; LINE of 4 pixels up, stepping right every 3
  DEFB $81,$C3            ; LINE of 4 pixels up, stepping right every 4
  DEFB $85,$83            ; LINE of 4 pixels up, stepping left every 3
  DEFB $85,$83            ; LINE of 4 pixels up, stepping left every 3
  DEFB $08,$2C,$4F        ; MOVE to 44, 79
  DEFB $81,$D2            ; LINE of 19 pixels up, stepping right every 4
  DEFB $82,$C7            ; LINE of 8 pixels right, stepping down every 4
  DEFB $87,$54            ; LINE of 21 pixels down, stepping left every 2
  DEFB $85,$44            ; LINE of 5 pixels up, stepping left every 2
  DEFB $40,$2E,$4F        ; FILL with black from 46, 79
  DEFB $08,$31,$62        ; MOVE to 49, 98
  DEFB $85,$43            ; LINE of 4 pixels up, stepping left every 2
  DEFB $85,$C3            ; LINE of 4 pixels up, stepping left every 4
  DEFB $81,$83            ; LINE of 4 pixels up, stepping right every 3
  DEFB $81,$43            ; LINE of 4 pixels up, stepping right every 2
  DEFB $83,$43            ; LINE of 4 pixels down, stepping right every 2
  DEFB $83,$43            ; LINE of 4 pixels down, stepping right every 2
  DEFB $83,$43            ; LINE of 4 pixels down, stepping right every 2
  DEFB $82,$43            ; LINE of 4 pixels right, stepping down every 2
  DEFB $87,$44            ; LINE of 5 pixels down, stepping left every 2
  DEFB $08,$30,$63        ; MOVE to 48, 99
  DEFB $85,$03            ; LINE of 4 pixels diagonally up and left
  DEFB $8D,$03            ; LINE of 4 pixels up, stepping left every 5
  DEFB $8D,$03            ; LINE of 4 pixels up, stepping left every 5
  DEFB $81,$83            ; LINE of 4 pixels up, stepping right every 3
  DEFB $81,$03            ; LINE of 4 pixels diagonally up and right
  DEFB $82,$43            ; LINE of 4 pixels right, stepping down every 2
  DEFB $08,$38,$60        ; MOVE to 56, 96
  DEFB $81,$43            ; LINE of 4 pixels up, stepping right every 2
  DEFB $81,$43            ; LINE of 4 pixels up, stepping right every 2
  DEFB $89,$03            ; LINE of 4 pixels up, stepping right every 5
  DEFB $84,$83            ; LINE of 4 pixels left, stepping up every 3
  DEFB $85,$83            ; LINE of 4 pixels up, stepping left every 3
  DEFB $85,$43            ; LINE of 4 pixels up, stepping left every 2
  DEFB $08,$AB,$4B        ; MOVE to 171, 75
  DEFB $8D,$4D            ; LINE of 14 pixels up, stepping left every 6
  DEFB $80,$C4            ; LINE of 5 pixels right, stepping up every 4
  DEFB $8F,$11            ; LINE of 18 pixels down, stepping left every 5
  DEFB $40,$AC,$51        ; FILL with black from 172, 81
  DEFB $08,$A9,$5A        ; MOVE to 169, 90
  DEFB $85,$43            ; LINE of 4 pixels up, stepping left every 2
  DEFB $81,$83            ; LINE of 4 pixels up, stepping right every 3
  DEFB $81,$43            ; LINE of 4 pixels up, stepping right every 2
  DEFB $81,$43            ; LINE of 4 pixels up, stepping right every 2
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $83,$83            ; LINE of 4 pixels down, stepping right every 3
  DEFB $83,$43            ; LINE of 4 pixels down, stepping right every 2
  DEFB $87,$43            ; LINE of 4 pixels down, stepping left every 2
  DEFB $08,$A8,$58        ; MOVE to 168, 88
  DEFB $85,$03            ; LINE of 4 pixels diagonally up and left
  DEFB $8D,$03            ; LINE of 4 pixels up, stepping left every 5
  DEFB $81,$C3            ; LINE of 4 pixels up, stepping right every 4
  DEFB $81,$43            ; LINE of 4 pixels up, stepping right every 2
  DEFB $81,$03            ; LINE of 4 pixels diagonally up and right
  DEFB $81,$03            ; LINE of 4 pixels diagonally up and right
  DEFB $08,$AF,$59        ; MOVE to 175, 89
  DEFB $81,$03            ; LINE of 4 pixels diagonally up and right
  DEFB $81,$83            ; LINE of 4 pixels up, stepping right every 3
  DEFB $81,$C3            ; LINE of 4 pixels up, stepping right every 4
  DEFB $85,$43            ; LINE of 4 pixels up, stepping left every 2
  DEFB $85,$83            ; LINE of 4 pixels up, stepping left every 3
  DEFB $84,$44            ; LINE of 5 pixels left, stepping up every 2
  DEFB $08,$D6,$4B        ; MOVE to 214, 75
  DEFB $85,$51            ; LINE of 18 pixels up, stepping left every 2
  DEFB $80,$C6            ; LINE of 7 pixels right, stepping up every 4
  DEFB $83,$D5            ; LINE of 22 pixels down, stepping right every 4
  DEFB $84,$04            ; LINE of 5 pixels diagonally left and up
  DEFB $40,$D3,$57        ; FILL with black from 211, 87
  DEFB $08,$CE,$5D        ; MOVE to 206, 93
  DEFB $8D,$03            ; LINE of 4 pixels up, stepping left every 5
  DEFB $81,$83            ; LINE of 4 pixels up, stepping right every 3
  DEFB $81,$03            ; LINE of 4 pixels diagonally up and right
  DEFB $81,$43            ; LINE of 4 pixels up, stepping right every 2
  DEFB $83,$83            ; LINE of 4 pixels down, stepping right every 3
  DEFB $87,$C3            ; LINE of 4 pixels down, stepping left every 4
  DEFB $83,$83            ; LINE of 4 pixels down, stepping right every 3
  DEFB $87,$83            ; LINE of 4 pixels down, stepping left every 3
  DEFB $08,$CD,$5D        ; MOVE to 205, 93
  DEFB $85,$03            ; LINE of 4 pixels diagonally up and left
  DEFB $81,$83            ; LINE of 4 pixels up, stepping right every 3
  DEFB $81,$43            ; LINE of 4 pixels up, stepping right every 2
  DEFB $81,$43            ; LINE of 4 pixels up, stepping right every 2
  DEFB $81,$43            ; LINE of 4 pixels up, stepping right every 2
  DEFB $81,$03            ; LINE of 4 pixels diagonally up and right
  DEFB $08,$D6,$5E        ; MOVE to 214, 94
  DEFB $81,$03            ; LINE of 4 pixels diagonally up and right
  DEFB $81,$83            ; LINE of 4 pixels up, stepping right every 3
  DEFB $81,$83            ; LINE of 4 pixels up, stepping right every 3
  DEFB $81,$C3            ; LINE of 4 pixels up, stepping right every 4
  DEFB $85,$43            ; LINE of 4 pixels up, stepping left every 2
  DEFB $84,$03            ; LINE of 4 pixels diagonally left and up
  DEFB $86,$43            ; LINE of 4 pixels left, stepping down every 2
  DEFB $08,$58,$4F        ; MOVE to 88, 79
  DEFB $81,$CC            ; LINE of 13 pixels up, stepping right every 4
  DEFB $82,$C4            ; LINE of 5 pixels right, stepping down every 4
  DEFB $87,$4E            ; LINE of 15 pixels down, stepping left every 2
  DEFB $85,$83            ; LINE of 4 pixels up, stepping left every 3
  DEFB $40,$5B,$57        ; FILL with black from 91, 87
  DEFB $08,$5C,$5D        ; MOVE to 92, 93
  DEFB $85,$43            ; LINE of 4 pixels up, stepping left every 2
  DEFB $81,$C3            ; LINE of 4 pixels up, stepping right every 4
  DEFB $81,$03            ; LINE of 4 pixels diagonally up and right
  DEFB $81,$43            ; LINE of 4 pixels up, stepping right every 2
  DEFB $81,$C3            ; LINE of 4 pixels up, stepping right every 4
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $8B,$03            ; LINE of 4 pixels down, stepping right every 5
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $87,$83            ; LINE of 4 pixels down, stepping left every 3
  DEFB $86,$43            ; LINE of 4 pixels left, stepping down every 2
  DEFB $08,$5C,$5D        ; MOVE to 92, 93
  DEFB $85,$03            ; LINE of 4 pixels diagonally up and left
  DEFB $81,$C3            ; LINE of 4 pixels up, stepping right every 4
  DEFB $81,$C3            ; LINE of 4 pixels up, stepping right every 4
  DEFB $81,$43            ; LINE of 4 pixels up, stepping right every 2
  DEFB $81,$43            ; LINE of 4 pixels up, stepping right every 2
  DEFB $81,$43            ; LINE of 4 pixels up, stepping right every 2
  DEFB $08,$62,$5C        ; MOVE to 98, 92
  DEFB $81,$03            ; LINE of 4 pixels diagonally up and right
  DEFB $81,$43            ; LINE of 4 pixels up, stepping right every 2
  DEFB $81,$43            ; LINE of 4 pixels up, stepping right every 2
  DEFB $85,$43            ; LINE of 4 pixels up, stepping left every 2
  DEFB $85,$43            ; LINE of 4 pixels up, stepping left every 2
  DEFB $85,$83            ; LINE of 4 pixels up, stepping left every 3
  DEFB $85,$03            ; LINE of 4 pixels diagonally up and left
  DEFB $87,$43            ; LINE of 4 pixels down, stepping left every 2
  DEFB $42,$D9,$6A        ; FILL with red from 217, 106
  DEFB $42,$B0,$61        ; FILL with red from 176, 97
  DEFB $42,$67,$68        ; FILL with red from 103, 104
  DEFB $42,$5D,$6B        ; FILL with red from 93, 107
  DEFB $08,$0E,$5F        ; MOVE to 14, 95
  DEFB $85,$05            ; LINE of 6 pixels diagonally up and left
  DEFB $08,$0E,$60        ; MOVE to 14, 96
  DEFB $85,$05            ; LINE of 6 pixels diagonally up and left
  DEFB $08,$0F,$61        ; MOVE to 15, 97
  DEFB $84,$05            ; LINE of 6 pixels diagonally left and up
  DEFB $08,$58,$56        ; MOVE to 88, 86
  DEFB $85,$05            ; LINE of 6 pixels diagonally up and left
  DEFB $08,$58,$57        ; MOVE to 88, 87
  DEFB $85,$03            ; LINE of 4 pixels diagonally up and left
  DEFB $08,$59,$58        ; MOVE to 89, 88
  DEFB $85,$03            ; LINE of 4 pixels diagonally up and left
  DEFB $08,$AD,$50        ; MOVE to 173, 80
  DEFB $80,$45            ; LINE of 6 pixels right, stepping up every 2
  DEFB $08,$AE,$51        ; MOVE to 174, 81
  DEFB $80,$45            ; LINE of 6 pixels right, stepping up every 2
  DEFB $08,$D7,$56        ; MOVE to 215, 86
  DEFB $80,$05            ; LINE of 6 pixels diagonally right and up
  DEFB $08,$D6,$57        ; MOVE to 214, 87
  DEFB $80,$05            ; LINE of 6 pixels diagonally right and up
  DEFB $08,$2D,$5A        ; MOVE to 45, 90
  DEFB $84,$45            ; LINE of 6 pixels left, stepping up every 2
  DEFB $08,$2E,$5B        ; MOVE to 46, 91
  DEFB $84,$45            ; LINE of 6 pixels left, stepping up every 2
  DEFB $42,$D6,$74        ; FILL with red from 214, 116
  DEFB $42,$AF,$6D        ; FILL with red from 175, 109
  DEFB $42,$63,$75        ; FILL with red from 99, 117
  DEFB $42,$31,$75        ; FILL with red from 49, 117
  DEFB $42,$35,$71        ; FILL with red from 53, 113
  DEFB $42,$2D,$70        ; FILL with red from 45, 112
  DEFB $42,$21,$75        ; FILL with red from 33, 117
  DEFB $00                ; End of the picture

; Picture for location 25: bewitched gloomy place
;
; A border colour and a starting attribute, then 40 moves, 215 lines, 11 fills,
; 1 paint, ending at $00.
LOC25_BEWITCHED_GLOOMY_PLACE_PIC:
  DEFB $01                ; Border: blue
  DEFB $08                ; The canvas starts blue paper, black ink
  DEFB $08,$32,$00        ; MOVE to 50, 0
  DEFB $85,$12            ; LINE of 19 pixels diagonally up and left
  DEFB $84,$CE            ; LINE of 15 pixels left, stepping up every 4
  DEFB $85,$10            ; LINE of 17 pixels diagonally up and left
  DEFB $08,$00,$2D        ; MOVE to 0, 45
  DEFB $82,$0F            ; LINE of 16 pixels diagonally right and down
  DEFB $9D,$DF            ; LINE of 32 pixels up, stepping left every 16
  DEFB $85,$1B            ; LINE of 28 pixels diagonally up and left
  DEFB $08,$00,$50        ; MOVE to 0, 80
  DEFB $82,$08            ; LINE of 9 pixels diagonally right and down
  DEFB $82,$55            ; LINE of 22 pixels right, stepping down every 2
  DEFB $85,$DF            ; LINE of 32 pixels up, stepping left every 4
  DEFB $84,$08            ; LINE of 9 pixels diagonally left and up
  DEFB $85,$88            ; LINE of 9 pixels up, stepping left every 3
  DEFB $82,$54            ; LINE of 21 pixels right, stepping down every 2
  DEFB $83,$D6            ; LINE of 23 pixels down, stepping right every 4
  DEFB $81,$CF            ; LINE of 16 pixels up, stepping right every 4
  DEFB $81,$0D            ; LINE of 14 pixels diagonally up and right
  DEFB $8B,$14            ; LINE of 21 pixels down, stepping right every 5
  DEFB $82,$85            ; LINE of 6 pixels right, stepping down every 3
  DEFB $82,$45            ; LINE of 6 pixels right, stepping down every 2
  DEFB $83,$85            ; LINE of 6 pixels down, stepping right every 3
  DEFB $83,$C5            ; LINE of 6 pixels down, stepping right every 4
  DEFB $8F,$05            ; LINE of 6 pixels down, stepping left every 5
  DEFB $87,$8B            ; LINE of 12 pixels down, stepping left every 3
  DEFB $87,$4B            ; LINE of 12 pixels down, stepping left every 2
  DEFB $83,$15            ; LINE of 22 pixels diagonally down and right
  DEFB $81,$54            ; LINE of 21 pixels up, stepping right every 2
  DEFB $81,$94            ; LINE of 21 pixels up, stepping right every 3
  DEFB $81,$CB            ; LINE of 12 pixels up, stepping right every 4
  DEFB $95,$0B            ; LINE of 12 pixels up, stepping left every 9
  DEFB $84,$0B            ; LINE of 12 pixels diagonally left and up
  DEFB $84,$4B            ; LINE of 12 pixels left, stepping up every 2
  DEFB $84,$8B            ; LINE of 12 pixels left, stepping up every 3
  DEFB $84,$CC            ; LINE of 13 pixels left, stepping up every 4
  DEFB $08,$20,$1C        ; MOVE to 32, 28
  DEFB $8D,$D3            ; LINE of 20 pixels up, stepping left every 8
  DEFB $84,$C4            ; LINE of 5 pixels left, stepping up every 4
  DEFB $84,$04            ; LINE of 5 pixels diagonally left and up
  DEFB $93,$19            ; LINE of 26 pixels down, stepping right every 9
  DEFB $8A,$4A            ; LINE of 11 pixels right, stepping down every 6
  DEFB $08,$33,$2A        ; MOVE to 51, 42
  DEFB $85,$4A            ; LINE of 11 pixels up, stepping left every 2
  DEFB $85,$47            ; LINE of 8 pixels up, stepping left every 2
  DEFB $89,$4E            ; LINE of 15 pixels up, stepping right every 6
  DEFB $81,$CA            ; LINE of 11 pixels up, stepping right every 4
  DEFB $81,$47            ; LINE of 8 pixels up, stepping right every 2
  DEFB $83,$CA            ; LINE of 11 pixels down, stepping right every 4
  DEFB $83,$4A            ; LINE of 11 pixels down, stepping right every 2
  DEFB $82,$04            ; LINE of 5 pixels diagonally right and down
  DEFB $8B,$44            ; LINE of 5 pixels down, stepping right every 6
  DEFB $87,$C4            ; LINE of 5 pixels down, stepping left every 4
  DEFB $87,$48            ; LINE of 9 pixels down, stepping left every 2
  DEFB $87,$06            ; LINE of 7 pixels diagonally down and left
  DEFB $08,$61,$00        ; MOVE to 97, 0
  DEFB $81,$9D            ; LINE of 30 pixels up, stepping right every 3
  DEFB $81,$91            ; LINE of 18 pixels up, stepping right every 3
  DEFB $80,$CB            ; LINE of 12 pixels right, stepping up every 4
  DEFB $80,$8B            ; LINE of 12 pixels right, stepping up every 3
  DEFB $88,$0A            ; LINE of 11 pixels right, stepping up every 5
  DEFB $80,$48            ; LINE of 9 pixels right, stepping up every 2
  DEFB $80,$08            ; LINE of 9 pixels diagonally right and up
  DEFB $80,$08            ; LINE of 9 pixels diagonally right and up
  DEFB $84,$C3            ; LINE of 4 pixels left, stepping up every 4
  DEFB $86,$48            ; LINE of 9 pixels left, stepping down every 2
  DEFB $86,$03            ; LINE of 4 pixels diagonally left and down
  DEFB $86,$03            ; LINE of 4 pixels diagonally left and down
  DEFB $86,$87            ; LINE of 8 pixels left, stepping down every 3
  DEFB $86,$47            ; LINE of 8 pixels left, stepping down every 2
  DEFB $86,$96            ; LINE of 23 pixels left, stepping down every 3
  DEFB $89,$D6            ; LINE of 23 pixels up, stepping right every 8
  DEFB $85,$C6            ; LINE of 7 pixels up, stepping left every 4
  DEFB $81,$50            ; LINE of 17 pixels up, stepping right every 2
  DEFB $81,$8E            ; LINE of 15 pixels up, stepping right every 3
  DEFB $87,$06            ; LINE of 7 pixels diagonally down and left
  DEFB $87,$46            ; LINE of 7 pixels down, stepping left every 2
  DEFB $85,$D9            ; LINE of 26 pixels up, stepping left every 4
  DEFB $08,$6F,$7F        ; MOVE to 111, 127
  DEFB $8B,$19            ; LINE of 26 pixels down, stepping right every 5
  DEFB $87,$47            ; LINE of 8 pixels down, stepping left every 2
  DEFB $84,$0A            ; LINE of 11 pixels diagonally left and up
  DEFB $84,$92            ; LINE of 19 pixels left, stepping up every 3
  DEFB $81,$92            ; LINE of 19 pixels up, stepping right every 3
  DEFB $08,$55,$7F        ; MOVE to 85, 127
  DEFB $87,$50            ; LINE of 17 pixels down, stepping left every 2
  DEFB $8C,$A4            ; LINE of 37 pixels left, stepping up every 7
  DEFB $82,$50            ; LINE of 17 pixels right, stepping down every 2
  DEFB $40,$2F,$71        ; FILL with black from 47, 113
  DEFB $08,$D3,$26        ; MOVE to 211, 38
  DEFB $95,$8E            ; LINE of 15 pixels up, stepping left every 11
  DEFB $8C,$C8            ; LINE of 9 pixels left, stepping up every 8
  DEFB $85,$46            ; LINE of 7 pixels up, stepping left every 2
  DEFB $84,$4D            ; LINE of 14 pixels left, stepping up every 2
  DEFB $8C,$8D            ; LINE of 14 pixels left, stepping up every 7
  DEFB $84,$47            ; LINE of 8 pixels left, stepping up every 2
  DEFB $84,$07            ; LINE of 8 pixels diagonally left and up
  DEFB $82,$C7            ; LINE of 8 pixels right, stepping down every 4
  DEFB $82,$47            ; LINE of 8 pixels right, stepping down every 2
  DEFB $82,$87            ; LINE of 8 pixels right, stepping down every 3
  DEFB $82,$C7            ; LINE of 8 pixels right, stepping down every 4
  DEFB $84,$07            ; LINE of 8 pixels diagonally left and up
  DEFB $84,$07            ; LINE of 8 pixels diagonally left and up
  DEFB $82,$47            ; LINE of 8 pixels right, stepping down every 2
  DEFB $82,$07            ; LINE of 8 pixels diagonally right and down
  DEFB $82,$47            ; LINE of 8 pixels right, stepping down every 2
  DEFB $82,$87            ; LINE of 8 pixels right, stepping down every 3
  DEFB $83,$46            ; LINE of 7 pixels down, stepping right every 2
  DEFB $8A,$04            ; LINE of 5 pixels right, stepping down every 5
  DEFB $89,$0D            ; LINE of 14 pixels up, stepping right every 5
  DEFB $85,$08            ; LINE of 9 pixels diagonally up and left
  DEFB $84,$88            ; LINE of 9 pixels left, stepping up every 3
  DEFB $84,$88            ; LINE of 9 pixels left, stepping up every 3
  DEFB $84,$C8            ; LINE of 9 pixels left, stepping up every 4
  DEFB $88,$08            ; LINE of 9 pixels right, stepping up every 5
  DEFB $82,$88            ; LINE of 9 pixels right, stepping down every 3
  DEFB $8A,$08            ; LINE of 9 pixels right, stepping down every 5
  DEFB $81,$51            ; LINE of 18 pixels up, stepping right every 2
  DEFB $85,$54            ; LINE of 21 pixels up, stepping left every 2
  DEFB $08,$CF,$7F        ; MOVE to 207, 127
  DEFB $83,$54            ; LINE of 21 pixels down, stepping right every 2
  DEFB $87,$92            ; LINE of 19 pixels down, stepping left every 3
  DEFB $82,$4E            ; LINE of 15 pixels right, stepping down every 2
  DEFB $81,$53            ; LINE of 20 pixels up, stepping right every 2
  DEFB $91,$49            ; LINE of 10 pixels up, stepping right every 10
  DEFB $80,$C2            ; LINE of 3 pixels right, stepping up every 4
  DEFB $93,$4F            ; LINE of 16 pixels down, stepping right every 10
  DEFB $82,$86            ; LINE of 7 pixels right, stepping down every 3
  DEFB $83,$86            ; LINE of 7 pixels down, stepping right every 3
  DEFB $8F,$86            ; LINE of 7 pixels down, stepping left every 7
  DEFB $87,$49            ; LINE of 10 pixels down, stepping left every 2
  DEFB $86,$0C            ; LINE of 13 pixels diagonally left and down
  DEFB $8F,$D2            ; LINE of 19 pixels down, stepping left every 8
  DEFB $86,$86            ; LINE of 7 pixels left, stepping down every 3
  DEFB $86,$C6            ; LINE of 7 pixels left, stepping down every 4
  DEFB $86,$46            ; LINE of 7 pixels left, stepping down every 2
  DEFB $87,$03            ; LINE of 4 pixels diagonally down and left
  DEFB $89,$03            ; LINE of 4 pixels up, stepping right every 5
  DEFB $81,$83            ; LINE of 4 pixels up, stepping right every 3
  DEFB $80,$45            ; LINE of 6 pixels right, stepping up every 2
  DEFB $80,$00            ; LINE of 1 pixel diagonally right and up
  DEFB $08,$E4,$3E        ; MOVE to 228, 62
  DEFB $89,$CB            ; LINE of 12 pixels up, stepping right every 8
  DEFB $81,$47            ; LINE of 8 pixels up, stepping right every 2
  DEFB $81,$04            ; LINE of 5 pixels diagonally up and right
  DEFB $81,$43            ; LINE of 4 pixels up, stepping right every 2
  DEFB $83,$03            ; LINE of 4 pixels diagonally down and right
  DEFB $8B,$03            ; LINE of 4 pixels down, stepping right every 5
  DEFB $87,$47            ; LINE of 8 pixels down, stepping left every 2
  DEFB $87,$0D            ; LINE of 14 pixels diagonally down and left
  DEFB $40,$D1,$21        ; FILL with black from 209, 33
  DEFB $40,$A0,$4F        ; FILL with black from 160, 79
  DEFB $08,$7F,$18        ; MOVE to 127, 24
  DEFB $81,$46            ; LINE of 7 pixels up, stepping right every 2
  DEFB $8D,$09            ; LINE of 10 pixels up, stepping left every 5
  DEFB $84,$90            ; LINE of 17 pixels left, stepping up every 3
  DEFB $8C,$10            ; LINE of 17 pixels left, stepping up every 5
  DEFB $8C,$47            ; LINE of 8 pixels left, stepping up every 6
  DEFB $85,$C3            ; LINE of 4 pixels up, stepping left every 4
  DEFB $8A,$0E            ; LINE of 15 pixels right, stepping down every 5
  DEFB $08,$77,$31        ; MOVE to 119, 49
  DEFB $82,$8A            ; LINE of 11 pixels right, stepping down every 3
  DEFB $81,$C6            ; LINE of 7 pixels up, stepping right every 4
  DEFB $08,$7F,$17        ; MOVE to 127, 23
  DEFB $80,$C8            ; LINE of 9 pixels right, stepping up every 4
  DEFB $82,$85            ; LINE of 6 pixels right, stepping down every 3
  DEFB $89,$07            ; LINE of 8 pixels up, stepping right every 5
  DEFB $8D,$47            ; LINE of 8 pixels up, stepping left every 6
  DEFB $85,$44            ; LINE of 5 pixels up, stepping left every 2
  DEFB $81,$86            ; LINE of 7 pixels up, stepping right every 3
  DEFB $80,$86            ; LINE of 7 pixels right, stepping up every 3
  DEFB $80,$46            ; LINE of 7 pixels right, stepping up every 2
  DEFB $82,$8D            ; LINE of 14 pixels right, stepping down every 3
  DEFB $8A,$07            ; LINE of 8 pixels right, stepping down every 5
  DEFB $8B,$07            ; LINE of 8 pixels down, stepping right every 5
  DEFB $8F,$87            ; LINE of 8 pixels down, stepping left every 7
  DEFB $82,$C7            ; LINE of 8 pixels right, stepping down every 4
  DEFB $81,$87            ; LINE of 8 pixels up, stepping right every 3
  DEFB $81,$07            ; LINE of 8 pixels diagonally up and right
  DEFB $81,$48            ; LINE of 9 pixels up, stepping right every 2
  DEFB $08,$C6,$3B        ; MOVE to 198, 59
  DEFB $87,$48            ; LINE of 9 pixels down, stepping left every 2
  DEFB $86,$46            ; LINE of 7 pixels left, stepping down every 2
  DEFB $85,$86            ; LINE of 7 pixels up, stepping left every 3
  DEFB $85,$C6            ; LINE of 7 pixels up, stepping left every 4
  DEFB $8D,$86            ; LINE of 7 pixels up, stepping left every 7
  DEFB $08,$B3,$44        ; MOVE to 179, 68
  DEFB $8F,$46            ; LINE of 7 pixels down, stepping left every 6
  DEFB $8F,$06            ; LINE of 7 pixels down, stepping left every 5
  DEFB $8C,$06            ; LINE of 7 pixels left, stepping up every 5
  DEFB $8C,$06            ; LINE of 7 pixels left, stepping up every 5
  DEFB $85,$46            ; LINE of 7 pixels up, stepping left every 2
  DEFB $40,$9C,$3B        ; FILL with black from 156, 59
  DEFB $40,$58,$34        ; FILL with black from 88, 52
  DEFB $08,$58,$34        ; MOVE to 88, 52
  DEFB $85,$46            ; LINE of 7 pixels up, stepping left every 2
  DEFB $08,$85,$3D        ; MOVE to 133, 61
  DEFB $84,$45            ; LINE of 6 pixels left, stepping up every 2
  DEFB $8D,$4B            ; LINE of 12 pixels up, stepping left every 6
  DEFB $86,$08            ; LINE of 9 pixels diagonally left and down
  DEFB $08,$76,$4B        ; MOVE to 118, 75
  DEFB $81,$08            ; LINE of 9 pixels diagonally up and right
  DEFB $83,$46            ; LINE of 7 pixels down, stepping right every 2
  DEFB $83,$88            ; LINE of 9 pixels down, stepping right every 3
  DEFB $82,$49            ; LINE of 10 pixels right, stepping down every 2
  DEFB $08,$96,$44        ; MOVE to 150, 68
  DEFB $95,$09            ; LINE of 10 pixels up, stepping left every 9
  DEFB $95,$09            ; LINE of 10 pixels up, stepping left every 9
  DEFB $82,$43            ; LINE of 4 pixels right, stepping down every 2
  DEFB $08,$94,$58        ; MOVE to 148, 88
  DEFB $82,$43            ; LINE of 4 pixels right, stepping down every 2
  DEFB $8B,$0A            ; LINE of 11 pixels down, stepping right every 5
  DEFB $83,$4A            ; LINE of 11 pixels down, stepping right every 2
  DEFB $40,$98,$4C        ; FILL with black from 152, 76
  DEFB $40,$80,$4C        ; FILL with black from 128, 76
  DEFB $08,$B4,$4B        ; MOVE to 180, 75
  DEFB $81,$CA            ; LINE of 11 pixels up, stepping right every 4
  DEFB $80,$47            ; LINE of 8 pixels right, stepping up every 2
  DEFB $87,$47            ; LINE of 8 pixels down, stepping left every 2
  DEFB $87,$C7            ; LINE of 8 pixels down, stepping left every 4
  DEFB $40,$B5,$4A        ; FILL with black from 181, 74
  DEFB $40,$B8,$51        ; FILL with black from 184, 81
  DEFB $08,$B1,$5D        ; MOVE to 177, 93
  DEFB $84,$52            ; LINE of 19 pixels left, stepping up every 2
  DEFB $08,$96,$56        ; MOVE to 150, 86
  DEFB $84,$12            ; LINE of 19 pixels diagonally left and up
  DEFB $08,$7B,$6F        ; MOVE to 123, 111
  DEFB $80,$12            ; LINE of 19 pixels diagonally right and up
  DEFB $08,$29,$73        ; MOVE to 41, 115
  DEFB $84,$92            ; LINE of 19 pixels left, stepping up every 3
  DEFB $08,$18,$69        ; MOVE to 24, 105
  DEFB $84,$92            ; LINE of 19 pixels left, stepping up every 3
  DEFB $08,$7E,$4F        ; MOVE to 126, 79
  DEFB $99,$12            ; LINE of 19 pixels up, stepping right every 13
  DEFB $08,$A9,$4F        ; MOVE to 169, 79
  DEFB $81,$83            ; LINE of 4 pixels up, stepping right every 3
  DEFB $08,$AB,$58        ; MOVE to 171, 88
  DEFB $81,$83            ; LINE of 4 pixels up, stepping right every 3
  DEFB $08,$ED,$6F        ; MOVE to 237, 111
  DEFB $81,$86            ; LINE of 7 pixels up, stepping right every 3
  DEFB $08,$00,$27        ; MOVE to 0, 39
  DEFB $88,$9F            ; LINE of 32 pixels right, stepping up every 7
  DEFB $88,$9F            ; LINE of 32 pixels right, stepping up every 7
  DEFB $AA,$63            ; LINE of 36 pixels right, stepping down every 22
  DEFB $08,$8D,$2E        ; MOVE to 141, 46
  DEFB $AA,$63            ; LINE of 36 pixels right, stepping down every 22
  DEFB $B2,$A3            ; LINE of 36 pixels right, stepping down every 27
  DEFB $08,$E6,$2C        ; MOVE to 230, 44
  DEFB $B2,$A8            ; LINE of 41 pixels right, stepping down every 27
  DEFB $08,$BE,$7F        ; MOVE to 190, 127
  DEFB $83,$45            ; LINE of 6 pixels down, stepping right every 2
  DEFB $83,$05            ; LINE of 6 pixels diagonally down and right
  DEFB $82,$47            ; LINE of 8 pixels right, stepping down every 2
  DEFB $08,$CF,$70        ; MOVE to 207, 112
  DEFB $8D,$47            ; LINE of 8 pixels up, stepping left every 6
  DEFB $08,$CD,$77        ; MOVE to 205, 119
  DEFB $8E,$45            ; LINE of 6 pixels left, stepping down every 6
  DEFB $08,$C7,$77        ; MOVE to 199, 119
  DEFB $95,$4B            ; LINE of 12 pixels up, stepping left every 10
  DEFB $42,$C3,$7B        ; FILL with red from 195, 123
  DEFB $08,$D8,$71        ; MOVE to 216, 113
  DEFB $9D,$8F            ; LINE of 16 pixels up, stepping left every 15
  DEFB $08,$E6,$7F        ; MOVE to 230, 127
  DEFB $87,$87            ; LINE of 8 pixels down, stepping left every 3
  DEFB $87,$04            ; LINE of 5 pixels diagonally down and left
  DEFB $86,$86            ; LINE of 7 pixels left, stepping down every 3
  DEFB $42,$DE,$73        ; FILL with red from 222, 115
  DEFB $22,$58,$19,$01,$06,$FF ; PAINT red ink from row 0, column 25, along a
                               ; path of 2 steps
  DEFB $00                ; End of the picture

; Picture for location 8: running river
;
; A border colour and a starting attribute, then 34 moves, 190 lines, 5 fills,
; 2 paints, ending at $00.
LOC8_RUNNING_RIVER_PIC:
  DEFB $04                ; Border: green
  DEFB $20                ; The canvas starts green paper, black ink
  DEFB $08,$5F,$7F        ; MOVE to 95, 127
  DEFB $AB,$66            ; LINE of 39 pixels down, stepping right every 22
  DEFB $92,$9F            ; LINE of 32 pixels right, stepping down every 11
  DEFB $81,$43            ; LINE of 4 pixels up, stepping right every 2
  DEFB $82,$C9            ; LINE of 10 pixels right, stepping down every 4
  DEFB $8A,$49            ; LINE of 10 pixels right, stepping down every 6
  DEFB $83,$43            ; LINE of 4 pixels down, stepping right every 2
  DEFB $82,$C3            ; LINE of 4 pixels right, stepping down every 4
  DEFB $83,$02            ; LINE of 3 pixels diagonally down and right
  DEFB $87,$82            ; LINE of 3 pixels down, stepping left every 3
  DEFB $86,$42            ; LINE of 3 pixels left, stepping down every 2
  DEFB $8E,$32            ; LINE of 51 pixels left, stepping down every 5
  DEFB $86,$85            ; LINE of 6 pixels left, stepping down every 3
  DEFB $86,$02            ; LINE of 3 pixels diagonally left and down
  DEFB $87,$8F            ; LINE of 16 pixels down, stepping left every 3
  DEFB $8B,$07            ; LINE of 8 pixels down, stepping right every 5
  DEFB $87,$87            ; LINE of 8 pixels down, stepping left every 3
  DEFB $86,$07            ; LINE of 8 pixels diagonally left and down
  DEFB $86,$47            ; LINE of 8 pixels left, stepping down every 2
  DEFB $86,$13            ; LINE of 20 pixels diagonally left and down
  DEFB $08,$76,$7F        ; MOVE to 118, 127
  DEFB $9B,$62            ; LINE of 35 pixels down, stepping right every 14
  DEFB $B2,$E2            ; LINE of 35 pixels right, stepping down every 28
  DEFB $8A,$59            ; LINE of 26 pixels right, stepping down every 6
  DEFB $82,$47            ; LINE of 8 pixels right, stepping down every 2
  DEFB $83,$44            ; LINE of 5 pixels down, stepping right every 2
  DEFB $87,$44            ; LINE of 5 pixels down, stepping left every 2
  DEFB $86,$44            ; LINE of 5 pixels left, stepping down every 2
  DEFB $86,$51            ; LINE of 18 pixels left, stepping down every 2
  DEFB $86,$03            ; LINE of 4 pixels diagonally left and down
  DEFB $87,$43            ; LINE of 4 pixels down, stepping left every 2
  DEFB $8F,$0A            ; LINE of 11 pixels down, stepping left every 5
  DEFB $83,$44            ; LINE of 5 pixels down, stepping right every 2
  DEFB $82,$44            ; LINE of 5 pixels right, stepping down every 2
  DEFB $82,$44            ; LINE of 5 pixels right, stepping down every 2
  DEFB $8B,$04            ; LINE of 5 pixels down, stepping right every 5
  DEFB $87,$04            ; LINE of 5 pixels diagonally down and left
  DEFB $87,$04            ; LINE of 5 pixels diagonally down and left
  DEFB $83,$84            ; LINE of 5 pixels down, stepping right every 3
  DEFB $83,$44            ; LINE of 5 pixels down, stepping right every 2
  DEFB $82,$48            ; LINE of 9 pixels right, stepping down every 2
  DEFB $82,$08            ; LINE of 9 pixels diagonally right and down
  DEFB $08,$7F,$55        ; MOVE to 127, 85
  DEFB $86,$44            ; LINE of 5 pixels left, stepping down every 2
  DEFB $87,$43            ; LINE of 4 pixels down, stepping left every 2
  DEFB $82,$43            ; LINE of 4 pixels right, stepping down every 2
  DEFB $8A,$4A            ; LINE of 11 pixels right, stepping down every 6
  DEFB $90,$0A            ; LINE of 11 pixels right, stepping up every 9
  DEFB $80,$C6            ; LINE of 7 pixels right, stepping up every 4
  DEFB $85,$86            ; LINE of 7 pixels up, stepping left every 3
  DEFB $08,$5A,$15        ; MOVE to 90, 21
  DEFB $80,$04            ; LINE of 5 pixels diagonally right and up
  DEFB $81,$43            ; LINE of 4 pixels up, stepping right every 2
  DEFB $80,$43            ; LINE of 4 pixels right, stepping up every 2
  DEFB $80,$C3            ; LINE of 4 pixels right, stepping up every 4
  DEFB $82,$C3            ; LINE of 4 pixels right, stepping down every 4
  DEFB $82,$C3            ; LINE of 4 pixels right, stepping down every 4
  DEFB $82,$43            ; LINE of 4 pixels right, stepping down every 2
  DEFB $83,$03            ; LINE of 4 pixels diagonally down and right
  DEFB $87,$83            ; LINE of 4 pixels down, stepping left every 3
  DEFB $86,$83            ; LINE of 4 pixels left, stepping down every 3
  DEFB $86,$C3            ; LINE of 4 pixels left, stepping down every 4
  DEFB $86,$C3            ; LINE of 4 pixels left, stepping down every 4
  DEFB $86,$C3            ; LINE of 4 pixels left, stepping down every 4
  DEFB $8E,$03            ; LINE of 4 pixels left, stepping down every 5
  DEFB $8E,$03            ; LINE of 4 pixels left, stepping down every 5
  DEFB $84,$83            ; LINE of 4 pixels left, stepping up every 3
  DEFB $85,$02            ; LINE of 3 pixels diagonally up and left
  DEFB $08,$90,$19        ; MOVE to 144, 25
  DEFB $84,$44            ; LINE of 5 pixels left, stepping up every 2
  DEFB $80,$02            ; LINE of 3 pixels diagonally right and up
  DEFB $80,$42            ; LINE of 3 pixels right, stepping up every 2
  DEFB $80,$82            ; LINE of 3 pixels right, stepping up every 3
  DEFB $80,$82            ; LINE of 3 pixels right, stepping up every 3
  DEFB $82,$82            ; LINE of 3 pixels right, stepping down every 3
  DEFB $82,$02            ; LINE of 3 pixels diagonally right and down
  DEFB $83,$42            ; LINE of 3 pixels down, stepping right every 2
  DEFB $87,$02            ; LINE of 3 pixels diagonally down and left
  DEFB $84,$82            ; LINE of 3 pixels left, stepping up every 3
  DEFB $84,$C2            ; LINE of 3 pixels left, stepping up every 4
  DEFB $84,$C2            ; LINE of 3 pixels left, stepping up every 4
  DEFB $84,$42            ; LINE of 3 pixels left, stepping up every 2
  DEFB $08,$65,$7F        ; MOVE to 101, 127
  DEFB $8B,$8D            ; LINE of 14 pixels down, stepping right every 7
  DEFB $89,$8E            ; LINE of 15 pixels up, stepping right every 7
  DEFB $08,$6D,$77        ; MOVE to 109, 119
  DEFB $8B,$CE            ; LINE of 15 pixels down, stepping right every 8
  DEFB $89,$4F            ; LINE of 16 pixels up, stepping right every 6
  DEFB $86,$C3            ; LINE of 4 pixels left, stepping down every 4
  DEFB $08,$67,$68        ; MOVE to 103, 104
  DEFB $8B,$8D            ; LINE of 14 pixels down, stepping right every 7
  DEFB $82,$41            ; LINE of 2 pixels right, stepping down every 2
  DEFB $8D,$8F            ; LINE of 16 pixels up, stepping left every 7
  DEFB $84,$82            ; LINE of 3 pixels left, stepping up every 3
  DEFB $08,$5F,$3E        ; MOVE to 95, 62
  DEFB $8E,$8D            ; LINE of 14 pixels left, stepping down every 7
  DEFB $8E,$4D            ; LINE of 14 pixels left, stepping down every 6
  DEFB $8E,$0D            ; LINE of 14 pixels left, stepping down every 5
  DEFB $87,$0D            ; LINE of 14 pixels diagonally down and left
  DEFB $86,$4D            ; LINE of 14 pixels left, stepping down every 2
  DEFB $86,$4D            ; LINE of 14 pixels left, stepping down every 2
  DEFB $86,$4D            ; LINE of 14 pixels left, stepping down every 2
  DEFB $08,$A4,$3A        ; MOVE to 164, 58
  DEFB $8A,$0D            ; LINE of 14 pixels right, stepping down every 5
  DEFB $92,$0D            ; LINE of 14 pixels right, stepping down every 9
  DEFB $8A,$CD            ; LINE of 14 pixels right, stepping down every 8
  DEFB $82,$4D            ; LINE of 14 pixels right, stepping down every 2
  DEFB $83,$0D            ; LINE of 14 pixels diagonally down and right
  DEFB $82,$4D            ; LINE of 14 pixels right, stepping down every 2
  DEFB $8A,$4D            ; LINE of 14 pixels right, stepping down every 6
  DEFB $82,$8D            ; LINE of 14 pixels right, stepping down every 3
  DEFB $08,$AA,$22        ; MOVE to 170, 34
  DEFB $82,$8D            ; LINE of 14 pixels right, stepping down every 3
  DEFB $82,$4D            ; LINE of 14 pixels right, stepping down every 2
  DEFB $82,$13            ; LINE of 20 pixels diagonally right and down
  DEFB $82,$D7            ; LINE of 24 pixels right, stepping down every 4
  DEFB $08,$56,$1B        ; MOVE to 86, 27
  DEFB $86,$CD            ; LINE of 14 pixels left, stepping down every 4
  DEFB $86,$8D            ; LINE of 14 pixels left, stepping down every 3
  DEFB $86,$4D            ; LINE of 14 pixels left, stepping down every 2
  DEFB $86,$0D            ; LINE of 14 pixels diagonally left and down
  DEFB $08,$2C,$0D        ; MOVE to 44, 13
  DEFB $8D,$1D            ; LINE of 30 pixels up, stepping left every 5
  DEFB $08,$39,$15        ; MOVE to 57, 21
  DEFB $8D,$A2            ; LINE of 35 pixels up, stepping left every 7
  DEFB $08,$A2,$5B        ; MOVE to 162, 91
  DEFB $98,$DB            ; LINE of 28 pixels right, stepping up every 16
  DEFB $B8,$1B            ; LINE of 28 pixels right, stepping up every 29
  DEFB $8A,$DB            ; LINE of 28 pixels right, stepping down every 8
  DEFB $8A,$DB            ; LINE of 28 pixels right, stepping down every 8
  DEFB $41,$92,$00        ; FILL with blue from 146, 0
  DEFB $08,$BA,$1E        ; MOVE to 186, 30
  DEFB $81,$16            ; LINE of 23 pixels diagonally up and right
  DEFB $08,$C5,$19        ; MOVE to 197, 25
  DEFB $81,$16            ; LINE of 23 pixels diagonally up and right
  DEFB $08,$DA,$05        ; MOVE to 218, 5
  DEFB $81,$5D            ; LINE of 30 pixels up, stepping right every 2
  DEFB $08,$F3,$00        ; MOVE to 243, 0
  DEFB $89,$19            ; LINE of 26 pixels up, stepping right every 5
  DEFB $08,$00,$29        ; MOVE to 0, 41
  DEFB $81,$53            ; LINE of 20 pixels up, stepping right every 2
  DEFB $81,$0C            ; LINE of 13 pixels diagonally up and right
  DEFB $80,$4C            ; LINE of 13 pixels right, stepping up every 2
  DEFB $80,$4C            ; LINE of 13 pixels right, stepping up every 2
  DEFB $80,$0C            ; LINE of 13 pixels diagonally right and up
  DEFB $81,$06            ; LINE of 7 pixels diagonally up and right
  DEFB $83,$86            ; LINE of 7 pixels down, stepping right every 3
  DEFB $88,$04            ; LINE of 5 pixels right, stepping up every 5
  DEFB $8D,$48            ; LINE of 9 pixels up, stepping left every 6
  DEFB $83,$48            ; LINE of 9 pixels down, stepping right every 2
  DEFB $83,$48            ; LINE of 9 pixels down, stepping right every 2
  DEFB $89,$08            ; LINE of 9 pixels up, stepping right every 5
  DEFB $8D,$88            ; LINE of 9 pixels up, stepping left every 7
  DEFB $81,$88            ; LINE of 9 pixels up, stepping right every 3
  DEFB $89,$4A            ; LINE of 11 pixels up, stepping right every 6
  DEFB $08,$04,$3E        ; MOVE to 4, 62
  DEFB $85,$4A            ; LINE of 11 pixels up, stepping left every 2
  DEFB $08,$00,$4B        ; MOVE to 0, 75
  DEFB $80,$4A            ; LINE of 11 pixels right, stepping up every 2
  DEFB $80,$05            ; LINE of 6 pixels diagonally right and up
  DEFB $8F,$4B            ; LINE of 12 pixels down, stepping left every 6
  DEFB $86,$0B            ; LINE of 12 pixels diagonally left and down
  DEFB $08,$1B,$52        ; MOVE to 27, 82
  DEFB $8D,$44            ; LINE of 5 pixels up, stepping left every 6
  DEFB $88,$45            ; LINE of 6 pixels right, stepping up every 6
  DEFB $89,$06            ; LINE of 7 pixels up, stepping right every 5
  DEFB $82,$85            ; LINE of 6 pixels right, stepping down every 3
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $86,$4E            ; LINE of 15 pixels left, stepping down every 2
  DEFB $08,$39,$68        ; MOVE to 57, 104
  DEFB $91,$8F            ; LINE of 16 pixels up, stepping right every 11
  DEFB $86,$C8            ; LINE of 9 pixels left, stepping down every 4
  DEFB $8F,$04            ; LINE of 5 pixels down, stepping left every 5
  DEFB $8E,$04            ; LINE of 5 pixels left, stepping down every 5
  DEFB $89,$85            ; LINE of 6 pixels up, stepping right every 7
  DEFB $8C,$46            ; LINE of 7 pixels left, stepping up every 6
  DEFB $8C,$86            ; LINE of 7 pixels left, stepping up every 7
  DEFB $84,$86            ; LINE of 7 pixels left, stepping up every 3
  DEFB $87,$85            ; LINE of 6 pixels down, stepping left every 3
  DEFB $82,$85            ; LINE of 6 pixels right, stepping down every 3
  DEFB $86,$45            ; LINE of 6 pixels left, stepping down every 2
  DEFB $82,$48            ; LINE of 9 pixels right, stepping down every 2
  DEFB $8E,$C8            ; LINE of 9 pixels left, stepping down every 8
  DEFB $82,$C8            ; LINE of 9 pixels right, stepping down every 4
  DEFB $80,$C8            ; LINE of 9 pixels right, stepping up every 4
  DEFB $90,$48            ; LINE of 9 pixels right, stepping up every 10
  DEFB $82,$C9            ; LINE of 10 pixels right, stepping down every 4
  DEFB $08,$31,$73        ; MOVE to 49, 115
  DEFB $82,$C8            ; LINE of 9 pixels right, stepping down every 4
  DEFB $08,$21,$76        ; MOVE to 33, 118
  DEFB $8B,$0D            ; LINE of 14 pixels down, stepping right every 5
  DEFB $08,$40,$6B        ; MOVE to 64, 107
  DEFB $91,$4D            ; LINE of 14 pixels up, stepping right every 10
  DEFB $83,$03            ; LINE of 4 pixels diagonally down and right
  DEFB $87,$4A            ; LINE of 11 pixels down, stepping left every 2
  DEFB $08,$30,$5F        ; MOVE to 48, 95
  DEFB $84,$44            ; LINE of 5 pixels left, stepping up every 2
  DEFB $80,$C9            ; LINE of 10 pixels right, stepping up every 4
  DEFB $86,$04            ; LINE of 5 pixels diagonally left and down
  DEFB $08,$3C,$61        ; MOVE to 60, 97
  DEFB $80,$C4            ; LINE of 5 pixels right, stepping up every 4
  DEFB $8D,$04            ; LINE of 5 pixels up, stepping left every 5
  DEFB $40,$40,$7F        ; FILL with black from 64, 127
  DEFB $40,$40,$63        ; FILL with black from 64, 99
  DEFB $08,$26,$6B        ; MOVE to 38, 107
  DEFB $85,$CC            ; LINE of 13 pixels up, stepping left every 4
  DEFB $40,$24,$6D        ; FILL with black from 36, 109
  DEFB $26,$59,$8C,$19,$02,$23,$FF ; PAINT yellow ink from row 12, column 12,
                                   ; along a path of 3 steps
  DEFB $27,$58,$8D,$03,$08,$02,$04,$01 ; PAINT white ink from row 4, column 13,
  DEFB $0E,$FF                         ; along a path of 6 steps
  DEFB $08,$5F,$58        ; MOVE to 95, 88
  DEFB $94,$E9            ; LINE of 42 pixels left, stepping up every 12
  DEFB $08,$B3,$5C        ; MOVE to 179, 92
  DEFB $85,$E9            ; LINE of 42 pixels up, stepping left every 4
  DEFB $08,$E1,$5C        ; MOVE to 225, 92
  DEFB $AD,$29            ; LINE of 42 pixels up, stepping left every 21
  DEFB $08,$C0,$45        ; MOVE to 192, 69
  DEFB $8A,$92            ; LINE of 19 pixels right, stepping down every 7
  DEFB $92,$D2            ; LINE of 19 pixels right, stepping down every 12
  DEFB $90,$0C            ; LINE of 13 pixels right, stepping up every 9
  DEFB $85,$C8            ; LINE of 9 pixels up, stepping left every 4
  DEFB $84,$44            ; LINE of 5 pixels left, stepping up every 2
  DEFB $84,$84            ; LINE of 5 pixels left, stepping up every 3
  DEFB $84,$C4            ; LINE of 5 pixels left, stepping up every 4
  DEFB $86,$C4            ; LINE of 5 pixels left, stepping down every 4
  DEFB $8E,$04            ; LINE of 5 pixels left, stepping down every 5
  DEFB $86,$C4            ; LINE of 5 pixels left, stepping down every 4
  DEFB $86,$84            ; LINE of 5 pixels left, stepping down every 3
  DEFB $86,$44            ; LINE of 5 pixels left, stepping down every 2
  DEFB $86,$C4            ; LINE of 5 pixels left, stepping down every 4
  DEFB $87,$04            ; LINE of 5 pixels diagonally down and left
  DEFB $46,$C8,$47        ; FILL with yellow from 200, 71
  DEFB $00                ; End of the picture

; Picture for location 41: lower halls
;
; A border colour and a starting attribute, then 36 moves, 132 lines, 16 fills,
; 1 paint, ending at $00.
LOC41_LOWER_HALLS_PIC:
  DEFB $07                ; Border: white
  DEFB $38                ; The canvas starts white paper, black ink
  DEFB $08,$FF,$7E        ; MOVE to 255, 126
  DEFB $8E,$7E            ; LINE of 63 pixels left, stepping down every 6
  DEFB $8E,$7E            ; LINE of 63 pixels left, stepping down every 6
  DEFB $08,$08,$00        ; MOVE to 8, 0
  DEFB $F9,$FE            ; LINE of 63 pixels up, stepping right every 64
  DEFB $C1,$1F            ; LINE of 32 pixels up, stepping right every 33
  DEFB $89,$07            ; LINE of 8 pixels up, stepping right every 5
  DEFB $81,$87            ; LINE of 8 pixels up, stepping right every 3
  DEFB $81,$47            ; LINE of 8 pixels up, stepping right every 2
  DEFB $80,$47            ; LINE of 8 pixels right, stepping up every 2
  DEFB $82,$87            ; LINE of 8 pixels right, stepping down every 3
  DEFB $83,$47            ; LINE of 8 pixels down, stepping right every 2
  DEFB $8B,$07            ; LINE of 8 pixels down, stepping right every 5
  DEFB $8B,$C7            ; LINE of 8 pixels down, stepping right every 8
  DEFB $FB,$FE            ; LINE of 63 pixels down, stepping right every 64
  DEFB $BF,$DF            ; LINE of 32 pixels down, stepping left every 32
  DEFB $08,$FF,$64        ; MOVE to 255, 100
  DEFB $96,$7E            ; LINE of 63 pixels left, stepping down every 10
  DEFB $96,$3E            ; LINE of 63 pixels left, stepping down every 9
  DEFB $08,$2D,$04        ; MOVE to 45, 4
  DEFB $F9,$FE            ; LINE of 63 pixels up, stepping right every 64
  DEFB $B9,$1C            ; LINE of 29 pixels up, stepping right every 29
  DEFB $89,$47            ; LINE of 8 pixels up, stepping right every 6
  DEFB $81,$87            ; LINE of 8 pixels up, stepping right every 3
  DEFB $81,$03            ; LINE of 4 pixels diagonally up and right
  DEFB $80,$43            ; LINE of 4 pixels right, stepping up every 2
  DEFB $83,$03            ; LINE of 4 pixels diagonally down and right
  DEFB $83,$43            ; LINE of 4 pixels down, stepping right every 2
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $8B,$03            ; LINE of 4 pixels down, stepping right every 5
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $FB,$FE            ; LINE of 63 pixels down, stepping right every 64
  DEFB $B3,$58            ; LINE of 25 pixels down, stepping right every 26
  DEFB $08,$49,$07        ; MOVE to 73, 7
  DEFB $F9,$FE            ; LINE of 63 pixels up, stepping right every 64
  DEFB $B1,$17            ; LINE of 24 pixels up, stepping right every 25
  DEFB $81,$84            ; LINE of 5 pixels up, stepping right every 3
  DEFB $81,$44            ; LINE of 5 pixels up, stepping right every 2
  DEFB $81,$44            ; LINE of 5 pixels up, stepping right every 2
  DEFB $80,$03            ; LINE of 4 pixels diagonally right and up
  DEFB $82,$03            ; LINE of 4 pixels diagonally right and down
  DEFB $83,$43            ; LINE of 4 pixels down, stepping right every 2
  DEFB $83,$83            ; LINE of 4 pixels down, stepping right every 3
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $FB,$FE            ; LINE of 63 pixels down, stepping right every 64
  DEFB $AB,$55            ; LINE of 22 pixels down, stepping right every 22
  DEFB $08,$25,$02        ; MOVE to 37, 2
  DEFB $82,$43            ; LINE of 4 pixels right, stepping down every 2
  DEFB $08,$42,$06        ; MOVE to 66, 6
  DEFB $82,$43            ; LINE of 4 pixels right, stepping down every 2
  DEFB $08,$5B,$09        ; MOVE to 91, 9
  DEFB $88,$5C            ; LINE of 29 pixels right, stepping up every 6
  DEFB $8A,$09            ; LINE of 10 pixels right, stepping down every 5
  DEFB $08,$79,$0E        ; MOVE to 121, 14
  DEFB $F9,$FE            ; LINE of 63 pixels up, stepping right every 64
  DEFB $E9,$33            ; LINE of 52 pixels up, stepping right every 53
  DEFB $08,$81,$57        ; MOVE to 129, 87
  DEFB $94,$08            ; LINE of 9 pixels left, stepping up every 9
  DEFB $08,$81,$69        ; MOVE to 129, 105
  DEFB $8E,$08            ; LINE of 9 pixels left, stepping down every 5
  DEFB $08,$5A,$09        ; MOVE to 90, 9
  DEFB $84,$51            ; LINE of 18 pixels left, stepping up every 2
  DEFB $08,$42,$06        ; MOVE to 66, 6
  DEFB $84,$55            ; LINE of 22 pixels left, stepping up every 2
  DEFB $08,$25,$03        ; MOVE to 37, 3
  DEFB $84,$5D            ; LINE of 30 pixels left, stepping up every 2
  DEFB $08,$6F,$00        ; MOVE to 111, 0
  DEFB $08,$66,$00        ; MOVE to 102, 0
  DEFB $80,$CE            ; LINE of 15 pixels right, stepping up every 4
  DEFB $80,$08            ; LINE of 9 pixels diagonally right and up
  DEFB $80,$98            ; LINE of 25 pixels right, stepping up every 3
  DEFB $8A,$C9            ; LINE of 10 pixels right, stepping down every 8
  DEFB $81,$49            ; LINE of 10 pixels up, stepping right every 2
  DEFB $8A,$0D            ; LINE of 14 pixels right, stepping down every 5
  DEFB $80,$CD            ; LINE of 14 pixels right, stepping up every 4
  DEFB $81,$4A            ; LINE of 11 pixels up, stepping right every 2
  DEFB $8A,$56            ; LINE of 23 pixels right, stepping down every 6
  DEFB $83,$47            ; LINE of 8 pixels down, stepping right every 2
  DEFB $82,$8E            ; LINE of 15 pixels right, stepping down every 3
  DEFB $80,$CE            ; LINE of 15 pixels right, stepping up every 4
  DEFB $08,$CD,$07        ; MOVE to 205, 7
  DEFB $80,$C8            ; LINE of 9 pixels right, stepping up every 4
  DEFB $84,$CF            ; LINE of 16 pixels left, stepping up every 4
  DEFB $86,$89            ; LINE of 10 pixels left, stepping down every 3
  DEFB $08,$C7,$0D        ; MOVE to 199, 13
  DEFB $85,$89            ; LINE of 10 pixels up, stepping left every 3
  DEFB $82,$D1            ; LINE of 18 pixels right, stepping down every 4
  DEFB $8B,$0A            ; LINE of 11 pixels down, stepping right every 5
  DEFB $81,$03            ; LINE of 4 pixels diagonally up and right
  DEFB $8D,$08            ; LINE of 9 pixels up, stepping left every 5
  DEFB $86,$45            ; LINE of 6 pixels left, stepping down every 2
  DEFB $08,$DB,$15        ; MOVE to 219, 21
  DEFB $84,$D0            ; LINE of 17 pixels left, stepping up every 4
  DEFB $86,$46            ; LINE of 7 pixels left, stepping down every 2
  DEFB $08,$D6,$08        ; MOVE to 214, 8
  DEFB $8B,$04            ; LINE of 5 pixels down, stepping right every 5
  DEFB $08,$DE,$26        ; MOVE to 222, 38
  DEFB $8D,$08            ; LINE of 9 pixels up, stepping left every 5
  DEFB $83,$04            ; LINE of 5 pixels diagonally down and right
  DEFB $81,$C7            ; LINE of 8 pixels up, stepping right every 4
  DEFB $83,$49            ; LINE of 10 pixels down, stepping right every 2
  DEFB $81,$45            ; LINE of 6 pixels up, stepping right every 2
  DEFB $8B,$8B            ; LINE of 12 pixels down, stepping right every 7
  DEFB $81,$8B            ; LINE of 12 pixels up, stepping right every 3
  DEFB $8B,$97            ; LINE of 24 pixels down, stepping right every 7
  DEFB $08,$DF,$22        ; MOVE to 223, 34
  DEFB $83,$4E            ; LINE of 15 pixels down, stepping right every 2
  DEFB $8A,$22            ; LINE of 35 pixels right, stepping down every 5
  DEFB $08,$84,$0C        ; MOVE to 132, 12
  DEFB $83,$5F            ; LINE of 32 pixels down, stepping right every 2
  DEFB $08,$25,$09        ; MOVE to 37, 9
  DEFB $84,$49            ; LINE of 10 pixels left, stepping up every 2
  DEFB $81,$42            ; LINE of 3 pixels up, stepping right every 2
  DEFB $80,$42            ; LINE of 3 pixels right, stepping up every 2
  DEFB $80,$82            ; LINE of 3 pixels right, stepping up every 3
  DEFB $82,$42            ; LINE of 3 pixels right, stepping down every 2
  DEFB $08,$41,$0D        ; MOVE to 65, 13
  DEFB $84,$46            ; LINE of 7 pixels left, stepping up every 2
  DEFB $85,$42            ; LINE of 3 pixels up, stepping left every 2
  DEFB $81,$41            ; LINE of 2 pixels up, stepping right every 2
  DEFB $80,$42            ; LINE of 3 pixels right, stepping up every 2
  DEFB $82,$42            ; LINE of 3 pixels right, stepping down every 2
  DEFB $82,$02            ; LINE of 3 pixels diagonally right and down
  DEFB $40,$15,$18        ; FILL with black from 21, 24
  DEFB $40,$32,$18        ; FILL with black from 50, 24
  DEFB $40,$54,$18        ; FILL with black from 84, 24
  DEFB $08,$28,$01        ; MOVE to 40, 1
  DEFB $80,$44            ; LINE of 5 pixels right, stepping up every 2
  DEFB $08,$46,$05        ; MOVE to 70, 5
  DEFB $80,$42            ; LINE of 3 pixels right, stepping up every 2
  DEFB $41,$FF,$62        ; FILL with blue from 255, 98
  DEFB $41,$F8,$7F        ; FILL with blue from 248, 127
  DEFB $46,$FF,$18        ; FILL with yellow from 255, 24
  DEFB $46,$82,$03        ; FILL with yellow from 130, 3
  DEFB $26,$59,$79,$05,$02,$01,$02,$09 ; PAINT yellow ink from row 11, column
  DEFB $06,$3B,$00,$35,$0B,$00,$27,$0D ; 25, along a path of 19 steps
  DEFB $03,$00,$19,$0B,$04,$09,$FF     ;
  DEFB $08,$9D,$06        ; MOVE to 157, 6
  DEFB $80,$02            ; LINE of 3 pixels diagonally right and up
  DEFB $83,$02            ; LINE of 3 pixels diagonally down and right
  DEFB $86,$02            ; LINE of 3 pixels diagonally left and down
  DEFB $85,$02            ; LINE of 3 pixels diagonally up and left
  DEFB $42,$9F,$06        ; FILL with red from 159, 6
  DEFB $08,$AB,$06        ; MOVE to 171, 6
  DEFB $81,$01            ; LINE of 2 pixels diagonally up and right
  DEFB $82,$01            ; LINE of 2 pixels diagonally right and down
  DEFB $87,$02            ; LINE of 3 pixels diagonally down and left
  DEFB $85,$43            ; LINE of 4 pixels up, stepping left every 2
  DEFB $44,$AC,$05        ; FILL with green from 172, 5
  DEFB $08,$AC,$11        ; MOVE to 172, 17
  DEFB $85,$43            ; LINE of 4 pixels up, stepping left every 2
  DEFB $80,$83            ; LINE of 4 pixels right, stepping up every 3
  DEFB $87,$83            ; LINE of 4 pixels down, stepping left every 3
  DEFB $45,$AD,$14        ; FILL with cyan from 173, 20
  DEFB $08,$96,$0D        ; MOVE to 150, 13
  DEFB $87,$83            ; LINE of 4 pixels down, stepping left every 3
  DEFB $85,$03            ; LINE of 4 pixels diagonally up and left
  DEFB $80,$C3            ; LINE of 4 pixels right, stepping up every 4
  DEFB $83,$83            ; LINE of 4 pixels down, stepping right every 3
  DEFB $43,$94,$0C        ; FILL with magenta from 148, 12
  DEFB $08,$D3,$1F        ; MOVE to 211, 31
  DEFB $83,$83            ; LINE of 4 pixels down, stepping right every 3
  DEFB $80,$03            ; LINE of 4 pixels diagonally right and up
  DEFB $86,$C4            ; LINE of 5 pixels left, stepping down every 4
  DEFB $47,$D5,$1E        ; FILL with white from 213, 30
  DEFB $08,$C5,$08        ; MOVE to 197, 8
  DEFB $86,$C4            ; LINE of 5 pixels left, stepping down every 4
  DEFB $82,$44            ; LINE of 5 pixels right, stepping down every 2
  DEFB $81,$83            ; LINE of 4 pixels up, stepping right every 3
  DEFB $41,$C4,$07        ; FILL with blue from 196, 7
  DEFB $08,$E9,$08        ; MOVE to 233, 8
  DEFB $81,$83            ; LINE of 4 pixels up, stepping right every 3
  DEFB $83,$43            ; LINE of 4 pixels down, stepping right every 2
  DEFB $8E,$03            ; LINE of 4 pixels left, stepping down every 5
  DEFB $42,$E9,$09        ; FILL with red from 233, 9
  DEFB $08,$F5,$0B        ; MOVE to 245, 11
  DEFB $8E,$04            ; LINE of 5 pixels left, stepping down every 5
  DEFB $81,$44            ; LINE of 5 pixels up, stepping right every 2
  DEFB $83,$04            ; LINE of 5 pixels diagonally down and right
  DEFB $44,$F3,$0C        ; FILL with green from 243, 12
  DEFB $08,$E1,$01        ; MOVE to 225, 1
  DEFB $8A,$44            ; LINE of 5 pixels right, stepping down every 6
  DEFB $85,$C4            ; LINE of 5 pixels up, stepping left every 4
  DEFB $87,$04            ; LINE of 5 pixels diagonally down and left
  DEFB $47,$E4,$03        ; FILL with white from 228, 3
  DEFB $00                ; End of the picture

; Picture for location 26: spider threads place
;
; A border colour and a starting attribute, then 35 moves, 175 lines, 4 fills,
; 2 paints, ending at $00.
LOC26_SPIDER_THREADS_PLACE_PIC:
  DEFB $02                ; Border: red
  DEFB $10                ; The canvas starts red paper, black ink
  DEFB $08,$5D,$00        ; MOVE to 93, 0
  DEFB $84,$59            ; LINE of 26 pixels left, stepping up every 2
  DEFB $85,$55            ; LINE of 22 pixels up, stepping left every 2
  DEFB $83,$10            ; LINE of 17 pixels diagonally down and right
  DEFB $82,$98            ; LINE of 25 pixels right, stepping down every 3
  DEFB $B8,$AD            ; LINE of 46 pixels right, stepping up every 31
  DEFB $80,$1B            ; LINE of 28 pixels diagonally right and up
  DEFB $84,$71            ; LINE of 50 pixels left, stepping up every 2
  DEFB $86,$FE            ; LINE of 63 pixels left, stepping down every 4
  DEFB $86,$D9            ; LINE of 26 pixels left, stepping down every 4
  DEFB $86,$4A            ; LINE of 11 pixels left, stepping down every 2
  DEFB $86,$0A            ; LINE of 11 pixels diagonally left and down
  DEFB $81,$4A            ; LINE of 11 pixels up, stepping right every 2
  DEFB $80,$0A            ; LINE of 11 pixels diagonally right and up
  DEFB $80,$FE            ; LINE of 63 pixels right, stepping up every 4
  DEFB $80,$E6            ; LINE of 39 pixels right, stepping up every 4
  DEFB $82,$95            ; LINE of 22 pixels right, stepping down every 3
  DEFB $85,$49            ; LINE of 10 pixels up, stepping left every 2
  DEFB $9C,$7A            ; LINE of 59 pixels left, stepping up every 14
  DEFB $9E,$9E            ; LINE of 31 pixels left, stepping down every 15
  DEFB $86,$4B            ; LINE of 12 pixels left, stepping down every 2
  DEFB $8F,$8B            ; LINE of 12 pixels down, stepping left every 7
  DEFB $8D,$8C            ; LINE of 13 pixels up, stepping left every 7
  DEFB $80,$0B            ; LINE of 12 pixels diagonally right and up
  DEFB $88,$A3            ; LINE of 36 pixels right, stepping up every 7
  DEFB $D0,$BC            ; LINE of 61 pixels right, stepping up every 43
  DEFB $83,$09            ; LINE of 10 pixels diagonally down and right
  DEFB $85,$8F            ; LINE of 16 pixels up, stepping left every 3
  DEFB $AC,$BA            ; LINE of 59 pixels left, stepping up every 23
  DEFB $9C,$4D            ; LINE of 14 pixels left, stepping up every 14
  DEFB $86,$A0            ; LINE of 33 pixels left, stepping down every 3
  DEFB $86,$13            ; LINE of 20 pixels diagonally left and down
  DEFB $8F,$0E            ; LINE of 15 pixels down, stepping left every 5
  DEFB $9D,$93            ; LINE of 20 pixels up, stepping left every 15
  DEFB $81,$18            ; LINE of 25 pixels diagonally up and right
  DEFB $80,$A1            ; LINE of 34 pixels right, stepping up every 3
  DEFB $E8,$7E            ; LINE of 63 pixels right, stepping up every 54
  DEFB $A0,$92            ; LINE of 19 pixels right, stepping up every 19
  DEFB $83,$95            ; LINE of 22 pixels down, stepping right every 3
  DEFB $99,$0E            ; LINE of 15 pixels up, stepping right every 13
  DEFB $88,$76            ; LINE of 55 pixels right, stepping up every 6
  DEFB $82,$53            ; LINE of 20 pixels right, stepping down every 2
  DEFB $83,$93            ; LINE of 20 pixels down, stepping right every 3
  DEFB $87,$89            ; LINE of 10 pixels down, stepping left every 3
  DEFB $8D,$49            ; LINE of 10 pixels up, stepping left every 6
  DEFB $85,$4F            ; LINE of 16 pixels up, stepping left every 2
  DEFB $84,$8F            ; LINE of 16 pixels left, stepping up every 3
  DEFB $86,$E8            ; LINE of 41 pixels left, stepping down every 4
  DEFB $8F,$8D            ; LINE of 14 pixels down, stepping left every 7
  DEFB $81,$03            ; LINE of 4 pixels diagonally up and right
  DEFB $81,$43            ; LINE of 4 pixels up, stepping right every 2
  DEFB $81,$03            ; LINE of 4 pixels diagonally up and right
  DEFB $80,$43            ; LINE of 4 pixels right, stepping up every 2
  DEFB $80,$83            ; LINE of 4 pixels right, stepping up every 3
  DEFB $80,$C3            ; LINE of 4 pixels right, stepping up every 4
  DEFB $88,$03            ; LINE of 4 pixels right, stepping up every 5
  DEFB $82,$C3            ; LINE of 4 pixels right, stepping down every 4
  DEFB $82,$83            ; LINE of 4 pixels right, stepping down every 3
  DEFB $82,$43            ; LINE of 4 pixels right, stepping down every 2
  DEFB $82,$03            ; LINE of 4 pixels diagonally right and down
  DEFB $83,$43            ; LINE of 4 pixels down, stepping right every 2
  DEFB $83,$43            ; LINE of 4 pixels down, stepping right every 2
  DEFB $83,$83            ; LINE of 4 pixels down, stepping right every 3
  DEFB $83,$C3            ; LINE of 4 pixels down, stepping right every 4
  DEFB $87,$C3            ; LINE of 4 pixels down, stepping left every 4
  DEFB $87,$83            ; LINE of 4 pixels down, stepping left every 3
  DEFB $87,$03            ; LINE of 4 pixels diagonally down and left
  DEFB $86,$03            ; LINE of 4 pixels diagonally left and down
  DEFB $86,$43            ; LINE of 4 pixels left, stepping down every 2
  DEFB $86,$C3            ; LINE of 4 pixels left, stepping down every 4
  DEFB $84,$C3            ; LINE of 4 pixels left, stepping up every 4
  DEFB $84,$83            ; LINE of 4 pixels left, stepping up every 3
  DEFB $84,$83            ; LINE of 4 pixels left, stepping up every 3
  DEFB $84,$83            ; LINE of 4 pixels left, stepping up every 3
  DEFB $84,$C3            ; LINE of 4 pixels left, stepping up every 4
  DEFB $83,$04            ; LINE of 5 pixels diagonally down and right
  DEFB $8A,$26            ; LINE of 39 pixels right, stepping down every 5
  DEFB $A5,$26            ; LINE of 39 pixels up, stepping left every 17
  DEFB $84,$0A            ; LINE of 11 pixels diagonally left and up
  DEFB $84,$4A            ; LINE of 11 pixels left, stepping up every 2
  DEFB $8A,$8C            ; LINE of 13 pixels right, stepping down every 7
  DEFB $82,$45            ; LINE of 6 pixels right, stepping down every 2
  DEFB $82,$0C            ; LINE of 13 pixels diagonally right and down
  DEFB $B3,$F2            ; LINE of 51 pixels down, stepping right every 28
  DEFB $8C,$67            ; LINE of 40 pixels left, stepping up every 6
  DEFB $83,$9D            ; LINE of 30 pixels down, stepping right every 3
  DEFB $92,$DD            ; LINE of 30 pixels right, stepping down every 12
  DEFB $81,$D8            ; LINE of 25 pixels up, stepping right every 4
  DEFB $85,$4D            ; LINE of 14 pixels up, stepping left every 2
  DEFB $08,$F8,$31        ; MOVE to 248, 49
  DEFB $83,$0D            ; LINE of 14 pixels diagonally down and right
  DEFB $08,$FF,$08        ; MOVE to 255, 8
  DEFB $87,$8D            ; LINE of 14 pixels down, stepping left every 3
  DEFB $08,$CF,$00        ; MOVE to 207, 0
  DEFB $85,$97            ; LINE of 24 pixels up, stepping left every 3
  DEFB $87,$59            ; LINE of 26 pixels down, stepping left every 2
  DEFB $08,$AB,$00        ; MOVE to 171, 0
  DEFB $81,$53            ; LINE of 20 pixels up, stepping right every 2
  DEFB $86,$18            ; LINE of 25 pixels diagonally left and down
  DEFB $08,$6F,$0B        ; MOVE to 111, 11
  DEFB $8D,$91            ; LINE of 18 pixels up, stepping left every 7
  DEFB $81,$54            ; LINE of 21 pixels up, stepping right every 2
  DEFB $97,$54            ; LINE of 21 pixels down, stepping left every 10
  DEFB $8B,$13            ; LINE of 20 pixels down, stepping right every 5
  DEFB $08,$C4,$4C        ; MOVE to 196, 76
  DEFB $83,$48            ; LINE of 9 pixels down, stepping right every 2
  DEFB $88,$08            ; LINE of 9 pixels right, stepping up every 5
  DEFB $80,$48            ; LINE of 9 pixels right, stepping up every 2
  DEFB $81,$88            ; LINE of 9 pixels up, stepping right every 3
  DEFB $84,$05            ; LINE of 6 pixels diagonally left and up
  DEFB $8C,$05            ; LINE of 6 pixels left, stepping up every 5
  DEFB $86,$89            ; LINE of 10 pixels left, stepping down every 3
  DEFB $87,$89            ; LINE of 10 pixels down, stepping left every 3
  DEFB $40,$BD,$4B        ; FILL with black from 189, 75
  DEFB $40,$73,$1A        ; FILL with black from 115, 26
  DEFB $08,$A6,$29        ; MOVE to 166, 41
  DEFB $83,$C8            ; LINE of 9 pixels down, stepping right every 4
  DEFB $08,$94,$10        ; MOVE to 148, 16
  DEFB $89,$49            ; LINE of 10 pixels up, stepping right every 6
  DEFB $8E,$88            ; LINE of 9 pixels left, stepping down every 7
  DEFB $86,$83            ; LINE of 4 pixels left, stepping down every 3
  DEFB $89,$03            ; LINE of 4 pixels up, stepping right every 5
  DEFB $81,$83            ; LINE of 4 pixels up, stepping right every 3
  DEFB $81,$03            ; LINE of 4 pixels diagonally up and right
  DEFB $81,$83            ; LINE of 4 pixels up, stepping right every 3
  DEFB $81,$03            ; LINE of 4 pixels diagonally up and right
  DEFB $80,$43            ; LINE of 4 pixels right, stepping up every 2
  DEFB $8A,$08            ; LINE of 9 pixels right, stepping down every 5
  DEFB $08,$92,$22        ; MOVE to 146, 34
  DEFB $80,$02            ; LINE of 3 pixels diagonally right and up
  DEFB $83,$42            ; LINE of 3 pixels down, stepping right every 2
  DEFB $86,$C3            ; LINE of 4 pixels left, stepping down every 4
  DEFB $08,$99,$1B        ; MOVE to 153, 27
  DEFB $80,$02            ; LINE of 3 pixels diagonally right and up
  DEFB $83,$42            ; LINE of 3 pixels down, stepping right every 2
  DEFB $84,$83            ; LINE of 4 pixels left, stepping up every 3
  DEFB $08,$99,$23        ; MOVE to 153, 35
  DEFB $80,$02            ; LINE of 3 pixels diagonally right and up
  DEFB $83,$42            ; LINE of 3 pixels down, stepping right every 2
  DEFB $84,$C3            ; LINE of 4 pixels left, stepping up every 4
  DEFB $40,$97,$20        ; FILL with black from 151, 32
  DEFB $08,$43,$7F        ; MOVE to 67, 127
  DEFB $87,$5B            ; LINE of 28 pixels down, stepping left every 2
  DEFB $08,$30,$56        ; MOVE to 48, 86
  DEFB $A7,$A7            ; LINE of 40 pixels down, stepping left every 19
  DEFB $83,$B1            ; LINE of 50 pixels down, stepping right every 3
  DEFB $08,$00,$28        ; MOVE to 0, 40
  DEFB $88,$F1            ; LINE of 50 pixels right, stepping up every 8
  DEFB $88,$F1            ; LINE of 50 pixels right, stepping up every 8
  DEFB $88,$F1            ; LINE of 50 pixels right, stepping up every 8
  DEFB $08,$DC,$3A        ; MOVE to 220, 58
  DEFB $82,$B1            ; LINE of 50 pixels right, stepping down every 3
  DEFB $08,$00,$60        ; MOVE to 0, 96
  DEFB $9A,$71            ; LINE of 50 pixels right, stepping down every 14
  DEFB $9A,$71            ; LINE of 50 pixels right, stepping down every 14
  DEFB $08,$E4,$57        ; MOVE to 228, 87
  DEFB $88,$31            ; LINE of 50 pixels right, stepping up every 5
  DEFB $08,$CF,$65        ; MOVE to 207, 101
  DEFB $81,$71            ; LINE of 50 pixels up, stepping right every 2
  DEFB $08,$AB,$65        ; MOVE to 171, 101
  DEFB $B1,$F1            ; LINE of 50 pixels up, stepping right every 28
  DEFB $08,$91,$5C        ; MOVE to 145, 92
  DEFB $85,$32            ; LINE of 51 pixels diagonally up and left
  DEFB $08,$94,$16        ; MOVE to 148, 22
  DEFB $86,$32            ; LINE of 51 pixels diagonally left and down
  DEFB $08,$AC,$0F        ; MOVE to 172, 15
  DEFB $A7,$B2            ; LINE of 51 pixels down, stepping left every 19
  DEFB $08,$D5,$19        ; MOVE to 213, 25
  DEFB $82,$32            ; LINE of 51 pixels diagonally right and down
  DEFB $08,$72,$7B        ; MOVE to 114, 123
  DEFB $87,$61            ; LINE of 34 pixels down, stepping left every 2
  DEFB $A7,$66            ; LINE of 39 pixels down, stepping left every 18
  DEFB $83,$7E            ; LINE of 63 pixels down, stepping right every 2
  DEFB $08,$74,$7B        ; MOVE to 116, 123
  DEFB $90,$78            ; LINE of 57 pixels right, stepping up every 10
  DEFB $08,$B4,$7F        ; MOVE to 180, 127
  DEFB $8A,$E5            ; LINE of 38 pixels right, stepping down every 8
  DEFB $83,$20            ; LINE of 33 pixels diagonally down and right
  DEFB $A3,$2B            ; LINE of 44 pixels down, stepping right every 17
  DEFB $87,$63            ; LINE of 36 pixels down, stepping left every 2
  DEFB $08,$7F,$6D        ; MOVE to 127, 109
  DEFB $87,$96            ; LINE of 23 pixels down, stepping left every 3
  DEFB $8F,$DF            ; LINE of 32 pixels down, stepping left every 8
  DEFB $83,$6B            ; LINE of 44 pixels down, stepping right every 2
  DEFB $82,$AA            ; LINE of 43 pixels right, stepping down every 3
  DEFB $80,$B1            ; LINE of 50 pixels right, stepping up every 3
  DEFB $81,$63            ; LINE of 36 pixels up, stepping right every 2
  DEFB $08,$D3,$71        ; MOVE to 211, 113
  DEFB $94,$68            ; LINE of 41 pixels left, stepping up every 10
  DEFB $08,$AA,$73        ; MOVE to 170, 115
  DEFB $96,$6A            ; LINE of 43 pixels left, stepping down every 10
  DEFB $08,$8B,$61        ; MOVE to 139, 97
  DEFB $87,$8B            ; LINE of 12 pixels down, stepping left every 3
  DEFB $9F,$DE            ; LINE of 31 pixels down, stepping left every 16
  DEFB $83,$4F            ; LINE of 16 pixels down, stepping right every 2
  DEFB $08,$D4,$1D        ; MOVE to 212, 29
  DEFB $81,$5B            ; LINE of 28 pixels up, stepping right every 2
  DEFB $8D,$45            ; LINE of 6 pixels up, stepping left every 6
  DEFB $08,$E1,$57        ; MOVE to 225, 87
  DEFB $84,$10            ; LINE of 17 pixels diagonally left and up
  DEFB $08,$BB,$6A        ; MOVE to 187, 106
  DEFB $A6,$12            ; LINE of 19 pixels left, stepping down every 17
  DEFB $24,$58,$B9,$05,$02,$0B,$02,$09 ; PAINT green ink from row 5, column 25,
  DEFB $FF                             ; along a path of 5 steps
  DEFB $26,$59,$72,$01,$06,$FF ; PAINT yellow ink from row 11, column 18, along
                               ; a path of 2 steps
  DEFB $08,$16,$7A        ; MOVE to 22, 122
  DEFB $8E,$06            ; LINE of 7 pixels left, stepping down every 5
  DEFB $8A,$06            ; LINE of 7 pixels right, stepping down every 5
  DEFB $82,$04            ; LINE of 5 pixels diagonally right and down
  DEFB $8B,$04            ; LINE of 5 pixels down, stepping right every 5
  DEFB $87,$45            ; LINE of 6 pixels down, stepping left every 2
  DEFB $80,$04            ; LINE of 5 pixels diagonally right and up
  DEFB $89,$44            ; LINE of 5 pixels up, stepping right every 6
  DEFB $85,$83            ; LINE of 4 pixels up, stepping left every 3
  DEFB $84,$03            ; LINE of 4 pixels diagonally left and up
  DEFB $8E,$04            ; LINE of 5 pixels left, stepping down every 5
  DEFB $46,$14,$79        ; FILL with yellow from 20, 121
  DEFB $00                ; End of the picture

; Picture for location 39: front gate
;
; A border colour and a starting attribute, then 16 moves, 114 lines, 13 fills,
; 4 paints, ending at $00.
LOC39_FRONT_GATE_PIC:
  DEFB $07                ; Border: white
  DEFB $38                ; The canvas starts white paper, black ink
  DEFB $08,$00,$2D        ; MOVE to 0, 45
  DEFB $82,$D0            ; LINE of 17 pixels right, stepping down every 4
  DEFB $92,$9A            ; LINE of 27 pixels right, stepping down every 11
  DEFB $8A,$5A            ; LINE of 27 pixels right, stepping down every 6
  DEFB $08,$00,$22        ; MOVE to 0, 34
  DEFB $92,$DA            ; LINE of 27 pixels right, stepping down every 12
  DEFB $83,$87            ; LINE of 8 pixels down, stepping right every 3
  DEFB $82,$DA            ; LINE of 27 pixels right, stepping down every 4
  DEFB $08,$00,$00        ; MOVE to 0, 0
  DEFB $80,$DA            ; LINE of 27 pixels right, stepping up every 4
  DEFB $80,$9A            ; LINE of 27 pixels right, stepping up every 3
  DEFB $80,$04            ; LINE of 5 pixels diagonally right and up
  DEFB $80,$97            ; LINE of 24 pixels right, stepping up every 3
  DEFB $88,$57            ; LINE of 24 pixels right, stepping up every 6
  DEFB $98,$57            ; LINE of 24 pixels right, stepping up every 14
  DEFB $98,$97            ; LINE of 24 pixels right, stepping up every 15
  DEFB $A0,$D7            ; LINE of 24 pixels right, stepping up every 20
  DEFB $A2,$11            ; LINE of 18 pixels right, stepping down every 17
  DEFB $80,$51            ; LINE of 18 pixels right, stepping up every 2
  DEFB $80,$11            ; LINE of 18 pixels diagonally right and up
  DEFB $87,$51            ; LINE of 18 pixels down, stepping left every 2
  DEFB $87,$0D            ; LINE of 14 pixels diagonally down and left
  DEFB $86,$CD            ; LINE of 14 pixels left, stepping down every 4
  DEFB $86,$8D            ; LINE of 14 pixels left, stepping down every 3
  DEFB $86,$4D            ; LINE of 14 pixels left, stepping down every 2
  DEFB $86,$0D            ; LINE of 14 pixels diagonally left and down
  DEFB $86,$0D            ; LINE of 14 pixels diagonally left and down
  DEFB $08,$2D,$16        ; MOVE to 45, 22
  DEFB $80,$4D            ; LINE of 14 pixels right, stepping up every 2
  DEFB $80,$4D            ; LINE of 14 pixels right, stepping up every 2
  DEFB $88,$0D            ; LINE of 14 pixels right, stepping up every 5
  DEFB $80,$CD            ; LINE of 14 pixels right, stepping up every 4
  DEFB $88,$0D            ; LINE of 14 pixels right, stepping up every 5
  DEFB $90,$4D            ; LINE of 14 pixels right, stepping up every 10
  DEFB $8A,$0D            ; LINE of 14 pixels right, stepping down every 5
  DEFB $82,$4F            ; LINE of 16 pixels right, stepping down every 2
  DEFB $08,$97,$27        ; MOVE to 151, 39
  DEFB $9A,$4F            ; LINE of 16 pixels right, stepping down every 14
  DEFB $98,$0F            ; LINE of 16 pixels right, stepping up every 13
  DEFB $80,$8F            ; LINE of 16 pixels right, stepping up every 3
  DEFB $80,$4F            ; LINE of 16 pixels right, stepping up every 2
  DEFB $81,$CF            ; LINE of 16 pixels up, stepping right every 4
  DEFB $81,$0F            ; LINE of 16 pixels diagonally up and right
  DEFB $88,$55            ; LINE of 22 pixels right, stepping up every 6
  DEFB $08,$EA,$3D        ; MOVE to 234, 61
  DEFB $88,$55            ; LINE of 22 pixels right, stepping up every 6
  DEFB $08,$CA,$00        ; MOVE to 202, 0
  DEFB $80,$D5            ; LINE of 22 pixels right, stepping up every 4
  DEFB $80,$55            ; LINE of 22 pixels right, stepping up every 2
  DEFB $80,$15            ; LINE of 22 pixels diagonally right and up
  DEFB $08,$A3,$1F        ; MOVE to 163, 31
  DEFB $81,$D5            ; LINE of 22 pixels up, stepping right every 4
  DEFB $89,$49            ; LINE of 10 pixels up, stepping right every 6
  DEFB $83,$C9            ; LINE of 10 pixels down, stepping right every 4
  DEFB $83,$D4            ; LINE of 21 pixels down, stepping right every 4
  DEFB $87,$03            ; LINE of 4 pixels diagonally down and left
  DEFB $86,$43            ; LINE of 4 pixels left, stepping down every 2
  DEFB $84,$04            ; LINE of 5 pixels diagonally left and up
  DEFB $8E,$4B            ; LINE of 12 pixels left, stepping down every 6
  DEFB $8E,$0B            ; LINE of 12 pixels left, stepping down every 5
  DEFB $86,$8B            ; LINE of 12 pixels left, stepping down every 3
  DEFB $86,$4B            ; LINE of 12 pixels left, stepping down every 2
  DEFB $88,$8B            ; LINE of 12 pixels right, stepping up every 7
  DEFB $80,$CB            ; LINE of 12 pixels right, stepping up every 4
  DEFB $80,$CB            ; LINE of 12 pixels right, stepping up every 4
  DEFB $88,$50            ; LINE of 17 pixels right, stepping up every 6
  DEFB $40,$A5,$20        ; FILL with black from 165, 32
  DEFB $40,$A7,$24        ; FILL with black from 167, 36
  DEFB $40,$A6,$28        ; FILL with black from 166, 40
  DEFB $40,$A1,$1D        ; FILL with black from 161, 29
  DEFB $44,$AE,$20        ; FILL with green from 174, 32
  DEFB $44,$AC,$1E        ; FILL with green from 172, 30
  DEFB $44,$AB,$2A        ; FILL with green from 171, 42
  DEFB $44,$AA,$31        ; FILL with green from 170, 49
  DEFB $44,$A8,$39        ; FILL with green from 168, 57
  DEFB $08,$D6,$2A        ; MOVE to 214, 42
  DEFB $88,$09            ; LINE of 10 pixels right, stepping up every 5
  DEFB $40,$DE,$2E        ; FILL with black from 222, 46
  DEFB $08,$1D,$29        ; MOVE to 29, 41
  DEFB $80,$51            ; LINE of 18 pixels right, stepping up every 2
  DEFB $80,$90            ; LINE of 17 pixels right, stepping up every 3
  DEFB $81,$4A            ; LINE of 11 pixels up, stepping right every 2
  DEFB $81,$49            ; LINE of 10 pixels up, stepping right every 2
  DEFB $80,$46            ; LINE of 7 pixels right, stepping up every 2
  DEFB $81,$48            ; LINE of 9 pixels up, stepping right every 2
  DEFB $81,$88            ; LINE of 9 pixels up, stepping right every 3
  DEFB $82,$C6            ; LINE of 7 pixels right, stepping down every 4
  DEFB $80,$43            ; LINE of 4 pixels right, stepping up every 2
  DEFB $82,$42            ; LINE of 3 pixels right, stepping down every 2
  DEFB $80,$46            ; LINE of 7 pixels right, stepping up every 2
  DEFB $83,$85            ; LINE of 6 pixels down, stepping right every 3
  DEFB $83,$46            ; LINE of 7 pixels down, stepping right every 2
  DEFB $87,$C6            ; LINE of 7 pixels down, stepping left every 4
  DEFB $80,$85            ; LINE of 6 pixels right, stepping up every 3
  DEFB $83,$49            ; LINE of 10 pixels down, stepping right every 2
  DEFB $83,$03            ; LINE of 4 pixels diagonally down and right
  DEFB $83,$43            ; LINE of 4 pixels down, stepping right every 2
  DEFB $82,$83            ; LINE of 4 pixels right, stepping down every 3
  DEFB $82,$4A            ; LINE of 11 pixels right, stepping down every 2
  DEFB $8B,$0A            ; LINE of 11 pixels down, stepping right every 5
  DEFB $83,$48            ; LINE of 9 pixels down, stepping right every 2
  DEFB $25,$59,$54,$04,$01,$0A,$00,$01 ; PAINT cyan ink from row 10, column 20,
  DEFB $00,$FF                         ; along a path of 6 steps
  DEFB $08,$49,$25        ; MOVE to 73, 37
  DEFB $81,$89            ; LINE of 10 pixels up, stepping right every 3
  DEFB $81,$49            ; LINE of 10 pixels up, stepping right every 2
  DEFB $80,$09            ; LINE of 10 pixels diagonally right and up
  DEFB $89,$09            ; LINE of 10 pixels up, stepping right every 5
  DEFB $91,$09            ; LINE of 10 pixels up, stepping right every 9
  DEFB $91,$09            ; LINE of 10 pixels up, stepping right every 9
  DEFB $40,$5C,$57        ; FILL with black from 92, 87
  DEFB $08,$9F,$28        ; MOVE to 159, 40
  DEFB $A9,$D7            ; LINE of 24 pixels up, stepping right every 24
  DEFB $A0,$0F            ; LINE of 16 pixels right, stepping up every 17
  DEFB $A3,$0F            ; LINE of 16 pixels down, stepping right every 17
  DEFB $8A,$C7            ; LINE of 8 pixels right, stepping down every 8
  DEFB $8B,$C7            ; LINE of 8 pixels down, stepping right every 8
  DEFB $25,$59,$43,$01,$00,$05,$00,$05 ; PAINT cyan ink from row 10, column 3,
  DEFB $00,$01,$00,$01,$04,$FF         ; along a path of 10 steps
  DEFB $08,$17,$29        ; MOVE to 23, 41
  DEFB $89,$86            ; LINE of 7 pixels up, stepping right every 7
  DEFB $88,$C6            ; LINE of 7 pixels right, stepping up every 8
  DEFB $89,$C7            ; LINE of 8 pixels up, stepping right every 8
  DEFB $98,$CE            ; LINE of 15 pixels right, stepping up every 16
  DEFB $89,$C7            ; LINE of 8 pixels up, stepping right every 8
  DEFB $98,$CE            ; LINE of 15 pixels right, stepping up every 16
  DEFB $89,$C7            ; LINE of 8 pixels up, stepping right every 8
  DEFB $88,$C6            ; LINE of 7 pixels right, stepping up every 8
  DEFB $89,$C7            ; LINE of 8 pixels up, stepping right every 8
  DEFB $88,$C6            ; LINE of 7 pixels right, stepping up every 8
  DEFB $89,$C7            ; LINE of 8 pixels up, stepping right every 8
  DEFB $88,$86            ; LINE of 7 pixels right, stepping up every 7
  DEFB $81,$07            ; LINE of 8 pixels diagonally up and right
  DEFB $21,$58,$6B,$09,$02,$0B,$02,$0D ; PAINT blue ink from row 3, column 11,
  DEFB $02,$13,$02,$19,$02,$1F,$02,$21 ; along a path of 17 steps
  DEFB $02,$23,$02,$09,$FF             ;
  DEFB $44,$5C,$23        ; FILL with green from 92, 35
  DEFB $25,$58,$0B,$06,$09,$04,$07,$02 ; PAINT cyan ink from row 0, column 11,
  DEFB $05,$FF                         ; along a path of 6 steps
  DEFB $08,$57,$7F        ; MOVE to 87, 127
  DEFB $B7,$58            ; LINE of 25 pixels down, stepping left every 26
  DEFB $08,$57,$67        ; MOVE to 87, 103
  DEFB $C0,$20            ; LINE of 33 pixels right, stepping up every 33
  DEFB $A9,$E0            ; LINE of 33 pixels up, stepping right every 24
  DEFB $08,$5A,$6E        ; MOVE to 90, 110
  DEFB $80,$02            ; LINE of 3 pixels diagonally right and up
  DEFB $82,$82            ; LINE of 3 pixels right, stepping down every 3
  DEFB $82,$01            ; LINE of 2 pixels diagonally right and down
  DEFB $81,$01            ; LINE of 2 pixels diagonally up and right
  DEFB $80,$42            ; LINE of 3 pixels right, stepping up every 2
  DEFB $82,$42            ; LINE of 3 pixels right, stepping down every 2
  DEFB $45,$79,$7A        ; FILL with cyan from 121, 122
  DEFB $00                ; End of the picture

; Unused
;
; Zeros after the last picture. Nothing reads or writes them.
AFTER_PICTURES:
  DEFS $A5

; Where START keeps the world as it was loaded
;
; The object records and then the room records, $0BEE bytes, which START copies
; here once and copies back for every new game. The copy runs on past the end
; of the game's code, to $FFED; on the tape this part is zeros.
WORLD_COPY:
  DEFS $0840

