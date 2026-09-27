    DEVICE ZXSPECTRUM48
  ORG $5E00

; Where the BASIC loader enters the game
;
; The loader's last statement is a PRINT USR to this address. The stack goes
; just under this code, where the loader's CLEAR put RAMTOP anyway, and the
; game starts at START.
ENTRY:
  DI
  LD SP,ENTRY
  JP START

; Room sizes
;
; Three entries: the half-size in U, the half-size in V (about the room's
; centre at 128), and the floor's height, 128 in all three. Bits 3-7 of a room
; record's third byte pick one, and the builder (BUILD_ROOM) copies it to
; ROOM_EXTENT.
ROOM_SIZES:
  DEFB $40,$40,$80        ; Size 0
  DEFB $20,$40,$80        ; Size 1
  DEFB $40,$20,$80        ; Size 2

; Room 0: 128 by 128, white; doorways to 147
;
; 4 pieces of scenery and 15 objects in 4 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
;
; The room directory: 139 records, one per room, end to end up to
; SCENERY_TABLE. BUILD_ROOM finds a room by stepping from one record to the
; next until the number matches.
;
; A record is +0 the room number, +1 the count of bytes that follow it, +2 the
; room's ink (bits 0-2; the builder adds BRIGHT) and its size (bits 3-7, an
; index into ROOM_SIZES). Then the scenery, two bytes an entry -- a scenery
; template (SCENERY_TABLE) and, for a doorway, the room it leads to -- up to an
; $FF; then the objects in groups, a header byte (bits 0-2: how many, less one;
; bits 3-7: the object template, OBJECT_TABLE) and a position byte for each: U
; in bits 0-2, V in bits 3-5, the level in bits 6-7. Nothing ends a record but
; the count at +1 running out, and a group can be cut short by it.
;
; Each room is an entry of its own, laid out from the game's data when the
; disassembly is built.
ROOMS:
  DEFB $00,$1E,$07        ; Room 0; 30 bytes follow; ink 7, size 0
  DEFB $18,$93            ; Scenery template 24: a doorway to room 147
  DEFB $1C,$00            ; Scenery template 28
  DEFB $0C,$00            ; Scenery template 12
  DEFB $0D,$00            ; Scenery template 13
  DEFB $FF                ; End of the scenery
  DEFB $01,$FD,$FE        ; Object template 0 x2 at (5,7,3), (6,7,3)
  DEFB $BD,$5A,$75,$B5,$F5,$35,$1A ; Object template 23 x6 at (2,3,1), (5,6,1),
                                   ; (5,6,2), (5,6,3), (5,6,0), (2,3,0)
  DEFB $1D,$2E,$25,$1E,$1C,$15,$33 ; Object template 3 x6 at (6,5,0), (5,4,0),
                                   ; (6,3,0), (4,3,0), (5,2,0), (3,6,0)
  DEFB $88,$9D            ; Object template 17 at (5,3,2)

; Room 1: 128 by 128, red; doorways to 3, 2
;
; 4 pieces of scenery and 6 objects in 1 group. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM1:
  DEFB $01,$12,$02        ; Room 1; 18 bytes follow; ink 2, size 0
  DEFB $00,$03            ; Scenery template 0: a doorway to room 3
  DEFB $05,$02            ; Scenery template 5: a doorway to room 2
  DEFB $08,$00            ; Scenery template 8
  DEFB $0B,$00            ; Scenery template 11
  DEFB $FF                ; End of the scenery
  DEFB $2D,$2F,$26,$1E,$2D,$24,$23 ; Object template 5 x6 at (7,5,0), (6,4,0),
                                   ; (6,3,0), (5,5,0), (4,4,0), (3,4,0)

; Room 2: 128 by 128, magenta; doorways to 1, 149
;
; 5 pieces of scenery and 20 objects in 7 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM2:
  DEFB $02,$28,$03        ; Room 2; 40 bytes follow; ink 3, size 0
  DEFB $07,$01            ; Scenery template 7: a doorway to room 1
  DEFB $18,$95            ; Scenery template 24: a doorway to room 149
  DEFB $1C,$00            ; Scenery template 28
  DEFB $0E,$00            ; Scenery template 14
  DEFB $0D,$00            ; Scenery template 13
  DEFB $FF                ; End of the scenery
  DEFB $42,$2E,$16,$39    ; Object template 8 x3 at (6,5,0), (6,2,0), (1,7,0)
  DEFB $46,$79,$B9,$F9,$56,$96,$6E,$AE ; Object template 8 x7 at (1,7,1),
                                       ; (1,7,2), (1,7,3), (6,2,1), (6,2,2),
                                       ; (6,5,1), (6,5,2)
  DEFB $80,$91            ; Object template 16 at (1,2,2)
  DEFB $88,$99            ; Object template 17 at (1,3,2)
  DEFB $60,$38            ; Object template 12 at (0,7,0)
  DEFB $01,$FD,$FE        ; Object template 0 x2 at (5,7,3), (6,7,3)
  DEFB $2C,$19,$1B,$09,$0B,$26 ; Object template 5 x5 at (1,3,0), (3,3,0),
                               ; (1,1,0), (3,1,0), (6,4,0)

; Room 3: 128 by 128, green; doorways to 7, 1
;
; 4 pieces of scenery and 4 objects in 2 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM3:
  DEFB $03,$11,$04        ; Room 3; 17 bytes follow; ink 4, size 0
  DEFB $00,$07            ; Scenery template 0: a doorway to room 7
  DEFB $02,$01            ; Scenery template 2: a doorway to room 1
  DEFB $08,$00            ; Scenery template 8
  DEFB $0B,$00            ; Scenery template 11
  DEFB $FF                ; End of the scenery
  DEFB $22,$1A,$1B,$1C    ; Object template 4 x3 at (2,3,0), (3,3,0), (4,3,0)
  DEFB $90,$0E            ; Object template 18 at (6,1,0)

; Room 4: 128 by 128, cyan; doorways to 9
;
; 3 pieces of scenery and 12 objects in 4 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM4:
  DEFB $04,$19,$05        ; Room 4; 25 bytes follow; ink 5, size 0
  DEFB $00,$09            ; Scenery template 0: a doorway to room 9
  DEFB $08,$00            ; Scenery template 8
  DEFB $0B,$00            ; Scenery template 11
  DEFB $FF                ; End of the scenery
  DEFB $2E,$2A,$22,$1A,$12,$1E,$27,$17 ; Object template 5 x7 at (2,5,0),
                                       ; (2,4,0), (2,3,0), (2,2,0), (6,3,0),
                                       ; (7,4,0), (7,2,0)
  DEFB $02,$1F,$5F,$DF    ; Object template 0 x3 at (7,3,0), (7,3,1), (7,3,3)
  DEFB $C0,$6A            ; Object template 24 at (2,5,1)
  DEFB $80,$9F            ; Object template 16 at (7,3,2)

; Room 5: 128 by 128, yellow; doorways to 6
;
; 3 pieces of scenery and 9 objects in 3 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM5:
  DEFB $05,$15,$06        ; Room 5; 21 bytes follow; ink 6, size 0
  DEFB $01,$06            ; Scenery template 1: a doorway to room 6
  DEFB $08,$00            ; Scenery template 8
  DEFB $09,$00            ; Scenery template 9
  DEFB $FF                ; End of the scenery
  DEFB $0A,$1A,$5A,$9A    ; Object template 1 x3 at (2,3,0), (2,3,1), (2,3,2)
  DEFB $2B,$22,$1B,$12,$19 ; Object template 5 x4 at (2,4,0), (3,3,0), (2,2,0),
                           ; (1,3,0)
  DEFB $21,$2D,$6D        ; Object template 4 x2 at (5,5,0), (5,5,1)

; Room 6: 128 by 64, white; doorways to 7, 5
;
; 3 pieces of scenery and 2 objects in 1 group. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM6:
  DEFB $06,$0C,$17        ; Room 6; 12 bytes follow; ink 7, size 2
  DEFB $01,$07            ; Scenery template 1: a doorway to room 7
  DEFB $03,$05            ; Scenery template 3: a doorway to room 5
  DEFB $11,$00            ; Scenery template 17
  DEFB $FF                ; End of the scenery
  DEFB $F1,$14,$2B        ; Object template 30 x2 at (4,2,0), (3,5,0)

; Room 7: 128 by 128, red; doorways to 8, 3, 6
;
; 5 pieces of scenery and 16 objects in 2 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM7:
  DEFB $07,$1F,$02        ; Room 7; 31 bytes follow; ink 2, size 0
  DEFB $01,$08            ; Scenery template 1: a doorway to room 8
  DEFB $02,$03            ; Scenery template 2: a doorway to room 3
  DEFB $03,$06            ; Scenery template 3: a doorway to room 6
  DEFB $0A,$00            ; Scenery template 10
  DEFB $09,$00            ; Scenery template 9
  DEFB $FF                ; End of the scenery
  DEFB $1F,$05,$0E,$17,$2F,$36,$3D,$3A ; Object template 3 x8 at (5,0,0),
  DEFB $31                             ; (6,1,0), (7,2,0), (7,5,0), (6,6,0),
                                       ; (5,7,0), (2,7,0), (1,6,0)
  DEFB $1F,$28,$10,$09,$02,$23,$24,$1B ; Object template 3 x8 at (0,5,0),
  DEFB $1C                             ; (0,2,0), (1,1,0), (2,0,0), (3,4,0),
                                       ; (4,4,0), (3,3,0), (4,3,0)

; Room 8: 128 by 128, green; doorways to 20, 7
;
; 4 pieces of scenery and 3 objects in 1 group. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM8:
  DEFB $08,$0F,$04        ; Room 8; 15 bytes follow; ink 4, size 0
  DEFB $00,$14            ; Scenery template 0: a doorway to room 20
  DEFB $03,$07            ; Scenery template 3: a doorway to room 7
  DEFB $0A,$00            ; Scenery template 10
  DEFB $0B,$00            ; Scenery template 11
  DEFB $FF                ; End of the scenery
  DEFB $72,$EA,$D2,$ED    ; Object template 14 x3 at (2,5,3), (2,2,3), (5,5,3)

; Room 9: 128 by 128, cyan; doorways to 21, 10, 4
;
; 5 pieces of scenery and 9 objects in 2 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM9:
  DEFB $09,$18,$05        ; Room 9; 24 bytes follow; ink 5, size 0
  DEFB $00,$15            ; Scenery template 0: a doorway to room 21
  DEFB $01,$0A            ; Scenery template 1: a doorway to room 10
  DEFB $02,$04            ; Scenery template 2: a doorway to room 4
  DEFB $08,$00            ; Scenery template 8
  DEFB $0B,$00            ; Scenery template 11
  DEFB $FF                ; End of the scenery
  DEFB $27,$2B,$2C,$25,$1D,$13,$14,$22 ; Object template 4 x8 at (3,5,0),
  DEFB $1A                             ; (4,5,0), (5,4,0), (5,3,0), (3,2,0),
                                       ; (4,2,0), (2,4,0), (2,3,0)
  DEFB $90,$24            ; Object template 18 at (4,4,0)

; Room 10: 128 by 64, cyan; doorways to 11, 9
;
; 3 pieces of scenery and 0 objects in 0 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM10:
  DEFB $0A,$08,$15        ; Room 10; 8 bytes follow; ink 5, size 2
  DEFB $01,$0B            ; Scenery template 1: a doorway to room 11
  DEFB $03,$09            ; Scenery template 3: a doorway to room 9
  DEFB $11,$00            ; Scenery template 17

; Room 11: 128 by 64, yellow; doorways to 12, 10
;
; 3 pieces of scenery and 16 objects in 4 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM11:
  DEFB $0B,$1D,$16        ; Room 11; 29 bytes follow; ink 6, size 2
  DEFB $01,$0C            ; Scenery template 1: a doorway to room 12
  DEFB $03,$0A            ; Scenery template 3: a doorway to room 10
  DEFB $11,$00            ; Scenery template 17
  DEFB $FF                ; End of the scenery
  DEFB $0F,$14,$54,$94,$D4,$1C,$5C,$9C ; Object template 1 x8 at (4,2,0),
  DEFB $DC                             ; (4,2,1), (4,2,2), (4,2,3), (4,3,0),
                                       ; (4,3,1), (4,3,2), (4,3,3)
  DEFB $0B,$2C,$6C,$AC,$EC ; Object template 1 x4 at (4,5,0), (4,5,1), (4,5,2),
                           ; (4,5,3)
  DEFB $22,$24,$64,$A4    ; Object template 4 x3 at (4,4,0), (4,4,1), (4,4,2)
  DEFB $78,$E4            ; Object template 15 at (4,4,3)

; Room 12: 128 by 128, white; doorways to 22, 13, 11
;
; 5 pieces of scenery and 18 objects in 3 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM12:
  DEFB $0C,$22,$07        ; Room 12; 34 bytes follow; ink 7, size 0
  DEFB $00,$16            ; Scenery template 0: a doorway to room 22
  DEFB $01,$0D            ; Scenery template 1: a doorway to room 13
  DEFB $03,$0B            ; Scenery template 3: a doorway to room 11
  DEFB $0A,$00            ; Scenery template 10
  DEFB $0B,$00            ; Scenery template 11
  DEFB $FF                ; End of the scenery
  DEFB $1F,$10,$11,$12,$13,$14,$15,$16 ; Object template 3 x8 at (0,2,0),
  DEFB $17                             ; (1,2,0), (2,2,0), (3,2,0), (4,2,0),
                                       ; (5,2,0), (6,2,0), (7,2,0)
  DEFB $1F,$28,$29,$2A,$32,$3A,$3D,$35 ; Object template 3 x8 at (0,5,0),
  DEFB $2D                             ; (1,5,0), (2,5,0), (2,6,0), (2,7,0),
                                       ; (5,7,0), (5,6,0), (5,5,0)
  DEFB $19,$2E,$2F        ; Object template 3 x2 at (6,5,0), (7,5,0)

; Room 13: 128 by 64, red; doorways to 14, 12
;
; 3 pieces of scenery and 16 objects in 3 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM13:
  DEFB $0D,$1C,$12        ; Room 13; 28 bytes follow; ink 2, size 2
  DEFB $01,$0E            ; Scenery template 1: a doorway to room 14
  DEFB $03,$0C            ; Scenery template 3: a doorway to room 12
  DEFB $11,$00            ; Scenery template 17
  DEFB $FF                ; End of the scenery
  DEFB $1F,$22,$23,$24,$25,$1A,$1B,$1C ; Object template 3 x8 at (2,4,0),
  DEFB $1D                             ; (3,4,0), (4,4,0), (5,4,0), (2,3,0),
                                       ; (3,3,0), (4,3,0), (5,3,0)
  DEFB $25,$12,$14,$15,$2A,$2B,$2D ; Object template 4 x6 at (2,2,0), (4,2,0),
                                   ; (5,2,0), (2,5,0), (3,5,0), (5,5,0)
  DEFB $92,$2C,$13        ; Object template 18 x2 at (4,5,0), (3,2,0) -- the
                          ; header says 3, but the record's byte count runs out
                          ; first

; Room 14: 128 by 128, magenta; doorways to 23, 13
;
; 4 pieces of scenery and 5 objects in 2 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM14:
  DEFB $0E,$12,$03        ; Room 14; 18 bytes follow; ink 3, size 0
  DEFB $00,$17            ; Scenery template 0: a doorway to room 23
  DEFB $03,$0D            ; Scenery template 3: a doorway to room 13
  DEFB $0A,$00            ; Scenery template 10
  DEFB $0B,$00            ; Scenery template 11
  DEFB $FF                ; End of the scenery
  DEFB $73,$2B,$24,$22,$1B ; Object template 14 x4 at (3,5,0), (4,4,0),
                           ; (2,4,0), (3,3,0)
  DEFB $90,$23            ; Object template 18 at (3,4,0)

; Room 15: 128 by 128, green; doorways to 24
;
; 3 pieces of scenery and 16 objects in 7 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM15:
  DEFB $0F,$20,$04        ; Room 15; 32 bytes follow; ink 4, size 0
  DEFB $04,$18            ; Scenery template 4: a doorway to room 24
  DEFB $0C,$00            ; Scenery template 12
  DEFB $0F,$00            ; Scenery template 15
  DEFB $FF                ; End of the scenery
  DEFB $BA,$03,$43,$83    ; Object template 23 x3 at (3,0,0), (3,0,1), (3,0,2)
  DEFB $1F,$20,$21,$22,$23,$1B,$13,$0B ; Object template 3 x8 at (0,4,0),
  DEFB $04                             ; (1,4,0), (2,4,0), (3,4,0), (3,3,0),
                                       ; (3,2,0), (3,1,0), (4,0,0)
  DEFB $90,$19            ; Object template 18 at (1,3,0)
  DEFB $80,$C5            ; Object template 16 at (5,0,3)
  DEFB $50,$9D            ; Object template 10 at (5,3,2)
  DEFB $C0,$2D            ; Object template 24 at (5,5,0)
  DEFB $18,$05            ; Object template 3 at (5,0,0)

; Room 16: 128 by 128, cyan; doorways to 17
;
; 3 pieces of scenery and 8 objects in 4 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM16:
  DEFB $10,$15,$05        ; Room 16; 21 bytes follow; ink 5, size 0
  DEFB $05,$11            ; Scenery template 5: a doorway to room 17
  DEFB $0C,$00            ; Scenery template 12
  DEFB $0D,$00            ; Scenery template 13
  DEFB $FF                ; End of the scenery
  DEFB $00,$D8            ; Object template 0 at (0,3,3)
  DEFB $C0,$88            ; Object template 24 at (0,1,2)
  DEFB $1C,$10,$08,$00,$18,$19 ; Object template 3 x5 at (0,2,0), (0,1,0),
                               ; (0,0,0), (0,3,0), (1,3,0)
  DEFB $38,$24            ; Object template 7 at (4,4,0)

; Room 17: 128 by 128, yellow; doorways to 16, 26
;
; 4 pieces of scenery and 0 objects in 0 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM17:
  DEFB $11,$0A,$06        ; Room 17; 10 bytes follow; ink 6, size 0
  DEFB $07,$10            ; Scenery template 7: a doorway to room 16
  DEFB $00,$1A            ; Scenery template 0: a doorway to room 26
  DEFB $0E,$00            ; Scenery template 14
  DEFB $0B,$00            ; Scenery template 11

; Room 18: 128 by 128, white; doorways to 19
;
; 3 pieces of scenery and 14 objects in 3 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM18:
  DEFB $12,$1A,$07        ; Room 18; 26 bytes follow; ink 7, size 0
  DEFB $01,$13            ; Scenery template 1: a doorway to room 19
  DEFB $08,$00            ; Scenery template 8
  DEFB $09,$00            ; Scenery template 9
  DEFB $FF                ; End of the scenery
  DEFB $0B,$09,$49,$89,$C9 ; Object template 1 x4 at (1,1,0), (1,1,1), (1,1,2),
                           ; (1,1,3)
  DEFB $21,$2D,$4C        ; Object template 4 x2 at (5,5,0), (4,1,1)
  DEFB $1F,$01,$02,$08,$11,$12,$0A,$0B ; Object template 3 x8 at (1,0,0),
  DEFB $0C                             ; (2,0,0), (0,1,0), (1,2,0), (2,2,0),
                                       ; (2,1,0), (3,1,0), (4,1,0)

; Room 19: 128 by 128, red; doorways to 28, 20, 18
;
; 5 pieces of scenery and 3 objects in 3 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM19:
  DEFB $13,$13,$02        ; Room 19; 19 bytes follow; ink 2, size 0
  DEFB $00,$1C            ; Scenery template 0: a doorway to room 28
  DEFB $01,$14            ; Scenery template 1: a doorway to room 20
  DEFB $03,$12            ; Scenery template 3: a doorway to room 18
  DEFB $0A,$00            ; Scenery template 10
  DEFB $0B,$00            ; Scenery template 11
  DEFB $FF                ; End of the scenery
  DEFB $38,$1B            ; Object template 7 at (3,3,0)
  DEFB $60,$02            ; Object template 12 at (2,0,0)
  DEFB $70,$0D            ; Object template 14 at (5,1,0)

; Room 20: 128 by 128, magenta; doorways to 21, 8, 19
;
; 5 pieces of scenery and 2 objects in 2 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM20:
  DEFB $14,$11,$03        ; Room 20; 17 bytes follow; ink 3, size 0
  DEFB $01,$15            ; Scenery template 1: a doorway to room 21
  DEFB $02,$08            ; Scenery template 2: a doorway to room 8
  DEFB $03,$13            ; Scenery template 3: a doorway to room 19
  DEFB $0A,$00            ; Scenery template 10
  DEFB $09,$00            ; Scenery template 9
  DEFB $FF                ; End of the scenery
  DEFB $28,$1C            ; Object template 5 at (4,3,0)
  DEFB $A0,$9A            ; Object template 20 at (2,3,2)

; Room 21: 128 by 128, green; doorways to 9, 20
;
; 4 pieces of scenery and 13 objects in 2 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM21:
  DEFB $15,$1A,$04        ; Room 21; 26 bytes follow; ink 4, size 0
  DEFB $02,$09            ; Scenery template 2: a doorway to room 9
  DEFB $03,$14            ; Scenery template 3: a doorway to room 20
  DEFB $0A,$00            ; Scenery template 10
  DEFB $09,$00            ; Scenery template 9
  DEFB $FF                ; End of the scenery
  DEFB $2F,$39,$28,$00,$11,$22,$33,$0B ; Object template 5 x8 at (1,7,0),
  DEFB $1C                             ; (0,5,0), (0,0,0), (1,2,0), (2,4,0),
                                       ; (3,6,0), (3,1,0), (4,3,0)
  DEFB $2C,$2D,$3E,$05,$16,$27 ; Object template 5 x5 at (5,5,0), (6,7,0),
                               ; (5,0,0), (6,2,0), (7,4,0)

; Room 22: 128 by 128, cyan; doorways to 12, 29
;
; 4 pieces of scenery and 2 objects in 1 group. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM22:
  DEFB $16,$0E,$05        ; Room 22; 14 bytes follow; ink 5, size 0
  DEFB $02,$0C            ; Scenery template 2: a doorway to room 12
  DEFB $00,$1D            ; Scenery template 0: a doorway to room 29
  DEFB $08,$00            ; Scenery template 8
  DEFB $0B,$00            ; Scenery template 11
  DEFB $FF                ; End of the scenery
  DEFB $21,$C3,$C4        ; Object template 4 x2 at (3,0,3), (4,0,3)

; Room 23: 128 by 128, yellow; doorways to 14, 31
;
; 4 pieces of scenery and 0 objects in 0 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM23:
  DEFB $17,$0A,$06        ; Room 23; 10 bytes follow; ink 6, size 0
  DEFB $02,$0E            ; Scenery template 2: a doorway to room 14
  DEFB $00,$1F            ; Scenery template 0: a doorway to room 31
  DEFB $08,$00            ; Scenery template 8
  DEFB $0B,$00            ; Scenery template 11

; Room 24: 128 by 128, white; doorways to 25, 15
;
; 4 pieces of scenery and 5 objects in 2 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM24:
  DEFB $18,$12,$07        ; Room 24; 18 bytes follow; ink 7, size 0
  DEFB $05,$19            ; Scenery template 5: a doorway to room 25
  DEFB $06,$0F            ; Scenery template 6: a doorway to room 15
  DEFB $0C,$00            ; Scenery template 12
  DEFB $0D,$00            ; Scenery template 13
  DEFB $FF                ; End of the scenery
  DEFB $33,$14,$1B,$1D,$24 ; Object template 6 x4 at (4,2,0), (3,3,0), (5,3,0),
                           ; (4,4,0)
  DEFB $90,$1C            ; Object template 18 at (4,3,0)

; Room 25: 128 by 128, red; doorways to 34, 24
;
; 4 pieces of scenery and 0 objects in 0 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM25:
  DEFB $19,$0A,$02        ; Room 25; 10 bytes follow; ink 2, size 0
  DEFB $00,$22            ; Scenery template 0: a doorway to room 34
  DEFB $07,$18            ; Scenery template 7: a doorway to room 24
  DEFB $0E,$00            ; Scenery template 14
  DEFB $0B,$00            ; Scenery template 11

; Room 26: 64 by 128, magenta; doorways to 35, 17
;
; 3 pieces of scenery and 3 objects in 2 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM26:
  DEFB $1A,$0E,$0B        ; Room 26; 14 bytes follow; ink 3, size 1
  DEFB $00,$23            ; Scenery template 0: a doorway to room 35
  DEFB $02,$11            ; Scenery template 2: a doorway to room 17
  DEFB $10,$00            ; Scenery template 16
  DEFB $FF                ; End of the scenery
  DEFB $90,$54            ; Object template 18 at (4,2,1)
  DEFB $09,$14,$2C        ; Object template 1 x2 at (4,2,0), (4,5,0)

; Room 27: 128 by 128, green; doorways to 36
;
; 3 pieces of scenery and 7 objects in 5 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM27:
  DEFB $1B,$15,$04        ; Room 27; 21 bytes follow; ink 4, size 0
  DEFB $00,$24            ; Scenery template 0: a doorway to room 36
  DEFB $08,$00            ; Scenery template 8
  DEFB $0B,$00            ; Scenery template 11
  DEFB $FF                ; End of the scenery
  DEFB $C0,$47            ; Object template 24 at (7,0,1)
  DEFB $01,$D7,$D8        ; Object template 0 x2 at (7,2,3), (0,3,3)
  DEFB $80,$DF            ; Object template 16 at (7,3,3)
  DEFB $29,$05,$06        ; Object template 5 x2 at (5,0,0), (6,0,0)
  DEFB $78,$07            ; Object template 15 at (7,0,0)

; Room 28: 64 by 128, cyan; doorways to 40, 19
;
; 3 pieces of scenery and 8 objects in 1 group. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM28:
  DEFB $1C,$12,$0D        ; Room 28; 18 bytes follow; ink 5, size 1
  DEFB $00,$28            ; Scenery template 0: a doorway to room 40
  DEFB $02,$13            ; Scenery template 2: a doorway to room 19
  DEFB $10,$00            ; Scenery template 16
  DEFB $FF                ; End of the scenery
  DEFB $2F,$2A,$2B,$2C,$2D,$12,$13,$14 ; Object template 5 x8 at (2,5,0),
  DEFB $15                             ; (3,5,0), (4,5,0), (5,5,0), (2,2,0),
                                       ; (3,2,0), (4,2,0), (5,2,0)

; Room 29: 128 by 128, yellow; doorways to 22
;
; 3 pieces of scenery and 11 objects in 5 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM29:
  DEFB $1D,$19,$06        ; Room 29; 25 bytes follow; ink 6, size 0
  DEFB $02,$16            ; Scenery template 2: a doorway to room 22
  DEFB $08,$00            ; Scenery template 8
  DEFB $09,$00            ; Scenery template 9
  DEFB $FF                ; End of the scenery
  DEFB $98,$31            ; Object template 19 at (1,6,0)
  DEFB $2E,$20,$21,$22,$23,$3B,$33,$2B ; Object template 5 x7 at (0,4,0),
                                       ; (1,4,0), (2,4,0), (3,4,0), (3,7,0),
                                       ; (3,6,0), (3,5,0)
  DEFB $20,$1C            ; Object template 4 at (4,3,0)
  DEFB $E8,$18            ; Object template 29 at (0,3,0)
  DEFB $F0,$3C            ; Object template 30 at (4,7,0)

; Room 30: 128 by 128, white; doorways to 31
;
; 3 pieces of scenery and 0 objects in 0 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM30:
  DEFB $1E,$08,$07        ; Room 30; 8 bytes follow; ink 7, size 0
  DEFB $01,$1F            ; Scenery template 1: a doorway to room 31
  DEFB $08,$00            ; Scenery template 8
  DEFB $09,$00            ; Scenery template 9

; Room 31: 128 by 128, red; doorways to 32, 23, 30
;
; 5 pieces of scenery and 16 objects in 2 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM31:
  DEFB $1F,$1F,$02        ; Room 31; 31 bytes follow; ink 2, size 0
  DEFB $01,$20            ; Scenery template 1: a doorway to room 32
  DEFB $02,$17            ; Scenery template 2: a doorway to room 23
  DEFB $03,$1E            ; Scenery template 3: a doorway to room 30
  DEFB $0A,$00            ; Scenery template 10
  DEFB $09,$00            ; Scenery template 9
  DEFB $FF                ; End of the scenery
  DEFB $07,$02,$0A,$12,$1B,$24,$2D,$2E ; Object template 0 x8 at (2,0,0),
  DEFB $2F                             ; (2,1,0), (2,2,0), (3,3,0), (4,4,0),
                                       ; (5,5,0), (6,5,0), (7,5,0)
  DEFB $1F,$42,$4A,$52,$5B,$64,$6D,$6E ; Object template 3 x8 at (2,0,1),
  DEFB $6F                             ; (2,1,1), (2,2,1), (3,3,1), (4,4,1),
                                       ; (5,5,1), (6,5,1), (7,5,1)

; Room 32: 128 by 128, magenta; doorways to 46, 33, 31
;
; 5 pieces of scenery and 0 objects in 0 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM32:
  DEFB $20,$0C,$03        ; Room 32; 12 bytes follow; ink 3, size 0
  DEFB $00,$2E            ; Scenery template 0: a doorway to room 46
  DEFB $01,$21            ; Scenery template 1: a doorway to room 33
  DEFB $03,$1F            ; Scenery template 3: a doorway to room 31
  DEFB $0A,$00            ; Scenery template 10
  DEFB $0B,$00            ; Scenery template 11

; Room 33: 128 by 128, green; doorways to 47, 32
;
; 4 pieces of scenery and 0 objects in 0 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM33:
  DEFB $21,$0A,$04        ; Room 33; 10 bytes follow; ink 4, size 0
  DEFB $00,$2F            ; Scenery template 0: a doorway to room 47
  DEFB $03,$20            ; Scenery template 3: a doorway to room 32
  DEFB $0A,$00            ; Scenery template 10
  DEFB $0B,$00            ; Scenery template 11

; Room 34: 128 by 128, cyan; doorways to 48, 35, 25
;
; 5 pieces of scenery and 3 objects in 2 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM34:
  DEFB $22,$12,$05        ; Room 34; 18 bytes follow; ink 5, size 0
  DEFB $00,$30            ; Scenery template 0: a doorway to room 48
  DEFB $01,$23            ; Scenery template 1: a doorway to room 35
  DEFB $02,$19            ; Scenery template 2: a doorway to room 25
  DEFB $08,$00            ; Scenery template 8
  DEFB $0B,$00            ; Scenery template 11
  DEFB $FF                ; End of the scenery
  DEFB $19,$01,$06        ; Object template 3 x2 at (1,0,0), (6,0,0)
  DEFB $E8,$02            ; Object template 29 at (2,0,0)

; Room 35: 128 by 128, yellow; doorways to 36, 26, 34
;
; 5 pieces of scenery and 0 objects in 0 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM35:
  DEFB $23,$0C,$06        ; Room 35; 12 bytes follow; ink 6, size 0
  DEFB $01,$24            ; Scenery template 1: a doorway to room 36
  DEFB $02,$1A            ; Scenery template 2: a doorway to room 26
  DEFB $03,$22            ; Scenery template 3: a doorway to room 34
  DEFB $0A,$00            ; Scenery template 10
  DEFB $09,$00            ; Scenery template 9

; Room 36: 128 by 128, white; doorways to 27, 35
;
; 4 pieces of scenery and 2 objects in 1 group. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM36:
  DEFB $24,$0E,$07        ; Room 36; 14 bytes follow; ink 7, size 0
  DEFB $02,$1B            ; Scenery template 2: a doorway to room 27
  DEFB $03,$23            ; Scenery template 3: a doorway to room 35
  DEFB $0A,$00            ; Scenery template 10
  DEFB $09,$00            ; Scenery template 9
  DEFB $FF                ; End of the scenery
  DEFB $29,$0B,$0C        ; Object template 5 x2 at (3,1,0), (4,1,0)

; Room 37: 128 by 128, red; doorways to 53
;
; 3 pieces of scenery and 15 objects in 4 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM37:
  DEFB $25,$1C,$02        ; Room 37; 28 bytes follow; ink 2, size 0
  DEFB $04,$35            ; Scenery template 4: a doorway to room 53
  DEFB $0C,$00            ; Scenery template 12
  DEFB $0F,$00            ; Scenery template 15
  DEFB $FF                ; End of the scenery
  DEFB $02,$00,$40,$80    ; Object template 0 x3 at (0,0,0), (0,0,1), (0,0,2)
  DEFB $CA,$08,$10,$18    ; Object template 25 x3 at (0,1,0), (0,2,0), (0,3,0)
  DEFB $DA,$01,$02,$03    ; Object template 27 x3 at (1,0,0), (2,0,0), (3,0,0)
  DEFB $1D,$09,$0A,$0B,$11,$12,$19 ; Object template 3 x6 at (1,1,0), (2,1,0),
                                   ; (3,1,0), (1,2,0), (2,2,0), (1,3,0)

; Room 38: 128 by 128, magenta; doorways to 54, 39
;
; 4 pieces of scenery and 14 objects in 3 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM38:
  DEFB $26,$1C,$03        ; Room 38; 28 bytes follow; ink 3, size 0
  DEFB $04,$36            ; Scenery template 4: a doorway to room 54
  DEFB $05,$27            ; Scenery template 5: a doorway to room 39
  DEFB $0C,$00            ; Scenery template 12
  DEFB $0F,$00            ; Scenery template 15
  DEFB $FF                ; End of the scenery
  DEFB $04,$7A,$73,$74,$75,$BE ; Object template 0 x5 at (2,7,1), (3,6,1),
                               ; (4,6,1), (5,6,1), (6,7,2)
  DEFB $1F,$3D,$3E,$36,$2E,$BA,$B3,$B4 ; Object template 3 x8 at (5,7,0),
  DEFB $B5                             ; (6,7,0), (6,6,0), (6,5,0), (2,7,2),
                                       ; (3,6,2), (4,6,2), (5,6,2)
  DEFB $80,$7F            ; Object template 16 at (7,7,1)

; Room 39: 128 by 128, green; doorways to 55, 38
;
; 4 pieces of scenery and 0 objects in 0 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM39:
  DEFB $27,$0A,$04        ; Room 39; 10 bytes follow; ink 4, size 0
  DEFB $04,$37            ; Scenery template 4: a doorway to room 55
  DEFB $07,$26            ; Scenery template 7: a doorway to room 38
  DEFB $0E,$00            ; Scenery template 14
  DEFB $0F,$00            ; Scenery template 15

; Room 40: 64 by 128, cyan; doorways to 56, 28
;
; 3 pieces of scenery and 0 objects in 0 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM40:
  DEFB $28,$08,$0D        ; Room 40; 8 bytes follow; ink 5, size 1
  DEFB $04,$38            ; Scenery template 4: a doorway to room 56
  DEFB $02,$1C            ; Scenery template 2: a doorway to room 28
  DEFB $10,$00            ; Scenery template 16

; Room 41: 128 by 128, magenta; doorways to 57, 140
;
; 5 pieces of scenery and 13 objects in 4 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM41:
  DEFB $29,$1E,$03        ; Room 41; 30 bytes follow; ink 3, size 0
  DEFB $04,$39            ; Scenery template 4: a doorway to room 57
  DEFB $1B,$8C            ; Scenery template 27: a doorway to room 140
  DEFB $1F,$00            ; Scenery template 31
  DEFB $0C,$00            ; Scenery template 12
  DEFB $0F,$00            ; Scenery template 15
  DEFB $FF                ; End of the scenery
  DEFB $06,$D0,$C8,$12,$52,$2A,$6A,$AA ; Object template 0 x7 at (0,2,3),
                                       ; (0,1,3), (2,2,0), (2,2,1), (2,5,0),
                                       ; (2,5,1), (2,5,2)
  DEFB $38,$25            ; Object template 7 at (5,4,0)
  DEFB $70,$92            ; Object template 14 at (2,2,2)
  DEFB $1B,$1A,$13,$0A,$11 ; Object template 3 x4 at (2,3,0), (3,2,0), (2,1,0),
                           ; (1,2,0)

; Room 42: 128 by 128, white; doorways to 58
;
; 3 pieces of scenery and 12 objects in 4 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM42:
  DEFB $2A,$19,$07        ; Room 42; 25 bytes follow; ink 7, size 0
  DEFB $04,$3A            ; Scenery template 4: a doorway to room 58
  DEFB $0C,$00            ; Scenery template 12
  DEFB $0F,$00            ; Scenery template 15
  DEFB $FF                ; End of the scenery
  DEFB $07,$1A,$5A,$9A,$DA,$1C,$5C,$9C ; Object template 0 x8 at (2,3,0),
  DEFB $DC                             ; (2,3,1), (2,3,2), (2,3,3), (4,3,0),
                                       ; (4,3,1), (4,3,2), (4,3,3)
  DEFB $00,$DB            ; Object template 0 at (3,3,3)
  DEFB $59,$1B,$5B        ; Object template 11 x2 at (3,3,0), (3,3,1)
  DEFB $78,$9B            ; Object template 15 at (3,3,2)

; Room 43: 128 by 128, red; doorways to 59, 44
;
; 4 pieces of scenery and 0 objects in 0 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM43:
  DEFB $2B,$0A,$02        ; Room 43; 10 bytes follow; ink 2, size 0
  DEFB $04,$3B            ; Scenery template 4: a doorway to room 59
  DEFB $05,$2C            ; Scenery template 5: a doorway to room 44
  DEFB $0C,$00            ; Scenery template 12
  DEFB $0F,$00            ; Scenery template 15

; Room 44: 128 by 128, magenta; doorways to 60, 43
;
; 4 pieces of scenery and 16 objects in 2 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM44:
  DEFB $2C,$1D,$03        ; Room 44; 29 bytes follow; ink 3, size 0
  DEFB $04,$3C            ; Scenery template 4: a doorway to room 60
  DEFB $07,$2B            ; Scenery template 7: a doorway to room 43
  DEFB $0E,$00            ; Scenery template 14
  DEFB $0F,$00            ; Scenery template 15
  DEFB $FF                ; End of the scenery
  DEFB $0F,$38,$31,$2A,$23,$1C,$15,$0E ; Object template 1 x8 at (0,7,0),
  DEFB $07                             ; (1,6,0), (2,5,0), (3,4,0), (4,3,0),
                                       ; (5,2,0), (6,1,0), (7,0,0)
  DEFB $1F,$78,$71,$6A,$63,$5C,$55,$4E ; Object template 3 x8 at (0,7,1),
  DEFB $47                             ; (1,6,1), (2,5,1), (3,4,1), (4,3,1),
                                       ; (5,2,1), (6,1,1), (7,0,1)

; Room 45: 128 by 128, green; doorways to 61, 46
;
; 4 pieces of scenery and 0 objects in 0 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM45:
  DEFB $2D,$0A,$04        ; Room 45; 10 bytes follow; ink 4, size 0
  DEFB $00,$3D            ; Scenery template 0: a doorway to room 61
  DEFB $01,$2E            ; Scenery template 1: a doorway to room 46
  DEFB $08,$00            ; Scenery template 8
  DEFB $0B,$00            ; Scenery template 11

; Room 46: 128 by 128, cyan; doorways to 32, 45
;
; 4 pieces of scenery and 15 objects in 4 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM46:
  DEFB $2E,$1E,$05        ; Room 46; 30 bytes follow; ink 5, size 0
  DEFB $02,$20            ; Scenery template 2: a doorway to room 32
  DEFB $03,$2D            ; Scenery template 3: a doorway to room 45
  DEFB $0A,$00            ; Scenery template 10
  DEFB $09,$00            ; Scenery template 9
  DEFB $FF                ; End of the scenery
  DEFB $0E,$28,$29,$22,$1A,$11,$10,$19 ; Object template 1 x7 at (0,5,0),
                                       ; (1,5,0), (2,4,0), (2,3,0), (1,2,0),
                                       ; (0,2,0), (1,3,0)
  DEFB $80,$A4            ; Object template 16 at (4,4,2)
  DEFB $88,$05            ; Object template 17 at (5,0,0)
  DEFB $2D,$68,$69,$62,$5A,$51,$50 ; Object template 5 x6 at (0,5,1), (1,5,1),
                                   ; (2,4,1), (2,3,1), (1,2,1), (0,2,1)

; Room 47: 64 by 128, yellow; doorways to 62, 33
;
; 3 pieces of scenery and 9 objects in 3 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM47:
  DEFB $2F,$15,$0E        ; Room 47; 21 bytes follow; ink 6, size 1
  DEFB $00,$3E            ; Scenery template 0: a doorway to room 62
  DEFB $02,$21            ; Scenery template 2: a doorway to room 33
  DEFB $10,$00            ; Scenery template 16
  DEFB $FF                ; End of the scenery
  DEFB $1B,$22,$23,$24,$25 ; Object template 3 x4 at (2,4,0), (3,4,0), (4,4,0),
                           ; (5,4,0)
  DEFB $C3,$62,$63,$64,$65 ; Object template 24 x4 at (2,4,1), (3,4,1),
                           ; (4,4,1), (5,4,1)
  DEFB $E8,$A2            ; Object template 29 at (2,4,2)

; Room 48: 128 by 128, white; doorways to 49, 34
;
; 4 pieces of scenery and 0 objects in 0 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM48:
  DEFB $30,$0A,$07        ; Room 48; 10 bytes follow; ink 7, size 0
  DEFB $01,$31            ; Scenery template 1: a doorway to room 49
  DEFB $02,$22            ; Scenery template 2: a doorway to room 34
  DEFB $08,$00            ; Scenery template 8
  DEFB $09,$00            ; Scenery template 9

; Room 49: 128 by 64, red; doorways to 50, 48
;
; 3 pieces of scenery and 2 objects in 1 group. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM49:
  DEFB $31,$0C,$12        ; Room 49; 12 bytes follow; ink 2, size 2
  DEFB $01,$32            ; Scenery template 1: a doorway to room 50
  DEFB $03,$30            ; Scenery template 3: a doorway to room 48
  DEFB $11,$00            ; Scenery template 17
  DEFB $FF                ; End of the scenery
  DEFB $F1,$14,$2C        ; Object template 30 x2 at (4,2,0), (4,5,0)

; Room 50: 128 by 64, magenta; doorways to 51, 49
;
; 3 pieces of scenery and 0 objects in 0 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM50:
  DEFB $32,$08,$13        ; Room 50; 8 bytes follow; ink 3, size 2
  DEFB $01,$33            ; Scenery template 1: a doorway to room 51
  DEFB $03,$31            ; Scenery template 3: a doorway to room 49
  DEFB $11,$00            ; Scenery template 17

; Room 51: 128 by 128, green; doorways to 63, 52, 50
;
; 5 pieces of scenery and 18 objects in 3 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM51:
  DEFB $33,$22,$04        ; Room 51; 34 bytes follow; ink 4, size 0
  DEFB $00,$3F            ; Scenery template 0: a doorway to room 63
  DEFB $01,$34            ; Scenery template 1: a doorway to room 52
  DEFB $03,$32            ; Scenery template 3: a doorway to room 50
  DEFB $0A,$00            ; Scenery template 10
  DEFB $0B,$00            ; Scenery template 11
  DEFB $FF                ; End of the scenery
  DEFB $1F,$10,$11,$12,$13,$14,$15,$16 ; Object template 3 x8 at (0,2,0),
  DEFB $17                             ; (1,2,0), (2,2,0), (3,2,0), (4,2,0),
                                       ; (5,2,0), (6,2,0), (7,2,0)
  DEFB $1F,$28,$29,$2A,$32,$3A,$3D,$35 ; Object template 3 x8 at (0,5,0),
  DEFB $2D                             ; (1,5,0), (2,5,0), (2,6,0), (2,7,0),
                                       ; (5,7,0), (5,6,0), (5,5,0)
  DEFB $19,$2E,$2F        ; Object template 3 x2 at (6,5,0), (7,5,0)

; Room 52: 128 by 64, cyan; doorways to 53, 51
;
; 3 pieces of scenery and 5 objects in 2 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM52:
  DEFB $34,$10,$15        ; Room 52; 16 bytes follow; ink 5, size 2
  DEFB $05,$35            ; Scenery template 5: a doorway to room 53
  DEFB $03,$33            ; Scenery template 3: a doorway to room 51
  DEFB $11,$00            ; Scenery template 17
  DEFB $FF                ; End of the scenery
  DEFB $2B,$12,$1A,$2D,$25 ; Object template 5 x4 at (2,2,0), (2,3,0), (5,5,0),
                           ; (5,4,0)
  DEFB $A0,$13            ; Object template 20 at (3,2,0)

; Room 53: 128 by 128, yellow; doorways to 64, 54, 37, 52
;
; 6 pieces of scenery and 17 objects in 3 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM53:
  DEFB $35,$23,$06        ; Room 53; 35 bytes follow; ink 6, size 0
  DEFB $04,$40            ; Scenery template 4: a doorway to room 64
  DEFB $05,$36            ; Scenery template 5: a doorway to room 54
  DEFB $06,$25            ; Scenery template 6: a doorway to room 37
  DEFB $07,$34            ; Scenery template 7: a doorway to room 52
  DEFB $0E,$00            ; Scenery template 14
  DEFB $0F,$00            ; Scenery template 15
  DEFB $FF                ; End of the scenery
  DEFB $1F,$38,$31,$2A,$23,$1C,$15,$0E ; Object template 3 x8 at (0,7,0),
  DEFB $07                             ; (1,6,0), (2,5,0), (3,4,0), (4,3,0),
                                       ; (5,2,0), (6,1,0), (7,0,0)
  DEFB $1F,$00,$09,$12,$1B,$24,$2D,$36 ; Object template 3 x8 at (0,0,0),
  DEFB $3F                             ; (1,1,0), (2,2,0), (3,3,0), (4,4,0),
                                       ; (5,5,0), (6,6,0), (7,7,0)
  DEFB $90,$5C            ; Object template 18 at (4,3,1)

; Room 54: 128 by 128, white; doorways to 65, 38, 53
;
; 6 pieces of scenery and 10 objects in 4 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM54:
  DEFB $36,$1D,$07        ; Room 54; 29 bytes follow; ink 7, size 0
  DEFB $18,$41            ; Scenery template 24: a doorway to room 65
  DEFB $06,$26            ; Scenery template 6: a doorway to room 38
  DEFB $07,$35            ; Scenery template 7: a doorway to room 53
  DEFB $0E,$00            ; Scenery template 14
  DEFB $0D,$00            ; Scenery template 13
  DEFB $1C,$00            ; Scenery template 28
  DEFB $FF                ; End of the scenery
  DEFB $01,$FD,$FE        ; Object template 0 x2 at (5,7,3), (6,7,3)
  DEFB $60,$1D            ; Object template 12 at (5,3,0)
  DEFB $C1,$5D,$F5        ; Object template 24 x2 at (5,3,1), (5,6,3)
  DEFB $1C,$25,$1E,$15,$1C,$35 ; Object template 3 x5 at (5,4,0), (6,3,0),
                               ; (5,2,0), (4,3,0), (5,6,0)

; Room 55: 128 by 128, red; doorways to 39, 143
;
; 5 pieces of scenery and 13 objects in 5 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM55:
  DEFB $37,$1F,$02        ; Room 55; 31 bytes follow; ink 2, size 0
  DEFB $06,$27            ; Scenery template 6: a doorway to room 39
  DEFB $19,$8F            ; Scenery template 25: a doorway to room 143
  DEFB $1D,$00            ; Scenery template 29
  DEFB $0C,$00            ; Scenery template 12
  DEFB $0D,$00            ; Scenery template 13
  DEFB $FF                ; End of the scenery
  DEFB $03,$29,$AA,$F7,$EF ; Object template 0 x4 at (1,5,0), (2,5,2), (7,6,3),
                           ; (7,5,3)
  DEFB $1D,$2C,$2D,$2E,$2F,$2A,$2B ; Object template 3 x6 at (4,5,0), (5,5,0),
                                   ; (6,5,0), (7,5,0), (2,5,0), (3,5,0)
  DEFB $C0,$AB            ; Object template 24 at (3,5,2)
  DEFB $58,$EB            ; Object template 11 at (3,5,3)
  DEFB $78,$6C            ; Object template 15 at (4,5,1)

; Room 56: 128 by 128, yellow; doorways to 57, 40
;
; 5 pieces of scenery and 6 objects in 4 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM56:
  DEFB $38,$17,$06        ; Room 56; 23 bytes follow; ink 6, size 0
  DEFB $19,$39            ; Scenery template 25: a doorway to room 57
  DEFB $06,$28            ; Scenery template 6: a doorway to room 40
  DEFB $0C,$00            ; Scenery template 12
  DEFB $0D,$00            ; Scenery template 13
  DEFB $1D,$00            ; Scenery template 29
  DEFB $FF                ; End of the scenery
  DEFB $02,$F7,$EF,$28    ; Object template 0 x3 at (7,6,3), (7,5,3), (0,5,0)
  DEFB $80,$30            ; Object template 16 at (0,6,0)
  DEFB $58,$68            ; Object template 11 at (0,5,1)
  DEFB $18,$37            ; Object template 3 at (7,6,0)

; Room 57: 128 by 128, green; doorways to 58, 41, 56
;
; 5 pieces of scenery and 0 objects in 0 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM57:
  DEFB $39,$0C,$04        ; Room 57; 12 bytes follow; ink 4, size 0
  DEFB $05,$3A            ; Scenery template 5: a doorway to room 58
  DEFB $06,$29            ; Scenery template 6: a doorway to room 41
  DEFB $07,$38            ; Scenery template 7: a doorway to room 56
  DEFB $0E,$00            ; Scenery template 14
  DEFB $0D,$00            ; Scenery template 13

; Room 58: 128 by 128, cyan; doorways to 59, 42, 57
;
; 5 pieces of scenery and 0 objects in 0 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM58:
  DEFB $3A,$0C,$05        ; Room 58; 12 bytes follow; ink 5, size 0
  DEFB $05,$3B            ; Scenery template 5: a doorway to room 59
  DEFB $06,$2A            ; Scenery template 6: a doorway to room 42
  DEFB $07,$39            ; Scenery template 7: a doorway to room 57
  DEFB $0E,$00            ; Scenery template 14
  DEFB $0D,$00            ; Scenery template 13

; Room 59: 128 by 128, yellow; doorways to 66, 60, 43, 58
;
; 8 pieces of scenery and 12 objects in 4 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM59:
  DEFB $3B,$23,$06        ; Room 59; 35 bytes follow; ink 6, size 0
  DEFB $18,$42            ; Scenery template 24: a doorway to room 66
  DEFB $05,$3C            ; Scenery template 5: a doorway to room 60
  DEFB $06,$2B            ; Scenery template 6: a doorway to room 43
  DEFB $1B,$3A            ; Scenery template 27: a doorway to room 58
  DEFB $0C,$00            ; Scenery template 12
  DEFB $0D,$00            ; Scenery template 13
  DEFB $1F,$00            ; Scenery template 31
  DEFB $1C,$00            ; Scenery template 28
  DEFB $FF                ; End of the scenery
  DEFB $05,$FD,$FE,$D0,$C8,$0E,$4E ; Object template 0 x6 at (5,7,3), (6,7,3),
                                   ; (0,2,3), (0,1,3), (6,1,0), (6,1,1)
  DEFB $80,$C9            ; Object template 16 at (1,1,3)
  DEFB $88,$F6            ; Object template 17 at (6,6,3)
  DEFB $1B,$16,$0F,$06,$0D ; Object template 3 x4 at (6,2,0), (7,1,0), (6,0,0),
                           ; (5,1,0)

; Room 60: 128 by 128, white; doorways to 44, 59
;
; 4 pieces of scenery and 0 objects in 0 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM60:
  DEFB $3C,$0A,$07        ; Room 60; 10 bytes follow; ink 7, size 0
  DEFB $06,$2C            ; Scenery template 6: a doorway to room 44
  DEFB $07,$3B            ; Scenery template 7: a doorway to room 59
  DEFB $0E,$00            ; Scenery template 14
  DEFB $0D,$00            ; Scenery template 13

; Room 61: 64 by 128, red; doorways to 67, 45
;
; 3 pieces of scenery and 8 objects in 1 group. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM61:
  DEFB $3D,$12,$0A        ; Room 61; 18 bytes follow; ink 2, size 1
  DEFB $00,$43            ; Scenery template 0: a doorway to room 67
  DEFB $02,$2D            ; Scenery template 2: a doorway to room 45
  DEFB $10,$00            ; Scenery template 16
  DEFB $FF                ; End of the scenery
  DEFB $2F,$2A,$2B,$2C,$2D,$12,$13,$14 ; Object template 5 x8 at (2,5,0),
  DEFB $15                             ; (3,5,0), (4,5,0), (5,5,0), (2,2,0),
                                       ; (3,2,0), (4,2,0), (5,2,0)

; Room 62: 128 by 128, magenta; doorways to 47
;
; 3 pieces of scenery and 13 objects in 4 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM62:
  DEFB $3E,$1A,$03        ; Room 62; 26 bytes follow; ink 3, size 0
  DEFB $02,$2F            ; Scenery template 2: a doorway to room 47
  DEFB $08,$00            ; Scenery template 8
  DEFB $09,$00            ; Scenery template 9
  DEFB $FF                ; End of the scenery
  DEFB $2D,$3A,$33,$2B,$2D,$35,$3D ; Object template 5 x6 at (2,7,0), (3,6,0),
                                   ; (3,5,0), (5,5,0), (5,6,0), (5,7,0)
  DEFB $02,$BB,$B4,$AC    ; Object template 0 x3 at (3,7,2), (4,6,2), (4,5,2)
  DEFB $79,$24,$3C        ; Object template 15 x2 at (4,4,0), (4,7,0)
  DEFB $C1,$64,$7C        ; Object template 24 x2 at (4,4,1), (4,7,1)

; Room 63: 64 by 128, green; doorways to 69, 51
;
; 3 pieces of scenery and 4 objects in 1 group. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM63:
  DEFB $3F,$0E,$0C        ; Room 63; 14 bytes follow; ink 4, size 1
  DEFB $00,$45            ; Scenery template 0: a doorway to room 69
  DEFB $02,$33            ; Scenery template 2: a doorway to room 51
  DEFB $10,$00            ; Scenery template 16
  DEFB $FF                ; End of the scenery
  DEFB $AB,$0D,$13,$32,$2C ; Object template 21 x4 at (5,1,0), (3,2,0),
                           ; (2,6,0), (4,5,0)

; Room 64: 64 by 128, cyan; doorways to 71, 53
;
; 3 pieces of scenery and 12 objects in 2 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM64:
  DEFB $40,$17,$0D        ; Room 64; 23 bytes follow; ink 5, size 1
  DEFB $00,$47            ; Scenery template 0: a doorway to room 71
  DEFB $06,$35            ; Scenery template 6: a doorway to room 53
  DEFB $10,$00            ; Scenery template 16
  DEFB $FF                ; End of the scenery
  DEFB $2F,$1A,$1B,$1C,$1D,$22,$23,$24 ; Object template 5 x8 at (2,3,0),
  DEFB $25                             ; (3,3,0), (4,3,0), (5,3,0), (2,4,0),
                                       ; (3,4,0), (4,4,0), (5,4,0)
  DEFB $C3,$0D,$9D,$A5,$35 ; Object template 24 x4 at (5,1,0), (5,3,2),
                           ; (5,4,2), (5,6,0)

; Room 65: 64 by 128, yellow; doorways to 72, 54
;
; 3 pieces of scenery and 0 objects in 0 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM65:
  DEFB $41,$08,$0E        ; Room 65; 8 bytes follow; ink 6, size 1
  DEFB $04,$48            ; Scenery template 4: a doorway to room 72
  DEFB $06,$36            ; Scenery template 6: a doorway to room 54
  DEFB $14,$00            ; Scenery template 20

; Room 66: 64 by 128, red; doorways to 73, 59
;
; 3 pieces of scenery and 0 objects in 0 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM66:
  DEFB $42,$08,$0A        ; Room 66; 8 bytes follow; ink 2, size 1
  DEFB $04,$49            ; Scenery template 4: a doorway to room 73
  DEFB $06,$3B            ; Scenery template 6: a doorway to room 59
  DEFB $14,$00            ; Scenery template 20

; Room 67: 64 by 128, magenta; doorways to 76, 61
;
; 3 pieces of scenery and 8 objects in 2 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM67:
  DEFB $43,$13,$0B        ; Room 67; 19 bytes follow; ink 3, size 1
  DEFB $00,$4C            ; Scenery template 0: a doorway to room 76
  DEFB $02,$3D            ; Scenery template 2: a doorway to room 61
  DEFB $10,$00            ; Scenery template 16
  DEFB $FF                ; End of the scenery
  DEFB $DB,$1A,$1B,$1C,$1D ; Object template 27 x4 at (2,3,0), (3,3,0),
                           ; (4,3,0), (5,3,0)
  DEFB $1B,$62,$63,$64,$65 ; Object template 3 x4 at (2,4,1), (3,4,1), (4,4,1),
                           ; (5,4,1)

; Room 69: 128 by 128, cyan; doorways to 63
;
; 3 pieces of scenery and 17 objects in 7 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM69:
  DEFB $45,$21,$05        ; Room 69; 33 bytes follow; ink 5, size 0
  DEFB $02,$3F            ; Scenery template 2: a doorway to room 63
  DEFB $08,$00            ; Scenery template 8
  DEFB $09,$00            ; Scenery template 9
  DEFB $FF                ; End of the scenery
  DEFB $59,$FE,$37        ; Object template 11 x2 at (6,7,3), (7,6,0)
  DEFB $80,$FA            ; Object template 16 at (2,7,3)
  DEFB $C0,$E1            ; Object template 24 at (1,4,3)
  DEFB $28,$39            ; Object template 5 at (1,7,0)
  DEFB $90,$25            ; Object template 18 at (5,4,0)
  DEFB $05,$3E,$51,$7E,$B7,$BE,$F7 ; Object template 0 x6 at (6,7,0), (1,2,1),
                                   ; (6,7,1), (7,6,2), (6,7,2), (7,6,3)
  DEFB $04,$11,$36,$76,$B6,$F6 ; Object template 0 x5 at (1,2,0), (6,6,0),
                               ; (6,6,1), (6,6,2), (6,6,3)

; Room 70: 128 by 128, yellow; doorways to 71
;
; 3 pieces of scenery and 17 objects in 3 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM70:
  DEFB $46,$1D,$06        ; Room 70; 29 bytes follow; ink 6, size 0
  DEFB $01,$47            ; Scenery template 1: a doorway to room 71
  DEFB $08,$00            ; Scenery template 8
  DEFB $09,$00            ; Scenery template 9
  DEFB $FF                ; End of the scenery
  DEFB $0F,$2B,$2C,$22,$1A,$13,$14,$1D ; Object template 1 x8 at (3,5,0),
  DEFB $25                             ; (4,5,0), (2,4,0), (2,3,0), (3,2,0),
                                       ; (4,2,0), (5,3,0), (5,4,0)
  DEFB $2F,$6B,$6C,$62,$5A,$53,$54,$5D ; Object template 5 x8 at (3,5,1),
  DEFB $65                             ; (4,5,1), (2,4,1), (2,3,1), (3,2,1),
                                       ; (4,2,1), (5,3,1), (5,4,1)
  DEFB $20,$0E            ; Object template 4 at (6,1,0)

; Room 71: 128 by 128, white; doorways to 72, 64, 70
;
; 5 pieces of scenery and 14 objects in 4 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM71:
  DEFB $47,$1F,$07        ; Room 71; 31 bytes follow; ink 7, size 0
  DEFB $05,$48            ; Scenery template 5: a doorway to room 72
  DEFB $02,$40            ; Scenery template 2: a doorway to room 64
  DEFB $03,$46            ; Scenery template 3: a doorway to room 70
  DEFB $0A,$00            ; Scenery template 10
  DEFB $09,$00            ; Scenery template 9
  DEFB $FF                ; End of the scenery
  DEFB $98,$33            ; Object template 19 at (3,6,0)
  DEFB $21,$15,$55        ; Object template 4 x2 at (5,2,0), (5,2,1)
  DEFB $1F,$39,$31,$29,$21,$22,$23,$24 ; Object template 3 x8 at (1,7,0),
  DEFB $25                             ; (1,6,0), (1,5,0), (1,4,0), (2,4,0),
                                       ; (3,4,0), (4,4,0), (5,4,0)
  DEFB $1A,$2D,$35,$3D    ; Object template 3 x3 at (5,5,0), (5,6,0), (5,7,0)

; Room 72: 128 by 128, red; doorways to 80, 65, 71
;
; 6 pieces of scenery and 2 objects in 1 group. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM72:
  DEFB $48,$12,$02        ; Room 72; 18 bytes follow; ink 2, size 0
  DEFB $04,$50            ; Scenery template 4: a doorway to room 80
  DEFB $1A,$41            ; Scenery template 26: a doorway to room 65
  DEFB $07,$47            ; Scenery template 7: a doorway to room 71
  DEFB $0E,$00            ; Scenery template 14
  DEFB $0F,$00            ; Scenery template 15
  DEFB $1E,$00            ; Scenery template 30
  DEFB $FF                ; End of the scenery
  DEFB $01,$C1,$C2        ; Object template 0 x2 at (1,0,3), (2,0,3)

; Room 73: 128 by 128, magenta; doorways to 83, 74, 66
;
; 6 pieces of scenery and 6 objects in 4 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM73:
  DEFB $49,$19,$03        ; Room 73; 25 bytes follow; ink 3, size 0
  DEFB $18,$53            ; Scenery template 24: a doorway to room 83
  DEFB $05,$4A            ; Scenery template 5: a doorway to room 74
  DEFB $06,$42            ; Scenery template 6: a doorway to room 66
  DEFB $1C,$00            ; Scenery template 28
  DEFB $0C,$00            ; Scenery template 12
  DEFB $0D,$00            ; Scenery template 13
  DEFB $FF                ; End of the scenery
  DEFB $38,$22            ; Object template 7 at (2,4,0)
  DEFB $09,$15,$55        ; Object template 1 x2 at (5,2,0), (5,2,1)
  DEFB $20,$95            ; Object template 4 at (5,2,2)
  DEFB $01,$FD,$FE        ; Object template 0 x2 at (5,7,3), (6,7,3)

; Room 74: 128 by 128, green; doorways to 75, 73
;
; 5 pieces of scenery and 9 objects in 4 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM74:
  DEFB $4A,$1A,$04        ; Room 74; 26 bytes follow; ink 4, size 0
  DEFB $01,$4B            ; Scenery template 1: a doorway to room 75
  DEFB $1B,$49            ; Scenery template 27: a doorway to room 73
  DEFB $0C,$00            ; Scenery template 12
  DEFB $09,$00            ; Scenery template 9
  DEFB $1F,$00            ; Scenery template 31
  DEFB $FF                ; End of the scenery
  DEFB $09,$14,$54        ; Object template 1 x2 at (4,2,0), (4,2,1)
  DEFB $21,$94,$D4        ; Object template 4 x2 at (4,2,2), (4,2,3)
  DEFB $01,$D0,$C8        ; Object template 0 x2 at (0,2,3), (0,1,3)
  DEFB $2A,$1C,$13,$0C    ; Object template 5 x3 at (4,3,0), (3,2,0), (4,1,0)

; Room 75: 128 by 128, cyan; doorways to 84, 74
;
; 4 pieces of scenery and 0 objects in 0 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM75:
  DEFB $4B,$0A,$05        ; Room 75; 10 bytes follow; ink 5, size 0
  DEFB $00,$54            ; Scenery template 0: a doorway to room 84
  DEFB $03,$4A            ; Scenery template 3: a doorway to room 74
  DEFB $0A,$00            ; Scenery template 10
  DEFB $0B,$00            ; Scenery template 11

; Room 76: 128 by 128, yellow; doorways to 86, 77, 67
;
; 5 pieces of scenery and 7 objects in 2 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM76:
  DEFB $4C,$16,$06        ; Room 76; 22 bytes follow; ink 6, size 0
  DEFB $00,$56            ; Scenery template 0: a doorway to room 86
  DEFB $01,$4D            ; Scenery template 1: a doorway to room 77
  DEFB $02,$43            ; Scenery template 2: a doorway to room 67
  DEFB $08,$00            ; Scenery template 8
  DEFB $0B,$00            ; Scenery template 11
  DEFB $FF                ; End of the scenery
  DEFB $75,$02,$05,$17,$2F,$3D,$3A ; Object template 14 x6 at (2,0,0), (5,0,0),
                                   ; (7,2,0), (7,5,0), (5,7,0), (2,7,0)
  DEFB $A0,$07            ; Object template 20 at (7,0,0)

; Room 77: 128 by 128, white; doorways to 87, 78, 76
;
; 5 pieces of scenery and 4 objects in 1 group. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM77:
  DEFB $4D,$12,$07        ; Room 77; 18 bytes follow; ink 7, size 0
  DEFB $04,$57            ; Scenery template 4: a doorway to room 87
  DEFB $01,$4E            ; Scenery template 1: a doorway to room 78
  DEFB $03,$4C            ; Scenery template 3: a doorway to room 76
  DEFB $0A,$00            ; Scenery template 10
  DEFB $0F,$00            ; Scenery template 15
  DEFB $FF                ; End of the scenery
  DEFB $AB,$24,$2A,$1A,$14 ; Object template 21 x4 at (4,4,0), (2,5,0),
                           ; (2,3,0), (4,2,0)

; Room 78: 128 by 128, red; doorways to 77
;
; 3 pieces of scenery and 13 objects in 2 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM78:
  DEFB $4E,$18,$02        ; Room 78; 24 bytes follow; ink 2, size 0
  DEFB $03,$4D            ; Scenery template 3: a doorway to room 77
  DEFB $0A,$00            ; Scenery template 10
  DEFB $0D,$00            ; Scenery template 13
  DEFB $FF                ; End of the scenery
  DEFB $AD,$2B,$24,$1D,$19,$14,$1B ; Object template 21 x6 at (3,5,0), (4,4,0),
                                   ; (5,3,0), (1,3,0), (4,2,0), (3,3,0)
  DEFB $6E,$2D,$22,$26,$12,$16,$0B,$0D ; Object template 13 x7 at (5,5,0),
                                       ; (2,4,0), (6,4,0), (2,2,0), (6,2,0),
                                       ; (3,1,0), (5,1,0)

; Room 80: 128 by 128, green; doorways to 93, 81, 72
;
; 7 pieces of scenery and 18 objects in 4 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM80:
  DEFB $50,$27,$04        ; Room 80; 39 bytes follow; ink 4, size 0
  DEFB $04,$5D            ; Scenery template 4: a doorway to room 93
  DEFB $19,$51            ; Scenery template 25: a doorway to room 81
  DEFB $1A,$48            ; Scenery template 26: a doorway to room 72
  DEFB $0C,$00            ; Scenery template 12
  DEFB $0F,$00            ; Scenery template 15
  DEFB $1D,$00            ; Scenery template 29
  DEFB $1E,$00            ; Scenery template 30
  DEFB $FF                ; End of the scenery
  DEFB $07,$C1,$C2,$EF,$F7,$1B,$5B,$9B ; Object template 0 x8 at (1,0,3),
  DEFB $DB                             ; (2,0,3), (7,5,3), (7,6,3), (3,3,0),
                                       ; (3,3,1), (3,3,2), (3,3,3)
  DEFB $C4,$44,$25,$65,$A5,$E5 ; Object template 24 x5 at (4,0,1), (5,4,0),
                               ; (5,4,1), (5,4,2), (5,4,3)
  DEFB $50,$ED            ; Object template 10 at (5,5,3)
  DEFB $1B,$04,$1A,$1D,$2F ; Object template 3 x4 at (4,0,0), (2,3,0), (5,3,0),
                           ; (7,5,0)

; Room 81: 128 by 128, cyan; doorways to 94, 80
;
; 4 pieces of scenery and 0 objects in 0 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM81:
  DEFB $51,$0A,$05        ; Room 81; 10 bytes follow; ink 5, size 0
  DEFB $04,$5E            ; Scenery template 4: a doorway to room 94
  DEFB $07,$50            ; Scenery template 7: a doorway to room 80
  DEFB $0E,$00            ; Scenery template 14
  DEFB $0F,$00            ; Scenery template 15

; Room 82: 128 by 128, yellow; doorways to 97
;
; 3 pieces of scenery and 0 objects in 0 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM82:
  DEFB $52,$08,$06        ; Room 82; 8 bytes follow; ink 6, size 0
  DEFB $04,$61            ; Scenery template 4: a doorway to room 97
  DEFB $0C,$00            ; Scenery template 12
  DEFB $0F,$00            ; Scenery template 15

; Room 83: 64 by 128, white; doorways to 98, 73
;
; 3 pieces of scenery and 9 objects in 2 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM83:
  DEFB $53,$14,$0F        ; Room 83; 20 bytes follow; ink 7, size 1
  DEFB $04,$62            ; Scenery template 4: a doorway to room 98
  DEFB $06,$49            ; Scenery template 6: a doorway to room 73
  DEFB $14,$00            ; Scenery template 20
  DEFB $FF                ; End of the scenery
  DEFB $1F,$2A,$2B,$2C,$2D,$12,$13,$14 ; Object template 3 x8 at (2,5,0),
  DEFB $15                             ; (3,5,0), (4,5,0), (5,5,0), (2,2,0),
                                       ; (3,2,0), (4,2,0), (5,2,0)
  DEFB $E8,$6A            ; Object template 29 at (2,5,1)

; Room 84: 128 by 128, red; doorways to 99, 85, 75
;
; 5 pieces of scenery and 16 objects in 2 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM84:
  DEFB $54,$1F,$02        ; Room 84; 31 bytes follow; ink 2, size 0
  DEFB $00,$63            ; Scenery template 0: a doorway to room 99
  DEFB $01,$55            ; Scenery template 1: a doorway to room 85
  DEFB $02,$4B            ; Scenery template 2: a doorway to room 75
  DEFB $08,$00            ; Scenery template 8
  DEFB $0B,$00            ; Scenery template 11
  DEFB $FF                ; End of the scenery
  DEFB $2F,$02,$0A,$12,$1A,$22,$2A,$32 ; Object template 5 x8 at (2,0,0),
  DEFB $3A                             ; (2,1,0), (2,2,0), (2,3,0), (2,4,0),
                                       ; (2,5,0), (2,6,0), (2,7,0)
  DEFB $2F,$05,$0D,$15,$1D,$25,$2D,$35 ; Object template 5 x8 at (5,0,0),
  DEFB $3D                             ; (5,1,0), (5,2,0), (5,3,0), (5,4,0),
                                       ; (5,5,0), (5,6,0), (5,7,0)

; Room 85: 128 by 128, magenta; doorways to 86, 84
;
; 4 pieces of scenery and 0 objects in 0 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM85:
  DEFB $55,$0A,$03        ; Room 85; 10 bytes follow; ink 3, size 0
  DEFB $01,$56            ; Scenery template 1: a doorway to room 86
  DEFB $03,$54            ; Scenery template 3: a doorway to room 84
  DEFB $0A,$00            ; Scenery template 10
  DEFB $09,$00            ; Scenery template 9

; Room 86: 128 by 128, green; doorways to 76, 85, 145
;
; 6 pieces of scenery and 14 objects in 5 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM86:
  DEFB $56,$22,$04        ; Room 86; 34 bytes follow; ink 4, size 0
  DEFB $02,$4C            ; Scenery template 2: a doorway to room 76
  DEFB $03,$55            ; Scenery template 3: a doorway to room 85
  DEFB $19,$91            ; Scenery template 25: a doorway to room 145
  DEFB $1D,$00            ; Scenery template 29
  DEFB $0A,$00            ; Scenery template 10
  DEFB $09,$00            ; Scenery template 9
  DEFB $FF                ; End of the scenery
  DEFB $01,$F7,$EF        ; Object template 0 x2 at (7,6,3), (7,5,3)
  DEFB $2C,$0D,$14,$16,$1D,$25 ; Object template 5 x5 at (5,1,0), (4,2,0),
                               ; (6,2,0), (5,3,0), (5,4,0)
  DEFB $50,$95            ; Object template 10 at (5,2,2)
  DEFB $41,$12,$2D        ; Object template 8 x2 at (2,2,0), (5,5,0)
  DEFB $43,$52,$6D,$AD,$ED ; Object template 8 x4 at (2,2,1), (5,5,1), (5,5,2),
                           ; (5,5,3)

; Room 87: 128 by 128, cyan; doorways to 88, 77
;
; 6 pieces of scenery and 19 objects in 4 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM87:
  DEFB $57,$26,$05        ; Room 87; 38 bytes follow; ink 5, size 0
  DEFB $19,$58            ; Scenery template 25: a doorway to room 88
  DEFB $1A,$4D            ; Scenery template 26: a doorway to room 77
  DEFB $0C,$00            ; Scenery template 12
  DEFB $0D,$00            ; Scenery template 13
  DEFB $1D,$00            ; Scenery template 29
  DEFB $1E,$00            ; Scenery template 30
  DEFB $FF                ; End of the scenery
  DEFB $07,$C1,$C2,$C3,$C4,$F7,$EF,$E7 ; Object template 0 x8 at (1,0,3),
  DEFB $DF                             ; (2,0,3), (3,0,3), (4,0,3), (7,6,3),
                                       ; (7,5,3), (7,4,3), (7,3,3)
  DEFB $C4,$CC,$D4,$DC,$DD,$DE ; Object template 24 x5 at (4,1,3), (4,2,3),
                               ; (4,3,3), (5,3,3), (6,3,3)
  DEFB $1C,$0C,$14,$1C,$1D,$1E ; Object template 3 x5 at (4,1,0), (4,2,0),
                               ; (4,3,0), (5,3,0), (6,3,0)
  DEFB $60,$11            ; Object template 12 at (1,2,0)

; Room 88: 128 by 128, yellow; doorways to 103, 87
;
; 4 pieces of scenery and 2 objects in 1 group. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM88:
  DEFB $58,$0E,$06        ; Room 88; 14 bytes follow; ink 6, size 0
  DEFB $04,$67            ; Scenery template 4: a doorway to room 103
  DEFB $07,$57            ; Scenery template 7: a doorway to room 87
  DEFB $0E,$00            ; Scenery template 14
  DEFB $0F,$00            ; Scenery template 15
  DEFB $FF                ; End of the scenery
  DEFB $79,$FB,$FC        ; Object template 15 x2 at (3,7,3), (4,7,3)

; Room 91: 128 by 128, magenta; doorways to 106, 92
;
; 4 pieces of scenery and 2 objects in 1 group. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM91:
  DEFB $5B,$0E,$03        ; Room 91; 14 bytes follow; ink 3, size 0
  DEFB $00,$6A            ; Scenery template 0: a doorway to room 106
  DEFB $01,$5C            ; Scenery template 1: a doorway to room 92
  DEFB $08,$00            ; Scenery template 8
  DEFB $0B,$00            ; Scenery template 11
  DEFB $FF                ; End of the scenery
  DEFB $49,$DF,$E7        ; Object template 9 x2 at (7,3,3), (7,4,3)

; Room 92: 128 by 128, green; doorways to 107, 93, 91
;
; 5 pieces of scenery and 18 objects in 3 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM92:
  DEFB $5C,$22,$04        ; Room 92; 34 bytes follow; ink 4, size 0
  DEFB $00,$6B            ; Scenery template 0: a doorway to room 107
  DEFB $05,$5D            ; Scenery template 5: a doorway to room 93
  DEFB $03,$5B            ; Scenery template 3: a doorway to room 91
  DEFB $0A,$00            ; Scenery template 10
  DEFB $0B,$00            ; Scenery template 11
  DEFB $FF                ; End of the scenery
  DEFB $1F,$10,$11,$12,$13,$14,$15,$16 ; Object template 3 x8 at (0,2,0),
  DEFB $17                             ; (1,2,0), (2,2,0), (3,2,0), (4,2,0),
                                       ; (5,2,0), (6,2,0), (7,2,0)
  DEFB $1F,$28,$29,$2A,$32,$3A,$3D,$35 ; Object template 3 x8 at (0,5,0),
  DEFB $2D                             ; (1,5,0), (2,5,0), (2,6,0), (2,7,0),
                                       ; (5,7,0), (5,6,0), (5,5,0)
  DEFB $19,$2E,$2F        ; Object template 3 x2 at (6,5,0), (7,5,0)

; Room 93: 128 by 128, cyan; doorways to 80, 92
;
; 5 pieces of scenery and 17 objects in 3 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM93:
  DEFB $5D,$21,$05        ; Room 93; 33 bytes follow; ink 5, size 0
  DEFB $06,$50            ; Scenery template 6: a doorway to room 80
  DEFB $1B,$5C            ; Scenery template 27: a doorway to room 92
  DEFB $0C,$00            ; Scenery template 12
  DEFB $0D,$00            ; Scenery template 13
  DEFB $1F,$00            ; Scenery template 31
  DEFB $FF                ; End of the scenery
  DEFB $C7,$C8,$D0,$7E,$FF,$F7,$EF,$E7 ; Object template 24 x8 at (0,1,3),
  DEFB $DF                             ; (0,2,3), (6,7,1), (7,7,3), (7,6,3),
                                       ; (7,5,3), (7,4,3), (7,3,3)
  DEFB $80,$D7            ; Object template 16 at (7,2,3)
  DEFB $1F,$3F,$37,$2F,$27,$1F,$17,$10 ; Object template 3 x8 at (7,7,0),
  DEFB $08                             ; (7,6,0), (7,5,0), (7,4,0), (7,3,0),
                                       ; (7,2,0), (0,2,0), (0,1,0)

; Room 94: 128 by 128, yellow; doorways to 95, 81
;
; 5 pieces of scenery and 13 objects in 5 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM94:
  DEFB $5E,$1F,$06        ; Room 94; 31 bytes follow; ink 6, size 0
  DEFB $19,$5F            ; Scenery template 25: a doorway to room 95
  DEFB $06,$51            ; Scenery template 6: a doorway to room 81
  DEFB $0C,$00            ; Scenery template 12
  DEFB $0D,$00            ; Scenery template 13
  DEFB $1D,$00            ; Scenery template 29
  DEFB $FF                ; End of the scenery
  DEFB $01,$F7,$EF        ; Object template 0 x2 at (7,6,3), (7,5,3)
  DEFB $1F,$19,$1A,$1C,$1D,$0B,$13,$23 ; Object template 3 x8 at (1,3,0),
  DEFB $2B                             ; (2,3,0), (4,3,0), (5,3,0), (3,1,0),
                                       ; (3,2,0), (3,4,0), (3,5,0)
  DEFB $60,$1B            ; Object template 12 at (3,3,0)
  DEFB $88,$EE            ; Object template 17 at (6,5,3)
  DEFB $C0,$59            ; Object template 24 at (1,3,1)

; Room 95: 128 by 128, white; doorways to 96, 94
;
; 4 pieces of scenery and 0 objects in 0 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM95:
  DEFB $5F,$0A,$07        ; Room 95; 10 bytes follow; ink 7, size 0
  DEFB $05,$60            ; Scenery template 5: a doorway to room 96
  DEFB $07,$5E            ; Scenery template 7: a doorway to room 94
  DEFB $0E,$00            ; Scenery template 14
  DEFB $0D,$00            ; Scenery template 13

; Room 96: 128 by 128, red; doorways to 108, 97, 95
;
; 5 pieces of scenery and 9 objects in 2 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM96:
  DEFB $60,$18,$02        ; Room 96; 24 bytes follow; ink 2, size 0
  DEFB $04,$6C            ; Scenery template 4: a doorway to room 108
  DEFB $05,$61            ; Scenery template 5: a doorway to room 97
  DEFB $07,$5F            ; Scenery template 7: a doorway to room 95
  DEFB $0E,$00            ; Scenery template 14
  DEFB $0F,$00            ; Scenery template 15
  DEFB $FF                ; End of the scenery
  DEFB $1F,$28,$29,$2A,$2B,$2C,$2D,$2E ; Object template 3 x8 at (0,5,0),
  DEFB $2F                             ; (1,5,0), (2,5,0), (3,5,0), (4,5,0),
                                       ; (5,5,0), (6,5,0), (7,5,0)
  DEFB $A0,$30            ; Object template 20 at (0,6,0)

; Room 97: 128 by 128, magenta; doorways to 109, 98, 82, 96
;
; 6 pieces of scenery and 0 objects in 0 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM97:
  DEFB $61,$0E,$03        ; Room 97; 14 bytes follow; ink 3, size 0
  DEFB $04,$6D            ; Scenery template 4: a doorway to room 109
  DEFB $05,$62            ; Scenery template 5: a doorway to room 98
  DEFB $06,$52            ; Scenery template 6: a doorway to room 82
  DEFB $07,$60            ; Scenery template 7: a doorway to room 96
  DEFB $0E,$00            ; Scenery template 14
  DEFB $0F,$00            ; Scenery template 15

; Room 98: 128 by 128, green; doorways to 83, 97
;
; 4 pieces of scenery and 5 objects in 2 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM98:
  DEFB $62,$12,$04        ; Room 98; 18 bytes follow; ink 4, size 0
  DEFB $06,$53            ; Scenery template 6: a doorway to room 83
  DEFB $07,$61            ; Scenery template 7: a doorway to room 97
  DEFB $0E,$00            ; Scenery template 14
  DEFB $0D,$00            ; Scenery template 13
  DEFB $FF                ; End of the scenery
  DEFB $33,$14,$1B,$1D,$24 ; Object template 6 x4 at (4,2,0), (3,3,0), (5,3,0),
                           ; (4,4,0)
  DEFB $90,$1C            ; Object template 18 at (4,3,0)

; Room 99: 128 by 128, cyan; doorways to 100, 84
;
; 4 pieces of scenery and 6 objects in 3 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM99:
  DEFB $63,$14,$05        ; Room 99; 20 bytes follow; ink 5, size 0
  DEFB $01,$64            ; Scenery template 1: a doorway to room 100
  DEFB $02,$54            ; Scenery template 2: a doorway to room 84
  DEFB $08,$00            ; Scenery template 8
  DEFB $09,$00            ; Scenery template 9
  DEFB $FF                ; End of the scenery
  DEFB $09,$01,$06        ; Object template 1 x2 at (1,0,0), (6,0,0)
  DEFB $E8,$02            ; Object template 29 at (2,0,0)
  DEFB $AA,$22,$1C,$2D    ; Object template 21 x3 at (2,4,0), (4,3,0), (5,5,0)

; Room 100: 128 by 128, yellow; doorways to 110, 101, 99
;
; 5 pieces of scenery and 18 objects in 3 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM100:
  DEFB $64,$22,$06        ; Room 100; 34 bytes follow; ink 6, size 0
  DEFB $00,$6E            ; Scenery template 0: a doorway to room 110
  DEFB $01,$65            ; Scenery template 1: a doorway to room 101
  DEFB $03,$63            ; Scenery template 3: a doorway to room 99
  DEFB $0A,$00            ; Scenery template 10
  DEFB $0B,$00            ; Scenery template 11
  DEFB $FF                ; End of the scenery
  DEFB $1F,$10,$11,$12,$13,$14,$15,$16 ; Object template 3 x8 at (0,2,0),
  DEFB $17                             ; (1,2,0), (2,2,0), (3,2,0), (4,2,0),
                                       ; (5,2,0), (6,2,0), (7,2,0)
  DEFB $1F,$28,$29,$2A,$32,$3A,$3D,$35 ; Object template 3 x8 at (0,5,0),
  DEFB $2D                             ; (1,5,0), (2,5,0), (2,6,0), (2,7,0),
                                       ; (5,7,0), (5,6,0), (5,5,0)
  DEFB $19,$2E,$2F        ; Object template 3 x2 at (6,5,0), (7,5,0)

; Room 101: 128 by 64, white; doorways to 102, 100
;
; 3 pieces of scenery and 9 objects in 2 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM101:
  DEFB $65,$14,$17        ; Room 101; 20 bytes follow; ink 7, size 2
  DEFB $01,$66            ; Scenery template 1: a doorway to room 102
  DEFB $03,$64            ; Scenery template 3: a doorway to room 100
  DEFB $11,$00            ; Scenery template 17
  DEFB $FF                ; End of the scenery
  DEFB $2F,$2B,$2C,$23,$24,$1B,$1C,$13 ; Object template 5 x8 at (3,5,0),
  DEFB $14                             ; (4,5,0), (3,4,0), (4,4,0), (3,3,0),
                                       ; (4,3,0), (3,2,0), (4,2,0)
  DEFB $80,$6B            ; Object template 16 at (3,5,1)

; Room 102: 128 by 128, red; doorways to 112, 103, 101
;
; 5 pieces of scenery and 0 objects in 0 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM102:
  DEFB $66,$0C,$02        ; Room 102; 12 bytes follow; ink 2, size 0
  DEFB $00,$70            ; Scenery template 0: a doorway to room 112
  DEFB $01,$67            ; Scenery template 1: a doorway to room 103
  DEFB $03,$65            ; Scenery template 3: a doorway to room 101
  DEFB $0A,$00            ; Scenery template 10
  DEFB $0B,$00            ; Scenery template 11

; Room 103: 128 by 128, magenta; doorways to 88, 102
;
; 4 pieces of scenery and 5 objects in 2 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM103:
  DEFB $67,$12,$03        ; Room 103; 18 bytes follow; ink 3, size 0
  DEFB $06,$58            ; Scenery template 6: a doorway to room 88
  DEFB $03,$66            ; Scenery template 3: a doorway to room 102
  DEFB $0A,$00            ; Scenery template 10
  DEFB $09,$00            ; Scenery template 9
  DEFB $FF                ; End of the scenery
  DEFB $71,$C3,$C4        ; Object template 14 x2 at (3,0,3), (4,0,3)
  DEFB $AA,$12,$1C,$2B    ; Object template 21 x3 at (2,2,0), (4,3,0), (3,5,0)

; Room 106: 128 by 128, yellow; doorways to 107, 91
;
; 4 pieces of scenery and 2 objects in 2 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM106:
  DEFB $6A,$0F,$06        ; Room 106; 15 bytes follow; ink 6, size 0
  DEFB $01,$6B            ; Scenery template 1: a doorway to room 107
  DEFB $02,$5B            ; Scenery template 2: a doorway to room 91
  DEFB $08,$00            ; Scenery template 8
  DEFB $09,$00            ; Scenery template 9
  DEFB $FF                ; End of the scenery
  DEFB $90,$78            ; Object template 18 at (0,7,1)
  DEFB $A0,$38            ; Object template 20 at (0,7,0)

; Room 107: 128 by 128, white; doorways to 117, 92, 106
;
; 5 pieces of scenery and 16 objects in 4 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM107:
  DEFB $6B,$21,$07        ; Room 107; 33 bytes follow; ink 7, size 0
  DEFB $00,$75            ; Scenery template 0: a doorway to room 117
  DEFB $02,$5C            ; Scenery template 2: a doorway to room 92
  DEFB $03,$6A            ; Scenery template 3: a doorway to room 106
  DEFB $0A,$00            ; Scenery template 10
  DEFB $0B,$00            ; Scenery template 11
  DEFB $FF                ; End of the scenery
  DEFB $23,$2B,$2C,$6B,$6C ; Object template 4 x4 at (3,5,0), (4,5,0), (3,5,1),
                           ; (4,5,1)
  DEFB $79,$AB,$AC        ; Object template 15 x2 at (3,5,2), (4,5,2)
  DEFB $2F,$38,$39,$31,$32,$2A,$3E,$3F ; Object template 5 x8 at (0,7,0),
  DEFB $35                             ; (1,7,0), (1,6,0), (2,6,0), (2,5,0),
                                       ; (6,7,0), (7,7,0), (5,6,0)
  DEFB $29,$36,$2D        ; Object template 5 x2 at (6,6,0), (5,5,0)

; Room 108: 128 by 128, red; doorways to 96
;
; 3 pieces of scenery and 12 objects in 6 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM108:
  DEFB $6C,$1B,$02        ; Room 108; 27 bytes follow; ink 2, size 0
  DEFB $06,$60            ; Scenery template 6: a doorway to room 96
  DEFB $08,$00            ; Scenery template 8
  DEFB $09,$00            ; Scenery template 9
  DEFB $FF                ; End of the scenery
  DEFB $D8,$23            ; Object template 27 at (3,4,0)
  DEFB $E0,$33            ; Object template 28 at (3,6,0)
  DEFB $02,$32,$34,$7B    ; Object template 0 x3 at (2,6,0), (4,6,0), (3,7,1)
  DEFB $19,$72,$74        ; Object template 3 x2 at (2,6,1), (4,6,1)
  DEFB $78,$2B            ; Object template 15 at (3,5,0)
  DEFB $2C,$39,$3A,$3C,$3D ; Object template 5 x4 at (1,7,0), (2,7,0), (4,7,0),
                           ; (5,7,0) -- the header says 5, but the record's
                           ; byte count runs out first

; Room 109: 128 by 128, magenta; doorways to 118, 97
;
; 4 pieces of scenery and 17 objects in 3 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM109:
  DEFB $6D,$1F,$03        ; Room 109; 31 bytes follow; ink 3, size 0
  DEFB $00,$76            ; Scenery template 0: a doorway to room 118
  DEFB $06,$61            ; Scenery template 6: a doorway to room 97
  DEFB $08,$00            ; Scenery template 8
  DEFB $0B,$00            ; Scenery template 11
  DEFB $FF                ; End of the scenery
  DEFB $2F,$06,$0D,$14,$1B,$23,$2C,$35 ; Object template 5 x8 at (6,0,0),
  DEFB $3E                             ; (5,1,0), (4,2,0), (3,3,0), (3,4,0),
                                       ; (4,5,0), (5,6,0), (6,7,0)
  DEFB $2F,$02,$09,$10,$18,$20,$28,$31 ; Object template 5 x8 at (2,0,0),
  DEFB $3A                             ; (1,1,0), (0,2,0), (0,3,0), (0,4,0),
                                       ; (0,5,0), (1,6,0), (2,7,0)
  DEFB $90,$1E            ; Object template 18 at (6,3,0)

; Room 110: 128 by 128, green; doorways to 111, 100
;
; 4 pieces of scenery and 0 objects in 0 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM110:
  DEFB $6E,$0A,$04        ; Room 110; 10 bytes follow; ink 4, size 0
  DEFB $01,$6F            ; Scenery template 1: a doorway to room 111
  DEFB $02,$64            ; Scenery template 2: a doorway to room 100
  DEFB $08,$00            ; Scenery template 8
  DEFB $09,$00            ; Scenery template 9

; Room 111: 128 by 128, cyan; doorways to 119, 110
;
; 4 pieces of scenery and 5 objects in 2 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM111:
  DEFB $6F,$12,$05        ; Room 111; 18 bytes follow; ink 5, size 0
  DEFB $00,$77            ; Scenery template 0: a doorway to room 119
  DEFB $03,$6E            ; Scenery template 3: a doorway to room 110
  DEFB $0A,$00            ; Scenery template 10
  DEFB $0B,$00            ; Scenery template 11
  DEFB $FF                ; End of the scenery
  DEFB $73,$2B,$24,$22,$1B ; Object template 14 x4 at (3,5,0), (4,4,0),
                           ; (2,4,0), (3,3,0)
  DEFB $90,$23            ; Object template 18 at (3,4,0)

; Room 112: 128 by 128, yellow; doorways to 102
;
; 3 pieces of scenery and 17 objects in 3 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM112:
  DEFB $70,$1D,$06        ; Room 112; 29 bytes follow; ink 6, size 0
  DEFB $02,$66            ; Scenery template 2: a doorway to room 102
  DEFB $08,$00            ; Scenery template 8
  DEFB $09,$00            ; Scenery template 9
  DEFB $FF                ; End of the scenery
  DEFB $6F,$26,$2C,$2E,$2F,$35,$37,$3D ; Object template 13 x8 at (6,4,0),
  DEFB $3F                             ; (4,5,0), (6,5,0), (7,5,0), (5,6,0),
                                       ; (7,6,0), (5,7,0), (7,7,0)
  DEFB $AD,$25,$27,$2D,$34,$36,$3E ; Object template 21 x6 at (5,4,0), (7,4,0),
                                   ; (5,5,0), (4,6,0), (6,6,0), (6,7,0)
  DEFB $0A,$AF,$17,$57    ; Object template 1 x3 at (7,5,2), (7,2,0), (7,2,1)

; Room 117: 64 by 128, cyan; doorways to 122, 107
;
; 3 pieces of scenery and 9 objects in 3 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM117:
  DEFB $75,$15,$0D        ; Room 117; 21 bytes follow; ink 5, size 1
  DEFB $00,$7A            ; Scenery template 0: a doorway to room 122
  DEFB $02,$6B            ; Scenery template 2: a doorway to room 107
  DEFB $10,$00            ; Scenery template 16
  DEFB $FF                ; End of the scenery
  DEFB $0B,$12,$13,$2C,$2D ; Object template 1 x4 at (2,2,0), (3,2,0), (4,5,0),
                           ; (5,5,0)
  DEFB $2B,$52,$53,$6C,$6D ; Object template 5 x4 at (2,2,1), (3,2,1), (4,5,1),
                           ; (5,5,1)
  DEFB $A0,$1A            ; Object template 20 at (2,3,0)

; Room 118: 128 by 128, yellow; doorways to 123, 109
;
; 4 pieces of scenery and 0 objects in 0 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM118:
  DEFB $76,$0A,$06        ; Room 118; 10 bytes follow; ink 6, size 0
  DEFB $00,$7B            ; Scenery template 0: a doorway to room 123
  DEFB $02,$6D            ; Scenery template 2: a doorway to room 109
  DEFB $08,$00            ; Scenery template 8
  DEFB $0B,$00            ; Scenery template 11

; Room 119: 128 by 128, white; doorways to 128, 120, 111
;
; 5 pieces of scenery and 0 objects in 0 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM119:
  DEFB $77,$0C,$07        ; Room 119; 12 bytes follow; ink 7, size 0
  DEFB $00,$80            ; Scenery template 0: a doorway to room 128
  DEFB $01,$78            ; Scenery template 1: a doorway to room 120
  DEFB $02,$6F            ; Scenery template 2: a doorway to room 111
  DEFB $08,$00            ; Scenery template 8
  DEFB $0B,$00            ; Scenery template 11

; Room 120: 128 by 128, red; doorways to 119
;
; 3 pieces of scenery and 14 objects in 4 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM120:
  DEFB $78,$1B,$02        ; Room 120; 27 bytes follow; ink 2, size 0
  DEFB $03,$77            ; Scenery template 3: a doorway to room 119
  DEFB $0A,$00            ; Scenery template 10
  DEFB $09,$00            ; Scenery template 9
  DEFB $FF                ; End of the scenery
  DEFB $0E,$0B,$0C,$0D,$0E,$0F,$4E,$4F ; Object template 1 x7 at (3,1,0),
                                       ; (4,1,0), (5,1,0), (6,1,0), (7,1,0),
                                       ; (6,1,1), (7,1,1)
  DEFB $20,$23            ; Object template 4 at (3,4,0)
  DEFB $2C,$4B,$4C,$4D,$8E,$8F ; Object template 5 x5 at (3,1,1), (4,1,1),
                               ; (5,1,1), (6,1,2), (7,1,2)
  DEFB $E8,$00            ; Object template 29 at (0,0,0)

; Room 122: 128 by 128, green; doorways to 117
;
; 3 pieces of scenery and 0 objects in 0 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM122:
  DEFB $7A,$08,$04        ; Room 122; 8 bytes follow; ink 4, size 0
  DEFB $02,$75            ; Scenery template 2: a doorway to room 117
  DEFB $08,$00            ; Scenery template 8
  DEFB $09,$00            ; Scenery template 9

; Room 123: 128 by 128, cyan; doorways to 124, 118
;
; 4 pieces of scenery and 16 objects in 5 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM123:
  DEFB $7B,$20,$05        ; Room 123; 32 bytes follow; ink 5, size 0
  DEFB $01,$7C            ; Scenery template 1: a doorway to room 124
  DEFB $02,$76            ; Scenery template 2: a doorway to room 118
  DEFB $08,$00            ; Scenery template 8
  DEFB $09,$00            ; Scenery template 9
  DEFB $FF                ; End of the scenery
  DEFB $98,$31            ; Object template 19 at (1,6,0)
  DEFB $6F,$20,$19,$1A,$22,$23,$2C,$34 ; Object template 13 x8 at (0,4,0),
  DEFB $3B                             ; (1,3,0), (2,3,0), (2,4,0), (3,4,0),
                                       ; (4,5,0), (4,6,0), (3,7,0)
  DEFB $AC,$18,$21,$2B,$33,$3C ; Object template 21 x5 at (0,3,0), (1,4,0),
                               ; (3,5,0), (3,6,0), (4,7,0)
  DEFB $50,$B4            ; Object template 10 at (4,6,2)
  DEFB $08,$36            ; Object template 1 at (6,6,0)

; Room 124: 128 by 128, yellow; doorways to 125, 123
;
; 4 pieces of scenery and 0 objects in 0 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM124:
  DEFB $7C,$0A,$06        ; Room 124; 10 bytes follow; ink 6, size 0
  DEFB $01,$7D            ; Scenery template 1: a doorway to room 125
  DEFB $03,$7B            ; Scenery template 3: a doorway to room 123
  DEFB $0A,$00            ; Scenery template 10
  DEFB $09,$00            ; Scenery template 9

; Room 125: 128 by 128, white; doorways to 126, 124
;
; 4 pieces of scenery and 9 objects in 2 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM125:
  DEFB $7D,$16,$07        ; Room 125; 22 bytes follow; ink 7, size 0
  DEFB $01,$7E            ; Scenery template 1: a doorway to room 126
  DEFB $03,$7C            ; Scenery template 3: a doorway to room 124
  DEFB $0A,$00            ; Scenery template 10
  DEFB $09,$00            ; Scenery template 9
  DEFB $FF                ; End of the scenery
  DEFB $AF,$2A,$2C,$23,$25,$1A,$1C,$13 ; Object template 21 x8 at (2,5,0),
  DEFB $15                             ; (4,5,0), (3,4,0), (5,4,0), (2,3,0),
                                       ; (4,3,0), (3,2,0), (5,2,0)
  DEFB $A0,$5C            ; Object template 20 at (4,3,1)

; Room 126: 128 by 64, red; doorways to 127, 125
;
; 3 pieces of scenery and 12 objects in 2 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM126:
  DEFB $7E,$17,$12        ; Room 126; 23 bytes follow; ink 2, size 2
  DEFB $01,$7F            ; Scenery template 1: a doorway to room 127
  DEFB $03,$7D            ; Scenery template 3: a doorway to room 125
  DEFB $11,$00            ; Scenery template 17
  DEFB $FF                ; End of the scenery
  DEFB $2F,$2A,$2C,$23,$25,$1A,$1C,$13 ; Object template 5 x8 at (2,5,0),
  DEFB $15                             ; (4,5,0), (3,4,0), (5,4,0), (2,3,0),
                                       ; (4,3,0), (3,2,0), (5,2,0)
  DEFB $23,$21,$61,$1E,$5E ; Object template 4 x4 at (1,4,0), (1,4,1), (6,3,0),
                           ; (6,3,1)

; Room 127: 128 by 128, magenta; doorways to 130, 126
;
; 4 pieces of scenery and 0 objects in 0 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM127:
  DEFB $7F,$0A,$03        ; Room 127; 10 bytes follow; ink 3, size 0
  DEFB $00,$82            ; Scenery template 0: a doorway to room 130
  DEFB $03,$7E            ; Scenery template 3: a doorway to room 126
  DEFB $0A,$00            ; Scenery template 10
  DEFB $0B,$00            ; Scenery template 11

; Room 128: 128 by 128, green; doorways to 119
;
; 3 pieces of scenery and 0 objects in 0 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM128:
  DEFB $80,$08,$04        ; Room 128; 8 bytes follow; ink 4, size 0
  DEFB $02,$77            ; Scenery template 2: a doorway to room 119
  DEFB $08,$00            ; Scenery template 8
  DEFB $09,$00            ; Scenery template 9

; Room 129: 128 by 128, cyan; doorways to 131
;
; 3 pieces of scenery and 12 objects in 5 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM129:
  DEFB $81,$1A,$05        ; Room 129; 26 bytes follow; ink 5, size 0
  DEFB $00,$83            ; Scenery template 0: a doorway to room 131
  DEFB $08,$00            ; Scenery template 8
  DEFB $0B,$00            ; Scenery template 11
  DEFB $FF                ; End of the scenery
  DEFB $00,$87            ; Object template 0 at (7,0,2)
  DEFB $80,$83            ; Object template 16 at (3,0,2)
  DEFB $F0,$C7            ; Object template 30 at (7,0,3)
  DEFB $C8,$11            ; Object template 25 at (1,2,0)
  DEFB $AF,$06,$0F,$0D,$16,$04,$14,$1D ; Object template 21 x8 at (6,0,0),
  DEFB $03                             ; (7,1,0), (5,1,0), (6,2,0), (4,0,0),
                                       ; (4,2,0), (5,3,0), (3,0,0)

; Room 130: 64 by 128, yellow; doorways to 134, 127
;
; 3 pieces of scenery and 11 objects in 4 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM130:
  DEFB $82,$18,$0E        ; Room 130; 24 bytes follow; ink 6, size 1
  DEFB $00,$86            ; Scenery template 0: a doorway to room 134
  DEFB $02,$7F            ; Scenery template 2: a doorway to room 127
  DEFB $10,$00            ; Scenery template 16
  DEFB $FF                ; End of the scenery
  DEFB $0A,$5B,$5C,$5D    ; Object template 1 x3 at (3,3,1), (4,3,1), (5,3,1)
  DEFB $22,$1B,$1C,$1D    ; Object template 4 x3 at (3,3,0), (4,3,0), (5,3,0)
  DEFB $2B,$9A,$9B,$9C,$9D ; Object template 5 x4 at (2,3,2), (3,3,2), (4,3,2),
                           ; (5,3,2)
  DEFB $E8,$1A            ; Object template 29 at (2,3,0)

; Room 131: 128 by 128, white; doorways to 132, 129
;
; 4 pieces of scenery and 9 objects in 2 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM131:
  DEFB $83,$16,$07        ; Room 131; 22 bytes follow; ink 7, size 0
  DEFB $01,$84            ; Scenery template 1: a doorway to room 132
  DEFB $02,$81            ; Scenery template 2: a doorway to room 129
  DEFB $08,$00            ; Scenery template 8
  DEFB $09,$00            ; Scenery template 9
  DEFB $FF                ; End of the scenery
  DEFB $AF,$06,$0D,$16,$14,$1D,$1B,$24 ; Object template 21 x8 at (6,0,0),
  DEFB $2D                             ; (5,1,0), (6,2,0), (4,2,0), (5,3,0),
                                       ; (3,3,0), (4,4,0), (5,5,0)
  DEFB $A0,$11            ; Object template 20 at (1,2,0)

; Room 132: 128 by 64, red; doorways to 133, 131
;
; 3 pieces of scenery and 0 objects in 0 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM132:
  DEFB $84,$08,$12        ; Room 132; 8 bytes follow; ink 2, size 2
  DEFB $01,$85            ; Scenery template 1: a doorway to room 133
  DEFB $03,$83            ; Scenery template 3: a doorway to room 131
  DEFB $11,$00            ; Scenery template 17

; Room 133: 128 by 128, magenta; doorways to 134, 132
;
; 4 pieces of scenery and 9 objects in 2 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM133:
  DEFB $85,$16,$03        ; Room 133; 22 bytes follow; ink 3, size 0
  DEFB $01,$86            ; Scenery template 1: a doorway to room 134
  DEFB $03,$84            ; Scenery template 3: a doorway to room 132
  DEFB $0A,$00            ; Scenery template 10
  DEFB $09,$00            ; Scenery template 9
  DEFB $FF                ; End of the scenery
  DEFB $27,$2B,$2C,$25,$1D,$13,$14,$22 ; Object template 4 x8 at (3,5,0),
  DEFB $1A                             ; (4,5,0), (5,4,0), (5,3,0), (3,2,0),
                                       ; (4,2,0), (2,4,0), (2,3,0)
  DEFB $90,$24            ; Object template 18 at (4,4,0)

; Room 134: 128 by 128, green; doorways to 135, 130, 133
;
; 5 pieces of scenery and 2 objects in 2 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM134:
  DEFB $86,$11,$04        ; Room 134; 17 bytes follow; ink 4, size 0
  DEFB $04,$87            ; Scenery template 4: a doorway to room 135
  DEFB $02,$82            ; Scenery template 2: a doorway to room 130
  DEFB $03,$85            ; Scenery template 3: a doorway to room 133
  DEFB $0A,$00            ; Scenery template 10
  DEFB $0F,$00            ; Scenery template 15
  DEFB $FF                ; End of the scenery
  DEFB $68,$13            ; Object template 13 at (3,2,0)
  DEFB $A8,$25            ; Object template 21 at (5,4,0)

; Room 135: 128 by 128, cyan; doorways to 137, 136, 134
;
; 5 pieces of scenery and 0 objects in 0 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM135:
  DEFB $87,$0C,$05        ; Room 135; 12 bytes follow; ink 5, size 0
  DEFB $04,$89            ; Scenery template 4: a doorway to room 137
  DEFB $05,$88            ; Scenery template 5: a doorway to room 136
  DEFB $06,$86            ; Scenery template 6: a doorway to room 134
  DEFB $0C,$00            ; Scenery template 12
  DEFB $0F,$00            ; Scenery template 15

; Room 136: 128 by 128, yellow; doorways to 138, 135
;
; 4 pieces of scenery and 0 objects in 0 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM136:
  DEFB $88,$0A,$06        ; Room 136; 10 bytes follow; ink 6, size 0
  DEFB $04,$8A            ; Scenery template 4: a doorway to room 138
  DEFB $07,$87            ; Scenery template 7: a doorway to room 135
  DEFB $0E,$00            ; Scenery template 14
  DEFB $0F,$00            ; Scenery template 15

; Room 137: 128 by 128, white; doorways to 138, 135
;
; 4 pieces of scenery and 0 objects in 0 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM137:
  DEFB $89,$0A,$07        ; Room 137; 10 bytes follow; ink 7, size 0
  DEFB $05,$8A            ; Scenery template 5: a doorway to room 138
  DEFB $06,$87            ; Scenery template 6: a doorway to room 135
  DEFB $0C,$00            ; Scenery template 12
  DEFB $0D,$00            ; Scenery template 13

; Room 138: 128 by 128, red; doorways to 136, 137
;
; 4 pieces of scenery and 0 objects in 0 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM138:
  DEFB $8A,$0A,$02        ; Room 138; 10 bytes follow; ink 2, size 0
  DEFB $06,$88            ; Scenery template 6: a doorway to room 136
  DEFB $07,$89            ; Scenery template 7: a doorway to room 137
  DEFB $0E,$00            ; Scenery template 14
  DEFB $0D,$00            ; Scenery template 13

; Room 139: 128 by 128, magenta; doorways to 142, 140
;
; 4 pieces of scenery and 0 objects in 0 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM139:
  DEFB $8B,$0A,$03        ; Room 139; 10 bytes follow; ink 3, size 0
  DEFB $04,$8E            ; Scenery template 4: a doorway to room 142
  DEFB $05,$8C            ; Scenery template 5: a doorway to room 140
  DEFB $0C,$00            ; Scenery template 12
  DEFB $0F,$00            ; Scenery template 15

; Room 140: 128 by 128, green; doorways to 143, 41, 139
;
; 5 pieces of scenery and 0 objects in 0 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM140:
  DEFB $8C,$0C,$04        ; Room 140; 12 bytes follow; ink 4, size 0
  DEFB $04,$8F            ; Scenery template 4: a doorway to room 143
  DEFB $05,$29            ; Scenery template 5: a doorway to room 41
  DEFB $07,$8B            ; Scenery template 7: a doorway to room 139
  DEFB $0E,$00            ; Scenery template 14
  DEFB $0F,$00            ; Scenery template 15

; Room 141: 128 by 128, cyan; doorways to 144
;
; 3 pieces of scenery and 7 objects in 3 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM141:
  DEFB $8D,$13,$05        ; Room 141; 19 bytes follow; ink 5, size 0
  DEFB $04,$90            ; Scenery template 4: a doorway to room 144
  DEFB $0C,$00            ; Scenery template 12
  DEFB $0F,$00            ; Scenery template 15
  DEFB $FF                ; End of the scenery
  DEFB $C2,$14,$5C,$9B    ; Object template 24 x3 at (4,2,0), (4,3,1), (3,3,2)
  DEFB $00,$D3            ; Object template 0 at (3,2,3)
  DEFB $1A,$1C,$1B,$13    ; Object template 3 x3 at (4,3,0), (3,3,0), (3,2,0)

; Room 142: 128 by 128, yellow; doorways to 139
;
; 3 pieces of scenery and 12 objects in 4 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM142:
  DEFB $8E,$19,$06        ; Room 142; 25 bytes follow; ink 6, size 0
  DEFB $06,$8B            ; Scenery template 6: a doorway to room 139
  DEFB $0C,$00            ; Scenery template 12
  DEFB $0D,$00            ; Scenery template 13
  DEFB $FF                ; End of the scenery
  DEFB $04,$30,$70,$B0,$E8,$38 ; Object template 0 x5 at (0,6,0), (0,6,1),
                               ; (0,6,2), (0,5,3), (0,7,0)
  DEFB $C2,$39,$79,$B9    ; Object template 24 x3 at (1,7,0), (1,7,1), (1,7,2)
  DEFB $49,$F9,$F8        ; Object template 9 x2 at (1,7,3), (0,7,3)
  DEFB $91,$78,$B8        ; Object template 18 x2 at (0,7,1), (0,7,2)

; Room 143: 128 by 128, white; doorways to 144, 140, 55
;
; 5 pieces of scenery and 0 objects in 0 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM143:
  DEFB $8F,$0C,$07        ; Room 143; 12 bytes follow; ink 7, size 0
  DEFB $05,$90            ; Scenery template 5: a doorway to room 144
  DEFB $06,$8C            ; Scenery template 6: a doorway to room 140
  DEFB $07,$37            ; Scenery template 7: a doorway to room 55
  DEFB $0E,$00            ; Scenery template 14
  DEFB $0D,$00            ; Scenery template 13

; Room 144: 128 by 128, red; doorways to 141, 143
;
; 4 pieces of scenery and 0 objects in 0 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM144:
  DEFB $90,$0A,$02        ; Room 144; 10 bytes follow; ink 2, size 0
  DEFB $06,$8D            ; Scenery template 6: a doorway to room 141
  DEFB $07,$8F            ; Scenery template 7: a doorway to room 143
  DEFB $0E,$00            ; Scenery template 14
  DEFB $0D,$00            ; Scenery template 13

; Room 145: 128 by 128, magenta; doorways to 146, 86
;
; 4 pieces of scenery and 2 objects in 2 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM145:
  DEFB $91,$0F,$03        ; Room 145; 15 bytes follow; ink 3, size 0
  DEFB $05,$92            ; Scenery template 5: a doorway to room 146
  DEFB $07,$56            ; Scenery template 7: a doorway to room 86
  DEFB $0E,$00            ; Scenery template 14
  DEFB $0D,$00            ; Scenery template 13
  DEFB $FF                ; End of the scenery
  DEFB $90,$5B            ; Object template 18 at (3,3,1)
  DEFB $00,$1B            ; Object template 0 at (3,3,0)

; Room 146: 128 by 128, green; doorways to 145
;
; 3 pieces of scenery and 14 objects in 5 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM146:
  DEFB $92,$1C,$04        ; Room 146; 28 bytes follow; ink 4, size 0
  DEFB $07,$91            ; Scenery template 7: a doorway to room 145
  DEFB $0E,$00            ; Scenery template 14
  DEFB $0D,$00            ; Scenery template 13
  DEFB $FF                ; End of the scenery
  DEFB $C3,$19,$1B,$5B,$9B ; Object template 24 x4 at (1,3,0), (3,3,0),
                           ; (3,3,1), (3,3,2)
  DEFB $50,$9E            ; Object template 10 at (6,3,2)
  DEFB $03,$2E,$6E,$AE,$EE ; Object template 0 x4 at (6,5,0), (6,5,1), (6,5,2),
                           ; (6,5,3)
  DEFB $48,$DB            ; Object template 9 at (3,3,3)
  DEFB $1B,$1D,$26,$1F,$16 ; Object template 3 x4 at (5,3,0), (6,4,0), (7,3,0),
                           ; (6,2,0)

; Room 147: 128 by 128, cyan; doorways to 148, 0
;
; 5 pieces of scenery and 6 objects in 4 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM147:
  DEFB $93,$17,$05        ; Room 147; 23 bytes follow; ink 5, size 0
  DEFB $19,$94            ; Scenery template 25: a doorway to room 148
  DEFB $06,$00            ; Scenery template 6: a doorway to room 0
  DEFB $0C,$00            ; Scenery template 12
  DEFB $0D,$00            ; Scenery template 13
  DEFB $1D,$00            ; Scenery template 29
  DEFB $FF                ; End of the scenery
  DEFB $60,$2C            ; Object template 12 at (4,5,0)
  DEFB $01,$EF,$F7        ; Object template 0 x2 at (7,5,3), (7,6,3)
  DEFB $F0,$A4            ; Object template 30 at (4,4,2)
  DEFB $19,$37,$2F        ; Object template 3 x2 at (7,6,0), (7,5,0)

; Room 148: 128 by 128, yellow; doorways to 149, 147
;
; 4 pieces of scenery and 0 objects in 0 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM148:
  DEFB $94,$0A,$06        ; Room 148; 10 bytes follow; ink 6, size 0
  DEFB $05,$95            ; Scenery template 5: a doorway to room 149
  DEFB $07,$93            ; Scenery template 7: a doorway to room 147
  DEFB $0E,$00            ; Scenery template 14
  DEFB $0D,$00            ; Scenery template 13

; Room 149: 128 by 128, white; doorways to 2, 148
;
; 5 pieces of scenery and 12 objects in 4 groups. Positions are cells (U, V,
; level): U and V 0-7, sixteen units a cell from 72; each level twelve units up
; from the floor.
ROOM149:
  DEFB $95,$1D,$07        ; Room 149; 29 bytes follow; ink 7, size 0
  DEFB $06,$02            ; Scenery template 6: a doorway to room 2
  DEFB $1B,$94            ; Scenery template 27: a doorway to room 148
  DEFB $0C,$00            ; Scenery template 12
  DEFB $0D,$00            ; Scenery template 13
  DEFB $1F,$00            ; Scenery template 31
  DEFB $FF                ; End of the scenery
  DEFB $1E,$3A,$39,$31,$30,$28,$08,$10 ; Object template 3 x7 at (2,7,0),
                                       ; (1,7,0), (1,6,0), (0,6,0), (0,5,0),
                                       ; (0,1,0), (0,2,0)
  DEFB $C2,$C8,$D0,$E8    ; Object template 24 x3 at (0,1,3), (0,2,3), (0,5,3)
  DEFB $60,$3B            ; Object template 12 at (3,7,0)
  DEFB $50,$F8            ; Object template 10 at (0,7,3)

; Scenery template table
;
; A word per scenery template, the entry's first byte doubled as the index
; (BUILD_ROOM). Four point back at the table itself, and no room uses them.
SCENERY_TABLE:
  DEFW SCENERY0           ; Template 0
  DEFW SCENERY1           ; Template 1
  DEFW SCENERY2           ; Template 2
  DEFW SCENERY3           ; Template 3
  DEFW SCENERY4           ; Template 4
  DEFW SCENERY5           ; Template 5
  DEFW SCENERY6           ; Template 6
  DEFW SCENERY7           ; Template 7
  DEFW SCENERY8           ; Template 8
  DEFW SCENERY9           ; Template 9
  DEFW SCENERY10          ; Template 10
  DEFW SCENERY11          ; Template 11
  DEFW SCENERY12          ; Template 12
  DEFW SCENERY13          ; Template 13
  DEFW SCENERY14          ; Template 14
  DEFW SCENERY15          ; Template 15
  DEFW SCENERY16          ; Template 16
  DEFW SCENERY17          ; Template 17
  DEFW SCENERY_TABLE      ; Template 18 (the table itself: not a template)
  DEFW SCENERY_TABLE      ; Template 19 (the table itself: not a template)
  DEFW SCENERY20          ; Template 20
  DEFW SCENERY21          ; Template 21
  DEFW SCENERY_TABLE      ; Template 22 (the table itself: not a template)
  DEFW SCENERY_TABLE      ; Template 23 (the table itself: not a template)
  DEFW SCENERY24          ; Template 24
  DEFW SCENERY25          ; Template 25
  DEFW SCENERY26          ; Template 26
  DEFW SCENERY27          ; Template 27
  DEFW SCENERY28          ; Template 28
  DEFW SCENERY29          ; Template 29
  DEFW SCENERY30          ; Template 30
  DEFW SCENERY31          ; Template 31

; Scenery template 0
;
; 2 pieces.
SCENERY0:
  DEFB $07,$73,$C5,$80,$03,$05,$28,$50 ; Graphic 7 at U 115, V 197, Z 128;
                                       ; half-sizes 3, 5, height 40; flags $50
  DEFB $06,$8D,$C5,$80,$03,$05,$28,$50 ; Graphic 6 at U 141, V 197, Z 128;
                                       ; half-sizes 3, 5, height 40; flags $50
  DEFB $00                ; End of the template

; Scenery template 1
;
; 2 pieces.
SCENERY1:
  DEFB $07,$C5,$8D,$80,$05,$03,$28,$10 ; Graphic 7 at U 197, V 141, Z 128;
                                       ; half-sizes 5, 3, height 40; flags $10
  DEFB $06,$C5,$73,$80,$05,$03,$28,$10 ; Graphic 6 at U 197, V 115, Z 128;
                                       ; half-sizes 5, 3, height 40; flags $10
  DEFB $00                ; End of the template

; Scenery template 2
;
; 2 pieces.
SCENERY2:
  DEFB $07,$73,$3B,$80,$03,$05,$28,$50 ; Graphic 7 at U 115, V 59, Z 128;
                                       ; half-sizes 3, 5, height 40; flags $50
  DEFB $06,$8D,$3B,$80,$03,$05,$28,$50 ; Graphic 6 at U 141, V 59, Z 128;
                                       ; half-sizes 3, 5, height 40; flags $50
  DEFB $00                ; End of the template

; Scenery template 3
;
; 2 pieces.
SCENERY3:
  DEFB $07,$3B,$8D,$80,$05,$03,$28,$10 ; Graphic 7 at U 59, V 141, Z 128;
                                       ; half-sizes 5, 3, height 40; flags $10
  DEFB $06,$3B,$73,$80,$05,$03,$28,$10 ; Graphic 6 at U 59, V 115, Z 128;
                                       ; half-sizes 5, 3, height 40; flags $10
  DEFB $00                ; End of the template

; Scenery template 4
;
; 2 pieces.
SCENERY4:
  DEFB $09,$73,$C5,$80,$03,$05,$28,$50 ; Graphic 9 at U 115, V 197, Z 128;
                                       ; half-sizes 3, 5, height 40; flags $50
  DEFB $08,$8D,$C5,$80,$03,$05,$28,$50 ; Graphic 8 at U 141, V 197, Z 128;
                                       ; half-sizes 3, 5, height 40; flags $50
  DEFB $00                ; End of the template

; Scenery template 5
;
; 2 pieces.
SCENERY5:
  DEFB $09,$C5,$8D,$80,$05,$03,$28,$10 ; Graphic 9 at U 197, V 141, Z 128;
                                       ; half-sizes 5, 3, height 40; flags $10
  DEFB $08,$C5,$73,$80,$05,$03,$28,$10 ; Graphic 8 at U 197, V 115, Z 128;
                                       ; half-sizes 5, 3, height 40; flags $10
  DEFB $00                ; End of the template

; Scenery template 6
;
; 2 pieces.
SCENERY6:
  DEFB $09,$73,$3B,$80,$03,$05,$28,$50 ; Graphic 9 at U 115, V 59, Z 128;
                                       ; half-sizes 3, 5, height 40; flags $50
  DEFB $08,$8D,$3B,$80,$03,$05,$28,$50 ; Graphic 8 at U 141, V 59, Z 128;
                                       ; half-sizes 3, 5, height 40; flags $50
  DEFB $00                ; End of the template

; Scenery template 7
;
; 2 pieces.
SCENERY7:
  DEFB $09,$3B,$8D,$80,$05,$03,$28,$10 ; Graphic 9 at U 59, V 141, Z 128;
                                       ; half-sizes 5, 3, height 40; flags $10
  DEFB $08,$3B,$73,$80,$05,$03,$28,$10 ; Graphic 8 at U 59, V 115, Z 128;
                                       ; half-sizes 5, 3, height 40; flags $10
  DEFB $00                ; End of the template

; Scenery template 24
;
; 2 pieces.
SCENERY24:
  DEFB $09,$93,$C5,$B0,$03,$05,$28,$50 ; Graphic 9 at U 147, V 197, Z 176;
                                       ; half-sizes 3, 5, height 40; flags $50
  DEFB $08,$AD,$C5,$B0,$03,$05,$28,$50 ; Graphic 8 at U 173, V 197, Z 176;
                                       ; half-sizes 3, 5, height 40; flags $50
  DEFB $00                ; End of the template

; Scenery template 25
;
; 2 pieces.
SCENERY25:
  DEFB $09,$C5,$AD,$B0,$05,$03,$28,$10 ; Graphic 9 at U 197, V 173, Z 176;
                                       ; half-sizes 5, 3, height 40; flags $10
  DEFB $08,$C5,$93,$B0,$05,$03,$28,$10 ; Graphic 8 at U 197, V 147, Z 176;
                                       ; half-sizes 5, 3, height 40; flags $10
  DEFB $00                ; End of the template

; Scenery template 26
;
; 2 pieces.
SCENERY26:
  DEFB $09,$53,$3B,$B0,$03,$05,$28,$50 ; Graphic 9 at U 83, V 59, Z 176;
                                       ; half-sizes 3, 5, height 40; flags $50
  DEFB $08,$6D,$3B,$B0,$03,$05,$28,$50 ; Graphic 8 at U 109, V 59, Z 176;
                                       ; half-sizes 3, 5, height 40; flags $50
  DEFB $00                ; End of the template

; Scenery template 27
;
; 2 pieces.
SCENERY27:
  DEFB $09,$3B,$6D,$B0,$05,$03,$28,$10 ; Graphic 9 at U 59, V 109, Z 176;
                                       ; half-sizes 5, 3, height 40; flags $10
  DEFB $08,$3B,$53,$B0,$05,$03,$28,$10 ; Graphic 8 at U 59, V 83, Z 176;
                                       ; half-sizes 5, 3, height 40; flags $10
  DEFB $00                ; End of the template

; Scenery template 28
;
; 2 pieces.
SCENERY28:
  DEFB $0B,$98,$C8,$A4,$08,$08,$0C,$10 ; Graphic 11 at U 152, V 200, Z 164;
                                       ; half-sizes 8, 8, height 12; flags $10
  DEFB $0B,$A8,$C8,$A4,$08,$08,$0C,$10 ; Graphic 11 at U 168, V 200, Z 164;
                                       ; half-sizes 8, 8, height 12; flags $10
  DEFB $00                ; End of the template

; Scenery template 29
;
; 2 pieces.
SCENERY29:
  DEFB $0B,$C8,$98,$A4,$08,$08,$0C,$10 ; Graphic 11 at U 200, V 152, Z 164;
                                       ; half-sizes 8, 8, height 12; flags $10
  DEFB $0B,$C8,$A8,$A4,$08,$08,$0C,$10 ; Graphic 11 at U 200, V 168, Z 164;
                                       ; half-sizes 8, 8, height 12; flags $10
  DEFB $00                ; End of the template

; Scenery template 30
;
; 2 pieces.
SCENERY30:
  DEFB $0B,$58,$39,$A4,$08,$08,$0C,$10 ; Graphic 11 at U 88, V 57, Z 164;
                                       ; half-sizes 8, 8, height 12; flags $10
  DEFB $0B,$68,$39,$A4,$08,$08,$0C,$10 ; Graphic 11 at U 104, V 57, Z 164;
                                       ; half-sizes 8, 8, height 12; flags $10
  DEFB $00                ; End of the template

; Scenery template 31
;
; 2 pieces.
SCENERY31:
  DEFB $0B,$38,$58,$A4,$08,$08,$0C,$10 ; Graphic 11 at U 56, V 88, Z 164;
                                       ; half-sizes 8, 8, height 12; flags $10
  DEFB $0B,$38,$68,$A4,$08,$08,$0C,$10 ; Graphic 11 at U 56, V 104, Z 164;
                                       ; half-sizes 8, 8, height 12; flags $10
  DEFB $00                ; End of the template

; Scenery template 8
;
; 2 pieces, and no zero after the last: BUILD_ROOM's piece loop reads on into
; the next template's.
SCENERY8:
  DEFB $0F,$40,$78,$80,$00,$08,$18,$50 ; Graphic 15 at U 64, V 120, Z 128;
                                       ; half-sizes 0, 8, height 24; flags $50
  DEFB $0C,$40,$88,$80,$00,$08,$18,$50 ; Graphic 12 at U 64, V 136, Z 128;
                                       ; half-sizes 0, 8, height 24; flags $50

; Scenery template 10
;
; 6 pieces.
SCENERY10:
  DEFB $0C,$40,$48,$80,$00,$08,$18,$50 ; Graphic 12 at U 64, V 72, Z 128;
                                       ; half-sizes 0, 8, height 24; flags $50
  DEFB $0D,$40,$58,$80,$00,$08,$18,$50 ; Graphic 13 at U 64, V 88, Z 128;
                                       ; half-sizes 0, 8, height 24; flags $50
  DEFB $0E,$40,$68,$80,$00,$08,$18,$50 ; Graphic 14 at U 64, V 104, Z 128;
                                       ; half-sizes 0, 8, height 24; flags $50
  DEFB $0D,$40,$98,$80,$00,$08,$18,$50 ; Graphic 13 at U 64, V 152, Z 128;
                                       ; half-sizes 0, 8, height 24; flags $50
  DEFB $0E,$40,$A8,$80,$00,$08,$18,$50 ; Graphic 14 at U 64, V 168, Z 128;
                                       ; half-sizes 0, 8, height 24; flags $50
  DEFB $0F,$40,$B8,$80,$00,$08,$18,$50 ; Graphic 15 at U 64, V 184, Z 128;
                                       ; half-sizes 0, 8, height 24; flags $50
  DEFB $00                ; End of the template

; Scenery template 9
;
; 2 pieces, and no zero after the last: BUILD_ROOM's piece loop reads on into
; the next template's.
SCENERY9:
  DEFB $0F,$78,$C0,$80,$08,$00,$18,$10 ; Graphic 15 at U 120, V 192, Z 128;
                                       ; half-sizes 8, 0, height 24; flags $10
  DEFB $0C,$88,$C0,$80,$08,$00,$18,$10 ; Graphic 12 at U 136, V 192, Z 128;
                                       ; half-sizes 8, 0, height 24; flags $10

; Scenery template 11
;
; 6 pieces.
SCENERY11:
  DEFB $0C,$48,$C0,$80,$08,$00,$18,$10 ; Graphic 12 at U 72, V 192, Z 128;
                                       ; half-sizes 8, 0, height 24; flags $10
  DEFB $0D,$58,$C0,$80,$08,$00,$18,$10 ; Graphic 13 at U 88, V 192, Z 128;
                                       ; half-sizes 8, 0, height 24; flags $10
  DEFB $0E,$68,$C0,$80,$08,$00,$18,$10 ; Graphic 14 at U 104, V 192, Z 128;
                                       ; half-sizes 8, 0, height 24; flags $10
  DEFB $0D,$98,$C0,$80,$08,$00,$18,$10 ; Graphic 13 at U 152, V 192, Z 128;
                                       ; half-sizes 8, 0, height 24; flags $10
  DEFB $0E,$A8,$C0,$80,$08,$00,$18,$10 ; Graphic 14 at U 168, V 192, Z 128;
                                       ; half-sizes 8, 0, height 24; flags $10
  DEFB $0F,$B8,$C0,$80,$08,$00,$18,$10 ; Graphic 15 at U 184, V 192, Z 128;
                                       ; half-sizes 8, 0, height 24; flags $10
  DEFB $00                ; End of the template

; Scenery template 16
;
; 9 pieces.
SCENERY16:
  DEFB $0F,$60,$78,$80,$00,$08,$18,$50 ; Graphic 15 at U 96, V 120, Z 128;
                                       ; half-sizes 0, 8, height 24; flags $50
  DEFB $0C,$60,$88,$80,$00,$08,$18,$50 ; Graphic 12 at U 96, V 136, Z 128;
                                       ; half-sizes 0, 8, height 24; flags $50
  DEFB $0C,$60,$48,$80,$00,$08,$18,$50 ; Graphic 12 at U 96, V 72, Z 128;
                                       ; half-sizes 0, 8, height 24; flags $50
  DEFB $0D,$60,$58,$80,$00,$08,$18,$50 ; Graphic 13 at U 96, V 88, Z 128;
                                       ; half-sizes 0, 8, height 24; flags $50
  DEFB $0E,$60,$68,$80,$00,$08,$18,$50 ; Graphic 14 at U 96, V 104, Z 128;
                                       ; half-sizes 0, 8, height 24; flags $50
  DEFB $0D,$60,$98,$80,$00,$08,$18,$50 ; Graphic 13 at U 96, V 152, Z 128;
                                       ; half-sizes 0, 8, height 24; flags $50
  DEFB $0E,$60,$A8,$80,$00,$08,$18,$50 ; Graphic 14 at U 96, V 168, Z 128;
                                       ; half-sizes 0, 8, height 24; flags $50
  DEFB $0F,$60,$B8,$80,$00,$08,$18,$50 ; Graphic 15 at U 96, V 184, Z 128;
                                       ; half-sizes 0, 8, height 24; flags $50
  DEFB $0E,$68,$C0,$80,$08,$00,$18,$10 ; Graphic 14 at U 104, V 192, Z 128;
                                       ; half-sizes 8, 0, height 24; flags $10
  DEFB $00                ; End of the template

; Scenery template 17
;
; 9 pieces.
SCENERY17:
  DEFB $0F,$78,$A0,$80,$08,$00,$18,$10 ; Graphic 15 at U 120, V 160, Z 128;
                                       ; half-sizes 8, 0, height 24; flags $10
  DEFB $0C,$88,$A0,$80,$08,$00,$18,$10 ; Graphic 12 at U 136, V 160, Z 128;
                                       ; half-sizes 8, 0, height 24; flags $10
  DEFB $0C,$48,$A0,$80,$08,$00,$18,$10 ; Graphic 12 at U 72, V 160, Z 128;
                                       ; half-sizes 8, 0, height 24; flags $10
  DEFB $0D,$58,$A0,$80,$08,$00,$18,$10 ; Graphic 13 at U 88, V 160, Z 128;
                                       ; half-sizes 8, 0, height 24; flags $10
  DEFB $0E,$68,$A0,$80,$08,$00,$18,$10 ; Graphic 14 at U 104, V 160, Z 128;
                                       ; half-sizes 8, 0, height 24; flags $10
  DEFB $0D,$98,$A0,$80,$08,$00,$18,$10 ; Graphic 13 at U 152, V 160, Z 128;
                                       ; half-sizes 8, 0, height 24; flags $10
  DEFB $0E,$A8,$A0,$80,$08,$00,$18,$10 ; Graphic 14 at U 168, V 160, Z 128;
                                       ; half-sizes 8, 0, height 24; flags $10
  DEFB $0F,$B8,$A0,$80,$08,$00,$18,$10 ; Graphic 15 at U 184, V 160, Z 128;
                                       ; half-sizes 8, 0, height 24; flags $10
  DEFB $0D,$40,$98,$80,$00,$08,$18,$50 ; Graphic 13 at U 64, V 152, Z 128;
                                       ; half-sizes 0, 8, height 24; flags $50
  DEFB $00                ; End of the template

; Scenery template 12
;
; 2 pieces, and no zero after the last: BUILD_ROOM's piece loop reads on into
; the next template's.
SCENERY12:
  DEFB $34,$40,$78,$80,$00,$08,$18,$10 ; Graphic 52 at U 64, V 120, Z 128;
                                       ; half-sizes 0, 8, height 24; flags $10
  DEFB $35,$40,$88,$80,$00,$08,$18,$10 ; Graphic 53 at U 64, V 136, Z 128;
                                       ; half-sizes 0, 8, height 24; flags $10

; Scenery template 14
;
; 6 pieces.
SCENERY14:
  DEFB $39,$40,$48,$80,$00,$08,$18,$10 ; Graphic 57 at U 64, V 72, Z 128;
                                       ; half-sizes 0, 8, height 24; flags $10
  DEFB $37,$40,$58,$80,$00,$08,$18,$10 ; Graphic 55 at U 64, V 88, Z 128;
                                       ; half-sizes 0, 8, height 24; flags $10
  DEFB $38,$40,$68,$80,$00,$08,$18,$10 ; Graphic 56 at U 64, V 104, Z 128;
                                       ; half-sizes 0, 8, height 24; flags $10
  DEFB $37,$40,$98,$80,$00,$08,$18,$10 ; Graphic 55 at U 64, V 152, Z 128;
                                       ; half-sizes 0, 8, height 24; flags $10
  DEFB $36,$40,$A8,$80,$00,$08,$18,$10 ; Graphic 54 at U 64, V 168, Z 128;
                                       ; half-sizes 0, 8, height 24; flags $10
  DEFB $35,$40,$B8,$80,$00,$08,$18,$10 ; Graphic 53 at U 64, V 184, Z 128;
                                       ; half-sizes 0, 8, height 24; flags $10
  DEFB $00                ; End of the template

; Scenery template 13
;
; 2 pieces, and no zero after the last: BUILD_ROOM's piece loop reads on into
; the next template's.
SCENERY13:
  DEFB $37,$78,$C0,$80,$08,$00,$18,$50 ; Graphic 55 at U 120, V 192, Z 128;
                                       ; half-sizes 8, 0, height 24; flags $50
  DEFB $38,$88,$C0,$80,$08,$00,$18,$50 ; Graphic 56 at U 136, V 192, Z 128;
                                       ; half-sizes 8, 0, height 24; flags $50

; Scenery template 15
;
; 6 pieces.
SCENERY15:
  DEFB $36,$48,$C0,$80,$08,$00,$18,$50 ; Graphic 54 at U 72, V 192, Z 128;
                                       ; half-sizes 8, 0, height 24; flags $50
  DEFB $35,$58,$C0,$80,$08,$00,$18,$50 ; Graphic 53 at U 88, V 192, Z 128;
                                       ; half-sizes 8, 0, height 24; flags $50
  DEFB $34,$68,$C0,$80,$08,$00,$18,$50 ; Graphic 52 at U 104, V 192, Z 128;
                                       ; half-sizes 8, 0, height 24; flags $50
  DEFB $36,$98,$C0,$80,$08,$00,$18,$50 ; Graphic 54 at U 152, V 192, Z 128;
                                       ; half-sizes 8, 0, height 24; flags $50
  DEFB $37,$A8,$C0,$80,$08,$00,$18,$50 ; Graphic 55 at U 168, V 192, Z 128;
                                       ; half-sizes 8, 0, height 24; flags $50
  DEFB $39,$B8,$C0,$80,$08,$00,$18,$50 ; Graphic 57 at U 184, V 192, Z 128;
                                       ; half-sizes 8, 0, height 24; flags $50
  DEFB $00                ; End of the template

; Scenery template 20
;
; 9 pieces.
SCENERY20:
  DEFB $34,$60,$78,$80,$00,$08,$18,$10 ; Graphic 52 at U 96, V 120, Z 128;
                                       ; half-sizes 0, 8, height 24; flags $10
  DEFB $35,$60,$88,$80,$00,$08,$18,$10 ; Graphic 53 at U 96, V 136, Z 128;
                                       ; half-sizes 0, 8, height 24; flags $10
  DEFB $39,$60,$48,$80,$00,$08,$18,$10 ; Graphic 57 at U 96, V 72, Z 128;
                                       ; half-sizes 0, 8, height 24; flags $10
  DEFB $37,$60,$58,$80,$00,$08,$18,$10 ; Graphic 55 at U 96, V 88, Z 128;
                                       ; half-sizes 0, 8, height 24; flags $10
  DEFB $36,$60,$68,$80,$00,$08,$18,$10 ; Graphic 54 at U 96, V 104, Z 128;
                                       ; half-sizes 0, 8, height 24; flags $10
  DEFB $37,$60,$98,$80,$00,$08,$18,$10 ; Graphic 55 at U 96, V 152, Z 128;
                                       ; half-sizes 0, 8, height 24; flags $10
  DEFB $35,$60,$A8,$80,$00,$08,$18,$10 ; Graphic 53 at U 96, V 168, Z 128;
                                       ; half-sizes 0, 8, height 24; flags $10
  DEFB $34,$60,$B8,$80,$00,$08,$18,$10 ; Graphic 52 at U 96, V 184, Z 128;
                                       ; half-sizes 0, 8, height 24; flags $10
  DEFB $36,$68,$C0,$80,$08,$00,$18,$50 ; Graphic 54 at U 104, V 192, Z 128;
                                       ; half-sizes 8, 0, height 24; flags $50
  DEFB $00                ; End of the template

; Scenery template 21
;
; 9 pieces.
SCENERY21:
  DEFB $34,$78,$A0,$80,$08,$00,$18,$50 ; Graphic 52 at U 120, V 160, Z 128;
                                       ; half-sizes 8, 0, height 24; flags $50
  DEFB $37,$88,$A0,$80,$08,$00,$18,$50 ; Graphic 55 at U 136, V 160, Z 128;
                                       ; half-sizes 8, 0, height 24; flags $50
  DEFB $36,$48,$A0,$80,$08,$00,$18,$50 ; Graphic 54 at U 72, V 160, Z 128;
                                       ; half-sizes 8, 0, height 24; flags $50
  DEFB $35,$58,$A0,$80,$08,$00,$18,$50 ; Graphic 53 at U 88, V 160, Z 128;
                                       ; half-sizes 8, 0, height 24; flags $50
  DEFB $36,$68,$A0,$80,$08,$00,$18,$50 ; Graphic 54 at U 104, V 160, Z 128;
                                       ; half-sizes 8, 0, height 24; flags $50
  DEFB $37,$98,$A0,$80,$08,$00,$18,$50 ; Graphic 55 at U 152, V 160, Z 128;
                                       ; half-sizes 8, 0, height 24; flags $50
  DEFB $35,$A8,$A0,$80,$08,$00,$18,$50 ; Graphic 53 at U 168, V 160, Z 128;
                                       ; half-sizes 8, 0, height 24; flags $50
  DEFB $39,$B8,$A0,$80,$08,$00,$18,$50 ; Graphic 57 at U 184, V 160, Z 128;
                                       ; half-sizes 8, 0, height 24; flags $50
  DEFB $36,$40,$98,$80,$00,$08,$18,$10 ; Graphic 54 at U 64, V 152, Z 128;
                                       ; half-sizes 0, 8, height 24; flags $10
  DEFB $00                ; End of the template

; Object template table
;
; A word per object template, the group header's bits 3-7 as the index
; (BUILD_ROOM). The builder keeps the table's address in TEMPLATES_AT: a
; template number of 31 moves it on by 64 bytes, to a second page of templates,
; though no room uses that.
OBJECT_TABLE:
  DEFW OBJECT0            ; Template 0
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
  DEFW OBJECT9            ; Template 22
  DEFW OBJECT23           ; Template 23
  DEFW OBJECT24           ; Template 24
  DEFW OBJECT25           ; Template 25
  DEFW OBJECT26           ; Template 26
  DEFW OBJECT27           ; Template 27
  DEFW OBJECT28           ; Template 28
  DEFW OBJECT29           ; Template 29
  DEFW OBJECT30           ; Template 30

; Object templates 9, 22: graphic 91
OBJECT9:
  DEFB $5B,$08,$08,$0C,$10 ; Graphic 91; half-sizes 8, 8, height 12; flags $10
  DEFB $00                ; End of the template

; Object template 0: graphic 11
OBJECT0:
  DEFB $0B,$08,$08,$0C,$10 ; Graphic 11; half-sizes 8, 8, height 12; flags $10
  DEFB $00                ; End of the template

; Object template 13: graphic 74
OBJECT13:
  DEFB $4A,$0C,$0C,$01,$10 ; Graphic 74; half-sizes 12, 12, height 1; flags $10
  DEFB $00                ; End of the template

; Object template 21: graphic 75
OBJECT21:
  DEFB $4B,$0C,$0C,$01,$10 ; Graphic 75; half-sizes 12, 12, height 1; flags $10
  DEFB $00                ; End of the template

; Object template 1: graphic 10
OBJECT1:
  DEFB $0A,$08,$08,$0C,$10 ; Graphic 10; half-sizes 8, 8, height 12; flags $10
  DEFB $00                ; End of the template

; Object template 2: graphic 48
OBJECT2:
  DEFB $30,$05,$05,$05,$10 ; Graphic 48; half-sizes 5, 5, height 5; flags $10
  DEFB $00                ; End of the template

; Object template 3: graphic 23
OBJECT3:
  DEFB $17,$07,$07,$0A,$10 ; Graphic 23; half-sizes 7, 7, height 10; flags $10
  DEFB $00                ; End of the template

; Object template 4: graphic 72
OBJECT4:
  DEFB $48,$08,$08,$0C,$14 ; Graphic 72; half-sizes 8, 8, height 12; flags $14
  DEFB $00                ; End of the template

; Object template 5: graphic 30
OBJECT5:
  DEFB $1E,$07,$07,$0A,$10 ; Graphic 30; half-sizes 7, 7, height 10; flags $10
  DEFB $00                ; End of the template

; Object template 6: graphic 63
OBJECT6:
  DEFB $3F,$08,$08,$0C,$14 ; Graphic 63; half-sizes 8, 8, height 12; flags $14
  DEFB $00                ; End of the template

; Object template 7: graphic 73
OBJECT7:
  DEFB $49,$08,$0E,$0C,$14 ; Graphic 73; half-sizes 8, 14, height 12; flags $14
  DEFB $00                ; End of the template

; Object template 8: graphic 76
OBJECT8:
  DEFB $4C,$08,$08,$0C,$10 ; Graphic 76; half-sizes 8, 8, height 12; flags $10
  DEFB $00                ; End of the template

; Object template 10: graphic 78
OBJECT10:
  DEFB $4E,$08,$08,$0C,$10 ; Graphic 78; half-sizes 8, 8, height 12; flags $10
  DEFB $00                ; End of the template

; Object template 11: graphic 79
OBJECT11:
  DEFB $4F,$08,$08,$0C,$14 ; Graphic 79; half-sizes 8, 8, height 12; flags $14
  DEFB $00                ; End of the template

; Object template 12: graphic 84
OBJECT12:
  DEFB $54,$08,$08,$0C,$10 ; Graphic 84; half-sizes 8, 8, height 12; flags $10
  DEFB $00                ; End of the template

; Object template 14: graphic 28
OBJECT14:
  DEFB $1C,$07,$07,$0B,$14 ; Graphic 28; half-sizes 7, 7, height 11; flags $14
  DEFB $00                ; End of the template

; Object template 15: graphic 86
OBJECT15:
  DEFB $56,$08,$08,$0C,$10 ; Graphic 86; half-sizes 8, 8, height 12; flags $10
  DEFB $00                ; End of the template

; Object template 16: graphic 87
OBJECT16:
  DEFB $57,$08,$08,$0C,$10 ; Graphic 87; half-sizes 8, 8, height 12; flags $10
  DEFB $00                ; End of the template

; Object template 17: graphic 88
OBJECT17:
  DEFB $58,$08,$08,$0C,$10 ; Graphic 88; half-sizes 8, 8, height 12; flags $10
  DEFB $00                ; End of the template

; Object template 18: graphic 89
OBJECT18:
  DEFB $59,$08,$08,$0A,$10 ; Graphic 89; half-sizes 8, 8, height 10; flags $10
  DEFB $00                ; End of the template

; Object template 29: graphic 92
OBJECT29:
  DEFB $5C,$08,$08,$0C,$10 ; Graphic 92; half-sizes 8, 8, height 12; flags $10
  DEFB $00                ; End of the template

; Object template 30: graphic 93
OBJECT30:
  DEFB $5D,$08,$08,$0C,$50 ; Graphic 93; half-sizes 8, 8, height 12; flags $50
  DEFB $00                ; End of the template

; Object template 19: graphic 120
OBJECT19:
  DEFB $78,$0A,$0A,$0C,$10 ; Graphic 120; half-sizes 10, 10, height 12; flags
                           ; $10
  DEFB $00                ; End of the template

; Object template 20: graphic 16
OBJECT20:
  DEFB $10,$08,$08,$0A,$10 ; Graphic 16; half-sizes 8, 8, height 10; flags $10
  DEFB $00                ; End of the template

; Object template 23: graphic 82
OBJECT23:
  DEFB $52,$08,$08,$0C,$10 ; Graphic 82; half-sizes 8, 8, height 12; flags $10
  DEFB $00                ; End of the template

; Object template 24: graphic 136
OBJECT24:
  DEFB $88,$08,$08,$0C,$10 ; Graphic 136; half-sizes 8, 8, height 12; flags $10
  DEFB $00                ; End of the template

; Object template 25: graphic 140
OBJECT25:
  DEFB $8C,$08,$08,$0C,$10 ; Graphic 140; half-sizes 8, 8, height 12; flags $10
  DEFB $00                ; End of the template

; Object template 26: graphic 141
OBJECT26:
  DEFB $8D,$08,$08,$0C,$10 ; Graphic 141; half-sizes 8, 8, height 12; flags $10
  DEFB $00                ; End of the template

; Object template 27: graphic 142
OBJECT27:
  DEFB $8E,$08,$08,$0C,$10 ; Graphic 142; half-sizes 8, 8, height 12; flags $10
  DEFB $00                ; End of the template

; Object template 28: graphic 143
OBJECT28:
  DEFB $8F,$08,$08,$0C,$10 ; Graphic 143; half-sizes 8, 8, height 12; flags $10
  DEFB $00                ; End of the template

; Graphic table
;
; A word per graphic number, the address of its sprite: FIND_SPRITE looks up
; the graphic in +0 of an object's record here. Many numbers share a sprite,
; and a sprite whose width and height are both zero (SPRITE0) draws nothing.
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
  DEFW SPRITE16           ; Graphic 17
  DEFW SPRITE18           ; Graphic 18
  DEFW SPRITE19           ; Graphic 19
  DEFW SPRITE18           ; Graphic 20
  DEFW SPRITE21           ; Graphic 21
  DEFW SPRITE22           ; Graphic 22
  DEFW SPRITE23           ; Graphic 23
  DEFW SPRITE0            ; Graphic 24
  DEFW SPRITE0            ; Graphic 25
  DEFW SPRITE0            ; Graphic 26
  DEFW SPRITE0            ; Graphic 27
  DEFW SPRITE23           ; Graphic 28
  DEFW SPRITE21           ; Graphic 29
  DEFW SPRITE30           ; Graphic 30
  DEFW SPRITE30           ; Graphic 31
  DEFW SPRITE18           ; Graphic 32
  DEFW SPRITE21           ; Graphic 33
  DEFW SPRITE34           ; Graphic 34
  DEFW SPRITE21           ; Graphic 35
  DEFW SPRITE36           ; Graphic 36
  DEFW SPRITE19           ; Graphic 37
  DEFW SPRITE38           ; Graphic 38
  DEFW SPRITE19           ; Graphic 39
  DEFW SPRITE40           ; Graphic 40
  DEFW SPRITE41           ; Graphic 41
  DEFW SPRITE42           ; Graphic 42
  DEFW SPRITE41           ; Graphic 43
  DEFW SPRITE44           ; Graphic 44
  DEFW SPRITE45           ; Graphic 45
  DEFW SPRITE46           ; Graphic 46
  DEFW SPRITE45           ; Graphic 47
  DEFW SPRITE48           ; Graphic 48
  DEFW SPRITE49           ; Graphic 49
  DEFW SPRITE48           ; Graphic 50
  DEFW SPRITE49           ; Graphic 51
  DEFW SPRITE52           ; Graphic 52
  DEFW SPRITE53           ; Graphic 53
  DEFW SPRITE54           ; Graphic 54
  DEFW SPRITE55           ; Graphic 55
  DEFW SPRITE56           ; Graphic 56
  DEFW SPRITE57           ; Graphic 57
  DEFW SPRITE58           ; Graphic 58
  DEFW SPRITE59           ; Graphic 59
  DEFW SPRITE60           ; Graphic 60
  DEFW SPRITE60           ; Graphic 61
  DEFW SPRITE62           ; Graphic 62
  DEFW SPRITE63           ; Graphic 63
  DEFW SPRITE64           ; Graphic 64
  DEFW SPRITE65           ; Graphic 65
  DEFW SPRITE66           ; Graphic 66
  DEFW SPRITE65           ; Graphic 67
  DEFW SPRITE66           ; Graphic 68
  DEFW SPRITE66           ; Graphic 69
  DEFW SPRITE70           ; Graphic 70
  DEFW SPRITE70           ; Graphic 71
  DEFW SPRITE10           ; Graphic 72
  DEFW SPRITE73           ; Graphic 73
  DEFW SPRITE74           ; Graphic 74
  DEFW SPRITE75           ; Graphic 75
  DEFW SPRITE10           ; Graphic 76
  DEFW SPRITE10           ; Graphic 77
  DEFW SPRITE11           ; Graphic 78
  DEFW SPRITE11           ; Graphic 79
  DEFW SPRITE80           ; Graphic 80
  DEFW SPRITE81           ; Graphic 81
  DEFW SPRITE63           ; Graphic 82
  DEFW SPRITE0            ; Graphic 83
  DEFW SPRITE11           ; Graphic 84
  DEFW SPRITE11           ; Graphic 85
  DEFW SPRITE86           ; Graphic 86
  DEFW SPRITE11           ; Graphic 87
  DEFW SPRITE11           ; Graphic 88
  DEFW SPRITE16           ; Graphic 89
  DEFW SPRITE90           ; Graphic 90
  DEFW SPRITE11           ; Graphic 91
  DEFW SPRITE86           ; Graphic 92
  DEFW SPRITE86           ; Graphic 93
  DEFW SPRITE0            ; Graphic 94
  DEFW SPRITE0            ; Graphic 95
  DEFW SPRITE0            ; Graphic 96
  DEFW SPRITE0            ; Graphic 97
  DEFW SPRITE0            ; Graphic 98
  DEFW SPRITE0            ; Graphic 99
  DEFW SPRITE0            ; Graphic 100
  DEFW SPRITE0            ; Graphic 101
  DEFW SPRITE0            ; Graphic 102
  DEFW SPRITE0            ; Graphic 103
  DEFW SPRITE0            ; Graphic 104
  DEFW SPRITE0            ; Graphic 105
  DEFW SPRITE0            ; Graphic 106
  DEFW SPRITE0            ; Graphic 107
  DEFW SPRITE0            ; Graphic 108
  DEFW SPRITE0            ; Graphic 109
  DEFW SPRITE0            ; Graphic 110
  DEFW SPRITE0            ; Graphic 111
  DEFW SPRITE112          ; Graphic 112
  DEFW SPRITE112          ; Graphic 113
  DEFW SPRITE112          ; Graphic 114
  DEFW SPRITE112          ; Graphic 115
  DEFW SPRITE116          ; Graphic 116
  DEFW SPRITE116          ; Graphic 117
  DEFW SPRITE116          ; Graphic 118
  DEFW SPRITE116          ; Graphic 119
  DEFW SPRITE120          ; Graphic 120
  DEFW SPRITE11           ; Graphic 121
  DEFW SPRITE11           ; Graphic 122
  DEFW SPRITE11           ; Graphic 123
  DEFW SPRITE11           ; Graphic 124
  DEFW SPRITE11           ; Graphic 125
  DEFW SPRITE11           ; Graphic 126
  DEFW SPRITE11           ; Graphic 127
  DEFW SPRITE128          ; Graphic 128
  DEFW SPRITE129          ; Graphic 129
  DEFW SPRITE130          ; Graphic 130
  DEFW SPRITE131          ; Graphic 131
  DEFW SPRITE132          ; Graphic 132
  DEFW SPRITE133          ; Graphic 133
  DEFW SPRITE134          ; Graphic 134
  DEFW SPRITE135          ; Graphic 135
  DEFW SPRITE11           ; Graphic 136
  DEFW SPRITE137          ; Graphic 137
  DEFW SPRITE138          ; Graphic 138
  DEFW SPRITE139          ; Graphic 139
  DEFW SPRITE11           ; Graphic 140
  DEFW SPRITE11           ; Graphic 141
  DEFW SPRITE11           ; Graphic 142
  DEFW SPRITE11           ; Graphic 143
  DEFW SPRITE144          ; Graphic 144
  DEFW SPRITE145          ; Graphic 145
  DEFW SPRITE146          ; Graphic 146
  DEFW SPRITE147          ; Graphic 147
  DEFW SPRITE148          ; Graphic 148
  DEFW SPRITE149          ; Graphic 149
  DEFW SPRITE150          ; Graphic 150
  DEFW SPRITE151          ; Graphic 151
  DEFW SPRITE144          ; Graphic 152
  DEFW SPRITE145          ; Graphic 153
  DEFW SPRITE146          ; Graphic 154
  DEFW SPRITE147          ; Graphic 155
  DEFW SPRITE148          ; Graphic 156
  DEFW SPRITE0            ; Graphic 157
  DEFW SPRITE0            ; Graphic 158
  DEFW SPRITE0            ; Graphic 159
  DEFW SPRITE160          ; Graphic 160
  DEFW SPRITE161          ; Graphic 161
  DEFW SPRITE160          ; Graphic 162
  DEFW SPRITE163          ; Graphic 163
  DEFW SPRITE164          ; Graphic 164
  DEFW SPRITE165          ; Graphic 165
  DEFW SPRITE164          ; Graphic 166
  DEFW SPRITE167          ; Graphic 167
  DEFW SPRITE168          ; Graphic 168
  DEFW SPRITE169          ; Graphic 169
  DEFW SPRITE170          ; Graphic 170
  DEFW SPRITE171          ; Graphic 171

; Sprite for graphic 128
;
; 24 by 24 pixels.
;
; The sprites, end to end from here to CONTROL, with the font among them
; (FONT). Each is a width byte (bits 0-3 the width in bytes; bit 7 set while it
; is stored upside down, bit 6 while mirrored, both toggled in place by
; FIND_SPRITE as objects face about), a height byte, then a mask byte and an
; image byte for each cell, the bottom row first. On the tape every sprite is
; the right way round.
SPRITE128:
  DEFB $03,$18            ; Width in bytes, and height in rows
  DEFB $70,$70,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $70,$70,$00,$00,$00,$00 ; bottom row first
  DEFB $70,$70,$00,$00,$00,$00 ;
  DEFB $70,$70,$00,$00,$00,$00 ;
  DEFB $38,$38,$00,$00,$00,$00 ;
  DEFB $38,$38,$00,$00,$00,$00 ;
  DEFB $1C,$1C,$00,$00,$00,$00 ;
  DEFB $1E,$1E,$00,$00,$00,$00 ;
  DEFB $0F,$0F,$00,$00,$01,$01 ;
  DEFB $07,$07,$80,$80,$03,$03 ;
  DEFB $03,$03,$C0,$C0,$07,$07 ;
  DEFB $01,$01,$E0,$E0,$0F,$0F ;
  DEFB $00,$00,$78,$78,$1F,$1F ;
  DEFB $00,$00,$3E,$3E,$3C,$3C ;
  DEFB $00,$00,$0F,$0F,$A0,$A0 ;
  DEFB $00,$00,$03,$03,$E0,$E0 ;
  DEFB $00,$00,$00,$00,$F8,$F8 ;
  DEFB $00,$00,$00,$00,$3E,$3E ;
  DEFB $00,$00,$00,$00,$0F,$0F ;
  DEFB $00,$00,$00,$00,$01,$01 ;
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00 ;

; Sprite for graphic 129
;
; 24 by 24 pixels.
SPRITE129:
  DEFB $03,$18            ; Width in bytes, and height in rows
  DEFB $0F,$0F,$C0,$C0,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $03,$03,$80,$80,$00,$00 ; bottom row first
  DEFB $07,$07,$00,$00,$00,$00 ;
  DEFB $0E,$0E,$00,$00,$00,$00 ;
  DEFB $1E,$1E,$00,$00,$00,$00 ;
  DEFB $3C,$3C,$00,$00,$0F,$0F ;
  DEFB $78,$78,$00,$00,$FF,$FF ;
  DEFB $F0,$F0,$0F,$0F,$FF,$FF ;
  DEFB $E0,$E0,$FF,$FF,$F8,$F8 ;
  DEFB $CF,$CF,$FF,$FF,$00,$00 ;
  DEFB $BF,$BF,$F0,$F0,$00,$00 ;
  DEFB $FE,$FE,$00,$00,$00,$00 ;
  DEFB $E0,$E0,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $C0,$C0,$00,$00,$00,$00 ;
  DEFB $FC,$FC,$00,$00,$00,$00 ;
  DEFB $3F,$3F,$F0,$F0,$00,$00 ;
  DEFB $03,$03,$FF,$FF,$FF,$FF ;
  DEFB $00,$00,$0F,$0F,$FF,$FF ;
  DEFB $00,$00,$00,$00,$00,$00 ;

; Sprite for graphic 130
;
; 24 by 24 pixels.
SPRITE130:
  DEFB $03,$18            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$00,$00,$7F,$7F ; bottom row first
  DEFB $00,$00,$03,$03,$FF,$FF ;
  DEFB $00,$00,$03,$03,$F0,$F0 ;
  DEFB $00,$00,$01,$01,$80,$80 ;
  DEFB $80,$80,$01,$01,$C0,$C0 ;
  DEFB $E0,$E0,$00,$00,$C0,$C0 ;
  DEFB $F8,$F8,$00,$00,$E0,$E0 ;
  DEFB $FF,$FF,$00,$00,$60,$60 ;
  DEFB $1F,$1F,$C0,$C0,$70,$70 ;
  DEFB $07,$07,$F0,$F0,$30,$30 ;
  DEFB $00,$00,$FE,$FE,$38,$38 ;
  DEFB $00,$00,$3F,$3F,$98,$98 ;
  DEFB $00,$00,$07,$07,$F8,$F8 ;
  DEFB $00,$00,$01,$01,$FC,$FC ;
  DEFB $00,$00,$00,$00,$3C,$3C ;
  DEFB $00,$00,$00,$00,$0E,$0E ;
  DEFB $00,$00,$00,$00,$01,$01 ;
  DEFB $00,$00,$00,$00,$03,$03 ;
  DEFB $00,$00,$00,$00,$3F,$3F ;
  DEFB $00,$00,$0F,$0F,$FC,$FC ;
  DEFB $FF,$FF,$FF,$FF,$C0,$C0 ;
  DEFB $FF,$FF,$F0,$F0,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00 ;

; Sprite for graphic 131
;
; 24 by 24 pixels.
SPRITE131:
  DEFB $03,$18            ; Width in bytes, and height in rows
  DEFB $FF,$FF,$C0,$C0,$0E,$0E ; Mask and image bytes, a pair per cell, the
  DEFB $FC,$FC,$00,$00,$0E,$0E ; bottom row first
  DEFB $80,$80,$00,$00,$0E,$0E ;
  DEFB $00,$00,$00,$00,$0E,$0E ;
  DEFB $00,$00,$00,$00,$1C,$1C ;
  DEFB $00,$00,$00,$00,$1C,$1C ;
  DEFB $00,$00,$00,$00,$38,$38 ;
  DEFB $00,$00,$00,$00,$78,$78 ;
  DEFB $00,$00,$00,$00,$F0,$F0 ;
  DEFB $00,$00,$01,$01,$E0,$E0 ;
  DEFB $00,$00,$03,$03,$C0,$C0 ;
  DEFB $00,$00,$07,$07,$80,$80 ;
  DEFB $00,$00,$1E,$1E,$00,$00 ;
  DEFB $00,$00,$7C,$7C,$00,$00 ;
  DEFB $01,$01,$F0,$F0,$00,$00 ;
  DEFB $07,$07,$C0,$C0,$00,$00 ;
  DEFB $1F,$1F,$00,$00,$00,$00 ;
  DEFB $7C,$7C,$00,$00,$00,$00 ;
  DEFB $F0,$F0,$00,$00,$00,$00 ;
  DEFB $80,$80,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00 ;

; Sprite for graphic 132
;
; 24 by 24 pixels.
SPRITE132:
  DEFB $03,$18            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$00,$00,$00,$00 ; bottom row first
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$01,$01 ;
  DEFB $00,$00,$00,$00,$0F,$0F ;
  DEFB $00,$00,$00,$00,$3E,$3E ;
  DEFB $00,$00,$00,$00,$F8,$F8 ;
  DEFB $00,$00,$03,$03,$E0,$E0 ;
  DEFB $00,$00,$0F,$0F,$80,$80 ;
  DEFB $00,$00,$3E,$3E,$00,$00 ;
  DEFB $00,$00,$78,$78,$00,$00 ;
  DEFB $01,$01,$E0,$E0,$00,$00 ;
  DEFB $03,$03,$C0,$C0,$00,$00 ;
  DEFB $07,$07,$80,$80,$00,$00 ;
  DEFB $0F,$0F,$FF,$FF,$F0,$F0 ;
  DEFB $1E,$1E,$1F,$1F,$FF,$FF ;
  DEFB $1C,$1C,$07,$07,$FF,$FF ;
  DEFB $38,$38,$00,$00,$F8,$F8 ;
  DEFB $38,$38,$00,$00,$3F,$3F ;
  DEFB $70,$70,$00,$00,$07,$07 ;
  DEFB $70,$70,$00,$00,$01,$01 ;
  DEFB $70,$70,$00,$00,$00,$00 ;

; Sprite for graphic 133
;
; 24 by 24 pixels.
SPRITE133:
  DEFB $03,$18            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$00,$00,$00,$00 ; bottom row first
  DEFB $00,$00,$0F,$0F,$FF,$FF ;
  DEFB $03,$03,$FF,$FF,$FF,$FF ;
  DEFB $3F,$3F,$F0,$F0,$00,$00 ;
  DEFB $FC,$FC,$00,$00,$00,$00 ;
  DEFB $C0,$C0,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$01,$01 ;
  DEFB $00,$00,$00,$00,$03,$03 ;
  DEFB $00,$00,$00,$00,$07,$07 ;
  DEFB $00,$00,$00,$00,$0F,$0F ;
  DEFB $00,$00,$00,$00,$1E,$1E ;
  DEFB $00,$00,$00,$00,$3C,$3C ;
  DEFB $00,$00,$00,$00,$78,$78 ;
  DEFB $00,$00,$00,$00,$F0,$F0 ;
  DEFB $00,$00,$01,$01,$E0,$E0 ;
  DEFB $00,$00,$03,$03,$C0,$C0 ;
  DEFB $FF,$FF,$07,$07,$80,$80 ;
  DEFB $FF,$FF,$FF,$FF,$00,$00 ;
  DEFB $7F,$7F,$FE,$FE,$00,$00 ;
  DEFB $00,$00,$7C,$7C,$00,$00 ;
  DEFB $E0,$E0,$00,$00,$00,$00 ;
  DEFB $FC,$FC,$00,$00,$00,$00 ;
  DEFB $3F,$3F,$00,$00,$00,$00 ;

; Sprite for graphic 134
;
; 24 by 24 pixels.
SPRITE134:
  DEFB $03,$18            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$00,$00,$00,$00 ; bottom row first
  DEFB $FF,$FF,$F0,$F0,$00,$00 ;
  DEFB $FF,$FF,$FF,$FF,$C0,$C0 ;
  DEFB $3E,$3E,$0F,$0F,$FC,$FC ;
  DEFB $7E,$7E,$00,$00,$3F,$3F ;
  DEFB $F7,$F7,$00,$00,$03,$03 ;
  DEFB $E7,$E7,$00,$00,$00,$00 ;
  DEFB $C3,$C3,$80,$80,$00,$00 ;
  DEFB $83,$83,$80,$80,$00,$00 ;
  DEFB $01,$01,$80,$80,$00,$00 ;
  DEFB $01,$01,$C0,$C0,$00,$00 ;
  DEFB $00,$00,$C0,$C0,$00,$00 ;
  DEFB $00,$00,$E0,$E0,$00,$00 ;
  DEFB $00,$00,$E0,$E0,$00,$00 ;
  DEFB $00,$00,$70,$70,$00,$00 ;
  DEFB $00,$00,$70,$70,$00,$00 ;
  DEFB $00,$00,$38,$38,$00,$00 ;
  DEFB $00,$00,$38,$38,$00,$00 ;
  DEFB $00,$00,$1C,$1C,$00,$00 ;
  DEFB $00,$00,$1F,$1F,$F0,$F0 ;
  DEFB $00,$00,$0F,$0F,$FF,$FF ;
  DEFB $00,$00,$00,$00,$FF,$FF ;
  DEFB $00,$00,$00,$00,$00,$00 ;

; Sprite for graphic 135
;
; 24 by 24 pixels.
SPRITE135:
  DEFB $03,$18            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$00,$00,$00,$00 ; bottom row first
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $80,$80,$00,$00,$00,$00 ;
  DEFB $F0,$F0,$00,$00,$00,$00 ;
  DEFB $7C,$7C,$00,$00,$00,$00 ;
  DEFB $1F,$1F,$00,$00,$00,$00 ;
  DEFB $07,$07,$C0,$C0,$00,$00 ;
  DEFB $01,$01,$F0,$F0,$00,$00 ;
  DEFB $00,$00,$7C,$7C,$00,$00 ;
  DEFB $00,$00,$1E,$1E,$00,$00 ;
  DEFB $00,$00,$07,$07,$80,$80 ;
  DEFB $00,$00,$03,$03,$C0,$C0 ;
  DEFB $00,$00,$01,$01,$E0,$E0 ;
  DEFB $00,$00,$00,$00,$F0,$F0 ;
  DEFB $00,$00,$00,$00,$78,$78 ;
  DEFB $00,$00,$00,$00,$38,$38 ;
  DEFB $00,$00,$00,$00,$1C,$1C ;
  DEFB $00,$00,$00,$00,$1C,$1C ;
  DEFB $FF,$FF,$00,$00,$0E,$0E ;
  DEFB $FF,$FF,$FF,$FF,$FE,$FE ;
  DEFB $0F,$0F,$FC,$FC,$0E,$0E ;

; Sprite for graphic 74
;
; 32 by 16 pixels.
SPRITE74:
  DEFB $04,$10            ; Width in bytes, and height in rows
  DEFB $00,$00,$05,$05,$55,$55,$00,$00 ; Mask and image bytes, a pair per cell,
  DEFB $00,$00,$2F,$2A,$FF,$AA,$80,$80 ; the bottom row first
  DEFB $01,$01,$7F,$55,$FF,$55,$C0,$40 ;
  DEFB $00,$00,$FF,$AA,$FF,$AA,$E8,$A8 ;
  DEFB $15,$15,$FF,$55,$FF,$55,$FC,$54 ;
  DEFB $3F,$2A,$FF,$AA,$FF,$AA,$FE,$AA ;
  DEFB $7F,$55,$FF,$55,$FF,$55,$FF,$55 ;
  DEFB $FF,$AA,$FF,$AA,$FF,$AA,$FE,$AA ;
  DEFB $7F,$55,$FF,$55,$FF,$55,$FF,$55 ;
  DEFB $FF,$AA,$FF,$AA,$FF,$AA,$FE,$AA ;
  DEFB $5F,$55,$FF,$55,$FF,$55,$FD,$55 ;
  DEFB $0B,$0A,$FF,$AA,$FF,$AA,$F8,$A8 ;
  DEFB $01,$01,$FF,$55,$FF,$55,$F0,$50 ;
  DEFB $00,$00,$FF,$AA,$FE,$AA,$A0,$A0 ;
  DEFB $00,$00,$57,$55,$FC,$54,$00,$00 ;
  DEFB $00,$00,$03,$02,$F8,$A8,$00,$00 ;

; Sprite for graphic 75
;
; 32 by 16 pixels.
SPRITE75:
  DEFB $04,$10            ; Width in bytes, and height in rows
  DEFB $00,$00,$0F,$05,$FC,$54,$00,$00 ; Mask and image bytes, a pair per cell,
  DEFB $01,$00,$FF,$AA,$FF,$AA,$E0,$A0 ; the bottom row first
  DEFB $03,$01,$FF,$55,$FF,$55,$F0,$50 ;
  DEFB $0F,$0A,$FF,$AA,$FF,$0A,$FC,$A8 ;
  DEFB $3F,$15,$FF,$51,$FF,$E5,$FC,$54 ;
  DEFB $7F,$2A,$FF,$A7,$FF,$FA,$FD,$A8 ;
  DEFB $FF,$55,$FF,$4F,$FF,$F5,$FF,$45 ;
  DEFB $FF,$AA,$FF,$93,$FF,$F2,$FF,$BA ;
  DEFB $FF,$55,$FF,$47,$FF,$F9,$FF,$7D ;
  DEFB $7F,$2A,$FF,$A5,$FF,$AA,$FF,$54 ;
  DEFB $3F,$15,$FF,$4D,$FF,$A5,$FE,$10 ;
  DEFB $1F,$0A,$FF,$A9,$FF,$A2,$FC,$A8 ;
  DEFB $1F,$15,$FF,$54,$FF,$A5,$F8,$50 ;
  DEFB $1F,$0A,$FF,$AA,$FF,$8A,$F0,$A0 ;
  DEFB $0F,$05,$FF,$54,$FF,$95,$C0,$40 ;
  DEFB $00,$00,$3F,$2A,$F8,$28,$00,$00 ;

; Sprite for graphic 137
;
; 32 by 27 pixels.
SPRITE137:
  DEFB $04,$1B            ; Width in bytes, and height in rows
  DEFB $00,$00,$04,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell,
  DEFB $00,$00,$1E,$04,$20,$00,$00,$00 ; the bottom row first
  DEFB $00,$00,$3F,$1E,$70,$20,$00,$00 ;
  DEFB $00,$00,$7F,$3E,$F8,$50,$00,$00 ;
  DEFB $00,$00,$7F,$3E,$74,$20,$00,$00 ;
  DEFB $03,$00,$3E,$1C,$3E,$14,$00,$00 ;
  DEFB $1F,$03,$BC,$00,$1F,$0A,$00,$00 ;
  DEFB $3F,$1F,$FD,$9C,$AF,$05,$82,$00 ;
  DEFB $7F,$3F,$FF,$CC,$F5,$A0,$C7,$02 ;
  DEFB $7F,$3F,$FE,$CC,$F8,$10,$EE,$44 ;
  DEFB $3F,$03,$ED,$C0,$FD,$28,$DF,$82 ;
  DEFB $1F,$01,$E3,$C1,$F8,$90,$FE,$54 ;
  DEFB $1F,$01,$E7,$C3,$FD,$C0,$FC,$A0 ;
  DEFB $3F,$1C,$CF,$81,$FE,$E4,$FE,$54 ;
  DEFB $7F,$3C,$FF,$0C,$F9,$F0,$F7,$A2 ;
  DEFB $FC,$78,$7F,$3E,$FF,$00,$AE,$04 ;
  DEFB $78,$20,$FF,$7F,$FF,$CF,$87,$02 ;
  DEFB $23,$00,$FF,$1F,$FF,$9F,$F2,$00 ;
  DEFB $0F,$03,$FF,$9F,$FF,$3E,$F8,$70 ;
  DEFB $1F,$0F,$9F,$0C,$FF,$78,$FC,$F8 ;
  DEFB $1F,$0F,$CC,$80,$7F,$30,$F8,$E0 ;
  DEFB $0F,$03,$83,$00,$FF,$0E,$E0,$C0 ;
  DEFB $03,$00,$3F,$03,$FF,$9B,$C0,$00 ;
  DEFB $00,$00,$7F,$3F,$FB,$B0,$00,$00 ;
  DEFB $00,$00,$3F,$0F,$F0,$A0,$00,$00 ;
  DEFB $00,$00,$0F,$03,$A0,$00,$00,$00 ;
  DEFB $00,$00,$03,$00,$00,$00,$00,$00 ;

; Sprite for graphic 138
;
; 32 by 27 pixels.
SPRITE138:
  DEFB $04,$1B            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell,
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; the bottom row first
  DEFB $00,$00,$04,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$0E,$04,$10,$00,$00,$00 ;
  DEFB $00,$00,$1E,$0C,$38,$10,$00,$00 ;
  DEFB $00,$00,$3C,$18,$74,$20,$00,$00 ;
  DEFB $00,$00,$18,$00,$3E,$14,$00,$00 ;
  DEFB $03,$00,$04,$00,$1C,$08,$00,$00 ;
  DEFB $0F,$03,$8E,$04,$0E,$04,$00,$00 ;
  DEFB $1F,$0F,$DE,$8C,$14,$00,$00,$00 ;
  DEFB $0F,$03,$EC,$C0,$38,$10,$02,$00 ;
  DEFB $03,$01,$E0,$C0,$7C,$28,$47,$02 ;
  DEFB $01,$00,$C1,$80,$F8,$10,$EE,$44 ;
  DEFB $80,$00,$83,$01,$F0,$C0,$74,$20 ;
  DEFB $1C,$08,$03,$01,$F0,$E0,$FA,$50 ;
  DEFB $3C,$18,$09,$00,$E0,$40,$77,$22 ;
  DEFB $78,$30,$1E,$08,$40,$00,$2E,$04 ;
  DEFB $60,$00,$3F,$1E,$0E,$00,$04,$00 ;
  DEFB $00,$00,$1F,$0E,$1F,$0E,$60,$00 ;
  DEFB $07,$00,$0E,$04,$3E,$18,$F0,$60 ;
  DEFB $0F,$07,$84,$00,$78,$30,$F0,$60 ;
  DEFB $07,$02,$00,$00,$3F,$00,$E0,$C0 ;
  DEFB $02,$00,$00,$00,$1F,$0E,$C0,$00 ;
  DEFB $00,$00,$0F,$00,$BE,$18,$00,$00 ;
  DEFB $00,$00,$1F,$0F,$F8,$90,$00,$00 ;
  DEFB $00,$00,$0F,$03,$90,$00,$00,$00 ;
  DEFB $00,$00,$03,$00,$00,$00,$00,$00 ;

; Sprite for graphic 139
;
; 32 by 27 pixels.
SPRITE139:
  DEFB $04,$1B            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell,
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; the bottom row first
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$04,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$0E,$04,$00,$00,$00,$00 ;
  DEFB $00,$00,$1C,$08,$10,$00,$00,$00 ;
  DEFB $00,$00,$08,$00,$38,$10,$00,$00 ;
  DEFB $02,$00,$00,$00,$1C,$08,$00,$00 ;
  DEFB $07,$02,$04,$00,$08,$00,$00,$00 ;
  DEFB $0F,$07,$CE,$04,$10,$00,$00,$00 ;
  DEFB $07,$01,$E4,$C0,$38,$10,$00,$00 ;
  DEFB $01,$00,$C0,$80,$10,$00,$04,$00 ;
  DEFB $00,$00,$80,$00,$F8,$10,$2E,$04 ;
  DEFB $00,$00,$01,$00,$F0,$C0,$74,$20 ;
  DEFB $18,$00,$01,$00,$E0,$C0,$E0,$40 ;
  DEFB $3C,$18,$00,$00,$C0,$00,$70,$20 ;
  DEFB $38,$10,$0C,$00,$00,$00,$20,$00 ;
  DEFB $10,$00,$1E,$0C,$08,$00,$00,$00 ;
  DEFB $00,$00,$0E,$04,$1C,$08,$40,$00 ;
  DEFB $03,$00,$04,$00,$3C,$18,$E0,$20 ;
  DEFB $07,$03,$80,$00,$38,$10,$F0,$60 ;
  DEFB $03,$00,$00,$00,$18,$00,$60,$00 ;
  DEFB $00,$00,$00,$00,$1C,$04,$00,$00 ;
  DEFB $00,$00,$03,$00,$3C,$18,$00,$00 ;
  DEFB $00,$00,$07,$03,$98,$00,$00,$00 ;
  DEFB $00,$00,$03,$00,$00,$00,$00,$00 ;

; Sprite for graphics 86, 92-93
;
; 32 by 24 pixels.
SPRITE86:
  DEFB $04,$18            ; Width in bytes, and height in rows
  DEFB $00,$00,$16,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell,
  DEFB $00,$00,$3F,$16,$00,$00,$00,$00 ; the bottom row first
  DEFB $03,$00,$FF,$27,$83,$00,$00,$00 ;
  DEFB $07,$03,$FF,$B1,$CF,$83,$80,$00 ;
  DEFB $1F,$07,$FF,$00,$FF,$CE,$F0,$00 ;
  DEFB $3F,$14,$FF,$78,$FF,$7E,$F8,$F0 ;
  DEFB $7F,$34,$FF,$CA,$FF,$3F,$F0,$C0 ;
  DEFB $7F,$21,$FF,$CB,$FF,$1E,$C0,$80 ;
  DEFB $3F,$1F,$FF,$FB,$FF,$CF,$F0,$C0 ;
  DEFB $7F,$33,$FF,$F7,$FF,$FF,$F8,$F0 ;
  DEFB $7F,$33,$FF,$0F,$FF,$FF,$F0,$E0 ;
  DEFB $3F,$1E,$FF,$F7,$FF,$7F,$F0,$C0 ;
  DEFB $1F,$0D,$FF,$FB,$FF,$93,$F8,$F0 ;
  DEFB $0F,$03,$FF,$FC,$FF,$C7,$FC,$F8 ;
  DEFB $03,$00,$FF,$1F,$FF,$7C,$F8,$C0 ;
  DEFB $00,$00,$7F,$2B,$FF,$83,$E0,$C0 ;
  DEFB $00,$00,$3F,$13,$FF,$FF,$E0,$C0 ;
  DEFB $00,$00,$1F,$0D,$FF,$BD,$F0,$E0 ;
  DEFB $00,$00,$0F,$00,$FF,$3E,$F0,$E0 ;
  DEFB $00,$00,$0F,$06,$FE,$9C,$F8,$70 ;
  DEFB $00,$00,$07,$03,$DC,$88,$7C,$38 ;
  DEFB $00,$00,$03,$01,$C8,$80,$78,$00 ;
  DEFB $00,$00,$01,$00,$E0,$C0,$00,$00 ;
  DEFB $00,$00,$00,$00,$C0,$00,$00,$00 ;

; Sprite for graphic 168
;
; 24 by 25 pixels.
SPRITE168:
  DEFB $03,$19            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$00,$00,$00,$00 ; bottom row first
  DEFB $00,$00,$1C,$00,$70,$00 ;
  DEFB $00,$00,$3F,$1C,$FC,$70 ;
  DEFB $00,$00,$1F,$0F,$FE,$3C ;
  DEFB $00,$00,$0F,$07,$FE,$1C ;
  DEFB $00,$00,$0F,$06,$FC,$78 ;
  DEFB $00,$00,$8F,$05,$F8,$F0 ;
  DEFB $01,$00,$CF,$86,$F8,$18 ;
  DEFB $03,$01,$EF,$47,$F8,$E8 ;
  DEFB $11,$00,$FF,$E7,$F8,$F0 ;
  DEFB $3B,$11,$FF,$E9,$F8,$F0 ;
  DEFB $7F,$28,$FF,$5E,$F8,$70 ;
  DEFB $7F,$3D,$FF,$3F,$F8,$B0 ;
  DEFB $3F,$1D,$FF,$DF,$FC,$F8 ;
  DEFB $1F,$03,$FF,$EF,$FC,$F8 ;
  DEFB $1F,$0F,$FF,$FF,$FC,$F8 ;
  DEFB $0F,$01,$FF,$F1,$F8,$E0 ;
  DEFB $01,$00,$FF,$7B,$F8,$F0 ;
  DEFB $00,$00,$7F,$1E,$F8,$70 ;
  DEFB $00,$00,$3F,$12,$F8,$70 ;
  DEFB $00,$00,$3F,$13,$F8,$F0 ;
  DEFB $00,$00,$3F,$1F,$F0,$E0 ;
  DEFB $00,$00,$1F,$0F,$E0,$C0 ;
  DEFB $00,$00,$0F,$00,$C0,$00 ;

; Sprite for graphic 169
;
; 24 by 25 pixels.
SPRITE169:
  DEFB $03,$19            ; Width in bytes, and height in rows
  DEFB $00,$00,$06,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$CF,$06,$80,$00 ; bottom row first
  DEFB $00,$00,$1F,$0F,$C0,$80 ;
  DEFB $00,$00,$0F,$07,$E0,$C0 ;
  DEFB $00,$00,$07,$01,$F0,$C0 ;
  DEFB $00,$00,$03,$01,$FC,$E0 ;
  DEFB $00,$00,$03,$00,$FE,$EC ;
  DEFB $00,$00,$47,$02,$FE,$F4 ;
  DEFB $00,$00,$E7,$42,$FC,$10 ;
  DEFB $01,$00,$F7,$A3,$FC,$E8 ;
  DEFB $08,$00,$FF,$73,$F8,$F0 ;
  DEFB $1D,$08,$FF,$F4,$FC,$F8 ;
  DEFB $3F,$14,$FF,$2F,$FC,$38 ;
  DEFB $3F,$1E,$FF,$9F,$FC,$D8 ;
  DEFB $1F,$0C,$FF,$EF,$FE,$FC ;
  DEFB $0F,$01,$FF,$F7,$FE,$FC ;
  DEFB $0F,$07,$FF,$FF,$FE,$FC ;
  DEFB $07,$00,$FF,$F8,$FC,$F0 ;
  DEFB $00,$00,$FF,$3D,$FC,$F8 ;
  DEFB $00,$00,$3F,$0F,$FC,$38 ;
  DEFB $00,$00,$1F,$09,$FC,$38 ;
  DEFB $00,$00,$1F,$09,$FC,$F8 ;
  DEFB $00,$00,$1F,$0F,$F8,$F0 ;
  DEFB $00,$00,$0F,$07,$F0,$E0 ;
  DEFB $00,$00,$07,$00,$E0,$00 ;

; Sprite for graphic 170
;
; 24 by 29 pixels.
SPRITE170:
  DEFB $03,$1D            ; Width in bytes, and height in rows
  DEFB $00,$00,$C0,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $01,$00,$F0,$C0,$00,$00 ; bottom row first
  DEFB $03,$01,$F8,$F0,$00,$00 ;
  DEFB $03,$01,$F8,$F0,$00,$00 ;
  DEFB $03,$00,$F0,$C0,$00,$00 ;
  DEFB $07,$02,$E0,$C0,$00,$00 ;
  DEFB $0F,$06,$F0,$E0,$00,$00 ;
  DEFB $0F,$06,$FC,$E0,$00,$00 ;
  DEFB $1F,$0F,$FE,$EC,$00,$00 ;
  DEFB $3F,$1F,$FE,$F4,$00,$00 ;
  DEFB $3F,$18,$FC,$70,$00,$00 ;
  DEFB $1F,$07,$F8,$90,$00,$00 ;
  DEFB $3F,$1F,$F0,$E0,$00,$00 ;
  DEFB $7F,$3F,$F0,$E0,$00,$00 ;
  DEFB $7F,$3F,$F0,$E0,$00,$00 ;
  DEFB $7F,$3F,$FC,$F0,$00,$00 ;
  DEFB $7F,$3F,$FF,$FC,$00,$00 ;
  DEFB $7F,$38,$FF,$7F,$C0,$00 ;
  DEFB $7F,$37,$FF,$BF,$E0,$C0 ;
  DEFB $7F,$2F,$FF,$DF,$F8,$E0 ;
  DEFB $3F,$1F,$FF,$EF,$FC,$E8 ;
  DEFB $7F,$3F,$FF,$F1,$FE,$EC ;
  DEFB $7F,$3F,$FF,$F6,$FF,$52 ;
  DEFB $3F,$1F,$FF,$EF,$FE,$18 ;
  DEFB $1F,$0F,$EF,$C6,$F8,$C0 ;
  DEFB $0F,$07,$C7,$81,$E0,$40 ;
  DEFB $07,$00,$83,$01,$C0,$00 ;
  DEFB $00,$00,$01,$00,$C0,$80 ;
  DEFB $00,$00,$00,$00,$80,$00 ;

; Sprite for graphic 171
;
; 24 by 28 pixels.
SPRITE171:
  DEFB $03,$1C            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$00,$00,$00,$00 ; bottom row first
  DEFB $18,$00,$00,$00,$00,$00 ;
  DEFB $3E,$18,$0C,$00,$00,$00 ;
  DEFB $3F,$1E,$9E,$0C,$00,$00 ;
  DEFB $3F,$1F,$DF,$1E,$80,$00 ;
  DEFB $3F,$1D,$FF,$9F,$C0,$80 ;
  DEFB $1F,$0C,$FF,$7F,$80,$00 ;
  DEFB $1F,$0D,$FF,$FC,$00,$00 ;
  DEFB $1F,$0B,$FC,$F8,$00,$00 ;
  DEFB $1F,$0C,$F8,$30,$00,$00 ;
  DEFB $0F,$03,$F0,$C0,$00,$00 ;
  DEFB $1F,$0F,$F8,$F0,$00,$00 ;
  DEFB $3F,$1F,$F8,$F0,$00,$00 ;
  DEFB $3F,$1F,$F8,$F0,$00,$00 ;
  DEFB $3F,$1F,$FE,$F8,$00,$00 ;
  DEFB $3F,$1F,$FF,$FE,$80,$00 ;
  DEFB $3F,$1C,$FF,$3F,$E0,$80 ;
  DEFB $3F,$1B,$FF,$DF,$F0,$E0 ;
  DEFB $3F,$17,$FF,$EF,$FC,$F0 ;
  DEFB $1F,$0F,$FF,$F3,$FE,$F4 ;
  DEFB $3F,$1F,$FF,$F8,$FF,$F6 ;
  DEFB $3F,$1F,$FF,$FB,$FF,$2A ;
  DEFB $1F,$0F,$FF,$F7,$FE,$8C ;
  DEFB $0F,$07,$F7,$E3,$FC,$60 ;
  DEFB $07,$03,$E3,$C0,$F0,$A0 ;
  DEFB $03,$00,$C0,$00,$E0,$40 ;
  DEFB $00,$00,$00,$00,$40,$00 ;

; Sprite for graphic 80
;
; 32 by 24 pixels.
SPRITE80:
  DEFB $04,$18            ; Width in bytes, and height in rows
  DEFB $00,$00,$02,$00,$00,$00,$10,$00 ; Mask and image bytes, a pair per cell,
  DEFB $00,$00,$1F,$02,$E0,$00,$38,$10 ; the bottom row first
  DEFB $00,$00,$3F,$19,$FF,$E0,$FC,$28 ;
  DEFB $00,$00,$7F,$00,$FF,$EF,$FC,$F8 ;
  DEFB $1F,$00,$FF,$74,$FF,$C1,$F8,$C0 ;
  DEFB $BF,$1F,$FF,$E8,$FF,$DE,$FC,$B8 ;
  DEFB $3F,$1F,$FF,$8C,$FF,$FF,$F8,$70 ;
  DEFB $1F,$00,$FF,$6C,$FF,$3F,$FC,$88 ;
  DEFB $00,$00,$7F,$16,$FF,$FF,$FC,$B8 ;
  DEFB $00,$00,$FF,$66,$FF,$FF,$F8,$80 ;
  DEFB $00,$00,$FF,$7B,$FF,$FF,$C0,$80 ;
  DEFB $00,$00,$7F,$0D,$FF,$FF,$C0,$80 ;
  DEFB $00,$00,$FF,$76,$FF,$FF,$C0,$80 ;
  DEFB $00,$00,$FF,$12,$FF,$BF,$80,$00 ;
  DEFB $01,$00,$FF,$A8,$FF,$BE,$00,$00 ;
  DEFB $01,$00,$FF,$83,$FF,$00,$00,$00 ;
  DEFB $00,$00,$FF,$7C,$C0,$80,$00,$00 ;
  DEFB $00,$00,$7F,$13,$C0,$80,$00,$00 ;
  DEFB $00,$00,$1F,$0F,$C0,$80,$00,$00 ;
  DEFB $00,$00,$0F,$07,$C0,$80,$00,$00 ;
  DEFB $00,$00,$07,$03,$C0,$80,$00,$00 ;
  DEFB $00,$00,$03,$01,$C0,$80,$00,$00 ;
  DEFB $00,$00,$01,$00,$C0,$80,$00,$00 ;
  DEFB $00,$00,$00,$00,$80,$00,$00,$00 ;

; Sprite for graphic 81
;
; 32 by 24 pixels.
SPRITE81:
  DEFB $04,$18            ; Width in bytes, and height in rows
  DEFB $00,$00,$40,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell,
  DEFB $00,$00,$E0,$40,$00,$00,$00,$00 ; the bottom row first
  DEFB $05,$00,$F0,$A0,$00,$00,$00,$00 ;
  DEFB $0F,$05,$FC,$F0,$00,$00,$00,$00 ;
  DEFB $1F,$0A,$FF,$4C,$00,$00,$00,$00 ;
  DEFB $1F,$0F,$FF,$BF,$CC,$00,$00,$00 ;
  DEFB $0F,$05,$FF,$7F,$FF,$CC,$00,$00 ;
  DEFB $1F,$0E,$FF,$FF,$FF,$EF,$80,$00 ;
  DEFB $0F,$02,$FF,$FF,$FF,$ED,$C0,$80 ;
  DEFB $03,$00,$FF,$FF,$FF,$FC,$80,$00 ;
  DEFB $01,$00,$FF,$FF,$FF,$FE,$00,$00 ;
  DEFB $01,$00,$FF,$FF,$FF,$FE,$00,$00 ;
  DEFB $00,$00,$FF,$7F,$FE,$E0,$00,$00 ;
  DEFB $00,$00,$FF,$7F,$FF,$FC,$E0,$00 ;
  DEFB $00,$00,$7F,$3F,$FF,$87,$F0,$C0 ;
  DEFB $00,$00,$3F,$1F,$FF,$78,$F0,$00 ;
  DEFB $00,$00,$1F,$06,$FF,$FC,$FC,$70 ;
  DEFB $00,$00,$07,$01,$FF,$8E,$FE,$BC ;
  DEFB $00,$00,$03,$01,$FF,$76,$FF,$8E ;
  DEFB $00,$00,$03,$00,$FF,$FA,$8F,$02 ;
  DEFB $00,$00,$0F,$03,$FF,$FA,$02,$00 ;
  DEFB $00,$00,$1F,$0F,$FF,$F6,$00,$00 ;
  DEFB $00,$00,$3F,$1E,$FE,$0C,$00,$00 ;
  DEFB $00,$00,$1E,$00,$0C,$00,$00,$00 ;

; Sprite for graphic 167
;
; 24 by 21 pixels.
SPRITE167:
  DEFB $03,$15            ; Width in bytes, and height in rows
  DEFB $00,$00,$FF,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $03,$00,$FF,$FF,$C0,$00 ; bottom row first
  DEFB $0F,$03,$FF,$FF,$F0,$C0 ;
  DEFB $3F,$0F,$FF,$FF,$F8,$F0 ;
  DEFB $7F,$3F,$FF,$FF,$FC,$F8 ;
  DEFB $FF,$7F,$FF,$FF,$FE,$FC ;
  DEFB $FF,$71,$FF,$FF,$FF,$FE ;
  DEFB $FF,$60,$FF,$FF,$FF,$FE ;
  DEFB $FF,$60,$FF,$7F,$FF,$FE ;
  DEFB $7F,$30,$FF,$7F,$FF,$FE ;
  DEFB $3F,$18,$FF,$3F,$FE,$FC ;
  DEFB $1F,$0E,$FF,$3F,$FC,$F8 ;
  DEFB $0F,$07,$FF,$3F,$F8,$F0 ;
  DEFB $07,$03,$FF,$1F,$F0,$E0 ;
  DEFB $07,$03,$FF,$9F,$E0,$C0 ;
  DEFB $03,$01,$FF,$CF,$C0,$80 ;
  DEFB $03,$01,$FF,$FF,$C0,$80 ;
  DEFB $01,$00,$FF,$FF,$80,$00 ;
  DEFB $00,$00,$FF,$7E,$00,$00 ;
  DEFB $00,$00,$7E,$38,$00,$00 ;
  DEFB $00,$00,$38,$00,$00,$00 ;

; Sprite for graphics 164, 166
;
; 24 by 24 pixels.
SPRITE164:
  DEFB $03,$18            ; Width in bytes, and height in rows
  DEFB $00,$00,$3C,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $01,$00,$FF,$3C,$80,$00 ; bottom row first
  DEFB $07,$01,$FF,$FF,$E0,$80 ;
  DEFB $0F,$07,$FF,$FF,$F0,$E0 ;
  DEFB $1F,$0F,$FF,$FF,$F8,$F0 ;
  DEFB $3F,$1F,$FF,$FF,$FC,$F8 ;
  DEFB $3F,$19,$FF,$FF,$FC,$F8 ;
  DEFB $7F,$30,$FF,$FF,$FF,$FC ;
  DEFB $7F,$30,$FF,$FF,$FE,$FC ;
  DEFB $3F,$18,$FF,$7F,$FC,$F8 ;
  DEFB $3F,$1C,$FF,$7F,$FC,$F8 ;
  DEFB $1F,$0C,$FF,$7F,$F8,$F0 ;
  DEFB $1F,$0E,$FF,$7F,$F8,$F0 ;
  DEFB $0F,$06,$FF,$7F,$F0,$E0 ;
  DEFB $0F,$06,$FF,$3F,$F0,$E0 ;
  DEFB $0F,$07,$FF,$3F,$F0,$E0 ;
  DEFB $07,$03,$FF,$3F,$E0,$C0 ;
  DEFB $07,$03,$FF,$BF,$E0,$C0 ;
  DEFB $07,$03,$FF,$BF,$E0,$C0 ;
  DEFB $03,$01,$FF,$FF,$C0,$80 ;
  DEFB $03,$01,$FF,$FF,$C0,$80 ;
  DEFB $01,$00,$FF,$FF,$80,$00 ;
  DEFB $00,$00,$FF,$7E,$00,$00 ;
  DEFB $00,$00,$7E,$00,$00,$00 ;

; Sprite for graphic 165
;
; 24 by 26 pixels.
SPRITE165:
  DEFB $03,$1A            ; Width in bytes, and height in rows
  DEFB $00,$00,$3C,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $01,$00,$FF,$3C,$80,$00 ; bottom row first
  DEFB $03,$01,$FF,$FF,$C0,$80 ;
  DEFB $07,$03,$FF,$FF,$E0,$C0 ;
  DEFB $0F,$07,$FF,$FF,$F0,$E0 ;
  DEFB $1F,$0E,$FF,$FF,$F8,$F0 ;
  DEFB $1F,$0C,$FF,$FF,$F8,$F0 ;
  DEFB $1F,$08,$FF,$FF,$F8,$F0 ;
  DEFB $1F,$08,$FF,$FF,$F8,$F0 ;
  DEFB $1F,$0C,$FF,$7F,$F8,$F0 ;
  DEFB $1F,$0C,$FF,$7F,$F8,$F0 ;
  DEFB $1F,$0E,$FF,$7F,$F8,$F0 ;
  DEFB $0F,$06,$FF,$3F,$F0,$E0 ;
  DEFB $0F,$07,$FF,$3F,$F0,$E0 ;
  DEFB $07,$03,$FF,$3F,$E0,$C0 ;
  DEFB $07,$03,$FF,$3F,$E0,$C0 ;
  DEFB $03,$01,$FF,$3F,$C0,$80 ;
  DEFB $03,$01,$FF,$3F,$C0,$80 ;
  DEFB $03,$01,$FF,$BF,$C0,$80 ;
  DEFB $03,$01,$FF,$BF,$C0,$80 ;
  DEFB $01,$00,$FF,$9F,$80,$00 ;
  DEFB $01,$00,$FF,$DF,$80,$00 ;
  DEFB $01,$00,$FF,$DF,$80,$00 ;
  DEFB $00,$00,$FF,$7E,$00,$00 ;
  DEFB $00,$00,$7E,$3C,$00,$00 ;
  DEFB $00,$00,$3C,$00,$00,$00 ;

; Sprite for graphics 160, 162
;
; 32 by 23 pixels.
SPRITE160:
  DEFB $04,$17            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell,
  DEFB $00,$00,$00,$00,$04,$00,$00,$00 ; the bottom row first
  DEFB $00,$00,$00,$00,$0E,$04,$00,$00 ;
  DEFB $00,$00,$00,$00,$1E,$0C,$00,$00 ;
  DEFB $00,$00,$00,$00,$1E,$0C,$00,$00 ;
  DEFB $00,$00,$00,$00,$3E,$1C,$04,$00 ;
  DEFB $00,$00,$00,$00,$3E,$1C,$0E,$04 ;
  DEFB $00,$00,$07,$00,$7C,$38,$1E,$0C ;
  DEFB $00,$00,$3F,$07,$FC,$78,$7C,$18 ;
  DEFB $40,$00,$FF,$3E,$FB,$F0,$FC,$78 ;
  DEFB $F9,$40,$FF,$FF,$FF,$6B,$F8,$F0 ;
  DEFB $FF,$78,$FF,$7F,$FF,$9B,$F0,$E0 ;
  DEFB $7F,$3F,$FF,$BF,$FF,$FD,$E2,$80 ;
  DEFB $3F,$1F,$FF,$BF,$FF,$FE,$DF,$02 ;
  DEFB $1F,$03,$FF,$7F,$FF,$FF,$FF,$DE ;
  DEFB $4F,$04,$FF,$FF,$FF,$FF,$FE,$DC ;
  DEFB $FF,$43,$FF,$FF,$FF,$FF,$FC,$D0 ;
  DEFB $FF,$7D,$FF,$FF,$FF,$FF,$D0,$80 ;
  DEFB $7F,$3E,$FF,$FF,$FF,$FF,$80,$00 ;
  DEFB $3F,$1F,$FF,$3F,$FF,$FC,$00,$00 ;
  DEFB $1F,$00,$FF,$87,$FC,$E0,$00,$00 ;
  DEFB $01,$00,$FF,$F8,$E0,$00,$00,$00 ;
  DEFB $00,$00,$F8,$00,$00,$00,$00,$00 ;

; Sprite for graphic 161
;
; 32 by 23 pixels.
SPRITE161:
  DEFB $04,$17            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$10,$00,$00,$00 ; Mask and image bytes, a pair per cell,
  DEFB $00,$00,$00,$00,$38,$10,$00,$00 ; the bottom row first
  DEFB $00,$00,$00,$00,$38,$10,$00,$00 ;
  DEFB $00,$00,$00,$00,$3C,$18,$00,$00 ;
  DEFB $00,$00,$00,$00,$3C,$18,$00,$00 ;
  DEFB $00,$00,$00,$00,$7C,$38,$00,$00 ;
  DEFB $00,$00,$00,$00,$7C,$38,$00,$00 ;
  DEFB $00,$00,$07,$00,$FC,$78,$06,$00 ;
  DEFB $40,$00,$3F,$07,$F8,$70,$1F,$06 ;
  DEFB $F0,$40,$FF,$3E,$FB,$F0,$FE,$1C ;
  DEFB $FF,$70,$FF,$FF,$FF,$6B,$FE,$FC ;
  DEFB $7F,$3E,$FF,$7F,$FF,$9B,$FC,$F8 ;
  DEFB $3F,$1F,$FF,$BF,$FF,$FD,$FE,$E4 ;
  DEFB $1F,$0F,$FF,$BF,$FF,$FE,$FE,$0C ;
  DEFB $0F,$03,$FF,$7F,$FF,$FF,$FC,$D8 ;
  DEFB $0F,$04,$FF,$FF,$FF,$FF,$FC,$D8 ;
  DEFB $0F,$03,$FF,$FF,$FF,$FF,$F8,$D0 ;
  DEFB $7F,$0D,$FF,$FF,$FF,$FF,$D0,$00 ;
  DEFB $FF,$7E,$FF,$FF,$FF,$FF,$80,$00 ;
  DEFB $7F,$0F,$FF,$3F,$FF,$FC,$00,$00 ;
  DEFB $0F,$00,$FF,$C7,$FC,$E0,$00,$00 ;
  DEFB $00,$00,$FF,$38,$E0,$00,$00,$00 ;
  DEFB $00,$00,$38,$00,$00,$00,$00,$00 ;

; Sprite for graphic 163
;
; 32 by 23 pixels.
SPRITE163:
  DEFB $04,$17            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell,
  DEFB $00,$00,$00,$00,$01,$00,$00,$00 ; the bottom row first
  DEFB $00,$00,$00,$00,$03,$01,$88,$00 ;
  DEFB $00,$00,$00,$00,$07,$03,$9C,$08 ;
  DEFB $00,$00,$00,$00,$0F,$07,$BC,$18 ;
  DEFB $00,$00,$00,$00,$1F,$0E,$3C,$18 ;
  DEFB $00,$00,$07,$00,$7F,$1E,$7C,$38 ;
  DEFB $00,$00,$3F,$07,$FF,$7C,$FC,$78 ;
  DEFB $00,$00,$FF,$3E,$FF,$F9,$F8,$F0 ;
  DEFB $41,$00,$FF,$FF,$FF,$73,$F0,$E0 ;
  DEFB $FF,$40,$FF,$7F,$FF,$8B,$E0,$C0 ;
  DEFB $FF,$7F,$FF,$BF,$FF,$FD,$C0,$80 ;
  DEFB $7F,$3F,$FF,$BF,$FF,$FE,$D2,$00 ;
  DEFB $7F,$0F,$FF,$7F,$FF,$FF,$FF,$D2 ;
  DEFB $FF,$40,$FF,$FF,$FF,$FF,$FF,$DE ;
  DEFB $FF,$73,$FF,$FF,$FF,$FF,$FF,$DC ;
  DEFB $7F,$3D,$FF,$FF,$FF,$FF,$DC,$80 ;
  DEFB $3F,$1E,$FF,$FF,$FF,$FF,$80,$00 ;
  DEFB $1F,$07,$FF,$3F,$FF,$FC,$00,$00 ;
  DEFB $07,$00,$FF,$C7,$FC,$E0,$00,$00 ;
  DEFB $03,$01,$FF,$F8,$E0,$00,$00,$00 ;
  DEFB $01,$00,$F8,$E0,$00,$00,$00,$00 ;
  DEFB $00,$00,$E0,$00,$00,$00,$00,$00 ;

; Sprite for graphics 48, 50
;
; 24 by 26 pixels.
SPRITE48:
  DEFB $03,$1A            ; Width in bytes, and height in rows
  DEFB $00,$00,$06,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$0F,$06,$00,$00 ; bottom row first
  DEFB $00,$00,$1F,$0E,$00,$00 ;
  DEFB $00,$00,$3E,$1C,$00,$00 ;
  DEFB $00,$00,$3E,$1C,$04,$00 ;
  DEFB $00,$00,$3F,$1E,$0E,$04 ;
  DEFB $00,$00,$7F,$3E,$0E,$04 ;
  DEFB $20,$00,$FF,$7E,$1F,$0A ;
  DEFB $71,$20,$FF,$FF,$9F,$0A ;
  DEFB $71,$20,$FF,$FF,$9F,$0A ;
  DEFB $71,$20,$FF,$FF,$9F,$0A ;
  DEFB $79,$30,$FF,$FF,$BF,$12 ;
  DEFB $79,$30,$FF,$FF,$FF,$32 ;
  DEFB $7D,$38,$FF,$FF,$FF,$F2 ;
  DEFB $7D,$38,$FF,$FF,$FF,$F2 ;
  DEFB $7F,$3C,$FF,$FB,$FF,$F2 ;
  DEFB $7F,$3F,$FF,$D3,$FF,$F2 ;
  DEFB $7F,$3F,$FF,$91,$FF,$FA ;
  DEFB $7F,$3F,$FF,$91,$FF,$FA ;
  DEFB $7F,$3F,$FF,$91,$FF,$BE ;
  DEFB $7F,$3F,$FF,$93,$BF,$0E ;
  DEFB $7F,$3E,$FF,$9B,$8E,$00 ;
  DEFB $7F,$3C,$FF,$FF,$80,$00 ;
  DEFB $7D,$3C,$FF,$7E,$00,$00 ;
  DEFB $3C,$18,$7E,$3C,$00,$00 ;
  DEFB $18,$00,$3C,$00,$00,$00 ;

; Sprite for graphics 49, 51
;
; 24 by 26 pixels.
SPRITE49:
  DEFB $03,$1A            ; Width in bytes, and height in rows
  DEFB $00,$00,$10,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$38,$10,$00,$00 ; bottom row first
  DEFB $00,$00,$7C,$38,$00,$00 ;
  DEFB $00,$00,$3E,$1C,$04,$00 ;
  DEFB $00,$00,$1F,$0E,$0E,$04 ;
  DEFB $00,$00,$1F,$0E,$0E,$04 ;
  DEFB $20,$00,$3F,$1E,$1F,$0A ;
  DEFB $70,$20,$7F,$3E,$1F,$0A ;
  DEFB $70,$20,$FF,$7E,$1F,$0A ;
  DEFB $71,$20,$FF,$FF,$9F,$0A ;
  DEFB $79,$30,$FF,$FF,$BF,$1A ;
  DEFB $79,$30,$FF,$FF,$FF,$32 ;
  DEFB $7D,$38,$FF,$FF,$FF,$72 ;
  DEFB $7D,$38,$FF,$FF,$FF,$F2 ;
  DEFB $7F,$3C,$FF,$FF,$FF,$F2 ;
  DEFB $7F,$3E,$FF,$FB,$FF,$F2 ;
  DEFB $7F,$3F,$FF,$D3,$FF,$F2 ;
  DEFB $7F,$3F,$FF,$91,$FF,$FA ;
  DEFB $7F,$3F,$FF,$91,$FF,$FA ;
  DEFB $7F,$3F,$FF,$91,$FF,$0E ;
  DEFB $7F,$3F,$FF,$93,$8E,$00 ;
  DEFB $7F,$3E,$FF,$9B,$80,$00 ;
  DEFB $7F,$3C,$FF,$FF,$80,$00 ;
  DEFB $3C,$18,$FF,$7E,$00,$00 ;
  DEFB $18,$00,$7E,$3C,$00,$00 ;
  DEFB $00,$00,$3C,$00,$00,$00 ;

; Sprite for graphic 64
;
; 16 by 14 pixels.
SPRITE64:
  DEFB $02,$0E            ; Width in bytes, and height in rows
  DEFB $03,$00,$E0,$00    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $07,$03,$F0,$E0    ; row first
  DEFB $0F,$07,$FC,$F0    ;
  DEFB $1F,$07,$FE,$EC    ;
  DEFB $3F,$1F,$FF,$FE    ;
  DEFB $7F,$3F,$FF,$FE    ;
  DEFB $7F,$3D,$FF,$9E    ;
  DEFB $3F,$1E,$FE,$5C    ;
  DEFB $7F,$3F,$FF,$DE    ;
  DEFB $7F,$3D,$FF,$E6    ;
  DEFB $3F,$1B,$FF,$FE    ;
  DEFB $1B,$01,$FE,$DC    ;
  DEFB $01,$00,$FC,$C0    ;
  DEFB $00,$00,$C0,$00    ;

; Sprite for graphics 65, 67
;
; 24 by 13 pixels.
SPRITE65:
  DEFB $03,$0D            ; Width in bytes, and height in rows
  DEFB $00,$00,$FC,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $01,$00,$FF,$FC,$C0,$00 ; bottom row first
  DEFB $3B,$01,$FF,$FB,$E0,$C0 ;
  DEFB $7F,$3B,$FF,$FF,$F0,$E0 ;
  DEFB $FF,$7F,$FF,$FF,$F8,$F0 ;
  DEFB $FF,$7F,$FF,$FB,$F8,$F0 ;
  DEFB $FF,$7D,$FF,$E5,$F0,$C0 ;
  DEFB $FF,$7E,$FF,$1D,$F8,$F0 ;
  DEFB $7F,$3F,$FF,$FE,$FC,$78 ;
  DEFB $3F,$07,$FF,$FF,$FC,$F8 ;
  DEFB $1F,$0F,$FF,$FB,$F8,$F0 ;
  DEFB $0F,$06,$FB,$F0,$F0,$E0 ;
  DEFB $06,$00,$F0,$00,$E0,$00 ;

; Sprite for graphics 66, 68-69
;
; 24 by 17 pixels.
SPRITE66:
  DEFB $03,$11            ; Width in bytes, and height in rows
  DEFB $01,$00,$F8,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $07,$01,$FF,$F8,$00,$00 ; bottom row first
  DEFB $0F,$07,$FF,$FF,$BC,$00 ;
  DEFB $1F,$0F,$FF,$FF,$FE,$BC ;
  DEFB $3F,$0F,$FF,$FF,$FF,$FE ;
  DEFB $7F,$3F,$FF,$FF,$FF,$FE ;
  DEFB $FF,$7F,$FF,$7C,$FF,$FE ;
  DEFB $FF,$7F,$FF,$81,$FF,$FE ;
  DEFB $FF,$7F,$FF,$C1,$FE,$FC ;
  DEFB $FF,$7D,$FF,$80,$FC,$78 ;
  DEFB $7F,$3D,$FF,$E3,$FE,$FC ;
  DEFB $FF,$7D,$FF,$F7,$FF,$FE ;
  DEFB $FF,$63,$FF,$FF,$FF,$FE ;
  DEFB $FF,$7F,$FF,$FF,$FF,$FE ;
  DEFB $7F,$3B,$FF,$FD,$FE,$FC ;
  DEFB $3B,$01,$FD,$F0,$FC,$F0 ;
  DEFB $01,$00,$F0,$00,$F0,$00 ;

; Sprite for graphics 70-71
;
; 24 by 16 pixels.
SPRITE70:
  DEFB $03,$10            ; Width in bytes, and height in rows
  DEFB $3F,$00,$00,$00,$F8,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $7F,$3F,$81,$00,$FC,$F8 ; bottom row first
  DEFB $FF,$7F,$C3,$81,$FE,$FC ;
  DEFB $FF,$7E,$81,$00,$FC,$38 ;
  DEFB $7E,$3C,$00,$00,$38,$00 ;
  DEFB $3C,$00,$00,$00,$0C,$00 ;
  DEFB $00,$00,$00,$00,$1E,$0C ;
  DEFB $00,$00,$00,$00,$3F,$1E ;
  DEFB $18,$00,$00,$00,$3F,$1E ;
  DEFB $3C,$18,$00,$00,$3F,$1E ;
  DEFB $7E,$3C,$00,$00,$3F,$1E ;
  DEFB $7E,$2C,$3C,$00,$1E,$04 ;
  DEFB $7E,$24,$7E,$3C,$1C,$08 ;
  DEFB $7E,$3C,$7F,$3E,$08,$00 ;
  DEFB $3C,$18,$3E,$1C,$00,$00 ;
  DEFB $18,$00,$1C,$00,$00,$00 ;

; Sprite for graphic 149
;
; 16 by 16 pixels.
SPRITE149:
  DEFB $02,$10            ; Width in bytes, and height in rows
  DEFB $08,$00,$00,$00    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $1C,$08,$40,$00    ; row first
  DEFB $3E,$1C,$E4,$40    ;
  DEFB $3F,$08,$4E,$04    ;
  DEFB $7F,$27,$DF,$0E    ;
  DEFB $3F,$0B,$FE,$C4    ;
  DEFB $3F,$1C,$F4,$A0    ;
  DEFB $5F,$0D,$FC,$B0    ;
  DEFB $FF,$5A,$FE,$54    ;
  DEFB $5F,$05,$FC,$F0    ;
  DEFB $0F,$01,$FC,$A8    ;
  DEFB $1F,$09,$F8,$40    ;
  DEFB $19,$00,$50,$00    ;
  DEFB $39,$10,$38,$10    ;
  DEFB $3F,$19,$90,$00    ;
  DEFB $19,$00,$00,$00    ;

; Sprite for graphic 150
;
; 16 by 16 pixels.
SPRITE150:
  DEFB $02,$10            ; Width in bytes, and height in rows
  DEFB $08,$00,$00,$00    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $1C,$08,$20,$00    ; row first
  DEFB $09,$00,$70,$20    ;
  DEFB $23,$01,$A8,$00    ;
  DEFB $73,$20,$BC,$08    ;
  DEFB $7F,$33,$F8,$A0    ;
  DEFB $3F,$06,$E2,$C0    ;
  DEFB $1F,$0D,$FF,$62    ;
  DEFB $4F,$06,$FA,$F0    ;
  DEFB $FF,$4A,$F8,$E0    ;
  DEFB $4F,$03,$FC,$88    ;
  DEFB $0F,$03,$FE,$5C    ;
  DEFB $1F,$09,$DC,$88    ;
  DEFB $3F,$1C,$C8,$00    ;
  DEFB $1C,$08,$E0,$40    ;
  DEFB $08,$00,$40,$00    ;

; Sprite for graphic 151
;
; 16 by 16 pixels.
SPRITE151:
  DEFB $02,$10            ; Width in bytes, and height in rows
  DEFB $08,$00,$40,$00    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $1C,$08,$E8,$40    ; row first
  DEFB $0B,$00,$FC,$68    ;
  DEFB $07,$03,$F8,$00    ;
  DEFB $27,$01,$FA,$D0    ;
  DEFB $7F,$27,$FF,$BA    ;
  DEFB $3F,$05,$FA,$D0    ;
  DEFB $3F,$0F,$FC,$B0    ;
  DEFB $7F,$32,$FE,$D4    ;
  DEFB $7F,$33,$FC,$B0    ;
  DEFB $3F,$01,$F2,$60    ;
  DEFB $0F,$02,$FF,$32    ;
  DEFB $1F,$08,$FA,$80    ;
  DEFB $09,$00,$9C,$08    ;
  DEFB $03,$01,$88,$00    ;
  DEFB $01,$00,$00,$00    ;

; The font
;
; 43 characters of 8 bytes, the codes $30 to $5A. The print routine at
; PRINT_CHAR adds eight times the code to a base in FONT_BASE: for text, 384
; bytes below this one, so that code $30 lands here, and this address itself
; for the digits of the score and lives, so that 0-9 are codes 0-9. A space is
; printed as code $3D.
FONT:
  DEFB $38                ; Character 0
  DEFB $6C                ;
  DEFB $D6                ;
  DEFB $D6                ;
  DEFB $D6                ;
  DEFB $D6                ;
  DEFB $6C                ;
  DEFB $38                ;
  DEFB $18                ; Character 1
  DEFB $38                ;
  DEFB $58                ;
  DEFB $18                ;
  DEFB $18                ;
  DEFB $18                ;
  DEFB $18                ;
  DEFB $7C                ;
  DEFB $38                ; Character 2
  DEFB $4C                ;
  DEFB $0C                ;
  DEFB $3C                ;
  DEFB $60                ;
  DEFB $C2                ;
  DEFB $C2                ;
  DEFB $FE                ;
  DEFB $38                ; Character 3
  DEFB $4C                ;
  DEFB $0C                ;
  DEFB $3C                ;
  DEFB $0E                ;
  DEFB $86                ;
  DEFB $86                ;
  DEFB $FC                ;
  DEFB $18                ; Character 4
  DEFB $38                ;
  DEFB $58                ;
  DEFB $9A                ;
  DEFB $FE                ;
  DEFB $1A                ;
  DEFB $18                ;
  DEFB $7C                ;
  DEFB $FE                ; Character 5
  DEFB $C2                ;
  DEFB $C0                ;
  DEFB $FC                ;
  DEFB $06                ;
  DEFB $06                ;
  DEFB $86                ;
  DEFB $7C                ;
  DEFB $1E                ; Character 6
  DEFB $32                ;
  DEFB $60                ;
  DEFB $EC                ;
  DEFB $C6                ;
  DEFB $C6                ;
  DEFB $C6                ;
  DEFB $7C                ;
  DEFB $7E                ; Character 7
  DEFB $46                ;
  DEFB $4C                ;
  DEFB $0C                ;
  DEFB $18                ;
  DEFB $18                ;
  DEFB $38                ;
  DEFB $F8                ;
  DEFB $38                ; Character 8
  DEFB $6C                ;
  DEFB $6C                ;
  DEFB $7C                ;
  DEFB $FE                ;
  DEFB $C6                ;
  DEFB $C6                ;
  DEFB $7C                ;
  DEFB $7C                ; Character 9
  DEFB $C6                ;
  DEFB $C6                ;
  DEFB $C6                ;
  DEFB $7C                ;
  DEFB $0C                ;
  DEFB $98                ;
  DEFB $F0                ;
  DEFB $00                ; Character $3A
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $18                ;
  DEFB $18                ;
  DEFB $00                ; Character $3B
  DEFB $C3                ;
  DEFB $C6                ;
  DEFB $0C                ;
  DEFB $18                ;
  DEFB $30                ;
  DEFB $63                ;
  DEFB $C3                ;
  DEFB $3C                ; Character $3C
  DEFB $42                ;
  DEFB $99                ;
  DEFB $A1                ;
  DEFB $A1                ;
  DEFB $99                ;
  DEFB $42                ;
  DEFB $3C                ;
  DEFB $00                ; Character $3D
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ; Character $3E
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
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
  DEFB $0C                ; Character A
  DEFB $1C                ;
  DEFB $2E                ;
  DEFB $66                ;
  DEFB $46                ;
  DEFB $CE                ;
  DEFB $D6                ;
  DEFB $66                ;
  DEFB $F8                ; Character B
  DEFB $6C                ;
  DEFB $6C                ;
  DEFB $78                ;
  DEFB $6C                ;
  DEFB $66                ;
  DEFB $66                ;
  DEFB $FC                ;
  DEFB $0E                ; Character C
  DEFB $32                ;
  DEFB $60                ;
  DEFB $40                ;
  DEFB $C0                ;
  DEFB $C2                ;
  DEFB $E6                ;
  DEFB $7C                ;
  DEFB $60                ; Character D
  DEFB $70                ;
  DEFB $68                ;
  DEFB $6C                ;
  DEFB $66                ;
  DEFB $66                ;
  DEFB $66                ;
  DEFB $FC                ;
  DEFB $FE                ; Character E
  DEFB $60                ;
  DEFB $64                ;
  DEFB $7C                ;
  DEFB $64                ;
  DEFB $60                ;
  DEFB $7A                ;
  DEFB $C6                ;
  DEFB $C6                ; Character F
  DEFB $7A                ;
  DEFB $60                ;
  DEFB $64                ;
  DEFB $7C                ;
  DEFB $64                ;
  DEFB $60                ;
  DEFB $60                ;
  DEFB $0E                ; Character G
  DEFB $30                ;
  DEFB $60                ;
  DEFB $C6                ;
  DEFB $CE                ;
  DEFB $F6                ;
  DEFB $66                ;
  DEFB $0E                ;
  DEFB $EE                ; Character H
  DEFB $C6                ;
  DEFB $C6                ;
  DEFB $FE                ;
  DEFB $C6                ;
  DEFB $C6                ;
  DEFB $C6                ;
  DEFB $EE                ;
  DEFB $7C                ; Character I
  DEFB $18                ;
  DEFB $18                ;
  DEFB $18                ;
  DEFB $18                ;
  DEFB $18                ;
  DEFB $18                ;
  DEFB $7C                ;
  DEFB $1E                ; Character J
  DEFB $06                ;
  DEFB $06                ;
  DEFB $86                ;
  DEFB $86                ;
  DEFB $C6                ;
  DEFB $7E                ;
  DEFB $1C                ;
  DEFB $E4                ; Character K
  DEFB $68                ;
  DEFB $70                ;
  DEFB $78                ;
  DEFB $6C                ;
  DEFB $64                ;
  DEFB $64                ;
  DEFB $F6                ;
  DEFB $E0                ; Character L
  DEFB $60                ;
  DEFB $60                ;
  DEFB $60                ;
  DEFB $60                ;
  DEFB $60                ;
  DEFB $62                ;
  DEFB $FE                ;
  DEFB $C6                ; Character M
  DEFB $EE                ;
  DEFB $EE                ;
  DEFB $D6                ;
  DEFB $D6                ;
  DEFB $D6                ;
  DEFB $C6                ;
  DEFB $EE                ;
  DEFB $CC                ; Character N
  DEFB $D6                ;
  DEFB $D6                ;
  DEFB $E6                ;
  DEFB $E4                ;
  DEFB $C4                ;
  DEFB $C8                ;
  DEFB $DE                ;
  DEFB $38                ; Character O
  DEFB $6C                ;
  DEFB $C6                ;
  DEFB $C6                ;
  DEFB $C6                ;
  DEFB $C6                ;
  DEFB $6C                ;
  DEFB $38                ;
  DEFB $F8                ; Character P
  DEFB $6C                ;
  DEFB $66                ;
  DEFB $76                ;
  DEFB $6E                ;
  DEFB $60                ;
  DEFB $60                ;
  DEFB $F0                ;
  DEFB $38                ; Character Q
  DEFB $6C                ;
  DEFB $C6                ;
  DEFB $C6                ;
  DEFB $C6                ;
  DEFB $D6                ;
  DEFB $6C                ;
  DEFB $3A                ;
  DEFB $F8                ; Character R
  DEFB $6C                ;
  DEFB $66                ;
  DEFB $76                ;
  DEFB $7E                ;
  DEFB $78                ;
  DEFB $6C                ;
  DEFB $E6                ;
  DEFB $38                ; Character S
  DEFB $64                ;
  DEFB $60                ;
  DEFB $3C                ;
  DEFB $06                ;
  DEFB $86                ;
  DEFB $C6                ;
  DEFB $7C                ;
  DEFB $FE                ; Character T
  DEFB $9A                ;
  DEFB $98                ;
  DEFB $18                ;
  DEFB $18                ;
  DEFB $18                ;
  DEFB $18                ;
  DEFB $18                ;
  DEFB $F6                ; Character U
  DEFB $26                ;
  DEFB $46                ;
  DEFB $4E                ;
  DEFB $CE                ;
  DEFB $D6                ;
  DEFB $D6                ;
  DEFB $66                ;
  DEFB $E2                ; Character V
  DEFB $62                ;
  DEFB $64                ;
  DEFB $64                ;
  DEFB $68                ;
  DEFB $68                ;
  DEFB $70                ;
  DEFB $60                ;
  DEFB $EE                ; Character W
  DEFB $C6                ;
  DEFB $D6                ;
  DEFB $D6                ;
  DEFB $D6                ;
  DEFB $EE                ;
  DEFB $EE                ;
  DEFB $C6                ;
  DEFB $C6                ; Character X
  DEFB $C6                ;
  DEFB $6C                ;
  DEFB $38                ;
  DEFB $38                ;
  DEFB $6C                ;
  DEFB $C6                ;
  DEFB $C6                ;
  DEFB $86                ; Character Y
  DEFB $66                ;
  DEFB $16                ;
  DEFB $0E                ;
  DEFB $06                ;
  DEFB $04                ;
  DEFB $4C                ;
  DEFB $38                ;
  DEFB $7E                ; Character Z
  DEFB $46                ;
  DEFB $0C                ;
  DEFB $18                ;
  DEFB $30                ;
  DEFB $62                ;
  DEFB $C2                ;
  DEFB $FE                ;

; Sprite for graphics 16-17, 89
;
; 32 by 18 pixels.
SPRITE16:
  DEFB $04,$12            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$18,$00,$00,$00 ; Mask and image bytes, a pair per cell,
  DEFB $00,$00,$00,$00,$3C,$18,$00,$00 ; the bottom row first
  DEFB $00,$00,$30,$00,$3C,$18,$30,$00 ;
  DEFB $00,$00,$78,$30,$38,$10,$78,$30 ;
  DEFB $00,$00,$7C,$38,$78,$30,$78,$30 ;
  DEFB $18,$00,$3C,$18,$78,$30,$F0,$60 ;
  DEFB $3E,$18,$1E,$0C,$79,$30,$F0,$E0 ;
  DEFB $3F,$1E,$8F,$06,$79,$30,$E6,$C0 ;
  DEFB $1F,$07,$CF,$86,$7F,$31,$EF,$C6 ;
  DEFB $07,$01,$F7,$C3,$FF,$37,$DF,$8E ;
  DEFB $01,$00,$FF,$73,$FF,$17,$FE,$98 ;
  DEFB $01,$00,$FF,$3C,$FF,$E1,$F8,$B0 ;
  DEFB $03,$01,$FF,$9D,$FF,$AE,$F0,$60 ;
  DEFB $03,$01,$FF,$D9,$FF,$47,$F0,$E0 ;
  DEFB $01,$00,$FF,$60,$FF,$33,$E0,$C0 ;
  DEFB $00,$00,$7F,$1D,$FB,$B1,$C0,$80 ;
  DEFB $00,$00,$1F,$0D,$F1,$80,$80,$00 ;
  DEFB $00,$00,$0D,$00,$F8,$30,$00,$00 ;

; Unused
SPARE_SPRITEA:
  DEFB $00,$00,$00,$00,$30,$00,$00,$00

; Sprite no graphic number reaches
;
; 32 by 24 pixels.
SPARE_SPRITEB:
  DEFB $04,$18            ; Width in bytes, and height in rows
  DEFB $00,$00,$0F,$0B,$F0,$F0,$00,$00 ; Mask and image bytes, a pair per cell,
  DEFB $00,$00,$FF,$9D,$FF,$FB,$00,$00 ; the bottom row first
  DEFB $01,$01,$FF,$BD,$FF,$FB,$C0,$40 ;
  DEFB $07,$07,$FF,$BE,$FF,$FB,$E0,$60 ;
  DEFB $3F,$0F,$FF,$BE,$FF,$F7,$FC,$78 ;
  DEFB $3F,$17,$FF,$BD,$FF,$F7,$FC,$78 ;
  DEFB $3F,$17,$FF,$BD,$FF,$EF,$FC,$B8 ;
  DEFB $3F,$1B,$FF,$BB,$FF,$EF,$FC,$B8 ;
  DEFB $3F,$1D,$FF,$D9,$FF,$EF,$FC,$70 ;
  DEFB $3F,$1E,$FF,$EE,$FF,$EF,$F8,$B0 ;
  DEFB $3F,$0F,$FF,$76,$FF,$F7,$F8,$D0 ;
  DEFB $1F,$0F,$FF,$77,$FF,$77,$F8,$B0 ;
  DEFB $1F,$0E,$FF,$F7,$FF,$7B,$FE,$B0 ;
  DEFB $1F,$0D,$FF,$FF,$FF,$FB,$FE,$78 ;
  DEFB $1F,$0B,$FF,$F8,$FF,$1F,$FE,$7C ;
  DEFB $1F,$0F,$FF,$C7,$FF,$E3,$FC,$F8 ;
  DEFB $1F,$0F,$FF,$3B,$FF,$3C,$FC,$F8 ;
  DEFB $1F,$0E,$FF,$E3,$FF,$C6,$FC,$F0 ;
  DEFB $1F,$0E,$FF,$E3,$FF,$C6,$F8,$F0 ;
  DEFB $1F,$07,$FF,$3C,$FF,$3D,$F8,$E0 ;
  DEFB $0F,$03,$FF,$C7,$FF,$E3,$F0,$C0 ;
  DEFB $07,$00,$FF,$F8,$FF,$1F,$E0,$00 ;
  DEFB $01,$00,$FF,$0F,$FF,$F0,$80,$00 ;
  DEFB $00,$00,$1F,$00,$F8,$00,$00,$00 ;

; Sprite for graphics 63, 82
;
; 32 by 28 pixels.
SPRITE63:
  DEFB $04,$1C            ; Width in bytes, and height in rows
  DEFB $00,$00,$03,$00,$C0,$00,$00,$00 ; Mask and image bytes, a pair per cell,
  DEFB $00,$00,$0F,$01,$F0,$80,$00,$00 ; the bottom row first
  DEFB $00,$00,$3F,$07,$FC,$E0,$00,$00 ;
  DEFB $00,$00,$FF,$1B,$FF,$D8,$00,$00 ;
  DEFB $03,$00,$FF,$7B,$FF,$DE,$C0,$00 ;
  DEFB $0F,$01,$FF,$FB,$FF,$DF,$F0,$80 ;
  DEFB $1F,$07,$FF,$FB,$FF,$DF,$F8,$E0 ;
  DEFB $1F,$0F,$FF,$FB,$FF,$DF,$F8,$F0 ;
  DEFB $1F,$0F,$FF,$FB,$FF,$DF,$F8,$F0 ;
  DEFB $1F,$0F,$FF,$FB,$FF,$DF,$F8,$F0 ;
  DEFB $1F,$0F,$FF,$FB,$FF,$DF,$F8,$F0 ;
  DEFB $1F,$0F,$FF,$FB,$FF,$DF,$F8,$F0 ;
  DEFB $1F,$0F,$FF,$FF,$FF,$FF,$F8,$F0 ;
  DEFB $1F,$0F,$FF,$F8,$FF,$1F,$F8,$F0 ;
  DEFB $1F,$0F,$FF,$E7,$FF,$E7,$F8,$F0 ;
  DEFB $1F,$0F,$FF,$9F,$FF,$F9,$F8,$F0 ;
  DEFB $1F,$0E,$FF,$7F,$FF,$FE,$F8,$70 ;
  DEFB $1F,$09,$FF,$FF,$FF,$FF,$F8,$90 ;
  DEFB $1F,$07,$FF,$FF,$FF,$FF,$F8,$E0 ;
  DEFB $1F,$0F,$FF,$FF,$FF,$FF,$F8,$F0 ;
  DEFB $1F,$0F,$FF,$FF,$FF,$FF,$F8,$F0 ;
  DEFB $1F,$0F,$FF,$FF,$FF,$FF,$F8,$F0 ;
  DEFB $1F,$07,$FF,$FF,$FF,$FF,$F8,$E0 ;
  DEFB $0F,$01,$FF,$FF,$FF,$FF,$F0,$80 ;
  DEFB $03,$00,$FF,$7F,$FF,$FE,$C0,$00 ;
  DEFB $00,$00,$FF,$1F,$FF,$F8,$00,$00 ;
  DEFB $00,$00,$3F,$07,$FC,$E0,$00,$00 ;
  DEFB $00,$00,$0F,$00,$F0,$00,$00,$00 ;

; Sprite for graphics 30-31
;
; 32 by 21 pixels.
SPRITE30:
  DEFB $04,$15            ; Width in bytes, and height in rows
  DEFB $00,$00,$1E,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell,
  DEFB $00,$00,$FF,$1E,$E1,$00,$80,$00 ; the bottom row first
  DEFB $07,$00,$FF,$FF,$F3,$E1,$C0,$80 ;
  DEFB $0F,$07,$FF,$FF,$FF,$F3,$E0,$C0 ;
  DEFB $1F,$0F,$FF,$B6,$FF,$8B,$F0,$E0 ;
  DEFB $3F,$1D,$BF,$12,$FF,$3D,$F0,$E0 ;
  DEFB $7F,$35,$93,$00,$FF,$C6,$E0,$C0 ;
  DEFB $7F,$34,$0F,$03,$FF,$3F,$E0,$40 ;
  DEFB $7C,$30,$3F,$0C,$FF,$FE,$F0,$E0 ;
  DEFB $78,$30,$FF,$33,$FE,$F8,$F0,$60 ;
  DEFB $79,$30,$FF,$CF,$F8,$E0,$F8,$50 ;
  DEFB $7F,$39,$FF,$3F,$E0,$80,$F8,$70 ;
  DEFB $7F,$2E,$FF,$FE,$80,$00,$F0,$60 ;
  DEFB $3F,$0B,$FE,$F8,$01,$00,$F0,$E0 ;
  DEFB $0F,$03,$F8,$E0,$07,$01,$F0,$E0 ;
  DEFB $03,$01,$FF,$D8,$FF,$07,$F0,$A0 ;
  DEFB $01,$00,$DF,$0F,$FF,$FF,$E0,$80 ;
  DEFB $00,$00,$1F,$0D,$FF,$FD,$C0,$80 ;
  DEFB $00,$00,$1F,$09,$FF,$D9,$80,$00 ;
  DEFB $00,$00,$09,$00,$DD,$88,$00,$00 ;
  DEFB $00,$00,$00,$00,$88,$00,$00,$00 ;

; Sprite for graphics 23, 28
;
; 32 by 28 pixels.
SPRITE23:
  DEFB $04,$1C            ; Width in bytes, and height in rows
  DEFB $00,$00,$01,$00,$80,$00,$00,$00 ; Mask and image bytes, a pair per cell,
  DEFB $00,$00,$07,$01,$E0,$80,$00,$00 ; the bottom row first
  DEFB $00,$00,$1F,$07,$F8,$E0,$00,$00 ;
  DEFB $00,$00,$7F,$1E,$FE,$78,$00,$00 ;
  DEFB $01,$00,$FF,$79,$FF,$9E,$80,$00 ;
  DEFB $07,$01,$FF,$E7,$FF,$E7,$E0,$80 ;
  DEFB $1F,$07,$FF,$9D,$FF,$F9,$F8,$E0 ;
  DEFB $7E,$1F,$FF,$7D,$FF,$BE,$FE,$78 ;
  DEFB $FF,$79,$FF,$ED,$FF,$AD,$FF,$9E ;
  DEFB $FF,$67,$FF,$6D,$FF,$AD,$FF,$E6 ;
  DEFB $FF,$1F,$FF,$6D,$FF,$AD,$FF,$F8 ;
  DEFB $FF,$7F,$FF,$AD,$FF,$6B,$FF,$FE ;
  DEFB $FF,$5D,$FF,$AD,$FF,$6B,$FF,$BA ;
  DEFB $7F,$1D,$FF,$DD,$FF,$6B,$FE,$B8 ;
  DEFB $1F,$0D,$FF,$FD,$FF,$77,$F8,$B8 ;
  DEFB $1F,$0D,$FF,$6E,$FF,$FE,$F8,$B8 ;
  DEFB $1F,$0D,$FF,$6F,$FF,$FC,$F8,$B0 ;
  DEFB $1D,$08,$FF,$6D,$FF,$B6,$F8,$30 ;
  DEFB $1C,$08,$FF,$6D,$FF,$B6,$38,$10 ;
  DEFB $1C,$08,$FF,$65,$FF,$A6,$3B,$10 ;
  DEFB $1C,$08,$E7,$41,$EF,$86,$38,$10 ;
  DEFB $1C,$08,$E3,$41,$C7,$82,$10,$00 ;
  DEFB $08,$00,$E1,$40,$C7,$82,$00,$00 ;
  DEFB $00,$00,$E1,$40,$C7,$82,$00,$00 ;
  DEFB $00,$00,$41,$00,$C2,$80,$00,$00 ;
  DEFB $00,$00,$01,$00,$C0,$80,$00,$00 ;
  DEFB $00,$00,$01,$00,$C0,$80,$00,$00 ;
  DEFB $00,$00,$00,$00,$80,$00,$00,$00 ;

; Sprite for graphic 22
;
; 16 by 17 pixels.
SPRITE22:
  DEFB $02,$11            ; Width in bytes, and height in rows
  DEFB $0E,$00,$38,$00    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $1F,$0E,$7C,$38    ; row first
  DEFB $1F,$0B,$FC,$78    ;
  DEFB $0F,$05,$F8,$70    ;
  DEFB $0E,$03,$F0,$60    ;
  DEFB $0F,$03,$F8,$E0    ;
  DEFB $1F,$0D,$FC,$F8    ;
  DEFB $1F,$0D,$FC,$F8    ;
  DEFB $1F,$0D,$FC,$F8    ;
  DEFB $1F,$0D,$FC,$F8    ;
  DEFB $1F,$0E,$FC,$38    ;
  DEFB $0F,$05,$F8,$D0    ;
  DEFB $07,$02,$F0,$E0    ;
  DEFB $07,$02,$F0,$E0    ;
  DEFB $07,$02,$F0,$E0    ;
  DEFB $03,$01,$E0,$40    ;
  DEFB $01,$00,$C0,$00    ;

; Sprite for graphics 11, 78-79, 84-85, 87-88, 91, 121-127, 136, 140-143
;
; 32 by 29 pixels.
SPRITE11:
  DEFB $04,$1D            ; Width in bytes, and height in rows
  DEFB $00,$00,$01,$00,$80,$00,$00,$00 ; Mask and image bytes, a pair per cell,
  DEFB $00,$00,$1F,$01,$E0,$80,$00,$00 ; the bottom row first
  DEFB $00,$00,$3F,$1E,$F0,$40,$00,$00 ;
  DEFB $00,$00,$7F,$3E,$F8,$A0,$00,$00 ;
  DEFB $00,$00,$FF,$7E,$FF,$50,$80,$00 ;
  DEFB $07,$00,$FF,$FE,$FF,$A2,$E0,$80 ;
  DEFB $0F,$06,$FF,$3E,$FF,$55,$F0,$40 ;
  DEFB $7F,$0F,$FF,$DE,$FF,$AA,$FE,$A0 ;
  DEFB $FF,$7F,$FF,$DE,$FF,$15,$FF,$54 ;
  DEFB $FF,$7F,$FF,$DE,$FF,$AA,$FF,$A2 ;
  DEFB $FF,$7F,$FF,$CE,$FF,$54,$FF,$54 ;
  DEFB $FF,$7F,$FF,$EE,$FF,$28,$FF,$82 ;
  DEFB $FF,$73,$FF,$E8,$FF,$94,$FF,$54 ;
  DEFB $FF,$0D,$FF,$F7,$FF,$CA,$FF,$A2 ;
  DEFB $FF,$7D,$FF,$EF,$FF,$E4,$FF,$54 ;
  DEFB $FF,$7D,$FF,$1F,$FF,$FC,$FF,$A2 ;
  DEFB $FF,$7C,$FF,$FF,$FF,$FE,$FF,$04 ;
  DEFB $FF,$79,$FF,$FF,$FF,$FF,$FF,$E2 ;
  DEFB $FF,$43,$FF,$FF,$FF,$FF,$FF,$F4 ;
  DEFB $FF,$1F,$FF,$FF,$FF,$FF,$FF,$F8 ;
  DEFB $FF,$7F,$FF,$FF,$FF,$FF,$FF,$FE ;
  DEFB $7F,$1F,$FF,$FF,$FF,$FF,$FE,$F8 ;
  DEFB $1F,$0F,$FF,$FF,$FF,$FF,$F8,$E0 ;
  DEFB $0F,$03,$FF,$FF,$FF,$FF,$E0,$C0 ;
  DEFB $03,$00,$FF,$7F,$FF,$F8,$C0,$00 ;
  DEFB $00,$00,$7F,$3F,$F8,$F0,$00,$00 ;
  DEFB $00,$00,$3F,$1F,$F0,$E0,$00,$00 ;
  DEFB $00,$00,$1F,$07,$E0,$C0,$00,$00 ;
  DEFB $00,$00,$07,$00,$C0,$00,$00,$00 ;

; Sprite for graphic 58
;
; 16 by 16 pixels.
SPRITE58:
  DEFB $02,$10            ; Width in bytes, and height in rows
  DEFB $0D,$0D,$F5,$F5    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $13,$13,$80,$80    ; row first
  DEFB $1E,$1E,$00,$00    ;
  DEFB $0B,$0B,$E0,$E0    ;
  DEFB $1E,$1E,$18,$18    ;
  DEFB $16,$16,$06,$06    ;
  DEFB $1B,$1B,$80,$80    ;
  DEFB $1E,$1E,$00,$00    ;
  DEFB $0E,$0E,$00,$00    ;
  DEFB $0F,$0F,$D0,$D0    ;
  DEFB $0F,$0F,$00,$00    ;
  DEFB $07,$07,$80,$80    ;
  DEFB $07,$07,$EC,$EC    ;
  DEFB $00,$00,$78,$78    ;
  DEFB $00,$00,$0C,$0C    ;
  DEFB $00,$00,$03,$03    ;

; Sprite for graphic 59
;
; 16 by 11 pixels.
SPRITE59:
  DEFB $02,$0B            ; Width in bytes, and height in rows
  DEFB $18,$18,$7E,$7E    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $07,$07,$80,$80    ; row first
  DEFB $00,$00,$40,$40    ;
  DEFB $00,$00,$30,$30    ;
  DEFB $00,$00,$08,$08    ;
  DEFB $00,$00,$04,$04    ;
  DEFB $18,$18,$06,$06    ;
  DEFB $07,$07,$F8,$F8    ;
  DEFB $C0,$C0,$10,$10    ;
  DEFB $38,$38,$0E,$0E    ;
  DEFB $07,$07,$FE,$FE    ;

; Sprite no graphic number reaches
;
; 16 by 16 pixels.
SPARE_SPRITEC:
  DEFB $02,$10            ; Width in bytes, and height in rows
  DEFB $FF,$FF,$FE,$FE    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $07,$07,$00,$00    ; row first
  DEFB $00,$00,$78,$78    ;
  DEFB $00,$00,$06,$06    ;
  DEFB $0E,$0E,$06,$06    ;
  DEFB $31,$31,$C1,$C1    ;
  DEFB $6C,$6C,$F1,$F1    ;
  DEFB $31,$31,$9E,$9E    ;
  DEFB $0E,$0E,$60,$60    ;
  DEFB $01,$01,$80,$80    ;
  DEFB $00,$00,$80,$80    ;
  DEFB $00,$00,$7E,$7E    ;
  DEFB $00,$00,$02,$02    ;
  DEFB $00,$00,$04,$04    ;
  DEFB $00,$00,$3C,$3C    ;
  DEFB $00,$00,$02,$02    ;

; Sprite for graphics 60-61
;
; 16 by 16 pixels.
SPRITE60:
  DEFB $02,$10            ; Width in bytes, and height in rows
  DEFB $FF,$FF,$F0,$F0    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $08,$08,$00,$00    ; row first
  DEFB $07,$07,$F8,$F8    ;
  DEFB $00,$00,$04,$04    ;
  DEFB $00,$00,$08,$08    ;
  DEFB $03,$03,$E4,$E4    ;
  DEFB $04,$04,$1C,$1C    ;
  DEFB $79,$79,$E6,$E6    ;
  DEFB $86,$86,$60,$60    ;
  DEFB $79,$79,$9E,$9E    ;
  DEFB $06,$06,$21,$21    ;
  DEFB $01,$01,$C3,$C3    ;
  DEFB $00,$00,$1C,$1C    ;
  DEFB $00,$00,$C0,$C0    ;
  DEFB $00,$00,$3E,$3E    ;
  DEFB $00,$00,$06,$06    ;

; Sprite for graphic 62
;
; 16 by 8 pixels.
SPRITE62:
  DEFB $02,$08            ; Width in bytes, and height in rows
  DEFB $C0,$C0,$00,$00    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $7F,$7F,$C0,$C0    ; row first
  DEFB $1C,$1C,$00,$00    ;
  DEFB $03,$03,$00,$00    ;
  DEFB $00,$00,$CE,$CE    ;
  DEFB $00,$00,$78,$78    ;
  DEFB $00,$00,$04,$04    ;
  DEFB $00,$00,$03,$03    ;

; Sprite for graphic 73
;
; 40 by 34 pixels.
SPRITE73:
  DEFB $05,$22            ; Width in bytes, and height in rows
  DEFB $00,$00,$01,$00,$80,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair
  DEFB $00,$00,$03,$01,$C0,$80,$00,$00,$00,$00 ; per cell, the bottom row first
  DEFB $00,$00,$07,$02,$E0,$C0,$00,$00,$00,$00 ;
  DEFB $00,$00,$07,$02,$E0,$C0,$00,$00,$00,$00 ;
  DEFB $00,$00,$07,$02,$E0,$C0,$00,$00,$00,$00 ;
  DEFB $00,$00,$07,$02,$E0,$C0,$00,$00,$00,$00 ;
  DEFB $0C,$00,$07,$02,$E0,$C0,$00,$00,$00,$00 ;
  DEFB $1E,$0C,$07,$02,$E0,$C0,$00,$00,$00,$00 ;
  DEFB $3F,$16,$07,$02,$E0,$C0,$00,$00,$00,$00 ;
  DEFB $3F,$16,$07,$02,$E0,$C0,$00,$00,$00,$00 ;
  DEFB $3F,$16,$07,$02,$E0,$C0,$00,$00,$30,$00 ;
  DEFB $3F,$16,$0F,$00,$E0,$20,$00,$00,$78,$30 ;
  DEFB $3F,$16,$1F,$0F,$E0,$80,$00,$00,$FC,$58 ;
  DEFB $3F,$16,$FF,$1E,$F8,$60,$00,$00,$FC,$58 ;
  DEFB $3F,$16,$FF,$D9,$FE,$98,$00,$00,$FC,$58 ;
  DEFB $3F,$15,$FF,$E7,$FF,$E6,$80,$00,$FC,$58 ;
  DEFB $3F,$03,$FF,$9F,$FF,$F9,$E0,$80,$FC,$58 ;
  DEFB $7F,$3E,$FF,$67,$FF,$FE,$F8,$60,$FC,$58 ;
  DEFB $FF,$79,$FF,$F9,$FF,$FF,$FE,$98,$FC,$58 ;
  DEFB $FF,$66,$FF,$7E,$FF,$7F,$FF,$E6,$FC,$58 ;
  DEFB $FF,$5F,$FF,$9F,$FF,$9F,$FF,$F9,$FC,$98 ;
  DEFB $FF,$7F,$FF,$E7,$FF,$E7,$FF,$FE,$FC,$60 ;
  DEFB $7F,$1F,$FF,$F9,$FF,$F9,$FF,$FF,$FE,$98 ;
  DEFB $1F,$07,$FF,$FE,$FF,$7E,$FF,$7F,$FF,$E6 ;
  DEFB $07,$01,$FF,$FF,$FF,$9F,$FF,$9F,$FF,$F8 ;
  DEFB $01,$00,$FF,$7F,$FF,$E7,$FF,$E7,$FF,$FE ;
  DEFB $00,$00,$7F,$1F,$FF,$F9,$FF,$F9,$FE,$F8 ;
  DEFB $00,$00,$1F,$07,$FF,$FE,$FF,$7E,$F8,$60 ;
  DEFB $00,$00,$07,$01,$FF,$FF,$FF,$9F,$E0,$80 ;
  DEFB $00,$00,$01,$00,$FF,$7F,$FF,$F6,$80,$00 ;
  DEFB $00,$00,$00,$00,$7F,$1F,$FE,$F8,$00,$00 ;
  DEFB $00,$00,$00,$00,$1F,$07,$F8,$E0,$00,$00 ;
  DEFB $00,$00,$00,$00,$07,$01,$E0,$80,$00,$00 ;
  DEFB $00,$00,$00,$00,$01,$00,$80,$00,$00,$00 ;

; Sprite for graphic 120
;
; 40 by 32 pixels.
SPRITE120:
  DEFB $05,$20            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$FF,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair
  DEFB $00,$00,$03,$00,$FF,$FC,$F0,$00,$00,$00 ; per cell, the bottom row first
  DEFB $00,$00,$3F,$03,$FF,$FC,$FC,$F0,$00,$00 ;
  DEFB $00,$00,$FF,$3B,$FF,$FE,$FF,$FC,$00,$00 ;
  DEFB $01,$00,$FF,$FB,$FF,$FE,$FF,$FE,$80,$00 ;
  DEFB $07,$00,$FF,$FB,$FF,$E0,$FF,$7E,$C0,$80 ;
  DEFB $0F,$04,$FF,$F9,$FF,$CE,$FF,$3D,$E0,$C0 ;
  DEFB $1F,$0E,$FF,$F0,$FF,$1F,$FF,$85,$F0,$E0 ;
  DEFB $1F,$0E,$FF,$E1,$FF,$CF,$FF,$B9,$F8,$F0 ;
  DEFB $1F,$0E,$FF,$4F,$FF,$83,$FF,$BE,$F8,$F0 ;
  DEFB $1F,$0E,$FF,$1F,$FF,$79,$FF,$9E,$F8,$30 ;
  DEFB $1F,$0E,$FF,$1E,$FF,$7C,$FF,$06,$F8,$D0 ;
  DEFB $1F,$0C,$FF,$D9,$FF,$3D,$FF,$F2,$F8,$E0 ;
  DEFB $1F,$0B,$FF,$C7,$FF,$7E,$FF,$F8,$F8,$F0 ;
  DEFB $1F,$07,$FF,$1E,$FF,$7F,$FF,$7C,$F8,$30 ;
  DEFB $1F,$0E,$FF,$7E,$FF,$40,$FF,$7E,$F8,$D0 ;
  DEFB $1F,$08,$FF,$F1,$FF,$3F,$FF,$06,$F8,$60 ;
  DEFB $1F,$06,$FF,$4F,$FF,$DF,$FF,$78,$F8,$30 ;
  DEFB $1F,$0E,$FF,$3F,$FF,$3E,$FF,$FF,$F8,$10 ;
  DEFB $1F,$0D,$FF,$9C,$FF,$00,$FF,$38,$F8,$D0 ;
  DEFB $1F,$0B,$FF,$C0,$FF,$00,$FF,$07,$F8,$E0 ;
  DEFB $1F,$07,$FF,$F1,$FF,$00,$FF,$03,$F8,$F0 ;
  DEFB $1F,$0F,$FF,$E0,$FF,$00,$FF,$01,$F8,$F0 ;
  DEFB $1F,$0F,$FF,$C0,$FF,$04,$FF,$01,$F8,$F0 ;
  DEFB $1F,$00,$FF,$21,$FF,$01,$FF,$00,$F0,$00 ;
  DEFB $0F,$07,$FF,$F0,$FF,$00,$FF,$03,$F0,$C0 ;
  DEFB $0F,$07,$FF,$E9,$FF,$44,$FF,$0F,$E0,$C0 ;
  DEFB $07,$03,$FF,$DF,$FF,$01,$FF,$67,$C0,$80 ;
  DEFB $03,$00,$FF,$BE,$FF,$7D,$FF,$F2,$80,$00 ;
  DEFB $00,$00,$FF,$0E,$FF,$FD,$FE,$F8,$00,$00 ;
  DEFB $00,$00,$0F,$00,$FF,$FE,$F8,$E0,$00,$00 ;
  DEFB $00,$00,$00,$00,$FF,$00,$E0,$00,$00,$00 ;

; Sprite for graphics 112-115
;
; 32 by 39 pixels.
SPRITE112:
  DEFB $04,$27            ; Width in bytes, and height in rows
  DEFB $00,$00,$01,$00,$80,$00,$00,$00 ; Mask and image bytes, a pair per cell,
  DEFB $00,$00,$03,$01,$E0,$00,$00,$00 ; the bottom row first
  DEFB $00,$00,$0F,$02,$F8,$A0,$00,$00 ;
  DEFB $00,$00,$3F,$0E,$FE,$50,$00,$00 ;
  DEFB $00,$00,$FF,$3C,$FF,$AA,$80,$00 ;
  DEFB $03,$00,$FF,$FF,$FF,$55,$E0,$00 ;
  DEFB $0F,$03,$FF,$FE,$FF,$A8,$F8,$A0 ;
  DEFB $1F,$0F,$FF,$F5,$FF,$55,$FE,$50 ;
  DEFB $3F,$1F,$FF,$F2,$FF,$A8,$FF,$AA ;
  DEFB $7F,$3F,$FF,$F9,$FF,$54,$FF,$54 ;
  DEFB $3F,$1F,$FF,$FA,$FF,$A2,$FE,$28 ;
  DEFB $3F,$1F,$FF,$FD,$FF,$51,$FE,$54 ;
  DEFB $3F,$1F,$FF,$FC,$FF,$AA,$FC,$A8 ;
  DEFB $3F,$1F,$FF,$FE,$FF,$51,$FC,$50 ;
  DEFB $1F,$07,$FF,$FE,$FF,$AA,$F8,$A0 ;
  DEFB $0F,$07,$FF,$FD,$FF,$55,$F8,$50 ;
  DEFB $07,$01,$FF,$FC,$FF,$AA,$F0,$A0 ;
  DEFB $07,$02,$FF,$FD,$FF,$55,$F0,$40 ;
  DEFB $07,$03,$FF,$7E,$FF,$8A,$F0,$A0 ;
  DEFB $0F,$07,$FF,$7D,$FF,$55,$F0,$40 ;
  DEFB $0F,$07,$FF,$BC,$FF,$AA,$E0,$A0 ;
  DEFB $0F,$07,$FF,$BC,$FF,$54,$80,$00 ;
  DEFB $07,$01,$FF,$DC,$FF,$AA,$00,$00 ;
  DEFB $07,$03,$FF,$EE,$FF,$54,$00,$00 ;
  DEFB $07,$03,$FF,$DE,$FF,$8A,$00,$00 ;
  DEFB $03,$01,$FF,$EF,$FF,$45,$80,$00 ;
  DEFB $03,$01,$FF,$FF,$FF,$2A,$00,$00 ;
  DEFB $03,$01,$FF,$FE,$FF,$55,$80,$00 ;
  DEFB $01,$00,$FF,$FE,$FF,$AA,$00,$00 ;
  DEFB $00,$00,$FF,$7E,$FE,$14,$00,$00 ;
  DEFB $00,$00,$7F,$38,$FE,$C8,$00,$00 ;
  DEFB $00,$00,$3F,$16,$FE,$E4,$00,$00 ;
  DEFB $00,$00,$3F,$0E,$FE,$F8,$00,$00 ;
  DEFB $00,$00,$3F,$1F,$FE,$7C,$00,$00 ;
  DEFB $00,$00,$1F,$07,$FC,$70,$00,$00 ;
  DEFB $00,$00,$07,$01,$F0,$60,$00,$00 ;
  DEFB $00,$00,$01,$00,$E0,$C0,$00,$00 ;
  DEFB $00,$00,$01,$00,$C0,$80,$00,$00 ;
  DEFB $00,$00,$00,$00,$80,$00,$00,$00 ;

; Sprite for graphics 116-119
;
; 32 by 51 pixels.
SPRITE116:
  DEFB $04,$33            ; Width in bytes, and height in rows
  DEFB $00,$00,$01,$00,$80,$00,$00,$00 ; Mask and image bytes, a pair per cell,
  DEFB $00,$00,$07,$01,$E0,$80,$00,$00 ; the bottom row first
  DEFB $00,$00,$1F,$07,$F8,$20,$00,$00 ;
  DEFB $00,$00,$7F,$1F,$FE,$50,$00,$00 ;
  DEFB $01,$00,$FF,$7F,$FF,$2A,$80,$00 ;
  DEFB $07,$01,$FF,$FF,$FF,$55,$E0,$00 ;
  DEFB $1F,$07,$FF,$FF,$FF,$2A,$F1,$A0 ;
  DEFB $7F,$1F,$FF,$FF,$FF,$55,$FE,$50 ;
  DEFB $FF,$7F,$FF,$FF,$FF,$2A,$FF,$AA ;
  DEFB $FF,$7F,$FF,$FF,$FF,$55,$FF,$54 ;
  DEFB $FF,$7F,$FF,$FF,$FF,$2A,$FF,$AA ;
  DEFB $FF,$7F,$FF,$FF,$FF,$55,$FF,$54 ;
  DEFB $FF,$7F,$FF,$FF,$FF,$2A,$FF,$AA ;
  DEFB $7F,$3F,$FF,$FF,$FF,$55,$FE,$54 ;
  DEFB $7F,$3F,$FF,$FF,$FF,$2A,$FE,$A8 ;
  DEFB $7F,$3F,$FF,$FF,$FF,$55,$FE,$54 ;
  DEFB $7F,$3F,$FF,$FF,$FF,$2A,$FE,$A8 ;
  DEFB $7F,$3F,$FF,$FF,$FF,$55,$FE,$54 ;
  DEFB $3F,$1F,$FF,$FF,$FF,$2A,$FC,$A8 ;
  DEFB $3F,$1F,$FF,$FF,$FF,$55,$FC,$50 ;
  DEFB $3F,$1F,$FF,$FF,$FF,$2A,$FC,$A8 ;
  DEFB $3F,$1F,$FF,$FF,$FF,$55,$FC,$50 ;
  DEFB $3F,$1F,$FF,$FF,$FF,$2A,$FC,$A8 ;
  DEFB $1F,$0F,$FF,$FF,$FF,$55,$F8,$50 ;
  DEFB $1F,$0F,$FF,$FF,$FF,$2A,$F8,$A0 ;
  DEFB $1F,$0F,$FF,$FF,$FF,$55,$F8,$50 ;
  DEFB $1F,$0F,$FF,$FF,$FF,$2A,$F8,$A0 ;
  DEFB $1F,$0F,$FF,$FF,$FF,$55,$F8,$50 ;
  DEFB $0F,$07,$FF,$FF,$FF,$2A,$F0,$A0 ;
  DEFB $0F,$07,$FF,$FF,$FF,$55,$F0,$40 ;
  DEFB $0F,$07,$FF,$FF,$FF,$2A,$F0,$A0 ;
  DEFB $0F,$07,$FF,$FF,$FF,$55,$F0,$40 ;
  DEFB $0F,$07,$FF,$FF,$FF,$2A,$F0,$A0 ;
  DEFB $07,$03,$FF,$FF,$FF,$55,$E0,$40 ;
  DEFB $07,$03,$FF,$FF,$FF,$2A,$E0,$80 ;
  DEFB $07,$03,$FF,$FF,$FF,$55,$E0,$40 ;
  DEFB $07,$03,$FF,$FF,$FF,$2A,$E0,$80 ;
  DEFB $07,$03,$FF,$FE,$FF,$55,$E0,$40 ;
  DEFB $03,$01,$FF,$F8,$FF,$8A,$C0,$80 ;
  DEFB $03,$01,$FF,$E3,$FF,$E5,$C0,$00 ;
  DEFB $03,$01,$FF,$9E,$FF,$F8,$C0,$80 ;
  DEFB $03,$00,$FF,$7E,$FF,$FE,$80,$00 ;
  DEFB $01,$00,$FF,$FE,$FF,$FF,$80,$00 ;
  DEFB $00,$00,$FF,$7E,$FF,$FE,$00,$00 ;
  DEFB $00,$00,$7F,$3E,$FE,$FC,$00,$00 ;
  DEFB $00,$00,$3F,$1E,$FC,$F8,$00,$00 ;
  DEFB $00,$00,$1F,$0E,$F8,$F0,$00,$00 ;
  DEFB $00,$00,$0F,$06,$F0,$E0,$00,$00 ;
  DEFB $00,$00,$07,$02,$E0,$C0,$00,$00 ;
  DEFB $00,$00,$03,$01,$C0,$80,$00,$00 ;
  DEFB $00,$00,$01,$00,$80,$00,$00,$00 ;

; Sprite for graphic 90
;
; 24 by 24 pixels.
SPRITE90:
  DEFB $03,$18            ; Width in bytes, and height in rows
  DEFB $00,$00,$7E,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $01,$00,$FF,$76,$80,$00 ; bottom row first
  DEFB $03,$01,$FF,$76,$C0,$80 ;
  DEFB $07,$03,$FF,$00,$E0,$C0 ;
  DEFB $0F,$04,$FF,$F7,$F0,$20 ;
  DEFB $0F,$02,$FF,$F7,$F0,$40 ;
  DEFB $1F,$0E,$FF,$F7,$F8,$70 ;
  DEFB $1F,$0D,$FF,$F7,$F8,$70 ;
  DEFB $1F,$0D,$FF,$F7,$F8,$F0 ;
  DEFB $3F,$1D,$FF,$F7,$FC,$B8 ;
  DEFB $3F,$1D,$FF,$00,$FC,$B8 ;
  DEFB $3F,$18,$FF,$FF,$FC,$18 ;
  DEFB $7F,$27,$FF,$00,$FE,$E4 ;
  DEFB $7F,$18,$FF,$10,$FE,$18 ;
  DEFB $FF,$62,$FF,$10,$FF,$46 ;
  DEFB $7F,$22,$FF,$10,$FE,$44 ;
  DEFB $7F,$3A,$FF,$10,$FE,$5C ;
  DEFB $3F,$17,$FF,$10,$FC,$F8 ;
  DEFB $3F,$10,$FF,$FF,$FC,$08 ;
  DEFB $1F,$08,$FF,$00,$F8,$10 ;
  DEFB $0F,$06,$FF,$00,$F0,$60 ;
  DEFB $07,$01,$FF,$81,$E0,$80 ;
  DEFB $01,$00,$FF,$7E,$80,$00 ;
  DEFB $00,$00,$7E,$00,$00,$00 ;

; Sprite for graphics 144, 152
;
; 24 by 24 pixels.
SPRITE144:
  DEFB $03,$18            ; Width in bytes, and height in rows
  DEFB $03,$00,$E0,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $03,$01,$FF,$E0,$F0,$00 ; bottom row first
  DEFB $3F,$03,$FF,$FF,$F8,$F0 ;
  DEFB $7F,$3E,$FF,$1F,$FC,$F8 ;
  DEFB $FF,$7D,$FF,$E0,$FE,$04 ;
  DEFB $FF,$43,$FF,$FF,$FF,$F9 ;
  DEFB $FF,$3F,$FF,$CF,$FF,$F9 ;
  DEFB $FF,$7F,$FF,$87,$FF,$FC ;
  DEFB $FF,$7F,$FF,$C3,$FF,$FE ;
  DEFB $FF,$7F,$FF,$E3,$FF,$FE ;
  DEFB $7F,$3F,$FF,$E3,$FF,$FE ;
  DEFB $7F,$1F,$FF,$C6,$FF,$1E ;
  DEFB $7F,$3D,$FF,$80,$FF,$0E ;
  DEFB $7F,$38,$FF,$00,$FE,$DC ;
  DEFB $3F,$1C,$FF,$33,$FE,$FC ;
  DEFB $3F,$0F,$FF,$E3,$FC,$F8 ;
  DEFB $3F,$1F,$FF,$E3,$F8,$F0 ;
  DEFB $3F,$1F,$FF,$E1,$F0,$E0 ;
  DEFB $1F,$0F,$FF,$F1,$F0,$E0 ;
  DEFB $0F,$03,$FF,$FB,$E0,$C0 ;
  DEFB $03,$00,$FF,$FF,$C0,$00 ;
  DEFB $00,$00,$FF,$1C,$00,$00 ;
  DEFB $00,$00,$1C,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00 ;

; Sprite for graphics 145, 153
;
; 24 by 24 pixels.
SPRITE145:
  DEFB $03,$18            ; Width in bytes, and height in rows
  DEFB $00,$00,$07,$00,$C0,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$7F,$0F,$E0,$C0 ; bottom row first
  DEFB $00,$00,$FF,$7F,$F8,$E0 ;
  DEFB $01,$00,$FF,$F8,$FC,$38 ;
  DEFB $07,$01,$FF,$87,$FE,$DC ;
  DEFB $1F,$07,$FF,$7F,$FE,$E4 ;
  DEFB $3F,$1E,$FF,$F8,$FF,$FA ;
  DEFB $7F,$39,$FF,$E0,$FF,$3C ;
  DEFB $7F,$27,$FF,$C0,$FF,$1E ;
  DEFB $FF,$5F,$FF,$87,$FF,$07 ;
  DEFB $FF,$3F,$FF,$8F,$FF,$C6 ;
  DEFB $FF,$7F,$FF,$8F,$FF,$E6 ;
  DEFB $FF,$70,$FF,$07,$FF,$E6 ;
  DEFB $FF,$60,$FF,$03,$FF,$C6 ;
  DEFB $FF,$77,$FF,$C0,$FF,$06 ;
  DEFB $FF,$7F,$FF,$F8,$FF,$0E ;
  DEFB $FF,$7F,$FF,$FC,$FE,$7C ;
  DEFB $7F,$3F,$FF,$FC,$FE,$7C ;
  DEFB $3F,$1F,$FF,$F0,$FC,$F8 ;
  DEFB $1F,$07,$FF,$FC,$F8,$F0 ;
  DEFB $07,$01,$FF,$FF,$F0,$E0 ;
  DEFB $01,$00,$FF,$FF,$E0,$C0 ;
  DEFB $00,$00,$FF,$0F,$C0,$80 ;
  DEFB $00,$00,$0F,$00,$80,$00 ;

; Sprite for graphics 146, 154
;
; 24 by 24 pixels.
SPRITE146:
  DEFB $03,$18            ; Width in bytes, and height in rows
  DEFB $0F,$00,$F0,$00,$C0,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $1F,$0F,$FF,$F0,$F0,$C0 ; bottom row first
  DEFB $3F,$1F,$FF,$FF,$F8,$F0 ;
  DEFB $7F,$30,$FF,$0F,$FC,$38 ;
  DEFB $7F,$2F,$FF,$F0,$FE,$CC ;
  DEFB $FF,$5F,$FF,$FF,$FE,$F4 ;
  DEFB $FF,$5F,$FF,$FF,$FF,$FA ;
  DEFB $FF,$5F,$FF,$FF,$FF,$FE ;
  DEFB $FF,$3F,$FF,$CF,$FF,$FC ;
  DEFB $FF,$7B,$FF,$C3,$FF,$FE ;
  DEFB $FF,$60,$FF,$80,$FF,$FE ;
  DEFB $FF,$78,$FF,$18,$FF,$3E ;
  DEFB $FF,$7E,$FF,$1E,$FF,$0E ;
  DEFB $7F,$3E,$FF,$30,$FF,$06 ;
  DEFB $3F,$1C,$FF,$00,$FF,$FE ;
  DEFB $3F,$18,$FF,$08,$FF,$3E ;
  DEFB $3F,$18,$FF,$FE,$FF,$1E ;
  DEFB $7F,$3F,$FF,$FF,$FE,$B8 ;
  DEFB $7F,$3F,$FF,$FF,$F8,$F0 ;
  DEFB $3F,$1F,$FF,$FF,$F8,$F0 ;
  DEFB $1F,$07,$FF,$FF,$F8,$F0 ;
  DEFB $07,$01,$FF,$F3,$F0,$E0 ;
  DEFB $01,$00,$F3,$01,$E0,$C0 ;
  DEFB $00,$00,$01,$00,$C0,$00 ;

; Sprite for graphics 147, 155
;
; 24 by 24 pixels.
SPRITE147:
  DEFB $03,$18            ; Width in bytes, and height in rows
  DEFB $00,$00,$FC,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $03,$00,$FF,$FC,$00,$00 ; bottom row first
  DEFB $07,$03,$FF,$FF,$F8,$00 ;
  DEFB $0F,$07,$FF,$03,$FC,$F8 ;
  DEFB $3F,$0C,$FF,$FC,$FE,$FC ;
  DEFB $7F,$3B,$FF,$FF,$FF,$06 ;
  DEFB $7F,$37,$FF,$DF,$FF,$FA ;
  DEFB $FF,$4F,$FF,$8F,$FF,$FC ;
  DEFB $FF,$7F,$FF,$8F,$FF,$FE ;
  DEFB $FF,$3F,$FF,$8F,$FF,$FE ;
  DEFB $FF,$7F,$FF,$CF,$FF,$FE ;
  DEFB $FF,$77,$FF,$C7,$FF,$E6 ;
  DEFB $FF,$61,$FF,$C1,$FF,$82 ;
  DEFB $FF,$38,$FF,$80,$F0,$06 ;
  DEFB $FF,$7C,$FF,$06,$FF,$1E ;
  DEFB $FF,$78,$FF,$0F,$FE,$FC ;
  DEFB $7F,$30,$FF,$06,$FE,$FC ;
  DEFB $7F,$38,$FF,$21,$FE,$FC ;
  DEFB $3F,$1C,$FF,$77,$FC,$F0 ;
  DEFB $3F,$1F,$FF,$FF,$F0,$E0 ;
  DEFB $1F,$0F,$FF,$FF,$E0,$C0 ;
  DEFB $0F,$01,$FF,$FF,$C0,$80 ;
  DEFB $01,$00,$FF,$FC,$80,$00 ;
  DEFB $00,$00,$FC,$00,$00,$00 ;

; Sprite for graphics 148, 156
;
; 24 by 24 pixels.
SPRITE148:
  DEFB $03,$18            ; Width in bytes, and height in rows
  DEFB $07,$00,$F8,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $0F,$07,$FC,$F8,$00,$00 ; bottom row first
  DEFB $1F,$0F,$FF,$FC,$F0,$00 ;
  DEFB $3F,$18,$FF,$07,$F8,$F0 ;
  DEFB $3F,$17,$FF,$FB,$FC,$F8 ;
  DEFB $7F,$2F,$FF,$FC,$FE,$1C ;
  DEFB $FF,$6F,$FF,$FF,$FE,$E4 ;
  DEFB $FF,$5C,$FF,$FF,$FE,$F8 ;
  DEFB $FF,$3C,$FF,$3F,$FE,$FC ;
  DEFB $FF,$7C,$FF,$0F,$FF,$FA ;
  DEFB $FF,$7C,$FF,$03,$FF,$FE ;
  DEFB $FF,$7C,$FF,$30,$FF,$FC ;
  DEFB $FF,$7E,$FF,$7C,$FF,$3E ;
  DEFB $FF,$7E,$FF,$7C,$FF,$0E ;
  DEFB $7F,$3E,$FF,$38,$FF,$06 ;
  DEFB $7F,$3E,$FF,$00,$FF,$3E ;
  DEFB $3F,$1F,$FF,$01,$FF,$FE ;
  DEFB $3F,$1F,$FF,$1F,$FE,$FC ;
  DEFB $3F,$1F,$FF,$FF,$FC,$F8 ;
  DEFB $1F,$0F,$FF,$FF,$F8,$F0 ;
  DEFB $0F,$07,$FF,$FF,$F0,$E0 ;
  DEFB $07,$01,$FF,$FF,$E0,$C0 ;
  DEFB $01,$00,$FF,$39,$C0,$80 ;
  DEFB $00,$00,$39,$00,$80,$00 ;

; Sprite for graphics 0-1, 24-27, 83, 94-111, 157-159
;
; Width and height both zero: FIND_SPRITE sees the zero and draws nothing.
SPRITE0:
  DEFB $00,$00            ; Width and height

; Sprite for graphic 42
;
; 24 by 27 pixels.
SPRITE42:
  DEFB $03,$1B            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$80,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$01,$00,$C0,$80 ; bottom row first
  DEFB $00,$00,$01,$00,$E0,$C0 ;
  DEFB $00,$00,$01,$00,$E0,$C0 ;
  DEFB $00,$00,$FD,$00,$F0,$E0 ;
  DEFB $0F,$00,$FF,$FD,$F4,$E0 ;
  DEFB $1F,$0F,$FF,$FB,$FE,$F4 ;
  DEFB $1F,$0F,$FF,$F7,$FF,$F6 ;
  DEFB $1F,$0F,$FF,$EF,$FF,$FA ;
  DEFB $1F,$0F,$FF,$F7,$FA,$E0 ;
  DEFB $1F,$0F,$FF,$F7,$E0,$80 ;
  DEFB $3F,$1F,$FF,$FF,$C0,$80 ;
  DEFB $3F,$1F,$FF,$FF,$E0,$C0 ;
  DEFB $7F,$30,$FF,$3F,$E0,$C0 ;
  DEFB $7F,$2F,$FF,$9F,$C0,$80 ;
  DEFB $3F,$0F,$FF,$EC,$80,$00 ;
  DEFB $1F,$0F,$FF,$F0,$00,$00 ;
  DEFB $3F,$1F,$FF,$FB,$80,$00 ;
  DEFB $3F,$1E,$FF,$1D,$80,$00 ;
  DEFB $3F,$1C,$FF,$FE,$00,$00 ;
  DEFB $3F,$19,$FF,$FE,$00,$00 ;
  DEFB $3F,$1B,$FE,$FC,$00,$00 ;
  DEFB $3F,$1B,$FC,$F0,$00,$00 ;
  DEFB $7F,$3F,$F0,$80,$00,$00 ;
  DEFB $7F,$3C,$80,$00,$00,$00 ;
  DEFB $FC,$70,$00,$00,$00,$00 ;
  DEFB $70,$00,$00,$00,$00,$00 ;

; Sprite for graphics 41, 43
;
; 24 by 27 pixels.
SPRITE41:
  DEFB $03,$1B            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$00,$00,$10,$00 ; bottom row first
  DEFB $00,$00,$00,$00,$38,$10 ;
  DEFB $00,$00,$00,$00,$38,$10 ;
  DEFB $00,$00,$FE,$00,$F8,$30 ;
  DEFB $0F,$00,$FF,$FE,$F8,$F0 ;
  DEFB $1F,$0F,$FF,$FD,$F8,$F0 ;
  DEFB $3F,$0F,$FF,$FD,$FC,$F8 ;
  DEFB $7F,$2F,$FF,$FD,$FE,$F8 ;
  DEFB $7F,$2F,$FF,$FD,$FF,$FA ;
  DEFB $7F,$2F,$FF,$F7,$FF,$9A ;
  DEFB $3F,$1F,$FF,$FF,$DF,$86 ;
  DEFB $3F,$1F,$FF,$FF,$C6,$80 ;
  DEFB $7F,$30,$FF,$3F,$C0,$80 ;
  DEFB $7F,$2F,$FF,$9F,$80,$00 ;
  DEFB $3F,$0F,$FF,$EC,$00,$00 ;
  DEFB $1F,$0F,$FF,$F0,$00,$00 ;
  DEFB $3F,$1F,$FF,$FB,$80,$00 ;
  DEFB $3F,$1E,$FF,$1D,$80,$00 ;
  DEFB $3F,$1C,$FF,$FE,$00,$00 ;
  DEFB $3F,$19,$FF,$FE,$00,$00 ;
  DEFB $3F,$1B,$FE,$FC,$00,$00 ;
  DEFB $3F,$1B,$FC,$F0,$00,$00 ;
  DEFB $7F,$3F,$F0,$80,$00,$00 ;
  DEFB $7F,$3C,$80,$00,$00,$00 ;
  DEFB $FC,$70,$00,$00,$00,$00 ;
  DEFB $70,$00,$00,$00,$00,$00 ;

; Sprite for graphic 40
;
; 24 by 27 pixels.
SPRITE40:
  DEFB $03,$1B            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$00,$00,$00,$00 ; bottom row first
  DEFB $00,$00,$00,$00,$08,$00 ;
  DEFB $00,$00,$00,$00,$1C,$08 ;
  DEFB $00,$00,$FF,$00,$3C,$18 ;
  DEFB $4F,$00,$FF,$FF,$FC,$18 ;
  DEFB $FF,$4F,$FF,$FE,$FC,$F8 ;
  DEFB $FF,$6F,$FF,$FD,$FC,$F8 ;
  DEFB $FF,$6F,$FF,$FB,$FC,$F8 ;
  DEFB $FF,$6F,$FF,$FB,$FC,$F8 ;
  DEFB $FF,$6F,$FF,$F7,$FC,$F8 ;
  DEFB $FF,$5F,$FF,$FF,$FE,$D8 ;
  DEFB $FF,$5F,$FF,$FF,$FF,$DA ;
  DEFB $7F,$30,$FF,$3F,$FF,$CA ;
  DEFB $7F,$2F,$FF,$9F,$CF,$86 ;
  DEFB $3F,$0F,$FF,$EC,$86,$00 ;
  DEFB $1F,$0F,$FF,$F0,$00,$00 ;
  DEFB $3F,$1F,$FF,$FB,$80,$00 ;
  DEFB $3F,$1E,$FF,$1D,$80,$00 ;
  DEFB $3F,$1C,$FF,$FE,$00,$00 ;
  DEFB $3F,$19,$FF,$FE,$00,$00 ;
  DEFB $3F,$1B,$FE,$FC,$00,$00 ;
  DEFB $3F,$1B,$FC,$F0,$00,$00 ;
  DEFB $7F,$3F,$F0,$80,$00,$00 ;
  DEFB $7F,$3C,$80,$00,$00,$00 ;
  DEFB $FC,$70,$00,$00,$00,$00 ;
  DEFB $70,$00,$00,$00,$00,$00 ;

; Sprite for graphics 45, 47
;
; 24 by 34 pixels.
SPRITE45:
  DEFB $03,$22            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$00,$00,$00,$00 ; bottom row first
  DEFB $00,$00,$01,$00,$00,$00 ;
  DEFB $00,$00,$03,$02,$80,$00 ;
  DEFB $00,$00,$03,$01,$C0,$80 ;
  DEFB $00,$00,$07,$02,$C0,$80 ;
  DEFB $20,$00,$07,$02,$E0,$C0 ;
  DEFB $70,$20,$07,$02,$E0,$C0 ;
  DEFB $78,$30,$07,$02,$F0,$E0 ;
  DEFB $78,$30,$1F,$0A,$F0,$E0 ;
  DEFB $7C,$38,$FF,$16,$F0,$E0 ;
  DEFB $7F,$38,$FF,$F6,$F8,$F0 ;
  DEFB $7F,$3B,$FF,$D1,$F8,$F0 ;
  DEFB $7F,$3B,$FF,$AE,$FC,$78 ;
  DEFB $7F,$3B,$FF,$6E,$FC,$38 ;
  DEFB $3F,$1A,$FF,$F6,$FC,$78 ;
  DEFB $1F,$06,$FF,$F6,$F8,$F0 ;
  DEFB $1F,$0E,$FF,$FB,$F0,$E0 ;
  DEFB $1F,$0D,$FF,$FB,$E0,$C0 ;
  DEFB $1F,$0D,$FF,$99,$F0,$20 ;
  DEFB $0F,$02,$FF,$E0,$F0,$60 ;
  DEFB $07,$02,$FF,$68,$F0,$60 ;
  DEFB $07,$02,$FF,$98,$F0,$E0 ;
  DEFB $07,$02,$FF,$C1,$F0,$E0 ;
  DEFB $03,$01,$FF,$01,$F0,$E0 ;
  DEFB $01,$00,$FF,$CF,$F0,$E0 ;
  DEFB $00,$00,$FF,$78,$F0,$E0 ;
  DEFB $00,$00,$7F,$30,$F0,$60 ;
  DEFB $00,$00,$3F,$0F,$F0,$20 ;
  DEFB $00,$00,$0F,$07,$F8,$B0 ;
  DEFB $00,$00,$07,$01,$F8,$F0 ;
  DEFB $00,$00,$01,$00,$F8,$F0 ;
  DEFB $00,$00,$00,$00,$FC,$38 ;
  DEFB $00,$00,$00,$00,$38,$00 ;

; Sprite for graphic 44
;
; 24 by 34 pixels.
SPRITE44:
  DEFB $03,$22            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$00,$00,$00,$00 ; bottom row first
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$40,$00 ;
  DEFB $40,$00,$00,$00,$E0,$40 ;
  DEFB $E0,$40,$00,$00,$E0,$40 ;
  DEFB $E0,$40,$01,$00,$F0,$A0 ;
  DEFB $E0,$40,$01,$00,$F0,$A0 ;
  DEFB $F0,$60,$01,$00,$F8,$B0 ;
  DEFB $F0,$60,$0F,$0E,$F8,$B0 ;
  DEFB $FC,$70,$FF,$3E,$F8,$B0 ;
  DEFB $FF,$78,$FF,$FD,$FC,$B8 ;
  DEFB $FF,$7B,$FF,$DD,$FC,$F8 ;
  DEFB $FF,$7B,$FF,$AE,$FE,$FC ;
  DEFB $7F,$3B,$FF,$6E,$FE,$7C ;
  DEFB $3F,$1A,$FF,$F6,$FE,$FC ;
  DEFB $1F,$06,$FF,$F6,$FC,$F8 ;
  DEFB $1F,$0E,$FF,$FB,$F8,$E0 ;
  DEFB $1F,$0D,$FF,$FB,$E0,$C0 ;
  DEFB $1F,$0D,$FF,$99,$F0,$20 ;
  DEFB $0F,$02,$FF,$E0,$F0,$60 ;
  DEFB $07,$02,$FF,$68,$F0,$60 ;
  DEFB $07,$02,$FF,$98,$F0,$E0 ;
  DEFB $07,$02,$FF,$C1,$F0,$E0 ;
  DEFB $03,$01,$FF,$01,$F0,$E0 ;
  DEFB $01,$00,$FF,$CF,$F0,$E0 ;
  DEFB $00,$00,$FF,$78,$F0,$E0 ;
  DEFB $00,$00,$7F,$30,$F0,$60 ;
  DEFB $00,$00,$3F,$0F,$F0,$20 ;
  DEFB $00,$00,$0F,$07,$F8,$B0 ;
  DEFB $00,$00,$07,$01,$F8,$F0 ;
  DEFB $00,$00,$01,$00,$F8,$F0 ;
  DEFB $00,$00,$00,$00,$FC,$38 ;
  DEFB $00,$00,$00,$00,$38,$00 ;

; Sprite for graphic 46
;
; 24 by 34 pixels.
SPRITE46:
  DEFB $03,$22            ; Width in bytes, and height in rows
  DEFB $00,$00,$04,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$0E,$04,$00,$00 ; bottom row first
  DEFB $00,$00,$1F,$0A,$00,$00 ;
  DEFB $00,$00,$1F,$0A,$00,$00 ;
  DEFB $00,$00,$3F,$13,$80,$00 ;
  DEFB $00,$00,$3F,$13,$80,$00 ;
  DEFB $00,$00,$3F,$13,$C0,$80 ;
  DEFB $10,$00,$3F,$13,$C0,$80 ;
  DEFB $38,$10,$7F,$33,$E0,$C0 ;
  DEFB $38,$10,$7F,$33,$E0,$C0 ;
  DEFB $3C,$18,$FF,$0F,$F0,$E0 ;
  DEFB $3F,$18,$FF,$F3,$F0,$E0 ;
  DEFB $3F,$1B,$FF,$D1,$F8,$F0 ;
  DEFB $3F,$1B,$FF,$AE,$F8,$F0 ;
  DEFB $1F,$0B,$FF,$6E,$F8,$F0 ;
  DEFB $1F,$0A,$FF,$F6,$F8,$F0 ;
  DEFB $0F,$06,$FF,$F6,$F0,$E0 ;
  DEFB $1F,$0E,$FF,$FB,$F0,$E0 ;
  DEFB $1F,$0D,$FF,$FB,$E0,$C0 ;
  DEFB $1F,$0D,$FF,$99,$F0,$20 ;
  DEFB $0F,$02,$FF,$E0,$F0,$60 ;
  DEFB $07,$02,$FF,$68,$F0,$60 ;
  DEFB $07,$02,$FF,$98,$F0,$E0 ;
  DEFB $07,$02,$FF,$C1,$F0,$E0 ;
  DEFB $03,$01,$FF,$01,$F0,$E0 ;
  DEFB $01,$00,$FF,$CF,$F0,$E0 ;
  DEFB $00,$00,$FF,$78,$F0,$E0 ;
  DEFB $00,$00,$7F,$30,$F0,$60 ;
  DEFB $00,$00,$3F,$0F,$F0,$20 ;
  DEFB $00,$00,$0F,$07,$F8,$B0 ;
  DEFB $00,$00,$07,$01,$F8,$F0 ;
  DEFB $00,$00,$01,$00,$F8,$F0 ;
  DEFB $00,$00,$00,$00,$FC,$38 ;
  DEFB $00,$00,$00,$00,$38,$00 ;

; Sprite for graphic 34
;
; 24 by 15 pixels.
SPRITE34:
  DEFB $03,$0F            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$00,$00,$00,$00 ; bottom row first
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $70,$00,$00,$00,$00,$00 ;
  DEFB $FE,$70,$01,$00,$80,$00 ;
  DEFB $FF,$7E,$03,$01,$C0,$80 ;
  DEFB $7F,$3F,$87,$03,$E0,$C0 ;
  DEFB $7F,$21,$87,$03,$F0,$E0 ;
  DEFB $3F,$0E,$07,$00,$F8,$F0 ;
  DEFB $3F,$1F,$8F,$07,$FC,$38 ;
  DEFB $1F,$0F,$8F,$07,$FC,$98 ;
  DEFB $0F,$07,$FF,$8F,$F8,$C0 ;
  DEFB $0F,$07,$FF,$7F,$C0,$80 ;
  DEFB $1F,$0F,$FF,$FF,$80,$00 ;
  DEFB $1F,$0F,$03,$03,$80,$00 ;

; Sprite for graphics 21, 29, 33, 35
;
; 24 by 15 pixels.
SPRITE21:
  DEFB $03,$0F            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$00,$00,$00,$00 ; bottom row first
  DEFB $00,$00,$06,$00,$00,$00 ;
  DEFB $00,$00,$1F,$06,$80,$00 ;
  DEFB $0E,$00,$3F,$1F,$C0,$80 ;
  DEFB $1F,$0E,$BF,$17,$E0,$C0 ;
  DEFB $3F,$1F,$FF,$99,$E0,$C0 ;
  DEFB $3F,$19,$FF,$DE,$E0,$C0 ;
  DEFB $1F,$06,$FE,$D8,$C0,$00 ;
  DEFB $1F,$0F,$FF,$1E,$00,$00 ;
  DEFB $1F,$0F,$FF,$1E,$00,$00 ;
  DEFB $1F,$0F,$FF,$BE,$00,$00 ;
  DEFB $1F,$0F,$FF,$BF,$80,$00 ;
  DEFB $0F,$07,$FF,$FF,$80,$00 ;
  DEFB $0F,$07,$03,$03,$80,$00 ;

; Sprite for graphics 18, 20, 32
;
; 24 by 15 pixels.
SPRITE18:
  DEFB $03,$0F            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$70,$00,$00,$00 ; bottom row first
  DEFB $00,$00,$FC,$70,$00,$00 ;
  DEFB $01,$00,$FE,$FC,$00,$00 ;
  DEFB $01,$00,$FF,$CE,$00,$00 ;
  DEFB $03,$00,$FF,$77,$80,$00 ;
  DEFB $07,$03,$FF,$BA,$00,$00 ;
  DEFB $03,$01,$FE,$DC,$00,$00 ;
  DEFB $07,$02,$FF,$5E,$00,$00 ;
  DEFB $07,$03,$FF,$9F,$80,$00 ;
  DEFB $03,$01,$FF,$DE,$00,$00 ;
  DEFB $03,$01,$FF,$DE,$00,$00 ;
  DEFB $07,$03,$FF,$BF,$80,$00 ;
  DEFB $0F,$07,$FF,$FF,$C0,$80 ;
  DEFB $0F,$07,$03,$02,$80,$00 ;

; Sprite for graphics 19, 37, 39
;
; 24 by 18 pixels.
SPRITE19:
  DEFB $03,$12            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$00,$00,$00,$00 ; bottom row first
  DEFB $00,$00,$38,$00,$00,$00 ;
  DEFB $00,$00,$7E,$38,$00,$00 ;
  DEFB $06,$00,$7F,$3E,$00,$00 ;
  DEFB $0F,$06,$BF,$1F,$80,$00 ;
  DEFB $1F,$0F,$DF,$83,$80,$00 ;
  DEFB $0F,$07,$EF,$C5,$80,$00 ;
  DEFB $07,$02,$FF,$66,$00,$00 ;
  DEFB $03,$01,$FF,$8F,$80,$00 ;
  DEFB $03,$01,$FF,$CF,$80,$00 ;
  DEFB $07,$03,$FF,$EF,$80,$00 ;
  DEFB $07,$03,$FF,$DF,$80,$00 ;
  DEFB $07,$03,$FF,$CE,$00,$00 ;
  DEFB $07,$03,$FF,$F1,$80,$00 ;
  DEFB $07,$03,$F1,$C0,$00,$00 ;
  DEFB $07,$03,$C0,$00,$00,$00 ;
  DEFB $03,$00,$00,$00,$00,$00 ;

; Sprite for graphic 36
;
; 24 by 18 pixels.
SPRITE36:
  DEFB $03,$12            ; Width in bytes, and height in rows
  DEFB $00,$00,$40,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$E0,$40,$00,$00 ; bottom row first
  DEFB $01,$00,$F8,$E0,$00,$00 ;
  DEFB $01,$00,$FE,$F8,$00,$00 ;
  DEFB $00,$00,$FF,$7E,$00,$00 ;
  DEFB $00,$00,$7F,$26,$00,$00 ;
  DEFB $01,$00,$FF,$1A,$00,$00 ;
  DEFB $03,$01,$FE,$BC,$00,$00 ;
  DEFB $07,$03,$FE,$BC,$00,$00 ;
  DEFB $03,$01,$FE,$BC,$00,$00 ;
  DEFB $01,$00,$FF,$3E,$00,$00 ;
  DEFB $01,$00,$FF,$DE,$00,$00 ;
  DEFB $01,$00,$FF,$DF,$80,$00 ;
  DEFB $03,$01,$FF,$DE,$00,$00 ;
  DEFB $03,$01,$FE,$F0,$00,$00 ;
  DEFB $03,$01,$F0,$C0,$00,$00 ;
  DEFB $03,$01,$C0,$00,$00,$00 ;
  DEFB $01,$00,$00,$00,$00,$00 ;

; Sprite for graphic 38
;
; 24 by 18 pixels.
SPRITE38:
  DEFB $03,$12            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$00,$00,$00,$00 ; bottom row first
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $38,$00,$0C,$00,$00,$00 ;
  DEFB $7C,$38,$1E,$0C,$00,$00 ;
  DEFB $7F,$3C,$1F,$0E,$00,$00 ;
  DEFB $3F,$0F,$9F,$0F,$80,$00 ;
  DEFB $0F,$07,$CF,$85,$C0,$80 ;
  DEFB $07,$02,$87,$04,$E0,$C0 ;
  DEFB $03,$01,$CF,$87,$E0,$40 ;
  DEFB $07,$03,$DF,$8F,$C0,$80 ;
  DEFB $0F,$07,$FF,$CF,$80,$00 ;
  DEFB $0F,$07,$FF,$EF,$80,$00 ;
  DEFB $07,$03,$FF,$DE,$00,$00 ;
  DEFB $03,$01,$FF,$F1,$80,$00 ;
  DEFB $03,$01,$F1,$C0,$00,$00 ;
  DEFB $03,$01,$C0,$00,$00,$00 ;
  DEFB $01,$00,$00,$00,$00,$00 ;

; Sprite for graphic 2
;
; 24 by 24 pixels.
SPRITE2:
  DEFB $03,$18            ; Width in bytes, and height in rows
  DEFB $BF,$BF,$9F,$9F,$D0,$D0 ; Mask and image bytes, a pair per cell, the
  DEFB $BF,$BF,$0F,$0F,$D0,$D0 ; bottom row first
  DEFB $BE,$BE,$C7,$C7,$D0,$D0 ;
  DEFB $BD,$BD,$DB,$DB,$D0,$D0 ;
  DEFB $BB,$BB,$BD,$BD,$D0,$D0 ;
  DEFB $B3,$B3,$7C,$7C,$D0,$D0 ;
  DEFB $AA,$AA,$FD,$FD,$50,$50 ;
  DEFB $99,$99,$FD,$FD,$90,$90 ;
  DEFB $9B,$9B,$F9,$F9,$90,$90 ;
  DEFB $AB,$AB,$F5,$F5,$50,$50 ;
  DEFB $B3,$B3,$EC,$EC,$D0,$D0 ;
  DEFB $BB,$BB,$DD,$DD,$D0,$D0 ;
  DEFB $BD,$BD,$BB,$BB,$D0,$D0 ;
  DEFB $BE,$BE,$37,$37,$D0,$D0 ;
  DEFB $BF,$BF,$0F,$0F,$D0,$D0 ;
  DEFB $BF,$BF,$9F,$9F,$D0,$D0 ;
  DEFB $9F,$9F,$DF,$DF,$90,$90 ;
  DEFB $8F,$8F,$EF,$EF,$10,$10 ;
  DEFB $97,$97,$F4,$F4,$90,$90 ;
  DEFB $9B,$9B,$F9,$F9,$90,$90 ;
  DEFB $99,$99,$FD,$FD,$90,$90 ;
  DEFB $96,$96,$FE,$FE,$90,$90 ;
  DEFB $8F,$8F,$7F,$7F,$10,$10 ;
  DEFB $9F,$9F,$BF,$BF,$90,$90 ;

; Sprite for graphic 3
;
; 16 by 24 pixels.
SPRITE3:
  DEFB $02,$18            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $00,$00,$00,$00    ; row first
  DEFB $00,$00,$00,$00    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $FF,$FF,$FF,$FF    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $FE,$FE,$7F,$7F    ;
  DEFB $FD,$FD,$BF,$BF    ;
  DEFB $FB,$FB,$DF,$DF    ;
  DEFB $F0,$F0,$0F,$0F    ;
  DEFB $EF,$EF,$77,$77    ;
  DEFB $DF,$DF,$BB,$BB    ;
  DEFB $9F,$9F,$DD,$DD    ;
  DEFB $0F,$0F,$EC,$EC    ;
  DEFB $37,$37,$F0,$F0    ;
  DEFB $BB,$BB,$F9,$F9    ;
  DEFB $DD,$DD,$FB,$FB    ;
  DEFB $EE,$EE,$F7,$F7    ;
  DEFB $F0,$F0,$0F,$0F    ;
  DEFB $FB,$FB,$DF,$DF    ;
  DEFB $FD,$FD,$BF,$BF    ;
  DEFB $FE,$FE,$7F,$7F    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $FF,$FF,$FF,$FF    ;

; Sprite for graphic 4
;
; 24 by 24 pixels.
SPRITE4:
  DEFB $03,$18            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$00,$00,$00,$00 ; bottom row first
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $FF,$FF,$FF,$FF,$FF,$FF ;
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $FE,$FE,$7F,$7F,$00,$00 ;
  DEFB $FD,$FD,$BF,$BF,$BD,$BD ;
  DEFB $FB,$FB,$DF,$DF,$DB,$DB ;
  DEFB $F0,$F0,$0F,$0F,$E7,$E7 ;
  DEFB $EF,$EF,$77,$77,$EF,$EF ;
  DEFB $DF,$DF,$BB,$BB,$DF,$DF ;
  DEFB $9F,$9F,$DD,$DD,$BF,$BF ;
  DEFB $0F,$0F,$EC,$EC,$7F,$7F ;
  DEFB $37,$37,$F0,$F0,$FE,$FE ;
  DEFB $BB,$BB,$F9,$F9,$FD,$FD ;
  DEFB $DD,$DD,$FB,$FB,$FB,$FB ;
  DEFB $EE,$EE,$F7,$F7,$F7,$F7 ;
  DEFB $F0,$F0,$0F,$0F,$E7,$E7 ;
  DEFB $FB,$FB,$DF,$DF,$DB,$DB ;
  DEFB $FD,$FD,$BF,$BF,$BD,$BD ;
  DEFB $FE,$FE,$7F,$7F,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $FF,$FF,$FF,$FF,$FF,$FF ;

; Sprite for graphic 5
;
; 24 by 24 pixels.
SPRITE5:
  DEFB $03,$18            ; Width in bytes, and height in rows
  DEFB $9F,$9F,$DF,$DF,$98,$98 ; Mask and image bytes, a pair per cell, the
  DEFB $8F,$8F,$EF,$EF,$04,$04 ; bottom row first
  DEFB $97,$97,$F6,$F6,$C2,$C2 ;
  DEFB $9B,$9B,$F9,$F9,$F1,$F1 ;
  DEFB $99,$99,$FC,$FC,$39,$39 ;
  DEFB $96,$96,$FE,$FE,$18,$18 ;
  DEFB $8F,$8F,$7F,$7F,$0C,$0C ;
  DEFB $9F,$9F,$BF,$BF,$8D,$8D ;
  DEFB $BF,$BF,$9F,$9F,$CB,$CB ;
  DEFB $BF,$BF,$0F,$0F,$E7,$E7 ;
  DEFB $BE,$BE,$07,$07,$F7,$F7 ;
  DEFB $BD,$BD,$03,$03,$FB,$FB ;
  DEFB $BB,$BB,$81,$81,$FD,$FD ;
  DEFB $B3,$B3,$C0,$C0,$FE,$FE ;
  DEFB $AB,$AB,$E0,$E0,$7F,$7F ;
  DEFB $9B,$9B,$F1,$F1,$BF,$BF ;
  DEFB $9B,$9B,$FB,$FB,$DF,$DF ;
  DEFB $9B,$9B,$F7,$F7,$EF,$EF ;
  DEFB $98,$98,$0F,$0F,$E7,$E7 ;
  DEFB $9F,$9F,$DF,$DF,$DB,$DB ;
  DEFB $9F,$9F,$BF,$BF,$DB,$DB ;
  DEFB $80,$80,$7F,$7F,$00,$00 ;
  DEFB $80,$80,$00,$00,$00,$00 ;
  DEFB $FF,$FF,$FF,$FF,$FF,$FF ;

; Sprite for graphic 6
;
; 24 by 55 pixels.
SPRITE6:
  DEFB $03,$37            ; Width in bytes, and height in rows
  DEFB $02,$00,$80,$00,$80,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $2F,$02,$E0,$80,$00,$00 ; bottom row first
  DEFB $7F,$2A,$FC,$A0,$00,$00 ;
  DEFB $FF,$5F,$FE,$DC,$00,$00 ;
  DEFB $FF,$ED,$FC,$B8,$00,$00 ;
  DEFB $FF,$6F,$F8,$B0,$00,$00 ;
  DEFB $FF,$77,$F8,$70,$00,$00 ;
  DEFB $7F,$37,$F0,$60,$00,$00 ;
  DEFB $7F,$3F,$F0,$60,$00,$00 ;
  DEFB $7F,$3F,$F0,$60,$00,$00 ;
  DEFB $7F,$3F,$F0,$E0,$00,$00 ;
  DEFB $7F,$3F,$F0,$E0,$00,$00 ;
  DEFB $7F,$3F,$F0,$E0,$00,$00 ;
  DEFB $7F,$3F,$E0,$C0,$00,$00 ;
  DEFB $7F,$3F,$E0,$C0,$00,$00 ;
  DEFB $7F,$3F,$E0,$C0,$00,$00 ;
  DEFB $7F,$3B,$E0,$C0,$00,$00 ;
  DEFB $7F,$37,$E0,$C0,$00,$00 ;
  DEFB $7F,$3F,$E0,$C0,$00,$00 ;
  DEFB $7F,$2F,$F0,$E0,$00,$00 ;
  DEFB $7F,$27,$F0,$E0,$00,$00 ;
  DEFB $7F,$1B,$F0,$E0,$00,$00 ;
  DEFB $7F,$3A,$F0,$E0,$00,$00 ;
  DEFB $7F,$39,$F0,$E0,$00,$00 ;
  DEFB $3F,$1B,$F0,$E0,$00,$00 ;
  DEFB $3F,$07,$F8,$F0,$00,$00 ;
  DEFB $7F,$3F,$F8,$F0,$00,$00 ;
  DEFB $FF,$5F,$F8,$F0,$00,$00 ;
  DEFB $FF,$9F,$F8,$F0,$00,$00 ;
  DEFB $BF,$1F,$FC,$F8,$00,$00 ;
  DEFB $7F,$3F,$FC,$F8,$00,$00 ;
  DEFB $7F,$3B,$FE,$BC,$00,$00 ;
  DEFB $7F,$3B,$FE,$9C,$00,$00 ;
  DEFB $7F,$33,$FF,$CE,$00,$00 ;
  DEFB $7F,$33,$EF,$C7,$80,$00 ;
  DEFB $7F,$33,$E7,$C3,$C0,$00 ;
  DEFB $77,$23,$F3,$E1,$C0,$80 ;
  DEFB $F7,$63,$F1,$60,$E0,$C0 ;
  DEFB $F7,$63,$F8,$70,$F0,$60 ;
  DEFB $F7,$63,$F8,$30,$78,$00 ;
  DEFB $E7,$07,$FC,$38,$78,$30 ;
  DEFB $E7,$43,$BC,$18,$FC,$58 ;
  DEFB $E7,$C3,$9E,$0C,$FE,$C0 ;
  DEFB $CF,$87,$9E,$0C,$EF,$46 ;
  DEFB $CF,$87,$BF,$16,$77,$23 ;
  DEFB $8F,$06,$3F,$16,$7E,$21 ;
  DEFB $1F,$0A,$77,$23,$9E,$00 ;
  DEFB $1F,$0A,$7F,$25,$DC,$80 ;
  DEFB $3F,$12,$7F,$24,$FE,$DC ;
  DEFB $3F,$12,$3C,$08,$FC,$60 ;
  DEFB $3F,$12,$1C,$08,$70,$20 ;
  DEFB $3F,$12,$1C,$08,$78,$30 ;
  DEFB $17,$02,$08,$00,$3C,$18 ;
  DEFB $07,$02,$00,$00,$18,$00 ;
  DEFB $02,$00,$00,$00,$00,$00 ;

; Sprite for graphic 7
;
; 16 by 40 pixels.
SPRITE7:
  DEFB $02,$28            ; Width in bytes, and height in rows
  DEFB $00,$00,$50,$00    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $01,$00,$FC,$50    ; row first
  DEFB $0F,$01,$FE,$54    ;
  DEFB $1F,$0D,$FF,$AA    ;
  DEFB $0F,$06,$FF,$F6    ;
  DEFB $07,$03,$FF,$7E    ;
  DEFB $07,$03,$FE,$7F    ;
  DEFB $03,$01,$FE,$EC    ;
  DEFB $03,$01,$FE,$EC    ;
  DEFB $03,$01,$FE,$F4    ;
  DEFB $07,$01,$FE,$F4    ;
  DEFB $0F,$07,$FC,$F8    ;
  DEFB $1F,$09,$FE,$FC    ;
  DEFB $3B,$11,$FE,$F8    ;
  DEFB $3B,$11,$FE,$C6    ;
  DEFB $77,$23,$FF,$D6    ;
  DEFB $77,$23,$FE,$D8    ;
  DEFB $2F,$05,$FC,$B8    ;
  DEFB $0F,$05,$FC,$B8    ;
  DEFB $1F,$09,$FC,$78    ;
  DEFB $1F,$09,$FC,$68    ;
  DEFB $3B,$10,$FC,$E8    ;
  DEFB $73,$20,$FC,$E8    ;
  DEFB $73,$21,$FE,$EC    ;
  DEFB $27,$03,$FE,$EC    ;
  DEFB $07,$03,$FE,$64    ;
  DEFB $0F,$06,$FE,$E4    ;
  DEFB $3F,$0D,$FE,$A4    ;
  DEFB $7F,$39,$FE,$24    ;
  DEFB $FF,$63,$FE,$24    ;
  DEFB $FF,$D2,$77,$22    ;
  DEFB $FF,$96,$77,$22    ;
  DEFB $9E,$04,$7B,$31    ;
  DEFB $3F,$0E,$7F,$29    ;
  DEFB $FF,$2A,$7D,$28    ;
  DEFB $FF,$D2,$FE,$64    ;
  DEFB $FF,$14,$FE,$A4    ;
  DEFB $7F,$25,$F7,$22    ;
  DEFB $75,$20,$77,$22    ;
  DEFB $20,$00,$22,$00    ;

; Sprite for graphics 10, 72, 76-77
;
; 32 by 25 pixels.
SPRITE10:
  DEFB $04,$19            ; Width in bytes, and height in rows
  DEFB $00,$00,$0F,$00,$F0,$00,$00,$00 ; Mask and image bytes, a pair per cell,
  DEFB $00,$00,$FF,$0D,$FF,$D0,$00,$00 ; the bottom row first
  DEFB $01,$00,$FF,$BD,$FF,$DF,$C0,$00 ;
  DEFB $07,$01,$FF,$BD,$FF,$DF,$E0,$40 ;
  DEFB $0F,$05,$FF,$BD,$FF,$EF,$F8,$60 ;
  DEFB $1F,$0C,$FF,$D9,$FF,$EF,$FC,$78 ;
  DEFB $1F,$0C,$FF,$D6,$FF,$EE,$FC,$F8 ;
  DEFB $1F,$0E,$FF,$B6,$FF,$EE,$FC,$50 ;
  DEFB $1F,$0E,$FF,$BA,$FF,$F6,$F8,$F0 ;
  DEFB $3F,$0D,$FF,$D9,$FF,$F6,$F8,$F0 ;
  DEFB $3F,$1D,$FF,$DD,$FF,$EE,$F8,$F0 ;
  DEFB $3F,$1D,$FF,$ED,$FF,$DF,$FC,$50 ;
  DEFB $3F,$1D,$FF,$ED,$FF,$EF,$FC,$58 ;
  DEFB $3F,$1B,$FF,$D0,$FF,$0F,$FC,$58 ;
  DEFB $3F,$0B,$FF,$0F,$FF,$F0,$FC,$F8 ;
  DEFB $1F,$08,$FF,$F8,$FF,$1F,$FC,$38 ;
  DEFB $1F,$0B,$FF,$C7,$FF,$E3,$FC,$D8 ;
  DEFB $1F,$07,$FF,$3C,$FF,$3D,$FC,$E8 ;
  DEFB $1F,$0E,$FF,$E3,$FF,$C6,$FC,$F0 ;
  DEFB $1F,$0E,$FF,$E3,$FF,$C6,$F8,$F0 ;
  DEFB $1F,$07,$FF,$3C,$FF,$3D,$F8,$E0 ;
  DEFB $0F,$03,$FF,$C7,$FF,$E3,$F0,$C0 ;
  DEFB $07,$00,$FF,$F8,$FF,$1F,$E0,$00 ;
  DEFB $01,$00,$FF,$0F,$FF,$F0,$80,$00 ;
  DEFB $00,$00,$1F,$00,$F8,$00,$00,$00 ;

; Sprite for graphic 12
;
; 16 by 43 pixels.
SPRITE12:
  DEFB $02,$2B            ; Width in bytes, and height in rows
  DEFB $00,$00,$42,$42    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $01,$01,$51,$51    ; row first
  DEFB $06,$06,$E9,$E9    ;
  DEFB $03,$03,$F1,$F1    ;
  DEFB $29,$29,$B1,$B1    ;
  DEFB $7C,$7C,$B1,$B1    ;
  DEFB $38,$38,$B1,$B1    ;
  DEFB $08,$08,$B1,$B1    ;
  DEFB $08,$08,$B1,$B1    ;
  DEFB $08,$08,$F3,$F3    ;
  DEFB $18,$18,$E3,$E3    ;
  DEFB $18,$18,$E3,$E3    ;
  DEFB $18,$18,$E3,$E3    ;
  DEFB $39,$39,$E3,$E3    ;
  DEFB $59,$59,$E3,$E3    ;
  DEFB $59,$59,$E3,$E3    ;
  DEFB $19,$19,$D3,$D3    ;
  DEFB $19,$19,$D3,$D3    ;
  DEFB $19,$19,$CA,$CA    ;
  DEFB $39,$39,$CA,$CA    ;
  DEFB $29,$29,$42,$42    ;
  DEFB $29,$29,$42,$42    ;
  DEFB $29,$29,$42,$42    ;
  DEFB $29,$29,$64,$64    ;
  DEFB $49,$49,$64,$64    ;
  DEFB $52,$49,$E4,$E4    ;
  DEFB $52,$52,$B2,$B2    ;
  DEFB $52,$52,$B2,$B2    ;
  DEFB $43,$43,$9A,$9A    ;
  DEFB $43,$43,$98,$98    ;
  DEFB $43,$43,$18,$18    ;
  DEFB $07,$07,$0C,$0C    ;
  DEFB $0B,$0B,$0C,$0C    ;
  DEFB $13,$13,$04,$04    ;
  DEFB $17,$17,$04,$04    ;
  DEFB $27,$17,$8E,$8E    ;
  DEFB $2B,$2B,$8A,$8A    ;
  DEFB $4A,$4A,$8A,$8A    ;
  DEFB $52,$52,$92,$92    ;
  DEFB $12,$12,$92,$92    ;
  DEFB $24,$24,$92,$92    ;
  DEFB $24,$24,$00,$00    ;
  DEFB $04,$04,$00,$00    ;

; Sprite for graphic 13
;
; 16 by 53 pixels.
SPRITE13:
  DEFB $02,$35            ; Width in bytes, and height in rows
  DEFB $41,$41,$40,$40    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $22,$22,$52,$52    ; row first
  DEFB $B2,$B2,$A2,$A2    ;
  DEFB $D6,$D6,$D0,$D0    ;
  DEFB $7F,$7F,$E0,$E0    ;
  DEFB $3E,$3E,$C2,$C2    ;
  DEFB $36,$36,$94,$94    ;
  DEFB $3A,$3A,$9C,$9C    ;
  DEFB $3B,$3B,$9C,$9C    ;
  DEFB $1B,$1B,$DE,$DE    ;
  DEFB $1D,$1D,$DC,$DC    ;
  DEFB $1D,$1D,$DC,$DC    ;
  DEFB $1D,$1D,$DE,$DE    ;
  DEFB $1D,$1D,$DC,$DC    ;
  DEFB $1F,$1F,$8C,$8C    ;
  DEFB $1F,$1F,$8C,$8C    ;
  DEFB $1F,$1F,$9C,$9C    ;
  DEFB $1F,$1F,$9E,$9E    ;
  DEFB $1D,$1D,$A6,$A6    ;
  DEFB $1D,$1D,$A6,$A6    ;
  DEFB $1D,$1D,$AE,$AE    ;
  DEFB $1D,$1D,$AD,$AD    ;
  DEFB $1D,$1D,$8D,$8D    ;
  DEFB $15,$15,$8D,$8D    ;
  DEFB $0E,$0E,$8C,$8C    ;
  DEFB $1E,$1E,$CC,$CC    ;
  DEFB $3E,$3E,$D4,$D4    ;
  DEFB $37,$37,$44,$44    ;
  DEFB $2F,$2F,$E4,$E4    ;
  DEFB $2F,$2F,$E4,$E4    ;
  DEFB $0D,$0D,$F0,$F0    ;
  DEFB $1D,$1D,$F8,$F8    ;
  DEFB $1D,$1D,$DC,$DC    ;
  DEFB $1D,$1D,$DC,$DC    ;
  DEFB $19,$19,$DA,$DA    ;
  DEFB $30,$30,$CD,$CD    ;
  DEFB $30,$30,$CC,$CC    ;
  DEFB $30,$30,$CC,$CC    ;
  DEFB $70,$70,$C6,$C6    ;
  DEFB $58,$58,$C6,$C6    ;
  DEFB $18,$18,$C6,$C6    ;
  DEFB $18,$18,$E2,$E2    ;
  DEFB $18,$18,$E2,$E2    ;
  DEFB $14,$14,$53,$53    ;
  DEFB $14,$14,$51,$51    ;
  DEFB $12,$12,$49,$49    ;
  DEFB $12,$12,$49,$49    ;
  DEFB $10,$10,$01,$01    ;
  DEFB $08,$08,$00,$00    ;
  DEFB $08,$08,$00,$00    ;
  DEFB $08,$08,$00,$00    ;
  DEFB $04,$04,$00,$00    ;
  DEFB $04,$04,$00,$00    ;

; Sprite for graphic 14
;
; 16 by 53 pixels.
SPRITE14:
  DEFB $02,$35            ; Width in bytes, and height in rows
  DEFB $01,$01,$24,$24    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $01,$01,$A5,$A5    ; row first
  DEFB $04,$04,$AA,$AA    ;
  DEFB $0A,$0A,$ED,$ED    ;
  DEFB $AF,$AF,$7F,$7F    ;
  DEFB $5B,$5B,$BE,$BE    ;
  DEFB $73,$73,$3C,$3C    ;
  DEFB $73,$73,$1C,$1C    ;
  DEFB $71,$71,$1C,$1C    ;
  DEFB $31,$31,$1C,$1C    ;
  DEFB $31,$31,$9C,$9C    ;
  DEFB $31,$31,$BC,$BC    ;
  DEFB $39,$39,$BC,$BC    ;
  DEFB $35,$35,$BC,$BC    ;
  DEFB $35,$35,$BC,$BC    ;
  DEFB $31,$31,$FA,$FA    ;
  DEFB $31,$31,$EA,$EA    ;
  DEFB $39,$39,$69,$69    ;
  DEFB $39,$39,$69,$69    ;
  DEFB $39,$39,$E9,$E9    ;
  DEFB $39,$39,$B9,$B9    ;
  DEFB $59,$59,$B9,$B9    ;
  DEFB $5D,$5D,$B8,$B8    ;
  DEFB $95,$95,$B8,$B8    ;
  DEFB $95,$95,$B8,$B8    ;
  DEFB $B5,$B5,$B8,$B8    ;
  DEFB $25,$25,$3C,$3C    ;
  DEFB $27,$27,$7C,$7C    ;
  DEFB $67,$67,$7A,$7A    ;
  DEFB $43,$43,$7A,$7A    ;
  DEFB $47,$47,$7A,$7A    ;
  DEFB $46,$46,$BA,$BA    ;
  DEFB $46,$46,$B8,$B8    ;
  DEFB $26,$26,$B8,$B8    ;
  DEFB $26,$26,$3C,$3C    ;
  DEFB $2E,$2E,$3C,$3C    ;
  DEFB $2C,$2C,$74,$74    ;
  DEFB $2C,$2C,$76,$76    ;
  DEFB $1A,$1A,$B2,$B2    ;
  DEFB $1A,$1A,$B2,$B2    ;
  DEFB $29,$29,$31,$31    ;
  DEFB $49,$49,$31,$31    ;
  DEFB $52,$52,$B8,$B8    ;
  DEFB $92,$92,$D8,$D8    ;
  DEFB $92,$92,$54,$54    ;
  DEFB $14,$14,$94,$94    ;
  DEFB $14,$14,$B4,$B4    ;
  DEFB $04,$04,$32,$32    ;
  DEFB $00,$00,$52,$52    ;
  DEFB $00,$00,$50,$50    ;
  DEFB $00,$00,$90,$90    ;
  DEFB $00,$00,$90,$90    ;
  DEFB $00,$00,$10,$10    ;

; Sprite for graphic 15
;
; 16 by 50 pixels.
SPRITE15:
  DEFB $02,$32            ; Width in bytes, and height in rows
  DEFB $00,$00,$50,$50    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $00,$00,$70,$70    ; row first
  DEFB $05,$05,$27,$27    ;
  DEFB $2A,$2A,$2E,$2E    ;
  DEFB $57,$57,$AE,$AE    ;
  DEFB $7F,$7F,$26,$26    ;
  DEFB $3B,$3B,$26,$26    ;
  DEFB $1A,$1A,$64,$64    ;
  DEFB $1A,$1A,$64,$64    ;
  DEFB $16,$16,$A4,$A4    ;
  DEFB $16,$16,$A4,$A4    ;
  DEFB $36,$36,$B4,$B4    ;
  DEFB $56,$56,$34,$34    ;
  DEFB $5C,$5C,$2C,$2C    ;
  DEFB $1C,$1C,$24,$24    ;
  DEFB $1C,$1C,$24,$24    ;
  DEFB $3E,$3E,$2A,$2A    ;
  DEFB $3E,$3E,$4A,$4A    ;
  DEFB $77,$77,$4A,$4A    ;
  DEFB $57,$57,$08,$08    ;
  DEFB $D6,$D6,$89,$89    ;
  DEFB $96,$96,$89,$89    ;
  DEFB $B5,$B5,$41,$41    ;
  DEFB $A5,$A5,$21,$21    ;
  DEFB $3C,$3C,$A1,$A1    ;
  DEFB $3A,$3A,$91,$91    ;
  DEFB $7A,$7A,$50,$50    ;
  DEFB $5A,$5A,$48,$48    ;
  DEFB $59,$59,$24,$24    ;
  DEFB $59,$59,$22,$22    ;
  DEFB $59,$59,$11,$11    ;
  DEFB $59,$59,$10,$10    ;
  DEFB $58,$58,$88,$88    ;
  DEFB $98,$98,$88,$88    ;
  DEFB $94,$94,$84,$84    ;
  DEFB $94,$94,$44,$44    ;
  DEFB $14,$14,$40,$40    ;
  DEFB $14,$14,$40,$40    ;
  DEFB $14,$14,$40,$40    ;
  DEFB $14,$14,$20,$20    ;
  DEFB $12,$12,$20,$20    ;
  DEFB $12,$12,$20,$20    ;
  DEFB $12,$12,$10,$10    ;
  DEFB $12,$12,$10,$10    ;
  DEFB $12,$12,$10,$10    ;
  DEFB $12,$12,$08,$08    ;
  DEFB $12,$12,$08,$08    ;
  DEFB $12,$12,$00,$00    ;
  DEFB $02,$02,$00,$00    ;
  DEFB $02,$02,$00,$00    ;

; Sprite for graphic 54
;
; 16 by 26 pixels.
SPRITE54:
  DEFB $02,$1A            ; Width in bytes, and height in rows
  DEFB $40,$40,$00,$00    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $70,$70,$00,$00    ; row first
  DEFB $7C,$7C,$00,$00    ;
  DEFB $7F,$7F,$00,$00    ;
  DEFB $7F,$7F,$80,$80    ;
  DEFB $3F,$3F,$B0,$B0    ;
  DEFB $CF,$CF,$BC,$BC    ;
  DEFB $F3,$F3,$BF,$BF    ;
  DEFB $FC,$FC,$BF,$BF    ;
  DEFB $FF,$FF,$3F,$3F    ;
  DEFB $FF,$FF,$BF,$BF    ;
  DEFB $FF,$FF,$BF,$BF    ;
  DEFB $3F,$3F,$BF,$BF    ;
  DEFB $4F,$4F,$BF,$BF    ;
  DEFB $73,$73,$3F,$3F    ;
  DEFB $7C,$7C,$3F,$3F    ;
  DEFB $1D,$1D,$CF,$CF    ;
  DEFB $65,$65,$F3,$F3    ;
  DEFB $75,$75,$FC,$FC    ;
  DEFB $38,$38,$FF,$FF    ;
  DEFB $07,$07,$3F,$3F    ;
  DEFB $1F,$1F,$CF,$CF    ;
  DEFB $07,$07,$F3,$F3    ;
  DEFB $01,$01,$FD,$FD    ;
  DEFB $00,$00,$7E,$7E    ;
  DEFB $00,$00,$18,$18    ;

; Sprite for graphic 53
;
; 16 by 31 pixels.
SPRITE53:
  DEFB $02,$1F            ; Width in bytes, and height in rows
  DEFB $60,$60,$00,$00    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $70,$70,$00,$00    ; row first
  DEFB $04,$04,$00,$00    ;
  DEFB $72,$72,$00,$00    ;
  DEFB $7B,$7B,$00,$00    ;
  DEFB $78,$78,$5C,$5C    ;
  DEFB $78,$78,$EE,$EE    ;
  DEFB $31,$31,$CE,$CE    ;
  DEFB $01,$01,$C8,$C8    ;
  DEFB $00,$00,$E6,$E6    ;
  DEFB $30,$30,$26,$26    ;
  DEFB $3E,$3E,$03,$03    ;
  DEFB $1E,$1E,$30,$30    ;
  DEFB $CF,$CF,$7C,$7C    ;
  DEFB $C7,$C7,$3E,$3E    ;
  DEFB $E3,$E3,$87,$87    ;
  DEFB $F0,$F0,$30,$30    ;
  DEFB $1B,$1B,$7E,$7E    ;
  DEFB $E9,$E9,$7E,$7E    ;
  DEFB $74,$74,$7F,$7F    ;
  DEFB $70,$70,$7F,$7F    ;
  DEFB $7F,$7F,$3F,$3F    ;
  DEFB $3E,$3E,$BF,$BF    ;
  DEFB $3D,$3D,$BF,$BF    ;
  DEFB $13,$13,$BF,$BF    ;
  DEFB $0F,$0F,$9F,$9F    ;
  DEFB $06,$06,$27,$27    ;
  DEFB $01,$01,$F9,$F9    ;
  DEFB $07,$07,$FE,$FE    ;
  DEFB $01,$01,$F8,$F8    ;
  DEFB $00,$00,$60,$60    ;

; Sprite for graphic 52
;
; 16 by 33 pixels.
SPRITE52:
  DEFB $02,$21            ; Width in bytes, and height in rows
  DEFB $34,$34,$00,$00    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $F7,$F7,$00,$00    ; row first
  DEFB $F7,$F7,$C0,$C0    ;
  DEFB $C9,$C9,$F0,$F0    ;
  DEFB $3E,$3E,$7C,$7C    ;
  DEFB $FF,$FF,$9F,$9F    ;
  DEFB $F0,$F0,$27,$27    ;
  DEFB $CF,$CF,$C9,$C9    ;
  DEFB $BE,$BE,$F7,$F7    ;
  DEFB $7C,$7C,$7A,$7A    ;
  DEFB $FC,$FC,$7C,$7C    ;
  DEFB $EC,$EC,$6C,$6C    ;
  DEFB $CC,$CC,$64,$64    ;
  DEFB $CC,$CC,$64,$64    ;
  DEFB $CC,$CC,$64,$64    ;
  DEFB $CC,$CC,$64,$64    ;
  DEFB $CC,$CC,$64,$64    ;
  DEFB $CC,$CC,$64,$64    ;
  DEFB $CC,$CC,$64,$64    ;
  DEFB $CC,$CC,$64,$64    ;
  DEFB $CC,$CC,$64,$64    ;
  DEFB $CC,$CC,$64,$64    ;
  DEFB $CC,$CC,$64,$64    ;
  DEFB $CC,$CC,$64,$64    ;
  DEFB $CC,$CC,$64,$64    ;
  DEFB $8F,$8F,$A4,$A4    ;
  DEFB $76,$76,$E4,$E4    ;
  DEFB $BF,$BF,$78,$78    ;
  DEFB $3D,$3D,$FC,$FC    ;
  DEFB $53,$53,$54,$54    ;
  DEFB $3D,$3D,$A8,$A8    ;
  DEFB $07,$07,$F0,$F0    ;
  DEFB $00,$00,$E0,$E0    ;

; Sprite for graphic 55
;
; 16 by 24 pixels.
SPRITE55:
  DEFB $02,$18            ; Width in bytes, and height in rows
  DEFB $C0,$C0,$00,$00    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $F0,$F0,$00,$00    ; row first
  DEFB $FC,$FC,$00,$00    ;
  DEFB $7E,$7E,$00,$00    ;
  DEFB $3E,$3E,$C0,$C0    ;
  DEFB $46,$46,$F0,$F0    ;
  DEFB $F8,$F8,$F4,$F4    ;
  DEFB $FE,$FE,$F6,$F6    ;
  DEFB $1E,$1E,$F3,$F3    ;
  DEFB $6C,$6C,$34,$34    ;
  DEFB $F1,$F1,$8E,$8E    ;
  DEFB $FB,$FB,$FF,$FF    ;
  DEFB $BD,$BD,$FF,$FF    ;
  DEFB $DE,$DE,$FF,$FF    ;
  DEFB $EF,$EF,$7F,$7F    ;
  DEFB $F7,$F7,$8E,$8E    ;
  DEFB $7B,$7B,$B0,$B0    ;
  DEFB $3F,$3F,$3E,$3E    ;
  DEFB $58,$58,$BF,$BF    ;
  DEFB $07,$07,$DF,$DF    ;
  DEFB $1F,$1F,$E6,$E6    ;
  DEFB $03,$03,$F8,$F8    ;
  DEFB $04,$04,$C6,$C6    ;
  DEFB $06,$06,$06,$06    ;

; Sprite for graphic 56
;
; 16 by 27 pixels.
SPRITE56:
  DEFB $02,$1B            ; Width in bytes, and height in rows
  DEFB $C0,$C0,$00,$00    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $E0,$E0,$00,$00    ; row first
  DEFB $EC,$EC,$00,$00    ;
  DEFB $6F,$6F,$00,$00    ;
  DEFB $0F,$0F,$80,$80    ;
  DEFB $E3,$E3,$B0,$B0    ;
  DEFB $F8,$F8,$BC,$BC    ;
  DEFB $FE,$FE,$0F,$0F    ;
  DEFB $FE,$FE,$E3,$E3    ;
  DEFB $FE,$FE,$F8,$F8    ;
  DEFB $3E,$3E,$7E,$7E    ;
  DEFB $8D,$8D,$BF,$BF    ;
  DEFB $E3,$E3,$8F,$8F    ;
  DEFB $FB,$FB,$72,$72    ;
  DEFB $FA,$FA,$BC,$BC    ;
  DEFB $F5,$F5,$DE,$DE    ;
  DEFB $6B,$6B,$DE,$DE    ;
  DEFB $07,$07,$EF,$EF    ;
  DEFB $03,$03,$EF,$EF    ;
  DEFB $03,$03,$E7,$E7    ;
  DEFB $03,$03,$FB,$FB    ;
  DEFB $00,$00,$7B,$7B    ;
  DEFB $01,$01,$8D,$8D    ;
  DEFB $00,$00,$FF,$FF    ;
  DEFB $00,$00,$FC,$FC    ;
  DEFB $00,$00,$70,$70    ;
  DEFB $00,$00,$40,$40    ;

; Sprite for graphic 9
;
; 24 by 36 pixels.
SPRITE9:
  DEFB $03,$24            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$30,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$00,$00,$7C,$30 ; bottom row first
  DEFB $00,$00,$01,$00,$FF,$7C ;
  DEFB $00,$00,$03,$01,$FF,$BF ;
  DEFB $00,$00,$0F,$03,$FF,$BF ;
  DEFB $00,$00,$3F,$0F,$FF,$BF ;
  DEFB $00,$00,$FF,$3F,$FF,$BE ;
  DEFB $01,$00,$FF,$FF,$FF,$C6 ;
  DEFB $01,$00,$FF,$FF,$FF,$3C ;
  DEFB $01,$00,$FF,$FC,$FF,$FE ;
  DEFB $00,$00,$FF,$33,$FF,$FF ;
  DEFB $00,$00,$3F,$0F,$FF,$F7 ;
  DEFB $00,$00,$3F,$03,$FF,$C8 ;
  DEFB $00,$00,$7F,$30,$FF,$3A ;
  DEFB $00,$00,$FF,$7B,$FF,$FA ;
  DEFB $00,$00,$7F,$3B,$FF,$D3 ;
  DEFB $00,$00,$7F,$3B,$FF,$38 ;
  DEFB $00,$00,$3F,$02,$FF,$F7 ;
  DEFB $00,$00,$03,$00,$FF,$F7 ;
  DEFB $00,$00,$01,$00,$FF,$F7 ;
  DEFB $00,$00,$01,$00,$FF,$EE ;
  DEFB $00,$00,$01,$00,$FF,$EE ;
  DEFB $00,$00,$0F,$00,$FF,$EE ;
  DEFB $00,$00,$3F,$0D,$FF,$EE ;
  DEFB $00,$00,$7F,$3D,$FE,$CC ;
  DEFB $01,$00,$FF,$1D,$FE,$F0 ;
  DEFB $07,$01,$FF,$A5,$FE,$FC ;
  DEFB $1F,$07,$FF,$B8,$FF,$7E ;
  DEFB $BF,$1F,$FF,$BD,$FF,$9E ;
  DEFB $FF,$BE,$FF,$5D,$FF,$E6 ;
  DEFB $FF,$B8,$FF,$E5,$FE,$F8 ;
  DEFB $FF,$06,$FF,$79,$FE,$FC ;
  DEFB $FF,$DF,$FF,$9C,$FC,$78 ;
  DEFB $FF,$DF,$FF,$E5,$FC,$98 ;
  DEFB $FF,$0F,$FF,$F0,$98,$00 ;
  DEFB $0F,$00,$F0,$00,$00,$00 ;

; Sprite for graphic 8
;
; 24 by 49 pixels.
SPRITE8:
  DEFB $03,$31            ; Width in bytes, and height in rows
  DEFB $01,$00,$C0,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $37,$01,$F0,$C0,$00,$00 ; bottom row first
  DEFB $FF,$37,$FC,$F0,$00,$00 ;
  DEFB $FF,$F3,$FF,$FC,$00,$00 ;
  DEFB $FF,$EE,$FF,$FC,$00,$00 ;
  DEFB $FF,$7E,$FF,$FA,$00,$00 ;
  DEFB $FF,$7E,$FE,$BC,$00,$00 ;
  DEFB $FF,$7F,$FE,$5C,$00,$00 ;
  DEFB $FF,$0F,$FF,$6E,$00,$00 ;
  DEFB $7F,$3D,$FF,$72,$00,$00 ;
  DEFB $3F,$13,$FF,$B4,$00,$00 ;
  DEFB $1F,$0F,$FF,$B8,$00,$00 ;
  DEFB $1F,$0F,$FF,$76,$00,$00 ;
  DEFB $3F,$1E,$FE,$F0,$00,$00 ;
  DEFB $7F,$19,$F8,$60,$00,$00 ;
  DEFB $FF,$67,$FE,$98,$00,$00 ;
  DEFB $FF,$7F,$FF,$9E,$00,$00 ;
  DEFB $FF,$FF,$FF,$AF,$80,$00 ;
  DEFB $FF,$FC,$FF,$37,$80,$00 ;
  DEFB $FF,$7B,$FF,$73,$80,$00 ;
  DEFB $7F,$33,$FF,$7B,$80,$00 ;
  DEFB $3F,$0D,$FF,$79,$80,$00 ;
  DEFB $1F,$0D,$FF,$1C,$80,$00 ;
  DEFB $1F,$09,$FF,$6F,$80,$00 ;
  DEFB $1F,$06,$FF,$77,$80,$00 ;
  DEFB $7F,$1B,$FF,$7B,$C0,$00 ;
  DEFB $FF,$7D,$FF,$78,$E0,$C0 ;
  DEFB $FF,$7B,$FF,$37,$E0,$C0 ;
  DEFB $7F,$2F,$FF,$83,$E0,$C0 ;
  DEFB $7F,$3C,$FF,$8C,$E0,$C0 ;
  DEFB $7F,$32,$FF,$2F,$C0,$00 ;
  DEFB $3F,$0E,$FF,$77,$E0,$C0 ;
  DEFB $7F,$3E,$FF,$7B,$F0,$E0 ;
  DEFB $FF,$7E,$FF,$FD,$F0,$E0 ;
  DEFB $7F,$38,$FF,$DC,$F0,$60 ;
  DEFB $3F,$06,$FF,$6D,$E0,$80 ;
  DEFB $1F,$0F,$FF,$7D,$F8,$E0 ;
  DEFB $0F,$07,$FF,$BB,$FC,$F8 ;
  DEFB $07,$00,$FF,$04,$FE,$FC ;
  DEFB $03,$01,$FF,$FF,$FE,$3C ;
  DEFB $01,$00,$FF,$7F,$FE,$CC ;
  DEFB $00,$00,$7F,$1F,$FC,$80 ;
  DEFB $00,$00,$1F,$04,$FE,$7C ;
  DEFB $00,$00,$07,$03,$FE,$FC ;
  DEFB $00,$00,$07,$03,$FF,$FE ;
  DEFB $00,$00,$03,$01,$FF,$FF ;
  DEFB $00,$00,$01,$00,$FF,$FF ;
  DEFB $00,$00,$00,$00,$FF,$07 ;
  DEFB $00,$00,$00,$00,$07,$00 ;

; Sprite for graphic 57
;
; 16 by 34 pixels.
SPRITE57:
  DEFB $02,$22            ; Width in bytes, and height in rows
  DEFB $00,$00,$20,$20    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $00,$00,$D8,$D8    ; row first
  DEFB $03,$03,$DE,$DE    ;
  DEFB $1B,$1B,$DF,$DF    ;
  DEFB $7B,$7B,$C7,$C7    ;
  DEFB $FA,$FA,$39,$39    ;
  DEFB $E1,$E1,$FC,$FC    ;
  DEFB $9B,$9B,$FE,$FE    ;
  DEFB $7B,$7B,$FF,$FF    ;
  DEFB $7B,$7B,$FF,$FF    ;
  DEFB $7B,$7B,$FE,$FE    ;
  DEFB $7A,$7A,$7E,$7E    ;
  DEFB $79,$79,$86,$86    ;
  DEFB $43,$43,$F8,$F8    ;
  DEFB $3B,$3B,$FC,$FC    ;
  DEFB $7B,$7B,$FE,$FE    ;
  DEFB $7B,$7B,$FF,$FF    ;
  DEFB $79,$79,$FE,$FE    ;
  DEFB $7A,$7A,$FE,$FE    ;
  DEFB $FB,$FB,$7C,$7C    ;
  DEFB $F7,$F7,$B0,$B0    ;
  DEFB $EF,$EF,$80,$80    ;
  DEFB $13,$13,$7E,$7E    ;
  DEFB $1C,$1C,$FF,$FF    ;
  DEFB $EF,$EF,$7F,$7F    ;
  DEFB $EF,$EF,$AF,$AF    ;
  DEFB $D3,$D3,$C3,$C3    ;
  DEFB $BC,$BC,$FC,$FC    ;
  DEFB $7F,$7F,$3E,$3E    ;
  DEFB $3F,$3F,$CE,$CE    ;
  DEFB $07,$07,$F2,$F2    ;
  DEFB $01,$01,$FC,$FC    ;
  DEFB $00,$00,$78,$78    ;
  DEFB $00,$00,$10,$10    ;

; Game variables
;
; All zero on the tape. When the game is first run, START clears everything
; from here to the end of the object records; after every game it clears again
; from BUCKET_OUT on. So the first five bytes -- the control method, the menu's
; two, an unused one and the random number -- carry over from one game to the
; next: the next game carries on the random sequence rather than replaying the
; last one, and the menu shows the method chosen before.
CONTROL:
  DEFB $00                ; Control method: bits 1-2 are 0 keyboard, 1
                          ; Kempston, 2 cursor, 3 Interface II (MENU); bit 3
                          ; steers a joystick by direction (HANDLE_LEFT_RIGHT),
                          ; and no menu choice sets it. Kept from game to game
MENU_PASSES:
  DEFB $00                ; Counted up each time round the menu's loop (MENU);
                          ; nothing reads it
  DEFB $00                ; Nothing refers to this byte
CONTROL_BEFORE:
  DEFB $00                ; The control method as it was before the menu read
                          ; the keys this time round; the menu compares the two
                          ; and throws the result away
RANDOM:
  DEFB $00                ; The random number: R is added in at every new game
                          ; and after every object's update (OBJECT_DONE). Read
                          ; for the start room (CHOOSE_START), the drops from
                          ; the sky (SKY_DROP), the collectables' starting
                          ; spots (NEW_QUEST) and by SPIDER; PUFF_SOUND reads
                          ; it as a word with the byte after, masked to an
                          ; address in the ROM, and plays the bytes there as
                          ; pitches
BUCKET_OUT:
  DEFB $00                ; 1 while the well's bucket is out: the well gives no
                          ; other (WELL); the bucket clears it when it reaches
                          ; a quest item (BUCKET). The first byte a new game
                          ; clears
PENTAGRAM_ON:
  DEFB $00                ; 1 once all four quest items are done
                          ; (ALL_FOUR_DONE): from then on the pentagram's
                          ; pieces are put into their room (QUEST_INTO_ROOM)
WIPE_COUNT:
  DEFB $00                ; How many areas RENDER_DYNAMIC_OBJECTS has wiped
                          ; this turn and left on the stack to be copied to the
                          ; screen
NEW_ROOM:
  DEFB $00                ; Set by ENTER_ROOM when it has built a room. While
                          ; it is set RENDER_DYNAMIC_OBJECTS wipes nothing; the
                          ; main loop (OBJECT_DONE) then redraws the whole
                          ; screen and the panel and clears it
LIST_POINTER:
  DEFB $00,$00            ; Where RENDER_DYNAMIC_OBJECTS is in the list at
                          ; DRAW_LIST
DRAW_WORK:
  DEFB $00                ; The turn's drawing work: SORT_AND_DRAW zeroes it
                          ; and counts every object it draws,
                          ; RENDER_DYNAMIC_OBJECTS adds every area it wiped,
                          ; and the main loop (OBJECT_DONE) waits six units
                          ; less this
TURNS:
  DEFB $00,$00            ; The turn counter, counted up at the end of every
                          ; turn (OBJECT_DONE); also read by CONVEYOR_PUSH and
                          ; SPIDER
SAVED_SP:
  DEFB $00,$00            ; The stack pointer, while DRAW_OBJECT has it reading
                          ; a sprite
SORT_FIRST:
  DEFB $00,$00            ; Where SORT_AND_DRAW is in the list at DRAW_LIST:
                          ; the place after the object it has in hand
SORT_SECOND:
  DEFB $00,$00            ; The place after the object SORT_AND_DRAW is
                          ; comparing it with
ROOM_EXTENT:
  DEFB $00,$00,$00        ; The room's size, from ROOM_SIZES (BUILD_ROOM): how
                          ; far from the middle of the room, 128, an object may
                          ; reach in U, then in V -- the walls' tests
                          ; (ADJ_DU_FOR_OUT_OF_BOUNDS,
                          ; ADJ_DV_FOR_OUT_OF_BOUNDS, CHK_PLYR_OOB) compare the
                          ; distance plus its half-size with them -- and the
                          ; floor's height in Z, 128 in all three sizes, below
                          ; which nothing falls (ADJ_DZ_FOR_OUT_OF_BOUNDS) and
                          ; on which the builder stands the objects
PANEL_DUE:
  DEFB $00                ; Set when what he carries changes (TAKE_OR_LEAVE);
                          ; SHOW_CARRIED redraws the panel's items and clears
                          ; it
LIVES:
  DEFB $00                ; Lives, in BCD. START gives five and every start of
                          ; a life takes one (RESTART_PLAYER), so five is the
                          ; one in play and four more; the game ends when there
                          ; is none to take
CARRIED:
  DEFB $00,$00,$00,$00    ; What he carries: entries of four bytes, the
                          ; graphic, the flags and the address of the thing's
                          ; quest record. This one is a slot for the thing
                          ; being picked up, empty between presses:
                          ; TAKE_OR_LEAVE writes it here, then moves every
                          ; entry along one
CARRIED_SHOWN:
  DEFB $00,$00,$00,$00    ; The things he carries, newest first; these two and
  DEFB $00,$00,$00,$00    ; the next are the three SHOW_CARRIED shows on the
                          ; panel
CARRIED_LAST:
  DEFB $00,$00,$00,$00    ; The oldest, which the next press puts down
FONT_BASE:
  DEFB $00,$00            ; The base the print routine (PRINT_CHAR) adds eight
                          ; times a character's code to: 384 bytes below the
                          ; font for text, the font itself for digits
FRAME_DRAWN:
  DEFB $00                ; 0 until DISPLAY_MENU has drawn the text screen's
                          ; frame and copied the whole buffer to the screen,
                          ; which it then does not do again; the menu and the
                          ; win clear it to have that done afresh (MENU, WON)
MENU_SPARE:
  DEFB $00                ; Nothing reads or writes it: its only mention is an
                          ; LD HL the menu's next instruction overwrites (MENU)
PRINT_ATTR:
  DEFB $00                ; The attribute PRINT_TEXT_SINGLE_COLOUR gives each
                          ; cell of text it prints; set by PRINT_SCORE and
                          ; DISPLAY_MENU
INPUT:
  DEFB $00                ; This turn's controls (READ_CONTROLS): bits 0 and 1
                          ; turn, 2 walk, 3 jump, 4 pick up or put down, 6 fire
ROOM_ATTR:
  DEFB $00                ; The room's attribute, its ink with BRIGHT on black
                          ; (BUILD_ROOM); the main loop fills the screen's
                          ; attributes with it on the first turn in a room
                          ; (OBJECT_DONE)
Z_STEP:
  DEFB $00                ; The player's step in Z this turn, kept past the
                          ; move (MOVE_PLAYER)
TEMPLATES_AT:
  DEFB $00,$00            ; The object template table the builder reads
                          ; (OBJECT_TABLE, BUILD_ROOM)
PLACE_NUDGE:
  DEFB $00                ; Added to the objects' positions by the builder
                          ; (BUILD_ROOM); zero for every room
DROP_TIMER:
  DEFB $00                ; Turns until something may fall from the sky
                          ; (SKY_DROP); set on entering a room
                          ; (RESET_DROP_TIMER)
MAIN_SP:
  DEFB $00,$00            ; The stack pointer, saved every turn by the main
                          ; loop (OBJECT_DONE); nothing reads it back
TAKE_HELD:
  DEFB $00                ; 1 while the pick-up key is held, so one press does
                          ; one thing (TAKE_OR_LEAVE)
NO_HEADROOM:
  DEFB $00                ; 1 when there is no room above him to stand on what
                          ; he puts down (TAKE_OR_LEAVE)
DROP_BAN:
  DEFB $00                ; 1 in a room with the well, a quest item or a piece
                          ; of the pentagram: nothing falls there (BAN_DROPS)
FIRE_HELD:
  DEFB $00                ; 1 while fire is held, so one press is one shot
                          ; (FIRE)
SCORE:
  DEFB $00,$00,$00        ; The score, six BCD digits, the highest first
                          ; (ADD_SCORE)
TUNE_HEARD:
  DEFB $00                ; Set once the menu's tune has played
                          ; (PLAY_TUNE_ONCE)
STEP_SOUND:
  DEFB $00                ; Counted up by FOOTSTEP, which clicks on every
                          ; fourth count
SOUND_COUNT:
  DEFB $00,$00            ; A sound effect under way: turns left, then which
                          ; sound (EFFECT_NOTE). The pause's click (PAUSE_BEEP)
                          ; counts the first byte up as well
PLACED:
  DEFB $00                ; How many collectables have reached their places in
                          ; room 82 (COLLECTABLE)
QUEST_DONE:
  DEFB $00                ; How many quest items the bucket has reached
                          ; (QUEST_ITEM)
PERCENT:
  DEFB $00,$00            ; The percentage of the quest done, BCD, the hundreds
                          ; first, worked out by PERCENTAGE
ROOMS_SEEN:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; A bit for each room number, bit 7 of
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; the first byte for room 0, set on
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; entering it (MARK_ROOM_SEEN).
  DEFB $00,$00,$00,$00,$00,$00,$00     ; PERCENTAGE counts all 31 bytes for the
                                       ; percentage, though rooms go no higher
                                       ; than 149, so only the first 19 can
                                       ; hold a bit
  DEFB $00                ; Nothing refers to this byte

; The object records
;
; Everything in the room: 54 records of 32 bytes, all zero on the tape. The
; first six have fixed jobs -- the player's legs and body, two bolts he fires,
; two things fallen from the sky -- and the other 48 are the room's: the
; builder (BUILD_ROOM) fills them from the top down with scenery and objects,
; and QUEST_INTO_ROOM puts the quest things in the lowest free ones. The main
; loop (START) runs every record's update routine once a turn, in order, empty
; ones included.
;
; A record: +0 the graphic, which also picks the update routine (UPDATES) and
; the sprite (GRAPHICS); 0 is an empty record, and 1 one that is emptied when
; it is next drawn. +1 to +3 U, V and Z. +4 and +5 the half-sizes in U and V,
; +6 the whole height from the base at +3. +7 the flags: bit 1 is set, among
; other uses, on the record being tested for overlaps (DO_ANY_OBJS_INTERSECT);
; bit 4 that it is to be drawn (LIST_DRAWN), bit 5 that it moved and its old
; picture must be wiped (RENDER_DYNAMIC_OBJECTS), bit 6 mirrored and bit 7
; upside down (FIND_SPRITE); the rest are described with the routines that use
; them. +8 the room -- except for scenery, where it is the scenery entry's
; second byte: for a doorway the room it leads to, otherwise 0. +9 to +B the
; step in U, V and Z this turn. +C what it bumped into. +D bit 7: kills what it
; moves into; bit 5: kills what touches it; bit 6: killed. +E and +F an extra
; step in U and V, added into the next move and cleared (CALC_PLYR_DUV); a
; doorway uses it to steer the player to its middle (NUDGE_ALONG_V,
; NUDGE_ALONG_U).
;
; +10 and +11: for a quest thing, the address of its quest record
; (QUEST_INTO_ROOM); other kinds keep their own counters there. +12 and +13 the
; drawing nudge, signed, added to the pixel x and y (CALC_PIXEL_XY); the update
; routines set it, through the short routines from DRAW_AT_L8 on. +14 to +17
; are each kind's own; bit 7 of +17 is set on a record that meets the player's
; legs, or graphic 91, in Z -- one on top of the other (MARK_STOOD_ON) -- and
; LIFT, BOBBER and CRUMBLING_BLOCK read it. +18 and +19 the width in bytes and
; the height in rows of the sprite as last drawn, +1A and +1B its pixel x and
; y; +1C to +1F the same four from the turn before, copied there before each
; update (START) so the old picture can be wiped.
OBJECTS:
  DEFB $00                ; The player's legs: graphic
PLAYER_U:
  DEFB $00                ; U
PLAYER_V:
  DEFB $00                ; V
  DEFB $00                ; Z
  DEFB $00,$00,$00        ; Half-sizes in U, V and Z
PLAYER_FLAGS:
  DEFB $00                ; Flags
PLAYER_ROOM:
  DEFB $00                ; The room
  DEFB $00,$00,$00        ; The step in U, V and Z
PLAYER_BUMPED:
  DEFB $00                ; What he bumped into
PLAYER_STATE:
  DEFB $00                ; Bit 6: killed
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; The rest of the legs' record
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00                         ;
PLAYER_BODY:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; The player's body
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
BOLTS:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; A bolt he fires (FIRE)
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
BOLT_SECOND:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; The other
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
FLYERS:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; A thing fallen from the sky (SKY_DROP)
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
FLYER_SECOND:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; The other
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
ROOM_OBJECTS:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; The room's 48: scenery, objects and
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; quest things; the builder fills them
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; from the top down, the quest things go
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; in from the bottom up
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
ROOM_SECOND:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; The second from the top
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
ROOM_FIRST:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; The first the builder fills
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; (BUILD_ROOM)
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;

; Update routines, by graphic
;
; A word per graphic number: the routine the main loop runs for each object,
; every turn (START). It is entered with IX on the object's record and with
; OBJECT_DONE on the stack, so it ends with a plain RET, and it can change the
; object's graphic -- and so the routine it gets next turn -- to animate it.
; Many graphics share one; NOTHING, a RET, is for what does nothing, the empty
; record's graphic 0 among them.
UPDATES:
  DEFW NOTHING            ; Graphic 0
  DEFW NOTHING            ; Graphic 1
  DEFW NOTHING            ; Graphic 2
  DEFW NOTHING            ; Graphic 3
  DEFW NOTHING            ; Graphic 4
  DEFW NOTHING            ; Graphic 5
  DEFW FIRST_PILLAR       ; Graphic 6
  DEFW SECOND_PILLAR      ; Graphic 7
  DEFW FIRST_PILLAR       ; Graphic 8
  DEFW SECOND_PILLAR      ; Graphic 9
  DEFW JUMP_L16_D8        ; Graphic 10
  DEFW JUMP_L16_D8        ; Graphic 11
  DEFW DRAW_AT_L8_D2      ; Graphic 12
  DEFW DRAW_AT_L8_D2      ; Graphic 13
  DEFW DRAW_AT_L8_D2      ; Graphic 14
  DEFW DRAW_AT_L8_D2      ; Graphic 15
  DEFW ROAMER             ; Graphic 16
  DEFW ROAMER             ; Graphic 17
  DEFW NOTHING            ; Graphic 18
  DEFW NOTHING            ; Graphic 19
  DEFW NOTHING            ; Graphic 20
  DEFW NOTHING            ; Graphic 21
  DEFW NOTHING            ; Graphic 22
  DEFW STILL_DEADLY       ; Graphic 23
  DEFW NOTHING            ; Graphic 24
  DEFW NOTHING            ; Graphic 25
  DEFW NOTHING            ; Graphic 26
  DEFW NOTHING            ; Graphic 27
  DEFW SPIKES             ; Graphic 28
  DEFW NOTHING            ; Graphic 29
  DEFW STILL_DEADLY       ; Graphic 30
  DEFW NOTHING            ; Graphic 31
  DEFW PLAYER_LEGS        ; Graphic 32
  DEFW PLAYER_LEGS        ; Graphic 33
  DEFW PLAYER_LEGS        ; Graphic 34
  DEFW PLAYER_LEGS        ; Graphic 35
  DEFW PLAYER_LEGS        ; Graphic 36
  DEFW PLAYER_LEGS        ; Graphic 37
  DEFW PLAYER_LEGS        ; Graphic 38
  DEFW PLAYER_LEGS        ; Graphic 39
  DEFW PLAYER_TOP         ; Graphic 40
  DEFW PLAYER_TOP         ; Graphic 41
  DEFW PLAYER_TOP         ; Graphic 42
  DEFW PLAYER_TOP         ; Graphic 43
  DEFW PLAYER_TOP         ; Graphic 44
  DEFW PLAYER_TOP         ; Graphic 45
  DEFW PLAYER_TOP         ; Graphic 46
  DEFW PLAYER_TOP         ; Graphic 47
  DEFW HOMER              ; Graphic 48
  DEFW HOMER              ; Graphic 49
  DEFW HOMER              ; Graphic 50
  DEFW HOMER              ; Graphic 51
  DEFW DRAW_AT_L8_D2      ; Graphic 52
  DEFW DRAW_AT_L8_D4      ; Graphic 53
  DEFW DRAW_AT_L8_D4      ; Graphic 54
  DEFW DRAW_AT_L8_D4      ; Graphic 55
  DEFW DRAW_AT_L8_D4      ; Graphic 56
  DEFW DRAW_AT_L8         ; Graphic 57
  DEFW NOTHING            ; Graphic 58
  DEFW NOTHING            ; Graphic 59
  DEFW BOLT               ; Graphic 60
  DEFW NOTHING            ; Graphic 61
  DEFW NOTHING            ; Graphic 62
  DEFW PUSHABLE           ; Graphic 63
  DEFW PUFF               ; Graphic 64
  DEFW PUFF               ; Graphic 65
  DEFW PUFF               ; Graphic 66
  DEFW PUFF               ; Graphic 67
  DEFW PUFF               ; Graphic 68
  DEFW PUFF               ; Graphic 69
  DEFW PUFF               ; Graphic 70
  DEFW END_PUFF           ; Graphic 71
  DEFW PUSHABLE           ; Graphic 72
  DEFW SLIDING_TABLE      ; Graphic 73
  DEFW STILL_DEADLY       ; Graphic 74
  DEFW STILL_DEADLY       ; Graphic 75
  DEFW JUMP_L16_D8        ; Graphic 76
  DEFW JUMP_L16_D12       ; Graphic 77
  DEFW SINKING_BLOCK      ; Graphic 78
  DEFW PUSHABLE           ; Graphic 79
  DEFW SKY_ROAMER         ; Graphic 80
  DEFW SKY_ROAMER         ; Graphic 81
  DEFW JUMP_L16_D8        ; Graphic 82
  DEFW NOTHING            ; Graphic 83
  DEFW LIFT               ; Graphic 84
  DEFW BOBBER             ; Graphic 85
  DEFW DEADLY_BOBBER      ; Graphic 86
  DEFW PACER_U            ; Graphic 87
  DEFW PACER_V            ; Graphic 88
  DEFW SPIDER             ; Graphic 89
  DEFW BUCKET             ; Graphic 90
  DEFW HEAVY_BLOCK        ; Graphic 91
  DEFW DEADLY_PACER_U     ; Graphic 92
  DEFW DEADLY_PACER_V     ; Graphic 93
  DEFW NOTHING            ; Graphic 94
  DEFW NOTHING            ; Graphic 95
  DEFW NOTHING            ; Graphic 96
  DEFW NOTHING            ; Graphic 97
  DEFW NOTHING            ; Graphic 98
  DEFW NOTHING            ; Graphic 99
  DEFW NOTHING            ; Graphic 100
  DEFW NOTHING            ; Graphic 101
  DEFW NOTHING            ; Graphic 102
  DEFW NOTHING            ; Graphic 103
  DEFW NOTHING            ; Graphic 104
  DEFW NOTHING            ; Graphic 105
  DEFW NOTHING            ; Graphic 106
  DEFW NOTHING            ; Graphic 107
  DEFW NOTHING            ; Graphic 108
  DEFW NOTHING            ; Graphic 109
  DEFW NOTHING            ; Graphic 110
  DEFW NOTHING            ; Graphic 111
  DEFW QUEST_ITEM         ; Graphic 112
  DEFW QUEST_ITEM         ; Graphic 113
  DEFW QUEST_ITEM         ; Graphic 114
  DEFW QUEST_ITEM         ; Graphic 115
  DEFW QUEST_ITEM         ; Graphic 116
  DEFW QUEST_ITEM         ; Graphic 117
  DEFW QUEST_ITEM         ; Graphic 118
  DEFW QUEST_ITEM         ; Graphic 119
  DEFW WELL               ; Graphic 120
  DEFW PENTAGRAM_PIECE    ; Graphic 121
  DEFW PENTAGRAM_PIECE    ; Graphic 122
  DEFW PENTAGRAM_PIECE    ; Graphic 123
  DEFW PENTAGRAM_PIECE    ; Graphic 124
  DEFW PENTAGRAM_PIECE    ; Graphic 125
  DEFW PENTAGRAM_PIECE    ; Graphic 126
  DEFW PENTAGRAM_PIECE    ; Graphic 127
  DEFW PENTAGRAM_PIECE    ; Graphic 128
  DEFW PENTAGRAM_PIECE    ; Graphic 129
  DEFW PENTAGRAM_PIECE    ; Graphic 130
  DEFW PENTAGRAM_PIECE    ; Graphic 131
  DEFW PENTAGRAM_PIECE    ; Graphic 132
  DEFW PENTAGRAM_PIECE    ; Graphic 133
  DEFW PENTAGRAM_PIECE    ; Graphic 134
  DEFW PENTAGRAM_PIECE    ; Graphic 135
  DEFW CRUMBLING_BLOCK    ; Graphic 136
  DEFW CRUMBLING_BLOCK    ; Graphic 137
  DEFW CRUMBLING_BLOCK    ; Graphic 138
  DEFW CRUMBLING_BLOCK    ; Graphic 139
  DEFW CONVEYOR_PLUS_U    ; Graphic 140
  DEFW CONVEYOR_MINUS_U   ; Graphic 141
  DEFW CONVEYOR_PLUS_V    ; Graphic 142
  DEFW CONVEYOR_MINUS_V   ; Graphic 143
  DEFW COLLECTABLE        ; Graphic 144
  DEFW COLLECTABLE        ; Graphic 145
  DEFW COLLECTABLE        ; Graphic 146
  DEFW COLLECTABLE        ; Graphic 147
  DEFW COLLECTABLE        ; Graphic 148
  DEFW BOLT               ; Graphic 149
  DEFW BOLT               ; Graphic 150
  DEFW BOLT               ; Graphic 151
  DEFW JUMP_L16_D8        ; Graphic 152
  DEFW JUMP_L16_D8        ; Graphic 153
  DEFW JUMP_L16_D8        ; Graphic 154
  DEFW JUMP_L16_D8        ; Graphic 155
  DEFW JUMP_L16_D8        ; Graphic 156
  DEFW JUMP_L16_D8        ; Graphic 157
  DEFW JUMP_L16_D8        ; Graphic 158
  DEFW JUMP_L16_D8        ; Graphic 159
  DEFW HOMER              ; Graphic 160
  DEFW HOMER              ; Graphic 161
  DEFW HOMER              ; Graphic 162
  DEFW HOMER              ; Graphic 163
  DEFW HOMER              ; Graphic 164
  DEFW HOMER              ; Graphic 165
  DEFW HOMER              ; Graphic 166
  DEFW HOMER              ; Graphic 167
  DEFW SKY_WALKER         ; Graphic 168
  DEFW SKY_WALKER         ; Graphic 169
  DEFW SKY_WALKER         ; Graphic 170
  DEFW SKY_WALKER         ; Graphic 171

; Start the game
;
; Used by the routine at ENTRY.
;
; Reached from ENTRY when the game has loaded. Clears the variables and the
; object records, and then does what every game does: clears the screen, builds
; the drawing tables (MAKE_TABLES), gives five lives, stirs the random number,
; and runs the menu (MENU) until 0 is pressed. Then the tune a game starts
; with, the quest's records afresh with the collectables placed (NEW_QUEST),
; and a start room chosen (CHOOSE_START).
;
; From there it is three loops, one inside another. RESTART starts a life:
; RESTART_PLAYER copies the player template over his two records and takes a
; life, and ends the game when there are none. GAME_LOOP enters a room: it
; files the quest things of the room being left back in their records, builds
; the room he is in (ENTER_ROOM), puts the quest things that are there into it,
; decides whether anything may fall from the sky there, prints the score and
; sets the drop timer. EXIT_LOW_U jumps back to it when he walks through a
; doorway. MAIN_LOOP is a turn: a chance of something falling, then every one
; of the 54 object records' update routines in turn, and OBJECT_DONE, which
; ends the turn, draws what changed and goes round again.
;
; Each object's update routine is found in UPDATES by its graphic and entered
; by a jump, with the address of OBJECT_DONE pushed first so that it ends with
; a RET. Unlike Knight Lore's loop, this one does not reset the stack pointer
; for each object: the routines keep the stack straight themselves.
START:
  XOR A                   ; A black border, and the speaker off
  OUT ($FE),A             ;
  LD HL,CONTROL           ; Clear the variables and all 54 object records, up
  LD BC,$0726             ; to the update table
  CALL CLEAR_MEMORY       ;
; This entry point is used by the routine at WON.
AFTER_GAME:
  LD HL,BUCKET_OUT        ; After a game (WON): the same from BUCKET_OUT on,
  LD BC,$0721             ; which keeps the control method, the menu's bytes
  CALL CLEAR_MEMORY       ; and the random number
  CALL CLEAR_SCREEN       ; Clear the screen
  LD A,$43                ; Bright magenta ink on black, the whole screen
  CALL FILL_ATTRS         ;
  CALL MAKE_TABLES        ; The shift tables and the bit reversal table
  LD A,$05                ; Five lives: the first start of a life takes one
  LD (LIVES),A            ;
  LD A,R                  ; Stir R into the random number, which then decides
  LD B,A                  ; the rest
  LD A,(RANDOM)           ;
  ADD A,B                 ;
  LD (RANDOM),A           ;
  CALL MENU               ; The menu, until 0 is pressed
  LD DE,TUNE_START        ; The tune a game starts with
  CALL PLAY_TUNE          ;
  CALL NEW_QUEST          ; The quest records afresh, and the collectables'
                          ; starting spots
  CALL CHOOSE_START       ; One of four start rooms, into the player template
; This entry point is used by the routine at OBJECT_DONE.
RESTART:
  CALL RESTART_PLAYER     ; Start a life: the player template over both his
                          ; records, and a life fewer; with none left the game
                          ; is over
; This entry point is used by the routine at EXIT_LOW_U.
GAME_LOOP:
  CALL QUEST_OUT_OF_ROOM  ; Enter a room: first the quest things of the room he
                          ; was in go back to their records
  CALL ENTER_ROOM         ; Build the room he is now in
  CALL QUEST_INTO_ROOM    ; Put the quest things that are in it into the room's
                          ; records
  CALL BAN_DROPS          ; Nothing falls from the sky in a room with the well,
                          ; a quest item or a piece of the pentagram
  CALL PRINT_SCORE        ; The score, and its heading
  CALL RESET_DROP_TIMER   ; Turns until something may fall
; This entry point is used by the routine at OBJECT_DONE.
MAIN_LOOP:
  CALL SKY_DROP           ; A turn: first, perhaps, something falls from the
                          ; sky
  LD IX,OBJECTS           ; IX on the first record, the player's legs
; This entry point is used by the routine at OBJECT_DONE.
NEXT_OBJECT:
  LD HL,OBJECT_DONE       ; The update routine returns to OBJECT_DONE
  PUSH HL                 ;
  LD BC,UPDATES           ; The update routines
  LD A,(IX+$18)           ; Keep last turn's drawn width, height and position
  LD (IX+$1C),A           ; in +1C to +1F, so the old picture can be wiped
  LD A,(IX+$19)           ;
  LD (IX+$1D),A           ;
  LD A,(IX+$1A)           ;
  LD (IX+$1E),A           ;
  LD A,(IX+$1B)           ;
  LD (IX+$1F),A           ;
UPDATE_OBJECT:
  LD L,(IX+$00)           ; The graphic is the index
; This entry point is used by the routines at SORT_AND_DRAW, CALC_PLYR_DUV and
; HANDLE_EXIT_SCREEN.
JUMP_TO_TBL_ENTRY:
  LD H,$00                ; HL = BC + 2 * L: a word in a table of routines.
  ADD HL,HL               ; SORT_AND_DRAW, CALC_PLYR_DUV and HANDLE_EXIT_SCREEN
  ADD HL,BC               ; jump in here with tables of their own
  LD A,(HL)               ; Load the address, and go
  INC HL                  ;
  LD H,(HL)               ;
  LD L,A                  ;
  JP (HL)                 ;

; One object done; at the end of a turn, draw and wait
;
; Every update routine returns here. It stirs R into the random number -- R
; counts instructions, so the numbers depend on how long each update took --
; and moves IX to the next record, going back to START until all 54 have had
; their turn.
;
; Then the turn is finished. The turn counter goes up, the objects to be drawn
; are listed (LIST_DRAWN), and RENDER_DYNAMIC_OBJECTS wipes what moved, draws
; the objects in depth order and copies the changes to the screen. SPACE or
; CAPS SHIFT on its own pauses (PAUSE). Then it burns whatever time is left, so
; that the game runs at an even speed: it waits six units less the turn's
; drawing work (DRAW_WORK, CONTROL), which SORT_AND_DRAW and
; RENDER_DYNAMIC_OBJECTS count in objects drawn and areas wiped. A unit is 1280
; turns of a 26 T-state loop, about 33,300 T-states, just under half a frame.
; So a room where fewer than six things change runs as fast as one where six
; do, and a busier one runs slower: the wait can only pad, never take time
; back.
;
; On the first turn in a room the whole screen is redrawn: the room's colour
; over every attribute, the carried things, the panel, the lives and the score,
; and the whole buffer copied to the screen, with a short sound. Last, if both
; of the player's records are empty -- they become so when his dying is over --
; a life is lost; otherwise the next turn.
OBJECT_DONE:
  LD A,R                  ; Stir R, the turn counter's low byte plus one, and
  LD B,A                  ; the ROM byte at that address into the random number
  LD A,(TURNS)            ;
  INC A                   ;
  LD H,$00                ;
  LD L,A                  ;
  ADD A,(HL)              ;
  ADD A,B                 ;
  LD B,A                  ;
  LD A,(RANDOM)           ;
  ADD A,B                 ;
  LD (RANDOM),A           ;
  LD DE,$0020             ; 32 bytes a record
  ADD IX,DE               ;
  PUSH IX                 ; Round again until IX reaches the update table, just
  POP HL                  ; past the last record
  LD DE,UPDATES           ;
  AND A                   ;
  SBC HL,DE               ;
  JP C,NEXT_OBJECT        ;
  LD HL,(TURNS)           ; The turn is over: count it
  INC HL                  ;
  LD (TURNS),HL           ;
  CALL LIST_DRAWN         ; List the records flagged to be drawn
  CALL RENDER_DYNAMIC_OBJECTS ; Wipe what moved, draw in depth order into the
                              ; buffer, and copy the changes to the screen
  LD (MAIN_SP),SP         ; Kept, and never read back
  CALL PAUSE              ; SPACE or CAPS SHIFT on its own pauses
  LD A,(DRAW_WORK)        ; Six units, less what the turn's drawing already
  NEG                     ; used
  ADD A,$06               ;
  LD B,A                  ;
  JP M,OBJECT_DONE_2      ; None left to wait
  JR Z,OBJECT_DONE_2      ;
OBJECT_DONE_0:
  LD HL,$0500             ; One unit: 1280 turns of 26 T-states
OBJECT_DONE_1:
  DEC HL                  ;
  LD A,L                  ;
  OR H                    ;
  JR NZ,OBJECT_DONE_1     ;
  DJNZ OBJECT_DONE_0      ; The next unit
OBJECT_DONE_2:
  LD A,(NEW_ROOM)         ; Not the first turn in the room: on to the sound
  AND A                   ;
  JR Z,OBJECT_DONE_3      ;
  XOR A                   ; Once only
  LD (NEW_ROOM),A         ;
  LD A,(ROOM_ATTR)        ; The room's colour over the whole screen
  CALL FILL_ATTRS         ;
  CALL SHOW_CARRIED_NOW   ; The three things he carries
  CALL DISPLAY_PANEL      ; The panel's artwork
  CALL DRAW_LIVES         ; The lives icon, and the lives
  CALL SHOW_BUFFER        ; The whole buffer to the screen
  CALL PRINT_SCORE        ; The score, and its heading
  CALL CLEAR_COPY_BITS    ; Nothing drawn so far needs wiping: bit 5 of every
                          ; record's flags cleared
  LD HL,$0004             ; The sound of arriving: sound 0, for four turns
  LD (SOUND_COUNT),HL     ;
OBJECT_DONE_3:
  CALL EFFECT_NOTE        ; A turn of the sound effect under way
  LD IX,OBJECTS           ; Both his records empty: a life is lost
  LD A,(IX+$00)           ;
  OR (IX+$20)             ;
  JP Z,RESTART            ;
  JP MAIN_LOOP            ; The next turn

; Put the quest things in this room into the object records
;
; Used by the routine at START.
;
; The quest things -- the four quest items, the five collectables, the eight
; pieces of the pentagram and the bucket -- are not in the room directory. They
; live in 18 records of 16 bytes at QUEST_RECORDS, each with its room at +8,
; and are copied into the object records when he enters a room, after the room
; is built (START). QUEST_OUT_OF_ROOM copies them back when he leaves.
;
; Each thing in this room goes into the lowest free record of the room's 48,
; with its flag to be drawn set, the address of its quest record in +10 and
; +11, and the rest of the record zeroed. Two exceptions: the pieces of the
; pentagram stay out until all four quest items are done (PENTAGRAM_ON,
; CONTROL), and anything but a piece is lifted 12 at a time until it overlaps
; nothing (DO_ANY_OBJS_INTERSECT), so that it stands on whatever it was left on
; top of -- in the sessions the lift never ran; poked in, a quest item put
; where a hazard stands came in 12 higher (measured). With no free record left
; it gives up on the rest.
QUEST_INTO_ROOM:
  LD IY,QUEST_START_BUCKET ; IY 16 bytes before the live quest records, since
  LD B,$12                 ; the loop adds 16 before it looks; 18 records
QUEST_INTO_ROOM_0:
  LD DE,$0010             ; C = the room he is in
  LD A,(PLAYER_ROOM)      ;
  LD C,A                  ;
QUEST_INTO_ROOM_1:
  ADD IY,DE               ; The next record; graphic 0 has nothing to place: a
  LD A,(IY+$00)           ; thing being carried, or the bucket before the well
  AND A                   ; gives it
  JR Z,QUEST_INTO_ROOM_2  ;
  LD A,(IY+$08)           ; In this room?
  CP C                    ;
  JR Z,QUEST_INTO_ROOM_3  ;
QUEST_INTO_ROOM_2:
  DJNZ QUEST_INTO_ROOM_1  ; No: the next
  RET                     ;
QUEST_INTO_ROOM_3:
  LD HL,ROOM_OBJECTS      ; Find the lowest empty record of the room's 48
  LD DE,$0020             ;
  PUSH BC                 ;
  LD B,$30                ;
QUEST_INTO_ROOM_4:
  LD A,(HL)               ;
  AND A                   ;
  JR Z,QUEST_INTO_ROOM_5  ;
  ADD HL,DE               ;
  DJNZ QUEST_INTO_ROOM_4  ;
  POP BC                  ; None free: give up
  RET                     ;
QUEST_INTO_ROOM_5:
  EX DE,HL                ; DE = the free record
  LD A,(IY+$00)           ; A piece of the pentagram (graphics 128 to 135)
  AND $F8                 ; stays out until all four quest items are done
  CP $80                  ;
  JR NZ,QUEST_INTO_ROOM_6 ;
  LD A,(PENTAGRAM_ON)     ;
  AND A                   ;
  JR Z,QUEST_INTO_ROOM_9  ;
QUEST_INTO_ROOM_6:
  SET 4,(IY+$07)          ; To be drawn: set in the quest record itself, so the
                          ; copy carries it
  PUSH IY                 ; The quest record's 16 bytes into the object record
  POP HL                  ;
  LD BC,$0010             ;
  LDIR                    ;
  PUSH IY                 ; Its address into +10 and +11, so the thing can find
  POP HL                  ; its record again
  EX DE,HL                ;
  LD (HL),E               ;
  INC HL                  ;
  LD (HL),D               ;
  INC HL
  LD B,$0E                ; +12 to +1F zeroed
  XOR A                   ;
QUEST_INTO_ROOM_7:
  LD (HL),A               ;
  INC HL                  ;
  DJNZ QUEST_INTO_ROOM_7  ;
  LD DE,$FFE0             ; IX = the record: back 32 from its end
  ADD HL,DE               ;
  PUSH HL                 ;
  POP IX                  ;
  LD A,(IX+$00)           ; A piece of the pentagram lies where it is
  AND $F8                 ;
  CP $80                  ;
  JR Z,QUEST_INTO_ROOM_9  ;
QUEST_INTO_ROOM_8:
  CALL DO_ANY_OBJS_INTERSECT ; Anything else: does it overlap something?
  JR NC,QUEST_INTO_ROOM_9    ;
  LD A,(IX+$03)           ; Yes: lift it 12 and try again
  ADD A,$0C               ;
  LD (IX+$03),A           ;
  JR QUEST_INTO_ROOM_8    ;
QUEST_INTO_ROOM_9:
  POP BC                  ; The next quest record
  DJNZ QUEST_INTO_ROOM_0  ;
  RET                     ;

; Copy the quest things in the room back to their records
;
; Used by the routine at START.
;
; Runs as a room is entered, before the room is built over the records (START),
; so it sees the room being left. Every one of the room's 48 records is looked
; up by its graphic among the 18 quest records at QUEST_RECORDS, and where one
; matches, the object's first 16 bytes -- where it is now, its sizes, its flags
; and its room -- are copied back over the quest record. A quest thing that
; moved or was pushed in a room is found there again.
;
; The match is by graphic, not by the address kept at +10: a quest thing's
; graphic is unique among them, and CHANGE_GRAPHIC changes the quest record's
; graphic along with the object's when a quest item is done. An empty record's
; graphic 0 matches the record of a thing being carried, whose graphic is
; zeroed while he has it (TAKE_OR_LEAVE), and copies the empty record's
; leftovers over it; that does no harm, since the graphic stays 0 and putting
; the thing down writes it back.
QUEST_OUT_OF_ROOM:
  LD IY,FLYER_SECOND      ; IY a record before the room's first; 48 records
  LD C,$30                ;
QUEST_OUT_OF_ROOM_0:
  LD DE,$0020             ; The next record
  ADD IY,DE               ;
  LD A,(IY+$00)           ; Its graphic
  LD HL,QUEST_RECORDS     ; Against each of the 18 quest records' graphics
  LD DE,$0010             ;
  LD B,$12                ;
QUEST_OUT_OF_ROOM_1:
  CP (HL)                  ; This one?
  JR Z,QUEST_OUT_OF_ROOM_3 ;
  ADD HL,DE                ;
  DJNZ QUEST_OUT_OF_ROOM_1 ;
QUEST_OUT_OF_ROOM_2:
  DEC C                     ; The next object
  JR NZ,QUEST_OUT_OF_ROOM_0 ;
  RET                       ;
QUEST_OUT_OF_ROOM_3:
  EX DE,HL                ; Found: the object's first 16 bytes back over the
  PUSH IY                 ; quest record
  POP HL                  ;
  PUSH BC                 ;
  LD BC,$0010             ;
  LDIR                    ;
  POP BC                  ; On to the next object
  LD DE,$0020             ;
  JR QUEST_OUT_OF_ROOM_2  ;

; Copy the score to the screen
;
; Used by the routine at SHOOT_DOWN.
;
; ADD_SCORE prints the score's six digits into the buffer; this copies them to
; the screen: six bytes wide and eight rows high, from pixel x 184, y 9. Used
; when something shot scores (SHOOT_DOWN).
SHOW_SCORE:
  LD BC,$09B8             ; The bottom left of the digits: DE its display
  CALL CALC_VRAM_ADDR     ; address, BC its buffer address
  CALL CALC_VIDBUF_ADDR   ;
  LD H,B                  ; HL the buffer; eight rows
  LD L,C                  ;
  LD C,$08                ;
SHOW_SCORE_0:
  PUSH BC                 ; A row: six bytes
  PUSH DE                 ;
  LD BC,$0006             ;
  LDIR                    ;
  POP DE                  ; Up a display line: DEC D is enough unless the line
  DEC D                   ; crossed into the character row above
  LD A,D                  ;
  CPL                     ;
  AND $07                 ;
  JR NZ,SHOW_SCORE_1      ; Crossing a character row: back 32 in E, and back
  LD A,E                  ; into this third unless that borrowed
  SUB $20                 ;
  LD E,A                  ;
  JR C,SHOW_SCORE_1       ;
  LD A,D                  ;
  ADD A,$08               ;
  LD D,A                  ;
SHOW_SCORE_1:
  POP BC                  ; The buffer row above: 26 more after the six copied
  LD A,L                  ;
  ADD A,$1A               ;
  LD L,A                  ;
  LD A,H                  ;
  ADC A,$00               ;
  LD H,A                  ;
  DEC C                   ; The next row
  JR NZ,SHOW_SCORE_0      ;
  RET                     ;

; Copy the screen buffer to the screen
;
; Used by the routines at OBJECT_DONE, DISPLAY_MENU and WON.
;
; All 192 rows of 32 bytes from BUFFER. The buffer runs the other way up from
; the display -- its first row is the bottom line of the screen -- because the
; game's pixel y counts up from the bottom; so the copy starts at the display's
; bottom-left byte and works up a line at a time. Used on the first turn in a
; room (OBJECT_DONE) and for the text screens (DISPLAY_MENU, WON). Knight
; Lore's copy clears the buffer as it goes; this one leaves it as it is.
SHOW_BUFFER:
  LD HL,BUFFER            ; From the buffer's first row to the display's bottom
  LD DE,$57E0             ; line; 192 rows
  LD C,$C0                ;
SHOW_BUFFER_0:
  PUSH BC                 ; A row of 32 bytes; HL runs on to the next row by
  PUSH DE                 ; itself
  LD BC,$0020             ;
  LDIR                    ;
  POP DE                  ; Up a display line, unless that crossed a character
  DEC D                   ; row
  LD A,D                  ;
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
  DEC C                   ;
  JR NZ,SHOW_BUFFER_0     ;
  RET                     ;

; Redraw what changed and copy it to the screen
;
; Used by the routine at OBJECT_DONE.
;
; Called at the end of every turn (OBJECT_DONE). The list at DRAW_LIST holds
; every record flagged to be drawn this turn (LIST_DRAWN). First, for each one
; that moved -- bit 5 of its flags -- the area covering both where it was drawn
; last turn (+1C to +1F) and where it is now (+18 to +1B) is cleared in the
; buffer and remembered on the stack. Then every listed object is drawn into
; the buffer in depth order (SORT_AND_DRAW), and the carried things on the
; panel if they changed (SHOW_CARRIED); and last the remembered areas -- and
; only those -- are copied to the screen.
;
; Nothing is ever rubbed out on the screen itself, so nothing flickers; the
; scenery is made of objects too, so what stood behind a moving thing is simply
; drawn again. On the first turn in a room nothing is wiped at all: the buffer
; is freshly built and OBJECT_DONE copies all of it. The areas count towards
; the turn's drawing work (DRAW_WORK, CONTROL), which sets how long the main
; loop waits.
RENDER_DYNAMIC_OBJECTS:
  XOR A                   ; No areas yet
  LD (WIPE_COUNT),A       ;
  PUSH IX                 ; Kept for the caller
  LD A,(NEW_ROOM)                ; The first turn in a room: nothing to wipe
  AND A                          ;
  JP NZ,RENDER_DYNAMIC_OBJECTS_8 ;
  LD HL,DRAW_LIST         ; From the start of the list
  LD (LIST_POINTER),HL    ;
RENDER_DYNAMIC_OBJECTS_0:
  LD HL,(LIST_POINTER)          ; The next record's number; $FF ends the list
  LD A,(HL)                     ;
  INC HL                        ;
  LD (LIST_POINTER),HL          ;
  CP $FF                        ;
  JP Z,RENDER_DYNAMIC_OBJECTS_8 ;
  CALL RECORD_OF          ; IX = the record
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
  XOR A                   ; Cleared in the buffer: FILL_RECT fills B bytes by C
  CALL FILL_RECT          ; rows with A
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
  CALL BLIT_TO_SCREEN     ; Copy it to the screen
  JR RENDER_DYNAMIC_OBJECTS_9 ; The next
RENDER_DYNAMIC_OBJECTS_10:
  POP IX                  ; Done
  RET                     ;

; Copy a rectangle of the buffer to the screen
;
; Used by the routines at RENDER_DYNAMIC_OBJECTS and SHOW_CARRIED.
;
; Works up the screen a row at a time, as SHOW_BUFFER does, for the areas
; RENDER_DYNAMIC_OBJECTS wiped and for the carried things on the panel
; (SHOW_CARRIED). The same as Knight Lore's.
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
  RET                     ;

; Build the drawing tables
;
; Used by the routine at START.
;
; Fills the fifteen pages from REVERSED up with tables the sprite drawing needs
; every turn, run at every new game (START).
;
; The fourteen from SHIFTED7 up are the shifted bytes, in pairs: for each shift
; s from 1 to 7, page $F0 + 2s holds every byte value shifted right s places,
; and the page above it the bits that fall out into the next byte. Both are
; stored complemented, so that one value both clears the screen under a
; sprite's mask and lets its image in. The loop builds them the other way
; about: it shifts each value left across two bytes, one place at a time, and
; stores the pair after each shift from the top page down, so shift s is the
; value shifted left 8 - s.
;
; REVERSED itself is every byte value with its bits in the opposite order,
; which is how a sprite is mirrored (FIND_SPRITE). The layout is Knight Lore's.
MAKE_TABLES:
  LD L,$00                ; Every byte value, L from 0
MAKE_TABLES_0:
  LD D,$00                ; DE = the value; H on the top page; seven shifts
  LD E,L                  ;
  LD H,$FF                ;
  LD B,$07                ;
MAKE_TABLES_1:
  SLA E                   ; One more place left across D and E
  RL D                    ;
  LD A,E                  ; E complemented, on this page
  CPL                     ;
  LD (HL),A               ;
  DEC H                   ; D complemented, on the page below
  LD A,D                  ;
  CPL                     ;
  LD (HL),A               ;
  DEC H                   ;
  DJNZ MAKE_TABLES_1      ; The next shift
  INC L                   ; The next value, until L wraps to 0
  JR NZ,MAKE_TABLES_0     ;
  LD HL,REVERSED          ; Then the bit reversal
MAKE_TABLES_2:
  LD D,L                  ; Eight bits out of the bottom of D into the bottom
  LD B,$08                ; of E: E is the value reversed
MAKE_TABLES_3:
  SRL D                   ;
  RL E                    ;
  DJNZ MAKE_TABLES_3      ;
  LD (HL),E               ; Store it; the next value, until L wraps to 0
  INC L                   ;
  JR NZ,MAKE_TABLES_2     ;
  RET                     ;

; Project an object's position onto the screen
;
; Used by the routines at DRAW_OBJECT, CALC_2D_INFO, TAKE_OR_LEAVE, SKY_DROP
; and WELL.
;
; The isometric projection. U, V and Z (+1 to +3) become a pixel x in +1A and a
; pixel y in +1B, counted up from the bottom of the screen: pixel x = U + V -
; 128, and pixel y = (V - U + 128) / 2 + Z - 104, each with the drawing nudge
; (+12, +13) added.
;
; Knight Lore's, with one addition: a picture whose x would come out below 0 is
; drawn from x 0. That rests on every nudge being negative -- adding one to an
; x that stays on the screen carries -- and so an object with a nudge of 0
; would always be drawn at x 0. The update routines set the nudges, through the
; short routines from DRAW_AT_L8 on; in room 100, measured, all 38 records in
; use had negative nudges.
;
;   IX the object
; O:F carry set if the pixel y is below 192, that is on the screen
CALC_PIXEL_XY:
  LD A,(IX+$01)           ; U + V - 128
  ADD A,(IX+$02)          ;
  SUB $80                 ;
  ADD A,(IX+$12)          ; Plus the nudge: no carry means it went below 0, so
  JR C,CALC_PIXEL_XY_0    ; 0
  XOR A                   ;
CALC_PIXEL_XY_0:
  LD (IX+$1A),A           ; Pixel x
  LD A,(IX+$02)           ; (V - U + 128) / 2 + Z - 104
  SUB (IX+$01)            ;
  ADD A,$80               ;
  SRL A                   ;
  ADD A,(IX+$03)          ;
  SUB $68                 ;
  ADD A,(IX+$13)          ; Plus the nudge: pixel y
  LD (IX+$1B),A           ;
  CP $C0                  ; Carry set if it is on the screen
  RET                     ;

; Find an object's sprite, and turn it the way the object faces
;
; Used by the routines at DRAW_OBJECT and CALC_2D_INFO.
;
; The graphic (+0) indexes GRAPHICS for the sprite. A sprite whose first byte
; is 0 draws nothing: the routine then drops its own return address, so its RET
; leaves its caller too.
;
; Sprites are turned in place, and the width byte remembers which way round the
; data now is: bit 7 set while it is stored upside down, bit 6 while mirrored.
; Bits 7 and 6 of the object's flags (+7) say how it wants to be drawn. Where
; they disagree the data is turned and the sprite's bit toggled, so an object
; that keeps facing one way costs nothing after the first time, while two
; objects sharing a sprite and facing opposite ways turn it back and forth
; every time each is drawn.
;
; Upside down is done by swapping whole rows end for end; mirroring by
; reversing the order of each row's cells and the bits of every byte, through
; REVERSED. Knight Lore does the same in three routines; here they are one.
;
;   IX the object
; O:DE the sprite
FIND_SPRITE:
  LD L,(IX+$00)           ; DE = the sprite, from the graphic table
  LD H,$00                ;
  ADD HL,HL               ;
  LD BC,GRAPHICS          ;
  ADD HL,BC               ;
  LD E,(HL)               ;
  INC HL                  ;
  LD D,(HL)               ;
  LD A,(DE)               ; A real sprite
  AND A                   ;
  JR NZ,FIND_SPRITE_0     ;
  INC SP                  ; None: return from the caller as well
  INC SP                  ;
  RET                     ;
FIND_SPRITE_0:
  PUSH DE                 ; Kept
  LD A,(DE)               ; The sprite's bit 7 against the object's: the same
  XOR (IX+$07)            ; means no turning over
  AND $80                 ;
  JR Z,FIND_SPRITE_4      ;
  LD A,(DE)               ; Toggle the sprite's bit
  XOR $80                 ;
  LD (DE),A               ;
  RLCA                    ; B = bytes a row: the width in bits 0 to 3, times
  AND $1E                 ; two for the mask and image bytes
  LD B,A                  ;
  INC DE                  ; C = the height in rows; DE on the data
  LD A,(DE)               ;
  LD C,A                  ;
  INC DE                  ;
  PUSH BC                 ; HL = B * C, the data's length, plus the start: one
  PUSH DE                 ; past the end
  LD E,C                  ;
  LD D,$00                ;
  LD H,D                  ;
  LD L,D                  ;
FIND_SPRITE_1:
  ADD HL,DE               ;
  DJNZ FIND_SPRITE_1      ;
  POP DE                  ;
  POP BC                  ;
  ADD HL,DE               ;
  EX DE,HL                ; DE one past the end; HL one past the first row
  LD A,B                  ;
  CALL ADD_HL_A           ;
  DEC DE                  ; DE on the last byte of the last row, HL on the last
  DEC HL                  ; byte of the first
  SRL C                   ; Swap rows in pairs: half the height
FIND_SPRITE_2:
  PUSH BC                 ; Swap the two rows byte by byte, working backwards
FIND_SPRITE_3:
  LD A,(DE)               ;
  LD C,(HL)               ;
  LD (HL),A               ;
  LD A,C                  ;
  LD (DE),A               ;
  DEC HL                  ;
  DEC DE                  ;
  DJNZ FIND_SPRITE_3      ;
  POP BC                  ; HL on to the end of the next row down; DE is
  LD A,B                  ; already at the end of the row before its last
  CALL ADD_HL_A           ;
  LD A,B                  ;
  CALL ADD_HL_A           ;
  DEC C                   ; The next pair
  JR NZ,FIND_SPRITE_2     ;
FIND_SPRITE_4:
  POP DE                  ; The sprite's bit 6 against the object's
  PUSH DE                 ;
  LD A,(DE)               ;
  XOR (IX+$07)            ;
  AND $40                 ;
  JR Z,FIND_SPRITE_7      ;
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
FIND_SPRITE_5:
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
  DJNZ FIND_SPRITE_5      ;
  LD B,C                  ; Pop them back over the row: last first, so the
FIND_SPRITE_6:
  POP DE                  ; cells come back in the reverse order
  LD (HL),E               ;
  INC HL                  ;
  LD (HL),D               ;
  INC HL                  ;
  DJNZ FIND_SPRITE_6      ;
  EX AF,AF'               ; The next row, until the height runs out
  DEC A                   ;
  JR Z,FIND_SPRITE_7      ;
  EX AF,AF'               ;
  LD B,C                  ;
  JR FIND_SPRITE_5        ;
FIND_SPRITE_7:
  POP DE                  ; DE = the sprite
  RET                     ;

; Buffer address of a pixel position
;
; Used by the routines at SHOW_SCORE, RENDER_DYNAMIC_OBJECTS, DRAW_OBJECT,
; SHOW_CARRIED, ADD_SCORE, PRINT_TEXT_SINGLE_COLOUR and PERCENTAGE.
;
; The buffer is plain rows of 32 bytes, the bottom line first, so the address
; is y * 32 + x / 8 from its start: BC shifted right three times. HL is kept.
; The same as Knight Lore's.
;
;   C the pixel x
;   B the pixel y, counted up from the bottom of the screen
; O:BC the address in BUFFER
CALC_VIDBUF_ADDR:
  PUSH HL                 ; BC / 8 = y * 32 + x / 8
  SRL B                   ;
  RR C                    ;
  SRL B                   ;
  RR C                    ;
  SRL B                   ;
  RR C                    ;
  LD HL,BUFFER            ; Plus the start of the buffer
  ADD HL,BC               ;
  LD C,L                  ;
  LD B,H                  ;
  POP HL                  ;
  RET                     ;

; Display address of a pixel position
;
; Used by the routines at SHOW_SCORE, RENDER_DYNAMIC_OBJECTS and SHOW_CARRIED.
;
; Turns the game's upward y into the display's line counted from the top by
; complementing it: 255 - y is that line plus 64, one third of the screen too
; many in the top bits, which is taken back by adding 56 rather than 64 to the
; high byte. A' is changed. The same as Knight Lore's.
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
  LD A,B                  ; The line within the character row, from bits 0 to 2
  CPL                     ; of 255 - y, kept in A'
  AND $07                 ;
  EX AF,AF'               ;
  LD A,B                  ; Bits 3 to 5, the character row within the third,
  CPL                     ; into the top of E
  RLCA                    ;
  RLCA                    ;
  AND $E0                 ;
  OR E                    ;
  LD E,A                  ;
  LD A,B                  ; Bits 6 and 7, the third, with the line within the
  CPL                     ; row, and 56 for the extra third
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  AND $18                 ;
  LD D,A                  ;
  EX AF,AF'               ;
  OR D                    ;
  ADD A,$38               ;
  LD D,A                  ;
  RET                     ;

; Attribute address of a pixel position
;
; Used by the routines at SHOW_CARRIED and TEXT_ATTR_ADDR.
;
; HL is kept. The same as Knight Lore's.
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
  POP HL                  ;
  RET                     ;

; Draw one object from the draw list
;
; Used by the routine at DRAW_CANDIDATE.
;
; Called by the depth sort (DRAW_CANDIDATE) for each listed object in turn,
; back to front. Graphic 1 marks an object on its way out of the room's records
; -- TAKE_OR_LEAVE sets it on what is picked up, END_PUFF at the end of a puff
; -- and is not drawn: its record is emptied instead, which frees it. Anything
; else loses its draw flag (bit 4 of +$07), is projected onto the screen by
; CALC_PIXEL_XY, and is drawn by the entry point below unless its pixel y is
; 192 or more, wholly above the screen.
;
; The entry point DRAW_SPRITE draws whatever sprite IX's graphic names at the
; pixel position already in +$1A and +$1B, with no projection: SHOW_CARRIED
; draws the panel's carried things with it, and DRAW_LIVES the lives icon, both
; through the spare record at PANEL_RECORD.
;
; A sprite is a width byte (bits 0-3 the width in bytes, bits 6 and 7 how it is
; currently stored, flipped or not), a height byte, and then a mask byte and an
; image byte for each byte of each row, the bottom row first. Each buffer byte
; is cleared where the mask is set and has the image put in, so an object
; punches its own shape out of whatever was drawn behind it.
;
; The row loop is unrolled for the widest sprite, five bytes, twice: a plain
; run for a sprite whose pixel x is a multiple of 8 (SPRITE_ALIGNED_RUN), and a
; shifted run that reads its bytes through the mask tables from SHIFTED7 up and
; so touches one byte more per row (SPRITE_SHIFTED_RUN). This routine patches
; the offset of the JR in SPRITE_ROW to enter the right run as many units from
; its end as the sprite is wide, and the operand of the ADD at the foot of
; SPRITE_SHIFTED_RUN with the step from the end of one row to the start of the
; next. The stack pointer reads the sprite: SP is pointed at the data and each
; POP DE fetches a mask into E and its image into D, the real SP kept in
; SAVED_SP meanwhile. The game runs with interrupts off (only PAUSE turns them
; on, and only while paused), so nothing pushes onto the sprite.
;
; On the way out +$18 holds the width in bytes that was drawn (one more than
; the sprite's own when shifted) and +$19 the height, cut to the rows below the
; top of the screen; the main loop copies them to +$1C and +$1D before the next
; turn's update, so RENDER_DYNAMIC_OBJECTS knows what to rub out. Nothing is
; clipped at the sides or the bottom.
;
; IX the object
DRAW_OBJECT:
  LD A,(IX+$00)           ; graphic 1: empty the record instead
  CP $01                  ;
  JR NZ,DRAW_OBJECT_0     ;
  LD (IX+$00),$00         ;
  RET                     ;
DRAW_OBJECT_0:
  RES 4,(IX+$07)          ; drawn now: off the draw list's flag
  CALL CALC_PIXEL_XY      ; pixel position into +$1A and +$1B; above the
  RET NC                  ; screen, nothing to draw
; This entry point is used by the routines at SHOW_CARRIED,
; TRANSFER_SPRITE_AND_PRINT, MULTIPLE_PRINT_SPRITE and DRAW_LIVES.
DRAW_SPRITE:
  CALL FIND_SPRITE        ; DE = the sprite's width byte, the sprite turned the
                          ; way the object faces (FIND_SPRITE); an empty sprite
                          ; returns from here at once
  LD A,(IX+$1A)           ; the pixel x within its byte; 0 goes to the aligned
  AND $07                 ; case, SPRITE_ALIGNED
  JR Z,SPRITE_ALIGNED     ;
  RLCA                    ; H = $F0 + 2 * the shift: the page pair of
  AND $0E                 ; MAKE_TABLES's tables for that shift
  OR $F0                  ;
  LD H,A                  ;
  LD A,(DE)               ; the width from the header, plus one: the bytes a
  INC DE                  ; shifted row touches, into +$18
  AND $07                 ;
  INC A                   ;
  LD B,A                  ;
  LD (IX+$18),A           ;
  DEC A                   ; the JR's offset: 16 bytes of code per byte of
  AND $07                 ; width, back from the end of the shifted run at
  ADD A,A                 ; SPRITE_SHIFTED_RUN
  ADD A,A                 ;
  ADD A,A                 ;
  ADD A,A                 ;
  NEG                     ;
  ADD A,$50               ;
PATCH_SPRITE_ROWS:
  LD ($B47C),A            ; the offset, into the JR in SPRITE_ROW
  LD A,B                  ; the step to the next row, into the ADD at the foot
  CPL                     ; of SPRITE_SHIFTED_RUN: 33 less the bytes touched,
  ADD A,$22               ; since a row moves BC on one fewer than that
  LD ($B4D0),A            ;
  LD A,(DE)               ; the height, into +$19
  INC DE                  ;
  LD (IX+$19),A           ;
  ADD A,(IX+$1B)          ;
  SUB $C0                 ; if the sprite would run past the top of the screen,
  JR C,DRAW_SPRITE_ROWS   ; only the rows below it: 192 less the pixel y
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
  LD A,(DE)               ; the aligned case: the width from the header, into
  INC DE                  ; +$18
  AND $0F                 ;
  LD (IX+$18),A           ;
  LD B,A                  ; B = the bytes a row touches, the width itself
  ADD A,A                 ; the JR's offset: 8 bytes of code per byte of width,
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
;
; BC the buffer byte to start at
; SP the sprite's next mask and image bytes
; A' the rows left
SPRITE_ALIGNED_RUN:
  POP DE                  ; the first of five units
  LD A,(BC)               ;
  CPL                     ;
  OR E                    ;
  CPL                     ;
  OR D                    ;
  LD (BC),A               ;
  INC BC                  ;
  POP DE                  ; three more the same
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
  POP DE                  ; the fifth, without the INC BC
  LD A,(BC)               ;
  CPL                     ;
  OR E                    ;
  CPL                     ;
  OR D                    ;
  LD (BC),A               ;
  JP SPRITE_NEXT_ROW      ; on to the next row

; Start a row of a sprite
;
; Used by the routines at DRAW_OBJECT and SPRITE_SHIFTED_RUN.
;
; The row count goes to A', and A takes the first buffer byte: the shifted
; units of SPRITE_SHIFTED_RUN expect the byte they are finishing to be in A
; already. The JR's offset is patched by DRAW_OBJECT for every sprite, into the
; aligned run at SPRITE_ALIGNED_RUN or the shifted one at SPRITE_SHIFTED_RUN;
; as it stands in the listing, an offset of $FE, it is a JR to itself.
;
; A the rows left
; BC the buffer byte the row starts at
SPRITE_ROW:
  EX AF,AF'               ; the count to A'; the first buffer byte
  LD A,(BC)               ;
SPRITE_ROW_0:
  JR SPRITE_ROW_0         ; offset patched: into one of the unrolled runs

; The unrolled row of a shifted sprite
;
; Entered by the JR in SPRITE_ROW, as many 16-byte units from the end as the
; sprite is wide. H is the first of the two pages MAKE_TABLES built for this
; shift. The tables hold complements, so each byte is ANDed with the complement
; of the mask shifted, and XORed with the complement of the image shifted and
; complemented again -- which comes to the buffer byte cleared under the
; shifted mask with the shifted image put in. Page H gives the part of a mask
; or image byte that stays in the current buffer byte, which is finished and
; stored; page H + 1 the part that falls into the next, which is begun and left
; in A for the next unit. The byte the last unit begins is stored after the
; fifth.
;
; Then, for both runs, BC steps up to the next row by the amount patched into
; the ADD below, and the loop goes round until A' runs out. The real stack
; pointer comes back from SAVED_SP, and the RET is the return from DRAW_OBJECT.
;
; A the buffer byte the row starts with
; BC its address
; H the shift's first table page
; SP the sprite's next mask and image bytes
SPRITE_SHIFTED_RUN:
  POP DE                  ; the first unit: the buffer byte cleared under the
  LD L,E                  ; mask and with the image put in, shifted right, and
  AND (HL)                ; stored
  LD L,D                  ;
  XOR (HL)                ;
  CPL                     ;
  LD (BC),A               ;
  INC BC                  ;
  INC H                   ; the bits that fall out, into the next buffer byte,
  LD L,E                  ; left in A
  LD A,(BC)               ;
  AND (HL)                ;
  LD L,D                  ;
  XOR (HL)                ;
  CPL                     ;
  DEC H                   ;
  POP DE                  ; four more units the same
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
  LD (BC),A               ; store the last spilled byte
; This entry point is used by the routine at SPRITE_ALIGNED_RUN.
SPRITE_NEXT_ROW:
  LD A,C                  ; BC up a row: its operand patched by DRAW_OBJECT to
  ADD A,$00               ; 33 less the bytes a row touches
  LD C,A                  ;
  LD A,B                  ;
  ADC A,$00               ;
  LD B,A                  ;
  EX AF,AF'               ; the next row, until the height runs out
  DEC A                   ;
  JP NZ,SPRITE_ROW        ;
  LD SP,(SAVED_SP)        ; the real stack pointer back; return from
  RET                     ; DRAW_OBJECT

; Pause, when SPACE or CAPS SHIFT is pressed on its own
;
; Used by the routine at OBJECT_DONE.
;
; Called once a turn by the main loop (OBJECT_DONE). Half-rows $7F and $FE are
; read together, so bit 0 is SPACE or CAPS SHIFT and bits 1-4 are the other
; eight keys of the two rows; the pause needs bit 0 and none of the others, so
; no key that plays the game can start one. The game beeps (PAUSE_BEEP), waits
; for the key to be let go, then for a press and a release, and beeps again.
;
; While it waits, interrupts are on: IY is set to the ROM's system variables
; and EI lets the ROM's frame interrupt run, the only place the game allows it.
; DI turns them off again before the game goes on. IY is left pointing at the
; system variables; nothing that follows expects it to hold anything else.
PAUSE:
  LD A,$7E                ; not SPACE or CAPS SHIFT: no pause
  CALL READ_KEYS          ;
  BIT 0,A                 ;
  RET Z                   ;
  AND $1E                 ; another key with it: no pause
  RET NZ                  ;
  CALL PAUSE_BEEP         ; a beep
PAUSE_0:
  LD A,$7E                ; wait for it to be let go
  CALL READ_KEYS          ;
  BIT 0,A                 ;
  JR NZ,PAUSE_0           ;
  LD IY,$5C3A             ; the ROM's interrupt routine may run while the game
  EI                      ; waits
PAUSE_1:
  LD A,$7E                ; wait for a press
  CALL READ_KEYS          ;
  BIT 0,A                 ;
  JR Z,PAUSE_1            ;
PAUSE_2:
  LD A,$7E                ; and for it to be let go
  CALL READ_KEYS          ;
  BIT 0,A                 ;
  JR NZ,PAUSE_2           ;
  DI                      ; interrupts off again; a beep
  CALL PAUSE_BEEP         ;
  RET                     ;

; Clear B bytes from DE
;
; Used by the routines at TAKE_OR_LEAVE and BUILD_ROOM.
;
; TAKE_OR_LEAVE and BUILD_ROOM clear parts of object records with it. The entry
; point FILL_BYTES fills with A instead: DRAW_LIVES colours the lives icon with
; it.
;
;   DE the first byte
;   B how many
; O:DE just past the last
CLEAR_BYTES:
  XOR A                   ; zero
; This entry point is used by the routine at DRAW_LIVES.
FILL_BYTES:
  LD (DE),A               ; fill B bytes with A
  INC DE                  ;
  DJNZ FILL_BYTES         ;
  RET                     ;

; HL = HL + A
;
; Used by the routines at FIND_SPRITE, BUILD_ROOM and PLAY_NOTE.
;
; A is treated as unsigned. A is left holding H.
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

; HL = the address of the object record numbered A
;
; Used by the routines at RENDER_DYNAMIC_OBJECTS and SORT_AND_DRAW.
;
; Bit 7 of A is ignored: the draw list (DRAW_LIST) sets it on entries already
; drawn. BC is kept.
;
;   A the record's number, 0-53
; O:HL the record, 32 bytes each from OBJECTS
RECORD_OF:
  PUSH BC
  AND $7F                 ; drop the drawn bit
  LD L,A                  ; times 32, plus the first record
  LD H,$00                ;
  ADD HL,HL               ;
  ADD HL,HL               ;
  ADD HL,HL               ;
  ADD HL,HL               ;
  ADD HL,HL               ;
  LD BC,OBJECTS           ;
  ADD HL,BC               ;
  POP BC                  ;
  RET

; List the objects to be drawn
;
; Used by the routine at OBJECT_DONE.
;
; Called by the main loop (OBJECT_DONE) once every object has been updated.
; Writes into DRAW_LIST the number (0-53) of every record in use whose draw
; flag, bit 4 of +$07, is set, in record order, and an $FF after the last.
; RENDER_DYNAMIC_OBJECTS wipes the objects' old places from this list and
; SORT_AND_DRAW draws from it.
LIST_DRAWN:
  PUSH IX                 ; 54 records from OBJECTS; HL = the list; C = the
  LD B,$36                ; number
  LD DE,$0020             ;
  LD IX,OBJECTS           ;
  LD HL,DRAW_LIST         ;
  LD C,$00                ;
LIST_DRAWN_0:
  LD A,(IX+$00)           ; an empty record: not listed
  AND A                   ;
  JR Z,LIST_DRAWN_1       ;
  BIT 4,(IX+$07)          ; not to be drawn this turn
  JR Z,LIST_DRAWN_1       ;
  LD (HL),C               ; list its number
  INC HL                  ;
LIST_DRAWN_1:
  INC C                   ; the next record
  ADD IX,DE               ;
  DJNZ LIST_DRAWN_0       ;
  LD A,$FF                ; end the list
  LD (HL),A               ;
  POP IX                  ;
  RET                     ;

; The objects to draw this turn
;
; Filled by LIST_DRAWN: record numbers, then $FF. While SORT_AND_DRAW works
; through the list it sets bit 7 of each entry as that object is drawn, so the
; list also says what is still to do.
;
; 48 bytes: Knight Lore's size, for its forty records. Pentagram has 54, so a
; turn that listed more than 47 objects would write its later entries and the
; $FF over the start of SORT_AND_DRAW. The fullest room (87) builds 43 records
; from the directory, and lists 45 on arrival. Watched in the emulator: with
; two collectables staged into it the list reached 47 and the game ran on for
; 300 turns; with three it reached 48, the $FF landed on SORT_AND_DRAW's first
; byte as RST $38 -- which turns interrupts on -- frame interrupts then pushed
; onto sprite data mid-draw, and the game hung; with five, a hang after six
; turns. See the bugs page.
DRAW_LIST:
  DEFS $30

; Draw the listed objects, back to front
;
; Used by the routine at RENDER_DYNAMIC_OBJECTS.
;
; Called by RENDER_DYNAMIC_OBJECTS. This is where the game decides what is in
; front of what; the code is Knight Lore's. Every listed object is a box in the
; room: centre U and V with half-sizes at +$04 and +$05, a base Z with its
; whole height at +$06. The far side of anything is towards smaller U, larger V
; and lower Z (measured in the simulator with pairs of boxes: the one with
; smaller U, larger V or lower base was drawn first).
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
  XOR A                   ; no objects drawn yet
  LD (DRAW_WORK),A        ;
  PUSH IX                 ;
  PUSH IY                 ;
; This entry point is used by the routines at IY_GOES_FIRST and DRAW_CANDIDATE.
SORT_PASS:
  LD DE,DRAW_LIST         ; a pass: from the top of the list
SORT_AND_DRAW_0:
  LD A,(DE)               ; the end of the list: everything is drawn
  INC DE                  ;
  CP $FF                  ;
  JP Z,ALL_DRAWN          ;
  BIT 7,A                 ; bit 7: already drawn
  JR NZ,SORT_AND_DRAW_0   ;
  CALL RECORD_OF          ; IX = the candidate; SORT_FIRST just past its entry
  LD (SORT_FIRST),DE      ;
  PUSH HL                 ;
  POP IX                  ;
; This entry point is used by the routines at ORDER_UNCONSTRAINED,
; CANDIDATE_ALREADY_FIRST, IY_GOES_FIRST and BOXES_INTERSECT.
COMPARE_NEXT_OBJ:
  LD A,(DE)               ; the end of the list: nothing is behind the
  INC DE                  ; candidate, so draw it
  CP $FF                  ;
  JP Z,DRAW_CANDIDATE     ;
  BIT 7,A                 ; already drawn: skip
  JR NZ,COMPARE_NEXT_OBJ  ;
  CALL RECORD_OF          ; IY = this object; SORT_SECOND just past its entry
  LD (SORT_SECOND),DE     ;
  PUSH HL                 ;
  POP IY                  ;
  PUSH IX                 ; the candidate itself: skip
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
  LD A,(IX+$03)           ; code 2 if IY's base is at or above the candidate's
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
  LD A,(IX+$02)           ; add 6 if IY lies wholly further back, 3 if they
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
  LD A,(IX+$01)           ; add 18 if the candidate lies wholly further back, 9
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
  LD L,C                  ; jump through DEPTH_ORDER, as the main loop jumps
  LD BC,DEPTH_ORDER       ; through the update table
  JP JUMP_TO_TBL_ENTRY    ;

; What to do about a pair of boxes
;
; 27 addresses, indexed by the Z code (0 the candidate above, 1 overlapping, 2
; IY above) + the V code (0 the candidate further back, 3 overlapping, 6 IY
; further back) + the U code (0 IY further back, 9 overlapping, 18 the
; candidate further back), as SORT_AND_DRAW works them out. "Further back" is
; smaller U, larger V, lower Z. The table is Knight Lore's, entry for entry.
;
; Four outcomes. IY_GOES_FIRST when IY is behind or level with the candidate on
; all three axes and strictly behind on at least one: IY must be drawn first.
; CANDIDATE_ALREADY_FIRST for the mirror image, where the candidate is behind
; IY and is being drawn first anyway. ORDER_UNCONSTRAINED where each is in
; front of the other on some axis, which says nothing about their order.
; BOXES_INTERSECT, index 13, for boxes that overlap on every axis. The last
; three do the same thing.
DEPTH_ORDER:
  DEFW ORDER_UNCONSTRAINED ; 0 (Z0 V0 U0) no constraint; 1 (Z1 V0 U0) no
  DEFW ORDER_UNCONSTRAINED ; constraint; 2 (Z2 V0 U0) no constraint; 3 (Z0 V3
  DEFW ORDER_UNCONSTRAINED ; U0) IY first
  DEFW IY_GOES_FIRST       ;
  DEFW IY_GOES_FIRST       ; 4 (Z1 V3 U0) IY first; 5 (Z2 V3 U0) no constraint;
  DEFW ORDER_UNCONSTRAINED ; 6 (Z0 V6 U0) IY first; 7 (Z1 V6 U0) IY first
  DEFW IY_GOES_FIRST       ;
  DEFW IY_GOES_FIRST       ;
  DEFW ORDER_UNCONSTRAINED     ; 8 (Z2 V6 U0) no constraint; 9 (Z0 V0 U9) no
  DEFW ORDER_UNCONSTRAINED     ; constraint; 10 (Z1 V0 U9) candidate first; 11
  DEFW CANDIDATE_ALREADY_FIRST ; (Z2 V0 U9) candidate first
  DEFW CANDIDATE_ALREADY_FIRST ;
  DEFW IY_GOES_FIRST           ; 12 (Z0 V3 U9) IY first; 13 (Z1 V3 U9) the
  DEFW BOXES_INTERSECT         ; boxes intersect; 14 (Z2 V3 U9) candidate
  DEFW CANDIDATE_ALREADY_FIRST ; first; 15 (Z0 V6 U9) IY first
  DEFW IY_GOES_FIRST           ;
  DEFW IY_GOES_FIRST           ; 16 (Z1 V6 U9) IY first; 17 (Z2 V6 U9) no
  DEFW ORDER_UNCONSTRAINED     ; constraint; 18 (Z0 V0 U18) no constraint; 19
  DEFW ORDER_UNCONSTRAINED     ; (Z1 V0 U18) candidate first
  DEFW CANDIDATE_ALREADY_FIRST ;
  DEFW CANDIDATE_ALREADY_FIRST ; 20 (Z2 V0 U18) candidate first; 21 (Z0 V3 U18)
  DEFW ORDER_UNCONSTRAINED     ; no constraint; 22 (Z1 V3 U18) candidate first;
  DEFW CANDIDATE_ALREADY_FIRST ; 23 (Z2 V3 U18) candidate first
  DEFW CANDIDATE_ALREADY_FIRST ;
  DEFW ORDER_UNCONSTRAINED ; 24 (Z0 V6 U18) no constraint; 25 (Z1 V6 U18) no
  DEFW ORDER_UNCONSTRAINED ; constraint; 26 (Z2 V6 U18) no constraint
  DEFW ORDER_UNCONSTRAINED ;

; A pair with no order between them
;
; Reached through DEPTH_ORDER. Each box is in front of the other along some
; axis, so neither has to be drawn first: on to the next object.
ORDER_UNCONSTRAINED:
  JP COMPARE_NEXT_OBJ     ; next comparison

; The candidate is behind the other object
;
; Reached through DEPTH_ORDER. The candidate is to be drawn before IY, which is
; what will happen anyway. The same instruction as ORDER_UNCONSTRAINED.
CANDIDATE_ALREADY_FIRST:
  JP COMPARE_NEXT_OBJ     ; next comparison

; The other object must be drawn first
;
; Reached through DEPTH_ORDER. IY is behind the candidate, so it becomes the
; candidate instead -- unless it is already in the chain of objects that have
; been candidates since the last draw (CANDIDATE_CHAIN), in which case the
; order has gone round in a circle and IY is drawn straight away.
;
; Nothing checks the chain's length: CANDIDATE_CHAIN has room for fifteen
; numbers and the $FF, twice Knight Lore's, and a sixteenth link would put its
; $FF on the first byte of FILL_RECT. Measured over every room's first turn:
; the longest chain is 9, in the four start rooms, and four rooms go past
; Knight Lore's 7 -- so Knight Lore's eight bytes would have overflowed here
; (that this is why it was doubled is an inference).
IY_GOES_FIRST:
  LD HL,(SORT_SECOND)     ; C = IY's number, from its entry in the list
  DEC HL                  ;
  LD C,(HL)               ;
  LD DE,CANDIDATE_CHAIN     ; search the chain for it
IY_GOES_FIRST_0:
  LD A,(DE)                 ;
  CP $FF                    ;
  JR Z,IY_BECOMES_CANDIDATE ;
  CP C                      ;
  JR Z,BREAK_ORDER_CYCLE    ;
  INC DE                    ;
  JR IY_GOES_FIRST_0        ;
IY_BECOMES_CANDIDATE:
  LD A,C                  ; not there: add it, with a new $FF after it
  LD (DE),A               ;
  INC DE                  ;
  LD A,$FF                ;
  LD (DE),A               ;
  PUSH IY                 ; IX = IY, and SORT_FIRST = SORT_SECOND
  POP IX                  ;
  LD HL,(SORT_SECOND)     ;
  LD (SORT_FIRST),HL      ;
  LD DE,DRAW_LIST         ; compare it with the whole list from the top, since
  JP COMPARE_NEXT_OBJ     ; it need not be the first undrawn entry
BREAK_ORDER_CYCLE:
  LD HL,DRAW_LIST         ; a circle: find IY's entry in the list (its number
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
; not come into it. On to the next object. In Knight Lore this entry is where a
; collectable met by another object is destroyed; Pentagram does nothing here.
BOXES_INTERSECT:
  JP COMPARE_NEXT_OBJ     ; next comparison

; Draw the candidate and start the next pass
;
; Used by the routine at SORT_AND_DRAW.
;
; The end of the list was reached with nothing found that has to be drawn
; before the candidate. Its entry is marked drawn (bit 7), the candidate chain
; emptied, the object counted in DRAW_WORK and drawn (DRAW_OBJECT); then back
; to the top of the list for the next. IY_GOES_FIRST comes in at
; DRAW_AND_NEXT_PASS to draw an object that closes a circle.
;
; IX the object
DRAW_CANDIDATE:
  LD HL,(SORT_FIRST)      ; HL = just past the candidate's entry
; This entry point is used by the routine at IY_GOES_FIRST.
DRAW_AND_NEXT_PASS:
  DEC HL                  ; its entry: drawn
  SET 7,(HL)              ;
  LD A,$FF                ; the chain is empty again
  LD (CANDIDATE_CHAIN),A  ;
  LD HL,DRAW_WORK         ; one more object drawn this turn
  INC (HL)                ;
  CALL DRAW_OBJECT        ; draw it; then the next pass
  JP SORT_PASS            ;

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
; by putting an $FF in the first byte. Sixteen bytes, where Knight Lore has
; eight.
CANDIDATE_CHAIN:
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF

; Fill a rectangle of bytes with A
;
; Used by the routines at RENDER_DYNAMIC_OBJECTS and SHOW_CARRIED.
;
; Rows are 32 bytes apart, each one on from the last: in the screen buffer
; (bottom row first) that is up the screen, in the attribute file down it.
; RENDER_DYNAMIC_OBJECTS clears in the buffer the rectangle an object leaves;
; SHOW_CARRIED clears a carried thing's place on the panel and then colours its
; attributes.
;
; HL the first byte
; B the bytes in a row
; C the rows
; A the value
FILL_RECT:
  LD DE,$0020             ; the row step
FILL_RECT_0:
  PUSH BC                 ; fill a row
  PUSH HL                 ;
FILL_RECT_1:
  LD (HL),A               ;
  INC HL                  ;
  DJNZ FILL_RECT_1        ;
  POP HL                  ; on 32 bytes, for the next
  ADD HL,DE               ;
  POP BC                  ;
  DEC C                   ;
  JR NZ,FILL_RECT_0       ;
  RET

; Cut a move short against the room and the other objects
;
; Used by the routines at DEC_DZ_AND_UPDATE_UVZ and MOVE_PLAYER.
;
; Every moving object's move comes through here, from DEC_DZ_AND_UPDATE_UVZ and
; its entry points and from the player's legs (MOVE_PLAYER). It takes the step
; in U, V and Z (+$09 to +$0B) and shortens each where the object would
; otherwise end up below the floor, through a wall, or inside another object,
; then writes them back. The code is Knight Lore's (ADJ_DU_FOR_OUT_OF_BOUNDS
; and its neighbours are the walls; ADJ_DU_FOR_OBJ_INTERSECT,
; ADJ_DV_FOR_OBJ_INTERSECT and ADJ_DZ_FOR_OBJ_INTERSECT the objects), with more
; done when two things meet in Z (ADJ_DZ_FOR_OBJ_INTERSECT).
;
; The axes are done one at a time, Z first, then U, then V, and each test
; counts the moves already accepted on the earlier axes and the later ones as
; zero. That is what lets a blocked move slide: walking diagonally into a wall
; keeps the part of the move that runs along it.
;
; While it works, bit 1 of +$07 is set, which is what makes the object scans
; (IS_OBJECT_NOT_IGNORED) pass over the object itself; found already set, it
; returns at once. Bits 0-2 of +$0C are cleared at the start and set for each
; axis whose move was cut.
;
; IX the object
ADJ_FOR_OUT_OF_BOUNDS:
  BIT 1,(IX+$07)          ; not while already set; and ignore ourself while we
  RET NZ                  ; work
  SET 1,(IX+$07)          ;
  LD A,(IX+$0C)           ; clear the three "stopped" bits
  AND $F8                 ;
  LD (IX+$0C),A           ;
  LD L,$00                ; dV and dU count as zero while Z is tested
  LD C,L                  ;
  LD A,(IX+$0B)                ; H = dZ; nothing to do if zero
  AND A                        ;
  LD H,A                       ;
  JR Z,ADJ_FOR_OUT_OF_BOUNDS_0 ;
  CALL ADJ_DZ_FOR_OUT_OF_BOUNDS ; the floor first; nothing left means no
  LD A,H                        ; objects to test
  AND A                         ;
  JR Z,ADJ_FOR_OUT_OF_BOUNDS_0  ;
  CALL ADJ_DZ_FOR_OBJ_INTERSECT ; then the other objects
ADJ_FOR_OUT_OF_BOUNDS_0:
  LD A,(IX+$09)                ; C = dU; nothing to do if zero
  AND A                        ;
  LD C,A                       ;
  JR Z,ADJ_FOR_OUT_OF_BOUNDS_1 ;
  CALL ADJ_DU_FOR_OUT_OF_BOUNDS ; the walls first; nothing left means no
  LD A,C                        ; objects to test
  AND A                         ;
  JR Z,ADJ_FOR_OUT_OF_BOUNDS_1  ;
  CALL ADJ_DU_FOR_OBJ_INTERSECT ; then the other objects
ADJ_FOR_OUT_OF_BOUNDS_1:
  LD A,(IX+$0A)                ; L = dV; nothing to do if zero
  AND A                        ;
  LD L,A                       ;
  JR Z,ADJ_FOR_OUT_OF_BOUNDS_2 ;
  CALL ADJ_DV_FOR_OUT_OF_BOUNDS ; the walls first; nothing left means no
  LD A,L                        ; objects to test
  AND A                         ;
  JR Z,ADJ_FOR_OUT_OF_BOUNDS_2  ;
  CALL ADJ_DV_FOR_OBJ_INTERSECT ; then the other objects
ADJ_FOR_OUT_OF_BOUNDS_2:
  LD (IX+$09),C           ; the three moves as cut
  LD (IX+$0A),L           ;
  LD (IX+$0B),H           ;
  RES 1,(IX+$07)          ; other objects' scans may find us again
  RET                     ;

; Shorten dU against the other objects
;
; Used by the routine at ADJ_FOR_OUT_OF_BOUNDS.
;
; Tries the object's box against all 54 records. For each one it already
; overlaps in V and Z, with the moves accepted so far, an overlap in U after
; the move means dU has to be shortened, a unit at a time, until the boxes no
; longer meet; if dU reaches zero the scan stops.
;
; Every such meeting sets bit 0 of +$0C and passes harm between the two: bit 6
; of +$0D means killed, and the obstacle gets it if the mover has bit 7 (kills
; what it moves into), the mover if the obstacle has bit 5 (kills what touches
; it). An obstacle that can be pushed (bit 2 of its +$07) is given the mover's
; whole intended dU, so it moves off on its own update.
;
;   IX the moving object
;   C dU
;   L dV so far (zero)
;   H dZ as accepted
; O:C dU, shortened
ADJ_DU_FOR_OBJ_INTERSECT:
  LD IY,OBJECTS           ; IY = the first record; 54 of them
  LD B,$36                ;
ADJ_DU_FOR_OBJ_INTERSECT_0:
  CALL IS_OBJECT_NOT_IGNORED ; empty, or marked to be ignored
  JR Z,DU_OBJ_NEXT           ;
  CALL DO_OBJS_INTERSECT_ON_V ; not overlapping in V, or not in Z
  JR NC,DU_OBJ_NEXT           ;
  CALL DO_OBJS_INTERSECT_ON_Z ;
  JR NC,DU_OBJ_NEXT           ;
DU_OBJ_HIT_TEST:
  CALL DO_OBJS_INTERSECT_ON_U ; no overlap in U after the move: the next object
  JR NC,DU_OBJ_NEXT           ;
  SET 0,(IX+$0C)          ; stopped in U
  LD A,(IX+$0D)           ; the mover's bit 7 becomes the obstacle's bit 6
  RRCA                    ;
  AND $40                 ;
  OR (IY+$0D)             ;
  LD (IY+$0D),A           ;
  RLCA                    ; the obstacle's bit 5 becomes the mover's bit 6
  AND $40                 ;
  OR (IX+$0D)             ;
  LD (IX+$0D),A           ;
  BIT 2,(IY+$07)                  ; a pushable obstacle takes on our dU
  JR Z,ADJ_DU_FOR_OBJ_INTERSECT_1 ;
  LD A,(IX+$09)                   ;
  LD (IY+$09),A                   ;
ADJ_DU_FOR_OBJ_INTERSECT_1:
  LD A,C                  ; a unit shorter; none left, done; else the same
  CALL SHORTEN_DELTA      ; object again
  LD C,A                  ;
  RET Z                   ;
  JR DU_OBJ_HIT_TEST      ;
DU_OBJ_NEXT:
  LD DE,$0020                     ; the next of 54
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
  LD IY,OBJECTS           ; IY = the first record; 54 of them
  LD B,$36                ;
ADJ_DV_FOR_OBJ_INTERSECT_0:
  CALL IS_OBJECT_NOT_IGNORED ; empty, or marked to be ignored
  JR Z,DV_OBJ_NEXT           ;
  CALL DO_OBJS_INTERSECT_ON_U ; not overlapping in U, or not in Z
  JR NC,DV_OBJ_NEXT           ;
  CALL DO_OBJS_INTERSECT_ON_Z ;
  JR NC,DV_OBJ_NEXT           ;
DV_OBJ_HIT_TEST:
  CALL DO_OBJS_INTERSECT_ON_V ; no overlap in V after the move: the next object
  JR NC,DV_OBJ_NEXT           ;
  SET 1,(IX+$0C)          ; stopped in V
  LD A,(IX+$0D)           ; harm passes both ways, as in U
  RRCA                    ;
  AND $40                 ;
  OR (IY+$0D)             ;
  LD (IY+$0D),A           ;
  RLCA                    ;
  AND $40                 ;
  OR (IX+$0D)             ;
  LD (IX+$0D),A           ;
  BIT 2,(IY+$07)                  ; a pushable obstacle takes on our dV
  JR Z,ADJ_DV_FOR_OBJ_INTERSECT_1 ;
  LD A,(IX+$0A)                   ;
  LD (IY+$0A),A                   ;
ADJ_DV_FOR_OBJ_INTERSECT_1:
  LD A,L                  ; a unit shorter; none left, done; else the same
  CALL SHORTEN_DELTA      ; object again
  LD L,A                  ;
  RET Z                   ;
  JR DV_OBJ_HIT_TEST      ;
DV_OBJ_NEXT:
  LD DE,$0020                     ; the next of 54
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
; Pentagram does more here than Knight Lore. Bit 7 of +$17 is set on the
; obstacle when the mover is the player's legs or graphic 91 (MARK_STOOD_ON),
; and on the mover when the obstacle is the player's legs (graphics 32-39): the
; update routines LIFT, BOBBER and CRUMBLING_BLOCK read it (the lift and the
; bobbing head, measured in staged rooms). An obstacle of graphic 140-143
; carries the mover along (CONVEYOR_PUSH). The obstacle gets bit 3 of its +$0D,
; something has met it in Z, as in Knight Lore. And a mover with bit 2 of +$07
; gives its intended dZ to the obstacle and, wherever its own dU or dV is zero,
; takes on the obstacle's, so standing on something that moves carries it along
; (measured in the simulator: a mover with bit 2 falling on a block moving 3 in
; U and -1 in V took on both, and the block took the mover's -2 in Z).
;
;   IX the moving object
;   H dZ
;   C dU, zero here
;   L dV, zero here
; O:H dZ, shortened
ADJ_DZ_FOR_OBJ_INTERSECT:
  LD IY,OBJECTS           ; IY = the first record; 54 of them
  LD B,$36                ;
ADJ_DZ_FOR_OBJ_INTERSECT_0:
  CALL IS_OBJECT_NOT_IGNORED ; empty, or marked to be ignored
  JR Z,DZ_OBJ_NEXT           ;
  CALL DO_OBJS_INTERSECT_ON_U ; not overlapping in U, or not in V
  JR NC,DZ_OBJ_NEXT           ;
  CALL DO_OBJS_INTERSECT_ON_V ;
  JR NC,DZ_OBJ_NEXT           ;
DZ_OBJ_HIT_TEST:
  CALL DO_OBJS_INTERSECT_ON_Z ; no overlap in Z after the move: the next object
  JR NC,DZ_OBJ_NEXT           ;
  SET 2,(IX+$0C)          ; stopped in Z
  CALL MARK_STOOD_ON      ; the player or graphic 91 has met the obstacle
  LD A,(IY+$00)                    ; the obstacle is the player's legs: mark
  CP $20                           ; the mover
  JR C,ADJ_DZ_FOR_OBJ_INTERSECT_1  ;
  CP $28                           ;
  JR NC,ADJ_DZ_FOR_OBJ_INTERSECT_1 ;
  SET 7,(IX+$17)                   ;
ADJ_DZ_FOR_OBJ_INTERSECT_1:
  CP $8C                          ; graphics 140-143 carry the mover
  JR C,ADJ_DZ_FOR_OBJ_INTERSECT_2 ;
  CP $90                          ;
  CALL C,CONVEYOR_PUSH            ;
ADJ_DZ_FOR_OBJ_INTERSECT_2:
  LD A,(IX+$0D)           ; harm passes both ways, as in U
  RRCA                    ;
  AND $40                 ;
  OR (IY+$0D)             ;
  LD (IY+$0D),A           ;
  RLCA                    ;
  AND $40                 ;
  OR (IX+$0D)             ;
  LD (IX+$0D),A           ;
  SET 3,(IY+$0D)          ; the obstacle has been met in Z
  BIT 2,(IX+$07)                  ; not a mover that can be carried
  JR Z,ADJ_DZ_FOR_OBJ_INTERSECT_4 ;
  LD A,(IX+$0B)           ; the obstacle takes our dZ
  LD (IY+$0B),A           ;
  LD A,(IX+$09)                    ; no dU of our own: ride with the obstacle's
  AND A                            ;
  JR NZ,ADJ_DZ_FOR_OBJ_INTERSECT_3 ;
  LD A,(IY+$09)                    ;
  LD (IX+$09),A                    ;
ADJ_DZ_FOR_OBJ_INTERSECT_3:
  LD A,(IX+$0A)                    ; no dV of our own: ride with the obstacle's
  AND A                            ;
  JR NZ,ADJ_DZ_FOR_OBJ_INTERSECT_4 ;
  LD A,(IY+$0A)                    ;
  LD (IX+$0A),A                    ;
ADJ_DZ_FOR_OBJ_INTERSECT_4:
  LD A,H                  ; a unit shorter; none left, done; else the same
  CALL SHORTEN_DELTA      ; object again
  LD H,A                  ;
  RET Z                   ;
  JR DZ_OBJ_HIT_TEST      ;
DZ_OBJ_NEXT:
  LD DE,$0020                     ; the next of 54
  ADD IY,DE                       ;
  DJNZ ADJ_DZ_FOR_OBJ_INTERSECT_0 ;
  RET                             ;

; Be carried along by a block of graphic 140-143
;
; Used by the routine at ADJ_DZ_FOR_OBJ_INTERSECT.
;
; Called by ADJ_DZ_FOR_OBJ_INTERSECT when the object met in Z is one of
; graphics 140-143. These four share the plain block's sprite but move what
; meets them, in practice what stands on them: on every other turn (bit 0 of
; TURNS set) the mover's step gets two units in the direction the graphic's low
; two bits pick from the table at CONVEYOR_STEPS -- 140 +U, 141 -U, 142 +V, 143
; -V. Only the first mover in a turn is pushed: bit 3 of the block's +$0D, set
; by ADJ_DZ_FOR_OBJ_INTERSECT just after this, is cleared only by the block's
; own update routine (CONVEYOR_PLUS_U and its three neighbours).
;
; None of this ran in the build's sessions. It was run in the simulator
; instead: the player's legs falling onto each of the four graphics were given
; +2 U, -2 U, +2 V and -2 V on an odd turn, nothing on an even one, and nothing
; with the block's bit 3 already set.
;
; A the obstacle's graphic
; IX the mover
; IY the block
CONVEYOR_PUSH:
  BIT 3,(IY+$0D)          ; something has met the block already this turn
  RET NZ                  ;
  AND $03                 ; DE = the graphic's low two bits, times two
  ADD A,A                 ;
  PUSH DE                 ;
  PUSH HL                 ;
  LD D,$00                ;
  LD E,A                  ;
  LD A,(TURNS)            ; only on odd turns
  AND $01                 ;
  JR Z,CONVEYOR_PUSH_0    ;
  LD HL,CONVEYOR_STEPS    ; the table's dU and dV added to the mover's
  ADD HL,DE               ;
  LD A,(HL)               ;
  ADD A,(IX+$09)          ;
  LD (IX+$09),A           ;
  INC HL                  ;
  LD A,(HL)               ;
  ADD A,(IX+$0A)          ;
  LD (IX+$0A),A           ;
CONVEYOR_PUSH_0:
  POP HL                  ; DE and HL back
  POP DE                  ;
  RET                     ;

; Mark the obstacle, if the mover is the player's legs or graphic 91
;
; Used by the routine at ADJ_DZ_FOR_OBJ_INTERSECT.
;
; Called by ADJ_DZ_FOR_OBJ_INTERSECT when two objects meet in Z. Bit 7 of the
; obstacle's +$17 says the player or a graphic 91 block (HEAVY_BLOCK) has met
; it -- in practice stood on it. LIFT, BOBBER and CRUMBLING_BLOCK read and
; clear it.
;
; IX the mover
; IY the obstacle
MARK_STOOD_ON:
  LD A,(IX+$00)           ; graphic 91, or 32-39: the player's legs
  CP $5B                  ;
  JR Z,MARK_STOOD_ON_0    ;
  CP $20                  ;
  RET C                   ;
  CP $28                  ;
  RET NC                  ;
MARK_STOOD_ON_0:
  SET 7,(IY+$17)          ; mark the obstacle
  RET

; Do two objects overlap in U?
;
; Used by the routines at ADJ_DU_FOR_OBJ_INTERSECT, ADJ_DV_FOR_OBJ_INTERSECT,
; ADJ_DZ_FOR_OBJ_INTERSECT, DO_ANY_OBJS_INTERSECT and CAN_PICK_UP.
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
  SUB D                   ; carry if less than D
  RET

; Do two objects overlap in V?
;
; Used by the routines at ADJ_DU_FOR_OBJ_INTERSECT, ADJ_DV_FOR_OBJ_INTERSECT,
; ADJ_DZ_FOR_OBJ_INTERSECT, DO_ANY_OBJS_INTERSECT and CAN_PICK_UP.
;
; DO_OBJS_INTERSECT_ON_U for V, with the mover's dV in L and the half-sizes at
; +$05.
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
  SUB D                   ; carry if less than D
  RET

; Do two objects overlap in Z?
;
; Used by the routines at ADJ_DU_FOR_OBJ_INTERSECT, ADJ_DV_FOR_OBJ_INTERSECT,
; ADJ_DZ_FOR_OBJ_INTERSECT, DO_ANY_OBJS_INTERSECT and CAN_PICK_UP.
;
; Not centred like U and V: Z is an object's base and +$06 its whole height. So
; the test takes the gap between the two bases, after the mover's dZ, and
; compares it with the height of whichever object is lower.
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
  NEG                     ; the mover lower: the distance, and its own height
  LD D,(IX+$06)           ;
DO_OBJS_INTERSECT_ON_Z_0:
  SUB D                   ; carry if the gap is less than the lower one's
                          ; height
  RET
DO_OBJS_INTERSECT_ON_Z_1:
  LD D,(IY+$06)               ; the other's height
  JR DO_OBJS_INTERSECT_ON_Z_0 ;

; Shorten dU at the walls
;
; Used by the routine at ADJ_FOR_OUT_OF_BOUNDS.
;
; Keeps the object's whole footprint within the room: its U, after the move, no
; further from 128 than the room's U half-size (the first byte of ROOM_EXTENT,
; 64 or 32) less its own half-size. dU is shortened a unit at a time, and bit 0
; of +$0C set if it had to be (measured: an object with half-size 4 at 90 from
; the centre of a room of half-size 96, asked to move 5, moved 1).
;
; Two things switch the walls off, as in Knight Lore: a count in the top four
; bits of +$0C, which the player's routine (PLAYER_LEGS) runs down by one a
; turn, and bit 0 of +$07, which HANDLE_EXIT_SCREEN sets on the player near a
; doorway. That is how he walks through one at all.
;
;   IX the object
;   C dU
; O:C dU, shortened
ADJ_DU_FOR_OUT_OF_BOUNDS:
  LD A,(IX+$0C)           ; not while the count in +$0C runs
  AND $F0                 ;
  RET NZ                  ;
  BIT 0,(IX+$07)          ; not near a doorway
  RET NZ                  ;
  LD A,(ROOM_EXTENT)      ; B = the room's U half-size
  LD B,A                  ;
CLIP_DU_TO_WALLS:
  LD A,(IX+$01)                    ; A = |U + dU - 128|
  ADD A,C                          ;
  SUB $80                          ;
  JR NC,ADJ_DU_FOR_OUT_OF_BOUNDS_0 ;
  NEG                              ;
ADJ_DU_FOR_OUT_OF_BOUNDS_0:
  ADD A,(IX+$04)                  ; inside if that plus the half-size is less
  CP B                            ; than the room's: done
  JR C,ADJ_DU_FOR_OUT_OF_BOUNDS_1 ;
  SET 0,(IX+$0C)          ; stopped in U
  LD A,C                  ; a unit shorter, and again unless nothing is left
  CALL SHORTEN_DELTA      ;
  LD C,A                  ;
  JR NZ,CLIP_DU_TO_WALLS  ;
ADJ_DU_FOR_OUT_OF_BOUNDS_1:
  RET

; Shorten dV at the walls
;
; Used by the routine at ADJ_FOR_OUT_OF_BOUNDS.
;
; ADJ_DU_FOR_OUT_OF_BOUNDS for V: the room's V half-size from the second byte
; of ROOM_EXTENT, the object's at +$05, and bit 1 of +$0C.
;
;   IX the object
;   L dV
; O:L dV, shortened
ADJ_DV_FOR_OUT_OF_BOUNDS:
  LD A,(IX+$0C)           ; not while the count in +$0C runs
  AND $F0                 ;
  RET NZ                  ;
  BIT 0,(IX+$07)          ; not near a doorway
  RET NZ                  ;
  LD A,($A71E)            ; B = the room's V half-size
  LD B,A                  ;
CLIP_DV_TO_WALLS:
  LD A,(IX+$02)                    ; A = |V + dV - 128|
  ADD A,L                          ;
  SUB $80                          ;
  JR NC,ADJ_DV_FOR_OUT_OF_BOUNDS_0 ;
  NEG                              ;
ADJ_DV_FOR_OUT_OF_BOUNDS_0:
  ADD A,(IX+$05)                  ; inside if that plus the half-size is less
  CP B                            ; than the room's: done
  JR C,ADJ_DV_FOR_OUT_OF_BOUNDS_1 ;
  SET 1,(IX+$0C)          ; stopped in V
  LD A,L                  ; a unit shorter, and again unless nothing is left
  CALL SHORTEN_DELTA      ;
  LD L,A                  ;
  JR NZ,CLIP_DV_TO_WALLS  ;
ADJ_DV_FOR_OUT_OF_BOUNDS_1:
  RET

; Work out an object's screen rectangle
;
; Used by the routine at SET_DRAW_OBJS_OVERLAPPED.
;
; Fills in where an object's sprite lands in the screen buffer: the pixel
; position at +$1A and +$1B (CALC_PIXEL_XY), and the size at +$18, the width in
; bytes, one more when the pixel x is not a multiple of 8, and +$19, the height
; in rows, not cut at the top of the screen as DRAW_OBJECT cuts it. FIND_SPRITE
; also turns the sprite the way the object faces.
;
; When the object's sprite is the empty one (graphics 0 and 1 use it),
; FIND_SPRITE returns straight to this routine's caller, and +$18 and +$19 keep
; what they held: the area the object last covered is still the area to clear.
;
; IX the object
CALC_2D_INFO:
  CALL CALC_PIXEL_XY      ; the pixel position; DE = the sprite, turned the way
  CALL FIND_SPRITE        ; the object faces
  LD A,(IX+$1A)           ; the width, and one more for a shifted sprite
  AND $07                 ;
  LD A,(DE)               ;
  INC DE                  ;
  JR Z,CALC_2D_INFO_0     ;
  INC A                   ;
CALC_2D_INFO_0:
  AND $0F                 ; +$18: the width in bytes
  LD (IX+$18),A           ;
  LD A,(DE)               ; +$19: the height
  LD (IX+$19),A           ;
  RET                     ;

; Read a half-row of the keyboard
;
; Used by the routines at PAUSE, MENU, READ_CONTROLS and PLAY_TUNE_ONCE.
;
; Knight Lore's routine, byte for byte. The IN does the selecting on its own:
; IN A,($FE) puts A on the top half of the address bus, so each 0 bit in A
; selects a half-row. The CPL turns the keys' active-low bits the right way up.
;
; The OUT before it is not needed for the read. It writes A to port A*256+$FD,
; which nothing on a 48K Spectrum answers. A 128K machine's paging port would
; decode it whenever A has bit 7 clear, and the first such write comes as soon
; as the keyboard is read: $7F from the keyboard read in READ_CONTROLS (RAM
; page 7), or $7E from a joystick's (READ_BOTTOM_ROW) and from PAUSE every turn
; (page 6). In 128 mode that would put another RAM page at the top 16K, where
; much of the game lives, show the other screen and lock the paging. Tried on
; the emulator's 128K, from a 128K snapshot: at the first turn of play $7F went
; to the paging port, bank 7 appeared at the top, the paging locked, and the
; machine reset (the menu tune's key test had already paged the editor ROM in).
;
;   A the half-rows to read, as the port's high byte
; O:A the keys pressed, bits 0-4, a set bit for a key down
READ_KEYS:
  OUT ($FD),A
  IN A,($FE)
  CPL
  AND $1F
  RET

; Shorten a move by one unit
;
; Used by the routines at ADJ_DU_FOR_OBJ_INTERSECT, ADJ_DV_FOR_OBJ_INTERSECT,
; ADJ_DZ_FOR_OBJ_INTERSECT, ADJ_DU_FOR_OUT_OF_BOUNDS, ADJ_DV_FOR_OUT_OF_BOUNDS
; and ADJ_DZ_FOR_OUT_OF_BOUNDS.
;
; Moves A one step towards zero -- down if positive, up if negative -- and
; leaves Z set if nothing is left. Every loop in the collision code uses it to
; cut a move short a unit at a time and try again.
;
;   A a dU, dV or dZ
; O:A one unit closer to zero; Z set if zero
SHORTEN_DELTA:
  AND A                   ; already zero
  RET Z                   ;
  JP P,SHORTEN_DELTA_DEC  ; negative: +2 here and -1 below
  INC A                   ;
  INC A                   ;
SHORTEN_DELTA_DEC:
  DEC A                   ; the step down that sets Z
  RET

; Shorten dZ at the floor
;
; Used by the routine at ADJ_FOR_OUT_OF_BOUNDS.
;
; The floor is the only limit on Z: there is no ceiling. The floor's height is
; the third byte of ROOM_EXTENT, 128 in all three room sizes. A move that would
; take the object's base below it is shortened a unit at a time until it would
; not, and bit 2 of +$0C records that the move was stopped.
;
;   IX the object
;   H dZ
; O:H dZ, shortened
ADJ_DZ_FOR_OUT_OF_BOUNDS:
  LD A,($A71F)            ; D = the floor
  LD D,A                  ;
CLIP_DZ_TO_FLOOR:
  LD A,(IX+$03)           ; Z + dZ at or above the floor: done
  ADD A,H                 ;
  CP D                    ;
  RET NC                  ;
  SET 2,(IX+$0C)          ; stopped in Z
  LD A,H                  ; a unit shorter, and again unless nothing is left
  CALL SHORTEN_DELTA      ;
  LD H,A                  ;
  JR NZ,CLIP_DZ_TO_FLOOR  ;
  RET

; Fall, and move
;
; Used by the routines at TAKE_OR_LEAVE, BOLT, HOMER, PUSHABLE, BOBBER, SPIDER,
; WELL, ROAMER and SKY_WALKER.
;
; Takes one off dZ -- the pull of gravity -- then lets ADJ_FOR_OUT_OF_BOUNDS
; cut the step down to what fits, and adds what is left to the position. Most
; update routines come in at CLIP_AND_MOVE, to move without falling; the
; player's legs come in at ADD_DUVZ, having cut the move themselves
; (MOVE_PLAYER).
;
; IX the object
DEC_DZ_AND_UPDATE_UVZ:
  DEC (IX+$0B)            ; gravity
; This entry point is used by the routines at COLLECTABLE, SINKING_BLOCK, LIFT,
; BOBBER, DEADLY_PACER_U, DEADLY_PACER_V, PENTAGRAM_PIECE, QUEST_ITEM, WELL,
; BUCKET, CRUMBLING_BLOCK, CONVEYOR_PLUS_U, CONVEYOR_MINUS_U, CONVEYOR_PLUS_V
; and CONVEYOR_MINUS_V.
CLIP_AND_MOVE:
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

; Does this object take part in collisions?
;
; Used by the routines at ADJ_DU_FOR_OBJ_INTERSECT, ADJ_DV_FOR_OBJ_INTERSECT,
; ADJ_DZ_FOR_OBJ_INTERSECT and DO_ANY_OBJS_INTERSECT.
;
; Z set for an empty record, or one with bit 1 of +$07 set: the object moving
; now (ADJ_FOR_OUT_OF_BOUNDS sets it on itself), or one marked to be passed
; over.
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

; Mark every object the moving object's old or new rectangle touches
;
; Used by the routines at PLAYER_TOP and HOMER.
;
; Called once an object has moved or changed its sprite: by the player's body
; (PLAYER_TOP), and by every update routine that ends in the tail of HOMER,
; which sets bits 4 and 5 of the object's +$07 first. It works out the object's
; new screen rectangle (CALC_2D_INFO), forms the smallest rectangle covering
; that and the one it had at the start of the turn (+$1C to +$1F, copied there
; by the main loop), and walks all 54 records setting the draw flag, bit 4 of
; +$07, on every live object whose rectangle meets it -- the moving object
; itself included.
;
; Across, the rectangles are measured in byte columns (pixel x over 8); up, in
; pixel rows from the bottom of the screen. E is the union's first column and D
; its width in columns; L its lowest row and H its height. Only the moving
; object's rectangle is used: an object redrawn because it meets it does not in
; turn mark the objects that meet it.
;
; IX the object that has moved
SET_DRAW_OBJS_OVERLAPPED:
  LD IY,OBJECTS           ; IY = the first record; the new rectangle into +$18
  CALL CALC_2D_INFO       ; to +$1B
  LD B,$36                ; 54 records
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
  LD A,(IY+$00)                   ; an empty record: next
  AND A                           ;
  JR Z,SET_DRAW_OBJS_OVERLAPPED_6 ;
  BIT 4,(IY+$07)                   ; already to be drawn: next
  JR NZ,SET_DRAW_OBJS_OVERLAPPED_6 ;
  LD A,(IY+$1A)                   ; its first column, less E; left of the
  RRCA                            ; union, see below
  RRCA                            ;
  RRCA                            ;
  AND $1F                         ;
  SUB E                           ;
  JR C,SET_DRAW_OBJS_OVERLAPPED_7 ;
  CP D                             ; not left of the union: it meets it across
SET_DRAW_OBJS_OVERLAPPED_4:
  JR NC,SET_DRAW_OBJS_OVERLAPPED_6 ; if it starts inside
  LD A,(IY+$1B)                   ; its bottom row, less L; below the union,
  SUB L                           ; see below
  JR C,SET_DRAW_OBJS_OVERLAPPED_8 ;
  CP H                             ; not below: it meets it up and down if it
SET_DRAW_OBJS_OVERLAPPED_5:
  JR NC,SET_DRAW_OBJS_OVERLAPPED_6 ; starts inside
  SET 4,(IY+$07)          ; draw it this turn
SET_DRAW_OBJS_OVERLAPPED_6:
  EXX                     ; the next record, DE kept across the step
  LD DE,$0020             ;
  ADD IY,DE               ;
  EXX                     ;
  DJNZ OVERLAP_TEST_OBJ   ;
  RET                     ;
SET_DRAW_OBJS_OVERLAPPED_7:
  NEG                           ; to the left: it meets the union if the union
  CP (IY+$18)                   ; starts inside its width
  JR SET_DRAW_OBJS_OVERLAPPED_4 ;
SET_DRAW_OBJS_OVERLAPPED_8:
  NEG                           ; below: it meets the union if the union starts
  CP (IY+$19)                   ; inside its height
  JR SET_DRAW_OBJS_OVERLAPPED_5 ;

; Show the carried things on the panel, if they have changed
;
; Used by the routine at RENDER_DYNAMIC_OBJECTS.
;
; Called every turn by RENDER_DYNAMIC_OBJECTS; it acts only when PANEL_DUE is
; set, as TAKE_OR_LEAVE sets it when what he carries changes. The main loop
; comes in at SHOW_CARRIED_NOW on entering a room, to draw them regardless.
;
; The panel shows three of the four carried entries, CARRIED_SHOWN's two and
; CARRIED_LAST (four bytes each: the graphic first), in three boxes 24 pixels
; square along the bottom of the screen, at pixel x 16, 40 and 64. For each,
; the box is cleared in the screen buffer, the thing's sprite drawn there
; through the spare record at PANEL_RECORD (DRAW_SPRITE in DRAW_OBJECT, with no
; projection, and no flip bits so the sprite is turned back to face its stored
; way), and the box copied to the screen (BLIT_TO_SCREEN); then its three by
; three attribute cells are coloured by the graphic's low three bits, from
; CARRIED_COLOURS. An empty entry is cleared, and coloured as if graphic 0.
SHOW_CARRIED:
  LD A,(PANEL_DUE)        ; nothing has changed; or clear the flag
  AND A                   ;
  RET Z                   ;
  XOR A                   ;
  LD (PANEL_DUE),A        ;
; This entry point is used by the routine at OBJECT_DONE.
SHOW_CARRIED_NOW:
  PUSH IX                 ; IX = the spare record; three boxes; HL = the first
  LD IX,PANEL_RECORD      ; entry shown
  LD B,$03                ;
  LD HL,CARRIED_SHOWN     ;
SHOW_CARRIED_0:
  PUSH BC                 ; the box's pixel x: 16 + 24 times its number
  PUSH HL                 ;
  LD A,B                  ;
  NEG                     ;
  ADD A,$03               ;
  SLA A                   ;
  SLA A                   ;
  SLA A                   ;
  LD C,A                  ;
  SLA A                   ;
  ADD A,C                 ;
  ADD A,$10               ;
  LD (IX+$1A),A           ;
  LD (IX+$1B),$00         ; pixel y 0: the bottom of the screen
  LD C,(IX+$1A)           ; clear three bytes by 24 rows of the buffer
  LD B,(IX+$1B)           ;
  PUSH HL                 ;
  CALL CALC_VIDBUF_ADDR   ;
  LD L,C                  ;
  LD H,B                  ;
  LD BC,$0318             ;
  XOR A                   ;
  CALL FILL_RECT          ;
  POP HL                  ; something there: its sprite into the buffer
  LD A,(HL)               ;
  AND A                   ;
  JR Z,SHOW_CARRIED_1     ;
  LD (IX+$00),A           ;
  CALL DRAW_SPRITE        ;
SHOW_CARRIED_1:
  LD C,(IX+$1A)           ; copy the box from the buffer to the screen
  LD B,(IX+$1B)           ;
  CALL CALC_VRAM_ADDR     ;
  CALL CALC_VIDBUF_ADDR   ;
  LD L,C                  ;
  LD H,B                  ;
  LD BC,$1803             ;
  CALL BLIT_TO_SCREEN     ;
  POP HL                  ; C = the colour for the entry's graphic
  POP BC                  ;
  PUSH BC                 ;
  PUSH HL                 ;
  LD A,(HL)               ;
  AND $07                 ;
  LD E,A                  ;
  LD D,$00                ;
  LD HL,CARRIED_COLOURS   ;
  ADD HL,DE               ;
  LD C,(HL)               ;
  LD L,(IX+$1A)           ; DE = the attribute address of the box's top row
  LD A,(IX+$1B)           ;
  ADD A,$17               ;
  LD H,A                  ;
  CALL CALC_ATTRIB_ADDR   ;
  EX DE,HL                ; colour three cells by three
  LD A,C                  ;
  LD BC,$0303             ;
  CALL FILL_RECT          ;
  POP HL                  ; the next entry, four bytes on
  POP BC                  ;
  INC HL                  ;
  INC HL                  ;
  INC HL                  ;
  INC HL                  ;
  DJNZ SHOW_CARRIED_0     ;
  POP IX                  ; IX back
  RET                     ;

; The colours of the carried things
;
; Eight attributes, indexed by the low three bits of a carried thing's graphic
; (SHOW_CARRIED): bright ink on black, blue, red, magenta, green, cyan, yellow,
; white and white again. sna2ctl took them for text, since they are the codes
; of eight capital letters.
CARRIED_COLOURS:
  DEFB $41,$42,$43,$44,$45,$46,$47,$47

; A spare object record, for drawing on the panel
;
; Never one of the room's objects: SHOW_CARRIED draws the carried things
; through it, DRAW_LIVES the lives icon and DISPLAY_PANEL another picture on
; the panel. They set its graphic (+0), its flags (+$07) and its pixel position
; (+$1A, +$1B), and DRAW_SPRITE (DRAW_OBJECT) writes +$18 and +$19. Zero on the
; tape.
PANEL_RECORD:
  DEFS $20

; Print a character into the screen buffer
;
; Used by the routines at ADD_SCORE and TEXT_ATTR_ADDR.
;
; A character is eight bytes from FONT_BASE plus eight times its code, the top
; row first; they overwrite eight rows of the buffer going down from HL (32
; bytes a row, down being towards the start of the buffer). HL comes back one
; byte to the right, on the same top row, ready for the next character. A space
; is printed as code $3D.
;
; For text FONT_BASE is 384 bytes below the font (PRINT_TEXT_SINGLE_COLOUR), so
; the codes $30 to $5A land in it; for numbers it is the font itself
; (PRINT_BCD, in ADD_SCORE), so that digits are codes 0 to 9.
;
;   A the code
;   HL the buffer address of the character's top row
; O:HL one byte to the right
PRINT_CHAR:
  PUSH BC
  PUSH DE
  PUSH HL
  CP $20                  ; a space is code $3D
  JR NZ,PRINT_CHAR_0      ;
  LD A,$3D                ;
PRINT_CHAR_0:
  LD L,A                  ; DE = FONT_BASE + 8 * the code
  LD H,$00                ;
  ADD HL,HL               ;
  ADD HL,HL               ;
  ADD HL,HL               ;
  LD DE,(FONT_BASE)       ;
  ADD HL,DE               ;
  EX DE,HL                ;
  POP HL
  LD B,$08                ; eight rows, each written 32 bytes below the one
PRINT_CHAR_1:
  LD A,(DE)               ; before
  LD (HL),A               ;
  INC DE                  ;
  PUSH BC                 ;
  LD BC,$FFE0             ;
  ADD HL,BC               ;
  POP BC                  ;
  DJNZ PRINT_CHAR_1       ;
  POP DE
  LD BC,$0101             ; back up the eight rows and one byte right
  ADD HL,BC               ;
  POP BC
  RET

; Print the score, with its heading, on the panel
;
; Used by the routines at START and OBJECT_DONE.
;
; Called when a game or a room starts (START) and again by the main loop after
; it has shown a new room (OBJECT_DONE), since filling the attributes with the
; room's colour there has painted over the heading's. The heading goes into the
; buffer at pixel x 192, pixel y 31, in bright white (PRINT_TEXT_SINGLE_COLOUR
; writes the attributes to the screen as it goes); the six digits into the
; buffer below it at pixel x 184, pixel y 16.
PRINT_SCORE:
  LD HL,$1FC0                   ; the heading, in bright white
  LD A,$47                      ;
  LD (PRINT_ATTR),A             ;
  LD DE,SCORE_TEXT              ;
  CALL PRINT_TEXT_SINGLE_COLOUR ;
  JR PRINT_SCORE_DIGITS   ; the digits

; The score's heading
;
; One word, printed by PRINT_SCORE; the text ends with bit 7 set on the last
; letter, which sna2ctl left as a byte on its own (SCORE_TEXT_END).
SCORE_TEXT:
  DEFM "SCOR"

; The last letter of the score's heading
;
; With bit 7 set: the end of SCORE_TEXT.
SCORE_TEXT_END:
  DEFB $C5

; Add BC to the score, in BCD, and print it
;
; Used by the routine at SHOOT_DOWN.
;
; C goes into the last two digits (the third byte of SCORE), B with the carry
; into the middle two and the carry into the first two. The score is then
; printed into the buffer; the only caller, SHOOT_DOWN, copies it to the screen
; with SHOW_SCORE.
;
; The entry point PRINT_BCD prints B bytes of BCD at DE, two digits each, into
; the buffer at HL; PRINT_BCD_LSD starts with only the second digit of the
; first byte. DRAW_LIVES prints the lives with the first, PERCENTAGE the
; percentage with both.
;
; BC the points, BCD
ADD_SCORE:
  LD HL,$A746             ; the last two digits
  LD A,(HL)               ;
  ADD A,C                 ;
  DAA                     ;
  LD (HL),A               ;
  DEC HL                  ; the middle two, with the carry
  LD A,(HL)               ;
  ADC A,B                 ;
  DAA                     ;
  LD (HL),A               ;
  DEC HL                  ; the first two
  LD A,(HL)               ;
  ADC A,$00               ;
  DAA                     ;
  LD (HL),A               ;
; This entry point is used by the routine at PRINT_SCORE.
PRINT_SCORE_DIGITS:
  LD BC,$10B8             ; HL = the buffer at pixel x 184, pixel y 16; three
  CALL CALC_VIDBUF_ADDR   ; bytes from SCORE
  LD L,C                  ;
  LD H,B                  ;
  LD DE,SCORE             ;
  LD B,$03                ;
; This entry point is used by the routines at DRAW_LIVES and PERCENTAGE.
PRINT_BCD:
  PUSH HL                 ; the font's own address as the base: digits are
  LD HL,FONT              ; codes 0-9
  LD (FONT_BASE),HL       ;
  POP HL                  ;
  LD A,(DE)               ; the first digit, from the high four bits
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  AND $0F                 ;
  CALL PRINT_CHAR         ;
; This entry point is used by the routine at PERCENTAGE.
PRINT_BCD_LSD:
  LD A,(DE)               ; the second, from the low four
  AND $0F                 ;
  CALL PRINT_CHAR         ;
  INC DE                  ; the next byte
  DJNZ PRINT_BCD          ;
  RET                     ;

; Flash one of B attributes, and steady the rest
;
; Used by the routine at FLASH_MENU.
;
; Sets bit 7, FLASH, on the A'th of B attribute bytes from HL, counting from 0,
; and clears it on the others. FLASH_MENU marks the chosen control method on
; the menu with it. This entry deals with the first byte; the loop is
; FLASH_NEXT_ONE. HL comes back just past the last byte.
;
; HL the first attribute
; B how many
; A which one flashes
TOGGLE_SELECTED:
  AND A                   ; not the first
  JR NZ,FLASH_NEXT_ONE_0  ;
; This entry point is used by the routine at FLASH_NEXT_ONE.
TOGGLE_SELECTED_0:
  SET 7,(HL)              ; flash this one
  JR FLASH_NEXT_ONE_1     ;

; The rest of TOGGLE_SELECTED
;
; Counts A down a byte at a time, flashing the byte where it reaches zero.
FLASH_NEXT_ONE:
  DEC A                   ; this is the one
  JR Z,TOGGLE_SELECTED_0  ;
; This entry point is used by the routine at TOGGLE_SELECTED.
FLASH_NEXT_ONE_0:
  RES 7,(HL)              ; steady
; This entry point is used by the routine at TOGGLE_SELECTED.
FLASH_NEXT_ONE_1:
  INC HL                  ; the next byte, until B runs out
  DJNZ FLASH_NEXT_ONE     ;
  RET                     ;

; The menu
;
; Used by the routine at START.
;
; Called by START before every game. It stops every line's flash, clears the
; buffer, draws the menu's text and frame (DISPLAY_MENU, which draws the frame
; and shows the buffer only the first time, as the flag cleared here tells it)
; and flashes the chosen control method (FLASH_MENU). Then round a loop: print
; the text again (its attributes, with the flashing, go straight to the
; screen), play the tune if it has not been heard (PLAY_TUNE_ONCE, which a key
; cuts short), and read the keys.
;
; Keys 1 to 4 set bits 1 and 2 of CONTROL to 0 keyboard, 1 Kempston, 2 cursor,
; 3 Interface II, and key 0 starts the game. If several are held the highest
; wins, since each is applied in turn. Key 5 is not read, and nothing here sets
; bit 3 of CONTROL, though FLASH_MENU flashes a sixth line of the menu when it
; is set.
;
; Two leftovers do nothing: HL is loaded with one variable's address and at
; once with another's, and the CP after them sets flags nothing reads --
; perhaps a test, once, for whether the choice had changed.
MENU:
  XOR A                   ; the menu's frame is still to be drawn
  LD (FRAME_DRAWN),A      ;
  LD HL,MENU_COLOURS      ; no line flashing; the loop takes in the byte after
  LD B,$08                ; the seven attributes as well, whose bit 7 is clear
MENU_0:
  RES 7,(HL)              ; anyway
  INC HL                  ;
  DJNZ MENU_0             ;
  CALL CLEAR_BUFFER       ; a clear buffer; the text, the frame and the choice
  CALL DISPLAY_MENU       ;
  CALL FLASH_MENU         ;
MENU_1:
  CALL DISPLAY_MENU       ; the text again; the tune, once
  LD DE,TUNE_MENU         ;
  CALL PLAY_TUNE_ONCE     ;
  LD A,$F7                ; the keys 1 to 5; CONTROL as it was, into
  CALL READ_KEYS          ; CONTROL_BEFORE
  LD E,A                  ;
  LD A,(CONTROL)          ;
  LD (CONTROL_BEFORE),A   ;
  BIT 0,E                 ; 1: keyboard
  JR Z,MENU_2             ;
  AND $F9                 ;
MENU_2:
  BIT 1,E                 ; 2: Kempston
  JR Z,MENU_3             ;
  AND $F9                 ;
  OR $02                  ;
MENU_3:
  BIT 2,E                 ; 3: cursor keys
  JR Z,MENU_4             ;
  AND $F9                 ;
  OR $04                  ;
MENU_4:
  BIT 3,E                 ; 4: Interface II
  JR Z,MENU_5             ;
  OR $06                  ;
MENU_5:
  LD (CONTROL),A          ; the new choice
  LD HL,MENU_SPARE        ; leftovers: a load at once overwritten, and a
  LD HL,CONTROL_BEFORE    ; compare nothing reads
  CP (HL)                 ;
  LD A,$EF                ; key 0: start
  CALL READ_KEYS          ;
  BIT 0,A                 ;
  RET NZ                  ;
  LD HL,MENU_PASSES       ; count the passes
  INC (HL)                ;
  CALL FLASH_MENU         ; flash the choice; round again
  JP MENU_1               ;

; Flash the chosen control method's line on the menu
;
; Used by the routine at MENU.
;
; Sets the FLASH bit on the colour of the line for the method in bits 1-2 of
; CONTROL and clears it on the other three (TOGGLE_SELECTED), then clears it on
; the next colour and sets it again if bit 3 of CONTROL is set. That next
; colour is the "0 START GAME" line's: Knight Lore's menu (flash_menu) has a
; line for directional control there, which bit 3 selects, and Pentagram kept
; the code but not the line. No menu choice sets bit 3, so the start line never
; flashes from here.
;
; The colours are the first bytes of MENU_COLOURS; the title's, the first, is
; left alone. MENU calls this once before its loop and again after every pass,
; and the flash reaches the screen when DISPLAY_MENU rewrites the attributes.
FLASH_MENU:
  LD HL,$BBF2             ; the colour of the "1 KEYBOARD" line, the second in
                          ; MENU_COLOURS
  LD A,(CONTROL)          ; flash the Ath of the four method lines, A the
  RRCA                    ; method from bits 1-2 of CONTROL
  AND $03                 ;
  LD B,$04                ;
  CALL TOGGLE_SELECTED    ;
  RES 7,(HL)              ; HL is now on the start line's colour: no flash...
  LD A,(CONTROL)          ; ...unless bit 3 of CONTROL (directional control) is
  AND $08                 ; set; this never ran in the build's sessions
  RET Z                   ;
  SET 7,(HL)              ;
  RET                     ;

; The menu: the colour of each line
;
; The menu's three tables run on from here as one block: seven colours, one per
; line (this entry's first seven bytes); seven (x, y) pixel positions from the
; eighth byte (MENU_XY), y counting up from the bottom of the screen; and the
; seven strings from the fifth byte of MENU_XY_START (MENU_TEXT) to
; MENU_COPYRIGHT_LAST, ASCII with bit 7 set on the last character of each.
; DISPLAY_MENU hands the three addresses to its list printer,
; DISPLAY_TEXT_LIST. The bytes are split into several entries only because the
; code map could not see where the text starts.
;
; The colours are bright magenta for the title, bright green for the four
; control methods and bright white for the start and copyright lines.
; FLASH_MENU sets bit 7 (FLASH) of the chosen method's; MENU clears bit 7 of
; eight bytes from here before the menu is drawn, one more than there are
; lines, as Knight Lore's menu has eight.
MENU_COLOURS:
  DEFB $43,$44,$44,$44,$44,$47,$47 ; The seven lines' colours; then the title's
MENU_XY:
  DEFB $58                         ; x, 88 (character column 11), the first
                                   ; byte of the positions

; The menu: where the lines go (the title's y; keys 1 and 2)
;
; The positions go on from MENU_XY, MENU_COLOURS's last byte, an (x, y) pair
; per line. The option lines start at x 48, character column 6, and step down
; 16 pixels, two character rows, from y 143.
MENU_Y_TITLE:
  DEFB $9F                ; The title's y (159, character row 4); "1 KEYBOARD"
  DEFB $30,$8F            ; at (48, 143); "2 KEMPSTON JOYSTICK" at (48, 127)
  DEFB $30,$7F            ;

; The menu: where the lines go (key 3; key 4's x)
MENU_XY_KEY3:
  DEFB $30,$6F            ; "3 CURSOR JOYSTICK" at (48, 111); x of "4 INTERFACE
  DEFB $30                ; II"

; The menu: where the lines go (key 4's y)
MENU_Y_KEY4:
  DEFB $5F                ; y of "4 INTERFACE II": 95

; The menu: where the lines go (start, copyright), and the title's first eight
; letters
;
; The last two positions, then the menu's strings begin, at MENU_TEXT, the
; fifth byte of this entry.
MENU_XY_START:
  DEFB $30,$3F            ; "0 START GAME" at (48, 63); the copyright line at
  DEFB $50,$27            ; (80, 39); then the first string, the title,
MENU_TEXT:
  DEFB "PENTAGRA"         ; PENTAGRAM, up to its last letter

; The menu: the title's last letter
MENU_TITLE_LAST:
  DEFB "M"+$80            ; M, with bit 7 set to end the string

; The menu: "1 KEYBOARD"
MENU_KEYBOARD:
  DEFM "1 KEYBOAR"

; The menu: "1 KEYBOARD", its last letter
MENU_KEYBOARD_LAST:
  DEFB "D"+$80            ; D, with bit 7 set

; The menu: "2 KEMPSTON JOYSTICK"
MENU_KEMPSTON:
  DEFM "2 KEMPSTON JOYSTIC"

; The menu: "2 KEMPSTON JOYSTICK", its last letter
MENU_KEMPSTON_LAST:
  DEFB "K"+$80            ; K, with bit 7 set

; The menu: "3 CURSOR JOYSTICK"
;
; Three spaces after CURSOR line JOYSTICK up with the line above.
MENU_CURSOR:
  DEFM "3 CURSOR   JOYSTIC"

; The menu: "3 CURSOR JOYSTICK", its last letter
MENU_CURSOR_LAST:
  DEFB "K"+$80            ; K, with bit 7 set

; The menu: "4 INTERFACE II"
MENU_INTERFACE:
  DEFM "4 INTERFACE I"

; The menu: "4 INTERFACE II", its last letter
MENU_INTERFACE_LAST:
  DEFB "I"+$80            ; I, with bit 7 set

; The menu: "0 START GAME"
MENU_START:
  DEFM "0 START GAM"

; The menu: "0 START GAME", its last letter
MENU_START_LAST:
  DEFB "E"+$80            ; E, with bit 7 set

; The menu: the copyright line
;
; Reads on the screen as a copyright sign, then "1986 A.C.G.": the font (FONT)
; draws the copyright sign for the code of the less-than sign, and a full stop
; for the colon.
MENU_COPYRIGHT:
  DEFM "< 1986 A:C:G"

; The menu: the copyright line's last character
MENU_COPYRIGHT_LAST:
  DEFB ":"+$80            ; The last full stop (a colon in the code), with bit
                          ; 7 set

; Print a string in one colour
;
; Used by the routines at PRINT_SCORE and DISPLAY_MENU.
;
; Prints into the screen buffer (BUFFER) in the text font, colouring each
; character's cell directly in the attribute file with PRINT_ATTR. Each
; character covers the pixel rows from y down to y-7. As Knight Lore's
; print_text_single_colour, instruction for instruction.
;
;   HL the position: L = x, H = y, in pixels, y counting up from the bottom of
;      the screen
;   DE the string, ASCII with bit 7 set on the last character
; O:DE the byte after the string
PRINT_TEXT_SINGLE_COLOUR:
  PUSH HL                 ; the text font: FONT_BASE is 384 bytes below the
  LD HL,$81D5             ; font at FONT, so that the code of a letter lands on
  LD (FONT_BASE),HL       ; its glyph
  POP BC                  ; BC = the position again, left on the stack for
  PUSH BC                 ; TEXT_ATTR_ADDR; HL = its address in the buffer
  CALL CALC_VIDBUF_ADDR   ; (CALC_VIDBUF_ADDR)
  LD L,C                  ;
  LD H,B                  ;
  LD A,(PRINT_ATTR)       ; the colour goes into A'
  EX AF,AF'               ;
  JR TEXT_ATTR_ADDR       ;

; Unreached code: print a string that starts with its colour byte
;
; These bytes are the Z80 code of Knight Lore's print_text_std_font and
; print_text: select the text font, work out the buffer address, and take the
; colour from the string's first byte, running on into TEXT_ATTR_ADDR. Nothing
; in Pentagram calls them, and they never ran in the build's sessions, so the
; code map leaves them as data; the comments give the instructions they encode.
; Pentagram's strings carry no colour byte: PRINT_TEXT_SINGLE_COLOUR takes the
; colour from PRINT_ATTR instead.
PRINT_TEXT_STD_FONT:
  DEFB $E5                ; PUSH HL; LD HL, the text font's base; LD into
  DEFB $21,$D5,$81        ; FONT_BASE; POP BC
  DEFB $22,$32,$A7        ;
  DEFB $C1                ;
  DEFB $C5                ; PUSH BC; CALL CALC_VIDBUF_ADDR; LD L,C; LD H,B; LD
  DEFB $CD,$7F,$B3        ; A,(DE), the colour byte; EX AF,AF'
  DEFB $69                ;
  DEFB $60                ;
  DEFB $1A                ;
  DEFB $08                ;
  DEFB $13                ; INC DE, past the colour byte, then on into
                          ; TEXT_ATTR_ADDR

; Find the string's first attribute cell, and print the string
;
; Used by the routine at PRINT_TEXT_SINGLE_COLOUR.
;
; The rest of PRINT_TEXT_SINGLE_COLOUR. The position is on the stack. In the
; alternate registers HL' becomes the attribute address of the first cell,
; while DE' is kept: the list printer in DISPLAY_MENU walks its list of colours
; with it. Then each character is drawn into the buffer by PRINT_CHAR, which
; leaves HL one cell to the right, and its cell in the attribute file is given
; the colour.
;
; HL the string's address in the buffer
; DE the string
; A' the colour
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

; Draw the menu
;
; Used by the routine at MENU.
;
; Hands DISPLAY_TEXT_LIST, at the end of this routine, the menu's seven colours
; (MENU_COLOURS), positions and strings. Called at the start of the menu and on
; every pass of its loop (MENU).
DISPLAY_MENU:
  LD DE,MENU_COLOURS      ; DE' = the colours
  EXX                     ;
  LD HL,MENU_XY           ; HL = the positions, MENU_XY
  LD DE,MENU_TEXT         ; DE = the strings, MENU_TEXT
  LD B,$07                ; seven lines
; This entry point is used by the routine at WON.
;
; Print a list of strings. B how many; DE' their colours, a byte each; HL their
; positions, an (x, y) pair each; DE the strings, end to end. Also used by WON.
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
  LD A,(FRAME_DRAWN)      ; the first list since the screen-shown flag
  AND A                   ; (FRAME_DRAWN) was cleared...
  RET NZ                  ;
  INC A                   ; ...sets it...
  LD (FRAME_DRAWN),A      ;
  CALL PRINT_BORDER       ; ...draws the border (PRINT_BORDER) and shows the
  JP SHOW_BUFFER          ; whole buffer (SHOW_BUFFER); later lists only redraw
                          ; into the buffer and write the attributes, which is
                          ; how the menu's flashing line changes without the
                          ; screen being redrawn

; Draw the scroll-work at the foot of the screen
;
; Used by the routine at OBJECT_DONE.
;
; Draws the panel's pieces from PANEL_DATA through the spare record at
; PANEL_RECORD: a slanting run of five of graphic 62 on each side, stepping 16
; pixels in and 8 down, four pieces up each edge, and four single pieces, the
; left side the right mirrored. The lives (DRAW_LIVES), the score (PRINT_SCORE)
; and the three carried things (SHOW_CARRIED) go in the spaces it leaves.
; Called from the main loop (OBJECT_DONE) when a room has just been drawn,
; before the whole buffer is shown; it takes its colour from the room's, which
; the main loop has just filled the attributes with.
DISPLAY_PANEL:
  LD IX,PANEL_RECORD      ; IX = the spare record; the first entry
  LD HL,PANEL_DATA        ;
  CALL TRANSFER_SPRITE    ;
  LD DE,$F810                ; the left run: five pieces, each 16 pixels right
  LD B,$05                   ; and 8 down
  CALL MULTIPLE_PRINT_SPRITE ;
  CALL TRANSFER_SPRITE       ; the right run: five, each 16 left and 8 down
  LD DE,$F8F0                ;
  LD B,$05                   ;
  CALL MULTIPLE_PRINT_SPRITE ;
  CALL TRANSFER_SPRITE       ; two up the left edge, 32 pixels apart
  LD DE,$2000                ;
  LD B,$02                   ;
  CALL MULTIPLE_PRINT_SPRITE ;
  CALL TRANSFER_SPRITE       ; two up the right edge
  LD B,$02                   ;
  CALL MULTIPLE_PRINT_SPRITE ;
  CALL TRANSFER_SPRITE       ; two more on each edge, between them
  LD B,$02                   ;
  CALL MULTIPLE_PRINT_SPRITE ;
  CALL TRANSFER_SPRITE       ;
  LD B,$02                   ;
  CALL MULTIPLE_PRINT_SPRITE ;
  CALL TRANSFER_SPRITE_AND_PRINT ; the four single pieces
  CALL TRANSFER_SPRITE_AND_PRINT ;
  CALL TRANSFER_SPRITE_AND_PRINT ;
  JP TRANSFER_SPRITE_AND_PRINT   ;

; The pieces of the panel's scroll-work
;
; Ten entries of four bytes, as TRANSFER_SPRITE reads them: the graphic, the
; flags (bit 6 mirrored, bit 7 upside down), then x and y in pixels, y counting
; up from the bottom. DISPLAY_PANEL draws some once and repeats others along a
; line. Each line here is a left and right pair.
PANEL_DATA:
  DEFB $3E,$40,$10,$34    ; Graphic 62 mirrored at (16, 52), and plain at (224,
  DEFB $3E,$00,$E0,$34    ; 52): the two slanting runs, five each
  DEFB $3D,$40,$00,$04    ; Graphic 61 mirrored at (0, 4), and plain at (240,
  DEFB $3D,$00,$F0,$04    ; 4): two each up the edges
  DEFB $3C,$40,$00,$14    ; Graphic 60 mirrored at (0, 20), and plain at (240,
  DEFB $3C,$00,$F0,$14    ; 20): two each, between those (60 and 61 share a
                          ; sprite)
  DEFB $3A,$40,$60,$04    ; Graphic 58 mirrored at (96, 4), and plain at (144,
  DEFB $3A,$00,$90,$04    ; 4): once each
  DEFB $3B,$40,$00,$34    ; Graphic 59 mirrored at (0, 52), and plain at (240,
  DEFB $3B,$00,$F0,$34    ; 52): once each

; Draw the border round the screen
;
; Used by the routines at DISPLAY_MENU and WON.
;
; From BORDER_DATA, into the buffer through the spare record at PANEL_RECORD:
; the corner sprite drawn four times, turned each way, the top and bottom edges
; as eight pieces 24 pixels apart and a shorter one to close each, and the
; sides as six pieces 24 pixels apart. It frames the menu and the end screens
; (DISPLAY_MENU, WON); a room has none.
PRINT_BORDER:
  LD IX,PANEL_RECORD             ; the four corners
  LD HL,BORDER_DATA              ;
  CALL TRANSFER_SPRITE_AND_PRINT ;
  CALL TRANSFER_SPRITE_AND_PRINT ;
  CALL TRANSFER_SPRITE_AND_PRINT ;
  CALL TRANSFER_SPRITE_AND_PRINT ;
  CALL TRANSFER_SPRITE       ; the top edge: eight pieces, 24 pixels apart
  LD DE,$0018                ;
  LD B,$08                   ;
  CALL MULTIPLE_PRINT_SPRITE ;
  CALL TRANSFER_SPRITE       ; the bottom edge
  LD B,$08                   ;
  CALL MULTIPLE_PRINT_SPRITE ;
  CALL TRANSFER_SPRITE_AND_PRINT ; the short pieces that close the top and
  CALL TRANSFER_SPRITE_AND_PRINT ; bottom
  CALL TRANSFER_SPRITE       ; the left edge: six pieces, 24 pixels apart going
  LD DE,$1800                ; up
  LD B,$06                   ;
  CALL MULTIPLE_PRINT_SPRITE ;
  CALL TRANSFER_SPRITE     ; the right edge
  LD B,$06                 ;
  JP MULTIPLE_PRINT_SPRITE ;

; The pieces of the border
;
; Ten entries of four bytes, as in PANEL_DATA: graphic, flags (bit 6 mirrored,
; bit 7 upside down), x, y. The screen is 256 by 192 and the pieces 24 pixels
; wide, so the right-hand ones are at x 232 and the top ones at y 168.
BORDER_DATA:
  DEFB $05,$00,$00,$A8    ; Graphic 5, the corner, at (0, 168); mirrored at
  DEFB $05,$40,$E8,$A8    ; (232, 168)
  DEFB $05,$C0,$E8,$00    ; Graphic 5 mirrored and upside down at (232, 0);
  DEFB $05,$80,$00,$00    ; upside down at (0, 0)
  DEFB $04,$00,$18,$A8    ; Graphic 4 at (24, 168), the top edge's first;
  DEFB $04,$80,$18,$00    ; upside down at (24, 0), the bottom's
  DEFB $03,$00,$D8,$A8    ; Graphic 3 at (216, 168), closing the top edge;
  DEFB $03,$80,$D8,$00    ; upside down at (216, 0)
  DEFB $02,$00,$00,$18    ; Graphic 2 at (0, 24), the left edge's first;
  DEFB $02,$40,$E8,$18    ; mirrored at (232, 24), the right's

; Copy a sprite's four bytes into the drawing record
;
; Used by the routines at DISPLAY_PANEL, PRINT_BORDER and
; TRANSFER_SPRITE_AND_PRINT.
;
; Graphic, flags, x and y into +0, +7, +$1A and +$1B, where the sprite drawing
; (DRAW_SPRITE, in DRAW_OBJECT) finds them. As Knight Lore's transfer_sprite.
;
;   HL the four-byte entry
;   IX the record to draw with, the spare one at PANEL_RECORD
; O:HL the next entry
TRANSFER_SPRITE:
  LD A,(HL)               ; the graphic
  INC HL                  ;
  LD (IX+$00),A           ;
  LD A,(HL)               ; the flags: bit 6 mirrored, bit 7 upside down
  INC HL                  ;
  LD (IX+$07),A           ;
  LD A,(HL)               ; x and y, in pixels
  INC HL                  ;
  LD (IX+$1A),A           ;
  LD A,(HL)               ;
  INC HL                  ;
  LD (IX+$1B),A           ;
  RET

; Copy a sprite's four bytes and draw it
;
; Used by the routines at DISPLAY_PANEL and PRINT_BORDER.
;
; TRANSFER_SPRITE, then DRAW_SPRITE (DRAW_OBJECT), keeping HL on the next
; entry.
;
;   HL the four-byte entry
;   IX the record to draw with
; O:HL the next entry
TRANSFER_SPRITE_AND_PRINT:
  CALL TRANSFER_SPRITE
  PUSH HL
  CALL DRAW_SPRITE
  POP HL
  RET

; Draw a sprite several times in a line
;
; Used by the routines at DISPLAY_PANEL and PRINT_BORDER.
;
; Used to build the border and the panel out of repeated pieces. As Knight
; Lore's multiple_print_sprite.
;
; IX the record, loaded by TRANSFER_SPRITE
; B how many times
; E the step in x between copies
; D the step in y between copies
MULTIPLE_PRINT_SPRITE:
  PUSH BC                 ; draw it, keeping the registers
  PUSH DE                 ;
  PUSH HL                 ;
  CALL DRAW_SPRITE        ;
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
  RET

; Read the controls into INPUT
;
; Used by the routine at PLAYER_LEGS.
;
; Reads the keyboard or a joystick, by the method in bits 1-2 of CONTROL, into
; one byte for this turn, kept in INPUT for the rest of the turn's code
; (CHK_PICKUP_DROP, FIRE). Bit 5 is never set, nor bit 7.
;
; The keyboard: Z, C, M and B turn left and X, V, SYMBOL SHIFT and N right; the
; whole of the A-G and H-ENTER rows walk; Q, E, T, U and O jump; W, R, Y, I and
; P fire; any number key picks up or puts down. Every key in a half-row does
; the same, except the top letter row, which is shared between jump and fire
; key by key. SPACE and CAPS SHIFT do nothing here; PAUSE reads SPACE for the
; pause.
;
; A joystick: left and right turn, up walks, down jumps and fire fires, and any
; key on the bottom row but CAPS SHIFT and SPACE picks up or puts down. The
; Kempston stick is read from port 31; the cursor keys are 5 left, 8 right, 7
; up, 6 down and 0 fire; Interface II is the 6-0 keys for one stick and 1-5 for
; the other, read together. Knight Lore's joysticks also had direction controls
; with pick-up moved to bit 5; Pentagram offers neither.
;
; O:A the controls: bit 0 turn left, 1 turn right, 2 walk, 3 jump, 4 pick up or
;     put down, 6 fire
; O:C the same
READ_CONTROLS:
  LD A,(CONTROL)          ; bits 1-2 of CONTROL: 0 keyboard, 1 Kempston, 2
  RRCA                    ; cursor keys...
  AND $03                 ;
  JP Z,READ_KEYBOARD      ;
  DEC A                   ;
  JR Z,READ_KEMPSTON      ;
  DEC A                   ;
  JR Z,READ_CURSOR        ;
; Interface II: its two sticks are the keys 6-0 and 1-5.
  LD A,$F7                ; ...3 Interface II: keys 1-5, their order reversed
  CALL READ_KEYS          ; into C, so that 5 is bit 0 and 1 is bit 4, the same
  PUSH BC                 ; as 0 and 6 on the other half-row
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
  LD C,$00                ; fire
  BIT 0,A                 ;
  JR Z,READ_CONTROLS_1    ;
  SET 6,C                 ;
READ_CONTROLS_1:
  BIT 1,A                 ; up: walk
  JR Z,READ_CONTROLS_2    ;
  SET 2,C                 ;
READ_CONTROLS_2:
  BIT 2,A                 ; down: jump
  JR Z,READ_CONTROLS_3    ;
  SET 3,C                 ;
READ_CONTROLS_3:
  BIT 3,A                 ; right: turn right
  JR Z,READ_CONTROLS_4    ;
  SET 1,C                 ;
READ_CONTROLS_4:
  BIT 4,A                 ; left: turn left; then the bottom row for pick-up
  JR Z,READ_CONTROLS_5    ;
  SET 0,C                 ;
READ_CONTROLS_5:
  JP READ_BOTTOM_ROW      ;
; The Kempston joystick: bit 0 right, 1 left, 2 down, 3 up, 4 fire.
READ_KEMPSTON:
  IN A,($1F)              ; right: turn right
  LD C,$00                ;
  BIT 0,A                 ;
  JR Z,READ_CONTROLS_6    ;
  SET 1,C                 ;
READ_CONTROLS_6:
  BIT 1,A                 ; left: turn left
  JR Z,READ_CONTROLS_7    ;
  SET 0,C                 ;
READ_CONTROLS_7:
  BIT 2,A                 ; down: jump
  JR Z,READ_CONTROLS_8    ;
  SET 3,C                 ;
READ_CONTROLS_8:
  BIT 3,A                 ; up: walk
  JR Z,READ_CONTROLS_9    ;
  SET 2,C                 ;
READ_CONTROLS_9:
  BIT 4,A                 ; fire; then the bottom row for pick-up
  JR Z,READ_CONTROLS_10   ;
  SET 6,C                 ;
READ_CONTROLS_10:
  JP READ_BOTTOM_ROW      ;
; The cursor keys: 5 left, 6 down, 7 up, 8 right, 0 fire.
READ_CURSOR:
  LD C,$00                ; 5: turn left
  LD A,$F7                ;
  CALL READ_KEYS          ;
  BIT 4,A                 ;
  JR Z,READ_CONTROLS_11   ;
  SET 0,C                 ;
READ_CONTROLS_11:
  LD A,$EF                ; 0: fire
  CALL READ_KEYS          ;
  BIT 0,A                 ;
  JR Z,READ_CONTROLS_12   ;
  SET 6,C                 ;
READ_CONTROLS_12:
  BIT 3,A                 ; 7: walk
  JR Z,READ_CONTROLS_13   ;
  SET 2,C                 ;
READ_CONTROLS_13:
  BIT 2,A                 ; 8: turn right
  JR Z,READ_CONTROLS_14   ;
  SET 1,C                 ;
READ_CONTROLS_14:
  BIT 4,A                 ; 6: jump; then the bottom row for pick-up
  JR Z,READ_BOTTOM_ROW    ;
  SET 3,C                 ;
  JR READ_BOTTOM_ROW      ;
; The keyboard.
READ_KEYBOARD:
  LD A,$FE                ; CAPS SHIFT to V: bits 1 and 2 (Z and X) and bits 3
  CALL READ_KEYS          ; and 4 (C and V) are both brought down to bits 0 and
  RRCA                    ; 1, turn left and turn right; CAPS SHIFT is dropped
  LD C,A                  ;
  AND $03                 ;
  SRL C                   ;
  SRL C                   ;
  OR C                    ;
  AND $03                 ;
  LD C,A                  ;
  LD A,$7F                ; SYMBOL SHIFT or N turns right...
  CALL READ_KEYS          ;
  BIT 1,A                 ;
  JR Z,READ_CONTROLS_15   ;
  SET 1,C                 ;
READ_CONTROLS_15:
  BIT 2,A                 ; ...M turns left...
  JR Z,READ_CONTROLS_16   ;
  SET 0,C                 ;
READ_CONTROLS_16:
  BIT 3,A                 ; ...N turns right...
  JR Z,READ_CONTROLS_17   ;
  SET 1,C                 ;
READ_CONTROLS_17:
  BIT 4,A                 ; ...B turns left
  JR Z,READ_CONTROLS_18   ;
  SET 0,C                 ;
READ_CONTROLS_18:
  LD A,$BD                ; any key on the A-G or H-ENTER rows (both half-rows
  CALL READ_KEYS          ; read at once): walk
  JR Z,READ_CONTROLS_19   ;
  SET 2,C                 ;
READ_CONTROLS_19:
  LD A,$DF                ; O or U: jump
  CALL READ_KEYS          ;
  LD B,A                  ;
  AND $0A                 ;
  JR NZ,READ_CONTROLS_20  ;
  LD A,$FB                ; or Q, E or T: jump
  CALL READ_KEYS          ;
  LD E,A                  ;
  AND $15                 ;
  JR Z,READ_CONTROLS_21   ;
READ_CONTROLS_20:
  SET 3,C                 ;
READ_CONTROLS_21:
  LD A,$E7                ; any number key (both half-rows at once): pick up or
  CALL READ_KEYS          ; put down
  JR Z,READ_CONTROLS_22   ;
  SET 4,C                 ;
READ_CONTROLS_22:
  LD A,$DF                ; P, I or Y: fire
  CALL READ_KEYS          ;
  AND $15                 ;
  JR NZ,READ_CONTROLS_23  ;
  LD A,$FB                ; or W or R: fire; done, without the bottom row
  CALL READ_KEYS          ;
  AND $0A                 ;
  JR Z,READ_CONTROLS_24   ;
READ_CONTROLS_23:
  SET 6,C                 ;
  JR READ_CONTROLS_24     ;
READ_BOTTOM_ROW:
  LD A,$7E                ; the joysticks: any of Z, X, C, V, SYMBOL SHIFT, M,
  CALL READ_KEYS          ; N and B (both half-rows at once, bits 1-4) picks up
  AND $1E                 ; or puts down
  JR Z,READ_CONTROLS_24   ;
  SET 4,C                 ;
READ_CONTROLS_24:
  LD A,C                  ; this turn's controls into INPUT, and in A and C
  LD (INPUT),A            ;
  RET                     ;

; Clear bit 5 of every object's flags
;
; Used by the routine at OBJECT_DONE.
;
; Bit 5 of +7 asks RENDER_DYNAMIC_OBJECTS to copy the object's part of the
; buffer to the screen. The main loop (OBJECT_DONE) calls this after drawing a
; new room and copying the whole buffer to the screen at once, so that no
; object's part is copied again.
CLEAR_COPY_BITS:
  LD B,$36                ; all 54 records, from the flags (+7) of the first
  LD DE,$0020             ;
  LD HL,PLAYER_FLAGS      ;
CLEAR_COPY_BITS_0:
  RES 5,(HL)              ; clear bit 5 of each
  ADD HL,DE               ;
  DJNZ CLEAR_COPY_BITS_0  ;
  RET

; Does this object overlap any other?
;
; Used by the routines at QUEST_INTO_ROOM, TAKE_OR_LEAVE and SKY_DROP.
;
; Tests IX against all 54 records with the tests on each axis at
; DO_OBJS_INTERSECT_ON_U, DO_OBJS_INTERSECT_ON_V and DO_OBJS_INTERSECT_ON_Z,
; with no offset on any axis. Empty records are skipped, and so is any with bit
; 1 of its flags set (IS_OBJECT_NOT_IGNORED) -- which is how IX avoids finding
; itself: it sets its own bit 1 for the duration. Used by TAKE_OR_LEAVE to see
; whether there is room above the player's head, by QUEST_INTO_ROOM as it puts
; the quest's things in a room, and by SKY_DROP as something falls from the
; sky. As Knight Lore's do_any_objs_intersect.
;
;   IX the object
; O:F carry set if another object's box overlaps IX's where it stands
; O:IY the one it overlaps, when carry is set
DO_ANY_OBJS_INTERSECT:
  PUSH BC                 ; save the registers; IY walks all 54 records
  PUSH DE                 ;
  PUSH HL                 ;
  PUSH IY                 ;
  LD IY,OBJECTS           ;
  LD B,$36                ;
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
; The exit clears IX's bit 1 whatever it was before, as Knight Lore's does.

; Mark the object at IY to be rubbed out and redrawn
;
; Used by the routine at TAKE_OR_LEAVE.
;
; The redraw marking at the end of HOMER (bits 4 and 5 of +7, and
; SET_DRAW_OBJS_OVERLAPPED for whatever it overlaps on the screen), for the
; record at IY instead of IX, with both kept. Used as something is picked up or
; put down (TAKE_OR_LEAVE). As Knight Lore's set_wipe_and_draw_IY.
;
; IY the object's record
SET_WIPE_AND_DRAW_IY:
  PUSH IY
  PUSH IX
  PUSH IY
  POP IX
  CALL SET_WIPE_AND_DRAW_FLAGS
  POP IX
  POP IY
  RET

; Is the pick-up control pressed?
;
; Used by the routine at TAKE_OR_LEAVE.
;
; The pick-up bit is 4 of INPUT, except with a joystick and bit 3 of CONTROL
; set, when it is taken from bit 5 -- as in Knight Lore (chk_pickup_drop),
; where a directional joystick uses down for a direction and keys set bit 5
; instead. Pentagram's READ_CONTROLS never sets bit 5, so in that mode, which
; no menu choice selects, nothing could be picked up or put down.
;
; O:F Z clear if it is
; O:A bit 4 set if it is
CHK_PICKUP_DROP:
  LD HL,CONTROL           ; a joystick (method not 0)...
  LD A,(HL)               ;
  AND $06                 ;
  LD A,(INPUT)            ;
  JR Z,CHK_PICKUP_DROP_0  ;
  BIT 3,(HL)              ;
  JR Z,CHK_PICKUP_DROP_0  ;
  RRCA                    ; ...and directional control: bit 5 moves into bit 4
CHK_PICKUP_DROP_0:
  AND $10                 ; the pick-up bit
  RET                     ;

; Pick up, or put down
;
; Used by the routine at PLAYER_LEGS.
;
; Called from the legs' update routine (PLAYER_LEGS) every turn. One press does
; one thing: pick up the bucket or a collectable that he is on or beside;
; failing that, put down the last of the things he carries (CARRIED_LAST),
; under himself, so that he stands on it; and if he carries nothing there, move
; what he carries one place along towards it. TAKE_HELD latches the press, so
; holding the key does nothing more, and every press that gets that far plays
; the pick-up sound. Knight Lore's handle_pickup_drop and the routines after
; it, joined into one.
;
; Nothing happens unless he is inside the room's walls (CHK_PLYR_OOB, not in a
; doorway), not jumping (bit 3 of +$0C) and standing on something (bit 2).
; Before anything else it looks for an object up to 12 units above his head: if
; there is one, NO_HEADROOM is set and nothing is put down, because putting
; something down lifts him 12 units onto it.
;
; He carries up to three things, in the four-byte slots CARRIED_SHOWN (the
; newest), the one after, and CARRIED_LAST (the oldest, put down next): the
; graphic, the flags from +7, and the address of the thing's quest record
; (QUEST_RECORDS). CARRIED is a fourth slot in front of them, where a thing
; just picked up waits for the slots to be moved along. They behave as a queue:
; the first picked up is the first put down.
;
; IX the player's legs (OBJECTS)
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
  XOR A                      ; anything within 12 units above his head? His Z
  LD (NO_HEADROOM),A         ; is raised to look, then put back
  LD A,(IX+$03)              ;
  LD B,A                     ;
  ADD A,$0C                  ;
  LD (IX+$03),A              ;
  CALL DO_ANY_OBJS_INTERSECT ;
  LD (IX+$03),B              ;
  JR NC,TAKE_OR_LEAVE_0      ;
  LD A,$01                ; yes: there is no room for him to stand on what he
  LD (NO_HEADROOM),A      ; puts down (this never ran in the build's sessions)
TAKE_OR_LEAVE_0:
  LD A,$01                ; latch the key, and have the panel's carried things
  LD (TAKE_HELD),A        ; redrawn (SHOW_CARRIED)
  LD (PANEL_DUE),A        ;
  LD B,$30                ; each half-size +4, so that a thing just out of
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
  LD IY,ROOM_OBJECTS      ; the 48 records of the room's things: the first that
TAKE_OR_LEAVE_1:
  CALL CAN_PICK_UP        ; can be picked up (CAN_PICK_UP) is taken
  JP C,PICK_UP            ;
  LD DE,$0020             ;
  ADD IY,DE               ;
  DJNZ TAKE_OR_LEAVE_1    ;
  CALL CHK_PICKUP_DROP    ; nothing to pick up. This test cannot fail: INPUT
  JR Z,TAKE_DONE          ; has not changed since the same test at the start
  LD DE,$0020             ; the first free record among the room's 48, to put a
  LD B,$30                ; thing down in; none: nothing is put down
  LD IY,ROOM_OBJECTS      ;
TAKE_OR_LEAVE_2:
  LD A,(IY+$00)           ;
  AND A                   ;
  JR Z,PUT_DOWN           ;
  ADD IY,DE               ;
  DJNZ TAKE_OR_LEAVE_2    ;
TAKE_DONE:
  POP HL                  ; his half-sizes back
  LD (IX+$06),L           ;
  POP HL                  ;
  LD (IX+$04),L           ;
  LD (IX+$05),H           ;
  LD HL,$0105             ; the pick-up sound: sound 1, for five turns
  LD (SOUND_COUNT),HL     ; (EFFECT_NOTE)
  RET                     ;
WAIT_TAKE_RELEASE:
  CALL CHK_PICKUP_DROP    ; clear the latch once the key is up
  RET NZ                  ;
  XOR A                   ;
  LD (TAKE_HELD),A        ;
  RET                     ;
; Put down the last thing he carries, into the free record at IY.
PUT_DOWN:
  LD HL,CARRIED_LAST      ; nothing in the last slot: just move the slots along
  LD A,(HL)               ;
  INC HL                  ;
  AND A                   ;
  JR Z,SHIFT_CARRIED      ;
  LD A,(NO_HEADROOM)      ; no headroom: put nothing down
  AND A                   ;
  JR NZ,TAKE_DONE         ;
  DEC HL                  ; the thing's graphic into the free record; HL on to
  LD A,(HL)               ; the slot's flags
  INC HL                  ;
  LD (IY+$00),A           ;
  PUSH HL                 ;
  LD BC,$001F             ; the rest of the record from the player's legs: his
  PUSH IX                 ; position, so that it goes down where he stands
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
  PUSH IX                      ; with IX on the thing: its drawing nudge
  PUSH IY                      ; (DRAW_AT_L16_D8), its place on the screen
  PUSH IY                      ; (CALC_PIXEL_XY), a turn's fall
  POP IX                       ; (DEC_DZ_AND_UPDATE_UVZ), and mark it to be
  CALL DRAW_AT_L16_D8          ; drawn
  CALL CALC_PIXEL_XY           ;
  CALL DEC_DZ_AND_UPDATE_UVZ   ;
  CALL SET_WIPE_AND_DRAW_FLAGS ;
  POP IY                       ;
  POP IX                       ;
; Fill in the record of a thing put down: IY the record, its graphic and
; position already set; the slot's flags byte on the stack.
FILL_PUT_DOWN:
  LD (IY+$04),$05         ; half-sizes 5, 5 and 12
  LD (IY+$05),$05         ;
  LD (IY+$06),$0C         ;
  POP HL                  ; +7 the flags from the slot; +8 the room, the
  LD A,(HL)               ; player's
  INC HL                  ;
  LD (IY+$07),A           ;
  LD A,(IX+$08)           ;
  LD (IY+$08),A           ;
  LD A,(HL)               ; +$10 and +$11: the address of its quest record,
  INC HL                  ; from the slot
  LD (IY+$10),A           ;
  LD A,(HL)               ;
  LD (IY+$11),A           ;
  LD H,A                  ; the graphic back into the quest record, which
  LD L,(IY+$10)           ; picking it up had emptied: it is in this room again
  LD A,(IY+$00)           ;
  LD (HL),A               ;
  SET 0,(IY+$0D)          ; bit 0 of +$0D: just put down. Nothing has been
                          ; found that reads it (Knight Lore's charms have a
                          ; use for it)
  CALL SET_WIPE_AND_DRAW_IY ; mark it to be drawn
; Move the carried things one slot along.
SHIFT_CARRIED:
  LD HL,$A72D             ; twelve bytes up by four, copied from the top down
  LD DE,$A731             ; so that they do not overwrite themselves: the slot
  LD BC,$000C             ; in front moves into CARRIED_SHOWN, and so on to
  LDDR                    ; CARRIED_LAST
  LD DE,CARRIED           ; the slot in front is empty
  LD B,$04                ;
  CALL CLEAR_BYTES        ;
  JP TAKE_DONE            ;
; Pick up the thing at IY.
PICK_UP:
  LD HL,CARRIED           ; graphic, flags and quest record's address into the
  LD A,(IY+$00)           ; slot in front; the quest record's graphic zeroed,
  LD (HL),A               ; so that the thing is not put back in its room when
  INC HL                  ; he leaves
  LD A,(IY+$07)           ;
  LD (HL),A               ;
  INC HL                  ;
  LD E,(IY+$10)           ;
  LD D,(IY+$11)           ;
  XOR A                   ;
  LD (DE),A               ;
  LD (HL),E               ;
  INC HL                  ;
  LD (HL),D               ;
  CALL SET_WIPE_AND_DRAW_IY ; mark it to be rubbed out, and make it graphic 1,
  LD (IY+$00),$01           ; which the drawing code rubs out and then empties
                            ; (DRAW_OBJECT)
  LD HL,CARRIED_LAST      ; carrying fewer than three: move the slots along
  LD A,(HL)               ;
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
; Only the bucket (graphic 90) and the collectables (144 to 148), and only when
; he is on or beside it: their boxes overlap in U and V, and in Z with him
; lowered by 4, so that a thing he stands on counts as touching. The caller has
; made his box 4 bigger each way. Knight Lore's can_pickup_spec_obj and
; is_on_or_near_obj together.
;
;   IX the player's legs
;   IY the thing
; O:F carry set if it can
CAN_PICK_UP:
  LD A,(IY+$00)           ; the bucket, or graphic 144 to 148; otherwise no
  CP $5A                  ; carry
  JR Z,CAN_PICK_UP_0      ;
  SUB $90                 ;
  CP $05                  ;
  RET NC                  ;
CAN_PICK_UP_0:
  PUSH BC                     ; overlapping in U and V, with no offset
  LD BC,$0000                 ;
  LD L,C                      ;
  LD H,C                      ;
  CALL DO_OBJS_INTERSECT_ON_U ;
  JR NC,CAN_PICK_UP_1         ;
  CALL DO_OBJS_INTERSECT_ON_V ;
  JR NC,CAN_PICK_UP_1         ;
  LD A,(IX+$03)               ; in Z, with him 4 lower, then put back
  SUB $04                     ;
  LD (IX+$03),A               ;
  CALL DO_OBJS_INTERSECT_ON_Z ;
  PUSH AF                     ;
  LD A,(IX+$03)               ;
  ADD A,$04                   ;
  LD (IX+$03),A               ;
  POP AF                      ;
CAN_PICK_UP_1:
  POP BC
  RET

; Make an object a puff of smoke
;
; Used by the routines at BOLT, PLAYER_LEGS, PLAYER_TOP and BUCKET.
;
; Turns the object into graphic 64, the first frame of the puff that PUFF runs
; through, and sets bit 1 of its flags so that the collision code leaves it
; alone. Used when the player is killed (PLAYER_LEGS, PLAYER_TOP), when a bolt
; hits a wall or an object (BOLT), and by BUCKET. Knight Lore's
; init_death_sparkles.
;
; IX the object
START_PUFF:
  LD (IX+$00),$40         ; graphic 64, out of collisions, and mark it to be
  SET 1,(IX+$07)          ; redrawn
  JR PUFF_DRAW            ;

; The update routine for a puff (graphics 64 to 70)
;
; One frame a turn, with a burst of noise (PUFF_SOUND); graphic 71 is the last
; (END_PUFF).
PUFF:
  CALL DRAW_AT_L12_D4     ; its drawing nudge
  CALL PUFF_SOUND         ; the noise, and the next frame
  INC (IX+$00)            ;
; This entry point is used by the routines at START_PUFF and END_PUFF.
PUFF_DRAW:
  JP SET_WIPE_AND_DRAW_FLAGS ; mark it to be redrawn

; The update routine for a puff's last frame (graphic 71)
;
; Makes the object graphic 1, which the drawing code rubs out and then empties
; (DRAW_OBJECT). SHOOT_DOWN comes in at VANISH to make a bolt vanish the same
; way.
END_PUFF:
  CALL DRAW_AT_L12_D4     ; its drawing nudge
; This entry point is used by the routine at SHOOT_DOWN.
VANISH:
  LD (IX+$00),$01         ; graphic 1: rubbed out at the next drawing, then an
  JR PUFF_DRAW            ; empty record

; Fire a bolt
;
; Used by the routine at PLAYER_LEGS.
;
; On a new press of fire (bit 6 of INPUT, latched by FIRE_HELD), takes the
; first free of the two bolt records (BOLTS and BOLT_SECOND), copies the
; player's legs into it and makes it graphic 150, moving 8 units a turn the way
; he faces (BOLT_STEPS), starting 16 units ahead of him and 4 higher. If that
; start is outside the room's walls -- he stands in a doorway, or faces a wall
; close up -- the bolt is taken back; otherwise it makes the firing sound
; (FIRE_SOUND). BOLT flies it.
;
; IX the player's legs
FIRE:
  LD HL,BOLTS             ; the first bolt record
  LD A,(INPUT)            ; fire not pressed: unlatch, and nothing more
  AND $40                 ;
  JR NZ,FIRE_0            ;
  XOR A                   ;
  LD (FIRE_HELD),A        ;
  RET                     ;
FIRE_0:
  LD A,(FIRE_HELD)        ; still held since the last shot: nothing; otherwise
  AND A                   ; latch
  RET NZ                  ;
  INC A                   ;
  LD (FIRE_HELD),A        ;
  LD BC,$0020             ; the first bolt record if it is empty, else the
  LD A,(HL)               ; second; both busy: no shot
  AND A                   ;
  JR Z,FIRE_1             ;
  ADD HL,BC               ;
  LD A,(HL)               ;
  AND A                   ;
  RET NZ                  ;
FIRE_1:
  EX DE,HL                ; IY = the bolt; a copy of the legs' record
  PUSH DE                 ;
  POP IY                  ;
  PUSH IX                 ;
  POP HL                  ;
  LDIR                    ;
  LD (IY+$00),$96         ; graphic 150
  CALL GET_SPRITE_DIR     ; HL = the step for the way he faces (GET_SPRITE_DIR)
  LD L,A                  ; in BOLT_STEPS
  LD H,$00                ;
  LD DE,BOLT_STEPS        ;
  ADD HL,HL               ;
  ADD HL,DE               ;
  LD A,(HL)               ; kept at +$14 and +$15, and twice it added to U and
  LD (IY+$14),A           ; V: 16 units ahead
  ADD A,A                 ;
  LD E,A                  ;
  INC HL                  ;
  LD A,(HL)               ;
  LD (IY+$15),A           ;
  ADD A,A                 ;
  ADD A,(IY+$02)          ;
  LD (IY+$02),A           ;
  LD A,E                  ;
  ADD A,(IY+$01)          ;
  LD (IY+$01),A           ;
  LD A,(IY+$03)           ; 4 units higher
  ADD A,$04               ;
  LD (IY+$03),A           ;
  LD (IY+$07),$14         ; flags $14 (bits 4 and 2), nothing bumped,
  LD (IY+$0C),$00         ; half-height 8
  LD (IY+$06),$08         ;
  LD HL,(ROOM_EXTENT)     ; inside the room's walls, as CHK_PLYR_OOB tests...
  LD A,L                  ;
  SUB (IY+$04)            ;
  LD L,A                  ;
  LD A,H                  ;
  SUB (IY+$05)            ;
  LD H,A                  ;
  LD A,(IY+$01)           ;
  SUB $80                 ;
  JP P,FIRE_2             ;
  NEG                     ;
FIRE_2:
  CP L                    ;
  JR NC,FIRE_4            ;
  LD A,(IY+$02)           ;
  SUB $80                 ;
  JP P,FIRE_3             ;
  NEG                     ;
FIRE_3:
  CP H                    ;
  JR NC,FIRE_4            ;
  JP FIRE_SOUND           ; ...the firing sound
FIRE_4:
  LD (IY+$00),$00         ; outside: no bolt after all
  RET

; A bolt's step in U and V, by the way the player faces
;
; Four pairs of signed bytes, indexed by the direction from GET_SPRITE_DIR (0
; to 3). FIRE puts the pair at +$14 and +$15 of the bolt, and BOLT copies it
; into the bolt's step every turn.
BOLT_STEPS:
  DEFB $F8,$00            ; Facing 0: (-8, 0); 1: (8, 0); 2: (0, 8); 3: (0, -8)
  DEFB $08,$00            ;
  DEFB $00,$08            ;
  DEFB $00,$F8            ;

; The update routine for a bolt (graphics 149 to 151, and 60)
;
; Moves the bolt and cycles its graphic through 151, 150 and 149. Gravity is
; applied as to everything (DEC_DZ_AND_UPDATE_UVZ), but a bolt is held at Z
; 132, so one fired from the floor flies level, and one fired from higher up
; drops to that height. If it touches either thing from the sky (BOLT_HIT) the
; thing is shot down (SHOOT_DOWN); if its move was cut short in U or V by a
; wall or an object it goes up in a puff (START_PUFF). Otherwise its step is
; set again from +$14 and +$15 for the next turn, and it is marked to be
; redrawn.
;
; The update-routine table (UPDATES) also gives this routine to graphic 60,
; which is one of the panel's pieces (PANEL_DATA); no room object has been seen
; with it.
BOLT:
  CALL DRAW_AT_L12_D6        ; its drawing nudge; fall and move, cut short
  CALL DEC_DZ_AND_UPDATE_UVZ ; against the room and the other objects
  LD A,(IX+$00)           ; the next frame: 151, 150, 149, then 151 again
  DEC A                   ;
  CP $94                  ;
  JR NZ,BOLT_0            ;
  LD A,$97                ;
BOLT_0:
  LD (IX+$00),A           ;
  LD A,(IX+$03)           ; never lower than Z 132, where it stops falling
  CP $84                  ;
  JR NC,BOLT_1            ;
  LD (IX+$03),$84         ;
  LD (IX+$0B),$00         ;
BOLT_1:
  CALL BOLT_HIT           ; hit a thing from the sky: shoot it down
  LD A,D                  ;
  AND A                   ;
  JP Z,SHOOT_DOWN         ;
  LD A,(IX+$0C)           ; bumped in U or V: a puff
  AND $03                 ;
  JP NZ,START_PUFF        ;
  LD A,(IX+$14)           ; its step again, for the next turn
  LD (IX+$09),A           ;
  LD A,(IX+$15)           ;
  LD (IX+$0A),A           ;
  JP SET_WIPE_AND_DRAW_FLAGS ; mark it to be redrawn

; Has the bolt hit either thing from the sky?
;
; Used by the routine at BOLT.
;
; Tests the two records for things from the sky (FLYERS and FLYER_SECOND) with
; HIT_TEST, the second half of this routine. BOLT_TOUCHING uses the test the
; other way round, for the two bolts against the well.
;
;   IX the bolt
; O:D 0 if it has
; O:IY the thing it hit, if D is 0
BOLT_HIT:
  LD D,$01                ; the first thing from the sky
  LD IY,FLYERS            ;
  CALL HIT_TEST           ;
  LD A,D                  ; hit: done
  AND A                   ;
  RET Z                   ;
  LD IY,FLYER_SECOND      ; the second
; This entry point is used by the routine at BOLT_TOUCHING.
;
; Is the object at IY touching the one at IX? D is set to 0 if it is, and left
; alone if not. IY's graphic must be 8 or more and not a puff (64 to 71). Each
; axis in turn: the distance between them no more than the sum of their
; half-sizes, plus 2.
HIT_TEST:
  LD A,(IY+$00)           ; graphic 0 to 7: nothing there
  AND $F8                 ;
  RET Z                   ;
  CP $40                  ; graphic 64 to 71, a puff...
; This entry point is used by the routine at BOLT_TOUCHING.
HIT_TEST_Z:
  RET Z                   ; ...no hit. BOLT_TOUCHING comes in here for the
                          ; first bolt with Z from its own test for an empty
                          ; record, which skips the test for a puff: that
                          ; bolt's puff still counts as touching the well
  LD A,(IY+$01)           ; U
  SUB (IX+$01)            ;
  JP P,BOLT_HIT_0         ;
  NEG                     ;
BOLT_HIT_0:
  LD E,A                  ;
  LD A,(IY+$04)           ;
  ADD A,(IX+$04)          ;
  ADD A,$02               ;
  CP E                    ;
  RET C                   ;
  LD A,(IX+$02)           ; V
  SUB (IY+$02)            ;
  JP P,BOLT_HIT_1         ;
  NEG                     ;
BOLT_HIT_1:
  LD E,A                  ;
  LD A,(IX+$05)           ;
  ADD A,(IY+$05)          ;
  ADD A,$02               ;
  CP E                    ;
  RET C                   ;
  LD A,(IX+$03)           ; Z
  SUB (IY+$03)            ;
  JP P,BOLT_HIT_2         ;
  NEG                     ;
BOLT_HIT_2:
  LD E,A                  ;
  LD A,(IX+$06)           ;
  ADD A,(IY+$06)          ;
  ADD A,$02               ;
  CP E                    ;
  RET C                   ;
  LD D,$00                ; touching
  RET

; A bolt hits a thing from the sky
;
; Used by the routine at BOLT.
;
; Scores for it, from its graphic number: the points are three digits made of
; the number's bits -- the hundreds from bits 5-7, the tens from bits 2-4, the
; units from bits 6, 7 and 0 -- so that no digit goes past 7 and the sum stays
; BCD. The things that fall (DROP_GRAPHICS) start as graphics 164, 160, 48, 80
; and 168, which score 512, 502, 140, 241 and 522 at those frames. The score is
; shown at once (SHOW_SCORE). The thing becomes a puff (graphic 64) and the
; bolt vanishes.
;
; IX the bolt
; IY the thing it hit
SHOOT_DOWN:
  LD A,(IY+$00)           ; BC = the points: C its graphic rotated left twice,
  LD B,A                  ; AND $77; B rotated left three times, AND 7
  RLCA                    ;
  RLCA                    ;
  AND $77                 ;
  LD C,A                  ;
  LD A,B                  ;
  RLCA                    ;
  RLCA                    ;
  RLCA                    ;
  AND $07                 ;
  LD B,A                  ;
  CALL ADD_SCORE          ; add them, and copy the score to the screen
  CALL SHOW_SCORE         ;
  LD (IY+$00),$40         ; the thing: a puff, out of collisions
  SET 1,(IY+$07)          ;
  JP VANISH               ; the bolt: gone

; The update routine for things that kill but never move (graphics 23, 30, 74
; and 75)
;
; Makes the thing deadly both ways (MAKE_DEADLY) and sets its drawing nudge; it
; is not marked for redrawing, as nothing about it changes.
STILL_DEADLY:
  CALL MAKE_DEADLY        ; deadly; the nudge (-16, -8), and return from there
  JP DRAW_AT_L16_D8       ;

; Unreached code: make a thing deadly, and redraw it
;
; Six bytes that are the code of an update routine -- CALL MAKE_DEADLY, then a
; jump to the redraw marking at the end of HOMER -- but no graphic's entry in
; UPDATES points here and nothing else reaches it, so the code map leaves it as
; data.
DEADLY_AND_DRAW:
  DEFB $CD,$91,$C2        ; CALL MAKE_DEADLY; JP to the redraw marking
  DEFB $C3,$DE,$CC        ;

; Make an object deadly both ways
;
; Used by the routines at STILL_DEADLY, SPIKES, DEADLY_BOBBER, DEADLY_PACER_U,
; DEADLY_PACER_V, SPIDER, ROAMER and SKY_WALKER.
;
; Sets bits 7 and 5 of +$0D: it kills what it moves into and what touches it.
; As Knight Lore's set_both_deadly_flags.
;
; IX the object
MAKE_DEADLY:
  LD A,(IX+$0D)
  OR $A0
  LD (IX+$0D),A
  RET

; Draw the lives icon and the number of lives on the panel
;
; Used by the routines at OBJECT_DONE and QUEST_ITEM.
;
; Draws graphic 22, a little Sabreman, at (16, 32) in the buffer through the
; spare record at PANEL_RECORD, makes six attribute cells bright white --
; columns 2 and 3 of character row 18, and 2 to 5 of row 19, the icon and the
; two digits -- and prints LIVES as two digits in columns 4 and 5 of row 19.
; Called when a room is drawn (OBJECT_DONE) and when a quest item adds a life
; (QUEST_ITEM). Knight Lore's print_lives_gfx draws only the icon.
DRAW_LIVES:
  LD IX,PANEL_RECORD      ; graphic 22, unturned, at (16, 32)
  LD (IX+$00),$16         ;
  LD (IX+$07),$00         ;
  LD (IX+$1A),$10         ;
  LD (IX+$1B),$20         ;
  CALL DRAW_SPRITE        ;
  LD A,$47                ; bright white on black: two cells of row 18, four of
  LD DE,$5A42             ; row 19, from column 2
  LD B,$02                ;
  CALL FILL_BYTES         ;
  LD DE,$5A62             ;
  LD B,$04                ;
  CALL FILL_BYTES         ;
  LD DE,LIVES             ; the two digits of LIVES, by the score's printer
  LD B,$01                ; (ADD_SCORE)
  LD HL,$DD73             ;
  JP PRINT_BCD            ;

; Choose where the game starts
;
; Used by the routine at START.
;
; Puts the first sixteen bytes of the player's legs record back as they are at
; the start of a game (PLAYER_START, over the start of PLAYER_TEMPLATE), and
; sets the room by the random number: one of the four at START_ROOMS. Called
; once a game, from START, before the first RESTART_PLAYER.
CHOOSE_START:
  LD HL,PLAYER_START      ; graphic, position, half-sizes, flags and room of a
  LD DE,PLAYER_TEMPLATE   ; new game
  LD BC,$0010             ;
  LDIR                    ;
  LD A,(RANDOM)           ; one of four rooms, by bits 0 and 1 of RANDOM
  AND $03                 ;
  LD C,A                  ;
  LD HL,START_ROOMS       ;
  ADD HL,BC               ;
  LD A,(HL)               ;
  LD (START_ROOM),A       ;
  RET

; The four rooms a game can start in
;
; CHOOSE_START picks one by bits 0 and 1 of RANDOM.
START_ROOMS:
  DEFB $33                ; Room 51
  DEFB $5C                ; Room 92
  DEFB $64                ; Room 100
  DEFB $0C                ; Room 12

; Put the player back, a life fewer
;
; Used by the routine at START.
;
; Copies PLAYER_TEMPLATE over both his records -- the player as he came into
; this room, or as the game starts -- and takes a life. Reached at the start of
; every game and after every death (START), so the first call takes the five
; lives the game gives to four; below zero, after the fifth death, the game is
; over (GAME_OVER, in WON).
;
; LIVES is treated as BCD elsewhere but decremented here as a plain number. It
; cannot go above 9 (five, and one for each of the four quest items,
; QUEST_ITEM), so the two agree.
RESTART_PLAYER:
  LD HL,PLAYER_TEMPLATE   ; both records, legs and body; IX on the legs
  LD DE,OBJECTS           ;
  PUSH DE                 ;
  POP IX                  ;
  LD BC,$0040             ;
  LDIR                    ;
  LD HL,LIVES             ; a life fewer; below zero: game over
  DEC (HL)                ;
  JP M,GAME_OVER          ;
  RET                     ;

; The quest is complete
;
; Used by the routine at COLLECTABLE.
;
; Jumped to by COLLECTABLE when the fifth collectable reaches its place. Clears
; the buffer, fills the attributes with bright cyan, prints the six lines of
; WON_CONGRATULATIONS -- congratulations, the quest done (with a misspelling),
; and the next adventure named as Mire Mare -- clearing the screen-shown flag
; (FRAME_DRAWN) first, so that the list also draws the border and shows the
; screen -- then plays TUNE_WON to its end and goes on to the game-over screen.
;
; Mire Mare was to be the next Sabreman game; it was never released.
WON:
  CALL CLEAR_BUFFER       ; clear the buffer; bright cyan on black
  LD A,$45                ;
  CALL FILL_ATTRS         ;
  LD DE,WON_COLOURS         ; colours from WON_COLOURS, positions from WON_XY,
  EXX                       ; strings from WON_CONGRATULATIONS: six lines
  LD HL,WON_XY              ;
  LD DE,WON_CONGRATULATIONS ;
  LD B,$06                  ;
  XOR A                   ; the first list since the flag was cleared: border
  LD (FRAME_DRAWN),A      ; and screen too
  CALL DISPLAY_TEXT_LIST  ;
  LD DE,TUNE_WON          ; the winning tune
  CALL PLAY_TUNE          ;
; This entry point is used by the routine at RESTART_PLAYER.
;
; The game is over: from RESTART_PLAYER when the last life is lost, and after
; the win.
GAME_OVER:
  CALL CLEAR_BUFFER       ; clear the buffer; bright yellow on black
  LD A,$46                ;
  CALL FILL_ATTRS         ;
  CALL PRINT_BORDER       ; border
  LD DE,OVER_COLOURS      ; GAME OVER, PERCENTAGE OF QUEST and COMPLETED:
  EXX                     ; colours from OVER_COLOURS, positions from OVER_XY,
  LD HL,OVER_XY           ; strings from OVER_GAME_OVER. The screen was shown
  LD DE,OVER_GAME_OVER    ; once already this game, so the list only draws into
  LD B,$03                ; the buffer
  CALL DISPLAY_TEXT_LIST  ;
  CALL PERCENTAGE         ; the percentage, into the buffer (PERCENTAGE)
  XOR A                   ; show it all. Clearing the flag here is redundant:
  LD (FRAME_DRAWN),A      ; the menu clears it again
  CALL SHOW_BUFFER        ;
  LD DE,TUNE_OVER         ; the game-over tune
  CALL PLAY_TUNE          ;
  LD B,$40                ; about four seconds: 64 times 8192 turns of a 26
WON_0:
  LD HL,$2000             ; T-state loop
WON_1:
  DEC HL                  ;
  LD A,H                  ;
  OR L                    ;
  JR NZ,WON_1             ;
  DJNZ WON_0              ;
  POP HL                  ; drop the return address -- the main loop's, or the
  JP AFTER_GAME           ; one back into START -- and start again from the
                          ; menu

; The game-over screen: the colour of each line
;
; The game-over screen's three tables, laid out as the menu's (MENU_COLOURS):
; three colours, three (x, y) positions from this entry's last byte (OVER_XY),
; and three strings from OVER_GAME_OVER, handed to DISPLAY_TEXT_LIST
; (DISPLAY_MENU) by GAME_OVER (WON).
OVER_COLOURS:
  DEFB $42,$43,$44        ; Red, magenta and green, all bright; then the first
OVER_XY:
  DEFB $58                ; line's x, the first byte of the positions

; The game-over screen: where the lines go
OVER_Y_TITLE:
  DEFB $9F                ; GAME OVER's y, 159, for (88, 159): character column
  DEFB $30,$6F            ; 11, row 4; PERCENTAGE OF QUEST at (48, 111);
  DEFB $40,$5F            ; COMPLETED at (64, 95)

; The game-over screen: GAME OVER
OVER_GAME_OVER:
  DEFM "GAME OVE"

; The game-over screen: GAME OVER, its last letter
OVER_GAME_OVER_LAST:
  DEFB "R"+$80            ; R, with bit 7 set

; The game-over screen: PERCENTAGE OF QUEST
OVER_PERCENTAGE:
  DEFM "PERCENTAGE OF QUES"

; The game-over screen: PERCENTAGE OF QUEST, its last letter
OVER_PERCENTAGE_LAST:
  DEFB "T"+$80            ; T, with bit 7 set

; The game-over screen: COMPLETED
;
; PERCENTAGE prints the percentage after it, at (144, 95).
OVER_COMPLETED:
  DEFM "COMPLETE"

; The game-over screen: COMPLETED, its last letter
OVER_COMPLETED_LAST:
  DEFB "D"+$80            ; D, with bit 7 set

; The winning screen: CONGRATULATIONS
;
; The winning screen's six strings run from here to WON_MIRE_MARE_LAST; their
; positions follow them, from WON_XY, the second byte of WON_MIRE_MARE_LAST,
; and their colours are WON_COLOURS. WON hands the three to DISPLAY_TEXT_LIST
; (DISPLAY_MENU).
WON_CONGRATULATIONS:
  DEFM "CONGRATULATION"

; The winning screen: CONGRATULATIONS, its last letter
WON_CONGRATULATIONS_LAST:
  DEFB "S"+$80            ; S, with bit 7 set

; The winning screen: YOU HAVE COMPLEATED
;
; Spelt so on the screen.
WON_COMPLEATED:
  DEFM "YOU HAVE COMPLEATE"

; The winning screen: YOU HAVE COMPLEATED, its last letter
WON_COMPLEATED_LAST:
  DEFB "D"+$80            ; D, with bit 7 set

; The winning screen: THE PENTAGRAM
WON_PENTAGRAM:
  DEFM "THE PENTAGRA"

; The winning screen: THE PENTAGRAM, its last letter
WON_PENTAGRAM_LAST:
  DEFB "M"+$80            ; M, with bit 7 set

; The winning screen: YOUR ADVENTURE
WON_ADVENTURE:
  DEFM "YOUR ADVENTUR"

; The winning screen: YOUR ADVENTURE, its last letter
WON_ADVENTURE_LAST:
  DEFB "E"+$80            ; E, with bit 7 set

; The winning screen: CONTINUES IN
WON_CONTINUES:
  DEFM "CONTINUES I"

; The winning screen: CONTINUES IN, its last letter
WON_CONTINUES_LAST:
  DEFB "N"+$80            ; N, with bit 7 set

; The winning screen: MIRE MARE
WON_MIRE_MARE:
  DEFM "MIRE MAR"

; The winning screen: MIRE MARE's last letter, and where the first line goes
WON_MIRE_MARE_LAST:
  DEFB "E"+$80            ; E, with bit 7 set; then the positions start:
WON_XY:
  DEFB $48,$8F            ; CONGRATULATIONS at (72, 143)

; The winning screen: where the lines go (the second; the third's x)
WON_XY_LINE2:
  DEFB $38,$6F            ; YOU HAVE COMPLEATED at (56, 111); x of THE
  DEFB $50                ; PENTAGRAM

; The winning screen: where the lines go (the third's y)
WON_Y_LINE3:
  DEFB $5F                ; y of THE PENTAGRAM: 95

; The winning screen: where the lines go (the fourth and fifth)
WON_XY_LINE4:
  DEFB $48,$4F            ; YOUR ADVENTURE at (72, 79); CONTINUES IN at (80,
  DEFB $50,$3F            ; 63)

; The winning screen: where the lines go (the sixth)
WON_XY_LINE6:
  DEFB $60,$1F            ; MIRE MARE at (96, 31)

; The winning screen: the colour of each line
WON_COLOURS:
  DEFB $46,$45,$45,$42,$42,$43 ; Yellow, cyan, cyan, red, red and magenta, all
                               ; bright

; The start of the player's legs record, as a game starts
;
; Sixteen bytes that CHOOSE_START copies over the start of PLAYER_TEMPLATE at
; every new game, putting back what his travels have changed there. The room is
; replaced at once by one of START_ROOMS.
PLAYER_START:
  DEFB $20                ; Graphic 32, the legs; U, V and Z 128, the middle of
  DEFB $80,$80,$80        ; the room on the floor; half-sizes 5, 5 and 23 --
  DEFB $05,$05,$17        ; the legs' box is the height of the whole man; flags
  DEFB $5C                ; $5C: bit 6 mirrored, bit 4 drawn, and bits 3 and 2
  DEFB $62                         ; Room 98, never used; the rest zero
  DEFB $00,$00,$00,$00,$00,$00,$00 ;

; The player, as he came into this room
;
; His two records, legs and body, 64 bytes, which RESTART_PLAYER copies over
; OBJECTS at the start of every life. Each time he goes through a doorway,
; EXIT_LOW_U and its neighbours copy his records here as he comes into the new
; room, so a life starts at the doorway he came in by; a new game puts the
; start of the legs' record back from PLAYER_START, and CHOOSE_START sets the
; room. What is kept is the exit marker, not a position: after an exit it held
; the new room with V $FF, so a restart runs the arrival code again (measured).
PLAYER_TEMPLATE:
  DEFB $20                ; The legs: graphic 32; U, V, Z; half-sizes 5 and 5,
  DEFB $80,$80,$80        ; height 23; flags $5C
  DEFB $05,$05,$17        ;
  DEFB $5C                ;
START_ROOM:
  DEFB $62                ; The room
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; The rest of the legs' record: zero
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00 ; The body's record starts at the last byte:
  DEFB $28                         ; graphic 40
  DEFB $80,$80,$8C        ; U and V 128, Z 140 (12 higher than the legs);
  DEFB $05,$05,$00        ; half-sizes 5, 5 and 0; flags $5E, as the legs' and
  DEFB $5E                ; out of collisions (bit 1); room 1, which nothing
  DEFB $01                ; reads -- PLAYER_TOP copies the legs' position into
                          ; the body every turn
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; The rest of the body's record: zero
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00

; The update routine for what does nothing
;
; Graphics 0 to 5 and many more in UPDATES: an empty record, scenery that never
; changes, and graphic 1, a record waiting to be rubbed out and emptied
; (DRAW_OBJECT).
NOTHING:
  RET

; The player's update routine: legs (graphics 32 to 39)
;
; The player's turn, in order: read the controls (READ_CONTROLS), turn
; (HANDLE_LEFT_RIGHT), step the legs' frame, with a footstep sound
; (HANDLE_FORWARD), start a jump (HANDLE_JUMP), pick up or put down
; (TAKE_OR_LEAVE). Then, if he stands in a doorway -- past the line of the
; room's walls -- he may not rise, only fall. The move is resolved and made
; (MOVE_PLAYER), with the body out of the way of the collision tests, and he
; may fire (FIRE).
;
; If he has been killed (bit 6 of +$0D), the body is killed too and the legs
; become a puff.
;
; IX the legs' record, OBJECTS
PLAYER_LEGS:
  CALL DRAW_AT_L12_D6     ; the legs' drawing nudge (-12, -6)
  BIT 6,(IX+$0D)          ; killed: the body too (+$0D of the next record), and
  JR Z,PLAYER_LEGS_0      ; a puff
  SET 6,(IX+$2D)          ;
  JP START_PUFF           ;
PLAYER_LEGS_0:
  CALL READ_CONTROLS      ; this turn's controls in A and C; no step in U or V
  XOR A                   ; yet
  LD (IX+$09),A           ;
  LD (IX+$0A),A           ;
  CALL HANDLE_LEFT_RIGHT  ; turn, walk, jump, pick up or put down
  CALL HANDLE_FORWARD     ;
  CALL HANDLE_JUMP        ;
  CALL TAKE_OR_LEAVE      ;
  CALL CHK_PLYR_OOB       ; in a doorway, beyond the walls?
  JR NC,LEGS_IN_DOORWAY   ;
LEGS_MOVE:
  SET 1,(IX+$27)          ; the body (+7 of the next record) out of the
                          ; collision tests while the legs move
  LD A,(IX+$03)           ; no higher than Z 240 (this never ran in the build's
  CP $F0                  ; sessions)
  JR C,PLAYER_LEGS_1      ;
  LD (IX+$03),$F0         ;
PLAYER_LEGS_1:
  CALL MOVE_PLAYER        ; make the move, and fire
  CALL FIRE               ;
  RES 1,(IX+$27)          ; the body back in the collision tests
  RES 0,(IX+$07)          ; bit 0 of his flags, set at a doorway to let the
                          ; move cross the line of the walls
                          ; (HANDLE_EXIT_SCREEN), lasts one turn
  LD A,(IX+$0C)           ; count down the top four bits of +$0C: the turns he
  SUB $10                 ; walks on by himself after coming through a doorway
  JR C,PLAYER_LEGS_2      ; (EXIT_LOW_U sets 3)
  LD (IX+$0C),A           ;
PLAYER_LEGS_2:
  JP SET_WIPE_AND_DRAW_FLAGS ; mark him to be redrawn
LEGS_IN_DOORWAY:
  LD A,(IX+$0B)           ; in a doorway: falling is allowed...
  AND A                   ;
  JP M,LEGS_MOVE          ;
  XOR A                   ; ...rising is not
  LD (IX+$0B),A           ;
  JR LEGS_MOVE            ;

; Unreached code: a RET
;
; One byte, a RET, between PLAYER_LEGS and CHK_PLYR_OOB, which nothing reaches;
; the code map leaves it as data.
STRAY_RET_LEGS:
  DEFB $C9                ; RET

; Is he inside the room's walls?
;
; Used by the routines at TAKE_OR_LEAVE and PLAYER_LEGS.
;
; Compares the object's distance from the room's centre, 128 on U and V, with
; the room's reach in each (ROOM_EXTENT) less its own half-size. Carry means
; the whole of its footprint is inside on both; no carry, that it touches or
; crosses the line of a wall, which only a doorway allows. FIRE has the same
; test written out again for a bolt. As Knight Lore's chk_plyr_OOB.
;
;   IX the object, the player's legs
; O:F carry set if it is
CHK_PLYR_OOB:
  LD HL,(ROOM_EXTENT)     ; L = the reach in U less the half-size in U; H = the
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

; Turn the player
;
; Used by the routine at PLAYER_LEGS.
;
; Two ways of steering. Rotational control -- the keyboard's, and every
; joystick's as the menu leaves them -- turns a quarter at a time on the two
; turn controls: bit 0 of C turns left, bit 1 right. Directional control treats
; the controls as four points of the compass instead: pushing one turns the
; player towards it and, once he faces it, walks him that way. It needs a
; joystick method and bit 3 of CONTROL, which no menu choice sets (MENU), so
; the game as sold never uses it.
;
; Facings, as GET_SPRITE_DIR gives them: 0 is towards lower U (up and left on
; the screen), 1 higher U (down and right), 2 higher V (up and right), 3 lower
; V (down and left). A facing is stored as two bits -- bit 2 of the graphic and
; bit 6 of the flags, the mirror bit -- and a quarter turn always toggles the
; mirror bit and, half the time, the graphic's bit 2 as well. A left turn goes
; 0, 3, 1, 2 and round; a right turn the other way. The body's graphic is set
; to the legs' plus 8 at once, so the two turn in the same turn.
;
; Directional control reads up (bit 2) unless left is also held, then right,
; down (bit 4), left, and goes the short way round, or two turns for an
; about-face. Up is the walk bit itself, so pushing up walks even while
; turning; and down is bit 4, which READ_CONTROLS sets only from the pick-up
; keys -- every joystick's down is jump, bit 3 -- so a joystick alone can never
; face 3. This is Knight Lore's code, where the stick's down was bit 4.
;
;   IX The player's legs (OBJECTS)
;   C The controls (INPUT): bits 0 and 1 turn, 2 walk, 3 jump, 4 pick up
; O:C Bit 2 set if the player is to walk
HANDLE_LEFT_RIGHT:
  LD HL,CONTROL            ; Bits 1-2 of the control method: 0, the keyboard,
  LD A,(HL)                ; always turns rotationally
  AND $06                  ;
  JR Z,HANDLE_LEFT_RIGHT_9 ;
  BIT 3,(HL)               ; Directional control not switched on
  JR Z,HANDLE_LEFT_RIGHT_9 ;
  LD A,(IX+$0C)           ; Directional: nothing during the walk into a room
  AND $F0                 ; (the count in bits 4-7 of +$0C)
  RET NZ                  ;
  BIT 2,(IX+$0C)          ; Nor in the air: bit 2 of +$0C, set when a move down
  RET Z                   ; was stopped, means standing
  BIT 0,C                   ; Left held: skip up; up held: face 2
  JR NZ,HANDLE_LEFT_RIGHT_0 ;
  BIT 2,C                   ;
  JR NZ,HANDLE_LEFT_RIGHT_1 ;
HANDLE_LEFT_RIGHT_0:
  BIT 1,C                   ; Right: face 1; down: face 3; left: face 0
  JR NZ,HANDLE_LEFT_RIGHT_4 ;
  BIT 4,C                   ;
  JR NZ,HANDLE_LEFT_RIGHT_5 ;
  BIT 0,C                   ;
  JR NZ,HANDLE_LEFT_RIGHT_7 ;
  RES 2,C                 ; Nothing pushed: no walking (bit 2 is already clear
  RET                     ; by now)
HANDLE_LEFT_RIGHT_1:
  CALL GET_SPRITE_DIR      ; Up: facing 2 already, so walk
  CP $02                   ;
HANDLE_LEFT_RIGHT_2:
  JR Z,HANDLE_LEFT_RIGHT_8 ;
  CPL                     ; Otherwise invert the facing, so that bit 0 set
HANDLE_LEFT_RIGHT_3:
  AND $01                 ; means a right turn is the short way
  JR HANDLE_LEFT_RIGHT_12 ;
HANDLE_LEFT_RIGHT_4:
  CALL GET_SPRITE_DIR     ; Right: facing 1 already? The same test as up
  CP $01                  ;
  JR HANDLE_LEFT_RIGHT_2  ;
HANDLE_LEFT_RIGHT_5:
  CALL GET_SPRITE_DIR      ; Down: facing 3 already? Walk if so
  CP $03                   ;
HANDLE_LEFT_RIGHT_6:
  JR Z,HANDLE_LEFT_RIGHT_8 ;
  JR HANDLE_LEFT_RIGHT_3  ; Otherwise the facing's own bit 0 picks the turn
HANDLE_LEFT_RIGHT_7:
  CALL GET_SPRITE_DIR     ; Left: facing 0 already? The same test as down
  AND A                   ;
  JR HANDLE_LEFT_RIGHT_6  ;
HANDLE_LEFT_RIGHT_8:
  SET 2,C                 ; Facing the way pushed: walk
  RET                     ;
HANDLE_LEFT_RIGHT_9:
  LD A,(IX+$0D)             ; Rotational: while the pause between turns (bits
  AND $07                   ; 0-2 of +$0D) runs, count it down and do nothing
  JR Z,HANDLE_LEFT_RIGHT_10 ; else
  DEC (IX+$0D)              ;
  RET                       ;
HANDLE_LEFT_RIGHT_10:
  LD A,C                  ; Neither turn control held
  AND $03                 ;
  RET Z                   ;
  LD A,(IX+$0C)           ; Not during the walk into a room
  AND $F0                 ;
  RET NZ                  ;
  BIT 3,(IX+$0C)          ; Not in the middle of a jump
  RET NZ                  ;
  BIT 2,C                    ; A jump to the next instruction: Knight Lore
  JR NZ,HANDLE_LEFT_RIGHT_11 ; plays a turning sound here when the player is
                             ; not walking, and this is what is left of it
HANDLE_LEFT_RIGHT_11:
  LD A,(IX+$0D)           ; A pause of two turns before the next quarter turn
  OR $02                  ;
  LD (IX+$0D),A           ;
  BIT 1,C                 ; Bit 1: right
HANDLE_LEFT_RIGHT_12:
  JR NZ,HANDLE_LEFT_RIGHT_15 ; NZ for a right turn, Z for a left
  BIT 6,(IX+$07)            ; Left turn: an unmirrored sprite only mirrors (2
  JR Z,HANDLE_LEFT_RIGHT_14 ; to 0, 3 to 1)
HANDLE_LEFT_RIGHT_13:
  LD A,(IX+$00)           ; Toggle the graphic's bit 2: the other view
  XOR $04                 ;
  LD (IX+$00),A           ;
HANDLE_LEFT_RIGHT_14:
  LD A,(IX+$07)           ; Toggle the mirror bit
  XOR $40                 ;
  LD (IX+$07),A           ;
  LD A,(IX+$00)           ; The body's graphic is the legs' plus 8
  ADD A,$08               ;
  LD (IX+$20),A           ;
  RET                     ;
HANDLE_LEFT_RIGHT_15:
  BIT 6,(IX+$07)            ; Right turn: a mirrored sprite only mirrors (0 to
  JR Z,HANDLE_LEFT_RIGHT_13 ; 2, 1 to 3); otherwise both
  JR HANDLE_LEFT_RIGHT_14   ;

; Start a jump
;
; Used by the routine at PLAYER_LEGS.
;
; A jump needs the jump control held, the walk into a room over, no jump
; already under way, and the player standing on something: bit 2 of +$0C, which
; the collision code (ADJ_FOR_OUT_OF_BOUNDS) sets when it stops a move down.
; Knight Lore tests the Z step here instead. The jump starts at 8 units up a
; turn; MOVE_PLAYER's gravity takes it away again.
;
; IX The player's legs
; C The controls
HANDLE_JUMP:
  BIT 3,C                 ; Jump not held
  RET Z                   ;
  LD A,(IX+$0C)           ; Not during the walk into a room
  AND $F0                 ;
  RET NZ                  ;
  BIT 3,(IX+$0C)          ; Already jumping
  RET NZ                  ;
  BIT 2,(IX+$0C)          ; Not standing on anything
  RET Z                   ;
  SET 3,(IX+$0C)          ; Jumping, 8 up
  LD (IX+$0B),$08         ;
  PUSH BC                 ; The jump's sound (JUMP_SOUND), the controls kept
  CALL JUMP_SOUND         ;
  POP BC                  ;
  RET

; Step the legs
;
; Used by the routine at PLAYER_LEGS.
;
; While the player walks, jumps or is walking into a room, the legs step on
; through their four frames -- the low two bits of the graphic -- and the
; footstep sound (FOOTSTEP) counts, sounding every fourth step. When none of
; those applies the legs carry on stepping to frame 2, the standing pose, and
; stop there. Knight Lore's cycle is six frames with two standing poses, and it
; carries on to them in silence; here the steps to the standing pose count
; towards a footstep too.
;
; IX The player's legs
; C The controls
HANDLE_FORWARD:
  LD A,(IX+$0C)           ; Walking into a room: step
  AND $F0                 ;
  JR NZ,HANDLE_FORWARD_0  ;
  BIT 3,(IX+$0C)          ; Jumping: step
  JR NZ,HANDLE_FORWARD_0  ;
  BIT 2,C                 ; Walk not held: go to the standing pose
  JR Z,HANDLE_FORWARD_1   ;
HANDLE_FORWARD_0:
  LD A,(IX+$00)           ; The next frame of four, in the graphic's low two
  LD E,A                  ; bits
  INC A                   ;
  AND $03                 ;
  LD D,A                  ;
  LD A,E                  ;
  AND $FC                 ;
  OR D                    ;
  LD (IX+$00),A           ;
  PUSH BC                 ; The footstep count and sound, the controls kept
  CALL FOOTSTEP           ;
  POP BC                  ;
  RET                     ;
HANDLE_FORWARD_1:
  LD A,(IX+$00)           ; Frame 2 is the standing pose: done
  AND $03                 ;
  CP $02                  ;
  RET Z                   ;
  JR HANDLE_FORWARD_0     ; Otherwise step on towards it

; Which way an object faces
;
; Used by the routines at FIRE, HANDLE_LEFT_RIGHT and CALC_PLYR_DUV.
;
; The facing, 0 to 3, from the two bits that store it: bit 6 of the flags
; (mirrored) clear gives 2, and bit 2 of the graphic adds 1. So 0 faces lower
; U, 1 higher U, 2 higher V and 3 lower V (see HANDLE_LEFT_RIGHT). Knight
; Lore's is the same with bit 3 of the type in place of bit 2.
;
;   IX The object
; O:A The facing
GET_SPRITE_DIR:
  LD A,(IX+$07)           ; L = 8 if the sprite is not mirrored
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  AND $08                 ;
  XOR $08                 ;
  LD L,A                  ;
  LD A,(IX+$00)           ; With the graphic's bit 2
  AND $04                 ;
  OR L                    ;
  RRCA                    ; Down to bits 1 and 0
  RRCA                    ;
  AND $03                 ;
  RET                     ;

; The player's update routine: body
;
; The body (graphics 40 to 47) has no movement of its own: each turn it copies
; the legs' position, half-sizes and flags, takes a height of zero and sets bit
; 1 of its flags, which keeps it out of every collision test -- the legs' box
; is the whole player's. Its graphic is the legs' plus 8, the same facing and
; frame, and it sits 12 above the legs when seen from behind (facings 0 and 2)
; and 8 above when seen from the front.
;
; Bits 0-3 of the body's +$0D are a count that would hold its own graphic for
; that many turns. Knight Lore sets it when it gives the head a random other
; frame; no code was found in Pentagram that sets it for the body, and the
; count never ran in the build's sessions.
;
; A body marked killed (bit 6 of +$0D, set by PLAYER_LEGS when the legs are)
; turns into the puff instead (START_PUFF).
;
; IX The body's record (PLAYER_BODY)
PLAYER_TOP:
  CALL DRAW_AT_L12_D8     ; Drawn 12 left and 8 down
  BIT 6,(IX+$0D)          ; Killed: become the puff
  JP NZ,START_PUFF        ;
  PUSH IX                 ; IY = HL = the legs, the record below
  POP DE                  ;
  LD HL,$FFE0             ;
  ADD HL,DE               ;
  PUSH HL                 ;
  POP IY                  ;
  INC DE                  ; U, V, Z, the half-sizes and the flags from the legs
  INC HL                  ;
  LD BC,$0007             ;
  LDIR                    ;
  LD (IX+$06),$00         ; Height 0
  SET 1,(IX+$07)          ; Bit 1: out of the collision tests
  LD A,(IX+$0D)           ; The count running?
  AND $0F                 ;
  JR Z,PLAYER_TOP_0       ;
  DEC (IX+$0D)            ; Yes: count it down and keep the graphic
  JR PLAYER_TOP_1         ;
PLAYER_TOP_0:
  LD A,(IY+$00)           ; Otherwise the legs' graphic plus 8
  ADD A,$08               ;
  LD (IX+$00),A           ;
PLAYER_TOP_1:
  LD A,(IY+$00)           ; Z: the legs' plus 12 for the view from behind (bit
  AND $04                 ; 2 clear), plus 8 for the front
  XOR $04                 ;
  ADD A,$08               ;
  ADD A,(IY+$03)          ;
  LD (IX+$03),A           ;
  CALL SET_DRAW_OBJS_OVERLAPPED ; Have it and whatever it overlaps redrawn
  RET                           ; (SET_DRAW_OBJS_OVERLAPPED)

; Move the player
;
; Used by the routine at PLAYER_LEGS.
;
; The player steps forward when walk is held, and also without it during a jump
; and during the walk into a room: 3 units in the way he faces, plus any nudge
; an arch has left him (CALC_PLYR_DUV). Then gravity: 2 off the Z step every
; turn, or 1 while he is still rising (or level) with jump held, so that
; holding jump jumps higher. The Z step is kept in Z_STEP before
; ADJ_FOR_OUT_OF_BOUNDS cuts the move short against the floor, the walls and
; the other objects, and then the move is made. A move down that was stopped
; (bit 2 of +$0C) is a landing, and ends the jump.
;
; Knight Lore's routine is the same with two calls taken out: the falling sound
; (the ADD A,2 before the collision code is its test, and nothing reads it now)
; and the check for walking out of the room, which here is an empty routine
; (EXIT_STUB) because Pentagram's arches do that themselves
; (HANDLE_EXIT_SCREEN).
;
; IX The player's legs
; C The controls
MOVE_PLAYER:
  BIT 3,(IX+$0C)          ; Jumping: forward
  JR NZ,MOVE_PLAYER_0     ;
  LD A,(IX+$0C)           ; Walking into a room: forward
  AND $F0                 ;
  JR NZ,MOVE_PLAYER_0     ;
  BIT 2,C                 ; Walk not held: no step
  JR Z,MOVE_PLAYER_1      ;
MOVE_PLAYER_0:
  PUSH BC                 ; A step forward, the controls kept
  CALL CALC_PLYR_DUV      ;
  POP BC                  ;
MOVE_PLAYER_1:
  LD A,(IX+$0B)           ; Z step negative: falling, two off
  AND A                   ;
  JP M,MOVE_PLAYER_2      ;
  BIT 3,C                 ; Rising or level with jump held: one off
  JR NZ,MOVE_PLAYER_3     ;
MOVE_PLAYER_2:
  DEC A                   ; Gravity: two off, or one
MOVE_PLAYER_3:
  DEC A                   ;
  LD (IX+$0B),A           ; The new Z step, and a copy that says afterwards
  LD (Z_STEP),A           ; which way he was going
  ADD A,$02               ; Left over from Knight Lore's falling sound: nothing
                          ; reads A
  CALL ADJ_FOR_OUT_OF_BOUNDS ; Cut the move short where it must be
  CALL EXIT_STUB          ; Knight Lore's exit check, now a RET
  CALL ADD_DUVZ           ; U, V and Z plus the steps
  BIT 2,(IX+$0C)          ; Stopped while moving down?
  JR Z,MOVE_PLAYER_4      ;
  LD A,(Z_STEP)           ;
  AND A                   ;
  JP P,MOVE_PLAYER_4      ;
  RES 3,(IX+$0C)          ; Then landed: the jump is over
MOVE_PLAYER_4:
  XOR A                   ; The U and V steps are one turn's; the Z step
  LD (IX+$09),A           ; carries over as the speed
  LD (IX+$0A),A           ;
  RET                     ;

; Add a step in the direction he faces
;
; Used by the routine at MOVE_PLAYER.
;
; First adds the nudge in +$0E and +$0F, which an arch leaves to steer the
; player onto its middle line (ARCH_NUDGE_TO_CENTRE), to the U and V steps, and
; clears it; then adds 3 in the direction of the facing, through WALK_STEP_TBL.
; So the nudge only acts while he walks.
;
; The last three instructions are a jump through a table of four addresses by
; the facing of the object at IX; ARCH_NUDGE_TO_CENTRE uses it too.
;
; IX The player's legs
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
; This entry point is used by the routine at ARCH_NUDGE_TO_CENTRE.
DISPATCH_ON_FACING:
  CALL GET_SPRITE_DIR     ; Jump to the entry for the facing (the main loop's
  LD L,A                  ; own dispatch at START does the rest)
  JP JUMP_TO_TBL_ENTRY    ;

; A step in each direction
;
; Four routine addresses, one per facing, used through the jump at the end of
; CALC_PLYR_DUV. Each adds 3 to, or takes 3 from, the U or V step.
WALK_STEP_TBL:
  DEFW STEP_U_DOWN        ; Facing 0: U - 3; 1: U + 3; 2: V + 3; 3: V - 3
  DEFW STEP_U_UP          ;
  DEFW STEP_V_UP          ;
  DEFW STEP_V_DOWN        ;

; Step towards lower U
;
; The U step less 3, for facing 0.
;
; IX The player's legs
STEP_U_DOWN:
  LD A,(IX+$09)           ; -3
  ADD A,$FD               ;
; This entry point is used by the routine at STEP_U_UP.
STEP_U_DOWN_0:
  LD (IX+$09),A           ; Store the U step
  RET

; Step towards higher U
;
; The U step plus 3, for facing 1.
;
; IX The player's legs
STEP_U_UP:
  LD A,(IX+$09)
  ADD A,$03
  JR STEP_U_DOWN_0

; Step towards higher V
;
; The V step plus 3, for facing 2.
;
; IX The player's legs
STEP_V_UP:
  LD A,(IX+$0A)
  ADD A,$03
; This entry point is used by the routine at STEP_V_DOWN.
STEP_V_UP_0:
  LD (IX+$0A),A           ; Store the V step
  RET

; Step towards lower V
;
; The V step less 3, for facing 3.
;
; IX The player's legs
STEP_V_DOWN:
  LD A,(IX+$0A)
  ADD A,$FD
  JR STEP_V_UP_0

; Where Knight Lore checks for walking out of the room
;
; Used by the routine at MOVE_PLAYER.
;
; A lone RET. MOVE_PLAYER calls it at the point in the move where Knight Lore
; calls its own exit check; in Pentagram the arch at the doorway decides that
; (HANDLE_EXIT_SCREEN), so this does nothing.
EXIT_STUB:
  RET

; Build the room he is in
;
; Used by the routine at START.
;
; Clears the screen buffer, builds the room's object records (BUILD_ROOM), puts
; the player in the doorway he came in by if he came through one
; (ADJUST_PLYR_UVZ_FOR_ROOM_SIZE), marks the room seen (MARK_ROOM_SEEN) and
; sets NEW_ROOM for the main loop (OBJECT_DONE), which redraws the panel and
; clears it.
ENTER_ROOM:
  LD IX,OBJECTS           ; IX = the player's legs, whose room is the one to
                          ; build
  CALL CLEAR_BUFFER
  CALL BUILD_ROOM
  CALL ADJUST_PLYR_UVZ_FOR_ROOM_SIZE
  CALL MARK_ROOM_SEEN
  LD A,$01                ; The room is new: NEW_ROOM
  LD (NEW_ROOM),A         ;
  RET                     ;

; Mark the player's room as seen
;
; Used by the routine at ENTER_ROOM.
;
; Sets the room's bit in ROOMS_SEEN: byte room/8, bit 7 minus room mod 8, so
; room 0 is bit 7 of the first byte. The 31 bytes have room for 248 rooms.
; PERCENTAGE counts them.
;
; IX The player's legs
MARK_ROOM_SEEN:
  LD A,(IX+$08)           ; E = the byte: the room number divided by 8
  RRA                     ;
  RRA                     ;
  RRA                     ;
  AND $1F                 ;
  LD E,A                  ;
  LD A,(IX+$08)           ; A = the bit: a carry rotated in from the top, as
  AND $07                 ; far as the room number's low three bits say
  LD B,A                  ;
  INC B                   ;
  XOR A                   ;
  SCF                     ;
MARK_ROOM_SEEN_0:
  RRA                     ;
  DJNZ MARK_ROOM_SEEN_0   ;
  LD D,$00                ; Set it in the map
  LD HL,ROOMS_SEEN        ;
  ADD HL,DE               ;
  OR (HL)                 ;
  LD (HL),A               ;
  RET                     ;

; Work out and print the percentage of the quest done
;
; Used by the routine at WON.
;
; For the game-over screen (WON). Two rooms seen count one per cent, up to 54
; (108 rooms or more); each quest item the bucket has reached counts 4
; (QUEST_DONE, four of them: 16); each collectable in its place in room 82
; counts 6 (PLACED, five: 30). 54, 16 and 30 make 100. The sum is counted up in
; BCD into PERCENT -- the hundreds, 0 or 1, then the tens and units -- and
; printed at pixel row 95, column 144 of the buffer: three digits at 100,
; otherwise two, with a leading zero.
;
; The count is a DJNZ loop, so a sum of 0 runs it 256 times and prints 56:
; measured in the simulator, a player who loses all five lives without leaving
; the room he started in is told 56 per cent. One room seen counts nothing,
; since the rooms are halved first, and two count 1.
PERCENTAGE:
  LD HL,ROOMS_SEEN        ; 31 bytes of the rooms-seen map, E counting
  LD C,$1F                ;
  LD E,$00                ;
PERCENTAGE_0:
  LD B,$08                ; Count the set bits
  LD A,(HL)               ;
PERCENTAGE_1:
  RRA                     ;
  JR NC,PERCENTAGE_2      ;
  INC E                   ;
PERCENTAGE_2:
  DJNZ PERCENTAGE_1       ;
  INC HL                  ;
  DEC C                   ;
  JR NZ,PERCENTAGE_0      ;
  SRL E                   ; Half the rooms seen, 54 at most
  LD A,E                  ;
  CP $36                  ;
  JR C,PERCENTAGE_3       ;
  LD E,$36                ;
PERCENTAGE_3:
  LD A,(QUEST_DONE)       ; Plus 4 for each quest item done
  ADD A,A                 ;
  ADD A,A                 ;
  ADD A,E                 ;
  LD E,A                  ;
  LD A,(PLACED)           ; Plus 6 for each collectable placed
  ADD A,A                 ;
  LD D,A                  ;
  ADD A,A                 ;
  ADD A,D                 ;
  ADD A,E                 ;
  LD B,A                  ;
  XOR A                   ; Count it up in BCD, one at a time
PERCENTAGE_4:
  ADD A,$01               ;
  DAA                     ;
  DJNZ PERCENTAGE_4       ;
  LD ($A74E),A            ; Tens and units; the carry out of the last is the
  LD A,$00                ; hundreds
  ADC A,$00               ;
  LD (PERCENT),A          ;
  EX AF,AF'               ; Keep the hundreds
  LD BC,$5F90             ; The place in the buffer to print at
  CALL CALC_VIDBUF_ADDR   ;
  LD L,C                  ;
  LD H,B                  ;
  EX AF,AF'               ; Three digits or two
  LD DE,PERCENT           ;
  LD B,$01                ;
  AND A                   ;
  JR Z,PERCENTAGE_5       ;
  INC B                   ; 100: the hundreds digit with the digits' font, then
  PUSH HL                 ; the other two (ADD_SCORE)
  LD HL,FONT              ;
  LD (FONT_BASE),HL       ;
  POP HL                  ;
  JP PRINT_BCD_LSD        ;
PERCENTAGE_5:
  INC HL                  ; Under 100: one place along, and the tens and units
  INC DE                  ; only
  JP PRINT_BCD            ;

; An unused RET
;
; Nothing calls or jumps here, and no graphic's update routine is this address.
; One more lies before CHK_PLYR_OOB.
STRAY_RET_OFFSETS:
  RET

; Drawing offset X -8, Y 0 (graphic 57)
;
; The whole update routine for graphic 57.
;
; A note for all the offset routines from here to DRAW_AT_L8_D2: +$12 and +$13
; of an object record are added to the pixel position CALC_PIXEL_XY works out
; from the object's U, V and Z, to line the sprite up with the object's
; position. X is pixels right and Y pixels up, so the usual negative values
; move the sprite left and down. For a still object that is all its update
; routine does; others call one to set the offset before they move. They all
; end at the end of DRAW_AT_L16_D12.
DRAW_AT_L8:
  LD HL,$00F8             ; Left 8
  JR SET_PIXEL_ADJ

; Three drawing offsets no graphic uses
;
; X -4, Y -12 at this address, X -36, Y -4 five bytes on, and X -20, Y -8 five
; bytes after that, each a LD HL and a JR to the end of DRAW_AT_L16_D12 like
; the routines round them. No entry of the update table (UPDATES) points at any
; of the three, and nothing calls them: offsets for graphics this version of
; the engine no longer has.
UNUSED_OFFSETS:
  LD HL,$F4FC             ; X -4, Y -12; X -36, Y -4; X -20, Y -8
  JR SET_PIXEL_ADJ        ;
  LD HL,$FCDC             ;
  JR SET_PIXEL_ADJ        ;
  LD HL,$F8EC             ;
  JR SET_PIXEL_ADJ        ;

; Drawing offset X -16, Y -8
;
; Used by the routines at TAKE_OR_LEAVE, STILL_DEADLY, JUMP_L16_D8,
; COLLECTABLE, PUSHABLE, SINKING_BLOCK, LIFT, BOBBER, DEADLY_PACER_U,
; DEADLY_PACER_V, PENTAGRAM_PIECE, SPIDER, QUEST_ITEM, WELL, BUCKET, ROAMER,
; SKY_WALKER, CRUMBLING_BLOCK, CONVEYOR_PLUS_U, CONVEYOR_MINUS_U,
; CONVEYOR_PLUS_V and CONVEYOR_MINUS_V.
;
; The offset of most of the things that move by themselves -- the collectables,
; the quest items, the well, the bucket and more -- and, through JUMP_L16_D8,
; the whole update routine of several still graphics.
DRAW_AT_L16_D8:
  LD HL,$F8F0             ; Left 16, down 8
  JR SET_PIXEL_ADJ

; Drawing offset X -12, Y -8
;
; Used by the routine at PLAYER_TOP.
;
; The player's body (PLAYER_TOP).
DRAW_AT_L12_D8:
  LD HL,$F8F4             ; Left 12, down 8
  JR SET_PIXEL_ADJ

; Drawing offset X -16, Y -12
;
; Used by the routines at JUMP_L16_D12 and HEAVY_BLOCK.
;
; Used through JUMP_L16_D12 (graphic 77) and by HEAVY_BLOCK.
DRAW_AT_L16_D12:
  LD HL,$F4F0             ; Left 16, down 12
  JR SET_PIXEL_ADJ
; This entry point is used by the routines at DRAW_AT_L8, UNUSED_OFFSETS,
; DRAW_AT_L16_D8, DRAW_AT_L12_D8, DRAW_AT_L12_D6, DRAW_AT_L12_D4,
; DRAW_AT_L8_D4, DRAW_AT_L8_D2, SECOND_PILLAR and FIRST_PILLAR.
SET_PIXEL_ADJ:
  LD (IX+$12),L           ; The shared end of all the offset routines: L to
  LD (IX+$13),H           ; +$12, H to +$13
  RET                     ;

; Drawing offset X -12, Y -6
;
; Used by the routines at BOLT, PLAYER_LEGS and HOMER.
;
; The player's legs (PLAYER_LEGS), the bolts (BOLT) and the homers (HOMER).
DRAW_AT_L12_D6:
  LD HL,$FAF4             ; Left 12, down 6
  JR SET_PIXEL_ADJ

; Drawing offset X -12, Y -4
;
; Used by the routines at PUFF and END_PUFF.
;
; The puff (PUFF, END_PUFF).
DRAW_AT_L12_D4:
  LD HL,$FCF4             ; Left 12, down 4
  JR SET_PIXEL_ADJ

; Drawing offset X -8, Y -4 (graphics 53 to 56)
;
; The whole update routine for graphics 53 to 56.
DRAW_AT_L8_D4:
  LD HL,$FCF8             ; Left 8, down 4
  JR SET_PIXEL_ADJ

; Drawing offset X -8, Y -2 (graphics 12 to 15 and 52)
;
; The whole update routine for graphics 12 to 15 and 52.
DRAW_AT_L8_D2:
  LD HL,$FEF8             ; Left 8, down 2
  JR SET_PIXEL_ADJ

; The second pillar of an arch (graphics 7 and 9)
;
; A doorway is two pillars, and this one only sets its drawing offset: the
; first pillar (FIRST_PILLAR) does the work. An arch in a wall of constant V is
; mirrored (bit 6 of its flags); one in a wall of constant U is not.
;
; IX The pillar's record
SECOND_PILLAR:
  BIT 6,(IX+$07)          ; Mirrored
  JR NZ,SECOND_PILLAR_0   ;
  LD A,(IX+$00)           ; Graphic 9 has an offset of its own
  CP $09                  ;
  JR Z,SECOND_PILLAR_1    ;
  LD HL,$FBF9             ; Graphic 7, not mirrored: X -7, Y -5
  JP SET_PIXEL_ADJ        ;
SECOND_PILLAR_0:
  LD HL,$FCF9             ; Mirrored: X -7, Y -4
  JP SET_PIXEL_ADJ        ;
SECOND_PILLAR_1:
  LD HL,$FBF0             ; Graphic 9, not mirrored: X -16, Y -5
  JP SET_PIXEL_ADJ        ;

; The first pillar of an arch: graphic 8, not mirrored
;
; Used by the routine at FIRST_PILLAR.
;
; X -8, Y -5, then the doorway as FIRST_PILLAR works it out.
;
; IX The pillar's record
FIRST_PILLAR_EIGHT:
  LD HL,$FBF8             ; Left 8, down 5
  JR ARCH_ALONG_U         ;

; The first pillar of an arch (graphics 6 and 8)
;
; This pillar is the doorway. It works out the point in the middle of the arch,
; 13 from itself along the wall, and keeps it in its own +$09 to +$0B -- the
; step fields, which a pillar never needs, borrowed because IS_NEAR_TO compares
; +$09 to +$0B of one record with +$01 to +$03 of another. Then
; HANDLE_EXIT_SCREEN lets the player out of the room if he is in the doorway
; and past the wall, and ARCH_NUDGE_TO_CENTRE nudges him onto the arch's middle
; line if he is near it.
;
; An arch in a wall of constant U (not mirrored) has its other pillar 13
; further along V, and its doorway reaches 15 either way in U and 6 in V; one
; in a wall of constant V (mirrored) has its other pillar 13 back along U, and
; a doorway 6 in U and 15 in V.
;
; A pillar's +$08 is not the room it stands in: the builder (BUILD_ROOM) gives
; every piece of a scenery entry the byte after the entry, which for a doorway
; is the room it leads to.
;
; IX The pillar's record
FIRST_PILLAR:
  BIT 6,(IX+$07)          ; Mirrored: an arch in a wall of constant V
  JR NZ,FIRST_PILLAR_0    ;
  LD A,(IX+$00)           ; Graphic 8 has an offset of its own
  CP $08                  ;
  JR Z,FIRST_PILLAR_EIGHT ;
  LD HL,$FBFB             ; Graphic 6, not mirrored: X -5, Y -5
; This entry point is used by the routine at FIRST_PILLAR_EIGHT.
ARCH_ALONG_U:
  CALL SET_PIXEL_ADJ      ; Set the offset
  LD A,(IX+$02)           ; V of the middle: this pillar's plus 13
  ADD A,$0D               ;
  LD (IX+$0A),A           ;
  LD A,(IX+$01)           ; U of the middle: this pillar's
  LD (IX+$09),A           ;
  LD HL,$060F             ; The doorway: U within 15, V within 6
ARCH_CHECK_DOORWAY:
  LD A,(IX+$03)           ; Z of the middle: the pillar's base
  LD (IX+$0B),A           ;
  CALL HANDLE_EXIT_SCREEN ; In the doorway and past the wall: out of the room,
                          ; and no return
  JP ARCH_NUDGE_TO_CENTRE ; Near it: nudge towards the middle
FIRST_PILLAR_0:
  LD A,(IX+$00)           ; Mirrored: graphic 8 has an offset of its own
  CP $08                  ;
  JR Z,FIRST_PILLAR_1     ;
  LD HL,$FAEF             ; Graphic 6, mirrored: X -17, Y -6
ARCH_ALONG_V:
  CALL SET_PIXEL_ADJ      ; Set the offset
  LD A,(IX+$01)           ; U of the middle: this pillar's less 13
  SUB $0D                 ;
  LD (IX+$09),A           ;
  LD A,(IX+$02)           ; V of the middle: this pillar's
  LD (IX+$0A),A           ;
  LD HL,$0F06             ; The doorway: U within 6, V within 15
  JR ARCH_CHECK_DOORWAY   ;
FIRST_PILLAR_1:
  LD HL,$FBF0             ; Graphic 8, mirrored: X -16, Y -5
  JR ARCH_ALONG_V         ;

; Is the player in the doorway, and has he walked out of the room?
;
; Used by the routine at FIRST_PILLAR.
;
; Only the player's legs, record 0, can use a doorway, and only while their
; graphic is one of 16 to 47 -- which leaves out the puff he becomes when he
; dies -- and bit 3 of the flags is set. In the doorway (IS_NEAR_TO, with the
; limits the pillar gives), bit 0 of the legs' flags is set: while it is, the
; collision code (ADJ_FOR_OUT_OF_BOUNDS) lets him past the line of the wall,
; and PLAYER_LEGS clears it again at the end of his next update. Then one of
; four routines (SCREEN_MOVE_TBL), by the way he faces, decides whether he is
; wholly past the wall he faces.
;
; This is Knight Lore's doorway check and its exit check in one. Knight Lore
; marks the player in the doorway from the arch and decides the exit in the
; player's own move; Pentagram leaves the move alone (EXIT_STUB) and decides
; here, from the player's position after his move rather than from his position
; plus the step. The room's half-sizes (ROOM_EXTENT) are pushed for the four,
; because the dispatch uses HL.
;
; IX The first pillar, holding the arch's middle at +$09 to +$0B
; L How near in U
; H How near in V
HANDLE_EXIT_SCREEN:
  LD IY,OBJECTS           ; The player's legs, graphics 16 to 47 only
  LD A,(IY+$00)           ;
  SUB $10                 ;
  CP $20                  ;
  RET NC                  ;
  BIT 3,(IY+$07)          ; Not one that uses doorways
  RET Z                   ;
  CALL IS_NEAR_TO         ; Not in the doorway
  RET NC                  ;
  SET 0,(IY+$07)          ; In it: he may cross the line of the wall
  LD BC,SCREEN_MOVE_TBL   ; The four exits, and the room's half-sizes in U and
  LD HL,(ROOM_EXTENT)     ; V for them
  PUSH HL                 ;
  LD A,(IY+$07)           ; Jump to the exit for the way he faces
  RRCA                    ; (GET_SPRITE_DIR's sum, done here for IY)
  RRCA                    ;
  RRCA                    ;
  AND $08                 ;
  XOR $08                 ;
  LD L,A                  ;
  LD A,(IY+$00)           ;
  AND $04                 ;
  OR L                    ;
  RRCA                    ;
  RRCA                    ;
  AND $03                 ;
  LD L,A                  ;
  JP JUMP_TO_TBL_ENTRY    ;

; Leaving a room, by facing
;
; Four routine addresses in facing order, used by HANDLE_EXIT_SCREEN.
SCREEN_MOVE_TBL:
  DEFW EXIT_LOW_U         ; Facing 0: EXIT_LOW_U; 1: EXIT_HIGH_U; 2:
  DEFW EXIT_HIGH_U        ; EXIT_HIGH_V; 3: EXIT_LOW_V
  DEFW EXIT_HIGH_V        ;
  DEFW EXIT_LOW_V         ;

; Out through the wall at low U?
;
; Out if the player's far edge -- U plus his half-size -- is below the wall at
; 128 less the room's half-size. U is then set to 0: not a position but a
; marker, which ADJUST_PLYR_UVZ_FOR_ROOM_SIZE sees when the next room is built
; and puts him in the doorway of its wall at high U. The other exits use $FF
; and 0 the same way.
;
; IY The player's legs
; IX The pillar
EXIT_LOW_U:
  POP HL                  ; L = the wall
  LD A,$80                ;
  SUB L                   ;
  LD L,A                  ;
  LD A,(IY+$01)           ; Still at or past it: stay
  ADD A,(IY+$04)          ;
  CP L                    ;
  RET NC                  ;
  LD (IY+$01),$00         ; Arrive at the wall at high U
; This entry point is used by the routines at EXIT_HIGH_U, EXIT_HIGH_V and
; EXIT_LOW_V.
EXIT_SCREEN:
  LD A,(IX+$08)           ; The new room: the one the pillar's doorway leads to
  LD (IY+$08),A           ;
  LD A,(IY+$0C)           ; The walk into a room: three turns (bits 4-7 of
  OR $30                  ; +$0C) of walking straight on
  LD (IY+$0C),A           ;
  PUSH IY                 ; Both player records to PLAYER_TEMPLATE, so that a
  POP HL                  ; life lost in the new room starts again at this
  LD DE,PLAYER_TEMPLATE   ; doorway
  LD BC,$0040             ;
  LDIR                    ;
  INC SP                  ; Drop the returns to FIRST_PILLAR and to the main
  INC SP                  ; loop
  INC SP                  ;
  INC SP                  ;
  JP GAME_LOOP            ; Build the new room and carry on from there (START)

; Out through the wall at high U?
;
; As EXIT_LOW_U the other way: out if the near edge, U less the half-size, is
; at or past the wall at 128 plus the room's half-size. U becomes the marker
; $FF: arrive at the wall at low U.
;
; IY The player's legs
; IX The pillar
EXIT_HIGH_U:
  POP HL                  ; L = the wall
  LD A,L                  ;
  ADD A,$80               ;
  LD L,A                  ;
  LD A,(IY+$01)           ; Short of it: stay
  SUB (IY+$04)            ;
  CP L                    ;
  RET C                   ;
  LD (IY+$01),$FF         ; Arrive at the wall at low U
  JR EXIT_SCREEN          ;

; Out through the wall at high V?
;
; Out if the near edge in V is at or past the wall at 128 plus the room's
; half-size in V. V becomes the marker $FF: arrive at the wall at low V.
;
; IY The player's legs
; IX The pillar
EXIT_HIGH_V:
  POP HL                  ; H = the wall
  LD A,H                  ;
  ADD A,$80               ;
  LD H,A                  ;
  LD A,(IY+$02)           ; Short of it: stay
  SUB (IY+$05)            ;
  CP H                    ;
  RET C                   ;
  LD (IY+$02),$FF         ; Arrive at the wall at low V
  JR EXIT_SCREEN          ;

; Out through the wall at low V?
;
; Out if the far edge in V is below the wall at 128 less the room's half-size
; in V. V becomes the marker 0: arrive at the wall at high V.
;
; IY The player's legs
; IX The pillar
EXIT_LOW_V:
  POP HL                  ; H = the wall
  LD A,$80                ;
  SUB H                   ;
  LD H,A                  ;
  LD A,(IY+$02)           ; Still at or past it: stay
  ADD A,(IY+$05)          ;
  CP H                    ;
  RET NC                  ;
  LD (IY+$02),$00         ; Arrive at the wall at high V
  JR EXIT_SCREEN          ;

; Is an object near a point?
;
; Used by the routines at HANDLE_EXIT_SCREEN and ARCH_NUDGE_TO_CENTRE.
;
; Carry set if the object's U, V and Z are all within the limits of the point:
; strictly less than L in U, H in V and 4 in Z. As Knight Lore's.
;
;   IX A record whose +$09 to +$0B hold the point's U, V and Z
;   IY The object
;   L The limit in U
;   H The limit in V
; O:F Carry set if near
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

; Nudge the player towards the middle of an arch
;
; Used by the routine at FIRST_PILLAR.
;
; If the player's legs are within 15 of the arch's middle in U and V and 4 in
; Z, sets a nudge of one unit towards its middle line in +$0E (U) or +$0F (V),
; which CALC_PLYR_DUV adds to his step when he next walks: this is why he
; slides into line with an arch as he walks through. An arch in a wall of
; constant U (not mirrored) nudges along V; one in a wall of constant V along
; U.
;
; The routine is picked from ROUTINES_BIT3_SET, through the jump at the end of
; CALC_PLYR_DUV, by the pillar's own facing. Knight Lore does the same for each
; of the player's records; here only the legs are nudged.
;
; IX The first pillar, holding the arch's middle at +$09 to +$0B
ARCH_NUDGE_TO_CENTRE:
  LD HL,$0F0F             ; 15 either way in U and V
  LD IY,OBJECTS           ; The player's legs, if there are any
  LD A,(IY+$00)           ;
  AND A                   ;
  RET Z                   ;
  BIT 3,(IY+$07)          ; Not one that uses doorways
  RET Z                   ;
  CALL IS_NEAR_TO         ; Not near
  RET NC                  ;
  LD BC,ROUTINES_BIT3_SET  ; Graphic 8: the first table
  BIT 3,(IX+$00)           ;
  JP NZ,DISPATCH_ON_FACING ;
  LD BC,ROUTINES_BIT3_CLEAR ; Graphic 6: the second
  JP DISPATCH_ON_FACING     ;

; Two tables of four nudge routines
;
; ARCH_NUDGE_TO_CENTRE picks the first for a pillar whose graphic has bit 3 set
; (graphic 8), the second for one without (graphic 6), and the entry by the
; pillar's facing (GET_SPRITE_DIR). Graphic 8 has bit 2 clear, so it only ever
; looks up entries 0 (mirrored) and 2; graphic 6 has it set and only looks up 1
; (mirrored) and 3. Each of those four gives the same answer -- mirrored: along
; U, not: along V -- and the other four are never used.
ROUTINES_BIT3_SET:
  DEFW NUDGE_ALONG_U      ; Graphic 8, mirrored: NUDGE_ALONG_U
  DEFW NUDGE_ALONG_V      ; Unused
  DEFW NUDGE_ALONG_V      ; Graphic 8, not mirrored: NUDGE_ALONG_V
  DEFW NUDGE_ALONG_U      ; Unused
ROUTINES_BIT3_CLEAR:
  DEFW NUDGE_ALONG_V      ; Unused
  DEFW NUDGE_ALONG_U      ; Graphic 6, mirrored: NUDGE_ALONG_U
  DEFW NUDGE_ALONG_U      ; Unused
  DEFW NUDGE_ALONG_V      ; Graphic 6, not mirrored: NUDGE_ALONG_V

; Nudge along V
;
; For an arch in a wall of constant U: nothing if the player is on its middle
; line already, otherwise +1 or -1 into +$0F, towards it.
;
; IX The pillar, holding the arch's middle
; IY The player's legs
NUDGE_ALONG_V:
  LD A,(IX+$0A)           ; On the middle line already
  CP (IY+$02)             ;
  JR Z,NUDGE_ALONG_U_1    ;
  LD A,$01                ; +1 if the middle is at a greater V, else -1
  JR NC,NUDGE_ALONG_V_0   ;
  NEG                     ;
NUDGE_ALONG_V_0:
  LD (IY+$0F),A           ; The V nudge
  JR NUDGE_ALONG_U_1      ;

; Nudge along U
;
; For an arch in a wall of constant V: +1 or -1 into +$0E, towards its middle
; line.
;
; IX The pillar, holding the arch's middle
; IY The player's legs
NUDGE_ALONG_U:
  LD A,(IX+$09)           ; On the middle line already
  CP (IY+$01)             ;
  JR Z,NUDGE_ALONG_U_1    ;
  LD A,$01                ; +1 if the middle is at a greater U, else -1
  JR NC,NUDGE_ALONG_U_0   ;
  NEG                     ;
NUDGE_ALONG_U_0:
  LD (IY+$0E),A           ; The U nudge
; This entry point is used by the routine at NUDGE_ALONG_V.
NUDGE_ALONG_U_1:
  RET

; Build a room's object records from the room directory
;
; Used by the routine at ENTER_ROOM.
;
; Clears every object record but the player's two, finds the player's room in
; ROOMS, and sets the room's colour (ROOM_ATTR) and its half-sizes and floor
; (ROOM_EXTENT, from ROOM_SIZES). Then fills the records from the top,
; ROOM_FIRST, downwards: first the scenery, then the objects. Nothing checks
; that the 48 records are enough.
;
; Scenery: each entry is a template number and one more byte, up to an $FF. A
; scenery template (SCENERY_TABLE) is a list of 8-byte pieces -- graphic, U, V,
; Z, the three half-sizes, flags -- ended by a zero, each piece its own record.
; Every piece of the entry takes the entry's second byte as its +$08: for a
; doorway that is the room it leads to (FIRST_PILLAR).
;
; Objects: groups, each a header byte (bits 0-2 how many less one, bits 3-7 the
; template) and a position byte for each. An object template (OBJECT_TABLE) is
; a list of 5-byte pieces -- graphic, the three half-sizes, flags -- ended by a
; zero, each piece its own record, all at the same place. A position byte gives
; U = 72 + 16 times bits 0-2, V = 72 + 16 times bits 3-5, and Z = the floor +
; 12 times bits 6-7; the object's +$08 is this room.
;
; Template 31 in a header is not a template: it moves TEMPLATES_AT on 64 bytes,
; to a second page of templates, and the byte after it is skipped. No room uses
; it (it never ran). PLACE_NUDGE would add 8 to U (bit 0), 8 to V (bit 1) and
; the rest to Z; it is cleared here and nothing sets it but the unreached code
; at SET_PLACE_NUDGE.
;
; The count at +1 of the room's record, of the bytes from there to the end, is
; what stops the build, not the end of the data: the scenery can use it up, or
; a group be cut short.
;
; IX The player's legs, whose +$08 is the room
BUILD_ROOM:
  CALL CLEAR_OBJECTS      ; Clear the other object records
  LD HL,OBJECT_TABLE      ; The first page of object templates, and no nudge
  LD (TEMPLATES_AT),HL    ;
  XOR A                   ;
  LD (PLACE_NUDGE),A      ;
  LD DE,ROOM_FIRST        ; The first record to fill, the scenery table, the
  LD BC,SCENERY_TABLE     ; directory
  LD HL,ROOMS             ;
BUILD_ROOM_0:
  LD A,(HL)               ; This room?
  INC HL                  ;
  CP (IX+$08)             ;
  JR Z,BUILD_ROOM_1       ;
  LD A,(HL)               ; No: on by the count
  CALL ADD_HL_A           ;
  AND A                   ; A comparison with the scenery table, whose result
  SBC HL,BC               ; nothing uses: the room is assumed to be there
  ADD HL,BC               ;
  JR BUILD_ROOM_0         ; Next room
BUILD_ROOM_1:
  LD B,(HL)               ; B = the count
  INC HL                  ; The room's ink, BRIGHT, on black
  LD A,(HL)               ;
  AND $07                 ;
  OR $40                  ;
  LD (ROOM_ATTR),A        ;
  PUSH DE                 ; The room's size, bits 3-7 of the same byte
  EX DE,HL                ;
  LD A,(DE)               ;
  INC DE                  ;
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  AND $1F                 ;
  LD C,A                  ;
  ADD A,A                 ; Three bytes of ROOM_SIZES: the half-sizes in U and
  ADD A,C                 ; V, and the floor
  LD HL,ROOM_SIZES        ;
  CALL ADD_HL_A           ;
  LD A,(HL)               ;
  INC HL                  ;
  LD (ROOM_EXTENT),A      ;
  LD A,(HL)               ;
  INC HL                  ;
  LD ($A71E),A            ;
  LD A,(HL)               ;
  LD ($A71F),A            ;
  DEC B                   ; Two of the count used; HL on the scenery, DE the
  DEC B                   ; record
  EX DE,HL                ;
  POP DE                  ;
BUILD_ROOM_2:
  LD A,(HL)               ; The scenery ends at an $FF
  INC HL                  ;
  CP $FF                  ;
  JR Z,BUILD_ROOM_4       ;
  PUSH BC                 ; HL = the scenery template, the entry kept on the
  PUSH HL                 ; stack
  LD L,A                  ;
  LD H,$00                ;
  ADD HL,HL               ;
  LD BC,SCENERY_TABLE     ;
  ADD HL,BC               ;
  LD A,(HL)               ;
  INC HL                  ;
  LD H,(HL)               ;
  LD L,A                  ;
BUILD_ROOM_3:
  LD BC,$0008             ; A piece: graphic, U, V, Z, half-sizes, flags
  LDIR                    ;
  EX (SP),HL              ; +$08: the entry's second byte
  LD A,(HL)               ;
  EX (SP),HL              ;
  LD (DE),A               ;
  INC DE                  ;
  LD B,$17                ; +$09 to +$1F cleared
  CALL CLEAR_BYTES        ;
  PUSH HL                 ; The record below
  LD HL,$FFC0             ;
  ADD HL,DE               ;
  EX DE,HL                ;
  POP HL                  ;
NEXT_PIECE:
  LD A,(HL)               ; Another piece?
  AND A                   ;
  JR NZ,BUILD_ROOM_3      ;
  POP HL                  ; Past the entry's second byte; two of the count, and
  POP BC                  ; on to the next entry
  INC HL                  ;
  DEC B                   ;
  DJNZ BUILD_ROOM_2       ;
  RET                     ; The count ran out
BUILD_ROOM_4:
  DEC B                   ; The $FF counted
  PUSH IY                 ; IY = the next record
  PUSH DE                 ;
  POP IY                  ;
NEXT_GROUP:
  LD A,(HL)               ; C = how many in this group
  AND $07                 ;
  INC A                   ;
  LD C,A                  ;
  LD A,(HL)               ; The header counted; D = the first position
  INC HL                  ;
  DEC B                   ;
  LD D,(HL)               ;
  INC HL                  ;
  PUSH HL                 ;
  RRCA                    ; The template number, doubled; 31 moves to the
  RRCA                    ; second page
  AND $3E                 ;
  CP $3E                  ;
  JP Z,TEMPLATE_PAGE      ;
  LD HL,(TEMPLATES_AT)    ; HL = the object template
  CALL ADD_HL_A           ;
  LD A,(HL)               ;
  INC HL                  ;
  LD H,(HL)               ;
  LD L,A                  ;
BUILD_ROOM_5:
  PUSH HL                 ; Kept for the next object of the group
BUILD_ROOM_6:
  LD A,(HL)               ; A piece: graphic, half-sizes, flags
  INC HL                  ;
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
  LD A,(IX+$08)           ; This room
  LD (IY+$08),A           ;
  LD A,(PLACE_NUDGE)      ; U from bits 0-2 of the position
  RLCA                    ;
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
  LD A,(PLACE_NUDGE)      ; V from bits 3-5
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
  LD A,D                  ; Z from bits 6-7, 12 a level, on the floor
  RLCA                    ;
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
  LD A,($A71F)            ;
  ADD A,E                 ;
  LD (IY+$03),A           ;
  PUSH BC                 ; +$09 to +$1F cleared
  LD BC,$0009             ;
  ADD IY,BC               ;
  LD B,$17                ;
BUILD_ROOM_7:
  LD (IY+$00),$00         ;
  INC IY                  ;
  DJNZ BUILD_ROOM_7       ;
  LD BC,$FFC0             ; The record below
  ADD IY,BC               ;
  POP BC                  ;
  LD A,(HL)               ; Another piece?
  AND A                   ;
  JR NZ,BUILD_ROOM_6      ;
  POP DE                  ; The position counted; the end of the count ends the
  POP HL                  ; room
  DEC B                   ;
  JR Z,BUILD_ROOM_8       ;
  DEC C                   ; The end of the group
  JP Z,NEXT_GROUP         ;
  LD A,(HL)               ; The next position, the same template
  INC HL                  ;
  PUSH HL                 ;
  EX DE,HL                ;
  LD D,A                  ;
  JP BUILD_ROOM_5         ;
BUILD_ROOM_8:
  PUSH IY                 ; DE = the next free record
  POP DE                  ;
  POP IY                  ;
  RET                     ;
TEMPLATE_PAGE:
  LD HL,(TEMPLATES_AT)    ; Template 31: the next page of templates
  LD A,$40                ;
  CALL ADD_HL_A           ;
  LD (TEMPLATES_AT),HL    ;
  DEC B                   ; The byte after it counted and skipped
  POP HL                  ;
  JP NEXT_GROUP           ;

; Unreached code: set the builder's nudge
;
; Six bytes no jump reaches: LD A,D, then LD (PLACE_NUDGE),A, then JR back to
; the step in BUILD_ROOM after template 31 that counts the byte after the
; header and goes on to the next group. That is a header like template 31's
; which set PLACE_NUDGE from the byte after it, for the objects that follow.
; Nothing jumps here, so the nudge is always 0; the bytes are kept as data
; because their second instruction runs across SET_PLACE_NUDGE_END.
SET_PLACE_NUDGE:
  DEFB $7A,$32,$3C

; The rest of the unreached code
;
; The last byte of LD (PLACE_NUDGE),A and a JR back to BUILD_ROOM: see
; SET_PLACE_NUDGE.
SET_PLACE_NUDGE_END:
  DEFB $A7,$18,$F5

; Put the player in the doorway he came in by
;
; Used by the routine at ENTER_ROOM.
;
; Called when a room has been built. A U or V of 0 or $FF is the marker an exit
; (EXIT_LOW_U to EXIT_LOW_V) left: 0 in U means he left through a wall at low U
; and comes in by this room's wall at high U, $FF the other way, and the same
; for V. He is put with his inner edge 2 inside the wall's line, the rest of
; him in the doorway, and the walk into a room brings him in. FIND_ENTRY_ARCH
; finds the arch in that wall and lines him up with its middle and its floor.
; Without a marker -- a new game, or a life lost where one began -- he stays
; where his record says.
;
; Knight Lore does the same with the same markers; the walls are where the
; room's size (ROOM_SIZES) puts them, so the doorway's place is worked out from
; ROOM_EXTENT.
;
; IX The player's legs
ADJUST_PLYR_UVZ_FOR_ROOM_SIZE:
  LD A,(ROOM_EXTENT)      ; L, H = the room's half-sizes in U and V, less 2
  SUB $02                 ;
  LD L,A                  ;
  LD A,($A71E)            ;
  SUB $02                 ;
  LD H,A                  ;
  LD A,(IX+$01)                        ; U 0: came in at high U
  AND A                                ;
  JR Z,ADJUST_PLYR_UVZ_FOR_ROOM_SIZE_6 ;
  INC A                                ; U $FF: came in at low U
  JR Z,ADJUST_PLYR_UVZ_FOR_ROOM_SIZE_4 ;
  LD A,(IX+$02)                        ; V 0: came in at high V
  AND A                                ;
  JR Z,ADJUST_PLYR_UVZ_FOR_ROOM_SIZE_3 ;
  INC A                                ; V $FF: came in at low V; otherwise
  JR Z,ADJUST_PLYR_UVZ_FOR_ROOM_SIZE_0 ; nothing to do
  RET                                  ;
ADJUST_PLYR_UVZ_FOR_ROOM_SIZE_0:
  LD C,$03                ; At low V: the arch there, and V puts his inner edge
  CALL FIND_ENTRY_ARCH    ; 2 inside the wall
  LD A,$80                ;
  SUB H                   ;
  SUB (IX+$05)            ;
ADJUST_PLYR_UVZ_FOR_ROOM_SIZE_1:
  LD (IX+$02),A           ; Store V
ADJUST_PLYR_UVZ_FOR_ROOM_SIZE_2:
  SET 4,(IX+$07)          ; Draw both of his records
  SET 4,(IX+$27)          ;
  LD A,(IX+$01)           ; The body at the same U and V
  LD (IX+$21),A           ;
  LD A,(IX+$02)           ;
  LD (IX+$22),A           ;
  RET                     ;
ADJUST_PLYR_UVZ_FOR_ROOM_SIZE_3:
  LD C,$02                           ; At high V
  CALL FIND_ENTRY_ARCH               ;
  LD A,H                             ;
  ADD A,$80                          ;
  ADD A,(IX+$05)                     ;
  JR ADJUST_PLYR_UVZ_FOR_ROOM_SIZE_1 ;
ADJUST_PLYR_UVZ_FOR_ROOM_SIZE_4:
  LD C,$01                ; At low U
  CALL FIND_ENTRY_ARCH    ;
  LD A,$80                ;
  SUB L                   ;
  SUB (IX+$04)            ;
ADJUST_PLYR_UVZ_FOR_ROOM_SIZE_5:
  LD (IX+$01),A                      ; Store U
  JR ADJUST_PLYR_UVZ_FOR_ROOM_SIZE_2 ;
ADJUST_PLYR_UVZ_FOR_ROOM_SIZE_6:
  LD C,$00                           ; At high U
  CALL FIND_ENTRY_ARCH               ;
  LD A,L                             ;
  ADD A,$80                          ;
  ADD A,(IX+$04)                     ;
  JR ADJUST_PLYR_UVZ_FOR_ROOM_SIZE_5 ;

; Line the player up with the arch he comes in by
;
; Used by the routine at ADJUST_PLYR_UVZ_FOR_ROOM_SIZE.
;
; The code takes the room's doorways to be its first scenery entries, two
; pieces each, and each entry's second piece -- the first pillar, graphic 6 or
; 8, at the second record from the top and every other record down from there
; -- is what this looks at, until one is not an arch piece (graphics 6 to 9) or
; four have been tried. The one in the wall he comes in by (U or V at least 192
; for a wall at the high end, below 64 for the low) gives him the middle of the
; arch along the wall and its Z; the body goes 12 above.
;
; C The wall: 0 high U, 1 low U, 2 high V, 3 low V
; IX The player's legs
FIND_ENTRY_ARCH:
  LD IY,ROOM_SECOND       ; Four doorways at most, two records apart
  LD DE,$FFC0             ;
  LD B,$04                ;
FIND_ENTRY_ARCH_0:
  LD A,(IY+$00)           ; Not an arch piece: no more doorways
  SUB $06                 ;
  CP $04                  ;
  RET NC                  ;
  LD A,C                  ; Which wall
  AND A                   ;
  JR Z,ARCH_AT_HIGH_U     ;
  DEC A                   ;
  JR Z,ARCH_AT_LOW_U      ;
  DEC A                   ;
  JR Z,ARCH_AT_HIGH_V     ;
ARCH_AT_LOW_V:
  LD A,(IY+$02)           ; Low V: an arch with V below 64
  CP $40                  ;
  JR C,ALIGN_U_TO_ARCH    ;
; This entry point is used by the routines at ARCH_AT_HIGH_U, ARCH_AT_LOW_U and
; ARCH_AT_HIGH_V.
NEXT_ARCH:
  ADD IY,DE               ; The next doorway
  DJNZ FIND_ENTRY_ARCH_0  ;
  RET                     ; None in that wall: he keeps the U or V he left with

; Line up in V with an arch in a wall of constant U
;
; Used by the routines at ARCH_AT_HIGH_U and ARCH_AT_LOW_U.
;
; V of the arch's middle, 13 on from the first pillar; then, from the fifth
; instruction on, Z.
;
; IY The first pillar
; IX The player's legs
ALIGN_V_TO_ARCH:
  LD A,(IY+$02)           ; V: the middle of the arch
  ADD A,$0D               ;
  LD (IX+$02),A           ;
; This entry point is used by the routine at ALIGN_U_TO_ARCH.
ALIGN_Z_TO_ARCH:
  LD A,(IY+$03)           ; Z: the pillar's base
  LD (IX+$03),A           ;
  ADD A,$0C               ; The body, 12 above
  LD (IX+$23),A           ;
  RET                     ;

; Line up in U with an arch in a wall of constant V
;
; Used by the routines at FIND_ENTRY_ARCH and ARCH_AT_HIGH_V.
;
; U of the arch's middle, 13 back from the first pillar; then Z
; (ALIGN_V_TO_ARCH).
;
; IY The first pillar
; IX The player's legs
ALIGN_U_TO_ARCH:
  LD A,(IY+$01)
  SUB $0D
  LD (IX+$01),A
  JR ALIGN_Z_TO_ARCH

; An arch in the wall at high U?
;
; Used by the routine at FIND_ENTRY_ARCH.
;
; Part of FIND_ENTRY_ARCH: an arch with U 192 or more lines him up in V.
ARCH_AT_HIGH_U:
  LD A,(IY+$01)           ; The wall at high U: this one
  CP $C0                  ;
  JR NC,ALIGN_V_TO_ARCH   ;
  JR NEXT_ARCH            ; Otherwise the next

; An arch in the wall at low U?
;
; Used by the routine at FIND_ENTRY_ARCH.
;
; Part of FIND_ENTRY_ARCH: U below 64.
ARCH_AT_LOW_U:
  LD A,(IY+$01)           ; The wall at low U: this one
  CP $40                  ;
  JR C,ALIGN_V_TO_ARCH    ;
  JR NEXT_ARCH            ; Otherwise the next

; An arch in the wall at high V?
;
; Used by the routine at FIND_ENTRY_ARCH.
;
; Part of FIND_ENTRY_ARCH: V 192 or more lines him up in U.
ARCH_AT_HIGH_V:
  LD A,(IY+$02)           ; The wall at high V: this one
  CP $C0                  ;
  JR NC,ALIGN_U_TO_ARCH   ;
  JR NEXT_ARCH            ; Otherwise the next

; Drawing offset X -16, Y -8, by a jump (graphics 10, 11, 76, 82 and 152 to
; 159)
;
; The whole update routine for these still graphics: a JP to DRAW_AT_L16_D8,
; which is a routine of its own rather than a table entry pointing there
; directly.
JUMP_L16_D8:
  JP DRAW_AT_L16_D8

; Drawing offset X -16, Y -12, by a jump (graphic 77)
;
; A JP to DRAW_AT_L16_D12. No scenery or object template has graphic 77, and
; this never ran in the build's sessions.
JUMP_L16_D12:
  JP DRAW_AT_L16_D12

; Clear every object record but the player's
;
; Used by the routine at BUILD_ROOM.
;
; 52 records of 32 bytes from BOLTS: the bolts, the things from the sky and the
; room's 48.
CLEAR_OBJECTS:
  LD HL,BOLTS             ; Through CLEAR_MEMORY
  LD BC,$0680             ;
  JR CLEAR_MEMORY         ;

; Clear the screen's pixels
;
; Used by the routine at START.
;
; 6144 bytes from 16384.
CLEAR_SCREEN:
  LD HL,$4000
  LD DE,$4001
  LD BC,$1800
  LD (HL),$00
  LDIR
  RET

; Fill the screen's attributes with A
;
; Used by the routines at START, OBJECT_DONE and WON.
;
; 768 bytes from 22528.
;
; A The attribute
FILL_ATTRS:
  LD HL,$5800
  LD DE,$5801
  LD BC,$0300
  LD (HL),A
  LDIR
  RET

; Clear BC bytes from HL
;
; Used by the routines at START, CLEAR_OBJECTS and CLEAR_BUFFER.
;
; HL The first byte
; BC How many
CLEAR_MEMORY:
  LD E,$00
CLEAR_MEMORY_0:
  LD (HL),E               ; One at a time: BC is a 16-bit count
  INC HL                  ;
  DEC BC                  ;
  LD A,B                  ;
  OR C                    ;
  JR NZ,CLEAR_MEMORY_0    ;
  RET

; Clear the screen buffer
;
; Used by the routines at MENU, WON and ENTER_ROOM.
;
; 6144 bytes of BUFFER.
CLEAR_BUFFER:
  LD BC,$1800
  LD HL,BUFFER
  JR CLEAR_MEMORY

; Decide whether things may fall from the sky in this room
;
; Used by the routine at START.
;
; Sets DROP_BAN to 1 if any of the room's 48 records holds the well (graphic
; 120), a quest item (112 to 119) or a piece of the pentagram (128 to 135), and
; to 0 otherwise. SKY_DROP drops nothing while it is 1.
BAN_DROPS:
  CALL ROOM_OBJECT_LOOP   ; IY, B, DE: the room's 48 records (ROOM_OBJECT_LOOP)
  LD C,$70                ;
BAN_DROPS_0:
  LD A,(IY+$00)           ; The well
  CP $78                  ;
  JR Z,BAN_DROPS_2        ;
  AND $F8                 ; A quest item, done or not
  CP C                    ;
  JR Z,BAN_DROPS_2        ;
  CP $80                  ; A piece of the pentagram
  JR Z,BAN_DROPS_2        ;
  ADD IY,DE               ; None of them: things may fall
  DJNZ BAN_DROPS_0        ;
  XOR A                   ;
BAN_DROPS_1:
  LD (DROP_BAN),A         ;
  RET
BAN_DROPS_2:
  LD A,$01                ; One of them: nothing falls
  JR BAN_DROPS_1          ;

; Perhaps drop something from the sky
;
; Used by the routine at START.
;
; Once a turn, from the main loop. When DROP_TIMER runs out it stays at 1, so
; from then on there is a one-in-four chance each turn (two bits of RANDOM). A
; drop resets the timer (RESET_DROP_TIMER) whether or not it comes to anything,
; then takes a free one of the two records at FLYERS, copies FLYER_TEMPLATE
; into it, and gives it a U and a V at random and one of the eight graphics at
; DROP_GRAPHICS. If the new thing overlaps anything already in the room it is
; taken away again.
;
; The random U and V are 104 plus a number masked with $2F: 104 to 119 or 136
; to 151, never within 8 of the room's middle line. It falls from Z 216.
SKY_DROP:
  LD A,(DROP_BAN)         ; Nothing falls in this room
  AND A                   ;
  RET NZ                  ;
  LD HL,DROP_TIMER        ; Count the timer down
  DEC (HL)                ;
  RET NZ                  ;
  LD (HL),$01             ; Then try every turn
  LD A,(RANDOM)           ; One chance in four
  AND $03                 ;
  RET NZ                  ;
  CALL RESET_DROP_TIMER   ; The timer starts again
  LD HL,FLYERS            ; The first of the two records, and the template
  LD BC,$0020             ;
  LD DE,FLYER_TEMPLATE    ;
  LD A,(HL)               ; Both in use: nothing falls
  AND A                   ;
  JR Z,SKY_DROP_0         ;
  ADD HL,BC               ;
  LD A,(HL)               ;
  AND A                   ;
  RET NZ                  ;
SKY_DROP_0:
  EX DE,HL                ; IX = the free record, filled from the template
  PUSH HL                 ;
  POP IX                  ;
  LDIR                    ;
  LD A,(RANDOM)           ; U at random
  AND $2F                 ;
  ADD A,$68               ;
  LD (IX+$01),A           ;
  LD A,R                  ; V from the refresh register
  AND $2F                 ;
  ADD A,$68               ;
  LD (IX+$02),A           ;
  LD A,(RANDOM)           ; One of the eight graphics, by bits 3-5 of the
  RRA                     ; random number
  RRA                     ;
  RRA                     ;
  AND $07                 ;
  LD L,A                  ;
  LD H,$00                ;
  LD DE,DROP_GRAPHICS     ;
  ADD HL,DE               ;
  LD A,(HL)               ;
  LD (IX+$00),A           ;
  CALL CALC_PIXEL_XY      ; Its place on the screen (CALC_PIXEL_XY)
  CALL DO_ANY_OBJS_INTERSECT ; Nothing in the way: it falls
  RET NC                     ; (DO_ANY_OBJS_INTERSECT)
  LD (IX+$00),$00         ; Something there: no drop after all
  RET                     ;

; What may fall from the sky: eight graphics, one picked at random
;
; 164, 160 (twice) and 48 (twice) are homers (HOMER); 80 (twice) and 168 have
; update routines in ROAMER and SKY_WALKER.
DROP_GRAPHICS:
  DEFB $A4,$A0,$30,$50,$A8,$A0,$30,$50

; The record a thing from the sky starts as
;
; SKY_DROP copies it and then sets the graphic, U and V.
FLYER_TEMPLATE:
  DEFB $00,$A0,$A0,$D8,$08,$08,$08,$10 ; Graphic, U, V, Z 216, half-sizes 8, 8
                                       ; and 8, flags: to be drawn
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; The rest zero, the room (+$08)
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; included
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;

; Reset the drop timer: 80 turns while the first quest item is still to do, 8
; after
;
; Used by the routines at START and SKY_DROP.
;
; Meant, by its shape, to count the quest items still to do -- records of
; QUEST_RECORDS whose graphic is 112 to 115; a quest item done becomes 116 to
; 119 -- and set DROP_TIMER to four times two more than that: 8 to 24 turns.
; But DE is loaded with the record length and never added to HL, so it tests
; the first record eighteen times: 80 turns while the first quest item is to
; do, 8 once it is done, whatever the other three are. Measured in the
; simulator: 80 with none done, 80 with the other three done, 8 with only the
; first done.
;
; It runs at the start of every room (START) as well as after each drop, so the
; first drop in a room is always at least that many turns away.
RESET_DROP_TIMER:
  LD HL,QUEST_RECORDS     ; Eighteen records of 16 bytes, C starting at 2 --
  LD DE,$0010             ; but HL never moves on
  LD BC,$1202             ;
RESET_DROP_TIMER_0:
  LD A,(HL)                ; A quest item still to do?
  AND $FC                  ;
  CP $70                   ;
  JR NZ,RESET_DROP_TIMER_1 ;
  INC C                    ;
RESET_DROP_TIMER_1:
  DJNZ RESET_DROP_TIMER_0  ;
  LD A,C                  ; Four turns for each
  ADD A,A                 ;
  ADD A,A                 ;
  LD (DROP_TIMER),A       ;
  RET                     ;

; The update routine for a homer (graphics 48 to 51 and 160 to 167)
;
; Flies at the player. Speeds in U, V and Z are kept in sixteenths in +$14,
; +$15 and +$16; each turn each gains 3 towards the player -- U and V towards
; his legs (PLAYER_U, PLAYER_V), Z towards his body's Z -- up to +56 or down to
; -72, and the step for the next turn is the speed plus 8 divided by 16,
; rounding down: at most 4 units a turn either way. Gravity takes one off the Z
; step before the move (DEC_DZ_AND_UPDATE_UVZ). A move stopped in U or V turns
; that speed round, so a homer bounces off walls and objects; one stopped in Z
; keeps its speed (the routine that would turn it, at BOUNCE_Z, is never
; called).
;
; The half-sizes in U and V are set to 10 every turn, over the 8 of
; FLYER_TEMPLATE. The four frames are the low two bits of the graphic, from a
; count in +$10. Some fall from the sky (DROP_GRAPHICS); object template 2 is
; graphic 48, so a room can start with one too.
;
; The last four instructions are where most moving things' updates finish: bits
; 4 and 5 of the flags, draw it and copy its rectangle to the screen, and
; SET_DRAW_OBJS_OVERLAPPED, which marks whatever it overlaps for redrawing.
;
; IX The homer's record
HOMER:
  CALL DRAW_AT_L12_D6     ; Drawn 12 left and 6 down
  LD (IX+$04),$0A         ; Half-sizes 10 in U and V
  LD (IX+$05),$0A         ;
  CALL DEC_DZ_AND_UPDATE_UVZ ; Z step less 1, cut short where it must be, and
                             ; moved
  LD A,(IX+$0C)           ; Stopped on any axis?
  AND $07                 ;
  JR Z,HOMER_0            ;
  AND $01                 ; In U: turn the U speed round
  CALL NZ,BOUNCE_U        ;
  BIT 1,(IX+$0C)          ; In V: turn the V speed round
  CALL NZ,BOUNCE_V        ;
HOMER_0:
  LD A,(PLAYER_U)         ; The U speed: 3 towards the player's U
  SUB (IX+$01)            ;
  LD A,(IX+$14)           ;
  JR NC,HOMER_5           ;
  CALL ACCEL_MINUS        ;
HOMER_1:
  LD (IX+$14),A           ; The V speed: 3 towards his V
  LD A,(PLAYER_V)         ;
  SUB (IX+$02)            ;
  LD A,(IX+$15)           ;
  JR NC,HOMER_6           ;
  CALL ACCEL_MINUS        ;
HOMER_2:
  LD (IX+$15),A           ; The Z speed: 3 towards his body's Z
  LD A,($A792)            ;
  SUB (IX+$03)            ;
  LD A,(IX+$16)           ;
  JR NC,HOMER_7           ;
  CALL ACCEL_MINUS        ;
HOMER_3:
  LD (IX+$16),A           ; The steps in U, V and Z: each speed plus 8, divided
  LD B,$03                ; by 16
HOMER_4:
  INC IX                  ;
  LD A,(IX+$13)           ;
  ADD A,$08               ;
  SRA A                   ;
  SRA A                   ;
  SRA A                   ;
  SRA A                   ;
  LD (IX+$08),A           ;
  DJNZ HOMER_4            ;
  DEC IX                  ;
  DEC IX                  ;
  DEC IX                  ;
  JR HOMER_8              ;
HOMER_5:
  CALL ACCEL_PLUS         ; The player at a greater U, V or Z (or level): 3 up
  JR HOMER_1              ;
HOMER_6:
  CALL ACCEL_PLUS         ;
  JR HOMER_2              ;
HOMER_7:
  CALL ACCEL_PLUS         ;
  JR HOMER_3              ;
HOMER_8:
  INC (IX+$10)            ; The next of four frames
  LD A,(IX+$10)           ;
  AND $03                 ;
  LD B,A                  ;
  LD A,(IX+$00)           ;
  AND $FC                 ;
  ADD A,B                 ;
  LD (IX+$00),A           ;
; This entry point is used by the routines at SET_WIPE_AND_DRAW_IY,
; TAKE_OR_LEAVE, PUFF, BOLT, PLAYER_LEGS, PUSHABLE, LIFT, BOBBER,
; DEADLY_PACER_U, DEADLY_PACER_V, SPIDER, QUEST_ITEM, WELL, ROAMER, SKY_WALKER
; and CRUMBLING_BLOCK.
SET_WIPE_AND_DRAW_FLAGS:
  LD A,(IX+$07)               ; Draw it and copy its rectangle to the screen,
  OR $30                      ; and mark what it overlaps
  LD (IX+$07),A               ;
  JP SET_DRAW_OBJS_OVERLAPPED ;

; Bounce off in U: reverse the U velocity
;
; Used by the routine at HOMER.
;
; HOMER calls this when its move has bumped into something in U. The velocity
; at +14 is in sixteenths of a unit, the step at +9 made from it each turn;
; negating it sends the flyer back the way it came.
;
; IX the flyer
BOUNCE_U:
  LD A,(IX+$14)           ; +14 = -(+14)
  NEG                     ;
  LD (IX+$14),A           ;
  RET

; Bounce off in V: reverse the V velocity
;
; Used by the routine at HOMER.
;
; As BOUNCE_U, for V: HOMER calls this when it has bumped into something in V.
;
; IX the flyer
BOUNCE_V:
  LD A,(IX+$15)           ; +15 = -(+15)
  NEG                     ;
  LD (IX+$15),A           ;
  RET

; Unused: bounce off in Z
;
; The third of the set, for the Z velocity at +16, and never called: HOMER
; tests only the U and V bits of what it bumped into, and no other code or
; table holds this address. sna2ctl left it as data because no session ran it;
; its nine bytes are LD A,(IX+$16), NEG, LD (IX+$16),A and RET, the pattern of
; BOUNCE_U and BOUNCE_V with the next offset.
;
; IX the flyer
BOUNCE_Z:
  LD A,(IX+$16)
  NEG
  LD (IX+$16),A
  RET

; Speed a homing velocity up the positive way
;
; Used by the routine at HOMER.
;
; HOMER pulls each of the flyer's three velocities three sixteenths towards the
; player every turn. This is the pull for a player further along the axis: add
; 3, and cap the result at 56. A velocity still negative after the add is left
; alone, so a flyer going the wrong way turns round gradually rather than at
; once.
;
; The cap is 56 here and -72 in ACCEL_MINUS, which looks lopsided until HOMER
; turns a velocity into a step: it adds 8 and shifts right four times, and both
; caps come out as a step of 4, one way or the other.
;
;   A the velocity, in sixteenths of a unit
; O:A the new velocity
ACCEL_PLUS:
  ADD A,$03               ; add 3; still going the other way: done
  RET M                   ;
  CP $38                  ; no faster than 56
  RET C                   ;
  LD A,$38                ;
  RET                     ;

; Speed a homing velocity up the negative way
;
; Used by the routine at HOMER.
;
; The pull for a player further back along the axis: subtract 3, and cap the
; result at -72 (see ACCEL_PLUS for why the caps differ).
;
;   A the velocity, in sixteenths of a unit
; O:A the new velocity
ACCEL_MINUS:
  SUB $03                 ; subtract 3; still going the other way: done
  RET P                   ;
  CP $B8                  ; no faster than -72
  RET NC                  ;
  LD A,$B8                ;
  RET                     ;

; The update routine for a collectable
;
; Graphics 144 to 148: the five things that must be brought to the pentagram.
; Anywhere but room 82, or before the pentagram is showing (PENTAGRAM_ON), a
; collectable is an ordinary thing that falls and can be pushed (it goes on at
; FALL, in PUSHABLE); the player can pick it up and carry it (TAKE_OR_LEAVE).
;
; In room 82 with the pentagram showing, it glides without falling towards its
; own place on the pentagram, one unit a turn in U and in V: the place comes
; from TARGETS by the low three bits of the graphic, and HEAD_FOR_TARGET
; steers. When it is there its graphic goes up by 8, in its object record and
; in its quest record (CHANGE_GRAPHIC), so it is no longer a collectable (152
; to 156 are a still thing's), and PLACED counts it. The fifth ends the game: a
; jump to WON.
;
; IX the collectable's object record
COLLECTABLE:
  CALL DRAW_AT_L16_D8     ; the drawing nudge
  LD A,(PLAYER_ROOM)      ; not in room 82, or no pentagram yet: just fall and
  CP $52                  ; stop
  JP NZ,FALL              ;
  LD A,(PENTAGRAM_ON)     ;
  AND A                   ;
  JP Z,FALL               ;
  LD A,(IX+$00)           ; +15 and +16 = its place on the pentagram, from
  AND $07                 ; TARGETS by graphic AND 7
  ADD A,A                 ;
  LD L,A                  ;
  LD H,$00                ;
  LD DE,TARGETS           ;
  ADD HL,DE               ;
  LD A,(HL)               ;
  LD (IX+$15),A           ;
  INC HL                  ;
  LD A,(HL)               ;
  LD (IX+$16),A           ;
  CALL HEAD_FOR_TARGET    ; step towards it, and move without falling
  CALL CLIP_AND_MOVE      ;
  LD A,(IX+$01)           ; not there yet: stop, and redraw
  SUB (IX+$15)            ;
  LD C,A                  ;
  LD A,(IX+$02)           ;
  SUB (IX+$16)            ;
  OR C                    ;
  JP NZ,STOP_MOVING       ;
  LD A,(IX+$00)           ; there: graphic + 8, here and in its quest record
  ADD A,$08               ;
  LD C,A                  ;
  LD A,(IX+$00)           ;
  CALL CHANGE_GRAPHIC     ;
  LD A,(PLACED)           ; one more placed; the fifth wins the game
  INC A                   ;
  LD (PLACED),A           ;
  CP $05                  ;
  JP NC,WON               ;
  JP STOP_MOVING          ; stop, and redraw

; The update routine for the spikes
;
; Graphic 28, a bed of spikes: deadly both ways (MAKE_DEADLY), and otherwise a
; thing that falls and can be pushed, as PUSHABLE.
;
; IX the object record
SPIKES:
  CALL MAKE_DEADLY        ; deadly
  JR PUSHABLE

; The update routine for a block that can only fall; and for the table
;
; Graphic 91, a block. The steps in U and V are cleared before it moves, so
; whatever pushed it this turn has no effect, and it only falls. It is also,
; with the player, one of the two things that set bit 7 of +17 on what they
; land on (MARK_STOOD_ON), so it can crumble a crumbling block or start a lift.
;
; Graphic 73, the table, enters at SLIDING_TABLE: its template makes it
; pushable, and it keeps the step a push gave it, falls, and stops.
;
; IX the object record
HEAVY_BLOCK:
  XOR A                   ; no sideways step: pushes are lost
  LD (IX+$09),A           ;
  LD (IX+$0A),A           ;
SLIDING_TABLE:
  CALL DRAW_AT_L16_D12    ; the table's way in: its own drawing nudge
  JR FALL                 ; fall, and stop

; The update routine for things that fall and can be pushed
;
; Used by the routine at SPIKES.
;
; Graphics 63 and 79 (blocks), 72 (a tree stump), and the tails of many other
; routines. A push from something walking into it (the collision code copies
; the pusher's step into a pushable thing's) moves it that far this turn; it
; also falls one unit a turn, since the fall at DEC_DZ_AND_UPDATE_UVZ takes one
; off the Z step and STOP_MOVING clears it again.
;
; STOP_MOVING is the common ending: if it moved at all this turn, clear the
; three steps and have it redrawn; if not, return without a redraw, so a thing
; at rest costs nothing to draw.
;
; IX the object record
PUSHABLE:
  CALL DRAW_AT_L16_D8     ; the drawing nudge
; This entry point is used by the routines at COLLECTABLE and HEAVY_BLOCK.
FALL:
  CALL DEC_DZ_AND_UPDATE_UVZ ; FALL: fall one unit, and move by whatever steps
                             ; it has
; This entry point is used by the routines at COLLECTABLE, SINKING_BLOCK, LIFT,
; PENTAGRAM_PIECE and BUCKET.
STOP_MOVING:
  LD A,(IX+$09)           ; STOP_MOVING: did it move?
  OR (IX+$0A)             ;
  OR (IX+$0B)             ;
  RET Z                   ;
  LD (IX+$09),$00            ; yes: clear the steps, and redraw it and what it
  LD (IX+$0A),$00            ; overlaps
  LD (IX+$0B),$00            ;
  JP SET_WIPE_AND_DRAW_FLAGS ;

; The update routine for a block that sinks under him
;
; Graphic 78, a block that stays where it is until he stands on it, and then
; sinks a unit a turn for as long as he does. It never falls by itself: its Z
; step is only ever set by what lands on it, since the player's flags (bit 2)
; make the collision code pass his Z step to what he lands on
; (ADJ_DZ_FOR_OBJ_INTERSECT). Any Z step at all becomes one unit down.
;
; Measured in the simulator in room 15: stood on, it went from Z 152 down one a
; turn, and he with it.
;
; IX the object record
SINKING_BLOCK:
  CALL DRAW_AT_L16_D8     ; the drawing nudge
  LD (IX+$09),$00         ; no sideways step
  LD (IX+$0A),$00         ;
  LD A,(IX+$0B)           ; pressed on from above: down one unit
  AND A                   ;
  JR Z,SINKING_BLOCK_0    ;
  LD A,$FF                ;
  LD (IX+$0B),A           ;
SINKING_BLOCK_0:
  CALL CLIP_AND_MOVE      ; move without falling, then stop
  JR STOP_MOVING          ;

; The update routine for the lift
;
; Graphic 84, a block that carries him up. It keeps its state in +17: bit 0
; while it is moving, bit 1 while it is on the way down, and bit 7, set by the
; collision code when he (or the heavy block, HEAVY_BLOCK) lands on it
; (MARK_STOOD_ON).
;
; At rest, it waits for him: landing on it passes his Z step down to it
; (ADJ_DZ_FOR_OBJ_INTERSECT), it moves, bumps the floor, and with bit 7 set it
; starts to rise. Rising, it asks for two units a turn, gives him a Z step of 3
; and tells his code he is standing on something (bit 2 of PLAYER_BUMPED); it
; rises only while it keeps bumping into something above it -- him -- so the
; moment he steps off it turns round. At a height of 176 it stops, and he is
; given a Z step of -2. On the way down it sinks one a turn until it bumps into
; something below, and then it is at rest again.
;
; Measured in the simulator in room 2: he landed on it at Z 128 and it rose one
; unit a turn with him on top, 12 above it; at 176 he fell, pushing the lift
; down with him faster and faster, and at the floor it started up again, and so
; on for as long as he stood there.
;
; IX the object record
LIFT:
  LD (IX+$09),$00         ; no sideways step
  LD (IX+$0A),$00         ;
  CALL DRAW_AT_L16_D8     ; the drawing nudge
  CALL CLIP_AND_MOVE      ; move by its Z step, without falling; no sideways
  XOR A                   ; step again
  LD (IX+$09),A           ;
  LD (IX+$0A),A           ;
  BIT 0,(IX+$17)          ; moving?
  JR NZ,LIFT_0            ;
  BIT 2,(IX+$0C)          ; at rest: did something land on it this turn?
  JR Z,STOP_MOVING        ;
  BIT 7,(IX+$17)          ; was it him?
  JR Z,STOP_MOVING        ;
  RES 7,(IX+$17)          ; yes: start moving, upwards
  SET 0,(IX+$17)          ;
  JR LIFT_2               ;
LIFT_0:
  BIT 2,(IX+$0C)             ; moving, and nothing above it: go down, one a
  JR NZ,LIFT_1               ; turn
  SET 1,(IX+$17)             ;
  LD (IX+$0B),$FF            ;
  JP SET_WIPE_AND_DRAW_FLAGS ;
LIFT_1:
  BIT 1,(IX+$17)          ; bumped: on the way down, that is the floor or
  JR NZ,LIFT_3            ; something below
  LD A,(IX+$03)           ; on the way up: below 176?
  CP $B0                  ;
  JR C,LIFT_2             ;
  LD (IX+$03),$B0            ; at the top: stay at 176; he is sent down
  LD A,$FE                   ;
  LD ($A77A),A               ;
  JP SET_WIPE_AND_DRAW_FLAGS ;
LIFT_2:
  LD (IX+$0B),$02            ; rise: two units a turn for the lift, three for
  LD A,$03                   ; him, and he stands on it
  LD ($A77A),A               ;
  LD A,(PLAYER_BUMPED)       ;
  OR $04                     ;
  LD (PLAYER_BUMPED),A       ;
  JP SET_WIPE_AND_DRAW_FLAGS ;
LIFT_3:
  LD (IX+$17),$00         ; down again: at rest
  JP STOP_MOVING          ;
; The Z step it gives him is written into his record whether or not he is the
; one on top.

; The update routine for a thing that bobs up and down
;
; Used by the routine at DEADLY_BOBBER.
;
; Used by graphic 86 through DEADLY_BOBBER, which makes it deadly first;
; graphic 85 comes here directly, but no room places one. It keeps its state in
; bit 2 of +D, which the kill bits (5 to 7) leave free: clear while it falls,
; set while it rises.
;
; Falling, it drops one unit a turn; when it lands on something it starts
; rising, one unit a turn (the 2 it stores on landing is overwritten with 1
; before any move uses it; measured in room 88: one unit a turn from the
; first), until its height reaches 176, when it falls again. If something above
; stops it rising, it falls at once. When the player (or the heavy block) is
; standing on it the rise is three a turn; a jump by him clears that.
;
; Measured in the simulator in room 11 (graphic 86, nothing on it): it rose one
; unit a turn to 176 and fell back one a turn to where it had landed, over and
; over.
;
; IX the object record
BOBBER:
  CALL DRAW_AT_L16_D8     ; the drawing nudge
  XOR A                   ; no sideways step; rising?
  LD (IX+$09),A           ;
  LD (IX+$0A),A           ;
  BIT 2,(IX+$0D)          ;
  JR NZ,BOBBER_1          ;
  LD (IX+$0B),A              ; falling: one unit a turn
  CALL DEC_DZ_AND_UPDATE_UVZ ;
  BIT 2,(IX+$0C)          ; landed: start rising (the 2 stored here is replaced
  JR Z,BOBBER_0           ; before it is used)
  SET 2,(IX+$0D)          ;
  LD (IX+$0B),$02         ;
BOBBER_0:
  XOR A                      ; no sideways step; redraw it
  LD (IX+$09),A              ;
  LD (IX+$0A),A              ;
  JP SET_WIPE_AND_DRAW_FLAGS ;
BOBBER_1:
  LD A,(PLAYER_BUMPED)    ; rising: if he has jumped, he is no longer on it
  AND $08                 ;
  JR Z,BOBBER_2           ;
  RES 7,(IX+$17)          ;
BOBBER_2:
  LD A,(IX+$0B)           ; he is on it, or it is moving: carry on up; stopped:
  AND A                   ; fall
  BIT 7,(IX+$17)          ;
  JR NZ,BOBBER_3          ;
  AND A                   ;
  JR Z,BOBBER_5           ;
BOBBER_3:
  LD A,$01                ; one unit a turn up, or three with him on it (the
  JP P,BOBBER_4           ; sign of what was tested last)
  ADD A,$02               ;
BOBBER_4:
  LD (IX+$0B),A           ;
  CALL CLIP_AND_MOVE      ; move; at 176 or above, fall from now on
  LD A,(IX+$03)           ;
  CP $B0                  ;
  JR C,BOBBER_0           ;
  RES 2,(IX+$0D)          ;
  JR BOBBER_0             ;
BOBBER_5:
  CALL DEC_DZ_AND_UPDATE_UVZ ; stopped from above: fall
  RES 2,(IX+$0D)             ;
  JR BOBBER_0                ;

; The update routine for the deadly head that bobs up and down
;
; Graphic 86, a head: deadly both ways (MAKE_DEADLY), then as BOBBER.
;
; IX the object record
DEADLY_BOBBER:
  CALL MAKE_DEADLY        ; deadly, then bob
  JP BOBBER               ;

; The update routine for things that pace to and fro in U
;
; Graphic 92, a head, is deadly (MAKE_DEADLY) and enters here; graphic 87, a
; block, enters at PACER_U. Either moves two units a turn along U, the way bit
; 0 of +10 says (set: forwards), and turns round when it bumps into anything.
; It never falls. The player standing on the block is carried along, since the
; collision code gives him the step of what he stands on when he has none of
; his own (ADJ_DZ_FOR_OBJ_INTERSECT).
;
; IX the object record
DEADLY_PACER_U:
  CALL MAKE_DEADLY        ; deadly
PACER_U:
  CALL DRAW_AT_L16_D8     ; PACER_U: the drawing nudge
  XOR A                   ; no step in V or Z; which way?
  LD (IX+$0A),A           ;
  LD (IX+$0B),A           ;
  BIT 0,(IX+$10)          ;
  JR Z,DEADLY_PACER_U_1   ;
  LD (IX+$09),$02         ; forwards: two units, and back the other way after a
  CALL CLIP_AND_MOVE      ; bump
  BIT 0,(IX+$0C)          ;
  JR Z,DEADLY_PACER_U_0   ;
  RES 0,(IX+$10)          ;
DEADLY_PACER_U_0:
  JP SET_WIPE_AND_DRAW_FLAGS ; redraw
DEADLY_PACER_U_1:
  LD (IX+$09),$FE         ; backwards: two units, and forwards again after a
  CALL CLIP_AND_MOVE      ; bump
  BIT 0,(IX+$0C)          ;
  JR Z,DEADLY_PACER_U_0   ;
  SET 0,(IX+$10)          ;
  JR DEADLY_PACER_U_0     ;

; The update routine for things that pace to and fro in V
;
; As DEADLY_PACER_U, along V: graphic 93, a head, deadly, enters here; graphic
; 88, a block, at PACER_V.
;
; IX the object record
DEADLY_PACER_V:
  CALL MAKE_DEADLY        ; deadly
PACER_V:
  CALL DRAW_AT_L16_D8     ; PACER_V: the drawing nudge
  XOR A                   ; no step in U or Z; which way?
  LD (IX+$09),A           ;
  LD (IX+$0B),A           ;
  BIT 0,(IX+$10)          ;
  JR Z,DEADLY_PACER_V_1   ;
  LD (IX+$0A),$02         ; forwards: two units, and back the other way after a
  CALL CLIP_AND_MOVE      ; bump
  BIT 1,(IX+$0C)          ;
  JR Z,DEADLY_PACER_V_0   ;
  RES 0,(IX+$10)          ;
DEADLY_PACER_V_0:
  JP SET_WIPE_AND_DRAW_FLAGS ; redraw
DEADLY_PACER_V_1:
  LD (IX+$0A),$FE         ; backwards: two units, and forwards again after a
  CALL CLIP_AND_MOVE      ; bump
  BIT 1,(IX+$0C)          ;
  JR Z,DEADLY_PACER_V_0   ;
  SET 0,(IX+$10)          ;
  JR DEADLY_PACER_V_0     ;

; The update routine for a piece of the pentagram
;
; Graphics 128 to 135, the eight pieces QUEST_INTO_ROOM brings into room 82
; once PENTAGRAM_ON is set, and 121 to 127, which no room, template or quest
; record uses. It moves without falling by whatever steps it has, but only a
; pushable thing (bit 2 of its flags) goes on to be stopped and redrawn; the
; pieces are not pushable, nothing gives them a step, and they return here
; without a redraw and never move.
;
; IX the object record
PENTAGRAM_PIECE:
  CALL DRAW_AT_L16_D8     ; the drawing nudge; move without falling
  CALL CLIP_AND_MOVE      ;
  BIT 2,(IX+$07)          ; not pushable: done; pushable: stop, and redraw
  RET Z                   ;
  JP STOP_MOVING          ;

; The update routine for the spider that scuttles at random
;
; Graphic 89: deadly both ways (MAKE_DEADLY), falling one unit a turn, and
; flipped on every other turn, which is its scuttle. It moves diagonally, four
; units a turn in both U and V; when it bumps into something in U or V, or has
; no step, it picks a new diagonal at random, U by bit 3 of RANDOM and V by bit
; 3 of R.
;
; IX the object record
SPIDER:
  CALL DRAW_AT_L16_D8        ; the drawing nudge; deadly; fall one unit a turn
  CALL MAKE_DEADLY           ;
  LD (IX+$0B),$00            ;
  CALL DEC_DZ_AND_UPDATE_UVZ ;
  RES 6,(IX+$07)          ; mirrored on odd turns
  LD A,(TURNS)            ;
  AND $01                 ;
  JR Z,SPIDER_0           ;
  SET 6,(IX+$07)          ;
SPIDER_0:
  BIT 0,(IX+$0C)          ; bumped in U or V, or still: a new direction
  JR NZ,SPIDER_1          ;
  BIT 1,(IX+$0C)          ;
  JR NZ,SPIDER_1          ;
  LD A,(IX+$09)           ;
  OR (IX+$0A)             ;
  JR NZ,SPIDER_2          ;
SPIDER_1:
  LD A,(RANDOM)           ; four units either way in U, and in V
  AND $08                 ;
  SUB $04                 ;
  LD (IX+$09),A           ;
  LD A,R                  ;
  AND $08                 ;
  SUB $04                 ;
  LD (IX+$0A),A           ;
SPIDER_2:
  JP SET_WIPE_AND_DRAW_FLAGS ; redraw

; The update routine for a quest item
;
; Graphics 112 to 115, the four rough stones the quest is about, and 116 to
; 119, the same four once done. Nothing happens until the bucket reaches one:
; BUCKET sets bit 0 of +16. Then the item is done: one more on QUEST_DONE, a
; life added and the lives redrawn (DRAW_LIVES), and its graphic goes up by 4,
; in the object record and the quest record (CHANGE_GRAPHIC), which turns the
; rough stone into a finished pillar and takes it out of the bucket's reach
; (BUCKET looks for 112 to 115 only). ALL_FOUR_DONE shows the pentagram if it
; was the fourth.
;
; IX the object record
QUEST_ITEM:
  CALL DRAW_AT_L16_D8     ; the drawing nudge; move without falling
  CALL CLIP_AND_MOVE      ;
  BIT 0,(IX+$16)          ; has the bucket reached it?
  RET Z                   ;
  LD A,(QUEST_DONE)       ; one more quest item done
  INC A                   ;
  LD (QUEST_DONE),A       ;
  LD A,(LIVES)            ; and a life more, shown on the panel
  INC A                   ;
  LD (LIVES),A            ;
  PUSH IX                 ;
  CALL DRAW_LIVES         ;
  POP IX                  ;
  RES 0,(IX+$16)          ; done with the bucket; graphic + 4, here and in its
  LD A,(IX+$00)           ; quest record
  ADD A,$04               ;
  LD C,A                  ;
  LD A,(IX+$00)           ;
  CALL CHANGE_GRAPHIC     ;
  CALL ALL_FOUR_DONE         ; all four? Then redraw
  JP SET_WIPE_AND_DRAW_FLAGS ;
; The life is added with INC, not in BCD, but lives start at 5 and only the
; four quest items add any, so they never pass 9.

; Give a quest thing a new graphic, in its quest record and its object record
;
; Used by the routines at COLLECTABLE and QUEST_ITEM.
;
; Finds the quest record (QUEST_RECORDS) that has the old graphic and gives it
; and the object the new one, so the change lasts when he leaves the room
; (QUEST_OUT_OF_ROOM matches the records by graphic). If no quest record has
; the old graphic, neither changes.
;
; A the old graphic
; C the new graphic
; IX the object record
CHANGE_GRAPHIC:
  CALL QUEST_RECORD_LOOP  ; find the quest record with the old graphic; none:
CHANGE_GRAPHIC_0:
  CP (IY+$00)             ; done
  JR Z,CHANGE_GRAPHIC_1   ;
  ADD IY,DE               ;
  DJNZ CHANGE_GRAPHIC_0   ;
  RET                     ;
CHANGE_GRAPHIC_1:
  LD (IY+$00),C           ; both get the new one
  LD (IX+$00),C           ;
  RET                     ;

; Is one of his bolts touching this object?
;
; Used by the routine at WELL.
;
; Tests the two bolt records against IX with the intersection test in BOLT_HIT,
; which counts boxes within two units of each other as touching.
;
; The two slots are not tested alike: the first goes in past BOLT_HIT's test
; for a puff (graphics 64 to 71, what a bolt becomes when it hits something),
; so a puff there still counts; the second goes in before it, and a puff there
; does not. Watched: as shipped, the bucket came after 7 shots; with both slots
; treated alike, after 32.
;
;   IX the object record
; O:F Z set if a bolt is touching it (and D is 0)
BOLT_TOUCHING:
  LD D,$01                ; the first bolt; touching: done
  LD IY,BOLTS             ;
  LD A,(IY+$00)           ;
  AND $F8                 ;
  CALL HIT_TEST_Z         ;
  LD A,D                  ;
  AND A                   ;
  RET Z                   ;
  LD IY,BOLT_SECOND       ; the second
  LD A,(IY+$00)           ;
  AND $F8                 ;
  CALL HIT_TEST           ;
  LD A,D                  ;
  AND A                   ;
  RET                     ;

; The update routine for the well
;
; Graphic 120. Shot at enough, it puts out the bucket. It counts in +14 the
; turns on which one of his bolts touches it (BOLT_TOUCHING), and on the 32nd,
; with no bucket already out (BUCKET_OUT) and none in the room, and a free
; record for one, it makes the bucket: a copy of its own record with graphic
; 90, at the well's U, 8 further in V, at a height of 141, rising one unit (so
; it hangs there for a turn and then falls), pushable, and linked to the
; quest's bucket record (QUEST_BUCKET, in QUEST_RECORDS), which gets the
; graphic and the room.
;
; The count is kept in the well's own record, which is rebuilt from the room's
; data every time the room is entered, so the 32 must come in one visit.
;
; IX the well's object record
WELL:
  CALL DRAW_AT_L16_D8     ; the drawing nudge; move without falling
  CALL CLIP_AND_MOVE      ;
  LD A,(BUCKET_OUT)       ; a bucket out already: nothing more
  AND A                   ;
  RET NZ                  ;
  CALL BOLT_TOUCHING      ; no bolt touching: nothing
  RET NZ                  ;
  INC (IX+$14)            ; the 32nd turn a bolt has touched it?
  LD A,(IX+$14)           ;
  CP $20                  ;
  RET C                   ;
  LD (IX+$14),$00         ; start the count again; a bucket in the room
  CALL ROOM_OBJECT_LOOP   ; already: nothing
  LD A,$5A                ;
WELL_0:
  CP (IY+$00)             ;
  RET Z                   ;
  ADD IY,DE               ;
  DJNZ WELL_0             ;
  CALL ROOM_OBJECT_LOOP   ; find a free record; none: nothing
  XOR A                   ;
WELL_1:
  CP (IY+$00)             ;
  JR Z,WELL_2             ;
  ADD IY,DE               ;
  DJNZ WELL_1             ;
  RET                     ;
WELL_2:
  PUSH IX                 ; copy the well's record into it
  POP HL                  ;
  PUSH IY                 ;
  POP DE                  ;
  LD BC,$0020             ;
  LDIR                    ;
  LD (IY+$00),$5A         ; graphic 90, height 141, half-sizes 8, 8, 12, flags
  LD (IY+$03),$8D         ; $14, rising one unit
  LD A,$08                ;
  LD (IY+$04),A           ;
  LD (IY+$05),A           ;
  LD (IY+$06),$0C         ;
  LD (IY+$07),$14         ;
  LD (IY+$0B),$01         ;
  LD DE,QUEST_BUCKET      ; linked to the quest's bucket record
  LD (IY+$10),E           ;
  LD (IY+$11),D           ;
  LD A,(IX+$01)           ; at the well's U, 8 further in V
  LD (IY+$01),A           ;
  LD A,(IX+$02)           ;
  ADD A,$08               ;
  LD (IY+$02),A           ;
  LD A,$01                ; the bucket is out
  LD (BUCKET_OUT),A       ;
  PUSH IX                      ; the new record: its nudge, its place on
  PUSH IY                      ; screen, a move, and drawn
  POP IX                       ;
  CALL DRAW_AT_L16_D8          ;
  CALL CALC_PIXEL_XY           ;
  CALL DEC_DZ_AND_UPDATE_UVZ   ;
  CALL SET_WIPE_AND_DRAW_FLAGS ;
  POP IX                       ;
  LD IY,QUEST_BUCKET         ; the quest's bucket record gets the graphic and
  LD (IY+$00),$5A            ; the room; redraw the well
  LD A,(IX+$08)              ;
  LD (IY+$08),A              ;
  JP SET_WIPE_AND_DRAW_FLAGS ;

; Set up a walk through the room's 48 object records
;
; Used by the routines at BAN_DROPS, WELL and BUCKET.
;
; For a loop of the form test (IY+n), ADD IY,DE, DJNZ.
;
; O:IY the first of the room's records, ROOM_OBJECTS
; O:DE 32, the size of a record
; O:B 48, the number of them
ROOM_OBJECT_LOOP:
  LD DE,$0020             ; DE = 32, IY = ROOM_OBJECTS, B = 48
  LD IY,ROOM_OBJECTS      ;
  LD B,$30                ;
  RET                     ;

; Set up a walk through the quest records
;
; Used by the routines at CHANGE_GRAPHIC, BUCKET and ALL_FOUR_DONE.
;
; As ROOM_OBJECT_LOOP, for the eighteen quest records at QUEST_RECORDS.
;
; O:IY the first quest record
; O:DE 16, the size of a record
; O:B 18, the number of them
QUEST_RECORD_LOOP:
  LD DE,$0010             ; DE = 16, IY = QUEST_RECORDS, B = 18
  LD IY,QUEST_RECORDS     ;
  LD B,$12                ;
  RET                     ;

; Steer towards the place in +15 and +16
;
; Used by the routines at COLLECTABLE and BUCKET.
;
; Sets the step in U to one unit towards the U in +15, and the step in V to one
; unit towards the V in +16. An axis already there keeps the step it had, which
; the callers have cleared the turn before, so the thing goes diagonally until
; one axis matches and then straight.
;
; IX the object record, with the target U and V in +15 and +16
HEAD_FOR_TARGET:
  LD A,(IX+$01)           ; U: one unit down, or...
  CP (IX+$15)             ;
  JR Z,HEAD_FOR_TARGET_1  ;
  JR C,HEAD_FOR_TARGET_0  ;
  LD (IX+$09),$FF         ;
  JR HEAD_FOR_TARGET_1    ;
HEAD_FOR_TARGET_0:
  LD (IX+$09),$01         ; ...one unit up
HEAD_FOR_TARGET_1:
  LD A,(IX+$02)           ; V: one unit down, or...
  CP (IX+$16)             ;
  RET Z                   ;
  JR C,HEAD_FOR_TARGET_2  ;
  LD (IX+$0A),$FF         ;
  RET                     ;
HEAD_FOR_TARGET_2:
  LD (IX+$0A),$01         ; ...one unit up
  RET                     ;

; The update routine for the bucket
;
; Graphic 90. Bit 0 of +14 says whether it has a quest item to go to. Until it
; has, it falls one unit a turn, and looks for a quest item not yet done
; (graphics 112 to 115) among the room's records each turn; the well's rooms
; have none, so it falls to the ground there and waits to be carried
; (TAKE_OR_LEAVE). Put down where a quest item is, it finds it, takes its U and
; V as the target, and from then on rises one unit a turn to a height of 176
; while it steers towards the item (HEAD_FOR_TARGET), without falling.
;
; When it can move no more -- above the item at the top of its rise, or stopped
; by something in every direction -- it finds the quest item in the room again
; and sets bit 0 of its +16, which QUEST_ITEM acts on. Then the bucket's work
; is done: BUCKET_OUT is cleared so the well can give another, the quest-item
; tune plays, the bucket's quest record is emptied, and the bucket turns into a
; puff (START_PUFF).
;
; IX the bucket's object record
BUCKET:
  CALL DRAW_AT_L16_D8     ; the drawing nudge
  BIT 0,(IX+$14)          ; not yet going to a quest item
  JR Z,BUCKET_5           ;
  CALL HEAD_FOR_TARGET    ; going: steer to it, and rise while below 176
  LD A,(IX+$03)           ;
  CP $B0                  ;
  JR NC,BUCKET_0          ;
  LD (IX+$0B),$01         ;
BUCKET_0:
  CALL CLIP_AND_MOVE      ; move without falling; moved: stop, and redraw
  LD A,(IX+$0A)           ;
  OR (IX+$09)             ;
  OR (IX+$0B)             ;
  JP NZ,STOP_MOVING       ;
  CALL ROOM_OBJECT_LOOP   ; stuck: find the quest item not yet done in this
  LD C,$70                ; room; none: stop
BUCKET_1:
  LD A,(IY+$00)           ;
  AND $FC                 ;
  CP C                    ;
  JR Z,BUCKET_2           ;
  ADD IY,DE               ;
  DJNZ BUCKET_1           ;
  JP STOP_MOVING          ;
BUCKET_2:
  SET 0,(IY+$16)          ; tell it the bucket has reached it
  XOR A                   ; the well may give another bucket; the quest-item
  LD (BUCKET_OUT),A       ; tune
  LD DE,TUNE_QUEST        ;
  CALL PLAY_TUNE          ;
  CALL QUEST_RECORD_LOOP  ; empty the bucket's quest record...
  LD A,$5A                ;
BUCKET_3:
  CP (IY+$00)             ;
  JR Z,BUCKET_4           ;
  ADD IY,DE               ;
  DJNZ BUCKET_3           ;
  JP START_PUFF           ;
BUCKET_4:
  LD (IY+$00),$00         ; ...and the bucket becomes a puff
  JP START_PUFF           ;
BUCKET_5:
  LD (IX+$0B),$FF         ; not going anywhere: fall one unit
  CALL CLIP_AND_MOVE      ;
  CALL ROOM_OBJECT_LOOP   ; a quest item not yet done in this room? None: stop
  LD C,$70                ;
BUCKET_6:
  LD A,(IY+$00)           ;
  AND $FC                 ;
  CP C                    ;
  JR Z,BUCKET_7           ;
  ADD IY,DE               ;
  DJNZ BUCKET_6           ;
  JP STOP_MOVING          ;
BUCKET_7:
  LD A,(IY+$01)           ; there is: its U and V are the target, and the
  LD (IX+$15),A           ; bucket is on its way
  LD A,(IY+$02)           ;
  LD (IX+$16),A           ;
  SET 0,(IX+$14)          ;
  JP STOP_MOVING          ;

; If all four quest items are done, show the pentagram
;
; Used by the routine at QUEST_ITEM.
;
; Counts the quest records whose graphic is 116 to 119, the quest items done.
; With all four, each piece of the pentagram (graphics 128 to 135) gets bit 4
; of its flags, and PENTAGRAM_ON is set, which is what lets QUEST_INTO_ROOM
; bring the pieces into room 82 the next time he enters it and makes the
; collectables there glide to their places (COLLECTABLE).
;
; IX the quest item that has just been done
ALL_FOUR_DONE:
  CALL QUEST_RECORD_LOOP  ; count the quest items done
  LD C,$00                ;
ALL_FOUR_DONE_0:
  LD A,(IY+$00)           ;
  AND $FC                 ;
  CP $74                  ;
  JR NZ,ALL_FOUR_DONE_1   ;
  INC C                   ;
ALL_FOUR_DONE_1:
  ADD IY,DE               ;
  DJNZ ALL_FOUR_DONE_0    ;
  LD A,C                  ; not all four: done
  CP $04                  ;
  RET NZ                  ;
  CALL QUEST_RECORD_LOOP  ; each piece of the pentagram...
ALL_FOUR_DONE_2:
  LD A,(IY+$00)           ;
  AND $F8                 ;
  CP $80                  ;
  JR NZ,ALL_FOUR_DONE_3   ;
  SET 0,(IX+$11)          ; (a write to the quest item's link that nothing
                          ; reads)
  SET 4,(IY+$07)          ; ...is to be drawn, and the pentagram is showing
  LD A,$01                ;
  LD (PENTAGRAM_ON),A     ;
ALL_FOUR_DONE_3:
  ADD IY,DE               ;
  DJNZ ALL_FOUR_DONE_2    ;
  RET                     ;
; Two of its writes have no effect found: bit 4 of the pieces' flags, which
; QUEST_INTO_ROOM sets anyway as it brings them in; and bit 0 of +11 of the
; quest item that called, the high byte of its quest record's address, which
; makes it point 256 bytes further on. Only a carried thing's link is ever
; followed (TAKE_OR_LEAVE), and a quest item cannot be picked up (CAN_PICK_UP),
; so nothing reads it.

; Set out the quest's things for a new game
;
; Used by the routine at START.
;
; Copies the eighteen records of QUEST_START to QUEST_RECORDS, and then puts
; the five collectables (records 4 to 8) in five consecutive places from SPOTS,
; the first chosen by the random number from the first sixteen: each gets its
; room, U, V and Z from its place. Called by START once the start tune has
; played.
NEW_QUEST:
  LD DE,QUEST_RECORDS     ; the quest records as a game starts
  LD HL,QUEST_START       ;
  LD BC,$0120             ;
  LDIR                    ;
  LD A,(RANDOM)           ; a random place, 0 to 15, four bytes each
  AND $3C                 ;
  LD E,A                  ;
  LD D,$00                ;
  LD HL,SPOTS             ;
  ADD HL,DE               ;
  LD IY,QUEST_COLLECTABLES ; for the five collectables' records, from record 4
  LD C,$05                 ;
  LD DE,$000D              ;
NEW_QUEST_0:
  LD A,(HL)               ; the room...
  LD (IY+$08),A           ;
  LD B,$03                ; ...then U, V and Z
NEW_QUEST_1:
  INC HL                  ;
  INC IY                  ;
  LD A,(HL)               ;
  LD (IY+$00),A           ;
  DJNZ NEW_QUEST_1        ;
  INC HL                  ; the next place, the next record
  ADD IY,DE               ;
  DEC C                   ;
  JR NZ,NEW_QUEST_0       ;
  RET                     ;

; Where the collectables can start
;
; Twenty places, four bytes each: the room, then U, V and Z. NEW_QUEST takes
; five in a row, starting at one of the first sixteen chosen at random, so a
; game's five collectables are always five neighbours in this list and places
; 16 to 19 are only ever used by the later ones.
SPOTS:
  DEFB $78,$B8,$48,$80    ; Spot 0: room 120, U 184, V 72, Z 128
  DEFB $25,$48,$48,$A4    ; Spot 1: room 37, U 72, V 72, Z 164
  DEFB $3E,$78,$B8,$80    ; Spot 2: room 62, U 120, V 184, Z 128
  DEFB $70,$B8,$B8,$81    ; Spot 3: room 112, U 184, V 184, Z 129
  DEFB $6C,$78,$B8,$98    ; Spot 4: room 108, U 120, V 184, Z 152
  DEFB $00,$68,$78,$98    ; Spot 5: room 0, U 104, V 120, Z 152
  DEFB $45,$B8,$B8,$80    ; Spot 6: room 69, U 184, V 184, Z 128
  DEFB $8E,$48,$98,$B0    ; Spot 7: room 142, U 72, V 152, Z 176
  DEFB $4E,$80,$80,$81    ; Spot 8: room 78, U 128, V 128, Z 129
  DEFB $0F,$78,$48,$A4    ; Spot 9: room 15, U 120, V 72, Z 164
  DEFB $2A,$78,$78,$B0    ; Spot 10: room 42, U 120, V 120, Z 176
  DEFB $05,$68,$78,$A4    ; Spot 11: room 5, U 104, V 120, Z 164
  DEFB $8D,$78,$68,$B0    ; Spot 12: room 141, U 120, V 104, Z 176
  DEFB $46,$80,$80,$80    ; Spot 13: room 70, U 128, V 128, Z 128
  DEFB $04,$B8,$78,$B0    ; Spot 14: room 4, U 184, V 120, Z 176
  DEFB $10,$48,$78,$B0    ; Spot 15: room 16, U 72, V 120, Z 176
  DEFB $81,$A8,$48,$81    ; Spot 16: room 129, U 168, V 72, Z 129
  DEFB $12,$58,$58,$B0    ; Spot 17: room 18, U 88, V 88, Z 176
  DEFB $92,$A8,$98,$B0    ; Spot 18: room 146, U 168, V 152, Z 176
  DEFB $1B,$48,$78,$B0    ; Spot 19: room 27, U 72, V 120, Z 176

; The update routine for a spider that runs straight, and a creature from the
; sky
;
; Graphics 16 and 17, a spider (both show the same sprite), enter here and flip
; their picture every turn as they go; graphics 80 and 81, a creature that
; falls from the sky (SKY_DROP), enter at SKY_ROAMER, which skips the flip.
; Either is deadly both ways (MAKE_DEADLY), and falls, faster each turn since
; its steps are never cleared, but never lower than 129: below that it is put
; back at 129 with no fall.
;
; It runs straight at four units a turn until it bumps into something, which
; the collision code shows by clearing the step. Then it picks a new way, the
; sign from bit 3 of R: along U if the bump was in V, otherwise along V. The
; way it faces goes with the way it runs: bit 0 of the graphic and the mirror
; bit (6) of the flags make four facings from two pictures.
;
; IX the object record
ROAMER:
  LD A,(IX+$07)           ; flip the picture
  XOR $40                 ;
  LD (IX+$07),A           ;
SKY_ROAMER:
  CALL DRAW_AT_L16_D8     ; SKY_ROAMER: the drawing nudge
  CALL MAKE_DEADLY           ; deadly; fall
  CALL DEC_DZ_AND_UPDATE_UVZ ;
  LD A,(IX+$03)           ; no lower than 129
  CP $81                  ;
  JR NC,ROAMER_0          ;
  LD (IX+$03),$81         ;
  LD (IX+$0B),$00         ;
ROAMER_0:
  LD A,(IX+$09)                 ; still moving: redraw
  OR (IX+$0A)                   ;
  JP NZ,SET_WIPE_AND_DRAW_FLAGS ;
  LD A,R                  ; stopped: four units, either way
  AND $08                 ;
  SUB $04                 ;
  BIT 1,(IX+$0C)          ; not bumped in V: along V, graphic odd, not
  JR NZ,ROAMER_1          ; mirrored...
  LD (IX+$0A),A           ;
  SET 0,(IX+$00)          ;
  RES 6,(IX+$07)          ;
  JR ROAMER_2             ;
ROAMER_1:
  LD (IX+$09),A           ; ...bumped in V: along U, graphic even, mirrored
  RES 0,(IX+$00)          ;
  SET 6,(IX+$07)          ;
ROAMER_2:
  AND A                        ; going backwards: the other graphic of the two;
  JP P,SET_WIPE_AND_DRAW_FLAGS ; redraw
  LD A,(IX+$00)                ;
  XOR $01                      ;
  LD (IX+$00),A                ;
  JP SET_WIPE_AND_DRAW_FLAGS   ;

; The update routine for the walker from the sky
;
; Graphics 168 to 171, a creature that falls from the sky (SKY_DROP) and walks.
; As ROAMER, but its picture changes every turn between the two graphics of a
; pair (bit 0), which is its walk, and bit 1 of the graphic is what goes with
; the way it runs.
;
; IX the object record
SKY_WALKER:
  CALL DRAW_AT_L16_D8        ; the drawing nudge; deadly; fall
  CALL MAKE_DEADLY           ;
  CALL DEC_DZ_AND_UPDATE_UVZ ;
  LD A,(IX+$00)           ; the next step of the walk
  XOR $01                 ;
  LD (IX+$00),A           ;
  LD A,(IX+$03)           ; no lower than 129
  CP $81                  ;
  JR NC,SKY_WALKER_0      ;
  LD (IX+$03),$81         ;
  LD (IX+$0B),$00         ;
SKY_WALKER_0:
  LD A,(IX+$09)                 ; still moving: redraw
  OR (IX+$0A)                   ;
  JP NZ,SET_WIPE_AND_DRAW_FLAGS ;
  LD A,R                  ; stopped: four units, either way
  AND $08                 ;
  SUB $04                 ;
  BIT 1,(IX+$0C)          ; not bumped in V: along V, the second pair, not
  JR NZ,SKY_WALKER_1      ; mirrored...
  LD (IX+$0A),A           ;
  SET 1,(IX+$00)          ;
  RES 6,(IX+$07)          ;
  JR SKY_WALKER_2         ;
SKY_WALKER_1:
  LD (IX+$09),A           ; ...bumped in V: along U, the first pair, mirrored
  RES 1,(IX+$00)          ;
  SET 6,(IX+$07)          ;
SKY_WALKER_2:
  AND A                        ; going backwards: the other pair; redraw
  JP P,SET_WIPE_AND_DRAW_FLAGS ;
  LD A,(IX+$00)                ;
  XOR $02                      ;
  LD (IX+$00),A                ;
  JP SET_WIPE_AND_DRAW_FLAGS   ;

; The update routine for the crumbling block
;
; Graphics 136 to 139: a block that crumbles a stage for each turn he stands on
; it, and vanishes after the fourth. It needs both bit 7 of +17, which the
; collision code sets when he (or the heavy block, HEAVY_BLOCK) lands on it
; (MARK_STOOD_ON), and bit 3 of +D, set for anything landing on it
; (ADJ_DZ_FOR_OBJ_INTERSECT); it clears both, then moves up a graphic, or from
; 139 becomes graphic 1, which DRAW_OBJECT rubs out and turns into an empty
; record.
;
; Measured in the simulator in room 4: he landed on it and it went 136, 137,
; 138, 139, gone, a turn each, and he fell.
;
; IX the object record
CRUMBLING_BLOCK:
  CALL DRAW_AT_L16_D8     ; the drawing nudge; no fall; move
  LD (IX+$0B),$00         ;
  CALL CLIP_AND_MOVE      ;
  BIT 7,(IX+$17)          ; he has landed on it this turn?
  RET Z                   ;
  RES 7,(IX+$17)          ;
  BIT 3,(IX+$0D)          ;
  RET Z                   ;
  RES 3,(IX+$0D)          ;
  LD A,(IX+$00)              ; the next stage; redraw
  CP $8B                     ;
  JR Z,CRUMBLING_BLOCK_0     ;
  INC A                      ;
  LD (IX+$00),A              ;
  JP SET_WIPE_AND_DRAW_FLAGS ;
CRUMBLING_BLOCK_0:
  LD (IX+$00),$01            ; after the last: vanish
  JP SET_WIPE_AND_DRAW_FLAGS ;

; The update routine for a conveyor that carries things forwards in U
;
; Graphic 140. What stands on a conveyor is carried by the collision code, not
; here: when something lands on one of graphics 140 to 143, CONVEYOR_PUSH adds
; to its step the pair from CONVEYOR_STEPS for that graphic, on every other
; turn, once a turn -- bit 3 of the conveyor's +D says it has pushed this turn.
; All this routine does is clear that bit, so it can push again next turn.
;
; Measured in the simulator in room 37: standing on graphic 140 he went up two
; units in U every other turn, and on graphic 142 the same in V.
;
; IX the object record
CONVEYOR_PLUS_U:
  CALL DRAW_AT_L16_D8     ; the drawing nudge; ready to push again; move
  RES 3,(IX+$0D)          ; without falling
  CALL CLIP_AND_MOVE      ;
  RET                     ;

; The update routine for a conveyor that carries things backwards in U
;
; Graphic 141; the same code as CONVEYOR_PLUS_U, a copy for each graphic. No
; room has one: this never ran in the build's sessions.
;
; IX the object record
CONVEYOR_MINUS_U:
  CALL DRAW_AT_L16_D8     ; the drawing nudge; ready to push again; move
  RES 3,(IX+$0D)          ; without falling
  CALL CLIP_AND_MOVE      ;
  RET                     ;

; The update routine for a conveyor that carries things forwards in V
;
; Graphic 142; the same code as CONVEYOR_PLUS_U.
;
; IX the object record
CONVEYOR_PLUS_V:
  CALL DRAW_AT_L16_D8     ; the drawing nudge; ready to push again; move
  RES 3,(IX+$0D)          ; without falling
  CALL CLIP_AND_MOVE      ;
  RET                     ;

; The update routine for a conveyor that carries things backwards in V
;
; Graphic 143; the same code as CONVEYOR_PLUS_U.
;
; IX the object record
CONVEYOR_MINUS_V:
  CALL DRAW_AT_L16_D8     ; the drawing nudge; ready to push again; move
  RES 3,(IX+$0D)          ; without falling
  CALL CLIP_AND_MOVE      ;
  RET                     ;

; What each conveyor adds to the step of what stands on it
;
; Four pairs of U and V, by the conveyor's graphic less 140 (its low two bits):
; +2 in U, -2 in U, +2 in V, -2 in V. Read by CONVEYOR_PUSH on every other
; turn.
CONVEYOR_STEPS:
  DEFB $02,$00            ; Graphics 140 to 143: (2, 0), (-2, 0), (0, 2), (0,
  DEFB $FE,$00            ; -2)
  DEFB $00,$02            ;
  DEFB $00,$FE            ;

; The quest's things, as a game starts
;
; Eighteen records of sixteen bytes, the first sixteen bytes of an object
; record (OBJECTS): 0-3 the quest items, 4-8 the collectables, 9-16 the pieces
; of the pentagram, 17 the bucket, empty until the well gives one (labelled
; QUEST_START_BUCKET). NEW_QUEST copies them to QUEST_RECORDS at every new game
; and gives the collectables their places, so the rooms and positions of
; records 4 to 8 here are never used.
;
; QUEST_INTO_ROOM loads QUEST_START_BUCKET's address and adds 16 before it
; looks at a record, so the address it wants is only "16 bytes before
; QUEST_RECORDS"; it reads nothing here.
QUEST_START:
  DEFB $70,$50,$A0,$80,$08,$08,$20,$10 ; Record 0, quest item: graphic 112 at U
  DEFB $7A,$00,$00,$00,$00,$00,$00,$00 ; 80, V 160, Z 128 in room 122;
                                       ; half-sizes 8, 8, height 32; flags $10
  DEFB $71,$70,$A0,$80,$08,$08,$20,$10 ; Record 1, quest item: graphic 113 at U
  DEFB $80,$00,$00,$00,$00,$00,$00,$00 ; 112, V 160, Z 128 in room 128;
                                       ; half-sizes 8, 8, height 32; flags $10
  DEFB $72,$84,$A0,$80,$08,$08,$20,$10 ; Record 2, quest item: graphic 114 at U
  DEFB $11,$00,$00,$00,$00,$00,$00,$00 ; 132, V 160, Z 128 in room 17;
                                       ; half-sizes 8, 8, height 32; flags $10
  DEFB $73,$A0,$A0,$80,$08,$08,$20,$10 ; Record 3, quest item: graphic 115 at U
  DEFB $21,$00,$00,$00,$00,$00,$00,$00 ; 160, V 160, Z 128 in room 33;
                                       ; half-sizes 8, 8, height 32; flags $10
  DEFB $94,$50,$50,$80,$08,$08,$0C,$14 ; Record 4, collectable: graphic 148 at
  DEFB $61,$00,$00,$00,$00,$00,$00,$00 ; U 80, V 80, Z 128 in room 97;
                                       ; half-sizes 8, 8, height 12; flags $14
  DEFB $93,$50,$80,$80,$08,$08,$0C,$14 ; Record 5, collectable: graphic 147 at
  DEFB $61,$00,$00,$00,$00,$00,$00,$00 ; U 80, V 128, Z 128 in room 97;
                                       ; half-sizes 8, 8, height 12; flags $14
  DEFB $92,$70,$80,$80,$08,$08,$0C,$14 ; Record 6, collectable: graphic 146 at
  DEFB $61,$00,$00,$00,$00,$00,$00,$00 ; U 112, V 128, Z 128 in room 97;
                                       ; half-sizes 8, 8, height 12; flags $14
  DEFB $91,$80,$80,$80,$08,$08,$0C,$14 ; Record 7, collectable: graphic 145 at
  DEFB $61,$00,$00,$00,$00,$00,$00,$00 ; U 128, V 128, Z 128 in room 97;
                                       ; half-sizes 8, 8, height 12; flags $14
  DEFB $90,$A0,$80,$80,$08,$08,$0C,$14 ; Record 8, collectable: graphic 144 at
  DEFB $61,$00,$00,$00,$00,$00,$00,$00 ; U 160, V 128, Z 128 in room 97;
                                       ; half-sizes 8, 8, height 12; flags $14
  DEFB $80,$60,$80,$7F,$0C,$0C,$00,$00 ; Record 9, piece of the pentagram:
  DEFB $52,$00,$00,$00,$00,$00,$00,$00 ; graphic 128 at U 96, V 128, Z 127 in
                                       ; room 82; half-sizes 12, 12, height 0;
                                       ; flags $00
  DEFB $81,$6C,$8C,$7F,$0C,$0C,$00,$00 ; Record 10, piece of the pentagram:
  DEFB $52,$00,$00,$00,$00,$00,$00,$00 ; graphic 129 at U 108, V 140, Z 127 in
                                       ; room 82; half-sizes 12, 12, height 0;
                                       ; flags $00
  DEFB $82,$78,$98,$7F,$0C,$0C,$00,$00 ; Record 11, piece of the pentagram:
  DEFB $52,$00,$00,$00,$00,$00,$00,$00 ; graphic 130 at U 120, V 152, Z 127 in
                                       ; room 82; half-sizes 12, 12, height 0;
                                       ; flags $00
  DEFB $83,$84,$A4,$7F,$0C,$0C,$00,$00 ; Record 12, piece of the pentagram:
  DEFB $52,$00,$00,$00,$00,$00,$00,$00 ; graphic 131 at U 132, V 164, Z 127 in
                                       ; room 82; half-sizes 12, 12, height 0;
                                       ; flags $00
  DEFB $84,$78,$68,$7F,$0C,$0C,$00,$00 ; Record 13, piece of the pentagram:
  DEFB $52,$00,$00,$00,$00,$00,$00,$00 ; graphic 132 at U 120, V 104, Z 127 in
                                       ; room 82; half-sizes 12, 12, height 0;
                                       ; flags $00
  DEFB $85,$84,$74,$7F,$0C,$0C,$00,$00 ; Record 14, piece of the pentagram:
  DEFB $52,$00,$00,$00,$00,$00,$00,$00 ; graphic 133 at U 132, V 116, Z 127 in
                                       ; room 82; half-sizes 12, 12, height 0;
                                       ; flags $00
  DEFB $86,$90,$80,$7F,$0C,$0C,$00,$00 ; Record 15, piece of the pentagram:
  DEFB $52,$00,$00,$00,$00,$00,$00,$00 ; graphic 134 at U 144, V 128, Z 127 in
                                       ; room 82; half-sizes 12, 12, height 0;
                                       ; flags $00
  DEFB $87,$9C,$8C,$7F,$0C,$0C,$00,$00 ; Record 16, piece of the pentagram:
  DEFB $52,$00,$00,$00,$00,$00,$00,$00 ; graphic 135 at U 156, V 140, Z 127 in
                                       ; room 82; half-sizes 12, 12, height 0;
                                       ; flags $00
QUEST_START_BUCKET:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; Record 17, the bucket: empty until the
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; well gives one

; The quest's things, as they are now
;
; QUEST_START copied here at every new game (NEW_QUEST) and kept up to date:
; QUEST_INTO_ROOM puts the records of the room he enters into the object
; records, linking each to its record through +10 and +11; QUEST_OUT_OF_ROOM
; copies them back as he leaves, finding each by its graphic; a thing picked up
; has its record's graphic cleared, and given back when it is put down
; (TAKE_OR_LEAVE). A record with graphic 0 is in no room.
;
; Eighteen records are used. The block is nineteen long, and the last sixteen
; bytes nothing reads or writes. Zero on the tape.
QUEST_RECORDS:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
QUEST_COLLECTABLES:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
QUEST_BUCKET:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; Nineteenth record: unused
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;

; Where the collectables settle in room 82
;
; Five pairs of U and V, one for each collectable, by its graphic less 144 (its
; low three bits): where COLLECTABLE steers it once the pentagram is showing.
; There is no height: it glides at the height it has.
TARGETS:
  DEFB $70,$B0            ; Graphic 144: U 112, V 176
  DEFB $9C,$A2            ; Graphic 145: U 156, V 162
  DEFB $A2,$6A            ; Graphic 146: U 162, V 106
  DEFB $72,$5C            ; Graphic 147: U 114, V 92
  DEFB $50,$88            ; Graphic 148: U 80, V 136

; Unused: a blip at a pitch chosen by the turn counter
;
; No code or table holds this address, and no session ran it. The 27 bytes
; decode cleanly up to BLIP_PITCHES: BC = the address of BLIP_PITCHES; BIT
; 1,(IX+$07); RES 1,(IX+$07); RET Z; A = TURNS AND 15; B = the byte at BC plus
; that; C = 12; JP BEEP. So: if bit 1 of the object's flags was set, clear it
; and play twelve waves at one of sixteen pitches, picked by the turn counter.
;
; It looks like Knight Lore's blip for the movable block, which plays four
; waves at one of eight pitches picked by the frame counter every frame; here
; it is gated on a flag bit and left unused. Bit 1 of the flags is the one the
; collision code sets on the record it is moving (ADJ_FOR_OUT_OF_BOUNDS) and on
; a puff (START_PUFF).
;
; IX an object record
BLIP_BY_TURN:
  LD BC,BLIP_PITCHES
  BIT 1,(IX+$07)
  RES 1,(IX+$07)
  RET Z
  LD A,(TURNS)
  AND $0F
  LD L,A
  LD H,$00
  ADD HL,BC
  LD B,(HL)
  LD C,$0C
  JP BEEP

; Pitches for the unused blip at BLIP_BY_TURN
;
; Sixteen half-wave counts from here for CLICK, every one a multiple of 16 (the
; larger, the lower). After them, up to PAUSE_BEEP, are 64 more bytes of the
; same kind that no code reads: a run of 32 that climbs from $20 to $90 and
; back two at a time, and two of 16. sna2ctl took some of the bytes for text,
; so the tables are cut into the entries that follow at places that mean
; nothing.
BLIP_PITCHES:
  DEFB $20,$20,$30

; More of the unused blip's pitches
BLIP_PITCHES_B:
  DEFB $40

; More of the unused blip's pitches
BLIP_PITCHES_C:
  DEFB $50,$20,$20,$30

; More of the unused blip's pitches
BLIP_PITCHES_D:
  DEFB $40

; More of the unused blip's pitches
BLIP_PITCHES_E:
  DEFB $50,$20,$20,$30

; More of the unused blip's pitches
BLIP_PITCHES_F:
  DEFB $40

; The last of the unused blip's pitches, and the start of an unread run
;
; Two bytes finish the sixteen of BLIP_PITCHES; the four after them start the
; run of 32 that climbs and falls, which no code reads.
BLIP_PITCHES_G:
  DEFB $50,$20,$20,$20,$30,$30

; More of the unread run of pitches
SWEEP_PITCHES:
  DEFB $40,$40,$50,$50,$60,$60,$70,$70
  DEFB $80,$80,$90,$90,$90,$90,$80,$80
  DEFB $70,$70,$60,$60,$50,$50,$40,$40

; The end of the unread run of pitches
SWEEP_PITCHES_B:
  DEFB $30,$30,$20,$20

; Two more unread tables of pitches
;
; Sixteen bytes that fall, zigzagging, from $90 to $20, then the start of
; sixteen that repeat a pattern of eight; no code reads either.
MORE_PITCHES:
  DEFB $90,$80,$70,$80,$70,$60,$70,$60 ; Falling
  DEFB $50,$60,$50,$40,$50,$40,$30,$20 ;
  DEFB $40,$40,$40        ; The start of the repeating pattern

; More of the repeating pattern
MORE_PITCHES_B:
  DEFB $30,$50,$50,$50,$50

; More of the repeating pattern
MORE_PITCHES_C:
  DEFB $40,$40,$40

; The end of the repeating pattern
MORE_PITCHES_D:
  DEFB $30,$50,$50,$50,$50

; The pause beep
;
; Used by the routine at PAUSE.
;
; Twelve waves, played by PAUSE as the game pauses and again as it goes on. The
; pitch is the effect counter's first byte (SOUND_COUNT) plus 64, after adding
; one to it -- so each pause also gives the sound effect under way, or the last
; one, an extra turn or two when play resumes.
PAUSE_BEEP:
  LD HL,SOUND_COUNT       ; one more on the effect's count
  INC (HL)                ;
  LD A,(HL)               ;
  ADD A,$40               ; twelve waves at 64 plus that
  LD B,A                  ;
  LD C,$0C                ;
  JP BEEP                 ;

; The jump's warble
;
; Used by the routine at HANDLE_JUMP.
;
; Sixteen single waves, the half-wave count scrambled from the step count with
; an XOR as Knight Lore's werewolf warble does (with $A5 for its $55).
; HANDLE_JUMP plays it as he leaves the ground.
JUMP_SOUND:
  LD C,$10                ; for C = 16 down to 1: one wave at (C XOR $A5) + C
JUMP_SOUND_0:
  LD A,C                  ;
  XOR $A5                 ;
  ADD A,C                 ;
  LD B,A                  ;
  CALL CLICK              ;
  DEC C                   ;
  JR NZ,JUMP_SOUND_0      ;
  RET                     ;

; Play this turn's note of the sound effect under way
;
; Used by the routine at OBJECT_DONE.
;
; Called by OBJECT_DONE every turn. SOUND_COUNT is two bytes: how many notes
; are left, and which effect. While the count is not zero, this takes one off
; and plays twelve waves at the pitch found at the effect's address in EFFECTS
; plus the count before it was taken: the notes run backwards from the end, and
; the byte at the effect's address itself is never played.
;
; Only two effects are started: 0, four notes, when a room has been entered
; (OBJECT_DONE), and 1, five notes, as he picks something up or puts it down
; (TAKE_OR_LEAVE). Effects 2 and 3 have their notes but nothing starts them.
EFFECT_NOTE:
  LD HL,SOUND_COUNT       ; nothing under way: done
  LD A,(HL)               ;
  AND A                   ;
  RET Z                   ;
  DEC (HL)                ; one note fewer; keep the count before
  EX AF,AF'               ;
  INC HL                  ; HL = the effect's notes (EFFECTS)
  LD A,(HL)               ;
  LD BC,EFFECTS           ;
  CALL TABLE_WORD         ;
  EX AF,AF'               ; twelve waves at the note the count points to
  LD C,A                  ;
  LD B,$00                ;
  ADD HL,BC               ;
  LD B,(HL)               ;
  LD C,$0C                ;
  JP BEEP                 ;

; The sound effects
;
; The addresses of the four effects' notes, then the notes: half-wave counts
; for CLICK. An effect of n notes plays the n bytes after its address, the last
; first (EFFECT_NOTE). Effect 0, entering a room, four notes: the last two
; bytes of this block and the first two of EFFECT_PITCHES_B. Effect 1, picking
; up or putting down, five notes: the last byte of EFFECT_PITCHES_B and the
; first four of EFFECT_PITCHES_C, played falling in pitch. Effects 2 and 3 are
; never started; their addresses point further into EFFECT_PITCHES_C, the byte
; at effect 2's being effect 1's last note.
EFFECTS:
  DEFW EFFECT_PITCHES     ; Effects 0 to 3
  DEFW $D619              ;
  DEFW $D61E              ;
  DEFW $D625              ;
EFFECT_PITCHES:
  DEFB $40,$70,$40        ; Effect 0's address byte, never played, then its
                          ; first two notes

; More of the effects' notes
;
; sna2ctl took these three bytes for text. The first two are effect 0's last
; two in memory (the first two it plays); the third is effect 1's first in
; memory (the last it plays).
EFFECT_PITCHES_B:
  DEFB $70,$50,$70

; The rest of the effects' notes
;
; Effect 1's other four notes, then what effects 2 and 3 would play if anything
; started them.
EFFECT_PITCHES_C:
  DEFB $60,$50,$40,$40,$50,$60,$70,$80
  DEFB $80,$80,$30,$60,$30,$60

; The sound of a bolt being fired
;
; Used by the routine at FIRE.
;
; 32 single waves; each half-wave count is the step count less the one before.
; FIRE comes here straight from an LDIR that leaves B zero, so the counts
; alternate between a short one falling from 32 and a long one falling from
; 255: a high note and a low one, interleaved.
;
; B the count to start from
FIRE_SOUND:
  LD C,$20                ; for C = 32 down to 1: one wave at C less the last
FIRE_SOUND_0:
  LD A,C                  ; count
  SUB B                   ;
  LD B,A                  ;
  CALL CLICK              ;
  DEC C                   ;
  JR NZ,FIRE_SOUND_0      ;
  RET                     ;

; A footstep
;
; Used by the routine at HANDLE_FORWARD.
;
; HANDLE_FORWARD calls this for every step of his walk; STEP_SOUND counts them,
; and every fourth plays two waves, at a half-wave count of 64 and 96 by turns.
FOOTSTEP:
  LD HL,STEP_SOUND        ; one more step; which pitch?
  INC (HL)                ;
  LD A,(HL)               ;
  BIT 2,A                 ;
  JR Z,FOOTSTEP_0         ;
  AND $03                 ; every fourth: two waves at 64...
  RET NZ                  ;
  LD BC,$4002             ;
  JR BEEP                 ;
FOOTSTEP_0:
  AND $03                 ; ...or at 96
  RET NZ                  ;
  LD BC,$6002             ;
  JR BEEP                 ;

; The sound of a puff
;
; Used by the routine at PUFF.
;
; Four single waves at pitches read from the ROM, as Knight Lore's crashes and
; sparkles are. The address is the word at RANDOM with its high byte cut to
; five bits: the random number is one byte, and the byte after it, the high one
; here, is BUCKET_OUT, which is 0 or 1, so the pitches come from the first 512
; bytes of the ROM. Played by PUFF as a puff begins.
PUFF_SOUND:
  LD HL,(RANDOM)          ; HL = an address in the ROM; four waves
  LD A,H                  ;
  AND $1F                 ;
  LD H,A                  ;
  LD E,$04                ;
PUFF_SOUND_0:
  LD A,(HL)               ; each at the next ROM byte, less its top bit
  INC HL                  ;
  AND $7F                 ;
  LD B,A                  ;
  LD C,$01                ;
  CALL BEEP               ;
  DEC E                   ;
  JR NZ,PUFF_SOUND_0      ;
  RET                     ;

; Unused: two more beeps, left as data
;
; Code no path reaches: no code or table holds any address in it, and no
; session ran it. It stays data because a byte in its middle is data that its
; second half reads; declared as code, that byte becomes a NOP which an LD
; reads, and skool2asm warns (tried in a scratch build). In order:
;
; Fourteen bytes: LD A,(IX+$00); CPL; RRCA three times; AND $E0; LD B,A; LD
; C,$06; JR to BEEP. Six waves pitched by the object's graphic, the top three
; bits of its complement rotated right three times.
;
; One byte, zero on the tape and written by nothing: the pitch the next part
; reads.
;
; Seven bytes: LD A from that byte; CPL; LD B,A; LD C,$08; and on into BEEP,
; which follows. Eight waves pitched by the complement of the spare byte.
BEEP_BY_GRAPHIC:
  DEFB $DD,$7E,$00,$2F,$0F,$0F,$0F,$E6
  DEFB $E0,$47,$0E,$06,$18,$08,$00,$3A
  DEFB $73,$D6,$2F,$47,$0E,$08

; Beep: C waves of half-wave count B
;
; Used by the routines at BLIP_BY_TURN, PAUSE_BEEP, EFFECT_NOTE, FOOTSTEP and
; PUFF_SOUND.
;
; The common tail of the effects. CLICK leaves B as it found it, so every wave
; has the same pitch.
;
; B the half-wave count (0 is 256)
; C the number of waves
BEEP:
  CALL CLICK              ; C waves
  DEC C                   ;
  JR NZ,BEEP              ;
  RET                     ;

; One wave
;
; Used by the routines at JUMP_SOUND, FIRE_SOUND and BEEP.
;
; Speaker bit on for B turns of a 13 T-state loop, then off for as long, with
; the border black throughout. A wave takes 26 times B plus a caller's
; overhead: 82 T-states within a BEEP, 101 for the jump, 94 for the bolt firing
; and 151 for the puff (measured): a count of 128 comes out at about 1kHz. The
; same routine as Knight Lore's.
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

; Look up a word in a table
;
; Used by the routine at EFFECT_NOTE.
;
;   A the index
;   BC the table
; O:HL the word at BC + 2A
TABLE_WORD:
  LD L,A                  ; HL = (BC + 2 * A)
  LD H,$00                ;
  ADD HL,HL               ;
  ADD HL,BC               ;
  LD A,(HL)               ;
  INC HL                  ;
  LD H,(HL)               ;
  LD L,A                  ;
  RET                     ;

; Play the menu's tune at DE, once, until a key is pressed
;
; Used by the routine at MENU.
;
; The menu (MENU) calls this every time round its loop. TUNE_HEARD remembers
; that the tune has been played, so it plays only the first time; START clears
; it with the rest of the game's variables after every game, so it plays again
; then. Before each note the whole keyboard is read, and any key stops the tune
; at once.
;
; DE the tune
PLAY_TUNE_ONCE:
  LD HL,TUNE_HEARD        ; played already: done
  LD A,(HL)               ;
  AND A                   ;
  RET NZ                  ;
  SET 0,(HL)              ; not again
PLAY_TUNE_ONCE_0:
  XOR A                   ; A = 0 reads every half-row at once: any key stops
  CALL READ_KEYS          ; it
  JR Z,PLAY_TUNE_ONCE_1   ;
  RET                     ;
PLAY_TUNE_ONCE_1:
  LD A,(DE)               ; $FF ends the tune; play a note, and look at the
  CP $FF                  ; keys again
  JR Z,PLAY_TUNE_0        ;
  CALL PLAY_NOTE          ;
  JR PLAY_TUNE_ONCE_0     ;

; Play the tune at DE
;
; Used by the routines at START, WON and BUCKET.
;
; Plays the whole tune and returns; nothing else happens meanwhile. Used by
; START as a game starts, WON and GAME_OVER (in WON) as it ends, and BUCKET
; when the bucket reaches a quest item.
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
; its length less one, one to four units. The note's three bytes are two loop
; counts that time each half of a wave and how many waves make one unit, and
; the wave count rises with the pitch, which keeps every unit close to 0.155
; seconds whatever the note. The speaker is driven directly, off for one
; half-wave and on for the other, with the border black.
;
; The routine and NOTES are byte for byte Knight Lore's (play_note there), at
; other addresses.
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
  POP DE                  ; the tune pointer back in DE
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
  LD L,A                  ;
  LD BC,$430B             ; ...each 17163 turns of a 26 T-state loop, about
PLAY_NOTE_6:
  PUSH BC                 ; 0.127 seconds (no tune has a rest)
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
; The same 183 bytes as Knight Lore's note table, and so the same scale: a
; semitone a row for five octaves, G#1 at row 1 and A4 (440Hz) at row 38, with
; the timing drifting a little sharp at the bottom and flat at the top, and row
; 18 a copy of row 17's pitch where C#3 should be. The comments are that
; table's, worked out from the loop timings at 3.5MHz.
NOTES:
  DEFB $00,$00,$00        ; index 0 is a rest, so this row is never read
  DEFB $F4,$0A,$08        ; 1: about 52.6 Hz, G#1; 8 cycles
  DEFB $65,$0A,$09        ; 2: about 55.7 Hz, A1; 9 cycles
  DEFB $DE,$09,$09        ; 3: about 59.0 Hz, A#1; 9 cycles
  DEFB $5E,$09,$0A        ; 4: about 62.5 Hz, B1; 10 cycles
  DEFB $E7,$08,$0A        ; 5: about 66.2 Hz, C2; 10 cycles
  DEFB $75,$08,$0B        ; 6: about 70.1 Hz, C#2; 11 cycles
  DEFB $0A,$08,$0C        ; 7: about 74.3 Hz, D2; 12 cycles
  DEFB $A5,$07,$0C        ; 8: about 78.7 Hz, D#2; 12 cycles
  DEFB $45,$07,$0D        ; 9: about 83.4 Hz, E2; 13 cycles
  DEFB $EB,$06,$0E        ; 10: about 88.4 Hz, F2; 14 cycles
  DEFB $96,$06,$0F        ; 11: about 93.6 Hz, F#2; 15 cycles
  DEFB $46,$06,$0F        ; 12: about 99.1 Hz, G2; 15 cycles
  DEFB $FA,$05,$10        ; 13: about 105 Hz, G#2; 16 cycles
  DEFB $B3,$05,$11        ; 14: about 111 Hz, A2; 17 cycles
  DEFB $6F,$05,$12        ; 15: about 118 Hz, A#2; 18 cycles
  DEFB $2F,$05,$13        ; 16: about 125 Hz, B2; 19 cycles
  DEFB $F3,$04,$15        ; 17: about 132 Hz, C3; 21 cycles
  DEFB $F3,$04,$16        ; 18: the same pitch bytes as 17, so C#3 is missing
                          ; -- probably a slip, since the cycle count carries
                          ; on as for C#3; 22 cycles
  DEFB $85,$04,$17        ; 19: about 148 Hz, D3; 23 cycles
  DEFB $52,$04,$19        ; 20: about 157 Hz, D#3; 25 cycles
  DEFB $23,$04,$1A        ; 21: about 166 Hz, E3; 26 cycles
  DEFB $F6,$03,$1C        ; 22: about 176 Hz, F3; 28 cycles
  DEFB $CB,$03,$1D        ; 23: about 187 Hz, F#3; 29 cycles
  DEFB $A3,$03,$1F        ; 24: about 198 Hz, G3; 31 cycles
  DEFB $7D,$03,$21        ; 25: about 209 Hz, G#3; 33 cycles
  DEFB $59,$03,$23        ; 26: about 222 Hz, A3; 35 cycles
  DEFB $38,$03,$25        ; 27: about 235 Hz, A#3; 37 cycles
  DEFB $18,$03,$27        ; 28: about 248 Hz, B3; 39 cycles
  DEFB $FA,$02,$29        ; 29: about 263 Hz, C4; 41 cycles
  DEFB $DD,$02,$2C        ; 30: about 279 Hz, C#4; 44 cycles
  DEFB $C2,$02,$2E        ; 31: about 296 Hz, D4; 46 cycles
  DEFB $A9,$02,$31        ; 32: about 313 Hz, D#4; 49 cycles
  DEFB $91,$02,$34        ; 33: about 331 Hz, E4; 52 cycles
  DEFB $7B,$02,$37        ; 34: about 350 Hz, F4; 55 cycles
  DEFB $66,$02,$3A        ; 35: about 371 Hz, F#4; 58 cycles
  DEFB $51,$02,$3E        ; 36: about 393 Hz, G4; 62 cycles
  DEFB $3F,$02,$41        ; 37: about 415 Hz, G#4; 65 cycles
  DEFB $2D,$02,$45        ; 38: about 440 Hz, A4; 69 cycles
  DEFB $1C,$02,$49        ; 39: about 465 Hz, A#4; 73 cycles
  DEFB $0C,$02,$4E        ; 40: about 493 Hz, B4; 78 cycles
  DEFB $FD,$01,$52        ; 41: about 523 Hz, C5; 82 cycles
  DEFB $EF,$01,$57        ; 42: about 553 Hz, C#5; 87 cycles
  DEFB $E2,$01,$5D        ; 43: about 584 Hz, D5; 93 cycles
  DEFB $D5,$01,$62        ; 44: about 619 Hz, D#5; 98 cycles
  DEFB $C9,$01,$68        ; 45: about 656 Hz, E5; 104 cycles
  DEFB $BD,$01,$6E        ; 46: about 696 Hz, F5; 110 cycles
  DEFB $B3,$01,$75        ; 47: about 734 Hz, F#5; 117 cycles
  DEFB $A9,$01,$7B        ; 48: about 777 Hz, G5; 123 cycles
  DEFB $9F,$01,$83        ; 49: about 824 Hz, G#5; 131 cycles
  DEFB $96,$01,$8B        ; 50: about 872 Hz, A5; 139 cycles
  DEFB $8E,$01,$93        ; 51: about 920 Hz, A#5; 147 cycles
  DEFB $86,$01,$9C        ; 52: about 973 Hz, B5; 156 cycles
  DEFB $7E,$01,$A5        ; 53: about 1033 Hz, C6; 165 cycles
  DEFB $77,$01,$AF        ; 54: about 1091 Hz, C#6; 175 cycles
  DEFB $71,$01,$B9        ; 55: about 1147 Hz, D6; 185 cycles
  DEFB $6A,$01,$C4        ; 56: about 1220 Hz, D#6; 196 cycles
  DEFB $64,$01,$D0        ; 57: about 1290 Hz, E6; 208 cycles
  DEFB $5F,$01,$DC        ; 58: about 1355 Hz, F6; 220 cycles
  DEFB $59,$01,$E9        ; 59: about 1442 Hz, F#6; 233 cycles
  DEFB $54,$01,$F7        ; 60: about 1524 Hz, G6; 247 cycles

; The menu's tune
;
; Played under the menu by PLAY_TUNE_ONCE, the first time the menu is shown
; after a game, until a key is pressed.
;
; A tune is a string of note bytes ended by $FF: the low six bits of a note
; index NOTES (0 would be a rest, and no tune has one), the top two bits its
; length less one, so a note lasts one to four units of about 0.155 seconds.
; The comments name each note by the step of the note table's scale it uses and
; give lengths over one unit as x2, x3 or x4. The other tunes are in the same
; format.
TUNE_MENU:
  DEFB $6C,$29,$2A,$2C,$29,$6A,$6A,$29 ; D#5 x2, C5, C#5, D#5, C5, C#5 x2, C#5
  DEFB $2A,$2C,$29,$67,$6C,$29,$2A,$2C ; x2, C5, C#5, D#5, C5, A#4 x2, D#5 x2,
                                       ; C5, C#5, D#5
  DEFB $29,$6A,$29,$2A,$6C,$60,$65,$6C ; C5, C#5 x2, C5, C#5, D#5 x2, D#4 x2,
  DEFB $29,$2A,$2C,$29,$6A,$6A,$29,$2A ; G#4 x2, D#5 x2, C5, C#5, D#5, C5, C#5
                                       ; x2, C#5 x2, C5, C#5
  DEFB $2C,$29,$67,$6C,$29,$2A,$2C,$29 ; D#5, C5, A#4 x2, D#5 x2, C5, C#5, D#5,
  DEFB $6A,$29,$2A,$6C,$60,$A5,$27,$69 ; C5, C#5 x2, C5, C#5, D#5 x2, D#4 x2,
                                       ; G#4 x3, A#4, C5 x2
  DEFB $65,$AA,$27,$69,$65,$A7,$27,$29 ; G#4 x2, C#5 x3, A#4, C5 x2, G#4 x2,
  DEFB $2A,$2C,$29,$6A,$29,$2A,$6C,$60 ; A#4 x3, A#4, C5, C#5, D#5, C5, C#5 x2,
                                       ; C5, C#5, D#5 x2, D#4 x2
  DEFB $A5,$27,$69,$65,$AA,$27,$69,$65 ; G#4 x3, A#4, C5 x2, G#4 x2, C#5 x3,
  DEFB $A7,$27,$29,$2A,$2C,$29,$6A,$29 ; A#4, C5 x2, G#4 x2, A#4 x3, A#4, C5,
                                       ; C#5, D#5, C5, C#5 x2, C5
  DEFB $2A,$6C,$60,$A5,$FF ; C#5, D#5 x2, D#4 x2, G#4 x3, end

; A tune no code plays
;
; In the tunes' format (TUNE_MENU), and nothing refers to it: perhaps one the
; game once used, or meant to.
TUNE_UNUSED:
  DEFB $27,$67,$67,$23,$67,$EA,$DE,$23 ; A#4, A#4 x2, A#4 x2, F#4, A#4 x2, C#5
  DEFB $23,$5E,$5B,$59,$D7,$23,$FF     ; x4, C#4 x4, F#4, F#4, C#4 x2, A#3 x2,
                                       ; G#3 x2, F#3 x4, F#4, end

; The tune a game starts with
;
; Played in full by START once 0 has been pressed at the menu, before the quest
; is set out.
TUNE_START:
  DEFB $65,$68,$6C,$71,$6F,$2D,$2C,$2F ; G#4 x2, B4 x2, D#5 x2, G#5 x2, F#5 x2,
  DEFB $2D,$6A,$6D,$2C,$2A,$2C,$31,$6C ; E5, D#5, F#5, E5, C#5 x2, E5 x2, D#5,
                                       ; C#5, D#5, G#5, D#5 x2
  DEFB $68,$67,$E5,$FF    ; B4 x2, A#4 x2, G#4 x4, end

; The tune when the bucket reaches a quest item
;
; Played in full by BUCKET.
TUNE_QUEST:
  DEFB $20,$20,$25,$26,$2C,$69,$20,$20 ; D#4, D#4, G#4, A4, D#5, C5 x2, D#4,
  DEFB $22,$24,$E5,$FF                 ; D#4, F4, G4, G#4 x4, end

; The game-over tune
;
; Played in full by GAME_OVER, in WON.
TUNE_OVER:
  DEFB $60,$65,$69,$6C,$69,$65,$65,$67 ; D#4 x2, G#4 x2, C5 x2, D#5 x2, C5 x2,
  DEFB $2A,$29,$27,$25,$64,$60,$60,$65 ; G#4 x2, G#4 x2, A#4 x2, C#5, C5, A#4,
                                       ; G#4, G4 x2, D#4 x2, D#4 x2, G#4 x2
  DEFB $29,$27,$25,$24,$62,$5E,$62,$60 ; C5, A#4, G#4, G4, F4 x2, C#4 x2, F4
  DEFB $65,$64,$E5,$FF                 ; x2, D#4 x2, G#4 x2, G4 x2, G#4 x4, end

; The tune when the quest is complete
;
; Played in full by WON when the fifth collectable reaches its place.
TUNE_WON:
  DEFB $29,$2A,$6C,$29,$2A,$2C,$2E,$6C ; C5, C#5, D#5 x2, C5, C#5, D#5, F5, D#5
  DEFB $6A,$69,$6A,$27,$29,$2A,$2C,$6A ; x2, C#5 x2, C5 x2, C#5 x2, A#4, C5,
                                       ; C#5, D#5, C#5 x2
  DEFB $69,$67,$69,$25,$27,$29,$2A,$69 ; C5 x2, A#4 x2, C5 x2, G#4, A#4, C5,
  DEFB $67,$65,$27,$20,$6C,$64,$E5,$FF ; C#5, C5 x2, A#4 x2, G#4 x2, A#4, D#4,
                                       ; D#5 x2, G4 x2, G#4 x4, end

; The screen buffer
;
; A room is drawn here, 192 rows of 32 bytes with the bottom row first, and
; SHOW_BUFFER copies it to the screen. CLEAR_BUFFER clears it. It starts in the
; last fifteen bytes of the tape's block, which are zero there; everything
; above them is whatever the machine held before the game loaded.
BUFFER:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; Between the buffer and the tables
SPARE:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00

; Every byte with its bits reversed
;
; Built by MAKE_TABLES; FIND_SPRITE mirrors a sprite by looking each byte up
; here.
REVERSED:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; Masks shifted by seven bits
;
; Built by MAKE_TABLES: for every byte, the complement of what it becomes
; shifted left seven bits as a 16-bit number, the high byte at $F2xx and the
; low at $F3xx.
SHIFTED7:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; Masks shifted by six bits
SHIFTED6:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; Masks shifted by five bits
SHIFTED5:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; Masks shifted by four bits
SHIFTED4:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; Masks shifted by three bits
SHIFTED3:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; Masks shifted by two bits
SHIFTED2:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; Masks shifted by one bit
;
; Until the game builds it, the top of this holds what the machine left there
; before the tape loaded: the ROM's graphics for the user-defined characters in
; the last 168 bytes, and below them what the ROM's stack left.
SHIFTED1:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$F3,$0D,$CE,$0B,$E3,$50,$CE,$0B
  DEFB $E4,$50,$1D,$17,$DC,$0A,$CE,$0B,$E7,$50,$1A,$17,$DC,$0A,$DB,$02
  DEFB $4D,$00,$D0,$3D,$1A,$17,$DB,$02,$4D,$00,$53,$46,$AD,$00,$52,$46
  DEFB $8C,$18,$5C,$0E,$00,$47,$C0,$57,$71,$0E,$F3,$0D,$21,$17,$C6,$1E
  DEFB $00,$5E,$76,$1B,$03,$13,$00,$3E,$00,$3C,$42,$42,$7E,$42,$42,$00
  DEFB $00,$7C,$42,$7C,$42,$42,$7C,$00,$00,$3C,$42,$40,$40,$42,$3C,$00
  DEFB $00,$78,$44,$42,$42,$44,$78,$00,$00,$7E,$40,$7C,$40,$40,$7E,$00
  DEFB $00,$7E,$40,$7C,$40,$40,$40,$00,$00,$3C,$42,$40,$4E,$42,$3C,$00
  DEFB $00,$42,$42,$7E,$42,$42,$42,$00,$00,$3E,$08,$08,$08,$08,$3E,$00
  DEFB $00,$02,$02,$02,$42,$42,$3C,$00,$00,$44,$48,$70,$48,$44,$42,$00
  DEFB $00,$40,$40,$40,$40,$40,$7E,$00,$00,$42,$66,$5A,$42,$42,$42,$00
  DEFB $00,$42,$62,$52,$4A,$46,$42,$00,$00,$3C,$42,$42,$42,$42,$3C,$00
  DEFB $00,$7C,$42,$42,$7C,$40,$40,$00,$00,$3C,$42,$42,$52,$4A,$3C,$00
  DEFB $00,$7C,$42,$42,$7C,$44,$42,$00,$00,$3C,$40,$3C,$02,$42,$3C,$00
  DEFB $00,$FE,$10,$10,$10,$10,$10,$00,$00,$42,$42,$42,$42,$42,$3C,$00

