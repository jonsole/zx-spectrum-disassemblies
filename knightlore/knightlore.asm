  DEVICE ZXSPECTRUM48
  ORG $6108

; The font
;
; Forty characters of 8 by 8 pixels, eight bytes each with the top row first. A
; character's code is its position here: $00 to $09 are the digits, $0A to $23
; the letters A to Z, $24 a full stop, $25 a copyright sign, $26 a space and
; $27 a percent sign. There is no lower case. Strings are lists of these codes
; with bit 7 set on the last one (print_text).
;
; print_8x8 finds a character by multiplying its code by eight and adding the
; address held at $5BC7, which every caller of it sets to this table first. All
; the game's text comes from here: the menu, the day and lives counters and the
; messages.
font:
  DEFB $38,$6C,$D6,$D6,$D6,$D6,$6C,$38 ; Code $00: 0
  DEFB $18,$38,$58,$18,$18,$18,$18,$7C ; Code $01: 1
  DEFB $38,$4C,$0C,$3C,$60,$C2,$C2,$FE ; Code $02: 2
  DEFB $38,$4C,$0C,$3C,$0E,$86,$86,$FC ; Code $03: 3
  DEFB $18,$38,$58,$9A,$FE,$1A,$18,$7C ; Code $04: 4
  DEFB $FE,$C2,$C0,$FC,$06,$06,$86,$7C ; Code $05: 5
  DEFB $1E,$32,$60,$7C,$C6,$C6,$C6,$7C ; Code $06: 6
  DEFB $7E,$46,$4C,$0C,$18,$18,$30,$F8 ; Code $07: 7
  DEFB $38,$6C,$6C,$7C,$FE,$C6,$C6,$7C ; Code $08: 8
  DEFB $7C,$C6,$C6,$C6,$7C,$0C,$98,$F0 ; Code $09: 9
  DEFB $0C,$1C,$2E,$66,$46,$CE,$DB,$66 ; Code $0A: A
  DEFB $F8,$6C,$6C,$78,$6C,$66,$66,$FC ; Code $0B: B
  DEFB $0E,$32,$60,$40,$C0,$C2,$E6,$7C ; Code $0C: C
  DEFB $60,$70,$68,$6C,$66,$66,$66,$FC ; Code $0D: D
  DEFB $FE,$60,$64,$7C,$64,$60,$7A,$C6 ; Code $0E: E
  DEFB $C6,$7A,$60,$64,$7C,$64,$60,$60 ; Code $0F: F
  DEFB $0E,$30,$60,$C6,$CE,$F6,$66,$0E ; Code $10: G
  DEFB $EE,$C6,$C6,$FE,$C6,$C6,$C6,$EE ; Code $11: H
  DEFB $7C,$18,$18,$18,$18,$18,$18,$7C ; Code $12: I
  DEFB $1E,$06,$06,$86,$86,$C6,$7E,$1C ; Code $13: J
  DEFB $E4,$68,$70,$78,$6C,$64,$64,$F6 ; Code $14: K
  DEFB $E0,$60,$60,$60,$60,$60,$62,$FE ; Code $15: L
  DEFB $C6,$EE,$EE,$D6,$D6,$D6,$C6,$EE ; Code $16: M
  DEFB $CC,$D6,$D6,$E6,$E4,$C4,$C8,$DE ; Code $17: N
  DEFB $38,$6C,$C6,$C6,$C6,$C6,$6C,$38 ; Code $18: O
  DEFB $F8,$6C,$66,$76,$6E,$60,$60,$F0 ; Code $19: P
  DEFB $38,$6C,$C6,$C6,$C6,$D6,$6C,$3A ; Code $1A: Q
  DEFB $F8,$6C,$66,$76,$7E,$78,$6C,$E6 ; Code $1B: R
  DEFB $38,$64,$60,$3C,$06,$86,$C6,$7C ; Code $1C: S
  DEFB $FE,$9A,$98,$18,$18,$18,$18,$18 ; Code $1D: T
  DEFB $F6,$26,$46,$4E,$CE,$D6,$D6,$66 ; Code $1E: U
  DEFB $E2,$62,$64,$64,$68,$68,$70,$60 ; Code $1F: V
  DEFB $EE,$C6,$D6,$D6,$D6,$EE,$EE,$C6 ; Code $20: W
  DEFB $C6,$C6,$6C,$38,$38,$6C,$C6,$C6 ; Code $21: X
  DEFB $86,$66,$16,$0E,$06,$04,$4C,$38 ; Code $22: Y
  DEFB $7E,$46,$0C,$18,$30,$62,$C2,$FE ; Code $23: Z
  DEFB $00,$00,$00,$00,$00,$18,$18,$00 ; Code $24: full stop
  DEFB $3C,$42,$99,$A1,$A1,$99,$42,$3C ; Code $25: copyright sign
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; Code $26: space
  DEFB $00,$62,$64,$08,$10,$26,$46,$00 ; Code $27: percent sign
; This is the first byte of the disassembly. Below it, $5BA0 to $6107 holds the
; game's variables and its forty object records, which START clears at
; start-up.

; Room shapes
;
; Three records of three bytes, one for each shape of room. Bits 3 to 7 of byte
; 2 of a room record (location_tbl) pick one, and found_screen copies its three
; bytes into variables: byte 0 is half the room's width along x, to $5BAB; byte
; 1 is half its depth along y, to $5BAC; byte 2 is the height of the floor, to
; $5BAE.
;
; Every room is centred on x = $80, y = $80, so shape 0 is a square room
; reaching from $40 to $C0 both ways, shape 1 is half as wide along x and shape
; 2 half as deep along y. The half sizes are what the movement code tests
; objects against to keep them inside the room (chk_plyr_OOB, and the exits at
; screen_west onwards). The floor is at $80 in all three: the third byte is a
; height, not a size. Of the castle's 128 rooms, 70 are shape 0, 34 shape 1 and
; 24 shape 2.
room_size_tbl:
  DEFB $40,$40,$80        ; Shape 0: square, $40 either side of the centre both
                          ; ways; floor at $80
  DEFB $20,$40,$80        ; Shape 1: narrow in x ($20 either side), full depth
                          ; in y; floor at $80
  DEFB $40,$20,$80        ; Shape 2: full width in x, narrow in y ($20 either
                          ; side); floor at $80

; The rooms
;
; Every room in the castle: 128 records of varying length packed end to end,
; the last ending where block_type_tbl begins. There is no index and no
; terminator. find_screen finds a room by walking the records from the start,
; comparing each room number with the player's; byte 1 of a record is the
; distance from itself to the next record, and the walk gives up when it
; reaches the address of block_type_tbl.
;
; Byte 0 is the room number. The castle is a grid of 16 by 16 squares, and the
; number is the square's row times 16 plus its column: walking out through the
; east or west side adds or subtracts 1 in the low four bits only, and north or
; south adds or subtracts 16 (screen_west to screen_south). Only 128 of the 256
; squares are rooms. Byte 1 is the record's length less one. Byte 2 holds the
; room's ink colour in bits 0 to 2 -- magenta, green, cyan or yellow -- which
; found_screen makes into bright ink on black paper at $5BAD, and its shape in
; bits 3 to 7, an index into room_size_tbl.
;
; Next come the room's backgrounds, one byte each, indexes into
; background_type_tbl: walls, arches, doorways and the other fixed scenery. A
; byte of $FF ends them. A room with nothing more in it has no $FF and simply
; ends; 24 rooms are like that.
;
; After the $FF come groups of objects. A group begins with a byte whose bits 3
; to 7 are an index into block_type_tbl and whose bits 0 to 2 are the number of
; copies less one, and carries one position byte per copy. A position byte
; names a cell in the room's grid of 8 by 8 cells on four levels: bits 0 to 2
; the x cell, bits 3 to 5 the y cell and bits 6 and 7 the level.
; next_fg_obj_sprite turns it into coordinates: x is $48 plus 16 times the x
; cell, y likewise, and z is the floor height plus 12 times the level, to which
; the block type can add half a cell in x or y and extra height.
;
; retrieve_screen builds the room as object records, 32 bytes each, from $5C88
; upwards, and clears whatever is left up to font. That is room for 36 objects,
; and six rooms in this table need exactly 36.
location_tbl:
  DEFB $00,$19,$03        ; Room $00 (row 0, column 0): square, magenta
  DEFB $00,$01,$0C,$FF    ; Backgrounds: arch N, arch E, walls (square room)
  DEFB $07,$10,$50,$90,$11,$51,$91,$0A ; Block x8
  DEFB $4A                             ;
  DEFB $06,$8A,$02,$42,$82,$C8,$C1,$C0 ; Block x7
  DEFB $A8,$C9            ; Block (type $5B)
; The comments give each record's room number, its square in the grid (row,
; column), its shape and colour, then what it contains. Where the listing's
; rows do not line up with the records, a comment covers the parts that begin
; in its row.

; Room $01 (row 0, column 1): narrow in y, green
room01:
  DEFB $01,$14,$14        ; Room $01 (row 0, column 1): narrow in y, green
  DEFB $01,$03,$0D,$FF    ; Backgrounds: arch E, arch W, walls (room narrow in
                          ; y)
  DEFB $03,$2B,$2C,$13,$14 ; Block x4
  DEFB $23,$6B,$6C,$53,$54 ; Gargoyle x4
  DEFB $40,$1C            ; Guard (type $96)
  DEFB $48,$28            ; Ghost

; Room $02 (row 0, column 2): square, magenta
room02:
  DEFB $02,$06,$03        ; Room $02 (row 0, column 2): square, magenta
  DEFB $00,$01,$03,$0C    ; Backgrounds: arch N, arch E, arch W, walls (square
                          ; room); no objects

; Room $03 (row 0, column 3): narrow in y, yellow
room03:
  DEFB $03,$1A,$16        ; Room $03 (row 0, column 3): narrow in y, yellow
  DEFB $01,$03,$0D,$FF    ; Backgrounds: arch E, arch W, walls (room narrow in
                          ; y)
  DEFB $03,$22,$1A,$25,$1D ; Block x4
  DEFB $2B,$23,$1B,$24,$1C ; Spikes x4
  DEFB $93,$2B,$2C,$13,$14 ; Spiked ball x4
  DEFB $B3,$63,$64,$5B,$5C ; Block (type $8F) x4

; Room $04 (row 0, column 4): square, cyan
room04:
  DEFB $04,$13,$05        ; Room $04 (row 0, column 4): square, cyan
  DEFB $00,$03,$0C,$FF    ; Backgrounds: arch N, arch W, walls (square room)
  DEFB $2B,$23,$1A,$1C,$13 ; Spikes x4
  DEFB $B2,$5A,$5C,$53    ; Block (type $8F) x3
  DEFB $02,$63,$9B,$DB    ; Block x3

; Room $08 (row 0, column 8): square, magenta
room08:
  DEFB $08,$1A,$03        ; Room $08 (row 0, column 8): square, magenta
  DEFB $04,$05,$0F,$10,$FF ; Backgrounds: forest exit N, forest exit E, forest
                           ; walls, trees closing the W gap
  DEFB $1B,$1B,$5B,$9B,$DB ; Rock x4
  DEFB $2B,$23,$1A,$1C,$13 ; Spikes x4
  DEFB $93,$63,$5A,$5C,$53 ; Spiked ball x4
  DEFB $B8,$09            ; Ball (type $B6)
  DEFB $80,$49            ; Block (type $3E)

; Room $09 (row 0, column 9): square, yellow
room09:
  DEFB $09,$0B,$06        ; Room $09 (row 0, column 9): square, yellow
  DEFB $05,$07,$0F,$11,$09,$0B,$FF ; Backgrounds: forest exit E, forest exit W,
                                   ; forest walls, trees closing the N gap,
                                   ; portcullis E, portcullis W
  DEFB $48,$23            ; Ghost

; Room $0A (row 0, column 10): square, magenta
room0A:
  DEFB $0A,$19,$03        ; Room $0A (row 0, column 10): square, magenta
  DEFB $05,$07,$0F,$11,$FF ; Backgrounds: forest exit E, forest exit W, forest
                           ; walls, trees closing the N gap
  DEFB $1D,$22,$62,$A2,$24,$64,$A4 ; Rock x6
  DEFB $2F,$2A,$2B,$6B,$2C,$1A,$1B,$5B ; Spikes x8
  DEFB $1C                             ;
  DEFB $38,$0E            ; Table

; Room $0B (row 0, column 11): square, yellow
room0B:
  DEFB $0B,$06,$06        ; Room $0B (row 0, column 11): square, yellow
  DEFB $05,$07,$0F,$11    ; Backgrounds: forest exit E, forest exit W, forest
                          ; walls, trees closing the N gap; no objects

; Room $0C (row 0, column 12): square, magenta
room0C:
  DEFB $0C,$17,$03        ; Room $0C (row 0, column 12): square, magenta
  DEFB $05,$07,$0F,$11,$FF ; Backgrounds: forest exit E, forest exit W, forest
                           ; walls, trees closing the N gap
  DEFB $2F,$3D,$32,$28,$2C,$2F,$22,$1C ; Spikes x8
  DEFB $10                             ;
  DEFB $2B,$12,$17,$0D,$04 ; Spikes x4
  DEFB $B8,$24            ; Ball (type $B6)

; Room $0D (row 0, column 13): square, green
room0D:
  DEFB $0D,$06,$04        ; Room $0D (row 0, column 13): square, green
  DEFB $00,$01,$03,$0C    ; Backgrounds: arch N, arch E, arch W, walls (square
                          ; room); no objects

; Room $0E (row 0, column 14): narrow in y, cyan
room0E:
  DEFB $0E,$0B,$15        ; Room $0E (row 0, column 14): narrow in y, cyan
  DEFB $01,$03,$0D,$FF    ; Backgrounds: arch E, arch W, walls (room narrow in
                          ; y)
  DEFB $53,$12,$1D,$2C,$23 ; Fire (type $B5) x4

; Room $0F (row 0, column 15): square, green
room0F:
  DEFB $0F,$1C,$04        ; Room $0F (row 0, column 15): square, green
  DEFB $00,$03,$0C,$FF    ; Backgrounds: arch N, arch W, walls (square room)
  DEFB $07,$23,$25,$13,$15,$63,$64,$65 ; Block x8
  DEFB $5B                             ;
  DEFB $04,$5D,$53,$54,$55,$1C ; Block x5
  DEFB $9B,$A4,$9B,$9D,$94 ; Raised spiked ball x4
  DEFB $B0,$9C            ; Block (type $8F)

; Room $10 (row 1, column 0): narrow in x, cyan
room10:
  DEFB $10,$18,$0D        ; Room $10 (row 1, column 0): narrow in x, cyan
  DEFB $00,$15,$17,$0E,$FF ; Backgrounds: arch N, high arch S, step to high
                           ; arch S, walls (room narrow in x)
  DEFB $01,$C3,$C4        ; Block x2
  DEFB $5B,$05,$0C,$0B,$0A ; Raised block x4
  DEFB $9B,$45,$4C,$4B,$4A ; Raised spiked ball x4
  DEFB $A8,$C2            ; Block (type $5B)
  DEFB $50,$5A            ; Fire (type $B5)

; Room $12 (row 1, column 2): narrow in x, green
room12:
  DEFB $12,$18,$0C        ; Room $12 (row 1, column 2): narrow in x, green
  DEFB $00,$02,$0E,$FF    ; Backgrounds: arch N, arch S, walls (room narrow in
                          ; x)
  DEFB $97,$FA,$FD,$F3,$F4,$EB,$EC,$E3 ; Spiked ball x8
  DEFB $E4                             ;
  DEFB $97,$DB,$DC,$D3,$D4,$CB,$CC,$C2 ; Spiked ball x8
  DEFB $C5                             ;

; Room $14 (row 1, column 4): narrow in x, yellow
room14:
  DEFB $14,$1A,$0E        ; Room $14 (row 1, column 4): narrow in x, yellow
  DEFB $00,$15,$17,$0E,$FF ; Backgrounds: arch N, high arch S, step to high
                           ; arch S, walls (room narrow in x)
  DEFB $01,$C3,$C4        ; Block x2
  DEFB $AD,$C2,$CA,$D2,$DA,$DB,$DC ; Block (type $5B) x6
  DEFB $AC,$DD,$E5,$AD,$75,$3D ; Block (type $5B) x5
  DEFB $29,$0B,$0C        ; Spikes x2

; Room $18 (row 1, column 8): narrow in x, cyan
room18:
  DEFB $18,$11,$0D        ; Room $18 (row 1, column 8): narrow in x, cyan
  DEFB $00,$02,$0E,$FF    ; Backgrounds: arch N, arch S, walls (room narrow in
                          ; x)
  DEFB $2F,$2A,$2B,$2C,$2D,$12,$13,$14 ; Spikes x8
  DEFB $15                             ;
  DEFB $B8,$1B            ; Ball (type $B6)

; Room $1D (row 1, column 13): narrow in x, yellow
room1D:
  DEFB $1D,$1B,$0E        ; Room $1D (row 1, column 13): narrow in x, yellow
  DEFB $00,$15,$17,$0E,$FF ; Backgrounds: arch N, high arch S, step to high
                           ; arch S, walls (room narrow in x)
  DEFB $07,$C3,$C4,$0C,$4C,$8C,$CC,$24 ; Block x8
  DEFB $64                             ;
  DEFB $02,$2C,$6C,$34    ; Block x3
  DEFB $29,$14,$1C        ; Spikes x2
  DEFB $58,$0C            ; Raised block
  DEFB $78,$54            ; Block (type $37)

; Room $1F (row 1, column 15): narrow in x, magenta
room1F:
  DEFB $1F,$17,$0B        ; Room $1F (row 1, column 15): narrow in x, magenta
  DEFB $00,$02,$0E,$FF    ; Backgrounds: arch N, arch S, walls (room narrow in
                          ; x)
  DEFB $03,$12,$15,$2A,$2D ; Block x4
  DEFB $2F,$52,$13,$14,$55,$6A,$2B,$2C ; Spikes x8
  DEFB $6D                             ;
  DEFB $E1,$93,$6B        ; Ball (half a cell along x) x2

; Room $20 (row 2, column 0): square, magenta
room20:
  DEFB $20,$12,$03        ; Room $20 (row 2, column 0): square, magenta
  DEFB $00,$01,$15,$17,$0C,$FF ; Backgrounds: arch N, arch E, high arch S, step
                               ; to high arch S, walls (square room)
  DEFB $02,$18,$C3,$C4    ; Block x3
  DEFB $AA,$50,$88,$C0    ; Block (type $5B) x3
  DEFB $28,$02            ; Spikes

; Room $21 (row 2, column 1): narrow in y, yellow
room21:
  DEFB $21,$1C,$16        ; Room $21 (row 2, column 1): narrow in y, yellow
  DEFB $14,$16,$03,$0D,$FF ; Backgrounds: high arch E, step to high arch E,
                           ; arch W, walls (room narrow in y)
  DEFB $07,$21,$61,$A2,$A3,$24,$64,$25 ; Block x8
  DEFB $65                             ;
  DEFB $03,$26,$66,$E7,$DF ; Block x4
  DEFB $29,$A4,$A6        ; Spikes x2
  DEFB $30,$E2            ; Chest
  DEFB $C0,$A5            ; Ball

; Room $22 (row 2, column 2): square, magenta
room22:
  DEFB $22,$1A,$03        ; Room $22 (row 2, column 2): square, magenta
  DEFB $02,$03,$0C,$FF    ; Backgrounds: arch S, arch W, walls (square room)
  DEFB $03,$30,$78,$B9,$FA ; Block x4
  DEFB $2F,$39,$3A,$3D,$3E,$3F,$33,$2B ; Spikes x8
  DEFB $23                             ;
  DEFB $2A,$34,$2C,$24    ; Spikes x3
  DEFB $A8,$FB            ; Block (type $5B)

; Room $24 (row 2, column 4): square, magenta
room24:
  DEFB $24,$18,$03        ; Room $24 (row 2, column 4): square, magenta
  DEFB $00,$02,$0C,$FF    ; Backgrounds: arch N, arch S, walls (square room)
  DEFB $2F,$02,$05,$0A,$0F,$10,$15,$19 ; Spikes x8
  DEFB $1B                             ;
  DEFB $2F,$1C,$1F,$28,$2A,$2C,$2E,$3A ; Spikes x8
  DEFB $3D                             ;

; Room $27 (row 2, column 7): square, yellow
room27:
  DEFB $27,$0F,$06        ; Room $27 (row 2, column 7): square, yellow
  DEFB $00,$0C,$FF        ; Backgrounds: arch N, walls (square room)
  DEFB $03,$1B,$1C,$23,$24 ; Block x4
  DEFB $4B,$12,$15,$2A,$2D ; Ghost x4

; Room $28 (row 2, column 8): narrow in x, yellow
room28:
  DEFB $28,$10,$0E        ; Room $28 (row 2, column 8): narrow in x, yellow
  DEFB $00,$15,$0E,$17,$FF ; Backgrounds: arch N, high arch S, walls (room
                           ; narrow in x), step to high arch S
  DEFB $39,$23,$63        ; Table x2
  DEFB $29,$0B,$0C        ; Spikes x2
  DEFB $01,$C3,$C4        ; Block x2

; Room $2D (row 2, column 13): square, green
room2D:
  DEFB $2D,$17,$04        ; Room $2D (row 2, column 13): square, green
  DEFB $14,$02,$16,$0C,$FF ; Backgrounds: high arch E, arch S, step to high
                           ; arch E, walls (square room)
  DEFB $07,$DF,$E7,$13,$1B,$23,$5B,$63 ; Block x8
  DEFB $A3                             ;
  DEFB $2B,$1E,$26,$22,$24 ; Spikes x4
  DEFB $70,$E3            ; Block (type $36)

; Room $2E (row 2, column 14): narrow in y, cyan
room2E:
  DEFB $2E,$11,$15        ; Room $2E (row 2, column 14): narrow in y, cyan
  DEFB $01,$03,$0D,$FF    ; Backgrounds: arch E, arch W, walls (room narrow in
                          ; y)
  DEFB $2F,$2B,$2C,$22,$25,$1A,$1D,$13 ; Spikes x8
  DEFB $14                             ;
  DEFB $68,$23            ; Guard (type $1E)

; Room $2F (row 2, column 15): square, green
room2F:
  DEFB $2F,$06,$04        ; Room $2F (row 2, column 15): square, green
  DEFB $00,$02,$03,$0C    ; Backgrounds: arch N, arch S, arch W, walls (square
                          ; room); no objects

; Room $30 (row 3, column 0): narrow in x, cyan
room30:
  DEFB $30,$16,$0D        ; Room $30 (row 3, column 0): narrow in x, cyan
  DEFB $00,$02,$0E,$FF    ; Backgrounds: arch N, arch S, walls (room narrow in
                          ; x)
  DEFB $2F,$33,$34,$2A,$2D,$22,$25,$1A ; Spikes x8
  DEFB $1D                             ;
  DEFB $2B,$12,$15,$0B,$0C ; Spikes x4
  DEFB $B8,$1B            ; Ball (type $B6)

; Room $34 (row 3, column 4): narrow in x, yellow
room34:
  DEFB $34,$18,$0E        ; Room $34 (row 3, column 4): narrow in x, yellow
  DEFB $00,$02,$0E,$FF    ; Backgrounds: arch N, arch S, walls (room narrow in
                          ; x)
  DEFB $3F,$1A,$1B,$1C,$1D,$5A,$5B,$5C ; Table x8
  DEFB $5D                             ;
  DEFB $97,$9A,$9B,$9C,$9D,$DA,$DB,$DC ; Spiked ball x8
  DEFB $DD                             ;

; Room $37 (row 3, column 7): narrow in x, cyan
room37:
  DEFB $37,$0D,$0D        ; Room $37 (row 3, column 7): narrow in x, cyan
  DEFB $00,$02,$0E,$FF    ; Backgrounds: arch N, arch S, walls (room narrow in
                          ; x)
  DEFB $78,$14            ; Block (type $37)
  DEFB $00,$2C            ; Block
  DEFB $49,$25,$1A        ; Ghost x2

; Room $38 (row 3, column 8): narrow in x, magenta
room38:
  DEFB $38,$19,$0B        ; Room $38 (row 3, column 8): narrow in x, magenta
  DEFB $00,$15,$17,$0E,$FF ; Backgrounds: arch N, high arch S, step to high
                           ; arch S, walls (room narrow in x)
  DEFB $05,$7A,$F2,$DA,$C2,$C3,$C4 ; Block x6
  DEFB $B3,$EA,$E2,$D2,$CA ; Block (type $8F) x4
  DEFB $2C,$2A,$22,$1A,$12,$0A ; Spikes x5

; Room $3F (row 3, column 15): square, magenta
room3F:
  DEFB $3F,$19,$03        ; Room $3F (row 3, column 15): square, magenta
  DEFB $04,$06,$0F,$10,$FF ; Backgrounds: forest exit N, forest exit S, forest
                           ; walls, trees closing the W gap
  DEFB $1F,$18,$19,$1A,$5A,$1D,$5D,$1E ; Rock x8
  DEFB $1F                             ;
  DEFB $2D,$58,$59,$9A,$9D,$5E,$5F ; Spikes x6
  DEFB $D0,$1B            ; Portcullis along x

; Room $40 (row 4, column 0): square, yellow
room40:
  DEFB $40,$13,$06        ; Room $40 (row 4, column 0): square, yellow
  DEFB $14,$15,$16,$17,$0C,$FF ; Backgrounds: high arch E, high arch S, step to
                               ; high arch E, step to high arch S, walls
                               ; (square room)
  DEFB $05,$3F,$06,$C3,$C4,$DF,$E7 ; Block x6
  DEFB $68,$38            ; Guard (type $1E)
  DEFB $80,$B8            ; Block (type $3E)

; Room $41 (row 4, column 1): narrow in y, green
room41:
  DEFB $41,$17,$14        ; Room $41 (row 4, column 1): narrow in y, green
  DEFB $01,$03,$0D,$FF    ; Backgrounds: arch E, arch W, walls (room narrow in
                          ; y)
  DEFB $05,$12,$14,$16,$2A,$2C,$2E ; Block x6
  DEFB $25,$52,$54,$56,$6A,$6C,$6E ; Gargoyle x6
  DEFB $51,$15,$2B        ; Fire (type $B5) x2

; Room $42 (row 4, column 2): square, cyan
room42:
  DEFB $42,$15,$05        ; Room $42 (row 4, column 2): square, cyan
  DEFB $01,$03,$0C,$FF    ; Backgrounds: arch E, arch W, walls (square room)
  DEFB $01,$1B,$DC        ; Block x2
  DEFB $A9,$63,$A4        ; Block (type $5B) x2
  DEFB $2F,$12,$1A,$22,$2B,$2C,$25,$1D ; Spikes x8
  DEFB $14                             ;

; Room $43 (row 4, column 3): narrow in y, yellow
room43:
  DEFB $43,$1B,$16        ; Room $43 (row 4, column 3): narrow in y, yellow
  DEFB $01,$03,$0D,$FF    ; Backgrounds: arch E, arch W, walls (room narrow in
                          ; y)
  DEFB $07,$1E,$26,$5D,$65,$19,$21,$5A ; Block x8
  DEFB $62                             ;
  DEFB $03,$2B,$2C,$13,$14 ; Block x4
  DEFB $2B,$6B,$6C,$53,$54 ; Spikes x4
  DEFB $60,$1B            ; Ball (half a cell along x and y)

; Room $44 (row 4, column 4): square, green
room44:
  DEFB $44,$07,$04        ; Room $44 (row 4, column 4): square, green
  DEFB $00,$01,$02,$03,$0C ; Backgrounds: arch N, arch E, arch S, arch W, walls
                           ; (square room); no objects

; Room $45 (row 4, column 5): square, cyan
room45:
  DEFB $45,$1D,$05        ; Room $45 (row 4, column 5): square, cyan
  DEFB $01,$03,$0C,$FF    ; Backgrounds: arch E, arch W, walls (square room)
  DEFB $07,$23,$25,$13,$15,$63,$64,$65 ; Block x8
  DEFB $5B                             ;
  DEFB $03,$5D,$53,$54,$55 ; Block x4
  DEFB $9B,$A4,$9B,$9D,$94 ; Raised spiked ball x4
  DEFB $B0,$9C            ; Block (type $8F)
  DEFB $28,$1C            ; Spikes

; Room $46 (row 4, column 6): narrow in y, yellow
room46:
  DEFB $46,$1C,$16        ; Room $46 (row 4, column 6): narrow in y, yellow
  DEFB $01,$03,$0D,$FF    ; Backgrounds: arch E, arch W, walls (room narrow in
                          ; y)
  DEFB $07,$23,$1B,$2C,$6C,$14,$54,$25 ; Block x8
  DEFB $1D                             ;
  DEFB $23,$65,$5D,$63,$5B ; Gargoyle x4
  DEFB $91,$24,$1C        ; Spiked ball x2
  DEFB $B3,$A4,$E4,$9C,$DC ; Block (type $8F) x4

; Room $47 (row 4, column 7): square, magenta
room47:
  DEFB $47,$06,$03        ; Room $47 (row 4, column 7): square, magenta
  DEFB $00,$02,$03,$0C    ; Backgrounds: arch N, arch S, arch W, walls (square
                          ; room); no objects

; Room $48 (row 4, column 8): narrow in x, yellow
room48:
  DEFB $48,$17,$0E        ; Room $48 (row 4, column 8): narrow in x, yellow
  DEFB $00,$15,$17,$0E,$FF ; Backgrounds: arch N, high arch S, step to high
                           ; arch S, walls (room narrow in x)
  DEFB $07,$C3,$C4,$CC,$2C,$2D,$25,$6C ; Block x8
  DEFB $6D                             ;
  DEFB $00,$AC            ; Block
  DEFB $29,$0B,$14        ; Spikes x2
  DEFB $78,$8C            ; Block (type $37)

; Room $4F (row 4, column 15): square, yellow
room4F:
  DEFB $4F,$15,$06        ; Room $4F (row 4, column 15): square, yellow
  DEFB $04,$06,$0F,$10,$FF ; Backgrounds: forest exit N, forest exit S, forest
                           ; walls, trees closing the W gap
  DEFB $9F,$D8,$D9,$DA,$DB,$DC,$DD,$DE ; Raised spiked ball x8
  DEFB $DF                             ;
  DEFB $9B,$C3,$C4,$FB,$FC ; Raised spiked ball x4

; Room $54 (row 5, column 4): narrow in x, cyan
room54:
  DEFB $54,$16,$0D        ; Room $54 (row 5, column 4): narrow in x, cyan
  DEFB $00,$02,$0E,$FF    ; Backgrounds: arch N, arch S, walls (room narrow in
                          ; x)
  DEFB $01,$0C,$33        ; Block x2
  DEFB $2B,$1A,$5A,$25,$65 ; Spikes x4
  DEFB $93,$13,$0B,$2C,$24 ; Spiked ball x4
  DEFB $79,$14,$23        ; Block (type $37) x2

; Room $57 (row 5, column 7): narrow in x, cyan
room57:
  DEFB $57,$14,$0D        ; Room $57 (row 5, column 7): narrow in x, cyan
  DEFB $00,$02,$0E,$FF    ; Backgrounds: arch N, arch S, walls (room narrow in
                          ; x)
  DEFB $07,$2D,$6D,$AD,$24,$64,$A4,$1B ; Block x8
  DEFB $5B                             ;
  DEFB $03,$9B,$12,$52,$92 ; Block x4

; Room $58 (row 5, column 8): narrow in x, cyan
room58:
  DEFB $58,$0B,$0D        ; Room $58 (row 5, column 8): narrow in x, cyan
  DEFB $00,$15,$17,$0E,$FF ; Backgrounds: arch N, high arch S, step to high
                           ; arch S, walls (room narrow in x)
  DEFB $48,$1D            ; Ghost
  DEFB $80,$5D            ; Block (type $3E)

; Room $5E (row 5, column 14): square, yellow
room5E:
  DEFB $5E,$12,$06        ; Room $5E (row 5, column 14): square, yellow
  DEFB $04,$05,$0F,$10,$FF ; Backgrounds: forest exit N, forest exit E, forest
                           ; walls, trees closing the W gap
  DEFB $1F,$32,$35,$29,$2E,$11,$16,$0A ; Rock x8
  DEFB $0D                             ;
  DEFB $C8,$2D            ; Sparkle (type $A4)

; Room $5F (row 5, column 15): square, magenta
room5F:
  DEFB $5F,$06,$03        ; Room $5F (row 5, column 15): square, magenta
  DEFB $04,$06,$07,$0F    ; Backgrounds: forest exit N, forest exit S, forest
                          ; exit W, forest walls; no objects

; Room $64 (row 6, column 4): narrow in x, yellow
room64:
  DEFB $64,$12,$0E        ; Room $64 (row 6, column 4): narrow in x, yellow
  DEFB $00,$15,$17,$0E,$FF ; Backgrounds: arch N, high arch S, step to high
                           ; arch S, walls (room narrow in x)
  DEFB $07,$03,$04,$0B,$0C,$23,$24,$2B ; Block x8
  DEFB $2C                             ;
  DEFB $30,$63            ; Chest

; Room $67 (row 6, column 7): narrow in x, green
room67:
  DEFB $67,$12,$0C        ; Room $67 (row 6, column 7): narrow in x, green
  DEFB $00,$02,$0E,$FF    ; Backgrounds: arch N, arch S, walls (room narrow in
                          ; x)
  DEFB $01,$2A,$2D        ; Block x2
  DEFB $2B,$6A,$6D,$1A,$1D ; Spikes x4
  DEFB $D0,$2B            ; Portcullis along x
  DEFB $68,$25            ; Guard (type $1E)

; Room $68 (row 6, column 8): narrow in x, magenta
room68:
  DEFB $68,$19,$0B        ; Room $68 (row 6, column 8): narrow in x, magenta
  DEFB $00,$02,$0E,$FF    ; Backgrounds: arch N, arch S, walls (room narrow in
                          ; x)
  DEFB $07,$3A,$7A,$BA,$FA,$3D,$7D,$BD ; Block x8
  DEFB $FD                             ;
  DEFB $03,$32,$33,$34,$35 ; Block x4
  DEFB $29,$72,$75        ; Spikes x2
  DEFB $60,$A3            ; Ball (half a cell along x and y)

; Room $6A (row 6, column 10): square, yellow
room6A:
  DEFB $6A,$05,$06        ; Room $6A (row 6, column 10): square, yellow
  DEFB $00,$01,$0C        ; Backgrounds: arch N, arch E, walls (square room);
                          ; no objects

; Room $6B (row 6, column 11): narrow in y, green
room6B:
  DEFB $6B,$11,$14        ; Room $6B (row 6, column 11): narrow in y, green
  DEFB $14,$03,$16,$0D,$FF ; Backgrounds: high arch E, arch W, step to high
                           ; arch E, walls (room narrow in y)
  DEFB $05,$24,$1C,$64,$5C,$E7,$DF ; Block x6
  DEFB $51,$D6,$ED        ; Fire (type $B5) x2

; Room $6C (row 6, column 12): narrow in y, magenta
room6C:
  DEFB $6C,$18,$13        ; Room $6C (row 6, column 12): narrow in y, magenta
  DEFB $01,$03,$0D,$FF    ; Backgrounds: arch E, arch W, walls (room narrow in
                          ; y)
  DEFB $37,$2B,$23,$1B,$13,$6B,$63,$5B ; Chest x8
  DEFB $53                             ;
  DEFB $9F,$AB,$A3,$9B,$93,$EB,$E3,$DB ; Raised spiked ball x8
  DEFB $D3                             ;

; Room $6D (row 6, column 13): square, yellow
room6D:
  DEFB $6D,$17,$06        ; Room $6D (row 6, column 13): square, yellow
  DEFB $05,$07,$0F,$11,$FF ; Backgrounds: forest exit E, forest exit W, forest
                           ; walls, trees closing the N gap
  DEFB $1F,$14,$2C,$54,$6C,$94,$9C,$A4 ; Rock x8
  DEFB $AC                             ;
  DEFB $21,$D4,$EC        ; Gargoyle x2
  DEFB $38,$09            ; Table
  DEFB $40,$1E            ; Guard (type $96)

; Room $6E (row 6, column 14): square, magenta
room6E:
  DEFB $6E,$07,$03        ; Room $6E (row 6, column 14): square, magenta
  DEFB $05,$06,$07,$0F,$11 ; Backgrounds: forest exit E, forest exit S, forest
                           ; exit W, forest walls, trees closing the N gap; no
                           ; objects

; Room $6F (row 6, column 15): square, yellow
room6F:
  DEFB $6F,$14,$06        ; Room $6F (row 6, column 15): square, yellow
  DEFB $06,$07,$0F,$11,$FF ; Backgrounds: forest exit S, forest exit W, forest
                           ; walls, trees closing the N gap
  DEFB $1A,$2D,$2E,$2F    ; Rock x3
  DEFB $22,$6D,$6E,$6F    ; Gargoyle x3
  DEFB $9B,$3D,$35,$7D,$75 ; Raised spiked ball x4

; Room $74 (row 7, column 4): square, green
room74:
  DEFB $74,$18,$04        ; Room $74 (row 7, column 4): square, green
  DEFB $01,$02,$0C,$FF    ; Backgrounds: arch E, arch S, walls (square room)
  DEFB $2A,$39,$30,$31    ; Spikes x3
  DEFB $07,$3A,$7A,$32,$72,$28,$68,$29 ; Block x8
  DEFB $69                             ;
  DEFB $B3,$B8,$B9,$B0,$B1 ; Block (type $8F) x4

; Room $75 (row 7, column 5): narrow in y, magenta
room75:
  DEFB $75,$0E,$13        ; Room $75 (row 7, column 5): narrow in y, magenta
  DEFB $01,$03,$0D,$FF    ; Backgrounds: arch E, arch W, walls (room narrow in
                          ; y)
  DEFB $01,$23,$1C        ; Block x2
  DEFB $29,$24,$1B        ; Spikes x2
  DEFB $C8,$2B            ; Sparkle (type $A4)

; Room $76 (row 7, column 6): narrow in y, yellow
room76:
  DEFB $76,$16,$16        ; Room $76 (row 7, column 6): narrow in y, yellow
  DEFB $14,$03,$16,$0D,$FF ; Backgrounds: high arch E, arch W, step to high
                           ; arch E, walls (room narrow in y)
  DEFB $06,$DF,$E7,$EF,$AE,$6D,$2C,$D7 ; Block x7
  DEFB $2D,$16,$1E,$26,$15,$1D,$25 ; Spikes x6

; Room $77 (row 7, column 7): square, magenta
room77:
  DEFB $77,$07,$03        ; Room $77 (row 7, column 7): square, magenta
  DEFB $00,$01,$02,$03,$0C ; Backgrounds: arch N, arch E, arch S, arch W, walls
                           ; (square room); no objects

; Room $78 (row 7, column 8): square, green
room78:
  DEFB $78,$19,$04        ; Room $78 (row 7, column 8): square, green
  DEFB $00,$01,$02,$03,$0C,$FF ; Backgrounds: arch N, arch E, arch S, arch W,
                               ; walls (square room)
  DEFB $2F,$39,$3F,$35,$28,$2C,$2F,$23 ; Spikes x8
  DEFB $1D                             ;
  DEFB $2C,$11,$13,$0A,$0D,$0E ; Spikes x5
  DEFB $68,$17            ; Guard (type $1E)

; Room $79 (row 7, column 9): narrow in y, magenta
room79:
  DEFB $79,$16,$13        ; Room $79 (row 7, column 9): narrow in y, magenta
  DEFB $01,$03,$0D,$FF    ; Backgrounds: arch E, arch W, walls (room narrow in
                          ; y)
  DEFB $B3,$22,$1A,$25,$1D ; Block (type $8F) x4
  DEFB $2F,$2B,$2C,$23,$24,$1B,$1C,$13 ; Spikes x8
  DEFB $14                             ;
  DEFB $60,$DB            ; Ball (half a cell along x and y)

; Room $7A (row 7, column 10): square, cyan
room7A:
  DEFB $7A,$16,$05        ; Room $7A (row 7, column 10): square, cyan
  DEFB $02,$03,$0C,$FF    ; Backgrounds: arch S, arch W, walls (square room)
  DEFB $04,$28,$70,$B8,$B9,$FF ; Block x5
  DEFB $2D,$BA,$BC,$BE,$37,$2F,$27 ; Spikes x6
  DEFB $A9,$FB,$FD        ; Block (type $5B) x2

; Room $83 (row 8, column 3): square, yellow
room83:
  DEFB $83,$05,$06        ; Room $83 (row 8, column 3): square, yellow
  DEFB $00,$01,$0C        ; Backgrounds: arch N, arch E, walls (square room);
                          ; no objects

; Room $84 (row 8, column 4): narrow in y, cyan
room84:
  DEFB $84,$17,$15        ; Room $84 (row 8, column 4): narrow in y, cyan
  DEFB $01,$03,$0D,$FF    ; Backgrounds: arch E, arch W, walls (room narrow in
                          ; y)
  DEFB $07,$2A,$6A,$2D,$6D,$12,$52,$15 ; Block x8
  DEFB $55                             ;
  DEFB $23,$AA,$AD,$92,$95 ; Gargoyle x4
  DEFB $11,$1D,$9A        ; Ball (half a cell along y) x2

; Room $85 (row 8, column 5): narrow in y, green
room85:
  DEFB $85,$19,$14        ; Room $85 (row 8, column 5): narrow in y, green
  DEFB $14,$03,$16,$0D,$FF ; Backgrounds: high arch E, arch W, step to high
                           ; arch E, walls (room narrow in y)
  DEFB $05,$28,$69,$AA,$EB,$E7,$DF ; Block x6
  DEFB $2F,$1B,$23,$1C,$24,$1D,$25,$1E ; Spikes x8
  DEFB $26                             ;
  DEFB $78,$DB            ; Block (type $37)

; Room $86 (row 8, column 6): narrow in y, magenta
room86:
  DEFB $86,$0B,$13        ; Room $86 (row 8, column 6): narrow in y, magenta
  DEFB $14,$03,$16,$0D,$FF ; Backgrounds: high arch E, arch W, step to high
                           ; arch E, walls (room narrow in y)
  DEFB $80,$63            ; Block (type $3E)
  DEFB $B8,$23            ; Ball (type $B6)

; Room $87 (row 8, column 7): square, cyan
room87:
  DEFB $87,$18,$05        ; Room $87 (row 8, column 7): square, cyan
  DEFB $00,$01,$02,$03,$0C,$FF ; Backgrounds: arch N, arch E, arch S, arch W,
                               ; walls (square room)
  DEFB $03,$2A,$2D,$12,$15 ; Block x4
  DEFB $2B,$6A,$6D,$52,$55 ; Spikes x4
  DEFB $D1,$2B,$13        ; Portcullis along x x2
  DEFB $D9,$1A,$1D        ; Portcullis along y x2

; Room $88 (row 8, column 8): square, yellow
room88:
  DEFB $88,$13,$06        ; Room $88 (row 8, column 8): square, yellow
  DEFB $00,$01,$02,$03,$12,$13,$0C,$FF ; Backgrounds: arch N, arch E, arch S,
                                       ; arch W, the wizard, the cauldron,
                                       ; walls (square room)
  DEFB $07,$32,$29,$35,$2E,$16,$0D,$11 ; Block x8
  DEFB $0A                             ;

; Room $89 (row 8, column 9): narrow in y, cyan
room89:
  DEFB $89,$14,$15        ; Room $89 (row 8, column 9): narrow in y, cyan
  DEFB $01,$03,$0D,$FF    ; Backgrounds: arch E, arch W, walls (room narrow in
                          ; y)
  DEFB $07,$2C,$6C,$AC,$24,$1C,$14,$54 ; Block x8
  DEFB $94                             ;
  DEFB $21,$EC,$D4        ; Gargoyle x2
  DEFB $50,$64            ; Fire (type $B5)

; Room $8A (row 8, column 10): narrow in y, magenta
room8A:
  DEFB $8A,$18,$13        ; Room $8A (row 8, column 10): narrow in y, magenta
  DEFB $01,$03,$0D,$FF    ; Backgrounds: arch E, arch W, walls (room narrow in
                          ; y)
  DEFB $5F,$2A,$22,$1A,$12,$2D,$25,$1D ; Raised block x8
  DEFB $15                             ;
  DEFB $97,$EA,$E2,$DA,$D2,$ED,$E5,$DD ; Spiked ball x8
  DEFB $D5                             ;

; Room $8B (row 8, column 11): square, cyan
room8B:
  DEFB $8B,$06,$05        ; Room $8B (row 8, column 11): square, cyan
  DEFB $00,$01,$03,$0C    ; Backgrounds: arch N, arch E, arch W, walls (square
                          ; room); no objects

; Room $8C (row 8, column 12): narrow in y, green
room8C:
  DEFB $8C,$19,$14        ; Room $8C (row 8, column 12): narrow in y, green
  DEFB $01,$03,$0D,$FF    ; Backgrounds: arch E, arch W, walls (room narrow in
                          ; y)
  DEFB $07,$2A,$6A,$2D,$6D,$12,$52,$15 ; Block x8
  DEFB $55                             ;
  DEFB $2B,$AA,$AD,$92,$95 ; Spikes x4
  DEFB $D9,$1A,$1D        ; Portcullis along y x2
  DEFB $40,$1B            ; Guard (type $96)

; Room $8D (row 8, column 13): square, cyan
room8D:
  DEFB $8D,$1A,$05        ; Room $8D (row 8, column 13): square, cyan
  DEFB $01,$03,$0C,$FF    ; Backgrounds: arch E, arch W, walls (square room)
  DEFB $07,$34,$74,$6C,$B4,$BC,$FB,$FD ; Block x8
  DEFB $F3                             ;
  DEFB $03,$FC,$F5,$EB,$ED ; Block x4
  DEFB $58,$3C            ; Raised block
  DEFB $28,$24            ; Spikes
  DEFB $10,$E4            ; Ball (half a cell along y)

; Room $8E (row 8, column 14): narrow in y, magenta
room8E:
  DEFB $8E,$0C,$13        ; Room $8E (row 8, column 14): narrow in y, magenta
  DEFB $14,$03,$16,$0D,$FF ; Backgrounds: high arch E, arch W, step to high
                           ; arch E, walls (room narrow in y)
  DEFB $39,$23,$63        ; Table x2
  DEFB $48,$2B            ; Ghost

; Room $8F (row 8, column 15): square, yellow
room8F:
  DEFB $8F,$05,$06        ; Room $8F (row 8, column 15): square, yellow
  DEFB $00,$03,$0C        ; Backgrounds: arch N, arch W, walls (square room);
                          ; no objects

; Room $93 (row 9, column 3): narrow in x, green
room93:
  DEFB $93,$14,$0C        ; Room $93 (row 9, column 3): narrow in x, green
  DEFB $00,$02,$0E,$FF    ; Backgrounds: arch N, arch S, walls (room narrow in
                          ; x)
  DEFB $07,$1A,$1B,$1C,$1D,$5A,$9A,$5D ; Block x8
  DEFB $9D                             ;
  DEFB $21,$DA,$DD        ; Gargoyle x2
  DEFB $A0,$5B            ; Fire (type $56)

; Room $97 (row 9, column 7): narrow in x, green
room97:
  DEFB $97,$10,$0C        ; Room $97 (row 9, column 7): narrow in x, green
  DEFB $00,$02,$0E,$FF    ; Backgrounds: arch N, arch S, walls (room narrow in
                          ; x)
  DEFB $03,$1A,$1B,$1C,$1D ; Block x4
  DEFB $23,$5A,$5B,$5C,$5D ; Gargoyle x4

; Room $98 (row 9, column 8): narrow in x, magenta
room98:
  DEFB $98,$1A,$0B        ; Room $98 (row 9, column 8): narrow in x, magenta
  DEFB $00,$02,$0E,$FF    ; Backgrounds: arch N, arch S, walls (room narrow in
                          ; x)
  DEFB $01,$33,$0C        ; Block x2
  DEFB $A9,$6B,$54        ; Block (type $5B) x2
  DEFB $2F,$22,$23,$24,$25,$1A,$1B,$1C ; Spikes x8
  DEFB $1D                             ;
  DEFB $B3,$A3,$A4,$9B,$9C ; Block (type $8F) x4

; Room $9B (row 9, column 11): narrow in x, magenta
room9B:
  DEFB $9B,$17,$0B        ; Room $9B (row 9, column 11): narrow in x, magenta
  DEFB $00,$15,$17,$0E,$FF ; Backgrounds: arch N, high arch S, step to high
                           ; arch S, walls (room narrow in x)
  DEFB $07,$3D,$7D,$35,$75,$B5,$F5,$C3 ; Block x8
  DEFB $C4                             ;
  DEFB $78,$DD            ; Block (type $37)
  DEFB $70,$DB            ; Block (type $36)
  DEFB $29,$1C,$1D        ; Spikes x2

; Room $9F (row 9, column 15): narrow in x, cyan
room9F:
  DEFB $9F,$18,$0D        ; Room $9F (row 9, column 15): narrow in x, cyan
  DEFB $00,$02,$0E,$FF    ; Backgrounds: arch N, arch S, walls (room narrow in
                          ; x)
  DEFB $07,$1A,$1B,$1C,$1D,$5A,$5B,$5C ; Block x8
  DEFB $5D                             ;
  DEFB $03,$9A,$9B,$9C,$9D ; Block x4
  DEFB $2A,$DB,$DC,$DD    ; Spikes x3

; Room $A3 (row 10, column 3): narrow in x, magenta
roomA3:
  DEFB $A3,$1C,$0B        ; Room $A3 (row 10, column 3): narrow in x, magenta
  DEFB $00,$15,$17,$0E,$FF ; Backgrounds: arch N, high arch S, step to high
                           ; arch S, walls (room narrow in x)
  DEFB $05,$3D,$7D,$34,$74,$C3,$C4 ; Block x6
  DEFB $2B,$12,$14,$23,$25 ; Spikes x4
  DEFB $93,$52,$54,$63,$65 ; Spiked ball x4
  DEFB $B8,$35            ; Ball (type $B6)
  DEFB $80,$75            ; Block (type $3E)

; Room $A7 (row 10, column 7): square, magenta
roomA7:
  DEFB $A7,$05,$03        ; Room $A7 (row 10, column 7): square, magenta
  DEFB $00,$02,$0C        ; Backgrounds: arch N, arch S, walls (square room);
                          ; no objects

; Room $A8 (row 10, column 8): square, yellow
roomA8:
  DEFB $A8,$18,$06        ; Room $A8 (row 10, column 8): square, yellow
  DEFB $02,$0C,$FF        ; Backgrounds: arch S, walls (square room)
  DEFB $07,$2A,$6A,$32,$72,$B2,$F2,$36 ; Block x8
  DEFB $76                             ;
  DEFB $05,$B6,$F6,$16,$56,$96,$D6 ; Block x6
  DEFB $29,$35,$1E        ; Spikes x2

; Room $AA (row 10, column 10): square, magenta
roomAA:
  DEFB $AA,$18,$03        ; Room $AA (row 10, column 10): square, magenta
  DEFB $00,$01,$0C,$FF    ; Backgrounds: arch N, arch E, walls (square room)
  DEFB $07,$00,$48,$90,$18,$58,$98,$D8 ; Block x8
  DEFB $21                             ;
  DEFB $02,$61,$28,$68    ; Block x3
  DEFB $29,$A8,$A1        ; Spikes x2
  DEFB $A8,$E0            ; Block (type $5B)

; Room $AB (row 10, column 11): square, green
roomAB:
  DEFB $AB,$06,$04        ; Room $AB (row 10, column 11): square, green
  DEFB $00,$02,$03,$0C    ; Backgrounds: arch N, arch S, arch W, walls (square
                          ; room); no objects

; Room $AF (row 10, column 15): narrow in x, green
roomAF:
  DEFB $AF,$0E,$0C        ; Room $AF (row 10, column 15): narrow in x, green
  DEFB $00,$15,$17,$0E,$FF ; Backgrounds: arch N, high arch S, step to high
                           ; arch S, walls (room narrow in x)
  DEFB $03,$1B,$1C,$33,$34 ; Block x4
  DEFB $30,$74            ; Chest

; Room $B3 (row 11, column 3): square, yellow
roomB3:
  DEFB $B3,$06,$06        ; Room $B3 (row 11, column 3): square, yellow
  DEFB $00,$01,$02,$0C    ; Backgrounds: arch N, arch E, arch S, walls (square
                          ; room); no objects

; Room $B4 (row 11, column 4): square, green
roomB4:
  DEFB $B4,$13,$04        ; Room $B4 (row 11, column 4): square, green
  DEFB $03,$0C,$FF        ; Backgrounds: arch W, walls (square room)
  DEFB $07,$13,$14,$15,$1B,$23,$63,$A3 ; Block x8
  DEFB $E3                             ;
  DEFB $30,$55            ; Chest
  DEFB $39,$2E,$6E        ; Table x2

; Room $B7 (row 11, column 7): narrow in x, green
roomB7:
  DEFB $B7,$0E,$0C        ; Room $B7 (row 11, column 7): narrow in x, green
  DEFB $00,$02,$0E,$FF    ; Backgrounds: arch N, arch S, walls (room narrow in
                          ; x)
  DEFB $03,$33,$34,$0B,$0C ; Block x4
  DEFB $49,$23,$1C        ; Ghost x2

; Room $BA (row 11, column 10): square, cyan
roomBA:
  DEFB $BA,$19,$05        ; Room $BA (row 11, column 10): square, cyan
  DEFB $01,$02,$0C,$FF    ; Backgrounds: arch E, arch S, walls (square room)
  DEFB $05,$2B,$6B,$AB,$1B,$5B,$9B ; Block x6
  DEFB $2F,$2A,$22,$62,$A2,$1A,$2C,$24 ; Spikes x8
  DEFB $64                             ;
  DEFB $29,$A4,$1C        ; Spikes x2

; Room $BB (row 11, column 11): square, yellow
roomBB:
  DEFB $BB,$0B,$06        ; Room $BB (row 11, column 11): square, yellow
  DEFB $02,$03,$0C,$FF    ; Backgrounds: arch S, arch W, walls (square room)
  DEFB $48,$24            ; Ghost
  DEFB $81,$64,$A4        ; Block (type $3E) x2

; Room $BF (row 11, column 15): square, magenta
roomBF:
  DEFB $BF,$1D,$03        ; Room $BF (row 11, column 15): square, magenta
  DEFB $00,$15,$17,$0C,$FF ; Backgrounds: arch N, high arch S, step to high
                           ; arch S, walls (square room)
  DEFB $04,$3D,$7E,$BE,$C3,$C4 ; Block x5
  DEFB $2F,$3F,$37,$2F,$2E,$2D,$25,$1D ; Spikes x8
  DEFB $15                             ;
  DEFB $29,$14,$0C        ; Spikes x2
  DEFB $B8,$7F            ; Ball (type $B6)
  DEFB $80,$BF            ; Block (type $3E)

; Room $C3 (row 12, column 3): narrow in x, magenta
roomC3:
  DEFB $C3,$14,$0B        ; Room $C3 (row 12, column 3): narrow in x, magenta
  DEFB $00,$02,$0E,$FF    ; Backgrounds: arch N, arch S, walls (room narrow in
                          ; x)
  DEFB $07,$1A,$1B,$1C,$1D,$5A,$5B,$5C ; Block x8
  DEFB $5D                             ;
  DEFB $03,$9A,$9B,$9C,$9D ; Block x4

; Room $C7 (row 12, column 7): square, cyan
roomC7:
  DEFB $C7,$0B,$05        ; Room $C7 (row 12, column 7): square, cyan
  DEFB $00,$15,$17,$0C,$FF ; Backgrounds: arch N, high arch S, step to high
                           ; arch S, walls (square room)
  DEFB $80,$5B            ; Block (type $3E)
  DEFB $48,$1B            ; Ghost

; Room $CF (row 12, column 15): narrow in x, green
roomCF:
  DEFB $CF,$0A,$0C        ; Room $CF (row 12, column 15): narrow in x, green
  DEFB $00,$02,$08,$0A,$0E,$FF ; Backgrounds: arch N, arch S, portcullis N,
                               ; portcullis S, walls (room narrow in x)
  DEFB $48,$1C            ; Ghost

; Room $D0 (row 13, column 0): square, cyan
roomD0:
  DEFB $D0,$19,$05        ; Room $D0 (row 13, column 0): square, cyan
  DEFB $00,$01,$0C,$FF    ; Backgrounds: arch N, arch E, walls (square room)
  DEFB $07,$03,$42,$81,$C0,$C8,$D0,$D8 ; Block x8
  DEFB $E0                             ;
  DEFB $03,$1C,$5C,$9C,$DC ; Block x4
  DEFB $2B,$1B,$24,$1D,$14 ; Spikes x4

; Room $D1 (row 13, column 1): narrow in y, green
roomD1:
  DEFB $D1,$11,$14        ; Room $D1 (row 13, column 1): narrow in y, green
  DEFB $01,$03,$0D,$FF    ; Backgrounds: arch E, arch W, walls (room narrow in
                          ; y)
  DEFB $68,$16            ; Guard (type $1E)
  DEFB $2F,$1E,$26,$1B,$1C,$23,$24,$19 ; Spikes x8
  DEFB $21                             ;

; Room $D2 (row 13, column 2): square, cyan
roomD2:
  DEFB $D2,$15,$05        ; Room $D2 (row 13, column 2): square, cyan
  DEFB $00,$03,$0C,$FF    ; Backgrounds: arch N, arch W, walls (square room)
  DEFB $07,$03,$27,$44,$5F,$85,$97,$C6 ; Block x8
  DEFB $CF                             ;
  DEFB $01,$CE,$C7        ; Block x2
  DEFB $99,$0F,$06        ; Raised spiked ball x2

; Room $D3 (row 13, column 3): narrow in x, cyan
roomD3:
  DEFB $D3,$12,$0D        ; Room $D3 (row 13, column 3): narrow in x, cyan
  DEFB $00,$02,$0E,$FF    ; Backgrounds: arch N, arch S, walls (room narrow in
                          ; x)
  DEFB $01,$2A,$2D        ; Block x2
  DEFB $2B,$6A,$6D,$1A,$1D ; Spikes x4
  DEFB $D0,$2B            ; Portcullis along x
  DEFB $68,$25            ; Guard (type $1E)

; Room $D6 (row 13, column 6): square, yellow
roomD6:
  DEFB $D6,$15,$06        ; Room $D6 (row 13, column 6): square, yellow
  DEFB $04,$05,$0F,$10,$FF ; Backgrounds: forest exit N, forest exit E, forest
                           ; walls, trees closing the W gap
  DEFB $1F,$2C,$6C,$AC,$EC,$24,$1C,$14 ; Rock x8
  DEFB $54                             ;
  DEFB $18,$94            ; Rock
  DEFB $11,$5D,$1B        ; Ball (half a cell along y) x2

; Room $D7 (row 13, column 7): square, magenta
roomD7:
  DEFB $D7,$0E,$03        ; Room $D7 (row 13, column 7): square, magenta
  DEFB $04,$05,$06,$07,$0F,$FF ; Backgrounds: forest exit N, forest exit E,
                               ; forest exit S, forest exit W, forest walls
  DEFB $51,$1B,$24        ; Fire (type $B5) x2
  DEFB $A1,$23,$1C        ; Fire (type $56) x2

; Room $D8 (row 13, column 8): square, magenta
roomD8:
  DEFB $D8,$06,$03        ; Room $D8 (row 13, column 8): square, magenta
  DEFB $04,$05,$07,$0F    ; Backgrounds: forest exit N, forest exit E, forest
                          ; exit W, forest walls; no objects

; Room $D9 (row 13, column 9): square, yellow
roomD9:
  DEFB $D9,$05,$06        ; Room $D9 (row 13, column 9): square, yellow
  DEFB $04,$07,$0F        ; Backgrounds: forest exit N, forest exit W, forest
                          ; walls; no objects

; Room $DD (row 13, column 13): square, yellow
roomDD:
  DEFB $DD,$14,$06        ; Room $DD (row 13, column 13): square, yellow
  DEFB $00,$14,$16,$0C,$FF ; Backgrounds: arch N, high arch E, step to high
                           ; arch E, walls (square room)
  DEFB $01,$E7,$DF        ; Block x2
  DEFB $5B,$2F,$26,$1E,$17 ; Raised block x4
  DEFB $3B,$1A,$5A,$9A,$DA ; Table x4

; Room $DE (row 13, column 14): narrow in y, magenta
roomDE:
  DEFB $DE,$05,$13        ; Room $DE (row 13, column 14): narrow in y, magenta
  DEFB $01,$03,$0D        ; Backgrounds: arch E, arch W, walls (room narrow in
                          ; y); no objects

; Room $DF (row 13, column 15): square, yellow
roomDF:
  DEFB $DF,$16,$06        ; Room $DF (row 13, column 15): square, yellow
  DEFB $00,$02,$03,$0C,$FF ; Backgrounds: arch N, arch S, arch W, walls (square
                           ; room)
  DEFB $04,$1B,$5B,$9B,$DB,$E2 ; Block x5
  DEFB $2B,$13,$1C,$23,$1A ; Spikes x4
  DEFB $B2,$12,$54,$A4    ; Block (type $8F) x3

; Room $E0 (row 14, column 0): narrow in x, yellow
roomE0:
  DEFB $E0,$11,$0E        ; Room $E0 (row 14, column 0): narrow in x, yellow
  DEFB $00,$02,$0E,$FF    ; Backgrounds: arch N, arch S, walls (room narrow in
                          ; x)
  DEFB $2F,$3A,$3D,$2B,$2C,$13,$14,$02 ; Spikes x8
  DEFB $05                             ;
  DEFB $C8,$24            ; Sparkle (type $A4)

; Room $E2 (row 14, column 2): narrow in x, yellow
roomE2:
  DEFB $E2,$16,$0E        ; Room $E2 (row 14, column 2): narrow in x, yellow
  DEFB $00,$02,$0E,$FF    ; Backgrounds: arch N, arch S, walls (room narrow in
                          ; x)
  DEFB $97,$05,$0A,$0C,$13,$15,$1A,$1C ; Spiked ball x8
  DEFB $23                             ;
  DEFB $95,$25,$2A,$2C,$33,$35,$3A ; Spiked ball x6

; Room $E3 (row 14, column 3): narrow in x, yellow
roomE3:
  DEFB $E3,$1B,$0E        ; Room $E3 (row 14, column 3): narrow in x, yellow
  DEFB $00,$02,$0E,$FF    ; Backgrounds: arch N, arch S, walls (room narrow in
                          ; x)
  DEFB $AF,$02,$05,$4A,$4D,$92,$95,$AA ; Block (type $5B) x8
  DEFB $AD                             ;
  DEFB $AB,$72,$75,$3A,$3D ; Block (type $5B) x4
  DEFB $B3,$DA,$DD,$E2,$E5 ; Block (type $8F) x4
  DEFB $60,$1B            ; Ball (half a cell along x and y)

; Room $E6 (row 14, column 6): square, magenta
roomE6:
  DEFB $E6,$07,$03        ; Room $E6 (row 14, column 6): square, magenta
  DEFB $04,$05,$06,$0F,$10 ; Backgrounds: forest exit N, forest exit E, forest
                           ; exit S, forest walls, trees closing the W gap; no
                           ; objects

; Room $E7 (row 14, column 7): square, yellow
roomE7:
  DEFB $E7,$11,$06        ; Room $E7 (row 14, column 7): square, yellow
  DEFB $04,$05,$06,$07,$0F,$FF ; Backgrounds: forest exit N, forest exit E,
                               ; forest exit S, forest exit W, forest walls
  DEFB $2F,$33,$34,$21,$19,$26,$1E,$0B ; Spikes x8
  DEFB $0C                             ;

; Room $E8 (row 14, column 8): square, yellow
roomE8:
  DEFB $E8,$16,$06        ; Room $E8 (row 14, column 8): square, yellow
  DEFB $04,$05,$06,$07,$0F,$FF ; Backgrounds: forest exit N, forest exit E,
                               ; forest exit S, forest exit W, forest walls
  DEFB $1F,$33,$21,$23,$63,$A3,$E3,$25 ; Rock x8
  DEFB $13                             ;
  DEFB $2B,$2B,$24,$1B,$22 ; Spikes x4

; Room $E9 (row 14, column 9): square, magenta
roomE9:
  DEFB $E9,$06,$03        ; Room $E9 (row 14, column 9): square, magenta
  DEFB $04,$06,$07,$0F    ; Backgrounds: forest exit N, forest exit S, forest
                          ; exit W, forest walls; no objects

; Room $ED (row 14, column 13): narrow in x, green
roomED:
  DEFB $ED,$14,$0C        ; Room $ED (row 14, column 13): narrow in x, green
  DEFB $00,$02,$0E,$FF    ; Backgrounds: arch N, arch S, walls (room narrow in
                          ; x)
  DEFB $07,$1A,$1B,$1C,$1D,$5A,$5B,$5C ; Block x8
  DEFB $5D                             ;
  DEFB $03,$9A,$9B,$9C,$9D ; Block x4

; Room $EF (row 14, column 15): narrow in x, cyan
roomEF:
  DEFB $EF,$05,$0D        ; Room $EF (row 14, column 15): narrow in x, cyan
  DEFB $00,$02,$0E        ; Backgrounds: arch N, arch S, walls (room narrow in
                          ; x); no objects

; Room $F0 (row 15, column 0): square, cyan
roomF0:
  DEFB $F0,$1B,$05        ; Room $F0 (row 15, column 0): square, cyan
  DEFB $14,$15,$16,$17,$0C,$FF ; Backgrounds: high arch E, high arch S, step to
                               ; high arch E, step to high arch S, walls
                               ; (square room)
  DEFB $07,$DF,$E7,$FF,$FE,$78,$A8,$D0 ; Block x8
  DEFB $C0                             ;
  DEFB $03,$C1,$C2,$C3,$C4 ; Block x4
  DEFB $29,$39,$3B        ; Spikes x2
  DEFB $70,$FB            ; Block (type $36)

; Room $F1 (row 15, column 1): narrow in y, magenta
roomF1:
  DEFB $F1,$0A,$13        ; Room $F1 (row 15, column 1): narrow in y, magenta
  DEFB $01,$03,$09,$0B,$0D,$FF ; Backgrounds: arch E, arch W, portcullis E,
                               ; portcullis W, walls (room narrow in y)
  DEFB $B8,$23            ; Ball (type $B6)

; Room $F2 (row 15, column 2): square, cyan
roomF2:
  DEFB $F2,$06,$05        ; Room $F2 (row 15, column 2): square, cyan
  DEFB $01,$02,$03,$0C    ; Backgrounds: arch E, arch S, arch W, walls (square
                          ; room); no objects

; Room $F3 (row 15, column 3): square, magenta
roomF3:
  DEFB $F3,$17,$03        ; Room $F3 (row 15, column 3): square, magenta
  DEFB $02,$03,$0C,$FF    ; Backgrounds: arch S, arch W, walls (square room)
  DEFB $07,$32,$3A,$72,$7A,$34,$3C,$74 ; Block x8
  DEFB $7C                             ;
  DEFB $01,$B3,$BB        ; Block x2
  DEFB $48,$33            ; Ghost
  DEFB $31,$2B,$6B        ; Chest x2

; Room $F6 (row 15, column 6): square, yellow
roomF6:
  DEFB $F6,$13,$06        ; Room $F6 (row 15, column 6): square, yellow
  DEFB $05,$06,$0F,$10,$11,$FF ; Backgrounds: forest exit E, forest exit S,
                               ; forest walls, trees closing the W gap, trees
                               ; closing the N gap
  DEFB $1B,$1B,$5B,$9B,$DB ; Rock x4
  DEFB $B0,$1C            ; Block (type $8F)
  DEFB $30,$12            ; Chest
  DEFB $38,$34            ; Table

; Room $F7 (row 15, column 7): square, magenta
roomF7:
  DEFB $F7,$15,$03        ; Room $F7 (row 15, column 7): square, magenta
  DEFB $05,$06,$07,$0F,$11,$FF ; Backgrounds: forest exit E, forest exit S,
                               ; forest exit W, forest walls, trees closing the
                               ; N gap
  DEFB $1F,$22,$23,$24,$1A,$1C,$12,$13 ; Rock x8
  DEFB $14                             ;
  DEFB $B8,$1B            ; Ball (type $B6)
  DEFB $30,$5B            ; Chest

; Room $F8 (row 15, column 8): square, magenta
roomF8:
  DEFB $F8,$07,$03        ; Room $F8 (row 15, column 8): square, magenta
  DEFB $05,$06,$07,$0F,$11 ; Backgrounds: forest exit E, forest exit S, forest
                           ; exit W, forest walls, trees closing the N gap; no
                           ; objects

; Room $F9 (row 15, column 9): square, yellow
roomF9:
  DEFB $F9,$13,$06        ; Room $F9 (row 15, column 9): square, yellow
  DEFB $06,$07,$0F,$11,$FF ; Backgrounds: forest exit S, forest exit W, forest
                           ; walls, trees closing the N gap
  DEFB $9F,$FF,$FE,$F6,$F7,$FD,$EF,$C3 ; Raised spiked ball x8
  DEFB $C4                             ;
  DEFB $99,$D8,$E0        ; Raised spiked ball x2

; Room $FD (row 15, column 13): square, yellow
roomFD:
  DEFB $FD,$11,$06        ; Room $FD (row 15, column 13): square, yellow
  DEFB $01,$02,$0C,$FF    ; Backgrounds: arch E, arch S, walls (square room)
  DEFB $07,$28,$29,$2A,$32,$3A,$70,$71 ; Block x8
  DEFB $79                             ;
  DEFB $00,$B8            ; Block

; Room $FE (row 15, column 14): narrow in y, magenta
roomFE:
  DEFB $FE,$12,$13        ; Room $FE (row 15, column 14): narrow in y, magenta
  DEFB $01,$03,$0D,$FF    ; Backgrounds: arch E, arch W, walls (room narrow in
                          ; y)
  DEFB $2B,$25,$1D,$22,$1A ; Spikes x4
  DEFB $23,$2B,$2C,$13,$14 ; Gargoyle x4
  DEFB $60,$5B            ; Ball (half a cell along x and y)

; Room $FF (row 15, column 15): square, yellow
roomFF:
  DEFB $FF,$0B,$06        ; Room $FF (row 15, column 15): square, yellow
  DEFB $02,$03,$0C,$FF    ; Backgrounds: arch S, arch W, walls (square room)
  DEFB $2B,$2E,$35,$37,$3E ; Spikes x4

; Block types
;
; 29 addresses, one for each kind of object a room record can place: bits 3 to
; 7 of a group byte in location_tbl, doubled, index this table (next_fg_obj).
; Each address points at a list of 6-byte parts ended by a 0 byte, laid out as
; described at block. Most kinds are one part; the two guards are two.
;
; The table is not in address order: the records it points at are grouped by
; what they are (blocks, then fire and balls, then spikes and so on), while the
; index order is simply the order the kinds were numbered in.
block_type_tbl:
  DEFW block              ; 0: block
  DEFW fire               ; 1: fire
  DEFW ball_ud_y          ; 2: ball (half a cell along y)
  DEFW rock               ; 3: rock
  DEFW gargoyle           ; 4: gargoyle
  DEFW spike              ; 5: spikes
  DEFW chest              ; 6: chest
  DEFW table              ; 7: table
  DEFW guard_ew           ; 8: guard (type $96)
  DEFW ghost              ; 9: ghost
  DEFW fire_ns            ; 10: fire (type $B5)
  DEFW block_high         ; 11: raised block
  DEFW ball_ud_xy         ; 12: ball (half a cell along x and y)
  DEFW guard_square       ; 13: guard (type $1E)
  DEFW block_ew           ; 14: block (type $36)
  DEFW block_ns           ; 15: block (type $37)
  DEFW moveable_block     ; 16: block (type $3E)
  DEFW spike_high         ; 17: raised spikes
  DEFW spike_ball_fall    ; 18: spiked ball
  DEFW spike_ball_high_fall ; 19: raised spiked ball
  DEFW fire_ew            ; 20: fire (type $56)
  DEFW dropping_block     ; 21: block (type $5B)
  DEFW collapsing_block   ; 22: block (type $8F)
  DEFW ball_bounce        ; 23: ball (type $B6)
  DEFW ball_ud            ; 24: ball
  DEFW repel_spell        ; 25: sparkle (type $A4)
  DEFW portcullis_along_x ; 26: portcullis along x
  DEFW portcullis_along_y ; 27: portcullis along y
  DEFW ball_ud_x          ; 28: ball (half a cell along x)

; Block type 0: stone block
;
; A block type is a list of parts, six bytes each, ended by a 0 byte. For every
; copy a room asks for, next_fg_obj_sprite makes one object record from each
; part.
;
; Byte 0 goes to +0, the object type -- which is also its sprite, through
; sprite_tbl, and its handler, through upd_sprite_jmp_tbl. Bytes 1 to 4 go to
; +4 to +7: size along x, size along y, height, and flags. Byte 5 is not
; stored; it adjusts the position. Its bit 0 adds 8 to x, bit 1 adds 8 to y,
; and the rest, with bits 0 and 1 masked off, is added to z. The record's +8
; gets the room number and bytes +9 to +31 are cleared.
;
; Of the flags, bit 6 draws the sprite mirrored left to right and bit 7 draws
; it upside down (vflip_sprite_data); the other bits are the business of the
; object handlers.
;
; This one is the plain stone block, type $07: 8 by 8 and 12 high, one cell of
; the grid, and the commonest thing in the castle.
block:
  DEFB $07,$08,$08,$0C,$10,$00 ; Type, size x, size y, height, flags, offset;
  DEFB $00                     ; then the end marker

; Block type 11: stone block, raised
;
; The same block with $30 added to its height, which lifts it four levels (12
; units each) above the level its position byte names. The raised spikes and
; the raised spiked ball do the same.
block_high:
  DEFB $07,$08,$08,$0C,$10,$30 ; Type, size x, size y, height, flags, offset;
  DEFB $00                     ; then the end marker

; Block type 14: stone block (type $36)
;
; Type $36, a block with a handler of its own that moves it; the label
; (tcdev's) says east-west, and block_ns is its north-south twin.
block_ew:
  DEFB $36,$08,$08,$0C,$10,$00 ; Type, size x, size y, height, flags, offset;
  DEFB $00                     ; then the end marker

; Block type 15: stone block (type $37)
;
; Type $37: the twin of block_ew, with a handler of its own.
block_ns:
  DEFB $37,$08,$08,$0C,$10,$00 ; Type, size x, size y, height, flags, offset;
  DEFB $00                     ; then the end marker

; Block type 16: stone block (type $3E)
;
; Type $3E, a block with a handler of its own; flags $14 rather than $10.
moveable_block:
  DEFB $3E,$08,$08,$0C,$14,$00 ; Type, size x, size y, height, flags, offset;
  DEFB $00                     ; then the end marker

; Block type 21: stone block (type $5B)
;
; Type $5B, a block with a handler of its own.
dropping_block:
  DEFB $5B,$08,$08,$0C,$10,$00 ; Type, size x, size y, height, flags, offset;
  DEFB $00                     ; then the end marker

; Block type 22: stone block (type $8F)
;
; Type $8F. Its handler (upd_143) turns it into sparkles (type $B8) when bit 3
; of its +13 is set, which is how the block collapses.
collapsing_block:
  DEFB $8F,$08,$08,$0C,$10,$00 ; Type, size x, size y, height, flags, offset;
  DEFB $00                     ; then the end marker

; Block type 1: fire (type $B0)
;
; Type $B0 animates by stepping between $B0 and $B1, the two frames of spr_010.
fire:
  DEFB $B0,$06,$06,$0C,$10,$00 ; Type, size x, size y, height, flags, offset;
  DEFB $00                     ; then the end marker

; Block type 2: ball, half a cell along y
;
; Byte 5 is 2, which moves the ball half a cell (8 units) along y from the
; centre of its cell. The four placements of type $B2 differ only in this byte;
; the label names are tcdev's.
ball_ud_y:
  DEFB $B2,$07,$07,$0C,$10,$02 ; Type, size x, size y, height, flags, offset;
  DEFB $00                     ; then the end marker

; Block type 12: ball, half a cell along x and y
;
; Byte 5 is 3: half a cell along both x and y.
ball_ud_xy:
  DEFB $B2,$07,$07,$0C,$10,$03 ; Type, size x, size y, height, flags, offset;
  DEFB $00                     ; then the end marker

; Block type 24: ball
;
; Byte 5 is 0: the ball sits in the centre of its cell.
ball_ud:
  DEFB $B2,$07,$07,$0C,$10,$00 ; Type, size x, size y, height, flags, offset;
  DEFB $00                     ; then the end marker

; Block type 28: ball, half a cell along x
;
; Byte 5 is 1: half a cell along x.
ball_ud_x:
  DEFB $B2,$07,$07,$0C,$10,$01 ; Type, size x, size y, height, flags, offset;
  DEFB $00                     ; then the end marker

; Block type 23: ball (type $B6)
;
; Type $B6: the same two sprites as the other balls under a different handler.
ball_bounce:
  DEFB $B6,$07,$07,$0C,$10,$00 ; Type, size x, size y, height, flags, offset;
  DEFB $00                     ; then the end marker

; Block type 3: rock
;
; Type $06.
rock:
  DEFB $06,$08,$08,$0C,$10,$00 ; Type, size x, size y, height, flags, offset;
  DEFB $00                     ; then the end marker

; Block type 4: gargoyle
;
; Type $16; its handler marks it deadly to touch.
gargoyle:
  DEFB $16,$06,$06,$0C,$10,$00 ; Type, size x, size y, height, flags, offset;
  DEFB $00                     ; then the end marker

; Block type 5: spikes
;
; Type $17, deadly to touch. Flags $50: drawn mirrored.
spike:
  DEFB $17,$06,$06,$0C,$50,$00 ; Type, size x, size y, height, flags, offset;
  DEFB $00                     ; then the end marker

; Block type 17: spikes, raised
;
; As spike, raised four levels.
spike_high:
  DEFB $17,$06,$06,$0C,$50,$30 ; Type, size x, size y, height, flags, offset;
  DEFB $00                     ; then the end marker

; Block type 18: spiked ball
;
; Type $3F, whose handler drops it on the player.
spike_ball_fall:
  DEFB $3F,$06,$06,$0C,$10,$00 ; Type, size x, size y, height, flags, offset;
  DEFB $00                     ; then the end marker

; Block type 19: spiked ball, raised
;
; As spike_ball_fall, raised four levels.
spike_ball_high_fall:
  DEFB $3F,$06,$06,$0C,$10,$30 ; Type, size x, size y, height, flags, offset;
  DEFB $00                     ; then the end marker

; Block type 6: chest
;
; Type $55, 9 by 6.
chest:
  DEFB $55,$09,$06,$0C,$14,$00 ; Type, size x, size y, height, flags, offset;
  DEFB $00                     ; then the end marker

; Block type 7: table
;
; Type $54, 6 by 10.
table:
  DEFB $54,$06,$0A,$0C,$14,$00 ; Type, size x, size y, height, flags, offset;
  DEFB $00                     ; then the end marker

; Block type 8: guard (type $96)
;
; Two parts at the same place: type $96, the guard's body, 24 high, and type
; $90, its legs, 0 high with bit 1 of its flags set. The body's handler
; (upd_150_151) moves it along x and copies its x into the next object record,
; so the two parts must be laid out one after the other, which this list
; guarantees. Both parts are half a cell along y.
guard_ew:
  DEFB $96,$06,$06,$18,$10,$02 ; Two parts (type, size x, size y, height,
  DEFB $90,$06,$06,$00,$12,$02 ; flags, offset), then the end marker
  DEFB $00                     ;

; Block type 13: guard (type $1E)
;
; Two parts at the same place: type $1E, the guard's body, and type $90, its
; legs. The body's handler (upd_30_31_158_159) walks it in each of the four
; directions in turn and copies its x and y into the next record, for the legs.
guard_square:
  DEFB $1E,$06,$06,$18,$10,$00 ; Two parts (type, size x, size y, height,
  DEFB $90,$06,$06,$00,$12,$00 ; flags, offset), then the end marker
  DEFB $00                     ;

; Block type 9: ghost
;
; Type $52, one of the ghost's four frames ($50 to $53).
ghost:
  DEFB $52,$06,$06,$0C,$10,$00 ; Type, size x, size y, height, flags, offset;
  DEFB $00                     ; then the end marker

; Block type 10: fire (type $B5)
;
; Type $B5; the label (tcdev's) says north-south, and its handler moves it
; along y.
fire_ns:
  DEFB $B5,$06,$06,$0C,$10,$00 ; Type, size x, size y, height, flags, offset;
  DEFB $00                     ; then the end marker

; Block type 20: fire (type $56)
;
; Type $56; its handler moves it along x.
fire_ew:
  DEFB $56,$06,$06,$0C,$10,$00 ; Type, size x, size y, height, flags, offset;
  DEFB $00                     ; then the end marker

; Block type 25: sparkle (type $A4)
;
; Type $A4, 5 by 5: a sparkle. Type $A4 is also what the sparkle over the
; cauldron becomes when the player is the werewulf (upd_160_to_163); the label
; is tcdev's name for it.
repel_spell:
  DEFB $A4,$05,$05,$0C,$10,$00 ; Type, size x, size y, height, flags, offset;
  DEFB $00                     ; then the end marker

; Block type 26: portcullis along x
;
; Type $08, the portcullis, 12 by 1 and 32 high. Byte 5 is 1: half a cell along
; x, which puts its middle on a cell boundary. Renamed from tcdev's gate_ud_1,
; a name that ended in a digit and did not say which way the gate lies.
portcullis_along_x:
  DEFB $08,$0C,$01,$20,$50,$01 ; Type, size x, size y, height, flags, offset;
  DEFB $00                     ; then the end marker

; Block type 27: portcullis along y
;
; Type $08 lying the other way, 1 by 12; byte 5 is 2, half a cell along y.
; Renamed from tcdev's gate_ud_2.
portcullis_along_y:
  DEFB $08,$01,$0C,$20,$10,$02 ; Type, size x, size y, height, flags, offset;
  DEFB $00                     ; then the end marker

; Backgrounds
;
; 24 addresses, one for each background a room record can name. Each points at
; a list of 8-byte records ended by a 0 byte, and next_bg_obj_sprite copies
; each record as it stands into bytes 0 to 7 of a new object record: type, x,
; y, z, size along x, size along y, height and flags. It sets +8 to the room
; number and clears the rest. Unlike a block type, a background carries its own
; coordinates, so it is always in the same place in a room.
;
; North is towards larger y and east towards larger x: the north arch stands at
; y = $C4, just beyond the far side of a full-depth room, and the east arch at
; x = $C4. Only the north and west sides have walls; the south and east sides
; are open towards the viewer.
background_type_tbl:
  DEFW arch_n             ; 0: arch N
  DEFW arch_e             ; 1: arch E
  DEFW arch_s             ; 2: arch S
  DEFW arch_w             ; 3: arch W
  DEFW tree_arch_n        ; 4: forest exit N
  DEFW tree_arch_e        ; 5: forest exit E
  DEFW tree_arch_s        ; 6: forest exit S
  DEFW tree_arch_w        ; 7: forest exit W
  DEFW gate_n             ; 8: portcullis N
  DEFW gate_e             ; 9: portcullis E
  DEFW gate_s             ; 10: portcullis S
  DEFW gate_w             ; 11: portcullis W
  DEFW walls_square       ; 12: walls (square room)
  DEFW walls_narrow_y     ; 13: walls (room narrow in y)
  DEFW walls_narrow_x     ; 14: walls (room narrow in x)
  DEFW tree_walls         ; 15: forest walls
  DEFW tree_filler_w      ; 16: trees closing the W gap
  DEFW tree_filler_n      ; 17: trees closing the N gap
  DEFW wizard             ; 18: the wizard
  DEFW cauldron           ; 19: the cauldron
  DEFW high_arch_e        ; 20: high arch E
  DEFW high_arch_s        ; 21: high arch S
  DEFW high_arch_e_base   ; 22: step to high arch E
  DEFW high_arch_s_base   ; 23: step to high arch S

; Background 0: arch in the north side
;
; Two pieces, types $02 and $03 (spr_071 and spr_072), $0D either side of x =
; $80 at y = $C4, each 3 by 5 and 40 high. An arch is a gap between two pillars
; rather than a hole in a wall. The other arches are the same pair moved and
; turned; flags $50 draws them mirrored where the arch faces along x. Named by
; 63 rooms.
arch_n:
  DEFB $02,$8D,$C4,$80,$03,$05,$28,$50 ; arch piece $02 at x $8D, y $C4, z $80;
                                       ; 3 by 5, 40 high; flags $50
  DEFB $03,$73,$C4,$80,$03,$05,$28,$50 ; arch piece $03 at x $73, y $C4, z $80;
                                       ; 3 by 5, 40 high; flags $50
  DEFB $00                ; End of list

; Background 1: arch in the east side
;
; The pair of arch_n turned to face along x, at x = $C4. Named by 40 rooms.
arch_e:
  DEFB $02,$C4,$73,$80,$05,$03,$28,$10 ; arch piece $02 at x $C4, y $73, z $80;
                                       ; 5 by 3, 40 high; flags $10
  DEFB $03,$C4,$8D,$80,$05,$03,$28,$10 ; arch piece $03 at x $C4, y $8D, z $80;
                                       ; 5 by 3, 40 high; flags $10
  DEFB $00                ; End of list

; Background 20: high arch in the east side
;
; As arch_e but with its floor at $B0, 48 units up. Every room that has it also
; has high_arch_e_base, the two blocks that make the step up to it. Named by 10
; rooms.
high_arch_e:
  DEFB $02,$C4,$73,$B0,$05,$03,$28,$10 ; arch piece $02 at x $C4, y $73, z $B0;
                                       ; 5 by 3, 40 high; flags $10
  DEFB $03,$C4,$8D,$B0,$05,$03,$28,$10 ; arch piece $03 at x $C4, y $8D, z $B0;
                                       ; 5 by 3, 40 high; flags $10
  DEFB $00                ; End of list

; Background 2: arch in the south side
;
; The pair of arch_n at y = $3B. Named by 46 rooms.
arch_s:
  DEFB $02,$8D,$3B,$80,$03,$05,$28,$50 ; arch piece $02 at x $8D, y $3B, z $80;
                                       ; 3 by 5, 40 high; flags $50
  DEFB $03,$73,$3B,$80,$03,$05,$28,$50 ; arch piece $03 at x $73, y $3B, z $80;
                                       ; 3 by 5, 40 high; flags $50
  DEFB $00                ; End of list

; Background 21: high arch in the south side
;
; As arch_s at z = $B0; always paired with high_arch_s_base. Named by 16 rooms.
high_arch_s:
  DEFB $02,$8D,$3B,$B0,$03,$05,$28,$50 ; arch piece $02 at x $8D, y $3B, z $B0;
                                       ; 3 by 5, 40 high; flags $50
  DEFB $03,$73,$3B,$B0,$03,$05,$28,$50 ; arch piece $03 at x $73, y $3B, z $B0;
                                       ; 3 by 5, 40 high; flags $50
  DEFB $00                ; End of list

; Background 3: arch in the west side
;
; The pair of arch_e at x = $3B. Named by 50 rooms.
arch_w:
  DEFB $02,$3B,$73,$80,$05,$03,$28,$10 ; arch piece $02 at x $3B, y $73, z $80;
                                       ; 5 by 3, 40 high; flags $10
  DEFB $03,$3B,$8D,$80,$05,$03,$28,$10 ; arch piece $03 at x $3B, y $8D, z $80;
                                       ; 5 by 3, 40 high; flags $10
  DEFB $00                ; End of list

; Background 4: forest exit, north
;
; The forest version of arch_n: two tree trunks, types $04 and $05 (spr_023 and
; spr_024), either side of the way out. Named by 13 rooms.
tree_arch_n:
  DEFB $04,$8D,$C4,$80,$03,$05,$28,$50 ; tree trunk $04 at x $8D, y $C4, z $80;
                                       ; 3 by 5, 40 high; flags $50
  DEFB $05,$73,$C4,$80,$03,$05,$28,$50 ; tree trunk $05 at x $73, y $C4, z $80;
                                       ; 3 by 5, 40 high; flags $50
  DEFB $00                ; End of list

; Background 5: forest exit, east
;
; Two tree trunks either side of the east way out. Named by 17 rooms.
tree_arch_e:
  DEFB $04,$C4,$73,$80,$05,$03,$28,$10 ; tree trunk $04 at x $C4, y $73, z $80;
                                       ; 5 by 3, 40 high; flags $10
  DEFB $05,$C4,$8D,$80,$05,$03,$28,$10 ; tree trunk $05 at x $C4, y $8D, z $80;
                                       ; 5 by 3, 40 high; flags $10
  DEFB $00                ; End of list

; Background 6: forest exit, south
;
; Two tree trunks either side of the south way out. Named by 14 rooms.
tree_arch_s:
  DEFB $04,$8D,$3B,$80,$03,$05,$28,$50 ; tree trunk $04 at x $8D, y $3B, z $80;
                                       ; 3 by 5, 40 high; flags $50
  DEFB $05,$73,$3B,$80,$03,$05,$28,$50 ; tree trunk $05 at x $73, y $3B, z $80;
                                       ; 3 by 5, 40 high; flags $50
  DEFB $00                ; End of list

; Background 7: forest exit, west
;
; Two tree trunks either side of the west way out. Named by 17 rooms.
tree_arch_w:
  DEFB $04,$3B,$73,$80,$05,$03,$28,$10 ; tree trunk $04 at x $3B, y $73, z $80;
                                       ; 5 by 3, 40 high; flags $10
  DEFB $05,$3B,$8D,$80,$05,$03,$28,$10 ; tree trunk $05 at x $3B, y $8D, z $80;
                                       ; 5 by 3, 40 high; flags $10
  DEFB $00                ; End of list

; Background 8: portcullis in the north doorway
;
; One piece, type $08, 12 by 1 and 32 high, at z = $A0: 32 units above a floor
; at $80, so it starts raised. Its handler, for type $08, is what lets it down.
; Named by 1 room.
gate_n:
  DEFB $08,$80,$BE,$A0,$0C,$01,$20,$50 ; portcullis $08 at x $80, y $BE, z $A0;
                                       ; 12 by 1, 32 high; flags $50
  DEFB $00                ; End of list

; Background 9: portcullis in the east doorway
;
; The portcullis turned to lie along y, at x = $BE. Named by 2 rooms.
gate_e:
  DEFB $08,$BE,$80,$A0,$01,$0C,$20,$10 ; portcullis $08 at x $BE, y $80, z $A0;
                                       ; 1 by 12, 32 high; flags $10
  DEFB $00                ; End of list

; Background 10: portcullis in the south doorway
;
; The portcullis at y = $41. Named by 1 room.
gate_s:
  DEFB $08,$80,$41,$A0,$0C,$01,$20,$50 ; portcullis $08 at x $80, y $41, z $A0;
                                       ; 12 by 1, 32 high; flags $50
  DEFB $00                ; End of list

; Background 11: portcullis in the west doorway
;
; The portcullis along y at x = $41. Named by 2 rooms.
gate_w:
  DEFB $08,$41,$80,$A0,$01,$0C,$20,$10 ; portcullis $08 at x $41, y $80, z $A0;
                                       ; 1 by 12, 32 high; flags $10
  DEFB $00                ; End of list

; Background 12: walls of a square room
;
; Thirteen pieces along the west side (x = $3F) and the north side (y = $C0) of
; a room of shape 0. Types $0D and $0E are the columns where the two walls
; meet, $0F the wall ends, stacked two high, and $0A to $0C slabs of three
; lengths that fill the wall between them, leaving the gaps where arches go.
; Renamed from tcdev's wall_size_1: the three wall sets serve room shapes 0, 2
; and 1 in that order, so numbered names mislead. Named by 46 rooms.
walls_square:
  DEFB $0D,$3F,$B8,$80,$00,$08,$28,$10 ; wall column $0D at x $3F, y $B8, z
                                       ; $80; 0 by 8, 40 high; flags $10
  DEFB $0E,$47,$C0,$80,$08,$00,$28,$10 ; wall column $0E at x $47, y $C0, z
                                       ; $80; 8 by 0, 40 high; flags $10
  DEFB $0F,$3F,$49,$80,$00,$08,$2C,$10 ; wall end $0F at x $3F, y $49, z $80; 0
                                       ; by 8, 44 high; flags $10
  DEFB $0F,$B8,$C0,$80,$08,$00,$2C,$50 ; wall end $0F at x $B8, y $C0, z $80; 8
                                       ; by 0, 44 high; flags $50
  DEFB $0F,$3F,$49,$AC,$00,$08,$2C,$10 ; wall end $0F at x $3F, y $49, z $AC; 0
                                       ; by 8, 44 high; flags $10
  DEFB $0F,$B8,$C0,$AC,$08,$00,$2C,$50 ; wall end $0F at x $B8, y $C0, z $AC; 8
                                       ; by 0, 44 high; flags $50
  DEFB $0A,$5C,$C0,$80,$14,$00,$14,$50 ; wall slab $0A at x $5C, y $C0, z $80;
                                       ; 20 by 0, 20 high; flags $50
  DEFB $0B,$3F,$5C,$98,$00,$0C,$14,$10 ; wall slab $0B at x $3F, y $5C, z $98;
                                       ; 0 by 12, 20 high; flags $10
  DEFB $0C,$3F,$A0,$98,$00,$0C,$0C,$10 ; wall slab $0C at x $3F, y $A0, z $98;
                                       ; 0 by 12, 12 high; flags $10
  DEFB $0B,$A4,$C0,$98,$0C,$00,$14,$50 ; wall slab $0B at x $A4, y $C0, z $98;
                                       ; 12 by 0, 20 high; flags $50
  DEFB $0A,$3F,$6D,$B1,$00,$14,$14,$10 ; wall slab $0A at x $3F, y $6D, z $B1;
                                       ; 0 by 20, 20 high; flags $10
  DEFB $0C,$60,$C0,$A0,$0C,$00,$0C,$50 ; wall slab $0C at x $60, y $C0, z $A0;
                                       ; 12 by 0, 12 high; flags $50
  DEFB $0A,$90,$C0,$B0,$14,$00,$14,$50 ; wall slab $0A at x $90, y $C0, z $B0;
                                       ; 20 by 0, 20 high; flags $50
  DEFB $00                ; End of list

; Background 13: walls of a room narrow in y
;
; Fourteen pieces for a room of shape 2, only $20 deep either side of the
; centre, so the west wall runs from y = $63 to $98. Renamed from tcdev's
; wall_size_2. Named by 24 rooms.
walls_narrow_y:
  DEFB $0D,$3F,$98,$80,$00,$08,$28,$10 ; wall column $0D at x $3F, y $98, z
                                       ; $80; 0 by 8, 40 high; flags $10
  DEFB $0E,$47,$A0,$80,$08,$00,$28,$10 ; wall column $0E at x $47, y $A0, z
                                       ; $80; 8 by 0, 40 high; flags $10
  DEFB $0F,$3F,$63,$80,$00,$08,$2C,$10 ; wall end $0F at x $3F, y $63, z $80; 0
                                       ; by 8, 44 high; flags $10
  DEFB $0F,$B8,$A0,$80,$08,$00,$2C,$50 ; wall end $0F at x $B8, y $A0, z $80; 8
                                       ; by 0, 44 high; flags $50
  DEFB $0F,$3F,$63,$AC,$00,$08,$2C,$10 ; wall end $0F at x $3F, y $63, z $AC; 0
                                       ; by 8, 44 high; flags $10
  DEFB $0F,$B8,$A0,$AC,$08,$00,$2C,$50 ; wall end $0F at x $B8, y $A0, z $AC; 8
                                       ; by 0, 44 high; flags $50
  DEFB $0D,$3F,$98,$A8,$00,$08,$28,$10 ; wall column $0D at x $3F, y $98, z
                                       ; $A8; 0 by 8, 40 high; flags $10
  DEFB $0E,$47,$A0,$A8,$08,$00,$28,$10 ; wall column $0E at x $47, y $A0, z
                                       ; $A8; 8 by 0, 40 high; flags $10
  DEFB $0F,$B8,$A0,$D0,$08,$00,$2C,$50 ; wall end $0F at x $B8, y $A0, z $D0; 8
                                       ; by 0, 44 high; flags $50
  DEFB $0A,$80,$A0,$80,$14,$00,$14,$50 ; wall slab $0A at x $80, y $A0, z $80;
                                       ; 20 by 0, 20 high; flags $50
  DEFB $0A,$3F,$7E,$B0,$00,$14,$14,$10 ; wall slab $0A at x $3F, y $7E, z $B0;
                                       ; 0 by 20, 20 high; flags $10
  DEFB $0B,$60,$A0,$90,$0C,$00,$14,$50 ; wall slab $0B at x $60, y $A0, z $90;
                                       ; 12 by 0, 20 high; flags $50
  DEFB $0A,$60,$A0,$B8,$14,$00,$14,$50 ; wall slab $0A at x $60, y $A0, z $B8;
                                       ; 20 by 0, 20 high; flags $50
  DEFB $0C,$A0,$A0,$B0,$0C,$00,$0C,$50 ; wall slab $0C at x $A0, y $A0, z $B0;
                                       ; 12 by 0, 12 high; flags $50
  DEFB $00                ; End of list

; Background 14: walls of a room narrow in x
;
; Fourteen pieces for a room of shape 1, only $20 wide either side of the
; centre: its west wall stands at x = $5F. Renamed from tcdev's wall_size_3.
; Named by 34 rooms.
walls_narrow_x:
  DEFB $0D,$5F,$B8,$80,$00,$08,$28,$10 ; wall column $0D at x $5F, y $B8, z
                                       ; $80; 0 by 8, 40 high; flags $10
  DEFB $0E,$67,$C0,$80,$08,$00,$28,$10 ; wall column $0E at x $67, y $C0, z
                                       ; $80; 8 by 0, 40 high; flags $10
  DEFB $0F,$5F,$48,$80,$00,$08,$2C,$10 ; wall end $0F at x $5F, y $48, z $80; 0
                                       ; by 8, 44 high; flags $10
  DEFB $0F,$9D,$C0,$80,$08,$00,$2C,$50 ; wall end $0F at x $9D, y $C0, z $80; 8
                                       ; by 0, 44 high; flags $50
  DEFB $0D,$5F,$B8,$A8,$00,$08,$28,$10 ; wall column $0D at x $5F, y $B8, z
                                       ; $A8; 0 by 8, 40 high; flags $10
  DEFB $0E,$67,$C0,$A8,$08,$00,$28,$10 ; wall column $0E at x $67, y $C0, z
                                       ; $A8; 8 by 0, 40 high; flags $10
  DEFB $0F,$5F,$48,$AC,$00,$08,$2C,$10 ; wall end $0F at x $5F, y $48, z $AC; 0
                                       ; by 8, 44 high; flags $10
  DEFB $0F,$9D,$C0,$AC,$08,$00,$2C,$50 ; wall end $0F at x $9D, y $C0, z $AC; 8
                                       ; by 0, 44 high; flags $50
  DEFB $0F,$5F,$48,$D0,$00,$08,$2C,$10 ; wall end $0F at x $5F, y $48, z $D0; 0
                                       ; by 8, 44 high; flags $10
  DEFB $0A,$5F,$90,$80,$00,$14,$14,$10 ; wall slab $0A at x $5F, y $90, z $80;
                                       ; 0 by 20, 20 high; flags $10
  DEFB $0A,$84,$C0,$B0,$14,$00,$14,$50 ; wall slab $0A at x $84, y $C0, z $B0;
                                       ; 20 by 0, 20 high; flags $50
  DEFB $0B,$5F,$60,$90,$00,$0C,$14,$10 ; wall slab $0B at x $5F, y $60, z $90;
                                       ; 0 by 12, 20 high; flags $10
  DEFB $0A,$5F,$68,$B8,$00,$14,$14,$10 ; wall slab $0A at x $5F, y $68, z $B8;
                                       ; 0 by 20, 20 high; flags $10
  DEFB $0C,$5F,$A0,$B0,$00,$0C,$0C,$10 ; wall slab $0C at x $5F, y $A0, z $B0;
                                       ; 0 by 12, 12 high; flags $10
  DEFB $00                ; End of list

; Background 15: the trees round a forest room
;
; Twelve trees, types $80, $81 and $82 in turn (spr_066, spr_067 and spr_068),
; six along the west side and six along the north, with a gap in the middle of
; each for a way out. Used by the 24 forest rooms, all of shape 0. Renamed from
; tcdev's tree_room_size_1: there is only one size. Named by 24 rooms.
tree_walls:
  DEFB $80,$3F,$49,$80,$00,$08,$2C,$10 ; tree $80 at x $3F, y $49, z $80; 0 by
                                       ; 8, 44 high; flags $10
  DEFB $81,$3F,$58,$80,$00,$08,$2C,$10 ; tree $81 at x $3F, y $58, z $80; 0 by
                                       ; 8, 44 high; flags $10
  DEFB $82,$3F,$68,$80,$00,$08,$2C,$10 ; tree $82 at x $3F, y $68, z $80; 0 by
                                       ; 8, 44 high; flags $10
  DEFB $80,$3F,$98,$80,$00,$08,$2C,$10 ; tree $80 at x $3F, y $98, z $80; 0 by
                                       ; 8, 44 high; flags $10
  DEFB $81,$3F,$A8,$80,$00,$08,$2C,$10 ; tree $81 at x $3F, y $A8, z $80; 0 by
                                       ; 8, 44 high; flags $10
  DEFB $82,$3F,$B8,$80,$00,$08,$2C,$10 ; tree $82 at x $3F, y $B8, z $80; 0 by
                                       ; 8, 44 high; flags $10
  DEFB $80,$48,$C0,$80,$08,$00,$2C,$50 ; tree $80 at x $48, y $C0, z $80; 8 by
                                       ; 0, 44 high; flags $50
  DEFB $81,$58,$C0,$80,$08,$00,$2C,$50 ; tree $81 at x $58, y $C0, z $80; 8 by
                                       ; 0, 44 high; flags $50
  DEFB $82,$68,$C0,$80,$08,$00,$2C,$50 ; tree $82 at x $68, y $C0, z $80; 8 by
                                       ; 0, 44 high; flags $50
  DEFB $80,$98,$C0,$80,$08,$00,$2C,$50 ; tree $80 at x $98, y $C0, z $80; 8 by
                                       ; 0, 44 high; flags $50
  DEFB $81,$A8,$C0,$80,$08,$00,$2C,$50 ; tree $81 at x $A8, y $C0, z $80; 8 by
                                       ; 0, 44 high; flags $50
  DEFB $82,$B8,$C0,$80,$08,$00,$2C,$50 ; tree $82 at x $B8, y $C0, z $80; 8 by
                                       ; 0, 44 high; flags $50
  DEFB $00                ; End of list

; Background 16: trees closing the west gap
;
; Two trees, $80 and $81, at y = $78 and $88 on the west side. A forest room
; with no way out to the west names this to close the gap tree_walls leaves; it
; never appears with tree_arch_w. Named by 7 rooms.
tree_filler_w:
  DEFB $80,$3F,$78,$80,$00,$08,$2C,$10 ; tree $80 at x $3F, y $78, z $80; 0 by
                                       ; 8, 44 high; flags $10
  DEFB $81,$3F,$88,$80,$00,$08,$2C,$10 ; tree $81 at x $3F, y $88, z $80; 0 by
                                       ; 8, 44 high; flags $10
  DEFB $00                ; End of list

; Background 17: trees closing the north gap
;
; The same for the north side: used by the forest rooms that have no
; tree_arch_n. Named by 11 rooms.
tree_filler_n:
  DEFB $80,$78,$C0,$80,$08,$00,$2C,$50 ; tree $80 at x $78, y $C0, z $80; 8 by
                                       ; 0, 44 high; flags $50
  DEFB $81,$88,$C0,$80,$08,$00,$2C,$50 ; tree $81 at x $88, y $C0, z $80; 8 by
                                       ; 0, 44 high; flags $50
  DEFB $00                ; End of list

; Background 18: the wizard
;
; Two pieces: type $9E, the wizard's body (spr_013), and type $90, legs, with
; bit 1 of its flags set, built as the guards are. Only room $88 has it. Named
; by 1 room.
wizard:
  DEFB $9E,$98,$68,$80,$05,$05,$18,$10 ; wizard's body $9E at x $98, y $68, z
                                       ; $80; 5 by 5, 24 high; flags $10
  DEFB $90,$A0,$60,$80,$05,$05,$00,$12 ; legs $90 at x $A0, y $60, z $80; 5 by
                                       ; 5, 0 high; flags $12
  DEFB $00                ; End of list

; Background 19: the cauldron
;
; Two pieces: type $8D, the cauldron itself (spr_074), 10 by 10, and type $8E
; (spr_075), with no size and bit 1 of its flags set. Only room $88 has it,
; beside the wizard. Named by 1 room.
cauldron:
  DEFB $8D,$80,$80,$80,$0A,$0A,$18,$10 ; cauldron $8D at x $80, y $80, z $80;
                                       ; 10 by 10, 24 high; flags $10
  DEFB $8E,$80,$88,$80,$00,$00,$00,$12 ; cauldron's top $8E at x $80, y $88, z
                                       ; $80; 0 by 0, 0 high; flags $12
  DEFB $00                ; End of list

; Background 22: step up to the high east arch
;
; Two stone blocks, type $07, at x = $C8, y = $78 and $88, z = $A4: the step
; below high_arch_e. Named by 10 rooms.
high_arch_e_base:
  DEFB $07,$C8,$78,$A4,$08,$08,$0C,$10 ; block $07 at x $C8, y $78, z $A4; 8 by
                                       ; 8, 12 high; flags $10
  DEFB $07,$C8,$88,$A4,$08,$08,$0C,$10 ; block $07 at x $C8, y $88, z $A4; 8 by
                                       ; 8, 12 high; flags $10
  DEFB $00                ; End of list

; Background 23: step up to the high south arch
;
; Two stone blocks at y = $38, z = $A4, below high_arch_s. Named by 16 rooms.
high_arch_s_base:
  DEFB $07,$78,$38,$A4,$08,$08,$0C,$10 ; block $07 at x $78, y $38, z $A4; 8 by
                                       ; 8, 12 high; flags $10
  DEFB $07,$88,$38,$A4,$08,$08,$0C,$10 ; block $07 at x $88, y $38, z $A4; 8 by
                                       ; 8, 12 high; flags $10
  DEFB $00                ; End of list

; Where the charms lie
;
; 32 records of 9 bytes, each a place where a charm lies. In the game as loaded
; only bytes 1 to 4 are filled: x, y, z and room number. init_special_objects
; fills in the rest when a game starts. Byte 0 becomes the charm's type, $60 to
; $67, taken in turn, so the eight kinds go round the table in a fixed order
; and each lies in exactly four places; only the starting kind varies, from the
; seed at $5BA0 plus the refresh register. Bytes 5 to 8 get a copy of bytes 1
; to 4, and from then on they, not 1 to 4, say where the charm is now: x, y, z
; and room.
;
; On entering a room, find_special_objs_here makes an object record, from $5C48
; upwards, for every entry whose type is not 0 and whose byte 8 is this room.
; It gives the object a size of 5 by 5 by 12 and flags $14, and stores the
; address of the entry itself at +16 and +17 of the record, so the object can
; find its entry again. On leaving, update_special_objs writes the object's
; type and position back into bytes 0 and 5 to 8, which is how a charm that has
; been carried and dropped stays where it was put. Picking a charm up, feeding
; it to the cauldron or losing it writes 0 to byte 0, which takes that entry
; out of the game (pickup_object, add_obj_to_cauldron, upd_185_187).
;
; This table only says where the charms lie. Which of them the wizard wants,
; and in what order, is the separate list at objects_required, which
; shuffle_objects_required rotates at the start of a game.
;
; No room holds more than one entry, so the two object slots from $5C48 to
; $5C87 are always enough. The 32 rooms are all different, and all exist in
; location_tbl.
special_objs_tbl:
  DEFB $00,$88,$80,$A4,$6D,$00,$00,$00 ; Place 0: room $6D, x $88, y $80, z $A4
  DEFB $00                             ;
  DEFB $00,$80,$80,$8C,$27,$00,$00,$00 ; Place 1: room $27, x $80, y $80, z $8C
  DEFB $00                             ;
  DEFB $00,$88,$78,$B0,$D0,$00,$00,$00 ; Place 2: room $D0, x $88, y $78, z $B0
  DEFB $00                             ;
  DEFB $00,$78,$88,$80,$0A,$00,$00,$00 ; Place 3: room $0A, x $78, y $88, z $80
  DEFB $00                             ;
  DEFB $00,$78,$88,$80,$BA,$00,$00,$00 ; Place 4: room $BA, x $78, y $88, z $80
  DEFB $00                             ;
  DEFB $00,$88,$78,$B0,$42,$00,$00,$00 ; Place 5: room $42, x $88, y $78, z $B0
  DEFB $00                             ;
  DEFB $00,$88,$B8,$BC,$8D,$00,$00,$00 ; Place 6: room $8D, x $88, y $B8, z $BC
  DEFB $00                             ;
  DEFB $00,$A8,$A8,$80,$FF,$00,$00,$00 ; Place 7: room $FF, x $A8, y $A8, z $80
  DEFB $00                             ;
  DEFB $00,$80,$80,$80,$87,$00,$00,$00 ; Place 8: room $87, x $80, y $80, z $80
  DEFB $00                             ;
  DEFB $00,$78,$B8,$80,$F3,$00,$00,$00 ; Place 9: room $F3, x $78, y $B8, z $80
  DEFB $00                             ;
  DEFB $00,$A8,$68,$B0,$A8,$00,$00,$00 ; Place 10: room $A8, x $A8, y $68, z
  DEFB $00                             ; $B0
  DEFB $00,$B8,$48,$B0,$D2,$00,$00,$00 ; Place 11: room $D2, x $B8, y $48, z
  DEFB $00                             ; $B0
  DEFB $00,$48,$48,$80,$00,$00,$00,$00 ; Place 12: room $00, x $48, y $48, z
  DEFB $00                             ; $80
  DEFB $00,$88,$B8,$80,$22,$00,$00,$00 ; Place 13: room $22, x $88, y $B8, z
  DEFB $00                             ; $80
  DEFB $00,$B8,$B8,$B0,$7A,$00,$00,$00 ; Place 14: room $7A, x $B8, y $B8, z
  DEFB $00                             ; $B0
  DEFB $00,$B8,$B8,$80,$F9,$00,$00,$00 ; Place 15: room $F9, x $B8, y $B8, z
  DEFB $00                             ; $80
  DEFB $00,$88,$98,$B0,$D6,$00,$00,$00 ; Place 16: room $D6, x $88, y $98, z
  DEFB $00                             ; $B0
  DEFB $00,$78,$88,$B0,$E8,$00,$00,$00 ; Place 17: room $E8, x $78, y $88, z
  DEFB $00                             ; $B0
  DEFB $00,$78,$78,$B0,$F6,$00,$00,$00 ; Place 18: room $F6, x $78, y $78, z
  DEFB $00                             ; $B0
  DEFB $00,$88,$78,$8C,$0F,$00,$00,$00 ; Place 19: room $0F, x $88, y $78, z
  DEFB $00                             ; $8C
  DEFB $00,$B8,$B8,$80,$6F,$00,$00,$00 ; Place 20: room $6F, x $B8, y $B8, z
  DEFB $00                             ; $80
  DEFB $00,$48,$B8,$A4,$FD,$00,$00,$00 ; Place 21: room $FD, x $48, y $B8, z
  DEFB $00                             ; $A4
  DEFB $00,$78,$78,$B0,$08,$00,$00,$00 ; Place 22: room $08, x $78, y $78, z
  DEFB $00                             ; $B0
  DEFB $00,$88,$88,$A4,$BB,$00,$00,$00 ; Place 23: room $BB, x $88, y $88, z
  DEFB $00                             ; $A4
  DEFB $00,$78,$78,$B0,$DF,$00,$00,$00 ; Place 24: room $DF, x $78, y $78, z
  DEFB $00                             ; $B0
  DEFB $00,$80,$80,$80,$5E,$00,$00,$00 ; Place 25: room $5E, x $80, y $80, z
  DEFB $00                             ; $80
  DEFB $00,$78,$88,$B0,$B4,$00,$00,$00 ; Place 26: room $B4, x $78, y $88, z
  DEFB $00                             ; $B0
  DEFB $00,$78,$78,$B0,$04,$00,$00,$00 ; Place 27: room $04, x $78, y $78, z
  DEFB $00                             ; $B0
  DEFB $00,$48,$B8,$80,$74,$00,$00,$00 ; Place 28: room $74, x $48, y $B8, z
  DEFB $00                             ; $80
  DEFB $00,$80,$80,$80,$40,$00,$00,$00 ; Place 29: room $40, x $80, y $80, z
  DEFB $00                             ; $80
  DEFB $00,$68,$78,$B0,$38,$00,$00,$00 ; Place 30: room $38, x $68, y $78, z
  DEFB $00                             ; $B0
  DEFB $00,$48,$B8,$98,$F0,$00,$00,$00 ; Place 31: room $F0, x $48, y $B8, z
  DEFB $00                             ; $98

; Sprite for each object type
;
; 188 addresses, one for each object type. The type is byte 0 of an object
; record, and flip_sprite doubles it to index this table, just as
; jump_to_upd_object indexes the handlers at upd_sprite_jmp_tbl with it. There
; is no separate frame number: an object animates by changing its own type, so
; an animation is a run of consecutive types, and a walk cycle is six types
; whose entries name four sprites in the order 1 2 3 4 3 2. The same sprite
; often serves several types, for things that look alike but behave
; differently.
;
; Several runs are laid out in parallel. Sabreman is two objects, legs ($10 to
; $15 and $18 to $1D) and head and shoulders ($20 to $2F); the upper half's
; type is the legs' type plus $10 (set_top_sprite), except that now and then it
; is given the frame at $x6 or $x7 instead. Bit 3 of the type chooses between
; two sets of art for two views of him, and mirroring (bit 6 of the flags)
; gives the other two directions. By night the whole set moves up by $20, to
; the werewulf's types $30 to $4F (lose_life). The guards and the wizard stand
; on Sabreman's leg frames, under types $90 to $9D.
;
; Types $00 and $01 have the empty sprite at spr_nul, which is never drawn: $00
; is an unused record and $01 one that is about to be removed.
sprite_tbl:
  DEFW spr_nul
  DEFW spr_nul
  DEFW spr_071
  DEFW spr_072
  DEFW spr_023
  DEFW spr_024
  DEFW spr_008
  DEFW spr_020
  DEFW spr_043
  DEFW spr_043
  DEFW spr_076
  DEFW spr_077
  DEFW spr_078
  DEFW spr_069
  DEFW spr_070
  DEFW spr_073
  DEFW spr_055
  DEFW spr_056
  DEFW spr_057
  DEFW spr_058
  DEFW spr_057
  DEFW spr_056
  DEFW spr_009
  DEFW spr_002
  DEFW spr_059
  DEFW spr_060
  DEFW spr_061
  DEFW spr_062
  DEFW spr_061
  DEFW spr_060
  DEFW spr_005
  DEFW spr_004
  DEFW spr_050
  DEFW spr_051
  DEFW spr_046
  DEFW spr_049
  DEFW spr_046
  DEFW spr_051
  DEFW spr_048
  DEFW spr_063
  DEFW spr_052
  DEFW spr_047
  DEFW spr_054
  DEFW spr_053
  DEFW spr_054
  DEFW spr_047
  DEFW spr_065
  DEFW spr_064
  DEFW spr_079
  DEFW spr_080
  DEFW spr_081
  DEFW spr_082
  DEFW spr_081
  DEFW spr_080
  DEFW spr_020
  DEFW spr_020
  DEFW spr_083
  DEFW spr_084
  DEFW spr_085
  DEFW spr_086
  DEFW spr_085
  DEFW spr_084
  DEFW spr_020
  DEFW spr_003
  DEFW spr_087
  DEFW spr_088
  DEFW spr_089
  DEFW spr_090
  DEFW spr_089
  DEFW spr_088
  DEFW spr_095
  DEFW spr_096
  DEFW spr_094
  DEFW spr_093
  DEFW spr_092
  DEFW spr_091
  DEFW spr_092
  DEFW spr_093
  DEFW spr_097
  DEFW spr_098
  DEFW spr_039
  DEFW spr_040
  DEFW spr_041
  DEFW spr_042
  DEFW spr_045
  DEFW spr_044
  DEFW spr_010
  DEFW spr_011
  DEFW spr_037
  DEFW spr_038
  DEFW spr_000
  DEFW spr_020
  DEFW spr_099
  DEFW spr_100
  DEFW spr_101
  DEFW spr_102
  DEFW spr_031
  DEFW spr_032
  DEFW spr_022
  DEFW spr_033
  DEFW spr_034
  DEFW spr_035
  DEFW spr_036
  DEFW spr_021
  DEFW spr_031
  DEFW spr_032
  DEFW spr_022
  DEFW spr_033
  DEFW spr_034
  DEFW spr_035
  DEFW spr_036
  DEFW spr_030
  DEFW spr_030
  DEFW spr_029
  DEFW spr_030
  DEFW spr_029
  DEFW spr_028
  DEFW spr_027
  DEFW spr_026
  DEFW spr_025
  DEFW spr_025
  DEFW spr_026
  DEFW spr_027
  DEFW spr_028
  DEFW spr_029
  DEFW spr_030
  DEFW spr_029
  DEFW spr_030
  DEFW spr_066
  DEFW spr_067
  DEFW spr_068
  DEFW spr_030
  DEFW spr_029
  DEFW spr_028
  DEFW spr_019
  DEFW spr_017
  DEFW spr_018
  DEFW spr_014
  DEFW spr_015
  DEFW spr_016
  DEFW spr_021
  DEFW spr_074
  DEFW spr_075
  DEFW spr_020
  DEFW spr_055
  DEFW spr_056
  DEFW spr_057
  DEFW spr_058
  DEFW spr_057
  DEFW spr_056
  DEFW spr_005
  DEFW spr_004
  DEFW spr_059
  DEFW spr_060
  DEFW spr_061
  DEFW spr_062
  DEFW spr_061
  DEFW spr_060
  DEFW spr_013
  DEFW spr_012
  DEFW spr_030
  DEFW spr_029
  DEFW spr_028
  DEFW spr_029
  DEFW spr_030
  DEFW spr_029
  DEFW spr_028
  DEFW spr_029
  DEFW spr_031
  DEFW spr_032
  DEFW spr_022
  DEFW spr_033
  DEFW spr_034
  DEFW spr_035
  DEFW spr_036
  DEFW spr_021
  DEFW spr_010
  DEFW spr_011
  DEFW spr_006
  DEFW spr_007
  DEFW spr_010
  DEFW spr_011
  DEFW spr_006
  DEFW spr_007
  DEFW spr_030
  DEFW spr_029
  DEFW spr_001
  DEFW spr_030

; No sprite; the sprite format
;
; Every sprite from here to spr_102 is two header bytes followed by its rows.
; Header byte 0 holds the width in bytes in bits 0 to 3; bit 6 is set while the
; rows are stored mirrored left to right and bit 7 while they are stored upside
; down. Header byte 1 is the height in rows. A row is a pair of bytes for each
; byte of width: a mask, then an image. print_sprite clears the pixels behind
; where the mask has a bit set and then ORs in the image, so each pixel is
; transparent, black or ink. The rows run from the bottom of the sprite
; upwards, because y in the screen buffer runs up the screen (calc_vram_addr
; turns it the right way up).
;
; Mirroring is done to the sprite itself. Before drawing, vflip_sprite_data
; compares bits 6 and 7 of the header with bits 6 and 7 of the object's flags
; (+7); where they differ it reverses the rows, or the pairs in each row
; (bit-reversing each byte through reverse_bits_tbl), in place, and toggles the
; header bit. So one set of pixels serves both ways round, and a snapshot
; catches each sprite in whichever way it was last drawn: of the 103, only
; spr_014, the border corner, was caught upside down. The header bits are
; state, not part of the width.
;
; This first one is empty: its width is 0, and flip_sprite, seeing the 0,
; returns from its caller without drawing anything. Types $00 and $01 use it.
spr_nul:
  DEFB $00,$00            ; Width 0, height 0

; Sun and moon window, left end
;
; display_frame draws the window in the status panel through which the sun and
; moon cross the sky, and prints this at its left end, at x = $B8. Type $5A.
spr_000:
  DEFB $03,$1F
  DEFB $FF,$1F,$FF,$00,$FF,$00
  DEFB $FF,$31
  DEFB $FF,$C0,$FF,$00,$FF,$2F,$FF,$F0
  DEFB $FF,$00,$FF,$37,$FF,$FE,$FF,$00
  DEFB $FF,$1F,$FF,$3F,$FF,$E0,$FF,$07
  DEFB $BF,$0F,$FF,$FF,$FF,$07,$8F,$03
  DEFB $FF,$FF,$FF,$07,$83,$00,$FF,$3F
  DEFB $FF,$07,$80,$00,$3F,$00,$FF,$0F
  DEFB $80,$00,$00,$00,$FF,$1D,$80,$00
  DEFB $00,$00,$FF,$3F,$80,$00,$00,$00
  DEFB $FF,$27,$80,$00,$00,$00,$FF,$07
  DEFB $80,$00,$00,$00,$FF,$27,$80,$00
  DEFB $00,$00,$FF,$3F,$80,$00,$00,$00
  DEFB $FF,$1D,$80,$00,$00,$00,$FF,$0F
  DEFB $80,$00,$00,$00,$FF,$07,$80,$00
  DEFB $00,$00,$FF,$07,$80,$00,$00,$00
  DEFB $FF,$1F,$80,$00,$00,$00,$FF,$33
  DEFB $80,$00,$00,$00,$FF,$2F,$80,$00
  DEFB $00,$00,$FF,$37,$C0,$00,$00,$00
  DEFB $FF,$19,$F0,$C0,$00,$00,$FF,$0F
  DEFB $FE,$F0,$00,$00,$FF,$03,$FF,$FE
  DEFB $E0,$00,$FF,$00,$FF,$FF,$FF,$E0
  DEFB $FF,$00,$FF,$1F,$FF,$FF,$FF,$00
  DEFB $FF,$03,$FF,$FF,$FF,$00,$FF,$00
  DEFB $FF,$3F

; Sun and moon window, right end
;
; The right-hand end of the window display_frame draws, at x = $D0. Type $BA.
spr_001:
  DEFB $03,$1F
  DEFB $FF,$00,$FF,$00,$FF,$F8
  DEFB $FF,$00
  DEFB $FF,$03,$FF,$8C,$FF,$00,$FF,$0F
  DEFB $FF,$F4,$FF,$00,$FF,$7F,$FF,$EC
  DEFB $FF,$07,$FF,$FC,$FF,$F8,$FF,$FF
  DEFB $FD,$F0,$FF,$E0,$FF,$FF,$F1,$C0
  DEFB $FF,$E0,$FF,$FC,$C1,$00,$FF,$E0
  DEFB $FC,$00,$01,$00,$FF,$E0,$00,$00
  DEFB $01,$00,$FF,$F0,$00,$00,$01,$00
  DEFB $FF,$D8,$00,$00,$01,$00,$FF,$FC
  DEFB $00,$00,$01,$00,$FF,$E4,$00,$00
  DEFB $01,$00,$FF,$E0,$00,$00,$01,$00
  DEFB $FF,$E4,$00,$00,$01,$00,$FF,$FC
  DEFB $00,$00,$01,$00,$FF,$D8,$00,$00
  DEFB $01,$00,$FF,$F0,$00,$00,$01,$00
  DEFB $FF,$E0,$00,$00,$01,$00,$FF,$E0
  DEFB $00,$00,$01,$00,$FF,$F8,$00,$00
  DEFB $01,$00,$FF,$CC,$00,$00,$01,$00
  DEFB $FF,$F4,$00,$00,$03,$00,$FF,$EC
  DEFB $00,$00,$0F,$03,$FF,$98,$00,$00
  DEFB $7F,$0F,$FF,$F0,$07,$00,$FF,$7F
  DEFB $FF,$C0,$FF,$07,$FF,$FF,$FF,$00
  DEFB $FF,$FF,$FF,$F8,$FF,$00,$FF,$FF
  DEFB $FF,$C0,$FF,$00,$FF,$FC,$FF,$00
  DEFB $FF,$00

; Spikes
;
; A bed of spikes, deadly to touch (block types 5 and 17). Type $17.
spr_002:
  DEFB $04,$1C
  DEFB $00,$00,$01,$00,$80,$00,$00,$00
  DEFB $00,$00,$07,$01,$E0,$80,$00,$00
  DEFB $00,$00,$1F,$07,$F8,$E0,$00,$00
  DEFB $00,$00,$7F,$1E,$FE,$78,$00,$00
  DEFB $01,$00,$FF,$79,$FF,$9E,$80,$00
  DEFB $07,$01,$FF,$E7,$FF,$E7,$E0,$80
  DEFB $1F,$07,$FF,$9D,$FF,$F9,$F8,$E0
  DEFB $7F,$1E,$FF,$7D,$FF,$BE,$FE,$78
  DEFB $FF,$79,$FF,$ED,$FF,$AD,$FF,$9E
  DEFB $FF,$67,$FF,$6D,$FF,$AD,$FF,$E6
  DEFB $FF,$1F,$FF,$6D,$FF,$AD,$FF,$F8
  DEFB $FF,$7F,$FF,$AD,$FF,$6B,$FF,$FE
  DEFB $FF,$5D,$FF,$AD,$FF,$6B,$FF,$BA
  DEFB $7F,$1D,$FF,$DD,$FF,$6B,$FE,$B8
  DEFB $1F,$0D,$FF,$FD,$FF,$77,$F8,$B8
  DEFB $1F,$0D,$FF,$6E,$FF,$FE,$F8,$B8
  DEFB $1F,$0D,$FF,$6F,$FF,$FC,$F8,$B0
  DEFB $1D,$08,$FF,$6D,$FF,$B6,$F8,$30
  DEFB $1C,$08,$FF,$6D,$FF,$B6,$38,$10
  DEFB $1C,$08,$FF,$65,$FF,$A6,$38,$10
  DEFB $1C,$08,$E7,$41,$EF,$86,$38,$10
  DEFB $1C,$08,$E3,$41,$C7,$82,$10,$00
  DEFB $08,$00,$E1,$40,$C7,$82,$00,$00
  DEFB $00,$00,$E1,$40,$C7,$82,$00,$00
  DEFB $00,$00,$41,$00,$C2,$80,$00,$00
  DEFB $00,$00,$01,$00,$C0,$80,$00,$00
  DEFB $00,$00,$01,$00,$C0,$80,$00,$00
  DEFB $00,$00,$00,$00,$80,$00,$00,$00

; Spiked ball
;
; The spiked ball that drops on the player (block types 18 and 19). Type $3F.
spr_003:
  DEFB $04,$19
  DEFB $00,$00,$00,$00,$80,$00,$00,$00
  DEFB $00,$00,$01,$00,$C0,$80,$00,$00
  DEFB $00,$00,$07,$00,$E2,$80,$00,$00
  DEFB $00,$00,$3F,$07,$F7,$E2,$00,$00
  DEFB $03,$00,$7F,$2F,$FF,$F4,$00,$00
  DEFB $07,$03,$FF,$13,$FE,$F4,$00,$00
  DEFB $03,$01,$FF,$6D,$FF,$EA,$00,$00
  DEFB $01,$00,$FF,$ED,$FF,$F7,$80,$00
  DEFB $01,$00,$FF,$F3,$FF,$FF,$E0,$00
  DEFB $0F,$00,$FF,$7F,$FF,$FC,$F0,$60
  DEFB $1F,$0F,$FF,$BF,$FF,$FB,$E0,$80
  DEFB $0F,$00,$FF,$7C,$FF,$F6,$C0,$00
  DEFB $03,$01,$FF,$FB,$FF,$F9,$F0,$80
  DEFB $03,$01,$FF,$FC,$FF,$FF,$F8,$F0
  DEFB $07,$01,$FF,$FF,$FF,$FF,$F0,$80
  DEFB $0F,$06,$FF,$FF,$FF,$F7,$80,$00
  DEFB $1F,$08,$FF,$CF,$FF,$EB,$80,$00
  DEFB $08,$00,$FF,$37,$FF,$F4,$00,$00
  DEFB $00,$00,$FF,$6F,$FF,$FA,$00,$00
  DEFB $01,$00,$FF,$9E,$FF,$F9,$80,$00
  DEFB $00,$00,$9F,$05,$F9,$60,$00,$00
  DEFB $00,$00,$1F,$09,$F8,$10,$00,$00
  DEFB $00,$00,$1F,$09,$9C,$08,$00,$00
  DEFB $00,$00,$0B,$01,$88,$00,$00,$00
  DEFB $00,$00,$01,$00,$00,$00,$00,$00

; Guard's body, second frame
;
; The second of the two frames of a guard's body; see spr_005. Types $1F, $97.
spr_004:
  DEFB $03,$17
  DEFB $03,$00,$7F,$00,$00,$00
  DEFB $07,$03
  DEFB $FF,$3F,$E0,$00,$0F,$07,$FF,$7F
  DEFB $F0,$E0,$0F,$03,$FF,$7F,$F8,$F0
  DEFB $1F,$0B,$FF,$7F,$F8,$F0,$1F,$0B
  DEFB $FF,$7F,$F0,$E0,$0F,$05,$FF,$01
  DEFB $F0,$E0,$0F,$06,$FF,$60,$F0,$20
  DEFB $0F,$05,$FF,$F0,$F0,$00,$07,$03
  DEFB $FF,$B0,$F8,$C0,$07,$03,$FF,$32
  DEFB $FC,$C8,$0F,$06,$FF,$BB,$FC,$28
  DEFB $0F,$05,$FF,$5C,$FC,$68,$07,$03
  DEFB $FF,$2F,$F8,$90,$07,$03,$FF,$33
  DEFB $F8,$F0,$07,$03,$FF,$3C,$F0,$60
  DEFB $03,$01,$FF,$BF,$F0,$A0,$03,$01
  DEFB $FF,$9F,$E0,$C0,$01,$00,$FF,$DF
  DEFB $E0,$C0,$00,$00,$FF,$6F,$C0,$80
  DEFB $00,$00,$7F,$37,$80,$00,$00,$00
  DEFB $3F,$1C,$00,$00,$00,$00,$1C,$00
  DEFB $00,$00

; Guard's body, first frame
;
; A guard is two objects at the same place: a body of this sprite or spr_004,
; and legs that borrow Sabreman's leg frames (types $90 to $9D). Types $1E and
; $1F walk north, east, south and west in turn (block type 13), and $96 and $97
; back and forth along x (block type 8). Types $1E, $96.
spr_005:
  DEFB $03,$17
  DEFB $01,$00,$80,$00,$00,$00
  DEFB $03,$01
  DEFB $FF,$80,$00,$00,$07,$03,$FF,$BF
  DEFB $E0,$00,$0F,$03,$FF,$7F,$F0,$E0
  DEFB $1F,$0B,$FF,$7F,$F8,$F0,$1F,$0B
  DEFB $FF,$BF,$F8,$F0,$0F,$05,$FF,$BF
  DEFB $F0,$E0,$0F,$05,$FF,$81,$F0,$E0
  DEFB $07,$00,$FF,$7E,$E0,$40,$0F,$01
  DEFB $FF,$FF,$C0,$80,$1F,$0D,$FF,$C2
  DEFB $E0,$40,$1F,$0D,$FF,$BC,$F0,$60
  DEFB $1F,$0D,$FF,$BC,$F0,$20,$0F,$05
  DEFB $FF,$BE,$F0,$40,$07,$03,$FF,$BC
  DEFB $F0,$E0,$0F,$07,$FF,$7C,$E0,$C0
  DEFB $0F,$06,$FF,$FC,$E0,$C0,$07,$01
  DEFB $FF,$FD,$C0,$80,$03,$01,$FF,$F9
  DEFB $C0,$80,$01,$00,$FF,$FB,$80,$00
  DEFB $00,$00,$FF,$76,$00,$00,$00,$00
  DEFB $7E,$38,$00,$00,$00,$00,$38,$00
  DEFB $00,$00

; Ball, first frame
;
; The ball of block types 2, 12, 23, 24 and 28. Types $B2 and $B3 share one
; handler and $B6 and $B7 another. Types $B2, $B6.
spr_006:
  DEFB $03,$13
  DEFB $00,$00,$3E,$00,$00,$00
  DEFB $00,$00
  DEFB $FF,$3E,$80,$00,$01,$00,$FF,$FF
  DEFB $C0,$80,$03,$01,$FF,$FF,$E0,$C0
  DEFB $07,$03,$FF,$FF,$F0,$E0,$0F,$07
  DEFB $FF,$FF,$F8,$F0,$0F,$07,$FF,$FF
  DEFB $F8,$F0,$1F,$0F,$FF,$FF,$FC,$F8
  DEFB $1F,$0F,$FF,$FF,$FC,$F8,$1F,$0C
  DEFB $FF,$FF,$FC,$F8,$1F,$0C,$FF,$FF
  DEFB $FC,$F8,$1F,$0C,$FF,$7F,$FC,$F8
  DEFB $0F,$06,$FF,$3F,$F8,$F0,$0F,$07
  DEFB $FF,$1F,$F8,$F0,$07,$03,$FF,$87
  DEFB $F0,$E0,$03,$01,$FF,$C7,$E0,$C0
  DEFB $01,$00,$FF,$FF,$C0,$80,$00,$00
  DEFB $FF,$3E,$80,$00,$00,$00,$3E,$00
  DEFB $00,$00

; Ball, second frame
;
; The ball's second frame; see spr_006. Types $B3, $B7.
spr_007:
  DEFB $03,$12
  DEFB $00,$00,$3E,$00,$00,$00
  DEFB $01,$00
  DEFB $FF,$3E,$C0,$00,$03,$01,$FF,$FF
  DEFB $E0,$C0,$07,$03,$FF,$FF,$F0,$E0
  DEFB $0F,$07,$FF,$FF,$F8,$F0,$1F,$0F
  DEFB $FF,$FF,$FC,$F8,$1F,$0F,$FF,$FF
  DEFB $FC,$F8,$3F,$1F,$FF,$FF,$FE,$FC
  DEFB $3F,$19,$FF,$FF,$FE,$FC,$3F,$19
  DEFB $FF,$FF,$FE,$FC,$3F,$1C,$FF,$FF
  DEFB $FE,$FC,$1F,$0C,$FF,$7F,$FC,$F8
  DEFB $1F,$0E,$FF,$3F,$FC,$F8,$0F,$07
  DEFB $FF,$07,$F8,$F0,$07,$03,$FF,$C7
  DEFB $F0,$E0,$03,$01,$FF,$FF,$E0,$C0
  DEFB $01,$00,$FF,$3E,$C0,$00,$00,$00
  DEFB $3E,$00,$00,$00

; Rock
;
; Block type 3. Type $06.
spr_008:
  DEFB $04,$1D
  DEFB $00,$00,$38,$00,$70,$00,$00,$00
  DEFB $00,$00,$7F,$38,$FC,$70,$00,$00
  DEFB $00,$00,$FF,$04,$FE,$E4,$00,$00
  DEFB $01,$00,$FF,$87,$FF,$CE,$00,$00
  DEFB $01,$00,$FF,$E7,$FF,$CE,$80,$00
  DEFB $03,$01,$FF,$47,$FF,$CE,$E0,$80
  DEFB $07,$01,$FF,$66,$FF,$1A,$F8,$60
  DEFB $3F,$06,$FF,$66,$FF,$1B,$FC,$78
  DEFB $7F,$3C,$FF,$32,$FF,$3D,$FE,$3C
  DEFB $7F,$12,$FF,$73,$FF,$3C,$FE,$3C
  DEFB $FF,$62,$FF,$E7,$FF,$1C,$FF,$32
  DEFB $FF,$62,$FF,$6D,$FF,$1E,$FF,$32
  DEFB $FF,$76,$FF,$4D,$FF,$DE,$FF,$32
  DEFB $FF,$24,$FF,$4F,$FF,$FE,$FF,$66
  DEFB $FF,$6C,$FF,$7F,$FF,$FE,$FF,$66
  DEFB $FF,$6C,$FF,$FF,$FF,$FF,$FE,$64
  DEFB $FF,$72,$FF,$FF,$FF,$FF,$FE,$E4
  DEFB $FF,$73,$FF,$FF,$FF,$FF,$FE,$F4
  DEFB $FF,$7F,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $7F,$3F,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $7F,$3F,$FF,$FF,$FF,$FF,$FF,$FE
  DEFB $3F,$1F,$FF,$FF,$FF,$FF,$FE,$FC
  DEFB $1F,$0F,$FF,$FF,$FF,$FF,$FE,$FC
  DEFB $0F,$07,$FF,$FF,$FF,$FF,$FC,$F8
  DEFB $07,$03,$FF,$FF,$FF,$FF,$F8,$E0
  DEFB $03,$00,$FF,$7F,$FF,$FF,$E0,$00
  DEFB $00,$00,$7F,$37,$FF,$FE,$00,$00
  DEFB $00,$00,$37,$03,$FE,$C0,$00,$00
  DEFB $00,$00,$03,$00,$C0,$00,$00,$00

; Gargoyle
;
; Block type 4; deadly to touch. Type $16.
spr_009:
  DEFB $03,$18
  DEFB $00,$00,$10,$00,$00,$00
  DEFB $00,$00,$7C,$10,$00,$00
  DEFB $01,$00,$FF,$7C,$00,$00
  DEFB $07,$00,$FF,$FF,$C0,$00
  DEFB $1F,$07,$FF,$E7,$F0,$C0
  DEFB $7F,$1F,$FF,$99,$FC,$F0
  DEFB $FF,$7E,$FF,$60,$FE,$7C
  DEFB $7F,$39,$FF,$9C,$FF,$1E
  DEFB $3F,$07,$FF,$7B,$FE,$A4
  DEFB $1F,$0E,$FF,$F7,$FC,$B0
  DEFB $0F,$04,$FF,$FC,$F0,$60
  DEFB $07,$03,$FF,$3E,$E0,$80
  DEFB $0F,$07,$FF,$DE,$C0,$00
  DEFB $0F,$07,$FF,$FD,$E0,$C0
  DEFB $07,$03,$FF,$F7,$F0,$60
  DEFB $03,$00,$FF,$FC,$F0,$A0
  DEFB $00,$00,$FF,$38,$F8,$90
  DEFB $00,$00,$7F,$37,$F8,$F0
  DEFB $00,$00,$7F,$3F,$F0,$E0
  DEFB $00,$00,$7F,$33,$E0,$C0
  DEFB $00,$00,$FF,$73,$C0,$80
  DEFB $00,$00,$FF,$7F,$E0,$C0
  DEFB $00,$00,$FF,$61,$E0,$C0
  DEFB $00,$00,$61,$00,$C0,$00

; Fire, first frame
;
; The flame of block types 1, 10 and 20: types $56 and $57 move along x, $B4
; and $B5 along y, and $B0 and $B1 stay put. Types $56, $B0, $B4.
spr_010:
  DEFB $02,$0F
  DEFB $1F,$0C,$F0,$00
  DEFB $1F,$0B,$F8,$F0
  DEFB $0F,$07,$FC,$F8,$1F,$0F,$FE,$7C
  DEFB $3F,$0E,$FE,$FC,$7F,$2D,$FE,$7C
  DEFB $7F,$2D,$FE,$6C,$7F,$25,$FC,$68
  DEFB $3F,$15,$FC,$68,$3F,$12,$FE,$C4
  DEFB $1F,$02,$FC,$90,$1F,$08,$F8,$90
  DEFB $1D,$08,$F0,$20,$0B,$01,$F0,$20
  DEFB $01,$00,$20,$00

; Fire, second frame
;
; The flame's second frame; see spr_010. Types $57, $B1, $B5.
spr_011:
  DEFB $02,$10
  DEFB $03,$00,$C0,$00
  DEFB $07,$03,$F8,$C0
  DEFB $0F,$07,$FC,$F8
  DEFB $0F,$05,$FE,$FC
  DEFB $1F,$0C,$FE,$DC
  DEFB $5F,$0C,$FE,$9C
  DEFB $FD,$48,$DE,$88
  DEFB $EE,$44,$DF,$82
  DEFB $EE,$44,$FF,$26
  DEFB $7F,$2F,$7E,$6C
  DEFB $3F,$0E,$7E,$6C
  DEFB $3F,$16,$7E,$64
  DEFB $3F,$12,$7E,$64
  DEFB $3F,$12,$E7,$42
  DEFB $1F,$09,$E7,$42
  DEFB $09,$00,$42,$00

; Wizard's body, second frame
;
; The second frame of spr_013. Type $9F.
spr_012:
  DEFB $03,$27
  DEFB $00,$00,$80,$00,$00,$00
  DEFB $01,$00
  DEFB $C0,$80,$00,$00,$03,$01,$C0,$80
  DEFB $04,$00,$07,$02,$C0,$80,$E0,$04
  DEFB $0F,$06,$C0,$80,$0E,$04,$0F,$06
  DEFB $C0,$80,$1F,$0A,$1F,$0E,$FF,$40
  DEFB $1F,$0A,$1F,$0C,$FF,$5F,$BF,$1A
  DEFB $1F,$0C,$FF,$5F,$FF,$92,$1F,$0C
  DEFB $FF,$5F,$FF,$B2,$3F,$1E,$FF,$5F
  DEFB $FF,$B2,$3F,$1E,$FF,$BD,$FF,$B2
  DEFB $3F,$1F,$FF,$7A,$FF,$B2,$3F,$1E
  DEFB $FF,$F2,$FF,$B2,$3F,$1E,$FF,$EA
  DEFB $FE,$BC,$3F,$1E,$FF,$CA,$FC,$F8
  DEFB $1F,$0F,$FF,$AF,$F8,$70,$1F,$0F
  DEFB $FF,$AF,$F0,$60,$0F,$07,$FF,$BF
  DEFB $F0,$60,$07,$03,$FF,$BF,$E0,$00
  DEFB $03,$01,$FF,$7F,$E0,$40,$07,$02
  DEFB $FF,$64,$F0,$A0,$07,$02,$FF,$40
  DEFB $F0,$20,$07,$02,$FF,$1B,$F0,$20
  DEFB $07,$03,$FF,$20,$F0,$A0,$07,$03
  DEFB $FF,$C0,$E0,$40,$07,$03,$FF,$FF
  DEFB $C0,$80,$07,$03,$FF,$FF,$80,$00
  DEFB $07,$03,$FF,$8F,$80,$00,$07,$03
  DEFB $FF,$16,$00,$00,$07,$03,$FE,$3C
  DEFB $00,$00,$03,$01,$FC,$78,$00,$00
  DEFB $03,$01,$F8,$70,$00,$00,$03,$01
  DEFB $F8,$F0,$00,$00,$03,$01,$F0,$E0
  DEFB $00,$00,$03,$01,$E0,$C0,$00,$00
  DEFB $03,$01,$C0,$80,$00,$00,$03,$01
  DEFB $80,$00,$00,$00,$01,$00,$00,$00
  DEFB $00,$00

; Wizard's body, first frame
;
; The wizard of room $88 (wizard), built like a guard: this body, type $9E or
; $9F, over legs of type $90. Type $9E.
spr_013:
  DEFB $03,$21
  DEFB $20,$00,$00,$00,$00,$00
  DEFB $70,$20
  DEFB $00,$00,$00,$00,$78,$30,$00,$00
  DEFB $00,$00,$7C,$38,$7F,$00,$10,$00
  DEFB $7E,$3C,$FF,$7F,$B8,$10,$7F,$3E
  DEFB $FF,$FF,$F8,$B0,$FF,$7F,$FF,$7F
  DEFB $FC,$B8,$FF,$7F,$FF,$BF,$FC,$B8
  DEFB $FF,$7F,$FF,$DF,$FE,$BC,$FF,$7F
  DEFB $FF,$DF,$FE,$7C,$FF,$7F,$FF,$EF
  DEFB $FE,$7C,$FF,$7F,$FF,$FF,$FE,$FC
  DEFB $FF,$7F,$FF,$FF,$FC,$F8,$7F,$07
  DEFB $FF,$FF,$F8,$F0,$07,$01,$FF,$FF
  DEFB $F0,$E0,$01,$00,$FF,$7C,$E0,$00
  DEFB $00,$00,$FF,$33,$F0,$E0,$01,$00
  DEFB $FF,$CF,$F8,$F0,$01,$00,$FF,$DF
  DEFB $F8,$F0,$00,$00,$FF,$3E,$F8,$70
  DEFB $00,$00,$7F,$3C,$F8,$F0,$00,$00
  DEFB $FF,$79,$FC,$F8,$00,$00,$FF,$79
  DEFB $FC,$F8,$00,$00,$FF,$78,$FC,$F8
  DEFB $00,$00,$FF,$78,$FC,$F8,$00,$00
  DEFB $7F,$3C,$FE,$7C,$00,$00,$3F,$0F
  DEFB $FE,$FC,$00,$00,$0F,$03,$FE,$FC
  DEFB $00,$00,$03,$00,$FE,$FC,$00,$00
  DEFB $00,$00,$FF,$3E,$00,$00,$00,$00
  DEFB $3F,$0E,$00,$00,$00,$00,$0F,$02
  DEFB $00,$00,$00,$00,$02,$00

; Screen border, corner
;
; print_border prints this at all four corners of the play area, with the flags
; listed at border_data asking for each corner mirrored or flipped as it needs.
; The last corner it prints is flipped upside down, which is why this is the
; one sprite whose header the snapshot catches with bit 7 set: its rows are
; stored upside down at the moment. Its width is 4. Type $89.
spr_014:
  DEFB $84,$20
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$1F,$1F,$00,$00,$03,$03
  DEFB $00,$00,$3F,$3F,$80,$80,$07,$07
  DEFB $00,$00,$7F,$7F,$C0,$C0,$0F,$0F
  DEFB $00,$00,$FB,$FB,$E0,$E0,$1F,$1F
  DEFB $01,$01,$F1,$F1,$F0,$F0,$3E,$3E
  DEFB $03,$03,$E0,$E0,$F8,$F8,$7C,$7C
  DEFB $07,$07,$C0,$C0,$7C,$7C,$F8,$F8
  DEFB $0F,$0F,$80,$80,$3D,$3D,$F0,$F0
  DEFB $1F,$1F,$00,$00,$1B,$1B,$E0,$E0
  DEFB $3E,$3E,$00,$00,$07,$07,$C0,$C0
  DEFB $3C,$3C,$00,$00,$0F,$0F,$80,$80
  DEFB $38,$38,$00,$00,$1F,$1F,$60,$60
  DEFB $3C,$3C,$00,$00,$3E,$3E,$F0,$F0
  DEFB $3E,$3E,$00,$00,$7C,$7C,$F8,$F8
  DEFB $1F,$1F,$00,$00,$F8,$F8,$7C,$7C
  DEFB $0F,$0F,$81,$81,$F0,$F0,$3E,$3E
  DEFB $07,$07,$C3,$C3,$E0,$E0,$1F,$1F
  DEFB $03,$03,$E7,$E7,$C0,$C0,$0F,$0F
  DEFB $01,$01,$F7,$F7,$80,$80,$07,$07
  DEFB $00,$00,$FB,$FB,$00,$00,$03,$03
  DEFB $00,$00,$7C,$7C,$00,$00,$00,$00
  DEFB $00,$00,$3E,$3E,$00,$00,$00,$00
  DEFB $00,$00,$DF,$DF,$00,$00,$00,$00
  DEFB $01,$01,$EF,$EF,$80,$80,$00,$00
  DEFB $03,$03,$E7,$E7,$C0,$C0,$00,$00
  DEFB $07,$07,$C3,$C3,$E0,$E0,$00,$00
  DEFB $0F,$0F,$81,$81,$F0,$F0,$00,$00
  DEFB $1F,$1F,$00,$00,$F8,$F8,$00,$00
  DEFB $3E,$3E,$00,$00,$7C,$7C,$00,$00
  DEFB $3C,$3C,$00,$00,$3C,$3C,$00,$00

; Screen border, one line of a side
;
; print_border repeats this one-row sprite 128 times, a line apart, up each
; side. Type $8A.
spr_015:
  DEFB $03,$01
  DEFB $3C,$3C,$00,$00,$3C,$3C

; Screen border, one column of the top and bottom
;
; print_border repeats this 24 times, a byte apart, along the top and the
; bottom. Type $8B.
spr_016:
  DEFB $01,$18
  DEFB $00,$00
  DEFB $00,$00
  DEFB $FF,$FF
  DEFB $FF,$FF
  DEFB $FF,$FF
  DEFB $FF,$FF
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
  DEFB $FF,$FF
  DEFB $FF,$FF
  DEFB $FF,$FF
  DEFB $FF,$FF
  DEFB $00,$00
  DEFB $00,$00

; Status panel scroll, rolled end
;
; display_panel draws the scroll round the status panel from three sprites,
; listed at panel_data; this is the tall rolled end, printed once plain and
; once mirrored. Type $87.
spr_017:
  DEFB $02,$40
  DEFB $87,$87,$F0,$F0
  DEFB $58,$58,$0C,$0C
  DEFB $20,$20,$02,$02
  DEFB $40,$40,$01,$01
  DEFB $40,$40,$01,$01
  DEFB $40,$40,$01,$01
  DEFB $40,$40,$01,$01
  DEFB $20,$20,$02,$02
  DEFB $20,$20,$02,$02
  DEFB $20,$20,$02,$02
  DEFB $10,$10,$04,$04
  DEFB $10,$10,$04,$04
  DEFB $10,$10,$04,$04
  DEFB $10,$10,$04,$04
  DEFB $10,$10,$04,$04
  DEFB $10,$10,$04,$04
  DEFB $10,$10,$04,$04
  DEFB $10,$10,$04,$04
  DEFB $10,$10,$04,$04
  DEFB $10,$10,$04,$04
  DEFB $10,$10,$04,$04
  DEFB $10,$10,$04,$04
  DEFB $10,$10,$04,$04
  DEFB $10,$10,$04,$04
  DEFB $10,$10,$04,$04
  DEFB $10,$10,$04,$04
  DEFB $10,$10,$04,$04
  DEFB $10,$10,$04,$04
  DEFB $10,$10,$04,$04
  DEFB $10,$10,$04,$04
  DEFB $10,$10,$04,$04
  DEFB $10,$10,$04,$04
  DEFB $10,$10,$04,$04
  DEFB $10,$10,$04,$04
  DEFB $10,$10,$04,$04
  DEFB $10,$10,$04,$04
  DEFB $10,$10,$04,$04
  DEFB $10,$10,$04,$04
  DEFB $10,$10,$04,$04
  DEFB $10,$10,$04,$04
  DEFB $10,$10,$04,$04
  DEFB $10,$10,$04,$04
  DEFB $10,$10,$04,$04
  DEFB $10,$10,$04,$04
  DEFB $10,$10,$04,$04
  DEFB $10,$10,$04,$04
  DEFB $20,$20,$04,$04
  DEFB $20,$20,$02,$02
  DEFB $20,$20,$02,$02
  DEFB $20,$20,$02,$02
  DEFB $40,$40,$02,$02
  DEFB $47,$47,$82,$82
  DEFB $58,$58,$F2,$F2
  DEFB $60,$60,$89,$89
  DEFB $40,$40,$85,$85
  DEFB $40,$40,$83,$83
  DEFB $20,$20,$81,$81
  DEFB $18,$18,$81,$81
  DEFB $07,$07,$81,$81
  DEFB $C0,$C0,$01,$01
  DEFB $60,$60,$02,$02
  DEFB $10,$10,$04,$04
  DEFB $0E,$0E,$18,$18
  DEFB $01,$01,$E0,$E0

; Twelve unused bytes
;
; Zeros between two sprites. Nothing in the code refers to them, and no entry
; in sprite_tbl points here; they are the only bytes between spr_nul and START
; that are not part of a sprite.
filler:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; Unused
  DEFB $00,$00,$00,$00                 ;

; Status panel scroll, curl
;
; A curl of the scroll, printed by display_panel at each end. Type $88.
spr_018:
  DEFB $02,$10
  DEFB $03,$03,$C3,$C3
  DEFB $04,$04,$2C,$2C
  DEFB $08,$08,$10,$10
  DEFB $08,$08,$10,$10
  DEFB $04,$04,$10,$10
  DEFB $07,$07,$90,$90
  DEFB $0D,$0D,$70,$70
  DEFB $09,$09,$10,$10
  DEFB $09,$09,$10,$10
  DEFB $09,$09,$E0,$E0
  DEFB $04,$04,$00,$00
  DEFB $02,$02,$00,$00
  DEFB $01,$01,$80,$80
  DEFB $00,$00,$70,$70
  DEFB $00,$00,$0C,$0C
  DEFB $00,$00,$03,$03

; Status panel scroll, slanting edge
;
; An 8-row slanting line, printed five times in a row by display_panel to make
; each slanting edge of the scroll. Type $86.
spr_019:
  DEFB $02,$08
  DEFB $00,$00,$03,$03
  DEFB $00,$00,$0C,$0C
  DEFB $00,$00,$30,$30
  DEFB $00,$00,$C0,$C0
  DEFB $03,$03,$00,$00
  DEFB $0C,$0C,$00,$00
  DEFB $30,$30,$00,$00
  DEFB $C0,$C0,$00,$00

; Stone block
;
; One cell's worth of stone block, the most used sprite in the game: type $07
; is the plain block, and $36, $37, $3E, $5B and $8F are blocks with handlers
; of their own that move, drop or collapse (see block_type_tbl). The
; end-of-game animation turns the plain blocks into type $83
; (blocks_to_rising). Types $07, $36, $37, $3E, $5B, $8F.
spr_020:
  DEFB $04,$1C
  DEFB $00,$00,$01,$00,$80,$00,$00,$00
  DEFB $00,$00,$07,$01,$E0,$80,$00,$00
  DEFB $00,$00,$1F,$06,$F8,$A0,$00,$00
  DEFB $00,$00,$7F,$1E,$FE,$50,$00,$00
  DEFB $01,$00,$FF,$7E,$FF,$AA,$80,$00
  DEFB $07,$01,$FF,$FE,$FF,$55,$E0,$00
  DEFB $1F,$07,$FF,$FE,$FF,$AA,$F8,$80
  DEFB $7F,$1F,$FF,$FE,$FF,$55,$FE,$50
  DEFB $FF,$7F,$FF,$FE,$FF,$AA,$FF,$AA
  DEFB $FF,$7F,$FF,$FE,$FF,$55,$FF,$54
  DEFB $FF,$7F,$FF,$FE,$FF,$AA,$FF,$AA
  DEFB $FF,$7F,$FF,$FE,$FF,$55,$FF,$54
  DEFB $FF,$7F,$FF,$F9,$FF,$8A,$FF,$AA
  DEFB $FF,$7F,$FF,$E7,$FF,$E5,$FF,$54
  DEFB $FF,$7F,$FF,$9F,$FF,$F8,$FF,$AA
  DEFB $FF,$7E,$FF,$7F,$FF,$FE,$FF,$54
  DEFB $FF,$79,$FF,$FF,$FF,$FF,$FF,$8A
  DEFB $FF,$67,$FF,$FF,$FF,$FF,$FF,$E4
  DEFB $FF,$5F,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $FF,$7F,$FF,$FF,$FF,$FF,$FF,$FE
  DEFB $7F,$1F,$FF,$FF,$FF,$FF,$FE,$F8
  DEFB $1F,$07,$FF,$FF,$FF,$FF,$F8,$E0
  DEFB $07,$01,$FF,$FF,$FF,$FF,$E0,$80
  DEFB $01,$00,$FF,$7F,$FF,$FE,$80,$00
  DEFB $00,$00,$7F,$1F,$FE,$F8,$00,$00
  DEFB $00,$00,$1F,$07,$F8,$E0,$00,$00
  DEFB $00,$00,$07,$01,$E0,$80,$00,$00
  DEFB $00,$00,$01,$00,$80,$00,$00,$00

; Extra-life charm and lives icon
;
; Type $67 is the eighth kind of charm (special_objs_tbl), the one the wizard
; never asks for: touching it adds a life (upd_103). print_lives_gfx prints the
; same sprite, as type $8C, as the lives icon in the status panel. Type $AF is
; the shape the cauldron would show for it (upd_160_to_163). Types $67, $8C,
; $AF.
spr_021:
  DEFB $02,$11
  DEFB $0E,$00,$38,$00
  DEFB $1F,$0E,$7C,$38
  DEFB $1F,$0B,$FC,$78,$0F,$05,$F8,$70
  DEFB $0E,$03,$F0,$60,$0F,$03,$F8,$E0
  DEFB $1F,$0D,$FC,$F8,$1F,$0D,$FC,$F8
  DEFB $1F,$0D,$FC,$F8,$1F,$0D,$FC,$F8
  DEFB $1F,$0E,$FC,$38,$0F,$05,$F8,$D0
  DEFB $07,$02,$F0,$E0,$07,$02,$F0,$E0
  DEFB $07,$02,$F0,$E0,$03,$01,$E0,$40
  DEFB $01,$00,$C0,$00

; Charm, type $62
;
; One of the seven charms the wizard asks for. By its outline (read from the
; pixels, not the code), a boot. It is type $6A as the charm travelling into
; the cauldron (upd_104_to_110), and $AA when the cauldron shows it as the one
; wanted next (upd_160_to_163). Types $62, $6A, $AA.
spr_022:
  DEFB $03,$15
  DEFB $03,$00,$E0,$00,$00,$00
  DEFB $07,$03
  DEFB $F0,$E0,$00,$00,$0F,$07,$F8,$F0
  DEFB $00,$00,$1F,$0C,$FC,$18,$00,$00
  DEFB $1F,$0B,$FE,$E4,$70,$00,$1F,$07
  DEFB $FF,$FA,$F8,$70,$1F,$0F,$FF,$FD
  DEFB $FC,$F8,$1F,$09,$FF,$FE,$FC,$18
  DEFB $1F,$0C,$FF,$EF,$FC,$E8,$0F,$06
  DEFB $FF,$DF,$F8,$70,$07,$03,$FF,$BB
  DEFB $FC,$B8,$03,$00,$BF,$1F,$F8,$B0
  DEFB $00,$00,$1F,$0B,$F8,$D0,$00,$00
  DEFB $1F,$0F,$F0,$E0,$00,$00,$1F,$0B
  DEFB $F0,$E0,$00,$00,$1F,$0C,$F8,$10
  DEFB $00,$00,$3F,$18,$FC,$08,$00,$00
  DEFB $3F,$10,$FC,$08,$00,$00,$1F,$08
  DEFB $F8,$30,$00,$00,$0F,$07,$F0,$C0
  DEFB $00,$00,$07,$00,$C0,$00

; Tree trunk beside a forest exit, first
;
; Type $04, the first of the two trunks that flank a way out of a forest room
; (tree_arch_n to tree_arch_w). Type $04.
spr_023:
  DEFB $02,$3C
  DEFB $C0,$00,$00,$00
  DEFB $F0,$C0,$00,$00
  DEFB $F8,$F0,$00,$00
  DEFB $F0,$E0,$00,$00
  DEFB $E0,$40,$00,$00
  DEFB $F0,$60,$00,$00
  DEFB $F0,$60,$00,$00
  DEFB $F0,$60,$00,$00
  DEFB $F8,$70,$00,$00
  DEFB $F8,$30,$00,$00
  DEFB $F8,$30,$00,$00
  DEFB $F8,$70,$00,$00
  DEFB $F0,$60,$00,$00
  DEFB $F0,$60,$00,$00
  DEFB $E0,$C0,$00,$00
  DEFB $E0,$C0,$00,$00
  DEFB $E0,$C0,$00,$00
  DEFB $F0,$E0,$00,$00
  DEFB $F8,$70,$00,$00
  DEFB $F8,$70,$00,$00
  DEFB $FC,$78,$00,$00
  DEFB $7C,$38,$00,$00
  DEFB $7C,$38,$00,$00
  DEFB $7C,$38,$00,$00
  DEFB $3C,$18,$00,$00
  DEFB $3C,$18,$00,$00
  DEFB $3C,$18,$00,$00
  DEFB $1C,$08,$00,$00
  DEFB $1E,$0C,$00,$00
  DEFB $3E,$1C,$00,$00
  DEFB $3E,$1C,$00,$00
  DEFB $3C,$18,$00,$00
  DEFB $7E,$38,$00,$00
  DEFB $FF,$5E,$80,$00
  DEFB $FF,$4F,$C0,$80
  DEFB $FF,$67,$E0,$80
  DEFB $FF,$63,$F0,$A0
  DEFB $FF,$77,$F0,$20
  DEFB $FF,$37,$F8,$30
  DEFB $FF,$6F,$FD,$18
  DEFB $FF,$6F,$FF,$1C
  DEFB $FF,$5E,$FF,$4E
  DEFB $FF,$5E,$FF,$46
  DEFB $FF,$5C,$FF,$66
  DEFB $FF,$5C,$FF,$23
  DEFB $FF,$43,$FF,$33
  DEFB $7F,$2C,$FF,$11
  DEFB $7F,$2C,$FF,$18
  DEFB $7F,$2C,$FF,$31
  DEFB $7F,$24,$FF,$31
  DEFB $3F,$04,$7F,$30
  DEFB $1E,$04,$7F,$30
  DEFB $0E,$04,$7B,$20
  DEFB $06,$00,$7B,$20
  DEFB $00,$00,$79,$20
  DEFB $00,$00,$38,$10
  DEFB $00,$00,$38,$10
  DEFB $00,$00,$38,$10
  DEFB $00,$00,$10,$00
  DEFB $00,$00,$00,$00

; Tree trunk beside a forest exit, second
;
; Type $05, the second trunk. Type $05.
spr_024:
  DEFB $02,$30
  DEFB $00,$00,$60,$00
  DEFB $00,$00,$F8,$60
  DEFB $03,$00,$F8,$D8
  DEFB $0F,$03,$FF,$7E
  DEFB $1F,$0C,$FF,$CD
  DEFB $1F,$0A,$FF,$8D
  DEFB $1F,$0A,$FF,$C5
  DEFB $1F,$08,$FF,$CB
  DEFB $1F,$09,$FF,$E3
  DEFB $1F,$0D,$FF,$A6
  DEFB $0F,$05,$FF,$A6
  DEFB $0F,$04,$FF,$AC
  DEFB $1F,$08,$FF,$A6
  DEFB $1F,$0C,$FF,$E2
  DEFB $0F,$05,$FF,$EA
  DEFB $0F,$05,$FF,$EA
  DEFB $1F,$0C,$FF,$EB
  DEFB $1F,$0C,$FF,$69
  DEFB $1F,$0E,$FF,$5A
  DEFB $1F,$0C,$FF,$D6
  DEFB $1F,$0D,$FF,$C6
  DEFB $1F,$0D,$FF,$56
  DEFB $3F,$1D,$FF,$96
  DEFB $3F,$19,$FF,$AE
  DEFB $3F,$13,$FF,$2E
  DEFB $7F,$26,$FF,$46
  DEFB $FF,$4C,$FF,$86
  DEFB $FF,$89,$FF,$86
  DEFB $FF,$13,$FF,$0E
  DEFB $FF,$67,$FF,$0E
  DEFB $FF,$C6,$FF,$0E
  DEFB $FF,$CE,$FE,$0C
  DEFB $FF,$8E,$FE,$4C
  DEFB $FF,$8E,$FF,$4E
  DEFB $FF,$8E,$FF,$4E
  DEFB $FF,$8E,$FF,$66
  DEFB $FF,$8E,$FF,$66
  DEFB $FF,$8E,$FF,$72
  DEFB $FF,$8F,$FF,$32
  DEFB $FF,$C7,$FF,$1A
  DEFB $FF,$C7,$FF,$9A
  DEFB $F7,$43,$FE,$98
  DEFB $F3,$61,$FC,$C8
  DEFB $F1,$20,$FC,$C8
  DEFB $70,$00,$FC,$48
  DEFB $20,$00,$7C,$28
  DEFB $00,$00,$3C,$08
  DEFB $00,$00,$08,$00

; Sparkle, size 1 of 6
;
; One of six sizes of sparkle, smallest first, shared by every kind of
; appearing and vanishing. Types $70 to $77 run from big to small as something
; vanishes (init_death_sparkles starts a death this way); $78 to $7F run from
; small to big as the player appears, at the start of a life or in a new room;
; the rest are the sparkles over the cauldron, of the end-of-game animation, of
; a collapsing block and of a charm that is lost. Types $77, $78.
spr_025:
  DEFB $03,$14
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $08,$00,$00,$00,$00,$00
  DEFB $1C,$08,$00,$00,$00,$00
  DEFB $08,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$20,$00
  DEFB $00,$00,$00,$00,$70,$20
  DEFB $00,$00,$00,$00,$20,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $10,$00,$00,$00,$00,$00
  DEFB $38,$10,$00,$00,$80,$00
  DEFB $10,$00,$11,$00,$C0,$80
  DEFB $00,$00,$38,$10,$80,$00
  DEFB $00,$00,$7C,$38,$00,$00
  DEFB $00,$00,$38,$10,$00,$00
  DEFB $00,$00,$10,$00,$00,$00
  DEFB $01,$00,$00,$00,$00,$00
  DEFB $03,$01,$80,$00,$00,$00
  DEFB $01,$00,$00,$00,$00,$00

; Sparkle, size 2 of 6
;
; One of six sizes of sparkle, smallest first, shared by every kind of
; appearing and vanishing. Types $70 to $77 run from big to small as something
; vanishes (init_death_sparkles starts a death this way); $78 to $7F run from
; small to big as the player appears, at the start of a life or in a new room;
; the rest are the sparkles over the cauldron, of the end-of-game animation, of
; a collapsing block and of a charm that is lost. Types $76, $79.
spr_026:
  DEFB $03,$15
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $08,$00
  DEFB $00,$00,$00,$00,$1C,$08,$00,$00
  DEFB $00,$00,$3E,$1C,$00,$00,$00,$00
  DEFB $1C,$08,$00,$00,$00,$00,$08,$00
  DEFB $1C,$08,$70,$20,$00,$00,$3E,$1C
  DEFB $F8,$70,$01,$00,$1C,$08,$70,$20
  DEFB $03,$01,$88,$00,$20,$00,$11,$00
  DEFB $00,$00,$00,$00,$38,$10,$00,$00
  DEFB $80,$00,$7C,$38,$11,$00,$C0,$80
  DEFB $38,$10,$3B,$11,$E0,$C0,$10,$00
  DEFB $7D,$38,$C0,$80,$00,$00,$FE,$7C
  DEFB $80,$00,$00,$00,$7C,$38,$00,$00
  DEFB $01,$00,$38,$10,$00,$00,$03,$01
  DEFB $90,$00,$00,$00,$07,$03,$C0,$80
  DEFB $00,$00,$03,$01,$80,$00,$00,$00
  DEFB $01,$00,$00,$00,$00,$00

; Sparkle, size 3 of 6
;
; One of six sizes of sparkle, smallest first, shared by every kind of
; appearing and vanishing. Types $70 to $77 run from big to small as something
; vanishes (init_death_sparkles starts a death this way); $78 to $7F run from
; small to big as the player appears, at the start of a life or in a new room;
; the rest are the sparkles over the cauldron, of the end-of-game animation, of
; a collapsing block and of a charm that is lost. Types $75, $7A.
spr_027:
  DEFB $03,$17
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00
  DEFB $00,$00,$00,$00,$08,$00,$00,$00
  DEFB $00,$00,$1C,$08,$08,$00,$00,$00
  DEFB $08,$00,$1C,$08,$00,$00,$00,$00
  DEFB $3E,$1C,$20,$00,$01,$00,$7F,$3E
  DEFB $70,$20,$03,$01,$BE,$1C,$20,$00
  DEFB $17,$03,$DC,$88,$00,$00,$3B,$11
  DEFB $88,$00,$80,$00,$7D,$38,$11,$00
  DEFB $C0,$80,$FE,$7C,$3B,$11,$E0,$C0
  DEFB $7C,$38,$7F,$3B,$F0,$E0,$38,$10
  DEFB $FF,$7D,$E0,$C0,$11,$00,$FF,$FE
  DEFB $C0,$80,$00,$00,$FE,$7C,$80,$00
  DEFB $00,$00,$7C,$38,$00,$00,$01,$00
  DEFB $38,$10,$00,$00,$03,$01,$90,$00
  DEFB $00,$00,$01,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$80,$00,$00,$00
  DEFB $01,$00,$C0,$80,$00,$00,$00,$00
  DEFB $80,$00

; Sparkle, size 4 of 6
;
; One of six sizes of sparkle, smallest first, shared by every kind of
; appearing and vanishing. Types $70 to $77 run from big to small as something
; vanishes (init_death_sparkles starts a death this way); $78 to $7F run from
; small to big as the player appears, at the start of a life or in a new room;
; the rest are the sparkles over the cauldron, of the end-of-game animation, of
; a collapsing block and of a charm that is lost. Types $74, $7B, $85, $A2,
; $A6.
spr_028:
  DEFB $03,$18
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $08,$00,$00,$00,$00,$00
  DEFB $1C,$08,$08,$00,$00,$00
  DEFB $3E,$1C,$1C,$01,$00,$00
  DEFB $1C,$08,$3E,$1C,$20,$00
  DEFB $09,$00,$7F,$3E,$70,$20
  DEFB $03,$01,$FF,$7F,$F8,$70
  DEFB $17,$03,$FF,$BE,$70,$20
  DEFB $3F,$17,$FE,$DC,$20,$00
  DEFB $7F,$3B,$DC,$88,$00,$00
  DEFB $FF,$7D,$88,$00,$80,$00
  DEFB $FF,$FE,$01,$00,$C0,$80
  DEFB $FE,$7C,$13,$01,$E0,$C0
  DEFB $7C,$38,$39,$10,$C8,$80
  DEFB $38,$10,$7C,$38,$9C,$08
  DEFB $10,$00,$38,$10,$08,$00
  DEFB $01,$00,$10,$00,$00,$00
  DEFB $03,$10,$80,$00,$00,$00
  DEFB $07,$03,$C0,$80,$00,$00
  DEFB $03,$10,$80,$00,$80,$00
  DEFB $01,$00,$09,$00,$C0,$80
  DEFB $00,$00,$1F,$09,$E0,$C0
  DEFB $00,$00,$09,$00,$C0,$80
  DEFB $00,$00,$00,$00,$80,$00

; Sparkle, size 5 of 6
;
; One of six sizes of sparkle, smallest first, shared by every kind of
; appearing and vanishing. Types $70 to $77 run from big to small as something
; vanishes (init_death_sparkles starts a death this way); $78 to $7F run from
; small to big as the player appears, at the start of a life or in a new room;
; the rest are the sparkles over the cauldron, of the end-of-game animation, of
; a collapsing block and of a charm that is lost. Types $71, $73, $7C, $7E,
; $84, $A1, $A3, $A5, $A7, $B9.
spr_029:
  DEFB $03,$18
  DEFB $08,$00,$70,$20,$00,$00
  DEFB $1C,$08,$F8,$70,$08,$00
  DEFB $3F,$1C,$FC,$F8,$3C,$08
  DEFB $7F,$36,$F8,$70,$78,$20
  DEFB $3E,$1C,$78,$20,$F8,$70
  DEFB $1C,$08,$3D,$08,$FC,$F8
  DEFB $08,$00,$3F,$1D,$FE,$FC
  DEFB $01,$00,$1D,$08,$FC,$F8
  DEFB $13,$01,$C8,$00,$F8,$70
  DEFB $39,$10,$E0,$40,$70,$40
  DEFB $7C,$38,$50,$00,$20,$00
  DEFB $FE,$7C,$38,$10,$80,$00
  DEFB $7F,$3A,$7D,$38,$C8,$80
  DEFB $3A,$10,$FE,$7C,$9C,$08
  DEFB $11,$00,$FF,$FE,$3E,$1C
  DEFB $01,$00,$FF,$7C,$1C,$08
  DEFB $03,$01,$FF,$39,$88,$00
  DEFB $07,$03,$F9,$90,$00,$00
  DEFB $0F,$07,$F0,$C0,$80,$00
  DEFB $07,$03,$C1,$80,$C0,$80
  DEFB $03,$01,$8B,$01,$E0,$C0
  DEFB $01,$00,$1F,$0B,$F0,$E0
  DEFB $00,$00,$0B,$01,$E0,$C0
  DEFB $00,$00,$01,$00,$C0,$80

; Sparkle, size 6 of 6
;
; One of six sizes of sparkle, smallest first, shared by every kind of
; appearing and vanishing. Types $70 to $77 run from big to small as something
; vanishes (init_death_sparkles starts a death this way); $78 to $7F run from
; small to big as the player appears, at the start of a life or in a new room;
; the rest are the sparkles over the cauldron, of the end-of-game animation, of
; a collapsing block and of a charm that is lost. Types $6F, $70, $72, $7D,
; $7F, $83, $A0, $A4, $B8, $BB.
spr_030:
  DEFB $03,$18
  DEFB $1C,$08,$00,$00,$08,$00
  DEFB $3E,$1C,$20,$00,$1C,$08
  DEFB $7F,$3E,$78,$20,$3E,$1C
  DEFB $FF,$7F,$BC,$08,$1C,$08
  DEFB $7F,$3E,$3E,$1C,$28,$00
  DEFB $3F,$1C,$7F,$3E,$70,$20
  DEFB $1F,$09,$FF,$7F,$F8,$70
  DEFB $0F,$03,$FF,$BE,$70,$20
  DEFB $0F,$07,$FE,$DC,$A0,$00
  DEFB $07,$03,$DD,$88,$C0,$80
  DEFB $13,$01,$8B,$01,$E0,$C0
  DEFB $3B,$10,$07,$03,$F8,$E0
  DEFB $17,$02,$13,$01,$FC,$C8
  DEFB $0F,$07,$B9,$10,$FE,$9C
  DEFB $07,$02,$7D,$38,$FF,$3E
  DEFB $03,$01,$BB,$11,$BE,$1C
  DEFB $07,$03,$D7,$83,$DC,$11
  DEFB $0F,$07,$E3,$C1,$88,$00
  DEFB $1F,$0F,$F9,$E0,$00,$00
  DEFB $0F,$07,$FC,$C8,$80,$00
  DEFB $07,$03,$FF,$9C,$C0,$80
  DEFB $03,$01,$FF,$3F,$E0,$C0
  DEFB $01,$00,$BF,$1C,$C0,$80
  DEFB $00,$00,$1C,$08,$80,$00

; Charm, type $60
;
; One of the seven charms the wizard asks for. By its outline (read from the
; pixels, not the code), a cut gem. It is type $68 as the charm travelling into
; the cauldron (upd_104_to_110), and $A8 when the cauldron shows it as the one
; wanted next (upd_160_to_163). Types $60, $68, $A8.
spr_031:
  DEFB $03,$13
  DEFB $00,$00,$7F,$08,$00,$00
  DEFB $00,$00
  DEFB $FF,$5D,$80,$00,$01,$00,$FF,$DD
  DEFB $C0,$80,$03,$01,$FF,$BE,$E0,$C0
  DEFB $03,$01,$FF,$BE,$E0,$C0,$07,$03
  DEFB $FF,$7F,$F0,$60,$0F,$07,$FF,$7F
  DEFB $F8,$70,$0F,$06,$FF,$FF,$F8,$B0
  DEFB $1F,$0E,$FF,$FF,$FC,$B8,$3F,$1D
  DEFB $FF,$FF,$FE,$5C,$3F,$1D,$FF,$00
  DEFB $FE,$AC,$7F,$37,$FF,$7F,$FF,$76
  DEFB $7F,$2F,$FF,$7F,$FF,$7A,$3F,$1E
  DEFB $FF,$80,$FE,$BC,$1F,$0D,$FF,$FF
  DEFB $FC,$D8,$0F,$03,$FF,$FF,$F8,$E0
  DEFB $03,$01,$FF,$FF,$E0,$C0,$01,$00
  DEFB $FF,$FF,$C0,$80,$00,$00,$FF,$00
  DEFB $80,$00

; Charm, type $61
;
; One of the seven charms the wizard asks for. By its outline (read from the
; pixels, not the code), a round-bodied flask. It is type $69 as the charm
; travelling into the cauldron (upd_104_to_110), and $A9 when the cauldron
; shows it as the one wanted next (upd_160_to_163). Types $61, $69, $A9.
spr_032:
  DEFB $03,$16
  DEFB $00,$00,$FF,$00,$00,$00
  DEFB $07,$00
  DEFB $FF,$FF,$E0,$00,$1F,$07,$FF,$FF
  DEFB $F8,$E0,$3F,$1E,$FF,$7E,$FC,$78
  DEFB $7F,$3E,$FF,$99,$FE,$7C,$7F,$3F
  DEFB $FF,$E7,$F8,$FC,$FF,$7F,$FF,$99
  DEFB $FF,$FE,$FF,$7E,$FF,$66,$FF,$7E
  DEFB $FF,$7E,$FF,$66,$FF,$7E,$FF,$7F
  DEFB $FF,$C3,$FF,$FE,$7F,$3F,$FF,$C3
  DEFB $FE,$FC,$7F,$3E,$FF,$E7,$FE,$7C
  DEFB $3F,$1F,$FF,$7E,$FC,$F8,$1F,$07
  DEFB $FF,$7E,$F8,$E0,$07,$00,$FF,$7E
  DEFB $E0,$00,$00,$00,$FF,$7E,$00,$00
  DEFB $00,$00,$FF,$7E,$00,$00,$00,$00
  DEFB $FF,$42,$00,$00,$01,$00,$FF,$BD
  DEFB $80,$00,$00,$00,$FF,$7E,$00,$00
  DEFB $00,$00,$7E,$3C,$00,$00,$00,$00
  DEFB $3C,$00,$00,$00

; Charm, type $63
;
; One of the seven charms the wizard asks for. By its outline (read from the
; pixels, not the code), a goblet. It is type $6B as the charm travelling into
; the cauldron (upd_104_to_110), and $AB when the cauldron shows it as the one
; wanted next (upd_160_to_163). Types $63, $6B, $AB.
spr_033:
  DEFB $03,$17
  DEFB $00,$00,$7E,$00,$00,$00
  DEFB $03,$00
  DEFB $FF,$7E,$C0,$00,$07,$01,$FF,$FF
  DEFB $E0,$C0,$0F,$01,$FF,$E7,$F0,$E0
  DEFB $1F,$0C,$FF,$DB,$F8,$F0,$0F,$06
  DEFB $FF,$3D,$F0,$E0,$07,$03,$FF,$81
  DEFB $E0,$C0,$01,$00,$FF,$5E,$80,$00
  DEFB $03,$03,$FF,$BF,$C0,$C0,$07,$03
  DEFB $FF,$7F,$E0,$C0,$0F,$06,$FF,$00
  DEFB $F0,$E0,$1F,$08,$FF,$FF,$F8,$10
  DEFB $1F,$05,$FF,$FF,$F8,$E0,$1F,$09
  DEFB $FF,$00,$FC,$F0,$3F,$18,$FF,$FF
  DEFB $FC,$18,$3F,$17,$FF,$00,$FC,$E8
  DEFB $3F,$08,$FF,$00,$FC,$10,$3F,$10
  DEFB $FF,$00,$FC,$08,$3F,$10,$FF,$00
  DEFB $FC,$08,$1F,$08,$FF,$00,$F8,$10
  DEFB $0F,$07,$FF,$00,$F0,$E0,$07,$00
  DEFB $FF,$FF,$E0,$00,$00,$00,$FF,$00
  DEFB $00,$00

; Charm, type $64
;
; One of the seven charms the wizard asks for. By its outline (read from the
; pixels, not the code), a cup with a handle. It is type $6C as the charm
; travelling into the cauldron (upd_104_to_110), and $AC when the cauldron
; shows it as the one wanted next (upd_160_to_163). Types $64, $6C, $AC.
spr_034:
  DEFB $03,$12
  DEFB $07,$00,$FC,$00,$00,$00
  DEFB $0F,$07
  DEFB $FE,$FC,$00,$00,$1F,$0E,$FF,$0E
  DEFB $00,$00,$1F,$09,$FF,$F2,$00,$00
  DEFB $0F,$07,$FF,$FC,$F8,$00,$1F,$0F
  DEFB $FF,$FE,$FC,$F8,$3F,$1F,$FF,$FF
  DEFB $FE,$7C,$7F,$3F,$FF,$FF,$FE,$8C
  DEFB $7F,$3E,$FF,$0F,$FF,$86,$FF,$71
  DEFB $FF,$F1,$FF,$C6,$FF,$4E,$FF,$0E
  DEFB $FF,$46,$FF,$30,$FF,$01,$FF,$86
  DEFB $FF,$40,$FF,$00,$FE,$5C,$FF,$40
  DEFB $FF,$00,$FC,$58,$7F,$30,$FF,$01
  DEFB $D8,$80,$3F,$0E,$FF,$0E,$80,$00
  DEFB $0F,$01,$FE,$F0,$00,$00,$01,$00
  DEFB $F0,$00,$00,$00

; Charm, type $65
;
; One of the seven charms the wizard asks for. By its outline (read from the
; pixels, not the code), a bottle. It is type $6D as the charm travelling into
; the cauldron (upd_104_to_110), and $AD when the cauldron shows it as the one
; wanted next (upd_160_to_163). Types $65, $6D, $AD.
spr_035:
  DEFB $03,$18
  DEFB $00,$00,$FE,$00,$00,$00
  DEFB $03,$00,$FF,$FE,$80,$00
  DEFB $07,$02,$FF,$FF,$C0,$80
  DEFB $0F,$04,$FF,$03,$E0,$C0
  DEFB $0F,$04,$FF,$FB,$E0,$C0
  DEFB $0F,$00,$FF,$FB,$E0,$C0
  DEFB $0F,$04,$FF,$FB,$E0,$C0
  DEFB $0F,$04,$FF,$FB,$E0,$C0
  DEFB $0F,$04,$FF,$FB,$E0,$C0
  DEFB $0F,$04,$FF,$03,$E0,$C0
  DEFB $0F,$04,$FF,$FF,$E0,$C0
  DEFB $0F,$02,$FF,$FF,$E0,$C0
  DEFB $0F,$06,$FF,$FF,$E0,$C0
  DEFB $07,$03,$FF,$7F,$C0,$80
  DEFB $07,$03,$FF,$BF,$C0,$80
  DEFB $03,$01,$FF,$BF,$80,$00
  DEFB $01,$00,$FF,$DE,$00,$00
  DEFB $00,$00,$FE,$5C,$00,$00
  DEFB $00,$00,$FE,$5C,$00,$00
  DEFB $00,$00,$FE,$44,$00,$00
  DEFB $01,$00,$FF,$BA,$00,$00
  DEFB $00,$00,$FE,$7C,$00,$00
  DEFB $00,$00,$7C,$38,$00,$00
  DEFB $00,$00,$38,$00,$00,$00

; Charm, type $66
;
; One of the seven charms the wizard asks for. By its outline (read from the
; pixels, not the code), a ball. It is type $6E as the charm travelling into
; the cauldron (upd_104_to_110), and $AE when the cauldron shows it as the one
; wanted next (upd_160_to_163). Types $66, $6E, $AE.
spr_036:
  DEFB $03,$15
  DEFB $00,$00,$FF,$00,$00,$00
  DEFB $03,$00
  DEFB $FF,$FF,$C0,$00,$07,$03,$FF,$FF
  DEFB $E0,$C0,$0F,$07,$FF,$81,$F0,$E0
  DEFB $1F,$0E,$FF,$7E,$F8,$70,$0F,$05
  DEFB $FF,$FF,$F0,$A0,$07,$03,$FF,$FF
  DEFB $E0,$C0,$0F,$07,$FF,$FF,$F0,$E0
  DEFB $0F,$07,$FF,$FF,$F0,$E0,$1F,$0F
  DEFB $FF,$FF,$F8,$F0,$1F,$0F,$FF,$FF
  DEFB $F8,$F0,$1F,$0F,$FF,$FF,$F8,$F0
  DEFB $1F,$0C,$FF,$7F,$F8,$F0,$1F,$0C
  DEFB $FF,$7F,$F8,$F0,$1F,$0C,$FF,$3F
  DEFB $F8,$F0,$0F,$06,$FF,$0F,$F0,$E0
  DEFB $0F,$07,$FF,$0F,$F0,$E0,$07,$03
  DEFB $FF,$8F,$E0,$C0,$03,$01,$FF,$FF
  DEFB $C0,$80,$01,$00,$FF,$7E,$80,$00
  DEFB $00,$00,$7E,$00,$00,$00

; Sun
;
; Type $58. toggle_day_night changes the type between $58 and $59 as day turns
; to night and back. Type $58.
spr_037:
  DEFB $02,$10
  DEFB $03,$01,$80,$00
  DEFB $23,$01,$84,$00
  DEFB $77,$20,$CE,$04
  DEFB $3F,$13,$FC,$C8
  DEFB $1F,$07,$F8,$E0
  DEFB $1F,$0F,$F8,$F0
  DEFB $3F,$1F,$FF,$F8
  DEFB $FF,$1F,$FF,$FB
  DEFB $FF,$DF,$FF,$F8
  DEFB $FF,$1F,$FC,$F8
  DEFB $3F,$0F,$F8,$F0
  DEFB $1F,$07,$F8,$E0
  DEFB $3F,$13,$FC,$C8
  DEFB $73,$20,$CE,$04
  DEFB $21,$00,$C4,$80
  DEFB $01,$00,$C0,$80

; Moon
;
; Type $59; see spr_037. Type $59.
spr_038:
  DEFB $02,$10
  DEFB $03,$00,$C0,$00
  DEFB $0F,$03,$F0,$C0
  DEFB $1F,$0F,$F8,$D0
  DEFB $3F,$1F,$FC,$38
  DEFB $7F,$1E,$FE,$FC
  DEFB $7F,$3D,$FE,$FC
  DEFB $FF,$7E,$FF,$3E
  DEFB $FF,$7F,$FF,$BE
  DEFB $FF,$7F,$FF,$BE
  DEFB $FF,$7E,$FF,$7E
  DEFB $7F,$35,$FE,$EC
  DEFB $7F,$32,$FE,$CC
  DEFB $3F,$1E,$FC,$F8
  DEFB $1F,$0F,$F8,$30
  DEFB $0F,$03,$F0,$C0
  DEFB $03,$00,$C0,$00

; Ghost, frame 1
;
; The ghost of block type 9, four frames under types $50 to $53. Type $50.
spr_039:
  DEFB $03,$14
  DEFB $00,$00,$1E,$00,$00,$00
  DEFB $00,$00,$3F,$1E,$00,$00
  DEFB $01,$00,$FF,$3F,$80,$00
  DEFB $03,$01,$FF,$FF,$80,$00
  DEFB $03,$01,$FF,$FE,$E6,$00
  DEFB $7F,$03,$FF,$FF,$FF,$66
  DEFB $FF,$7F,$FF,$FF,$FF,$FE
  DEFB $FF,$7F,$FF,$FF,$FF,$FE
  DEFB $7F,$3F,$FF,$FF,$FE,$FC
  DEFB $3F,$1F,$FF,$FF,$FE,$FC
  DEFB $1F,$0F,$FF,$E7,$FC,$F8
  DEFB $0F,$07,$FF,$0B,$F8,$F0
  DEFB $0F,$06,$FF,$9B,$F8,$F0
  DEFB $07,$02,$FF,$C7,$F0,$E0
  DEFB $07,$03,$FF,$3F,$F0,$E0
  DEFB $03,$01,$FF,$FF,$E0,$C0
  DEFB $03,$01,$FF,$FF,$C0,$80
  DEFB $01,$00,$FF,$FF,$80,$00
  DEFB $00,$00,$FF,$3C,$00,$00
  DEFB $00,$00,$3C,$00,$00,$00

; Ghost, frame 2
;
; The ghost of block type 9, four frames under types $50 to $53. Type $51.
spr_040:
  DEFB $03,$13
  DEFB $00,$00,$1C,$00,$00,$00
  DEFB $00,$00
  DEFB $3E,$1C,$00,$00,$07,$00,$3F,$1E
  DEFB $38,$00,$0F,$07,$FF,$3F,$FC,$38
  DEFB $1F,$0F,$FF,$FF,$FC,$F8,$0F,$07
  DEFB $FF,$FF,$FE,$F8,$7F,$07,$FF,$FF
  DEFB $FF,$FE,$FF,$7F,$FF,$FF,$FF,$FE
  DEFB $FF,$7F,$FF,$FF,$FF,$FE,$7F,$3F
  DEFB $FF,$FF,$FE,$FC,$3F,$1F,$FF,$E7
  DEFB $FC,$F8,$1F,$0F,$FF,$0B,$FC,$F8
  DEFB $0F,$06,$FF,$9B,$F8,$F0,$0F,$06
  DEFB $FF,$C7,$F8,$F0,$0F,$07,$FF,$3F
  DEFB $F8,$F0,$07,$03,$FF,$FF,$F0,$E0
  DEFB $03,$01,$FF,$FF,$E0,$80,$01,$00
  DEFB $FF,$3C,$80,$00,$00,$00,$3C,$00
  DEFB $00,$00

; Ghost, frame 3
;
; The ghost of block type 9, four frames under types $50 to $53. Type $52.
spr_041:
  DEFB $03,$14
  DEFB $00,$00,$06,$00,$00,$00
  DEFB $03,$00,$1F,$06,$00,$00
  DEFB $07,$03,$FF,$1F,$F0,$00
  DEFB $0F,$07,$FF,$FF,$F8,$F0
  DEFB $3F,$0F,$FF,$FF,$F8,$F0
  DEFB $7F,$3F,$FF,$FF,$FC,$F0
  DEFB $FF,$7F,$FF,$FF,$FE,$FC
  DEFB $FF,$7F,$FF,$FF,$FF,$FE
  DEFB $7F,$3F,$FF,$FF,$FF,$FE
  DEFB $3F,$1F,$FF,$FF,$FE,$FC
  DEFB $1F,$0F,$FF,$FF,$FC,$F8
  DEFB $0F,$07,$FF,$FF,$FC,$98
  DEFB $0F,$07,$FF,$FF,$F8,$50
  DEFB $07,$03,$FF,$FF,$F0,$20
  DEFB $07,$03,$FF,$FF,$F0,$20
  DEFB $03,$01,$FF,$FF,$E0,$C0
  DEFB $03,$01,$FF,$FF,$C0,$80
  DEFB $01,$00,$FF,$FF,$80,$00
  DEFB $00,$00,$FF,$3C,$00,$00
  DEFB $00,$00,$3C,$00,$00,$00

; Ghost, frame 4
;
; The ghost of block type 9, four frames under types $50 to $53. Type $53.
spr_042:
  DEFB $03,$14
  DEFB $00,$00,$1E,$00,$00,$00
  DEFB $00,$00,$3F,$1E,$00,$00
  DEFB $1E,$00,$7F,$3F,$F0,$00
  DEFB $3F,$1E,$7F,$3F,$F8,$30
  DEFB $1F,$0F,$FF,$3F,$FC,$F8
  DEFB $3F,$0F,$FF,$FF,$FC,$F8
  DEFB $7F,$3F,$FF,$FF,$FE,$FC
  DEFB $FF,$7F,$FF,$FF,$FF,$FE
  DEFB $7F,$3F,$FF,$FF,$FF,$FE
  DEFB $3F,$1F,$FF,$FF,$FE,$FC
  DEFB $1F,$0F,$FF,$FF,$FC,$F8
  DEFB $0F,$07,$FF,$FF,$FC,$98
  DEFB $0F,$07,$FF,$FF,$F8,$50
  DEFB $07,$03,$FF,$FF,$F0,$20
  DEFB $07,$03,$FF,$FF,$F0,$20
  DEFB $03,$01,$FF,$FF,$E0,$C0
  DEFB $03,$01,$FF,$FF,$C0,$80
  DEFB $01,$00,$FF,$FF,$80,$00
  DEFB $00,$00,$FF,$3C,$00,$00
  DEFB $00,$00,$3C,$00,$00,$00

; Portcullis
;
; Type $08, the portcullis of the doorways (gate_n to gate_w) and of block
; types 26 and 27; type $09 is the same thing while it moves. Types $08, $09.
spr_043:
  DEFB $03,$2A
  DEFB $30,$00,$00,$00,$00,$00
  DEFB $78,$30
  DEFB $00,$00,$00,$00,$F8,$70,$00,$00
  DEFB $00,$00,$7C,$18,$C0,$00,$00,$00
  DEFB $79,$20,$E0,$C0,$00,$00,$7B,$31
  DEFB $E0,$C0,$00,$00,$F9,$70,$F3,$60
  DEFB $00,$00,$FF,$78,$E7,$83,$80,$00
  DEFB $7F,$3E,$EF,$C7,$80,$00,$7F,$37
  DEFB $E7,$C1,$CC,$80,$7F,$31,$FF,$E2
  DEFB $9E,$0C,$F9,$70,$FF,$FB,$BE,$1C
  DEFB $FF,$78,$FF,$DF,$9F,$06,$7F,$3E
  DEFB $FF,$C7,$FE,$88,$7F,$37,$E7,$C3
  DEFB $FE,$EC,$7F,$31,$FF,$E3,$FE,$7C
  DEFB $F9,$70,$FF,$FB,$FF,$1E,$FF,$78
  DEFB $FF,$DF,$9F,$0E,$7F,$3E,$FF,$C7
  DEFB $FE,$8C,$7F,$37,$E7,$C3,$FE,$EC
  DEFB $7F,$31,$FF,$E3,$FE,$7C,$F9,$70
  DEFB $FF,$FB,$FF,$1E,$FF,$78,$FF,$DF
  DEFB $9F,$0E,$7F,$3E,$FF,$C7,$FE,$8C
  DEFB $7F,$37,$E7,$C3,$FE,$EC,$7F,$31
  DEFB $FF,$E3,$FE,$7C,$F9,$70,$FF,$FB
  DEFB $FF,$1E,$FF,$78,$FF,$DF,$9F,$0E
  DEFB $7F,$3E,$FF,$C7,$FE,$8C,$7F,$37
  DEFB $E7,$C3,$FE,$EC,$7F,$31,$FF,$E3
  DEFB $FE,$7C,$79,$30,$FF,$FB,$FF,$1E
  DEFB $39,$10,$FF,$DF,$9F,$0E,$11,$00
  DEFB $FF,$C7,$FE,$8C,$01,$00,$E7,$C3
  DEFB $FE,$EC,$00,$00,$E7,$43,$FE,$7C
  DEFB $00,$00,$47,$03,$FF,$1E,$00,$00
  DEFB $07,$03,$9F,$0E,$00,$00,$03,$01
  DEFB $9E,$0C,$00,$00,$01,$00,$1E,$0C
  DEFB $00,$00,$00,$00,$0E,$04,$00,$00
  DEFB $00,$00,$04,$00

; Chest
;
; Block type 6. Type $55.
spr_044:
  DEFB $04,$1D
  DEFB $00,$00,$00,$00,$38,$00,$00,$00
  DEFB $00,$00,$00,$00,$FE,$38,$00,$00
  DEFB $00,$00,$03,$00,$FF,$DA,$80,$00
  DEFB $00,$00,$0F,$03,$FF,$57,$E0,$80
  DEFB $00,$00,$3F,$0F,$FF,$8F,$F8,$E0
  DEFB $00,$00,$FF,$33,$FF,$DF,$FE,$F8
  DEFB $03,$00,$FF,$F3,$FF,$DF,$FF,$F6
  DEFB $0F,$03,$FF,$F3,$FF,$DF,$FF,$FA
  DEFB $3F,$0D,$FF,$F3,$FF,$DF,$FF,$FC
  DEFB $7F,$39,$FF,$F3,$FF,$DF,$FF,$FE
  DEFB $FF,$59,$FF,$F3,$FF,$DF,$FF,$FE
  DEFB $FF,$59,$FF,$B3,$FF,$DF,$FF,$FE
  DEFB $FF,$39,$FF,$93,$FF,$07,$FF,$FE
  DEFB $FF,$79,$FF,$1C,$FF,$B9,$FF,$FE
  DEFB $FF,$79,$FF,$73,$FF,$BE,$FF,$7E
  DEFB $FF,$79,$FF,$CF,$FF,$DF,$FF,$9E
  DEFB $FF,$7B,$FF,$33,$FF,$9F,$FF,$E6
  DEFB $FF,$7C,$FF,$F0,$FF,$6F,$FF,$FA
  DEFB $FF,$73,$FF,$F9,$FF,$C7,$FF,$FE
  DEFB $FF,$4D,$FF,$E0,$FF,$39,$FE,$FC
  DEFB $FF,$38,$FF,$9C,$FF,$7E,$FC,$30
  DEFB $7F,$3C,$FF,$F2,$FF,$3F,$F0,$C0
  DEFB $7F,$38,$FF,$0F,$FF,$0F,$C0,$00
  DEFB $3F,$16,$FF,$3F,$FF,$C4,$00,$00
  DEFB $3F,$1C,$FF,$1F,$FC,$F0,$00,$00
  DEFB $1F,$0B,$FF,$87,$F0,$C0,$00,$00
  DEFB $0F,$07,$FF,$E3,$C0,$00,$00,$00
  DEFB $07,$01,$FF,$FC,$00,$00,$00,$00
  DEFB $01,$00,$FC,$00,$00,$00,$00,$00

; Table
;
; Block type 7. Type $54.
spr_045:
  DEFB $04,$1F
  DEFB $00,$00,$0C,$00,$00,$00,$00,$00
  DEFB $00,$00,$1E,$0C,$00,$00,$00,$00
  DEFB $00,$00,$3E,$14,$00,$00,$00,$00
  DEFB $00,$00,$3E,$14,$00,$00,$00,$00
  DEFB $00,$00,$3E,$14,$00,$00,$00,$00
  DEFB $18,$00,$3E,$14,$00,$00,$00,$00
  DEFB $3C,$18,$3E,$14,$00,$00,$00,$00
  DEFB $7C,$28,$3E,$14,$00,$00,$0C,$00
  DEFB $7C,$28,$3E,$14,$00,$00,$1E,$0C
  DEFB $7C,$28,$3E,$14,$00,$00,$3E,$14
  DEFB $7C,$28,$3E,$14,$00,$00,$3E,$14
  DEFB $7C,$28,$3E,$04,$00,$00,$3E,$14
  DEFB $7C,$28,$7E,$18,$18,$00,$3E,$14
  DEFB $7C,$28,$FF,$66,$BC,$18,$3E,$14
  DEFB $7F,$29,$FF,$99,$FC,$88,$3E,$14
  DEFB $7F,$26,$FF,$7E,$FC,$60,$3E,$14
  DEFB $7F,$19,$FF,$FF,$FE,$98,$3E,$14
  DEFB $FF,$67,$FF,$FF,$FF,$E6,$BE,$14
  DEFB $FF,$9F,$FF,$FF,$FF,$F9,$FE,$94
  DEFB $FF,$FF,$FF,$FF,$FF,$FE,$FE,$64
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FE,$98
  DEFB $FF,$7F,$FF,$FF,$FF,$FF,$FF,$E6
  DEFB $7F,$1F,$FF,$FF,$FF,$FF,$FF,$F9
  DEFB $1F,$07,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $07,$01,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $01,$00,$FF,$7F,$FF,$FF,$FF,$FC
  DEFB $00,$00,$7F,$1F,$FF,$FF,$FC,$F0
  DEFB $00,$00,$1F,$07,$FF,$FF,$F0,$C0
  DEFB $00,$00,$07,$01,$FF,$FF,$C0,$00
  DEFB $00,$00,$01,$00,$FF,$7C,$00,$00
  DEFB $00,$00,$00,$00,$7C,$10,$00,$00

; Sabreman's head and shoulders, view A, frame 3
;
; Sabreman's head and shoulders, types $20 to $2F, drawn 12 units above the
; legs. The type follows the legs' type plus $10 (set_top_sprite); the two
; occasional frames, $x6 and $x7, are given instead now and then, at random,
; and held for eight frames. Types $22, $24.
spr_046:
  DEFB $03,$18
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$0E,$00,$00,$00
  DEFB $0E,$00,$3F,$0E,$F8,$20
  DEFB $3F,$0E,$FF,$3F,$FC,$B8
  DEFB $7F,$3D,$FF,$DF,$FC,$88
  DEFB $FF,$7B,$FF,$DF,$F8,$D0
  DEFB $FF,$63,$FF,$FF,$FC,$F8
  DEFB $63,$01,$FF,$FF,$F8,$80
  DEFB $01,$00,$FF,$FC,$F8,$70
  DEFB $00,$00,$FF,$73,$FC,$F8
  DEFB $01,$00,$FF,$CF,$FE,$FC
  DEFB $01,$00,$FF,$DF,$FE,$8C
  DEFB $00,$00,$FF,$3E,$FC,$78
  DEFB $00,$00,$FF,$79,$F8,$70
  DEFB $01,$00,$FF,$F7,$FC,$B8
  DEFB $03,$01,$FF,$E7,$F8,$B0
  DEFB $03,$01,$FF,$EB,$F8,$A0
  DEFB $01,$00,$FF,$EC,$F8,$50
  DEFB $00,$00,$FF,$6F,$F0,$A0
  DEFB $00,$00,$6F,$07,$E0,$00
  DEFB $00,$00,$07,$00,$00,$00

; Sabreman's head and shoulders, view B, frame 2
;
; Sabreman's head and shoulders, types $20 to $2F, drawn 12 units above the
; legs. The type follows the legs' type plus $10 (set_top_sprite); the two
; occasional frames, $x6 and $x7, are given instead now and then, at random,
; and held for eight frames. Types $29, $2D.
spr_047:
  DEFB $03,$19
  DEFB $03,$00,$00,$00,$00,$00
  DEFB $07,$03
  DEFB $80,$00,$00,$00,$0F,$07,$80,$00
  DEFB $00,$00,$0F,$07,$80,$00,$00,$00
  DEFB $1F,$0E,$38,$00,$04,$00,$1F,$0E
  DEFB $FF,$38,$0E,$04,$3F,$18,$FF,$FF
  DEFB $9F,$0E,$3F,$17,$FF,$7F,$FE,$1C
  DEFB $1F,$0F,$FF,$7E,$FC,$E8,$1F,$0F
  DEFB $FF,$FE,$F8,$E0,$0F,$07,$FF,$FF
  DEFB $E0,$C0,$07,$03,$FF,$F1,$E0,$C0
  DEFB $0F,$05,$FF,$C0,$C0,$80,$1F,$08
  DEFB $FF,$46,$E0,$40,$1F,$08,$FF,$06
  DEFB $F0,$20,$0F,$04,$FF,$15,$F8,$10
  DEFB $07,$02,$FF,$1B,$FC,$08,$0F,$05
  DEFB $FF,$80,$FC,$08,$0F,$06,$FF,$60
  DEFB $F8,$30,$07,$02,$FF,$9F,$F0,$C0
  DEFB $07,$02,$FF,$E0,$C0,$00,$03,$01
  DEFB $FF,$77,$80,$00,$01,$00,$FF,$AE
  DEFB $00,$00,$00,$00,$FE,$58,$00,$00
  DEFB $00,$00,$78,$00,$00,$00

; Sabreman's head and shoulders, view A, occasional frame
;
; Sabreman's head and shoulders, types $20 to $2F, drawn 12 units above the
; legs. The type follows the legs' type plus $10 (set_top_sprite); the two
; occasional frames, $x6 and $x7, are given instead now and then, at random,
; and held for eight frames. Type $26.
spr_048:
  DEFB $03,$19
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $0F,$00,$0E,$00,$20,$00,$3F,$0F
  DEFB $BF,$0E,$F0,$20,$7F,$3E,$FF,$BF
  DEFB $F0,$A0,$7F,$35,$FF,$DF,$F8,$B0
  DEFB $3F,$03,$FF,$DF,$FC,$C8,$07,$03
  DEFB $FF,$FF,$F8,$F0,$03,$00,$FF,$FF
  DEFB $F8,$F0,$01,$00,$FF,$3F,$FC,$E0
  DEFB $03,$01,$FF,$C7,$FE,$9C,$03,$01
  DEFB $FF,$B0,$FF,$7E,$01,$00,$FF,$71
  DEFB $FF,$FE,$00,$00,$FF,$67,$FE,$C4
  DEFB $00,$00,$7F,$1E,$FC,$38,$00,$00
  DEFB $FF,$79,$FE,$BC,$01,$00,$FF,$F7
  DEFB $FE,$BC,$03,$01,$FF,$EB,$FC,$B8
  DEFB $03,$01,$FF,$DC,$FC,$D8,$01,$00
  DEFB $FF,$DE,$F8,$50,$00,$00,$FF,$1F
  DEFB $F0,$A0,$00,$00,$1F,$07,$E0,$C0
  DEFB $00,$00,$07,$00,$C0,$00

; Sabreman's head and shoulders, view A, frame 4
;
; Sabreman's head and shoulders, types $20 to $2F, drawn 12 units above the
; legs. The type follows the legs' type plus $10 (set_top_sprite); the two
; occasional frames, $x6 and $x7, are given instead now and then, at random,
; and held for eight frames. Type $23.
spr_049:
  DEFB $03,$18
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$1C,$00
  DEFB $00,$00,$0E,$00,$7E,$1C
  DEFB $18,$00,$7F,$0E,$FE,$7C
  DEFB $3D,$18,$FF,$7F,$FE,$A8
  DEFB $3F,$1D,$FF,$BF,$FE,$84
  DEFB $7F,$3B,$FF,$DF,$FC,$D8
  DEFB $7F,$37,$FF,$FF,$FC,$F8
  DEFB $F7,$63,$FF,$FF,$F8,$80
  DEFB $F3,$61,$FF,$FC,$F8,$70
  DEFB $61,$00,$FF,$73,$FC,$F8
  DEFB $01,$00,$FF,$CF,$FE,$FC
  DEFB $01,$00,$FF,$DF,$FE,$8C
  DEFB $00,$00,$FF,$3E,$FC,$78
  DEFB $00,$00,$FF,$79,$F8,$70
  DEFB $01,$00,$FF,$F7,$FC,$B8
  DEFB $03,$01,$FF,$E7,$F8,$B0
  DEFB $03,$01,$FF,$EB,$F8,$A0
  DEFB $01,$00,$FF,$EC,$F8,$50
  DEFB $00,$00,$FF,$6F,$F0,$A0
  DEFB $00,$00,$6F,$07,$E0,$00
  DEFB $00,$00,$07,$00,$00,$00

; Sabreman's head and shoulders, view A, frame 1
;
; Sabreman's head and shoulders, types $20 to $2F, drawn 12 units above the
; legs. The type follows the legs' type plus $10 (set_top_sprite); the two
; occasional frames, $x6 and $x7, are given instead now and then, at random,
; and held for eight frames. Type $20.
spr_050:
  DEFB $03,$18
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $03,$00,$80,$00,$00,$00
  DEFB $0F,$03,$CE,$80,$00,$00
  DEFB $1F,$0F,$FF,$8E,$80,$00
  DEFB $3F,$1C,$FF,$6F,$C0,$80
  DEFB $3F,$11,$FF,$EF,$E0,$C0
  DEFB $13,$01,$FF,$EF,$F0,$E0
  DEFB $01,$00,$FF,$FF,$F0,$E0
  DEFB $01,$00,$FF,$FF,$F0,$80
  DEFB $00,$00,$FF,$7C,$F8,$70
  DEFB $00,$00,$FF,$73,$FC,$F8
  DEFB $01,$00,$FF,$CF,$FE,$FC
  DEFB $01,$00,$FF,$DF,$FE,$8C
  DEFB $00,$00,$FF,$3E,$FC,$78
  DEFB $00,$00,$FF,$79,$F8,$70
  DEFB $01,$00,$FF,$F7,$FC,$B8
  DEFB $03,$01,$FF,$E7,$F8,$B0
  DEFB $03,$01,$FF,$EB,$F8,$A0
  DEFB $01,$00,$FF,$EC,$F8,$50
  DEFB $00,$00,$FF,$6F,$F0,$A0
  DEFB $00,$00,$6F,$07,$E0,$00
  DEFB $00,$00,$07,$00,$00,$00

; Sabreman's head and shoulders, view A, frame 2
;
; Sabreman's head and shoulders, types $20 to $2F, drawn 12 units above the
; legs. The type follows the legs' type plus $10 (set_top_sprite); the two
; occasional frames, $x6 and $x7, are given instead now and then, at random,
; and held for eight frames. Types $21, $25.
spr_051:
  DEFB $03,$18
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $07,$00,$0E,$00,$60,$00
  DEFB $1F,$07,$DF,$0E,$F0,$60
  DEFB $3F,$1E,$FF,$5F,$F0,$A0
  DEFB $7F,$39,$FF,$DF,$F8,$90
  DEFB $7F,$23,$FF,$DF,$F0,$E0
  DEFB $23,$01,$FF,$FF,$F8,$F0
  DEFB $01,$00,$FF,$FF,$F0,$80
  DEFB $01,$00,$FF,$FC,$F8,$70
  DEFB $00,$00,$FF,$73,$FC,$F8
  DEFB $01,$00,$FF,$CF,$FE,$FC
  DEFB $01,$00,$FF,$DF,$FE,$9C
  DEFB $00,$00,$FF,$3E,$FC,$78
  DEFB $00,$00,$FF,$79,$F8,$70
  DEFB $01,$00,$FF,$F7,$FC,$B8
  DEFB $03,$01,$FF,$E7,$F8,$B0
  DEFB $03,$01,$FF,$EB,$F8,$A0
  DEFB $01,$00,$FF,$EC,$F8,$50
  DEFB $00,$00,$FF,$6F,$F0,$A0
  DEFB $00,$00,$6F,$07,$E0,$00
  DEFB $00,$00,$07,$00,$00,$00

; Sabreman's head and shoulders, view B, frame 1
;
; Sabreman's head and shoulders, types $20 to $2F, drawn 12 units above the
; legs. The type follows the legs' type plus $10 (set_top_sprite); the two
; occasional frames, $x6 and $x7, are given instead now and then, at random,
; and held for eight frames. Type $28.
spr_052:
  DEFB $03,$19
  DEFB $01,$00,$C0,$00,$00,$00
  DEFB $03,$01
  DEFB $E0,$C0,$00,$00,$07,$03,$C0,$80
  DEFB $00,$00,$0F,$07,$80,$00,$00,$00
  DEFB $0F,$07,$B8,$00,$00,$00,$1F,$0F
  DEFB $FF,$38,$08,$00,$1F,$0C,$FF,$7F
  DEFB $9C,$08,$0F,$03,$FF,$BF,$BE,$1C
  DEFB $1F,$0F,$FF,$BE,$FC,$B8,$1F,$0F
  DEFB $FF,$FE,$F8,$D0,$0F,$07,$FF,$FF
  DEFB $F0,$C0,$07,$03,$FF,$F1,$E0,$C0
  DEFB $0F,$05,$FF,$C0,$C0,$80,$1F,$08
  DEFB $FF,$46,$E0,$40,$1F,$08,$FF,$06
  DEFB $F0,$20,$0F,$04,$FF,$15,$F8,$10
  DEFB $07,$02,$FF,$1B,$FC,$08,$0F,$05
  DEFB $FF,$80,$FC,$08,$0F,$06,$FF,$60
  DEFB $F8,$30,$07,$02,$FF,$9F,$F0,$C0
  DEFB $07,$02,$FF,$E0,$C0,$00,$03,$01
  DEFB $FF,$77,$80,$00,$01,$00,$FF,$AE
  DEFB $00,$00,$00,$00,$FE,$58,$00,$00
  DEFB $00,$00,$78,$00,$00,$00

; Sabreman's head and shoulders, view B, frame 4
;
; Sabreman's head and shoulders, types $20 to $2F, drawn 12 units above the
; legs. The type follows the legs' type plus $10 (set_top_sprite); the two
; occasional frames, $x6 and $x7, are given instead now and then, at random,
; and held for eight frames. Type $2B.
spr_053:
  DEFB $03,$19
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00
  DEFB $00,$00,$00,$00,$0C,$00,$00,$00
  DEFB $00,$00,$1E,$0C,$00,$00,$06,$00
  DEFB $3E,$1C,$38,$00,$0F,$06,$3E,$18
  DEFB $FF,$38,$3F,$0E,$7F,$38,$FF,$FF
  DEFB $FE,$3C,$7F,$37,$FF,$FF,$FC,$58
  DEFB $7F,$2F,$FF,$7E,$F8,$E0,$3F,$1F
  DEFB $FF,$FE,$F8,$F0,$3F,$1F,$FF,$FF
  DEFB $F0,$E0,$1F,$07,$FF,$F1,$E0,$C0
  DEFB $0F,$05,$FF,$C0,$C0,$80,$1F,$08
  DEFB $FF,$46,$E0,$40,$1F,$08,$FF,$06
  DEFB $F0,$20,$0F,$04,$FF,$15,$F8,$10
  DEFB $07,$02,$FF,$1B,$FC,$08,$0F,$05
  DEFB $FF,$80,$FC,$08,$0F,$06,$FF,$60
  DEFB $F8,$30,$07,$02,$FF,$9F,$F0,$C0
  DEFB $07,$02,$FF,$E0,$C0,$00,$03,$01
  DEFB $FF,$77,$80,$00,$01,$00,$FF,$AE
  DEFB $00,$00,$00,$00,$FE,$58,$00,$00
  DEFB $00,$00,$78,$00,$00,$00

; Sabreman's head and shoulders, view B, frame 3
;
; Sabreman's head and shoulders, types $20 to $2F, drawn 12 units above the
; legs. The type follows the legs' type plus $10 (set_top_sprite); the two
; occasional frames, $x6 and $x7, are given instead now and then, at random,
; and held for eight frames. Types $2A, $2C.
spr_054:
  DEFB $03,$19
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $06,$00
  DEFB $00,$00,$00,$00,$0F,$06,$00,$00
  DEFB $00,$00,$1F,$0E,$00,$00,$06,$00
  DEFB $3E,$1C,$38,$00,$1F,$06,$3E,$1C
  DEFB $FF,$38,$3F,$1E,$3F,$18,$FF,$FF
  DEFB $FF,$3C,$7F,$36,$FF,$FF,$FE,$58
  DEFB $3F,$0F,$FF,$7E,$F8,$E0,$3F,$1F
  DEFB $FF,$FE,$F8,$F0,$1F,$0F,$FF,$FF
  DEFB $F0,$E0,$0F,$07,$FF,$F1,$E0,$C0
  DEFB $0F,$05,$FF,$C0,$C0,$80,$1F,$08
  DEFB $FF,$46,$E0,$40,$1F,$08,$FF,$06
  DEFB $F0,$20,$0F,$04,$FF,$15,$F8,$10
  DEFB $07,$02,$FF,$1B,$FC,$08,$0F,$05
  DEFB $FF,$80,$FC,$08,$0F,$06,$FF,$60
  DEFB $F8,$30,$07,$02,$FF,$9F,$F0,$C0
  DEFB $07,$02,$FF,$E0,$C0,$00,$03,$01
  DEFB $FF,$77,$80,$00,$01,$00,$FF,$AE
  DEFB $00,$00,$00,$00,$FE,$58,$00,$00
  DEFB $00,$00,$78,$00,$00,$00

; Legs, view A, frame 1
;
; Sabreman's legs by day, and the legs of the guards and the wizard (types $90
; to $9D). A walk plays frames 1 2 3 4 3 2: animate_human_legs steps the low
; three bits of the type round 0 to 5. View A is the types with bit 3 clear,
; view B those with it set. Types $10, $90.
spr_055:
  DEFB $03,$10
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$E0,$00
  DEFB $00,$00,$03,$00,$F0,$E0
  DEFB $06,$00,$0F,$03,$F0,$E0
  DEFB $3F,$06,$1F,$0F,$F0,$E0
  DEFB $7F,$3F,$9F,$0E,$F0,$00
  DEFB $FF,$7F,$9F,$0D,$E0,$C0
  DEFB $FF,$78,$3F,$01,$C0,$80
  DEFB $7F,$36,$7B,$30,$80,$00
  DEFB $3F,$06,$FF,$7B,$E0,$80
  DEFB $0F,$06,$FF,$FD,$F0,$F0
  DEFB $0F,$05,$FF,$FE,$F0,$E0
  DEFB $07,$03,$FF,$FE,$E0,$C0
  DEFB $03,$00,$FF,$FF,$E0,$C0

; Legs, view A, frame 2
;
; Sabreman's legs by day, and the legs of the guards and the wizard (types $90
; to $9D). A walk plays frames 1 2 3 4 3 2: animate_human_legs steps the low
; three bits of the type round 0 to 5. View A is the types with bit 3 clear,
; view B those with it set. Types $11, $15, $91, $95.
spr_056:
  DEFB $03,$10
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$C0,$00,$00,$00
  DEFB $07,$00,$E3,$C0,$80,$00
  DEFB $0F,$07,$FF,$E3,$C0,$80
  DEFB $1F,$0F,$FF,$EF,$C0,$80
  DEFB $1F,$0F,$FF,$1F,$C0,$80
  DEFB $0F,$06,$FF,$D7,$80,$00
  DEFB $07,$00,$FF,$C9,$80,$00
  DEFB $01,$00,$FF,$DC,$80,$00
  DEFB $01,$00,$FF,$BD,$C0,$80
  DEFB $01,$00,$FF,$7E,$E0,$C0
  DEFB $03,$01,$FF,$FE,$E0,$C0
  DEFB $01,$00,$FF,$FE,$E0,$C0
  DEFB $00,$00,$FF,$7F,$E0,$C0

; Legs, view A, frame 3
;
; Sabreman's legs by day, and the legs of the guards and the wizard (types $90
; to $9D). A walk plays frames 1 2 3 4 3 2: animate_human_legs steps the low
; three bits of the type round 0 to 5. View A is the types with bit 3 clear,
; view B those with it set. Types $12, $14, $92, $94.
spr_057:
  DEFB $03,$10
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$18,$00,$00,$00
  DEFB $00,$00,$FC,$18,$00,$00
  DEFB $01,$00,$FE,$FC,$00,$00
  DEFB $03,$01,$FE,$FC,$00,$00
  DEFB $03,$01,$FF,$E2,$00,$00
  DEFB $01,$00,$FF,$DA,$00,$00
  DEFB $01,$00,$FF,$36,$00,$00
  DEFB $03,$01,$FE,$60,$00,$00
  DEFB $03,$01,$FF,$4E,$80,$00
  DEFB $01,$00,$FF,$3F,$C0,$00
  DEFB $01,$00,$FF,$7F,$E0,$40
  DEFB $01,$00,$FF,$FF,$E0,$40
  DEFB $00,$00,$FF,$7F,$E0,$40
  DEFB $00,$00,$FF,$7F,$E0,$C0

; Legs, view A, frame 4
;
; Sabreman's legs by day, and the legs of the guards and the wizard (types $90
; to $9D). A walk plays frames 1 2 3 4 3 2: animate_human_legs steps the low
; three bits of the type round 0 to 5. View A is the types with bit 3 clear,
; view B those with it set. Types $13, $93.
spr_058:
  DEFB $03,$10
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$06,$00,$00,$00
  DEFB $00,$00,$1F,$06,$00,$00
  DEFB $00,$00,$7F,$1F,$80,$00
  DEFB $00,$00,$FF,$7B,$80,$00
  DEFB $00,$00,$FF,$70,$00,$00
  DEFB $00,$00,$7F,$06,$00,$00
  DEFB $00,$00,$FE,$0C,$00,$00
  DEFB $03,$00,$FC,$D8,$00,$00
  DEFB $07,$03,$FF,$D0,$00,$00
  DEFB $07,$03,$FF,$87,$80,$00
  DEFB $03,$00,$FF,$5F,$C0,$00
  DEFB $01,$00,$FF,$BF,$E0,$40
  DEFB $01,$00,$FF,$FF,$E0,$40
  DEFB $03,$01,$FF,$7F,$E0,$40
  DEFB $03,$01,$FF,$7F,$E0,$80

; Legs, view B, frame 1
;
; Sabreman's legs by day, and the legs of the guards and the wizard (types $90
; to $9D). A walk plays frames 1 2 3 4 3 2: animate_human_legs steps the low
; three bits of the type round 0 to 5. View A is the types with bit 3 clear,
; view B those with it set. Types $18, $98.
spr_059:
  DEFB $03,$10
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$38,$00
  DEFB $00,$00,$00,$00,$FC,$38
  DEFB $07,$00,$03,$00,$FC,$F8
  DEFB $1F,$07,$87,$03,$FC,$F8
  DEFB $3F,$1F,$8F,$07,$F8,$D0
  DEFB $7F,$3E,$07,$03,$D0,$00
  DEFB $FF,$70,$03,$01,$C0,$80
  DEFB $FF,$6F,$FE,$00,$E0,$C0
  DEFB $7F,$1C,$FF,$6E,$F0,$20
  DEFB $1F,$03,$FF,$EF,$E0,$C0
  DEFB $1F,$0F,$FF,$F7,$E0,$C0
  DEFB $0F,$07,$FF,$F7,$C0,$80
  DEFB $0F,$07,$FF,$F7,$C0,$80
  DEFB $07,$03,$FF,$FF,$80,$00

; Legs, view B, frame 2
;
; Sabreman's legs by day, and the legs of the guards and the wizard (types $90
; to $9D). A walk plays frames 1 2 3 4 3 2: animate_human_legs steps the low
; three bits of the type round 0 to 5. View A is the types with bit 3 clear,
; view B those with it set. Types $19, $1D, $99, $9D.
spr_060:
  DEFB $03,$10
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$E0,$00,$E0,$00
  DEFB $03,$00,$F3,$E0,$F0,$E0
  DEFB $07,$03,$FF,$E3,$F0,$E0
  DEFB $0F,$07,$FF,$CF,$F0,$E0
  DEFB $1F,$0F,$DF,$0F,$E0,$00
  DEFB $1F,$0C,$8F,$00,$00,$00
  DEFB $0F,$03,$FF,$86,$00,$00
  DEFB $03,$01,$FF,$31,$80,$00
  DEFB $07,$00,$FF,$F7,$C0,$80
  DEFB $0F,$07,$FF,$F7,$C0,$80
  DEFB $07,$03,$FF,$F7,$80,$00
  DEFB $07,$03,$FF,$F7,$80,$00
  DEFB $03,$01,$FF,$FF,$80,$00

; Legs, view B, frame 3
;
; Sabreman's legs by day, and the legs of the guards and the wizard (types $90
; to $9D). A walk plays frames 1 2 3 4 3 2: animate_human_legs steps the low
; three bits of the type round 0 to 5. View A is the types with bit 3 clear,
; view B those with it set. Types $1A, $1C, $9A, $9C.
spr_061:
  DEFB $03,$10
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$30,$00,$00,$00
  DEFB $00,$00,$F8,$30,$00,$00
  DEFB $03,$00,$FF,$F8,$80,$00
  DEFB $07,$03,$FF,$8B,$C0,$80
  DEFB $07,$03,$FF,$C7,$C0,$80
  DEFB $07,$02,$FF,$3D,$C0,$80
  DEFB $03,$01,$FF,$B8,$80,$00
  DEFB $03,$01,$FE,$84,$00,$00
  DEFB $01,$00,$FE,$30,$00,$00
  DEFB $03,$01,$FF,$F6,$00,$00
  DEFB $07,$03,$FF,$F6,$00,$00
  DEFB $07,$03,$FF,$F7,$80,$00
  DEFB $07,$03,$FF,$F7,$80,$00
  DEFB $03,$01,$FF,$FF,$80,$00

; Legs, view B, frame 4
;
; Sabreman's legs by day, and the legs of the guards and the wizard (types $90
; to $9D). A walk plays frames 1 2 3 4 3 2: animate_human_legs steps the low
; three bits of the type round 0 to 5. View A is the types with bit 3 clear,
; view B those with it set. Types $1B, $9B.
spr_062:
  DEFB $03,$10
  DEFB $00,$00,$06,$00,$00,$00
  DEFB $00,$00,$1F,$06,$00,$00
  DEFB $00,$00,$7F,$1F,$80,$00
  DEFB $00,$00,$FF,$7F,$80,$00
  DEFB $01,$00,$FF,$FE,$00,$00
  DEFB $01,$00,$FE,$E0,$00,$00
  DEFB $00,$00,$F8,$50,$00,$00
  DEFB $03,$00,$FC,$B8,$00,$00
  DEFB $07,$03,$FC,$D8,$00,$00
  DEFB $07,$03,$FE,$0C,$00,$00
  DEFB $07,$02,$FC,$F0,$00,$00
  DEFB $03,$01,$FE,$FC,$00,$00
  DEFB $03,$01,$FF,$FA,$00,$00
  DEFB $07,$03,$FF,$FA,$00,$00
  DEFB $07,$03,$FF,$F7,$80,$00
  DEFB $07,$03,$FF,$FF,$80,$00

; Sabreman's head and shoulders, view A, second occasional frame
;
; Sabreman's head and shoulders, types $20 to $2F, drawn 12 units above the
; legs. The type follows the legs' type plus $10 (set_top_sprite); the two
; occasional frames, $x6 and $x7, are given instead now and then, at random,
; and held for eight frames. Type $27.
spr_063:
  DEFB $03,$18
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$0E,$00,$20,$00
  DEFB $0E,$00,$FF,$0E,$F8,$20
  DEFB $3F,$0E,$FF,$3F,$FC,$B8
  DEFB $7F,$3D,$FF,$DF,$FC,$88
  DEFB $FF,$7B,$FF,$DF,$F8,$D0
  DEFB $FF,$63,$FF,$C3,$FC,$F8
  DEFB $63,$01,$FF,$80,$F8,$30
  DEFB $01,$00,$FF,$7F,$F0,$A0
  DEFB $01,$00,$FF,$C7,$E0,$C0
  DEFB $01,$00,$FF,$B1,$F0,$E0
  DEFB $01,$00,$FF,$76,$F8,$F0
  DEFB $01,$00,$FF,$EF,$FC,$78
  DEFB $01,$00,$FF,$DE,$FC,$B8
  DEFB $01,$00,$FF,$DD,$FE,$BC
  DEFB $01,$00,$FF,$FB,$FE,$DC
  DEFB $00,$00,$FF,$57,$FE,$DC
  DEFB $00,$00,$FF,$4E,$FE,$DC
  DEFB $00,$00,$7F,$29,$FC,$38
  DEFB $00,$00,$3F,$1E,$F8,$F0
  DEFB $00,$00,$1F,$00,$F0,$00

; Sabreman's head and shoulders, view B, second occasional frame
;
; Sabreman's head and shoulders, types $20 to $2F, drawn 12 units above the
; legs. The type follows the legs' type plus $10 (set_top_sprite); the two
; occasional frames, $x6 and $x7, are given instead now and then, at random,
; and held for eight frames. Type $2F.
spr_064:
  DEFB $03,$19
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $03,$00
  DEFB $00,$00,$00,$00,$07,$03,$80,$00
  DEFB $00,$00,$0F,$07,$00,$00,$00,$00
  DEFB $1F,$0E,$38,$00,$04,$00,$1F,$0E
  DEFB $FF,$38,$0E,$04,$3F,$19,$FF,$FF
  DEFB $9F,$0E,$3F,$17,$FF,$7F,$FE,$1C
  DEFB $1F,$0F,$FF,$7E,$FC,$E8,$1F,$0F
  DEFB $FF,$FE,$F8,$E0,$0F,$07,$FF,$FF
  DEFB $F0,$C0,$07,$03,$FF,$F1,$F8,$D0
  DEFB $0F,$05,$FF,$C0,$F8,$90,$1F,$08
  DEFB $FF,$00,$F8,$10,$3F,$10,$FF,$80
  DEFB $F0,$20,$7F,$22,$FF,$A0,$F8,$50
  DEFB $7F,$23,$FF,$60,$F8,$B0,$7F,$20
  DEFB $FF,$03,$F8,$70,$3F,$10,$FF,$1C
  DEFB $F8,$B0,$1F,$0F,$FF,$E3,$F0,$A0
  DEFB $0F,$02,$FF,$1D,$E0,$40,$03,$01
  DEFB $FF,$CE,$C0,$80,$01,$00,$FF,$F3
  DEFB $80,$00,$00,$00,$FF,$3C,$00,$00
  DEFB $00,$00,$3C,$00,$00,$00

; Sabreman's head and shoulders, view B, occasional frame
;
; Sabreman's head and shoulders, types $20 to $2F, drawn 12 units above the
; legs. The type follows the legs' type plus $10 (set_top_sprite); the two
; occasional frames, $x6 and $x7, are given instead now and then, at random,
; and held for eight frames. Type $2E.
spr_065:
  DEFB $03,$19
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $03,$00
  DEFB $00,$00,$00,$00,$07,$03,$80,$00
  DEFB $00,$00,$0F,$07,$80,$00,$00,$00
  DEFB $1F,$0E,$38,$00,$00,$00,$3F,$1E
  DEFB $FF,$38,$18,$00,$3F,$11,$FF,$7F
  DEFB $FC,$18,$3F,$0F,$FF,$7F,$FE,$7C
  DEFB $3F,$1F,$FF,$BE,$FC,$B8,$1F,$0F
  DEFB $FF,$FE,$F8,$C0,$0F,$03,$FF,$FF
  DEFB $E0,$C0,$1F,$09,$FF,$F1,$C0,$80
  DEFB $1F,$08,$FF,$F0,$C0,$00,$0F,$04
  DEFB $FF,$60,$F0,$00,$07,$02,$FF,$00
  DEFB $F8,$70,$0F,$05,$FF,$00,$F8,$B0
  DEFB $0F,$06,$FF,$C0,$FC,$C8,$0F,$07
  DEFB $FF,$38,$FC,$08,$0F,$06,$FF,$C7
  DEFB $FC,$88,$07,$02,$FF,$E8,$F8,$70
  DEFB $07,$02,$FF,$DD,$F0,$80,$03,$01
  DEFB $FF,$53,$80,$00,$01,$00,$FF,$8E
  DEFB $00,$00,$00,$00,$FE,$78,$00,$00
  DEFB $00,$00,$78,$00,$00,$00

; Tree, first kind
;
; Type $80: one of the three trees that alternate round a forest room
; (tree_walls). Type $80.
spr_066:
  DEFB $02,$30
  DEFB $FC,$00,$00,$00
  DEFB $FE,$7C,$00,$00
  DEFB $FF,$7E,$70,$00
  DEFB $FF,$3D,$F8,$70
  DEFB $FF,$3C,$FC,$B0
  DEFB $FF,$3C,$FE,$3C
  DEFB $FF,$3D,$FF,$1A
  DEFB $FF,$1D,$FF,$1B
  DEFB $FF,$1D,$FF,$18
  DEFB $FF,$1D,$FF,$38
  DEFB $FF,$1D,$FF,$3C
  DEFB $FF,$19,$FF,$B0
  DEFB $FF,$39,$FF,$B0
  DEFB $FF,$31,$FF,$A0
  DEFB $FF,$71,$FF,$F0
  DEFB $FF,$70,$FF,$F0
  DEFB $FF,$70,$FF,$F0
  DEFB $FF,$78,$FF,$F2
  DEFB $FF,$6C,$FF,$71
  DEFB $FF,$74,$FF,$59
  DEFB $FF,$72,$FF,$75
  DEFB $FF,$39,$FF,$71
  DEFB $FF,$39,$FF,$A2
  DEFB $FF,$39,$FF,$C2
  DEFB $FF,$38,$FF,$34
  DEFB $FF,$3C,$FF,$E4
  DEFB $FF,$3C,$FF,$E6
  DEFB $FF,$3C,$FF,$E6
  DEFB $FF,$1C,$FF,$66
  DEFB $FF,$1C,$FF,$72
  DEFB $FF,$1C,$FF,$72
  DEFB $FF,$0E,$FF,$32
  DEFB $FF,$0E,$FF,$32
  DEFB $FF,$0E,$FF,$3A
  DEFB $FF,$0E,$FF,$1A
  DEFB $FF,$0E,$FF,$99
  DEFB $FF,$0C,$FF,$59
  DEFB $FF,$0C,$FF,$58
  DEFB $FF,$18,$FF,$48
  DEFB $FF,$18,$FF,$6C
  DEFB $FF,$10,$FF,$C4
  DEFB $FF,$11,$FF,$84
  DEFB $FF,$11,$FF,$84
  DEFB $FF,$23,$FF,$04
  DEFB $FF,$23,$FF,$04
  DEFB $FF,$02,$FF,$02
  DEFB $FF,$02,$FF,$02
  DEFB $FF,$00,$FF,$02

; Tree, second kind
;
; Type $81; see spr_066. Type $81.
spr_067:
  DEFB $02,$30
  DEFB $F8,$00,$00,$00
  DEFB $FE,$78,$00,$00
  DEFB $FF,$7E,$00,$00
  DEFB $FF,$7D,$80,$00
  DEFB $FF,$7C,$FC,$80
  DEFB $FF,$6C,$FE,$FC
  DEFB $FF,$6C,$FF,$7C
  DEFB $FF,$6C,$FF,$7D
  DEFB $FF,$5C,$FF,$3E
  DEFB $FF,$5C,$FF,$3E
  DEFB $FF,$5C,$FF,$1F
  DEFB $FF,$2C,$FF,$1F
  DEFB $FF,$1E,$FF,$0F
  DEFB $FF,$97,$FF,$0F
  DEFB $FF,$57,$FF,$0F
  DEFB $FF,$57,$FF,$0F
  DEFB $FF,$4B,$FF,$1E
  DEFB $FF,$4B,$FF,$1E
  DEFB $FF,$E7,$FF,$9E
  DEFB $FF,$E7,$FF,$9C
  DEFB $FF,$E7,$FF,$9C
  DEFB $FF,$E7,$FF,$1C
  DEFB $FF,$6F,$FF,$1C
  DEFB $FF,$4F,$FF,$1E
  DEFB $FF,$4B,$FF,$3F
  DEFB $FF,$13,$FF,$5E
  DEFB $FF,$26,$FF,$5E
  DEFB $FF,$26,$FF,$9C
  DEFB $FF,$4C,$FF,$1C
  DEFB $FF,$5C,$FF,$3C
  DEFB $FF,$58,$FF,$38
  DEFB $FF,$28,$FF,$3E
  DEFB $FF,$28,$FF,$3F
  DEFB $FF,$18,$FF,$1E
  DEFB $FF,$18,$FF,$1E
  DEFB $FF,$14,$FF,$1C
  DEFB $FF,$14,$FF,$1C
  DEFB $FF,$16,$FF,$0C
  DEFB $FF,$1E,$FF,$0C
  DEFB $FF,$1C,$FF,$0C
  DEFB $FF,$14,$FF,$16
  DEFB $FF,$14,$FF,$16
  DEFB $FF,$18,$FF,$24
  DEFB $FF,$18,$FF,$2C
  DEFB $FF,$18,$FF,$48
  DEFB $FF,$10,$FF,$10
  DEFB $FF,$10,$FF,$00
  DEFB $FF,$00,$FF,$00

; Tree, third kind
;
; Type $82; see spr_066. Type $82.
spr_068:
  DEFB $02,$30
  DEFB $F8,$C0,$00,$00
  DEFB $FF,$78,$F0,$00
  DEFB $FF,$3F,$F8,$F0
  DEFB $FF,$1F,$FC,$E8
  DEFB $FF,$1E,$FC,$E8
  DEFB $FF,$0E,$FE,$C4
  DEFB $FF,$0E,$FF,$C2
  DEFB $FF,$4E,$FF,$C1
  DEFB $FF,$4E,$FF,$C0
  DEFB $FF,$4E,$FF,$40
  DEFB $FF,$47,$FF,$40
  DEFB $FF,$47,$FF,$E0
  DEFB $FF,$43,$FF,$E4
  DEFB $FF,$69,$FF,$E4
  DEFB $FF,$68,$FF,$E4
  DEFB $FF,$65,$FF,$EC
  DEFB $FF,$25,$FF,$EC
  DEFB $FF,$25,$FF,$EC
  DEFB $FF,$39,$FF,$E4
  DEFB $FF,$39,$FF,$F4
  DEFB $FF,$31,$FF,$F2
  DEFB $FF,$31,$FF,$F2
  DEFB $FF,$31,$FF,$F0
  DEFB $FF,$21,$FF,$E0
  DEFB $FF,$21,$FF,$E0
  DEFB $FF,$41,$FF,$E1
  DEFB $FF,$41,$FF,$F1
  DEFB $FF,$41,$FF,$F2
  DEFB $FF,$01,$FF,$F2
  DEFB $FF,$03,$FF,$E2
  DEFB $FF,$07,$FF,$C2
  DEFB $FF,$07,$FF,$83
  DEFB $FF,$0F,$FF,$03
  DEFB $FF,$0E,$FF,$03
  DEFB $FF,$1C,$FF,$07
  DEFB $FF,$18,$FF,$06
  DEFB $FF,$18,$FF,$06
  DEFB $FF,$18,$FF,$0C
  DEFB $FF,$18,$FF,$1C
  DEFB $FF,$18,$FF,$18
  DEFB $FF,$08,$FF,$30
  DEFB $FF,$08,$FF,$20
  DEFB $FF,$08,$FF,$40
  DEFB $FF,$18,$FF,$00
  DEFB $FF,$01,$FF,$00
  DEFB $FF,$01,$FF,$00
  DEFB $FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00

; Wall column, west wall
;
; Type $0D, a 48-row column of stone wall: in every wall set it stands at the
; north end of the west wall (walls_square). Type $0D.
spr_069:
  DEFB $02,$30
  DEFB $40,$00,$00,$00
  DEFB $F0,$40,$00,$00
  DEFB $FC,$70,$00,$00
  DEFB $FE,$7C,$00,$00
  DEFB $FF,$7E,$C0,$00
  DEFB $FF,$7E,$F0,$C0
  DEFB $FF,$7E,$FC,$F0
  DEFB $FF,$7E,$FF,$FC
  DEFB $7F,$36,$FF,$FE
  DEFB $37,$00,$FF,$FE
  DEFB $0F,$06,$FF,$3E
  DEFB $0F,$07,$FF,$8E
  DEFB $0F,$07,$FF,$E2
  DEFB $07,$03,$FF,$F8
  DEFB $07,$03,$FF,$FE
  DEFB $07,$03,$FF,$FF
  DEFB $07,$03,$FF,$FF
  DEFB $0F,$07,$FF,$FF
  DEFB $0F,$07,$FF,$FF
  DEFB $0F,$07,$FF,$FF
  DEFB $67,$01,$FF,$FF
  DEFB $F9,$60,$FF,$7F
  DEFB $FE,$78,$FF,$1F
  DEFB $FF,$7E,$FF,$67
  DEFB $FF,$7E,$FF,$F8
  DEFB $7F,$1E,$FF,$FE
  DEFB $1F,$06,$FF,$FE
  DEFB $07,$00,$FF,$FE
  DEFB $01,$00,$FF,$FE
  DEFB $00,$00,$FF,$3E
  DEFB $06,$00,$7F,$0E
  DEFB $0F,$06,$7F,$30
  DEFB $1F,$0E,$FF,$3C
  DEFB $1F,$0F,$FF,$9E
  DEFB $0F,$07,$FF,$E6
  DEFB $07,$01,$FF,$F8
  DEFB $07,$02,$FF,$7F
  DEFB $07,$03,$FF,$9F
  DEFB $07,$03,$FF,$E7
  DEFB $03,$01,$FF,$F9
  DEFB $03,$00,$FF,$FE
  DEFB $07,$03,$FF,$3F
  DEFB $07,$03,$FF,$CF
  DEFB $07,$03,$FF,$F7
  DEFB $03,$00,$FF,$F7
  DEFB $00,$00,$FF,$33
  DEFB $00,$00,$3B,$00
  DEFB $00,$00,$00,$00

; Wall column, north wall
;
; Type $0E, the column at the west end of the north wall. Type $0E.
spr_070:
  DEFB $02,$30
  DEFB $00,$00,$02,$00
  DEFB $00,$00,$0F,$02
  DEFB $00,$00,$1F,$0E
  DEFB $00,$00,$FF,$0E
  DEFB $03,$00,$FF,$EE
  DEFB $0F,$03,$FF,$EE
  DEFB $03,$0F,$FF,$EE
  DEFB $FF,$3F,$FE,$E8
  DEFB $FF,$FF,$F8,$E0
  DEFB $FF,$FF,$E0,$C0
  DEFB $FF,$FF,$C0,$00
  DEFB $FF,$FC,$E0,$C0
  DEFB $FF,$F3,$EC,$C0
  DEFB $FF,$CF,$FE,$8C
  DEFB $FF,$3F,$FE,$3C
  DEFB $FF,$7C,$FE,$FC
  DEFB $FF,$73,$FE,$FC
  DEFB $FF,$4F,$FC,$F0
  DEFB $FF,$3F,$F0,$C0
  DEFB $FF,$7F,$C0,$00
  DEFB $FF,$7C,$C0,$80
  DEFB $FF,$73,$C0,$80
  DEFB $FF,$4F,$C0,$80
  DEFB $FF,$3F,$80,$00
  DEFB $FF,$7C,$80,$00
  DEFB $FF,$FB,$8F,$02
  DEFB $FF,$E7,$FF,$8E
  DEFB $FF,$9F,$FF,$BE
  DEFB $FF,$7F,$FE,$BC
  DEFB $FF,$FF,$FC,$B0
  DEFB $FF,$FF,$F0,$80
  DEFB $FF,$FF,$F8,$30
  DEFB $FF,$FC,$FC,$78
  DEFB $FF,$F1,$FC,$F8
  DEFB $FF,$49,$FC,$F8
  DEFB $FF,$3D,$F8,$F0
  DEFB $FF,$7D,$F0,$E0
  DEFB $FF,$7D,$F0,$80
  DEFB $FF,$7C,$F0,$20
  DEFB $FF,$78,$F8,$F0
  DEFB $FF,$73,$F8,$F0
  DEFB $FF,$4F,$F8,$F0
  DEFB $FF,$3F,$F0,$E0
  DEFB $FF,$7F,$E0,$80
  DEFB $FF,$7E,$80,$00
  DEFB $FE,$78,$00,$00
  DEFB $F8,$60,$00,$00
  DEFB $60,$00,$00,$00

; Arch, first piece
;
; Type $02, the taller of the two pieces of an arch (arch_n), 52 rows. Type
; $02.
spr_071:
  DEFB $03,$34
  DEFB $01,$00,$F0,$C0,$00,$00
  DEFB $07,$01,$F8,$70,$00,$00
  DEFB $1F,$07,$FC,$78,$00,$00
  DEFB $7F,$1F,$FC,$78,$00,$00
  DEFB $FF,$7F,$FC,$78,$00,$00
  DEFB $FF,$7F,$FC,$78,$00,$00
  DEFB $FF,$7F,$FC,$78,$00,$00
  DEFB $FF,$7E,$FC,$38,$00,$00
  DEFB $FF,$79,$FC,$48,$00,$00
  DEFB $FF,$67,$FC,$70,$00,$00
  DEFB $FF,$1F,$FC,$78,$00,$00
  DEFB $FF,$7F,$FC,$78,$00,$00
  DEFB $FF,$7F,$FC,$78,$00,$00
  DEFB $FF,$7F,$FC,$78,$00,$00
  DEFB $FF,$7E,$FC,$18,$00,$00
  DEFB $FF,$79,$FC,$60,$00,$00
  DEFB $FF,$67,$FC,$78,$00,$00
  DEFB $FF,$1F,$FC,$78,$00,$00
  DEFB $FF,$7F,$FC,$78,$00,$00
  DEFB $FF,$7F,$FC,$78,$00,$00
  DEFB $FF,$7F,$FC,$78,$00,$00
  DEFB $FF,$7F,$FC,$18,$00,$00
  DEFB $FF,$7C,$FC,$A0,$00,$00
  DEFB $FF,$73,$FE,$BC,$00,$00
  DEFB $7F,$0F,$FE,$BC,$00,$00
  DEFB $7F,$3F,$FE,$BC,$00,$00
  DEFB $7F,$3F,$FF,$BE,$00,$00
  DEFB $7F,$3F,$FF,$DE,$00,$00
  DEFB $7F,$3F,$FF,$80,$00,$00
  DEFB $7F,$3E,$FF,$5F,$80,$00
  DEFB $3F,$19,$FF,$EF,$80,$00
  DEFB $3F,$07,$FF,$EF,$80,$00
  DEFB $3F,$1F,$FF,$EF,$80,$00
  DEFB $1F,$0F,$FF,$F7,$C0,$80
  DEFB $1F,$0F,$FF,$F7,$E0,$00
  DEFB $1F,$0F,$FF,$F8,$F0,$E0
  DEFB $0F,$07,$FF,$F3,$F0,$E0
  DEFB $0F,$07,$FF,$CD,$F8,$F0
  DEFB $07,$03,$FF,$3E,$FC,$F8
  DEFB $07,$00,$FF,$FE,$FE,$F4
  DEFB $03,$01,$FF,$FF,$FE,$6C
  DEFB $01,$00,$FF,$FF,$FF,$9E
  DEFB $01,$00,$FF,$FE,$FF,$5F
  DEFB $00,$00,$FF,$79,$FF,$EF
  DEFB $00,$00,$7F,$27,$FF,$F7
  DEFB $00,$00,$3F,$1F,$FF,$FB
  DEFB $00,$00,$1F,$0F,$FF,$FD
  DEFB $00,$00,$0F,$07,$FF,$F8
  DEFB $00,$00,$07,$03,$FF,$E3
  DEFB $00,$00,$03,$01,$FF,$8C
  DEFB $00,$00,$01,$00,$FC,$30
  DEFB $00,$00,$00,$00,$30,$00

; Arch, second piece
;
; Type $03, the other pillar of an arch. Type $03.
spr_072:
  DEFB $02,$23
  DEFB $00,$00,$3C,$00
  DEFB $00,$00,$FE,$2C
  DEFB $03,$00,$FF,$EE,$0F,$03,$FF,$EE
  DEFB $1F,$0F,$FF,$EE,$1F,$0F,$FF,$EE
  DEFB $1F,$0F,$FF,$EE,$1F,$0F,$FF,$EE
  DEFB $1F,$0F,$FF,$C2,$1F,$0F,$FF,$2D
  DEFB $1F,$0C,$FF,$EE,$1F,$03,$FF,$EE
  DEFB $1F,$0F,$FF,$EE,$1F,$0F,$FF,$C2
  DEFB $1F,$0F,$FF,$2C,$1F,$0C,$FF,$EE
  DEFB $1F,$03,$FF,$EE,$1F,$0F,$FF,$E6
  DEFB $1F,$0F,$FF,$18,$1F,$0C,$FF,$DE
  DEFB $1F,$03,$FE,$DC,$3F,$1F,$FE,$BC
  DEFB $3F,$1F,$FE,$0C,$3F,$1C,$FC,$70
  DEFB $7F,$33,$FC,$78,$7F,$0E,$F8,$F0
  DEFB $FF,$7C,$F8,$F0,$FF,$73,$F0,$60
  DEFB $FF,$CF,$E0,$80,$FF,$37,$C0,$80
  DEFB $FF,$77,$80,$00,$FF,$7A,$00,$00
  DEFB $FE,$78,$00,$00,$F8,$60,$00,$00
  DEFB $E0,$00,$00,$00

; Wall end
;
; Type $0F, the column that ends a wall towards the viewer, stacked two high.
; Type $0F.
spr_073:
  DEFB $02,$30
  DEFB $C0,$00,$00,$00
  DEFB $F0,$C0,$00,$00
  DEFB $FC,$F0,$00,$00
  DEFB $FF,$FC,$00,$00
  DEFB $FF,$FF,$C0,$00
  DEFB $FF,$FF,$F0,$C0
  DEFB $FF,$FF,$FC,$F0
  DEFB $FF,$FF,$FE,$FC
  DEFB $FF,$3F,$FF,$FE
  DEFB $FF,$CF,$FF,$FE
  DEFB $FF,$E3,$FF,$FE
  DEFB $FF,$EC,$FF,$FE
  DEFB $FF,$EF,$FE,$3C
  DEFB $FF,$EF,$FE,$CC
  DEFB $FF,$0F,$FC,$E0
  DEFB $FF,$67,$F0,$E0
  DEFB $FF,$F9,$F0,$E0
  DEFB $FF,$FE,$F0,$60
  DEFB $FF,$FF,$E0,$80
  DEFB $FF,$FF,$F0,$E0
  DEFB $FF,$FF,$F8,$F0
  DEFB $FF,$FF,$F8,$F0
  DEFB $FF,$FF,$F8,$F0
  DEFB $FF,$7F,$F8,$F0
  DEFB $FF,$1F,$F8,$F0
  DEFB $FF,$67,$F8,$F0
  DEFB $FF,$79,$FC,$F8
  DEFB $FF,$7E,$FE,$7C
  DEFB $FF,$7F,$FE,$1C
  DEFB $FF,$1F,$9E,$04
  DEFB $FF,$E7,$84,$00
  DEFB $FF,$F9,$80,$00
  DEFB $FF,$FE,$00,$00
  DEFB $FF,$FF,$E0,$00
  DEFB $FF,$FF,$F8,$A0
  DEFB $FF,$FF,$FC,$B8
  DEFB $FF,$3F,$FE,$DC
  DEFB $FF,$CF,$FE,$DC
  DEFB $FF,$F3,$FE,$DC
  DEFB $FF,$FC,$FF,$DE
  DEFB $FF,$FF,$FF,$1E
  DEFB $FF,$FF,$9F,$0E
  DEFB $FF,$FF,$8F,$02
  DEFB $FF,$FF,$82,$00
  DEFB $FF,$3F,$80,$00
  DEFB $3F,$0F,$80,$00
  DEFB $0F,$03,$80,$00
  DEFB $03,$00,$00,$00

; Cauldron
;
; Type $8D, the cauldron in the wizard's room (cauldron). Type $8D.
spr_074:
  DEFB $04,$21
  DEFB $01,$00,$C0,$00,$00,$00,$00,$00
  DEFB $03,$01,$E0,$C0,$C0,$00,$00,$00
  DEFB $07,$03,$F3,$E1,$E7,$C0,$00,$00
  DEFB $07,$03,$FF,$E3,$EF,$C7,$98,$00
  DEFB $03,$01,$FF,$D3,$FF,$CF,$FC,$8C
  DEFB $3B,$01,$FF,$17,$FF,$5F,$FE,$BC
  DEFB $7F,$38,$FF,$98,$FF,$A7,$FE,$7C
  DEFB $FF,$7C,$FF,$51,$FF,$42,$FE,$B8
  DEFB $FF,$7E,$FF,$00,$FF,$05,$FF,$62
  DEFB $7F,$38,$FF,$7F,$FF,$FE,$FF,$0E
  DEFB $7F,$23,$FF,$FF,$FF,$FF,$FF,$CE
  DEFB $3F,$0F,$FF,$FF,$FF,$FF,$FF,$F6
  DEFB $3F,$1F,$FF,$1F,$FF,$FF,$FE,$F8
  DEFB $7F,$3E,$FF,$1F,$FF,$FF,$FE,$FC
  DEFB $7F,$3C,$FF,$3F,$FF,$FF,$FE,$FC
  DEFB $FF,$7C,$FF,$7F,$FF,$FF,$FF,$FE
  DEFB $FF,$78,$FF,$FF,$FF,$FF,$FF,$FE
  DEFB $FF,$78,$FF,$FF,$FF,$FF,$FF,$FE
  DEFB $FF,$78,$FF,$FF,$FF,$FF,$FF,$FE
  DEFB $7F,$38,$FF,$FF,$FF,$E0,$FE,$3C
  DEFB $7F,$38,$FF,$7F,$FF,$1F,$FE,$CC
  DEFB $3F,$1C,$FF,$7C,$FF,$FF,$FC,$F0
  DEFB $3F,$1E,$FF,$7B,$FF,$FF,$FE,$FC
  DEFB $1F,$0F,$FF,$F7,$FF,$FF,$FE,$F4
  DEFB $0F,$07,$FF,$EF,$FF,$FF,$F7,$E2
  DEFB $07,$03,$FF,$DF,$FF,$FF,$E7,$C2
  DEFB $07,$03,$FF,$9F,$FF,$FF,$E7,$C2
  DEFB $07,$03,$FF,$9F,$FF,$FF,$E7,$C2
  DEFB $07,$03,$F0,$F0,$0F,$0F,$EE,$C2
  DEFB $0F,$07,$00,$00,$00,$00,$FE,$E4
  DEFB $1C,$0C,$00,$00,$00,$00,$3C,$38
  DEFB $18,$08,$00,$00,$00,$00,$18,$10
  DEFB $10,$00,$00,$00,$00,$00,$08,$00

; Cauldron's top
;
; Type $8E, the second piece of the cauldron: a flat oval, 11 rows high. Type
; $8E.
spr_075:
  DEFB $04,$0B
  DEFB $00,$00,$0F,$00,$F0,$00,$00,$00
  DEFB $00,$00,$FF,$05,$FF,$50,$00,$00
  DEFB $03,$00,$FF,$6C,$FF,$21,$C0,$00
  DEFB $07,$02,$FF,$92,$FF,$91,$E0,$80
  DEFB $0F,$07,$FF,$FD,$FF,$51,$F0,$60
  DEFB $1F,$0D,$FF,$35,$FF,$E0,$F8,$F0
  DEFB $0F,$06,$FF,$FB,$FF,$78,$F0,$60
  DEFB $07,$03,$FF,$DD,$FF,$F8,$E0,$C0
  DEFB $03,$00,$FF,$FF,$FF,$FF,$C0,$00
  DEFB $00,$00,$FF,$0F,$FF,$F0,$00,$00
  DEFB $00,$00,$0F,$00,$F0,$00,$00,$00

; Wall slab, long
;
; Type $0A, the longest of the three slabs that fill a stone wall between its
; columns: 20 units long and 20 high. Type $0A.
spr_076:
  DEFB $05,$19
  DEFB $00,$00,$C0,$00,$00,$00,$00,$00
  DEFB $00,$00,$01,$00,$F1,$C0,$80,$00
  DEFB $00,$00,$00,$00,$01,$00,$FB,$F8
  DEFB $E0,$80,$00,$00,$00,$00,$01,$00
  DEFB $FF,$F9,$F8,$E0,$00,$00,$00,$00
  DEFB $01,$00,$FF,$F9,$FE,$F8,$60,$00
  DEFB $00,$00,$71,$00,$FF,$F8,$FF,$7E
  DEFB $F8,$60,$00,$00,$FD,$70,$FF,$F9
  DEFB $FF,$9F,$FE,$78,$00,$00,$FF,$7C
  DEFB $FF,$FB,$FF,$E7,$FF,$7E,$80,$00
  DEFB $FF,$7F,$FF,$3B,$FF,$F9,$FF,$7F
  DEFB $E0,$80,$FF,$7F,$FF,$CD,$FF,$FE
  DEFB $FF,$7F,$F8,$E0,$7F,$3F,$FF,$F3
  DEFB $FF,$FF,$FF,$9F,$FE,$F8,$3F,$0F
  DEFB $FF,$FC,$FF,$FF,$FF,$C7,$FF,$FE
  DEFB $0F,$03,$FF,$FF,$FF,$3F,$FF,$E9
  DEFB $FF,$FE,$03,$00,$FF,$FF,$FF,$8F
  DEFB $FF,$EE,$FF,$7E,$00,$00,$FF,$3F
  DEFB $CF,$83,$FF,$EF,$FF,$9E,$00,$00
  DEFB $FF,$4F,$C3,$80,$FF,$EF,$FF,$C6
  DEFB $00,$00,$FF,$73,$C0,$80,$FF,$2F
  DEFB $E6,$C0,$00,$00,$FF,$7C,$C0,$80
  DEFB $3F,$0F,$E0,$C0,$00,$00,$7F,$3F
  DEFB $C0,$00,$1F,$0F,$E0,$C0,$00,$00
  DEFB $3F,$0F,$F0,$C0,$0F,$0F,$E0,$C0
  DEFB $00,$00,$0F,$03,$F8,$F0,$0F,$07
  DEFB $E0,$C0,$00,$00,$03,$00,$FC,$F8
  DEFB $07,$01,$E0,$C0,$00,$00,$00,$00
  DEFB $FC,$38,$01,$00,$E0,$40,$00,$00
  DEFB $00,$00,$3C,$08,$00,$00,$40,$00
  DEFB $00,$00,$00,$00,$08,$00,$00,$00
  DEFB $00,$00

; Wall slab, medium
;
; Type $0B, 12 units long and 20 high. Type $0B.
spr_077:
  DEFB $03,$18
  DEFB $01,$00,$80,$00,$00,$00
  DEFB $03,$01,$E0,$80,$00,$00
  DEFB $03,$01,$F8,$E0,$00,$00
  DEFB $03,$01,$FE,$F8,$00,$00
  DEFB $01,$00,$FF,$FE,$80,$00
  DEFB $00,$00,$FF,$7F,$C0,$80
  DEFB $08,$00,$FF,$7F,$E0,$80
  DEFB $1E,$08,$7F,$3F,$F1,$A0
  DEFB $3F,$1E,$FF,$3F,$FC,$B8
  DEFB $3F,$1F,$FF,$BF,$FC,$B8
  DEFB $1F,$0F,$FF,$BF,$FC,$B8
  DEFB $1F,$0F,$FF,$9F,$FC,$B8
  DEFB $7F,$0F,$FF,$A7,$FC,$98
  DEFB $FF,$67,$FF,$B9,$D8,$80
  DEFB $FF,$79,$FF,$BE,$C0,$00
  DEFB $FF,$7E,$FF,$3F,$E0,$80
  DEFB $7F,$3F,$FF,$9F,$F8,$E0
  DEFB $3F,$0F,$FF,$E7,$FE,$F8
  DEFB $0F,$03,$FF,$F9,$FF,$FE
  DEFB $03,$00,$FF,$FD,$FF,$FE
  DEFB $00,$00,$FF,$3D,$FF,$FE
  DEFB $00,$00,$3F,$0C,$FF,$7E
  DEFB $00,$00,$0C,$00,$7E,$1C
  DEFB $00,$00,$00,$00,$1C,$00

; Wall slab, short
;
; Type $0C, 12 units long and 12 high. Type $0C.
spr_078:
  DEFB $03,$12
  DEFB $40,$00,$00,$00,$00,$00
  DEFB $F0,$40
  DEFB $00,$00,$00,$00,$FC,$70,$00,$00
  DEFB $00,$00,$FF,$7C,$00,$00,$00,$00
  DEFB $FF,$7F,$C3,$00,$00,$00,$FF,$7F
  DEFB $F7,$C3,$C0,$00,$7F,$33,$FF,$F3
  DEFB $F0,$C0,$3F,$14,$FF,$FB,$FC,$F0
  DEFB $1F,$07,$FF,$3B,$FE,$FC,$0F,$07
  DEFB $FF,$CB,$FF,$FE,$0F,$07,$FF,$F3
  DEFB $FF,$FE,$07,$01,$FF,$FC,$FF,$FE
  DEFB $01,$00,$FF,$7F,$FF,$3E,$00,$00
  DEFB $7F,$1F,$FF,$CE,$00,$00,$1F,$07
  DEFB $FF,$E2,$00,$00,$07,$01,$F2,$E0
  DEFB $00,$00,$01,$00,$F0,$60,$00,$00
  DEFB $00,$00,$60,$00

; Werewulf's legs, view A, frame 1
;
; The werewulf's legs, the night-time form of Sabreman's (spr_055 onwards):
; types $30 to $3D, the day types plus $20. Type $30.
spr_079:
  DEFB $03,$10
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$60,$00
  DEFB $00,$00,$09,$00,$F0,$60
  DEFB $03,$00,$1F,$09,$F8,$F0
  DEFB $27,$03,$9F,$0F,$F8,$F0
  DEFB $7F,$27,$CF,$87,$F0,$60
  DEFB $7F,$3F,$C7,$80,$F0,$E0
  DEFB $7F,$3D,$C1,$80,$E0,$C0
  DEFB $3F,$1B,$8D,$00,$E0,$C0
  DEFB $1F,$03,$BF,$0D,$E0,$C0
  DEFB $07,$03,$FF,$3E,$F0,$E0
  DEFB $07,$03,$FF,$FF,$F8,$60
  DEFB $03,$01,$FF,$FF,$F8,$60

; Werewulf's legs, view A, frame 2
;
; The werewulf's legs, the night-time form of Sabreman's (spr_055 onwards):
; types $30 to $3D, the day types plus $20. Types $31, $35.
spr_080:
  DEFB $03,$10
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$C0,$00,$00,$00
  DEFB $09,$00,$E3,$C0,$80,$00
  DEFB $1F,$09,$FF,$E3,$C0,$80
  DEFB $1F,$0F,$FF,$EF,$C0,$80
  DEFB $1F,$0F,$FF,$5F,$C0,$80
  DEFB $0F,$06,$FF,$D9,$80,$00
  DEFB $07,$00,$FF,$C3,$80,$00
  DEFB $01,$00,$FF,$FB,$80,$00
  DEFB $01,$00,$FF,$FD,$C0,$80
  DEFB $01,$00,$FF,$FE,$E0,$C0
  DEFB $01,$00,$FF,$FE,$E0,$C0
  DEFB $00,$00,$FF,$7E,$E0,$C0

; Werewulf's legs, view A, frame 3
;
; The werewulf's legs, the night-time form of Sabreman's (spr_055 onwards):
; types $30 to $3D, the day types plus $20. Types $32, $34.
spr_081:
  DEFB $03,$10
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$18,$00,$00,$00
  DEFB $01,$00,$3C,$18,$00,$00
  DEFB $03,$01,$FE,$3C,$00,$00
  DEFB $03,$01,$FE,$FC,$00,$00
  DEFB $03,$01,$FE,$EC,$00,$00
  DEFB $01,$00,$FF,$DA,$00,$00
  DEFB $03,$01,$FF,$36,$00,$00
  DEFB $03,$01,$FE,$B4,$00,$00
  DEFB $03,$01,$FF,$7A,$00,$00
  DEFB $01,$00,$FF,$7C,$00,$00
  DEFB $00,$00,$FF,$7E,$00,$00
  DEFB $00,$00,$7F,$3F,$C0,$00
  DEFB $00,$00,$FF,$7F,$E0,$40

; Werewulf's legs, view A, frame 4
;
; The werewulf's legs, the night-time form of Sabreman's (spr_055 onwards):
; types $30 to $3D, the day types plus $20. Type $33.
spr_082:
  DEFB $03,$10
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$06,$00,$00,$00
  DEFB $00,$00,$5F,$06,$00,$00
  DEFB $00,$00,$FF,$5F,$80,$00
  DEFB $00,$00,$FF,$7B,$80,$00
  DEFB $00,$00,$7F,$37,$80,$00
  DEFB $02,$00,$7F,$06,$00,$00
  DEFB $07,$02,$FF,$6E,$00,$00
  DEFB $07,$03,$FE,$EC,$00,$00
  DEFB $07,$03,$FE,$DC,$00,$00
  DEFB $03,$00,$FF,$5E,$00,$00
  DEFB $00,$00,$FF,$5F,$80,$00
  DEFB $01,$00,$FF,$DF,$80,$00
  DEFB $01,$00,$FF,$BF,$C0,$80
  DEFB $03,$01,$FF,$BF,$C0,$80

; Werewulf's legs, view B, frame 1
;
; The werewulf's legs, the night-time form of Sabreman's (spr_055 onwards):
; types $30 to $3D, the day types plus $20. Type $38.
spr_083:
  DEFB $03,$10
  DEFB $00,$00,$01,$00,$00,$00
  DEFB $00,$00,$07,$01,$80,$00
  DEFB $00,$00,$1F,$07,$80,$00
  DEFB $00,$00,$7F,$1F,$80,$00
  DEFB $00,$00,$FF,$7C,$00,$00
  DEFB $01,$00,$FC,$F0,$00,$00
  DEFB $00,$00,$FE,$64,$00,$00
  DEFB $00,$00,$FE,$74,$00,$00
  DEFB $03,$00,$FC,$B8,$00,$00
  DEFB $07,$03,$FE,$BC,$00,$00
  DEFB $07,$03,$FE,$7C,$00,$00
  DEFB $07,$02,$FE,$FC,$00,$00
  DEFB $03,$01,$FF,$FA,$00,$00
  DEFB $07,$03,$FF,$FA,$00,$00
  DEFB $07,$03,$FF,$F6,$00,$00
  DEFB $07,$03,$FF,$FF,$80,$00

; Werewulf's legs, view B, frame 2
;
; The werewulf's legs, the night-time form of Sabreman's (spr_055 onwards):
; types $30 to $3D, the day types plus $20. Types $39, $3D.
spr_084:
  DEFB $03,$10
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$08,$00,$00,$00
  DEFB $00,$00,$3C,$08,$80,$00
  DEFB $00,$00,$FF,$38,$C0,$80
  DEFB $03,$00,$FF,$FB,$C0,$80
  DEFB $07,$03,$FF,$F7,$C0,$80
  DEFB $0F,$07,$FF,$C7,$80,$00
  DEFB $07,$03,$FE,$3C,$00,$00
  DEFB $07,$03,$FC,$B8,$00,$00
  DEFB $03,$01,$FC,$D8,$00,$00
  DEFB $03,$01,$FE,$EC,$00,$00
  DEFB $01,$00,$FF,$EE,$00,$00
  DEFB $01,$00,$FF,$F7,$80,$00
  DEFB $03,$01,$FF,$F7,$80,$00
  DEFB $03,$01,$FF,$FF,$80,$00

; Werewulf's legs, view B, frame 3
;
; The werewulf's legs, the night-time form of Sabreman's (spr_055 onwards):
; types $30 to $3D, the day types plus $20. Types $3A, $3C.
spr_085:
  DEFB $03,$10
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$20,$00,$20,$00
  DEFB $00,$00,$F1,$20,$F0,$20
  DEFB $03,$00,$F7,$E1,$F0,$E0
  DEFB $0F,$03,$FF,$E7,$F0,$E0
  DEFB $1F,$0F,$FF,$DF,$E0,$80
  DEFB $3F,$1F,$FF,$1E,$80,$00
  DEFB $1F,$0E,$9E,$0C,$00,$00
  DEFB $0F,$07,$FF,$8E,$00,$00
  DEFB $07,$01,$FF,$EF,$80,$00
  DEFB $01,$00,$FF,$F7,$80,$00
  DEFB $01,$00,$FF,$F7,$C0,$80
  DEFB $03,$01,$FF,$F7,$C0,$80
  DEFB $03,$01,$FF,$FF,$80,$00

; Werewulf's legs, view B, frame 4
;
; The werewulf's legs, the night-time form of Sabreman's (spr_055 onwards):
; types $30 to $3D, the day types plus $20. Type $3B.
spr_086:
  DEFB $03,$10
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$08,$00
  DEFB $00,$00,$00,$00,$3C,$08
  DEFB $01,$00,$00,$00,$FC,$38
  DEFB $07,$01,$83,$00,$FC,$F8
  DEFB $1F,$07,$87,$03,$F8,$E0
  DEFB $3F,$1F,$8F,$07,$E0,$80
  DEFB $7F,$3C,$07,$03,$80,$00
  DEFB $FF,$70,$03,$01,$C0,$80
  DEFB $FF,$7F,$83,$01,$E0,$C0
  DEFB $7F,$3F,$C7,$83,$E0,$C0
  DEFB $3F,$07,$EF,$C7,$E0,$C0
  DEFB $07,$03,$FF,$EF,$E0,$C0
  DEFB $07,$03,$FF,$EF,$C0,$80
  DEFB $07,$03,$FF,$FF,$C0,$80

; Werewulf's head and shoulders, view A, frame 1
;
; The werewulf's head and shoulders, types $40 to $4F: the night-time form of
; Sabreman's, drawn 12 units above the legs. Type $40.
spr_087:
  DEFB $03,$1D
  DEFB $00,$00,$18,$00,$00,$00
  DEFB $00,$00
  DEFB $3C,$18,$00,$00,$00,$00,$7E,$34
  DEFB $00,$00,$00,$00,$74,$20,$00,$00
  DEFB $00,$00,$F0,$60,$00,$00,$00,$00
  DEFB $F8,$70,$00,$00,$00,$00,$F8,$70
  DEFB $00,$00,$00,$00,$7C,$38,$00,$00
  DEFB $00,$00,$7E,$3C,$00,$00,$00,$00
  DEFB $3F,$1D,$E0,$C0,$00,$00,$7F,$3D
  DEFB $E0,$C0,$00,$00,$FF,$7B,$E0,$C0
  DEFB $01,$00,$FF,$F7,$F0,$C0,$01,$00
  DEFB $FF,$EF,$F8,$D0,$03,$01,$FF,$FF
  DEFB $FC,$F8,$03,$01,$FF,$FF,$FC,$F8
  DEFB $01,$00,$FF,$7F,$FC,$F8,$01,$00
  DEFB $FF,$8F,$F8,$E0,$01,$00,$FF,$9F
  DEFB $F8,$F0,$03,$01,$FF,$F7,$F8,$F0
  DEFB $03,$01,$FF,$D7,$F8,$F0,$01,$00
  DEFB $FF,$BB,$F8,$F0,$00,$00,$FF,$7B
  DEFB $F8,$F0,$00,$00,$FF,$77,$F8,$F0
  DEFB $01,$00,$FF,$EF,$F0,$E0,$01,$00
  DEFB $EF,$C0,$F0,$E0,$00,$00,$C1,$00
  DEFB $E0,$C0,$00,$00,$01,$00,$C0,$80
  DEFB $00,$00,$00,$00,$80,$00

; Werewulf's head and shoulders, view A, frame 2
;
; The werewulf's head and shoulders, types $40 to $4F: the night-time form of
; Sabreman's, drawn 12 units above the legs. Types $41, $45.
spr_088:
  DEFB $03,$1D
  DEFB $00,$00,$30,$00,$00,$00
  DEFB $00,$00
  DEFB $78,$30,$00,$00,$00,$00,$FC,$68
  DEFB $00,$00,$00,$00,$F8,$60,$00,$00
  DEFB $01,$00,$F0,$E0,$00,$00,$01,$00
  DEFB $F0,$E0,$00,$00,$01,$00,$F8,$F0
  DEFB $00,$00,$00,$00,$F8,$70,$00,$00
  DEFB $00,$00,$FC,$78,$00,$00,$00,$00
  DEFB $FF,$7B,$E0,$C0,$00,$00,$FF,$7B
  DEFB $F0,$C0,$00,$00,$FF,$77,$F8,$D0
  DEFB $01,$00,$FF,$EF,$F8,$D0,$01,$00
  DEFB $FF,$FF,$FC,$D8,$03,$01,$FF,$FF
  DEFB $FC,$F8,$03,$01,$FF,$FF,$FC,$F8
  DEFB $01,$00,$FF,$7F,$FC,$F8,$01,$00
  DEFB $FF,$8F,$F8,$E0,$01,$00,$FF,$9F
  DEFB $F8,$F0,$03,$01,$FF,$F7,$F8,$F0
  DEFB $03,$01,$FF,$D7,$F8,$F0,$01,$00
  DEFB $FF,$BB,$F8,$F0,$00,$00,$FF,$7B
  DEFB $F8,$F0,$00,$00,$FF,$77,$F8,$F0
  DEFB $01,$00,$FF,$EF,$F0,$E0,$01,$00
  DEFB $EF,$C0,$F0,$E0,$00,$00,$C1,$00
  DEFB $E0,$C0,$00,$00,$01,$00,$C0,$80
  DEFB $00,$00,$00,$00,$80,$00

; Werewulf's head and shoulders, view A, frame 3
;
; The werewulf's head and shoulders, types $40 to $4F: the night-time form of
; Sabreman's, drawn 12 units above the legs. Types $42, $44.
spr_089:
  DEFB $03,$1D
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $03,$00
  DEFB $00,$00,$00,$00,$07,$03,$80,$00
  DEFB $00,$00,$0F,$06,$C0,$80,$00,$00
  DEFB $0F,$06,$80,$00,$00,$00,$0F,$06
  DEFB $00,$00,$00,$00,$0F,$07,$C0,$00
  DEFB $00,$00,$07,$03,$E0,$C0,$00,$00
  DEFB $03,$01,$F0,$E0,$00,$00,$01,$00
  DEFB $FF,$F7,$F8,$D0,$01,$00,$FF,$F7
  DEFB $FC,$D8,$01,$00,$FF,$EF,$FC,$D8
  DEFB $01,$00,$FF,$EF,$FC,$D8,$01,$00
  DEFB $FF,$FF,$FC,$E8,$03,$01,$FF,$FF
  DEFB $FC,$F8,$03,$01,$FF,$FF,$FC,$F8
  DEFB $01,$00,$FF,$7F,$FC,$F8,$01,$00
  DEFB $FF,$8F,$F8,$E0,$01,$00,$FF,$9F
  DEFB $F8,$F0,$03,$01,$FF,$F7,$F8,$F0
  DEFB $03,$01,$FF,$D7,$F8,$F0,$01,$00
  DEFB $FF,$BB,$F8,$F0,$00,$00,$FF,$7B
  DEFB $F8,$F0,$00,$00,$FF,$77,$F8,$F0
  DEFB $01,$00,$FF,$EF,$F0,$E0,$01,$00
  DEFB $EF,$C0,$F0,$E0,$00,$00,$C1,$00
  DEFB $E0,$C0,$00,$00,$01,$00,$C0,$80
  DEFB $00,$00,$00,$00,$80,$00

; Werewulf's head and shoulders, view A, frame 4
;
; The werewulf's head and shoulders, types $40 to $4F: the night-time form of
; Sabreman's, drawn 12 units above the legs. Type $43.
spr_090:
  DEFB $03,$1D
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$10,$00,$00,$00,$00,$00
  DEFB $38,$10,$00,$00,$00,$00,$70,$20
  DEFB $00,$00,$00,$00,$FC,$60,$00,$00
  DEFB $00,$00,$FF,$7C,$C0,$00,$0C,$00
  DEFB $7F,$3F,$E0,$C0,$0E,$0C,$3F,$0F
  DEFB $FF,$EF,$FF,$DE,$0F,$01,$FF,$EF
  DEFB $FF,$D6,$03,$01,$FF,$DF,$FF,$C6
  DEFB $03,$01,$FF,$DF,$FF,$EE,$03,$01
  DEFB $FF,$FF,$FE,$EC,$03,$01,$FF,$FF
  DEFB $FE,$FC,$03,$00,$FF,$FF,$FE,$FC
  DEFB $01,$00,$FF,$7F,$FC,$F8,$01,$00
  DEFB $FF,$8F,$F8,$E0,$01,$00,$FF,$9F
  DEFB $F8,$F0,$03,$01,$FF,$F7,$F8,$F0
  DEFB $03,$01,$FF,$D7,$F8,$F0,$01,$00
  DEFB $FF,$BB,$F8,$F0,$00,$00,$FF,$7B
  DEFB $F8,$F0,$00,$00,$FF,$77,$F8,$F0
  DEFB $01,$00,$FF,$EF,$F0,$E0,$01,$00
  DEFB $EF,$C0,$F0,$E0,$00,$00,$C1,$00
  DEFB $E0,$C0,$00,$00,$01,$00,$C0,$80
  DEFB $00,$00,$00,$00,$80,$00

; Werewulf's head and shoulders, view B, frame 4
;
; The werewulf's head and shoulders, types $40 to $4F: the night-time form of
; Sabreman's, drawn 12 units above the legs. Type $4B.
spr_091:
  DEFB $03,$1E
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00
  DEFB $20,$00,$00,$00,$00,$00,$70,$20
  DEFB $00,$00,$00,$00,$78,$30,$00,$00
  DEFB $00,$00,$F8,$30,$00,$00,$01,$00
  DEFB $F8,$F0,$00,$00,$03,$01,$F0,$E0
  DEFB $10,$00,$07,$03,$E0,$C0,$38,$10
  DEFB $0F,$07,$C0,$80,$3C,$18,$1F,$0F
  DEFB $FF,$7F,$FC,$98,$1F,$0F,$FF,$7F
  DEFB $FC,$B8,$1F,$0F,$FF,$7F,$F8,$B0
  DEFB $0F,$07,$FF,$7F,$F0,$A0,$0F,$07
  DEFB $FF,$7F,$E0,$80,$0F,$07,$FF,$FE
  DEFB $C0,$00,$0F,$07,$FF,$F1,$E0,$C0
  DEFB $0F,$07,$FF,$EA,$E0,$80,$07,$02
  DEFB $FF,$1A,$F0,$20,$03,$01,$FF,$FB
  DEFB $F0,$E0,$03,$01,$FF,$F6,$F0,$A0
  DEFB $03,$01,$FF,$FF,$F0,$E0,$03,$01
  DEFB $FF,$7F,$E0,$C0,$01,$00,$FF,$F7
  DEFB $E0,$40,$01,$00,$FF,$F2,$F0,$60
  DEFB $03,$01,$FF,$FF,$F8,$D0,$03,$01
  DEFB $FF,$FF,$F8,$B0,$07,$03,$FF,$DF
  DEFB $F8,$E0,$07,$03,$DF,$00,$78,$30
  DEFB $0F,$04,$00,$00,$3C,$08,$04,$00
  DEFB $00,$00,$08,$00

; Werewulf's head and shoulders, view B, frame 3
;
; The werewulf's head and shoulders, types $40 to $4F: the night-time form of
; Sabreman's, drawn 12 units above the legs. Types $4A, $4C.
spr_092:
  DEFB $03,$1E
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00
  DEFB $80,$00,$00,$00,$01,$00,$C0,$80
  DEFB $00,$00,$00,$00,$E0,$40,$00,$00
  DEFB $00,$00,$F0,$60,$00,$00,$01,$00
  DEFB $F0,$E0,$00,$00,$07,$01,$E0,$C0
  DEFB $10,$00,$0F,$07,$C0,$80,$38,$10
  DEFB $1F,$0F,$80,$00,$3C,$08,$3F,$1E
  DEFB $FF,$FF,$FE,$8C,$7F,$3E,$FF,$FF
  DEFB $FE,$9C,$3F,$1E,$FF,$FF,$FC,$B8
  DEFB $3F,$1F,$FF,$7F,$F8,$B0,$3F,$1F
  DEFB $FF,$7F,$F0,$80,$1F,$0F,$FF,$FE
  DEFB $C0,$00,$1F,$0F,$FF,$F1,$E0,$C0
  DEFB $1F,$0F,$FF,$EA,$E0,$80,$0F,$06
  DEFB $FF,$1A,$F0,$20,$07,$01,$FF,$FB
  DEFB $F0,$E0,$03,$01,$FF,$F6,$F0,$A0
  DEFB $03,$01,$FF,$FF,$F0,$E0,$03,$01
  DEFB $FF,$7F,$E0,$C0,$01,$00,$FF,$F7
  DEFB $E0,$40,$01,$00,$FF,$F2,$F0,$60
  DEFB $03,$01,$FF,$FF,$F8,$D0,$03,$01
  DEFB $FF,$FF,$F8,$B0,$07,$03,$FF,$DF
  DEFB $F8,$70,$07,$03,$BF,$00,$78,$30
  DEFB $0F,$04,$00,$00,$3C,$08,$04,$00
  DEFB $00,$00,$08,$00

; Werewulf's head and shoulders, view B, frame 2
;
; The werewulf's head and shoulders, types $40 to $4F: the night-time form of
; Sabreman's, drawn 12 units above the legs. Types $49, $4D.
spr_093:
  DEFB $03,$1E
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00
  DEFB $00,$00,$00,$00,$03,$00,$00,$00
  DEFB $00,$00,$07,$03,$80,$00,$00,$00
  DEFB $03,$01,$C0,$80,$00,$00,$03,$01
  DEFB $C0,$80,$08,$00,$03,$01,$C0,$80
  DEFB $1C,$08,$07,$03,$C0,$80,$0E,$04
  DEFB $0F,$07,$80,$00,$0E,$04,$1F,$0E
  DEFB $FF,$FF,$FE,$8C,$3F,$1C,$FF,$FF
  DEFB $FE,$BC,$7F,$3C,$FF,$FF,$FC,$B8
  DEFB $7F,$3E,$FF,$7F,$F8,$B0,$3F,$1F
  DEFB $FF,$7F,$F0,$80,$3F,$1F,$FF,$FE
  DEFB $C0,$00,$1F,$0F,$FF,$F1,$E0,$C0
  DEFB $0F,$07,$FF,$EA,$E0,$80,$07,$02
  DEFB $FF,$1A,$F0,$20,$03,$01,$FF,$FB
  DEFB $F0,$E0,$03,$01,$FF,$F6,$F0,$A0
  DEFB $03,$01,$FF,$FF,$F0,$E0,$03,$01
  DEFB $FF,$7F,$E0,$C0,$01,$00,$FF,$F7
  DEFB $E0,$60,$01,$00,$FF,$F2,$F0,$40
  DEFB $03,$01,$FF,$FF,$F8,$D0,$03,$01
  DEFB $FF,$FF,$F8,$B0,$07,$03,$FF,$DF
  DEFB $F8,$70,$07,$03,$DF,$00,$78,$30
  DEFB $0F,$04,$00,$00,$3C,$08,$04,$00
  DEFB $00,$00,$08,$00

; Werewulf's head and shoulders, view B, frame 1
;
; The werewulf's head and shoulders, types $40 to $4F: the night-time form of
; Sabreman's, drawn 12 units above the legs. Type $48.
spr_094:
  DEFB $03,$1E
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$06,$00,$00,$00,$0C,$00
  DEFB $0F,$06,$00,$00,$1E,$0C,$07,$03
  DEFB $80,$00,$0F,$06,$07,$03,$80,$00
  DEFB $0F,$06,$07,$03,$80,$00,$1F,$0E
  DEFB $0F,$06,$00,$00,$3E,$1C,$0F,$06
  DEFB $FF,$FF,$FC,$B8,$1F,$0D,$FF,$FF
  DEFB $FC,$B8,$1F,$0D,$FF,$FF,$F8,$B0
  DEFB $3F,$1E,$FF,$FF,$F8,$B0,$3F,$1F
  DEFB $FF,$7F,$F8,$B0,$3F,$1F,$FF,$FE
  DEFB $F0,$20,$1F,$0F,$FF,$F1,$E0,$C0
  DEFB $0F,$07,$FF,$EA,$E0,$80,$07,$02
  DEFB $FF,$1A,$F0,$20,$03,$01,$FF,$FB
  DEFB $F0,$E0,$03,$01,$FF,$F6,$F0,$A0
  DEFB $03,$01,$FF,$FF,$F0,$E0,$03,$01
  DEFB $FF,$7F,$E0,$C0,$01,$00,$FF,$F7
  DEFB $E0,$40,$01,$00,$FF,$F2,$F0,$60
  DEFB $03,$01,$FF,$FF,$F8,$D0,$03,$01
  DEFB $FF,$FF,$F8,$B0,$07,$03,$FF,$DF
  DEFB $F8,$70,$07,$03,$DF,$00,$78,$30
  DEFB $0F,$04,$00,$00,$3C,$08,$04,$00
  DEFB $00,$00,$08,$00

; Werewulf's head and shoulders, view A, occasional frame
;
; The werewulf's head and shoulders, types $40 to $4F: the night-time form of
; Sabreman's, drawn 12 units above the legs. Type $46.
spr_095:
  DEFB $03,$1D
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $03,$00
  DEFB $00,$00,$00,$00,$07,$03,$80,$00
  DEFB $00,$00,$0F,$06,$C0,$80,$00,$00
  DEFB $0F,$06,$80,$00,$00,$00,$0F,$06
  DEFB $80,$00,$00,$00,$07,$03,$E0,$80
  DEFB $00,$00,$03,$01,$F0,$E0,$00,$00
  DEFB $01,$00,$F8,$F0,$00,$00,$00,$00
  DEFB $FF,$77,$F0,$C0,$00,$00,$FF,$77
  DEFB $F8,$D0,$01,$00,$FF,$F7,$F8,$D0
  DEFB $01,$00,$FF,$F7,$FC,$D8,$01,$00
  DEFB $FF,$FF,$FC,$E8,$01,$00,$FF,$FF
  DEFB $FC,$F8,$03,$00,$FF,$FF,$FC,$F8
  DEFB $07,$03,$FF,$3F,$F8,$F0,$07,$03
  DEFB $FF,$FF,$F0,$C0,$07,$00,$FF,$3F
  DEFB $F0,$E0,$0E,$04,$FF,$7F,$F0,$E0
  DEFB $0F,$06,$FF,$EF,$F0,$E0,$1F,$0F
  DEFB $FF,$DF,$F0,$E0,$1F,$0B,$FF,$DF
  DEFB $F0,$E0,$0F,$06,$FF,$3F,$F0,$E0
  DEFB $06,$00,$7F,$3F,$E0,$C0,$00,$00
  DEFB $7F,$33,$C0,$80,$00,$00,$77,$23
  DEFB $C0,$80,$00,$00,$27,$03,$80,$00
  DEFB $00,$00,$03,$00,$00,$00

; Werewulf's head and shoulders, view A, second occasional frame
;
; The werewulf's head and shoulders, types $40 to $4F: the night-time form of
; Sabreman's, drawn 12 units above the legs. Type $47.
spr_096:
  DEFB $03,$1D
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $03,$00
  DEFB $00,$00,$00,$00,$07,$03,$80,$00
  DEFB $00,$00,$0F,$06,$C0,$80,$00,$00
  DEFB $0F,$06,$80,$00,$00,$00,$0F,$06
  DEFB $00,$00,$00,$00,$0F,$06,$00,$00
  DEFB $00,$00,$0F,$07,$80,$00,$00,$00
  DEFB $0F,$07,$C0,$80,$00,$00,$07,$03
  DEFB $FF,$DF,$F8,$D0,$03,$01,$FF,$DF
  DEFB $FC,$D8,$03,$01,$FF,$DF,$FC,$D8
  DEFB $03,$01,$FF,$DF,$FE,$DC,$03,$01
  DEFB $FF,$DF,$FE,$FC,$03,$01,$FF,$FF
  DEFB $FE,$FC,$01,$00,$FF,$FF,$FE,$FC
  DEFB $01,$00,$FF,$FF,$FC,$F8,$00,$00
  DEFB $FF,$1F,$FC,$E0,$00,$00,$7F,$3F
  DEFB $FE,$FC,$00,$00,$7F,$3F,$FF,$FE
  DEFB $00,$00,$7F,$3F,$FE,$F8,$00,$00
  DEFB $7F,$3F,$FF,$FE,$00,$00,$7F,$3F
  DEFB $FF,$FE,$00,$00,$7F,$3F,$FE,$F8
  DEFB $00,$00,$7F,$3F,$F8,$F0,$00,$00
  DEFB $7F,$38,$F8,$70,$00,$00,$3C,$18
  DEFB $F8,$70,$00,$00,$1C,$08,$70,$20
  DEFB $00,$00,$08,$00,$20,$00

; Werewulf's head and shoulders, view B, occasional frame
;
; The werewulf's head and shoulders, types $40 to $4F: the night-time form of
; Sabreman's, drawn 12 units above the legs. Type $4E.
spr_097:
  DEFB $03,$1E
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00
  DEFB $20,$00,$00,$00,$00,$00,$70,$20
  DEFB $00,$00,$00,$00,$78,$30,$00,$00
  DEFB $00,$00,$F8,$30,$00,$00,$01,$00
  DEFB $F8,$F0,$00,$00,$03,$01,$F0,$E0
  DEFB $10,$00,$07,$03,$E0,$C0,$38,$10
  DEFB $0F,$07,$C0,$00,$3C,$18,$1F,$0F
  DEFB $FF,$7F,$FC,$98,$1F,$0F,$FF,$7F
  DEFB $FC,$B8,$1F,$0F,$FF,$7F,$F8,$B0
  DEFB $0F,$07,$FF,$7F,$F0,$E0,$0F,$07
  DEFB $FF,$FF,$F0,$E0,$07,$03,$FF,$FF
  DEFB $FC,$80,$07,$03,$FF,$FF,$FE,$7C
  DEFB $07,$03,$FF,$FC,$FE,$C0,$03,$01
  DEFB $FF,$03,$FF,$92,$01,$00,$FF,$FF
  DEFB $FF,$12,$01,$00,$FF,$FE,$FF,$7E
  DEFB $01,$00,$FF,$FF,$FF,$EA,$01,$00
  DEFB $FF,$FF,$FE,$FC,$00,$00,$FF,$7D
  DEFB $FC,$F0,$00,$00,$FF,$7C,$F0,$A0
  DEFB $01,$00,$FF,$FF,$F0,$E0,$01,$00
  DEFB $FF,$FF,$F0,$E0,$01,$00,$FF,$F7
  DEFB $F0,$E0,$01,$00,$FF,$E0,$F0,$E0
  DEFB $03,$01,$E0,$80,$F8,$30,$01,$00
  DEFB $80,$00,$30,$00

; Werewulf's head and shoulders, view B, second occasional frame
;
; The werewulf's head and shoulders, types $40 to $4F: the night-time form of
; Sabreman's, drawn 12 units above the legs. Type $4F.
spr_098:
  DEFB $03,$1E
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00
  DEFB $80,$00,$00,$00,$01,$00,$C0,$80
  DEFB $00,$00,$00,$00,$E0,$40,$00,$00
  DEFB $00,$00,$E0,$40,$00,$00,$01,$00
  DEFB $E0,$C0,$00,$00,$03,$01,$E0,$C0
  DEFB $10,$00,$07,$03,$C0,$80,$38,$10
  DEFB $0F,$07,$80,$00,$3C,$18,$1F,$0E
  DEFB $FF,$FF,$FC,$D8,$1F,$0E,$FF,$FF
  DEFB $FC,$D8,$1F,$0E,$FF,$FF,$FC,$D8
  DEFB $3F,$1E,$FF,$FF,$FC,$B8,$3F,$1F
  DEFB $FF,$FF,$FC,$F8,$3F,$1F,$FF,$3F
  DEFB $F8,$F0,$3F,$1C,$FF,$CF,$F8,$F0
  DEFB $1F,$0A,$FF,$14,$F0,$E0,$0F,$03
  DEFB $FF,$F3,$E0,$00,$07,$03,$FF,$FB
  DEFB $E0,$C0,$07,$03,$FF,$5F,$E0,$C0
  DEFB $03,$01,$FF,$FF,$E0,$C0,$03,$01
  DEFB $FF,$FF,$E0,$C0,$01,$00,$FF,$BB
  DEFB $E0,$C0,$01,$00,$FF,$93,$E0,$C0
  DEFB $01,$00,$FF,$FF,$C0,$80,$03,$01
  DEFB $FF,$FF,$E0,$C0,$03,$01,$FF,$FF
  DEFB $E0,$C0,$03,$01,$FF,$E1,$E0,$C0
  DEFB $03,$01,$E1,$80,$F0,$60,$01,$00
  DEFB $80,$00,$60,$00

; Transformation, frame 1
;
; When day turns to night or back, chk_and_init_transform removes Sabreman's
; upper half and turns his legs into one of types $5C to $5F, chosen at random
; every fourth frame and never the same twice running (rand_legs_sprite), eight
; times over; then he comes back in his other form. Type $5C.
spr_099:
  DEFB $03,$20
  DEFB $00,$00,$00,$00,$02,$00
  DEFB $40,$00,$00,$00,$0F,$02
  DEFB $F0,$40,$00,$00,$3F,$0E
  DEFB $FC,$70,$00,$00,$FF,$3E
  DEFB $FF,$7C,$01,$00,$FE,$F8
  DEFB $7F,$3F,$81,$00,$F8,$E0
  DEFB $3F,$0F,$81,$00,$F0,$60
  DEFB $0F,$06,$E7,$81,$F8,$70
  DEFB $1F,$0E,$FF,$E7,$F8,$30
  DEFB $1F,$0D,$FF,$FF,$FC,$98
  DEFB $3F,$1D,$FF,$FF,$FC,$B8
  DEFB $3F,$1B,$FF,$FF,$FC,$D8
  DEFB $3F,$1B,$FF,$FF,$F8,$C0
  DEFB $1F,$03,$FF,$00,$E0,$C0
  DEFB $1F,$0C,$FF,$7F,$C0,$00
  DEFB $1F,$0E,$FF,$7F,$C6,$80
  DEFB $3F,$1D,$FF,$BF,$CF,$86
  DEFB $3F,$1D,$FF,$FF,$CF,$86
  DEFB $7F,$39,$FF,$FF,$EF,$C6
  DEFB $7B,$31,$FF,$C3,$FF,$EE
  DEFB $FB,$71,$FF,$3C,$FE,$EC
  DEFB $F3,$60,$FF,$FF,$FE,$2C
  DEFB $67,$03,$FF,$FF,$FE,$DC
  DEFB $0F,$07,$FF,$81,$FE,$EC
  DEFB $1F,$0E,$FF,$7E,$FC,$70
  DEFB $1F,$0D,$FF,$BD,$F8,$B0
  DEFB $1F,$0D,$FF,$BD,$F8,$B0
  DEFB $0F,$05,$FF,$BD,$F0,$A0
  DEFB $07,$02,$FF,$DB,$E0,$40
  DEFB $02,$00,$FF,$5A,$40,$00
  DEFB $00,$00,$7E,$24,$00,$00
  DEFB $00,$00,$3C,$00,$00,$00

; Transformation, frame 2
;
; When day turns to night or back, chk_and_init_transform removes Sabreman's
; upper half and turns his legs into one of types $5C to $5F, chosen at random
; every fourth frame and never the same twice running (rand_legs_sprite), eight
; times over; then he comes back in his other form. Type $5D.
spr_100:
  DEFB $03,$21
  DEFB $00,$00,$07,$00,$F0,$00
  DEFB $18,$00
  DEFB $0F,$07,$F8,$F0,$3C,$18,$0F,$03
  DEFB $F8,$F0,$3E,$1C,$7F,$00,$FC,$38
  DEFB $1F,$0E,$FD,$78,$FC,$38,$1F,$0E
  DEFB $FF,$F1,$FE,$0C,$0F,$07,$FF,$CF
  DEFB $FE,$70,$37,$03,$FF,$3F,$FF,$7E
  DEFB $7B,$30,$3F,$1F,$FF,$FE,$FC,$78
  DEFB $3F,$1F,$FE,$FC,$FE,$5C,$1F,$0F
  DEFB $FF,$FA,$5F,$0E,$BF,$13,$FE,$F4
  DEFB $1F,$0D,$FF,$9C,$FC,$E8,$1F,$0B
  DEFB $FF,$DF,$FE,$2C,$0F,$07,$FF,$FF
  DEFB $FE,$CC,$0F,$07,$FF,$FF,$FF,$E6
  DEFB $07,$03,$FF,$FF,$FF,$C6,$03,$01
  DEFB $FF,$8F,$FF,$B6,$03,$00,$FF,$01
  DEFB $FF,$F6,$07,$03,$FF,$30,$FF,$7A
  DEFB $0F,$04,$FF,$7C,$FE,$38,$0F,$04
  DEFB $FF,$2F,$F8,$40,$0F,$04,$FF,$03
  DEFB $F0,$20,$0F,$04,$FF,$08,$F0,$20
  DEFB $0F,$04,$FF,$33,$F8,$10,$07,$02
  DEFB $FF,$37,$F8,$10,$07,$03,$FF,$07
  DEFB $F8,$10,$07,$02,$FF,$80,$F8,$10
  DEFB $07,$03,$FF,$60,$F8,$10,$03,$01
  DEFB $FF,$9E,$F0,$60,$01,$00,$FF,$E5
  DEFB $E0,$80,$00,$00,$FF,$78,$80,$00
  DEFB $00,$00,$78,$00,$00,$00

; Transformation, frame 3
;
; When day turns to night or back, chk_and_init_transform removes Sabreman's
; upper half and turns his legs into one of types $5C to $5F, chosen at random
; every fourth frame and never the same twice running (rand_legs_sprite), eight
; times over; then he comes back in his other form. Type $5E.
spr_101:
  DEFB $03,$26
  DEFB $00,$00,$07,$00,$E0,$00
  DEFB $07,$00
  DEFB $AF,$07,$F0,$E0,$0F,$06,$F7,$A3
  DEFB $E0,$00,$1F,$0F,$F7,$23,$C0,$80
  DEFB $1F,$0B,$FB,$31,$F0,$C0,$0F,$07
  DEFB $F9,$90,$F8,$F0,$0F,$07,$F8,$D0
  DEFB $F8,$70,$1F,$0F,$F9,$F0,$F0,$A0
  DEFB $1F,$0B,$FF,$69,$F0,$C0,$0F,$06
  DEFB $FF,$7D,$F8,$F0,$0F,$07,$FF,$FD
  DEFB $F8,$F0,$0F,$07,$FF,$FB,$F0,$E0
  DEFB $0F,$07,$FF,$F7,$E0,$C0,$1F,$0F
  DEFB $FF,$F7,$C0,$80,$1F,$0C,$FF,$6F
  DEFB $E0,$C0,$0F,$03,$FF,$7F,$F0,$E0
  DEFB $1F,$0F,$FF,$5F,$F0,$E0,$3F,$17
  DEFB $FF,$5F,$F8,$F0,$3F,$1B,$FF,$1F
  DEFB $F0,$C0,$3F,$1A,$3F,$1E,$F8,$30
  DEFB $3E,$18,$1F,$01,$FC,$F8,$3C,$18
  DEFB $1F,$0F,$FC,$F8,$3C,$18,$3F,$1F
  DEFB $FE,$FC,$18,$00,$3F,$1D,$FF,$FE
  DEFB $03,$00,$7F,$3D,$FF,$FE,$0F,$03
  DEFB $FF,$3E,$FE,$F8,$3F,$0F,$FF,$1E
  DEFB $F8,$C0,$7F,$3F,$FF,$A6,$F8,$30
  DEFB $FF,$7E,$FF,$F8,$F8,$70,$FF,$78
  DEFB $FF,$F0,$F8,$F0,$78,$00,$FF,$01
  DEFB $F0,$E0,$00,$00,$3F,$0D,$E0,$C0
  DEFB $00,$00,$3F,$1C,$C0,$00,$00,$00
  DEFB $3C,$18,$00,$00,$00,$00,$7C,$38
  DEFB $00,$00,$00,$00,$78,$30,$00,$00
  DEFB $00,$00,$78,$30,$00,$00,$00,$00
  DEFB $30,$00,$00,$00

; Transformation, frame 4
;
; When day turns to night or back, chk_and_init_transform removes Sabreman's
; upper half and turns his legs into one of types $5C to $5F, chosen at random
; every fourth frame and never the same twice running (rand_legs_sprite), eight
; times over; then he comes back in his other form. Type $5F.
spr_102:
  DEFB $03,$23
  DEFB $03,$00,$00,$00,$C0,$00
  DEFB $0F,$03
  DEFB $81,$00,$F0,$C0,$3F,$0F,$C1,$80
  DEFB $FC,$F0,$7F,$3F,$80,$00,$FE,$7C
  DEFB $FF,$7C,$00,$00,$7F,$1E,$FC,$70
  DEFB $00,$00,$3F,$0E,$7F,$3C,$00,$00
  DEFB $FF,$3E,$3F,$1F,$B3,$00,$FE,$F8
  DEFB $1F,$0F,$FF,$33,$F8,$20,$0F,$02
  DEFB $FF,$F7,$F0,$C0,$03,$01,$FF,$F7
  DEFB $F8,$F0,$07,$03,$FF,$FF,$F8,$F0
  DEFB $07,$03,$FF,$FF,$F0,$E0,$03,$01
  DEFB $FF,$FF,$E0,$C0,$01,$00,$FF,$0F
  DEFB $C0,$80,$01,$00,$FF,$F0,$80,$00
  DEFB $01,$00,$FF,$FF,$80,$00,$03,$01
  DEFB $FF,$FF,$80,$00,$03,$01,$FF,$FF
  DEFB $80,$00,$07,$01,$FF,$FF,$80,$00
  DEFB $0F,$07,$FF,$FF,$C0,$80,$1F,$0F
  DEFB $FF,$C7,$F0,$C0,$3F,$17,$FF,$BB
  DEFB $F8,$F0,$7F,$13,$FF,$3D,$F0,$E0
  DEFB $FF,$58,$FF,$FE,$F8,$D0,$FF,$5F
  DEFB $FF,$FE,$FC,$58,$FF,$4E,$FF,$7E
  DEFB $7E,$3C,$FF,$60,$FF,$FE,$3E,$0C
  DEFB $FF,$6B,$FF,$FE,$9E,$0C,$7F,$0F
  DEFB $FF,$BC,$DE,$8C,$3F,$1F,$FF,$3E
  DEFB $DE,$8C,$3F,$17,$FF,$EE,$EC,$C0
  DEFB $1F,$0C,$EF,$06,$F0,$E0,$0C,$00
  DEFB $07,$02,$E0,$00,$00,$00,$02,$00
  DEFB $00,$00

; Cold start
;
; Wipes the game's whole RAM -- $5BA0 to $6107, 1384 bytes -- and falls into
; main. The one thing it keeps is the ROM's frame counter, which it reads
; before the wipe and writes back afterwards as the first random seed. A
; machine that has been switched on for a different length of time therefore
; gets a different castle.
;
; The read has to come first for a second reason: FRAMES, at $5C78, lies inside
; the object table (it is byte 16 of object 3), so the wipe destroys it.
START:
  LD HL,$5BA0             ; $5BA0 to $6107: the variables and all 40 object
                          ; records
  LD BC,$0568
  LD A,($5C78)            ; FRAMES, the ROM's 50Hz counter, as the seed
  PUSH AF
  CALL clr_mem            ; clear them, and take the seed back
  POP AF                  ;
  LD ($5BA0),A            ; put it back where the wipe cannot reach it
  JR main                 ; and set up a game

; Restart after a game
;
; Used by the routine at await_restart.
;
; Clears from $5BA8 rather than $5BA0, which leaves $5BA0 to $5BA7 alone: the
; game seed, the frame counter, the random byte and the chosen control method.
; That is deliberate: the next game should carry on the random sequence rather
; than replay the last one, and should not ask again which keys you wanted. It
; falls into main.
;
; Reached by a jump from await_restart once the game-over screen has been seen.
start_menu:
  LD HL,$5BA8             ; $5BA8 to $6107
  LD BC,$0560
  CALL clr_mem

; Set up and play
;
; Used by the routine at START.
;
; Builds the lookup tables, shows the menu, and then does the four things that
; make a game different from the last one: shuffles which objects the wizard
; will ask for, chooses a starting room, sets the sun and moon running, and
; places the special objects. Then it falls into player_dies, which brings
; Sabreman on exactly as it does after a death.
;
; Three of those choices come from the game seed at $5BA0, and two of them from
; the same two bits of it: bits 0 and 1 pick the starting room in
; init_start_location and also how far shuffle_objects_required rotates the
; wizard's list. So on the first game after loading, the starting room tells
; you the order the cauldron will ask in. The charms' placing adds the refresh
; register, so that one is not tied.
main:
  CALL build_lookup_tbls  ; the tables at reverse_bits_tbl -- see
                          ; build_lookup_tbls
  XOR A                   ; no room has been played yet, so the first room
  LD ($5BB2),A            ; entry has nothing to save back
  LD (flags12_1),A        ; clear byte 12 of the player record saved at
                          ; plyr_spr_1_scratchpad
  LD A,$05                ; five lives; the first pass through player_dies
                          ; takes one of them
  LD ($5BBA),A
  LD HL,$5BA0             ; stir the frame counter into the game seed; it is
  LD A,($5BA2)            ; zero on the first game after loading
  ADD A,(HL)              ;
  LD (HL),A               ;
  CALL clear_scrn         ; clear the screen
  CALL do_menu_selection  ; the control menu; the seed also goes up by one
                          ; every time round its loop
  LD DE,start_game_tune   ; the tune that plays as the game starts
  CALL play_audio         ;
  CALL shuffle_objects_required ; rotate the list of objects the cauldron wants
  CALL init_start_location ; pick one of four starting rooms, and make the
                           ; player records
  CALL init_sun           ; the sun starts at the left of its frame
  CALL init_special_objects ; deal the charms and extra lives out to their
                            ; places

; Start a life
;
; Used by the routine at next_frame_or_die.
;
; Reached at the start of a game and whenever both halves of Sabreman have gone
; from the object table. lose_life copies back the two player records that were
; saved when he entered the room, takes a life (ending the game when there are
; none), and makes him man or werewolf by whether it is day or night. The
; records come back as type 120, so he materialises where he came in.
player_dies:
  CALL lose_life          ; restore Sabreman and take a life

; Enter a room
;
; Used by the routine at exit_screen.
;
; Builds the room Sabreman is in -- its walls and objects into the object
; table, and the flag that tells no_delay to redraw the whole screen -- then
; falls into onscreen_loop, which runs frames until something jumps out.
; Leaving a room comes back here from exit_screen, so this is the loop over
; rooms and onscreen_loop the loop over frames.
game_loop:
  CALL build_screen_objects ; build the room's objects and clear the screen
                            ; buffer

; Walk the object table
;
; Used by the routine at next_frame_or_die.
;
; The start of one frame. IX steps through 40 object records of 32 bytes each,
; from $5C08 up to font -- the byte just below the font. The game deliberately
; puts its object table on top of the ROM's system variables: from $5BA0
; upwards nothing the ROM keeps there is wanted, and Knight Lore does not call
; the ROM once it is running. LAST-K, at $5C08, is the first byte of object
; zero.
;
; Objects 0 and 1 are Sabreman's legs and upper body, and objects 2 and 3 the
; slots for the charms that lie in the current room. The rest are the room's
; walls, blocks and creatures in the order the room was built.
onscreen_loop:
  LD A,($5BA2)            ; $5BBC starts the frame at the frame counter's low
  LD ($5BBC),A            ; byte and goes up by one for each object
  LD IX,$5C08             ; IX = the first object record

; Next object
;
; Used by the routine at ret_from_tbl_jp.
;
; The stack is reloaded to $5BA0 for every object, so it grows downwards into
; the printer buffer below and nothing a handler leaves on it can leak into the
; next one. The loop pushes its own continuation, ret_from_tbl_jp, before
; dispatching, so an object handler ends with a plain RET -- and a handler can
; jump away mid-routine, to another handler or out to the game-over code,
; without tidying the stack.
;
; $5BBC counts up by one per object, so two objects of the same kind see
; opposite parities in the same frame; upd_176_177 uses that to make
; neighbouring fires flicker out of step.
update_sprite_loop:
  LD SP,$5BA0             ; reset the stack for this object
  LD HL,$5BBC             ; this object's phase: the frame counter plus its
  INC (HL)                ; place in the table
  LD HL,ret_from_tbl_jp   ; push the return address the handler will RET to
  PUSH HL                 ;
  CALL save_2d_info       ; keep last frame's screen rectangle so the old image
                          ; can be wiped

; Dispatch on object type
;
; Used by the routine at upd_127.
;
; Byte 0 of an object record is its type, which is also its sprite number. This
; looks the type up in upd_sprite_jmp_tbl and jumps to the handler. Handlers
; animate an object by changing this byte, so the same object passes through
; several types -- and several handlers -- as it moves.
jump_to_upd_object:
  LD L,(IX+$00)            ; the type indexes the table of handlers
  LD BC,upd_sprite_jmp_tbl ;

; Jump through a table of addresses
;
; Used by the routines at upd_131_to_133, move_guard_wizard_NSEW,
; dispatch_on_facing and act_on_comparison.
;
; Doubles the index, adds the base, loads the word there and jumps to it. The
; object dispatch uses it, and so do the other tables of routines: the finale
; sparks' directions at dX_dY_tbl, the guards' patrol directions, the arch
; nudges and the player's movement.
;
; L the index
; BC the base of a table of words
jump_to_tbl_entry:
  LD H,$00                ; HL = base + 2 * index
  ADD HL,HL               ;
  ADD HL,BC               ;
  LD A,(HL)               ; fetch the address and go
  INC HL                  ;
  LD H,(HL)               ;
  LD L,A                  ;
  JP (HL)                 ;

; One object done
;
; Every handler returns here. It stirs the refresh register into the random
; byte at $5BA5 -- so the sequence depends on how much work the frame did --
; then advances IX by 32 and goes round again until it reaches the font, when
; the frame is finished.
ret_from_tbl_jp:
  LD A,R                  ; R changes with every instruction fetched
  LD C,A                  ;
  LD A,($5BA5)            ;
  ADD A,C                 ;
  LD ($5BA5),A            ;
  LD BC,$0020             ; 32 bytes per object record
  ADD IX,BC               ;
  PUSH IX                 ; HL = IX
  POP HL                  ;
  LD BC,font              ; the end of the object table is the start of the
                          ; font
  AND A
  SBC HL,BC
  JR NC,end_of_frame
  JR update_sprite_loop   ; not there yet

; End of frame
;
; Used by the routine at ret_from_tbl_jp.
;
; Draws everything the object walk decided on and then burns whatever time is
; left, so the game runs at an even speed rather than at whatever speed the
; room happens to allow.
;
; The time is counted in units of drawing. The renderer counts at $5BBE every
; object it draws and every rectangle it wipes, and this waits for six units
; less that count. One unit of waiting is 1280 turns of a 26-cycle loop, about
; 33,300 T-states, just under half a 50Hz frame. So a room where fewer than six
; things change runs at the same speed as one where six do, and a room busier
; than that runs slower -- the delay can only pad, never take time back.
end_of_frame:
  LD HL,($5BA2)           ; the 16-bit frame counter
  INC HL                  ;
  LD ($5BA2),HL           ;
  LD A,($5BA5)            ; stir it into the random byte, with whatever memory
  ADD A,(HL)              ; it happens to address
  ADD A,L                 ;
  ADD A,H                 ;
  LD ($5BA5),A            ;
  LD HL,$5BB2             ; a frame has been played: the next room entry saves
  SET 0,(HL)              ; the charms' places back
  CALL handle_pause       ; SPACE pauses
  CALL init_cauldron_bubbles ; bubbles in the cauldron room
  CALL list_objects_to_draw ; list the objects flagged to be drawn
  CALL render_dynamic_objects ; wipe, draw in depth order into the buffer at
                              ; screen_buffer, and copy the changes to the
                              ; screen
  LD A,($5BC5)               ; during the finale, a tone pitched by the last
  AND A                      ; spark's height
  CALL NZ,sound_pitch_from_a ;
  LD A,($5BBE)            ; six units, less what this frame already used
  NEG                     ;
  ADD A,$06               ;
  LD B,A                  ; none left to wait
  JP M,no_delay           ;
  JR Z,no_delay           ;

; Wait one unit
;
; Used by the routine at delay_loop.
;
; 1280 turns of the loop at delay_loop.
;
; B the number of units still to wait
game_delay:
  LD HL,$0500             ; 1280 turns of 26 T-states each

; Frame delay loop
;
; Counts HL down, then goes back to game_delay for another unit until B runs
; out.
delay_loop:
  DEC HL                  ; 26 T-states a turn
  LD A,L                  ;
  OR H                    ;
  JR NZ,delay_loop        ;
  DJNZ game_delay         ; the next unit

; Redraw the whole screen on entering a room
;
; Used by the routine at end_of_frame.
;
; Only on the first frame in a room, which build_screen_objects flags at $5BB7.
; Every other frame draws only what changed; this one paints the room's colour
; over the whole screen, redraws the panel, the carried objects, the sun or
; moon and the counters, and then copies the whole buffer to the display.
no_delay:
  LD A,($5BB7)            ; not a new room: on to the next frame
  AND A
  JR Z,next_frame_or_die
  XOR A                   ; once only
  LD ($5BB7),A            ;
  LD A,($5BAD)            ; the whole attribute file in the room's colour
  CALL fill_attr
  CALL display_objects    ; the three objects being carried
  CALL colour_panel       ; the panel's colours and its artwork
  CALL colour_sun_moon    ;
  CALL display_panel      ;
  LD IX,sun_moon_scratchpad   ; the sun or moon in its frame
  CALL display_sun_moon_frame ;
  CALL display_day        ; the day, the days, the lives icon and the lives
  CALL print_days         ;
  CALL print_lives_gfx    ;
  CALL print_lives        ;
  CALL update_screen      ; the whole buffer to the display
  CALL reset_objs_wipe_flag ; nothing drawn so far needs wiping

; Next frame, or lose a life
;
; Used by the routine at no_delay.
;
; When both player records are empty -- they become empty when the death
; sparkles finish -- a life is lost; otherwise the next frame starts.
next_frame_or_die:
  XOR A                   ; the finale tone is set again each frame by the
  LD ($5BC5),A            ; sparks
  LD IX,$5C08             ; objects 0 and 1 both gone? Then a life is lost;
  LD A,(IX+$00)           ; otherwise the next frame
  OR (IX+$20)             ;
  JP Z,player_dies        ;
  JP onscreen_loop        ;

; Clear every object's wipe flag
;
; Used by the routine at no_delay.
;
; Bit 5 of byte 7 marks an object whose old image must be wiped. After the
; whole screen has just been redrawn there is nothing to wipe.
reset_objs_wipe_flag:
  LD B,$28                ; all 40 records, starting at byte 7 of object 0
  LD DE,$0020
  LD HL,$5C0F

; Clear one wipe flag
clear_wipe_flag_loop:
  RES 5,(HL)                ; bit 5 of byte 7, then the next record
  ADD HL,DE                 ;
  DJNZ clear_wipe_flag_loop ;
  RET                       ;

; Object handlers, indexed by type
;
; 188 words, one per object type. The type byte of an object record is also its
; sprite number -- sprite_tbl has one word per type in the same order -- so one
; byte chooses both what an object does and what it looks like, and a handler
; animates its object by changing its type. jump_to_upd_object jumps through
; this.
;
; Several types are drawn only in the status panel and never occupy the object
; table: the sun, the moon, the ends of their frame, the panel and border
; pieces and the lives icon. Their entries point at a bare RET or at a routine
; that only sets drawing offsets. Types 0 and 1 are not objects at all but the
; states of a free slot.
upd_sprite_jmp_tbl:
  DEFW no_update          ; Type 0: empty slot
  DEFW no_update          ; Type 1: an object that has just gone; it draws as
                          ; nothing so its old image is wiped, and the renderer
                          ; then frees the slot
  DEFW upd_2_4            ; Type 2: stone arch, the half that also nudges
                          ; Sabreman into line with the doorway
  DEFW upd_3_5            ; Type 3: stone arch, the other half
  DEFW upd_2_4            ; Type 4: tree-room arch, the half that nudges
                          ; Sabreman into the doorway
  DEFW upd_3_5            ; Type 5: tree-room arch, the other half
  DEFW upd_6_7            ; Type 6: rock, static
  DEFW upd_6_7            ; Type 7: plain block, static; at the end of the game
                          ; each one left in the room becomes type 131
  DEFW upd_8              ; Type 8: portcullis at rest, deciding when to start
                          ; moving (one moves at a time)
  DEFW upd_9              ; Type 9: portcullis moving; it kills what it lands
                          ; on and crashes when it reaches the floor
  DEFW upd_10             ; Type 10: a piece of room wall, static
  DEFW upd_11             ; Type 11: a piece of room wall, static
  DEFW upd_12_to_15       ; Type 12: a piece of room wall, static
  DEFW upd_12_to_15       ; Type 13: a piece of room wall, static
  DEFW upd_12_to_15       ; Type 14: a piece of room wall, static
  DEFW upd_12_to_15       ; Type 15: a piece of room wall, static
  DEFW upd_16_to_21_24_to_29 ; Type 16: Sabreman's legs, human, walking frame
                             ; 0, first pair of facings
  DEFW upd_16_to_21_24_to_29 ; Type 17: Sabreman's legs, human, walking frame
                             ; 1, first pair of facings
  DEFW upd_16_to_21_24_to_29 ; Type 18: Sabreman's legs, human, walking frame
                             ; 2, first pair of facings
  DEFW upd_16_to_21_24_to_29 ; Type 19: Sabreman's legs, human, walking frame
                             ; 3, first pair of facings
  DEFW upd_16_to_21_24_to_29 ; Type 20: Sabreman's legs, human, walking frame
                             ; 4, first pair of facings
  DEFW upd_16_to_21_24_to_29 ; Type 21: Sabreman's legs, human, walking frame
                             ; 5, first pair of facings
  DEFW upd_22             ; Type 22: gargoyle, static and deadly
  DEFW upd_23             ; Type 23: spikes, static and deadly
  DEFW upd_16_to_21_24_to_29 ; Type 24: Sabreman's legs, human, walking frame
                             ; 0, second pair of facings
  DEFW upd_16_to_21_24_to_29 ; Type 25: Sabreman's legs, human, walking frame
                             ; 1, second pair of facings
  DEFW upd_16_to_21_24_to_29 ; Type 26: Sabreman's legs, human, walking frame
                             ; 2, second pair of facings
  DEFW upd_16_to_21_24_to_29 ; Type 27: Sabreman's legs, human, walking frame
                             ; 3, second pair of facings
  DEFW upd_16_to_21_24_to_29 ; Type 28: Sabreman's legs, human, walking frame
                             ; 4, second pair of facings
  DEFW upd_16_to_21_24_to_29 ; Type 29: Sabreman's legs, human, walking frame
                             ; 5, second pair of facings
  DEFW upd_30_31_158_159  ; Type 30: upper body of the guard that walks round
                          ; the room, one frame per facing
  DEFW upd_30_31_158_159  ; Type 31: upper body of the guard that walks round
                          ; the room, one frame per facing
  DEFW upd_32_to_47       ; Type 32: Sabreman's upper body, human, walking
                          ; frame 0, first pair of facings
  DEFW upd_32_to_47       ; Type 33: Sabreman's upper body, human, walking
                          ; frame 1, first pair of facings
  DEFW upd_32_to_47       ; Type 34: Sabreman's upper body, human, walking
                          ; frame 2, first pair of facings
  DEFW upd_32_to_47       ; Type 35: Sabreman's upper body, human, walking
                          ; frame 3, first pair of facings
  DEFW upd_32_to_47       ; Type 36: Sabreman's upper body, human, walking
                          ; frame 4, first pair of facings
  DEFW upd_32_to_47       ; Type 37: Sabreman's upper body, human, walking
                          ; frame 5, first pair of facings
  DEFW upd_32_to_47       ; Type 38: Sabreman's upper body, human, an
                          ; occasional frame held for eight frames, first pair
                          ; of facings
  DEFW upd_32_to_47       ; Type 39: Sabreman's upper body, human, an
                          ; occasional frame held for eight frames, first pair
                          ; of facings
  DEFW upd_32_to_47       ; Type 40: Sabreman's upper body, human, walking
                          ; frame 0, second pair of facings
  DEFW upd_32_to_47       ; Type 41: Sabreman's upper body, human, walking
                          ; frame 1, second pair of facings
  DEFW upd_32_to_47       ; Type 42: Sabreman's upper body, human, walking
                          ; frame 2, second pair of facings
  DEFW upd_32_to_47       ; Type 43: Sabreman's upper body, human, walking
                          ; frame 3, second pair of facings
  DEFW upd_32_to_47       ; Type 44: Sabreman's upper body, human, walking
                          ; frame 4, second pair of facings
  DEFW upd_32_to_47       ; Type 45: Sabreman's upper body, human, walking
                          ; frame 5, second pair of facings
  DEFW upd_32_to_47       ; Type 46: Sabreman's upper body, human, an
                          ; occasional frame held for eight frames, second pair
                          ; of facings
  DEFW upd_32_to_47       ; Type 47: Sabreman's upper body, human, an
                          ; occasional frame held for eight frames, second pair
                          ; of facings
  DEFW upd_48_to_53_56_to_61 ; Type 48: Sabreman's legs, werewolf, walking
                             ; frame 0, first pair of facings
  DEFW upd_48_to_53_56_to_61 ; Type 49: Sabreman's legs, werewolf, walking
                             ; frame 1, first pair of facings
  DEFW upd_48_to_53_56_to_61 ; Type 50: Sabreman's legs, werewolf, walking
                             ; frame 2, first pair of facings
  DEFW upd_48_to_53_56_to_61 ; Type 51: Sabreman's legs, werewolf, walking
                             ; frame 3, first pair of facings
  DEFW upd_48_to_53_56_to_61 ; Type 52: Sabreman's legs, werewolf, walking
                             ; frame 4, first pair of facings
  DEFW upd_48_to_53_56_to_61 ; Type 53: Sabreman's legs, werewolf, walking
                             ; frame 5, first pair of facings
  DEFW upd_54             ; Type 54: block that slides back and forth along X
  DEFW upd_55             ; Type 55: block that slides back and forth along Y
  DEFW upd_48_to_53_56_to_61 ; Type 56: Sabreman's legs, werewolf, walking
                             ; frame 0, second pair of facings
  DEFW upd_48_to_53_56_to_61 ; Type 57: Sabreman's legs, werewolf, walking
                             ; frame 1, second pair of facings
  DEFW upd_48_to_53_56_to_61 ; Type 58: Sabreman's legs, werewolf, walking
                             ; frame 2, second pair of facings
  DEFW upd_48_to_53_56_to_61 ; Type 59: Sabreman's legs, werewolf, walking
                             ; frame 3, second pair of facings
  DEFW upd_48_to_53_56_to_61 ; Type 60: Sabreman's legs, werewolf, walking
                             ; frame 4, second pair of facings
  DEFW upd_48_to_53_56_to_61 ; Type 61: Sabreman's legs, werewolf, walking
                             ; frame 5, second pair of facings
  DEFW upd_62             ; Type 62: the block tcdev called movable: stops
                          ; every frame, falls, and blips the speaker every
                          ; frame
  DEFW upd_63             ; Type 63: spiked ball that drops once, at random,
                          ; one at a time; deadly
  DEFW upd_64_to_79       ; Type 64: werewolf upper body, walking frame 0,
                          ; first pair of facings
  DEFW upd_64_to_79       ; Type 65: werewolf upper body, walking frame 1,
                          ; first pair of facings
  DEFW upd_64_to_79       ; Type 66: werewolf upper body, walking frame 2,
                          ; first pair of facings
  DEFW upd_64_to_79       ; Type 67: werewolf upper body, walking frame 3,
                          ; first pair of facings
  DEFW upd_64_to_79       ; Type 68: werewolf upper body, walking frame 4,
                          ; first pair of facings
  DEFW upd_64_to_79       ; Type 69: werewolf upper body, walking frame 5,
                          ; first pair of facings
  DEFW upd_64_to_79       ; Type 70: werewolf upper body, an occasional frame,
                          ; first pair of facings
  DEFW upd_64_to_79       ; Type 71: werewolf upper body, an occasional frame,
                          ; first pair of facings
  DEFW upd_64_to_79       ; Type 72: werewolf upper body, walking frame 0,
                          ; second pair of facings
  DEFW upd_64_to_79       ; Type 73: werewolf upper body, walking frame 1,
                          ; second pair of facings
  DEFW upd_64_to_79       ; Type 74: werewolf upper body, walking frame 2,
                          ; second pair of facings
  DEFW upd_64_to_79       ; Type 75: werewolf upper body, walking frame 3,
                          ; second pair of facings
  DEFW upd_64_to_79       ; Type 76: werewolf upper body, walking frame 4,
                          ; second pair of facings
  DEFW upd_64_to_79       ; Type 77: werewolf upper body, walking frame 5,
                          ; second pair of facings
  DEFW upd_64_to_79       ; Type 78: werewolf upper body, an occasional frame,
                          ; second pair of facings
  DEFW upd_64_to_79       ; Type 79: werewolf upper body, an occasional frame,
                          ; second pair of facings
  DEFW upd_80_to_83       ; Type 80: ghost, wandering at random; deadly (bit 1
                          ; facing, bit 0 flapping)
  DEFW upd_80_to_83       ; Type 81: ghost, wandering at random; deadly (bit 1
                          ; facing, bit 0 flapping)
  DEFW upd_80_to_83       ; Type 82: ghost, wandering at random; deadly (bit 1
                          ; facing, bit 0 flapping)
  DEFW upd_80_to_83       ; Type 83: ghost, wandering at random; deadly (bit 1
                          ; facing, bit 0 flapping)
  DEFW upd_84             ; Type 84: table: falls, and stops after each push
  DEFW upd_85             ; Type 85: chest: falls; unlike the table, its
                          ; handler does not stop it after a push
  DEFW upd_86_87          ; Type 86: flame that runs back and forth along X;
                          ; deadly
  DEFW upd_86_87          ; Type 87: flame that runs back and forth along X;
                          ; deadly
  DEFW upd_88_to_90       ; Type 88: the sun (drawn in the panel, never in the
                          ; object table)
  DEFW upd_88_to_90       ; Type 89: the moon (drawn in the panel, never in the
                          ; object table)
  DEFW upd_88_to_90       ; Type 90: left end of the sun and moon frame (panel
                          ; only)
  DEFW upd_91             ; Type 91: block that sinks while something stands on
                          ; it
  DEFW upd_92_to_95       ; Type 92: Sabreman changing between man and werewolf
  DEFW upd_92_to_95       ; Type 93: Sabreman changing between man and werewolf
  DEFW upd_92_to_95       ; Type 94: Sabreman changing between man and werewolf
  DEFW upd_92_to_95       ; Type 95: Sabreman changing between man and werewolf
  DEFW upd_96_to_102      ; Type 96: charm 0 of the seven, lying in a room
  DEFW upd_96_to_102      ; Type 97: charm 1 of the seven, lying in a room
  DEFW upd_96_to_102      ; Type 98: charm 2 of the seven, lying in a room
  DEFW upd_96_to_102      ; Type 99: charm 3 of the seven, lying in a room
  DEFW upd_96_to_102      ; Type 100: charm 4 of the seven, lying in a room
  DEFW upd_96_to_102      ; Type 101: charm 5 of the seven, lying in a room
  DEFW upd_96_to_102      ; Type 102: charm 6 of the seven, lying in a room
  DEFW upd_103            ; Type 103: extra life, lying in a room
  DEFW upd_104_to_110     ; Type 104: charm 0 dropped in the cauldron room,
                          ; drifting to the cauldron
  DEFW upd_104_to_110     ; Type 105: charm 1 dropped in the cauldron room,
                          ; drifting to the cauldron
  DEFW upd_104_to_110     ; Type 106: charm 2 dropped in the cauldron room,
                          ; drifting to the cauldron
  DEFW upd_104_to_110     ; Type 107: charm 3 dropped in the cauldron room,
                          ; drifting to the cauldron
  DEFW upd_104_to_110     ; Type 108: charm 4 dropped in the cauldron room,
                          ; drifting to the cauldron
  DEFW upd_104_to_110     ; Type 109: charm 5 dropped in the cauldron room,
                          ; drifting to the cauldron
  DEFW upd_104_to_110     ; Type 110: charm 6 dropped in the cauldron room,
                          ; drifting to the cauldron
  DEFW upd_111            ; Type 111: extra life just collected; vanishes next
                          ; frame
  DEFW upd_112_to_118_184 ; Type 112: death sparkle, frame 0
  DEFW upd_112_to_118_184 ; Type 113: death sparkle, frame 1
  DEFW upd_112_to_118_184 ; Type 114: death sparkle, frame 2
  DEFW upd_112_to_118_184 ; Type 115: death sparkle, frame 3
  DEFW upd_112_to_118_184 ; Type 116: death sparkle, frame 4
  DEFW upd_112_to_118_184 ; Type 117: death sparkle, frame 5
  DEFW upd_112_to_118_184 ; Type 118: death sparkle, frame 6
  DEFW upd_119            ; Type 119: death sparkle, last frame; vanishes next
                          ; frame
  DEFW upd_120_to_126     ; Type 120: Sabreman materialising, frame 0
  DEFW upd_120_to_126     ; Type 121: Sabreman materialising, frame 1
  DEFW upd_120_to_126     ; Type 122: Sabreman materialising, frame 2
  DEFW upd_120_to_126     ; Type 123: Sabreman materialising, frame 3
  DEFW upd_120_to_126     ; Type 124: Sabreman materialising, frame 4
  DEFW upd_120_to_126     ; Type 125: Sabreman materialising, frame 5
  DEFW upd_120_to_126     ; Type 126: Sabreman materialising, frame 6
  DEFW upd_127            ; Type 127: Sabreman materialising, done: becomes the
                          ; type saved at +16
  DEFW upd_128_to_130     ; Type 128: tree-trunk piece of a tree room's walls,
                          ; static
  DEFW upd_128_to_130     ; Type 129: tree-trunk piece of a tree room's walls,
                          ; static
  DEFW upd_128_to_130     ; Type 130: tree-trunk piece of a tree room's walls,
                          ; static
  DEFW upd_131_to_133     ; Type 131: finale spark: rises circling the room,
                          ; then homes on Sabreman and ends the game
  DEFW upd_131_to_133     ; Type 132: finale spark: rises circling the room,
                          ; then homes on Sabreman and ends the game
  DEFW upd_131_to_133     ; Type 133: finale spark: rises circling the room,
                          ; then homes on Sabreman and ends the game
  DEFW no_update          ; Type 134: a piece of the status panel (panel only)
  DEFW no_update          ; Type 135: a piece of the status panel (panel only)
  DEFW no_update          ; Type 136: a piece of the status panel (panel only)
  DEFW no_update          ; Type 137: a corner of the screen border (panel
                          ; only)
  DEFW no_update          ; Type 138: an edge of the screen border (panel only)
  DEFW no_update          ; Type 139: an edge of the screen border (panel only)
  DEFW no_update          ; Type 140: the lives icon (panel only)
  DEFW upd_141            ; Type 141: the cauldron
  DEFW upd_142            ; Type 142: the cauldron's second sprite, with no
                          ; size of its own
  DEFW upd_143            ; Type 143: block that crumbles away when stood on
  DEFW upd_144_to_149_152_to_157 ; Type 144: legs of a guard or the wizard,
                                 ; walking frame 0, first pair of facings
  DEFW upd_144_to_149_152_to_157 ; Type 145: legs of a guard or the wizard,
                                 ; walking frame 1, first pair of facings
  DEFW upd_144_to_149_152_to_157 ; Type 146: legs of a guard or the wizard,
                                 ; walking frame 2, first pair of facings
  DEFW upd_144_to_149_152_to_157 ; Type 147: legs of a guard or the wizard,
                                 ; walking frame 3, first pair of facings
  DEFW upd_144_to_149_152_to_157 ; Type 148: legs of a guard or the wizard,
                                 ; walking frame 4, first pair of facings
  DEFW upd_144_to_149_152_to_157 ; Type 149: legs of a guard or the wizard,
                                 ; walking frame 5, first pair of facings
  DEFW upd_150_151        ; Type 150: upper body of the guard that walks back
                          ; and forth along X, one frame per facing
  DEFW upd_150_151        ; Type 151: upper body of the guard that walks back
                          ; and forth along X, one frame per facing
  DEFW upd_144_to_149_152_to_157 ; Type 152: legs of a guard or the wizard,
                                 ; walking frame 0, second pair of facings
  DEFW upd_144_to_149_152_to_157 ; Type 153: legs of a guard or the wizard,
                                 ; walking frame 1, second pair of facings
  DEFW upd_144_to_149_152_to_157 ; Type 154: legs of a guard or the wizard,
                                 ; walking frame 2, second pair of facings
  DEFW upd_144_to_149_152_to_157 ; Type 155: legs of a guard or the wizard,
                                 ; walking frame 3, second pair of facings
  DEFW upd_144_to_149_152_to_157 ; Type 156: legs of a guard or the wizard,
                                 ; walking frame 4, second pair of facings
  DEFW upd_144_to_149_152_to_157 ; Type 157: legs of a guard or the wizard,
                                 ; walking frame 5, second pair of facings
  DEFW upd_30_31_158_159  ; Type 158: the wizard's upper body, one frame per
                          ; facing
  DEFW upd_30_31_158_159  ; Type 159: the wizard's upper body, one frame per
                          ; facing
  DEFW upd_160_to_163     ; Type 160: bubbles rising from the cauldron
  DEFW upd_160_to_163     ; Type 161: bubbles rising from the cauldron
  DEFW upd_160_to_163     ; Type 162: bubbles rising from the cauldron
  DEFW upd_160_to_163     ; Type 163: bubbles rising from the cauldron
  DEFW upd_164_to_167     ; Type 164: repel spell, homing on Sabreman
  DEFW upd_164_to_167     ; Type 165: repel spell, homing on Sabreman
  DEFW upd_164_to_167     ; Type 166: repel spell, homing on Sabreman
  DEFW upd_164_to_167     ; Type 167: repel spell, homing on Sabreman
  DEFW upd_168_to_175     ; Type 168: picture of charm 0 over the cauldron, the
                          ; one it wants next
  DEFW upd_168_to_175     ; Type 169: picture of charm 1 over the cauldron, the
                          ; one it wants next
  DEFW upd_168_to_175     ; Type 170: picture of charm 2 over the cauldron, the
                          ; one it wants next
  DEFW upd_168_to_175     ; Type 171: picture of charm 3 over the cauldron, the
                          ; one it wants next
  DEFW upd_168_to_175     ; Type 172: picture of charm 4 over the cauldron, the
                          ; one it wants next
  DEFW upd_168_to_175     ; Type 173: picture of charm 5 over the cauldron, the
                          ; one it wants next
  DEFW upd_168_to_175     ; Type 174: picture of charm 6 over the cauldron, the
                          ; one it wants next
  DEFW upd_168_to_175     ; Type 175: would be the extra life over the
                          ; cauldron; the code never makes it
  DEFW upd_176_177        ; Type 176: flickering fire; deadly
  DEFW upd_176_177        ; Type 177: flickering fire; deadly
  DEFW upd_178_179        ; Type 178: ball bouncing up and down; deadly
  DEFW upd_178_179        ; Type 179: ball bouncing up and down; deadly
  DEFW upd_180_181        ; Type 180: flame that runs back and forth along Y;
                          ; deadly
  DEFW upd_180_181        ; Type 181: flame that runs back and forth along Y;
                          ; deadly
  DEFW upd_182_183        ; Type 182: ball that hops towards the werewolf and
                          ; away from the man; deadly
  DEFW upd_182_183        ; Type 183: ball that hops towards the werewolf and
                          ; away from the man; deadly
  DEFW upd_112_to_118_184 ; Type 184: crumbling block, vanishing
  DEFW upd_185_187        ; Type 185: crumbling block, last frame: zeroes the
                          ; byte its +16 points at, then vanishes
  DEFW no_update          ; Type 186: right end of the sun and moon frame
                          ; (panel only)
  DEFW upd_185_187        ; Type 187: a charm destroyed where it met another
                          ; object: zeroes its record, then vanishes
; Objects made of two records -- Sabreman, the guards and the wizard -- keep
; the second at the next record up: a guard's upper body is followed by its
; legs, and its handler writes the legs' position and motion 32 bytes on.
; Sabreman is the other way round, legs first at object 0.

; The tune played as a game starts
;
; Played in full by main once a control method has been chosen.
;
; A tune is a string of note bytes ended by $FF. The low six bits of a note are
; an index into freq_tbl, with 0 meaning a rest; the top two bits are its
; length less one, so a note lasts one to four units of about 0.155 seconds.
; The comments name each note by the step of the table's own scale it uses and
; give lengths over one unit as x2, x3 or x4.
start_game_tune:
  DEFB $59,$5C,$5B,$54,$19,$17,$14,$17 ; G#3 x2, B3 x2, A#3 x2, D#3 x2, G#3,
                                       ; F#3, D#3, F#3
  DEFB $D9,$FF            ; G#3 x4, end

; The game-over tune
;
; Played by await_restart under the game-over screen until a key is pressed. It
; fakes two voices by alternating a moving upper note with a held bass, one
; unit each. The format is described at start_game_tune.
game_over_tune:
  DEFB $2E,$17,$27,$17,$2E,$17,$27,$17 ; F5, F#3, A#4, F#3, F5, F#3, A#4, F#3
  DEFB $2C,$19,$27,$19,$2C,$19,$27,$19 ; D#5, G#3, A#4, G#3, D#5, G#3, A#4, G#3
  DEFB $2A,$1B,$27,$1B,$2A,$1B,$27,$1B ; C#5, A#3, A#4, A#3, C#5, A#3, A#4, A#3
  DEFB $2A,$1B,$27,$1B,$2A,$1B,$27,$1B ; C#5, A#3, A#4, A#3, C#5, A#3, A#4, A#3
  DEFB $FF                ; end

; The tune for completing the game
;
; Played in full by game_complete_msg under the closing message. The format is
; described at start_game_tune.
game_complete_tune:
  DEFB $1B,$1D,$1E,$1B,$1D,$1E,$20,$1D ; A#3, C4, C#4, A#3, C4, C#4, D#4, C4
  DEFB $1E,$20,$22,$1E,$1D,$1E,$20,$1D ; C#4, D#4, F4, C#4, C4, C#4, D#4, C4
  DEFB $1B,$1D,$1E,$1B,$1A,$1B,$1D,$1A ; A#3, C4, C#4, A#3, A3, A#3, C4, A3
  DEFB $9B,$FF            ; A#3 x3, end

; The menu tune
;
; Played under the control menu by do_menu_selection, once per visit to the
; menu and only until a key is pressed (see play_audio_wait_key). Like the
; game-over tune it alternates two lines, one unit per note. The format is
; described at start_game_tune.
menu_tune:
  DEFB $1B,$27,$1B,$27,$1B,$2A,$2E,$1B ; A#3, A#4, A#3, A#4, A#3, C#5, F5, A#3
  DEFB $27,$1B,$27,$1B,$2A,$1B,$2E,$16 ; A#4, A#3, A#4, A#3, C#5, A#3, F5, F3
  DEFB $25,$16,$24,$16,$22,$16,$22,$16 ; G#4, F3, G4, F3, F4, F3, F4, F3
  DEFB $25,$16,$24,$16,$22,$16,$22,$16 ; G#4, F3, G4, F3, F4, F3, F4, F3
  DEFB $22,$1B,$27,$1B,$27,$1B,$2A,$2E ; F4, A#3, A#4, A#3, A#4, A#3, C#5, F5
  DEFB $1B,$27,$1B,$27,$1B,$2A,$1B,$2E ; A#3, A#4, A#3, A#4, A#3, C#5, A#3, F5
  DEFB $16,$25,$16,$24,$16,$22,$16,$22 ; F3, G#4, F3, G4, F3, F4, F3, F4
  DEFB $16,$25,$16,$24,$16,$22,$16,$22 ; F3, G#4, F3, G4, F3, F4, F3, F4
  DEFB $16,$22,$17,$2E,$17,$2E,$17,$2E ; F3, F4, F#3, F5, F#3, F5, F#3, F5
  DEFB $17,$2E,$19,$2E,$19,$2E,$19,$2E ; F#3, F5, G#3, F5, G#3, F5, G#3, F5
  DEFB $19,$2E,$1B,$2E,$1B,$2E,$1B,$2E ; G#3, F5, A#3, F5, A#3, F5, A#3, F5
  DEFB $1B,$2E,$1B,$2E,$1B,$2E,$1B,$2E ; A#3, F5, A#3, F5, A#3, F5, A#3, F5
  DEFB $1B,$2E,$FF        ; A#3, F5, end

; Play the menu tune once per visit
;
; Used by the routine at menu_loop.
;
; The menu loop calls this every time round. $5BD1 remembers that the tune has
; been played, so it plays only the first time; start_menu clears the flag with
; the rest of the game's variables, so it plays again after the next game.
; Falls into play_audio_until_keypress.
;
; DE the tune
play_audio_wait_key:
  LD HL,$5BD1             ; played already?
  LD A,(HL)               ;
  AND A                   ;
  RET NZ                  ;
  SET 0,(HL)              ; not again until the variables are next cleared

; Play a tune until a key is pressed
;
; Used by the routines at keypress_tune_note and await_restart.
;
; Checks the keyboard before every note and stops at once if any key is down.
; Used for the menu and game-over tunes, which the player may want to skip.
;
; DE the tune
play_audio_until_keypress:
  XOR A                   ; A=0 selects every half-row at once, so any key at
  CALL read_port          ; all counts
  JR Z,keypress_tune_note ; a key: stop
  RET                     ;

; Play one note of a tune that a key can stop
;
; Used by the routine at play_audio_until_keypress.
keypress_tune_note:
  LD A,(DE)               ; $FF ends the tune
  CP $FF                  ;
  JR Z,end_audio          ;
  CALL play_note               ; play the note, then look at the keyboard again
  JR play_audio_until_keypress ;

; Play a tune
;
; Used by the routines at main and game_complete_msg.
;
; Plays the whole tune and returns. Nothing else happens while it plays: the
; sound is made by timing loops, so the tune has the machine to itself.
;
; DE the tune
play_audio:
  LD A,(DE)               ; $FF ends the tune
  CP $FF                  ;
  JR Z,end_audio          ;
  CALL play_note          ; play the note, and the next
  JR play_audio           ;

; End of a tune
;
; Used by the routines at keypress_tune_note and play_audio.
end_audio:
  RET                     ; DE is left pointing at the $FF

; Play one note
;
; Used by the routines at keypress_tune_note and play_audio.
;
; Looks up the note's three bytes in freq_tbl: two loop counts that set how
; long each half of a wave lasts, and how many waves make one unit. The length
; bits multiply the wave count by one to four. It then drives the speaker
; directly, off for one half-wave and on for the other, with the border held
; black.
;
; The wave count in the table rises with the pitch, which keeps every unit
; close to 0.155 seconds whatever the note.
;
; A the note byte
; DE the address of the note byte; on exit, the next one
play_note:
  AND $3F                 ; index 0 is a rest
  JR Z,snd_delay
  LD L,A                  ; HL = freq_tbl + 3 * index
  LD H,$00                ;
  ADD HL,HL               ;
  CALL add_HL_A           ;
  LD BC,freq_tbl          ;
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
  PUSH DE                 ; DE = the waves in one unit, to add up
  LD E,L                  ;
  LD D,H                  ;

; Multiply the waves by the length
calc_duration:
  DEC A                   ; HL = HL * A
  JR Z,restore_tune_ptr   ;
  ADD HL,DE               ;
  JR calc_duration        ;

; Restore the tune pointer
;
; Used by the routine at calc_duration.
restore_tune_ptr:
  POP DE                  ; the tune pointer back in DE

; One wave
;
; Used by the routine at note_second_half.
;
; Speaker off for one half, on for the other. Each half is the loop at
; note_first_half or note_second_half: B turns first, then 256 turns for each
; further count in C, at 13 T-states a turn.
note_wave:
  PUSH BC                 ; speaker off, border black
  XOR A                   ;
  OUT ($FE),A             ;

; First half-wave
note_first_half:
  DJNZ note_first_half    ; wait
  DEC C                   ;
  JR NZ,note_first_half   ;
  POP BC                  ; speaker on
  PUSH BC                 ;
  LD A,$10                ;
  OUT ($FE),A             ;

; Second half-wave
note_second_half:
  DJNZ note_second_half   ; wait
  DEC C                   ;
  JR NZ,note_second_half  ;
  POP BC                  ; until all the waves are done
  DEC HL                  ;
  LD A,H                  ;
  OR L                    ;
  JR NZ,note_wave         ;
  INC DE                  ; on to the next note byte
  RET                     ;

; Rest
;
; Used by the routine at play_note.
;
; Silence for one to four units, each 17163 turns of a 26 T-state loop: about
; 0.127 seconds, a little shorter than a note's unit. None of the four tunes
; uses a rest.
;
; DE the address of the note byte; on exit, the next one
snd_delay:
  LD A,(DE)               ; the length, one to four units
  INC DE                  ;
  RLCA                    ;
  RLCA                    ;
  AND $03                 ;
  INC A                   ;
  LD L,A                  ;
  LD BC,$430B             ; 17163 turns per unit

; One unit of rest
;
; Used by the routine at rest_countdown.
rest_unit:
  PUSH BC                 ; keep the count

; Rest countdown
rest_countdown:
  DEC BC                  ; 26 T-states a turn
  LD A,B                  ;
  OR C                    ;
  JR NZ,rest_countdown    ;
  POP BC                  ; the next unit
  DEC L                   ;
  JR NZ,rest_unit         ;
  RET                     ;

; Note table
;
; 61 rows of three bytes, indexed by the low six bits of a note: the first two
; are the B and C counts that time each half-wave in note_wave, and the third
; is how many waves make one unit of length. Row 0 stands for a rest and is
; never read.
;
; The rows go up a semitone at a time for five octaves. The comments give each
; row's pitch as worked out from the loop timings at 3.5MHz, and the step of an
; equal-tempered scale it stands for -- G#1 at row 1, A4 (440Hz) at row 38. The
; timing drifts across the range: the low rows come out about a fifth of a
; semitone sharp and the top rows up to half a semitone flat. Part of the
; flatness at the top is the 101 T-states each wave spends outside its two
; waits, which weigh more as the waits get shorter; why the bottom is sharp has
; not been worked out. Row 18 is the one real fault, noted below.
freq_tbl:
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

; Sound: the movable block's blip
;
; Used by the routine at upd_62.
;
; Four waves at one of eight pitches from block_blip_pitches, chosen by the
; frame counter. Called by the type 62 handler every frame, so a room with one
; of these blocks has a quiet buzz under everything else.
;
; IX the object
sound_movable_block:
  LD A,($5BA2)
  AND $07
  LD L,A
  LD H,$00
  LD BC,block_blip_pitches
  ADD HL,BC
  LD B,(HL)
  LD C,$04                ; four waves
  JP toggle_audio_hw_xC   ;

; Pitches for the movable block's blip
;
; Eight half-wave counts for toggle_audio_hw_xC, one per value of the frame
; counter's bottom three bits. The larger the count, the lower the note.
block_blip_pitches:
  DEFB $A0,$B0,$C0,$90,$A0,$E0,$80,$60

; Sound: sparkle
;
; Used by the routines at sparkle_sound_and_draw and cycle_attribute_mem.
;
; A burst of short blips whose pitches are read from the ROM at $1234, so the
; burst sounds random but is the same every time. The number of blips is the
; bottom five bits of the complemented type: fifteen for the first death
; sparkle (type 112), falling by one each frame as the sparkle runs down. Also
; used by cycle_colours_with_sound as each wanted charm goes into the cauldron.
;
; IX the object; its type sets the length
sound_sparkle:
  LD A,(IX+$00)           ; E = the number of blips
  CPL
  AND $1F
  LD E,A
  LD HL,$1234             ; pitches from the ROM

; One blip of the sparkle
sparkle_blip:
  LD A,(HL)               ; the next ROM byte is the half-wave count
  INC HL                  ;
  LD B,A                  ;
  LD C,$02                ; two waves
  CALL toggle_audio_hw_xC ;
  DEC E                   ; until E runs out
  JR NZ,sparkle_blip      ;
  RET                     ;

; Sound: materialising
;
; Used by the routine at upd_120_to_126.
;
; A rising sweep, one wave per step from a low note upwards. The number of
; steps comes from the type, so each frame of the materialising sweep is longer
; than the last: 3, 7, 11 and so on up to 27 steps.
;
; IX the object, types 120 to 126
sound_materialise:
  LD A,(IX+$00)           ; C = the number of steps
  RLCA
  RLCA
  AND $1F
  OR $03
  LD C,A

; One step of the materialising sweep
materialise_sweep:
  LD A,C                  ; half-wave count 4 * C: shorter, so higher, as C
  RLCA                    ; falls
  RLCA                    ;
  LD B,A                  ;
  CALL toggle_audio_hw    ;
  DEC C                   ; until C runs out
  JR NZ,materialise_sweep ;
  RET                     ;

; Sound: thud
;
; Used by the routines at bounce_ball_on_landing, fire_turn_if_blocked and
; ud_ball_rise_or_fall.
;
; Four low blips of three waves each, their pitches taken from the first four
; bytes of the ROM with the top two bits forced on so they are all long. Played
; when a bouncing ball lands or a moving flame turns.
sound_thud:
  LD HL,$0000             ; pitches from the start of the ROM; four blips
  LD E,$04                ;

; One blip of the thud
thud_blip:
  LD C,$03                ; three waves at the next ROM byte, made low
  LD A,(HL)               ;
  INC HL                  ;
  OR $C0                  ;
  LD B,A                  ;
  CALL toggle_audio_hw_xC ;
  DEC E                   ; until E runs out
  JR NZ,thud_blip         ;
  RET                     ;

; Sound: jump
;
; Used by the routine at handle_jump.
;
; A rising sweep of 32 single waves, played by handle_jump as Sabreman leaves
; the ground.
sound_jump:
  LD C,$20                ; 32 steps

; One step of the jump sweep
;
; Five right-rotations are three left ones, so the half-wave count is 8 * C:
; shorter, so higher, as C falls. The very first step, with C = 32, wraps round
; to a count of 1.
jump_sweep:
  LD A,C                  ; half-wave count 8 * C, one wave
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  LD B,A                  ;
  CALL toggle_audio_hw    ;
  DEC C                   ; until C runs out
  JR NZ,jump_sweep        ;
  RET                     ;

; Sound: a note pitched by height
;
; Used by the routines at upd_91, spiked_ball_drop, ud_ball_rise_or_fall and
; move_player_apply.
;
; Six waves whose pitch rises with the object's height. Used for things that
; fall or rise: a sinking block, a dropping spiked ball, a bouncing ball, and
; Sabreman falling.
;
; IX the object
sound_pitch_from_z:
  LD A,(IX+$03)           ; A = Z

; Sound: a note pitched by A
;
; Used by the routines at end_of_frame, sound_pitch_from_x, sound_pitch_from_y
; and sound_pitch_from_xyz.
;
; Six waves with a half-wave count of four times the complement of A (rotated,
; so the top two bits wrap round). end_of_frame calls this directly during the
; finale with the last spark's height.
;
; A the value to turn into a pitch; the larger, the higher
sound_pitch_from_a:
  CPL                     ; B = the half-wave count
  RLCA                    ;
  RLCA                    ;
  LD B,A                  ;
  LD C,$06                ; six waves
  JP toggle_audio_hw_xC   ;

; Sound: a note pitched by X
;
; Used by the routines at upd_54 and fire_ew_move.
;
; For the things that move along X: the sliding block and the flame.
;
; IX the object
sound_pitch_from_x:
  LD A,(IX+$01)           ; A = X
  JR sound_pitch_from_a

; Sound: a note pitched by Y
;
; Used by the routines at upd_55 and fire_ns_move.
;
; For the things that move along Y: the sliding block and the flame.
;
; IX the object
sound_pitch_from_y:
  LD A,(IX+$02)           ; A = Y
  JR sound_pitch_from_a

; Sound: a note pitched by position
;
; Used by the routines at click_wipe_and_draw, ghost_new_direction and
; move_portcullis_up.
;
; The pitch follows the sum of X, Y and Z, so it changes whichever way the
; object moves. Used for charms, tables and chests on the move, ghosts turning,
; a portcullis rising, the repel spell, and anything that vanishes through the
; type 111 handler.
;
; IX the object
sound_pitch_from_xyz:
  LD A,(IX+$01)           ; A = X + Y + Z
  ADD A,(IX+$02)          ;
  ADD A,(IX+$03)          ;
  JR sound_pitch_from_a   ;

; Sound: changing between man and werewolf
;
; Used by the routine at transform_step.
;
; A warble of 16 to 40 single waves, the number set by which of the four
; transformation frames is showing, each at a pitch scrambled from the step
; count with an XOR.
;
; IX the object, types 92 to 95
sound_transform:
  LD A,(IX+$00)           ; C = 16, 24, 32 or 40 steps
  RLCA                    ;
  RLCA                    ;
  RLCA                    ;
  AND $18                 ;
  ADD A,$10               ;
  LD C,A                  ;

; One step of the warble
transform_warble:
  LD A,C                  ; half-wave count (C XOR $55) + C, one wave
  XOR $55                 ;
  ADD A,C                 ;
  LD B,A                  ;
  CALL toggle_audio_hw    ;
  DEC C                   ; until C runs out
  JR NZ,transform_warble  ;
  RET                     ;

; Sound: the portcullis lands
;
; Used by the routine at upd_9.
;
; Sixteen blips of two waves each, their pitches read from somewhere in the
; first 8K -- the ROM -- chosen by the random byte and the frame counter, so
; each crash sounds different.
;
; IX the portcullis
sound_portcullis_crash:
  LD A,($5BA5)            ; HL = a random address below $2000; 16 blips
  LD L,A                  ;
  LD A,($5BA2)            ;
  AND $1F                 ;
  LD H,A                  ;
  LD E,$10                ;

; One blip of the crash
crash_blip:
  LD A,(HL)               ; two waves at the next byte, less its top bit
  INC HL                  ;
  AND $7F                 ;
  LD B,A                  ;
  LD C,$02                ;
  CALL toggle_audio_hw_xC ;
  DEC E                   ; until E runs out
  JR NZ,crash_blip        ;
  RET                     ;

; Sound: a plain beep of 16 waves
;
; Used by the routines at check_for_start_game, start_pickup_drop and upd_103.
;
; Used when an object is picked up or dropped, when an extra life is collected,
; and when the control menu's choice changes.
toggle_audio_hw_x16:
  LD BC,$8010             ; 16 waves at half-wave count 128
  JR toggle_audio_hw_xC   ;

; Sound: a plain beep of 24 waves
;
; Used by the routines at debounce_space_press and debounce_space_release.
;
; The pause beep, as handle_pause pauses and again as it lets go.
toggle_audio_hw_x24:
  LD BC,$5018             ; 24 waves at half-wave count 80
  JR toggle_audio_hw_xC   ;

; Sound: a guard's or the wizard's footstep
;
; Used by the routine at upd_144_to_149_152_to_157.
;
; Plays on every other frame of the walk cycle. It alternates between a fixed
; pitch and one set by the walker's height, by bit 1 of the complemented frame
; counter, which gives the tick-tock of two feet; the number of waves comes
; from X and Y. Sabreman's steps, sound_walk_step, use the frame counter
; uncomplemented, so his two pitches alternate the other way round.
;
; IX the legs object
audio_guard_wizard:
  LD A,(IX+$00)           ; only on even walking frames
  AND $01
  RET NZ
  LD B,$80
  LD A,($5BA2)
  CPL
  JR footstep_pitch

; Sound: Sabreman's footstep while walking
;
; Used by the routine at walk_step_sound.
;
; Plays on every other frame of the walk cycle, then as sound_footstep.
;
; IX Sabreman's legs
sound_walk_step:
  LD A,(IX+$00)           ; only on even walking frames
  AND $01                 ;
  RET NZ

; Sound: Sabreman's footstep
;
; Used by the routine at rotational_turn.
;
; Called directly when he turns on the spot, and through sound_walk_step when
; he walks.
;
; IX Sabreman's legs
sound_footstep:
  LD B,$60                ; a fixed pitch, and the frame counter
  LD A,($5BA2)            ;

; Footstep pitch
;
; Used by the routine at audio_guard_wizard.
;
; On alternate pairs of frames the pitch is replaced by one from the walker's
; height.
;
; A the frame counter, or its complement
; B the fixed half-wave count
footstep_pitch:
  BIT 1,A                 ; keep the fixed pitch
  JR Z,footstep_length    ;
  LD A,(IX+$03)           ; or take half the complement of Z
  CPL
  SRL A
  LD B,A

; Footstep length
;
; Used by the routine at footstep_pitch.
;
; The number of waves is (X/2 + (256-Y)/2)/16, which over the floor of a room
; comes to between 3 and 12: longer as X grows and shorter as Y grows. Falls
; into toggle_audio_hw_xC.
footstep_length:
  LD A,(IX+$01)           ; C = the number of waves
  SRL A
  LD C,A
  LD A,(IX+$02)
  NEG
  SRL A
  ADD A,C
  RRCA
  RRCA
  RRCA
  RRCA
  AND $0F
  LD C,A

; Sound: C waves at one pitch
;
; Used by the routines at sound_movable_block, sparkle_blip, thud_blip,
; sound_pitch_from_a, crash_blip, toggle_audio_hw_x16 and toggle_audio_hw_x24.
;
; The common tail of most of the effects. toggle_audio_hw leaves B as it found
; it, so every wave has the same pitch.
;
; B the half-wave count
; C the number of waves
toggle_audio_hw_xC:
  CALL toggle_audio_hw
  DEC C
  JR NZ,toggle_audio_hw_xC
  RET

; Sound: one wave
;
; Used by the routines at materialise_sweep, jump_sweep, transform_warble and
; toggle_audio_hw_xC.
;
; Speaker bit on for B turns of a 13 T-state loop, then off for as long, with
; the border black throughout. A count of 128 comes out at about 1kHz.
;
; B the half-wave count, kept
toggle_audio_hw:
  LD A,$10                ; speaker on; keep B
  OUT ($FE),A
  LD A,B

; First half of the wave
speaker_on_wait:
  DJNZ speaker_on_wait    ; wait, then speaker off
  LD B,A
  XOR A
  OUT ($FE),A
  LD A,B

; Second half of the wave
speaker_off_wait:
  DJNZ speaker_off_wait   ; wait, and give B back
  LD B,A                  ;
  RET                     ;

; Does this object overlap any other?
;
; Used by the routine at handle_pickup_drop.
;
; Tests IX against all 40 records with the per-axis tests at
; do_objs_intersect_on_x, do_objs_intersect_on_y and do_objs_intersect_on_z,
; with no offset on any axis. Empty slots are skipped, and so is any object
; with bit 1 of byte 7 set -- which is how IX avoids finding itself: it sets
; its own bit 1 for the duration. Only handle_pickup_drop uses it, to see
; whether there is room above Sabreman's head for a dropped object.
;
; IX the object
; F on exit: carry set if another object's box overlaps IX's where it stands
do_any_objs_intersect:
  PUSH BC                 ; save the registers; IY walks all 40 records
  PUSH DE                 ;
  PUSH HL                 ;
  PUSH IY                 ;
  LD IY,$5C08             ;
  LD B,$28                ;
  LD C,$00                ; no offset on X, Y or Z; and IX out of its own way
  LD L,C
  LD H,C
  SET 1,(IX+$07)
; The exit clears IX's bit 1 unconditionally, so an object that had the bit set
; before the call loses it. The only caller passes Sabreman's legs, which do
; not normally carry it.

; Test one object for overlap
;
; Used by the routine at overlap_next_obj.
overlap_test_obj:
  CALL is_object_not_ignored ; an empty slot, or one that takes no part in
                             ; collisions
  JR Z,overlap_next_obj
  CALL do_objs_intersect_on_x ; overlapping on X, Y and Z?
  JR NC,overlap_next_obj      ;
  CALL do_objs_intersect_on_y ;
  JR NC,overlap_next_obj      ;
  CALL do_objs_intersect_on_z ;
  JR NC,overlap_next_obj      ;

; Overlap found, or none
;
; Used by the routine at overlap_next_obj.
overlap_done:
  POP IY                  ; restore, and let IX take part in collisions again;
  POP HL                  ; carry says which
  POP DE                  ;
  POP BC                  ;
  RES 1,(IX+$07)          ;
  RET                     ;

; Next object
;
; Used by the routine at overlap_test_obj.
overlap_next_obj:
  LD DE,$0020             ; the next record, until all 40 are done
  ADD IY,DE
  DJNZ overlap_test_obj
  AND A                   ; none overlap: carry clear
  JR overlap_done         ;

; Does this object take part in collisions?
;
; Used by the routines at overlap_test_obj, dX_obj_loop, dY_obj_loop and
; dZ_obj_loop.
;
; Bit 1 of byte 7 takes an object out of collision tests. Objects set it on
; themselves while they are being moved, and some keep it: Sabreman's upper
; half, the legs of the guards and the wizard, the cauldron bubbles and the
; finale sparks.
;
; IY the object
; F on exit: Z if the slot is empty or bit 1 of byte 7 is set, NZ for an object
;   things can collide with
is_object_not_ignored:
  LD A,(IY+$00)           ; empty?
  AND A
  RET Z
  LD A,(IY+$07)           ; or bit 1 of byte 7 set?
  CPL
  AND $02
  RET

; Rotate the list of objects the cauldron wants
;
; Used by the routine at main.
;
; The cauldron asks for fourteen objects in the order of the list at
; objects_required. This rotates that list left by 4 to 7 places, the number
; chosen by bits 0 and 1 of the game seed. The list itself never changes order,
; so every game asks for the same cycle of objects starting at a different
; point -- and since the list is in the game's code rather than its variables,
; the rotations add up from one game to the next.
shuffle_objects_required:
  LD A,($5BA0)            ; C = 4 to 7 rotations
  AND $03                 ;
  OR $04                  ;
  LD C,A

; Rotate once
;
; Used by the routine at rotate_wanted_entry.
rotate_wanted_once:
  LD B,$0D                ; 13 moves; E = the first entry
  LD IY,objects_required  ;
  LD E,(IY+$00)           ;

; Move one entry down
rotate_wanted_entry:
  LD A,(IY+$01)            ; each entry down one place
  LD (IY+$00),A            ;
  INC IY                   ;
  DJNZ rotate_wanted_entry ;
  LD (IY+$00),E           ; the first entry goes on the end
  DEC C                    ; until done
  JR NZ,rotate_wanted_once ;
  RET                      ;

; Handler: the finale sparks (types 131 to 133)
;
; When the fourteenth object goes into the cauldron, prepare_final_animation
; clears away objects 3 to 13 and turns every plain block from object 14 on
; into one of these. Below height $A4 a spark rises two a frame while moving
; four a frame round the middle of the room: which quarter of the room it is in
; picks a direction from dX_dY_tbl, and each direction carries it into the next
; quarter round. Once it is high enough it flies at Sabreman instead, and when
; it comes within 6 of him on both X and Y the game ends -- through game_over,
; which sees the finale flag at $5BC3 and shows the closing message.
;
; Every frame each spark takes a random one of the three frames, and leaves its
; height at $5BC5 for end_of_frame to turn into a tone.
;
; IX the spark
upd_131_to_133:
  CALL adj_m4_m12         ; drawing offsets
  LD A,(IX+$03)           ; high enough: go for Sabreman
  CP $A4
  JR NC,spark_near_player
  LD (IX+$0B),$03         ; dZ = 3; gravity takes one, so it rises two a frame
  LD A,(IX+$01)           ; L = which quarter: bit 1 from X, bit 0 from Y
  RLCA
  AND $01
  LD L,A
  LD A,(IX+$02)
  AND $80
  OR L
  RLCA
  AND $03
  LD L,A
  LD BC,dX_dY_tbl         ; go and set that quarter's direction
  JP jump_to_tbl_entry    ;

; Finale spark directions, by quarter of the room
;
; Indexed by bit 7 of X times two plus bit 7 of Y. Each routine loads H with dY
; and L with dX, so the names read dY first: p4_m4 is dY +4, dX -4.
dX_dY_tbl:
  DEFW p4_m4              ; X low, Y low: dX -4, dY +4
  DEFW p4_p4              ; X low, Y high: dX +4, dY +4
  DEFW m4_m4              ; X high, Y low: dX -4, dY -4
  DEFW m4_p4              ; X high, Y high: dX +4, dY -4

; Spark direction: dX -4, dY +4
p4_m4:
  LD HL,$04FC             ; H = dY, L = dX

; Store the spark's direction and pick a frame
;
; Used by the routines at p4_p4, m4_m4 and m4_p4.
;
; H dY
; L dX
save_dX_dY:
  LD (IX+$09),L           ; the new dX and dY
  LD (IX+$0A),H
  LD A,($5BA5)            ; a random frame, 1 to 3
  AND $03
  JR NZ,set_spark_frame
  INC A

; Set the spark's frame
;
; Used by the routine at save_dX_dY.
set_spark_frame:
  ADD A,$82               ; type 131, 132 or 133
  LD (IX+$00),A

; Leave the spark's height for the finale tone
;
; Used by the routine at spark_home_in.
spark_tone_and_move:
  LD A,(IX+$03)           ; read by end_of_frame
  LD ($5BC5),A            ;

; Move under gravity and flag for redrawing
;
; Used by the routines at shuttle_block_move and upd_62.
;
; Takes one off the object's dZ, moves it by dX, dY and dZ as far as the
; collision code allows, and marks it to be wiped and drawn. Also used by the
; sliding blocks and the movable block.
;
; IX the object
dec_dZ_wipe_and_draw:
  CALL dec_dZ_and_update_XYZ ; gravity, collisions and the move
  JP set_wipe_and_draw_flags ; wipe and redraw

; Spark direction: dX +4, dY +4
p4_p4:
  LD HL,$0404             ; H = dY, L = dX
  JR save_dX_dY           ;

; Spark direction: dX -4, dY -4
m4_m4:
  LD HL,$FCFC             ; H = dY, L = dX
  JR save_dX_dY           ;

; Spark direction: dX +4, dY -4
m4_p4:
  LD HL,$FC04             ; H = dY, L = dX
  JR save_dX_dY           ;

; Is the spark near Sabreman?
;
; Used by the routine at upd_131_to_133.
;
; Distance on X first; $5C09 and $5C0A are X and Y of object 0, Sabreman's
; legs.
spark_near_player:
  LD A,($5C09)            ; A = |Sabreman's X - the spark's X|
  SUB (IX+$01)
  JP P,spark_check_y
  NEG

; Near on X; and on Y?
;
; Used by the routine at spark_near_player.
spark_check_y:
  CP $06                  ; not within 6 on X: keep flying
  JR NC,spark_home_in
  LD A,($5C0A)            ; A = |Sabreman's Y - the spark's Y|
  SUB (IX+$02)
  JP P,spark_touch
  NEG

; Near on X; near on Y?
;
; Used by the routine at spark_check_y.
spark_touch:
  CP $06                  ; within 6 on both: the game is complete
  JP C,game_over

; Fly at Sabreman
;
; Used by the routine at spark_check_y.
;
; Level flight at four a frame towards him on both axes. Bit 1 of byte 7 takes
; the spark out of collisions, so it flies through whatever is in the way. It
; also sets bit 7 of byte 13, the flag that elsewhere makes an object kill
; whatever it lands on; with collisions off it seems to do nothing here.
spark_home_in:
  SET 7,(IX+$0D)          ; the killing flag, and out of collisions
  SET 1,(IX+$07)
  LD (IX+$0B),$01         ; dZ = 1: after gravity, level
  LD BC,$0404             ; dX and dY of 4 towards Sabreman
  CALL move_towards_plyr
  JR spark_tone_and_move  ; tone, move and draw

; Read one or more keyboard half-rows
;
; Used by the routines at play_audio_until_keypress, await_restart,
; wait_key_poll, menu_loop, check_for_start_game, interface_ii,
; reverse_if2_bits, cursor, cursor_second_row, keyboard, keyboard_forward,
; keyboard_jump, keyboard_pickup, finished_input, handle_pause,
; debounce_space_press, wait_for_space and debounce_space_release.
;
; The IN does the selecting on its own: IN A,($FE) puts A on the top half of
; the address bus, so each 0 bit in A selects one half-row, and A=0 reads all
; eight at once -- which is how the "press any key" waits call it. Callers also
; pass $7E, $99, $BD and so on to read several rows in one go. The CPL turns
; the Spectrum's active-low keys the right way up, and the AND keeps the five
; that mean anything.
;
; The OUT before it is not needed for the read. It writes A to port A*256+$FD,
; which nothing on a 48K Spectrum answers because address line 0 is high. A
; 128K machine's paging port would decode it whenever A has bit 7 clear, and 0,
; $7E and $7F are all among the values callers pass.
;
; A the half-rows to select, a 0 bit for each
; A on exit, the five key bits, 1 for pressed
read_port:
  OUT ($FD),A             ; not what selects the row: see above
  IN A,($FE)              ; reads port A*256+$FE
  CPL                     ; set bits now mean pressed keys; keep the five
  AND $1F                 ;
  RET

; Bouncing ball (types 182 and 183)
;
; The ball_bounce block (ball_bounce). Falls under gravity, and every time it
; lands it jumps again and picks a new heading: two units a frame along X or
; along Y, chosen at random, pointing towards the player if the player is
; Sabrewulf and away if he is Sabreman. It keeps that heading all the way
; through the air, however often a wall stops it. The frame flips between the
; two types every frame, and it kills on contact.
;
; Which way "towards" means is decided by patching two JR instructions rather
; than by testing: see bounce_ball_set_sense.
upd_182_183:
  CALL upd_12_to_15       ; pixel offsets for the ball sprite
  LD L,(IX+$09)           ; keep dX and dY
  LD H,(IX+$0A)
  PUSH HL
  LD A,(IX+$0B)           ; remember dZ from before the move, for the bounce
                          ; sound
  LD ($5BC2),A
  CALL dec_dZ_and_update_XYZ ; gravity, then move, clipped against the room and
                             ; other objects
  POP HL                  ; put dX and dY back: the clipping may have cut them,
  LD (IX+$09),L           ; but the ball keeps its heading until it bounces
  LD (IX+$0A),H           ;
  LD A,($5C08)            ; object 0's type is the player's legs: 16 to 29 for
  SUB $10                 ; Sabreman gives $38 (JR C), anything else $30 (JR
                          ; NC)
  CP $20
  LD A,$30
  JR NC,bounce_ball_set_sense
  ADD A,$08

; Bouncing ball: set the chase direction and the bounce height
;
; Used by the routine at upd_182_183.
;
; Writes the opcode chosen in upd_182_183 into the two conditional jumps at
; bounce_ball_y_sense and bounce_ball_x_sense. With JR C a ball flees the
; player; with JR NC it chases him.
;
; Then works out how hard it will bounce: a dZ of 4 in an even-numbered room,
; and 4 plus a random 0 to 3 in an odd-numbered one.
;
; A $30 or $38, the JR opcode
bounce_ball_set_sense:
  LD (bounce_ball_y_sense),A ; patch both jumps
  LD (bounce_ball_x_sense),A
  LD A,($5C10)                ; even room: bounce with dZ 4
  AND $01                     ;
  LD A,$04                    ;
  JR Z,bounce_ball_on_landing ;
  LD B,A                  ; odd room: 4 to 7
  LD A,($5BA5)            ;
  AND $03                 ;
  ADD A,B                 ;

; Bouncing ball: on landing, bounce
;
; Used by the routine at bounce_ball_set_sense.
;
; Nothing changes while the ball is in the air. When the last move left it
; standing on something, dZ is set to the bounce value and a new heading is
; chosen in bounce_ball_pick_axis.
;
; A the bounce dZ
bounce_ball_on_landing:
  BIT 2,(IX+$0C)          ; not on the ground: keep flying
  JR Z,bounce_ball_animate
  LD (IX+$0B),A           ; landed: jump
  LD A,($5BC2)            ; thud only if it was falling, not if it was already
                          ; resting
  AND A
  JP P,bounce_ball_pick_axis
  CALL sound_thud

; Bouncing ball: choose X or Y and compare with the player
;
; Used by the routine at bounce_ball_on_landing.
;
; Bit 0 of the refresh register is the coin toss. Heads, the new heading is
; along Y and is worked out here and at bounce_ball_y_sense; tails, along X at
; bounce_ball_x_axis.
bounce_ball_pick_axis:
  LD A,R                  ; R register bit 0: 0 goes along X
  AND $01                 ;
  JR Z,bounce_ball_x_axis ;
  LD A,($5C0A)            ; carry if the player's Y is less than the ball's
  CP (IX+$02)
  LD A,$02

; Bouncing ball: the patched jump for Y
;
; The JR here is rewritten every frame by bounce_ball_set_sense: JR NC to head
; towards the player, JR C to head away. Falling through negates the step.
bounce_ball_y_sense:
  JR NC,bounce_ball_set_dy ; JR NC or JR C, patched
  NEG                     ; step -2

; Bouncing ball: head along Y
;
; Used by the routine at bounce_ball_y_sense.
;
; A the step, +2 or -2
bounce_ball_set_dy:
  LD (IX+$0A),A           ; dY = A, dX = 0
  LD (IX+$09),$00

; Bouncing ball: animate and draw
;
; Used by the routines at bounce_ball_on_landing and bounce_ball_set_dx.
;
; Flips between types 182 and 183 and hands over to
; set_deadly_wipe_and_draw_flags, which makes the ball deadly and marks it to
; be wiped and redrawn.
bounce_ball_animate:
  CALL toggle_next_prev_sprite ; flip bit 0 of the type
  JP set_deadly_wipe_and_draw_flags ; deadly, wipe and draw

; Bouncing ball: compare X with the player
;
; Used by the routine at bounce_ball_pick_axis.
bounce_ball_x_axis:
  LD A,($5C09)            ; carry if the player's X is less than the ball's; A
                          ; = 2
  CP (IX+$01)
  LD A,$02

; Bouncing ball: the patched jump for X
;
; The same patched jump as bounce_ball_y_sense, for the X axis.
bounce_ball_x_sense:
  JR NC,bounce_ball_set_dx ; JR NC or JR C, patched
  NEG                     ; step -2

; Bouncing ball: head along X
;
; Used by the routine at bounce_ball_x_sense.
;
; A the step, +2 or -2
bounce_ball_set_dx:
  LD (IX+$09),A           ; dX = A, dY = 0
  LD (IX+$0A),$00
  JR bounce_ball_animate  ; animate and draw

; Dropping block (type 91)
;
; The dropping_block (dropping_block). It sinks while something stands on it,
; one unit a frame, and stops when it lands on what is underneath. Bit 3 of +13
; is set by the collision code (adj_for_out_of_bounds) on whatever an object
; lands on, so it is the "someone is standing on me" flag; this handler clears
; it every frame, so the block stops sinking the moment the weight steps off.
upd_91:
  CALL upd_6_7            ; pixel offsets
  BIT 3,(IX+$0D)          ; nothing on it: nothing to do, not even a redraw
  RET Z
  RES 3,(IX+$0D)          ; clear the flag; a rider will set it again next
                          ; frame
  LD (IX+$0B),$00         ; dZ = 0, which the DEC in the move makes -1
  CALL dec_dZ_and_update_XYZ
  BIT 2,(IX+$0C)          ; grinding sound while it is still moving down
  JR NZ,drop_block_draw
  CALL sound_pitch_from_z

; Dropping block: draw
;
; Used by the routine at upd_91.
drop_block_draw:
  JP set_wipe_and_draw_flags ; wipe and draw

; Collapsing block (type 143)
;
; The collapsing_block (collapsing_block). It sits still until something lands
; on it, then crumbles: it becomes type 184, which upd_112_to_118_184 steps on
; to 185 with a sound, and type 185's handler (upd_185_187) makes it vanish the
; frame after. Rebuilding the room brings it back.
upd_143:
  CALL upd_6_7            ; pixel offsets
  BIT 3,(IX+$0D)          ; wait for something to stand on it
  RET Z
  LD (IX+$00),$B8         ; crumble
  JP upd_112_to_118_184

; Shuttling block, north-south (type 55)
;
; The block_ns block (block_ns). Sets up shuttle_block to work on Y and dY.
upd_55:
  CALL sound_pitch_from_y ; sound pitched by Y
  LD HL,$020A             ; H = 2 (Y), L = 10 (dY)
  JR shuttle_block

; Shuttling block, east-west (type 54)
;
; The block_ew block (block_ew). Sets up shuttle_block to work on X and dX.
upd_54:
  CALL sound_pitch_from_x ; sound pitched by X
  LD HL,$0109             ; H = 1 (X), L = 9 (dX)

; Shuttling block: the common part
;
; Used by the routine at upd_55.
;
; One routine serves both axes by patching the displacement bytes of two IX
; instructions: the read of the position at shuttle_block_step and the write of
; the step at shuttle_block_move.
;
; The block follows the frame counter. Folding the counter at bit 4 gives a
; triangle wave, 0 up to 15 and back down over 32 frames, and the block steps
; one unit a frame towards that position within a 16-unit span. Blocks in
; odd-numbered object records add 16 to the counter first, which puts them half
; a cycle out of step with their even-numbered neighbours: one is at the far
; end while the next is at the near one.
;
; H the offset of the axis to follow, 1 (X) or 2 (Y)
; L the offset of the delta to set, 9 (dX) or 10 (dY)
shuttle_block:
  LD A,H                  ; patch the two displacements
  LD ($B6E0),A            ;
  LD A,L                  ;
  LD ($B6F1),A            ;
  CALL upd_6_7            ; pixel offsets
  PUSH IX                 ; C = 16 if IX is an odd-numbered record, else 0
  POP BC                  ;
  LD A,C                  ;
  RRCA                    ;
  AND $10                 ;
  LD C,A                  ;
  LD A,($5BA2)              ; frame counter plus C, folded when bit 4 is set
  ADD A,C                   ;
  BIT 4,A                   ;
  JR Z,shuttle_block_target ;
  CPL                       ;

; Shuttling block: the target
;
; Used by the routine at shuttle_block.
shuttle_block_target:
  AND $0F                 ; C = where in its span the block should be, 0 to 15
  LD C,A

; Shuttling block: step towards the target
;
; The first instruction's displacement is patched by shuttle_block to read X or
; Y. Adding 8 is because a block built on a cell's centre line sits at 8 past a
; multiple of 16, so this is its distance along its span.
shuttle_block_step:
  LD A,(IX+$01)           ; the position: IX+1 or IX+2, patched
  ADD A,$08               ; where in its span it is now; is that the target?
  AND $0F                 ;
  CP C                    ;
  JP Z,set_wipe_and_draw_flags ; yes: stand still this frame, but redraw
  LD A,$01                ; no: +1 if short of it, -1 if past it
  JR C,shuttle_block_move ;
  NEG                     ;

; Shuttling block: move
;
; Used by the routine at shuttle_block_step.
;
; The first instruction's displacement is patched by shuttle_block to set dX or
; dY. dZ is set to 1 so that the DEC in the move leaves it at 0: the block
; floats rather than falling.
;
; A the step, +1 or -1
shuttle_block_move:
  LD (IX+$09),A           ; dX or dY, patched
  LD (IX+$0B),$01         ; no gravity
  JP dec_dZ_wipe_and_draw ; move, wipe and draw

; Walking legs (types 144 to 149 and 152 to 157)
;
; The lower half of a guard or of the wizard: the second record in the guard_ew
; (guard_ew), guard_square (guard_square) and wizard (wizard) layouts. It is 6
; pixels lower on the screen than the body it goes with (compare adj_m6_m12
; with adj_p3_m12), has no height and is not solid, and uses the same sprites
; as the player's own legs, types 16 to 29.
;
; The legs never move themselves: the body's handler, which runs just before,
; copies its X, Y and deltas into this record (at IX+33 onwards from its point
; of view). This handler only animates. Standing still, it does nothing at all.
; Walking, it plays a footstep, chooses one of two views -- types 144-149 or
; 152-157, bit 3 of the type -- and whether to mirror it, from the direction of
; travel, and steps the six-frame walk cycle (animate_human_legs).
;
; The direction test compares dX and dY as unsigned bytes, which works because
; only one of them is ever non-zero and a negative step is a large number. +X
; and -Y use the second view, -X and +Y the first; +Y and -Y are drawn
; mirrored.
upd_144_to_149_152_to_157:
  CALL adj_m6_m12         ; pixel offsets
  LD A,(IX+$09)           ; not moving: no step, no redraw
  OR (IX+$0A)
  RET Z
  CALL audio_guard_wizard ; footstep
  LD A,(IX+$09)           ; moving along Y?
  CP (IX+$0A)
  JR C,legs_moving_in_y
  BIT 7,A                 ; moving -X?
  JR NZ,legs_face_minus_x ;
  SET 3,(IX+$00)          ; +X: second view

; Walking legs: unmirrored
;
; Used by the routine at legs_face_minus_x.
legs_unmirrored:
  RES 6,(IX+$07)          ; +X or -X: not mirrored

; Walking legs: animate and draw
;
; Used by the routine at legs_mirrored.
legs_animate_and_draw:
  CALL animate_human_legs ; next frame of the walk cycle
  JP set_wipe_and_draw_flags ; wipe and draw

; Walking legs: facing -X
;
; Used by the routine at upd_144_to_149_152_to_157.
legs_face_minus_x:
  RES 3,(IX+$00)          ; first view, not mirrored
  JR legs_unmirrored      ;

; Walking legs: moving along Y
;
; Used by the routine at upd_144_to_149_152_to_157.
legs_moving_in_y:
  BIT 7,(IX+$0A)          ; moving +Y?
  JR Z,legs_face_plus_y
  SET 3,(IX+$00)          ; -Y: second view

; Walking legs: mirrored
;
; Used by the routine at legs_face_plus_y.
legs_mirrored:
  SET 6,(IX+$07)          ; +Y or -Y: mirrored
  JR legs_animate_and_draw ; animate and draw

; Walking legs: facing +Y
;
; Used by the routine at legs_moving_in_y.
legs_face_plus_y:
  RES 3,(IX+$00)          ; first view, mirrored
  JR legs_mirrored        ;

; Guard walking east-west (types 150 and 151)
;
; The body of a guard_ew guard (guard_ew). It walks two units a frame along X,
; turning round whenever the move leaves it blocked. Bit 0 of +13 is the
; direction, 1 for +X; the layout starts it at 0, heading -X. Its legs are the
; next record, and get its dX and X each frame; it never moves along Y, so
; their dY stays 0. Deadly to touch.
upd_150_151:
  CALL adj_p7_m12         ; pixel offsets: 13 pixels above the legs
  BIT 0,(IX+$0D)          ; dX = +2 or -2 from bit 0 of +13
  LD A,$02
  JR NZ,guard_ew_move
  NEG

; Guard east-west: move and turn
;
; Used by the routine at upd_150_151.
;
; A dX
guard_ew_move:
  LD (IX+$09),A           ; set the guard's dX and its legs'
  LD (IX+$29),A
  CALL set_guard_wizard_sprite ; pick the frame and mirroring from the
                               ; direction
  CALL dec_dZ_and_update_XYZ ; gravity and move
  BIT 0,(IX+$0C)          ; blocked along X: turn round
  JR Z,guard_ew_legs
  LD A,(IX+$0D)
  XOR $01
  LD (IX+$0D),A

; Guard east-west: take the legs along
;
; Used by the routine at guard_ew_move.
guard_ew_legs:
  LD A,(IX+$01)           ; the legs' X = the guard's X
  LD (IX+$21),A
  JP set_deadly_wipe_and_draw_flags ; deadly, wipe and draw

; Choose a guard's or the wizard's frame from its direction
;
; Used by the routines at guard_ew_move and upd_30_31_158_159.
;
; The body's version of the facing logic in upd_144_to_149_152_to_157. Bit 0 of
; the type chooses one of the two drawings -- 30 or 31, 150 or 151, 158 or 159
; -- and bit 6 of +7 mirrors it. +X and -Y set bit 0, -X and +Y clear it; +Y
; and -Y are mirrored. With both deltas 0 nothing changes, so a guard that
; stops keeps facing the way it was.
;
; The dX and dY comparison is unsigned, as in upd_144_to_149_152_to_157.
set_guard_wizard_sprite:
  LD A,(IX+$09)           ; not moving: leave it
  OR (IX+$0A)
  RET Z
  LD A,(IX+$09)           ; moving along Y?
  CP (IX+$0A)
  JR C,guard_moving_in_y
  BIT 7,A                  ; moving -X?
  JR NZ,guard_face_minus_x ;
  SET 0,(IX+$00)          ; +X: bit 0 set

; Guard or wizard: unmirrored
;
; Used by the routine at guard_face_minus_x.
guard_unmirrored:
  RES 6,(IX+$07)          ; not mirrored
  RET

; Guard or wizard: facing -X
;
; Used by the routine at set_guard_wizard_sprite.
guard_face_minus_x:
  RES 0,(IX+$00)          ; bit 0 clear, not mirrored
  JR guard_unmirrored     ;

; Guard or wizard: moving along Y
;
; Used by the routine at set_guard_wizard_sprite.
guard_moving_in_y:
  BIT 7,(IX+$0A)          ; moving +Y?
  JR Z,guard_face_plus_y
  SET 0,(IX+$00)          ; -Y: bit 0 set

; Guard or wizard: mirrored
;
; Used by the routine at guard_face_plus_y.
guard_mirrored:
  SET 6,(IX+$07)          ; mirrored
  RET

; Guard or wizard: facing +Y
;
; Used by the routine at guard_moving_in_y.
guard_face_plus_y:
  RES 0,(IX+$00)          ; bit 0 clear, mirrored
  JR guard_mirrored       ;

; Gargoyle (type 22)
;
; The gargoyle block (gargoyle). It never moves and is never redrawn on its own
; account; all its handler does is make it deadly and set its pixel offsets.
upd_22:
  CALL set_both_deadly_flags ; deadly both ways
  JP adj_m7_m12           ; pixel offsets, and return

; Spiked ball (type 63)
;
; The spike_ball_fall block (spike_ball_fall). Deadly to touch. It hangs where
; the room put it until it is let go, then falls under gravity to whatever is
; below and stays there.
;
; Only one spiked ball in a room falls at a time: $5BBF is set while one is on
; its way down, and a waiting ball lets go with a chance of 1 in 16 each frame
; when it is clear. None falls at all while $5BC0 is non-zero. That byte is set
; on entering a room to bit 0 of the room number and is cleared when the player
; picks something up, so in odd-numbered rooms the balls wait until then.
upd_63:
  CALL set_both_deadly_flags ; deadly both ways; pixel offsets
  CALL upd_6_7               ;
  LD A,($5BC0)            ; held in this room
  AND A                   ;
  RET NZ                  ;
  BIT 2,(IX+$0D)          ; already falling
  JR NZ,spiked_ball_drop
  LD HL,$5BBF             ; another ball is falling
  LD A,(HL)               ;
  AND A                   ;
  RET NZ                  ;
  LD A,($5BA5)            ; 1 in 16: let go
  CP $10
  RET NC
  SET 2,(IX+$0D)          ; falling, and claim the one-at-a-time flag
  LD (HL),$01
  RET

; Spiked ball: fall
;
; Used by the routine at upd_63.
spiked_ball_drop:
  CALL dec_dZ_and_update_XYZ ; gravity and move
  BIT 2,(IX+$0C)          ; landed? if not, a sound pitched by the height
  JR NZ,spiked_ball_landed
  CALL sound_pitch_from_z

; Spiked ball: draw
;
; Used by the routine at spiked_ball_landed.
draw_spiked_ball:
  JP set_wipe_and_draw_flags ; wipe and draw

; Spiked ball: landed
;
; Used by the routine at spiked_ball_drop.
spiked_ball_landed:
  RES 2,(IX+$0D)          ; no longer falling
  LD HL,$5BBF             ; let the next ball go
  LD (HL),$00             ;
  JR draw_spiked_ball     ; draw

; Spike (type 23)
;
; The spike and spike_high blocks (spike and spike_high). Like the gargoyle:
; never moves, deadly to touch.
upd_23:
  CALL set_both_deadly_flags ; deadly both ways
  JP upd_6_7              ; pixel offsets, and return

; Fire moving east-west (types 86 and 87)
;
; The fire_ew block (fire_ew). Two units a frame along X, turning round with a
; thud when blocked; bit 0 of +13 is the direction, 1 for +X. It floats,
; flickers between types 86 and 87 every frame, and kills on contact.
upd_86_87:
  CALL upd_12_to_15       ; pixel offsets; dZ = 1, which the move's DEC makes
                          ; 0: no gravity
  LD (IX+$0B),$01
  BIT 0,(IX+$0D)          ; dX = +2 or -2 from bit 0 of +13
  LD A,$02
  JR NZ,fire_ew_move
  NEG

; Fire east-west: move
;
; Used by the routine at upd_86_87.
;
; A dX
fire_ew_move:
  LD (IX+$09),A           ; set dX; a sound pitched by X
  CALL sound_pitch_from_x ;
  CALL dec_dZ_and_update_XYZ ; move
  BIT 0,(IX+$0C)          ; blocked along X? A = the direction bit to flip
  LD A,$01
  JR fire_turn_if_blocked

; Fire moving north-south (types 180 and 181)
;
; The fire_ns block (fire_ns). The same as upd_86_87 along Y, with bit 1 of +13
; as the direction, 1 for +Y.
upd_180_181:
  CALL upd_12_to_15       ; pixel offsets; no gravity
  LD (IX+$0B),$01
  BIT 1,(IX+$0D)          ; dY = +2 or -2 from bit 1 of +13
  LD A,$02
  JR NZ,fire_ns_move
  NEG

; Fire north-south: move
;
; Used by the routine at upd_180_181.
;
; A dY
fire_ns_move:
  LD (IX+$0A),A           ; set dY; a sound pitched by Y
  CALL sound_pitch_from_y ;
  CALL dec_dZ_and_update_XYZ ; move
  BIT 1,(IX+$0C)          ; blocked along Y? A = the direction bit to flip
  LD A,$02

; Fire: turn round if blocked
;
; Used by the routine at fire_ew_move.
;
; A the direction bit in +13
; F Z clear if the move was blocked
fire_turn_if_blocked:
  JR Z,fire_flicker_and_draw ; not blocked
  XOR (IX+$0D)            ; turn round, with a thud
  LD (IX+$0D),A
  CALL sound_thud

; Fire: flicker and draw
;
; Used by the routine at fire_turn_if_blocked.
fire_flicker_and_draw:
  CALL toggle_next_prev_sprite ; flip bit 0 of the type
  JR set_deadly_wipe_and_draw_flags ; deadly, wipe and draw

; Fire standing still (types 176 and 177)
;
; The fire block (fire). It stays put and flickers: every other frame it flips
; between types 176 and 177 and, at random, mirrors itself.
;
; The every-other-frame test uses $5BBC, which the object loop sets to the
; frame counter and then increments before each object. Its bit 0 therefore
; alternates from frame to frame and from one record to the next, so
; neighbouring fires take turns.
upd_176_177:
  CALL upd_12_to_15       ; pixel offsets
  LD A,($5BBC)            ; not this frame: no change, no redraw
  AND $01                 ;
  RET Z                   ;
  LD A,($5BA5)                 ; flip the mirroring bit if a random bit is set;
  AND $40                      ; flip the type
  XOR (IX+$07)                 ;
  LD (IX+$07),A                ;
  CALL toggle_next_prev_sprite ;

; Make an object deadly and mark it to be wiped and redrawn
;
; Used by the routines at bounce_ball_animate, guard_ew_legs,
; fire_flicker_and_draw, ud_ball_draw, upd_30_31_158_159 and ghost_animate.
;
; The usual ending for a hostile object's handler.
set_deadly_wipe_and_draw_flags:
  CALL set_both_deadly_flags ; bits 7 and 5 of +13
  JP set_wipe_and_draw_flags ; bits 5 and 4 of +7

; Make an object deadly both ways
;
; Used by the routines at upd_22, upd_63, upd_23 and
; set_deadly_wipe_and_draw_flags.
;
; Sets bits 7 and 5 of +13. The collision code (adj_for_out_of_bounds) passes
; bit 7 of a moving object on to whatever it runs into, and bit 5 of an object
; on to whatever runs into it, as bit 6 -- the "has touched something deadly"
; flag the player's handler checks. With both set, it does not matter who
; moved.
set_both_deadly_flags:
  LD A,(IX+$0D)           ; +13 OR $A0
  OR $A0
  LD (IX+$0D),A
  RET

; Ball bouncing on the spot (types 178 and 179)
;
; The ball_ud blocks (ball_ud and its three shifted variants). The ball goes
; straight up and down: rising at two units a frame to a ceiling, then falling
; under gravity until it lands, which sends it up again with a thud. Bit 2 of
; +13 is set while it is rising. It flips between its two frames every frame
; and kills on contact.
;
; The ceiling is shared. $5BBD is cleared on entering a room, and the first
; ball to run sets it to 32 above its own height; every ball in the room then
; turns at that same height.
upd_178_179:
  CALL upd_12_to_15       ; pixel offsets
  LD A,($5BBD)               ; ceiling already set
  AND A                      ;
  JR NZ,ud_ball_rise_or_fall ;
  LD A,(IX+$03)           ; 32 above this ball
  ADD A,$20
  LD ($5BBD),A

; Ball bouncing on the spot: rise or fall
;
; Used by the routine at upd_178_179.
ud_ball_rise_or_fall:
  CALL toggle_next_prev_sprite ; flip the frame
  CALL sound_pitch_from_z ; a sound pitched by the height
  BIT 2,(IX+$0D)          ; rising
  JR NZ,ball_up
  CALL dec_dZ_and_update_XYZ ; falling: gravity and move
  BIT 2,(IX+$0C)          ; landed: go up, with a thud
  JR Z,ud_ball_draw
  SET 2,(IX+$0D)
  CALL sound_thud

; Ball bouncing on the spot: draw
;
; Used by the routines at ud_ball_rise_or_fall and ball_up.
ud_ball_draw:
  JR set_deadly_wipe_and_draw_flags ; deadly, wipe and draw

; Ball bouncing on the spot: rise
;
; Used by the routine at ud_ball_rise_or_fall.
;
; dZ is set to 3 every frame, so after the move's DEC it rises a steady two
; units. Once above the ceiling it is marked as falling, and gravity takes over
; from the next frame.
ball_up:
  LD (IX+$0B),$03            ; up two units
  CALL dec_dZ_and_update_XYZ ;
  LD A,($5BBD)            ; above the ceiling? start falling
  CP (IX+$03)             ;
  JR NC,ud_ball_draw      ;
  RES 2,(IX+$0D)          ;
  JR ud_ball_draw         ;

; Start the cauldron bubbles
;
; Used by the routine at end_of_frame.
;
; Called once a frame from end_of_frame. In the wizard's room, room $88, it
; puts the bubbles into object record 3 if that record is empty and the game is
; not already won ($5BC3). Records 2 and 3 are where the special objects found
; in a room go; in this room the code that drops an object only considers
; record 2, which leaves 3 for the bubbles.
init_cauldron_bubbles:
  LD A,($5C10)            ; not the wizard's room
  CP $88
  RET NZ
  LD DE,$5C68             ; record 3 already in use
  LD A,(DE)
  AND A
  RET NZ
  LD A,($5BC3)            ; the game has been won
  AND A
  RET NZ
  LD HL,cauldron_bubbles  ; copy the bubbles' first 18 bytes in; IX = record 3
  LD BC,$0012
  PUSH DE
  POP IX
  LDIR
  JP adj_m4_m12           ; set their pixel offsets, and return

; The cauldron bubbles' starting record
;
; The first 18 bytes of an object record, copied into record 3 by
; init_cauldron_bubbles; the rest of the record is already zero.
;
; The room byte is $B4, not the wizard's room $88. Nothing about the bubbles
; depends on it except the room tests in upd_164_to_167, which therefore treat
; bubbles that have turned hostile as being in some other room.
cauldron_bubbles:
  DEFB $A0,$80,$80,$80,$05,$05,$0C,$10
  DEFB $B4,$00,$00,$00,$00,$A0,$00,$00
  DEFB $00,$00

; Cauldron bubbles (types 160 to 163)
;
; The bubbles rise out of the cauldron, cycling through four frames, and they
; are not solid on the way up (bit 1 of +7 is set, so the collision code
; ignores them). At height $A0 they hover, and every fourth frame they are
; replaced by a picture of the next object the wizard wants -- type 168 plus
; that object's number -- for one frame in every five: the picture, then 160,
; 161, 162 and 163, then the picture again.
;
; If the player is Sabrewulf -- his legs are type 48 to 63 -- the bubbles turn
; hostile instead: they become types 164 to 167 (upd_164_to_167), solid, and
; still carry the deadly bits their starting record gave them.
;
; They vanish while object record 2 is occupied, which is while an object has
; been dropped into the cauldron and is being taken. init_cauldron_bubbles puts
; them back once the record is free again.
upd_160_to_163:
  CALL adj_m4_m12         ; pixel offsets
  LD A,($5C48)            ; an object is in the cauldron: vanish
  AND A                   ;
  JP NZ,upd_111           ;
  SET 1,(IX+$07)          ; not solid
  CALL dec_dZ_and_update_XYZ ; move; next of four frames
  CALL next_graphic_no_mod_4 ;
  LD A,(IX+$03)           ; still below $A0: dZ = 2, so rise one unit
  CP $A0
  LD (IX+$0B),$02
  JR C,bubbles_draw
  LD (IX+$0B),$01         ; at the top: dZ = 1, so hover
  LD A,($5C08)            ; the player is Sabrewulf
  SUB $30
  CP $10
  JR C,bubbles_turn_hostile
  LD A,(IX+$00)           ; only when the cycle comes back round to 160
  AND $03
  JR NZ,bubbles_draw
  CALL ret_next_obj_required ; show the object wanted: type 168 plus its number
  LD A,(HL)                  ;
  OR $A8                     ;
  LD (IX+$00),A              ;

; Cauldron bubbles: draw
;
; Used by the routines at upd_160_to_163, bubbles_turn_hostile and
; upd_168_to_175.
bubbles_draw:
  JP set_wipe_and_draw_flags ; wipe and draw

; Cauldron bubbles: turn hostile
;
; Used by the routine at upd_160_to_163.
;
; Setting bit 2 of the type turns 160-163 into 164-167, and clearing bit 1 of
; +7 makes them solid, so they can now touch the player.
bubbles_turn_hostile:
  SET 2,(IX+$00)          ; types 164-167; solid
  RES 1,(IX+$07)
  JR bubbles_draw         ; draw

; The object the wizard wants, shown in the bubbles (types 168 to 175)
;
; Lasts one frame: goes straight back to the first bubble frame.
upd_168_to_175:
  CALL adj_m4_m12         ; pixel offsets; type 160
  LD (IX+$00),$A0
  JR bubbles_draw         ; draw

; Chasing sparkles (types 164 to 167)
;
; The repel_spell block (repel_spell), and the cauldron bubbles once they have
; turned on Sabrewulf. They fly straight at the player, four units a frame
; along each of X and Y, cycling through four frames. They slow to one unit a
; frame while the player is in an archway (bit 0 of the player's +7, set by
; chk_plyr_spec_near_arch), except in the wizard's room. Gravity still applies.
;
; In the wizard's room they vanish once the player is no longer either form of
; the knight -- object 0's type outside 16 to 79, as it is once he has died.
; Because the bubbles' record says room $B4 (cauldron_bubbles), in practice
; this test is only made for sparkles built into room $88 itself, if any are.
;
; Whether they do harm depends on +13: the bubbles' starting record makes them
; deadly, but a room's repel_spell record starts with +13 clear.
upd_164_to_167:
  CALL adj_m4_m12         ; pixel offsets
  LD A,(IX+$08)           ; in the wizard's room: always fast
  CP $88
  JR Z,chaser_speed_fast
  LD A,($5C0F)            ; the player is not in an archway: fast
  BIT 0,A                 ;
  JR Z,chaser_speed_fast  ;
  LD BC,$0101             ; slow
  JR chaser_chase

; Chasing sparkles: fast
;
; Used by the routine at upd_164_to_167.
chaser_speed_fast:
  LD BC,$0404             ; four units a frame

; Chasing sparkles: chase
;
; Used by the routine at upd_164_to_167.
;
; BC the speed along Y (B) and X (C)
chaser_chase:
  CALL move_towards_plyr  ; aim at the player
  CALL dec_dZ_and_update_XYZ ; gravity and move; next of four frames
  CALL next_graphic_no_mod_4 ;
  LD A,(IX+$08)           ; not the wizard's room: carry on
  CP $88
  JR NZ,sound_wipe_and_draw
  LD A,($5C08)            ; the player's legs are still type 16 to 79: carry on
  SUB $10                 ;
  CP $40
  JR C,sound_wipe_and_draw

; Make an object vanish (type 111)
;
; Used by the routines at upd_160_to_163, upd_119 and cauldron_consume.
;
; Also reached from upd_160_to_163, upd_119 and cauldron_consume. Type 1 has no
; handler; the renderer (calc_pixel_XY_and_render) wipes a type 1 object one
; last time and then sets its type to 0, freeing the record.
upd_111:
  LD (IX+$00),$01         ; type 1

; Play a sound, then wipe and draw
;
; Used by the routine at chaser_chase.
sound_wipe_and_draw:
  JP click_wipe_and_draw  ; see click_wipe_and_draw

; Point an object at the player
;
; Used by the routines at spark_home_in and chaser_chase.
;
; Sets dX and dY to plus or minus the given speeds, each pointing from the
; object towards the player along its axis. The sign is taken from the
; difference, so it is right as long as the two are less than 128 apart. When
; they are level the object steps back the negative way, so a chaser jitters
; about the player rather than stopping on him.
;
; IX the object
; C the speed along X
; B the speed along Y
move_towards_plyr:
  LD HL,$5C09             ; own X minus the player's X
  LD A,(IX+$01)
  SUB (HL)
  INC HL                  ; C if the player is further along X, else -C
  LD A,C                  ;
  JP M,towards_plyr_y     ;
  NEG                     ;

; Point at the player: Y
;
; Used by the routine at move_towards_plyr.
;
; A the step along X
towards_plyr_y:
  LD (IX+$09),A           ; dX; own Y
  LD A,(IX+$02)
  SUB (HL)                 ; minus the player's Y: B if the player is further
  INC HL                   ; along Y, else -B
  LD A,B                   ;
  JP M,towards_plyr_set_dy ;
  NEG                      ;

; Point at the player: set dY
;
; Used by the routine at towards_plyr_y.
;
; A the step along Y
towards_plyr_set_dy:
  LD (IX+$0A),A           ; dY
  RET

; Flip between an object's two frames
;
; Used by the routines at bounce_ball_animate, fire_flicker_and_draw,
; upd_176_177, ud_ball_rise_or_fall and ghost_animate.
;
; Toggles bit 0 of the type. Used for the fires and the balls, whose two frames
; are a pair of types differing only in bit 0.
toggle_next_prev_sprite:
  LD A,(IX+$00)           ; type XOR 1
  XOR $01
  JR save_graphic_no

; Step an object through four frames
;
; Used by the routines at upd_160_to_163 and chaser_chase.
;
; Increments the low two bits of the type and leaves the rest alone, so 160
; goes to 161, 162, 163 and back to 160.
next_graphic_no_mod_4:
  LD A,(IX+$00)           ; type with its low two bits plus 1, modulo 4
  LD C,A
  AND $FC
  LD B,A
  LD A,C
  INC A
  AND $03
  OR B

; Store an object's type
;
; Used by the routine at toggle_next_prev_sprite.
;
; A the new type
save_graphic_no:
  LD (IX+$00),A           ; type
  RET

; The cauldron (type 141)
;
; The cauldron layout (cauldron). It stands still; all its handler does is set
; its pixel offsets.
upd_141:
  JP upd_88_to_90         ; pixel offsets, and return

; The cauldron's top (type 142)
;
; The second record of the cauldron layout: a sprite with no size, drawn 24
; pixels left of and 12 above its position. Never moves.
upd_142:
  LD HL,$0CE8             ; pixel offsets, and return
  JP set_pixel_adj        ;

; Guard walking round the room, and the wizard (types 30, 31, 158 and 159)
;
; The body of a guard_square guard (guard_square), and the wizard (wizard).
; Each frame it moves with the deltas it already has, then picks its next
; deltas from whether that move was blocked: it walks two units a frame in a
; straight line until it hits something, then turns a quarter and carries on.
; The turns always go the same way round, -X, +Y, +X, -Y, so it follows the
; walls of the room. It is deadly to touch.
;
; Its legs are the next record: they get its X, Y, dX and dY every frame.
upd_30_31_158_159:
  CALL adj_p3_m12         ; pixel offsets: 9 pixels above the legs
  CALL dec_dZ_and_update_XYZ ; gravity and move
  CALL move_guard_wizard_NSEW ; the next heading, in H (dY) and L (dX)
  LD (IX+$09),L           ; set its deltas and the legs'
  LD (IX+$29),L
  LD (IX+$0A),H
  LD (IX+$2A),H
  LD A,(IX+$01)           ; the legs go where it went
  LD (IX+$21),A
  LD A,(IX+$02)
  LD (IX+$22),A
  CALL set_guard_wizard_sprite ; choose its frame and mirroring
  JP set_deadly_wipe_and_draw_flags ; deadly, wipe and draw

; Choose a walking guard's next heading
;
; Used by the routine at upd_30_31_158_159.
;
; Bits 0 and 1 of +13 are the heading, and the handler for each is in
; guard_NSEW_tbl. Each one returns the deltas for carrying on the same way, or,
; if the last move was blocked along that heading's axis, the deltas for the
; next heading and a step on of the heading bits.
;
; HL on exit, the new dY (H) and dX (L)
move_guard_wizard_NSEW:
  LD BC,guard_NSEW_tbl    ; jump on bits 0 and 1 of +13
  LD A,(IX+$0D)           ;
  AND $03
  LD L,A
  JP jump_to_tbl_entry

; Walking guard's headings
;
; Four handlers indexed by the heading in bits 0 and 1 of +13, in the order
; they are walked: tcdev's names call -X west, +Y north, +X east and -Y south.
guard_NSEW_tbl:
  DEFW guard_W            ; 0: heading -X
  DEFW guard_N            ; 1: heading +Y
  DEFW guard_E            ; 2: heading +X
  DEFW guard_S            ; 3: heading -Y

; Walking guard heading -X
guard_W:
  LD HL,$00FE             ; dX = -2; not blocked along X, keep going
  BIT 0,(IX+$0C)
  RET Z
  LD HL,$0200             ; blocked: dY = +2, and turn

; Walking guard: next heading
;
; Used by the routines at guard_N, guard_E and guard_S.
;
; Adds 1 to bits 0 and 1 of +13, wrapping round, and leaves the other bits
; alone.
next_guard_dir:
  LD A,(IX+$0D)           ; heading + 1, modulo 4
  LD C,A
  INC A
  AND $03
  LD B,A
  LD A,C
  AND $FC
  OR B
  LD (IX+$0D),A
  RET

; Walking guard heading +Y
guard_N:
  LD HL,$0200             ; dY = +2; not blocked along Y, keep going
  BIT 1,(IX+$0C)
  RET Z
  LD HL,$0002             ; blocked: dX = +2, and turn
  JR next_guard_dir

; Walking guard heading +X
guard_E:
  LD HL,$0002             ; dX = +2; not blocked along X, keep going
  BIT 0,(IX+$0C)
  RET Z
  LD HL,$FE00             ; blocked: dY = -2, and turn
  JR next_guard_dir

; Walking guard heading -Y
guard_S:
  LD HL,$FE00             ; dY = -2; not blocked along Y, keep going
  BIT 1,(IX+$0C)
  RET Z
  LD HL,$00FE             ; blocked: dX = -2, and turn
  JR next_guard_dir

; Game over
;
; Used by the routines at spark_touch, inc_days and lose_life.
;
; The one way out of a game, whichever way it ended: inc_days comes here when
; the fortieth day begins, lose_life when the last life is lost, and
; upd_131_to_133 when the final animation reaches the player after the
; fourteenth object has gone into the cauldron. The last case has set $5BC3,
; and the player sees the completion message at game_complete_msg before the
; same summary screen everyone else gets.
game_over:
  LD A,($5BC3)
  AND A
  JP NZ,game_complete_msg

; The game-over summary screen
;
; Used by the routine at game_complete_msg.
;
; Clears the screen and its buffer and writes the six-line summary -- time
; taken, percentage of the quest completed, charms collected and an overall
; rating -- then fills in the numbers. The text goes into the buffer at
; screen_buffer while the attributes go straight to the screen, so nothing
; shows until print_charms_and_show copies the buffer across.
;
; The rating is one of eight words from rating_tbl. Bit 0 of $5BC3 (the quest
; finished) picks the better four; bits 5 and 6 of $5BC6, the number of rooms
; visited less one, pick one of those four. So the rating moves up a step for
; every 32 rooms seen, and a player who finishes having seen more of the castle
; is rated higher than one who took a short cut.
game_over_summary:
  CALL clear_scrn_buffer  ; blank the buffer and the screen
  CALL clear_scrn         ;
  LD DE,gameover_colours  ; six lines: colours from gameover_colours, positions
                          ; from gameover_xy, text from gameover_text
  EXX
  LD HL,gameover_xy
  LD DE,gameover_text
  LD B,$06
  CALL display_text_list
  LD HL,$E8E2             ; the days taken, two BCD digits from $5BB9, into the
  LD DE,$5BB9             ; buffer at y=127, column 15
  LD B,$01
  CALL print_BCD_number
  CALL calc_and_display_percent ; count the rooms visited and print the
                                ; percentage
  LD A,($5BC6)            ; bits 6 and 5 of rooms-visited-less-one, moved up to
  RLCA                    ; bits 7 and 6
  AND $C0                 ;
  LD C,A                  ;
  LD A,($5BC3)            ; add the quest-complete flag as bit 0
  AND $01                 ;
  OR C                    ;
  RLCA                    ; rotate into place: complete*8 + visited bits * 2, a
  RLCA                    ; word offset
  RLCA                    ;
  AND $0E                 ;
  LD L,A                  ; DE = the rating text's address from rating_tbl
  LD H,$00                ;
  LD BC,rating_tbl        ;
  ADD HL,BC               ;
  LD E,(HL)               ;
  INC HL                  ;
  LD D,(HL)               ;
  LD HL,$2758              ; print it at x=$58, y=$27; its first byte is its
  CALL print_text_std_font ; colour
  LD DE,$5BBB                ; the charms count is kept in binary (0 to 14):
  LD A,(DE)                  ; turn 10 to 14 into BCD for printing -- harmless,
  SUB $0A                    ; since the game is over
  JR C,print_charms_and_show ;
  OR $10                     ;
  LD (DE),A                  ;

; Print the charms count and show the summary
;
; Used by the routine at game_over_summary.
;
; The last number on the summary, then the border and the copy of the finished
; buffer to the screen.
print_charms_and_show:
  LD HL,$E2EA             ; two BCD digits from $5BBB, at y=79, column 23 of
                          ; the buffer
  LD B,$01
  CALL print_BCD_number
  CALL print_border       ; draw the border and copy the buffer to the display
  CALL update_screen      ;

; Wait, play the game-over tune, and start again
;
; Waits for every key to be let go -- the player is probably still holding one
; down from the moment of death -- then plays the game-over tune until a key is
; pressed, lingers for a while longer or until a key, and restarts at
; start_menu, which keeps the control method and the random seeds.
await_restart:
  XOR A                   ; all eight half-rows at once: loop while anything is
  CALL read_port          ; held
  JR NZ,await_restart     ;
  LD DE,game_over_tune           ; the tune at game_over_tune, cut short by any
  CALL play_audio_until_keypress ; key
  LD B,$08                ; about 14 seconds, or until a key
  CALL wait_for_key_press
  JP start_menu           ; new game, without the menu's reset of everything

; Wait a while or until a key is pressed
;
; Used by the routines at await_restart and game_complete_msg.
;
; Polls all eight half-rows through read_port until one shows a key or the
; count runs out. Each poll costs about 95 T-states, so B=8 -- what both
; callers pass -- is roughly 14 seconds.
;
; B how long: B times 65536 polls of the keyboard
wait_for_key_press:
  LD HL,$0000             ; HL counts 65536 polls before B is decremented

; One poll of the keyboard
wait_key_poll:
  XOR A                   ; A=0 selects every half-row; return as soon as any
  CALL read_port          ; key is down
  RET NZ                  ;
  DEC HL                  ; inner count
  LD A,H                  ;
  OR L                    ;
  JR NZ,wait_key_poll     ;
  DJNZ wait_key_poll      ; outer count
  RET

; The quest is complete
;
; Used by the routine at game_over.
;
; Shown in place of nothing else: blanks the screen, writes the six-line
; completion message, plays the completion tune to its end (no key cuts it
; short), waits up to 14 seconds or for a key, and then goes on to the ordinary
; summary at game_over_summary.
game_complete_msg:
  CALL clear_scrn_buffer  ; blank the buffer and the screen
  CALL clear_scrn         ;
  LD DE,complete_colours  ; colours from complete_colours, positions from
  EXX                     ; complete_xy, text from complete_text
  LD HL,complete_xy       ;
  LD DE,complete_text     ;
  LD B,$06                ;
  XOR A                   ; clearing $5BB8 makes display_text_list draw the
  LD ($5BB8),A            ; border and show the screen as soon as the text is
  CALL display_text_list  ; written
  LD DE,game_complete_tune ; the completion tune at game_complete_tune, played
  CALL play_audio          ; in full
  LD B,$08                ; then the same summary as a failed game
  CALL wait_for_key_press ;
  JP game_over_summary    ;

; Completion message: the colour of each line
;
; Six attribute bytes, one per line of complete_text, used in order by
; display_text_list: bright ink on black, running from white down through
; yellow, cyan, green and magenta to red.
complete_colours:
  DEFB $47,$46,$45,$44,$43,$42

; Completion message: where each line goes
;
; Six (x, y) pairs in pixels, one per line of complete_text. x counts from the
; left edge; y counts up from the bottom of the screen and is the top row of
; the characters. x is a multiple of 8, so each line starts on a character
; column.
complete_xy:
  DEFB $40,$87
  DEFB $40,$77
  DEFB $30,$67
  DEFB $30,$57
  DEFB $50,$47
  DEFB $30,$37

; Completion message: the text
;
; Six strings in the game's text code (see print_text): one byte per character,
; the index of its glyph in the font at font -- 0 to 9 are the digits, $0A to
; $23 the letters, $26 a space -- with bit 7 set on the last character of each
; string. These have no colour byte of their own; the colours come from
; complete_colours.
complete_text:
  DEFB $1D,$11,$0E,$26,$19,$18,$1D,$12 ; Line 1
  DEFB $18,$17,$26,$0C,$0A,$1C,$1D,$9C ;
  DEFB $12,$1D,$1C,$26,$16,$0A,$10,$12 ; Line 2
  DEFB $0C,$26,$1C,$1D,$1B,$18,$17,$90 ;
  DEFB $0A,$15,$15,$26,$0E,$1F,$12,$15
  DEFB $26,$16,$1E,$1C,$1D,$26,$0B,$0E
  DEFB $20,$0A,$1B,$8E
  DEFB $1D,$11,$0E,$26,$1C,$19,$0E,$15
  DEFB $15,$26,$11,$0A,$1C,$26,$0B,$1B
  DEFB $18,$14,$0E,$97
  DEFB $22,$18,$1E,$26,$0A,$1B,$0E,$26
  DEFB $0F,$1B,$0E,$8E
  DEFB $10,$18,$26,$0F,$18,$1B,$1D,$11
  DEFB $26,$1D,$18,$26,$16,$12,$1B,$0E
  DEFB $16,$0A,$1B,$8E

; Game-over summary: the colour of each line
;
; Six attribute bytes, one per line of gameover_text, all bright on black.
gameover_colours:
  DEFB $47,$46,$45,$45,$43,$44

; Game-over summary: where each line goes
;
; Six (x, y) pairs in pixels, in the same form as complete_xy.
gameover_xy:
  DEFB $58,$9F
  DEFB $50,$7F
  DEFB $30,$6F
  DEFB $40,$5F
  DEFB $30,$4F,$48,$37

; Game-over summary: the text
;
; Six strings in the game's text code (see complete_text for the format),
; without colour bytes. Four of them leave blank space where a number is
; printed afterwards straight into the buffer: the days (game_over_summary),
; the percentage (calc_and_display_percent) and the charms
; (print_charms_and_show). The fourth line ends in character $27, the percent
; sign.
gameover_text:
  DEFB $10,$0A,$16,$0E,$26,$26,$18,$1F
  DEFB $0E,$9B
  DEFB $1D,$12,$16,$0E,$26,$26,$26,$26
  DEFB $0D,$0A,$22,$9C
  DEFB $19,$0E,$1B,$0C,$0E,$17,$1D,$0A
  DEFB $10,$0E,$26,$18,$0F,$26,$1A,$1E
  DEFB $0E,$1C,$9D
  DEFB $0C,$18,$16,$19,$15,$0E,$1D,$0E
  DEFB $0D,$26,$26,$26,$26,$26,$A7
  DEFB $0C,$11,$0A,$1B,$16,$1C,$26,$0C
  DEFB $18,$15,$15,$0E,$0C,$1D,$0E,$0D
  DEFB $26,$26,$A6
  DEFB $18,$1F,$0E,$1B,$0A,$15,$15,$26
  DEFB $1B,$0A,$1D,$12,$17,$90

; The ratings
;
; Eight addresses of rating words, picked by game_over_summary: index = 4 if
; the quest was completed, plus (rooms visited - 1) / 32, so the second number
; runs 0 to 3 for up to 128 rooms.
rating_tbl:
  DEFW rating_poor        ; Quest not completed, fewest rooms first:
  DEFW rating_average     ; rating_poor, rating_average, rating_fair,
  DEFW rating_fair        ; rating_good
  DEFW rating_good        ;
  DEFW rating_excellent   ; Quest completed, fewest rooms first:
  DEFW rating_marvellous  ; rating_excellent, rating_marvellous, rating_hero,
  DEFW rating_hero        ; rating_adventurer
  DEFW rating_adventurer  ;

; Rating: 1 to 32 rooms, not completed
;
; A rating string: a colour byte (bright red), then the word in the text code,
; padded on the left with spaces so that every rating ends in the same column.
; Bit 7 marks the last character.
rating_poor:
  DEFB $42,$26,$26,$26,$19,$18,$18,$9B

; Rating: 33 to 64 rooms, not completed
;
; Same form as rating_poor. Oddly, this word ranks below the next one.
rating_average:
  DEFB $42,$26,$0A,$1F,$0E,$1B,$0A,$10
  DEFB $8E

; Rating: 65 to 96 rooms, not completed
;
; Same form as rating_poor.
rating_fair:
  DEFB $42,$26,$26,$26,$0F,$0A,$12,$9B

; Rating: 97 rooms or more, not completed
;
; Same form as rating_poor: the best rating a player can get without finishing.
rating_good:
  DEFB $42,$26,$26,$26,$10,$18,$18,$8D

; Rating: 1 to 32 rooms, completed
;
; Same form as rating_poor.
rating_excellent:
  DEFB $42,$0E,$21,$0C,$0E,$15,$15,$0E
  DEFB $17,$9D

; Rating: 33 to 64 rooms, completed
;
; Same form as rating_poor.
rating_marvellous:
  DEFB $42,$16,$0A,$1B,$1F,$0E,$15,$15
  DEFB $18,$1E,$9C

; Rating: 65 to 96 rooms, completed
;
; Same form as rating_poor.
rating_hero:
  DEFB $42,$26,$26,$26,$11,$0E,$1B,$98

; Rating: 97 rooms or more, completed
;
; Same form as rating_poor. The top rating needs the quest finished and most of
; the castle explored.
rating_adventurer:
  DEFB $42,$0A,$0D,$1F,$0E,$17,$1D,$1E
  DEFB $1B,$0E,$9B

; Count the rooms visited and print the percentage of the quest
;
; Used by the routine at game_over_summary.
;
; Counts the set bits in the 32-byte visited-room map at $5BE8 -- one bit per
; room number, set by flag_room_visited whenever a room is entered -- and keeps
; that count less one in $5BC6 for the rating.
;
; The percentage is (rooms + 2 x charms) x 100 / 156, and 156 is 128 rooms plus
; 14 charms counted twice, so visiting every room and filling the cauldron is
; exactly 100. There is no divide: HL is a 16-bit fraction and A a BCD whole
; part, and adding 100/156 as a 16-bit fraction once per point carries into A,
; with DAA keeping A decimal. The final $28 is exactly what a perfect score
; falls short of 100 x 65536, so the maximum comes out as 100 rather than 99;
; it is also the only step that can carry into the hundreds.
;
; E on exit, rooms + 2 x charms
calc_and_display_percent:
  LD E,$00                ; E = the count; B = 8 bits, C = 32 bytes, from $5BE8
  LD BC,$0820
  LD HL,$5BE8

; Count the visited bits in one byte
;
; Used by the routine at next_visited_bit.
count_screens:
  PUSH BC                 ; next byte of the map
  LD A,(HL)               ;
  INC HL                  ;

; Test one bit of the visited map
;
; Used by the routine at next_visited_bit.
count_visited_bit:
  RRCA                    ; count it if set
  JR NC,next_visited_bit  ;
  INC E                   ;

; Next bit, next byte, then work out the percentage
;
; Used by the routine at count_visited_bit.
next_visited_bit:
  DJNZ count_visited_bit  ; eight bits per byte, 32 bytes
  POP BC
  DEC C
  JR NZ,count_screens
  LD A,E                  ; rooms visited less one, for the rating in
  DEC A                   ; game_over_summary
  LD ($5BC6),A            ;
  LD A,($5BBB)            ; charms count double
  SLA A                   ;
  ADD A,E                 ;
  LD E,A                  ;
  LD BC,$A41A             ; HL = fraction, A = BCD whole part
  LD HL,$0000
  XOR A

; Add 100/156 per point
scale_to_percent:
  ADD HL,BC               ; the carry out of the fraction is a whole 1 per cent
  ADC A,$00               ;
  DAA                     ;
  DEC E
  JR NZ,scale_to_percent
  LD BC,$0028             ; the correction that lets 156 points reach 100
  ADD HL,BC
  ADC A,$00
  DAA
  LD ($5BCA),A            ; tens and units, BCD
  LD A,$00                ; the hundreds digit, 0 or 1
  ADC A,$00               ;
  DAA                     ;
  LD ($5BC9),A            ;
  LD HL,$E4E6             ; into the buffer at y=95, column 19
  LD DE,$5BC9             ;
  LD B,$01                ;
  LD A,(DE)                     ; three digits when it is 100: the low digit of
  AND A                         ; $5BC9, then $5BCA
  JR Z,print_percent_two_digits ;
  INC B                         ;
  JP print_BCD_lsd              ;

; Print a percentage under 100
;
; Used by the routine at scale_to_percent.
;
; One column to the right and one byte on, so the two digits line up with the
; last two of a three-digit number.
print_percent_two_digits:
  INC HL
  INC DE
  JP print_BCD_number

; Print the day count on the panel
;
; Used by the routines at no_delay and inc_days.
;
; Two BCD digits from $5BB9 into the buffer at the bottom of the panel (y=7,
; column 15), then makes their two attribute cells bright white directly on the
; screen. inc_days copies the digits to the display.
print_days:
  LD HL,$D9E2
  LD DE,$5BB9
  LD B,$01
  CALL print_BCD_number
  LD HL,$5AEF
  LD (HL),$47
  INC L
  LD (HL),$47
  RET

; Draw the lives icon on the panel
;
; Used by the routine at no_delay.
;
; Uses the object record at sprite_scratchpad to draw sprite type $8C at x=16,
; y=32 in the buffer, then makes six attribute cells bright white: two in
; character row 18 and four in row 19, from column 2 -- the icon and the two
; cells where print_lives prints the number.
print_lives_gfx:
  LD IX,sprite_scratchpad ; the icon, unflipped
  LD (IX+$00),$8C
  LD (IX+$07),$00
  LD (IX+$1A),$10
  LD (IX+$1B),$20
  CALL print_sprite
  LD A,$47                ; two cells of row 18 and four of row 19, from column
  LD DE,$5A42             ; 2
  LD B,$02                ;
  CALL fill_DE            ;
  LD DE,$5A62             ;
  LD B,$04                ;
  JP fill_DE              ;

; Print the number of lives
;
; Used by the routines at no_delay and upd_103.
;
; $5BBA as two BCD digits at y=39, column 4 of the buffer. The game counts
; lives in binary (it starts with 5; lose_life decrements and upd_103
; increments), so the display is right only while there are fewer than 10.
print_lives:
  LD DE,$5BBA
  LD B,$01
  LD HL,$DDD7
  JP print_BCD_number

; Print BCD numbers in the standard font
;
; Used by the routines at game_over_summary, print_charms_and_show,
; print_percent_two_digits, print_days and print_lives.
;
; Points the font pointer at $5BC7 at the standard font and prints each nibble
; as a character -- the digits are the first ten glyphs, so a BCD nibble is its
; own character code. No attributes are touched.
;
; DE the first byte of the number
; B how many bytes: two digits each, high digit first
; HL where in the buffer at screen_buffer the first digit's top row goes
print_BCD_number:
  PUSH HL
  LD HL,font
  LD ($5BC7),HL
  POP HL

; Print both digits of one BCD byte
;
; Used by the routine at print_BCD_lsd.
print_BCD_byte:
  LD A,(DE)               ; high digit
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  AND $0F                 ;
  CALL print_8x8          ;

; Print the low digit of a BCD byte
;
; Used by the routine at scale_to_percent.
;
; Also an entry point: starting here skips a leading digit, which is how
; calc_and_display_percent prints the 1 of 100.
print_BCD_lsd:
  LD A,(DE)
  AND $0F
  CALL print_8x8
  INC DE                  ; next byte
  DJNZ print_BCD_byte     ;
  RET

; Draw the day label on the panel
;
; Used by the routine at no_delay.
;
; Prints day_txt with the four-glyph font at day_font, at x=$70, y=$0F. Its
; colour is worked out from the room's colour in $5BAD: the ink is (1 - room
; ink) mod 8, bright, on black, so the label changes colour with the room.
display_day:
  LD A,($5BAD)
  CPL
  ADD A,$02
  AND $07
  OR $40
  LD (day_txt),A
  LD HL,day_font          ; the private font
  LD ($5BC7),HL           ;
  LD DE,day_txt
  LD HL,$0F70             ; print_text takes its position from the stack
  PUSH HL
  JP print_text

; The day label
;
; A string in the text code with a colour byte at the front (filled in by
; display_day), followed by the four glyphs of day_font in order, the last with
; bit 7 set.
day_txt:
  DEFB $00,$00,$01,$02,$83

; The day label's font
;
; Four 8x8 glyphs, eight bytes each, top row first, that together make one
; small hand-lettered word four cells wide. Nothing else uses them.
day_font:
  DEFB $06,$07,$06,$06,$06,$06,$06,$0F
  DEFB $00,$01,$82,$C6,$64,$6C,$6D,$C6
  DEFB $C8,$C6,$E1,$60,$60,$E0,$64,$63
  DEFB $60,$60,$60,$E0,$60,$40,$C0,$80

; The control-method menu
;
; Used by the routine at main.
;
; Reads the keyboard directly rather than through the ROM: read_port OUTs a
; half-row and INs port $FE. Keys 1 to 4 choose keyboard, Kempston, cursor or
; Interface II, 5 toggles directional control, and 0 starts the game. The
; options chosen are shown by the FLASH bit of their line's colour.
;
; The control method is bits 1 and 2 of $5BA4 (0 keyboard, 1 Kempston, 2
; cursor, 3 Interface II) and bit 3 is directional control. The menu tune plays
; only on the first pass and blocks until it ends or a key is pressed (see
; menu_loop), so the menu does not respond to keys until then.
do_menu_selection:
  XOR A                   ; $5BB8=0: the first list drawn will show the screen
  LD ($5BB8),A            ;
  LD HL,menu_colours
  LD B,$08
; Worth knowing if you are driving the game from a script: nothing here goes
; through LAST-K, so poking the ROM's key buffer has no effect at all. The keys
; have to be presented at the port.

; Clear the FLASH bit on every menu line, then draw the menu
clear_menu_flash:
  RES 7,(HL)              ; all eight colours in menu_colours
  INC HL                  ;
  DJNZ clear_menu_flash   ;
  CALL clear_scrn_buffer  ; draw into the buffer; display_text_list shows it
  CALL display_menu       ; this first time
  CALL flash_menu         ; flash the lines already selected

; The menu loop
;
; Used by the routine at check_for_start_game.
;
; One pass: redraws the menu (only its attributes change on screen after the
; first time), plays the tune if it has not played yet, and reads keys 1 to 5
; into E. The control byte is kept in A through the key tests that follow and
; saved in $5BA6 first, so that check_for_start_game can click when it changes.
menu_loop:
  CALL display_menu
  LD DE,menu_tune          ; menu_tune; $5BD1 makes this a no-op after the
  CALL play_audio_wait_key ; first pass
  LD A,$F7                ; half-row $F7 is 1 2 3 4 5, key 1 in bit 0
  CALL read_port
  LD E,A
  LD A,($5BA4)            ; A = control byte; remember it as it was
  LD ($5BA6),A            ;
  BIT 0,E                          ; key 1: method 0, keyboard
  JR Z,check_for_kempston_joystick ;
  AND $F9                          ;

; Key 2: Kempston joystick
;
; Used by the routine at menu_loop.
check_for_kempston_joystick:
  BIT 1,E                        ; method 1
  JR Z,check_for_cursor_joystick ;
  AND $F9                        ;
  OR $02                         ;

; Key 3: cursor joystick
;
; Used by the routine at check_for_kempston_joystick.
check_for_cursor_joystick:
  BIT 2,E                     ; method 2
  JR Z,check_for_interface_ii ;
  AND $F9                     ;
  OR $04                      ;

; Key 4: Interface II joystick
;
; Used by the routine at check_for_cursor_joystick.
check_for_interface_ii:
  BIT 3,E                            ; method 3
  JR Z,check_for_directional_control ;
  OR $06                             ;

; Store the method, then key 5: directional control
;
; Used by the routine at check_for_interface_ii.
;
; Key 5 flips bit 3 of $5BA4, once per press: bit 0 of $5BD2 remembers that the
; key is down, and clr_debounce clears it when the key is let go.
check_for_directional_control:
  LD ($5BA4),A            ; the method chosen by keys 1 to 4
  LD HL,$5BD2
  BIT 4,E                 ; key 5 not pressed: clear the latch
  JR Z,clr_debounce       ;
  BIT 0,(HL)                 ; still held since last pass: do nothing
  JR NZ,check_for_start_game ;
  SET 0,(HL)              ; new press: latch it and toggle directional control
  LD A,($5BA4)            ;
  XOR $08                 ;
  LD ($5BA4),A            ;

; Start the game?
;
; Used by the routines at check_for_directional_control and clr_debounce.
;
; Clicks if the control byte changed this pass, then returns to start the game
; if 0 is pressed. Otherwise it bumps the seed at $5BA0 -- so the time spent in
; the menu shapes the game that follows -- updates the flashing lines and goes
; round again.
check_for_start_game:
  LD HL,$5BA6             ; A is the new control byte here, whichever way we
                          ; arrived
  CP (HL)
  CALL NZ,toggle_audio_hw_x16
  LD A,$EF                ; half-row $EF is 0 9 8 7 6; bit 0 is the 0 key
  CALL read_port
  BIT 0,A                 ; CPL in read_port means a set bit is a pressed key
  RET NZ
  LD HL,$5BA0             ; one more step of the seed per pass of the menu
  INC (HL)
  CALL flash_menu         ; show the new selection and loop
  JP menu_loop            ;

; Key 5 released
;
; Used by the routine at check_for_directional_control.
clr_debounce:
  RES 0,(HL)              ; clear the latch in $5BD2
  JR check_for_start_game

; Flash the selected menu lines
;
; Used by the routines at clear_menu_flash and check_for_start_game.
;
; Sets the FLASH bit on the colour of the line for the chosen control method
; and clears it on the other three, then sets or clears it on the
; directional-control line to match bit 3 of $5BA4. The colours are in
; menu_colours; the first byte is the title's and is left alone.
flash_menu:
  LD HL,$BDA3             ; the colour of the first option line: the second
                          ; byte of menu_colours
  LD A,($5BA4)            ; method 0 to 3 selects one of four lines
  RRCA                    ;
  AND $03                 ;
  LD B,$04                ;
  CALL toggle_selected    ;
  RES 7,(HL)              ; HL is now at the directional-control line
  LD A,($5BA4)            ;
  AND $08                 ;
  RET Z                   ;
  SET 7,(HL)              ;
  RET                     ;

; Menu: the colour of each line
;
; Eight attribute bytes for the lines of menu_text: the title, the four control
; methods, directional control, start, and the copyright line. Bit 7 (FLASH)
; marks a selected option; flash_menu sets and clears it, and the initial value
; flashes the first method, keyboard.
menu_colours:
  DEFB $43,$C4,$44,$44,$44,$45,$47,$47

; Menu: where each line goes
;
; Eight (x, y) pixel pairs, in the same form as complete_xy.
menu_xy:
  DEFB $58,$9F
  DEFB $30,$8F
  DEFB $30,$7F
  DEFB $30,$6F
  DEFB $30,$5F
  DEFB $30,$4F
  DEFB $30,$3F
  DEFB $50,$27

; Menu: the text
;
; Eight strings in the game's text code, without colour bytes (see
; complete_text). The option lines start with their key's digit. The last line
; uses the two glyphs beyond the letters and space: $24, a full stop, and $25,
; the copyright sign.
menu_text:
  DEFB $14,$17,$12,$10,$11,$1D,$26,$15
  DEFB $18,$1B,$8E
  DEFB $01,$26,$14,$0E,$22,$0B,$18,$0A
  DEFB $1B,$8D
  DEFB $02,$26,$14,$0E,$16,$19,$1C,$1D
  DEFB $18,$17,$26,$13,$18,$22,$1C,$1D
  DEFB $12,$0C,$94
  DEFB $03,$26,$0C,$1E,$1B,$1C,$18,$1B
  DEFB $26,$26,$26,$13,$18,$22,$1C,$1D
  DEFB $12,$0C,$94
  DEFB $04,$26,$12,$17,$1D,$0E,$1B,$0F
  DEFB $0A,$0C,$0E,$26,$12,$92
  DEFB $05,$26,$0D,$12,$1B,$0E,$0C,$1D
  DEFB $12,$18,$17,$0A,$15,$26,$0C,$18
  DEFB $17,$1D,$1B,$18,$95
  DEFB $00,$26,$1C,$1D,$0A,$1B,$1D,$26
  DEFB $10,$0A,$16,$8E
  DEFB $25,$26,$01,$09,$08,$04,$26,$0A ; Copyright line
  DEFB $24,$0C,$24,$10,$A4             ;

; Print a string in one given colour
;
; Used by the routine at display_text_list.
;
; For strings that carry no colour byte: the colour is whatever
; display_text_list left in $5BB6. Selects the standard font, works out the
; buffer address, and joins print_text where the attribute address is found.
;
; HL the position: L = x, H = y, in pixels, y counting up from the bottom
; DE the string, in the text code; on exit, the byte after it
print_text_single_colour:
  PUSH HL                 ; the standard font
  LD HL,font              ;
  LD ($5BC7),HL           ;
  POP BC                  ; BC = the position again; HL = its buffer address
  PUSH BC                 ;
  CALL calc_vidbuf_addr   ;
  LD L,C                  ;
  LD H,B                  ;
  LD A,($5BB6)            ; the colour into A'
  EX AF,AF'               ;
  JR text_attr_addr

; Print a string with its colour byte, in the standard font
;
; Used by the routine at game_over_summary.
;
; HL the position (see print_text_single_colour)
; DE the string: a colour byte, then characters in the text code
print_text_std_font:
  PUSH HL                 ; the position stays on the stack for print_text
  LD HL,font              ;
  LD ($5BC7),HL           ;

; Print a string with its colour byte
;
; Used by the routine at display_day.
;
; The game's one text printer. The position is on the stack, the font pointer
; in $5BC7 selects the glyphs, and each character is an index into that font.
; The first byte is the attribute for every cell the string covers; the
; characters follow, and bit 7 marks the last. Glyphs go into the buffer at
; screen_buffer and the colours straight into attribute memory, one cell per
; character.
;
; The position is a pixel (x, y) with y counting up from the bottom of the
; screen, the same convention as the rest of the drawing code, so a string's
; top edge is at y and it extends eight rows below.
;
; DE the string: a colour byte, then characters in the text code
print_text:
  POP BC                  ; BC = the position, left on the stack; HL = its
  PUSH BC                 ; buffer address
  CALL calc_vidbuf_addr   ;
  LD L,C                  ;
  LD H,B                  ;
  LD A,(DE)               ; the colour byte into A'
  EX AF,AF'               ;
  INC DE                  ;

; Find the attribute address for the string
;
; Used by the routine at print_text_single_colour.
;
; In the alternate registers: HL' becomes the attribute address of the first
; cell. DE' is kept, because display_text_list uses it to walk its colour list.
text_attr_addr:
  EXX
  POP HL                  ; take the position off the stack
  PUSH DE
  CALL calc_attrib_addr
  LD L,E
  LD H,D
  POP DE

; Print one character of a string
print_text_char:
  EXX
  LD A,(DE)               ; bit 7: the last character
  BIT 7,A                 ;
  JR NZ,print_text_last   ;
  PUSH DE                 ; draw it; print_8x8 leaves HL one cell to the right
  CALL print_8x8          ;
  POP DE                  ;
  INC DE                  ;
  EXX                     ; colour its cell and move one cell right
  EX AF,AF'               ;
  LD (HL),A               ;
  INC L                   ;
  EX AF,AF'               ;
  JR print_text_char

; Print the last character of a string
;
; Used by the routine at print_text_char.
print_text_last:
  AND $7F                 ; without its end marker; DE ends past the string
  PUSH DE
  CALL print_8x8
  POP DE
  INC DE
  EXX                     ; colour it and return
  EX AF,AF'               ;
  LD (HL),A               ;
  EXX                     ;
  RET                     ;

; Print one 8x8 character into the buffer
;
; Used by the routines at print_BCD_byte, print_BCD_lsd, print_text_char and
; print_text_last.
;
; The glyph is at $5BC7 plus eight times the code. Rows go downwards on the
; screen, which in the buffer is 32 bytes lower each time. Rather than keep the
; start address, it adds $0101 at the end: eight rows of -32 is -256, so +257
; lands on the next cell to the right of where it began.
;
; A the character code
; HL the buffer address of its top row; on exit, one cell to the right
print_8x8:
  PUSH BC
  PUSH DE
  PUSH HL
  LD L,A                  ; DE = the glyph
  LD H,$00                ;
  ADD HL,HL               ;
  ADD HL,HL               ;
  ADD HL,HL               ;
  LD DE,($5BC7)           ;
  ADD HL,DE               ;
  EX DE,HL                ;
  POP HL
  LD B,$08

; Copy one row of the glyph
print_8x8_row:
  LD A,(DE)
  LD (HL),A
  INC DE
  PUSH BC
  LD BC,$FFE0             ; one row down the screen
  ADD HL,BC
  POP BC
  DJNZ print_8x8_row
  POP DE                  ; -256 + 257: one cell right of the start
  LD BC,$0101             ;
  ADD HL,BC               ;
  POP BC
  RET

; Set the FLASH bit on one of a list of colours
;
; Used by the routine at flash_menu.
;
; Sets bit 7 of the Ath byte and clears it on the others.
;
; A which one to set, from 0
; B how many colours
; HL the first colour; on exit, the byte after the last
toggle_selected:
  AND A                   ; A=0: this first one is the chosen one
  JR NZ,unflash_this_one  ;

; Flash this colour
;
; Used by the routine at flash_next_one.
flash_this_one:
  SET 7,(HL)
  JR flash_list_step

; Count down to the chosen colour
;
; Used by the routine at flash_list_step.
flash_next_one:
  DEC A
  JR Z,flash_this_one

; Do not flash this colour
;
; Used by the routine at toggle_selected.
unflash_this_one:
  RES 7,(HL)

; Next colour in the list
;
; Used by the routine at flash_this_one.
flash_list_step:
  INC HL
  DJNZ flash_next_one
  RET

; Draw the menu
;
; Used by the routines at clear_menu_flash and menu_loop.
;
; Sets up display_text_list with the menu's eight colours, positions and
; strings.
display_menu:
  LD DE,menu_colours
  EXX
  LD HL,menu_xy
  LD DE,menu_text
  LD B,$08

; Print a list of strings
;
; Used by the routines at game_over_summary and game_complete_msg.
;
; Prints each string at its position in its colour. The first list printed
; after $5BB8 is cleared also draws the border and copies the buffer to the
; screen; later calls only redraw into the buffer (and write the attributes
; directly), which is how the menu can update its flashing lines every pass
; without redrawing the screen.
;
; B how many
; DE' the colours, one byte per string
; HL the positions, an (x, y) pair per string
; DE the strings, one after another, in the text code without colour bytes
display_text_list:
  EXX                     ; this string's colour, for print_text_single_colour
  LD A,(DE)               ;
  LD ($5BB6),A            ;
  INC DE                  ;
  EXX                     ;
  PUSH BC                 ; L = x, H = y; HL advanced to the next pair
  LD A,(HL)               ;
  INC HL                  ;
  INC HL                  ;
  PUSH HL                 ;
  DEC HL                  ;
  LD H,(HL)               ;
  LD L,A                  ;
  CALL print_text_single_colour
  POP HL
  POP BC
  DJNZ display_text_list
  LD A,($5BB8)            ; already shown once: leave the screen alone
  AND A                   ;
  RET NZ                  ;
  INC A                   ; first time: flag it, draw the border and show the
  LD ($5BB8),A            ; buffer
  CALL print_border       ;
  JP update_screen        ;

; Print a sprite several times in a line
;
; Used by the routines at display_panel and print_border.
;
; Used to build the border and the panel out of repeated pieces.
;
; IX an object record holding the sprite type and position
; B how many times
; E the step in x between copies
; D the step in y between copies
multiple_print_sprite:
  PUSH BC
  PUSH DE
  PUSH HL
  CALL print_sprite
  POP HL
  POP DE
  POP BC
  LD A,(IX+$1A)           ; move the record's pixel position by (E, D)
  ADD A,E
  LD (IX+$1A),A
  LD A,(IX+$1B)
  ADD A,D
  LD (IX+$1B),A
  DJNZ multiple_print_sprite
  RET

; Player appearing, frames 120 to 126
;
; When the player enters a room (or comes back after losing a life) both of the
; player's records start as type 120 with their real type saved at +$10 (see
; exit_screen and lose_life). This handler steps the type on by one every other
; frame, with a sound whose pitch follows the frame, and upd_127 finishes the
; effect.
upd_120_to_126:
  CALL adj_m4_m12         ; sprite drawing offset for this kind of object
  LD A,($5BA2)            ; only on alternate frames of the counter at $5BA2
  CPL                     ;
  AND $01                 ;
  RET NZ                  ;
  INC (IX+$00)            ; next frame of the effect, a sound, and redraw
  CALL sound_materialise
  JP set_wipe_and_draw_flags

; Player appearing, last frame
;
; Turns the record back into what it was -- the type saved at +$10 -- and runs
; that type's handler at once.
upd_127:
  CALL adj_m4_m12
  RES 6,(IX+$0D)          ; clear bit 6 of +$0D
  LD A,(IX+$10)           ; restore the saved type and dispatch on it
  LD (IX+$00),A
  JP jump_to_upd_object

; Start the sparkle an object vanishes in
;
; Used by the routines at upd_92_to_95, upd_player_bottom and upd_player_top.
;
; Turns the object in IX into type 112, the first frame of the sparkle, and
; sets bit 1 of +$07 so the collision code leaves it alone. Used by the
; player's own handlers when the player dies, and by upd_92_to_95 (types 92 to
; 95).
init_death_sparkles:
  LD (IX+$00),$70
  SET 1,(IX+$07)          ; bit 1 of +$07: no collision checks for this object
  JR sparkle_sound_and_draw

; Sparkle, frames 112 to 118 (and type 184)
;
; Used by the routine at upd_143.
;
; Advances the type by one every frame, with a noise burst that gets shorter as
; the frames go on. Type 119 (upd_119) ends it. Type 184 comes here too and
; steps to 185 (upd_185_187), which removes the object from the special-object
; table as it vanishes.
upd_112_to_118_184:
  CALL adj_m4_m12
  INC (IX+$00)

; Sparkle sound and redraw
;
; Used by the routine at init_death_sparkles.
sparkle_sound_and_draw:
  CALL sound_sparkle      ; noise burst; its length depends on the type
  JP set_wipe_and_draw_flags

; Vanish and leave the special-object table
;
; For types 185 and 187: clears the type byte of the object's entry in the
; table at special_objs_tbl (its address is at +$10 and +$11), so the object is
; gone for good, then vanishes as upd_119 does.
upd_185_187:
  LD L,(IX+$10)
  LD H,(IX+$11)
  LD (HL),$00

; Sparkle, last frame: vanish
;
; Hands over to upd_111, which makes the record type 1 -- an empty placeholder
; that is wiped from the screen and then does nothing.
upd_119:
  CALL adj_m4_m12
  JP upd_111

; Redraw the carried objects if they changed
;
; Used by the routine at draw_and_copy_rects.
;
; Called every frame; does the work only when $5BB4 has been set by a pick-up
; or a drop, and clears it.
display_objects_carried:
  LD A,($5BB4)
  AND A
  RET Z
  XOR A
  LD ($5BB4),A

; Draw the three carried objects on the panel
;
; Used by the routine at no_delay.
;
; The inventory is four 4-byte slots from $5BD8 (see pickup_object); the first
; is only a staging slot, so the three shown are the ones at $5BDC, $5BE0 and
; $5BE4, drawn left to right at x = 16, 40 and 64 along the bottom of the
; screen. The rightmost is the one the next drop will put down.
display_objects:
  PUSH IX                 ; the scratch record at sprite_scratchpad, three
  LD IX,sprite_scratchpad ; slots from $5BDC
  LD B,$03                ;
  LD HL,$5BDC             ;

; Draw one carried object
;
; Used by the routine at show_carried_slot.
;
; Clears a box three cells wide and 24 rows high in the buffer, draws the
; object's sprite in it if the slot is not empty, copies the box to the screen
; and colours its nine cells from object_attributes.
display_object:
  PUSH BC
  PUSH HL
  LD A,B                  ; x = 24 x (slot number) + 16, y = 0
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
  LD (IX+$1B),$00         ;
  LD C,(IX+$1A)           ; blank the box in the buffer
  LD B,(IX+$1B)
  PUSH HL
  CALL calc_vidbuf_addr
  LD L,C
  LD H,B
  LD BC,$0318
  XOR A
  CALL fill_window
  POP HL
  LD A,(HL)               ; an empty slot has type 0: nothing to draw
  AND A                   ;
  JR Z,show_carried_slot  ;
  LD (IX+$00),A           ;
  CALL print_sprite       ;

; Show one carried object and colour it
;
; Used by the routine at display_object.
show_carried_slot:
  LD C,(IX+$1A)           ; copy the 3 x 24 box from the buffer to the screen
  LD B,(IX+$1B)
  CALL calc_vram_addr
  CALL calc_vidbuf_addr
  LD L,C
  LD H,B
  LD BC,$1803
  CALL blit_to_screen
  POP HL
  POP BC
  PUSH BC
  PUSH HL
  LD A,(HL)               ; the colour for this type, from the table at
  AND $0F                 ; object_attributes
  LD E,A                  ;
  LD D,$00                ;
  LD HL,object_attributes ;
  ADD HL,DE               ;
  LD C,(HL)               ;
  LD L,(IX+$1A)           ; 3 x 3 attribute cells, from the top of the box
  LD A,(IX+$1B)
  ADD A,$17
  LD H,A
  CALL calc_attrib_addr
  EX DE,HL
  LD A,C
  LD BC,$0303
  CALL fill_window
  POP HL
  POP BC
  INC HL                  ; next 4-byte slot
  INC HL                  ;
  INC HL                  ;
  INC HL                  ;
  DJNZ display_object     ;
  POP IX
  RET

; Colours of the carried objects
;
; Eight attribute bytes indexed by the object type AND $0F. The things that can
; be carried are types $60 to $66, so entries 0 to 6 are the seven kinds of
; charm; entry 0 also colours an empty slot, which has nothing to show.
object_attributes:
  DEFB $42,$43,$44,$45,$46,$47,$42,$47

; Scratch object record for the panel
;
; A 32-byte object record, laid out like those in the object table, that the
; panel code fills in to draw a sprite on its own: type at +$00, the flip flags
; at +$07, the pixel position at +$1A (x) and +$1B (y). print_sprite writes the
; drawn width and height back to +$18 and +$19. Used for the border, the panel,
; the lives icon and the carried objects.
sprite_scratchpad:
  DEFB $8A,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $03,$01,$E8,$A0,$00,$00,$00,$00

; Is the pick-up/drop control pressed?
;
; Used by the routines at handle_pickup_drop, try_pickup_loop and
; wait_pickup_release.
;
; The input bits in $5BB5 have pick-up/drop in bit 4 for every control method.
; With a joystick and directional control, though, the stick's down direction
; is a direction rather than pick-up, so bit 5 -- set by keys on the keyboard
; -- is used instead.
;
; F on exit, Z clear if it is pressed
chk_pickup_drop:
  LD HL,$5BA4             ; joystick (method not 0)...
  LD A,(HL)
  AND $06
  LD A,($5BB5)
  JR Z,test_pickup_bit
  BIT 3,(HL)              ; ...and directional control: use bit 5
  JR Z,test_pickup_bit    ;
  RRCA                    ;

; Test the pick-up bit
;
; Used by the routine at chk_pickup_drop.
test_pickup_bit:
  AND $10
  RET

; Pick up or drop an object
;
; Used by the routine at player_controls.
;
; Called from the player's handler with IX on the player's lower record at
; $5C08. One press does one thing: pick up a charm the player is on or beside
; if there is one; otherwise put down the oldest charm carried. $5BB3 latches
; the press so holding the key down does nothing more.
;
; Nothing happens unless the player is inside the room (not in an arch), not
; jumping, and standing on something. It also checks whether there is an object
; within 12 units above the player's head; if so, $5BD3 is set and a drop is
; refused, because a drop lifts the player 12 units onto the dropped object.
handle_pickup_drop:
  LD A,($5BB3)            ; still held from the last press: wait for release
  AND A
  JP NZ,wait_pickup_release
  CALL chk_pickup_drop
  RET Z
  CALL chk_plyr_OOB       ; only inside the room's walls
  RET NC
  BIT 3,(IX+$0C)          ; not while jumping (+$0C bit 3), only when standing
                          ; on something (bit 2)
  RET NZ
  BIT 2,(IX+$0C)
  RET Z
  XOR A                      ; anything within 12 units above? The player's z
  LD ($5BD3),A               ; is raised to look, then put back
  LD A,(IX+$03)              ;
  LD B,A                     ;
  ADD A,$0C                  ;
  LD (IX+$03),A              ;
  CALL do_any_objs_intersect ;
  LD (IX+$03),B              ;
  JR NC,start_pickup_drop    ;
  LD A,$01                ; yes: there is no room to stand on a dropped object
  LD ($5BD3),A

; Look for a charm to pick up
;
; Used by the routine at handle_pickup_drop.
;
; Clicks, latches the key, flags the panel for redraw, and enlarges the
; player's box by 4 in each dimension -- the old sizes go on the stack for
; done_pickup_drop -- so that a charm just out of reach still counts. The
; special objects in a room are always in the two records at $5C48 and $5C68.
start_pickup_drop:
  CALL toggle_audio_hw_x16
  LD A,$01
  LD ($5BB3),A
  LD ($5BB4),A
  LD B,$02
  LD L,(IX+$04)           ; width, depth and height +4 each; the originals are
                          ; pushed
  LD A,L
  ADD A,$04
  LD (IX+$04),A
  LD H,(IX+$05)
  LD A,H
  ADD A,$04
  LD (IX+$05),A
  PUSH HL
  LD L,(IX+$06)
  LD A,L
  ADD A,$04
  LD (IX+$06),A
  PUSH HL
  LD IY,$5C48             ; the first special-object record

; Try each special-object record
try_pickup_loop:
  CALL can_pickup_spec_obj ; a charm, and touching the player: take it
  JP C,pickup_object
  LD DE,$0020             ; next record
  ADD IY,DE
  DJNZ try_pickup_loop
  CALL chk_pickup_drop    ; this can only be non-zero here: $5BB5 has not
  JR Z,done_pickup_drop   ; changed since the first test
  LD B,$02                ; room for two special objects, but only one in the
  LD A,(IX+$08)           ; wizard's room, $88, where the second record is the
  CP $88                  ; cauldron's bubbles
  JR NZ,find_free_record  ;
  LD B,$01                ;

; Nothing to pick up: find a free record to drop into
;
; Used by the routine at try_pickup_loop.
find_free_record:
  LD IY,$5C48
  LD DE,$0020

; Is this record free?
find_free_record_loop:
  LD A,(IY+$00)           ; type 0 is free
  AND A
  JR Z,room_to_drop
  ADD IY,DE                  ; none free: the room already has its quota; drop
  DJNZ find_free_record_loop ; nothing

; Pick-up or drop done
;
; Used by the routines at try_pickup_loop, room_to_drop and adjust_carried.
;
; Puts back the player's width, depth and height saved by start_pickup_drop.
done_pickup_drop:
  POP HL
  LD (IX+$06),L
  POP HL
  LD (IX+$04),L
  LD (IX+$05),H
  RET

; Wait for the pick-up key to be released
;
; Used by the routine at handle_pickup_drop.
wait_pickup_release:
  CALL chk_pickup_drop    ; clear the latch once it is up
  RET NZ
  XOR A
  LD ($5BB3),A
  RET

; Drop the oldest charm carried
;
; Used by the routine at find_free_record_loop.
;
; IY is a free special-object record. The charm dropped is the one in the last
; slot, $5BE4. If that slot is empty the slots are shifted along anyway, which
; brings the next charm into the dropping position.
;
; In the wizard's room, with the player standing high (z of $98 or more, which
; in that room means standing on the cauldron -- inferred from the height), the
; charm becomes type $68 to $6E instead of $60 to $66, which upd_104_to_110
; carries into the cauldron, and $5BC4 is set to lock out the controls until it
; arrives.
room_to_drop:
  LD HL,$5BE4             ; last slot empty: just move the slots along
  LD A,(HL)               ;
  INC HL                  ;
  AND A                   ;
  JR Z,adjust_carried     ;
  LD A,($5BD3)            ; something above the player's head: no drop
  AND A                   ;
  JR NZ,done_pickup_drop  ;
  DEC HL                  ; the charm's type into the free record
  LD A,(HL)               ;
  INC HL                  ;
  LD (IY+$00),A           ;
  LD A,(IX+$08)           ; in the wizard's room and high up?
  CP $88
  JR NZ,place_under_player
  LD A,(IX+$03)
  CP $98
  JR C,place_under_player
  SET 3,(IY+$00)          ; yes: into the cauldron, and freeze the player's
                          ; controls
  LD A,$01
  LD ($5BC4),A

; Put the charm under the player
;
; Used by the routine at room_to_drop.
;
; The charm takes the player's x, y and z, and the player -- both records, at
; $5C08 and $5C28 -- goes up 12 units, the height of a charm, so the player
; ends up standing on it. This is how charms can be stacked into steps.
place_under_player:
  PUSH HL                 ; HL = $5BE5: the rest of the slot, for drop_object
  LD BC,$0003             ; copy x, y, z from the player to the charm
  PUSH IX
  POP HL
  PUSH IY
  POP DE
  INC DE
  INC HL
  LDIR
  LD A,(IX+$03)           ; lift both of the player's records by 12
  ADD A,$0C
  LD (IX+$03),A
  LD A,(IX+$23)
  ADD A,$0C
  LD (IX+$23),A
  PUSH IX                 ; the charm's screen position
  PUSH IY                 ;
  POP IX                  ;
  CALL calc_pixel_XY      ;
  POP IX                  ;

; Fill in a dropped charm's record
;
; Used by the routine at pickup_object.
;
; The size is 5 x 5 x 12; the flags byte and the address of its entry in
; special_objs_tbl come back from the carried slot; the room is the player's.
; Bit 0 of +$0D tells upd_96_to_102 it has just been put down.
;
; IY the record, its type and position already set
drop_object:
  LD (IY+$04),$05         ; width, depth, height
  LD (IY+$05),$05
  LD (IY+$06),$0C
  POP HL                  ; +$07 flags from the slot
  LD A,(HL)               ;
  INC HL                  ;
  LD (IY+$07),A           ;
  LD A,(IX+$08)           ; the room: the player's
  LD (IY+$08),A
  LD A,(HL)               ; +$10: its entry in the special-object table
  INC HL                  ;
  LD (IY+$10),A           ;
  LD A,(HL)               ;
  LD (IY+$11),A           ;
  SET 0,(IY+$0D)          ; just dropped

; Shift the carried slots along
;
; Used by the routines at room_to_drop and pickup_object.
;
; Moves slots 0 to 2 ($5BD8 to $5BE3) up one to slots 1 to 3 and empties slot
; 0. Whatever was in slot 3 has already been put down, so the carried objects
; behave as a queue: first picked up, first dropped.
adjust_carried:
  LD HL,$5BE3             ; 12 bytes up by 4, copied from the top down so they
                          ; do not overwrite themselves
  LD DE,$5BE7
  LD BC,$000C
  LDDR
  LD DE,$5BD8             ; slot 0 is now free
  LD B,$04                ;
  CALL zero_DE
  JP done_pickup_drop

; Pick up a charm
;
; Used by the routine at try_pickup_loop.
;
; Copies the charm into the staging slot at $5BD8 -- type, flags, and the
; address of its entry in special_objs_tbl, whose type byte is then zeroed so
; the charm will not be put back in its room when the player leaves. The record
; becomes type 1 and is wiped from the screen.
;
; If three charms are already carried, the oldest is dropped where the new one
; was, using the same record: picking up swaps.
;
; A carried slot is four bytes: +0 the type ($60 to $66), +1 the flags byte
; from +$07, +2 and +3 the address of the charm's entry in the special-object
; table.
;
; IY the charm's record
pickup_object:
  LD HL,$5BD8
  XOR A                   ; clear $5BC0
  LD ($5BC0),A            ;
  LD A,(IY+$00)           ; type, flags and table pointer into slot 0; zero the
                          ; table entry's type
  LD (HL),A
  INC HL
  LD A,(IY+$07)
  LD (HL),A
  INC HL
  LD E,(IY+$10)
  LD D,(IY+$11)
  XOR A
  LD (DE),A
  LD (HL),E
  INC HL
  LD (HL),D
  CALL set_wipe_and_draw_IY
  LD (IY+$00),$01
  LD HL,$5BE4             ; carrying fewer than three: just shift the slots
  LD A,(HL)
  INC HL
  AND A
  JR Z,adjust_carried
  LD (IY+$00),A           ; otherwise the oldest takes the new one's place
  PUSH HL                 ;
  JR drop_object          ;

; Can this special object be picked up?
;
; Used by the routine at try_pickup_loop.
;
; Only types $60 to $66, the seven kinds of charm, and only when the player
; (IX) is on or beside it. $67, the extra life, is not picked up but collected
; by touching (upd_103).
;
; IY the object
; F on exit, carry set if it can
can_pickup_spec_obj:
  LD A,(IY+$00)
  SUB $60
  CP $07
  RET NC

; Is the player on or next to this object?
;
; Used by the routine at upd_103.
;
; Lowering the player by 4 makes an object the player stands on count as
; touching.
;
; IX the player
; IY the object
; F on exit, carry set if their boxes overlap in x and y, and in z with the
;   player lowered by 4
is_on_or_near_obj:
  PUSH BC
  LD BC,$0000
  LD L,C
  LD H,C
  CALL do_objs_intersect_on_x
  JR NC,near_obj_done
  CALL do_objs_intersect_on_y
  JR NC,near_obj_done
  LD A,(IX+$03)           ; z test with the player 4 units lower, then put back
  SUB $04
  LD (IX+$03),A
  CALL do_objs_intersect_on_z
  PUSH AF
  LD A,(IX+$03)
  ADD A,$04
  LD (IX+$03),A
  POP AF

; Result of the touch test
;
; Used by the routine at is_on_or_near_obj.
near_obj_done:
  POP BC
  RET

; Is the object moving?
;
; Used by the routines at upd_96_to_102, upd_85 and
; dec_dZ_upd_XYZ_wipe_if_moving.
;
; IX the object
; F on exit, Z set if its dX, dY and dZ (+$09 to +$0B) are all zero
is_obj_moving:
  LD A,(IX+$09)
  OR (IX+$0A)
  OR (IX+$0B)
  RET

; Special object $67: the extra life
;
; Tests whether the player touches it, with the player's box widened by 1 in x
; and y. If so the object changes to type $6F (upd_111, vanish), its entry in
; the special-object table is cleared so it never comes back, and the lives
; count at $5BBA goes up by one, is reprinted and copied to the screen.
upd_103:
  CALL upd_128_to_130
  PUSH IX                 ; test against the player at $5C08, widened by 1 in x
  POP IY                  ; and y
  LD IX,$5C08             ;
  INC (IX+$04)            ;
  INC (IX+$05)            ;
  CALL is_on_or_near_obj  ;
  DEC (IX+$04)            ;
  DEC (IX+$05)            ;
  PUSH IY                 ;
  POP IX                  ;
  JR NC,extra_life_fall
  SET 3,(IX+$00)          ; set bit 3: type $6F
  CALL adj_m4_m12
  LD L,(IX+$10)           ; gone from the table for good
  LD H,(IX+$11)           ;
  LD (HL),$00             ;
  LD HL,$5BBA             ; one more life
  INC (HL)                ;
  XOR A                   ; clear $5BC0
  LD ($5BC0),A            ;
  CALL toggle_audio_hw_x16 ; click, print and show the new count
  CALL print_lives         ;
  LD BC,$2020              ;
  CALL blit_2x8            ;

; Fall and settle like any other object
;
; Used by the routine at upd_103.
extra_life_fall:
  JP dec_dZ_upd_XYZ_wipe_if_moving

; A charm on its way into the cauldron, types $68 to $6E
;
; A charm dropped from high up in the wizard's room (room_to_drop) becomes one
; of these. Each frame it moves one unit in x and one in y towards the centre
; of the room, $80,$80, and rises to a height of $98; once over the centre it
; falls straight down into the cauldron (centre_of_room).
upd_104_to_110:
  CALL adj_m4_m12
  LD A,(IX+$01)           ; dX = +1, -1 or 0 towards x = $80
  SUB $80
  JR Z,steer_to_centre_y
  LD A,$01
  JP M,steer_to_centre_y
  NEG

; Steer towards the centre in y
;
; Used by the routine at upd_104_to_110.
steer_to_centre_y:
  LD (IX+$09),A
  LD A,(IX+$02)           ; dY = +1, -1 or 0 towards y = $80
  SUB $80
  JR Z,check_over_centre
  LD A,$01
  JP M,check_over_centre
  NEG

; Over the centre yet?
;
; Used by the routine at steer_to_centre_y.
check_over_centre:
  LD (IX+$0A),A
  LD A,(IX+$01)           ; x = $80 and y = $80: go down
  CP $80
  JR NZ,rise_over_cauldron
  XOR (IX+$02)
  JR Z,centre_of_room

; Rise to a height of $98
;
; Used by the routine at check_over_centre.
rise_over_cauldron:
  LD A,(IX+$03)           ; dZ = 2 below $98, 1 from there up; gravity takes
  CP $98                  ; one off each frame
  LD A,$01                ;
  JR NC,store_rise_speed  ;
  INC A

; Set the vertical speed
;
; Used by the routine at rise_over_cauldron.
store_rise_speed:
  LD (IX+$0B),A

; Move it
;
; Used by the routine at centre_of_room.
move_charm_to_cauldron:
  CALL dec_dZ_and_update_XYZ

; Click and redraw
;
; Used by the routines at sound_wipe_and_draw, settle_charm, upd_85 and
; dec_dZ_upd_XYZ_wipe_if_moving.
;
; A short click whose pitch depends on the object's position
; (sound_pitch_from_xyz), then flags the object to be wiped and redrawn.
click_wipe_and_draw:
  CALL sound_pitch_from_xyz
  JP set_wipe_and_draw_flags

; Over the centre: fall into the cauldron
;
; Used by the routine at check_over_centre.
;
; Keeps falling, with collisions switched off so the charm drops through the
; cauldron's top, until z is down to $80.
centre_of_room:
  LD A,$80                ; reached $80?
  CP (IX+$03)
  JR NC,add_obj_to_cauldron
  SET 1,(IX+$07)          ; bit 1 of +$07: no collision checks this frame
  JR move_charm_to_cauldron

; A charm lands in the cauldron
;
; Used by the routine at centre_of_room.
;
; If the charm's kind (type AND 7) is the one the wizard wants next, the count
; at $5BBB goes up and the screen's colours cycle; the fourteenth starts the
; ending. Either way the charm is used up: its entry in the special-object
; table is cleared and it vanishes. So the wrong charm is not given back -- it
; is lost.
add_obj_to_cauldron:
  LD (IX+$03),$80
  CALL ret_next_obj_required ; the kind wanted next, from objects_required
  LD A,(IX+$00)              ;
  AND $07                    ;
  CP (HL)                    ;
  JR NZ,cauldron_consume     ;
  LD HL,$5BBB                   ; right one: count it and flash the screen
  INC (HL)                      ;
  CALL cycle_colours_with_sound ;
  LD A,($5BBB)                 ; fourteen: the quest is done
  CP $0E                       ;
  JR NZ,cauldron_consume       ;
  CALL prepare_final_animation ;

; Use the charm up
;
; Used by the routine at add_obj_to_cauldron.
cauldron_consume:
  XOR A                   ; give the player back the controls
  LD ($5BC4),A            ;
  LD L,(IX+$10)           ; gone from the special-object table
  LD H,(IX+$11)           ;
  LD (HL),$00             ;
  JP upd_111              ; and from the room

; Which charm the wizard wants next
;
; Used by the routines at upd_160_to_163 and add_obj_to_cauldron.
;
; Also used by the cauldron's bubbles (upd_160_to_163) to show the next charm
; wanted above the cauldron.
;
; HL on exit, the address of the entry in objects_required for the count in
;    $5BBB
ret_next_obj_required:
  LD A,($5BBB)
  LD HL,objects_required
  JP add_HL_A

; The charms the wizard wants, in order
;
; Fourteen kinds, 0 to 6 (the charm's type AND 7), each appearing twice.
; shuffle_objects_required rotates the list left by 4 to 7 places at the start
; of a game, choosing by the seed at $5BA0. The list is rotated in place and
; never put back, so the first game after loading can ask for only four orders,
; and later games rotate on from wherever the last one left it. Every game
; wants the same fourteen, two of each kind; only the order changes.
; ret_next_obj_required indexes it by the number already added.
objects_required:
  DEFB $00,$01,$02,$03,$04,$05,$06 ; First seven as stored
  DEFB $03,$05,$00,$06,$01,$02,$04 ; Second seven as stored

; Special objects $60 to $66: a charm lying in a room
;
; Falls under gravity and comes to rest. When it has just been put down (bit 0
; of +$0D, set by drop_object) or has moved, its horizontal speed is stopped
; and it is redrawn with a click.
upd_96_to_102:
  CALL adj_m4_m12
  CALL dec_dZ_and_update_XYZ
  BIT 0,(IX+$0D)          ; just dropped, or moving: stop it
  JR NZ,settle_charm
  CALL is_obj_moving
  RET Z

; Stop the charm and redraw it
;
; Used by the routine at upd_96_to_102.
settle_charm:
  RES 0,(IX+$0D)          ; clear the just-dropped flag and dX, dY; click and
  CALL clear_dX_dY        ; redraw
  JP click_wipe_and_draw  ;

; Cycle the screen's colours with a sound
;
; Used by the routine at add_obj_to_cauldron.
;
; Sixteen times: steps the ink of every attribute cell on by one (paper, BRIGHT
; and FLASH kept), makes a noise burst and waits briefly. The effect a correct
; charm makes in the cauldron.
cycle_colours_with_sound:
  LD D,$10                ; sixteen passes

; One pass over the attributes
;
; Used by the routine at cycle_colours_pause.
cycle_colours_pass:
  LD HL,$5800             ; all 768 cells
  LD BC,$0300

; Step one cell's ink
cycle_attribute_mem:
  LD A,(HL)               ; ink + 1 mod 8, the rest unchanged
  AND $F8                 ;
  LD E,A                  ;
  LD A,(HL)               ;
  INC A                   ;
  AND $07                 ;
  OR E                    ;
  LD (HL),A               ;
  INC HL
  DEC BC
  LD A,B
  OR C
  JR NZ,cycle_attribute_mem
  CALL sound_sparkle      ; noise burst, sized by the charm's type
  LD BC,$2000             ; a short pause

; Pause between passes
cycle_colours_pause:
  DEC BC
  LD A,B
  OR C
  JR NZ,cycle_colours_pause
  DEC D
  JR NZ,cycle_colours_pass

; Handler that does nothing
;
; The handler for the object types that stay still and need no update.
no_update:
  RET

; Start the final animation
;
; Used by the routine at add_obj_to_cauldron.
;
; Called by add_obj_to_cauldron when the fourteenth object has gone into the
; cauldron. It sets the game-complete flag at $5BC3, which from now on stops
; the sun and moon (display_sun_moon_frame) and with them any further
; transformation, the player's input (check_user_input) and death. Then it
; clears the room for the ending: object records 3 to 13 are marked for erasing
; and given type 1, which the renderer turns into an empty record once the old
; image has been wiped (see calc_pixel_XY_and_render), and every plain stone
; block (type 7) further up the table becomes type 131, whose handler
; (upd_131_to_133) lifts it into the air.
;
; IX the object that has just reached the cauldron (preserved)
prepare_final_animation:
  LD A,$01                ; the game is complete
  LD ($5BC3),A            ;
  PUSH IX
  LD IX,$5C68             ; from record 3 at $5C68, eleven records of 32 bytes
  LD DE,$0020
  LD B,$0B
; Which things records 3 to 13 hold in the wizard's room depends on the room
; data and has not been worked out record by record.

; Erase the next of records 3 to 13
;
; One pass of the loop in prepare_final_animation: flag the record's image to
; be wiped and set its type to 1 so that it is freed once the wipe has
; happened.
final_clear_loop:
  PUSH BC                      ; wipe and redraw it (and whatever it overlaps)
  PUSH DE                      ;
  CALL set_wipe_and_draw_flags ;
  POP DE                       ;
  POP BC                       ;
  LD (IX+$00),$01         ; type 1: erase, then free
  ADD IX,DE
  DJNZ final_clear_loop
  LD BC,font              ; the end of the object table, for the scan that
                          ; follows

; Turn a stone block into a rising block
;
; Used by the routine at final_next_record.
;
; The second loop of prepare_final_animation walks the rest of the object
; table, from record 14 to the end, and turns every plain block (type 7, the
; first entry of the block types at block_type_tbl) into type 131.
blocks_to_rising:
  LD A,(IX+$00)           ; a plain block?
  CP $07
  JR NZ,final_next_record
  LD (IX+$00),$83         ; type 131: rises

; Next record in the stone-block scan
;
; Used by the routine at blocks_to_rising.
;
; Steps IX on by 32 and loops while it is below the font at font, the end of
; the object table. Then IX is restored for the caller.
final_next_record:
  ADD IX,DE
  PUSH IX                 ; IX less the font's address, font, without
  POP HL                  ; disturbing IX
  AND A                   ;
  SBC HL,BC               ;
  JR C,blocks_to_rising   ;
  POP IX                  ; back to the object that reached the cauldron
  RET

; Start the transformation if one is due
;
; Used by the routine at player_controls.
;
; The first thing the player's handler (player_controls) does each frame. The
; variable at $5BB1 is set to 1 by toggle_day_night at every sunrise and
; sunset; if it is set, and the player is neither in the settling time just
; after entering a room (the top nibble of +$0C) nor in the middle of a jump
; (bit 3 of +$0C), the change from knight to werewolf or back begins now.
;
; Starting it replaces the rest of the player's frame: the two INC SPs throw
; away the return address into player_controls, so the final RET of
; rand_legs_sprite returns straight to the object loop and the player neither
; reads the keys nor moves. $5BB1 now holds the player's type, which is how the
; end of the transformation (finish_transform) knows which way to change. The
; top half of the player is erased; the bottom half becomes one of the spinning
; transformation sprites, types 92 to 95, handled from now on by upd_92_to_95.
;
; IX the player's bottom (legs) record, $5C08
chk_and_init_transform:
  LD A,($5BB1)            ; no transformation pending
  AND A                   ;
  RET Z                   ;
  LD A,(IX+$0C)           ; still settling into a new room
  AND $F0                 ;
  RET NZ                  ;
  BIT 3,(IX+$0C)          ; in mid-jump
  RET NZ                  ;
  INC SP                  ; drop the return into the player handler
  INC SP                  ;
  LD A,(IX+$00)           ; remember the knight or werewolf type
  LD ($5BB1),A
  LD (IX+$10),$08         ; +$10 counts eight steps of four frames each
  PUSH IX                 ; the top half: type 1, erase and free
  LD DE,$0020             ;
  ADD IX,DE               ;
  LD (IX+$00),$01         ;
  CALL set_wipe_and_draw_flags ; and draw that
  POP IX                       ;
  CALL upd_11             ; the transformation sprite's drawing offset, and the
  JR rand_legs_sprite     ; first sprite

; The transformation in progress (types 92 to 95)
;
; The handler for the player's bottom record while it is changing. The player
; can still be killed during the change: if bit 6 of +$0D says something deadly
; has touched it, and the game is not complete, the death sparkles start.
;
; IX the player's bottom record
upd_92_to_95:
  CALL upd_11             ; draw 12 pixels left and 2 down
  BIT 6,(IX+$0D)          ; touched by something deadly?
  JR Z,transform_step     ;
  LD A,($5BC3)            ; not once the game is complete
  AND A                   ;
  JR NZ,transform_step    ;
  JP init_death_sparkles  ; die

; One step of the transformation
;
; Used by the routine at upd_92_to_95.
;
; Every fourth frame: a sound, a step off the counter at +$10, and either the
; end of the transformation (finish_transform) or a new random sprite
; (rand_legs_sprite). Eight steps, so the change takes 32 frames.
transform_step:
  LD A,($5BA2)            ; only on every fourth frame
  AND $03
  RET NZ
  CALL sound_transform    ; a sound that depends on which sprite is showing
  DEC (IX+$10)            ; the last step?
  JR Z,finish_transform

; Show a random transformation sprite
;
; Used by the routine at chk_and_init_transform.
;
; Picks one of the four transformation sprites (types 92 to 95) at random,
; never the one already showing, so the figure always changes.
;
; IX the player's bottom record
rand_legs_sprite:
  LD A,R                  ; the refresh register plus the random seed
  LD C,A                  ;
  LD A,($5BA5)            ;
  ADD A,C                 ;
  AND $03                 ; 92 to 95
  OR $5C                  ;
  CP (IX+$00)             ; if it is the current one, take its neighbour
  JR NZ,set_transform_sprite
  XOR $01

; Set the transformation sprite
;
; Used by the routine at rand_legs_sprite.
;
; Stores the new type and mirrors the sprite each time, which makes the figure
; appear to spin.
set_transform_sprite:
  LD (IX+$00),A           ; the new sprite
  LD A,(IX+$07)           ; flip it left for right
  XOR $40                 ;
  LD (IX+$07),A           ;
  JP set_wipe_and_draw_flags ; draw it

; End the transformation
;
; Used by the routine at transform_step.
;
; Flips bit 5 of the saved type, which swaps a knight's legs (types 16 to 29)
; for the matching werewolf's (48 to 61) or back, and puts the top half back as
; that type plus 16. $5BB1 is cleared, so nothing is pending until the next
; sunrise or sunset.
;
; The drawing offset is set here too, one pixel lower for the werewolf, which
; is what the new type's own handler (upd_16_to_21_24_to_29 or
; upd_48_to_53_56_to_61) will set on the next frame anyway; setting it now
; keeps the first frame in the right place.
;
; IX the player's bottom record
finish_transform:
  LD A,($5BB1)            ; knight to werewolf or werewolf to knight
  XOR $20
  LD (IX+$00),A
  ADD A,$10               ; the top half is the bottom's type plus 16
  LD (IX+$20),A
  XOR A                   ; no transformation pending
  LD ($5BB1),A            ;
  CALL adj_m6_m12         ; X -12, Y -6: the knight's legs
  BIT 5,(IX+$00)           ; Y -7 for the werewolf's
  JR Z,transform_done_draw ;
  DEC (IX+$13)             ;

; Draw the finished player
;
; Used by the routine at finish_transform.
;
; Flags the player for redrawing in its new form.
transform_done_draw:
  JP set_wipe_and_draw_flags

; Move the sun or moon on
;
; Used by the routine at draw_and_copy_rects.
;
; Called by the renderer (draw_and_copy_rects) as it finishes a frame; every
; eighth frame it moves the sun or moon one pixel to the right across its
; window in the bottom right of the screen and redraws the window. The object
; doing the moving is the 32-byte record at sun_moon_scratchpad, laid out like
; an entry in the object table.
print_sun_moon:
  LD A,($5BA2)            ; every eighth frame
  AND $07                 ;
  RET NZ                  ;
  LD IX,sun_moon_scratchpad ; one pixel right (+$1A is the pixel X)
  INC (IX+$1A)              ;

; Place the sun or moon, and redraw its window
;
; Used by the routine at no_delay.
;
; Once the sun or moon reaches pixel X 225 its half of the day is over and
; toggle_day_night swaps them. Before that, its height comes from the arc at
; sun_moon_yoff, one entry for every four pixels across: it climbs, levels off
; and sinks. Also called directly from no_delay when a room is entered, to draw
; the window afresh.
;
; IX sun_moon_scratchpad
display_sun_moon_frame:
  LD A,($5BC3)            ; the sun stops once the game is complete
  AND A
  RET NZ
  LD A,(IX+$1A)           ; reached the right-hand edge?
  CP $E1
  JR Z,toggle_day_night
  LD A,(IX+$1A)           ; height = the table entry for ((X + 16) / 4) mod 16;
                          ; X runs 176 to 224, so the index runs 0 to 12
  ADD A,$10
  LD HL,sun_moon_yoff
  RRCA
  RRCA
  AND $0F
  CALL add_HL_A
  LD A,(HL)
  LD (IX+$1B),A

; Draw the sun and moon window
;
; Used by the routine at inc_days.
;
; Builds the window in the screen buffer and copies it to the screen: a patch
; 48 pixels wide and 31 high in the bottom right corner, cleared, the sun or
; moon drawn at its current position, and the two halves of the window frame
; (types 90 and 186) drawn over it using the scratch record at
; sprite_scratchpad. Because the frame is drawn last, the sun or moon rises
; from behind its left side and sets behind its right.
;
; IX sun_moon_scratchpad
display_frame:
  LD BC,$1F06             ; clear 6 bytes by 31 rows of the buffer, from column
                          ; 23 of the bottom row
  LD HL,$D90A
  PUSH BC
  PUSH HL
  LD A,C
  LD C,B
  LD B,A
  XOR A
  CALL fill_window
  CALL print_sprite       ; the sun or moon
  LD IX,sprite_scratchpad ; the frame's left half, type 90, at pixel (184, 0)
  LD (IX+$07),$00         ;
  LD (IX+$00),$5A         ;
  LD (IX+$1A),$B8         ;
  LD (IX+$1B),$00         ;
  CALL print_sprite       ;
  LD (IX+$1A),$D0         ; and its right half, type 186, at (208, 0)
  LD (IX+$00),$BA
  CALL print_sprite
  POP HL                  ; copy the 31 rows to the screen, upwards from the
  POP BC                  ; bottom line
  LD DE,$57F7             ;
  JP blit_to_screen       ;

; Swap the sun and moon
;
; Used by the routine at display_sun_moon_frame.
;
; The end of a day or a night. Type 88 is the sun and type 89 the moon;
; flipping bit 0 swaps them, recolours the window (colour_sun_moon) and starts
; the new one at the left again. Setting $5BB1 to 1 asks the player's handler
; to transform (chk_and_init_transform): knight by day, werewolf by night. When
; the moon has just given way to the sun a new day has begun, and inc_days
; counts it.
;
; IX sun_moon_scratchpad
toggle_day_night:
  LD A,(IX+$00)           ; sun to moon or moon to sun
  XOR $01
  LD (IX+$00),A
  CALL colour_sun_moon    ; yellow for the sun, white for the moon
  LD (IX+$1A),$B0         ; back to the left of the window
  LD A,$01                ; the player must transform
  LD ($5BB1),A            ;
  LD A,(sun_moon_scratchpad) ; moon: nothing more to do
  AND $01                    ;
  RET NZ                     ;

; A new day
;
; Adds one to the day count at $5BB9, which is kept in binary-coded decimal for
; printing. Reaching day 40 ends the game (game_over); otherwise the new number
; is printed and copied to the screen, and the sun's window redrawn.
inc_days:
  LD HL,$5BB9             ; days + 1, in BCD
  LD A,(HL)               ;
  ADD A,$01               ;
  DAA                     ;
  LD (HL),A               ;
  CP $40                  ; forty days: game over
  JP Z,game_over          ;
  CALL print_days         ; copy the 16 by 8 pixel patch holding the number, at
  LD BC,$0078             ; pixel (120, 0), to the screen
  CALL blit_2x8           ;
  JP display_frame        ; redraw the window with the new sun

; Copy a 16 by 8 pixel patch from the buffer to the screen
;
; Used by the routines at upd_103 and inc_days.
;
; Converts the pixel position into a screen address (calc_vram_addr) and an
; address in the buffer (calc_vidbuf_addr), then copies 8 rows of 2 bytes. Used
; for the day count and the lives count, which change without the whole screen
; being redrawn.
;
; B the pixel row, counted from the bottom of the screen
; C the pixel column
blit_2x8:
  CALL calc_vram_addr
  CALL calc_vidbuf_addr
  LD L,C
  LD H,B
  LD BC,$0802             ; 8 rows of 2 bytes
  JP blit_to_screen       ;

; The sun's and moon's heights
;
; Thirteen pixel heights, one for every four pixels the sun or moon has moved
; across its window: up from 5 to 10 and back down to 5. Read by
; display_sun_moon_frame.
sun_moon_yoff:
  DEFB $05,$06,$07,$08,$09,$0A,$0A,$09
  DEFB $08,$07,$06,$05,$05

; The sun or moon, as an object record
;
; Thirty-two bytes laid out like a record in the object table, so that the
; ordinary sprite printer (print_sprite) can draw the sun or moon. The fields
; that matter: +$00 the type, 88 for the sun or 89 for the moon, and +$1A and
; +$1B the pixel position. Set up by init_sun, moved by print_sun_moon, swapped
; by toggle_day_night. Other code reads +$00 to know whether it is day or
; night: colour_sun_moon for the window's colour, and lose_life to bring the
; player back as a knight or a werewolf.
sun_moon_scratchpad:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; Start the first day
;
; Used by the routine at main.
;
; The sun (type 88) at the left of its window. The height of 9 does not
; survive: the first call to display_sun_moon_frame replaces it from the table
; at sun_moon_yoff.
init_sun:
  LD IX,sun_moon_scratchpad ; the sun, pixel X 176, pixel Y 9
  LD (IX+$00),$58
  LD (IX+$1A),$B0
  LD (IX+$1B),$09
  RET

; Shuffle the special objects
;
; Used by the routine at main.
;
; Gives each of the 32 places in special_objs_tbl an object, and puts each one
; at its starting position. The places are fixed by the table; what changes
; from game to game is which object is where. The kinds are handed out in
; rotation, 96 to 103 and round again, so there are four of each, but the
; rotation starts at a random point: the seed saved at switch-on ($5BA0) plus
; the refresh register.
;
; Types 96 to 102 are the seven things the wizard's cauldron needs
; (objects_required lists the order he asks for them); type 103 is the one that
; gives an extra life when touched (upd_103).
init_special_objects:
  LD HL,special_objs_tbl  ; the first of 32 nine-byte entries
  LD A,($5BA0)            ; a random starting kind
  LD E,A                  ;
  LD A,R                  ;
  ADD A,E                 ;
  LD E,A                  ;

; Set up one special-object entry
;
; A table entry is nine bytes: +0 the type, 0 once the object has been
; collected; +1 to +4 where it starts, as x, y, z and room; +5 to +8 where it
; is now, in the same order. Here the type is written and the starting position
; copied to the current one.
;
; HL the entry
; E the rotating kind
init_obj_loop:
  LD A,E                  ; type 96 + (kind mod 8)
  AND $07                 ;
  OR $60                  ;
  LD (HL),A               ;
  INC HL                  ; on to +1, and the next kind
  INC E                   ;
  PUSH DE                 ; copy +1..+4, where it starts, to +5..+8, where it
  EX DE,HL                ; is
  LD HL,$0004             ;
  ADD HL,DE               ;
  EX DE,HL                ;
  LD BC,$0004             ;
  LDIR                    ;
  EX DE,HL                ;
  PUSH HL                 ; until the sprite table at sprite_tbl, which follows
  LD BC,sprite_tbl        ; the last entry
  AND A                   ;
  SBC HL,BC               ;
  POP HL                  ;
  POP DE                  ;
  JR C,init_obj_loop      ;
  RET

; The block type called moveable (type 62)
;
; Clears its horizontal velocity, clicks the speaker with a pitch taken from
; the frame counter, and lets gravity act on it. Clearing the velocity before
; moving undoes any push the collision code gave it earlier in the frame -- the
; player is always the first object -- so the block can only fall, never be
; pushed. Watched in the emulator: a table placed in the player's path was
; pushed a step per frame, and the same table given this type did not move at
; all. Compare the table's handler, upd_84, which moves first and clears the
; velocity afterwards. Whether a block that cannot be moved was meant is not
; known.
upd_62:
  CALL upd_6_7            ; draw 16 left and 8 down
  CALL clear_dX_dY        ; no horizontal movement
  CALL sound_movable_block
  JP dec_dZ_wipe_and_draw

; A chest (type 85)
;
; Falls and moves by its velocity, and makes a sound and redraws only when it
; is actually moving. Unlike the table (upd_84) it keeps its horizontal
; velocity from one frame to the next.
upd_85:
  CALL upd_6_7            ; draw 16 left and 8 down
  CALL dec_dZ_and_update_XYZ ; gravity, then move
  CALL is_obj_moving      ; still: nothing to draw
  RET Z                   ;
  JP click_wipe_and_draw

; A table (type 84)
;
; The drawing offset, then the shared code that follows.
upd_84:
  CALL upd_6_7            ; draw 16 left and 8 down

; Move under gravity, and redraw if moved
;
; Used by the routine at extra_life_fall.
;
; Applies gravity and moves the object; if it moved, its horizontal velocity is
; cleared (so a push moves it one step, not a slide), a sound is made and it is
; redrawn. Shared by the table (upd_84) and the extra-life object (upd_103).
dec_dZ_upd_XYZ_wipe_if_moving:
  CALL dec_dZ_and_update_XYZ ; gravity, then move
  CALL is_obj_moving      ; still: nothing to draw
  RET Z                   ;
  CALL clear_dX_dY        ; one step per push
  JP click_wipe_and_draw

; Drawing offset X -8, Y -2 (types 128 to 130)
;
; Used by the routine at upd_103.
;
; This is the whole handler for types 128 to 130: they only need their drawing
; offset set. upd_103 calls it too.
;
; A note that applies to all the routines from here to adj_p3_m12: +$12 and
; +$13 of an object record are added to the pixel position that calc_pixel_XY
; projects from its x, y and z, to line the sprite's picture up with the
; object's position in the room. X is pixels right and Y pixels up, so the
; usual negative values move the sprite left and down. The tcdev names that
; start adj_ give the Y value first: adj_m6_m12 is Y -6, X -12.
upd_128_to_130:
  LD HL,$FEF8
  JR jp_set_pixel_adj

; Drawing offset X -12, Y -4
;
; Used by the routines at upd_131_to_133, init_cauldron_bubbles,
; upd_160_to_163, upd_168_to_175, upd_164_to_167, upd_120_to_126, upd_127,
; upd_112_to_118_184, upd_119, upd_103, upd_104_to_110 and upd_96_to_102.
;
; The offset used by most small objects: the special objects, the cauldron's
; contents and a dozen more.
adj_m4_m12:
  LD HL,$FCF4
  JR jp_set_pixel_adj

; Drawing offset X -12, Y -6
;
; Used by the routines at upd_144_to_149_152_to_157, finish_transform,
; upd_80_to_83, upd_8, upd_9 and upd_16_to_21_24_to_29.
;
; Used by the knight's legs, the ghosts, the portcullis and others.
adj_m6_m12:
  LD HL,$FAF4

; Jump to set the drawing offset
;
; Used by the routines at upd_128_to_130, adj_m4_m12, upd_6_7, upd_10, upd_11,
; upd_12_to_15, adj_m8_m12, adj_m7_m12, adj_m12_m12, upd_88_to_90, adj_p7_m12
; and adj_p3_m12.
;
; The offset routines from upd_128_to_130 to adj_p3_m12 all end by jumping
; here, because set_pixel_adj is too far away for a relative jump and a JR plus
; one shared JP is shorter than a JP in every one of them.
jp_set_pixel_adj:
  JP set_pixel_adj

; Drawing offset X -16, Y -8 (types 6 and 7)
;
; Used by the routines at upd_91, upd_143, shuttle_block, upd_63, upd_23,
; upd_62, upd_85 and upd_84.
;
; The whole handler for types 6 and 7 -- type 7 is the plain stone block -- and
; the offset for chests, tables and several others.
upd_6_7:
  LD HL,$F8F0
  JR jp_set_pixel_adj

; Drawing offset X -20, Y -1 (type 10)
;
; The whole handler for type 10.
upd_10:
  LD HL,$FFEC
  JR jp_set_pixel_adj

; Drawing offset X -12, Y -2 (type 11)
;
; Used by the routines at chk_and_init_transform and upd_92_to_95.
;
; The whole handler for type 11; also the offset of the transformation sprites
; (chk_and_init_transform, upd_92_to_95).
upd_11:
  LD HL,$FEF4
  JR jp_set_pixel_adj

; Drawing offset X -8, Y -4 (types 12 to 15)
;
; Used by the routines at upd_182_183, upd_86_87, upd_180_181, upd_176_177 and
; upd_178_179.
;
; The whole handler for types 12 to 15, and used by several others.
upd_12_to_15:
  LD HL,$FCF8
  JR jp_set_pixel_adj

; Drawing offset X -12, Y -8
;
; Used by the routine at upd_32_to_47.
;
; The knight's top half.
adj_m8_m12:
  LD HL,$F8F4
  JR jp_set_pixel_adj

; Drawing offset X -12, Y -7
;
; Used by the routines at upd_22 and upd_48_to_53_56_to_61.
;
; The werewolf's legs (upd_48_to_53_56_to_61) and one other.
adj_m7_m12:
  LD HL,$F9F4
  JR jp_set_pixel_adj

; Drawing offset X -12, Y -12
;
; Used by the routine at upd_64_to_79.
;
; The werewolf's top half.
adj_m12_m12:
  LD HL,$F4F4
  JR jp_set_pixel_adj

; Drawing offset X -16, Y -12 (types 88 to 90)
;
; Used by the routine at upd_141.
;
; The whole handler for types 88 to 90, and used by one other. The sun, the
; moon and the left half of their window's frame are drawn with these type
; numbers, but through their own records (sun_moon_scratchpad,
; sprite_scratchpad), not the object table.
upd_88_to_90:
  LD HL,$F4F0
  JR jp_set_pixel_adj

; Drawing offset X -12, Y +7
;
; Used by the routine at upd_150_151.
adj_p7_m12:
  LD HL,$07F4
  JR jp_set_pixel_adj

; Drawing offset X -12, Y +3
;
; Used by the routine at upd_30_31_158_159.
adj_p3_m12:
  LD HL,$03F4
  JR jp_set_pixel_adj

; Fill a rectangle of bytes
;
; Used by the routines at display_object, show_carried_slot, display_frame,
; colour_panel, fill_sun_moon_colour and wipe_rect.
;
; Rows are 32 bytes apart, which suits both the buffer at screen_buffer and the
; attribute file.
;
; HL the top-left byte, in the screen buffer or the attributes
; B the width in bytes
; C the number of rows
; A the value to fill with
fill_window:
  LD DE,$0020

; Fill one row
;
; Used by the routine at fill_window_byte.
;
; The row loop of fill_window.
fill_window_row:
  PUSH BC
  PUSH HL

; Fill one byte
;
; The inner loop of fill_window, then on to the next row 32 bytes down.
fill_window_byte:
  LD (HL),A
  INC HL
  DJNZ fill_window_byte
  POP HL
  ADD HL,DE
  POP BC
  DEC C
  JR NZ,fill_window_row
  RET

; Bring in the special objects for a new room
;
; Used by the routine at build_room.
;
; Called while a room is built (build_room). Looks through the 32 entries of
; special_objs_tbl for objects not yet collected whose current room is the one
; being entered, and builds an object record for each in records 2 and 3 ($5C48
; and $5C68) -- the two slots the game keeps for special objects. Whatever is
; left of those two records is cleared.
;
; The 32 starting rooms in the table are all different, so at the start no room
; has more than one. A third match would build a record over $5C88, the room's
; first object, and clear_spare_spec_records would then never stop clearing;
; how the drop code keeps it to two has not been checked here.
;
; IX the player's record; +$08 is the room being entered
find_special_objs_here:
  LD DE,$5C48
  EXX
  LD IY,special_objs_tbl
  LD B,(IX+$08)           ; the room

; Check one special-object entry
;
; Used by the routine at next_spec_obj_slot.
;
; If the entry is still in play and in this room, copy it into the next
; special-object record: type; x, y and z from where it is now; size 5 by 5 by
; 12 and flags $14 (drawn, and can be pushed); the room; nothing moving; and at
; +$10 the address of the table entry, so the record can be written back to it
; by update_special_objs when the room is left.
find_spec_obj_loop:
  LD A,(IY+$00)           ; collected: skip
  AND A
  JR Z,next_spec_obj_slot
  LD A,(IY+$08)           ; in another room: skip
  CP B
  JR NZ,next_spec_obj_slot
  PUSH IY                 ; HL = the entry; its address is kept on the stack
  EXX                     ;
  POP HL                  ;
  PUSH HL                 ;
  LD A,(HL)               ; the type
  INC HL                  ;
  LD (DE),A               ;
  INC DE                  ;
  INC HL                  ; x, y and z from +5..+7, where it is now
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
  LD B,$07                ; +$09..+$0F: no velocity or status
  CALL zero_DE            ;
  POP BC                  ; +$10: the address of the table entry
  LD A,C                  ;
  LD (DE),A               ;
  INC DE                  ;
  LD A,B                  ;
  LD (DE),A               ;
  INC DE                  ;
  LD B,$0E                ; +$12..+$1F cleared
  CALL zero_DE            ;
  EXX                     ; back to the scan's registers

; Next special-object entry
;
; Used by the routine at find_spec_obj_loop.
;
; Nine bytes on, until the sprite table at sprite_tbl.
next_spec_obj_slot:
  LD DE,$0009
  ADD IY,DE
  PUSH IY
  POP HL
  LD DE,sprite_tbl
  AND A
  SBC HL,DE
  JR C,find_spec_obj_loop
  EXX

; Clear the unused special-object records
;
; Zeroes 32 bytes at a time until DE reaches record 4 at $5C88, the first of
; the room's own objects.
;
; DE the first unused byte of records 2 and 3
clear_spare_spec_records:
  LD HL,$5C88
  AND A
  SBC HL,DE
  RET Z
  LD B,$20
  CALL zero_DE
  JR clear_spare_spec_records

; Remember where the special objects were left
;
; Used by the routine at build_screen_objects.
;
; Called before a new room is built (build_screen_objects), once a frame of the
; game has run (bit 0 of $5BB2). For each of records 2 and 3 that is in use,
; writes its type and its x, y, z and room back into its entry in
; special_objs_tbl, through the pointer at +$10. That is how an object pushed
; or dropped somewhere stays there when you come back.
update_special_objs:
  LD IY,$5C48             ; record 2

; Write back one special object
;
; Used by the routine at save_spec_obj_next.
save_spec_obj_loop:
  LD A,(IY+$00)           ; empty
  AND A
  JR Z,save_spec_obj_next
  LD E,(IY+$10)           ; the type, through the pointer at +$10
  LD D,(IY+$11)           ;
  LD A,(IY+$00)           ;
  LD (DE),A               ;
  INC DE                  ; on to +5
  INC DE                  ;
  INC DE                  ;
  INC DE                  ;
  INC DE                  ;
  PUSH IY                 ; x, y and z
  POP HL                  ;
  INC HL                  ;
  LD BC,$0003             ;
  LDIR                    ;
  LD A,(IY+$08)           ; the room
  LD (DE),A

; Next special-object record
;
; Used by the routine at save_spec_obj_loop.
;
; Until record 4, at $5C88.
save_spec_obj_next:
  LD BC,$0020
  ADD IY,BC
  PUSH IY
  POP HL
  LD BC,$5C88
  AND A
  SBC HL,BC
  JR C,save_spec_obj_loop
  RET

; A ghost (types 80 to 83)
;
; A ghost drifts diagonally at a speed of 3 or 4 in each direction, and picks a
; new random diagonal whenever it has no speed (as when it has just been
; created) or runs into something across the floor. It animates on every frame
; and is deadly both ways: to what it runs into, and to what runs into it.
;
; IX the ghost's record
upd_80_to_83:
  CALL adj_m6_m12         ; draw 12 left and 6 down
  CALL dec_dZ_and_update_XYZ ; gravity, then move
  LD A,(IX+$09)           ; not moving: new direction
  OR (IX+$0A)
  JR Z,ghost_new_direction
  LD A,(IX+$0C)           ; blocked in x or y (bits 0 and 1 of +$0C): new
  AND $03                 ; direction
  JR Z,ghost_animate      ;

; Give a ghost a new direction
;
; Used by the routine at upd_80_to_83.
;
; Each of dx and dy is taken from entries 4 to 7 of delta_tbl -- -3, +3, -4 or
; +4 -- one chosen by the random seed and the other by the frame counter. Then
; the sprite is chosen to match, and a sound played.
ghost_new_direction:
  LD A,($5BA5)            ; dx
  AND $03                 ;
  ADD A,$04
  CALL get_delta_from_tbl
  LD (IX+$09),A
  LD A,($5BA2)            ; dy
  AND $03                 ;
  ADD A,$04
  CALL get_delta_from_tbl
  LD (IX+$0A),A
  CALL calc_ghost_sprite  ; face the way it is going
  CALL sound_pitch_from_xyz ; the sound's pitch comes from x + y + z

; Animate a ghost
;
; Used by the routine at upd_80_to_83.
;
; Swaps between the two frames of its sprite (bit 0 of the type) and sets the
; deadly flags and the redraw flags.
ghost_animate:
  CALL toggle_next_prev_sprite
  JP set_deadly_wipe_and_draw_flags

; Choose a ghost's sprite from its direction
;
; Used by the routine at ghost_new_direction.
;
; A ghost has two views, chosen by bit 1 of its type, and each can be mirrored
; (bit 6 of +$07); together they give four directions. Whichever of dx and dy
; is larger in size decides: mostly along x, the view is mirrored; mostly along
; y, it is not. The sign then picks the view.
;
; IX the ghost's record
calc_ghost_sprite:
  LD A,(IX+$09)           ; the size of dx
  AND A
  JP P,ghost_abs_dy
  NEG

; The size of dy
;
; Used by the routine at calc_ghost_sprite.
ghost_abs_dy:
  LD C,A                  ; C = the size of dx
  LD A,(IX+$0A)
  AND A
  JP P,ghost_pick_view
  NEG

; Mostly along x, or mostly along y?
;
; Used by the routine at ghost_abs_dy.
ghost_pick_view:
  CP C                    ; |dy| >= |dx|: mostly along y
  JR NC,ghost_mostly_y    ;
  LD A,(IX+$09)           ; which way along x
  AND A
  JP M,ghost_x_negative
  RES 1,(IX+$00)          ; +x: view 0

; Mirror the ghost
;
; Used by the routine at ghost_x_negative.
;
; Mirrored when moving mostly along x.
set_ghost_hflip:
  SET 6,(IX+$07)
  RET

; Moving towards -x
;
; Used by the routine at ghost_pick_view.
;
; View 1, mirrored.
ghost_x_negative:
  SET 1,(IX+$00)
  JR set_ghost_hflip

; Moving mostly along y
;
; Used by the routine at ghost_pick_view.
ghost_mostly_y:
  LD A,(IX+$0A)           ; which way along y
  AND A
  JP M,ghost_y_negative
  SET 1,(IX+$00)          ; +y: view 1

; Don't mirror the ghost
;
; Used by the routine at ghost_y_negative.
;
; Not mirrored when moving mostly along y.
clr_ghost_hflip:
  RES 6,(IX+$07)
  RET

; Moving towards -y
;
; Used by the routine at ghost_mostly_y.
;
; View 0, not mirrored.
ghost_y_negative:
  RES 1,(IX+$00)
  JR clr_ghost_hflip

; Look up a speed
;
; Used by the routine at ghost_new_direction.
;
; A plain byte lookup in delta_tbl.
;
; A the index into delta_tbl
; A on exit, the speed
get_delta_from_tbl:
  LD BC,delta_tbl
  LD L,A
  LD H,$00
  ADD HL,BC
  LD A,(HL)
  RET

; Speeds, negative and positive
;
; Sixteen signed bytes in pairs: -1 and +1, -2 and +2, up to -8 and +8. The
; ghosts (ghost_new_direction) only read entries 4 to 7, the pairs for 3 and 4;
; no other use of the table has been found.
delta_tbl:
  DEFB $FF,$01
  DEFB $FE,$02
  DEFB $FD,$03
  DEFB $FC,$04
  DEFB $FB,$05
  DEFB $FA,$06
  DEFB $F9,$07
  DEFB $F8,$08

; A portcullis at rest (type 8)
;
; A portcullis moves between the floor and 32 above it. Only one in a room
; moves at a time: $5BAF counts the one moving, and while it is non-zero
; nothing here happens. A portcullis anywhere below the top starts to rise at a
; random moment, on average once every 32 frames. One at the top drops at once
; for its first four falls after the room is entered (counted in $5BB0); after
; that it too waits for a 1-in-32 chance on each frame. Setting bit 0 of the
; type makes it type 9, handled by upd_9 while it moves.
;
; IX the portcullis's record
upd_8:
  CALL adj_m6_m12         ; draw 12 left and 6 down
  LD HL,$5BAF             ; another portcullis is moving
  LD A,(HL)               ;
  AND A                   ;
  RET NZ                  ;
  LD A,($5BAE)            ; on the floor ($5BAE is the floor's height): rise
  CP (IX+$03)
  JR Z,init_portcullis_up
  ADD A,$1F                ; anywhere below the floor + 31: rise
  CP (IX+$03)              ;
  JR NC,init_portcullis_up ;
  LD A,($5BB0)              ; fewer than four falls so far: fall now
  CP $04                    ;
  JR C,init_portcullis_down ;
  LD A,($5BA5)            ; otherwise a 1-in-32 chance
  AND $1F                 ;
  RET NZ                  ;
  OR $80                  ; $80 + 1 is stored as the count; any value from 4 up
                          ; would do the same

; Start a portcullis falling
;
; Used by the routine at upd_8.
;
; A the number of falls so far
; HL $5BAF
init_portcullis_down:
  INC A                   ; one more fall
  LD ($5BB0),A            ;
  SET 0,(IX+$00)          ; type 9: moving
  LD (IX+$0B),$FF         ; dz = -1

; Count the moving portcullis
;
; Used by the routine at init_portcullis_up.
;
; Sets $5BAF so that no other portcullis in the room starts to move.
count_moving_portcullis:
  INC (HL)

; Mark an object to be wiped and redrawn
;
; Used by the routines at dec_dZ_wipe_and_draw, drop_block_draw,
; shuttle_block_step, legs_animate_and_draw, draw_spiked_ball,
; set_deadly_wipe_and_draw_flags, bubbles_draw, upd_120_to_126,
; sparkle_sound_and_draw, click_wipe_and_draw, final_clear_loop,
; chk_and_init_transform, set_transform_sprite, transform_done_draw,
; set_wipe_and_draw_IY, upd_9, stop_portcullis, move_portcullis_up and
; player_redraw.
;
; Sets bit 5 of +$07 (erase the old image) and bit 4 (draw the new one), then
; goes on to set_draw_objs_overlapped to mark whatever the object overlaps on
; the screen for redrawing too. Nearly every moving object's handler ends here.
;
; IX the object's record
set_wipe_and_draw_flags:
  LD A,(IX+$07)
  OR $30
  LD (IX+$07),A
  JP set_draw_objs_overlapped

; Mark the object at IY to be wiped and redrawn
;
; Used by the routine at pickup_object.
;
; set_wipe_and_draw_flags for the record at IY instead of IX, with both
; preserved. Used when an object is picked up (pickup_object).
;
; IY the object's record
set_wipe_and_draw_IY:
  PUSH IY
  PUSH IX
  PUSH IY
  POP IX
  CALL set_wipe_and_draw_flags
  POP IX
  POP IY
  RET

; Start a portcullis rising
;
; Used by the routine at upd_8.
;
; Only on one frame in 32 or so, chosen by the random seed.
init_portcullis_up:
  LD A,($5BA5)            ; a 1-in-32 chance
  AND $1F
  RET NZ
  SET 0,(IX+$00)          ; type 9: moving
  LD (IX+$0B),$01         ; dz = +1
  JR count_moving_portcullis

; A moving portcullis (type 9)
;
; Rising, it climbs one unit a frame with a sound whose pitch follows its
; height, until it is more than 31 above the floor. Falling, it gets an extra
; unit of downward speed each frame on top of gravity, so it falls with twice
; the pull of anything else, and lands with a crash of noise. While it moves it
; has bit 7 of +$0D set, which passes the deadly mark (bit 6) to whatever it
; moves into: a falling portcullis kills. It stays still while the player is
; settling into the room.
;
; IX the portcullis's record
upd_9:
  CALL adj_m6_m12         ; draw 12 left and 6 down
  SET 7,(IX+$0D)          ; deadly to what it moves into
  LD A,($5C14)            ; wait while the player's +$0C counts down after
                          ; entering the room
  AND $F0
  RET NZ
  LD A,(IX+$0B)           ; rising
  AND A
  JP P,move_portcullis_up
  DEC (IX+$0B)            ; extra speed down, then gravity and move
  CALL dec_dZ_and_update_XYZ
  BIT 2,(IX+$0C)          ; not landed yet
  JR Z,set_wipe_and_draw_flags
  CALL sound_portcullis_crash ; the crash: noise from bytes of the ROM chosen
                              ; by the seed and the frame counter

; Stop a portcullis
;
; Used by the routine at move_portcullis_up.
;
; Frees the room for another portcullis to move and makes this one type 8
; again.
stop_portcullis:
  XOR A                   ; no portcullis moving
  LD ($5BAF),A            ;
  RES 0,(IX+$00)          ; type 8: at rest
  JR set_wipe_and_draw_flags

; Raise a portcullis
;
; Used by the routine at upd_9.
;
; dz of 2 less one for gravity: one unit a frame upwards.
move_portcullis_up:
  LD (IX+$0B),$02         ; dz = 2
  CALL sound_pitch_from_xyz ; a sound whose pitch follows its height
  CALL dec_dZ_and_update_XYZ ; gravity, then move
  LD A,($5BAE)                  ; still at or below the floor + 31: keep going
  ADD A,$1F                     ;
  CP (IX+$03)                   ;
  JR NC,set_wipe_and_draw_flags ;
  JR stop_portcullis

; Apply gravity and move
;
; Used by the routines at dec_dZ_wipe_and_draw, upd_182_183, upd_91,
; guard_ew_move, spiked_ball_drop, fire_ew_move, fire_ns_move,
; ud_ball_rise_or_fall, ball_up, upd_160_to_163, chaser_chase,
; upd_30_31_158_159, move_charm_to_cauldron, upd_96_to_102, upd_85,
; dec_dZ_upd_XYZ_wipe_if_moving, upd_80_to_83, upd_9 and move_portcullis_up.
;
; Takes one off dz, then lets adj_for_out_of_bounds cut the velocity down to
; what the room's walls and floor and the other objects allow (and set the
; blocked bits in +$0C), and moves the object by what is left.
;
; IX the object's record
dec_dZ_and_update_XYZ:
  DEC (IX+$0B)
  CALL adj_for_out_of_bounds

; Move by the velocity
;
; Used by the routine at move_player_apply.
;
; Adds dx, dy and dz (+$09 to +$0B) to x, y and z (+$01 to +$03).
;
; IX the object's record
add_dXYZ:
  LD A,(IX+$01)
  ADD A,(IX+$09)
  LD (IX+$01),A
  LD A,(IX+$02)
  ADD A,(IX+$0A)
  LD (IX+$02),A
  LD A,(IX+$03)
  ADD A,(IX+$0B)
  LD (IX+$03),A
  RET

; The second pillar of an arch (types 3 and 5)
;
; An arch is two pillars, built together from one background entry
; (background_type_tbl). This one only needs its drawing offset: X -9, Y -3, or
; X -7, Y -2 when mirrored. The work of the doorway is done by the other pillar
; (upd_2_4).
;
; IX the pillar's record
upd_3_5:
  BIT 6,(IX+$07)          ; mirrored for the arches in the north and south
                          ; walls
  JR NZ,adj_3_5_hflip
  LD HL,$FDF7

; Set the drawing offset
;
; Used by the routines at upd_142, jp_set_pixel_adj, adj_3_5_hflip,
; arch_ew_doorway and adj_2_4_hflip.
;
; The end of all the offset routines; see upd_128_to_130.
;
; L the X offset in pixels, stored at +$12
; H the Y offset in pixels, stored at +$13
; IX the object's record
set_pixel_adj:
  LD (IX+$12),L
  LD (IX+$13),H
  RET

; The second pillar, mirrored
;
; Used by the routine at upd_3_5.
;
; X -7, Y -2.
adj_3_5_hflip:
  LD HL,$FEF9
  JR set_pixel_adj

; The first pillar of a tree arch, facing east or west
;
; Used by the routine at upd_2_4.
;
; Type 4 uses X +1, Y -3 where the stone arch's type 2 uses X -7, Y -3; the
; doorway itself is worked out the same way.
adj_m3_p1:
  LD HL,$FD01
  JR arch_ew_doorway

; The first pillar of an arch (types 2 and 4)
;
; This pillar handles the doorway. It works out the point in the middle of the
; arch, 13 units from itself, and keeps it in its own +$09 to +$0B -- the
; velocity fields, which an arch never needs, borrowed because is_near_to
; compares +$09 to +$0B of one record with +$01 to +$03 of another. Then two
; passes over the player: chk_plyr_spec_near_arch, which marks it as allowed to
; leave the room if it is right in the doorway, and arch_nudge_to_centre, which
; nudges it towards the arch's centre line if it is anywhere near.
;
; Arches in the north and south walls are mirrored (bit 6 of +$07) and lead
; along y; those in the east and west walls are not, and lead along x.
;
; IX the pillar's record
upd_2_4:
  BIT 6,(IX+$07)          ; north or south wall
  JR NZ,adj_2_4_hflip
  LD A,(IX+$00)           ; a tree arch has its own offset
  CP $04
  JR Z,adj_m3_p1
  LD HL,$FDF9

; The middle of an east or west arch
;
; Used by the routine at adj_m3_p1.
;
; The other pillar is 13 further along y; the doorway is 15 deep (along x) and
; 6 either side of the middle (along y).
arch_ew_doorway:
  CALL set_pixel_adj      ; the drawing offset in HL
  LD A,(IX+$02)           ; y of the middle: this pillar's y + 13
  ADD A,$0D
  LD (IX+$0A),A
  LD A,(IX+$01)           ; x of the middle: this pillar's
  LD (IX+$09),A
  LD HL,$060F             ; the doorway: x within 15, y within 6

; Check the player against the doorway
;
; Used by the routine at adj_2_4_hflip.
arch_check_doorway:
  LD A,(IX+$03)           ; z of the middle: the pillar's base
  LD (IX+$0B),A
  CALL chk_plyr_spec_near_arch ; in the doorway: may leave the room
  JP arch_nudge_to_centre ; near it: nudge towards the middle

; The first pillar, mirrored: a north or south arch
;
; Used by the routine at upd_2_4.
;
; X -17, Y -2. The other pillar is 13 back along x; the doorway is 15 deep
; along y and 6 either side along x.
adj_2_4_hflip:
  LD HL,$FEEF             ; the drawing offset
  CALL set_pixel_adj      ;
  LD A,(IX+$01)           ; x of the middle: this pillar's x - 13
  SUB $0D
  LD (IX+$09),A
  LD A,(IX+$02)           ; y of the middle: this pillar's
  LD (IX+$0A),A
  LD HL,$0F06             ; the doorway: x within 6, y within 15
  JR arch_check_doorway

; Nudge the player towards the middle of an arch
;
; Used by the routine at arch_check_doorway.
;
; For each of records 0 to 3 with bit 3 of +$07 set -- only the player's two
; records have it -- within 15 of the arch's middle along both x and y and
; within 4 of its z, set a nudge of one unit towards the centre line. The nudge
; goes in +$0E (x) or +$0F (y), which the player's movement adds to its
; velocity (calc_plyr_dXY) when it next walks. This is why the knight slides
; into line with an arch as he walks through.
;
; IX the pillar's record, holding the arch's middle at +$09 to +$0B
arch_nudge_to_centre:
  LD HL,$0F0F             ; 15 either way along x and y
  LD IY,$5C08             ; records 0 to 3
  LD DE,$0020             ;
  LD B,$04                ;

; Nudge one record
;
; Used by the routine at arch_nudge_next.
arch_nudge_loop:
  LD A,(IY+$00)           ; empty record
  AND A
  JR Z,arch_nudge_next
  BIT 3,(IY+$07)          ; not one that uses arches
  JR Z,arch_nudge_next    ;
  CALL is_near_to         ; not near
  JR NC,arch_nudge_next   ;
  PUSH BC                 ; which way the arch runs: dispatch_on_facing reads
  LD BC,adj_arch_tbl      ; the mirror bit of the arch at IX, giving entry 0 or
  JP dispatch_on_facing   ; 2

; How to nudge, by the arch's direction
;
; Four words indexed as the player's facing would be; an arch only ever
; produces 0 (east or west wall, not mirrored) or 2 (north or south, mirrored).
adj_arch_tbl:
  DEFW adj_ew             ; East or west arch: nudge along y
  DEFW adj_ew             ;
  DEFW adj_ns             ; North or south arch: nudge along x
  DEFW adj_ns             ;

; Nudge along y, for an east or west arch
;
; IX the arch's record
; IY the player's record
adj_ew:
  LD A,(IX+$0A)           ; already on the centre line
  CP (IY+$02)
  JR Z,arch_nudge_done
  LD A,$01                ; +1 if the middle is at a greater y, else -1
  JR NC,nudge_y_store     ;
  NEG                     ;

; Store the y nudge
;
; Used by the routine at adj_ew.
nudge_y_store:
  LD (IY+$0F),A           ; the y nudge
  JR arch_nudge_done

; Nudge along x, for a north or south arch
;
; IX the arch's record
; IY the player's record
adj_ns:
  LD A,(IX+$09)           ; already on the centre line
  CP (IY+$01)
  JR Z,arch_nudge_done
  LD A,$01                ; +1 if the middle is at a greater x, else -1
  JR NC,nudge_x_store     ;
  NEG                     ;

; Store the x nudge
;
; Used by the routine at adj_ns.
nudge_x_store:
  LD (IY+$0E),A           ; the x nudge

; Nudge done
;
; Used by the routines at adj_ew, nudge_y_store and adj_ns.
;
; Recovers the loop counter pushed at arch_nudge_loop.
arch_nudge_done:
  POP BC

; Next record to nudge
;
; Used by the routine at arch_nudge_loop.
arch_nudge_next:
  ADD IY,DE               ; 32 bytes on, four records
  DJNZ arch_nudge_loop    ;
  RET                     ;

; Is the player in the doorway?
;
; Used by the routine at arch_check_doorway.
;
; For each of records 0 to 3 that is in use and has bit 3 of +$07 set (the
; player's two records), sets bit 0 of +$07 if it is within the doorway's
; limits. handle_exit_screen will let the player leave the room only while that
; bit is set, and clears it when it does.
;
; IX the pillar's record, holding the arch's middle at +$09 to +$0B
; L how near along x
; H how near along y
chk_plyr_spec_near_arch:
  LD IY,$5C08             ; records 0 to 3
  LD DE,$0020
  LD B,$04

; Check one record against the doorway
;
; Used by the routine at near_arch_next.
near_arch_loop:
  LD A,(IY+$00)           ; empty record
  AND A
  JR Z,near_arch_next
  BIT 3,(IY+$07)          ; not one that uses arches
  JR Z,near_arch_next
  CALL is_near_to         ; not in the doorway
  JR NC,near_arch_next    ;
  SET 0,(IY+$07)          ; in the doorway: allowed to leave

; Next record for the doorway check
;
; Used by the routine at near_arch_loop.
near_arch_next:
  ADD IY,DE
  DJNZ near_arch_loop
  RET

; Is an object near a point?
;
; Used by the routines at arch_nudge_loop and near_arch_loop.
;
; IX a record whose +$09 to +$0B hold the point's x, y and z
; IY the object's record
; L the limit along x
; H the limit along y
; F on exit, carry set if the object's x, y and z are all within the limits (z
;   within 4)
is_near_to:
  LD A,(IX+$09)           ; the distance along x
  SUB (IY+$01)
  JR NC,near_check_y
  NEG

; Within the limit along x?
;
; Used by the routine at is_near_to.
near_check_y:
  CP L                    ; no: carry clear
  RET NC                  ;
  LD A,(IX+$0A)           ; the distance along y
  SUB (IY+$02)
  JR NC,near_check_z
  NEG

; Within the limit along y?
;
; Used by the routine at near_check_y.
near_check_z:
  CP H                    ; no: carry clear
  RET NC                  ;
  LD A,(IX+$0B)           ; the distance along z
  SUB (IY+$03)
  JR NC,near_z_compare
  NEG

; Within 4 along z?
;
; Used by the routine at near_check_z.
near_z_compare:
  CP $04                  ; carry set if so
  RET

; The knight's legs (types 16 to 21 and 24 to 29)
;
; Sets the drawing offset and goes into the player's handler
; (upd_player_bottom).
upd_16_to_21_24_to_29:
  CALL adj_m6_m12         ; draw 12 left and 6 down
  JR upd_player_bottom

; The werewolf's legs (types 48 to 53 and 56 to 61)
;
; One pixel lower than the knight's, then the same handler, which follows.
upd_48_to_53_56_to_61:
  CALL adj_m7_m12         ; draw 12 left and 7 down

; Update the player's legs
;
; Used by the routine at upd_16_to_21_24_to_29.
;
; The handler for the bottom of the two records that make up the player: the
; legs, whose box is the whole knight's for collisions. upd_16_to_21_24_to_29
; and upd_48_to_53_56_to_61 arrive here for the man and for the werewolf. IX is
; always the first object record, $5C08, and the top half is the record after
; it.
;
; First, death: bit 6 of +$0D is set by the collision code when the player
; touches something harmful. Unless the end-of-game sequence is running
; ($5BC3), the legs and the top half both turn into the death sparkle.
;
; IX the player's bottom record
upd_player_bottom:
  BIT 6,(IX+$0D)          ; has something harmful touched us?
  JR Z,player_controls
  LD A,($5BC3)            ; not once the game has been won: nothing kills the
  AND A                   ; player then
  JR NZ,player_controls   ;
  SET 6,(IX+$2D)          ; mark the top half (the next record) dead too
  JP init_death_sparkles  ; and become the death sparkle

; Read the controls and act on them
;
; Used by the routine at upd_player_bottom.
;
; The player's turn, in order: change between man and werewolf if the sun or
; moon says so, read the controls into C (bit 0 left, 1 right, 2 forward or up,
; 3 jump, 4 pick up or drop, or down on a joystick), pick up or drop, turn,
; jump, and step the legs. Then, if the player is standing in a doorway -- past
; the line of the room's walls -- plyr_OOB forbids any upward movement before
; the move is made.
player_controls:
  CALL chk_and_init_transform ; day or night may change the player's form
  CALL check_user_input   ; C = the controls this frame
  CALL handle_pickup_drop
  CALL handle_left_right  ; turn, jump, and walk
  CALL handle_jump        ;
  CALL handle_forward     ;
  CALL chk_plyr_OOB       ; no carry: in a doorway, beyond the walls
  JR NC,plyr_OOB          ;

; Move the player and count down the room-entry walk
;
; Used by the routine at plyr_OOB.
;
; Moves the player through move_player. For the length of the move the top
; half's "ignore me" bit is set, so the collision scan does not find the
; player's own head in the way of its legs.
;
; The top nibble of +$0C is a count set to 3 by exit_screen when the player
; walks into a new room; while it runs the controls are ignored and the player
; walks straight on. It drops by one here each frame.
player_move_and_draw:
  SET 1,(IX+$27)          ; top half out of the collision scan...
  CALL move_player        ; move
  RES 1,(IX+$27)          ; ...and back in
  LD A,(IX+$0C)           ; count the room-entry walk down, unless it is
                          ; already zero
  SUB $10
  JR C,player_redraw
  LD (IX+$0C),A

; Have the player redrawn
;
; Used by the routine at player_move_and_draw.
;
; Hands over to set_wipe_and_draw_flags, which marks the player to be wiped and
; redrawn, and which returns to the object loop.
player_redraw:
  JP set_wipe_and_draw_flags

; In a doorway: allow no rising
;
; Used by the routine at player_controls.
;
; Reached when chk_plyr_OOB finds the player at or beyond the line of a wall,
; which in practice means in an archway. A falling player keeps falling, but
; any upward speed -- a jump just started included -- is cancelled, so the
; player cannot rise inside a doorway. Then on to the move.
plyr_OOB:
  LD A,(IX+$0B)           ; dZ negative: falling is fine
  AND A
  JP M,player_move_and_draw
  XOR A                   ; otherwise no vertical movement at all
  LD (IX+$0B),A           ;
  JR player_move_and_draw ; move

; Is the player inside the room's walls?
;
; Used by the routines at handle_pickup_drop and player_controls.
;
; Compares the player's distance from the room's centre, $80 on each axis, with
; the room's half-size less the player's own half-width. Carry means the whole
; of the player's footprint is inside on both X and Y; no carry means it
; touches or crosses the line of a wall, which only an archway allows.
;
; Also used by handle_pickup_drop.
;
; IX the player's bottom record
; F carry set on exit if inside the walls
chk_plyr_OOB:
  LD HL,($5BAB)           ; L = X half-size less our half-width, H = the same
                          ; for Y
  LD A,L
  SUB (IX+$04)
  LD L,A
  LD A,H
  SUB (IX+$05)
  LD H,A
  LD A,(IX+$01)           ; A = |X - $80|
  SUB $80
  JP P,oob_test_x
  NEG

; Test X, then work out the Y distance
;
; Used by the routine at chk_plyr_OOB.
;
; Part of chk_plyr_OOB: fails (no carry) if the X distance is too great,
; otherwise measures the Y distance.
oob_test_x:
  CP L                    ; too far from the centre in X: no carry
  RET NC                  ;
  LD A,(IX+$02)           ; A = |Y - $80|
  SUB $80
  JP P,oob_test_y
  NEG

; Test Y
;
; Used by the routine at oob_test_x.
;
; The last step of chk_plyr_OOB: carry if the Y distance is inside the room.
oob_test_y:
  CP H
  RET

; Turn the player
;
; Used by the routine at player_controls.
;
; Two control schemes. Rotational control, the only one the keyboard has, uses
; left and right to turn a quarter at a time: see left_right_rotational.
; Directional control, which a joystick gets when option 5 on the menu is on
; (bit 3 of $5BA4), treats the stick as four compass points: pushing one turns
; the player towards it and, once facing it, walks that way.
;
; In directional mode nothing happens during the room-entry walk or in the air
; -- bit 2 of +$0C, set by the collision code when a downward move is stopped,
; is what "standing on something" means here. Otherwise the stick is read in
; the order up (unless left is also held), right, down, left.
;
; C the controls: bit 0 left, 1 right, 2 up, 3 jump, 4 down
; C on exit, bit 2 set if the player should walk forward
handle_left_right:
  LD HL,$5BA4             ; bits 1-2 of $5BA4 are the control method; 0, the
                          ; keyboard, is always rotational
  LD A,(HL)
  AND $06
  JR Z,left_right_rotational
  BIT 3,(HL)                 ; directional control switched off
  JR Z,left_right_rotational ;
  LD A,(IX+$0C)           ; not during the room-entry walk
  AND $F0
  RET NZ
  BIT 2,(IX+$0C)          ; not in the air
  RET Z                   ;
  BIT 0,C                 ; left pressed: skip the test for up; up: face N
  JR NZ,directional_pick  ;
  BIT 2,C                 ;
  JR NZ,chk_facing_N      ;

; Directional control: right, down or left
;
; Used by the routine at handle_left_right.
;
; The rest of the stick in handle_left_right: right faces E, down faces S, left
; faces W. With nothing pressed, no walking.
directional_pick:
  BIT 1,C                 ; right: E
  JR NZ,chk_facing_E      ;
  BIT 4,C                 ; down: S
  JR NZ,chk_facing_S      ;
  BIT 0,C                 ; left: W
  JR NZ,chk_facing_W      ;
  RES 2,C                 ; nothing: stand still
  RET                     ;

; Directional control: face N
;
; Used by the routine at handle_left_right.
;
; Facing codes, from get_sprite_dir: 0 W, 1 E, 2 N, 3 S. If already facing N
; the player walks; if not, turn_by_parity picks the shorter way round -- a
; right turn from W, a left turn from E, and from S a left turn now and another
; on the next frame.
chk_facing_N:
  CALL get_sprite_dir     ; facing N is code 2
  CP $02

; Directional control: walk, or turn towards N or E
;
; Used by the routine at chk_facing_E.
;
; Shared by chk_facing_N and chk_facing_E. Zero means the player already faces
; the way the stick points. Otherwise the facing code is inverted, so that bit
; 0 is set for the facings from which a right turn is the short way.
chk_facing_ne_result:
  JR Z,flag_forward       ; already facing that way: walk
  CPL                     ; flip bit 0 for turn_by_parity

; Directional control: turn left or right
;
; Used by the routine at chk_facing_sw_result.
;
; Bit 0 of A chooses: set for a right turn, clear for a left. The turn itself
; is left_right_calc_sprite, which does it at once, without the pause and the
; sound that rotational turning has.
turn_by_parity:
  AND $01                   ; Z for left, NZ for right
  JR left_right_calc_sprite ;

; Directional control: face E
;
; Used by the routine at directional_pick.
;
; As chk_facing_N for E, code 1: right from W (via N) and N, left from S.
chk_facing_E:
  CALL get_sprite_dir     ; facing E is code 1
  CP $01
  JR chk_facing_ne_result

; Directional control: face S
;
; Used by the routine at directional_pick.
;
; As chk_facing_N for S, code 3. Here the code is used as it is: left from W,
; right from E, and from N a left turn now (to W) and another next frame.
chk_facing_S:
  CALL get_sprite_dir     ; facing S is code 3
  CP $03

; Directional control: walk, or turn towards S or W
;
; Used by the routine at chk_facing_W.
;
; Shared by chk_facing_S and chk_facing_W: walk if already facing that way, or
; turn by bit 0 of the facing code without inverting it.
chk_facing_sw_result:
  JR Z,flag_forward       ; already facing: walk; otherwise turn
  JR turn_by_parity       ;

; Directional control: face W
;
; Used by the routine at directional_pick.
;
; As chk_facing_N for W, code 0: left from N, right from S, and from E a right
; turn to S now and another to W on the next frame.
chk_facing_W:
  CALL get_sprite_dir     ; facing W is code 0
  AND A
  JR chk_facing_sw_result

; Directional control: walk
;
; Used by the routines at chk_facing_ne_result and chk_facing_sw_result.
;
; The player already faces the way the stick is pushed, so set the "forward"
; bit for handle_forward and move_player.
flag_forward:
  SET 2,C
  RET

; Rotational control: turn a quarter
;
; Used by the routine at handle_left_right.
;
; Left and right turn the player a quarter at a time: right goes W, N, E, S
; (clockwise), left the other way. Bits 0-2 of +$0D are a pause between turns;
; while it counts down nothing else happens here, so holding a key turns the
; player once every third frame rather than every frame.
;
; C the controls: bit 0 left, 1 right, 2 forward
left_right_rotational:
  LD A,(IX+$0D)           ; pause still running?
  AND $07
  JR Z,rotational_turn
  DEC (IX+$0D)            ; count it down and do nothing else
  RET                     ;

; Rotational control: start a turn
;
; Used by the routine at left_right_rotational.
;
; A turn needs left or right held, the room-entry walk over, and no jump in
; progress. It makes a sound of its own only when the player is not also
; walking -- the footstep covers it otherwise.
rotational_turn:
  LD A,C                  ; neither left nor right
  AND $03                 ;
  RET Z                   ;
  LD A,(IX+$0C)           ; not during the room-entry walk
  AND $F0
  RET NZ
  BIT 3,(IX+$0C)          ; not in the middle of a jump
  RET NZ                  ;
  BIT 2,C                 ; turning on the spot: the turning sound
  JR NZ,start_turn_delay  ;
  PUSH BC                 ;
  CALL sound_footstep     ;
  POP BC                  ;

; Rotational control: set the pause and choose the direction
;
; Used by the routine at rotational_turn.
;
; Sets the pause between turns (two frames' wait) and leaves NZ for a right
; turn, Z for a left one, for left_right_calc_sprite.
start_turn_delay:
  LD A,(IX+$0D)           ; bit 1 of the pause count
  OR $02
  LD (IX+$0D),A
  BIT 1,C                 ; NZ: right

; Turn the player one quarter
;
; Used by the routine at turn_by_parity.
;
; How a facing is stored explains the shape of this. Bit 3 of the type chooses
; the sprite seen from behind (clear: W or N) or from the front (set: E or S),
; and bit 6 of +$07 mirrors it (clear: W or E; set: N or S). A quarter turn
; always toggles the mirror bit; half the time it also toggles the view. For a
; left turn that is when the sprite is not mirrored.
;
; F Z for a left turn, NZ for a right turn
left_right_calc_sprite:
  JR NZ,turn_right        ; right turn
  BIT 6,(IX+$07)          ; left: mirrored sprites only change mirror (N to W,
                          ; S to E)
  JR NZ,turn_toggle_mirror

; Turn: change between back and front view
;
; Used by the routine at turn_right.
;
; Toggles bit 3 of the type -- behind to in front, or back -- and goes on to
; toggle the mirror bit too.
turn_toggle_view:
  LD A,(IX+$00)           ; type bit 3: back or front view
  XOR $08                 ;
  LD (IX+$00),A           ;

; Turn: mirror the sprite, and turn the top half to match
;
; Used by the routines at left_right_calc_sprite and turn_right.
;
; Toggles the mirror bit, then sets the top half's type to the legs' type plus
; 16 so the body turns in the same frame; upd_player_top would otherwise only
; catch up on its own update.
turn_toggle_mirror:
  LD A,(IX+$07)           ; mirror bit
  XOR $40
  LD (IX+$07),A
  LD A,(IX+$00)           ; top half's type = our type + 16
  ADD A,$10
  LD (IX+$20),A
  RET

; Turn right
;
; Used by the routine at left_right_calc_sprite.
;
; A right turn toggles the view as well only when the sprite is already
; mirrored (N to E, S to W); from W or E it only mirrors (to N or S).
turn_right:
  BIT 6,(IX+$07)          ; mirrored: view and mirror; otherwise mirror only
  JR NZ,turn_toggle_view
  JR turn_toggle_mirror

; Start a jump
;
; Used by the routine at player_controls.
;
; Jump starts only when the jump control is held, the room-entry walk is over,
; no jump is already in progress (bit 3 of +$0C, cleared on landing by
; move_player_apply), and the player is not already falling. The launch speed
; is 8 units up; apply_gravity then takes it away again frame by frame.
;
; The test is on the speed, not on standing: a dZ of -1 or more is enough, and
; the collision code leaves dZ at 0 for a player on the ground.
;
; C the controls
handle_jump:
  BIT 3,C                 ; jump not held
  RET Z                   ;
  LD A,(IX+$0C)           ; not during the room-entry walk
  AND $F0
  RET NZ
  BIT 3,(IX+$0C)          ; not while a jump is in progress
  RET NZ
  LD A,(IX+$0B)           ; dZ -2 or less: already falling
  INC A
  RET M
  SET 3,(IX+$0C)          ; jumping, 8 units a frame upwards
  LD (IX+$0B),$08
  PUSH BC                 ; the jump sound; C, the controls, kept
  CALL sound_jump         ;
  POP BC                  ;
  RET                     ;

; Step the legs
;
; Used by the routine at player_controls.
;
; While the player is walking forward, jumping, or on the room-entry walk, the
; legs cycle and a footstep sounds. When none of those applies the legs do not
; simply stop: legs_to_rest carries the stride on to one of the two standing
; frames.
;
; C the controls
handle_forward:
  LD A,(IX+$0C)           ; room-entry walk or jump: step
  AND $F0
  JR NZ,walk_step_sound
  BIT 3,(IX+$0C)
  JR NZ,walk_step_sound
  BIT 2,C                 ; forward not held: finish the stride
  JR Z,legs_to_rest       ;

; Footstep, then the next leg frame
;
; Used by the routine at handle_forward.
;
; The footstep sound (sound_walk_step), then animate_human_legs.
walk_step_sound:
  PUSH BC                 ; C, the controls, kept
  CALL sound_walk_step    ;
  POP BC                  ;

; Next frame of a walk cycle
;
; Used by the routines at legs_animate_and_draw and legs_to_rest.
;
; The low three bits of the type are the frame of a six-frame walk cycle; this
; steps to the next, wrapping 5 to 0. Also used by legs_animate_and_draw.
;
; IX the object
animate_human_legs:
  LD A,(IX+$00)           ; frame + 1, and 6 wraps to 0
  LD E,A
  INC A
  AND $07
  CP $06
  JR NZ,store_leg_frame
  XOR A

; Store the new leg frame
;
; Used by the routine at animate_human_legs.
;
; Puts the new frame into the low three bits of the type.
store_leg_frame:
  LD D,A                  ; keep the type's other bits
  LD A,E                  ;
  AND $F8                 ;
  OR D                    ;
  LD (IX+$00),A           ;
  RET                     ;

; Bring the legs to rest
;
; Used by the routine at handle_forward.
;
; Frames 2 and 4 are the two standing poses. From any other frame the cycle
; carries on, silently, until it reaches one.
legs_to_rest:
  LD A,(IX+$00)           ; standing already
  AND $07                 ;
  CP $02                  ;
  RET Z                   ;
  CP $04                  ;
  RET Z                   ;
  JR animate_human_legs   ; keep stepping

; Move the player
;
; Used by the routine at player_move_and_draw.
;
; Works out this frame's move, has the collision code cut it short where it
; must, lets the player leave the room if that is what the move does, and
; applies it.
;
; While an object is floating up into the wizard's cauldron ($5BC4 set) the
; controls are off and dZ is forced to 2 here, which the two units of gravity
; below bring back to 0: the player hangs where he is.
;
; IX the player's bottom record
; C the controls
move_player:
  LD A,($5BC4)
  AND A
  JR Z,move_player_xy
  LD (IX+$0B),$02

; Is the player moving forward?
;
; Used by the routine at move_player.
;
; The player moves in the direction he faces when forward is held, and also,
; without it, throughout a jump and during the room-entry walk.
move_player_xy:
  BIT 3,(IX+$0C)          ; jumping, entering a room, or forward held
  JR NZ,move_player_walk
  LD A,(IX+$0C)
  AND $F0
  JR NZ,move_player_walk
  BIT 2,C
  JR Z,apply_gravity

; Take a step forward
;
; Used by the routine at move_player_xy.
;
; calc_plyr_dXY adds a step in the facing direction to dX and dY.
move_player_walk:
  PUSH BC                 ; C, the controls, kept
  CALL calc_plyr_dXY      ;
  POP BC                  ;

; Gravity
;
; Used by the routine at move_player_xy.
;
; Gravity takes 2 from dZ every frame. The exception is a player going up or
; level with jump still held, who loses only 1: holding jump makes a higher,
; slower jump. Nothing limits the speed of a fall.
apply_gravity:
  LD A,(IX+$0B)
  AND A
  JP M,gravity_extra
  BIT 3,C
  JR NZ,move_player_apply

; Gravity's second unit
;
; Used by the routine at apply_gravity.
;
; The extra unit taken off for a player falling, or not holding jump.
gravity_extra:
  DEC A

; Resolve and apply the move
;
; Used by the routine at apply_gravity.
;
; Stores the new dZ, and keeps a copy in $5BC1: the collision code will shorten
; dZ, and the copy is what says afterwards which way the player was trying to
; go. A fall faster than two units a frame has a sound pitched by the height.
;
; Then adj_for_out_of_bounds shortens the move against the walls and the other
; objects, handle_exit_screen checks for a walk out of the room (and does not
; come back if there is one), and add_dXYZ adds what is left to the position. A
; move downwards that was stopped (bit 2 of +$0C) is a landing, and ends the
; jump.
move_player_apply:
  DEC A                   ; the first unit
  LD (IX+$0B),A           ; new dZ, and the intended dZ in $5BC1
  LD ($5BC1),A
  ADD A,$02                 ; falling faster than 2: the falling sound
  CALL M,sound_pitch_from_z ;
  CALL adj_for_out_of_bounds ; cut the move short where it must be
  CALL handle_exit_screen ; out of the room?
  CALL add_dXYZ           ; X, Y, Z += dX, dY, dZ
  BIT 2,(IX+$0C)          ; stopped while moving down?
  JR Z,clear_dX_dY
  LD A,($5BC1)
  AND A
  JP P,clear_dX_dY
  RES 3,(IX+$0C)          ; then landed: the jump is over

; Clear dX and dY
;
; Used by the routines at settle_charm, upd_62, dec_dZ_upd_XYZ_wipe_if_moving
; and move_player_apply.
;
; dX and dY are one frame's movement, so once applied they go back to zero.
; Also the end of several other objects' updates.
clear_dX_dY:
  XOR A
  LD (IX+$09),A
  LD (IX+$0A),A
  RET

; Add a step in the facing direction
;
; Used by the routine at move_player_walk.
;
; First adds in the nudge in +$0E and +$0F, which an archway leaves there
; (arch_nudge_loop) to steer the player towards the middle of the arch, and
; clears it. Then dispatches on the facing to add 3 units in that direction.
; The nudge is only ever used when the player is walking.
calc_plyr_dXY:
  LD A,(IX+$09)           ; dX += nudge X, dY += nudge Y
  ADD A,(IX+$0E)
  LD (IX+$09),A
  LD A,(IX+$0A)
  ADD A,(IX+$0F)
  LD (IX+$0A),A
  XOR A                   ; the nudge is used up
  LD (IX+$0E),A           ;
  LD (IX+$0F),A           ;
  LD BC,walk_step_tbl     ; the table of steps, walk_step_tbl

; Jump by the object's facing
;
; Used by the routines at arch_nudge_loop and handle_exit_screen.
;
; Jumps to the entry in the table of four addresses at BC chosen by the facing
; of the object at IX, in the order W, E, N, S. Used for the player's step
; (walk_step_tbl), for leaving a room (screen_move_tbl), and by the archways
; (arch_nudge_loop), which have facings of their own.
;
; BC a table of four routine addresses
; IX the object
dispatch_on_facing:
  CALL get_sprite_dir
  LD L,A
  JP jump_to_tbl_entry

; Which way does the object face?
;
; Used by the routines at chk_facing_N, chk_facing_E, chk_facing_S,
; chk_facing_W and dispatch_on_facing.
;
; Builds the facing code from the two bits that store it: bit 6 of +$07 (the
; sprite is mirrored) becomes bit 1, and bit 3 of the type (front view) becomes
; bit 0. So 0 is W, 1 E, 2 N and 3 S.
;
; IX the object
; A on exit, the facing: 0 W, 1 E, 2 N, 3 S
get_sprite_dir:
  LD A,(IX+$07)           ; mirror bit to bit 4
  RRCA
  RRCA
  AND $10
  LD L,A
  LD A,(IX+$00)           ; with type bit 3
  AND $08
  OR L                    ; down to bits 1 and 0
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  AND $03                 ;
  RET                     ;

; A step in each direction
;
; Four addresses, one per facing, used through dispatch_on_facing by
; calc_plyr_dXY. Each adds 3 to or takes 3 from dX or dY: X grows eastwards and
; Y northwards.
walk_step_tbl:
  DEFW move_plyr_W        ; W: dX - 3
  DEFW move_plyr_E        ; E: dX + 3
  DEFW move_plyr_N        ; N: dY + 3
  DEFW move_plyr_S        ; S: dY - 3

; Step west
;
; dX - 3.
move_plyr_W:
  LD A,(IX+$09)           ; -3
  ADD A,$FD

; Store dX
;
; Used by the routine at move_plyr_E.
;
; Shared end of move_plyr_W and move_plyr_E.
store_plyr_dX:
  LD (IX+$09),A
  RET

; Step east
;
; dX + 3.
move_plyr_E:
  LD A,(IX+$09)           ; +3
  ADD A,$03
  JR store_plyr_dX

; Step north
;
; dY + 3.
move_plyr_N:
  LD A,(IX+$0A)           ; +3
  ADD A,$03

; Store dY
;
; Used by the routine at move_plyr_S.
;
; Shared end of move_plyr_N and move_plyr_S.
store_plyr_dY:
  LD (IX+$0A),A
  RET

; Step south
;
; dY - 3.
move_plyr_S:
  LD A,(IX+$0A)           ; -3
  ADD A,$FD
  JR store_plyr_dY

; Shorten dZ at the floor
;
; Used by the routine at adj_for_out_of_bounds.
;
; The floor is the only limit on Z: there is no ceiling. $5BAE holds the
; floor's height, $80 in all three room sizes. A move that would take the
; object's base below it is shortened a unit at a time until it would not, and
; bit 2 of +$0C records that the move was stopped.
;
; IX the object
; H dZ
; H on exit, dZ shortened
adj_dZ_for_out_of_bounds:
  LD A,($5BAE)            ; D = the floor
  LD D,A

; Shorten dZ at the floor: the loop
;
; The loop for adj_dZ_for_out_of_bounds.
clip_dZ_to_floor:
  LD A,(IX+$03)           ; Z + dZ at or above the floor: done
  ADD A,H
  CP D
  RET NC
  SET 2,(IX+$0C)          ; stopped in Z
  LD A,H                  ; one unit shorter, and try again unless nothing is
  CALL shorten_delta      ; left
  LD H,A                  ;
  JR NZ,clip_dZ_to_floor  ;
  RET                     ; no move left

; Has the player walked out of the room?
;
; Used by the routine at move_player_apply.
;
; A room can be left only through an archway, and only walking the way the
; player faces. An archway sets bit 0 of +$07 on the player while he is close
; to it (chk_plyr_spec_near_arch); this clears it and dispatches through
; screen_move_tbl on the facing. Each of the four routines there decides
; whether this frame's move carries the player wholly past the line of the
; wall.
;
; The room's half-sizes from $5BAB are pushed for them, because the dispatch
; uses HL.
;
; IX the player's bottom record
handle_exit_screen:
  LD A,(IX+$0C)           ; not during the room-entry walk
  AND $F0
  RET NZ
  BIT 0,(IX+$07)          ; not near an archway; the flag is used once
  RET Z
  RES 0,(IX+$07)
  LD BC,screen_move_tbl   ; the room's X and Y half-sizes, for the exit
  LD HL,($5BAB)           ; routines
  PUSH HL                 ;
  JP dispatch_on_facing   ;

; Shorten a movement by one unit
;
; Used by the routines at clip_dZ_to_floor, dX_obj_shorten, dY_obj_shorten,
; dZ_obj_shorten, clip_dX_test and clip_dY_test.
;
; Moves A one step towards zero -- down if positive, up if negative -- and
; leaves Z set if nothing is left. Every loop in the collision code uses it to
; cut a move short one unit at a time and try again.
;
; A a dX, dY or dZ
; A on exit, one unit closer to zero; Z set if zero
shorten_delta:
  AND A                   ; already zero
  RET Z                   ;
  JP P,shorten_delta_dec  ; negative: +2 and then -1
  INC A
  INC A

; Shorten a movement: subtract one
;
; Used by the routine at shorten_delta.
;
; The DEC that sets the zero flag for shorten_delta.
shorten_delta_dec:
  DEC A
  RET

; Leaving a room, by facing
;
; Four addresses in facing order, used through dispatch_on_facing by
; handle_exit_screen.
screen_move_tbl:
  DEFW screen_west        ; W: screen_west
  DEFW screen_east        ; E: screen_east
  DEFW screen_north       ; N: screen_north
  DEFW screen_south       ; S: screen_south

; Leave by the west wall?
;
; Out if the player's east edge, after this frame's move, is west of the west
; wall at $80 less the room's X half-size. The new room is one west: the low
; nibble of the room number less one, wrapping within its row.
;
; X is set to 0, which is not a position but a marker:
; adjust_plyr_xyz_for_room_size sees it when the new room is built and puts the
; player in the doorway of that room's east wall, at the height of the arch
; there. The Y markers work the same way, $FF for the south wall and 0 for the
; north.
;
; HL the room's half-sizes (pushed by handle_exit_screen)
screen_west:
  POP HL                  ; L = the west wall
  LD A,$80                ;
  SUB L                   ;
  LD L,A                  ;
  LD A,(IX+$01)           ; X + dX + half-width still at or beyond it: stay
  ADD A,(IX+$09)
  ADD A,(IX+$04)
  CP L
  RET NC
  LD (IX+$01),$00         ; arrive at the east wall
  LD A,(IX+$08)           ; room - 1
  LD L,A
  DEC A

; Keep an east-west move within the row
;
; Used by the routine at screen_east.
;
; Room numbers are a row in the high nibble and a column in the low. The column
; is changed on its own so that it wraps without disturbing the row.
screen_e_w:
  AND $0F                 ; the new column with the old row
  LD H,A
  LD A,L
  AND $F0
  OR H

; Go into the next room
;
; Used by the routines at screen_north and screen_south.
;
; Gives the object its new room number and starts the room-entry walk: 3 in the
; top nibble of +$0C, three frames of walking straight in with the controls and
; the room's walls ignored, so the player clears the archway.
;
; For the player -- type 16 to 79, both forms and both halves -- the rest of
; this frame is abandoned. The two return addresses on the stack, to
; move_player_apply and player_move_and_draw, are dropped, and both player
; records are copied to plyr_spr_1_scratchpad and plyr_spr_2_scratchpad: the
; player as he entered this room, which lose_life copies back when a life is
; lost, so he reappears at the door he came in by. The copies' types are
; replaced by 120, the first frame of the materialising sparkle, with the real
; types kept in +$10 for upd_127 to restore. Then the new room is built from
; game_loop.
;
; Only the player reaches this code in this build, so the return for other
; types is never taken.
;
; A the new room number
exit_screen:
  LD (IX+$08),A           ; new room
  LD A,(IX+$0C)           ; the room-entry walk: three frames
  OR $30
  LD (IX+$0C),A
  LD A,(IX+$00)           ; anything but the player: carry on
  SUB $10
  CP $40
  RET NC
  INC SP                  ; drop the returns to the rest of this frame
  INC SP                  ;
  INC SP                  ;
  INC SP                  ;
  PUSH IX                     ; both player records to the respawn copy
  POP HL                      ;
  LD DE,plyr_spr_1_scratchpad ;
  LD BC,$0040                 ;
  LDIR                        ;
  LD A,(plyr_spr_1_scratchpad) ; each copy's real type kept in its +$10
  LD (plyr_spr_1_tail),A       ;
  LD A,(plyr_spr_2_scratchpad)
  LD (plyr_spr_2_tail),A
  LD A,$78                ; and replaced by the materialising sparkle
  LD (plyr_spr_1_scratchpad),A
  LD (plyr_spr_2_scratchpad),A
  JP game_loop            ; build the new room and start its frames

; Leave by the east wall?
;
; As screen_west the other way: out if the west edge after the move is at or
; past the east wall at $80 plus the X half-size. X is set to the marker $FF
; (arrive at the west wall) and the room number goes up one within the row.
;
; HL the room's half-sizes (pushed by handle_exit_screen)
screen_east:
  POP HL                  ; L = the east wall
  LD A,L                  ;
  ADD A,$80               ;
  LD L,A                  ;
  LD A,(IX+$01)           ; X + dX - half-width short of it: stay
  ADD A,(IX+$09)
  SUB (IX+$04)
  CP L
  RET C
  LD (IX+$01),$FF         ; arrive at the west wall
  LD A,(IX+$08)           ; room + 1
  LD L,A
  INC A
  JR screen_e_w

; Leave by the north wall?
;
; Out if the south edge after the move is at or past the north wall at $80 plus
; the Y half-size. Y becomes the marker $FF (arrive at the south wall) and the
; room number goes up a row, 16.
;
; HL the room's half-sizes (pushed by handle_exit_screen)
screen_north:
  POP HL                  ; H = the north wall
  LD A,H                  ;
  ADD A,$80               ;
  LD H,A                  ;
  LD A,(IX+$02)           ; Y + dY - half-depth short of it: stay
  ADD A,(IX+$0A)
  SUB (IX+$05)
  CP H
  RET C
  LD (IX+$02),$FF         ; arrive at the south wall
  LD A,(IX+$08)           ; room + 16
  ADD A,$10
  JR exit_screen

; Leave by the south wall?
;
; Out if the north edge after the move is south of the south wall at $80 less
; the Y half-size. Y becomes the marker 0 (arrive at the north wall) and the
; room number goes down a row.
;
; HL the room's half-sizes (pushed by handle_exit_screen)
screen_south:
  POP HL                  ; H = the south wall
  LD A,$80                ;
  SUB H                   ;
  LD H,A                  ;
  LD A,(IX+$02)           ; Y + dY + half-depth still at or beyond it: stay
  ADD A,(IX+$0A)
  ADD A,(IX+$05)
  CP H
  RET NC
  LD (IX+$02),$00         ; arrive at the north wall
  LD A,(IX+$08)           ; room - 16
  SUB $10
  JP exit_screen

; Cut a move short against the room and the other objects
;
; Used by the routines at dec_dZ_and_update_XYZ and move_player_apply.
;
; Every moving object's move comes through here, the player's from
; move_player_apply and everyone else's from dec_dZ_and_update_XYZ. It takes
; dX, dY and dZ from the record and shortens each where the object would
; otherwise end up inside the floor, a wall, or another object, then writes
; them back.
;
; The axes are done one at a time, Z first, then X, then Y, and each test uses
; the moves already accepted on the earlier axes (the later ones count as
; zero). That is what lets a blocked move slide: walking diagonally into a wall
; keeps the part of the move that runs along it.
;
; While it works, bit 1 of the object's +$07 is set, which is what makes the
; object scans (is_object_not_ignored) pass over the object itself; found
; already set, it means the object is not to be moved this way at all. Bits 0-2
; of +$0C are cleared at the start and set for each axis whose move was cut.
;
; IX the object
adj_for_out_of_bounds:
  BIT 1,(IX+$07)          ; not for objects marked to be ignored; and ignore
  RET NZ                  ; ourself while we work
  SET 1,(IX+$07)          ;
  LD A,(IX+$0C)           ; clear the three "stopped" bits
  AND $F8                 ;
  LD (IX+$0C),A           ;
  LD L,$00                ; dY and dX count as zero while Z is tested
  LD C,L                  ;
  LD A,(IX+$0B)           ; H = dZ; nothing to do if zero
  AND A
  LD H,A
  JR Z,dZ_ok
  CALL adj_dZ_for_out_of_bounds ; the floor first; nothing left means no
  LD A,H                        ; objects to test
  AND A                         ;
  JR Z,dZ_ok                    ;
  CALL adj_dZ_for_obj_intersect ; then the other objects

; Cut a move short: X
;
; Used by the routine at adj_for_out_of_bounds.
;
; The X part of adj_for_out_of_bounds, with C as the working dX. dZ is final by
; now, and may have been changed by landing on a moving object
; (dZ_obj_hit_test), so dX is read from the record only here.
dZ_ok:
  LD A,(IX+$09)           ; C = dX; nothing to do if zero
  AND A
  LD C,A
  JR Z,dX_done
  CALL adj_dX_for_out_of_bounds ; the walls first; nothing left means no
  LD A,C                        ; objects to test
  AND A                         ;
  JR Z,dX_done                  ;
  CALL adj_dX_for_obj_intersect ; then the other objects

; Cut a move short: Y
;
; Used by the routine at dZ_ok.
;
; The Y part of adj_for_out_of_bounds, with L as the working dY and the final
; dX and dZ in C and H.
dX_done:
  LD A,(IX+$0A)           ; L = dY; nothing to do if zero
  AND A
  LD L,A
  JR Z,store_clipped_move
  CALL adj_dY_for_out_of_bounds ; the walls first; nothing left means no
  LD A,L                        ; objects to test
  AND A                         ;
  JR Z,store_clipped_move       ;
  CALL adj_dY_for_obj_intersect ; then the other objects

; Store the move as cut
;
; Used by the routine at dX_done.
;
; Writes back the three shortened movements and takes the object's "ignore me"
; bit off again.
store_clipped_move:
  LD (IX+$09),C           ; dX, dY, dZ
  LD (IX+$0A),L
  LD (IX+$0B),H
  RES 1,(IX+$07)          ; other objects' scans may find us again
  RET

; Shorten dX against the other objects
;
; Used by the routine at dZ_ok.
;
; Tries the object's box against every one of the forty records. For each one
; it already overlaps in Y and Z -- with the moves accepted so far -- an
; overlap in X after the move means dX has to be shortened, a unit at a time,
; until the boxes no longer meet. If dX reaches zero the scan stops.
;
; Every such meeting also passes harm between the two (see dX_obj_hit_test)
; and, if the obstacle can be pushed (bit 2 of its +$07), gives it the mover's
; whole intended dX, so it moves off on its own next update.
;
; IX the moving object
; C dX
; L dY so far (zero)
; H dZ as accepted
; C on exit, dX shortened
adj_dX_for_obj_intersect:
  LD IY,$5C08             ; IY = the first record; forty of them
  LD B,$28

; Shorten dX: is this object in line?
;
; Used by the routine at dX_obj_next.
;
; Skips empty records and those marked to be ignored, and those not overlapping
; in Y and in Z. Only an object in line on both can stop an X move.
dX_obj_loop:
  CALL is_object_not_ignored ; empty, or marked to be ignored
  JR Z,dX_obj_next
  CALL do_objs_intersect_on_y ; not overlapping in Y or not in Z
  JR NC,dX_obj_next           ;
  CALL do_objs_intersect_on_z ;
  JR NC,dX_obj_next           ;

; Shorten dX: does the move hit it?
;
; Used by the routine at dX_obj_shorten.
;
; If the boxes would overlap in X too, the move is stopped (bit 0 of +$0C) and
; harm passes. Bit 6 of +$0D means "has been harmed": the obstacle gets it if
; the mover has bit 7 (harms what it runs into), and the mover gets it if the
; obstacle has bit 5 (harms what runs into it). This is how the player dies of
; a guard or of spikes: upd_player_bottom watches bit 6.
dX_obj_hit_test:
  CALL do_objs_intersect_on_x ; no overlap in X: next object
  JR NC,dX_obj_next           ;
  SET 0,(IX+$0C)          ; stopped in X
  LD A,(IX+$0D)           ; mover's bit 7 becomes the obstacle's bit 6
  RRCA
  AND $40
  OR (IY+$0D)
  LD (IY+$0D),A
  RLCA                    ; obstacle's bit 5 becomes the mover's bit 6
  AND $40                 ;
  OR (IX+$0D)             ;
  LD (IX+$0D),A           ;
  BIT 2,(IY+$07)          ; a pushable obstacle takes on our dX
  JR Z,dX_obj_shorten
  LD A,(IX+$09)
  LD (IY+$09),A

; Shorten dX by one and try the same object again
;
; Used by the routine at dX_obj_hit_test.
;
; Returns from the whole scan once nothing of dX is left.
dX_obj_shorten:
  LD A,C                  ; shorter by a unit; none left, done
  CALL shorten_delta      ;
  LD C,A                  ;
  RET Z                   ;
  JR dX_obj_hit_test      ;

; Shorten dX: the next object
;
; Used by the routines at dX_obj_loop and dX_obj_hit_test.
;
; Steps IY on to the next 32-byte record.
dX_obj_next:
  LD DE,$0020             ; next of forty
  ADD IY,DE
  DJNZ dX_obj_loop
  RET

; Shorten dY against the other objects
;
; Used by the routine at dX_done.
;
; adj_dX_for_obj_intersect for Y: an object has to overlap in X (after the
; accepted dX) and in Z to be in the way. Stopping sets bit 1 of +$0C.
;
; IX the moving object
; L dY
; C dX as accepted
; H dZ as accepted
; L on exit, dY shortened
adj_dY_for_obj_intersect:
  LD IY,$5C08             ; IY = the first record; forty of them
  LD B,$28

; Shorten dY: is this object in line?
;
; Used by the routine at dY_obj_next.
;
; Skips empty and ignored records, and those not overlapping in X and Z.
dY_obj_loop:
  CALL is_object_not_ignored ; empty, or marked to be ignored
  JR Z,dY_obj_next
  CALL do_objs_intersect_on_x ; not overlapping in X or not in Z
  JR NC,dY_obj_next           ;
  CALL do_objs_intersect_on_z ;
  JR NC,dY_obj_next           ;

; Shorten dY: does the move hit it?
;
; Used by the routine at dY_obj_shorten.
;
; As dX_obj_hit_test, for Y: stopped in Y is bit 1 of +$0C, harm passes the
; same way, and a pushable obstacle takes on the mover's dY.
dY_obj_hit_test:
  CALL do_objs_intersect_on_y ; no overlap in Y: next object
  JR NC,dY_obj_next
  SET 1,(IX+$0C)          ; stopped in Y
  LD A,(IX+$0D)           ; mover's bit 7 becomes the obstacle's bit 6
  RRCA
  AND $40
  OR (IY+$0D)
  LD (IY+$0D),A
  RLCA                    ; obstacle's bit 5 becomes the mover's bit 6
  AND $40                 ;
  OR (IX+$0D)             ;
  LD (IX+$0D),A           ;
  BIT 2,(IY+$07)          ; a pushable obstacle takes on our dY
  JR Z,dY_obj_shorten
  LD A,(IX+$0A)
  LD (IY+$0A),A

; Shorten dY by one and try the same object again
;
; Used by the routine at dY_obj_hit_test.
;
; Returns from the whole scan once nothing of dY is left.
dY_obj_shorten:
  LD A,L                  ; shorter by a unit; none left, done
  CALL shorten_delta      ;
  LD L,A                  ;
  RET Z                   ;
  JR dY_obj_hit_test      ;

; Shorten dY: the next object
;
; Used by the routines at dY_obj_loop and dY_obj_hit_test.
;
; Steps IY on to the next 32-byte record.
dY_obj_next:
  LD DE,$0020             ; next of forty
  ADD IY,DE
  DJNZ dY_obj_loop
  RET

; Shorten dZ against the other objects
;
; Used by the routine at adj_for_out_of_bounds.
;
; adj_dX_for_obj_intersect for Z, done before X and Y so it tests the object
; where it stands: an object has to overlap in X and in Y (with no horizontal
; move yet) to be above or below it. Stopping sets bit 2 of +$0C, whether the
; move was up or down.
;
; IX the moving object
; H dZ
; C dX, zero here
; L dY, zero here
; H on exit, dZ shortened
adj_dZ_for_obj_intersect:
  LD IY,$5C08             ; IY = the first record; forty of them
  LD B,$28

; Shorten dZ: is this object above or below?
;
; Used by the routine at dZ_obj_next.
;
; Skips empty and ignored records, and those not overlapping in X and Y.
dZ_obj_loop:
  CALL is_object_not_ignored ; empty, or marked to be ignored
  JR Z,dZ_obj_next
  CALL do_objs_intersect_on_x ; not overlapping in X or not in Y
  JR NC,dZ_obj_next           ;
  CALL do_objs_intersect_on_y ;
  JR NC,dZ_obj_next           ;

; Shorten dZ: does the move hit it?
;
; Used by the routine at dZ_obj_shorten.
;
; As dX_obj_hit_test, and two things more. The obstacle gets bit 3 of its +$0D:
; something has come down on it (or up against it). A block that gives way when
; stood on, upd_91, waits for that bit. And a mover that can be carried -- bit
; 2 of +$07, which the player has -- takes on the obstacle's dX and dY wherever
; its own are zero, so standing on something that moves carries it along.
dZ_obj_hit_test:
  CALL do_objs_intersect_on_z ; no overlap in Z: next object
  JR NC,dZ_obj_next
  SET 2,(IX+$0C)          ; stopped in Z
  LD A,(IX+$0D)           ; harm passes both ways, as in X
  RRCA
  AND $40
  OR (IY+$0D)
  LD (IY+$0D),A
  RLCA
  AND $40
  OR (IX+$0D)
  LD (IX+$0D),A
  SET 3,(IY+$0D)          ; the obstacle has been landed on
  BIT 2,(IX+$07)          ; not a mover that can be carried
  JR Z,dZ_obj_shorten
  LD A,(IX+$09)           ; no dX of our own: ride with the obstacle's
  AND A
  JR NZ,dZ_ride_dY
  LD A,(IY+$09)
  LD (IX+$09),A

; Shorten dZ: ride with the obstacle's dY
;
; Used by the routine at dZ_obj_hit_test.
;
; The Y half of being carried by the object underneath.
dZ_ride_dY:
  LD A,(IX+$0A)           ; no dY of our own: ride with the obstacle's
  AND A
  JR NZ,dZ_obj_shorten
  LD A,(IY+$0A)
  LD (IX+$0A),A

; Shorten dZ by one and try the same object again
;
; Used by the routines at dZ_obj_hit_test and dZ_ride_dY.
;
; Returns from the whole scan once nothing of dZ is left.
dZ_obj_shorten:
  LD A,H                  ; shorter by a unit; none left, done
  CALL shorten_delta      ;
  LD H,A                  ;
  RET Z                   ;
  JR dZ_obj_hit_test      ;

; Shorten dZ: the next object
;
; Used by the routines at dZ_obj_loop and dZ_obj_hit_test.
;
; Steps IY on to the next 32-byte record.
dZ_obj_next:
  LD DE,$0020             ; next of forty
  ADD IY,DE
  DJNZ dZ_obj_loop
  RET

; Do two objects overlap in X?
;
; Used by the routines at overlap_test_obj, is_on_or_near_obj, dX_obj_hit_test,
; dY_obj_loop and dZ_obj_loop.
;
; Boxes are centred on X and Y, with +$04 and +$05 the half-sizes. They overlap
; in X if the distance between the centres, after the mover's dX, is less than
; the two half-widths added: exactly touching is not overlapping. Also used by
; overlap_test_obj and is_on_or_near_obj.
;
; IX the moving object
; IY the other object
; C the mover's dX
; F carry set on exit if they overlap
do_objs_intersect_on_x:
  LD A,(IX+$04)           ; D = the two half-widths
  ADD A,(IY+$04)
  LD D,A
  LD A,(IX+$01)           ; A = |X + dX - other X|
  ADD A,C
  SUB (IY+$01)
  JP P,intersect_x_result
  NEG

; Overlap in X: compare
;
; Used by the routine at do_objs_intersect_on_x.
;
; Carry if the distance is less than the sum.
intersect_x_result:
  SUB D
  RET

; Do two objects overlap in Y?
;
; Used by the routines at overlap_test_obj, is_on_or_near_obj, dX_obj_loop,
; dY_obj_hit_test and dZ_obj_loop.
;
; do_objs_intersect_on_x for Y, with the mover's dY in L and the half-depths at
; +$05.
;
; IX the moving object
; IY the other object
; L the mover's dY
; F carry set on exit if they overlap
do_objs_intersect_on_y:
  LD A,(IX+$05)           ; D = the two half-depths
  ADD A,(IY+$05)
  LD D,A
  LD A,(IX+$02)           ; A = |Y + dY - other Y|
  ADD A,L
  SUB (IY+$02)
  JP P,intersect_y_result
  NEG

; Overlap in Y: compare
;
; Used by the routine at do_objs_intersect_on_y.
;
; Carry if the distance is less than the sum.
intersect_y_result:
  SUB D
  RET

; Do two objects overlap in Z?
;
; Used by the routines at overlap_test_obj, is_on_or_near_obj, dX_obj_loop,
; dY_obj_loop and dZ_obj_hit_test.
;
; Not centred like X and Y: Z is an object's base and +$06 its whole height. So
; the test takes the gap between the two bases and compares it with the height
; of whichever object is lower. The player's top half has a height of 0, which
; is why it is kept out of the scans while the legs move
; (player_move_and_draw): the legs, 23 high, would find it inside them.
;
; IX the moving object
; IY the other object
; H the mover's dZ
; F carry set on exit if they overlap
do_objs_intersect_on_z:
  LD A,(IX+$03)           ; A = Z + dZ - other Z
  ADD A,H
  SUB (IY+$03)
  JP P,intersect_z_above  ; we are the lower one: our height
  NEG
  LD D,(IX+$06)

; Overlap in Z: compare
;
; Used by the routine at intersect_z_above.
;
; Carry if the gap between the bases is less than the lower object's height.
intersect_z_result:
  SUB D
  RET

; Overlap in Z: the other object is lower
;
; Used by the routine at do_objs_intersect_on_z.
;
; Uses the other object's height.
intersect_z_above:
  LD D,(IY+$06)           ; its height
  JR intersect_z_result   ;

; Shorten dX at the walls
;
; Used by the routine at dZ_ok.
;
; Keeps the whole of the object's footprint between the room's east and west
; walls, $80 plus and minus the X half-size in $5BAB, shortening dX a unit at a
; time and setting bit 0 of +$0C if it had to.
;
; Two things switch the walls off: the room-entry walk (the top nibble of +$0C)
; and being near an archway (bit 0 of +$07, set by chk_plyr_spec_near_arch).
; That is how the player walks into an arch at all -- and why only the arch's
; own pillars, which are objects, then stop him.
;
; IX the object
; C dX
; C on exit, dX shortened
adj_dX_for_out_of_bounds:
  LD A,(IX+$0C)           ; not during the room-entry walk
  AND $F0
  RET NZ
  BIT 0,(IX+$07)          ; not near an archway
  RET NZ
  LD A,($5BAB)            ; B = the X half-size
  LD B,A

; Shorten dX at the walls: distance from the centre
;
; Used by the routine at clip_dX_test.
;
; The loop for adj_dX_for_out_of_bounds, from the distance from the room's
; centre after the move.
clip_dX_to_walls:
  LD A,(IX+$01)           ; A = |X + dX - $80|
  ADD A,C
  SUB $80
  JR NC,clip_dX_test
  NEG

; Shorten dX at the walls: test and shorten
;
; Used by the routine at clip_dX_to_walls.
;
; Inside if the distance plus the half-width is less than the half-size.
clip_dX_test:
  ADD A,(IX+$04)          ; inside: done
  CP B
  JR C,dX_ok
  SET 0,(IX+$0C)          ; stopped in X
  LD A,C                  ; one unit shorter, and again unless nothing is left
  CALL shorten_delta      ;
  LD C,A                  ;
  JR NZ,clip_dX_to_walls  ;

; Shorten dX at the walls: done
;
; Used by the routine at clip_dX_test.
;
; The end of adj_dX_for_out_of_bounds, with C the dX that fits.
dX_ok:
  RET

; Shorten dY at the walls
;
; Used by the routine at dX_done.
;
; adj_dX_for_out_of_bounds for Y: the north and south walls from $5BAC, the
; half-depth at +$05, and bit 1 of +$0C.
;
; IX the object
; L dY
; L on exit, dY shortened
adj_dY_for_out_of_bounds:
  LD A,(IX+$0C)           ; not during the room-entry walk
  AND $F0
  RET NZ
  BIT 0,(IX+$07)          ; not near an archway
  RET NZ
  LD A,($5BAC)            ; B = the Y half-size
  LD B,A

; Shorten dY at the walls: distance from the centre
;
; Used by the routine at clip_dY_test.
;
; The loop for adj_dY_for_out_of_bounds.
clip_dY_to_walls:
  LD A,(IX+$02)           ; A = |Y + dY - $80|
  ADD A,L
  SUB $80
  JR NC,clip_dY_test
  NEG

; Shorten dY at the walls: test and shorten
;
; Used by the routine at clip_dY_to_walls.
;
; Inside if the distance plus the half-depth is less than the half-size.
clip_dY_test:
  ADD A,(IX+$05)          ; inside: done
  CP B
  JR C,dY_ok
  SET 1,(IX+$0C)          ; stopped in Y
  LD A,L                  ; one unit shorter, and again unless nothing is left
  CALL shorten_delta      ;
  LD L,A                  ;
  JR NZ,clip_dY_to_walls  ;

; Shorten dY at the walls: done
;
; Used by the routine at clip_dY_test.
;
; The end of adj_dY_for_out_of_bounds, with L the dY that fits.
dY_ok:
  RET

; Work out an object's screen rectangle
;
; Used by the routine at set_draw_objs_overlapped.
;
; Fills in the four bytes that say where an object's sprite lands in the screen
; buffer: the pixel position at +$1A and +$1B (from calc_pixel_XY) and the size
; at +$18 (width in bytes) and +$19 (height in pixel rows). The width is the
; sprite's own, plus one byte when the x position is not a multiple of eight,
; because a sprite shifted across a byte boundary spills into the next byte.
;
; flip_sprite also turns the sprite the way the object's flip bits ask for.
; When the object's sprite is the empty one (types 0 and 1 both use it),
; flip_sprite discards this routine's return address and goes straight back to
; the caller, so the size bytes keep their previous values. That is what an
; object that is vanishing wants: the area it last covered is still the area to
; clear.
;
; IX the object
calc_2d_info:
  CALL calc_pixel_XY      ; pixel position into +$1A/+$1B; DE = the sprite,
  CALL flip_sprite        ; flipped to match
  LD A,(IX+$1A)           ; Z set if the sprite starts on a byte boundary
  AND $07
  LD A,(DE)               ; the sprite's width byte (flip flags in the top
  INC DE                  ; bits)
  JR Z,store_2d_size      ; one byte wider when shifted
  INC A

; Store the sprite's width and height
;
; Used by the routine at calc_2d_info.
;
; The tail of calc_2d_info: masks the flip flags off the width and stores the
; width and the sprite's height.
store_2d_size:
  AND $0F                 ; +$18 = width in bytes
  LD (IX+$18),A
  LD A,(DE)               ; +$19 = height in pixel rows
  LD (IX+$19),A           ;
  RET                     ;

; Mark every object the moving object's old or new rectangle touches
;
; Used by the routines at set_wipe_and_draw_flags and head_on_shoulders.
;
; Called once an object has moved or changed sprite. It works out the object's
; new screen rectangle, forms the smallest rectangle that covers both that and
; the one it had at the start of the frame (saved at +$1C to +$1F by
; save_2d_info), and then walks all forty object records setting the redraw
; flag, bit 4 of +$07, on every live object whose current rectangle overlaps it
; -- including the moving object itself, if it is not marked already.
;
; Horizontally the rectangles are measured in byte columns (pixel x divided by
; 8), vertically in pixel rows counted up from the bottom. At the end of this
; entry E is the union's first column and D its width in columns;
; union_right_edge to union_height go on to put its lowest row in L and its
; height in H.
;
; Only the moving object's own rectangle is used. An object that is redrawn
; because it overlaps it does not in turn mark the objects that overlap it.
;
; IX the object that has moved
set_draw_objs_overlapped:
  LD IY,$5C08             ; IY = object 0; new rectangle into +$18 to +$1B
  CALL calc_2d_info       ;
  LD B,$28                ; forty objects to test
  LD A,(IX+$1A)           ; L = the new first column
  RRCA
  RRCA
  RRCA
  AND $1F
  LD L,A
  LD A,(IX+$1E)           ; H = the old first column
  RRCA
  RRCA
  RRCA
  AND $1F
  LD H,A
  CP L                    ; A = whichever is further left
  JR C,union_right_edge   ;
  LD A,L                  ;

; Union rectangle: right-hand edge
;
; Used by the routine at set_draw_objs_overlapped.
;
; Part of set_draw_objs_overlapped. Keeps the left edge in E and finds the
; further right of the two right-hand edges.
union_right_edge:
  LD E,A                  ; E = left edge; L = new right edge
  LD A,L                  ;
  ADD A,(IX+$18)          ;
  LD L,A                  ;
  LD A,H                  ; A = old right edge
  ADD A,(IX+$1C)          ;
  CP L                     ; take the larger
  JR NC,union_width_bottom ;
  LD A,L                   ;

; Union rectangle: width, and the lower edge
;
; Used by the routine at union_right_edge.
;
; Part of set_draw_objs_overlapped. D becomes the union's width in columns;
; then the lower of the two bottom rows is chosen.
union_width_bottom:
  SUB E                   ; D = width in byte columns
  LD D,A                  ;
  LD A,(IX+$1B)           ; new bottom row lower than the old one?
  CP (IX+$1F)
  JR C,union_top_edge     ; no: use the old one
  LD A,(IX+$1F)

; Union rectangle: the upper edge
;
; Used by the routine at union_width_bottom.
;
; Part of set_draw_objs_overlapped. L holds the union's bottom row; this finds
; the higher of the two top rows.
union_top_edge:
  LD L,A                  ; H = new top (bottom row plus height)
  LD A,(IX+$1B)           ;
  ADD A,(IX+$19)          ;
  LD H,A                  ;
  LD A,(IX+$1F)           ; A = old top
  ADD A,(IX+$1D)
  CP H                    ; take the larger
  JR NC,union_height      ;
  LD A,H                  ;

; Union rectangle: the height
;
; Used by the routine at union_top_edge.
;
; Part of set_draw_objs_overlapped. H becomes the union's height in pixel rows,
; and the walk through the objects begins.
union_height:
  SUB L                   ; H = height
  LD H,A                  ;

; Test one object against the union rectangle
;
; Used by the routine at next_overlap_obj.
;
; IY is the object under test. An empty record (type 0) is skipped, and so is
; one already marked for redrawing. Otherwise its current rectangle is compared
; with the union: in each direction, if the object starts inside the union its
; offset from the union's start must be less than the union's size, and if it
; starts before the union the distance back must be less than the object's own
; size. Both directions overlapping means the object must be redrawn.
;
; IY the object to test
; E the union's first column, D its width in columns
; L the union's bottom row, H its height in rows
test_overlap_obj:
  LD A,(IY+$00)           ; skip empty records
  AND A
  JR Z,next_overlap_obj
  BIT 4,(IY+$07)          ; skip objects already marked for redrawing
  JR NZ,next_overlap_obj
  LD A,(IY+$1A)           ; A = the object's first column
  RRCA
  RRCA
  RRCA
  AND $1F
  SUB E                   ; columns from the union's left edge; negative if it
  JR C,obj_starts_left    ; starts to the left
  CP D                    ; does it start beyond the union's right edge?

; Horizontal overlap decided
;
; Used by the routine at obj_starts_left.
;
; Part of test_overlap_obj, and where obj_starts_left rejoins it: no carry from
; the last comparison means no horizontal overlap. Then the same for the rows.
overlap_x_decided:
  JR NC,next_overlap_obj  ; clear of the union horizontally
  LD A,(IY+$1B)           ; rows from the union's bottom edge; negative if it
                          ; starts below
  SUB L
  JR C,obj_starts_below   ; does it start above the union's top?
  CP H

; Vertical overlap decided: mark the object
;
; Used by the routine at obj_starts_below.
;
; Part of test_overlap_obj, and where obj_starts_below rejoins it. An object
; that overlaps in both directions gets the redraw flag.
overlap_y_decided:
  JR NC,next_overlap_obj  ; clear of the union vertically
  SET 4,(IY+$07)          ; bit 4 of +$07: draw this object again this frame

; Next object for the overlap test
;
; Used by the routines at test_overlap_obj, overlap_x_decided and
; overlap_y_decided.
;
; Part of test_overlap_obj. The union rectangle lives in D, E, H and L, so the
; step to the next record is done in the other register set.
next_overlap_obj:
  EXX                     ; IY += 32, without disturbing DE and HL
  LD DE,$0020             ;
  ADD IY,DE               ;
  EXX                     ;
  DJNZ test_overlap_obj   ; round all forty
  RET                     ;

; Object starts to the left of the union
;
; Used by the routine at test_overlap_obj.
;
; Part of test_overlap_obj. The object's first column is before the union's; it
; overlaps if the gap is less than its own width in columns.
obj_starts_left:
  NEG                     ; columns by which it starts to the left, against its
  CP (IY+$18)             ; width
  JR overlap_x_decided    ; carry means overlap

; Object starts below the union
;
; Used by the routine at overlap_x_decided.
;
; Part of test_overlap_obj. The object's bottom row is below the union's; it
; overlaps if the gap is less than its own height.
obj_starts_below:
  NEG                     ; rows by which it starts below, against its height
  CP (IY+$19)             ;
  JR overlap_y_decided    ; carry means overlap

; Object types 32 to 47: the knight's head
;
; The player is two objects: legs in record 0 and head in record 1. Types 32 to
; 47 are the knight's heads. This sets the head sprite's pixel offset (-8, -12)
; and joins the shared head code at upd_player_top.
;
; IX the head object (record 1)
upd_32_to_47:
  CALL adj_m8_m12         ; offsets to +$12/+$13
  JR upd_player_top       ;

; Object types 64 to 79: the werewolf's head
;
; As upd_32_to_47 for the werewolf's heads, with a pixel offset of (-12, -12);
; falls into upd_player_top.
;
; IX the head object (record 1)
upd_64_to_79:
  CALL adj_m12_m12        ; offsets to +$12/+$13

; Update the player's head
;
; Used by the routine at upd_32_to_47.
;
; The head has no movement of its own: it copies the legs. First, unless the
; game has been won ($5BC3), a head whose kill flag (bit 6 of +$0D) has been
; set -- by the legs' handler at upd_player_bottom when the legs are killed --
; turns into the death sparkle at init_death_sparkles.
;
; IX the head object (record 1)
upd_player_top:
  LD A,($5BC3)            ; once the game is won the player cannot die
  AND A                   ;
  JR NZ,head_follows_legs ;
  BIT 6,(IX+$0D)            ; killed: become the sparkle
  JP NZ,init_death_sparkles ;

; The head follows the legs
;
; Used by the routine at upd_player_top.
;
; Copies the legs' position, size and flags into the head -- so the head
; inherits the legs' redraw, wipe and flip bits and is wiped and redrawn with
; them -- then gives the head a height of zero and sets its bit 1, which takes
; it out of every collision test. The legs' record carries the whole body's
; height, so the head never needs to collide with anything.
;
; Then the choice of head sprite. The low nibble of +$0D is a countdown: while
; it is running the head keeps the sprite it has.
head_follows_legs:
  PUSH IX                 ; DE = the head; IY = HL = the legs, one record below
  POP DE                  ;
  LD HL,$FFE0             ;
  ADD HL,DE               ;
  PUSH HL                 ;
  POP IY                  ;
  INC DE                  ; copy +$01 to +$07: X, Y, Z, the three half-sizes,
  INC HL                  ; flags
  LD BC,$0007             ;
  LDIR                    ;
  LD (IX+$06),$00         ; height 0
  SET 1,(IX+$07)          ; bit 1: ignored by collision tests
  LD A,(IX+$0D)           ; countdown running?
  AND $0F
  JR Z,choose_head_sprite ; yes: count it down and keep the current head
  DEC (IX+$0D)
  JR head_on_shoulders

; Choose the head sprite
;
; Used by the routine at head_follows_legs.
;
; Normally the head is the legs' type plus 16: the same creature, facing and
; animation frame. About one frame in 64 (the random byte at $5BA5 being 0 or
; 1, or $FE or $FF) the head is given one of two other frames of its type group
; instead -- frame 6 or frame 7 -- which it then holds for eight frames. The
; legs only ever use frames 0 to 5, so frames 6 and 7 exist only as heads. What
; the two look like has not been checked against the sprites.
choose_head_sprite:
  LD A,($5BA5)            ; random byte below 2: frame 6
  CP $02
  JR C,head_frame_six
  CP $FE                  ; $FE or above: frame 7
  JR NC,head_frame_seven
  LD A,(IY+$00)           ; otherwise the legs' type

; Set the head's sprite
;
; Used by the routine at hold_head_frame.
;
; Adds 16 to a legs type to make the matching head type, and stores it.
;
; A a legs type
set_top_sprite:
  ADD A,$10               ; head type = legs type + 16
  LD (IX+$00),A

; Put the head on the shoulders
;
; Used by the routine at head_follows_legs.
;
; The head's Z is twelve above the legs'. Then the rectangle work of
; set_draw_objs_overlapped, so the head and whatever it overlaps are redrawn.
head_on_shoulders:
  LD A,(IY+$03)           ; Z = legs' Z + 12
  ADD A,$0C
  LD (IX+$03),A
  CALL set_draw_objs_overlapped ; mark what the head's old and new rectangles
                                ; touch
  RET

; Head frame 6
;
; Used by the routine at choose_head_sprite.
;
; Part of choose_head_sprite: the legs' type with the frame replaced by 6.
head_frame_six:
  LD A,(IY+$00)           ; the legs' type group, frame 6
  AND $F8                 ;
  OR $06

; Hold the chosen head frame
;
; Used by the routine at head_frame_seven.
;
; Part of choose_head_sprite: starts the eight-frame countdown and sets the
; head.
hold_head_frame:
  LD (IX+$0D),$08
  JR set_top_sprite

; Head frame 7
;
; Used by the routine at choose_head_sprite.
;
; Part of choose_head_sprite: the legs' type with the frame replaced by 7.
head_frame_seven:
  LD A,(IY+$00)           ; the legs' type group, frame 7
  AND $F8                 ;
  OR $07
  JR hold_head_frame

; Remember an object's screen rectangle
;
; Used by the routine at update_sprite_loop.
;
; Called by the main loop at update_sprite_loop for every object before its
; handler runs: copies the current width, height and pixel position (+$18 to
; +$1B) to +$1C to +$1F. Whatever the handler then does,
; set_draw_objs_overlapped can compare the new rectangle with the one the
; object had at the start of the frame, and render_dynamic_objects knows which
; area to wipe.
;
; IX the object
save_2d_info:
  LD A,(IX+$18)           ; +$18..+$1B to +$1C..+$1F
  LD (IX+$1C),A
  LD A,(IX+$19)
  LD (IX+$1D),A
  LD A,(IX+$1A)
  LD (IX+$1E),A
  LD A,(IX+$1B)
  LD (IX+$1F),A
  RET

; List the objects to be drawn this frame
;
; Used by the routine at end_of_frame.
;
; At the end of a frame, writes to objects_to_draw the index (0 to 39) of every
; live object whose redraw flag is set, in table order, and an $FF after the
; last. render_dynamic_objects wipes from this list and
; calc_display_order_and_render draws from it.
list_objects_to_draw:
  PUSH IX                 ; IX = object 0, HL = the list, C = index
  LD B,$28                ;
  LD DE,$0020             ;
  LD IX,$5C08             ;
  LD HL,objects_to_draw   ;
  LD C,$00                ;

; Test one object for the draw list
;
; Used by the routine at list_next_obj.
;
; Part of list_objects_to_draw: an object is listed if its record is in use and
; its redraw flag is set.
list_test_obj:
  LD A,(IX+$00)           ; empty record?
  AND A
  JR Z,list_next_obj
  BIT 4,(IX+$07)          ; redraw flag (bit 4 of +$07) clear?
  JR Z,list_next_obj
  LD (HL),C               ; add this index
  INC HL                  ;

; Next object for the draw list
;
; Used by the routine at list_test_obj.
;
; Part of list_objects_to_draw.
list_next_obj:
  INC C                   ; on to the next record
  ADD IX,DE               ;
  DJNZ list_test_obj      ;
  LD A,$FF                ; terminate the list
  LD (HL),A               ;
  POP IX                  ;
  RET                     ;

; The objects to draw this frame
;
; Filled by list_objects_to_draw: object indices (0 to 39), then $FF. While
; calc_display_order_and_render works through the list it sets bit 7 of each
; entry as that object is drawn, so the same list says what is still to do. 48
; bytes leaves room for all forty and the terminator.
objects_to_draw:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; Draw the listed objects, back to front
;
; Used by the routine at draw_and_copy_rects.
;
; This is where Knight Lore decides what is in front of what. Every listed
; object is an axis-aligned box in the room: centre X and Y with half-sizes at
; +$04 and +$05, and a base Z with a height at +$06. On the screen +X runs down
; and to the right and +Y up and to the right, so the far side of anything is
; towards smaller X, larger Y and smaller Z.
;
; It repeatedly takes the first object in objects_to_draw not yet drawn as the
; candidate (IX) and compares it with every other undrawn one (IY). If some IY
; has to be drawn before the candidate, IY becomes the candidate and the
; comparison starts again from the top of the list; when a candidate survives a
; full pass it is drawn, marked done, and the whole thing starts over. So each
; draw is of an object with nothing undrawn behind it.
;
; The comparison classifies the two boxes on each axis into IX clear on the
; near side, overlapping, or IY clear on the near side, and combines the three
; into an index 0 to 26 into depth_order_tbl. The rule the table encodes: IY
; must go first when, on every axis, IY is either further back than IX or
; overlapping it, and is further back on at least one. Any other arrangement
; places no constraint on the pair.
;
; The order found need not be consistent -- three boxes can each be behind the
; next -- so the chain of candidates is recorded in candidate_chain, and
; meeting an object already in it breaks the cycle by drawing that object at
; once (break_order_cycle).
;
; $5BBE counts the objects drawn; end_of_frame uses it to pace the frame.
calc_display_order_and_render:
  XOR A                   ; no objects drawn yet
  LD ($5BBE),A            ;
  PUSH IX                 ;
  PUSH IY                 ;

; Start a pass: find the first object not yet drawn
;
; Used by the routines at find_iy_entry and render_obj.
;
; Re-entered after every object is drawn. Every entry before the first undrawn
; one is drawn, so comparing the candidate with only the entries after it
; covers every undrawn object.
process_remaining_objs:
  LD DE,objects_to_draw   ; from the top of the list

; Skip entries already drawn
;
; Part of process_remaining_objs. The end of the list means everything is
; drawn.
skip_drawn_entries:
  LD A,(DE)               ; end of the list: finished
  INC DE                  ;
  CP $FF                  ;
  JP Z,render_done        ;
  BIT 7,A                  ; bit 7: already drawn
  JR NZ,skip_drawn_entries ;
  CALL get_ptr_object     ; IX = the candidate; $5BCD points just past its
  LD ($5BCD),DE           ; entry
  PUSH HL                 ;
  POP IX                  ;

; Compare the candidate with the next undrawn object
;
; Used by the routines at order_unconstrained, candidate_already_first,
; iy_becomes_candidate and coincide_done.
;
; IY is each other undrawn object in turn. If the end of the list is reached
; nothing has to be drawn before the candidate, and it is drawn by
; render_obj_no1.
;
; C collects the comparison. On the Z axis (base +$03, height +$06): 0 if the
; candidate's base is at or above IY's top, 2 if IY's base is at or above the
; candidate's top, otherwise 1.
;
; IX the candidate
; DE the next entry to compare with
compare_next_obj:
  LD A,(DE)               ; end of the list: nothing is behind the candidate
  INC DE                  ;
  CP $FF                  ;
  JP Z,render_obj_no1     ;
  BIT 7,A                 ; already drawn: skip
  JR NZ,compare_next_obj  ;
  CALL get_ptr_object     ; IY = this object; $5BCF points just past its entry
  LD ($5BCF),DE           ;
  PUSH HL                 ;
  POP IY                  ;
  PUSH IX                 ;
  POP BC                  ;
  AND A                   ; the candidate itself: skip
  SBC HL,BC               ;
  JR Z,compare_next_obj   ;
  LD C,$00                ; L = IY's top
  LD A,(IY+$03)           ;
  ADD A,(IY+$06)          ;
  LD L,A                  ; candidate's base at or above IY's top: Z code 0
  LD A,(IX+$03)           ;
  SUB L                   ;
  JR NC,compare_along_y   ;
  LD A,(IX+$03)           ; L = the candidate's top
  ADD A,(IX+$06)
  LD L,A
  LD A,(IY+$03)           ; IY's base at or above it: Z code 2
  SUB L
  JR C,z_code_overlap
  INC C

; Z code: the boxes overlap in height
;
; Used by the routine at compare_next_obj.
;
; Part of compare_next_obj. Reached with C at 0 for overlap, or at 1 to make 2.
z_code_overlap:
  INC C                   ; Z code 1 (or 2)

; Compare the boxes along Y
;
; Used by the routine at compare_next_obj.
;
; Part of compare_next_obj. Along Y (centre +$02, half-size +$05) the code adds
; 0 if the candidate's low-Y edge is at or beyond IY's high-Y edge -- the
; candidate lies wholly further back -- 6 if IY lies wholly further back, and 3
; if they overlap.
compare_along_y:
  LD A,(IY+$02)           ; L = IY's high-Y edge
  ADD A,(IY+$05)
  LD L,A                  ; candidate's low-Y edge at or beyond it: add 0
  LD A,(IX+$02)           ;
  SUB (IX+$05)            ;
  SUB L                   ;
  JR NC,compare_along_x   ;
  LD A,(IX+$02)           ; L = the candidate's high-Y edge
  ADD A,(IX+$05)
  LD L,A                  ; IY's low-Y edge at or beyond it: add 6, otherwise 3
  LD A,(IY+$02)           ;
  SUB (IY+$05)            ;
  SUB L                   ;
  LD A,C                  ;
  JR C,add_y_code         ;
  ADD A,$03               ;

; Add the Y code
;
; Used by the routine at compare_along_y.
;
; Part of compare_along_y: entered with 3 already added for the separated case,
; or not for the overlapping one.
add_y_code:
  ADD A,$03               ; Y code 3 (or 6)
  LD C,A

; Compare the boxes along X
;
; Used by the routine at compare_along_y.
;
; Part of compare_next_obj. Along X (centre +$01, half-size +$04) the code adds
; 0 if the candidate's low-X edge is at or beyond IY's high-X edge -- IY lies
; wholly further back -- 18 if the candidate lies wholly further back, and 9 if
; they overlap.
compare_along_x:
  LD A,(IY+$01)           ; L = IY's high-X edge
  ADD A,(IY+$04)
  LD L,A                  ; candidate's low-X edge at or beyond it: add 0
  LD A,(IX+$01)           ;
  SUB (IX+$04)            ;
  SUB L                   ;
  JR NC,act_on_comparison ;
  LD A,(IX+$01)           ; L = the candidate's high-X edge
  ADD A,(IX+$04)
  LD L,A                  ; IY's low-X edge at or beyond it: add 18, otherwise
  LD A,(IY+$01)           ; 9
  SUB (IY+$04)            ;
  SUB L                   ;
  LD A,C                  ;
  JR C,add_x_code         ;
  ADD A,$09               ;

; Add the X code
;
; Used by the routine at compare_along_x.
;
; Part of compare_along_x: entered with 9 already added for the separated case,
; or not for the overlapping one.
add_x_code:
  ADD A,$09               ; X code 9 (or 18)
  LD C,A                  ;

; Act on the comparison
;
; Used by the routine at compare_along_x.
;
; Part of compare_next_obj. C is now Z code + Y code + X code, 0 to 26; jump
; through depth_order_tbl.
act_on_comparison:
  LD L,C                  ; via jump_to_tbl_entry
  LD BC,depth_order_tbl   ;
  JP jump_to_tbl_entry    ;

; What to do about a pair of boxes
;
; 27 addresses, indexed by Z code (0 candidate above, 1 overlap, 2 IY above) +
; Y code (0 candidate further back, 3 overlap, 6 IY further back) + X code (0
; IY further back, 9 overlap, 18 candidate further back). "Further back" means
; further from the viewer: smaller X, larger Y, lower Z.
;
; Three outcomes. iy_goes_first when IY is behind or level with the candidate
; on all three axes and strictly behind on at least one: IY must be drawn
; first. candidate_already_first for the mirror image, where the candidate is
; behind IY -- it is already being drawn first, so nothing to do.
; order_unconstrained where each is in front of the other on some axis, which
; says nothing about their order. The last two are the same instruction; the
; table distinguishes them only in which entry it names. Index 13, overlapping
; on every axis, goes to objs_coincide.
depth_order_tbl:
  DEFW order_unconstrained ; 0: Z0 Y0 X0 -- no constraint
  DEFW order_unconstrained ; 1: Z1 Y0 X0 -- no constraint
  DEFW order_unconstrained ; 2: Z2 Y0 X0 -- no constraint
  DEFW iy_goes_first      ; 3: Z0 Y3 X0 -- IY first
  DEFW iy_goes_first      ; 4: Z1 Y3 X0 -- IY first
  DEFW order_unconstrained ; 5: Z2 Y3 X0 -- no constraint
  DEFW iy_goes_first      ; 6: Z0 Y6 X0 -- IY first
  DEFW iy_goes_first      ; 7: Z1 Y6 X0 -- IY first
  DEFW order_unconstrained ; 8: Z2 Y6 X0 -- no constraint
  DEFW order_unconstrained ; 9: Z0 Y0 X9 -- no constraint
  DEFW candidate_already_first ; 10: Z1 Y0 X9 -- candidate first
  DEFW candidate_already_first ; 11: Z2 Y0 X9 -- candidate first
  DEFW iy_goes_first      ; 12: Z0 Y3 X9 -- IY first
  DEFW objs_coincide      ; 13: Z1 Y3 X9 -- the boxes intersect
  DEFW candidate_already_first ; 14: Z2 Y3 X9 -- candidate first
  DEFW iy_goes_first      ; 15: Z0 Y6 X9 -- IY first
  DEFW iy_goes_first      ; 16: Z1 Y6 X9 -- IY first
  DEFW order_unconstrained ; 17: Z2 Y6 X9 -- no constraint
  DEFW order_unconstrained ; 18: Z0 Y0 X18 -- no constraint
  DEFW candidate_already_first ; 19: Z1 Y0 X18 -- candidate first
  DEFW candidate_already_first ; 20: Z2 Y0 X18 -- candidate first
  DEFW order_unconstrained ; 21: Z0 Y3 X18 -- no constraint
  DEFW candidate_already_first ; 22: Z1 Y3 X18 -- candidate first
  DEFW candidate_already_first ; 23: Z2 Y3 X18 -- candidate first
  DEFW order_unconstrained ; 24: Z0 Y6 X18 -- no constraint
  DEFW order_unconstrained ; 25: Z1 Y6 X18 -- no constraint
  DEFW order_unconstrained ; 26: Z2 Y6 X18 -- no constraint

; Pair with no order between them
;
; Each box is in front of the other along some axis, so neither has to be drawn
; first. Go on to the next object.
order_unconstrained:
  JP compare_next_obj     ; next comparison

; Candidate is behind the other object
;
; The candidate is to be drawn before IY, which is what will happen anyway.
; Identical to order_unconstrained.
candidate_already_first:
  JP compare_next_obj     ; next comparison

; The other object must be drawn first
;
; IY is behind the candidate, so it becomes the candidate instead -- unless it
; is already in the chain of objects that have been candidates since the last
; draw (candidate_chain), in which case the order has gone round in a circle
; and break_order_cycle draws it straight away.
iy_goes_first:
  LD HL,($5BCF)           ; C = IY's index, from its entry in the list
  DEC HL
  LD C,(HL)
  LD DE,candidate_chain   ; search the chain

; Search the candidate chain
;
; Part of iy_goes_first.
search_chain:
  LD A,(DE)                 ; end of the chain: IY is new to it
  CP $FF                    ;
  JR Z,iy_becomes_candidate ;
  CP C                    ; already in the chain: a cycle
  JR Z,break_order_cycle  ;
  INC DE                  ; next
  JR search_chain         ;

; IY becomes the candidate
;
; Used by the routine at search_chain.
;
; Part of iy_goes_first: adds IY to the chain, makes it the candidate, and
; compares it with the whole list from the top, since it may not be the first
; undrawn entry.
;
; Nothing checks the chain's length. candidate_chain has room for seven indices
; and the terminator; an eighth link would put its $FF terminator over the
; first byte of check_user_input. How long a chain real rooms can produce has
; not been measured.
iy_becomes_candidate:
  LD A,C                  ; append IY's index and a new terminator
  LD (DE),A               ;
  INC DE                  ;
  LD A,$FF                ;
  LD (DE),A               ;
  PUSH IY                 ; IX = IY; $5BCD = $5BCF
  POP IX                  ;
  LD HL,($5BCF)           ;
  LD ($5BCD),HL           ;
  LD DE,objects_to_draw   ; compare from the top of the list
  JP compare_next_obj     ;

; Break a cycle in the order
;
; Used by the routine at search_chain.
;
; Part of iy_goes_first. IY has been the candidate before in this chain, so
; there is no order that satisfies every pair; draw IY now. The search below
; only finds IY's own entry in the list again -- $5BCF - 1 already addressed it
; -- and so its exit on reaching the end cannot be taken.
break_order_cycle:
  LD HL,objects_to_draw   ; from the top of the list

; Find IY's entry and draw it
;
; Part of break_order_cycle.
find_iy_entry:
  LD A,(HL)                   ; not found at all: start a new pass
  INC HL                      ;
  CP $FF                      ;
  JP Z,process_remaining_objs ;
  CP C                    ; look for IY's index
  JR NZ,find_iy_entry     ;
  PUSH IY                 ; IX = IY, and draw it; HL points just past its entry
  POP IX                  ;
  JR render_obj           ;

; Two boxes occupy the same space
;
; Index 13 of depth_order_tbl: the boxes overlap on all three axes. Order does
; not come into it. If either is one of the seven collectable objects (types 96
; to 102), that object is turned into type 187, whose handler at upd_185_187
; removes it from the list of special objects for good and makes it vanish. The
; candidate is checked first; only one of the pair is changed.
objs_coincide:
  LD A,(IX+$00)           ; candidate a collectable?
  SUB $60                 ;
  CP $07
  JR NC,check_iy_collectable
  LD (IX+$00),$BB         ; yes: destroy it
  JR coincide_done

; Is the other one a collectable?
;
; Used by the routine at objs_coincide.
;
; Part of objs_coincide.
check_iy_collectable:
  LD A,(IY+$00)           ; IY a collectable?
  SUB $60                 ;
  CP $07
  JR NC,coincide_done
  LD (IY+$00),$BB         ; yes: destroy it

; Continue after two boxes intersect
;
; Used by the routines at objs_coincide and check_iy_collectable.
;
; Part of objs_coincide: carry on comparing, with no order imposed.
coincide_done:
  JP compare_next_obj     ; next comparison

; Draw the candidate
;
; Used by the routine at compare_next_obj.
;
; The end of the list was reached with nothing found that has to be drawn
; before the candidate: draw it. HL is the pointer just past its entry, which
; render_obj marks.
render_obj_no1:
  LD HL,($5BCD)           ; HL = just past the candidate's entry

; Draw an object and start the next pass
;
; Used by the routine at find_iy_entry.
;
; Marks the object's entry drawn, empties the candidate chain, counts the
; object in $5BBE, and draws it with calc_pixel_XY_and_render -- which clears
; its redraw flag, or deletes it if it is of type 1. Then back to the top of
; the list for the next.
;
; IX the object to draw
; HL just past its entry in objects_to_draw
render_obj:
  DEC HL                  ; bit 7 of the entry: drawn
  SET 7,(HL)              ;
  LD A,$FF                ; the chain is empty again
  LD (candidate_chain),A
  LD HL,$5BBE             ; one more object drawn this frame
  INC (HL)                ;
  CALL calc_pixel_XY_and_render ; draw it; then the next pass
  JP process_remaining_objs

; All listed objects drawn
;
; Used by the routine at skip_drawn_entries.
;
; Part of calc_display_order_and_render.
render_done:
  POP IY                  ; restore the caller's IX and IY
  POP IX                  ;
  RET                     ;

; The chain of candidates since the last draw
;
; Object indices, ended by $FF, of every object that iy_becomes_candidate has
; made the candidate since render_obj last drew something. iy_goes_first looks
; for an object here before making it the candidate: finding it means the depth
; order has a cycle. The first byte is set to $FF after every draw, so between
; frames the list is always empty. The object the pass began with is not
; recorded, so a cycle back to it is caught one step later, at the next object
; in the loop.
candidate_chain:
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF

; Read the controls
;
; Used by the routine at player_controls.
;
; Reads whichever control method the menu chose (bits 1 and 2 of $5BA4: 0
; keyboard, 1 Kempston, 2 cursor keys, 3 Interface II) into one byte of bits
; that means the same whichever it came from, and stores it at $5BB5. The legs'
; handler at upd_player_bottom calls this every frame and also uses the byte as
; it is returned, in C.
;
; The bits: 0 turn left, 1 turn right, 2 walk forward, 3 jump, 4 pick up or
; drop, 5 any key but the number keys, Caps Shift and Space. On a joystick with
; the menu's directional option set (bit 3 of $5BA4), bits 0, 1, 2 and 4 are
; instead the four directions of the stick, and bit 5 takes over picking up and
; dropping -- see chk_pickup_drop and handle_left_right. The directional option
; has no effect with the keyboard method.
;
; While the game is won ($5BC3) or an object is falling into the cauldron
; ($5BC4) the controls are ignored: the byte is 0 apart from bit 5.
;
; C on exit, the control bits (also at $5BB5)
check_user_input:
  LD A,($5BC3)            ; C = 0; A non-zero if the controls are frozen
  LD C,A                  ;
  LD A,($5BC4)            ;
  OR C                    ;
  LD C,$00                ;
  JP NZ,finished_input    ; frozen: straight to the end, where only bit 5 is
                          ; read
  LD A,($5BA4)            ; A = the control method, 0 to 3
  RRCA                    ;
  AND $03                 ;
  JP Z,keyboard
  DEC A
  JR Z,kempston
  DEC A
  JR Z,cursor

; Interface II joysticks
;
; Both of the Interface II's joysticks are read, and either will do. The one is
; the keys 1 to 5 (left, right, down, up, fire) and the other 6 to 0 in the
; same order. The two half-rows come in with their keys in opposite orders, so
; the 1 to 5 bits are reversed first to line up with 6 to 0.
interface_ii:
  LD A,$F7                ; half-row 1 to 5
  CALL read_port
  PUSH BC                 ; five bits to reverse, keeping B
  LD B,$05                ;

; Reverse the 1 to 5 bits
;
; Part of interface_ii. After this, bit 0 is 5 (fire), 1 is 4 (up), 2 is 3
; (down), 3 is 2 (right), 4 is 1 (left) -- the same meanings as the 0 to 6
; half-row's bits.
reverse_if2_bits:
  RRA                     ; one bit out of A into the bottom of C
  RL C                    ;
  DJNZ reverse_if2_bits   ;
  LD A,C                  ; C = the reversed bits
  POP BC                  ;
  LD C,A                  ;
  LD A,$EF                ; combine with half-row 0 to 6
  CALL read_port
  OR C
  LD C,$00                ; fire (5 or 0): jump, bit 3
  BIT 0,A
  JR Z,if2_up
  SET 3,C

; Interface II up
;
; Used by the routine at reverse_if2_bits.
;
; Part of interface_ii.
if2_up:
  BIT 1,A                 ; up (4 or 9): forward, bit 2
  JR Z,if2_down           ;
  SET 2,C                 ;

; Interface II down
;
; Used by the routine at if2_up.
;
; Part of interface_ii.
if2_down:
  BIT 2,A                 ; down (3 or 8): bit 4
  JR Z,if2_right          ;
  SET 4,C                 ;

; Interface II right
;
; Used by the routine at if2_down.
;
; Part of interface_ii.
if2_right:
  BIT 3,A                 ; right (2 or 7): bit 1
  JR Z,if2_left           ;
  SET 1,C                 ;

; Interface II left
;
; Used by the routine at if2_right.
;
; Part of interface_ii.
if2_left:
  BIT 4,A                 ; left (1 or 6): bit 0
  JR Z,if2_done           ;
  SET 0,C                 ;

; Interface II done
;
; Used by the routine at if2_left.
;
; Part of interface_ii.
if2_done:
  JP finished_input       ; on to the common ending

; Kempston joystick
;
; Used by the routine at check_user_input.
;
; The Kempston interface answers on port $1F with the stick's switches active
; high: bit 0 right, 1 left, 2 down, 3 up, 4 fire.
kempston:
  IN A,($1F)              ; read the stick
  LD C,$00                ;
  BIT 0,A                 ; right: bit 1
  JR Z,kempston_left      ;
  SET 1,C                 ;

; Kempston left
;
; Used by the routine at kempston.
;
; Part of kempston.
kempston_left:
  BIT 1,A                 ; left: bit 0
  JR Z,kempston_down      ;
  SET 0,C                 ;

; Kempston down
;
; Used by the routine at kempston_left.
;
; Part of kempston.
kempston_down:
  BIT 2,A                 ; down: bit 4
  JR Z,kempston_up        ;
  SET 4,C                 ;

; Kempston up
;
; Used by the routine at kempston_down.
;
; Part of kempston.
kempston_up:
  BIT 3,A                 ; up: forward, bit 2
  JR Z,kempston_fire      ;
  SET 2,C                 ;

; Kempston fire
;
; Used by the routine at kempston_up.
;
; Part of kempston.
kempston_fire:
  BIT 4,A                 ; fire: jump, bit 3
  JR Z,kempston_done      ;
  SET 3,C                 ;

; Kempston done
;
; Used by the routine at kempston_fire.
;
; Part of kempston.
kempston_done:
  JP finished_input       ; on to the common ending

; Cursor keys
;
; Used by the routine at check_user_input.
;
; The cursor keys on the number row: 5 left, 6 down, 7 up, 8 right, with 0 as
; fire.
cursor:
  LD C,$00                ; half-row 1 to 5
  LD A,$F7
  CALL read_port
  BIT 4,A                 ; 5 (left): bit 0
  JR Z,cursor_second_row  ;
  SET 0,C                 ;

; Cursor keys: the 6 to 0 half-row
;
; Used by the routine at cursor.
;
; Part of cursor.
cursor_second_row:
  LD A,$EF                ; half-row 0 to 6
  CALL read_port
  BIT 0,A                 ; 0 (fire): jump, bit 3
  JR Z,cursor_up          ;
  SET 3,C                 ;

; Cursor up
;
; Used by the routine at cursor_second_row.
;
; Part of cursor.
cursor_up:
  BIT 3,A                 ; 7 (up): forward, bit 2
  JR Z,cursor_right       ;
  SET 2,C                 ;

; Cursor right
;
; Used by the routine at cursor_up.
;
; Part of cursor.
cursor_right:
  BIT 2,A                 ; 8 (right): bit 1
  JR Z,cursor_down        ;
  SET 1,C                 ;

; Cursor down
;
; Used by the routine at cursor_right.
;
; Part of cursor.
cursor_down:
  BIT 4,A                 ; 6 (down): bit 4
  JR Z,finished_input     ;
  SET 4,C                 ;
  JR finished_input       ;

; Keyboard
;
; Used by the routine at check_user_input.
;
; The whole keyboard is in use, a pair of half-rows to each action. The bottom
; row alternates: Z, C, B and M turn left, X, V, N and Symbol Shift turn right.
; A to G and H to Enter walk forward, Q to T and Y to P jump, and the number
; keys pick up and drop. Caps Shift and Space are left alone -- they are the
; pause keys (handle_pause).
keyboard:
  LD A,$FE                ; half-row Caps..V; Z to bit 0, X to bit 1, C to bit
  CALL read_port          ; 2, V to bit 3
  RRCA                    ;
  LD C,A                  ; Z and X
  AND $03                 ;
  SRL C                   ; fold C onto Z and V onto X
  SRL C                   ;
  OR C                    ;
  AND $03                 ;
  LD C,A                  ; C = left and right so far; half-row B..Space
  LD A,$7F                ;
  CALL read_port          ;
  BIT 1,A                 ; Symbol Shift: right
  JR Z,keyboard_m         ;
  SET 1,C                 ;

; Keyboard: M
;
; Used by the routine at keyboard.
;
; Part of keyboard.
keyboard_m:
  BIT 2,A                 ; M: left
  JR Z,keyboard_n         ;
  SET 0,C                 ;

; Keyboard: N
;
; Used by the routine at keyboard_m.
;
; Part of keyboard.
keyboard_n:
  BIT 3,A                 ; N: right
  JR Z,keyboard_b         ;
  SET 1,C                 ;

; Keyboard: B
;
; Used by the routine at keyboard_n.
;
; Part of keyboard.
keyboard_b:
  BIT 4,A                 ; B: left
  JR Z,keyboard_forward   ;
  SET 0,C                 ;

; Keyboard: walk forward
;
; Used by the routine at keyboard_b.
;
; Part of keyboard. $BD selects two half-rows at once, A to G and H to Enter;
; any key in either sets the bit.
keyboard_forward:
  LD A,$BD                ; any of A..G, H..Enter: forward, bit 2
  CALL read_port          ;
  JR Z,keyboard_jump      ;
  SET 2,C

; Keyboard: jump
;
; Used by the routine at keyboard_forward.
;
; Part of keyboard.
keyboard_jump:
  LD A,$DB                ; any of Q..T, Y..P: jump, bit 3
  CALL read_port          ;
  JR Z,keyboard_pickup    ;
  SET 3,C

; Keyboard: pick up and drop
;
; Used by the routine at keyboard_jump.
;
; Part of keyboard.
keyboard_pickup:
  LD A,$E7                ; any number key: bit 4
  CALL read_port          ;
  JR Z,finished_input     ;
  SET 4,C

; Finish reading the controls
;
; Used by the routines at check_user_input, if2_done, kempston_done,
; cursor_down and keyboard_pickup.
;
; Common to every method. Bit 5 is set if any key is down other than the number
; keys, Caps Shift and Space. It is the pick-up key for a joystick in
; directional mode, where bit 4 is a direction. The byte is stored at $5BB5.
finished_input:
  LD A,$7E                ; bottom two half-rows together, less Caps Shift and
  CALL read_port          ; Space
  AND $1E
  PUSH BC                 ; or'd with the A..G, Q..T, Y..P and H..Enter
  LD B,A                  ; half-rows
  LD A,$99                ;
  CALL read_port          ;
  OR B                    ;
  POP BC                  ;
  JR Z,store_input        ; any of them: bit 5
  SET 5,C                 ;

; Store the control bits
;
; Used by the routine at finished_input.
;
; Part of finished_input.
store_input:
  LD A,C                  ; $5BB5 = the control bits, also left in C
  LD ($5BB5),A            ;
  RET                     ;

; Start a life
;
; Used by the routine at player_dies.
;
; Reached at the start of every game and after every death (player_dies). Puts
; the player's two saved records from plyr_spr_1_scratchpad back into object
; records 0 and 1 -- the legs and head as they were on entering the current
; room, but with the materialising type -- and takes a life from $5BBA. When
; the count goes below zero the game is over.
;
; The game begins with $5BBA at 5, and this first call takes it to 4, so the
; player has five lives: the fifth death ends the game. Touching the extra-life
; object (type 103, upd_103) adds one.
;
; The saved records say what the legs and head become once they have
; materialised (+$10). That is corrected here for the time of day: knight by
; day, werewolf by night (bit 0 of the sun and moon's type at
; sun_moon_scratchpad). Werewolf types are the knight's plus 32, so the
; creature bit is replaced and the frame and facing kept. A transformation that
; was pending ($5BB1) is cancelled, as the new body is already the right one.
lose_life:
  LD HL,plyr_spr_1_scratchpad ; copy both 32-byte records; IX = object 0
  LD DE,$5C08                 ;
  PUSH DE
  POP IX
  LD BC,$0040
  LDIR
  XOR A                   ; no transformation pending
  LD ($5BB1),A            ;
  LD HL,$5BBA             ; one life fewer; below zero is game over
  DEC (HL)                ;
  JP M,game_over          ;
  LD A,(sun_moon_scratchpad) ; C = 32 at night, 0 by day
  RRCA
  RRCA
  RRCA
  AND $20
  LD C,A
  LD A,(IX+$10)           ; legs: knight legs type (16 to 31), plus 32 at night
  AND $1F
  ADD A,C
  LD (IX+$10),A
  LD A,(IX+$30)           ; head: knight head type (32 to 47), plus 32 at night
  AND $0F
  ADD A,C
  ADD A,$20
  LD (IX+$30),A
  RET

; The saved legs record: bytes 0 to 7
;
; This block and the next four, up to plyr_spr_init_data, are two 32-byte
; object records -- the player's legs and head -- that lose_life copies over
; records 0 and 1 to start a life. init_start_location fills them at the start
; of a game; each time the player leaves a room, exit_screen saves the live
; records here, with the type moved to +$10 and the materialising type 120 put
; in its place. So after a death the player reappears in the room he last
; entered, where he entered it.
;
; This block is bytes 0 to 7 of the legs: type, X, Y, Z, the X and Y
; half-sizes, height, flags.
plyr_spr_1_scratchpad:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; The saved legs record: room and movement
;
; Bytes 8 to 11 of the saved legs record at plyr_spr_1_scratchpad: the room
; number, then three bytes (+$09 to +$0B) that the movement code uses for its
; X, Y and Z steps. init_start_location sets the room.
start_loc_1:
  DEFB $00,$00,$00,$00

; The saved legs record: bytes 12 to 15
;
; Bytes 12 to 15 of the saved legs record at plyr_spr_1_scratchpad. +$0C holds
; movement state bits. exit_screen sets its top nibble to 3 before saving, and
; the legs' handler counts it down by one a frame: while it is non-zero the
; turn and jump controls are ignored, the legs keep walking, and the
; room-boundary check at adj_dX_for_out_of_bounds is skipped -- which is
; presumably what walks him in through the doorway. main clears this byte for
; each new game.
flags12_1:
  DEFB $00,$00,$00,$00

; The saved legs record: bytes 16 to 31
;
; The rest of the saved legs record at plyr_spr_1_scratchpad. The first byte
; (+$10) is the type the legs take once they have materialised:
; init_start_location sets 18, knight legs standing, and lose_life adjusts it
; for the time of day.
plyr_spr_1_tail:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; The saved head record: bytes 0 to 7
;
; The head's saved record, laid out as the legs' at plyr_spr_1_scratchpad:
; type, X, Y, Z, the X and Y half-sizes, height, flags.
plyr_spr_2_scratchpad:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; The saved head record: bytes 8 to 15
;
; +$08 is the room number, set by init_start_location to match the legs.
start_loc_2:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; The saved head record: bytes 16 to 31
;
; The first byte (+$10) is the type the head takes once it has materialised:
; init_start_location sets 34, and lose_life adjusts it for the time of day.
plyr_spr_2_tail:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; The player's records at the start of a game
;
; The first eight bytes of the legs' and head's records, copied to
; plyr_spr_1_scratchpad and plyr_spr_2_scratchpad by init_start_location. Both
; start as type 120, the first frame of materialising, in the middle of the
; room ($80, $80). The legs stand on Z $80 with half-sizes of 5 and a height of
; 23 -- the whole knight -- and the head sits 12 higher with a height of 0.
; Flags: both redraw (bit 4), and the head is ignored by collisions (bit 1);
; bits 2 and 3 are set in both and are not yet worked out here.
plyr_spr_init_data:
  DEFB $78,$80,$80,$80,$05,$05,$17,$1C ; legs: type, X, Y, Z, X half-size, Y
                                       ; half-size, height, flags
  DEFB $78,$80,$80,$8C,$05,$05,$00,$1E ; head: type, X, Y, Z, X half-size, Y
                                       ; half-size, height, flags

; Set up the player for a new game
;
; Used by the routine at main.
;
; Fills the saved records at plyr_spr_1_scratchpad and plyr_spr_2_scratchpad
; that lose_life starts each life from: the initial values from
; plyr_spr_init_data, knight legs and head as the types to become after
; materialising, and one of four starting rooms, chosen by the low two bits of
; the random seed at $5BA0.
init_start_location:
  LD HL,plyr_spr_init_data
  LD DE,plyr_spr_1_scratchpad
  LD BC,$0008
  LDIR
  LD DE,plyr_spr_2_scratchpad
  LD BC,$0008
  LDIR
  LD A,$12                ; become knight legs (18) and knight head (34)
  LD (plyr_spr_1_tail),A
  LD A,$22
  LD (plyr_spr_2_tail),A
  LD A,($5BA0)            ; one of four rooms
  AND $03                 ;
  LD L,A                  ;
  LD H,$00                ;
  LD BC,start_locations   ;
  ADD HL,BC               ;
  LD A,(HL)               ; into both records
  LD (start_loc_1),A      ;
  LD (start_loc_2),A      ;
  RET                     ;

; The four starting rooms
;
; Room numbers, one of which init_start_location picks at random. A room number
; is its Y position in the castle grid in the high nibble and its X position in
; the low nibble.
start_locations:
  DEFB $2F,$44,$B3,$8F

; Build the room the player is in
;
; Used by the routine at game_loop.
;
; Called at the start of each life and whenever the player walks into another
; room (game_loop). Before the old room's objects are thrown away, the
; collectable objects in records 2 and 3 are written back to the special object
; table (update_special_objs) -- unless no frame of this game has been played
; yet ($5BB2), in which case there is no old room.
;
; IX object 0, the player's legs; its +$08 is the room to build
build_screen_objects:
  LD A,($5BB2)            ; skip the save on the first build of a game
  AND A
  JR Z,build_room
  CALL update_special_objs

; Fill the object table for the new room
;
; Used by the routine at build_screen_objects.
;
; Clears the screen buffer; builds the room's walls, arches and fixed objects
; into records 4 onwards (retrieve_screen); puts any collectable objects in
; this room into records 2 and 3 (find_special_objs_here); and places the
; player in the doorway he came through (adjust_plyr_xyz_for_room_size). Then
; resets the per-room state and asks for the whole room to be drawn and copied
; to the screen ($5BB7).
;
; $5BAF is the portcullis-moving flag and $5BB0 a count the portcullis code
; keeps; $5BBD is the bouncing ball's turning height and $5BBF the
; spiked-ball-falling flag. $5BC0 takes bit 0 of the room number: the dropping
; spiked balls (upd_63) stay put while it is non-zero; picking an object up
; (pickup_object) or collecting an extra life (upd_103) clears it.
build_room:
  CALL clear_scrn_buffer  ; build the room
  CALL retrieve_screen    ;
  CALL find_special_objs_here
  CALL adjust_plyr_xyz_for_room_size
  XOR A                   ; clear the per-room flags
  LD ($5BAF),A            ;
  LD ($5BB0),A            ;
  LD ($5BBD),A            ;
  LD ($5BBF),A            ;
  LD A,$01                ; draw the whole room this frame
  LD ($5BB7),A
  LD A,($5C10)            ; odd rooms hold their spiked balls
  AND $01                 ;
  LD ($5BC0),A            ;
  CALL flag_room_visited  ; the room counts as visited
  RET                     ;

; Mark the player's room as visited
;
; Used by the routine at build_room.
;
; $5BE8 to $5C07 is a 256-bit map of the castle, a bit per room number. The
; byte is the room number divided by 8; the bit number is the bottom three
; bits, and since SET takes its bit number in the opcode, the second opcode
; byte of the SET n,(HL) near the end of this routine is rewritten before it
; runs. calc_and_display_percent counts the bits for the percentage shown when
; the game ends.
flag_room_visited:
  LD A,($5C10)            ; HL = room / 8
  LD C,A
  RRCA
  RRCA
  RRCA
  AND $1F
  LD L,A
  LD H,$00
  LD A,C                  ; opcode byte for SET (room AND 7),(HL)
  RLCA                    ;
  RLCA                    ;
  RLCA                    ;
  AND $38                 ;
  OR $C6                  ;
  LD ($D235),A            ;
  LD BC,$5BE8             ; set the bit in the map
  ADD HL,BC               ;
  SET 0,(HL)              ;
  RET                     ;

; Copy a sprite's four bytes into the drawing record
;
; Used by the routines at transfer_sprite_and_print, display_panel and
; print_border.
;
; Loads a sprite type, flags (for the flip bits), pixel x and pixel y from a
; four-byte entry into the object record at IX -- the spare record at
; sprite_scratchpad -- ready for print_sprite.
;
; HL the four-byte entry
; IX the record to draw with
; HL on exit, the next entry
transfer_sprite:
  LD A,(HL)               ; type, +$07 flags, +$1A x, +$1B y
  INC HL                  ;
  LD (IX+$00),A           ;
  LD A,(HL)               ;
  INC HL                  ;
  LD (IX+$07),A           ;
  LD A,(HL)               ;
  INC HL                  ;
  LD (IX+$1A),A           ;
  LD A,(HL)               ;
  INC HL                  ;
  LD (IX+$1B),A           ;
  RET                     ;

; Copy a sprite's four bytes and draw it
;
; Used by the routines at display_panel and print_border.
;
; transfer_sprite and then print_sprite, keeping HL on the next entry.
;
; HL the four-byte entry
; IX the record to draw with
transfer_sprite_and_print:
  CALL transfer_sprite
  PUSH HL
  CALL print_sprite
  POP HL
  RET

; Draw the scroll-work at the foot of the screen
;
; Used by the routine at no_delay.
;
; Draws the panel artwork under the room from panel_data: a slanting run of
; five of one piece on each side, and two more pieces on each side, the right
; side the left mirrored. The picture of the sun and moon and the lives and
; days are drawn over it by other routines.
display_panel:
  LD IX,sprite_scratchpad ; the first entry
  LD HL,panel_data        ;
  CALL transfer_sprite    ;
  LD DE,$F810             ; left run: five copies, each 16 pixels right and 8
                          ; down
  LD B,$05
  CALL multiple_print_sprite
  CALL transfer_sprite_and_print ; two more pieces, drawn once each
  CALL transfer_sprite_and_print ;
  CALL transfer_sprite    ; the right run's piece
  LD DE,$0810             ; five copies, each 16 pixels right and 8 up
  LD B,$05
  CALL multiple_print_sprite
  CALL transfer_sprite_and_print ; two more pieces, drawn once each
  JP transfer_sprite_and_print   ;

; The panel artwork
;
; Six four-byte entries for display_panel: sprite type, flags (bit 6 mirrors
; the sprite), pixel x, pixel y counted up from the bottom.
panel_data:
  DEFB $86,$00,$10,$34    ; type 134 at (16, 52): the first of the left-hand
                          ; run
  DEFB $87,$00,$F0,$00    ; type 135 at (240, 0)
  DEFB $88,$00,$90,$04    ; type 136 at (144, 4)
  DEFB $86,$40,$A0,$14    ; type 134 mirrored at (160, 20): the first of the
                          ; right-hand run
  DEFB $87,$40,$00,$00    ; type 135 mirrored at (0, 0)
  DEFB $88,$40,$60,$04    ; type 136 mirrored at (96, 4)

; Draw the border round the play area
;
; Used by the routines at print_charms_and_show and display_text_list.
;
; From border_data: one corner sprite drawn four times, flipped each way, then
; the top and bottom edges as 24 pieces 8 pixels apart and the two sides as 128
; pieces a pixel apart.
print_border:
  LD IX,sprite_scratchpad        ; the four corners
  LD HL,border_data              ;
  CALL transfer_sprite_and_print ;
  CALL transfer_sprite_and_print ;
  CALL transfer_sprite_and_print ;
  CALL transfer_sprite_and_print ;
  CALL transfer_sprite       ; the top edge: 24 pieces, 8 pixels apart
  LD DE,$0008                ;
  LD B,$18                   ;
  CALL multiple_print_sprite ;
  CALL transfer_sprite       ; the bottom edge
  LD B,$18                   ;
  CALL multiple_print_sprite ;
  CALL transfer_sprite       ; the left edge: 128 pieces, stepping up a pixel
  LD DE,$0100                ; at a time
  LD B,$80                   ;
  CALL multiple_print_sprite ;
  CALL transfer_sprite     ; the right edge
  LD B,$80                 ;
  JP multiple_print_sprite ;

; The border pieces
;
; Eight four-byte entries for print_border: sprite type, flags (bit 6 mirrors,
; bit 7 turns upside down), pixel x, pixel y counted up from the bottom.
border_data:
  DEFB $89,$00,$00,$A0    ; type 137, corner at (0, 160)
  DEFB $89,$40,$E0,$A0    ; type 137 mirrored, corner at (224, 160)
  DEFB $89,$C0,$E0,$00    ; type 137 mirrored and upside down, corner at (224,
                          ; 0)
  DEFB $89,$80,$00,$00    ; type 137 upside down, corner at (0, 0)
  DEFB $8B,$00,$20,$A8    ; type 139, top edge from (32, 168)
  DEFB $8B,$00,$20,$00    ; type 139, bottom edge from (32, 0)
  DEFB $8A,$00,$00,$20    ; type 138, left edge from (0, 32)
  DEFB $8A,$00,$E8,$20    ; type 138, right edge from (232, 32)

; Colour the sun and moon window's frame
;
; Used by the routine at no_delay.
;
; Attributes only. Blacks out the columns either side of the window (columns 22
; and 29, rows 21 to 23) and colours its frame bright red (columns 23 to 28,
; rows 20 to 23). colour_sun_moon then colours the inside.
colour_panel:
  XOR A                   ; black: column 22, rows 21 to 23
  LD HL,$5AB6             ;
  LD BC,$0103             ;
  CALL fill_window        ; black: column 29, rows 21 to 23
  LD HL,$5ABD             ;
  LD BC,$0103
  CALL fill_window
  LD A,$42                ; bright red: columns 23 to 28, rows 20 to 23
  LD HL,$5A97
  LD BC,$0604
  JP fill_window

; Colour the sun or the moon
;
; Used by the routines at no_delay and toggle_day_night.
;
; Colours the inside of the window (columns 24 to 27, rows 21 and 22) bright
; yellow while the sun shows and bright white for the moon. Bit 0 of the type
; in sun_moon_scratchpad is 0 for the sun and 1 for the moon.
colour_sun_moon:
  LD A,(sun_moon_scratchpad) ; yellow on black, or white for the moon
  AND $01
  LD A,$46
  JR Z,fill_sun_moon_colour
  INC A

; Fill the window's colour
;
; Used by the routine at colour_sun_moon.
;
; Part of colour_sun_moon.
fill_sun_moon_colour:
  LD HL,$5AB8             ; columns 24 to 27, rows 21 and 22
  LD BC,$0402
  JP fill_window

; Put the player in the doorway he came through
;
; Used by the routine at build_room.
;
; When the player walks out of a room, the exit code (screen_west and its three
; neighbours, ending at exit_screen) moves him to the next room number and sets
; the coordinate he left by to an extreme -- X to 0 on leaving towards -X, $FF
; towards +X, and the same for Y. That extreme says which side of the new room
; he enters from, and this routine moves him to that side, with his inner side
; two units inside the room's edge and the rest of him in the doorway. His Z is
; then set to the floor of the arch there (adjust_plyr_Z_for_arch).
;
; The names follow the compass used for the arches: +X is east, +Y north. If no
; coordinate is at an extreme -- the start of a life -- nothing is changed.
;
; $5BAB and $5BAC are the room's X and Y half-sizes, measured from the centre,
; $80.
;
; IX object 0, the player's legs
adjust_plyr_xyz_for_room_size:
  LD A,($5BAB)
  SUB $02
  LD L,A
  LD A,($5BAC)
  SUB $02
  LD H,A
  LD A,(IX+$01)           ; X = 0: came in on the east side
  AND A
  JR Z,enter_arch_e       ; X = $FF: the west side
  INC A
  JR Z,enter_arch_w
  LD A,(IX+$02)           ; Y = 0: the north side
  AND A
  JR Z,enter_arch_n       ; Y = $FF: the south side; otherwise stay put
  INC A
  JR Z,enter_arch_s
  RET

; Enter through the south arch
;
; Used by the routine at adjust_plyr_xyz_for_room_size.
;
; The player left the last room northwards (Y was $FF) and arrives at the low-Y
; side of this one.
enter_arch_s:
  LD C,$C8                    ; Z from the arch whose X+Y is $C8
  CALL adjust_plyr_Z_for_arch ;
  LD A,$80                ; Y = $80 - (half-size - 2) - his Y half-size
  SUB H
  SUB (IX+$05)

; Set the player's Y
;
; Used by the routine at enter_arch_n.
;
; Part of enter_arch_s and enter_arch_n.
adjust_plyr_y:
  LD (IX+$02),A           ; the new Y

; Redraw the player and line the head up with the legs
;
; Used by the routine at adjust_plyr_x.
;
; Sets the redraw flag on both of the player's records and copies the legs' new
; X and Y to the head.
plyr_redraw_copy_xy:
  SET 4,(IX+$07)          ; redraw legs and head
  SET 4,(IX+$27)
  LD A,(IX+$01)           ; head X and Y = legs X and Y
  LD (IX+$21),A
  LD A,(IX+$02)
  LD (IX+$22),A
  RET

; Enter through the north arch
;
; Used by the routine at adjust_plyr_xyz_for_room_size.
;
; The player left the last room southwards (Y was 0) and arrives at the high-Y
; side of this one.
enter_arch_n:
  LD C,$51                    ; Z from the arch whose X+Y is $51
  CALL adjust_plyr_Z_for_arch ;
  LD A,H                  ; Y = $80 + (half-size - 2) + his Y half-size
  ADD A,$80               ;
  ADD A,(IX+$05)          ;
  JR adjust_plyr_y        ;

; Enter through the west arch
;
; Used by the routine at adjust_plyr_xyz_for_room_size.
;
; The player left the last room eastwards (X was $FF) and arrives at the low-X
; side of this one.
enter_arch_w:
  LD C,$AE                    ; Z from the arch whose X+Y is $AE
  CALL adjust_plyr_Z_for_arch ;
  LD A,$80                ; X = $80 - (half-size - 2) - his X half-size
  SUB L                   ;
  SUB (IX+$04)            ;

; Set the player's X
;
; Used by the routine at enter_arch_e.
;
; Part of enter_arch_w and enter_arch_e.
adjust_plyr_x:
  LD (IX+$01),A           ; the new X, and on to the head
  JR plyr_redraw_copy_xy  ;

; Enter through the east arch
;
; Used by the routine at adjust_plyr_xyz_for_room_size.
;
; The player left the last room westwards (X was 0) and arrives at the high-X
; side of this one.
enter_arch_e:
  LD C,$37                    ; Z from the arch whose X+Y is $37
  CALL adjust_plyr_Z_for_arch ;
  LD A,L                  ; X = $80 + (half-size - 2) + his X half-size
  ADD A,$80               ;
  ADD A,(IX+$04)          ;
  JR adjust_plyr_x        ;

; Stand the player on the floor of the arch
;
; Used by the routines at enter_arch_s, enter_arch_n, enter_arch_w and
; enter_arch_e.
;
; The code expects a room's arches to be its first background objects, each two
; records (the two pillars, types 2 to 5), so the first pillars are records 4,
; 6, 8 and 10. The side an arch is on is recognised by the X+Y of its first
; pillar -- $51 north, $37 east, $C8 south, $AE west, from the arch data at
; arch_n on. The player takes that pillar's Z, which is what puts him at the
; right height in a raised arch; the head goes 12 above.
;
; The search stops at the first record that is not an arch pillar; if no arch
; matches, Z is left alone.
;
; C X+Y of the arch wanted
; IX object 0, the player's legs
adjust_plyr_Z_for_arch:
  LD IY,$5C88             ; IY = record 4; step two records; four arches at
                          ; most
  LD DE,$0040
  LD B,$04

; Look at the next arch
;
; Part of adjust_plyr_Z_for_arch.
check_next_arch:
  LD A,(IY+$00)           ; type 6 or more: no more arches
  CP $06
  RET NC
  LD A,(IY+$01)           ; X+Y matches: this is the one
  ADD A,(IY+$02)
  CP C
  JR Z,adj_plyr_Z
  ADD IY,DE               ; next arch
  DJNZ check_next_arch    ;
  RET                     ;

; Take the arch's Z
;
; Used by the routine at check_next_arch.
;
; Part of adjust_plyr_Z_for_arch.
adj_plyr_Z:
  LD A,(IY+$03)           ; legs' Z = the pillar's Z
  LD (IX+$03),A
  ADD A,$0C               ; head's Z = 12 higher
  LD (IX+$23),A
  RET

; Object index to record address
;
; Used by the routines at skip_drawn_entries, compare_next_obj and
; wipe_next_object.
;
; Five doublings is a multiply by 32, and $5C08 is the base of the object
; table. The AND $7F is the counterpart of the flag bit that callers carry in
; the top of the index: render_obj sets bit 7 of an entry in the list at
; objects_to_draw once that object has been drawn, and the list is read again
; later in the same frame.
;
; A the object index; bit 7 is ignored
; HL the address of its 32-byte record
get_ptr_object:
  PUSH BC
  AND $7F                 ; HL = index * 32
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,$5C08             ; plus the start of the object table
  ADD HL,BC
  POP BC
  RET

; Build the objects of the room the player has entered
;
; Used by the routine at build_room.
;
; Turns one room record from location_tbl into object records, filling the
; object table from record 4 ($5C88) upwards and clearing whatever is left
; after the last one. Records 0 to 3 are not touched here. The first two are
; the player's; build_room calls find_special_objs_here next, which fills from
; record 2 ($5C48) with the special objects that are in this room.
;
; Every fixed part of the room -- walls, arches, doors, blocks, spikes --
; becomes an ordinary 32-byte object, the same as a guard or a ghost. There is
; no separate background picture: the room is drawn by drawing its objects.
;
; IX the object whose byte 8 names the room: the player's record at $5C08
retrieve_screen:
  LD DE,$5C88             ; the first record the room may use
  LD BC,block_type_tbl    ; the end of the room table, where block_type_tbl
                          ; begins
  LD HL,location_tbl      ; the first room record

; Find the room's record
;
; Walks the room table from the start, since records vary in length and there
; is no index. A room that is not in the table gets no objects at all: the
; table is cleared from DE and the routine returns.
;
; HL a room record's first byte, its room number
; BC the end of the room table
find_screen:
  LD A,(HL)               ; this record's room number against the one the
  INC HL                  ; player is in
  CP (IX+$08)             ;
  JR Z,found_screen       ;
  LD A,(HL)               ; not it: the second byte is the record's length
  CALL add_HL_A           ; counted from that byte itself, so adding it lands
                          ; on the next record's room number
  AND A                              ; past the end of the table: no such room;
  SBC HL,BC                          ; otherwise go round again
  JR NC,zero_end_of_graphic_objs_tbl ;
  ADD HL,BC                          ;
  JR find_screen                     ;

; Clear the object records from DE to the end of the table
;
; Used by the routines at find_screen, next_bg_obj_sprite and end_of_fg_objs.
;
; Every way out of the room builder ends here, so the records a room did not
; fill are left empty -- byte 0, the graphic, is 0 -- and the object walk at
; onscreen_loop skips them.
;
; DE the first record to clear, a whole number of records below font
zero_end_of_graphic_objs_tbl:
  LD HL,font              ; done when DE has reached font, the end of the
                          ; object table
  AND A
  SBC HL,DE
  RET Z
  LD B,$20                ; clear one 32-byte record and go round
  CALL zero_DE
  JR zero_end_of_graphic_objs_tbl

; Take the room's colour and size from its record
;
; Used by the routine at find_screen.
;
; The byte after the length is the room's attribute byte. Its bits 0 to 2 are
; the ink colour the whole room is drawn in, and its bits 3 to 7 pick one of
; the entries in room_size_tbl, which give the room's half-widths in x and y
; and the height of its floor. After this B counts the bytes that remain in the
; record, so that the lists that follow can end on it as well as on their own
; markers.
;
; HL the record's length byte
found_screen:
  LD B,(HL)               ; B = the record's length; HL on the attribute byte
  INC HL                  ;
  LD A,(HL)               ; ink colour, BRIGHT, black paper: kept in $5BAD for
  AND $07                 ; fill_attr to paint the room with
  OR $40                  ;
  LD ($5BAD),A            ;
  PUSH DE                 ; bits 3 to 7 index the size table
  EX DE,HL                ;
  LD A,(DE)               ;
  INC DE                  ;
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  AND $1F                 ;
  LD C,A                  ; three bytes an entry in room_size_tbl
  ADD A,A                 ;
  ADD A,C                 ;
  LD HL,room_size_tbl     ;
  CALL add_HL_A           ;
  LD A,(HL)               ; half-width in x into $5BAB, in y into $5BAC, and
  INC HL                  ; the floor height into $5BAE
  LD ($5BAB),A            ;
  LD A,(HL)               ;
  INC HL                  ;
  LD ($5BAC),A            ;
  LD A,(HL)               ;
  LD ($5BAE),A            ;
  DEC B                   ; the length counted itself and the attribute byte;
  DEC B                   ; HL on the list of backgrounds, DE on the next free
  EX DE,HL                ; record again
  POP DE                  ;

; Next background in the room's list
;
; Used by the routine at next_bg_obj_sprite.
;
; The room record starts with a list of background numbers, ended by $FF. Each
; one is looked up in background_type_tbl to find its list of templates.
;
; HL the next byte of the room record
; DE the next free object record
; B the bytes left in the room record
next_bg_obj:
  LD A,(HL)               ; $FF ends the backgrounds and starts the foreground
  INC HL                  ; list
  CP $FF                  ;
  JR Z,find_fg_objs       ;
  PUSH BC                   ; look the background up in background_type_tbl; HL
  PUSH HL                   ; = its template list
  LD L,A                    ;
  LD H,$00                  ;
  ADD HL,HL                 ;
  LD BC,background_type_tbl ;
  ADD HL,BC                 ;
  LD A,(HL)                 ;
  INC HL                    ;
  LD H,(HL)                 ;
  LD L,A                    ;

; Copy one background template into an object record
;
; A background template is eight bytes that become bytes 0 to 7 of the record
; unchanged: graphic, x, y, z, the half-sizes in x and y, the height, and the
; flags. Byte 8 is the room, and the rest of the record is cleared. A
; background's templates follow one another and end at a 0 byte, where the next
; graphic number would be; graphic 0 is never an object.
next_bg_obj_sprite:
  LD BC,$0008             ; bytes 0 to 7 straight from the template
  LDIR
  LD A,(IX+$08)           ; byte 8: the room it belongs to
  LD (DE),A
  INC DE
  LD B,$17                ; bytes 9 to 31 cleared
  CALL zero_DE
  LD A,(HL)                ; more templates for this background until a 0
  AND A                    ;
  JR NZ,next_bg_obj_sprite ;
  POP HL                  ; one byte of the room record used; next background
  POP BC                  ;
  DJNZ next_bg_obj        ;
  JP zero_end_of_graphic_objs_tbl ; a record with only backgrounds: clear the
                                  ; rest of the table

; Start on the room's foreground objects
;
; Used by the routine at next_bg_obj.
;
; After the $FF come the foreground groups. IY becomes the pointer to the next
; free record here, because D is about to hold a location byte and HL and DE
; are both in use.
find_fg_objs:
  DEC B                   ; count the $FF
  PUSH IY                 ; IY = the next free record; the caller's IY kept on
  PUSH DE                 ; the stack
  POP IY                  ;

; Read a foreground group: its type, count and first location
;
; Used by the routine at zero_fg_obj_tail.
;
; A group is a type byte followed by one location byte per object. The type
; byte's bits 3 to 7 index block_type_tbl, and its bits 0 to 2 are one less
; than the number of locations that follow. So one room record can scatter
; eight identical blocks in nine bytes.
;
; HL the group's first byte
next_fg_obj:
  LD A,(HL)               ; C = how many of this type
  AND $07                 ;
  INC A                   ;
  LD C,A                  ;
  LD A,(HL)               ; D = the first location; each type and location byte
  INC HL                  ; counts off B
  DEC B                   ;
  LD D,(HL)               ;
  INC HL                  ;
  PUSH HL                 ; bits 3 to 7 of the type byte, already doubled by
  RRCA                    ; the RRCAs, index the word table at block_type_tbl
  RRCA                    ;
  AND $3E                 ;
  LD HL,block_type_tbl    ;
  CALL add_HL_A           ;
  LD A,(HL)               ; HL = the type's template list
  INC HL                  ;
  LD H,(HL)               ;
  LD L,A                  ;

; Place one more of the same type
;
; Used by the routine at zero_fg_obj_tail.
;
; Keeps the start of the template list on the stack, so it can be read again
; for the next location of the same type.
next_fg_obj_in_count:
  PUSH HL

; Build one object record from a foreground template and a location
;
; Used by the routine at zero_fg_obj_tail.
;
; A foreground template is six bytes: the graphic, four bytes that become bytes
; 4 to 7 of the record (half-sizes, height, flags), and an offset byte. The
; position comes from the room's location byte, which is a cell on a grid: bits
; 0 to 2 the x cell, bits 3 to 5 the y cell, bits 6 and 7 the level. Cells are
; 16 units apart starting at $48, and levels 12 units apart starting at the
; floor height in $5BAE. The offset byte's bits 0 and 1 add half a cell in x
; and y, and the rest of it, a multiple of 4, is added to the height -- which
; is how something can stand on top of a block or sit between two cells.
;
; HL the template
; D the location byte
; IY the record to fill
next_fg_obj_sprite:
  LD A,(HL)               ; graphic into byte 0, then four template bytes into
  INC HL                  ; bytes 4 to 7
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
  LD A,(IX+$08)           ; byte 8: the room
  LD (IY+$08),A           ;
  LD A,(HL)               ; x = $48 + 16 * the x cell, plus 8 if bit 0 of the
  RLCA                    ; offset byte is set
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
  LD A,(HL)               ; y = $48 + 16 * the y cell, plus 8 if bit 1 is set
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
  LD A,D                  ; z = the floor height + (12 * the level + the offset
  RLCA                    ; byte) AND $FC
  RLCA                    ;
  AND $03                 ;
  ADD A,A                 ;
  ADD A,A                 ;
  LD E,A                  ;
  ADD A,A                 ;
  ADD A,E                 ;
  ADD A,(HL)              ;
  INC HL                  ;
  AND $FC                 ;
  LD E,A                  ;
  LD A,($5BAE)            ;
  ADD A,E                 ;
  LD (IY+$03),A           ;
  PUSH BC                 ; on to byte 9 of the record; 23 bytes to clear
  LD BC,$0009             ;
  ADD IY,BC               ;
  LD B,$17                ;

; Clear the rest of a foreground record, then carry on
;
; A type's template list can hold more than one template, ended by a 0, so one
; location can build several records -- each the next template placed at the
; same cell.
zero_fg_obj_tail:
  LD (IY+$00),$00         ; zero bytes 9 to 31, leaving IY on the next record
  INC IY                  ;
  DJNZ zero_fg_obj_tail   ;
  POP BC                   ; more templates for this location until a 0
  LD A,(HL)                ;
  AND A                    ;
  JR NZ,next_fg_obj_sprite ;
  POP DE                  ; DE = the start of the template list; HL on the room
  POP HL                  ; record
  DEC B                   ; each location counts off B; at zero the room record
  JR Z,end_of_fg_objs     ; is used up
  DEC C                   ; all the locations of this type placed: read the
  JP Z,next_fg_obj        ; next type byte
  LD A,(HL)               ; another location of the same type: D = its byte,
  INC HL                  ; and HL back on the template list
  PUSH HL                 ;
  EX DE,HL                ;
  LD D,A                  ;
  JR next_fg_obj_in_count ;

; The room record is used up
;
; Used by the routine at zero_fg_obj_tail.
;
; Hands the next free record back in DE, restores the caller's IY and clears
; the rest of the table.
end_of_fg_objs:
  PUSH IY
  POP DE
  POP IY
  JP zero_end_of_graphic_objs_tbl

; Add A to HL
;
; Used by the routines at play_note, ret_next_obj_required,
; display_sun_moon_frame, find_screen, found_screen, next_fg_obj,
; vflip_sprite_data and vflip_sprite_line_pair.
;
; An unsigned 8-bit add with the carry taken into H. A comes back holding H.
;
; A the amount to add
; HL the address to add it to
add_HL_A:
  ADD A,L
  LD L,A
  LD A,H
  ADC A,$00
  LD H,A
  RET

; HL = DE * A
;
; Used by the routine at vflip_sprite_data.
;
; Shift and add, taking the bits of A from the top. Eight RLCAs bring A back to
; what it was, and BC is kept.
;
; DE the multiplicand
; A the multiplier
; HL on exit, the product
HL_equals_DE_x_A:
  PUSH BC
  LD HL,$0000
  LD B,$08

; One bit of the multiply
;
; Used by the routine at mult_next_bit.
;
; Doubles the running total, and adds DE if this bit of A is set.
mult_step:
  ADD HL,HL
  RLCA
  JR NC,mult_next_bit
  ADD HL,DE

; Next bit of the multiply
;
; Used by the routine at mult_step.
;
; Eight passes, one for each bit of A.
mult_next_bit:
  DJNZ mult_step
  POP BC
  RET

; Clear B bytes at DE
;
; Used by the routines at adjust_carried, find_spec_obj_loop,
; clear_spare_spec_records, zero_end_of_graphic_objs_tbl and
; next_bg_obj_sprite.
;
; Falls into fill_DE with A = 0. DE is left after the last byte, which is how
; the room builder moves on to the next record.
;
; DE the first byte
; B the count
zero_DE:
  XOR A

; Fill B bytes at DE with A
;
; Used by the routine at print_lives_gfx.
;
; DE is left after the last byte.
;
; DE the first byte
; B the count
; A the value
fill_DE:
  LD (DE),A
  INC DE
  DJNZ fill_DE
  RET

; Pause if SPACE is pressed
;
; Used by the routine at end_of_frame.
;
; Called once a frame. The half-row $7E is B, N, M, SYMBOL SHIFT and SPACE, and
; read_port returns SPACE as bit 0. Only SPACE on its own pauses: with any
; other key of that half-row held as well the routine returns. Why that matters
; has not been worked out.
;
; The pause itself is a busy wait inside this routine: nothing moves, nothing
; is drawn and the frame counter stops until SPACE is pressed and let go again.
; toggle_audio_hw_x24 sounds on the way in and on the way out.
handle_pause:
  LD A,$7E                ; SPACE not pressed: carry on
  CALL read_port
  BIT 0,A
  RET Z
  AND $1E                 ; another key of the half-row is held too: not a
                          ; pause
  RET NZ

; Wait for SPACE to be let go, then sound
;
; Without this the press that paused the game would also end the pause.
debounce_space_press:
  LD A,$7E                ; wait until SPACE is up
  CALL read_port          ;
  BIT 0,A
  JR NZ,debounce_space_press
  CALL toggle_audio_hw_x24 ; the pause sound

; Paused: wait for SPACE again
wait_for_space:
  LD A,$7E
  CALL read_port
  BIT 0,A
  JR Z,wait_for_space

; Wait for SPACE to be let go, sound, and carry on
;
; The release is waited for so that the unpausing press does not pause the game
; again on the next frame.
debounce_space_release:
  LD A,$7E
  CALL read_port
  BIT 0,A
  JR NZ,debounce_space_release
  JP toggle_audio_hw_x24  ; the sound again, and back to the game

; Clear BC bytes at HL
;
; Used by the routines at START, start_menu, clr_bitmap_memory and
; clear_scrn_buffer.
;
; HL the first byte
; BC the count
clr_mem:
  LD E,$00

; Fill BC bytes at HL with E
;
; Used by the routines at clr_attribute_memory and fill_attr.
;
; HL the first byte
; BC the count
; E the value
clr_byte:
  LD (HL),E
  INC HL
  DEC BC
  LD A,B
  OR C
  JR NZ,clr_byte
  RET

; Clear the display bitmap
;
; Used by the routine at clear_scrn.
;
; All 6144 bytes from $4000.
clr_bitmap_memory:
  LD HL,$4000
  LD BC,$1800
  JR clr_mem

; Set every attribute to bright yellow on black
;
; Used by the routine at clear_scrn.
;
; $46 is BRIGHT, black paper, yellow ink: the colour of the menu and the status
; line.
clr_attribute_memory:
  LD HL,$5800
  LD BC,$0300
  LD E,$46
  JR clr_byte

; Set every attribute to A
;
; Used by the routine at no_delay.
;
; Called with the room's colour from $5BAD when a new room is shown: the game
; area is one colour throughout, which is why a room's objects all take the
; room's ink.
;
; A the attribute
fill_attr:
  LD HL,$5800
  LD BC,$0300
  LD E,A
  JR clr_byte

; Clear the screen and make the border black
;
; Used by the routines at main, game_over_summary and game_complete_msg.
;
; Black border, the attributes to bright yellow on black, and then the bitmap
; cleared.
clear_scrn:
  XOR A                   ; black border
  OUT ($FE),A             ;
  CALL clr_attribute_memory
  JR clr_bitmap_memory

; Clear the screen buffer
;
; Used by the routines at game_over_summary, game_complete_msg,
; clear_menu_flash and build_room.
;
; Blanks all of screen_buffer before a room is built into it.
clear_scrn_buffer:
  LD BC,$1800
  LD HL,screen_buffer
  JR clr_mem

; Copy the whole buffer to the display, clearing it as it goes
;
; Used by the routines at no_delay, print_charms_and_show and
; display_text_list.
;
; Used when a new room is shown: the whole room is composed in screen_buffer
; first and then appears at once. The buffer runs the other way up from the
; display -- its first row is the bottom line of the screen -- because the
; game's pixel y counts up from the bottom; so the copy starts at the display's
; bottom-left byte, $57E0, and works up a line at a time.
;
; Clearing as it copies leaves the buffer blank. That is safe because from here
; on only the areas render_dynamic_objects wipes and redraws are ever copied
; out of it, so what the rest of the buffer holds does not matter.
update_screen:
  LD HL,screen_buffer     ; from the start of the buffer to the bottom-left of
                          ; the display; B = 32 bytes a row, C = 192 rows
  LD DE,$57E0
  LD BC,$20C0

; One row of the whole-screen copy
;
; Used by the routine at update_screen_next_row.
update_screen_row:
  PUSH BC
  PUSH DE
  PUSH HL

; Copy and clear a row, then step to the display line above
update_screen_byte:
  LD A,(HL)               ; copy a byte and clear it behind
  LD (DE),A               ;
  LD (HL),$00             ;
  INC HL                  ;
  INC E                   ;
  DJNZ update_screen_byte ;
  POP HL                  ; the next buffer row is 32 bytes on
  LD BC,$0020             ;
  ADD HL,BC               ;
  POP DE                  ;
  DEC D                        ; up a display line: DEC D is enough unless the
  LD A,D                       ; low three bits of D have wrapped round to 7,
  CPL                          ; which means the line crossed into the
  AND $07                      ; character row above
  JR NZ,update_screen_next_row ;
  LD A,E                      ; crossing a character row: back 32 in E; if that
  SUB $20                     ; borrows the line is the bottom of the third
  LD E,A                      ; above, which is where DEC D left it; if not, D
  JR C,update_screen_next_row ; goes back up by 8 to stay in this third
  LD A,D                      ;
  ADD A,$08                   ;
  LD D,A                      ;

; Next row of the whole-screen copy
;
; Used by the routine at update_screen_byte.
update_screen_next_row:
  POP BC
  DEC C
  JR NZ,update_screen_row
  RET

; Redraw what changed and copy it to the display
;
; Used by the routine at end_of_frame.
;
; Called at the end of every frame. The list at objects_to_draw holds every
; object that is to be drawn this frame: those that moved or changed, which
; set_wipe_and_draw_flags flagged with bits 4 and 5 of byte 7, and those whose
; picture overlaps them, which set_draw_objs_overlapped flagged with bit 4
; only. First, for each object that moved, the rectangle covering both where it
; was last frame and where it is now is cleared in the buffer and remembered on
; the stack. Then every flagged object is drawn into the buffer in depth order,
; and finally the remembered rectangles -- and only those -- are copied to the
; display.
;
; Nothing is ever erased on the display itself, so nothing flickers; and since
; the background is made of objects too, a wall behind a moving knight is
; simply drawn again.
;
; In the frame a room is entered the wiping is skipped altogether: the buffer
; has just been cleared, and end_of_frame copies all of it to the display with
; update_screen once the objects are drawn.
render_dynamic_objects:
  XOR A                   ; no rectangles yet: $5BA8 counts them
  LD ($5BA8),A            ;
  PUSH IX
  LD A,($5BB7)              ; a room just built ($5BB7 set by build_room):
  AND A                     ; nothing to wipe
  JP NZ,draw_and_copy_rects ;
  LD HL,objects_to_draw   ; walk the list that list_objects_to_draw made; $5BCB
  LD ($5BCB),HL           ; is the place in it

; Wipe the next object that moved
;
; Used by the routines at wipe_height and wipe_rect.
;
; Bytes $18 and $19 of a record are the width in bytes and height in rows of
; its sprite as last drawn, and $1A and $1B its pixel x and y; save_2d_info
; copies all four to bytes $1C to $1F before the object's handler runs, so they
; hold last frame's picture while $18 to $1B are about to get this frame's. The
; rectangle wiped is the smallest one that covers both.
wipe_next_object:
  LD HL,($5BCB)           ; the next index from the list
  LD A,(HL)
  INC HL
  LD ($5BCB),HL
  CP $FF                  ; $FF ends it
  JP Z,draw_and_copy_rects
  CALL get_ptr_object     ; bit 5 of byte 7 means it needs wiping; the others
  PUSH HL                 ; in the list are only being drawn again
  POP IX                  ;
  BIT 5,(IX+$07)          ;
  JR Z,wipe_next_object   ;
  RES 5,(IX+$07)          ; only once
  LD A,(IX+$1A)           ; C = whichever of the new (byte $1A) and old (byte
                          ; $1E) pixel x is further left
  SUB (IX+$1E)
  JP C,wipe_left_is_new
  LD C,(IX+$1E)

; Find the right edge of the area to wipe
;
; Used by the routine at wipe_left_is_new.
wipe_right_edge:
  LD A,(IX+$1E)           ; the old right edge in bytes: old x / 8 + old width
                          ; (byte $1C)
  RRCA
  RRCA
  RRCA
  AND $1F
  ADD A,(IX+$1C)
  LD E,A
  LD A,(IX+$1A)           ; the new one: new x / 8 + new width (byte $18); E =
                          ; the further right
  RRCA
  RRCA
  RRCA
  AND $1F
  ADD A,(IX+$18)
  CP E
  JR C,wipe_width
  LD E,A

; The width of the area, and its bottom edge
;
; Used by the routine at wipe_right_edge.
wipe_width:
  LD A,C                  ; H = the width in bytes, from the left byte to the
  RRCA                    ; right edge
  RRCA                    ;
  RRCA                    ;
  AND $1F                 ;
  LD B,A                  ;
  LD A,E                  ;
  SUB B                   ;
  LD H,A                  ;
  LD A,(IX+$1B)           ; B = the lower of the new (byte $1B) and old (byte
                          ; $1F) pixel y
  SUB (IX+$1F)
  JR C,wipe_bottom_is_new
  LD B,(IX+$1F)

; Find the top edge of the area to wipe
;
; Used by the routine at wipe_bottom_is_new.
wipe_top_edge:
  LD A,(IX+$1F)           ; the old top: old y + old height (byte $1D)
  ADD A,(IX+$1D)
  LD E,A
  LD A,(IX+$1B)           ; the new top: new y + new height (byte $19); A = the
                          ; higher
  ADD A,(IX+$19)
  CP E
  JR NC,wipe_height
  LD A,E

; The height of the area, cut off at the top of the screen
;
; Used by the routine at wipe_top_edge.
wipe_height:
  SUB B                   ; L = the height in rows
  LD L,A                  ;
  LD A,B                  ; an area that starts above the top of the screen has
  CP $C0                  ; nothing to wipe
  JR NC,wipe_next_object  ;
  ADD A,L                 ; if it runs past line 192, keep only the part below
  SUB $C0                 ;
  JR C,wipe_rect          ;
  NEG                     ;
  ADD A,L                 ;
  LD L,A                  ;

; Wipe the area in the buffer and remember it
;
; Used by the routine at wipe_height.
wipe_rect:
  CALL calc_vram_addr     ; DE = its display address, BC = its buffer address
  CALL calc_vidbuf_addr
  LD A,L                  ; rearrange: HL = buffer address, B = width, C =
  LD L,C                  ; height
  LD C,A                  ;
  LD A,H                  ;
  LD H,B                  ;
  LD B,A                  ;
  LD A,($5BA8)            ; one more rectangle to copy
  INC A                   ;
  LD ($5BA8),A            ;
  PUSH BC                 ; on the stack until the objects have been drawn
  PUSH DE                 ;
  PUSH HL                 ;
  XOR A                   ; cleared in the buffer: fill_window fills B bytes by
  CALL fill_window        ; C rows with A
  JP wipe_next_object     ; the next object

; The new x is the further left
;
; Used by the routine at wipe_next_object.
wipe_left_is_new:
  LD C,(IX+$1A)
  JR wipe_right_edge

; The new y is the lower
;
; Used by the routine at wipe_width.
wipe_bottom_is_new:
  LD B,(IX+$1B)
  JR wipe_top_edge

; Draw the objects, then copy the wiped areas to the display
;
; Used by the routines at render_dynamic_objects and wipe_next_object.
draw_and_copy_rects:
  CALL calc_display_order_and_render ; every flagged object into the buffer, in
                                     ; depth order
  CALL print_sun_moon     ; the sun or moon in the status area
  CALL display_objects_carried ; the objects the player carries
  LD HL,$5BA8             ; the rectangles count towards $5BBE, the frame's
  LD A,($5BBE)            ; work, which sets how long end_of_frame waits
  ADD A,(HL)              ;
  LD ($5BBE),A            ;

; Copy the next wiped area to the display
;
; They come off the stack last first, which does not matter: each is copied
; whole.
copy_next_rect:
  LD HL,$5BA8             ; none left
  LD A,(HL)
  AND A
  JR Z,copy_rects_done
  DEC (HL)                ; pop one, with width and height swapped into the
  POP HL                  ; order blit_to_screen takes them
  POP DE                  ;
  POP BC                  ;
  LD A,B                  ;
  LD B,C                  ;
  LD C,A                  ;
  CALL blit_to_screen
  JR copy_next_rect

; All copied
;
; Used by the routine at copy_next_rect.
copy_rects_done:
  POP IX
  RET

; Copy a rectangle of the buffer to the display
;
; Used by the routines at show_carried_slot, display_frame, blit_2x8,
; copy_next_rect and blit_next_row.
;
; Works up the screen a row at a time, the same way as update_screen, but
; leaves the buffer as it is. Used for the wiped areas at the end of a frame
; and by the status area, which draws into the buffer and copies its own parts
; out.
;
; HL the buffer address of its bottom-left byte
; DE the display address of the same byte
; B the height in rows
; C the width in bytes
blit_to_screen:
  PUSH BC                 ; one row: B is cleared so that LDIR copies C bytes
  PUSH DE                 ;
  PUSH HL                 ;
  LD B,$00                ;
  LDIR                    ;
  POP HL                  ; the buffer row above is 32 bytes on
  LD DE,$0020             ;
  ADD HL,DE               ;
  POP DE                  ;
  DEC D                   ; up a display line, unless that crossed a character
  LD A,D                  ; row
  CPL                     ;
  AND $07                 ;
  JR NZ,blit_next_row     ;
  LD A,E                  ; crossing a character row: back 32 in E, and back
  SUB $20                 ; into this third unless that borrowed
  LD E,A                  ;
  JR C,blit_next_row      ;
  LD A,D                  ;
  ADD A,$08               ;
  LD D,A                  ;

; Next row of the rectangle
;
; Used by the routine at blit_to_screen.
blit_next_row:
  POP BC
  DJNZ blit_to_screen
  RET

; Build the lookup tables
;
; Used by the routine at main.
;
; Fills reverse_bits_tbl and the fourteen pages above it at start-up with
; tables the drawing code needs every frame and would otherwise have to
; compute. At reverse_bits_tbl itself is the bit-reversal of every byte value.
; Reversing bits is how a sprite is mirrored horizontally, which is how the
; game gets a knight facing west out of one facing east.
;
; The fourteen pages from shift_tbls up are the shifted bytes, in pairs: for
; each shift s from 1 to 7, page $F0 + 2s holds every byte shifted right s
; places, and the page above it the bits that fall out into the next byte. Both
; are stored complemented. sprite_row_jump uses one value from such a table to
; do two jobs: ANDed with the background it clears the bits under the mask, and
; XORed with the result and then complemented it adds the image.
build_lookup_tbls:
  LD L,$00                ; every byte value, L from 0

; Start on one byte value
;
; Used by the routine at shift_tbl_entry.
shift_tbl_value:
  LD D,$00                ; DE = the value; H on the top page; seven shifts
  LD E,L                  ;
  LD H,$FF                ;
  LD B,$07                ;

; Store the value shifted one place further
shift_tbl_entry:
  SLA E                   ; one more place left across D and E: after k shifts
  RL D                    ; E is the value shifted right 8 - k, and D what
                          ; spills out of it
  LD A,E                  ; E complemented on this page
  CPL                     ;
  LD (HL),A               ;
  DEC H                   ; D complemented on the page below
  LD A,D                  ;
  CPL                     ;
  LD (HL),A               ;
  DEC H                   ;
  DJNZ shift_tbl_entry
  INC L                   ; the next value
  JR NZ,shift_tbl_value   ;
  LD HL,reverse_bits_tbl  ; from here up: reverse_bits(n) for n = 0 to 255

; Start reversing one byte value
;
; Used by the routine at reverse_tbl_bit.
reverse_tbl_value:
  LD D,L
  LD B,$08

; Move one bit across
reverse_tbl_bit:
  SRL D                   ; a bit out of the bottom of D into the bottom of E:
  RL E                    ; after eight, E is the value reversed
  DJNZ reverse_tbl_bit
  LD (HL),E               ; store it; the next value, until L wraps to 0
  INC L                   ;
  JR NZ,reverse_tbl_value ;
  RET

; Project an object's position onto the screen
;
; Used by the routines at place_under_player, calc_2d_info and
; project_and_draw.
;
; The isometric projection. The object's x, y and z (bytes 1 to 3) become a
; pixel x in byte $1A and a pixel y in byte $1B, counted up from the bottom of
; the screen:
;
; pixel x = x + y - 128, and pixel y = (y - x + 128) / 2 + z - 104.
;
; So a step in x moves one pixel right and half a pixel down, a step in y one
; pixel right and half a pixel up, and a step in z one pixel straight up -- the
; two-to-one slopes of the view. Bytes $12 and $13 are added on top: set by
; set_pixel_adj, they shift an object's picture without moving the object, for
; sprites whose artwork does not sit where the object stands.
;
; IX the object
; F on exit, carry set if the pixel y is below 192, that is on the
; screen
calc_pixel_XY:
  LD A,(IX+$01)           ; pixel x
  ADD A,(IX+$02)
  SUB $80
  ADD A,(IX+$12)
  LD (IX+$1A),A
  LD A,(IX+$02)           ; pixel y
  SUB (IX+$01)
  ADD A,$80
  SRL A
  ADD A,(IX+$03)
  SUB $68
  ADD A,(IX+$13)
  LD (IX+$1B),A           ; carry set if it is on the screen
  CP $C0
  RET

; Find an object's sprite and make it face the right way
;
; Used by the routines at calc_2d_info and print_sprite.
;
; Byte 0 of the record indexes sprite_tbl for the sprite. A sprite whose first
; header byte is 0 is not drawn: the routine then throws away its own return
; address, so its RET leaves its caller too. Otherwise vflip_sprite_data turns
; the stored data to match the object's flip bits and returns here with DE
; still on the header.
;
; IX the object
; DE on exit, the sprite's header
flip_sprite:
  LD L,(IX+$00)           ; DE = the sprite, from sprite_tbl
  LD H,$00
  ADD HL,HL
  LD BC,sprite_tbl
  ADD HL,BC
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD A,(DE)               ; a real sprite: see that it faces the right way
  AND A                   ;
  JP NZ,vflip_sprite_data ;
  INC SP                  ; no sprite: return from the caller as well
  INC SP                  ;
  RET                     ;

; Draw one object from the render list
;
; Used by the routine at render_obj.
;
; Called by render_obj for each object in depth order. Graphic 1 is not drawn:
; the record is emptied instead, by setting its graphic to 0, which frees the
; slot. That makes graphic 1 look like a marker for an object on its way out,
; but what sets it has not been traced from this range.
;
; IX the object
calc_pixel_XY_and_render:
  LD A,(IX+$00)           ; graphic 1?
  CP $01
  JR NZ,project_and_draw
  LD (IX+$00),$00         ; empty the record
  RET

; Project the object and draw it if it is on the screen
;
; Used by the routine at calc_pixel_XY_and_render.
project_and_draw:
  RES 4,(IX+$07)          ; no longer waiting to be drawn
  CALL calc_pixel_XY      ; above the top of the screen: nothing to draw
  RET NC                  ;

; Draw an object's sprite into the buffer, through its mask
;
; Used by the routines at print_lives_gfx, multiple_print_sprite,
; display_object, display_frame and transfer_sprite_and_print.
;
; A sprite is a header -- width in bytes in bits 0 to 3, the flip state in bits
; 6 and 7, then the height in rows -- and then a pair of bytes for every byte
; of every row: a mask and an image. Rows are drawn from the bottom up. Each
; background byte is cleared where the mask is set and then has the image put
; in, so a sprite punches its own shape out of whatever was drawn before it and
; objects can overlap in depth.
;
; The row loop at sprite_row is unrolled for the widest sprite, five bytes, and
; this routine patches it for the one in hand: the offset of the JR at
; sprite_row_jump decides how far into the unrolled code a row starts, and the
; operand of the ADD at sprite_next_row how far BC must then move to reach the
; next row up. There are two unrolled runs. A sprite whose pixel x is a
; multiple of 8 uses the plain one; any other uses the shifted one, which reads
; its bytes through the tables from shift_tbls up and so touches one byte more
; per row.
;
; The stack pointer is borrowed to read the sprite: SP is pointed at the data
; and each POP DE fetches a mask byte into E and its image byte into D. The
; real SP is kept in $5BA9 meanwhile. The listing has no EI anywhere, so the
; game runs with interrupts off and nothing can push onto the sprite while SP
; is borrowed.
;
; Bytes $18 and $19 come out as the width and height actually drawn, which
; wipe_next_object uses next frame to wipe the picture away. Only the top of
; the screen is clipped; nothing is clipped at the sides.
;
; IX the object: its graphic in byte 0, its pixel position in bytes $1A
; and $1B, its flip bits in byte 7
print_sprite:
  CALL flip_sprite        ; DE = the sprite, turned the way byte 7 asks
  LD A,(IX+$1A)           ; x within its byte; 0 goes to the aligned case at
                          ; sprite_aligned
  AND $07
  JR Z,sprite_aligned
  RLCA                    ; H = $F0 + 2 * the shift, the page pair
  AND $0E                 ; build_lookup_tbls built for it
  OR $F0                  ;
  LD H,A                  ;
  LD A,(DE)               ; the width from the header, plus one: the bytes a
  INC DE                  ; shifted row touches, into byte $18
  AND $07                 ;
  INC A                   ;
  LD B,A                  ;
  LD (IX+$18),A           ;
  DEC A                   ; the JR offset for sprite_row_jump: 16 bytes of code
  AND $07                 ; per byte of width, counted back from the end of the
  ADD A,A                 ; shifted run
  ADD A,A                 ;
  ADD A,A                 ;
  ADD A,A                 ;
  NEG                     ;
  ADD A,$50               ;

; Patch the row loop for this width, and cut the height to the screen
;
; Used by the routine at sprite_aligned.
;
; A the JR offset
; B the bytes a row touches
patch_sprite_rows:
  LD ($D7AD),A            ; the JR at sprite_row_jump
  LD A,B                  ; the step to the next row, into the ADD at
  CPL                     ; sprite_next_row: 33 less the bytes touched, since a
  ADD A,$22               ; row moves BC on one fewer than that
  LD ($D801),A            ;
  LD A,(DE)               ; the height, into byte $19
  INC DE                  ;
  LD (IX+$19),A           ;
  ADD A,(IX+$1B)          ; if the sprite would run past the top of the screen,
                          ; draw only the rows below it
  SUB $C0
  JR C,draw_sprite_rows
  NEG
  ADD A,(IX+$19)
  LD (IX+$19),A

; Draw the rows
;
; Used by the routine at patch_sprite_rows.
draw_sprite_rows:
  LD C,(IX+$1A)           ; BC = the buffer address of the sprite's bottom-left
                          ; byte
  LD B,(IX+$1B)
  CALL calc_vidbuf_addr
  LD ($5BA9),SP           ; SP onto the pixel data, just after the two header
  EX DE,HL                ; bytes
  LD SP,HL                ;
  EX DE,HL                ;
  LD A,(IX+$19)           ; A = the rows to draw; into the loop
  JR sprite_row

; The byte-aligned case, and the start of its unrolled run
;
; Used by the routine at print_sprite.
;
; For a sprite on a byte boundary each byte of a row is one unit of eight bytes
; of code: the background byte, cleared under the mask with CPL / OR E / CPL,
; has the image ORed in and is stored. Five units run on from the POP below,
; and the JR at sprite_row_jump is set to enter them as many units from the end
; as the sprite is wide.
sprite_aligned:
  LD A,(DE)               ; the width from the header, into byte $18
  INC DE                  ;
  AND $0F                 ;
  LD (IX+$18),A           ;
  LD B,A                  ; the JR offset: 8 bytes of code per byte of width,
  ADD A,A                 ; back from the end of the aligned run
  ADD A,A                 ;
  ADD A,A                 ;
  NEG                     ;
  SUB $06                 ;
  JR patch_sprite_rows
  POP DE                  ; the first two units of the aligned run
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

; The last three units of an aligned row
;
; Used by the routine at sprite_row_jump.
sprite_aligned_tail:
  POP DE                  ; three more units the same, the last without the INC
  LD A,(BC)               ; BC
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
  JP sprite_row_end       ; on to the next row

; Start a row
;
; Used by the routines at draw_sprite_rows and sprite_next_row.
;
; The row count goes to A', and A takes the first background byte: the shifted
; units expect the byte they are finishing to be in A already.
sprite_row:
  EX AF,AF'
  LD A,(BC)

; Jump into the row, then the shifted run
;
; The JR's offset byte is patched by patch_sprite_rows: back into the aligned
; run for a byte-aligned sprite, into the shifted run below for any other. Each
; shifted unit is 16 bytes of code for one source byte. The left part of the
; mask and image, looked up on page H, finishes the byte in A, which is stored;
; the right part, on page H + 1, starts the next buffer byte, which is left in
; A for the next unit. The last spill is stored after the fifth unit.
sprite_row_jump:
  JR sprite_aligned_tail  ; offset set by patch_sprite_rows
  POP DE                  ; the background byte in A, cleared under the mask
  LD L,E                  ; shifted right and with the image shifted right put
  AND (HL)                ; in; stored
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

; Step to the row above
;
; Used by the routine at sprite_aligned_tail.
sprite_row_end:
  LD A,C

; Move BC up a row, and loop
sprite_next_row:
  ADD A,$1E               ; the step, its operand patched by patch_sprite_rows
  LD C,A                  ; carried into B
  LD A,B                  ;
  ADC A,$00               ;
  LD B,A                  ;
  EX AF,AF'               ; the next row, until the height runs out
  DEC A                   ;
  JP NZ,sprite_row        ;
  LD SP,($5BA9)           ; the real stack pointer back
  RET                     ;

; Buffer address of a pixel position
;
; Used by the routines at print_text_single_colour, print_text, display_object,
; show_carried_slot, blit_2x8, wipe_rect and draw_sprite_rows.
;
; The buffer is plain rows of 32 bytes, the bottom line first, so the address
; is y * 32 + x / 8 from its start: BC shifted right three times.
;
; C the pixel x
; B the pixel y, counted up from the bottom of the screen
; BC on exit, the address in screen_buffer
calc_vidbuf_addr:
  PUSH HL                 ; BC / 8 = y * 32 + x / 8
  SRL B                   ;
  RR C                    ;
  SRL B                   ;
  RR C                    ;
  SRL B                   ;
  RR C                    ;
  LD HL,screen_buffer     ; plus the start of the buffer
  ADD HL,BC               ;
  LD C,L                  ;
  LD B,H                  ;
  POP HL                  ;
  RET

; Display address of a pixel position
;
; Used by the routines at show_carried_slot, blit_2x8 and wipe_rect.
;
; Turns the game's upward y into the display's line counted from the top by
; complementing it: 255 - y is that line plus 64, and the extra 64 is one third
; of the screen too many in the top bits, taken back by adding $38 instead of
; $40.
;
; C the pixel x
; B the pixel y, counted up from the bottom of the screen
; DE on exit, the display address of that byte
calc_vram_addr:
  LD A,C                  ; E = x / 8, the column
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  AND $1F                 ;
  LD E,A                  ;
  LD A,B                  ; the line within the character row, from bits 0 to 2
  CPL                     ; of 255 - y, kept in A'
  AND $07                 ;
  EX AF,AF'
  LD A,B                  ; bits 3 to 5, the character row within the third,
  CPL                     ; into the top of E
  RLCA                    ;
  RLCA                    ;
  AND $E0                 ;
  OR E                    ;
  LD E,A                  ;
  LD A,B                  ; bits 6 and 7, the third, with the line within the
  CPL                     ; row, and $38 for the extra third
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
; Used by the routines at text_attr_addr and show_carried_slot.
;
; HL is kept.
;
; H the pixel y, counted up from the bottom of the screen
; L the pixel x
; DE on exit, the attribute address
calc_attrib_addr:
  PUSH HL
  LD A,H                  ; H = (255 - y) / 8: the character row counted from
  CPL                     ; the top, plus 8
  LD H,A                  ;
  SRL H                   ;
  SRL H                   ;
  SRL H                   ;
  SRL H                   ; three more shifts across H and L: row * 32 + x / 8
  RR L                    ;
  SRL H                   ;
  RR L                    ;
  SRL H                   ;
  RR L                    ;
  LD DE,$5700             ; $5700 is the attribute file less those 8 rows
  ADD HL,DE               ;
  EX DE,HL                ;
  POP HL
  RET

; Turn a sprite's stored data to face the way its object wants
;
; Used by the routine at flip_sprite.
;
; Sprites are flipped in place, and the header remembers which way round the
; data now is: bit 7 of its first byte for upside down, bit 6 for mirrored.
; Bits 7 and 6 of the object's byte 7 say which way it wants to be drawn. Where
; they disagree the data is turned and the header bit toggled. An object that
; keeps facing one way therefore costs nothing after the first frame; two
; objects that share a sprite but face opposite ways turn it back and forth
; every time each is drawn.
;
; This part does the vertical flip, swapping whole rows end for end;
; hflip_sprite_data does the mirror. DE is kept.
;
; DE the sprite's header
; IX the object
vflip_sprite_data:
  PUSH DE                 ; the header's bit 7 against the object's: the same
  LD A,(DE)               ; means no vertical flip
  XOR (IX+$07)            ;
  AND $80                 ;
  JR Z,hflip_sprite_data  ;
  LD A,(DE)               ; toggle the header's bit
  XOR $80                 ;
  LD (DE),A               ;
  RLCA                    ; B = bytes per row: the width in bits 0 to 3, times
  AND $1E                 ; two for the mask and image bytes
  LD B,A                  ;
  INC DE                  ; C = the height in rows
  LD A,(DE)               ;
  LD C,A                  ;
  INC DE                  ;
  PUSH DE                 ; HL = the data's length; DE = one past the end of
  LD E,B                  ; the data, and HL its start
  LD D,$00                ;
  CALL HL_equals_DE_x_A   ;
  POP DE                  ;
  ADD HL,DE               ;
  EX DE,HL                ;
  LD A,B                  ; DE on the last byte of the last row, HL on the last
  CALL add_HL_A           ; byte of the first
  DEC DE                  ;
  DEC HL                  ;
  SRL C                   ; swap rows in pairs: half the height

; Swap the next pair of rows
;
; Used by the routine at vflip_sprite_line_pair.
vflip_row_pair:
  PUSH BC

; Swap two rows byte by byte, working backwards
vflip_sprite_line_pair:
  LD A,(DE)               ; swap a byte of each row
  LD C,(HL)               ;
  LD (HL),A               ;
  LD A,C                  ;
  LD (DE),A               ;
  DEC HL                  ;
  DEC DE                  ;
  DJNZ vflip_sprite_line_pair
  POP BC                  ; HL on to the end of the next row down; DE is
  LD A,B                  ; already at the end of the row before its last
  CALL add_HL_A           ;
  LD A,B                  ;
  CALL add_HL_A           ;
  DEC C                   ; the next pair
  JR NZ,vflip_row_pair    ;

; Mirror the sprite if its object wants it the other way round
;
; Used by the routine at vflip_sprite_data.
;
; Mirroring a row is two things at once: the order of its bytes is reversed,
; and so are the bits of each byte. The bytes of a row are pushed as mask and
; image pairs, each byte reversed through the table at reverse_bits_tbl on the
; way; popped off again they come back last first, and are written over the
; same row.
hflip_sprite_data:
  POP DE                  ; the header's bit 6 against the object's
  PUSH DE                 ;
  LD A,(DE)               ;
  XOR (IX+$07)            ;
  AND $40                 ;
  JR Z,flip_done          ;
  LD A,(DE)               ; toggle the header's bit; B and C = the width in
  XOR $40                 ; bytes
  LD (DE),A               ;
  AND $0F                 ;
  LD B,A                  ;
  LD C,A                  ;
  INC DE                  ; the height into A'
  LD A,(DE)               ;
  EX AF,AF'               ;
  INC DE                  ;
  EX DE,HL                ; HL' reads and HL writes, both from the first row;
  PUSH HL                 ; B' = $F1, the page of the bit-reversal table
  EXX                     ;
  POP HL                  ;
  LD B,$F1                ;
  EXX                     ;

; Push a row's pairs, each byte reversed
;
; Used by the routine at hflip_write_row.
hflip_read_row:
  EXX                     ; E' = the mask byte reversed, D' = the image byte
  LD C,(HL)               ; reversed
  LD A,(BC)               ;
  LD E,A                  ;
  INC HL                  ;
  LD C,(HL)               ;
  LD A,(BC)               ;
  LD D,A                  ;
  INC HL                  ;
  PUSH DE                 ; onto the stack, to come back last first
  EXX
  DJNZ hflip_read_row
  LD B,C                  ; the width again for the writing

; Write the row back in the reverse order
hflip_write_row:
  POP DE                  ; a pair back, still mask then image
  LD (HL),E               ;
  INC HL                  ;
  LD (HL),D               ;
  INC HL                  ;
  DJNZ hflip_write_row    ;
  EX AF,AF'               ; the next row, until the height runs out
  DEC A                   ;
  JR Z,flip_done          ;
  EX AF,AF'               ;
  LD B,C                  ;
  JR hflip_read_row       ;

; Return with DE on the header
;
; Used by the routines at hflip_sprite_data and hflip_write_row.
flip_done:
  POP DE
  RET

; Copyright notice
;
; Twenty-one characters of plain text: the year and the initials of Ashby
; Computers and Graphics, the company behind Ultimate. No instruction in the
; listing refers to its address; it sits between the last routine and the
; screen buffer for anyone who looks through the memory.
copyright_notice:
  DEFM "COPYRIGHT 1984 A.C.G."

; The screen buffer
;
; 6144 bytes -- one screen's worth of bitmap, no attributes. The drawing code
; composes a whole room here and then copies it to the display in one go, so a
; half-drawn room is never visible.
screen_buffer:
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
  DEFB $00,$00,$3C,$00,$7C,$F0,$7C,$7C
  DEFB $00,$66,$00,$7C,$00,$0E,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$42,$00,$18,$98,$C6,$18
  DEFB $00,$DB,$18,$E6,$18,$66,$18,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$99,$00,$18,$0C,$C6,$1A
  DEFB $00,$CE,$18,$C2,$18,$F6,$18,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$A1,$00,$18,$7C,$FE,$FE
  DEFB $00,$46,$00,$C0,$00,$CE,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$A1,$00,$18,$C6,$7C,$9A
  DEFB $00,$66,$00,$40,$00,$C6,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$99,$00,$58,$C6,$6C,$58
  DEFB $00,$2E,$00,$60,$00,$60,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$42,$00,$38,$C6,$6C,$38
  DEFB $00,$1C,$00,$32,$00,$30,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$3C,$00,$18,$7C,$38,$18
  DEFB $00,$0C,$00,$0E,$00,$0E,$00,$00
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
  DEFB $00,$00,$00,$00,$00,$00,$38,$00
  DEFB $7C,$18,$66,$E6,$18,$00,$0E,$66
  DEFB $EE,$C6,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$6C,$00
  DEFB $C6,$18,$DB,$6C,$18,$00,$66,$DB
  DEFB $C6,$7A,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$D6,$00
  DEFB $86,$18,$CE,$78,$18,$00,$F6,$CE
  DEFB $D6,$60,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$D6,$00
  DEFB $06,$18,$46,$7E,$18,$00,$CE,$46
  DEFB $D6,$64,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$D6,$00
  DEFB $3C,$18,$66,$76,$18,$00,$C6,$66
  DEFB $D6,$7C,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$D6,$00
  DEFB $60,$98,$2E,$66,$98,$00,$60,$2E
  DEFB $EE,$64,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$6C,$00
  DEFB $64,$9A,$1C,$6C,$9A,$00,$30,$1C
  DEFB $EE,$60,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$38,$00
  DEFB $38,$FE,$0C,$F8,$FE,$00,$0E,$0C
  DEFB $C6,$FE,$00,$00,$00,$00,$00,$00
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
  DEFB $00,$00,$00,$00,$00,$00,$7C,$00
  DEFB $FC,$7C,$E6,$C6,$7C,$18,$7C,$38
  DEFB $DE,$66,$FE,$00,$7C,$38,$DE,$18
  DEFB $E6,$38,$FE,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$86,$00
  DEFB $66,$18,$6C,$7A,$E6,$18,$18,$6C
  DEFB $C8,$DB,$62,$00,$E6,$6C,$C8,$18
  DEFB $6C,$6C,$62,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$06,$00
  DEFB $66,$18,$78,$60,$C2,$18,$18,$C6
  DEFB $C4,$CE,$60,$00,$C2,$C6,$C4,$18
  DEFB $78,$C6,$60,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$06,$00
  DEFB $66,$18,$7E,$64,$C0,$18,$18,$C6
  DEFB $E4,$46,$60,$00,$C0,$C6,$E4,$18
  DEFB $7E,$C6,$60,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$FC,$00
  DEFB $6C,$18,$76,$7C,$40,$18,$18,$C6
  DEFB $E6,$66,$60,$00,$40,$C6,$E6,$18
  DEFB $76,$C6,$60,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$C0,$00
  DEFB $68,$18,$66,$64,$60,$98,$18,$C6
  DEFB $D6,$2E,$60,$00,$60,$C6,$D6,$98
  DEFB $66,$C6,$60,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$C2,$00
  DEFB $70,$18,$6C,$60,$32,$9A,$18,$6C
  DEFB $D6,$1C,$60,$00,$32,$6C,$D6,$9A
  DEFB $6C,$6C,$60,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$FE,$00
  DEFB $60,$7C,$F8,$FE,$0E,$FE,$7C,$38
  DEFB $CC,$0C,$E0,$00,$0E,$38,$CC,$FE
  DEFB $F8,$38,$E0,$00,$00,$00,$00,$00
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
  DEFB $00,$00,$00,$00,$00,$00,$7C,$00
  DEFB $7C,$DE,$18,$C6,$E6,$60,$66,$7C
  DEFB $C6,$00,$7C,$7C,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$18,$00
  DEFB $18,$C8,$18,$7A,$6C,$60,$DB,$E6
  DEFB $7A,$00,$18,$18,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$1A,$00
  DEFB $18,$C4,$18,$60,$78,$64,$CE,$C2
  DEFB $60,$00,$18,$18,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$FE,$00
  DEFB $18,$E4,$18,$64,$7E,$7C,$46,$C0
  DEFB $64,$00,$18,$18,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$9A,$00
  DEFB $18,$E6,$18,$7C,$76,$64,$66,$40
  DEFB $7C,$00,$18,$18,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$58,$00
  DEFB $18,$D6,$98,$64,$66,$60,$2E,$60
  DEFB $64,$00,$18,$18,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$38,$00
  DEFB $18,$D6,$9A,$60,$6C,$7A,$1C,$32
  DEFB $60,$00,$18,$18,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$18,$00
  DEFB $7C,$CC,$FE,$FE,$F8,$C6,$0C,$0E
  DEFB $FE,$00,$7C,$7C,$00,$00,$00,$00
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
  DEFB $00,$00,$00,$00,$00,$00,$FC,$00
  DEFB $7C,$66,$E6,$7C,$38,$E6,$00,$00
  DEFB $00,$1C,$38,$38,$7C,$18,$7C,$7C
  DEFB $F6,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$86,$00
  DEFB $E6,$D6,$6C,$C6,$6C,$6C,$00,$00
  DEFB $00,$7E,$6C,$4C,$C6,$18,$18,$E6
  DEFB $64,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$86,$00
  DEFB $C2,$D6,$78,$86,$C6,$78,$00,$00
  DEFB $00,$C6,$C6,$04,$86,$18,$18,$C2
  DEFB $64,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$0E,$00
  DEFB $C0,$CE,$7E,$06,$C6,$7E,$00,$00
  DEFB $00,$86,$C6,$06,$06,$18,$18,$C0
  DEFB $6C,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$3C,$00
  DEFB $40,$4E,$76,$3C,$C6,$76,$00,$00
  DEFB $00,$86,$C6,$0E,$3C,$18,$18,$40
  DEFB $78,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$0C,$00
  DEFB $60,$46,$66,$60,$C6,$66,$00,$00
  DEFB $00,$06,$C6,$16,$60,$98,$18,$60
  DEFB $70,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$4C,$00
  DEFB $32,$26,$6C,$64,$6C,$6C,$00,$00
  DEFB $00,$06,$6C,$66,$64,$9A,$18,$32
  DEFB $68,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$38,$00
  DEFB $0E,$F6,$F8,$38,$38,$F8,$00,$00
  DEFB $00,$1E,$38,$86,$38,$FE,$7C,$0E
  DEFB $E4,$00,$00,$00,$00,$00,$00,$00
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
  DEFB $00,$00,$00,$00,$00,$00,$FE,$00
  DEFB $F6,$C6,$EE,$F0,$7C,$18,$38,$DE
  DEFB $00,$1C,$38,$38,$7C,$18,$7C,$7C
  DEFB $F6,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$C2,$00
  DEFB $64,$7A,$C6,$60,$C6,$18,$6C,$C8
  DEFB $00,$7E,$6C,$4C,$C6,$18,$18,$E6
  DEFB $64,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$C2,$00
  DEFB $64,$60,$D6,$60,$86,$18,$C6,$C4
  DEFB $00,$C6,$C6,$04,$86,$18,$18,$C2
  DEFB $64,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$60,$00
  DEFB $6C,$64,$D6,$6E,$06,$18,$C6,$E4
  DEFB $00,$86,$C6,$06,$06,$18,$18,$C0
  DEFB $6C,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$3C,$00
  DEFB $78,$7C,$D6,$76,$3C,$18,$C6,$E6
  DEFB $00,$86,$C6,$0E,$3C,$18,$18,$40
  DEFB $78,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$0C,$00
  DEFB $70,$64,$EE,$66,$60,$98,$C6,$D6
  DEFB $00,$06,$C6,$16,$60,$98,$18,$60
  DEFB $70,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$4C,$00
  DEFB $68,$60,$EE,$6C,$64,$9A,$6C,$D6
  DEFB $00,$06,$6C,$66,$64,$9A,$18,$32
  DEFB $68,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$38,$00
  DEFB $E4,$FE,$C6,$F8,$38,$FE,$38,$CC
  DEFB $00,$1E,$38,$86,$38,$FE,$7C,$0E
  DEFB $E4,$00,$00,$00,$00,$00,$00,$00
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
  DEFB $00,$00,$00,$00,$00,$00,$7C,$00
  DEFB $F6,$C6,$38,$FC,$38,$66,$E6,$FC
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$18,$00
  DEFB $64,$7A,$4C,$66,$6C,$DB,$6C,$66
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$18,$00
  DEFB $64,$60,$04,$66,$C6,$CE,$78,$66
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$18,$00
  DEFB $6C,$64,$06,$6C,$C6,$46,$7E,$66
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$18,$00
  DEFB $78,$7C,$0E,$78,$C6,$66,$76,$6C
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$58,$00
  DEFB $70,$64,$16,$6C,$C6,$2E,$66,$68
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$38,$00
  DEFB $68,$60,$66,$6C,$6C,$1C,$6C,$70
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$18,$00
  DEFB $E4,$FE,$86,$F8,$38,$0C,$F8,$60
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
  DEFB $00,$00,$00,$F6,$DE,$7C,$0E,$EE
  DEFB $18,$00,$FE,$38,$E6,$C6,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$64,$C8,$18,$66,$C6
  DEFB $18,$00,$62,$6C,$6C,$7A,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$64,$C4,$18,$F6,$C6
  DEFB $18,$00,$60,$C6,$78,$60,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$6C,$E4,$18,$CE,$C6
  DEFB $18,$00,$60,$C6,$7E,$64,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$78,$E6,$18,$C6,$FE
  DEFB $18,$00,$60,$C6,$76,$7C,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$70,$D6,$18,$60,$C6
  DEFB $98,$00,$60,$C6,$66,$64,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$68,$D6,$18,$30,$C6
  DEFB $9A,$00,$60,$6C,$6C,$60,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$E4,$CC,$7C,$0E,$EE
  DEFB $FE,$00,$E0,$38,$F8,$FE,$00,$00
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

; Thirteen bytes nothing uses
;
; Zeros between the end of the screen buffer and the page-aligned tables at
; reverse_bits_tbl. Nothing in the code refers to them: the tables start on a
; page boundary, and these are what is left of the page the buffer ends in.
spare_bytes:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00

; Bit reversal, built at run time
;
; A page holding every byte value with its bits reversed, which is how a sprite
; is mirrored left to right (hflip_sprite_data). Empty in a freshly loaded game
; and filled by build_lookup_tbls. The disassembly covers the region anyway: it
; is part of the map, and a snapshot taken during play catches it holding real
; values.
reverse_bits_tbl:
  DEFB $00,$80,$40,$C0,$20,$A0,$60,$E0
  DEFB $10,$90,$50,$D0,$30,$B0,$70,$F0
  DEFB $08,$88,$48,$C8,$28,$A8,$68,$E8
  DEFB $18,$98,$58,$D8,$38,$B8,$78,$F8
  DEFB $04,$84,$44,$C4,$24,$A4,$64,$E4
  DEFB $14,$94,$54,$D4,$34,$B4,$74,$F4
  DEFB $0C,$8C,$4C,$CC,$2C,$AC,$6C,$EC
  DEFB $1C,$9C,$5C,$DC,$3C,$BC,$7C,$FC
  DEFB $02,$82,$42,$C2,$22,$A2,$62,$E2
  DEFB $12,$92,$52,$D2,$32,$B2,$72,$F2
  DEFB $0A,$8A,$4A,$CA,$2A,$AA,$6A,$EA
  DEFB $1A,$9A,$5A,$DA,$3A,$BA,$7A,$FA
  DEFB $06,$86,$46,$C6,$26,$A6,$66,$E6
  DEFB $16,$96,$56,$D6,$36,$B6,$76,$F6
  DEFB $0E,$8E,$4E,$CE,$2E,$AE,$6E,$EE
  DEFB $1E,$9E,$5E,$DE,$3E,$BE,$7E,$FE
  DEFB $01,$81,$41,$C1,$21,$A1,$61,$E1
  DEFB $11,$91,$51,$D1,$31,$B1,$71,$F1
  DEFB $09,$89,$49,$C9,$29,$A9,$69,$E9
  DEFB $19,$99,$59,$D9,$39,$B9,$79,$F9
  DEFB $05,$85,$45,$C5,$25,$A5,$65,$E5
  DEFB $15,$95,$55,$D5,$35,$B5,$75,$F5
  DEFB $0D,$8D,$4D,$CD,$2D,$AD,$6D,$ED
  DEFB $1D,$9D,$5D,$DD,$3D,$BD,$7D,$FD
  DEFB $03,$83,$43,$C3,$23,$A3,$63,$E3
  DEFB $13,$93,$53,$D3,$33,$B3,$73,$F3
  DEFB $0B,$8B,$4B,$CB,$2B,$AB,$6B,$EB
  DEFB $1B,$9B,$5B,$DB,$3B,$BB,$7B,$FB
  DEFB $07,$87,$47,$C7,$27,$A7,$67,$E7
  DEFB $17,$97,$57,$D7,$37,$B7,$77,$F7
  DEFB $0F,$8F,$4F,$CF,$2F,$AF,$6F,$EF
  DEFB $1F,$9F,$5F,$DF,$3F,$BF,$7F,$FF

; Shift tables, built at run time
;
; Fourteen pages, a pair for each shift from 1 to 7: page $F0 + 2s holds every
; byte shifted right s places and the page above it the bits that fall out into
; the next byte, both stored complemented, so that one lookup serves to clear
; the bits under a sprite's mask and to add its image (sprite_row_jump). Filled
; by build_lookup_tbls; empty in a freshly loaded game.
shift_tbls:
  DEFB $FF,$FF,$FE,$FE,$FD,$FD,$FC,$FC
  DEFB $FB,$FB,$FA,$FA,$F9,$F9,$F8,$F8
  DEFB $F7,$F7,$F6,$F6,$F5,$F5,$F4,$F4
  DEFB $F3,$F3,$F2,$F2,$F1,$F1,$F0,$F0
  DEFB $EF,$EF,$EE,$EE,$ED,$ED,$EC,$EC
  DEFB $EB,$EB,$EA,$EA,$E9,$E9,$E8,$E8
  DEFB $E7,$E7,$E6,$E6,$E5,$E5,$E4,$E4
  DEFB $E3,$E3,$E2,$E2,$E1,$E1,$E0,$E0
  DEFB $DF,$DF,$DE,$DE,$DD,$DD,$DC,$DC
  DEFB $DB,$DB,$DA,$DA,$D9,$D9,$D8,$D8
  DEFB $D7,$D7,$D6,$D6,$D5,$D5,$D4,$D4
  DEFB $D3,$D3,$D2,$D2,$D1,$D1,$D0,$D0
  DEFB $CF,$CF,$CE,$CE,$CD,$CD,$CC,$CC
  DEFB $CB,$CB,$CA,$CA,$C9,$C9,$C8,$C8
  DEFB $C7,$C7,$C6,$C6,$C5,$C5,$C4,$C4
  DEFB $C3,$C3,$C2,$C2,$C1,$C1,$C0,$C0
  DEFB $BF,$BF,$BE,$BE,$BD,$BD,$BC,$BC
  DEFB $BB,$BB,$BA,$BA,$B9,$B9,$B8,$B8
  DEFB $B7,$B7,$B6,$B6,$B5,$B5,$B4,$B4
  DEFB $B3,$B3,$B2,$B2,$B1,$B1,$B0,$B0
  DEFB $AF,$AF,$AE,$AE,$AD,$AD,$AC,$AC
  DEFB $AB,$AB,$AA,$AA,$A9,$A9,$A8,$A8
  DEFB $A7,$A7,$A6,$A6,$A5,$A5,$A4,$A4
  DEFB $A3,$A3,$A2,$A2,$A1,$A1,$A0,$A0
  DEFB $9F,$9F,$9E,$9E,$9D,$9D,$9C,$9C
  DEFB $9B,$9B,$9A,$9A,$99,$99,$98,$98
  DEFB $97,$97,$96,$96,$95,$95,$94,$94
  DEFB $93,$93,$92,$92,$91,$91,$90,$90
  DEFB $8F,$8F,$8E,$8E,$8D,$8D,$8C,$8C
  DEFB $8B,$8B,$8A,$8A,$89,$89,$88,$88
  DEFB $87,$87,$86,$86,$85,$85,$84,$84
  DEFB $83,$83,$82,$82,$81,$81,$80,$80
  DEFB $FF,$7F,$FF,$7F,$FF,$7F,$FF,$7F
  DEFB $FF,$7F,$FF,$7F,$FF,$7F,$FF,$7F
  DEFB $FF,$7F,$FF,$7F,$FF,$7F,$FF,$7F
  DEFB $FF,$7F,$FF,$7F,$FF,$7F,$FF,$7F
  DEFB $FF,$7F,$FF,$7F,$FF,$7F,$FF,$7F
  DEFB $FF,$7F,$FF,$7F,$FF,$7F,$FF,$7F
  DEFB $FF,$7F,$FF,$7F,$FF,$7F,$FF,$7F
  DEFB $FF,$7F,$FF,$7F,$FF,$7F,$FF,$7F
  DEFB $FF,$7F,$FF,$7F,$FF,$7F,$FF,$7F
  DEFB $FF,$7F,$FF,$7F,$FF,$7F,$FF,$7F
  DEFB $FF,$7F,$FF,$7F,$FF,$7F,$FF,$7F
  DEFB $FF,$7F,$FF,$7F,$FF,$7F,$FF,$7F
  DEFB $FF,$7F,$FF,$7F,$FF,$7F,$FF,$7F
  DEFB $FF,$7F,$FF,$7F,$FF,$7F,$FF,$7F
  DEFB $FF,$7F,$FF,$7F,$FF,$7F,$FF,$7F
  DEFB $FF,$7F,$FF,$7F,$FF,$7F,$FF,$7F
  DEFB $FF,$7F,$FF,$7F,$FF,$7F,$FF,$7F
  DEFB $FF,$7F,$FF,$7F,$FF,$7F,$FF,$7F
  DEFB $FF,$7F,$FF,$7F,$FF,$7F,$FF,$7F
  DEFB $FF,$7F,$FF,$7F,$FF,$7F,$FF,$7F
  DEFB $FF,$7F,$FF,$7F,$FF,$7F,$FF,$7F
  DEFB $FF,$7F,$FF,$7F,$FF,$7F,$FF,$7F
  DEFB $FF,$7F,$FF,$7F,$FF,$7F,$FF,$7F
  DEFB $FF,$7F,$FF,$7F,$FF,$7F,$FF,$7F
  DEFB $FF,$7F,$FF,$7F,$FF,$7F,$FF,$7F
  DEFB $FF,$7F,$FF,$7F,$FF,$7F,$FF,$7F
  DEFB $FF,$7F,$FF,$7F,$FF,$7F,$FF,$7F
  DEFB $FF,$7F,$FF,$7F,$FF,$7F,$FF,$7F
  DEFB $FF,$7F,$FF,$7F,$FF,$7F,$FF,$7F
  DEFB $FF,$7F,$FF,$7F,$FF,$7F,$FF,$7F
  DEFB $FF,$7F,$FF,$7F,$FF,$7F,$FF,$7F
  DEFB $FF,$7F,$FF,$7F,$FF,$7F,$FF,$7F
  DEFB $FF,$FF,$FF,$FF,$FE,$FE,$FE,$FE
  DEFB $FD,$FD,$FD,$FD,$FC,$FC,$FC,$FC
  DEFB $FB,$FB,$FB,$FB,$FA,$FA,$FA,$FA
  DEFB $F9,$F9,$F9,$F9,$F8,$F8,$F8,$F8
  DEFB $F7,$F7,$F7,$F7,$F6,$F6,$F6,$F6
  DEFB $F5,$F5,$F5,$F5,$F4,$F4,$F4,$F4
  DEFB $F3,$F3,$F3,$F3,$F2,$F2,$F2,$F2
  DEFB $F1,$F1,$F1,$F1,$F0,$F0,$F0,$F0
  DEFB $EF,$EF,$EF,$EF,$EE,$EE,$EE,$EE
  DEFB $ED,$ED,$ED,$ED,$EC,$EC,$EC,$EC
  DEFB $EB,$EB,$EB,$EB,$EA,$EA,$EA,$EA
  DEFB $E9,$E9,$E9,$E9,$E8,$E8,$E8,$E8
  DEFB $E7,$E7,$E7,$E7,$E6,$E6,$E6,$E6
  DEFB $E5,$E5,$E5,$E5,$E4,$E4,$E4,$E4
  DEFB $E3,$E3,$E3,$E3,$E2,$E2,$E2,$E2
  DEFB $E1,$E1,$E1,$E1,$E0,$E0,$E0,$E0
  DEFB $DF,$DF,$DF,$DF,$DE,$DE,$DE,$DE
  DEFB $DD,$DD,$DD,$DD,$DC,$DC,$DC,$DC
  DEFB $DB,$DB,$DB,$DB,$DA,$DA,$DA,$DA
  DEFB $D9,$D9,$D9,$D9,$D8,$D8,$D8,$D8
  DEFB $D7,$D7,$D7,$D7,$D6,$D6,$D6,$D6
  DEFB $D5,$D5,$D5,$D5,$D4,$D4,$D4,$D4
  DEFB $D3,$D3,$D3,$D3,$D2,$D2,$D2,$D2
  DEFB $D1,$D1,$D1,$D1,$D0,$D0,$D0,$D0
  DEFB $CF,$CF,$CF,$CF,$CE,$CE,$CE,$CE
  DEFB $CD,$CD,$CD,$CD,$CC,$CC,$CC,$CC
  DEFB $CB,$CB,$CB,$CB,$CA,$CA,$CA,$CA
  DEFB $C9,$C9,$C9,$C9,$C8,$C8,$C8,$C8
  DEFB $C7,$C7,$C7,$C7,$C6,$C6,$C6,$C6
  DEFB $C5,$C5,$C5,$C5,$C4,$C4,$C4,$C4
  DEFB $C3,$C3,$C3,$C3,$C2,$C2,$C2,$C2
  DEFB $C1,$C1,$C1,$C1,$C0,$C0,$C0,$C0
  DEFB $FF,$BF,$7F,$3F,$FF,$BF,$7F,$3F
  DEFB $FF,$BF,$7F,$3F,$FF,$BF,$7F,$3F
  DEFB $FF,$BF,$7F,$3F,$FF,$BF,$7F,$3F
  DEFB $FF,$BF,$7F,$3F,$FF,$BF,$7F,$3F
  DEFB $FF,$BF,$7F,$3F,$FF,$BF,$7F,$3F
  DEFB $FF,$BF,$7F,$3F,$FF,$BF,$7F,$3F
  DEFB $FF,$BF,$7F,$3F,$FF,$BF,$7F,$3F
  DEFB $FF,$BF,$7F,$3F,$FF,$BF,$7F,$3F
  DEFB $FF,$BF,$7F,$3F,$FF,$BF,$7F,$3F
  DEFB $FF,$BF,$7F,$3F,$FF,$BF,$7F,$3F
  DEFB $FF,$BF,$7F,$3F,$FF,$BF,$7F,$3F
  DEFB $FF,$BF,$7F,$3F,$FF,$BF,$7F,$3F
  DEFB $FF,$BF,$7F,$3F,$FF,$BF,$7F,$3F
  DEFB $FF,$BF,$7F,$3F,$FF,$BF,$7F,$3F
  DEFB $FF,$BF,$7F,$3F,$FF,$BF,$7F,$3F
  DEFB $FF,$BF,$7F,$3F,$FF,$BF,$7F,$3F
  DEFB $FF,$BF,$7F,$3F,$FF,$BF,$7F,$3F
  DEFB $FF,$BF,$7F,$3F,$FF,$BF,$7F,$3F
  DEFB $FF,$BF,$7F,$3F,$FF,$BF,$7F,$3F
  DEFB $FF,$BF,$7F,$3F,$FF,$BF,$7F,$3F
  DEFB $FF,$BF,$7F,$3F,$FF,$BF,$7F,$3F
  DEFB $FF,$BF,$7F,$3F,$FF,$BF,$7F,$3F
  DEFB $FF,$BF,$7F,$3F,$FF,$BF,$7F,$3F
  DEFB $FF,$BF,$7F,$3F,$FF,$BF,$7F,$3F
  DEFB $FF,$BF,$7F,$3F,$FF,$BF,$7F,$3F
  DEFB $FF,$BF,$7F,$3F,$FF,$BF,$7F,$3F
  DEFB $FF,$BF,$7F,$3F,$FF,$BF,$7F,$3F
  DEFB $FF,$BF,$7F,$3F,$FF,$BF,$7F,$3F
  DEFB $FF,$BF,$7F,$3F,$FF,$BF,$7F,$3F
  DEFB $FF,$BF,$7F,$3F,$FF,$BF,$7F,$3F
  DEFB $FF,$BF,$7F,$3F,$FF,$BF,$7F,$3F
  DEFB $FF,$BF,$7F,$3F,$FF,$BF,$7F,$3F
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC
  DEFB $FB,$FB,$FB,$FB,$FB,$FB,$FB,$FB
  DEFB $FA,$FA,$FA,$FA,$FA,$FA,$FA,$FA
  DEFB $F9,$F9,$F9,$F9,$F9,$F9,$F9,$F9
  DEFB $F8,$F8,$F8,$F8,$F8,$F8,$F8,$F8
  DEFB $F7,$F7,$F7,$F7,$F7,$F7,$F7,$F7
  DEFB $F6,$F6,$F6,$F6,$F6,$F6,$F6,$F6
  DEFB $F5,$F5,$F5,$F5,$F5,$F5,$F5,$F5
  DEFB $F4,$F4,$F4,$F4,$F4,$F4,$F4,$F4
  DEFB $F3,$F3,$F3,$F3,$F3,$F3,$F3,$F3
  DEFB $F2,$F2,$F2,$F2,$F2,$F2,$F2,$F2
  DEFB $F1,$F1,$F1,$F1,$F1,$F1,$F1,$F1
  DEFB $F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0
  DEFB $EF,$EF,$EF,$EF,$EF,$EF,$EF,$EF
  DEFB $EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE
  DEFB $ED,$ED,$ED,$ED,$ED,$ED,$ED,$ED
  DEFB $EC,$EC,$EC,$EC,$EC,$EC,$EC,$EC
  DEFB $EB,$EB,$EB,$EB,$EB,$EB,$EB,$EB
  DEFB $EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA
  DEFB $E9,$E9,$E9,$E9,$E9,$E9,$E9,$E9
  DEFB $E8,$E8,$E8,$E8,$E8,$E8,$E8,$E8
  DEFB $E7,$E7,$E7,$E7,$E7,$E7,$E7,$E7
  DEFB $E6,$E6,$E6,$E6,$E6,$E6,$E6,$E6
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E4,$E4,$E4,$E4,$E4,$E4,$E4,$E4
  DEFB $E3,$E3,$E3,$E3,$E3,$E3,$E3,$E3
  DEFB $E2,$E2,$E2,$E2,$E2,$E2,$E2,$E2
  DEFB $E1,$E1,$E1,$E1,$E1,$E1,$E1,$E1
  DEFB $E0,$E0,$E0,$E0,$E0,$E0,$E0,$E0
  DEFB $FF,$DF,$BF,$9F,$7F,$5F,$3F,$1F
  DEFB $FF,$DF,$BF,$9F,$7F,$5F,$3F,$1F
  DEFB $FF,$DF,$BF,$9F,$7F,$5F,$3F,$1F
  DEFB $FF,$DF,$BF,$9F,$7F,$5F,$3F,$1F
  DEFB $FF,$DF,$BF,$9F,$7F,$5F,$3F,$1F
  DEFB $FF,$DF,$BF,$9F,$7F,$5F,$3F,$1F
  DEFB $FF,$DF,$BF,$9F,$7F,$5F,$3F,$1F
  DEFB $FF,$DF,$BF,$9F,$7F,$5F,$3F,$1F
  DEFB $FF,$DF,$BF,$9F,$7F,$5F,$3F,$1F
  DEFB $FF,$DF,$BF,$9F,$7F,$5F,$3F,$1F
  DEFB $FF,$DF,$BF,$9F,$7F,$5F,$3F,$1F
  DEFB $FF,$DF,$BF,$9F,$7F,$5F,$3F,$1F
  DEFB $FF,$DF,$BF,$9F,$7F,$5F,$3F,$1F
  DEFB $FF,$DF,$BF,$9F,$7F,$5F,$3F,$1F
  DEFB $FF,$DF,$BF,$9F,$7F,$5F,$3F,$1F
  DEFB $FF,$DF,$BF,$9F,$7F,$5F,$3F,$1F
  DEFB $FF,$DF,$BF,$9F,$7F,$5F,$3F,$1F
  DEFB $FF,$DF,$BF,$9F,$7F,$5F,$3F,$1F
  DEFB $FF,$DF,$BF,$9F,$7F,$5F,$3F,$1F
  DEFB $FF,$DF,$BF,$9F,$7F,$5F,$3F,$1F
  DEFB $FF,$DF,$BF,$9F,$7F,$5F,$3F,$1F
  DEFB $FF,$DF,$BF,$9F,$7F,$5F,$3F,$1F
  DEFB $FF,$DF,$BF,$9F,$7F,$5F,$3F,$1F
  DEFB $FF,$DF,$BF,$9F,$7F,$5F,$3F,$1F
  DEFB $FF,$DF,$BF,$9F,$7F,$5F,$3F,$1F
  DEFB $FF,$DF,$BF,$9F,$7F,$5F,$3F,$1F
  DEFB $FF,$DF,$BF,$9F,$7F,$5F,$3F,$1F
  DEFB $FF,$DF,$BF,$9F,$7F,$5F,$3F,$1F
  DEFB $FF,$DF,$BF,$9F,$7F,$5F,$3F,$1F
  DEFB $FF,$DF,$BF,$9F,$7F,$5F,$3F,$1F
  DEFB $FF,$DF,$BF,$9F,$7F,$5F,$3F,$1F
  DEFB $FF,$DF,$BF,$9F,$7F,$5F,$3F,$1F
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC
  DEFB $FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC
  DEFB $FB,$FB,$FB,$FB,$FB,$FB,$FB,$FB
  DEFB $FB,$FB,$FB,$FB,$FB,$FB,$FB,$FB
  DEFB $FA,$FA,$FA,$FA,$FA,$FA,$FA,$FA
  DEFB $FA,$FA,$FA,$FA,$FA,$FA,$FA,$FA
  DEFB $F9,$F9,$F9,$F9,$F9,$F9,$F9,$F9
  DEFB $F9,$F9,$F9,$F9,$F9,$F9,$F9,$F9
  DEFB $F8,$F8,$F8,$F8,$F8,$F8,$F8,$F8
  DEFB $F8,$F8,$F8,$F8,$F8,$F8,$F8,$F8
  DEFB $F7,$F7,$F7,$F7,$F7,$F7,$F7,$F7
  DEFB $F7,$F7,$F7,$F7,$F7,$F7,$F7,$F7
  DEFB $F6,$F6,$F6,$F6,$F6,$F6,$F6,$F6
  DEFB $F6,$F6,$F6,$F6,$F6,$F6,$F6,$F6
  DEFB $F5,$F5,$F5,$F5,$F5,$F5,$F5,$F5
  DEFB $F5,$F5,$F5,$F5,$F5,$F5,$F5,$F5
  DEFB $F4,$F4,$F4,$F4,$F4,$F4,$F4,$F4
  DEFB $F4,$F4,$F4,$F4,$F4,$F4,$F4,$F4
  DEFB $F3,$F3,$F3,$F3,$F3,$F3,$F3,$F3
  DEFB $F3,$F3,$F3,$F3,$F3,$F3,$F3,$F3
  DEFB $F2,$F2,$F2,$F2,$F2,$F2,$F2,$F2
  DEFB $F2,$F2,$F2,$F2,$F2,$F2,$F2,$F2
  DEFB $F1,$F1,$F1,$F1,$F1,$F1,$F1,$F1
  DEFB $F1,$F1,$F1,$F1,$F1,$F1,$F1,$F1
  DEFB $F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0
  DEFB $F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0
  DEFB $FF,$EF,$DF,$CF,$BF,$AF,$9F,$8F
  DEFB $7F,$6F,$5F,$4F,$3F,$2F,$1F,$0F
  DEFB $FF,$EF,$DF,$CF,$BF,$AF,$9F,$8F
  DEFB $7F,$6F,$5F,$4F,$3F,$2F,$1F,$0F
  DEFB $FF,$EF,$DF,$CF,$BF,$AF,$9F,$8F
  DEFB $7F,$6F,$5F,$4F,$3F,$2F,$1F,$0F
  DEFB $FF,$EF,$DF,$CF,$BF,$AF,$9F,$8F
  DEFB $7F,$6F,$5F,$4F,$3F,$2F,$1F,$0F
  DEFB $FF,$EF,$DF,$CF,$BF,$AF,$9F,$8F
  DEFB $7F,$6F,$5F,$4F,$3F,$2F,$1F,$0F
  DEFB $FF,$EF,$DF,$CF,$BF,$AF,$9F,$8F
  DEFB $7F,$6F,$5F,$4F,$3F,$2F,$1F,$0F
  DEFB $FF,$EF,$DF,$CF,$BF,$AF,$9F,$8F
  DEFB $7F,$6F,$5F,$4F,$3F,$2F,$1F,$0F
  DEFB $FF,$EF,$DF,$CF,$BF,$AF,$9F,$8F
  DEFB $7F,$6F,$5F,$4F,$3F,$2F,$1F,$0F
  DEFB $FF,$EF,$DF,$CF,$BF,$AF,$9F,$8F
  DEFB $7F,$6F,$5F,$4F,$3F,$2F,$1F,$0F
  DEFB $FF,$EF,$DF,$CF,$BF,$AF,$9F,$8F
  DEFB $7F,$6F,$5F,$4F,$3F,$2F,$1F,$0F
  DEFB $FF,$EF,$DF,$CF,$BF,$AF,$9F,$8F
  DEFB $7F,$6F,$5F,$4F,$3F,$2F,$1F,$0F
  DEFB $FF,$EF,$DF,$CF,$BF,$AF,$9F,$8F
  DEFB $7F,$6F,$5F,$4F,$3F,$2F,$1F,$0F
  DEFB $FF,$EF,$DF,$CF,$BF,$AF,$9F,$8F
  DEFB $7F,$6F,$5F,$4F,$3F,$2F,$1F,$0F
  DEFB $FF,$EF,$DF,$CF,$BF,$AF,$9F,$8F
  DEFB $7F,$6F,$5F,$4F,$3F,$2F,$1F,$0F
  DEFB $FF,$EF,$DF,$CF,$BF,$AF,$9F,$8F
  DEFB $7F,$6F,$5F,$4F,$3F,$2F,$1F,$0F
  DEFB $FF,$EF,$DF,$CF,$BF,$AF,$9F,$8F
  DEFB $7F,$6F,$5F,$4F,$3F,$2F,$1F,$0F
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC
  DEFB $FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC
  DEFB $FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC
  DEFB $FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC
  DEFB $FB,$FB,$FB,$FB,$FB,$FB,$FB,$FB
  DEFB $FB,$FB,$FB,$FB,$FB,$FB,$FB,$FB
  DEFB $FB,$FB,$FB,$FB,$FB,$FB,$FB,$FB
  DEFB $FB,$FB,$FB,$FB,$FB,$FB,$FB,$FB
  DEFB $FA,$FA,$FA,$FA,$FA,$FA,$FA,$FA
  DEFB $FA,$FA,$FA,$FA,$FA,$FA,$FA,$FA
  DEFB $FA,$FA,$FA,$FA,$FA,$FA,$FA,$FA
  DEFB $FA,$FA,$FA,$FA,$FA,$FA,$FA,$FA
  DEFB $F9,$F9,$F9,$F9,$F9,$F9,$F9,$F9
  DEFB $F9,$F9,$F9,$F9,$F9,$F9,$F9,$F9
  DEFB $F9,$F9,$F9,$F9,$F9,$F9,$F9,$F9
  DEFB $F9,$F9,$F9,$F9,$F9,$F9,$F9,$F9
  DEFB $F8,$F8,$F8,$F8,$F8,$F8,$F8,$F8
  DEFB $F8,$F8,$F8,$F8,$F8,$F8,$F8,$F8
  DEFB $F8,$F8,$F8,$F8,$F8,$F8,$F8,$F8
  DEFB $F8,$F8,$F8,$F8,$F8,$F8,$F8,$F8
  DEFB $FF,$F7,$EF,$E7,$DF,$D7,$CF,$C7
  DEFB $BF,$B7,$AF,$A7,$9F,$97,$8F,$87
  DEFB $7F,$77,$6F,$67,$5F,$57,$4F,$47
  DEFB $3F,$37,$2F,$27,$1F,$17,$0F,$07
  DEFB $FF,$F7,$EF,$E7,$DF,$D7,$CF,$C7
  DEFB $BF,$B7,$AF,$A7,$9F,$97,$8F,$87
  DEFB $7F,$77,$6F,$67,$5F,$57,$4F,$47
  DEFB $3F,$37,$2F,$27,$1F,$17,$0F,$07
  DEFB $FF,$F7,$EF,$E7,$DF,$D7,$CF,$C7
  DEFB $BF,$B7,$AF,$A7,$9F,$97,$8F,$87
  DEFB $7F,$77,$6F,$67,$5F,$57,$4F,$47
  DEFB $3F,$37,$2F,$27,$1F,$17,$0F,$07
  DEFB $FF,$F7,$EF,$E7,$DF,$D7,$CF,$C7
  DEFB $BF,$B7,$AF,$A7,$9F,$97,$8F,$87
  DEFB $7F,$77,$6F,$67,$5F,$57,$4F,$47
  DEFB $3F,$37,$2F,$27,$1F,$17,$0F,$07
  DEFB $FF,$F7,$EF,$E7,$DF,$D7,$CF,$C7
  DEFB $BF,$B7,$AF,$A7,$9F,$97,$8F,$87
  DEFB $7F,$77,$6F,$67,$5F,$57,$4F,$47
  DEFB $3F,$37,$2F,$27,$1F,$17,$0F,$07
  DEFB $FF,$F7,$EF,$E7,$DF,$D7,$CF,$C7
  DEFB $BF,$B7,$AF,$A7,$9F,$97,$8F,$87
  DEFB $7F,$77,$6F,$67,$5F,$57,$4F,$47
  DEFB $3F,$37,$2F,$27,$1F,$17,$0F,$07
  DEFB $FF,$F7,$EF,$E7,$DF,$D7,$CF,$C7
  DEFB $BF,$B7,$AF,$A7,$9F,$97,$8F,$87
  DEFB $7F,$77,$6F,$67,$5F,$57,$4F,$47
  DEFB $3F,$37,$2F,$27,$1F,$17,$0F,$07
  DEFB $FF,$F7,$EF,$E7,$DF,$D7,$CF,$C7
  DEFB $BF,$B7,$AF,$A7,$9F,$97,$8F,$87
  DEFB $7F,$77,$6F,$67,$5F,$57,$4F,$47
  DEFB $3F,$37,$2F,$27,$1F,$17,$0F,$07
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC
  DEFB $FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC
  DEFB $FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC
  DEFB $FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC
  DEFB $FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC
  DEFB $FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC
  DEFB $FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC
  DEFB $FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC
  DEFB $FF,$FB,$F7,$F3,$EF,$EB,$E7,$E3
  DEFB $DF,$DB,$D7,$D3,$CF,$CB,$C7,$C3
  DEFB $BF,$BB,$B7,$B3,$AF,$AB,$A7,$A3
  DEFB $9F,$9B,$97,$93,$8F,$8B,$87,$83
  DEFB $7F,$7B,$77,$73,$6F,$6B,$67,$63
  DEFB $5F,$5B,$57,$53,$4F,$4B,$47,$43
  DEFB $3F,$3B,$37,$33,$2F,$2B,$27,$23
  DEFB $1F,$1B,$17,$13,$0F,$0B,$07,$03
  DEFB $FF,$FB,$F7,$F3,$EF,$EB,$E7,$E3
  DEFB $DF,$DB,$D7,$D3,$CF,$CB,$C7,$C3
  DEFB $BF,$BB,$B7,$B3,$AF,$AB,$A7,$A3
  DEFB $9F,$9B,$97,$93,$8F,$8B,$87,$83
  DEFB $7F,$7B,$77,$73,$6F,$6B,$67,$63
  DEFB $5F,$5B,$57,$53,$4F,$4B,$47,$43
  DEFB $3F,$3B,$37,$33,$2F,$2B,$27,$23
  DEFB $1F,$1B,$17,$13,$0F,$0B,$07,$03
  DEFB $FF,$FB,$F7,$F3,$EF,$EB,$E7,$E3
  DEFB $DF,$DB,$D7,$D3,$CF,$CB,$C7,$C3
  DEFB $BF,$BB,$B7,$B3,$AF,$AB,$A7,$A3
  DEFB $9F,$9B,$97,$93,$8F,$8B,$87,$83
  DEFB $7F,$7B,$77,$73,$6F,$6B,$67,$63
  DEFB $5F,$5B,$57,$53,$4F,$4B,$47,$43
  DEFB $3F,$3B,$37,$33,$2F,$2B,$27,$23
  DEFB $1F,$1B,$17,$13,$0F,$0B,$07,$03
  DEFB $FF,$FB,$F7,$F3,$EF,$EB,$E7,$E3
  DEFB $DF,$DB,$D7,$D3,$CF,$CB,$C7,$C3
  DEFB $BF,$BB,$B7,$B3,$AF,$AB,$A7,$A3
  DEFB $9F,$9B,$97,$93,$8F,$8B,$87,$83
  DEFB $7F,$7B,$77,$73,$6F,$6B,$67,$63
  DEFB $5F,$5B,$57,$53,$4F,$4B,$47,$43
  DEFB $3F,$3B,$37,$33,$2F,$2B,$27,$23
  DEFB $1F,$1B,$17,$13,$0F,$0B,$07,$03
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FF,$FD,$FB,$F9,$F7,$F5,$F3,$F1
  DEFB $EF,$ED,$EB,$E9,$E7,$E5,$E3,$E1
  DEFB $DF,$DD,$DB,$D9,$D7,$D5,$D3,$D1
  DEFB $CF,$CD,$CB,$C9,$C7,$C5,$C3,$C1
  DEFB $BF,$BD,$BB,$B9,$B7,$B5,$B3,$B1
  DEFB $AF,$AD,$AB,$A9,$A7,$A5,$A3,$A1
  DEFB $9F,$9D,$9B,$99,$97,$95,$93,$91
  DEFB $8F,$8D,$8B,$89,$87,$85,$83,$81
  DEFB $7F,$7D,$7B,$79,$77,$75,$73,$71
  DEFB $6F,$6D,$6B,$69,$67,$65,$63,$61
  DEFB $5F,$5D,$5B,$59,$57,$55,$53,$51
  DEFB $4F,$4D,$4B,$49,$47,$45,$43,$41
  DEFB $3F,$3D,$3B,$39,$37,$35,$33,$31
  DEFB $2F,$2D,$2B,$29,$27,$25,$23,$21
  DEFB $1F,$1D,$1B,$19,$17,$15,$13,$11
  DEFB $0F,$0D,$0B,$09,$07,$05,$03,$01
  DEFB $FF,$FD,$FB,$F9,$F7,$F5,$F3,$F1
  DEFB $EF,$ED,$EB,$E9,$E7,$E5,$E3,$E1
  DEFB $DF,$DD,$DB,$D9,$D7,$D5,$D3,$D1
  DEFB $CF,$CD,$CB,$C9,$C7,$C5,$C3,$C1
  DEFB $BF,$BD,$BB,$B9,$B7,$B5,$B3,$B1
  DEFB $AF,$AD,$AB,$A9,$A7,$A5,$A3,$A1
  DEFB $9F,$9D,$9B,$99,$97,$95,$93,$91
  DEFB $8F,$8D,$8B,$89,$87,$85,$83,$81
  DEFB $7F,$7D,$7B,$79,$77,$75,$73,$71
  DEFB $6F,$6D,$6B,$69,$67,$65,$63,$61
  DEFB $5F,$5D,$5B,$59,$57,$55,$53,$51
  DEFB $4F,$4D,$4B,$49,$47,$45,$43,$41
  DEFB $3F,$3D,$3B,$39,$37,$35,$33,$31
  DEFB $2F,$2D,$2B,$29,$27,$25,$23,$21
  DEFB $1F,$1D,$1B,$19,$17,$15,$13,$11
  DEFB $0F,$0D,$0B,$09,$07,$05,$03,$01

